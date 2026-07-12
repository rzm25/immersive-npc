-- ============================================================================
-- lua-immersive-npc-chat — base schema (world DB)
--
-- Three custom tables. Safe to re-run: CREATE ... IF NOT EXISTS never drops operator
-- data. Content seeds live in sql/world/updates/ and are individually idempotent.
--
-- 64-bit masks are split into `_lo` (bits 0..31) and `_hi` (bits 32..51) uint32
-- columns because the ALE/Eluna runtime is Lua 5.2, whose bit32 library is 32-bit
-- only (see scripts/inc/02_inc_util.lua). Never set a bit above position 51.
--
-- ----------------------------------------------------------------------------
-- BIT CONSTANT MIRROR — the single source of truth is scripts/inc/02_inc_util.lua.
-- Keep this block in sync with it. Values below are decimal bit VALUES (1<<pos)
-- unless noted as a POSITION.
--
-- chat_mode:            0 = say, 1 = whisper, 2 = emote
-- team_mask (ANY-of):   ALLIANCE=1, HORDE=2                    (0 = no restriction)
-- class_mask (ANY-of, 1<<(classId-1)):
--   WARRIOR=1 PALADIN=2 HUNTER=4 ROGUE=8 PRIEST=16 DEATHKNIGHT=32
--   SHAMAN=64 MAGE=128 WARLOCK=256 DRUID=1024
-- race_mask (ANY-of, 1<<(raceId-1)):
--   HUMAN=1 ORC=2 DWARF=4 NIGHTELF=8 UNDEAD=16 TAUREN=32
--   GNOME=64 TROLL=128 BLOODELF=512 DRAENEI=1024
-- location_mask (ANY-of over location ids, 1<<locationId): 0 = all locations.
--   SW=2 IF=4 DARN=8 ORG=16 TB=32 UC=64   (location ids 1..6 below)
-- npc_role_mask (ANY-of, split-64, POSITIONS): GUARD=0 INNKEEPER=1 VENDOR=2
--   TRAINER=3 BANKER=4 AUCTIONEER=5 FLIGHTMASTER=6 CITIZEN=7 OFFICIAL=8 CRIER=9
--   BARTENDER=10 COOK=11 BLACKSMITH=12 GUILD_MASTER=13 STABLE_MASTER=14 WATCH=15
--   SUNREAVER=16 VIOLET_HOLD=17 SKYREAVER=18 SKYBREAKER=19   (Dalaran faction voices)
--   -> role_mask_lo bit VALUE = 1<<pos (GUARD => 1, VENDOR => 4, CITIZEN => 128,
--      OFFICIAL => 256, CRIER => 512, SUNREAVER => 65536, VIOLET_HOLD => 131072,
--      SKYREAVER => 262144, SKYBREAKER => 524288)
-- required_item_tags (ALL-of, split-64, POSITIONS -> lo bit VALUE = 1<<pos):
--   HAS_WEAPON=0(1) HAS_TWO_HAND=1(2) HAS_SHIELD=2(4) HAS_RANGED=3(8)
--   PLATE=4(16) MAIL=5(32) LEATHER=6(64) CLOTH=7(128) SWORD=8(256) AXE=9(512)
--   MACE=10(1024) POLEARM=11(2048) DAGGER=12(4096) STAFF=13(8192) FIST=14(16384)
--   BOW=15(32768) GUN=16(65536) CROSSBOW=17(131072) WAND=18(262144)
--   TABARD=19(524288) OFFHAND_FRILL=20(1048576)
-- min_item_quality: 0 poor .. 2 uncommon .. 3 rare .. 4 epic .. 5 legendary .. 7 heirloom
-- min_player_level: 0 = no gate; otherwise the listener's level must be >= this
--                   (used for the Violet Hold "speak only to 75+" pool)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `immersive_npc_chat_location` (
  `id` INT UNSIGNED NOT NULL PRIMARY KEY,          -- must be < 32 (fits one uint32 location_mask bit); loader enforces
  `name` VARCHAR(100) NOT NULL,
  `map_id` SMALLINT UNSIGNED NOT NULL,
  `zone_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `area_id` INT UNSIGNED NOT NULL DEFAULT 0,        -- 0 = whole zone
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `min_interval_ms` INT UNSIGNED NOT NULL DEFAULT 120000,
  `max_lines_per_10min` INT UNSIGNED NOT NULL DEFAULT 6,
  `comment` TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `immersive_npc_chat_npc_profile` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `creature_entry` INT UNSIGNED NOT NULL,
  `creature_guid` INT UNSIGNED NOT NULL DEFAULT 0, -- 0 = all spawns of entry
  `location_id` INT UNSIGNED NOT NULL,
  `role_mask_lo` INT UNSIGNED NOT NULL DEFAULT 0,
  `role_mask_hi` INT UNSIGNED NOT NULL DEFAULT 0,
  `max_speak_distance` FLOAT NOT NULL DEFAULT 22,
  `allow_personal_lines` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `comment` TEXT NULL,
  INDEX `idx_entry_location` (`creature_entry`,`location_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `immersive_npc_chat_line` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `location_mask` INT UNSIGNED NOT NULL DEFAULT 0,
  `npc_role_mask_lo` INT UNSIGNED NOT NULL DEFAULT 0,
  `npc_role_mask_hi` INT UNSIGNED NOT NULL DEFAULT 0,
  `class_mask` INT UNSIGNED NOT NULL DEFAULT 0,
  `race_mask` INT UNSIGNED NOT NULL DEFAULT 0,
  `team_mask` INT UNSIGNED NOT NULL DEFAULT 0,
  `required_item_tags_lo` INT UNSIGNED NOT NULL DEFAULT 0,
  `required_item_tags_hi` INT UNSIGNED NOT NULL DEFAULT 0,
  `min_item_quality` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `min_player_level` TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- 0 = no level gate; else listener must be >= this
  `cooldown_group` INT UNSIGNED NOT NULL DEFAULT 0,
  `weight` INT UNSIGNED NOT NULL DEFAULT 100,
  `chat_mode` TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- 0 say, 1 whisper, 2 emote
  `locale` VARCHAR(8) NOT NULL DEFAULT 'enUS',
  `text` TEXT NOT NULL,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `comment` TEXT NULL,
  INDEX `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
