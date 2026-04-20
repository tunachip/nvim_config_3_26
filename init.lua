-- init.lua

require('loader')
require('plugins')
require('tmux_nav').setup()

vim.keymap.set("x", "<leader>rr", ":BugChaserRun<cr>", { desc = "Run selected range" })
