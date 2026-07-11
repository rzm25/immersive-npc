-- ============================================================================
-- lua-immersive-npc-chat — Dalaran (Northrend) as location 7, + its content.
-- Idempotent: re-inserts location id 7 and line id range 201..299.
--
-- Dalaran is the neutral floating city of the Kirin Tor (map 571, zone 4395).
-- Content is deliberately MOSTLY small talk / polite greetings / references to the
-- visitor's class/race/gear, with a MINORITY of lore lines (lower weight, so they
-- surface rarely) touching Kirin Tor / Antonidas / the fall of old Dalaran to
-- Archimonde / the Violet Hold / Rhonin / the war on the Lich King.
--
-- location_mask = 128 (= 1<<7, Dalaran only). Lines use role 0 (any), so profile
-- Dalaran NPCs (Kirin Tor mages, Silver Covenant / Sunreaver, citizens) with role
-- CITIZEN (role_mask_lo = 128): they then match ONLY these Dalaran lines — never the
-- guard lines (role 1) or the townsfolk lines (location_mask 126 excludes Dalaran).
-- cooldown_group: 12 greetings/small talk  13 arcane/gear  14 lore (rarer)
-- ============================================================================

DELETE FROM `immersive_npc_chat_location` WHERE `id` = 7;
INSERT INTO `immersive_npc_chat_location`
  (`id`,`name`,`map_id`,`zone_id`,`area_id`,`enabled`,`min_interval_ms`,`max_lines_per_10min`,`comment`) VALUES
  (7,'Dalaran',571,4395,0,1,20000,30,'Kirin Tor floating city, Northrend (verify zone 4395 with .gps)');

DELETE FROM `immersive_npc_chat_line` WHERE `id` BETWEEN 201 AND 299;
INSERT INTO `immersive_npc_chat_line`
  (`id`,`location_mask`,`npc_role_mask_lo`,`npc_role_mask_hi`,`class_mask`,`race_mask`,`team_mask`,
   `required_item_tags_lo`,`required_item_tags_hi`,`min_item_quality`,`cooldown_group`,`weight`,`chat_mode`,`locale`,`text`,`enabled`) VALUES
  -- 12: greetings / small talk (the bulk)
  (201,128,0,0,0,0,0, 0,0,0,12,100,0,'enUS','Welcome to Dalaran, {race}. Mind the wards — they bite the careless.',1),
  (202,128,0,0,0,0,0, 0,0,0,12,100,0,'enUS','Greetings, traveller. The Eventide is lovely at this hour.',1),
  (203,128,0,0,0,0,0, 0,0,0,12, 90,0,'enUS','A good day beneath the violet dome, wouldn''t you say?',1),
  (204,128,0,0,0,0,0, 0,0,0,12,100,0,'enUS','Fresh from the world below, {race}? The city floats far from home.',1),
  (205,128,0,0,0,0,0, 0,0,0,12, 80,0,'enUS','Tea? No? More for me, then.',1),
  (206,128,0,0,0,0,0, 0,0,0,12, 90,0,'enUS','Stay a while. Dalaran rewards the curious.',1),
  (207,128,0,0,0,0,0, 0,0,0,12, 90,0,'enUS','Another {race} seeking their fortune. The city welcomes you.',1),
  (208,128,0,0,0,0,0, 0,0,0,12, 90,0,'enUS','Good day to you. Do try not to wander into a portal.',1),
  (209,128,0,0,0,0,0, 0,0,0,12, 80,0,'enUS','The Legerdemain pours a fine wine, if you''ve the coin.',1),
  (210,128,0,0,0,0,0, 0,0,0,12, 90,0,'enUS','You''ll find no finer libraries in all the world.',1),
  (211,128,0,0,0,0,0, 0,0,0,12, 90,0,'enUS','Don''t look down. The city floats, and the ground is very far.',1),
  (212,128,0,0,0,0,0, 0,0,0,12, 90,0,'enUS','Books, scrolls, reagents — we trade in wonders here.',1),
  (213,128,0,0,0,0,0, 0,0,0,12, 90,0,'enUS','New apprentices arrive daily. The halls have never been busier.',1),
  (214,128,0,0,0,0,0, 0,0,0,12, 90,0,'enUS','If you seek the Violet Citadel, mind your manners inside.',1),
  (215,128,0,0,0,0,0, 0,0,0,12,100,0,'enUS','Welcome, welcome. Mind the enchantments and enjoy your stay, {race}.',1),
  -- 13: arcane flavor + gear (gear lines gate on weapon / quality)
  (216,128,0,0,0,0,0, 0,0,0,13, 90,0,'enUS','The arcane hums strong today. Can you feel it?',1),
  (217,128,0,0,0,0,0, 0,0,0,13, 90,0,'enUS','Watch your step near the portals. We lose a tourist most weeks.',1),
  (218,128,0,0,0,0,0, 0,0,0,13, 80,0,'enUS','Mind the mages muttering to themselves — usually harmless.',1),
  (219,128,0,0,0,0,0, 0,0,0,13, 80,0,'enUS','Arcane wards, a flying city — and still the tea goes cold.',1),
  (220,128,0,0,0,0,0, 0,0,0,13, 80,0,'enUS','The magi keep us aloft. Best not ask how.',1),
  (221,128,0,0,0,0,0, 0,0,0,13, 80,0,'enUS','The dome keeps the weather out. Small mercies.',1),
  (222,128,0,0,0,0,0, 0,0,0,13, 80,0,'enUS','Mind the sewers below — not everything down there is friendly.',1),
  (223,128,0,0,0,0,0, 1,0,0,13, 90,0,'enUS','Careful with that {weapon_type} indoors, {race}. This is a city of scholars.',1),
  (224,128,0,0,0,0,0, 0,0,3,13, 90,0,'enUS','Lovely enchantment on that gear, {race}. Dalaran work, perhaps?',1),
  (225,128,0,0,0,0,0, 0,0,4,13, 80,0,'enUS','Such finery. You''ve done well for yourself out there, {race}.',1),
  -- class / race nods (small talk, group 12)
  (226,128,0,0,0,0,0, 0,0,0,12, 90,0,'enUS','A {class} walks among us. How refreshing.',1),
  (227,128,0,0,0,0,0, 0,0,0,12, 90,0,'enUS','You carry yourself well for one so far from home, {race}.',1),
  (228,128,0,0,0,0,0, 0,0,0,12, 80,0,'enUS','You''ve the look of the battlefield about you. Rest a while.',1),
  (229,128,0,0,0,0,0, 0,0,0,12, 80,0,'enUS','A hero, are you? We get a few. Do try not to break anything.',1),
  (230,128,0,0,0,0,0, 0,0,0,12, 80,0,'enUS','The magi could learn a thing from a seasoned {class}, I''d wager.',1),
  -- 14: LORE — minority, low weight so it surfaces rarely
  (231,128,0,0,0,0,0, 0,0,0,14, 35,0,'enUS','The Kirin Tor watch over us all. Six minds, one purpose.',1),
  (232,128,0,0,0,0,0, 0,0,0,14, 35,0,'enUS','Old Dalaran fell to Archimonde''s fire. This city rose from that grief.',1),
  (233,128,0,0,0,0,0, 0,0,0,14, 35,0,'enUS','They say Antonidas himself once walked these halls. A great loss, his.',1),
  (234,128,0,0,0,0,0, 0,0,0,14, 35,0,'enUS','We raised the city and flew it north to face the Lich King. Bold days.',1),
  (235,128,0,0,0,0,0, 0,0,0,14, 35,0,'enUS','The Violet Hold keeps darker things than you''d care to meet, {race}.',1),
  (236,128,0,0,0,0,0, 0,0,0,14, 35,0,'enUS','Archmage Rhonin leads the Kirin Tor now. A dragon''s pupil, they whisper.',1),
  (237,128,0,0,0,0,0, 0,0,0,14, 35,0,'enUS','Silver Covenant or Sunreaver — we all breathe the same arcane air. Mostly.',1),
  (238,128,0,0,0,0,0, 0,0,0,14, 30,0,'enUS','Lady Proudmoore studied under Antonidas, once. Before it all.',1),
  (239,128,0,0,0,0,0, 0,0,0,14, 30,0,'enUS','The Council of Six speaks, and the city listens. Wise to do the same.',1),
  (240,128,0,0,0,0,0, 0,0,0,14, 30,0,'enUS','The Legion, the Scourge, the Lich King — Dalaran has weathered every storm.',1);
