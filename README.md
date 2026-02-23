# vim-claude-code

A Vim plugin that integrates the [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI directly into your editor. Run Claude Code in a managed terminal, send code context with a single keystroke, and get automatic file reloading when Claude edits your files — all without leaving Vim.

## Features

- **One-key toggle** — Open and close Claude Code with `<C-\>`
- **20 intelligent sub-commands** — Explain, fix, refactor, test, document, commit, review, and more
- **Selection-aware** — Commands use visual selection when active, otherwise detect the current function
- **Multiple window layouts** — Bottom split, top split, vertical split, floating popup, or dedicated tab
- **Automatic file refresh** — Buffers reload when Claude modifies files on disk
- **Git-aware** — Starts Claude at the repository root; separate sessions per repo
- **Configurable** — 20+ `g:` variables with buffer-local overrides

## Requirements

- Vim 8.2+ compiled with `+terminal`
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and in `$PATH`
- Optional: `+popupwin` for floating window mode

## Installation

### [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'rishi-opensource/vim-claude-code'
```

### [Vundle](https://github.com/VundleVim/Vundle.vim)
```vim
Plugin 'rishi-opensource/vim-claude-code'
```

### [pathogen](https://github.com/tpope/vim-pathogen)
```sh
cd ~/.vim/bundle
git clone https://github.com/rishi-opensource/vim-claude-code.git
```

### Native packages (Vim 8+)
```sh
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/rishi-opensource/vim-claude-code.git
```

### Manual
Copy `plugin/`, `autoload/`, and `doc/` into `~/.vim/`, then:
```vim
:helptags ALL
```

## Quick Start

Press `<C-\>` to open Claude Code. Press it again to hide; again to restore. The session persists.

All sub-commands are tab-completable:
```
:Claude <Tab>
```

## Commands

### Terminal

| Command | Description |
|---|---|
| `:Claude` | Toggle the Claude Code terminal |
| `:Claude continue` | Toggle with `--continue` (resume last conversation) |
| `:Claude resume` | Toggle with `--resume` (interactive conversation picker) |
| `:Claude verbose` | Toggle with `--verbose` (detailed logging) |

### Code Intelligence

| Command | Flags | Description |
|---|---|---|
| `:Claude explain` | `--brief`, `--detailed` | Explain selected code or current function |
| `:Claude fix` | `--apply`, `--safe` | Fix bugs and correctness issues |
| `:Claude refactor` | `--extract`, `--simplify`, `--optimize`, `--rename` | Refactor code |
| `:Claude test` | `--framework {name}`, `--edge-cases` | Generate unit tests |
| `:Claude doc` | `--inline`, `--markdown` | Generate documentation |

### Git

| Command | Flags | Description |
|---|---|---|
| `:Claude commit` | `--conventional`, `--amend` | Generate commit message from staged diff |
| `:Claude review` | `--strict`, `--security` | Code review on current diff |
| `:Claude pr` | | Generate PR description |

### Architecture & Planning

| Command | Description |
|---|---|
| `:Claude plan` | Generate implementation plan for current file |
| `:Claude analyze` | Analyze for complexity, performance, and security |

### Workflow

| Command | Description |
|---|---|
| `:Claude rename` | Suggest better variable/function names |
| `:Claude optimize` | Optimize code for performance |
| `:Claude debug` | Analyze error on current line |
| `:Claude apply` | Apply Claude's last suggestion to the file |

### Meta

| Command | Description |
|---|---|
| `:Claude chat` | Send a free-form message with current file context |
| `:Claude context` | Preview what context will be sent to Claude |
| `:Claude model [name]` | Switch model (`sonnet`, `opus`, `haiku`) |

## Keymaps

### Default keymaps

| Mode | Key | Action |
|---|---|---|
| Normal | `<C-\>` | Toggle Claude Code terminal |
| Normal | `<Leader>cC` | Toggle with `--continue` |
| Normal | `<Leader>cV` | Toggle with `--verbose` |
| Terminal | `<C-\>` | Hide Claude Code terminal |
| Terminal | `<C-h/j/k/l>` | Navigate to adjacent window |

### Extended keymaps (`<Leader>c*`)

| Key | Command | Key | Command |
|---|---|---|---|
| `<Leader>ce` | explain | `<Leader>cG` | commit |
| `<Leader>cf` | fix | `<Leader>cR` | review |
| `<Leader>cr` | refactor | `<Leader>cp` | pr |
| `<Leader>ct` | test | `<Leader>cP` | plan |
| `<Leader>cd` | doc | `<Leader>ca` | analyze |
| `<Leader>cn` | rename | `<Leader>cD` | debug |
| `<Leader>co` | optimize | `<Leader>cA` | apply |
| `<Leader>cc` | chat | `<Leader>cx` | context |
| `<Leader>cm` | model | | |

Visual mode: `<Leader>c` + `e/f/r/t/d/n/o` operate on the selection.

To disable all default keymaps:
```vim
let g:claude_code_map_keys = 0
let g:claude_code_map_extended_keys = 0
```

## Window Modes

Set `g:claude_code_position` to one of:

| Value | Layout |
|---|---|
| `'bottom'` | Horizontal split at the bottom (default) |
| `'top'` | Horizontal split at the top |
| `'left'` | Vertical split on the left |
| `'right'` | Vertical split on the right |
| `'float'` | Floating popup (requires `+popupwin`) |
| `'tab'` | Dedicated tab page |

```vim
" Right split at 40%
let g:claude_code_position   = 'right'
let g:claude_code_split_ratio = 0.4

" Floating popup
let g:claude_code_position    = 'float'
let g:claude_code_float_width  = 0.85
let g:claude_code_float_height = 0.85
let g:claude_code_float_border = 'double'
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `g:claude_code_command` | `'claude'` | CLI executable |
| `g:claude_code_position` | `'bottom'` | Window layout |
| `g:claude_code_split_ratio` | `0.3` | Terminal size (0.0–1.0) |
| `g:claude_code_enter_insert` | `1` | Auto-enter Terminal mode on focus |
| `g:claude_code_hide_numbers` | `1` | Hide line numbers in terminal |
| `g:claude_code_hide_signcolumn` | `1` | Hide sign column in terminal |
| `g:claude_code_use_git_root` | `1` | Start Claude at git root |
| `g:claude_code_multi_instance` | `1` | Separate session per git repo |
| `g:claude_code_map_keys` | `1` | Register default toggle keymaps |
| `g:claude_code_map_extended_keys` | `1` | Register `<Leader>c*` keymaps |
| `g:claude_code_map_toggle` | `'<C-\>'` | Toggle key |
| `g:claude_code_map_continue` | `'<Leader>cC'` | Continue key |
| `g:claude_code_map_verbose` | `'<Leader>cV'` | Verbose key |
| `g:claude_code_refresh_enable` | `1` | Auto-reload changed buffers |
| `g:claude_code_refresh_interval` | `1000` | Polling interval (ms) |
| `g:claude_code_refresh_notify` | `1` | Notify on buffer reload |
| `g:claude_code_float_width` | `0.8` | Popup width fraction |
| `g:claude_code_float_height` | `0.8` | Popup height fraction |
| `g:claude_code_float_border` | `'rounded'` | Border style |
| `g:claude_code_model` | `''` | Claude model override |

Buffer-local `b:claude_code_*` overrides take precedence over `g:` variables.

## Plugin Structure

```
vim-claude-code/
├── plugin/
│   └── claude_code.vim           # Entry point: command + keymaps
├── autoload/
│   └── claude_code/
│       ├── config.vim            # Configuration defaults + get/set
│       ├── terminal.vim          # Terminal lifecycle (create/toggle/close)
│       ├── terminal_bridge.vim   # Terminal lookup and prompt dispatch
│       ├── window.vim            # Window layout utilities
│       ├── git.vim               # Git root detection with caching
│       ├── keymaps.vim           # Terminal-local keymaps
│       ├── refresh.vim           # File change detection and reload
│       ├── util.vim              # Shared helpers (selection, context)
│       ├── commands.vim          # explain, fix, refactor, test, doc
│       ├── git_commands.vim      # commit, review, pr
│       ├── arch_commands.vim     # plan, analyze
│       ├── workflow_commands.vim # rename, optimize, debug, apply
│       └── meta_commands.vim     # chat, context, model
└── doc/
    └── claude_code.txt           # :help documentation
```

## Help

```vim
:help claude-code
```

## Troubleshooting

**E117: Unknown function** — Run `:helptags ALL` then restart Vim. Ensure the
plugin directory is on your `runtimepath`.

**Terminal does not open** — Verify `vim --version | grep +terminal`. The plugin
requires Vim compiled with `+terminal`.

**Claude not found** — Ensure `claude` is in `$PATH`: `which claude`.

**File changes not detected** — Check `g:claude_code_refresh_enable` is `1` and
that `autoread` is not globally disabled in your vimrc.

## License

MIT
