# Core services, options and Respec timer audit

This is a read-only audit. [Findings](core_findings.json), [repeated raw results](core-results.json)
and the [fresh baseline](baseline.json) identify the actual consumed source.
No runtime, existing test, TOC, artwork or settings change was issued by this audit.
Independent later unit-frame/PvP edits are recorded in the
[concurrent recheck](concurrent-recheck.json), without replacing the original snapshot.

The current complete suite passes 232 scripts and compiles 896 Lua files. These
passes retain their stated desktop scope; the additional probes below reproduce
behaviors the existing suite does not cover. A successful reproducer exit means
its expected bad observations and controls were verified, not that the addon is
free of faults.

## Timer ownership

[Fresh primary timer contracts](timer-contracts.json) were checked at all four
Gethe pins. `C_Timer.After` declares no return; `NewTimer` is the separate API
that returns an object. A cancellation/pending field assigned from `After`
therefore stays nil. The probe uses that real return contract and a separately
labelled counterfactual handle-return control, without changing production code.

| Finding | Reproduced result | Future work |
|---|---|---|
| R2-CORE-01 | Gear and enabled rune picker enter→leave or explicit Hide before 60 ms still invokes the departed owner's Show request. | Invalidate delayed show/hide ownership; preserve alternatives, mutual picker exclusion, delays and existing combat/capability checks. |
| R2-CORE-02 | A visible attached Restock panel receives 1/10/1,000 refresh requests and runs 1/10/1,000 callback entries. Hidden-panel checks still suppress heavy delivery. | Arm a public pending flag before scheduling, merge valid contexts, and invalidate callbacks on widget/hide/reopen changes. |
| R2-CORE-03 | Await A is cancelled at 4.9 s; B starts; A's old 5 s timeout removes B's event script. B's event at 5.1 s cannot reach the observer, and B later times out. | Cleanup must check the exact watcher/generation it owns. Keep the existing top-level apply-generation checks, which do not prevent the earlier cross-owner cleanup. |

`core_timers.lua.txt` executes contiguous real owner functions with controlled
activity predicates, widget/event leaves and callback sinks. It does not render
the flyouts or perform native talent operations. The rune path is tested only
with `Compat.IsSoD()` enabled; this is not a claim that every target exposes
engraving. The talent await applies only where the Classic talent-group path is
available. The panel uses its actual attachment/visibility predicate.

Forty assertions pass per process across five repeated processes. Existing learn
callbacks additionally reject an obsolete `Talents._state`, so the report does
not infer stale protected work from every `After` assignment. One thousand
scheduled learn callbacks are retained under the nil-handle contract, but the
cancelled-state control performs no continuation calls. Queue cost and actual
native action legality remain separate questions.

The timer assumption also appears in Mount, Status/Info layout, Details resize
and equipment flyout callers covered by the domain reports. These are one
mechanism family, with distinct owner lifetimes and regression requirements;
counting each line as a separate universal defect would overstate the findings.

## Explicit rapid Shift/Ctrl/Alt simulation

The user requested very fast presses and releases of all three modifiers.
`modifier_bus.lua.txt` loads the **complete current Modifier and Context owners**
through the unchanged existing context fixture. It drives actual held-key API
truth independently of duplicate, contradictory and reordered event payloads.

Each process covers:

- All eight held masks and all six modifier release/update orders: 3,840 ordered
  transition cases across five labels and two starting combat states.
- Ten isolated storm configurations, each with more than one million physical
  state edges, 256-edge same-frame bursts plus overlapping holds/releases,
  duplicate notifications and combat entry/exit while keys remain held.
- **10,544,220 physical state edges** and **10,883,400 modifier notifications** in
  total per process. These count repetitions of state transitions, not millions
  of unique gameplay scenarios or real hardware events.
- Correct final release state; at most one context notification per modeled
  frame; no additional modifier driver frames, no timer tail and no captured
  callback errors in the isolated storms.

Five repeated processes pass **96,850 assertions each**, with stable consumed
hashes. The fixture's event/timer/display boundaries remain models; native secure
input, OS handling, true secret values, rendering and FPS are not exercised.
Actual binding, PushPress, EBS and badge consumers are separate supplements.

## R2-CORE-06: mixed mouseover can starve full display context

With an indexed mouseover-dependent program and no unit-frame hover-peek bypass,
when a narrow delayed mouseover request starts first, every later mouseover event
pushes `mouseoverAt` forward. A full modifier/target/combat request widens its
flags but keeps waiting behind that timer. Each of the five current source
models delivers **zero Context notifications over 1,200 frames / 10 modeled
seconds** of combined key/target/mouseover traffic, then one after quiet.

The full target/combat flags survive, distinguishing this from the already fixed
INPUT-001 lost-flag defect. The new problem is unbounded delivery delay while
mouseover continues. A future fix should let a full request supersede or bound
the narrow delay using the existing display scheduler and owned generation.
Narrow-only mouseover throttling must remain bounded and economical.

The active consumer trace is deliberately precise: `Bars/ProgramFace.lua`
subscribes its display translator, including bar overlay and badge face refresh.
Bars Watch skips its conditional refresh when Context owns that subscription;
an unchanged action slot need not invalidate the missing macro display. The
independent Utility modifier subscriber and EBS condition-event flags can
bypass this route. This does **not** establish a whole-addon or secure-click
freeze. The [modifier consumer report](modifier-storm/CONSUMER_REPORT.md) retains the
caller trace and independent raw-event work budgets.

The largest out-of-combat attribute count in that supplement is a forced
unsupported-paging model. Current repaired Forever uses secure paging; do not
promote that fallback count to an ordinary current-client performance diagnosis.
The actual raw-event combat host scan is the remaining current-path candidate.

## Other reviewed core surfaces and limits

The source screen covers every classified Lua/XML file and every selected load
path. The bounded core review inspected the DB bootstrap/recovery roots,
Module eligibility and dependency scheduling, Optional readiness, startup marks,
Timer/Ticker ownership, event mutation, Scheduler/Combat queues, Modifier/Context
and Range lifecycle, the options shell/window setters and Restock panel, and the
Respec include/apply/cancellation flow. Existing current tests exercise prior
queue, default-data, startup and profile contracts. No additional defect is
claimed merely because an arbitrary external callback could throw.

The complete production gear owner and orchestrator expose two further issues
documented separately: [missing-gear false completion and cancelled gear work](core-equipment/REPORT.md).
Native bank withdrawal, item-lock event timing and UI gesture legality are
explicit follow-up gates. No settings file was read or written for these tests.

This review is broader than the four timer/function replays, but does not prove
branch coverage of every option, library or external integration. The source
matrix records that distinction; remaining verification belongs in the roadmap.
