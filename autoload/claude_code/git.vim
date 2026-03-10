vim9script

# claude_code/git.vim - Git repository root detection
# Maintainer: Claude Code Vim Plugin
# License: MIT

# Cache: cwd -> git root path (or empty string if not a repo).
var git_root_cache: dict<string> = {}

# Return the git repository root for the current working directory.
# Returns an empty string if not inside a git work tree.
# Results are cached per cwd to avoid repeated shell-outs.
export def Root(): string
  var cwd = getcwd()
  if has_key(git_root_cache, cwd)
    return git_root_cache[cwd]
  endif

  var inside = system('git -C ' .. shellescape(cwd) .. ' rev-parse --is-inside-work-tree 2>/dev/null')
  if v:shell_error || trim(inside) !=# 'true'
    git_root_cache[cwd] = ''
    return ''
  endif

  var root = trim(system('git -C ' .. shellescape(cwd) .. ' rev-parse --show-toplevel 2>/dev/null'))
  if v:shell_error
    git_root_cache[cwd] = ''
    return ''
  endif

  git_root_cache[cwd] = root
  return root
enddef

# Clear the git root cache (useful if user changes repos mid-session).
export def ClearCache()
  git_root_cache = {}
enddef

