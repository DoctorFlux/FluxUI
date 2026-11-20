# Party roster border work

Change `PARTY-BORDER-WORK-20261117` follows the user's party join/leave lag report.
The previously accepted mini-overlay and active-crafting visuals are preserved.

| ID | Requirement | Current change |
|---|---|---|
| PRW-01 | Reuse prepared party geometry on visibility changes | Mark only the bare FluxRaidContainer as an existing retained unit host. Show/hide and alpha crossings keep native paint ownership. Actual point, size, scale, parenting, private/public availability and unrelated HUD changes remain observable. |
| PRW-02 | One prepared header-position owner | Keep Secure.RefreshRosterLayout and its execution on every prepared reconciliation. Omit the temporary Lua positions and width that this same execution immediately overwrites. Keep legacy placement for an MTMA header not passed to the secure owner, and for unprepared/failure paths. |
| PRW-03 | Preserve live roster data | Keep all full paints, unit binding, pet/member updates, aura/range refresh, joined-border requests, MTMA/chat lift, labels, focus notifications and native fallback/retry. The same unit token can identify a different player; no token-only suppression. |
| PRW-04 | Preserve input and compatibility | No new native API, driver, event, timer, hook, settings, command, saved root or input route. Combat still defers protected layout. Existing Retail, Forever and Classic adapters remain. |
| PRW-05 | Report actual scope | Exact model geometry/material/cadence controls and archived-source negatives are separate from native CPU/FPS, taint and complete join/leave latency. The requested user capture remains pending. |

The shared border observer previously queued a full geometry read and nearby
alignment pass when this unit-only ancestor hid or showed, even when the final
mesh signature was unchanged. The actual Core/Init model reports one wake,
one read and one alignment becoming zero for each visibility transition; both
versions already avoided a solve in this unchanged case. This is not evidence
of an observed native millisecond saving.

The prepared roster path also positioned all group headers in Lua, including
empty headers at an offscreen placeholder, then immediately ran the secure
layout that assigned their canonical positions again. Delegating the prepared
positions removes up to nine duplicate clear/set pairs and one width write.
Disabled MTMA retains its original Lua positioning because no MTMA frame ref is
passed to that secure owner. All data refresh and secure execution remain.

Success final geometry and slot bindings match in the actual-function model.
Returned partial execution failures can leave different hidden intermediate
header poses because the legacy fallback staging happens after that failure;
both paths retain header hiding, native UI restoration, readiness reset, error
and retry behavior. Raw exceptions propagate, and recovery poses match. No
claim of identical intermediate failure poses is made.

A separate raid-local adjacency-cache prototype is **unapplied**. Repeated
unchanged layouts improved modeled CPU, while genuine changed layouts cost
24.3%, 6.5% and 2.7% more at 5, 40 and 80 cells. The current priority is join/leave reflow.
The current runtime still performs fresh collection and all joined-edge paints.

The changes affect existing raid layout and border-observer ownership. Modeled
final geometry and input routes remain unchanged; existing native controller,
mouse, keyboard and unit interactions remain. There are no new
focus stops or visible strings. Native tests stay user-operated in the
background; no automatic group join/leave or profiling is performed here.

See [exact checkpoint, sources and validation](validation/party-border-work-2026-11-17.json).

<!-- PARTY-ROSTER-LOCALITY-R73-20261119 -->
R73 adds a prepared-mode guard to the existing roster callback. In player-style party mode, independently driven party frames handle solo/party transitions. In raid-style party mode, secure layout still runs while only group one is read for unit reconciliation. GUID-confirmed same-member party cast paint retains active casts. The native restricted layout from R72 remains the full path for roster readiness and raid recovery.
[R73 evidence](validation/party-roster-locality-2026-11-19.json).
<!-- /PARTY-ROSTER-LOCALITY-R73-20261119 -->

<!-- GROUP-RENDER-R74-20261119 -->
R74 reduces repeat work at the source of common party and raid events. Roster paint and visibility-driven party target paint share one batch, with immediate target identity retirement and live UNIT_TARGET updates. Native raid overlay suppression reads state once per frame per sweep. Nameplate roster refresh occurs once per burst. Minimap roster and instance-size updates retain group-specific work. The evidence records the remaining secure and compatibility owners.
[R74 evidence](validation/group-render-work-2026-11-19.json).
<!-- /GROUP-RENDER-R74-20261119 -->

<!-- ROSTER-REGION-ROUTING-R75-20261119 -->
The shared roster path called focus aura positioning even with unchanged panel geometry. Current public anchors and sizes now avoid redundant native writes while keeping aura paint and drift recovery. Raid-unit reveal reuses successful existing filters and still binds replacement tokens or restores filters after hide.
[R75 evidence](validation/roster-region-routing-2026-11-19.json).
<!-- /ROSTER-REGION-ROUTING-R75-20261119 -->

<!-- ROSTER-RETURN-PLANS-R76-20261119 -->
The native raid bind now sets the token and event filters for a publicly hidden frame. Native reveal paints the new unit, including its auras. Repeated layouts can reuse recent numeric border plans after validation against current inputs. First-entry work and current native event-to-frame timings remain unresolved.
[R76 evidence](validation/roster-return-plans-2026-11-19.json).
<!-- /ROSTER-RETURN-PLANS-R76-20261119 -->

<!-- ROSTER-LOCAL-FALLBACK-R77-20261119 -->
Visible raid cell geometry is still read on roster work. The same cell rectangles and overlap reuse their computed adjacency while the renderer updates from current paint state. Cold border fallback preparation allocates less metadata. Native grouped timing remains open.
[R77 evidence](validation/roster-local-fallback-2026-11-19.json).
<!-- /ROSTER-LOCAL-FALLBACK-R77-20261119 -->

<!-- ROSTER-PREPARED-LAYOUT-R78-20261119 -->
R78 skips repeated border ownership scans and scope checks during party and raid layout changes. The replays preserve both styles and their prepared border fields.
[R78 evidence](validation/roster-prepared-layout-2026-11-19.json).
<!-- /ROSTER-PREPARED-LAYOUT-R78-20261119 -->

<!-- REGIONAL-CLIPPING-R79-20261119 -->
R79 keeps matching target and focus threat-bar geometry in place during roster updates. Group visibility, current threat and genuine pose changes are applied on the same event. Live join/leave timing remains open.
[R79 evidence](validation/regional-clipping-2026-11-19.json).
<!-- /REGIONAL-CLIPPING-R79-20261119 -->
