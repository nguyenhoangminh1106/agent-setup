---
name: feature-summary
description: "Summarize current work or an explicitly requested feature, branch, or PR, explain its business purpose, and produce step-by-step UI testing instructions. Includes scoped committed and uncommitted changes; optionally queries the DB for concrete examples."
---

## Task

Produce a plain-English summary of the scoped current work or explicit target,
explain its business intent, and write concrete UI testing instructions for its
features/fixes. Include relevant committed and uncommitted changes. When the
provided DB lacks test data, include the seed-data plan returned through testing-instructions.
Do not edit code. An explicitly requested whole branch includes all its topic work.

When a `{{spec}}` is provided, also produce: a delivery summary of what was done vs. left out, a ticket-alignment table mapping each acceptance criterion to the change that satisfies it, a risk assessment, and technical notes — giving a full delivery report equivalent to what a human reviewer would write.

## Rules

- DO NOT edit, write, or modify any code.
- DO NOT checkout, commit, rebase, or run any state-changing git command.
- Output a REPORT ONLY.
- Ask the user for DB access instructions before running any DB query — never assume a connection string.
- If `{{db}}` was provided, use it directly without asking.

## Steps

**1) Establish the scope**

Use [current-work](../current-work/SKILL.md) to establish the requested feature/fix, baseline, and included changes. Reuse an existing scope result when it is still current; pass that result to downstream skills without broadening it. Keep this skill's task, permissions, and output format.

Pass any `target` and current task context to current-work. Do not reject main
or master: active changes and local-only commits can exist there. Use the
returned commit set/ranges, paths/hunks, and staged/unstaged/untracked changes;
exclude unrelated imported work and keep distinct active feature groups visible.

**2) Read spec (if provided)**

Read the provided `spec` and reconcile its acceptance criteria with the scope.
The user's explicit target remains authoritative.

**3) Read surrounding context**

For each changed file, read enough of the file to understand:
- What the file does in the app (component, API route, DB model, etc.)
- How the changed lines fit into the broader flow
- Any related files that clarify intent (e.g. if a route changed, read the page that calls it)

Focus on explaining the delivered behavior. Do not turn this summary into a
defect review. If the user separately requests one, use
[review-rebuild](../review-rebuild/SKILL.md) with the same scope and the user's
requested review mode. In this report, limit the spec-mode risk assessment to
evidence-backed implementation risks and known verification gaps.

**4) Generate UI testing instructions**

Use [testing-instructions](../testing-instructions/SKILL.md), passing:
- The `current-work` scope result (target, actual baseline/commit set, relevant local changes, and exclusions). Include the branch as context, not as permission to expand scope.
- `db={{db}}` (pass through as-is — `skip`, a connection string, or omit to let the skill ask)

The skill will read the diff, resolve DB access if relevant, use query-db for real example data, and use [seed-data](../seed-data/SKILL.md) in plan mode for missing fixtures. Reuse its output for **🧪 How to Test in the UI**, **🧱 Local test fixtures**, and **⚠️ Testing gaps / unknowns** below. Preserve proposed-versus-existing IDs and not-executed status; this report does not authorize fixture writes.

**5) Produce the report** (see Output Format below)


## Output Format

### 🗂 Work Summary

- **Branch / PR:** `<name or link>`
- **Scope / baseline:** `<target and actual baseline/range or commit set>`
- **Committed changes:** `<N selected topic commits; distinguish unpushed where known>`
- **Uncommitted changes:** staged / unstaged / none


### 🎯 What This Work Does

2–4 sentences explaining the business purpose. Answer: *what problem does this solve, or what capability does it add, from a user or product perspective?* Avoid implementation jargon — write as if explaining to a PM.


### 📦 Changes at a Glance

For each logical group of changes (not necessarily one file per row — group related files):

| Area | Files touched | What changed | Why (business reason) |
|------|--------------|--------------|----------------------|
| e.g. "Request form" | `components/RequestForm.tsx` | Added expiry date field | Pending requests now expire after 30 days |

Include uncommitted changes with a note: *(uncommitted)*.


### 🧪 How to Test in the UI

A single linear walkthrough — no backtracking, no mid-session setup. The tester completes all setup upfront, then goes through every step smoothly and covers all features without jumping around. Use the output from the `/testing-instructions` skill verbatim, which follows this structure:

**🛠 Setup (do all of this before starting):** All accounts, records, and seed actions listed upfront so the tester can prepare everything before starting.

**🧱 Local test fixtures (optional):** Reuse the seed-data plan returned by testing-instructions, including setup, verification, cleanup, and separate workflow triggers. Do not independently generate SQL or execute setup in this report-only skill.

**✅ Steps:** One unbroken sequence of numbered steps covering all features in the optimal order. Expected results appear inline as `Expect:` lines immediately after each action. Edge cases are woven into the flow at the natural point — not batched separately.

If DB queries were run, every step MUST use exact real values — exact email, exact company/tenant name, exact URLs with real record IDs. The tester follows blindly without searching or choosing.


### ⚠️ Testing gaps / unknowns

List any behaviors that couldn't be fully understood from the diff alone — e.g. missing context, env vars needed, external services involved, or things that require a specific DB state the skill couldn't verify.


### 🗒 Uncommitted changes note

If there are uncommitted changes: list them explicitly and note that they are not yet on the branch — tester must be running locally against the working tree to test these.


*The following sections are only included when `{{spec}}` was provided:*


### ✅ Delivery Summary *(spec mode)*

What was done and what was intentionally left out. Written against the spec's stated goals — not a raw file list.


### 🎫 Ticket Alignment *(spec mode)*

For each acceptance criterion in the spec:

| Criterion | Status | Change that satisfies it |
|-----------|--------|--------------------------|
| e.g. "Pending requests expire after 30 days" | ✅ Done | `ExpiryService.ts` — adds TTL check on load |
| e.g. "Send Slack notification on expiry" | ✅ Done | `cron/expiry.ts` — calls `slackNotify()` |
| e.g. "Show expiry date in UI" | ⚠️ Partial | Field added but not shown in list view |
| e.g. "Admin can manually expire a request" | ❌ Not addressed | No changes found |


### 🔴 Risk Assessment *(spec mode)*

- **Overall risk level:** LOW / MEDIUM / HIGH
- **Safe to merge?** YES / YES WITH CAUTION / NO
- Brief justification (1–3 sentences). Focus on behavioral safety and scope drift — not style.


### 🔧 Technical Notes *(spec mode)*

- Files changed (list)
- Key assumptions made during implementation
- Anything deferred or explicitly out of scope
- Any follow-up work recommended
