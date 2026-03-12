---
description: "Read a .ticket/<branch>/ artifacts folder, study the codebase, and apply only the fixes that are clearly required — no questions asked. Reports what was fixed and what was skipped."
arguments:
  - name: artifacts
    description: "Path to the ticket artifacts folder, e.g. .ticket/minh2/automate-recruiter-offboarding/"
---

## Task

Read all artifacts in `{{artifacts}}` (spec, plan, risk reviews, spec reviews, diff), study the actual codebase, and apply only the fixes that are unambiguously required. Skip anything that requires a judgment call or business decision. When done, report what was fixed, what was skipped, and why.

## Rules

- **Read the artifacts first** — spec.md, plan.md, the latest risk-N.md and spec-review-N.md.
- **Read the actual code** before touching anything — understand the current state before deciding what to fix.
- **Only fix BLOCKERs and FIXes** that are clearly described with enough detail to implement correctly. Skip NOTEs entirely.
- **Skip anything ambiguous** — if the fix requires a product decision, a behavioral tradeoff, or isn't fully specified, skip it and explain why.
- **Minimal diff** — implement exactly what the review says. No refactors, no extra improvements, no scope creep.
- **No new dependencies, no schema changes** unless the review explicitly calls for one and the spec confirms it.
- **Do not ask questions** — either fix it or skip it with a reason.

## Steps

**1) Read all artifacts**

Read every file in `{{artifacts}}`:
- `spec.md` — the source of truth for intended behavior
- `plan.md` — files in scope
- All `spec-review-N.md` files (use the highest N as the latest)
- All `risk-N.md` files (use the highest N as the latest)
- `diff-current.md` if present — to understand what's already implemented

Extract all BLOCKER and FIX items. Ignore NOTEs.

**2) Read the codebase**

For each BLOCKER/FIX item, read the referenced files and line numbers. Understand the current implementation before changing anything.

**3) Triage each item**

For each finding, decide:
- **Will fix**: the required change is unambiguous, fully described, and has no behavioral tradeoffs.
- **Skip**: the fix requires a product decision, is underspecified, or conflicts with other constraints.

Document the triage outcome for every item before touching any code.

**4) Apply fixes**

For each "will fix" item:
- Make the minimal change described in the review.
- Follow existing code style and patterns exactly.
- Do not touch files outside the plan unless the review explicitly calls for it.

**5) Report**

After all fixes are applied (or skipped), print a summary:

```
## Fix Report

### Applied
- [BLOCKER/FIX] <finding title> — <one line: what was changed and where>

### Skipped
- [BLOCKER/FIX] <finding title> — <one line: why skipped>

### Result
<Overall: all blockers resolved / blockers remain — human review needed>
```

If nothing needed fixing: say so clearly — "All findings already resolved or no actionable items found."
