" autoload/claude_code/git_commands.vim
" Git-aware commands: commit, review, pr
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_git_commands')
  finish
endif
let g:autoloaded_claude_code_git_commands = 1

" 6. :Claude commit
function! claude_code#git_commands#commit(flags) abort
  let l:diff = system('git diff --staged 2>&1')
  if empty(trim(l:diff))
    echohl WarningMsg
    echomsg 'claude-code: no staged changes. Did you forget to git add?'
    echohl None
    return
  endif

  let l:style = a:flags =~# '--conventional'
        \ ? 'Use Conventional Commits format (feat:, fix:, chore:, docs:, refactor:, test:).'
        \ : ''
  let l:amend = a:flags =~# '--amend' ? ' This amends the previous commit.' : ''

  call claude_code#terminal_bridge#send(
        \ "Task: Generate a concise git commit message. " . l:style . l:amend .
        \ "\nOutput only the commit message (subject + optional body), nothing else." .
        \ "\n\nStaged diff:\n```diff\n" . l:diff . "\n```\n")
endfunction

" 7. :Claude review
function! claude_code#git_commands#review(flags) abort
  let l:diff = system('git diff 2>&1')
  if empty(trim(l:diff))
    let l:diff = system('git diff HEAD 2>&1')
  endif
  if empty(trim(l:diff))
    echohl WarningMsg
    echomsg 'claude-code: no diff found to review.'
    echohl None
    return
  endif

  if a:flags =~# '--security'
    let l:focus = 'Focus on security vulnerabilities, injection risks, and unsafe patterns.'
  elseif a:flags =~# '--strict'
    let l:focus = 'Strict exhaustive review: correctness, style, security, and performance.'
  else
    let l:focus = 'Review for: bug risks, refactor opportunities, and performance notes.'
  endif

  call claude_code#terminal_bridge#send(
        \ "Task: Code review. " . l:focus .
        \ "\n\nDiff:\n```diff\n" . l:diff . "\n```\n")
endfunction

" 8. :Claude pr
function! claude_code#git_commands#pr(flags) abort
  let l:diff = system('git diff origin/HEAD...HEAD 2>&1')
  if empty(trim(l:diff))
    let l:diff = system('git diff HEAD~1 2>&1')
  endif
  if empty(trim(l:diff))
    echohl WarningMsg
    echomsg 'claude-code: no diff found for PR description.'
    echohl None
    return
  endif

  let l:log = system('git log origin/HEAD..HEAD --oneline 2>&1')

  call claude_code#terminal_bridge#send(
        \ "Task: Generate a pull request description in Markdown. " .
        \ "Sections: ## Summary, ## Changes, ## Testing." .
        \ "\n\nCommits:\n```\n" . l:log . "\n```" .
        \ "\n\nDiff:\n```diff\n" . l:diff . "\n```\n")
endfunction
