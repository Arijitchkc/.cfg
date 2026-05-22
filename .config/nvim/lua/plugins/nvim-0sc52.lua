return {
  "ojroques/nvim-osc52",
  event = "VeryLazy",
  config = function()
    local osc52 = require("osc52")
    osc52.setup({
      silent = true,
      -- This is the secret sauce for TMUX on HPC
      tmux_passthrough = true, 
    })

    -- Copy on yank
    vim.api.nvim_create_autocmd("TextYankPost", {
      callback = function()
        if vim.v.event.operator == "y" then
          osc52.copy_register(vim.v.event.regname)
        end
      end,
    })
  end,
}
