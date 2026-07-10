# SOURCES — engine pins + verified facts

Every engine fact this module relies on traces to a source below, with a commit hash
or retrieval date. **Re-verify against the pin your server actually builds** before
trusting any of it (workspace gotcha #1: never trust an API/schema from memory).

## Engine identity (decided ONCE — see DECISIONS ADR-003)

**The owner confirmed the engine is ALE, at `azerothcore/mod-ale`.** All event IDs and
method names below are verified against ALE's own source (not just upstream Eluna).

| | Value |
|---|---|
| **Engine** | **ALE — AzerothCore Lua Engine**, `azerothcore/mod-ale`. Lua **5.2**. |
| **ALE pin (verified against)** | `1cb86c9600260c3731c96dc3c98d25b4fc3f2153` (master, committed 2026-05-22) |
| **Where the truth files live** | Hooks: **`src/LuaEngine/Hooks.h`**. Methods: **`src/LuaEngine/methods/*.h`** (+ Lua-name bindings, `src/LuaEngine/LuaFunctions.cpp`). |
| **Config file** | `mod_ale.conf` (from `mod_ale.conf.dist`). Keys: `ALE.Enabled = true`, `ALE.ScriptPath = "lua_scripts"`, `ALE.AutoReload` (file-watcher; off by default). |
| **Default script dir** | `ALE.ScriptPath` = `lua_scripts` — relative to the server folder (the folder with the worldserver binary). |
| **Reload command** | `.reload ale` (in-game GM; dev-only) or a full restart. |

> **How we got here.** The build spec named `azerothcore/mod-eluna`, which **404s**;
> the old `azerothcore/mod-eluna-lua-engine` is **archived (2022)**. I first pinned
> upstream Eluna (`ElunaLuaEngine/Eluna` @ `e36707d`, via `ElunaLuaEngine/ElunaAzerothcore`
> @ `7029f29`) as a best-available proxy and verified every event ID against it. The
> owner then supplied the real engine: **ALE at `azerothcore/mod-ale`**. I re-verified
> every event ID **and** every method name against ALE's own `src/LuaEngine` — they
> match (ALE is Eluna-lineage; internal signatures differ, e.g. `int F(lua_State* L,…)`
> vs `Eluna* E`, but the Lua-facing names/IDs are identical). See ADR-003.
>
> **S1 residual gap:** I still don't have the owner's *exact* build commit; the pin
> above is `azerothcore/mod-ale@master` as of 2026-05-22. If the server tracks a
> different ALE commit, re-check this file against it — but the surface we use (login/
> logout/zone/area/command + creature add/remove + config-load + state-close + the ~50
> methods) is long-standing and unlikely to have moved.

## ALE-specific behaviors verified (differ from a generic Eluna)

- **`PLAYER_EVENT_ON_COMMAND` (42)** signature is `(event, player, command, chatHandler)`
  and **`player` is nil for a server-console command** (`handler.IsConsole()`). The
  handler guards `if not player then return end` (07). `command` has **no leading dot**
  (ALE's own `reload ale` intercept matches from index 0). Returning `false` consumes the
  command; `nil` lets core process it (`START_HOOK_WITH_RETVAL(…, true)`).
- **State-close hook is `ALE_EVENT_ON_LUA_STATE_CLOSE = 16`** (Eluna's `ELUNA_…`). We use
  the numeric literal 16.
- **`.reload ale` fires no login event for already-connected players** (ALE reload
  limitation). Boot calls `INC.Players.TrackOnline()` (via `GetPlayersInWorld()`) so they
  are re-tracked; a no-op at server startup.

## Source table (spec §1)

| # | Source | Authoritative for | Status |
|---|--------|-------------------|--------|
| S1 | The exact ALE checkout the server builds | every event ID / method / signature | engine confirmed **ALE**; verified against `azerothcore/mod-ale@1cb86c9` (owner to confirm exact commit) |
| S2 | `src/LuaEngine/Hooks.h` @ mod-ale 1cb86c9 | event enums | verified 2026-07-10 |
| S3 | `src/LuaEngine/methods/*.h` + `LuaFunctions.cpp` @ mod-ale 1cb86c9 | `Player/Creature/Unit/Item/Map/WorldObject/Global` methods + Lua-name bindings | verified 2026-07-10 |
| S4 | AzerothCore world DB schema of the target server | `creature`, `creature_template` for authoring profiles | operator-side (verify guard entries with `sql/verify_ids.sql`) |
| S5 | AzerothCore wiki (SmartAI, `creature_text`) | v2 ambience supplement | not used in v1 |
| S6 | 3.3.5a client addon API | v3 client layer | not built |

## Verified event IDs (S2 — ALE `src/LuaEngine/Hooks.h` @ 1cb86c9)

All match the spec. Registered by this module marked ✅; referenced-but-not-registered
marked ·; **banned** marked 🚫.

| Enum | ID | Used |
|---|---|---|
| `PLAYER_EVENT_ON_LOGIN` | 3 | ✅ 05 |
| `PLAYER_EVENT_ON_LOGOUT` | 4 | ✅ 05 |
| `PLAYER_EVENT_ON_UPDATE_ZONE` | 27 | ✅ 05 |
| `PLAYER_EVENT_ON_UPDATE_AREA` | 47 | ✅ 05 |
| `PLAYER_EVENT_ON_EQUIP` | 29 | · (deliberately NOT registered — ADR-001) |
| `PLAYER_EVENT_ON_COMMAND` | 42 | ✅ 07 |
| `CREATURE_EVENT_ON_ADD` | 36 | ✅ 04 (per profiled entry) |
| `CREATURE_EVENT_ON_REMOVE` | 37 | ✅ 04 (per profiled entry) |
| `WORLD_EVENT_ON_CONFIG_LOAD` | 9 | ✅ 08 |
| `ALE_EVENT_ON_LUA_STATE_CLOSE` | 16 | ✅ 08 (cancel heartbeat) |
| `WORLD_EVENT_ON_UPDATE` | 13 | 🚫 never registered (spec §4.7 / §13) |
| `TRIGGER_EVENT_ON_TRIGGER` | 24 | · v2 |
| `ADDON_EVENT_ON_MESSAGE` | 30 | · v3 |

**No player unequip event exists.** `PlayerEvents` has `ON_EQUIP=29` but no unequip.
(There is an item-entry-level `ITEM_EVENT_ON_UNEQUIP=8`, useless here — it would need
registering every item entry.) This is the whole reason equipment is lazy-scanned, not
cached (ADR-001).

## Verified method signatures (S3 — ALE `src/LuaEngine/methods/*.h` @ 1cb86c9; names confirmed in `LuaFunctions.cpp`)

Globals (`GlobalMethods.h`):
- `RegisterPlayerEvent(event, fn)` · `RegisterCreatureEvent(entry, event, fn)` · `RegisterServerEvent(event, fn)`
- `id = CreateLuaEvent(fn, delayMs, repeats)` — `repeats == 0` = infinite; **returns the event id**
- `RemoveEventById(id)` — cancels a global timed event
- `WorldDBQuery(sql) -> result|nil` (nil = zero rows)
- `GetPlayerByGUID(objectguid) -> Player|nil` — takes the **full ObjectGuid** (`CHECKVAL<ObjectGuid>`)
- `GetGameTime() -> int64 epoch SECONDS` (never wraps; this module's ms clock is `*1000` — ADR-002)
- `PrintInfo(str)` / `PrintError(str)`

Query result (`ALEQueryMethods.h`), columns **0-indexed**:
- `GetUInt32(i)` `GetUInt8(i)` `GetFloat(i)` `GetString(i)` `IsNull(i)` `GetRowCount()`
- `NextRow() -> bool` — iterate with `repeat ... until not q:NextRow()`

Object / WorldObject (`ObjectMethods.h`, `WorldObjectMethods.h`):
- `GetGUID() -> ObjectGuid` (a **value** type — safe to persist, never dangles) · `GetGUIDLow() -> uint32` (counter; table key)
- `GetEntry()` · `IsInWorld()` · `GetX/GetY/GetZ/GetO()` · `GetMapId()` · `GetMap() -> Map`
- `GetZoneId()` · `GetAreaId()` · `GetPhaseMask()` · `GetName()`
- `GetDistance(worldobject) -> float` (also `(x,y,z)`) · `IsWithinLoS(worldobject)` · `IsInFront(worldobject)`

Map (`MapMethods.h`):
- `GetWorldObject(objectguid) -> object|nil` — resolves creature/player/GO by full ObjectGuid on that map

Unit (`UnitMethods.h`):
- `SendUnitSay(msg, language)` · `SendUnitWhisper(msg, language, receiverPlayer, bossWhisper=false)`
- `SendUnitEmote(msg[, receiver[, boss]])` (text emote) · `PerformEmote(emoteId)` (animation)
- `IsAlive()` `IsDead()` `IsInCombat()` `IsTaxi()` `IsFlying()` `GetClass()` (1..11) `GetRace()` (1..11) `HasAura(id)`

Player (`PlayerMethods.h`):
- `GetTeam() -> TeamId` (0 Alliance, 1 Horde) · `GetGMRank()` · `IsGM()` · `IsGMVisible()`
- `GetEquippedItemBySlot(slot) -> Item|nil` (slots 0..18, EQUIPMENT_SLOT_END=19) · `SendBroadcastMessage(str)`

Item (`ItemMethods.h`):
- `GetClass()` (2 weapon, 4 armor) · `GetSubClass()` · `GetInventoryType()` · `GetQuality()` (0..7)

## GUID model (critical — the no-userdata rule, spec §1)

`GetGUID()` returns a full `ObjectGuid` **value** (not a live-object pointer), so it is
safe to store across ticks; resolve it later with `GetPlayerByGUID(guid)` (players) or
`playerMap:GetWorldObject(guid)` (creatures). `GetGUIDLow()` returns the plain counter,
used only as a compact table key. This module stores both and **never** stores a
`Player`/`Creature` userdata across a tick.

## Zone IDs used (S4 — client constants, verify with `.gps`)

Stormwind 1519 (map 0) · Ironforge 1537 (0) · Darnassus 1657 (1) · Orgrimmar 1637 (1) ·
Thunder Bluff 1638 (1) · Undercity 1497 (0). Stable 3.3.5a values, but confirm in-game.

## Changelog
- 2026-07-10 — Owner confirmed the engine is ALE (azerothcore/mod-ale). Re-pinned + re-verified all event IDs and method names against ALE src/LuaEngine (@1cb86c9); added ALE-specific behaviors (console nil player, .reload ale, state-close naming, TrackOnline). Prior Eluna proxy pin retained in the history note.
- 2026-07-07 — Created. Pinned upstream Eluna as a proxy; verified event IDs; recorded the mod-eluna 404.
  against the pin; recorded the spec's missing-`mod-eluna` divergence and the S1
  UNVERIFIED-for-this-server caveat.
