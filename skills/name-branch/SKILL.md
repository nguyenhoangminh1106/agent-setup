---
name: name-branch
description: "Generate a well-formatted git branch name from a ticket, feature request, plain-English context, or the current repo's combined uncommitted and unpushed changes."
---

## Task

Read the context and produce exactly one valid git branch name. Nothing else. No explanation, no reasoning, no markdown — just the name.

## Rules

- **Follow the repo's existing branch naming convention.** Run `git branch --all --format='%(refname:short)' | head -30` and match the pattern used (e.g. `minh2/eng-<num>-<slug>`, `feat/<slug>`, etc).
- If the context contains a Linear or GitHub ticket number (e.g. `ENG-5618`), include it in the name: `<user>/eng-<num>-<short-slug>`.
- Kebab-case only — lowercase letters, numbers, hyphens. No extra slashes.
- **Max 50 characters total.** Truncate the slug if needed — never exceed this.
- Be concise — 3–5 words for the slug is enough.
- If the context is a file path (starts with `/` or `./`), read the file from disk first.
- If no context is provided, apply [current-work](../current-work/SKILL.md) and name the combined active work it identifies, including relevant uncommitted and unpushed changes. Do not include unrelated changes imported from main. Keep discovery internal so the exact output contract below is preserved.
- **Output ONLY the final `BRANCH:<name>` line to stdout. Nothing else. No explanation, no markdown, no extra lines.**

## Steps

**1) Read the context**

Detect the input type:
- **No input provided**: use the `current-work` scope result, read its relevant patches/code, and generate one branch name describing the combined intent. This also applies when working directly on main.
- **File path** (starts with `/` or `./`): read the file from disk, then re-detect what's inside it.
- **Linear URL** (`linear.app/...`): the ticket pipeline pre-fetches Linear issue content before invoking this skill, so the input will already contain the issue title as plain text. Use it as-is.
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

No other output. No explanation, no reasoning, no markdown, no trailing newline. Just that one line.
