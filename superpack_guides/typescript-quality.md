# Superpack: typescript-quality

After-write feedback for TypeScript/JavaScript: ESLint and Prettier `--check` on the touched file.

## Hooks

| Hook | Role |
|------|------|
| [`eslint-after-edit.sh`](../../hooks/quality/eslint-after-edit.sh) | `npx eslint <file>` (bash + `jq` + Node) |
| [`prettier-after-edit.sh`](../../hooks/quality/prettier-after-edit.sh) | `npx prettier --check <file>` (bash + `jq` + Node) |

Requires `npx` and resolvable `eslint` / `prettier` for your project.

## Install

Use the agent example file, keep only the `eslint-after-edit` and `prettier-after-edit` commands (under `postToolUse` / `afterFileEdit` for Cursor, `PostToolUse` for Claude/Codex), and delete the rest if you do not want other hooks:

- [`claude-code/settings.json`](../../claude-code/settings.json)
- [`cursor/hooks.json`](../../cursor/hooks.json)
- [`codex/hooks.json`](../../codex/hooks.json)

Then adjust hook paths to match where you vendored `hooks/`.
