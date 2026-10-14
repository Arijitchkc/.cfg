return {
  {
    "lervag/vimtex",
    ft = { "tex", "latex", "plaintex", "bib" },
    init = function()
      -- Safety (not needed, but OK)
      vim.cmd("filetype plugin indent on")
      vim.cmd("syntax enable")

      -- macOS + Skim
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_activate = 1
      vim.g.vimtex_compiler_method = "latexmk"

      -- Never open the quickfix list by itself after a build (open it by hand with :copen or <leader>xq)
      vim.g.vimtex_quickfix_mode = 0

      -- Local leader for VimTeX mappings
      vim.g.maplocalleader = ","
    end,
  },
}
