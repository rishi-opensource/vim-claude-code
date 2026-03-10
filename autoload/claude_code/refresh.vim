vim9script

# claude_code/refresh.vim - File change detection and auto-reload
# Maintainer: Claude Code Vim Plugin
# License: MIT

import './config.vim'

# State
var timer_id = -1
var saved_updatetime = -1
var saved_autoread = -1
var active = false

# Start file-refresh monitoring.
# Lowers 'updatetime' for faster CursorHold triggers and sets up both
# event-driven and timer-based checktime calls.
export def Start()
  if !config.Get('refresh_enable') || active
    return
  endif
  active = true

  # Save and lower updatetime.
  saved_updatetime = &updatetime
  # Lower updatetime to trigger CursorHold more frequently while Claude
  # is active. 500ms is a reasonable balance — fast enough to catch file
  # changes quickly, but not so aggressive that it interferes with other
  # plugins (GitGutter, ALE, LSP clients) or floods swap file writes.
  &updatetime = 500

  # Save and enable autoread so :checktime actually reloads silently.
  saved_autoread = &autoread
  &autoread = true

  # Event-driven refresh.
  augroup ClaudeCodeRefresh
    autocmd!
    autocmd CursorHold,CursorHoldI * SafeChecktime()
    autocmd FocusGained,BufEnter   * SafeChecktime()
    autocmd InsertLeave            * SafeChecktime()
    # Notification on reload.
    if config.Get('refresh_notify')
      autocmd FileChangedShellPost * echomsg 'claude-code: buffer reloaded — ' .. expand('<afile>')
    endif
  augroup END

  # Timer-based polling as a safety net.
  var interval = config.Get('refresh_interval')
  timer_id = timer_start(interval, TimerChecktime, {repeat: -1})
enddef

# Stop file-refresh monitoring and restore original updatetime.
export def Stop()
  if !active
    return
  endif
  active = false

  # Stop timer.
  if timer_id >= 0
    timer_stop(timer_id)
    timer_id = -1
  endif

  # Remove autocommands.
  augroup ClaudeCodeRefresh
    autocmd!
  augroup END

  # Restore updatetime.
  if saved_updatetime >= 0
    &updatetime = saved_updatetime
    saved_updatetime = -1
  endif

  # Restore autoread.
  if saved_autoread >= 0
    &autoread = saved_autoread != 0
    saved_autoread = -1
  endif
enddef

# Run :checktime only when safe (buffer is a normal file on disk).
def SafeChecktime()
  if &buftype ==# '' && filereadable(expand('%'))
    silent! checktime
  endif
enddef

# Timer callback — runs checktime across all windows.
def TimerChecktime(_tid: number)
  silent! checktime
enddef

