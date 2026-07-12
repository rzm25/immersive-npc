-- ============================================================================
-- lua-immersive-npc-chat — eligibility / profiling pass (2026-07-12)
--
-- WHY: an NPC only ever speaks if its ENTRY has a profile row for the location it
-- stands in. `.inm force self` returning NO_NEARBY_NPC means there is no *registered*
-- profiled NPC in range. This file profiles the NPCs the owner reported silent, plus
-- broad sweeps for whole roles (vendors) and the Dalaran factions.
--
-- IDEMPOTENT: every row this file writes carries a `comment` beginning 'inm-auto:'.
-- We delete exactly those first, so re-running is safe and never touches the hand-seeded
-- profiles (ids 1..6 etc.).
--
-- ── TWO THINGS TO VERIFY ON YOUR CORE (I cannot run SQL from the sandbox) ──────────
--  1. `creature.id1` is the spawn's entry column on current AzerothCore. If your core
--     predates the multi-spawn refactor it is `creature.id` — swap `c.id1` -> `c.id`.
--     Quick check:  SHOW COLUMNS FROM `creature` LIKE 'id%';
--  2. VENDOR SWEEP HOOK COST: profiling every vendor-flagged entry on maps 0/1/571
--     means the mod registers ON_ADD/ON_REMOVE for each such entry (cheap: it just
--     resolves location and early-outs off-city). If `.inm status` registryNPCs looks
--     alarming or you see load cost, delete the 'inm-auto:vendor' rows and keep only
--     the named vendors. Gauge it, don't guess.
--
-- Role bit VALUES used here (role_mask_lo; see inc_base.sql mirror):
--   CITIZEN=128  VENDOR=4  SUNREAVER=65536  VIOLET_HOLD=131072
--   SKYREAVER=262144  SKYBREAKER=524288
-- Locations: 7 = Dalaran, 8 = Darkshire.
-- ============================================================================

DELETE FROM `immersive_npc_chat_npc_profile` WHERE `comment` LIKE 'inm-auto:%';

-- ── Darkshire named NPCs (loc 8) — draw the existing Darkshire CITIZEN pool ─────────
-- Town Crier 4185, Watcher Keefer 5965, Cmdr Althea Ebonlocke 4194, Watcher Ladimore 4211.
-- (Entry derived from the spawn guid; entry-wildcard profile so every spawn speaks.)
INSERT INTO `immersive_npc_chat_npc_profile`
  (`creature_entry`,`creature_guid`,`location_id`,`role_mask_lo`,`role_mask_hi`,`max_speak_distance`,`allow_personal_lines`,`enabled`,`comment`)
SELECT DISTINCT c.id1, 0, 8, 128, 0, 22, 0, 1, 'inm-auto:darkshire-named'
FROM `creature` c
WHERE c.guid IN (4185, 5965, 4194, 4211);

-- ── Dalaran named NPCs (loc 7) — draw the existing Dalaran CITIZEN pool ─────────────
INSERT INTO `immersive_npc_chat_npc_profile`
  (`creature_entry`,`creature_guid`,`location_id`,`role_mask_lo`,`role_mask_hi`,`max_speak_distance`,`allow_personal_lines`,`enabled`,`comment`)
SELECT DISTINCT c.id1, 0, 7, 128, 0, 22, 0, 1, 'inm-auto:dalaran-named'
FROM `creature` c
WHERE c.guid IN (111691, 112609, 111283, 112852, 112052, 112385, 102700, 111858,
                 112329, 112965, 111461, 108843, 112522, 112928, 111374, 112194, 1823);

-- ── Aerith Primrose 102033 (flower vendor) + all vendor-flag NPCs → VENDOR role ─────
-- Named flower vendor first (so she is covered even if the sweep is later removed):
INSERT INTO `immersive_npc_chat_npc_profile`
  (`creature_entry`,`creature_guid`,`location_id`,`role_mask_lo`,`role_mask_hi`,`max_speak_distance`,`allow_personal_lines`,`enabled`,`comment`)
SELECT DISTINCT c.id1, 0, 7, 4, 0, 20, 0, 1, 'inm-auto:vendor-named'
FROM `creature` c
WHERE c.guid IN (102033);

-- Broad sweep: every vendor-flagged entry (npcflag bit 128) spawned on a map that hosts
-- one of our locations, profiled VENDOR into each location on that map. Runtime
-- ResolveLocation registers ONLY the spawns actually standing in a location, so the
-- cross-join over-generation is inert (see caveat #2 above).
INSERT INTO `immersive_npc_chat_npc_profile`
  (`creature_entry`,`creature_guid`,`location_id`,`role_mask_lo`,`role_mask_hi`,`max_speak_distance`,`allow_personal_lines`,`enabled`,`comment`)
SELECT DISTINCT c.id1, 0, L.id, 4, 0, 20, 0, 1, 'inm-auto:vendor'
FROM `creature` c
JOIN `creature_template` ct ON ct.entry = c.id1
JOIN `immersive_npc_chat_location` L ON L.map_id = c.map
WHERE (ct.npcflag & 128) <> 0;

-- ── Dalaran factions (loc 7), each its own role. Name-prefix match, bounded to the
-- Northrend map (571); ResolveLocation keeps only the Dalaran spawns. Explicit guids
-- the owner listed are unioned in so they are covered even if a name differs. ─────────

-- Sunreaver Guardians (SUNREAVER = 65536)
INSERT INTO `immersive_npc_chat_npc_profile`
  (`creature_entry`,`creature_guid`,`location_id`,`role_mask_lo`,`role_mask_hi`,`max_speak_distance`,`allow_personal_lines`,`enabled`,`comment`)
SELECT DISTINCT c.id1, 0, 7, 65536, 0, 22, 0, 1, 'inm-auto:sunreaver'
FROM `creature` c
JOIN `creature_template` ct ON ct.entry = c.id1
WHERE (c.map = 571 AND ct.name LIKE 'Sunreaver%')
   OR c.guid IN (102417,102427,102434,102428,102420,102430,116668,119054,
                 102432,102429,102425,102426,102431,102418,102419);

-- Violet Hold Guards (VIOLET_HOLD = 131072) — their lines are level-gated 75+ in content.
INSERT INTO `immersive_npc_chat_npc_profile`
  (`creature_entry`,`creature_guid`,`location_id`,`role_mask_lo`,`role_mask_hi`,`max_speak_distance`,`allow_personal_lines`,`enabled`,`comment`)
SELECT DISTINCT c.id1, 0, 7, 131072, 0, 22, 0, 1, 'inm-auto:violethold'
FROM `creature` c
JOIN `creature_template` ct ON ct.entry = c.id1
WHERE (c.map = 571 AND ct.name LIKE 'Violet Hold%')
   OR c.guid IN (114319,114316,114317,114318,114315,114320,114321,114322);

-- Sky-Reavers (Horde/orc, SKYREAVER = 262144)
INSERT INTO `immersive_npc_chat_npc_profile`
  (`creature_entry`,`creature_guid`,`location_id`,`role_mask_lo`,`role_mask_hi`,`max_speak_distance`,`allow_personal_lines`,`enabled`,`comment`)
SELECT DISTINCT c.id1, 0, 7, 262144, 0, 22, 0, 1, 'inm-auto:skyreaver'
FROM `creature` c
JOIN `creature_template` ct ON ct.entry = c.id1
WHERE (c.map = 571 AND (ct.name LIKE 'Sky-Reaver%' OR ct.name LIKE 'Skyreaver%'))
   OR c.guid IN (105878, 53921, 53922, 53919, 53920);

-- Skybreakers (Alliance/human, SKYBREAKER = 524288)
INSERT INTO `immersive_npc_chat_npc_profile`
  (`creature_entry`,`creature_guid`,`location_id`,`role_mask_lo`,`role_mask_hi`,`max_speak_distance`,`allow_personal_lines`,`enabled`,`comment`)
SELECT DISTINCT c.id1, 0, 7, 524288, 0, 22, 0, 1, 'inm-auto:skybreaker'
FROM `creature` c
JOIN `creature_template` ct ON ct.entry = c.id1
WHERE (c.map = 571 AND (ct.name LIKE 'Skybreaker%' OR ct.name LIKE 'Sky-Breaker%'))
   OR c.guid IN (105358, 53924, 53923, 53925, 53926);
