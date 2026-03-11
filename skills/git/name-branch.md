---
description: "Generate a well-formatted git branch name from a ticket, feature request, or any plain-English context."
arguments:
  - name: context
    description: "Ticket text, feature description, issue title, or any plain-English description of the work."
---

## Task

Read the context and produce exactly one valid git branch name. Nothing else.

## Rules

- **Follow the repo's existing branch naming convention.** Run `git branch --all --format='%(refname:short)' | head -30` and match the pattern used (e.g. `minh2/eng-<num>-<slug>`, `feat/<slug>`, etc).
- If the context contains a Linear or GitHub ticket number (e.g. `ENG-5618`), include it in the name: `<user>/eng-<num>-<short-slug>`.
- Kebab-case only — lowercase letters, numbers, hyphens. No extra slashes.
- **Max 50 characters total.** Truncate the slug if needed — never exceed this.
- Be concise — 3–5 words for the slug is enough.
- If the context is a file path (starts with `/` or `./`), read the file from disk first.
- **Output ONLY the final `BRANCH:<name>` line to stdout. Nothing else. No explanation, no markdown, no extra lines.**

## Steps

**1) Read the context**

Detect the input type:
- **File path** (starts with `/` or `./`): read the file from disk, then re-detect what's inside it.
- **Linear URL** (`linear.app/...`): extract the issue ID (e.g. `ENG-5618`) and fetch the title using the Linear MCP tool (already connected). If MCP is unavailable, use the URL slug as the description.
- **GitHub issue number or URL**: `gh issue view <id> --json title`
- **Plain text**: use as-is.

**2) Check existing branch convention**

```
git branch --all --format='%(refname:short)' | head -30
```

Identify the naming pattern in use (prefix, ticket inclusion, user prefix, etc).

**3) Generate the branch name**

Apply the rules:
- Match the repo's convention
- Include ticket number if present (lowercase, e.g. `eng-5618`)
- Truncate slug so total length ≤ 50 chars
- Examples:
  - Repo uses `minh2/eng-NNN-slug` + ticket ENG-5618 "show AI bubble" → `minh2/eng-5618-show-ai-bubble`
  - Repo uses `feat/slug`, new feature "dark mode toggle" → `feat/dark-mode-toggle`
  - Fix ticket ENG-142 "null pointer on checkout" → `fix/eng-142-null-pointer-checkout`

**4) Output**

Print exactly one line to stdout:
```
BRANCH:<name>
```

No other output. No trailing newline issues. Just that one line.
