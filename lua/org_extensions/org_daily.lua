-- /root/.dotfiles/.config/nvim/lua/org_extensions/org_daily.lua

local M = {}

M.config = {
	daily_file = vim.fn.expand('~/org/daily.org'),
	day_heading_format = '* %Y-%m-%d %A',
}

local function expand_path(path)
	if not path or path == '' then
		return path
	end
	return vim.fn.expand(path)
end

local function today_heading()
	return os.date(M.config.day_heading_format)
end

local function split_semicolons(s)
	local out = {}
	if not s or s == '' then
		return out
	end
	for part in string.gmatch(s, '([^;]+)') do
		local trimmed = vim.trim(part)
		if trimmed ~= '' then
			table.insert(out, trimmed)
		end
	end
	return out
end

local function yn(prompt)
	local choice = vim.fn.confirm(prompt, '&Yes\n&No', 2)
	if choice == 0 then
		return nil -- Esc / cancel
	end
	return choice == 1
end

local function input_or_cancel(prompt, default)
	local ok, value = pcall(vim.fn.input, { prompt = prompt, default = default or '' })
	if not ok then
		return nil
	end
	if value == nil then
		return nil
	end
	return vim.trim(value)
end

local function trim_trailing_blank_index(lines, idx)
	while idx > 0 and lines[idx] == '' do
		idx = idx - 1
	end
	return idx
end

local function with_single_trailing_blank(lines)
	local out = vim.deepcopy(lines)
	if out[#out] ~= '' then
		table.insert(out, '')
	end
	return out
end

local function append_lines_under_today(file, lines)
	file = expand_path(file)
	local parent = vim.fn.fnamemodify(file, ':h')
	if parent and parent ~= '' then
		vim.fn.mkdir(parent, 'p')
	end
	local buf = vim.fn.bufadd(file)
	vim.fn.bufload(buf)

	local existing = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local heading = today_heading()

	local start_idx = nil
	local insert_idx = nil
	local section_end_idx = #existing

	for i, line in ipairs(existing) do
		if line == heading then
			start_idx = i
			insert_idx = trim_trailing_blank_index(existing, #existing)
			for j = i + 1, #existing do
				if existing[j]:match('^%* ') then
					section_end_idx = j - 1
					insert_idx = trim_trailing_blank_index(existing, section_end_idx)
					break
				end
			end
			break
		end
	end

	if not start_idx then
		if #existing > 0 and existing[#existing] ~= '' then
			table.insert(existing, '')
		end
		table.insert(existing, heading)
		table.insert(existing, '')
		start_idx = #existing - 1
		insert_idx = #existing
		section_end_idx = #existing
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, existing)
	end

	local payload = with_single_trailing_blank(lines)
	if insert_idx > start_idx then
		table.insert(payload, 1, '')
	end

	vim.api.nvim_buf_set_lines(buf, insert_idx, section_end_idx, false, payload)
	vim.api.nvim_buf_call(buf, function()
		vim.cmd('silent write')
	end)
end

local function build_email_sections(base_level)
	local lines = {}
	local count = 0
	while true do
		local add = yn('Add an email entry?')
		if add == nil then
			return nil
		end
		if not add then
			break
		end

		count = count + 1
		local title = count == 1 and 'Email' or ('Email ' .. count)
		local body = input_or_cancel('Email contents: ')
		if body == nil then
			return nil
		end

		table.insert(lines, string.rep('*', base_level) .. ' ' .. title)
		table.insert(lines, '#+begin_quote')
		for _, line in ipairs(vim.split(body, '\n', { plain = true })) do
			table.insert(lines, line)
		end
		table.insert(lines, '#+end_quote')
		table.insert(lines, '')
	end
	return lines
end

local function build_subtask_sections(base_level)
	local lines = {}
	local n = 0
	while true do
		local add = yn('Add a subtask?')
		if add == nil then
			return nil
		end
		if not add then
			break
		end

		n = n + 1
		local title = input_or_cancel('Subtask title: ', 'Subtask ' .. n)
		if title == nil or title == '' then
			return nil
		end

		local steps_raw = input_or_cancel('Steps (; delimited): ')
		if steps_raw == nil then
			return nil
		end

		table.insert(lines, string.rep('*', base_level) .. ' ' .. title)
		local steps = split_semicolons(steps_raw)
		for _, step in ipairs(steps) do
			table.insert(lines, '- [ ] ' .. step)
		end
		table.insert(lines, '')
	end
	return lines
end

function M.collect_task_template()
	local title = input_or_cancel('Task title: ')
	if not title or title == '' then
		return nil
	end

	local desc = input_or_cancel('Description: ') or ''

	local lines = {
		'** TODO ' .. title,
	}

	if desc ~= '' then
		table.insert(lines, desc)
		table.insert(lines, '')
	end

	table.insert(lines, '*** Notes')
	table.insert(lines, '')
	table.insert(lines, '*** Outcome')
	table.insert(lines, '')

	local emails = build_email_sections(3)
	if emails == nil then
		return nil
	end

	local subtasks = build_subtask_sections(3)
	if subtasks == nil then
		return nil
	end

	local final = {
		'** TODO ' .. title,
	}

	if desc ~= '' then
		table.insert(final, desc)
		table.insert(final, '')
	end

	for _, line in ipairs(emails) do
		table.insert(final, line)
	end
	for _, line in ipairs(subtasks) do
		table.insert(final, line)
	end

	table.insert(final, '*** Notes')
	table.insert(final, '')
	table.insert(final, '*** Outcome')
	table.insert(final, '')

	return final
end

function M.new_daily_task()
	local lines = M.collect_task_template()
	if not lines then
		return
	end
	append_lines_under_today(M.config.daily_file, lines)
	vim.notify('Added task to ' .. M.config.daily_file)
end

local function current_headline()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for i = row, 1, -1 do
		local stars, title = lines[i]:match('^(%*+)%s+(.*)$')
		if stars then
			return {
				row = i,
				level = #stars,
				title = title,
			}
		end
	end
	return nil
end

local function subtree_end(start_row, level)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	for i = start_row + 1, #lines do
		local stars = lines[i]:match('^(%*+) ')
		if stars and #stars <= level then
			return trim_trailing_blank_index(lines, i - 1)
		end
	end
	return trim_trailing_blank_index(lines, #lines)
end

local function insert_after_subtree(start_row, level, new_lines)
	local end_row = subtree_end(start_row, level)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local section_end = end_row
	while section_end < #lines and lines[section_end + 1] == '' do
		section_end = section_end + 1
	end
	vim.api.nvim_buf_set_lines(0, end_row, section_end, false, vim.list_extend({ '' }, with_single_trailing_blank(new_lines)))
end

function M.insert_task_here()
	local heading = current_headline()
	if not heading then
		vim.notify('No Org heading found above cursor', vim.log.levels.WARN)
		return
	end

	local title = input_or_cancel('Task title: ')
	if not title or title == '' then
		return
	end
	local desc = input_or_cancel('Description: ') or ''

	local lines = {
		string.rep('*', math.max(heading.level + 1, 2)) .. ' TODO ' .. title,
	}
	if desc ~= '' then
		table.insert(lines, desc)
		table.insert(lines, '')
	end
	table.insert(lines, string.rep('*', math.max(heading.level + 2, 3)) .. ' Notes')
	table.insert(lines, '')
	table.insert(lines, string.rep('*', math.max(heading.level + 2, 3)) .. ' Outcome')
	table.insert(lines, '')

	insert_after_subtree(heading.row, heading.level, lines)
end

function M.insert_subtask_here()
	local heading = current_headline()
	if not heading then
		vim.notify('No Org heading found above cursor', vim.log.levels.WARN)
		return
	end

	local title = input_or_cancel('Subtask title: ')
	if not title or title == '' then
		return
	end

	local steps_raw = input_or_cancel('Steps (; delimited): ') or ''
	local level = heading.level + 1
	local lines = { string.rep('*', level) .. ' ' .. title }
	for _, step in ipairs(split_semicolons(steps_raw)) do
		table.insert(lines, '- [ ] ' .. step)
	end
	table.insert(lines, '')

	insert_after_subtree(heading.row, heading.level, lines)
end

function M.insert_email_here()
	local heading = current_headline()
	if not heading then
		vim.notify('No Org heading found above cursor', vim.log.levels.WARN)
		return
	end

	local body = input_or_cancel('Email contents: ')
	if body == nil or body == '' then
		return
	end

	local level = heading.level + 1
	local lines = {
		string.rep('*', level) .. ' Email',
		'#+begin_quote',
	}
	for _, line in ipairs(vim.split(body, '\n', { plain = true })) do
		table.insert(lines, line)
	end
	table.insert(lines, '#+end_quote')
	table.insert(lines, '')

	insert_after_subtree(heading.row, heading.level, lines)
end

function M.setup(opts)
	opts = opts or {}
	if opts.daily_file then
		opts.daily_file = expand_path(opts.daily_file)
	end
	M.config = vim.tbl_extend('force', M.config, opts)

	vim.api.nvim_create_user_command('OrgDailyTask', function()
		M.new_daily_task()
	end, {})

	vim.api.nvim_create_autocmd('FileType', {
		pattern = 'org',
		callback = function(ev)
			local map = function(lhs, rhs, desc)
				vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc })
			end
			map('<leader>nt', M.insert_task_here, 'Org: new task')
			map('<leader>ns', M.insert_subtask_here, 'Org: new subtask')
			map('<leader>ne', M.insert_email_here, 'Org: new email')
		end,
	})
end

return M
