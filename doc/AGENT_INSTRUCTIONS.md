# Vim-Claude-Code Agent Instructions

This document provides context and rules for AI agents (like Antigravity) working on the `vim-claude-code` project. Please review these instructions before making any architectural or codebase changes.

## 1. Core Technology Stack
- **Language**: Written strictly in **Legacy Vimscript (Vim 8+)**. Do *not* use Vim9 script syntax.
- **Dependencies**: The plugin relies on the `+terminal` feature built into Vim 8+. Do not introduce external UI frameworks, browser APIs, or Neovim-only features (e.g., Lua APIs or Neovim floating windows), as native Vim 8 compatibility is the primary goal.
- **External CLI**: Interacts with the Anthropic `claude` CLI. Assume it is available in the user's `$PATH`.

## 2. Architecture & File Structure
The project follows a standard, clean Vim plugin structure utilizing the `autoload` pattern for lazy loading:

- **`plugin/claude_code.vim`**: This is the entry point. Keep it minimal. It should solely define the global `:Claude` command (which acts as a dispatcher) and the default keymaps.
- **`autoload/claude_code/`**: All core logic lives here, split into modular files:
  - `commands.vim`, `git_commands.vim`, `arch_commands.vim`, `workflow_commands.vim`, `meta_commands.vim`: Handlers for various `:Claude <subcommand>` invocations.
  - `terminal.vim`, `terminal_bridge.vim`: Manage the Vim `+terminal` lifecycle, window splits, and sending prompts to the Claude CLI.
  - `config.vim`: Defines defaults and getters/setters for configuration variables.
  - `util.vim`: Shared helpers for text selection, context extraction, and error handling.
- **`test/`**: Uses the Vader test framework (`test_dispatch.vader`). Always add or update tests here when modifying command dispatching or core utility logic.

## 3. Coding Conventions

### Command Dispatching
- The plugin exposes a **single unified command**: `:Claude <subcommand>`.
- Never create new top-level commands (e.g., do not create `:ClaudeExplain`). Instead, add an `explain` subcommand to the dispatcher in `plugin/claude_code.vim` and route it to an autoload function like `claude_code#commands#explain()`.

### Variables & Configuration
- **Global Config**: Prefix all global configuration variables with `g:claude_code_` (e.g., `g:claude_code_position`).
- **Buffer Overrides**: Respect buffer-local overrides prefixed with `b:claude_code_`. The code should check `b:` before falling back to `g:`.
- **Internal Variables**: Prefix script-local variables with `s:` and plugin-internal global state variables carefully to avoid polluting the global namespace.

### Keymaps
- The default extended keymap prefix is `<Leader>c`.
- Provide `<Plug>` mappings for all actions so users can easily remap them without conflicts.
- Always check config flags (like `g:claude_code_map_keys` and `g:claude_code_map_extended_keys`) before mapping keys.

## 4. Workflows & Features
- **Health Checks**: If adding a new system dependency or configuration requirement, update the `:Claude doctor` subcommand logic (usually in `meta_commands.vim`) so the tool can self-diagnose user issues.
- **Context Awareness**: Commands should be aware of both normal mode (acting on the whole file or current function) and visual mode (acting on the user's text selection).


