---
description: Read-only PR triage. Auto reply+resolve ONLY for bot threads (STYLE/FALSE-ALARM). Human threads: report only.
arguments:
  - name: pr
    description: PR number or URL (e.g. 123 or https://github.com/org/repo/pull/123)
---

## Task

Triage all unresolved review threads on a pull request. Classify each as CRITICAL, NONCRITICAL, FALSE-ALARM, or STYLE. Auto reply+resolve only for bot threads with low-impact verdicts. Never touch human threads.

## Rules

- DO NOT edit, write, or modify any code files.
- DO NOT checkout branches, commit, or run tools that change repo state.
- You MAY reply+resolve ONLY for BOT threads when verdict is STYLE, FALSE-ALARM, or NONCRITICAL with ~Low / ~Very Low likelihood.
- For HUMAN feedback: NEVER reply, NEVER resolve (report only).
- If unsure whether bot vs human: treat as HUMAN.

## Definitions

**Human feedback** — thread author login is not a known bot and not obviously automated.

**Bot feedback** — author login indicates automation (e.g. contains "bot") OR matches known tools: greptile, cursor bugbot, codex, github-actions, dependabot, renovate, snyk, codecov, sonar, etc.

**Severity levels:**
- `CRITICAL` — correctness, crashes, data loss, or security issues that are realistically exploitable
- `NONCRITICAL` — valid but minor
- `FALSE-ALARM` — incorrect, misunderstanding, or flagging intentional behavior
- `STYLE` — cosmetic / formatting / preference

## Context

**Before assigning CRITICAL:**
- Ask "can this realistically happen in production given how the code is used?" If no → downgrade to NONCRITICAL or FALSE-ALARM.
- Ask "could this be intentional given the feature's business purpose?" If yes or unsure → do NOT flag as CRITICAL, note the uncertainty.
- Every CRITICAL must include an estimated real-world likelihood: ~High / ~Medium / ~Low / ~Very Low.
- If likelihood is ~Low or ~Very Low, downgrade to NONCRITICAL unless impact is catastrophic (data loss, auth bypass).

**Business context:**
- Before flagging any issue, consider whether the behavior makes sense for what the feature is supposed to do.
- If a reviewer flags something that looks like a business rule or intentional design choice, classify as FALSE-ALARM and explain why.
- Do NOT treat "I don't understand why this works this way" as a reason to flag a risk.

## Steps

**1) Identify PR**
```
gh pr view {{pr}} --json number,title,url,headRefName,baseRefName
```

**2) Fetch review threads**
```
gh api graphql -f query='
query($owner:String!, $name:String!, $number:Int!) {
  repository(owner:$owner, name:$name) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes {
          id
          isResolved
          isOutdated
          comments(first:50) {
            nodes {
              id
              author { login }
              body
              path
              position
              originalPosition
              createdAt
            }
          }
        }
      }
    }
  }
}' -f owner=... -f name=... -F number=...
```

**3) Classify each thread** using the severity levels and decision rules below.

**4) Act** per the decision rules.

## Decision Rules

| Verdict | Likelihood | Author | Action |
|---|---|---|---|
| CRITICAL | ~High or ~Medium | Any | Report + fix plan. Do NOT reply or resolve. |
| CRITICAL | ~Low or ~Very Low | Any | Downgrade to NONCRITICAL (unless catastrophic). |
| NONCRITICAL | ~High or ~Medium | Any | Report only. |
| NONCRITICAL | ~Low or ~Very Low | Bot | Reply + resolve. |
| NONCRITICAL | ~Low or ~Very Low | Human | Report only. |
| STYLE / FALSE-ALARM | — | Bot | Reply + resolve. |
| STYLE / FALSE-ALARM | — | Human | Report only. |

**Bot reply guidelines:**
- 1–3 sentences max, professional and factual.
- For STYLE/FALSE-ALARM: explain why no change is needed.
- For ~Low/~Very Low NONCRITICAL: acknowledge the point, explain the likelihood is too low to justify a fix at this time.
- No promises.
- Only resolve after replying, and only if no code change is required.

## Output Format

**A) PR summary**

**B) Triage table** (all unresolved threads, before any actions)
- Thread ID | Author | Bot/Human | File/location | Claim summary | Verdict | Likelihood | Business context | Recommended action | Rationale

**C) Bot replies posted** (if any)
- Thread ID → exact reply text

**D) Threads resolved** (bot-only)
- Thread IDs

**E) Minimal fix plan** (ONLY for CRITICAL with ~High or ~Medium likelihood)
- Issue summary
- Real-world likelihood + why
- Minimal change + verification step

**F) Human follow-up needed**
- List of human threads with recommended next steps for you to take
