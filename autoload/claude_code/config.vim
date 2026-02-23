" claude_code/config.vim - Configuration defaults and access helpers
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_config')
  finish
endif
let g:autoloaded_claude_code_config = 1

" Default configuration values.
" Users override these by setting g:claude_code_<key> in their vimrc.
let s:defaults = {
      \ 'command':          'claude',
      \ 'split_ratio':      0.3,
      \ 'position':         'bottom',
      \ 'enter_insert':     1,
      \ 'hide_numbers':     1,
      \ 'hide_signcolumn':  1,
      \ 'use_git_root':     1,
      \ 'multi_instance':   1,
      \ 'map_keys':         1,
      \ 'refresh_enable':   1,
      \ 'refresh_interval': 1000,
      \ 'refresh_notify':   1,
      \ 'float_width':      0.8,
      \ 'float_height':     0.8,
      \ 'float_border':     'rounded',
      \ 'variant_continue': '--continue',
      \ 'variant_resume':   '--resume',
      \ 'variant_verbose':  '--verbose',
      \ 'map_toggle':       '<C-\>',
      \ 'map_continue':     '<Leader>cC',
      \ 'map_verbose':      '<Leader>cV',
      \ }

" Get a configuration value.
" Checks buffer-local (b:claude_code_<key>) first, then global
" (g:claude_code_<key>), then falls back to the built-in default.
function! claude_code#config#get(key, ...) abort
  let l:bvar = 'claude_code_' . a:key
  if exists('b:' . l:bvar)
    return get(b:, l:bvar)
  endif
  let l:default = get(s:defaults, a:key, a:0 ? a:1 : '')
  return get(g:, l:bvar, l:default)
endfunction

" Return a copy of the full defaults dictionary (useful for documentation).
function! claude_code#config#defaults() abort
  return copy(s:defaults)
endfunction

" Set a configuration value for the current session.
" Writes to the g:claude_code_<key> variable that get() already reads.
function! claude_code#config#set(key, value) abort
  let g:{'claude_code_' . a:key} = a:value
endfunction
