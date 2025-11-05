return {
  "ojroques/nvim-osc52",
  config = function()
    local osc52 = require("osc52")
    osc52.setup({
      silent = true, -- don’t echo messages
    })

    -- Copy every yank to macOS clipboard, whether visual or not
    vim.api.nvim_create_autocmd("TextYankPost", {
      callback = function()
        if vim.v.event.operator == "y" and vim.v.event.regname == "" then
          osc52.copy_register("+")
        end
      end,
    })
  end,
}
