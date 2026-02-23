" autoload/claude_code/arch_commands.vim
" Architecture and planning commands: plan, analyze
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_arch_commands')
  finish
endif
let g:autoloaded_claude_code_arch_commands = 1

" 9. :Claude plan
function! claude_code#arch_commands#plan(flags) abort
  let l:ctx     = claude_code#util#file_context()
  let l:content = join(getline(1, '$'), "\n")

  call claude_code#terminal_bridge#send(
        \ l:ctx .
        \ "\nTask: Generate a detailed implementation plan. " .
        \ "Break into phases, list dependencies, flag potential risks." .
        \ "\n\nFile content:\n```\n" . l:content . "\n```\n")
endfunction

" 10. :Claude analyze
function! claude_code#arch_commands#analyze(flags) abort
  let l:ctx     = claude_code#util#file_context()
  let l:content = join(getline(1, '$'), "\n")

  call claude_code#terminal_bridge#send(
        \ l:ctx .
        \ "\nTask: Analyze this file. Format with sections: " .
        \ "## Complexity, ## Performance, ## Security." .
        \ "\n\nFile content:\n```\n" . l:content . "\n```\n")
endfunction
