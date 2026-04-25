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
				local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
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
				terminal = { focus = true, height = 0.75 },
			})
			set_bug_chaser_highlights()
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("BugChaserThemeOverrides", { clear = true }),
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

})
