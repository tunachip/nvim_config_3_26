local vim = vim

vim.cmd("hi clear")

if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end

vim.o.background = "dark"
vim.g.colors_name = "clean-dark"

local white = "#ffffff"
local black = "#000000"
local gray = "#808080"
local midgray = "#444444"
local darkgray = "#222222"

local function hi(group, opts)
	vim.api.nvim_set_hl(0, group, opts)
end

local function set_terminal_cursor_color(color)
	if vim.fn.has("nvim-0.10") == 1 then
		vim.api.nvim_ui_send(("\027]12;%s\027\\"):format(color))
	end
end

local normal = { fg = white, bg = black }
local cursorline = { fg = white, bg = darkgray }

set_terminal_cursor_color(gray)

for _, group in ipairs({
	"Normal",
	"NormalFloat",
	"ColorColumn",
	"Conceal",
	"Cursor",
	"CursorIM",
	"CursorColumn",
	"Directory",
	"EndOfBuffer",
	"ErrorMsg",
	"FloatBorder",
	"FoldColumn",
	"Folded",
	"Identifier",
	"LineNr",
	"MatchParen",
	"ModeMsg",
	"MoreMsg",
	"NonText",
	"Pmenu",
	"PmenuSbar",
	"PmenuSel",
	"PmenuThumb",
	"Question",
	"Search",
	"SignColumn",
	"SpecialKey",
	"SpellBad",
	"SpellCap",
	"SpellLocal",
	"SpellRare",
	"StatusLine",
	"StatusLineNC",
	"TabLine",
	"TabLineFill",
	"TabLineSel",
	"Title",
	"VertSplit",
	"Visual",
	"WarningMsg",
	"Whitespace",
	"WildMenu",
	"WinBar",
	"WinBarNC",
}) do
	hi(group, normal)
end

for _, group in ipairs({
	"CursorLine",
	"CursorLineNr",
}) do
	hi(group, cursorline)
end

for _, group in ipairs({
	"Constant",
	"String",
	"Character",
	"Number",
	"Boolean",
	"Float",
	"Function",
	"Statement",
	"Conditional",
	"Repeat",
	"Label",
	"Operator",
	"Keyword",
	"Exception",
	"PreProc",
	"Include",
	"Define",
	"Macro",
	"PreCondit",
	"Type",
	"StorageClass",
	"Structure",
	"Typedef",
	"Special",
	"SpecialChar",
	"Tag",
	"Delimiter",
	"SpecialComment",
	"Debug",
	"Underlined",
	"Ignore",
	"Error",
	"Todo",
	"Added",
	"Changed",
	"Removed",
}) do
	hi(group, { fg = white, bg = black })
end

for _, group in ipairs({
	"DiagnosticError",
	"DiagnosticWarn",
	"DiagnosticInfo",
	"DiagnosticHint",
	"DiagnosticOk",
	"DiagnosticVirtualTextError",
	"DiagnosticVirtualTextWarn",
	"DiagnosticVirtualTextInfo",
	"DiagnosticVirtualTextHint",
	"DiagnosticVirtualTextOk",
	"DiagnosticVirtualLinesError",
	"DiagnosticVirtualLinesWarn",
	"DiagnosticVirtualLinesInfo",
	"DiagnosticVirtualLinesHint",
	"DiagnosticVirtualLinesOk",
}) do
	hi(group, { fg = white, bg = black })
end

hi("CurSearch", { fg = black, bg = white })
hi("IncSearch", { fg = black, bg = white })
hi("Visual", { fg = black, bg = white })
hi("MatchParen", { fg = black, bg = white })
hi("MultipleCursorsCursor", { fg = black, bg = white })
hi("MultipleCursorsVisual", { fg = black, bg = gray })
hi("MultipleCursorsLockedCursor", { fg = white, bg = midgray })
hi("MultipleCursorsLockedVisual", { fg = white, bg = darkgray })
hi("CursorLine", { fg = white, bg = darkgray })
hi("CursorColumn", { fg = white, bg = black })
hi("CursorLineNr", { fg = white, bg = darkgray, bold = true })
hi("LineNr", { fg = gray, bg = black })
hi("NonText", { fg = gray, bg = black })
hi("Whitespace", { fg = gray, bg = black })
hi("EndOfBuffer", { fg = black, bg = black })
hi("Comment", { fg = gray, bg = black, italic = true })

hi("yamlBlockMappingKey", { fg = "#5599ff" })
hi("yamlNodeTag", { fg = "#5599ff" })

hi("DiagnosticUnderlineError", { undercurl = true, sp = white })
hi("DiagnosticUnderlineWarn", { undercurl = true, sp = white })
hi("DiagnosticUnderlineInfo", { undercurl = true, sp = white })
hi("DiagnosticUnderlineHint", { undercurl = true, sp = white })
hi("DiagnosticUnderlineOk", { undercurl = true, sp = white })

for _, group in ipairs({
	"@variable",
	"@variable.builtin",
	"@variable.member",
	"@variable.parameter",
	"@constant",
	"@constant.builtin",
	"@constant.macro",
	"@module",
	"@module.builtin",
	"@label",
	"@string",
	"@string.documentation",
	"@string.escape",
	"@string.regex",
	"@string.special",
	"@character",
	"@character.special",
	"@boolean",
	"@number",
	"@number.float",
	"@type",
	"@type.builtin",
	"@type.definition",
	"@attribute",
	"@attribute.builtin",
	"@property",
	"@function",
	"@function.builtin",
	"@function.call",
	"@function.macro",
	"@function.method",
	"@function.method.call",
	"@constructor",
	"@operator",
	"@keyword",
	"@keyword.function",
	"@keyword.operator",
	"@keyword.return",
	"@keyword.import",
	"@keyword.conditional",
	"@keyword.repeat",
	"@keyword.exception",
	"@keyword.type",
	"@keyword.modifier",
	"@punctuation",
	"@punctuation.delimiter",
	"@punctuation.bracket",
	"@punctuation.special",
	"@comment",
	"@comment.documentation",
	"@markup",
	"@markup.heading",
	"@markup.link",
	"@markup.link.url",
	"@markup.raw",
	"@markup.list",
	"@diff.plus",
	"@diff.minus",
	"@diff.delta",
	"@tag",
	"@tag.attribute",
	"@tag.delimiter",
}) do
	hi(group, { fg = white, bg = black })
end
