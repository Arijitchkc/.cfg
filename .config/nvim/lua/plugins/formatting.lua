return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    opts = {
      formatters_by_ft = {
        python = { "black" }, -- or "ruff_format"
      },
    },
  },
}
