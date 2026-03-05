---
description: "Given a branch diff and optional DB access, produce concrete step-by-step UI testing instructions with real example data to test against."
arguments:
  - name: branch
    description: "Branch name to diff against origin/main. Defaults to current branch if omitted."
  - name: db
    description: "DB connection string or tool name (e.g. 'psql://...', 'Prisma Studio'). Pass 'skip' to skip DB querying entirely. If omitted, the skill will ask when DB context would help."
---

## Task

Read the git diff for a branch, understand what changed, prompt the user for DB access if relevant, query the DB for concrete test data, then produce a single linear walkthrough a human can follow — start to finish, no backtracking — as if recording a demo video.

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
- The single best user account (email + role) to cover the most features in one session
- Any records that need to exist before testing (so they can be listed in setup)

Collect ALL values now — everything needed will be declared upfront before any steps are written.

**5) Plan the walkthrough order**

Before writing any steps, determine the optimal linear order to test all features:
- Group features by the same user session / page area to avoid logging in and out multiple times
- Order features so earlier steps naturally set up state for later steps (e.g. create a record first, then test editing it)
- Identify which features share the same URL or user context and batch them together
- The goal: a single unbroken recording from login to the last assertion, with zero backtracking

**6) Write the testing instructions**

CRITICAL RULES:
- **All setup goes in one upfront section** — every account, record, URL, and seed action needed for the entire walkthrough must be listed before Step 1. The tester completes all setup, then records without interruption.
- **If DB was queried**, every pre-condition and step MUST use exact real values — no placeholders, no "find a user with X role", no "navigate to a record". Name the exact email, exact company/tenant, exact URL with real IDs.
- **Linear flow only** — steps must flow forward. Never tell the tester to go back to a previous page, log out and back in, or repeat an earlier action mid-walkthrough (unless the feature itself requires it).
- **One session where possible** — pick one user account that can see all changed features. Only switch users if a feature is only testable by a different role, and batch all same-role steps together.

---

### 🛠 Setup (do this before recording)

List everything the tester must have ready before they start:

**Accounts:**
- Log in as: `<exact email>` (role: `<role>`) — used for steps 1–N
- Switch to: `<exact email>` (role: `<role>`) — used for steps N+1–M (only if role switch needed)

**Records to have open / ready:**
- `<Record name or ID>` at `<full URL>` — `<its state and why it's needed>`
- `<Record name or ID>` at `<full URL>` — `<its state and why it's needed>`

**Any seed actions needed:**
- `<e.g. "Ensure record X is in 'pending' state — if not, reset it via [instructions]">`
- `<e.g. "Open browser devtools console to watch for errors during step N">`

---

### 🎬 Walkthrough (record this)

A single ordered sequence covering all features. No preamble — just numbered steps.

1. Go to `<full URL with real IDs>`
2. Click / fill in / select `<exact element label>`
3. Expect: `<what should appear or happen>`
4. …

Inline expected results as `Expect:` lines immediately after the action that triggers them — do not batch them at the end. This makes it easy to verify each action in real time while recording.

For edge cases that require a separate action (e.g. submitting a blank form), include them as a natural continuation of the flow at the point where it makes sense — not in a separate section.

---

**7) List gaps**

After the walkthrough, add a short **⚠️ Testing gaps / unknowns** section:
- Behaviors that couldn't be confirmed from the diff alone
- Env vars or external services required
- Anything requiring DB state the skill couldn't verify
- Uncommitted changes the tester must run locally to see
