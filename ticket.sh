#!/usr/bin/env bash
# ticket.sh — multi-agent ticket implementation pipeline
# Usage:
#   ticket                              # opens editor to paste ticket
#   ticket 142                          # GitHub issue number
#   ticket "some text"                  # inline text
#   ticket --skip-spec branch=fix/foo   # skip spec, use existing .ticket/fix/foo/spec.md
#   ticket branch=fix/foo               # with optional branch name
#   ticket repo=/path/to/repo           # with optional repo path
#
# Artifacts are stored per-branch in .ticket/<branch>/ so multiple tickets
# in the same repo never overwrite each other.
set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
TICKET=""
BRANCH=""
REPO="$(pwd)"
SKIP_SPEC=0

for arg in "$@"; do
  case "$arg" in
    --skip-spec) SKIP_SPEC=1 ;;
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
die()  { echo ""; echo "ERROR: $*" >&2; exit 1; }

require() {
  command -v "$1" &>/dev/null || die "'$1' is not installed or not in PATH"
}

require codex
require claude
require git
require gh

# Non-interactive wrappers
# claude_run: runs Claude Code headlessly, streams output to stdout
claude_run() {
  claude --dangerously-skip-permissions -p "$1"
}

# codex_run: runs Codex non-interactively, captures stdout
codex_run() {
  codex exec --full-auto "$1"
}

# ── Input: open editor if no ticket provided (skip if --skip-spec) ────────────
if [[ "$SKIP_SPEC" -eq 1 ]]; then
  [[ -n "$BRANCH" ]] || { echo "ERROR: --skip-spec requires branch=<name> so we know which artifact folder to use" >&2; exit 1; }
  ARTIFACTS="$ARTIFACTS_ROOT/$BRANCH"
  [[ -s "$ARTIFACTS/spec.md" ]] || { echo "ERROR: --skip-spec requires an existing .ticket/$BRANCH/spec.md" >&2; exit 1; }
  echo "Skipping spec — using existing $ARTIFACTS/spec.md"
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
if [[ "$SKIP_SPEC" -eq 0 ]]; then
  log "Step 1 — Spec (Codex)"
  SPEC_TMP="$ARTIFACTS_ROOT/.spec-tmp.md"
  codex_run "/spec $TICKET" > "$SPEC_TMP"
  [[ -s "$SPEC_TMP" ]] || die "spec output is empty — codex /spec failed"
fi

# ── Step 2 — Worktree (Claude Code) ───────────────────────────────────────────
log "Step 2 — Worktree (Claude Code)"

# Derive branch name from spec if not provided
if [[ -z "$BRANCH" ]]; then
  SPEC_FOR_BRANCH="${SPEC_TMP:-$ARTIFACTS_ROOT/.spec-tmp.md}"
  GOAL=$(grep -m1 "^##* Goal" "$SPEC_FOR_BRANCH" -A1 | tail -1 | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '-' | cut -c1-50)
  BRANCH="feat/${GOAL:-ticket-$(date +%s)}"
fi

# Now that branch is known, set the namespaced artifact dir
ARTIFACTS="$ARTIFACTS_ROOT/$BRANCH"
mkdir -p "$ARTIFACTS"

# Move spec into the namespaced folder
if [[ "$SKIP_SPEC" -eq 0 ]]; then
  mv "$SPEC_TMP" "$ARTIFACTS/spec.md"
  echo "Spec saved to $ARTIFACTS/spec.md"
fi

echo "Branch: $BRANCH"
claude_run "/worktree-create branch=$BRANCH repo=$REPO"

# cd into worktree so subsequent steps run inside it
WORKTREE_PATH="$REPO/.claude/worktrees/$BRANCH"
if [[ -d "$WORKTREE_PATH" ]]; then
  cd "$WORKTREE_PATH"
else
  # fallback: try codex/cursor worktree paths
  for base in "$REPO/.codex/worktrees" "$REPO/.cursor/worktrees"; do
    if [[ -d "$base/$BRANCH" ]]; then
      cd "$base/$BRANCH"
      break
    fi
  done
fi

echo "Working directory: $(pwd)"

# ── Step 3 — Plan (Codex) ─────────────────────────────────────────────────────
log "Step 3 — Plan (Codex)"

SPEC=$(cat "$ARTIFACTS/spec.md")

codex_run "You are a software planner. Produce a minimal-diff Execution Plan.

SPEC:
---
$SPEC
---

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

# ── Step 4 — Implementation (Claude Code) ─────────────────────────────────────
log "Step 4 — Implementation (Claude Code)"

PLAN=$(cat "$ARTIFACTS/plan.md")

claude_run "Execute this plan inside the current worktree. Match existing code style and patterns. No new dependencies or abstractions unless the spec requires them. Do not touch files outside the plan.

Safety: no force push, no DROP/DELETE/ALTER TABLE/migrations, no changes to main or master. If any guard fires: STOP and report.

PLAN:
---
$PLAN
---"

# ── Step 5 — Risk Review Loop (Codex reviews, Claude fixes) ───────────────────
log "Step 5 — Risk Review Loop"

for ROUND in 1 2 3; do
  log "  Risk review round $ROUND / 3"

  # 5a: fresh diff
  git fetch origin
  git diff origin/main...HEAD > "$ARTIFACTS/diff-current.md"

  if [[ ! -s "$ARTIFACTS/diff-current.md" ]]; then
    echo "  No diff found — branch has no changes. Stopping."
    break
  fi

  # 5b: Codex reviews
  SPEC=$(cat "$ARTIFACTS/spec.md")
  DIFF=$(cat "$ARTIFACTS/diff-current.md")

  codex_run "You are a code risk reviewer. Review the diff against the spec.

SPEC:
---
$SPEC
---

DIFF (current branch state, captured just now):
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
- DB/schema changes (skip *.sql and migrations/ — humans write those): any ORM model or schema change not strictly required? → BLOCKER.
- Intent loss: does the implementation still match the spec goals?
- Hidden data risk: any writes, deletes, or transforms on existing data rows?" > "$ARTIFACTS/risk-${ROUND}.md"

  echo "  Risk review saved to $ARTIFACTS/risk-${ROUND}.md"

  # Check for BLOCKERs or FIXes
  if ! grep -qiE "^-?\s*(BLOCKER|FIX):" "$ARTIFACTS/risk-${ROUND}.md"; then
    echo "  No BLOCKER or FIX items — exiting review loop early."
    break
  fi

  # 5c: Claude applies fixes
  RISK=$(cat "$ARTIFACTS/risk-${ROUND}.md")

  claude_run "Apply only the BLOCKER and FIX items from the risk review below. Minimal diffs only. No refactors. Ignore NOTE items.

RISK REVIEW:
---
$RISK
---"

  if [[ "$ROUND" -eq 3 ]]; then
    if grep -qiE "^-?\s*BLOCKER:" "$ARTIFACTS/risk-${ROUND}.md"; then
      die "BLOCKERs still present after 3 rounds. Stopping — human review required."
    fi
  fi
done

# ── Step 6 — AI Comment Cleanup (Claude Code) ─────────────────────────────────
log "Step 6 — AI Comment Cleanup (Claude Code)"
claude_run "/clean-ai-comments"

# ── Step 7 — Commit and Push (Claude Code) ────────────────────────────────────
log "Step 7 — Commit and Push (Claude Code)"
claude_run "/commit-push"

# ── Step 8 — Final Report (Codex drafts) ──────────────────────────────────────
log "Step 8 — Final Report (Codex)"

SPEC=$(cat "$ARTIFACTS/spec.md")
PLAN=$(cat "$ARTIFACTS/plan.md")
RISK1=$(cat "$ARTIFACTS/risk-1.md" 2>/dev/null || echo "")
RISK2=$(cat "$ARTIFACTS/risk-2.md" 2>/dev/null || echo "")
RISK3=$(cat "$ARTIFACTS/risk-3.md" 2>/dev/null || echo "")

codex_run "Produce a final delivery report.

SPEC:
$SPEC

PLAN:
$PLAN

RISK REVIEWS:
$RISK1
$RISK2
$RISK3

Sections:
## A) Summary — what was done, what was intentionally left out
## B) Ticket alignment — map each acceptance criterion to the change that satisfies it; flag any unaddressed
## C) Risk assessment — final level LOW/MEDIUM/HIGH; safe to merge? YES / YES WITH CAUTION / NO
## D) How to test — step-by-step UI instructions; expected results; edge cases
## E) Technical notes — files changed, assumptions, deferred work"

echo ""
echo "── Compare URL ──────────────────────────────────────────"
gh pr view --json url --jq .url 2>/dev/null || {
  base=$(git remote get-url origin | sed 's/\.git$//')
  branch=$(git branch --show-current)
  echo "${base}/compare/main...${branch}"
}
echo ""
