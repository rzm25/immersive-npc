-- ============================================================================
-- lua-immersive-npc-chat — VENDOR line pool (role_mask_lo = 4, all locations).
-- Idempotent: clears line id range 700..899, then inserts.
--
-- Tone: lore-friendly, polite, professional. Half are short greetings / light
-- trade enquiries; a handful are quirky/fun; a handful gossip about fine outfits
-- and trinkets seen on the main street. location_mask = 0 (every city, incl.
-- neutral Dalaran) — a vendor draws ONLY these because its profile role is VENDOR.
--
-- STAGED: this is the functional first tranche (42 lines) so vendors speak now.
-- Target is ~200; the pool will be filled out (owner can tune tone via
-- docs/CONTENT_LINES.md first). cooldown_group: 26 greeting/enquiry · 27 quirky · 28 gossip.
-- ============================================================================

DELETE FROM `immersive_npc_chat_line` WHERE `id` BETWEEN 700 AND 899;
INSERT INTO `immersive_npc_chat_line`
  (`id`,`location_mask`,`npc_role_mask_lo`,`npc_role_mask_hi`,`class_mask`,`race_mask`,`team_mask`,
   `required_item_tags_lo`,`required_item_tags_hi`,`min_item_quality`,`cooldown_group`,`weight`,`chat_mode`,`locale`,`text`,`enabled`) VALUES
  -- 26: short, polite greetings / trade enquiries
  (700,0,4,0,0,0,0, 0,0,0,26,100,0,'enUS','Welcome, {race}. Care to see my wares?',1),
  (701,0,4,0,0,0,0, 0,0,0,26,100,0,'enUS','Good day to you. Something catch your eye?',1),
  (702,0,4,0,0,0,0, 0,0,0,26,100,0,'enUS','Browse at your leisure, friend. No obligation.',1),
  (703,0,4,0,0,0,0, 0,0,0,26,100,0,'enUS','Fine goods, fair prices. How may I help you?',1),
  (704,0,4,0,0,0,0, 0,0,0,26, 90,0,'enUS','A pleasure. Everything you see is for sale.',1),
  (705,0,4,0,0,0,0, 0,0,0,26, 90,0,'enUS','Looking for something particular, {race}?',1),
  (706,0,4,0,0,0,0, 0,0,0,26, 90,0,'enUS','Welcome to my stall. Take your time.',1),
  (707,0,4,0,0,0,0, 0,0,0,26, 80,0,'enUS','Coin well spent is coin well kept. What''ll it be?',1),
  (708,0,4,0,0,0,0, 0,0,0,26, 90,0,'enUS','Ah, a customer! Do come in, do come in.',1),
  (709,0,4,0,0,0,0, 0,0,0,26, 90,0,'enUS','Quality goods, honestly priced. Have a look.',1),
  (710,0,4,0,0,0,0, 0,0,0,26, 80,0,'enUS','Trade, barter, or browse — you''re welcome either way.',1),
  (711,0,4,0,0,0,0, 0,0,0,26, 90,0,'enUS','How can I be of service today, {class}?',1),
  (712,0,4,0,0,0,0, 0,0,0,26, 80,0,'enUS','Everything''s fresh in this morning. See anything you like?',1),
  (713,0,4,0,0,0,0, 0,0,0,26, 80,0,'enUS','Step right up — no need to be shy.',1),
  (714,0,4,0,0,0,0, 0,0,0,26, 90,0,'enUS','A fine day for business. What are you after?',1),
  (715,0,4,0,0,0,0, 0,0,0,26, 80,0,'enUS','You''ll not find better wares this side of the square.',1),
  (716,0,4,0,0,0,0, 0,0,0,26, 90,0,'enUS','Take your pick, {race}. I stand behind all I sell.',1),
  (717,0,4,0,0,0,0, 0,0,0,26, 80,0,'enUS','Greetings. My stock is yours to peruse.',1),
  (718,0,4,0,0,0,0, 0,0,0,26, 90,0,'enUS','Good to see a paying customer. What can I get you?',1),
  (719,0,4,0,0,0,0, 0,0,0,26, 80,0,'enUS','Interested in a trade? I drive a fair bargain.',1),
  (720,0,4,0,0,0,0, 0,0,0,26, 90,0,'enUS','Welcome, welcome. Gold or goods, I deal in both.',1),
  (721,0,4,0,0,0,0, 0,0,0,26, 80,0,'enUS','Something for the road, perhaps? I''ve plenty.',1),
  (722,0,4,0,0,0,0, 0,0,0,26, 80,0,'enUS','Have a look around. Ask if aught catches your fancy.',1),
  (723,0,4,0,0,0,0, 0,0,0,26, 90,0,'enUS','A warm welcome, traveller. Wares aplenty here.',1),
  -- 27: quirky / fun, still polite
  (740,0,4,0,0,0,0, 0,0,0,27, 70,0,'enUS','Buy something, won''t you? My cat''s got expensive tastes.',1),
  (741,0,4,0,0,0,0, 0,0,0,27, 70,0,'enUS','Half of this I can''t explain, but it all sells.',1),
  (742,0,4,0,0,0,0, 0,0,0,27, 60,0,'enUS','No refunds, no haggling, and no — that one''s not cursed. Probably.',1),
  (743,0,4,0,0,0,0, 0,0,0,27, 60,0,'enUS','I could sell sand to a gnome, me. Care to test that?',1),
  (744,0,4,0,0,0,0, 0,0,0,27, 60,0,'enUS','Everything must go! ...well, except the stool. I like the stool.',1),
  (745,0,4,0,0,0,0, 0,0,0,27, 60,0,'enUS','That one? Fell off a caravan. Perfectly legal, I assure you.',1),
  (746,0,4,0,0,0,0, 0,0,0,27, 60,0,'enUS','Prices go up when it rains. Best buy now, eh?',1),
  (747,0,4,0,0,0,0, 0,0,0,27, 60,0,'enUS','I once sold a boot to a king. Just the one. Long story.',1),
  (748,0,4,0,0,0,0, 0,0,0,27, 60,0,'enUS','You break it, you''ve bought a story. And the item.',1),
  (749,0,4,0,0,0,0, 0,0,0,27, 60,0,'enUS','My grandmother enchanted these. Don''t ask which grandmother.',1),
  -- 28: gossip about fine outfits / trinkets seen on the main street
  (760,0,4,0,0,0,0, 0,0,0,28, 80,0,'enUS','That tabard''s a fine cut, {race}. Saw one like it on a lord last week.',1),
  (761,0,4,0,0,0,0, 0,0,0,28, 80,0,'enUS','Lovely trinket you''re wearing. Half the square''s been asking after those.',1),
  (762,0,4,0,0,0,0, 0,0,0,28, 70,0,'enUS','Such finery! You''ll set a fashion in the streets, mark me.',1),
  (763,0,4,0,0,0,0, 0,0,0,28, 70,0,'enUS','I saw a {class} stroll by in gold-trimmed plate this morning. Quite the sight.',1),
  (764,0,4,0,0,0,0, 0,0,0,28, 70,0,'enUS','Word is the nobles all wear enchanted cloaks now. You''d fit right in.',1),
  (765,0,4,0,0,0,0, 0,0,0,28, 70,0,'enUS','Fine boots on you. A cobbler two stalls down would weep with envy.',1),
  (766,0,4,0,0,0,0, 0,0,0,28, 70,0,'enUS','Everyone''s after gemmed rings of late. You''ve an eye for style, {race}.',1),
  (767,0,4,0,0,0,0, 0,0,3,28, 80,0,'enUS','That armor''s turning heads, {class}. Where does one come by such?',1);
