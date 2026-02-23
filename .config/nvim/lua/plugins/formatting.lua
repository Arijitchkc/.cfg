return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    -- Merge with existing LazyVim opts
    opts.formatters_by_ft = vim.tbl_extend("force", opts.formatters_by_ft or {}, {
      cpp = { "astyle_aspect" },
      c = { "astyle_aspect" },
      python = { "ruff_format" },
    })
    opts.formatters = vim.tbl_extend("force", opts.formatters or {}, {
      astyle_aspect = {
        command = "astyle",
        args = {
          "--options=" .. vim.fn.expand("~/.config/nvim/astyle.rc"),
        },
        stdin = false,
      },
      ruff_format = {
        -- Ruff requires 'format' subcommand with args after it
        args = { "format", "--line-length", "120", "-" },
      },
    })
  end,
}

