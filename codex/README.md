# Codex

Copy [`hooks/`](../hooks/) into your repo, then copy [`hooks.json`](hooks.json) to **`.codex/hooks.json`** (or merge `hooks` into config).

## Which binary

- **`hooks/security/*.sh`** — `bash` + **`jq`** (no `AI_HOOKS_AGENT` needed).
- **`hooks/quality/*.py`** — **Python 3.10+** for ruff, ty, and test-before-stop; example config uses `env AI_HOOKS_AGENT=codex` so stdin/stdout routing matches Codex for those events.
- **`hooks/quality/eslint-after-edit.sh`** / **`prettier-after-edit.sh`** — **bash**, **`jq`**, and **Node (`npx`)** only (no Python).

Docs: [Codex hooks](https://developers.openai.com/codex/hooks).

## Trust

Project `.codex/` hooks must be **trusted** (`/hooks` in Codex).
