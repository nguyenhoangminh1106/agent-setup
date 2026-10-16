---
name: minimal-coding
description: "General minimal-diff coding guardrails for codebase-consistent implementation, review, planning, and debugging. Use when Codex is changing or reasoning about code and should preserve existing behavior, reuse local patterns, respect project-specific architecture, avoid unnecessary abstractions or files, and run only the smallest relevant validation."
---

# Minimal Coding

## Purpose And Authority

Use this skill to keep code changes small, local, and consistent with the existing project. This skill is a general guardrail, not a replacement for repository-specific instructions, framework-specific standards, review workflows, generated-file contracts, or the user's current request.

When this skill conflicts with a more specific authority, follow the more specific authority and keep the diff as small as that authority allows.

## Before Editing

Apply [current-work](../current-work/SKILL.md) to establish the requested feature/fix, included changes, and relevant ownership before implementation or review. Reuse its scope result when still current. Preserve pre-existing user changes and context-only dependencies; this skill does not expand the discovered scope.

Look for nearby patterns, helpers, types, components, tests, warnings, validation, and data flows before adding anything new.

## Implementation

Reuse existing abstractions when they fit and are not deprecated. Avoid no-op wrappers that only pass arguments through unchanged. Extract helper logic only when it is reused, large, complex, or clearly worth abstracting.

Prefer the smallest local guard inside the owner that already has the needed context. Add props, plumbing, abstractions, or files only when the current owner cannot reliably decide the behavior itself.

Treat each new file as a cost. Keep feature-specific helpers close to the owning component or module; use the closest existing shared owner for shared constants, field keys, warning keys, magic strings, parsing, mapping, and generic utility code.

Do not break existing correct logic, touch unrelated code, or change behavior unless the request requires it. For bug fixes, learn from the surrounding code first and keep the diff narrow.

## Boundaries And Generated Work

Respect the project's existing architecture boundaries. Route database, network, filesystem, and external-service access through the established layer for that project.

Do not bypass service, repository, store, client/server, authorization, or integration boundaries just to make a local fix shorter.

Do not create migrations, regenerate large artifacts, update lockfiles, or make destructive data/schema changes unless the user asked for it or the active project instructions require it.

Never run database migration or database code-generation commands, including Prisma migration or generate commands. Leave those commands for the user to run manually, and state when they are needed.

When generated files, migrations, or lockfiles appear necessary, verify the project's workflow first and report exactly what was run or intentionally skipped.

## Type Safety

Reuse existing types whenever possible. Add new types only when needed; keep one-off types inline when clear, and move reusable types to a clear shared or context-specific owner.

Prefer database enums over similar new enums. Avoid impossible fallbacks for typed finite keys, enums, and constants; if TypeScript guarantees the value exists, do not add `return null`, `?? fallback`, or silent skips unless real runtime data can violate it.

Avoid casts or type assertions just to satisfy a local helper API. Shape the data so TypeScript can verify it. When multiple UI paths share ids, labels, ordering, or defaults, define one source of truth and derive the rest.

## UI

When changing UI, match the existing product experience. Reuse existing components, tokens, accessibility patterns, and interaction conventions before creating new components or props.

Do not use `useMemo` for cheap JSX or simple object/array creation unless identity stability matters for a child component, hook dependency, or expensive computation. Helpers referenced inside memoized values should be stable module-level functions or included in dependencies.

Prefer simplifying awkward code over adding comments explaining why it is awkward.

## Comments

Only add concise comments explaining why a non-obvious choice was made, real gotchas or side effects, or TODOs with useful context. Prefer clear code over comments explaining how it works.

When edits are authorized, apply [clean-ai-comments](../clean-ai-comments/SKILL.md)
to the final scoped diff. Reuse the current-work result; do not repeat cleanup
already completed unless that diff changed. In read-only reviews, assess
comments without editing. That skill owns the detailed cleanup rules, including
preserving pre-existing lines and separating comment cleanup from logic changes.

## Validation

After editing code, run the smallest relevant formatter, linter, type checker, tests, or build checks for the touched files. Do not run database migrations or database code generation; tell the user to run any required commands manually.

Prefer project-owned commands over invented checks. If checks cannot be run, report the exact reason and residual risk.
