# Cursor

Copy [`hooks/`](../hooks/) into your repo, then copy [`hooks.json`](hooks.json) to **`.cursor/hooks.json`**.

## Which binary

- **`hooks/security/*.sh`** — `bash` + **`jq`**.
- **`hooks/quality/*.sh`** (ESLint, Prettier, **npm-test-before-stop**) — **bash**, **`jq`**, and **Node (`npx` / `npm`)** as needed.
- **`hooks/quality/*.py`** — **Python 3.10+** plus ruff, ty, and **pytest-before-stop** (pytest on `PATH`).

Docs: [Cursor agent hooks](https://cursor.com/docs/agent/hooks).

## Example

```bash
bash "$(git rev-parse --show-toplevel)/hooks/security/block-dangerous-shell.sh"
```

## Matchers / fail closed

Matchers are **JavaScript-style** regexes. Use `"failClosed": true` on read/shell gates.

## Stop hook

Cursor `stop` only supports `followup_message`; [`pytest-before-stop.py`](../hooks/quality/pytest-before-stop.py) and [`npm-test-before-stop.sh`](../hooks/quality/npm-test-before-stop.sh) use a follow-up when the respective test run fails.
