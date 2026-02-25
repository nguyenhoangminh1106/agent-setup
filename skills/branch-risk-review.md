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
- DO NOT suggest refactors that require large diffs.
- Output REPORT ONLY.

PRIMARY GOAL (highest priority):
1) Ensure new changes DO NOT break existing logic or behavior.
2) Ensure changes FOLLOW the existing style, patterns, and structure of the codebase.
3) Minimize risk over cleanliness or ideal design.

SECONDARY GOALS:
- Identify real risks (logic, edge cases, regressions).
- Prefer reuse of existing helpers/utilities.
- Prefer isolating new logic instead of modifying old logic.
- Prefer minimal diffs.
- Code quality matters, but safety > elegance.

ACCEPTABLE:
- Small inefficiencies
- Minor style inconsistencies
- Slightly "bad" but contained code
If fixing them risks breaking existing behavior.

UNACCEPTABLE:
- Silent behavior changes
- Inconsistent patterns inside the same file/module
- Broad refactors touching unrelated logic
- Rewriting existing working logic unnecessarily

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

3) For context (if needed):
- Inspect surrounding existing code in touched files.

---

## Review dimensions (evaluate ALL)

### A) Behavioral safety (MOST IMPORTANT)
- Any change that could alter existing behavior?
- Any logic path that used to work but might not now?
- Any edge case now handled differently?

### B) Consistency with existing code
- Does this follow the same style used nearby?
- Same error handling approach?
- Same naming, structure, abstraction level?
- If different: is it justified or risky?

### C) Change containment
- Is new logic isolated?
- Did it modify existing logic directly?
- Could it have been added without touching old code?

### D) Reuse vs duplication
- Could existing helpers be reused?
- If duplication exists, is it acceptable to avoid risk?

### E) Code quality (LOWER priority)
- Readability
- Clarity
- Reasonable complexity
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
- Risk assessment:
  - None / Low / Medium / High
- Why (specific reasoning)
- Consistency with existing code: OK / Minor deviation / Concerning
- Notes on containment & reuse

C) Risk highlights (if any)
- List only REAL risks
- Explain exact scenario where behavior could break

D) Non-blocking observations
- Style
- Minor quality notes
- Things intentionally NOT fixed to avoid risk

E) Recommendations (GUIDANCE ONLY)
- If changes are risky:
  - How to reduce risk while minimizing diff
  - How to isolate logic better
- If changes are safe:
  - Optional follow-ups (clearly marked as optional)

F) Handoff notes
- What another agent SHOULD change (if any)
- What MUST NOT be touched to avoid regressions
