# Changelog

All notable changes to vim-claude-code are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [1.0.1] – 2026-02-24

### Fixed
- Restore scroll behaviour for Claude response split window
- Ensure standard Vim scrolling works on response buffer (line-up/down, mouse wheel, PageUp/PageDown)
- Resolved buffer options that prevented scrolling in certain terminals

### Improved
- Better buffer configuration for Claude output to support navigation and movement keys

## [1.0.0] — 2026-02-24

### Added

- **Version guard** — Plugin refuses to load on Vim < 8 with a clear `echoerr` message.
- **`g:claude_code_version`** — Plugin version constant (`"1.0.0"`).
- **`g:claude_code_debug`** — Debug mode flag (default `0`). When `1`, logs dispatch
  calls, git operations, terminal launches, and refresh events to the message area.
- **`:Claude version`** — Prints plugin version, Vim version, Claude CLI version
  (if installed), and terminal feature availability.
- **`:Claude doctor`** — Health check: reports `[OK]` / `[FAIL]` for Claude CLI,
  Git, terminal support, and Vim version with friendly guidance on failures.
- **`claude_code#util#error(msg)`** — Centralized error display using `ErrorMsg`
  highlight; replaces all inline `echohl ErrorMsg / echomsg / echohl None` blocks.
- **`claude_code#util#debug(msg)`** — Lightweight debug logger gated on
  `g:claude_code_debug`.
- **`claude_code#util#confirm(prompt)`** — Shared yes/no prompt helper.
- **Git safety** — `:Claude commit`, `:Claude review`, `:Claude pr` now verify
  `executable('git')` before running and emit a friendly error if git is absent.
- **Apply confirmation** — `:Claude apply` prompts
  `Apply changes to file <name>? (y/n)` before sending the destructive write
  instruction to Claude. Cancellable with `n`.
- **Terminal debug logging** — `terminal#toggle`, `s:create_new`, and refresh
  start now call `claude_code#util#debug()`.
- **Vader test suite** — `test/test_dispatch.vader` covers: plugin constants,
  util helpers, visual selection, config round-trips, git root detection, and
  terminal/meta command presence.
- **GitHub Actions CI** — `.github/workflows/ci.yml` runs tests on Vim stable
  and nightly.
- **`CHANGELOG.md`** — This file.
- **`SECURITY.md`** — Security policy: local-only execution model, no remote
  calls from Vim, local-only git operations.
- **`LICENSE`** — MIT license.

### Changed

- All internal error messages now route through `claude_code#util#error()`.
- Terminal creation failure uses the centralized error handler.
- `version` and `doctor` added to `:Claude <Tab>` completion.

---

## [0.x] — Pre-release

Initial development. No formal changelog kept.
