local M = {}

local state = {
    theme = nil,
    preview = nil,
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

local function normalize_family_name(name)
    local normalized = (name or "template"):lower():gsub("%-", "_"):gsub("%s+", "_")
    if normalized == "" then
	return "template"
    end
    if not normalized:match("^[%a_][%w_]*$") then
	error(("Invalid theme family '%s'"):format(name), 2)
    end
    return normalized
end

local function family_paths(family)
    local config_root = vim.fn.stdpath("config")
    if family == "template" then
	return {
	    family = family,
	    colors_prefix = "template",
	    palette_module = "lush_theme.template_palette",
	    theme_module = "lush_theme.template_base",
	    palette_path = config_root .. "/lua/lush_theme/template_palette.lua",
	    base_path = config_root .. "/lua/lush_theme/template_base.lua",
	}
    end

    local colors_prefix = family:gsub("_", "-")
    return {
	family = family,
	colors_prefix = colors_prefix,
	palette_module = ("lush_theme.%s_palettes"):format(family),
	theme_module = ("lush_theme.%s_base"):format(family),
	palette_path = config_root .. "/lua/lush_theme/" .. family .. "_palettes.lua",
	base_path = config_root .. "/lua/lush_theme/" .. family .. "_base.lua",
	colors_dark_path = config_root .. "/colors/" .. colors_prefix .. "-dark.lua",
	colors_medium_path = config_root .. "/colors/" .. colors_prefix .. "-medium.lua",
	colors_light_path = config_root .. "/colors/" .. colors_prefix .. "-light.lua",
    }
end

local function preview_sample_lines()
    return {
	typescript = {
	    "import { writeFileSync } from \"node:fs\"",
	    "",
	    "interface PalettePreview {",
	    "  title: string",
	    "  accent: string",
	    "  enabled?: boolean",
	    "}",
	    "",
	    "const paint = (preview: PalettePreview): string => {",
	    "  if (!preview.enabled) return preview.title",
	    "  return `${preview.title} -> ${preview.accent}`",
	    "}",
	    "",
	    "class ThemeDraft {",
	    "  constructor(private readonly mode: \"dark\" | \"medium\" | \"light\") {}",
	    "",
	    "  save(path: string) {",
	    "    writeFileSync(path, paint({ title: this.mode, accent: \"#aabbcc\", enabled: true }))",
	    "  }",
	    "}",
	    "",
	    "new ThemeDraft(\"dark\").save(\"preview.txt\")",
	},
	markdown = {
	    "# Theme Preview",
	    "",
	    "A quick reference buffer for headings, emphasis, and inline `code`.",
	    "",
	    "## Surface",
	    "",
	    "- Normal text should stay readable.",
	    "- `Code blocks` should pick up the panel background.",
	    "- Links, punctuation, and headings should stay distinct.",
	    "",
	    "### Notes",
	    "",
	    "> Diagnostics and UI groups are better checked in real files after the palette feels close.",
	    "",
	    "```lua",
	    "local accent = \"#7ab0a6\"",
	    "print(\"preview\", accent)",
	    "```",
	},
    }
end

local function create_preview_buffer(filetype, lines, name)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    vim.bo[buf].filetype = filetype
    pcall(vim.api.nvim_buf_set_name, buf, name)
    return buf
end

local function cleanup_preview()
    local preview = state.preview
    if not preview then
	return
    end

    if preview.timer then
	preview.timer:stop()
	preview.timer:close()
    end

    if preview.augroup then
	pcall(vim.api.nvim_del_augroup_by_id, preview.augroup)
    end

    state.preview = nil
end

local function preview_status(message, level)
    local hl = level == vim.log.levels.ERROR and "ErrorMsg" or "ModeMsg"
    vim.api.nvim_echo({ { message, hl } }, false, {})
end

local function load_lua_module_from_buffer(buf, path)
    if not vim.api.nvim_buf_is_valid(buf) then
	error("Preview palette buffer is no longer valid", 2)
    end

    local chunk_text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    local chunk, err = load(chunk_text, "@" .. path, "t", setmetatable({
	vim = vim,
	require = require,
	package = package,
    }, { __index = _G }))

    if not chunk then
	error(err, 2)
    end

    local module = chunk()
    if module == nil then
	error(("Preview module did not return a value: %s"):format(path), 2)
    end

    return module
end

local function palette_from_preview_buffer(preview)
    local module = load_lua_module_from_buffer(preview.palette_buf, preview.palette_path)
    if type(module.get) == "function" then
	return module.get(preview.variant)
    end
    return type(module) == "function" and module(preview.variant) or module
end

local function apply_preview(preview)
    local runtime = require("lush_theme.runtime")
    local ok, result = pcall(function()
	return runtime.apply(vim.tbl_extend("force", preview.apply_opts, {
	    palette = palette_from_preview_buffer(preview),
	}))
    end)
    if ok then
	if preview.last_error then
	    preview_status(("Theme preview recovered: %s %s"):format(preview.family, preview.variant))
	end
	preview.last_error = nil
	return result
    end

    local message = tostring(result)
    if preview.last_error ~= message then
	preview.last_error = message
	preview_status("Theme preview error: " .. message, vim.log.levels.ERROR)
    end
    return nil
end

local function schedule_preview_apply(preview)
    if not preview or not preview.timer then
	return
    end

    preview.timer:stop()
    preview.timer:start(120, 0, vim.schedule_wrap(function()
	apply_preview(preview)
    end))
end

local function open_preview_windows(paths)
    local samples = preview_sample_lines()
    if #vim.api.nvim_list_uis() == 0 then
	vim.cmd("edit " .. vim.fn.fnameescape(paths.palette_path))
	return vim.api.nvim_get_current_buf()
    end

    vim.cmd("tabnew")
    vim.cmd("edit " .. vim.fn.fnameescape(paths.palette_path))
    local palette_buf = vim.api.nvim_get_current_buf()
    vim.bo[palette_buf].bufhidden = "hide"
    vim.wo.number = true
    vim.wo.relativenumber = false

    vim.cmd("vsplit")
    local ts_buf = create_preview_buffer("typescript", samples.typescript, "theme-preview://sample.ts")
    vim.api.nvim_win_set_buf(0, ts_buf)
    vim.wo.wrap = false

    vim.cmd("split")
    local md_buf = create_preview_buffer("markdown", samples.markdown, "theme-preview://notes.md")
    vim.api.nvim_win_set_buf(0, md_buf)
    vim.wo.wrap = true

    vim.cmd("wincmd t")
    vim.cmd("wincmd h")

    return palette_buf
end

local function camelize(name)
    local parts = vim.split(name, "_", { plain = true })
    for i, part in ipairs(parts) do
	parts[i] = part:sub(1, 1):upper() .. part:sub(2)
    end
    return table.concat(parts, "")
end

local function colorscheme_loader_text(family, variant)
    local colors_prefix = family:gsub("_", "-")
    local family_title = camelize(family)
    local variant_title = camelize(variant)

    return table.concat({
	'require("lush_theme.runtime").setup_colorscheme({',
	('  variant = "%s",'):format(variant),
	('  theme_module = "lush_theme.%s_base",'):format(family),
	('  palette_module = "lush_theme.%s_palettes",'):format(family),
	('  colors_name = "%s-%s",'):format(colors_prefix, variant),
	('  reload_command = "%s%sReload",'):format(family_title, variant_title),
	"})",
	"",
    }, "\n")
end

local function scaffold_theme(family)
    local paths = family_paths(family)
    if family == "template" then
	error("template is reserved", 2)
    end

    local targets = {
	paths.palette_path,
	paths.base_path,
	paths.colors_dark_path,
	paths.colors_medium_path,
	paths.colors_light_path,
    }

    for _, path in ipairs(targets) do
	if vim.fn.filereadable(path) == 1 then
	    error(("Refusing to overwrite existing file: %s"):format(path), 2)
	end
    end

    local template_palette = table.concat(vim.fn.readfile(family_paths("template").palette_path), "\n")
    local template_base = table.concat(vim.fn.readfile(family_paths("template").base_path), "\n")

    template_palette = template_palette
	:gsub("Copy this file to <yourtheme>_palettes.lua and replace the sample values%.", ("Copy this file into %s_palettes.lua and replace the sample values."):format(family))
	:gsub("Unknown template palette", ("Unknown %s palette"):format(family))
    template_base = template_base:gsub('require%("lush_theme%.template_palette"%)', ('require("lush_theme.%s_palettes")'):format(family))

    vim.fn.writefile(vim.split(template_palette, "\n", { plain = true }), paths.palette_path)
    vim.fn.writefile(vim.split(template_base, "\n", { plain = true }), paths.base_path)
    vim.fn.writefile(vim.split(colorscheme_loader_text(family, "dark"), "\n", { plain = true }), paths.colors_dark_path)
    vim.fn.writefile(vim.split(colorscheme_loader_text(family, "medium"), "\n", { plain = true }), paths.colors_medium_path)
    vim.fn.writefile(vim.split(colorscheme_loader_text(family, "light"), "\n", { plain = true }), paths.colors_light_path)

    return paths
end

function M.theme_palette_preview(args)
    local family = normalize_family_name(args.fargs[1] or "template")
    local variant = args.fargs[2] or "dark"
    local paths = family_paths(family)

    if vim.fn.filereadable(paths.palette_path) ~= 1 then
	vim.notify(("Palette file not found: %s"):format(paths.palette_path), vim.log.levels.ERROR)
	return
    end

    cleanup_preview()

    local palette_buf = open_preview_windows(paths)
    local preview = {
	family = family,
	variant = variant,
	augroup = vim.api.nvim_create_augroup("ThemePalettePreview", { clear = true }),
	timer = vim.uv.new_timer(),
	palette_buf = palette_buf,
	palette_path = paths.palette_path,
	apply_opts = {
	    variant = variant,
	    theme_module = paths.theme_module,
	    palette_module = paths.palette_module,
	    colors_name = ("%s-%s-preview"):format(paths.colors_prefix, variant),
	    extra_modules = {
		paths.theme_module,
		paths.palette_module,
	    },
	},
    }
    state.preview = preview

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
	group = preview.augroup,
	buffer = palette_buf,
	callback = function()
	    schedule_preview_apply(preview)
	end,
    })

    vim.api.nvim_create_autocmd("BufHidden", {
	group = preview.augroup,
	buffer = palette_buf,
	once = true,
	callback = function()
	    cleanup_preview()
	end,
    })

    apply_preview(preview)
    vim.notify(("Theme preview: editing %s (%s)"):format(paths.palette_module, variant), vim.log.levels.INFO)
end

function M.theme_scaffold(args)
    local family = normalize_family_name(args.args)
    local ok, paths = pcall(scaffold_theme, family)
    if not ok then
	vim.notify(paths, vim.log.levels.ERROR)
	return
    end

    vim.notify(("Scaffolded %s. Run :ThemePalettePreview %s dark to start tuning it."):format(paths.colors_prefix, family), vim.log.levels.INFO)
end

function M.setup()
    vim.api.nvim_create_user_command("InitTheme", function(opts)
	M.init_theme(opts.args)
    end, { nargs = "?" })

    vim.api.nvim_create_user_command("UpdateHighlight", function()
	M.update_highlight()
    end, { nargs = 0 })

    vim.api.nvim_create_user_command("ThemePalettePreview", function(opts)
	M.theme_palette_preview(opts)
    end, { nargs = "*" })

    vim.api.nvim_create_user_command("ThemeScaffold", function(opts)
	M.theme_scaffold(opts)
    end, { nargs = 1 })
end

return M
