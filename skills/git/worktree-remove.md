---
description: "Safely remove a git worktree by branch or path. ASK before removal/force. Optionally delete the branch after removing (ask first)."
arguments:
  - name: repo
    description: "Optional path to the git repo. If omitted, use current directory."
  - name: target
    description: "Branch name OR worktree path to remove."
  - name: delete_branch
    description: "Optional. If 'true', propose deleting the branch after worktree removal (still ASK)."
---

## Task

Safely remove a git worktree. Always ask for approval before executing any state-changing command. Never remove the main working tree or force-remove dirty worktrees without explicit user approval.

## Rules

- ALWAYS ASK for approval before executing any command that changes state (worktree remove, branch delete, force).
- Never remove the main working tree.
- If the worktree has uncommitted changes, default is STOP and ask what to do. Do not force unless the user explicitly approves.

## Steps

**1) Resolve repo root**
- If `{{repo}}` provided: use it. Else: stay in current directory.
```
git rev-parse --show-toplevel
```
If not a git repo: stop and explain.

**2) Gather facts** (read-only)
```
git worktree list --porcelain
git branch --show-current
```
If `{{target}}` is empty: list existing worktrees (path + branch) and ASK which one to remove. STOP.

**3) Resolve target to a worktree path + branch**
- Parse `git worktree list --porcelain` entries.
- If `{{target}}` matches a path (exact or basename): select that worktree.
- If `{{target}}` matches a branch name: select the worktree with `branch refs/heads/{{target}}`.
- If no match: stop and explain.

**4) Safety checks**
- If selected path == repo root: STOP (never remove the main worktree).
- Check for uncommitted changes:
```
git -C "<worktreePath>" status --porcelain
```
If output is non-empty:
- Report the local changes.
- ASK whether to: (a) stop and let user handle it, or (b) force remove with `git worktree remove --force`.
- Default: STOP unless the user explicitly approves force.

**5) Create removal plan**

| Condition | Command |
|---|---|
| Clean worktree | `git worktree remove "<worktreePath>"` |
| Dirty + user approved force | `git worktree remove --force "<worktreePath>"` |

After removal: `git worktree prune`

**6) Optional: delete branch** (only after successful worktree removal, only if requested)
If `{{delete_branch}} == "true"` or user asks:
```
git show-ref --verify --quiet "refs/heads/<branch>"  # check if local
git branch -d "<branch>"     # safe delete
git branch -D "<branch>"     # only if not merged AND user insists (ASK explicitly)
```
Do NOT delete the remote branch unless the user explicitly requests it.

**7) Confirm before executing**
Print:
- Worktree path
- Branch
- Whether clean or dirty
- Exact command(s) to run

Ask: "Proceed? (yes/no)"

**8) Execute approved commands**
```
git worktree remove "<worktreePath>"   # (or --force if approved)
git worktree prune
git worktree list
```
