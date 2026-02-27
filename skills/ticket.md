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
# Codex steps — use `exec` subcommand for non-interactive streaming output:
codex exec "...prompt..."

# Claude Code steps — use -p --output-format stream-json for live token streaming:
claude -p --output-format stream-json "...prompt..."
```

Both are peers dispatched by this orchestrator. Neither is the "controller" of the other.

**Progress visibility — mandatory before every step:**

Before invoking any subprocess, print a progress banner to the terminal so the user always knows what is running:

```
════════════════════════════════════════
▶ Step <N> — <Step Name>  [tool: codex | claude]
   <one-line description of what this step will do>
════════════════════════════════════════
```

After the subprocess exits, print a completion line:

```
✓ Step <N> — <Step Name> complete  (artifact: .ticket/<branch>/<file> if applicable)
```

If the subprocess exits non-zero, print:
```
✗ Step <N> FAILED — exit code <N>. Stopping.
```
…and halt immediately.

**Subprocess output:** Both `codex` and `claude` stream their output directly to the terminal (do not suppress or redirect to /dev/null). The user sees live output from each tool as it runs.

**Artifacts** are saved to `.ticket/<branch>/` between steps so each ticket run is isolated and runs never overwrite each other:
- `spec.md` — output of the `spec` skill (Step 1)
- `plan.md` — Codex planning output (Step 3)
- `risk-1.md`, `risk-2.md`, `risk-3.md` — per-round risk review output (Step 5)

Each tool reads its input artifact from disk and writes its output artifact to disk. Never pass stale in-memory content between steps.

**CRITICAL — never inline large artifacts as shell variables.** Always pass artifact paths to the tool and let the tool read them. Inlining large files via `$VAR` expansion hits shell `ARG_MAX` limits and can OOM the process.

## Steps

---

### Step 1 — Spec (spec skill via Codex)

**Auto-skip check:** If `.ticket/<branch>/spec.md` already exists and `{{branch}}` was provided, skip this step entirely and print:
```
Step 1 — Spec: skipped (using existing .ticket/<branch>/spec.md)
```

Otherwise, print the progress banner then run:
```
════════════════════════════════════════
▶ Step 1 — Spec  [tool: codex]
   Generating requirement spec from ticket input
════════════════════════════════════════
```
```bash
codex exec "/spec {{ticket}}"
```

Output is saved to `.ticket/<branch>/spec.md` by the `spec` skill.

---

### Step 2 — Worktree (worktree-create skill)

Determine branch name:
- If `{{branch}}` provided: use it.
- Else: derive from the spec Goal line — kebab-case, prefixed `feat/`, `fix/`, or `chore/`.

Print the progress banner then run:
```
════════════════════════════════════════
▶ Step 2 — Worktree  [tool: claude]
   Creating isolated git worktree for branch: <branch>
════════════════════════════════════════
```
```bash
claude -p --output-format stream-json "/worktree-create branch=<branch> repo={{repo}} yes=true"
```

Do not continue until the worktree path is confirmed and the working directory is inside it.

---

### Step 3 — Plan (Codex)

**Auto-skip check:** If `.ticket/<branch>/plan.md` already exists, skip this step entirely and print:
```
Step 3 — Plan: skipped (using existing .ticket/<branch>/plan.md)
```

Otherwise, print the progress banner then run:
```
════════════════════════════════════════
▶ Step 3 — Plan  [tool: codex]
   Producing minimal-diff execution plan from spec
════════════════════════════════════════
```
```bash
codex exec "You are a software planner. Produce a minimal-diff Execution Plan.

Read the spec from disk: .ticket/<branch>/spec.md

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

Save output to `.ticket/<branch>/plan.md`.

---

### Step 4 — Implementation (Claude Code)

Print the progress banner then run:
```
════════════════════════════════════════
▶ Step 4 — Implementation  [tool: claude]
   Executing plan — writing code changes in worktree
════════════════════════════════════════
```
```bash
claude -p --output-format stream-json "Execute this plan inside the current worktree. Match existing code style and patterns. No new dependencies or abstractions unless the spec requires them. Do not touch files outside the plan.

Safety: no force push, no DROP/DELETE/ALTER TABLE/migrations, no changes to main or master. If any guard fires: STOP and report.

Read the plan from disk: .ticket/<branch>/plan.md"
```

---

### Step 5 — Risk Review Loop (Codex reviews, Claude Code fixes)

Run up to 3 rounds. Each round uses a freshly captured diff — never reuse a diff from a prior round.

**Each round:**

**5a) Capture fresh diff**

Print:
```
════════════════════════════════════════
▶ Step 5a — Diff capture  [tool: bash]  (round <N>/3)
   Fetching origin and diffing branch against main
════════════════════════════════════════
```
```bash
git fetch origin
git diff origin/main...HEAD > .ticket/<branch>/diff-current.md
```
If the diff is empty: STOP and report — no changes on branch.

**5b) Codex reviews**

Print:
```
════════════════════════════════════════
▶ Step 5b — Risk review  [tool: codex]  (round <N>/3)
   Reviewing diff for blockers, regressions, and scope drift
════════════════════════════════════════
```
```bash
codex exec "You are a code risk reviewer. Review the diff against the spec.

Read both artifacts fresh from disk:
- Spec: .ticket/<branch>/spec.md
- Diff: .ticket/<branch>/diff-current.md

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

Save output to `.ticket/<branch>/risk-<N>.md`.

**5c) Claude Code applies fixes**

Print:
```
════════════════════════════════════════
▶ Step 5c — Fix application  [tool: claude]  (round <N>/3)
   Applying BLOCKER and FIX items from risk review
════════════════════════════════════════
```
```bash
claude -p --output-format stream-json "Apply only the BLOCKER and FIX items from the risk review. Minimal diffs only. No refactors. Ignore NOTE items.

Read the risk review from disk: .ticket/<branch>/risk-<N>.md"
```

Exit the loop early if no BLOCKER or FIX items remain. After round 3, if BLOCKERs still exist: STOP and report.

---

### Step 6 — AI Comment Cleanup (Claude Code)

Print the progress banner then run:
```
════════════════════════════════════════
▶ Step 6 — AI Comment Cleanup  [tool: claude]
   Removing noisy AI-generated comments from diff
════════════════════════════════════════
```
```bash
claude -p --output-format stream-json "/clean-ai-comments"
```

---

### Step 7 — Commit and Push (Claude Code)

Print the progress banner then run:
```
════════════════════════════════════════
▶ Step 7 — Commit and Push  [tool: claude]
   Creating conventional commit and pushing branch
════════════════════════════════════════
```
```bash
claude -p --output-format stream-json "/commit-push"
```

Commit message must follow Conventional Commits and include the ticket identifier if available (e.g. `feat: add login page (#42)`). No `--no-verify`. If a hook fails: fix minimally, retry once. If it fails again: STOP and report.

---

### Step 8 — Final Report (Codex drafts, terminal publishes)

Print the progress banner then run:
```
════════════════════════════════════════
▶ Step 8 — Final Report  [tool: codex]
   Synthesizing delivery report from all artifacts
════════════════════════════════════════
```
```bash
codex exec "Produce a final delivery report.

Read all artifacts from disk:
- Spec: .ticket/<branch>/spec.md
- Plan: .ticket/<branch>/plan.md
- Risk review 1 (if exists): .ticket/<branch>/risk-1.md
- Risk review 2 (if exists): .ticket/<branch>/risk-2.md
- Risk review 3 (if exists): .ticket/<branch>/risk-3.md

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

---

### Step 9 — Worktree Cleanup (Claude Code)

Print the progress banner then run:
```
════════════════════════════════════════
▶ Step 9 — Worktree Cleanup  [tool: claude]
   Removing local worktree directory (branch kept on remote)
════════════════════════════════════════
```
```bash
claude -p --output-format stream-json "/worktree-remove target=<branch> repo={{repo}}"
```

Do NOT pass `delete_branch=true` — the branch must be preserved on the remote. If the worktree has unexpected uncommitted changes: STOP and report, do not force.

Print on success:
```
✓ Step 9 — Worktree Cleanup complete  (worktree removed, branch <branch> preserved on remote)
```
