local M = {}

local defaults = {
	page_markers = true,
	header = true,
	filetype = "markdown",
	pdftotext_cmd = "pdftotext",
	pdftotext_args = { "-layout", "-nopgbrk" },
}

local state = {
	config = nil,
}

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "pdf-reader.nvim" })
end

local function normalize_path(path)
	if not path or path == "" then
		return nil
	end
	return vim.fn.fnamemodify(vim.fn.expand(path), ":p")
end

local function ensure_config()
	if state.config == nil then
		state.config = vim.tbl_deep_extend("force", {}, defaults)
	end
	return state.config
end

local function split_pages(text)
	local pages = {}
	local page_start = 1

	while true do
		local break_start, break_end = text:find("\f", page_start, true)
		if break_start == nil then
			table.insert(pages, text:sub(page_start))
			break
		end
		table.insert(pages, text:sub(page_start, break_start - 1))
		page_start = break_end + 1
	end

	return pages
end

local function trim_blank_edges(lines)
	local first = 1
	local last = #lines

	while first <= last and lines[first] == "" do
		first = first + 1
	end
	while last >= first and lines[last] == "" do
		last = last - 1
	end

	if first > last then
		return {}
	end

	return vim.list_slice(lines, first, last)
end

local function render_text(pdf_path, text, config)
	local lines = {}

	if config.header then
		lines[#lines + 1] = "# " .. vim.fn.fnamemodify(pdf_path, ":t")
		lines[#lines + 1] = ""
		lines[#lines + 1] = pdf_path
		lines[#lines + 1] = ""
	end

	local pages = split_pages(text)
	for index, page in ipairs(pages) do
		local page_lines = trim_blank_edges(vim.split(page, "\n", { plain = true }))
		if config.page_markers then
			lines[#lines + 1] = ("## Page %d"):format(index)
			lines[#lines + 1] = ""
		end
		if #page_lines == 0 then
			lines[#lines + 1] = "[No extractable text on this page]"
		else
			vim.list_extend(lines, page_lines)
		end
		if index < #pages then
			lines[#lines + 1] = ""
			lines[#lines + 1] = ""
		end
	end

	if #lines == 0 then
		return { "[No extractable text found]" }
	end

	return lines
end

local function read_pdf_text(pdf_path, config)
	local command = vim.list_extend({ config.pdftotext_cmd }, vim.deepcopy(config.pdftotext_args))
	command[#command + 1] = pdf_path
	command[#command + 1] = "-"

	local result = vim.system(command, { text = true }):wait()
	if result.code ~= 0 then
		local stderr = vim.trim(result.stderr or "")
		if stderr == "" then
			stderr = "pdftotext failed"
		end
		return nil, stderr
	end

	return result.stdout or ""
end

local function set_buffer_content(bufnr, lines)
	vim.bo[bufnr].modifiable = true
	vim.bo[bufnr].readonly = false
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].modifiable = false
	vim.bo[bufnr].readonly = true
	vim.bo[bufnr].modified = false
end

local function configure_buffer(bufnr, pdf_path, config)
	vim.bo[bufnr].buftype = "nofile"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].readonly = false
	vim.bo[bufnr].modifiable = false
	vim.api.nvim_buf_set_name(bufnr, "pdf://" .. pdf_path)
	vim.bo[bufnr].filetype = config.filetype
	vim.bo[bufnr].modified = false
	vim.b[bufnr].pdf_reader_source = pdf_path
end

function M.open(pdf_path, opts)
	local config = vim.tbl_deep_extend("force", {}, ensure_config(), opts or {})
	local normalized_path = normalize_path(pdf_path)
	if normalized_path == nil then
		notify("No PDF path provided", vim.log.levels.ERROR)
		return
	end
	if vim.fn.filereadable(normalized_path) ~= 1 then
		notify("PDF not found: " .. normalized_path, vim.log.levels.ERROR)
		return
	end

	local text, err = read_pdf_text(normalized_path, config)
	if text == nil then
		notify(err, vim.log.levels.ERROR)
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	configure_buffer(bufnr, normalized_path, config)
	set_buffer_content(bufnr, render_text(normalized_path, text, config))
end

function M.open_current_pdf()
	M.open(vim.api.nvim_buf_get_name(0))
end

function M.setup(opts)
	state.config = vim.tbl_deep_extend("force", {}, defaults, opts or {})

	vim.api.nvim_create_user_command("OpenPdf", function(command_opts)
		local path = command_opts.args
		if path == "" then
			path = vim.api.nvim_buf_get_name(0)
		end
		M.open(path)
	end, {
		nargs = "?",
		complete = "file",
		desc = "Open a PDF as extracted text",
	})

	local group = vim.api.nvim_create_augroup("PdfReaderNvim", { clear = true })
	vim.api.nvim_create_autocmd("BufReadCmd", {
		group = group,
		pattern = "*.pdf",
		callback = function()
			M.open_current_pdf()
		end,
		desc = "Open PDFs with pdftotext",
	})
end

return M
