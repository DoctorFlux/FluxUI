# Minimap, embedded buttons, objectives and buffs

Target/focus tracking is now built in where the native engine exposes hidden
filters. The normal tracking menu saves character choices; show-all and an enabled
ForeverMinimapTarget stay native. Classic clients without the filter lookup remain
inactive. [Behavior, compatibility and acceptance](MINIMAP_TARGET_FOCUS.md).

Flux reshapes Blizzard's minimap and relocates surrounding widgets. It can embed that same map into the Flux Window instead of maintaining a second minimap. [FluxMinimap.lua](../Minimap/FluxMinimap.lua) owns the global controller and its runtime `embeddedState` (original parent/size/points plus current host).

## Map appearance, controls and lifecycle

Initial configuration is a 190px square with a white square mask near the upper-right corner. Style/cleanup repositions supported indicators, queue-status eye, mail, tracking and difficulty controls, removes unwanted stock chrome and supplies a bordered info bar. Mouse wheel zooms; mouse-up hooks preserve Blizzard's native ping handler before adding Flux behavior. Zone text has fit/scroll/tooltip handling; clock and info-bar click targets are separate.

Mail positioning searches legacy global/Minimap keys, then the native
`MinimapCluster.IndicatorFrame.MailFrame`, and finally the owned fallback. This
intentionally restores Forever's native 32x24 `ui-hud-minimap-mail-icon` artwork.
Clients without a native frame keep the 20x15 fallback; a late native frame retires
that fallback and its listeners. Tracking-relative anchors, unread-mail policy,
tooltip cadence and native hide cleanup remain.
[Native indicators](MINIMAP_NATIVE_INDICATORS.md) supersede the artwork choice in
[the earlier lifetime fix](MINIMAP_MAIL_LIFECYCLE.md).

Calendar opens from left-click on the existing clock/time hit region when
`ToggleCalendar` is available at runtime. Its tooltip advertises that action.
The separate native calendar icon stays hidden; right-click on the clock retains
TimeManager/stopwatch. Native mail styling remains. This supersedes the earlier
top-left calendar-button placement. Native input/visual checks remain pending.

Map right-click opens the tracking menu on the Retail path or available calendar on the older path. Info-bar/zone left-click toggles World Map and right-click opens calendar when supported. Clock-area left-click opens calendar; right-click invokes available TimeManager/stopwatch helpers. The comment suggesting Shift-left stopwatch is not an implemented Shift branch.

`Initialize`, `UpdateStyle`, `CleanupBlizzardFrames`, `PositionIndicators`, `PositionQueueStatusEye` and `EnforcePosition` reconcile this presentation. `RequestEnforcerBurst` temporarily tightens checking after layout changes; idle fallback runs less often. The code uses event-driven updates plus these bounded/idle enforcers, not just a one-time login anchor. Addon/world/difficulty/group/mail/tracking/display/UI-scale events cover changing widgets and late Blizzard UI.

`EmbedInFrame(parent)` remembers normal geometry and lays out the map within the Flux Window. `RestoreToNormal`, `HideEmbedded`, `ShowEmbedded`, `IsEmbedded` and `GetNormalWidth` support tab changes and restoration. Hiding a non-Map tab must not accidentally leave MinimapCluster visible. Embed changes also update tracker geometry, Info Frame and the micromenu's minimap placement. The saved layout preference and runtime parent state are different things.

Protected reposition/reparent work queues through combat exit. Edit Mode compatibility avoids adding methods to EditModeManagerFrame or mutating its registered system-frame table; those paths can taint action-bar/vehicle layout. See [runtime restrictions](03-midnight-constraints.md).

## Shared embedded and optional screen-side action buttons

The screen-side grid has a shared FluxBorder inside its secure visibility owner,
so border/backdrop follow mouseover and combat hiding, empty filtering and scale.
Side widgets/chrome draw in HIGH above the minimap clock/cluster; embedded mode
restores MEDIUM and hides the side border. Native clock/minimap handlers and
geometry are preserved. [Layering and native acceptance](MINIMAP_EXTRA_LAYOUT.md#screen-side-border-and-minimap-clock-layering).

Optional empty-slot hiding compacts only screen-side assignments and reveals one
drop target while carrying an action. Dynamic button count uses the configured
count as a minimum, preserves all assigned slots and offers one temporary slot
while carrying an action over a full grid, up to 120. Unused previews disappear;
deletion shrinks the grid back toward the minimum. Mouseover leaves minimap,
Questie, objectives and auras at their normal dock; Always shown automatically
makes room. There is no independent movement setting. Visibility combines with the
separate secure combat-hide option; hover state freezes during combat. Embedded
buttons ignore side-only visibility/empty filtering. These preferences preserve
the defaults and existing saved slot indices. [Behavior and acceptance](MINIMAP_EXTRA_LAYOUT.md#dynamic-minimum-and-automatic-frame-movement).

[FluxMinimapButtons.lua](../Minimap/FluxMinimapButtons.lua) defaults to 15 EBS widgets in three columns beside the embedded map. Flux Window → General configures the shared 1–120 count. Both layouts automatically choose columns and button size; embedded map sizing is automatic, with no size control. An optional external layout uses the identical slots, fills downward from the rightmost column, and can start below or beside the normal minimap. At 100%, standard buttons are retained when space permits and dense columns fit within two standard columns. A separate 10–200% screen-side grid scale (100% equals the previous85%) resizes the entire grid; grids refit at every scale to stay above Flux Window. Layout padding is zero; completed side columns meet the window boundary, and embedded buttons meet the minimap edge. The always-visible combat-hide setting applies only to screen-side buttons, including their arrows and flyouts on capable clients. Embedded buttons ignore that preference during combat. [Requirements, defaults and native acceptance](MINIMAP_EXTRA_LAYOUT.md). `_FluxUI_CharSavedVars.minimapExtraButtons[index]` stores assignments, including macro index/name/body recovery data. Creation, refresh, slot layout, accent refresh and `OnEmbedStateChanged` are separate methods. The strip uses [EBS](12-extra-button-system.md) action/count/cooldown handling in either minimap arrangement; it is separate from the four noncombat utility slots. Reducing the count preserves higher saved slots and allocated widget identities.

## Objective tracker scroll dock

The inner tracker is released from screen clamping while the outer viewport
keeps the screen bounds. Otherwise a long native tracker is pushed above the
clip and its first quests cannot be reached even at offset zero. Native profile
recovery also settles cached content height and queues one existing scroll sync,
with Edit Mode/combat ownership guards. [Reproduction and validation](OBJECTIVE_TRACKER_TOP.md).

[FluxObjectiveTrackerScroll.lua](../Minimap/FluxObjectiveTrackerScroll.lua) wraps the supported objective tracker in a viewport, computes content height and anchors it relative to minimap/layout bounds. It handles scrollbar/content size, top-module gaps, header and quest-timer placement, full-layout requests, dirty-state recovery and combat-delayed setup. The implementation works with the actual client tracker/manager rather than inventing a new quest log.

`EnsureViewport`, `ApplyViewportSize`, `LayoutScrollArea`, `SyncAfterUpdate` and `RefreshLayout` are the central operations. Height/anchor hooks keep Blizzard's update pipeline inside the dock. Overflow scrolls instead of extending indefinitely into the bottom HUD. Hidden/zero-height bodies and late async manager initialization have explicit recovery paths.

Retail and Forever both reserve 38px above the first module for the native header.
Flux moves that header outside the scrolling body, so the first visible module must
be anchored at the body's top after native layout. Both clients' container update
now receives the after-hook: Blizzard's saved dirty callback calls that mixin
directly and bypasses the later frame-instance hook. The deferred sync also repairs
anchors before its unchanged-height shortcut, covering Campaign/Quests replacements
with equal stack heights. Native padding values remain untouched. Child resizing
restores a requested zero scroll offset as well as positive offsets.
[The regression](../tests/objective_tracker_scroll.lua) replays the supplied native
Retail/Forever container and frame code with a callback saved before Flux hooks.
Its 40 geometry/dispatch checks pass; live rendering and taint checks remain pending.

Forever has additional compatibility: `InstallForeverCompat`, `StartForeverLoginPulse` and `KickScrollLayoutOnce` wait for the client's initialization sequence, correct stuck dirty state and stabilize the first dock. Ordinary world transitions do not continually force a full tracker layout. Current source deliberately avoids specialization/level listeners because Forever emits misleading spec events on level-up.

Forever's mouse/keyboard tracker also guards the container update entry during combat. `DirtiableMixin:SetDirtyMethod` captures `Frame.Update` at startup, so callbacks already queued before Flux's dirty-callback wrapper can bypass an instance hook and still reach `ManageFramePositions`. Captured callbacks and direct container updates coalesce until the tick after combat ends; native dirty processing then resumes. The gamepad container entry stays native because its caller performs protected navigation after the container returns. [The combat regression](../Minimap/_tmp_trackercombatsmoke.lua) replays the supplied native dirty/frame/container code, reproduces the original resize with the guard disabled, and checks deferred layout, regen timing and callback replacement. It does not emulate engine taint.

These combat guards install even with Questie's tracker enabled: Blizzard's hidden tracker can still receive a saved dirty callback. Questie continues to own the visible dock; skipping Blizzard scroll setup must not skip the combat guard.

## Questie and buff frames

[FluxQuestie.lua](../Minimap/FluxQuestie.lua) is optional. It imports tracker/line/base/combat-queue modules through QuestieLoader, hooks real tracker updates and expand/collapse interaction, then sizes/anchors/styles lines and base frames. It does not continuously poll the expand flag; post-update hooks cover transitions. This tracker integration is separate from [Battlezone HBD pin routing](10-flux-window.md).

Classic Era, Anniversary and Forever/Camelot share that same 175px Questie dock, wrapped objective rows, zone/quest controls and embedded-minimap placement. Selection follows Questie's `trackerEnabled` setting, including when Questie temporarily hides its tracker. With Questie's tracker enabled, Flux skips Blizzard viewport creation/recovery/watch sorting and hides any existing viewport, including its detached “All Objectives” header. Forever uses Questie's compatibility visibility helpers to suppress late native frames and release suppression when the tracker is disabled. With Questie disabled or used only for map pins, the Blizzard objective dock remains available.

Late addon/frame creation is handled by addon events and Questie's real updates; header hooks attach when the button exists. Combat-deferred layout runs after combat, and the scroll range is recalculated after text wrapping. Forever's optional Blizzard quest timer is moved to the Questie dock, reserves room above the objectives, and returns to its original parent/anchors when released. [The tracker smoke check](../Minimap/_tmp_questiesmoke.lua) exercises both client layouts, native/Questie ownership changes, late loading, wrapped overflow, collapse/expand, combat deferral and the optional timer with mocked frames. Run it with `lua Minimap/_tmp_questiesmoke.lua`; it does not establish live taint safety.

[FluxBuffDebuffFrames.lua](../Minimap/FluxBuffDebuffFrames.lua) installs positioning/squeeze hooks for Blizzard buff/debuff/consolidated-aura frames and anchors them around the map/layout. Beside-map screen buttons now reserve the same horizontal space for BuffFrame and DebuffFrame; below/off/embedded modes restore their previous screen anchors. The screen-side 10–200% grid scale updates the actual space reserved beside auras, while columns and button size are chosen automatically. Actual aura contents remain Blizzard-owned here; this module differs from unit-frame aura rendering and the nameplate countdown overlay. Shared Core helpers provide the client-specific squeeze behavior.

## Configuration and checks

Map embedding/tab selection belongs to Flux Window; placement and surrounding tracker geometry use Layout/General settings. The minimap action strip is per character. Questie is detected automatically. Exact settings and commands are indexed in [options](26-options-map.md) and [commands](31-commands-and-bindings.md).

Test normal→embedded→other-tab→restored transitions, resizing/scale, combat entry/exit with pending positions, minimap ping/zoom, difficulty/mail/queue indicators, zone text overflow, saved actions above and below slot 15, both optional side starts/columns/combat hiding, long/empty objective lists, late tracker load, collapse/expand, timers, Questie absent/present and Forever's first login/level-up. Source hooks and mock layout tests do not establish live taint safety.

## Tracker ownership and combat flow

```mermaid
flowchart TD
  A[Tracker or minimap update] --> B{Questie trackerEnabled?}
  B -->|Yes| C[Questie dock and wrapped rows]
  B -->|No| D[Blizzard scroll dock and native layout]
  A --> E{Forever keyboard native callback in combat?}
  E -->|Yes, including hidden native tracker| F[Coalesce dirty/container work]
  F --> G[Regen then next-tick native flush]
  E -->|No| H[Keep eligible native pipeline]
```

`IsTrackerEnabled` checks Questie/loader/profile availability and the actual preference, rather than `IsShown`. Layout requests coalesce; a pending combat request resumes on regen. Late-created header buttons receive hooks when available. Timer placement starts from Questie's own quest-positioning function each time, reserves native timer height plus four pixels, and restores saved native parent/anchors on release. Repeated relayout therefore does not intentionally accumulate a timer offset. This is source/mocked evidence; [live scenarios](41-verification.md#current-compatibility-scenarios) remain pending.
