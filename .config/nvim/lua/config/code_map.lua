local M = {}

local sources = {
  { key = "s", label = "S", hl = "Function", format = "lsp_symbol" },
  { key = "r", label = "R", hl = "DiagnosticInfo", format = "file" },
  { key = "j", label = "J", hl = "Comment", format = "file" },
  { key = "m", label = "M", hl = "DiagnosticHint", format = "file" },
}

local source_ids = {}
for id, source in ipairs(sources) do
  source_ids[source.key] = id
end

---@param item snacks.picker.finder.Item
---@param picker snacks.Picker
local function format_item(item, picker)
  local source = sources[item.source_id]
  if not source then
    return Snacks.picker.format.file(item, picker)
  end

  local formatted = Snacks.picker.format[source.format](item, picker)
  table.insert(formatted, 1, { (" %s  "):format(source.label), source.hl })
  return formatted
end

---@param _ snacks.Picker
---@param filter snacks.picker.Filter
local function apply_lens(_, filter)
  local lens, pattern = filter.pattern:match("^%s*([asrjmASRJM]):%s*(.*)$")
  if lens then
    filter.source_id = source_ids[lens:lower()]
    filter.pattern = pattern
  else
    filter.source_id = nil
  end
end

---@param item snacks.picker.finder.Item
local function named_mark(item)
  return type(item.label) == "string" and item.label:match("^[A-Za-z]$") ~= nil
end

function M.open()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then
    vim.notify("Code Map is available in file buffers", vim.log.levels.INFO, { title = "Code Map" })
    return
  end

  local path = vim.api.nvim_buf_get_name(buf)
  local name = path ~= "" and vim.fn.fnamemodify(path, ":t") or "[No Name]"

  return Snacks.picker({
    title = ("Code Map · %s  [s: symbols · r: refs · j: trail · m: marks · a: all]"):format(name),
    layout = { preset = "ivy" },
    main = { current = true },
    auto_confirm = false,
    filter = { transform = apply_lens },
    multi = {
      {
        source = "lsp_symbols",
        tree = true,
      },
      {
        source = "lsp_references",
        include_declaration = true,
        include_current = false,
      },
      {
        source = "jumps",
        filter = { buf = buf },
      },
      {
        source = "marks",
        global = true,
        ["local"] = true,
        filter = { buf = buf, filter = named_mark },
      },
    },
    format = format_item,
  })
end

return M
