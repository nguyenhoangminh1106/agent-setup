---
description: "Create or reuse a git worktree for a branch. Auto-infers branch name from context, checks local/remote, and runs with minimal confirmation."
arguments:
  - name: repo
    description: "Optional path to the git repo. If omitted, use current directory."
  - name: branch
    description: "Desired branch name. If omitted, infer from chat context and auto-generate a kebab-case name."
  - name: base
    description: "Optional base ref if creating a new branch (default: origin/main if exists, else main, else HEAD)."
---

## Task

Create a git worktree for a branch with minimal friction. Reuse existing worktrees when possible. Ask for confirmation only once before executing.

## Rules

- If a branch/worktree already exists, reuse it — no duplicates.
- Never guess the repo path. If not provided, use the current directory.
- Prefer minimal, reversible actions.
- Only ask for confirmation ONCE (the final "run?" prompt) unless something is genuinely ambiguous.

## Steps

**1) Resolve repo root**
- If `{{repo}}` provided: use it. Else: use current directory.
```
git rev-parse --show-toplevel
```
If not a git repo: stop and explain.

**2) Detect worktrees base dir** (no confirmation needed)
Check in this order and use the first that exists:
- `ROOT/.claude/worktrees`
- `ROOT/.codex/worktrees`
- `ROOT/.cursor/worktrees`

If none exist: default to `ROOT/.claude/worktrees` (create it silently in step 7).

**3) Decide branch name** (no confirmation needed unless truly unclear)
- If `{{branch}}` provided: use it as-is.
- Else: infer from the user's message — extract the intent, generate one kebab-case name.
  - Example: "add login page" → `feat/add-login-page`
  - Example: "fix null pointer in checkout" → `fix/null-pointer-checkout`
- Only ask if the message is so vague that no reasonable name can be inferred.

**4) Fetch and inspect** (read-only, no confirmation)
```
git fetch --prune origin
git worktree list --porcelain
git show-ref --verify --quiet refs/heads/<branch>        # LOCAL_BRANCH=1/0
git show-ref --verify --quiet refs/remotes/origin/<branch>  # REMOTE_BRANCH=1/0
```

**5) Resolve outcome silently**

| Case | Condition | Plan |
|---|---|---|
| A | Branch already checked out by an existing worktree | Report path and STOP. |
| B | LOCAL_BRANCH=1, not in another worktree | `git worktree add "<BASE>/<branch>" "<branch>"` |
| C | LOCAL_BRANCH=0, REMOTE_BRANCH=1 | `git worktree add -b "<branch>" "<BASE>/<branch>" "origin/<branch>"` |
| D | LOCAL_BRANCH=0, REMOTE_BRANCH=0 | `git worktree add -b "<branch>" "<BASE>/<branch>" "<baseRef>"` |

For case D, base ref = `{{base}}` if provided, else `origin/main` if exists, else `main`, else `HEAD`.

**6) Single confirmation prompt**
Print a one-line summary:
```
Branch: <branch> (<new|local|remote>) → <BASE>/<branch>
```
Ask: "Create this worktree? (yes/no)" — only proceed on explicit "yes".

**7) Execute**
```
mkdir -p "<BASE>"
git worktree add ...   # planned command from step 5
cd "<BASE>/<branch>"
git worktree list
```
Print the final worktree path and confirm the current directory is now the worktree.
