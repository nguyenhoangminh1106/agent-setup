---
description: "Write a plain-English PR description for non-technical readers. Covers all main changes in 1-3 sentences. No jargon."
arguments:
  - name: target
    description: "PR number, PR URL, or branch name. Defaults to current branch if omitted."
---

## Task

Read the diff for a PR or branch and write a short, plain-English description of what changed — suitable for a non-technical reader. Not a full summary, just the main things that matter.

Do not edit any code.

---

## Steps

**1) Identify target**

- If `{{target}}` looks like a PR number or URL: `gh pr view {{target}} --json title,body,headRefName,baseRefName`
- If `{{target}}` is a branch name: use it directly
- If omitted: `git branch --show-current`

**2) Read the diff**

```bash
git fetch origin
git diff origin/main...<branch>
```

Skim for the changes that matter to end users or business outcomes — what visibly changed, what works differently, what was fixed.

Ignore: internal refactors, file renames, config tweaks, comment changes, test files, anything with no user-facing effect.

**3) Write the description**

Rules:
- 1 to 3 sentences maximum
- Plain English — no technical terms, no file names, no function names, no jargon
- Focus on the **what and why** from a user or product perspective
- If multiple things changed, group them into one flowing description rather than a bullet list
- Do not start with "This PR" — just describe the change directly

Good: "Recruiters can now see which SOLs are assigned to a role directly from the request tab. Roles with no assignment show a clear empty state."

Bad: "Updated `RequestSupplyTab.tsx` to call `getSolsForRole` and render `UserTag` chips in the qualification card."

**4) Output**

Print just the description — no headers, no preamble, ready to paste into a PR body or Slack message.
