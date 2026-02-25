---
name: worktree-create
description: Create or reuse a git worktree for a branch. Detect local/remote branch, propose safe commands, and ASK before running. Place worktrees under repo root .claude/.codex/.cursor (auto-detect).
arguments:
  - name: repo
    description: Optional path to the git repo. If omitted, use current directory.
  - name: branch
    description: Desired branch name. If omitted, infer from chat and propose a name; ASK for confirmation.
  - name: base
    description: Optional base ref if creating a new branch (default: origin/main if exists else main else current HEAD).
---

You are an engineering assistant. Your job: create a git worktree safely.

Hard rules:
- ALWAYS ASK for approval before executing any git commands that change state (creating branches, adding worktrees, deleting).
- Never guess repo path. If not provided, use current directory.
- Prefer minimal, reversible actions.
- If a branch/worktree already exists, reuse it instead of creating duplicates.

Procedure (plan first, then ask, then execute):
1) Resolve repo root:
   - If {{repo}} provided: cd {{repo}}
   - Else: stay in current dir
   - Run: git rev-parse --show-toplevel
   - If not a git repo: stop and explain.

2) Detect which agent folder to use under repo root (for worktree location):
   - Let ROOT = repo root path
   - Choose WORKTREES_BASE in this priority order if exists:
     a) ROOT/.claude/worktrees
     b) ROOT/.codex/worktrees
     c) ROOT/.cursor/worktrees
   - If none exist:
     - Propose creating ROOT/.claude/worktrees (default) OR ask user which one they want (.claude vs .codex vs .cursor)
     - DO NOT create directories yet; ASK first.

3) Decide branch name:
   - If {{branch}} provided: use it.
   - Else:
     - Infer from chat intent (short, kebab-case). Propose 1-2 options.
     - ASK user to pick/confirm the exact branch name.

4) Fetch + inspect:
   - Run (read-only):
     - git fetch --prune origin
     - git branch --show-current
     - git worktree list --porcelain
     - git show-ref --verify --quiet refs/heads/<branch> && echo "LOCAL_BRANCH=1" || echo "LOCAL_BRANCH=0"
     - git show-ref --verify --quiet refs/remotes/origin/<branch> && echo "REMOTE_BRANCH=1" || echo "REMOTE_BRANCH=0"

5) Resolve outcomes:
   A) If branch is already checked out by an existing worktree:
      - From `git worktree list --porcelain`, locate the worktree path for that branch.
      - Report: "Worktree already exists at: <path>" and STOP (no changes).

   B) If LOCAL_BRANCH=1 and not used by another worktree:
      - Target path: <WORKTREES_BASE>/<branch>
      - Plan command:
        git worktree add "<WORKTREES_BASE>/<branch>" "<branch>"

   C) If LOCAL_BRANCH=0 and REMOTE_BRANCH=1:
      - Create a local tracking branch at worktree creation time.
      - Plan command:
        git worktree add -b "<branch>" "<WORKTREES_BASE>/<branch>" "origin/<branch>"

   D) If LOCAL_BRANCH=0 and REMOTE_BRANCH=0:
      - Creating a new branch. Choose base ref:
        - If {{base}} provided: use it
        - Else:
          - If origin/main exists: use origin/main
          - Else if main exists: use main
          - Else: use HEAD
      - Plan command:
        git worktree add -b "<branch>" "<WORKTREES_BASE>/<branch>" "<baseRef>"

6) Before executing any change:
   - Print a short plan:
     - Repo root
     - Worktrees base dir
     - Branch + whether local/remote/new
     - Exact command(s) to run
   - ASK: "Run these commands? (yes/no)"
   - Only proceed on explicit "yes".

7) Execute approved commands:
   - Ensure directory exists:
     mkdir -p "<WORKTREES_BASE>"
   - Run the planned `git worktree add ...`
   - Post-check:
     - git worktree list
     - echo the final path
