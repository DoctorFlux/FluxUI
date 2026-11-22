# Action bars

22 November. Blizzard page 2 previously put the same native slots on
columns 1–7 and 13–19. On page 2, Flux keeps base slots 1–7 in the
first seven columns and uses slots 20–24 in columns 8–12. Fixed columns
13–19 retain slots 13–19. The shared secure handler and Lua slot model
apply the rule on all supported clients. Saved actions stay in their
original slots. [Client checks](CLIENT_VALIDATION.md#action-strip-page-two-ownership).

<!-- RESPEC-ACTION-SAFETY-20261116 -->
16 November: automatic rank upgrades require an empty player cursor, the exact fourth-field spell cursor ID and a verified resulting slot. Failed pickups/placements preserve actions/recovery cursors and block dependent saved binding/stance ID rewrites; event cadence and opt-in auto-rank policy stay. Binding-mode activation keeps the current account/character binding set and unsaved keys. [Evidence](validation/respec-action-safety-2026-11-16.json).
<!-- /RESPEC-ACTION-SAFETY-20261116 -->


<!-- GROUP-COMBAT-SPIKES-20261116 -->
16 November `GROUP-COMBAT-SPIKES-20261116`: combat transition redundant-work fixes applied; 491 scripts/1181 syntax PASS; final Lua corpus stable. Full paint/binding recovery and current native/private checks remain; native timings/taint/rendering pending. [Exact scope and evidence](validation/group-combat-spikes-2026-11-16.json).
<!-- /GROUP-COMBAT-SPIKES-20261116 -->

16 November frozen border `adaptive-fallback-r50`: dedicated1226/Cost74 PASS;
full467/1157 stable and global Lua5.1 689files/24857prototypes max57/0fail PASS.
Native cost PENDING. Adaptive fallback lookup preserves tested meshes,
small-bucket flat publication and existing action/input mappings. Common24 CPU is
mixed+1.43%,56−6.20%; dense stress is not native evidence. All coordinates remain
fresh. Quiet R50 capture only after all owned CPU/docs jobs finish; last quiet R49
207.94ms leaves208ms hitch/CB36 OPEN. Prior accepted fits/Trinket work retained.
[Border requirements and acceptance](CONNECTED_BORDERS.md).

15 November: range now follows the selected cast target, independently of idle
icons, pinned tooltips and reverse badge token swaps. Plain actions apply the
native friendly/hostile eligibility rule. The reported Frostbolt/friendly-hover
case is confirmed in game. [Rules and scoped validation](CAST_RANGE_TARGETING.md).

15 November: hotkey text and mouse/scroll/space glyphs turn red only for the
existing out-of-range result. Original gray text/white art returns in range;
binding/modifier/size refreshes retain the correct color. No new range probes or
polling. [Four-surface requirements and validation](HOTKEY_RANGE_GLYPHS.md).

15 November action routing (`ACTION-ROUTING-RELIABILITY-20261115`): native
PreClick proved Shift globals are consumed while the large main already shows66;
old inheritance selected action6. Secure main now publishes its LIVE keyboard
bundle, with independent mouse modifier sets. Native Ctrl-Shift-½ capture selects
macro66 and macro parser reports both despite rawkeysfalse. User confirms:
"Fire Ward casts; icons return correctly." This verifies that reported cast and
release, not all19/pages/clients/taint/controller/FPS. No macro-condition rewrite.

Also corrected mini inverse page updates, temporary fallback overlays, shared-slot
badge prewarm, OOC and late-callback display indexing, held-modifier page bursts,
and hover native/free ownership/reconfigure/retry. New native restricted-builder
regression rejects the intermediate quoted-function error and accepts correction.
Focused:363885modifier;864nativehandler;21532visual;547hover;510badge;25920control
checks PASS. Full408/410 before final control-fixture repair; repaired25920PASS;
one unrelated portrait fixture misses GetUnitClassColor. No settings/action reset,
agent input/focus/profiler operation or manual installation copy. Nine Forever
runtime files match. Native broad acceptance and FPS measurement remain pending.
[Requirements, sources and measured limits](ACTION_ROUTING_RELIABILITY.md).

15 November shared binding modifiers (`SHARED-BINDING-MODIFIERS-20261115`): fixed the
keyboard proxy selector leak across main/mini rows and obsolete live LeftButton
selectors. The saved hidden main11/Shift71/native35 pattern reproduces Shift-F
casting main11 in the linked GitHub version; candidate selects71 and releases
back to11 before display updates. 2,271 focused checks; exact246; three harmful
controls and12 focused scripts PASS. Regular key press OFF still disables that
binding including ALT; profiles/badges/compiler/settings remain unchanged.
The first full sweep400PASS/2FAIL preceded final test refinement and concurrent
changes. Final modifier checks and the bar smoke now PASS; fresh1,092-file
syntax passes. Other full-sweep results remain historical for newer unrelated
sources. Native casting/taint/controller/render/FPS acceptance remains pending;
no client input or manual installation copy. [Requirements and evidence](SHARED_BINDING_MODIFIERS.md).

15 November current main-row work: explicit `/fluxbars restore` rebuilds all19
owned routes, including fixed13-19, and removes shadowing mouse/proxy action
selectors while preserving placed actions and profiles. `/fluxbars audit` reports
native calculated slots and key routes. The candidate is installed for later
Forever testing;the user cannot test in game yet. Offline3,228recovery/700audit
checks and six harmful controls PASS;native recovery remains unverified.
[Requirements and acceptance](MAIN_ROW_RECOVERY.md).

15 November action-bar follow-up and rollback: native diagnostics showed main
page2 (`native=2`, `actionpage=2`, `swap=0`), with correct ID0 hosts and column1
using13. Dynamic column6 and static column18 therefore both used18. The user
confirmed page1 restored the expected normal-page actions, then reported fixed
columns13-19 still wrong. Further dumps show18/19 routing to18/19, keysX/C and
ID0; expected/actual action contents have not been supplied. Treat remaining
button recovery as unresolved.

At the user's request, all runtime source is restored to the verified checkpoint
from before connected borders. Eight action-routing owners and the repo HEAD
match GitHub main6b444eba4573092b57919ee3e497d86d2ebb3ece. No slot reassignment,
placed-action reset or automatic page reset was introduced. This source restore
cannot establish recovered game-stored action contents. Fresh native checking
after reload remains pending. The temporary connected-startup integration test
is removed with that feature; the prior714-check startup regression is restored.
[Reports, source comparison and exact rollback](validation/border-types-2026-11-15.json).

13 November action counts: the existing synchronous Bars inventory listener now admits light bag publications at the instant count tier. Validated SPELL_UPDATE_USES refreshes count/usability through existing scheduler lanes, without macro/layout work. [Requirements, comparison and666 focused checks](ACTION_COUNT_REFRESH.md).

<!-- STRESS-FIXES-20261107 -->
7 November applied stress fixes: Quiet-grid, cast/badge and bling alpha readers avoid secret comparisons and handle denied getters with feature-specific public-write or retained-state policies. Native secure driver/watch globals retain their identities; Forever adapters are selected locally by Flux callers. [Evidence](../Stress%20test%20doc/applied-fixes/README.md). Native taint/pixels/performance acceptance remains pending.
<!-- /STRESS-FIXES-20261107 -->

`Flux.Bars` owns the bottom strip, secure click surfaces, pet/stance bars and hover-to-bind mode. Blizzard action slots store content; Flux-owned widgets provide presentation and clicks. [Init.lua](../Bars/Init.lua) is the entrypoint. Current TOC loading, rather than older engine terminology in comments, establishes the implementation.

## Structure and startup

There are **19 columns**: 12 page-dependent native columns and 7 static columns. Every column has main, `sec` and `tert` hosts: 57 surfaces. `Bars.hosts[column]`, `GetHost`, `GetMain`, `ForEach` and `ForEachHost` are the registry/traversal API. Minis are half-size.

`Start()` runs once outside combat: prepare stock bars; start vehicle handling; create strip/state headers; build main/mini hosts; install clicks/drivers/watches; start program-face translation, cast effects and layout; apply slots/options. [Hosts.lua](../Bars/Hosts.lua) chooses modern `ActionBarButtonTemplate` or art-only `ActionButtonTemplate` plus the secure action template. Forever deliberately uses the latter even with modern native UI, preserving its native collector methods. Stock `ActionButton1–12` stay suppressed. Columns 13–19 borrow Blizzard commands exposed by `Hosts.BindingCommand()` while displayed labels remain Action Buttons 13–19.

Initial visual constants are 44px buttons, 0 padding, 4px margin, 1.24 scale and 4px vertical offset. [Strip.lua](../Bars/Strip.lua) adds shared squeeze/scaling and gamepad adjustments. Effective geometry also depends on current layout/options.

## Pages, modifiers and promotion

[SlotMath.lua](../Bars/SlotMath.lua) is the pure model; [State.lua](../Bars/State.lua) reproduces it in restricted handlers. They must agree.

| At-rest surface | Columns 1–12 | Columns 13–19 |
|---|---|---|
| Main, page 1 | Slots 1–12 | Slots 13–19 |
| Main, page 2 | Slots 1–7, then 20–24 | Slots 13–19 |
| Main, other pages | `(page - 1) * 12 + column` | Slots 13–19 |
| SHIFT mini | Slots 61–72 | Slots 49–55 |
| CTRL mini | Slots 25–36 | Slots 37–43 |

**Native page** covers ordinary pages, forms/stances, stealth variants, vehicle/possess/override and supported skyriding states. Six headers cover main/sec/tert across dynamic/static columns. **Modifier selection** uses the secure hub to publish the current large main action and compiled program to its keyboard proxy. Native bound-click dispatch can consume Shift/Ctrl globals; keyboard execution therefore uses that live bundle rather than reconstructing the row from a fresh key-state query. Mouse input retains eight prepared modifier attribute sets. Read-only display indexing keeps identities current, preserves held modifiers across page events and rejects late callback rollback. Each header retains its own page during staggered updates.

[Layout.lua](../Bars/Layout.lua) reserves all twelve native columns, including empty positions, and packs eligible static columns. Promotion can put mini content into an empty ordinary main. One available mini can serve both modifier paths; two minis can use promoted-main/remaining-mini behavior. Hover, drag and binding mode expand the compact view. `ApplyMappings()` changes slot relationships; `ApplyVisual()` changes anchors/visibility. Structural Show/Hide/SetPoint work defers through combat; already-created surfaces have safe reveal/alpha paths.

## Input and compiled overlays

[Clicks.lua](../Bars/Clicks.lua) preserves the existing click policy: wrapped clients use `KeyBind`; Forever uses hidden `FluxActionStripKey<column>` key-down proxies with `LeftButton`, while visible mouse hosts remain mouse-up. Otherwise-unassigned Shift/Ctrl key variants route explicitly, preserving native exact assignments and Binding-owned ALT/combined free chords. The secure main alone publishes the proxy's live type/action/macro/delegate bundle through its header frame reference. Mini hosts cannot overwrite it, and no-mod wildcard attributes on the mouse host cannot shadow it. Bindings and initial/reused proxies reconcile through the existing key owner; shared `Flux.ButtonFX.Click` retains mouse/hold/empower behavior.

[BindingMode.lua](../Bars/BindingMode.lua) adapts LibKeyBound: hover a main/mini/pet/stance/combat/noncombat/utility/trinket surface and press a key. It registers appropriate commands, forces relevant empty slots visible and dims unrelated columns. Activation is combat-locked. This simple assignment mode is separate from [conditional binding authoring](13-binding-system.md).

[SlotProgram.lua](../Bars/SlotProgram.lua) stores compiled programs by **action slot ID**. Simple peer/badge conditionals can use temporary visible-host macro attributes; sequence/petattack/multi-cast programs delegate through hidden `FluxSlotClick_<slot>` secure buttons. `ApplyMap`, `ApplyHoverMap`, reassert and queue-flush methods skip unchanged programs. Native slot content remains distinct from these overlays.

[ProgramFace.lua](../Bars/ProgramFace.lua) translates displayed macro identity so icon/count/cooldown/usability/range and badges follow the apparent action. It indexes body requirements and receives shared context updates. [MacrotextDisplay.lua](../Bars/MacrotextDisplay.lua) is an adapter to `Flux.Context`, not an independent mouseover scanner.

## Paint, effects and native flyouts

[Paint.lua](../Bars/Paint.lua) owns labels, icons, counts, cooldowns, tint, checked/flash/equipped state, hotkeys and assisted-combat highlights. Dirty hosts batch through `Flush(tokens)`. Shared action/secret wrappers keep restricted values out of Lua comparisons and pass them to supported display widgets.

[BadgeHost.lua](../Bars/BadgeHost.lua) maps up to three alternate-action corner previews per slot onto every surface that can display it. Form, occupancy, cooldown, macro identity and per-binding policies control visibility. Combat visibility uses alpha; structural writes defer. Badge ordering differs from macro clause ordering.

[Effects.lua](../Bars/Effects.lua) transfers proc overlays by action identity across main/mini widgets so paging does not restart the birth animation. Shared cast effects follow the column. [Flyout.lua](../Bars/Flyout.lua) attaches native Blizzard SpellFlyout; custom item/utility flyouts use EBS instead.

The native flyout glyph uses the [shared arrow layer](12-extra-button-system.md#flyouts-and-trinkets) above the strip crest and follows its button when the layout moves.

[SpellRank.lua](../Bars/SpellRank.lua) desaturates lower learned ranks, offers explicit/automatic rank-up, maintains a blacklist and reconciles affected binding/spellbook displays. Rank support is gated for applicable Classic/Forever clients; Live Midnight does not use this rank workflow.

## Pet and hybrid stance bars

The [pet bar](../Bars/Pet/Init.lua) is 5×2 EBS widgets using `BONUSACTIONBUTTON1–10`. It follows player/stance or alternate HUD placement, pet/vehicle visibility and binding-mode overrides. Watches separate full refresh from cooldown/usability updates.

Forever's pet visibility driver uses `[pet,nobonusbar:5]show;hide` for legacy control encounters; other clients use `[pet,novehicleui]show;hide`. The pet driver's compatibility policy remains independent of the main bar's secure-paging probe.

The [stance shell](../Bars/Stance/Init.lua) combines true forms, class extras and custom slots. Hidden Blizzard donors retain native secure behavior; EBS faces provide Flux presentation. `Order.lua` persists per-character order, hidden keys and additions. `Extras.lua` discovers class helpers, deduplicates form abilities and tracks active auras/pets. Visual aura changes repaint instead of rebuilding discovery/layout. Options support reorder/hide and cursor-added slots.

## Configuration and verification

`FluxOptions:GetActionbarsDB()` selects account/character settings; stance order/custom slots remain per character. `ApplyPerformanceSettings()` configures distinct queues: action range 0.25, extra range 0.18, macro mouseover 0.07, macro-usability minimum 0.05 and optional action-usability minimum 0 by default. [Options](26-options-map.md) records exact controls.

`/fluxbars` reports state; `<column>` prints surfaces; `page`/`paging` prints the secure chain; `mo`/`mouseover` prints targeting; `smoke` runs slot-math assertions. The [local smoke harness](../Bars/_tmp_barsmoke.lua) checks mapping/selected lockdown contracts, not live protected execution.

Vehicle abilities page onto the first 12 Flux columns. Blizzard vehicle/override chrome differs from suppressed unused bars; modern Settings hooks avoid replacing taint-sensitive globals. Verify vehicles, forms, held modifiers at combat entry, mouse/wheel hovercast, native flyouts, promotion and identity-stable effects in game on each family.

All twelve native main positions remain shown even when empty, so control actions never require a protected Show/Hide or repacking during combat. Temporary pages own these mains regardless of held SHIFT/CTRL or mini promotion; the ordinary mapping returns on exit. Temporary page contents do not alter ordinary promotion flags.

The implementation treats every page numbered 11 or higher as temporary. The first twelve mains bypass saved macro/click programs on those pages, while secondary/tertiary hosts and static columns retain their own mappings. Promotion discovery checks ordinary pages 7–10 rather than temporary control content. Modern clients also include supported override/vehicle/possess/shapeshift driver clauses; Forever uses bonus page 5 to reach action page 11 (slots 121–132).

Forever retains v8's native `SecureActionButton_OnClick`, mouse-up registration and hidden key-down proxies. Ordinary native actions are not wrapped in routing macros. `Restricted.PagingWorks()` separately executes a small setup-time snippet to check whether the client's repaired secure environment works; it does not infer support from the deliberately removed public `loadstring_untainted` global. After success, the bar headers register through captured native attribute-driver functions and handle both entry and exit in combat. Other modules keep their existing compatibility policy. Forever's driver uses `[bonusbar:5]` for Mind Control / Chess and excludes the unsupported vehicle/override/possess/shapeshift macro options. A failed probe retains the legacy OOC fallback; that engine cannot perform secure combat paging. `/fluxbars page` reports `securePaging`.

Forever strip widgets use the art-only `ActionButtonTemplate` with the same secure click handler, avoiding temporary replacement of native collector methods. Native collector event delivery stays active. When secure paging is available, native stance suppression also uses restricted frame handles instead of reparenting the Edit Mode bar.

[The Forever control regression](../Bars/_tmp_forevercontrolsmoke.lua) executes the supplied native `SecureStateDriver` and `SecureTemplates` with Flux's actual state, click, key-proxy and layout modules. It compares ordinary mapping with the supplied v8 backup and checks empty positions, combat control entry/exit, normal pages 1/2/6, held modifiers, promotion, macro restoration, native collector ownership and a failed engine probe. It models protected writes and input edges; it does not model the game's taint engine or replace an in-game encounter test.

## Stock grid events and combat bag pickup

The supplied Forever source matches the reported bag-pickup stack: `PickupContainerItem → ACTIONBAR_SHOWGRID → SetShowGrid → UpdateVisibility → UpdateActionBarLayout → ManageFramePositions → RightManagedFrameContainer:SetSize`. Alpha-hidden Blizzard bars still received grid events and entered Edit Mode layout during combat; deferring Flux's own grid cleanup did not prevent that native dispatch. The stack establishes this trigger but does not identify the first taint write.

[Blizzard.lua](../Bars/Blizzard.lua) unregisters only recognized action/pet grid events named by each replaced bar's `showGridEventName` and `hideGridEventName`, including the main bar. Suppression runs before neutralization, handles aliases and late `Blizzard_ActionBar` loads across clients, and coalesces combat requests until regeneration. It checks current registrations independently of the unused-bar visibility flag. Flux grid listeners remain active; native controller/paging events, vehicle bars, layout methods and managed-frame tables retain their existing ownership.

Run `lua Bars/_tmp_stockgridsmoke.lua` from the addon root. The fixture executes the supplied native action-grid and layout methods plus Flux's actual suppression and combat queue. It reproduces the original dispatch with a modeled protected resize, then checks action/pet show/hide events, aliases, missing capabilities, repeated setup, event re-registration, late loading, combat deferral and Forever gamepad mode. Four client snapshots are exercised; MoP coverage uses an explicit compatibility fixture backed by Era methods, since no MoP snapshot was supplied. Native taint, hardware input and saved Edit Mode anchor geometry remain outside the fixture.

In-game acceptance remains pending: start a fresh Forever session with `/console taintLog 2` and `/reload`, reproduce combat bag pickup/cancel and bag transfers, and inspect `Logs/taint.log` for the first taint attribution and any blocked resize. Disable logging afterward with `/console taintLog 0`. Repeat in a clean session with Flux disabled when attributing the original taint. Verify normal action assignment outside combat, pet grids, forms, possession, vehicles and Edit Mode on each supported client, including keyboard/gamepad modes where available. A fresh reload is required to discard taint retained from older loaded code.

## Possession and override layout — 23 October 2026

The user reported `ActionBarController_UpdateAll → StanceBar:Update → HideOverride → UpdateActionBarLayout → RightManagedFrameContainer:SetSize` during possession/override transitions on Forever and Retail. The stack identifies the blocked operation, not the first taint writer. A shared source-level cause exists in Flux's boss/arena positioning: it wrote `ignoreInLayout = true` while the stock container could still be parented to the native right-side layout. `BaseLayoutMixin:AddLayoutChildren` reads that field before testing whether a child is shown; even a hidden container therefore exposes an addon-owned layout value to the protected resize.

[Boss positioning](../Other/FluxBossFramePosition.lua) and [arena positioning](../Other/FluxArenaFramePosition.lua) now reparent the Flux-positioned container to `UIParent` outside combat instead of writing `ignoreInLayout`. Native layout methods, system settings, scripts and managed-frame tables retain their ownership. The existing position-manager opt-out remains. Edit Mode exit and top-level UI restoration queue reapplication after the native pass; encounter events during combat defer positioning until regeneration.

[Vehicle refresh](../Bars/Vehicle.lua) now captures namespaced `C_ActionBar` APIs with legacy-global fallbacks and includes possession, bonus and temporary-shapeshift states in its change signature. Possession entry/exit no longer disappears behind an unchanged vehicle/override signature. Out-of-combat repair detects a stale possession page; combat action attributes remain owned by the existing secure drivers. The Lua temporary-token resolver now uses page 11 when no usable index exists, matching its restricted counterpart. Existing temporary-page modifier/promotion rules and native cancel-possession controls remain in effect.

[The possession-layout regression](../tests/possession_layout.lua) executes both supplied branches' native controller, stance visibility, Edit Mode positioning and LayoutFrame methods. A field-ownership/lockdown model rejects the former hidden-child policy and checks 40 combat control transitions per branch, native page completion, combat deferral, Edit Mode and UI restoration. [Bar refresh tests](../tests/bars_refresh_regression.lua) also cover possession-only changes, bonus possession, temporary shapeshifts, override, vehicle, exit, coalescing, stale-page repair and both API surfaces. [The validation run](validation/possession-control-2026-10-23.json) passed 711 Lua syntax checks and all 73 standalone tests. These are desktop/source fixtures, not WoW's taint VM. Fresh `/reload` checks of Mind Control/possession, override/vehicle entry and exit, held modifiers, cancel controls and Edit Mode remain required in Retail and Forever; this change does not establish that every possible native layout taint is resolved.

## Highlight batch work

PERF-010 `677d85c` shares activation within the existing highlight and Flush batches;
standalone updates remain fresh. No cross-frame cache, cadence change or new
resource. 1,420 checks cover enabled/disabled/parked/opaque identities, direct calls,
template geometry/reuse and 100 toggle cycles per branch. Five native pairs on each
of Retail and Era reduce activation calls 5,800 ->100 per100 passes with identical
57-button geometry and zero recorded errors. Native enabled/combat/secure input
and full FPS remain pending. [Audit and exact evidence](ACTION_AURA_WORK.md).

Attached stance placement follows the Flux player-frame whole scale; detached
placement restores its normal scale. Existing combat deferral is retained.
[Scope and regression checks](UNIT_FRAME_SCALE.md#attached-stance-bar-scale--30-october-2026).

## Native mouseover toggle — 7 November 2026

The spellbook keeps a directly clickable mouseover toggle. On clients where
Blizzard's `IsMouseoverCastSupported()` returns true and `enableMouseoverCast`
exists, it is the actual `ClickBindingFrame.EnableMouseoverCastCheckbox`.
Flux leaves its native scripts, label, tooltip and CVar ownership intact.
The shared spellbook layout borrows it while the book is visible, then restores
the original parent, anchors, scale, strata and level for Click Casting or a
closed book. The same existing observer handles both panels without native
OnShow/OnHide/method hooks. Parent changes defer in combat. Click Casting is
loaded lazily on first spellbook use, not at login.

The native CVar is the source of truth even when a scoped Flux preference
disagrees. The saved custom preference remains available on unsupported clients;
there is no migration or forced reset. Flux's option shows native state and opens
Click Casting. Default/reset/binding-save paths preserve both the native CVar
and `MOUSEOVERCAST` modifier. Native change events leave Blizzard's synchronous
callback stack before coalesced Flux refresh. Native action-slot checks stay
prepared even while off, allowing Blizzard to apply its own combat changes.
Explicit user macro targets remain explicit. The 8 November correction adds
automatic factory mouseover clauses on native clients using the same native
modifier, including bindings with prefix commands. Default/Target casts try a
compatible mouseover first; explicit Focus/Self/cursor rules retain priority.
See [universal mouseover targeting](UNIVERSAL_MOUSEOVER.md) for exact scope,
combat deferral, limitations and current validation.

Blizzard's native helper classifies an action slot, so standalone spell/item
buttons retain their existing click-time adapter on clients supporting wraps,
now gated by the same native preference/modifier. Those attribute changes keep
existing combat deferral. Standalone Forever buttons can use the existing
repaired-handler probe; plain native actions keep Blizzard's resolver. Actual
operation, native taint/gamepad/input and pixel parity are not certified by mocks.

Regression: `lua tests/mouseover_native.lua` executes the addon and the pinned
Blizzard checkbox/target resolver, including support-false/missing-CVar clients,
native off/on, modifiers, both panels, close/reopen, ownership restoration,
combat deferral, source defaults, scoped-data preservation and standalone inputs.
388 checks pass; five fresh alternating baseline/candidate pairs reject the old
source and pass the candidate. These are functional replays, not CPU/FPS trials.

Native acceptance pending: reload; open the spellbook and verify the checkbox
remains visible; toggle it there and confirm the same state in native Combat /
Click Casting; change the native control and verify the spellbook on reopening;
open/close Click Casting beside the book; select a mouseover modifier and test
native bar keys, standalone spell/item buttons, unit-frame hover, gamepad and
combat transitions. Check Lua/taint logs separately and restore diagnostic
preferences after any user-selected capture.

[Source identities and evidence](validation/mouseover-native-2026-11-07.json).

<!-- ACTION-STRIP-BORDER-R55-20261116 -->
R55 `strip-updates-r55`: matching occupied-swap layouts skip redundant decorative
writes/player-layout fanout using fresh native geometry; nearby strip/envelope
crests align in both types. 144 focused scripts pass. Real packing/expansion and
all mapping/binding recovery remain. Actual drag prefixes had0cache hits, so no
extra cut cache was admitted. Native checks are deferred by the user.
[Requirements](ACTION_STRIP_BORDER_UPDATES.md); [scoped evidence](validation/action-strip-borders-2026-11-16.json).
<!-- /ACTION-STRIP-BORDER-R55-20261116 -->

<!-- ROSTER-MACRO-BATCH-20261119 -->
On roster events, the action strip and Extra share one ProgramFace callback. The current solo, party or raid branch is resolved in the existing conditional eval pass. This path refreshes visual macro identities without changing the assigned action.
[Macro roster batch evidence](validation/roster-macro-batch-2026-11-19.json).
<!-- /ROSTER-MACRO-BATCH-20261119 -->

<!-- STRIP-CHROME-MINIMAP-ROSTER-20261119 -->
Held-action strip crossings reuse matching button-ring and backdrop artwork. New visibility, a changed face size and a native restyle return to the regular skin path.
[Strip and minimap evidence](validation/strip-chrome-minimap-roster-2026-11-19.json).
<!-- /STRIP-CHROME-MINIMAP-ROSTER-20261119 -->

<!-- FINAL-STRIP-UNIT-ANCHORS-R90-20261119 -->
Held-action crossings position the player and target once after the side-panel envelope settles, immediately before the border junction pass.
[Strip unit anchoring evidence](validation/final-strip-unit-anchors-2026-11-19.json).
<!-- /FINAL-STRIP-UNIT-ANCHORS-R90-20261119 -->

<!-- STRIP-PANEL-SETTLE-R92-20261119 -->
A held-action crossing moves Info only when it occupies the strip. The unified envelope still reconciles the Info and Trinket Menu gap fills against the final strip layout.
[Strip panel settlement evidence](validation/strip-panel-settle-2026-11-19.json).
<!-- /STRIP-PANEL-SETTLE-R92-20261119 -->

<!-- STRIP-VISIBILITY-R117-20261119 -->
A held action can expand or collapse the strip by crossing its sensing area. Rapid reversals that return to the current pose in the same update skip layout. Settled crossings, action-slot signals and grid signals use the existing layout dispatcher.
[Matched validation](validation/strip-visibility-2026-11-19.json).
<!-- /STRIP-VISIBILITY-R117-20261119 -->

<!-- STRIP-CHAT-DOCK-R120-20261119 -->
A pure drag crossing now passes the settled strip floor to chat before the border commit. Matching native layout avoids chat writes. The raid stack still follows a changing strip floor in the side-column layout.
[Matched validation](validation/strip-chat-dock-2026-11-19.json).
<!-- /STRIP-CHAT-DOCK-R120-20261119 -->

<!-- STRIP-HOVER-OCCUPANCY-R151-20261119 -->
Held-action crossings now resample mini occupancy in the same secure pass that resolves mouse and key routes. Real action edits still force fresh routes. No action-slot storage, packing or modifier convention changed.
[Matched validation](validation/strip-hover-occupancy-2026-11-19.json).
<!-- /STRIP-HOVER-OCCUPANCY-R151-20261119 -->

<!-- STRIP-SHELL-ANCHORS-R165-20261120 -->
Held-action crossings and slot changes keep existing screen anchors while resizing the strip. The button area moves only when its required anchor actually changes.
[Matched validation](validation/strip-shell-anchors-2026-11-20.json).
<!-- /STRIP-SHELL-ANCHORS-R165-20261120 -->

<!-- STRIP-EVENT-OWNERSHIP-R183-20261120 -->
Sixty matched slot changes, each with two native notifications, cut early envelope reads from 120 to zero. The same 60 final layout passes and border commits still run. Six warmed held-cursor replays across both styles and three UI scales use 8 to 16 fewer parent level reads per six crossings. Settled action routes, button geometry, raised layers and sampled border artwork match the archived sources.
[Matched validation](validation/strip-event-ownership-2026-11-20.json).
<!-- /STRIP-EVENT-OWNERSHIP-R183-20261120 -->

<!-- STRIP-PARKED-CHROME-20261120 -->
The strip retains verified button chrome when a face returns from off-screen parking. The first crossing refits 19 versus 5 faces in each desktop client model. Sixty warmed crossings refit 571 faces before and zero after. Button positions, action slots and visible art match. The held-cursor watcher also leaves the sensing frame alone once its live visibility matches. Keep the current verification of texture identities, native normal paint, backdrop visibility and applied button dimensions. New widths, art replacement and unreadable region state take the regular repair. Capture an unlocked native art update for the next verification. The locked native callback retains its original art writer and leaves validation for the next unlocked layout.
[Matched validation](validation/strip-parked-chrome-2026-11-20.json).
<!-- /STRIP-PARKED-CHROME-20261120 -->
