" autoload/claude_code/commands.vim
" Core code intelligence commands: explain, fix, refactor, test, doc
" Maintainer: Claude Code Vim Plugin
" License: MIT

if exists('g:autoloaded_claude_code_commands')
  finish
endif
let g:autoloaded_claude_code_commands = 1

" 1. :Claude explain
function! claude_code#commands#explain(flags) abort
  let l:code = claude_code#util#code_target()
  let l:ctx  = claude_code#util#file_context()

  if a:flags =~# '--brief'
    let l:detail = 'Give a very brief (2-3 sentence) explanation.'
  elseif a:flags =~# '--detailed'
    let l:detail = 'Give a thorough, detailed explanation including edge cases.'
  else
    let l:detail = 'Give a clear explanation.'
  endif

  let l:use_flompt = a:flags =~# '--flompt' || claude_code#config#get('use_flompt')
  let l:flompt = l:use_flompt ? "\n[FLOMPT] Use your Flompt MCP tools to decompose and compile a structured prompt before executing this task. " : ''

  call claude_code#terminal_bridge#send(
        \ l:ctx . "\n" . l:detail . l:flompt .
        \ "\n\nCode to explain:\n```\n" . l:code . "\n```\n")
endfunction

" 2. :Claude fix
function! claude_code#commands#fix(flags) abort
  let l:code = claude_code#util#code_target()
  let l:ctx  = claude_code#util#file_context()
  let l:safe = a:flags =~# '--safe'  ? 'Use minimal, safe changes only.' : ''
  let l:hint = a:flags =~# '--apply' ? 'Apply the fix directly without asking.'
        \                             : 'Show a diff preview before applying.'
  let l:use_flompt = a:flags =~# '--flompt' || claude_code#config#get('use_flompt')
  let l:flompt = l:use_flompt ? "[FLOMPT] Use your Flompt MCP tools to decompose and compile a structured prompt before executing this task. " : ''

  call claude_code#terminal_bridge#send(
        \ l:ctx . "\nTask: Fix any bugs or correctness issues. " . l:flompt .
        \ l:safe . ' ' . l:hint .
        \ "\n\n```\n" . l:code . "\n```\n")
endfunction

" 3. :Claude refactor
function! claude_code#commands#refactor(flags) abort
  let l:code = claude_code#util#code_target()
  let l:ctx  = claude_code#util#file_context()

  let l:strategy = 'Refactor for clarity and structure.'
  if a:flags =~# '--extract'
    let l:strategy = 'Extract reusable helpers or sub-functions.'
  elseif a:flags =~# '--simplify'
    let l:strategy = 'Simplify and reduce complexity.'
  elseif a:flags =~# '--optimize'
    let l:strategy = 'Optimize for performance and efficiency.'
  elseif a:flags =~# '--rename'
    let l:strategy = 'Suggest better, more descriptive names for variables and functions.'
  endif

  let l:use_flompt = a:flags =~# '--flompt' || claude_code#config#get('use_flompt')
  let l:flompt = l:use_flompt ? "[FLOMPT] Use your Flompt MCP tools to decompose and compile a structured prompt before executing this task. " : ''

  call claude_code#terminal_bridge#send(
        \ l:ctx . "\nTask: " . l:strategy . " " . l:flompt .
        \ "\n\n```\n" . l:code . "\n```\n")
endfunction

" 4. :Claude test
function! claude_code#commands#test(flags) abort
  let l:code = claude_code#util#code_target()
  let l:ctx  = claude_code#util#file_context()

  let l:fw = ''
  if a:flags =~# '--framework'
    let l:fw = matchstr(a:flags, '--framework\s\+\zs\S\+')
  endif
  if empty(l:fw)
    let l:fw = get({
          \ 'python': 'pytest', 'javascript': 'jest', 'typescript': 'jest',
          \ 'go': 'go-test', 'ruby': 'rspec', 'rust': 'cargo-test',
          \ 'java': 'junit',
          \ }, &filetype, '')
  endif

  let l:fw_hint   = empty(l:fw) ? '' : 'Use the ' . l:fw . ' testing framework.'
  let l:edge_hint = a:flags =~# '--edge-cases'
        \ ? ' Include edge cases and boundary conditions.' : ''

  let l:use_flompt = a:flags =~# '--flompt' || claude_code#config#get('use_flompt')
  let l:flompt = l:use_flompt ? "[FLOMPT] Use your Flompt MCP tools to decompose and compile a structured prompt before executing this task. " : ''

  call claude_code#terminal_bridge#send(
        \ l:ctx . "\nTask: Generate unit tests. " . l:fw_hint . l:edge_hint . ' ' . l:flompt .
        \ "\n\n```\n" . l:code . "\n```\n")
endfunction

" 5. :Claude doc
function! claude_code#commands#doc(flags) abort
  let l:code = claude_code#util#code_target()
  let l:ctx  = claude_code#util#file_context()

  if a:flags =~# '--markdown'
    let l:style = 'Generate Markdown documentation.'
  elseif a:flags =~# '--inline'
    let l:style = 'Add inline comments and docstrings directly in the code.'
  else
    let l:style = 'Generate appropriate docstrings/documentation comments.'
  endif

  let l:use_flompt = a:flags =~# '--flompt' || claude_code#config#get('use_flompt')
  let l:flompt = l:use_flompt ? "[FLOMPT] Use your Flompt MCP tools to decompose and compile a structured prompt before executing this task. " : ''

  call claude_code#terminal_bridge#send(
        \ l:ctx . "\nTask: " . l:style . " " . l:flompt .
        \ "\n\n```\n" . l:code . "\n```\n")
endfunction

" 6. :Claude flompt
function! claude_code#commands#flompt(flags) abort
  let l:code = claude_code#util#code_target()
  let l:ctx  = claude_code#util#file_context()
  
  " Optional custom prompt or instructions can be passed as flags
  let l:custom = trim(a:flags)
  let l:task = empty(l:custom) ? "Analyze the code." : l:custom

  call claude_code#terminal_bridge#send(
        \ l:ctx . "\nTask: " . l:task . 
        \ "\n[FLOMPT] Use your Flompt MCP tools to decompose and compile a structured prompt to complete this task effectively." .
        \ "\n\n```\n" . l:code . "\n```\n")
endfunction

" ---------------------------------------------------------------------------
" Private helpers
" ---------------------------------------------------------------------------

" s:code_target() consolidated into claude_code#util#code_target() in util.vim
