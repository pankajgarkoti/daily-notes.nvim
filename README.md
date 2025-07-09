# Daily Notes

A simple and lightweight daily notes plugin for Neovim that helps you maintain a daily journal with ease. This is an attempt to re-create Obsidian's daily notes functionality without any fluff.

[![Lint](https://github.com/pankajgarkoti/daily-notes.nvim/actions/workflows/lint.yml/badge.svg)](https://github.com/pankajgarkoti/daily-notes.nvim/actions/workflows/lint.yml)

## Features

- 🗓️ **Daily Note Management**: Automatically create and open daily notes.
- 📁 **Organized Structure**: Notes are organized by year/month directories.
- 📝 **Template Support**: Use templates for new notes or copy from the previous day.
- 🧹 **Selective Content Carryover**: Keep headers from the previous day's note but leave the content blank for a fresh start using the `ignored_headers` option.
- ⏰ **Customizable Timestamps**: Quickly insert timestamps with a configurable format and keymaps.
- ⚡ **Fast Navigation**: Quickly navigate between previous/next day notes.
- 🛠️ **Interactive Configuration**: Configure the plugin interactively.
- 🎯 **Directory-aware**: Only active when working in your notes directory.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "pankajgarkoti/daily-notes.nvim",
  config = function()
    require("daily-notes").setup({
      base_dir = "~/Documents/Notes",  -- Your notes directory
      journal_path = "Daily",          -- Subdirectory for daily notes
      template_path = "~/Documents/Notes/templates/daily.md", -- Optional template
      -- Example of ignoring a header
      ignored_headers = { "To-Do" },
    })
  end,
  keys = {
    { "<leader>dn", function() require("daily-notes").open_daily_note() end, desc = "Open daily note" },
    { "<leader>dk", function() require("daily-notes").open_adjacent_note(-1) end, desc = "Previous daily note" },
    { "<leader>dj", function() require("daily-notes").open_adjacent_note(1) end, desc = "Next daily note" },
    { "<leader>dm", function() require("daily-notes").create_tomorrow_note() end, desc = "Create tomorrow's note" },
    { "<leader>dc", function() require("daily-notes").configure_interactive() end, desc = "Configure daily notes" },
    { "<leader>ts", function() require("daily-notes").insert_timestamp() end, desc = "Insert timestamp" },
    { "<leader>T", function() require("daily-notes").insert_timestamp(true) end, desc = "Insert timestamp on new line" },
  },
  cmd = {
    "DailyNote",
    "DailyNotePrev",
    "DailyNoteNext",
    "DailyNoteTomorrow",
    "DailyNoteConfig",
    "DailyNoteTimestamp",
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "pankajgarkoti/daily-notes.nvim",
  config = function()
    require("daily-notes").setup({
      -- your configuration here
    })
  end
}
```

## Configuration

### Default Configuration

```lua
{
  base_dir = "~/Desktop/notes",
  journal_path = "Journal",
  file_format = "%Y-%m-%d.md",
  dir_format = "%Y/%m",
  template_path = nil,
  -- Headers to keep when creating a new note from the previous day, but whose
  -- content should be cleared.
  ignored_headers = {},
  -- The format for timestamps, using os.date patterns.
  timestamp_format = "%H:%M:%S",
}
```

### Configuration Options

- **`base_dir`**: The root directory where your notes are stored. The plugin only works when you're in this directory or its subdirectories.
- **`journal_path`**: Subdirectory within `base_dir` where daily notes will be stored.
- **`file_format`**: Format for daily note filenames using `os.date` patterns (default: `YYYY-MM-DD.md`).
- **`dir_format`**: Format for organizing notes into subdirectories using `os.date` patterns (default: `YYYY/MM`).
- **`template_path`**: Optional path to a template file. If provided, new notes will use this template when yesterday's note doesn't exist.
- **`ignored_headers`**: A list of top-level headers (e.g., `{ "Tasks" }`) whose content should be cleared when creating a new note from the previous day. The headers themselves are kept.
- **`timestamp_format`**: The format for timestamps, using `os.date` patterns (default: `%H:%M:%S`).
- **`search_depth`**: The number of days to look back for a recent note to copy from when the previous day's note doesn't exist (default: `7`).

## Usage

### Commands

- `:DailyNote` - Open today's daily note
- `:DailyNotePrev` - Open previous day's note
- `:DailyNoteNext` - Open next day's note
- `:DailyNoteTomorrow` - Create and open tomorrow's note
- `:DailyNoteConfig` - Interactive configuration
- `:DailyNoteTimestamp` - Insert a timestamp

### Key Mappings

The plugin provides functions to insert timestamps, which you can map to your preferred keys. Here is the recommended setup for `lazy.nvim`:

```lua
-- In your lazy.nvim plugin spec
keys = {
  { "<leader>dn", function() require("daily-notes").open_daily_note() end, desc = "Open daily note" },
  { "<leader>dk", function() require("daily-notes").open_adjacent_note(-1) end, desc = "Previous daily note" },
  { "<leader>dj", function() require("daily-notes").open_adjacent_note(1) end, desc = "Next daily note" },
  { "<leader>dm", function() require("daily-notes").create_tomorrow_note() end, desc = "Create tomorrow's note" },
  { "<leader>dc", function() require("daily-notes").configure_interactive() end, desc = "Configure daily notes" },
  { "<leader>ts", function() require("daily-notes").insert_timestamp() end, desc = "Insert timestamp" },
  { "<leader>T", function() require("daily-notes").insert_timestamp(true) end, desc = "Insert timestamp on new line" },
}
```

This setup provides two keymaps for timestamps:

- `<leader>ts`: Inserts a timestamp at the current cursor position.
- `<leader>T`: Inserts a timestamp on a new line below the current one.

## Directory Structure

The plugin creates a directory structure like this:

```
~/Documents/Notes/
├── Daily/
│   ├── 2024/
│   │   ├── 01/
│   │   │   ├── 2024-01-15.md
│   │   │   └── 2024-01-16.md
│   │   └── 02/
│   │       ├── 2024-02-01.md
│   │       └── 2024-02-02.md
│   └── templates/
│       └── daily.md
```

## How It Works

1. **Daily Note Creation**: When you open a daily note, the plugin first checks if it exists. If not, it creates it by copying content from yesterday's note or from a template.

2. **Directory Awareness**: The plugin only works when you're in your configured notes directory, preventing accidental note creation elsewhere.

3. **Navigation**: Easily navigate between days using the previous/next commands, which automatically find and open notes based on the current file's date.

4. **Template Support**: Supports both yesterday-based copying and template-based note creation for consistency.

## Requirements

- Neovim 0.7+
- No external dependencies

## AI Disclaimer

This plugin was create entirely using CodeCompanion https://github.com/olimorris/codecompanion.nvim and Aider https://github.com/aider-chat/aider

The models used were:

- `gemini-2.5-pro` and `gemini-2.5-flash` with Aider - Generated most of the code and documentation
- `claude-4-sonnet` with CodeCompanion - Helped with more minute fixes and changes

## License

MIT License - see LICENSE file for details.
