-- init.lua
local vim = vim

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "✘",
			[vim.diagnostic.severity.WARN] = "▲",
			[vim.diagnostic.severity.INFO] = "●",
			[vim.diagnostic.severity.HINT] = "⚑",
		},
	},
})

require('loader')
require('plugins')
require('tmux_nav').setup()
