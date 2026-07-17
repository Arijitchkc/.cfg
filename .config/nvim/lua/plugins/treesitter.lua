return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate", -- auto update parsers after install
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
        "cpp",
        "c",
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
  },

  -- Sticky scope header at top of window (great for long C++ files)
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      max_lines = 3, -- cap header height so it never eats the screen
      min_window_height = 20, -- skip on small windows
      multiline_threshold = 1, -- collapse multiline signatures to one line
      mode = "cursor", -- track context by cursor, not topline
      trim_scope = "outer", -- when over max_lines, drop the outermost scope
      separator = nil,
    },
    keys = {
      {
        "<leader>jc",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Jump to context (outer scope)",
      },
    },
  },
}
