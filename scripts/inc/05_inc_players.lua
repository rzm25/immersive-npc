-- 05_inc_players.lua — player tracking + LAZY equipment scan.
--
-- Events verified against S1 pin (Hooks.h @ e36707d):
--   PLAYER_EVENT_ON_LOGIN       = 3
--   PLAYER_EVENT_ON_LOGOUT      = 4
--   PLAYER_EVENT_ON_UPDATE_ZONE = 27
--   PLAYER_EVENT_ON_UPDATE_AREA = 47
-- There is NO player unequip / visible-slot event (confirmed: PlayerEvents has
-- ON_EQUIP=29 but no unequip). Hence the equipment scan below is LAZY, never cached
-- (ADR-001). We deliberately do NOT register ON_EQUIP (29): a spam-swapping client
-- must cost the server nothing.

INC = INC or {}
INC.Players = INC.Players or {}
local U = INC.Util
local lshift = bit32.lshift

local PLAYER_EVENT_ON_LOGIN = 3
local PLAYER_EVENT_ON_LOGOUT = 4
local PLAYER_EVENT_ON_UPDATE_ZONE = 27
local PLAYER_EVENT_ON_UPDATE_AREA = 47

-- Equipment slots (AzerothCore EQUIPMENT_SLOT_*). END = 19, so slots are 0..18.
local EQUIPMENT_SLOT_END = 19
local SLOT_CHEST = 4
local SLOT_MAINHAND = 15
local SLOT_OFFHAND = 16
local SLOT_RANGED = 17
local SLOT_TABARD = 18

local ITEM_CLASS_WEAPON = 2
local ITEM_CLASS_ARMOR = 4
local INVTYPE_2HWEAPON = 17
local INVTYPE_HELD_IN_OFFHAND = 23

local TAG = INC.ItemTagPos

-- Weapon subclass (item class 2) -> item-tag bit position. nil = not a tag we track.
local WEAPON_SUBCLASS_TAG = {
  [0] = TAG.AXE, [1] = TAG.AXE,        -- 1H / 2H axe
  [2] = TAG.BOW, [3] = TAG.GUN,
  [4] = TAG.MACE, [5] = TAG.MACE,      -- 1H / 2H mace
  [6] = TAG.POLEARM,
  [7] = TAG.SWORD, [8] = TAG.SWORD,    -- 1H / 2H sword
  [10] = TAG.STAFF,
  [13] = TAG.FIST,
  [15] = TAG.DAGGER,
  [18] = TAG.CROSSBOW,
  [19] = TAG.WAND,
}
-- Weapon subclasses that are ranged (also set HAS_RANGED).
local WEAPON_SUBCLASS_RANGED = { [2] = true, [3] = true, [18] = true, [19] = true }
-- Armor subclass (item class 4) -> material tag position.
local ARMOR_SUBCLASS_MATERIAL = { [1] = TAG.CLOTH, [2] = TAG.LEATHER, [3] = TAG.MAIL, [4] = TAG.PLATE }
local ARMOR_SUBCLASS_SHIELD = 6

-- Weapon subclass -> friendly name for the {weapon_type} placeholder.
local WEAPON_SUBCLASS_NAME = {
  [0] = "axe", [1] = "axe", [2] = "bow", [3] = "gun", [4] = "mace", [5] = "mace",
  [6] = "polearm", [7] = "sword", [8] = "sword", [10] = "staff", [13] = "fist weapon",
  [15] = "dagger", [18] = "crossbow", [19] = "wand",
}

-- Walk ONE player's 19 equipment slots and derive item tags + max visible quality on
-- the spot (spec §4.5). Pure arithmetic + engine getters; allocates nothing (returns
-- three numbers). Called at most ~1–2×/min globally, so cost is irrelevant.
-- Returns: tagsLo, tagsHi, maxQuality, weaponTypeName (nil if unarmed).
function INC.Players.ScanEquipment(player)
  local lo, hi = 0, 0
  local maxQuality = 0
  local weaponType
  for slot = 0, EQUIPMENT_SLOT_END - 1 do
    local item = player:GetEquippedItemBySlot(slot)
    if item then
      local q = item:GetQuality()
      if q > maxQuality then maxQuality = q end
      local iclass = item:GetClass()

      if slot == SLOT_CHEST and iclass == ITEM_CLASS_ARMOR then
        local mat = ARMOR_SUBCLASS_MATERIAL[item:GetSubClass()]
        if mat then lo, hi = U.SetBit64(lo, hi, mat) end

      elseif slot == SLOT_MAINHAND or slot == SLOT_OFFHAND or slot == SLOT_RANGED then
        if iclass == ITEM_CLASS_WEAPON then
          lo, hi = U.SetBit64(lo, hi, TAG.HAS_WEAPON)
          local sub = item:GetSubClass()
          local wtag = WEAPON_SUBCLASS_TAG[sub]
          if wtag then lo, hi = U.SetBit64(lo, hi, wtag) end
          if slot == SLOT_MAINHAND then weaponType = WEAPON_SUBCLASS_NAME[sub] end
          if WEAPON_SUBCLASS_RANGED[sub] or slot == SLOT_RANGED then
            lo, hi = U.SetBit64(lo, hi, TAG.HAS_RANGED)
          end
          if item:GetInventoryType() == INVTYPE_2HWEAPON then
            lo, hi = U.SetBit64(lo, hi, TAG.HAS_TWO_HAND)
          end
        elseif iclass == ITEM_CLASS_ARMOR and slot == SLOT_OFFHAND
            and item:GetSubClass() == ARMOR_SUBCLASS_SHIELD then
          lo, hi = U.SetBit64(lo, hi, TAG.HAS_SHIELD)
        elseif slot == SLOT_OFFHAND and item:GetInventoryType() == INVTYPE_HELD_IN_OFFHAND then
          lo, hi = U.SetBit64(lo, hi, TAG.OFFHAND_FRILL)
        end

      elseif slot == SLOT_TABARD then
        lo, hi = U.SetBit64(lo, hi, TAG.TABARD)
      end
    end
  end
  return lo, hi, maxQuality, weaponType
end

-- ---------------------------------------------------------------------------
-- Tracking
-- ---------------------------------------------------------------------------

local function locState(locId)
  local ls = INC.State.LocationState[locId]
  if not ls then ls = { players = {}, count = 0 }; INC.State.LocationState[locId] = ls end
  return ls
end

-- Move a tracked player's location membership to match their current position.
local function updateLocation(track, player)
  local newLoc = INC.Data.ResolveLocation(INC.Caches, player:GetMapId(), player:GetZoneId(), player:GetAreaId())
  if newLoc == track.locationId then return end
  if track.locationId then
    local old = INC.State.LocationState[track.locationId]
    if old and old.players[track.guidLow] then
      old.players[track.guidLow] = nil
      old.count = old.count - 1
    end
  end
  track.locationId = newLoc
  if newLoc then
    local ls = locState(newLoc)
    if not ls.players[track.guidLow] then
      ls.players[track.guidLow] = true
      ls.count = ls.count + 1
    end
  end
end

local function classBit(class)
  if class >= 1 and class <= 32 then return lshift(1, class - 1) end
  return 0
end
local function raceBit(race)
  if race >= 1 and race <= 32 then return lshift(1, race - 1) end
  return 0
end

-- Build/refresh the track for one player and place them in their location. Shared by
-- the login hook and TrackOnline (the `.reload ale` path).
local function track(player)
  local guidLow = player:GetGUIDLow()
  local class, race = player:GetClass(), player:GetRace()
  local t = {
    guid = player:GetGUID(),
    guidLow = guidLow,
    classId = class,
    raceId = race,
    classBits = classBit(class),
    raceBits = raceBit(race),
    teamBits = (player:GetTeam() == 0) and INC.Team.ALLIANCE or INC.Team.HORDE,
    zoneId = player:GetZoneId(),
    areaId = player:GetAreaId(),
    locationId = nil,
    cooldownUntil = 0,
    lineCd = {},    -- [lineId]  -> untilMs  (per-player; never blocks OTHER players)
    groupCd = {},   -- [group]   -> untilMs  (per-player)
  }
  INC.State.PlayerTrack[guidLow] = t
  updateLocation(t, player)
end

local function onLogin(_, player)
  track(player)
end

local function onLogout(_, player)
  local guidLow = player:GetGUIDLow()
  local t = INC.State.PlayerTrack[guidLow]
  if t and t.locationId then
    local ls = INC.State.LocationState[t.locationId]
    if ls and ls.players[guidLow] then
      ls.players[guidLow] = nil
      ls.count = ls.count - 1
    end
  end
  INC.State.PlayerTrack[guidLow] = nil
end

local function onZoneOrArea(_, player)
  local guidLow = player:GetGUIDLow()
  local t = INC.State.PlayerTrack[guidLow]
  if not t then return end  -- not yet tracked (rare ordering); login will set it
  t.zoneId = player:GetZoneId()
  t.areaId = player:GetAreaId()
  updateLocation(t, player)
end

-- Track every already-connected player. Called once at Boot: a no-op at server
-- startup (nobody online yet), but on `.reload ale` it re-tracks connected players,
-- who otherwise get no login event (ALE reload limitation) and would stay invisible
-- to the feature until relog.
function INC.Players.TrackOnline()
  local players = GetPlayersInWorld()
  if type(players) ~= "table" then return 0 end
  local n = 0
  for _, player in pairs(players) do
    if player then track(player); n = n + 1 end
  end
  return n
end

function INC.Players.Init()
  INC.State.PlayerTrack = {}
  INC.State.LocationState = {}
  RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, INC.Protect("players.onLogin", onLogin))
  RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT, INC.Protect("players.onLogout", onLogout))
  RegisterPlayerEvent(PLAYER_EVENT_ON_UPDATE_ZONE, INC.Protect("players.onZone", onZoneOrArea))
  RegisterPlayerEvent(PLAYER_EVENT_ON_UPDATE_AREA, INC.Protect("players.onArea", onZoneOrArea))
end
