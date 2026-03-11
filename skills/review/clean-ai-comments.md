---
description: "Remove noisy, redundant AI-generated comments introduced in the current branch diff. Only touches lines added in the diff — never modifies pre-existing code."
arguments:
  - name: target
    description: "Branch name or PR number/URL. If omitted, diffs current branch against origin/main."
---

## Task

Scan the diff for AI-generated comments in newly added lines and remove them. This includes both obvious restating comments AND over-engineered walls of text that no human would naturally write. Do NOT touch any line that was not added in the current branch diff.

## Rules

- Only remove comments introduced in the diff (`+` lines in the patch).
- Never modify, reformat, or reindent any line that existed before this branch.
- If genuinely unsure whether a comment is meaningful: KEEP it.

## Context

**Comments to REMOVE:**

*Category 1 — Restating the obvious:*
Comments that add zero information beyond what the code already says.
- `// increment the counter` above `count++`
- `// check if user is null` above `if (!user)`
- `// return the result` above `return result`
- `# loop through items` above `for item in items:`
- Block comments that restate the function signature in prose
- `// TODO: implement` on already-implemented code
- Section dividers like `// ---- helper methods ----` with no real content

*Category 2 — Over-explained AI prose:*
Multi-line comment blocks that explain implementation details in a way no human reviewer would write or need. Ask: "Would a competent engineer on this team naturally write this comment?" If no → REMOVE.

Signs of over-explained AI prose:
- Uses jargon or named concepts not defined anywhere in the codebase (e.g. "starvation risk", "crowding out", "DB predicate ensures take")
- Explains *how* the code works line-by-line instead of *why* a decision was made
- 3+ line comment blocks above a single query, condition, or assignment
- Lettered sub-points `(a)`, `(b)` explaining query variants inline
- References internal implementation details (column names, time windows, row counts) that belong in a ticket or PR description, not in code
- Reads like a design document pasted into a comment

**Comments to KEEP:**
- A single short sentence explaining WHY a non-obvious choice was made (not how it works)
- Warnings about real gotchas or side effects a future developer would need to know
- Links to issues, tickets, or external docs
- `// eslint-disable`, `// @ts-ignore`, or other directive comments
- License headers
- Comments that existed before this branch (not in the diff)

**The bar:** if a human senior engineer would read it and think "I didn't need to know all that" → remove it.

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
