# ai-coding-hooks

Portable hook scripts for AI coding agents (Cursor, Claude Code, Codex). Each hook is a small process that reads JSON from stdin and returns JSON on stdout so agents can block unsafe actions, run linters after edits, or gate completion on tests—without repeating those rules in every prompt.

Human-oriented overview: [README.md](README.md). Cross-agent behavior differences: [comparison_matrix.md](comparison_matrix.md).

## Layout

| Path | Purpose |
|------|---------|
| `hooks/security/` | Block dangerous shell commands and secret file reads |
| `hooks/quality/` | Post-edit lint/format checks and stop-time test gates |
| `cursor/hooks.json` | Example Cursor config (copy to `.cursor/hooks.json`) |
| `claude-code/settings.json` | Example Claude Code config |
| `codex/hooks.json` | Example Codex config |
| `superpacks/` / `superpack_guides/` | Curated hook bundles by concern |
| `adapters/` | JSON fragments for merging into existing configs |

## Vendoring hooks into a project

1. Copy only the scripts you need from `hooks/security/` and `hooks/quality/` into the target repo (keep them flat; do not depend on `hooks/_lib/`).
2. Copy the matching example config for the agent and merge with any existing hooks JSON.
3. Remove config entries for hooks you did not copy.
4. Point commands at your vendored path. Examples in this repo use `$(git rev-parse --show-toplevel)/hooks/...`.

For Codex, set `AI_HOOKS_AGENT=codex` on quality hook commands so stdout matches Codex’s expected shape (see `codex/hooks.json`).

## Adding a new hook to this repository

### 1. Pick the event and category

| Goal | Typical event | Config key (Cursor) |
|------|---------------|---------------------|
| Block shell / reads | Before tool or read | `beforeShellExecution`, `preToolUse`, `beforeReadFile` |
| Lint or format after a write | After edit | `postToolUse`, `afterFileEdit` |
| Run tests before the agent stops | Session end | `stop` |

Put security hooks under `hooks/security/`; lint, format, and test gates under `hooks/quality/`.

### 2. Implement a self-contained script

- **Bash** (`.sh`): security, Node/Go/Terraform CLI checks. Requires `bash` and usually `jq`.
- **Python** (`.py`): Python tooling. Requires Python 3.10+.

Conventions used by existing quality hooks:

- Read all of stdin as JSON; extract the edited path from `tool_input.file_path`, `file_path`, etc. (copy `edited_file()` from [hooks/quality/prettier-after-edit.sh](hooks/quality/prettier-after-edit.sh) or [hooks/quality/ruff-after-edit.py](hooks/quality/ruff-after-edit.py)).
- Filter by file extension; **exit 0 with `{}`** if the hook does not apply or the CLI is missing (fail open unless the config sets `failClosed`).
- On failure, return feedback—not a non-zero exit for quality hooks:
  - **Cursor**: `{ "additional_context": "..." }`
  - **Claude / Codex**: `{ "hookSpecificOutput": { "hookEventName": "PostToolUse", "additionalContext": "..." } }`
- Use `AI_HOOKS_AGENT` or the host-detection helpers in existing scripts when stdout shape differs by agent.
- `chmod +x` shell scripts.

### 3. Register in example configs

Add the same command to all three example files you want to support:

- [cursor/hooks.json](cursor/hooks.json) — use `matcher: "Write"` for post-edit hooks; set `failClosed: true` only for security gates.
- [claude-code/settings.json](claude-code/settings.json) — under `hooks.PostToolUse` / `PreToolUse` / `Stop` as appropriate.
- [codex/hooks.json](codex/hooks.json) — wrap with `env AI_HOOKS_AGENT=codex` for quality hooks.

### 4. Document (optional)

Add a row to a relevant `superpack_guides/*.md` or create a superpack if the hook belongs in a bundle.

## Existing quality hooks (reference)

| Script | Trigger | Tooling |
|--------|---------|---------|
| `eslint-after-edit.sh` | `.ts`, `.js`, … | `npx eslint` |
| `prettier-after-edit.sh` | same | `npx prettier --check` |
| `ruff-after-edit.py` | `.py` | `ruff check` |
| `ty-after-edit.py` | `.py` | `ty check` |
| `terraform-fmt-after-edit.sh` | `.tf`, `.tfvars`, `.hcl` | `terraform fmt -check` |
| `golangci-lint-after-edit.sh` | `.go` | `golangci-lint run --fix` then `run` |
| `pytest-before-stop.py` | stop | `pytest` |
| `npm-test-before-stop.sh` | stop | `npm test` |

## Agent docs

- [Cursor hooks](https://cursor.com/docs/agent/hooks)
- [Claude Code hooks](https://code.claude.com/docs/en/hooks.md)
- [Codex hooks](https://developers.openai.com/codex/hooks)
