-- 07_inc_commands.lua — GM command set, via PLAYER_EVENT_ON_COMMAND = 42.
--
-- Event verified against S1 pin (Hooks.h @ e36707d): PLAYER_EVENT_ON_COMMAND = 42.
-- Return false to CONSUME the command (stop core processing); return nothing to let
-- any non-`.inm` command fall through untouched (spec §7).
--
--   .inm status | where | force [self] | reload | cooldown clear | stats | debug on|off

INC = INC or {}
INC.Commands = INC.Commands or {}

local PLAYER_EVENT_ON_COMMAND = 42
local MIN_GM_RANK = 2   -- SEC_GAMEMASTER

local function reply(player, msg)
  player:SendBroadcastMessage("|cff66ccff[inm]|r " .. msg)
end

local function splitWords(s)
  local t = {}
  for w in s:gmatch("%S+") do t[#t + 1] = w end
  return t
end

-- ---------------------------------------------------------------------------

local function cmdStatus(player)
  local st = INC.State
  local cfg = INC.Config
  local trackedN = 0
  for _ in pairs(st.PlayerTrack) do trackedN = trackedN + 1 end
  reply(player, ("enabled=%s  debug=%s  tracked=%d  registryNPCs=%d")
    :format(tostring(cfg.Enable), tostring(cfg.Debug), trackedN, st.RegistryCount))
  local now = INC.NowMs()
  reply(player, ("tick=%dms  emitBudget/tick=%d  cadence=%s")
    :format(cfg.SchedulerTickMs, cfg.MaxEmitsPerTick, table.concat(cfg.PlayerCadenceMs, "/")))
  -- Per-location: players present, and how many are DUE for a line right now (their
  -- personal cadence has elapsed) — the live view of the per-player scheduler.
  for _, loc in ipairs(INC.Caches.LocationList) do
    local ls = st.LocationState[loc.id]
    local players, due = 0, 0
    if ls then
      for guidLow in pairs(ls.players) do
        players = players + 1
        local t = st.PlayerTrack[guidLow]
        if t and (t.nextEligibleMs or 0) <= now then due = due + 1 end
      end
    end
    reply(player, ("  loc %d %-16s players=%d  due=%d")
      :format(loc.id, loc.name, players, due))
  end
end

local function cmdWhere(player)
  local caches = INC.Caches
  local mapId, zoneId, areaId = player:GetMapId(), player:GetZoneId(), player:GetAreaId()
  local locId = INC.Data.ResolveLocation(caches, mapId, zoneId, areaId)
  reply(player, ("map=%d zone=%d area=%d  ->  location=%s")
    :format(mapId, zoneId, areaId, locId and ('%d (%s)'):format(locId, caches.Locations[locId].name) or "none"))
  if not locId then return end
  local px, py, pz = player:GetX(), player:GetY(), player:GetZ()
  local radius = INC.Config.MaxCandidateSearchRadius
  local shown = 0
  for guidLow, reg in pairs(INC.Registry.ForLocation(locId)) do
    local dx, dy, dz = reg.x - px, reg.y - py, reg.z - pz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    if dist <= radius then
      shown = shown + 1
      reply(player, ("  npc entry=%d guid=%d dist=%.1f"):format(reg.entry, guidLow, dist))
      if shown >= 10 then reply(player, "  ...(more)"); break end
    end
  end
  if shown == 0 then reply(player, "  no registry NPCs within search radius") end
end

local function cmdForce(player, args)
  -- args: [1]="inm" [2]="force" [3]="self"
  local selfOnly = args[3] == "self"
  local target = selfOnly and player:GetGUIDLow() or nil
  local reason = INC.Scheduler.RunAttempt(true, target)
  reply(player, "force -> " .. reason)
end

local function cmdStats(player)
  local m = INC.State.Metrics
  -- Fixed order so the readout is stable across calls.
  local order = {
    "EMITTED", "GLOBAL_COOLDOWN", "NO_ACTIVE_LOCATION", "LOCATION_COOLDOWN",
    "NO_ACTIVE_PLAYER", "PLAYER_COOLDOWN", "NO_NEARBY_NPC", "NPC_COOLDOWN",
    "NO_MATCHING_LINE", "GROUP_COOLDOWN", "LINE_COOLDOWN",
    "FINAL_VALIDATION_FAILED_PLAYER", "FINAL_VALIDATION_FAILED_NPC",
    "PHASE_MISMATCH", "LUA_ERROR",
  }
  reply(player, "metrics:")
  for _, k in ipairs(order) do
    reply(player, ("  %-30s %d"):format(k, m[k] or 0))
  end
end

local function cmdReload(player)
  local summary = INC.Reload()
  reply(player, "reloaded: " .. summary)
end

local function cmdDebug(player, args)
  local v = args[3]   -- args: [1]="inm" [2]="debug" [3]="on|off"
  if v == "on" then
    INC.Config.Debug = true
  elseif v == "off" then
    INC.Config.Debug = false
  else
    reply(player, "usage: .inm debug on|off")
    return
  end
  reply(player, "debug = " .. tostring(INC.Config.Debug))
end

local function handle(_, player, command)
  -- ALE passes player=nil for a command typed at the SERVER CONSOLE
  -- (handler.IsConsole()); we only act on in-game GMs, so let those fall through.
  if not player then return end
  local args = splitWords(command)
  if args[1] ~= "inm" then return end   -- not ours: let core handle it (return nothing)

  if not player:IsGM() or player:GetGMRank() < MIN_GM_RANK then
    reply(player, "insufficient permission")
    return false
  end

  local sub = args[2]
  if sub == "status" then cmdStatus(player)
  elseif sub == "where" then cmdWhere(player)
  elseif sub == "force" then cmdForce(player, args)
  elseif sub == "reload" then cmdReload(player)
  elseif sub == "stats" then cmdStats(player)
  elseif sub == "debug" then cmdDebug(player, args)
  elseif sub == "cooldown" and args[3] == "clear" then
    INC.Scheduler.ClearCooldowns()
    reply(player, "cooldowns cleared")
  else
    reply(player, "commands: status | where | force [self] | reload | cooldown clear | stats | debug on|off")
  end
  return false   -- consume: this was an .inm command
end

function INC.Commands.Init()
  -- ProtectRet (not Protect) so the handler's `false` return propagates to consume
  -- the command; on internal error it falls through to core untouched.
  RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, INC.ProtectRet("commands.onCommand", handle))
end
