# Idle performance investigation — 23 October 2026

Latest follow-up: [background comparison and additional idle fixes](46-idle-followup.md).

This follow-up targets passive work, prompted by the reported Forever idle difference of roughly 200 FPS with FluxUI and 240 FPS without it. Those rates correspond to approximately 5.00 versus 4.17 ms per frame. The approximately 0.83 ms difference is an investigation target, not measured Flux Lua time or a guaranteed recoverable gain.

## Native baseline

The user supplied two 20-second captures on **Forever 1.60.1 / camelot, build 70532**, running from `F:\World of Warcraft\_classic_beta_`. The relevant source files matched the working tree before this optimization. The existing synchronization script includes that client. No player SavedVariables were directly edited; subsequent normal client reloads persisted the requested performance reports.

| Capture | Observations | Limit |
|---|---|---|
| Profiling disabled | 199.7 FPS average, 149.3 minimum; visible OnUpdates 37 to 36; `flux.cond.mo` remained registered. | CPU counters were unavailable; 0.00 ms/s does not mean no CPU work. |
| Profiling enabled | 211.5 FPS average, 164.0 minimum; Flux CPU 11.25 ms/s; visible OnUpdates 36 to 38; `flux.cond.mo` remained registered. | Profiling changes overhead; these FPS values are not a matched before/after comparison. |

The full profiled baseline was read from the client's saved `FluxPerfCaptureDB` without modifying it and exported to [forever-idle-native-before-2026-10-23.json](validation/forever-idle-native-before-2026-10-23.json). It includes all 50 recorded function and frame rows. Key inclusive function readings were:

| Function | CPU | Calls in 20 seconds |
|---|---:|---:|
| `FluxInfoFrame._CamelotSpellBonus` | 9.82 ms/s | 60 |
| `FluxInfoFrame.ResolveStatFramesForTooltip` | 9.74 ms/s | 150 |
| `FluxInfoFrame._ClassicSpellDamageColorHex` | 2.99 ms/s | 30 |
| `UF_UnitFramePollFrame:OnUpdate` | 2.69 ms/s | 4,188 |
| `UnitFrames.UpdateHealth` | 1.34 ms/s | 98 |

These rows overlap and must not be summed. The native frame results also include shared chat/status callbacks and opaque frame names; they do not prove that each named object independently incurs that cost. The small `bars.paint.lane` contribution and lack of other shared ticker subscribers argue against indiscriminately slowing action-bar painting. Native/rendering cost is outside this Lua attribution.

The [first candidate capture](validation/forever-idle-native-first-candidate-2026-10-23.json) confirms that `flux.cond.mo` is no longer registered while idle. Spell bonus CPU falls from **9.82 to 3.83 ms/s**, resolver CPU from **9.74 to 3.79 ms/s** (approximately 61% lower), and reported Flux CPU from **11.25 to 9.84 ms/s** (approximately 12.5% lower). Health samples remain at the prior rate. However, profiled FPS is **195.5**, below the baseline's 211.5: these observations establish reduced measured Lua work, **not an FPS improvement**.

The user confirms the World Map was closed and Flux Window's Map tab open. Native map callbacks appear prominently in the candidate rankings, but script counters can be labeled with a closed owner's name. Subsequent diagnostics therefore record map visibility and registered OnUpdate owners; the existing visible-map animation/input cadence remains intact. The final code also names the four private InfoFrame drivers to improve further attribution.

## Agent-operated native follow-up

At the user's request, the agent operated the already-open Forever client through ordinary diagnostic slash commands, saved completed reports through normal reloads, and exported only `FluxPerfCaptureDB`. The chat copy button was unnecessary because the saved report contains the complete ranked lists. All eight changed runtime files were subsequently confirmed to match the Forever installation. CPU profiling was restored to **0**, the client reloaded, and the original cursor position restored.

| Capture | Result | Evidence |
|---|---|---|
| Final profiled candidate, 20 seconds | Flux CPU **8.23 ms/s**; FPS average 215.6, minimum 160.1; no shared ticker subscribers. Spell bonus **2.61 ms/s / 30 calls**, resolver **2.57 ms/s / 80 calls**. | [Full profiled report](validation/forever-idle-native-final-profiled-2026-10-23.json) |
| Final candidate with profiling off, 20 seconds | FPS average **184.3**, minimum **142.6**; no shared ticker subscribers. Foreground sampled 23 times, with zero background observations. CPU rankings unavailable. | [Full unprofiled report](validation/forever-idle-native-final-unprofiled-2026-10-23.json) |

Both reports confirm **World Map hidden, embedded Battlefield Map visible, Flux tab Map, CharacterFrame hidden** at both endpoints. The agent-operated outdoor view differs from the original inn scene, and camera framing changed between the two final runs. The reported Flux CPU is approximately 27% below the earlier 11.25 ms/s observation, but these are not controlled before/after samples. The unprofiled 184.3 FPS observation does **not** demonstrate recovery of the reported 200/240 FPS difference.

The largest remaining callback was anonymous in that run: approximately **8.71 ms/s**, 4,284 calls and one visible registered owner. A further [source-attribution capture](validation/forever-native-source-attribution-2026-10-23.json), using guarded `GetSourceLocation()` reads, identifies the corresponding leading frame as created at **`Blizzard_SharedXMLBase/GlobalCallbackRegistry.lua:9`**. In the Forever reference this is `EventRegistry.frameEventFrame`; its OnUpdate iterates `onUpdateCallbacksByOwner`. It accounts for **8.08 ms/s** in that additional run. This identifies the native dispatcher, not which registered callbacks or addon hooks contribute its inclusive time. No global dispatcher or callback was modified. The same report identifies **Questie's HereBeDragons pin driver (2.58 ms/s)** and **FluxChatColumnMicros' character-button watcher (2.10 ms/s)**. The latter preserves frame-synchronous native character-panel/press mirroring, particularly Forever's no-native-hook policy.

The source-attribution run measured Flux CPU at **8.15 ms/s**. It remained in the foreground for all 23 observations, but the character changed position/zone and camera view during the sample. It is **not an idle benchmark or matched FPS acceptance result**. Profiling was again disabled, the client reloaded, and the cursor restored afterward. Frame creation sources are persisted separately from callback definitions; unsupported, failing or secret source reads are omitted.

Native map detail, scrolling and canvas functions also remain prominent. In the Forever reference, the hidden World Map registers `MapCanvasMixin.OnUpdate`, and Flux's visible Battlefield Map wrapper calls that function directly. A unique hidden registered owner therefore still does not prove hidden-frame execution. Function CPU includes such direct calls and overlaps other rows.

## Implemented changes and preservation rules

| Source | Change | Preserved behavior |
|---|---|---|
| [FluxInfoFrame](../StatusBars/FluxInfoFrame.lua) | Discover all character stat keys in one tree traversal; share the frame-reference cache across damage/healing/tooltip lookups. Reuse the current spell data for its color. | Read current numbers and visibility on every query. Preserve the existing 0.25-second structural discovery bound, root replacement, active pools/Forever ScrollBox frames, row assignment invalidation, native/proxy filtering, pinning and tooltip behavior. No CharacterFrame hooks or character watcher cadence changes were added. |
| [ProgramFace](../Bars/ProgramFace.lua), [Context](../Core/Engine/Context.lua) | Sleep the mouseover watchdog when no unit is present. Wake through both existing event-routing paths, including unchanged Context fingerprints. | Keep the 70 ms active poll cadence, existing trailing coalescing, reaction/death updates, cursor re-entry and clients that omit leave events. Macro indexing and secure input remain unchanged. |
| [Restricted](../Core/Engine/Restricted.lua) | Parse identical conditional strings once per fallback sweep, including nil results. Avoid existence queries whose results normal unit watches never used. | Keep Forever's event-assisted 0.2-second fallback, combat guards, as-state existence watches and separate secure paging policy. No result is cached across sweeps or events. |
| [Shared unit frames](../UnitFrames/FluxUnitFrames_Shared.lua) | Use existing `Flux.Timer.NewTicker` for health/visibility and combat threat deadlines; cancel when unused. Remove repeated plain-number comparison closures. | Keep the original 0.2/0.5-second intervals, immediate event updates, target-of-target checks, initial-combat handling, secret-value fallbacks and timerless OnUpdate fallback. |
| [Shared unit portraits](../UnitFrames/FluxUnitFrames_Shared.lua) | Clear an absent owned portrait once; invalidate on repaint, replacement, external show or delayed model loading. Retry failed clears. | Preserve 3D/flat portraits, question marks, hidden/absent transitions and fresh models. Existing owned `OnModelLoaded` handles late completion; no native model hooks were installed. |
| [Minimap](../Minimap/FluxMinimap.lua) | Write the clock only when its minute changes and stop its timer while hidden. Marquee animation reuses text/layout/color and always detaches obsolete callbacks after refitting. | Clock refreshes immediately on show. Zone text, color, width changes and active scrolling remain responsive; position animation still runs every frame while active. |
| [Battlefield map lifecycle](../Battlezonemap/FluxBattlefieldMap.lua) | Retain permanent native show/hide hook flags across cleanup and reuse the dormant zone watcher. | Preserve map visits, native visibility recovery, providers/pins, gamepad and Classic method restoration. Inactive/stale callbacks cannot reopen or refresh an inactive map. Native canvas/scroll/detail animations are unchanged. |
| [InfoFrame horizontal layout](../StatusBars/FluxInfoFrame.lua) | Pass current measured width through one layout transaction. Measure again after every merge, compact/hybrid text change or font change. | Preserve final text, fonts, merge choices, anchors and tooltip descriptors across width/font combinations. No cross-transaction value cache or delayed layout. |
| [On-demand CPU capture](../Other/FluxPerfCapture.lua) | Record map/character visibility, shared OnUpdate ownership and available frame creation sources; identify namespace-owned frames. | No scans, timer, hook or wrapper runs until a capture is requested. Old saved captures remain printable; forbidden/inaccessible objects and secret source results remain uninspected or omitted. Creation source is not callback definition. |

No option, default, saved preference, binding, supported branch, integration or player feature was removed. No graphics/FPS CVar was changed by the code. Native nameplate region reanchoring was left intact: its existing secret-value/no-native-measurement constraints need stronger proof before safely suppressing writes.

## Repeatable operation counts

These are deterministic desktop Lua controls, separate from the native capture above. They measure work eliminated, not FPS. Full command outputs and source fingerprints are in [idle-operation-counts-2026-10-23.json](validation/idle-operation-counts-2026-10-23.json). The retained HUD bodies are [idle_hud_before.txt](../tests/fixtures/idle_hud_before.txt); the other controls reconstruct only the relevant old polling/clearing/comparison paths.

| Scenario | Before/control | Candidate |
|---|---:|---:|
| Indexed mouseover macro, no unit, 60 seconds at 240 Hz | 14,400 callbacks; 848 reaction probes | 0; 0 |
| Forever, 36 fallback drivers sharing 3 strings, 60 seconds | 10,800 parses | 900 parses |
| Same fallback with 57 normal unit watches | 17,100 unused existence queries | 0 |
| Unit poll dispatch, 20 seconds at 240 Hz | 4,800 per-frame callbacks | 100 health timer callbacks; 0 per-frame callbacks |
| Four absent watched portraits, 60 seconds | 1,200 model clears | 4 |
| 3,000 unchanged health/power samples, host Lua heap with GC paused in test only | 1,171.88 KB from old comparison closures | 0 KB in that loop |
| Stat discovery, 30 refreshes over 124 nodes | 22,320 child enumerations | 3,720 |
| Ten visible minutes of clock updates | 601 text writes/formats | 11 |
| Hidden clock for 120 seconds | 120 calendar queries | 0 |
| 2,400 active marquee frames, unchanged content | 9,600 text/width/measurement/color operations | 0; animation positions still update |
| 2,400 idle frames after refitting the marquee | 2,400 leaked callbacks | 0 |
| 30 Map-tab visits | 465 refreshes; 30 zone watchers; 30 hook pairs | 30 refreshes; 1 watcher; 1 hook pair |
| Fitting three-stat horizontal layout, width/font/text native calls | 18 / 21 / 21 | 6 / 9 / 9 |

The fallback driver's 14,400 frame callbacks in its synthetic fixture are deliberately retained; this change deduplicates its work rather than altering the Forever compatibility cadence. The native CPU capture recorded that driver at approximately 0.30 ms/s, considerably below the stat resolver.

Reproduce with:

```text
lua tests/idle_bars.lua --baseline
lua tests/idle_bars.lua
lua tests/idle_units.lua
lua tests/idle_hud.lua --baseline
lua tests/idle_hud.lua
lua tests/idle_map.lua --baseline
lua tests/idle_map.lua
lua tests/idle_info_layout.lua
lua tests/perf_capture.lua
python -B tests/run_validation.py --output docs/validation/idle-optimization-2026-10-23.json --sync-docs
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
git -c core.safecrlf=false diff --check
```

The [previous validation](validation/before-idle-optimization-2026-10-23.json) preserves 44 passing scripts before this work; the [first-pass validation](validation/idle-first-pass-validation-2026-10-23.json) records 47 before the map/layout/diagnostic follow-up. The [final validation](validation/idle-optimization-2026-10-23.json) records 50 passing scripts, 687 syntax-checked Lua files and the current source manifest. Six new fixtures cover five client policies and reject 49 targeted production mutations/negative controls at their intended assertions. The diagnostic fixture covers inaccessible/secret namespace tables, forbidden owners, unavailable/throwing/secret source APIs, shared callbacks, direct-call attribution limits and older saved reports. Documentation/source evidence and whitespace checks pass; the inventory retains 353 setting definitions and 501 literal defaults. Luacheck is not installed.

## Native comparison still required

A controlled FPS comparison still needs the same scene, camera, mouse position, target/group state and HUD tabs. The completed native captures verify that `flux.cond.mo` sleeps with no mouseover and the stat resolver uses less CPU in the observed scenes. Automated fixtures cover timer dispatch and feature behavior; native mouseover arrival/leave/death, health/power/ToT changes, combat threat, portrait loads, scrolling zone names and hidden/shown minimap HUD still need acceptance.

Restore `/console scriptProfile 0` and reload before comparing final FPS with and without FluxUI under otherwise matching conditions. This report does not claim that the entire 200/240 FPS difference has been recovered. The five-client combat/startup/transition scenarios in [the startup report](43-startup-optimization.md#client-source-checks-and-required-game-acceptance) still require native acceptance.
