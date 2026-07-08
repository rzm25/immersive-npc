-- luacheck configuration for lua-immersive-npc-chat (ALE / Eluna, Lua 5.2)
-- Spec §11: "No global leakage: everything under INC.*; local everywhere else."
-- The ONLY writable global is INC (the module namespace). Everything the Eluna
-- engine injects is declared read-only here so an accidental typo that shadows an
-- engine function, or a stray implicit global, fails the lint.

std = "lua52"
max_line_length = 140

-- INC is the single shared namespace across all scripts in the one Lua state.
globals = { "INC" }

-- Eluna/ALE engine API used by this module. Verified against the S1 pin
-- (ElunaLuaEngine/Eluna @ e36707d — see docs/SOURCES.md). Read-only: scripts call
-- them but must never reassign them.
read_globals = {
  "RegisterPlayerEvent",
  "RegisterCreatureEvent",
  "RegisterServerEvent",
  "CreateLuaEvent",
  "RemoveEventById",
  "WorldDBQuery",
  "GetPlayerByGUID",
  "GetPlayersInWorld",
  "GetGameTime",
  "PrintInfo",
  "PrintError",
}

-- The pure-logic module and its tests must remain engine-free so they run under
-- standalone lua5.2 (spec §10). Forbid the engine globals there to enforce it.
files["scripts/inc/02_inc_util.lua"] = {
  read_globals = {},
}
-- The pure unit tests must not touch the engine at all.
files["tests/run_tests.lua"] = {
  read_globals = {},
  globals = { "INC" },
}
-- The integration harness DEFINES stub engine globals, so it may write them. Its
-- fake object methods intentionally ignore `self`/args, so don't flag those.
files["tests/integration_mock.lua"] = {
  unused_args = false,
  globals = {
    "INC", "PrintInfo", "PrintError", "GetGameTime", "WorldDBQuery",
    "RegisterPlayerEvent", "RegisterCreatureEvent", "RegisterServerEvent",
    "CreateLuaEvent", "RemoveEventById", "GetPlayerByGUID",
  },
}
