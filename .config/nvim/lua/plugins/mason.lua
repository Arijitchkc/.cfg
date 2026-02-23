local plugins = {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "pyright",
      },
    },
  },
}
return plugins
