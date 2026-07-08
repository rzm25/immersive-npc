# SOURCES — engine pins + verified facts

Every engine fact this module relies on traces to a source below, with a commit hash
or retrieval date. **Re-verify against the pin your server actually builds** before
trusting any of it (workspace gotcha #1: never trust an API/schema from memory).

## Engine identity (decided ONCE — see DECISIONS ADR-003)

| | Value |
|---|---|
| **Engine** | **Eluna** (the `ElunaLuaEngine/Eluna` Lua engine) as embedded in the `ElunaLuaEngine/ElunaAzerothcore` AzerothCore fork. Lua **5.2**. |
| **ElunaAzerothcore pin** | `7029f29b4e53564830ef465a9a3ffb9d3ca774dd` (master, committed 2026-07-07) |
| **Eluna engine submodule pin** | `e36707dde7ac5628bb733376a7b679e488612de4` (master, committed 2026-07-06), mounted at `src/server/game/LuaEngine` |
| **Where the truth files live** | Hooks: `hooks/Hooks.h` (Eluna repo). Methods: `methods/AzerothCore/*.h` (Eluna repo). |

> **Spec-vs-reality note (must read).** The build spec names the engine
> `azerothcore/mod-eluna` ("ALE — AzerothCore Lua Engine", claimed diverged from
> upstream Eluna). As of 2026-07-07 that repo path **404s**; the old
> `azerothcore/mod-eluna-lua-engine` is **archived (2022)**. The live, actively
> maintained AzerothCore Eluna is `ElunaLuaEngine/ElunaAzerothcore` (pinned above),
> and **every event ID the spec listed verifies exactly against its upstream Eluna
> `Hooks.h`** — so for the event/method surface this module uses, the claimed
> divergence is immaterial. See ADR-003.
>
> **S1 is still UNVERIFIED for THIS server.** I do not have access to the owner's
> server checkout. The pins above are the canonical public Eluna at the dates shown.
> The owner must confirm which engine + commit their `worldserver` actually builds
> and, if it differs, re-run the verification in this file against it.

## Source table (spec §1)

| # | Source | Authoritative for | Status |
|---|--------|-------------------|--------|
| S1 | The exact Eluna checkout the server builds | every event ID / method / signature | **UNVERIFIED for this server** — pins above used as the public reference |
| S2 | `hooks/Hooks.h` @ Eluna e36707d | event enums | verified 2026-07-07 |
| S3 | `methods/AzerothCore/*.h` @ Eluna e36707d | `Player/Creature/Unit/Item/Map/WorldObject/Global` methods | verified 2026-07-07 |
| S4 | AzerothCore world DB schema of the target server | `creature`, `creature_template` for authoring profiles | operator-side (verify guard entries with `sql/verify_ids.sql`) |
| S5 | AzerothCore wiki (SmartAI, `creature_text`) | v2 ambience supplement | not used in v1 |
| S6 | 3.3.5a client addon API | v3 client layer | not built |

## Verified event IDs (S2 — `hooks/Hooks.h` @ e36707d)

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
| `ELUNA_EVENT_ON_LUA_STATE_CLOSE` | 16 | ✅ 08 (cancel heartbeat) |
| `WORLD_EVENT_ON_UPDATE` | 13 | 🚫 never registered (spec §4.7 / §13) |
| `TRIGGER_EVENT_ON_TRIGGER` | 24 | · v2 |
| `ADDON_EVENT_ON_MESSAGE` | 30 | · v3 |

**No player unequip event exists.** `PlayerEvents` has `ON_EQUIP=29` but no unequip.
(There is an item-entry-level `ITEM_EVENT_ON_UNEQUIP=8`, useless here — it would need
registering every item entry.) This is the whole reason equipment is lazy-scanned, not
cached (ADR-001).

## Verified method signatures (S3 — `methods/AzerothCore/*.h` @ e36707d)

Globals (`GlobalMethods.h`):
- `RegisterPlayerEvent(event, fn)` · `RegisterCreatureEvent(entry, event, fn)` · `RegisterServerEvent(event, fn)`
- `id = CreateLuaEvent(fn, delayMs, repeats)` — `repeats == 0` = infinite; **returns the event id**
- `RemoveEventById(id)` — cancels a global timed event
- `WorldDBQuery(sql) -> result|nil` (nil = zero rows)
- `GetPlayerByGUID(objectguid) -> Player|nil` — takes the **full ObjectGuid** (`CHECKVAL<ObjectGuid>`)
- `GetGameTime() -> int64 epoch SECONDS` (never wraps; this module's ms clock is `*1000` — ADR-002)
- `PrintInfo(str)` / `PrintError(str)`

Query result (`ElunaQueryMethods.h`), columns **0-indexed**:
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
- 2026-07-07 — Created. Pinned Eluna/ElunaAzerothcore; verified all event IDs + methods
  against the pin; recorded the spec's missing-`mod-eluna` divergence and the S1
  UNVERIFIED-for-this-server caveat.
