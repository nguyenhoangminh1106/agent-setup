---
name: pr-triage
description: Read-only PR triage. Auto reply+resolve ONLY for bot threads (STYLE/FALSE-ALARM). Human threads: report only.
arguments:
  - name: pr
    description: PR number or URL (e.g. 123 or https://github.com/org/repo/pull/123)
---

STRICT MODE:
- DO NOT edit, write, or modify any code files.
- DO NOT checkout branches, commit, or run tools that change repo state.
- You MAY reply+resolve ONLY for BOT threads when verdict is STYLE, FALSE-ALARM, or NONCRITICAL with ~Low / ~Very Low likelihood.
- For HUMAN feedback: NEVER reply, NEVER resolve (report only).

Definitions:
- HUMAN feedback = thread author login is not a known bot and not obviously automated.
- BOT feedback = author login indicates automation (e.g. contains "bot") OR matches known tools:
  greptile, cursor bugbot, codex, github-actions, dependabot, renovate, snyk, codecov, sonar, etc.
If unsure whether bot vs human: treat as HUMAN (report-only).

Severity classification:
- CRITICAL: correctness, crashes, data loss, or security issues that are realistically exploitable
- NONCRITICAL: valid but minor
- FALSE-ALARM: incorrect, misunderstanding, or flagging intentional behavior
- STYLE: cosmetic / formatting / preference

Before assigning CRITICAL:
- Ask "can this realistically happen in production given how the code is used?" If no → downgrade to NONCRITICAL or FALSE-ALARM.
- Ask "could this be intentional given the feature's business purpose?" If yes or unsure → do NOT flag as CRITICAL, note the uncertainty instead.
- Every CRITICAL must include an estimated real-world likelihood: ~High / ~Medium / ~Low / ~Very Low.
- If likelihood is ~Low or ~Very Low, downgrade to NONCRITICAL unless the impact is catastrophic (data loss, auth bypass).

Business context awareness:
- Before flagging any issue, consider whether the behavior makes sense for what the feature is supposed to do.
- If a reviewer flags something that looks like a business rule or intentional design choice, classify as FALSE-ALARM and explain why.
- Do NOT treat "I don't understand why this works this way" as a reason to flag a risk.

Objectives:
- Read ALL unresolved PR review threads/comments.
- Validate each claim — including whether the claim accounts for business intent.
- Preserve consistency: if a suggestion would break existing patterns in the file/module, recommend IGNORE.
- Only propose fixes for CRITICAL issues (in plan). No code changes.

Data collection (use gh; prefer GraphQL):

1) Identify PR:
   gh pr view {{pr}} --json number,title,url,headRefName,baseRefName

2) Fetch review threads:
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

Decision rules:
- CRITICAL with ~High or ~Medium likelihood (any author):
  - Report + add to minimal fix plan
  - Do NOT reply, do NOT resolve
- CRITICAL with ~Low or ~Very Low likelihood (any author):
  - Downgrade to NONCRITICAL unless impact is catastrophic (data loss, auth bypass)
- NONCRITICAL with ~High or ~Medium likelihood (any author):
  - Report only (no auto actions)
- NONCRITICAL with ~Low or ~Very Low likelihood:
  - If BOT: reply + resolve (explain the risk is too unlikely to warrant a fix)
  - If HUMAN: report only
- STYLE or FALSE-ALARM:
  - If BOT: reply + resolve
  - If HUMAN: report only (no auto actions)

Reply guidelines (BOT only):
- 1–3 sentences max
- Professional, factual
- For STYLE/FALSE-ALARM: explain why no change is needed (no behavior impact / consistency)
- For ~Low/~Very Low NONCRITICAL: acknowledge the point, explain the likelihood is too low to justify a fix at this time
- No promises

Resolve rules (BOT only):
- Resolve only after replying
- Only if no code change required

Output format (STRICT):

A) PR summary

B) Triage table (all unresolved threads BEFORE any actions)
- Thread ID
- Author login
- Bot or Human (your classification)
- File/location
- Claim summary
- Verdict
- Real-world likelihood (for CRITICAL/NONCRITICAL): ~High / ~Medium / ~Low / ~Very Low
- Business context check: Intentional? / Unclear / Not applicable
- Recommended action: FIX PLAN / IGNORE / ASK / (BOT) REPLY+RESOLVE
- Rationale

C) Bot replies posted (if any)
- Thread ID
- Exact reply text

D) Threads resolved (bot-only)
- Thread IDs

E) Minimal fix plan (ONLY for CRITICAL with ~High or ~Medium likelihood)
- Issue summary
- Real-world likelihood + why
- Minimal change + verification step
- Note: skip fix plan for ~Low / ~Very Low likelihood unless impact is catastrophic

F) Human follow-up needed
- List of human threads where you recommend what I should reply/do next
