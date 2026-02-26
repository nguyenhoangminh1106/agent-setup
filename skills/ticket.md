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

Orchestrate a full ticket-to-branch workflow by explicitly delegating steps to Codex CLI (reasoning, spec, planning, risk review) and Claude Code (worktree, implementation, cleanup, commit). This is a multi-agent controller — not a single-prompt workflow. Each tool runs only the steps it is assigned. Outputs are passed as structured artifacts between tools. Never modify the main branch. Never exceed the ticket's scope.

## Tool Assignment

| Step | Tool | Reason |
|---|---|---|
| 1. Ingest + spec | **Codex CLI** | Strong structured reasoning, long context |
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

## Context: How Tool Switching Works

When this skill says "switch to Codex CLI", the current agent (e.g. Claude Code) must invoke Codex CLI as a subprocess:

```bash
codex "<prompt with embedded artifact>"
```

When it says "switch to Claude Code", the orchestrator resumes in-process (Claude Code is the controller).

Artifacts are passed as inline text embedded in the prompt — not as file paths unless the artifact is too large (>4000 chars), in which case write it to `.claude/ticket-artifacts/<step>.md` and reference the path.

## Steps

---

### Step 1 — Spec Generation (Codex CLI)

Run the `spec` skill with `ticket` = `{{ticket}}`.

The `spec` skill handles: fetching the ticket if it's an issue number/URL, invoking Codex CLI, and saving the output to `.claude/ticket-artifacts/spec.md`.

Once the `spec` skill completes, load **SPEC_ARTIFACT** from `.claude/ticket-artifacts/spec.md`.

If the `spec` skill reports a fallback warning (Codex unavailable), note it in the final report.

---

### Step 2 — Worktree Creation (Claude Code)

**Stay in Claude Code.**

Determine branch name:
- If `{{branch}}` provided: use it.
- Else: derive a kebab-case name from the ticket title, prefixed `feat/`, `fix/`, or `chore/` as appropriate.

Run the `worktree-create` skill with:
- `repo` = `{{repo}}` (or current directory)
- `branch` = derived branch name

Do not continue until `worktree-create` confirms the worktree path and current directory is inside it.

---

### Step 3 — Planning (Codex CLI)

**Switch to Codex CLI.**

Embed the ticket and SPEC_ARTIFACT and instruct Codex to produce an Execution Plan:

```bash
codex "You are a software planner. Given the ticket and requirement spec below, produce a minimal-diff Execution Plan.

TICKET (verbatim):
---
{{ticket}}
---

REQUIREMENT SPEC:
---
{{SPEC_ARTIFACT}}
---

Output the plan in this format:

## Files to change
(list each file + one-line reason)

## Files NOT to touch
(list + reason)

## DB / schema changes
State explicitly: NONE, or list each change with justification.
A DB/schema change is only acceptable if the ticket explicitly requires it AND there is no way to satisfy the requirement without it.
If a DB change can be deferred or avoided: omit it and note why.

## Implementation approach
(prose, ≤10 lines)

## Known risks
(list)

## Confirmation
- Ticket fidelity: confirmed
- No refactors: confirmed
- No migrations unless unavoidable: confirmed
- No force pushes: confirmed

Plan priorities (strict order):
1. Ticket fidelity
2. Minimal diff — touch the fewest files and lines possible
3. Avoid DB/schema changes unless strictly required by the ticket
4. No behavior breakage
5. Acceptable code quality"
```

Save the full Codex output as **PLAN_ARTIFACT**.

---

### Step 4 — Implementation (Claude Code)

**Stay in Claude Code** (inside the worktree from Step 2).

Execute PLAN_ARTIFACT file-by-file:
- Match existing code style, naming conventions, and patterns.
- Introduce no new dependencies or abstractions unless the ticket explicitly requires them.
- Do not touch files outside the plan without stating why and stopping for input.

Safety guards — if any fire: STOP, report the violation, wait for instruction:
- No `git push --force` or `git push --force-with-lease`
- No `DROP`, `DELETE FROM`, `ALTER TABLE`, or migration commands
- No changes to `main` or `master`

---

### Step 5 — Risk Review Loop (Codex CLI reviews, Claude Code fixes)

Run up to 3 rounds. **Each round reviews the current state of the code, not a cached diff.**

**Each round, in order:**

**5a) Capture a fresh diff (Claude Code)**

Before invoking Codex, always re-run this to get the current state of the branch:

```bash
git fetch origin
CURRENT_DIFF=$(git diff origin/main...HEAD)
```

Verify `CURRENT_DIFF` is non-empty. If empty: the branch has no changes — STOP and report.

Do NOT reuse a diff captured in a previous round. Every round must capture its own.

**5b) Switch to Codex CLI** — pass the freshly captured diff:

```bash
codex "You are a code risk reviewer. Review the diff below against the original ticket and spec.

TICKET (verbatim):
---
{{ticket}}
---

REQUIREMENT SPEC:
---
{{SPEC_ARTIFACT}}
---

DIFF (current state of branch, captured just now):
---
${CURRENT_DIFF}
---

Run the branch-risk-review skill. For each finding classify as:
- BLOCKER: must fix (HIGH risk, behavioral regression, or out-of-scope change)
- FIX: should fix (MEDIUM risk, consistency issue)
- NOTE: informational only

Also explicitly check and report on each of these:
- Scope drift: does the diff touch anything the ticket did not ask for?
- Diff size: are there files or lines changed that were not necessary?
- DB/schema changes: does the diff include any schema changes, seed data edits, or ORM model changes?
  - Skip migration files (*.sql, migrations/) entirely — humans write those separately. Do not flag, review, or comment on them.
  - For everything else: is each change strictly required by the ticket, with no alternative? If not strictly required → flag as BLOCKER.
- Intent loss: does the implementation still match the ticket's stated goals?
- Hidden data risk: any writes, deletes, or transforms on existing data rows?"
```

Save the Codex output as **RISK_ARTIFACT_N** (where N = round number 1, 2, or 3).

**5c) Switch to Claude Code** — apply only BLOCKER and FIX items using minimal diffs. Do not refactor. Do not address NOTE items.

Exit the loop early if no BLOCKER or FIX items remain after any round.

After round 3, if BLOCKER items still exist: STOP and report. Do not proceed to commit.

---

### Step 6 — AI Comment Cleanup (Claude Code)

**Stay in Claude Code.**

Run the `clean-ai-comments` skill with no arguments (diffs current branch against `origin/main`).

Report lines removed. If nothing to remove, continue.

---

### Step 7 — Commit and Push (Claude Code)

**Stay in Claude Code.**

Run the `commit-push` skill.

- Commit message must follow Conventional Commits and include the ticket identifier if available (e.g., `feat: add login page (#42)`).
- Do not pass `--no-verify`.
- If a hook fails: fix minimally, re-stage, retry once. If it fails again: STOP and report.

---

### Step 8 — Final Report (Codex CLI drafts, Claude Code publishes)

**Switch to Codex CLI** to synthesize the report:

```bash
codex "You are a technical writer. Produce a final delivery report from the artifacts below.

TICKET (verbatim):
---
{{ticket}}
---

REQUIREMENT SPEC:
---
{{SPEC_ARTIFACT}}
---

PLAN:
---
{{PLAN_ARTIFACT}}
---

RISK REVIEW FINDINGS (all rounds — RISK_ARTIFACT_1, RISK_ARTIFACT_2, RISK_ARTIFACT_3 as available):
---
{{RISK_ARTIFACT_1}}

{{RISK_ARTIFACT_2}}

{{RISK_ARTIFACT_3}}
---

Include these sections:

## A) Summary
- What was implemented and why
- What was intentionally not done

## B) Ticket alignment
- Map each acceptance criterion to the code change that satisfies it
- Flag any criterion not addressed
- Confirm no out-of-scope changes

## C) Risk assessment
- Final risk level: LOW / MEDIUM / HIGH
- Remaining NOTEs
- Safe to merge? YES / YES WITH CAUTION / NO

## D) How to test (UI-focused)
- Where to navigate
- Actions to take
- Expected results
- Edge cases to verify

## E) Technical notes
- Files changed
- Assumptions made
- Deferred work or known limitations"
```

**Switch back to Claude Code** to append:

```
## F) GitHub compare URL
```
```bash
gh pr view --json url --jq .url 2>/dev/null || {
  base=$(git remote get-url origin | sed 's/\.git$//')
  branch=$(git branch --show-current)
  echo "${base}/compare/main...${branch}"
}
```

Print the complete report to the user.
