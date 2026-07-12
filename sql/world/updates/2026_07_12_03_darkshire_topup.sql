-- ============================================================================
-- lua-immersive-npc-chat — Darkshire (loc 8) content top-up.
-- Idempotent: clears line id range 323..380, then inserts.
--
-- Continues the Darkshire CITIZEN pool (role 128, location_mask 256): tentative,
-- cautious, but polite — short but sweet. Brings the town toward ~40 lines (target 50).
-- cooldown_group: 15 startled/greeting · 16 night/dread · 17 faction/race nerves.
-- ============================================================================

DELETE FROM `immersive_npc_chat_line` WHERE `id` BETWEEN 323 AND 380;
INSERT INTO `immersive_npc_chat_line`
  (`id`,`location_mask`,`npc_role_mask_lo`,`npc_role_mask_hi`,`class_mask`,`race_mask`,`team_mask`,
   `required_item_tags_lo`,`required_item_tags_hi`,`min_item_quality`,`cooldown_group`,`weight`,`chat_mode`,`locale`,`text`,`enabled`) VALUES
  (323,256,128,0,0,0,0, 0,0,0,15,100,0,'enUS','Oh — hello there. Do come in off the road, it''s safer.',1),
  (324,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','A friendly face! You don''t know how rare that is these days.',1),
  (325,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','Mind how you go, {race}. And... thank you for stopping.',1),
  (326,256,128,0,0,0,0, 0,0,0,16, 80,0,'enUS','Was that a wolf? ...I do hope that was a wolf.',1),
  (327,256,128,0,0,0,0, 0,0,0,16, 90,0,'enUS','Lock your shutters after dusk. We all do, here.',1),
  (328,256,128,0,0,0,0, 0,0,0,16, 80,0,'enUS','The lamplighter''s late again. I don''t like the dark. I don''t.',1),
  (329,256,128,0,0,0,0, 0,0,0,16, 80,0,'enUS','They say something moved in the old orchard. I don''t go there now.',1),
  (330,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','You''ve a kind look about you, {class}. That eases my heart a little.',1),
  (331,256,128,0,0,0,0, 0,0,0,15, 80,0,'enUS','Stay for a meal, if you like. Company keeps the fear at bay.',1),
  (332,256,128,0,0,0,0, 0,0,0,17, 90,0,'enUS','A {race}? Goodness. Well — you''re very welcome, of course.',1),
  (333,256,128,0,0,0,0, 0,0,0,16, 80,0,'enUS','Hush — did you hear it too? ...No? Just the wind. Just the wind.',1),
  (334,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','Bless you for passing through. It gets lonely behind these walls.',1),
  (335,256,128,0,0,0,0, 0,0,0,16, 90,0,'enUS','Don''t stray from the road, please. Duskwood swallows the careless.',1),
  (336,256,128,0,0,0,0, 0,0,0,15, 80,0,'enUS','You carry yourself like someone who''s seen a fight. That''s a comfort.',1),
  (337,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','Careful out there. And... come back safe, won''t you?',1),
  (338,256,128,0,0,0,0, 0,0,0,16, 80,0,'enUS','The candles gutter for no reason some nights. I try not to think on it.',1),
  (339,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','A traveller with steel and steady hands. Light be praised.',1),
  (340,256,128,0,0,0,0, 0,0,0,17, 90,0,'enUS','No trouble, I hope? We keep the peace here, best we can.',1),
  (341,256,128,0,0,0,0, 0,0,0,16, 80,0,'enUS','Some nights the fog comes right to the door. I sit up till dawn.',1),
  (342,256,128,0,0,0,0, 0,0,0,15, 90,0,'enUS','Kind of you to ask after us. We manage. We always have.',1);
