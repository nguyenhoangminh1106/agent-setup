---
name: ui-polish
description: Revamp and clean up the UI of in-progress frontend work so it looks finished, clean, and consistent with the rest of the app — spacing, padding, alignment, typography, color, borders, radius, states, responsive and dark-mode details — fixing confirmed UI issues directly and verifying the result. Scope is limited to active work established by current-work or a target the user names, never the whole codebase. Use this whenever the user asks to polish, clean up, tidy, revamp, beautify, make consistent, or "make the UI look good/right/professional" for what they're working on, says the spacing/padding/fonts look off, or asks for a design pass on their branch, PR, screen, or component — even if they don't say "polish".
---

# UI polish

Make the frontend in scope look deliberate and consistent with the product.
By default, fix confirmed UI issues directly, inspect the complete scoped change,
and verify the result before reporting. Do not stop at an audit, suggestions,
or a list of fixes the user must request again. Stay read-only only when the
user explicitly asks for findings only, planning only, or no edits.

## 1. Load design guidance first

Read the available `frontend-design:frontend-design` skill instructions before
touching any file. It sets the bar for visual quality. If the repository has its
own frontend conventions skill or doc (for example a `frontend-conventions`
skill, `AGENTS.md`, `CLAUDE.md`, or a design-system README), read that too.

One tension to resolve: `frontend-design` encourages distinctive aesthetics, but
this is an existing product. Here, quality means fitting the established design
system precisely and raising the craft within it. Do not introduce a new visual
language, font, palette, or component library unless the user asks.

## 2. Resolve the scope

Use [current-work](../current-work/SKILL.md) to establish the requested feature
or explicit target, its actual baseline/selected changes, and relevant local
contributions. Reuse its scope result when still current. Pass the user's task
and any named file, component, route, screen, PR, branch, or commit range;
without a target, use the active work it identifies, including work on main.
Do not independently choose an upstream/default-branch comparison or include
unrelated imported history. Retain the result's exclusions and uncertainty.

Apply the UI repair limits below to that scope. A shared file does not
make its unrelated hunks eligible for polishing. Read unchanged owners and
nearby screens as design context without expanding the edit scope. Pass the
same scope result to supporting skills if they need feature context.

Keep only frontend files: components and pages (`.tsx`, `.jsx`, `.vue`,
`.svelte`, `.astro`, `.html`), styles (`.css`, `.scss`, `.module.css`), and
style config that the work itself already edited. Within each file, focus on the
regions the work changed and the UI they render; leave unrelated parts of a
large file alone.

If the scope is empty or contains no frontend files, say so and stop rather than
widening the search. Tell the user the file list you settled on before editing
so they can correct it.

If a shared component or token causes a confirmed issue in the scoped UI,
inspect its consumers and make the smallest necessary repair at the appropriate
owner. Check affected consumers before finishing. Do not use this exception to
redesign unrelated screens or broadly change shared tokens.

## 3. Learn the design system before judging

Consistency is measured against the app, so look at it first:

- Tokens: Tailwind config / CSS variables / theme file — spacing scale, type
  scale, font weights, colors, radii, shadows, breakpoints.
- Primitives: the shared `Button`, `Input`, `Card`, `Dialog`, typography
  components, icon set and its standard sizes.
- Two or three mature, polished screens near the one in scope. Note how they
  space sections, size headings, align labels, pad containers, and handle empty
  and loading states. These are the reference.

## 4. Audit, then fix

Go through the scope with this lens. The goal is a calm, consistent, intentional
result — every value should come from the system and every difference in size
or spacing should mean something.

- **Spacing and rhythm**: values on the scale, no arbitrary `px` or one-off
  `mt-[13px]`; consistent gaps between siblings (prefer `gap`/`space-*` on the
  parent over margins on children); section spacing larger than item spacing;
  matching padding in sibling containers.
- **Alignment and layout**: shared left edges, baselines aligned, icons
  vertically centered with text, no accidental full-width or cramped elements,
  sensible max widths for text.
- **Typography**: a clear hierarchy using the type scale and a small set of
  weights; consistent heading sizes for the same level across the screen;
  line-height and truncation for long content; muted color for secondary text
  from tokens.
- **Color and surfaces**: tokens instead of hex/raw palette colors; consistent
  borders, radii, and shadows per element type; enough contrast; dark mode
  works if the app supports it.
- **Components**: use the existing primitives and variants the rest of the app
  uses for the same job; consistent icon sizes and stroke.
- **States**: hover, focus-visible, active, disabled, loading, empty, and error
  look right and remain usable. Repair missing UI feedback when the existing
  data and behavior already support it.
- **Responsive**: no horizontal overflow, sensible wrapping, touch targets of
  reasonable size on mobile widths.
- **Details**: no double borders, orphaned dividers, inconsistent corner radii
  between nested elements, stray z-index or overflow hacks that clip content.

Prefer fewer, cleaner class lists over stacking overrides. Removing redundant
styling is as valuable as adding it.

## 5. Fix the UI with the smallest necessary change

Prefer presentation changes: classes, styles, layout wrappers, style variants,
and existing primitives. Preserve working interactions and business behavior.

When a confirmed UI defect needs a small companion change, make it directly:
for example, correct misleading or misspelled UI copy, repair accessible names
or keyboard controls, fix focus handling, or adjust a local interaction that
causes the visual defect. Do not leave an issue unfixed merely because the
repair touches ARIA attributes, markup, props, handlers, or local state.
Check the affected behavior and add meaningful regression coverage when needed.

Keep these repairs tied to the scoped UI. Do not change backend contracts,
product rules, routes, analytics, or unrelated feature behavior as part of
polish. If a finding requires a real product decision or work beyond this scope,
complete independent fixes first and report the specific remaining blocker.

## 6. Verify

1. Re-read the complete scoped diff, including existing changes and your
   repairs. Confirm every edit addresses the scoped UI and preserves intended
   behavior. Fix any remaining confirmed UI defects before finishing.
2. Run the repo's format/lint/typecheck for the touched files (for example
   `pnpm run check -- <files>` if the repo documents it).
3. Use the available local app to inspect the result in a browser — desktop
   and a mobile width, light and dark if supported. Exercise affected states
   and interactions, fix observed defects, and recheck after repairs. Follow
   repository rules for running tests and starting services; do not create or
   run E2E tests without required authorization. If browser verification is
   unavailable, state that limitation rather than claiming a visual pass.
   If missing test records prevent inspecting a scoped state, use
   [seed-data](../seed-data/SKILL.md) with that state and test environment,
   following its setup/cleanup rules. Keep findings-only work in plan mode;
   fixture setup does not expand frontend repair scope or authorize services.

## 7. Report

Keep it short:

- **Scope**: the files you worked on.
- **Changes**: grouped by file, one line each, in plain terms ("aligned card
  padding to the list-item spacing used in Inbox", not class names).
- **Verification**: check results, affected behavior tested, and whether you
  viewed it in a browser.
- **Remaining blockers**, only if any: the specific unresolved issue and why it
  requires a product decision, additional access, or work outside the scope.

Report completed fixes, not a proposed to-do list. If no repairs were needed,
say so and describe what you checked.
