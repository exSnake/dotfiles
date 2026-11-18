#!/usr/bin/env python3
"""Register the dotfiles' Claude Code hooks in ~/.claude/settings.json.

Idempotent: adds only the entries that are missing and leaves every other
hook and setting as it is.
"""

import json
from pathlib import Path

SETTINGS = Path.home() / ".claude/settings.json"
TAB_TITLE = 'python3 "' + str(Path.home() / ".claude/scripts/tab-title.py") + '"'
HOOKS = {
    "Stop": TAB_TITLE,
    "SessionStart": TAB_TITLE,
}


def main() -> None:
    settings = json.loads(SETTINGS.read_text()) if SETTINGS.exists() else {}
    hooks = settings.setdefault("hooks", {})
    added = []
    for event, command in HOOKS.items():
        groups = hooks.setdefault(event, [])
        if any(h.get("command") == command for g in groups for h in g.get("hooks", [])):
            continue
        groups.append({"hooks": [{"type": "command", "command": command, "timeout": 5}]})
        added.append(event)
    if added:
        SETTINGS.parent.mkdir(parents=True, exist_ok=True)
        SETTINGS.write_text(json.dumps(settings, indent=2, ensure_ascii=False) + "\n")
        print(f"→  hook Claude Code aggiunti: {', '.join(added)}")
    else:
        print(f"✓  hook Claude Code già registrati in {SETTINGS}")


if __name__ == "__main__":
    main()
