" autoload/claude_code/config_ext.vim
" Extends the base config module with runtime session overrides.
"
" The base plugin (config.vim) already defines claude_code#config#get().
" We do NOT redefine it — we only add claude_code#config#set() for
" session-scoped overrides (e.g. :Claude model sonnet).
"
" How it works:
"   claude_code#config#set(key, val) stores into g:claude_code_{key}
"   which the base plugin's claude_code#config#get() already reads.

if exists('g:autoloaded_claude_code_config_ext')
  finish
endif
let g:autoloaded_claude_code_config_ext = 1

" claude_code#config#set(key, value)
" Write a runtime override by setting the canonical g: variable.
" The base claude_code#config#get() reads g:claude_code_{key}, so this
" integrates seamlessly without touching or redefining config.vim.
function! claude_code#config#set(key, value) abort
  let g:{'claude_code_' . a:key} = a:value
endfunction
