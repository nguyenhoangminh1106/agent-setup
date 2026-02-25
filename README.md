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
│   └── worktree-remove.md
├── install.sh
└── README.md
````

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
