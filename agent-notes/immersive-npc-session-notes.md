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

## Session 2 (2026-07-10): engine confirmed as ALE (azerothcore/mod-ale)

The owner pointed to `azerothcore/mod-ale`'s USAGE.md — so ALE is real, at
**`azerothcore/mod-ale`** (I'd only checked the 404 `azerothcore/mod-eluna`). I re-verified
**every event ID and method name against ALE's own `src/LuaEngine`** (Hooks.h + methods/*.h
+ LuaFunctions.cpp bindings) at `mod-ale@1cb86c9` — they all match; the module was already
API-correct (ALE is Eluna-lineage; only internal C signatures differ). Changes made:

- **Real bug (ALE-specific):** `PLAYER_EVENT_ON_COMMAND` passes `player=nil` for
  server-console commands (`handler.IsConsole()`). Added `if not player then return end` in
  `07` (previously only the pcall wrapper caught the deref). ADR-009.
- **`.reload ale` fires no login event** for connected players → added
  `INC.Players.TrackOnline()` (via `GetPlayersInWorld()`) called at Boot; no-op at startup.
  ADR-009. Refactored login into a shared `track(player)`.
- Renamed the state-close constant to `ALE_EVENT_ON_LUA_STATE_CLOSE` (value 16 unchanged).
- Docs corrected everywhere: engine = ALE, config `mod_ale.conf` (`ALE.Enabled`,
  `ALE.ScriptPath="lua_scripts"`), reload `.reload ale` (NOT `.reload eluna`). SOURCES.md
  re-pinned to ALE; DECISIONS ADR-003 addendum + ADR-009; `/source` gotcha #15 corrected
  (ALE lives at `azerothcore/mod-ale`; snapshot taken).
- Integration harness now **46** assertions (added console-nil-player + TrackOnline).
- Handoff commands corrected for the owner (script dir, `.reload ale`).

## Session 3 (2026-07-12): live-feedback fixes + eligibility + faction content

Owner ran the live server hard and gave a big feedback batch (logged in full in
`agent-notes/FEEDBACK_LOG.md`). Delivered:

- **Diagnosed the "1 line / ~10 min" complaint.** Emission RATE is gated by pacing, NOT
  cooldowns: `SchedulerTickMs`, `GlobalMinIntervalMs` (45s), the **global token bucket**
  (2 per 180s ≈ 1/90s, *shared server-wide* — the real bottleneck on a bot-populated server),
  per-location `min_interval_ms`/`max_lines_per_10min`, and `PopulationScaling` (~1/4min at
  pop≈1). Lowering group cooldown did nothing because that only controls per-listener variety.
  `.inm force` bypasses ONLY those pacing gates — which is why force works when natural won't.
  Fix is config (owner has `01_inc_config.lua` skip-worktree'd), values given in handoff.
- **Root-caused every "silent NPC" report:** the entry wasn't profiled. Added
  `sql/world/updates/2026_07_12_00_eligibility.sql` — profiles the named Darkshire + Dalaran
  NPCs (by the exact spawn guids given), a broad **VENDOR** sweep (npcflag bit 128, bounded to
  our locations' maps), and the four Dalaran factions by name+guid. Idempotent via an
  `inm-auto:*` comment marker. **Uses `creature.id1`** (verify vs `id` on older cores).
- **New `min_player_level` line gate** (schema + loader col 16 + `track.level` + `selectLine`,
  nil-guarded both sides) for the Violet Hold "speak only to 75+" requirement. Integration
  test added (level-74 never hears it; level-80 does). Tests: unit 66, integration **58**.
- **New role bits:** VENDOR=4 (was already reserved), SUNREAVER=65536, VIOLET_HOLD=131072,
  SKYREAVER=262144, SKYBREAKER=524288. `inc_base.sql` mirror extended.
- **Content (STAGED functional tranches; owner tunes tone via CONTENT_LINES.md, then fill to
  target):** vendors 42 (→200), Sunreaver 26, Violet Hold 20, Sky-Reaver 24, Skybreaker 24,
  Darkshire +20 (→42). Opposing-faction lines via `team_mask`. Total content now **382 lines**.
- CONTENT_LINES.md regenerated (generator now names the new roles + shows the level gate).

**Next:** fill each new pool to its target count; owner to run the eligibility SQL + content
SQL, `.reload ale` (then a restart for full Dalaran/Darkshire registration), and re-test.

### Handoff state / next steps (Session 2)
- **Pushed** the module commit `60dfc9e` to `origin/main` (github.com/rzm25/immersive-npc).
  The CI workflow is a SEPARATE local commit `5558460` that could NOT be pushed — the
  provided PAT lacks the `workflow` scope. Owner must push it with a workflow-scoped token
  (`git push origin 5558460:main`) or add `.github/workflows/build.yml` via the GitHub web UI.
- Owner to: confirm engine build (S1); import SQL + run `verify_ids.sql`; deploy `scripts/inc/`
  to the Lua dir; `.reload eluna`; check the boot summary line; run the in-game matrix
  (TESTPLAN); report `.inm stats`.
- `/source/ID_RANGES.md`: reserved **9506xx** for this module (snapshot taken first).
  `/source/AZEROTHCORE_GOTCHAS.md`: added #15 (Eluna/ALE facts) — snapshot taken first.
