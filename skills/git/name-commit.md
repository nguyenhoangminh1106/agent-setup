---
description: "Generate a clean, conventional commit message from a diff, ticket, or plain-English context."
arguments:
  - name: context
    description: "Diff output, ticket text, feature description, or any plain-English description of the changes."
---

## Task

Read the context and produce exactly one commit message. Nothing else.

## Rules

- **Follow the repo's existing commit message convention.** Run `git log --oneline -20` and match the style used (e.g. `feat: ...`, `fix(scope): ...`, `Feat (Minh): ...`).
- Use Conventional Commits format unless the repo clearly uses something else.
- **Subject line ≤ 72 characters.** Truncate if needed — never exceed this.
- Be concise — describe the *what* and *why*, not the *how*.
- Lowercase the subject (unless repo convention capitalizes).
- No trailing period on the subject line.
- If the context is a file path (starts with `/` or `./`), read the file from disk first.
- If no context is provided, run `git diff --cached` (or `git diff` if nothing staged) and generate the message from the actual diff.
- **Output ONLY the final `COMMIT:<message>` line to stdout. Nothing else. No explanation, no markdown, no extra lines.**

## Steps

**1) Read the context**

Detect the input type:
- **No input provided**: run `git diff --cached` (fall back to `git diff` if empty) and use the diff as context.
- **File path** (starts with `/` or `./`): read the file from disk, then re-detect what's inside it.
- **Plain text / ticket text**: use as-is.

**2) Check existing commit convention**

```
git log --oneline -20
```

Identify the commit message pattern in use (prefix style, scope, capitalization, etc).

**3) Generate the commit message**

Apply the rules:
- Match the repo's convention
- Include scope if the repo uses scopes and it's clear from context
- Keep subject ≤ 72 chars
- Examples:
  - Repo uses `feat: slug` + new dark mode → `feat: add dark mode toggle`
  - Repo uses `Feat (Minh): slug` + new auth flow → `Feat (Minh): add OAuth2 login flow`
  - Bug fix for null pointer → `fix: handle null pointer in checkout flow`
  - Refactor of DB layer → `refactor: simplify database connection pooling`

**4) Output**

Print exactly one line to stdout:
```
COMMIT:<message>
```

No other output. No trailing newline issues. Just that one line.
