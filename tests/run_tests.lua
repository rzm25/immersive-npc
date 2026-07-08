#!/usr/bin/env lua5.2
-- tests/run_tests.lua — pure-Lua unit tests (spec §10). Runs under standalone
-- lua5.2 with NO server: it only exercises the engine-free modules 01_inc_config
-- and 02_inc_util. Exits non-zero on any failure so CI fails loudly.
--
--   $ lua5.2 tests/run_tests.lua        (run from repo root)

local SCRIPTS = "scripts/inc/"

-- Load the engine-free modules into a shared INC (mirrors the one Lua state ALE uses).
INC = {}
dofile(SCRIPTS .. "01_inc_config.lua")
dofile(SCRIPTS .. "02_inc_util.lua")
local U = INC.Util

-- ---- tiny assert framework -------------------------------------------------
local passed, failed = 0, 0
local function ok(cond, name)
  if cond then passed = passed + 1
  else failed = failed + 1; io.write("  FAIL: " .. name .. "\n") end
end
local function eq(a, b, name)
  ok(a == b, name .. (a == b and "" or (" (got " .. tostring(a) .. ", want " .. tostring(b) .. ")")))
end

-- ---- 64-bit split-mask helpers (band / all-of / any-of across lo|hi) --------
do
  -- BitFor / SetBit64
  local lo, hi = U.BitFor(0);  eq(lo, 1, "BitFor(0).lo"); eq(hi, 0, "BitFor(0).hi")
  lo, hi = U.BitFor(31);       eq(lo, 2147483648, "BitFor(31).lo (0x80000000)"); eq(hi, 0, "BitFor(31).hi")
  lo, hi = U.BitFor(32);       eq(lo, 0, "BitFor(32).lo"); eq(hi, 1, "BitFor(32).hi (crosses boundary)")
  lo, hi = U.BitFor(40);       eq(lo, 0, "BitFor(40).lo"); eq(hi, 256, "BitFor(40).hi")
  lo, hi = U.SetBit64(0, 0, 3); lo, hi = U.SetBit64(lo, hi, 35)
  eq(lo, 8, "SetBit64 lo bit3"); eq(hi, 8, "SetBit64 hi bit3 (35-32)")

  -- Mask64Band
  local blo, bhi = U.Mask64Band(0xF, 0xF, 0x3, 0x9)
  eq(blo, 0x3, "Mask64Band.lo"); eq(bhi, 0x9, "Mask64Band.hi")

  -- MatchAll64 (item tags): req == 0 means no restriction
  ok(U.MatchAll64(0, 0, 0, 0), "AllOf: empty req always matches")
  ok(U.MatchAll64(0xA, 0, 0x2, 0), "AllOf: lo subset matches")
  ok(not U.MatchAll64(0xA, 0, 0x4, 0), "AllOf: missing lo bit fails")
  ok(U.MatchAll64(0x1, 0x8, 0x1, 0x8), "AllOf: both words required, present")
  ok(not U.MatchAll64(0x1, 0x8, 0x1, 0x10), "AllOf: hi bit missing fails (boundary)")
  ok(U.MatchAll64(0x0, 0x8, 0x0, 0x8), "AllOf: hi-only req present")
  ok(not U.MatchAll64(0x0, 0x8, 0x2, 0x8), "AllOf: lo bit required but absent (boundary)")

  -- MatchAny64 (roles): req == 0 means no restriction
  ok(U.MatchAny64(0, 0, 0, 0), "AnyOf: empty req always matches")
  ok(U.MatchAny64(0x0, 0x8, 0x0, 0x8), "AnyOf: hi bit overlaps")
  ok(not U.MatchAny64(0x0, 0x8, 0x0, 0x10), "AnyOf: no hi overlap")
  ok(not U.MatchAny64(0x0, 0x8, 0x1, 0x0), "AnyOf: lo req, only hi present -> no overlap")
  ok(U.MatchAny64(0x0, 0x8, 0x1, 0x8), "AnyOf: matches on hi even when lo differs (boundary)")

  -- MatchAny32 (class/race/team/location)
  ok(U.MatchAny32(0x4, 0), "AnyOf32: req 0 no restriction")
  ok(U.MatchAny32(0x4, 0x4), "AnyOf32: overlap")
  ok(not U.MatchAny32(0x4, 0x2), "AnyOf32: no overlap")
end

-- ---- weighted selection ----------------------------------------------------
do
  local items = { { w = 1 }, { w = 3 } }  -- total weight 4; a:1/4, b:3/4
  local function wof(x) return x.w end
  local function fixed(v) return function() return v end end
  eq(select(1, U.WeightedPick(items, 2, wof, fixed(0.0))), items[1], "weighted: r=0 -> a")
  eq(select(1, U.WeightedPick(items, 2, wof, fixed(0.24))), items[1], "weighted: r<0.25 -> a")
  eq(select(1, U.WeightedPick(items, 2, wof, fixed(0.25))), items[2], "weighted: r>=0.25 -> b")
  eq(select(1, U.WeightedPick(items, 2, wof, fixed(0.99))), items[2], "weighted: r~1 -> b")
  ok(U.WeightedPick(items, 0, wof, fixed(0.5)) == nil, "weighted: zero items -> nil")
  ok(U.WeightedPick({ { w = 0 } }, 1, wof, fixed(0.5)) == nil, "weighted: zero total weight -> nil")

  -- loose statistical check: ~3:1 split within tolerance
  math.randomseed(1234)
  local ca, cb = 0, 0
  for _ = 1, 20000 do
    local pick = U.WeightedPick(items, 2, wof, math.random)
    if pick == items[1] then ca = ca + 1 else cb = cb + 1 end
  end
  local ratio = cb / ca
  ok(ratio > 2.5 and ratio < 3.6, "weighted: ~3:1 distribution (got " .. string.format("%.2f", ratio) .. ")")
end

-- ---- token bucket ----------------------------------------------------------
do
  local b = U.NewBucket(2, 1000, 0)      -- capacity 2, full refill over 1000ms
  ok(U.BucketPeek(b, 0), "bucket: peek full")
  ok(U.BucketTryConsume(b, 0), "bucket: consume 1 (t=0)")
  ok(U.BucketTryConsume(b, 0), "bucket: consume 2 (t=0)")
  ok(not U.BucketTryConsume(b, 0), "bucket: empty -> deny")
  ok(not U.BucketPeek(b, 0), "bucket: peek empty")
  ok(U.BucketTryConsume(b, 500), "bucket: half-refilled by t=500 -> 1 token")
  ok(not U.BucketTryConsume(b, 500), "bucket: only 1 token available at t=500")
  ok(U.BucketTryConsume(b, 1000), "bucket: refilled to cap by t=1000")
  -- backwards-clock guard: must not error or over-refill
  U.BucketRefill(b, 200)
  ok(true, "bucket: backwards clock handled without error")
end

-- ---- population budget + clamp --------------------------------------------
do
  eq(U.PopulationPerMinute(0, 0.25, 0.20, 1.5), 0.25, "pop: 0 players -> base")
  local one = U.PopulationPerMinute(1, 0.25, 0.20, 1.5)
  ok(math.abs(one - 0.45) < 1e-9, "pop: 1 player -> base + scale (log2(2)=1)")
  eq(U.PopulationPerMinute(1000000, 0.25, 0.20, 1.5), 1.5, "pop: huge -> capped")
  eq(U.PopulationPerMinute(-5, 0.25, 0.20, 1.5), 0.25, "pop: negative clamps players to 0")
  eq(U.Clamp(100, 5, 60), 60, "clamp high")
  eq(U.Clamp(1, 5, 60), 5, "clamp low")
  eq(U.Clamp(30, 5, 60), 30, "clamp mid")
end

-- ---- placeholder replacement (incl. hostile input) -------------------------
do
  eq(U.ReplacePlaceholders("Hi {player}, nice {weapon_type}", { player = "Bob", weapon_type = "sword" }),
     "Hi Bob, nice sword", "placeholder: basic")
  eq(U.ReplacePlaceholders("gold {gold} here", { player = "Bob" }),
     "gold {gold} here", "placeholder: unknown token left verbatim")
  eq(U.ReplacePlaceholders("{evil}", { evil = "x" }),
     "{evil}", "placeholder: non-whitelisted key not substituted")
  -- hostile: '%' in the value must be inserted LITERALLY (function replacement),
  -- never interpreted as a gsub pattern capture. This is the injection-class test.
  eq(U.ReplacePlaceholders("promo: {player}", { player = "50%_off_%1%0" }),
     "promo: 50%_off_%1%0", "placeholder: % / %1 / %0 in value are literal")
  eq(U.ReplacePlaceholders("{player}", { player = "a{b}c" }),
     "a{b}c", "placeholder: braces in value do not re-expand")
  eq(U.ReplacePlaceholders("{player}", { player = "{race}", race = "orc" }),
     "{race}", "placeholder: single-pass, value not recursively expanded")
  -- UTF-8 value
  eq(U.ReplacePlaceholders("hail {player}", { player = "Ünïçödé" }),
     "hail Ünïçödé", "placeholder: UTF-8 value preserved")
  -- long string: must not error
  local long = string.rep("x", 10000)
  ok(#U.ReplacePlaceholders("{player}", { player = long }) == 10000, "placeholder: long value handled")
  -- non-string input passes through
  ok(U.ReplacePlaceholders(nil, {}) == nil, "placeholder: nil text passthrough")
end

-- ---- TruncateBytes ---------------------------------------------------------
do
  eq(U.TruncateBytes("hello", 255), "hello", "truncate: short unchanged")
  eq(U.TruncateBytes("abcdef", 3), "abc", "truncate: hard cut")
  -- multibyte: "é" is 2 bytes (0xC3 0xA9). Truncating to 3 bytes of "aé..." must
  -- not split the 'é' (should back off to "a").
  local s = "a" .. "\xC3\xA9" .. "\xC3\xA9"   -- a é é  (5 bytes)
  local t = U.TruncateBytes(s, 2)             -- would land mid-é -> back off to "a"
  eq(t, "a", "truncate: does not split a UTF-8 sequence")
end

-- ---- config clamp ----------------------------------------------------------
do
  INC.Config.SchedulerTickMs = 10
  INC.Config.PlayerCooldownMs = 5
  INC.Config.MaxCandidateSearchRadius = 100
  INC.Config.DefaultChatMode = 9
  INC.ClampConfig()
  eq(INC.Config.SchedulerTickMs, 1000, "clamp: tick floor 1000")
  eq(INC.Config.PlayerCooldownMs, 30000, "clamp: player cd floor 30000")
  eq(INC.Config.MaxCandidateSearchRadius, 60, "clamp: radius ceil 60")
  eq(INC.Config.DefaultChatMode, 0, "clamp: invalid chat mode -> 0")
end

-- ---- report ----------------------------------------------------------------
io.write(string.format("\n%d passed, %d failed\n", passed, failed))
os.exit(failed == 0 and 0 or 1)
