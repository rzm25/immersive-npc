-- 06_inc_scheduler.lua — event-driven heartbeat, PER-PLAYER emission, cooldowns,
-- final validation, metrics.
--
-- Emission model (spec v2): every heartbeat the scheduler sweeps players in populated
-- hubs and emits for each whose PERSONAL cadence is due, up to MaxEmitsPerTick this
-- tick. Pacing is per-player (arrival line, then an escalating personal gap) + per-NPC
-- (anti-repeat), NOT a single server-wide throttle — so a hub with 250 arrivals can
-- greet them all while each individual still hears lines only rarely. (The original v1
-- model emitted at most one line per tick server-wide, which starved individuals on a
-- populated server — ADR-011.)
--
-- Heartbeat rule (spec §4.7, the single most important Lua-side perf rule): the
-- heartbeat is CreateLuaEvent(fn, SchedulerTickMs, 0) — a repeating timer. We NEVER
-- register WORLD_EVENT_ON_UPDATE (13); that would cross the C++->Lua bridge ~20×/s.
--
-- Timer/global API verified against S1 pin (GlobalMethods.h @ e36707d):
--   id = CreateLuaEvent(fn, delayMs, repeats)   repeats 0 = infinite; returns event id
--   RemoveEventById(id)                          cancel (used on state close)
--   GetGameTime()                                int64 epoch SECONDS (never wraps)
--   GetPlayerByGUID(objectguid) / map:GetWorldObject(objectguid)  resolve by GUID
--
-- The entire tick body runs inside ONE pcall wrapper (INC.Protect) so a scripting
-- bug degrades the feature instead of spamming every tick (spec §4.4).

INC = INC or {}
INC.Scheduler = INC.Scheduler or {}
local U = INC.Util
local band = bit32.band

-- ms clock from epoch seconds. ALE boxes int64 return values (incl. GetGameTime) as a
-- LongLong *userdata*, which can't be used with math.randomseed or plain arithmetic —
-- so when GetGameTime() isn't a plain number (i.e. on ALE), fall back to os.time()
-- (a plain-number epoch clock; ALE calls luaL_openlibs so os is available). Both are
-- epoch seconds and never wrap, unlike getMSTime() (ADR-002/ADR-010).
function INC.NowMs()
  local g = GetGameTime()
  if type(g) == "number" then return g * 1000 end
  return os.time() * 1000
end

-- Failure-reason / outcome codes (spec §8). Every tick ends on exactly one of these.
local REASONS = {
  "EMITTED", "GLOBAL_COOLDOWN", "NO_ACTIVE_LOCATION", "LOCATION_COOLDOWN",
  "NO_ACTIVE_PLAYER", "PLAYER_COOLDOWN", "NO_NEARBY_NPC", "NPC_COOLDOWN",
  "NO_MATCHING_LINE", "GROUP_COOLDOWN", "LINE_COOLDOWN",
  "FINAL_VALIDATION_FAILED_PLAYER", "FINAL_VALIDATION_FAILED_NPC",
  "PHASE_MISMATCH", "LUA_ERROR",
}

function INC.Scheduler.NewMetrics()
  local m = {}
  for _, k in ipairs(REASONS) do m[k] = 0 end
  return m
end

local CLASS_NAME = {
  [1] = "warrior", [2] = "paladin", [3] = "hunter", [4] = "rogue", [5] = "priest",
  [6] = "death knight", [7] = "shaman", [8] = "mage", [9] = "warlock", [11] = "druid",
}
local RACE_NAME = {
  [1] = "human", [2] = "orc", [3] = "dwarf", [4] = "night elf", [5] = "undead",
  [6] = "tauren", [7] = "gnome", [8] = "troll", [10] = "blood elf", [11] = "draenei",
}

local CHAT_MAX_BYTES = 255           -- server chat line ceiling
local LANG_UNIVERSAL = 0

-- Reusable scratch arrays — never re-allocated per tick (spec §11). Each is paired
-- with an explicit count so we read only [1..n].
local sNpc, sNpcProf = {}, {}
local sLine = {}
local replScratch = { player = "", class = "", race = "", weapon_type = "" }

-- ---------------------------------------------------------------------------
-- Selection stages. Each returns the pick (or nil) plus, on failure, whether a
-- candidate existed but was blocked by cooldown (to attribute the right metric).
-- ---------------------------------------------------------------------------

-- Candidate NPC: in the location's registry, on the player's map, within the cheap
-- squared-distance pre-filter (cached spawn pos), cooldown-clear. Picks one at
-- random among candidates. Returns reg entry + its live profile.
-- NOTE: the per-NPC cooldown is honored even for a forced attempt — `.inm force`
-- bypasses only the player's own cadence, not per-entity cooldowns, so forcing twice
-- against a lone NPC is blocked until `.inm cooldown clear` (TESTPLAN matrix 4).
local function selectNpc(loc, player, cfg, now)
  local px, py, pz = player:GetX(), player:GetY(), player:GetZ()
  local pmap = player:GetMapId()
  local radiusSq = cfg.MaxCandidateSearchRadius * cfg.MaxCandidateSearchRadius
  local n = 0
  local anyNear, anyBlocked = false, false
  for guidLow, reg in pairs(INC.Registry.ForLocation(loc.id)) do
    if reg.mapId == pmap then
      local dx, dy, dz = reg.x - px, reg.y - py, reg.z - pz
      if dx * dx + dy * dy + dz * dz <= radiusSq then
        anyNear = true
        local prof = INC.Data.FindProfile(INC.Caches, reg.entry, loc.id, guidLow)
        if prof then
          if reg.cooldownUntil <= now then
            n = n + 1
            sNpc[n] = reg
            sNpcProf[n] = prof
          else
            anyBlocked = true
          end
        end
      end
    end
  end
  if n == 0 then
    if anyNear and anyBlocked then return nil, nil, "NPC_COOLDOWN" end
    return nil, nil, "NO_NEARBY_NPC"
  end
  local i = math.random(1, n)
  return sNpc[i], sNpcProf[i], nil
end

-- Matching line for (player context, npc role). Two-stage: content match first
-- (attributes the NO_MATCHING_LINE reason), then cooldown-group / line-repeat gates.
local function selectLine(loc, track, prof, tagLo, tagHi, quality, now)
  local lines = INC.Caches.LinesByLocation[loc.id]
  if not lines then return nil, "NO_MATCHING_LINE" end
  local n = 0
  local anyContent, blockedGroup, blockedLine = false, false, false
  for i = 1, #lines do
    local line = lines[i]
    if U.MatchAny32(track.classBits, line.classMask)
        and U.MatchAny32(track.raceBits, line.raceMask)
        and U.MatchAny32(track.teamBits, line.teamMask)
        and U.MatchAny64(prof.roleMaskLo, prof.roleMaskHi, line.roleMaskLo, line.roleMaskHi)
        and U.MatchAll64(tagLo, tagHi, line.itemTagLo, line.itemTagHi)
        and quality >= line.minQuality
        and ((line.minLevel or 0) == 0 or (track.level or 0) >= line.minLevel)
        and (line.chatMode ~= INC.ChatMode.WHISPER
             or (INC.Config.AllowPersonalWhispers and prof.allowPersonal)) then
      anyContent = true
      -- Per-PLAYER line/group cooldowns: keep variety for THIS listener without ever
      -- blocking another player who happens to be nearby (this player's activity must
      -- not starve everyone else's ambient).
      local groupOk = line.cooldownGroup == 0 or (track.groupCd[line.cooldownGroup] or 0) <= now
      local lineOk = (track.lineCd[line.id] or 0) <= now
      if not groupOk then
        blockedGroup = true
      elseif not lineOk then
        blockedLine = true
      else
        n = n + 1
        sLine[n] = line
      end
    end
  end
  if n == 0 then
    if not anyContent then return nil, "NO_MATCHING_LINE" end
    if blockedGroup then return nil, "GROUP_COOLDOWN" end
    if blockedLine then return nil, "LINE_COOLDOWN" end
    return nil, "NO_MATCHING_LINE"
  end
  local line = U.WeightedPick(sLine, n, function(l) return l.weight end, math.random)
  return line, nil
end

-- ---------------------------------------------------------------------------
-- Final validation (spec §4.4) — mandatory, immediately before emission.
-- ---------------------------------------------------------------------------

-- Returns true if the player is still a legal target. `player` is already resolved.
local function validatePlayer(player, loc)
  if not player:IsInWorld() then return false end
  if not player:IsAlive() then return false end          -- excludes dead AND ghost
  if player:IsInCombat() then return false end
  if player:IsTaxi() then return false end
  if player:IsGM() and not player:IsGMVisible() then return false end  -- GM-invisible
  local nowLoc = INC.Data.ResolveLocation(INC.Caches, player:GetMapId(), player:GetZoneId(), player:GetAreaId())
  return nowLoc == loc.id
end

-- Resolve + validate the NPC on the player's map. Returns (npc, reasonOrNil).
local function validateNpc(player, reg, prof, cfg)
  local map = player:GetMap()
  if not map then return nil, "FINAL_VALIDATION_FAILED_NPC" end
  local npc = map:GetWorldObject(reg.guid)
  if not npc then return nil, "FINAL_VALIDATION_FAILED_NPC" end
  if not npc:IsInWorld() or not npc:IsAlive() or npc:IsInCombat() then
    return nil, "FINAL_VALIDATION_FAILED_NPC"
  end
  if band(player:GetPhaseMask(), npc:GetPhaseMask()) == 0 then
    return nil, "PHASE_MISMATCH"
  end
  if player:GetDistance(npc) > prof.maxSpeakDistance then   -- LIVE distance (patrollers)
    return nil, "FINAL_VALIDATION_FAILED_NPC"
  end
  if cfg.RequireLineOfSight and not npc:IsWithinLoS(player) then
    return nil, "FINAL_VALIDATION_FAILED_NPC"
  end
  if cfg.RequireNpcFacingPlayer and not npc:IsInFront(player) then
    return nil, "FINAL_VALIDATION_FAILED_NPC"
  end
  return npc, nil
end

-- ---------------------------------------------------------------------------
-- Emission
-- ---------------------------------------------------------------------------

local function emit(npc, player, line, track, weaponType)
  local repl = replScratch
  repl.player = player:GetName() or "stranger"
  repl.class = CLASS_NAME[track.classId] or "adventurer"
  repl.race = RACE_NAME[track.raceId] or "traveller"
  repl.weapon_type = weaponType or "weapon"
  local text = U.TruncateBytes(U.ReplacePlaceholders(line.text, repl), CHAT_MAX_BYTES)

  if line.chatMode == INC.ChatMode.WHISPER then
    npc:SendUnitWhisper(text, LANG_UNIVERSAL, player, false)
  elseif line.chatMode == INC.ChatMode.EMOTE then
    local emoteId = tonumber(line.text)
    if emoteId then
      npc:PerformEmote(emoteId)          -- numeric line text = animation id
    else
      npc:SendUnitEmote(text)            -- otherwise a visible text emote
    end
  else
    npc:SendUnitSay(text, LANG_UNIVERSAL)
  end
end

-- ---------------------------------------------------------------------------
-- Per-player emission (spec v2). Emit ONE line for a specific player standing in
-- `loc`, if a nearby speakable NPC and a matching, cooldown-clear line exist and
-- final validation passes. On success applies the player's ESCALATING cadence (their
-- next line is delayed by PlayerCadenceMs indexed by how many they've heard this
-- visit) plus the per-NPC / per-line / per-group anti-repeat cooldowns. Returns the
-- reason code; the caller counts the metric. Used by both the tick and `.inm force`.
-- ---------------------------------------------------------------------------

local function emitForPlayer(loc, track, player, cfg, now)
  local reg, prof, nFail = selectNpc(loc, player, cfg, now)
  if not reg then return nFail end

  -- Lazy equipment scan — this player, this instant (spec §4.5). Only after a nearby
  -- NPC is found, so a due player with no NPC in range costs no scan.
  local tagLo, tagHi, quality, weaponType = INC.Players.ScanEquipment(player)

  local line, lFail = selectLine(loc, track, prof, tagLo, tagHi, quality, now)
  if not line then return lFail end

  if not validatePlayer(player, loc) then return "FINAL_VALIDATION_FAILED_PLAYER" end
  local npc, vFail = validateNpc(player, reg, prof, cfg)
  if not npc then return vFail end

  emit(npc, player, line, track, weaponType)

  -- Escalating per-player cadence: the more this player has already heard THIS visit,
  -- the longer until their next line (last value repeats). Reset to 0 on arrival
  -- (05_inc_players.updateLocation), so a fresh visit starts responsive again.
  track.emitCount = (track.emitCount or 0) + 1
  local cad = cfg.PlayerCadenceMs
  track.nextEligibleMs = now + (cad[track.emitCount] or cad[#cad])
  reg.cooldownUntil = now + cfg.NpcCooldownMs
  track.lineCd[line.id] = now + cfg.LineCooldownMs
  if line.cooldownGroup ~= 0 then
    track.groupCd[line.cooldownGroup] = now + cfg.CooldownGroupMs
  end

  if INC.Config.Debug then
    INC.DebugLog(("emitted line %d at '%s' -> %s"):format(line.id, loc.name, tostring(player:GetName())))
  end
  return "EMITTED"
end

-- Heartbeat body: sweep every populated hub and, for each player whose personal cadence
-- is DUE, emit one line — up to MaxEmitsPerTick emissions this tick (bounds a mass-arrival
-- burst; the rest are served next tick). A due player with no speakable NPC in range yet
-- is pushed out by RetryBackoffMs so we recheck them soon (walk-up responsiveness) without
-- rescanning the registry for them every single tick. This is O(players in hubs) per tick,
-- with the expensive NPC scan + equipment scan only on the (bounded) due set.
local function tick()
  local cfg = INC.Config
  if not cfg.Enable then return end
  local now = INC.NowMs()
  local metrics = INC.State.Metrics
  local budget = cfg.MaxEmitsPerTick
  local emitted = 0
  for _, loc in ipairs(INC.Caches.LocationList) do
    local ls = INC.State.LocationState[loc.id]
    if ls and ls.count > 0 then
      for guidLow in pairs(ls.players) do
        local track = INC.State.PlayerTrack[guidLow]
        if track and (track.nextEligibleMs or 0) <= now then
          local player = GetPlayerByGUID(track.guid)
          if player and player:IsInWorld() then
            local reason = emitForPlayer(loc, track, player, cfg, now)
            metrics[reason] = (metrics[reason] or 0) + 1
            if reason == "EMITTED" then
              emitted = emitted + 1
              if emitted >= budget then return end
            else
              track.nextEligibleMs = now + cfg.RetryBackoffMs  -- recheck soon, don't rescan every tick
            end
          end
        end
      end
    end
  end
end

-- Public entry for `.inm force [self]`. Bypasses the player's cadence (emits on demand)
-- but still honors per-NPC / line / group cooldowns + full validation, so forcing twice
-- against a lone NPC is blocked by NPC cooldown until `.inm cooldown clear` (TESTPLAN
-- matrix 4). Commands only ever force the GM's own guid. Returns the outcome reason.
function INC.Scheduler.RunAttempt(_forced, targetGuidLow)
  local cfg = INC.Config
  local now = INC.NowMs()
  local metrics = INC.State.Metrics
  local function done(reason)
    metrics[reason] = (metrics[reason] or 0) + 1
    return reason
  end
  if not cfg.Enable then return done("GLOBAL_COOLDOWN") end
  if not targetGuidLow then return done("NO_ACTIVE_PLAYER") end
  local track = INC.State.PlayerTrack[targetGuidLow]
  if not track or not track.locationId then return done("NO_ACTIVE_LOCATION") end
  local loc = INC.Caches.Locations[track.locationId]
  if not loc then return done("NO_ACTIVE_LOCATION") end
  local player = GetPlayerByGUID(track.guid)
  if not player or not player:IsInWorld() then return done("NO_ACTIVE_PLAYER") end
  return done(emitForPlayer(loc, track, player, cfg, now))
end

function INC.Scheduler.ClearCooldowns()
  for _, track in pairs(INC.State.PlayerTrack) do
    track.emitCount = 0
    track.nextEligibleMs = 0     -- due immediately again
    track.lineCd = {}
    track.groupCd = {}
  end
  for _, locTable in pairs(INC.State.Registry) do
    for _, reg in pairs(locTable) do reg.cooldownUntil = 0 end
  end
end

function INC.Scheduler.Init()
  INC.State.Metrics = INC.Scheduler.NewMetrics()
  -- All pacing is now per-player (on each PlayerTrack) + per-NPC (on each registry entry);
  -- there is no global/location bucket state to initialise.

  -- Cancel any prior heartbeat before creating a new one, so re-entering Boot inside one
  -- Lua state can't leak a timer. (INC.schedulerEventId persists on INC, not on the
  -- freshly-reset INC.State, precisely so it survives to be cancelled here.)
  if INC.schedulerEventId then RemoveEventById(INC.schedulerEventId) end
  local tickFn = INC.Protect("scheduler.tick", tick)
  INC.schedulerEventId = CreateLuaEvent(tickFn, INC.Config.SchedulerTickMs, 0)
  INC.State.schedulerEventId = INC.schedulerEventId
end
