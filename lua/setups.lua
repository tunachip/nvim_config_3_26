-- lua/setups.lua
local M = {}
local set = vim.api.nvim_set_hl
local cmd = vim.api.nvim_create_user_command
local markdown_preview_pairs = {}
local cmp_autocomplete_enabled = false
local bitops = bit or bit32
local run_program_session = nil
local run_program_tempfile = { prompt_on_delete = false, }
local external_review_sessions = {}

M.external_file_review = {
	auto_open = true,
	comment_mode = true,
}

local function blend_rgb(color, target, factor)
	if type(color) ~= "number" or type(target) ~= "number" or not bitops then
		return color
	end

	local function channel(value, shift)
		return bitops.band(bitops.rshift(value, shift), 0xff)
	end

	local function blend_channel(source, dest)
		return math.floor(source + (dest - source) * factor + 0.5)
	end

	local r = blend_channel(channel(color, 16), channel(target, 16))
	local g = blend_channel(channel(color, 8), channel(target, 8))
	local b = blend_channel(channel(color, 0), channel(target, 0))
	return bitops.bor(bitops.lshift(r, 16), bitops.lshift(g, 8), b)
end

local function apply_cmp_highlights()
	local ok_pmenu, pmenu = pcall(vim.api.nvim_get_hl, 0, { name = "Pmenu", link = false })
	if not ok_pmenu or not pmenu or next(pmenu) == nil then
		return
	end

	local bg = pmenu.bg
	if not bg then
		local ok_float, normal_float = pcall(vim.api.nvim_get_hl, 0, { name = "NormalFloat", link = false })
		if ok_float and normal_float then
			bg = normal_float.bg
		end
	end
	if not bg then
		return
	end

	vim.api.nvim_set_hl(0, "PmenuSel", {
		fg = pmenu.fg,
		bg = blend_rgb(bg, 0xffffff, 0.12),
		bold = false,
		underline = false,
	})
end

local function get_single_line_comment_prefix_for_buffer(bufnr)
	bufnr = bufnr or 0
	local comments = vim.bo[bufnr].comments or ""

	for part in comments:gmatch("[^,]+") do
		local prefix = part:match("^b:(.+)$")
				or part:match("^fb:(.+)$")
				or part:match("^f:(.+)$")
		if prefix then
			prefix = vim.trim(prefix):gsub("\\", "")
			if prefix ~= "" then
				return prefix
			end
		end
	end

	local commentstring = vim.bo[bufnr].commentstring or ""
	local prefix = commentstring:match("^(.*)%%s")
	if prefix then
		prefix = vim.trim(prefix):gsub("\\", "")
		if prefix ~= "" and not prefix:find("%*/", 1, true) then
			return prefix
		end
	end

	return "#"
end

local function get_single_line_comment_prefix()
	return get_single_line_comment_prefix_for_buffer(0)
end

local function format_header_comment(text)
	local prefix = get_single_line_comment_prefix()
	return string.format("%s %s", prefix, text)
end

local function add_file_header(opts)
	opts = opts or {}

	if not vim.bo.modifiable then
		if not opts.silent then
			vim.notify("Current buffer is not modifiable", vim.log.levels.WARN)
		end
		return
	end

	local filepath = vim.fn.expand("%:.")
	if filepath == "" then
		if not opts.silent then
			vim.notify("Current buffer has no file path", vim.log.levels.WARN)
		end
		return
	end

	local header = format_header_comment(filepath)
	local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
	if first_line == header then
		if not opts.silent then
			vim.notify("File header already exists", vim.log.levels.INFO)
		end
		return
	end

	local view = vim.fn.winsaveview()
	vim.api.nvim_buf_set_lines(0, 0, 0, false, { header })
	vim.fn.winrestview(view)
end

local function is_empty_named_buffer()
	local filepath = vim.fn.expand("%:p")
	if filepath == "" or vim.bo.buftype ~= "" then
		return false
	end

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	return #lines == 1 and lines[1] == ""
end

local function is_todo_markdown_buffer(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	return name ~= "" and vim.fs.basename(name) == "todo.md"
end

local function is_normal_file_buffer(bufnr)
	bufnr = bufnr or 0
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end

	if vim.bo[bufnr].buftype ~= "" then
		return false
	end

	local name = vim.api.nvim_buf_get_name(bufnr)
	return name ~= ""
end

local function get_disk_file_stat(bufnr)
	bufnr = bufnr or 0
	if not is_normal_file_buffer(bufnr) then
		return nil
	end

	local name = vim.api.nvim_buf_get_name(bufnr)
	return vim.uv.fs_stat(name)
end

local function mark_external_change(bufnr)
	bufnr = bufnr or 0
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end

	local stat = get_disk_file_stat(bufnr)
	local mtime = stat and stat.mtime and stat.mtime.sec or nil
	local is_new_change = (not vim.b[bufnr].external_change_pending) or vim.b[bufnr].external_change_mtime ~= mtime
	if vim.b[bufnr].external_change_rejected_mtime ~= nil and vim.b[bufnr].external_change_rejected_mtime ~= mtime then
		vim.b[bufnr].external_change_rejected_mtime = nil
	end
	vim.b[bufnr].external_change_pending = true
	vim.b[bufnr].external_change_mtime = mtime
	return is_new_change
end

local function clear_external_change(bufnr)
	bufnr = bufnr or 0
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	vim.b[bufnr].external_change_pending = false
	vim.b[bufnr].external_change_mtime = nil
end

local function mark_external_change_rejected(bufnr)
	bufnr = bufnr or 0
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	vim.b[bufnr].external_change_rejected_mtime = vim.b[bufnr].external_change_mtime
	clear_external_change(bufnr)
end

local function current_buffer_matches_disk(bufnr)
	bufnr = bufnr or 0
	local stat = get_disk_file_stat(bufnr)
	if not stat or not stat.mtime then
		return false
	end

	local recorded = vim.b[bufnr].external_change_mtime
	if recorded == nil then
		return false
	end

	return recorded == stat.mtime.sec
end

local function get_external_review_session(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if external_review_sessions[bufnr] then
		return external_review_sessions[bufnr]
	end

	for source_buf, session in pairs(external_review_sessions) do
		if session.disk_buf == bufnr then
			return session, source_buf
		end
	end

	return nil
end

local function buffer_in_external_review(bufnr)
	return get_external_review_session(bufnr) ~= nil
end

local function set_review_buffer_locked(bufnr, locked)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	vim.bo[bufnr].modifiable = not locked
	vim.bo[bufnr].readonly = locked
end

local function close_external_review(source_buf)
	local session = external_review_sessions[source_buf]
	if not session then
		return
	end

	if session.source_win and vim.api.nvim_win_is_valid(session.source_win) then
		vim.api.nvim_set_current_win(session.source_win)
	end

	if vim.api.nvim_buf_is_valid(source_buf) then
		set_review_buffer_locked(source_buf, false)
	end

	if session.source_win and vim.api.nvim_win_is_valid(session.source_win) then
		vim.api.nvim_set_current_win(session.source_win)
		if vim.wo.diff then
			vim.cmd("diffoff")
		end
	end

	if session.disk_win and vim.api.nvim_win_is_valid(session.disk_win) then
		vim.api.nvim_set_current_win(session.disk_win)
		if vim.wo.diff then
			vim.cmd("diffoff")
		end
		vim.cmd("close")
	end

	if session.source_win and vim.api.nvim_win_is_valid(session.source_win) then
		vim.api.nvim_set_current_win(session.source_win)
	end

	external_review_sessions[source_buf] = nil
end

local function build_comment_mode_lines(old_lines, new_lines, source_buf)
	local prefix = get_single_line_comment_prefix_for_buffer(source_buf)
	local old_text = table.concat(old_lines, "\n")
	local new_text = table.concat(new_lines, "\n")
	local hunks = vim.diff(old_text, new_text, {
		result_type = "indices",
		algorithm = "histogram",
	})

	local merged = {}
	local old_index = 1

	local function append_range(lines, first, last)
		for i = first, last do
			merged[#merged + 1] = lines[i]
		end
	end

	local function append_commented_range(lines, first, last)
		for i = first, last do
			local line = lines[i]
			if line == "" then
				merged[#merged + 1] = prefix
			else
				merged[#merged + 1] = prefix .. " " .. line
			end
		end
	end

	for _, hunk in ipairs(hunks) do
		local start_old, count_old, start_new, count_new = unpack(hunk)
		append_range(old_lines, old_index, start_old - 1)
		if count_old > 0 then
			append_commented_range(old_lines, start_old, start_old + count_old - 1)
		end
		if count_new > 0 then
			append_range(new_lines, start_new, start_new + count_new - 1)
		end
		old_index = start_old + count_old
	end

	append_range(old_lines, old_index, #old_lines)
	return merged
end

local function accept_external_review(opts)
	opts = opts or {}
	local current_buf = opts.bufnr or vim.api.nvim_get_current_buf()
	local session, source_buf = get_external_review_session(current_buf)
	source_buf = source_buf or current_buf
	if not session or not source_buf then
		vim.notify("No external review session is active", vim.log.levels.WARN)
		return
	end

	if not vim.api.nvim_buf_is_valid(source_buf) or not vim.api.nvim_buf_is_valid(session.disk_buf) then
		close_external_review(source_buf)
		vim.notify("External review session is no longer valid", vim.log.levels.WARN)
		return
	end

	local old_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
	local new_lines = vim.api.nvim_buf_get_lines(session.disk_buf, 0, -1, false)
	local accepted_lines = new_lines
	if M.external_file_review.comment_mode then
		accepted_lines = build_comment_mode_lines(old_lines, new_lines, source_buf)
	end

	set_review_buffer_locked(source_buf, false)
	vim.api.nvim_buf_set_lines(source_buf, 0, -1, false, accepted_lines)
	vim.bo[source_buf].modified = true

	if session.source_win and vim.api.nvim_win_is_valid(session.source_win) then
		vim.api.nvim_set_current_win(session.source_win)
	end

	vim.cmd("silent write")
	clear_external_change(source_buf)
	close_external_review(source_buf)

	if opts.quit then
		vim.cmd("quit")
	end
	if opts.quit_all then
		vim.cmd("qall")
	end
end

local function reject_external_review(opts)
	opts = opts or {}
	local current_buf = opts.bufnr or vim.api.nvim_get_current_buf()
	local session, source_buf = get_external_review_session(current_buf)
	source_buf = source_buf or current_buf
	if not session or not source_buf then
		return
	end

	mark_external_change_rejected(source_buf)
	close_external_review(source_buf)
	vim.notify("Rejected external changes for the current buffer", vim.log.levels.INFO)
end

local function set_external_review_keymaps(bufnr)
	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, {
			buffer = bufnr,
			noremap = true,
			silent = true,
			nowait = true,
			desc = desc,
		})
	end

	map("<CR>", function()
		accept_external_review({ bufnr = bufnr })
	end, "Accept external changes")
	map("<Esc>", function()
		reject_external_review({ bufnr = bufnr })
	end, "Reject external changes")
	map("ZZ", function()
		accept_external_review({ bufnr = bufnr, quit = true })
	end, "Accept external changes")
end

local function open_external_diff(opts)
	opts = opts or {}
	local source_buf = opts.bufnr or vim.api.nvim_get_current_buf()
	if external_review_sessions[source_buf] then
		return
	end

	if not is_normal_file_buffer(source_buf) then
		vim.notify("Current buffer is not a file-backed buffer", vim.log.levels.WARN)
		return
	end

	local source_win = vim.fn.bufwinid(source_buf)
	if source_win == -1 then
		source_win = vim.api.nvim_get_current_win()
	end

	local file = vim.api.nvim_buf_get_name(source_buf)
	local stat = vim.uv.fs_stat(file)
	if not stat or stat.type ~= "file" then
		vim.notify("Current file does not exist on disk", vim.log.levels.WARN)
		return
	end

	vim.api.nvim_set_current_win(source_win)
	vim.cmd("vertical new")
	local disk_win = vim.api.nvim_get_current_win()
	local disk_buf = vim.api.nvim_get_current_buf()
	vim.bo[disk_buf].buftype = "nofile"
	vim.bo[disk_buf].bufhidden = "wipe"
	vim.bo[disk_buf].swapfile = false
	vim.bo[disk_buf].modifiable = true
	vim.bo[disk_buf].readonly = false
	vim.api.nvim_buf_set_name(disk_buf, ("[disk] %s"):format(vim.fn.fnamemodify(file, ":t")))
	vim.cmd("read ++edit " .. vim.fn.fnameescape(file))
	vim.cmd("0delete _")
	vim.bo[disk_buf].modified = false
	vim.bo[disk_buf].filetype = vim.bo[source_buf].filetype
	set_review_buffer_locked(disk_buf, true)
	vim.cmd("diffthis")

	vim.api.nvim_set_current_win(source_win)
	vim.cmd("diffthis")
	vim.wo.scrollbind = true
	vim.wo.cursorbind = true
	set_review_buffer_locked(source_buf, true)

	external_review_sessions[source_buf] = {
		source_buf = source_buf,
		source_win = source_win,
		disk_buf = disk_buf,
		disk_win = disk_win,
	}

	set_external_review_keymaps(source_buf)
	set_external_review_keymaps(disk_buf)

	vim.notify("External review mode: <Enter> accepts, <Esc> rejects.", vim.log.levels.INFO)
end

local function reload_current_buffer_from_disk()
	local bufnr = vim.api.nvim_get_current_buf()
	if not is_normal_file_buffer(bufnr) then
		vim.notify("Current buffer is not a file-backed buffer", vim.log.levels.WARN)
		return
	end

	if vim.bo[bufnr].modified then
		vim.notify("Buffer has unsaved edits. Review with :ExternalDiff before reloading.", vim.log.levels.WARN)
		return
	end

	vim.cmd("checktime")
	vim.cmd("edit!")
	clear_external_change(bufnr)
	vim.notify("Reloaded buffer from disk", vim.log.levels.INFO)
end

function _G.external_review_command_abbrev(cmd)
	if vim.fn.getcmdtype() ~= ":" then
		return cmd
	end

	local cmdline = vim.fn.getcmdline()
	if cmdline ~= cmd then
		return cmd
	end

	if not buffer_in_external_review(vim.api.nvim_get_current_buf()) then
		return cmd
	end

	local replacements = {
		w = "ExternalReviewAccept",
		["w!"] = "ExternalReviewAccept",
		wa = "ExternalReviewAccept",
		["wa!"] = "ExternalReviewAccept",
		write = "ExternalReviewAccept",
		["write!"] = "ExternalReviewAccept",
		wall = "ExternalReviewAccept",
		["wall!"] = "ExternalReviewAccept",
		update = "ExternalReviewAccept",
		wq = "ExternalReviewAcceptQuit",
		["wq!"] = "ExternalReviewAcceptQuit",
		xit = "ExternalReviewAcceptQuit",
		x = "ExternalReviewAcceptQuit",
		["x!"] = "ExternalReviewAcceptQuit",
		xa = "ExternalReviewAcceptQuitAll",
		["xa!"] = "ExternalReviewAcceptQuitAll",
		wqa = "ExternalReviewAcceptQuitAll",
		["wqa!"] = "ExternalReviewAcceptQuitAll",
		xall = "ExternalReviewAcceptQuitAll",
	}

	return replacements[cmd] or cmd
end

local function maybe_checktime()
	if vim.o.autoread then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	if not is_normal_file_buffer(bufnr) then
		return
	end

	vim.cmd("checktime")
end

local function find_todo_project_root(filepath)
	local start = vim.fs.dirname(filepath)
	local git_dir = vim.fs.find(".git", { path = start, upward = true })[1]
	if git_dir then
		return vim.fs.dirname(git_dir)
	end
	return start
end

local function normalize_todo_comment(line)
	local comment = line:match("TODO:%s*(.+)$")
	if not comment then
		return nil
	end
	comment = vim.trim(comment)
	if comment == "" then
		return nil
	end
	return comment
end

local function relpath_from_root(root, filepath)
	local rel = vim.fs.relpath(root, filepath)
	return rel or filepath
end

local function todo_key(filepath, comment)
	return filepath .. "\31" .. comment
end

local function parse_existing_todo_file(lines)
	local existing = {}
	local notes = {}
	local in_todo = false
	local current_path = nil

	local function add_note(line)
		notes[#notes + 1] = line
	end

	for _, line in ipairs(lines) do
		if line == "## TODO" then
			in_todo = true
			current_path = nil
		elseif line == "## Notes" then
			in_todo = false
		elseif in_todo then
			local heading = line:match("^###%s+(.+)$")
			if heading then
				current_path = heading
			else
				local linked_comment = line:match("^%- %[[ xX]%]%s+(.-)%s+%[%[.+%]%]%s*$")
				local done_comment = line:match("^%- %[[xX]%]%s+(.-)%s+#done%s*$")
				if linked_comment then
					if current_path then
						local comment = vim.trim(linked_comment)
						existing[todo_key(current_path, comment)] = {
							filepath = current_path,
							comment = comment,
						}
					end
				elseif done_comment then
					if current_path then
						local comment = vim.trim(done_comment)
						existing[todo_key(current_path, comment)] = {
							filepath = current_path,
							comment = comment,
						}
					end
				elseif line ~= "" then
					add_note(line)
				end
			end
		else
			if line ~= "" or #notes > 0 then
				add_note(line)
			end
		end
	end

	while #notes > 0 and notes[1] == "" do
		table.remove(notes, 1)
	end
	while #notes > 0 and notes[#notes] == "" do
		table.remove(notes, #notes)
	end

	return existing, notes
end

local function collect_project_todos(root, todo_filepath)
	if vim.fn.executable("rg") ~= 1 then
		vim.notify("ripgrep (rg) is required to sync todo.md", vim.log.levels.WARN)
		return {}
	end

	local cmd = {
		"rg",
		"--line-number",
		"--no-heading",
		"--color=never",
		"--hidden",
		"--glob",
		"!.git",
		"--glob",
		"!**/.*",
		"--glob",
		"!**/.*/**",
		"--glob",
		"!**/node_modules/**",
		"--glob",
		"!**/.next/**",
		"--glob",
		"!**/.nuxt/**",
		"--glob",
		"!**/.svelte-kit/**",
		"--glob",
		"!**/.turbo/**",
		"--glob",
		"!**/dist/**",
		"--glob",
		"!**/build/**",
		"--glob",
		"!**/coverage/**",
		"--glob",
		"!**/package-lock.json",
		"--glob",
		"!**/pnpm-lock.yaml",
		"--glob",
		"!**/yarn.lock",
		"--glob",
		"!**/bun.lockb",
		"--glob",
		"!**/bun.lock",
		"--glob",
		"!**/tsconfig*.json",
		"--glob",
		"!**/vite.config.*",
		"--glob",
		"!**/todo.md",
		"TODO:",
		root,
	}
	local result = vim.system(cmd, { text = true }):wait()
	if result.code ~= 0 and (result.stdout == nil or result.stdout == "") then
		if result.code ~= 1 then
			vim.notify(
				"Failed to scan project TODOs: " .. (result.stderr or "rg error"),
				vim.log.levels.WARN
			)
		end
		return {}
	end

	local todos = {}
	for line in (result.stdout or ""):gmatch("[^\r\n]+") do
		local file, lnum, text = line:match("^(.-):(%d+):(.*)$")
		if file and lnum and text and vim.fs.normalize(file) ~= vim.fs.normalize(todo_filepath) then
			local comment = normalize_todo_comment(text)
			if comment then
				local relfile = relpath_from_root(root, file)
				local key = todo_key(relfile, comment)
				todos[key] = {
					filepath = relfile,
					line = tonumber(lnum),
					comment = comment,
				}
			end
		end
	end

	return todos
end

local function build_todo_buffer_lines(current, existing, notes)
	local grouped = {}
	local paths = {}

	local function ensure_group(path)
		if not grouped[path] then
			grouped[path] = {}
			paths[#paths + 1] = path
		end
		return grouped[path]
	end

	for _, item in pairs(current) do
		local group = ensure_group(item.filepath)
		group[#group + 1] = string.format(
			"- [ ] %s [[%s#L%d]]",
			item.comment,
			item.filepath,
			item.line
		)
	end

	for key, item in pairs(existing) do
		if not current[key] then
			local group = ensure_group(item.filepath)
			group[#group + 1] = string.format("- [x] %s #done", item.comment)
		end
	end

	table.sort(paths)
	for _, path in ipairs(paths) do
		table.sort(grouped[path], function(a, b)
			if a:find("%- %[ %]") and b:find("%- %[x%]") then
				return true
			end
			if a:find("%- %[x%]") and b:find("%- %[ %]") then
				return false
			end
			return a < b
		end)
	end

	local out = { "## TODO" }
	for _, path in ipairs(paths) do
		out[#out + 1] = ""
		out[#out + 1] = "### " .. path
		vim.list_extend(out, grouped[path])
	end

	out[#out + 1] = ""
	out[#out + 1] = ""
	out[#out + 1] = "## Notes"
	if #notes > 0 then
		out[#out + 1] = ""
		vim.list_extend(out, notes)
	end

	return out
end

local function sync_todo_markdown(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) or not is_todo_markdown_buffer(bufnr) then
		return
	end
	if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
		return
	end

	local filepath = vim.api.nvim_buf_get_name(bufnr)
	local root = find_todo_project_root(filepath)
	local current = collect_project_todos(root, filepath)
	local existing, notes = parse_existing_todo_file(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
	local new_lines = build_todo_buffer_lines(current, existing, notes)
	local old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	if vim.deep_equal(old_lines, new_lines) then
		return
	end

	local was_modified = vim.bo[bufnr].modified
	local view = vim.fn.winsaveview()
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
	vim.fn.winrestview(view)
	if not was_modified then
		vim.bo[bufnr].modified = false
	end
end

local function parse_todo_link_at_cursor(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1

	for target in line:gmatch("%[%[([^%]]+)%]%]") do
		local start_col, end_col = line:find("[[" .. target .. "]]", 1, true)
		if start_col and end_col and col >= start_col and col <= end_col then
			local path, lnum = target:match("^(.-)#L(%d+)$")
			if path and lnum then
				local base = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
				return vim.fs.normalize(base .. "/" .. path), tonumber(lnum)
			end
		end
	end

	return nil
end

local function open_todo_link()
	local filepath, lnum = parse_todo_link_at_cursor(0)
	if not filepath or not lnum then
		vim.notify("No todo link under cursor", vim.log.levels.WARN)
		return
	end
	if vim.fn.filereadable(filepath) ~= 1 then
		vim.notify("Todo link target not found: " .. filepath, vim.log.levels.WARN)
		return
	end

	vim.cmd.edit(vim.fn.fnameescape(filepath))
	vim.api.nvim_win_set_cursor(0, { lnum, 0 })
end

local function trim_ws(text)
	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalize_inline(text)
	text = text or ""
	local lines = vim.split(text, "\n", { plain = true })

	while #lines > 0 and trim_ws(lines[1]) == "" do
		table.remove(lines, 1)
	end
	while #lines > 0 and trim_ws(lines[#lines]) == "" do
		table.remove(lines)
	end

	for i, line in ipairs(lines) do
		lines[i] = trim_ws(line)
	end

	return table.concat(lines, " ")
end

local function split_top_level_commas(text)
	local items = {}
	local start_idx = 1
	local depth_paren, depth_brack, depth_brace = 0, 0, 0
	local quote = nil
	local escaped = false

	for i = 1, #text do
		local ch = text:sub(i, i)
		if quote then
			if escaped then
				escaped = false
			elseif ch == "\\" then
				escaped = true
			elseif ch == quote then
				quote = nil
			end
		else
			if ch == "'" or ch == '"' or ch == "`" then
				quote = ch
			elseif ch == "(" then
				depth_paren = depth_paren + 1
			elseif ch == ")" then
				depth_paren = math.max(0, depth_paren - 1)
			elseif ch == "[" then
				depth_brack = depth_brack + 1
			elseif ch == "]" then
				depth_brack = math.max(0, depth_brack - 1)
			elseif ch == "{" then
				depth_brace = depth_brace + 1
			elseif ch == "}" then
				depth_brace = math.max(0, depth_brace - 1)
			elseif ch == "," and depth_paren == 0 and depth_brack == 0 and depth_brace == 0 then
				items[#items + 1] = text:sub(start_idx, i - 1)
				start_idx = i + 1
			end
		end
	end

	items[#items + 1] = text:sub(start_idx)
	return items
end

local function is_placeholder_import_source(source)
	local normalized = trim_ws(source or "")
	return normalized == "" or normalized == "?" or normalized == "???" or normalized == "TODO"
end

local function get_nvim_cwd()
	local uv = vim.uv or vim.loop
	return uv.cwd()
end

local function path_without_extension(path)
	return (path:gsub("%.[^.]+$", ""))
end

local function strip_index_suffix(path)
	return (path:gsub("/index$", ""))
end

local function to_relative_module_path(from_file, target_file)
	local from_dir
	if from_file and from_file ~= "" then
		from_dir = vim.fs.dirname(from_file)
	else
		from_dir = get_nvim_cwd()
	end

	local rel = vim.fs.relpath(from_dir, target_file) or target_file
	rel = strip_index_suffix(path_without_extension(rel))
	if not rel:match("^%.") then
		rel = "./" .. rel
	end
	return rel
end

local function to_python_module_path(root, target_file)
	local rel = vim.fs.relpath(root, target_file) or target_file
	rel = path_without_extension(rel):gsub("/", ".")
	rel = rel:gsub("%.__init__$", "")
	return rel
end

local function rg_escape(text)
	return (text:gsub("([\\%^%$%(%)%%%.%[%]%*%+%-%?%{%}%|])", "\\%1"))
end

local function find_typescript_definition(root, symbol, current_file)
	local escaped = rg_escape(symbol)
	local patterns = {
		"export\\s+type\\s+" .. escaped .. "\\b",
		"export\\s+interface\\s+" .. escaped .. "\\b",
		"export\\s+enum\\s+" .. escaped .. "\\b",
		"export\\s+class\\s+" .. escaped .. "\\b",
		"export\\s+function\\s+" .. escaped .. "\\b",
		"export\\s+async\\s+function\\s+" .. escaped .. "\\b",
		"export\\s+const\\s+" .. escaped .. "\\b",
		"export\\s+let\\s+" .. escaped .. "\\b",
		"export\\s+var\\s+" .. escaped .. "\\b",
	}

	for _, pattern in ipairs(patterns) do
		local args = {
			"rg",
			"--line-number",
			"--no-heading",
			"--color=never",
			"--hidden",
			"--glob",
			"!**/.git/**",
			"--glob",
			"!**/node_modules/**",
			"--glob",
			"!**/dist/**",
			"--glob",
			"!**/build/**",
			"--glob",
			"!**/coverage/**",
			"--glob",
			"*.ts",
			"--glob",
			"*.tsx",
			"--glob",
			"*.mts",
			"--glob",
			"*.cts",
			"--glob",
			"*.js",
			"--glob",
			"*.jsx",
			"-m",
			"20",
			"-e",
			pattern,
			root,
		}
		local result = vim.system(args, { text = true }):wait()
		if result.code == 0 or (result.stdout and result.stdout ~= "") then
			for line in (result.stdout or ""):gmatch("[^\r\n]+") do
				local file = line:match("^(.-):%d+:")
				if file and vim.fs.normalize(file) ~= current_file then
					return vim.fs.normalize(file)
				end
			end
		end
	end

	return nil
end

local function find_python_definition(root, symbol, current_file)
	local escaped = rg_escape(symbol)
	local patterns = {
		"^class\\s+" .. escaped .. "\\b",
		"^async\\s+def\\s+" .. escaped .. "\\b",
		"^def\\s+" .. escaped .. "\\b",
		"^" .. escaped .. "\\s*:\\s*[^=]+\\s*=",
		"^" .. escaped .. "\\s*=",
	}

	for _, pattern in ipairs(patterns) do
		local args = {
			"rg",
			"--line-number",
			"--no-heading",
			"--color=never",
			"--hidden",
			"--glob",
			"!**/.git/**",
			"--glob",
			"!**/__pycache__/**",
			"--glob",
			"*.py",
			"-m",
			"20",
			"-e",
			pattern,
			root,
		}
		local result = vim.system(args, { text = true }):wait()
		if result.code == 0 or (result.stdout and result.stdout ~= "") then
			for line in (result.stdout or ""):gmatch("[^\r\n]+") do
				local file = line:match("^(.-):%d+:")
				if file and vim.fs.normalize(file) ~= current_file then
					return vim.fs.normalize(file)
				end
			end
		end
	end

	return nil
end

local function parse_typescript_named_imports(spec_text)
	local specs = {}
	for _, item in ipairs(split_top_level_commas(spec_text)) do
		local spec = trim_ws(item)
		if spec ~= "" then
			local lookup = spec
			lookup = lookup:gsub("^type%s+", "")
			lookup = trim_ws((lookup:gsub("%s+as%s+.+$", "")))
			specs[#specs + 1] = {
				text = spec,
				symbol = lookup,
			}
		end
	end
	return specs
end

local function rebuild_typescript_imports(indent, import_type_kw, groups, suffix)
	local lines = {}
	local paths = vim.tbl_keys(groups)
	table.sort(paths)

	for _, path in ipairs(paths) do
		local prefix = import_type_kw or ""
		lines[#lines + 1] = string.format(
			"%simport%s { %s } from '%s'%s",
			indent,
			prefix,
			table.concat(groups[path], ", "),
			path,
			suffix
		)
	end

	return lines
end

local function resolve_typescript_import_text(text, current_file, root)
	local indent, spec_text, quote1, source, quote2, suffix =
			text:match("^(%s*)import%s+type%s*{%s*([%s%S]-)%s*}%s+from%s+(['\"])(.-)(['\"])(.*)$")
	local import_type_kw = nil

	if indent then
		import_type_kw = " type"
	else
		indent, spec_text, quote1, source, quote2, suffix =
				text:match("^(%s*)import%s*{%s*([%s%S]-)%s*}%s+from%s+(['\"])(.-)(['\"])(.*)$")
	end

	if not indent or quote1 ~= quote2 or not is_placeholder_import_source(source) then
		return nil, nil
	end

	local groups = {}
	local unresolved = {}
	local resolved_count = 0

	for _, spec in ipairs(parse_typescript_named_imports(spec_text)) do
		local filepath = find_typescript_definition(root, spec.symbol, current_file)
		if filepath then
			local import_path = to_relative_module_path(current_file, filepath)
			groups[import_path] = groups[import_path] or {}
			groups[import_path][#groups[import_path] + 1] = spec.text
			resolved_count = resolved_count + 1
		else
			unresolved[#unresolved + 1] = spec.text
		end
	end

	if resolved_count == 0 then
		return nil, unresolved
	end

	if #unresolved > 0 then
		groups["?"] = unresolved
	end

	return rebuild_typescript_imports(indent, import_type_kw, groups, suffix), unresolved
end

local function resolve_typescript_import_block(lines, start_idx, current_file, root)
	if not (lines[start_idx] or ""):match("^%s*import%s") then
		return nil, nil, start_idx
	end

	local block = {}
	local last_missing = nil

	for end_idx = start_idx, math.min(#lines, start_idx + 24) do
		block[#block + 1] = lines[end_idx]
		local text = table.concat(block, "\n")
		local replacement, missing = resolve_typescript_import_text(text, current_file, root)
		if replacement then
			return replacement, missing, end_idx
		end
		last_missing = missing

		if end_idx > start_idx and lines[end_idx]:match("^%s*$") then
			break
		end
		if lines[end_idx]:find(";", 1, true) then
			break
		end
	end

	return nil, last_missing, start_idx
end

local function parse_python_import_names(spec_text)
	local specs = {}
	for _, item in ipairs(split_top_level_commas(spec_text)) do
		local spec = trim_ws(item)
		if spec ~= "" then
			local lookup = trim_ws((spec:gsub("%s+as%s+.+$", "")))
			specs[#specs + 1] = {
				text = spec,
				symbol = lookup,
			}
		end
	end
	return specs
end

local function rebuild_python_imports(indent, groups)
	local lines = {}
	local paths = vim.tbl_keys(groups)
	table.sort(paths)

	for _, path in ipairs(paths) do
		lines[#lines + 1] = string.format(
			"%sfrom %s import %s",
			indent,
			path,
			table.concat(groups[path], ", ")
		)
	end

	return lines
end

local function resolve_python_import_line(line, current_file, root)
	local indent, module_name, spec_text = line:match("^(%s*)from%s+([^%s]+)%s+import%s+(.+)$")
	if not indent or not is_placeholder_import_source(module_name:gsub("['\"]", "")) then
		return nil, nil
	end

	local groups = {}
	local unresolved = {}
	local resolved_count = 0

	for _, spec in ipairs(parse_python_import_names(spec_text)) do
		local filepath = find_python_definition(root, spec.symbol, current_file)
		if filepath then
			local import_path = to_python_module_path(root, filepath)
			groups[import_path] = groups[import_path] or {}
			groups[import_path][#groups[import_path] + 1] = spec.text
			resolved_count = resolved_count + 1
		else
			unresolved[#unresolved + 1] = spec.text
		end
	end

	if resolved_count == 0 then
		return nil, unresolved
	end

	if #unresolved > 0 then
		groups["???"] = unresolved
	end

	return rebuild_python_imports(indent, groups), unresolved
end

local function fill_import_sources()
	if vim.fn.executable("rg") ~= 1 then
		vim.notify("ripgrep (rg) is required to fill import sources", vim.log.levels.WARN)
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.bo[bufnr].modifiable then
		vim.notify("Current buffer is not modifiable", vim.log.levels.WARN)
		return
	end

	local current_file = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
	local root = get_nvim_cwd()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local new_lines = {}
	local changed = 0
	local unresolved = {}

	local line_idx = 1
	while line_idx <= #lines do
		local line = lines[line_idx]
		local replacement, missing, end_idx = resolve_typescript_import_block(lines, line_idx, current_file, root)
		if not replacement then
			replacement, missing = resolve_python_import_line(line, current_file, root)
			end_idx = line_idx
		end

		if replacement then
			changed = changed + 1
			vim.list_extend(new_lines, replacement)
			if missing and #missing > 0 then
				vim.list_extend(unresolved, missing)
			end
		else
			new_lines[#new_lines + 1] = line
			if missing and #missing > 0 then
				vim.list_extend(unresolved, missing)
			end
		end
		line_idx = (end_idx or line_idx) + 1
	end

	if changed == 0 then
		vim.notify(
			"No placeholder imports were resolved from cwd: " .. root,
			vim.log.levels.INFO
		)
		return
	end

	local view = vim.fn.winsaveview()
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
	vim.fn.winrestview(view)

	if #unresolved > 0 then
		vim.notify(
			string.format(
				"Filled %d import line(s); unresolved: %s",
				changed,
				table.concat(unresolved, ", ")
			),
			vim.log.levels.WARN
		)
		return
	end

	vim.notify(string.format("Filled %d import line(s)", changed), vim.log.levels.INFO)
end

local function get_visual_selection_range()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local sr, sc = start_pos[2], start_pos[3]
	local er, ec = end_pos[2], end_pos[3]
	if sr == 0 or er == 0 then
		return nil
	end

	if sr > er or (sr == er and sc > ec) then
		sr, er = er, sr
		sc, ec = ec, sc
	end

	local start_line = vim.api.nvim_buf_get_lines(0, sr - 1, sr, false)[1] or ""
	local end_line = vim.api.nvim_buf_get_lines(0, er - 1, er, false)[1] or ""
	if sc < 1 then sc = 1 end
	if ec < 1 then ec = 1 end
	if sc > #start_line + 1 then sc = #start_line + 1 end
	if ec > #end_line then ec = #end_line end

	local lines = vim.api.nvim_buf_get_lines(0, sr - 1, er, false)
	if #lines == 0 then return nil end
	if sr == er then
		lines = { start_line:sub(sc, ec) }
	else
		lines[1] = lines[1]:sub(sc)
		lines[#lines] = lines[#lines]:sub(1, ec)
	end

	return {
		sr = sr,
		sc = sc,
		er = er,
		ec = ec,
		text = table.concat(lines, "\n"),
		base_indent = (start_line:sub(1, sc - 1):match("^%s*") or ""),
	}
end

local function run_in_terminal(run_cmd, opts)
	opts = opts or {}
	local shell = vim.o.shell or "sh"
	local cleanup_prompt_path = opts.cleanup_prompt_path
	local timeout = opts.timeout

	local function maybe_prompt_cleanup()
		if not cleanup_prompt_path or cleanup_prompt_path == "" then
			return
		end
		if not run_program_tempfile.prompt_on_delete then
			vim.fn.delete(cleanup_prompt_path)
			return
		end
		vim.schedule(function()
			local prompt = "Delete temp file after run?\n" .. cleanup_prompt_path
			local answer = vim.fn.confirm(prompt, "&Yes\n&No", 1)
			if answer == 1 then
				vim.fn.delete(cleanup_prompt_path)
			else
				vim.notify("Kept temp file: " .. cleanup_prompt_path, vim.log.levels.INFO)
			end
		end)
	end

	local function close_session(session)
		if not session or session.closed then
			return
		end
		session.closed = true
		if session.timer then
			pcall(vim.fn.timer_stop, session.timer)
			session.timer = nil
		end
		maybe_prompt_cleanup()
		vim.schedule(function()
			if session.win and vim.api.nvim_win_is_valid(session.win) then
				pcall(vim.api.nvim_win_close, session.win, true)
			end
			if session.buf and vim.api.nvim_buf_is_valid(session.buf) then
				pcall(vim.api.nvim_buf_delete, session.buf, { force = true })
			end
			if run_program_session == session then
				run_program_session = nil
			end
		end)
	end

	local function stop_session(session)
		if not session or session.closed then
			return
		end
		if session.job_id then
			pcall(vim.fn.jobstop, session.job_id)
		end
		close_session(session)
	end

	if run_program_session and not run_program_session.closed then
		stop_session(run_program_session)
	end

	local width = math.max(60, math.floor(vim.o.columns * 0.8))
	local height = math.max(12, math.floor(vim.o.lines * 0.7))
	local row = math.max(1, math.floor((vim.o.lines - height) / 2 - 1))
	local col = math.max(0, math.floor((vim.o.columns - width) / 2))
	local term_buf = vim.api.nvim_create_buf(false, true)
	local term_win = vim.api.nvim_open_win(term_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "single",
		title = " Run ",
		title_pos = "center",
	})

	vim.bo[term_buf].bufhidden = "wipe"

	local session = {
		buf = term_buf,
		win = term_win,
		job_id = nil,
		timer = nil,
		closed = false,
	}
	run_program_session = session

	local launch_cmd = run_cmd
	if timeout and timeout > 0 then
		launch_cmd = string.format("printf 'Closing in %ss...\\n'; %s", timeout, run_cmd)
	else
		launch_cmd = string.format("printf 'Running... output will stay open. Press Enter, q, or Ctrl-C to close.\\n\\n'; %s", run_cmd)
	end

	local job_id = vim.fn.termopen({ shell, "-lc", launch_cmd }, {
		on_exit = function()
			session.job_id = nil
			if timeout and timeout > 0 then
				close_session(session)
				return
			end
			vim.schedule(function()
				pcall(vim.cmd, "stopinsert")
			end)
		end,
	})
	session.job_id = job_id

	for _, lhs in ipairs({ "<CR>", "q" }) do
		vim.keymap.set("n", lhs, function()
			stop_session(session)
		end, { buffer = term_buf, silent = true, nowait = true })
	end
	vim.keymap.set("n", "<C-c>", function()
		stop_session(session)
	end, { buffer = term_buf, silent = true, nowait = true })

	if timeout and timeout > 0 then
		session.timer = vim.fn.timer_start(math.floor(timeout * 1000), function()
			vim.schedule(function()
				stop_session(session)
			end)
		end)
	end

	vim.cmd("startinsert")
end

local function tmux_navigate(direction)
	local mode = vim.api.nvim_get_mode().mode
	if mode:sub(1, 1) == "t" then
		vim.cmd("stopinsert")
	end

	local before_win = vim.api.nvim_get_current_win()
	local before_tab = vim.api.nvim_get_current_tabpage()
	vim.cmd("TmuxNavigate" .. direction)

	local after_win = vim.api.nvim_get_current_win()
	local after_tab = vim.api.nvim_get_current_tabpage()
	if after_tab ~= before_tab or after_win ~= before_win then
		return
	end

	local wrap_cmd = {
		Left = "999wincmd l",
		Right = "999wincmd h",
		Up = "999wincmd j",
		Down = "999wincmd k",
	}
	local cmd = wrap_cmd[direction]
	if cmd then
		vim.cmd(cmd)
	end
end

local function build_run_command(filepath, search_path)
	local function prepend_project_venv(run_cmd, search_path)
		local start = vim.fs.dirname(search_path or filepath)
		local venv = vim.fs.find(".venv", {
			path = start,
			upward = true,
		})[1]
		if not venv then
			return run_cmd
		end

		if vim.fn.isdirectory(venv) == 1 then
			local activate = venv .. "/bin/activate"
			if vim.fn.filereadable(activate) == 1 then
				return "source " .. vim.fn.shellescape(activate) .. " && " .. run_cmd
			end
		end

		if vim.fn.filereadable(venv) == 1 then
			return "source " .. vim.fn.shellescape(venv) .. " && " .. run_cmd
		end

		return run_cmd
	end

	local ft = vim.bo.filetype
	local escaped_file = vim.fn.shellescape(filepath)
	local run_cmd = nil

	local function build_python_run_cmd()
		local source_path = search_path or filepath
		if filepath ~= source_path then
			return "python " .. escaped_file
		end

		local normalized_source = vim.fs.normalize(source_path)
		local start = vim.fs.dirname(normalized_source)
		local cwd = vim.fs.normalize(vim.fn.getcwd())
		local git_dir = vim.fs.find(".git", {
			path = start,
			upward = true,
		})[1]
		local run_root = cwd
		if git_dir then
			run_root = vim.fs.dirname(git_dir)
		end
		if normalized_source:sub(1, #cwd + 1) == cwd .. "/" or normalized_source == cwd then
			run_root = cwd
		end

		local rel = vim.fs.relpath(run_root, normalized_source)
		if not rel or rel:sub(-3) ~= ".py" then
			return "python " .. escaped_file
		end

		local module = rel:gsub("%.py$", ""):gsub("/", ".")
		module = module:gsub("%.__init__$", "")
		if module == "" or module:find("[^%w_%.]") then
			return "python " .. escaped_file
		end

		return "cd " .. vim.fn.shellescape(run_root) .. " && python -m " .. module
	end

	local function build_rust_run_cmd()
		local compiler = vim.env.RUSTC or "rustc"
		local stem = vim.fn.fnamemodify(filepath, ":t:r")
		local bin = vim.fn.tempname() .. "_" .. stem
		local escaped_bin = vim.fn.shellescape(bin)
		return string.format("%s %s -o %s && %s; exit_code=$?; rm -f %s; exit $exit_code", compiler, escaped_file, escaped_bin, escaped_bin, escaped_bin)
	end

	if ft == "python" then
		run_cmd = build_python_run_cmd()
	end
	if ft == "c" then
		local stem = vim.fn.fnamemodify(filepath, ":t:r")
		local bin = vim.fn.tempname() .. "_" .. stem
		local escaped_bin = vim.fn.shellescape(bin)
		local compiler = vim.env.CC or "cc"
		run_cmd = string.format("%s %s -o %s && %s; exit_code=$?; rm -f %s; exit $exit_code", compiler, escaped_file, escaped_bin, escaped_bin, escaped_bin)
	end
	if ft == "javascript" then
		run_cmd = "node " .. escaped_file
	end
	if ft == "typescript" then
		run_cmd = "node --experimental-strip-types " .. escaped_file
	end
	if ft == "lua" then
		run_cmd = "lua " .. escaped_file
	end
	if ft == "rust" then
		run_cmd = build_rust_run_cmd()
	end
	if ft == "sh" or ft == "bash" or ft == "zsh" then
		run_cmd = "bash " .. escaped_file
	end

	if run_cmd then
		return prepend_project_venv(run_cmd, search_path)
	end

	local ext = vim.fn.fnamemodify(filepath, ":e")
	if ext == "py" then
		run_cmd = build_python_run_cmd()
	end
	if ext == "c" then
		local stem = vim.fn.fnamemodify(filepath, ":t:r")
		local bin = vim.fn.tempname() .. "_" .. stem
		local escaped_bin = vim.fn.shellescape(bin)
		local compiler = vim.env.CC or "cc"
		run_cmd = string.format("%s %s -o %s && %s; exit_code=$?; rm -f %s; exit $exit_code", compiler, escaped_file, escaped_bin, escaped_bin, escaped_bin)
	end
	if ext == "js" then
		run_cmd = "node " .. escaped_file
	end
	if ext == "ts" then
		run_cmd = "node --experimental-strip-types " .. escaped_file
	end
	if ext == "lua" then
		run_cmd = "lua " .. escaped_file
	end
	if ext == "rs" then
		run_cmd = build_rust_run_cmd()
	end
	if ext == "sh" or ext == "bash" or ext == "zsh" then
		run_cmd = "bash " .. escaped_file
	end

	if run_cmd then
		return prepend_project_venv(run_cmd, search_path)
	end

	return nil
end

function M.run_program(opts)
	opts = opts or {}
	local use_visual = opts.use_visual == true
	local timeout = opts.timeout

	local filepath = vim.api.nvim_buf_get_name(0)
	if filepath == "" then
		vim.notify("Current buffer has no file path", vim.log.levels.WARN)
		return
	end
	if vim.bo.buftype ~= "" then
		vim.notify("RunProgram only supports file buffers", vim.log.levels.WARN)
		return
	end
	if vim.bo.modified then
		vim.cmd.write()
	end

	local target_path = filepath
	local cleanup_prompt_path = nil

	if use_visual then
		local range = get_visual_selection_range()
		if not range then
			vim.notify("Select text in visual mode, then run <leader>rr", vim.log.levels.WARN)
			return
		end

		local ext = vim.fn.fnamemodify(filepath, ":e")
		target_path = vim.fn.tempname()
		if ext ~= "" then
			target_path = target_path .. "." .. ext
		end

		local selected_lines = vim.split(range.text, "\n", { plain = true })
		vim.fn.writefile(selected_lines, target_path)

		cleanup_prompt_path = target_path
	end

	local run_cmd = build_run_command(target_path, filepath)
	if not run_cmd then
		vim.notify("RunProgram unsupported for filetype: " .. (vim.bo.filetype or ""), vim.log.levels.WARN)
		if target_path ~= filepath then
			vim.fn.delete(target_path)
		end
		return
	end

	run_in_terminal(run_cmd, {
		cleanup_prompt_path = cleanup_prompt_path,
		timeout = timeout,
	})
end

local function find_vite_project_root(path)
	local start = path
	if vim.fn.isdirectory(start) ~= 1 then
		start = vim.fs.dirname(path)
	end
	local vite_config = vim.fs.find({
		"vite.config.ts",
		"vite.config.js",
		"vite.config.mjs",
		"vite.config.cjs",
	}, {
		path = start,
		upward = true,
	})[1]
	if vite_config then
		return vim.fs.dirname(vite_config)
	end

	local pkg = vim.fs.find("package.json", { path = start, upward = true })[1]
	if not pkg then
		return nil
	end
	local ok, pkg_json = pcall(vim.fn.readfile, pkg)
	if not ok then
		return nil
	end
	local text = table.concat(pkg_json, "\n")
	if text:find('"vite"', 1, true) then
		return vim.fs.dirname(pkg)
	end
	return nil
end

local function parse_http_host_port(url)
	url = vim.trim(url or "")
	local scheme, authority = url:match("^(https?)://([^/]+)")
	if not scheme or not authority then
		return nil, nil
	end

	authority = vim.trim(authority)
	local host, port = authority:match("^%[([^%]]+)%]:(%d+)$")
	if not host then
		host, port = authority:match("^([^:]+):(%d+)$")
	end
	if not host then
		host = authority
		port = scheme == "https" and "443" or "80"
	end

	return vim.trim(host), tonumber(port)
end

local function is_tcp_port_open(host, port, timeout_ms)
	local uv = vim.uv or vim.loop
	if not uv then
		return false
	end

	local targets = { host }
	if host == "localhost" then
		targets = { "127.0.0.1", "localhost" }
	end

	for _, target in ipairs(targets) do
		local tcp = uv.new_tcp()
		if tcp then
			local done = false
			local ok = false
			local connect_ok = pcall(function()
				tcp:connect(target, port, function(err)
					ok = err == nil
					done = true
					pcall(function()
						tcp:close()
					end)
				end)
			end)

			if connect_ok then
				vim.wait(timeout_ms or 300, function()
					return done
				end, 25)
			end

			if not done then
				pcall(function()
					tcp:close()
				end)
			end

			if connect_ok and ok then
				return true
			end
		end
	end

	return false
end

local function ensure_vite_server(vite_root, dev_url)
	local host, port = parse_http_host_port(dev_url)
	if not host or not port then
		return false, "Invalid Vite dev URL: " .. dev_url, false
	end

	if is_tcp_port_open(host, port, 300) then
		return true, nil, false
	end

	if vim.fn.executable("npm") ~= 1 then
		return false, "npm is not installed or not in PATH", false
	end
	if vim.fn.executable("tmux") ~= 1 then
		return false, "tmux is not installed or not in PATH", false
	end
	if vim.fn.isdirectory(vite_root) ~= 1 then
		return false, "Vite root directory does not exist: " .. vite_root, false
	end

	local session_name = "sys"
	local has_session = vim.system({ "tmux", "has-session", "-t", session_name }, { text = true }):wait()
	if has_session.code ~= 0 then
		local create_session = vim.system({
			"tmux",
			"new-session",
			"-d",
			"-s",
			session_name,
		}, { text = true }):wait()
		if create_session.code ~= 0 then
			local details = vim.trim(create_session.stderr or create_session.stdout or "")
			if details ~= "" then
				return false, "Failed to create tmux session `" .. session_name .. "`: " .. details, false
			end
			return false, "Failed to create tmux session `" .. session_name .. "`", false
		end
	end

	local tmux_start = vim.system({
		"tmux",
		"new-window",
		"-d",
		"-t",
		session_name,
		"-n",
		"vite-dev",
		"-c",
		vite_root,
		"npm",
		"run",
		"dev",
	}, { text = true }):wait()
	if tmux_start.code ~= 0 then
		local details = vim.trim(tmux_start.stderr or tmux_start.stdout or "")
		if details ~= "" then
			return false, "Failed to start Vite in tmux: " .. details, false
		end
		return false, "Failed to start Vite in tmux", false
	end

	return true, nil, true
end

function M.launch_in_browser()
	local filepath = vim.api.nvim_buf_get_name(0)
	if filepath == "" then
		vim.notify("Current buffer has no file path", vim.log.levels.WARN)
		return
	end
	if vim.bo.buftype ~= "" then
		vim.notify("LaunchInBrowser only supports file buffers", vim.log.levels.WARN)
		return
	end
	if vim.fn.executable("firefox") ~= 1 then
		vim.notify("firefox is not installed or not in PATH", vim.log.levels.WARN)
		return
	end
	if vim.bo.modified then
		vim.cmd.write()
	end

	local vite_root = find_vite_project_root(vim.fn.getcwd())
	if vite_root then
		local dev_url = vim.env.VITE_DEV_URL or "http://localhost:5173"
		local ok, err, started_now = ensure_vite_server(vite_root, dev_url)
		if not ok then
			vim.notify(err, vim.log.levels.WARN)
			return
		end
		if started_now then
			vim.notify("Starting Vite in tmux session `sys`...", vim.log.levels.INFO)
			return
		end
		vim.fn.jobstart({ "firefox", "--new-window", dev_url }, { detach = true })
		return
	end

	local uri = vim.uri_from_fname(filepath)
	vim.fn.jobstart({ "firefox", "--new-window", uri }, { detach = true })
end

local function format_current_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({
	  bufnr = bufnr,
	  method = "textDocument/formatting"
	})
	if not clients or #clients == 0 then
		vim.notify("No LSP formatter attached for this buffer", vim.log.levels.WARN)
		return
	end
	vim.lsp.buf.format({ async = true, bufnr = bufnr })
end

local function markdown_preview_sync(source_buf, preview_buf)
	if not (vim.api.nvim_buf_is_valid(source_buf) and vim.api.nvim_buf_is_valid(preview_buf)) then
		return
	end
	local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
	vim.bo[preview_buf].modifiable = true
	vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
	vim.bo[preview_buf].modifiable = false
end

function M.markdown_side_preview()
	local source_buf = vim.api.nvim_get_current_buf()
	if vim.bo[source_buf].filetype ~= "markdown" then
		vim.notify("MarkdownSidePreview only works for markdown buffers", vim.log.levels.WARN)
		return
	end

	local current = markdown_preview_pairs[source_buf]
	if current and vim.api.nvim_buf_is_valid(current.preview_buf) then
		if current.preview_win and vim.api.nvim_win_is_valid(current.preview_win) then
			vim.api.nvim_win_close(current.preview_win, true)
		end
		pcall(vim.api.nvim_buf_delete, current.preview_buf, { force = true })
		markdown_preview_pairs[source_buf] = nil
		return
	end

	local group = vim.api.nvim_create_augroup("MarkdownSidePreview_" .. source_buf, { clear = true })

	vim.cmd("botright vsplit")
	vim.cmd("wincmd L")
	local preview_win = vim.api.nvim_get_current_win()
	local preview_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(preview_win, preview_buf)

	vim.bo[preview_buf].buftype = "nofile"
	vim.bo[preview_buf].bufhidden = "wipe"
	vim.bo[preview_buf].swapfile = false
	vim.bo[preview_buf].modifiable = false
	vim.bo[preview_buf].filetype = "markdown"

	vim.wo[preview_win].number = false
	vim.wo[preview_win].relativenumber = false
	vim.wo[preview_win].signcolumn = "no"
	vim.wo[preview_win].foldcolumn = "0"
	vim.wo[preview_win].wrap = true
	vim.wo[preview_win].linebreak = true
	vim.wo[preview_win].cursorline = false
	vim.wo[preview_win].winhighlight = "Normal:MarkdownPreviewNormal,EndOfBuffer:MarkdownPreviewNormal"

	set(0, "MarkdownPreviewNormal", { fg = "#e6e1cf", bg = "#0f1419" })

	markdown_preview_pairs[source_buf] = {
		preview_buf = preview_buf,
		preview_win = preview_win,
		group = group,
	}

	markdown_preview_sync(source_buf, preview_buf)
	pcall(vim.api.nvim_win_call, preview_win, function()
		require("render-markdown").buf_enable()
	end)

	vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI" }, {
		group = group,
		buffer = source_buf,
		callback = function()
			local pair = markdown_preview_pairs[source_buf]
			if not pair then
				return
			end
			if not (vim.api.nvim_buf_is_valid(pair.preview_buf) and vim.api.nvim_win_is_valid(pair.preview_win)) then
				markdown_preview_pairs[source_buf] = nil
				pcall(vim.api.nvim_del_augroup_by_id, group)
				return
			end
			markdown_preview_sync(source_buf, pair.preview_buf)
			pcall(vim.api.nvim_win_call, pair.preview_win, function()
				require("render-markdown").buf_enable()
			end)
		end,
		desc = "Sync markdown side preview",
	})

	vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
		group = group,
		buffer = source_buf,
		callback = function()
			local pair = markdown_preview_pairs[source_buf]
			if not pair then
				return
			end
			if pair.preview_win and vim.api.nvim_win_is_valid(pair.preview_win) then
				vim.api.nvim_win_close(pair.preview_win, true)
			end
			if pair.preview_buf and vim.api.nvim_buf_is_valid(pair.preview_buf) then
				pcall(vim.api.nvim_buf_delete, pair.preview_buf, { force = true })
			end
			markdown_preview_pairs[source_buf] = nil
			pcall(vim.api.nvim_del_augroup_by_id, group)
		end,
		desc = "Close markdown side preview when source closes",
	})

	vim.api.nvim_set_current_buf(source_buf)
end

function M.keymaps()
	vim.keymap.set("n", "<leader>ah", add_file_header, {
		noremap = true,
		silent = true,
		desc = "Add file header",
	})

	local map = vim.keymap.set
	local opts = { noremap = true, silent = true }

	map("n", "<leader>hh", "<C-w>h", opts)
	map("n", "<leader>jj", "<C-w>j", opts)
	map("n", "<leader>kk", "<C-w>k", opts)
	map("n", "<leader>ll", "<C-w>l", opts)
	map("n", "<leader>uf", "<cmd>Unfold<cr>", vim.tbl_extend("force", opts, {
		desc = "Unfold comma-separated list",
	}))
	map("n", "<leader>fu", "<cmd>Fold<cr>", vim.tbl_extend("force", opts, {
		desc = "Fold comma-separated list",
	}))
	map("x", "<leader>uf", ":<C-u>Unfold<cr>", vim.tbl_extend("force", opts, {
		desc = "Unfold selected comma-separated list",
	}))
	map("x", "<leader>fu", ":<C-u>Fold<cr>", vim.tbl_extend("force", opts, {
		desc = "Fold selected comma-separated list",
	}))
	map("n", "<leader>f}", "<cmd>Fold<cr>", vim.tbl_extend("force", opts, {
		desc = "Fold around nearest {}",
	}))
	map("n", "<leader>f]", "<cmd>Fold<cr>", vim.tbl_extend("force", opts, {
		desc = "Fold around nearest []",
	}))
	map("n", "<leader>f)", "<cmd>Fold<cr>", vim.tbl_extend("force", opts, {
		desc = "Fold around nearest ()",
	}))
	map("n", "<leader>u}", "<cmd>Unfold<cr>", vim.tbl_extend("force", opts, {
		desc = "Unfold around nearest {}",
	}))
	map("n", "<leader>u]", "<cmd>Unfold<cr>", vim.tbl_extend("force", opts, {
		desc = "Unfold around nearest []",
	}))
	map("n", "<leader>u)", "<cmd>Unfold<cr>", vim.tbl_extend("force", opts, {
		desc = "Unfold around nearest ()",
	}))
	map("n", "gx", open_todo_link, vim.tbl_extend("force", opts, {
		desc = "Open todo link under cursor",
	}))
	map("n", "<leader>oo", M.launch_in_browser, vim.tbl_extend("force", opts, {
		desc = "Open current file in browser",
	}))
	map("n", "<leader>F", format_current_buffer, vim.tbl_extend("force", opts, {
		desc = "Format current buffer with LSP",
	}))
	map("n", "<leader>dd", vim.diagnostic.open_float, vim.tbl_extend("force", opts, {
		desc = "Show diagnostics under cursor",
	}))
	map("n", "<leader>zz", "<cmd>ZenMode<cr>", vim.tbl_extend("force", opts, {
		desc = "Toggle Zen Mode",
	}))
	map("n", "<leader>DD", function()
		vim.diagnostic.setqflist({ open = true })
	end, vim.tbl_extend("force", opts, {
		desc = "Show all diagnostics",
	}))
	map("n", "<leader>fi", "<cmd>FillImportSources<cr>", vim.tbl_extend("force", opts, {
		desc = "Fill placeholder import sources",
	}))
	map("n", "<leader>ed", "<cmd>ExternalDiff<cr>", vim.tbl_extend("force", opts, {
		desc = "Diff current buffer against disk",
	}))
	map("n", "<leader>er", "<cmd>ExternalReload<cr>", vim.tbl_extend("force", opts, {
		desc = "Reload current buffer from disk",
	}))
	map("x", "<leader>rr", function()
		M.run_program({ use_visual = true })
	end, vim.tbl_extend("force", opts, {
		desc = "Run selected text via temp file",
	}))

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

function M.autocmds()
	local group = vim.api.nvim_create_augroup("file_header", { clear = true })
	vim.o.autoread = false

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function()
			if is_empty_named_buffer() then
				add_file_header({ silent = true })
			end

			maybe_checktime()
		end,
		desc = "Add file header to empty files",
	})

	vim.api.nvim_create_user_command("SyncTodoMd", function()
		sync_todo_markdown(0)
	end, { desc = "Sync project TODOs into todo.md" })

	vim.api.nvim_create_user_command("OpenTodoLink", open_todo_link, {
		desc = "Open todo link under cursor",
	})
	vim.api.nvim_create_user_command("FillImportSources", fill_import_sources, {
		desc = "Resolve placeholder import sources from the current working directory",
	})
	vim.api.nvim_create_user_command("ExternalDiff", function()
		open_external_diff()
	end, {
		desc = "Open a diff between current buffer and the on-disk file",
	})
	vim.api.nvim_create_user_command("ExternalReviewAccept", function()
		accept_external_review()
	end, {
		desc = "Accept external changes for the active review session",
	})
	vim.api.nvim_create_user_command("ExternalReviewAcceptQuit", function()
		accept_external_review({ quit = true })
	end, {
		desc = "Accept external changes and quit the current window",
	})
	vim.api.nvim_create_user_command("ExternalReviewAcceptQuitAll", function()
		accept_external_review({ quit_all = true })
	end, {
		desc = "Accept external changes and quit Neovim",
	})
	vim.api.nvim_create_user_command("ExternalReviewReject", function()
		reject_external_review()
	end, {
		desc = "Reject external changes for the active review session",
	})
	vim.api.nvim_create_user_command("ExternalReload", function()
		reload_current_buffer_from_disk()
	end, {
		desc = "Reload current buffer from disk if it is safe to do so",
	})
	vim.api.nvim_create_user_command("Run", function(command_opts)
		local timeout = nil
		if command_opts.args ~= "" then
			timeout = tonumber(command_opts.args)
			if not timeout or timeout <= 0 then
				vim.notify("Run timeout must be a positive number of seconds", vim.log.levels.ERROR)
				return
			end
		end
		M.run_program({ timeout = timeout })
	end, {
		nargs = "?",
		desc = "Run the current file, optionally auto-closing after N seconds",
	})
	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		pattern = "todo.md",
		callback = function(args)
			sync_todo_markdown(args.buf)
		end,
		desc = "Sync project TODOs into todo.md",
	})
	vim.api.nvim_create_autocmd({ "FocusGained", "TermClose" }, {
		group = group,
		callback = maybe_checktime,
		desc = "Check for file changes after focus returns or terminal commands finish",
	})
	vim.api.nvim_create_autocmd("FileChangedShell", {
		group = group,
		callback = function(args)
			local bufnr = args.buf
			if not is_normal_file_buffer(bufnr) then
				return
			end

			vim.v.fcs_choice = ""
			local is_new_change = mark_external_change(bufnr)
			local rejected_mtime = vim.b[bufnr].external_change_rejected_mtime

			local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
			local reason = vim.v.fcs_reason ~= "" and (" (" .. vim.v.fcs_reason .. ")") or ""
			vim.schedule(function()
				if not is_new_change or not vim.api.nvim_buf_is_valid(bufnr) or not current_buffer_matches_disk(bufnr) then
					return
				end

				if rejected_mtime ~= nil and rejected_mtime == vim.b[bufnr].external_change_mtime then
					vim.notify(
						("External change still pending for %s%s. Re-open with :ExternalDiff if needed."):format(filename, reason),
						vim.log.levels.INFO
					)
					return
				end

				if M.external_file_review.auto_open then
					open_external_diff({ bufnr = bufnr })
					return
				end

				vim.notify(
					("External change detected for %s%s. Review with :ExternalDiff or <leader>ed."):format(filename, reason),
					vim.log.levels.WARN
				)
			end)
		end,
		desc = "Detect but do not auto-reload externally changed files",
	})
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		callback = function(args)
			clear_external_change(args.buf)
		end,
		desc = "Clear external change marker after writing the buffer",
	})

	vim.cmd([[cnoreabbrev <expr> w v:lua.external_review_command_abbrev('w')]])
	vim.cmd([[cnoreabbrev <expr> w! v:lua.external_review_command_abbrev('w!')]])
	vim.cmd([[cnoreabbrev <expr> wa v:lua.external_review_command_abbrev('wa')]])
	vim.cmd([[cnoreabbrev <expr> wa! v:lua.external_review_command_abbrev('wa!')]])
	vim.cmd([[cnoreabbrev <expr> wall v:lua.external_review_command_abbrev('wall')]])
	vim.cmd([[cnoreabbrev <expr> wall! v:lua.external_review_command_abbrev('wall!')]])
	vim.cmd([[cnoreabbrev <expr> write v:lua.external_review_command_abbrev('write')]])
	vim.cmd([[cnoreabbrev <expr> write! v:lua.external_review_command_abbrev('write!')]])
	vim.cmd([[cnoreabbrev <expr> update v:lua.external_review_command_abbrev('update')]])
	vim.cmd([[cnoreabbrev <expr> wq v:lua.external_review_command_abbrev('wq')]])
	vim.cmd([[cnoreabbrev <expr> wq! v:lua.external_review_command_abbrev('wq!')]])
	vim.cmd([[cnoreabbrev <expr> wqa v:lua.external_review_command_abbrev('wqa')]])
	vim.cmd([[cnoreabbrev <expr> wqa! v:lua.external_review_command_abbrev('wqa!')]])
	vim.cmd([[cnoreabbrev <expr> x v:lua.external_review_command_abbrev('x')]])
	vim.cmd([[cnoreabbrev <expr> x! v:lua.external_review_command_abbrev('x!')]])
	vim.cmd([[cnoreabbrev <expr> xa v:lua.external_review_command_abbrev('xa')]])
	vim.cmd([[cnoreabbrev <expr> xa! v:lua.external_review_command_abbrev('xa!')]])
	vim.cmd([[cnoreabbrev <expr> xit v:lua.external_review_command_abbrev('xit')]])
	vim.cmd([[cnoreabbrev <expr> xall v:lua.external_review_command_abbrev('xall')]])

	apply_cmp_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function()
			apply_cmp_highlights()
		end,
		desc = "Refresh completion highlights after colorscheme changes",
	})
end

-- Surround
function M.surround()
	require("nvim-surround").setup({
		aliases = {
			["q"] = { '"', "'", "`" },
			["b"] = { ")", "]", "}" },
		},
		highlight = { duration = 0 },
	})
end

-- Align
function M.align()
	local align = require("nvim-align")
	align.setup({
		preview = true,
		default_spacing = 1,
		default_jit = false,
		keymaps = { start = "ga", stop = "gA" },
	})
end

-- Autopairs
function M.autopairs()
	local ok, npairs = pcall(require, "nvim-autopairs")
	if not ok then
		vim.notify("nvim-autopairs not available", vim.log.levels.WARN)
		return
	end
	npairs.setup({
		check_ts = true,
		ts_config = {
			html = { "text" },
		},
		disable_filetype = { "TelescopePrompt", "vim" },
		enable_afterquote = true,
		enable_check_bracket_line = true,
		fast_wrap = {
			map = "<M-e>",
			chars = { "(", "[", "{", '"', "'" },
			pattern = [=[[%'%"%)%>%]%)%}%,]]=],
			end_key = "$",
			keys = "qwertyuiopasdfghjklzxcvbnm",
			manual_position = true,
			highlight = "Search",
			highlight_grey = "Comment",
		},
	})
	local present_rule, Rule = pcall(require, "nvim-autopairs.rule")
	if not present_rule then return end
	npairs.add_rules({
		Rule("__", "__", "python")
				:with_pair(function(opts)
					local prev = opts.prev_char or ""
					if prev:match("%w") then
						return false
					end
					return true
				end)
				:with_move(function(opts)
					return opts.next_char == "_"
				end)
				:use_key("_"),
	})
end

function M.cmp()
	local ok, cmp = pcall(require, "cmp")
	if not ok then
		vim.notify("nvim-cmp not available", vim.log.levels.WARN)
		return
	end

	local function current_cmp_config()
		return {
			enabled = function()
				return vim.bo.buftype ~= "prompt"
			end,
			completion = {
				autocomplete = cmp_autocomplete_enabled and { cmp.TriggerEvent.TextChanged } or false,
				completeopt = "menu,menuone,noinsert,noselect",
			},
			preselect = cmp.PreselectMode.None,
			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},
			mapping = cmp.mapping.preset.insert({
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<A-Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
				["<A-Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
				["<A-Right>"] = cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace }),
				["<CR>"] = cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace }),
			}),
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "path" },
				{ name = "buffer" },
			}),
		}
	end

	local function apply_cmp_config()
		cmp.setup(current_cmp_config())
		if not cmp_autocomplete_enabled then
			cmp.abort()
		end
	end

	apply_cmp_config()

	vim.keymap.set("n", "<leader>cc", function()
		cmp_autocomplete_enabled = not cmp_autocomplete_enabled
		apply_cmp_config()
		vim.notify(
			string.format("Completion %s", cmp_autocomplete_enabled and "enabled" or "disabled"),
			vim.log.levels.INFO
		)
	end, {
		noremap = true,
		silent = true,
		desc = "Toggle completion popup",
	})
end

-- Telescope
function M.telescope()
	local borders = { "─", "│", "─", "│", "┌", "┐", "┘", "└" }

	local ok, telescope = pcall(require, "telescope")
	if not ok then return end

	local actions = require("telescope.actions")

	telescope.setup({
		defaults = {
			prompt_prefix = "   ",
			selection_caret = " ",
			path_display = { "smart" },
			sorting_strategy = "ascending",
			layout_strategy = "bottom_pane",
			layout_config = {
				prompt_position = "top",
				preview_cutoff = 1,
				height = 25,
				bottom_pane = {
					height = 25,
					prompt_position = "top",
					preview_cutoff = 1,
				},
			},
			border = true,
			borderchars = {
				prompt = { "─", " ", " ", " ", "─", "─", " ", " " },
				results = { " " },
				preview = borders,
			},
			file_ignore_patterns = {},
			respect_gitignore = true,
			hidden = true,
			mappings = {
				i = {
					["<esc>"] = actions.close,
					["<C-j>"] = actions.move_selection_next,
					["<C-k>"] = actions.move_selection_previous,
				},
			},
		},
		pickers = {
			find_files = {
				hidden = true,
				no_ignore = false,
			},
			live_grep = {
				additional_args = function()
					return { "--hidden" }
				end,
			},
		},
		extensions = {
			fzf = {
				fuzzy = true,
				override_generic_sorter = true,
				override_file_sorter = true,
				case_mode = "smart_case",
			},
			live_grep_args = {},
			symbols = {},
		},
	})
	-- load extensions
	pcall(telescope.load_extension, "fzf")
	pcall(telescope.load_extension, "live_grep_args")
	pcall(telescope.load_extension, "symbols")

	set(0, "TelescopeNormal", { link = "NormalFloat" })
	set(0, "TelescopeBorder", { link = "FloatBorder" })
	set(0, "TelescopePromptNormal", { link = "NormalFloat" })
	set(0, "TelescopePromptBorder", { link = "FloatBorder" })
	set(0, "TelescopePromptTitle", { link = "Title" })
	set(0, "TelescopeResultsNormal", { link = "NormalFloat" })
	set(0, "TelescopeResultsBorder", { link = "FloatBorder" })
	set(0, "TelescopePreviewNormal", { link = "NormalFloat" })
	set(0, "TelescopePreviewBorder", { link = "FloatBorder" })

	-- Keymaps
	local map = vim.keymap.set
	local opts = { noremap = true, silent = true }

	map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", opts)
	map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", opts)
	map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", opts)
	map("n", "<leader>bb", "<cmd>Telescope buffers<cr>", opts)
	map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", opts)
	map("n", "<leader>fs", "<cmd>Telescope symbols<cr>", opts)

	-- alias Telescope for core commands
	local cmd = vim.api.nvim_create_user_command
	cmd("Find", function()
		require("telescope.builtin").find_files()
	end, {})
	cmd("Grep", function()
		require("telescope.builtin").live_grep()
	end, {})
end

function M.fterm()
	local fterm = require("FTerm")
	fterm.setup({
		border = "single",
		dimensions = { height = 0.8, width = 0.8 },
	})
	local cmd = vim.api.nvim_create_user_command
	pcall(cmd, "FTermToggle", function()
		fterm.toggle()
	end, { bang = true, desc = "Toggle floating terminal" })
end

function M.render_markdown()
	local ok, render_markdown = pcall(require, "render-markdown")
	if not ok then
		vim.notify("render-markdown.nvim not available", vim.log.levels.WARN)
		return
	end
	render_markdown.setup({
		file_types = { "markdown" },
		-- Plugin is lazy-loaded on markdown buffers; restarting ensures
		-- treesitter highlights are fully active after attach.
		restart_highlighter = true,
	})
end

-- Oil
function M.oil()
	local oil = require("oil")
	local function rebalance_windows()
		vim.schedule(function()
			vim.wo.winfixwidth = false
			pcall(vim.cmd.wincmd, "=")
		end)
	end
	local function current_buffer_dir()
		local path = vim.api.nvim_buf_get_name(0)
		if path == "" then
			return vim.fn.getcwd()
		end
		return vim.fn.fnamemodify(path, ":p:h")
	end

	oil.setup({
		default_file_explorer = true,
		skip_confirm_for_simple_edits = true,
		keymaps = {
			["<CR>"] = {
				callback = function()
					oil.select({}, function(err)
						if not err then
							rebalance_windows()
						end
					end)
				end,
				desc = "Open the entry under the cursor",
				mode = "n",
			},
		},
		view_options = {
			show_hidden = true,
			is_always_hidden = function(name, _)
				return name == ".git"
			end,
		},
		columns = { "icon" },
	})

	vim.keymap.set("n", "-", function()
		oil.open()
	end, {
		desc = "Open parent directory"
	})

	vim.keymap.set("n", "_", function()
		local dir = current_buffer_dir()
		vim.cmd("topleft vsplit")
		oil.open(dir)
		vim.wo.winfixwidth = true
		vim.cmd(("vertical resize %d"):format(math.max(20, math.floor(vim.o.columns * 0.25))))
		vim.cmd.wincmd("=")
	end, {
		desc = "Open parent directory in a left sidebar"
	})
end

-- Treesitter
function M.treesitter()
	local ok_ts, ts = pcall(require, "nvim-treesitter")
	if not ok_ts then
		vim.notify("nvim-treesitter not available", vim.log.levels.WARN)
		return
	end

	ts.setup({})

	local ensure = {
		"lua",
		"python",
		"json",
		"yaml",
		"markdown",
		"markdown_inline",
		"bash",
		"javascript",
		"typescript",
		"tsx",
		"rust",
	}

	local installed = {}
	for _, lang in ipairs(ts.get_installed() or {}) do
		installed[lang] = true
	end

	local missing = {}
	for _, lang in ipairs(ensure) do
		if not installed[lang] then
			missing[#missing + 1] = lang
		end
	end
	if #missing > 0 then
		pcall(ts.install, missing, { summary = true })
	end

	local augroup = vim.api.nvim_create_augroup("treesitter_start", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		callback = function(args)
			pcall(vim.treesitter.start, args.buf)
			vim.bo[args.buf].syntax = "off"
		end,
		desc = "Prefer treesitter highlighting for file buffers",
	})

	-- Map common markdown fence labels to installed parser languages.
	local ts_lang = vim.treesitter and vim.treesitter.language
	if ts_lang and ts_lang.register then
		ts_lang.register("javascript", "js")
		ts_lang.register("typescript", "ts")
		ts_lang.register("typescript", "tsx")
		ts_lang.register("python", "py")
		ts_lang.register("bash", "sh")
		ts_lang.register("bash", "zsh")
		ts_lang.register("yaml", "yml")
	end

	-- Prevent markdown raw-block capture from washing out injected language colors.
	set(0, "@markup.raw.block", { link = "Normal" })
	set(0, "@markup.raw.block.markdown", { link = "Normal" })
end

function M.orgmode_telescope()
	require('telescope').load_extension('orgmode')
	local ext = require('telescope').extensions.orgmode
	vim.keymap.set('n', '<leader>fh', ext.search_headings, { desc = 'Org headlines' })
	vim.keymap.set('n', '<leader>ft', ext.search_tags, { desc = 'Org tags' })
	vim.keymap.set('n', '<leader>rf', ext.refile_heading, { desc = 'Org refile' })
	vim.keymap.set('n', '<leader>li', ext.insert_link, { desc = 'Org insert link' })
end

-- LSP
function M.lsp()
	local servers = {
		"lua_ls",
		"pyright",
		"bashls",
		"jsonls",
		"ts_ls",
		"rust_analyzer",
	}
	local has_mason, mason = pcall(require, "mason")
	if has_mason then mason.setup() end

	local has_mlc, mlc = pcall(require, "mason-lspconfig")
	if has_mlc then
		mlc.setup({
			ensure_installed = servers,
			automatic_enable = true,
		})
	end

	local caps = vim.lsp.protocol.make_client_capabilities()
	local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
	if ok_cmp and cmp_nvim_lsp.default_capabilities then
		caps = cmp_nvim_lsp.default_capabilities(caps)
	end

	local toggle_virtual_lines

	local function set_lsp_keymaps(bufnr)
		local map = vim.keymap.set
		local o = { silent = true, noremap = true, buffer = bufnr }
		local function toggle_inlay_hints()
			if not vim.lsp.inlay_hint then
				return
			end

			local enabled = false
			local ok_enabled, current = pcall(vim.lsp.inlay_hint.is_enabled, { bufnr = bufnr })
			if ok_enabled then enabled = current end
			pcall(vim.lsp.inlay_hint.enable, not enabled, { bufnr = bufnr })
		end
		local function split_definition()
			vim.cmd("split")
			vim.lsp.buf.definition()
		end
		map("n", "gd", vim.lsp.buf.definition, o)
		map("n", "gK", split_definition, o)
		map("n", "gr", vim.lsp.buf.references, o)
		map("n", "K", vim.lsp.buf.hover, o)
		map("n", "<leader>rn", vim.lsp.buf.rename, o)
		map("n", "<leader>ca", vim.lsp.buf.code_action, o)
		map("n", "[d", vim.diagnostic.goto_prev, o)
		map("n", "]d", vim.diagnostic.goto_next, o)
		map("n", "gl", vim.diagnostic.open_float, o)
		map("n", "<leader>q", vim.diagnostic.setloclist, o)
		map("n", "<leader>F", format_current_buffer, o)
		map("n", "<leader>vv", toggle_virtual_lines, vim.tbl_extend("force", o, {
			desc = "Toggle diagnostic virtual lines",
		}))
		map("n", "<leader>vi", toggle_inlay_hints, vim.tbl_extend("force", o, {
			desc = "Toggle inlay hints",
		}))
		if vim.lsp.inlay_hint then pcall(vim.lsp.inlay_hint.enable, false, { bufnr = bufnr }) end
	end

	local lsp_keymap_group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true })
	vim.api.nvim_create_autocmd("LspAttach", {
		group = lsp_keymap_group,
		callback = function(args)
			set_lsp_keymaps(args.buf)
		end,
	})

	vim.lsp.config("*", {
		capabilities = caps,
		flags = {
			debounce_text_changes = 200,
		},
	})
	vim.lsp.config("lua_ls", {
		settings = {
			Lua = {
				diagnostics = { globals = { "vim" } },
				workspace = { checkThirdParty = false },
			},
		},
	})
	vim.lsp.config("pylsp", {
		settings = {
			pylsp = {
				plugins = {
					pycodestyle = {
						ignore = { "E501" },
					},
				},
			},
		},
	})
	vim.lsp.config("ts_ls", {
		settings = {
			typescript = {
				inlayHints = {
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayEnumMemberValueHints = true,
				},
			},
			javascript = {
				inlayHints = {
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayEnumMemberValueHints = true,
				},
			},
		},
	})
	vim.lsp.config("rust_analyzer", {
		settings = {
			["rust-analyzer"] = {
				cargo = {
					allFeatures = true,
				},
				checkOnSave = true,
				check = {
					command = "clippy",
				},
				inlayHints = {
					bindingModeHints = {
						enable = false,
					},
					closingBraceHints = {
						enable = false,
					},
					closureReturnTypeHints = {
						enable = "always",
					},
					discriminantHints = {
						enable = "fieldless",
					},
					expressionAdjustmentHints = {
						enable = "never",
					},
					lifetimeElisionHints = {
						enable = "skip_trivial",
						useParameterNames = true,
					},
					typeHints = {
						enable = true,
						hideClosureInitialization = false,
						hideNamedConstructor = false,
					},
				},
				procMacro = {
					enable = true,
				},
			},
		},
	})

	local function wrap_virtual_line_message(msg, width)
		if type(msg) ~= "string" or msg == "" then
			return {}
		end

		local max_width = math.max(20, width or 80)
		local out = {}
		for raw in msg:gmatch("[^\n]+") do
			local line = ""
			for word in raw:gmatch("%S+") do
				if line == "" then
					line = word
				elseif #line + 1 + #word <= max_width then
					line = line .. " " .. word
				else
					table.insert(out, line)
					line = word
				end
			end
			if line ~= "" then
				table.insert(out, line)
			end
		end
		return out
	end

	local function diag_virtual_hl(severity)
		if severity == vim.diagnostic.severity.ERROR then
			return "DiagnosticVirtualLinesError"
		elseif severity == vim.diagnostic.severity.WARN then
			return "DiagnosticVirtualLinesWarn"
		elseif severity == vim.diagnostic.severity.INFO then
			return "DiagnosticVirtualLinesInfo"
		end
		return "DiagnosticVirtualLinesHint"
	end

	local function diag_virtual_fill_hl(severity)
		if severity == vim.diagnostic.severity.ERROR then
			return "DiagnosticVirtualLinesFillError"
		elseif severity == vim.diagnostic.severity.WARN then
			return "DiagnosticVirtualLinesFillWarn"
		elseif severity == vim.diagnostic.severity.INFO then
			return "DiagnosticVirtualLinesFillInfo"
		end
		return "DiagnosticVirtualLinesFillHint"
	end

	local function format_virtual_message(diagnostic, opts, many_sources)
		local msg = (diagnostic.message or ""):gsub("%s+", " ")
		local source_mode = opts.source
		if diagnostic.source and (source_mode == "always" or (source_mode == "if_many" and many_sources)) then
			return string.format("%s: %s", diagnostic.source, msg)
		end
		return msg
	end

	local vline_ns = vim.api.nvim_create_namespace("olivetone_virtual_lines")
	vim.diagnostic.handlers.olivetone_virtual_lines = {
		show = function(_, bufnr, diagnostics, opts)
			vim.api.nvim_buf_clear_namespace(bufnr, vline_ns, 0, -1)
			if not diagnostics or vim.tbl_isempty(diagnostics) then
				return
			end

			local winid = vim.fn.bufwinid(bufnr)
			if winid == -1 then
				return
			end

			local win_width = vim.api.nvim_win_get_width(winid)
			local wininfo = vim.fn.getwininfo(winid)[1] or {}
			local textoff = tonumber(wininfo.textoff) or 0

			local by_source = {}
			for _, d in ipairs(diagnostics) do
				by_source[d.source or ""] = true
			end
			local many_sources = vim.tbl_count(by_source) > 1

			for _, diagnostic in ipairs(diagnostics) do
				local anchor_col = diagnostic.col or 0
				local usable = math.max(20, win_width - textoff - anchor_col - 14)
				local hl = diag_virtual_hl(diagnostic.severity)
				local fill_hl = diag_virtual_fill_hl(diagnostic.severity)
				local msg = format_virtual_message(diagnostic, opts, many_sources)
				local wrapped = wrap_virtual_line_message(msg, usable)
				local virt_lines = {}
				local trailing_pad = 18

				for i, line in ipairs(wrapped) do
					local prefix = (i == 1) and "└ " or "  "
					local left_fill = math.max(0, textoff + anchor_col)
					local content = prefix .. line
					local fill = math.max(0, usable - vim.fn.strdisplaywidth(content) + trailing_pad)
					table.insert(virt_lines, {
						{ string.rep("█", left_fill), fill_hl },
						{ content, hl },
						{ string.rep("█", fill), fill_hl },
					})
				end

				if #virt_lines > 0 then
					vim.api.nvim_buf_set_extmark(bufnr, vline_ns, diagnostic.lnum, 0, {
						virt_lines = virt_lines,
						virt_lines_above = false,
						virt_lines_leftcol = true,
					})
				end
			end
		end,
		hide = function(_, bufnr)
			vim.api.nvim_buf_clear_namespace(bufnr, vline_ns, 0, -1)
		end,
	}

	local olivetone_virtual_lines_opts = {
		source = "if_many",
		severity = { min = vim.diagnostic.severity.WARN },
	}
	local olivetone_virtual_lines_enabled = false

	local function refresh_visible_diagnostics()
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(bufnr) then
				vim.diagnostic.hide(nil, bufnr)
				vim.diagnostic.show(nil, bufnr)
			end
		end
	end

	toggle_virtual_lines = function()
		olivetone_virtual_lines_enabled = not olivetone_virtual_lines_enabled
		vim.diagnostic.config({
			olivetone_virtual_lines = olivetone_virtual_lines_enabled and olivetone_virtual_lines_opts or false,
		})
		refresh_visible_diagnostics()
	end

	vim.lsp.enable(servers)
	vim.diagnostic.config({
		virtual_text = false,
		virtual_lines = false,
		olivetone_virtual_lines = olivetone_virtual_lines_enabled and olivetone_virtual_lines_opts or false,
		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = "E",
				[vim.diagnostic.severity.WARN] = "W",
				[vim.diagnostic.severity.INFO] = "I",
				[vim.diagnostic.severity.HINT] = "H",
			},
		},
		underline = true,
		update_in_insert = false,
		severity_sort = true,
		float = { border = "rounded", source = "always", focusable = false },
	})
end

function M.org_extensions()
	require('orgmode').setup({
		org_agenda_files = { '~/org/*.org' },
		org_default_notes_file = '~/org/inbox.org',
		ui = { input = { use_vim_ui = true, }, },
		org_todo_keywords = { 'TODO(t)', 'NEXT(n)', 'WAITING(w)', '|', 'DONE(d)' },
		org_log_done = 'time',

		org_agenda_custom_commands = {
			u = {
				description = 'Unfinished tasks',
				types = { {
					type = 'tags_todo',
					match = '',
					org_agenda_overriding_header = 'Unfinished tasks',
				} },
			},
			d = {
				description = 'Completed tasks',
				types = { {
					type = 'tags',
					match = 'TODO="DONE"',
					org_agenda_overriding_header = 'Completed tasks',
				} },
			},
			T = {
				description = 'Today: agenda + unfinished',
				types = { {
					type = 'agenda',
					org_agenda_span = 'day',
					org_agenda_overriding_header = 'Today',
				}, {
					type = 'tags_todo',
					match = '',
					org_agenda_overriding_header = 'Unfinished tasks',
				} },
			},
		},
	})
	require('org_extensions/org_daily').setup({
		daily_file = '~/org/daily.org',
	})
end

return M
