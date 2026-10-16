# agent-setup

A shared registry of **21 reusable skills** for Claude Code, Codex, and Cursor, with their supporting references, examples, licenses, and agent metadata.

Each skill lives once in this checkout. Setup creates links so the apps read the same files, without copying or converting them.

## Structure

```text
agent-setup/
├── skills/
│   ├── argue-to-clarify/
│   │   └── SKILL.md
│   ├── clean-ai-comments/
│   │   └── SKILL.md
│   ├── codebase-study-pack/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── current-work/
│   │   ├── SKILL.md
│   │   ├── agents/
│   │   └── references/
│   ├── db-unsync-fix/
│   │   └── SKILL.md
│   ├── feature-summary/
│   │   └── SKILL.md
│   ├── find-skills/
│   │   └── SKILL.md
│   ├── frontend-design/
│   │   ├── SKILL.md
│   │   └── LICENSE.txt
│   ├── minimal-coding/
│   │   └── SKILL.md
│   ├── name-branch/
│   │   └── SKILL.md
│   ├── name-commit/
│   │   └── SKILL.md
│   ├── pr-description/
│   │   └── SKILL.md
│   ├── query-db/
│   │   └── SKILL.md
│   ├── remotion-best-practices/
│   │   ├── SKILL.md
│   │   └── rules/                       # Remotion guides and examples
│   ├── resolve-conflicts-safely/
│   │   └── SKILL.md
│   ├── review-rebuild/
│   │   ├── SKILL.md
│   │   └── agents/
│   ├── seed-data/
│   │   ├── SKILL.md
│   │   └── agents/
│   ├── summarize-changes/
│   │   └── SKILL.md
│   ├── testing-instructions/
│   │   └── SKILL.md
│   ├── ui-polish/
│   │   └── SKILL.md
│   └── ui-test/
│       ├── SKILL.md
│       └── agents/
├── tests/
│   └── test_install.py
├── install.sh
├── AGENTS.md                      # Shared repository instructions
├── CLAUDE.md                      # Imports AGENTS.md
└── README.md
```

All 21 skill folders are listed above. Each contains `SKILL.md`; supporting files remain inside that skill’s `agents/`, `references/`, or `rules/` folders. Skill folders are siblings so links such as `../current-work/SKILL.md` work in the repository and through installed paths.

`AGENTS.md` holds the shared repository instructions. `CLAUDE.md` contains only `@AGENTS.md`, importing those same instructions for Claude Code. Update shared rules in `AGENTS.md` once.

The categories below group skills by purpose without adding another directory level.

## Skills

| Category | Skill | Purpose |
|---|---|---|
| Planning and scope | [argue-to-clarify](skills/argue-to-clarify/SKILL.md) | Resolve unclear requirements through code-informed design decisions. |
| Planning and scope | [current-work](skills/current-work/SKILL.md) | Establish the feature, fix, changes, and Git baseline in scope. |
| Coding and review | [minimal-coding](skills/minimal-coding/SKILL.md) | Keep changes small and consistent with the codebase. |
| Coding and review | [review-rebuild](skills/review-rebuild/SKILL.md) | Review, repair, and verify the complete scoped change. |
| Coding and review | [clean-ai-comments](skills/clean-ai-comments/SKILL.md) | Remove noisy comments added in the scoped diff. |
| Git | [name-branch](skills/name-branch/SKILL.md) | Generate a branch name from context or current work. |
| Git | [name-commit](skills/name-commit/SKILL.md) | Generate a conventional commit message. |
| Git | [resolve-conflicts-safely](skills/resolve-conflicts-safely/SKILL.md) | Resolve conflicts while preserving both sides' intended behavior. |
| Documentation | [codebase-study-pack](skills/codebase-study-pack/SKILL.md) | Create deep, navigable technical study packs. |
| Documentation | [feature-summary](skills/feature-summary/SKILL.md) | Explain scoped changes, business purpose, and UI testing. |
| Documentation | [summarize-changes](skills/summarize-changes/SKILL.md) | Write a short, plain-English summary of scoped changes. |
| Documentation | [pr-description](skills/pr-description/SKILL.md) | Combine a change summary with existing screenshots in a PR draft. |
| Data | [db-unsync-fix](skills/db-unsync-fix/SKILL.md) | Generate manual SQL for branch-related Prisma schema drift. **Prisma-specific.** |
| Data | [query-db](skills/query-db/SKILL.md) | Answer questions using read-only database queries. |
| Data | [seed-data](skills/seed-data/SKILL.md) | Prepare, verify, and clean up scoped synthetic test records. |
| UI and testing | [frontend-design](skills/frontend-design/SKILL.md) | Design distinctive interfaces grounded in the product brief. |
| UI and testing | [ui-polish](skills/ui-polish/SKILL.md) | Repair and polish the UI of scoped frontend work. |
| UI and testing | [testing-instructions](skills/testing-instructions/SKILL.md) | Produce concrete UI testing steps and example data. |
| UI and testing | [ui-test](skills/ui-test/SKILL.md) | Test an already-running app and report screenshot evidence. |
| Video | [remotion-best-practices](skills/remotion-best-practices/SKILL.md) | Build and render videos with Remotion. **Remotion-specific.** |
| Skill tooling | [find-skills](skills/find-skills/SKILL.md) | Discover skills for additional capabilities. |

## Setup

Clone and install from your chosen permanent location:

```bash
git clone https://github.com/nguyenhoangminh1106/agent-setup.git
cd agent-setup
./install.sh
```

Or bootstrap without cloning manually:

```bash
curl -fsSL https://raw.githubusercontent.com/nguyenhoangminh1106/agent-setup/main/install.sh | bash
```

The piped installer requires Git and keeps its checkout at `~/.local/share/agent-setup`. It updates an existing managed checkout with `git pull --ff-only`. Running the installer from a local clone uses that clone, including uncommitted edits, without downloads.

| Apps | Discovery location | Target |
|---|---|---|
| Codex | `~/.agents/skills/<name>` | `<checkout>/skills/<name>` |
| Cursor | `~/.agents/skills/<name>` | Same folder |
| Claude Code | `~/.claude/skills/<name>` | Same folder |

Codex and Claude support symlinked skill folders, and Cursor discovers the shared `~/.agents/skills/` directory. See the official [Codex](https://learn.chatgpt.com/docs/build-skills), [Claude Code](https://code.claude.com/docs/en/skills), and [Cursor](https://cursor.com/docs/skills) documentation.

Keep the checkout in place. If you move it, rerun setup to repair the links. Restart existing agent sessions if newly linked skills do not appear. App installations, credentials, MCP connections, and specialized dependencies such as Prisma or Remotion are configured separately.

## Updates and migration

- Edit a skill in this checkout once; all apps read the same files.
- To refresh from local skills again, copy the complete selected folders from `~/.agents/skills/`, resolving source symlinks and preserving their supporting files. If those local folders already link to this checkout, they are the same files.
- Push changes and pull them into the source checkout on other machines. Rerun setup after adding or removing skills or moving the checkout.
- Setup retires this registry's legacy command/prompt copies for the selected skills. Identical copies and obsolete links are removed; differing files are preserved in the printed `~/.local/state/agent-setup/backups/migration.*` directory.
- Dangling skill links into this checkout are removed during setup. Other local skills, plugins, and their files are left alone.

The previous ticket pipeline, ticket CLI installer, and Linear API-key setup have been removed. This repository contains only the selected reusable skills and their setup tooling.

## Adding a skill

1. Create `skills/<name>/SKILL.md` with YAML `name` and `description`, followed by instructions.
2. Keep supporting references, scripts, assets, licenses, and metadata inside that folder. Preserve sibling links when importing skills.
3. Update the skill lists in this README and `AGENTS.md`. `CLAUDE.md` imports `AGENTS.md`, so shared instructions are maintained once.
4. Run `./install.sh`. Skill folders are discovered automatically.

## Validation

Run isolated installer tests without touching your real home directory:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
bash -n install.sh
```

## Licenses

Preserve the license terms included with imported skills. In particular, `frontend-design` includes its Apache 2.0 terms in [LICENSE.txt](skills/frontend-design/LICENSE.txt).
