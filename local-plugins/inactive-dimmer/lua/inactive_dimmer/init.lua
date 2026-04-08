local M = {}

local bitops = bit or bit32
local namespace = vim.api.nvim_create_namespace("inactive_dimmer")
local augroup_id = nil
local enabled = false

local defaults = {
	dim_factor = 0.65,
}

local config = vim.deepcopy(defaults)

local function dim_rgb(color, factor)
	if type(color) ~= "number" or not bitops then
		return color
	end

	local r = math.floor(bitops.band(bitops.rshift(color, 16), 0xff) * factor + 0.5)
	local g = math.floor(bitops.band(bitops.rshift(color, 8), 0xff) * factor + 0.5)
	local b = math.floor(bitops.band(color, 0xff) * factor + 0.5)
	return bitops.bor(bitops.lshift(r, 16), bitops.lshift(g, 8), b)
end

local function rebuild_namespace()
	local groups = vim.fn.getcompletion("", "highlight")
	for _, name in ipairs(groups) do
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
		if ok and hl and next(hl) ~= nil then
			local dim = vim.deepcopy(hl)
			if dim.fg then
				dim.fg = dim_rgb(dim.fg, config.dim_factor)
			end
			vim.api.nvim_set_hl(namespace, name, dim)
		end
	end
end

local function apply()
	local current = vim.api.nvim_get_current_win()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local cfg = vim.api.nvim_win_get_config(win)
		if cfg.relative == "" then
			local ok_skip, skip = pcall(vim.api.nvim_win_get_var, win, "inactive_dimmer_skip")
			if enabled and win ~= current and not (ok_skip and skip) then
				vim.api.nvim_win_set_hl_ns(win, namespace)
			else
				vim.api.nvim_win_set_hl_ns(win, 0)
			end
		end
	end
end

local function schedule_apply()
	vim.schedule(apply)
end

function M.refresh()
	rebuild_namespace()
	apply()
end

function M.enable()
	if enabled then
		return
	end
	enabled = true
	M.refresh()
end

function M.disable()
	if not enabled then
		return
	end
	enabled = false
	apply()
end

function M.toggle()
	if enabled then
		M.disable()
	else
		M.enable()
	end
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

	if augroup_id then
		pcall(vim.api.nvim_del_augroup_by_id, augroup_id)
	end

	pcall(vim.api.nvim_del_user_command, "InactiveDimEnable")
	pcall(vim.api.nvim_del_user_command, "InactiveDimDisable")
	pcall(vim.api.nvim_del_user_command, "InactiveDimToggle")

	augroup_id = vim.api.nvim_create_augroup("InactiveDimmer", { clear = true })
	vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "TabEnter", "VimResized", "WinClosed" }, {
		group = augroup_id,
		callback = schedule_apply,
		desc = "Dim inactive windows",
	})
	vim.api.nvim_create_autocmd("WinLeave", {
		group = augroup_id,
		callback = schedule_apply,
		desc = "Dim inactive windows",
	})
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = augroup_id,
		callback = function()
			if enabled then
				M.refresh()
			end
		end,
		desc = "Rebuild inactive dim highlights after colorscheme changes",
	})

	vim.api.nvim_create_user_command("InactiveDimEnable", M.enable, {
		desc = "Enable inactive window dimming",
	})
	vim.api.nvim_create_user_command("InactiveDimDisable", M.disable, {
		desc = "Disable inactive window dimming",
	})
	vim.api.nvim_create_user_command("InactiveDimToggle", M.toggle, {
		desc = "Toggle inactive window dimming",
	})

	M.enable()
end

return M
