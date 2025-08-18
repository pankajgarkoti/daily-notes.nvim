local M = {}

---@class DailyNoteConfig
---@field base_dir string The root directory for notes. The feature is only active here.
---@field journal_path string The sub-directory within base_dir for journal entries.
---@field file_format string The format for the note's filename, using os.date patterns.
---@field dir_format string The format for the directory structure, using os.date patterns.
---@field template_path string | nil Optional path to a template file for new notes if yesterday's doesn't exist.
---@field ignored_headers string[] List of headers to ignore when copying from yesterday's note.
---@field timestamp_format string The format for the timestamp, using os.date patterns.
---@field search_depth number The number of days to look back for a recent note to copy from.

---@class NoteSection
---@field header string|nil The header line (e.g., "# Header")
---@field content string[] Array of content lines under this header



---@type DailyNoteConfig
local default_config = {
	base_dir = vim.fn.expand("~/Desktop/notes"),
	journal_path = "Journal",
	file_format = "%Y-%m-%d.md",
	dir_format = "%Y/%m",
	template_path = nil,
	ignored_headers = {},
	timestamp_format = "%H:%M:%S",
	search_depth = 7,
}

M.config = vim.deepcopy(default_config)

---Parse note content into a structured format
---@param lines string[] Array of lines from the note
---@return NoteSection[] Array of parsed sections
local function _parse_note_content(lines)
	---@type NoteSection[]
	local sections = {}
	---@type NoteSection
	local current_section = { header = nil, content = {} }

	for _, line in ipairs(lines) do
		if line:match("^#+") then
			-- Only add the current section if it has content or a header
			if current_section.header or #current_section.content > 0 then
				table.insert(sections, current_section)
			end
			current_section = { header = line, content = {} }
		else
			table.insert(current_section.content, line)
		end
	end

	-- Always add the final section
	table.insert(sections, current_section)

	return sections
end

---Merge two parsed note structures, using template structure but preserving old content
---@param template_parsed NoteSection[] Parsed template structure (defines the output structure)
---@param old_note_parsed NoteSection[] Parsed old note (source of content to preserve)
---@return string The merged content as a single string
local function _merge_note_contents(template_parsed, old_note_parsed)
	---@type string[]
	local merged_lines = {}

	-- Create lookup table for old note sections by header
	---@type table<string, string[]>
	local old_sections_by_header = {}
	---@type table<string, boolean>
	local used_old_headers = {}

	for _, section in ipairs(old_note_parsed) do
		if section.header then
			old_sections_by_header[section.header] = section.content
		end
	end

	-- Process template sections, using old content where available
	for _, template_section in ipairs(template_parsed) do
		if template_section.header then
			-- Add the header
			table.insert(merged_lines, template_section.header)

			-- Use old content if available, otherwise use template content
			if old_sections_by_header[template_section.header] then
				used_old_headers[template_section.header] = true
				for _, line in ipairs(old_sections_by_header[template_section.header]) do
					table.insert(merged_lines, line)
				end
			else
				for _, line in ipairs(template_section.content) do
					table.insert(merged_lines, line)
				end
			end
		else
			-- Section without header (usually at the beginning)
			for _, line in ipairs(template_section.content) do
				table.insert(merged_lines, line)
			end
		end
	end

	-- Add any sections from old note that weren't in the template
	for _, old_section in ipairs(old_note_parsed) do
		if old_section.header and not used_old_headers[old_section.header] then
			table.insert(merged_lines, old_section.header)
			for _, line in ipairs(old_section.content) do
				table.insert(merged_lines, line)
			end
		end
	end

	return table.concat(merged_lines, "\n")
end



---Setup function to configure the daily note system
---@param opts DailyNoteConfig|nil Configuration options
---@return boolean Success status
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts)

	-- Expand paths
	M.config.base_dir = vim.fn.expand(M.config.base_dir)
	if M.config.template_path then
		M.config.template_path = vim.fn.expand(M.config.template_path)
	end

	-- Validate configuration
	if not M.config.base_dir or M.config.base_dir == "" then
		vim.notify("daily-notes: base_dir cannot be empty", vim.log.levels.ERROR)
		return false
	end

	if not M.config.journal_path or M.config.journal_path == "" then
		vim.notify("daily-notes: journal_path cannot be empty", vim.log.levels.ERROR)
		return false
	end

	-- Check if template exists if specified
	if M.config.template_path and vim.fn.filereadable(M.config.template_path) == 0 then
		vim.notify("daily-notes: Template file not found: " .. M.config.template_path, vim.log.levels.WARN)
	end

	return true
end

---Extract date components from a file path
---@param path string File path
---@return {year: number, month: number, day: number}|nil Date components or nil if parsing fails
local function get_date_from_path(path)
	local filename = vim.fn.fnamemodify(path, ":t")
	local year, month, day = filename:match("^(%d%d%d%d)-(%d%d)-(%d%d)%.md$")
	if not (year and month and day) then
		return nil
	end
	return { year = tonumber(year), month = tonumber(month), day = tonumber(day) }
end

---Get template version from a file's frontmatter
---@param path string|nil File path
---@return string|nil Template version or nil if not found
local function get_template_version(path)
	if not path or vim.fn.filereadable(path) == 0 then
		return nil
	end

	local lines = vim.fn.readfile(path)
	if #lines < 2 or lines[1] ~= "---" then
		return nil
	end

	for i = 2, #lines do
		if lines[i] == "---" then
			return nil -- Reached end of frontmatter without finding version
		end
		-- Match 'template_version:' with optional whitespace
		local match = lines[i]:match("template_version:%s*(.+)")
		if match then
			-- Trim leading/trailing whitespace from the matched value
			return match:match("^%s*(.-)%s*$")
		end
	end

	return nil -- No closing '---' or version found
end

---Generate metadata frontmatter for a note
---@param date_table osdate Date table
---@param template_version string|nil Template version
---@return string Metadata as string
local function generate_metadata(date_table, template_version)
	local note_date_ts = os.time(date_table)
	local id = os.date("%Y-%m-%d", note_date_ts)
	local alias_date = os.date("%B %d, %Y", note_date_ts)
	local creation_date = os.date("%Y-%m-%d")

	local version = template_version
	if not version or version == "" then
		-- Using current date for template_version as it's when the note is created.
		version = creation_date
	end

	local metadata = {
		"---",
		"id: " .. id,
		"aliases:",
		"    - " .. alias_date,
		"tags:",
		"    - daily",
		"    - log",
		"    - daily-notes",
		"template_version: " .. version,
		"---",
		"", -- Extra newline for separation
	}
	return table.concat(metadata, "\n")
end

---Remove frontmatter from lines array
---@param lines string[] Array of lines
---@return string[] Lines without frontmatter
local function strip_frontmatter_from_lines(lines)
	if #lines == 0 or lines[1] ~= "---" then
		return lines
	end

	local end_marker_index = -1
	for i = 2, #lines do
		if lines[i] == "---" then
			end_marker_index = i
			break
		end
	end

	if end_marker_index > 0 then
		local new_lines = {}
		for i = end_marker_index + 1, #lines do
			table.insert(new_lines, lines[i])
		end
		-- Also remove a potential blank line after the frontmatter
		if #new_lines > 0 and new_lines[1] == "" then
			table.remove(new_lines, 1)
		end
		return new_lines
	end

	return lines -- No closing '---' found
end

---Strip ignored headers from lines array
---@param lines string[] Array of lines
---@param ignored_headers string[] List of headers to ignore
---@return string[] Lines with ignored headers removed
local function strip_ignored_headers_from_lines(lines, ignored_headers)
	if #ignored_headers == 0 then
		return lines
	end

	local new_lines = {}
	local ignored_header_level = nil

	for _, line in ipairs(lines) do
		local header_match = line:match("^(#+)")
		if header_match then
			local current_level = #header_match

			-- If we're in an ignored section, check if this header ends it
			if ignored_header_level and current_level <= ignored_header_level then
				ignored_header_level = nil
			end

			-- Check if this header should be ignored
			if not ignored_header_level then
				for _, ignored_header in ipairs(ignored_headers) do
					if line:match("^#+%s+" .. ignored_header) then
						ignored_header_level = current_level
						break
					end
				end
			end
		end

		-- Include line if not in ignored section
		if not ignored_header_level then
			table.insert(new_lines, line)
		end
	end

	return new_lines
end

---Find the most recent note path to copy from
---@param start_date osdate The date to start searching backward from
---@return string|nil The path to the most recent note, or nil if not found
local function _find_most_recent_note_path(start_date)
	local start_time = os.time(start_date)
	for i = 1, M.config.search_depth do
		local prev_time = start_time - (i * 24 * 60 * 60)
		local prev_date = os.date("*t", prev_time)
		local dir_path = M.config.base_dir ..
				"/" .. M.config.journal_path .. "/" .. os.date(M.config.dir_format, os.time(prev_date))
		local filename = os.date(M.config.file_format, os.time(prev_date))
		local file_path = dir_path .. "/" .. filename

		if vim.fn.filereadable(file_path) == 1 then
			return file_path
		end
	end
	return nil
end

---Create a new note
---@param date_table osdate The date for the new note
---@param note_path string The full path to the new note
local function _create_note(date_table, note_path)
	vim.fn.mkdir(vim.fn.fnamemodify(note_path, ":h"), "p")

	local template_version = get_template_version(M.config.template_path)
	local new_metadata = generate_metadata(date_table, template_version)

	local recent_note_path = _find_most_recent_note_path(date_table)
	local content = ""
	local prev_note_version = get_template_version(recent_note_path)

	if template_version and prev_note_version and template_version > prev_note_version then
		local template_lines = vim.fn.readfile(M.config.template_path)
		local yesterday_lines = vim.fn.readfile(recent_note_path)

		local template_parsed = _parse_note_content(strip_frontmatter_from_lines(template_lines))
		local yesterday_parsed = _parse_note_content(strip_frontmatter_from_lines(yesterday_lines))

		content = _merge_note_contents(template_parsed, yesterday_parsed)
		vim.notify("Created note by merging the updated template.", vim.log.levels.INFO)
	elseif recent_note_path then
		local lines = vim.fn.readfile(recent_note_path)
		lines = strip_frontmatter_from_lines(lines)
		lines = strip_ignored_headers_from_lines(lines, M.config.ignored_headers)
		content = table.concat(lines, "\n")
		local recent_filename = vim.fn.fnamemodify(recent_note_path, ":t")
		vim.notify("Created note from " .. recent_filename, vim.log.levels.INFO)
	elseif M.config.template_path and vim.fn.filereadable(M.config.template_path) == 1 then
		local lines = vim.fn.readfile(M.config.template_path)
		lines = strip_frontmatter_from_lines(lines)
		content = table.concat(lines, "\n")
		vim.notify("Created note from template.", vim.log.levels.INFO)
	else
		vim.notify("No recent note found. Creating an empty note.", vim.log.levels.INFO)
	end

	local final_content = new_metadata .. content
	vim.fn.writefile(vim.split(final_content, "\n", true), note_path)
	vim.cmd("e " .. note_path)
end

---Open today's daily note
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

	_create_note(today, today_path)
end

---Open an adjacent note (previous or next day)
---@param offset number Days offset (-1 for previous, 1 for next)
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

---Create tomorrow's note
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

	_create_note(tomorrow, tomorrow_path)
end

---Insert a timestamp
---@param on_new_line boolean|nil If true, insert on a new line
function M.insert_timestamp(on_new_line)
	local current_line = vim.fn.line(".")
	local indent = vim.fn.indent(current_line)
	local timestamp = os.date(M.config.timestamp_format)
	local current_content = vim.api.nvim_get_current_line()

	if on_new_line then
		local new_line = string.rep(" ", indent) .. "- [" .. timestamp .. "] "
		vim.api.nvim_buf_set_lines(0, current_line, current_line, false, { new_line })
		vim.api.nvim_win_set_cursor(0, { current_line + 1, #new_line })
	else
		local new_content = current_content .. " - [" .. timestamp .. "] "
		vim.api.nvim_set_current_line(new_content)
		vim.api.nvim_win_set_cursor(0, { current_line, #new_content })
	end

	vim.cmd("startinsert!")
end

return M
