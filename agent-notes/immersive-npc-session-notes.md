# immersive-npc — agent working notes

Living session log. Cold-start context: kickoff + Project Context in `agent.md`; frozen
plan + assessor rubric in `docs/PROJECT_PLAN.md`; at-a-glance map in `TRUTH_SOURCES.md`;
engine pin + verified API in `docs/SOURCES.md`; decisions in `docs/DECISIONS.md`.
Cross-project truth is in `/workspaces/sandyb/source`. Newest at the bottom of each section.

## Session 1 (2026-07-07): v1 build from the spec

### What happened, in order
1. Identified the repo (`rzm25/immersive-npc`, empty, default branch `main`) from the
   token; working dir `/workspaces/sandyb/immersive-npc` copied from the template and
   made its own git repo (nested inside the shared workspace repo — gotcha #13).
2. Read shared `/source` (gotchas, ID ranges, README). No local Eluna checkout.
3. **Engine hunt (the big one).** The spec's `azerothcore/mod-eluna` ("ALE") **404s**;
   `azerothcore/mod-eluna-lua-engine` is archived (2022). Live engine is
   `ElunaLuaEngine/ElunaAzerothcore` (full AC fork) + `ElunaLuaEngine/Eluna` submodule at
   `src/server/game/LuaEngine`. Pinned both commits (SOURCES.md). Fetched `hooks/Hooks.h`
   and `methods/AzerothCore/*.h` and **verified every event ID + method signature**. All
   spec event IDs matched upstream Eluna exactly → ADR-003.
4. Installed a local toolchain: `lua5.2` (5.2.4) + `luacheck` (1.2.0) via apt/luarocks —
   so unit tests + lint actually run here, not just in CI.
5. Wrote `01`–`08` scripts; lint-clean; smoke-tested config+util under lua5.2.
6. Wrote pure-Lua unit tests (`tests/run_tests.lua`, 66/66) and an **offline mock-engine
   integration harness** (`tests/integration_mock.lua`, 32/32) that boots all 8 scripts
   against stubbed Eluna objects and drives boot→select→validate→emit.
7. Wrote schema + seeds (6 hubs, 6 guard profiles, 36 lines) + `verify_ids.sql`, plus a
   **negative-tested** SQL structural checker (`tools/check_sql*.py`) since the sandbox
   has no `mysql`.
8. Adapted CI (`build.yml`) for a Lua module: luacheck + lua tests + real MySQL apply.
9. Wrote the docs suite + this log.

### Key design decisions (condensed — full reasoning in docs/DECISIONS.md)
- **ADR-003**: engine = upstream Eluna (ElunaAzerothcore), not the spec's missing `mod-eluna`.
- **ADR-001**: lazy equip scan, no cache, no `ON_EQUIP` registration (no unequip event).
- **ADR-002**: ms clock = `GetGameTime()*1000` (epoch seconds; avoids getMSTime 49-day wrap).
- **ADR-004**: population budget = per-location capacity-2 bucket with dynamic window; uniform location choice.
- **ADR-007**: `.inm reload` swaps caches + config only; new profiled *entries* need `.reload eluna`.

### What's built
All of v1 (Phases 1–6): scripts, SQL+seeds, unit+integration tests, SQL checker, CI, docs.
Offline gates all green (luacheck 0, unit 66/66, integration 32/32, SQL checker 5/5 + clean).

### Verified vs deferred (be precise about the gap)
- **Verified here:** every event id/method vs the Eluna pin; all pure logic + the full
  pipeline via the mock harness; SQL structure + idempotency (CI); lint.
- **Reasonably confident, not executed live:** scripts load cleanly in a real ALE state;
  `WorldDBQuery` result iteration; emission visibility; `IsTaxi()` = "on taxi".
- **Deferred to the owner's server:** S1 (actual engine build), guard entries + zone IDs,
  the entire in-game matrix (TESTPLAN "in-game" section).

### Divergences from the frozen docs/PROJECT_PLAN.md
- None yet. All deviations from the spec are captured as ADRs (003 is the substantive one:
  the spec's named engine doesn't exist; used upstream Eluna instead).

### Bugs found and fixed (root cause)
- `INC.Protect` swallowed handler return values → the `.inm` command handler couldn't
  return `false` to consume the command. Added `INC.ProtectRet` (propagates returns) for
  the command handler only; kept alloc-free `Protect` for the hot tick path.
- `Scheduler.Init` set `INC.State.schedulerEventId` but not the persistent
  `INC.schedulerEventId` used by state-close cleanup → caught by the integration harness
  (heartbeat timer assertion). Fixed to set both + cancel any prior timer.
- SQL structural checker v1 had the swallowed-comma rule *backwards* (flagged the safe
  comma-before-comment pattern) and the quote check was shadowed by the tuple regex.
  Rewrote with a state-machine parser; negative test now proves it catches all 3 defect
  classes.
- **Code-review pass found real command bugs:** `cmdForce`/`cmdDebug` read `args[2]` (the
  subcommand token) instead of `args[3]` (the parameter), so `.inm force self` never pinned
  self and `.inm debug on|off` always printed usage. Fixed to `args[3]`. Also `selectNpc`
  bypassed the per-NPC cooldown when `forced`, contradicting TESTPLAN matrix 4 (force must
  honor per-entity cooldowns); removed the bypass. Added command-handler + NPC-cooldown
  integration tests (would have caught both).
- **Mock harness bug (masked the above):** `makePlayer` hardcoded `gm=false`, so the command
  tests were silently hitting the permission-denied path (which also returns `false`).
  Verified `PLAYER_EVENT_ON_COMMAND` semantics against the pin first: `text` has no leading
  dot; returning `false` consumes, `nil` falls through (`CallAllFunctionsBool` default true).
  Fixed the mock to honor `o.gm`; command tests now exercise the real GM-gated dispatch.
- Integration harness is now **41** assertions (added 2 NPC-cooldown + 7 command tests).

### Handoff state / next steps
- Committed to `main` (local). **Not pushed** — owner pushes (see the commit + exact
  push/deploy commands in the handoff message / README).
- Owner to: confirm engine build; import SQL + run `verify_ids.sql`; deploy `scripts/inc/`;
  reload; run the in-game matrix; report `.inm stats`.
- `/source/ID_RANGES.md`: reserved **9506xx** for this module (snapshot taken first).
