---
name: branch-risk-review
description: Read-only risk-focused review of branch/PR changes. Ensures no behavior breakage and alignment with existing code style. No code edits.
arguments:
  - name: target
    description: Branch name or PR number/URL to review
---

STRICT READ-ONLY MODE:
- DO NOT edit, write, or modify any code.
- DO NOT checkout, commit, or rebase.
- Output REPORT ONLY.

## Priorities (in order — earlier beats later)

1. **Don't break existing behavior** — Any regression or silent behavior change is a hard NO.
2. **Follow existing code** — Match the style, patterns, naming, and structure already in the file/module. Don't introduce a new pattern when one already exists.
3. **Minimize the diff** — Prefer the smaller change. A fix that touches 3 lines is better than one that touches 30.
4. **Simplify** — Simpler code is better. Flag unnecessary complexity, over-engineering, or abstractions that add no real value.
5. **Code quality** — Readability, clarity, sensible naming.

## Security and safety: keep it proportional

- Only flag security issues if they are concrete, exploitable in a realistic real-world scenario, and worth the cost of fixing.
- Ask: "Can this actually happen in practice, given how this code is used?" If no → skip it.
- Minor concerns (theoretical XSS on an internal tool, a null check that can't realistically trigger) → at most a non-blocking note.
- Never suggest adding complexity, extra validation layers, or defensive code for hypothetical edge cases.
- Do NOT penalize simple, readable code in favor of "safer" but more complex code.

## Business context: understand intent before flagging

- Before flagging something as a risk, consider whether it might be intentional by design.
- If a feature behaves in a way that makes sense for a business reason (e.g. skipping a check for performance, allowing an action that seems unsafe but is gated upstream), do NOT flag it as a risk just because you don't have full context.
- When unsure whether something is a bug or intentional: ask or note the uncertainty — do NOT assume it's wrong.
- Flagging intentional behavior as a risk wastes review time and erodes trust in the review.

## What is UNACCEPTABLE

- Silent behavior changes in existing logic
- Broad refactors that touch unrelated code
- Rewriting working logic without a clear reason
- Introducing a new pattern when the existing one works fine
- Adding complexity where simplicity would do

## What is ACCEPTABLE (do not flag these)

- Small inefficiencies
- Minor style inconsistencies
- Slightly unconventional but contained code
- Skipping defensive checks that can't realistically fail

---

## Data collection

1) Identify target:
- If PR:
  gh pr view {{target}} --json number,title,url,baseRefName,headRefName
- If branch:
  git show-ref {{target}}

2) Collect diff ONLY (no working tree changes):
- If PR:
  gh pr diff {{target}}
- If branch:
  git diff origin/main...{{target}}

3) For context (read surrounding code in touched files as needed).

---

## Review dimensions

### A) Behavioral safety (MOST IMPORTANT)
- Could any existing code path behave differently after this change?
- Any logic that used to work but might not now?
- Any edge case handled differently in a way that affects current users?

### B) Consistency with existing code
- Does this match the style, structure, and patterns used in the same file/module?
- Same error handling approach? Same naming conventions?
- If it deviates: is there a good reason, or is it just different?

### C) Diff size and containment
- Is the diff minimal for the goal?
- Is new logic isolated, or does it touch existing logic unnecessarily?
- Could the same outcome be achieved with fewer changes?

### D) Simplicity
- Is the code as simple as it could be?
- Any unnecessary abstractions, layers, or complexity?
- Would a simpler approach work just as well?

### E) Code quality (LOWER priority)
- Readability and clarity
- Sensible naming
- No unnecessary cleverness

---

## Output format (STRICT)

A) Review summary
- Target (branch or PR)
- Overall risk level: LOW / MEDIUM / HIGH
- Safe to merge? YES / YES WITH CAUTION / NO

B) File-by-file analysis
For each changed file:
- File path
- What changed (1–2 lines)
- Risk: None / Low / Medium / High
- Why (specific reasoning)
- Consistency with existing code: OK / Minor deviation / Concerning
- Diff size: Minimal / Reasonable / Larger than needed

C) Risk highlights (REAL risks only)
- Only list concrete scenarios where existing behavior could break in practice
- For each risk, explicitly state: what triggers it, how likely it is in real use, and what the actual impact is
- Skip theoretical, low-probability, or "could happen if someone does X wrong" concerns
- If something looks risky but might be intentional, note the uncertainty instead of flagging it as a defect

D) Simplicity and complexity notes
- Flag over-engineered code, unnecessary abstractions, or added complexity that isn't justified
- Flag places where a simpler approach would achieve the same result

E) Non-blocking observations
- Style, minor quality notes
- Small security notes (only if they matter in practice)
- Things intentionally not flagged to avoid over-reporting

F) Recommendations (guidance only)
- How to reduce risk while keeping the diff small
- Where to simplify without breaking anything
- Optional follow-ups (clearly marked as optional)
