---
description: "Summarize all changes on a branch (committed + uncommitted), explain the business purpose, and produce step-by-step UI testing instructions. Optionally queries the DB for richer context."
arguments:
  - name: target
    description: "Branch name, PR number, or PR URL to summarize. Defaults to current branch if omitted."
  - name: spec
    description: "Optional path to a spec file (e.g. .ticket/<branch>/spec.md). When provided, enables ticket-alignment and risk-assessment sections in the report."
  - name: db
    description: "Optional DB connection string or query instructions (e.g. 'psql://...' or 'use Prisma studio'). Pass 'skip' to suppress the DB prompt entirely. If omitted, the skill will ask when DB context would help."
---

## Task

Produce a plain-English summary of everything changed on a branch — committed and uncommitted — explain the business intent behind each change, and write concrete step-by-step instructions for how to manually test every feature or fix in the UI. Do not edit any code.

When a `{{spec}}` is provided, also produce: a delivery summary of what was done vs. left out, a ticket-alignment table mapping each acceptance criterion to the change that satisfies it, a risk assessment, and technical notes — giving a full delivery report equivalent to what a human reviewer would write.

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

**2) Read spec (if provided)**

If `{{spec}}` was given, read it from disk now:
```
Read file: {{spec}}
```
Keep it in context for steps 4, 6, and the output sections below.

**3) Collect the full diff (committed changes)**

```bash
# Against origin/main (three-dot: all commits on branch not on main)
git fetch origin
git diff origin/main...<branch>
```

**4) Collect uncommitted changes**

```bash
# Staged
git diff --cached

# Unstaged
git diff
```

Combine committed + uncommitted into one mental model of "everything changed on this branch."

**5) Read surrounding context**

For each changed file, read enough of the file to understand:
- What the file does in the app (component, API route, DB model, etc.)
- How the changed lines fit into the broader flow
- Any related files that clarify intent (e.g. if a route changed, read the page that calls it)

Focus on understanding — do not flag issues or risks (that is branch-risk-review's job).

**6) Generate UI testing instructions**

Invoke the `/testing-instructions` skill, passing:
- `branch=<branch>` (the branch identified in step 1)
- `db={{db}}` (pass through as-is — `skip`, a connection string, or omit to let the skill ask)

The skill will read the diff, prompt for DB access if relevant, use `/query-db` to fetch real example data, and return complete step-by-step testing instructions. Use its output verbatim for the **🧪 How to Test in the UI** and **⚠️ Testing gaps / unknowns** sections below.

**7) Produce the report** (see Output Format below)

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

A single linear walkthrough designed for smooth video recording — no backtracking, no mid-session setup. Use the output from the `/testing-instructions` skill verbatim, which follows this structure:

**🛠 Setup (do this before recording):** All accounts, records, and seed actions listed upfront so the tester can prepare everything before hitting record.

**🎬 Walkthrough (record this):** One unbroken sequence of numbered steps covering all features in the optimal order. Expected results appear inline as `Expect:` lines immediately after each action. Edge cases are woven into the flow at the natural point — not batched separately.

If DB queries were run, every step MUST use exact real values — exact email, exact company/tenant name, exact URLs with real record IDs. The tester follows blindly without searching or choosing.

---

### ⚠️ Testing gaps / unknowns

List any behaviors that couldn't be fully understood from the diff alone — e.g. missing context, env vars needed, external services involved, or things that require a specific DB state the skill couldn't verify.

---

### 🗒 Uncommitted changes note

If there are uncommitted changes: list them explicitly and note that they are not yet on the branch — tester must be running locally against the working tree to test these.

---

*The following sections are only included when `{{spec}}` was provided:*

---

### ✅ Delivery Summary *(spec mode)*

What was done and what was intentionally left out. Written against the spec's stated goals — not a raw file list.

---

### 🎫 Ticket Alignment *(spec mode)*

For each acceptance criterion in the spec:

| Criterion | Status | Change that satisfies it |
|-----------|--------|--------------------------|
| e.g. "Pending requests expire after 30 days" | ✅ Done | `ExpiryService.ts` — adds TTL check on load |
| e.g. "Send Slack notification on expiry" | ✅ Done | `cron/expiry.ts` — calls `slackNotify()` |
| e.g. "Show expiry date in UI" | ⚠️ Partial | Field added but not shown in list view |
| e.g. "Admin can manually expire a request" | ❌ Not addressed | No changes found |

---

### 🔴 Risk Assessment *(spec mode)*

- **Overall risk level:** LOW / MEDIUM / HIGH
- **Safe to merge?** YES / YES WITH CAUTION / NO
- Brief justification (1–3 sentences). Focus on behavioral safety and scope drift — not style.

---

### 🔧 Technical Notes *(spec mode)*

- Files changed (list)
- Key assumptions made during implementation
- Anything deferred or explicitly out of scope
- Any follow-up work recommended
