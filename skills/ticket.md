---
description: "End-to-end ticket implementation pipeline: ingest ticket, create worktree, plan, implement, risk-review, clean comments, commit, and report."
arguments:
  - name: ticket
    description: "Full ticket text, GitHub issue number, or URL describing the work to be done."
  - name: branch
    description: "Optional branch name. If omitted, inferred from the ticket title in kebab-case."
  - name: repo
    description: "Optional path to the git repo. If omitted, use current directory."
---

## Task

Implement a ticket end-to-end in an isolated worktree: ingest and expand the ticket into a structured spec, plan the minimal implementation, write the code, run up to 3 rounds of risk review with fixes, clean AI-generated comments, commit and push, then produce a final delivery report. Never modify the main branch. Never exceed the ticket's scope.

## Rules

- Never run destructive git commands (`git push --force`, `git reset --hard`, `git checkout -- .`, `git clean -f`, `git branch -D`).
- Never execute or generate database migrations.
- Never modify the `main` (or `master`) branch directly.
- Never introduce scope beyond what the ticket explicitly describes.
- Never force-push under any circumstances.
- Never silently swallow errors — surface every failure immediately and STOP.
- Never skip pre-commit hooks (`--no-verify`).
- All confirmation gates (marked ASK) require explicit "yes" before proceeding.

## Steps

**1) Ingest ticket**

Read `{{ticket}}` in full. If it is a GitHub issue number or URL, fetch it:
```
gh issue view {{ticket}} --json title,body,labels,assignees
```

Produce and display a **Structured Requirement Spec**:

| Section | Content |
|---|---|
| Goals | What the ticket wants to achieve |
| Non-goals | What is explicitly out of scope |
| Functional requirements | Observable behaviors the implementation must produce |
| Non-functional requirements | Performance, accessibility, compatibility constraints |
| Constraints | Tech stack, file limits, must-not-touch areas |
| Edge cases | Boundary conditions and failure modes mentioned or implied |
| Acceptance criteria | Conditions under which the ticket is "done" |
| Assumptions | Anything inferred that is not stated — flag each clearly |

Rules:
- Never invent scope.
- Never "improve" the product beyond what is described.
- If something is unclear, document the uncertainty — do not guess.

ASK: "Does this spec look correct? (yes / edit)" — only proceed on "yes".

**2) Create isolated worktree**

Determine branch name:
- If `{{branch}}` provided: use it.
- Else: derive a kebab-case name from the ticket title, prefixed `feat/`, `fix/`, or `chore/` as appropriate.

Run the `worktree-create` skill with:
- `repo` = `{{repo}}` (or current directory)
- `branch` = derived branch name

Do not continue until `worktree-create` confirms the worktree path and that the current directory is inside it.

**3) Generate execution plan**

Before writing any code, produce a written **Execution Plan**:

- List every file that will be created or modified, with a one-line reason.
- State what will NOT be touched and why.
- Confirm the approach uses the minimal diff that satisfies the acceptance criteria.
- Confirm: no refactors, no pattern changes, no migrations, no force pushes.
- Note any known risks or unknowns upfront.

Plan priorities (strict order):
1. Correctly implement the ticket
2. Minimize changes and diff size
3. Avoid breaking existing behavior
4. Maintain acceptable code quality

ASK: "Proceed with this plan? (yes / revise)" — only proceed on "yes".

**4) Implement**

Follow the plan file-by-file:
- Match existing code style, naming conventions, and patterns in each file touched.
- Introduce no new dependencies unless the ticket explicitly requires them.
- Introduce no new abstractions unless the ticket explicitly requires them.
- Do not touch files outside the plan without first stating why and seeking approval.

Safety guards — if any of these fire: STOP, report the violation, and wait for instruction:
- No `git push --force` or `git push --force-with-lease`
- No `DROP`, `DELETE FROM`, `ALTER TABLE`, or any migration commands
- No changes to `main` or `master`

**5) Risk review loop**

Run up to 3 rounds. Each round:

a) Run the `branch-risk-review` skill with `target` = current branch name.
   Provide the requirement spec from Step 1 as context so the reviewer can check alignment.

b) Classify each finding:
   - `BLOCKER` — must fix before proceeding (HIGH risk, behavioral regression, or out-of-scope change)
   - `FIX` — should fix (MEDIUM risk, non-trivial consistency issue)
   - `NOTE` — informational only, no action needed

c) Apply only BLOCKER and FIX items using minimal diffs. Do not refactor. Do not address NOTE items.

d) If no BLOCKER or FIX items remain after any round: exit the loop early.

e) After round 3, if BLOCKER items still exist: STOP and report them. Do not proceed to commit.

**6) Clean AI comments**

Run the `clean-ai-comments` skill with no arguments (diffs current branch against `origin/main`).

Report the lines removed. If nothing to remove, continue.

**7) Commit and push**

Run the `commit-push` skill.

- The commit message must follow Conventional Commits and include the ticket identifier if available (e.g., `feat: add login page (#42)`).
- Do not pass `--no-verify`.
- If a hook fails: fix minimally, re-stage, retry once. If it fails again: STOP and report.

**8) Final report**

Produce the following sections:

**A) Summary**
- Branch name and worktree path
- Commit hash and message
- Files changed (count and list)
- Rounds of risk review completed
- What was implemented and what was intentionally left out

**B) Ticket alignment**
- Map each acceptance criterion from Step 1 to the code change that satisfies it.
- Flag any criterion not addressed and explain why.
- Explicit confirmation: no out-of-scope changes introduced.

**C) Risk assessment**
- Final risk level from the last `branch-risk-review` round: LOW / MEDIUM / HIGH
- Any remaining NOTEs from risk review
- Verdict: **Safe to merge? YES / YES WITH CAUTION / NO**

**D) How to test**
Step-by-step manual test instructions written for a non-engineer:
- Where to navigate in the UI
- Which screens or features are affected
- What actions to perform
- Expected results for each step
- Edge cases to verify

**E) Technical notes**
- Files changed
- Any assumptions made during implementation
- Deferred work or known limitations
- Any environment setup required before deploying

**F) GitHub compare URL**
```
# If a PR already exists:
gh pr view --json url --jq .url

# Otherwise, print the compare URL:
git remote get-url origin   # derive base URL
# Format: <base>/compare/main...<branch>
```
