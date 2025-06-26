-- Simple Daily Notes Plugin
-- Commands for traditional plugin loading

if vim.g.loaded_simple_daily_notes == 1 then
  return
end
vim.g.loaded_simple_daily_notes = 1

-- Create commands that will be available globally
vim.api.nvim_create_user_command('DailyNote', function()
  require('simple-daily-notes').open_daily_note()
end, { desc = 'Open today\'s daily note' })

vim.api.nvim_create_user_command('DailyNotePrev', function()
  require('simple-daily-notes').open_adjacent_note(-1)
end, { desc = 'Open previous daily note' })

vim.api.nvim_create_user_command('DailyNoteNext', function()
  require('simple-daily-notes').open_adjacent_note(1)
end, { desc = 'Open next daily note' })

vim.api.nvim_create_user_command('DailyNoteTomorrow', function()
  require('simple-daily-notes').create_tomorrow_note()
end, { desc = 'Create tomorrow\'s note' })

vim.api.nvim_create_user_command('DailyNoteConfig', function()
  require('simple-daily-notes').configure_interactive()
end, { desc = 'Configure daily notes interactively' })
