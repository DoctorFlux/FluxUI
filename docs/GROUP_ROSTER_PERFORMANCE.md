# Group roster performance — 8 November 2026

The user reported severe lag while inviting members. This change removes repeated
Flux work on ordinary roster notifications while retaining native membership,
visibility, group ordering, click casting and deferred protected setup.

## Changed paths

- `FluxRaidLayout`: prepared groups take one roster/layout pass. They keep their
  header attributes, child pools and party drivers instead of hiding/reconfiguring
  them. Initial setup, incomplete normal-party readiness, lost native capability and
  explicit option edits keep the full path.
- `FluxRaidUnit`: unchanged cell tokens queue the existing one-frame paint batch.
  New unit tokens still bind immediately; native state/attribute handlers stay intact.
- `FluxUnitFrames_Party`: member/pet show and roster notifications share one paint
  batch. Cast reset/resampling and range wake happen once per batch. Ready checks
  and other immediate indicators retain their event behavior.
- `FluxRaidHealerExtras`: all45pet slots and the optional friendly target retain
  prepared native drivers. Roster changes repaint without relayout/rebind; pending
  option changes still apply out of combat; a previously unavailable optional driver
  retries setup on the next roster notification.
- `FluxMouseoverKeybind`: roster discovery uses one existing0.3-second timer per
  burst and skips stable routing-data rebuilds. New/deferred frames still register;
  real Edit Mode, binding and routing edits keep their refresh path.
- `FluxUnitFrames_DebuffTint`: roster identity invalidation targets party owners;
  target/focus only need friendliness reevaluation and player auras retain UNIT_AURA.
  Known-type and display-only-dispellable checkbox semantics remain unchanged.

## Matched desktop evidence

Five alternating baseline/candidate pairs replay20same-turn notifications under
five client models. Each counter is identical across the five pairs. These model
scenarios are operation counts, not measurements of native invite latency or FPS.
The number of actual roster events emitted by a real invitation is not asserted.

| Replayed work | Before | After |
|---|---:|---:|
| Direct raid-header attribute writes per prepared roster burst |213|0|
| Full party/extra layouts per burst |1each|0|
| Header-child sync passes per burst |3|1|
| Hover frame discovery passes |60|1|
| Binding-key queries on unchanged roster |340|0|
| Binding roster timers |20|1|
| Optional extra-cell rebinds |920|0|
| Optional extra-cell protected writes |5520|0|
| Optional extra-cell paint calls |920|46|
| Raid paint calls after20syncs of40cells |800|40|
| Normal-party/pet paints after8shows plus20roster events |168|8|
| Normal-party cast resets / current-cast samples |80/84|4/4|
| Range wake checks for that normal-party burst |8|1|
| Prepared/extra cell allocations in the replay |0|0|

No new event frame, persistent OnUpdate or ticker is added. Raid painting reuses
its existing batch. Normal party and adjunct paints each have at most one pending
After callback; binding keeps its existing timer cadence. Native aura/secure
internal work is not included in these counts and still needs actual measurement.

## Coverage and boundaries

The focused fixture executes production paths with initial readiness/fallback,
prepared party/raid pools, combat deferral, deferred/new hover registration, real
secure hover programs, Edit Mode routing refresh, optional pet/target state, cast
cleanup and immediate ready checks.163checks pass. Twelve harmful mutations fail;
removing only the redundant outer combat guard remains safe through existing inner
guards and is recorded as a benign control rather than claimed as a rejection.

All35upstream cache files match exact Gethe Git blob SHA values. Fresh source
execution passes255908secure wrap/state/roster/click checks and58native member-order
checks across Retail, Forever, Classic progression, Era and Anniversary. These
execute client source under a desktop model; they do not establish the protected
VM, hardware input, secret-value behavior or actual rendering.

The complete suite passes257scripts and922Lua syntax files. Owned source hashes
match the tested manifest. All five installed copies match through user sync.
Before-source/history recovery holds98runtime files plus47read-only settings
metadata entries outside AddOns; the changed party fixture preimage is verified
against the preceding validation manifest. Older uncommitted work is preserved.
No foreground/input, WTF/profiler writes, manual sync or publication occurred.

Actual invite/join/leave/reorder latency, native CPU/memory/frame-time and pixel/
taint acceptance remain pending. The host has no connected WoW profiling tool;
no closed-client inference or profiler preference change was made. Keep WoW in
the background and use a matched build/addon/profile/scenario if native samples
are collected later.

[Machine evidence](validation/group-roster-performance-2026-11-08.json) contains
exact before/candidate hashes, all35source identities, raw matched samples,
negative controls, focused/full reports and installed-copy results. Continuity
requirement: [REQ-RF-95](RAID_HEALKIT_REWORK.md).

<!-- ROSTER-PREPARED-LAYOUT-R78-20261119 -->
R78 delegates prepared roster placement to the secure headers and retains the fallback layout paths. Comparisons cover joining, leaving, conversion between modes, combat release and secure failure. Current live latency and taint remain pending.
[R78 evidence](validation/roster-prepared-layout-2026-11-19.json).
<!-- /ROSTER-PREPARED-LAYOUT-R78-20261119 -->

<!-- REGIONAL-CLIPPING-R79-20261119 -->
Roster updates in R79 stop clearing matching target and focus threat-bar anchors. Join, leave, group gating, missing geometry and explicit settings changes retain their placement paths.
[R79 evidence](validation/regional-clipping-2026-11-19.json).
<!-- /REGIONAL-CLIPPING-R79-20261119 -->

<!-- GRID-ENVELOPE-R80-20261119 -->
R80 filters native party and raid hovercast cleanup by the current registration table before reading native frame names and ancestors. Previously wrapped stock cells still unregister in the same order under the existing combat guard.
[R80 evidence](validation/grid-envelope-2026-11-19.json).
<!-- /GRID-ENVELOPE-R80-20261119 -->

<!-- INDEXED-REGIONS-R81-20261119 -->
R81 reduces repeated geometry and index work inside a single regional pass. The paired dock replay measures prepared public geometry. Timing during actual roster changes remains open.
[R81 evidence](validation/indexed-regions-2026-11-19.json).
<!-- /INDEXED-REGIONS-R81-20261119 -->

<!-- INDEXED-NEIGHBORS-R82-20261119 -->
R82 reduces the regional source search in the synthetic multi-panel dock update, from 36 halo checks to 8. Native group join and leave remain open.
[R82 evidence](validation/indexed-neighbors-2026-11-19.json).
<!-- /INDEXED-NEIGHBORS-R82-20261119 -->

<!-- RAID-CELL-NEIGHBORS-20261119 -->
Raid cells sort by row and column before testing shared seams. A 40-cell grid avoids 1,560 expensive distance comparisons. Exact edges match in both overlap models through irregular rows, occupancy changes and stable token reassignments.
[Raid cell evidence](validation/raid-cell-neighbors-2026-11-19.json).
<!-- /RAID-CELL-NEIGHBORS-20261119 -->

<!-- ROSTER-ADJUNCT-DISPATCH-20261119 -->
Optional healer displays use the settled raid roster callback. Pending full and aura paint cover missing-buff selection without a second scan. Disabled displays avoid the frame batch. Visible pets, friendly target updates and native driver recovery still run on demand.
[Adjunct dispatch evidence](validation/roster-adjunct-dispatch-2026-11-19.json).
<!-- /ROSTER-ADJUNCT-DISPATCH-20261119 -->

<!-- SOURCE-RENDER-CONTEXT-R83-20261119 -->
R83 reduces renderer reads for a synthetic multi-panel change. This model is separate from a real roster transition and uses no native client timings.
[R83 evidence](validation/source-render-context-2026-11-19.json).
<!-- /SOURCE-RENDER-CONTEXT-R83-20261119 -->

<!-- FRAGMENT-OWNERS-R84-20261119 -->
R84 cuts repeated fragment ownership work in the modeled multi-panel dock. The desktop case is synthetic and does not establish native group latency.
[R84 evidence](validation/fragment-owners-2026-11-19.json).
<!-- /FRAGMENT-OWNERS-R84-20261119 -->

<!-- PREPARED-LAYERS-R85-20261119 -->
The R85 synthetic dock model uses 13–14 participating-frame strata reads per build, down from 1,807–2,104. The comparison is a desktop geometry replay and does not establish roster-event latency.
[R85 evidence](validation/prepared-layers-2026-11-19.json).
<!-- /PREPARED-LAYERS-R85-20261119 -->

<!-- ROSTER-MACRO-BATCH-20261119 -->
The action strip and Extra systems share roster-dependent macro evaluation. The existing eval pass samples the final condition state once across the burst. The fallback handles the extra system without the shared macro owner.
[Macro roster batch evidence](validation/roster-macro-batch-2026-11-19.json).
<!-- /ROSTER-MACRO-BATCH-20261119 -->

<!-- TILE-FIELD-REJECTION-R86-20261119 -->
The R86 synthetic dock models allocate 143–193 clipping polygons per reflow, down from 234–330. This measures renderer work in a desktop geometry replay. Actual group event performance remains pending.
[R86 evidence](validation/tile-field-rejection-2026-11-19.json).
<!-- /TILE-FIELD-REJECTION-R86-20261119 -->

<!-- INDIVIDUAL-ROSTER-BATCH-20261119 -->
The individual player, target, focus, mirrored and pet chrome paths now run once per delivered burst. The group label reads one validated roster row and uses the original identity search when the direct slot is unavailable.
[Individual unit roster evidence](validation/individual-roster-batch-2026-11-19.json).
<!-- /INDIVIDUAL-ROSTER-BATCH-20261119 -->

<!-- STRIP-CHROME-MINIMAP-ROSTER-20261119 -->
The minimap difficulty, layout and queue calls now share a next-turn roster batch. The matched 20-notification replay drops from 20 to one call per path. Any already-pending work is consumed by a full indicator pass or released after combat.
[Strip and minimap evidence](validation/strip-chrome-minimap-roster-2026-11-19.json).
<!-- /STRIP-CHROME-MINIMAP-ROSTER-20261119 -->

<!-- PREPARED-STRIP-SAMPLING-R88-20261119 -->
The general border fallback renderer skips setup for empty rectangle plans. The paired replay uses a synthetic dock move to cover this path beyond the strip. Native group join or leave performance is still open.
[Border sampling evidence](validation/prepared-strip-sampling-2026-11-19.json).
<!-- /PREPARED-STRIP-SAMPLING-R88-20261119 -->

<!-- BORDER-SETTERS-THREAT-ROSTER-R89-20261119 -->
The optional Details threat meter merges same-turn roster notifications into one in-combat scan. An immediate matching threat event, target change or existing poll covers the refresh first when available. Stop, cancel and disable clear pending roster work.
[Setter and threat roster evidence](validation/border-setters-threat-roster-2026-11-19.json).
<!-- /BORDER-SETTERS-THREAT-ROSTER-R89-20261119 -->

<!-- RAID-ROSTER-ATTACHMENT-PAINT-R93-20261119 -->
Restrict MT/MA attachment checks to their dedicated prepared header. The matched 40-member case reduces attachment child reads from 50 to two. The shared loot assignment in its paint pass is read once per batch. Normal cell and aura paint counts agree.
[Raid roster paint evidence](validation/raid-roster-attachment-paint-2026-11-19.json).
<!-- /RAID-ROSTER-ATTACHMENT-PAINT-R93-20261119 -->

<!-- STRIP-LAYER-COMMIT-R95-20261119 -->
On clients using the insecure unit-watch fallback, repeated roster notifications before the existing next-frame reconciliation share its sweep. The first notification still reconciles immediately. Unchanged public pet opacity and unit-existence attributes stay in place.
[Matched validation](validation/strip-layer-commit-2026-11-19.json).
<!-- /STRIP-LAYER-COMMIT-R95-20261119 -->

<!-- CONSUMABLE-ROSTER-BINDINGS-R97-20261119 -->
Group notifications no longer trigger Food or Water spell and bind refreshes. The active create-spell provider uses learned ranks for solo, party and raid. Repeated Food updates also used to clear the existing middle-click suppression.
[Matched validation](validation/consumable-roster-bindings-2026-11-19.json).
<!-- /CONSUMABLE-ROSTER-BINDINGS-R97-20261119 -->

<!-- RAID-ROSTER-NATIVE-WRITES-R104-20261119 -->
Matching frame references, legacy header anchors, container width and group labels now keep their current state through ordinary roster reconciliation. Real or unreadable changes still use the original setters and secure reflow.
[Matched validation](validation/raid-roster-native-writes-2026-11-19.json).
<!-- /RAID-ROSTER-NATIVE-WRITES-R104-20261119 -->

<!-- REGIONAL-ROSTER-POSES-R105-20261119 -->
The border renderer retains up to two small compiled roster layouts. An exact repeat reuses the prepared joins and samples current paint. The four-frame relocation replay exercises both named party frames and named raid frames, with native join and leave timing still pending.
[Matched validation](validation/regional-roster-poses-2026-11-19.json).
<!-- /REGIONAL-ROSTER-POSES-R105-20261119 -->

<!-- HELD-ACTION-REFLOW-R107-20261119 -->
Prepared regional roster layouts share the new paint input recipe with held-action poses. Party and raid replay coverage passed. Native group hitching remains open.
[Matched validation](validation/held-action-reflow-2026-11-19.json).
<!-- /HELD-ACTION-REFLOW-R107-20261119 -->

<!-- INDEPENDENT-BORDER-REGIONS-R108-20261119 -->
An explicitly independent normal party outline now owns a separate paint region. Each movement of one party member replaces one output region, compared with six to nine screen tiles. Hover replays retain all four party paint generations and plan half as many source segments. Compact raid cells still use the existing separate joined-edge renderer. Actual join and leave timing remains open.
[Matched validation](validation/independent-border-regions-2026-11-19.json).
<!-- /INDEPENDENT-BORDER-REGIONS-R108-20261119 -->

<!-- COMPACT-RAID-SEAM-DELTAS-R109-20261119 -->
A single leave uses 111 instead of 627 seam distance checks, a join uses 111 instead of 660, and a moved cell uses 210 instead of 648. Unbound prepared cells skip visibility reads. Both row overlaps, duplicate neighbors, bulk churn and a failed paint retry remain covered.
[Matched validation](validation/compact-raid-seam-updates-2026-11-19.json).
<!-- /COMPACT-RAID-SEAM-DELTAS-R109-20261119 -->

<!-- RAID-AURA-PRESENTATION-R110-20261119 -->
Twenty stable 40-cell repaints skip 8,000 redundant visibility writes. With one cell leaving and rejoining, writes fall from 8,000 to 70 and all 210 necessary unit writes agree. Native filter groups still process their own aura events, and readable fallback keeps its existing snapshots.
[Matched validation](validation/raid-aura-presentation-2026-11-19.json).
<!-- /RAID-AURA-PRESENTATION-R110-20261119 -->

<!-- RAID-UNIT-PAINT-READS-R111-20261119 -->
A full 40-cell roster pass uses 160 health and connection-related reads instead of 520 in the Forever and Retail models. Classic models use 200 instead of 600. Opaque values still reach native setters. Data stays in the current paint dispatch and is overwritten for the next cell.
[Matched validation](validation/raid-unit-paint-reads-2026-11-19.json).
<!-- /RAID-UNIT-PAINT-READS-R111-20261119 -->

<!-- STRIP-BORDER-REFRESH-R112-20261119 -->
The regional roster renderer reuses the source lookup pass and the committed owner map. Exact paired sampled geometry agrees in both border types.
[Matched validation](validation/strip-border-refresh-2026-11-19.json).
<!-- /STRIP-BORDER-REFRESH-R112-20261119 -->

<!-- BORDER-VISIBILITY-FANOUT-R114-20261119 -->
Retained border fragments share their source availability checks during frame visibility and opacity changes. The desktop comparison covers paint-only changes and separate roster geometry reflows. Actual group membership latency remains pending.
[Matched validation](validation/border-visibility-fanout-2026-11-19.json).
<!-- /BORDER-VISIBILITY-FANOUT-R114-20261119 -->

<!-- BORDER-DRAW-GEOMETRY-R115-20261119 -->
Regional roster draws use the same combined native placement check and current public source color. Desktop sampled roster joins match. Actual group membership latency remains pending.
[Matched validation](validation/border-draw-geometry-2026-11-19.json).
<!-- /BORDER-DRAW-GEOMETRY-R115-20261119 -->

<!-- ROSTER-DISCOVERY-REFRESH-R116-20261119 -->
A 40-plate roster batch needs one combo target lookup, down from 41 when the target has no visible plate. Across twenty hover discoveries, raid ownership reads fall from 2200 to 20 and forbidden checks from 1960 to 21. The model preserves native and Flux admission, Clicked ownership and lockdown. Native roster timing remains pending.
[Matched validation](validation/roster-discovery-refresh-2026-11-19.json).
<!-- /ROSTER-DISCOVERY-REFRESH-R116-20261119 -->

<!-- STRIP-VISIBILITY-R117-20261119 -->
The regional renderer attaches and removes visibility lists at the tile level during scoped roster updates and held-action strip crossings. Native join and leave timing remains pending.
[Matched validation](validation/strip-visibility-2026-11-19.json).
<!-- /STRIP-VISIBILITY-R117-20261119 -->

<!-- RAID-PAINT-BATCH-R118-20261119 -->
A 40-cell compact paint reads each shared option once and halves class lookups from 80 to 40. The name painter owns the role-icon hide, removing 40 duplicate writes. The readable aura path paints dispel highlights once per cell. The model also covers five-member compact groups. Native group latency remains pending.
[Matched validation](validation/raid-paint-batch-2026-11-19.json).
<!-- /RAID-PAINT-BATCH-R118-20261119 -->

<!-- RAID-REASSIGNMENT-R119-20261119 -->
Three reassignment waves across 40 compact cells drop from 160 full paints to 40. Paired companion roster requests drop from 82 to 41 paints for the raid and from 12 to 6 for the party. Visibility, unit reassignment, addon event routes and explicit reveals run through the current owner. Actual latency remains pending.
[Matched validation](validation/raid-reassignment-2026-11-19.json).
<!-- /RAID-REASSIGNMENT-R119-20261119 -->

<!-- STRIP-CHAT-DOCK-R120-20261119 -->
Twenty settled held-action crossings with matching chat and raid positions remove 100 chat widget writes, 40 saved-position and dimension calls, 40 focus partition calls and 60 focus aura layout entries in the desktop replay. The actual focus and raid dock methods were replayed with their existing draw callbacks. Live join and leave timing remains pending.
[Matched validation](validation/strip-chat-dock-2026-11-19.json).
<!-- /STRIP-CHAT-DOCK-R120-20261119 -->

<!-- STRIP-PAINT-INDEX-R121-20261119 -->
Regional sprite and tint subscriptions now publish by tile. The matched roster fixture had zero affected junction membership in this scene. Live group latency remains pending.
[Matched validation](validation/strip-paint-index-2026-11-19.json).
<!-- /STRIP-PAINT-INDEX-R121-20261119 -->

<!-- BORDER-VISIBILITY-COMMIT-R122-20261119 -->
An independent roster layout replay preserves unit alpha ownership. The affected tiles have zero eligible fallback ancestor reads in this fixture. Native party and raid timing remain pending.
[Matched validation](validation/border-visibility-commit-2026-11-19.json).
<!-- /BORDER-VISIBILITY-COMMIT-R122-20261119 -->

<!-- PARTY-DISPEL-IDENTITY-R123-20261119 -->
A stable four-member roster batch now triggers zero native debuff owner refreshes in the Retail and Forever models. A one-member replacement uses three refreshes instead of twelve. An unreadable GUID still refreshes all native owners for that member. Native join and leave timing remain pending.
[Matched validation](validation/party-dispel-identity-2026-11-19.json).
<!-- /PARTY-DISPEL-IDENTITY-R123-20261119 -->

<!-- UNIT-NAME-STRIP-GEOMETRY-R124-20261119 -->
Thirty settled unit border refreshes remove 360 size and point writes per frame with class and spec icons plus their two dividers in the desktop replay. Group chrome still paints current identity and role information. Native join and leave timing remain pending.
[Matched validation](validation/unit-name-strip-geometry-2026-11-19.json).
<!-- /UNIT-NAME-STRIP-GEOMETRY-R124-20261119 -->

<!-- BORDER-POSE-SAMPLES-R125-20261119 -->
Matching prepared roster layouts share validated source-coordinate arrays through the existing regional renderer. Current color and opacity still follow the live source. Native join and leave timing remain pending.
[Matched validation](validation/border-pose-samples-2026-11-19.json).
<!-- /BORDER-POSE-SAMPLES-R125-20261119 -->

<!-- BORDER-PREPARED-DRAW-R126-20261119 -->
Warm roster reflows share compiled tile geometry. Current alpha, material and layer checks still run, and changed regions use the existing planner. Native membership latency remains pending.
[Matched validation](validation/border-prepared-draw-2026-11-19.json).
<!-- /BORDER-PREPARED-DRAW-R126-20261119 -->

<!-- BORDER-DRAW-INPUTS-R127-20261119 -->
The junction draw path compares and retains matching public inputs for any regional layout. The modeled roster relocation had no junction descriptors and showed no savings from this change. Native group membership latency remains pending.
[Matched validation](validation/border-draw-inputs-2026-11-19.json).
<!-- /BORDER-DRAW-INPUTS-R127-20261119 -->

<!-- BORDER-SPRITE-REUSE-R128-20261119 -->
Eight relocations of four party frames with internal dividers remove 704 type 1 and 768 type 2 per-sprite binding tables in the desktop replay. Native group membership timing remains pending.
[Matched validation](validation/border-sprite-reuse-2026-11-19.json).
<!-- /BORDER-SPRITE-REUSE-R128-20261119 -->

<!-- ROSTER-ROLE-CHROME-R129-20261119 -->
Twenty settled role refreshes across player, target and focus reduce modeled texture writes from 3,120 to zero. Matched geometry is identical in the five paired runs. Leader changes and leaving the group still update the status strip. Native join and leave timing remain pending.
[Matched validation](validation/roster-role-chrome-2026-11-19.json).
<!-- /ROSTER-ROLE-CHROME-R129-20261119 -->

<!-- BORDER-PARENT-GEOMETRY-R132-20261119 -->
In both border types, six modeled moves of four roster frames with internal dividers use 72 owner getter calls, down from 456. Sampled joins match across the six moves. Real membership latency is pending.
[Matched validation](validation/border-parent-geometry-2026-11-19.json).
<!-- /BORDER-PARENT-GEOMETRY-R132-20261119 -->

<!-- BORDER-POSE-TOPOLOGY-R133-20261119 -->
In six modeled roster position changes with extra dividers, the median scalar check count moves from 7,553 to 2,693. Actual membership latency remains pending.
[Matched validation](validation/border-pose-topology-2026-11-19.json).
<!-- /BORDER-POSE-TOPOLOGY-R133-20261119 -->

<!-- BORDER-FALLBACK-CONTEXT-R134-20261119 -->
Four prepared party unit outlines enter and leave the modeled layout twice. The geometry planner uses 48 old and new group extents to obtain the same scoped rectangle unions, down from 160 piece visits. Actual membership latency remains pending.
[Matched validation](validation/border-fallback-context-2026-11-19.json).
<!-- /BORDER-FALLBACK-CONTEXT-R134-20261119 -->

<!-- BORDER-ADMISSION-R135-20261119 -->
Four modeled party-linked and raid-linked outline changes halve the registered source eligibility scans. Geometry capture and sampled scope output remain the same. Actual membership latency remains pending.
[Matched validation](validation/border-admission-2026-11-19.json).
<!-- /BORDER-ADMISSION-R135-20261119 -->

<!-- BORDER-LAYER-PLAN-R136-20261119 -->
Across four modeled party-linked or raid-linked geometry transitions, the regional layer union creates 44 records, down from 276. Actual membership latency remains pending.
[Matched validation](validation/border-layer-plan-2026-11-19.json).
<!-- /BORDER-LAYER-PLAN-R136-20261119 -->

<!-- BORDER-SNAPSHOT-COPY-R137-20261119 -->
Across four modeled party-linked or raid-linked geometry transitions, structural copying allocates zero duplicate source bounds. The archived path makes 192 copies. Actual membership latency remains pending.
[Matched validation](validation/border-snapshot-copy-2026-11-19.json).
<!-- /BORDER-SNAPSHOT-COPY-R137-20261119 -->

<!-- BORDER-POSE-REGISTRATION-R138-20261119 -->
Prepared party and raid-linked layout pairs survive an unrelated decorative registration or removal. In both styles four later modeled transitions need zero solves and plans. Actual membership latency remains pending.
[Matched validation](validation/border-pose-registration-2026-11-19.json).
<!-- /BORDER-POSE-REGISTRATION-R138-20261119 -->

<!-- BORDER-EMPTY-FRAGMENTS-R139-20261119 -->
Four modeled changes in group-linked rectangle availability skip 148 visits for nonexistent fallback rectangles. Four modeled roster movements skip 196 such visits in each mode. Live membership latency remains pending.
[Matched validation](validation/border-empty-fragments-2026-11-19.json).
<!-- /BORDER-EMPTY-FRAGMENTS-R139-20261119 -->

<!-- RAID-ROSTER-SAMPLE-R140-20261119 -->
One legacy raid roster sample supplies group occupancy and tank or assist placement. The 40-member desktop replay drops from 194 roster-row reads to 40 with the column enabled and from 114 to 40 with it disabled. The matching player-slot reads fall from 117 or 77 to one. The modeled compact party still reads no raid rows. Visible group ordering and position, MT/MA visibility and bindings match the archived behavior.
[Matched validation](validation/raid-roster-sample-2026-11-19.json).
<!-- /RAID-ROSTER-SAMPLE-R140-20261119 -->

<!-- RAID-GRID-RECTANGLE-R141-20261119 -->
Compact raid border refreshes confirm retained bounds with a single rectangle read. Eight five-cell leave and return transitions reduce geometry getter calls from 1,200 to 360 in both modeled row-overlap arrangements. Each newly visible or changed cell still uses exact native edge getters. In eight unchanged-position rebinds, geometry getter calls fall from 1,280 to 320. Native group event timing remains pending.
[Matched validation](validation/raid-grid-rectangle-2026-11-19.json).
<!-- /RAID-GRID-RECTANGLE-R141-20261119 -->

<!-- RAID-RANGE-BURST-R142-20261119 -->
Compact-cell lifecycle callbacks share one range discovery per queued border update. A modeled 40-cell join and leave reduce pool searches from 160 to two with native range events and from 120 to two with fallback range. When only the range event fails, required event registrations fall from 1,840 to 920. The five-cell replay uses two searches, down from 20 or 15. Immediate reveal, periodic range and required route recovery retain their owners. Native timing remains pending.
[Matched validation](validation/raid-range-burst-2026-11-19.json).
<!-- /RAID-RANGE-BURST-R142-20261119 -->

<!-- RAID-JOIN-INDEX-R143-20261119 -->
Aligned compact groups locate joined edges by exact row and column coordinates. The first 40-cell border pass avoids 660 tolerance calculations and two sorts. Eight aligned five-cell departures and returns avoid 4,740 tolerance calculations and 16 sorts in both overlap models. The compact five-cell layout removes 30 tolerance checks on first appearance. Both paths match the archived seam flags, including signed fractions, partial groups, mixed spans and duplicate origins.
[Matched validation](validation/raid-join-index-2026-11-19.json).
<!-- /RAID-JOIN-INDEX-R143-20261119 -->

<!-- BORDER-ANCHOR-BURSTS-R144-20261119 -->
Settled anchor batching reduces modeled point-count queries from 180 to 60 in twelve five-frame transitions and from 480 to 160 in four forty-frame transitions. Current group tracking and compact roster rendering retain their existing scheduling.
[Matched validation](validation/border-anchor-bursts-2026-11-19.json).
<!-- /BORDER-ANCHOR-BURSTS-R144-20261119 -->

<!-- PARTY-INDICATOR-PASS-R147-20261119 -->
One shared text refresh and one final indicator layout now cover an ordinary party roster paint. Four settled batches reduce text passes from eight to four and indicator layouts from twelve to four. The three tracked role icons stop making 96 redundant geometry writes in the same replay. Three archive and candidate pairs agree across five model clients. Real role changes repack the top-left stack and repair anchor, size and depth.
[Matched validation](validation/party-indicator-pass-2026-11-19.json).
<!-- /PARTY-INDICATOR-PASS-R147-20261119 -->

<!-- RAID-EXTRA-DRIVER-RETRY-R148-20261119 -->
Roster recovery keeps prepared optional pet and target frames when one paging driver fails. A single rejected route goes from 46 driver attempts and 278 protected writes to one attempt and eight writes in the desktop replay. A repeat notification while the same provider is unavailable performs zero extra protected writes. A configuration change or recovery of the full paging provider still installs every required driver. Combat-release recovery drops from 276 to six modeled writes for one cell.
[Matched validation](validation/raid-extra-driver-retry-2026-11-19.json).
<!-- /RAID-EXTRA-DRIVER-RETRY-R148-20261119 -->

<!-- BORDER-ROLE-ANCESTRY-R149-20261119 -->
Border role classification shares public parent chains for the current regional geometry pass. Six modeled roster moves avoid 906 classification parent reads per border type. Later changes still sample current ancestry.
[Matched validation](validation/border-role-ancestry-2026-11-19.json).
<!-- /BORDER-ROLE-ANCESTRY-R149-20261119 -->

<!-- RAID-CHROME-LOOKUP-R153-20261120 -->
Native selection suppression now checks grouped raid frame names before walking the active party pool. Two modeled passes over forty raid cells avoid eighty pool enumerations and four hundred entry visits. Anonymous frames retain pool recognition, including when the name is private or inaccessible. The native route is exercised with source-pinned selection handlers for five client families.
[Matched validation](validation/raid-chrome-lookup-2026-11-20.json).
<!-- /RAID-CHROME-LOOKUP-R153-20261120 -->

<!-- RAID-STABLE-PAINT-R154-20261120 -->
Full compact raid roster paint retains native ranges and visibility when the widgets report the expected values. A forty-cell pass avoids 320 visibility setters and 80 health or power range setters. A five-cell pass avoids 40 visibility setters and 10 range setters. Current or unreadable changes retain the protected writer path. Five client models matched archived behavior on current health, power, leader and dispel outcomes.
[Matched validation](validation/raid-stable-paint-2026-11-20.json).
<!-- /RAID-STABLE-PAINT-R154-20261120 -->

<!-- RAID-AURA-RETIREMENT-R167-20261120 -->
Prepared group cells remember unit bindings through cleanup. In the forty-cell replay, two cleanup calls per frame issue 120 native SetUnit calls and 120 native Hide calls, down from 400 of each. In the five-cell replay each count falls from 50 to 15. The second cleanup performs zero native owner writes. Active subscriptions match on join and rejoin. Private descendant access remained blocked in the cleanup fixture. Native hitch timing remains pending.
[Matched validation](validation/raid-aura-owner-retirement-2026-11-20.json).
<!-- /RAID-AURA-RETIREMENT-R167-20261120 -->

<!-- RAID-UNIT-EVENT-RETIREMENT-R169-20261120 -->
Compact group frames keep completed event clears through duplicate unbind and hide callbacks. In matched leave and rejoin replays, native event reset calls fall from 15 to five for a five-person party and from 120 to 40 for a forty-person raid. Active event subscriptions and registration counts match. The fixture checks normal rejoin, delegated power events, write failures and reentry.
[Matched validation](validation/raid-unit-event-retirement-2026-11-20.json).
<!-- /RAID-UNIT-EVENT-RETIREMENT-R169-20261120 -->

<!-- PARTY-ROSTER-DISPATCH-20261120 -->
The existing raid event handler queues one settled paint for normal party members, pets, and targets. In a twenty-event desktop burst with eight active member/pet slots, dispatch calls fall from 180 to 20 and synchronous visibility reads from 160 to zero. The same eight paints, cast refreshes and range wake occur in one deferred callback. Optional target and disabled-layout scenarios were also checked.
[Matched validation](validation/party-roster-dispatch-2026-11-20.json).
<!-- /PARTY-ROSTER-DISPATCH-20261120 -->

<!-- BORDER-ROSTER-BOUNDS-R178-20261120 -->
Prepared roster reflows share a bounding box among eligible textures in the same junction. Twelve warmed reflows cut modeled box calls from 5,664 to 4,236 and from 9,864 to 7,368 in border-style order. The first two compiles keep the original setter counts. First prepared restores and one unseen layout after warming also use fewer box calls. Strip crossings match the original setter counts. Desktop elapsed comparisons were mixed. Timings from a native roster change remain pending.
[Matched validation](validation/border-roster-bounds-2026-11-20.json).
<!-- /BORDER-ROSTER-BOUNDS-R178-20261120 -->

<!-- PARTY-TARGET-TRAIL-20261120 -->
Party-target roster refreshes keep the existing damage trail when the same readable unit and health sample remain current. Sixty modeled roster batches that change one of four targets reduce trail resets from 240 to 60 and hide calls from 1,440 to 360. With all four targets unchanged those counts fall to zero. Main health and color paint remain current. Replacements use their existing fresh identity read after reset, including one extra GUID read when the replacement has the same health. Desktop elapsed gains are small and vary by scenario.
[Matched validation](validation/party-target-trail-2026-11-20.json).
<!-- /PARTY-TARGET-TRAIL-20261120 -->

<!-- PARTY-STATUS-OWNER-20261120 -->
The normal party roster paint keeps its portrait indicator anchors through the shared update. Sixty paired roster batches reduce role position writes from 290 to 23 and level position writes from 360 to zero. Final visibility, positions and level label paint match. The master-loot check uses only the assigned party slot. Sixty party name fits with a public host width and a single level label remove 120 unused outer-width reads and 120 level text measurements.
[Matched validation](validation/party-status-owner-2026-11-20.json).
<!-- /PARTY-STATUS-OWNER-20261120 -->

<!-- BORDER-PANEL-INPUTS-R186-20261120 -->
The nearby-panel alignment phase keeps matching records during unit reflows. The stable seven-panel replay still reads each rectangle on every pass. Sixty scans create no new panel records, down from 420. Live held-action crossings, rapid drops, group join and leave, seams and combat taint remain pending. Unchanged-panel scans in the desktop model establish the cost of that phase during unrelated HUD or unit reflows.
[Matched validation](validation/border-panel-inputs-2026-11-20.json).
<!-- /BORDER-PANEL-INPUTS-R186-20261120 -->

<!-- ROSTER-HOVER-DRIVER-20261120 -->
Stable mouse-only roster discovery now skips an action-bar binding scan. Thirty modeled bursts across each client profile go from 570 native binding reads to zero. Early registrations still sample each action binding once per scan, including keys after nil or empty results. Forty newly discovered raid cells cut binding reads from 1,179 to 600 in the Forever model and from 419 to 120 in the Era model. Mouse and wheel routes, discovery and protected write counts match. Only spell-hover routes qualify for the native unit-exists driver. When the last spell-hover route is removed under the mouse, the same out-of-combat lifecycle parks that driver. Public routing detection still recognizes ordinary mouse and wheel bindings. Full binding and Edit Mode refreshes, frame registration and combat deferral retain their existing owners. Current live invite, leave, raid conversion timing and combat taint remain pending. Full action-strip, border seams, minimap and combat exit acceptance remain part of the active roadmap.
[Matched validation](validation/roster-hover-driver-2026-11-20.json).
<!-- /ROSTER-HOVER-DRIVER-20261120 -->

<!-- NAMEPLATE-RANK-ROSTER-20261120 -->
Nameplate threat refreshes now share successful public group identity reads for one pass. With 32 visible plates, a modeled party entry uses 10 GUID queries instead of 320. The raid case uses 82 instead of 2,624. A confirmed tanking player already has rank one, allowing the same raid replay to use 64 detailed threat queries instead of 2,592. Matched text, tint and plate lookups remain equal in all three client models. Live party and raid join or leave timing and native secret-value and combat checks remain pending. Action strip, border seams, embedded minimap and combat exit acceptance remain open for the wider goal.
[Matched validation](validation/nameplate-rank-roster-2026-11-20.json).
<!-- /NAMEPLATE-RANK-ROSTER-20261120 -->
