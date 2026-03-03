---
description: "Given a branch diff and optional DB access, produce concrete step-by-step UI testing instructions with real example data to test against."
arguments:
  - name: branch
    description: "Branch name to diff against origin/main. Defaults to current branch if omitted."
  - name: db
    description: "DB connection string or tool name (e.g. 'psql://...', 'Prisma Studio'). Pass 'skip' to skip DB querying entirely. If omitted, the skill will ask when DB context would help."
---

## Task

Read the git diff for a branch, understand what changed, prompt the user for DB access if relevant, query the DB for concrete test data, then produce step-by-step UI testing instructions a human can follow without reading any code.

Do not edit any code or run any state-changing commands.

---

## Steps

**1) Determine branch**

- If `{{branch}}` is provided, use it.
- Otherwise: `git branch --show-current`
- If the result is `main` or `master`, stop and ask the user which branch to use.

**2) Read the diff**

```bash
git fetch origin
git diff origin/main...<branch>
```

Also collect uncommitted changes:
```bash
git diff --cached
git diff
```

Combine all changes into a single mental model of "everything that changed."

**3) Read surrounding context**

For each changed file, read enough of the file to understand:
- What it does in the app (component, API route, DB model, etc.)
- How the changed lines fit into the broader flow
- Any related files needed to understand intent (e.g. the page that calls a changed route)

**4) Decide if DB context would help**

If `{{db}}` is `skip`: skip to step 5.

If the diff touches DB models, queries, seed data, API responses that depend on DB state, or any feature where knowing real data would help a tester know *what to click* or *what ID to use*:

> Ask the user:
> "The changes involve database-backed features. Can you give me DB access so I can find real example data for the testing instructions?
> Options: psql connection string, Prisma Studio URL, DB read tool, or type 'skip' to proceed without."

If the user provides access (or `{{db}}` is already set), proceed to step 4b. Otherwise skip to step 5.

**4b) Query the DB for test data**

Use the `/query-db` skill to find concrete, realistic values a tester can use. Pass the DB connection from `{{db}}` and ask plain-English questions derived from the diff. Focus on:
- Example IDs or records in the states touched by this diff (e.g. "find a request in pending state")
- Edge-case records that match boundary conditions in the code (e.g. "find an expired record", "find a record where <field> is null")
- Any enum values, status codes, or categories referenced in the changed code

Collect these values — you will embed them directly in the testing steps.

**5) Write the testing instructions**

For each distinct feature or fix in the diff, produce a block:

---

**[Feature or fix name]**

Pre-conditions:
- (setup needed: logged-in user, specific role, existing DB record, etc.)
- If DB was queried: name the specific record to use (e.g. "use Request ID `abc-123` which is in `pending` state")

Steps:
1. Go to `<page or URL>`
2. Click / fill in / select `<element>`
3. …

Expected result:
- `<what the user should see or experience>`

Edge cases to verify:
- `<e.g. what happens if the field is blank>`
- `<e.g. what happens at a boundary condition>`

---

**6) List gaps**

After all feature blocks, add a short **Testing gaps / unknowns** section:
- Behaviors that couldn't be confirmed from the diff alone
- Env vars or external services required
- Anything requiring DB state the skill couldn't verify
- Uncommitted changes the tester must run locally to see
