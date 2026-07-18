local M = {}

local config_dir = vim.fn.stdpath("config")
local binary = config_dir .. "/bin/copilot-language-server"
local version_file = config_dir .. "/bin/copilot-language-server.version"
local state_dir = config_dir .. "/.state/copilot"
local privacy_file = state_dir .. "/privacy-confirmed"
local privacy_url = "https://github.com/settings/copilot/features"

local allowed_filetypes = {
  c = true,
  cpp = true,
  objc = true,
  objcpp = true,
  cuda = true,
  python = true,
  lua = true,
  sh = true,
  bash = true,
  zsh = true,
  fish = true,
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  rust = true,
  go = true,
  cmake = true,
}

local sensitive_words = {
  credential = true,
  credentials = true,
  secret = true,
  secrets = true,
  token = true,
  tokens = true,
}

local blocked_suffixes = {
  [".key"] = true,
  [".pem"] = true,
  [".p12"] = true,
  [".pfx"] = true,
}

local blocked_path_parts = {
  "/.git/",
  "/node_modules/",
  "/cmakefiles/",
  "/build/",
  "/dist/",
  "/generated/",
  "/vendor/",
}

local status_by_client = {}
local notified_auth = {}
local configured = false
local setup_done = false

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Copilot" })
end

local function normalize_bufnr(bufnr)
  if not bufnr or bufnr == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return bufnr
end

local function file_exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function read_version()
  local lines = vim.fn.readfile(version_file)
  for _, line in ipairs(lines) do
    local version = line:match("^version=(.+)$")
    if version then
      return version
    end
  end
  return "unknown"
end

local function privacy_confirmed()
  return file_exists(privacy_file)
end

local function confirm_privacy()
  if privacy_confirmed() then
    return true
  end

  if #vim.api.nvim_list_uis() == 0 then
    notify("Privacy confirmation is required in an interactive Neovim session.", vim.log.levels.WARN)
    return false
  end

  local choice = vim.fn.confirm(
    "Before enabling Copilot, disable GitHub's model-training setting.\n"
      .. "Cloud inference will still send nearby code to GitHub.\n\n"
      .. "Have you disabled 'Allow GitHub to use my data for AI model training'?",
    "&Yes, I disabled it\n&Cancel",
    2
  )

  if choice ~= 1 then
    notify("Copilot remains off. Run :CopilotPrivacySettings to open the GitHub setting.", vim.log.levels.WARN)
    return false
  end

  vim.fn.mkdir(state_dir, "p")
  local ok = pcall(vim.fn.writefile, {
    "confirmed=true",
    "setting=Allow GitHub to use my data for AI model training: disabled",
    "confirmed_at=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }, privacy_file)
  if not ok then
    notify("Could not save the privacy confirmation; Copilot remains off.", vim.log.levels.ERROR)
    return false
  end
  pcall(vim.uv.fs_chmod, state_dir, 448) -- 0700
  pcall(vim.uv.fs_chmod, privacy_file, 384) -- 0600
  return true
end

local function sensitive_filename(name)
  local basename = vim.fs.basename(name):lower()
  if basename == ".env" or basename:match("^%.env%.") then
    return true
  end
  if basename:match("^id_rsa") or basename:match("^id_ed25519") or basename:match("^id_ecdsa") then
    return true
  end
  for suffix in pairs(blocked_suffixes) do
    if basename:sub(-#suffix) == suffix then
      return true
    end
  end
  for word in basename:gsub("[^%w]+", " "):gmatch("%w+") do
    if sensitive_words[word] then
      return true
    end
  end
  return false
end

local function generated_path(name)
  local path = name:lower():gsub("\\", "/")
  for _, part in ipairs(blocked_path_parts) do
    if path:find(part, 1, true) then
      return true
    end
  end
  return false
end

function M.eligibility(bufnr)
  bufnr = normalize_bufnr(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false, "invalid buffer"
  end
  if vim.bo[bufnr].buftype ~= "" then
    return false, "special/non-file buffer"
  end
  if not vim.bo[bufnr].modifiable then
    return false, "non-modifiable buffer"
  end
  if not allowed_filetypes[vim.bo[bufnr].filetype] then
    return false, "unsupported filetype: " .. (vim.bo[bufnr].filetype ~= "" and vim.bo[bufnr].filetype or "none")
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return false, "unnamed buffer"
  end
  if sensitive_filename(name) then
    return false, "sensitive filename"
  end
  if generated_path(name) then
    return false, "generated, dependency, or build path"
  end

  local stat = vim.uv.fs_stat(name)
  if stat and stat.size and stat.size > 1024 * 1024 then
    return false, "file is larger than 1 MiB"
  end
  return true
end

local function project_root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local marker = vim.fs.root(name, { ".copilot-root", ".git" })
  return marker or vim.fs.dirname(name)
end

local function status_handler(err, result, ctx)
  if err then
    status_by_client[ctx.client_id] = { kind = "Error", message = err.message or tostring(err) }
    vim.schedule(function()
      vim.cmd.redrawstatus()
    end)
    return
  end

  result = result or {}
  status_by_client[ctx.client_id] = {
    kind = result.kind or "Normal",
    busy = result.busy or false,
    message = result.message or result.status or "",
  }
  vim.schedule(function()
    vim.cmd.redrawstatus()
    if result.status == "Error" and not notified_auth[ctx.client_id] then
      notified_auth[ctx.client_id] = true
      notify("Sign in with :LspCopilotSignIn after confirming the privacy setting.", vim.log.levels.WARN)
    end
  end)
end

local function ensure_config()
  if configured then
    return true
  end
  if not file_exists(binary) or vim.fn.executable(binary) ~= 1 then
    notify("Native language server is missing or not executable: " .. binary, vim.log.levels.ERROR)
    return false
  end

  -- Ensure nvim-lspconfig's Copilot config (including sign-in commands) is on the runtime path.
  pcall(function()
    require("lazy").load({ plugins = { "nvim-lspconfig" } })
  end)

  vim.lsp.config("copilot", {
    cmd = { binary, "--stdio" },
    cmd_env = {
      XDG_CONFIG_HOME = state_dir .. "/xdg",
    },
    settings = {
      telemetry = {
        telemetryLevel = "off",
      },
    },
    handlers = {
      didChangeStatus = status_handler,
    },
  })
  configured = true
  return true
end

local function set_buffer_keymaps(bufnr)
  local function accept()
    if not vim.lsp.inline_completion.get({ bufnr = bufnr }) then
      notify("No Copilot suggestion is currently visible.")
    end
  end

  vim.keymap.set("i", "<M-l>", accept, { buffer = bufnr, desc = "Accept Copilot suggestion" })
  -- macOS terminals commonly send Option-L as the literal character below.
  vim.keymap.set("i", "¬", accept, { buffer = bufnr, desc = "Accept Copilot suggestion (macOS Option-L)" })
  vim.keymap.set("i", "<M-]>", function()
    vim.lsp.inline_completion.select({ bufnr = bufnr, count = 1 })
  end, { buffer = bufnr, desc = "Next Copilot suggestion" })
  vim.keymap.set("i", "<M-[>", function()
    vim.lsp.inline_completion.select({ bufnr = bufnr, count = -1 })
  end, { buffer = bufnr, desc = "Previous Copilot suggestion" })
end

local function del_buffer_keymaps(bufnr)
  for _, lhs in ipairs({ "<M-l>", "¬", "<M-]>", "<M-[>" }) do
    pcall(vim.keymap.del, "i", lhs, { buffer = bufnr })
  end
end

local function stop_unused_clients()
  vim.schedule(function()
    for _, client in ipairs(vim.lsp.get_clients({ name = "copilot" })) do
      local used = false
      for bufnr in pairs(client.attached_buffers or {}) do
        if vim.api.nvim_buf_is_valid(bufnr) and vim.b[bufnr].copilot_manual_enabled then
          used = true
          break
        end
      end
      if not used and not client:is_stopped() then
        status_by_client[client.id] = nil
        notified_auth[client.id] = nil
        client:stop()
      end
    end
    vim.cmd.redrawstatus()
  end)
end

function M.is_enabled(bufnr)
  bufnr = normalize_bufnr(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and vim.b[bufnr].copilot_manual_enabled == true
end

function M.enable(bufnr)
  bufnr = normalize_bufnr(bufnr)
  if M.is_enabled(bufnr) then
    notify("Copilot is already enabled for this buffer.")
    return true
  end

  local eligible, reason = M.eligibility(bufnr)
  if not eligible then
    notify("Copilot was not enabled: " .. reason .. ".", vim.log.levels.WARN)
    return false
  end
  if not confirm_privacy() or not ensure_config() then
    return false
  end

  local config = vim.deepcopy(vim.lsp.config.copilot)
  config.root_dir = project_root(bufnr)
  config.workspace_folders = nil

  local client_id = vim.lsp.start(config, { bufnr = bufnr })
  if not client_id then
    notify("The Copilot language server could not be started.", vim.log.levels.ERROR)
    return false
  end

  -- Neovim's capability filter accepts a buffer or a client, not both.
  -- Buffer scope is the privacy boundary chosen for this integration.
  local inline_ok, inline_err = pcall(vim.lsp.inline_completion.enable, true, { bufnr = bufnr })
  if not inline_ok then
    pcall(vim.lsp.buf_detach_client, bufnr, client_id)
    stop_unused_clients()
    notify("Native inline completion could not be enabled: " .. tostring(inline_err), vim.log.levels.ERROR)
    return false
  end

  vim.b[bufnr].copilot_manual_enabled = true
  set_buffer_keymaps(bufnr)
  notify("Copilot enabled for this buffer. Use Option-L to accept ghost text.")
  vim.cmd.redrawstatus()
  return true
end

function M.disable(bufnr, quiet)
  bufnr = normalize_bufnr(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    stop_unused_clients()
    return
  end

  vim.lsp.inline_completion.enable(false, { bufnr = bufnr })
  for _, client in ipairs(vim.lsp.get_clients({ name = "copilot", bufnr = bufnr })) do
    pcall(vim.lsp.buf_detach_client, bufnr, client.id)
  end
  vim.b[bufnr].copilot_manual_enabled = false
  del_buffer_keymaps(bufnr)
  stop_unused_clients()
  if not quiet then
    notify("Copilot disabled for this buffer.")
  end
end

function M.toggle(bufnr)
  bufnr = normalize_bufnr(bufnr)
  if M.is_enabled(bufnr) then
    M.disable(bufnr)
  else
    M.enable(bufnr)
  end
end

function M.statusline()
  local bufnr = vim.api.nvim_get_current_buf()
  if not M.is_enabled(bufnr) then
    return ""
  end
  local clients = vim.lsp.get_clients({ name = "copilot", bufnr = bufnr })
  if #clients == 0 then
    return "AI!"
  end
  local status = status_by_client[clients[1].id] or {}
  if status.kind == "Error" or status.kind == "Warning" then
    return "AI!"
  end
  return status.busy and "AI…" or "AI"
end

function M.status(bufnr)
  bufnr = normalize_bufnr(bufnr)
  local eligible, reason = M.eligibility(bufnr)
  local clients = vim.api.nvim_buf_is_valid(bufnr) and vim.lsp.get_clients({ name = "copilot", bufnr = bufnr }) or {}
  local lines = {
    "Buffer: " .. (M.is_enabled(bufnr) and "enabled" or "disabled"),
    "Eligible: " .. (eligible and "yes" or "no (" .. reason .. ")"),
    "Privacy acknowledgement: " .. (privacy_confirmed() and "recorded" or "required"),
    "Telemetry: off",
    "Server version: " .. read_version(),
    "Active client: " .. (#clients > 0 and tostring(clients[1].id) or "none"),
    "Training setting: managed at " .. privacy_url,
  }
  if #clients > 0 and status_by_client[clients[1].id] then
    local status = status_by_client[clients[1].id]
    lines[#lines + 1] = "Server status: " .. (status.kind or "unknown") .. (status.busy and " (busy)" or "")
    if status.message and status.message ~= "" then
      lines[#lines + 1] = "Message: " .. status.message
    end
  end
  notify(table.concat(lines, "\n"))
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  vim.api.nvim_create_user_command("CopilotBufferEnable", function()
    M.enable(0)
  end, { desc = "Enable native Copilot for the current buffer" })
  vim.api.nvim_create_user_command("CopilotBufferDisable", function()
    M.disable(0)
  end, { desc = "Disable native Copilot for the current buffer" })
  vim.api.nvim_create_user_command("CopilotBufferToggle", function()
    M.toggle(0)
  end, { desc = "Toggle native Copilot for the current buffer" })
  vim.api.nvim_create_user_command("CopilotStatus", function()
    M.status(0)
  end, { desc = "Show native Copilot status" })
  vim.api.nvim_create_user_command("CopilotPrivacySettings", function()
    vim.ui.open(privacy_url)
  end, { desc = "Open GitHub Copilot privacy settings" })

  vim.keymap.set("n", "<leader>ai", function()
    M.toggle(0)
  end, { desc = "Toggle Copilot for buffer" })

  vim.api.nvim_create_autocmd({ "BufWipeout", "LspDetach" }, {
    group = vim.api.nvim_create_augroup("copilot_native_cleanup", { clear = true }),
    callback = function(args)
      if args.event == "BufWipeout" and vim.api.nvim_buf_is_valid(args.buf) then
        vim.b[args.buf].copilot_manual_enabled = false
      end
      stop_unused_clients()
    end,
  })
end

return M
