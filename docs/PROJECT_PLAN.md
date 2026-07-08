# PROJECT_PLAN — frozen plan + assessor rubric

**Frozen.** Do not rewrite as work proceeds — record divergences in `agent-notes/`
(and ADRs in `DECISIONS.md`). This is the stable yardstick to measure the build against.
The authoritative spec is the build prompt; this plan is the itemised, checkable
restatement.

## Conceptual framework

NPCs in six faction-hub cities occasionally make short, lore-friendly, context-aware
remarks about a nearby player (race, class, faction, visible equipment) as real,
server-authoritative NPC chat. Rare and delightful, never spammy, near-zero server
cost. Pure Lua on Eluna/ALE. No worldserver core patch; no client patch in v1.

**Architecture (frozen):** event-driven central scheduler (`CreateLuaEvent` heartbeat,
never `WORLD_EVENT_ON_UPDATE`) + per-entry creature registry (events 36/37 for profiled
entries only) + lazy per-attempt equipment scan (no cache — no unequip event exists).
Data in three world-DB tables, loaded once into immutable caches; zero DB queries at
emission. 64-bit masks split lo/hi for Lua 5.2 `bit32`.

## Ordered build agenda (phases → see PROGRESS.md for status)
1 skeleton → 2 config+data → 3 player tracking+lazy scan → 4 registry → 5 scheduler+emission → 6 content. (7 v2, 8 v3 future.)

## Verified facts the build relies on (see SOURCES.md for the pin + full table)
- Engine: Eluna @ `ElunaAzerothcore` pins in SOURCES.md; Lua 5.2. **S1 UNVERIFIED for this server.**
- Event IDs 3/4/27/47/42/36/37/9/16 verified; 13 banned. No player unequip event.
- `CreateLuaEvent` returns an id; `RemoveEventById` cancels. `GetGameTime()` = epoch seconds.
- `GetGUID()` = persistable ObjectGuid value; resolve via `GetPlayerByGUID` / `Map:GetWorldObject`.
- Emission: `SendUnitSay(msg,lang)`, `SendUnitWhisper(msg,lang,player,boss)`, `SendUnitEmote(msg)`, `PerformEmote(id)`.
- Player `GetTeam()`=0/1, `GetClass()/GetRace()`=1..11; Item `GetClass/GetSubClass/GetInventoryType/GetQuality`.

## Assessor rubric — concrete pass/fail checks

An assessor can run these to judge whether the code meets each requirement.

### A. Static / offline (runnable in this sandbox)
- **A1** `luacheck scripts/inc tests .luacheckrc` → 0 warnings. (No implicit globals; only `INC` is global.) ✅
- **A2** `lua5.2 tests/run_tests.lua` → "66 passed, 0 failed". ✅
- **A3** `lua5.2 tests/integration_mock.lua` → "41 passed, 0 failed". ✅
- **A4** `python3 tools/check_sql_selftest.py` → "self-test: OK" (linter provably catches broken SQL). ✅
- **A5** `python3 tools/check_sql.py sql/world/base/*.sql sql/world/updates/*.sql` → clean. ✅
- **A6** `grep -rn "WORLD_EVENT_ON_UPDATE\|RegisterServerEvent(13" scripts/` → no match (heartbeat rule). ✅
- **A7** `grep -rn "WorldDBQuery\|CharDBQuery" scripts/` → matches only in `03_inc_data.lua`. ✅
- **A8** No `Player`/`Creature` userdata stored across a tick: registry/track tables hold only numbers + ObjectGuid values (review 04/05). ✅
- **A9** Seed set is 25–40 lines (36) with whitelist-only placeholders; hostile-input placeholder test exists. ✅

### B. Structural correctness (review)
- **B1** Schema matches spec §5 exactly (three tables, split masks, columns/indexes). ✅ `sql/world/base/inc_base.sql`
- **B2** Bit constants defined once (`02_inc_util.lua`) and mirrored in the base SQL comment. ✅
- **B3** Gate order is cheap→expensive with short-circuit (enabled→global→location→player→npc→group→line→validation). ✅ `06` `attemptBody`
- **B4** Final validation checks player (in-world/alive/not-combat/not-taxi/not-GM-invisible/still-in-location) and NPC (resolve/in-world/alive/not-combat/phase-overlap/live-distance/opt LoS+facing) before emit. ✅ `06`
- **B5** Metrics cover all 15 reason codes (spec §8); `.inm stats` prints them. ✅
- **B6** Tick wrapped in one pcall that logs once + counts LUA_ERROR (no per-tick spam). ✅ `INC.Protect`

### C. In-game (owner runs — TESTPLAN in-game matrix)
- **C1** Boot summary prints; malformed rows warned+skipped; no Lua errors on load/reload.
- **C2** `.inm where` correct in all six hubs + an unsupported zone.
- **C3** `.inm force` reflects a gear swap with **no relog** (validates the no-cache design).
- **C4** Cooldowns block forced repeats; `cooldown clear` restores.
- **C5** Lifecycle abuse (logout/teleport/hearth/death/taxi/instance/GM-invis) → no bad emission, no dangling-userdata errors.
- **C6** Grid churn: registry counts fall then recover.
- **C7** Load: emissions never exceed caps; no world-update regression; zero DB queries steady-state; no chat spam over a 30-min soak.

### Definition of done (v1) — met when A+B are green (they are) and C is recorded pass in TESTPLAN.
