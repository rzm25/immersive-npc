# TRUTH_SOURCES — immersive-npc at-a-glance

Module-specific values this module owns (cross-project truth lives in
`/workspaces/sandyb/source`). If this and any other doc disagree, one has drifted — fix
it and note it in `agent-notes/`.

## Identity
- **Module:** `lua-immersive-npc-chat` — immersive, context-aware NPC ambience chat.
- **Repo:** `github.com/rzm25/immersive-npc` (working dir `/workspaces/sandyb/immersive-npc`).
- **Engine:** **ALE** (`azerothcore/mod-ale`), Lua 5.2 (pin in [docs/SOURCES.md](docs/SOURCES.md)). Lua-only — no C++ build, no loader symbol. Scripts → `ALE.ScriptPath` (`lua_scripts`); reload `.reload ale`; engine conf `mod_ale.conf`.
- **Deploy target (live server `peri0`):** the whole `scripts/inc/` set lives in **`/opt/azerothcore/server/bin/lua_scripts/immersive-npc/`** — ONE directory. ALE loads `ScriptPath` recursively and errors on duplicate basenames, so **never** leave loose copies in the `lua_scripts/` root or deploy a subset next to the full set (breaks load with nil-upvalue errors — shared gotcha #15). Deploy all files together, in place. `01_inc_config.lua` there is operator-tuned + `--skip-worktree`'d — don't overwrite it.
- **Reserved ID block:** **9506xx** (`/source/ID_RANGES.md`). v1 uses **no** custom
  creature/spell/quest IDs — it profiles STOCK creatures. Block held for future custom NPCs (e.g. a Town Crier).

## Custom tables (world DB) — full schema in `sql/world/base/inc_base.sql`
- `immersive_npc_chat_location` — hubs. PK `id` (< 32). map/zone/area + pacing caps.
- `immersive_npc_chat_npc_profile` — profiled creature entries → role mask, speak distance, whisper flag.
- `immersive_npc_chat_line` — content rows → masks + cooldown group + weight + chat mode + text
  + **`min_player_level`** (0 = no gate; else listener must be ≥ this — the Violet Hold "75+" pool).

### Role bit values (`role_mask_lo`, positions in `inc_base.sql` mirror)
GUARD=1 · VENDOR=4 · CITIZEN=128 · OFFICIAL/EMISSARY=256 · CRIER=512 ·
SUNREAVER=65536 · VIOLET_HOLD=131072 · SKYREAVER=262144 · SKYBREAKER=524288.
Profiles are attached by `sql/world/updates/2026_07_12_00_eligibility.sql` (idempotent via a
`comment LIKE 'inm-auto:%'` marker; derives entry from spawn guid via `creature.id1`).

## Config keys
- Live in `scripts/inc/01_inc_config.lua` as `INC.Config` (no `.conf`). Clamped by `INC.ClampConfig()`
  (which also **defaults any missing key**, so an operator config predating a schema change keeps
  working). Full list in [README.md](README.md#configuration).
- **Emission is PER-PLAYER (ADR-011), not server-wide.** Key knobs: `PlayerCadenceMs` (escalating
  per-player gaps, arrival→30s→2.5m→5m→10m), `MaxEmitsPerTick` (per-tick emission budget),
  `RetryBackoffMs`, `NpcCooldownMs`/`LineCooldownMs`/`CooldownGroupMs` (anti-repeat), `SchedulerTickMs`,
  `MaxCandidateSearchRadius`. **Removed** (do not reference): `GlobalMinIntervalMs`, `GlobalBurst*`,
  `LocationMinIntervalMs`, `LocationMaxLinesPer10Min`, `PlayerCooldownMs`, `PopulationScaling`.

## Seeded content (operator-tunable — verify with `sql/verify_ids.sql`)
- **Locations 1–6:** Stormwind(zone 1519,map0) Ironforge(1537,0) Darnassus(1657,1) Orgrimmar(1637,1) ThunderBluff(1638,1) Undercity(1497,0).
- **Guard profiles (role GUARD, `role_mask_lo=1`):** entries 68 / 5595 / 4262 / 3296 / 3084 / 5624 (SW/IF/DARN/ORG/TB/UC). **Verify each in `creature_template`.**
- **36 chat lines**, cooldown groups 1 greeting · 2 equipment · 3 class · 4 faction/place · 5 warning · 6 gesture.

## Where each behaviour lives (`scripts/inc/`)
| File | Responsibility |
|---|---|
| `01_inc_config.lua` | `INC.Config`, `ClampConfig`, log shims (`Log/Warn/Err/DebugLog`), `Protect`/`ProtectRet` (pcall wrappers) |
| `02_inc_util.lua` | **engine-free**: all bit constants, `Mask64*`/`MatchAny*/MatchAll64`, token bucket, `WeightedPick`, `ReplacePlaceholders`, `TruncateBytes` |
| `03_inc_data.lua` | `WorldDBQuery` loaders (ONLY here), validation+skip, prebuilt `LinesByLocation`/`NpcProfilesByEntry`, `Load()` (atomic-swap caches), `ResolveLocation`, `FindProfile` |
| `04_inc_registry.lua` | per-entry ON_ADD/ON_REMOVE (36/37), `Registry[loc][guidLow]`, `RegistryIndex`, `Registry.Init/ForLocation/SeedFromPlayers` (one grid-search per player). **Spatial-index upgrade planned: [docs/SPATIAL_INDEX_PLAN.md](docs/SPATIAL_INDEX_PLAN.md).** |
| `05_inc_players.lua` | player events 3/4/27/47, `PlayerTrack` (`emitCount`/`nextEligibleMs`/`level`, reset on hub arrival)/`LocationState`, `ScanEquipment` (lazy 19-slot scan → tags+quality+weaponType) |
| `06_inc_scheduler.lua` | `NowMs`, metrics, **per-player** cadence + anti-repeat cooldowns, `emitForPlayer`, `tick` (multi-emit sweep, `MaxEmitsPerTick`), final validation, `RunAttempt` (force), `ClearCooldowns`, heartbeat `CreateLuaEvent` |
| `07_inc_commands.lua` | `.inm` command set via event 42 |
| `08_inc_main.lua` | `INC.Boot()` (wire everything, boot summary), `INC.Reload()`, config-load survival (9), state-close cleanup (16) |

## Runtime state (all under `INC.State`, memory-only, reset on script reload)
`Registry[loc][guidLow]` / `RegistryIndex` / `RegistryCount`; `PlayerTrack[guidLow]` (per-player
`emitCount`/`nextEligibleMs`/`level`/`lineCd`/`groupCd`) / `LocationState[loc]` (players set + count);
`Metrics`; `schedulerEventId`. **No global/location pacing state** (ADR-011 removed `GlobalBucket`/
`GlobalLastEmitMs`/`LocPacing`). Persistent on `INC`: `schedulerEventId` (for teardown), `Caches`
(immutable, swapped whole on reload).

## Tooling
- `tools/check_sql.py` (+ `check_sql_selftest.py`) — structural SQL checker, negative-tested (no `mysql` in sandbox).
- `tests/run_tests.lua` (unit), `tests/integration_mock.lua` (offline mock-engine integration).
