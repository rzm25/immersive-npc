-- 01_inc_config.lua — configuration table + clamping.
--
-- ALE/Eluna scripts have no .conf.dist; configuration is a plain Lua table, which
-- is an advantage: `.inm reload` re-reads it without a server restart. Key names
-- mirror the C++ module's config keys so an operator familiar with either feels at
-- home. NO engine calls at file scope (this file must load before events exist).
--
-- Load order: this is the first file (01_). It only defines data + a pure clamp
-- function; nothing here touches the engine.

INC = INC or {}

-- Shared logging shims (definitions only — no engine call at file scope). At
-- runtime PrintInfo/PrintError exist; under standalone lua5.2 (the unit harness)
-- they are nil, so we fall back to print(). Load summary + warnings always go out;
-- per-attempt traces only when Config.Debug is set.
function INC.Log(msg)
  local p = PrintInfo
  if p then p("[inm] " .. msg) else print("[inm] " .. msg) end
end

function INC.Warn(msg)
  local p = PrintError
  if p then p("[inm][WARN] " .. msg) else print("[inm][WARN] " .. msg) end
end

function INC.Err(msg)
  local p = PrintError
  if p then p("[inm][ERROR] " .. msg) else print("[inm][ERROR] " .. msg) end
end

function INC.DebugLog(msg)
  if INC.Config and INC.Config.Debug then INC.Log("[dbg] " .. msg) end
end

-- Wrap an event/heartbeat handler so a scripting bug degrades the feature instead of
-- spamming the console every tick (spec §4.4). Counts every failure in the LUA_ERROR
-- metric but logs the traceback only the FIRST time a given label fails.
function INC.Protect(label, fn)
  return function(...)
    local ok, err = xpcall(fn, debug.traceback, ...)
    if not ok then
      local st = INC.State
      if st then
        st.Metrics = st.Metrics or {}
        st.Metrics.LUA_ERROR = (st.Metrics.LUA_ERROR or 0) + 1
        st.loggedErrors = st.loggedErrors or {}
        if not st.loggedErrors[label] then
          st.loggedErrors[label] = true
          INC.Err(("%s (first error shown; further occurrences counted only):\n%s"):format(label, tostring(err)))
        end
      else
        INC.Err(label .. ": " .. tostring(err))
      end
    end
  end
end

-- Like INC.Protect but PROPAGATES the wrapped function's return values (up to two).
-- Used for PLAYER_EVENT_ON_COMMAND, whose handler must return false to consume the
-- command. Not used on the hot tick path, so its lack of alloc-avoidance is moot.
function INC.ProtectRet(label, fn)
  return function(...)
    local ok, a, b = xpcall(fn, debug.traceback, ...)
    if not ok then
      local st = INC.State
      if st then
        st.Metrics = st.Metrics or {}
        st.Metrics.LUA_ERROR = (st.Metrics.LUA_ERROR or 0) + 1
      end
      INC.Err(("%s: %s"):format(label, tostring(a)))
      return
    end
    return a, b
  end
end

INC.Config = {
  Enable = true,

  -- Heartbeat / global pacing
  SchedulerTickMs = 5000,            -- clamp >= 1000
  GlobalMinIntervalMs = 45000,       -- clamp >= 10000
  GlobalBurstMax = 2,                -- clamp 1..10
  GlobalBurstWindowMs = 180000,      -- token-bucket refill window for the global gate

  -- Per-location pacing DEFAULTS. NOTE: the authoritative per-city values are the
  -- `min_interval_ms` / `max_lines_per_10min` columns on immersive_npc_chat_location
  -- (edit those + `.inm reload` to tune a city). These two keys mirror the seed's DB
  -- defaults for operator familiarity and are not enforced at runtime.
  LocationMinIntervalMs = 120000,
  LocationMaxLinesPer10Min = 6,

  -- Per-entity cooldowns (memory-only; reset on reload/restart — documented in README)
  PlayerCooldownMs = 300000,         -- clamp >= 30000
  NpcCooldownMs = 600000,            -- clamp >= 30000
  LineCooldownMs = 3600000,
  CooldownGroupMs = 900000,

  -- Candidate search / emission geometry
  MaxCandidateSearchRadius = 24.0,   -- clamp 5..60
  RequireLineOfSight = false,
  RequireNpcFacingPlayer = false,

  -- Population-scaled per-location budget (see 02_inc_util.PopulationPerMinute)
  PopulationScaling = { Enable = true, BasePerMinute = 0.25, LogScale = 0.20, MaxPerMinute = 1.50 },

  -- Emission defaults
  DefaultChatMode = 0,               -- 0 say, 1 whisper, 2 emote
  AllowPersonalWhispers = true,

  -- Diagnostics
  Debug = false,
  DebugToConsole = true,
  DebugToGM = false,
}

-- Clamp a numeric value into [lo, hi]. Pure; safe for the unit harness.
local function clampNum(v, lo, hi, default)
  if type(v) ~= "number" then v = default end
  if lo and v < lo then v = lo end
  if hi and v > hi then v = hi end
  return v
end

-- Re-clamp INC.Config in place. Called at boot, on `.inm reload`, and on
-- WORLD_EVENT_ON_CONFIG_LOAD. Idempotent: safe to call repeatedly. Pure w.r.t. the
-- engine (only reads/writes the config table), so the harness can exercise it.
function INC.ClampConfig()
  local c = INC.Config
  c.SchedulerTickMs        = clampNum(c.SchedulerTickMs, 1000, nil, 5000)
  c.GlobalMinIntervalMs    = clampNum(c.GlobalMinIntervalMs, 10000, nil, 45000)
  c.GlobalBurstMax         = clampNum(c.GlobalBurstMax, 1, 10, 2)
  c.GlobalBurstWindowMs    = clampNum(c.GlobalBurstWindowMs, 1000, nil, 180000)
  c.LocationMinIntervalMs  = clampNum(c.LocationMinIntervalMs, 1000, nil, 120000)
  c.LocationMaxLinesPer10Min = clampNum(c.LocationMaxLinesPer10Min, 0, nil, 6)
  c.PlayerCooldownMs       = clampNum(c.PlayerCooldownMs, 30000, nil, 300000)
  c.NpcCooldownMs          = clampNum(c.NpcCooldownMs, 30000, nil, 600000)
  c.LineCooldownMs         = clampNum(c.LineCooldownMs, 0, nil, 3600000)
  c.CooldownGroupMs        = clampNum(c.CooldownGroupMs, 0, nil, 900000)
  c.MaxCandidateSearchRadius = clampNum(c.MaxCandidateSearchRadius, 5.0, 60.0, 24.0)

  local p = c.PopulationScaling
  if type(p) == "table" then
    p.BasePerMinute = clampNum(p.BasePerMinute, 0, nil, 0.25)
    p.LogScale      = clampNum(p.LogScale, 0, nil, 0.20)
    p.MaxPerMinute  = clampNum(p.MaxPerMinute, 0, nil, 1.50)
  end

  if c.DefaultChatMode ~= 0 and c.DefaultChatMode ~= 1 and c.DefaultChatMode ~= 2 then
    c.DefaultChatMode = 0
  end
  return c
end
