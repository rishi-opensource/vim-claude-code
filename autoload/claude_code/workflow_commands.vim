" autoload/claude_code/workflow_commands.vim
" Productivity commands: rename, optimize, debug, apply
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_workflow_commands')
  finish
endif
let g:autoloaded_claude_code_workflow_commands = 1

" 11. :Claude rename
function! claude_code#workflow_commands#rename(flags) abort
  let l:code = s:code_target()
  let l:ctx  = claude_code#util#file_context()

  call claude_code#terminal_bridge#send(
        \ l:ctx .
        \ "\nTask: Suggest better, more descriptive and idiomatic names. " .
        \ "List old → new mappings." .
        \ "\n\n```\n" . l:code . "\n```\n")
endfunction

" 12. :Claude optimize
function! claude_code#workflow_commands#optimize(flags) abort
  let l:code = s:code_target()
  let l:ctx  = claude_code#util#file_context()

  call claude_code#terminal_bridge#send(
        \ l:ctx .
        \ "\nTask: Optimize for performance. " .
        \ "Explain each optimization with a brief comment." .
        \ "\n\n```\n" . l:code . "\n```\n")
endfunction

" 13. :Claude debug
function! claude_code#workflow_commands#debug(flags) abort
  let l:ctx       = claude_code#util#file_context()
  let l:lnum      = line('.')
  let l:error_ln  = getline(l:lnum)
  let l:ctx_start = max([1, l:lnum - 10])
  let l:ctx_end   = min([line('$'), l:lnum + 10])
  let l:surround  = join(getline(l:ctx_start, l:ctx_end), "\n")

  call claude_code#terminal_bridge#send(
        \ l:ctx .
        \ "\nTask: Analyze this error and explain the root cause and fix." .
        \ "\n\nError line " . l:lnum . ":\n  " . trim(l:error_ln) .
        \ "\n\nContext:\n```\n" . l:surround . "\n```\n")
endfunction

" 15. :Claude apply
function! claude_code#workflow_commands#apply(flags) abort
  if !claude_code#util#confirm('Apply changes to file ' . expand('%:t') . '?')
    echomsg 'vim-claude-code: apply cancelled'
    return
  endif
  call claude_code#util#debug('workflow_commands: apply confirmed for ' . expand('%:p'))
  call claude_code#terminal_bridge#send(
        \ claude_code#util#file_context() .
        \ "\nTask: Apply the last code suggestion you made to this file. " .
        \ "Write the complete updated file content and save it.")
endfunction

" ---------------------------------------------------------------------------
" Private helpers
" ---------------------------------------------------------------------------

function! s:code_target() abort
  let l:sel = claude_code#util#visual_selection()
  return empty(l:sel) ? claude_code#util#current_function() : l:sel
endfunction
