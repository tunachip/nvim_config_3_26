local M = {}

local function list_snippet_files(snippets_dir)
	local files = vim.fn.globpath(snippets_dir, "*.py", false, true)
	table.sort(files)
	return files
end

local function basename(path)
	return vim.fn.fnamemodify(path, ":t")
end

local function run_selected_snippet(file_path)
	local arg = vim.fn.input("snippet arg (optional): ")
	local cmd = { "python", file_path }

	if arg ~= nil and arg ~= "" then
		table.insert(cmd, arg)
	end

	local output = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify(
			"Snippet failed: " .. basename(file_path) .. " (exit " ..
			vim.v.shell_error .. ")",
			vim.log.levels.ERROR
		)
		return
	end

	if #output == 0 then
		vim.notify("Snippet produced no output", vim.log.levels.WARN)
		return
	end

	vim.api.nvim_put(output, "l", true, true)
end

function M.select_and_run()
	local snippets_dir = vim.fn.getcwd() .. "/snippets"
	local files = list_snippet_files(snippets_dir)

	if #files == 0 then
		vim.notify("No Python snippets found in ./snippets",
			vim.log.levels.WARN)
		return
	end

	local options = {}
	local option_to_file = {}

	for _, file_path in ipairs(files) do
		local name = basename(file_path)
		table.insert(options, name)
		option_to_file[name] = file_path
	end

	vim.ui.select(options, { prompt = "Select snippet" },
		function(choice)
			if not choice then
				return
			end
			run_selected_snippet(option_to_file[choice])
		end)
end

function M.setup()
	vim.keymap.set("n", "<leader>gs", M.select_and_run, {
		desc =
		"Select snippet from ./snippets"
	})
end

return M
