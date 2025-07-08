return {
  "ojroques/nvim-osc52",
  config = function()
    require("osc52").setup({ silent = true })
    vim.api.nvim_create_autocmd("TextYankPost", {
      callback = function()
        if not vim.v.event.visual then
          return
        end
        require("osc52").copy_register('"')
      end,
    })
  end,
}
