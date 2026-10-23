# Minimap, embedded buttons, objectives and buffs

Flux reshapes Blizzard's minimap and relocates surrounding widgets. It can embed that same map into the Flux Window instead of maintaining a second minimap. [FluxMinimap.lua](../Minimap/FluxMinimap.lua) owns the global controller and its runtime `embeddedState` (original parent/size/points plus current host).

## Map appearance, controls and lifecycle

Initial configuration is a 190px square with a white square mask near the upper-right corner. Style/cleanup repositions supported indicators, queue-status eye, mail, tracking and difficulty controls, removes unwanted stock chrome and supplies a bordered info bar. Mouse wheel zooms; mouse-up hooks preserve Blizzard's native ping handler before adding Flux behavior. Zone text has fit/scroll/tooltip handling; clock and info-bar click targets are separate.

Map right-click opens the tracking menu on the Retail path or available calendar on the older path. Info-bar/zone left-click toggles World Map and right-click opens calendar when supported. Clock-area left-click opens calendar; right-click invokes available TimeManager/stopwatch helpers. The comment suggesting Shift-left stopwatch is not an implemented Shift branch.

`Initialize`, `UpdateStyle`, `CleanupBlizzardFrames`, `PositionIndicators`, `PositionQueueStatusEye` and `EnforcePosition` reconcile this presentation. `RequestEnforcerBurst` temporarily tightens checking after layout changes; idle fallback runs less often. The code uses event-driven updates plus these bounded/idle enforcers, not just a one-time login anchor. Addon/world/difficulty/group/mail/tracking/display/UI-scale events cover changing widgets and late Blizzard UI.

`EmbedInFrame(parent)` remembers normal geometry and lays out the map within the Flux Window. `RestoreToNormal`, `HideEmbedded`, `ShowEmbedded`, `IsEmbedded` and `GetNormalWidth` support tab changes and restoration. Hiding a non-Map tab must not accidentally leave MinimapCluster visible. Embed changes also update tracker geometry, Info Frame and the micromenu's minimap placement. The saved layout preference and runtime parent state are different things.

Protected reposition/reparent work queues through combat exit. Edit Mode compatibility avoids adding methods to EditModeManagerFrame or mutating its registered system-frame table; those paths can taint action-bar/vehicle layout. See [runtime restrictions](03-midnight-constraints.md).

## Embedded 3×5 action strip

[FluxMinimapButtons.lua](../Minimap/FluxMinimapButtons.lua) creates 15 EBS widgets in three columns beside the embedded map. `_FluxUI_CharSavedVars.minimapExtraButtons[index]` stores assignments, including macro index/name/body recovery data. Creation, refresh, slot layout, accent refresh and `OnEmbedStateChanged` are separate methods. The strip uses [EBS](12-extra-button-system.md) action/count/cooldown handling and only belongs to the embedded map arrangement; it is not the four noncombat utility slots.

## Objective tracker scroll dock

[FluxObjectiveTrackerScroll.lua](../Minimap/FluxObjectiveTrackerScroll.lua) wraps the supported objective tracker in a viewport, computes content height and anchors it relative to minimap/layout bounds. It handles scrollbar/content size, top-module gaps, header and quest-timer placement, full-layout requests, dirty-state recovery and combat-delayed setup. The implementation works with the actual client tracker/manager rather than inventing a new quest log.

`EnsureViewport`, `ApplyViewportSize`, `LayoutScrollArea`, `SyncAfterUpdate` and `RefreshLayout` are the central operations. Height/anchor hooks keep Blizzard's update pipeline inside the dock. Overflow scrolls instead of extending indefinitely into the bottom HUD. Hidden/zero-height bodies and late async manager initialization have explicit recovery paths.

Forever has additional compatibility: `InstallForeverCompat`, `StartForeverLoginPulse` and `KickScrollLayoutOnce` wait for the client's initialization sequence, correct stuck dirty state and stabilize the first dock. Ordinary world transitions do not continually force a full tracker layout. Current source deliberately avoids specialization/level listeners because Forever emits misleading spec events on level-up.

## Questie and buff frames

[FluxQuestie.lua](../Minimap/FluxQuestie.lua) is optional. It imports tracker/line/base/combat-queue modules through QuestieLoader, hooks real tracker updates and expand/collapse interaction, then sizes/anchors/styles lines and base frames. It does not continuously poll the expand flag; post-update hooks cover transitions. This tracker integration is separate from [Battlezone HBD pin routing](10-flux-window.md).

[FluxBuffDebuffFrames.lua](../Minimap/FluxBuffDebuffFrames.lua) installs positioning/squeeze hooks for Blizzard buff/debuff/consolidated-aura frames and anchors them around the map/layout. Actual aura contents remain Blizzard-owned here; this module differs from unit-frame aura rendering and the nameplate countdown overlay. Shared Core helpers provide the client-specific squeeze behavior.

## Configuration and checks

Map embedding/tab selection belongs to Flux Window; placement and surrounding tracker geometry use Layout/General settings. The minimap action strip is per character. Questie is detected automatically. Exact settings and commands are indexed in [options](26-options-map.md) and [commands](31-commands-and-bindings.md).

Test normal→embedded→other-tab→restored transitions, resizing/scale, combat entry/exit with pending positions, minimap ping/zoom, difficulty/mail/queue indicators, zone text overflow, the 15 saved actions, long/empty objective lists, late tracker load, collapse/expand, timers, Questie absent/present and Forever's first login/level-up. Source hooks and mock layout tests do not establish live taint safety.
