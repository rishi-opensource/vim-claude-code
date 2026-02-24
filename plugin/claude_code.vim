" plugin/claude_code.vim - Claude Code CLI integration for Vim
" Maintainer: Claude Code Vim Plugin
" License: MIT
" Requires: Vim 8.0+ with +terminal

" ---------------------------------------------------------------------------
" Version guard — must come first
" ---------------------------------------------------------------------------

if v:version < 800
  echoerr "vim-claude-code requires Vim 8.0+"
  finish
endif

if exists('g:loaded_claude_code')
  finish
endif
let g:loaded_claude_code = 1

" ---------------------------------------------------------------------------
" Plugin constants
" ---------------------------------------------------------------------------

let g:claude_code_version = "1.1.0"
" Initialise debug flag from user config (defaults to 0 via config.vim).
" We use get() here so it works even before config.vim is autoloaded.
let g:claude_code_debug = get(g:, 'claude_code_debug', 0)

if !has('terminal')
  call claude_code#util#error('vim-claude-code: requires Vim 8.0+ compiled with +terminal support')
  finish
endif

" ---------------------------------------------------------------------------
" Single :Claude command — dispatches all sub-commands
" ---------------------------------------------------------------------------

function! s:complete(ArgLead, CmdLine, CursorPos) abort
  let l:subs = [
        \ 'continue', 'resume', 'verbose',
        \ 'explain', 'fix', 'refactor', 'test', 'doc',
        \ 'commit', 'review', 'pr',
        \ 'plan', 'analyze',
        \ 'rename', 'optimize', 'debug', 'apply',
        \ 'chat', 'context', 'model',
        \ 'version', 'doctor',
        \ ]
  return filter(copy(l:subs), 'v:val =~# "^" . a:ArgLead')
endfunction

command! -nargs=* -range=% -complete=customlist,<SID>complete Claude
      \ call s:dispatch(<q-args>)

function! s:dispatch(args) abort
  let l:parts = split(a:args)
  let l:sub   = get(l:parts, 0, '')
  let l:flags = len(l:parts) > 1 ? join(l:parts[1:]) : ''

  call claude_code#util#debug('dispatch: sub=' . l:sub . ' flags=' . l:flags)

  if l:sub ==# ''
    call claude_code#terminal#toggle()
  elseif l:sub ==# 'continue'
    call claude_code#terminal#toggle('continue')
  elseif l:sub ==# 'resume'
    call claude_code#terminal#toggle('resume')
  elseif l:sub ==# 'verbose'
    call claude_code#terminal#toggle('verbose')
  elseif l:sub ==# 'explain'
    call claude_code#commands#explain(l:flags)
  elseif l:sub ==# 'fix'
    call claude_code#commands#fix(l:flags)
  elseif l:sub ==# 'refactor'
    call claude_code#commands#refactor(l:flags)
  elseif l:sub ==# 'test'
    call claude_code#commands#test(l:flags)
  elseif l:sub ==# 'doc'
    call claude_code#commands#doc(l:flags)
  elseif l:sub ==# 'commit'
    call claude_code#git_commands#commit(l:flags)
  elseif l:sub ==# 'review'
    call claude_code#git_commands#review(l:flags)
  elseif l:sub ==# 'pr'
    call claude_code#git_commands#pr(l:flags)
  elseif l:sub ==# 'plan'
    call claude_code#arch_commands#plan(l:flags)
  elseif l:sub ==# 'analyze'
    call claude_code#arch_commands#analyze(l:flags)
  elseif l:sub ==# 'rename'
    call claude_code#workflow_commands#rename(l:flags)
  elseif l:sub ==# 'optimize'
    call claude_code#workflow_commands#optimize(l:flags)
  elseif l:sub ==# 'debug'
    call claude_code#workflow_commands#debug(l:flags)
  elseif l:sub ==# 'apply'
    call claude_code#workflow_commands#apply(l:flags)
  elseif l:sub ==# 'chat'
    call claude_code#meta_commands#chat(l:flags)
  elseif l:sub ==# 'context'
    call claude_code#meta_commands#context(l:flags)
  elseif l:sub ==# 'model'
    call claude_code#meta_commands#model(l:flags)
  elseif l:sub ==# 'version'
    call claude_code#meta_commands#version()
  elseif l:sub ==# 'doctor'
    call claude_code#meta_commands#doctor()
  else
    call claude_code#util#error('vim-claude-code: unknown sub-command "' . l:sub . '". Try :Claude <Tab>')
  endif
endfunction

" ---------------------------------------------------------------------------
" Default keymaps
" ---------------------------------------------------------------------------

if claude_code#config#get('map_keys')
  let s:toggle_key = claude_code#config#get('map_toggle')
  if !empty(s:toggle_key)
    execute 'nnoremap <silent> ' . s:toggle_key . ' :Claude<CR>'
    execute 'tnoremap <silent> ' . s:toggle_key . ' <C-\><C-n>:Claude<CR>'
  endif

  let s:cont_key = claude_code#config#get('map_continue')
  if !empty(s:cont_key)
    execute 'nnoremap <silent> ' . s:cont_key . ' :Claude continue<CR>'
  endif

  let s:verbose_key = claude_code#config#get('map_verbose')
  if !empty(s:verbose_key)
    execute 'nnoremap <silent> ' . s:verbose_key . ' :Claude verbose<CR>'
  endif
endif

if claude_code#config#get('map_extended_keys')
  " Normal mode
  nnoremap <silent> <Leader>ce  :Claude explain<CR>
  nnoremap <silent> <Leader>cf  :Claude fix<CR>
  nnoremap <silent> <Leader>cr  :Claude refactor<CR>
  nnoremap <silent> <Leader>ct  :Claude test<CR>
  nnoremap <silent> <Leader>cd  :Claude doc<CR>
  nnoremap <silent> <Leader>cG  :Claude commit<CR>
  nnoremap <silent> <Leader>cR  :Claude review<CR>
  nnoremap <silent> <Leader>cp  :Claude pr<CR>
  nnoremap <silent> <Leader>cP  :Claude plan<CR>
  nnoremap <silent> <Leader>ca  :Claude analyze<CR>
  nnoremap <silent> <Leader>cn  :Claude rename<CR>
  nnoremap <silent> <Leader>co  :Claude optimize<CR>
  nnoremap <silent> <Leader>cD  :Claude debug<CR>
  nnoremap <silent> <Leader>cA  :Claude apply<CR>
  nnoremap <silent> <Leader>cc  :Claude chat<CR>
  nnoremap <silent> <Leader>cx  :Claude context<CR>
  nnoremap <silent> <Leader>cm  :Claude model<CR>

  " Visual mode
  xnoremap <silent> <Leader>ce  :<C-u>Claude explain<CR>
  xnoremap <silent> <Leader>cf  :<C-u>Claude fix<CR>
  xnoremap <silent> <Leader>cr  :<C-u>Claude refactor<CR>
  xnoremap <silent> <Leader>ct  :<C-u>Claude test<CR>
  xnoremap <silent> <Leader>cd  :<C-u>Claude doc<CR>
  xnoremap <silent> <Leader>cn  :<C-u>Claude rename<CR>
  xnoremap <silent> <Leader>co  :<C-u>Claude optimize<CR>
endif
