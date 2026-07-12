-- ============================================================================
-- lua-immersive-npc-chat — Dalaran faction voices (location_mask = 128, loc 7).
-- Idempotent: clears line id range 1000..1399, then inserts.
--
-- Four roles, each its own voice (profiles in 2026_07_12_00_eligibility.sql):
--   SUNREAVER=65536   (Horde-aligned Kirin Tor: terse, assertive, aloof, mysterious)
--   VIOLET_HOLD=131072 (neutral guards: polite, gear-complimenting, "safe travels";
--                       spoken ONLY to level 75+ via min_player_level — the 17-col INSERT)
--   SKYREAVER=262144  (Horde/orc airship crew: gruff, brash, blunt)
--   SKYBREAKER=524288 (Alliance/human airship crew: grandiose, polite, snooty)
--
-- "Opposing faction only" lines use team_mask: to-Alliance = 1, to-Horde = 2.
-- cooldown_group: 29 sunreaver · 30 sunreaver-vs-Alliance · 31 violet-hold ·
--   32 skyreaver · 33 skyreaver-vs-Alliance · 34 skybreaker · 35 skybreaker-vs-Horde.
--
-- STAGED functional tranche (Sunreaver 26, Violet Hold 20, Sky-Reaver 24, Skybreaker 24).
-- Targets: Sunreaver 50+20, Violet Hold 50, Sky-Reaver 20+40, Skybreaker 20+40 — to fill next.
-- ============================================================================

DELETE FROM `immersive_npc_chat_line` WHERE `id` BETWEEN 1000 AND 1399;

-- ── 16-column INSERT: Sunreaver + Sky-Reaver + Skybreaker (no level gate) ──────────
INSERT INTO `immersive_npc_chat_line`
  (`id`,`location_mask`,`npc_role_mask_lo`,`npc_role_mask_hi`,`class_mask`,`race_mask`,`team_mask`,
   `required_item_tags_lo`,`required_item_tags_hi`,`min_item_quality`,`cooldown_group`,`weight`,`chat_mode`,`locale`,`text`,`enabled`) VALUES
  -- 29: SUNREAVER identity (any listener)
  (1000,128,65536,0,0,0,0, 0,0,0,29,100,0,'enUS','Move along, {race}. The Sunreavers keep the peace here.',1),
  (1001,128,65536,0,0,0,0, 0,0,0,29, 90,0,'enUS','We watch. We remember. Mind your conduct in Dalaran.',1),
  (1002,128,65536,0,0,0,0, 0,0,0,29, 90,0,'enUS','Aethas Sunreaver vouches for us. That is all you need know.',1),
  (1003,128,65536,0,0,0,0, 0,0,0,29, 90,0,'enUS','The Kirin Tor tolerate us. Do not test that tolerance.',1),
  (1004,128,65536,0,0,0,0, 0,0,0,29, 80,0,'enUS','Eyes forward, {race}. Nothing here concerns you.',1),
  (1005,128,65536,0,0,0,0, 0,0,0,29, 80,0,'enUS','The Horde has friends in high places now. We are those friends.',1),
  (1006,128,65536,0,0,0,0, 0,0,0,29, 80,0,'enUS','Magic is a blade like any other. We hold ours ready.',1),
  (1007,128,65536,0,0,0,0, 0,0,0,29, 80,0,'enUS','State your business or state nothing at all.',1),
  (1008,128,65536,0,0,0,0, 0,0,0,29, 80,0,'enUS','You are watched, {class}. All are watched. It is nothing personal.',1),
  (1009,128,65536,0,0,0,0, 0,0,0,29, 80,0,'enUS','The Sunreavers answer to Silvermoon, and to none of you.',1),
  (1010,128,65536,0,0,0,0, 0,0,0,29, 80,0,'enUS','Keep your spells sheathed. This is neutral ground, for now.',1),
  (1011,128,65536,0,0,0,0, 0,0,0,29, 80,0,'enUS','We are not your enemy today. See that it stays that way.',1),
  (1012,128,65536,0,0,0,0, 0,0,0,29, 70,0,'enUS','Quiet feet, quieter tongue. That is how one survives Dalaran.',1),
  (1013,128,65536,0,0,0,0, 0,0,0,29, 80,0,'enUS','I have no quarrel with you. Give me no reason to find one.',1),
  (1014,128,65536,0,0,0,0, 0,0,0,29, 70,0,'enUS','The floating city has many secrets. Do not go seeking ours.',1),
  (1015,128,65536,0,0,0,0, 0,0,0,29, 80,0,'enUS','Pass freely, {race}. But know that we are counting.',1),
  (1016,128,65536,0,0,0,0, 0,0,0,29, 70,0,'enUS','Order is a fragile thing here. We are what keeps it whole.',1),
  (1017,128,65536,0,0,0,0, 0,0,0,29, 70,0,'enUS','You wear your allegiance loudly. We wear ours in silence.',1),
  -- 30: SUNREAVER, spoken only to ALLIANCE (team 1)
  (1070,128,65536,0,0,0,1, 0,0,0,30, 90,0,'enUS','An Alliance {race}. How... diplomatic of you to visit.',1),
  (1071,128,65536,0,0,0,1, 0,0,0,30, 90,0,'enUS','We are all Kirin Tor here. Do try to remember that, {race}.',1),
  (1072,128,65536,0,0,0,1, 0,0,0,30, 80,0,'enUS','Smile all you like. I know exactly what you are.',1),
  (1073,128,65536,0,0,0,1, 0,0,0,30, 80,0,'enUS','The Silver Enclave is that way. You would be happier there.',1),
  (1074,128,65536,0,0,0,1, 0,0,0,30, 80,0,'enUS','No trouble from you today, Alliance. That is an order.',1),
  (1075,128,65536,0,0,0,1, 0,0,0,30, 70,0,'enUS','Charming. Now keep walking, {race}.',1),
  (1076,128,65536,0,0,0,1, 0,0,0,30, 80,0,'enUS','We share this city. We do not share my patience. Move along.',1),
  (1077,128,65536,0,0,0,1, 0,0,0,30, 70,0,'enUS','How brave, an Alliance {class} in our quarter. How very brave.',1),
  -- 32: SKY-REAVER identity (Horde/orc airship crew)
  (1200,128,262144,0,0,0,0, 0,0,0,32,100,0,'enUS','Hmph. Another one. State your business, {race}.',1),
  (1201,128,262144,0,0,0,0, 0,0,0,32, 90,0,'enUS','The Horde owns the skies now. Try to keep up.',1),
  (1202,128,262144,0,0,0,0, 0,0,0,32, 80,0,'enUS','Don''t touch the airship. Last fool who did is still falling.',1),
  (1203,128,262144,0,0,0,0, 0,0,0,32, 80,0,'enUS','You lost, {race}? The tavern''s that way. Go on.',1),
  (1204,128,262144,0,0,0,0, 0,0,0,32, 80,0,'enUS','Orgrim''s Hammer flies for the Warchief. Remember that.',1),
  (1205,128,262144,0,0,0,0, 0,0,0,32, 70,0,'enUS','Bah. Too much talking, not enough fighting in this city.',1),
  (1206,128,262144,0,0,0,0, 0,0,0,32, 80,0,'enUS','Stand aside. Reaver business, not yours.',1),
  (1207,128,262144,0,0,0,0, 0,0,0,32, 80,0,'enUS','You want something, {class}? Spit it out. I''ve no time.',1),
  (1208,128,262144,0,0,0,0, 0,0,0,32, 70,0,'enUS','Strong grip, that. Maybe you''re not useless after all.',1),
  (1209,128,262144,0,0,0,0, 0,0,0,32, 80,0,'enUS','We fight. We fly. We don''t chat. Move along.',1),
  (1210,128,262144,0,0,0,0, 0,0,0,32, 70,0,'enUS','Dalaran''s too soft. Give me the deck of a warship any day.',1),
  (1211,128,262144,0,0,0,0, 0,0,0,32, 80,0,'enUS','Lok''tar, {race}. Now clear the landing before I clear it for you.',1),
  -- 33: SKY-REAVER, spoken only to ALLIANCE (team 1) — gruff, backhanded
  (1220,128,262144,0,0,0,1, 0,0,0,33, 90,0,'enUS','An Alliance {race}. Charmed. Now don''t linger.',1),
  (1221,128,262144,0,0,0,1, 0,0,0,33, 80,0,'enUS','You fight well, for one of yours. There. A compliment. Happy?',1),
  (1222,128,262144,0,0,0,1, 0,0,0,33, 80,0,'enUS','Brave of the Alliance to send a {class} up here. Or foolish.',1),
  (1223,128,262144,0,0,0,1, 0,0,0,33, 80,0,'enUS','Nice armor. Shame about the colors.',1),
  (1224,128,262144,0,0,0,1, 0,0,0,33, 70,0,'enUS','We''re not fighting today, {race}. Pity. I was getting comfortable.',1),
  (1225,128,262144,0,0,0,1, 0,0,0,33, 80,0,'enUS','You''ve some spine, Alliance. I''ll grant you that and no more.',1),
  (1226,128,262144,0,0,0,1, 0,0,0,33, 70,0,'enUS','Keep smiling, {race}. It''ll make the next battlefield sweeter.',1),
  (1227,128,262144,0,0,0,1, 0,0,0,33, 70,0,'enUS','Neutral ground. Lucky for you. Very lucky.',1),
  (1228,128,262144,0,0,0,1, 0,0,0,33, 80,0,'enUS','Not bad, for Alliance work. Don''t let it go to your head.',1),
  (1229,128,262144,0,0,0,1, 0,0,0,33, 70,0,'enUS','You lot clean up nice. Under the tabard you''re still the enemy.',1),
  (1230,128,262144,0,0,0,1, 0,0,0,33, 70,0,'enUS','Enjoy the truce while it lasts, {class}. It won''t.',1),
  (1231,128,262144,0,0,0,1, 0,0,0,33, 70,0,'enUS','A polite nod, then. That''s all you''ll get from me, {race}.',1),
  -- 34: SKYBREAKER identity (Alliance/human airship crew)
  (1300,128,524288,0,0,0,0, 0,0,0,34,100,0,'enUS','Well met! You stand before a crew of the mighty Skybreaker.',1),
  (1301,128,524288,0,0,0,0, 0,0,0,34, 90,0,'enUS','Ho there, {race}! A fine day to serve the Alliance, is it not?',1),
  (1302,128,524288,0,0,0,0, 0,0,0,34, 80,0,'enUS','Chin up, shoulders back — you''re in distinguished company now.',1),
  (1303,128,524288,0,0,0,0, 0,0,0,34, 80,0,'enUS','The Skybreaker patrols these skies. You may rest easy, citizen.',1),
  (1304,128,524288,0,0,0,0, 0,0,0,34, 80,0,'enUS','A hearty welcome, {class}! The Alliance is glad of stout hearts.',1),
  (1305,128,524288,0,0,0,0, 0,0,0,34, 80,0,'enUS','We fly for king and country, and we fly rather splendidly.',1),
  (1306,128,524288,0,0,0,0, 0,0,0,34, 80,0,'enUS','Stand tall, {race}. The finest airship in the fleet watches over you.',1),
  (1307,128,524288,0,0,0,0, 0,0,0,34, 70,0,'enUS','Vigor and valor, that''s the Skybreaker way. Care to salute?',1),
  (1308,128,524288,0,0,0,0, 0,0,0,34, 80,0,'enUS','High Commander Wyrmbane runs a proud ship. The proudest, I''d say.',1),
  (1309,128,524288,0,0,0,0, 0,0,0,34, 70,0,'enUS','A pleasure, truly. One meets such fine folk in Dalaran.',1),
  (1310,128,524288,0,0,0,0, 0,0,0,34, 80,0,'enUS','Onward and upward, friend! There''s glory enough for all.',1),
  (1311,128,524288,0,0,0,0, 0,0,0,34, 70,0,'enUS','Mind your bearing near the ship, {race}. Standards to uphold.',1),
  -- 35: SKYBREAKER, spoken only to HORDE (team 2) — snooty, condescending, polite veneer
  (1320,128,524288,0,0,0,2, 0,0,0,35, 90,0,'enUS','A Horde {race}. How... quaint. Do enjoy your visit.',1),
  (1321,128,524288,0,0,0,2, 0,0,0,35, 80,0,'enUS','One does try to be civil, even to your sort. You''re welcome.',1),
  (1322,128,524288,0,0,0,2, 0,0,0,35, 80,0,'enUS','Charming attire, for the Horde. Bless your effort, truly.',1),
  (1323,128,524288,0,0,0,2, 0,0,0,35, 80,0,'enUS','We share the city, {race}. We do not share breeding. Good day.',1),
  (1324,128,524288,0,0,0,2, 0,0,0,35, 70,0,'enUS','How gracious of you not to cause a scene. We noticed.',1),
  (1325,128,524288,0,0,0,2, 0,0,0,35, 80,0,'enUS','A Horde {class}, unescorted? How terribly bold of you.',1),
  (1326,128,524288,0,0,0,2, 0,0,0,35, 70,0,'enUS','Mind the polish on the hull, would you? Some of us keep standards.',1),
  (1327,128,524288,0,0,0,2, 0,0,0,35, 70,0,'enUS','You carry yourself well — for one of the savage banners, I mean.',1),
  (1328,128,524288,0,0,0,2, 0,0,0,35, 70,0,'enUS','Neutral ground spares you today. Send my regards to your Warchief.',1),
  (1329,128,524288,0,0,0,2, 0,0,0,35, 70,0,'enUS','I shall be the very picture of courtesy. It costs me dearly, {race}.',1),
  (1330,128,524288,0,0,0,2, 0,0,0,35, 70,0,'enUS','Run along now. The adults are discussing matters of the Alliance.',1),
  (1331,128,524288,0,0,0,2, 0,0,0,35, 70,0,'enUS','A nod, then, {race}. Noblesse oblige, as the finer folk say.',1);

-- ── 17-column INSERT: VIOLET HOLD guards (min_player_level = 75) ───────────────────
INSERT INTO `immersive_npc_chat_line`
  (`id`,`location_mask`,`npc_role_mask_lo`,`npc_role_mask_hi`,`class_mask`,`race_mask`,`team_mask`,
   `required_item_tags_lo`,`required_item_tags_hi`,`min_item_quality`,`cooldown_group`,`weight`,`chat_mode`,`locale`,`text`,`enabled`,`min_player_level`) VALUES
  (1100,128,131072,0,0,0,0, 0,0,0,31,100,0,'enUS','Well met, champion. Few earn the right to stand where you stand.',1,75),
  (1101,128,131072,0,0,0,0, 0,0,3,31, 90,0,'enUS','That is fine armor, {race}. It will serve you well beyond that door.',1,75),
  (1102,128,131072,0,0,0,0, 0,0,0,31, 90,0,'enUS','A worthy {class}. The Hold has seen many heroes; you look the part.',1,75),
  (1103,128,131072,0,0,0,0, 0,0,0,31, 90,0,'enUS','Mind the wards as you enter. And good luck to you, truly.',1,75),
  (1104,128,131072,0,0,0,0, 0,0,0,31, 90,0,'enUS','Prepare well. What waits within does not forgive the careless.',1,75),
  (1105,128,131072,0,0,0,0, 0,0,0,31, 90,0,'enUS','Safe travels, {race}. Return to us, and return victorious.',1,75),
  (1106,128,131072,0,0,0,0, 1,0,0,31, 80,0,'enUS','A splendid weapon. Keep it close where you are going.',1,75),
  (1107,128,131072,0,0,0,0, 0,0,0,31, 80,0,'enUS','The Kirin Tor thank you for your service, champion.',1,75),
  (1108,128,131072,0,0,0,0, 0,0,0,31, 80,0,'enUS','Steel yourself. Great foes have broken lesser heroes here.',1,75),
  (1109,128,131072,0,0,0,0, 0,0,0,31, 80,0,'enUS','That helm suits a warrior of your standing. Wear it with pride.',1,75),
  (1110,128,131072,0,0,0,0, 0,0,0,31, 80,0,'enUS','We guard the door so that you may face what lies beyond it. Go well.',1,75),
  (1111,128,131072,0,0,0,0, 0,0,0,31, 80,0,'enUS','Your aura is strong, {class}. The Hold could use more like you.',1,75),
  (1112,128,131072,0,0,0,0, 0,0,0,31, 80,0,'enUS','Check your blade, check your wards, then step through with confidence.',1,75),
  (1113,128,131072,0,0,0,0, 0,0,0,31, 80,0,'enUS','Many go in. The worthy come out. See that you are among them.',1,75),
  (1114,128,131072,0,0,0,0, 0,0,3,31, 80,0,'enUS','Fine craftsmanship, that gear. Northrend has tested it, I see.',1,75),
  (1115,128,131072,0,0,0,0, 0,0,0,31, 80,0,'enUS','Stand ready. The dragon''s brood does not tire, and neither must you.',1,75),
  (1116,128,131072,0,0,0,0, 0,0,0,31, 80,0,'enUS','You carry yourself like a veteran, {race}. The Hold is in good hands.',1,75),
  (1117,128,131072,0,0,0,0, 0,0,0,31, 70,0,'enUS','May the Light — or whatever you hold sacred — see you through.',1,75),
  (1118,128,131072,0,0,0,0, 0,0,0,31, 70,0,'enUS','Rest before you enter. There is no rest once that gate opens.',1,75),
  (1119,128,131072,0,0,0,0, 0,0,0,31, 80,0,'enUS','Go with our thanks, champion. Few would dare what you dare.',1,75);
