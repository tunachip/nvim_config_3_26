local M = {}

local TARGETS = {
	"camelCase",
	"snake_case",
	"PascalCase",
	"kebab-case",
	"CONSTANT_CASE",
	"__dunder_case__",
	"_private_case",
}

local TARGET_SET = {}

for _, target in ipairs(TARGETS) do
	TARGET_SET[target] = true
end

local function get_identifier_details()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
	local index = col + 1

	local function is_identifier_char(char)
		return char ~= "" and char:match("[%w_-]") ~= nil
	end

	if not is_identifier_char(line:sub(index, index)) then
		return nil
	end

	local start_col = index
	while start_col > 1 and is_identifier_char(line:sub(start_col - 1, start_col - 1)) do
		start_col = start_col - 1
	end

	local end_col = index
	while end_col < #line and is_identifier_char(line:sub(end_col + 1, end_col + 1)) do
		end_col = end_col + 1
	end

	return {
		row = row,
		line = line,
		start_col = start_col,
		end_col = end_col,
		identifier = line:sub(start_col, end_col),
	}
end

local function split_words(identifier)
	local core = identifier

	if core:match("^__.+__$") then
		core = core:sub(3, -3)
	elseif core:match("^_[^_].*$") then
		core = core:sub(2)
	end

	core = core:gsub("([A-Z]+)([A-Z][a-z])", "%1 %2")
	core = core:gsub("([a-z0-9])([A-Z])", "%1 %2")
	core = core:gsub("[_-]+", " ")

	local words = {}
	for word in core:gmatch("%S+") do
		words[#words + 1] = word:lower()
	end
	return words
end

local function capitalize(word)
	return word:sub(1, 1):upper() .. word:sub(2)
end

local function build_case(words, target)
	if #words == 0 then
		return nil
	end

	if target == "camelCase" then
		local parts = { words[1] }
		for index = 2, #words do
			parts[#parts + 1] = capitalize(words[index])
		end
		return table.concat(parts)
	end

	if target == "snake_case" then
		return table.concat(words, "_")
	end

	if target == "PascalCase" then
		local parts = {}
		for _, word in ipairs(words) do
			parts[#parts + 1] = capitalize(word)
		end
		return table.concat(parts)
	end

	if target == "kebab-case" then
		return table.concat(words, "-")
	end

	if target == "CONSTANT_CASE" then
		return table.concat(words, "_"):upper()
	end

	if target == "__dunder_case__" then
		return "__" .. table.concat(words, "_") .. "__"
	end

	if target == "_private_case" then
		return "_" .. table.concat(words, "_")
	end

	return nil
end

function M.convert_identifier(identifier, target)
	if not TARGET_SET[target] then
		error("Unsupported target case: " .. tostring(target))
	end

	return build_case(split_words(identifier), target)
end

local function apply_identifier_change(details, replacement)
	local new_line = details.line:sub(1, details.start_col - 1) .. replacement .. details.line:sub(details.end_col + 1)
	vim.api.nvim_buf_set_lines(0, details.row - 1, details.row, false, { new_line })
	vim.api.nvim_win_set_cursor(0, { details.row, details.start_col - 1 })
end

function M.shift_at_cursor(target)
	if not TARGET_SET[target] then
		vim.notify("Unsupported target case: " .. tostring(target), vim.log.levels.ERROR)
		return
	end

	local details = get_identifier_details()
	if not details then
		vim.notify("No identifier found under cursor", vim.log.levels.WARN)
		return
	end

	local replacement = M.convert_identifier(details.identifier, target)
	if not replacement then
		vim.notify("Could not convert identifier: " .. details.identifier, vim.log.levels.WARN)
		return
	end

	apply_identifier_change(details, replacement)
end

function M.pick_case_at_cursor()
	local details = get_identifier_details()
	if not details then
		vim.notify("No identifier found under cursor", vim.log.levels.WARN)
		return
	end

	local ok_pickers, pickers = pcall(require, "telescope.pickers")
	local ok_finders, finders = pcall(require, "telescope.finders")
	local ok_config, config_values = pcall(require, "telescope.config")
	local ok_actions, actions = pcall(require, "telescope.actions")
	local ok_state, action_state = pcall(require, "telescope.actions.state")
	local ok_entry_display, entry_display = pcall(require, "telescope.pickers.entry_display")

	if not (ok_pickers and ok_finders and ok_config and ok_actions and ok_state and ok_entry_display) then
		vim.notify("Telescope is required for CaseShiftPicker", vim.log.levels.ERROR)
		return
	end

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 18 },
			{ remaining = true },
		},
	})

	local entries = {}
	for _, target in ipairs(TARGETS) do
		entries[#entries + 1] = {
			target = target,
			preview = M.convert_identifier(details.identifier, target),
		}
	end

	pickers.new({}, {
		prompt_title = "Case Shift: " .. details.identifier,
		finder = finders.new_table({
			results = entries,
			entry_maker = function(entry)
				return {
					value = entry,
					display = function(item)
						return displayer({
							{ item.value.target, "TelescopeResultsIdentifier" },
							item.value.preview,
						})
					end,
					ordinal = entry.target .. " " .. entry.preview,
				}
			end,
		}),
		sorter = config_values.values.generic_sorter({}),
		attach_mappings = function(prompt_bufnr)
			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if selection and selection.value and selection.value.preview then
					apply_identifier_change(details, selection.value.preview)
				end
			end)
			return true
		end,
	}):find()
end

function M.setup()
	pcall(vim.api.nvim_del_user_command, "CaseShift")
	pcall(vim.api.nvim_del_user_command, "CaseShiftPicker")
	pcall(vim.api.nvim_del_user_command, "ToCamelCase")
	pcall(vim.api.nvim_del_user_command, "ToSnakeCase")
	pcall(vim.api.nvim_del_user_command, "ToPascalCase")
	pcall(vim.api.nvim_del_user_command, "ToKebabCase")
	pcall(vim.api.nvim_del_user_command, "ToConstantCase")
	pcall(vim.api.nvim_del_user_command, "ToDunderCase")
	pcall(vim.api.nvim_del_user_command, "ToPrivateCase")

	vim.api.nvim_create_user_command("CaseShift", function(opts)
		if opts.args == "" then
			M.pick_case_at_cursor()
			return
		end
		M.shift_at_cursor(opts.args)
	end, {
		nargs = "?",
		desc = "Convert the identifier under the cursor or open a Telescope case picker",
		complete = function(arg_lead)
			return vim.tbl_filter(function(item)
				return item:find("^" .. vim.pesc(arg_lead)) ~= nil
			end, TARGETS)
		end,
	})

	vim.api.nvim_create_user_command("CaseShiftPicker", function()
		M.pick_case_at_cursor()
	end, {
		desc = "Open a Telescope picker for the identifier under the cursor",
	})

	vim.api.nvim_create_user_command("ToCamelCase", function()
		M.shift_at_cursor("camelCase")
	end, { desc = "Convert the identifier under the cursor to camelCase" })

	vim.api.nvim_create_user_command("ToSnakeCase", function()
		M.shift_at_cursor("snake_case")
	end, { desc = "Convert the identifier under the cursor to snake_case" })

	vim.api.nvim_create_user_command("ToPascalCase", function()
		M.shift_at_cursor("PascalCase")
	end, { desc = "Convert the identifier under the cursor to PascalCase" })

	vim.api.nvim_create_user_command("ToKebabCase", function()
		M.shift_at_cursor("kebab-case")
	end, { desc = "Convert the identifier under the cursor to kebab-case" })

	vim.api.nvim_create_user_command("ToConstantCase", function()
		M.shift_at_cursor("CONSTANT_CASE")
	end, { desc = "Convert the identifier under the cursor to CONSTANT_CASE" })

	vim.api.nvim_create_user_command("ToDunderCase", function()
		M.shift_at_cursor("__dunder_case__")
	end, { desc = "Convert the identifier under the cursor to __dunder_case__" })

	vim.api.nvim_create_user_command("ToPrivateCase", function()
		M.shift_at_cursor("_private_case")
	end, { desc = "Convert the identifier under the cursor to _private_case" })
end

return M
