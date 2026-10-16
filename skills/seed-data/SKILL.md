---
name: seed-data
description: Prepare, create, verify, and clean up scoped synthetic test data for local development, UI testing, or bug reproduction. Use when required test records are missing. Excludes production data repair, migrations, broad database resets, and ordinary fixtures already managed by a test suite.
---

# Seed test data

Make the smallest realistic data setup needed for the requested test, using the current project's schema and conventions. This skill owns fixture planning, creation, verification, and cleanup; it does not own application fixes, service setup, or live provider actions.

## Choose the mode and establish scope

- **Plan:** For walkthroughs, reports, investigations, or explicit read-only requests, return a concrete setup and cleanup plan without changing data or running a seeder. A database URL alone does not authorize writes.
- **Execute:** A request to seed data authorizes the scoped fixture setup. When an execution workflow such as ui-test requests missing fixtures for an authorized local test, proceed with the minimum required synthetic data in the verified designated test environment, unless the user restricted writes. Do not ask again for setup already covered by that authorization. If the target or permission is unclear, finish the reviewable plan and ask only for the missing decision.
- **Cleanup:** Remove this run's disposable data or conditionally restore its recorded changes. Reuse the original run's manifest rather than guessing records from names.

Reuse the caller's feature scope, acceptance criteria, environment, and test identities. Otherwise read the relevant repository instructions, owning code, schema, and fixture conventions. Do not broaden a named feature into a database-wide seeding task. Reuse existing safe records when they already cover the required state.

## Verify the target before writes

For SQL discovery and verification, reuse [query-db](../query-db/SKILL.md)
when available, passing only the narrow read-only question, test scope, and
verified access constraints. Keep fixture writes and cleanup in seed-data;
do not pass the parent seeding task back to query-db. For non-SQL stores,
use their project-owned read interface.

Confirm the actual database or datastore identity and the designated test tenant/account using repository configuration and read-only checks. Use supplied access or documented project tooling; do not guess credentials or store them in artifacts. A localhost URL may be a tunnel to production, and a local frontend may use a remote backend. Establish that fixtures will land in the datastore used by the test target.

Create fixtures only in a verified non-production environment for designated test identities. A shared staging database needs explicit authorization for the concrete target and changes; local-test authorization does not cover it. Do not copy private production payloads or modify real-user records. Keep production investigations and read-only callers in plan mode. Missing access, schema, services, or an unverified target is a setup gap, not permission to change configuration.

Do not start or restart services, bootstrap, install dependencies, change environment files, create accounts through a real provider, run migrations, reset/truncate databases, or run broad seed commands. Inspect an existing fixture helper or targeted seeder before reusing it: it must stay within this scope and have no hidden bootstrap, reset, migration, or external-delivery effects. Stop when those constraints cannot be met.

## Prepare fixtures and a recovery record

Prefer the project's existing domain helpers or focused fixture commands; use parameterized datastore operations or bounded SQL when appropriate. Preserve tenant ownership, foreign keys, constraints, status transitions, and derived state required by the owning code. For a regression, recreate the relevant bad state rather than sanitizing it away. Do not bypass validations or disable constraints to make an insert succeed.

Before writing, record a credential-free run manifest outside application source unless a reusable repo fixture was requested. Include the target identity, scope, test account/tenant, a unique run marker, exact new IDs, reused IDs, expected states, setup operations, verification queries, and cleanup operations. Capture the original values of any existing disposable records that must change. Prefer new records over editing shared seed rows.

Make retries bounded and safe: reuse this run's exact IDs or a scoped natural key, reject collisions with unrelated rows, and never upsert over a record merely because its label matches. If a previous run or test has changed the expected setup, inspect it rather than silently resetting it. Use a transaction for database setup where supported; for multi-system setup, record each completed operation and its compensation. On partial failure, inspect what actually persisted before retrying.

## Execute and verify the intended state

In execute mode, perform the scoped setup and verify the persisted relationships and values with read-only checks. Return exact IDs, unique test labels, account/tenant, and app links where derivable so the caller can run its walkthrough without guessing. In plan mode, clearly label artifacts as not executed and identify schema or access assumptions.

Separate fixture setup from the behavior being tested. Inserting a row may not run ingestion, classification, queues, webhooks, notifications, or provider sync. Identify the real trigger needed next and whether the existing test boundary supports it. Do not manually stamp the expected final state or call a direct API/SQL mutation in place of a UI action whose behavior is under test.

Inspect triggers, outboxes, background consumers, and provider integrations before committing fixtures. Use an established mock or isolated test boundary for external effects; never change global configuration to invent one. Live sends, remote pushes, payments, or provider changes require the caller's authorization for their concrete test targets. Do not enqueue work that can reach real users. A seeded record or generated payload is not proof of UI rendering, email receipt, or remote-push delivery; missing device/provider capabilities remain separate gaps.

## Cleanup and handoff

Coordinate fixture lifetime with the caller. After testing, clean up run-owned disposable records unless the user requested they remain for manual inspection. Do not delete fixtures while a downstream walkthrough still needs them. In a standalone seeding request, leave the requested fixtures available and provide their cleanup command.

Clean up by recorded IDs and tenant scope in dependency order; check cascades and refuse deletion if unrelated data now depends on the fixtures. Restore pre-existing records only if their current values still match this run's expected changes, so concurrent edits are not overwritten. Verify cleanup and report any remaining records, pending jobs, or artifacts. Cleanup must not retract already-sent external effects or purge unrelated logs/history.

Report briefly: mode and execution status, verified target without credentials, records created/reused/changed, verification results, exact next test trigger, and cleanup status or instructions. Pass this handoff to the calling skill. Do not present seeded data as an end-to-end test pass.
