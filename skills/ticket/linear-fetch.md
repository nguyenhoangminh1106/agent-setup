---
description: "Fetch a Linear ticket's full context — title, description, and all comments — and print it as plain text."
arguments:
  - name: url
    description: "Linear issue URL (e.g. https://linear.app/paraform/issue/ENG-5618/...)"
---

## Task

Fetch the full context of a Linear ticket and print it as plain text. Nothing else — no analysis, no spec, no questions.

## Steps

**1) Extract the issue ID**

Parse the issue ID from `{{url}}` (e.g. `ENG-5618`).

**2) Fetch the issue**

Use the Linear MCP tool to fetch:
- Title
- Description
- All comments (author + body)

**3) Print**

Output exactly this format:

```
# <ISSUE-ID>: <Title>

## Description
<description>

## Comments
### <author> — <date>
<comment body>

### <author> — <date>
<comment body>
```

Print everything verbatim. Do not summarize, interpret, or omit anything.
