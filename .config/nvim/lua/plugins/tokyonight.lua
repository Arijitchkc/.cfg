return {
  {
    "folke/tokyonight.nvim",
    opts = {
      on_highlights = function(hl, _)
        -- Link the treesitter capture for Python docstrings to the Comment group.
        hl["@string.documentation.python"] = { link = "Comment" }
      end,
    },
  },
}
