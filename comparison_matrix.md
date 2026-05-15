# Hook capability matrix (Claude Code, Cursor, Codex)

This repository targets three coding agents: Claude Code, Cursor, and Codex. Each hook is a **single file** (`*.sh` for security, TS lint/format checks, and the npm stop gate; `*.py` for Python lint, typing, and the pytest stop gate). Optional git/CI fallbacks are described in each agent README ([`claude-code/README.md`](../claude-code/README.md), [`cursor/README.md`](../cursor/README.md), [`codex/README.md`](../codex/README.md)).

| Capability | Claude Code | Cursor | Codex |
|------------|-------------|--------|--------|
| Writes confined to workspace (built-in) | Partial (depends on sandbox / permissions) | Yes by default (sandbox) | Yes by default (`workspace-write`) |
| Pre-tool / pre-shell block | Yes (`PreToolUse`, exit 2 or JSON `permissionDecision`) | Yes (`preToolUse`, `beforeShellExecution`; stdout `permission`) | Yes (`PreToolUse`; JSON `permissionDecision`) |
| Block reads (secrets) | Yes (`PreToolUse` on Read) | Yes (`beforeReadFile` + `preToolUse` Read; use `failClosed`) | Yes (`PreToolUse` Read) |
| Post-tool feedback (lint) | Yes (`PostToolUse`; `additionalContext` in `hookSpecificOutput`) | Yes (`postToolUse`; `additional_context`) | Yes (`PostToolUse`; Claude-shaped `hookSpecificOutput`) |
| Stop / completion gate | Yes (`Stop`; `decision: "block"` continues with reason) | Partial: `stop` only supports `followup_message` (auto follow-up) | Yes (`Stop`; `decision: "block"` continues per Codex docs) |
| Project trust for local hooks | Claude project settings | Project `.cursor/hooks.json` | `.codex/` must be trusted for project hooks |
| Config locations | `.claude/settings.json` (and managed layers) | `.cursor/hooks.json` | `.codex/hooks.json` or `[hooks]` in `config.toml` |

## References

- [Claude Code hooks](https://code.claude.com/docs/en/hooks.md)
- [Cursor hooks](https://cursor.com/docs/agent/hooks)
- [Codex hooks](https://developers.openai.com/codex/hooks)
