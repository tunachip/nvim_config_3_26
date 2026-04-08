local M = {}

local state = {
	config = nil,
	session = nil,
}

local COLUMN = {
	CANDIDATE = 1,
	SLOT = 2,
	COLOR = 3,
	HUE = 4,
	SAT = 5,
	LIGHT = 6,
	STYLE = 7,
}

local SLOT_NAMES = { "fg", "bg", "sp" }
local STYLE_BASES = { "bold", "italic", "underline", "undercurl", "strikethrough" }
local LUA_KEYWORDS = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["goto"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
}
local COMMAND_ALIASES = {
	add_color = "AddColor",
	set_style = "SetStyle",
	new_theme = "NewTheme",
	update_styles = "UpdateStyles",
}
local SUBCOMMANDS = {
	add_color = true,
	set_style = true,
	new_theme = true,
	update_styles = true,
	apply = true,
}

local defaults = {
	theme_path = vim.fn.stdpath("config") .. "/example_theme.lua",
	auto_apply = true,
	glow_interval_ms = 420,
}
local ui_ns = vim.api.nvim_create_namespace("styla_ui")
local ARROW_UP = "↑"
local ARROW_DOWN = "↓"
local ARROW_BOTH = "↕"

local function clamp(value, min_value, max_value)
	if value < min_value then
		return min_value
	end
	if value > max_value then
		return max_value
	end
	return value
end

local function trim(text)
	return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function deep_copy(value)
	return vim.deepcopy(value)
end

local function normalize_slot(value)
	if type(value) == "string" then
		return { color = value, h = 0, s = 0, l = 0 }
	end
	if type(value) ~= "table" then
		return nil
	end
	if value.color == nil or value.color == "none" then
		return nil
	end
	return {
		color = value.color,
		h = tonumber(value.h) or 0,
		s = tonumber(value.s) or 0,
		l = tonumber(value.l) or 0,
	}
end

local function normalize_spec(spec)
	spec = type(spec) == "table" and deep_copy(spec) or {}
	spec.fg = normalize_slot(spec.fg)
	spec.bg = normalize_slot(spec.bg)
	spec.sp = normalize_slot(spec.sp)
	spec.style = type(spec.style) == "table" and deep_copy(spec.style) or {}
	table.sort(spec.style)
	return spec
end

local function normalize_theme(theme)
	theme = type(theme) == "table" and theme or {}
	theme.colors = type(theme.colors) == "table" and deep_copy(theme.colors) or {}
	theme.specs = type(theme.specs) == "table" and deep_copy(theme.specs) or {}
	theme.resolve = type(theme.resolve) == "table" and deep_copy(theme.resolve) or {}

	for group, spec in pairs(theme.specs) do
		theme.specs[group] = normalize_spec(spec)
	end
	for scope, rules in pairs(theme.resolve) do
		if type(rules) ~= "table" then
			theme.resolve[scope] = {}
		else
			for role, items in pairs(rules) do
				if type(items) ~= "table" then
					rules[role] = {}
				end
			end
		end
	end

	return theme
end

local function load_theme(path)
	local chunk, err = loadfile(path)
	if not chunk then
		error(err, 2)
	end
	local ok, theme = pcall(chunk)
	if not ok then
		error(theme, 2)
	end
	return normalize_theme(theme)
end

local function serialize(value, indent)
	indent = indent or 0
	local pad = string.rep("  ", indent)
	local child_pad = string.rep("  ", indent + 1)

	if type(value) == "string" then
		return string.format("%q", value)
	end
	if type(value) == "number" or type(value) == "boolean" then
		return tostring(value)
	end
	if value == nil then
		return "nil"
	end
	if type(value) ~= "table" then
		error("Unsupported theme value: " .. type(value), 2)
	end

	local is_array = true
	local count = 0
	for key in pairs(value) do
		count = count + 1
		if type(key) ~= "number" then
			is_array = false
			break
		end
	end

	if count == 0 then
		return "{}"
	end

	local lines = { "{" }
	if is_array then
		for _, item in ipairs(value) do
			lines[#lines + 1] = child_pad .. serialize(item, indent + 1) .. ","
		end
	else
		local keys = vim.tbl_keys(value)
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		for _, key in ipairs(keys) do
			local key_text = tostring(key)
			local bareword = key_text:match("^[%a_][%w_]*$") and not LUA_KEYWORDS[key_text]
			local rendered_key = bareword and key_text or ("[" .. serialize(key, 0) .. "]")
			lines[#lines + 1] = string.format("%s%s = %s,", child_pad, rendered_key, serialize(value[key], indent + 1))
		end
	end
	lines[#lines + 1] = pad .. "}"
	return table.concat(lines, "\n")
end

local function write_theme(path, theme)
	local content = table.concat({
		"-- styla.nvim theme file",
		"",
		"return " .. serialize(theme, 0),
		"",
	}, "\n")
	vim.fn.writefile(vim.split(content, "\n", { plain = true }), path)
end

local function ensure_lua_suffix(name)
	if name:sub(-4) == ".lua" then
		return name
	end
	return name .. ".lua"
end

local function default_theme(name)
	return normalize_theme({
		meta = {
			name = name,
		},
		colors = {
			bg = "#101418",
			fg = "#e6edf3",
			muted = "#7d8590",
			red = "#ff7b72",
			green = "#3fb950",
			yellow = "#d29922",
			blue = "#58a6ff",
			magenta = "#bc8cff",
			cyan = "#39c5cf",
			orange = "#f0883e",
		},
		specs = {},
		resolve = {
			default = {},
		},
	})
end

local function hex_to_rgb(hex)
	hex = trim(hex):gsub("^#", "")
	if #hex ~= 6 then
		return nil
	end
	return {
		tonumber(hex:sub(1, 2), 16),
		tonumber(hex:sub(3, 4), 16),
		tonumber(hex:sub(5, 6), 16),
	}
end

local function rgb_to_hex(rgb)
	return string.format("#%02x%02x%02x", rgb[1], rgb[2], rgb[3])
end

local function shift_rgb(color, factor)
	if type(color) ~= "number" then
		return color
	end
	local r = clamp(math.floor(math.floor(color / 0x10000) % 0x100 * factor + 0.5), 0, 255)
	local g = clamp(math.floor(math.floor(color / 0x100) % 0x100 * factor + 0.5), 0, 255)
	local b = clamp(math.floor((color % 0x100) * factor + 0.5), 0, 255)
	return r * 0x10000 + g * 0x100 + b
end

local function rgb_to_hsl(rgb)
	local r = rgb[1] / 255
	local g = rgb[2] / 255
	local b = rgb[3] / 255
	local maxc = math.max(r, g, b)
	local minc = math.min(r, g, b)
	local h, s
	local l = (maxc + minc) / 2

	if maxc == minc then
		h = 0
		s = 0
	else
		local d = maxc - minc
		s = l > 0.5 and d / (2 - maxc - minc) or d / (maxc + minc)
		if maxc == r then
			h = ((g - b) / d + (g < b and 6 or 0)) / 6
		elseif maxc == g then
			h = ((b - r) / d + 2) / 6
		else
			h = ((r - g) / d + 4) / 6
		end
	end

	return {
		h = math.floor(h * 360 + 0.5),
		s = math.floor(s * 100 + 0.5),
		l = math.floor(l * 100 + 0.5),
	}
end

local function hsl_to_rgb(hsl)
	local h = ((hsl.h % 360) + 360) % 360 / 360
	local s = clamp(hsl.s, 0, 100) / 100
	local l = clamp(hsl.l, 0, 100) / 100

	if s == 0 then
		local value = math.floor(l * 255 + 0.5)
		return { value, value, value }
	end

	local function hue_to_rgb(p, q, t)
		if t < 0 then t = t + 1 end
		if t > 1 then t = t - 1 end
		if t < 1 / 6 then return p + (q - p) * 6 * t end
		if t < 1 / 2 then return q end
		if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
		return p
	end

	local q = l < 0.5 and l * (1 + s) or l + s - l * s
	local p = 2 * l - q
	return {
		math.floor(hue_to_rgb(p, q, h + 1 / 3) * 255 + 0.5),
		math.floor(hue_to_rgb(p, q, h) * 255 + 0.5),
		math.floor(hue_to_rgb(p, q, h - 1 / 3) * 255 + 0.5),
	}
end

function M.hsl(color, h_delta, s_delta, l_delta)
	local rgb = type(color) == "string" and hex_to_rgb(color) or nil
	if not rgb then
		return color
	end
	local hsl = rgb_to_hsl(rgb)
	hsl.h = hsl.h + (tonumber(h_delta) or 0)
	hsl.s = clamp(hsl.s + (tonumber(s_delta) or 0), 0, 100)
	hsl.l = clamp(hsl.l + (tonumber(l_delta) or 0), 0, 100)
	return rgb_to_hex(hsl_to_rgb(hsl))
end

local function is_valid_hex(hex)
	return type(hex) == "string" and hex:match("^#%x%x%x%x%x%x$") ~= nil
end

local function resolve_slot(theme, slot)
	if not slot or slot.color == nil then
		return nil
	end
	local base = theme.colors[slot.color]
	if type(base) ~= "string" then
		return nil
	end
	return M.hsl(base, slot.h or 0, slot.s or 0, slot.l or 0)
end

local function apply_theme(theme)
	for group, spec in pairs(theme.specs) do
		local hl = {}
		local fg = resolve_slot(theme, spec.fg)
		local bg = resolve_slot(theme, spec.bg)
		local sp = resolve_slot(theme, spec.sp)
		if fg then hl.fg = fg end
		if bg then hl.bg = bg end
		if sp then hl.sp = sp end
		for _, style in ipairs(spec.style or {}) do
			hl[style] = true
			hl.cterm = hl.cterm or {}
			hl.cterm[style] = true
		end
		vim.api.nvim_set_hl(0, group, hl)
	end
end

local function style_options()
	local options = { { label = "none", values = {} } }
	for size = 1, #STYLE_BASES do
		local function build(start_idx, acc)
			if #acc == size then
				options[#options + 1] = {
					label = table.concat(acc, "+"),
					values = deep_copy(acc),
				}
				return
			end
			for i = start_idx, #STYLE_BASES do
				acc[#acc + 1] = STYLE_BASES[i]
				build(i + 1, acc)
				acc[#acc] = nil
			end
		end
		build(1, {})
	end
	return options
end

local STYLE_OPTIONS = style_options()

local function syn_group_at(bufnr, row, col)
	local stack = vim.fn.synstack(row + 1, col + 1)
	for i = #stack, 1, -1 do
		local id = vim.fn.synIDtrans(stack[i])
		local name = vim.fn.synIDattr(id, "name")
		if name ~= "" then
			return name
		end
	end
	local id = vim.fn.synIDtrans(vim.fn.synID(row + 1, col + 1, 1))
	local name = vim.fn.synIDattr(id, "name")
	return name ~= "" and name or "Normal"
end

local function unique_extend(out, seen, value)
	if type(value) == "string" and value ~= "" and not seen[value] then
		seen[value] = true
		out[#out + 1] = value
	end
end

local function semantic_candidates(bufnr, row, col, filetype)
	local out, seen = {}, {}
	local ok, items = pcall(vim.lsp.semantic_tokens.get_at_pos, bufnr, row, col)
	if not ok or type(items) ~= "table" then
		return out
	end

	for _, item in ipairs(items) do
		if type(item) == "table" then
			unique_extend(out, seen, item.hl_group)
			unique_extend(out, seen, item.group)
			if type(item.opts) == "table" then
				unique_extend(out, seen, item.opts.hl_group)
			end
			local token_type = item.type or item.token_type
			if type(token_type) == "string" then
				if filetype ~= "" then
					unique_extend(out, seen, "@lsp.type." .. token_type .. "." .. filetype)
				end
				unique_extend(out, seen, "@lsp.type." .. token_type)
			end
			local modifiers = item.modifiers
			if type(modifiers) == "table" and type(token_type) == "string" then
				for _, modifier in ipairs(modifiers) do
					if type(modifier) == "string" then
						if filetype ~= "" then
							unique_extend(out, seen, "@lsp.typemod." .. token_type .. "." .. modifier .. "." .. filetype)
						end
						unique_extend(out, seen, "@lsp.typemod." .. token_type .. "." .. modifier)
					end
				end
			end
		end
	end
	return out
end

local function treesitter_candidates(bufnr, row, col, filetype)
	local out, seen = {}, {}
	local ok, items = pcall(vim.treesitter.get_captures_at_pos, bufnr, row, col)
	if not ok or type(items) ~= "table" then
		return out
	end

	for _, item in ipairs(items) do
		if type(item) == "table" then
			local capture = item.capture or item.name or item[1]
			local lang = item.lang or filetype
			if type(capture) == "string" then
				local base = capture:sub(1, 1) == "@" and capture or ("@" .. capture)
				if type(lang) == "string" and lang ~= "" then
					unique_extend(out, seen, base .. "." .. lang)
				end
				unique_extend(out, seen, base)
			end
		end
	end
	return out
end

local function syntax_candidates(bufnr, row, col)
	local out, seen = {}, {}
	local stack = vim.fn.synstack(row + 1, col + 1)
	for i = #stack, 1, -1 do
		local id = vim.fn.synIDtrans(stack[i])
		local name = vim.fn.synIDattr(id, "name")
		unique_extend(out, seen, name)
	end
	unique_extend(out, seen, syn_group_at(bufnr, row, col))
	return out
end

local function candidates_at(bufnr, row, col, filetype)
	local out, seen = {}, {}
	for _, name in ipairs(semantic_candidates(bufnr, row, col, filetype)) do
		unique_extend(out, seen, name)
	end
	for _, name in ipairs(treesitter_candidates(bufnr, row, col, filetype)) do
		unique_extend(out, seen, name)
	end
	for _, name in ipairs(syntax_candidates(bufnr, row, col)) do
		unique_extend(out, seen, name)
	end
	if #out == 0 then
		out[1] = "Normal"
	end
	return out
end

local function normalize_role(candidate, filetype)
	if type(candidate) ~= "string" or candidate == "" then
		return "token"
	end
	local role = candidate
	role = role:gsub("^@lsp%.typemod%.", "")
	role = role:gsub("^@lsp%.type%.", "")
	role = role:gsub("^@lsp%.mod%.", "")
	role = role:gsub("^@", "")
	if filetype ~= "" then
		role = role:gsub("%." .. vim.pesc(filetype) .. "$", "")
	end
	return role ~= "" and role or "token"
end

local function inspect_context(bufnr, winid)
	local cursor = vim.api.nvim_win_get_cursor(winid)
	local row, col = cursor[1] - 1, cursor[2]
	local filetype = vim.bo[bufnr].filetype or ""
	local candidates = candidates_at(bufnr, row, col, filetype)
	return {
		bufnr = bufnr,
		row = row,
		col = col,
		filetype = filetype ~= "" and filetype or "default",
		candidates = candidates,
		role = normalize_role(candidates[1], filetype),
	}
end

local function ensure_rule(theme, filetype, role, detected_candidates)
	theme.resolve.default = theme.resolve.default or {}
	theme.resolve[filetype] = theme.resolve[filetype] or {}

	local existing = theme.resolve[filetype][role]
	if type(existing) ~= "table" then
		existing = theme.resolve.default[role]
	end
	existing = type(existing) == "table" and deep_copy(existing) or {}

	local seen, ordered = {}, {}
	for _, name in ipairs(existing) do
		unique_extend(ordered, seen, name)
	end
	for _, name in ipairs(detected_candidates or {}) do
		unique_extend(ordered, seen, name)
	end

	theme.resolve[filetype][role] = ordered
	return ordered
end

local function style_index(values)
	local wanted = deep_copy(values or {})
	table.sort(wanted)
	local label = #wanted == 0 and "none" or table.concat(wanted, "+")
	for idx, option in ipairs(STYLE_OPTIONS) do
		if option.label == label then
			return idx
		end
	end
	return 1
end

local function palette_options(theme, slot)
	local names = vim.tbl_keys(theme.colors)
	table.sort(names)
	local out = { "none" }
	for _, name in ipairs(names) do
		out[#out + 1] = name
	end
	if slot and slot.color and slot.color ~= "none" and not vim.tbl_contains(out, slot.color) then
		out[#out + 1] = slot.color
	end
	return out
end

local function current_group(session)
	if session.mode == "groups_pick" or session.mode == "groups_edit" then
		return session.group_items[session.group_index]
	end
	return session.candidates[session.candidate_index]
end

local function current_spec(session)
	local group = current_group(session)
	session.theme.specs[group] = normalize_spec(session.theme.specs[group])
	return session.theme.specs[group]
end

local function current_slot_name(session)
	return SLOT_NAMES[session.slot_index]
end

local function current_slot(session)
	return current_spec(session)[current_slot_name(session)]
end

local function sync_indexes(session)
	local slot = current_slot(session)
	session.color_options = palette_options(session.theme, slot)
	session.color_index = 1
	local wanted = slot and slot.color or "none"
	for idx, name in ipairs(session.color_options) do
		if name == wanted then
			session.color_index = idx
			break
		end
	end
	session.style_index = style_index(current_spec(session).style)
end

local function persist(session)
	write_theme(session.theme_path, session.theme)
	apply_theme(session.theme)
end

local function persist_theme(theme_path, theme)
	write_theme(theme_path, theme)
	apply_theme(theme)
end

local function refresh_inactive_dimmer()
	local ok, dimmer = pcall(require, "inactive_dimmer")
	if ok and type(dimmer.refresh) == "function" then
		pcall(dimmer.refresh)
	end
end

local function source_window_visible_range(session)
	if not session.source_win or not vim.api.nvim_win_is_valid(session.source_win) then
		return nil
	end
	local info = vim.fn.getwininfo(session.source_win)[1]
	if not info then
		return nil
	end
	return info.topline - 1, info.botline - 1
end

local function matches_group_at(session, row, col, group)
	local filetype = vim.bo[session.source_buf].filetype or ""
	for _, candidate in ipairs(candidates_at(session.source_buf, row, col, filetype)) do
		if candidate == group then
			return true
		end
	end
	return false
end

local function scan_line_for_group(session, row, group)
	local line = vim.api.nvim_buf_get_lines(session.source_buf, row, row + 1, false)[1] or ""
	local ranges = {}
	local active_start = nil
	for col = 0, #line - 1 do
		local ch = line:sub(col + 1, col + 1)
		local match = ch:match("%s") == nil and matches_group_at(session, row, col, group)
		if match and not active_start then
			active_start = col
		elseif not match and active_start then
			ranges[#ranges + 1] = { row = row, start_col = active_start, end_col = col }
			active_start = nil
		end
	end
	if active_start then
		ranges[#ranges + 1] = { row = row, start_col = active_start, end_col = #line }
	end
	return ranges
end

local function first_match_row(session, group)
	local line_count = vim.api.nvim_buf_line_count(session.source_buf)
	for row = 0, line_count - 1 do
		if #scan_line_for_group(session, row, group) > 0 then
			return row
		end
	end
	return nil
end

local function ensure_match_visible(session, group)
	local top, bottom = source_window_visible_range(session)
	if top == nil then
		return
	end
	for row = top, bottom do
		if #scan_line_for_group(session, row, group) > 0 then
			return
		end
	end
	local row = first_match_row(session, group)
	if row == nil then
		return
	end
	vim.api.nvim_win_set_cursor(session.source_win, { row + 1, 0 })
	pcall(vim.api.nvim_win_call, session.source_win, function()
		vim.cmd("normal! zz")
	end)
end

local function set_glow_highlight(group, phase)
	local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
	local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
	local base = hl.sp or hl.fg or normal.fg or 0xffffff
	local factor = phase and 1.18 or 0.86
	vim.api.nvim_set_hl(0, "StyleGlowPreview", {
		undercurl = true,
		sp = shift_rgb(base, factor),
	})
end

local function update_glow(session)
	if not session or not session.glow_ns then
		return
	end
	vim.api.nvim_buf_clear_namespace(session.source_buf, session.glow_ns, 0, -1)
	if not session.glow_on then
		return
	end
	local group = current_group(session)
	if not group then
		return
	end
	if session.mode == "groups_pick" or (session.mode == "inspect" and session.active_column == COLUMN.CANDIDATE) then
		ensure_match_visible(session, group)
	end
	local top, bottom = source_window_visible_range(session)
	if top == nil then
		return
	end
	set_glow_highlight(group, session.glow_phase)
	for row = top, bottom do
		for _, range in ipairs(scan_line_for_group(session, row, group)) do
			vim.api.nvim_buf_set_extmark(session.source_buf, session.glow_ns, range.row, range.start_col, {
				end_row = range.row,
				end_col = range.end_col,
				hl_group = "StyleGlowPreview",
				hl_mode = "combine",
			})
		end
	end
end

local function stop_glow(session)
	if session and session.glow_timer then
		session.glow_timer:stop()
		session.glow_timer:close()
		session.glow_timer = nil
	end
	if session and session.glow_ns and vim.api.nvim_buf_is_valid(session.source_buf) then
		vim.api.nvim_buf_clear_namespace(session.source_buf, session.glow_ns, 0, -1)
	end
end

local function start_glow(session)
	stop_glow(session)
	session.glow_ns = vim.api.nvim_create_namespace("style_glow_preview")
	session.glow_on = true
	session.glow_phase = false
	session.glow_timer = vim.uv.new_timer()
	if not session.glow_timer then
		return
	end
	session.glow_timer:start(0, state.config.glow_interval_ms, vim.schedule_wrap(function()
		if state.session ~= session then
			return
		end
		session.glow_phase = not session.glow_phase
		update_glow(session)
	end))
	update_glow(session)
end

local function format_cell(text, width)
	text = text or ""
	if #text > width then
		text = text:sub(1, width)
	end
	return text .. string.rep(" ", math.max(0, width - #text))
end

local function compact_value(items, selected, active)
	local current = items[selected] or ""
	local prev = selected > 1 and items[selected - 1] or ""
	local next_item = selected < #items and items[selected + 1] or ""
	local symbol
	if prev ~= "" and next_item ~= "" then
		symbol = ARROW_BOTH
	elseif prev ~= "" then
		symbol = ARROW_UP
	elseif next_item ~= "" then
		symbol = ARROW_DOWN
	else
		symbol = " "
	end
	return string.format("%s %s", symbol, current), active
end

local function centered_numbers(value, min_value, max_value)
	local items = {}
	for offset = -3, 3 do
		items[#items + 1] = tostring(clamp(value + offset, min_value, max_value))
	end
	return items, 4
end

local function line_from_columns(columns)
	local parts = {}
	local spans = {}
	local col = 0
	for _, column in ipairs(columns) do
		local text = format_cell(column.text, column.width)
		parts[#parts + 1] = text
		spans[#spans + 1] = {
			start_col = col,
			end_col = col + #text,
			active = column.active,
		}
		col = col + #text + 2
	end
	return table.concat(parts, "  "), spans
end

local function apply_ui_highlights(session, rows)
	vim.api.nvim_buf_clear_namespace(session.ui_buf, ui_ns, 0, -1)
	vim.api.nvim_set_hl(0, "StylaActiveCell", { reverse = true, bold = true })
	for row, spans in ipairs(rows) do
		for _, span in ipairs(spans) do
			if span.active then
				vim.api.nvim_buf_add_highlight(session.ui_buf, ui_ns, "StylaActiveCell", row - 1, span.start_col, span.end_col)
			end
		end
	end
end

local function render_group_picker(session)
	local group_value, group_active = compact_value(session.group_items, session.group_index, true)
	local header, header_spans = line_from_columns({
		{ text = "Group", width = 56, active = group_active },
	})
	local status, status_spans = line_from_columns({
		{ text = group_value, width = 56, active = group_active },
	})
	local lines = { header, status }

	vim.bo[session.ui_buf].modifiable = true
	vim.api.nvim_buf_set_lines(session.ui_buf, 0, -1, false, lines)
	vim.bo[session.ui_buf].modifiable = false
	apply_ui_highlights(session, { header_spans, status_spans })
end

local function render_editor(session, include_candidate)
	local spec = current_spec(session)
	local slot = current_slot(session)
	local hue_items, hue_selected = centered_numbers(slot and slot.h or 0, -180, 180)
	local sat_items, sat_selected = centered_numbers(slot and slot.s or 0, -100, 100)
	local light_items, light_selected = centered_numbers(slot and slot.l or 0, -100, 100)
	local style_labels = {}
	for _, option in ipairs(STYLE_OPTIONS) do
		style_labels[#style_labels + 1] = option.label
	end

	local header_columns = {}
	local value_columns = {}
	if include_candidate then
		local text, active = compact_value(session.candidates, session.candidate_index, session.active_column == COLUMN.CANDIDATE)
		header_columns[#header_columns + 1] = { text = "Resolve", width = 28, active = active }
		value_columns[#value_columns + 1] = {
			text = text,
			width = 28,
			active = active,
		}
	end
	local slot_text, slot_active = compact_value(SLOT_NAMES, session.slot_index, session.active_column == COLUMN.SLOT)
	header_columns[#header_columns + 1] = { text = "Slot", width = 14, active = slot_active }
	value_columns[#value_columns + 1] = {
		text = slot_text,
		width = 14,
		active = slot_active,
	}
	local color_text, color_active = compact_value(session.color_options, session.color_index, session.active_column == COLUMN.COLOR)
	header_columns[#header_columns + 1] = { text = "Color", width = 22, active = color_active }
	value_columns[#value_columns + 1] = {
		text = color_text,
		width = 22,
		active = color_active,
	}
	local hue_text, hue_active = compact_value(hue_items, hue_selected, session.active_column == COLUMN.HUE)
	header_columns[#header_columns + 1] = { text = "Hue", width = 12, active = hue_active }
	value_columns[#value_columns + 1] = {
		text = hue_text,
		width = 12,
		active = hue_active,
	}
	local sat_text, sat_active = compact_value(sat_items, sat_selected, session.active_column == COLUMN.SAT)
	header_columns[#header_columns + 1] = { text = "Sat", width = 12, active = sat_active }
	value_columns[#value_columns + 1] = {
		text = sat_text,
		width = 12,
		active = sat_active,
	}
	local light_text, light_active = compact_value(light_items, light_selected, session.active_column == COLUMN.LIGHT)
	header_columns[#header_columns + 1] = { text = "Light", width = 12, active = light_active }
	value_columns[#value_columns + 1] = {
		text = light_text,
		width = 12,
		active = light_active,
	}
	local style_text, style_active = compact_value(style_labels, session.style_index, session.active_column == COLUMN.STYLE)
	header_columns[#header_columns + 1] = { text = "Style", width = 26, active = style_active }
	value_columns[#value_columns + 1] = {
		text = style_text,
		width = 26,
		active = style_active,
	}

	local context_label = include_candidate
		and string.format(
			"%s prio=%d/%d %s.%s=%s",
			session.role,
			session.candidate_index,
			#session.candidates,
			current_group(session),
			current_slot_name(session),
			slot and slot.color or "none"
		)
		or string.format("%s.%s=%s", current_group(session), current_slot_name(session), slot and slot.color or "none")
	local info_width = math.max(36, #context_label + 16)
	header_columns[#header_columns + 1] = { text = session.mode == "groups_edit" and "Editing" or "Resolved", width = info_width, active = false }
	value_columns[#value_columns + 1] = {
		text = context_label .. " styles=" .. (#spec.style > 0 and table.concat(spec.style, "+") or "none"),
		width = info_width,
		active = false,
	}
	local header_line, header_spans = line_from_columns(header_columns)
	local value_line, value_spans = line_from_columns(value_columns)
	local lines = { header_line, value_line }

	vim.bo[session.ui_buf].modifiable = true
	vim.api.nvim_buf_set_lines(session.ui_buf, 0, -1, false, lines)
	vim.bo[session.ui_buf].modifiable = false
	apply_ui_highlights(session, { header_spans, value_spans })
end

local function render(session)
	if session.mode == "groups_pick" then
		render_group_picker(session)
	elseif session.mode == "groups_edit" then
		render_editor(session, false)
	else
		render_editor(session, true)
	end
	update_glow(session)
end

local function close(session)
	stop_glow(session)
	if session and session.source_win and vim.api.nvim_win_is_valid(session.source_win) then
		pcall(vim.api.nvim_win_del_var, session.source_win, "inactive_dimmer_skip")
	end
	if session and session.ui_win and vim.api.nvim_win_is_valid(session.ui_win) then
		pcall(vim.api.nvim_win_del_var, session.ui_win, "inactive_dimmer_skip")
	end
	if session and session.ui_win and vim.api.nvim_win_is_valid(session.ui_win) then
		vim.api.nvim_win_close(session.ui_win, true)
	end
	refresh_inactive_dimmer()
	if state.session == session then
		state.session = nil
	end
end

local function move_column(session, delta)
	local min_column = session.mode == "inspect" and COLUMN.CANDIDATE or COLUMN.SLOT
	session.active_column = clamp(session.active_column + delta, min_column, COLUMN.STYLE)
	render(session)
end

local function commit_candidate(session)
	if session.mode == "inspect" and session.active_column == COLUMN.CANDIDATE then
		session.active_column = COLUMN.SLOT
		sync_indexes(session)
		render(session)
	end
end

local function reorder_candidate(session, delta)
	local idx = session.candidate_index
	local new_idx = clamp(idx + delta, 1, #session.candidates)
	if new_idx == idx then
		return
	end
	session.candidates[idx], session.candidates[new_idx] = session.candidates[new_idx], session.candidates[idx]
	session.candidate_index = new_idx
	session.theme.resolve[session.filetype][session.role] = deep_copy(session.candidates)
	persist(session)
	sync_indexes(session)
	render(session)
end

local function move_value(session, delta, coarse)
	if session.mode == "groups_pick" then
		session.group_index = clamp(session.group_index + delta, 1, #session.group_items)
		render(session)
		return
	end

	local step = coarse and 10 or 1
	local spec = current_spec(session)
	local slot_name = current_slot_name(session)
	local slot = spec[slot_name]

	if session.mode == "inspect" and session.active_column == COLUMN.CANDIDATE then
		session.candidate_index = clamp(session.candidate_index + delta, 1, #session.candidates)
		sync_indexes(session)
		render(session)
		return
	end

	if session.active_column == COLUMN.SLOT then
		session.slot_index = clamp(session.slot_index + delta, 1, #SLOT_NAMES)
		sync_indexes(session)
		render(session)
		return
	end

	if session.active_column == COLUMN.COLOR then
		session.color_index = clamp(session.color_index + delta, 1, #session.color_options)
		local value = session.color_options[session.color_index]
		if value == "none" then
			spec[slot_name] = nil
		else
			spec[slot_name] = spec[slot_name] or { color = value, h = 0, s = 0, l = 0 }
			spec[slot_name].color = value
		end
		persist(session)
		sync_indexes(session)
		render(session)
		return
	end

	if session.active_column == COLUMN.STYLE then
		session.style_index = clamp(session.style_index + delta, 1, #STYLE_OPTIONS)
		spec.style = deep_copy(STYLE_OPTIONS[session.style_index].values)
		persist(session)
		render(session)
		return
	end

	if not slot then
		return
	end

	if session.active_column == COLUMN.HUE then
		slot.h = clamp((slot.h or 0) + delta * step, -180, 180)
	elseif session.active_column == COLUMN.SAT then
		slot.s = clamp((slot.s or 0) + delta * step, -100, 100)
	elseif session.active_column == COLUMN.LIGHT then
		slot.l = clamp((slot.l or 0) + delta * step, -100, 100)
	end

	persist(session)
	render(session)
end

local function enter_group_edit(session)
	session.mode = "groups_edit"
	session.slot_index = 1
	session.active_column = COLUMN.SLOT
	sync_indexes(session)
	render(session)
end

local function back_from_group_edit(session)
	session.mode = "groups_pick"
	render(session)
end

local function set_keymaps(session)
	local function map(lhs, rhs)
		vim.keymap.set("n", lhs, rhs, { buffer = session.ui_buf, silent = true, nowait = true })
	end

	map("q", function() close(session) end)
	map("h", function() move_column(session, -1) end)
	map("l", function() move_column(session, 1) end)
	map("j", function() move_value(session, -1, false) end)
	map("k", function() move_value(session, 1, false) end)
	map("J", function()
		if session.mode == "inspect" and session.active_column == COLUMN.CANDIDATE then
			reorder_candidate(session, -1)
		else
			move_value(session, -1, true)
		end
	end)
	map("K", function()
		if session.mode == "inspect" and session.active_column == COLUMN.CANDIDATE then
			reorder_candidate(session, 1)
		else
			move_value(session, 1, true)
		end
	end)
	map("<CR>", function()
		if session.mode == "groups_pick" then
			enter_group_edit(session)
		elseif session.mode == "inspect" and session.active_column == COLUMN.CANDIDATE then
			commit_candidate(session)
		end
	end)
	map("<Esc>", function()
		if session.mode == "groups_edit" then
			back_from_group_edit(session)
		else
			close(session)
		end
	end)
end

function M.apply()
	local ok, theme = pcall(load_theme, state.config.theme_path)
	if not ok then
		vim.notify("StylaApply: " .. theme, vim.log.levels.ERROR)
		return
	end
	apply_theme(theme)
end

function M.add_color()
	local ok_theme, theme = pcall(load_theme, state.config.theme_path)
	if not ok_theme then
		vim.notify("AddColor: " .. theme, vim.log.levels.ERROR)
		return
	end

	local name = trim(vim.fn.input("Color name: "))
	if name == "" then
		return
	end
	if not name:match("^[%a_][%w_]*$") then
		vim.notify("AddColor: names must match [a-zA-Z_][a-zA-Z0-9_]*", vim.log.levels.ERROR)
		return
	end

	local existing = theme.colors[name]
	if existing ~= nil then
		local choice = vim.fn.confirm(
			string.format("Color '%s' already exists as %s. Overwrite?", name, existing),
			"&Overwrite\n&Cancel",
			2
		)
		if choice ~= 1 then
			return
		end
	end

	local prompt = existing and string.format("Hex for %s: ", name) or "Hex color: "
	local hex = trim(vim.fn.input(prompt, existing or ""))
	if hex == "" then
		return
	end
	hex = hex:lower()
	if hex:sub(1, 1) ~= "#" then
		hex = "#" .. hex
	end
	if not is_valid_hex(hex) then
		vim.notify("AddColor: expected a valid #rrggbb hex color", vim.log.levels.ERROR)
		return
	end

	theme.colors[name] = hex
	persist_theme(state.config.theme_path, theme)
	if state.session and state.session.theme_path == state.config.theme_path then
		state.session.theme = theme
		sync_indexes(state.session)
		render(state.session)
	end
	vim.notify(string.format("Added color %s = %s", name, hex), vim.log.levels.INFO)
end

function M.new_theme(opts)
	local args = opts and opts.args or ""
	local raw_name = trim(args ~= "" and args or vim.fn.input("Theme name: "))
	if raw_name == "" then
		return
	end

	local file_name = ensure_lua_suffix(raw_name)
	local theme_path = file_name:sub(1, 1) == "/"
		and file_name
		or (vim.fn.stdpath("config") .. "/" .. file_name)

	if vim.fn.filereadable(theme_path) == 1 then
		local choice = vim.fn.confirm(
			string.format("Theme file '%s' exists. Overwrite?", vim.fn.fnamemodify(theme_path, ":~:.")),
			"&Overwrite\n&Cancel",
			2
		)
		if choice ~= 1 then
			return
		end
	end

	local theme_name = vim.fn.fnamemodify(file_name, ":t:r")
	local theme = default_theme(theme_name)
	write_theme(theme_path, theme)
	state.config.theme_path = theme_path
	apply_theme(theme)
	vim.notify(string.format("Created theme at %s", vim.fn.fnamemodify(theme_path, ":~:.")), vim.log.levels.INFO)
end

local function open_ui_window()
	vim.cmd("botright split")
	local ui_win = vim.api.nvim_get_current_win()
	local ui_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(ui_win, ui_buf)
	vim.bo[ui_buf].bufhidden = "wipe"
	vim.bo[ui_buf].buftype = "nofile"
	vim.bo[ui_buf].swapfile = false
	vim.bo[ui_buf].filetype = "styletool"
	vim.wo[ui_win].number = false
	vim.wo[ui_win].relativenumber = false
	vim.wo[ui_win].signcolumn = "no"
	vim.wo[ui_win].wrap = false
	vim.api.nvim_win_set_height(ui_win, 4)
	return ui_buf, ui_win
end

function M.open()
	local bufnr = vim.api.nvim_get_current_buf()
	local source_win = vim.api.nvim_get_current_win()
	if vim.bo[bufnr].buftype ~= "" then
		vim.notify("SetStyle only works from normal editing buffers", vim.log.levels.WARN)
		return
	end

	local ok_theme, theme = pcall(load_theme, state.config.theme_path)
	if not ok_theme then
		vim.notify("SetStyle: " .. theme, vim.log.levels.ERROR)
		return
	end

	local context = inspect_context(bufnr, source_win)
	local candidates = ensure_rule(theme, context.filetype, context.role, context.candidates)

	if state.session then
		close(state.session)
	end

	local ui_buf, ui_win = open_ui_window()
	pcall(vim.api.nvim_win_set_var, source_win, "inactive_dimmer_skip", true)
	pcall(vim.api.nvim_win_set_var, ui_win, "inactive_dimmer_skip", true)
	refresh_inactive_dimmer()
	local session = {
		mode = "inspect",
		theme = theme,
		theme_path = state.config.theme_path,
		source_buf = bufnr,
		source_win = source_win,
		filetype = context.filetype,
		role = context.role,
		candidates = candidates,
		candidate_index = 1,
		slot_index = 1,
		active_column = COLUMN.CANDIDATE,
		color_index = 1,
		color_options = {},
		style_index = 1,
		ui_buf = ui_buf,
		ui_win = ui_win,
	}

	state.session = session
	sync_indexes(session)
	set_keymaps(session)
	persist(session)
	start_glow(session)
	render(session)
end

function M.open_groups()
	local bufnr = vim.api.nvim_get_current_buf()
	local source_win = vim.api.nvim_get_current_win()
	if vim.bo[bufnr].buftype ~= "" then
		vim.notify("UpdateStyles only works from normal editing buffers", vim.log.levels.WARN)
		return
	end

	local ok_theme, theme = pcall(load_theme, state.config.theme_path)
	if not ok_theme then
		vim.notify("UpdateStyles: " .. theme, vim.log.levels.ERROR)
		return
	end

	if state.session then
		close(state.session)
	end

	local ui_buf, ui_win = open_ui_window()
	pcall(vim.api.nvim_win_set_var, source_win, "inactive_dimmer_skip", true)
	pcall(vim.api.nvim_win_set_var, ui_win, "inactive_dimmer_skip", true)
	refresh_inactive_dimmer()
	local group_items = vim.fn.getcompletion("", "highlight")
	for name in pairs(theme.specs) do
		if not vim.tbl_contains(group_items, name) then
			group_items[#group_items + 1] = name
		end
	end
	table.sort(group_items)

	local current = syn_group_at(bufnr, vim.api.nvim_win_get_cursor(source_win)[1] - 1, vim.api.nvim_win_get_cursor(source_win)[2])
	local group_index = 1
	for idx, name in ipairs(group_items) do
		if name == current then
			group_index = idx
			break
		end
	end

	local session = {
		mode = "groups_pick",
		theme = theme,
		theme_path = state.config.theme_path,
		source_buf = bufnr,
		source_win = source_win,
		filetype = vim.bo[bufnr].filetype ~= "" and vim.bo[bufnr].filetype or "default",
		group_items = group_items,
		group_index = group_index,
		slot_index = 1,
		active_column = COLUMN.SLOT,
		color_index = 1,
		color_options = {},
		style_index = 1,
		ui_buf = ui_buf,
		ui_win = ui_win,
	}

	state.session = session
	sync_indexes(session)
	set_keymaps(session)
	start_glow(session)
	render(session)
end

local function install_command_aliases()
	for alias, real in pairs(COMMAND_ALIASES) do
		vim.cmd(string.format(
			"cnoreabbrev <expr> %s ((getcmdtype() == ':' && getcmdline() == '%s') ? '%s' : '%s')",
			alias,
			alias,
			real,
			alias
		))
	end
end

local function parse_dispatch_args(arg_string)
	local parts = vim.split(trim(arg_string or ""), "%s+", { plain = false, trimempty = true })
	local subcommand = parts[1] or ""
	table.remove(parts, 1)
	return subcommand, table.concat(parts, " ")
end

function M.dispatch(opts)
	local subcommand, rest = parse_dispatch_args(opts and opts.args or "")
	if subcommand == "" then
		vim.notify("Styla: expected one of add_color, set_style, new_theme, update_styles, apply", vim.log.levels.WARN)
		return
	end

	if subcommand == "set_style" then
		return M.open()
	end
	if subcommand == "update_styles" then
		return M.open_groups()
	end
	if subcommand == "add_color" then
		return M.add_color()
	end
	if subcommand == "new_theme" then
		return M.new_theme({ args = rest })
	end
	if subcommand == "apply" then
		return M.apply()
	end

	vim.notify("Styla: unknown subcommand '" .. subcommand .. "'", vim.log.levels.ERROR)
end

local function complete_dispatch(arglead, cmdline)
	local subcommand, _ = parse_dispatch_args(cmdline:gsub("^%s*Styla%s*", ""))
	if subcommand == "" or not SUBCOMMANDS[subcommand] then
		return vim.tbl_filter(function(item)
			return item:find("^" .. vim.pesc(arglead))
		end, vim.tbl_keys(SUBCOMMANDS))
	end
	return {}
end

function M.setup(opts)
	state.config = vim.tbl_deep_extend("force", deep_copy(defaults), opts or {})

	pcall(vim.api.nvim_del_user_command, "Style")
	pcall(vim.api.nvim_del_user_command, "StyleGroups")
	pcall(vim.api.nvim_del_user_command, "StyleApply")
	pcall(vim.api.nvim_del_user_command, "SetStyle")
	pcall(vim.api.nvim_del_user_command, "UpdateStyles")
	pcall(vim.api.nvim_del_user_command, "AddColor")
	pcall(vim.api.nvim_del_user_command, "NewTheme")
	pcall(vim.api.nvim_del_user_command, "StylaApply")
	pcall(vim.api.nvim_del_user_command, "Styla")

	vim.api.nvim_create_user_command("SetStyle", M.open, {
		desc = "Inspect the token under cursor and edit theme specs and resolve order",
	})
	vim.api.nvim_create_user_command("UpdateStyles", M.open_groups, {
		desc = "Browse highlight groups and edit one with live glow preview",
	})
	vim.api.nvim_create_user_command("AddColor", M.add_color, {
		desc = "Add or update a palette color in the active Styla theme",
	})
	vim.api.nvim_create_user_command("NewTheme", M.new_theme, {
		nargs = "?",
		desc = "Create a new Styla theme with a default palette and no style groups",
	})
	vim.api.nvim_create_user_command("StylaApply", M.apply, {
		desc = "Apply the active Styla theme file to current highlights",
	})
	vim.api.nvim_create_user_command("Styla", M.dispatch, {
		nargs = "*",
		complete = complete_dispatch,
		desc = "Styla command dispatcher",
	})
	install_command_aliases()

	if state.config.auto_apply and vim.fn.filereadable(state.config.theme_path) == 1 then
		vim.schedule(M.apply)
	end
end

return M
