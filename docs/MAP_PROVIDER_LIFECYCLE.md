# Battlefield map provider lifecycle — 6 November 2026

Two concrete defects were reproduced: discarded Flux provider clones retained
callbacks/input handlers, and opening Flux's Map tab tainted shared native pin
methods. The candidate fixes ownership and removes the native method rewrite.
This does not establish the cause of the reported random freezes.

The work remains uncommitted on local main. Existing unrelated work is preserved.
Source/history and accessible on-disk settings were checkpointed externally in
`Random-spike-resume-20261106T170042Z` and
`Map-provider-combat-before-20261106T171453Z`. No settings reset was introduced.

## Failure and intended behavior

Flux attaches temporary Blizzard provider clones to its battlefield map. Native
map providers normally outlive these clones. Removing a clone must release every
registration owned by that clone while retaining Blizzard's World Map owners.
The [pinned native canvas](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_MapCanvas/Blizzard_MapCanvas.lua)
calls `OnAdded`/`OnRemoved`; removal does not substitute for the clone's hide lifecycle.
The [native quest provider](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_SharedMapDataProviders/QuestDataProvider.lua)
registers `Supertracking.OnChanged` without releasing it in `UnregisterEvents`.

Previously, repeated attach/detach retained that callback, waypoint toggle
callbacks and canvas/pin input handlers. Queued quest refreshes could still run
against a discarded clone whose map reference remained populated.

The old acquisition guard temporarily assigned no-op methods to shared native
mixins and muted per-pin mouse propagation. Restoring function values did not
restore secure provenance. On Forever 1.60.1 build 70790, a normal `/fw tab Map`
changed three checked shared pin methods and battlefield `AcquirePin` from secure
to `_FluxUI` tainted. Returning to Meter restored the tab, not the taint.
[Native baseline](validation/map-provider-native-baseline-2026-11-06.json).

Native pin acquisition must retain its ordinary mouse-passthrough checks. Those
checks include protected work in the [pinned native provider base](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_MapCanvas/MapCanvas_DataProviderBase.lua).
Flux must defer restricted work belonging to its own clones rather than replacing
global native methods or suppressing the resulting errors.

## Candidate boundaries

Only [FluxBattlefieldMapProviders.lua](../Battlezonemap/FluxBattlefieldMapProviders.lua)
changes at runtime. Detach marks a clone inactive, releases its owned registrations,
clears pending refresh/ping work and runs the ordinary hide/removal lifecycle.
Partial attach failure uses the same cleanup. Stale timers verify owner activity.

The shared mixin no-op mechanism and battlefield `AcquirePin` override are removed.
Clone refresh/ping methods use the existing `Flux.Combat` service when native
protected mouse-passthrough capability is present. One shared deferred job drains
active owners; one owner's reported failure does not discard the remaining work.
Reentrant lockdown retains unfinished owners for the next combat exit.

Delayed bonus-objective callbacks and secret-aware quest refresh timers recheck
combat when they execute. Pending pings retain their latest four arguments and run
after the required refresh, including the existing quarter-second quest throttle.
Older canvases without that protected capability retain immediate combat updates.

All eleven available provider layers remain: quest offers, bonus objectives,
quests, waypoint location, super-tracked waypoints, area POIs, vignettes, flight
points, gossip, dig sites and dungeon entrances. Existing client capability guards,
pin templates, tooltips, map settings and optional Questie routing remain in place.
Actual all-client appearance and interaction parity still require native checks.

## Source identities and desktop evidence

SHA-256 of the actual provider file, in order:

- Original baseline: `94df2a8c65e5cc76b98b0f2f53084f74df498d7dd958c7ccfe3683c329862913`.
- A, detach cleanup: `9a66d5e6c1ff14e377c7948b0340262fb1a67f31f53bf5d37c299b30ce152718`.
- B, clone combat ownership: `3aac4df59ece5b96dde666c2a6f03fa34b211c44eea97ecdbda948ea2bf63578`.

A passes 31 [detach checks](../tests/map_provider_detach.lua); the original fails,
and five deliberate regressions are rejected. Across 1/10/100/1,000 cycles, retained
callbacks and each affected handler grow with cycle count in the baseline and stay
at zero after detach in A. At 1,000 cycles this is 1,000→0 for each affected resource.
The 1,000 stale timers are a separate rapid, fixed-clock event model, not a native
timer count. [Raw A samples and fixture identities](validation/map-provider-detach-comparison-2026-11-06.json).

B passes 36 [combat checks](../tests/map_provider_combat.lua); A fails the ownership
regression, and eight deliberate regressions are rejected. The fixture loads the
actual provider owner and actual Combat service. Callback storms, queued callbacks,
failed refreshes, combat reentry, cancellation and older-canvas behavior are covered.
For the measured workload, both variants acquire 10,110 pins. Shared native method
writes fall from 121,320 to zero; ordinary native checks rise from zero to 10,110.
No provider layer is removed. [Raw B samples](validation/map-provider-combat-comparison-2026-11-06.json).

Each measurement uses ten warm-up cycles/sweeps, 1,000 measured cycles/sweeps and
five alternating pairs. Host `os.clock` medians/ranges in milliseconds are A:
33 [32–34]→31 [30–32], and B: 47 [45–49]→10 [10–12]. These are uncalibrated desktop
intervals with mock native sinks; B restores checks that the old code suppressed.
They do not measure native CPU, allocations, operation latency, frame time or FPS.
Native memory/leak and performance acceptance remain pending.

The frozen complete working tree passes 193 scripts and 855 Lua syntax checks,
with no source drift; corpus SHA-256
`fd41765411f9201d3a49645b88580fed2745b41986af8e0547b99c1283daa1cd`.
[Full result](validation/map-provider-lifecycle-2026-11-06.json).
[Client-copy verification](validation/map-provider-client-copy-2026-11-06.json)
confirms only this changed runtime file reached the configured existing copies.

## Native status and next checks

The candidate was reloaded in background Forever at 17:28:52 UTC; Map content was
observed at 17:30:18 UTC. Post-Map secure metadata and native feature acceptance
are pending; rendering alone does not establish them.
Keep profiling optional and preserve its prior value. Verify fresh provenance,
repeat Map↔Meter/tab toggles, then quest tracking, waypoint clicks/pings, bonus
objectives and available feature layers before/during/after combat. Check error
counts, matched screenshots and repeated timings on each installed client.

The earlier watch's 3,185 ms gap had only 2.2509 ms nearest Flux billing and no
correlated error. Its later twelve map protection errors support this ownership
investigation, not a causal freeze claim. Four later QuickJoin protected-anchor
errors occurred outside that watch and remain a separate lead. Quest-area/focus
hooks also remain a separate lifecycle audit. See [random-spike evidence](RANDOM_SPIKES.md).

## Native candidate result

With Map visible after the candidate reload, the user ran the read-only
provenance/error probe and reported `FXMAP true true 0`. The queried
MapCanvasPinMixin.CheckMouseButtonPassthrough and BattlefieldMapFrame.AcquirePin
fields remain secure; current-session BugTabs errors are zero. This is
user-reported native evidence, distinct from agent-observed screenshots and
desktop fixtures. It does not certify all methods/clients, interactions, combat
recovery, pixels, leaks or random-spike improvement. Profiling was not changed.
[Exact command and scope](validation/map-provider-native-after-2026-11-06.json).
A fresh optional spike watch is requested for remaining unexplained gaps.
