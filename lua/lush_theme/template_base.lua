local build_theme = require("lush_theme.semantic_theme_base")
local palettes = require("lush_theme.template_palette")

return function(variant)
  return build_theme(palettes.get(variant))
end
