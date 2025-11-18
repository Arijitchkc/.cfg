return {
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

    local themes = { "onedark", "onedark_dark", "onedark_vivid", "onedark_dark_vivid" }
    local index = 1

    vim.keymap.set("n", "<leader>tt", function()
      index = index % #themes + 1
      local next = themes[index]
      onedark.load_theme(next)
      print("Theme → " .. next)
    end, { desc = "Toggle OneDarkPro Theme" })
  end,
}
