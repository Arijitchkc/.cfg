return {
  {
    "olimorris/onedarkpro.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      theme = "onedark",
      styles = { comments = "italic" },
    },

    config = function(_, opts)
      local onedark = require("onedarkpro")
      onedark.setup(opts)
      vim.cmd("colorscheme onedark")

      local quiet = require("config.onedark_quiet")
      quiet.setup()
      quiet.enable({ reload = false, notify = false })

      local themes = { "onedark", "onedark_dark", "onedark_vivid" }
      local index = 1

      vim.keymap.set("n", "<leader>tt", function()
        quiet.disable({ reload = false, notify = false })
        index = index % #themes + 1
        local next = themes[index]
        require("onedarkpro.config").set_theme(next)
        onedark.load()
        print("Theme → " .. next)
      end, { desc = "Toggle OneDarkPro Theme" })

      vim.keymap.set("n", "<leader>tq", quiet.toggle, { desc = "Toggle OneDark Quiet" })
    end,
  },

  -- onedark is the only colorscheme in use; skip the others LazyVim bundles
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
}
