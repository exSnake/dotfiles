#!/usr/bin/env python3
"""Claude Code hook: name the iTerm2 tab after the session's PR.

Wire it to Stop and SessionStart. It reads the hook payload on stdin, detaches,
and sets the session name with iTerm2's `it2`:

    <project>: #<pr> <pr title> (<state>)     the last PR the session touched
    <project>: <topic> · #<pr> merged          that PR is merged or closed
    <project>: <topic>                         no PR yet

<project> is the first directory under ~/source (sossoldi, betech, ...).
<topic> is the title Claude Code generates for the session.
The PR comes from the `pr-link` records Claude Code writes in the transcript.

Set CC_TAB_TITLE=off in a session's environment to leave its tab alone.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

IT2 = Path.home() / ".config/iterm2/it2"
GH = shutil.which("gh") or "/opt/homebrew/bin/gh"
CACHE = Path.home() / ".cache/cc-tab-title"
SOURCE = Path.home() / "source"
OPEN_PR_TTL = 300
TAIL_BYTES = 4 * 1024 * 1024
MAX_TOPIC = 45


def project_label(cwd: str) -> str:
    path = Path(cwd)
    try:
        return path.relative_to(SOURCE).parts[0]
    except (ValueError, IndexError):
        return path.name or "~"


def read_tail(path: Path) -> list[dict]:
    size = path.stat().st_size
    with path.open("rb") as f:
        f.seek(max(0, size - TAIL_BYTES))
        lines = f.read().splitlines()
    records = []
    for line in lines:
        if b'"pr-link"' in line or b'"ai-title"' in line:
            try:
                records.append(json.loads(line))
            except ValueError:
                pass
    return records


def last_pr_and_topic(transcript: Path) -> tuple[dict | None, str | None]:
    pr, topic = None, None
    for record in read_tail(transcript):
        if record.get("type") == "pr-link":
            pr = record
        elif record.get("type") == "ai-title":
            topic = record.get("aiTitle")
    return pr, topic


def pr_info(repo: str, number: int) -> dict | None:
    CACHE.mkdir(parents=True, exist_ok=True)
    cached = CACHE / f"{repo.replace('/', '_')}_{number}.json"
    if cached.exists():
        data = json.loads(cached.read_text())
        if data["state"] != "OPEN" or time.time() - cached.stat().st_mtime < OPEN_PR_TTL:
            return data
    result = subprocess.run(
        [GH, "pr", "view", str(number), "-R", repo, "--json", "state,title"],
        capture_output=True, text=True, timeout=20,
    )
    if result.returncode != 0:
        return None
    cached.write_text(result.stdout)
    return json.loads(result.stdout)


def shorten(text: str) -> str:
    text = re.sub(r"^\w+(\([^)]*\))?!?:\s*", "", text)
    return text if len(text) <= MAX_TOPIC else text[: MAX_TOPIC - 1].rstrip() + "…"


def build_title(payload: dict) -> str | None:
    transcript = Path(payload.get("transcript_path") or "")
    if not transcript.is_file():
        return None
    label = project_label(payload.get("cwd") or os.getcwd())
    pr, topic = last_pr_and_topic(transcript)
    if pr:
        info = pr_info(pr["prRepository"], pr["prNumber"])
        if info and info["state"] == "OPEN":
            return f"{label}: #{pr['prNumber']} {shorten(info['title'])}"
        if info:
            state = info["state"].lower()
            if topic:
                return f"{label}: {shorten(topic)} · #{pr['prNumber']} {state}"
            return f"{label}: #{pr['prNumber']} {shorten(info['title'])} ({state})"
    return f"{label}: {shorten(topic)}" if topic else None


def set_name(iterm_session: str, title: str) -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    last = CACHE / f"tab_{iterm_session}"
    if last.exists() and last.read_text() == title:
        return
    subprocess.run([str(IT2), "session", "set-name", "--session", iterm_session, title],
                   capture_output=True, timeout=10)
    last.write_text(title)


def main() -> None:
    if os.environ.get("CC_TAB_TITLE") == "off" or not IT2.exists():
        return
    iterm_session = os.environ.get("ITERM_SESSION_ID", "").partition(":")[2]
    if not iterm_session:
        return
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return
    if os.fork():
        return
    os.setsid()
    devnull = os.open(os.devnull, os.O_RDWR)
    for fd in (0, 1, 2):
        os.dup2(devnull, fd)
    try:
        title = build_title(payload)
        if title:
            set_name(iterm_session, title)
    except Exception:
        pass
    os._exit(0)


if __name__ == "__main__":
    main()
