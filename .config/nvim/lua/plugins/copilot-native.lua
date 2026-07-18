return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      require("config.copilot_native").setup()
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, math.min(2, #opts.sections.lualine_x + 1), {
        function()
          return require("config.copilot_native").statusline()
        end,
        cond = function()
          return require("config.copilot_native").statusline() ~= ""
        end,
      })
    end,
  },
}
