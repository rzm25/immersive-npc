-- ============================================================================
-- lua-immersive-npc-chat — pre-import verification (SELECT-only; safe to run on the
-- live world DB before importing the seeds). Workspace gotcha #7.
--
-- 1) Which seeded guard entries actually exist on THIS server (adjust the seed's
--    creature_entry values for any that are missing/renamed).
-- 2) Any entries that are missing entirely.
-- The module has no custom creature/spell/quest IDs in v1 (it profiles STOCK
-- creatures), so there is no 95xxxx collision surface to check here; the reserved
-- block 9506xx (see /source/ID_RANGES.md) is held for future custom NPCs.
-- ============================================================================

-- 1) Present guard entries:
SELECT ct.entry, ct.name
FROM creature_template ct
WHERE ct.entry IN (68, 5595, 4262, 3296, 3084, 5624)
ORDER BY ct.entry;

-- 2) Missing guard entries (rows returned here = fix these in the profile seed):
SELECT want.entry AS missing_entry
FROM (
  SELECT 68 AS entry UNION ALL SELECT 5595 UNION ALL SELECT 4262
  UNION ALL SELECT 3296 UNION ALL SELECT 3084 UNION ALL SELECT 5624
) want
LEFT JOIN creature_template ct ON ct.entry = want.entry
WHERE ct.entry IS NULL;
