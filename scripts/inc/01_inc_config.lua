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

  -- Heartbeat.
  SchedulerTickMs = 3000,            -- clamp >= 1000 (how often the per-player sweep runs)

  -- PER-PLAYER emission model (spec v2). Each player is paced INDIVIDUALLY, not the
  -- server as a whole, so a busy hub can greet 250 arrivals while each of them still
  -- hears a line only rarely. On entering a hub a player is due immediately (arrival
  -- line); after each line their next line is delayed by an ESCALATING gap indexed by
  -- how many they've already heard this visit (the last value repeats). So: line on
  -- arrival, then ~30s, then ~2.5m, then ~5m, then ~10m — quieting a lingerer down.
  PlayerCadenceMs = { 30000, 150000, 300000, 600000 },
  RetryBackoffMs = 4000,             -- if a due player has no nearby speakable NPC yet, recheck this soon
                                     -- (so "walk up to an NPC -> line within a few seconds")
  MaxEmitsPerTick = 25,              -- hot-path budget: cap emissions per heartbeat (bounds mass-arrival cost)

  -- Anti-repeat cooldowns (memory-only; reset on reload/restart).
  NpcCooldownMs = 90000,             -- one NPC won't speak again this soon (kept low so a guard can greet a stream of passers-by)
  LineCooldownMs = 1800000,          -- a given player won't hear the SAME line again this soon
  CooldownGroupMs = 600000,          -- ...nor the same category (cooldown_group) this soon

  -- Candidate search / emission geometry
  MaxCandidateSearchRadius = 30.0,   -- clamp 5..60 (how close counts as "near an NPC")
  RequireLineOfSight = false,
  RequireNpcFacingPlayer = false,

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
  c.SchedulerTickMs        = clampNum(c.SchedulerTickMs, 1000, nil, 3000)
  c.RetryBackoffMs         = clampNum(c.RetryBackoffMs, 1000, nil, 4000)
  c.MaxEmitsPerTick        = clampNum(c.MaxEmitsPerTick, 1, 500, 25)
  c.NpcCooldownMs          = clampNum(c.NpcCooldownMs, 5000, nil, 90000)
  c.LineCooldownMs         = clampNum(c.LineCooldownMs, 0, nil, 1800000)
  c.CooldownGroupMs        = clampNum(c.CooldownGroupMs, 0, nil, 600000)
  c.MaxCandidateSearchRadius = clampNum(c.MaxCandidateSearchRadius, 5.0, 60.0, 30.0)

  -- PlayerCadenceMs: ascending array of gap-ms between a player's successive lines.
  -- Default if missing/empty (the operator's skip-worktree'd config may predate this
  -- key); otherwise floor each entry at 0. Never mutate the engine here — pure table work.
  local cad = c.PlayerCadenceMs
  if type(cad) ~= "table" or #cad == 0 then
    c.PlayerCadenceMs = { 30000, 150000, 300000, 600000 }
  else
    for i = 1, #cad do cad[i] = clampNum(cad[i], 0, nil, 30000) end
  end

  if c.DefaultChatMode ~= 0 and c.DefaultChatMode ~= 1 and c.DefaultChatMode ~= 2 then
    c.DefaultChatMode = 0
  end
  return c
end
