" autoload/claude_code/git_commands.vim
" Git-aware commands: commit, review, pr

" Run a shell command and return its stdout (trimmed).
function! s:shell(cmd) abort
  return system(a:cmd)
endfunction

" ─────────────────────────────────────────────
" 6. :Claude commit
" ─────────────────────────────────────────────
function! claude_code#git_commands#commit(flags, ...) abort
  let diff = s:shell('git diff --staged 2>&1')
  if empty(trim(diff))
    echo 'claude-code: no staged changes found. Did you forget to git add?'
    return
  endif

  let style_hint = ''
  if a:flags =~# '--conventional'
    let style_hint = 'Format the commit message using Conventional Commits '
          \ . '(e.g. feat:, fix:, chore:, docs:, refactor:, test:).'
  endif
  let amend_hint = a:flags =~# '--amend'
        \ ? ' This will amend the previous commit.'
        \ : ''

  let prompt = "Task: Generate a concise, informative git commit message. "
        \ . style_hint . amend_hint
        \ . "\nOutput only the commit message (subject line + optional body), nothing else."
        \ . "\n\nStaged diff:\n```diff\n" . diff . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" 7. :Claude review
" ─────────────────────────────────────────────
function! claude_code#git_commands#review(flags, ...) abort
  let diff = s:shell('git diff 2>&1')
  if empty(trim(diff))
    " Fall back to HEAD diff
    let diff = s:shell('git diff HEAD 2>&1')
  endif
  if empty(trim(diff))
    echo 'claude-code: no diff found to review.'
    return
  endif

  let focus = 'Review for: bug risks, refactor opportunities, and performance notes.'
  if a:flags =~# '--security'
    let focus = 'Focus the review on security vulnerabilities, injection risks, and unsafe patterns.'
  elseif a:flags =~# '--strict'
    let focus = 'Perform a strict, exhaustive review covering correctness, style, security, and performance.'
  endif

  let prompt = "Task: Code review. " . focus
        \ . "\n\nDiff:\n```diff\n" . diff . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" 8. :Claude pr
" ─────────────────────────────────────────────
function! claude_code#git_commands#pr(flags, ...) abort
  let diff = s:shell('git diff origin/HEAD...HEAD 2>&1')
  if empty(trim(diff))
    let diff = s:shell('git diff HEAD~1 2>&1')
  endif
  if empty(trim(diff))
    echo 'claude-code: no diff found for PR description.'
    return
  endif

  let log = s:shell('git log origin/HEAD..HEAD --oneline 2>&1')

  let prompt = "Task: Generate a pull request description in Markdown. "
        \ . "Include a summary, motivation, and list of changes. "
        \ . "Use headers: ## Summary, ## Changes, ## Testing."
        \ . "\n\nRecent commits:\n```\n" . log . "\n```"
        \ . "\n\nDiff:\n```diff\n" . diff . "\n```\n"

  call s:send_to_terminal(prompt)
endfunction

" ─────────────────────────────────────────────
" Shared terminal sender (delegates to terminal module)
" ─────────────────────────────────────────────
function! s:send_to_terminal(prompt) abort
  call claude_code#terminal_bridge#send(a:prompt)
endfunction
