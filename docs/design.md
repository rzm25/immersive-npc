# lua-immersive-npc-chat — design

The authoritative spec is the build prompt; the frozen, itemised plan + assessor rubric
is [PROJECT_PLAN.md](PROJECT_PLAN.md). This file is the short "why" narrative.

## Problem

A living city should occasionally acknowledge the people in it. Vanilla NPCs are inert
props. We want guards and citizens in the six faction hubs to make rare, short,
lore-friendly remarks about a nearby player — noticing their race, class, faction, and
*visible gear* — as real, server-authoritative NPC chat, at effectively zero cost and
with no client mod required.

## Why the hard parts are hard
1. **Cost.** Naively, "react to nearby players" means per-NPC proximity scans every tick
   — death by a thousand cuts inside the single-threaded map update. Solved by making it
   *event-driven*: one central 5 s heartbeat picks at most one (player, NPC, line) per
   attempt, globally token-gated to ~1–2/min.
2. **Staleness.** Equipment can change without a usable event (there is an `ON_EQUIP` but
   no unequip / visible-slot event). A cache would silently rot. Solved by *not caching*:
   scan the one selected player's 19 slots on the spot (ADR-001).
3. **Dangling references.** Storing `Player`/`Creature` userdata across ticks is a
   crash/staleness hazard. Solved by storing GUIDs (numbers + persistable ObjectGuid
   values) and resolving + re-validating at use.
4. **Lua 32-bit maths.** Lua 5.2 `bit32` is 32-bit; role/item masks want more. Solved by
   splitting 64-bit masks into `lo`/`hi` uint32 words with tested helpers.
5. **Spam vs. delight.** Solved by a layered gate: global bucket → per-location
   population-scaled budget + hard 10-min cap → per-player/NPC/line/group cooldowns →
   final validation. Every rejection is counted by reason (`.inm stats`) for tuning.

## Solution components
1. **Data layer** (`03`): three world tables → immutable caches with prebuilt per-location
   indexes; loaded once, swapped atomically on reload; zero DB access at emission.
2. **Registry** (`04`): per-profiled-entry ON_ADD/ON_REMOVE so Lua fires only for our
   handful of entries during grid load; registry keyed by location→guid.
3. **Player tracking + lazy scan** (`05`): login/logout/zone/area maintain who is where;
   the scan derives item tags + max quality + weapon type on demand.
4. **Scheduler** (`06`): the heartbeat + selection pipeline + final validation + emission
   (say/whisper/emote) + metrics; the one pcall-guarded hot path.
5. **Commands** (`07`) + **boot** (`08`): operator control and wiring.

## Deliberately NOT doing (v1)
Per-NPC AIUpdate scanners; `WORLD_EVENT_ON_UPDATE` polling; an equipment cache; any
client-authoritative behavior; SmartAI/`creature_text` for personalized lines; worldserver
core patches; any client patch; non-enUS locales; custom creature/spell IDs.

## Guessed / needs verification before shipping
- **S1 (the server's actual engine build)** — UNVERIFIED for this server; pinned to public
  Eluna. Owner confirms (SOURCES.md).
- **Guard creature entries** (68/5595/4262/3296/3084/5624) and **zone IDs** — best-effort;
  verify via `sql/verify_ids.sql` and `.gps`. Wrong values are inert, not fatal.
- Live behavior of `WorldDBQuery` result objects, emission visibility, and `IsTaxi()`
  semantics — confirmed only by the in-game matrix (TESTPLAN).
