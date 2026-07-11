-- ============================================================================
-- lua-immersive-npc-chat — Darkshire (Duskwood) as location 8, + its content.
-- Idempotent: re-inserts location id 8 and line id range 301..399.
--
-- Darkshire is a small, embattled Alliance town in Duskwood (map 0, zone 10), under
-- constant threat from the Scourge, worgen and restless dead. Its townsfolk are
-- fearful and jumpy but POLITE — short, endearing quips: startled greetings, nervous
-- (never hostile) manners toward the Horde, wide-eyed remarks at very tall races, and
-- quiet hope that a passing hero will keep them safe. Fewer NPCs than a capital, so
-- fewer lines.
--
-- location_mask = 256 (= 1<<8). role CITIZEN (128) — profile Darkshire townsfolk with
-- role_mask_lo = 128 for location 8 and they draw only these lines.
-- cooldown_group: 15 startled/greeting  16 night/dread  17 faction/race nerves
-- ============================================================================

DELETE FROM `immersive_npc_chat_location` WHERE `id` = 8;
INSERT INTO `immersive_npc_chat_location`
  (`id`,`name`,`map_id`,`zone_id`,`area_id`,`enabled`,`min_interval_ms`,`max_lines_per_10min`,`comment`) VALUES
  (8,'Darkshire',0,10,0,1,60000,12,'Town in Duskwood (verify zone 10 with .gps)');

DELETE FROM `immersive_npc_chat_line` WHERE `id` BETWEEN 301 AND 399;
INSERT INTO `immersive_npc_chat_line`
  (`id`,`location_mask`,`npc_role_mask_lo`,`npc_role_mask_hi`,`class_mask`,`race_mask`,`team_mask`,
   `required_item_tags_lo`,`required_item_tags_hi`,`min_item_quality`,`cooldown_group`,`weight`,`chat_mode`,`locale`,`text`,`enabled`) VALUES
  -- 15: startled greetings
  (301,256,128,0,0,0,0, 0,0,0,15,100,0,'enUS','Oh! You startled me. Forgive an old worrier.',1),
  (302,256,128,0,0,0,0, 0,0,0,15,100,0,'enUS','Light preserve us — oh, it''s only you. Welcome, {race}.',1),
  (303,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','A visitor! We don''t get many brave enough for Darkshire.',1),
  (304,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','Bless you for coming. It''s been a fearful season, truly.',1),
  (305,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','Good day — oh, do forgive my nerves. One learns to jump, here.',1),
  (306,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','You gave me a fright! But a friendly face is always welcome.',1),
  -- 17: wide-eyed remarks at tall races
  (307,256,128,0,0,1024,0, 0,0,0,17,100,0,'enUS','Oh! You startled me. Such a tall draenei — a pleasure, truly.',1),
  (308,256,128,0,0,32,0,   0,0,0,17,100,0,'enUS','Goodness, a tauren! So very tall. N-nice to meet you, honestly.',1),
  (309,256,128,0,0,128,0,  0,0,0,17,100,0,'enUS','Oh — a troll! No trouble, I hope. Only manners here, I promise.',1),
  (310,256,128,0,0,8,0,    0,0,0,17, 90,0,'enUS','A night elf, abroad in daylight? These are strange times indeed.',1),
  -- 17: nervous but polite toward the Horde (team 2 = Horde players)
  (311,256,128,0,0,0,2, 0,0,0,17,100,0,'enUS','We want no trouble. Alliance we may be, but no enemy of yours.',1),
  (312,256,128,0,0,0,2, 0,0,0,17, 90,0,'enUS','P-please, we''re just simple folk. No quarrel with the Horde here.',1),
  (313,256,128,0,0,0,2, 0,0,0,17, 90,0,'enUS','You''re welcome to pass through, friend. We keep to ourselves.',1),
  -- 16: the dark woods / restless dead
  (314,256,128,0,0,0,0, 0,0,0,16, 90,0,'enUS','Best indoors before dark. The woods... they don''t sleep, you know.',1),
  (315,256,128,0,0,0,0, 0,0,0,16, 80,0,'enUS','Did you hear that? ...No? Only nerves. Pay me no mind.',1),
  (316,256,128,0,0,0,0, 0,0,0,16, 90,0,'enUS','Stay to the lit paths. Duskwood keeps its secrets in the shadow.',1),
  (317,256,128,0,0,0,0, 0,0,0,16, 90,0,'enUS','The nights are long here. Longer still when the dead don''t rest.',1),
  (318,256,128,0,0,0,0, 0,0,0,16, 90,0,'enUS','Mind the graveyard, {race}. Some who lie there don''t always stay.',1),
  -- 15: quiet hope in the passing hero
  (319,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','A {class}, thank the Light. We could use a stout heart round here.',1),
  (320,256,128,0,0,0,0, 0,0,0,15, 80,0,'enUS','You''ll keep us safe if it comes to it, won''t you? Please say you will.',1),
  (321,256,128,0,0,0,0, 1,0,0,15, 80,0,'enUS','Keep that {weapon_type} close after sundown. You''ll want it.',1),
  (322,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','Fine armor. Are you here to help? Oh, say you''re here to help us.',1);
