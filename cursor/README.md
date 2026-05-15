# Cursor

Copy [`hooks/`](../hooks/) into your repo, then copy [`hooks.json`](hooks.json) to **`.cursor/hooks.json`**.

## Which binary

- **`hooks/security/*.sh`** — `bash` + **`jq`**.
- **`hooks/quality/*.sh`** (ESLint, Prettier) — **bash**, **`jq`**, and **Node (`npx`)**.
- **`hooks/quality/*.py`** — **Python 3.10+** plus ruff / ty / test runner.

Docs: [Cursor agent hooks](https://cursor.com/docs/agent/hooks).

## Example

```bash
bash "$(git rev-parse --show-toplevel)/hooks/security/block-dangerous-shell.sh"
```

## Matchers / fail closed

Matchers are **JavaScript-style** regexes. Use `"failClosed": true` on read/shell gates.

## Stop hook

Cursor `stop` only supports `followup_message`; [`test-before-stop.py`](../hooks/quality/test-before-stop.py) uses a follow-up when tests fail.
