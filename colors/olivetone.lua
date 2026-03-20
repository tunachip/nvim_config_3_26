vim.o.background = "dark"

local ok_lush, lush = pcall(require, "lush")
if not ok_lush then
  vim.notify("pablotuna: lush.nvim is required", vim.log.levels.ERROR)
  return
end

local function apply()
  package.loaded["lush_theme.olivetone"] = nil
  local theme = require("lush_theme.olivetone")
  lush(theme)
  -- Keep Python builtin type hints (e.g. int/str/list) aligned with Type.
  vim.api.nvim_set_hl(0, "@type.builtin.python", { link = "Type" })
  -- render-markdown heading palette: almost black background, green foregrounds.
  vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = "#f0ead6", bg = "#aa5588", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = "#181818", bg = "#d2c270", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = "#6b8e23", bg = "#181818", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = "#6b8e23", bg = "#181818", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = "#6b8e23", bg = "#181818", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = "#6b8e23", bg = "#181818", bold = true, cterm = { bold = true } })
  -- Full markdown heading text (treesitter captures), not just render-markdown symbols.
  vim.api.nvim_set_hl(0, "@markup.heading.1.markdown", { fg = "#aa5588", bg = "#181818", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "@markup.heading.2.markdown", { fg = "#d2c270", bg = "#181818", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "@markup.heading.3.markdown", { fg = "#6b8e23", bg = "#181818", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "@markup.heading.4.markdown", { fg = "#6b8e23", bg = "#181818", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "@markup.heading.5.markdown", { fg = "#6b8e23", bg = "#181818", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "@markup.heading.6.markdown", { fg = "#6b8e23", bg = "#181818", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#181818" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#181818" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#181818" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "#181818" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "#181818" })
  vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "#181818" })
  -- Keep TypeScript builtin type hints (e.g. string/number/void) aligned with Type.
  vim.api.nvim_set_hl(0, "@type.builtin.typescript", { link = "Type" })
  vim.api.nvim_set_hl(0, "@type.typescript", { link = "Type" })
  -- Keep brackets dark olive even when runtime links them to Delimiter.
  vim.api.nvim_set_hl(0, "@punctuation.bracket", { fg = "#656b2f" })
  vim.api.nvim_set_hl(0, "@punctuation.bracket.python", { link = "Special" })
  vim.api.nvim_set_hl(0, "@punctuation.bracket.typescript", { fg = "#656b2f" })
  vim.api.nvim_set_hl(0, "@punctuation.bracket.tsx", { fg = "#656b2f" })
  -- TS keyword policy: general keywords fg+italic, function keyword magenta+bold.
  vim.api.nvim_set_hl(0, "@keyword.typescript", { fg = "#f0ead6", italic = true, cterm = { italic = true } })
  vim.api.nvim_set_hl(0, "@keyword.tsx", { fg = "#f0ead6", italic = true, cterm = { italic = true } })
  vim.api.nvim_set_hl(0, "@keyword.typescript", { fg = "#6b8e23" })
  vim.api.nvim_set_hl(0, "@keyword.tsx", { fg = "#6b8e23" })
  vim.api.nvim_set_hl(0, "@keyword.import", { fg = "#656b2f" })
  vim.api.nvim_set_hl(0, "@keyword.import.typescript", { fg = "#656b2f" })
  vim.api.nvim_set_hl(0, "@keyword.import.tsx", { fg = "#656b2f" })
  vim.api.nvim_set_hl(0, "@keyword.repeat.typescript", { fg = "#f0ead6", italic = true, cterm = { italic = true } })
  vim.api.nvim_set_hl(0, "@keyword.operator.typescript", { fg = "#f0ead6", italic = true, cterm = { italic = true } })
  vim.api.nvim_set_hl(0, "@keyword.conditional", { fg = "#aa5588" })
  vim.api.nvim_set_hl(0, "@keyword.conditional.typescript", { fg = "#aa5588" })
  vim.api.nvim_set_hl(0, "@keyword.conditional.tsx", { fg = "#aa5588" })
  vim.api.nvim_set_hl(0, "@punctuation.special", { fg = "#aa5588" })
  vim.api.nvim_set_hl(0, "@punctuation.special.typescript", { fg = "#aa5588" })
  vim.api.nvim_set_hl(0, "@punctuation.special.tsx", { fg = "#aa5588" })
  vim.api.nvim_set_hl(0, "@keyword.function.typescript", { fg = "#aa5588", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "@keyword.function.tsx", { fg = "#aa5588", bold = true, cterm = { bold = true } })
  -- TS/JS dotted members and method calls (e.g. .log, .length) match Constant color.
  vim.api.nvim_set_hl(0, "@function.method.call", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@function.method.call.typescript", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@function.method.call.tsx", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@variable.member", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@variable.member.typescript", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@variable.member.tsx", { link = "Constant" })
  -- LSP semantic tokens can override treesitter members; pin TS properties to Constant.
  vim.api.nvim_set_hl(0, "@lsp.type.property", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@lsp.type.property.typescript", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@lsp.type.property.tsx", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.property.defaultLibrary", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.property.defaultLibrary.typescript", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.property.defaultLibrary.tsx", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.property.readonly", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.property.readonly.typescript", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.property.readonly.tsx", { link = "Constant" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.property.declaration", { link = "Normal", nocombine = true })
  vim.api.nvim_set_hl(0, "@lsp.typemod.property.declaration.typescript", { link = "Normal", nocombine = true })
  vim.api.nvim_set_hl(0, "@lsp.typemod.property.declaration.tsx", { link = "Normal", nocombine = true })
  -- Interface declarations should use fg (Normal), not type color.
  vim.api.nvim_set_hl(0, "@lsp.typemod.interface.declaration", { link = "Normal", nocombine = true })
  vim.api.nvim_set_hl(0, "@lsp.typemod.interface.declaration.typescript", { link = "Normal", nocombine = true })
  vim.api.nvim_set_hl(0, "@lsp.typemod.interface.declaration.tsx", { link = "Normal", nocombine = true })
  -- Python function keyword/calls policy.
  vim.api.nvim_set_hl(0, "@keyword.function.python", { fg = "#aa5588", bold = true, cterm = { bold = true } })
  vim.api.nvim_set_hl(0, "@function.call.python", { link = "Normal" })
  vim.api.nvim_set_hl(0, "@function.builtin.python", { link = "@function.call.python" })
  vim.g.colors_name = "olivetone"
end

apply()

pcall(vim.api.nvim_del_user_command, "OliveToneReload")
vim.api.nvim_create_user_command("OliveToneReload", function()
  apply()
  vim.notify("olivetone reloaded", vim.log.levels.INFO)
end, { desc = "Reload the olivetone colorscheme" })
