" Simple Daily Notes Plugin
" Commands for traditional plugin loading

if exists('g:loaded_simple_daily_notes')
  finish
endif
let g:loaded_simple_daily_notes = 1

" Create commands that will be available globally
command! DailyNote lua require('simple-daily-notes').open_daily_note()
command! DailyNotePrev lua require('simple-daily-notes').open_adjacent_note(-1)
command! DailyNoteNext lua require('simple-daily-notes').open_adjacent_note(1)
command! DailyNoteTomorrow lua require('simple-daily-notes').create_tomorrow_note()
command! DailyNoteConfig lua require('simple-daily-notes').configure_interactive()
