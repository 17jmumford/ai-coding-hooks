# ai-coding-hooks: Stop Wasting Tokens

Stop wasting tokens. Don't put instructions in your prompts to "never run rm -rf /" or "always run linter after file changes". Use hooks to automatically extend agent capabilities deterministically and reliably.

AI-first engineers use hooks to keep their codebases production safe and maintainable. Advantages include:

- Reliable: Never lose sleep that your agent will skip an instruction.
- Faster: Stop wasting tool calls and context windows on repeatable actions.
- Lower cost: Save millions of tokens by removing responsibilities from your agent.
- More secure: Extra guardrails on shell commands and secret reads.

## What are hooks?

> Hooks let you observe, control, and extend the agent loop using custom scripts.
> Hooks are spawned processes that communicate over stdio using JSON in both directions.
> They run before or after defined stages of the agent loop and can observe, block, or modify behavior.
>
> — [Cursor agent hooks](https://cursor.com/docs/agent/hooks)

Hooks let you inject scripts for the stuff you care about. For example, always run a type checker and linter after an agent edits a file. The hard part is knowing which hooks you should use.

## Quick start for Humans

Give your AI coding agent the link to this repo. They'll take it from there, and ask questions as needed. Alternatively, you can copy and paste stuff out on your own.

Hooks basically have two parts:

- The hook script itself under `hooks/` in this repo.
- The agent config JSON. We've included example configs along with readmes for each agent.

We've also created superpacks to group hooks by purpose.

This repo is full of useful hooks, organized by coding language, framework, and other categories. Your AI coding agent can figure out which of these are most useful. For example, if you are in a mature codebase that is already using Ruff, you'll want to use the Ruff hook. If you're in a new project, adding several hooks at the beginning can put guardrails on your codebase that keep it maintainable into production.

It's also very easy to copy and paste code from this repo. These are primarily bash and Python scripts, so they are highly portable.

## Detailed instructions for AI coding agents reading this

1. Copy only the hook files you need from `hooks/security/*.sh`, `hooks/quality/*.sh`, and/or `hooks/quality/*.py` into your project's `hooks/` tree (flat files—no shared `_lib`).
2. Copy a relevant example config into `.claude/settings.json`, `.cursor/hooks.json`, or `.codex/hooks.json`, merging with existing JSON if needed.
3. Delete hook entries you do not want. See a focused bundle in [`superpacks/`](superpacks/).
4. Replace `$(git rev-parse --show-toplevel)/hooks/...` with your vendored path if different.

Codex **Python** quality commands in [`codex/hooks.json`](codex/hooks.json) use `AI_HOOKS_AGENT=codex` so stdin/stdout routing matches Codex (the same variable is set for ESLint/Prettier so Codex-shaped feedback is consistent).
