#!/usr/bin/env lua5.2
-- tests/integration_mock.lua — offline integration harness (verification path #2 in
-- the workspace gotchas: a standalone logic harness). It stubs the Eluna/ALE engine
-- API + fake game objects, loads all eight production scripts unmodified, and drives
-- the full boot -> select -> validate -> emit pipeline. This exercises the wiring
-- that the pure unit tests cannot: loaders, registry, player tracking, the cooldown
-- gates, final validation, emission dispatch, and `.inm reload` atomicity.
--
-- It is NOT a substitute for the in-game matrix (TESTPLAN §"in-game"): the stubs
-- model the API *contract* I verified against the S1 pin, not the live server. But a
-- green run here means the Lua logic is internally consistent end-to-end.
--
--   $ lua5.2 tests/integration_mock.lua      (run from repo root)

local passed, failed = 0, 0
local function ok(cond, name)
  if cond then passed = passed + 1
  else failed = failed + 1; io.write("  FAIL: " .. name .. "\n") end
end

-- ===========================================================================
-- Controllable clock
-- ===========================================================================
local CLOCK = { sec = 1000000 }        -- epoch seconds

-- ===========================================================================
-- Fake in-memory world DB. Rows are arrays in the EXACT column order the loaders
-- SELECT (see 03_inc_data.lua). The fake query object returns row[i+1] for any typed
-- getter (we store correct Lua types).
-- ===========================================================================
local DB = {}
-- location: id,name,map_id,zone_id,area_id,enabled,min_interval_ms,max_lines_per_10min
DB.location = {
  { 1, "Test City", 0, 1519, 0, 1, 120000, 6 },
}
-- npc_profile: id,creature_entry,creature_guid,location_id,role_mask_lo,role_mask_hi,
--              max_speak_distance,allow_personal_lines,enabled
DB.npc_profile = {
  { 1, 68, 0, 1, 1, 0, 25.0, 1, 1 },     -- entry 68, role GUARD (bit0=1), personal ok
  { 2, 68, 0, 99, 1, 0, 25.0, 1, 1 },    -- references location 99 (does not exist): must be skipped, not crash
}
-- line: id,location_mask,npc_role_mask_lo,npc_role_mask_hi,class_mask,race_mask,
--       team_mask,required_item_tags_lo,required_item_tags_hi,min_item_quality,
--       cooldown_group,weight,chat_mode,locale,text,enabled
DB.line = {
  { 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 5, 100, 0, "enUS", "Well met, {race}.", 1 },   -- cooldown_group 5
  { 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 100, 1, "enUS", "Mind the guards, {player}.", 1 },
  { 3, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 100, 0, "deDE", "German line", 1 },  -- non-enUS: must be skipped
}

local function makeQueryResult(rows)
  if #rows == 0 then return nil end
  local idx = 1
  local q = {}
  function q:GetUInt32(i) return rows[idx][i + 1] end
  function q:GetUInt8(i) return rows[idx][i + 1] end
  function q:GetFloat(i) return rows[idx][i + 1] end
  function q:GetString(i) return rows[idx][i + 1] end
  function q:NextRow() idx = idx + 1; return idx <= #rows end
  return q
end

-- ===========================================================================
-- Engine global stubs
-- ===========================================================================
local logs = {}
function PrintInfo(m) logs[#logs + 1] = m end
function PrintError(m) logs[#logs + 1] = m end
function GetGameTime() return CLOCK.sec end

function WorldDBQuery(sql)
  if sql:find("immersive_npc_chat_location") then return makeQueryResult(DB.location) end
  if sql:find("immersive_npc_chat_npc_profile") then return makeQueryResult(DB.npc_profile) end
  if sql:find("immersive_npc_chat_line") then return makeQueryResult(DB.line) end
  return nil
end

-- Captured event handlers.
local playerEvents = {}     -- [eventId] = handler
local creatureEvents = {}   -- [entry][eventId] = handler
local serverEvents = {}
function RegisterPlayerEvent(ev, fn) playerEvents[ev] = fn end
function RegisterCreatureEvent(entry, ev, fn)
  creatureEvents[entry] = creatureEvents[entry] or {}
  creatureEvents[entry][ev] = fn
end
function RegisterServerEvent(ev, fn) serverEvents[ev] = fn end

local luaEvents = {}        -- captured CreateLuaEvent timers
local nextEventId = 1
function CreateLuaEvent(fn) local id = nextEventId; nextEventId = id + 1; luaEvents[id] = fn; return id end
function RemoveEventById(id) luaEvents[id] = nil end

-- Player registry for GetPlayerByGUID.
local playersByGuid = {}
function GetPlayerByGUID(guid) return playersByGuid[guid] end

-- ALE GetPlayersInWorld() returns a table of online Player objects. Test-controlled.
local worldPlayers = {}
function GetPlayersInWorld() return worldPlayers end

-- ===========================================================================
-- Fake game objects
-- ===========================================================================
local function dist3(a, b)
  local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function makeItem(class, subclass, invtype, quality)
  return {
    GetClass = function() return class end,
    GetSubClass = function() return subclass end,
    GetInventoryType = function() return invtype end,
    GetQuality = function() return quality end,
  }
end

local mapSingleton  -- forward decl; one shared map
local allCreatures = {}  -- every makeCreature() is appended here (for GetCreaturesInRange)

local function makePlayer(o)
  local p = {
    x = o.x, y = o.y, z = o.z, mapId = o.mapId, zoneId = o.zoneId, areaId = o.areaId,
    _guidLow = o.guidLow, _guid = "player:" .. o.guidLow, _name = o.name,
    _class = o.class, _race = o.race, _team = o.team, _equip = o.equip or {},
    alive = true, combat = false, taxi = false,
    gm = o.gm or false, gmVisible = o.gmVisible ~= false,
    gmRank = o.gmRank or 0, phase = o.phase or 1, world = true,
  }
  function p:GetGUIDLow() return self._guidLow end
  function p:GetGUID() return self._guid end
  function p:GetName() return self._name end
  function p:GetClass() return self._class end
  function p:GetRace() return self._race end
  function p:GetTeam() return self._team end
  function p:GetZoneId() return self.zoneId end
  function p:GetAreaId() return self.areaId end
  function p:GetMapId() return self.mapId end
  function p:GetX() return self.x end
  function p:GetY() return self.y end
  function p:GetZ() return self.z end
  function p:IsInWorld() return self.world end
  function p:IsAlive() return self.alive end
  function p:IsInCombat() return self.combat end
  function p:IsTaxi() return self.taxi end
  function p:IsGM() return self.gm end
  function p:IsGMVisible() return self.gmVisible end
  function p:GetGMRank() return self.gmRank end
  function p:GetPhaseMask() return self.phase end
  function p:GetMap() return mapSingleton end
  function p:GetDistance(other) return dist3(self, other) end
  function p:GetEquippedItemBySlot(slot) return self._equip[slot] end
  function p:SendBroadcastMessage(_) end
  -- ALE: player:GetCreaturesInRange(range, entry, hostile, dead) -> table of creatures
  function p:GetCreaturesInRange(range, entry)
    local out = {}
    for _, c in ipairs(allCreatures) do
      if (entry == 0 or c._entry == entry) and c.mapId == self.mapId and dist3(self, c) <= range then
        out[#out + 1] = c
      end
    end
    return out
  end
  playersByGuid[p._guid] = p
  return p
end

local creaturesByGuid = {}
local function makeCreature(o)
  local c = {
    x = o.x, y = o.y, z = o.z, mapId = o.mapId, zoneId = o.zoneId, areaId = o.areaId,
    _entry = o.entry, _guidLow = o.guidLow, _guid = "creature:" .. o.guidLow,
    alive = true, combat = false, phase = o.phase or 1, world = true,
    lastSay = nil, lastWhisper = nil, lastEmote = nil, lastPerform = nil,
  }
  function c:GetEntry() return self._entry end
  function c:GetGUIDLow() return self._guidLow end
  function c:GetGUID() return self._guid end
  function c:GetMapId() return self.mapId end
  function c:GetZoneId() return self.zoneId end
  function c:GetAreaId() return self.areaId end
  function c:GetX() return self.x end
  function c:GetY() return self.y end
  function c:GetZ() return self.z end
  function c:IsInWorld() return self.world end
  function c:IsAlive() return self.alive end
  function c:IsInCombat() return self.combat end
  function c:GetPhaseMask() return self.phase end
  function c:IsWithinLoS(_) return true end
  function c:IsInFront(_) return true end
  function c:SendUnitSay(msg) self.lastSay = msg end
  function c:SendUnitWhisper(msg) self.lastWhisper = msg end
  function c:SendUnitEmote(msg) self.lastEmote = msg end
  function c:PerformEmote(id) self.lastPerform = id end
  creaturesByGuid[c._guid] = c
  allCreatures[#allCreatures + 1] = c
  return c
end

mapSingleton = {
  GetWorldObject = function(_, guid) return creaturesByGuid[guid] end,
}

-- ===========================================================================
-- Load production scripts (order matters: 01..08). 08 calls INC.Boot().
-- ===========================================================================
INC = {}
for _, f in ipairs({ "01_inc_config", "02_inc_util", "03_inc_data", "04_inc_registry",
                     "05_inc_players", "06_inc_scheduler", "07_inc_commands", "08_inc_main" }) do
  dofile("scripts/inc/" .. f .. ".lua")
end

-- ---- boot assertions -------------------------------------------------------
ok(INC.State and INC.State.booted, "boot: booted flag set")
ok(INC.Caches.Stats.locations == 1, "boot: 1 location loaded")
ok(INC.Caches.Stats.lines == 2, "boot: 2 enUS lines (deDE row skipped)")
ok(INC.Caches.ProfiledEntries[68] == true, "boot: entry 68 profiled")
ok(INC.Caches.Stats.skipped >= 1, "boot: profile with unknown location_id skipped (aggregated, no crash)")
ok(creatureEvents[68] and creatureEvents[68][36] and creatureEvents[68][37], "boot: ON_ADD/ON_REMOVE hooked for entry 68")
ok(luaEvents[INC.schedulerEventId] ~= nil, "boot: heartbeat timer created")

-- ---- populate the world ----------------------------------------------------
-- Warrior (class 1) human (race 1) Alliance (team 0), in the Test City zone.
local hero = makePlayer({
  guidLow = 5, name = "Testeroni", class = 1, race = 1, team = 0,
  x = 100, y = 100, z = 10, mapId = 0, zoneId = 1519, areaId = 0,
  gm = true, gmRank = 3,  -- GM so we can also drive commands
  equip = {
    [4] = makeItem(4, 4, 20, 4),   -- chest: armor/plate/epic  -> PLATE + quality EPIC(4)
    [15] = makeItem(2, 7, 21, 3),  -- mainhand: weapon/sword/1H -> HAS_WEAPON+SWORD
    [16] = makeItem(4, 6, 14, 3),  -- offhand: armor/shield -> HAS_SHIELD (regression: off-hand branch)
    [18] = makeItem(4, 0, 19, 1),  -- tabard slot -> TABARD
  },
})
playerEvents[3](3, hero)  -- ON_LOGIN
ok(INC.State.PlayerTrack[5] ~= nil, "login: player tracked")
ok(INC.State.LocationState[1] and INC.State.LocationState[1].count == 1, "login: player counted in location 1")

-- A guard (entry 68) right next to the player.
local guard = makeCreature({ entry = 68, guidLow = 1001, x = 102, y = 101, z = 10,
                             mapId = 0, zoneId = 1519, areaId = 0 })
creatureEvents[68][36](36, guard)  -- ON_ADD
ok(INC.State.RegistryCount == 1, "registry: guard registered")

-- ---- lazy equip scan reflects current gear (no relog) ----------------------
do
  local lo, hi, q, wt = INC.Players.ScanEquipment(hero)
  ok(q == 4, "scan: max quality is epic(4)")
  ok(wt == "sword", "scan: weapon_type derived = sword")
  ok(INC.Util.MatchAll64(lo, hi, INC.Util.BitFor(INC.ItemTagPos.PLATE)), "scan: PLATE tag set from chest")
  ok(INC.Util.MatchAll64(lo, hi, INC.Util.BitFor(INC.ItemTagPos.SWORD)), "scan: SWORD tag set from mainhand")
  ok(INC.Util.MatchAll64(lo, hi, INC.Util.BitFor(INC.ItemTagPos.HAS_SHIELD)),
     "scan: HAS_SHIELD from off-hand (regression for the nil-TAG.SHIELD crash)")
  ok(INC.Util.MatchAll64(lo, hi, INC.Util.BitFor(INC.ItemTagPos.TABARD)), "scan: TABARD set")
end

-- ---- forced emission -------------------------------------------------------
guard.lastSay = nil
local r1 = INC.Scheduler.RunAttempt(true, 5)
ok(r1 == "EMITTED", "force: emitted (got " .. r1 .. ")")
ok(guard.lastSay == "Well met, human." or guard.lastWhisper == "Mind the guards, Testeroni.",
   "force: a line was spoken with placeholders replaced (say='" .. tostring(guard.lastSay)
   .. "' whisper='" .. tostring(guard.lastWhisper) .. "')")

-- ---- cooldown blocks a forced repeat (TESTPLAN matrix 4) -------------------
local r2 = INC.Scheduler.RunAttempt(true, 5)
ok(r2 == "PLAYER_COOLDOWN", "cooldown: forced repeat blocked by player cooldown (got " .. r2 .. ")")

-- ---- cooldown clear restores ----------------------------------------------
INC.Scheduler.ClearCooldowns()
local r3 = INC.Scheduler.RunAttempt(true, 5)
ok(r3 == "EMITTED", "cooldown clear: emits again (got " .. r3 .. ")")

-- ---- per-NPC cooldown blocks a FORCED attempt (even for another player) ----
-- Second player next to the same guard. Force self for hero (sets guard NPC
-- cooldown), then force self for player B (B's player cooldown is clear, but the
-- guard is on NPC cooldown) -> must NOT re-use the guard. With one guard, that is
-- NPC_COOLDOWN. Proves `.inm force` honors per-NPC cooldown (TESTPLAN matrix 4).
do
  local heroB = makePlayer({
    guidLow = 6, name = "Sidekick", class = 1, race = 1, team = 0,
    x = 100, y = 100, z = 10, mapId = 0, zoneId = 1519, areaId = 0,
    equip = { [15] = makeItem(2, 7, 21, 2) },
  })
  playerEvents[3](3, heroB)
  INC.Scheduler.ClearCooldowns()
  local a = INC.Scheduler.RunAttempt(true, 5)   -- hero
  ok(a == "EMITTED", "npc-cd: first force emits (got " .. a .. ")")
  local b = INC.Scheduler.RunAttempt(true, 6)   -- sidekick: guard now on NPC cooldown
  ok(b == "NPC_COOLDOWN", "npc-cd: forced attempt for 2nd player blocked by NPC cooldown (got " .. b .. ")")
  playerEvents[4](4, heroB)  -- log the sidekick back out
end

-- ---- final validation: player in combat is not targeted --------------------
INC.Scheduler.ClearCooldowns()
hero.combat = true
local r4 = INC.Scheduler.RunAttempt(true, 5)
ok(r4 == "FINAL_VALIDATION_FAILED_PLAYER", "validation: combat player rejected (got " .. r4 .. ")")
hero.combat = false

-- ---- player too far from any NPC -> NO_NEARBY_NPC --------------------------
INC.Scheduler.ClearCooldowns()
hero.x, hero.y = 1000, 1000
local r5 = INC.Scheduler.RunAttempt(true, 5)
ok(r5 == "NO_NEARBY_NPC", "distance: far player has no nearby NPC (got " .. r5 .. ")")
hero.x, hero.y = 100, 100

-- ---- phase mismatch --------------------------------------------------------
INC.Scheduler.ClearCooldowns()
guard.phase = 2   -- player is phase 1
local r6 = INC.Scheduler.RunAttempt(true, 5)
ok(r6 == "PHASE_MISMATCH", "phase: non-overlapping phase rejected (got " .. r6 .. ")")
guard.phase = 1

-- ---- whisper path honors AllowPersonalWhispers -----------------------------
INC.Scheduler.ClearCooldowns()
-- Force line id 2 (whisper) to be the only content match by disabling say lines: we
-- can't easily pin selection, so instead just confirm a whisper is possible by
-- toggling the config and checking no crash + emission over several tries.
guard.lastWhisper = nil
local sawWhisper = false
for _ = 1, 40 do
  INC.Scheduler.ClearCooldowns()
  INC.Scheduler.RunAttempt(true, 5)
  if guard.lastWhisper == "Mind the guards, Testeroni." then sawWhisper = true; break end
end
ok(sawWhisper, "whisper: personal whisper line can be selected + placeholder-filled")

-- with personal whispers disabled, the whisper line must never be chosen
INC.Config.AllowPersonalWhispers = false
guard.lastWhisper = nil
for _ = 1, 40 do
  INC.Scheduler.ClearCooldowns()
  INC.Scheduler.RunAttempt(true, 5)
end
ok(guard.lastWhisper == nil, "whisper: disabled -> whisper line never emitted")
INC.Config.AllowPersonalWhispers = true

-- ---- GM command handler (event 42) ----------------------------------------
do
  local onCmd = playerEvents[42]
  -- non-.inm command must fall through untouched (return nil, not false)
  ok(onCmd(42, hero, "help") == nil, "cmd: non-.inm command falls through (returns nil)")
  -- .inm command is consumed (returns false)
  ok(onCmd(42, hero, "inm status") == false, "cmd: .inm status consumed (returns false)")
  -- `.inm debug on|off` reads the 3rd token (regression guard for the args[3] fix)
  INC.Config.Debug = false
  onCmd(42, hero, "inm debug on")
  ok(INC.Config.Debug == true, "cmd: 'inm debug on' enables debug (args[3])")
  onCmd(42, hero, "inm debug off")
  ok(INC.Config.Debug == false, "cmd: 'inm debug off' disables debug (args[3])")
  -- `.inm force self` runs an attempt (still final-validated) and is consumed
  INC.Scheduler.ClearCooldowns()
  ok(onCmd(42, hero, "inm force self") == false, "cmd: 'inm force self' consumed")
  -- `.inm cooldown clear` path
  ok(onCmd(42, hero, "inm cooldown clear") == false, "cmd: 'inm cooldown clear' consumed")
  -- non-GM is refused (and still consumes the .inm command)
  hero.gm = false
  ok(onCmd(42, hero, "inm status") == false, "cmd: non-GM refused but .inm still consumed")
  hero.gm = true
  -- ALE console command: player is nil -> must fall through untouched (no crash)
  ok(onCmd(42, nil, "inm status") == nil, "cmd: console (nil player) falls through without error")
end

-- ---- TrackOnline re-tracks connected players (the `.reload ale` path) ---------
-- On `.reload ale` no login event fires for already-connected players; TrackOnline
-- picks them up from GetPlayersInWorld(). We add a new player (guid 7) WITHOUT firing
-- login, then verify TrackOnline tracks them — without disturbing hero (guid 5).
do
  local heroC = makePlayer({
    guidLow = 7, name = "Reconnected", class = 1, race = 1, team = 0,
    x = 100, y = 100, z = 10, mapId = 0, zoneId = 1519, areaId = 0,
  })
  worldPlayers = { heroC }
  local n = INC.Players.TrackOnline()
  ok(n == 1, "TrackOnline: reported 1 online player")
  ok(INC.State.PlayerTrack[7] ~= nil, "TrackOnline: connected player is tracked without a login event")
  ok(INC.State.LocationState[1] and INC.State.LocationState[1].players[7], "TrackOnline: placed in their location")
  -- clean up via the real logout handler so shared state is undisturbed for later tests
  worldPlayers = {}
  playerEvents[4](4, heroC)
  ok(INC.State.PlayerTrack[7] == nil, "TrackOnline cleanup: player untracked on logout")
end

-- ---- SeedFromPlayers re-registers guards near players (the `.reload ale` path) ----
-- On reload the registry is empty even though guards are still spawned (ON_ADD only
-- fires on grid load). SeedFromPlayers walks tracked players and re-registers profiled
-- creatures around them via GetCreaturesInRange. Wipe the registry, then reseed: hero
-- (tracked, in Stormwind) is next to the guard, so it must come back.
do
  INC.State.Registry = {}
  INC.State.RegistryIndex = {}
  INC.State.RegistryCount = 0
  local n = INC.Registry.SeedFromPlayers()
  ok(n >= 1, "SeedFromPlayers: re-registered guard(s) near tracked players (got " .. n .. ")")
  ok(INC.State.Registry[1] and INC.State.Registry[1][1001] ~= nil,
     "SeedFromPlayers: Stormwind guard back in the registry without ON_ADD")
end

-- ---- ON_REMOVE deregisters -------------------------------------------------
creatureEvents[68][37](37, guard)
ok(INC.State.RegistryCount == 0, "registry: guard removed on ON_REMOVE")
-- with no NPC, a forced attempt reports NO_NEARBY_NPC
INC.Scheduler.ClearCooldowns()
local r7 = INC.Scheduler.RunAttempt(true, 5)
ok(r7 == "NO_NEARBY_NPC", "registry: emptied registry -> NO_NEARBY_NPC (got " .. r7 .. ")")
creatureEvents[68][36](36, guard)  -- put it back

-- ---- `.inm reload` swaps content atomically -------------------------------
DB.line[1][15] = "Greetings, {class}."   -- change line 1 text
local sum = INC.Reload()
ok(sum:find("2 lines"), "reload: summary reports 2 lines")
local found = false
for _, l in ipairs(INC.Caches.Lines) do if l.text == "Greetings, {class}." then found = true end end
ok(found, "reload: new line text is live in caches")
-- guard still registered after reload (reload doesn't touch the registry)
ok(INC.State.RegistryCount == 1, "reload: registry untouched")
INC.Scheduler.ClearCooldowns()
guard.lastSay = nil; guard.lastWhisper = nil
local r8 = INC.Scheduler.RunAttempt(true, 5)
ok(r8 == "EMITTED", "reload: still emits after reload (got " .. r8 .. ")")

-- ---- ambient emission finds a guard-adjacent player among many far ones ----
-- The whole point of pickPlayerWithNpc: on a busy server most players aren't near a
-- guard. Add several far players in Stormwind; hero is the only one by the guard. An
-- ambient (non-forced) attempt must still emit, not waste the tick on a far player.
do
  local far = {}
  for i = 1, 8 do
    far[i] = makePlayer({ guidLow = 100 + i, name = "Far" .. i, class = 1, race = 1, team = 0,
                          x = 5000 + i, y = 5000, z = 10, mapId = 0, zoneId = 1519, areaId = 0 })
    playerEvents[3](3, far[i])   -- all land in Stormwind (loc 1), far from the guard
  end
  INC.Scheduler.ClearCooldowns()
  guard.lastSay = nil; guard.lastWhisper = nil
  local emitted = false
  for _ = 1, 5 do            -- a few ambient ticks (random order); should find hero quickly
    if INC.Scheduler.RunAttempt(false, nil) == "EMITTED" then emitted = true; break end
    INC.Scheduler.ClearCooldowns()
  end
  ok(emitted, "ambient: emits by finding the guard-adjacent player among 8 far players")
  for i = 1, 8 do playerEvents[4](4, far[i]) end  -- clean up
end

-- ---- ReresolveAll re-recognises a player after a location appears on reload ----
-- Simulate a player who was tracked while their location didn't exist yet (locationId
-- nil), then a `.inm reload` adds it: ReresolveAll must place them without a relog.
do
  local t = INC.State.PlayerTrack[5]
  t.locationId = nil
  INC.State.LocationState = {}
  INC.Players.ReresolveAll()
  ok(t.locationId == 1, "reresolve: player re-recognised into their location after reload")
  ok(INC.State.LocationState[1] and INC.State.LocationState[1].players[5], "reresolve: location membership rebuilt")
end

-- ---- per-player line/group cooldown isolation -------------------------------
-- One player receiving a line must NOT put a different, nearby player on cooldown.
-- Two guards, two players, each next to their own guard: A emits (setting A's line +
-- group-5 cooldowns), then B — whose own cooldowns are empty — must still emit. Under
-- the old global line/group cooldowns, B would have been wrongly blocked.
do
  local guard2 = makeCreature({ entry = 68, guidLow = 1002, x = 300, y = 300, z = 10,
                                mapId = 0, zoneId = 1519, areaId = 0 })
  creatureEvents[68][36](36, guard2)
  local pB = makePlayer({ guidLow = 8, name = "Bystander", class = 1, race = 1, team = 0,
                          x = 301, y = 300, z = 10, mapId = 0, zoneId = 1519, areaId = 0 })
  playerEvents[3](3, pB)
  INC.Scheduler.ClearCooldowns()
  local a = INC.Scheduler.RunAttempt(true, 5)   -- player A (hero) near guard1
  ok(a == "EMITTED", "cd-isolation: player A emits (got " .. a .. ")")
  local b = INC.Scheduler.RunAttempt(true, 8)   -- player B near guard2, own cooldowns empty
  ok(b == "EMITTED", "cd-isolation: player B not blocked by A's line/group cooldown (got " .. b .. ")")
  playerEvents[4](4, pB)
  creatureEvents[68][37](37, guard2)
end

-- ---- heartbeat tick is safe to call and pcall-guarded ----------------------
INC.Scheduler.ClearCooldowns()
local tickFn = luaEvents[INC.schedulerEventId]
local okCall = pcall(tickFn)
ok(okCall, "heartbeat: tick function runs without error")

-- ---- logout removes tracking ----------------------------------------------
playerEvents[4](4, hero)  -- ON_LOGOUT
ok(INC.State.PlayerTrack[5] == nil, "logout: player untracked")
ok(INC.State.LocationState[1].count == 0, "logout: location count decremented")

-- ---- WORLD_EVENT_ON_UPDATE (13) must NEVER be registered (spec §13 DoD) -----
ok(serverEvents[13] == nil, "no WORLD_EVENT_ON_UPDATE registration")

-- ===========================================================================
io.write(string.format("\n%d passed, %d failed\n", passed, failed))
os.exit(failed == 0 and 0 or 1)
