-- 08_inc_main.lua — boot orchestration. Loads last (08_). Wires everything, prints
-- the load summary, and starts the heartbeat.
--
-- Events verified against S1 pin (Hooks.h @ e36707d):
--   WORLD_EVENT_ON_CONFIG_LOAD        = 9   (survive worldserver `.reload config`)
--   ELUNA_EVENT_ON_LUA_STATE_CLOSE    = 16  (cancel the heartbeat on state teardown)
--
-- Boot runs at file scope: Eluna executes script files when the Lua state opens
-- (after the world DB is up), and re-executes them on an engine reload — which tears
-- the whole state down first, so no CreateLuaEvent timer is ever orphaned across an
-- engine reload (TESTPLAN matrix 7). `.inm reload` is the lighter path: it swaps
-- caches + re-clamps config only, and never re-registers events or the timer.

INC = INC or {}

INC.VERSION = "1.0.0"
INC.ENGINE = "Eluna (ElunaAzerothcore) — see docs/SOURCES.md for the pinned commit"

local WORLD_EVENT_ON_CONFIG_LOAD = 9
local ELUNA_EVENT_ON_LUA_STATE_CLOSE = 16

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
  -- Seed the RNG from engine time so line/NPC selection varies across restarts
  -- (unseeded math.random repeats the same sequence every boot).
  math.randomseed(GetGameTime())
  INC.ClampConfig()
  INC.Caches = INC.Data.Load()

  INC.Scheduler.Init()   -- Metrics + buckets + heartbeat first (Protect needs Metrics)
  local profiledN = INC.Registry.Init()
  INC.Players.Init()
  INC.Commands.Init()

  RegisterServerEvent(WORLD_EVENT_ON_CONFIG_LOAD, INC.Protect("main.onConfigLoad", function()
    INC.ClampConfig()
  end))
  RegisterServerEvent(ELUNA_EVENT_ON_LUA_STATE_CLOSE, INC.Protect("main.onStateClose", function()
    if INC.schedulerEventId then RemoveEventById(INC.schedulerEventId) end
  end))

  INC.State.booted = true
  INC.Log(("v%s loaded: %s | profiledEntries hooked=%d | tick=%dms | engine=%s")
    :format(INC.VERSION, summary(), profiledN, INC.Config.SchedulerTickMs, INC.ENGINE))
end

INC.Boot()
