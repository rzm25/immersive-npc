-- 08_inc_main.lua — boot orchestration. Loads last (08_). Wires everything, prints
-- the load summary, and starts the heartbeat.
--
-- Events verified against ALE src/LuaEngine/Hooks.h (azerothcore/mod-ale, see SOURCES.md):
--   WORLD_EVENT_ON_CONFIG_LOAD        = 9   (survive worldserver `.reload config`)
--   ALE_EVENT_ON_LUA_STATE_CLOSE      = 16  (cancel the heartbeat on state teardown)
--
-- Boot runs at file scope: ALE executes script files when the Lua state opens (after
-- the world DB is up), and re-executes them on `.reload ale` — which tears the whole
-- state down first, so no CreateLuaEvent timer is ever orphaned across a reload
-- (TESTPLAN matrix 7). We also TrackOnline() at boot so a `.reload ale` re-tracks
-- already-connected players (ALE reloads fire no login event for them). `.inm reload`
-- is the lighter path: it swaps caches + re-clamps config only, never re-registering
-- events or the timer.

INC = INC or {}

INC.VERSION = "1.0.0"
INC.ENGINE = "ALE (azerothcore/mod-ale) — see docs/SOURCES.md for the pinned commit"

local WORLD_EVENT_ON_CONFIG_LOAD = 9
local ALE_EVENT_ON_LUA_STATE_CLOSE = 16

local function summary()
  local s = INC.Caches.Stats
  return ("%d locations, %d profiled entries (%d profiles), %d lines, %d skipped")
    :format(s.locations, s.profiledEntries or 0, s.profiles, s.lines, s.skipped)
end

-- Rebuild caches from the DB and re-clamp config (the `.inm reload` path). Atomic:
-- the new caches are built completely, THEN swapped in with one assignment, so the
-- old cache stays live until the instant of replacement (spec §7). Does NOT touch
-- event registrations or the heartbeat timer. Returns a one-line summary.
function INC.Reload()
  INC.ClampConfig()
  local newCaches = INC.Data.Load()
  INC.Caches = newCaches
  return summary()
end

function INC.Boot()
  INC.State = {}
  -- Seed the RNG so line/NPC selection varies across restarts. GetGameTime() is a
  -- LongLong *userdata* on ALE (randomseed needs a number), so use os.time() unless
  -- GetGameTime happens to be a plain number (the test harness).
  local seed = GetGameTime()
  if type(seed) ~= "number" then seed = os.time() end
  math.randomseed(seed)
  INC.ClampConfig()
  INC.Caches = INC.Data.Load()

  INC.Scheduler.Init()   -- Metrics + buckets + heartbeat first (Protect needs Metrics)
  local profiledN = INC.Registry.Init()
  INC.Players.Init()
  INC.Commands.Init()
  local onlineN = INC.Players.TrackOnline()      -- 0 at startup; re-tracks players on `.reload ale`
  local seededN = INC.Registry.SeedFromPlayers() -- 0 at startup (ON_ADD covers grids); fills registry on `.reload ale`

  RegisterServerEvent(WORLD_EVENT_ON_CONFIG_LOAD, INC.Protect("main.onConfigLoad", function()
    INC.ClampConfig()
  end))
  RegisterServerEvent(ALE_EVENT_ON_LUA_STATE_CLOSE, INC.Protect("main.onStateClose", function()
    if INC.schedulerEventId then RemoveEventById(INC.schedulerEventId) end
  end))

  INC.State.booted = true
  INC.Log(("v%s loaded: %s | entries hooked=%d | online=%d | registry seeded=%d | tick=%dms | engine=%s")
    :format(INC.VERSION, summary(), profiledN, onlineN, seededN, INC.Config.SchedulerTickMs, INC.ENGINE))
end

INC.Boot()
