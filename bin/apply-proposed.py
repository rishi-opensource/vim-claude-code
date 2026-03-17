#!/usr/bin/env python3
"""Compute proposed file content from a Claude Code hook JSON.

Usage:
    python3 apply-proposed.py <hook_json_path> <output_path>

Reads the hook JSON, applies the Edit/Write/MultiEdit operation to produce
the proposed file content, and writes it to <output_path>.
"""
import json
import sys


def apply_edit(content, old_string, new_string, replace_all=False):
    if not old_string:
        return content
    if replace_all:
        return content.replace(old_string, new_string)
    return content.replace(old_string, new_string, 1)


def main():
    if len(sys.argv) < 3:
        print("Usage: apply-proposed.py <hook_json_path> <output_path>", file=sys.stderr)
        sys.exit(1)

    hook_json_path = sys.argv[1]
    output_path = sys.argv[2]

    with open(hook_json_path) as f:
        data = json.load(f)

    tool_name = data["tool_name"]
    tool_input = data["tool_input"]
    file_path = tool_input["file_path"]

    # Read original file content
    try:
        with open(file_path) as f:
            content = f.read()
    except FileNotFoundError:
        content = ""

    if tool_name == "Edit":
        old_string = tool_input.get("old_string", "")
        new_string = tool_input.get("new_string", "")
        replace_all = tool_input.get("replace_all", False)
        proposed = apply_edit(content, old_string, new_string, replace_all)

    elif tool_name == "Write":
        proposed = tool_input.get("content", "")

    elif tool_name == "MultiEdit":
        proposed = content
        for edit in tool_input.get("edits", []):
            old = edit.get("old_string", "")
            new = edit.get("new_string", "")
            if not old:
                # Empty old_string means prepend
                proposed = new + proposed
            else:
                pos = proposed.find(old)
                if pos >= 0:
                    proposed = proposed[:pos] + new + proposed[pos + len(old):]
                # If not found, skip silently (matches Claude Code behavior)
    else:
        proposed = content

    with open(output_path, "w") as f:
        f.write(proposed)


if __name__ == "__main__":
    main()
