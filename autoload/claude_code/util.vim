" autoload/claude_code/util.vim
" Shared helper utilities used across command modules.
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_util')
  finish
endif
let g:autoloaded_claude_code_util = 1

" Return visually selected text, or empty string if no selection active.
function! claude_code#util#visual_selection() abort
  let [l:lnum1, l:col1] = getpos("'<")[1:2]
  let [l:lnum2, l:col2] = getpos("'>")[1:2]
  if l:lnum1 == 0 || l:lnum1 > l:lnum2
    return ''
  endif
  let l:lines = getline(l:lnum1, l:lnum2)
  if empty(l:lines)
    return ''
  endif
  let l:lines[-1] = l:lines[-1][: l:col2 - (&selection ==# 'inclusive' ? 1 : 2)]
  let l:lines[0]  = l:lines[0][l:col1 - 1:]
  return join(l:lines, "\n")
endfunction

" Detect the function/method body surrounding the cursor.
" Walks upward for a keyword line, then forward up to 200 lines.
" Falls back to the whole file if nothing is found.
function! claude_code#util#current_function() abort
  let l:cursor = line('.')
  let l:start  = l:cursor

  " Walk up to find a function-start line.
  while l:start > 1
    if getline(l:start) =~# '\v(function|def |func |fn |sub |method|class )'
      break
    endif
    let l:start -= 1
  endwhile

  " Walk forward to find the end (next top-level keyword or 200-line cap).
  let l:end    = l:start
  let l:max    = min([line('$'), l:start + 200])
  while l:end < l:max
    let l:end += 1
    if l:end > l:start + 2
          \ && getline(l:end) =~# '\v^(function|def |func |fn |class )'
      let l:end -= 1
      break
    endif
  endwhile

  let l:lines = getline(l:start, l:end)
  return empty(l:lines) ? join(getline(1, '$'), "\n") : join(l:lines, "\n")
endfunction

" Return a context header for the current buffer.
function! claude_code#util#file_context() abort
  return printf("File: %s\nFiletype: %s\n", expand('%:p'), &filetype)
endfunction

" Open a read-only scratch split. Press q to close.
function! claude_code#util#open_scratch(title, lines) abort
  botright split
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted filetype=text
  silent! execute 'file ' . escape(a:title, ' ')
  call setline(1, a:lines)
  setlocal nomodifiable
  nnoremap <buffer> <silent> q :close<CR>
endfunction
