# Idle follow-up — 23 October 2026

This continues the [idle investigation](45-idle-performance.md). It preserves all features and settings; the remaining FPS difference is not yet resolved.

The latest [Retail capture and shared trinket/tier changes](52-retail-idle-hotspots.md) identify two further source-supported targets. The new deterministic controls preserve frame-synchronous input and live item usability. Repeated native profiling records lower CPU readings without an FPS improvement; the wider gap remains unresolved.

The later [v9 comparison follow-up](51-input-and-native-callbacks.md#stance-flicker-player-artwork-containers-and-retained-idle-optimization) verifies eight retained optimization regions against optimized main, reruns the idle fixtures, and records a new Forever capture. The reported near-300 versus near-200 FPS change remains unverified by a matched capture. The new sample averages 238.91 FPS; it is not attributed to the code changes.

## Measurements and limits

An independent temporary sampler recorded 20-second intervals with and without FluxUI. Initial foreground attempts were interrupted by Chrome and are [retained as rejected evidence](validation/idle-rejected-native-comparisons-2026-10-23.json). The user confirmed using Chrome during those intervals. They are not foreground FPS acceptance.

The subsequent [background comparison](validation/idle-background-comparison-2026-10-23.json) contains one usable pair:

| State | Average FPS | Median FPS | Samples |
|---|---:|---:|---:|
| FluxUI disabled temporarily | 273.55 | 275.23 | 20 |
| FluxUI restored | 184.10 | 183.77 | 19 |

Both intervals have matching player coordinates, instance, zone, facing, zoom and CVars at both endpoints. Speed is zero, and the character is a ghost. The host recorded 20 background observations and zero foreground observations during each interval. Screenshots corroborate matching world framing. The earlier on interval is excluded: its position differs slightly and no contemporaneous focus trace covers it.

This reproduces lower FPS with FluxUI **in this background scene**. It is one pair with uncontrolled Chrome activity, not a foreground benchmark, a living-character/combat test, or evidence of an FPS gain from this follow-up's code changes. The source of the entire difference remains unproven. Earlier Lua CPU reports do not measure native UI rendering cost.

A separate [native recent-metric capture](validation/idle-native-application-metrics-2026-10-23.json), with `scriptProfile=0`, samples Blizzard's `RecentAverageTime` metric five times: application **4.020 ms/tick**, all addons **0.0441 ms/tick**, and Flux **0.0211 ms/tick**. This is a different diagnostic interval, not the paired FPS sample. The application metric includes the wider application, so these figures do not isolate GPU time or prove which native UI component causes the gap. They support investigating native UI/engine costs before further marginal polling reductions. The APIs are capability-detected and optional on older clients.

The [presentation audit](validation/idle-native-presentation-2026-10-23.json) records 19,714 inspectable frames, 1,660 visible frames and 3,750 regions on visible frames across all addons/native UI. Twelve model frames are visible: one Flux player portrait and eleven native scenes; two native tracker scenes have effective alpha zero. This does not reveal a duplicate Flux portrait leak. Intended portrait animation and native widget/effect scenes remain intact; visibility alone does not establish render cost.

## Implemented changes

- The chat character-button watcher repaints only when its pressed state changes. It still checks every frame, preserves the secure child click route and Forever's no-native-character-hook policy, and retries unfinished protected repaints after combat. Portrait refreshes invalidate the cached appearance. Hover glow, masks, alternate character panels and legacy portrait cropping remain supported.
- The chat bag counter no longer treats `C_Timer.After` as a cancellable timer. One pending callback coalesces inventory events, keeps updates at most 0.2 seconds apart during continuous bursts, and performs a trailing reconciliation 0.2 seconds after the last event. This trailing update includes the source counter's asynchronous refresh. Timerless fallback remains immediate.
- Opt-in performance captures now include visible-frame/region counts, visible model frames with available creation sources/effective alpha, and supported modern application/addon timing samples. Visibility and alpha are separate; a visible frame at alpha zero is not proof it renders. Forbidden objects and secret results are excluded. Scans run only at capture endpoints; timing queries reuse the requested capture's sampler. Neither adds idle work.

The actual production-handler fixture [idle_chat.lua](../tests/idle_chat.lua) compares the retained old handler in [idle_chat_bag_before.txt](../tests/fixtures/idle_chat_bag_before.txt). In 2,400 unchanged open-panel frames, layout writes fall from **26,400 to zero**. A 200-event inventory burst drops from **200 callbacks to two**, with one outstanding callback at a time. Tests cover asynchronous source freshness, continuous events, later bursts, timerless behavior, legacy and current shells, hidden buttons, duplicate setup, press/drag transitions, alternate panels, portrait refresh and combat retry. These are deterministic operation counts, not native FPS gains.

Exact outputs and normalized source hashes are retained in [follow-up operation counts](validation/idle-followup-operation-counts-2026-10-23.json).

## Temporary sampler recovery

Forever blocked the first background protocol's addon-initiated `ReloadUI()` callback. That protocol was stopped; normal `/reload` chat commands restored FluxUI. The replacement sampler contains no addon reload calls: ordinary reloads run between completed measurements and restores the user's previous foreground window. It restored FluxUI and disabled itself at the end; its two temporary addon files were then removed. The blocked operation is not treated as a successful test, and no protected-action workaround was introduced.

No graphics/FPS CVar, binding or player SavedVariables was directly edited. The comparison temporarily changed only FluxUI's native addon enable state and the temporary sampler's own state; FluxUI is restored. Native client reloads persisted the diagnostic reports normally.

## Validation

The [full validation](validation/idle-followup-2026-10-23.json) covers **51 passing scripts and 688 syntax-checked Lua files**, including the two formerly failing scripts. Seven idle fixtures reject 57 targeted mutations/negative controls. The capture fixture covers missing, throwing and secret modern metrics, visible/hidden models, transparent/secret alpha, and zero metric queries on load or saved-report printing. Documentation generation, source evidence, local links and whitespace checks are rerun after the changes. Native five-client gameplay, secure combat acceptance and a controlled foreground FPS comparison remain pending.
