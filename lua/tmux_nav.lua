local M = {}

local nvim_cmd = {
	Left = "wincmd h",
	Right = "wincmd l",
	Up = "wincmd k",
	Down = "wincmd j",
}

local vim_dir = {
	Left = "h",
	Right = "l",
	Up = "k",
	Down = "j",
}

local tmux_flag = {
	Left = "-L",
	Right = "-R",
	Up = "-U",
	Down = "-D",
}

local function local_target_exists(direction)
	local current = vim.api.nvim_get_current_win()
	local target = vim.fn.win_getid(vim.fn.winnr(vim_dir[direction]))
	return target ~= 0 and target ~= current
end

local function tmux_select(direction)
	local flag = tmux_flag[direction]
	local pane = vim.env.TMUX_PANE
	if not flag or not pane or pane == "" then
		return false
	end

	vim.fn.system({ "tmux", "select-pane", "-t", pane, flag })
	return vim.v.shell_error == 0
end

local function tmux_navigate(direction)
	local mode = vim.api.nvim_get_mode().mode
	if mode:sub(1, 1) == "t" then
		vim.cmd("stopinsert")
	end

	if local_target_exists(direction) then
		vim.cmd(nvim_cmd[direction])
		return
	end

	tmux_select(direction)
end

function M.setup()
	local map = vim.keymap.set
	local opts = { silent = true }

	map({ "n", "t" }, "<A-h>", function()
		tmux_navigate("Left")
	end, vim.tbl_extend("force", opts, { desc = "Move left split/tmux pane" }))

	map({ "n", "t" }, "<A-j>", function()
		tmux_navigate("Down")
	end, vim.tbl_extend("force", opts, { desc = "Move down split/tmux pane" }))

	map({ "n", "t" }, "<A-k>", function()
		tmux_navigate("Up")
	end, vim.tbl_extend("force", opts, { desc = "Move up split/tmux pane" }))

	map({ "n", "t" }, "<A-l>", function()
		tmux_navigate("Right")
	end, vim.tbl_extend("force", opts, { desc = "Move right split/tmux pane" }))

	map({ "n", "t" }, "<A-Left>", function()
		tmux_navigate("Left")
	end, vim.tbl_extend("force", opts, { desc = "Move left split/tmux pane" }))

	map({ "n", "t" }, "<A-Down>", function()
		tmux_navigate("Down")
	end, vim.tbl_extend("force", opts, { desc = "Move down split/tmux pane" }))

	map({ "n", "t" }, "<A-Up>", function()
		tmux_navigate("Up")
	end, vim.tbl_extend("force", opts, { desc = "Move up split/tmux pane" }))

	map({ "n", "t" }, "<A-Right>", function()
		tmux_navigate("Right")
	end, vim.tbl_extend("force", opts, { desc = "Move right split/tmux pane" }))
end

return M
