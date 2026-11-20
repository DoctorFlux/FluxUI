# Border builder locality goal

18 November 2026: the user requests much lower border-build spikes on group
invite/leave, action drag/drop, embedded-minimap toggles and **any HUD change**,
while the visible update remains immediate. This goal is active; existing
visual and static-paint requirements in CONNECTED_BORDERS still apply.

Follow the [HUD performance roadmap](HUD_PERFORMANCE_ROADMAP.md) for current
priorities, completed work and the remaining checks.

| ID | Required outcome | Acceptance |
|---|---|---|
| BBL-01 | Local geometry changes rebuild their affected joins and neighbours, preserving unrelated prepared output. | Before/after actual-source geometry, solve, plan, draw and retirement work; untouched-region output and resources retained. |
| BBL-02 | Group join/leave and party/raid transitions reuse prepared unit chrome wherever geometry is unchanged. | Real party/raid cases, first and repeated transitions, no missing outlines/paint/secure state. |
| BBL-03 | Action drag/drop and button expansion update only changed strip/grid geometry and contacts. | Occupancy-only paint has no solve; real expansion/detachment has correct T/X, caps and strip-owned seams. Input IDs/routes unchanged. |
| BBL-04 | Embedded-minimap toggle and side-button count/scale changes retain window bounds and update affected contacts immediately. | First and repeated toggle/side-button cases, exact dimensions and border comparison. |
| BBL-05 | Combat/dispel/class/private color and target/focus visibility remain paint-only on prepared geometry. | Existing restricted-value and no-rebuild regressions; native combat/taint acceptance separate. |
| BBL-06 | Avoid a new delay, polling driver, mask dependency or asynchronous partial reset. | Existing scheduler ownership; atomic finished replacement; no new idle work or per-change timer chain. |
| BBL-07 | Preserve both border styles, rounded corners, shadows, multi-color joins, mini overlays and detached outlines. | Exact old/current geometry/material/opacity output comparisons plus native screenshots. Decorative changes add no controller focus or input route. |
| BBL-08 | Measure actual costs and retain exact before/candidate identities and failed experiments. | Matched bounded Lua CPU/allocation/native-call evidence and native watch captures. Mock counts never certify FPS, pixel parity or taint. |
| BBL-09 | Keep Retail, Forever and Classic progression support, settings, commands and integrations. | Existing capability guards and private-value boundaries; target-specific native acceptance recorded separately. No new user option or visible/localized label is required. |

Initial R66 finding (superseded by R67/R69): preflight records local pending objects, but one changed
snapshot still causes full ReadLayout, Solve, source-plan reconstruction and
global commit/retirement. Existing branch/fallback/draw caches reduce later work
without narrowing this rebuild scope. CF64's historical105.54ms build is useful
attribution, not a baseline of the current exact loaded source.

Implementation sequence:

1. Retain a source/history/settings-metadata checkpoint and reproducible scoped
   before scenarios; identify work by phase and changed owner.
2. Add bounded locality inside the existing renderer, with fallback to the
   existing full transaction for unsafe/global changes. Select the first slice
   from measured work; preserve current native/privacy validation semantics.
3. Exercise the four trigger families, visibility/material/scale/reparent cases,
   rollback and global settings changes. Reject regressions and unsafe reuse.
4. Run a stable combined gate, then coordinate Mario-only native loading and
   captures. Do not touch another owner's reservations, client or profiler state.

Checkpoint: main6b444eba4573092b57919ee3e497d86d2ebb3ece, dirty shared tree.
External `builder-locality-checkpoint-20261118.json` records exact source hashes,
archive and dated history coverage. No runtime change at that initial checkpoint. Initial renderer is
`native-unit-rgb-r66`; its label does not prove exact loaded-source adoption.
Implementation/design remains under investigation. All BBL rows are OPEN;
native availability and acceptance are pending. Existing direct-implementation
and in-game testing preferences remain; no new mock-up/approval gate is needed.


18 November prototype progress: the existing solver/planner was tested through
a bounded regional query and exact output scissor, using both canonical styles,
three scales, mixed material colors, independent units and rounded aura joins.
34,992 artwork samples matched the full source renderer (maximum numerical
premultiplied error 3.51e-14). Six moved-divider cases retained 34/48/60
untouched cell arrays and replanned four cells in one regional batch. These are
source-model observations, not GPU, native FPS, taint or total-runtime acceptance.
The initial hidden-parent evaluator failure is retained externally; native
parent visibility must continue to govern the finished fields.

The planning block is now extracted into the private `_PreparePlan` helper,
without changing its existing full transaction. This enables a regional caller
to reuse the exact cap/shadow/fallback policies. Runtime locality was not yet
installed at that intermediate checkpoint; its resource, native-paint, retirement and rollback contracts must
pass before admission. External receipt: `builder-spatial-prototype-20261118.json`.


Direct Lua implementation — R67 (`regional-render-r67`)

The user explicitly requested direct Lua fixes on18November. Core now retains
128-physical-pixel output regions, reads only the changed registered parents and
anchor/ancestor dependency closure, and runs the existing solver/planner on the
nearby groups. Registration/removal carries the old parent explicitly. Unchanged
public raw segments, native fields and listener/pool arrays retain identity.
Color, visibility, public/private alpha and approved native unit RGB still use
the existing native sinks; generic unsupported private paint keeps conservative
retirement and preserves its just-written native source. Public recovery marks
its owner dirty even when the geometry snapshot itself is equal.

Listener membership uses indexed swap removal/addition for changed cells; no
whole-HUD field/index publication remains. Canvas level requirements reconcile
from the small logical-operation metadata rather than walking native fields.
Global settings/display changes, unsupported sources, foreign geometry getters
and budget failures retain the original full transaction. Query/availability
memos remain phase-only; retained geometry contains resolved public decorative
numbers, never a cached private/unavailable marker. Native mask operations are
observed read-only; no masks are allocated, attached or removed by the builder.

Rounded outside caps retain their original native artwork. Cast icon/body
sections keep one small unsplit region per existing connected scope, including
swing/Shoot users of that geometry. This fixes an observed high-scale crest gap
from unnecessarily splitting the small cast section across the spatial grid.
The existing20Hz drag wake and synchronous CommitLayout owner are retained;
there is no new timer, ticker, input route, protected attribute or settings UI.

Validation is in progress on the final source. Differential artwork/ownership,
registration/removal, private paint recovery, indexed listeners and rollback are
covered in `tests/border_locality.lua` and the expanded native/private paint
models. These are actual-source desktop checks, not native GPU/FPS/taint proof.
All BBL rows remain OPEN for their stated native scenario acceptance. The goal
is ACTIVE. No game input, profiler preference change, publication or native lease
has been made by this owner. Do not replay other owners' controllers.


Final R67 checkpoint:68 focused scripts PASS on stable Core;1218 Lua files
parse;226 Core prototypes max51 (limit60). Actual source/index/claim/rollback
and source-field comparisons retain34/46/60 regions, update4 and query2 model
rectangles versus26. Expanded models pass600 native-RGB,640 native-alpha and
2428 unsupported-private checks; cast crest/cap sampling passes13522 at scales
.75..3 and both alignments. Same-source full-dispatch controls are not a native
baseline. Desktop alternating CPU medians4/5ms versus6/7ms do not certify native
latency. All test/benchmark jobs are finished. Exact hashes and retained failed
experiments: [R67 evidence](validation/border-regional-render-2026-11-18.json).
Next: coordinated native first/repeated group/raid, combat exit, drag/expansion
and embedded-minimap/side-button scenarios. BBL native acceptance remains OPEN.


User acceptance,18November: "The hitches are much better", followed by
"No noticeable hitches remain" when asked explicitly about residual hitches.
Goal COMPLETE on the direct implementation, exact-source desktop gate and that
user acceptance. Earlier OPEN/ACTIVE notes above are historical. This feedback
is not an independent loaded-hash/build capture or an event-by-event native/FPS,
GPU or all-client taint certification. Those broader checks remain unperformed;
no further runtime change is required for the accepted border-builder task.


Party follow-up18November: user corrects acceptance: party join/leave still
hitches. BBL-10 audits all roster consumers and removes unscoped material
repaints while retaining combat deferral/private-value boundaries. R67 general
improvement stands; party-specific latency is OPEN. No new native probes/input
are requested; fix Lua directly and verify in existing models.


BBL-10 implementation: `party-paint-r68` directly updates FluxBorder's two
unit-material classifiers to use registered ownership buckets. Owned source
ancestors and detached owner aliases are indexed during registration/adoption;
existing observed SetParent maintains only the affected scope. Removed frames
release membership. No cached GUID/class/private unit data. Border without the
observer retains live traversal. All inspected owner annotations precede source
registration. External raw owner changes can use RefreshPaintOwners explicitly.

R68 actual-source checks:548 versus31844 model parent queries for the four-member
classification replay, with identical material/RGBA/UV state;five alternating
pairs per style cover20transition rounds. Model CPU medians3/2ms versus61/60ms are
not native timings.77composed focused observations and1219syntax PASS;maximum51
captures. Existing party preview fixture needed its missing UpdateBorderColors
stub and now asserts pet preview paint. Runtime roster paths were preserved.
Native party join/leave and taint/FPS/GPU acceptance remain PENDING.
[Exact checkpoint, audit, source and results](validation/party-material-ownership-2026-11-18.json).


<!-- REGIONAL-PLAN-R69-20261118 -->
18 November: native R68 party join/leave still blocks `border.junctions` for
161.4/123.1ms. The161.39ms peak spends105.40ms planning with59active regions,
6changed; repeated target/focus availability reasons remain recorded. Direct
`regional-plan-r69` keeps complete source cuts/ownership but compiles branch and
fallback meshes only for changed output. Unchanged committed numeric compile
records now survive partial publication, under existing storage limits.

78focused scripts and1220Lua syntax PASS;226Core prototypes maximum51 captures.
Repeated actual-source desktop moves compile6 fresh meshes versus24 per sequence;
matched median CPU44->29ms/style1 and53->34ms/style2 for six moves. These are model
measurements, not native latency/FPS/taint/GPU acceptance. R69 native party checks
remain OPEN; R68 is confirmed insufficient. No native input/profiler/settings or
protected routing changes; other owners preserved. Test/benchmark jobs stopped.
[Exact sources and evidence](validation/border-regional-plan-2026-11-18.json).
<!-- /REGIONAL-PLAN-R69-20261118 -->



<!-- ROSTER-TRANSITIONS-R70-20261118 -->
18 November: user reports R69 still hitches, authorizes full party/raid join/leave
review/rework, and is away: **ask no questions or native tests**. R70
`roster-layout-r70` changes22runtime files after reviewing40signal owners.
Prepared unit-root snapshots now observe public authored layout rather than
transient computed bounds. Regional drawing uses the existing guarded sprite
reuse with per-cell epochs and shared cache bounds.17player-only spec consumers
ignore confirmed other units; unknown/private/alias handling stays conservative.
Raid spell updates reuse aura paint; unchanged secure attributes skip writes
while every native roster execution/reference reconciliation remains.

179unique focused scripts PASS;1225stable syntax checks plus2final fixture parses;
1427prototypes maximum51captures. Five archived negative controls rejected.
A pre-existing1200character smoke window missed the unchanged color helper at
1286; its routine boundary is corrected and helper/raw-key checks retained.
Regional setter checks3531->1803/type1 and6393->2793/type2 atscale1/four moves;
other scales/art/paint/index checks pass. These are desktop results only.
Native hitch/GPU/FPS/taint acceptance remains OPEN. No native input/profiling or
settings changes; preserve other owners and saved captures.
[Exact sources, audit and evidence](validation/roster-transitions-2026-11-18.json).
<!-- /ROSTER-TRANSITIONS-R70-20261118 -->

<!-- ROSTER-GEOMETRY-PORTRAITS-R71-20261118 -->
R71 keeps the R70 regional border renderer. Regular raid layout now skips matching secure anchors and width and only reacts to the first child of each regular header. This cuts redundant upstream mutations arriving at layout observers. Normal party roster paint retains confirmed live 3D models and coalesces duplicate leadership and loot updates. Matched desktop replay confirms identical modeled layout and presentation. Native hitch improvement and visual/taint acceptance remain pending.
[R71 source pins, replay counts and validation](validation/roster-geometry-and-portraits-2026-11-18.json).
<!-- /ROSTER-GEOMETRY-PORTRAITS-R71-20261118 -->

<!-- ROSTER-RESTRICTED-PARSER-R72-20261118 -->
Raid-cell connected trim now evaluates each pair once, then paints only cells whose ownership flags, live texture set or power-divider state changed. The same edge tolerances and native drawing behavior were checked in the matched raid replay. The shared HUD border builder remains outside this change.
[R72 source and validation evidence](validation/roster-restricted-parser-2026-11-18.json).
<!-- /ROSTER-RESTRICTED-PARSER-R72-20261118 -->

<!-- PARTY-ROSTER-LOCALITY-R73-20261119 -->
R73 limits party events upstream of border work. The settled player-style party path leaves hidden compact headers alone. The raid-style party path skips the hidden roster columns and MT/MA attachment walk. Real geometry and explicit configuration continue through the existing observers.
[R73 evidence](validation/party-roster-locality-2026-11-19.json).
<!-- /PARTY-ROSTER-LOCALITY-R73-20261119 -->

<!-- GROUP-RENDER-R74-20261119 -->
R74 shares completed dependency branches within each observer refresh. A graph revision clears this reuse after a rewire. Panel alignment checks current eligible bounds, scale, priority and placement policy before reusing the previous result. Actual layout changes still reach the existing local border solver, including changed bounds, removed panels and newly registered frames.
[R74 evidence](validation/group-render-work-2026-11-19.json).
<!-- /GROUP-RENDER-R74-20261119 -->

<!-- ROSTER-REGION-ROUTING-R75-20261119 -->
Dirty output regions take only intersecting piece and operation lists. Piece ownership is indexed once. The query keeps expanded-tile contact eligibility with scalar comparisons. Cast scopes remain separate, and a triangle can reference a source centered outside its output region. Modeled mixed-scale and direct archived-source replays cover existing geometry and clipping behavior.
[R75 evidence](validation/roster-region-routing-2026-11-19.json).
<!-- /ROSTER-REGION-ROUTING-R75-20261119 -->

<!-- ROSTER-RETURN-PLANS-R76-20261119 -->
Retain a displaced numeric branch and fallback plan only for a contact still present in the current successful commit. Active and alternate plans share the retention ceilings. Fresh native geometry and artwork checks still precede reuse. Compare both art styles, masks, UV and paint changes, source removal, and recovery after a failed commit.
[R76 evidence](validation/roster-return-plans-2026-11-19.json).
<!-- /ROSTER-RETURN-PLANS-R76-20261119 -->

<!-- ROSTER-LOCAL-FALLBACK-R77-20261119 -->
R77 separates fallback cells that belong to specific junctions from parallel edge backups. The current render inputs and order are preserved. Numerical guard snapshots retain a single copied representation and preserve the conservative resource limits. Source routing and primitive output comparisons cover the first layout switch and subsequent switches.
[R77 evidence](validation/roster-local-fallback-2026-11-19.json).
<!-- /ROSTER-LOCAL-FALLBACK-R77-20261119 -->

<!-- ROSTER-PREPARED-LAYOUT-R78-20261119 -->
R78 reuses the existing public geometry index in each regional update. Immutable retained groups skip piece comparisons. Cast bounds include old and new pieces when the cast region changes. Previously selected operations retain their order when combined with unaffected junctions.
[R78 evidence](validation/roster-prepared-layout-2026-11-19.json).
<!-- /ROSTER-PREPARED-LAYOUT-R78-20261119 -->

<!-- REGIONAL-CLIPPING-R79-20261119 -->
R79 avoids clipping a regional primitive against planes that already contain it. A split keeps the original processing order for newly interpolated vertices. The action strip updates its attached grids and panels before the envelope and the local junction commit.
[R79 evidence](validation/regional-clipping-2026-11-19.json).
<!-- /REGIONAL-CLIPPING-R79-20261119 -->

<!-- GRID-ENVELOPE-R80-20261119 -->
R80 finishes shared side-panel layout, Info and the envelope before the strip’s local border commit. Cursor hover samples schedule a real layout edge while leaving existing fallback checks in place. Standalone grid and pet calls retain their own completion paths.
[R80 evidence](validation/grid-envelope-2026-11-19.json).
<!-- /GRID-ENVELOPE-R80-20261119 -->

<!-- INDEXED-REGIONS-R81-20261119 -->
R81 shares the dirty tile index between operation selection and routing. Cast scopes still select in their own plane, and strict overlap still determines physical HUD output. Retained cells keep their solved references. Publish the shared lookup once per selected input array.
[R81 evidence](validation/indexed-regions-2026-11-19.json).
<!-- /INDEXED-REGIONS-R81-20261119 -->

<!-- INDEXED-NEIGHBORS-R82-20261119 -->
R82 shares the dirty-cell index across padded source selection, operation membership and paint routing. Keep the original per-tile comparison for fractional boundaries and copy complete selected groups in source order.
[R82 evidence](validation/indexed-neighbors-2026-11-19.json).
<!-- /INDEXED-NEIGHBORS-R82-20261119 -->

<!-- RAID-CELL-NEIGHBORS-20261119 -->
The compact raid border painter owns a separate shared-edge calculation. It prunes distant row and column contacts and preserves the existing paint ownership. The source comparison covers both one- and four-pixel row overlap.
[Raid cell evidence](validation/raid-cell-neighbors-2026-11-19.json).
<!-- /RAID-CELL-NEIGHBORS-20261119 -->

<!-- SOURCE-RENDER-CONTEXT-R83-20261119 -->
Resolve source parents and canvas geometry once per operation. Keep role-sensitive raised strip and retained unit parents distinct. Regional and fallback paint paths keep the same field output and rebuild bounds.
[R83 evidence](validation/source-render-context-2026-11-19.json).
<!-- /SOURCE-RENDER-CONTEXT-R83-20261119 -->

<!-- FRAGMENT-OWNERS-R84-20261119 -->
Plan fragment canvas owners once per source group. Existing plans include earlier contacts, while plans created in the owner phase maintain the original contact suffix. The model checks exact owner sets and sampled geometry in both styles.
[R84 evidence](validation/fragment-owners-2026-11-19.json).
<!-- /FRAGMENT-OWNERS-R84-20261119 -->

<!-- PREPARED-LAYERS-R85-20261119 -->
R85 shares public participant layers and repeated fragment owner summaries for one regional draw. Decorated canvases retain live validation and the default full/fallback renderer retains live source resolution.
[R85 evidence](validation/prepared-layers-2026-11-19.json).
<!-- /PREPARED-LAYERS-R85-20261119 -->

<!-- TILE-FIELD-REJECTION-R86-20261119 -->
R86 avoids allocating polygons for fully disjoint field/tile projections. Boundary contact and matching source or fallback references are covered by the regional oracle.
[R86 evidence](validation/tile-field-rejection-2026-11-19.json).
<!-- /TILE-FIELD-REJECTION-R86-20261119 -->

<!-- STRIP-POSE-TOPOLOGY-R87-20261119 -->
R87 retains a bounded pair of compiled strip poses from normal expand/collapse commits. A warm match skips solving and planning, validates artwork, and uses live paint sinks. Real changes rebuild the affected region. Both styles retain coverage in the replay.
[R87 evidence](validation/strip-pose-topology-2026-11-19.json).
<!-- /STRIP-POSE-TOPOLOGY-R87-20261119 -->

<!-- STRIP-CHROME-MINIMAP-ROSTER-20261119 -->
Alongside the R87 prepared shell, the held-action path reuses stable artwork within the action buttons. The placed size is authoritative for same-turn paint. Changed, revealed and explicitly restyled buttons use the existing skin.
[Strip and minimap evidence](validation/strip-chrome-minimap-roster-2026-11-19.json).
<!-- /STRIP-CHROME-MINIMAP-ROSTER-20261119 -->

<!-- PREPARED-STRIP-SAMPLING-R88-20261119 -->
Strip pose replay retains fragment UVs and triangle/quad UV arrays after first use. A restore still validates the material, coordinates and masks. Fallback plans with no rectangles no longer prepare draw state.
[Border sampling evidence](validation/prepared-strip-sampling-2026-11-19.json).
<!-- /PREPARED-STRIP-SAMPLING-R88-20261119 -->

<!-- BORDER-SETTERS-THREAT-ROSTER-R89-20261119 -->
Scalar setter matches compare values directly. Normal fragments, fallback fragments and mesh fields unpack their immutable samples only for a texture-coordinate write. Both styles match the prior visible fields in the strip and synthetic dock models.
[Setter and threat roster evidence](validation/border-setters-threat-roster-2026-11-19.json).
<!-- /BORDER-SETTERS-THREAT-ROSTER-R89-20261119 -->

<!-- FINAL-STRIP-UNIT-ANCHORS-R90-20261119 -->
Settle the strip and side-panel envelope before reanchoring player and target on a held-action crossing. A matching public screen point stays in place. Unchanged target placement keeps its existing internal chrome.
[Strip unit anchoring evidence](validation/final-strip-unit-anchors-2026-11-19.json).
<!-- /FINAL-STRIP-UNIT-ANCHORS-R90-20261119 -->

<!-- STRIP-GRID-PACKING-R91-20261119 -->
Both extra grids preserve matching packed slots and faces during strip crossings. Info and the neighboring envelope still run within the normal border transaction, including when neither grid resizes.
[Strip grid packing evidence](validation/strip-grid-packing-2026-11-19.json).
<!-- /STRIP-GRID-PACKING-R91-20261119 -->

<!-- STRIP-PANEL-SETTLE-R92-20261119 -->
Resolve the Trinket Menu squeeze, Info placement and envelope fills in the strip layout transaction. Use the current frame identity when deciding whether envelope anchors can stay. Stable relative trinket gap anchors track their host movement.
[Strip panel settlement evidence](validation/strip-panel-settle-2026-11-19.json).
<!-- /STRIP-PANEL-SETTLE-R92-20261119 -->

<!-- STRIP-LAYER-COMMIT-R95-20261119 -->
A regional commit uses the final member-layer requirement for each shared canvas at first use. This reduces repeated native layer reads during warm drag crossings and localized group changes. Full fallback rendering keeps its normal layer path.
[Matched validation](validation/strip-layer-commit-2026-11-19.json).
<!-- /STRIP-LAYER-COMMIT-R95-20261119 -->

<!-- STRIP-RELATIVE-ANCHORS-R96-20261119 -->
Strip crossings retain native button and envelope anchors that already match. The border continues following grid and window movement through those points and the existing regional transaction. A new peer or changed offset binds before the junction update.
[Matched validation](validation/strip-relative-anchors-2026-11-19.json).
<!-- /STRIP-RELATIVE-ANCHORS-R96-20261119 -->

<!-- STRIP-SLOT-SAMPLING-R98-20261119 -->
The strip measures and places buttons from the same per-pass occupancy. Placement starts after secure mapping and preserves the existing immediate grid and border transaction.
[Matched validation](validation/strip-slot-sampling-2026-11-19.json).
<!-- /STRIP-SLOT-SAMPLING-R98-20261119 -->

<!-- RAPID-STRIP-DROPS-R99-20261119 -->
An intermittent pickup or placement can resize the strip without a hover transition. Such layouts offer the current hover state to the existing regional transaction. Two shapes per state retain topology and compiled plan, with current material, level, geometry and footprint validation on reuse.
[Matched validation](validation/rapid-strip-drops-2026-11-19.json).
<!-- /RAPID-STRIP-DROPS-R99-20261119 -->

<!-- REGIONAL-FRAGMENT-READS-R100-20261119 -->
Regional tiles share public original texture parent and draw-layer samples and ancestry within one commit. Alpha and visibility ownership stay local to each tile. Cross-tile source suppression uses the existing single final publication.
[Matched validation](validation/regional-fragment-reads-2026-11-19.json).
<!-- /REGIONAL-FRAGMENT-READS-R100-20261119 -->

<!-- STRIP-JOIN-SOURCES-R101-20261119 -->
Junction paint reuses the public source parent sampled for original fragments. Its draw path can reuse the canvas resolved by the current draw descriptor after the layer has been applied. Fresh commits sample current parents and layers.
[Matched validation](validation/strip-join-sources-2026-11-19.json).
<!-- /STRIP-JOIN-SOURCES-R101-20261119 -->

<!-- REGIONAL-LAYOUT-INDEX-R102-20261119 -->
Keep per-group layout fingerprints and coarse immutable group bounds. The first and repeated reflows still admit the same exact neighbor edges and preserve particular cast planes. Affected and retained cells continue through the same synchronous renderer.
[Matched validation](validation/regional-layout-index-2026-11-19.json).
<!-- /REGIONAL-LAYOUT-INDEX-R102-20261119 -->

<!-- REGIONAL-TILE-MATERIALS-R103-20261119 -->
A local build reuses material decisions sampled by the planner and reads other materials when a tile actually needs them. Prepared strip poses still validate every dependency. Unused native caps keep their regular paint. Masked sources involved in a join still take the existing fallback.
[Matched validation](validation/regional-tile-materials-2026-11-19.json).
<!-- /REGIONAL-TILE-MATERIALS-R103-20261119 -->

<!-- REGIONAL-ROSTER-POSES-R105-20261119 -->
Keep up to two recent regional layouts for prepared party and raid geometry. The matcher verifies the same source identity, anchors, roles, tile footprint, material and applicable levels. Repeat matches skip solving and planning before the synchronous native commit. Larger groups still use the normal regional path whenever their neighborhood exceeds the retention limits.
[Matched validation](validation/regional-roster-poses-2026-11-19.json).
<!-- /REGIONAL-ROSTER-POSES-R105-20261119 -->

<!-- REGIONAL-BORDER-CUTS-R106-20261119 -->
An out-of-region cut leaves the current rectangle or fallback list in place. An actual intersection still uses the existing stroke and visibility partition order. Cold replays cover both styles and keeper visibility changes.
[Matched validation](validation/regional-border-cuts-2026-11-19.json).
<!-- /REGIONAL-BORDER-CUTS-R106-20261119 -->

<!-- HELD-ACTION-REFLOW-R107-20261119 -->
Prepared border descriptor visits fell to 990 from 3810 in type 1, 930 from 4284 in type 2 over twelve crossings. A genuine held-action crossing still applies the settled panel geometry in one transaction. The prepared recipes retain public geometry and blocker references. The existing draw path validates live source material and paint.
[Matched validation](validation/held-action-reflow-2026-11-19.json).
<!-- /HELD-ACTION-REFLOW-R107-20261119 -->

<!-- INDEPENDENT-BORDER-REGIONS-R108-20261119 -->
Each movement of one party member replaces one output region, compared with six to nine screen tiles. Hover replays retain all four party paint generations and plan half as many source segments. Retained output regions keep their paint listeners and live alpha/color. The compact raid border painter has its own topology and does not use these regions.
[Matched validation](validation/independent-border-regions-2026-11-19.json).
<!-- /INDEPENDENT-BORDER-REGIONS-R108-20261119 -->

<!-- COMPACT-RAID-SEAM-DELTAS-R109-20261119 -->
The compact raid joined-edge path retains unrelated sides when a single cell changes. Its separate painter keeps using current public edge geometry and the existing paint guard.
[Matched validation](validation/compact-raid-seam-updates-2026-11-19.json).
<!-- /COMPACT-RAID-SEAM-DELTAS-R109-20261119 -->

<!-- STRIP-BORDER-REFRESH-R112-20261119 -->
Regional selection shares the eligibility scan. The prepared raw geometry and its owner map publish together. Reflow compares that committed index and the owner map produced during the new geometry copy.
[Matched validation](validation/strip-border-refresh-2026-11-19.json).
<!-- /STRIP-BORDER-REFRESH-R112-20261119 -->

<!-- STRIP-HOVER-PAINT-R113-20261119 -->
Held-action crossings keep the existing settled border transaction and reuse unchanged button display. New size or placement is still repaired before that transaction.
[Matched validation](validation/strip-hover-paint-2026-11-19.json).
<!-- /STRIP-HOVER-PAINT-R113-20261119 -->

<!-- BORDER-VISIBILITY-FANOUT-R114-20261119 -->
Share fresh source availability during one fallback paint update and share verified gates among identical observer pairs during a prepared commit. The next event or commit reads its own source state.
[Matched validation](validation/border-visibility-fanout-2026-11-19.json).
<!-- /BORDER-VISIBILITY-FANOUT-R114-20261119 -->

<!-- BORDER-DRAW-GEOMETRY-R115-20261119 -->
A normal, fallback or junction field shares its anchor and size record. A previously confirmed rectangle keeps all four zero offsets. Polygon changes continue to compare the exact vertex IDs and offsets.
[Matched validation](validation/border-draw-geometry-2026-11-19.json).
<!-- /BORDER-DRAW-GEOMETRY-R115-20261119 -->

<!-- STRIP-VISIBILITY-R117-20261119 -->
Regional fallback visibility subscriptions are attached by tile. A changed region replaces its own lists. Native show, hide and opacity changes use one live visibility sample across every subscribed tile.
[Matched validation](validation/strip-visibility-2026-11-19.json).
<!-- /STRIP-VISIBILITY-R117-20261119 -->

<!-- STRIP-PAINT-INDEX-R121-20261119 -->
Eight warm cursor crossings with a held action reduce regional paint membership visits from 10,560 to 1,664 for type 1 and 12,264 to 1,640 for type 2. Global fallback continues using its plain lists, and regional input still uses the original paint and opacity guards.
[Matched validation](validation/strip-paint-index-2026-11-19.json).
<!-- /STRIP-PAINT-INDEX-R121-20261119 -->

<!-- BORDER-VISIBILITY-COMMIT-R122-20261119 -->
Eight warm cursor crossings reduce parent-frame visibility and opacity reads from 944 to 80 in each border style. Matched desktop seam and color samples agree. Frame updates invalidate their current sample, and the next commit reads fresh state.
[Matched validation](validation/border-visibility-commit-2026-11-19.json).
<!-- /BORDER-VISIBILITY-COMMIT-R122-20261119 -->

<!-- UNIT-NAME-STRIP-GEOMETRY-R124-20261119 -->
Class and spec icon refresh preserves matching anchors and dimensions for registered dividers. Layout changes or missing native geometry still run the normal setters.
[Matched validation](validation/unit-name-strip-geometry-2026-11-19.json).
<!-- /UNIT-NAME-STRIP-GEOMETRY-R124-20261119 -->

<!-- BORDER-POSE-SAMPLES-R125-20261119 -->
Eight prepared cursor crossings share 516 exact texture-coordinate arrays per border style. The renderer still samples every live source, and modeled heap growth falls by roughly 176 to 182 KiB. Prepared reuse still requires exact material, mask and UV validation.
[Matched validation](validation/border-pose-samples-2026-11-19.json).
<!-- /BORDER-POSE-SAMPLES-R125-20261119 -->

<!-- BORDER-PREPARED-DRAW-R126-20261119 -->
Eight prepared held-action crossings share 312 existing tile plans in the desktop replay. Median heap growth falls by 27.2 to 289.7 KiB across the strip and roster fixtures. An unchanged tile keeps its existing render state. A reflow reuses mutable draw records for tiles that remain active.
[Matched validation](validation/border-prepared-draw-2026-11-19.json).
<!-- /BORDER-PREPARED-DRAW-R126-20261119 -->

<!-- BORDER-DRAW-INPUTS-R127-20261119 -->
Eight warmed held-action crossings reused 48 draw-input lists per style. New input entries fell from 12,996 to 9,588 in type 1 and from 12,232 to 8,960 in type 2. A mismatch takes the normal current draw. A hidden derived field still repaints even when its public inputs match.
[Matched validation](validation/border-draw-inputs-2026-11-19.json).
<!-- /BORDER-DRAW-INPUTS-R127-20261119 -->

<!-- BORDER-SPRITE-REUSE-R128-20261119 -->
Eight warmed held-action crossings removed 1,556 type 1 and 1,776 type 2 per-sprite binding tables in the median replay. Heap growth fell by 151 to 176 KiB. Actual triangle and source matching still precede all native sprite reuse.
[Matched validation](validation/border-sprite-reuse-2026-11-19.json).
<!-- /BORDER-SPRITE-REUSE-R128-20261119 -->

<!-- STRIP-HOVER-MAPPINGS-R130-20261119 -->
Six crossings with an action held reduce modeled protected attribute writes from 1,026 to 594 and mapping slot queries from 300 to 186 in both mini-row positions. Unit and adjacent-panel geometry still settles before the single border commit on each edge.
[Matched validation](validation/strip-hover-mappings-2026-11-19.json).
<!-- /STRIP-HOVER-MAPPINGS-R130-20261119 -->

<!-- STRIP-HOVER-KEYS-R131-20261119 -->
Six held-action crossings remove 114 binding key queries in both the wrapped and Forever proxy desktop replays. Installed routes and settled geometry match on every edge. Real slot edits and binding events retain their routing recovery. Each edge still completes its existing panel and border transaction.
[Matched validation](validation/strip-hover-keys-2026-11-19.json).
<!-- /STRIP-HOVER-KEYS-R131-20261119 -->

<!-- BORDER-PARENT-GEOMETRY-R132-20261119 -->
Across six modeled strip crossings, three frame getter counts fell from 552 to 72. Across six modeled roster moves, they fell from 456 to 72. Both border types matched sampled seams and retained their solve counts. The measured change is in the geometry reader. Regional selection and prepared poses retain their prior ownership.
[Matched validation](validation/border-parent-geometry-2026-11-19.json).
<!-- /BORDER-PARENT-GEOMETRY-R132-20261119 -->

<!-- BORDER-POSE-TOPOLOGY-R133-20261119 -->
Across six modeled held-action crossings, median prepared-layout field checks fall from 4,816 to 3,016. Across six modeled roster position changes they fall from 7,553 to 2,693. Both border styles keep the same prepared hits and match sampled seams. Rapid crossings still validate changed frame samples, material and paint before the same commit.
[Matched validation](validation/border-pose-topology-2026-11-19.json).
<!-- /BORDER-POSE-TOPOLOGY-R133-20261119 -->

<!-- BORDER-FALLBACK-CONTEXT-R134-20261119 -->
Four modeled held-action crossings reduce fallback cache keys from 80 to 30 per border type. Four modeled party geometry appearances and removals reduce bounds union visits from 160 to 48. The represented joins and contributing fallback contexts match. The isolated-party replay continues to retain the current HUD tiles and update the unit scopes inside the same commit.
[Matched validation](validation/border-fallback-context-2026-11-19.json).
<!-- /BORDER-FALLBACK-CONTEXT-R134-20261119 -->

<!-- BORDER-ADMISSION-R135-20261119 -->
Four modeled transitions in the strip, party and raid-linked replays each cut regional source checks from 3,296 to 1,648. Frame visits fall from 392 to 196, while both styles retain matching sampled edges and rebuild counts. Unsupported sources keep fresh full-layout geometry reads. New material and layer samples still go through the existing compositor.
[Matched validation](validation/border-admission-2026-11-19.json).
<!-- /BORDER-ADMISSION-R135-20261119 -->

<!-- BORDER-LAYER-PLAN-R136-20261119 -->
Four modeled held-action crossings cut raised-strip level reads from 26 to eight and temporary layer records from 310 to 52. Four modeled party or raid-linked geometry transitions cut layer records from 276 to 44. Both styles preserve canvas layers and sampled seams. Live native inputs still verify before the same synchronous draw and publication.
[Matched validation](validation/border-layer-plan-2026-11-19.json).
<!-- /BORDER-LAYER-PLAN-R136-20261119 -->

<!-- BORDER-SNAPSHOT-COPY-R137-20261119 -->
Four modeled held-action crossings eliminate 552 duplicate source rectangles and reduce copy lookup tables from 106 to six. Four modeled party or raid-linked geometry transitions eliminate 192 duplicate rectangles and reduce those tables from 36 to three. The visible samples and matching rebuild counts agree in both styles. Each source movement still samples fresh geometry, and the solver crops its own operation rectangles.
[Matched validation](validation/border-snapshot-copy-2026-11-19.json).
<!-- /BORDER-SNAPSHOT-COPY-R137-20261119 -->

<!-- BORDER-POSE-REGISTRATION-R138-20261119 -->
Unrelated border registration and removal preserve the prepared action-strip, party and raid-linked layouts. Four subsequent transitions per modeled replay go from four solves and plans to zero in both border types. The actual registration pass still compiles any changed area. A source leaving its original frame retires that frame from matching saved layouts.
[Matched validation](validation/border-pose-registration-2026-11-19.json).
<!-- /BORDER-POSE-REGISTRATION-R138-20261119 -->

<!-- BORDER-EMPTY-FRAGMENTS-R139-20261119 -->
Four warm held-action crossings remove 236 to 240 empty normal-canvas preparations and 474 empty fallback visits in both border styles. Four modeled party or raid-linked outline appearances and removals skip 148 empty fallback visits. All sampled fields match. The full renderer retains its existing canvas preparation. Uninstrumented desktop elapsed samples show small and mixed changes.
[Matched validation](validation/border-empty-fragments-2026-11-19.json).
<!-- /BORDER-EMPTY-FRAGMENTS-R139-20261119 -->

<!-- RAID-GRID-RECTANGLE-R141-20261119 -->
Compact raid border refreshes confirm retained bounds with a single rectangle read. Eight five-cell leave and return transitions reduce geometry getter calls from 1,200 to 360 in both modeled row-overlap arrangements. Each newly visible or changed cell still uses exact native edge getters. Both row-overlap arrangements match the legacy edge oracle through fractional joins, geometry changes and unreadable inputs.
[Matched validation](validation/raid-grid-rectangle-2026-11-19.json).
<!-- /RAID-GRID-RECTANGLE-R141-20261119 -->

<!-- RAID-JOIN-INDEX-R143-20261119 -->
Aligned compact groups locate joined edges by exact row and column coordinates. The first 40-cell border pass avoids 660 tolerance calculations and two sorts. Eight aligned five-cell departures and returns avoid 4,740 tolerance calculations and 16 sorts in both overlap models. The same public native edge data feeds both join paths. The irregular replay preserves its tolerance checks and has mixed desktop timing.
[Matched validation](validation/raid-join-index-2026-11-19.json).
<!-- /RAID-JOIN-INDEX-R143-20261119 -->

<!-- BORDER-ANCHOR-BURSTS-R144-20261119 -->
The border builder reads watched anchors once from the settled layout and preserves unchanged reverse dependencies during strip and roster reflow. A four-panel, twelve-transition matched replay reduced point-count queries from 144 to 48 and per-point queries from 144 to 96 in both styles. The committed mesh and number of geometry passes match. Equal-position anchor replacement still records the new link before querying its dependents.
[Matched validation](validation/border-anchor-bursts-2026-11-19.json).
<!-- /BORDER-ANCHOR-BURSTS-R144-20261119 -->

<!-- STRIP-HOVER-ROUTES-R145-20261119 -->
Held spell, item and macro crossings refresh page and live occupancy while retaining valid click routes. Six transitions on page one reduced button attribute setters from 20,151 to 9,192. Page two reduced them from 20,142 to 9,189. The existing synchronous strip border commit continues to follow both hover poses and real slot edits.
[Matched validation](validation/strip-hover-routes-2026-11-19.json).
<!-- /STRIP-HOVER-ROUTES-R145-20261119 -->

<!-- STRIP-MODIFIER-ROUTES-R146-20261119 -->
Keep each confirmed modifier route during a pure held-action crossing. Six crossings avoid another 1,740 button attribute setters on each tested page. Current type, action, macro text and alternate modifier aliases agree with the full-refresh oracle. The layout transaction retains its border commit and owned side-panel reanchoring.
[Matched validation](validation/strip-modifier-routes-2026-11-19.json).
<!-- /STRIP-MODIFIER-ROUTES-R146-20261119 -->

<!-- PARTY-INDICATOR-PASS-R147-20261119 -->
Party chrome consolidates duplicate placement on roster events. Shared border geometry, focus presentation and actual partition relayout retain their existing paths.
[Matched validation](validation/party-indicator-pass-2026-11-19.json).
<!-- /PARTY-INDICATOR-PASS-R147-20261119 -->

<!-- RAID-EXTRA-DRIVER-RETRY-R148-20261119 -->
Retrying one optional roster cell preserves the ready cells and their anchors. This avoids publishing unrelated protected geometry to other layout owners when a driver fails.
[Matched validation](validation/raid-extra-driver-retry-2026-11-19.json).
<!-- /RAID-EXTRA-DRIVER-RETRY-R148-20261119 -->

<!-- BORDER-ROLE-ANCESTRY-R149-20261119 -->
The regional border builder shares public parent-chain role reads within one geometry pass. Six modeled held-action changes reduce classification parent reads from 1,194 to 312. Six roster-related moves reduce them from 1,218 to 312. Sampled seams and retained regions match in both border types. Reentrant invalidation, private role data and live role changes are covered by the phase tests.
[Matched validation](validation/border-role-ancestry-2026-11-19.json).
<!-- /BORDER-ROLE-ANCESTRY-R149-20261119 -->

<!-- STRIP-FLYOUT-ARROW-R150-20261119 -->
The strip dependency transaction keeps live flyout arrow geometry when its point and size already match. The shared border renderer retains the prior source. Exact-tile routing prototypes did not materially improve the held-action replay and were discarded.
[Matched validation](validation/strip-flyout-arrow-2026-11-19.json).
<!-- /STRIP-FLYOUT-ARROW-R150-20261119 -->

<!-- STRIP-HOVER-OCCUPANCY-R151-20261119 -->
The held-action strip transaction now enters the border work after one secure state broadcast per header. Six modeled crossings save 1,710 button attribute writes. Existing border planning, local commit and side attachments follow the same layout.
[Matched validation](validation/strip-hover-occupancy-2026-11-19.json).
<!-- /STRIP-HOVER-OCCUPANCY-R151-20261119 -->

<!-- STRIP-PLAN-COVERAGE-R152-20261119 -->
A saved action-strip border plan can now cover a smaller set of changed tiles at the same destination geometry. Nine matched width changes reduce border planning from nine passes to six in each style. Nearby seams, active operation owners and retained tile listeners match the uncached replay. Uncovered tiles request the existing local planning pass.
[Matched validation](validation/strip-plan-coverage-2026-11-19.json).
<!-- /STRIP-PLAN-COVERAGE-R152-20261119 -->

<!-- BORDER-LISTENER-INDEX-R155-20261120 -->
The regional border commit reuses color, sprite and visibility index tables across a tile redraw. Eight held-action crossings avoid 344 replacements in border type one and 384 in type two. Forty warmed crossings reduce median temporary Lua heap growth by 158 and 187 KiB. Sampled joins and live updates match the archived renderer. Elapsed samples are mixed and native timing remains pending.
[Matched validation](validation/border-listener-index-2026-11-20.json).
<!-- /BORDER-LISTENER-INDEX-R155-20261120 -->

<!-- BORDER-FRAGMENT-MEMBERSHIP-R156-20261120 -->
The regional border commit keeps live fragments in their source paint pools during a redraw. Eight held-action crossings reduce pool insertions and removals from 1,789 to three for border type one and from 1,821 to three for type two. Sampled joins and live layer, tint and visibility match the prior renderer. Rollback and recovery pass in the desktop fixture. Native timing remains pending.
[Matched validation](validation/border-fragment-membership-2026-11-20.json).
<!-- /BORDER-FRAGMENT-MEMBERSHIP-R156-20261120 -->

<!-- PET-STRIP-PACKING-R157-20261120 -->
Action-strip crossings preserve settled pet slots when live geometry, content ownership and sizing inputs match. Eight matched crossings each remove 168 size writes, 160 point writes, 160 parent writes and 80 chrome rebuilds in both modeled client shapes. The pet root update and final border transaction keep their order. Native timing remains pending.
[Matched validation](validation/pet-strip-packing-2026-11-20.json).
<!-- /PET-STRIP-PACKING-R157-20261120 -->

<!-- STANCE-STRIP-LAYOUT-R158-20261120 -->
The action-strip transaction samples stance after pet placement and keeps settled stance geometry on a crossing. Eight modeled crossings keep eight shared border commits and remove eight extra commits, eight stance catalog checks, 24 button paints and eight binding passes. Player-docked and pet-docked stance geometry match. Changed inputs still use the normal repair path. Native timing and rendering remain pending.
[Matched validation](validation/stance-strip-layout-2026-11-20.json).
<!-- /STANCE-STRIP-LAYOUT-R158-20261120 -->

<!-- NATIVE-GROUP-HIDE-R159-20261120 -->
Twenty-four modeled native group-suppression sweeps remove 72 redundant alpha writes and reduce median heap growth from 562 to 200 KiB. The same 4,872 native child reads catch new and reparented controls. The longer 240-sweep process clock samples range around medians of 54 and 50 ms. Native group hitch timing is pending.
[Matched validation](validation/native-group-hide-2026-11-20.json).
<!-- /NATIVE-GROUP-HIDE-R159-20261120 -->

<!-- RAID-ACTIVE-HEADERS-R160-20261120 -->
Prepared roster reconciliation skips headers confirmed hidden by the native visibility getter. Eight modeled unscoped raid passes with a hidden tank/assist header reduce child attribute reads from 1,024 to 384 and attachment calls from 320 to zero. Visible paint and border dispatch match. Explicit recovery, private visibility and actual header reveals still use their current event owners. Native timing remains pending.
[Matched validation](validation/raid-active-headers-2026-11-20.json).
<!-- /RAID-ACTIVE-HEADERS-R160-20261120 -->

<!-- STRIP-BADGE-PLACEMENT-R161-20261120 -->
Held-action strip crossings now retain matching corner-badge placement and layer levels. Eight matched crossings with 135 prepared badge faces remove 14,040 placement and layer writes in the desktop model. Changed size, clipping, anchoring and layers still take the existing repair path. Relative badge anchors follow the moved host during the same border transaction. Native timing remains pending.
[Matched validation](validation/strip-badge-placement-2026-11-20.json).
<!-- /STRIP-BADGE-PLACEMENT-R161-20261120 -->

<!-- BORDER-RECENT-LAYOUTS-R162-20261120 -->
The border builder keeps up to four small exact layouts per strip hover state and three roster layouts within the previous combined geometry and clipped-field bounds. Twelve modeled width transitions now compile four times instead of twelve. Nine modeled roster layout transitions compile three times instead of nine. Both styles match sampled joins. New geometry still compiles locally, and cached output checks current materials and paint. Native timing remains pending.
[Matched validation](validation/border-recent-layouts-2026-11-20.json).
<!-- /BORDER-RECENT-LAYOUTS-R162-20261120 -->

<!-- BORDER-SIMPLE-INTERVALS-R163-20261120 -->
Cold border builds skip boundary allocation and sorting for unpartitioned parallel overlaps. Two modeled strip changes per style remove 19 walks and sorts and 608 keeper corner candidate visits. Two modeled roster changes remove eight walks and sorts. All sampled joins and the chained ownership oracle match. Dense ownership chains retain their original caps, cuts and budgets. Native timing remains pending.
[Matched validation](validation/border-simple-intervals-2026-11-20.json).
<!-- /BORDER-SIMPLE-INTERVALS-R163-20261120 -->

<!-- BORDER-FALLBACK-CLIP-R164-20261120 -->
Cold regional reflows reject strictly disjoint compiled triangles before the per-triangle guard or cache record. Median guard counts across two strip changes fall from 226 to 127 and 201 to 117 in border order. Across two roster changes, they fall from 704 to 540 and 784 to 512. Sampled joins and revealed backups match. Dense cases and clock samples are in the validation record. Native timing remains pending.
[Matched validation](validation/border-fallback-clip-2026-11-20.json).
<!-- /BORDER-FALLBACK-CLIP-R164-20261120 -->

<!-- STRIP-SHELL-ANCHORS-R165-20261120 -->
The action strip retains matching screen and sensing anchors across resizes. For six held-action crossings, desktop replays eliminate 24 exterior anchor writes and six redundant scale writes. Six slot edits also eliminate 12 inner anchor writes. Final positions, action routes and one border commit per resize match the previous source. The standard resize still commits its junctions against the final layout.
[Matched validation](validation/strip-shell-anchors-2026-11-20.json).
<!-- /STRIP-SHELL-ANCHORS-R165-20261120 -->

<!-- BORDER-TILE-FIELDS-R166-20261120 -->
The border renderer writes fully contained tile triangles and rectangular quads directly. In two cold action-strip reflows, temporary polygon builds fall from 429 to 216 and from 496 to 216 in border style order. Clipped vertices, artwork coordinates and sampled seams match the archived source. Desktop end-to-end elapsed samples are mixed. Raw allocation, resource and parity data are in the matched record.
[Matched validation](validation/border-tile-fields-2026-11-20.json).
<!-- /BORDER-TILE-FIELDS-R166-20261120 -->

<!-- STRIP-GRID-ROOT-ANCHORS-R168-20261120 -->
Combat and noncombat grid roots keep verified relative anchors when the action strip resizes. Across ten modeled crossings, 50 root anchor writes and ten unused floor queries fall to zero. Each crossing still settles the envelope once. Both client models keep the same relative anchors and offsets. Native timing remains pending.
[Matched validation](validation/strip-grid-root-anchors-2026-11-20.json).
<!-- /STRIP-GRID-ROOT-ANCHORS-R168-20261120 -->

<!-- BORDER-NEIGHBOR-RUNS-R170-20261120 -->
The regional border planner checks neighbor membership once per consecutive group and reuses the group during geometry copying. Two cold strip or roster changes reduce membership checks from 392 to 98 across both styles. Isolated copy and selection medians fall from 45 to 38 ms and from 44 to 37 ms per 1000 passes in border style order. Full desktop reflow timings are mixed. Source ordering and sampled seams match. Raw measurements and the prototype comparisons are in the matched record.
[Matched validation](validation/border-neighbor-runs-2026-11-20.json).
<!-- /BORDER-NEIGHBOR-RUNS-R170-20261120 -->

<!-- STRIP-EMPTY-PROMOTION-R171-20261120 -->
The action strip checks alternate main pages during promotion only when a secondary or tertiary button has an action. Eight paired cursor crossings remove 72 action reads from mapping and 52 from placement in each tested layout. Click routes, placement and the border transaction match the archived Lua.
[Matched validation](validation/strip-empty-promotion-2026-11-20.json).
<!-- /STRIP-EMPTY-PROMOTION-R171-20261120 -->

<!-- FLYOUT-ARROW-LAYERS-R172-20261120 -->
The shared flyout refresh keeps an arrow’s confirmed parent, frame strata, level and scale during strip movement. Twelve matched moves cut layer and scale writes from 48 to zero per arrow. Replacement owners, layer drift and denied getters still use native repair. The shared border and visibility-parent paths agree with the archived source.
[Matched validation](validation/flyout-arrow-layers-2026-11-20.json).
<!-- /FLYOUT-ARROW-LAYERS-R172-20261120 -->

<!-- BORDER-FALLBACK-PARTITION-R173-20261120 -->
The border planner writes each split fallback fragment directly into its final list. Across two matched changes per style, strip resizing removes 38 temporary tables, roster movement removes 64, and a dense overlap replay removes 172. Draw counts, sampled joins and borders revealed when a keeper hides match the original. The matched record contains isolated clock and allocation results and mixed whole-reflow samples.
[Matched validation](validation/border-fallback-partition-2026-11-20.json).
<!-- /BORDER-FALLBACK-PARTITION-R173-20261120 -->

<!-- BORDER-LISTENER-RUNS-R174-20261120 -->
The regional border commit shares watcher entries for consecutive fallback fields with the same source and blockers. Twelve warmed strip crossings reduce observer visits from medians of 1,464 to 1,056 and from 1,272 to 1,044 in border style order. Twelve roster reflows reduce them from 6,624 to 6,060 and from 15,648 to 14,040. The same fields paint in their original order, including when a keeper hides and returns. Raw timing, heap samples and retained watcher-slot counts are in the matched record.
[Matched validation](validation/border-fallback-listeners-2026-11-20.json).
<!-- /BORDER-LISTENER-RUNS-R174-20261120 -->

<!-- BORDER-LISTENER-LINKS-R175-20261120 -->
The renderer reuses one visibility-link table per changed tile. Observer lists keep the head of each consecutive fallback run, and its existing visibility check supplies the whole run. Twelve warmed strip crossings save a median 13.5 to 16.0 KiB of temporary Lua allocation. The roster fixture saves 30.5 to 152.5 KiB. Observer visits also fall, with equal logical memberships and paint order. Whole-reflow timing is mixed. The matched record includes the remaining prepared paint work counters.
[Matched validation](validation/border-listener-links-2026-11-20.json).
<!-- /BORDER-LISTENER-LINKS-R175-20261120 -->

<!-- BORDER-FIELD-ANCHORS-R176-20261120 -->
Moving border fields update a verified existing anchor in place. Across twelve warmed strip crossings the median point clears fall from 1,764 and 1,932 to 12 in each style. The roster replay falls from 4,164 and 6,720 to zero. Point writes, sampled joins and widget counts match. Temporary heap use falls with mixed full-update timing. The two-pool experiment and exact client-source examples are recorded with the comparisons.
[Matched validation](validation/border-field-anchors-2026-11-20.json).
<!-- /BORDER-FIELD-ANCHORS-R176-20261120 -->

<!-- BORDER-FIELD-PAINT-R177-20261120 -->
Border paint caches texture and layer values directly and compares public RGBA through its fixed setter. Twelve warmed strip crossings take 53 to 53 ms and 97 to 96 ms at the desktop median in style order. Temporary Lua allocation falls by 32.4 and 33.6 KiB. Attempted setter counts and sampled seams agree. The roster replay, render work counts and rejected combined guard samples are in the matched record.
[Matched validation](validation/border-field-paint-2026-11-20.json).
<!-- /BORDER-FIELD-PAINT-R177-20261120 -->

<!-- BORDER-ROSTER-BOUNDS-R178-20261120 -->
Prepared roster reflows share a bounding box among eligible textures in the same junction. Twelve warmed reflows cut modeled box calls from 5,664 to 4,236 and from 9,864 to 7,368 in border-style order. The first two compiles keep the original setter counts. First prepared restores and one unseen layout after warming also use fewer box calls. Strip crossings match the original setter counts. Desktop elapsed comparisons were mixed. The raw timings and earlier scope and binding experiments are recorded with the comparison.
[Matched validation](validation/border-roster-bounds-2026-11-20.json).
<!-- /BORDER-ROSTER-BOUNDS-R178-20261120 -->

<!-- BORDER-SOURCE-ALPHA-R179-20261120 -->
Regional paint reuses the observation of zero source opacity through publication. Sixty warmed strip crossings save 3,540 modeled opacity reads per style. Sixty warmed roster reflows save 2,700 reads per style. Alpha and mesh writes, sampled seams and texture counts match. The measured desktop elapsed times were mixed. Counter, timing, and texture pool comparisons are attached.
[Matched validation](validation/border-source-alpha-2026-11-20.json).
<!-- /BORDER-SOURCE-ALPHA-R179-20261120 -->

<!-- STRIP-EXPANDED-COLUMNS-20261120 -->
The expanded strip uses its full column count and checks current-page main and mini occupancy for drop placement. Sixty modeled cursor crossings per fixture remove 1,770 to 1,800 collapsed packing checks during expansion. Action reads, action routes, point and visibility writes, and border commits match the archived Lua. The matched record includes the draw-record and tile-routing trials.
[Matched validation](validation/strip-expanded-columns-2026-11-20.json).
<!-- /STRIP-EXPANDED-COLUMNS-20261120 -->

<!-- BORDER-OBSERVED-SOURCES-R180-20261120 -->
A regional read reuses public preflight snapshots for watched source textures. Sixty warmed strip crossings per style remove 5,760 modeled getter calls and about 1.22 MiB of temporary allocation. Sixty roster moves per style remove 7,920 calls. Actual source geometry and paint still use live inputs. Matched setter counts, sampled joins and texture counts agree. Desktop elapsed timing was mixed. The attached record preserves the setter, counter, clock and guard-control results.
[Matched validation](validation/border-observed-sources-2026-11-20.json).
<!-- /BORDER-OBSERVED-SOURCES-R180-20261120 -->

<!-- BORDER-PANEL-ALIGNMENT-POSES-R181-20261120 -->
Panel alignment retains offsets for its two most recent successful layouts. For both border types and both tested scales, 60 warmed crossings eliminate 60 alignment graph builds. The same 60 anchor updates and sampled junctions remain. Median alignment-phase time falls by 45 to 48 percent across the paired desktop runs. Full transaction timings were mixed. The attached record includes raw elapsed and allocation samples.
[Matched validation](validation/border-panel-alignment-poses-2026-11-20.json).
<!-- /BORDER-PANEL-ALIGNMENT-POSES-R181-20261120 -->

<!-- GROUP-NAMEPLATE-ANCHORS-20261120 -->
Roster refreshes retain verified quest badge anchors on visible nameplates. In 60 modeled roster bursts with 32 active plates, anchor writes fall from 7,680 to zero in each of five client models. Objective refresh counts and follow-up polls match. The desktop Lua median is 10 ms before and 11 ms after across all 60 bursts per model. Native write and frame-time costs remain unmeasured. This removes work from the upstream roster path alongside border updates.
[Matched validation](validation/group-nameplate-anchors-2026-11-20.json).
<!-- /GROUP-NAMEPLATE-ANCHORS-20261120 -->

<!-- GROUP-NAMEPLATE-LEVELS-20261120 -->
Nameplate overlays keep a verified frame level while attached to the same plate. Across 60 modeled roster bursts with 32 plates, frame-level writes fall from 7,680 to zero in each of five client models. Two seconds of steady 20-plate polling reduce writes from 184 to 5 in Retail and 364 to 6 in Forever. Fresh attachment and repair preserve their existing writes. Modeled elapsed timings were mixed. This work reduces group refresh costs outside the border solver.
[Matched validation](validation/group-nameplate-levels-2026-11-20.json).
<!-- /GROUP-NAMEPLATE-LEVELS-20261120 -->

<!-- STRIP-INFO-ANCHORS-20261120 -->
Held-action strip crossings now keep verified native anchors on the Info slot and its gap fill. Over 60 modeled crossings, point writes fall from 180 to zero when both poses are wide and from 90 to zero when one pose hides the slot. The envelope samples the shared left, top and bottom owner once instead of three times. All four Info placements preserve their settled shown states, points and sizes.
[Matched validation](validation/strip-info-anchors-2026-11-20.json).
<!-- /STRIP-INFO-ANCHORS-20261120 -->

<!-- STRIP-SLOT-SETTLE-20261120 -->
Warmed action-slot edits use the strip settlement for face placement, chrome, nearby panels and unit roots even without a cursor edge. Sixty alternating column additions and removals reduce modeled strip point writes from 2,610 to 3 and ring sizing calls from 3,420 to 30 across three client fixtures. On both unit placements and three scales, ten edits replace twenty full unit refreshes with ten checks of the final root anchors. Every modeled junction commit still runs after the final panel and unit geometry.
[Matched validation](validation/strip-slot-settle-2026-11-20.json).
<!-- /STRIP-SLOT-SETTLE-20261120 -->

<!-- BORDER-CURRENT-DRAW-INPUTS-R182-20261120 -->
The regional border draw reuses the current validated source paint and samples the parent once per junction-only source during the commit. Twelve warmed strip crossings remove 990 and 924 repeat paint validations in border style order. Twelve roster reflows remove 522 and 702. The same setters, sampled seams and texture counts remain. Desktop elapsed timings were mixed.
[Matched validation](validation/border-current-draw-inputs-2026-11-20.json).
<!-- /BORDER-CURRENT-DRAW-INPUTS-R182-20261120 -->

<!-- ROSTER-AURA-PAINT-20261120 -->
Raid and party aura refreshes retain matching owned icon textures, stack text and visibility. Twenty modeled forty-cell reflows with one joining/leaving slot reduce visibility writes from 895 to 95 on the Retail and Forever native-container profiles and from 15,960 to 95 on the readable Classic profiles. Readable icon and stack writes each fall from 1,580 to zero there. Aura queries, native assignments and cooldown timing match. Desktop timing samples vary by profile.
[Matched validation](validation/roster-aura-paint-2026-11-20.json).
<!-- /ROSTER-AURA-PAINT-20261120 -->

<!-- STRIP-EVENT-OWNERSHIP-R183-20261120 -->
Sixty matched slot changes, each with two native notifications, cut early envelope reads from 120 to zero. The same 60 final layout passes and border commits still run. Six warmed held-cursor replays across both styles and three UI scales use 8 to 16 fewer parent level reads per six crossings. Settled action routes, button geometry, raised layers and sampled border artwork match the archived sources.
[Matched validation](validation/strip-event-ownership-2026-11-20.json).
<!-- /STRIP-EVENT-OWNERSHIP-R183-20261120 -->

<!-- STRIP-GRID-WIDTH-20261120 -->
Combat and Non-combat grids retain their verified column order when an action-strip crossing changes the horizontal squeeze. Across 60 modeled crossings, geometry setters fell from 6,844 to 4,484 and column sorts from 1,239 to zero in each client fixture. Both grid shapes, icon refreshes, clipping and Info/envelope notification order match. Five alternating desktop pairs per profile measured 20 to 12 ms median for 320 crossings of this layout path.
[Matched validation](validation/strip-grid-width-2026-11-20.json).
<!-- /STRIP-GRID-WIDTH-20261120 -->

<!-- BORDER-FIELD-RETIREMENT-R184-20261120 -->
The regional border renderer hides outgoing fragments and junction textures through their current ownership records. Twelve modeled held-action crossings removed 1,446 and 1,818 visibility reads in border style order. Twelve roster-layout moves removed 876 and 1,914. Native setter counts, sampled joins, and texture counts match in the model. Desktop timings improved for the two held-action medians and were mixed across roster reflows.
[Matched validation](validation/border-field-retirement-2026-11-20.json).
<!-- /BORDER-FIELD-RETIREMENT-R184-20261120 -->

<!-- BORDER-OBSERVER-SCRATCH-R185-20261120 -->
Regional preflight uses a flat dependency stack and one scratch link set per settled anchor batch. Twelve modeled strip crossings remove 768 temporary dependency entries and 432 temporary snapshot validation tables per style. Twelve modeled roster moves remove 1,056 entries and 576 validation tables. Each replay reduces scratch link sets from 48 to 12, with identical dependency visits and snapshot counts. Texture setters, sampled seams and operation counts match. Use the original current native getters and preserve dependency order, cycle detection, traversal ceilings and conservative global fallback. Publish a separate weak-key link set for each real rewire. Reject opaque parents before producing a comparable snapshot.
[Matched validation](validation/border-observer-scratch-2026-11-20.json).
<!-- /BORDER-OBSERVER-SCRATCH-R185-20261120 -->

<!-- STRIP-GRID-RING-20261120 -->
Width changes in Combat and Non-Combat Grid now size each button ring once. Sixty modeled crossings cut ring fits from 1,920 to 960. Cosmetic setter calls fall from 102,720 to 62,400 in the Retail and Forever models and from 108,480 to 66,240 in the Classic model. Grid positions, ring art, checked and pressed textures, equipped glow and cooldown layout match.
[Matched validation](validation/strip-grid-ring-2026-11-20.json).
<!-- /STRIP-GRID-RING-20261120 -->

<!-- STRIP-ARROW-OWNER-20261120 -->
The action-strip envelope now shares its completed flyout refresh with the Trinket Menu. Across 60 modeled crossings with 20 attached arrows, explicit shared scans fell from 180 to 120 and all visible arrow updates from 4,800 to 3,600. Trinket layer setters fell from 720 to zero with matching slot anchors, size, scale and atlas layering.
[Matched validation](validation/strip-arrow-owner-2026-11-20.json).
<!-- /STRIP-ARROW-OWNER-20261120 -->

<!-- BORDER-PANEL-INPUTS-R186-20261120 -->
R186 reuses the nearby-panel records that match either prepared layout. In both styles, 60 repeated scans of a stable seven-panel HUD and 60 alternating warmed strip widths cut 420 new panel records to zero. Sixty new widths create 300 records and retain the same 60 alignment graphs. The native-style rectangle reads, changed decorative boxes and final coordinates match. The phase fixture models panel geometry and does not measure the whole border rebuild. Match the existing frame, border owner, role, layer priority, scale and four public stroke coordinates before reusing an input record. Read live geometry on every alignment pass. The planner keeps its temporary nodes outside the retained records, and the output phase keeps the existing native writes and failure recovery. Removing the last owner shortens the active list and restores its border.
[Matched validation](validation/border-panel-inputs-2026-11-20.json).
<!-- /BORDER-PANEL-INPUTS-R186-20261120 -->

<!-- BORDER-CELL-BUDGET-R187-20261120 -->
R187 reduces capacity checks from 7,560 region visits to 2,340 across 60 warmed action-strip crossings per border style. The modeled fields, sampled colors and opacity, and admitted draw records match. Keep aggregate planned-field and draw-cache usage with the committed regional layout. Admission inspects the replacement keys, subtracts their existing claims and keeps unchanged claims in the totals. Commit publishes the counts with the new layout. Full release and recovery clear them. The existing resource limits remain in force.
[Matched validation](validation/border-cell-budget-2026-11-20.json).
<!-- /BORDER-CELL-BUDGET-R187-20261120 -->
