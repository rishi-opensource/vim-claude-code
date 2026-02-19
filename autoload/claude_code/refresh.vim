" claude_code/refresh.vim - File change detection and auto-reload
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_refresh')
  finish
endif
let g:autoloaded_claude_code_refresh = 1

" State
let s:timer_id = -1
let s:saved_updatetime = -1
let s:active = 0

" Start file-refresh monitoring.
" Lowers 'updatetime' for faster CursorHold triggers and sets up both
" event-driven and timer-based checktime calls.
function! claude_code#refresh#start() abort
  if !claude_code#config#get('refresh_enable') || s:active
    return
  endif
  let s:active = 1

  " Save and lower updatetime.
  let s:saved_updatetime = &updatetime
  let &updatetime = 100

  " Enable autoread so :checktime actually reloads silently.
  set autoread

  " Event-driven refresh.
  augroup ClaudeCodeRefresh
    autocmd!
    autocmd CursorHold,CursorHoldI * call s:safe_checktime()
    autocmd FocusGained,BufEnter   * call s:safe_checktime()
    autocmd InsertLeave            * call s:safe_checktime()
    " Notification on reload.
    if claude_code#config#get('refresh_notify')
      autocmd FileChangedShellPost * echomsg 'claude-code: buffer reloaded — ' . expand('<afile>')
    endif
  augroup END

  " Timer-based polling as a safety net.
  let l:interval = claude_code#config#get('refresh_interval')
  let s:timer_id = timer_start(l:interval, function('s:timer_checktime'), {'repeat': -1})
endfunction

" Stop file-refresh monitoring and restore original updatetime.
function! claude_code#refresh#stop() abort
  if !s:active
    return
  endif
  let s:active = 0

  " Stop timer.
  if s:timer_id >= 0
    call timer_stop(s:timer_id)
    let s:timer_id = -1
  endif

  " Remove autocommands.
  augroup ClaudeCodeRefresh
    autocmd!
  augroup END

  " Restore updatetime.
  if s:saved_updatetime >= 0
    let &updatetime = s:saved_updatetime
    let s:saved_updatetime = -1
  endif
endfunction

" Run :checktime only when safe (buffer is a normal file on disk).
function! s:safe_checktime() abort
  if &buftype ==# '' && filereadable(expand('%'))
    silent! checktime
  endif
endfunction

" Timer callback — runs checktime across all windows.
function! s:timer_checktime(timer_id) abort
  silent! checktime
endfunction
