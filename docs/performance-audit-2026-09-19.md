> **Historical audit, retained for context.** This report records the 19 September 2026 investigation and source layout. Its counts, named old implementations, claimed fixes and checks are historical assertions, not a fresh validation of the 22 October working tree. The referenced `tests/performance_inventory.py` and `tests/performance_regression.py` were subsequently removed; do not use those commands as current instructions. `Other/FluxNamePlates.lua` was replaced by the current `NamePlates/` subsystem. Use the [current driver inventory](performance-driver-inventory.md), [shared diagnostics](08-shared-services.md), [findings](40-findings.md) and [verification procedures](41-verification.md) for current evidence.

# Performance audit — 2026-09-19

## Finding and limits

Reported: Retail runs around 150 FPS with FluxUI and can reach 300 FPS without it, including idle scenes. Those rates correspond to approximately 6.67 ms and 3.33 ms per rendered frame. That difference is a frame-time budget to investigate, not a measurement of Lua CPU: render cost, frame limiting, other addons, and scene differences can contribute.

No FPS-cap/VSYNC/render-scale writes were found in FluxUI. No game client or actual CPU capture was available during this audit. The complete cause of the 150 FPS result is **not yet established**, and no FPS improvement is claimed from static analysis.

The TOC/XML inventory covers 525 reachable files across the four requested client gates, including 505 Lua files. It found 167 candidate recurring-driver registration sites (136 OnUpdate and 31 ticker sites), plus event, timer and hook sites. These are source counts, not simultaneously active tasks. See [the full inventory](performance-driver-inventory.md); regenerate it with `python tests/performance_inventory.py`. Text scanning can include definitions and miss dynamic/native registrations. It is not a proof that every runtime hotspot has been found.

## Confirmed waste corrected

| Change | Applies to | Evidence and preserved behavior |
|---|---|---|
| Coalesce aura bursts into one cancellable trailing timer | Lua aura backend, chiefly Era/Anniversary; fallback on other clients | `UnitFrames/FluxUnitFrames_Auras.lua`, `RequestAuraRefreshThrottled`: previously assigned the return of `C_Timer.After` to a handle and tried to cancel it. All four source trees document no return from After and a cancellable callback object from NewTimer. Repeated events could queue callbacks, and an older callback could consume a newer pending refresh. The fix uses one NewTimer for the remaining throttle window; explicit refresh, disable, and unit changes invalidate pending work. No aura features or active refresh rate removed. Retail engine auras take a separate path, so this is not an explanation for steady Retail idle loss. |
| Install InfoFrame grid hooks once per object | All four | `StatusBars/FluxInfoFrame.lua`, `HookGridRelayout`: called at setup and every PLAYER_ENTERING_WORLD without installation guards. Hook callbacks accumulated across loading screens. Both Relayout hooks and OnSizeChanged hooks are now guarded on their actual owning objects; replacement grid frames still receive hooks. |
| Park empty nameplate polling | Forever, Era, Anniversary | `Other/FluxNamePlates.lua`, `StartTicker`: permanently shown frame ran 0.05s tint, 0.1s countdown, and 0.25s discovery paths even with no plates. After an empty cleanup sweep it now hides; NAME_PLATE_UNIT_ADDED/REMOVED and PLAYER_ENTERING_WORLD wake it. Settings previews also wake it. Existing active update intervals and visual logic are preserved. Retail mainline excludes this file in its TOC. |
| Repair measurement gaps | All four | Old report used cached addon CPU without updating it and treated IsShown as effective visibility. It also emphasized unloaded LAB/old ExtraButton implementations. The new capture measures deltas for current module functions, ticker subscribers, named passes, and all inspectable frames, including anonymous and Blizzard frames. The old report remains available. |

Original versions of changed existing files are in `.perf-backup-20260919/`; that directory is not TOC-loaded.

## Remaining candidates, ordered for investigation

These are verified running paths or reachable patterns, **not a measured ranking**. Preserve the listed behavior when optimizing them.

| Candidate | Client scope and cadence | Why investigate / feature constraint |
|---|---|---|
| Embedded battlefield map and mirrored providers | All four; visible map scripts execute per frame | `Battlezonemap/FluxBattlefieldMap.lua` and `FluxBattlefieldMapWorldFeatures.lua` keep a full MapCanvas visible and can mirror WorldMap providers. Live/Forever MapCanvas OnUpdate runs pin suppression, nudging, cursor processing and provider updates; Era/Anniversary's base OnUpdate only nudges pins. Inspect BattlefieldMapFrame, its scroll container and provider costs in the capture. Costs may be charged to Blizzard or third-party code. Retain pins, interactions and map tracking; do not simply disable the map. |
| Unit frame health/power and visibility safety polling | All four; 0.2s health/visibility, 0.5s combat threat | `UnitFrames/FluxUnitFrames_Shared.lua:192`. Player remains registered in the shared poll table; target/focus visibility and target-of-target health checks also run. The player branch does not check effective visibility. Secret health/power cannot use numeric equality caches, so it always refreshes in that case; health updates include predictions and text. Profile before replacing event fallbacks. Target-of-target changes and secret-safe display must continue working. |
| Hover/macro background probes | All four when corresponding bindings exist | `Bars/ProgramFace.lua`: mouseover polling at 0.07s whenever mouseover conditions exist; peek polling at 0.05s can stay armed while any hover program exists, even when not hovering. `Core/Engine/Context.lua` also polls peek context while armed. `ExtraButtonSystem/Engine/Action.lua` probes flying/mounted/swimming/indoors/flyable at 0.15s. Shared Ticker callbacks still dispatch every rendered frame. Preserve cursor-leave detection and macro-condition updates if consolidating these. |
| Range sweeps over bars, Extra buttons and badges | All four when a range unit exists; 0.25s bars / 0.18s EBS defaults | `Core/Engine/Range.lua`, `Bars/Watch.lua`, `ExtraButtonSystem/Engine/Range.lua`. Memoization already exists and range paints use dedicated lanes, but demand checks and sweeps still traverse surfaces. `RunSweeps` runs registered surfaces even when only another surface needs range. Need the final clear pass to remove stale red tints, and immediate target/focus changes must survive optimization. |
| Assisted Combat duplicate polling paths | Clients exposing Assisted Combat; approximately 0.05–0.1s or client-configured | Both `Bars/Watch.lua` and `ExtraButtonSystem/Engine/Watch.lua` have separate assistant tickers and query update rate before their elapsed gate, so rate lookup happens every frame while armed. Bars also walk hosts for highlights. Consolidation must retain the rotating action icon, highlight, and configured update rate. |
| Engine aura full-refresh fan-out | Live/Forever engine aura backend; event bursts | `UF.PokeEngineAuras` calls SetUnit and UpdateAllAuras for buff and debuff containers from Flux's UNIT_AURA handler. The native container also owns UNIT_AURA and updates incrementally. `UF.SyncEngineAuras` additionally reapplies flow/group sizing. This is a candidate duplicate refresh path, especially under many aura events, not an always-on idle explanation. Preserve engine secret-safe aura handling and explicit target/focus refreshes. |
| Raid extras and MT/MA target minis | All four with Flux raid frames enabled | `RaidFrame/FluxRaidFrame.lua`: range/status safety sweep every 0.75s over assigned frames; MT/MA wrappers poll target mini frames independently. Cost scales with roster/mini count. Existing aura/dispel work has already been excluded from the periodic extras path. Preserve range/status updates and target mini responsiveness. |
| Nameplate work with plates present | Forever/Era/Anniversary | Empty-scene work is fixed, but active 20Hz tint reassertion, Classic 10Hz countdown and 4Hz discovery remain. They scale with visible plates and deliberately avoid unsafe Blizzard nameplate hooks. Preserve threat, levels, countdown and settings preview behavior. |
| Cast fills, glows, countdowns and native animations | All four, only while corresponding effect is live | `Core/ButtonFX/Overlay.lua` updates active fills per frame; Classic fill path also reapplies anchoring/color, and native fill probes cast/channel data per watched widget. `LibCustomGlow` has per-effect animation work. Preserve smooth animation; investigate shared cast timing and stable layout caching rather than lowering animation rate blindly. GPU/native drawing is not fully represented by Lua CPU metrics. |
| InfoFrame stats, minimap clock and hovered tooltips | All four when visible/hovered | `StatusBars/FluxInfoFrame.lua` updates stats every second, may rebuild merged text when FPS changes, and polls hovered tooltips every 0.05s. Minimap clock ticks every second. These are persistent but low-frequency candidates; don't infer a 3.33ms/frame cost from their mere existence. Layout hook accumulation is fixed separately. |
| Inventory/classification and grid refresh fan-out | All four; normally events, login settling or combat | `Inventory/Init.lua` uses budgeted queues; `FluxConsumableBest/Scan.lua` resumes unresolved classification every 1.5s. CombatGrid refreshers run every 0.5s only in combat. A stuck queue can look like persistent lag; normal idle must be measured after login settles. Preserve cold-cache item handling and consumable selection. |
| Forever insecure-driver fallback | Forever/capability fallback only | `Core/Engine/Restricted.lua` polls registered attribute drivers and unit watchers while fallback is active. Cannot remove it as if it were a redundant Retail secure-driver path; it owns behavior on clients without the same secure execution support. |
| Details, UI startup retries, drag/hover watchers | Dependency/state-specific | Details containment watchdog is bounded; many apparently permanent OnUpdates detach after setup, hide, drag release or hover exit. Unloaded legacy `LibActionButton`, old ExtraButton Engine/Events and old FluxInv scanner must not be blamed solely because they exist on disk. The inventory distinguishes TOC reachability; in-game deltas distinguish live work. |

## Four-client source verification

All references are the user's local snapshots under `../__AddonsForRef/` (not claims about a different downloaded version).

| Source / contract | Live | Forever | Era | Anniversary |
|---|---|---|---|---|
| `Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua`: After has no return; NewTimer returns callback handle | Verified | Verified | Verified | Verified |
| `Blizzard_APIDocumentationGenerated/PerformanceDocumentation.lua`: addon/frame/function CPU and UpdateAddOnCPUUsage available | Verified | Verified | Verified | Verified |
| `Blizzard_APIDocumentationGenerated/NamePlateManagerDocumentation.lua`: added/removed lifecycle events | Verified | Verified | Verified | Verified |
| `Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`: UNIT_HEALTH present | Verified | Verified | Verified | Verified |
| `Blizzard_MapCanvas/Blizzard_MapCanvas.lua`: per-frame base work | Suppression/nudging/cursor/provider paths | Suppression/nudging/cursor/provider paths | Pin nudging | Pin nudging |
| `Blizzard_AuraContainer/Blizzard_AuraContainer.lua`: engine-owned UNIT_AURA handling | Verified | Verified | Flux Lua backend | Flux Lua backend |

## Capture procedure

1. Keep resolution, UI scale, scene, camera, foreground focus, graphics settings and other addons identical. Wait about 30 seconds after login/reload for inventory and layout settling.
2. For CPU attribution: `/console scriptProfile 1`, then `/reload`.
3. Stand idle without moving the mouse: `/fluxperf capture 20`. It does not hide UI, disable features, wrap global functions, or reset the client's CPU counters.
4. Paste the printed rankings. `/fluxperf last` prints the most recent capture again. `/fluxperf cancel` cancels a running capture.
5. Repeat with a target, a group/raid, during combat, and with the map/meter tab in the state used when lag occurs. Run separately on each client; keep reports labelled by client and scenario.
6. Restore `/console scriptProfile 0`, then `/reload` before comparing final FPS with/without FluxUI. Profiling itself has overhead, so profiled FPS is not the acceptance benchmark.

Only the last completed capture is persisted as `FluxPerfCaptureDB` in the addon's SavedVariables file on normal reload/logout. It contains client/build, profile CVar, FPS samples, relevant graphics CVars, addon CPU delta, visible frames with OnUpdate scripts, shared ticker subscriber names and the top 50 rows per CPU category. Print shows 12 rows per category. `/fluxperf probe` is the older visibility A/B probe; the new capture does not use it.

Limits: frame/script/module timings overlap and must not be added together. Named passes can nest. Frame endpoint scans are excluded from the addon CPU/time boundary, but individual function/frame counters are read sequentially, and sampling has some overhead. Newly discovered functions/frames without a baseline are omitted rather than charged their lifetime totals. A visible OnUpdate script can have native OnUpdateMode disabled. Native rendering, GPU cost, anonymous timer callbacks not exposed through a sampled function, and all private engine work are not comprehensively attributed. Low Lua CPU with a large FPS loss means rendering/native work needs investigation; it does not mean the addon is cleared.

## Verification

- All 505 TOC/XML-reachable Lua files compile in Lua 5.1; no missing load references in the four-client inventory.
- `python tests/performance_regression.py`: aura burst coalescing/cancellation, stale unit and overdue timer handling, repeated layout hook installation and replacement frames, capture delta arithmetic/client labels/forbidden-frame handling/cancellation, empty nameplate sleep/wake/preview, and ticker snapshot isolation pass with mocked WoW APIs.
- These tests cannot validate real WoW rendering, combat restrictions, secure taint, or FPS. Required in-game checks remain: aura expiry/target swaps, loading screens and grid resizing, nameplate appearance/disappearance/previews, and captures across the four clients. No feature was intentionally removed or disabled.
