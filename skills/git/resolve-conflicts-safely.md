---
description: "Resolve Git merge/rebase conflicts with minimal, behavior-preserving edits. Use when the user says there are conflicts, asks to resolve a merge/rebase, asks to \"ensure break nothing\", wants only conflict-resolution changes, or wants Codex to clean up conflict markers without broad refactors, migrations, regeneration, tests, or unrelated edits unless explicitly requested."
---

# Resolve Conflicts Safely

## Goal

Resolve only the conflicted files, preserve both branches' intended behavior when compatible, avoid unrelated cleanup, and leave the worktree in a clear state.

## Workflow

1. Inspect the conflict surface:
   - Run `git diff --name-only --diff-filter=U`.
   - Run `rg -n "^(<<<<<<<|=======|>>>>>>>)" <unmerged-files>`.
   - Read only the conflicted hunks and enough surrounding code to understand both sides.

2. Determine each side's intent:
   - Use `git show :1:<file>`, `git show :2:<file>`, and `git show :3:<file>` when the conflict is non-trivial.
   - Treat `:2:` as ours/current branch and `:3:` as theirs/incoming branch.
   - Prefer a union of both changes when they touch adjacent capabilities and can coexist.
   - Prefer the incoming side only when the current side was plainly superseded.
   - Prefer the current side only when the incoming side is unrelated or would undo the branch's purpose.

3. Edit narrowly:
   - Remove conflict markers.
   - Keep existing formatting and local ordering.
   - Do not rename, refactor, reorganize imports, or regenerate files unless required for the conflicted file to be valid.
   - Do not touch files that are not unmerged unless resolving one conflicted file requires a direct companion edit.

4. Generated/codelocked files:
   - If a generated file conflicts, prefer regenerating only that generated file when the user allows checks/generation.
   - If the user explicitly says not to run generation or checks, resolve the markers with the smallest textual merge and clearly report that the codelock/hash may need regeneration.
   - Never hand-edit manual-protected generated sections beyond resolving conflict markers.

5. Validation:
   - If the user asks for verification, run the smallest relevant checks first: conflict-marker search, formatter/linter on touched files, targeted tests, then typecheck.
   - If the user says not to run tests/checks/migrations, obey. Only do lightweight reads such as `rg`/`git status`.
   - Never run migrations while resolving conflicts unless explicitly requested.

6. Mark resolved:
   - After edits, run `git add <resolved-files>` for only the files you resolved.
   - If sandbox blocks `.git/index`, request escalation for that `git add`.
   - Do not stage unrelated files.

## Reporting

Report:

- Which files were resolved.
- The merge decision, especially where both sides were preserved.
- Whether any generated files may need regeneration.
- Which checks were run, or explicitly note that checks were skipped because the user asked.

Keep the final response short and concrete.
