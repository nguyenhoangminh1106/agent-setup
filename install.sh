#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/nguyenhoangminh1106/agent-setup/main"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

mkdir -p "$HOME/.claude/commands" "$HOME/.codex/prompts" "$HOME/.cursor/commands"

# Download skills
curl -fsSL "$REPO_RAW/skills/commit-push.md" -o "$TMP_DIR/commit-push.md"
curl -fsSL "$REPO_RAW/skills/pr-triage.md" -o "$TMP_DIR/pr-triage.md"
curl -fsSL "$REPO_RAW/skills/branch-risk-review.md" -o "$TMP_DIR/branch-risk-review.md"

# Install ALL skills into ALL tools (copy, no clone needed)
cp "$TMP_DIR/commit-push.md" "$HOME/.claude/commands/commit-push.md"
cp "$TMP_DIR/pr-triage.md" "$HOME/.claude/commands/pr-triage.md"
cp "$TMP_DIR/branch-risk-review.md" "$HOME/.claude/commands/branch-risk-review.md"

cp "$TMP_DIR/commit-push.md" "$HOME/.codex/prompts/commit-push.md"
cp "$TMP_DIR/pr-triage.md" "$HOME/.codex/prompts/pr-triage.md"
cp "$TMP_DIR/branch-risk-review.md" "$HOME/.codex/prompts/branch-risk-review.md"

cp "$TMP_DIR/commit-push.md" "$HOME/.cursor/commands/commit-push.md"
cp "$TMP_DIR/pr-triage.md" "$HOME/.cursor/commands/pr-triage.md"
cp "$TMP_DIR/branch-risk-review.md" "$HOME/.cursor/commands/branch-risk-review.md"

echo "Installed agent skills (all tools, all skills):"
echo " - Claude : commit-push, pr-triage, branch-risk-review"
echo " - Codex  : commit-push, pr-triage, branch-risk-review"
echo " - Cursor : commit-push, pr-triage, branch-risk-review"
