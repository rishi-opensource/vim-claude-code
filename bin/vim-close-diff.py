#!/usr/bin/env python3
"""
vim-close-diff.py — PostToolUse hook for Claude Code
"""
import sys
import os
import subprocess

def main():
    try:
        sys.stdin.read()
    except Exception:
        pass

    cwd = os.getcwd()
    claude_dir = os.path.join(cwd, ".claude", "tmp")
    prefix = os.path.join(claude_dir, "claude-vim-diff")
    close_trigger = f"{prefix}-close"

    os.makedirs(claude_dir, exist_ok=True)

    # Write close trigger
    with open(close_trigger, "w") as f:
        f.write("1")

    # Try IPC
    try:
        servers = subprocess.check_output(["vim", "--serverlist"], stderr=subprocess.DEVNULL).decode('utf-8').strip().split('\n')
        if servers and servers[0]:
            subprocess.run(["vim", "--servername", servers[0], "--remote-expr", "claude_code#diff#close()"], stderr=subprocess.DEVNULL)
    except Exception:
        pass

    # Clean up temp files
    for ext in ["-original", "-proposed", "-trigger.json"]:
        try:
            os.remove(prefix + ext)
        except OSError:
            pass

    sys.exit(0)

if __name__ == "__main__":
    main()
