---
description: "Generate a well-formatted git branch name from a ticket, feature request, or any plain-English context."
arguments:
  - name: context
    description: "Ticket text, feature description, issue title, or any plain-English description of the work."
---

## Task

Read the context and produce exactly one valid git branch name. Nothing else.

## Rules

- Use the correct prefix: `feat/` for new features, `fix/` for bug fixes, `chore/` for maintenance/tooling/refactors.
- Kebab-case only — lowercase letters, numbers, hyphens. No slashes except the prefix separator.
- Max 50 characters total (including prefix).
- Be descriptive but concise — capture the core intent in 3–5 words.
- If the context is a file path, read the file from disk first.
- Do NOT output anything except the final line: `BRANCH:<name>`

## Steps

**1) Read the context**

If `{{context}}` starts with `/` or `./`, read the file from disk. Otherwise treat it as inline text.

**2) Extract the intent**

Identify what is being built or fixed in one phrase. Ignore implementation details.

**3) Generate the branch name**

Apply the rules above. Examples:
- "Add dark mode toggle to settings page" → `feat/dark-mode-toggle`
- "Fix null pointer crash on checkout" → `fix/null-pointer-checkout`
- "Upgrade dependencies and clean up lint warnings" → `chore/upgrade-deps-lint-cleanup`
- "Linear ticket ENG-142: user can export invoices as PDF" → `feat/export-invoices-pdf`

**4) Output**

Print exactly one line:
```
BRANCH:<name>
```

No explanation. No markdown. No extra lines.
