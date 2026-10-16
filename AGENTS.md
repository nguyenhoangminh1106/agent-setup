# AGENTS.md

Shared repository instructions for coding agents. Claude Code imports this file through `CLAUDE.md`.

## What this repo is

A shared registry of 21 reusable skills for Claude Code, Codex, and Cursor. Skill folders are fresh copies of the selected current local skills, including supporting resources and metadata. `skills/<name>/SKILL.md` is the canonical entrypoint. Keep skills as sibling folders so their relative links remain valid.

## Installing / updating

```bash
# From a local checkout; links directly to these files
./install.sh

# Or bootstrap a persistent checkout at ~/.local/share/agent-setup
curl -fsSL https://raw.githubusercontent.com/nguyenhoangminh1106/agent-setup/main/install.sh | bash
```

Codex and Cursor discover links in `~/.agents/skills/<name>`. Claude Code follows links in `~/.claude/skills/<name>`. All links point to the same checkout folders; there is no per-app conversion or copied installation.

Local edits are immediately shared. Push and pull to update other machines; rerun setup after adding/removing skills or moving the checkout. Setup preserves differing previous local files under `~/.local/state/agent-setup/backups/` and removes dangling skill links into this checkout. It leaves unrelated local skills and plugins alone. Do not run setup against the user's real home unless installation is part of the request.

## Skill inventory

- Planning and scope: `argue-to-clarify`, `current-work`.
- Coding and review: `minimal-coding`, `review-rebuild`, `clean-ai-comments`.
- Git: `name-branch`, `name-commit`, `resolve-conflicts-safely`.
- Documentation: `codebase-study-pack`, `feature-summary`, `summarize-changes`, `pr-description`.
- Data: `db-unsync-fix` (Prisma-specific), `query-db`, `seed-data`.
- UI and testing: `frontend-design`, `ui-polish`, `testing-instructions`, `ui-test`.
- Video: `remotion-best-practices` (Remotion-specific).
- Skill tooling: `find-skills`.

## Architecture

- `skills/<name>/SKILL.md` — Shared skill instructions with YAML `name` and `description`.
- Folder-local `references/`, `rules/`, `agents/`, scripts, assets, and license files — Preserve these when importing or updating skills.
- `install.sh` — Discovers `skills/*/SKILL.md`, links selected skills, and migrates their old app paths. Piped setup clones or updates a persistent checkout; local setup does not download files.
- `tests/test_install.py` — Integration checks using disposable checkouts and home directories.

The old ticket skills, ticket pipeline, and CLI/API-key setup are no longer part of this repository.

## Adding or refreshing skills

1. Create or copy the complete `skills/<name>/` folder. For local imports, read the current source and resolve source symlinks so the repo is self-contained.
2. Preserve supporting files, license terms, metadata, and working relative links. Do not rewrite a fresh imported prompt unless requested.
3. Update the skill inventory in `README.md` and `AGENTS.md`. Keep `CLAUDE.md` as an import of `AGENTS.md`. The installer needs no manifest entry.
4. Run isolated validation, then use `./install.sh` when local installation is requested. Push and pull to distribute changes.

## Validation

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
bash -n install.sh
```

## Working conventions

- Update `README.md` for new/removed skills, structural changes, or new usage patterns; skip it for minor internal fixes.
- Keep shared instructions in one place and preserve imported licenses.
- Safety > cleverness; read-only unless explicitly permitted.
- Minimal diff > ideal design; avoid unrelated refactors.
- Always ask before executing state-changing commands unless the user has already authorized them.
- Never bypass hooks (`--no-verify`).
