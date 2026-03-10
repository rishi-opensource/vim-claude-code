vim9script

# claude_code/terminal.vim - Terminal buffer lifecycle management
# Maintainer: Claude Code Vim Plugin
# License: MIT

import './config.vim'
import './util.vim'
import './git.vim'
import './window.vim'
import './keymaps.vim'
import './refresh.vim'

# Instance registry: instance_id -> bufnr
var instances: dict<number> = {}

# Temporary variant flag appended to the command for one toggle cycle.
var pending_variant = ''

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

# Toggle the Claude Code terminal, optionally with a subcommand variant.
# If a terminal for the current instance exists and is visible, hide it.
# If it exists but is hidden, show it. Otherwise create a new one.
# When a variant name is given (e.g. 'continue'), the corresponding CLI
# flag is appended on first creation only.
export def Toggle(...args: list<string>)
  var variant_name = args->len() > 0 ? args[0] : ''
  util.Debug('terminal#toggle variant=' .. variant_name)

  # Resolve variant flag when a subcommand is provided.
  var flag = ''
  if !empty(variant_name)
    var val = config.Get('variant_' .. variant_name)
    if type(val) != v:t_string || empty(val)
      util.Error('claude-code: unknown subcommand "' .. variant_name .. '"')
      return
    endif
    flag = val
  endif

  var id = GetInstanceId()
  var bufnr = get(instances, id, -1)

  if bufnr > 0 && IsValid(bufnr)
    if IsVisible(bufnr)
      window.CloseBufWindows(bufnr)
    else
      ShowExisting(bufnr)
    endif
  else
    if !empty(flag)
      pending_variant = flag
    endif
    CreateNew(id)
    pending_variant = ''
  endif
enddef

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Determine the instance identifier.
# In multi-instance mode this is the git root (or cwd as fallback).
# In single-instance mode it is the fixed string 'global'.
def GetInstanceId(): string
  if !config.Get('multi_instance')
    return 'global'
  endif
  if config.Get('use_git_root')
    var root = git.Root()
    if !empty(root)
      return root
    endif
  endif
  return getcwd()
enddef

# Build the shell command to execute.
def BuildCommand(instance_id: string): string
  var cmd = config.Get('command')

  # Append --model when the user has configured one.
  var model = config.Get('model')
  if !empty(model)
    cmd ..= ' --model ' .. shellescape(model)
  endif

  # Append pending variant flag.
  if !empty(pending_variant)
    cmd ..= ' ' .. pending_variant
  endif

  # Wrap in pushd/popd when using a git root different from cwd.
  if config.Get('use_git_root') && instance_id !=# getcwd() && instance_id !=# 'global'
    cmd = 'pushd ' .. shellescape(instance_id) .. ' && ' .. cmd .. ' ; popd'
  endif

  return cmd
enddef

# Create a brand-new Claude Code terminal.
def CreateNew(instance_id: string)
  util.Debug('terminal: creating new instance for ' .. instance_id)
  var cmd = BuildCommand(instance_id)
  var pos = window.ResolvePosition(config.Get('position'))

  var bufnr = -1
  if pos ==# 'float' && has('popupwin')
    bufnr = CreateFloatTerminal(cmd)
  elseif pos ==# 'tab'
    bufnr = CreateTabTerminal(cmd)
  else
    bufnr = CreateSplitTerminal(cmd, pos)
  endif

  if bufnr <= 0
    util.Error('claude-code: failed to create terminal')
    return
  endif

  # Register instance.
  instances[instance_id] = bufnr

  # Apply buffer name.
  SetBufferName(bufnr, instance_id)

  # Terminal-local keymaps.
  keymaps.SetupTerminal(bufnr)

  # Start file-refresh monitoring.
  util.Debug('terminal: refresh started')
  refresh.Start()

  # Autocommand to clean up when the terminal job exits.
  augroup ClaudeCodeTermClose
    execute 'autocmd! * <buffer=' .. bufnr .. '>'
    execute 'autocmd BufWipeout <buffer=' .. bufnr .. '>'
          .. ' call claude_code#terminal#OnClose(' .. bufnr .. ')'
  augroup END

  # Enter terminal mode if configured.
  if config.Get('enter_insert')
    if mode() !=# 't'
      silent! normal! i
    endif
  endif
enddef

# Create terminal inside a split window.
def CreateSplitTerminal(cmd: string, position: string): number
  var ratio = config.Get('split_ratio')
  var is_vertical = (position =~# 'vert')

  var size = 0
  if is_vertical
    size = float2nr(round(&columns * ratio))
  else
    size = float2nr(round(&lines * ratio))
  endif

  var term_opts: dict<any> = {
    term_finish: 'open',
    term_name:   'claude-code',
    curwin:      0,
    norestore:   1,
  }

  # Use term_start with vertical/horizontal option.
  if is_vertical
    term_opts['vertical'] = 1
    term_opts['term_cols'] = size
  else
    term_opts['term_rows'] = size
  endif

  var bufnr = term_start([&shell, '-c', cmd], term_opts)

  # Move window to the correct edge.
  if is_vertical
    if position =~# 'topleft'
      wincmd H
    else
      wincmd L
    endif
    execute 'vertical resize ' .. size
  else
    if position =~# 'botright'
      wincmd J
    else
      wincmd K
    endif
    execute 'resize ' .. size
  endif

  # Configure the window.
  ConfigureTermWindow()

  return bufnr
enddef

# Create terminal inside a floating popup.
def CreateFloatTerminal(cmd: string): number
  var popup_opts = window.BuildFloatOpts(0)

  var bufnr = term_start([&shell, '-c', cmd], {
    hidden: 1,
    term_finish: 'open',
    term_name:   'claude-code',
    norestore:   1,
  })

  popup_create(bufnr, popup_opts)
  return bufnr
enddef

# Create terminal in a new tab.
def CreateTabTerminal(cmd: string): number
  var bufnr = term_start([&shell, '-c', cmd], {
    term_finish: 'open',
    term_name:   'claude-code',
    curwin:      0,
    norestore:   1,
  })
  # Move to its own tab.
  execute 'tab sbuffer ' .. bufnr
  # Close the split left behind in the original tab.
  wincmd p
  if winnr('$') > 1
    close
  endif
  # Switch back to the tab containing our terminal.
  tablast
  ConfigureTermWindow()
  return bufnr
enddef

# Re-show a hidden but valid terminal buffer.
def ShowExisting(bufnr: number)
  var pos = window.ResolvePosition(config.Get('position'))

  if pos ==# 'float' && has('popupwin')
    CreateFloatTerminalFromBuf(bufnr)
  elseif pos ==# 'tab'
    execute 'tab sbuffer ' .. bufnr
    ConfigureTermWindow()
  else
    var ratio = config.Get('split_ratio')
    var is_vertical = (pos =~# 'vert')

    execute pos .. ' sbuffer ' .. bufnr

    if is_vertical
      var size = float2nr(round(&columns * ratio))
      execute 'vertical resize ' .. size
    else
      var size = float2nr(round(&lines * ratio))
      execute 'resize ' .. size
    endif

    ConfigureTermWindow()
  endif

  # Re-enter terminal mode.
  if config.Get('enter_insert')
    if mode() !=# 't'
      silent! normal! i
    endif
  endif
enddef

# Show an existing buffer in a floating popup.
def CreateFloatTerminalFromBuf(bufnr: number)
  var popup_opts = window.BuildFloatOpts(bufnr)
  popup_create(bufnr, popup_opts)
enddef

# Called when a Claude Code terminal buffer is wiped out.
export def OnClose(bufnr: number)
  # Remove from instance registry.
  for [id, bn] in items(instances)
    if bn == bufnr
      remove(instances, id)
      break
    endif
  endfor

  # If no more instances, stop file-refresh.
  if empty(instances)
    refresh.Stop()
  endif
enddef

# ---------------------------------------------------------------------------
# Utility helpers
# ---------------------------------------------------------------------------

# Check if a buffer is a valid, running terminal.
def IsValid(bufnr: number): bool
  if !bufexists(bufnr)
    return false
  endif
  if getbufvar(bufnr, '&buftype') !=# 'terminal'
    return false
  endif
  # term_getstatus() returns e.g. 'running' or 'finished'.
  return term_getstatus(bufnr) =~# 'running'
enddef

# Check if a buffer is currently displayed in any window.
def IsVisible(bufnr: number): bool
  # Check regular windows.
  if !empty(win_findbuf(bufnr))
    return true
  endif
  # Check popup windows.
  if has('popupwin')
    for pid in popup_list()
      if winbufnr(pid) == bufnr
        return true
      endif
    endfor
  endif
  return false
enddef

# Set a descriptive buffer name.
def SetBufferName(bufnr: number, instance_id: string)
  try
    if instance_id ==# 'global'
      setbufvar(bufnr, 'claude_code_instance', 'global')
    else
      setbufvar(bufnr, 'claude_code_instance', instance_id)
    endif
  catch
    # Silently ignore — buffer name collisions are harmless.
  endtry
enddef

# Apply terminal-friendly options to the current window.
def ConfigureTermWindow()
  if config.Get('hide_numbers')
    setlocal nonumber
    setlocal norelativenumber
  endif
  if config.Get('hide_signcolumn')
    setlocal signcolumn=no
  endif
  setlocal nobuflisted
  setlocal bufhidden=hide
  setlocal winfixheight
  setlocal winfixwidth
  # Ensure mouse events (clicks, scroll wheel) are always active in this
  # window regardless of the user's global 'mouse' setting.  Without this,
  # touchpad and mouse scroll events never reach Vim when the terminal window
  # is focused, so ScrollWheelUp/Down tnoremap bindings cannot fire.
  setlocal mouse=a
enddef

