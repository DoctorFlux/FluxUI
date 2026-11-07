# Restricted unit identity and feedback

## Follow-up: badges and unused power snapshots

The next source audit reproduced a separate failure in cooldown-only badge
visibility. Modern cooldown adapters passed restricted timing values through;
BadgeHost converted/compared them to decide whether a badge should appear.
The adapters now retain their existing return positions and append the public
`isOnGCD` flag. Field fallback checks use type-based nil tests so restricted
values are forwarded without boolean tests. Existing consumers use fixed
assignments; no return-count-dependent consumer was found.
The pinned Forever 1.60.1.70790 contracts mark timing restricted while exposing
public cooldown flags: [action API](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/ActionBarFrameDocumentation.lua),
[spell cooldown fields](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellSharedDocumentation.lua).

Readable timings keep the exact existing `duration > 1.5` and `start > 0` rule,
including numeric strings and stale contradictory flags. Only restricted
timings use readable enabled/activity/GCD flags. Unknown restricted state keeps
the badge visible. Slot-or-badge-spell cooldown selection, action attributes,
main/mini swaps, combat alpha, geometry and proc art remain unchanged.

The power audit also proved the old width-snapshot chain unused. It allocated
an anchor and called GetWidth/SetWidth for every power update, but its only
reader was an uncalled local function. Removed that chain and its two Shared
call sites. The live ghost-based spend effect, anchor helper, animations,
preview and AfterPowerApplied bodies are unchanged. The regression exercises
the actual primary Shared updater and secondary callback boundary; full
secondary Shared execution and native rendering remain separate checks.

The two new scripts pass 150 checks and reject 10 faulty mutations. Final
whole-tree validation passes 199 scripts and 861 syntax files with unchanged
source. Five matched pairs per five badge client models retain public results
and ownership counts, with added desktop guard overhead. Four power scenarios
retain all 10,002 value writes/live states while removing one unused frame per
bar and all 10,002 snapshot writes; modeled restricted setter attempts fall
from 10,001 to zero. Native FPS and random-freeze causality are unmeasured.

Verified checkpoint `Unit-secret-followup-20261106T224752Z` preserves 1,683
actual files, 179 available on-disk settings and all-ref history externally.
Five tested runtime files were copied to four existing clients after external
backups; all 20 destination hashes match. No settings or profiling change.

Before this follow-up was installed, background Forever probes observed the
earlier identity fixes loaded, scriptProfile=0 and zero BugTabs errors in two
name-probe samples and a later sample. TacoTip was unloaded; Syndicator and
Baganator were loaded. This accepts those bounded out-of-combat observations,
not combat secrecy or pixels. The user then reloaded and performed ordinary
combat. At23:09:18UTC the new cleanup marker was nil and BugTabs reported0.
A capture showed action cooldowns; target/target-of-target resources and the
owned Threat row. Direct restricted badge cases; swaps; matched pixels/FPS and
other native clients remain pending. Later adapter/owner probes were blocked
before input by the foreground guard. Automatic native Current stays blocked.

Evidence:

- [Matched source, cases and samples](validation/unit-state-followup-comparison-2026-11-06.json)
- [Whole-tree validation](validation/unit-state-followup-safety-2026-11-06.json)
- [Verified client copies](validation/unit-state-followup-client-copy-2026-11-06.json)
- [Native observations](validation/unit-state-native-followup-2026-11-06.json)

Pending independent findings: pet-family/name fallback in stance extras and
existing cast-time/overlay arithmetic probes need their own requirements and
regressions. Do not replace them with guessed identities or disable features.
These findings have not been linked to a native random spike.

## Original identity errors

On 6 November the user reported recurring Forever errors while selecting units,
hovering actions and finishing casts. The 23:16 log repeats the same failures
with TacoTip unloaded. These are FluxUI failures, independent of the separate
TacoTip backdrop report.

| Owner | Existing failure | Intended behavior |
| --- | --- | --- |
| PlayerName | Branch on a secret UnitIsUnit boolean | Use readable identity only; the literal player token remains known |
| ProgramFace | Compare secret unit/channel names with an empty string | Exclude unreadable names from hover fingerprints without changing actions |
| HealthLossOverlay | Compare current/cached secret GUIDs | Cache readable identities and retain feedback through restricted samples |
| PowerCostOverlay | Compare feedback/cast secret GUIDs, including cast finish | Keep readable identity or an owned unit token invalidated by unit changes |

Checks precede comparisons, formatting and arithmetic. Native APIs are unchanged.
Public surname choices and account/character key formats remain intact.
Unknown alias identity cannot select the self-only surname path. Watched frames
retain their existing unresolved-name handling.

Health-loss identity resets use the existing unit-frame events. Parent target,
focus and pet handlers reset affected child feedback before refreshing it;
ordinary health/power/name updates do not reset it. Power-cost identity remains
owned by its existing watcher, which restores a current cast after a unit swap.
Losing GUID readability alone must not discard a health hit or cast completion.

Restricted numbers are forwarded only to existing permitted native display
sinks. Unreadable geometry is not used in Lua arithmetic. The existing hidden
cost-preview fallback remains when its dimensions cannot be read; its native
rendering is unverified. No feedback feature, setting or public cadence is removed.

The source/history checkpoint `Secret-unit-state-20261106T215659Z` preserves
1,674 actual files, all refs and 197 available on-disk settings. Its verified
archives are outside AddOns. Baseline HEAD is
`75cf2bcba83adfea0501934f4eeb2a980c46fdf8`; the baseline is the actual dirty
checkpoint, not a clean historical checkout. Candidate identity is recorded
per file and across the tested Lua corpus.

Desktop regression tests load the actual modules and event-routing fragments.
The four new scripts pass 344 checks and reject 23 faulty mutations. Final full
validation passes 197 scripts and 859 Lua syntax files with unchanged source.
They cover readable/restricted identity transitions, stale caches, cast finish,
target/focus/child/pet resets, disabled overlays, public names and Classic API
absence. Faulty mutations must fail. Sentinel fixtures cannot reproduce native
secret-boolean truthiness, taint provenance, rendering or protected input.

Matched desktop samples record public outputs, API calls, feedback operations
and owned resources. Explicit checks add host timing overhead; these changes
make no native CPU, frame-time, FPS or memory-leak improvement claim. Native
startup, steady-state and combat-burst measurements remain pending.

Five alternating public-workload pairs show the same ProgramFace operation and
resource counts (both host medians 42 ms). The Forever name fixture removes
5,000 redundant self-alias queries per 5,000 cycles while added checks increase
its host median from 52 to 81 ms. The overlay model retains identical work and
resources; host median increases from 29 to 45 ms per 10,000 sample pairs.
These intervals are desktop safety overhead, not native operation latency.

Only the five tested runtime files were copied to four existing client folders;
all 20 destination hashes match after external backups. The verified Forever
window capture succeeded. Its background-only reload guard refused before
sending any input because the game was active, so the new build has no native
acceptance yet. The user's 23:16 errors predate this sync/reload.

Evidence:

- [Full source and validation manifest](validation/unit-state-secret-safety-2026-11-06.json)
- [Matched regressions and samples](validation/unit-state-secret-comparison-2026-11-06.json)
- [Verified client copies](validation/unit-state-secret-client-copy-2026-11-06.json)
- [Native check boundary](validation/unit-state-secret-native-2026-11-06.json)

For native acceptance, reload outside combat after the tested files are synced.
Preserve profiler settings and existing BugTabs history. Test target cycling,
mouse selection, focus changes and target-of-target updates during a normal
fight; cast and channel with resource costs; swap a pet where available.
Confirm names, hover actions, health trails and power feedback remain correct,
then inspect new-session errors for the four paths above. Repeat on Retail,
Era, Anniversary and Classic progression with equivalent options. Compare
matched screenshots and optional captures for both the affected owners and
the complete addon. Do not attribute the earlier random freezes to these
errors without a matched capture.
