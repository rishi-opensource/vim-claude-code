vim9script

# claude_code/config.vim - Configuration defaults and access helpers
# Maintainer: Claude Code Vim Plugin
# License: MIT

# Default configuration values.
# Users override these by setting g:claude_code_<key> in their vimrc.
const defaults = {
  command:             'claude',
  split_ratio:         0.4,
  position:            'right',
  enter_insert:        1,
  hide_numbers:        1,
  hide_signcolumn:     1,
  use_git_root:        1,
  multi_instance:      1,
  map_keys:            1,
  map_extended_keys:   1,
  refresh_enable:      1,
  refresh_interval:    1000,
  refresh_notify:      1,
  float_width:         0.8,
  float_height:        0.8,
  float_border:        'rounded',
  variant_continue:    '--continue',
  variant_resume:      '--resume',
  variant_verbose:     '--verbose',
  map_toggle:          '<C-\>',
  map_continue:        '<Leader>cC',
  map_verbose:         '<Leader>cV',
  debug:               0,
  terminal_start_delay: 300,
  scroll_keys:         1,
}

# Get a configuration value.
# Checks buffer-local (b:claude_code_<key>) first, then global
# (g:claude_code_<key>), then falls back to the built-in default.
export def Get(key: string, ...args: any[]): any
  var bvar = 'claude_code_' .. key
  if exists('b:' .. bvar)
    return b:[bvar]
  endif
  var default = get(defaults, key, args->len() > 0 ? args[0] : '')
  var gvar = 'claude_code_' .. key
  return g:->get(gvar, default)
enddef

# Return a copy of the full defaults dictionary (useful for documentation).
export def Defaults(): dict<any>
  return copy(defaults)
enddef

# Set a configuration value for the current session.
# Writes to the g:claude_code_<key> variable that get() already reads.
export def Set(key: string, value: any)
  var gvar = 'claude_code_' .. key
  g:[gvar] = value
enddef

