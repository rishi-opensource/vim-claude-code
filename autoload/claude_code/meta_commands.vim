" autoload/claude_code/meta_commands.vim
" Meta commands: chat, context, model
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_meta_commands')
  finish
endif
let g:autoloaded_claude_code_meta_commands = 1

" 14. :Claude chat
function! claude_code#meta_commands#chat(flags) abort
  let l:msg = input('Claude> ')
  redraw
  if empty(trim(l:msg))
    return
  endif
  call claude_code#terminal_bridge#send(
        \ claude_code#util#file_context() . l:msg)
endfunction

" 16. :Claude context
function! claude_code#meta_commands#context(flags) abort
  let l:sel      = claude_code#util#visual_selection()
  let l:sel_info = empty(l:sel)
        \ ? 'none (will use current function / file)'
        \ : len(split(l:sel, "\n")) . ' lines selected'
  let l:model    = claude_code#config#get('model', 'default')
  let l:git_root = claude_code#git#root()

  call claude_code#util#open_scratch('Claude: Context Preview', [
        \ '──────────────────────────────────',
        \ ' Claude Code — Context Preview',
        \ '──────────────────────────────────',
        \ 'File     : ' . expand('%:p'),
        \ 'Filetype : ' . &filetype,
        \ 'Git root : ' . (empty(l:git_root) ? '(not a git repo)' : l:git_root),
        \ 'Selection: ' . l:sel_info,
        \ 'Model    : ' . l:model,
        \ '──────────────────────────────────',
        \ 'Press q to close',
        \ ])
endfunction

" 17. :Claude model
function! claude_code#meta_commands#model(flags) abort
  let l:model = trim(matchstr(a:flags, '\S\+'))

  if empty(l:model)
    let l:choice = inputlist([
          \ 'Select model:',
          \ '1. claude-opus-4-6    (most capable)',
          \ '2. claude-sonnet-4-6  (balanced, default)',
          \ '3. claude-haiku-4-5-20251001  (fastest)',
          \ ])
    let l:model = get({1: 'claude-opus-4-6', 2: 'claude-sonnet-4-6',
          \            3: 'claude-haiku-4-5-20251001'}, l:choice, '')
    if empty(l:model)
      return
    endif
  else
    let l:model = get({
          \ 'opus':   'claude-opus-4-6',
          \ 'sonnet': 'claude-sonnet-4-6',
          \ 'haiku':  'claude-haiku-4-5-20251001',
          \ }, tolower(l:model), l:model)
  endif

  call claude_code#config#set('model', l:model)

  let l:bnr = claude_code#terminal_bridge#get_buf()
  if l:bnr >= 0
    call term_sendkeys(l:bnr, '/model ' . l:model . "\n")
    echomsg 'claude-code: model → ' . l:model . ' (terminal notified)'
  else
    echomsg 'claude-code: model → ' . l:model . ' (takes effect on next session)'
  endif
endfunction
