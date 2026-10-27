return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    opts = {
      -- Markdown remains plain text until rendering is explicitly requested.
      enabled = false,
      render_modes = { "n", "c", "t" },
      max_file_size = 10.0,
      anti_conceal = {
        enabled = true,
      },
      heading = {
        sign = false,
        icons = {},
      },
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      latex = {
        enabled = true,
        converter = { "utftex", "latex2text" },
        inline = true,
        block = true,
        position = "center",
      },
    },
    keys = {
      {
        "<leader>mp",
        function()
          require("render-markdown").preview()
        end,
        ft = "markdown",
        desc = "Markdown Preview (split)",
      },
      {
        "<leader>mr",
        function()
          require("render-markdown").buf_toggle()
        end,
        ft = "markdown",
        desc = "Markdown Render Toggle",
      },
    },
  },
}
