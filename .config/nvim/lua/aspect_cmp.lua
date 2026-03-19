local M = {}

function M.new()
  local self = setmetatable({}, { __index = M })
  local path1 = vim.fn.stdpath("config") .. "/aspect_data/parameters.json"

  local file = io.open(path1, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    if ok then
      self.parsed_json = parsed
    end
  end
  return self
end

-- Helper to find the current subsection depth
function M:get_current_path()
  local cursor_row = vim.fn.line(".")
  local lines = vim.api.nvim_buf_get_lines(0, 0, cursor_row, false)
  local subsection_path = {}
  local ends_to_skip = 0

  for i = #lines - 1, 1, -1 do
    local l = lines[i]:match("^%s*(.-)%s*$") or ""
    if l ~= "" and l:sub(1, 1) ~= "#" then
      if l == "end" then
        ends_to_skip = ends_to_skip + 1
      elseif l:match("^subsection") then
        if ends_to_skip > 0 then
          ends_to_skip = ends_to_skip - 1
        else
          local sub_name = l:match("^subsection%s+(.-)%s*$")
          if sub_name then
            table.insert(subsection_path, 1, sub_name)
          end
        end
      end
    end
  end
  return subsection_path
end

function M:get_completions(context, callback)
  if not self.parsed_json then
    return callback({ items = {} })
  end

  local current_line = vim.api.nvim_get_current_line()
  local cursor_col = context.cursor.col
  local line_to_cursor = current_line:sub(1, cursor_col)

  -- 1. Get current subsection node in JSON
  local path = self:get_current_path()
  local current_node = self.parsed_json
  for _, sub in ipairs(path) do
    local next_node = nil
    if type(current_node) == "table" then
      for k, v in pairs(current_node) do
        if type(k) == "string" and k:gsub("_20", " ") == sub then
          next_node = v
          break
        end
      end
    end
    current_node = next_node or {}
  end

  local items = {}

  -- 2. DETECT CONTEXT: Are we typing the VALUE (after '=')?
  local param_before_eq = line_to_cursor:match("^%s*set%s+(.-)%s*=%s*")

  if param_before_eq then
    -- We are after the '='
    local clean_param = param_before_eq:gsub("%s+$", ""):gsub(" ", "_20")
    local param_node = current_node[clean_param]

    -- Only show options if 'values' or 'possible_values' exist in JSON
    if param_node and type(param_node) == "table" then
      local options = param_node.values or param_node.possible_values
      if type(options) == "table" then
        for _, opt in ipairs(options) do
          table.insert(items, {
            label = tostring(opt),
            kind = 12, -- Value icon
            detail = "ASPECT Option",
          })
        end
      end
    end
  else
    -- 3. We are typing the PARAMETER NAME or SUBSECTION
    local first_word = current_line:match("^%s*(%a+)")
    if type(current_node) == "table" then
      for k, val in pairs(current_node) do
        if type(k) == "string" and type(val) == "table" then
          local clean_label = k:gsub("_20", " ")
          local is_parameter = (val.value ~= nil)

          if first_word == "set" and is_parameter then
            table.insert(items, {
              label = clean_label,
              kind = 10,
              insertText = clean_label .. " = $0",
              insertTextFormat = 2,
              detail = val.pattern_description or "Parameter",
              documentation = val.documentation or "",
            })
          elseif first_word == "subsection" and not is_parameter then
            table.insert(items, {
              label = clean_label,
              kind = 22,
              insertText = clean_label .. "\n\t$0\nend",
              insertTextFormat = 2,
              detail = "Subsection",
              documentation = val.documentation or "ASPECT Subsection",
            })
          end
        end
      end
    end
  end

  callback({ items = items })
end

function M:get_trigger_characters()
  return { " ", "=" }
end

return M
