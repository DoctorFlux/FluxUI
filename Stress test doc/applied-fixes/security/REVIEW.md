# Applied SEC-01 / SEC-02 / SEC-03 fixes

Applied on main after the user's “fix everything now” authorization and the
external `apply-fixes-20261107T125749Z` source/history/settings checkpoint.
[Raw results and normalized source identities](results.json) identify the tested
files. The earlier `security/` reports describe the historical audit baseline;
their deliberately defect-reproducing harnesses are not acceptance tests for the
fixed source.

## Behavior changed

| Finding | Applied change | Intentional correction |
| --- | --- | --- |
| SEC-01 | `Core/Engine/Restricted.lua` retains all seven Blizzard driver/watch globals. Fourteen addon caller modules select the existing Flux adapter locally only when its legacy Forever policy is active. | Foreign and unnamed Blizzard/other-addon requests now continue to reach their native APIs. Flux-owned fallback behavior stays local. |
| SEC-02 | Bars, utility assignments and consumable presets propagate their actual results to the profile pipeline. Failures retain the affected section's recovery checkpoint. PresetBundle returns the operation's result rather than the outer `pcall` status. | A thrown, refused or silently unsuccessful requested restore cannot report a completed profile. Combat deferral stays pending. |
| SEC-03 | Deferred bars/utility requests own detached snapshots and completion/state guards. Cancellation, replacement and stale regen callbacks respect that owner. | Editing a saved profile cannot change an already queued restore; cancelling a load stops its queued writes. |

Primary current locations:

- `Core/Engine/Restricted.lua:13`, `:334`, `:393`, `:430`: retained paging entry
  points and local fallback, without global replacement.
- `Respec/FluxRespec_ActionBars.lua:118`, `:379`, `:441`, `:509`, `:520`: readable
  public action state, explicit setter failure handling, pickup and placement
  failure propagation, and post-operation slot checks.
- `Respec/FluxRespec_ActionBars.lua:547`, `:557`, `:566`, `:597`: one pending
  request, detached snapshot, owned cancellation and completion. One reusable
  dormant watcher retains no active event/closure after completion/cancellation.
- `Respec/FluxRespec_Apply.lua:119`, `:728`, `:771`, `:892`: cancel current bars
  work, invalidate utility ownership, and wait/report each requested section.
- `Respec/FluxRespec_PresetBundle.lua:100`, `:248`: propagate actual utility and
  action-bar results/reasons.
- `Respec/FluxRespec_Consumables.lua:29`, `:63`: detect missing/unavailable
  presets, refused/no-op setters and unsuccessful active-preset verification.

The fourteen local driver consumers are Bars State and Pet/Init; Binding
SecurePool and FluxMouseoverKeybind; Core MouseoverCast; RaidFrame FluxRaidLayout;
UnitFrames Shared, ClassPower, Pet, PetTarget, Target, TargetOfTarget and
PlayerTransmogClick; and Salvage Overlay. Shared's alias was coordinated with the
geometry change; the two input aliases were coordinated with the input owner.

## Preserved behavior

The restricted snippet capability policy, owned fallback's combat guard,
out-of-combat visibility reconciliation, parser throttle and repaired native
paging probe remain intact. Other clients bind to the original native functions
directly. No new global driver wrapper or global hook is installed.

Classic still restores only differing action slots. Public controls restore
spells, items, macros, equipment sets, mounts, companions, battle pets and empty
slots while preserving stance order, hidden flags and custom entries.
Retail/Forever still leave Blizzard loadout-owned action slots untouched and
restore Flux stance data only. Requested stance restoration now waits for combat
to end, so the profile cannot finish while protected layout work is pending.
Saved data, section switches and the already-matching fast path remain intact.

For stance data, completion means the existing saved-state setters and layout
request accepted the restore. `Stance.RequestLayout` retains its established
deferred UI cadence; this change adds no visual-layout acknowledgement framework.
The desktop tests cannot certify that later native frame layout.

A failure after some valid earlier slot/stance writes is not rolled back. The
load reports failure and retains the bars checkpoint so a retry can restore the
remaining differences. This preserves legitimate completed work and avoids a
second set of protected writes masquerading as a transaction.

The follow-up result audit reproduced the same false-success pattern in utility
and consumables before changing those paths. An enabled section with captured
data is requested work: missing/invalid/unavailable data or a false API result
now fails with its `spellbook` or `consumables` checkpoint. Disabled sections and
uncaptured sections retain their existing skip behavior. Consumables keep their
one early successful switch, skip the matched late step, and validate a needed
late switch independently. A failed early switch stops before parallel setup.

Utility combat deferral uses the existing named `Combat.Defer` service and a
detached snapshot tied to the current Apply state. Cancellation clears that
state's snapshot/callback; a retained old combat callback becomes a no-op and
cannot affect a replacement profile. No utility queue framework, utility-slot
implementation change or new event frame was added.

## Acceptance evidence

`lua tests/restricted_driver_ownership.lua` passes **264 checks** in five client
models. It executes the complete production adapter and actual caller alias
declarations. It checks all seven native global identities, foreign/unnamed
pass-through, owned fallback visibility/watch lifecycle, no protected fallback
writes in combat, empty-driver sleep and the repaired paging probe/native path.
It does not pretend to execute all fourteen consumers' UI construction.

`lua tests/respec_actionbar_completion.lua` passes **320 checks** in Era,
Anniversary, progression Classic, live and Forever models. It executes the full
production ActionBars owner, Apply orchestrator and PresetBundle modules. Cases
cover stance errors/false returns; pickup throw/false/no-op; placement throw/no-op;
read/clear failures; deferred completion; mutable nested profiles; cancellation;
spurious regen while still in combat; stale callbacks; supersession; reentrant
replacement; and ordinary feature controls. Five thousand supersessions across
the five models retain one watcher per module and complete only the latest
pending snapshot successfully. Later combat cycles reuse the dormant frame.

The same acceptance cases reject six isolated behaviors in the dated checkpoint:
native global replacement, false profile completion, false result swallowed by
PresetBundle, premature deferred completion, mutable queued snapshot, and
post-cancel writes. Each applied variant passes. Baseline files were read from
the external checkpoint archive into an external control folder.

`lua tests/respec_section_results.lua` adds **200 checks** across the five client
models, executing full production Compat, Includes, Assign, Combat, Consumables,
PresetBundle and Apply modules. It covers utility combat wait/completion,
cancellation/replacement, detached nested data, legacy `spellBookSlots`, invalid
or unavailable/refused/throwing utility APIs, consumables missing/unavailable/
refused/no-op/throw results, late-stage failures, matching cadence, and disabled/
uncaptured optional sections. [Section raw results](section-results.json) retain
the three independent pre-fix production rejects and passing applied controls.

The raid fixtures now supply native driver functions before module loading,
matching the real client lifetime and preserving local native identity capture.
Their existing allocation/readiness assertions remain, with added identity
controls: header precreation **1,160** checks, startup **2,080** assertions pass.

Existing binding/Respec regression (**110** checks), idle-bars regression (**153**
checks / **7** rejected mutations), core smoke and bars smoke also pass. The bars
smoke includes bars refresh (**17,454** checks / **19** rejected mutations), bars
contract (**468** checks / **13** rejected mutations), and native script ownership
(**26** checks / **6** rejected mutations). The root validation records the full
combined suite and current complete-source manifest.

## Limits and client source provenance

These are deterministic desktop Lua tests of production control flow with public
API/frame mocks. They establish neither native taint safety nor hardware input,
secure snippets, engine secret values, rendering parity or client FPS. Native
acceptance stays pending, including interaction with other addons/native driver
managers and real combat/regen transitions. No game input, foreground control,
WTF changes or profiling preferences were used.

The four upstream identities are recorded in
`Stress test doc/evidence/upstream-pins.json`: Forever
`9dc84f0d3bbae1768ac3405b3716000bd93eda06` (1.60.1.70862), live
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (12.1.5.70783), Era
`4192ac60067fc55566182291bc67c85dd9b6794d` (1.15.9.70576), Anniversary
`68e0a2ec559d9761dfc4e7f864c3944f9d758a49` (2.5.6.70577). The native secure driver
functions belong to `Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua`;
no change to those implementations is required or claimed here.
