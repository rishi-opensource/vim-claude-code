# 🚀 vim-claude-code: Claude Code CLI Integration for Vim

Vim is powerful.  
Claude Code CLI is powerful.  
So I built a clean integration between them.

👉 **vim-claude-code** integrates the Claude Code CLI directly inside Vim using the built-in terminal feature.

GitHub: https://github.com/rishi-opensource/vim-claude-code

---

## ✨ What This Plugin Actually Does

This plugin provides a single unified command:

```
:Claude <subcommand>
```

It acts as a dispatcher that routes to different Claude-powered workflows.

If no subcommand is provided:

```
:Claude
```

It toggles the Claude terminal.

---

## 🧠 Available Subcommands

The plugin currently supports:

### Core Development
- `:Claude explain`
- `:Claude fix`
- `:Claude refactor`
- `:Claude test`
- `:Claude doc`

### Git Workflows
- `:Claude commit`
- `:Claude review`
- `:Claude pr`

### Architecture / Analysis
- `:Claude plan`
- `:Claude analyze`

### Workflow Utilities
- `:Claude rename`
- `:Claude optimize`
- `:Claude debug`
- `:Claude apply`

### Meta / System
- `:Claude chat`
- `:Claude context`
- `:Claude model`
- `:Claude version`
- `:Claude doctor`
- `:Claude continue`
- `:Claude resume`
- `:Claude verbose`

All subcommands are implemented through a single dispatcher inside `plugin/claude_code.vim`.

---

## ⚙️ Technical Architecture

This plugin is written in **Vimscript (not Vim9)** and requires:

- Vim 8.0+
- `+terminal` support

Core architecture:

- `plugin/claude_code.vim`  
  Defines the `:Claude` command and subcommand dispatcher.

- `autoload/claude_code/*`  
  Modularized logic for:
  - commands
  - git workflows
  - architecture tools
  - workflow automation
  - terminal integration
  - configuration
  - utilities

The plugin uses Vim's built-in **terminal feature** to run Claude Code CLI and manage interaction inside Vim.

It does not depend on:
- Browser APIs
- External UI frameworks
- Neovim-only features

---

## 🖥 How It Works Internally

High-level flow:

1. User runs `:Claude <subcommand>`
2. Dispatcher parses the first argument
3. Routes to the correct autoload module
4. Opens or reuses a terminal buffer
5. Executes Claude Code CLI with proper context

Visual mode mappings are also supported, so selected code can be sent directly to Claude.

---

## ⌨ Default Keymaps (Configurable)

If enabled in configuration:

Normal mode examples:

```
<Leader>ce  → :Claude explain
<Leader>cf  → :Claude fix
<Leader>cr  → :Claude refactor
<Leader>ct  → :Claude test
<Leader>cd  → :Claude doc
```

There are also mappings for:
- commit
- review
- plan
- analyze
- rename
- optimize
- debug
- chat
- context
- model

All mappings are configurable via plugin config.

---

## 🧩 Why This Plugin Is Different

- Single clean command dispatcher (`:Claude`)
- Modular autoload architecture
- Deep Git workflow integration
- Architecture + complexity analysis commands
- Health check via `:Claude doctor`
- Model switching support
- Terminal-based integration (native Vim)

This is not just a “send prompt to AI” wrapper —  
it’s structured around real development workflows.

---

## 📦 Requirements

- Vim 8.0+
- Compiled with `+terminal`
- Claude Code CLI installed and available in PATH

---

## 🎯 Example Usage

Explain selected code:

```
:Claude explain
```

Generate tests:

```
:Claude test
```

Analyze architecture:

```
:Claude analyze
```

Check setup health:

```
:Claude doctor
```

---

## 👨‍💻 Who Is This For?

- Vim users who want AI assistance inside the editor
- Developers using Claude Code CLI
- Engineers who prefer terminal-native workflows
- People building structured AI-driven development pipelines

---

## 🙌 Feedback Welcome

If you use Vim and Claude Code CLI, I’d love feedback.

⭐ Star the repo  
🐛 Open issues  
💬 Suggest improvements  

GitHub: https://github.com/rishi-opensource/vim-claude-code

---

Built with focus on clean architecture, extensibility, and real developer workflows.