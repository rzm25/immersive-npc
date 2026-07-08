-- ============================================================================
-- lua-immersive-npc-chat — seed: six faction-hub locations + one guard profile each.
-- Idempotent (DELETE the seeded id ranges, then INSERT with explicit ids).
--
-- ZONE IDs are 3.3.5a client constants (stable across cores) but VERIFY in-game with
-- `.gps` in each city and correct if your build differs (workspace gotcha #1). area_id
-- 0 = whole zone (v1); district area-ids are a v2 refinement.
--
-- CREATURE ENTRIES below are the well-known capital-guard entries. They are
-- operator-tunable: a wrong/absent entry simply means that city's guards never speak
-- (no error), and `.inm status` / `.inm where` will show it. Confirm or extend with:
--   SELECT entry,name FROM creature_template WHERE name LIKE '%Guard%' OR name LIKE '%Sentinel%';
-- role_mask_lo = 1  => role GUARD (bit position 0). See inc_base.sql bit mirror.
-- ============================================================================

DELETE FROM `immersive_npc_chat_location` WHERE `id` BETWEEN 1 AND 6;
INSERT INTO `immersive_npc_chat_location`
  (`id`,`name`,`map_id`,`zone_id`,`area_id`,`enabled`,`min_interval_ms`,`max_lines_per_10min`,`comment`) VALUES
  (1,'Stormwind',   0,1519,0,1,120000,6,'Alliance capital (verify zone 1519 with .gps)'),
  (2,'Ironforge',   0,1537,0,1,120000,6,'Alliance capital (verify zone 1537)'),
  (3,'Darnassus',   1,1657,0,1,120000,6,'Alliance capital (verify zone 1657)'),
  (4,'Orgrimmar',   1,1637,0,1,120000,6,'Horde capital (verify zone 1637)'),
  (5,'Thunder Bluff',1,1638,0,1,120000,6,'Horde capital (verify zone 1638)'),
  (6,'Undercity',   0,1497,0,1,120000,6,'Horde capital (verify zone 1497)');

DELETE FROM `immersive_npc_chat_npc_profile` WHERE `id` BETWEEN 1 AND 6;
INSERT INTO `immersive_npc_chat_npc_profile`
  (`id`,`creature_entry`,`creature_guid`,`location_id`,`role_mask_lo`,`role_mask_hi`,`max_speak_distance`,`allow_personal_lines`,`enabled`,`comment`) VALUES
  (1,  68,0,1,1,0,22,1,1,'Stormwind City Guard (verify entry 68)'),
  (2,5595,0,2,1,0,22,1,1,'Ironforge Guard (verify entry 5595)'),
  (3,4262,0,3,1,0,22,1,1,'Darnassus Sentinel (verify entry 4262)'),
  (4,3296,0,4,1,0,22,1,1,'Orgrimmar Grunt (verify entry 3296)'),
  (5,3084,0,5,1,0,22,1,1,'Bluffwatcher (verify entry 3084)'),
  (6,5624,0,6,1,0,22,1,1,'Undercity Guardian (verify entry 5624)');
