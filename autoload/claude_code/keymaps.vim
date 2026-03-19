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
  if !claude_code#config#get('map_keys')
    return
  endif

  " Window navigation from terminal mode: <C-h/j/k/l>
  " Pattern: escape terminal mode -> switch window -> re-enter terminal mode
  " in the target window if it is also a terminal.
  execute 'tnoremap <buffer> <silent> <C-h> <C-\><C-n><C-w>h'
  execute 'tnoremap <buffer> <silent> <C-j> <C-\><C-n><C-w>j'
  execute 'tnoremap <buffer> <silent> <C-k> <C-\><C-n><C-w>k'
  execute 'tnoremap <buffer> <silent> <C-l> <C-\><C-n><C-w>l'

  let l:zoom_key = claude_code#config#get('map_zoom')
  if !empty(l:zoom_key)
    execute 'tnoremap <buffer> <silent> ' . l:zoom_key . ' <C-\><C-n>:Claude zoom<CR>'
  endif

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
  if !empty(l:zoom_key)
    execute 'nnoremap <buffer> <silent> ' . l:zoom_key . ' :Claude zoom<CR>'
  endif

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
" Global keymaps setup
function! claude_code#keymaps#setup_globals() abort
  if !claude_code#config#get('map_keys')
    return
  endif

  let l:toggle_key = claude_code#config#get('map_toggle')
  if !empty(l:toggle_key)
    execute 'nnoremap <silent> ' . l:toggle_key . ' :Claude<CR>'
    execute 'tnoremap <silent> ' . l:toggle_key . ' <C-\><C-n>:Claude<CR>'
  endif

  let l:cont_key = claude_code#config#get('map_continue')
  if !empty(l:cont_key)
    execute 'nnoremap <silent> ' . l:cont_key . ' :Claude continue<CR>'
  endif

  let l:verbose_key = claude_code#config#get('map_verbose')
  if !empty(l:verbose_key)
    execute 'nnoremap <silent> ' . l:verbose_key . ' :Claude verbose<CR>'
  endif

  if claude_code#config#get('map_extended_keys')
    let l:prefix = claude_code#config#get('map_extended_prefix')
    " Normal mode
    execute 'nnoremap <silent> ' . l:prefix . 'e  :Claude explain<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'f  :Claude fix<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'r  :Claude refactor<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 't  :Claude test<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'd  :Claude doc<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'G  :Claude commit<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'R  :Claude review<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'p  :Claude pr<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'P  :Claude plan<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'a  :Claude analyze<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'n  :Claude rename<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'o  :Claude optimize<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'D  :Claude debug<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'A  :Claude apply<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'c  :Claude chat<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'x  :Claude context<CR>'
    execute 'nnoremap <silent> ' . l:prefix . 'm  :Claude model<CR>'

    " Visual mode
    execute 'xnoremap <silent> ' . l:prefix . 'e  :<C-u>Claude explain<CR>'
    execute 'xnoremap <silent> ' . l:prefix . 'f  :<C-u>Claude fix<CR>'
    execute 'xnoremap <silent> ' . l:prefix . 'r  :<C-u>Claude refactor<CR>'
    execute 'xnoremap <silent> ' . l:prefix . 't  :<C-u>Claude test<CR>'
    execute 'xnoremap <silent> ' . l:prefix . 'd  :<C-u>Claude doc<CR>'
    execute 'xnoremap <silent> ' . l:prefix . 'n  :<C-u>Claude rename<CR>'
    execute 'xnoremap <silent> ' . l:prefix . 'o  :<C-u>Claude optimize<CR>'
  endif
endfunction
