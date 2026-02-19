" claude_code.vim - Claude Code CLI integration for Vim
" Maintainer: Claude Code Vim Plugin
" License: MIT
" Requires: Vim 8.2+ with +terminal

" Load guard.
if exists('g:loaded_claude_code')
  finish
endif
let g:loaded_claude_code = 1

" Feature check.
if !has('terminal')
  echohl ErrorMsg
  echomsg 'claude-code: this plugin requires Vim with +terminal support (Vim 8.0+)'
  echohl None
  finish
endif

" ---------------------------------------------------------------------------
" Commands
" ---------------------------------------------------------------------------

command! -nargs=? -complete=customlist,<SID>complete Claude
      \ call claude_code#terminal#toggle(<f-args>)

function! s:complete(ArgLead, CmdLine, CursorPos) abort
  let l:subs = ['continue', 'resume', 'verbose']
  return filter(copy(l:subs), 'v:val =~# "^" . a:ArgLead')
endfunction

" ---------------------------------------------------------------------------
" Default keymaps
" ---------------------------------------------------------------------------

if claude_code#config#get('map_keys')
  " Normal mode toggle.
  let s:toggle_key = claude_code#config#get('map_toggle')
  if !empty(s:toggle_key)
    execute 'nnoremap <silent> ' . s:toggle_key . ' :Claude<CR>'
    execute 'tnoremap <silent> ' . s:toggle_key . ' <C-\><C-n>:Claude<CR>'
  endif

  " Variant keymaps.
  let s:cont_key = claude_code#config#get('map_continue')
  if !empty(s:cont_key)
    execute 'nnoremap <silent> ' . s:cont_key . ' :Claude continue<CR>'
  endif

  let s:verbose_key = claude_code#config#get('map_verbose')
  if !empty(s:verbose_key)
    execute 'nnoremap <silent> ' . s:verbose_key . ' :Claude verbose<CR>'
  endif
endif
