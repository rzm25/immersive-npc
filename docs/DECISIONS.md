# DECISIONS — append-only ADR log

Every deviation from the build spec, and every non-obvious engineering choice, is
recorded here with date, decision, alternatives, and reason (spec §2). Newest at the
bottom.

---

## ADR-001 — Equipment context is a lazy scan, never cached (2026-07-07)
**Decision.** Do not cache equipment. When the scheduler selects a player, walk that
one player's 19 equipment slots on the spot and build `itemTags` + max visible quality.
**Alternatives.** An incremental cache driven by `PLAYER_EVENT_ON_EQUIP`.
**Reason.** Verified against S1: there is **no** player unequip / visible-slot event
(only `ON_EQUIP=29`). An `ON_EQUIP`-driven cache silently goes stale on unequip. The
scan is ~19 method calls at ≤1–2 attempts/min globally — trivial — and always correct.
We also deliberately do **not** register `ON_EQUIP`, so a client spam-swapping gear
costs the server nothing. (Spec §4.5.)

## ADR-002 — Millisecond clock is `GetGameTime()*1000`, not `getMSTime()` (2026-07-07)
**Decision.** `INC.NowMs()` returns `GetGameTime() * 1000`.
**Alternatives.** Eluna's `GetCurrTime()` (wraps `getMSTime()`), or `os.time()`.
**Reason.** `getMSTime()` is a uint32 that wraps every ~49.7 days of uptime, which
would corrupt cooldown/expiry comparisons on a long-lived server. `GetGameTime()` is
int64 epoch seconds — monotonic, never wraps. Second granularity is fine: the tick is
5000 ms and the smallest cooldown is 30 s. `os.time()` was rejected because it is wall
clock (can jump) and not the engine's notion of time.

## ADR-003 — Target engine is upstream Eluna (ElunaAzerothcore), not the spec's `mod-eluna`/ALE (2026-07-07)
**Decision.** Pin and verify against `ElunaLuaEngine/Eluna` (submodule of
`ElunaLuaEngine/ElunaAzerothcore`); treat that as the engine.
**Alternatives.** The spec's named `azerothcore/mod-eluna` ("ALE").
**Reason.** `azerothcore/mod-eluna` does not resolve (404 as of 2026-07-07); the
AzerothCore-org Eluna module `azerothcore/mod-eluna-lua-engine` is archived (2022). The
live, maintained AzerothCore Eluna is `ElunaLuaEngine/ElunaAzerothcore`. Crucially,
**every event ID the spec listed matches upstream Eluna's `Hooks.h` exactly**, so the
"diverged, scripts not interchangeable" claim — whatever its history — does not affect
the surface this module uses. The spec's own §1 mandates deciding the engine ONCE and
pinning it; this is that decision. **Caveat:** the owner must still confirm what their
server actually builds (S1 is UNVERIFIED for this server — see SOURCES.md).

## ADR-004 — Population budget realized as a per-location token bucket with a dynamic window (2026-07-07)
**Decision.** Each location has a capacity-2 token bucket (spec §4.6). Before gating,
its refill window is set to `capacity * 60000 / perMinute`, where `perMinute =
clamp(base + log2(players+1)*scale, 0, cap)`. Location choice among eligible locations
is **uniform** (population gates the RATE, not the choice — otherwise busy hubs would be
double-counted).
**Alternatives.** A fixed second bucket; or weighting location choice by population.
**Reason.** Matches spec §4.6 ("per-location token bucket under the global bucket")
while keeping the rate correctly population-scaled and the choice unbiased.

## ADR-005 — enUS-only in v1 (2026-07-07)
**Decision.** Keep the `locale` column; load only `enUS` rows. (Spec §4.8.)
**Reason.** Localisation is a content concern deferred past v1; the schema already
supports it.

## ADR-006 — `chat_mode = 2` (emote) supports both animation and text emote (2026-07-07)
**Decision.** For an emote line, if `text` is purely numeric → `PerformEmote(tonumber)`
(an animation id); otherwise → `SendUnitEmote(text)` (a visible text emote).
**Reason.** The spec mentions `PerformEmote` for emote mode, but a *text* emote reads as
more immersive chat. Supporting both (disambiguated by whether the text is a number)
covers each interpretation with one column and no schema change. Seed content uses text
emotes.

## ADR-007 — `.inm reload` does not re-register creature events (2026-07-07)
**Decision.** `.inm reload` swaps caches + re-clamps config atomically, but does not
re-run event registration or recreate the heartbeat. Adding a brand-new profiled
creature **entry** requires a full engine script reload.
**Alternatives.** Diff the profiled-entry set on reload and register/unregister deltas.
**Reason.** Eluna cannot cleanly unregister a single creature event, and re-registering
risks double-firing. Changing a profile's *attributes* (role/distance/personal flag) or
its *lines/locations* IS picked up live, because the registry stores only identity +
position and re-resolves the profile from the swapped cache at emission. Only the set of
hooked entries is fixed at boot. This matches how a C++ module behaves (new hooks need a
restart) and is documented as a known limitation in README.

## ADR-008 — Chest slot determines the armor "material" tag (2026-07-07)
**Decision.** The player's armor-material item tag (PLATE/MAIL/LEATHER/CLOTH) is derived
from the **chest** slot only; weapon/shield/ranged/tabard tags come from their own slots.
**Reason.** A character wears mixed armor subclasses (a plate wearer often has a cloth
cloak). The chest piece is the reliable signal of a character's armor class, avoiding
false material tags.
