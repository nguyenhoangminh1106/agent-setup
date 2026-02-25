Create ONE clean commit for all uncommitted changes and push to the current branch.

Rules:
- Do NOT add any "Co-authored-by" lines or extra trailers.
- Use a short meaningful commit message (<=72 chars) based on actual diff.
- If no changes: say so and stop.
- If pre-commit (husky) fails with ERRORS: fix only the errors with minimal diff. Ignore warnings.
- Never bypass hooks (no --no-verify).
- Always sync current branch with remote and main BEFORE pushing.

Steps:

0) Preconditions:
   - Ensure gh is authenticated: gh auth status
   - Determine current branch:
     git branch --show-current
   - If detached HEAD: stop and explain.

1) Fetch latest:
   git fetch --prune origin

2) Sync with remote branch (if exists):
   - If origin/<branch> exists:
     git rebase origin/<branch>

3) Sync with main (if not on main and origin/main exists):
   git rebase origin/main

4) Check changes:
   git status --porcelain
   - If empty: say "No changes to commit."

5) Inspect:
   git diff

6) Decide commit message (Conventional Commits).

7) Stage all:
   git add -A

8) Commit:
   git -c commit.template= commit -m "<message>"
   - On Husky ERROR: fix minimal, retry.

9) Ensure HTTPS remote:
   git remote -v
   git remote set-url origin https://github.com/paraform-xyz/paraform.git

10) Push:
   git push -u origin HEAD

11) PR URL:
   - If exists:
     gh pr view --json url --jq .url
   - Else:
     https://github.com/paraform-xyz/paraform/compare/<branch>?expand=1
