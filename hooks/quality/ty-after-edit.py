#!/usr/bin/env python3
"""Self-contained: post-edit Astral ty check. Requires Python 3.10+ and `ty` or uv when used."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from enum import Enum
from pathlib import Path
from typing import Any, NamedTuple


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
    import os

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
        return {"permission": "allow"}
    return {}


def _edited_file(data: dict[str, Any]) -> str:
    ti = data.get("tool_input")
    if isinstance(ti, dict):
        for k in ("file_path", "path", "target_file"):
            v = ti.get(k)
            if isinstance(v, str):
                return v
    if isinstance(data.get("file_path"), str) and (
        "edits" in data or data.get("hook_event_name") == "PostToolUse"
    ):
        return str(data["file_path"])
    if data.get("hook_event_name") == "PostToolUse" and isinstance(data.get("file_path"), str):
        return str(data["file_path"])
    tn = str(data.get("tool_name") or "")
    if "Write" in tn or tn.endswith("Write"):
        if isinstance(ti, dict):
            for k in ("file_path", "path", "target_file"):
                v = ti.get(k)
                if isinstance(v, str):
                    return v
    return ""


def _cwd(data: dict[str, Any]) -> Path:
    import os

    return Path(str(data.get("cwd") or os.getcwd())).resolve()


class _Proc(NamedTuple):
    ok: bool
    stdout: str
    stderr: str
    cmd: list[str]


def _run(cmd: list[str], cwd: Path) -> _Proc:
    try:
        p = subprocess.run(
            cmd, cwd=str(cwd), capture_output=True, text=True, timeout=120, check=False
        )
        return _Proc(p.returncode == 0, p.stdout or "", p.stderr or "", cmd)
    except (OSError, subprocess.SubprocessError) as e:
        return _Proc(False, "", str(e), cmd)


def _ty(file_path: Path, cwd: Path) -> _Proc:
    ty = shutil.which("ty")
    if ty:
        return _run([ty, "check", str(file_path)], cwd)
    uv = shutil.which("uv")
    if uv:
        return _run([uv, "run", "ty", "check", str(file_path)], cwd)
    return _Proc(True, "", "", [])


def _feedback(host: Host, msg: str) -> dict[str, Any]:
    text = (msg or "").strip()
    if len(text) > 9500:
        text = text[:9500] + "\n…(truncated)"
    if host is Host.CURSOR:
        return {"additional_context": text} if text else {}
    if not text:
        return {}
    return {
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": text,
        }
    }


def main() -> int:
    data = _read_stdin()
    host = _detect_host(data)
    fp = _edited_file(data)
    if not fp:
        _write_out(_allow_empty(host, data))
        return 0
    path = Path(fp)
    if path.suffix != ".py":
        _write_out(_allow_empty(host, data))
        return 0
    cwd = _cwd(data)
    res = _ty(path, cwd)
    if res.ok or not res.cmd:
        _write_out(_allow_empty(host, data))
        return 0
    _write_out(_feedback(host, f"ty check failed on {path}:\n{res.stderr or res.stdout}"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
