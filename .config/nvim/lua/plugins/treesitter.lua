return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate", -- auto update parsers after install
  lazy = false, -- load early (important for syntax)
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    ensure_installed = {
      "lua",
      "python",
      "bash",
      "json",
      "yaml",
      "markdown",
      "markdown_inline",
      "vim",
      "vimdoc",
    },

    sync_install = false,
    -- Auto install missing parsers when entering buffer
    auto_install = true,

    ignore_install = { "javascript" },

    highlight = {
      enable = true, -- syntax highlighting, yes
      additional_vim_regex_highlighting = false,
    },

    indent = { enable = true }, -- enable Tree-sitter indentation

    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn",
        node_incremental = "grn",
        scope_incremental = "grc",
        node_decremental = "grm",
      },
    },

    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
        },
      },
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
