local lush = require("lush")

-- Pablotuna: bottom-up high-contrast theme scaffold.
-- Reload while editing:
--   :PablotunaReload
-- One-shot reload command (works from any buffer):
--   :lua package.loaded["lush_theme.pablotuna"] = nil; vim.cmd.colorscheme("pablotuna")
return lush(function(injected_functions)
  local sym = injected_functions.sym

  -- Palette: start here and tune values.
  local c = {
    fg		  = "#f0ead6",
    bg		  = "#000000",
    hl		  = "#440044",
		almost_black = '#181818',
		gray = '#525252',

    olive_green   = "#6b8e23",
    light_olive   = "#7aa035",
    dark_olive    = "#656b2f",
    darkest_olive = "#333b0f",
    muted_green   = '#a2cd5a',
    magenta				= "#aa5588",
    off_yellow	  = "#d2c270",

    diag_red			= '#550000',
    diag_yellow	  = '#555500',
    diag_green	  = '#005500',
    diag_blue			= '#000055',
    diag_cyan			= '#005555',
    vline_fg      = '#ffffff',
  }

  return {
    -- Core baseline
    Normal			{ fg = c.fg, bg = c.bg },
    NormalNC		{ fg = c.fg, bg = c.bg },
    NormalFloat { fg = c.fg, bg = c.bg },
    SignColumn	{ fg = c.fg, bg = c.bg },
    EndOfBuffer { fg = c.dark_olive, bg = c.bg },

    -- Cursor / selection
    Visual { bg = c.hl, gui = 'underline' },
		CursorLine { bg = c.darkest_olive }, 

    -- Text classes
    Comment { fg = c.magenta, gui = 'italic' },
    Constant { fg = c.light_olive },
    Identifier { fg = c.fg },
    Statement { fg = c.off_yellow, gui = "italic" },
    PreProc { fg = c.off_yellow, gui = 'italic' },
    Type { fg = c.off_yellow },
    Special { fg = c.off_yellow, gui = "bold" },
    String { fg = c.muted_green },
    Function { fg = c.fg },
    pythonFunction { fg = c.fg },
    Keyword { fg = c.fg, gui = "italic" },
		Delimiter { fg = c.fg },
		Title { fg = c.olive_green, gui = "bold" },
    Operator { fg = c.fg },

    -- render-markdown.nvim: keep syntax fg from injected language, only tint code-block bg.
    RenderMarkdownCode { bg = c.almost_black },
    RenderMarkdownCodeBorder { fg = c.almost_black, bg = c.almost_black },
    RenderMarkdownCodeInfo { bg = c.almost_black, fg = c.gray },
    RenderMarkdownCodeInline { bg = c.almost_black },

    -- TypeScript: keep type usage styled as Type, but declarations as Normal.
    [sym"@lsp.type.interface"] = { fg = c.off_yellow },
    [sym"@lsp.type.type"] = { fg = c.off_yellow },
    [sym"@lsp.type.class"] = { fg = c.off_yellow },
    [sym"@lsp.type.interface.typescript"] = { fg = c.off_yellow },
    [sym"@lsp.type.type.typescript"] = { fg = c.off_yellow },
    [sym"@lsp.type.function.typescript"] = { fg = c.fg },
    [sym"@lsp.type.class.typescript"] = { fg = c.off_yellow },
    [sym"@function.call.typescript"] = { fg = c.fg },
    [sym"@function.call.tsx"] = { fg = c.fg },
    [sym"@variable"] = { fg = c.fg },
    [sym"@variable.parameter"] = { fg = c.fg },
    [sym"@function"] = { fg = c.fg },
    [sym"@function.call"] = { fg = c.fg },
    [sym"@function.method.call"] = { fg = c.light_olive },
    [sym"@variable.member"] = { fg = c.light_olive },
    [sym"@type"] = { fg = c.off_yellow },
    [sym"@type.builtin"] = { fg = c.off_yellow },
    [sym"@type.python"] = { fg = c.off_yellow },
    [sym"@type.builtin.python"] = { fg = c.off_yellow },
    [sym"@keyword"] = { fg = c.fg, gui = "italic" },
    [sym"@keyword.import"] = { fg = c.fg, gui = "italic" },
    [sym"@keyword.function"] = { fg = c.magenta, gui = "bold" },
    [sym"@keyword.repeat"] = { fg = c.fg, gui = "italic" },
    [sym"@keyword.operator"] = { fg = c.fg, gui = "italic" },
    [sym"@keyword.conditional"] = { fg = c.fg, gui = "italic" },
    [sym"@keyword.return"] = { fg = c.fg, gui = "italic" },
    [sym"@operator"] = { fg = c.fg },
    [sym"@punctuation.delimiter"] = { fg = c.fg },
    [sym"@punctuation.bracket"] = { fg = c.dark_olive },
    [sym"@function.python"] = { fg = c.fg },
    [sym"@function.call.python"] = { fg = c.fg },
    [sym"@method.python"] = { fg = c.fg },
    [sym"@method.call.python"] = { fg = c.fg },
    [sym"@variable.builtin.python"] = { fg = c.off_yellow },
    [sym"@module.python"] = { fg = c.fg },
    [sym"@keyword.python"] = { fg = c.fg, gui = "italic" },
    [sym"@keyword.function.python"] = { fg = c.magenta, gui = "bold" },
    [sym"@keyword.import.python"] = { fg = c.fg, gui = "italic" },
    [sym"@type.builtin.python"] = { fg = c.off_yellow },
    [sym"@lsp.type.type.python"] = { fg = c.off_yellow },
    [sym"@lsp.type.class.python"] = { fg = c.off_yellow },
    [sym"@lsp.type.typeParameter.python"] = { fg = c.off_yellow },
    [sym"@punctuation.bracket.typescript"] = { fg = c.dark_olive },
    [sym"@punctuation.bracket.tsx"] = { fg = c.dark_olive },
    [sym"@punctuation.bracket.python"] = { fg = c.dark_olive },
    [sym"@lsp.mod.declaration"] = { fg = c.fg, nocombine = true },
    [sym"@lsp.typemod.interface.declaration"] = { fg = c.fg, nocombine = true },
    [sym"@lsp.typemod.type.declaration"] = { fg = c.fg, nocombine = true },
    [sym"@lsp.typemod.class.declaration"] = { fg = c.fg, nocombine = true },
    [sym"@lsp.mod.declaration.typescript"] = { fg = c.fg, nocombine = true },
    [sym"@lsp.typemod.interface.declaration.typescript"] = { fg = c.fg, nocombine = true },
    [sym"@lsp.typemod.type.declaration.typescript"] = { fg = c.fg, nocombine = true },
    [sym"@lsp.typemod.class.declaration.typescript"] = { fg = c.fg, nocombine = true },
    typescriptInterfaceName { fg = c.fg },
    typescriptTypeName { fg = c.fg },
    pythonBuiltin { fg = c.off_yellow },
    pythonStatement { fg = c.fg },
    pythonDecorator { fg = c.dark_olive, gui = "italic" },

    -- UI
    LineNr { fg = c.dark_olive, bg = c.bg },
    StatusLine { fg = c.olive_green, bg = c.almost_black },
    StatusLineNC { fg = c.gray, bg = c.almost_black, gui = "italic" },
    --VertSplit { fg = c.gray_3, bg = c.bg },
    --WinSeparator { fg = c.gray_3, bg = c.bg },
    --Pmenu { fg = c.fg, bg = c.gray_2 },
    --PmenuSel { fg = c.bg, bg = c.fg },
    --TabLine { fg = c.fg, bg = c.gray_4 },
    --TabLineSel { fg = c.fg, bg = c.bg, gui = "bold" },
    --TabLineFill { fg = c.fg, bg = c.bg },

    -- Diagnostics
    DiagnosticError		{ bg = c.diag_red,    fg = c.fg,  gui = 'bold' },
    DiagnosticWarn		{ bg = c.diag_yellow, fg = c.fg,  gui = 'bold' },
    DiagnosticInfo		{ bg = c.diag_blue,   fg = c.fg,  gui = 'bold' },
    DiagnosticHint		{ bg = c.diag_cyan,   fg = c.fg,  gui = 'bold' },
    DiagnosticOk		{ bg = c.diag_green,  fg = c.fg,  gui = 'bold' },
    DiagnosticUnderlineError	{ sp = c.diag_red,    gui = "undercurl" },
    DiagnosticUnderlineWarn	{ sp = c.diag_yellow, gui = "undercurl" },
    DiagnosticUnderlineInfo	{ sp = c.diag_blue,   gui = "undercurl" },
    DiagnosticUnderlineHint	{ sp = c.diag_cyan,   gui = "undercurl" },
    DiagnosticUnnecessary	{ fg = c.fg, sp = c.dark_olive, gui = "italic,undercurl" },
    DiagnosticVirtualLinesError	{ bg = c.diag_red,    fg = c.vline_fg },
    DiagnosticVirtualLinesWarn	{ bg = c.diag_yellow, fg = c.vline_fg },
    DiagnosticVirtualLinesInfo	{ bg = c.diag_blue,   fg = c.vline_fg },
    DiagnosticVirtualLinesHint	{ bg = c.diag_cyan,   fg = c.vline_fg },
    DiagnosticVirtualLinesOk	{ bg = c.diag_green,  fg = c.vline_fg },
    DiagnosticVirtualLinesFill	{ bg = c.diag_red,    fg = c.vline_fg },
    DiagnosticVirtualLinesFillError { bg = c.diag_red,    fg = c.diag_red },
    DiagnosticVirtualLinesFillWarn  { bg = c.diag_yellow, fg = c.diag_yellow },
    DiagnosticVirtualLinesFillInfo  { bg = c.diag_blue,   fg = c.diag_blue },
    DiagnosticVirtualLinesFillHint  { bg = c.diag_cyan,   fg = c.diag_cyan },
		Directory { fg = c.off_yellow, gui = 'italic' },

    -- Diff
    --DiffAdd { fg = c.white, bg = "#1f5f1f" },
    --DiffChange { fg = c.white, bg = "#1f3f6f" },
    --DiffDelete { fg = c.white, bg = "#6f1f4f" },
    --DiffText { fg = c.black, bg = "#bfbfbf" },

    -- Treesitter entry examples (uncomment and tweak as needed)
    -- [sym"@comment"] { fg = c.gray_4 },
    -- [sym"@keyword"] { fg = c.yellow, gui = "bold" },
    -- [sym"@string"] { fg = c.green },
    -- [sym"@function"] { fg = c.cyan },
  }
end)

-- Complete highlight-group reference (captured from Neovim via getcompletion('', 'highlight')).
-- Use these names in this Lush spec to colorize each element.
-- Regenerate this list anytime with:
--   :lua vim.fn.writefile(vim.fn.getcompletion('', 'highlight'), '/tmp/nvim_highlight_groups.txt')
-- @attribute
-- @attribute.builtin
-- @boolean
-- @character
-- @character.special
-- @comment
-- @comment.error
-- @comment.note
-- @comment.todo
-- @comment.warning
-- @constant
-- @constant.builtin
-- @constructor
-- @diff.delta
-- @diff.minus
-- @diff.plus
-- @function
-- @function.builtin
-- @keyword
-- @label
-- @lsp.mod.deprecated
-- @lsp.type.class
-- @lsp.type.comment
-- @lsp.type.decorator
-- @lsp.type.enum
-- @lsp.type.enumMember
-- @lsp.type.event
-- @lsp.type.function
-- @lsp.type.interface
-- @lsp.type.keyword
-- @lsp.type.macro
-- @lsp.type.method
-- @lsp.type.modifier
-- @lsp.type.namespace
-- @lsp.type.number
-- @lsp.type.operator
-- @lsp.type.parameter
-- @lsp.type.property
-- @lsp.type.regexp
-- @lsp.type.string
-- @lsp.type.struct
-- @lsp.type.type
-- @lsp.type.typeParameter
-- @lsp.type.variable
-- @markup
-- @markup.heading
-- @markup.heading.1.delimiter.vimdoc
-- @markup.heading.2.delimiter.vimdoc
-- @markup.italic
-- @markup.link
-- @markup.strikethrough
-- @markup.strong
-- @markup.underline
-- @module
-- @module.builtin
-- @number
-- @number.float
-- @operator
-- @property
-- @punctuation
-- @punctuation.special
-- @string
-- @string.escape
-- @string.regexp
-- @string.special
-- @string.special.url
-- @tag
-- @tag.builtin
-- @type
-- @type.builtin
-- @variable
-- @variable.builtin
-- @variable.parameter.builtin
-- Added
-- Boolean
-- Changed
-- Character
-- ColorColumn
-- Comment
-- ComplMatchIns
-- Conceal
-- Conditional
-- Constant
-- CurSearch
-- Cursor
-- CursorColumn
-- CursorIM
-- CursorLine
-- CursorLineFold
-- CursorLineNr
-- CursorLineSign
-- Debug
-- Define
-- Delimiter
-- DiagnosticDeprecated
-- DiagnosticError
-- DiagnosticFloatingError
-- DiagnosticFloatingHint
-- DiagnosticFloatingInfo
-- DiagnosticFloatingOk
-- DiagnosticFloatingWarn
-- DiagnosticHint
-- DiagnosticInfo
-- DiagnosticOk
-- DiagnosticSignError
-- DiagnosticSignHint
-- DiagnosticSignInfo
-- DiagnosticSignOk
-- DiagnosticSignWarn
-- DiagnosticUnderlineError
-- DiagnosticUnderlineHint
-- DiagnosticUnderlineInfo
-- DiagnosticUnderlineOk
-- DiagnosticUnderlineWarn
-- DiagnosticUnnecessary
-- DiagnosticVirtualLinesError
-- DiagnosticVirtualLinesHint
-- DiagnosticVirtualLinesInfo
-- DiagnosticVirtualLinesOk
-- DiagnosticVirtualLinesWarn
-- DiagnosticVirtualTextError
-- DiagnosticVirtualTextHint
-- DiagnosticVirtualTextInfo
-- DiagnosticVirtualTextOk
-- DiagnosticVirtualTextWarn
-- DiagnosticWarn
-- DiffAdd
-- DiffChange
-- DiffDelete
-- DiffText
-- Directory
-- EndOfBuffer
-- Error
-- ErrorMsg
-- Exception
-- Float
-- FloatBorder
-- FloatFooter
-- FloatShadow
-- FloatShadowThrough
-- FloatTitle
-- FoldColumn
-- Folded
-- Function
-- Identifier
-- Ignore
-- IncSearch
-- Include
-- Keyword
-- Label
-- LineNr
-- LineNrAbove
-- LineNrBelow
-- LspCodeLens
-- LspCodeLensSeparator
-- LspInlayHint
-- LspReferenceRead
-- LspReferenceTarget
-- LspReferenceText
-- LspReferenceWrite
-- LspSignatureActiveParameter
-- Macro
-- MatchParen
-- ModeMsg
-- MoreMsg
-- MsgArea
-- MsgSeparator
-- NonText
-- Normal
-- NormalFloat
-- NormalNC
-- Number
-- NvimAnd
-- NvimArrow
-- NvimAssignment
-- NvimAssignmentWithAddition
-- NvimAssignmentWithConcatenation
-- NvimAssignmentWithSubtraction
-- NvimAugmentedAssignment
-- NvimBinaryMinus
-- NvimBinaryOperator
-- NvimBinaryPlus
-- NvimCallingParenthesis
-- NvimColon
-- NvimComma
-- NvimComparison
-- NvimComparisonModifier
-- NvimConcat
-- NvimConcatOrSubscript
-- NvimContainer
-- NvimCurly
-- NvimDict
-- NvimDivision
-- NvimDoubleQuote
-- NvimDoubleQuotedBody
-- NvimDoubleQuotedEscape
-- NvimDoubleQuotedUnknownEscape
-- NvimEnvironmentName
-- NvimEnvironmentSigil
-- NvimFigureBrace
-- NvimFloat
-- NvimIdentifier
-- NvimIdentifierKey
-- NvimIdentifierName
-- NvimIdentifierScope
-- NvimIdentifierScopeDelimiter
-- NvimInternalError
-- NvimInvalid
-- NvimInvalidAnd
-- NvimInvalidArrow
-- NvimInvalidAssignment
-- NvimInvalidAssignmentWithAddition
-- NvimInvalidAssignmentWithConcatenation
-- NvimInvalidAssignmentWithSubtraction
-- NvimInvalidAugmentedAssignment
-- NvimInvalidBinaryMinus
-- NvimInvalidBinaryOperator
-- NvimInvalidBinaryPlus
-- NvimInvalidCallingParenthesis
-- NvimInvalidColon
-- NvimInvalidComma
-- NvimInvalidComparison
-- NvimInvalidComparisonModifier
-- NvimInvalidConcat
-- NvimInvalidConcatOrSubscript
-- NvimInvalidContainer
-- NvimInvalidCurly
-- NvimInvalidDelimiter
-- NvimInvalidDict
-- NvimInvalidDivision
-- NvimInvalidDoubleQuote
-- NvimInvalidDoubleQuotedBody
-- NvimInvalidDoubleQuotedEscape
-- NvimInvalidDoubleQuotedUnknownEscape
-- NvimInvalidEnvironmentName
-- NvimInvalidEnvironmentSigil
-- NvimInvalidFigureBrace
-- NvimInvalidFloat
-- NvimInvalidIdentifier
-- NvimInvalidIdentifierKey
-- NvimInvalidIdentifierName
-- NvimInvalidIdentifierScope
-- NvimInvalidIdentifierScopeDelimiter
-- NvimInvalidLambda
-- NvimInvalidList
-- NvimInvalidMod
-- NvimInvalidMultiplication
-- NvimInvalidNestingParenthesis
-- NvimInvalidNot
-- NvimInvalidNumber
-- NvimInvalidNumberPrefix
-- NvimInvalidOperator
-- NvimInvalidOptionName
-- NvimInvalidOptionScope
-- NvimInvalidOptionScopeDelimiter
-- NvimInvalidOptionSigil
-- NvimInvalidOr
-- NvimInvalidParenthesis
-- NvimInvalidPlainAssignment
-- NvimInvalidRegister
-- NvimInvalidSingleQuote
-- NvimInvalidSingleQuotedBody
-- NvimInvalidSingleQuotedQuote
-- NvimInvalidSingleQuotedUnknownEscape
-- NvimInvalidSpacing
-- NvimInvalidString
-- NvimInvalidStringBody
-- NvimInvalidStringQuote
-- NvimInvalidStringSpecial
-- NvimInvalidSubscript
-- NvimInvalidSubscriptBracket
-- NvimInvalidSubscriptColon
-- NvimInvalidTernary
-- NvimInvalidTernaryColon
-- NvimInvalidUnaryMinus
-- NvimInvalidUnaryOperator
-- NvimInvalidUnaryPlus
-- NvimInvalidValue
-- NvimLambda
-- NvimList
-- NvimMod
-- NvimMultiplication
-- NvimNestingParenthesis
-- NvimNot
-- NvimNumber
-- NvimNumberPrefix
-- NvimOperator
-- NvimOptionName
-- NvimOptionScope
-- NvimOptionScopeDelimiter
-- NvimOptionSigil
-- NvimOr
-- NvimParenthesis
-- NvimPlainAssignment
-- NvimRegister
-- NvimSingleQuote
-- NvimSingleQuotedBody
-- NvimSingleQuotedQuote
-- NvimSingleQuotedUnknownEscape
-- NvimSpacing
-- NvimString
-- NvimStringBody
-- NvimStringQuote
-- NvimStringSpecial
-- NvimSubscript
-- NvimSubscriptBracket
-- NvimSubscriptColon
-- NvimTernary
-- NvimTernaryColon
-- NvimUnaryMinus
-- NvimUnaryOperator
-- NvimUnaryPlus
-- Operator
-- Pmenu
-- PmenuExtra
-- PmenuExtraSel
-- PmenuKind
-- PmenuKindSel
-- PmenuMatch
-- PmenuMatchSel
-- PmenuSbar
-- PmenuSel
-- PmenuThumb
-- PreCondit
-- PreProc
-- Question
-- QuickFixLine
-- RedrawDebugClear
-- RedrawDebugComposed
-- RedrawDebugNormal
-- RedrawDebugRecompose
-- Removed
-- Repeat
-- Search
-- SignColumn
-- SnippetTabstop
-- Special
-- SpecialChar
-- SpecialComment
-- SpecialKey
-- SpellBad
-- SpellCap
-- SpellLocal
-- SpellRare
-- Statement
-- StatusLine
-- StatusLineNC
-- StatusLineTerm
-- StatusLineTermNC
-- StorageClass
-- String
-- Structure
-- Substitute
-- TabLine
-- TabLineFill
-- TabLineSel
-- Tag
-- TermCursor
-- Title
-- Todo
-- Type
-- Typedef
-- Underlined
-- VertSplit
-- Visual
-- VisualNOS
-- WarningMsg
-- Whitespace
-- WildMenu
-- WinBar
-- WinBarNC
-- WinSeparator
-- lCursor
