local vim = vim

require("lazy").setup({
	{ -- treesitter
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
	},

	{
		"epwalsh/obsidian.nvim",
		version = "*",
		lazy = true,
		ft = "markdown",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		opts = {
			workspaces = {
				{
					name = "personal",
					path = "~/vaults/personal",
				},
				{
					name = "work",
					path = "~/vaults/work",
				},
			},
		},
	},

	{ -- icons
		"nvim-tree/nvim-web-devicons",
		opts = {}
	},

	{ -- oil
		'tunachip/oil.nvim',
		lazy = false,
		dependancies = { 'nvim-tree/nvim-web-devicons' },
		config = function()
			require('oil').setup({
				default_file_explorer = true,
				skip_confirm_for_simple_edits = true,
				view_options = { show_hidden = true },
				columns = { "icon" },
				preview = { vertical = true, splits = "botright" },
				keymaps = {
					["<C-h>"] = false,
					["<C-s>"] = false,
				},
			})
		end
	},

	{
		'stevearc/conform.nvim',
		opts = {},
		config = function()
			vim.api.nvim_create_user_command("Format", function(args)
				local range = nil
				if args.count ~= -1 then
					local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
					range = { start = { args.line1, 0 }, ["end"] = { args.line2, end_line:len() } }
				end
				require("conform").format({ async = true, lsp_format = "fallback", range = range })
			end, { range = true })
		end,
	},

	{
		"brenton-leighton/multiple-cursors.nvim",
		version = "*",
		opts = {},
	},

	{ -- telescope
		"nvim-telescope/telescope.nvim",
		version = "*",
		lazy = false,
		dependencies = {
			'nvim-lua/plenary.nvim',
			'nvim-lua/popup.nvim',
			{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
			{ 'nvim-telescope/telescope-github.nvim' },
			{ 'nvim-telescope/telescope-media-files.nvim' },
			{ 'nvim-telescope/telescope-symbols.nvim' },
		},
		config = function()
			local telescope = require("telescope")
			local action_state = require("telescope.actions.state")
			local themes = require("telescope.themes")
			local ivy_height = 0.5

			local function toggle_ivy_fullscreen(prompt_bufnr)
				local picker = action_state.get_current_picker(prompt_bufnr)
				if not picker or picker.layout_strategy ~= "bottom_pane" then
					return
				end

				picker.layout_config = picker.layout_config or {}
				picker.layout_config.bottom_pane = picker.layout_config.bottom_pane or {}

				local current_height = picker.layout_config.height
				local is_fullscreen = type(current_height) == "table" and current_height.padding == 0
				local new_height = is_fullscreen and ivy_height or { padding = 0 }

				picker.layout_config.height = new_height
				picker.layout_config.bottom_pane.height = new_height
				picker:full_layout_update()
			end

			telescope.setup({
				defaults = vim.tbl_deep_extend("force", themes.get_ivy({
					layout_config = {
						height = ivy_height,
					},
				}), {
					mappings = {
						i = {
							["<C-f>"] = toggle_ivy_fullscreen,
						},
						n = {
							["<C-f>"] = toggle_ivy_fullscreen,
						},
					},
					path_display = { "smart" },
					sorting_strategy = "ascending",
				}),
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
					media_files = {
						filetypes = { "png", "webp", "jpg", "jpeg", },
						find_cmd = "rg",
					},
				},
			})

			pcall(telescope.load_extension, "fzf")
		end,
	},

	{ -- gitsigns
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	},

	{
		"tunachip/fold-up.nvim",
		config = function()
			require("fold-up").setup({
				fold_command = "Fold",
				unfold_command = "Unfold",
			})
		end,
	},

	{ -- minischeme
		dir = "~/Development/minischeme.nvim",
		priority = 1000,
		config = function()
			require("minischeme").setup()

			for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "ColorScheme" })) do
				if autocmd.desc == "Reapply the active minischeme after base colorscheme changes" then
					vim.api.nvim_del_autocmd(autocmd.id)
				end
			end
		end,
	},

	{ -- surround
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({
				aliases = {
					["q"] = { "'", '"', "`" },
					["b"] = { ")", "]", "}" },
				},
				highlight = { duration = 0 },
			})
		end,
	},

	{ -- autopairs
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup({
				disable_filetype = { "TelescopePrompt" },
				enable_afterquote = true,
				enable_check_bracket_line = true,
			})
			local rules, Rule = pcall(require, "nvim-autopairs.rule")
			if not rules then return end
			require("nvim-autopairs").add_rules({
				Rule("__", "__", "python")
						:with_pair(
							function(opts)
								local prev = opts.prev_char or ""
								if prev:match("%w") then
									return false
								end
								return true
							end
						)
						:with_move(
							function(opts)
								return opts.next_char == "_"
							end
						)
						:use_key("_"),
			})
		end,
	},

	{ -- align
		"rrethy/nvim-align",
		cmd = "Align",
		keys = { "ga", "gA" },
		config = function()
			require("nvim-align").setup({
				preview = true,
				default_spacing = 1,
				default_jit = false,
				keymaps = { start = "ga", stop = "gA" },
			})
		end,
	},

	{ -- yamicon
		dir = "~/Development/yamicon",
		priority = 900,
		config = function()
			require("yamicon").setup({})
		end,
	},

	{ -- bug chaser
		dir = "~/Development/bug-chaser.nvim",
		config = function()
			local function get_hl(name)
				local ok, hl = pcall(
					vim.api.nvim_get_hl, 0,
					{ name = name, link = false }
				)
				if not ok or not hl or vim.tbl_isempty(hl) then
					return nil
				end
				return hl
			end

			local function first_hl(names)
				for _, name in ipairs(names) do
					local hl = get_hl(name)
					if hl then
						return hl
					end
				end
			end

			local function set_bug_chaser_highlights()
				local normal = get_hl("Normal") or {}
				local severities = {
					Error = {
						"DiagnosticVirtualLinesError",
						"DiagnosticVirtualTextError",
						"DiagnosticError",
						"ErrorMsg"
					},
					Warn = {
						"DiagnosticVirtualLinesWarn",
						"DiagnosticVirtualTextWarn",
						"DiagnosticWarn",
						"WarningMsg"
					},
					Info = {
						"DiagnosticVirtualLinesInfo",
						"DiagnosticVirtualTextInfo",
						"DiagnosticInfo",
						"MoreMsg"
					},
					Hint = {
						"DiagnosticVirtualLinesHint",
						"DiagnosticVirtualTextHint",
						"DiagnosticHint",
						"Question"
					},
				}

				for suffix, groups in pairs(severities) do
					local source = first_hl(groups) or {}
					local fg = source.fg or normal.fg
					local bg = source.bg or normal.bg

					vim.api.nvim_set_hl(0, "BugChaserDiagnosticVirtualLine" .. suffix, {
						fg = fg,
						bg = bg,
						bold = source.bold,
						italic = source.italic,
						underline = source.underline,
						undercurl = source.undercurl,
					})
					vim.api.nvim_set_hl(0, "BugChaserDiagnosticVirtualFill" .. suffix, {
						fg = bg,
						bg = bg,
					})
				end
			end

			require("bug_chaser").setup({
				diagnostics = { virtual_lines = { enabled = true, } },
				terminal = { focus = true, height = 0.50 },
				summary = { enabled = false },
			})
			set_bug_chaser_highlights()
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup(
					"BugChaserThemeOverrides", { clear = true }
				),
				callback = set_bug_chaser_highlights,
			})
		end,
	},

	{ -- casket
		dir = "~/Development/casket.nvim",
		config = function()
			require("casket").setup({
				auto = {
					enabled = false,
					mode = "repair",
					events = { 'BufWritePre' },
				},
				profiles = {
					lua = { variable = 'camelCase' },
				},
			})
		end,
	},

	{ -- tmux navigator
		"christoomey/vim-tmux-navigator",
		lazy = true,
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
		},
		init = function()
			vim.g.tmux_navigator_no_mappings = 1
		end,
	},

	{ -- open
		dir = "~/Development/open.nvim",
		config = function()
			require("open").setup({
				launch = {
					default_mode = "auto",
					port = 8123,
				},
			})
		end,
	},

	{ -- mason
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = {},
	},

	{ -- mason lsp config
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mason-lspconfig").setup({
				automatic_enable = true,
			})
		end,
	},
	{
		"iamcco/markdown-preview.nvim",
		cmd = {
			"MarkdownPreviewToggle",
			"MarkdownPreview",
			"MarkdownPreviewStop",
		},
		ft = { "markdown" },
		build = "cd app && ./install.sh",
		init = function()
			local css_dir = vim.fn.stdpath("cache") .. "/markdown-preview.nvim"
			vim.g.mkdp_markdown_css = css_dir .. "/colorscheme.css"
			vim.g.mkdp_highlight_css = css_dir .. "/highlight.css"
			vim.g.mkdp_theme = vim.o.background == "light" and "light" or "dark"
		end,
		config = function()
			local css_dir = vim.fn.stdpath("cache") .. "/markdown-preview.nvim"
			local markdown_css = css_dir .. "/colorscheme.css"
			local highlight_css = css_dir .. "/highlight.css"

			local function current_hl_namespace()
				if vim.api.nvim_win_get_hl_ns == nil then
					return 0
				end

				local ok, ns = pcall(vim.api.nvim_win_get_hl_ns, 0)
				if ok and type(ns) == "number" and ns >= 0 then
					return ns
				end

				return 0
			end

			local function get_hl(name)
				local ok, hl = pcall(
					vim.api.nvim_get_hl,
					current_hl_namespace(),
					{ name = name, link = false }
				)
				if not ok or not hl or vim.tbl_isempty(hl) then
					ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
				end
				if not ok or not hl or vim.tbl_isempty(hl) then
					return {}
				end
				return hl
			end

			local function color(value, fallback)
				if type(value) ~= "number" then
					return fallback
				end
				return ("#%06x"):format(value)
			end

			local function first_color(groups, key, fallback)
				for _, group in ipairs(groups) do
					local hl = get_hl(group)
					if type(hl[key]) == "number" then
						return color(hl[key], fallback)
					end
				end
				return fallback
			end

			local function write_preview_css()
				local normal = get_hl("Normal")
				local bg = color(normal.bg, "#000000")
				local fg = color(normal.fg, "#ffffff")
				local muted = first_color({ "Comment", "LineNr" }, "fg", fg)
				local accent = first_color({ "Title", "Statement", "Special" }, "fg", fg)
				local link = first_color({ "Underlined", "Directory", "String" }, "fg", accent)
				local border = first_color({ "LineNr", "FloatBorder" }, "fg", muted)
				local code_bg = first_color({ "CursorLine", "NormalFloat", "SignColumn" }, "bg", bg)
				local selection = first_color({ "Visual" }, "bg", code_bg)
				local string = first_color({ "String" }, "fg", fg)
				local constant = first_color({ "Constant", "Number" }, "fg", fg)
				local keyword = first_color({ "Keyword", "Statement" }, "fg", fg)
				local type_color = first_color({ "Type" }, "fg", fg)
				local func = first_color({ "Function", "Identifier" }, "fg", fg)
				local color_scheme = vim.o.background == "light" and "light" or "dark"

				vim.fn.mkdir(css_dir, "p")
				vim.fn.writefile({
					":root {",
					("  color-scheme: %s;"):format(color_scheme),
					("  --mkdp-bg: %s;"):format(bg),
					("  --mkdp-fg: %s;"):format(fg),
					("  --mkdp-muted: %s;"):format(muted),
					("  --mkdp-accent: %s;"):format(accent),
					("  --mkdp-link: %s;"):format(link),
					("  --mkdp-border: %s;"):format(border),
					("  --mkdp-code-bg: %s;"):format(code_bg),
					("  --mkdp-selection: %s;"):format(selection),
					"}",
					"",
					"html, body, main, #page-ctn, .markdown-body {",
					"  background: var(--mkdp-bg) !important;",
					"  color: var(--mkdp-fg) !important;",
					"}",
					"",
					".markdown-body a, .markdown-body a code { color: var(--mkdp-link) !important; }",
					".markdown-body h1, .markdown-body h2, .markdown-body h3,",
					".markdown-body h4, .markdown-body h5, .markdown-body h6 {",
					"  color: var(--mkdp-accent) !important;",
					"  border-bottom-color: var(--mkdp-border) !important;",
					"}",
					"",
					".markdown-body blockquote {",
					"  color: var(--mkdp-muted) !important;",
					"  border-left-color: var(--mkdp-border) !important;",
					"}",
					"",
					".markdown-body code, .markdown-body pre, .markdown-body pre code,",
					".markdown-body table tr, .markdown-body table tr:nth-child(2n),",
					".markdown-body table th, .markdown-body table td {",
					"  background: var(--mkdp-code-bg) !important;",
					"  color: var(--mkdp-fg) !important;",
					"  border-color: var(--mkdp-border) !important;",
					"}",
					"",
					".markdown-body hr { background-color: var(--mkdp-border) !important; }",
					".markdown-body ::selection { background: var(--mkdp-selection) !important; }",
				}, markdown_css)

				vim.fn.writefile({
					(".hljs { background: %s !important; color: %s !important; }"):format(code_bg, fg),
					(".hljs-comment, .hljs-quote { color: %s !important; font-style: italic; }"):format(muted),
					(".hljs-keyword, .hljs-selector-tag, .hljs-subst { color: %s !important; }"):format(keyword),
					(".hljs-string, .hljs-doctag { color: %s !important; }"):format(string),
					(".hljs-number, .hljs-literal, .hljs-variable, .hljs-template-variable, .hljs-attribute { color: %s !important; }"):format(constant),
					(".hljs-title, .hljs-section, .hljs-selector-id { color: %s !important; font-weight: bold; }"):format(accent),
					(".hljs-type, .hljs-class .hljs-title { color: %s !important; }"):format(type_color),
					(".hljs-function, .hljs-name { color: %s !important; }"):format(func),
					(".hljs-symbol, .hljs-bullet, .hljs-link { color: %s !important; }"):format(link),
				}, highlight_css)

				vim.g.mkdp_markdown_css = markdown_css
				vim.g.mkdp_highlight_css = highlight_css
				vim.g.mkdp_theme = vim.o.background == "light" and "light" or "dark"
			end

			write_preview_css()
			vim.schedule(function()
				if vim.bo.filetype == "markdown" then
					write_preview_css()
				end
			end)

			vim.api.nvim_create_autocmd({ "ColorScheme", "FileType", "WinEnter" }, {
				group = vim.api.nvim_create_augroup("markdown_preview_colorscheme_css", { clear = true }),
				pattern = "*",
				callback = function(args)
					if args.event == "FileType" and vim.bo[args.buf].filetype ~= "markdown" then
						return
					end
					if vim.bo.filetype == "markdown" then
						write_preview_css()
					end
				end,
				desc = "Update MarkdownPreview CSS from the active markdown colorscheme",
			})
		end,
	},

})
