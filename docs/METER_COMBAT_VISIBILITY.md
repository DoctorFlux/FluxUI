# Embedded Blizzard meter combat visibility

5 November 2026: the supplied Forever stack reaches native `SetSessionDuration`
while execution is tainted by FluxUI. This change removes an identified writer
of native visibility state. It does not replace the timer, hide combat totals,
convert secret values or claim that every remaining native boundary is certified.

## Failure and correction

Embedding previously called `SetVisibility(Always)` where present, otherwise
assigned `DamageMeter.visibility = Always` whenever the native field existed.
The pinned Forever meter has no `SetVisibility` method in its meter/Edit Mode
mixins; Edit Mode normally owns that field. Native combat events read it in
`ShouldBeShown`, then `UpdateShownState` dispatches session timers, including the
reported secret-duration comparison. Writing the policy from an addon is an
identified taint source consistent with that stack; the exact running VM state
was not inspected in this batch.

Flux no longer writes the field or calls that setter. Embed, explicit Show and
the existing gamepad host-show path query native `ShouldBeShown` and also retain
the Flux host/tab boundary. An already shown root is left shown, avoiding
redundant addon Show calls. Native events keep their original visibility and
timer dispatch. The existing secure posthook only hides outside the Flux host/tab;
it does not replace native methods or sanitize an earlier native call.

This intentionally restores native visibility options: Always is visible when
allowed; In Combat follows combat; In Group follows group membership; Hidden,
the disabled CVar and unavailable content remain hidden. Flux previously
overrode those choices. No settings reset or permanent setting change occurs.
Native timer formatting, pane selection, layouts, scale, colors, icons, menus,
reset, Details priority and missing-client behavior remain. The explicit combat
Show path is preserved; its native child OnShow/Refresh remains an acceptance
boundary rather than being disabled as a workaround.

## Source and recovery

Baseline main: `72704d19cec2190495acb51d0ab82659e945d71a`. External checkpoint
`Mail-auction-publication-20261105T202207Z` preserves 1,534 actual files, 122
accessible on-disk settings and verified all-ref history. Source ZIP SHA256:
`10f43e0b24068defd30e84f170beeb1ab50537a14f7b4acd70c70296959cb946`.
Unsaved game memory is excluded; archives and settings stay outside AddOns/Git.

Exact runtime SHA256: baseline Git/LF
`ace8215a0e96b7a79ebab01b854c8c5e656f024ed3e7112df04f1a83d62820b3`;
candidate raw bytes
`6e0be242155ca102204982fa39d808f00f7ff7553569e5ca78c329e9ab04e4a4`.
The comparison records the final regression and native-source hashes separately.

Pinned [Forever visibility/timer dispatch](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_DamageMeter/DamageMeter.lua#L197),
[Edit Mode policy ownership](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_EditMode/Shared/EditModeSystemTemplates.lua#L3649)
and [native timer](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.lua#L928)
are the source contracts. Retail uses the separately resolved source commit
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`. These are Forever 1.60.1.70790
and Retail 12.1.5.70783 source versions, not new candidate runtime observations.
Clients without Blizzard's meter retain their existing Details/absent route.

## Desktop evidence

Run `lua tests/native_meter_ownership.lua`. The existing production-module
regression now observes all native-policy writes, including the optional setter,
and covers four visibility policies, combat entry/exit, group changes, disabled/
unavailable state, inactive tabs, hidden hosts, combat reopen and repeated Show.
Its original geometry, styling, pane/control and backend ownership checks remain.

An optional second argument is an external pinned source prefix, for example
`.../forever`. It loads `<prefix>-DamageMeter.lua` and
`<prefix>-DamageMeterSessionWindow.lua` to replay their actual visibility/event
and timer method bodies. The source is not redistributed by the test. Public
APIs, widgets and a plain 65-second session are explicitly mocked. Without that
argument the runner uses its documented ordinary dispatch model.

Five fresh-process baseline/candidate pairs alternate order for each native
Forever and Retail source: candidate 332 checks/zero failures; baseline 332/80
failures. All counts repeat identically. Six semantic mutants are rejected:
restore field write, restore setter, ignore native policy, ignore host/tab,
reenter native timer from addon Show, and issue redundant root Show.
[Raw samples, hashes, variation and host](validation/meter-combat-visibility-comparison-2026-11-05.json).

| Aggregate eight policy/setter fixtures | Baseline | Candidate |
| --- | ---: | ---: |
| Addon policy writes during initial embed | 8 | 0 |
| Optional native setter calls | 4 | 0 |
| Root Show calls in 500 repeated addon Shows per fixture | 4,000 | 0 |
| Native event dispatches | 4,032 | 4,032 |
| Native timer dispatches | 4,032 | 4,032 |
| Native timer FontString writes | 16,096 | 16,096 |

These are correctness/work counts, not CPU, memory bytes, frame time or FPS.
Proxy-observed ownership and ordinary numbers do not emulate taint or secret
values. Whole-harness wall times include startup/assertions. No game input,
foreground, clipboard, profiling or preference changes occurred.

## Native acceptance pending

Reload after sync: removing a disk write cannot remove taint already retained
in the running session. Record loaded candidate/build, addons, settings/profile,
hardware, resolution and UI scale. On Forever and Retail without Details, test
all four native visibility choices and disabled/unavailable states, combat entry/
exit, Meter/other-tab changes and hidden-host reveal while already in combat.
Verify native durations continue updating, entries/source windows/icons/colors
remain intact, and menus/pane changes/reset work at their permitted times.
Compare matched screenshots and optional profiler captures; preserve preferences.
Repeat the existing Details and absent-native-meter paths on other clients.

Native child OnShow/Refresh, geometry and per-session setter boundaries remain
separate taint checks. This batch does not suppress them or establish that each
is faulty. Native secret safety, rendering, pixels and performance remain pending.
