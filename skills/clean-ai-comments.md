---
name: clean-ai-comments
description: Remove noisy, redundant AI-generated comments introduced in the current branch diff. Only touches lines added in the diff — never modifies pre-existing code.
arguments:
  - name: target
    description: Branch name or PR number/URL. If omitted, diffs current branch against origin/main.
---

Remove AI-generated fluff comments from NEW code only. Do NOT touch any line that was not added in the current branch diff.

## What counts as an AI comment to remove

Remove a comment if it meets ALL of these:
- It was introduced in the diff (a `+` line in the patch)
- It adds zero information beyond what the code already says

Examples to REMOVE:
- `// increment the counter` above `count++`
- `// check if user is null` above `if (!user)`
- `// return the result` above `return result`
- `# loop through items` above `for item in items:`
- Block comments that restate the function signature in prose
- `// TODO: implement` on already-implemented code
- Section dividers like `// ---- helper methods ----` with no real content

Examples to KEEP:
- Comments explaining WHY a non-obvious decision was made
- Warnings about gotchas or side effects
- Links to issues, tickets, or external docs
- `// eslint-disable`, `// @ts-ignore`, or other directive comments
- License headers
- Comments that existed before this branch (not in the diff)

## Steps

1) Get the diff of new lines only:
   - If {{target}} provided and looks like a PR number/URL:
     gh pr diff {{target}}
   - Else if {{target}} is a branch name:
     git diff origin/main...{{target}}
   - Else (no argument):
     git diff origin/main...HEAD

2) Parse added lines:
   - Only consider lines starting with `+` (excluding the `+++` file header).
   - For each added comment line, read the surrounding added code (5 lines of context).
   - Classify: REMOVE or KEEP per the rules above.

3) For each file with comments to remove:
   - Read the full file.
   - Remove only the identified comment lines.
   - Do NOT reformat, reindent, or change any other line.
   - If removing a comment would leave a blank line above/below that looks odd, remove that blank line too — but only if it was also an added line in the diff.

4) After editing each file:
   - Re-read the changed section and verify no logic lines were touched.
   - If unsure whether a comment is meaningful: KEEP it.

5) Report what was removed:
   - List each file and the exact comment lines deleted.
   - If nothing to remove: say so and stop.
