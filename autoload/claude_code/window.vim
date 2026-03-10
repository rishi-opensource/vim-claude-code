vim9script

# claude_code/window.vim - Window layout management utilities
# Maintainer: Claude Code Vim Plugin
# License: MIT

import './config.vim'

# Border character sets for popup windows.
const border_styles = {
  rounded: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
  single:  ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
  double:  ['═', '║', '═', '║', '╔', '╗', '╝', '╚'],
  solid:   [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
  none:    [],
}

# Translate user-friendly position names to Vim command modifiers.
# Maps: bottom->botright, top->topleft, left->vertical topleft,
#       right->vertical botright. Float and tab pass through as-is.
const position_map = {
  bottom: 'botright',
  top:    'topleft',
  left:   'vertical topleft',
  right:  'vertical botright',
  float:  'float',
  tab:    'tab',
}

# Get border characters for a given border style name.
# Returns the character array or empty list for 'none'.
export def GetBorderChars(border_name: string): list<string>
  return get(border_styles, border_name, border_styles['rounded'])
enddef

# Resolve a position name to its Vim modifier.
# Returns the modifier string or the original value if not found.
export def ResolvePosition(pos: string): string
  return get(position_map, pos, pos)
enddef

# Build popup options for a floating window.
# Returns a dictionary suitable for popup_create().
export def BuildFloatOpts(bufnr: number): dict<any>
  var width_ratio = config.Get('float_width')
  var height_ratio = config.Get('float_height')

  var width = float2nr(round(&columns * width_ratio))
  var height = float2nr(round(&lines * height_ratio))
  width = max([width, 20])
  height = max([height, 5])

  var col = (&columns - width) / 2
  var row = (&lines - height) / 2

  var border_name = config.Get('float_border')
  var borderchars = GetBorderChars(border_name)

  var opts: dict<any> = {
    minwidth:  width,
    maxwidth:  width,
    minheight: height,
    maxheight: height,
    line:      row + 1,
    col:       col + 1,
    zindex:    50,
    title:     ' Claude Code ',
  }

  # Only add border if borderchars is not empty (i.e., not 'none').
  if !empty(borderchars)
    opts['border'] = [1, 1, 1, 1]
    opts['borderchars'] = borderchars
  endif

  return opts
enddef

# Close all windows displaying a given buffer.
# Returns the number of windows closed.
export def CloseBufWindows(bufnr: number): number
  var closed = 0
  for win_id in win_findbuf(bufnr)
    var winnr = win_id2win(win_id)
    if winnr > 0
      execute winnr .. 'wincmd c'
      closed += 1
    endif
  endfor

  # Also check for popup windows.
  if has('popupwin')
    for pid in popup_list()
      if winbufnr(pid) == bufnr
        popup_close(pid)
        closed += 1
      endif
    endfor
  endif

  return closed
enddef

