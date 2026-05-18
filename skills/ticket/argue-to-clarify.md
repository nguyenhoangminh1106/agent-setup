---
description: "Challenge unclear requests through concise solution-design arguments after silently reading the relevant codebase, likely edit locations, feature context, and business intent, until the request, constraints, implementation direction, and planning path are high quality, without implementing anything unless the user explicitly instructs implementation."
---

# Argue To Clarify

## Overview

Use this skill to turn an unclear request into a clear, high-quality direction by arguing only about real solution-design decisions.
Before asking the first question, silently inspect the relevant codebase, likely edit locations, existing feature behavior, product vocabulary, related business intent, and nearby implementation patterns.
Run it as a step-by-step dialogue after that context pass: make one argument, ask one yes/no question, remember that question until it is answered, then choose the next argument from the full conversation so far.
This skill stops at clarification, specification, or planning; it must never modify files, run implementation commands, create branches, commit, open PRs, or otherwise execute the plan unless the user gives a separate explicit instruction to implement.

## Core Rules

- Argue to clarify, not to win.
- Ask only questions that affect implementation, product behavior, architecture, data flow, UX, constraints, tradeoffs, or acceptance criteria.
- Do not ask preference, background, or curiosity questions unless the answer changes the solution.
- Make each argument exactly one sentence.
- Include an example whenever it makes the decision easier to understand.
- Prefer specific claims over abstract advice.
- Ground the first and later questions in discovered context from the repository, ticket, docs, product copy, or existing behavior whenever that context is available.
- Do the context gathering silently; do not narrate searches, summarize findings, or tell the user which files were inspected unless that context is necessary to frame the one argument and one ask.
- Stop arguing when there are no relevant clarification questions or real solution-design decisions left.
- Do not impose a fixed limit on the number of questions; continue until the completion criteria are met.
- After clarification is complete, ask whether the user wants a plan, then enter plan-making if they agree.
- Treat plan-making as the maximum allowed next step; do not implement from the plan unless the user explicitly says to implement, build, code, edit, apply, execute, create the branch, commit, or perform an equivalent action.
- Do not interpret approval of a direction, answer to a clarification question, or agreement to make a plan as permission to implement.
- Ask only one question per response.
- Make the question answerable with yes/no whenever possible.
- Preselect the recommended answer so the user can respond with `yes` or `no`.
- Choose each next question from all answers and side discussion so far instead of listing a fixed batch of questions.
- Never dump multiple arguments or multiple asks in one response.

## Live Clarification State

Maintain an internal clarification state across turns:

- Current outcome: the concrete result being clarified.
- Context gathered: relevant files, likely edit locations, existing patterns, related feature behavior, product vocabulary, and business intent that inform the questions.
- Last unanswered question: the exact active ask and recommended answer.
- Known decisions: confirmed answers and important context from the user's side discussion.
- Open decisions: only the implementation-relevant questions still blocking a high-quality plan.

If the user discusses something else before answering, respond to that discussion when appropriate, then return to the last unanswered question if it still matters.
Before re-asking, incorporate any new information from the intervening conversation and rewrite the question so it is still specific and to the point.
If the intervening conversation answers or invalidates the question, mark it resolved and ask the next most important open decision instead.

## Workflow

1. Read the relevant repository, ticket, docs, existing UI/API flows, likely edit locations, naming patterns, and related business context enough to avoid asking questions the codebase can answer.
2. Keep that context internal unless one discovered fact is necessary for the argument.
3. Restate the request as one concrete outcome.
4. Pick the single highest-impact unclear decision, starting high-level before going into smaller pieces.
5. Present one argument and one example if useful.
6. Ask exactly one yes/no question with a recommended answer.
7. Record that ask as the last unanswered question and wait for the user's answer.
8. If the user answers, update known decisions; if the user digresses, answer briefly if useful and re-ask or revise the last unanswered question.
9. Use all accumulated context to choose the next most relevant small decision.
10. Repeat until no relevant clarification remains.
11. When clarification is complete, ask one yes/no question about whether to make a plan.
12. If the user agrees, produce a concrete, ordered plan with milestones, risks, validation, and the first implementation step.
13. Stop after the plan and wait for an explicit implementation instruction before touching code, files, external systems, git state, tickets, or production data.

## Argument Format

Use this compact block:

```markdown
**Decision N**
Argument: One sentence explaining the design risk or tradeoff.
Example: One sentence with a concrete example when helpful.
Ask: Should we choose [recommended option], yes recommended, because [short reason]?
```

Do not add filler like "great question," "to clarify," "it depends," or long explanations before the argument.
Do not include the `Example:` line when it would be repetitive.
Do not include more than one `Ask:` line.
When re-asking after a side conversation, keep the same format and update the argument only if the new context changes the tradeoff.

## Good Arguments

```markdown
**Decision 1**
Argument: Building a generic dashboard before choosing the primary user will create weak defaults because recruiters and admins need different filters.
Example: A recruiter dashboard should default to assigned candidates, while an admin dashboard should default to team-level pipeline health.
Ask: Should v1 optimize for recruiters first, yes recommended, because their default view can stay narrow and actionable?
```

If the user answers `yes`, continue to a decision that assumes recruiter-first behavior.

```markdown
**Decision 2**
Argument: A recruiter-first dashboard should prioritize assigned candidates because team-wide pipeline metrics make the default view slower to act on.
Example: Default to `My candidates`, with `All candidates` as a filter.
Ask: Should the default view show only the recruiter's assigned candidates, yes recommended, because it keeps the first screen actionable?
```

If the user answers `no`, continue to a decision that explores the alternative they selected or implied.

```markdown
**Decision 2**
Argument: An admin-first dashboard should prioritize team health because individual assignment filters hide cross-recruiter bottlenecks.
Example: Default to stage counts by recruiter, with individual candidates one click deeper.
Ask: Should the default view optimize for team health instead, yes recommended, because that matches an admin-first dashboard?
```

## Bad Arguments

- Do not ask: "What inspired this idea?"
- Do not ask: "What color do you like?"
- Do not ask: "Would you like me to explain more?"
- Do not argue: "We should think carefully about scalability."
- Do not ask four questions at once.
- Replace with: "If this endpoint can be called from bulk actions, it needs pagination or queueing because a synchronous request may time out on large accounts."

## Completion Criteria

Before moving from argument to planning, confirm these are known:

- Goal: The concrete outcome is stated.
- Context: Relevant code locations, existing behavior, nearby patterns, and business intent have been inspected enough to avoid unnecessary questions.
- Scope: Included and excluded behavior is explicit.
- Direction: Major design choices are selected.
- Examples: At least one representative example is clear.
- Risks: Important edge cases, constraints, and failure modes are named.
- Next step: The implementation, spec, or plan can proceed without guessing.

These criteria only authorize a plan or spec handoff. They do not authorize implementation, file edits, tool execution for changes, or git operations.

## Plan Handoff

When the completion criteria are met, stop clarifying and use this handoff:

```markdown
Clarification complete: One sentence explaining why no relevant clarification remains.
Ask: Should I make a plan now, yes recommended, because the direction is clear enough to sequence?
```

If the user says yes, produce the plan immediately unless the current environment requires a separate explicit mode switch.
Keep the plan concrete: phases, steps, files or systems likely touched, validation, risks, and first action.
After producing the plan, stop and wait. Only implement if the user explicitly asks for implementation in a later message.
