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
  "clean-ai-comments"
  "ticket"
  "spec"
)

# Download then install each skill
for s in "${SKILLS[@]}"; do
  curl -fsSL "$REPO_RAW/skills/${s}.md" -o "$TMP_DIR/${s}.md"
  if [[ ! -s "$TMP_DIR/${s}.md" ]]; then
    echo "ERROR: failed to download skills/${s}.md" >&2
    exit 1
  fi
  rm -f "$HOME/.claude/commands/${s}.md"
  rm -f "$HOME/.codex/prompts/${s}.md"
  rm -f "$HOME/.cursor/commands/${s}.md"
  cp "$TMP_DIR/${s}.md" "$HOME/.claude/commands/${s}.md"
  cp "$TMP_DIR/${s}.md" "$HOME/.codex/prompts/${s}.md"
  cp "$TMP_DIR/${s}.md" "$HOME/.cursor/commands/${s}.md"
done

echo "Installed agent skills (all tools, all skills):"
echo " - Claude : ${SKILLS[*]}"
echo " - Codex  : ${SKILLS[*]}"
echo " - Cursor : ${SKILLS[*]}"
