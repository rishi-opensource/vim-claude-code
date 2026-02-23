" autoload/claude_code/workflow_commands.vim
" Productivity commands: rename, optimize, debug, apply

function! s:get_visual_selection() abort
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  if lnum1 == 0 || lnum1 > lnum2
    return ''
  endif
  let lines = getline(lnum1, lnum2)
  if empty(lines)
    return ''
  endif
  let lines[-1] = lines[-1][: col2 - (&selection ==# 'inclusive' ? 1 : 2)]
  let lines[0]  = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction

function! s:get_current_function() abort
  let start = line('.')
  let func_start = start
  while func_start > 1
    let ln = getline(func_start)
    if ln =~# '\v(function|def |func |fn |sub |method|class )'
      break
    endif
    let func_start -= 1
  endwhile
  let func_end = func_start
  let max_end  = min([line('$'), func_start + 200])
  while func_end < max_end
    let func_end += 1
    if func_end > func_start + 2 && getline(func_end) =~# '\v^(function|def |func |fn |class )'
      let func_end -= 1
      break
    endif
  endwhile
  let lines = getline(func_start, func_end)
  return empty(lines) ? join(getline(1, '$'), "\n") : join(lines, "\n")
endfunction

function! s:file_context() abort
  return printf("File: %s\nFiletype: %s\n", expand('%:p'), &filetype)
endfunction

function! s:send_to_terminal(prompt) abort
  call claude_code#terminal_bridge#send(a:prompt)
endfunction

" ─────────────────────────────────────────────
" 11. :Claude rename
" ─────────────────────────────────────────────
function! claude_code#workflow_commands#rename(flags, ...) abort
  let sel  = s:get_visual_selection()
  let code = empty(sel) ? s:get_current_function() : sel
  let ctx  = s:file_context()

  let prompt = ctx
        \ . "\nTask: Suggest better, more descriptive and idiomatic names for the variables "
        \ . "and functions in the following code. List old → new mappings."
        \ . "\n\n```\n" . code . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" 12. :Claude optimize
" ─────────────────────────────────────────────
function! claude_code#workflow_commands#optimize(flags, ...) abort
  let sel  = s:get_visual_selection()
  let code = empty(sel) ? s:get_current_function() : sel
  let ctx  = s:file_context()

  let prompt = ctx
        \ . "\nTask: Optimize the following code for performance. "
        \ . "Explain each optimization with a brief comment."
        \ . "\n\n```\n" . code . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" 13. :Claude debug
" Extracts the error text under/near the cursor and sends it with context.
" ─────────────────────────────────────────────
function! claude_code#workflow_commands#debug(flags, ...) abort
  let ctx        = s:file_context()
  let error_line = getline('.')
  let cursor_ln  = line('.')

  " Grab surrounding 10 lines for context
  let start_ctx = max([1, cursor_ln - 10])
  let end_ctx   = min([line('$'), cursor_ln + 10])
  let surrounding = join(getline(start_ctx, end_ctx), "\n")

  let prompt = ctx
        \ . "\nTask: Analyze this error and explain the root cause and fix."
        \ . "\n\nError line (line " . cursor_ln . "):\n  " . trim(error_line)
        \ . "\n\nSurrounding code context:\n```\n" . surrounding . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" 15. :Claude apply
" Applies the last suggestion Claude made as a patch to the current buffer.
" ─────────────────────────────────────────────
function! claude_code#workflow_commands#apply(flags, ...) abort
  let ctx = s:file_context()
  let prompt = ctx
        \ . "\nTask: Apply the last code suggestion you made to the file above. "
        \ . "Write the complete updated file content, then use write_file to save it."

  call s:send_to_terminal(prompt)
endfunction
