# agent-setup

A lightweight **agent skills registry** for Claude Code, OpenAI Codex, and Cursor.
Every skill is plain Markdown, versioned in Git, and installed locally into each agent's command directory.

---

## Philosophy

- **Skills, not magic** – every action is explicit, reviewable, and reversible
- **Ask before change** – destructive or state-changing commands must be approved
- **One source of truth** – this repo is the canonical definition of all skills
- **Tool-agnostic** – the same skill works in Claude, Codex, and Cursor
- **Repo-local first** – workflows (e.g. worktrees) live inside the project root

---

## Repository Structure

```text
agent-setup/
├── skills/
│   ├── coding/       # minimal-coding
│   ├── git/          # commit-push, name-branch, worktree-create, worktree-remove, resolve-conflicts-safely
│   ├── review/       # branch-risk-review, clean-ai-comments, pr-description, pr-triage
│   ├── ticket/       # clarify, argue-to-clarify, spec, ticket
│   ├── project/      # codebase-study-pack, daily-update, feature-summary, testing-instructions
│   └── data/         # db-unsync-fix, query-db
├── install.sh        # installs skills into ~/.claude/commands/, ~/.codex/skills/<name>/SKILL.md, ~/.cursor/commands/
├── ticket.sh         # terminal CLI orchestrator for the full ticket pipeline
└── README.md
```

Skills are organised into subfolders in the repo for clarity. Claude Code and Cursor install them as flat `.md` files; Codex installs them as folder-based skills (`<name>/SKILL.md`) with converted frontmatter. Codex-only reference files are installed beside the relevant `SKILL.md` when a skill needs them.

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/nguyenhoangminh1106/agent-setup/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/nguyenhoangminh1106/agent-setup.git
cd agent-setup
bash install.sh
```

Installs skills to:

- **Claude Code** → `~/.claude/commands/`
- **OpenAI Codex** → `~/.codex/skills/<name>/SKILL.md`
- **Cursor** → `~/.cursor/commands/`
- **Terminal CLI** → `~/bin/ticket`

Make sure `~/bin` is in your PATH:

```bash
export PATH="$HOME/bin:$PATH"  # add to ~/.zshrc or ~/.bashrc
```

---

## Skills

### Coding

#### `minimal-coding`
Minimal-diff coding guardrails for codebase-consistent implementation. Emphasizes reusing existing patterns, avoiding unnecessary abstractions, preserving type safety, and running checks that match touched files.

---

### Git

#### `commit-push`
Stage, commit (Conventional Commits format), and push in one step. Never force-pushes. Handles pre-commit hook failures minimally.

#### `name-branch`
Generate a well-formatted git branch name (`feat/`, `fix/`, `chore/` + kebab-case, ≤50 chars) from any ticket or plain-English description. Used internally by `worktree-create` and the ticket pipeline.

#### `worktree-create`
Create or reuse a git worktree. Always places worktrees at `ROOT/.claude/worktrees/<branch>`. Infers branch name via `/name-branch` if not provided. Asks for confirmation once (skippable with `yes=true`).

#### `worktree-remove`
Safely remove a git worktree by branch name or path. Detects uncommitted changes. Optionally deletes the branch after removal (ask-first). Never force-removes without approval.

#### `resolve-conflicts-safely`
Resolve Git merge/rebase conflicts with minimal, behavior-preserving edits. Restricts changes to conflicted files, preserves compatible intent from both sides, and stages only resolved files.

---

### Review

#### `branch-risk-review`
Read-only risk review of a branch or PR diff. Classifies findings as BLOCKER / FIX / NOTE. Checks behavioral safety, consistency with existing code, diff size, and simplicity. Does not edit code.

#### `clean-ai-comments`
Remove noisy, redundant AI-generated comments from the current branch diff only. Never touches pre-existing code. Keeps meaningful comments (WHY, gotchas, links).

#### `pr-description`
Write a plain-English PR description for non-technical readers. Covers all main changes in 1–3 sentences, no jargon.

#### `pr-triage`
Read-only PR triage. Auto-resolves bot threads (style/false-alarm/low-risk). Reports human threads without replying.

---

### Ticket

#### `clarify`
Read a ticket and the codebase, then ask only questions that cannot be answered from existing code. Outputs `CLARIFY:DONE` if nothing is unclear, or `CLARIFY:QUESTIONS` with a minimal list. Used as Step 0 of the ticket pipeline.

#### `argue-to-clarify`
Challenge unclear requests through concise solution-design arguments. Reads relevant code context first, asks one yes/no decision at a time, and stops at clarification or planning until implementation is explicitly requested.

#### `spec`
Turn raw ticket input into a clean, codebase-aware requirement spec. Studies existing patterns before writing a single line. Outputs to stdout — the caller handles file saving.

#### `ticket`
The top-level multi-agent pipeline. Takes a ticket and runs end-to-end — from branch naming and clarification through to a committed, pushed, review-ready branch.

See [Ticket Pipeline](#ticket-pipeline) below for full details.

---

### Project

#### `codebase-study-pack`
Create deep, navigable technical study packs for a codebase with infrastructure and feature docs, exact file/function citations, and principal-engineer-level implementation detail.

#### `daily-update`
Generate a daily work update from Slack (Beeper), Linear, GitHub, and Claude Code session logs. Matches past entry style, shows draft for approval, then appends to the updates file.

#### `feature-summary`
Summarize all changes on a branch (committed + uncommitted), explain the business purpose, and produce step-by-step UI testing instructions.

#### `testing-instructions`
Given a branch diff and optional DB access, produce concrete step-by-step UI testing instructions with real example data.

---

### Data

#### `query-db`
Accept a plain-English question, figure out the right read-only query, run it, and return a clear answer. Never mutates data.

#### `db-unsync-fix`
When Prisma detects schema drift from migrations run on another branch, generate the manual SQL to revert those changes so you can run migrations cleanly on the current branch.

---

## Ticket Pipeline

The `ticket` command is a terminal orchestrator. It dispatches `codex` and `claude` as separate subprocess calls, using each for what it does best.

### Usage

```bash
ticket "Add a logout button that clears session and redirects to /login"
ticket 142                         # GitHub issue number
ticket https://github.com/org/repo/issues/142
ticket branch=fix/my-branch        # resume an existing branch
```

Requirements: `codex` and `claude` CLIs both installed and in PATH.

### Pipeline steps

| # | Step | Tool | What happens |
|---|---|---|---|
| 0a | Branch name | **Claude** via `/name-branch` | Derives a clean branch name from the ticket before anything else |
| 0 | Clarify | **Codex** via `/clarify` | Reads codebase, asks only unanswerable questions. Interactive loop up to 3 rounds |
| 1 | Spec | **Codex** via `/spec` | Reads ticket + codebase, produces a minimal requirement spec |
| 2 | Worktree | **Claude** via `/worktree-create` | Creates an isolated branch + worktree. All changes happen here |
| 3 | Plan | **Codex** | Reads spec, produces minimal-diff execution plan |
| 4 | Implement | **Claude** | Executes plan in worktree. Matches existing patterns, no unnecessary abstractions |
| 5 | Push | **Claude** via `/commit-push` | Commits and pushes implementation before any reviews |
| 6 | Spec review | **Codex** reviews, **Claude** fixes + pushes (×3 max) | Reads diff from pushed branch. Verifies spec alignment. Each fix round pushes before next review |
| 7 | Risk review | **Claude** reviews + fixes + pushes (×3 max) | Reads diff from pushed branch. Checks regressions, scope drift, data risk. Each fix round pushes |
| 8 | Cleanup | **Claude** via `/clean-ai-comments` + push | Removes noisy AI comments, then pushes |
| 9 | Report | **Claude** via `/feature-summary` | Summary, business purpose, UI test steps, compare URL |
| 10 | Worktree cleanup | bash | Removes local worktree. Branch preserved on remote |

### Artifacts

All intermediate outputs saved to `.ticket/<branch>/`:

| File | Written by | Read by |
|---|---|---|
| `spec.md` | Step 1 | Steps 3, 6, 7, 9 |
| `plan.md` | Step 3 | Step 4 |
| `diff-current.md` | Steps 6, 7 (fresh each round from `origin/<branch>`) | Review steps |
| `spec-review-N.md` | Step 6 | Step 6 fix |
| `risk-N.md` | Step 7 | Step 7 fix |
| `report.md` | Step 9 | Human |

### Safety guarantees

- No destructive git commands (`--force`, `reset --hard`, `clean -f`, `branch -D`)
- No force pushes — ever
- No database migrations generated or executed
- No changes to `main` or `master`
- Scope drift is a BLOCKER in every review round
- Silent failures are not allowed — every error stops the pipeline immediately

---

## Adding a New Skill

1. Create `skills/<subfolder>/<name>.md` with YAML frontmatter and instructions.
2. Add `"<name>:<subfolder>/<name>.md"` to the `SKILLS` array in `install.sh`.
3. Update `CLAUDE.md` and `AGENTS.md` skills lists and add a section to this README.
4. Commit, push, re-run `install.sh` on other machines.

---

## License

MIT — use it, fork it, adapt it.
