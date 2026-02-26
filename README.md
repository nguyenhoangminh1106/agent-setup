# agent-setup

A lightweight, copy-pasteable **agent skills registry** for Claude Code, OpenAI Codex, and Cursor.  
This repo is designed to be **deterministic, safe, and auditable**: every skill is plain Markdown, versioned in Git, and installed locally into each agent’s command/prompt directory.

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
│   ├── commit-push.md
│   ├── pr-triage.md
│   ├── branch-risk-review.md
│   ├── worktree-create.md
│   ├── worktree-remove.md
│   ├── clean-ai-comments.md
│   ├── ticket.md
│   └── spec.md
├── install.sh
└── README.md
```

* `skills/`
  Each file defines **one agent skill** in Markdown.
* `install.sh`
  Installs all skills into Claude, Codex, and Cursor.
* `README.md`
  Documentation and usage.

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

This installs skills to:

* **Claude Code** → `~/.claude/commands/`
* **OpenAI Codex** → `~/.codex/prompts/`
* **Cursor** → `~/.cursor/commands/`

No global binaries. No background services.

---

## Available Skills

### `commit-push`

Safely stage, commit, and push changes.

* Summarises diffs before committing
* Asks for confirmation
* Never force-pushes unless explicitly approved

---

### `pr-triage`

Review pull requests with engineering focus.

* Risk assessment
* Change classification
* Reviewer guidance

---

### `branch-risk-review`

Evaluate branch safety before merge.

* Detects large diffs
* Flags risky patterns
* Encourages incremental merges

---

### `worktree-create`

Create or reuse a **Git worktree** safely.

**What it does**

* Detects local vs remote branches
* Reuses existing worktrees when possible
* Creates new branches only when approved
* Places worktrees inside the project root:

  * `.claude/worktrees/`
  * `.codex/worktrees/`
  * `.cursor/worktrees/`
    (auto-detected, asks if none exist)

**Safety rules**

* Read-only inspection first
* Explicit confirmation before:

  * creating branches
  * adding worktrees
  * creating directories

---

### `worktree-remove`

Safely remove a Git worktree.

**What it does**

* Accepts a branch name or worktree path
* Refuses to remove the main working tree
* Detects uncommitted changes
* Supports optional branch deletion (ask-first)

**Safety rules**

* No force removal without explicit approval
* No remote branch deletion unless explicitly requested

---

### `clean-ai-comments`

Remove noisy, redundant AI-generated comments from new code only.

* Only touches lines introduced in the current branch diff
* Removes comments that restate the obvious (e.g. `// increment counter` above `count++`)
* Keeps meaningful comments: WHY explanations, gotchas, links, directives
* Reports every removed line before finishing

### `spec`

Turn raw user input into a clean, codebase-aware requirement spec.

**What it does**

* Reads everything the user provides: ticket text, chat history, context dumps, decisions
* Studies the existing codebase to understand patterns, conventions, and what already exists
* Produces a spec that describes the smallest change needed to satisfy the intent
* Prefers reusing existing code over introducing new abstractions
* Saves the output to `.ticket/spec.md` for use by downstream skills (e.g. `ticket`)

**Usage**

```
/spec "Add a logout button to the nav"
/spec 142
/spec "Here's the whole chat + context from our planning session..."
```

Can be used standalone before a planning session, or as the first step of `/ticket`.

---

### `ticket`

The top-level orchestrator. Takes a ticket and runs an end-to-end multi-agent pipeline — from spec to merged-ready branch — without human involvement during execution.

This is not a single-agent prompt. It dispatches `codex` and `claude` as separate subprocess calls from the terminal, using each tool for what it does best. Artifacts are saved to disk between steps so nothing is ever passed as stale in-memory content.

---

**Usage**

Run from the repo root in your terminal:

```bash
# Paste ticket text inline
/ticket "Add a logout button to the top nav that clears the session and redirects to /login"

# GitHub issue number
/ticket 142

# GitHub issue URL
/ticket https://github.com/org/repo/issues/142

# Optional: specify branch name or repo path
/ticket 142 branch=fix/logout-button repo=/path/to/repo
```

---

**Execution model**

`/ticket` is a terminal orchestrator — not running inside Claude Code or Codex. It dispatches both as peers:

```
terminal (/ticket)
├── codex "/spec ..."              → .ticket/spec.md
├── claude "/worktree-create ..."  → isolated branch + worktree
├── codex "plan from spec..."      → .ticket/plan.md
├── claude "implement plan..."     → code changes in worktree
├── [up to 3 rounds]
│   ├── git diff → .ticket/diff-current.md       (fresh each round)
│   ├── codex "review diff vs spec..."   → .ticket/risk-N.md
│   └── claude "apply BLOCKER+FIX..."
├── claude "/clean-ai-comments"
├── claude "/commit-push"
└── codex "final report..."        → printed to terminal + compare URL
```

---

**Step-by-step breakdown**

| # | Step | Tool | What happens |
|---|---|---|---|
| 1 | Spec | **Codex (GPT-5.2)** via `/spec` skill | Reads ticket + codebase, produces a codebase-aligned requirement spec. Saved to `spec.md`. |
| 2 | Worktree | **Claude Code** via `/worktree-create` | Creates an isolated branch and worktree. All code changes happen here — never on `main`. |
| 3 | Plan | **Codex (GPT-5.2)** | Reads `spec.md`, produces a minimal-diff execution plan: files to touch, files to skip, DB changes (only if unavoidable). Saved to `plan.md`. |
| 4 | Implement | **Claude Code** | Executes `plan.md` file-by-file. Matches existing patterns. No new dependencies or abstractions unless the spec explicitly requires them. |
| 5 | Risk review | **Codex** reviews, **Claude Code** fixes (×3 max) | Each round: captures a fresh diff from disk, Codex reviews it against `spec.md`, Claude applies only BLOCKER and FIX items. Skips `*.sql` and `migrations/` — those are written by humans. |
| 6 | Cleanup | **Claude Code** via `/clean-ai-comments` | Removes noisy AI-generated comments added in this branch only. |
| 7 | Commit | **Claude Code** via `/commit-push` | Commits with a Conventional Commits message tied to the ticket ID. Pushes. No `--no-verify`. |
| 8 | Report | **Codex** drafts, terminal prints | Final report: Summary, Ticket alignment, Risk verdict, How to test (UI steps), Technical notes, GitHub compare URL. |

---

**Artifact files**

All intermediate outputs are saved to `.ticket/` in the repo:

| File | Written by | Read by |
|---|---|---|
| `spec.md` | Step 1 (Codex / `/spec`) | Steps 3, 5, 8 |
| `plan.md` | Step 3 (Codex) | Step 4 |
| `diff-current.md` | Step 5a (git diff, fresh each round) | Step 5b (Codex) |
| `risk-1.md` … `risk-3.md` | Step 5b (Codex) | Step 5c (Claude), Step 8 |

Each tool reads from disk — never from a previous tool's in-memory state.

---

**Safety guarantees**

* No destructive git commands (`--force`, `reset --hard`, `clean -f`, `branch -D`)
* No force pushes — ever
* No database migrations generated or executed
* No changes to `main` or `master`
* Never exceeds ticket scope — scope drift is a BLOCKER in every risk review round
* Silent failures are not allowed — every error surfaces immediately and stops the pipeline

---

**What you get at the end**

* A clean branch with a single well-described commit
* A GitHub compare URL ready to open as a PR
* A structured report covering: what was done and why, how each acceptance criterion was met, the final risk verdict, step-by-step UI test instructions, and any deferred work or known limitations

The human's only job is to read the report, test in the UI, and decide whether to merge.

## Design Rules for All Skills

Every skill must follow these principles:

1. **Plan → Ask → Execute**
2. **No silent side effects**
3. **No guessing**
4. **Prefer reuse over creation**
5. **Never destroy without consent**

If a skill violates these rules, it should not live in this repo.

---

## Updating / Adding Skills

1. Create or edit a file in `skills/`
2. Commit and push
3. Re-run `install.sh` locally

Example:

```bash
git checkout -b feat/new-skill
vim skills/my-skill.md
git commit -am "Add my-skill"
git push
```

---

## Intended Use

This repo is built for:

* Agent-assisted engineering
* Multi-worktree development
* Deterministic workflows
* Humans who want **control**, not automation chaos

If you want hidden magic, this is not for you.

---

## License

MIT — use it, fork it, adapt it.
Just keep your workflows honest.
