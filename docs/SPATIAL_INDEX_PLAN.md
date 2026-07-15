# SPATIAL_INDEX_PLAN — registry spatial index (uniform grid hash)

**Status:** design, not yet built. Actionable plan for adding a spatial index to the per-location
creature registry so `selectNpc` stops scanning the whole hub registry per due player.

Related: `docs/DECISIONS.md` ADR-011 (per-player scheduler), `/source/EFFICIENCY.md` §5 (the
sweep cost model this optimises), `scripts/inc/04_inc_registry.lua`, `scripts/inc/06_inc_scheduler.lua`.

---

## 1. Problem statement

The per-player scheduler (ADR-011) calls `selectNpc(loc, player, …)` for every *due* player each
tick. `selectNpc` today iterates **the entire location registry** and squared-distance-checks each
entry against the player:

```
for guidLow, reg in pairs(INC.Registry.ForLocation(loc.id)) do   -- O(R)
  if reg.mapId == pmap and <within radius^2> then … end
end
```

Cost per tick ≈ `(due + backed-off players in the hub) × R`, where **R = registered NPCs in that
hub**. R is small for the seed guards, but the broad **vendor profiling sweep** (`inm-auto:vendor`,
~4366 profile rows → up to ~1500 hooked entries) can register hundreds of NPCs in a busy hub. At
that point the O(R) inner scan is the module's largest steady-state cost (see EFFICIENCY.md §5:
timer frequency is free, *scan width* is what bites).

**Goal:** replace the O(R) per-query scan with an O(local density) neighbourhood lookup, with **no
behavioural change** (same candidate set as the cached-position pre-filter produces today) and no
new per-tick allocation.

**Non-goal:** changing final validation (still uses the live creature position), changing which
NPCs are eligible, or fixing the vendor-sweep row count (that is a separate, orthogonal lever —
trimming the sweep reduces R directly; this index makes any R cheap to query).

---

## 2. Options considered

| Option | Fit | Verdict |
|---|---|---|
| **Uniform grid hash** (bucket by fixed cell; query the local neighbourhood) | O(1) insert/remove, O(cells) query; WoW hubs are ~flat 2-D; registry entries are near-static (cached spawn pos) | **Chosen** |
| Quadtree / k-d tree | Better for wildly non-uniform density or huge worlds | Over-engineered here; dynamic insert/remove fiddly; the win over a grid is negligible at hub scale |
| Sort-by-axis + binary search | Cheaper memory | Re-sort on every insert/remove; worse for churn (grid loads) |
| **Status quo + trim the vendor sweep** | Zero code | Keeps R small but caps content coverage; complementary, not a substitute — do both if desired |

**Why the uniform grid:** registry entries carry a **cached** position set once at `ON_ADD` and never
moved (final validation uses the live position, so patrollers are already handled approximately —
§6). A structure whose only mutations are O(1) insert (`ON_ADD`) and O(1) remove (`ON_REMOVE`) is
exactly a grid keyed on the cached cell. Query is a small fixed neighbourhood. No sqrt, no alloc.

---

## 3. Data structure

Per location, alongside the existing flat `byGuid` map (kept — `ON_REMOVE` and the scheduler still
need direct guid access), add a grid:

```
INC.State.Registry[locId] = {
  byGuid = { [guidLow] = reg, … },        -- unchanged; authoritative entry store
  grid   = { [cx] = { [cy] = { [guidLow] = reg, … } } },  -- cells -> entries in that cell
}
```

- **Cell size:** a module constant `REGISTRY_CELL = 40.0` (yards), independent of
  `MaxCandidateSearchRadius` so the grid **never needs a rebuild when the radius config changes**.
  Chosen as ≥ the max candidate radius (clamp ceiling 60) is *not* required — instead the query
  spans `ceil(radius / REGISTRY_CELL)` cells each way (see §4). 40 keeps a typical 30-yd radius to a
  3×3 query and the 60-yd ceiling to 5×5.
- **Cell key:** integer cell coords `cx = floor(x / REGISTRY_CELL)`, `cy = floor(y / REGISTRY_CELL)`.
  Use **nested tables** `grid[cx][cy]` (not a packed string/int key): WoW coords are negative in
  large regions, nested integer keys handle that with no offset arithmetic and no string allocation.
- **Per-entry cell tag:** store `reg.cx, reg.cy` on the registry entry at insert, so `ON_REMOVE` is
  O(1) (no need to recompute or search).
- **One map per location:** a location is a single `map_id`+`zone`; `registerCreature` only registers
  creatures whose `ResolveLocation` matches, so **every entry in a location's grid shares a map** —
  the cell key needs no map/z component. `z` is ignored for bucketing; the exact distance check (§4)
  still includes `z`, so vertical hubs (Dalaran) stay correct.

Memory: the grid stores references to the same `reg` tables already held by `byGuid` — negligible
extra.

---

## 4. Algorithms

**Insert** (in `registerCreature`, after building `reg`):
```
reg.cx = floor(reg.x / REGISTRY_CELL)
reg.cy = floor(reg.y / REGISTRY_CELL)
local col = grid[reg.cx]; if not col then col = {}; grid[reg.cx] = col end
local cell = col[reg.cy]; if not cell then cell = {}; col[reg.cy] = cell end
cell[guidLow] = reg
byGuid[guidLow] = reg   -- as today
```

**Remove** (in `onRemove`, using the stored cell tag):
```
local reg = byGuid[guidLow]
if reg then
  local col = grid[reg.cx]; local cell = col and col[reg.cy]
  if cell then cell[guidLow] = nil end     -- leave empty cell tables; they’re tiny and reused
  byGuid[guidLow] = nil
end
```
(We deliberately do **not** prune empty cell tables — a hub has a bounded set of occupied cells and
they churn back on respawn; pruning would add work for no memory win.)

**Query** (rewrite of `selectNpc`'s candidate gather):
```
local pcx = floor(px / REGISTRY_CELL)
local pcy = floor(py / REGISTRY_CELL)
local span = ceil(cfg.MaxCandidateSearchRadius / REGISTRY_CELL)   -- 1 for r<=40, 2 for r<=80
local radiusSq = cfg.MaxCandidateSearchRadius^2
for ix = pcx - span, pcx + span do
  local col = grid[ix]
  if col then
    for iy = pcy - span, pcy + span do
      local cell = col[iy]
      if cell then
        for guidLow, reg in pairs(cell) do
          -- identical body to today: reg.mapId == pmap already implied per-location, but keep the
          -- squared-distance + FindProfile + cooldown checks EXACTLY as now
          local dx,dy,dz = reg.x-px, reg.y-py, reg.z-pz
          if dx*dx+dy*dy+dz*dz <= radiusSq then … end
        end
      end
    end
  end
end
```
`span` is recomputed per query from the live config (cheap), so a `.inm reload` that changes the
radius takes effect with no grid rebuild. The candidate set produced is **identical** to today's full
scan (every entry within `radius` is in one of the queried cells, because `span` covers `radius`).

---

## 5. Integration points (files touched)

1. **`scripts/inc/04_inc_registry.lua`**
   - `REGISTRY_CELL` constant + local `floor`.
   - `Registry.Init`: initialise each `st.Registry[locId]` lazily as `{ byGuid = {}, grid = {} }`
     (or keep `st.Registry[locId]` = the grid-bearing table; adjust the two places that create it).
   - `registerCreature`: compute + store cell, insert into both `byGuid` and `grid`.
   - `onRemove`: O(1) removal via stored cell tag.
   - `ForLocation`: return the location's `byGuid` map (so `cmdWhere` and any full-iteration caller
     are unchanged) **and** add `Registry.ForCell(locId, cx, cy)` / a `Registry.QueryNear(locId, x,
     y, radius, fn)` helper that the scheduler uses. Prefer a single `QueryNear` iterator so the grid
     walk lives in one place.
2. **`scripts/inc/06_inc_scheduler.lua`**
   - `selectNpc`: replace the `pairs(ForLocation(...))` loop with `Registry.QueryNear(...)`; body
     (distance, `FindProfile`, cooldown, scratch-array fill, random pick) unchanged.
3. **`scripts/inc/07_inc_commands.lua`**
   - `cmdWhere` still iterates `ForLocation` (the full `byGuid`) — fine, it's a debug command; leave
     it, or switch it to `QueryNear` for consistency (optional).
4. **`RegistryCount` / `RegistryIndex`** — unchanged (still keyed by guidLow globally).

---

## 6. Edge cases & correctness

- **Behavioural parity:** the query returns exactly the entries a full O(R) scan would, so
  `selectNpc`'s output distribution is unchanged. The existing integration tests (`ambient`,
  multi-emit, NPC-cooldown, `far players`) must still pass **unmodified** — that is the regression
  guarantee.
- **Patrollers:** the registry caches the **spawn** position and never updates it; final validation
  uses the *live* position. The grid keys on the same cached position, so behaviour is identical to
  today (a guard that wandered is found iff its *cached* cell is near, then live-distance-validated).
  No regression. If we ever want patrol-accurate pre-filtering, that's a separate change (periodic
  position refresh) and would apply equally to the current code.
- **Negative / large coords:** nested integer-keyed tables handle negatives directly; no offset.
- **`.inm reload`:** does not rebuild the registry (ADR-007); the grid is maintained incrementally by
  `ON_ADD`/`ON_REMOVE` + `SeedFromPlayers`, so no reload interaction. A radius change is absorbed by
  recomputing `span` per query.
- **`SeedFromPlayers`:** already funnels through `registerCreature`, so it populates the grid for
  free — no change beyond the `registerCreature` edit.
- **Empty cells:** left in place (tiny), not pruned — avoids churn on respawn.

---

## 7. Testing plan (all runnable in-sandbox)

Add to `tests/run_tests.lua` (pure grid unit tests — factor the cell math into a tiny pure helper so
it can be tested without the engine) and `tests/integration_mock.lua`:

- **Unit:** `cellOf(x, y)` returns expected `cx,cy` incl. negative coords and cell boundaries.
- **Unit:** insert 3 entries across 2 cells; `QueryNear` at a point returns only those within radius;
  a far entry in a non-adjacent cell is excluded; remove one and it disappears from the query.
- **Integration (regression):** the existing `far players` test — 8 far + 1 adjacent — must still
  emit for the near player, now via the grid path. Add an assertion that the **candidate scan
  touched ≤ K entries** (instrument `QueryNear` with a counter in the mock) to prove the index
  actually bounds work, not just returns the right answer (EFFICIENCY.md §5: prove the budget binds).
- **Integration:** two entries in the same cell, one on NPC cooldown → `QueryNear` still yields the
  free one (cooldown logic unchanged).

Gates unchanged: `luacheck` 0, `run_tests.lua`, `integration_mock.lua`, `check_sql*` (no SQL here).

---

## 8. Build order & verification

1. Factor `cellOf` + a pure `queryCells(grid, pcx, pcy, span, fn)` walker; unit-test them.
2. Wire insert/remove in `04_inc_registry.lua`; add `QueryNear`; keep `ForLocation` returning
   `byGuid`. Run integration — everything green (grid populated, full-scan callers unaffected).
3. Switch `selectNpc` to `QueryNear`; add the scan-count assertion. Green.
4. `/code-review` the diff (hot-path change); update `TRUTH_SOURCES.md` (registry shape) + a short
   ADR-012 (spatial index) + session notes.

---

## 9. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Off-by-one in `span` misses a boundary NPC | `span = ceil(radius/CELL)` covers radius; regression test with an NPC placed exactly `radius` away straddling a cell edge |
| Grid and `byGuid` drift (entry in one, not the other) | Single insert/remove path (`registerCreature`/`onRemove`); assert `RegistryCount` parity in a test |
| Premature complexity if R stays small | Ship only when `.inm status` shows large hub registries; until then the O(R) scan is fine (EFFICIENCY.md §5). This plan is the trigger-ready design, not a mandate to build now. |
| Config radius > 2×CELL (unlikely; clamp ceil 60, CELL 40 → span 2) | `span` handles any radius; no assumption that radius ≤ CELL |

---

## 10. Out of scope

- Trimming the vendor sweep (separate lever; reduces R directly — can be done independently or
  alongside).
- Live-position tracking of patrollers (separate; current cached-pos behaviour is preserved).
- Cross-location or cross-map queries (a location is single-map by construction).
