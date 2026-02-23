" autoload/claude_code/terminal_bridge.vim
" Finds the active Claude Code terminal buffer and sends text to it.
"
" How the base plugin works (from terminal.vim):
"   - Terminal bufs are tracked in s:instances (private, inaccessible)
"   - Each buf gets b:claude_code_instance set via setbufvar()
"   - term_getstatus(bufnr) returns 'running' while alive
"   - term_name is set to 'claude-code' in term_start() opts
"
" So we find the right buffer by scanning for b:claude_code_instance.

" ─────────────────────────────────────────────────────────────────────────────
" claude_code#terminal_bridge#get_buf()
" Returns the bufnr of a running Claude Code terminal, or -1.
" ─────────────────────────────────────────────────────────────────────────────
function! claude_code#terminal_bridge#get_buf() abort
  " Pass 1: b:claude_code_instance is stamped by the base plugin on every
  " terminal it owns (via setbufvar in s:set_buffer_name).
  for l:bnr in term_list()
    if getbufvar(l:bnr, 'claude_code_instance', '') !=# ''
      if term_getstatus(l:bnr) =~# 'running'
        return l:bnr
      endif
    endif
  endfor

  " Pass 2: base plugin sets term_name 'claude-code' — buf name contains it.
  for l:bnr in term_list()
    if term_getstatus(l:bnr) =~# 'running'
      if bufname(l:bnr) =~# 'claude'
        return l:bnr
      endif
    endif
  endfor

  return -1
endfunction

" ─────────────────────────────────────────────────────────────────────────────
" claude_code#terminal_bridge#send(prompt)
" Sends a prompt to the active Claude terminal.
" Opens one via the base plugin's toggle if none exists yet.
" ─────────────────────────────────────────────────────────────────────────────
function! claude_code#terminal_bridge#send(prompt) abort
  let l:bnr = claude_code#terminal_bridge#get_buf()

  if l:bnr < 0
    " Open a terminal via the base plugin (toggle with no variant).
    call claude_code#terminal#toggle()
    sleep 300m
    let l:bnr = claude_code#terminal_bridge#get_buf()
  endif

  if l:bnr < 0
    echoerr 'claude-code: no Claude terminal is running. '
          \ . 'Open one first with :Claude or <C-\>'
    return
  endif

  " Send the prompt text followed by Enter to submit it.
  call term_sendkeys(l:bnr, a:prompt . "\<CR>")
endfunction
