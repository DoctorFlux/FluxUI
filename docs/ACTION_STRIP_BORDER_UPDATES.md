# Action-strip border updates

Change `ACTION-STRIP-BORDER-R55-20261116` follows the user's partial-row
screenshot `codex-clipboard-81a6edb4-45e7-479f-a0fc-0e7a0ce1d817.png`.

| ID | Requirement | Implementation and acceptance |
|---|---|---|
| ASB01 | Avoid unrelated border/layout work when an occupied slot changes without changing geometry. | Only the existing same-occupancy branch requests a changed-only decorative pass. Fresh public frame, inner and sensing geometry must match. Unknown/private/drift takes the original writer. |
| ASB02 | Keep real packing, expansion and collapse functional. | Changed-hash/direct/options calls retain full layout. The paired Strip-guard replay on R54 Core has one commit/read/solve per genuine state change; expand and collapse remain separate changes. |
| ASB03 | Preserve all action IDs, modifier routes, bindings and repair. | Mapping invalidation, 171 cursor flag writes, ForceApply, paint and binding notifications remain. No routing/slot changes. |
| ASB04 | Make the strip's top edge continuous with the surrounding HUD on partial rows. | Exact strip/enclosing-border top nodes may join only when overlapping and within the existing contact limit. Strip is authoritative; only decorative border bounds change. |
| ASB05 | Support both border types, scales, mini-row states and attach/detach. | 144 static actual producer scenes; 5,798 checks; 1,080 single-source crest samples; hidden/distant/detached controls and no-op stability. Native pixels remain deferred. |
| ASB06 | Reduce real rebuilding only where work is unchanged. | Existing prepared numeric caches remain. A proposed extra cut/prefix cache is rejected for this slice: the compact actual grow/shrink/expand/collapse scene has no exact reusable cut prefixes. Full fresh discovery/solve still occurs for genuine geometry changes; broader CB36 latency acceptance remains open. |
| ASB07 | Keep settled borders static and avoid new drivers. | No new timer, ticker, script polling, mask or recurring job. Existing visibility/gamepad and cursor cadence remain. |
| ASB08 | Honor the user's test restriction. | All in-game testing is deferred until explicit renewed user availability. Offline implementation and tests continue. No reload/capture requests while the hold remains. |

The enclosing border used a nominal top two UI units above the actual strip
crest. Adjacent grid decoration was fitted to the strip, while the containing
envelope was not an adjacent/stacked panel. At a packed strip endpoint the paint
owner could therefore change between two different heights. The local top-node
contact fixes that gap without moving widget, strip, unit or envelope roots.

The action layout already filtered unchanged occupancy before its final explicit
commit. However, its same-hash branch still called `Strip.Layout`, which reset
three decorative frames and invoked player/target status layout. The new optional
guard checks current native dimensions, scales and anchors before skipping
those writes; visibility and metadata updates remain. It adds 15 fresh native
getter calls to remove nine clear/point/size calls across three frames, one scale write and one
player-layout callback in the occupied-swap replay. This is work evidence, not
native latency or FPS acceptance.

UnifiedBorder's event handler is unconditional, but its `UpdateBorder` already
has a layout-hash/visibility early return. That callback alone was not evidence
of repeated rebuilding. The combined actual Init/Watch/Hosts/Layout/Strip,
factory/Unified/Core replay checks the resulting work rather than inferring it
from requests. Its ten paired work states use the same R54 Core on both routes
to isolate the Strip guard. Combined R55 visual sampling covered type 1
occupied/grow/shrink states before an expansion-domain guard stopped the sampler;
neighboring layouts are counted sinks in that compact fixture. The separate
144 static R55 seam scenes establish their own stated scope.

The user's R54 combat-exit capture reports a 0.73ms unchanged preflight and zero
geometry/solve/plan/commit. Its 81ms frame gap remains unattributed. Mesh/cache
counts in that unchanged row describe the preceding completed build; this sample
does not establish drag/drop or real-layout performance.

Decorative borders add no controller focus stops. Existing native/gamepad
visibility, mouse/keyboard/controller action routing and settings remain.
See [exact sources and scoped proof](validation/action-strip-borders-2026-11-16.json)
and [shared border requirements](CONNECTED_BORDERS.md).

<!-- STRIP-PARKED-CHROME-20261120 -->
The strip retains verified button chrome when a face returns from off-screen parking. The first crossing refits 19 versus 5 faces in each desktop client model. Sixty warmed crossings refit 571 faces before and zero after. Button positions, action slots and visible art match. The held-cursor watcher also leaves the sensing frame alone once its live visibility matches. Live rapid cursor crossings and drops, including changing side-panel contacts, remain pending for frame time, seams and combat taint. Party and raid join and leave, embedded minimap toggles and combat exit remain open for the broader goal.
[Matched validation](validation/strip-parked-chrome-2026-11-20.json).
<!-- /STRIP-PARKED-CHROME-20261120 -->

<!-- STRIP-INFO-MEASURE-20261120 -->
Info now reuses the width just measured when its hybrid labels match, and adjusts the current render list in place. In 60 modeled width changes, the usual FPS and ping row uses 120 width queries instead of 240. The dense row uses 2,010 instead of 2,220. The item-level and GearScore case keeps all 960 queries because the labels change. The decorative slot skips 120 grid-height reads over 60 crossings. Text, fonts, anchors, tooltip contents and slot visibility match.
[Matched validation](validation/strip-info-measure-2026-11-20.json).
<!-- /STRIP-INFO-MEASURE-20261120 -->

<!-- BORDER-CELL-BUDGET-R187-20261120 -->
R187 reduces capacity checks from 7,560 region visits to 2,340 across 60 warmed action-strip crossings per border style. The modeled fields, sampled colors and opacity, and admitted draw records match. Native action-strip latency, party and raid transitions, seam pixels and combat taint remain pending. The desktop replay counts capacity work and does not measure client frame time.
[Matched validation](validation/border-cell-budget-2026-11-20.json).
<!-- /BORDER-CELL-BUDGET-R187-20261120 -->
