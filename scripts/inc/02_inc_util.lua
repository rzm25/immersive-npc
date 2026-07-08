-- 02_inc_util.lua — pure helpers + the ONE authoritative definition of every bit
-- constant. THIS FILE MUST STAY ENGINE-FREE (no Register*/WorldDBQuery/Get* calls,
-- directly or transitively) so `tests/run_tests.lua` runs it under standalone
-- lua5.2 (spec §10). Only the Lua 5.2 standard library is allowed here.
--
-- 64-bit note (spec §4.2): Lua 5.2 `bit32` is 32-bit only. Masks that can exceed 32
-- bits (item tags, NPC role masks) are split into `lo` (bits 0..31) and `hi`
-- (bits 32..51) uint32 words, mirrored as `*_lo`/`*_hi` SQL columns. NEVER use more
-- than 52 usable bits anywhere (bit 51 is the ceiling) — Lua numbers are doubles and
-- bit32 output above 2^32 is undefined; we keep each word within one uint32.

INC = INC or {}
INC.Util = INC.Util or {}
local U = INC.Util

local band, lshift = bit32.band, bit32.lshift
local floor, log, min, max = math.floor, math.log, math.min, math.max

-- ---------------------------------------------------------------------------
-- Bit constants — defined ONCE here, mirrored as a comment block in the base SQL.
-- ---------------------------------------------------------------------------

-- chat_mode column values.
INC.ChatMode = { SAY = 0, WHISPER = 1, EMOTE = 2 }

-- team_mask (ANY-of, uint32). 0 = no restriction.
INC.Team = { ALLIANCE = 0x1, HORDE = 0x2 }

-- class_mask (ANY-of, uint32). Bit = 1 << (classId - 1), matching Blizzard ClassMask.
INC.Class = {
  WARRIOR = lshift(1, 0), PALADIN = lshift(1, 1), HUNTER = lshift(1, 2),
  ROGUE   = lshift(1, 3), PRIEST  = lshift(1, 4), DEATHKNIGHT = lshift(1, 5),
  SHAMAN  = lshift(1, 6), MAGE    = lshift(1, 7), WARLOCK = lshift(1, 8),
  DRUID   = lshift(1, 10),
}

-- race_mask (ANY-of, uint32). Bit = 1 << (raceId - 1), matching Blizzard RaceMask.
INC.Race = {
  HUMAN    = lshift(1, 0), ORC      = lshift(1, 1), DWARF   = lshift(1, 2),
  NIGHTELF = lshift(1, 3), UNDEAD   = lshift(1, 4), TAUREN  = lshift(1, 5),
  GNOME    = lshift(1, 6), TROLL    = lshift(1, 7), BLOODELF = lshift(1, 9),
  DRAENEI  = lshift(1, 10),
}

-- NPC role tags (author-assigned per profile) — role_mask_lo/hi, ANY-of, split-64.
-- Bit POSITIONS (0..51). v1 uses only lo-word positions (< 32).
INC.RolePos = {
  GUARD = 0, INNKEEPER = 1, VENDOR = 2, TRAINER = 3, BANKER = 4, AUCTIONEER = 5,
  FLIGHTMASTER = 6, CITIZEN = 7, OFFICIAL = 8, CRIER = 9, BARTENDER = 10,
  COOK = 11, BLACKSMITH = 12, GUILD_MASTER = 13, STABLE_MASTER = 14, WATCH = 15,
}

-- Equipment-derived item tags — required_item_tags_lo/hi, ALL-of, split-64.
-- Bit POSITIONS (0..51). v1 uses only lo-word positions (< 32).
INC.ItemTagPos = {
  HAS_WEAPON = 0, HAS_TWO_HAND = 1, HAS_SHIELD = 2, HAS_RANGED = 3,
  PLATE = 4, MAIL = 5, LEATHER = 6, CLOTH = 7,
  SWORD = 8, AXE = 9, MACE = 10, POLEARM = 11, DAGGER = 12, STAFF = 13, FIST = 14,
  BOW = 15, GUN = 16, CROSSBOW = 17, WAND = 18, TABARD = 19, OFFHAND_FRILL = 20,
}

-- Item quality (min_item_quality column): 0 poor .. 5 legendary .. 7 heirloom.
INC.Quality = { POOR = 0, COMMON = 1, UNCOMMON = 2, RARE = 3, EPIC = 4, LEGENDARY = 5, ARTIFACT = 6, HEIRLOOM = 7 }

-- ---------------------------------------------------------------------------
-- 64-bit split-mask helpers (spec §4.2). lo/hi are each a uint32.
-- ---------------------------------------------------------------------------

-- Build a {lo,hi} bit from a 0..51 position.
function U.BitFor(pos)
  if pos < 32 then return lshift(1, pos), 0 end
  return 0, lshift(1, pos - 32)
end

-- OR a 0..51 position into an existing lo/hi pair. Returns new lo,hi.
function U.SetBit64(lo, hi, pos)
  local blo, bhi = U.BitFor(pos)
  return bit32.bor(lo, blo), bit32.bor(hi, bhi)
end

-- Bitwise AND of two split masks. Returns lo,hi.
function U.Mask64Band(alo, ahi, blo, bhi)
  return band(alo, blo), band(ahi, bhi)
end

function U.Mask64IsZero(lo, hi)
  return lo == 0 and hi == 0
end

-- ALL-of: does `have` contain every bit of `req`? (req == 0 => no restriction, true.)
-- Used for item-tag matching (spec §4.2).
function U.MatchAll64(haveLo, haveHi, reqLo, reqHi)
  return band(haveLo, reqLo) == reqLo and band(haveHi, reqHi) == reqHi
end

-- ANY-of over a split mask (req == 0 => no restriction, true).
function U.MatchAny64(haveLo, haveHi, reqLo, reqHi)
  if reqLo == 0 and reqHi == 0 then return true end
  return band(haveLo, reqLo) ~= 0 or band(haveHi, reqHi) ~= 0
end

-- ANY-of over a single uint32 (req == 0 => no restriction, true).
-- Used for class/race/team/location masks (spec §4.2).
function U.MatchAny32(haveBits, reqMask)
  if reqMask == 0 then return true end
  return band(haveBits, reqMask) ~= 0
end

-- ---------------------------------------------------------------------------
-- Numeric helpers
-- ---------------------------------------------------------------------------

function U.Clamp(v, lo, hi)
  if type(v) ~= "number" then return lo end
  if lo and v < lo then return lo end
  if hi and v > hi then return hi end
  return v
end

-- Population-scaled per-minute budget (spec §4.6):
--   clamp(base + log2(players+1) * scale, 0, cap)
function U.PopulationPerMinute(players, base, scale, cap)
  if players < 0 then players = 0 end
  local v = base + (log(players + 1) / log(2)) * scale
  return U.Clamp(v, 0, cap)
end

-- ---------------------------------------------------------------------------
-- Token bucket (memory-only). `capacity` tokens refill fully over refillWindowMs.
-- nowMs is injected so this is pure and unit-testable.
-- ---------------------------------------------------------------------------

function U.NewBucket(capacity, refillWindowMs, nowMs)
  return { tokens = capacity, capacity = capacity, refillWindowMs = refillWindowMs, lastMs = nowMs }
end

function U.BucketRefill(b, nowMs)
  if nowMs <= b.lastMs then
    if nowMs < b.lastMs then b.lastMs = nowMs end  -- clock moved backwards: re-anchor
    return
  end
  local rate = b.capacity / b.refillWindowMs   -- tokens per ms
  b.tokens = min(b.capacity, b.tokens + (nowMs - b.lastMs) * rate)
  b.lastMs = nowMs
end

-- Refill then report whether at least one token is available, WITHOUT consuming.
-- Used to gate an attempt cheaply before we know it will succeed.
function U.BucketPeek(b, nowMs)
  U.BucketRefill(b, nowMs)
  return b.tokens >= 1
end

-- Try to spend `cost` (default 1) tokens at nowMs. Returns true if spent.
function U.BucketTryConsume(b, nowMs, cost)
  cost = cost or 1
  U.BucketRefill(b, nowMs)
  if b.tokens >= cost then
    b.tokens = b.tokens - cost
    return true
  end
  return false
end

-- ---------------------------------------------------------------------------
-- Weighted selection. `items[1..nItems]`; weightOf(item) -> non-negative weight;
-- rnd() -> float in [0,1). `rnd` and `nItems` are injectable so callers can reuse a
-- scratch array (no per-tick allocation — spec §11) and tests stay deterministic.
-- Returns chosen item, index — or nil if total weight <= 0.
-- ---------------------------------------------------------------------------

function U.WeightedPick(items, nItems, weightOf, rnd)
  local total = 0
  for i = 1, nItems do
    local w = weightOf(items[i]) or 0
    if w > 0 then total = total + w end
  end
  if total <= 0 then return nil end
  local r = rnd() * total
  local acc = 0
  for i = 1, nItems do
    local w = weightOf(items[i]) or 0
    if w > 0 then
      acc = acc + w
      if r < acc then return items[i], i end
    end
  end
  return items[nItems], nItems  -- float-rounding safety net
end

-- ---------------------------------------------------------------------------
-- Placeholder substitution. Whitelist ONLY. Values are inserted via a gsub
-- *function* replacement, which Lua treats literally — so `%`, `{`, patterns, or
-- any hostile character in a value is NOT interpreted (injection-safe by design,
-- spec §9). Unknown/absent tokens are left verbatim.
-- ---------------------------------------------------------------------------

local PLACEHOLDER_WHITELIST = { player = true, class = true, race = true, weapon_type = true }

function U.ReplacePlaceholders(text, repl)
  if type(text) ~= "string" then return text end
  repl = repl or {}
  return (text:gsub("{([%w_]+)}", function(key)
    if PLACEHOLDER_WHITELIST[key] and repl[key] ~= nil then
      return tostring(repl[key])
    end
    return nil  -- keep the original "{key}" untouched
  end))
end

-- Truncate a UTF-8-ish string to at most maxChars bytes without splitting a
-- multibyte sequence (best-effort; content is authored <= ~110 chars anyway).
function U.TruncateBytes(s, maxBytes)
  if #s <= maxBytes then return s end
  local cut = maxBytes
  -- back off if we landed in the middle of a UTF-8 continuation byte (0x80..0xBF)
  while cut > 0 do
    local b = s:byte(cut + 1)
    if not b or b < 0x80 or b >= 0xC0 then break end
    cut = cut - 1
  end
  return s:sub(1, cut)
end

U.floor = floor  -- re-export for callers that want the localized version
U.max = max
