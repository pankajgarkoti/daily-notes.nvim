-- Simple Daily Notes Plugin for Neovim
local M = {}

---@class DailyNoteConfig
---@field base_dir string The root directory for notes. The feature is only active here.
---@field journal_path string The sub-directory within base_dir for journal entries.
---@field file_format string The format for the note's filename, using os.date patterns.
---@field dir_format string The format for the directory structure, using os.date patterns.
---@field template_path string | nil Optional path to a template file for new notes if yesterday's doesn't exist.

---@type DailyNoteConfig
local default_config = {
	base_dir = vim.fn.expand("~/Desktop/notes"),
	journal_path = "Journal",
	file_format = "%Y-%m-%d.md",
	dir_format = "%Y/%m",
	template_path = nil,
}

M.config = vim.deepcopy(default_config)

--- Setup function to configure the daily note system
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", default_config, opts)

	-- Expand paths
	M.config.base_dir = vim.fn.expand(M.config.base_dir)
	if M.config.template_path then
		M.config.template_path = vim.fn.expand(M.config.template_path)
	end

	-- Validate configuration
	if not M.config.base_dir or M.config.base_dir == "" then
		vim.notify("daily_note: base_dir cannot be empty", vim.log.levels.ERROR)
		return false
	end

	if not M.config.journal_path or M.config.journal_path == "" then
		vim.notify("daily_note: journal_path cannot be empty", vim.log.levels.ERROR)
		return false
	end

	-- Check if template exists if specified
	if M.config.template_path and vim.fn.filereadable(M.config.template_path) == 0 then
		vim.notify("daily_note: Template file not found: " .. M.config.template_path, vim.log.levels.WARN)
	end

	-- Create user commands
	vim.api.nvim_create_user_command('DailyNote', M.open_daily_note, { desc = 'Open today\'s daily note' })
	vim.api.nvim_create_user_command('DailyNotePrev', function() M.open_adjacent_note(-1) end,
		{ desc = 'Open previous daily note' })
	vim.api.nvim_create_user_command('DailyNoteNext', function() M.open_adjacent_note(1) end,
		{ desc = 'Open next daily note' })
	vim.api.nvim_create_user_command('DailyNoteTomorrow', M.create_tomorrow_note, { desc = 'Create tomorrow\'s note' })
	vim.api.nvim_create_user_command('DailyNoteConfig', M.configure_interactive,
		{ desc = 'Configure daily notes interactively' })

	return true
end

function M.get_config()
	return vim.deepcopy(M.config)
end

function M.set_config(key, value)
	if M.config[key] == nil then
		vim.notify("daily_note: Unknown config key: " .. key, vim.log.levels.ERROR)
		return false
	end

	M.config[key] = value

	if key == "base_dir" or key == "template_path" then
		if value then
			M.config[key] = vim.fn.expand(value)
		end
	end

	vim.notify("daily_note: Updated " .. key, vim.log.levels.INFO)
	return true
end

function M.configure_interactive()
	local function get_input(prompt, default)
		local input = vim.fn.input(prompt .. " [" .. (default or "none") .. "]: ")
		if input == "" then
			return default
		end
		return input
	end

	local function get_confirm(prompt)
		local response = vim.fn.input(prompt .. " (y/n): ")
		return response:lower() == "y" or response:lower() == "yes"
	end

	print("=== Daily Note Configuration ===")

	local new_config = {}
	new_config.base_dir = get_input("Notes base directory", M.config.base_dir)
	new_config.journal_path = get_input("Journal subdirectory", M.config.journal_path)
	new_config.file_format = get_input("File format (date pattern)", M.config.file_format)
	new_config.dir_format = get_input("Directory format (date pattern)", M.config.dir_format)

	if get_confirm("Use a template file?") then
		new_config.template_path = get_input("Template file path", M.config.template_path)
	else
		new_config.template_path = nil
	end

	if M.setup(new_config) then
		print("\nConfiguration updated successfully!")
		print("Base directory: " .. M.config.base_dir)
		print("Journal path: " .. M.config.journal_path)
		print("Template: " .. (M.config.template_path or "none"))
	end
end

local function get_date_from_path(path)
	local filename = vim.fn.fnamemodify(path, ":t")
	local year, month, day = filename:match("^(%d%d%d%d)-(%d%d)-(%d%d)%.md$")
	if not (year and month and day) then
		return nil
	end
	return { year = tonumber(year), month = tonumber(month), day = tonumber(day) }
end

function M.open_daily_note()
	local cwd = vim.fn.getcwd()
	if not (cwd == M.config.base_dir or cwd:find(M.config.base_dir .. "/", 1, true) == 1) then
		vim.notify("Not in notes directory: " .. M.config.base_dir, vim.log.levels.WARN)
		return
	end

	local today = os.date("*t")
	local today_dir_path = M.config.base_dir ..
			"/" .. M.config.journal_path .. "/" .. os.date(M.config.dir_format, os.time(today))
	local today_filename = os.date(M.config.file_format, os.time(today))
	local today_path = today_dir_path .. "/" .. today_filename

	if vim.fn.filereadable(today_path) == 1 then
		vim.cmd("e " .. today_path)
		vim.notify("Opened today's note.", vim.log.levels.INFO)
		return
	end

	vim.fn.mkdir(today_dir_path, "p")

	local yesterday_t = os.time(today) - (24 * 60 * 60)
	local yesterday = os.date("*t", yesterday_t)
	local yesterday_dir_path = M.config.base_dir ..
			"/" .. M.config.journal_path .. "/" .. os.date(M.config.dir_format, os.time(yesterday))
	local yesterday_filename = os.date(M.config.file_format, os.time(yesterday))
	local yesterday_path = yesterday_dir_path .. "/" .. yesterday_filename

	local content = ""
	if vim.fn.filereadable(yesterday_path) == 1 then
		local lines = vim.fn.readfile(yesterday_path)
		content = table.concat(lines, "\n")
		vim.notify("Created today's note from yesterday's.", vim.log.levels.INFO)
	elseif M.config.template_path and vim.fn.filereadable(M.config.template_path) == 1 then
		local lines = vim.fn.readfile(M.config.template_path)
		content = table.concat(lines, "\n")
		vim.notify("Created today's note from template.", vim.log.levels.INFO)
	else
		vim.notify("Yesterday's note not found. Creating an empty daily note.", vim.log.levels.INFO)
	end

	vim.fn.writefile(vim.split(content, "\n"), today_path)
	vim.cmd("e " .. today_path)
end

function M.open_adjacent_note(offset)
	local current_path = vim.fn.expand("%:p")
	local journal_dir = M.config.base_dir .. "/" .. M.config.journal_path

	if not current_path:find(journal_dir, 1, true) then
		vim.notify("Not in a daily note.", vim.log.levels.WARN)
		return
	end

	local current_date_parts = get_date_from_path(current_path)
	if not current_date_parts then
		vim.notify("Could not determine date from current file name.", vim.log.levels.WARN)
		return
	end

	local current_timestamp = os.time(current_date_parts)
	local adjacent_timestamp = current_timestamp + (offset * 24 * 60 * 60)
	local adjacent_date = os.date("*t", adjacent_timestamp)

	local adjacent_dir_path = M.config.base_dir ..
			"/" .. M.config.journal_path .. "/" .. os.date(M.config.dir_format, os.time(adjacent_date))
	local adjacent_filename = os.date(M.config.file_format, os.time(adjacent_date))
	local adjacent_path = adjacent_dir_path .. "/" .. adjacent_filename

	if vim.fn.filereadable(adjacent_path) == 1 then
		vim.cmd("e " .. adjacent_path)
		local direction = offset > 0 and "next" or "previous"
		vim.notify("Opened " .. direction .. " day's note.", vim.log.levels.INFO)
	else
		local date_str = os.date("%Y-%m-%d", adjacent_timestamp)
		vim.notify("Note for " .. date_str .. " does not exist.", vim.log.levels.WARN)
	end
end

function M.create_tomorrow_note()
	local cwd = vim.fn.getcwd()
	if not (cwd == M.config.base_dir or cwd:find(M.config.base_dir .. "/", 1, true) == 1) then
		vim.notify("Not in notes directory: " .. M.config.base_dir, vim.log.levels.WARN)
		return
	end

	local tomorrow_t = os.time() + (24 * 60 * 60)
	local tomorrow = os.date("*t", tomorrow_t)
	local tomorrow_dir_path = M.config.base_dir ..
			"/" .. M.config.journal_path .. "/" .. os.date(M.config.dir_format, os.time(tomorrow))
	local tomorrow_filename = os.date(M.config.file_format, os.time(tomorrow))
	local tomorrow_path = tomorrow_dir_path .. "/" .. tomorrow_filename

	if vim.fn.filereadable(tomorrow_path) == 1 then
		vim.cmd("e " .. tomorrow_path)
		vim.notify("Opened existing tomorrow's note.", vim.log.levels.INFO)
		return
	end

	vim.fn.mkdir(tomorrow_dir_path, "p")

	local today = os.date("*t")
	local today_dir_path = M.config.base_dir ..
			"/" .. M.config.journal_path .. "/" .. os.date(M.config.dir_format, os.time(today))
	local today_filename = os.date(M.config.file_format, os.time(today))
	local today_path = today_dir_path .. "/" .. today_filename

	local content = ""
	if vim.fn.filereadable(today_path) == 1 then
		local lines = vim.fn.readfile(today_path)
		content = table.concat(lines, "\n")
		vim.notify("Created tomorrow's note from today's.", vim.log.levels.INFO)
	elseif M.config.template_path and vim.fn.filereadable(M.config.template_path) == 1 then
		local lines = vim.fn.readfile(M.config.template_path)
		content = table.concat(lines, "\n")
		vim.notify("Created tomorrow's note from template.", vim.log.levels.INFO)
	else
		vim.notify("Today's note not found. Creating an empty note for tomorrow.", vim.log.levels.INFO)
	end

	vim.fn.writefile(vim.split(content, "\n"), tomorrow_path)
	vim.cmd("e " .. tomorrow_path)
end

return M

