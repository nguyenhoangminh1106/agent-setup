---
description: "Create ONE clean commit for all uncommitted changes and push to the current branch."
---

## Task

Create one clean commit for all uncommitted changes and push to the current branch.
If no changes exist, say so and stop.

## Rules

- Do NOT add any "Co-authored-by" lines or extra trailers.
- Use a short, meaningful commit message (≤72 chars) based on the actual diff.
- If pre-commit (husky) fails with ERRORS: fix only the errors with minimal diff. Ignore warnings.
- Never bypass hooks (`--no-verify`).

## Steps

**0) Preconditions**
- Determine current branch: `git branch --show-current`
- If detached HEAD: stop and explain.

**1) Fetch latest**
```
git fetch --prune origin
```

**2) Merge main into current branch** (if not on main and `origin/main` exists)
```
git merge origin/main
```

**3) Check for changes**
```
git status --porcelain
```
If empty: say "No changes to commit." and stop.

**4) Inspect the diff**
```
git diff
```

**5) Decide commit message**
Use Conventional Commits format based on the diff.

**6) Stage all**
```
git add -A
```

**7) Commit**
```
git -c commit.template= commit -m "<message>"
```
On Husky ERROR: fix minimally, re-stage, and retry.

**8) Push**
```
git push -u origin HEAD
```

**9) Print PR URL**
- If a PR already exists: `gh pr view --json url --jq .url`
- Else: print the compare URL from `git remote -v`
