return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "default",
      ["<CR>"] = { "accept", "fallback" },
      ["<Tab>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_next()
          end
        end,
        "fallback",
      },
      ["<S-Tab>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_prev()
          end
        end,
        "fallback",
      },
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
      providers = {
        lsp = {
          score_offset = 0,
          min_keyword_length = 0,
          -- Penalize long/complex function signatures in sorting
          transform_items = function(_, items)
            for _, item in ipairs(items) do
              -- Boost variables and fields, penalize complex functions
              if item.kind == 6 or item.kind == 5 then -- Variable=6, Field=5
                item.score_offset = (item.score_offset or 0) + 5
              elseif item.kind == 3 then -- Function=3
                -- Penalize if the label looks complex (many params)
                if item.label and item.label:find(",.*,") then
                  item.score_offset = (item.score_offset or 0) - 3
                end
              end
            end
            return items
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
