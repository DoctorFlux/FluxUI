# Resource effects performance follow-up

10 November 2026 — RESOURCE-EFFECTS-PERFORMANCE-20261110. This continues the authorized [passive optimization](PASSIVE_PERFORMANCE_OPTIMIZATION.md) and checks resource effects adjacent to the [combat-invite partition correction](POWER_PARTITION_COMBAT_JOIN.md). Preserve appearance, features and update timing. Work is limited to shared resource helpers and the power-cost overlay; other party/raid feature work remains paused.

The later [additional passive pass](PASSIVE_PERFORMANCE_PASS2.md) preserves both resource runtime owners byte-for-byte and passes the full 295-script/967-syntax suite. Results below remain evidence for this earlier correction's stated workloads.

| Requirement | Acceptance |
| --- | --- |
| RFX-01 Reduce repeated work | Exact before/after production-code replays, repeated matched samples and operation counts |
| RFX-02 Preserve timing and appearance | Same nominal animation durations, value ordering, geometry and art; native pixels remain a separate check |
| RFX-03 Respect combat ownership | Prepare protected helpers outside combat; exercise cold first use, completion, identity changes and disable without protected structural attempts |
| RFX-04 Avoid secret arithmetic | Validate public geometry before comparison/arithmetic; invalid or inaccessible inputs never enter caught arithmetic |
| RFX-05 Preserve idle lifecycle | Inactive helpers have no per-frame callback; reuse existing deferred ownership and event/timer services |
| RFX-06 Preserve compatibility and evidence | Five pinned client families, exact checkpoint/candidate hashes, regression checks and unchanged data/assets/input policy |

Baseline: external `resource-effects-followup/checkpoint-20261110T145129Z`, 2,539 files, complete SHA256 manifest and verified Git history on main. Available settings metadata was inspected read-only (53 entries); no private settings were copied and no quiescent settings backup is claimed.

Native client operation, true secret values, pixels, taint and FPS have not been tested for this follow-up. No client foreground/input, settings/profiler write, manual synchronization or publication occurred.

## Shared spark and full-resource pulse

Spark height/width getters now pass the existing public-geometry guard before arithmetic or comparison. Catching a forbidden operation with pcall contained a Lua error but could still generate native diagnostic work. Public spark geometry retains its original sampling cadence and style behavior; unverifiable inputs retain the hidden/unscaled fallback.

Eligible HUD main bars prepare their unchanged full-pulse animation tree in the power-bar factory, before a future party member needs its first paint. Preparation through styling alone would miss hidden future party slots. The inactive tree stays transparent with no OnUpdate. Classic, health-only, party-pet and inactive secondary mana/stagger bars avoid this preparation. Explicit active demand remains available where supported.

Cold requests that cannot already use prepared resources defer through the existing combat owner, preserving the latest requested state. Existing Core combat/events services supply fallback ownership; completion removes only its own callback. A missing service leaves the request retryable without attempting protected allocation or permanently marking the pulse failed because of combat.

| Shared replay, per HUD scenario | Exact checkpoint | Candidate |
| --- | ---: | ---: |
| Secret/inaccessible geometry arithmetic or comparison attempts | 400 | 0 |
| Cold protected structural attempts | 5 | 0 |
| Geometry reads during 300 settled spark paints | 900 | 900 |
| Style writes during those settled paints | 0 | 0 |

Three matched pairs produce identical counters; the candidate passes 122 checks and rejects nine harmful controls. The original animation constructor/art/durations remain byte-identical. Preparing an eligible HUD main bar adds **three dormant Frames, four Textures, three AnimationGroups, twelve Animations and one regeneration subscription**. This is a bounded safety tradeoff, not a measured native memory/CPU saving.

## Power-cost overlay work and lifecycle

The existing mount path prepares the ghost, cost meter, feedback container and secret-animation groups outside combat. This runs through CreateOverlay, which the actual party factory calls; relying on Initialize alone would miss party bars. Readable non-HUD behavior stays selected by the existing client/feature logic.

Ghost and cost meter remain locally shown with alpha zero. The feedback container also stays shown; its three textures determine visible gain/spend art. Its OnUpdate runs only during readable gain/loss. Engine-owned secret animations need no per-frame Lua callback. Completion, identity reset and disable explicitly park all three textures, including a lingering gain-to-secret overlap.

One pending next-frame ghost commit per bar replaces repeated stale callbacks. The original After(0) boundary remains, including when values are unchanged, so later same-frame AFK color writes are still observed. The 0.6-second cast hold and old-ghost ordering remain. Public values/max/art that were successfully applied skip duplicate native writes; opaque values continue through native sinks without cached equality. False texture-load results, thrown setters and rejected maximum/value writes remain retryable.

Atlas path resolution uses the owned atlas, resolver and client identity/Forever flag. This avoids moving callback savings into repeated Forever path concatenation. Actual layout/animation inputs stay live; no polling interval is increased.

The focused production-module replay passes 168 checks across five client models. Three matched pairs reject twelve harmful controls; three additional appearance/progress comparisons retain identical modeled traces. Native C++ animation behavior and pixels are outside those traces.

| Power overlay replay | Exact checkpoint | Candidate |
| --- | ---: | ---: |
| Queued callbacks for 1,000 same-frame settled paints | 1,000 | 1 |
| Redundant ghost value writes in that burst | 1 | 0 |
| Lua callbacks during 0.5 s of secret-only animation at 240 Hz | 120 | 0 |
| Protected attempts in each HUD lifecycle case | 4 | 0 |
| Protected attempts in each non-HUD lifecycle case | 5 | 0 |

The burst result is not a 1,000-fold FPS claim; separate frames retain their original callback boundary. Preparation adds three helper Frames plus two AnimationGroups/four Alpha animations per enabled bar, including non-HUD clients. Their existing readable paths remain intact; the secret groups remain dormant on clients that do not start them. This moves bounded allocation outside combat and does not establish a memory reduction or zero native overhead.

Cold preparation belongs to the bar, since AdditionalPower is parented to UIParent. Only an explicit Initialize request installs a watcher, preventing a party-only mount or secondary-bar recovery from accidentally attaching player/watch-root events. Cold Initialize intent survives a unit/GUID change; explicit Disable cancels it. The existing internal behavior for a new identity with deliberately omitted value/max arguments is unchanged; actual Shared callers supply both values, and that partial integration contract is outside this correction.

## Integration and validation

A combined replay executes the actual Shared factory → actual overlay mount on the same bar before any paint, then actual spark/pulse/overlay methods for readable and secret effects, completion, reset, disable and re-enable. Three runs of 84 checks across five models pass; two disconnected-factory controls fail. It records zero protected attempts, unsafe arithmetic, combat Frame growth or leftover idle callbacks. Its widgets, animation progress and cast identity are modeled; it does not execute the full native event dispatcher.

The full suite passes **290 scripts and 962 Lua syntax checks**. The documentation validator passes with 995 sources, 607 TOC/XML-reachable files, 427 settings, 24 SavedVariables roots and 16,146 local links. The existing unit-resource/MP5 fixtures now assert effective child art and driver lifecycle instead of treating the container's local Hide state as the visible effect. The artwork smoke executes the renamed current art helper and retains its Retail/Forever/fallback/color/TGA checks.

Full compilation caught the large Shared chunk's 200-local limit; a narrow do/end scope now contains the new preparation helper. The initial failed full result is retained externally. The final full run and both matched comparisons use the corrected source. This is why extracted helper passes alone are insufficient for release validation.

Only two runtime files change in this follow-up. All other runtime owners, including the earlier 23-file optimization pass, remain byte-identical to the checkpoint. The previous power painter and partition correction remain byte-identical within Shared. All 252 appearance/XML/TOC files and 80 options/binding sources are unchanged. Current source identities, exact commands, samples, negative controls, initial/final full results and external checkpoint are retained in the [evidence record](validation/resource-effects-performance-2026-11-10.json).

```text
lua tests/resource_effects_safety.lua
lua tests/power_cost_idle_work.lua
python tests/run_validation.py --output <external-result.json>
python docs/tools/validate_docs.py
```

## Native ownership evidence

The five branch heads were refreshed once for this follow-up and remain the pins recorded in the partition report. The external native bundle contains 88 exact source records / 54 unique Git blobs, independently verified against their Git blob SHA1 identities.

SimpleFrameAPI overrides generic ScriptRegion Show/Hide and marks both protected on every selected client. Generic region declarations alone were incomplete inheritance evidence. Frame alpha and owned texture/animation sinks have distinct contracts; assigning an owned OnUpdate still requires an assignable script and script-binding permission. These declarations guide the implementation but do not establish every permission on a running object.

Retail's native builder/spender container stays locally shown, hides its three texture children, attaches OnUpdate while gain/loss is active and detaches it after completion. [Pinned implementation](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_UnitFrame/Mainline/BuilderSpenderFrame.lua), [pinned template](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_UnitFrame/Mainline/BuilderSpenderFrame.xml). The corresponding files exist at the Forever pin, but its TOC gates those templates to mainline; their presence is not proof that camelot loads them. Flux's Forever recreation therefore has its own native acceptance requirement.

## Native acceptance still required

Reload outside combat and repeat the reported mid-combat invitation with a previously absent party slot. Check current health/resource/text immediately, no new blocked calls, full-resource pulse, readable gain/spend, secret cast completion and final post-combat layout. Exercise identity changes, a hidden parent and feature disable/re-enable. Repeat on Retail, Forever, progression, Era and Anniversary with their existing feature selection; the overlay's readable non-HUD paths remain supported.

Actual operation permissions, first-frame animation appearance, pixels, clipping, controller/input parity and native CPU/memory/FPS remain NOT RUN. These are decorative effects and acquire no input/focus stops. No settings, defaults, bindings, saved data, assets, XML or TOC/load order change is intended. The user-managed synchronization program is not operated by this work.
