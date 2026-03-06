#!/usr/bin/env bash
# ticket.sh — multi-agent ticket implementation pipeline
# Usage:
#   ticket                              # opens editor to paste ticket
#   ticket 142                          # GitHub issue number
#   ticket "some text"                  # inline text
#   ticket branch=fix/foo               # resume a branch — auto-skips spec/plan if artifacts exist
#   ticket repo=/path/to/repo           # with optional repo path
#
# Artifacts are stored per-branch in .ticket/<branch>/ so multiple tickets
# in the same repo never overwrite each other.
# If spec.md already exists for the branch, spec is skipped automatically.
# If plan.md already exists for the branch, planning is skipped automatically.
set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
TICKET=""
BRANCH=""
REPO="$(pwd)"

for arg in "$@"; do
  case "$arg" in
    --skip-spec) ;;  # kept for backwards compat, now a no-op (auto-detected)
    branch=*)    BRANCH="${arg#branch=}" ;;
    repo=*)      REPO="${arg#repo=}" ;;
    *)           TICKET="$arg" ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────
# Artifacts are namespaced by branch so multiple tickets in the same repo
# never overwrite each other. Branch name is resolved after Step 1 (spec).
# ARTIFACTS is set properly once BRANCH is known (after Step 1).
ARTIFACTS_ROOT="$REPO/.ticket"
mkdir -p "$ARTIFACTS_ROOT"

log()  { echo ""; echo "▶ $*"; echo ""; }
die()  { echo "[STATUS:failed] $*" >&2; echo ""; echo "ERROR: $*" >&2; exit 1; }
# step N "desc" — emits [STEP:N] prefix for dashboard parsing then calls log()
step() { local n="$1"; local desc="$2"; echo "[STEP:${n}] ${desc}"; log "Step ${n} — ${desc}"; }

require() {
  command -v "$1" &>/dev/null || die "'$1' is not installed or not in PATH"
}

require codex
require claude
require git
require gh

# WORKTREE is set after Step 2 once we know the path.
# claude_run and codex_run use it to run in the correct directory.
WORKTREE=""

# claude_run: runs Claude Code headlessly in the worktree directory
claude_run() {
  if [[ -n "$WORKTREE" ]]; then
    (cd "$WORKTREE" && claude --dangerously-skip-permissions -p "$1")
  else
    claude --dangerously-skip-permissions -p "$1"
  fi
}

# codex_run: runs Codex non-interactively in the worktree directory
codex_run() {
  if [[ -n "$WORKTREE" ]]; then
    codex exec --full-auto -C "$WORKTREE" "$1"
  else
    codex exec --full-auto "$1"
  fi
}

# ── Input: open editor if no ticket provided ───────────────────────────────────
# If branch is given and spec already exists, we can skip input entirely.
if [[ -n "$BRANCH" && -s "$ARTIFACTS_ROOT/$BRANCH/spec.md" ]]; then
  ARTIFACTS="$ARTIFACTS_ROOT/$BRANCH"
  echo "Found existing spec at $ARTIFACTS/spec.md — skipping input and spec generation."
elif [[ -n "$BRANCH" ]]; then
  : # branch given but no spec yet — skip editor, let Step 1 generate spec
elif [[ -z "$TICKET" ]]; then
  INPUT_FILE="$(mktemp /tmp/ticket-input.XXXXXX.md)"

  cat > "$INPUT_FILE" <<'TEMPLATE'
<!-- Paste your ticket, chat history, context, screenshots descriptions, decisions below. -->
<!-- Delete these comment lines when done. Save and close to continue. -->

TEMPLATE

  # prefer VS Code, fall back to $EDITOR, then nano
  if command -v code &>/dev/null; then
    echo "Opening VS Code — paste your ticket, save, and close the tab to continue..."
    code --wait "$INPUT_FILE"
  elif [[ -n "${EDITOR:-}" ]]; then
    echo "Opening $EDITOR — paste your ticket, save and exit to continue..."
    "$EDITOR" "$INPUT_FILE"
  else
    echo "Opening nano — paste your ticket, then Ctrl+X → Y → Enter to continue..."
    nano "$INPUT_FILE"
  fi

  # strip comment lines and leading/trailing blank lines
  TICKET=$(sed '/^<!--/d' "$INPUT_FILE" | sed '/^$/N;/^\n$/d' | xargs -0 echo -n)
  rm -f "$INPUT_FILE"

  if [[ -z "$TICKET" ]]; then
    echo "No input provided — exiting." >&2
    exit 1
  fi
fi

# ── Step 1 — Spec (Codex via /spec skill) ─────────────────────────────────────
# Auto-skip if spec already exists for this branch (ARTIFACTS already set above).
if [[ -z "${ARTIFACTS:-}" ]]; then
  step 1 "Spec (Codex)"
  SPEC_TMP="$ARTIFACTS_ROOT/.spec-tmp.md"
  codex_run "/spec $TICKET" > "$SPEC_TMP"
  [[ -s "$SPEC_TMP" ]] || die "spec output is empty — codex /spec failed"

  # Derive branch name from spec if not provided
  if [[ -z "$BRANCH" ]]; then
    GOAL=$(grep -m1 "^##* Goal" "$SPEC_TMP" -A1 | tail -1 | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '-' | cut -c1-50)
    BRANCH="feat/${GOAL:-ticket-$(date +%s)}"
  fi

  ARTIFACTS="$ARTIFACTS_ROOT/$BRANCH"
  mkdir -p "$ARTIFACTS"
  mv "$SPEC_TMP" "$ARTIFACTS/spec.md"
  echo "Spec saved to $ARTIFACTS/spec.md"
else
  echo "Step 1 — Spec: skipped (using existing $ARTIFACTS/spec.md)"
fi
# Emit branch name for dashboard display
echo "[BRANCH:${BRANCH}]"

# ── Step 2 — Worktree (Claude Code) ───────────────────────────────────────────
step 2 "Worktree (Claude Code)"

echo "Branch: $BRANCH"
claude_run "/worktree-create branch=$BRANCH repo=$REPO yes=true"

# Resolve worktree path — always inside the repo under .claude/worktrees
WORKTREE=""
if [[ -d "$REPO/.claude/worktrees/$BRANCH" ]]; then
  WORKTREE="$REPO/.claude/worktrees/$BRANCH"
fi

if [[ -z "$WORKTREE" ]]; then
  # Fallback: ask git directly (covers any path the skill may have used)
  WORKTREE="$(git -C "$REPO" worktree list --porcelain | awk '/^worktree/{wt=$2} /^branch refs\/heads\/'"$BRANCH"'$/{print wt}' | head -1)"
fi

if [[ -z "$WORKTREE" ]]; then
  die "Worktree not found after creation. Expected $REPO/.claude/worktrees/$BRANCH"
fi

echo "Working directory: $WORKTREE"
# Also cd into it so shell-level git commands (Step 5 diff) run in the right place
cd "$WORKTREE"

# ── Step 3 — Plan (Codex) ─────────────────────────────────────────────────────
# Auto-skip if plan already exists for this branch.
if [[ -s "$ARTIFACTS/plan.md" ]]; then
  echo "[STEP:3] Plan: skipped (using existing $ARTIFACTS/plan.md)"
else
  step 3 "Plan (Codex)"

  codex_run "You are a software planner. Produce a minimal-diff Execution Plan.

Read the spec from disk: $ARTIFACTS/spec.md

Output format:

## Files to change
(each file + one-line reason)

## Files NOT to touch
(each + reason)

## DB / schema changes
NONE, or list each with justification. Only acceptable if strictly required by the spec with no alternative.

## Implementation approach
(prose, <=10 lines)

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
5. Acceptable code quality" > "$ARTIFACTS/plan.md"

  [[ -s "$ARTIFACTS/plan.md" ]] || die "plan.md is empty — codex planning failed"
  echo "Plan saved to $ARTIFACTS/plan.md"
fi

# ── Step 4 — Implementation (Claude Code) ─────────────────────────────────────
step 4 "Implementation (Claude Code)"

claude_run "Execute this plan inside the current worktree. Match existing code style and patterns. No new dependencies or abstractions unless the spec requires them. Do not touch files outside the plan.

Safety: no force push, no DROP/DELETE/ALTER TABLE/migrations, no changes to main or master. If any guard fires: STOP and report.

Read the plan from disk: $ARTIFACTS/plan.md"

# ── Step 4b — Spec Review Loop (Codex reviews, Claude fixes) ──────────────────
step "4b" "Spec Review Loop (Codex reviews, Claude fixes)"

for ROUND in 1 2 3; do
  echo "[STEP:4b] Spec review round ${ROUND}/3"
  log "  Spec review round $ROUND / 3"

  # 4b-i: fresh diff
  git fetch origin
  git diff origin/main...HEAD > "$ARTIFACTS/diff-current.md"

  if [[ ! -s "$ARTIFACTS/diff-current.md" ]]; then
    echo "  No diff found — branch has no changes. Stopping."
    break
  fi

  # 4b-ii: Codex reviews spec alignment
  codex_run "You are a spec compliance reviewer. Check whether the implementation satisfies every requirement in the spec.

Read both artifacts fresh from disk:
- Spec: $ARTIFACTS/spec.md
- Diff: $ARTIFACTS/diff-current.md

Classify each finding:
- BLOCKER: a spec requirement is missing or incorrectly implemented
- FIX: a requirement is partially met or could better match the spec intent
- NOTE: informational only

Explicitly check:
- Are all acceptance criteria from the spec addressed in the diff?
- Does the implementation match the spec's described behavior exactly?
- Are there any spec requirements not yet implemented?
- Does anything in the diff contradict the spec?" > "$ARTIFACTS/spec-review-${ROUND}.md"

  echo "  Spec review saved to $ARTIFACTS/spec-review-${ROUND}.md"

  # Check for BLOCKERs or FIXes
  if ! grep -qiE "^-?\s*(BLOCKER|FIX):" "$ARTIFACTS/spec-review-${ROUND}.md"; then
    echo "  No BLOCKER or FIX items — exiting spec review loop early."
    break
  fi

  # 4b-iii: Claude applies fixes
  claude_run "Apply only the BLOCKER and FIX items from the spec review. Minimal diffs only. No refactors. Ignore NOTE items.

Read the spec review from disk: $ARTIFACTS/spec-review-${ROUND}.md
Read the spec from disk: $ARTIFACTS/spec.md"

  if [[ "$ROUND" -eq 3 ]]; then
    if grep -qiE "^-?\s*BLOCKER:" "$ARTIFACTS/spec-review-${ROUND}.md"; then
      die "Spec BLOCKERs still present after 3 rounds. Stopping — human review required."
    fi
  fi
done

# ── Step 5 — Risk Review Loop (Claude reviews and fixes) ──────────────────────
step 5 "Risk Review Loop (Claude Code)"

for ROUND in 1 2 3; do
  echo "[STEP:5] Risk review round ${ROUND}/3"
  log "  Risk review round $ROUND / 3"

  # 5a: fresh diff (shell is cd'd into worktree, so git runs in the right branch)
  git fetch origin
  git diff origin/main...HEAD > "$ARTIFACTS/diff-current.md"

  if [[ ! -s "$ARTIFACTS/diff-current.md" ]]; then
    echo "  No diff found — branch has no changes. Stopping."
    break
  fi

  # 5b: Claude reviews
  claude_run "You are a code risk reviewer. Review the diff against the spec.

Read both artifacts fresh from disk:
- Spec: $ARTIFACTS/spec.md
- Diff: $ARTIFACTS/diff-current.md

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

Save your full review output to: $ARTIFACTS/risk-${ROUND}.md"

  [[ -s "$ARTIFACTS/risk-${ROUND}.md" ]] || die "risk-${ROUND}.md is empty — Claude risk review failed"
  echo "  Risk review saved to $ARTIFACTS/risk-${ROUND}.md"

  # Check for BLOCKERs or FIXes
  if ! grep -qiE "^-?\s*(BLOCKER|FIX):" "$ARTIFACTS/risk-${ROUND}.md"; then
    echo "  No BLOCKER or FIX items — exiting review loop early."
    break
  fi

  # 5c: Claude applies fixes
  claude_run "Apply only the BLOCKER and FIX items from the risk review. Minimal diffs only. No refactors. Ignore NOTE items.

Read the risk review from disk: $ARTIFACTS/risk-${ROUND}.md"

  if [[ "$ROUND" -eq 3 ]]; then
    if grep -qiE "^-?\s*BLOCKER:" "$ARTIFACTS/risk-${ROUND}.md"; then
      die "BLOCKERs still present after 3 rounds. Stopping — human review required."
    fi
  fi
done

# ── Step 6 — AI Comment Cleanup (Claude Code) ─────────────────────────────────
step 6 "AI Comment Cleanup (Claude Code)"
claude_run "/clean-ai-comments"

# ── Step 7 — Commit and Push (Claude Code) ────────────────────────────────────
step 7 "Commit and Push (Claude Code)"
claude_run "/commit-push"

# ── Step 8 — Final Report (Claude Code via feature-summary skill) ──────────────
step 8 "Final Report (Claude Code)"

claude_run "/feature-summary target=$BRANCH spec=$ARTIFACTS/spec.md db=skip"

echo ""
echo "── Compare URL ──────────────────────────────────────────"
gh pr view --json url --jq .url 2>/dev/null || {
  base=$(git remote get-url origin | sed 's/\.git$//')
  branch=$(git branch --show-current)
  echo "${base}/compare/main...${branch}"
}
echo ""

# ── Step 9 — Worktree Cleanup (Claude Code) ───────────────────────────────────
step 9 "Worktree Cleanup (Claude Code)"
# Run from the repo root, not the worktree, since we're about to remove it
(cd "$REPO" && claude --dangerously-skip-permissions -p "/worktree-remove target=$BRANCH repo=$REPO")
echo "Worktree removed. Branch $BRANCH is preserved on the remote."
echo "[STATUS:completed]"
