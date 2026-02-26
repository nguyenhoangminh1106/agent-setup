---
description: Read-only risk-focused review of branch/PR changes. Ensures no behavior breakage and alignment with existing code style. No code edits.
arguments:
  - name: target
    description: Branch name or PR number/URL to review
---

## Task

Review the diff of a branch or PR for behavioral regressions, consistency issues, and unnecessary complexity. Output a structured risk report. Do not edit any code.

## Rules

- DO NOT edit, write, or modify any code.
- DO NOT checkout, commit, or rebase.
- Output a REPORT ONLY.

## Context

**Priorities (earlier beats later):**
1. **Don't break existing behavior** — Any regression or silent behavior change is a hard NO.
2. **Follow existing code** — Match the style, patterns, naming, and structure already in the file/module.
3. **Minimize the diff** — A fix that touches 3 lines is better than one that touches 30.
4. **Simplify** — Flag unnecessary complexity, over-engineering, or abstractions that add no real value.
5. **Code quality** — Readability, clarity, sensible naming.

**Security and safety — keep it proportional:**
- Only flag security issues if they are concrete, exploitable in a realistic real-world scenario, and worth the cost of fixing.
- Ask: "Can this actually happen in practice, given how this code is used?" If no → skip it.
- Never suggest adding complexity or defensive code for hypothetical edge cases.
- Do NOT penalize simple, readable code in favor of "safer" but more complex code.

**Business context — understand intent before flagging:**
- Before flagging something as a risk, consider whether it might be intentional by design.
- If a feature behaves in a way that makes sense for a business reason, do NOT flag it as a risk just because you don't have full context.
- When unsure whether something is a bug or intentional: note the uncertainty — do NOT assume it's wrong.

**What is UNACCEPTABLE:**
- Silent behavior changes in existing logic
- Broad refactors that touch unrelated code
- Rewriting working logic without a clear reason
- Introducing a new pattern when the existing one works fine
- Adding complexity where simplicity would do

**What is ACCEPTABLE (do not flag):**
- Small inefficiencies
- Minor style inconsistencies
- Slightly unconventional but contained code
- Skipping defensive checks that can't realistically fail

## Steps

**1) Identify target**
```
# If PR:
gh pr view {{target}} --json number,title,url,baseRefName,headRefName

# If branch:
git show-ref {{target}}
```

**2) Collect diff** (no working tree changes)
```
# If PR:
gh pr diff {{target}}

# If branch:
git diff origin/main...{{target}}
```

**3) Read surrounding context** in touched files as needed for accurate analysis.

**4) Review** across all dimensions below and produce the output report.

## Review Dimensions

**A) Behavioral safety** *(most important)*
- Could any existing code path behave differently after this change?
- Any logic that used to work but might not now?
- Any edge case handled differently in a way that affects current users?

**B) Consistency with existing code**
- Does this match the style, structure, and patterns used in the same file/module?
- Same error handling approach? Same naming conventions?
- If it deviates: is there a good reason?

**C) Diff size and containment**
- Is the diff minimal for the goal?
- Is new logic isolated, or does it touch existing logic unnecessarily?
- Could the same outcome be achieved with fewer changes?

**D) Simplicity**
- Is the code as simple as it could be?
- Any unnecessary abstractions, layers, or complexity?

**E) Code quality** *(lower priority)*
- Readability and clarity
- Sensible naming
- No unnecessary cleverness

## Output Format

**A) Review summary**
- Target (branch or PR)
- Overall risk level: LOW / MEDIUM / HIGH
- Safe to merge? YES / YES WITH CAUTION / NO

**B) File-by-file analysis**
For each changed file:
- File path
- What changed (1–2 lines)
- Risk: None / Low / Medium / High + why
- Consistency with existing code: OK / Minor deviation / Concerning
- Diff size: Minimal / Reasonable / Larger than needed

**C) Risk highlights** (real risks only)
- Only list concrete scenarios where existing behavior could break in practice.
- For each risk: what triggers it, how likely in real use, what the actual impact is.
- Skip theoretical or "could happen if someone does X wrong" concerns.

**D) Simplicity and complexity notes**
- Flag over-engineered code or added complexity that isn't justified.
- Flag places where a simpler approach would achieve the same result.

**E) Non-blocking observations**
- Style, minor quality notes
- Small security notes (only if they matter in practice)
- Things intentionally not flagged to avoid over-reporting

**F) Recommendations** (guidance only)
- How to reduce risk while keeping the diff small
- Where to simplify without breaking anything
- Optional follow-ups (clearly marked as optional)
