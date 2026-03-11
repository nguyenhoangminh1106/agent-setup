---
description: "Read a ticket and the codebase, then ask only the questions that can't be answered from existing code. If everything is clear, say so."
arguments:
  - name: ticket
    description: "Ticket text, GitHub issue number, or URL describing the work to be done."
---

## Task

Read the ticket and the existing codebase. Identify only the things that are genuinely unclear and cannot be inferred from code at all. Output a short, targeted question list — or confirm that nothing is unclear.

## Rules

- **Read the codebase first** — mandatory before forming any question.
- **If you can make a reasonable inference from existing code, do not ask.** Even if the ticket is silent, if a similar pattern exists in the codebase you can follow it — that is not a question.
- **Only ask when you truly cannot proceed without an answer.** The bar is: "I cannot implement this correctly without knowing X, and X does not exist anywhere in the codebase."
- Do NOT ask about implementation details — how to build it is your job.
- Do NOT ask about things that are standard practice or follow from existing code patterns.
- Do NOT list things that are clear.
- Ask the minimum number of questions. Zero is the right answer most of the time.
- If nothing is unclear: output exactly `CLARIFY:DONE` on its own line — nothing else.
- If there are questions: output exactly `CLARIFY:QUESTIONS` on its own line, then list the questions.

## Steps

**1) Ingest the ticket**

Read `{{ticket}}` in full:
- If it is a file path (starts with `/` or `./`), read the file from disk.
- If it is a GitHub issue number or URL, fetch it: `gh issue view {{ticket}} --json title,body,labels,assignees,comments`
- Otherwise treat it as inline text.

If the input contains a previous round of Q&A (`## Answers`), treat those answers as resolved context — do not re-ask answered questions.

Extract the intent: what is being asked for, and why.

**2) Study the codebase**

Read the relevant parts of the codebase before forming any question:
- Find files and modules related to the feature area.
- Understand existing patterns: how similar things are structured, named, and wired.
- Note what already exists that the ticket might be reusing or extending.

The goal: determine what you need to know that you absolutely cannot infer from the code.

**3) Filter aggressively**

For each potential question, apply this test in order:
1. Can it be answered by reading the code? → **Drop it.**
2. Can a reasonable inference be made from a similar existing pattern? → **Drop it.**
3. Is it an implementation decision (how to build it)? → **Drop it — that's your job.**
4. Does it require a business decision or knowledge only the requester has, with no codebase signal at all? → **Keep it.**

**4) Output**

If there are no questions:
```
CLARIFY:DONE
```

If there are questions:
```
CLARIFY:QUESTIONS

1. <question> — <one sentence on why the codebase gives no signal here>
2. <question> — <one sentence on why the codebase gives no signal here>
```
