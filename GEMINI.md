# Project Guidelines: daily-notes.nvim

This document outlines the best practices and conventions for developing this plugin with Gemini. Adhering to these rules will ensure code quality, consistency, and a smooth workflow.

## General Workflow

When making changes to this project, please follow these steps:

1.  **Code Implementation:** Write or modify the Lua code in the `lua/` directory to implement the desired feature or fix.
1.  **Break Down Big Changes** Add separate files for big changes and feature additions.
1.  **Documentation First:** Before finalizing any code, update the user-facing documentation to reflect the changes. This includes:
    - `README.md`: This is the primary source of information for users. Ensure it is clear, accurate, and provides complete examples.
    - `doc/daily-notes.txt`: The Vim help file must be kept in sync with all new features, commands, and configuration options.
1.  **Update Vim Plugin File:** If any new commands are added or existing ones are modified, update `plugin/daily-notes.vim` accordingly.
1.  **Linting:** Before committing, always run the linter to ensure the code adheres to the project's style guidelines. The command is:
    ```bash
    luacheck .
    ```
1.  **Commit:** Write a clear and descriptive commit message summarizing the changes. It should be 2 sentences or less and follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format.

## Key Conventions

- **Single Source of Truth for Keymaps:** The `lazy.nvim` installation example in `README.md` should be treated as the single source of truth for all recommended keymaps. Do not add keymap logic to the `setup()` function in the Lua code.
- **Thorough Documentation:** Ensure all examples, especially in the `README.md`, are complete and functional.

## Things to Avoid

Based on our previous session, here are specific things to avoid:

- **Do not use placeholder comments:** Never leave placeholders like `-- Existing keymaps...` in documentation or code. Always provide the full, correct implementation.
- **Do not commit failing code:** Always run the linter and ensure it passes before committing any changes. Do not commit code with known bugs or style violations.
- **Do not leave dead code:** Remove any unused functions, variables, or other code remnants from refactoring to keep the codebase clean.
- **Do not make Git assumptions:** When pushing changes, do not assume the local branch is tracking a remote. Use explicit commands if necessary (`git push origin <branch-name>`).
