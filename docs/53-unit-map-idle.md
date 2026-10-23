# Unit-frame, portrait and open-map follow-up — 23 October 2026

The acceptance case remains **Flux Window's Map tab open on Live, Forever, Era, Anniversary and progression Classic**, with every feature retained. This follows the [Retail captures and shared idle fixes](52-retail-idle-hotspots.md). The native FPS gap is still unresolved by a controlled foreground measurement; a lower Lua operation count is not an FPS result.

## Implemented changes

[Shared unit-frame rendering](../UnitFrames/FluxUnitFrames_Shared.lua) now avoids rebuilding geometry that Flux already owns:

- Heal/absorb striped overlays retain their anchors to the current fill texture. Those anchors automatically follow the live fill. A replacement fill texture invalidates the anchor; a failed anchor update remains retryable.
- Overlay texture coordinates update when readable width, height or tile size changes. Secret or inaccessible dimensions are never cached or compared; their live result still reaches the native setter at the original cadence. Failed texture writes invalidate the cache.
- Prediction bars retain the same anchor until the preceding fill texture or readable offset changes. Live width/height, range and value updates remain synchronous. Secret offsets always use the native setter and are excluded from the cache.
- Both 3D and 2D portrait regions retain completed container/size geometry between partition passes. Resizing, replacing the portrait, replacing its container and retrying failed writes all refresh geometry. Model binding, face framing, animation, events, 2D/3D options and combat feedback remain unchanged.

These fields belong to Flux-created regions. Source inspection found no other anchor/size writer for these overlays or portrait regions. A future writer must invalidate or share this ownership; no cache is placed on a Blizzard unit frame. Health, power, incoming heals and absorbs themselves are not cached by this change. No native method, secure attribute, binding, SavedVariable, Edit Mode callback or native frame suppression path is changed.

[Battlefield Map initialization](../Battlezonemap/FluxBattlefieldMap.lua) now reuses its bounded scaling/legacy-zoom watchers across tab visits. Hiding or cleaning up the map cancels their scripts, including same-frame tab changes. The original next-frame scaling, zone refresh and legacy zoom fallback remain. If combat begins before a retry executes, the watchers stop and mark the existing deferred-embed state; `FinishDeferredEmbed` reconciles it once after combat. Combat-time initialization also cancels a previous out-of-combat retry. The map can continue its allowed live presentation while restricted setup waits.

This adds no permanent polling loop or timer. MapCanvas, scroll-container, player/group pin, zoom/pan, hover and provider update cadence remain unchanged. The Map tab is not closed or replaced to obtain a performance improvement.

## Audit boundaries

| Path inspected | Finding and decision |
|---|---|
| Shared unit-frame health/power/threat sampling | Earlier deadline-based polling is retained at 0.2/0.5 seconds. Secret values still paint; no slower sampling is introduced. |
| 3D portrait creation and camera events | Existing creation guard reuses models. Camera retries coalesce into three finite callbacks; there is no permanent portrait camera OnUpdate. Face framing and model animation are retained. |
| Saved Retail presentation capture | One visible Flux PlayerModel was recorded. This is not evidence of a duplicate active portrait leak or a native render-cost measurement. |
| Portrait combat feedback, health loss and power gain/loss drivers | Animation work is armed for feedback and parks afterward. True animation updates are retained. |
| Full-resource pulse | Combat/full-resource gating and fade/stop behavior are retained. |
| Native unit/raid suppression | Existing parent/shown-state preservation and Edit Mode deferral remain. No speculative restoration of hidden-parent suppression or native script replacement is introduced. |
| Native MapCanvas and detail layers | Root/provider, scroll and detail-loading callbacks have distinct duties. Their registered function labels do not prove that a hidden World Map executes. No native callback is throttled or removed. |
| Map tab initialization/cleanup | Returning to the tab recreated watcher frames; same-frame departure left stale retries. Reuse/cancellation addresses those actual lifecycle paths. |

## Executable validation

[Unit geometry replay](../tests/idle_unit_geometry.lua) executes the real prediction module and portrait geometry function against retained [overlay](../tests/fixtures/unit_overlay_geometry_before.txt), [prediction-anchor](../tests/fixtures/unit_prediction_geometry_before.txt) and [portrait](../tests/fixtures/unit_portrait_geometry_before.txt) bodies. It compares live values, anchors, sizes, UVs and visibility on five client/API models. Inputs include changed heals/absorbs, offsets, death, options, dimensions, replacement fills/portraits/containers, failed writes and secret dimensions/offsets/amounts. Six behavioral mutations are rejected. In its steady-state modern fixture, **300 calls of the prediction painter plus 300 explicit portrait-geometry synchronizations reduce anchor/UV writes from 10,500 to 1,800**. The fixture keeps fixed nonzero heal/absorb amounts. Production portrait synchronization follows partition/display layout requests, not every health update; these operation counts do not claim that synthetic call rate occurs on every idle character or constitute a native benchmark. Every live status-bar value update remains present.

[Map watcher replay](../tests/map_init_watchers.lua) executes actual initialization, hide, cleanup and deferred-embed recovery against the [retained earlier initializer](../tests/fixtures/map_initialization_before.txt). Thirty visits allocate **30 → 1 watcher frames** on the modern capability path and **60 → 2** on the legacy path. It covers all five client models, legacy `ZoomOut` fallback, absent dependencies, retry after failure, immediate departure, combat login, combat beginning before a retry and exactly-once deferred recovery. Five targeted mutations are rejected. Existing map-hook, window-tab, unit-poll, portrait-camera, startup, input, binding, migration and taint-ownership fixtures remain in the full suite.

[Operation evidence](validation/unit-map-operation-counts-2026-10-23.json) records exact commands, outputs and normalized source hashes. [Full validation](validation/unit-map-idle-2026-10-23.json) records the complete syntax/test corpus. Desktop Lua mocks do not execute WoW's secure/taint VM, real secret values or rendering engine.

## Native acceptance still needed

Keep the same scene, UI scale, camera, mouse position and open Map tab. With `scriptProfile=0` and WoW foreground, compare stable FPS before/after on each client; CPU-profiled or background readings are separate evidence. No native FPS improvement is claimed for these changes yet.

Test player/target/focus/pet and nested frames, 2D/3D mode, transforms/model loading, UI scale and squeeze, heal/absorb growth and expiry, resource feedback, combat, rapid Map/other-tab switching, map/minimap switching, world transitions and combat interruption/recovery. Check Retail/Forever Edit Mode save/exit for the previously reported errors; verify Forever gamepad, swing/threat, bank and paging behavior as part of the broader acceptance matrix. Those systems are unchanged here. Preserving their source is not equivalent to live testing every scenario, and the earlier native taint writer remains unconfirmed.
