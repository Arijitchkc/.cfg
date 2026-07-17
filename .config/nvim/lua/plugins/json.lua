return {
  "VPavliashvili/json-nvim",
  ft = "json", -- only load for json filetype
  config = function()
    vim.keymap.set("n", "<leader>jff", "<cmd>JsonFormatFile<cr>")
    vim.keymap.set("n", "<leader>jmf", "<cmd>JsonMinifyFile<cr>")
  end,
}
