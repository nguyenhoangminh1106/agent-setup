---
description: "Read a ticket and the codebase, then ask only the questions that can't be answered from existing code. If everything is clear, say so."
arguments:
  - name: ticket
    description: "Ticket text, GitHub issue number, or URL describing the work to be done."
---

## Task

Read the ticket and the existing codebase. Identify only the things that are genuinely unclear and cannot be inferred from the code. Output a short, targeted question list — or confirm that nothing is unclear.

## Rules

- Read the codebase before forming any questions.
- Do NOT ask about things that are already clear from existing code, even if the ticket describes them slightly differently. If the existing pattern is close enough, assume it applies.
- Do NOT ask about implementation details you can figure out by reading the code.
- Do NOT list things that are clear — only list genuine blockers.
- Ask the minimum number of questions. One precise question is better than three vague ones.
- If nothing is unclear: say "Nothing is unclear. Ready to implement." — do not invent questions.

## Steps

**1) Ingest the ticket**

Read `{{ticket}}` in full. If it is a GitHub issue number or URL, fetch it:
```
gh issue view {{ticket}} --json title,body,labels,assignees,comments
```

Extract the intent: what is being asked for, and why.

**2) Study the codebase**

Before forming any question, read the relevant parts of the codebase:
- Find files and modules related to the feature area.
- Understand existing patterns: how similar things are structured, named, and wired.
- Note what already exists that the ticket might be reusing or extending.
- Note where the ticket's description conflicts with, deviates from, or is simply silent about the existing code.

The goal: determine what you would need to know to implement the ticket that you cannot answer yourself.

**3) Filter aggressively**

For each potential question, apply this test:
- Can it be answered by reading the code? → Drop it.
- Is the existing behavior close enough to implement against? → Drop it.
- Does it require a business decision, a design choice, or knowledge that only the requester has? → Keep it.

**4) Output**

If there are questions, output:

---

## Questions before implementing

For each question:
- One sentence describing what is unclear.
- Why it cannot be inferred from the codebase (one short sentence).

---

If there are no questions, output exactly:

---

Nothing is unclear. Ready to implement.

---
