---
name: current-work
description: Investigate which feature or fix is currently in scope from the user's intent, repository code, working-tree changes, and Git history. Use before acting on current work or interpreting a feature, branch, PR, commit, or range; handles mixed committed/uncommitted work, imported merges, and work on main. Read-only scope discovery, not a whole-codebase audit.
---

# Current Work

Establish what the user is working on, why it matters, and which changes belong
to the request. Return a reusable scope result to the calling skill. Discovery
itself never edits code, changes Git state, starts services, or accesses data
systems. It does not authorize implementation, deployment, or other mutations.

## Resolve the intended target

Read the current request, relevant conversation, repository instructions, and
any named ticket/spec/PR. An explicit target or restriction wins over defaults.
Distinguish an explicitly requested whole branch/range from a named feature
inside that branch. An explicit whole-repository study is also valid; do not
silently narrow it to local diffs. A ticket or new feature can be in scope even
before its implementation exists.

Without an explicit target, investigate the combined active work: staged,
unstaged, and relevant untracked changes plus local topic commits not present
in the configured upstream. Include already-pushed parts of the same unfinished
feature when the user's current context and code establish that relationship;
do not automatically include every historical change on the branch.

Reuse a scope result already established in this conversation if the target and
repository state still match. Refresh it after branch changes, new edits/commits,
or user steering; stale context must not overrule the latest request.

## Collect evidence without changing the checkout

Read status, current branch/HEAD, upstream, locally available default/target
refs, staged/unstaged diffs, untracked paths, and bounded relevant history.
Read the actual patches and owning code; branch names, authors, timestamps,
and commit messages are clues, not proof of intent or ownership.

Use [Git evidence](references/git-evidence.md) for read-only command recipes and
special cases. Discover refs rather than assuming `origin/main`. For a PR, read
its real base/head and product evidence through available GitHub tools or CLI.
Do not checkout another branch to inspect it: use `git show` or remote reads.
Record whether the requested target is actually in the current working tree.

Do not fetch, stash, stage, commit, checkout, reset, rebase, merge, clean, or write
Git refs during discovery. Local remote-tracking refs can be stale: report that
limit or verify metadata with a read-only connector. Missing refs/upstream do
not justify choosing an arbitrary baseline or claiming commits are unpushed.

## Reconstruct the feature, not just a diff

Follow candidate changes through their entry points, state/data ownership,
callers, tests, types, and relevant product documentation. Read enough unchanged
code to understand the current behavior, conventions, and business outcome.
Unchanged dependencies are context; they are not additional work to modify or
test unless the requested change plausibly affects their contract.

Group changes by feature or fix using this evidence. Account for follow-up
commits, split commits, renames, deletions, fixes on top of existing work, and
uncommitted continuations. Assess scope at the hunk/behavior level when unrelated
work shares a file. Do not force independent local features into one story or
silently discard one: include each active group for a general current-work
request, and select only the requested group for a narrow target.

Separate topic work from incoming branch history. A commit absent from the
feature's upstream may simply have arrived through a merge from main. Exclude
imported changes that do not belong to the active feature; retain merge
resolutions and incoming contracts where they affect it. Conversely, a change
being on main, pushed, or made by another author does not exclude it from an
explicitly requested feature/PR or a related unfinished feature.

Keep the baseline, selected commit patches, and current working-tree contents
separate. An aggregate diff alone can obscure reordered, reverted, cherry-picked,
or partially superseded work. Confirm the final behavior in the current tree
and do not count a reverted change as delivered. Never label later changes on
the target branch as this feature's deletions just because HEAD is behind it.

## Main, missing history, and ambiguity

On `main`/`master`/the default branch, inspect dirty changes and local-only commits
against its actual upstream just as on any other branch. Do not stop merely
because the branch is main, and do not use `main...HEAD` when both refs identify
the same commit. If it is clean and synchronized, use explicit feature/commit
or ongoing-task evidence to locate the relevant completed/unfinished work.

For missing upstreams, detached HEADs, shallow repositories, ongoing merges or
rebases, and repositories without commits, use the evidence actually available.
Conflicted index stages describe competing versions, not ordinary staged work.
Preserve uncertainty where history is insufficient. If there is no identifiable
active work or competing interpretations materially change the task, ask one
specific question about the target; never fall back to auditing the entire repo.

## Reusable scope result

Return a compact result, internally to the calling skill unless the user asked
for an investigation report:

- **Intent and target:** feature/fix, business outcome, explicit vs inferred scope.
- **Repository state:** branch/HEAD, upstream/target refs, dirty/conflicted state,
  freshness limits, and whether the checkout contains the requested target.
- **Selected changes:** precise baseline/ranges or commit set, staged/unstaged/
  untracked contributions, and relevant paths/hunks or flow owners.
- **Included behavior:** user flows/contracts and evidence connecting them to the
  active work; separate independent feature groups when present.
- **Excluded/context-only work:** imported history, unrelated local work, and
  unchanged dependencies, with brief reasons where exclusion is non-obvious.
- **Uncertainty:** unresolved scope decisions or unavailable history; distinguish
  inferred intent from confirmed behavior.

Preserve the caller's task and output contract: a naming skill still outputs
only its name, a report-only skill stays read-only, and a UI-testing skill still
uses the existing server. Pass this result to downstream skills instead of
letting each rediscover or broaden the scope. Repository-required validation
may be broader than the feature; that does not expand implementation scope.
