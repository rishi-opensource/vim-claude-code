# claude-code.vim

A Vim plugin that integrates the [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI directly into your editor. Toggle a Claude Code terminal, get automatic file reloading when Claude edits your files, and maintain separate conversations per git repository — all without leaving Vim.

## Features

- **One-key toggle** — Open and close Claude Code with a single keystroke
- **Multiple window layouts** — Bottom split, top split, vertical split, floating popup, or dedicated tab
- **Automatic file refresh** — Buffers reload when Claude modifies files on disk
- **Git-aware** — Starts Claude at the repository root with per-repo terminal instances
- **Command variants** — Built-in support for `--continue`, `--resume`, and `--verbose` flags
- **Configurable** — 20+ settings via standard `g:` variables with buffer-local overrides

## Requirements

- Vim 8.2+ with `+terminal`
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and in `$PATH`
- Optional: Vim 8.2+ with `+popupwin` for floating window mode

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

### Manual

Copy the `plugin/`, `autoload/`, and `doc/` directories into `~/.vim/`.

After installing, generate help tags:

```vim
:helptags ALL
```

## Quick Start

Open Vim and press `<C-,>` (Ctrl+comma) to launch Claude Code in a terminal split at the bottom of the screen. Press `<C-,>` again to hide it, and again to bring it back — the session persists.

Run `:ClaudeCode` if you prefer using the command directly.

## Commands

| Command | Description |
|---|---|
| `:ClaudeCode` | Toggle the Claude Code terminal |
| `:ClaudeCodeContinue` | Toggle with `--continue` (resume last conversation) |
| `:ClaudeCodeResume` | Toggle with `--resume` (interactive conversation picker) |
| `:ClaudeCodeVerbose` | Toggle with `--verbose` (detailed logging) |

## Default Keymaps

### Normal mode

| Key | Action |
|---|---|
| `<C-,>` | Toggle Claude Code terminal |
| `<Leader>cC` | Toggle with `--continue` |
| `<Leader>cV` | Toggle with `--verbose` |

### Terminal mode (inside the Claude Code window)

| Key | Action |
|---|---|
| `<C-,>` | Toggle (hide) Claude Code terminal |
| `<C-h>` | Move to the window on the left |
| `<C-j>` | Move to the window below |
| `<C-k>` | Move to the window above |
| `<C-l>` | Move to the window on the right |

To disable all default keymaps and define your own:

```vim
let g:claude_code_map_keys = 0

nnoremap <Leader>cc :ClaudeCode<CR>
tnoremap <Leader>cc <C-\><C-n>:ClaudeCode<CR>
```

## Window Modes

Set `g:claude_code_position` to one of:

| Value | Layout |
|---|---|
| `'bottom'` | Horizontal split at the bottom (default) |
| `'top'` | Horizontal split at the top |
| `'left'` | Vertical split on the left |
| `'right'` | Vertical split on the right |
| `'float'` | Centered popup window (requires `+popupwin`) |
| `'tab'` | Dedicated tab page |

If `'float'` is selected but your Vim lacks `+popupwin`, the plugin falls back to `'bottom'`.

```vim
" Example: vertical split on the right taking 40% of the screen
let g:claude_code_position = 'right'
let g:claude_code_split_ratio = 0.4
```

```vim
" Example: floating popup with double border
let g:claude_code_position = 'float'
let g:claude_code_float_width = 0.85
let g:claude_code_float_height = 0.85
let g:claude_code_float_border = 'double'
```

## Configuration

All options are set via `g:claude_code_*` variables in your `vimrc`. Buffer-local `b:claude_code_*` overrides are also supported.

### General

| Variable | Default | Description |
|---|---|---|
| `g:claude_code_command` | `'claude'` | CLI executable name |
| `g:claude_code_position` | `'bottom'` | Window layout (`bottom`, `top`, `left`, `right`, `float`, `tab`) |
| `g:claude_code_split_ratio` | `0.3` | Terminal size as fraction of screen (0.0 - 1.0) |
| `g:claude_code_enter_insert` | `1` | Auto-enter terminal mode when focusing the window |
| `g:claude_code_hide_numbers` | `1` | Hide line numbers in the terminal window |
| `g:claude_code_hide_signcolumn` | `1` | Hide the sign column in the terminal window |
| `g:claude_code_map_keys` | `1` | Register default keymaps (set `0` to define your own) |

### Floating Window

| Variable | Default | Description |
|---|---|---|
| `g:claude_code_float_width` | `0.8` | Popup width as fraction of the editor |
| `g:claude_code_float_height` | `0.8` | Popup height as fraction of the editor |
| `g:claude_code_float_border` | `'rounded'` | Border style: `rounded`, `single`, `double`, `solid`, `none` |

### Git Integration

| Variable | Default | Description |
|---|---|---|
| `g:claude_code_use_git_root` | `1` | Start Claude in the git repository root |
| `g:claude_code_multi_instance` | `1` | Maintain separate terminals per git repository |

### File Refresh

| Variable | Default | Description |
|---|---|---|
| `g:claude_code_refresh_enable` | `1` | Enable automatic file-change detection |
| `g:claude_code_refresh_interval` | `1000` | Polling interval in milliseconds |
| `g:claude_code_refresh_notify` | `1` | Show a message when buffers are reloaded |

### Command Variants

| Variable | Default | Description |
|---|---|---|
| `g:claude_code_variant_continue` | `'--continue'` | CLI flag for `:ClaudeCodeContinue` |
| `g:claude_code_variant_resume` | `'--resume'` | CLI flag for `:ClaudeCodeResume` |
| `g:claude_code_variant_verbose` | `'--verbose'` | CLI flag for `:ClaudeCodeVerbose` |

### Keymap Customization

| Variable | Default | Description |
|---|---|---|
| `g:claude_code_map_toggle` | `'<C-,>'` | Toggle key (normal + terminal mode) |
| `g:claude_code_map_continue` | `'<Leader>cC'` | Continue variant key (normal mode) |
| `g:claude_code_map_verbose` | `'<Leader>cV'` | Verbose variant key (normal mode) |

## How It Works

### Terminal Management

The plugin uses Vim's built-in `term_start()` to run the Claude Code CLI in a managed terminal buffer. Toggling hides/shows the window while preserving the terminal session and conversation state.

### File Refresh

When Claude modifies files on disk, the plugin detects changes and reloads affected buffers automatically. This works through:

1. Lowered `updatetime` while a Claude terminal is active (triggers faster `CursorHold` events)
2. Autocommands on `CursorHold`, `FocusGained`, `BufEnter`, and `InsertLeave` that run `:checktime`
3. A background timer polling every `g:claude_code_refresh_interval` milliseconds

The original `updatetime` is restored when the last Claude terminal closes.

### Git Integration

When `g:claude_code_use_git_root` is enabled, the plugin detects the repository root via `git rev-parse` and starts Claude there. With `g:claude_code_multi_instance` enabled, each git repository gets its own independent terminal instance.

## Plugin Structure

```
claude-code.vim/
├── plugin/
│   └── claude_code.vim          # Entry point: commands and keymaps
├── autoload/
│   └── claude_code/
│       ├── config.vim           # Configuration defaults and access
│       ├── terminal.vim         # Terminal lifecycle (create/toggle/close)
│       ├── window.vim           # Window layout (split/float/tab)
│       ├── git.vim              # Git root detection with caching
│       ├── keymaps.vim          # Terminal-local keymap setup
│       └── refresh.vim          # File change detection and reload
└── doc/
    └── claude_code.txt          # Vim :help documentation
```

## Help

Full documentation is available inside Vim:

```vim
:help claude-code
```

## License

MIT
