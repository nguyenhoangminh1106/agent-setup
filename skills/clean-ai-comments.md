---
description: "Remove noisy, redundant AI-generated comments introduced in the current branch diff. Only touches lines added in the diff — never modifies pre-existing code."
arguments:
  - name: target
    description: "Branch name or PR number/URL. If omitted, diffs current branch against origin/main."
---

## Task

Scan the diff for AI-generated fluff comments in newly added lines and remove them. Do NOT touch any line that was not added in the current branch diff.

## Rules

- Only remove comments introduced in the diff (`+` lines in the patch).
- Never modify, reformat, or reindent any line that existed before this branch.
- If unsure whether a comment is meaningful: KEEP it.

## Context

**Comments to REMOVE** (must meet ALL criteria):
- Introduced in the diff (a `+` line in the patch)
- Adds zero information beyond what the code already says

Examples:
- `// increment the counter` above `count++`
- `// check if user is null` above `if (!user)`
- `// return the result` above `return result`
- `# loop through items` above `for item in items:`
- Block comments that restate the function signature in prose
- `// TODO: implement` on already-implemented code
- Section dividers like `// ---- helper methods ----` with no real content

**Comments to KEEP:**
- Comments explaining WHY a non-obvious decision was made
- Warnings about gotchas or side effects
- Links to issues, tickets, or external docs
- `// eslint-disable`, `// @ts-ignore`, or other directive comments
- License headers
- Comments that existed before this branch (not in the diff)

## Steps

**1) Get the diff**
```
# If {{target}} is a PR number/URL:
gh pr diff {{target}}

# If {{target}} is a branch name:
git diff origin/main...{{target}}

# If no argument:
git diff origin/main...HEAD
```

**2) Parse added lines**
- Only consider lines starting with `+` (excluding `+++` file headers).
- For each added comment line, read the surrounding added code (5 lines of context).
- Classify each: REMOVE or KEEP per the rules above.

**3) Remove identified comments**
For each file with comments to remove:
- Read the full file.
- Remove only the identified comment lines.
- Do NOT reformat, reindent, or change any other line.
- If removing a comment would leave an odd blank line that was also an added line in the diff, remove that blank line too.

**4) Verify each edit**
- Re-read the changed section and confirm no logic lines were touched.

**5) Report**
- List each file and the exact comment lines deleted.
- If nothing to remove: say so and stop.
