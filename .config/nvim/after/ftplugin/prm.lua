-- ASPECT parameter files are not JSON. Never let LazyVim's global
-- format-on-save hand them to jsonls for whole-file reindentation.
vim.b.autoformat = false
