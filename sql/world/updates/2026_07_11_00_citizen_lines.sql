-- ============================================================================
-- lua-immersive-npc-chat — CITIZEN content pass: medieval-townsfolk small talk.
-- Idempotent (clears id range 101..199, then inserts).
--
-- Role: CITIZEN (npc_role_mask_lo = 128, i.e. bit position 7). Profile townsfolk/
-- commoner creatures with role_mask_lo = 128 and they draw ONLY these lines (guards,
-- role_mask_lo = 1, never match). location_mask = 126 = cities 1..6 (SW+IF+Darn+Org+
-- TB+UC) but NOT Dalaran (loc 7) — Dalaran has its own arcane content, so a Dalaran
-- mage never says "have you seen my hen?".
--
-- cooldown_group: 7 weather  8 livestock/harvest  9 gossip  10 greetings  11 class/race/gear
-- Column order:
--  id, location_mask, role_lo, role_hi, class_mask, race_mask, team_mask,
--  item_lo, item_hi, min_quality, cooldown_group, weight, chat_mode, locale, text, enabled
-- ============================================================================

DELETE FROM `immersive_npc_chat_line` WHERE `id` BETWEEN 101 AND 199;
INSERT INTO `immersive_npc_chat_line`
  (`id`,`location_mask`,`npc_role_mask_lo`,`npc_role_mask_hi`,`class_mask`,`race_mask`,`team_mask`,
   `required_item_tags_lo`,`required_item_tags_hi`,`min_item_quality`,`cooldown_group`,`weight`,`chat_mode`,`locale`,`text`,`enabled`) VALUES
  -- 7: weather / season
  (101,126,128,0,0,0,0, 0,0,0, 7,100,0,'enUS','Fine weather for it, eh? The crops''ll be glad of the sun.',1),
  (102,126,128,0,0,0,0, 0,0,0, 7,100,0,'enUS','Rain''s coming, mark my words. My knee never lies.',1),
  (103,126,128,0,0,0,0, 0,0,0, 7, 90,0,'enUS','Cold enough to freeze the well again. Mind your step.',1),
  (104,126,128,0,0,0,0, 0,0,0, 7,100,0,'enUS','A fair morning to you, {race}.',1),
  -- 8: livestock / harvest
  (105,126,128,0,0,0,0, 0,0,0, 8,100,0,'enUS','Have you seen my hen? Brown thing, foul temper. Wanders off daily.',1),
  (106,126,128,0,0,0,0, 0,0,0, 8, 90,0,'enUS','The chickens won''t lay in this heat. Stubborn birds.',1),
  (107,126,128,0,0,0,0, 0,0,0, 8, 90,0,'enUS','Mind the geese by the water — they''ll have your fingers.',1),
  (108,126,128,0,0,0,0, 0,0,0, 8,100,0,'enUS','The grain hauls came in light this season. Millers are grumbling.',1),
  (109,126,128,0,0,0,0, 0,0,0, 8, 90,0,'enUS','Flour''s dear this month. Everything''s dear this month.',1),
  (110,126,128,0,0,0,0, 0,0,0, 8, 90,0,'enUS','Hauled sacks since dawn. My back''s not what it was.',1),
  -- 9: gossip / the king
  (111,126,128,0,0,0,0, 0,0,0, 9, 90,0,'enUS','They say the king''s advisors can''t agree on the time of day.',1),
  (112,126,128,0,0,0,0, 0,0,0, 9, 90,0,'enUS','Heard there''s trouble at the border again. Always is.',1),
  (113,126,128,0,0,0,0, 0,0,0, 9, 90,0,'enUS','The nobles feast while we count coppers. Same as ever.',1),
  (114,126,128,0,0,0,0, 0,0,0, 9,100,0,'enUS','Word is a hero passed through. Suppose that''d be you, {race}?',1),
  (115,126,128,0,0,0,0, 0,0,0, 9, 80,0,'enUS','Taxes up again. A hero wouldn''t notice, but we feel it.',1),
  -- 10: greetings / small talk
  (116,126,128,0,0,0,0, 0,0,0,10,100,0,'enUS','Good day to you. Mind how you go.',1),
  (117,126,128,0,0,0,0, 0,0,0,10, 80,0,'enUS','Spare a kind word for an honest worker?',1),
  (118,126,128,0,0,0,0, 0,0,0,10,100,0,'enUS','Bless you, traveller. Safe roads.',1),
  (119,126,128,0,0,0,0, 0,0,0,10, 80,0,'enUS','Don''t mind me, just resting my feet a moment.',1),
  (120,126,128,0,0,0,0, 0,0,0,10, 90,0,'enUS','Busy day at market. Everyone wants everything at once.',1),
  (121,126,128,0,0,0,0, 0,0,0,10, 90,0,'enUS','You''ll want the inn if you''re after a bed. Just down the way.',1),
  (122,126,128,0,0,0,0, 0,0,0,10, 90,0,'enUS','Watch your purse in the crowd, friend. Cutpurses about.',1),
  (123,126,128,0,0,0,0, 0,0,0,10, 90,0,'enUS','Another day, another copper. Such is life.',1),
  (124,126,128,0,0,0,0, 0,0,0,10, 80,0,'enUS','The bells ring soon. Best be about my errands.',1),
  (125,126,128,0,0,0,0, 0,0,0,10, 90,0,'enUS','Ah, to be young and off seeing the world, like you.',1),
  -- 11: class / race / gear (gear lines gate on an equipped weapon or quality)
  (126,126,128,0,0,0,0, 0,0,0,11, 90,0,'enUS','A {class}, are you? We don''t see many of your sort round here.',1),
  (127,126,128,0,0,0,0, 0,0,4,11, 80,0,'enUS','That''s fine armor for a common street, {race}. Off adventuring?',1),
  (128,126,128,0,0,0,0, 1,0,0,11, 90,0,'enUS','Careful swinging that {weapon_type} about — you''ll frighten the little ones.',1),
  (129,126,128,0,0,0,0, 0,0,0,11, 90,0,'enUS','A {race} in these parts? Well, times are changing.',1),
  (130,126,128,0,0,0,0, 0,0,0,11, 90,0,'enUS','You''ve the look of someone with somewhere to be, {class}.',1),
  (131,126,128,0,0,0,0, 1,0,0,11, 80,0,'enUS','Best keep that {weapon_type} sheathed near the stalls, aye?',1),
  (132,126,128,0,0,0,0, 0,0,0,11, 90,0,'enUS','Off to slay something dreadful, no doubt. Rather you than me, {race}.',1);
