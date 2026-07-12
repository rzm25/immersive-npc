-- ============================================================================
-- lua-immersive-npc-chat — content expansion: new Crier + Emissary roles, and
-- per-race / per-class / per-weapon / per-armor / faction-religion categories.
-- Idempotent: clears line id range 401..999, then inserts.
--
-- Roles (npc_role_mask_lo): 512 = CRIER (bit 9), 256 = OFFICIAL/EMISSARY (bit 8).
-- Profile criers with role_mask_lo=512 and emissaries with 256 so they draw their own
-- sets (see the re-profile SQL in the handoff). The per-race/class/weapon/armor nods
-- use role 0 (ANY profiled NPC in that location can say them) so every NPC type gains
-- context-aware variety; faction/religion lines are role 0 but capital-scoped (126)
-- to stay out of neutral Dalaran.
--
-- Masks — class: War1 Pal2 Hun4 Rog8 Pri16 DK32 Sha64 Mage128 Lock256 Dru1024
--         race: Hum1 Orc2 Dwf4 NE8 UD16 Tau32 Gno64 Tro128 BE512 Dra1024
--         item(lo): weapon1 2H2 shield4 ranged8 plate16 mail32 leather64 cloth128
--                   sword256 axe512 mace1024 polearm2048 dagger4096 staff8192
--                   fist16384 bow32768 gun65536 crossbow131072 wand262144
--         team: Alliance1 Horde2
-- cooldown_group: 18 crier  19 emissary  20 race  21 class  22 weapon  23 armor  24 faction  25 religion
-- ============================================================================

DELETE FROM `immersive_npc_chat_line` WHERE `id` BETWEEN 401 AND 999;
INSERT INTO `immersive_npc_chat_line`
  (`id`,`location_mask`,`npc_role_mask_lo`,`npc_role_mask_hi`,`class_mask`,`race_mask`,`team_mask`,
   `required_item_tags_lo`,`required_item_tags_hi`,`min_item_quality`,`cooldown_group`,`weight`,`chat_mode`,`locale`,`text`,`enabled`) VALUES
  -- 18: CRIER (role 512), capitals
  (401,126,512,0,0,0,0, 0,0,0,18,100,0,'enUS','Hear ye, hear ye! The city stands strong under watchful eyes!',1),
  (402,126,512,0,0,0,0, 0,0,0,18, 90,0,'enUS','Oyez! Mind the law and keep the peace, good folk!',1),
  (403,126,512,0,0,0,0, 0,0,0,18, 90,0,'enUS','Fresh word from the front — stay vigilant, and stay proud!',1),
  (404,126,512,0,0,0,0, 0,0,0,18, 90,0,'enUS','Hear ye! A {class} walks among us this very day!',1),
  (405,126,512,0,0,0,0, 0,0,0,18, 80,0,'enUS','Step lively, citizens! The market bells ring within the hour!',1),
  (406,126,512,0,0,0,0, 0,0,0,18, 90,0,'enUS','Make way, make way! A {race} of note passes through!',1),
  (407,126,512,0,0,0,0, 0,0,0,18, 80,0,'enUS','By order of the city — no brawling, no thieving, no mischief!',1),
  (408,126,512,0,0,0,0, 0,0,0,18, 80,0,'enUS','Tidings, tidings! The taverns are open and the ale is cold!',1),
  (409,126,512,0,0,0,0, 0,0,0,18, 90,0,'enUS','Honor to the brave this day, and a wary eye to the rest!',1),
  (410,126,512,0,0,0,0, 0,0,0,18, 80,0,'enUS','All able hands are welcome to the city''s defense — hear ye!',1),
  (411,126,512,0,0,0,0, 0,0,0,18, 80,0,'enUS','Mind your purses in the crowd, and mind the King''s law!',1),
  (412,126,512,0,0,0,0, 0,0,0,18, 80,0,'enUS','Oyez! The roads grow bold with heroes — glory to the realm!',1),
  -- 19: EMISSARY (role 256)
  (421,0,256,0,0,0,0, 0,0,0,19,100,0,'enUS','The Argent Crusade stands against the Scourge. Will you stand with us, {race}?',1),
  (422,0,256,0,0,0,0, 0,0,0,19, 90,0,'enUS','We seek champions for the front. A {class} would be most welcome.',1),
  (423,0,256,0,0,0,0, 0,0,0,19, 90,0,'enUS','Wear your colors with pride, {race}. The war is far from won.',1),
  (424,0,256,0,0,0,0, 0,0,0,19, 90,0,'enUS','Every hero counts. Even one such as you might turn the tide.',1),
  (425,0,256,0,0,0,0, 0,0,0,19, 80,0,'enUS','There is coin and honor both for those who fight for the cause.',1),
  (426,0,256,0,0,0,0, 0,0,0,19, 80,0,'enUS','Rare to see a {class} unsworn to any banner. Consider ours.',1),
  (427,0,256,0,0,0,0, 0,0,0,19, 90,0,'enUS','Speak with me if you''d earn the favor of my order, {race}.',1),
  (428,0,256,0,0,0,0, 0,0,0,19, 80,0,'enUS','Tabards and titles mean nothing without the deeds to earn them.',1),
  (429,0,256,0,0,0,0, 0,0,0,19, 80,0,'enUS','The dead do not tire, {race}. Neither, then, must we.',1),
  (430,0,256,0,0,0,0, 0,0,0,19, 80,0,'enUS','You have the bearing of a champion. My order could use you.',1),
  (431,0,256,0,0,0,0, 0,0,0,19, 70,0,'enUS','Old enemies make common cause against a common foe these days.',1),
  (432,0,256,0,0,0,0, 0,0,0,19, 80,0,'enUS','Glory awaits the bold on the borderlands, {race}. Seek it.',1),
  (433,0,256,0,0,0,0, 0,0,0,19, 70,0,'enUS','We remember our fallen. See that you honor them, {class}.',1),
  (434,0,256,0,0,0,0, 0,0,0,19, 70,0,'enUS','The banner I carry has seen a hundred fields. It seeks a hundred more.',1),
  -- 20: per-race nods (role 0, everywhere)
  (501,0,0,0,0,1,0,    0,0,0,20, 80,0,'enUS','You humans do get everywhere. Ambitious lot, and no mistake.',1),
  (502,0,0,0,0,1,0,    0,0,0,20, 70,0,'enUS','A son or daughter of Stormwind, I''d wager. Long roads ahead of you.',1),
  (503,0,0,0,0,2,0,    0,0,0,20, 80,0,'enUS','An orc, walking tall and proud. Strength and honor to you.',1),
  (504,0,0,0,0,2,0,    0,0,0,20, 70,0,'enUS','May your axe stay sharp, orc, and your enemies few.',1),
  (505,0,0,0,0,4,0,    0,0,0,20, 80,0,'enUS','A dwarf! Mind you don''t drink us dry, friend.',1),
  (506,0,0,0,0,4,0,    0,0,0,20, 70,0,'enUS','Stout as the mountain, you dwarves — and twice as hard-headed.',1),
  (507,0,0,0,0,8,0,    0,0,0,20, 80,0,'enUS','A child of the stars. You night elves make an old soul feel young.',1),
  (508,0,0,0,0,8,0,    0,0,0,20, 70,0,'enUS','Elune''s grace upon you, kaldorei. You walk far from your groves.',1),
  (509,0,0,0,0,16,0,   0,0,0,20, 80,0,'enUS','A Forsaken... forgive my flinch. Old fears die hard, friend.',1),
  (510,0,0,0,0,16,0,   0,0,0,20, 70,0,'enUS','You wear death lightly, Forsaken. I''ll not pretend it''s easy to see.',1),
  (511,0,0,0,0,32,0,   0,0,0,20, 80,0,'enUS','An Earthmother''s child. You tauren carry such a gentle strength.',1),
  (512,0,0,0,0,32,0,   0,0,0,20, 70,0,'enUS','So tall, so calm. The tauren shame the rest of us for temper.',1),
  (513,0,0,0,0,64,0,   0,0,0,20, 80,0,'enUS','A gnome! Mind the cobbles — I''d hate to tread on a genius.',1),
  (514,0,0,0,0,64,0,   0,0,0,20, 70,0,'enUS','Tinkering again, no doubt. You gnomes never sit still, do you?',1),
  (515,0,0,0,0,128,0,  0,0,0,20, 80,0,'enUS','A troll, and mannered too. The old stories don''t do you justice.',1),
  (516,0,0,0,0,128,0,  0,0,0,20, 70,0,'enUS','Them tusks give me a start, but you carry yourself well, troll.',1),
  (517,0,0,0,0,512,0,  0,0,0,20, 80,0,'enUS','A sin''dorei. You blood elves wear your pride like fine silk.',1),
  (518,0,0,0,0,512,0,  0,0,0,20, 70,0,'enUS','The Sunwell''s children walk among us. Strange days indeed.',1),
  (519,0,0,0,0,1024,0, 0,0,0,20, 80,0,'enUS','A draenei — so tall! The Light shines strange and bright in you.',1),
  (520,0,0,0,0,1024,0, 0,0,0,20, 70,0,'enUS','From beyond the stars, they say. You draenei have seen much grief.',1),
  -- 21: per-class nods (role 0, everywhere)
  (541,0,0,0,1,0,0,    0,0,0,21, 80,0,'enUS','A warrior''s hands, scarred and steady. You''ve earned those.',1),
  (542,0,0,0,1,0,0,    0,0,0,21, 70,0,'enUS','No tricks for you, eh warrior? Just steel and will. I respect it.',1),
  (543,0,0,0,2,0,0,    0,0,0,21, 80,0,'enUS','The Light walks with you, paladin. We sleep safer for your kind.',1),
  (544,0,0,0,2,0,0,    0,0,0,21, 70,0,'enUS','Armor and faith both, paladin. A fine pairing in dark times.',1),
  (545,0,0,0,4,0,0,    0,0,0,21, 80,0,'enUS','Where''s your beast, hunter? Left it outside, I do hope.',1),
  (546,0,0,0,4,0,0,    0,0,0,21, 70,0,'enUS','A steady eye and a loyal companion. You hunters want for little.',1),
  (547,0,0,0,8,0,0,    0,0,0,21, 80,0,'enUS','Didn''t hear you approach, {class}. ...I never do, do I?',1),
  (548,0,0,0,8,0,0,    0,0,0,21, 70,0,'enUS','Keep those clever fingers to yourself, rogue. All in good humor.',1),
  (549,0,0,0,16,0,0,   0,0,0,21, 80,0,'enUS','Bless you, priest. The wounded and weary are in your debt.',1),
  (550,0,0,0,16,0,0,   0,0,0,21, 70,0,'enUS','Faith is a heavy burden to carry, priest. You wear it well.',1),
  (551,0,0,0,32,0,0,   0,0,0,21, 80,0,'enUS','A death knight. The grave gave you back — use the gift well.',1),
  (552,0,0,0,32,0,0,   0,0,0,21, 70,0,'enUS','Cold comes off you like winter, death knight. But you fight for the living now.',1),
  (553,0,0,0,64,0,0,   0,0,0,21, 80,0,'enUS','The elements whisper around you, shaman. I feel the air change.',1),
  (554,0,0,0,64,0,0,   0,0,0,21, 70,0,'enUS','Earth, wind, fire and water — all your kin, shaman. What a thing.',1),
  (555,0,0,0,128,0,0,  0,0,0,21, 80,0,'enUS','Mind the sparks, mage. My thatch roof thanks you in advance.',1),
  (556,0,0,0,128,0,0,  0,0,0,21, 70,0,'enUS','A mage''s work is never dull, nor safe. Do be careful in the streets.',1),
  (557,0,0,0,256,0,0,  0,0,0,21, 80,0,'enUS','Keep your... friends leashed, warlock. Folk here are the nervous sort.',1),
  (558,0,0,0,256,0,0,  0,0,0,21, 70,0,'enUS','Dark power, darker bargains. I''ll not ask the price, warlock.',1),
  (559,0,0,0,1024,0,0, 0,0,0,21, 80,0,'enUS','The wilds sent you, druid? You smell of pine and open sky.',1),
  (560,0,0,0,1024,0,0, 0,0,0,21, 70,0,'enUS','Claw, feather or leaf today, druid? You shapechangers keep us guessing.',1),
  -- 22: per-weapon nods (role 0, everywhere; gated on the weapon tag)
  (581,0,0,0,0,0,0, 256,0,0,22, 80,0,'enUS','A swordsman''s stance. Honest steel — nothing wrong with that.',1),
  (582,0,0,0,0,0,0, 512,0,0,22, 80,0,'enUS','That axe has split more than firewood, I''d wager. Heavy work.',1),
  (583,0,0,0,0,0,0, 1024,0,0,22, 80,0,'enUS','A good mace ends an argument quick. Blunt, like my old mother.',1),
  (584,0,0,0,0,0,0, 2048,0,0,22, 70,0,'enUS','Reach and weight both, that polearm. Keep it clear of the awnings.',1),
  (585,0,0,0,0,0,0, 4096,0,0,22, 80,0,'enUS','Small blade, quick hands. I''ll keep my coin purse close, {race}.',1),
  (586,0,0,0,0,0,0, 8192,0,0,22, 70,0,'enUS','A scholar''s staff — or a cracked skull waiting to happen. Both, maybe.',1),
  (587,0,0,0,0,0,0, 16384,0,0,22, 70,0,'enUS','Bare hands and a bit of steel? Bold way to fight, {class}.',1),
  (588,0,0,0,0,0,0, 32768,0,0,22, 80,0,'enUS','A fine bow. Steady in the draw, I''d guess. Don''t aim it near me!',1),
  (589,0,0,0,0,0,0, 65536,0,0,22, 70,0,'enUS','A firearm! Loud, smelly things — effective, mind, but loud.',1),
  (590,0,0,0,0,0,0, 2,0,0,22, 70,0,'enUS','That two-hander''s taller than my youngest. Mind the doorframes.',1),
  (591,0,0,0,0,0,0, 4,0,0,22, 80,0,'enUS','Shield on your arm — a defender''s heart. We need more like you.',1),
  -- 23: per-armor nods (role 0, everywhere; gated on the chest material)
  (601,0,0,0,0,0,0, 16,0,0,23, 80,0,'enUS','Head to toe in plate! You must sound like a cart on the cobbles.',1),
  (602,0,0,0,0,0,0, 16,0,0,23, 70,0,'enUS','Fine steel plate, {race}. The smiths did right by you.',1),
  (603,0,0,0,0,0,0, 32,0,0,23, 80,0,'enUS','Mail and mettle. Practical — moves with you, keeps the edge off.',1),
  (604,0,0,0,0,0,0, 32,0,0,23, 70,0,'enUS','Chainmail suits you, {race}. Not too heavy, not too light.',1),
  (605,0,0,0,0,0,0, 64,0,0,23, 80,0,'enUS','Supple leather, quiet steps. A practical sort, aren''t you?',1),
  (606,0,0,0,0,0,0, 64,0,0,23, 70,0,'enUS','Leathers well worn, {race}. The road''s left its mark on them.',1),
  (607,0,0,0,0,0,0, 128,0,0,23, 80,0,'enUS','Robes and cloth — a caster''s garb. Mind the mud; it never comes out.',1),
  (608,0,0,0,0,0,0, 128,0,0,23, 70,0,'enUS','Fine cloth, that. Enchanted, is it? I daren''t ask what it cost.',1),
  -- 24: faction (role 0, capitals, team-gated)
  (621,126,0,0,0,0,1, 0,0,0,24, 80,0,'enUS','For the Alliance! Good to see the banner carried proud, {race}.',1),
  (622,126,0,0,0,0,1, 0,0,0,24, 70,0,'enUS','Stormwind, Ironforge, Darnassus, the Exodar — one people, one cause.',1),
  (623,126,0,0,0,0,1, 0,0,0,24, 70,0,'enUS','The Light and the King keep us. Stand tall, {race} of the Alliance.',1),
  (624,126,0,0,0,0,2, 0,0,0,24, 80,0,'enUS','Lok''tar ogar, {race}! Victory or death — the Horde endures.',1),
  (625,126,0,0,0,0,2, 0,0,0,24, 70,0,'enUS','For the Warchief! The Horde is family, forged in fire.',1),
  (626,126,0,0,0,0,2, 0,0,0,24, 70,0,'enUS','Blood and thunder, {race}. The Horde bows to no one.',1),
  -- 25: religion / faith (role 0, capitals)
  (627,126,0,0,0,0,0, 0,0,0,25, 70,0,'enUS','The Light watches over the faithful. May it guide your road, {race}.',1),
  (628,126,0,0,0,0,0, 0,0,0,25, 60,0,'enUS','Some pray to the Light, some the elements, some older things. All welcome.',1),
  (629,126,0,0,0,0,0, 0,0,0,25, 70,0,'enUS','Faith carries folk through dark seasons, {class}. Hold to yours.',1),
  (630,126,0,0,0,0,0, 0,0,0,25, 60,0,'enUS','Elune, the Light, the Earthmother — many names, one hope, I say.',1);
