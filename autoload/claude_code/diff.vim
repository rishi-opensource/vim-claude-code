" autoload/claude_code/diff.vim
" Diff preview for Claude Code edit suggestions.
" Shows a side-by-side diff tab when Claude proposes file changes.
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_diff')
  finish
endif
let g:autoloaded_claude_code_diff = 1

" ---------------------------------------------------------------------------
" State
" ---------------------------------------------------------------------------

let s:diff_tab = -1
let s:diff_bufs = []
let s:poll_timer = -1
let s:trigger_dir = ''

" ---------------------------------------------------------------------------
" Polling — file-based IPC for hook → Vim communication
" ---------------------------------------------------------------------------

function! claude_code#diff#start_polling() abort
  if s:poll_timer >= 0
    return
  endif
  let s:trigger_dir = exists('$TMPDIR') ? $TMPDIR : '/tmp'
  let s:poll_timer = timer_start(300, function('s:check_trigger'), {'repeat': -1})
  call claude_code#util#debug('diff: polling started (' . s:trigger_dir . ')')
endfunction

function! claude_code#diff#stop_polling() abort
  if s:poll_timer >= 0
    call timer_stop(s:poll_timer)
    let s:poll_timer = -1
    call claude_code#util#debug('diff: polling stopped')
  endif
endfunction

function! s:check_trigger(timer_id) abort
  let l:close_trigger = s:trigger_dir . '/claude-vim-diff-close'
  let l:open_trigger = s:trigger_dir . '/claude-vim-diff-trigger.json'

  " Check for close trigger first
  if filereadable(l:close_trigger)
    call delete(l:close_trigger)
    call claude_code#diff#close()
    return
  endif

  " Check for open trigger
  if filereadable(l:open_trigger)
    try
      let l:raw = join(readfile(l:open_trigger), "\n")
      call delete(l:open_trigger)
      let l:data = json_decode(l:raw)
      call claude_code#diff#show(l:data.orig, l:data.proposed, l:data.display_name)
    catch
      call claude_code#util#error('claude-code: failed to parse diff trigger — ' . v:exception)
    endtry
  endif
endfunction

" Called by vim --servername --remote-expr for instant response
function! claude_code#diff#handle_trigger() abort
  call s:check_trigger(0)
  return ''
endfunction

" ---------------------------------------------------------------------------
" Diff display
" ---------------------------------------------------------------------------

function! claude_code#diff#show(orig_file, proposed_file, display_name) abort
  " Close any existing diff first
  call claude_code#diff#close()

  " Remember current tab so we can return if needed
  let l:prev_tab = tabpagenr()

  " --- New tab ---
  tabnew
  let s:diff_tab = tabpagenr()

  " --- Left window: CURRENT (original) ---
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  silent execute 'read ' . fnameescape(a:orig_file)
  silent 1delete _
  " Detect filetype from real filename for syntax highlighting
  execute 'doautocmd filetypedetect BufRead ' . fnameescape(a:display_name)
  setlocal nomodifiable readonly
  let &l:statusline = ' CURRENT: ' . a:display_name
  diffthis
  let l:orig_buf = bufnr('%')

  " --- Right window: PROPOSED ---
  rightbelow vsplit
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  silent execute 'read ' . fnameescape(a:proposed_file)
  silent 1delete _
  execute 'doautocmd filetypedetect BufRead ' . fnameescape(a:display_name)
  setlocal nomodifiable readonly
  let &l:statusline = ' PROPOSED: ' . a:display_name
  diffthis
  let l:prop_buf = bufnr('%')

  let s:diff_bufs = [l:orig_buf, l:prop_buf]

  " Show full file (open all folds)
  windo setlocal foldenable foldmethod=diff foldlevel=999 foldcolumn=0

  " Equalize windows and jump to first change
  wincmd =
  normal! gg]c

  " Keymap: q to close diff tab
  for l:buf in s:diff_bufs
    call setbufvar(l:buf, '&buflisted', 0)
    execute 'nnoremap <buffer> <silent> q :call claude_code#diff#close()<CR>'
  endfor

  echomsg 'claude-code: diff preview for ' . a:display_name . ' — accept/reject in Claude terminal (q to close)'
endfunction

" ---------------------------------------------------------------------------
" Close diff
" ---------------------------------------------------------------------------

function! claude_code#diff#close() abort
  if s:diff_tab <= 0
    return ''
  endif

  " Find and close the diff tab
  try
    let l:current_tab = tabpagenr()
    " Only close if the tab still exists
    if s:diff_tab <= tabpagenr('$')
      execute 'tabclose ' . s:diff_tab
      " If we were on a later tab, adjust index
      if l:current_tab > s:diff_tab
        execute 'tabnext ' . (l:current_tab - 1)
      elseif l:current_tab < s:diff_tab
        execute 'tabnext ' . l:current_tab
      endif
    endif
  catch
    " Tab may already be closed
  endtry

  " Clean up buffer references
  for l:buf in s:diff_bufs
    try
      if bufexists(l:buf)
        execute 'bwipeout! ' . l:buf
      endif
    catch
    endtry
  endfor

  let s:diff_tab = -1
  let s:diff_bufs = []
  return ''
endfunction

" ---------------------------------------------------------------------------
" Status
" ---------------------------------------------------------------------------

function! claude_code#diff#is_open() abort
  return s:diff_tab > 0 && s:diff_tab <= tabpagenr('$')
endfunction

function! claude_code#diff#is_polling() abort
  return s:poll_timer >= 0
endfunction

" ---------------------------------------------------------------------------
" Hook management — install/uninstall PreToolUse & PostToolUse hooks
" ---------------------------------------------------------------------------

function! s:bin_dir() abort
  " Resolve the plugin's bin/ directory
  let l:this_file = resolve(expand('<sfile>:p'))
  " autoload/claude_code/diff.vim -> go up 3 levels to plugin root
  return fnamemodify(l:this_file, ':h:h:h') . '/bin'
endfunction

function! claude_code#diff#install_hooks() abort
  let l:bin = s:bin_dir()
  let l:preview_script = l:bin . '/vim-preview-diff.sh'
  let l:close_script = l:bin . '/vim-close-diff.sh'

  " Verify scripts exist
  if !filereadable(l:preview_script)
    call claude_code#util#error('claude-code: hook script not found: ' . l:preview_script)
    return
  endif
  if !filereadable(l:close_script)
    call claude_code#util#error('claude-code: hook script not found: ' . l:close_script)
    return
  endif

  " Determine settings path
  let l:git_root = claude_code#git#root()
  let l:base = empty(l:git_root) ? getcwd() : l:git_root
  let l:settings_dir = l:base . '/.claude'
  let l:settings_path = l:settings_dir . '/settings.local.json'

  " Read existing settings
  let l:data = {}
  if filereadable(l:settings_path)
    try
      let l:raw = join(readfile(l:settings_path), "\n")
      if !empty(l:raw)
        let l:data = json_decode(l:raw)
      endif
    catch
      call claude_code#util#error('claude-code: failed to parse ' . l:settings_path)
      return
    endtry
  endif

  " Ensure hooks structure exists
  if !has_key(l:data, 'hooks')
    let l:data.hooks = {}
  endif
  if !has_key(l:data.hooks, 'PreToolUse')
    let l:data.hooks.PreToolUse = []
  endif
  if !has_key(l:data.hooks, 'PostToolUse')
    let l:data.hooks.PostToolUse = []
  endif

  " Remove any existing vim-claude-code diff entries (avoid duplicates)
  let l:marker = 'vim-preview-diff'
  call s:remove_hook_entries(l:data.hooks.PreToolUse, l:marker)
  call s:remove_hook_entries(l:data.hooks.PostToolUse, l:marker)

  " Add our entries
  call add(l:data.hooks.PreToolUse, {
        \ 'matcher': 'Edit|Write|MultiEdit',
        \ 'hooks': [{'type': 'command', 'command': l:preview_script}],
        \ })
  call add(l:data.hooks.PostToolUse, {
        \ 'matcher': 'Edit|Write|MultiEdit',
        \ 'hooks': [{'type': 'command', 'command': l:close_script}],
        \ })

  " Write settings
  call mkdir(l:settings_dir, 'p')
  call writefile([json_encode(l:data)], l:settings_path)

  " Start polling
  call claude_code#diff#start_polling()

  echomsg 'claude-code: diff preview hooks installed -> ' . l:settings_path
endfunction

function! claude_code#diff#uninstall_hooks() abort
  " Determine settings path
  let l:git_root = claude_code#git#root()
  let l:base = empty(l:git_root) ? getcwd() : l:git_root
  let l:settings_path = l:base . '/.claude/settings.local.json'

  if !filereadable(l:settings_path)
    call claude_code#util#error('claude-code: no settings found at ' . l:settings_path)
    return
  endif

  let l:data = {}
  try
    let l:raw = join(readfile(l:settings_path), "\n")
    if !empty(l:raw)
      let l:data = json_decode(l:raw)
    endif
  catch
    call claude_code#util#error('claude-code: failed to parse ' . l:settings_path)
    return
  endtry

  if !has_key(l:data, 'hooks')
    echomsg 'claude-code: no hooks found in ' . l:settings_path
    return
  endif

  let l:marker = 'vim-preview-diff'
  if has_key(l:data.hooks, 'PreToolUse')
    call s:remove_hook_entries(l:data.hooks.PreToolUse, l:marker)
  endif
  if has_key(l:data.hooks, 'PostToolUse')
    call s:remove_hook_entries(l:data.hooks.PostToolUse, l:marker)
  endif

  call writefile([json_encode(l:data)], l:settings_path)

  " Stop polling
  call claude_code#diff#stop_polling()

  echomsg 'claude-code: diff preview hooks removed from ' . l:settings_path
endfunction

" Remove entries whose command contains the marker string
function! s:remove_hook_entries(list, marker) abort
  let l:i = len(a:list) - 1
  while l:i >= 0
    let l:entry = a:list[l:i]
    if has_key(l:entry, 'hooks') && !empty(l:entry.hooks)
      let l:cmd = get(l:entry.hooks[0], 'command', '')
      if stridx(l:cmd, a:marker) >= 0
        call remove(a:list, l:i)
      endif
    endif
    let l:i -= 1
  endwhile
endfunction

" ---------------------------------------------------------------------------
" Doctor check for diff preview dependencies
" ---------------------------------------------------------------------------

function! claude_code#diff#check_deps() abort
  let l:results = []

  if executable('python3')
    call add(l:results, '[OK]   python3 found')
  else
    call add(l:results, '[FAIL] python3 not found — required for diff preview')
  endif

  if executable('jq')
    call add(l:results, '[OK]   jq found')
  else
    call add(l:results, '[FAIL] jq not found — required for diff preview')
  endif

  if has('clientserver')
    call add(l:results, '[OK]   +clientserver support (instant diff, optional)')
  else
    call add(l:results, '[INFO] No +clientserver — using file-based polling (works fine)')
  endif

  return l:results
endfunction
