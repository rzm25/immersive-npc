# CONTENT_LINES — editable dialogue table

Every chat line currently shipped, pulled straight from `sql/world/updates/*.sql`.
Edit the **text** (or **wt**, **mode**, **targets**), or add new rows, then hand the
table back and I will (1) snapshot the current content as a `v0.0.1` backup SQL and
(2) generate a fresh content SQL from your table.

## How to edit / add

- **id** — leave **blank** for a new line (I assign one). Keep existing ids to track edits.
- **section** (the `###` heading) — which NPC type + place the line belongs to. Add a row
  under the matching section, or ask for a new one (e.g. a **Criers** section).
- **grp** — cooldown group: lines sharing a number share a *per-player* cooldown, so a
  listener won't hear the same category twice in a row. Reuse a number or pick a new one.
- **mode** — `say` · `whisper` · `emote`.
- **wt** — weight (relative frequency; ~100 = normal, lower = rarer). Lore/special lines
  are low (e.g. 30–35) so they stay a treat.
- **targets** — who the line is for. `—` = anyone. Mix with commas:
  `class:Mage` · `race:Draenei` · `Horde players` / `Alliance players` ·
  `gear:weapon` / `gear:shield` / `gear:plate` / `gear:ranged` · `rare+` / `epic+` (min gear quality) ·
  `level 75+` (min listener level — used by the Violet Hold pool).
- **text** — the dialogue. Placeholders: `{player}` `{race}` `{class}` `{weapon_type}`.
  Keep it ≤ ~110 chars. Use normal apostrophes — I double them for SQL.

## Placement / scope reference

- **Guards** speak in every capital (role GUARD). Faction/city-specific guard lines are in section 2.
- **Citizens** speak in the six capitals but NOT Dalaran (role CITIZEN).
- **Dalaran** lines are Dalaran-only (role CITIZEN — the mages/townsfolk).
- **Darkshire** lines are Darkshire-only (role CITIZEN).
- **Vendors** speak in every city (role VENDOR) and draw ONLY the vendor pool.
- **Dalaran factions** — Sunreaver / Violet Hold / Sky-Reaver / Skybreaker each have their
  own role and voice; "opposing faction" lines use the `Alliance/Horde players` target;
  Violet Hold lines are gated to `level 75+`.

---


### 1. Guards  (30 lines)

| id | grp | mode | wt | scope | targets | text |
|----|-----|------|----|-------|---------|------|
| 1 | 1 | say | 100 | ALL capitals | — | Well met, {race}. Keep to the roads and you'll have no trouble here. |
| 2 | 1 | say | 100 | ALL capitals | — | Move along, citizen. The watch has its eyes open. |
| 3 | 1 | say | 90 | ALL capitals | — | Stay sharp, {class}. These are uneasy times. |
| 4 | 1 | say | 70 | ALL capitals | — | Another {race} in the city? Good — we can use steady hands. |
| 5 | 1 | say | 80 | ALL capitals | — | Mind yourself in the crowds, {race}. |
| 6 | 2 | say | 90 | ALL capitals | gear:weapon | That {weapon_type} of yours has seen use, I'd wager. |
| 7 | 2 | say | 90 | ALL capitals | epic+ | Fine gear, {class}. You've earned your place. |
| 8 | 2 | say | 90 | ALL capitals | gear:shield | A shield-bearer. You'd make a fine addition to the watch. |
| 9 | 2 | say | 80 | ALL capitals | gear:2H | Mind that big blade indoors, {race}. |
| 10 | 2 | say | 80 | ALL capitals | gear:plate | Plate and steel — a proper soldier's kit. |
| 11 | 2 | say | 80 | ALL capitals | gear:ranged | Keep that string dry, {race}. You never know. |
| 12 | 3 | say | 80 | ALL capitals | class:Mage | A mage in our streets. Try not to set anything alight, hm? |
| 13 | 3 | say | 80 | ALL capitals | class:Paladin | The Light guide you, {race}. |
| 14 | 3 | say | 80 | ALL capitals | class:Rogue | Hands where I can see them, {class}. |
| 15 | 3 | say | 80 | ALL capitals | class:Hunter | Leave the beast outside the bank, would you? |
| 16 | 3 | say | 80 | ALL capitals | class:Warrior | A warrior's stride. You carry yourself well, {race}. |
| 17 | 3 | say | 80 | ALL capitals | class:Priest | Blessings, {class}. The wounded will thank you. |
| 18 | 3 | say | 70 | ALL capitals | class:DeathKnight | ...A death knight. We watch your kind closely. |
| 19 | 3 | say | 70 | ALL capitals | class:Warlock | Keep your companions leashed, {class}. |
| 20 | 3 | say | 80 | ALL capitals | class:Druid | The wilds send us one of their own. Welcome, {race}. |
| 21 | 3 | say | 80 | ALL capitals | class:Shaman | The elements favor you, {class}? We'll take the luck. |
| 22 | 4 | say | 70 | ALL capitals | Alliance players | For the Alliance, {race}. Stand tall. |
| 23 | 4 | say | 70 | ALL capitals | Horde players | Lok'tar, {race}. Strength and honor. |
| 30 | 5 | say | 60 | ALL capitals | — | No brawling in the streets, {class}. Take it to the ring. |
| 31 | 5 | say | 60 | ALL capitals | — | Watch your purse in the market, {race}. |
| 32 | 6 | whisper | 50 | ALL capitals | — | Psst — fresh goods at the auction house, {race}. You didn't hear it from me. |
| 33 | 6 | whisper | 50 | ALL capitals | — | Between us, {class}, the quarter's been jumpy all week. |
| 34 | 6 | emote | 60 | ALL capitals | — | sizes you up with a soldier's glance. |
| 35 | 6 | emote | 60 | ALL capitals | — | nods respectfully as you pass. |
| 36 | 6 | emote | 50 | ALL capitals | — | snaps to attention as the {race} approaches. |

### 2. Guards (faction/city-specific)  (6 lines)

| id | grp | mode | wt | scope | targets | text |
|----|-----|------|----|-------|---------|------|
| 24 | 4 | say | 90 | Stormwind | — | Welcome to Stormwind, {race}. The king's peace holds here. |
| 25 | 4 | say | 90 | Ironforge | — | Ironforge welcomes you, {race}. Mind the forge-heat. |
| 26 | 4 | say | 90 | Orgrimmar | — | Orgrimmar's gates are open to you, {race}. |
| 27 | 4 | say | 90 | ThunderBluff | — | Walk gently on the rise, {race}. The winds are watching. |
| 28 | 4 | say | 90 | Undercity | — | The Dark Lady watches over us, {race}. |
| 29 | 4 | say | 90 | Darnassus | — | Elune guide your steps, {race}. |

### 3. Citizens (all capitals, not Dalaran)  (54 lines)

| id | grp | mode | wt | scope | targets | text |
|----|-----|------|----|-------|---------|------|
| 101 | 7 | say | 100 | ALL capitals | — | Fine weather for it, eh? The crops'll be glad of the sun. |
| 102 | 7 | say | 100 | ALL capitals | — | Rain's coming, mark my words. My knee never lies. |
| 103 | 7 | say | 90 | ALL capitals | — | Cold enough to freeze the well again. Mind your step. |
| 104 | 7 | say | 100 | ALL capitals | — | A fair morning to you, {race}. |
| 105 | 8 | say | 100 | ALL capitals | — | Have you seen my hen? Brown thing, foul temper. Wanders off daily. |
| 106 | 8 | say | 90 | ALL capitals | — | The chickens won't lay in this heat. Stubborn birds. |
| 107 | 8 | say | 90 | ALL capitals | — | Mind the geese by the water — they'll have your fingers. |
| 108 | 8 | say | 100 | ALL capitals | — | The grain hauls came in light this season. Millers are grumbling. |
| 109 | 8 | say | 90 | ALL capitals | — | Flour's dear this month. Everything's dear this month. |
| 110 | 8 | say | 90 | ALL capitals | — | Hauled sacks since dawn. My back's not what it was. |
| 111 | 9 | say | 90 | ALL capitals | — | They say the king's advisors can't agree on the time of day. |
| 112 | 9 | say | 90 | ALL capitals | — | Heard there's trouble at the border again. Always is. |
| 113 | 9 | say | 90 | ALL capitals | — | The nobles feast while we count coppers. Same as ever. |
| 114 | 9 | say | 100 | ALL capitals | — | Word is a hero passed through. Suppose that'd be you, {race}? |
| 115 | 9 | say | 80 | ALL capitals | — | Taxes up again. A hero wouldn't notice, but we feel it. |
| 116 | 10 | say | 100 | ALL capitals | — | Good day to you. Mind how you go. |
| 117 | 10 | say | 80 | ALL capitals | — | Spare a kind word for an honest worker? |
| 118 | 10 | say | 100 | ALL capitals | — | Bless you, traveller. Safe roads. |
| 119 | 10 | say | 80 | ALL capitals | — | Don't mind me, just resting my feet a moment. |
| 120 | 10 | say | 90 | ALL capitals | — | Busy day at market. Everyone wants everything at once. |
| 121 | 10 | say | 90 | ALL capitals | — | You'll want the inn if you're after a bed. Just down the way. |
| 122 | 10 | say | 90 | ALL capitals | — | Watch your purse in the crowd, friend. Cutpurses about. |
| 123 | 10 | say | 90 | ALL capitals | — | Another day, another copper. Such is life. |
| 124 | 10 | say | 80 | ALL capitals | — | The bells ring soon. Best be about my errands. |
| 125 | 10 | say | 90 | ALL capitals | — | Ah, to be young and off seeing the world, like you. |
| 126 | 11 | say | 90 | ALL capitals | — | A {class}, are you? We don't see many of your sort round here. |
| 127 | 11 | say | 80 | ALL capitals | epic+ | That's fine armor for a common street, {race}. Off adventuring? |
| 128 | 11 | say | 90 | ALL capitals | gear:weapon | Careful swinging that {weapon_type} about — you'll frighten the little ones. |
| 129 | 11 | say | 90 | ALL capitals | — | A {race} in these parts? Well, times are changing. |
| 130 | 11 | say | 90 | ALL capitals | — | You've the look of someone with somewhere to be, {class}. |
| 131 | 11 | say | 80 | ALL capitals | gear:weapon | Best keep that {weapon_type} sheathed near the stalls, aye? |
| 132 | 11 | say | 90 | ALL capitals | — | Off to slay something dreadful, no doubt. Rather you than me, {race}. |
| 401 | 18 | say | 100 | ALL capitals | — | Hear ye, hear ye! The city stands strong under watchful eyes! |
| 402 | 18 | say | 90 | ALL capitals | — | Oyez! Mind the law and keep the peace, good folk! |
| 403 | 18 | say | 90 | ALL capitals | — | Fresh word from the front — stay vigilant, and stay proud! |
| 404 | 18 | say | 90 | ALL capitals | — | Hear ye! A {class} walks among us this very day! |
| 405 | 18 | say | 80 | ALL capitals | — | Step lively, citizens! The market bells ring within the hour! |
| 406 | 18 | say | 90 | ALL capitals | — | Make way, make way! A {race} of note passes through! |
| 407 | 18 | say | 80 | ALL capitals | — | By order of the city — no brawling, no thieving, no mischief! |
| 408 | 18 | say | 80 | ALL capitals | — | Tidings, tidings! The taverns are open and the ale is cold! |
| 409 | 18 | say | 90 | ALL capitals | — | Honor to the brave this day, and a wary eye to the rest! |
| 410 | 18 | say | 80 | ALL capitals | — | All able hands are welcome to the city's defense — hear ye! |
| 411 | 18 | say | 80 | ALL capitals | — | Mind your purses in the crowd, and mind the King's law! |
| 412 | 18 | say | 80 | ALL capitals | — | Oyez! The roads grow bold with heroes — glory to the realm! |
| 621 | 24 | say | 80 | ALL capitals | Alliance players | For the Alliance! Good to see the banner carried proud, {race}. |
| 622 | 24 | say | 70 | ALL capitals | Alliance players | Stormwind, Ironforge, Darnassus, the Exodar — one people, one cause. |
| 623 | 24 | say | 70 | ALL capitals | Alliance players | The Light and the King keep us. Stand tall, {race} of the Alliance. |
| 624 | 24 | say | 80 | ALL capitals | Horde players | Lok'tar ogar, {race}! Victory or death — the Horde endures. |
| 625 | 24 | say | 70 | ALL capitals | Horde players | For the Warchief! The Horde is family, forged in fire. |
| 626 | 24 | say | 70 | ALL capitals | Horde players | Blood and thunder, {race}. The Horde bows to no one. |
| 627 | 25 | say | 70 | ALL capitals | — | The Light watches over the faithful. May it guide your road, {race}. |
| 628 | 25 | say | 60 | ALL capitals | — | Some pray to the Light, some the elements, some older things. All welcome. |
| 629 | 25 | say | 70 | ALL capitals | — | Faith carries folk through dark seasons, {class}. Hold to yours. |
| 630 | 25 | say | 60 | ALL capitals | — | Elune, the Light, the Earthmother — many names, one hope, I say. |

### 4. Dalaran  (40 lines)

| id | grp | mode | wt | scope | targets | text |
|----|-----|------|----|-------|---------|------|
| 201 | 12 | say | 100 | Dalaran | — | Welcome to Dalaran, {race}. Mind the wards — they bite the careless. |
| 202 | 12 | say | 100 | Dalaran | — | Greetings, traveller. The Eventide is lovely at this hour. |
| 203 | 12 | say | 90 | Dalaran | — | A good day beneath the violet dome, wouldn't you say? |
| 204 | 12 | say | 100 | Dalaran | — | Fresh from the world below, {race}? The city floats far from home. |
| 205 | 12 | say | 80 | Dalaran | — | Tea? No? More for me, then. |
| 206 | 12 | say | 90 | Dalaran | — | Stay a while. Dalaran rewards the curious. |
| 207 | 12 | say | 90 | Dalaran | — | Another {race} seeking their fortune. The city welcomes you. |
| 208 | 12 | say | 90 | Dalaran | — | Good day to you. Do try not to wander into a portal. |
| 209 | 12 | say | 80 | Dalaran | — | The Legerdemain pours a fine wine, if you've the coin. |
| 210 | 12 | say | 90 | Dalaran | — | You'll find no finer libraries in all the world. |
| 211 | 12 | say | 90 | Dalaran | — | Don't look down. The city floats, and the ground is very far. |
| 212 | 12 | say | 90 | Dalaran | — | Books, scrolls, reagents — we trade in wonders here. |
| 213 | 12 | say | 90 | Dalaran | — | New apprentices arrive daily. The halls have never been busier. |
| 214 | 12 | say | 90 | Dalaran | — | If you seek the Violet Citadel, mind your manners inside. |
| 215 | 12 | say | 100 | Dalaran | — | Welcome, welcome. Mind the enchantments and enjoy your stay, {race}. |
| 226 | 12 | say | 90 | Dalaran | — | A {class} walks among us. How refreshing. |
| 227 | 12 | say | 90 | Dalaran | — | You carry yourself well for one so far from home, {race}. |
| 228 | 12 | say | 80 | Dalaran | — | You've the look of the battlefield about you. Rest a while. |
| 229 | 12 | say | 80 | Dalaran | — | A hero, are you? We get a few. Do try not to break anything. |
| 230 | 12 | say | 80 | Dalaran | — | The magi could learn a thing from a seasoned {class}, I'd wager. |
| 216 | 13 | say | 90 | Dalaran | — | The arcane hums strong today. Can you feel it? |
| 217 | 13 | say | 90 | Dalaran | — | Watch your step near the portals. We lose a tourist most weeks. |
| 218 | 13 | say | 80 | Dalaran | — | Mind the mages muttering to themselves — usually harmless. |
| 219 | 13 | say | 80 | Dalaran | — | Arcane wards, a flying city — and still the tea goes cold. |
| 220 | 13 | say | 80 | Dalaran | — | The magi keep us aloft. Best not ask how. |
| 221 | 13 | say | 80 | Dalaran | — | The dome keeps the weather out. Small mercies. |
| 222 | 13 | say | 80 | Dalaran | — | Mind the sewers below — not everything down there is friendly. |
| 223 | 13 | say | 90 | Dalaran | gear:weapon | Careful with that {weapon_type} indoors, {race}. This is a city of scholars. |
| 224 | 13 | say | 90 | Dalaran | rare+ | Lovely enchantment on that gear, {race}. Dalaran work, perhaps? |
| 225 | 13 | say | 80 | Dalaran | epic+ | Such finery. You've done well for yourself out there, {race}. |
| 231 | 14 | say | 35 | Dalaran | — | The Kirin Tor watch over us all. Six minds, one purpose. |
| 232 | 14 | say | 35 | Dalaran | — | Old Dalaran fell to Archimonde's fire. This city rose from that grief. |
| 233 | 14 | say | 35 | Dalaran | — | They say Antonidas himself once walked these halls. A great loss, his. |
| 234 | 14 | say | 35 | Dalaran | — | We raised the city and flew it north to face the Lich King. Bold days. |
| 235 | 14 | say | 35 | Dalaran | — | The Violet Hold keeps darker things than you'd care to meet, {race}. |
| 236 | 14 | say | 35 | Dalaran | — | Archmage Rhonin leads the Kirin Tor now. A dragon's pupil, they whisper. |
| 237 | 14 | say | 35 | Dalaran | — | Silver Covenant or Sunreaver — we all breathe the same arcane air. Mostly. |
| 238 | 14 | say | 30 | Dalaran | — | Lady Proudmoore studied under Antonidas, once. Before it all. |
| 239 | 14 | say | 30 | Dalaran | — | The Council of Six speaks, and the city listens. Wise to do the same. |
| 240 | 14 | say | 30 | Dalaran | — | The Legion, the Scourge, the Lich King — Dalaran has weathered every storm. |

### 5. Darkshire  (22 lines)

| id | grp | mode | wt | scope | targets | text |
|----|-----|------|----|-------|---------|------|
| 301 | 15 | say | 100 | Darkshire | — | Oh! You startled me. Forgive an old worrier. |
| 302 | 15 | say | 100 | Darkshire | — | Light preserve us — oh, it's only you. Welcome, {race}. |
| 303 | 15 | say | 90 | Darkshire | — | A visitor! We don't get many brave enough for Darkshire. |
| 304 | 15 | say | 90 | Darkshire | — | Bless you for coming. It's been a fearful season, truly. |
| 305 | 15 | say | 90 | Darkshire | — | Good day — oh, do forgive my nerves. One learns to jump, here. |
| 306 | 15 | say | 90 | Darkshire | — | You gave me a fright! But a friendly face is always welcome. |
| 319 | 15 | say | 90 | Darkshire | — | A {class}, thank the Light. We could use a stout heart round here. |
| 320 | 15 | say | 80 | Darkshire | — | You'll keep us safe if it comes to it, won't you? Please say you will. |
| 321 | 15 | say | 80 | Darkshire | gear:weapon | Keep that {weapon_type} close after sundown. You'll want it. |
| 322 | 15 | say | 90 | Darkshire | — | Fine armor. Are you here to help? Oh, say you're here to help us. |
| 314 | 16 | say | 90 | Darkshire | — | Best indoors before dark. The woods... they don't sleep, you know. |
| 315 | 16 | say | 80 | Darkshire | — | Did you hear that? ...No? Only nerves. Pay me no mind. |
| 316 | 16 | say | 90 | Darkshire | — | Stay to the lit paths. Duskwood keeps its secrets in the shadow. |
| 317 | 16 | say | 90 | Darkshire | — | The nights are long here. Longer still when the dead don't rest. |
| 318 | 16 | say | 90 | Darkshire | — | Mind the graveyard, {race}. Some who lie there don't always stay. |
| 307 | 17 | say | 100 | Darkshire | race:Draenei | Oh! You startled me. Such a tall draenei — a pleasure, truly. |
| 308 | 17 | say | 100 | Darkshire | race:Tauren | Goodness, a tauren! So very tall. N-nice to meet you, honestly. |
| 309 | 17 | say | 100 | Darkshire | race:Troll | Oh — a troll! No trouble, I hope. Only manners here, I promise. |
| 310 | 17 | say | 90 | Darkshire | race:NightElf | A night elf, abroad in daylight? These are strange times indeed. |
| 311 | 17 | say | 100 | Darkshire | Horde players | We want no trouble. Alliance we may be, but no enemy of yours. |
| 312 | 17 | say | 90 | Darkshire | Horde players | P-please, we're just simple folk. No quarrel with the Horde here. |
| 313 | 17 | say | 90 | Darkshire | Horde players | You're welcome to pass through, friend. We keep to ourselves. |

### 9. Other  (73 lines)

| id | grp | mode | wt | scope | targets | text |
|----|-----|------|----|-------|---------|------|
| 421 | 19 | say | 100 | ALL capitals | — | The Argent Crusade stands against the Scourge. Will you stand with us, {race}? |
| 422 | 19 | say | 90 | ALL capitals | — | We seek champions for the front. A {class} would be most welcome. |
| 423 | 19 | say | 90 | ALL capitals | — | Wear your colors with pride, {race}. The war is far from won. |
| 424 | 19 | say | 90 | ALL capitals | — | Every hero counts. Even one such as you might turn the tide. |
| 425 | 19 | say | 80 | ALL capitals | — | There is coin and honor both for those who fight for the cause. |
| 426 | 19 | say | 80 | ALL capitals | — | Rare to see a {class} unsworn to any banner. Consider ours. |
| 427 | 19 | say | 90 | ALL capitals | — | Speak with me if you'd earn the favor of my order, {race}. |
| 428 | 19 | say | 80 | ALL capitals | — | Tabards and titles mean nothing without the deeds to earn them. |
| 429 | 19 | say | 80 | ALL capitals | — | The dead do not tire, {race}. Neither, then, must we. |
| 430 | 19 | say | 80 | ALL capitals | — | You have the bearing of a champion. My order could use you. |
| 431 | 19 | say | 70 | ALL capitals | — | Old enemies make common cause against a common foe these days. |
| 432 | 19 | say | 80 | ALL capitals | — | Glory awaits the bold on the borderlands, {race}. Seek it. |
| 433 | 19 | say | 70 | ALL capitals | — | We remember our fallen. See that you honor them, {class}. |
| 434 | 19 | say | 70 | ALL capitals | — | The banner I carry has seen a hundred fields. It seeks a hundred more. |
| 501 | 20 | say | 80 | ALL capitals | race:Human | You humans do get everywhere. Ambitious lot, and no mistake. |
| 502 | 20 | say | 70 | ALL capitals | race:Human | A son or daughter of Stormwind, I'd wager. Long roads ahead of you. |
| 503 | 20 | say | 80 | ALL capitals | race:Orc | An orc, walking tall and proud. Strength and honor to you. |
| 504 | 20 | say | 70 | ALL capitals | race:Orc | May your axe stay sharp, orc, and your enemies few. |
| 505 | 20 | say | 80 | ALL capitals | race:Dwarf | A dwarf! Mind you don't drink us dry, friend. |
| 506 | 20 | say | 70 | ALL capitals | race:Dwarf | Stout as the mountain, you dwarves — and twice as hard-headed. |
| 507 | 20 | say | 80 | ALL capitals | race:NightElf | A child of the stars. You night elves make an old soul feel young. |
| 508 | 20 | say | 70 | ALL capitals | race:NightElf | Elune's grace upon you, kaldorei. You walk far from your groves. |
| 509 | 20 | say | 80 | ALL capitals | race:Undead | A Forsaken... forgive my flinch. Old fears die hard, friend. |
| 510 | 20 | say | 70 | ALL capitals | race:Undead | You wear death lightly, Forsaken. I'll not pretend it's easy to see. |
| 511 | 20 | say | 80 | ALL capitals | race:Tauren | An Earthmother's child. You tauren carry such a gentle strength. |
| 512 | 20 | say | 70 | ALL capitals | race:Tauren | So tall, so calm. The tauren shame the rest of us for temper. |
| 513 | 20 | say | 80 | ALL capitals | race:Gnome | A gnome! Mind the cobbles — I'd hate to tread on a genius. |
| 514 | 20 | say | 70 | ALL capitals | race:Gnome | Tinkering again, no doubt. You gnomes never sit still, do you? |
| 515 | 20 | say | 80 | ALL capitals | race:Troll | A troll, and mannered too. The old stories don't do you justice. |
| 516 | 20 | say | 70 | ALL capitals | race:Troll | Them tusks give me a start, but you carry yourself well, troll. |
| 517 | 20 | say | 80 | ALL capitals | race:BloodElf | A sin'dorei. You blood elves wear your pride like fine silk. |
| 518 | 20 | say | 70 | ALL capitals | race:BloodElf | The Sunwell's children walk among us. Strange days indeed. |
| 519 | 20 | say | 80 | ALL capitals | race:Draenei | A draenei — so tall! The Light shines strange and bright in you. |
| 520 | 20 | say | 70 | ALL capitals | race:Draenei | From beyond the stars, they say. You draenei have seen much grief. |
| 541 | 21 | say | 80 | ALL capitals | class:Warrior | A warrior's hands, scarred and steady. You've earned those. |
| 542 | 21 | say | 70 | ALL capitals | class:Warrior | No tricks for you, eh warrior? Just steel and will. I respect it. |
| 543 | 21 | say | 80 | ALL capitals | class:Paladin | The Light walks with you, paladin. We sleep safer for your kind. |
| 544 | 21 | say | 70 | ALL capitals | class:Paladin | Armor and faith both, paladin. A fine pairing in dark times. |
| 545 | 21 | say | 80 | ALL capitals | class:Hunter | Where's your beast, hunter? Left it outside, I do hope. |
| 546 | 21 | say | 70 | ALL capitals | class:Hunter | A steady eye and a loyal companion. You hunters want for little. |
| 547 | 21 | say | 80 | ALL capitals | class:Rogue | Didn't hear you approach, {class}. ...I never do, do I? |
| 548 | 21 | say | 70 | ALL capitals | class:Rogue | Keep those clever fingers to yourself, rogue. All in good humor. |
| 549 | 21 | say | 80 | ALL capitals | class:Priest | Bless you, priest. The wounded and weary are in your debt. |
| 550 | 21 | say | 70 | ALL capitals | class:Priest | Faith is a heavy burden to carry, priest. You wear it well. |
| 551 | 21 | say | 80 | ALL capitals | class:DeathKnight | A death knight. The grave gave you back — use the gift well. |
| 552 | 21 | say | 70 | ALL capitals | class:DeathKnight | Cold comes off you like winter, death knight. But you fight for the living now. |
| 553 | 21 | say | 80 | ALL capitals | class:Shaman | The elements whisper around you, shaman. I feel the air change. |
| 554 | 21 | say | 70 | ALL capitals | class:Shaman | Earth, wind, fire and water — all your kin, shaman. What a thing. |
| 555 | 21 | say | 80 | ALL capitals | class:Mage | Mind the sparks, mage. My thatch roof thanks you in advance. |
| 556 | 21 | say | 70 | ALL capitals | class:Mage | A mage's work is never dull, nor safe. Do be careful in the streets. |
| 557 | 21 | say | 80 | ALL capitals | class:Warlock | Keep your... friends leashed, warlock. Folk here are the nervous sort. |
| 558 | 21 | say | 70 | ALL capitals | class:Warlock | Dark power, darker bargains. I'll not ask the price, warlock. |
| 559 | 21 | say | 80 | ALL capitals | class:Druid | The wilds sent you, druid? You smell of pine and open sky. |
| 560 | 21 | say | 70 | ALL capitals | class:Druid | Claw, feather or leaf today, druid? You shapechangers keep us guessing. |
| 581 | 22 | say | 80 | ALL capitals | gear:256 | A swordsman's stance. Honest steel — nothing wrong with that. |
| 582 | 22 | say | 80 | ALL capitals | gear:512 | That axe has split more than firewood, I'd wager. Heavy work. |
| 583 | 22 | say | 80 | ALL capitals | gear:1024 | A good mace ends an argument quick. Blunt, like my old mother. |
| 584 | 22 | say | 70 | ALL capitals | gear:2048 | Reach and weight both, that polearm. Keep it clear of the awnings. |
| 585 | 22 | say | 80 | ALL capitals | gear:4096 | Small blade, quick hands. I'll keep my coin purse close, {race}. |
| 586 | 22 | say | 70 | ALL capitals | gear:8192 | A scholar's staff — or a cracked skull waiting to happen. Both, maybe. |
| 587 | 22 | say | 70 | ALL capitals | gear:16384 | Bare hands and a bit of steel? Bold way to fight, {class}. |
| 588 | 22 | say | 80 | ALL capitals | gear:32768 | A fine bow. Steady in the draw, I'd guess. Don't aim it near me! |
| 589 | 22 | say | 70 | ALL capitals | gear:65536 | A firearm! Loud, smelly things — effective, mind, but loud. |
| 590 | 22 | say | 70 | ALL capitals | gear:2H | That two-hander's taller than my youngest. Mind the doorframes. |
| 591 | 22 | say | 80 | ALL capitals | gear:shield | Shield on your arm — a defender's heart. We need more like you. |
| 601 | 23 | say | 80 | ALL capitals | gear:plate | Head to toe in plate! You must sound like a cart on the cobbles. |
| 602 | 23 | say | 70 | ALL capitals | gear:plate | Fine steel plate, {race}. The smiths did right by you. |
| 603 | 23 | say | 80 | ALL capitals | gear:mail | Mail and mettle. Practical — moves with you, keeps the edge off. |
| 604 | 23 | say | 70 | ALL capitals | gear:mail | Chainmail suits you, {race}. Not too heavy, not too light. |
| 605 | 23 | say | 80 | ALL capitals | gear:leather | Supple leather, quiet steps. A practical sort, aren't you? |
| 606 | 23 | say | 70 | ALL capitals | gear:leather | Leathers well worn, {race}. The road's left its mark on them. |
| 607 | 23 | say | 80 | ALL capitals | gear:cloth | Robes and cloth — a caster's garb. Mind the mud; it never comes out. |
| 608 | 23 | say | 70 | ALL capitals | gear:cloth | Fine cloth, that. Enchanted, is it? I daren't ask what it cost. |

Total lines: 382

### 1. Guards  (30 lines)

| id | role | grp | mode | wt | scope | targets | text |
|----|------|-----|------|----|-------|---------|------|
| 1 | GUARD | 1 | say | 100 | ALL capitals | — | Well met, {race}. Keep to the roads and you'll have no trouble here. |
| 2 | GUARD | 1 | say | 100 | ALL capitals | — | Move along, citizen. The watch has its eyes open. |
| 3 | GUARD | 1 | say | 90 | ALL capitals | — | Stay sharp, {class}. These are uneasy times. |
| 4 | GUARD | 1 | say | 70 | ALL capitals | — | Another {race} in the city? Good — we can use steady hands. |
| 5 | GUARD | 1 | say | 80 | ALL capitals | — | Mind yourself in the crowds, {race}. |
| 6 | GUARD | 2 | say | 90 | ALL capitals | gear:weapon | That {weapon_type} of yours has seen use, I'd wager. |
| 7 | GUARD | 2 | say | 90 | ALL capitals | epic+ | Fine gear, {class}. You've earned your place. |
| 8 | GUARD | 2 | say | 90 | ALL capitals | gear:shield | A shield-bearer. You'd make a fine addition to the watch. |
| 9 | GUARD | 2 | say | 80 | ALL capitals | gear:2H | Mind that big blade indoors, {race}. |
| 10 | GUARD | 2 | say | 80 | ALL capitals | gear:plate | Plate and steel — a proper soldier's kit. |
| 11 | GUARD | 2 | say | 80 | ALL capitals | gear:ranged | Keep that string dry, {race}. You never know. |
| 12 | GUARD | 3 | say | 80 | ALL capitals | class:Mage | A mage in our streets. Try not to set anything alight, hm? |
| 13 | GUARD | 3 | say | 80 | ALL capitals | class:Paladin | The Light guide you, {race}. |
| 14 | GUARD | 3 | say | 80 | ALL capitals | class:Rogue | Hands where I can see them, {class}. |
| 15 | GUARD | 3 | say | 80 | ALL capitals | class:Hunter | Leave the beast outside the bank, would you? |
| 16 | GUARD | 3 | say | 80 | ALL capitals | class:Warrior | A warrior's stride. You carry yourself well, {race}. |
| 17 | GUARD | 3 | say | 80 | ALL capitals | class:Priest | Blessings, {class}. The wounded will thank you. |
| 18 | GUARD | 3 | say | 70 | ALL capitals | class:DeathKnight | ...A death knight. We watch your kind closely. |
| 19 | GUARD | 3 | say | 70 | ALL capitals | class:Warlock | Keep your companions leashed, {class}. |
| 20 | GUARD | 3 | say | 80 | ALL capitals | class:Druid | The wilds send us one of their own. Welcome, {race}. |
| 21 | GUARD | 3 | say | 80 | ALL capitals | class:Shaman | The elements favor you, {class}? We'll take the luck. |
| 22 | GUARD | 4 | say | 70 | ALL capitals | Alliance players | For the Alliance, {race}. Stand tall. |
| 23 | GUARD | 4 | say | 70 | ALL capitals | Horde players | Lok'tar, {race}. Strength and honor. |
| 30 | GUARD | 5 | say | 60 | ALL capitals | — | No brawling in the streets, {class}. Take it to the ring. |
| 31 | GUARD | 5 | say | 60 | ALL capitals | — | Watch your purse in the market, {race}. |
| 32 | GUARD | 6 | whisper | 50 | ALL capitals | — | Psst — fresh goods at the auction house, {race}. You didn't hear it from me. |
| 33 | GUARD | 6 | whisper | 50 | ALL capitals | — | Between us, {class}, the quarter's been jumpy all week. |
| 34 | GUARD | 6 | emote | 60 | ALL capitals | — | sizes you up with a soldier's glance. |
| 35 | GUARD | 6 | emote | 60 | ALL capitals | — | nods respectfully as you pass. |
| 36 | GUARD | 6 | emote | 50 | ALL capitals | — | snaps to attention as the {race} approaches. |

### 2. Guards (faction/city-specific)  (6 lines)

| id | role | grp | mode | wt | scope | targets | text |
|----|------|-----|------|----|-------|---------|------|
| 24 | GUARD | 4 | say | 90 | Stormwind | — | Welcome to Stormwind, {race}. The king's peace holds here. |
| 25 | GUARD | 4 | say | 90 | Ironforge | — | Ironforge welcomes you, {race}. Mind the forge-heat. |
| 26 | GUARD | 4 | say | 90 | Orgrimmar | — | Orgrimmar's gates are open to you, {race}. |
| 27 | GUARD | 4 | say | 90 | ThunderBluff | — | Walk gently on the rise, {race}. The winds are watching. |
| 28 | GUARD | 4 | say | 90 | Undercity | — | The Dark Lady watches over us, {race}. |
| 29 | GUARD | 4 | say | 90 | Darnassus | — | Elune guide your steps, {race}. |

### 3. Citizens (all capitals, not Dalaran)  (54 lines)

| id | role | grp | mode | wt | scope | targets | text |
|----|------|-----|------|----|-------|---------|------|
| 101 | CITIZEN | 7 | say | 100 | ALL capitals | — | Fine weather for it, eh? The crops'll be glad of the sun. |
| 102 | CITIZEN | 7 | say | 100 | ALL capitals | — | Rain's coming, mark my words. My knee never lies. |
| 103 | CITIZEN | 7 | say | 90 | ALL capitals | — | Cold enough to freeze the well again. Mind your step. |
| 104 | CITIZEN | 7 | say | 100 | ALL capitals | — | A fair morning to you, {race}. |
| 105 | CITIZEN | 8 | say | 100 | ALL capitals | — | Have you seen my hen? Brown thing, foul temper. Wanders off daily. |
| 106 | CITIZEN | 8 | say | 90 | ALL capitals | — | The chickens won't lay in this heat. Stubborn birds. |
| 107 | CITIZEN | 8 | say | 90 | ALL capitals | — | Mind the geese by the water — they'll have your fingers. |
| 108 | CITIZEN | 8 | say | 100 | ALL capitals | — | The grain hauls came in light this season. Millers are grumbling. |
| 109 | CITIZEN | 8 | say | 90 | ALL capitals | — | Flour's dear this month. Everything's dear this month. |
| 110 | CITIZEN | 8 | say | 90 | ALL capitals | — | Hauled sacks since dawn. My back's not what it was. |
| 111 | CITIZEN | 9 | say | 90 | ALL capitals | — | They say the king's advisors can't agree on the time of day. |
| 112 | CITIZEN | 9 | say | 90 | ALL capitals | — | Heard there's trouble at the border again. Always is. |
| 113 | CITIZEN | 9 | say | 90 | ALL capitals | — | The nobles feast while we count coppers. Same as ever. |
| 114 | CITIZEN | 9 | say | 100 | ALL capitals | — | Word is a hero passed through. Suppose that'd be you, {race}? |
| 115 | CITIZEN | 9 | say | 80 | ALL capitals | — | Taxes up again. A hero wouldn't notice, but we feel it. |
| 116 | CITIZEN | 10 | say | 100 | ALL capitals | — | Good day to you. Mind how you go. |
| 117 | CITIZEN | 10 | say | 80 | ALL capitals | — | Spare a kind word for an honest worker? |
| 118 | CITIZEN | 10 | say | 100 | ALL capitals | — | Bless you, traveller. Safe roads. |
| 119 | CITIZEN | 10 | say | 80 | ALL capitals | — | Don't mind me, just resting my feet a moment. |
| 120 | CITIZEN | 10 | say | 90 | ALL capitals | — | Busy day at market. Everyone wants everything at once. |
| 121 | CITIZEN | 10 | say | 90 | ALL capitals | — | You'll want the inn if you're after a bed. Just down the way. |
| 122 | CITIZEN | 10 | say | 90 | ALL capitals | — | Watch your purse in the crowd, friend. Cutpurses about. |
| 123 | CITIZEN | 10 | say | 90 | ALL capitals | — | Another day, another copper. Such is life. |
| 124 | CITIZEN | 10 | say | 80 | ALL capitals | — | The bells ring soon. Best be about my errands. |
| 125 | CITIZEN | 10 | say | 90 | ALL capitals | — | Ah, to be young and off seeing the world, like you. |
| 126 | CITIZEN | 11 | say | 90 | ALL capitals | — | A {class}, are you? We don't see many of your sort round here. |
| 127 | CITIZEN | 11 | say | 80 | ALL capitals | epic+ | That's fine armor for a common street, {race}. Off adventuring? |
| 128 | CITIZEN | 11 | say | 90 | ALL capitals | gear:weapon | Careful swinging that {weapon_type} about — you'll frighten the little ones. |
| 129 | CITIZEN | 11 | say | 90 | ALL capitals | — | A {race} in these parts? Well, times are changing. |
| 130 | CITIZEN | 11 | say | 90 | ALL capitals | — | You've the look of someone with somewhere to be, {class}. |
| 131 | CITIZEN | 11 | say | 80 | ALL capitals | gear:weapon | Best keep that {weapon_type} sheathed near the stalls, aye? |
| 132 | CITIZEN | 11 | say | 90 | ALL capitals | — | Off to slay something dreadful, no doubt. Rather you than me, {race}. |
| 401 | CRIER | 18 | say | 100 | ALL capitals | — | Hear ye, hear ye! The city stands strong under watchful eyes! |
| 402 | CRIER | 18 | say | 90 | ALL capitals | — | Oyez! Mind the law and keep the peace, good folk! |
| 403 | CRIER | 18 | say | 90 | ALL capitals | — | Fresh word from the front — stay vigilant, and stay proud! |
| 404 | CRIER | 18 | say | 90 | ALL capitals | — | Hear ye! A {class} walks among us this very day! |
| 405 | CRIER | 18 | say | 80 | ALL capitals | — | Step lively, citizens! The market bells ring within the hour! |
| 406 | CRIER | 18 | say | 90 | ALL capitals | — | Make way, make way! A {race} of note passes through! |
| 407 | CRIER | 18 | say | 80 | ALL capitals | — | By order of the city — no brawling, no thieving, no mischief! |
| 408 | CRIER | 18 | say | 80 | ALL capitals | — | Tidings, tidings! The taverns are open and the ale is cold! |
| 409 | CRIER | 18 | say | 90 | ALL capitals | — | Honor to the brave this day, and a wary eye to the rest! |
| 410 | CRIER | 18 | say | 80 | ALL capitals | — | All able hands are welcome to the city's defense — hear ye! |
| 411 | CRIER | 18 | say | 80 | ALL capitals | — | Mind your purses in the crowd, and mind the King's law! |
| 412 | CRIER | 18 | say | 80 | ALL capitals | — | Oyez! The roads grow bold with heroes — glory to the realm! |
| 621 | any | 24 | say | 80 | ALL capitals | Alliance players | For the Alliance! Good to see the banner carried proud, {race}. |
| 622 | any | 24 | say | 70 | ALL capitals | Alliance players | Stormwind, Ironforge, Darnassus, the Exodar — one people, one cause. |
| 623 | any | 24 | say | 70 | ALL capitals | Alliance players | The Light and the King keep us. Stand tall, {race} of the Alliance. |
| 624 | any | 24 | say | 80 | ALL capitals | Horde players | Lok'tar ogar, {race}! Victory or death — the Horde endures. |
| 625 | any | 24 | say | 70 | ALL capitals | Horde players | For the Warchief! The Horde is family, forged in fire. |
| 626 | any | 24 | say | 70 | ALL capitals | Horde players | Blood and thunder, {race}. The Horde bows to no one. |
| 627 | any | 25 | say | 70 | ALL capitals | — | The Light watches over the faithful. May it guide your road, {race}. |
| 628 | any | 25 | say | 60 | ALL capitals | — | Some pray to the Light, some the elements, some older things. All welcome. |
| 629 | any | 25 | say | 70 | ALL capitals | — | Faith carries folk through dark seasons, {class}. Hold to yours. |
| 630 | any | 25 | say | 60 | ALL capitals | — | Elune, the Light, the Earthmother — many names, one hope, I say. |

### 4. Dalaran  (40 lines)

| id | role | grp | mode | wt | scope | targets | text |
|----|------|-----|------|----|-------|---------|------|
| 201 | any | 12 | say | 100 | Dalaran | — | Welcome to Dalaran, {race}. Mind the wards — they bite the careless. |
| 202 | any | 12 | say | 100 | Dalaran | — | Greetings, traveller. The Eventide is lovely at this hour. |
| 203 | any | 12 | say | 90 | Dalaran | — | A good day beneath the violet dome, wouldn't you say? |
| 204 | any | 12 | say | 100 | Dalaran | — | Fresh from the world below, {race}? The city floats far from home. |
| 205 | any | 12 | say | 80 | Dalaran | — | Tea? No? More for me, then. |
| 206 | any | 12 | say | 90 | Dalaran | — | Stay a while. Dalaran rewards the curious. |
| 207 | any | 12 | say | 90 | Dalaran | — | Another {race} seeking their fortune. The city welcomes you. |
| 208 | any | 12 | say | 90 | Dalaran | — | Good day to you. Do try not to wander into a portal. |
| 209 | any | 12 | say | 80 | Dalaran | — | The Legerdemain pours a fine wine, if you've the coin. |
| 210 | any | 12 | say | 90 | Dalaran | — | You'll find no finer libraries in all the world. |
| 211 | any | 12 | say | 90 | Dalaran | — | Don't look down. The city floats, and the ground is very far. |
| 212 | any | 12 | say | 90 | Dalaran | — | Books, scrolls, reagents — we trade in wonders here. |
| 213 | any | 12 | say | 90 | Dalaran | — | New apprentices arrive daily. The halls have never been busier. |
| 214 | any | 12 | say | 90 | Dalaran | — | If you seek the Violet Citadel, mind your manners inside. |
| 215 | any | 12 | say | 100 | Dalaran | — | Welcome, welcome. Mind the enchantments and enjoy your stay, {race}. |
| 226 | any | 12 | say | 90 | Dalaran | — | A {class} walks among us. How refreshing. |
| 227 | any | 12 | say | 90 | Dalaran | — | You carry yourself well for one so far from home, {race}. |
| 228 | any | 12 | say | 80 | Dalaran | — | You've the look of the battlefield about you. Rest a while. |
| 229 | any | 12 | say | 80 | Dalaran | — | A hero, are you? We get a few. Do try not to break anything. |
| 230 | any | 12 | say | 80 | Dalaran | — | The magi could learn a thing from a seasoned {class}, I'd wager. |
| 216 | any | 13 | say | 90 | Dalaran | — | The arcane hums strong today. Can you feel it? |
| 217 | any | 13 | say | 90 | Dalaran | — | Watch your step near the portals. We lose a tourist most weeks. |
| 218 | any | 13 | say | 80 | Dalaran | — | Mind the mages muttering to themselves — usually harmless. |
| 219 | any | 13 | say | 80 | Dalaran | — | Arcane wards, a flying city — and still the tea goes cold. |
| 220 | any | 13 | say | 80 | Dalaran | — | The magi keep us aloft. Best not ask how. |
| 221 | any | 13 | say | 80 | Dalaran | — | The dome keeps the weather out. Small mercies. |
| 222 | any | 13 | say | 80 | Dalaran | — | Mind the sewers below — not everything down there is friendly. |
| 223 | any | 13 | say | 90 | Dalaran | gear:weapon | Careful with that {weapon_type} indoors, {race}. This is a city of scholars. |
| 224 | any | 13 | say | 90 | Dalaran | rare+ | Lovely enchantment on that gear, {race}. Dalaran work, perhaps? |
| 225 | any | 13 | say | 80 | Dalaran | epic+ | Such finery. You've done well for yourself out there, {race}. |
| 231 | any | 14 | say | 35 | Dalaran | — | The Kirin Tor watch over us all. Six minds, one purpose. |
| 232 | any | 14 | say | 35 | Dalaran | — | Old Dalaran fell to Archimonde's fire. This city rose from that grief. |
| 233 | any | 14 | say | 35 | Dalaran | — | They say Antonidas himself once walked these halls. A great loss, his. |
| 234 | any | 14 | say | 35 | Dalaran | — | We raised the city and flew it north to face the Lich King. Bold days. |
| 235 | any | 14 | say | 35 | Dalaran | — | The Violet Hold keeps darker things than you'd care to meet, {race}. |
| 236 | any | 14 | say | 35 | Dalaran | — | Archmage Rhonin leads the Kirin Tor now. A dragon's pupil, they whisper. |
| 237 | any | 14 | say | 35 | Dalaran | — | Silver Covenant or Sunreaver — we all breathe the same arcane air. Mostly. |
| 238 | any | 14 | say | 30 | Dalaran | — | Lady Proudmoore studied under Antonidas, once. Before it all. |
| 239 | any | 14 | say | 30 | Dalaran | — | The Council of Six speaks, and the city listens. Wise to do the same. |
| 240 | any | 14 | say | 30 | Dalaran | — | The Legion, the Scourge, the Lich King — Dalaran has weathered every storm. |

### 5. Darkshire  (42 lines)

| id | role | grp | mode | wt | scope | targets | text |
|----|------|-----|------|----|-------|---------|------|
| 301 | CITIZEN | 15 | say | 100 | Darkshire | — | Oh! You startled me. Forgive an old worrier. |
| 302 | CITIZEN | 15 | say | 100 | Darkshire | — | Light preserve us — oh, it's only you. Welcome, {race}. |
| 303 | CITIZEN | 15 | say | 90 | Darkshire | — | A visitor! We don't get many brave enough for Darkshire. |
| 304 | CITIZEN | 15 | say | 90 | Darkshire | — | Bless you for coming. It's been a fearful season, truly. |
| 305 | CITIZEN | 15 | say | 90 | Darkshire | — | Good day — oh, do forgive my nerves. One learns to jump, here. |
| 306 | CITIZEN | 15 | say | 90 | Darkshire | — | You gave me a fright! But a friendly face is always welcome. |
| 319 | CITIZEN | 15 | say | 90 | Darkshire | — | A {class}, thank the Light. We could use a stout heart round here. |
| 320 | CITIZEN | 15 | say | 80 | Darkshire | — | You'll keep us safe if it comes to it, won't you? Please say you will. |
| 321 | CITIZEN | 15 | say | 80 | Darkshire | gear:weapon | Keep that {weapon_type} close after sundown. You'll want it. |
| 322 | CITIZEN | 15 | say | 90 | Darkshire | — | Fine armor. Are you here to help? Oh, say you're here to help us. |
| 323 | CITIZEN | 15 | say | 100 | Darkshire | — | Oh — hello there. Do come in off the road, it's safer. |
| 324 | CITIZEN | 15 | say | 90 | Darkshire | — | A friendly face! You don't know how rare that is these days. |
| 325 | CITIZEN | 15 | say | 90 | Darkshire | — | Mind how you go, {race}. And... thank you for stopping. |
| 330 | CITIZEN | 15 | say | 90 | Darkshire | — | You've a kind look about you, {class}. That eases my heart a little. |
| 331 | CITIZEN | 15 | say | 80 | Darkshire | — | Stay for a meal, if you like. Company keeps the fear at bay. |
| 334 | CITIZEN | 15 | say | 90 | Darkshire | — | Bless you for passing through. It gets lonely behind these walls. |
| 336 | CITIZEN | 15 | say | 80 | Darkshire | — | You carry yourself like someone who's seen a fight. That's a comfort. |
| 337 | CITIZEN | 15 | say | 90 | Darkshire | — | Careful out there. And... come back safe, won't you? |
| 339 | CITIZEN | 15 | say | 90 | Darkshire | — | A traveller with steel and steady hands. Light be praised. |
| 342 | CITIZEN | 15 | say | 90 | Darkshire | — | Kind of you to ask after us. We manage. We always have. |
| 314 | CITIZEN | 16 | say | 90 | Darkshire | — | Best indoors before dark. The woods... they don't sleep, you know. |
| 315 | CITIZEN | 16 | say | 80 | Darkshire | — | Did you hear that? ...No? Only nerves. Pay me no mind. |
| 316 | CITIZEN | 16 | say | 90 | Darkshire | — | Stay to the lit paths. Duskwood keeps its secrets in the shadow. |
| 317 | CITIZEN | 16 | say | 90 | Darkshire | — | The nights are long here. Longer still when the dead don't rest. |
| 318 | CITIZEN | 16 | say | 90 | Darkshire | — | Mind the graveyard, {race}. Some who lie there don't always stay. |
| 326 | CITIZEN | 16 | say | 80 | Darkshire | — | Was that a wolf? ...I do hope that was a wolf. |
| 327 | CITIZEN | 16 | say | 90 | Darkshire | — | Lock your shutters after dusk. We all do, here. |
| 328 | CITIZEN | 16 | say | 80 | Darkshire | — | The lamplighter's late again. I don't like the dark. I don't. |
| 329 | CITIZEN | 16 | say | 80 | Darkshire | — | They say something moved in the old orchard. I don't go there now. |
| 333 | CITIZEN | 16 | say | 80 | Darkshire | — | Hush — did you hear it too? ...No? Just the wind. Just the wind. |
| 335 | CITIZEN | 16 | say | 90 | Darkshire | — | Don't stray from the road, please. Duskwood swallows the careless. |
| 338 | CITIZEN | 16 | say | 80 | Darkshire | — | The candles gutter for no reason some nights. I try not to think on it. |
| 341 | CITIZEN | 16 | say | 80 | Darkshire | — | Some nights the fog comes right to the door. I sit up till dawn. |
| 307 | CITIZEN | 17 | say | 100 | Darkshire | race:Draenei | Oh! You startled me. Such a tall draenei — a pleasure, truly. |
| 308 | CITIZEN | 17 | say | 100 | Darkshire | race:Tauren | Goodness, a tauren! So very tall. N-nice to meet you, honestly. |
| 309 | CITIZEN | 17 | say | 100 | Darkshire | race:Troll | Oh — a troll! No trouble, I hope. Only manners here, I promise. |
| 310 | CITIZEN | 17 | say | 90 | Darkshire | race:NightElf | A night elf, abroad in daylight? These are strange times indeed. |
| 311 | CITIZEN | 17 | say | 100 | Darkshire | Horde players | We want no trouble. Alliance we may be, but no enemy of yours. |
| 312 | CITIZEN | 17 | say | 90 | Darkshire | Horde players | P-please, we're just simple folk. No quarrel with the Horde here. |
| 313 | CITIZEN | 17 | say | 90 | Darkshire | Horde players | You're welcome to pass through, friend. We keep to ourselves. |
| 332 | CITIZEN | 17 | say | 90 | Darkshire | — | A {race}? Goodness. Well — you're very welcome, of course. |
| 340 | CITIZEN | 17 | say | 90 | Darkshire | — | No trouble, I hope? We keep the peace here, best we can. |

### 6. Vendors (all cities)  (42 lines)

| id | role | grp | mode | wt | scope | targets | text |
|----|------|-----|------|----|-------|---------|------|
| 700 | VENDOR | 26 | say | 100 | ALL capitals | — | Welcome, {race}. Care to see my wares? |
| 701 | VENDOR | 26 | say | 100 | ALL capitals | — | Good day to you. Something catch your eye? |
| 702 | VENDOR | 26 | say | 100 | ALL capitals | — | Browse at your leisure, friend. No obligation. |
| 703 | VENDOR | 26 | say | 100 | ALL capitals | — | Fine goods, fair prices. How may I help you? |
| 704 | VENDOR | 26 | say | 90 | ALL capitals | — | A pleasure. Everything you see is for sale. |
| 705 | VENDOR | 26 | say | 90 | ALL capitals | — | Looking for something particular, {race}? |
| 706 | VENDOR | 26 | say | 90 | ALL capitals | — | Welcome to my stall. Take your time. |
| 707 | VENDOR | 26 | say | 80 | ALL capitals | — | Coin well spent is coin well kept. What'll it be? |
| 708 | VENDOR | 26 | say | 90 | ALL capitals | — | Ah, a customer! Do come in, do come in. |
| 709 | VENDOR | 26 | say | 90 | ALL capitals | — | Quality goods, honestly priced. Have a look. |
| 710 | VENDOR | 26 | say | 80 | ALL capitals | — | Trade, barter, or browse — you're welcome either way. |
| 711 | VENDOR | 26 | say | 90 | ALL capitals | — | How can I be of service today, {class}? |
| 712 | VENDOR | 26 | say | 80 | ALL capitals | — | Everything's fresh in this morning. See anything you like? |
| 713 | VENDOR | 26 | say | 80 | ALL capitals | — | Step right up — no need to be shy. |
| 714 | VENDOR | 26 | say | 90 | ALL capitals | — | A fine day for business. What are you after? |
| 715 | VENDOR | 26 | say | 80 | ALL capitals | — | You'll not find better wares this side of the square. |
| 716 | VENDOR | 26 | say | 90 | ALL capitals | — | Take your pick, {race}. I stand behind all I sell. |
| 717 | VENDOR | 26 | say | 80 | ALL capitals | — | Greetings. My stock is yours to peruse. |
| 718 | VENDOR | 26 | say | 90 | ALL capitals | — | Good to see a paying customer. What can I get you? |
| 719 | VENDOR | 26 | say | 80 | ALL capitals | — | Interested in a trade? I drive a fair bargain. |
| 720 | VENDOR | 26 | say | 90 | ALL capitals | — | Welcome, welcome. Gold or goods, I deal in both. |
| 721 | VENDOR | 26 | say | 80 | ALL capitals | — | Something for the road, perhaps? I've plenty. |
| 722 | VENDOR | 26 | say | 80 | ALL capitals | — | Have a look around. Ask if aught catches your fancy. |
| 723 | VENDOR | 26 | say | 90 | ALL capitals | — | A warm welcome, traveller. Wares aplenty here. |
| 740 | VENDOR | 27 | say | 70 | ALL capitals | — | Buy something, won't you? My cat's got expensive tastes. |
| 741 | VENDOR | 27 | say | 70 | ALL capitals | — | Half of this I can't explain, but it all sells. |
| 742 | VENDOR | 27 | say | 60 | ALL capitals | — | No refunds, no haggling, and no — that one's not cursed. Probably. |
| 743 | VENDOR | 27 | say | 60 | ALL capitals | — | I could sell sand to a gnome, me. Care to test that? |
| 744 | VENDOR | 27 | say | 60 | ALL capitals | — | Everything must go! ...well, except the stool. I like the stool. |
| 745 | VENDOR | 27 | say | 60 | ALL capitals | — | That one? Fell off a caravan. Perfectly legal, I assure you. |
| 746 | VENDOR | 27 | say | 60 | ALL capitals | — | Prices go up when it rains. Best buy now, eh? |
| 747 | VENDOR | 27 | say | 60 | ALL capitals | — | I once sold a boot to a king. Just the one. Long story. |
| 748 | VENDOR | 27 | say | 60 | ALL capitals | — | You break it, you've bought a story. And the item. |
| 749 | VENDOR | 27 | say | 60 | ALL capitals | — | My grandmother enchanted these. Don't ask which grandmother. |
| 760 | VENDOR | 28 | say | 80 | ALL capitals | — | That tabard's a fine cut, {race}. Saw one like it on a lord last week. |
| 761 | VENDOR | 28 | say | 80 | ALL capitals | — | Lovely trinket you're wearing. Half the square's been asking after those. |
| 762 | VENDOR | 28 | say | 70 | ALL capitals | — | Such finery! You'll set a fashion in the streets, mark me. |
| 763 | VENDOR | 28 | say | 70 | ALL capitals | — | I saw a {class} stroll by in gold-trimmed plate this morning. Quite the sight. |
| 764 | VENDOR | 28 | say | 70 | ALL capitals | — | Word is the nobles all wear enchanted cloaks now. You'd fit right in. |
| 765 | VENDOR | 28 | say | 70 | ALL capitals | — | Fine boots on you. A cobbler two stalls down would weep with envy. |
| 766 | VENDOR | 28 | say | 70 | ALL capitals | — | Everyone's after gemmed rings of late. You've an eye for style, {race}. |
| 767 | VENDOR | 28 | say | 80 | ALL capitals | rare+ | That armor's turning heads, {class}. Where does one come by such? |

### 7. Dalaran factions (Sunreaver/Violet Hold/Sky-Reaver/Skybreaker)  (94 lines)

| id | role | grp | mode | wt | scope | targets | text |
|----|------|-----|------|----|-------|---------|------|
| 1000 | SUNREAVER | 29 | say | 100 | Dalaran | — | Move along, {race}. The Sunreavers keep the peace here. |
| 1001 | SUNREAVER | 29 | say | 90 | Dalaran | — | We watch. We remember. Mind your conduct in Dalaran. |
| 1002 | SUNREAVER | 29 | say | 90 | Dalaran | — | Aethas Sunreaver vouches for us. That is all you need know. |
| 1003 | SUNREAVER | 29 | say | 90 | Dalaran | — | The Kirin Tor tolerate us. Do not test that tolerance. |
| 1004 | SUNREAVER | 29 | say | 80 | Dalaran | — | Eyes forward, {race}. Nothing here concerns you. |
| 1005 | SUNREAVER | 29 | say | 80 | Dalaran | — | The Horde has friends in high places now. We are those friends. |
| 1006 | SUNREAVER | 29 | say | 80 | Dalaran | — | Magic is a blade like any other. We hold ours ready. |
| 1007 | SUNREAVER | 29 | say | 80 | Dalaran | — | State your business or state nothing at all. |
| 1008 | SUNREAVER | 29 | say | 80 | Dalaran | — | You are watched, {class}. All are watched. It is nothing personal. |
| 1009 | SUNREAVER | 29 | say | 80 | Dalaran | — | The Sunreavers answer to Silvermoon, and to none of you. |
| 1010 | SUNREAVER | 29 | say | 80 | Dalaran | — | Keep your spells sheathed. This is neutral ground, for now. |
| 1011 | SUNREAVER | 29 | say | 80 | Dalaran | — | We are not your enemy today. See that it stays that way. |
| 1012 | SUNREAVER | 29 | say | 70 | Dalaran | — | Quiet feet, quieter tongue. That is how one survives Dalaran. |
| 1013 | SUNREAVER | 29 | say | 80 | Dalaran | — | I have no quarrel with you. Give me no reason to find one. |
| 1014 | SUNREAVER | 29 | say | 70 | Dalaran | — | The floating city has many secrets. Do not go seeking ours. |
| 1015 | SUNREAVER | 29 | say | 80 | Dalaran | — | Pass freely, {race}. But know that we are counting. |
| 1016 | SUNREAVER | 29 | say | 70 | Dalaran | — | Order is a fragile thing here. We are what keeps it whole. |
| 1017 | SUNREAVER | 29 | say | 70 | Dalaran | — | You wear your allegiance loudly. We wear ours in silence. |
| 1070 | SUNREAVER | 30 | say | 90 | Dalaran | Alliance players | An Alliance {race}. How... diplomatic of you to visit. |
| 1071 | SUNREAVER | 30 | say | 90 | Dalaran | Alliance players | We are all Kirin Tor here. Do try to remember that, {race}. |
| 1072 | SUNREAVER | 30 | say | 80 | Dalaran | Alliance players | Smile all you like. I know exactly what you are. |
| 1073 | SUNREAVER | 30 | say | 80 | Dalaran | Alliance players | The Silver Enclave is that way. You would be happier there. |
| 1074 | SUNREAVER | 30 | say | 80 | Dalaran | Alliance players | No trouble from you today, Alliance. That is an order. |
| 1075 | SUNREAVER | 30 | say | 70 | Dalaran | Alliance players | Charming. Now keep walking, {race}. |
| 1076 | SUNREAVER | 30 | say | 80 | Dalaran | Alliance players | We share this city. We do not share my patience. Move along. |
| 1077 | SUNREAVER | 30 | say | 70 | Dalaran | Alliance players | How brave, an Alliance {class} in our quarter. How very brave. |
| 1100 | VIOLET_HOLD | 31 | say | 100 | Dalaran | level 75+ | Well met, champion. Few earn the right to stand where you stand. |
| 1101 | VIOLET_HOLD | 31 | say | 90 | Dalaran | rare+, level 75+ | That is fine armor, {race}. It will serve you well beyond that door. |
| 1102 | VIOLET_HOLD | 31 | say | 90 | Dalaran | level 75+ | A worthy {class}. The Hold has seen many heroes; you look the part. |
| 1103 | VIOLET_HOLD | 31 | say | 90 | Dalaran | level 75+ | Mind the wards as you enter. And good luck to you, truly. |
| 1104 | VIOLET_HOLD | 31 | say | 90 | Dalaran | level 75+ | Prepare well. What waits within does not forgive the careless. |
| 1105 | VIOLET_HOLD | 31 | say | 90 | Dalaran | level 75+ | Safe travels, {race}. Return to us, and return victorious. |
| 1106 | VIOLET_HOLD | 31 | say | 80 | Dalaran | gear:weapon, level 75+ | A splendid weapon. Keep it close where you are going. |
| 1107 | VIOLET_HOLD | 31 | say | 80 | Dalaran | level 75+ | The Kirin Tor thank you for your service, champion. |
| 1108 | VIOLET_HOLD | 31 | say | 80 | Dalaran | level 75+ | Steel yourself. Great foes have broken lesser heroes here. |
| 1109 | VIOLET_HOLD | 31 | say | 80 | Dalaran | level 75+ | That helm suits a warrior of your standing. Wear it with pride. |
| 1110 | VIOLET_HOLD | 31 | say | 80 | Dalaran | level 75+ | We guard the door so that you may face what lies beyond it. Go well. |
| 1111 | VIOLET_HOLD | 31 | say | 80 | Dalaran | level 75+ | Your aura is strong, {class}. The Hold could use more like you. |
| 1112 | VIOLET_HOLD | 31 | say | 80 | Dalaran | level 75+ | Check your blade, check your wards, then step through with confidence. |
| 1113 | VIOLET_HOLD | 31 | say | 80 | Dalaran | level 75+ | Many go in. The worthy come out. See that you are among them. |
| 1114 | VIOLET_HOLD | 31 | say | 80 | Dalaran | rare+, level 75+ | Fine craftsmanship, that gear. Northrend has tested it, I see. |
| 1115 | VIOLET_HOLD | 31 | say | 80 | Dalaran | level 75+ | Stand ready. The dragon's brood does not tire, and neither must you. |
| 1116 | VIOLET_HOLD | 31 | say | 80 | Dalaran | level 75+ | You carry yourself like a veteran, {race}. The Hold is in good hands. |
| 1117 | VIOLET_HOLD | 31 | say | 70 | Dalaran | level 75+ | May the Light — or whatever you hold sacred — see you through. |
| 1118 | VIOLET_HOLD | 31 | say | 70 | Dalaran | level 75+ | Rest before you enter. There is no rest once that gate opens. |
| 1119 | VIOLET_HOLD | 31 | say | 80 | Dalaran | level 75+ | Go with our thanks, champion. Few would dare what you dare. |
| 1200 | SKYREAVER | 32 | say | 100 | Dalaran | — | Hmph. Another one. State your business, {race}. |
| 1201 | SKYREAVER | 32 | say | 90 | Dalaran | — | The Horde owns the skies now. Try to keep up. |
| 1202 | SKYREAVER | 32 | say | 80 | Dalaran | — | Don't touch the airship. Last fool who did is still falling. |
| 1203 | SKYREAVER | 32 | say | 80 | Dalaran | — | You lost, {race}? The tavern's that way. Go on. |
| 1204 | SKYREAVER | 32 | say | 80 | Dalaran | — | Orgrim's Hammer flies for the Warchief. Remember that. |
| 1205 | SKYREAVER | 32 | say | 70 | Dalaran | — | Bah. Too much talking, not enough fighting in this city. |
| 1206 | SKYREAVER | 32 | say | 80 | Dalaran | — | Stand aside. Reaver business, not yours. |
| 1207 | SKYREAVER | 32 | say | 80 | Dalaran | — | You want something, {class}? Spit it out. I've no time. |
| 1208 | SKYREAVER | 32 | say | 70 | Dalaran | — | Strong grip, that. Maybe you're not useless after all. |
| 1209 | SKYREAVER | 32 | say | 80 | Dalaran | — | We fight. We fly. We don't chat. Move along. |
| 1210 | SKYREAVER | 32 | say | 70 | Dalaran | — | Dalaran's too soft. Give me the deck of a warship any day. |
| 1211 | SKYREAVER | 32 | say | 80 | Dalaran | — | Lok'tar, {race}. Now clear the landing before I clear it for you. |
| 1220 | SKYREAVER | 33 | say | 90 | Dalaran | Alliance players | An Alliance {race}. Charmed. Now don't linger. |
| 1221 | SKYREAVER | 33 | say | 80 | Dalaran | Alliance players | You fight well, for one of yours. There. A compliment. Happy? |
| 1222 | SKYREAVER | 33 | say | 80 | Dalaran | Alliance players | Brave of the Alliance to send a {class} up here. Or foolish. |
| 1223 | SKYREAVER | 33 | say | 80 | Dalaran | Alliance players | Nice armor. Shame about the colors. |
| 1224 | SKYREAVER | 33 | say | 70 | Dalaran | Alliance players | We're not fighting today, {race}. Pity. I was getting comfortable. |
| 1225 | SKYREAVER | 33 | say | 80 | Dalaran | Alliance players | You've some spine, Alliance. I'll grant you that and no more. |
| 1226 | SKYREAVER | 33 | say | 70 | Dalaran | Alliance players | Keep smiling, {race}. It'll make the next battlefield sweeter. |
| 1227 | SKYREAVER | 33 | say | 70 | Dalaran | Alliance players | Neutral ground. Lucky for you. Very lucky. |
| 1228 | SKYREAVER | 33 | say | 80 | Dalaran | Alliance players | Not bad, for Alliance work. Don't let it go to your head. |
| 1229 | SKYREAVER | 33 | say | 70 | Dalaran | Alliance players | You lot clean up nice. Under the tabard you're still the enemy. |
| 1230 | SKYREAVER | 33 | say | 70 | Dalaran | Alliance players | Enjoy the truce while it lasts, {class}. It won't. |
| 1231 | SKYREAVER | 33 | say | 70 | Dalaran | Alliance players | A polite nod, then. That's all you'll get from me, {race}. |
| 1300 | SKYBREAKER | 34 | say | 100 | Dalaran | — | Well met! You stand before a crew of the mighty Skybreaker. |
| 1301 | SKYBREAKER | 34 | say | 90 | Dalaran | — | Ho there, {race}! A fine day to serve the Alliance, is it not? |
| 1302 | SKYBREAKER | 34 | say | 80 | Dalaran | — | Chin up, shoulders back — you're in distinguished company now. |
| 1303 | SKYBREAKER | 34 | say | 80 | Dalaran | — | The Skybreaker patrols these skies. You may rest easy, citizen. |
| 1304 | SKYBREAKER | 34 | say | 80 | Dalaran | — | A hearty welcome, {class}! The Alliance is glad of stout hearts. |
| 1305 | SKYBREAKER | 34 | say | 80 | Dalaran | — | We fly for king and country, and we fly rather splendidly. |
| 1306 | SKYBREAKER | 34 | say | 80 | Dalaran | — | Stand tall, {race}. The finest airship in the fleet watches over you. |
| 1307 | SKYBREAKER | 34 | say | 70 | Dalaran | — | Vigor and valor, that's the Skybreaker way. Care to salute? |
| 1308 | SKYBREAKER | 34 | say | 80 | Dalaran | — | High Commander Wyrmbane runs a proud ship. The proudest, I'd say. |
| 1309 | SKYBREAKER | 34 | say | 70 | Dalaran | — | A pleasure, truly. One meets such fine folk in Dalaran. |
| 1310 | SKYBREAKER | 34 | say | 80 | Dalaran | — | Onward and upward, friend! There's glory enough for all. |
| 1311 | SKYBREAKER | 34 | say | 70 | Dalaran | — | Mind your bearing near the ship, {race}. Standards to uphold. |
| 1320 | SKYBREAKER | 35 | say | 90 | Dalaran | Horde players | A Horde {race}. How... quaint. Do enjoy your visit. |
| 1321 | SKYBREAKER | 35 | say | 80 | Dalaran | Horde players | One does try to be civil, even to your sort. You're welcome. |
| 1322 | SKYBREAKER | 35 | say | 80 | Dalaran | Horde players | Charming attire, for the Horde. Bless your effort, truly. |
| 1323 | SKYBREAKER | 35 | say | 80 | Dalaran | Horde players | We share the city, {race}. We do not share breeding. Good day. |
| 1324 | SKYBREAKER | 35 | say | 70 | Dalaran | Horde players | How gracious of you not to cause a scene. We noticed. |
| 1325 | SKYBREAKER | 35 | say | 80 | Dalaran | Horde players | A Horde {class}, unescorted? How terribly bold of you. |
| 1326 | SKYBREAKER | 35 | say | 70 | Dalaran | Horde players | Mind the polish on the hull, would you? Some of us keep standards. |
| 1327 | SKYBREAKER | 35 | say | 70 | Dalaran | Horde players | You carry yourself well — for one of the savage banners, I mean. |
| 1328 | SKYBREAKER | 35 | say | 70 | Dalaran | Horde players | Neutral ground spares you today. Send my regards to your Warchief. |
| 1329 | SKYBREAKER | 35 | say | 70 | Dalaran | Horde players | I shall be the very picture of courtesy. It costs me dearly, {race}. |
| 1330 | SKYBREAKER | 35 | say | 70 | Dalaran | Horde players | Run along now. The adults are discussing matters of the Alliance. |
| 1331 | SKYBREAKER | 35 | say | 70 | Dalaran | Horde players | A nod, then, {race}. Noblesse oblige, as the finer folk say. |

### 9. Other  (74 lines)

| id | role | grp | mode | wt | scope | targets | text |
|----|------|-----|------|----|-------|---------|------|
| 0 | any | 0 | say | 0 | ALL capitals | — | `text` |
| 421 | OFFICIAL | 19 | say | 100 | ALL capitals | — | The Argent Crusade stands against the Scourge. Will you stand with us, {race}? |
| 422 | OFFICIAL | 19 | say | 90 | ALL capitals | — | We seek champions for the front. A {class} would be most welcome. |
| 423 | OFFICIAL | 19 | say | 90 | ALL capitals | — | Wear your colors with pride, {race}. The war is far from won. |
| 424 | OFFICIAL | 19 | say | 90 | ALL capitals | — | Every hero counts. Even one such as you might turn the tide. |
| 425 | OFFICIAL | 19 | say | 80 | ALL capitals | — | There is coin and honor both for those who fight for the cause. |
| 426 | OFFICIAL | 19 | say | 80 | ALL capitals | — | Rare to see a {class} unsworn to any banner. Consider ours. |
| 427 | OFFICIAL | 19 | say | 90 | ALL capitals | — | Speak with me if you'd earn the favor of my order, {race}. |
| 428 | OFFICIAL | 19 | say | 80 | ALL capitals | — | Tabards and titles mean nothing without the deeds to earn them. |
| 429 | OFFICIAL | 19 | say | 80 | ALL capitals | — | The dead do not tire, {race}. Neither, then, must we. |
| 430 | OFFICIAL | 19 | say | 80 | ALL capitals | — | You have the bearing of a champion. My order could use you. |
| 431 | OFFICIAL | 19 | say | 70 | ALL capitals | — | Old enemies make common cause against a common foe these days. |
| 432 | OFFICIAL | 19 | say | 80 | ALL capitals | — | Glory awaits the bold on the borderlands, {race}. Seek it. |
| 433 | OFFICIAL | 19 | say | 70 | ALL capitals | — | We remember our fallen. See that you honor them, {class}. |
| 434 | OFFICIAL | 19 | say | 70 | ALL capitals | — | The banner I carry has seen a hundred fields. It seeks a hundred more. |
| 501 | any | 20 | say | 80 | ALL capitals | race:Human | You humans do get everywhere. Ambitious lot, and no mistake. |
| 502 | any | 20 | say | 70 | ALL capitals | race:Human | A son or daughter of Stormwind, I'd wager. Long roads ahead of you. |
| 503 | any | 20 | say | 80 | ALL capitals | race:Orc | An orc, walking tall and proud. Strength and honor to you. |
| 504 | any | 20 | say | 70 | ALL capitals | race:Orc | May your axe stay sharp, orc, and your enemies few. |
| 505 | any | 20 | say | 80 | ALL capitals | race:Dwarf | A dwarf! Mind you don't drink us dry, friend. |
| 506 | any | 20 | say | 70 | ALL capitals | race:Dwarf | Stout as the mountain, you dwarves — and twice as hard-headed. |
| 507 | any | 20 | say | 80 | ALL capitals | race:NightElf | A child of the stars. You night elves make an old soul feel young. |
| 508 | any | 20 | say | 70 | ALL capitals | race:NightElf | Elune's grace upon you, kaldorei. You walk far from your groves. |
| 509 | any | 20 | say | 80 | ALL capitals | race:Undead | A Forsaken... forgive my flinch. Old fears die hard, friend. |
| 510 | any | 20 | say | 70 | ALL capitals | race:Undead | You wear death lightly, Forsaken. I'll not pretend it's easy to see. |
| 511 | any | 20 | say | 80 | ALL capitals | race:Tauren | An Earthmother's child. You tauren carry such a gentle strength. |
| 512 | any | 20 | say | 70 | ALL capitals | race:Tauren | So tall, so calm. The tauren shame the rest of us for temper. |
| 513 | any | 20 | say | 80 | ALL capitals | race:Gnome | A gnome! Mind the cobbles — I'd hate to tread on a genius. |
| 514 | any | 20 | say | 70 | ALL capitals | race:Gnome | Tinkering again, no doubt. You gnomes never sit still, do you? |
| 515 | any | 20 | say | 80 | ALL capitals | race:Troll | A troll, and mannered too. The old stories don't do you justice. |
| 516 | any | 20 | say | 70 | ALL capitals | race:Troll | Them tusks give me a start, but you carry yourself well, troll. |
| 517 | any | 20 | say | 80 | ALL capitals | race:BloodElf | A sin'dorei. You blood elves wear your pride like fine silk. |
| 518 | any | 20 | say | 70 | ALL capitals | race:BloodElf | The Sunwell's children walk among us. Strange days indeed. |
| 519 | any | 20 | say | 80 | ALL capitals | race:Draenei | A draenei — so tall! The Light shines strange and bright in you. |
| 520 | any | 20 | say | 70 | ALL capitals | race:Draenei | From beyond the stars, they say. You draenei have seen much grief. |
| 541 | any | 21 | say | 80 | ALL capitals | class:Warrior | A warrior's hands, scarred and steady. You've earned those. |
| 542 | any | 21 | say | 70 | ALL capitals | class:Warrior | No tricks for you, eh warrior? Just steel and will. I respect it. |
| 543 | any | 21 | say | 80 | ALL capitals | class:Paladin | The Light walks with you, paladin. We sleep safer for your kind. |
| 544 | any | 21 | say | 70 | ALL capitals | class:Paladin | Armor and faith both, paladin. A fine pairing in dark times. |
| 545 | any | 21 | say | 80 | ALL capitals | class:Hunter | Where's your beast, hunter? Left it outside, I do hope. |
| 546 | any | 21 | say | 70 | ALL capitals | class:Hunter | A steady eye and a loyal companion. You hunters want for little. |
| 547 | any | 21 | say | 80 | ALL capitals | class:Rogue | Didn't hear you approach, {class}. ...I never do, do I? |
| 548 | any | 21 | say | 70 | ALL capitals | class:Rogue | Keep those clever fingers to yourself, rogue. All in good humor. |
| 549 | any | 21 | say | 80 | ALL capitals | class:Priest | Bless you, priest. The wounded and weary are in your debt. |
| 550 | any | 21 | say | 70 | ALL capitals | class:Priest | Faith is a heavy burden to carry, priest. You wear it well. |
| 551 | any | 21 | say | 80 | ALL capitals | class:DeathKnight | A death knight. The grave gave you back — use the gift well. |
| 552 | any | 21 | say | 70 | ALL capitals | class:DeathKnight | Cold comes off you like winter, death knight. But you fight for the living now. |
| 553 | any | 21 | say | 80 | ALL capitals | class:Shaman | The elements whisper around you, shaman. I feel the air change. |
| 554 | any | 21 | say | 70 | ALL capitals | class:Shaman | Earth, wind, fire and water — all your kin, shaman. What a thing. |
| 555 | any | 21 | say | 80 | ALL capitals | class:Mage | Mind the sparks, mage. My thatch roof thanks you in advance. |
| 556 | any | 21 | say | 70 | ALL capitals | class:Mage | A mage's work is never dull, nor safe. Do be careful in the streets. |
| 557 | any | 21 | say | 80 | ALL capitals | class:Warlock | Keep your... friends leashed, warlock. Folk here are the nervous sort. |
| 558 | any | 21 | say | 70 | ALL capitals | class:Warlock | Dark power, darker bargains. I'll not ask the price, warlock. |
| 559 | any | 21 | say | 80 | ALL capitals | class:Druid | The wilds sent you, druid? You smell of pine and open sky. |
| 560 | any | 21 | say | 70 | ALL capitals | class:Druid | Claw, feather or leaf today, druid? You shapechangers keep us guessing. |
| 581 | any | 22 | say | 80 | ALL capitals | gear:256 | A swordsman's stance. Honest steel — nothing wrong with that. |
| 582 | any | 22 | say | 80 | ALL capitals | gear:512 | That axe has split more than firewood, I'd wager. Heavy work. |
| 583 | any | 22 | say | 80 | ALL capitals | gear:1024 | A good mace ends an argument quick. Blunt, like my old mother. |
| 584 | any | 22 | say | 70 | ALL capitals | gear:2048 | Reach and weight both, that polearm. Keep it clear of the awnings. |
| 585 | any | 22 | say | 80 | ALL capitals | gear:4096 | Small blade, quick hands. I'll keep my coin purse close, {race}. |
| 586 | any | 22 | say | 70 | ALL capitals | gear:8192 | A scholar's staff — or a cracked skull waiting to happen. Both, maybe. |
| 587 | any | 22 | say | 70 | ALL capitals | gear:16384 | Bare hands and a bit of steel? Bold way to fight, {class}. |
| 588 | any | 22 | say | 80 | ALL capitals | gear:32768 | A fine bow. Steady in the draw, I'd guess. Don't aim it near me! |
| 589 | any | 22 | say | 70 | ALL capitals | gear:65536 | A firearm! Loud, smelly things — effective, mind, but loud. |
| 590 | any | 22 | say | 70 | ALL capitals | gear:2H | That two-hander's taller than my youngest. Mind the doorframes. |
| 591 | any | 22 | say | 80 | ALL capitals | gear:shield | Shield on your arm — a defender's heart. We need more like you. |
| 601 | any | 23 | say | 80 | ALL capitals | gear:plate | Head to toe in plate! You must sound like a cart on the cobbles. |
| 602 | any | 23 | say | 70 | ALL capitals | gear:plate | Fine steel plate, {race}. The smiths did right by you. |
| 603 | any | 23 | say | 80 | ALL capitals | gear:mail | Mail and mettle. Practical — moves with you, keeps the edge off. |
| 604 | any | 23 | say | 70 | ALL capitals | gear:mail | Chainmail suits you, {race}. Not too heavy, not too light. |
| 605 | any | 23 | say | 80 | ALL capitals | gear:leather | Supple leather, quiet steps. A practical sort, aren't you? |
| 606 | any | 23 | say | 70 | ALL capitals | gear:leather | Leathers well worn, {race}. The road's left its mark on them. |
| 607 | any | 23 | say | 80 | ALL capitals | gear:cloth | Robes and cloth — a caster's garb. Mind the mud; it never comes out. |
| 608 | any | 23 | say | 70 | ALL capitals | gear:cloth | Fine cloth, that. Enchanted, is it? I daren't ask what it cost. |
