# Applied geometry and layout fixes — 7 November 2026

GEO-01 and GEO-02 now use addon-owned public layout dimensions. Prediction
amounts and maximum health continue through their existing native StatusBar
sinks. The implementation preserves full-width/max-health normalization; it
does not use the rejected remaining-health-span experiment.

The fresh pre-apply checkpoint is recorded in [checkpoint.json](../checkpoint.json).
The immutable baseline Shared SHA-256 is
`79d1d123ee4c628b706b6c8e6f0a102ebe0a87084e0908501f95d493042cb20f`.
Exact current hashes, three focused repetitions, syntax results and paired
checkpoint/applied observations are in [results.json](results.json). No consumed
file changed during this focused run. This work issued no game, input, settings
or profiler writes. Runtime changes were authorized by the later “fix everything
now” instruction; earlier audit/proposal reports describe their earlier phase.

| Finding | Applied behavior | Evidence |
|---|---|---|
| GEO-01 | Public width/height captured at owned layout writers; unreadable child rectangles never enter comparison, arithmetic or geometry setters. The older positive-heal path uses the same ledger. | Identical complete-painter boundary controls: checkpoint hits one opaque comparison and cannot show the absorb; applied code shows the intended120px bar with zero opaque operations. |
| GEO-02 | Original striped textures render on full public canvases, cropped by native fill-anchored clip frames. UV scale remains one tile per32 logical pixels. | Identical tile controls: checkpoint contains one denied division and leaves old UVs; applied code performs zero opaque operations. Visible96px remains exactly three tiles in both public controls. |

`tests/prediction_public_geometry.lua` passes **8,460 assertions** across Era,
Anniversary, Live and Forever models. It executes the actual factory, partition
and full prediction painter, including positive own/other incoming heals,
forward and overflow damage absorbs, antiheal decorations, health0/25/60/100,
35/250/960-wide owners, normal/health-only layouts, additional power, hidden
resource and party power-height factors. Live/Forever controls include opaque
numeric and geometry stand-ins; Classic uses readable health contracts.

The production public writers are exercised separately in
`tests/public_geometry_writers.lua`: **80 assertions** for actual squeeze,
focus-target, pet-target, party and options routes, with inaccessible native
dimensions. Public arguments are recorded before each owner size write.
`idle_unit_geometry.lua` retains **1,547 portrait checks** and reduces300 paired
unchanged size writes from3,000 to10 across five models. Prediction rendering
checks moved to the dedicated geometry test because a clipped full-size canvas
intentionally has different internal width/UVs from the old fill-sized texture.
The existing portrait-camera test retains its **1,191 assertions and three
negative controls**, loading the actual public helper dependency.

Each health frame adds exactly **three clip frames on modern clients, two on
Classic**. They are constructed with the existing health bars, before combat
paints; they add no OnUpdate, events, timers, setter hooks or recurring service.
Repeated changes reuse them. Parent visibility controls their lifetime.
Individual canvas setter failures leave caches uncommitted so the same geometry
can retry. Layout-only partition changes immediately refresh existing visible
canvas size/UVs, without a prediction recalculation or a later unit event.

The original texture/art/alpha is reused. Each clip has the original bar's
frame level and inherits its strata. Shield stripes retain ARTWORK sublevel1;
antiheal retains sublevel2 and its edge textures remain sublevel0. Prediction
bars/clip owners remain at main owner+3, edge glows at owner+4, and the existing
text overlay at owner+30. The modeled ordering is asserted. Reparenting no
longer raises these clips above their bars. For forward and reverse overflow
fill, UV at distance x from the physical left edge of the live fill remains
x/32: native clipping changes the visible rectangle, while the canvas retains
the original32px phase and frequency.

Peer review caught and corrected two implementation gaps before finalization:
partition-only resize initially left a stale canvas, and Pet's pre-factory
parent-level raise initially left a stale40-level cache. Active stripe44/84/144
resize controls now pass without another prediction event. The actual Pet
raise now yields parent70, health72 and text100. Pet/ToT public parent-level
writes update their ledger; a clip configuration retry derives owner+3 rather
than reusing a child cache from before reparenting. Native child levels are not
manually shifted twice.

The rejected snapshot-coupled alternative stays rejected:250px, drawn60% health,
calculator40%, absorb20% must produce50px; normalizing against the remaining
span would produce33.3333px. The applied painter retains the original formula;
its independent300px control produces60px despite different drawn/calculator
health snapshots.

Owned constructors provide public geometry before first paint. If an external
incomplete owner supplies neither recorded dimensions nor readable fallback
getters, the code makes no opaque SetWidth/SetSize call and invents no zero
size; that owner remains unsupported until public layout becomes available.
This is not a recovery mechanism for reading native secrets.

Shared threat glow now routes start/stop/raise/presence through the private
addon renderer delivered with this change. Successful application commits the
band cache; a failed or explicitfalse start remains retryable. Only historical
overlays explicitly attached to this owned shell/legacy host are stopped and
hidden. They are never returned through an unrelated winning shared-library
pool. An old shared allocation can remain retained until its original owner
cleans it or the UI reloads. Private renderer regressions are recorded in the
alpha report. PERF-01–04 changes and697 permanent budget checks are recorded
separately in [performance/REPORT.md](../performance/REPORT.md).

Reproduce the focused evidence with:

```powershell
python 'Stress test doc/applied-fixes/geometry/run_geometry.py'
```

These are desktop executions of production code with rectangle/API mocks and
explicit opaque traps. They establish the stated source paths, counts and
mathematics. Native clipping pixels, protected execution/taint provenance,
animation rendering and FPS remain pending in each real client. Current
Forever geometry/StatusBar/texture contracts are pinned in
[upstream.json](../../fix-proposals/upstream.json).
