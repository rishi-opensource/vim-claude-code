#!/usr/bin/env bash
# vim-close-diff.sh — PostToolUse hook for Claude Code
# Closes the diff preview tab in Vim after the user accepts or rejects.

# Read stdin (PostToolUse sends JSON but we don't need it)
cat > /dev/null

TMPDIR="${TMPDIR:-/tmp}"
CLOSE_TRIGGER="$TMPDIR/claude-vim-diff-close"

# Write close trigger for Vim's polling timer
touch "$CLOSE_TRIGGER"

# Try vim --servername for instant response (optional)
if command -v vim &>/dev/null; then
  VIM_SERVERS="$(vim --serverlist 2>/dev/null || true)"
  if [[ -n "$VIM_SERVERS" ]]; then
    FIRST_SERVER="$(echo "$VIM_SERVERS" | head -1)"
    vim --servername "$FIRST_SERVER" \
      --remote-expr "claude_code#diff#close()" 2>/dev/null || true
  fi
fi

# Clean up temp files
rm -f "$TMPDIR/claude-vim-diff-original" \
      "$TMPDIR/claude-vim-diff-proposed" \
      "$TMPDIR/claude-vim-hook-input.json"

exit 0
