# Superpack: python-quality

After-write feedback for Python: `ruff check` and [Astral **ty**](https://docs.astral.sh/ty/) on the touched file.

## Hooks

| Hook | Role |
|------|------|
| [`ruff-after-edit.py`](../../hooks/quality/ruff-after-edit.py) | `ruff check <file>` or `uv run ruff check <file>` |
| [`ty-after-edit.py`](../../hooks/quality/ty-after-edit.py) | `ty check <file>` or `uv run ty check <file>` |

## Install

Use the agent example file and keep the `ruff-after-edit` and `ty-after-edit` entries (drop either if you do not want that tool); remove other hooks if you want a minimal config:

- [`claude-code/settings.json`](../../claude-code/settings.json)
- [`cursor/hooks.json`](../../cursor/hooks.json)
- [`codex/hooks.json`](../../codex/hooks.json)

Then adjust hook paths to match where you vendored `hooks/`.
