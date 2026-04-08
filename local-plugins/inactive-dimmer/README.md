# inactive-dimmer.nvim

Dims inactive Neovim windows by rebuilding highlight groups into a separate window-local highlight namespace.

## Features

- Dims non-floating inactive windows
- Rebuilds dimmed highlights after `:colorscheme`
- Includes `:InactiveDimEnable`, `:InactiveDimDisable`, and `:InactiveDimToggle`

## Installation

### lazy.nvim

```lua
{
  "your-name/inactive-dimmer.nvim",
  config = function()
    require("inactive_dimmer").setup({
      dim_factor = 0.65,
    })
  end,
}
```

## Options

```lua
require("inactive_dimmer").setup({
  dim_factor = 0.65,
})
```

- `dim_factor`: multiplier applied to foreground colors in inactive windows
