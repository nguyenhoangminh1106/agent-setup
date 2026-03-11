---
description: "Accept a plain-English question, figure out the right read-only query, run it against the DB, and return a clear answer. Never mutates data."
arguments:
  - name: question
    description: "Plain-English question about the data (e.g. 'How many users signed up last week?' or 'Show me all pending orders for customer 42')."
  - name: db
    description: "DB connection string or tool name (e.g. 'psql://user:pass@host/db', 'Prisma Studio', 'sqlite:./dev.db'). If omitted, the skill will ask."
---

## Task

Accept a plain-English question about the database, figure out the correct read-only query, run it, and return a clear human-readable answer. Never run any mutation (INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE, etc.).

---

## Rules

- **Read-only only.** If the question implies a mutation, refuse and explain why.
- Never assume a connection string — ask if `{{db}}` was not provided.
- Always show the query you ran alongside the result, so the user can verify it.
- If the query returns no rows, say so explicitly — do not invent data.
- If the schema is unknown, introspect it first (e.g. `\dt` in psql, `PRAGMA table_list` in SQLite, `SHOW TABLES` in MySQL).
- Prefer simple, readable queries. Avoid joins unless necessary to answer the question.
- Limit result rows to 50 by default unless the question implies a full count or aggregate.

---

## Steps

**1) Get DB access**

If `{{db}}` is provided, use it directly.

Otherwise ask:
> "What DB should I query? Provide a connection string, a tool name (e.g. Prisma Studio), or a local file path (e.g. `sqlite:./dev.db`)."

Wait for the answer before proceeding.

**2) Understand the question**

Parse `{{question}}` (or the user's message) to identify:
- The entity or table involved (e.g. users, orders, events)
- The filter or condition (e.g. status = pending, created last week)
- The shape of the answer needed (count, list of rows, single value, etc.)

**3) Introspect schema if needed**

If the table name or column names are uncertain, run a schema inspection query first:

- PostgreSQL: `\dt` or `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';`
- MySQL: `SHOW TABLES;`
- SQLite: `SELECT name FROM sqlite_master WHERE type='table';`

Then inspect the relevant table:
- PostgreSQL / MySQL: `SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '<table>';`
- SQLite: `PRAGMA table_info(<table>);`

**4) Build the query**

Translate the plain-English question into a SQL SELECT (or equivalent read-only query). Apply:
- Appropriate WHERE / HAVING filters
- ORDER BY if the question implies recency or ranking
- `LIMIT 50` unless the question is an aggregate (COUNT, SUM, AVG, etc.)

**5) Run the query**

Execute using the provided DB access method. Show the query before the result:

```
Query:
  <SQL here>

Result:
  <rows or value>
```

**6) Answer in plain English**

After the raw result, write 1–3 sentences summarising the answer to the original question in plain English. Example:

> "There are **142 users** who signed up in the last 7 days. The most recent joined 3 hours ago (user ID 9981)."

**7) Offer follow-up**

Suggest 1–2 natural follow-up queries the user might want, based on what the result showed. Example:

> "Want me to break this down by day, or show the full list with email addresses?"
