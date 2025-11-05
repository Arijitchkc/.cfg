local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s("set", {
    t("set "),
    i(1, "Parameter Name"),
    t(" = "),
    i(2, "Value"),
  }),
  s("subsection", {
    t("subsection "),
    i(1, "Section Name"),
    t({ "", "\t" }),
    i(0),
    t({ "", "end" }),
  }),
}
