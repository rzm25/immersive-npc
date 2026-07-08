# Branch plan

Branch: `main` (repo created empty for this project). v1 = Phases 1–6 of the spec,
delivered as a single coherent build. The frozen, itemised plan is
[PROJECT_PLAN.md](PROJECT_PLAN.md); phase status is in [PROGRESS.md](PROGRESS.md).

## Goal
Ship a complete, offline-verified v1 of the immersive NPC chat feature in pure Lua on
Eluna/ALE: six hubs, guard profiles, ~36 lines, the full scheduler/validation/emission
pipeline, GM commands, tests, and docs — ready for the owner to import + deploy + run the
in-game matrix.

## Constraints and design rules
- No worldserver core patch; no client patch (v1). Lua-only.
- Heartbeat is `CreateLuaEvent`; **never** `WORLD_EVENT_ON_UPDATE` (13).
- Zero DB queries at emission; `WorldDBQuery` only in `03`.
- No `Player`/`Creature` userdata stored across a tick — GUIDs only, resolve+validate at use.
- No equipment cache (no unequip event) — lazy scan.
- Only `INC` is global; `local` everywhere else; `luacheck` clean.
- No per-tick table/closure churn (reused scratch arrays).
- Every spec deviation → an ADR in DECISIONS.md before the change.

## Verified technical foundations
See [SOURCES.md](SOURCES.md): engine pin, all event IDs, method signatures, the GUID
model, and the ms-clock choice — each verified against the Eluna pin (S2/S3). S1 (the
owner's actual build) is UNVERIFIED and flagged for confirmation.

## Workstreams
- **A. Engine verification + pin (do first).** Locate the real engine, pin commits,
  verify every event id + method signature. *(Done — SOURCES.md, ADR-003.)*
- **B. Core logic (engine-free) + tests.** `01` config, `02` util (masks/bucket/weighted/
  placeholder), unit tests. *(Done — 66/66.)*
- **C. Runtime pipeline.** `03`–`08`: loaders, registry, tracking+scan, scheduler,
  commands, boot. *(Done.)*
- **D. Verification harnesses.** Mock-engine integration test; SQL structural checker
  (self-tested); CI. *(Done — 41/41, checker 5/5.)*
- **E. Content + SQL.** Schema, seeds (6 hubs, 6 profiles, 36 lines), verify_ids. *(Done.)*
- **F. Docs + handoff.** SOURCES/DECISIONS/PROGRESS/TESTPLAN/CONTENT_GUIDE/PROJECT_PLAN/
  README/TRUTH_SOURCES + agent-notes + /source updates. *(In progress.)*

## Build order & gates
1 verify engine → 2 config+util+unit tests (gate: tests green) → 3 loaders (gate: SQL
checker) → 4 registry → 5 tracking+scan → 6 scheduler+emission (gate: integration harness
green) → 7 commands+boot → 8 content → 9 docs + review. Each gate was met before moving on.

## Risks & mitigations
- **Wrong engine assumption** → verified against a real pin; flagged S1 for owner (ADR-003).
- **Wrong guard entries / zone IDs** → inert not fatal; `verify_ids.sql` + `.inm where` surface it.
- **Can't run the server here** → mock-engine harness + CI MySQL apply + explicit in-game matrix.
- **Silent wrong-event-id registration** → every id verified + grep-gated; documented habit.

## Explicitly out of scope for this branch
v2 (area districts, TRIGGER_EVENT moments, LoS/facing tuning, 200+ lines) and v3 (client
addon). Non-enUS locales. Custom creature/spell content. Any core/client binary patching.
