# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

## What this repo is

A set of reusable skill files (`.md` prompts) that are installed into Claude Code (`~/.claude/commands/`), Codex (`~/.codex/skills/<name>/SKILL.md`), and Cursor (`~/.cursor/commands/`). The install script fetches each skill from GitHub and installs it in the correct format for each tool.

## Installing / updating skills

```bash
# Install all skills from GitHub (no clone needed)
curl -fsSL https://raw.githubusercontent.com/nguyenhoangminh1106/agent-setup/main/install.sh | bash

# Or, after cloning, run locally
./install.sh
```

The script installs these skills: `minimal-coding`, `commit-push`, `name-branch`, `name-commit`, `worktree-create`, `worktree-remove`, `resolve-conflicts-safely`, `branch-risk-review`, `clean-ai-comments`, `pr-description`, `pr-triage`, `clarify`, `argue-to-clarify`, `spec`, `fix-review`, `ticket`, `codebase-study-pack`, `daily-update`, `feature-summary`, `testing-instructions`, `db-unsync-fix`, `query-db`.

After editing skills locally, push and re-run `./install.sh` on other machines.

## Architecture

- `skills/` — Skills are organised into subfolders by category. Each skill file is a prompt with YAML frontmatter (`description`, `arguments`) followed by procedural instructions. Some Codex skills may also include folder-local references.
  - `skills/coding/` — `minimal-coding`
  - `skills/git/` — `commit-push`, `name-branch`, `name-commit`, `worktree-create`, `worktree-remove`, `resolve-conflicts-safely`
  - `skills/review/` — `branch-risk-review`, `clean-ai-comments`, `pr-description`, `pr-triage`
  - `skills/ticket/` — `clarify`, `argue-to-clarify`, `fix-review`, `linear-fetch`, `spec`, `ticket`
  - `skills/project/` — `codebase-study-pack`, `daily-update`, `feature-summary`, `testing-instructions`
  - `skills/data/` — `db-unsync-fix`, `query-db`
- `install.sh` — Downloads each skill and installs it **flat** into `~/.claude/commands/<name>.md` (and Codex/Cursor equivalents). Subfolders are repo organisation only — the installed names are unchanged so all `/skill-name` references keep working. Codex-only reference files are installed beside the relevant `SKILL.md` when needed.

## Adding a new skill

1. Create `skills/<subfolder>/<name>.md` with YAML frontmatter and instructions.
2. Add `"<name>:<subfolder>/<name>.md"` to the `SKILLS` array in `install.sh`.
3. Add the skill to the skills list in `CLAUDE.md` and add a section for it in `README.md`.
4. Commit, push, and re-run `install.sh` to deploy.

## Working conventions

- **"ticket skill"** means both `ticket.sh` (the shell pipeline) and `skills/ticket.md` (the skill definition). Any change to ticket behavior must be applied to both files.
- **Update `README.md`** whenever there are significant changes: new skills, removed skills, pipeline step changes, structural changes, or new usage patterns. Do NOT update it for minor fixes, internal refactors, or changes with no user-facing impact.

## Core philosophy (reflected in all skills)

- Safety > cleverness; read-only unless explicitly permitted
- Minimal diff > ideal design; prefer containment over broad refactors
- Always ask before executing state-changing commands
- Never bypass hooks (`--no-verify`)
