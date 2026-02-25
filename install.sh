#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/nguyenhoangminh1106/agent-setup/main"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# Install locations (user-level)
mkdir -p \
  "$HOME/.claude/commands" \
  "$HOME/.codex/prompts" \
  "$HOME/.cursor/commands"

# Skills list
SKILLS=(
  "commit-push"
  "pr-triage"
  "branch-risk-review"
  "worktree-create"
  "worktree-remove"
)

# Download
for s in "${SKILLS[@]}"; do
  curl -fsSL "$REPO_RAW/skills/${s}.md" -o "$TMP_DIR/${s}.md"
done

# Copy to each tool
for s in "${SKILLS[@]}"; do
  cp "$TMP_DIR/${s}.md" "$HOME/.claude/commands/${s}.md"
  cp "$TMP_DIR/${s}.md" "$HOME/.codex/prompts/${s}.md"
  cp "$TMP_DIR/${s}.md" "$HOME/.cursor/commands/${s}.md"
done

echo "Installed agent skills (all tools, all skills):"
echo " - Claude : ${SKILLS[*]}"
echo " - Codex  : ${SKILLS[*]}"
echo " - Cursor : ${SKILLS[*]}"
