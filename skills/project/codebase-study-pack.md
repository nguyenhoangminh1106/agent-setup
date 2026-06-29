---
description: "Create deep, low-level, navigable technical study packs for a codebase. Use when the user asks Codex to analyze a repository's advanced engineering patterns, infrastructure, architecture, unique product features, performance optimizations, state/concurrency behavior, error handling, or critical workflows, especially when they want exact files, functions, structures, line citations, code snippets, and output written as folders/subfolders such as infra-wise and feature-wise study documents."
---

# Codebase Study Pack

Produce rigorous codebase study packs for experienced engineers. Optimize for concrete implementation detail, exact citations, and navigable artifacts rather than summaries.

## Workflow

1. Confirm the target repository from `cwd` unless the user names another repo.
2. Infer the output location from the request. If unspecified, write under `~/Downloads/<repo>_codebase_study_pack`; if filesystem permissions block this, stage in `/private/tmp` and request approval to copy.
   - If the requested or default output folder already exists, reuse it as the working study pack.
   - Do not delete or restart the existing folder unless the user explicitly asks.
   - Read the existing pack first, then refresh it from a fresh codebase scan.
   - Preserve useful existing structure and add new files or sections for newly discovered systems, changed paths, or deeper evidence.
3. Build a code map before writing:
   - list top-level directories with `find` or `rg --files`;
   - inspect architecture docs such as `AGENTS.md`, `CLAUDE.md`, `README.md`, `docs/`;
   - use `rg` to find routers/controllers, services, repositories, stores, workers, queues, state machines, caches, providers, and feature domains.
4. When updating an existing pack, build both maps:
   - existing artifact map: `find <folder> -maxdepth 3 -type f | sort`;
   - fresh code map: current repository files, docs, and domain searches.
5. Compare the existing pack against the fresh code map. Add coverage for important new subsystems and update stale citations, paths, reading order, file counts, and feature rankings.
6. Read exact file slices with line numbers using `nl -ba <file> | sed -n '<start>,<end>p'`.
7. Choose both infrastructure-wise and feature-wise topics unless the user asks for only one.
8. Write one parent folder with subfolders, never separate top-level packs:
   - `README.md`
   - `infrastructure/`
   - `features/`
9. Cite every substantive claim with exact file path, function/type name, and line range.
10. Include short code snippets only where they prove a claim or make a pattern easier to study.
11. Verify final structure with `find <folder> -maxdepth 3 -type f | sort` and `wc -l`.

## Output Standard

Write for a principal engineer. Do not explain basic framework concepts. Focus on:

- concrete abstractions and decoupling boundaries;
- dependency wiring and runtime execution paths;
- state transitions, concurrency, memory, cache, and pooling choices;
- advanced idioms and design patterns;
- error handling, retries, idempotency, partial failure, and boundary conditions;
- critical path traces from entrypoint to persistence or side effect;
- feature systems that are unique, product-specific, or unusually worth learning.

Prefer many medium-depth files over one huge document. Use stable filenames with numeric prefixes.

## Folder Shape

Read `references/study-pack-structure.md` when creating the artifact, selecting topics, or deciding how deep each file should go.
When an existing study pack is present, also use that reference to decide whether to keep, split, rename, or extend existing files.

The default shape:

```txt
<repo>_codebase_study_pack/
  README.md
  infrastructure/
    README.md
    00_scope_and_reading_order.md
    01_<topic>.md
    ...
  features/
    README.md
    00_ranked_feature_map.md
    01_<feature>.md
    ...
```

## Topic Selection

For infrastructure docs, prioritize:

- API/auth boundary;
- domain/service/repository/store boundaries;
- database access and generated layers;
- queue/task/workers;
- state machines;
- caches/provider abstraction;
- high-throughput or critical-path flows.

For feature docs, prioritize code that teaches something domain-specific:

- ranking/matching/search systems;
- workflow state machines;
- multi-persona messaging/collaboration;
- complex data ingestion/enrichment;
- high-density UI engines;
- agentic workflows bound to domain tools;
- operational automation with business rules.

## Citation Rules

Use absolute paths in generated documents when possible. Each section should name:

- file path;
- function, class, type, constant, or SQL query;
- line range;
- why that code matters.

Avoid claims like "uses caching" without pointing to the cache key, invalidation path, read/write function, or freshness guard.

## Writing Style

Be direct and technical. Avoid generic "overview" filler. Each file should answer:

- what problem this code solves;
- where the important code lives;
- how the execution path works;
- what invariants or tradeoffs are encoded;
- what an experienced engineer should learn from it.
