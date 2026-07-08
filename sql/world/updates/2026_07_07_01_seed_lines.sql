-- ============================================================================
-- lua-immersive-npc-chat — seed: 36 guard chat lines (v1 content pass).
-- Idempotent: clears id range 1..100 then inserts explicit ids.
--
-- All lines target role GUARD (npc_role_mask_lo = 1) because every seeded profile is
-- a guard. Tone: friendly / neutral / cautious. Placeholders are whitelist-only
-- ({player} {class} {race} {weapon_type}) and injection-safe (see CONTENT_GUIDE.md).
-- Apostrophes are doubled ('') per workspace gotcha #6.
--
-- cooldown_group: 1 greeting  2 equipment  3 class  4 faction/place  5 warning  6 gesture
-- Column order:
--  id, location_mask, role_lo, role_hi, class_mask, race_mask, team_mask,
--  item_lo, item_hi, min_quality, cooldown_group, weight, chat_mode, locale, text, enabled
-- ============================================================================

DELETE FROM `immersive_npc_chat_line` WHERE `id` BETWEEN 1 AND 100;
INSERT INTO `immersive_npc_chat_line`
  (`id`,`location_mask`,`npc_role_mask_lo`,`npc_role_mask_hi`,`class_mask`,`race_mask`,`team_mask`,
   `required_item_tags_lo`,`required_item_tags_hi`,`min_item_quality`,`cooldown_group`,`weight`,`chat_mode`,`locale`,`text`,`enabled`) VALUES
  -- group 1: greetings (say)
  (1, 0,1,0,0,0,0, 0,0,0, 1,100,0,'enUS','Well met, {race}. Keep to the roads and you''ll have no trouble here.',1),
  (2, 0,1,0,0,0,0, 0,0,0, 1,100,0,'enUS','Move along, citizen. The watch has its eyes open.',1),
  (3, 0,1,0,0,0,0, 0,0,0, 1, 90,0,'enUS','Stay sharp, {class}. These are uneasy times.',1),
  (4, 0,1,0,0,0,0, 0,0,0, 1, 70,0,'enUS','Another {race} in the city? Good — we can use steady hands.',1),
  (5, 0,1,0,0,0,0, 0,0,0, 1, 80,0,'enUS','Mind yourself in the crowds, {race}.',1),
  -- group 2: equipment-aware (require item tags / quality)
  (6, 0,1,0,0,0,0, 1,0,0, 2, 90,0,'enUS','That {weapon_type} of yours has seen use, I''d wager.',1),
  (7, 0,1,0,0,0,0, 0,0,4, 2, 90,0,'enUS','Fine gear, {class}. You''ve earned your place.',1),
  (8, 0,1,0,0,0,0, 4,0,0, 2, 90,0,'enUS','A shield-bearer. You''d make a fine addition to the watch.',1),
  (9, 0,1,0,0,0,0, 2,0,0, 2, 80,0,'enUS','Mind that big blade indoors, {race}.',1),
  (10,0,1,0,0,0,0, 16,0,0,2, 80,0,'enUS','Plate and steel — a proper soldier''s kit.',1),
  (11,0,1,0,0,0,0, 8,0,0, 2, 80,0,'enUS','Keep that string dry, {race}. You never know.',1),
  -- group 3: class flavor
  (12,0,1,0,128,0,0, 0,0,0, 3, 80,0,'enUS','A mage in our streets. Try not to set anything alight, hm?',1),
  (13,0,1,0,2,0,0,   0,0,0, 3, 80,0,'enUS','The Light guide you, {race}.',1),
  (14,0,1,0,8,0,0,   0,0,0, 3, 80,0,'enUS','Hands where I can see them, {class}.',1),
  (15,0,1,0,4,0,0,   0,0,0, 3, 80,0,'enUS','Leave the beast outside the bank, would you?',1),
  (16,0,1,0,1,0,0,   0,0,0, 3, 80,0,'enUS','A warrior''s stride. You carry yourself well, {race}.',1),
  (17,0,1,0,16,0,0,  0,0,0, 3, 80,0,'enUS','Blessings, {class}. The wounded will thank you.',1),
  (18,0,1,0,32,0,0,  0,0,0, 3, 70,0,'enUS','...A death knight. We watch your kind closely.',1),
  (19,0,1,0,256,0,0, 0,0,0, 3, 70,0,'enUS','Keep your companions leashed, {class}.',1),
  (20,0,1,0,1024,0,0,0,0,0, 3, 80,0,'enUS','The wilds send us one of their own. Welcome, {race}.',1),
  (21,0,1,0,64,0,0,  0,0,0, 3, 80,0,'enUS','The elements favor you, {class}? We''ll take the luck.',1),
  -- group 4: faction + place flavor
  (22,0,1,0,0,0,1,   0,0,0, 4, 70,0,'enUS','For the Alliance, {race}. Stand tall.',1),
  (23,0,1,0,0,0,2,   0,0,0, 4, 70,0,'enUS','Lok''tar, {race}. Strength and honor.',1),
  (24,2,1,0,0,0,0,   0,0,0, 4, 90,0,'enUS','Welcome to Stormwind, {race}. The king''s peace holds here.',1),
  (25,4,1,0,0,0,0,   0,0,0, 4, 90,0,'enUS','Ironforge welcomes you, {race}. Mind the forge-heat.',1),
  (26,16,1,0,0,0,0,  0,0,0, 4, 90,0,'enUS','Orgrimmar''s gates are open to you, {race}.',1),
  (27,32,1,0,0,0,0,  0,0,0, 4, 90,0,'enUS','Walk gently on the rise, {race}. The winds are watching.',1),
  (28,64,1,0,0,0,0,  0,0,0, 4, 90,0,'enUS','The Dark Lady watches over us, {race}.',1),
  (29,8,1,0,0,0,0,   0,0,0, 4, 90,0,'enUS','Elune guide your steps, {race}.',1),
  -- group 5: warnings
  (30,0,1,0,0,0,0,   0,0,0, 5, 60,0,'enUS','No brawling in the streets, {class}. Take it to the ring.',1),
  (31,0,1,0,0,0,0,   0,0,0, 5, 60,0,'enUS','Watch your purse in the market, {race}.',1),
  -- group 6: personal whispers + text emotes
  (32,0,1,0,0,0,0,   0,0,0, 6, 50,1,'enUS','Psst — fresh goods at the auction house, {race}. You didn''t hear it from me.',1),
  (33,0,1,0,0,0,0,   0,0,0, 6, 50,1,'enUS','Between us, {class}, the quarter''s been jumpy all week.',1),
  (34,0,1,0,0,0,0,   0,0,0, 6, 60,2,'enUS','sizes you up with a soldier''s glance.',1),
  (35,0,1,0,0,0,0,   0,0,0, 6, 60,2,'enUS','nods respectfully as you pass.',1),
  (36,0,1,0,0,0,0,   0,0,0, 6, 50,2,'enUS','snaps to attention as the {race} approaches.',1);
