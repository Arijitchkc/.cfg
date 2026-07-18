local M = {}

M.palette = {
  -- The original OneDark canvas is deliberately preserved.
  bg = "#282c34",
  bg_float = "#21252b",
  bg_status = "#242830",
  bg_soft = "#2c3038",
  bg_selection = "#394251",
  bg_search = "#4a4437",

  -- Code stays bright against the dark canvas; only the chrome is dimmed.
  fg = "#c5c8ce",
  fg_bright = "#e0e2e6",
  muted = "#8b919b",
  comment = "#909499",
  subtle = "#4b5361",
  border = "#4f5764",
  indent = "#343943",
  scope = "#5b7184",

  -- Vivid accents are used sparingly, according to semantic role.
  red = "#e06c75",
  member = "#e06c75",
  orange = "#d19a66",
  yellow = "#e5c07b",
  green = "#98c379",
  cyan = "#56b6c2",
  blue = "#61afef",
  purple = "#c678dd",
  operator = "#c0c4cb",
  parameter = "#b9bec7",
}

local function groups(p)
  return {
    Normal = { bg = p.bg, fg = p.fg },

    -- Core syntax: ordinary identifiers become the visual resting point.
    Comment = { fg = p.comment, italic = true },
    SpecialComment = { fg = p.comment, italic = true },
    Constant = { fg = p.orange },
    String = { fg = p.green },
    Character = { fg = p.green },
    Number = { fg = p.orange },
    Float = { fg = p.orange },
    Boolean = { fg = p.orange },
    Identifier = { fg = p.fg },
    Function = { fg = p.blue },
    Statement = { fg = p.purple },
    Conditional = { fg = p.purple },
    Repeat = { fg = p.purple },
    Label = { fg = p.purple },
    Operator = { fg = p.operator },
    Keyword = { fg = p.purple },
    Exception = { fg = p.purple },
    PreProc = { fg = p.yellow },
    Include = { fg = p.purple },
    Define = { fg = p.purple },
    Macro = { fg = p.blue },
    PreCondit = { fg = p.yellow },
    Type = { fg = p.yellow },
    StorageClass = { fg = p.yellow },
    Structure = { fg = p.purple },
    Typedef = { fg = p.purple },
    Special = { fg = p.blue },
    SpecialChar = { fg = p.orange },
    Delimiter = { fg = p.operator },
    Error = { fg = p.red },
    Todo = { fg = p.yellow, bold = true },

    -- Treesitter and clangd semantic tokens.
    ["@variable"] = { fg = p.fg },
    ["@variable.builtin"] = { fg = p.yellow },
    ["@variable.parameter"] = { fg = p.parameter },
    ["@variable.member"] = { fg = p.member },
    ["@parameter"] = { fg = p.parameter },
    ["@field"] = { fg = p.member },
    ["@property"] = { fg = p.member },
    ["@constant"] = { fg = p.orange },
    ["@constant.builtin"] = { fg = p.orange },
    ["@module"] = { fg = p.yellow },
    ["@namespace"] = { fg = p.yellow },
    ["@type"] = { fg = p.yellow },
    ["@type.builtin"] = { fg = p.yellow },
    ["@type.definition"] = { fg = p.yellow },
    ["@type.qualifier"] = { fg = p.purple },
    ["@attribute"] = { fg = p.yellow },
    ["@function"] = { fg = p.blue },
    ["@function.call"] = { fg = p.blue },
    ["@function.builtin"] = { fg = p.cyan },
    ["@function.macro"] = { fg = p.blue },
    ["@function.method"] = { fg = p.blue },
    ["@function.method.call"] = { fg = p.blue },
    ["@constructor"] = { fg = p.yellow },
    ["@operator"] = { fg = p.operator },
    ["@keyword"] = { fg = p.purple },
    ["@keyword.function"] = { fg = p.purple },
    ["@keyword.operator"] = { fg = p.purple },
    ["@punctuation.delimiter"] = { fg = p.operator },
    ["@punctuation.bracket"] = { fg = p.operator },
    ["@punctuation.special"] = { fg = p.operator },
    ["@comment"] = { fg = p.comment, italic = true },
    ["@comment.error"] = { fg = p.red, bold = true },
    ["@comment.warning"] = { fg = p.yellow, bold = true },
    ["@comment.todo"] = { fg = p.blue, bold = true },
    ["@comment.note"] = { fg = p.cyan, bold = true },

    ["@lsp.type.class"] = { fg = p.yellow },
    ["@lsp.type.interface"] = { fg = p.yellow },
    ["@lsp.type.struct"] = { fg = p.yellow },
    ["@lsp.type.enum"] = { fg = p.yellow },
    ["@lsp.type.enumMember"] = { fg = p.orange },
    ["@lsp.type.typeParameter"] = { fg = p.yellow },
    ["@lsp.type.namespace"] = { fg = p.yellow },
    ["@lsp.type.parameter"] = { link = "@variable.parameter" },
    ["@lsp.type.property"] = { link = "@property" },
    ["@lsp.type.variable"] = { link = "@variable" },
    -- clangd represents an unqualified C++ member as a variable carrying
    -- the classScope modifier (for example: `total_points_evaluated`).
    ["@lsp.typemod.variable.classScope"] = { link = "@variable.member" },
    ["@lsp.typemod.variable.classScope.cpp"] = { link = "@variable.member" },
    ["@lsp.type.function"] = { link = "@function" },
    ["@lsp.type.method"] = { link = "@function.method" },
    ["@lsp.type.macro"] = { fg = p.orange },
    ["@lsp.type.keyword"] = { link = "@keyword" },
    ["@lsp.type.modifier"] = { fg = p.purple },

    -- Editor surfaces.
    CursorLine = { bg = p.bg_soft },
    CursorColumn = { bg = p.bg_soft },
    CursorLineNr = { fg = p.muted },
    LineNr = { fg = p.subtle },
    SignColumn = { bg = p.bg },
    FoldColumn = { bg = p.bg, fg = p.subtle },
    Folded = { bg = p.bg_soft, fg = p.muted },
    ColorColumn = { bg = p.bg_soft },
    Visual = { bg = p.bg_selection },
    Search = { bg = p.bg_search, fg = p.fg_bright },
    CurSearch = { bg = p.yellow, fg = p.bg },
    IncSearch = { bg = p.yellow, fg = p.bg },
    MatchParen = { bg = p.bg_soft, fg = p.yellow, bold = true },
    WinSeparator = { fg = p.border },
    NonText = { fg = p.subtle },
    Whitespace = { fg = p.indent },
    NormalFloat = { bg = p.bg_float, fg = p.fg },
    FloatBorder = { bg = p.bg_float, fg = p.border },
    FloatTitle = { bg = p.bg_float, fg = p.blue },
    Pmenu = { bg = p.bg_float, fg = p.fg },
    PmenuSel = { bg = p.bg_selection, fg = p.fg_bright },
    PmenuSbar = { bg = p.bg_soft },
    PmenuThumb = { bg = p.subtle },
    StatusLine = { bg = p.bg_status, fg = p.fg },
    StatusLineNC = { bg = p.bg_status, fg = p.muted },
    TabLine = { bg = p.bg_status, fg = p.muted },
    TabLineSel = { bg = p.bg, fg = p.fg_bright },
    TabLineFill = { bg = p.bg_status },

    -- Diagnostics remain distinct without coloured backgrounds.
    DiagnosticError = { fg = p.red },
    DiagnosticWarn = { fg = p.yellow },
    DiagnosticInfo = { fg = p.blue },
    DiagnosticHint = { fg = p.cyan },
    DiagnosticVirtualTextError = { fg = p.red },
    DiagnosticVirtualTextWarn = { fg = p.yellow },
    DiagnosticVirtualTextInfo = { fg = p.blue },
    DiagnosticVirtualTextHint = { fg = p.cyan },
    DiagnosticUnderlineError = { undercurl = true, sp = p.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = p.yellow },
    DiagnosticUnderlineInfo = { undercurl = true, sp = p.blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = p.cyan },
    DiagnosticUnnecessary = { fg = p.muted },
    DiagnosticDeprecated = { fg = p.muted, strikethrough = true },

    -- Diff and source-control colours are deliberately subdued.
    DiffAdd = { bg = "#2f3932" },
    DiffChange = { bg = "#38372f" },
    DiffDelete = { bg = "#3b2f33" },
    DiffText = { bg = "#34404a" },
    GitSignsAdd = { fg = p.green },
    GitSignsChange = { fg = p.yellow },
    GitSignsDelete = { fg = p.red },

    -- Long-file context and scope guides.
    SnacksIndent = { fg = p.indent },
    SnacksIndentScope = { fg = p.scope },
    SnacksIndentChunk = { fg = p.scope },
    TreesitterContext = { bg = p.bg, fg = p.fg },
    TreesitterContextLineNumber = { bg = p.bg, fg = p.subtle },
    TreesitterContextBottom = { underline = true, sp = p.indent },
    TreesitterContextSeparator = { fg = p.indent },

    -- Completion, documentation, and inline AI use one surface language.
    BlinkCmpMenu = { bg = p.bg_float, fg = p.fg },
    BlinkCmpMenuBorder = { bg = p.bg_float, fg = p.border },
    BlinkCmpMenuSelection = { bg = p.bg_selection, fg = p.fg_bright },
    BlinkCmpDoc = { bg = p.bg_float, fg = p.fg },
    BlinkCmpDocBorder = { bg = p.bg_float, fg = p.border },
    BlinkCmpSignatureHelp = { bg = p.bg_float, fg = p.fg },
    BlinkCmpSignatureHelpBorder = { bg = p.bg_float, fg = p.border },
    BlinkCmpLabel = { fg = p.fg },
    BlinkCmpLabelMatch = { fg = p.blue },
    BlinkCmpLabelDeprecated = { fg = p.muted, strikethrough = true },
    BlinkCmpSource = { fg = p.muted },
    BlinkCmpKindFunction = { fg = p.blue },
    BlinkCmpKindMethod = { fg = p.blue },
    BlinkCmpKindField = { fg = p.member },
    BlinkCmpKindProperty = { fg = p.member },
    BlinkCmpKindClass = { fg = p.yellow },
    BlinkCmpKindInterface = { fg = p.yellow },
    BlinkCmpKindStruct = { fg = p.yellow },
    BlinkCmpKindTypeParameter = { fg = p.yellow },
    BlinkCmpKindKeyword = { fg = p.purple },
    BlinkCmpKindConstant = { fg = p.orange },
    BlinkCmpKindValue = { fg = p.orange },
    BlinkCmpKindEnumMember = { fg = p.orange },
    BlinkCmpKindOperator = { fg = p.operator },
    BlinkCmpKindSnippet = { fg = p.green },
    ComplHint = { fg = p.subtle },
    CopilotSuggestion = { fg = p.subtle },
    LspInlayHint = { fg = p.subtle, bg = p.bg_soft },
  }
end

local function apply_lualine(p)
  local modes = {
    normal = p.blue,
    insert = p.green,
    visual = p.purple,
    replace = p.red,
    command = p.yellow,
    terminal = p.cyan,
  }
  for mode, accent in pairs(modes) do
    vim.api.nvim_set_hl(0, "lualine_a_" .. mode, { bg = accent, fg = p.bg, bold = true })
    vim.api.nvim_set_hl(0, "lualine_b_" .. mode, { bg = p.bg_soft, fg = accent })
    vim.api.nvim_set_hl(0, "lualine_c_" .. mode, { bg = p.bg_status, fg = p.fg })
  end
  vim.api.nvim_set_hl(0, "lualine_a_inactive", { bg = p.bg_status, fg = p.muted })
  vim.api.nvim_set_hl(0, "lualine_b_inactive", { bg = p.bg_status, fg = p.muted })
  vim.api.nvim_set_hl(0, "lualine_c_inactive", { bg = p.bg_status, fg = p.muted })
end

function M.apply()
  if vim.g.onedark_quiet_enabled == false then
    return
  end

  for name, spec in pairs(groups(M.palette)) do
    vim.api.nvim_set_hl(0, name, spec)
  end
  apply_lualine(M.palette)

  local p = M.palette
  local terminal = { p.bg, p.red, p.green, p.yellow, p.blue, p.purple, p.cyan, p.fg }
  for index, color in ipairs(terminal) do
    vim.g["terminal_color_" .. (index - 1)] = color
    vim.g["terminal_color_" .. (index + 7)] = color
  end
end

local function notify(enabled)
  vim.notify(enabled and "OneDark Quiet enabled" or "Original OneDark restored", vim.log.levels.INFO, {
    title = "Theme",
  })
end

local function load_onedark()
  require("onedarkpro.config").set_theme("onedark")
  require("onedarkpro").load()
end

function M.enable(opts)
  opts = opts or {}
  vim.g.onedark_quiet_enabled = true
  if opts.reload ~= false then
    load_onedark()
  end
  M.apply()
  if opts.notify ~= false then
    notify(true)
  end
end

function M.disable(opts)
  opts = opts or {}
  vim.g.onedark_quiet_enabled = false
  if opts.reload ~= false then
    load_onedark()
  end
  if opts.notify ~= false then
    notify(false)
  end
end

function M.toggle()
  if vim.g.onedark_quiet_enabled == false then
    M.enable()
  else
    M.disable()
  end
end

function M.status()
  local enabled = vim.g.onedark_quiet_enabled ~= false
  vim.notify(enabled and "OneDark Quiet is enabled" or "Original OneDark is enabled", vim.log.levels.INFO, {
    title = "Theme",
  })
end

function M.setup()
  if M._setup then
    return
  end
  M._setup = true

  vim.api.nvim_create_user_command("OneDarkQuietEnable", function()
    M.enable()
  end, { desc = "Enable the quieter OneDark palette", force = true })
  vim.api.nvim_create_user_command("OneDarkQuietDisable", function()
    M.disable()
  end, { desc = "Restore the original OneDark palette", force = true })
  vim.api.nvim_create_user_command("OneDarkQuietToggle", function()
    M.toggle()
  end, { desc = "Toggle the quieter OneDark palette", force = true })
  vim.api.nvim_create_user_command("OneDarkQuietStatus", function()
    M.status()
  end, { desc = "Show the current OneDark palette", force = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("onedark_quiet", { clear = true }),
    pattern = "onedark*",
    callback = function()
      if vim.g.onedark_quiet_enabled ~= false then
        M.apply()
      end
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = "onedark_quiet",
    pattern = "VeryLazy",
    callback = function()
      if vim.g.onedark_quiet_enabled ~= false then
        vim.schedule(M.apply)
      end
    end,
  })
end

return M
