---
name: review-rebuild
description: Review, repair, and verify an existing feature in current work or an explicitly named issue, PR, branch, commit, or range. Fix confirmed issues directly and check the complete scoped change by default; stay read-only only when the user explicitly requests findings only, planning only, or no edits.
---

# Review and Rebuild

Treat the existing work as evidence of a product brief whose implementation must earn its place. Establish the intended outcome and assess the actual feature, whether it lives in local edits, commits, or a PR. For an authorized rebuild, preserve that outcome while replacing any or all of the scoped implementation when justified. The goal is a correct, maintainable feature that belongs in the receiving codebase.

## Choose the requested mode

- **Default — review, fix, and verify:** invoking this skill, including with only an issue/PR link or a request to review, means investigate the implementation, fix confirmed issues within scope, and verify the complete scoped change. Choose repair, partial replacement, or complete replacement based on evidence. Do not stop at findings in chat or ask whether to implement routine fixes.
- **Explicit read-only or planning:** when the user says review only, findings only, plan only, do not edit, or otherwise clearly limits the task to analysis, investigate and report without editing files, staging, committing, or running mutating checks.

Use the latest user instruction to choose the mode. This default applies to work requested through this skill; it does not authorize edits in unrelated review tasks. Rebuilding is permission to replace feature code, not a requirement to rewrite sound code. Execution permissions and authorization for external actions remain unchanged.

Do not infer code quality from the author's technical background. Inspect the actual implementation. Neither the existing diff nor its tests establish correctness by themselves.

## Establish intent and the baseline

Use [current-work](../current-work/SKILL.md) with the user's current task or explicit target to establish feature intent, actual baseline/commit set, and relevant local contributions. Reuse and pass its scope result; preserve unrelated working-tree changes. Without an explicit target, include the active committed and uncommitted work it identifies, including work on main, while excluding unrelated imported history.

Read the request, ticket/spec, relevant discussion, screenshots or demos, selected patches, and current owning code. A PR is optional. When one is named, read its actual base/head, description and full relevant diff through available GitHub tools or `gh pr view` / `gh pr diff`; attach it to the chat when supported. Confirm whether the current checkout contains that target before testing or changing it.

Separate three things:

- **Product intent:** the user problem, audience, key interactions, and expected outcomes supported by the request and feature evidence.
- **Implementation choices:** implementation, dependencies, schema, abstractions, mock data, and incidental visual choices that may be discarded.
- **Existing contracts:** correct behavior on the target branch, authorization and tenant boundaries, API consumers, persisted data, integrations, and established product conventions.

Inspect the receiving codebase at the discovered baseline as well as the selected work. Find the owning modules and existing patterns before adopting the prototype's architecture. For an already merged PR, account for subsequent changes and current consumers rather than treating everything it added as disposable.

Summarize the intended behavior and a short set of observable acceptance criteria before implementing. Label assumptions and resolve conflicting requirements from the user's instructions and reliable product evidence. Ask only when a missing decision materially changes the intended outcome; continue independent work while awaiting it. Do not reproduce a prototype bug as a requirement or silently drop a demonstrated interaction.

Only an explicit read-only or planning constraint ends at a report. Otherwise, carry confirmed findings through implementation and verification within the established feature scope.

## Decide what earns reuse

Audit the feature path from UI or entry point through validation, authorization, services, storage, and response. Focus on defects that affect this feature: disconnected UI, mock-only success, unsafe access, incomplete states, duplicate sources of truth, broken integration boundaries, fragile concurrency, unnecessary dependencies, and behavior tests that prove little.

In explicit read-only mode, assess what should be retained, repaired, or replaced and explain the evidence. In the default implementation mode, make that choice and implement it based on correctness and fit. Do not retain a poor abstraction merely to keep the diff small. Conversely, do not rewrite sound code just because the prototype was AI-generated.

For implementation, state the direction briefly, including what is retained and replaced and why. Proceed without asking for approval of routine engineering choices. Complete replacement means rebuilding the requested feature, not rewriting the surrounding application, changing the product brief, or replacing the project's stack.

Preserve unrelated user changes. For implementation, use an isolated checkout when needed, following the repository's worktree and branch conventions. Keep existing local work and any original PR/commits recoverable; do not use destructive resets or force pushes as a shortcut to discarding feature code.

## Supporting skills

Read the relevant supporting skill when available. Use the session's skill catalog to locate it; these are separate skills, not instructions to copy into this one.

- **minimal-coding:** apply architecture boundaries, local ownership, reuse, type safety, and concise implementation. Its minimal-diff preference does not require preserving the prototype implementation: an authorized rebuild permits feature replacement. Keep the replacement bounded to the intended feature and avoid unrelated refactors. Preserve its migration and database code-generation restrictions unless higher-priority instructions explicitly override them.
- **[seed-data](../seed-data/SKILL.md):** use when verification needs missing synthetic records in a designated test environment. Pass the scoped scenario and existing test boundaries; use execute mode only within authorized testing, and plan mode for read-only reviews. Reuse existing per-test fixtures rather than replacing them. Seeding does not authorize services, migrations, or live provider effects.
- **clean-ai-comments:** in implementation mode, use on the final feature diff, compared with the actual target baseline, to remove noisy comments introduced by the work. Keep useful rationale, gotchas, directives, and comments that existed in the baseline. Comment-only cleanup must not alter logic; rebuilding logic is a separate implementation action.
- **[frontend-design:frontend-design](../frontend-design/SKILL.md):** use for visual design review and when building or reshaping UI within the requested feature. Read the real brief and existing brand/content; apply its design planning and critique process when design changes are authorized. In explicit read-only mode, assess the existing UI and report findings without redesigning it. For an established product, its brand, components, typography, and frontend conventions are the brief's constraints; reuse them rather than imposing a new identity. Permission to rebuild implementation does not itself authorize changing branding, routes, legal copy, or product requirements.

If a supporting skill is unavailable, continue using the principles above and disclose any material limitation. Do not install skills or new design systems solely because this workflow mentions them.

## Build the intended feature (implementation mode)

Implement against the receiving project's established layers, types, UI primitives, and permission model. Replace fake data and placeholder actions with the real feature path where the brief requires it. Include meaningful loading, empty, error, and success behavior for interactive flows.

Remove abandoned prototype code and dependencies introduced solely for it when their callers are gone. Check callers before deleting or changing interfaces. Keep valuable existing behavior and tests; remove or replace tautological tests and assertions tied to incidental implementation structure in the feature's scope.

Do not edit a merged migration or assume an unmerged migration has never run. Follow repository migration and compatibility rules. Rebuilding code does not authorize destructive data changes, production operations, publishing, merging, or messaging the author. Follow the user's actual authorization for those actions.

## Verify the product contract

Derive verification from the acceptance criteria and real failure risks, not the prototype's test coverage. In implementation mode, add or improve tests for observable behavior and meaningful contracts where they add confidence. In explicit read-only mode, inspect existing tests and use non-mutating checks; report coverage gaps without writing tests or fixing findings. Exercise the actual path across relevant boundaries; mocked unit success alone does not establish that a UI reaches a working API or that an integration persists the right data.

For UI changes, inspect the running feature and exercise the main interactions, relevant states, keyboard behavior, and mobile layouts. For backend changes, verify the relevant permissions, validation, persistence, failures, and retry or concurrency behavior when applicable. Use local or staging environments under repository rules.

For implementation, check the complete scoped change against its actual target baseline, including existing feature commits and staged, unstaged, and new files—not just the lines repaired during this run. Review the integrated behavior and direct consumers, especially after merges, while excluding unrelated incoming history and user work.

Run required repository formatting and lint for all files in that scoped change, all required workspace typechecks, and affected tests. Respect repository limits such as E2E opt-in; a request to check all changes does not override them. Repair findings as required by the repository, rerun the affected checks after fixes, and inspect the final diff for regressions, accidental scope growth, and leftover prototype artifacts. Continue until confirmed in-scope issues are fixed and checks pass, or a concrete blocker prevents further work. Do not leave a known actionable issue as a chat finding when it can be fixed within the authorized scope.

For explicit read-only requests, avoid auto-formatters and checks that rewrite files, and report any required validation that cannot be completed without edits.

Never claim verification that was not performed. If an environment, credential, or command prevents a required check, explain the exact gap and its effect; distinguish implemented work from verified work.

## Deliver the requested result

For explicit read-only requests, lead with actionable findings ordered by severity, with precise file/line evidence, affected behavior, and a proposed correction where useful. Distinguish confirmed defects from assumptions and verification gaps. State explicitly when no actionable findings were found, without claiming unperformed verification. Do not present a planned fix as implemented.

For the default implementation mode, lead with the fixes completed and the verification result. Report the intended behavior now delivered, any substantial implementation choices replaced, the checks actually performed, and any remaining blocker, limitation, or product decision. A findings-only response is incomplete unless the user explicitly requested read-only work or a concrete blocker prevented a fix. Give concrete UI testing steps when the feature has a user-facing flow.

Update a PR or create a replacement PR when authorized by the request and repository workflow; attach any resulting PR when supported. Describe the final implementation and validation so a reviewer can assess it without knowing this conversation. Do not disparage the author or narrate discarded approaches unless they explain a material tradeoff.
