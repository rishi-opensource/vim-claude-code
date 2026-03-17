#!/usr/bin/env bash
# vim-preview-diff.sh — PreToolUse hook for Claude Code
# Intercepts Edit/Write/MultiEdit, computes proposed file content,
# and triggers a diff preview in Vim via file-based IPC (+ clientserver if available).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Read the full hook JSON from stdin
INPUT="$(cat)"

TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name')"

# Only handle file-editing tools
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

CWD="$(echo "$INPUT" | jq -r '.cwd')"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path')"

TMPDIR="${TMPDIR:-/tmp}"
ORIG_FILE="$TMPDIR/claude-vim-diff-original"
PROP_FILE="$TMPDIR/claude-vim-diff-proposed"
HOOK_JSON="$TMPDIR/claude-vim-hook-input.json"
TRIGGER_FILE="$TMPDIR/claude-vim-diff-trigger.json"

# --- Copy original file ---
if [[ -f "$FILE_PATH" ]]; then
  cp "$FILE_PATH" "$ORIG_FILE"
else
  > "$ORIG_FILE"
fi

# --- Compute proposed content ---
echo "$INPUT" > "$HOOK_JSON"
python3 "$SCRIPT_DIR/apply-proposed.py" "$HOOK_JSON" "$PROP_FILE"

# --- Write trigger file for Vim's polling timer ---
DISPLAY_NAME="${FILE_PATH#"$CWD/"}"
jq -n \
  --arg orig "$ORIG_FILE" \
  --arg proposed "$PROP_FILE" \
  --arg name "$DISPLAY_NAME" \
  '{orig: $orig, proposed: $proposed, display_name: $name}' > "$TRIGGER_FILE"

# --- Try vim --servername for instant response (optional) ---
if command -v vim &>/dev/null; then
  VIM_SERVERS="$(vim --serverlist 2>/dev/null || true)"
  if [[ -n "$VIM_SERVERS" ]]; then
    FIRST_SERVER="$(echo "$VIM_SERVERS" | head -1)"
    vim --servername "$FIRST_SERVER" \
      --remote-expr "claude_code#diff#handle_trigger()" 2>/dev/null || true
  fi
fi

# --- Ask for user confirmation (Claude CLI shows accept/reject prompt) ---
REASON="Diff preview opened in Vim. Review before accepting."
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$REASON"
