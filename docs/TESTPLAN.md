# TESTPLAN — test matrix with pass/fail per build

A phase is not done until its tests pass (spec §10). Two tiers: **offline** (runnable in
the dev sandbox / CI, done) and **in-game** (owner runs on the live server, pending).

## Offline — DONE (build 2026-07-07)

| Test | How | Result |
|---|---|---|
| Lint: no implicit globals | `luacheck scripts/inc tests .luacheckrc` | ✅ 0 warnings, 11 files |
| Unit: split-mask band/all-of/any-of across lo\|hi boundary | `tests/run_tests.lua` | ✅ |
| Unit: weighted selection (deterministic + ~3:1 distribution) | `tests/run_tests.lua` | ✅ |
| Unit: token bucket refill/consume/peek + backwards-clock guard | `tests/run_tests.lua` | ✅ |
| Unit: population budget + clamp | `tests/run_tests.lua` | ✅ |
| Unit: placeholder replace incl. hostile input (`%`, `%1`, `{}`, UTF-8, 10k) | `tests/run_tests.lua` | ✅ (66 total) |
| Unit: UTF-8-safe truncate; config clamp | `tests/run_tests.lua` | ✅ |
| Integration: boot loads caches, hooks entries, starts heartbeat | `tests/integration_mock.lua` | ✅ |
| Integration: login/logout tracking + location membership | `tests/integration_mock.lua` | ✅ |
| Integration: lazy scan reflects current gear (tags + quality + weapon_type) | `tests/integration_mock.lua` | ✅ |
| Integration: forced emit → placeholders replaced → say/whisper dispatched | `tests/integration_mock.lua` | ✅ |
| Integration: player/npc/line cooldown blocks forced repeat; `cooldown clear` restores | `tests/integration_mock.lua` | ✅ |
| Integration: final validation rejects combat / far / phase-mismatch | `tests/integration_mock.lua` | ✅ |
| Integration: whisper honors `AllowPersonalWhispers`; ON_REMOVE deregisters | `tests/integration_mock.lua` | ✅ |
| Integration: `.inm reload` swaps content atomically, registry untouched | `tests/integration_mock.lua` | ✅ (41 total) |
| Integration: `WORLD_EVENT_ON_UPDATE` (13) never registered | `tests/integration_mock.lua` | ✅ |
| SQL: structural checker self-test (must be able to fail) | `tools/check_sql_selftest.py` | ✅ 5/5 |
| SQL: schema + seeds structurally clean; real MySQL apply + idempotency | `tools/check_sql.py` + CI `sql` job | ✅ local; CI on push |

> The integration harness stubs the engine API *contract* verified against S1; it proves
> the Lua logic is internally consistent end-to-end, **not** that the live server behaves
> identically. That gap is closed only by the in-game matrix below.

## In-game — PENDING (owner runs; record pass/fail here)

| # | Test (spec §10) | Steps | Pass? |
|---|---|---|---|
| 1 | Cold start + `.inm reload` | boot; check summary line; feed a malformed row, confirm warned+skipped, no Lua errors | ☐ |
| 2 | `.inm where` in all six hubs + one unsupported zone | walk each; confirm location + nearby registry NPCs; unsupported → "location=none" | ☐ |
| 3 | `.inm force` across ≥6 race/class/weapon combos; **gear swap reflected with no relog** | swap a weapon, `.inm force self` seconds later, confirm the new `{weapon_type}`/tags matched (validates ADR-001) | ☐ |
| 4 | Cooldowns block forced repeats (player/NPC/line/group); `cooldown clear` restores | `.inm force self` twice → 2nd blocked; `.inm cooldown clear`; force again → emits | ☐ |
| 5 | Lifecycle abuse: logout, teleport, hearth, death+corpse run, taxi, instance in/out, GM-invisible | drive each; confirm no emission mid-transition, no dangling-userdata errors | ☐ |
| 6 | Grid churn: leave city until grids unload, return | `.inm status` registry counts fall then recover | ☐ |
| 7 | Engine script reload mid-activity | reload; state rebuilds; `.inm status` sane; no duplicate/orphaned heartbeat | ☐ |
| L1 | Load: 1/10/50 in one hub, 100 split; spam-swap gear (should cost nothing) | watch `.inm stats` vs wall clock; emissions never exceed caps | ☐ |
| L2 | No world-update regression | compare `server info` timings with feature on/off | ☐ |
| L3 | Zero DB queries steady-state | MySQL general log over 10 min after boot/reload → no module queries | ☐ |
| L4 | 30-min populated-hub soak reads as rare-and-neat | observe; no spam; tune pacing via `.inm reload` | ☐ |

### How to drive the in-game tests
- Be a GM of rank ≥ 2. Commands: `.inm status | where | force [self] | reload | cooldown clear | stats | debug on|off`.
- `.inm debug on` logs each attempt's outcome; `.inm stats` shows the failure-reason counters (the tuning instrument, spec §8).
- If a hub never speaks: `.inm where` there — if no registry NPCs, the guard entry is wrong (fix via `sql/verify_ids.sql`) or the zone id is wrong (fix the location row after `.gps`).
