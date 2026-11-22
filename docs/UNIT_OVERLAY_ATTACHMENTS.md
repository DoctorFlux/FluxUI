# Mini unit overlays and portrait contacts

Change `UNIT-OVERLAY-ATTACHMENTS-20261116` follows the user's target-of-target
reference and request to improve pet, target-of-target and party-pet borders
while keeping those frames overlaid on the parent unit frame.

| ID | Requirement | Implementation / acceptance |
|---|---|---|
| UOA-01 | Keep the existing overlay layout | Body, HP/resource fills, portrait/model, backdrop and input anchors keep their owners and dimensions. Only the mini's decorative container and horizontal endpoints fit to the contact. |
| UOA-02 | Meet the parent's portrait divider | Mini top/bottom and HP/resource divider meet the existing portrait vertical core. Factory corner overhang, normalised artwork, border-style tracks, inset and complete effective scale determine the endpoint. |
| UOA-03 | Preserve independent units | Parent portrait strokes remain intact. Only the mini's portrait-facing side and its two facing caps leave junction registration; outside caps remain. No parent/child unit-owner or party-instance topology is merged. The solver recognises the five remaining pieces as one open frame, retaining its outside-cap ownership and protection. |
| UOA-04 | Restore detached outlines | Closed outlines return for standalone ToT, disabled portraits, independently moved/stretched minis and nonstandard portrait anchors. Unknown/restricted geometry preserves prepared state; no secret value is compared or used in arithmetic. |
| UOA-05 | Keep prepared geometry stable | Reuse the existing Forget/Register, public layout guards and local shape cache. No new region, mask, timer, event, hook or update driver. No attachment geometry writes in combat or on unchanged visibility/color. |
| UOA-06 | Apply to both border styles | Type1/100% and Type2/150% keep the same mini/root positions. The current measured border core supplies each endpoint; no user thickness setting is added. |

The contact keeps each unit's own color. The parent's uninterrupted vertical
stroke remains authoritative; the mini's incoming horizontal stroke retains its
own paint. This deliberately avoids permanently cutting a parent's border for a
separately watched unit that may disappear in combat.

The shared fitter validates the actual stock portrait anchor and a single stock
mini anchor before fitting. It computes contact from public authored geometry,
not unit health, existence, aura, combat or private native coordinate values.
No settings, localized strings, saved roots or input route change. Decorative
pieces introduce no controller focus stops.

Offline acceptance must separately cover real Border/Core/Shared helpers, actual
factory integration, omitted-source persistence after type/material/color refresh,
restoration, outside caps and unchanged-shape work. Native seam quality, GPU
sampling, security and FPS are separate from model counters and remain unclaimed
until a corresponding observation is recorded.

See [exact sources and validation](validation/unit-overlays-active-casts-2026-11-16.json)
and [the broader connected-border contract](CONNECTED_BORDERS.md).

## Active cast follow-up

The same user report supplied Blackmouth Oil and Conjure Water captures with
active crafting chrome/icon and fill-fit issues. These are distinct from the
successful green finish already confirmed by the user.

| ID | Requirement | Implementation / acceptance |
|---|---|---|
| ACF-01 | Correct active crafting warning | A readable crafting flag selects ordinary crafting chrome/fill. The same warning predicate governs initial artwork, color/shield paint and appearance refresh. Actual protected combat casts retain their warning; private/unknown values do not become a guessed crafting exemption. |
| ACF-02 | Paint a real icon | Missing/placeholder/rejected public icons use existing spell/profession fallback data. A successful native setter call with no texture is not sufficient. Restricted icons remain native paint inputs without inspection. |
| ACF-03 | Fit icon/fill consistently | Derive vertical insets from the selected border's actual tracks. Type1 remains unchanged; Type2 corrects its one-UI-unit offset. Keep total row dimensions, icon width, unit layout and pet inset. Match optional sampling settings to the border. |
| ACF-04 | Preserve static/lifecycle behavior | Keep green success, active profession artwork, interrupt/channel/empower behavior, timers and layout guards. No added driver, mask, frame, new saved option or border solve on ordinary cast paint. |

Offline tests establish their stated source/model and arithmetic scope only.
An actual-client visual comparison is recorded separately from those results;
no native FPS/taint or complete cross-client guarantee follows from them.

User visual acceptance,17November: after the requested reload and both-style checks,
the user reported “Connections look right” and “Crafting and fit look right”.
This is user-operated game feedback; no agent native capture, input, security or
FPS measurement was performed. Broader party join/leave performance is a new
active investigation and is not marked resolved by these visual results.

## Leading-edge and crafting-flare follow-up

17 November (`CAST-DIVIDER-FLARE-20261117`): the Mooncloth capture showed a gap
beside the first name letter. The native fill's rounded leading alpha was not
covered by the old center-row check. The shared non-pet fill and trough now
extend two UI units farther beneath the icon divider. The name compensates by
the same amount, keeping its screen position. Protected-cast completion, flight
label fitting and swing/Shoot label bounds use the same compensation. Header/icon dimensions, right edge,
pet resource overlay and prepared layout guards remain.

The wide profession flare now shares the fill's existing native progress mask,
matching the profession owner's masking of both textures. This clips early
progress to the bar without another mask, region or update driver. Profession
art/settings, source and Spark restoration, restricted progress sinks and the
plain green success finish remain. Recipe classification is unchanged.

| ID | Acceptance |
|---|---|
| CDF-01 | Shared leading-cap coverage and unchanged text origin on both border styles; pet no-icon policy retained. |
| CDF-02 | Fill and flare bind the same mask once; early progress, recast, source replacement, edge-off and missing-flare restoration covered. |
| CDF-03 | Existing visibility cache, combat defer, timers and secret handling retained; passive art adds no controller focus stop. |

Fourteen focused scripts pass, including a new upper-leading-alpha assertion and
826 active-crafting checks. Archived casts fail the leading-cap test; archived
profession code fails the flare-mask test. Seven syntax checks and 286 runtime
compiler prototypes pass (maximum 52 upvalues). These checks establish their
model scope. Native Mooncloth/ordinary-cast seam appearance in both styles is
pending; native FPS, taint and controller operation were not measured.

See [exact sources and evidence](validation/cast-divider-flare-2026-11-17.json).

## Type 1 cast icon seam

20 November. Type 1 puts the icon-side divider at −1.5 UI units from the
shared edge. The icon artwork ended at −2, leaving half a UI unit before
the divider. The icon now ends at the same style-specific track used by the
fill-effect clip. Type 2 already ends there. The fill rectangle, glow clip,
header geometry and pet overlay keep their existing anchors. Swing and
Shoot follow the prepared cast header.

The archived cast source fails the new divider alignment assertion. The
current layout passes in both styles and both header alignments across five
client models. A live screenshot comparison remains pending.
[Evidence](validation/cast-type1-seam-2026-11-20.json).

### Continuous cast border rim

The user reported that the gap remained after the icon adjustment. The
source-art replay reproduced an interruption in both styles. The vertical
divider took over the inner part of the horizontal rim at the two
T-junctions. An opacity-only check passed because the vertical artwork was
opaque at those samples.

The renderer now keeps the horizontal artwork through the rim and joins the
vertical divider against it. The rule uses the registered border track and
source scale for each style. A future style can use the existing normalized
canvas and declare its own tracks. The same join rule applies to its artwork.
The replay includes a simulated new profile with different tracks and a
distinct material identity. Both released styles and the test profile pass
source-ownership and opacity checks at both ends of the divider.
[R188 evidence](validation/cast-rim-r188-2026-11-20.json).

### Vertical cast divider

The user identified the remaining line beside the spell icon. The renderer
was using the surrounding bevel of an outside edge on this internal seam.
In R189, the divider renders a narrow band centered on the style's own
stroke track. Its width follows the registered thickness. Straight
fragments and T-junction fields use the same trimmed paint bounds.
The horizontal rims and outside corners retain their own artwork.

The source-art replay checks the divider center, both margins and both
junctions in the released styles and a simulated third profile. The
archived renderer fails the margin check for all three profiles. Native
appearance remains pending. [R189 evidence](validation/cast-divider-r189-2026-11-20.json).

The follow-up crop shows that the Type 1 divider reads too thin. R190 uses
two UI units on the icon side and one on the fill side. The fill edge and
track stay in place. The renderer uses the icon-side width from the pattern
profile, or the thickness-based width when the profile omits it. The same
paint bounds apply to the straight run and mitered ends. This is decorative
chrome and adds no controls or focus stops.
[R190 evidence](validation/cast-divider-weight-r190-2026-11-20.json).

## Optional unit parts, glow interior and capture reasons

17 November (`CAST-UNIT-JUNCTIONS-20261117`): prepare perpendicular continuations
where an optional class/spec icon, target-of-target or HP/resource divider can
disappear. Four T directions and X reuse existing native paint availability
forwarding. Equivalent parallel backups inherit the keeper's cuts, preventing
duplicate paint. Ordinary visibility reveals prepared fields without geometry
reads or solves in the fixture. No target/focus global invalidation is added.

Eligibility is narrow: unknown, shifted, cropped, mixed-scale or ambiguous backup
profiles retain their exact previous field policy. Per-pass markers reset and
existing fragment/triangle limits remain. The initial gate exposed incorrect
accounting of synthetic cells as native bitmap fragments; that failure and its
correction remain in the evidence.

The cast glow clip now reaches the actual top/bottom header core and icon-right
divider during prepared layout. Earlier fill/name compensation, icon/header
dimensions, pet inset, profession mask and green finish remain. Swing/Shoot uses
that clip. No region, mask, driver or per-cast layout path was added. A three-unit
crossbar experiment was rejected because it worsened alpha steps.

| ID | Acceptance and evidence |
|---|---|
| CUJ-01 | Glow bounds and unchanged fit: two focused and eleven dependent cast scripts pass. Native tiny-notch comparison pending. |
| CUJ-02 | Optional parts: 357 checks, 177,498 source samples; prior 3,108 missing samples become zero, with exact modeled premultiplied RGBA. |
| CUJ-03 | Generic/ambiguous/foreign output stays unchanged; budgets and cache/reparent cases pass. |
| CUJ-04 | Prepared visibility uses zero geometry reads, solves or allocations in the fixture. Decorative changes add no controller focus stop or input route. |
| CUJ-05 | Active cost records reuse at most three existing `readReasons` and addon-owned `dirtyState` counts. 342 checks include getter parity. These do not establish upstream event causation. |
| CUJ-06 | Performance chat owns coordinated native validation; current pixels, GPU/FPS and taint remain pending. |

Final stable border/unit gate: 59 scripts pass; the cost regression is a separate
passing script. Thirteen syntax checks and 463 runtime compiler prototypes pass
(maximum 56 upvalues). These are scoped desktop results. The unchanged
`watch-mesh-phases-r60` label does not prove loaded-source adoption.

See [exact sources, failures and validation](validation/cast-unit-junctions-2026-11-17.json)
and [the collaboration reply](COMBAT_COLLABORATION_BORDER_REPLY.md).

## Mini fill and unit palette follow-up

17 November (`MINI-UNIT-FIT-COLORS-20261117`): target-of-target, player-pet and
party-pet outlines now use a fixed75% geometry profile of the selected border.
Global type1/100% and type2/150% artwork, UVs and nominal padding are preserved.
Corner size/overhang and separator height scale together; the content frame and
whole-frame scale stay with their existing layout owners. The attachment fitter
uses the scaled corner overhang to meet the parent's portrait stroke.

Mini fill-bearing HP/resource hosts and opaque class backdrops use3 UI units
left/right and5 top/bottom. Prediction geometry follows W-6/H-10; a28-high
health-only party pet gets18 units of health. HUD health can still extend behind
the fixed power layer. The separator's actual source core is centered in the
split. ToT's old outward left/right overrides are removed. This intentionally
updates UOA-01's earlier fill-preservation rule for the new reported corner leak.

| ID | Requirement and implementation |
|---|---|
| MIF-01 | Mini-only thinner outlines, same root/overlay relationship and both selected styles; no thickness option. |
| MIF-02 | Health, resource, prediction/trough/backdrop and hover interior fit the rounded outline; no new mask chain. |
| MIF-03 | ToT players keep their own class policy like target; player pets use player class, party pets use their authored owner token or preview class. Appearance does not override these unit policies. |
| MIF-04 | Explicit false natural/no-unit-color boundaries prevent parent PC/NPC changes from repainting the child with inherited material. Unknown owner class retains prepared public color. |
| MIF-05 | Constructor, appearance/preview and normal/combat paint agree. The existing pet-cast chrome getter uses owner class without changing cast fit, fill or green completion. Existing eligible friendly dispel overlays retain priority and eligibility. |
| MIF-06 | Existing protected-layout guards, static warm geometry and independent unit ownership remain; no new frame/mask/driver/event/hook/settings/input or Core builder change. |

Actual-source tests cover thin construction, fit, parent contact, detachment,
prepared visibility/color/combat work, public prediction bounds and color
lifecycles. Static artwork-contour sampling is separate from native pixels.
Decorative pieces add no focus stops; native controller/taint/FPS and current
in-game visual acceptance remain untested. The performance chat owns the next
combined gate and Mario reload/capture.

See [exact sources, tests and retained failures](validation/mini-unit-fit-colors-2026-11-17.json)
and [current reload coordination](COMBAT_COLLABORATION_BORDER_REPLY.md).


## NPC Default and restricted ToT paint

17 November (`TOT-NPC-SECRET-COLORS-20261117`): NPC target/focus and their target
units always use the selected style's Default palette and artwork, independently
of the Appearance accent. Friendly/neutral/hostile names keep reaction colors.
PCs keep their own class policy; pets keep the owner policy above.

| ID | Requirement and implementation |
|---|---|
| TNC-01 | Default NPC material/RGB/backdrop survives atlas/class/custom Appearance and parent PC/NPC changes in both border types. |
| TNC-02 | Opaque ToT names go directly to native formatted text; the prefix stays white. Public levels remain; private levels are omitted. Private channels never enter Lua hex formatting or class-table keys. |
| TNC-03 | Where available, native class-color lookup forwards opaque class identifiers and RGB to native border/backdrop/separator/text sinks. A public neutral geometry proxy does not contain private channels. |
| TNC-04 | Opted-in prepared static unit fields repaint without a solve or geometry read on warm color transitions. Generic unsupported private-color fallback is unchanged. |
| TNC-05 | Unknown classification or unavailable native class capability holds prepared paint. No new mask/frame/driver/event/input or controller focus stop; existing dispel/combat priority and mini fit remain. |
| TNC-06 | Broad76 passed before final name pacing refinement; final9 focused scripts and7 compiles pass on exact final sources.636 runtime prototypes/max56upvalues. Native security/pixels/CPU/FPS remain pending. |

Source contracts are pinned per client; a native paint declaration and source
model do not certify live combat behavior. The performance chat owns the next
combined gate and Mario-only reload/capture.

See [exact sources, controls and qualifications](validation/tot-npc-secret-colors-2026-11-17.json)
and [the current collaboration reply](COMBAT_COLLABORATION_BORDER_REPLY.md).


## Portrait backdrop straight-edge fill

17 November (`PORTRAIT-BACKDROP-GAP-20261117`): user clarified the narrow
screenshot gap is inside the player portrait backdrop. Prepare one plain fill
texture along the straight left interior edge, before initial portrait color.
It covers the one-unit strip between the flat background and inner border
shadow; it stops five units inside the existing background's top and bottom.
The rounded corner areas, original background and model bounds stay intact.

| ID | Acceptance |
|---|---|
| PBG-01 | Actual straight interior has fill coverage with no overlap/double opacity at the original background; corner areas receive no new coverage. Both selected styles retain their original border geometry. |
| PBG-02 | Existing normal/class/custom/combat/native restricted paint, alpha and hide/show update the continuation with the same RGB and opacity. Legacy native texture-color fallback forwards channels unchanged. |
| PBG-03 | Construct once; reuse on color/visibility changes. No new mesh registration, builder invalidation, frame/mask/driver/event/hook/settings/input or controller focus stop. Mini profiles keep their tighter fill fit. |
| PBG-04 |17 focused scripts pass; final coverage/legacy-sink regression26496checks in288 real constructor scenes, plus30816 retained geometry checks. Two runtime files448prototypes/max20upvalues. Native screenshot/taint/CPU/FPS acceptance pending. |

The existing sampling capability guards keep adjacent flat fills on the same
continuous boundary at fractional HUD scales. No border builder code changed.
Native comparison remains with the performance chat's coordinated Mario test.

See [exact sources and coverage negative control](validation/portrait-backdrop-gap-2026-11-17.json)
and [current collaboration status](COMBAT_COLLABORATION_BORDER_REPLY.md).


## Attached stance/player backdrop contact

17 November (`STANCE-PORTRAIT-BACKDROP-CONTACT-20261117`): user identified the
remaining vertical strip when the stance bar sits beside the player portrait.
The earlier one-unit continuation was incomplete. It now reaches the portrait
edge across the full inset. The stance backdrop also stopped1.5 UI units short:
its root anchors RIGHT-to-player-LEFT at+4 while its background used5.5 padding.
Only attached chrome now uses STANCE_ANCHOR_GAP at the background's right point,
so the two actual background endpoints meet. Detached padding is restored by
the existing mode-change constructor. Left/top/bottom and round areas remain.

| ID | Acceptance |
|---|---|
| SPC-01 | Actual Stance.Anchor and ApplyBorderChrome make the attached background meet player-left, in both styles and fractional scales. Full portrait inset has coverage to its edge. |
| SPC-02 | Stance left/vertical padding, portrait corner exclusions, mini fitting and model/root geometry remain. Detach restores original background defaults; reattach restores contact. |
| SPC-03 | No new resources or refresh path. Cold/mode change adds one background point write; repeated locked/unlocked chrome keeps zero geometry/resource work. Existing private/color/alpha policy remains. |
| SPC-04 | Six focused scripts and four compiles pass. Contact2208checks/288scenes; portrait26496checks/288scenes. Archived sources fail actual endpoint/full-inset coverage. Native pixels/taint/CPU/FPS remain pending. |

The native point-replacement semantics in the test fixture were corrected; its
initial duplicate-anchor failure is retained. Core and Stance.Layout are
unchanged. This adds no controller focus stop, input action or visible label.
[Exact sources and qualified evidence](validation/stance-portrait-backdrop-contact-2026-11-17.json).
