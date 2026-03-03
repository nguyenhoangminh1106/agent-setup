---
description: "Summarize all changes on a branch (committed + uncommitted), explain the business purpose, and produce step-by-step UI testing instructions. Optionally queries the DB for richer context."
arguments:
  - name: target
    description: "Branch name, PR number, or PR URL to summarize. Defaults to current branch if omitted."
  - name: db
    description: "Optional DB connection string or query instructions (e.g. 'psql://...' or 'use Prisma studio'). If omitted, the skill will ask when DB context would help."
---

## Task

Produce a plain-English summary of everything changed on a branch — committed and uncommitted — explain the business intent behind each change, and write concrete step-by-step instructions for how to manually test every feature or fix in the UI. Do not edit any code.

## Rules

- DO NOT edit, write, or modify any code.
- DO NOT checkout, commit, rebase, or run any state-changing git command.
- Output a REPORT ONLY.
- Ask the user for DB access instructions before running any DB query — never assume a connection string.
- If `{{db}}` was provided, use it directly without asking.

## Steps

**1) Identify target**

- If `{{target}}` is provided and looks like a PR number or URL:
  ```
  gh pr view {{target}} --json number,title,url,baseRefName,headRefName,body
  ```
- If `{{target}}` is a branch name:
  ```
  git show-ref {{target}}
  ```
- If `{{target}}` is omitted: use current branch (`git branch --show-current`). If that is `main` or `master`, stop and ask the user which branch to summarize.

**2) Collect the full diff (committed changes)**

```bash
# Against origin/main (three-dot: all commits on branch not on main)
git fetch origin
git diff origin/main...<branch>
```

**3) Collect uncommitted changes**

```bash
# Staged
git diff --cached

# Unstaged
git diff
```

Combine committed + uncommitted into one mental model of "everything changed on this branch."

**4) Read surrounding context**

For each changed file, read enough of the file to understand:
- What the file does in the app (component, API route, DB model, etc.)
- How the changed lines fit into the broader flow
- Any related files that clarify intent (e.g. if a route changed, read the page that calls it)

Focus on understanding — do not flag issues or risks (that is branch-risk-review's job).

**5) Identify whether DB context would help**

If the diff touches DB models, queries, seed data, or API responses that depend on DB state, and `{{db}}` was NOT provided:

> Ask the user:
> "The changes touch database logic. Do you have a DB connection or tool I can query to give better testing instructions? (e.g. psql connection string, Prisma Studio URL, or just tell me to skip)"

If the user provides access, run targeted read-only queries to understand the relevant data shape. Never run INSERT, UPDATE, DELETE, or DROP.

**6) Produce the report** (see Output Format below)

---

## Output Format

### 🗂 Branch Summary

- **Branch / PR:** `<name or link>`
- **Base:** `main` (or detected base branch)
- **Committed changes:** `<N> commits`
- **Uncommitted changes:** staged / unstaged / none

---

### 🎯 What This Branch Does

2–4 sentences explaining the business purpose. Answer: *what problem does this solve, or what capability does it add, from a user or product perspective?* Avoid implementation jargon — write as if explaining to a PM.

---

### 📦 Changes at a Glance

For each logical group of changes (not necessarily one file per row — group related files):

| Area | Files touched | What changed | Why (business reason) |
|------|--------------|--------------|----------------------|
| e.g. "Request form" | `components/RequestForm.tsx` | Added expiry date field | Pending requests now expire after 30 days |

Include uncommitted changes with a note: *(uncommitted)*.

---

### 🧪 How to Test in the UI

Concrete, ordered steps a human can follow right now. Write these as if the reader has never seen the code — just the running app.

For each feature or fix, a block like:

**[Feature/fix name]**

Pre-conditions:
- (any setup needed: logged-in user, specific role, existing DB record, etc.)

Steps:
1. Go to `<page or URL>`
2. Click / fill in / select `<element>`
3. …

Expected result:
- `<what should happen>`

Edge cases to verify:
- `<e.g. what happens if the field is left blank>`
- `<e.g. what happens at the expiry boundary>`

If DB queries were run to understand data shape, include specific example values the tester can use (e.g. "use request ID `abc-123` which is in `pending` state").

---

### ⚠️ Testing gaps / unknowns

List any behaviors that couldn't be fully understood from the diff alone — e.g. missing context, env vars needed, external services involved, or things that require a specific DB state the skill couldn't verify.

---

### 🗒 Uncommitted changes note

If there are uncommitted changes: list them explicitly and note that they are not yet on the branch — tester must be running locally against the working tree to test these.
