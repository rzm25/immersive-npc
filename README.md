# lua-immersive-npc-chat

Immersive, server-authoritative NPC ambience for **AzerothCore WotLK 3.3.5a**, written
entirely in **Lua** for the **Eluna / ALE** engine. Guards and citizens in the six
faction-hub cities occasionally make short, lore-friendly, context-aware remarks about a
nearby player — their race, class, faction, and *visible equipment* — as real NPC chat.
Rare and delightful, never spammy, near-zero server cost.

No worldserver core patch. No client patch (v1). Works on an unmodified client.

## Requirements

- An AzerothCore 3.3.5a server running **Eluna / ALE** (this module is Lua-only — there
  is nothing to compile). Pinned reference engine + commit: see [docs/SOURCES.md](docs/SOURCES.md).
  **Confirm the engine + commit your server actually builds** before trusting event IDs
  (workspace gotcha #1). If your build is not the pinned Eluna, re-verify SOURCES.md
  against it — a wrong event id fails **silently** in Lua.
- Lua **5.2** (ALE). The scripts and unit tests assume 5.2 (`bit32`).

## Install

1. **Import SQL** into the world DB (order: base, then updates):
   ```bash
   mysql acore_world < sql/world/base/inc_base.sql
   mysql acore_world < sql/world/updates/2026_07_07_00_seed_locations_profiles.sql
   mysql acore_world < sql/world/updates/2026_07_07_01_seed_lines.sql
   ```
   Seeds are idempotent (safe to re-run). Then **pre-flight the guard entries** on your DB:
   ```bash
   mysql acore_world < sql/verify_ids.sql
   ```
   Any entries listed as `missing_entry` don't exist on your server — fix those
   `creature_entry` values in the profile seed (find yours with
   `SELECT entry,name FROM creature_template WHERE name LIKE '%Guard%';`).
2. **Deploy the scripts**: copy the contents of `scripts/inc/` into your server's
   configured Lua scripts directory (e.g. `lua_scripts/`). Keep the `01_`…`08_` filename
   prefixes — load order matters.
3. **Reload or restart**: `.reload eluna` (or restart `worldserver`). You should see a
   boot line like:
   ```
   [inm] v1.0.0 loaded: 6 locations, 6 profiled entries (6 profiles), 36 lines, 0 skipped | profiledEntries hooked=6 | tick=5000ms | engine=...
   ```
4. Walk into a capital and wait, or drive it with `.inm force self` (as a GM).

## Configuration

There is **no `.conf` file** — config is the Lua table `INC.Config` in
[scripts/inc/01_inc_config.lua](scripts/inc/01_inc_config.lua). Edit it and reload
(`.inm reload` re-clamps the in-memory config and reloads the DB content without a
restart; editing the *file* needs `.reload eluna`). Key values (all clamped on load):

| Key | Default | Meaning |
|---|---|---|
| `Enable` | `true` | master switch |
| `SchedulerTickMs` | 5000 | heartbeat period (≥1000) |
| `GlobalMinIntervalMs` | 45000 | min gap between any two lines, server-wide |
| `GlobalBurstMax` / `GlobalBurstWindowMs` | 2 / 180000 | global burst token bucket |
| `LocationMinIntervalMs` | 120000 | min gap per location |
| `LocationMaxLinesPer10Min` | 6 | hard per-location ceiling |
| `PlayerCooldownMs` / `NpcCooldownMs` | 300000 / 600000 | per-player / per-NPC cooldown (≥30000) |
| `LineCooldownMs` / `CooldownGroupMs` | 3600000 / 900000 | per-line / per-category cooldown |
| `MaxCandidateSearchRadius` | 24.0 | candidate NPC pre-filter radius (5..60) |
| `RequireLineOfSight` / `RequireNpcFacingPlayer` | false / false | extra final-validation gates |
| `PopulationScaling` | on, 0.25→1.5/min | busier hubs talk a little more often (rate only) |
| `AllowPersonalWhispers` | true | allow `chat_mode=1` whisper lines |
| `Debug` | false | per-attempt trace logging |

## Tables (world DB)

- `immersive_npc_chat_location` — the six hubs (map/zone/area, pacing caps). `id` < 32.
- `immersive_npc_chat_npc_profile` — which creature entries speak, their role mask,
  speak distance, whisper permission.
- `immersive_npc_chat_line` — the content: masks (class/race/team/location/role, ALL-of
  item tags, min quality), cooldown group, weight, chat mode, text.

Bit-constant values are documented in the header of `sql/world/base/inc_base.sql`
(mirrored from `scripts/inc/02_inc_util.lua`, the single source of truth) and in
[docs/CONTENT_GUIDE.md](docs/CONTENT_GUIDE.md).

## GM commands (rank ≥ 2)

```
.inm status              counts, tokens, tracked players, per-location line rate
.inm where               your map/zone/area, matched location, nearby registry NPCs + distances
.inm force [self]        one attempt now (still final-validated); reports the outcome/reason
.inm reload              re-clamp config + reload DB content (atomic; no restart)
.inm cooldown clear      reset all cooldowns/buckets
.inm stats               the 15 failure-reason counters (the tuning instrument)
.inm debug on|off        per-attempt trace logging
```

## Adding content

Add rows to `immersive_npc_chat_line`, run `python3 tools/check_sql.py <file>`, import,
`.inm reload`. New lines/locations and profile-attribute edits go live on reload. See
[docs/CONTENT_GUIDE.md](docs/CONTENT_GUIDE.md) for tone rules and mask semantics.

## Known limitations (v1)

- **enUS only.** The `locale` column exists; only `enUS` rows load (ADR-005).
- **Cooldowns are memory-only** — they reset on script reload / server restart (by design).
- **No unequip event exists**, so equipment is *lazy-scanned* per attempt rather than
  cached — always correct, and a client spam-swapping gear costs nothing (ADR-001).
- **Adding a brand-new profiled creature `entry` needs a full `.reload eluna`**, not
  just `.inm reload` — Eluna can't hot-register a new creature hook (ADR-007). Editing an
  existing profile's attributes, or its lines/locations, works live.
- **Guard entries + zone IDs are best-effort** and must be verified on your DB
  (`sql/verify_ids.sql`, `.gps`, `.inm where`). A wrong one is inert, not fatal.

## Development / testing

```bash
luacheck scripts/inc tests .luacheckrc     # lint (0 warnings; no implicit globals)
lua5.2 tests/run_tests.lua                  # pure-Lua unit tests (engine-free)
lua5.2 tests/integration_mock.lua          # offline mock-engine integration harness
python3 tools/check_sql_selftest.py         # prove the SQL checker can fail
python3 tools/check_sql.py sql/world/base/*.sql sql/world/updates/*.sql
```

CI (`.github/workflows/build.yml`) runs all of the above plus a real MySQL apply of the
schema + seeds on every push. See [docs/](docs/) for SOURCES, DECISIONS, PROGRESS,
TESTPLAN, PROJECT_PLAN, and CONTENT_GUIDE.
