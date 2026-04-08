# styla.nvim

`styla.nvim` is a live colorscheme editor.

You keep a single theme data file with:

- `colors`
- `specs`
- `resolve`

Then you work from any normal editing buffer with:

- `:set_style` to inspect the token under the cursor and edit its candidate highlight groups
- `:update_styles` to browse highlight groups directly with glow preview
- `:add_color` to add or overwrite palette colors from anywhere
- `:new_theme [name]` to create a new theme file with default colors and empty specs

The live editor lets you:

- choose which candidate group to style
- edit `fg`, `bg`, or `sp`
- pick a palette color
- adjust H/S/L modifiers
- set style mixes like `bold+italic`
- reorder candidate priority for the current filetype and role
- browse known groups and blink matching text in the source window before editing

Changes are written permanently into the theme file and applied live to the current Neovim session.
