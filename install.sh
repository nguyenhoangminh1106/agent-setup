#!/usr/bin/env bash
set -euo pipefail

# A piped installer bootstraps a persistent checkout, then uses its installer.
INSTALL_SCRIPT="${BASH_SOURCE[0]:-}"
if [[ -n "$INSTALL_SCRIPT" && -f "$INSTALL_SCRIPT" ]]; then
  SOURCE_DIR="$(cd "$(dirname "$INSTALL_SCRIPT")" && pwd -P)"
else
  SOURCE_DIR=""
fi
if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR/skills" ]]; then
  SOURCE_DIR="$HOME/.local/share/agent-setup"
  REPO_URL="https://github.com/nguyenhoangminh1106/agent-setup.git"
  if [[ -d "$SOURCE_DIR/.git" ]]; then
    if [[ "$(git -C "$SOURCE_DIR" remote get-url origin)" != "$REPO_URL" ]]; then
      echo "ERROR: $SOURCE_DIR has a different origin; run its installer directly." >&2
      exit 1
    fi
    git -C "$SOURCE_DIR" pull --ff-only
  else
    mkdir -p "$(dirname "$SOURCE_DIR")"
    git clone "$REPO_URL" "$SOURCE_DIR"
  fi
  exec bash "$SOURCE_DIR/install.sh"
fi

SKILL_NAMES=()
SKILL_DIRS=()
for skill_file in "$SOURCE_DIR"/skills/*/SKILL.md; do
  [[ -f "$skill_file" ]] || continue
  skill_dir="${skill_file%/SKILL.md}"
  name="${skill_dir##*/}"
  if ! grep -qx "name: $name" "$skill_file"; then
    echo "ERROR: $skill_file must declare name: $name" >&2
    exit 1
  fi
  SKILL_NAMES+=("$name")
  SKILL_DIRS+=("$skill_dir")
done
if [[ ${#SKILL_NAMES[@]} -eq 0 ]]; then
  echo "ERROR: no skills found in $SOURCE_DIR/skills" >&2
  exit 1
fi

BACKUP_DIR=""
retire_path() {
  local destination="$1"
  local target="$2"
  if [[ -L "$destination" ]]; then
    rm -f "$destination"
  elif [[ -e "$destination" ]]; then
    if diff -qr "$destination" "$target" >/dev/null 2>&1; then
      rm -rf "$destination"
    else
      if [[ -z "$BACKUP_DIR" ]]; then
        mkdir -p "$HOME/.local/state/agent-setup/backups"
        BACKUP_DIR="$(mktemp -d "$HOME/.local/state/agent-setup/backups/migration.XXXXXX")"
      fi
      local backup="$BACKUP_DIR/${destination#"$HOME"/}"
      mkdir -p "$(dirname "$backup")"
      mv "$destination" "$backup"
    fi
  fi
}

link_path() {
  local target="$1"
  local destination="$2"
  if [[ -L "$destination" && "$(readlink "$destination")" == "$target" ]]; then
    return
  fi
  retire_path "$destination" "$target"
  mkdir -p "$(dirname "$destination")"
  ln -s "$target" "$destination"
}

# Remove stale links belonging to this checkout after skills are removed or moved.
for skill_root in "$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.cursor/skills"; do
  for installed_skill in "$skill_root"/*; do
    [[ -L "$installed_skill" ]] || continue
    target="$(readlink "$installed_skill")"
    if [[ "$target" == "$SOURCE_DIR/skills/"* && ! -f "$installed_skill/SKILL.md" ]]; then
      rm -f "$installed_skill"
    fi
  done
done

for ((i = 0; i < ${#SKILL_NAMES[@]}; i++)); do
  name="${SKILL_NAMES[$i]}"
  skill_dir="${SKILL_DIRS[$i]}"
  # Codex and Cursor discover ~/.agents/skills; Claude uses its own skill root.
  link_path "$skill_dir" "$HOME/.agents/skills/$name"
  link_path "$skill_dir" "$HOME/.claude/skills/$name"

  # Retire only this registry's old copies and links, never whole app directories.
  retire_path "$HOME/.claude/commands/$name.md" "$skill_dir/SKILL.md"
  retire_path "$HOME/.cursor/commands/$name.md" "$skill_dir/SKILL.md"
  retire_path "$HOME/.codex/prompts/$name.md" "$skill_dir/SKILL.md"
  for legacy_root in "$HOME/.codex/skills" "$HOME/.cursor/skills"; do
    if [[ "$legacy_root" -ef "$HOME/.agents/skills" || "$legacy_root" -ef "$HOME/.claude/skills" ]]; then
      continue
    fi
    retire_path "$legacy_root/$name" "$skill_dir"
  done
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Shared skill source: $SOURCE_DIR/skills"
echo "Skills (${#SKILL_NAMES[@]}): ${SKILL_NAMES[*]}"
echo " - Codex / Cursor: ~/.agents/skills/<name> → source folder"
echo " - Claude Code:    ~/.claude/skills/<name> → source folder"
if [[ -n "$BACKUP_DIR" ]]; then
  echo "Previous local files that differed were preserved in: $BACKUP_DIR"
fi
echo "Edit skills in the source checkout; all apps read the same files."
echo "Restart existing agent sessions if newly linked skills do not appear."
