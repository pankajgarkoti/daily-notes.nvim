# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - Unreleased

### Added

- Initial release of `daily-notes`.
- Commands to open today's, previous, next, and tomorrow's daily notes (`:DailyNote`, `:DailyNotePrev`, `:DailyNoteNext`, `:DailyNoteTomorrow`).
- Interactive configuration with `:DailyNoteConfig`.
- Configuration via `setup()` function for `base_dir`, `journal_path`, `file_format`, `dir_format`, and `template_path`.
- Support for creating new notes from a template or by copying from the previous day.
- Vim help documentation (`doc/daily-notes.txt`).
