---
description: "When Prisma detects schema drift from migrations run on another branch, generate the manual SQL to revert those changes so you can run migrations cleanly on the current branch."
arguments:
  - name: drift
    description: "Paste the full Prisma drift error output. If omitted, the skill will ask you to paste it."
---

## Task

Prisma has detected that migrations were applied to the local database from another branch. Rather than running `prisma migrate reset` (which destroys all data), generate the exact SQL to manually revert only the foreign-branch changes — so the DB matches what the current branch's migration history expects.

Do not query the DB directly. Parse the drift report alone to generate the revert SQL, then return it in chat for the user to run manually.

---

## Steps

**1) Get the drift report**

If `{{drift}}` is provided, parse it directly.

Otherwise ask:
> "Paste the full Prisma drift output (the error starting with 'Drift detected:')."

**2) Parse the drift**

From the drift output, identify:

- **Rogue migrations** — migration files applied to the DB but absent from the current branch's `prisma/migrations/` directory. These are the migrations that need to be undone.
- **Added tables** — tables that exist in the DB but shouldn't (created by the rogue migration)
- **Added columns** — columns added to existing tables by the rogue migration
- **Added indexes** — indexes added by the rogue migration
- **Added foreign keys** — foreign keys added by the rogue migration
- **Last common migration** — the migration ID both branches share (revert target)

**3) Generate revert SQL**

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

**4) Remove the rogue migration record**

The `_prisma_migrations` table tracks what Prisma thinks is applied. The rogue migration's record must be deleted so Prisma's history matches the current branch's files. Always include this as the final statement inside the transaction.

**5) Present the plan**

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

Return the SQL in chat — do not run it. The user will copy-paste and run it themselves.
