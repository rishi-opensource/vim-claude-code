# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅ Yes    |
| < 1.0   | ❌ No     |

## Reporting a Vulnerability

Do **not** open a public issue for security bugs. Use GitHub's private
vulnerability reporting feature or contact the maintainers directly.

We aim to acknowledge within 48 hours and patch within 14 days.

---

## Security Model

### Local execution only

vim-claude-code is a Vim plugin that launches the Claude CLI in a Vim terminal
buffer. It does **not**:

- Make network requests from Vim itself.
- Send telemetry or usage data.
- Communicate with any server other than what the Claude CLI contacts.

All AI interactions go through the Claude CLI binary on your machine. The CLI
authenticates with Anthropic's API and handles prompt transmission. See
[Anthropic's privacy policy](https://www.anthropic.com/privacy) for server-side
data handling.

### Git operations are local

All `git` calls (`git diff`, `git log`, `git rev-parse`) are **read-only** and
run against your local repository. The plugin never pushes, commits, or modifies
history — those actions are suggested by Claude and require your confirmation.

Destructive file writes (`:Claude apply`) require explicit `y` confirmation
before proceeding.

### No remote code execution

The plugin executes only:

1. The `claude` binary (configurable via `g:claude_code_command`).
2. `git` subcommands for context gathering.
3. Shell builtins (`pushd`, `popd`) for directory management.

No URLs are fetched, no scripts are downloaded at runtime.

### Dependency trust

- **Claude CLI** — distributed by Anthropic. Verify the binary's provenance
  before installation.
- **Vader.vim** — used only in the test suite; never loaded in production.

## Hardening Tips

- Pin the plugin to a specific git tag in your plugin manager.
- Ensure `g:claude_code_command` points to the real Claude CLI binary.
- Audit your `PATH` so a rogue binary named `claude` cannot shadow the real one.
