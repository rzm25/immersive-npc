# immersive-npc — live bugtesting / feedback log

Running log of owner feedback from live testing on `peri0`, with root cause and status.
Newest session at the bottom. Cross-ref: root-cause fixes also land in the code + the
session notes; content asks track their SQL file.

Status key: ✅ done · 🔧 in progress · 📋 queued · ❓ needs owner input

---

## 2026-07-12 — feedback batch after Dalaran/Darkshire import

### Diagnosis items
1. **✅ Emissaries in Stormwind now emit on `.inm force self`.** (confirmed working)
2. **✅ Extra expansion lines live.** (225 lines confirmed)
3. **🔧 "Dialogue only ~once per 10 min, even after I lowered group cooldown to 60000."**
   ROOT CAUSE: emission RATE is **not** set by any cooldown. It's gated by, in order:
   `SchedulerTickMs` (attempt cadence), `GlobalMinIntervalMs` (server-wide floor, default
   45s), the **global token bucket** (`GlobalBurstMax`/`GlobalBurstWindowMs` = 2 per 180s ≈
   1 line / 90s *for the whole server*), each location's `min_interval_ms` + `max_lines_per_10min`,
   and **`PopulationScaling`** (at pop≈1, BasePerMinute 0.25 ⇒ ~1 line / 4 min for that city,
   via a capacity-2 bucket that takes ~8 min to refill). The group/line/player COOLDOWNS only
   control *variety per listener*, never the rate — which is why lowering them did nothing.
   On a bot-populated server the **shared global bucket** is the real throttle: other cities
   drain it, starving a quiet city → the ~10 min you saw. FIX = config (see below), not cooldowns.
4. **✅ "Why does `force self` fire when natural won't? What does it bypass?"**
   ANSWER: `forced=true` bypasses **only the PACING gates** — `GlobalMinIntervalMs`, the global
   bucket, and the whole per-location pacing block (`min_interval_ms`, `max_lines_per_10min`,
   population bucket). It still honors per-player/npc/line/group cooldowns + full final
   validation. So "force works, natural doesn't" is *proof* the throttle is pacing, exactly the
   knobs in item 3. (`06_inc_scheduler.lua` `attemptBody`, `forced` branch.)

### Eligibility items (NPCs silent because their ENTRY isn't profiled)
Root cause for ALL of these: the mod speaks only near creatures whose **entry** has a profile
row for that location. `.inm force self` → `NO_NEARBY_NPC` means no *registered* profiled NPC in
range. Fix = add profile rows. Delivered in `sql/world/updates/2026_07_12_00_eligibility.sql`
(profiles by the exact GUIDs you gave, deriving entry via `creature.id1`; idempotent via a
`inm-auto:*` comment marker).
5. **🔧 Darkshire named NPCs silent** (Town Crier 4185, Watcher Keefer 5965, Cmdr Althea
   Ebonlocke 4194, Watcher Ladimore 4211): profiled CITIZEN(128) → loc 8 → draw the existing
   Darkshire pool immediately. Darkshire pool being expanded toward 50 (item 5b).
6. **🔧 Dalaran named NPCs** (Darthalia Ebonscorch 111691, Archmage Tenaj 112609, Babagahnoosh
   111283, Magus Fansy Goodbringer 112852, Grezla 112052, Crafticus Mindbender 112385, Windle
   Sparkshine 102700, Merleaux 111858, Kitz Proudbreeze 112329, Sabriana Sorrowgaze 112965,
   Emeline Fizzlefry 111461, Torgo the Younger 108843, Lidia Ann Kastinglow 112522, Arcanist
   Alec 112928, Whirt 111374, Mona Everspring 112194, Sebastian Bower 1823): profiled CITIZEN(128)
   → loc 7 → draw the existing Dalaran pool.
7. **🔧 Vendors** (Aerith Primrose 102033 + all vendor-flag NPCs): new **VENDOR role = 4**
   (position 2, already reserved in `inc_base.sql`). Named vendor pinned; broad sweep profiles
   vendor-flag entries on our locations' maps (self-corrects at runtime via ResolveLocation).
   Dedicated vendor line pool started (target 200) in `2026_07_12_01_vendor_lines.sql`.
8. **🔧 Sunreaver Guardians** (102417/102427/… list): new **SUNREAVER role = 65536** (pos 16).
   Terse/aloof guard voice + opposing-faction lines. Target 50 + 20 opposing.
9. **🔧 Violet Hold Guards** (114315–114322): new **VIOLET_HOLD role = 131072** (pos 17).
   Requires the new **`min_player_level` line gate** (speak only to 75+) — schema+code added
   this session. Polite, gear-complimenting, "safe travels" outside Malygos/Tharon'ja. Target 50.
10. **🔧 Sky-Reavers** (Horde/orc: 105878/53919–53922): new **SKYREAVER role = 262144** (pos 18).
    Gruff/brash guard voice + backhanded opposing-faction lines (team_mask = Alliance). Target 20 + 40.
11. **🔧 Skybreakers** (Alliance/human: 105358/53923–53926): new **SKYBREAKER role = 524288**
    (pos 19). Grandiose/snooty + condescending opposing-faction lines (team_mask = Horde). Target 20 + 40.

### New role bit assignments (extend the `inc_base.sql` mirror)
GUARD=1 · CITIZEN=128 · OFFICIAL/EMISSARY=256 · CRIER=512 · **VENDOR=4** · **SUNREAVER=65536** ·
**VIOLET_HOLD=131072** · **SKYREAVER=262144** · **SKYBREAKER=524288** (all `role_mask_lo`).

### Live deploy findings (2026-07-13)
- **✅ SQL imported clean.** The import loop ran all 5 files without `break` → the
  `creature.id1`-based eligibility profiling applied, confirming **`id1` is the entry column**
  on this core (no swap needed). `min_player_level` column present.
- **⚠️ Vendor sweep = 4366 profile rows** (`inm-auto:vendor`), i.e. ~1000–1500 distinct hooked
  vendor entries. Steady-state cost ≈ 0 (ON_ADD only on grid load), but it made
  `SeedFromPlayers` (the `.reload ale` path) O(entries×players). **Fixed in code:** seed now does
  ONE `GetCreaturesInRange(0)` per player + a `ProfiledEntries` hash filter (commit 9c08249).
  Faction counts healthy: sunreaver 10, violethold 2, skyreaver 2, skybreaker 6, dalaran-named 17,
  darkshire-named 4, vendor-named 1 (entries; the 8 Violet Hold guard spawns share 2 templates).
- **⚠️ DB had 349 lines vs repo's 381** → an older content file (likely the 32 citizen lines)
  wasn't fully imported historically. Fix: re-import ALL `sql/world/updates/*.sql` (every file is
  idempotent: DELETE range + INSERT).
- **🐛 DEPLOY BREAK (my error):** the `cp … /lua_scripts/` command dropped loose `03/05/06` in the
  flat root while the full set lives in `lua_scripts/immersive-npc/`. ALE loads ScriptPath
  recursively → `already loaded, rename either file` + nil `INC.Util`/`INC.ItemTagPos` (siblings
  loaded out of order). Correct target is the **`immersive-npc/` subdir, whole set together**.
  Recorded in `/source` gotcha #15 and TRUTH_SOURCES.

### 2026-07-14 — emission model rewrite (per-player)
- **Item 3 RESOLVED (properly).** The "1 line / several minutes with 250 bots" was architectural,
  not a knob: v1 emitted **one line per tick server-wide** behind a shared ~1/90s global bucket, so
  individuals starved at scale. Rewrote to a **per-player** model (ADR-011): the tick emits for
  every DUE player each heartbeat (up to `MaxEmitsPerTick`), each on an escalating personal cadence
  (`PlayerCadenceMs` = arrival → 30s → 2.5m → 5m → 10m), **reset on hub arrival** so walking into
  town greets you within seconds. Removed the global/location buckets + `PopulationScaling` +
  `PopulationPerMinute`; anti-repeat is now per-NPC (`NpcCooldownMs` lowered to 90s) + per-player
  line/group cooldowns. `.inm status` now shows tick/budget/cadence + per-location players & due
  count. `.inm force` bypasses only the player's cadence (still honors NPC cooldown). Config keys
  changed — the owner's skip-worktree'd `01_inc_config.lua` is defaulted by `ClampConfig` for the
  new keys, so it keeps working; re-tune `PlayerCadenceMs`/`MaxEmitsPerTick` there. Tests: unit 64,
  integration 67 (added multi-emit/escalation/arrival/budget).

### Content counts are STAGED
Each new pool is seeded functional this session (so the NPCs speak), then filled to the requested
target counts next. Owner can tune tone via `docs/CONTENT_LINES.md` before the pools are ballooned.
