local M = {}

local state = {
    theme = nil,
}

local function clamp(value, min_value, max_value)
    if value < min_value then return min_value end
    if value > max_value then return max_value end
    return value
end

local function int_to_rgb(color)
    return {
	math.floor(color / 65536) % 256,
	math.floor(color / 256) % 256,
	color % 256,
    }
end

local function rgb_to_int(rgb)
    return (rgb[1] * 65536) + (rgb[2] * 256) + rgb[3]
end

local function rgb_to_hex(rgb)
    return string.format("#%02x%02x%02x", rgb[1], rgb[2], rgb[3])
end

local function shift_color(color, delta)
    local rgb = int_to_rgb(color)
    return rgb_to_int({
	clamp(rgb[1] + delta, 0, 255),
	clamp(rgb[2] + delta, 0, 255),
	clamp(rgb[3] + delta, 0, 255),
    })
end

local function get_hl(group)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if not ok or not hl then
	return {}
    end
    return hl
end

local function list_highlight_groups()
    return vim.fn.getcompletion("", "highlight")
end

local function group_under_cursor()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]
    local col = cursor[2] + 1

    local stack = vim.fn.synstack(row, col)
    for i = #stack, 1, -1 do
	local id = vim.fn.synIDtrans(stack[i])
	local name = vim.fn.synIDattr(id, "name")
	if name ~= "" then
	    return name
	end
    end

    local id = vim.fn.synIDtrans(vim.fn.synID(row, col, 1))
    local name = vim.fn.synIDattr(id, "name")
    if name ~= "" then
	return name
    end
    return "Normal"
end

function M.init_theme(name)
    local theme_name = name
    if not theme_name or theme_name == "" then
	local base = vim.g.colors_name or "theme"
	theme_name = base .. "_custom"
    end

    local snapshot = {}
    for _, group in ipairs(list_highlight_groups()) do
	local hl = get_hl(group)
	if next(hl) ~= nil then
	    snapshot[group] = vim.deepcopy(hl)
	end
    end

    state.theme = {
	name = theme_name,
	base = vim.g.colors_name or "unknown",
	highlights = snapshot,
	modified = {},
    }

    vim.notify(
	string.format("InitTheme: %s (%d groups)", state.theme.name, vim.tbl_count(snapshot)),
	vim.log.levels.INFO
    )
end

function M.update_highlight()
    if not state.theme then
	vim.notify("Run :InitTheme first", vim.log.levels.WARN)
	return
    end

    local groups = {}
    for group, hl in pairs(state.theme.highlights) do
	if type(hl.fg) == "number" or type(hl.bg) == "number" or type(hl.sp) == "number" then
	    table.insert(groups, group)
	end
    end
    table.sort(groups)
    if #groups == 0 then
	vim.notify("No highlight groups available in theme snapshot", vim.log.levels.WARN)
	return
    end

    local index = 1
    local mode = "browse"
    local channel_index = 1
    local buf = vim.api.nvim_create_buf(false, true)
    local width = 62
    local height = 18
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local win = vim.api.nvim_open_win(buf, true, {
	relative = "editor",
	row = row,
	col = col,
	width = width,
	height = height,
	style = "minimal",
	border = "rounded",
	title = "UpdateHighlight",
	title_pos = "center",
    })
    local ns = vim.api.nvim_create_namespace("theme_builder_preview")
    local flicker_timer = vim.uv.new_timer()
    local flicker_on = false

    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "themebuilder"

    local function current_group()
	return groups[index]
    end

    local function persisted_hl()
	local group = current_group()
	local hl = state.theme.modified[group]
	if hl then return vim.deepcopy(hl) end
	return vim.deepcopy(state.theme.highlights[group] or get_hl(group))
    end

    local function apply_hl(group, hl)
	vim.api.nvim_set_hl(0, group, hl)
    end

    local function save_hl(group, hl)
	state.theme.modified[group] = vim.deepcopy(hl)
	apply_hl(group, hl)
    end

    local function edit_slots(hl)
	local colors = {}
	if type(hl.fg) == "number" then colors.fg = int_to_rgb(hl.fg) end
	if type(hl.bg) == "number" then colors.bg = int_to_rgb(hl.bg) end
	if type(hl.sp) == "number" then colors.sp = int_to_rgb(hl.sp) end

	local slots = {}
	local channel_names = { "r", "g", "b" }
	for _, key in ipairs({ "fg", "bg", "sp" }) do
	    if colors[key] then
		for idx2 = 1, 3 do
		    table.insert(slots, { key = key, idx = idx2, channel = channel_names[idx2] })
		end
	    end
	end
	return colors, slots
    end

    local function flicker_variant(hl)
	local variant = vim.deepcopy(hl)
	local delta = 34
	if type(variant.fg) == "number" then
	    variant.fg = shift_color(variant.fg, delta)
	end
	if type(variant.bg) == "number" then
	    variant.bg = shift_color(variant.bg, -delta)
	end
	if variant.bold == nil then variant.bold = true end
	return variant
    end

    local function stop_flicker()
	if flicker_timer then
	    flicker_timer:stop()
	end
	local group = current_group()
	apply_hl(group, persisted_hl())
    end

    local function start_flicker()
	if not flicker_timer then return end
	flicker_on = false
	flicker_timer:stop()
	flicker_timer:start(0, 170, vim.schedule_wrap(function()
	    if mode ~= "browse" then return end
	    local group = current_group()
	    local base_hl = persisted_hl()
	    if flicker_on then
		apply_hl(group, flicker_variant(base_hl))
	    else
		apply_hl(group, base_hl)
	    end
	    flicker_on = not flicker_on
	    vim.cmd("redraw")
	end))
    end

    local function render()
	if not vim.api.nvim_win_is_valid(win) then return end
	local group = current_group()
	local hl = persisted_hl()
	local colors, slots = edit_slots(hl)
	if channel_index > #slots then channel_index = 1 end
	local preview_line = nil
	local lines = {
	    string.format("Theme: %s  Base: %s", state.theme.name, state.theme.base),
	    string.format("Mode: %s", mode),
	    "Browse keys: j/k move group, a or i edit, q close",
	    "Edit keys: h/l select channel, j/k -/+1, J/K -/+10, <Esc> browse",
	    "",
	}

	local start_line = math.max(1, index - 5)
	local end_line = math.min(#groups, start_line + 9)
	for i = start_line, end_line do
	    local marker = (i == index) and ">" or " "
	    table.insert(lines, string.format("%s %s", marker, groups[i]))
	end

	table.insert(lines, "")
	table.insert(lines, "Live preview:")
	table.insert(lines, "  SAMPLE TEXT")
	preview_line = #lines
	table.insert(lines, string.format("  fg=%s bg=%s", colors.fg and rgb_to_hex(colors.fg) or "none", colors.bg and rgb_to_hex(colors.bg) or "none"))

	if mode == "edit" then
	    table.insert(lines, "")
	    table.insert(lines, "Channels:")
	    for i, slot in ipairs(slots) do
		local marker = (i == channel_index) and ">" or " "
		local rgb = colors[slot.key]
		local value = rgb[slot.idx]
		table.insert(lines, string.format("%s %s.%s = %3d", marker, slot.key, slot.channel, value))
	    end
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	vim.api.nvim_set_hl(0, "ThemeBuilderPreview", {
	    fg = hl.fg,
	    bg = hl.bg,
	    bold = hl.bold,
	    italic = hl.italic,
	    underline = hl.underline,
	})
	if preview_line then
	    vim.api.nvim_buf_add_highlight(buf, ns, "ThemeBuilderPreview", preview_line - 1, 2, -1)
	end
	vim.bo[buf].modifiable = false
    end

    start_flicker()
    render()

    while vim.api.nvim_win_is_valid(win) do
	local key = vim.fn.getcharstr()

	if key == "\027" then
	    if mode == "edit" then
		mode = "browse"
		start_flicker()
	    end
	elseif key == "q" then
	    break
	elseif mode == "browse" then
	    if key == "j" then
		stop_flicker()
		index = math.min(index + 1, #groups)
		start_flicker()
	    elseif key == "k" then
		stop_flicker()
		index = math.max(index - 1, 1)
		start_flicker()
	    elseif key == "a" or key == "i" then
		mode = "edit"
		stop_flicker()
	    end
	elseif mode == "edit" then
	    local group = current_group()
	    local hl = persisted_hl()
	    local colors, slots = edit_slots(hl)
	    if #slots > 0 then
		local slot = slots[channel_index]
		local rgb = colors[slot.key]
		local changed = false
		if key == "h" then
		    channel_index = (channel_index - 2) % #slots + 1
		elseif key == "l" then
		    channel_index = channel_index % #slots + 1
		elseif key == "j" then
		    rgb[slot.idx] = clamp(rgb[slot.idx] - 1, 0, 255)
		    changed = true
		elseif key == "k" then
		    rgb[slot.idx] = clamp(rgb[slot.idx] + 1, 0, 255)
		    changed = true
		elseif key == "J" then
		    rgb[slot.idx] = clamp(rgb[slot.idx] - 10, 0, 255)
		    changed = true
		elseif key == "K" then
		    rgb[slot.idx] = clamp(rgb[slot.idx] + 10, 0, 255)
		    changed = true
		end
		if changed then
		    for key2, rgb2 in pairs(colors) do
			hl[key2] = rgb_to_int(rgb2)
		    end
		    save_hl(group, hl)
		end
	    end
	end

	render()
	vim.cmd("redraw")
    end

    stop_flicker()
    if flicker_timer then
	flicker_timer:stop()
	flicker_timer:close()
    end
    if vim.api.nvim_win_is_valid(win) then
	vim.api.nvim_win_close(win, true)
    end
end

function M.setup()
    vim.api.nvim_create_user_command("InitTheme", function(opts)
	M.init_theme(opts.args)
    end, { nargs = "?" })

    vim.api.nvim_create_user_command("UpdateHighlight", function()
	M.update_highlight()
    end, { nargs = 0 })
end

return M
