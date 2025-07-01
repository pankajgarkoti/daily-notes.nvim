" Daily Notes Plugin
" Commands for traditional plugin loading

if exists('g:loaded_daily_notes')
  finish
endif
let g:loaded_daily_notes = 1

" Create commands that will be available globally
command! DailyNote lua require('daily-notes').open_daily_note()
command! DailyNotePrev lua require('daily-notes').open_adjacent_note(-1)
command! DailyNoteNext lua require('daily-notes').open_adjacent_note(1)
command! DailyNoteTomorrow lua require('daily-notes').create_tomorrow_note()
command! DailyNoteConfig lua require('daily-notes').configure_interactive()
command! DailyNoteTimestamp lua require('daily-notes').insert_timestamp()
command! DailyNoteTimestampNewLine lua require('daily-notes').insert_timestamp_new_line()