# Claude Code

Copy [`hooks/`](../hooks/) into your repo, then merge [`settings.json`](settings.json) into [`.claude/settings.json`](https://code.claude.com/docs/en/hooks.md) (or another supported Claude Code settings file).

## Which binary

- **`hooks/security/*.sh`** — `bash` + **`jq`** on `PATH` (no Python).
- **`hooks/quality/*.sh`** (ESLint, Prettier) — **bash**, **`jq`**, and **Node (`npx`)**.
- **`hooks/quality/*.py`** — **Python 3.10+** plus your tools (`ruff`, `ty`, `pytest`, etc.).

## Example command

```bash
bash "$(git rev-parse --show-toplevel)/hooks/security/block-dangerous-shell.sh"
```

## Blocking

Claude Code accepts **exit code 2** or JSON `permissionDecision: deny` on **exit 0**. The shell hooks emit stdout JSON (exit 0) for denies.
