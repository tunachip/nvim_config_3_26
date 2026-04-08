local build_theme = require("lush_theme.semantic_theme_base")
local palettes = require("lush_theme.carbon_palettes")

return function(variant)
  return build_theme(palettes.get(variant))
end
