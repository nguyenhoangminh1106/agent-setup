---
description: "Read raw user input (ticket, chat, context dumps) and the existing codebase, then produce a clean requirement spec that minimizes changes and aligns with existing patterns."
arguments:
  - name: input
    description: "Raw user input: ticket text, chat history, context, decisions, or any combination. Can be a GitHub issue number/URL."
---

## Task

Read everything the user provided — ticket, chat, context, decisions — then study the existing codebase to understand its patterns, conventions, and what already exists. Produce a clean, codebase-aware requirement spec that describes the smallest change needed to satisfy the intent, reusing existing code wherever possible.

## Rules

- Read the codebase before writing the spec. Understanding what already exists is mandatory.
- Prefer reusing existing code, patterns, and abstractions over introducing new ones.
- It is acceptable to slightly adjust the stated approach if doing so results in a smaller diff and better alignment with the codebase — but never change the intent or outcome.
- Never invent scope. If something is unclear, document the uncertainty.
- Do not document things that don't need to change.

## Steps

**1) Ingest all input**

Read `{{input}}` in full. If it is a GitHub issue number or URL, fetch it first:
```
gh issue view {{input}} --json title,body,labels,assignees,comments
```

Treat everything — ticket body, discussion comments, decisions, constraints — as context. Nothing is discarded.

**2) Study the existing codebase**

Before writing a single line of spec, read the relevant parts of the codebase:
- Find files and modules related to the feature area described in the input.
- Identify the existing patterns: how similar features are structured, named, and wired together.
- Note what already exists that can be reused or extended rather than recreated.
- Note what must NOT be touched (unrelated code, stable APIs, shared utilities with many callers).

The goal: understand the path of least resistance through the codebase that still satisfies the intent.

**3) Produce the spec**

Write the spec in this format:

---

## Goal
One paragraph. What the user wants to achieve and why.

## Codebase alignment
- Existing code that will be reused or extended (with file paths).
- Patterns this change should follow.
- Any deviation from the stated approach that reduces diff size, and why it's equivalent.

## What changes
A focused list of what needs to be added or modified. Every item must be the minimum necessary.
- For each: what changes, in which file, and why it can't be avoided.

## What does NOT change
Explicitly list areas that might seem related but should not be touched.

## Acceptance criteria
Concrete, testable conditions. Written from the user's perspective — what they can observe or verify.

## Edge cases
Boundary conditions and failure modes to handle.

## Assumptions
Anything inferred that is not stated. Flag each with [ASSUMPTION].

## Open questions
Anything unclear that a human must decide before implementation begins.

---

**4) Save artifact**

Write the spec to `.claude/ticket-artifacts/spec.md`:
```
mkdir -p .claude/ticket-artifacts
```
Save the spec content to `.claude/ticket-artifacts/spec.md`.

**5) Display**

Print the full spec to the user.
