" plugin/claude_code_commands.vim
" Extended :Claude sub-commands (loaded alongside the original plugin).
" Adds commands 1-17 from the vim-claude-code extended spec.

if exists('g:loaded_claude_code_commands') | finish | endif
let g:loaded_claude_code_commands = 1

" ─────────────────────────────────────────────────────────────────────────────
" Dispatcher — extend the existing :Claude command
"
" Usage examples:
"   :Claude explain
"   :Claude explain --brief
"   :'<,'>Claude fix --safe
"   :Claude commit --conventional
"   :Claude model sonnet
" ─────────────────────────────────────────────────────────────────────────────

" We redefine :Claude with -complete so we can tab-complete sub-commands.
" The original plugin's :Claude is for the terminal toggle; we chain to it
" for the original sub-commands (continue / resume / verbose).

if exists(':Claude') == 2
  delcommand Claude
endif

function! s:complete_claude(ArgLead, CmdLine, CursorPos) abort
  let subcmds = [
        \ 'explain', 'fix', 'refactor', 'test', 'doc',
        \ 'commit', 'review', 'pr',
        \ 'plan', 'analyze',
        \ 'rename', 'optimize', 'debug',
        \ 'chat', 'apply',
        \ 'context', 'model',
        \ 'continue', 'resume', 'verbose',
        \ ]
  return filter(copy(subcmds), 'v:val =~# "^" . a:ArgLead')
endfunction

command! -nargs=* -range -complete=customlist,s:complete_claude Claude
      \ call s:dispatch_claude(<q-args>)

function! s:dispatch_claude(args) abort
  let parts = split(a:args)
  if empty(parts)
    " No sub-command → toggle terminal (original behaviour)
    call claude_code#terminal#toggle('')
    return
  endif

  let sub   = parts[0]
  let flags = len(parts) > 1 ? join(parts[1:]) : ''

  " ── Original commands (delegate to terminal module) ──────────────────────
  if sub ==# 'continue'
    call claude_code#terminal#toggle('--continue')
  elseif sub ==# 'resume'
    call claude_code#terminal#toggle('--resume')
  elseif sub ==# 'verbose'
    call claude_code#terminal#toggle('--verbose')

  " ── Core code intelligence ────────────────────────────────────────────────
  elseif sub ==# 'explain'
    call claude_code#commands#explain(flags)
  elseif sub ==# 'fix'
    call claude_code#commands#fix(flags)
  elseif sub ==# 'refactor'
    call claude_code#commands#refactor(flags)
  elseif sub ==# 'test'
    call claude_code#commands#test(flags)
  elseif sub ==# 'doc'
    call claude_code#commands#doc(flags)

  " ── Git-aware ─────────────────────────────────────────────────────────────
  elseif sub ==# 'commit'
    call claude_code#git_commands#commit(flags)
  elseif sub ==# 'review'
    call claude_code#git_commands#review(flags)
  elseif sub ==# 'pr'
    call claude_code#git_commands#pr(flags)

  " ── Architecture / planning ───────────────────────────────────────────────
  elseif sub ==# 'plan'
    call claude_code#arch_commands#plan(flags)
  elseif sub ==# 'analyze'
    call claude_code#arch_commands#analyze(flags)

  " ── Productivity / workflow ───────────────────────────────────────────────
  elseif sub ==# 'rename'
    call claude_code#workflow_commands#rename(flags)
  elseif sub ==# 'optimize'
    call claude_code#workflow_commands#optimize(flags)
  elseif sub ==# 'debug'
    call claude_code#workflow_commands#debug(flags)
  elseif sub ==# 'apply'
    call claude_code#workflow_commands#apply(flags)

  " ── Meta / control ────────────────────────────────────────────────────────
  elseif sub ==# 'chat'
    call claude_code#meta_commands#chat(flags)
  elseif sub ==# 'context'
    call claude_code#meta_commands#context(flags)
  elseif sub ==# 'model'
    call claude_code#meta_commands#model(flags)

  else
    echoerr 'claude-code: unknown sub-command "' . sub . '". Try :Claude <Tab>'
  endif
endfunction

" ─────────────────────────────────────────────────────────────────────────────
" Optional default keymaps for the most-used new commands
" (all under <Leader>c* prefix to match existing conventions)
" Disable with: let g:claude_code_map_extended_keys = 0
" ─────────────────────────────────────────────────────────────────────────────
if get(g:, 'claude_code_map_extended_keys', 1)
  " Normal mode
  nnoremap <Leader>ce  :Claude explain<CR>
  nnoremap <Leader>cf  :Claude fix<CR>
  nnoremap <Leader>cr  :Claude refactor<CR>
  nnoremap <Leader>ct  :Claude test<CR>
  nnoremap <Leader>cd  :Claude doc<CR>
  nnoremap <Leader>cG  :Claude commit<CR>
  nnoremap <Leader>cR  :Claude review<CR>
  nnoremap <Leader>cp  :Claude pr<CR>
  nnoremap <Leader>cP  :Claude plan<CR>
  nnoremap <Leader>ca  :Claude analyze<CR>
  nnoremap <Leader>cn  :Claude rename<CR>
  nnoremap <Leader>co  :Claude optimize<CR>
  nnoremap <Leader>cD  :Claude debug<CR>
  nnoremap <Leader>cA  :Claude apply<CR>
  nnoremap <Leader>cc  :Claude chat<CR>
  nnoremap <Leader>cx  :Claude context<CR>
  nnoremap <Leader>cm  :Claude model<CR>

  " Visual mode (operate on selection)
  xnoremap <Leader>ce  :<C-u>Claude explain<CR>
  xnoremap <Leader>cf  :<C-u>Claude fix<CR>
  xnoremap <Leader>cr  :<C-u>Claude refactor<CR>
  xnoremap <Leader>ct  :<C-u>Claude test<CR>
  xnoremap <Leader>cd  :<C-u>Claude doc<CR>
  xnoremap <Leader>cn  :<C-u>Claude rename<CR>
  xnoremap <Leader>co  :<C-u>Claude optimize<CR>
endif
