# PROGRESS — phase checklist

Updated every session. v1 = Phases 1–6. Phases 7 (v2) and 8 (v3) are future milestones.

## Status: v1 code-complete, offline-verified. Awaiting in-game validation on the owner's server.

| Phase | Goal | State | Evidence |
|---|---|---|---|
| 1 | Skeleton: repo, docs, 01–08 stubs, boot log, `.inm status` | ✅ done | scripts load with zero errors; engine pinned in SOURCES.md |
| 2 | Config clamping; base SQL; loaders w/ validation, prebuilt indexes, atomic swap; `.inm reload` | ✅ done | unit tests (clamp), integration harness (load/reload), SQL checker |
| 3 | Player tracking (3/4/27/47); PlayerTrack/LocationState; lazy equip scan; `.inm where` | ✅ done | integration: login/logout tracking, scan freshness, tags |
| 4 | Per-entry registry (36/37); per-location registry w/ cached positions | ✅ done | integration: ON_ADD/ON_REMOVE register/deregister, RegistryCount |
| 5 | Scheduler + emission: heartbeat, buckets, cooldowns, selection, final validation, emit, metrics, `.inm force|stats|cooldown clear` | ✅ done | integration: EMITTED, cooldown block/clear, combat/phase/distance rejects |
| 6 | Content pass: 36 seed lines, tone rules, placeholder safety | ✅ done | seed SQL applied+idempotent in CI; hostile-input placeholder unit test |
| 7 | v2 — area-ID districts, TRIGGER_EVENT curated moments, LoS/facing, 200+ lines | ⬜ future | `RequireLineOfSight`/`RequireNpcFacingPlayer` already wired |
| 8 | v3 — cosmetic client addon layer (ADDON_EVENT_ON_MESSAGE) | ⬜ future | server never trusts client-reported identity |

## Verified HERE (this sandbox — see TESTPLAN for detail)
- `luacheck` clean on all scripts + tests + `.luacheckrc` (0 warnings; implicit globals forbidden).
- `tests/run_tests.lua` — 66/66 pure-Lua unit assertions.
- `tests/integration_mock.lua` — 46/46 end-to-end assertions against a mock engine.
- `tools/check_sql*.py` — SQL structural checker self-test passes (catches the 3 defect classes); real seeds clean.
- Every event ID + method signature verified against the Eluna pin (SOURCES.md).

## NOT verified here (needs the owner's server — see README "Known limitations" + TESTPLAN in-game matrix)
- The scripts loading in a live ALE/Eluna state (S1 is UNVERIFIED for this server).
- Real `WorldDBQuery` result-object behavior on this build.
- Real emission (`SendUnitSay`/`Whisper`/`SendUnitEmote`) visibility in-game.
- Guard creature entries + zone IDs matching this server's DB (run `sql/verify_ids.sql`, `.gps`, `.inm where`).

## Next steps for the owner
1. Confirm the engine + commit the server builds; if not the pinned Eluna, re-verify SOURCES.md against it.
2. Import SQL (§README), run `sql/verify_ids.sql`, fix any missing guard entries.
3. Deploy `scripts/inc/` to the Lua scripts dir; reload/restart; check the boot summary line.
4. Run the in-game matrix in TESTPLAN.md; record pass/fail.
