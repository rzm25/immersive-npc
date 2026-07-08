-- 04_inc_registry.lua — per-entry creature registry.
--
-- We RegisterCreatureEvent(entry, ON_ADD/ON_REMOVE) for EACH profiled entry only
-- (spec §4). Because registration is per-entry, the C++->Lua bridge fires during a
-- capital's grid load ONLY for our handful of profiled entries — not for every
-- creature in the city. That is the whole point of the per-entry design.
--
-- Events verified against S1 pin (Hooks.h @ e36707d):
--   CREATURE_EVENT_ON_ADD    = 36
--   CREATURE_EVENT_ON_REMOVE = 37
--
-- A registry entry stores identity + a CACHED spawn position (cheap candidate
-- pre-filter only) + phase. Mutable profile attributes (role mask, speak distance,
-- personal flag) are re-resolved from INC.Caches at emission, so a `.inm reload`
-- that edits a profile updates already-registered NPCs with no respawn. The LIVE
-- creature position is used for the final distance check (spec §4.4), so patrolling
-- guards are still validated correctly.

INC = INC or {}
INC.Registry = INC.Registry or {}

local CREATURE_EVENT_ON_ADD = 36
local CREATURE_EVENT_ON_REMOVE = 37

local function onAdd(_, creature)
  local caches = INC.Caches
  if not caches then return end
  local entry = creature:GetEntry()
  local guidLow = creature:GetGUIDLow()
  local locId = INC.Data.ResolveLocation(caches, creature:GetMapId(), creature:GetZoneId(), creature:GetAreaId())
  if not locId then return end
  local prof = INC.Data.FindProfile(caches, entry, locId, guidLow)
  if not prof then return end

  local st = INC.State
  local locTable = st.Registry[locId]
  if not locTable then locTable = {}; st.Registry[locId] = locTable end
  if not locTable[guidLow] then st.RegistryCount = st.RegistryCount + 1 end
  locTable[guidLow] = {
    entry = entry,
    guid = creature:GetGUID(),          -- full ObjectGuid (value type; safe to persist)
    guidLow = guidLow,
    x = creature:GetX(), y = creature:GetY(), z = creature:GetZ(),
    mapId = creature:GetMapId(),
    locationId = locId,
    cooldownUntil = 0,                  -- memory-only NPC cooldown
  }
  st.RegistryIndex[guidLow] = locId
end

local function onRemove(_, creature)
  local st = INC.State
  local guidLow = creature:GetGUIDLow()
  local locId = st.RegistryIndex[guidLow]
  if not locId then return end
  local locTable = st.Registry[locId]
  if locTable and locTable[guidLow] then
    locTable[guidLow] = nil
    st.RegistryCount = st.RegistryCount - 1
  end
  st.RegistryIndex[guidLow] = nil
end

-- Called once at boot after caches are loaded. Sets up registry state and wires the
-- per-entry hooks. NOT called by `.inm reload` (Eluna can't cleanly unregister a
-- single creature event; adding a brand-new profiled ENTRY needs a full script
-- reload — documented as a known limitation in README).
function INC.Registry.Init()
  local st = INC.State
  st.Registry = {}
  st.RegistryIndex = {}
  st.RegistryCount = 0

  local addH = INC.Protect("registry.onAdd", onAdd)
  local remH = INC.Protect("registry.onRemove", onRemove)
  local n = 0
  for entry in pairs(INC.Caches.ProfiledEntries) do
    RegisterCreatureEvent(entry, CREATURE_EVENT_ON_ADD, addH)
    RegisterCreatureEvent(entry, CREATURE_EVENT_ON_REMOVE, remH)
    n = n + 1
  end
  return n
end

-- Iterate registry entries for a location (may be empty/nil). Returns the table or
-- an empty table; callers must not mutate it during iteration.
function INC.Registry.ForLocation(locId)
  return INC.State.Registry[locId] or {}
end
