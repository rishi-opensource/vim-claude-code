" claude_code/keymaps.vim - Terminal-local keymap management
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_keymaps')
  finish
endif
let g:autoloaded_claude_code_keymaps = 1

" Set up buffer-local keymaps on a Claude Code terminal buffer.
" Called each time a new terminal is created or an existing one is reopened.
function! claude_code#keymaps#setup_terminal(bufnr) abort
  " Window navigation from terminal mode: <C-h/j/k/l>
  " Pattern: escape terminal mode -> switch window -> re-enter terminal mode
  " in the target window if it is also a terminal.
  execute 'tnoremap <buffer> <silent> <C-h> <C-\><C-n><C-w>h'
  execute 'tnoremap <buffer> <silent> <C-j> <C-\><C-n><C-w>j'
  execute 'tnoremap <buffer> <silent> <C-k> <C-\><C-n><C-w>k'
  execute 'tnoremap <buffer> <silent> <C-l> <C-\><C-n><C-w>l'

  " Mouse/touchpad scroll in terminal mode: escape to Normal, scroll, stay in
  " Normal so the user can keep reading.  Vim passes raw ScrollWheel events
  " through to the running program when in terminal mode, so we must intercept
  " them here and translate them into normal-mode scroll commands instead.
  " Disable with: let g:claude_code_scroll_keys = 0
  if claude_code#config#get('scroll_keys')
    execute 'tnoremap <buffer> <silent> <ScrollWheelUp>    <C-\><C-n><C-y>'
    execute 'tnoremap <buffer> <silent> <ScrollWheelDown>  <C-\><C-n><C-e>'
    execute 'tnoremap <buffer> <silent> <2-ScrollWheelUp>  <C-\><C-n><C-y>'
    execute 'tnoremap <buffer> <silent> <2-ScrollWheelDown> <C-\><C-n><C-e>'
    execute 'tnoremap <buffer> <silent> <3-ScrollWheelUp>  <C-\><C-n><C-y>'
    execute 'tnoremap <buffer> <silent> <3-ScrollWheelDown> <C-\><C-n><C-e>'
    execute 'tnoremap <buffer> <silent> <4-ScrollWheelUp>  <C-\><C-n><C-y>'
    execute 'tnoremap <buffer> <silent> <4-ScrollWheelDown> <C-\><C-n><C-e>'
  endif

  " Normal mode equivalents (when browsing terminal scrollback).
  execute 'nnoremap <buffer> <silent> <C-h> <C-w>h'
  execute 'nnoremap <buffer> <silent> <C-j> <C-w>j'
  execute 'nnoremap <buffer> <silent> <C-k> <C-w>k'
  execute 'nnoremap <buffer> <silent> <C-l> <C-w>l'

  " Autocommand to re-enter terminal mode when switching INTO the Claude window
  " from another window.  Uses WinEnter only (not BufEnter) so that the user
  " can escape to Normal mode inside the Claude window for scrollback browsing
  " without being immediately kicked back into terminal mode.
  " BufEnter also fires on mouse-clicks within the same buffer, which was the
  " root cause of scroll being broken: any scroll attempt triggered BufEnter
  " which fired 'normal! i', putting Vim back in terminal mode and sending the
  " scroll event to Claude CLI as raw input instead of scrolling the buffer.
  if claude_code#config#get('enter_insert')
    augroup ClaudeCodeTermFocus
      execute 'autocmd! * <buffer=' . a:bufnr . '>'
      execute 'autocmd WinEnter <buffer=' . a:bufnr . '>'
            \ . ' if mode() !~# ''[tRiI]'' && mode() !=# ''c'' | silent! normal! i | endif'
    augroup END
  endif
endfunction
