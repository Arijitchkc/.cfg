return {
  "hrsh7th/nvim-cmp",
  lazy = false,
  priority = 1000, -- Give it high priority
  enabled = true, -- Crucial: force enable it
  opts = function(_, opts)
    local cmp = require("cmp")

    -- merge your mappings with existing ones
    opts.mapping = cmp.mapping.preset.insert({
      ["<Tab>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
      ["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<C-Space>"] = cmp.mapping.complete(),
    })
  end,
}
