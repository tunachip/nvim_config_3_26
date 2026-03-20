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
    fg			= "#ffffff",
    bg			= "#000000",
    black		= "#000000",
    white		= "#ffffff",

    gray_1	= "#121212",
    gray_2	= "#1f1f1f",
    gray_3	= "#2a2a2a",
    gray_4	= "#7f7f7f",

    red			= "#ff5555",
    green		= "#33ff00",
    yellow	= "#ffdd55",
    blue		= "#0055ff",
    magenta = "#ff44ff",
    dim_magenta = "#cc77cc",
    cyan		= "#00ffff",
    orange	= "#dd5500",
  }

  return {
    -- Core baseline
    Normal {
			fg = c.fg,
			bg = c.bg
		},
    NormalNC {
			fg = c.fg,
			bg = c.bg
		},
    NormalFloat {
			fg = c.fg,
			bg = c.gray_1
		},
    SignColumn {
			fg = c.fg,
			bg = c.bg
		},
    EndOfBuffer {
			fg = c.gray_4,
			bg = c.gray_1
		},

    -- Cursor / selection
    --Cursor { fg = c.bg, bg = c.fg },
    --CursorLine { bg = c.gray_2 },
    --CursorColumn { bg = c.gray_2 },
    --CursorLineNr { fg = c.yellow, bg = c.gray_2, gui = "bold" },
    --Visual { fg = c.bg, bg = c.gray_4 },
    --Search { fg = c.bg, bg = c.yellow },
    --IncSearch { fg = c.bg, bg = c.orange, gui = "bold" },

    -- Text classes
    Comment { fg = c.dim_magenta, gui = 'italic' },
    Constant { fg = c.yellow },
    Identifier { fg = c.yellow, gui = 'italic' },
    Statement { fg = c.cyan, gui = "italic" },
    PreProc { fg = c.cyan, gui = 'italic' },
    Type { fg = c.cyan },
    Special { fg = c.blue },
    String { fg = c.dim_magenta },
    Function { fg = c.blue },
    Keyword { fg = c.gray_4, gui = "italic" },
    --Operator { fg = c.blue },

    -- UI
    LineNr { fg = c.gray_4, bg = c.bg },
    StatusLine { fg = c.gray_4, bg = c.gray_1 },
    StatusLineNC { fg = c.gray_4, bg = c.gray_1 },
    --VertSplit { fg = c.gray_3, bg = c.bg },
    --WinSeparator { fg = c.gray_3, bg = c.bg },
    --Pmenu { fg = c.fg, bg = c.gray_2 },
    --PmenuSel { fg = c.bg, bg = c.fg },
    --TabLine { fg = c.fg, bg = c.gray_4 },
    --TabLineSel { fg = c.fg, bg = c.bg, gui = "bold" },
    --TabLineFill { fg = c.fg, bg = c.bg },

    -- Diagnostics
    DiagnosticError { fg = "#ff0000" },
    DiagnosticWarn { fg = "#ffff00" },
    DiagnosticInfo { fg = "#0000ff" },
    DiagnosticHint { fg = "#00ffff" },
    DiagnosticOk { fg = "#00ff00" },
    DiagnosticUnderlineError { sp = "#ff0000", gui = "undercurl" },
    DiagnosticUnderlineWarn { sp = "#ffff00", gui = "undercurl" },
    DiagnosticUnderlineInfo { sp = "#0000ff", gui = "undercurl" },
    DiagnosticUnderlineHint { sp = "#00ffff", gui = "undercurl" },

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
