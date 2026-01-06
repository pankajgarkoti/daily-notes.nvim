# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Lint (required before committing):**
```bash
luacheck .
```

No test suite exists. Manual testing only.

## Architecture

This is a Neovim plugin providing Obsidian-like daily notes functionality. It's a compact, single-module Lua plugin (~455 lines).

### Structure

- `lua/daily-notes.lua` - Core plugin logic (all functionality lives here)
- `plugin/daily-notes.vim` - VimScript command registration (6 commands)
- `init.lua` - Entry point that returns `require('daily-notes')`
- `doc/daily-notes.txt` - Vim help documentation

### Key Concepts

**Note Creation Flow:**
1. Check for most recent note within `search_depth` days
2. If template version is newer than recent note's version, merge template structure with recent note content
3. Otherwise copy from recent note (stripping frontmatter and ignored headers)
4. If no recent note, use template or create empty note
5. Generate YAML frontmatter with metadata

**Important Functions in `lua/daily-notes.lua`:**
- `M.setup(opts)` - Initialize with config, validates `base_dir` and `journal_path`
- `M.open_daily_note()` - Opens/creates today's note (only works when cwd is within `base_dir`)
- `M.open_adjacent_note(offset)` - Navigate ±N days from current note
- `_parse_note_content(lines)` - Parses markdown into sections by headers for merging
- `_merge_note_contents(template, old_note)` - Merges template structure with existing content
- `strip_ignored_headers_from_lines(lines, ignored_headers)` - Only top-level headers (`# Header`) can be ignored

**Template Versioning:**
- Templates use `template_version` in YAML frontmatter
- When template version > note version, triggers smart merge (template structure + old content)

### Commands (defined in `plugin/daily-notes.vim`)
- `:DailyNote` → `open_daily_note()`
- `:DailyNotePrev` / `:DailyNoteNext` → `open_adjacent_note(-1/1)`
- `:DailyNoteTomorrow` → `create_tomorrow_note()`
- `:DailyNoteTimestamp` → `insert_timestamp()`

## Development Conventions

From GEMINI.md:
- **Workflow:** Implement → Document (README.md + doc/daily-notes.txt) → Update plugin/daily-notes.vim if adding commands → Lint → Commit
- **Keymaps:** Define in README.md lazy.nvim example only, never in `setup()` code
- **Commits:** Follow Conventional Commits format, 2 sentences or less
- **No placeholders or dead code**
- **When pushing:** Use explicit `git push origin <branch-name>` (don't assume tracking)
