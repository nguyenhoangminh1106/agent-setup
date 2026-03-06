---
description: "When Prisma detects schema drift from migrations run on another branch, generate the manual SQL to revert those changes so you can run migrations cleanly on the current branch."
arguments:
  - name: drift
    description: "Paste the full Prisma drift error output. If omitted, the skill will ask you to paste it."
  - name: db
    description: "DB connection string (e.g. 'postgresql://user:pass@localhost:5432/mydb'). If omitted, the skill will ask."
---

## Task

Prisma has detected that migrations were applied to the local database from another branch. Rather than running `prisma migrate reset` (which destroys all data), generate the exact SQL to manually revert only the foreign-branch changes — so the DB matches what the current branch's migration history expects.

Never run any mutation automatically. Present all SQL for the user to review and run manually.

---

## Steps

**1) Get the drift report**

If `{{drift}}` is provided, parse it directly.

Otherwise ask:
> "Paste the full Prisma drift output (the error starting with 'Drift detected:')."

**2) Get DB access**

If `{{db}}` is provided, use it. Otherwise ask:
> "What's your local DB connection string? (e.g. `postgresql://user:pass@localhost:5432/dbname`)"

**3) Parse the drift**

From the drift output, identify:

- **Rogue migrations** — migration files applied to the DB but absent from the current branch's `prisma/migrations/` directory. These are the migrations that need to be undone.
- **Added tables** — tables that exist in the DB but shouldn't (created by the rogue migration)
- **Added columns** — columns added to existing tables by the rogue migration
- **Added indexes** — indexes added by the rogue migration
- **Added foreign keys** — foreign keys added by the rogue migration
- **Last common migration** — the migration ID both branches share (revert target)

**4) Inspect the actual DB state**

Connect to the DB and confirm what actually exists, to avoid generating SQL for things that don't exist:

```sql
-- Confirm rogue tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name IN (<rogue table names>);

-- Confirm rogue columns exist on changed tables
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = '<table>' AND column_name IN (<rogue columns>);

-- Confirm rogue indexes exist
SELECT indexname FROM pg_indexes
WHERE schemaname = 'public' AND tablename = '<table>' AND indexname IN (<rogue indexes>);

-- Confirm rogue foreign keys exist
SELECT constraint_name FROM information_schema.table_constraints
WHERE table_schema = 'public' AND table_name = '<table>' AND constraint_type = 'FOREIGN KEY';
```

Only generate revert SQL for things confirmed to exist.

**5) Generate revert SQL**

Produce a single SQL block the user can copy-paste and run. Order matters — drop in reverse dependency order:

1. Drop foreign keys first (before indexes or columns that reference them)
2. Drop indexes
3. Drop added columns from existing tables
4. Drop added tables last

Example structure:
```sql
-- Revert: <rogue migration name>
-- Run this manually, then run: npx prisma migrate dev

BEGIN;

-- 1. Drop foreign keys
ALTER TABLE "<table>" DROP CONSTRAINT IF EXISTS "<fk_name>";

-- 2. Drop indexes
DROP INDEX IF EXISTS "<index_name>";

-- 3. Drop added columns
ALTER TABLE "<table>" DROP COLUMN IF EXISTS "<column>";

-- 4. Drop added tables
DROP TABLE IF EXISTS "<table>" CASCADE;

-- 5. Remove rogue migration record from Prisma's history
DELETE FROM "_prisma_migrations" WHERE migration_name = '<rogue_migration_name>';

COMMIT;
```

**6) Remove the rogue migration record**

The `_prisma_migrations` table tracks what Prisma thinks is applied. The rogue migration's record must be deleted so Prisma's history matches the current branch's files. Always include this as the final statement inside the transaction.

**7) Present the plan**

Show the user:

1. **What was detected** — summary of rogue migration(s) and what they added
2. **What the SQL will do** — plain-English description of each step
3. **The SQL block** — ready to copy-paste
4. **What to run after** — once the SQL succeeds:
   ```bash
   npx prisma migrate dev
   # or
   npx prisma migrate deploy
   ```

Do not run the SQL automatically. Wait for the user to confirm they've run it, then offer to verify the DB state matches expectations.

**8) Verify (optional)**

If the user confirms they ran the SQL, re-inspect the DB to confirm:
- Rogue tables are gone
- Rogue columns are gone
- Rogue indexes and FKs are gone
- `_prisma_migrations` no longer contains the rogue migration record

Then confirm it's safe to run `prisma migrate dev`.
