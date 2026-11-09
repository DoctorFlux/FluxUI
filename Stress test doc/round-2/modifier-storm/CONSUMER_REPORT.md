# Rapid modifier storms — consumer work and ownership

This supplement executes the actual Bars State, SlotMath, Hosts.IndexSlot and
registered Watch modifier callback, plus the complete EBS HotkeyUtil. It changes
only new audit files. Three repeated runs have identical metrics: **4,526
assertions and983,064 consumer-local event dispatches per run**. Raw output and
exact before/after source hashes are in [consumer-results.json](consumer-results.json).
All runtime hashes match the round-2 baseline; consumed source drift is empty.

These are independent consumer scenarios, not a sum of physical keystrokes or a
whole-addon timing measurement. Root's Core Modifier/Context edge matrix,
Binding/click routes and EBS utility/VFX follow-up are separate evidence. No
native client input, secure execution, real secret values, pixels, CPU or FPS
was tested here.

## R2-MOD-01 — raw Bars events perform work before coalescing

**Confirmed production work-count behavior; optimization candidate, not a native
performance diagnosis.** At `Bars/Watch.lua:843`, every raw modifier callback
immediately calls State.IndexLiveSlots in combat. The no-secure-paging fallback
calls State.ApplySlotsInsecure out of combat. These happen before Context and
the scheduler can coalesce display work.

|57-host case,5,120 raw events|Host visits|Attribute reads|SetAttribute calls|Index remove/reinsert operations|
|---|---:|---:|---:|---:|
|Combat, all declared client policies|291,840|875,520|0|291,840|
|Forever no-secure-paging fallback, out of combat|291,840|4,669,440|7,587,840|291,840|
|Secure-paging policies, out of combat|0|0|0|0|

The same counts occur for held-state duplicate events and for an eight-state
Shift/Ctrl/Alt Gray-code sequence. `State.IndexLiveSlots:993` calls the real
Hosts.IndexSlot at117 before testing whether the slot changed. The latter
removes/reinserts even an unchanged host. `State.ApplySlotsInsecure:1039`
unconditionally calls SetAttribute26 times per host per raw event: all three prepared
click sets and the live type/action fields. This figure excludes native keyer
frames and OnAttributeChanged side effects, so it is not a complete native cost.
It counts setter invocations, including identical values; it does not imply that
every invocation changes native state or dispatches an attribute-changed event.

The simulated driver delivers256 events per frame for20 frames, in and out of
combat, with0/1/57 hosts, held duplicates and all eight modifier combinations.
The normal native paging capability is declared for Era/Anniversary/Live and
the fallback capability for Forever; these labels are policy inputs, not runtime
capability captures. Combat attribute writes remain zero. Actual slot-index
membership stays at exactly the number of hosts; this is repeated work, not a
growing slot-index cache.

Downstream paint coalescing still works: each256-event frame makes1,024 paint
requests but retains only four distinct pending paint keys. An optimization
should address the earlier raw work without removing that bounded behavior.

Future options: first skip no-change index removal/reinsertion after proving
that host.slot, widget.action and membership already agree. For the fallback,
separate changed live-face updates from the stable prepared click sets, tracking
the existing layout/page/program generation. Reuse the existing input/display
services where safe. Do not simply postpone every setter: click payloads and
modifier precedence must remain valid for a key press between two events.

Acceptance needs same-frame press/release, Alt-only and simultaneous Shift/Ctrl,
page/form/occupancy changes, slot-program edits, keyer/clickbutton/macros,
combat entry/exit and native OnAttributeChanged effects. Preserve the exact
chord payload, public face/VFX timing, three prepared action sets and current
command/settings behavior. Verify a failed/partial layout can retry. Native
matched profiling is required before claiming an FPS benefit.

## Bounded control — EBS hotkey updates

`ExtraButtonSystem/Shared/HotkeyUtil.lua:446` records the physical modifier state
on every event, then uses a separate boolean to retain one0.05s timer. It does
not depend on After returning a handle.

For30,721 events,60 active dynamic labels and a120-frame/one-second logical
clock, the actual owner performs20 timer flushes,1,200 text writes and10,800
style setter calls. Peak pending timers:1. Owner frames:1. Final release leaves
unprefixed `G` labels, no timer backlog and no pending flag. The same control
passes in and out of combat for all four declared client models;0/1-label
cases also pass. Across all consumer cases per run there are245,760 Bars event
dispatches and737,304 hotkey dispatches.

Repeated style setters could be reviewed separately with measured native data;
this bounded work is not reported as a new timer-leak or correctness finding.
The simulation counts direct label styling calls, not permission to mutate a
particular native FontString during combat.

## R2-CORE-06 — where Context starvation can affect consumers

Root's [actual core replay](../modifier_bus.lua.txt) establishes that continuous
mouseover requests can repeatedly extend the pending deadline while full
modifier/target/combat invalidations wait behind it. The mixed ten-second replay
gets no Context delivery during the storm and one after quiet. This is a
different problem from the earlier fixed loss of invalidation flags: the wider
flags survive but delivery lacks a maximum wait/expedite rule.

The following is a bounded source ownership trace, not a new native visual
error report:

|Consumer|Dependence and remaining bypass|
|---|---|
|Bar SlotProgram/ProgramFace displays|ProgramFace.Start1549 subscribes OnContext1445. That callback bumps the condition stamp and translates indexed strip faces. Watch target/focus/unit-condition handlers return when Context owns display; its modifier handler also skips RequestCond. Same-slot Alt-only macro faces are the clearest affected candidate.|
|Bar VFX and cached shown identity|Effects' OnContextedHop at701 returns while Context owns display. ProgramFace.Shown at1232/ShownForSlot1208 can return a previously published slot identity, or reuse the prior condition-stamped face. Repainting count/hotkey/CD is not proof of a fresh macro translation. Native slot changes can independently translate/rebind a host.|
|Badge column visibility/ownership|OnContext invokes BadgeHost.RefreshDisplays/SyncShownFaces. Those particular column/visibility refreshes wait with Context. This does not prove every badge face is stuck: EBS has an independent badge conditional walk.|
|Ordinary EBS macros|Engine Conditional:OnEvent1301 independently handles modifier/target/focus by frame flags. Its generic/badge conditional paths can translate without Context. Paging-latch gating at992/1021 is a separate qualification; module-managed mount/hearth/portal buttons are skipped in this generic modifier path.|
|Utility slots|Manager.RegisterModifierListener1348 registers directly with FluxModifierTracker; it checks the authoritative chord and refreshes changed entries. These callbacks bypass Core Context and are covered by the peer utility/VFX matrix.|
|Keyboard mouseover watchdog|ProgramFace.NoteMouseoverEvent/ArmMouseoverPoll deliberately suppress parsing while the cursor keeps hopping. It covers quiet/missing-leave behavior, so it does not guarantee delivery during an uninterrupted storm.|
|Unit-frame hover-only SlotProgram|RequestHoverPeek uses its own70ms coalescer and finite hover state. This is a separate route, not evidence that keyboard mouseover or general Context delivery is fresh.|

The relevant preconditions matter: a real indexed keyboard mouseover body must
make ProgramFace.Needs("mouseover") true, Context must own display, and the
tested macro face must not be independently rebound by a native slot/action
change. A representative acceptance setup is one indexed keyboard-mouseover
macro plus a separate unchanged-slot `[mod:alt]` overlay face. Sustain mouseover
events while toggling Alt, target and combat state; bound the full-context delay
and verify the face/column ownership while preserving secure click payloads.
Also test missing/published Identity entries and interrupted versus uninterrupted
sweeps. A whole-addon “stuck modifiers” claim is unsupported because the bypasses
above remain active.

Future Core fix options and the core deadline proof belong to R2-CORE-06 in the
root roadmap. Preserve the intended trailing mouseover parse, but give full
invalidations an expedite or bounded maximum wait; keep wider flags when a
pending operation changes owner. Verify these consumer-visible outcomes after
the bus-level regression passes. No such change is applied here.

Reproduce the supplemental counts with:

```powershell
python 'Stress test doc/round-2/modifier-storm/run_consumer_budgets.py'
```
