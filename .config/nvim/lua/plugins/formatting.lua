return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    -- Merge with existing LazyVim opts
    opts.formatters_by_ft = vim.tbl_extend("force", opts.formatters_by_ft or {}, {
      cpp = { "astyle" },
      cc = { "astyle" },
      python = { "ruff_fix", "ruff_format" },
    })
    opts.formatters = vim.tbl_extend("force", opts.formatters or {}, {
      -- astyle_aspect = {
      --   command = "astyle",
      --   args = {
      --     "--options=" .. vim.fn.expand("~/.config/nvim/astyle.rc"),
      --   },
      --   stdin = false,
      -- },
      astyle = {
        command = "astyle",
        args = { "--options=" .. vim.fn.expand(vim.fn.stdpath("config") .. "/aspect_data/astyle.rc") },
      },
      ruff_format = {
        -- Ruff requires 'format' subcommand with args after it
        args = { "format", "--line-length", "120", "-" },
      },
      ruff_fix = {
        prepend_args = { "--unfixable=F401" },
      },
    })
    opts.format_on_save = {
      timeout_ms = 1000,
      lsp_fallback = true,
    }
  end,
}
