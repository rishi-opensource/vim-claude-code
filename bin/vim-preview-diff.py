#!/usr/bin/env python3
"""
vim-preview-diff.py — PreToolUse hook for Claude Code
Intercepts Edit/Write/MultiEdit, computes proposed file content natively in Python
(removing the `jq` dependency), isolates temp files inside the repository's `.claude/` directory,
and triggers a diff preview in Vim.
"""
import sys
import json
import os
import subprocess

def apply_edit(content, old_string, new_string, replace_all=False):
    if not old_string:
        return content
    if replace_all:
        return content.replace(old_string, new_string)
    
    # Simple MultiEdit/Edit replacement. 
    return content.replace(old_string, new_string, 1)

def main():
    # Read stdin
    try:
        input_data = sys.stdin.read()
        data = json.loads(input_data)
    except Exception:
        sys.exit(0)

    tool_name = data.get("tool_name")
    if tool_name not in ("Edit", "Write", "MultiEdit"):
        sys.exit(0)

    cwd = data.get("cwd", os.getcwd())
    tool_input = data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")
    if not file_path:
        sys.exit(0)

    # Secure temp file prefix inside the repo itself!
    claude_dir = os.path.join(cwd, ".claude", "tmp")
    os.makedirs(claude_dir, exist_ok=True)
    
    prefix = os.path.join(claude_dir, "claude-vim-diff")
    orig_file = f"{prefix}-original"
    prop_file = f"{prefix}-proposed"
    trigger_file = f"{prefix}-trigger.json"

    # Read original file
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        content = ""

    # Write original file payload
    with open(orig_file, "w", encoding="utf-8") as f:
        f.write(content)

    # Compute proposed
    proposed = content
    if tool_name == "Edit":
        old_string = tool_input.get("old_string", "")
        new_string = tool_input.get("new_string", "")
        replace_all = tool_input.get("replace_all", False)
        proposed = apply_edit(content, old_string, new_string, replace_all)

    elif tool_name == "Write":
        proposed = tool_input.get("content", "")

    elif tool_name == "MultiEdit":
        for edit in tool_input.get("edits", []):
            old = edit.get("old_string", "")
            new = edit.get("new_string", "")
            if not old:
                proposed = new + proposed
            else:
                proposed = proposed.replace(old, new, 1)

    with open(prop_file, "w", encoding="utf-8") as f:
        f.write(proposed)

    # Write trigger file for Vim
    display_name = file_path[len(cwd)+1:] if file_path.startswith(cwd) else file_path
    
    trigger_data = {
        "orig": orig_file,
        "proposed": prop_file,
        "display_name": display_name
    }
    with open(trigger_file, "w", encoding="utf-8") as f:
        json.dump(trigger_data, f)

    # Try IPC
    try:
        servers = subprocess.check_output(["vim", "--serverlist"], stderr=subprocess.DEVNULL).decode('utf-8').strip().split('\n')
        if servers and servers[0]:
            subprocess.run(["vim", "--servername", servers[0], "--remote-expr", "claude_code#diff#handle_trigger()"], stderr=subprocess.DEVNULL)
    except Exception:
        pass

    # Ask for user confirmation
    reason = "Diff preview opened in Vim. Review before accepting."
    response = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": reason
        }
    }
    print(json.dumps(response))

if __name__ == "__main__":
    main()
