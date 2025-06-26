-- Neovim plugin luacheck configuration
globals = {
  "vim",
}

-- Standard Lua globals
std = "lua51"

-- Ignore some common patterns
ignore = {
  "212", -- Unused argument
  "213", -- Unused loop variable
  "631", -- Line is too long
}

-- Read globals from other files
read_globals = {
  "vim",
}