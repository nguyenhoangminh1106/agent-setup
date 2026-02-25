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
- You MAY reply+resolve ONLY for BOT threads when verdict is STYLE or FALSE-ALARM.
- For HUMAN feedback: NEVER reply, NEVER resolve (report only).

Definitions:
- HUMAN feedback = thread author login is not a known bot and not obviously automated.
- BOT feedback = author login indicates automation (e.g. contains "bot") OR matches known tools:
  greptile, cursor bugbot, codex, github-actions, dependabot, renovate, snyk, codecov, sonar, etc.
If unsure whether bot vs human: treat as HUMAN (report-only).

Severity classification:
- CRITICAL: correctness, security, crashes, data loss
- NONCRITICAL: valid but minor
- FALSE-ALARM: incorrect or misunderstanding
- STYLE: cosmetic / formatting / preference

Objectives:
- Read ALL unresolved PR review threads/comments.
- Validate each claim.
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
- CRITICAL (any author):
  - Report + add to minimal fix plan
  - Do NOT reply, do NOT resolve
- NONCRITICAL (any author):
  - Report only (no auto actions)
- STYLE or FALSE-ALARM:
  - If BOT: reply + resolve
  - If HUMAN: report only (no auto actions)

Reply guidelines (BOT only):
- 1–3 sentences max
- Professional, factual
- Explain why no change is needed (no behavior impact / consistency)
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
- Recommended action: FIX PLAN / IGNORE / ASK / (BOT) REPLY+RESOLVE
- Rationale

C) Bot replies posted (if any)
- Thread ID
- Exact reply text

D) Threads resolved (bot-only)
- Thread IDs

E) Minimal fix plan (ONLY for CRITICAL)
- Minimal change + verification step

F) Human follow-up needed
- List of human threads where you recommend what I should reply/do next
