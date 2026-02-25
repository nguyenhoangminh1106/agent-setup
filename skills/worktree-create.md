---
name: worktree-create
description: Create or reuse a git worktree for a branch. Auto-infers branch name from context, checks local/remote, and runs with minimal confirmation.
arguments:
  - name: repo
    description: Optional path to the git repo. If omitted, use current directory.
  - name: branch
    description: Desired branch name. If omitted, infer from chat context and auto-generate a kebab-case name.
  - name: base
    description: Optional base ref if creating a new branch (default: origin/main if exists else main else HEAD).
---

You are an engineering assistant. Your job: create a git worktree with minimal friction.

Hard rules:
- If a branch/worktree already exists, reuse it — no duplicates.
- Never guess repo path. If not provided, use current directory.
- Prefer minimal, reversible actions.
- Only ask for confirmation ONCE (the final "run?" prompt) unless something is genuinely ambiguous.

Procedure:

1) Resolve repo root:
   - If {{repo}} provided: use it. Else: use current directory.
   - Run: git rev-parse --show-toplevel
   - If not a git repo: stop and explain.

2) Detect worktrees base dir (no confirmation needed):
   - Check in this order, use the first that exists:
     a) ROOT/.claude/worktrees
     b) ROOT/.codex/worktrees
     c) ROOT/.cursor/worktrees
   - If none exist: default to ROOT/.claude/worktrees (create it silently in step 7).

3) Decide branch name (no confirmation needed unless truly unclear):
   - If {{branch}} provided: use it as-is.
   - Else: infer from the user's message — extract the intent, generate one kebab-case branch name.
     - Example: "add login page" → feat/add-login-page
     - Example: "fix null pointer in checkout" → fix/null-pointer-checkout
   - Only ask if the message is so vague that no reasonable name can be inferred.

4) Fetch + inspect (read-only, no confirmation):
   - git fetch --prune origin
   - git worktree list --porcelain
   - git show-ref --verify --quiet refs/heads/<branch> → LOCAL_BRANCH=1/0
   - git show-ref --verify --quiet refs/remotes/origin/<branch> → REMOTE_BRANCH=1/0

5) Resolve outcome silently:
   A) Branch already checked out by an existing worktree:
      - Report: "Worktree already exists at: <path>" and STOP.

   B) LOCAL_BRANCH=1, not used by another worktree:
      - Plan: git worktree add "<WORKTREES_BASE>/<branch>" "<branch>"

   C) LOCAL_BRANCH=0, REMOTE_BRANCH=1:
      - Plan: git worktree add -b "<branch>" "<WORKTREES_BASE>/<branch>" "origin/<branch>"

   D) LOCAL_BRANCH=0, REMOTE_BRANCH=0 (new branch):
      - Base ref: {{base}} if provided, else origin/main if exists, else main, else HEAD
      - Plan: git worktree add -b "<branch>" "<WORKTREES_BASE>/<branch>" "<baseRef>"

6) Single confirmation prompt:
   - Print a one-line summary:
     Branch: <branch> (<new|local|remote>) → <WORKTREES_BASE>/<branch>
   - Ask: "Create this worktree? (yes/no)"
   - Only proceed on explicit "yes".

7) Execute:
   - mkdir -p "<WORKTREES_BASE>"
   - Run the planned git worktree add command.
   - Post-check: git worktree list
   - Print the final worktree path.
