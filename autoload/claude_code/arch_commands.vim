" autoload/claude_code/arch_commands.vim
" Architecture / planning commands: plan, analyze

function! s:file_context() abort
  return printf("File: %s\nFiletype: %s\n", expand('%:p'), &filetype)
endfunction

function! s:send_to_terminal(prompt) abort
  call claude_code#terminal_bridge#send(a:prompt)
endfunction

" ─────────────────────────────────────────────
" 9. :Claude plan
" ─────────────────────────────────────────────
function! claude_code#arch_commands#plan(flags, ...) abort
  let ctx      = s:file_context()
  let content  = join(getline(1, '$'), "\n")

  let prompt = ctx
        \ . "\nTask: Generate a detailed implementation plan for this file/feature. "
        \ . "Break it into phases, list dependencies, and flag potential risks."
        \ . "\n\nCurrent file content:\n```\n" . content . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" 10. :Claude analyze
" ─────────────────────────────────────────────
function! claude_code#arch_commands#analyze(flags, ...) abort
  let ctx     = s:file_context()
  let content = join(getline(1, '$'), "\n")

  let focus = 'Analyze for: cyclomatic complexity, performance bottlenecks, and security concerns. '
        \ . 'Format the report with sections: ## Complexity, ## Performance, ## Security.'

  let prompt = ctx
        \ . "\nTask: " . focus
        \ . "\n\nFile content:\n```\n" . content . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction
