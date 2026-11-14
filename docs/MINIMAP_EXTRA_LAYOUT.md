# Configurable minimap extra buttons — 13 November 2026

Task `MINIMAP-LAYOUT-20261113` implements the user's two layouts for the same
character action slots. The prior direct-implementation choice and user-managed
native reproduction route recorded in STATUS/NEXT_SESSION remain in effect.
The existing five-client scope is retained: Retail, Forever, MoP progression,
Era and Anniversary. This task does not change TOCs or client detection.

## Screen-side border and minimap clock layering

`MINIMAP-SIDE-BORDER-20261113` follows the user's screenshot and clarification:
the minimap cluster/clock was drawing over the buttons. The reported defect is
layering, rather than grid spacing or the intentional mouseover overlay.
Direct implementation and user-managed native reproduction remain accepted.

| ID | Requirement | Implementation / acceptance |
|---|---|---|
| REQ-MBL-24 | Screen-side FluxBorder follows all button visibility, including combat. | One lazy decorative host uses actual `FluxBorder:ApplyTo`/`SetClassColor`, parented inside the existing secure visibility gate. The border/background inherit hover hiding, secure combat hiding, disabled/window ownership and scale. Empty filtered grids and embedded mode hide the side border. There is no separate border visibility driver, timer or event. |
| REQ-MBL-25 | Minimap cluster and timer must not cover side buttons. | Side root, gate, slots and native-template widgets use HIGH; explicit template strata are overridden. The border/background use the same tier, with backdrop below buttons, border above their art and the existing flyout arrow above the border. Embedded mode restores MEDIUM and has no side border. Native minimap/clock frames keep their existing placement, strata, handlers and ownership. |

The earlier root used MEDIUM level 25, while the info-bar clock was placed above
its border and zone hit area (typically MEDIUM level 45). Its text and hit region
could therefore cover the column in mouseover mode. Side-only HIGH fixes drawing
and hit priority. The decorative host and border disable mouse input, leaving
button activation and lower chrome outside the grid unchanged. Tooltips and
existing flyout popup tiers retain their normal priority.

The border uses the shared atlas/legacy artwork and accent/backdrop registry,
following the exact grid rectangle and effective scale without adding layout
padding or changing packing, saved actions, count, settings or minimap size.
The shared border's usual BACKGROUND backdrop would fall behind the minimap, so
this instance places it in HIGH beneath the button art. Resources are created
once: one host plus the border service's two frames and normal textures. Reflow
and appearance changes reuse them. Layout and border frame changes remain
outside combat; requests in combat defer through the existing service. Native
secure hiding controls their common ancestor and does not call an insecure
border hide handler on combat entry.

[Checkpoint](validation/minimap-side-border-checkpoint-2026-11-13.json) verifies
2,724 source files, full history and 99 settings metadata entries outside AddOns;
private values were not copied. [Source evidence](validation/minimap-side-border-sources-2026-11-13.json)
re-resolves Retail/Forever/Classic pins and records the native/addon chrome
contract. [Validation](validation/minimap-side-border-2026-11-13.json) records
exact baseline/candidate identities, real FluxBorder/arrow-layer execution,
atlas/legacy models and meaningful controls. The screenshot establishes the
reported symptom only; its native build and settings were not captured.

Native acceptance remains **NOT RUN** on all five clients: reload out of combat,
enable the side grid and check the screenshot's overlapping clock/minimap area.
Buttons and their border must draw above the clock and receive clicks there;
clock/minimap interactions outside the grid must remain native. Test both starts,
scales 10/100/200%, automatic columns, empty hiding, dynamic drag/cancel/delete,
theme changes, mouseover enter/leave, shown/hidden combat entry, combat-hide,
deferred transitions, embedded restoration and flyout arrow/popup interactions.
Check controller focus and activation through the existing options/button paths;
the passive border must not become a focus stop. Native input, event delivery,
taint, pixels, controller and CPU/FPS remain pending; desktop layer comparisons
do not certify native rendering or combat safety.

## Dynamic minimum and automatic frame movement

`MINIMAP-DYNAMIC-20261113` supersedes the earlier growth and movement choices in
REQ-MBL-19/20. HUD → Flux Window → General now calls the existing `autoGrow`
toggle **Dynamic button count**. **Button count** remains the saved minimum;
drag/drop and deletion never rewrite it. The independent movement option is
removed. Existing direct implementation, English fallback and user-managed native
reproduction/controller assessment remain accepted.

| ID | Current requirement | Implementation and observable acceptance |
|---|---|---|
| REQ-MBL-22 | Fully dynamic add/remove with configured minimum in both layouts. | Select all assigned indices up to 120, then enough empty indices to reach the minimum. A carried action adds one temporary empty target only when no selected slot is empty. With minimum 15 and all 15 filled: idle 15 → carry 16 → cancel/drop elsewhere 15, or drop on the new slot 16. The next spare appears on the next drag. Deleting assignments compacts toward 15, including interior holes, without renumbering saved records. |
| REQ-MBL-23 | Movement follows visibility; no independent movement option. | Always shown automatically reserves the side grid's width through the existing minimap/Questie/objective/aura owners. Mouseover returns zero reservation offsets and overlays their normal positions. Combat-hide does not change reservation. Remove the toggle, locale strings and active default; ignore the retired `sideMoveFrames` value while retaining its saved data. |

Dynamic packing uses saved action records as its authority, including assigned
items with zero inventory and existing higher macro records. It preserves widget
identities, keybinds and all saved indices. Enabling dynamic mode also restores
previously saved assignments above the configured minimum; disabling it returns
to the first configured indices without deleting higher assignments. Empty
screen-side hiding remains separate: it may hide minimum placeholders, while
dragging reveals one usable empty target. Embedded layouts retain their minimum
placeholders. The supported cap remains 120.

`CURSOR_CHANGED` is active for dynamic mode in either visible layout, and for
side hide-empty mode. It is removed when neither feature needs it or the grid
is inactive. Existing coalescing waits until EBS's synchronous cursor-clear and
save/delete callbacks finish. Preview creation/removal and layout stay deferred
during combat; after combat the current cursor state determines whether the
preview is still needed. Mouseover still freezes during combat and explicit
combat hiding still belongs to the existing secure inner gate. Embedding ignores
side visibility policies. No new frame, poll, ticker, native API, hook or event is
introduced; only the existing cursor subscription gains the dynamic mode scope.
Selection is bounded to 120 saved indices; widgets remain allocated for reuse.

[Checkpoint](validation/minimap-dynamic-checkpoint-2026-11-13.json) verifies 2,706
source files, full history and 99 settings metadata entries outside AddOns;
private values were not copied. [Fresh source resolution](validation/minimap-dynamic-sources-2026-11-13.json)
retains the previous Retail/Forever/Classic commits and existing loaded cursor/
secure contracts. Era/Anniversary retain existing guards without new source
certification. [Validation](validation/minimap-dynamic-2026-11-13.json) records
exact baseline/candidate identities, paired behavior and meaningful controls.

Native acceptance remains **NOT RUN**: reload outside combat; set minimum 15,
enable Dynamic button count and fill all slots in each layout. Carry/cancel,
drop onto an existing slot, drop onto slot 16, repeat for 17, delete an interior
or final assignment, and reload. Confirm the minimum remains 15 and saved macro/
item actions and bindings survive. Test manual minimum changes, sparse higher
indices, hide-empty on/off, both side starts and scales 10/100/200%, cap 120,
combat drag/cancel/exit, flyout closure and controller/virtual-cursor interaction.
Mouseover must leave minimap, Questie, objectives and auras at their normal dock;
Always shown must automatically reserve room. Native input, event delivery,
taint, pixels, persistence, controller and CPU/FPS remain pending on all five
clients; desktop counts are not native performance evidence.

## Empty slots, automatic growth and optional overlay visibility

`MINIMAP-VISIBILITY-20261113` originally added four character preferences under
HUD → Flux Window → General. REQ-MBL-22/23 above replace its growth and movement
rules; the other grid/scale/visibility requirements remain.
The existing direct-implementation and user-managed native reproduction choices
remain accepted; no new setup, client control or synchronization was performed.

| ID | Requirement | Result |
|---|---|---|
| REQ-MBL-18 | Toggle hiding empty screen-side buttons. | `sideHideEmpty`, default false, compacts only unassigned numbered slots. Assigned items with zero inventory remain assigned and visible. One empty slot appears while carrying an action, including an initially empty grid; cancelling the drag hides it again. Embedded layout retains every configured slot. |
| REQ-MBL-19 | Toggle increasing the shared count after a drop fills all configured slots. | Superseded by REQ-MBL-22: `autoGrow` now enables a dynamic minimum and temporary drag target; it never writes the configured count. |
| REQ-MBL-20 | Optionally leave minimap, Questie, objectives and auras in their normal positions. | Superseded by REQ-MBL-23: mouseover automatically overlays, Always shown automatically reserves room; no independent movement setting. |
| REQ-MBL-21 | Always shown, mouseover, combat hiding, and no mouseover changes during combat. | `sideVisibility`, default `always`, also offers `mouseover`. The separate existing `hideInCombat` toggle remains visible, including while embedded. Combine these for always shown, mouseover, hide only in combat, or mouseover plus combat hiding. Embedded buttons ignore these side-only choices. Hover's last shown/hidden state freezes during combat and resumes from the current pointer after combat. Explicit combat hiding still uses the native secure driver. |

Collapsed grids pack visible slot indices without renumbering saved actions,
recreating widgets or changing keybinds. The existing outer container owns hover
visibility; the existing inner secure gate owns combat hiding. This separation is
required because the native visibility driver repeats `show` outside combat; it
must not override hover hiding. Hidden containers/slots inherit the existing
secure flyout closure and binding release. Hover includes visible flyout popup and
arrow geometry. There are no invisible clickable buttons or mouse-capturing
sensor frames. The owner reads its own geometry and cursor coordinates only.

One 0.1-second ticker uses `Flux.Timer` only for the active side mouseover mode.
It stops in combat, when embedding, disabling the side grid or choosing always
shown. Its callback also checks lockdown before any show/hide. `CURSOR_CHANGED`
is subscribed for an active dynamic layout or side hide-empty mode. It queues/coalesces
refreshes until synchronous EBS `ClearCursor`/save callbacks finish; combat changes
defer through the existing combat service. No per-frame updater or new frame is
added. Defaults add no ticker/cursor subscription. The boolean normalizer now
preserves an explicitly false value for the new default-true movement setting.

Source evidence: fresh Gethe branch resolution retained Retail
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`, Forever
`bebcb6bf309cf41b41bd74f8ca651e6a105b2676` and Classic progression
`e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`.
[Cursor/state contracts](validation/minimap-visibility-sources-2026-11-13.json)
supplement the earlier loading/security ledger. Source declarations do not prove
native event delivery, protected execution or addon access. Era/Anniversary retain
existing guards without fresh branch certification. The
[external checkpoint](validation/minimap-visibility-checkpoint-2026-11-13.json)
verifies 2,697 source files, full history and 99 settings metadata entries; private
settings were not copied. [Validation](validation/minimap-visibility-2026-11-13.json)
records exact baseline/candidate identities and the scope of desktop checks.

Native acceptance remains **NOT RUN** on all five clients: reload out of combat;
toggle empty hiding with sparse and zero assignments, depleted assigned items,
cancelled drags and successful drops; fill the last slot in both layouts with
growth on/off and at count 120. Confirm drag swaps, macros, flyouts and saved
hidden assignments survive reload. For both starting positions and scales
10/25/100/200%, choose mouseover and verify minimap/Questie/objective/buff/debuff
positions stay at their normal dock. Test all four visibility combinations,
hidden/shown hover states on combat entry, pointer motion during combat, option
edits and deferred embedding/restoring. Check flyout arrows, popup interaction,
secure binding release and absence of invisible click blockers. Controller users
can choose Always shown; native options reachability, focus/activation, virtual
cursor and combat input still need per-client acceptance. Native pixels, taint,
persistence, CPU/FPS and profiler comparisons remain pending; desktop counts or
wall time are not native performance evidence.

## Current behavior: automatic grids and screen-side grid scale

`MINIMAP-AUTO-LAYOUT-20261113` records the user's latest requirements. Both layouts
choose their button columns and size automatically from the shared count and
available rectangle. Screen-side placement still fills the rightmost column
before continuing left. The separate **Screen-side grid scale (%)** control scales
the entire side grid from **10% to 200%**, default 100%. The new 100% equals
the previous 85% size; the runtime factor is `percentage × 0.85 / 100`.

| ID | Current requirement | Implementation / acceptance |
|---|---|---|
| REQ-MBL-12 | Embedded columns and button size are automatic; no embedded map-size setting. | Search the bounded possible grids for the largest squares that fit all slots; ties prefer fewer columns. The square map fits automatically and reserves a usable button strip in narrow/tall windows. Remove embedded columns and minimap-size controls and ignore their stored legacy values. |
| REQ-MBL-13 | Screen-side columns and button sizing automatically add/repack columns as needed. | At 100%, use 44-point buttons when possible; dense columns share two standard buttons of width. Choose the largest fit, then fill downward to the chosen grid boundary before continuing left. Remove the manual column count. Both starting positions and the window boundary remain supported. |
| REQ-MBL-14 | Retain a 10–200% whole-grid screen-side scale. | Reuse character `sideScale`, extend its range to 200%, and scale the root including padding, buttons, text, arrows and popups. Refit at every scale in the available local height to keep controls above Flux Window. Completed columns reach the window boundary exactly; short lists retain standard sizing. Map/tracker/aura reservation uses the actual scaled width; embedded layout always restores scale 1. |

Current `REQ-MBL-15` additionally requires zero layout gaps at the minimap, screen
and Flux Window; its implementation and screenshot evidence are described below.

Retired `embeddedColumns`, `embeddedMapScale` and `sideColumns` values remain saved
without influencing layout. Assignments and macro recovery records remain in the
same numbered slots. Active `sideScale` values are preserved and bounded to
10–200%. The shared count, optional side enablement, start position and secure
combat-hide option remains visible and applies only to the screen-side layout.
There is no embedded map-size or columns control.

This supersedes manual choices described in the historical sections and original
REQ-MBL-02/03/05/10 below. Both grid packing paths reuse one pure bounded fit helper;
it examines at most the supported 120 columns only when layout changes. No new
frame, event, timer, ticker, hook, polling or native API contract is introduced.
Existing out-of-combat geometry, pending combat state, visibility ownership,
controller paths, English fallback and user-native reproduction choices remain.

[Fresh checkpoint](validation/minimap-auto-embedded-checkpoint-2026-11-13.json)
contains 2,638 verified source files and full Git history outside AddOns; 103
settings metadata entries were inspected without copying private values.
[Current validation](validation/minimap-auto-layout-2026-11-13.json) and
[baseline/regression controls](validation/minimap-auto-layout-controls-2026-11-13.json)
record exact source identities and desktop results. Existing fresh Gethe source
pins from the earlier layout and aura ledgers remain applicable; this follow-up
changes addon-owned geometry and existing options only.

Native acceptance: reload out of combat, vary the shared count and Flux Window
size, and confirm both layouts repack without overlap. Test side scale 10/25/50/100/
150/200%, both starting positions, and a dense strip. At large scales, additional
columns may be necessary to keep the window clear. Verify map/tracker/buff/debuff
space, saved assignments, flyout scale/closure, hidden tabs, whole-window hiding,
combat changes and controller focus. Native pixels/input/taint/controller/
persistence/FPS remain NOT RUN; no such result is inferred from desktop fixtures.

### Combat hiding applies only to the screen-side grid

`MINIMAP-SIDE-COMBAT-20261113`, requirement `REQ-MBL-17`, supersedes the original
both-layout combat-hide behavior. **Hide screen-side buttons in combat** remains
visible in Flux Window → General even while the map is embedded. Its saved
`hideInCombat` key is retained; there is no mode-dependent hidden/disabled rule.
The existing capability check may still disable unsupported secure hiding.

Only the active normal-map side layout installs the secure visibility driver.
Embedding removes that driver out of combat and shows its existing visibility
owner. With the embedded map tab/window shown, this preference cannot hide the
buttons on combat entry or after edits in combat. Returning to the normal-map
side layout reapplies the saved preference, including secure flyout/arrow hiding.
No setting reset, action change, new driver kind, event, hook, frame or polling is
introduced. Existing tab/window visibility still applies, and protected layout or
tab changes requested during combat remain deferred until combat ends; the change
does not attempt an insecure hide/show of protected controls during lockdown.

[Checkpoint](validation/minimap-side-combat-checkpoint-2026-11-13.json) and
[validation](validation/minimap-side-combat-2026-11-13.json) record exact source
identities and checks. Existing source pins, direct implementation, English fallback
and user-managed native reproduction/controller assessment remain in effect.
Native acceptance: keep the setting enabled, embed the minimap, enter combat and
confirm the grid remains usable; confirm the option stays visible in settings.
Return to the screen-side layout and confirm combat hiding works again. Exercise
both side starting positions, flyouts, preference edits, inactive tabs and deferred
transitions. Native pixels/input/controller/persistence/taint/FPS remain NOT RUN.

### Scale normalization: 100% equals the previous 85%

`MINIMAP-SCALE-BASIS-20261113`, requirement `REQ-MBL-16`, implements the user's
new default and slider range. The displayed default remains 100%; its effective
frame scale is now 0.85. The displayed range is 10–200%, mapping to effective
frame scales 0.085–1.7. Automatic packing and zero layout gaps are retained.

Old saved `sideScale` values without `sideScaleVersion = 2` are interpreted in
previous units and divided by 0.85 for display. Fractional percentages preserve
exact effective sizes instead of rounding and potentially changing columns.
Reading a preference does not rewrite its original record. Choosing a new scale
stores the new units plus version 2, preventing repeat conversion. An old 85%
choice therefore becomes displayed 100% with identical geometry. Values above
the new effective ceiling (previously above 170%) are capped by the requested
new 200% limit; their original saved record remains intact until edited.

A character without a saved scale uses new100%/effective0.85. Explicitly selecting
new100% sets that same default size even on an older character. Existing action
assignments, other settings, embedded sizing, combat deferral and controller/input
paths remain unchanged. No new frame/event/timer/hook/poll is introduced. English
fallback text documents the normalized default; native pixels, controller/input,
combat taint, persistence and FPS remain pending user verification.

[Checkpoint](validation/minimap-scale-basis-checkpoint-2026-11-13.json) and
[validation](validation/minimap-scale-basis-2026-11-13.json) record source identities,
metadata-only settings inspection and actual checks. The previous direct
implementation/user-native reproduction choices and source/API pins still apply.

### Zero-gap follow-up

The user's attached native screenshot reports visible gaps at the minimap, screen
edge and Flux Window. The image establishes that symptom only; its source/build
identity was not captured. The final layout removes explicit outer margins and
container padding, including the grid-to-map gutter in the embedded layout.
Embedded buttons align directly to the map's left edge. Side grids touch the
chosen top/minimap edge and screen-right edge at every grid scale. A completed
column uses an integer row count and adjusts its square size to reach the Flux
Window exactly, avoiding fractional-row slack before wrapping left. Small lists
keep their normal maximum button size rather than being stretched to fill unused
space. Count, 25–200% scale, saved actions and combat guards remain.

The earlier proportional-shrink policy below 100% is superseded: every percentage
now refits against available height to use space freed by removing the gaps.
Native candidate pixels/taint/input remain pending user verification after reload;
frame-boundary assertions do not establish native artwork pixel parity.

## Follow-up: screen-side resizing and aura placement

`MINIMAP-SIDE-AURA-20261113` is the historical resizing/aura follow-up (its manual
size policy is superseded above). It addresses the user's follow-up that screen-side
buttons need resizing and the aura frames must move with the beside-map layout.

| ID | Requirement | Implementation and observable acceptance |
|---|---|---|
| REQ-MBL-10 | The screen-side size control must resize buttons, including crowded layouts. | Keep the existing character setting and 25–100% slider under Flux Window → General. Apply its percentage after the default size fits the available height. In a height-limited 120-button strip, 50% must produce half the fitted button size and 25% one quarter. Recompute downward column packing and reservation from the resulting size. |
| REQ-MBL-11 | Buff and debuff frames move left when buttons are beside the normal minimap. | Add the same `GetMinimapOffset()` reservation to the existing native aura-frame screen anchors. Refresh through the existing aura placement service on shared layout changes, including disabled/hidden transitions. Below-map, disabled and embedded layouts return the auras to their previous positions; retain their gap, row separation, scales, native ownership and Edit Mode/combat guards. |

The resize defect occurred because the slider reduced the default size before a
smaller height cap was applied. Both 100% and lower settings could therefore end
up at the same final size. The percentage now scales that fitted result. Default
100% behavior, the two-standard-column width limit, settings identities and saved
actions remain unchanged. This follow-up adds no setting or control.

Auras retain their independent screen anchors and Blizzard's native content,
styling, interaction and lifecycle. Only the horizontal reserved space changes.
The existing `RefreshLayout` path invokes aura placement before its hidden-layout
return, so switching the strip off also restores aura position. No new frame,
event, timer, ticker, hook, updater call or polling is introduced. Combat settings
continue to save intent and apply geometry after combat; the aura owner separately
honors Edit Mode. It never reparents or traverses native aura buttons.

[Fresh recovery checkpoint](validation/minimap-side-aura-checkpoint-2026-11-13.json)
contains 2,630 current source files and verified full Git history outside AddOns.
69 settings metadata entries were inspected read-only; private values and client
preferences were untouched. The follow-up passes 3,415 resize and 1,855 aura
checks, three matched baseline/candidate pairs per scenario, five harmful controls
and the complete 322-script/1,004-syntax desktop suite; its full Lua source manifest
matches current files. Native checks remain separate. The changing-document capture attempt is retained
externally as well. [Follow-up evidence](validation/minimap-side-aura-2026-11-13.json)
records source identities, regression results and current verification limits.

The previous direct-implementation choice, user-managed native reproduction route,
English option catalog and controller assessment remain in effect. The existing
range widget, buttons and native aura controls retain their input paths and focus
roles; this change adds no navigation or binding. Native pixels, slider/controller
operation, saved-setting persistence, secure input/taint and FPS remain NOT RUN.
After an out-of-combat reload, test a crowded side strip at 100/50/25%, then toggle
beside/below/off/embedded states and check buffs/debuffs. Repeat after changing
column/count settings and after combat/Edit Mode exit. The aura offset should
track the actual strip width and reset when the beside layout is released.

## Original requirements and implementation matrix

| ID | Requested behavior / acceptance | Implementation | Verification |
|---|---|---|---|
| REQ-MBL-01 | Increase the original 15 buttons; both layouts use one count and identical assignments. | Character `minimapExtraLayout.count`, 1–120, default 15. Existing `minimapExtraButtons[index]` records and macro recovery fields retained. | Runtime growth/shrink/regrowth and higher-slot drag/delete/macro callbacks pass. Native persistence pending. |
| REQ-MBL-02 | More embedded buttons shrink to fit the available area. | Embedded columns 1–8, default 3; button squares fit the remaining width beside the map and the window height. Existing row order retained. | Bounds, dense counts, independent scales and retained widget identities pass. Native pixels pending. |
| REQ-MBL-03 | Resize the embedded minimap to arrange the Flux Window. | Square map size 40–100% of its previous fitted size, default 100%; stays right aligned with its info bar. Startup watcher, same-parent refresh and window resizing use the preference. | Real map/window methods cover slider changes, startup settling and resized windows. Native pixels pending. |
| REQ-MBL-04 | An optional external layout appears only with a normal minimap. | `sideEnabled` defaults false. Uses the same widgets and slots; other embedded tabs suppress both layouts. | Normal/embedded/hidden-tab/released transitions pass. Native tab/input check pending. |
| REQ-MBL-05 | One/two columns use standard buttons; denser columns can fit into two-column width. | Side columns 1–8, default 1. Native 44-point buttons when space permits; 3+ columns share 88 points of button width. Side size 25–100% can reduce further. | One/two-column native sizes, three-column width and dense-height fitting pass. Native pixels pending. |
| REQ-MBL-06 | Fill vertically to above Flux Window before starting the next column. | Start with the rightmost column, fill down to the available boundary, then continue left. Shrink if all requested slots cannot fit in the chosen columns. | Observable column order, map/window bounds, scale conversion and max-count checks pass. |
| REQ-MBL-07 | Choose below the minimap or beside it from the screen's top right; make room to the left. | `sideStart` is `below` by default, or `top`. Beside-map layout shifts normal map and its following trackers left. Below-map layout reserves the strip width beside Blizzard/Questie trackers. | Real native tracker and Questie methods verify reservation, scales and unchanged-height snapshot invalidation. Native collapse/overflow checks pending. |
| REQ-MBL-08 | Optional full combat hiding with safe protected-state ownership. | Separate secure visibility gate, existing `Restricted.PagingWorks` probe and captured native attribute driver. All geometry/action/count changes defer until combat ends. Flyout arrows/popups follow each slot, close securely and release Escape on owner hiding. Unsupported secure engines disable the toggle with explanation. | Strict combat-write fixture, actual flyout snippets and regression controls pass. Engine taint/secure input acceptance NOT RUN. |
| REQ-MBL-09 | Discoverable saved controls, retained integrations/appearance and controller consideration. | HUD → Flux Window → General; character-scoped controls; existing EBS engine, buttons, click/drag/macro behavior and English fallback catalog. No new framework, bindings or polling. | Options mapping/lifecycle and existing regressions pass. Built-in menu/controller/localized layout/persistence native checks pending. |

These original rows record the earlier implementation. Current automatic layout
and grid-scale requirements above supersede their manual controls. Desktop
verification and native acceptance remain separate. The 120-slot limit and 40–100% square map range are implementation
bounds; the user did not request unlimited allocation or an independently
stretched rectangular map. Below-map mode keeps the normal minimap at the screen
edge. Beside-map mode moves it left. The main combat-consumable grid beside the
action bars retains its existing position.

## Ownership, saved data and defaults

`Minimap/FluxMinimapButtons.lua` owns one shared set of EBS widgets. Growth creates
only previously unallocated indices. Shrinking hides the slots, preserving both
their secure widget identity and saved action. It does not unregister/recreate
existing named widgets or delete higher-index saved records. Existing EBS parked
visibility handling skips work on parent-hidden widgets.

The layout root follows the embedded window's parent visibility and scale; it
returns to UIParent for the external layout. A separate protected child owns the
secure visibility driver. Each action's slot owns its flyout arrow and popup, so
both count reduction and combat hiding cover those additional hit regions.
Unrelated flyout hosts retain their existing parents and behavior. Resizing
refreshes arrow/pop-up scale without replaying saved actions.

The new character table is `_FluxUI_CharSavedVars.minimapExtraLayout`. Missing or
invalid numeric settings read safe bounded defaults. No settings reset or action
migration is required. Action storage remains
`_FluxUI_CharSavedVars.minimapExtraButtons`. The external option defaults off;
embedded defaults remain 15 slots and 3 columns, with size reduced only as needed
to prevent the old strip from overlapping the map or window bounds.

The normal map anchor owns the horizontal reservation. Tracker anchors receive
the below-map reservation in their own coordinate scale; the native tracker
snapshot includes that offset. Questie continues to own its tracker and combat
queue. Its width, header policy, timer and native-tracker suppression stay intact.
No Edit Mode methods, Blizzard global APIs or registered-system tables are replaced.

One existing strip boot/event owner replaces its redundant login helper and
delayed hydration callback. No new addon ticker, timer or OnUpdate polling is
introduced. The existing short embedded-map startup watcher remains. Disabled or
hidden strip layouts remove their visibility registration; EBS retains its normal
action/count/cooldown cadence. Allocated widgets can grow to the highest selected
count during the session; native memory/frame-time impact at high counts is pending.

## Source evidence and compatibility

[Fresh source ledger](validation/minimap-layout-sources-2026-11-13.json) verifies
46 fetched source records and 36 unique Git blobs from the user-supplied
Gethe/wow-ui-source repository. Sources were read-only; no Blizzard source/art was
copied into this implementation.

| Target | Commit | Mirror version |
|---|---|---|
| Retail `live` | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` | 12.1.5.70783 |
| Forever `forever` | `bebcb6bf309cf41b41bd74f8ca651e6a105b2676` | 1.60.1.70938 |
| Classic progression `classic` | `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` | 5.5.4.70631 |

The native `state-visibility` driver handles secure Show/Hide, registered and
unregistered out of combat. Forever's old insecure compatibility driver cannot
fully hide protected controls in combat. This feature therefore uses the existing
repaired-engine probe/captured native registration path, and exposes no false
alpha-only substitute on broken secure engines. Popup-owner OnHide uses a scoped
restricted wrapper for hiding/clearing Escape; combat callbacks avoid insecure
binding/edit-child changes. Source declarations, mock execution and actual engine
permission remain separate evidence levels. Era/Anniversary existing paths are
retained; no new current Era/Anniversary upstream-version certification is claimed.

## Validation and recovery

- [Checkpoint](validation/minimap-layout-checkpoint-2026-11-13.json): 2,608 actual
  source files plus verified full Git history outside AddOns; main revision
  `26f886e3ea5371b196ab235d2dace0c156002285`. All archived/live file hashes matched
  before runtime edits. 69 on-disk settings metadata entries inspected read-only;
  no private settings contents copied or written.
- [Layout regression controls](validation/minimap-extra-layout-controls-2026-11-13.json):
  three repeated candidate runs; exact old checkpoint and ten harmful controls
  rejected. Functional counts are not native frame-time measurements.
- `lua tests/minimap_extra_layout.lua`: shared runtime controller, retained
  actions, bounds/order/scales, no insecure combat mutations, no disabled polling.
- `lua tests/minimap_window_layout.lua`: actual map/window/native tracker/Questie
  methods, map resizing/startup settling, hidden tabs and deferred geometry.
- `lua tests/minimap_flyout_visibility.lua`: production flyout placement and secure
  snippets across four client capability models; eight harmful controls rejected.
- [Full desktop suite](validation/minimap-layout-full-2026-11-13.json) and generated
  verification manifest record the tested corpus. The full 320-script/1002-syntax
  snapshot passed; the final closed-popup correction then passed six scoped
  regressions (760 focused task checks), with stable task-owned hashes. Unrelated
  inventory source/test edits continued during verification; global current-source
  freshness remains pending rather than relabeling those newer files as tested. See
  [source guard](validation/minimap-layout-source-guard-2026-11-13.json) for the
  eight task runtime owners and preserved unrelated concurrent work.

The [final documentation check](validation/minimap-layout-docs-2026-11-13.json)
reports ten outstanding issues in concurrently changing inventory/auction/Syndicator
source inventories, generated interfaces, verification hashes and a Syndicator
evidence link. No minimap-task source freshness issue is reported. Global
documentation acceptance remains pending; those other files were preserved.

No client foreground/input/clipboard action, manual installation sync, private
settings/profiler change, commit or publication was performed. No Witchcraft or
UIForever client-control tool is available in this session. User-managed native
reproduction remains selected. Client process existence was not used as a blocker.

## Native acceptance still pending

Reload out of combat, open HUD → Flux Window → General, keep the Map tab in minimap
mode, and vary count and window dimensions to exercise automatic fitting. Check borders, readable counts, arrows,
tooltips and clicks at normal/large UI scales. Assign item/spell/macro/flyout actions
to a slot above 15; reduce the count and restore it, then reload/logout/login to
verify persistence. Switch tabs and hide/show the entire window.

Restore the normal map, enable screen-side buttons and test below/beside modes,
automatic column changes, 25–200% grid scale and a tall Flux Window. Verify rightmost-column
completion, no overlap, and Blizzard/Questie expanded/collapsed tracker/timer
behavior. Check late Questie loading and its visible-dock ownership.

For secure-capable clients, enable combat hiding before combat, open a flyout,
enter combat and verify that buttons/arrows/popups are absent and unclickable,
Escape is released, and exiting combat does not reopen a popup. Change layout
preferences during combat and verify the latest state settles afterward without
blocked actions or taint logs. Repeat normal/embedded/tab transitions. On a broken
secure engine verify the option explains its unavailability and preferences remain.

Controller plan: reuse existing EBS SecureActionButton/opener interactions and
existing options range/toggle/select widgets. Keep user bindings/CVars intact.
Directional focus acquisition, activation/back, select/range operation, tab/scroll
navigation and focus visibility require each native client/controller route.
Decorative containers are not focus stops. No controller support certification is
claimed from mouse handlers or these fixtures.

All new labels have English fallback through the existing options catalog.
Reviewed non-English translations have not been supplied; missing/unknown locales
retain English. Actual translated text expansion/font/menu/controller layout is
NOT RUN. Native input, rendering, taint, persistence and matched FPS/memory captures
remain NOT RUN across all five supported client families.
