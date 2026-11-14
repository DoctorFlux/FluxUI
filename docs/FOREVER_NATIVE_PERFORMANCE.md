# Forever native party/raid performance follow-up — 9 November 2026

REQ-RF-99 follows REQ-RF-97/98 and the user's request for background in-game
simulation when real roster/combat changes could not be reproduced. The selected
route was the actual Forever client, using explicitly authorized diagnostic
`/run`/reload input to its verified background window. No foreground activation,
global input, clipboard control or gameplay automation was used. Witchcraft was
not connected. The helper refuses input whenever Forever is foreground.

Native client: Forever 1.60.1, build70862, interface16001, PID49960, verified
`F:/World of Warcraft/_forever_/Wow.exe`. Legacy `scriptProfile=0`, `taintLog=2`,
solo and outside combat throughout simulation. Native `C_AddOnProfiler` was
enabled independently of legacy script profiling. Source presence, modeled
permission checks and native operation results remain separate evidence.

## Observations and fixes

`RESOURCE-PULSE-SECRET-GEOMETRY-20261109`: the retained native taint log had eleven
secret-geometry arithmetic errors at old Shared.lua:1441 during approximately
two seconds. `UpdateFullResourcePulse` now uses its existing public finite-number
validator before calculating full-bar geometry. Public power/geometry still
supports the pulse; unreadable geometry does not guess a full bar. No new poll,
frame, event, setting or cadence.185 focused checks, three candidate repetitions,
baseline rejection and16272 resource-lifecycle checks pass. Post-reload solo/OOC
logging contained no actual blocked operations; this does not reproduce the
restricted-combat trigger or prove it absent during combat.

`VENDOR-INPUT-PERMISSIONS-20261109`: the reported repair-toggle initialization
called protected mouse-propagation methods without a permission check. The
existing checkbox factory now checks combat and the optional native
`C_RestrictedActions.CheckAllowProtectedFunctions(toggle,true)` contract before
either setter. Denied/opaque/query-error results leave checkbox defaults intact;
combat retries use the existing keyed combat queue. Later attachments retry
initialization, and settled toggles do not rewrite flags. There are no new drivers,
and no protected setter is hidden inside error suppression.285 focused checks,
three old-reject/new-pass pairs and four harmful controls pass. Legacy no-query
initialization remains OOC-only. Native merchant interaction and combat acceptance
are pending: the verified window was foreground at final preflight, so no input
was sent. Reload outside combat before checking the new code.

The older DebuffTint.lua:146 `GetVertexColor` report predates the already-installed
forbidden-reader correction. All five installed copies match and contain no such
reader;17050 tint checks pass. Do not reintroduce private color extraction to
color numeric text. Restricted numeric text capability remains as documented in
[the debuff combat audit](UNITFRAME_DEBUFF_COMBAT.md).

## Actual-client simulation

Existing nonsecure raid/party previews were exercised through
`C_AddOnProfiler.MeasureCall`. Group/combat APIs and secure header state were not
replaced or forced. Each row is one native measurement, not a matched optimization
comparison. Cold construction costs belong to preview pools; live secure frames
are prepared outside combat and use a different roster path.

| Preview operation | Elapsed ms | Allocated bytes |
| --- | ---: | ---: |
| First40-member raid |196.1003 |3405545 |
| Warm40-member raid |11.1176 |438592 |
|10 members |4.6555 |131128 |
|20 members |7.2995 |233616 |
|40 members |13.3116 |438592 |
| Column move |1.0121 |2122 |
|40-member reflow |15.0475 |438592 |
| First player-style party |25.3566 |1300767 |
| Warm party |4.8791 |383968 |
| Hide |0.1340 |0 |
| Return to party |4.6818 |384640 |

A20.001-second solo/background pilot recorded20 native profiler samples,
0.343504ms recent-average Flux time,145.017 average FPS and72.137 minimum FPS.
This is a contextual native observation, not grouped acceptance or an FPS gain.
Later scene/UI/reload changes invalidate a comparison with later readings. No
reproducible grouped lag spike was captured, so no additional roster optimization
is justified from these samples alone.

## Recovery and remaining acceptance

An intervening reload cleared the temporary `FluxPartyPerfBackup` table. My
unguarded readback/cleanup commands then caused the reported18:07 diagnostic nil
errors. These were diagnostic mistakes, not production group-frame failures.
External diagnostic commands now guard missing state. Earlier screenshots retain
the timings. Temporary globals were cleared, previews hidden, original preview
fields restored, and capture/watch stopped. Original `FluxPerfCaptureDB` from
6 November16:25:27 was recovered from the verified external pre-test backup and
persisted through reload: all3843 compared values match. Legacy profiling remains0.
Private recovery payloads/settings/screenshots stay outside AddOns and Git.

Actual mid-combat joins/leaves, party/raid conversions, subgroup changes, merchant
checkbox interaction, protected input and combat taint are **NOT RUN** for this
native follow-up. The user's requested in-game simulation cannot establish these
server-driven states. Prior desktop secure-state replay remains useful evidence
with its stated limitations. No universal taint-free or full optimization claim.

## Checkpoints and pinned evidence

External artifacts under the authorized visualizations root:
`forever-party-live-20261109T163017Z` (source/history checkpoint and native results)
and `vendor-input-checkpoint-20261109T171808Z` (2475 source files, all-ref bundle,
43 settings metadata entries, before/candidate controls). No manual client sync,
publication, feature removal or settings reset. Existing sync delivered matching
installed debuff copies.

Ten exact Git blobs verify the restricted-actions and mouse-method contracts for:

| Client | Gethe/wow-ui-source commit |
| --- | --- |
| Retail12.1.5.70783 |297d7aaaa736f346b3e036f38ee088eaf7f8c07f |
| Forever1.60.1.70862 |9dc84f0d3bbae1768ac3405b3716000bd93eda06 |
| Progression5.5.4.70631 |e5d9b3a22c3f0f6f41ebac0e454f4969594261cf |
| Era1.15.9.70576 |4192ac60067fc55566182291bc67c85dd9b6794d |
| Anniversary2.5.6.70577 |68e0a2ec559d9761dfc4e7f864c3944f9d758a49 |

The current Forever generated definitions mark both propagation setters protected
and restricted. Declaration evidence is not proof of availability or permission
in every execution context. Runtime probes are optional and permission checks
remain conservative. See [public evidence](validation/forever-native-performance-2026-11-09.json)
for exact identities, numeric results, cleanup scope and final validation.

## Native continuation — 17:40 UTC

A later background readback confirms build1.60.1, solo/OOC, legacy profiling0
and zero BugTabs session errors. All three existing repair/guild-repair/junk
toggles report `fluxInputConfigured=true`. This verifies current native startup
initialization; merchant clicks and combat permission transitions remain untested.
Party diagnostics v7 reports ready/secure, solo, a shown prepared dock and four
hidden member buttons. No gameplay, settings/profiler writes or runtime changes
were performed in this continuation.

The user explicitly answered that a real test party/raid with combat roster
changes is **not available now**. Remaining live acceptance is therefore pending
that external scenario. No further idle/preview replay can prove those changes.
The first audit left the goal active. After three consecutive goal turns with
the same unavailable-scenario blocker, the goal is blocked pending a real test
party/raid and user-triggered combat roster changes. The second turn revalidated
the actual client through read-only capture; no native profiling job remains
active. Repeating idle/preview tests cannot satisfy the missing acceptance.
The preceding goal turn made progress through concrete fixes and regression
validation. Native screenshot/hash/readback is in the public evidence summary;
private screenshot files remain external.


## User-requested pause — 19:27 Copenhagen

9 November 19:27 Copenhagen — USER PAUSED live party/raid work.
Temporary native recorder stopped; FXPAUSED true true confirms original report
restored and recorder finished; probe/setup/last globals cleared; profiling0.
New shared fix is installed and loaded (raid-units), but candidate combat retest
has NOT RUN. Baseline native capture proved a defect: IsInRaid=true in combat
while native group:raid parsed party; raid-unit existence correctly parsed raid.
Player-style party remained visible. Both APIs reported secure. Fix uses native
roster-token drivers on EVERY client, covering40raid slots and party/pets/targets/
optional raid pets. No new production events/timers/frames. Full278scripts and
948syntax PASS;53615focused checks/2800combat transitions;baseline rejected,
3candidate repeats and4harmful controls. External2484-source/history checkpoint,
all baseline84rows and callback/gap screenshots, comparison and full reports:
forever-group-live-20261109T174833Z under the authorized visualizations root.
See its PAUSED.json. Source changes: FluxRaidSecure.lua/FluxRaidHealerExtras.lua;
new tests raid_group_conversion_conditions.lua and support/group_condition_parser.lua;
existing secure/party/combat/extras fixtures now parse actual clauses. Baseline
409.277s had12frame gaps (peak1231ms) and20slow callbacks; includes loading/scene
changes, so not all are Flux/group cost. Candidate only solo/OOC before pause.
Resume: native bidirectional conversion/roster retest, inspect exported baseline
rows/spikes, finish affected docs/ledgers/reference freshness. Foreground targeted
diagnostics were explicitly allowed for THIS test; default background rule remains.
