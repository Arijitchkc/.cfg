-- Polish a few snacks.nvim modules (LazyVim already loads snacks; we just extend opts)
return {
  "folke/snacks.nvim",
  opts = {
    indent = {
      enabled = true,
      indent = { char = "│" },
      scope = { enabled = true, char = "│" },
      animate = { enabled = vim.g.snacks_animate ~= false },
    },
    styles = {
      notification = { border = "rounded" },
      lazygit = { border = "rounded" },
    },
  },
}
