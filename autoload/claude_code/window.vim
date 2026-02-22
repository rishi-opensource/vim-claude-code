" claude_code/window.vim - Window layout management utilities
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

" Translate user-friendly position names to Vim command modifiers.
" Maps: bottom->botright, top->topleft, left->vertical topleft,
"       right->vertical botright. Float and tab pass through as-is.
let s:position_map = {
      \ 'bottom': 'botright',
      \ 'top':    'topleft',
      \ 'left':   'vertical topleft',
      \ 'right':  'vertical botright',
      \ 'float':  'float',
      \ 'tab':    'tab',
      \ }

" Get border characters for a given border style name.
" Returns the character array or empty list for 'none'.
function! claude_code#window#get_border_chars(border_name) abort
  return get(s:border_styles, a:border_name, s:border_styles['rounded'])
endfunction

" Resolve a position name to its Vim modifier.
" Returns the modifier string or the original value if not found.
function! claude_code#window#resolve_position(pos) abort
  return get(s:position_map, a:pos, a:pos)
endfunction

" Build popup options for a floating window.
" Returns a dictionary suitable for popup_create().
function! claude_code#window#build_float_opts(bufnr) abort
  let l:width_ratio  = claude_code#config#get('float_width')
  let l:height_ratio = claude_code#config#get('float_height')

  let l:width  = float2nr(round(&columns * l:width_ratio))
  let l:height = float2nr(round(&lines   * l:height_ratio))
  let l:width  = max([l:width,  20])
  let l:height = max([l:height, 5])

  let l:col = (&columns - l:width)  / 2
  let l:row = (&lines   - l:height) / 2

  let l:border_name = claude_code#config#get('float_border')
  let l:borderchars = claude_code#window#get_border_chars(l:border_name)

  let l:opts = {
        \ 'minwidth':    l:width,
        \ 'maxwidth':    l:width,
        \ 'minheight':   l:height,
        \ 'maxheight':   l:height,
        \ 'line':        l:row + 1,
        \ 'col':         l:col + 1,
        \ 'zindex':      50,
        \ 'title':       ' Claude Code ',
        \ }

  " Only add border if borderchars is not empty (i.e., not 'none').
  if !empty(l:borderchars)
    let l:opts['border']      = [1, 1, 1, 1]
    let l:opts['borderchars'] = l:borderchars
  endif

  return l:opts
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
