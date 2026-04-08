local palettes = require("lush_theme.olivetone_palettes")
local build_theme = require("lush_theme.semantic_theme_base")

return function(variant)
  return build_theme(palettes.get(variant))
end
