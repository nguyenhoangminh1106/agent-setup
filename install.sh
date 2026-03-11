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

# Skills: "name:subfolder/name.md"
# Installed to ~/.claude/commands/<name>.md (flat) — subfolder is repo-only organisation.
SKILLS=(
  "commit-push:git/commit-push.md"
  "name-branch:git/name-branch.md"
  "worktree-create:git/worktree-create.md"
  "worktree-remove:git/worktree-remove.md"
  "branch-risk-review:review/branch-risk-review.md"
  "clean-ai-comments:review/clean-ai-comments.md"
  "pr-description:review/pr-description.md"
  "pr-triage:review/pr-triage.md"
  "clarify:ticket/clarify.md"
  "spec:ticket/spec.md"
  "ticket:ticket/ticket.md"
  "daily-update:project/daily-update.md"
  "feature-summary:project/feature-summary.md"
  "testing-instructions:project/testing-instructions.md"
  "db-unsync-fix:data/db-unsync-fix.md"
  "query-db:data/query-db.md"
)

SKILL_NAMES=()

# Download then install each skill
for entry in "${SKILLS[@]}"; do
  name="${entry%%:*}"
  path="${entry##*:}"
  SKILL_NAMES+=("$name")
  curl -fsSL "$REPO_RAW/skills/${path}" -o "$TMP_DIR/${name}.md"
  if [[ ! -s "$TMP_DIR/${name}.md" ]]; then
    echo "ERROR: failed to download skills/${path}" >&2
    exit 1
  fi
  rm -f "$HOME/.claude/commands/${name}.md"
  rm -f "$HOME/.codex/prompts/${name}.md"
  rm -f "$HOME/.cursor/commands/${name}.md"
  cp "$TMP_DIR/${name}.md" "$HOME/.claude/commands/${name}.md"
  cp "$TMP_DIR/${name}.md" "$HOME/.codex/prompts/${name}.md"
  cp "$TMP_DIR/${name}.md" "$HOME/.cursor/commands/${name}.md"
done

# Install ticket.sh as a global CLI command
mkdir -p "$HOME/bin"
curl -fsSL "$REPO_RAW/ticket.sh" -o "$TMP_DIR/ticket.sh"
if [[ -s "$TMP_DIR/ticket.sh" ]]; then
  cp "$TMP_DIR/ticket.sh" "$HOME/bin/ticket"
  chmod +x "$HOME/bin/ticket"
  echo "Installed: ~/bin/ticket (run 'ticket <issue>' from any repo)"
  echo "  → Make sure ~/bin is in your PATH: export PATH=\"\$HOME/bin:\$PATH\""
else
  echo "WARNING: failed to download ticket.sh — skipping CLI install" >&2
fi

echo ""
echo "Installed agent skills (all tools, all skills):"
echo " - Claude : ${SKILL_NAMES[*]}"
echo " - Codex  : ${SKILL_NAMES[*]}"
echo " - Cursor : ${SKILL_NAMES[*]}"
