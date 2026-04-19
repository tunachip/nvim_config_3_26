require('lazy').setup({

	{ -- OrgMode
		'nvim-orgmode/orgmode',
		event = 'VeryLazy',
		ft = { 'org ' },
		config = function()
			vim.lsp.enable('org')
		end,
	},

	{ -- OrgmodeTelescope
		'nvim-orgmode/telescope-orgmode.nvim',
		event = "VeryLazy",
		dependencies = {
			'nvim-orgmode/orgmode',
			'nvim-telescope/telescope.nvim',
		},
		config = function()
			require("setups").orgmode_telescope()
		end,
	},

	{
		"hat0uma/csvview.nvim",
		---@module "csvview"
		---@type CsvView.Options
		opts = {
			parser = { comments = { "#", "//" } },
			keymaps = {
				textobject_field_inner = { "if", mode = { "o", "x" } },
				textobject_field_outer = { "af", mode = { "o", "x" } },
				jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
				jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
				jump_next_row = { "<Enter>", mode = { "n", "v" } },
				jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
			},
		},
		cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
	},

	{ -- Treesitter
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		lazy = false,
		dependencies = { {
			"windwp/nvim-ts-autotag",
			config = function()
				require('nvim-ts-autotag').setup()
			end,
		} },
		config = function()
			require("setups").treesitter()
		end,
	},

	{ -- Plenary
		'nvim-lua/plenary.nvim',
		lazy = true,
	},

	{ -- Tmux Navigator
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

	{ -- Render Markdown
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("setups").render_markdown()
		end,
	},

	{ -- Lush (colorscheme builder)
		'rktjmp/lush.nvim',
		lazy = true,
	},

	{ -- Zen Mode
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		opts = {
			window = {
				width = 0.65,
			},
		},
	},

	{ -- LSP Config
		'neovim/nvim-lspconfig',
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("setups").lsp()
		end,
	},

	{ -- Completion
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		keys = { "<leader>cc" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
		},
		config = function()
			require("setups").cmp()
		end,
	},

	{ -- Mason
		'williamboman/mason.nvim',
		cmd = "Mason",
	},

	{ -- Mason LSP Config
		'williamboman/mason-lspconfig.nvim',
		event = 'VeryLazy',
	},

	{ -- Oil
		'stevearc/oil.nvim',
		lazy = false,
		dependancies = { 'nvim-tree/nvim-web-devicons' },
		config = function()
			require('setups').oil()
		end,
	},

	{ -- Telescope
		"nvim-telescope/telescope.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				lazy = false,
			},
			"nvim-telescope/telescope-live-grep-args.nvim",
			"nvim-telescope/telescope-symbols.nvim",
		},
		config = function()
			require("setups").telescope()
		end,
	},

	{ -- FTerm
		"numToStr/FTerm.nvim",
		cmd = "FTermToggle",
		lazy = false,
		config = function()
			require('setups').fterm()
		end,
	},

	{ -- Surround
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("setups").surround()
		end,
	},

	{ -- Autopairs
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("setups").autopairs()
		end,
	},

	{ -- Align
		"rrethy/nvim-align",
		cmd = "Align",
		keys = { "ga", "gA" },
		config = function()
			require("setups").align()
		end,
	},

	-- Local Repos ------------------------------------------
	{ -- Yamicon
		dir = "~/Development/yamicon",
		config = function()
			require('yamicon').setup({})
		end,
	},

	{ -- Codex-Inline
		dir = "~/Development/codex-inline",
		config = function()
			require('codex_inline').setup({
				codex_exec_command = { "codex", "exec" },
				codex_terminal_command = { "codex" },
				skip_git_repo_check = true,
				terminal = {
					direction = "horizontal",
					placement = "botright",
					size = 15,
				},
			})
		end,
	},

	{ -- Fold-Up
		dir = "~/Development/fold-up",
		config = function()
			require("fold-up").setup({})
		end,
	},

	{ -- Styla
		dir = vim.fn.stdpath("config") .. "/local-plugins/styla.nvim",
		config = function()
			require("styla").setup()
		end,
	},

	{ -- Discord Chat
		dir = "~/Development/discord-chat.nvim",
		config = function()
			require('discord-chat').setup({
				token = vim.env.DISCORD_BOT_TOKEN,
				channel_id = "https://discord.com/channels/1447973083666448384/1484352669521809450",
				mappings = {
					toggle = "<leader>dc",
					refresh = "<leader>dr",
				},
			})
		end,
	},

	{ -- Inactive Dimmer
		dir = vim.fn.stdpath("config") .. "/local-plugins/inactive-dimmer",
		name = "inactive-dimmer.nvim",
		lazy = false,
		config = function()
			require("inactive_dimmer").setup({
				dim_factor = 0.65,
			})
		end,
	},

	{ -- PDF Reader
		dir = vim.fn.stdpath("config") .. "/local-plugins/pdf-reader.nvim",
		name = "pdf-reader.nvim",
		lazy = false,
	},

	{ -- Casket
		dir = "~/Development/casket.nvim",
		name = "casket.nvim",
		lazy = false,
		config = function()
			require("casket").setup()
		end,
	},

	{
		dir = "~/Development/bug-chaser.nvim",
		name = "bug-chaser.nvim",
		lazy = true,
		config = function()
			require('bug_chaser').setup()
		end,
	},

	{ -- Telescope-Diff
		dir = "~/Development/telescope-diff",
		dependancies = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("telescope_diff").setup()
			require("telescope").load_extension("telescope_diff")
		end,
	},

})
