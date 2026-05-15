#!/usr/bin/env python3
"""Stop hook: run ``pytest -q`` at cwd when a Python project is detected. Requires Python 3.10+."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from enum import Enum
from pathlib import Path
from typing import Any


class Host(str, Enum):
    CURSOR = "cursor"
    CLAUDE = "claude-code"
    CODEX = "codex"


def _read_stdin() -> dict[str, Any]:
    raw = sys.stdin.read()
    return json.loads(raw) if raw.strip() else {}


def _write_out(obj: dict[str, Any]) -> None:
    sys.stdout.write(json.dumps(obj, ensure_ascii=False))
    sys.stdout.flush()


def _detect_host(data: dict[str, Any]) -> Host:
    o = os.environ.get("AI_HOOKS_AGENT", "").strip().lower()
    if o in ("cursor", "claude-code", "codex"):
        return Host(o)
    if "loop_count" in data and "status" in data and "hook_event_name" not in data:
        return Host.CURSOR
    if data.get("hook_event_name"):
        return Host.CLAUDE
    if isinstance(data.get("command"), str) and "tool_name" not in data:
        return Host.CURSOR
    if data.get("tool_name") and "hook_event_name" not in data:
        return Host.CURSOR
    if data.get("file_path") and "hook_event_name" not in data:
        return Host.CURSOR
    return Host.CLAUDE


def _allow_empty(host: Host, data: dict[str, Any]) -> dict[str, Any]:
    if host is Host.CURSOR:
        if "loop_count" in data and "status" in data:
            return {}
        return {"permission": "allow"}
    return {}


def _cwd(data: dict[str, Any]) -> Path:
    return Path(str(data.get("cwd") or os.getcwd())).resolve()


def _run_pytest(cwd: Path, timeout: int = 600) -> tuple[bool, str]:
    if not (cwd / "pyproject.toml").exists() and not (cwd / "setup.py").exists():
        return True, "no pyproject.toml or setup.py; skipped"
    pytest = shutil.which("pytest")
    if not pytest:
        return True, "pytest not installed; skipped"
    p = subprocess.run(
        [pytest, "-q"],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False,
    )
    tail = (p.stdout + "\n" + p.stderr)[-8000:]
    return p.returncode == 0, tail or "(empty output)"


def main() -> int:
    data = _read_stdin()
    host = _detect_host(data)
    cwd = _cwd(data)
    ok, details = _run_pytest(cwd)
    if ok:
        _write_out(_allow_empty(host, data))
        return 0
    msg = "pytest failed; fix failures before finishing.\n" + details
    if host is Host.CURSOR:
        _write_out({"followup_message": msg[:8000]})
        return 0
    if host is Host.CODEX:
        _write_out({"decision": "block", "reason": msg})
        return 0
    _write_out({"decision": "block", "reason": msg})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
