" autoload/claude_code/commands.vim
" Core code intelligence commands: explain, fix, refactor, test, doc

" ─────────────────────────────────────────────
" Helpers
" ─────────────────────────────────────────────

" Return visually selected text (empty string if none)
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

" Detect the current function/method body around the cursor.
" Returns the function text, or the whole file as fallback.
function! s:get_current_function() abort
  let start = line('.')
  " Walk up to find a function start heuristic (works for most languages)
  let func_start = start
  while func_start > 1
    let ln = getline(func_start)
    if ln =~# '\v(function|def |func |fn |sub |method|class )'
      break
    endif
    let func_start -= 1
  endwhile

  " Find matching end (walk forward up to 200 lines)
  let func_end = func_start
  let max_end  = min([line('$'), func_start + 200])
  while func_end < max_end
    let func_end += 1
    let ln = getline(func_end)
    " Stop at a blank line after content or next top-level def
    if func_end > func_start + 2 && ln =~# '\v^(function|def |func |fn |class )'
      let func_end -= 1
      break
    endif
  endwhile

  let lines = getline(func_start, func_end)
  return empty(lines) ? join(getline(1, '$'), "\n") : join(lines, "\n")
endfunction

" Open a scratch buffer (split or float based on config) and put text in it.
function! s:open_output_window(title, content) abort
  let pos = claude_code#config#get('output_position', 'bottom')

  if pos ==# 'float' && has('popupwin')
    let width  = float2nr(&columns * claude_code#config#get('float_width', 0.8))
    let height = float2nr(&lines   * claude_code#config#get('float_height', 0.8))
    let col    = float2nr((&columns - width)  / 2)
    let row    = float2nr((&lines   - height) / 2)
    let winid = popup_create([], {
          \ 'title':    ' ' . a:title . ' ',
          \ 'border':   [1,1,1,1],
          \ 'minwidth':  width,
          \ 'maxwidth':  width,
          \ 'minheight': height,
          \ 'maxheight': height,
          \ 'col': col,
          \ 'line': row,
          \ 'wrap': 1,
          \ 'scrollbar': 1,
          \ 'mapping': 0,
          \ })
    call setbufline(winbufnr(winid), 1, split(a:content, "\n"))
    call popup_show(winid)
    return
  endif

  " Scratch split
  if pos ==# 'right'
    vsplit
    wincmd l
  elseif pos ==# 'left'
    vsplit
    wincmd h
  elseif pos ==# 'top'
    topleft split
  else
    botright split
  endif

  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  setlocal filetype=markdown
  let b:claude_output_win = 1
  silent! execute 'file ' . escape(a:title, ' ')
  call setline(1, split(a:content, "\n"))
  setlocal nomodifiable
  nnoremap <buffer> q :close<CR>
endfunction

" Send a prompt to the Claude Code terminal (uses the active terminal session).
" The prompt is injected as keyboard input into the terminal buffer.
function! s:send_to_terminal(prompt) abort
  call claude_code#terminal_bridge#send(a:prompt)
endfunction

" Build a context header for the current file
function! s:file_context() abort
  let path = expand('%:p')
  let ft   = &filetype
  return printf("File: %s\nFiletype: %s\n", path, ft)
endfunction

" ─────────────────────────────────────────────
" 1. :Claude explain
" ─────────────────────────────────────────────
function! claude_code#commands#explain(flags, ...) abort
  let sel  = s:get_visual_selection()
  let code = empty(sel) ? s:get_current_function() : sel
  let ctx  = s:file_context()

  if a:flags =~# '--brief'
    let detail = 'Give a very brief (2-3 sentence) explanation.'
  elseif a:flags =~# '--detailed'
    let detail = 'Give a thorough, detailed explanation including edge cases.'
  else
    let detail = 'Give a clear explanation.'
  endif

  let prompt = ctx
        \ . "\n" . detail
        \ . "\n\nCode to explain:\n```\n" . code . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" 2. :Claude fix
" ─────────────────────────────────────────────
function! claude_code#commands#fix(flags, ...) abort
  let sel  = s:get_visual_selection()
  let code = empty(sel) ? s:get_current_function() : sel
  let ctx  = s:file_context()

  let mode_hint = ''
  if a:flags =~# '--safe'
    let mode_hint = 'Use minimal, safe changes only.'
  endif

  let apply_hint = a:flags =~# '--apply'
        \ ? 'Apply the fix directly in the file without asking.'
        \ : 'Show a diff preview before applying.'

  let prompt = ctx
        \ . "\nTask: Fix any bugs or correctness issues in the following code. "
        \ . mode_hint . ' ' . apply_hint
        \ . "\n\n```\n" . code . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" 3. :Claude refactor
" ─────────────────────────────────────────────
function! claude_code#commands#refactor(flags, ...) abort
  let sel  = s:get_visual_selection()
  let code = empty(sel) ? s:get_current_function() : sel
  let ctx  = s:file_context()

  let strategy = 'Refactor for clarity and structure.'
  if a:flags =~# '--extract'
    let strategy = 'Extract reusable helpers or sub-functions.'
  elseif a:flags =~# '--simplify'
    let strategy = 'Simplify and reduce complexity.'
  elseif a:flags =~# '--optimize'
    let strategy = 'Optimize for performance and efficiency.'
  elseif a:flags =~# '--rename'
    let strategy = 'Suggest better, more descriptive names for variables and functions.'
  endif

  let prompt = ctx
        \ . "\nTask: " . strategy
        \ . "\n\n```\n" . code . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" 4. :Claude test
" ─────────────────────────────────────────────
function! claude_code#commands#test(flags, ...) abort
  let sel  = s:get_visual_selection()
  let code = empty(sel) ? s:get_current_function() : sel
  let ctx  = s:file_context()

  " Framework detection
  let fw = ''
  if a:flags =~# '--framework'
    let fw = matchstr(a:flags, '--framework\s\+\zs\S\+')
  endif
  if empty(fw)
    " Auto-detect from filetype
    let ft = &filetype
    let fw = get({
          \ 'python':     'pytest',
          \ 'javascript': 'jest',
          \ 'typescript': 'jest',
          \ 'go':         'go-test',
          \ 'ruby':       'rspec',
          \ 'rust':       'cargo-test',
          \ 'java':       'junit',
          \ }, ft, '')
  endif

  let fw_hint    = empty(fw) ? '' : 'Use the ' . fw . ' testing framework.'
  let edge_hint  = a:flags =~# '--edge-cases'
        \ ? ' Include edge cases and boundary conditions.'
        \ : ''

  let prompt = ctx
        \ . "\nTask: Generate unit tests for the following code. "
        \ . fw_hint . edge_hint
        \ . "\n\n```\n" . code . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" 5. :Claude doc
" ─────────────────────────────────────────────
function! claude_code#commands#doc(flags, ...) abort
  let sel  = s:get_visual_selection()
  let code = empty(sel) ? s:get_current_function() : sel
  let ctx  = s:file_context()

  if a:flags =~# '--markdown'
    let style = 'Generate Markdown documentation.'
  elseif a:flags =~# '--inline'
    let style = 'Add inline comments and docstrings directly in the code.'
  else
    let style = 'Generate appropriate docstrings/documentation comments.'
  endif

  let prompt = ctx
        \ . "\nTask: " . style
        \ . "\n\n```\n" . code . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction
