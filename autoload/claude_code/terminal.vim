" claude_code/terminal.vim - Terminal buffer lifecycle management
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_terminal')
  finish
endif
let g:autoloaded_claude_code_terminal = 1

" Instance registry: instance_id -> bufnr
let s:instances = {}

" Temporary variant flag appended to the command for one toggle cycle.
let s:pending_variant = ''

" ---------------------------------------------------------------------------
" Public API
" ---------------------------------------------------------------------------

" Toggle the Claude Code terminal, optionally with a subcommand variant.
" If a terminal for the current instance exists and is visible, hide it.
" If it exists but is hidden, show it. Otherwise create a new one.
" When a variant name is given (e.g. 'continue'), the corresponding CLI
" flag is appended on first creation only.
function! claude_code#terminal#toggle(...) abort
  let l:variant_name = a:0 ? a:1 : ''
  call claude_code#util#debug('terminal#toggle variant=' . l:variant_name)

  " Resolve variant flag when a subcommand is provided.
  if !empty(l:variant_name)
    let l:flag = claude_code#config#get('variant_' . l:variant_name)
    if type(l:flag) != v:t_string || empty(l:flag)
      call claude_code#util#error('claude-code: unknown subcommand "' . l:variant_name . '"')
      return
    endif
  else
    let l:flag = ''
  endif

  let l:id = s:get_instance_id()
  let l:bufnr = get(s:instances, l:id, -1)

  if l:bufnr > 0 && s:is_valid(l:bufnr)
    if s:is_visible(l:bufnr)
      call claude_code#window#close_buf_windows(l:bufnr)
    else
      call s:show_existing(l:bufnr)
    endif
  else
    if !empty(l:flag)
      let s:pending_variant = l:flag
    endif
    call s:create_new(l:id)
    let s:pending_variant = ''
  endif
endfunction

" Toggle the zoomed (maximized) state of the current Claude terminal.
" Uses a temporary tab to provide a full-screen view without losing context.
function! claude_code#terminal#zoom() abort
  if get(t:, 'claude_code_zoomed', 0)
    " We are in a zoomed tab, so just close it to return.
    tabclose
    return
  endif

  let l:bufnr = bufnr('%')
  let l:id = s:get_instance_id()
  let l:instance_buf = get(s:instances, l:id, -1)

  if l:bufnr != l:instance_buf
    " If we are not in the terminal window, try to jump to it first.
    if l:instance_buf > 0 && s:is_valid(l:instance_buf)
      let l:win_ids = win_findbuf(l:instance_buf)
      if !empty(l:win_ids)
        call win_gotoid(l:win_ids[0])
        let l:bufnr = l:instance_buf
      else
        " It's hidden, show it first normally.
        call s:show_existing(l:instance_buf)
        let l:bufnr = l:instance_buf
      endif
    endif
  endif

  if l:bufnr > 0 && s:is_valid(l:bufnr)
    " Maximize by opening the buffer in a new tab.
    execute 'tab split'
    let t:claude_code_zoomed = 1
    call s:configure_term_window()
    " Ensure we stay in terminal mode if inserts are enabled.
    if claude_code#config#get('enter_insert')
      if mode() !=# 't'
        silent! normal! i
      endif
    endif
  else
    call claude_code#util#error('claude-code: no active terminal to zoom')
  endif
endfunction

" ---------------------------------------------------------------------------
" Internal helpers
" ---------------------------------------------------------------------------

" Determine the instance identifier.
" In multi-instance mode this is the git root (or cwd as fallback).
" In single-instance mode it is the fixed string 'global'.
function! s:get_instance_id() abort
  if !claude_code#config#get('multi_instance')
    return 'global'
  endif
  if claude_code#config#get('use_git_root')
    let l:root = claude_code#git#root()
    if !empty(l:root)
      return l:root
    endif
  endif
  return getcwd()
endfunction

" Build the shell command to execute.
function! s:build_command(instance_id) abort
  let l:cmd = claude_code#config#get('command')

  " Append --model when the user has configured one.
  let l:model = claude_code#config#get('model')
  if !empty(l:model)
    let l:cmd .= ' --model ' . shellescape(l:model)
  endif

  " Append pending variant flag.
  if !empty(s:pending_variant)
    let l:cmd .= ' ' . s:pending_variant
  endif

  return l:cmd
endfunction

" Resolve the working directory for a terminal instance.
" Returns the instance_id path (normalised for the OS) when it differs from
" cwd, or an empty string when no directory change is needed.
function! s:instance_cwd(instance_id) abort
  if !claude_code#config#get('use_git_root') || a:instance_id ==# 'global'
    return ''
  endif
  " Normalise both sides to forward slashes for a reliable comparison.
  let l:inst = substitute(a:instance_id, '\\', '/', 'g')
  let l:cwd  = substitute(getcwd(),      '\\', '/', 'g')
  if l:inst ==# l:cwd
    return ''
  endif
  " Return an OS-native path so term_start's cwd option works on all platforms.
  if has('win32')
    return substitute(a:instance_id, '/', '\\', 'g')
  endif
  return a:instance_id
endfunction

" Create a brand-new Claude Code terminal.
function! s:create_new(instance_id) abort
  call claude_code#util#debug('terminal: creating new instance for ' . a:instance_id)
  let l:cmd = s:build_command(a:instance_id)
  let l:cwd = s:instance_cwd(a:instance_id)
  let l:pos = claude_code#window#resolve_position(claude_code#config#get('position'))

  if l:pos ==# 'float' && has('popupwin')
    let l:bufnr = s:create_float_terminal(l:cmd, l:cwd)
  elseif l:pos ==# 'tab'
    let l:bufnr = s:create_tab_terminal(l:cmd, l:cwd)
  else
    let l:bufnr = s:create_split_terminal(l:cmd, l:pos, l:cwd)
  endif

  if l:bufnr <= 0
    call claude_code#util#error('claude-code: failed to create terminal')
    return
  endif

  " Register instance.
  let s:instances[a:instance_id] = l:bufnr

  " Apply buffer name.
  call s:set_buffer_name(l:bufnr, a:instance_id)

  " Terminal-local keymaps.
  call claude_code#keymaps#setup_terminal(l:bufnr)

  " Start file-refresh monitoring.
  call claude_code#util#debug('terminal: refresh started')
  call claude_code#refresh#start()

  " Autocommand to clean up when the terminal job exits.
  augroup ClaudeCodeTermClose
    execute 'autocmd! * <buffer=' . l:bufnr . '>'
    execute 'autocmd BufWipeout <buffer=' . l:bufnr . '>'
          \ . ' call claude_code#terminal#on_close(' . l:bufnr . ')'
  augroup END

  " Enter terminal mode if configured.
  if claude_code#config#get('enter_insert')
    if mode() !=# 't'
      silent! normal! i
    endif
  endif
endfunction

" Create terminal inside a split window.
function! s:create_split_terminal(cmd, position, cwd) abort
  let l:ratio = claude_code#config#get('split_ratio')
  let l:is_vertical = (a:position =~# 'vert')

  if l:is_vertical
    let l:size = float2nr(round(&columns * l:ratio))
  else
    let l:size = float2nr(round(&lines * l:ratio))
  endif

  let l:term_opts = {
        \ 'term_finish': 'open',
        \ 'term_name':   'claude-code',
        \ 'curwin':      0,
        \ 'norestore':   1,
        \ }

  if !empty(a:cwd)
    let l:term_opts['cwd'] = a:cwd
  endif

  " Use term_start with vertical/horizontal option.
  if l:is_vertical
    let l:term_opts['vertical'] = 1
    let l:term_opts['term_cols'] = l:size
  else
    let l:term_opts['term_rows'] = l:size
  endif

  let l:bufnr = term_start([&shell, &shellcmdflag, a:cmd], l:term_opts)

  " Move window to the correct edge.
  if l:is_vertical
    if a:position =~# 'topleft'
      wincmd H
    else
      wincmd L
    endif
    execute 'vertical resize ' . l:size
  else
    if a:position =~# 'botright'
      wincmd J
    else
      wincmd K
    endif
    execute 'resize ' . l:size
  endif

  " Configure the window.
  call s:configure_term_window()

  return l:bufnr
endfunction

" Create terminal inside a floating popup.
function! s:create_float_terminal(cmd, cwd) abort
  let l:popup_opts = claude_code#window#build_float_opts(0)

  let l:term_opts = {
        \ 'hidden': 1,
        \ 'term_finish': 'open',
        \ 'term_name':   'claude-code',
        \ 'norestore':   1,
        \ }
  if !empty(a:cwd)
    let l:term_opts['cwd'] = a:cwd
  endif

  let l:bufnr = term_start([&shell, &shellcmdflag, a:cmd], l:term_opts)

  call popup_create(l:bufnr, l:popup_opts)
  return l:bufnr
endfunction

" Create terminal in a new tab.
function! s:create_tab_terminal(cmd, cwd) abort
  let l:term_opts = {
        \ 'term_finish': 'open',
        \ 'term_name':   'claude-code',
        \ 'curwin':      0,
        \ 'norestore':   1,
        \ }
  if !empty(a:cwd)
    let l:term_opts['cwd'] = a:cwd
  endif

  let l:bufnr = term_start([&shell, &shellcmdflag, a:cmd], l:term_opts)
  " Move to its own tab.
  execute 'tab sbuffer ' . l:bufnr
  " Close the split left behind in the original tab.
  wincmd p
  if winnr('$') > 1
    close
  endif
  " Switch back to the tab containing our terminal.
  tablast
  call s:configure_term_window()
  return l:bufnr
endfunction

" Re-show a hidden but valid terminal buffer.
function! s:show_existing(bufnr) abort
  let l:pos = claude_code#window#resolve_position(claude_code#config#get('position'))

  if l:pos ==# 'float' && has('popupwin')
    call s:create_float_terminal_from_buf(a:bufnr)
  elseif l:pos ==# 'tab'
    execute 'tab sbuffer ' . a:bufnr
    call s:configure_term_window()
  else
    let l:ratio = claude_code#config#get('split_ratio')
    let l:is_vertical = (l:pos =~# 'vert')

    execute l:pos . ' sbuffer ' . a:bufnr

    if l:is_vertical
      let l:size = float2nr(round(&columns * l:ratio))
      execute 'vertical resize ' . l:size
    else
      let l:size = float2nr(round(&lines * l:ratio))
      execute 'resize ' . l:size
    endif

    call s:configure_term_window()
  endif

  " Re-enter terminal mode.
  if claude_code#config#get('enter_insert')
    if mode() !=# 't'
      silent! normal! i
    endif
  endif
endfunction

" Show an existing buffer in a floating popup.
function! s:create_float_terminal_from_buf(bufnr) abort
  let l:popup_opts = claude_code#window#build_float_opts(a:bufnr)
  call popup_create(a:bufnr, l:popup_opts)
endfunction

" Called when a Claude Code terminal buffer is wiped out.
function! claude_code#terminal#on_close(bufnr) abort
  " Remove from instance registry.
  for [l:id, l:bn] in items(s:instances)
    if l:bn ==# a:bufnr
      call remove(s:instances, l:id)
      break
    endif
  endfor

  " If no more instances, stop file-refresh.
  if empty(s:instances)
    call claude_code#refresh#stop()
  endif
endfunction

" ---------------------------------------------------------------------------
" Utility helpers
" ---------------------------------------------------------------------------

" Check if a buffer is a valid, running terminal.
function! s:is_valid(bufnr) abort
  if !bufexists(a:bufnr)
    return 0
  endif
  if getbufvar(a:bufnr, '&buftype') !=# 'terminal'
    return 0
  endif
  " term_getstatus() returns e.g. 'running' or 'finished'.
  return term_getstatus(a:bufnr) =~# 'running'
endfunction

" Check if a buffer is currently displayed in any window.
function! s:is_visible(bufnr) abort
  " Check regular windows.
  if !empty(win_findbuf(a:bufnr))
    return 1
  endif
  " Check popup windows.
  if has('popupwin')
    for l:pid in popup_list()
      if winbufnr(l:pid) ==# a:bufnr
        return 1
      endif
    endfor
  endif
  return 0
endfunction

" Set a descriptive buffer name.
function! s:set_buffer_name(bufnr, instance_id) abort
  try
    if a:instance_id ==# 'global'
      call setbufvar(a:bufnr, 'claude_code_instance', 'global')
    else
      call setbufvar(a:bufnr, 'claude_code_instance', a:instance_id)
    endif
  catch
    " Silently ignore — buffer name collisions are harmless.
  endtry
endfunction

" Apply terminal-friendly options to the current window.
function! s:configure_term_window() abort
  if claude_code#config#get('hide_numbers')
    setlocal nonumber
    setlocal norelativenumber
  endif
  if claude_code#config#get('hide_signcolumn')
    setlocal signcolumn=no
  endif
  setlocal nobuflisted
  setlocal bufhidden=hide
  setlocal winfixheight
  setlocal winfixwidth
  " Ensure mouse events (clicks, scroll wheel) are always active in this
  " window regardless of the user's global 'mouse' setting.  Without this,
  " touchpad and mouse scroll events never reach Vim when the terminal window
  " is focused, so ScrollWheelUp/Down tnoremap bindings cannot fire.
  setlocal mouse=a
endfunction
