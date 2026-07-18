return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "default",
      ["<CR>"] = { "accept", "fallback" },
      ["<Tab>"] = { "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },
    },
    completion = {
      list = {
        selection = {
          preselect = true,
          auto_insert = false,
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 100, -- Pops up instantly after 100 milliseconds
      },
      menu = {
        draw = {
          columns = {
            { "label", "label_description", gap = 1 },
            { "kind_icon", "kind" }, -- shows kind so you can see Variable vs Function
          },
        },
      },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "aspect_params" },
      per_filetype = {
        c = { "lsp", "path", "snippets" },
        cpp = { "lsp", "path", "snippets" },
        objc = { "lsp", "path", "snippets" },
        objcpp = { "lsp", "path", "snippets" },
      },
      providers = {
        lsp = {
          score_offset = 0,
          fallbacks = function()
            local semantic_only = { c = true, cpp = true, objc = true, objcpp = true }
            return semantic_only[vim.bo.filetype] and {} or { "buffer" }
          end,
        },
        path = {
          fallbacks = function()
            local semantic_only = { c = true, cpp = true, objc = true, objcpp = true }
            return semantic_only[vim.bo.filetype] and {} or { "buffer" }
          end,
        },
        aspect_params = {
          name = "ASPECT",
          module = "aspect_cmp", -- Points to the custom source file created above
          -- Only enable for aspect filetypes
          enabled = function()
            return vim.bo.filetype == "aspect" or vim.bo.filetype == "prm"
          end,
          score_offset = 10, -- Give these completions high priority
        },
      },
    },
  },
}
