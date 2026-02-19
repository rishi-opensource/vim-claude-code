" claude_code/window.vim - Window layout management
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_window')
  finish
endif
let g:autoloaded_claude_code_window = 1

" Border character sets for popup windows.
let s:border_styles = {
      \ 'rounded': ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
      \ 'single':  ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
      \ 'double':  ['═', '║', '═', '║', '╔', '╗', '╝', '╚'],
      \ 'solid':   [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
      \ 'none':    [],
      \ }

" Open a window in the configured layout.
" If {bufnr} is > 0, display that existing buffer; otherwise the caller
" is responsible for creating a terminal in the new window.
" Returns the window ID of the created window.
function! claude_code#window#open(bufnr) abort
  let l:pos = claude_code#config#get('position')

  " Translate user-friendly names to Vim modifiers.
  let l:pos_map = {
        \ 'bottom': 'botright',
        \ 'top':    'topleft',
        \ 'left':   'vertical topleft',
        \ 'right':  'vertical botright',
        \ }
  let l:modifier = get(l:pos_map, l:pos, l:pos)

  if l:pos ==# 'float'
    return s:open_float(a:bufnr)
  elseif l:pos ==# 'tab'
    return s:open_tab(a:bufnr)
  else
    return s:open_split(l:modifier, a:bufnr)
  endif
endfunction

" Open a horizontal or vertical split.
function! s:open_split(modifier, bufnr) abort
  let l:ratio = claude_code#config#get('split_ratio')
  let l:is_vertical = (a:modifier =~# 'vertical\|vert')

  if a:bufnr > 0
    execute a:modifier . ' sbuffer ' . a:bufnr
  else
    execute a:modifier . ' new'
  endif

  " Resize based on ratio.
  if l:is_vertical
    let l:size = float2nr(round(&columns * l:ratio))
    execute 'vertical resize ' . l:size
  else
    let l:size = float2nr(round(&lines * l:ratio))
    execute 'resize ' . l:size
  endif

  let l:win_id = win_getid()
  call s:configure_window(l:win_id)
  return l:win_id
endfunction

" Open a new tab.
function! s:open_tab(bufnr) abort
  if a:bufnr > 0
    execute 'tab sbuffer ' . a:bufnr
  else
    tabnew
  endif
  let l:win_id = win_getid()
  call s:configure_window(l:win_id)
  return l:win_id
endfunction

" Open a floating popup window (Vim 8.2+ with +popupwin).
" Falls back to a botright split if popups are not available.
function! s:open_float(bufnr) abort
  if !has('popupwin')
    echohl WarningMsg
    echomsg 'claude-code: popup windows require Vim 8.2+ with +popupwin; falling back to split'
    echohl None
    return s:open_split('botright', a:bufnr)
  endif

  let l:width_ratio  = claude_code#config#get('float_width')
  let l:height_ratio = claude_code#config#get('float_height')

  " Calculate pixel dimensions.
  let l:width  = float2nr(round(&columns * l:width_ratio))
  let l:height = float2nr(round(&lines   * l:height_ratio))

  " Ensure minimum size.
  let l:width  = max([l:width,  20])
  let l:height = max([l:height, 5])

  " Centre the popup.
  let l:col = (&columns - l:width)  / 2
  let l:row = (&lines   - l:height) / 2

  " Border characters.
  let l:border_name = claude_code#config#get('float_border')
  let l:borderchars = get(s:border_styles, l:border_name, s:border_styles['rounded'])

  let l:opts = {
        \ 'minwidth':  l:width,
        \ 'maxwidth':  l:width,
        \ 'minheight': l:height,
        \ 'maxheight': l:height,
        \ 'line':      l:row + 1,
        \ 'col':       l:col + 1,
        \ 'zindex':    50,
        \ 'title':     ' Claude Code ',
        \ }

  if !empty(l:borderchars)
    let l:opts['border']      = [1, 1, 1, 1]
    let l:opts['borderchars'] = l:borderchars
  endif

  if a:bufnr > 0
    " Show existing buffer in popup.
    let l:popup_id = popup_create(a:bufnr, l:opts)
  else
    " Create an empty popup; caller will start a terminal inside it.
    let l:tmp_buf = term_start('NONE', {
          \ 'hidden': 1,
          \ 'term_finish': 'close',
          \ })
    let l:popup_id = popup_create(l:tmp_buf, l:opts)
  endif

  return l:popup_id
endfunction

" Apply terminal-friendly options to a window.
function! s:configure_window(win_id) abort
  if claude_code#config#get('hide_numbers')
    call setwinvar(win_getid() ==# a:win_id ? 0 : a:win_id, '&number', 0)
    call setwinvar(win_getid() ==# a:win_id ? 0 : a:win_id, '&relativenumber', 0)
  endif
  if claude_code#config#get('hide_signcolumn')
    call setwinvar(win_getid() ==# a:win_id ? 0 : a:win_id, '&signcolumn', 'no')
  endif
endfunction

" Close all windows displaying a given buffer.
" Returns the number of windows closed.
function! claude_code#window#close_buf_windows(bufnr) abort
  let l:closed = 0
  for l:win_id in win_findbuf(a:bufnr)
    let l:winnr = win_id2win(l:win_id)
    if l:winnr > 0
      execute l:winnr . 'wincmd c'
      let l:closed += 1
    endif
  endfor

  " Also check for popup windows.
  if has('popupwin')
    for l:pid in popup_list()
      if winbufnr(l:pid) ==# a:bufnr
        call popup_close(l:pid)
        let l:closed += 1
      endif
    endfor
  endif

  return l:closed
endfunction
