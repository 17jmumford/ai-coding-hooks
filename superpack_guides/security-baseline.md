# Superpack: security-baseline

Deterministic guardrails: dangerous shell patterns and secret file reads.

**Harness overlap:** Cursor, Codex, and (with sandbox modes) Claude Code already limit **writes** to the workspace in many setups. This repo **no longer ships** `block-outside-repo-writes`—add your own policy if you disable sandboxes or need **git-root** semantics stricter than “workspace”.

**Shell hooks** (`hooks/security/*.sh`, `hooks/quality/eslint-after-edit.sh`, `hooks/quality/prettier-after-edit.sh`) need **`bash`** and **`jq`** on `PATH`, plus **Node/`npx`** for ESLint and Prettier. **Python quality hooks** (`hooks/quality/*.py`) need **Python 3.10+** plus your toolchain (`ruff`, `ty`, `pytest`, etc.).

## Hooks

| Hook | Role |
|------|------|
| [`block-dangerous-shell.sh`](../../hooks/security/block-dangerous-shell.sh) | Block destructive / `curl \| bash` style commands |
| [`block-secret-reads.sh`](../../hooks/security/block-secret-reads.sh) | Block reads of `.env`, SSH keys, `~/.aws/credentials`, etc. |

## Install

1. Vendor this repository so `hooks/` lives inside your project.
2. Start from the agent config in this repo and trim what you do not need:
   - Claude Code: [`claude-code/settings.json`](../../claude-code/settings.json) → merge into `.claude/settings.json`
   - Cursor: [`cursor/hooks.json`](../../cursor/hooks.json) → copy to `.cursor/hooks.json`
   - Codex: [`codex/hooks.json`](../../codex/hooks.json) → copy to `.codex/hooks.json`
3. Remove `PostToolUse`, `Stop`, `afterFileEdit`, etc. entries if you only want the security hooks.
4. Fix every `$(git rev-parse --show-toplevel)/hooks/...` path if your layout differs.

See each agent’s README under [`claude-code/`](../claude-code), [`cursor/`](../cursor), [`codex/`](../codex).
