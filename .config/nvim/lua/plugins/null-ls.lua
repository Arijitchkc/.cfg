return {
  "nvimtools/none-ls.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.diagnostics.checkstyle.with({
          command = "aspect-autotype",
          args = { "--check", "--stdin" },
          filetypes = { "aspectprm" },
        }),
      },
    })
  end,
}
