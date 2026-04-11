" claude_code/git.vim - Git repository root detection
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_git')
  finish
endif
let g:autoloaded_claude_code_git = 1

" Cache: cwd -> git root path (or empty string if not a repo).
let s:git_root_cache = {}

" Return the git repository root for the current working directory.
" Returns an empty string if not inside a git work tree.
" Results are cached per cwd to avoid repeated shell-outs.
function! claude_code#git#root() abort
  let l:cwd = getcwd()
  if has_key(s:git_root_cache, l:cwd)
    return s:git_root_cache[l:cwd]
  endif

  let s:output_redirect = ' 2>/dev/null'
  if has("win32")
    let s:output_redirect = ' 2>nul'
  endif

  let l:inside = system('git -C ' . shellescape(l:cwd) . ' rev-parse --is-inside-work-tree' . s:output_redirect)
  if v:shell_error || trim(l:inside) !=# 'true'
    let s:git_root_cache[l:cwd] = ''
    return ''
  endif

  let l:root = trim(system('git -C ' . shellescape(l:cwd) . ' rev-parse --show-toplevel' . s:output_redirect))
  if v:shell_error
    let s:git_root_cache[l:cwd] = ''
    return ''
  endif

  let s:git_root_cache[l:cwd] = l:root
  return l:root
endfunction

" Clear the git root cache (useful if user changes repos mid-session).
function! claude_code#git#clear_cache() abort
  let s:git_root_cache = {}
endfunction
