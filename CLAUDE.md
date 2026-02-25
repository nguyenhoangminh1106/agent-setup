# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

## What this repo is

A set of reusable skill files (`.md` prompts) that are installed into Claude Code (`~/.claude/commands/`), Codex (`~/.codex/prompts/`), and Cursor (`~/.cursor/commands/`). The install script fetches each skill from GitHub and copies it to all three tool directories.

## Installing / updating skills

```bash
# Install all skills from GitHub (no clone needed)
curl -fsSL https://raw.githubusercontent.com/nguyenhoangminh1106/agent-setup/main/install.sh | bash

# Or, after cloning, run locally
./install.sh
```

The script installs these skills: `commit-push`, `pr-triage`, `branch-risk-review`, `worktree-create`, `worktree-remove`.

After editing skills locally, push and re-run `./install.sh` on other machines.

## Architecture

- `skills/*.md` — One file per skill. Each file is a self-contained prompt with YAML frontmatter (`name`, `description`, `arguments`) followed by procedural instructions for the agent.
- `install.sh` — Downloads each skill from the raw GitHub URL and copies it into the three tool directories. No build step; files are copied as-is.

## Adding a new skill

1. Create `skills/<name>.md` with YAML frontmatter and instructions.
2. Add `<name>` to the `SKILLS` array in `install.sh`.
3. Commit, push, and re-run `install.sh` to deploy.

## Core philosophy (reflected in all skills)

- Safety > cleverness; read-only unless explicitly permitted
- Minimal diff > ideal design; prefer containment over broad refactors
- Always ask before executing state-changing commands
- Never bypass hooks (`--no-verify`)
