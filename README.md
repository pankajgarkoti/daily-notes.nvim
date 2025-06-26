# Simple Daily Notes

A simple and lightweight daily notes plugin for Neovim that helps you maintain a daily journal with ease.

## Features

- 🗓️ **Daily Note Management**: Automatically create and open daily notes
- 📁 **Organized Structure**: Notes are organized by year/month directories
- 📝 **Template Support**: Use templates for new notes or copy from previous day
- ⚡ **Fast Navigation**: Quickly navigate between previous/next day notes
- 🛠️ **Interactive Configuration**: Configure the plugin interactively
- 🎯 **Directory-aware**: Only active when working in your notes directory

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/simple-daily-notes.nvim",
  config = function()
    require("simple-daily-notes").setup({
      base_dir = "~/Documents/Notes",  -- Your notes directory
      journal_path = "Daily",          -- Subdirectory for daily notes
      template_path = "~/Documents/Notes/templates/daily.md", -- Optional template
    })
  end,
  keys = {
    { "<leader>dn", function() require("simple-daily-notes").open_daily_note() end, desc = "Open daily note" },
    { "<leader>dp", function() require("simple-daily-notes").open_adjacent_note(-1) end, desc = "Previous daily note" },
    { "<leader>dt", function() require("simple-daily-notes").open_adjacent_note(1) end, desc = "Next daily note" },
    { "<leader>dm", function() require("simple-daily-notes").create_tomorrow_note() end, desc = "Create tomorrow's note" },
    { "<leader>dc", function() require("simple-daily-notes").configure_interactive() end, desc = "Configure daily notes" },
  },
  cmd = {
    "DailyNote",
    "DailyNotePrev", 
    "DailyNoteNext",
    "DailyNoteTomorrow",
    "DailyNoteConfig",
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "your-username/simple-daily-notes.nvim",
  config = function()
    require("simple-daily-notes").setup({
      -- your configuration here
    })
  end
}
```

## Configuration

### Default Configuration

```lua
{
  base_dir = "~/Desktop/notes",    -- Root directory for notes
  journal_path = "Journal",        -- Subdirectory for daily notes  
  file_format = "%Y-%m-%d.md",     -- Date format for filenames
  dir_format = "%Y/%m",            -- Date format for directories
  template_path = nil,             -- Optional template file path
}
```

### Configuration Options

- **`base_dir`**: The root directory where your notes are stored. The plugin only works when you're in this directory or its subdirectories.
- **`journal_path`**: Subdirectory within `base_dir` where daily notes will be stored.
- **`file_format`**: Format for daily note filenames using `os.date` patterns (default: `YYYY-MM-DD.md`).
- **`dir_format`**: Format for organizing notes into subdirectories using `os.date` patterns (default: `YYYY/MM`).
- **`template_path`**: Optional path to a template file. If provided, new notes will use this template when yesterday's note doesn't exist.

## Usage

### Commands

- `:DailyNote` - Open today's daily note
- `:DailyNotePrev` - Open previous day's note
- `:DailyNoteNext` - Open next day's note  
- `:DailyNoteTomorrow` - Create and open tomorrow's note
- `:DailyNoteConfig` - Interactive configuration

### Default Key Mappings

When using the lazy.nvim configuration above:

- `<leader>dn` - Open daily note
- `<leader>dp` - Previous daily note
- `<leader>dt` - Next daily note  
- `<leader>dm` - Create tomorrow's note
- `<leader>dc` - Configure plugin

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

## License

MIT License - see LICENSE file for details.