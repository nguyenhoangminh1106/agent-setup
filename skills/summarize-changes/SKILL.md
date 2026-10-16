---
name: summarize-changes
description: "Summarize scoped code changes in one short, plain-English update for a non-technical reader, focusing on what changed and why."
---

## Task

Read the scoped changes and write a quick overall update suitable for a non-technical reader. Convey the main outcome without listing every behavior or fix.

Do not edit any code.


## Steps

**1) Establish the scope**

Use [current-work](../current-work/SKILL.md) to establish the requested feature/fix, baseline, and included changes. Reuse an existing scope result when it is still current; pass that result to downstream skills without broadening it. Keep this skill's task, permissions, and output format.

With an explicit PR/branch/range, use its actual target and final feature changes.
Without a target, describe the combined current work, including relevant local
edits and unpushed commits. Work on main is supported.

**2) Read the selected changes**

Read the scoped diff and surrounding behavior from the scope result. Do not fetch
or assume an origin/main baseline. Skim for changes that matter to end users or
business outcomes. Ignore internal refactors, renames, config, comments, or tests
when they have no user-facing effect.

**3) Write the description**

Rules:
- Default to one short sentence, roughly 15–30 words. Use a second short sentence only when separate main changes cannot be described clearly together; stay under 40 words unless the user requests more detail.
- Plain English — no technical terms, no file names, no function names, no jargon
- Focus on the **what and why** from a user or product perspective
- Group related changes under their overall user benefit. Omit edge cases, safeguards, testing details, and acceptance criteria unless they are the main purpose of the work.
- Do not start with "This PR" — just describe the change directly

Good: "Answer calendar invitations directly from Priority and Home, with Undo to restore them to the queue."

Bad: "Updated `RequestSupplyTab.tsx` to call `getSolsForRole` and render `UserTag` chips in the qualification card."

**4) Output**

Print just the description — no headers, no preamble, ready to paste into a PR body or Slack message.
