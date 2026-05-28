---
description: "Minimal-diff coding guardrails for codebase-consistent implementation. Use when Codex is editing, reviewing, planning, or debugging code, especially in the Paraform repo or similar TypeScript, React, Next.js, tRPC, Prisma, service/repository, UI, warning, validation, or behavior-fix work."
---

# Minimal Coding

## Core Posture

Prioritize minimal diff changes unless a larger change is clearly necessary. Inspect and reuse existing codebase patterns, components, helpers, services, repositories, types, utilities, warning channels, and data flows before adding anything new.

Prefer the smallest local guard inside the owning component when it already has the needed context. Add props, plumbing, abstractions, or files only when the current owner cannot reliably decide the behavior itself.

Do not break existing correct logic, touch unrelated code, or change behavior unless the request explicitly requires it. For bug fixes, learn from the surrounding code first and keep the diff narrow.

## Implementation Guidelines

Reuse existing abstractions when they fit and are not deprecated. Avoid no-op wrappers that only pass arguments through unchanged. Extract helper logic only when it is reused, large, complex, or clearly worth abstracting.

Treat each new file as a cost. Keep feature-specific helpers close to the owning component or module; use the closest existing shared owner for shared constants, field keys, warning keys, magic strings, parsing, mapping, and generic utility code.

Route Prisma/database access through the service/repository layer. Repository methods must live in the repository for the Prisma table they directly query, not the service/domain that happens to call them.

Do not run migrations or generate migration files. Ignore migration-related errors; Minh handles migrations.

## Type Safety

Reuse existing types whenever possible. Add new types only when needed; keep one-off types inline when clear, and move reusable types to a clear shared or context-specific owner.

Prefer database enums over similar new enums. Avoid impossible fallbacks for typed finite keys, enums, and constants; if TypeScript guarantees the value exists, do not add `return null`, `?? fallback`, or silent skips unless real runtime data can violate it.

Avoid casts or type assertions just to satisfy a local helper API. Shape the data so TypeScript can verify it. When multiple UI paths share ids, labels, ordering, or defaults, define one source of truth and derive the rest.

## React And UI

Keep UI consistent with Paraform's existing product experience. Reuse existing UI components and local patterns before creating new components or props.

Do not use `useMemo` for cheap JSX or simple object/array creation unless identity stability matters for a child component, hook dependency, or expensive computation. Helpers referenced inside memoized values should be stable module-level functions or included in dependencies.

Prefer simplifying awkward code over adding comments explaining why it is awkward.

## Comments

Only add comments for non-obvious business logic, complex decisions, important warnings, or TODOs with context. Do not comment obvious or self-documenting code.

## Validation

After editing code, run formatting and checks that match the touched files:

```bash
pnpm exec eslint --fix <files>
pnpm exec prettier --write <files>
pnpm run typecheck:affected
```

Use `pnpm run typecheck:affected -- --no-dependents` only when speed matters more than catching caller breakage. If a tRPC router handler return shape changes, run the router output codemod and commit the regenerated sister file:

```bash
pnpm codemod:add-trpc-output --router=<name>
```
