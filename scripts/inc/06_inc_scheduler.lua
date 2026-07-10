-- 06_inc_scheduler.lua — event-driven heartbeat, selection pipeline, cooldowns,
-- final validation, emission, metrics.
--
-- Heartbeat rule (spec §4.7, the single most important Lua-side perf rule): the
-- heartbeat is CreateLuaEvent(fn, SchedulerTickMs, 0) — a repeating timer. We NEVER
-- register WORLD_EVENT_ON_UPDATE (13); that would cross the C++->Lua bridge ~20×/s
-- to do nothing.
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
local LOCATION_BURST = 2             -- per-location token-bucket capacity (spec §4.6)

-- Reusable scratch arrays — never re-allocated per tick (spec §11). Each is paired
-- with an explicit count so we read only [1..n].
local sLoc = {}
local sPlayers = {}
local sNpc, sNpcProf = {}, {}
local sLine = {}
local replScratch = { player = "", class = "", race = "", weapon_type = "" }

-- ---------------------------------------------------------------------------
-- Per-location pacing state
-- ---------------------------------------------------------------------------

local function locPacing(locId)
  local p = INC.State.LocPacing[locId]
  if not p then
    p = { lastEmitMs = 0, emitTimes = {},
          bucket = U.NewBucket(LOCATION_BURST, LOCATION_BURST * 60000, INC.NowMs()) }
    INC.State.LocPacing[locId] = p
  end
  return p
end

-- Count emit timestamps within `windowMs` of now (for the per-10min hard cap).
local function countRecent(times, now, windowMs)
  local n = 0
  for i = 1, #times do
    if now - times[i] < windowMs then n = n + 1 end
  end
  return n
end

-- ---------------------------------------------------------------------------
-- Selection stages. Each returns the pick (or nil) plus, on failure, whether a
-- candidate existed but was blocked by cooldown (to attribute the right metric).
-- ---------------------------------------------------------------------------

-- Eligible locations: enabled, populated, and (unless forced) pacing-clear.
local function selectLocation(cfg, now, forced)
  local n = 0
  local anyPopulated, anyBlocked = false, false
  for _, loc in ipairs(INC.Caches.LocationList) do
    local ls = INC.State.LocationState[loc.id]
    local count = ls and ls.count or 0
    if count > 0 then
      anyPopulated = true
      local ok = true
      if not forced then
        local pacing = locPacing(loc.id)
        local floorMs = math.max(loc.minIntervalMs, cfg.LocationMinIntervalMs)
        local cap = math.min(loc.maxLinesPer10Min, cfg.LocationMaxLinesPer10Min)
        if now - pacing.lastEmitMs < floorMs then
          ok = false
        elseif countRecent(pacing.emitTimes, now, 600000) >= cap then
          ok = false
        elseif cfg.PopulationScaling.Enable then
          local ps = cfg.PopulationScaling
          local perMin = U.PopulationPerMinute(count, ps.BasePerMinute, ps.LogScale, ps.MaxPerMinute)
          if perMin <= 0 then
            ok = false
          else
            pacing.bucket.refillWindowMs = pacing.bucket.capacity * 60000 / perMin
            if not U.BucketPeek(pacing.bucket, now) then ok = false end
          end
        end
      end
      if ok then
        n = n + 1
        sLoc[n] = loc
      else
        anyBlocked = true
      end
    end
  end
  if n == 0 then
    if anyPopulated and anyBlocked then return nil, "LOCATION_COOLDOWN" end
    return nil, "NO_ACTIVE_LOCATION"
  end
  -- Uniform pick over the eligible set. Population already gates the emission RATE
  -- per location (the bucket window above), so it must not also bias the choice —
  -- that would double-count busy hubs.
  return sLoc[math.random(1, n)], nil
end

-- Eligible player in a location: tracked, present, cooldown-clear. If a target guid
-- is given (force self), only that player is considered.
local function selectPlayer(loc, now, targetGuidLow)
  local ls = INC.State.LocationState[loc.id]
  if not ls or ls.count == 0 then return nil, "NO_ACTIVE_PLAYER" end
  local n = 0
  local anyBlocked = false
  for guidLow in pairs(ls.players) do
    if not targetGuidLow or guidLow == targetGuidLow then
      local track = INC.State.PlayerTrack[guidLow]
      if track then
        if track.cooldownUntil <= now then
          n = n + 1
          sPlayers[n] = track
        else
          anyBlocked = true
        end
      end
    end
  end
  if n == 0 then
    if anyBlocked then return nil, "PLAYER_COOLDOWN" end
    return nil, "NO_ACTIVE_PLAYER"
  end
  return sPlayers[math.random(1, n)], nil
end

-- Candidate NPC: in the location's registry, on the player's map, within the cheap
-- squared-distance pre-filter (cached spawn pos), cooldown-clear. Picks one at
-- random among candidates. Returns reg entry + its live profile.
-- NOTE: the per-NPC cooldown is honored even for a forced attempt — `.inm force`
-- bypasses only the global/location PACING, not per-entity cooldowns, so forcing
-- twice is blocked until `.inm cooldown clear` (TESTPLAN matrix 4).
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
        and (line.chatMode ~= INC.ChatMode.WHISPER
             or (INC.Config.AllowPersonalWhispers and prof.allowPersonal)) then
      anyContent = true
      local groupOk = line.cooldownGroup == 0 or (INC.State.GroupCooldown[line.cooldownGroup] or 0) <= now
      local lineOk = (INC.State.LineCooldown[line.id] or 0) <= now
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
-- The attempt (heartbeat body AND `.inm force`). forced=true bypasses the global +
-- location PACING gates but still honors per-player/npc/line/group cooldowns and
-- full final validation (so `.inm force` twice is blocked until `.inm cooldown
-- clear` — TESTPLAN matrix 4). Returns the outcome reason code.
-- ---------------------------------------------------------------------------

local function attemptBody(forced, targetGuidLow)
  local cfg = INC.Config
  local metrics = INC.State.Metrics
  local now = INC.NowMs()

  local function done(reason)
    metrics[reason] = (metrics[reason] or 0) + 1
    return reason
  end

  if not cfg.Enable then return done("GLOBAL_COOLDOWN") end

  -- Global gate (peek only; consumed on success) — skipped when forced.
  if not forced then
    if now - (INC.State.GlobalLastEmitMs or 0) < cfg.GlobalMinIntervalMs then
      return done("GLOBAL_COOLDOWN")
    end
    if not U.BucketPeek(INC.State.GlobalBucket, now) then
      return done("GLOBAL_COOLDOWN")
    end
  end

  -- Location.
  local loc, locFail
  if targetGuidLow then
    local track = INC.State.PlayerTrack[targetGuidLow]
    if not track or not track.locationId then return done("NO_ACTIVE_LOCATION") end
    loc = INC.Caches.Locations[track.locationId]
    if not loc then return done("NO_ACTIVE_LOCATION") end
  else
    loc, locFail = selectLocation(cfg, now, forced)
    if not loc then return done(locFail) end
  end

  -- Player.
  local track, pFail = selectPlayer(loc, now, targetGuidLow)
  if not track then return done(pFail) end

  local player = GetPlayerByGUID(track.guid)
  if not player or not player:IsInWorld() then return done("NO_ACTIVE_PLAYER") end

  -- Lazy equipment scan — this one player, this instant (spec §4.5).
  local tagLo, tagHi, quality, weaponType = INC.Players.ScanEquipment(player)

  -- NPC.
  local reg, prof, nFail = selectNpc(loc, player, cfg, now)
  if not reg then return done(nFail) end

  -- Line.
  local line, lFail = selectLine(loc, track, prof, tagLo, tagHi, quality, now)
  if not line then return done(lFail) end

  -- Final validation.
  if not validatePlayer(player, loc) then return done("FINAL_VALIDATION_FAILED_PLAYER") end
  local npc, vFail = validateNpc(player, reg, prof, cfg)
  if not npc then return done(vFail) end

  -- Emit.
  emit(npc, player, line, track, weaponType)

  -- Apply cooldowns + pacing bookkeeping.
  track.cooldownUntil = now + cfg.PlayerCooldownMs
  reg.cooldownUntil = now + cfg.NpcCooldownMs
  INC.State.LineCooldown[line.id] = now + cfg.LineCooldownMs
  if line.cooldownGroup ~= 0 then
    INC.State.GroupCooldown[line.cooldownGroup] = now + cfg.CooldownGroupMs
  end
  if not forced then
    INC.State.GlobalLastEmitMs = now
    U.BucketTryConsume(INC.State.GlobalBucket, now)
    local pacing = locPacing(loc.id)
    pacing.lastEmitMs = now
    pacing.emitTimes[#pacing.emitTimes + 1] = now
    -- prune the 10-min ring so it can't grow unbounded
    if #pacing.emitTimes > 64 then
      local keep = {}
      for i = 1, #pacing.emitTimes do
        if now - pacing.emitTimes[i] < 600000 then keep[#keep + 1] = pacing.emitTimes[i] end
      end
      pacing.emitTimes = keep
    end
    U.BucketTryConsume(pacing.bucket, now)
  end

  if INC.Config.Debug then
    INC.DebugLog(("emitted line %d at '%s' -> %s"):format(line.id, loc.name, tostring(player:GetName())))
  end
  return done("EMITTED")
end

-- Public entry for `.inm force`. Returns the outcome reason.
function INC.Scheduler.RunAttempt(forced, targetGuidLow)
  return attemptBody(forced, targetGuidLow)
end

function INC.Scheduler.ClearCooldowns()
  for _, track in pairs(INC.State.PlayerTrack) do track.cooldownUntil = 0 end
  for _, locTable in pairs(INC.State.Registry) do
    for _, reg in pairs(locTable) do reg.cooldownUntil = 0 end
  end
  INC.State.LineCooldown = {}
  INC.State.GroupCooldown = {}
  INC.State.GlobalLastEmitMs = 0
  local now = INC.NowMs()
  INC.State.GlobalBucket = U.NewBucket(INC.Config.GlobalBurstMax, INC.Config.GlobalBurstWindowMs, now)
  for _, p in pairs(INC.State.LocPacing) do
    p.lastEmitMs = 0
    p.emitTimes = {}
    p.bucket = U.NewBucket(LOCATION_BURST, LOCATION_BURST * 60000, now)
  end
end

function INC.Scheduler.Init()
  local now = INC.NowMs()
  INC.State.Metrics = INC.Scheduler.NewMetrics()
  INC.State.GlobalBucket = U.NewBucket(INC.Config.GlobalBurstMax, INC.Config.GlobalBurstWindowMs, now)
  INC.State.GlobalLastEmitMs = now   -- start the global min-interval clock at boot (no line in the first interval; sane `.inm status`)
  INC.State.LocPacing = {}
  INC.State.LineCooldown = {}
  INC.State.GroupCooldown = {}

  -- Cancel any prior heartbeat before creating a new one, so re-entering Boot inside
  -- one Lua state can't leak a timer. (INC.schedulerEventId persists on INC, not on
  -- the freshly-reset INC.State, precisely so it survives to be cancelled here.)
  if INC.schedulerEventId then RemoveEventById(INC.schedulerEventId) end
  local tick = INC.Protect("scheduler.tick", function() attemptBody(false, nil) end)
  INC.schedulerEventId = CreateLuaEvent(tick, INC.Config.SchedulerTickMs, 0)
  INC.State.schedulerEventId = INC.schedulerEventId
end
