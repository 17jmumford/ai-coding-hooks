# ai-coding-hooks: Built by an AI Engineer for AI-first Engineers
Stop wasting tokens with Skills. Just use hooks!

People are telling their coding agents to run this linter, check that type checker, blah blah blah. It's a waste of tokens. You're burning tokens for deterministic processes that should run every time. 

AI-first engineers use hooks to keep their codebases production safe and maintainable.

## What is a hook?

```
Hooks let you observe, control, and extend the agent loop using custom scripts. Hooks are spawned processes that communicate over stdio using JSON in both directions. They run before or after defined stages of the agent loop and can observe, block, or modify behavior.
```
-- Cursor

Hooks let you inject scripts for the stuff you care about. For example, always run a type checker and linter after an agent edits a file. The hard part is know which hooks you should use. 

## How do I use this repo?

This repo is full of extremely useful hooks, organized by coding language, framework, and other categories.

Your AI coding agent can likely figure out which of these are most useful. For example, if you are in a mature codebase that is already using Ruff, you'll want to use the Ruff hook. If you're in a new project, adding several hooks at the beginning can put guardrails on your codebase that keep in maintainable into production.

It's also very easy to just copy/paste code from this repo. These are primarily bash scripts, so they are highly portable. 

## Why do things like linters and type checkers matter in AI coding?

I should hope the value of a type checker in large interconnected systems is obvious: Your AI coding agent doesn't realize that updating a class broke 37 functions across the codebase. 

Linters may seem less obvious on the surface: I'm not reading code anymore, why does it matter how it is formatted? Linters are actually MORE important than ever in the age of coding. For example, forcing a comment to be at the top of every file is one of the fastest ways to improve your AI coding agents ability to navigate a codebase. 
