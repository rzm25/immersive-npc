-- 03_inc_data.lua — DB loaders -> immutable in-memory caches.
--
-- HARD RULE (spec §5): the ONLY WorldDBQuery calls in this whole module live here,
-- and they run ONLY at boot and on `.inm reload`. Zero DB access at emission time.
--
-- Load() builds a brand-new `caches` table and returns it; the caller swaps it in
-- with a single assignment (INC.Caches = new) so a reload is atomic — the old cache
-- stays fully live until the new one is completely built (spec §7 reload).
--
-- Query result API verified against S1 pin (ElunaQueryMethods.h @ e36707d):
--   q = WorldDBQuery(sql)  -> result or nil (nil = zero rows)
--   q:GetUInt32(i) / GetUInt8(i) / GetFloat(i) / GetString(i)   (columns 0-indexed)
--   q:NextRow() -> bool (advance; iterate with repeat ... until not q:NextRow())

INC = INC or {}
INC.Data = INC.Data or {}
local U = INC.Util
local band, lshift = bit32.band, bit32.lshift

-- Iterate a WorldDBQuery result, calling fn(q) once per row. Handles the nil (no
-- rows) case. Kept tiny so the three loaders read cleanly.
local function eachRow(q, fn)
  if not q then return end
  repeat
    fn(q)
  until not q:NextRow()
end

-- ---------------------------------------------------------------------------

local function loadLocations(caches, stats)
  local q = WorldDBQuery(
    "SELECT id, name, map_id, zone_id, area_id, enabled, min_interval_ms, max_lines_per_10min " ..
    "FROM immersive_npc_chat_location")
  eachRow(q, function(row)
    local id = row:GetUInt32(0)
    if id >= 32 then
      INC.Warn(("location id %d skipped: must be < 32 (fits one uint32 location_mask bit)"):format(id))
      stats.skipped = stats.skipped + 1
      return
    end
    if caches.Locations[id] then
      INC.Warn(("location id %d skipped: duplicate id"):format(id))
      stats.skipped = stats.skipped + 1
      return
    end
    local loc = {
      id = id,
      name = row:GetString(1),
      mapId = row:GetUInt32(2),
      zoneId = row:GetUInt32(3),
      areaId = row:GetUInt32(4),
      enabled = row:GetUInt8(5) ~= 0,
      minIntervalMs = row:GetUInt32(6),
      maxLinesPer10Min = row:GetUInt32(7),
    }
    caches.Locations[id] = loc
    if loc.enabled then
      caches.LocationList[#caches.LocationList + 1] = loc
      caches.LinesByLocation[id] = {}
    end
  end)
end

local function loadProfiles(caches, stats)
  local q = WorldDBQuery(
    "SELECT id, creature_entry, creature_guid, location_id, role_mask_lo, role_mask_hi, " ..
    "max_speak_distance, allow_personal_lines, enabled FROM immersive_npc_chat_npc_profile")
  -- Aggregate "unknown location_id" skips so one missing location prints ONE summary
  -- line at the end, not one warning per profile row (a bulk profiling pass can
  -- otherwise flood the log with dozens of identical warnings).
  local unknownLoc = {}
  eachRow(q, function(row)
    local rowId = row:GetUInt32(0)
    if row:GetUInt8(8) == 0 then return end  -- disabled profile: silently ignore
    local entry = row:GetUInt32(1)
    local locId = row:GetUInt32(3)
    local loc = caches.Locations[locId]
    if not loc then
      local u = unknownLoc[locId]
      if not u then u = { count = 0, firstId = rowId }; unknownLoc[locId] = u end
      u.count = u.count + 1
      stats.skipped = stats.skipped + 1
      return
    end
    if not loc.enabled then return end  -- location disabled: profile is inert, skip quietly
    local prof = {
      rowId = rowId,
      entry = entry,
      guidFilter = row:GetUInt32(2),          -- 0 = all spawns of entry
      locationId = locId,
      roleMaskLo = row:GetUInt32(4),
      roleMaskHi = row:GetUInt32(5),
      maxSpeakDistance = row:GetFloat(6),
      allowPersonal = row:GetUInt8(7) ~= 0,
    }
    local list = caches.NpcProfilesByEntry[entry]
    if not list then list = {}; caches.NpcProfilesByEntry[entry] = list end
    list[#list + 1] = prof
    caches.ProfiledEntries[entry] = true
  end)
  for locId, u in pairs(unknownLoc) do
    INC.Warn(("%d npc_profile row(s) skipped: unknown location_id %d (e.g. profile id %d) — add that row to immersive_npc_chat_location")
      :format(u.count, locId, u.firstId))
  end
end

-- OR together the role masks of every enabled, personal-capable profile, so a
-- whisper line that no such NPC can carry is flagged (spec §5).
local function personalCapableRoles(caches)
  local lo, hi = 0, 0
  for _, list in pairs(caches.NpcProfilesByEntry) do
    for _, prof in ipairs(list) do
      if prof.allowPersonal then
        lo = bit32.bor(lo, prof.roleMaskLo)
        hi = bit32.bor(hi, prof.roleMaskHi)
      end
    end
  end
  return lo, hi
end

local function loadLines(caches, stats)
  local pcLo, pcHi = personalCapableRoles(caches)
  local q = WorldDBQuery(
    "SELECT id, location_mask, npc_role_mask_lo, npc_role_mask_hi, class_mask, race_mask, team_mask, " ..
    "required_item_tags_lo, required_item_tags_hi, min_item_quality, cooldown_group, weight, chat_mode, " ..
    "locale, text, enabled, min_player_level FROM immersive_npc_chat_line")
  eachRow(q, function(row)
    local id = row:GetUInt32(0)
    if row:GetUInt8(15) == 0 then return end                 -- disabled line
    if row:GetString(13) ~= "enUS" then return end           -- v1 is enUS-only (spec §4.8)
    local text = row:GetString(14)
    if not text or text == "" then
      INC.Warn(("line id %d skipped: empty text"):format(id))
      stats.skipped = stats.skipped + 1
      return
    end
    local chatMode = row:GetUInt8(12)
    local roleLo, roleHi = row:GetUInt32(2), row:GetUInt32(3)
    if chatMode == INC.ChatMode.WHISPER and not U.MatchAny64(pcLo, pcHi, roleLo, roleHi) then
      INC.Warn(("line id %d skipped: whisper line matches no personal-capable NPC role"):format(id))
      stats.skipped = stats.skipped + 1
      return
    end
    local line = {
      id = id,
      locationMask = row:GetUInt32(1),
      roleMaskLo = roleLo, roleMaskHi = roleHi,
      classMask = row:GetUInt32(4),
      raceMask = row:GetUInt32(5),
      teamMask = row:GetUInt32(6),
      itemTagLo = row:GetUInt32(7), itemTagHi = row:GetUInt32(8),
      minQuality = row:GetUInt8(9),
      cooldownGroup = row:GetUInt32(10),
      weight = row:GetUInt32(11),
      chatMode = chatMode,
      text = text,
      minLevel = row:GetUInt8(16),   -- 0 = no gate; else listener must be >= this
    }
    caches.Lines[#caches.Lines + 1] = line
    -- Prebuild per-location index so the hot path never scans the full line table.
    for _, loc in ipairs(caches.LocationList) do
      if line.locationMask == 0 or band(line.locationMask, lshift(1, loc.id)) ~= 0 then
        local bucket = caches.LinesByLocation[loc.id]
        bucket[#bucket + 1] = line
      end
    end
  end)
end

-- Build a fresh caches table from the DB. Never raises on bad content — bad rows are
-- warned + skipped. Returns the caches table (for atomic swap by the caller).
function INC.Data.Load()
  local caches = {
    Locations = {},          -- [id] = loc
    LocationList = {},        -- array of ENABLED locs
    NpcProfilesByEntry = {},  -- [entry] = { prof, ... }
    ProfiledEntries = {},     -- set of entries to RegisterCreatureEvent for
    Lines = {},               -- all live lines
    LinesByLocation = {},     -- [locId] = { line, ... } (enabled locs only)
    Stats = { locations = 0, profiles = 0, lines = 0, skipped = 0 },
  }
  local stats = caches.Stats
  loadLocations(caches, stats)
  loadProfiles(caches, stats)
  loadLines(caches, stats)

  -- Final counts for the summary.
  for _ in pairs(caches.Locations) do stats.locations = stats.locations + 1 end
  local profCount, entryCount = 0, 0
  for _, list in pairs(caches.NpcProfilesByEntry) do
    entryCount = entryCount + 1
    profCount = profCount + #list
  end
  stats.profiles = profCount
  stats.profiledEntries = entryCount
  stats.lines = #caches.Lines
  return caches
end

-- Find the profile that applies to a spawned creature: same entry, same resolved
-- location, and either a wildcard guid filter (0) or an exact guid match. Resolved
-- from caches at ON_ADD and again at emission, so a `.inm reload` that changes a
-- profile's attributes takes effect for already-registered NPCs without a respawn.
-- Returns the profile or nil.
function INC.Data.FindProfile(caches, entry, locationId, guidLow)
  local list = caches.NpcProfilesByEntry[entry]
  if not list then return nil end
  local wildcard
  for _, prof in ipairs(list) do
    if prof.locationId == locationId then
      if prof.guidFilter == guidLow then
        return prof                 -- exact guid pin wins
      elseif prof.guidFilter == 0 then
        wildcard = wildcard or prof
      end
    end
  end
  return wildcard
end

-- Resolve which location (if any) a position belongs to. area_id 0 on a location =
-- whole zone. Exact area matches win over whole-zone so a district can override its
-- parent zone in v2. Returns locationId or nil.
function INC.Data.ResolveLocation(caches, mapId, zoneId, areaId)
  local zoneMatch
  for _, loc in ipairs(caches.LocationList) do
    if loc.mapId == mapId and loc.zoneId == zoneId then
      if loc.areaId ~= 0 and loc.areaId == areaId then
        return loc.id  -- exact area match: strongest
      elseif loc.areaId == 0 then
        zoneMatch = loc.id
      end
    end
  end
  return zoneMatch
end
