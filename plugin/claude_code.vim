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

let g:claude_code_version = "1.2.0"
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
        \ 'preview',
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
  elseif l:sub ==# 'preview'
    call s:dispatch_preview(l:flags)
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
  let s:map_extended_prefix = claude_code#config#get('map_extended_prefix')
  " Normal mode
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'e  :Claude explain<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'f  :Claude fix<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'r  :Claude refactor<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 't  :Claude test<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'd  :Claude doc<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'G  :Claude commit<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'R  :Claude review<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'p  :Claude pr<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'P  :Claude plan<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'a  :Claude analyze<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'n  :Claude rename<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'o  :Claude optimize<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'D  :Claude debug<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'A  :Claude apply<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'c  :Claude chat<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'x  :Claude context<CR>'
  execute 'nnoremap <silent> ' . s:map_extended_prefix . 'm  :Claude model<CR>'

  " Visual mode
  execute 'xnoremap <silent> ' . s:map_extended_prefix . 'e  :<C-u>Claude explain<CR>'
  execute 'xnoremap <silent> ' . s:map_extended_prefix . 'f  :<C-u>Claude fix<CR>'
  execute 'xnoremap <silent> ' . s:map_extended_prefix . 'r  :<C-u>Claude refactor<CR>'
  execute 'xnoremap <silent> ' . s:map_extended_prefix . 't  :<C-u>Claude test<CR>'
  execute 'xnoremap <silent> ' . s:map_extended_prefix . 'd  :<C-u>Claude doc<CR>'
  execute 'xnoremap <silent> ' . s:map_extended_prefix . 'n  :<C-u>Claude rename<CR>'
  execute 'xnoremap <silent> ' . s:map_extended_prefix . 'o  :<C-u>Claude optimize<CR>'
endif

" ---------------------------------------------------------------------------
" :Claude preview — diff preview sub-commands
" ---------------------------------------------------------------------------

function! s:dispatch_preview(flags) abort
  let l:sub = trim(a:flags)

  if l:sub ==# 'install' || l:sub ==# ''
    call claude_code#diff#install_hooks()
  elseif l:sub ==# 'uninstall'
    call claude_code#diff#uninstall_hooks()
  elseif l:sub ==# 'close'
    call claude_code#diff#close()
  elseif l:sub ==# 'status'
    call s:preview_status()
  else
    call claude_code#util#error('claude-code: unknown preview command "' . l:sub . '". Try: install, uninstall, close, status')
  endif
endfunction

function! s:preview_status() abort
  let l:lines = [
        \ '──────────────────────────────────',
        \ ' Claude Code — Diff Preview Status',
        \ '──────────────────────────────────',
        \ 'Polling : ' . (claude_code#diff#is_polling() ? 'active' : 'inactive'),
        \ 'Diff tab: ' . (claude_code#diff#is_open() ? 'open' : 'closed'),
        \ '',
        \ 'Dependencies:',
        \ ]
  call extend(l:lines, claude_code#diff#check_deps())
  call add(l:lines, '──────────────────────────────────')
  call add(l:lines, 'Press q to close')
  call claude_code#util#open_scratch('Claude: Preview Status', l:lines)
endfunction

" Auto-start polling if diff_preview is enabled
if claude_code#config#get('diff_preview')
  call claude_code#diff#start_polling()
endif
