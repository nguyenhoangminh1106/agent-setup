---
description: "Generate Minh's daily work update: gather context from Slack (Beeper), Linear, GitHub, and Claude Code sessions, match past entry style, show draft for approval, then append to the updates file."
arguments: []
---

## Task

Gather everything that happened today across Slack, Linear, GitHub, and Claude Code sessions. Produce a concise daily update in the exact style of past entries. Show the draft to Minh for approval, then append it to the updates file.

Do not append anything until Minh explicitly approves the draft.

---

## Identity

- Name: Minh Nguyen / Minh2
- Slack user ID: `U07EA84FWER`
- Repo: `~/Documents/GitHub/paraform`
- Updates file: `~/Documents/Work/paraform/Updates 2026.md`

---

## Steps

**1) Gather Slack context via Beeper**

Search all of Minh's DMs, group DMs, and channel mentions from today using Beeper tools (`search_messages`, `list_messages`, `search_chats`). Filter for:
- Messages sent by Minh (`U07EA84FWER`)
- Messages that mention or are directed at Minh
- Any work discussed, requested, completed, or acknowledged across Paraform Slack channels

**2) Check Linear tickets**

Look up Linear tickets updated or completed today:
- Tickets moved to Done, In Progress, or In Review
- Tickets commented on by Minh
- Any newly created tickets

**3) Check GitHub activity**

```bash
cd ~/Documents/GitHub/paraform
git log --oneline --since="midnight" --author="Minh"
gh pr list --author @me --state open
gh pr list --author @me --state merged --limit 5
```

Also check for review comments received or addressed on open PRs today.

**4) Check recent Claude Code sessions**

Read the last 5 Claude Code chat transcripts from `~/.claude/projects/-Users-minh2-Documents-GitHub-paraform*/` to find work done today — PRs, code changes, debugging, feature work, etc. Focus on `.jsonl` files modified today.

**5) Cross-reference everything**

Combine Slack messages, Linear tickets, GitHub activity, and Claude session history into a full picture of the day's work. Group related items (e.g. a PR + its Linear ticket + the Slack discussion about it).

**6) Study past entries for style**

Read the last 5–10 entries in `~/Documents/Work/paraform/Updates 2026.md`. Match their:
- Section headers and structure exactly
- Bullet length and phrasing style
- Which areas get their own section vs. get grouped
- How pending items are listed

The new entry must look like it was written by the same person on the same day as the others.

**7) Draft the update**

Write the update following the format below and the patterns from past entries. Show the draft to Minh and wait for explicit approval before appending.

**8) Append once approved**

Append the approved entry to the bottom of `~/Documents/Work/paraform/Updates 2026.md`. Do not overwrite — append only.

---

## Format

```
## {ordinal} {Month}

### Codebase
- …
- …

### Pending
1. **Item title** — short description
```

- Use `## {ordinal} {Month}` heading (e.g. `## 6th March`)
- One section: `Codebase` — covers all code, PR, and feature work
- Add other sections only if clearly warranted by the day's work (e.g. `Metrics`, `Infra`)
- `Pending` section at the bottom with numbered items, kept short
- Optional freeform note after bullets for context or caveats

---

## Tone and Style

- Professional, direct, concise — like a quick standup
- 3–5 bullet points max. Each bullet is 1–2 lines. Trim if longer.
- Describe the **what and outcome**, not the how or implementation detail

Good: "Fixed bug where interview reminders were sent to wrong recipients"
Bad: "Updated the `sendReminder` function to filter by `intervieweeId` instead of `requestId`"

---

## Formatting Rules

- No em dashes or en dashes — use "to" or commas instead
- No Obsidian wiki links
- No internal workflow references, branch conditions, or attribute configs
- No overly specific technical details (no function names, file paths, config keys)
- Backticks for Slack channel names
- Bold for pending item titles
- Do not name the audience or any internal stakeholders

---

## Late Night Rule

If working past midnight (e.g. 1am, 2am), count the work as the **previous day's** update. Do not create a new date entry — append to or update the most recent entry in the file.
