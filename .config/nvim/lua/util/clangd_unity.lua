local M = {}

local uv = vim.uv or vim.loop
local adapter_version = 1
local config_dir = vim.fn.stdpath("config")
local cache_root = vim.fs.joinpath(config_dir, ".cache", "clangd-unity")
local aspect_root = vim.fs.normalize("/Users/arijit/installations/aspect_magemin/aspect")

local last_status = {}

local function normalize(path)
  return path and vim.fs.normalize(path) or nil
end

local function is_file(path)
  local stat = path and uv.fs_stat(path)
  return stat and stat.type == "file"
end

local function read_file(path)
  local file, err = io.open(path, "rb")
  if not file then
    return nil, err
  end

  local contents = file:read("*a")
  file:close()
  return contents
end

local function write_atomic(path, contents)
  local temporary = path .. ".tmp"
  local file, err = io.open(temporary, "wb")
  if not file then
    return nil, err
  end

  local ok, write_err = file:write(contents)
  file:close()
  if not ok then
    uv.fs_unlink(temporary)
    return nil, write_err
  end

  local renamed, rename_err = uv.fs_rename(temporary, path)
  if not renamed then
    uv.fs_unlink(temporary)
    return nil, rename_err
  end
  return true
end

local function stat_signature(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return "missing"
  end

  local mtime = stat.mtime or {}
  return table.concat({ stat.size or 0, mtime.sec or 0, mtime.nsec or 0 }, ":")
end

local function database_candidates(root)
  local candidates = {
    vim.fs.joinpath(root, "compile_commands.json"),
    vim.fs.joinpath(root, "build", "compile_commands.json"),
  }

  local scanner = uv.fs_scandir(root)
  if scanner then
    while true do
      local name, kind = uv.fs_scandir_next(scanner)
      if not name then
        break
      end
      if kind == "directory" and (name:match("^build") or name:match("^cmake%-build")) then
        table.insert(candidates, vim.fs.joinpath(root, name, "compile_commands.json"))
      end
    end
  end

  return candidates
end

local function find_database(root)
  local seen = {}
  for _, candidate in ipairs(database_candidates(root)) do
    if is_file(candidate) then
      local resolved = uv.fs_realpath(candidate) or normalize(candidate)
      if not seen[resolved] then
        return resolved
      end
      seen[resolved] = true
    end
  end
end

local function decode_database(path)
  local contents, read_err = read_file(path)
  if not contents then
    return nil, "cannot read compile database: " .. tostring(read_err)
  end

  local ok, database = pcall(vim.json.decode, contents)
  if not ok or type(database) ~= "table" then
    return nil, "invalid compile_commands.json"
  end
  return database
end

local function is_unity_file(path)
  if not path then
    return false
  end
  local basename = vim.fs.basename(path)
  return path:find("/Unity/", 1, true) ~= nil and basename:match("^unity_.+%.[cC][cCpPxX]*$") ~= nil
end

local function is_source_file(path)
  return path:lower():match("%.c$")
    or path:lower():match("%.cc$")
    or path:lower():match("%.cpp$")
    or path:lower():match("%.cxx$")
    or path:lower():match("%.m$")
    or path:lower():match("%.mm$")
end

local function included_sources(unity_file)
  local contents = read_file(unity_file)
  if not contents then
    return {}
  end

  local sources = {}
  for line in contents:gmatch("[^\r\n]+") do
    local included = line:match('^%s*#%s*include%s*["<]([^">]+)[">]')
    if included and is_source_file(included) then
      if not vim.startswith(included, "/") then
        included = vim.fs.joinpath(vim.fs.dirname(unity_file), included)
      end
      table.insert(sources, normalize(included))
    end
  end
  return sources
end

local function unity_priority(path)
  local lower = path:lower()
  if lower:find("debug", 1, true) then
    return 3
  elseif lower:find("release", 1, true) then
    return 1
  end
  return 2
end

local function analyze_database(database)
  local unity_entries = {}
  local direct_sources = {}

  for _, entry in ipairs(database) do
    local file = normalize(entry.file)
    if is_unity_file(file) then
      table.insert(unity_entries, { entry = entry, file = file })
    elseif file then
      direct_sources[file] = true
    end
  end

  table.sort(unity_entries, function(left, right)
    local left_priority = unity_priority(left.file)
    local right_priority = unity_priority(right.file)
    if left_priority == right_priority then
      return left.file < right.file
    end
    return left_priority > right_priority
  end)

  local mappings = {}
  for _, unity in ipairs(unity_entries) do
    for _, source in ipairs(included_sources(unity.file)) do
      if not direct_sources[source] and not mappings[source] then
        mappings[source] = unity
      end
    end
  end

  return unity_entries, mappings
end

local function fingerprint(root, database_path, unity_entries)
  local parts = {
    tostring(adapter_version),
    normalize(root),
    database_path,
    stat_signature(database_path),
  }

  for _, unity in ipairs(unity_entries) do
    table.insert(parts, unity.file)
    table.insert(parts, stat_signature(unity.file))
  end
  return vim.fn.sha256(table.concat(parts, "\n"))
end

local function shell_split(command)
  local arguments = {}
  local current = {}
  local quote
  local index = 1

  local function finish_argument()
    if #current > 0 then
      table.insert(arguments, table.concat(current))
      current = {}
    end
  end

  while index <= #command do
    local character = command:sub(index, index)
    if quote == "'" then
      if character == "'" then
        quote = nil
      else
        table.insert(current, character)
      end
    elseif quote == '"' then
      if character == '"' then
        quote = nil
      elseif character == "\\" and index < #command then
        index = index + 1
        table.insert(current, command:sub(index, index))
      else
        table.insert(current, character)
      end
    elseif character == "'" or character == '"' then
      quote = character
    elseif character == "\\" and index < #command then
      index = index + 1
      table.insert(current, command:sub(index, index))
    elseif character:match("%s") then
      finish_argument()
    else
      table.insert(current, character)
    end
    index = index + 1
  end

  if quote then
    return nil, "unterminated quote in compile command"
  end
  finish_argument()
  return arguments
end

local function command_arguments(entry)
  if type(entry.arguments) == "table" then
    return vim.deepcopy(entry.arguments)
  end
  if type(entry.command) == "string" then
    return shell_split(entry.command)
  end
end

local flags_with_values = {
  ["-MF"] = true,
  ["-MT"] = true,
  ["-MQ"] = true,
  ["-MJ"] = true,
  ["-o"] = true,
}

local function is_same_file_argument(argument, directory, expected)
  if argument:sub(1, 1) == "-" then
    return false
  end
  local candidate = argument
  if not vim.startswith(candidate, "/") then
    candidate = vim.fs.joinpath(directory, candidate)
  end
  return normalize(candidate) == expected
end

local function cloned_arguments(entry, unity_file, source_file)
  local arguments, split_err = command_arguments(entry)
  if not arguments then
    return nil, split_err or "compile entry has neither arguments nor command"
  end

  local cloned = {}
  local skip_next = false
  for _, argument in ipairs(arguments) do
    if skip_next then
      skip_next = false
    elseif flags_with_values[argument] then
      skip_next = true
    elseif argument == "-Winvalid-pch" or argument:match("^-Wa,") then
      -- These flags do not affect semantic parsing and are noisy in clangd.
    elseif argument:match("^%-M[FQJT].+") then
      -- Drop joined dependency-output forms as well.
    elseif is_same_file_argument(argument, entry.directory, unity_file) then
      table.insert(cloned, source_file)
    else
      table.insert(cloned, argument)
    end
  end
  return cloned
end

local function generated_database(database, mappings)
  local generated = {}
  local sources = vim.tbl_keys(mappings)
  table.sort(sources)

  for _, source in ipairs(sources) do
    local unity = mappings[source]
    local arguments, err = cloned_arguments(unity.entry, unity.file, source)
    if not arguments then
      return nil, err
    end
    table.insert(generated, {
      directory = unity.entry.directory,
      arguments = arguments,
      file = source,
    })
  end

  for _, entry in ipairs(database) do
    table.insert(generated, entry)
  end
  return generated
end

local function cache_paths(root)
  local project_dir = vim.fs.joinpath(cache_root, vim.fn.sha256(normalize(root)):sub(1, 16))
  return {
    directory = project_dir,
    database = vim.fs.joinpath(project_dir, "compile_commands.json"),
    manifest = vim.fs.joinpath(project_dir, "manifest.json"),
  }
end

local function read_manifest(path)
  local contents = read_file(path)
  if not contents then
    return nil
  end
  local ok, manifest = pcall(vim.json.decode, contents)
  return ok and manifest or nil
end

local function inspect(root)
  root = normalize(root)
  if not root then
    return { state = "error", error = "project root is unavailable" }
  end

  local database_path = find_database(root)
  if not database_path then
    return { root = root, state = "not_unity", error = "compile_commands.json was not found" }
  end

  local database, decode_err = decode_database(database_path)
  if not database then
    return { root = root, source_database = database_path, state = "error", error = decode_err }
  end

  local unity_entries, mappings = analyze_database(database)
  if #unity_entries == 0 or vim.tbl_isempty(mappings) then
    return {
      root = root,
      source_database = database_path,
      state = "not_unity",
      error = "no CMake Unity source mappings were found",
    }
  end

  local paths = cache_paths(root)
  local current_fingerprint = fingerprint(root, database_path, unity_entries)
  local manifest = read_manifest(paths.manifest)
  local fresh = manifest and manifest.fingerprint == current_fingerprint and is_file(paths.database)

  return {
    root = root,
    source_database = database_path,
    database = database,
    unity_entries = unity_entries,
    mappings = mappings,
    paths = paths,
    fingerprint = current_fingerprint,
    generated_entries = vim.tbl_count(mappings),
    state = fresh and "fresh" or "stale",
  }
end

function M.prepare(root, opts)
  opts = opts or {}
  local status = inspect(root)
  last_status[normalize(root) or "unknown"] = status

  if status.state == "error" then
    return nil, status
  end
  if status.state == "not_unity" then
    return nil, status
  end
  if status.state == "fresh" and not opts.force then
    return status.paths.directory, status
  end

  local output, generation_err = generated_database(status.database, status.mappings)
  if not output then
    status.state = "error"
    status.error = generation_err
    return nil, status
  end

  vim.fn.mkdir(status.paths.directory, "p")
  local database_ok, database_err = write_atomic(status.paths.database, vim.json.encode(output))
  if not database_ok then
    status.state = "error"
    status.error = "cannot write generated database: " .. tostring(database_err)
    return nil, status
  end

  local manifest = {
    version = adapter_version,
    root = status.root,
    source_database = status.source_database,
    fingerprint = status.fingerprint,
    generated_entries = status.generated_entries,
    unity_entries = #status.unity_entries,
    updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }
  local manifest_ok, manifest_err = write_atomic(status.paths.manifest, vim.json.encode(manifest))
  if not manifest_ok then
    status.state = "error"
    status.error = "cannot write generated manifest: " .. tostring(manifest_err)
    return nil, status
  end

  status.state = "generated"
  last_status[status.root] = status
  return status.paths.directory, status
end

function M.disable_project_config(root)
  return normalize(root) == aspect_root
end

local function current_root()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "clangd" })
  if clients[1] and clients[1].root_dir then
    return normalize(clients[1].root_dir)
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return nil
  end
  return vim.fs.root(filename, { "compile_commands.json", "CMakeLists.txt", ".git" })
end

local function restart_root(root)
  local buffers = {}
  for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
    if normalize(client.root_dir) == normalize(root) then
      for bufnr in pairs(client.attached_buffers or {}) do
        buffers[bufnr] = true
      end
      client:stop(true)
    end
  end

  vim.defer_fn(function()
    for bufnr in pairs(buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr, group = "nvim.lsp.enable" })
      end
    end
  end, 150)
end

local function status_message(status)
  local lines = {
    "clangd Unity adapter: " .. status.state,
    "root: " .. tostring(status.root),
    "source database: " .. tostring(status.source_database),
  }
  if status.paths then
    table.insert(lines, "generated database: " .. status.paths.database)
  end
  if status.generated_entries then
    table.insert(lines, "generated source entries: " .. status.generated_entries)
  end
  if status.error then
    table.insert(lines, "detail: " .. status.error)
  end
  return table.concat(lines, "\n")
end

function M.setup_commands()
  if M._commands_created then
    return
  end
  M._commands_created = true

  vim.api.nvim_create_user_command("ClangdUnityRefresh", function()
    local root = current_root()
    if not root then
      vim.notify("Cannot determine the current C/C++ project root", vim.log.levels.ERROR)
      return
    end

    local directory, status = M.prepare(root, { force = true })
    if not directory then
      vim.notify(status_message(status), status.state == "error" and vim.log.levels.ERROR or vim.log.levels.WARN)
      return
    end
    restart_root(root)
    vim.notify(status_message(status) .. "\nclangd restarted for this project", vim.log.levels.INFO)
  end, { desc = "Refresh CMake Unity metadata and restart clangd" })

  vim.api.nvim_create_user_command("ClangdUnityStatus", function()
    local root = current_root()
    if not root then
      vim.notify("Cannot determine the current C/C++ project root", vim.log.levels.ERROR)
      return
    end
    local status = inspect(root)
    last_status[root] = status
    vim.notify(status_message(status), status.state == "error" and vim.log.levels.ERROR or vim.log.levels.INFO)
  end, { desc = "Show CMake Unity metadata status for clangd" })
end

return M
