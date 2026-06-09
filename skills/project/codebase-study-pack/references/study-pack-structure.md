# Study Pack Structure

Use this reference when creating a navigable deep-dive artifact.

## Top-Level README

Include:

- one-sentence purpose;
- folder layout;
- best reading path that mixes feature and infrastructure files;
- distinction between `infrastructure/` and `features/`;
- total file/line count after verification.

## Infrastructure Files

Recommended files:

1. `00_scope_and_reading_order.md`
   - repository scope;
   - files inspected;
   - what was intentionally excluded;
   - reading order.
2. `01_api_boundary_and_auth.md`
   - routers/controllers;
   - auth checks;
   - validation;
   - output schemas;
   - dependency handoff into services.
3. `02_domain_data_boundaries.md`
   - services;
   - repositories;
   - stores;
   - generated descriptors/delegates;
   - dependency inversion or store authorization.
4. `03_state_concurrency_memory.md`
   - state machines;
   - locks, atomics, queues, maps, channels;
   - cache layout;
   - batching and chunking;
   - allocation-sensitive paths.
5. `04_resilience_error_boundaries.md`
   - typed errors;
   - retry/backoff;
   - idempotency keys;
   - guarded writes;
   - partial-failure strategy.
6. `05_critical_path_trace.md`
   - one or two most complex workflows;
   - function-by-function data path;
   - persistence and side effects;
   - micro-optimizations.
7. `06_cross_cutting_patterns.md`
   - advanced idioms;
   - repeated architectural motifs;
   - tradeoffs and risks.

Adapt names to the actual repo. For a large repo, split one file per concrete subsystem.

## Feature Files

Recommended files:

1. `00_ranked_feature_map.md`
   - top features worth studying;
   - why each is unique;
   - exact files/functions to start with.
2. `01_<feature>.md`
   - one file per feature system.

Each feature file should include:

- core files;
- why it is worth learning;
- entrypoints;
- data model or state model;
- execution trace;
- important invariants;
- code snippets with line ranges;
- lessons an experienced engineer can reuse.

## Depth Heuristics

Go deeper when:

- the code spans multiple layers;
- the feature encodes domain policy;
- the path includes side effects or external systems;
- concurrent updates or retries matter;
- performance is a stated or implied concern;
- the implementation uses generated code, generic types, workers, caches, or state machines.

Stay lighter when:

- code is mostly boilerplate;
- code is conventional framework glue;
- the feature is interesting but the inspected evidence is thin.

## Research Commands

Use these patterns:

```sh
rg --files
find . -maxdepth 3 -type f | sort
rg -n "class|interface|type .*Service|Repository|StateMachine|transition|Queue|cache|retry|backoff|mutex|lock|worker|pool|provider|router|procedure" .
nl -ba <file> | sed -n '<start>,<end>p'
wc -l <folder>/**/*.md
```

For TypeScript/Next/tRPC-style repos, search:

```sh
rg -n "createTRPCRouter|protectedProcedure|assertTrpcGuardianChecks|\\.output\\(|TRPCError|prisma|read_only_prisma|QueueService|createTask|StateMachine|zustand|Comlink|worker|IndexedDB|pgvector|\\$queryRaw" .
```

For feature discovery, search product nouns:

```sh
rg -n "matching|ranking|message|inbox|candidate|role|workflow|submission|approval|staleness|onboarding|agent|assistant|embedding|search|score|priority" .
```

## Quality Bar

Reject shallow output. A valid section should usually include at least one of:

- a concrete code snippet;
- an execution trace;
- a data/state structure;
- a SQL/query path;
- a concurrency/resilience explanation;
- an explicit tradeoff.

If a section cannot cite exact code, mark it as an inference and explain what evidence supports it.
