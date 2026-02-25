#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.claude/commands"
mkdir -p "$HOME/.codex/prompts"
mkdir -p "$HOME/.cursor/commands"

# commit-push
ln -sf "$REPO_DIR/skills/commit-push.md" "$HOME/.claude/commands/commit-push.md"
ln -sf "$REPO_DIR/skills/commit-push.md" "$HOME/.cursor/commands/commit-push.md"

# pr-triage
ln -sf "$REPO_DIR/skills/pr-triage.md" "$HOME/.codex/prompts/pr-triage.md"
ln -sf "$REPO_DIR/skills/pr-triage.md" "$HOME/.cursor/commands/pr-triage.md"

# branch-risk-review
ln -sf "$REPO_DIR/skills/branch-risk-review.md" "$HOME/.codex/prompts/branch-risk-review.md"
ln -sf "$REPO_DIR/skills/branch-risk-review.md" "$HOME/.cursor/commands/branch-risk-review.md"

echo "Installed skills:"
echo " - Claude : commit-push"
echo " - Codex  : pr-triage, branch-risk-review"
echo " - Cursor : commit-push, pr-triage, branch-risk-review"
