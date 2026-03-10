vim9script

# autoload/claude_code/util.vim
# Shared helper utilities used across command modules.
# Maintainer: Claude Code Vim Plugin
# License: MIT

# ---------------------------------------------------------------------------
# Error / debug helpers
# ---------------------------------------------------------------------------

# Emit an error message using ErrorMsg highlight.
# Use this everywhere instead of raw echoerr / echohl blocks.
export def Error(msg: string)
  echohl ErrorMsg
  echomsg msg
  echohl None
enddef

# Emit a debug message when g:claude_code_debug is enabled.
export def Debug(msg: string)
  if g:->get('claude_code_debug', 0)
    echomsg '[claude-code debug] ' .. msg
  endif
enddef

# ---------------------------------------------------------------------------
# Selection / context helpers
# ---------------------------------------------------------------------------

# Return visually selected text, or empty string if no selection active.
export def VisualSelection(): string
  var pos1 = getpos("'<")
  var lnum1 = pos1[1]
  var col1 = pos1[2]
  var pos2 = getpos("'>")
  var lnum2 = pos2[1]
  var col2 = pos2[2]

  if lnum1 == 0 || lnum1 > lnum2
    return ''
  endif

  var lines = getline(lnum1, lnum2)
  if empty(lines)
    return ''
  endif

  var last_line_len = col2 - (&selection == 'inclusive' ? 1 : 2)
  lines[-1] = lines[-1][: last_line_len]
  lines[0] = lines[0][col1 - 1 :]

  return join(lines, "\n")
enddef

# Detect the function/method body surrounding the cursor.
# Walks upward for a keyword line, then forward up to 200 lines.
# Falls back to the whole file if nothing is found.
export def CurrentFunction(): string
  var cursor = line('.')
  var start = cursor

  # Walk up to find a function-start line.
  while start > 1
    if getline(start) =~# '\v(function|def |func |fn |sub |method|class )'
      break
    endif
    start -= 1
  endwhile

  # Walk forward to find the end (next top-level keyword or 200-line cap).
  var end = start
  var max = min([line('$'), start + 200])
  while end < max
    end += 1
    if end > start + 2 && getline(end) =~# '\v^(function|def |func |fn |class )'
      end -= 1
      break
    endif
  endwhile

  var lines = getline(start, end)
  return empty(lines) ? join(getline(1, '$'), "\n") : join(lines, "\n")
enddef

# Return a context header for the current buffer.
export def FileContext(): string
  return printf("File: %s\nFiletype: %s\n", expand('%:p'), &filetype)
enddef

# Open a read-only scratch split. Press q to close.
export def OpenScratch(title: string, lines: list<string>)
  botright split
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted filetype=text
  silent! execute 'file ' .. escape(title, ' ')
  setline(1, lines)
  setlocal nomodifiable
  nnoremap <buffer> <silent> q :close<CR>
enddef

# Prompt the user with a yes/no question. Returns 1 for yes, 0 for no.
export def Confirm(prompt: string): bool
  var ans = input(prompt .. ' (y/n): ')
  return ans =~? '^y'
enddef

# Return visual selection if active, otherwise current function body.
# Shared helper used by commands.vim and workflow_commands.vim.
export def CodeTarget(): string
  var sel = VisualSelection()
  return empty(sel) ? CurrentFunction() : sel
enddef

