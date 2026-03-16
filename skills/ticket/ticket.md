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
| 0a. Branch name (`/name-branch` skill) | **Claude Code** | Derives branch name early so all artifacts are namespaced correctly from the start |
| 0. Clarify (`/clarify` skill) | **Codex CLI (GPT-5.2)** | Reads codebase and asks only unanswerable questions; interactive loop with user |
| 1. Spec (`/spec` skill) | **Codex CLI (GPT-5.2)** | Strong structured reasoning, codebase-aware spec generation |
| 2. Worktree creation | **Claude Code** | Repo-aware, safe git ops |
| 3. Planning | **Codex CLI** | Diff-minimization and plan discipline |
| 4. Implementation | **Claude Code** | Safer code edits, repo-aware |
| 5. Commit and push | **Claude Code** | Push implementation before reviews so all review steps read from the remote branch |
| 6. Spec review loop | **Codex CLI** | Re-validates implementation against spec; each fix round commits and pushes before next review |
| 7. Risk review loop | **Claude Code** | Objective validation against ticket intent; each fix round commits and pushes before next review |
| 8. AI comment cleanup + push | **Claude Code** | Comment-only edits, then push final state |
| 9. Final report | **Claude Code** (feature-summary skill) | Summarizes changes, business purpose, and UI testing steps using spec as context |
| 10. Worktree cleanup | **bash** | Remove local worktree; branch preserved on remote |

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
- `spec-review-1.md`, `spec-review-2.md`, `spec-review-3.md` — per-round spec review output (Step 4b)
- `risk-1.md`, `risk-2.md`, `risk-3.md` — per-round risk review output (Step 5)
- `report.md` — final feature summary and UI testing instructions (Step 8)

Each tool reads its input artifact from disk and writes its output artifact to disk. Never pass stale in-memory content between steps.

**CRITICAL — never inline large artifacts as shell variables.** Always pass artifact paths to the tool and let the tool read them. Inlining large files via `$VAR` expansion hits shell `ARG_MAX` limits and can OOM the process.

## Steps

---

### Step 0a — Branch Name (Codex)

Resolve the branch name before anything else so all artifacts are namespaced correctly.

- If `{{branch}}` was provided: use it. Skip this step.
- Otherwise, run:
  ```bash
  claude -p "/name-branch <ticket-input-file>"
  ```
  Parse `BRANCH:<name>` from the output. All subsequent artifacts go to `.ticket/<branch>/`.

---

### Step 0 — Clarify (Codex, interactive loop)

Run the `/clarify` skill up to 3 rounds. Each round reads the ticket (plus any accumulated answers from previous rounds) and checks whether anything is genuinely unclear that cannot be inferred from the codebase.

```bash
codex exec "/clarify <ticket-plus-answers>"
```

**After each round:**
- If output contains `CLARIFY:DONE` → proceed to Step 1.
- If output contains `CLARIFY:QUESTIONS` → print the questions to the terminal, read the user's answers interactively, append them to the ticket input as `## Answers (round N)`, and re-run.
- If the user provides no answers → stop clarify loop and proceed.
- After round 3 → proceed regardless.

Pass the full accumulated ticket + answers as `{{ticket}}` to Step 1 so the spec has all context.

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
codex exec "/spec <ticket-input>" | tee .ticket/<branch>/spec.md
```

The `/spec` skill outputs the spec to stdout — `ticket.sh` pipes it directly to `.ticket/<branch>/spec.md`. Verify the file is non-empty after the command exits — if not, STOP and report.

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

After the skill runs, resolve the worktree path:
1. Primary: `<repo>/.claude/worktrees/<branch>`
2. Fallback: `git worktree list --porcelain` — find the entry whose branch matches

Do not continue until the worktree path is confirmed. All subsequent steps must run inside this directory.

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

```bash
claude -p "You are running inside the git worktree at: <worktreePath>
CRITICAL: All file reads and writes MUST use paths inside <worktreePath> only.

Execute this plan. Match existing code style and patterns. No new dependencies or abstractions unless the spec requires them. Do not touch files outside the plan.

Safety: no force push, no DROP/DELETE/ALTER TABLE/migrations, no changes to main or master. If any guard fires: STOP and report.

Read the plan from disk: .ticket/<branch>/plan.md"
```

---

### Step 5 — Commit and Push initial implementation (Claude Code)

Push the implementation to the remote branch before any reviews, so all review steps read from a consistent pushed state.

```bash
claude -p "Run /commit-push to commit all changes and push to branch <branch>."
```

---

### Step 6 — Spec Review Loop (Codex reviews, Claude Code fixes, push each round)

Run up to 3 rounds. Each round reads the diff from the **pushed remote branch**, not local state. After fixes, push before the next round.

**Each round:**

**6-i) Capture diff from remote branch**
```bash
git -C <worktreePath> fetch origin
git -C <worktreePath> diff origin/main...origin/<branch> > .ticket/<branch>/diff-current.md
```
If the diff is empty: STOP and report — no changes on branch.

**6-ii) Codex reviews spec alignment**
```bash
# Run in the worktree so Codex reads the implemented files
codex exec -s read-only -C <worktreePath> "You are a spec compliance reviewer. Check whether the implementation satisfies every requirement in the spec.

Read both artifacts fresh from disk:
- Spec: .ticket/<branch>/spec.md
- Diff: .ticket/<branch>/diff-current.md

Classify each finding:
- BLOCKER: a spec requirement is missing or incorrectly implemented
- FIX: a requirement is partially met or could better match the spec intent
- NOTE: informational only

Explicitly check:
- Are all acceptance criteria from the spec addressed in the diff?
- Does the implementation match the spec's described behavior exactly?
- Are there any spec requirements not yet implemented?
- Does anything in the diff contradict the spec?"
```
Save output to `.ticket/<branch>/spec-review-<N>.md`. Exit loop early if no BLOCKER or FIX items.

**6-iii) Claude Code applies fixes then pushes**
```bash
claude -p "You are running inside the git worktree at: <worktreePath>
All file reads and writes MUST use paths inside <worktreePath> only.

Apply only the BLOCKER and FIX items from the spec review. Minimal diffs only. No refactors. Ignore NOTE items.

Read the spec review from disk: .ticket/<branch>/spec-review-<N>.md
Read the spec from disk: .ticket/<branch>/spec.md"

claude -p "Run /commit-push to push fixes."
```

After round 3, if BLOCKERs still exist: STOP and report.

---

### Step 7 — Risk Review Loop (Claude Code reviews, fixes, push each round)

Run up to 3 rounds. Each round reads the diff from the **pushed remote branch**.

**Each round:**

**7-i) Capture diff from remote branch**
```bash
git -C <worktreePath> fetch origin
git -C <worktreePath> diff origin/main...origin/<branch> > .ticket/<branch>/diff-current.md
```
If the diff is empty: STOP and report — no changes on branch.

**7-ii) Claude Code reviews**
```bash
claude -p "You are a code risk reviewer. Review the diff against the spec.

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
- Hidden data risk: any writes, deletes, or transforms on existing data rows?

Save your full review output to: .ticket/<branch>/risk-<N>.md"
```
Exit loop early if no BLOCKER or FIX items.

**7-iii) Claude Code applies fixes then pushes**
```bash
claude -p "You are running inside the git worktree at: <worktreePath>
All file reads and writes MUST use paths inside <worktreePath> only.

Apply only the BLOCKER and FIX items from the risk review. Minimal diffs only. No refactors. Ignore NOTE items.

Read the risk review from disk: .ticket/<branch>/risk-<N>.md"

claude -p "Run /commit-push to push fixes."
```

After round 3, if BLOCKERs still exist: STOP and report.

---

### Step 8 — AI Comment Cleanup then push (Claude Code)

```bash
claude -p "/clean-ai-comments"
claude -p "Run /commit-push to push the comment cleanup."
```

---

### Step 9 — Final Report (Claude Code via feature-summary skill)

```bash
claude -p "/feature-summary target=<branch> spec=.ticket/<branch>/spec.md db=skip" \
  | tee .ticket/<branch>/report.md
```

Append the compare URL:
```bash
COMPARE_URL=$(gh pr view <branch> --json url --jq .url 2>/dev/null || {
  base=$(git -C <worktreePath> remote get-url origin | sed 's/\.git$//')
  echo "${base}/compare/main...<branch>"
})
echo "" >> .ticket/<branch>/report.md
echo "---" >> .ticket/<branch>/report.md
echo "Compare: $COMPARE_URL" >> .ticket/<branch>/report.md
```

---

### Step 10 — Worktree Cleanup

The worktree-remove skill is interactive (it asks "Proceed?") and will block when called headlessly. Run the removal directly instead:

```bash
cd <repo>
git worktree remove "<worktreePath>" || git worktree remove --force "<worktreePath>"
git worktree prune
```

Do NOT delete the branch. If the worktree directory does not exist, skip and log a warning.

Print on success:
```
✓ Step 10 — Worktree Cleanup complete  (worktree removed, branch <branch> preserved on remote)
```
