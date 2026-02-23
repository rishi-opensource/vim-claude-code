" autoload/claude_code/meta_commands.vim
" Transparency & control: context, model, chat

" ─────────────────────────────────────────────
" 14. :Claude chat
" Opens a minimal interactive chat input prompt and sends to terminal.
" ─────────────────────────────────────────────
function! claude_code#meta_commands#chat(flags, ...) abort
  let msg = input('Claude> ')
  if empty(trim(msg))
    echo ''
    return
  endif
  echo ''

  let ctx = printf("File: %s | Filetype: %s\n", expand('%:p'), &filetype)
  let prompt = ctx . msg

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" 16. :Claude context
" Displays what context will be sent: file path, git root, selection length, model.
" ─────────────────────────────────────────────
function! claude_code#meta_commands#context(flags, ...) abort
  let file_path   = expand('%:p')
  let git_root    = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
  let model       = claude_code#config#get('model', 'default (claude picks)')
  let sel         = s:get_visual_selection()
  let sel_info    = empty(sel)
        \ ? 'none (will use current function / file)'
        \ : len(split(sel, "\n")) . ' lines selected'

  let lines = [
        \ '─────────────────────────────────',
        \ ' Claude Code Context Preview',
        \ '─────────────────────────────────',
        \ 'File path  : ' . file_path,
        \ 'Filetype   : ' . &filetype,
        \ 'Git root   : ' . (empty(git_root) ? 'not a git repo' : git_root),
        \ 'Selection  : ' . sel_info,
        \ 'Model      : ' . model,
        \ '─────────────────────────────────',
        \ 'Press q to close',
        \ ]

  call s:open_scratch('Claude: Context Preview', lines)
endfunction

" ─────────────────────────────────────────────
" 17. :Claude model
" Switch the active Claude model.
" Usage: :Claude model sonnet  |  :Claude model opus  |  :Claude model haiku
" ─────────────────────────────────────────────
function! claude_code#meta_commands#model(flags, ...) abort
  " Parse model name from flags string or extra args
  let model = trim(matchstr(a:flags, '\S\+'))
  if empty(model) && a:0 > 0
    let model = trim(a:1)
  endif

  if empty(model)
    " Interactive picker
    let choices = ['1. claude-opus-4-6   (most capable)', '2. claude-sonnet-4-6 (balanced, default)', '3. claude-haiku-4-5  (fastest)']
    let choice  = inputlist(['Select model:'] + choices)
    if choice == 1
      let model = 'claude-opus-4-6'
    elseif choice == 2
      let model = 'claude-sonnet-4-6'
    elseif choice == 3
      let model = 'claude-haiku-4-5-20251001'
    else
      echo 'Cancelled.'
      return
    endif
  else
    " Accept shorthand aliases
    let aliases = {
          \ 'opus':   'claude-opus-4-6',
          \ 'sonnet': 'claude-sonnet-4-6',
          \ 'haiku':  'claude-haiku-4-5-20251001',
          \ }
    let model = get(aliases, tolower(model), model)
  endif

  call claude_code#config#set('model', model)

  " Notify the terminal if running
  let term_buf = claude_code#terminal_bridge#get_buf()
  if term_buf >= 0
    call term_sendkeys(term_buf, '/model ' . model . "\n")
  endif

  echo 'claude-code: model set to ' . model
        \ . (term_buf >= 0 ? ' (notified terminal)' : ' (takes effect on next session)')
endfunction

" ─────────────────────────────────────────────
" Helpers (duplicated here to avoid cross-autoload coupling)
" ─────────────────────────────────────────────
function! s:get_visual_selection() abort
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  if lnum1 == 0 || lnum1 > lnum2
    return ''
  endif
  let lines = getline(lnum1, lnum2)
  if empty(lines) | return '' | endif
  let lines[-1] = lines[-1][: col2 - (&selection ==# 'inclusive' ? 1 : 2)]
  let lines[0]  = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction

function! s:open_scratch(title, lines) abort
  botright split
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  setlocal filetype=text
  silent! execute 'file ' . escape(a:title, ' ')
  call setline(1, a:lines)
  setlocal nomodifiable
  nnoremap <buffer> q :close<CR>
endfunction

function! s:send_to_terminal(prompt) abort
  call claude_code#terminal_bridge#send(a:prompt)
endfunction
