# style.nvim

`style.nvim` is an inspect-driven colorscheme editor.

You keep a single theme data file with:

- `colors`
- `specs`
- `resolve`

Then you run `:Style` from any normal editing buffer. The plugin inspects the
token under the cursor, gathers candidate Treesitter / LSP / syntax highlight
groups, and opens a side UI that lets you:

- choose which candidate group to style
- edit `fg`, `bg`, or `sp`
- pick a palette color
- adjust H/S/L modifiers
- set style mixes like `bold+italic`
- reorder candidate priority for the current filetype and role

Changes are written permanently into the theme file and applied live to the
current Neovim session.
