---
description: "Multi-agent ticket implementation pipeline: orchestrates Codex CLI (spec, planning, risk review) and Claude Code (worktree, implementation, cleanup, commit) across a full ticket-to-branch workflow."
arguments:
  - name: ticket
    description: "Full ticket text, GitHub issue number, or URL describing the work to be done."
  - name: branch
    description: "Optional branch name. If omitted, inferred from the ticket title in kebab-case."
  - name: repo
    description: "Optional path to the git repo. If omitted, use current directory."
---

## Task

You are a top-level orchestrator running in the terminal at the repo root. You are not running inside Claude Code or Codex — you dispatch to both as separate subprocess calls. Each step explicitly names which tool to invoke. Outputs are saved as artifact files and passed between tools. Never modify the main branch. Never exceed the ticket's scope.

## Tool Assignment

| Step | Tool | Reason |
|---|---|---|
| 1. Spec (`/spec` skill) | **Codex CLI (GPT-5.2)** | Strong structured reasoning, codebase-aware spec generation |
| 2. Worktree creation | **Claude Code** | Repo-aware, safe git ops |
| 3. Planning | **Codex CLI** | Diff-minimization and plan discipline |
| 4. Implementation | **Claude Code** | Safer code edits, repo-aware |
| 5. Risk review loop | **Codex CLI** | Objective validation against ticket intent |
| 5b. Fix iterations | **Claude Code** | Controlled corrective edits |
| 6. AI comment cleanup | **Claude Code** | Comment-only edits |
| 7. Commit and push | **Claude Code** | Repo-safe execution |
| 8. Final report | **Codex CLI** (draft) + **Claude Code** (publish) | Codex synthesizes, Claude appends compare URL |

## Rules

- Never run destructive git commands (`git push --force`, `git reset --hard`, `git checkout -- .`, `git clean -f`, `git branch -D`).
- Never execute or generate database migrations.
- Never modify `main` or `master` directly.
- Never introduce scope beyond what the ticket explicitly describes.
- Never force-push under any circumstances.
- Never silently swallow errors — surface every failure immediately and STOP.
- Never skip pre-commit hooks (`--no-verify`).
- Each tool must consume the previous tool's artifact verbatim — never summarize or re-interpret upstream output.

## Context: Execution Model

This skill runs from the terminal at the repo root — not inside either tool. Each step is a subprocess call:

```bash
# Codex steps:
codex "...prompt with artifact embedded..."

# Claude Code steps:
claude "...prompt with artifact embedded..."
```

Both are peers dispatched by this orchestrator. Neither is the "controller" of the other.

**Artifacts** are saved to `.ticket/` between steps so each tool reads the exact output of the previous one:
- `spec.md` — output of the `spec` skill (Step 1)
- `plan.md` — Codex planning output (Step 3)
- `risk-1.md`, `risk-2.md`, `risk-3.md` — per-round risk review output (Step 5)

Each tool reads its input artifact from disk and writes its output artifact to disk. Never pass stale in-memory content between steps.

## Steps

---

### Step 1 — Spec (spec skill via Codex)

```bash
codex "/spec {{ticket}}"
```

Output is saved to `.ticket/spec.md` by the `spec` skill.

---

### Step 2 — Worktree (worktree-create skill)

Determine branch name:
- If `{{branch}}` provided: use it.
- Else: derive from the spec Goal line — kebab-case, prefixed `feat/`, `fix/`, or `chore/`.

```bash
claude "/worktree-create branch=<branch> repo={{repo}}"
```

Do not continue until the worktree path is confirmed and the working directory is inside it.

---

### Step 3 — Plan (Codex)

Read `.ticket/spec.md` into `$SPEC`.

```bash
codex "You are a software planner. Produce a minimal-diff Execution Plan.

SPEC (from /spec skill):
---
$SPEC
---

Output format:

## Files to change
(each file + one-line reason)

## Files NOT to touch
(each + reason)

## DB / schema changes
NONE, or list each with justification.
Only acceptable if strictly required by the spec with no alternative.

## Implementation approach
(prose, ≤10 lines)

## Known risks

## Confirmation
- Spec fidelity: confirmed
- No refactors: confirmed
- No unnecessary migrations: confirmed
- No force pushes: confirmed

Priorities (strict order):
1. Spec fidelity
2. Minimal diff — fewest files and lines possible
3. Avoid DB/schema changes unless strictly required
4. No behavior breakage
5. Acceptable code quality"
```

Save output to `.ticket/plan.md`.

---

### Step 4 — Implementation (Claude Code)

Read `.ticket/plan.md` into `$PLAN`.

```bash
claude "Execute this plan inside the current worktree. Match existing code style and patterns. No new dependencies or abstractions unless the spec requires them. Do not touch files outside the plan.

Safety: no force push, no DROP/DELETE/ALTER TABLE/migrations, no changes to main or master. If any guard fires: STOP and report.

PLAN:
---
$PLAN
---"
```

---

### Step 5 — Risk Review Loop (Codex reviews, Claude Code fixes)

Run up to 3 rounds. Each round uses a freshly captured diff — never reuse a diff from a prior round.

**Each round:**

**5a) Capture fresh diff**
```bash
git fetch origin
git diff origin/main...HEAD > .ticket/diff-current.md
```
If the diff is empty: STOP and report — no changes on branch.

**5b) Codex reviews**

Read all artifacts fresh from disk:
```bash
SPEC=$(cat .ticket/spec.md)
DIFF=$(cat .ticket/diff-current.md)
```

```bash
codex "You are a code risk reviewer. Review the diff against the spec.

SPEC:
---
$SPEC
---

DIFF (captured just now — current branch state):
---
$DIFF
---

Run the branch-risk-review skill. Classify each finding:
- BLOCKER: must fix (regression, out-of-scope change, HIGH risk)
- FIX: should fix (MEDIUM risk, consistency issue)
- NOTE: informational only

Explicitly check:
- Scope drift: anything touched that the spec did not ask for?
- Diff size: any unnecessary files or lines changed?
- DB/schema changes (skip *.sql and migrations/ — humans write those): any ORM model or schema change not strictly required? → BLOCKER if so.
- Intent loss: does the implementation still match the spec goals?
- Hidden data risk: any writes, deletes, or transforms on existing data rows?"
```

Save output to `.ticket/risk-<N>.md`.

**5c) Claude Code applies fixes**
```bash
claude "Apply only the BLOCKER and FIX items from the risk review below. Minimal diffs only. No refactors. Ignore NOTE items.

RISK REVIEW:
---
$(cat .ticket/risk-<N>.md)
---"
```

Exit the loop early if no BLOCKER or FIX items remain. After round 3, if BLOCKERs still exist: STOP and report.

---

### Step 6 — AI Comment Cleanup (Claude Code)

```bash
claude "/clean-ai-comments"
```

---

### Step 7 — Commit and Push (Claude Code)

```bash
claude "/commit-push"
```

Commit message must follow Conventional Commits and include the ticket identifier if available (e.g. `feat: add login page (#42)`). No `--no-verify`. If a hook fails: fix minimally, retry once. If it fails again: STOP and report.

---

### Step 8 — Final Report (Codex drafts, terminal publishes)

Read all artifacts:
```bash
SPEC=$(cat .ticket/spec.md)
PLAN=$(cat .ticket/plan.md)
RISK1=$(cat .ticket/risk-1.md 2>/dev/null)
RISK2=$(cat .ticket/risk-2.md 2>/dev/null)
RISK3=$(cat .ticket/risk-3.md 2>/dev/null)
```

```bash
codex "Produce a final delivery report.

SPEC: $SPEC
PLAN: $PLAN
RISK REVIEWS: $RISK1 $RISK2 $RISK3

Sections:
## A) Summary — what was done, what was intentionally left out
## B) Ticket alignment — map each acceptance criterion to the change that satisfies it; flag any unaddressed
## C) Risk assessment — final level LOW/MEDIUM/HIGH; safe to merge? YES / YES WITH CAUTION / NO
## D) How to test — step-by-step UI instructions; expected results; edge cases
## E) Technical notes — files changed, assumptions, deferred work"
```

Append the compare URL:
```bash
gh pr view --json url --jq .url 2>/dev/null || {
  base=$(git remote get-url origin | sed 's/\.git$//')
  branch=$(git branch --show-current)
  echo "${base}/compare/main...${branch}"
}
```

Print the complete report.
