-- ============================================================================
-- lua-immersive-npc-chat — add immersive_npc_chat_line.min_player_level to an
-- EXISTING database. Fresh installs already get it from inc_base.sql's CREATE TABLE;
-- this migration is for servers whose line table predates the column (CREATE TABLE
-- IF NOT EXISTS never alters an existing table).
--
-- Idempotent AND MySQL-8-safe: MySQL 8 has no `ADD COLUMN IF NOT EXISTS`, so we
-- check information_schema and only ALTER when the column is absent. Re-running is
-- a no-op.
--
-- MUST run BEFORE 2026_07_12_02_dalaran_factions.sql (its Violet Hold rows INSERT
-- into this column). The filename sorts ahead of the 01/02/03 content files.
-- ============================================================================

SET @col_exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'immersive_npc_chat_line'
    AND COLUMN_NAME = 'min_player_level');

SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `immersive_npc_chat_line` ADD COLUMN `min_player_level` TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `min_item_quality`',
  'DO 0');

PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
