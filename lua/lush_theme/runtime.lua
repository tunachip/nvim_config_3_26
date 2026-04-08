local M = {}
local tbl_unpack = table.unpack or unpack

local function set_hl(name, spec)
	vim.api.nvim_set_hl(0, name, spec)
end

local function unload(modules)
	for _, module in ipairs(modules or {}) do
		if module and module ~= "" then
			package.loaded[module] = nil
		end
	end
end

function M.apply_overrides(c)
	set_hl("ZenBg", { fg = c.zen_backdrop_bg, bg = c.zen_backdrop_bg })
	set_hl("@type.builtin.python", { link = "Type" })

	set_hl("RenderMarkdownH1", {
	  fg = c.heading1_fg,
	  bg = c.heading1_bg,
	  bold = true,
	  cterm = {bold = true}
	})
	set_hl("RenderMarkdownH2", {
	  fg = c.heading2_fg,
	  bg = c.heading2_bg,
	  bold = true,
	  cterm = {bold = true}
	})
	set_hl("RenderMarkdownH3", {
	  fg = c.heading3_fg,
	  bg = c.heading3_bg,
	  bold = true,
	  cterm = {bold = true}
	})
	set_hl("RenderMarkdownH4", {
	  fg = c.heading3_fg,
	  bg = c.heading3_bg,
	  bold = true,
	  cterm = {bold = true}
	})
	set_hl("RenderMarkdownH5", {
	  fg = c.heading3_fg,
	  bg = c.heading3_bg,
	  bold = true,
	  cterm = {bold = true}
	})
	set_hl("RenderMarkdownH6", {
	  fg = c.heading3_fg,
	  bg = c.heading3_bg,
	  bold = true,
	  cterm = {bold = true}
	})

	set_hl("@markup.heading.1.markdown",{
		fg = c.markup_heading1_fg,
		bg = c.markup_heading_bg,
		bold = true,
		cterm = { bold = true }
	})
	set_hl("@markup.heading.2.markdown",
		{
		  fg = c.markup_heading2_fg,
		  bg = c.markup_heading_bg,
		  bold = true,
		  cterm = {bold = true}
		})
	set_hl("@markup.heading.3.markdown",
		{
		  fg = c.markup_heading3_fg,
		  bg = c.markup_heading_bg,
		  bold = true,
		  cterm = {bold = true}
		})
	set_hl("@markup.heading.4.markdown",
		{
		  fg = c.markup_heading3_fg,
		  bg = c.markup_heading_bg,
		  bold = true,
		  cterm = {bold = true}
		})
	set_hl("@markup.heading.5.markdown",
		{
		  fg = c.markup_heading3_fg,
		  bg = c.markup_heading_bg,
		  bold = true,
		  cterm = {bold = true}
		})
	set_hl("@markup.heading.6.markdown",
		{
		  fg = c.markup_heading3_fg,
		  bg = c.markup_heading_bg,
		  bold = true,
		  cterm = {bold = true}
		})

	set_hl("RenderMarkdownH1Bg", { bg = c.markup_heading_bg})
	set_hl("RenderMarkdownH2Bg", { bg = c.markup_heading_bg })
	set_hl("RenderMarkdownH3Bg", { bg = c.markup_heading_bg })
	set_hl("RenderMarkdownH4Bg", { bg = c.markup_heading_bg })
	set_hl("RenderMarkdownH5Bg", { bg = c.markup_heading_bg })
	set_hl("RenderMarkdownH6Bg", { bg = c.markup_heading_bg })

	set_hl("@type.builtin.typescript", { link = "Type" })
	set_hl("@type.typescript", { link = "Type" })

	set_hl("@punctuation.bracket", { fg = c.accent_dim_fg })
	set_hl("@punctuation.bracket.python", { link = "Special" })
	set_hl("@punctuation.bracket.typescript", { fg = c.accent_dim_fg })
	set_hl("@punctuation.bracket.tsx", { fg = c.accent_dim_fg })

	set_hl("@keyword.typescript", { fg = c.title_fg })
	set_hl("@keyword.type.typescript", { fg = c.accent_hot_fg, italic = true, cterm = { italic = true } })
	set_hl("@keyword.tsx", { fg = c.title_fg })
	set_hl("@keyword.import", { fg = c.accent_dim_fg })
	set_hl("@keyword.import.typescript", { fg = c.accent_dim_fg })
	set_hl("@keyword.import.tsx", { fg = c.accent_dim_fg })
	set_hl("@keyword.repeat.typescript", { fg = c.fg, italic = true, cterm = { italic = true } })
	set_hl("@keyword.operator.typescript", { fg = c.fg, italic = true, cterm = { italic = true } })
	set_hl("@keyword.conditional", { fg = c.accent_hot_fg })
	set_hl("@keyword.conditional.typescript", { fg = c.accent_hot_fg })
	set_hl("@keyword.conditional.tsx", { fg = c.accent_hot_fg })
	set_hl("@punctuation.special", { fg = c.accent_hot_fg })
	set_hl("@punctuation.special.typescript", { fg = c.accent_hot_fg, bold = true, cterm = { bold = true } })
	set_hl("@punctuation.special.tsx", { fg = c.accent_hot_fg })
	set_hl("@keyword.function.typescript", { fg = c.accent_hot_fg, bold = true, cterm = { bold = true } })
	set_hl("@keyword.function.tsx", { fg = c.accent_hot_fg, bold = true, cterm = { bold = true } })

	set_hl("@function.method.call", { link = "Constant" })
	set_hl("@function.method.call.typescript", { link = "Constant" })
	set_hl("@function.method.call.tsx", { link = "Constant" })
	set_hl("@variable.member", { link = "Constant" })
	set_hl("@variable.member.typescript", { link = "Constant" })
	set_hl("@variable.member.tsx", { link = "Constant" })

	set_hl("@lsp.type.variable.typescript", { link = "Constant" })
	set_hl("@lsp.type.variable.tsx", { link = "Constant" })
	set_hl("@lsp.mod.declaration.typescript", { link = "Type" })
	set_hl("@lsp.mod.declaration.tsx", { link = "Type" })
	set_hl("@lsp.mod.readonly.typescript", { link = "Type" })
	set_hl("@lsp.mod.readonly.tsx", { link = "Constant" })
	set_hl("@lsp.typemod.variable.declaration.typescript", { link = "Type" })
	set_hl("@lsp.typemod.variable.declaration.tsx", { link = "Type" })
	set_hl("@lsp.typemod.variable.readonly.typescript", { link = "Type" })
	set_hl("@lsp.typemod.variable.readonly.tsx", { link = "Constant" })
	set_hl("@lsp.type.property", { link = "Constant" })
	set_hl("@lsp.type.property.typescript", { link = "Constant" })
	set_hl("@lsp.type.property.tsx", { link = "Constant" })
	set_hl("@lsp.typemod.property.defaultLibrary", { link = "Constant" })
	set_hl("@lsp.typemod.property.defaultLibrary.typescript", { link = "Constant" })
	set_hl("@lsp.typemod.property.defaultLibrary.tsx", { link = "Constant" })
	set_hl("@lsp.typemod.property.readonly", { link = "Constant" })
	set_hl("@lsp.typemod.property.readonly.typescript", { link = "Constant" })
	set_hl("@lsp.typemod.property.readonly.tsx", { link = "Constant" })
	set_hl("@lsp.typemod.property.declaration", { link = "Normal", nocombine = true })
	set_hl("@lsp.typemod.property.declaration.typescript", { link = "Constant", nocombine = true })
	set_hl("@lsp.typemod.property.declaration.tsx", { link = "Normal", nocombine = true })
	set_hl("@boolean.typescript", { link = "Normal" })

	set_hl("@lsp.typemod.interface.declaration", { link = "Normal", nocombine = true })
	set_hl("@lsp.typemod.interface.declaration.typescript", { link = "Normal", nocombine = true })
	set_hl("@lsp.typemod.interface.declaration.tsx", { link = "Normal", nocombine = true })

	set_hl("@keyword.function.python", { fg = c.accent_hot_fg, bold = true, cterm = { bold = true } })
	set_hl("@function.call.python", { link = "Normal" })
	set_hl("@function.builtin.python", { link = "@function.call.python" })
end

function M.apply(opts)
	local ok_lush, lush = pcall(require, "lush")
	if not ok_lush then
		error("lush.nvim is required", 2)
	end

	unload({
		opts.palette_module,
		opts.theme_module,
		"lush_theme.semantic_theme_base",
		tbl_unpack(opts.extra_modules or {}),
	})

	local variant = opts.variant or "dark"
	local palette = opts.palette
	if not palette and opts.palette_module then
		local palette_source = require(opts.palette_module)
		if type(palette_source.get) == "function" then
			palette = palette_source.get(variant)
		else
			palette = type(palette_source) == "function" and palette_source(variant) or palette_source
		end
	end

	if palette and palette.background then
		vim.o.background = palette.background
	end

	local theme_source = require(opts.theme_module)
	local theme = type(theme_source) == "function" and theme_source(variant) or theme_source

	lush(theme)
	if palette then
		M.apply_overrides(palette)
	end

	if opts.colors_name then
		vim.g.colors_name = opts.colors_name
	end

	return palette
end

function M.setup_colorscheme(opts)
	local ok, err = pcall(M.apply, opts)
	if not ok then
		vim.notify(("%s: %s"):format(opts.colors_name or opts.theme_module, err), vim.log.levels.ERROR)
		return
	end

	if not opts.reload_command then
		return
	end

	pcall(vim.api.nvim_del_user_command, opts.reload_command)
	vim.api.nvim_create_user_command(opts.reload_command, function()
		M.apply(opts)
		vim.notify((opts.colors_name or opts.theme_module) .. " reloaded", vim.log.levels.INFO)
	end, { desc = "Reload " .. (opts.colors_name or opts.theme_module) })
end

return M
