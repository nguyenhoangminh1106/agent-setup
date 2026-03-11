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
│   ├── git/          # commit-push, name-branch, worktree-create, worktree-remove
│   ├── review/       # branch-risk-review, clean-ai-comments, pr-description, pr-triage
│   ├── ticket/       # clarify, spec, ticket
│   ├── project/      # daily-update, feature-summary, testing-instructions
│   └── data/         # db-unsync-fix, query-db
├── install.sh        # installs all skills flat into ~/.claude/commands/, ~/.codex/prompts/, ~/.cursor/commands/
├── ticket.sh         # terminal CLI orchestrator for the full ticket pipeline
└── README.md
```

Skills are organised into subfolders in the repo for clarity, but installed **flat** so `/skill-name` references work identically in all tools.

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
- **OpenAI Codex** → `~/.codex/prompts/`
- **Cursor** → `~/.cursor/commands/`
- **Terminal CLI** → `~/bin/ticket`

Make sure `~/bin` is in your PATH:

```bash
export PATH="$HOME/bin:$PATH"  # add to ~/.zshrc or ~/.bashrc
```

---

## Skills

### Git

#### `commit-push`
Stage, commit (Conventional Commits format), and push in one step. Never force-pushes. Handles pre-commit hook failures minimally.

#### `name-branch`
Generate a well-formatted git branch name (`feat/`, `fix/`, `chore/` + kebab-case, ≤50 chars) from any ticket or plain-English description. Used internally by `worktree-create` and the ticket pipeline.

#### `worktree-create`
Create or reuse a git worktree. Always places worktrees at `ROOT/.claude/worktrees/<branch>`. Infers branch name via `/name-branch` if not provided. Asks for confirmation once (skippable with `yes=true`).

#### `worktree-remove`
Safely remove a git worktree by branch name or path. Detects uncommitted changes. Optionally deletes the branch after removal (ask-first). Never force-removes without approval.

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

#### `spec`
Turn raw ticket input into a clean, codebase-aware requirement spec. Studies existing patterns before writing a single line. Outputs to stdout — the caller handles file saving.

#### `ticket`
The top-level multi-agent pipeline. Takes a ticket and runs end-to-end — from branch naming and clarification through to a committed, pushed, review-ready branch.

See [Ticket Pipeline](#ticket-pipeline) below for full details.

---

### Project

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
| 0a | Branch name | **Codex** via `/name-branch` | Derives a clean branch name from the ticket before anything else |
| 0 | Clarify | **Codex** via `/clarify` | Reads codebase, asks only unanswerable questions. Interactive loop up to 3 rounds |
| 1 | Spec | **Codex** via `/spec` | Reads ticket + codebase, produces a minimal requirement spec |
| 2 | Worktree | **Claude** via `/worktree-create` | Creates an isolated branch + worktree. All changes happen here |
| 3 | Plan | **Codex** | Reads spec, produces minimal-diff execution plan |
| 4 | Implement | **Claude** | Executes plan. Matches existing patterns, no unnecessary abstractions |
| 4b | Spec review | **Codex** reviews, **Claude** fixes (×3 max) | Verifies implementation matches spec. Applies BLOCKER + FIX items only |
| 5 | Risk review | **Claude** reviews + fixes (×3 max) | Checks for regressions, scope drift, data risk |
| 6 | Cleanup | **Claude** via `/clean-ai-comments` | Removes noisy AI comments from diff |
| 7 | Commit | **Claude** via `/commit-push` | Conventional Commits message, no `--no-verify` |
| 8 | Report | **Claude** via `/feature-summary` | Summary, business purpose, UI test steps, compare URL |
| 9 | Worktree cleanup | bash | Removes local worktree. Branch preserved on remote |

### Artifacts

All intermediate outputs saved to `.ticket/<branch>/`:

| File | Written by | Read by |
|---|---|---|
| `spec.md` | Step 1 | Steps 3, 4b, 5, 8 |
| `plan.md` | Step 3 | Step 4 |
| `diff-current.md` | Steps 4b, 5 (fresh each round) | Review steps |
| `spec-review-N.md` | Step 4b | Step 4b fix |
| `risk-N.md` | Step 5 | Step 5 fix |
| `report.md` | Step 8 | Human |

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
3. Update `CLAUDE.md` skills list and add a section to this README.
4. Commit, push, re-run `install.sh` on other machines.

---

## License

MIT — use it, fork it, adapt it.
