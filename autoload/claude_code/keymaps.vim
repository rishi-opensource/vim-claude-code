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

  " Normal mode equivalents (when browsing terminal scrollback).
  execute 'nnoremap <buffer> <silent> <C-h> <C-w>h'
  execute 'nnoremap <buffer> <silent> <C-j> <C-w>j'
  execute 'nnoremap <buffer> <silent> <C-k> <C-w>k'
  execute 'nnoremap <buffer> <silent> <C-l> <C-w>l'

  " Autocommand to re-enter terminal mode when focusing the Claude window.
  if claude_code#config#get('enter_insert')
    augroup ClaudeCodeTermFocus
      execute 'autocmd! * <buffer=' . a:bufnr . '>'
      execute 'autocmd BufEnter,WinEnter <buffer=' . a:bufnr . '>'
            \ . ' if mode() !=# "t" | silent! normal! i | endif'
    augroup END
  endif
endfunction
