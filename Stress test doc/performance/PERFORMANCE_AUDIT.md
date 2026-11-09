# Performance and lifecycle stress audit — 7 November 2026

This is a test record and future-work proposal. This audit issued no addon runtime,
TOC, existing-test, saved-settings, game, profiler or input writes. All audit output
files are confined to this folder and are absent from the addon load list. Source
or settings changes made outside this audit are tracked in the root preservation
record separately.

The current snapshot has several concrete opportunities to reduce repeated work.
Two shared-service edge cases also produce lost or skipped callbacks in desktop
replays. Those edge cases are service-contract findings; an ordinary gameplay
trigger has not been established. No native CPU, FPS, allocation, taint or pixel
acceptance is inferred from these results.

## Reproduction and evidence

From the addon repository root:

```powershell
python 'Stress test doc/performance/run_performance.py'
```

The runner reads the existing TOC/XML graph and uses the existing source tokenizer.
It executes four standalone Lua files, each five times. The `.lua.txt` extension
keeps these additional harnesses out of the existing recursive Lua corpus checks.
The harnesses load unchanged production modules, or explicitly bounded source
slices. Native widgets, client events, clocks, secrets and rendering are modeled.

- [performance-results.json](performance-results.json): all 20 processes passed;
  all recorded operation counts match across five repetitions; no hash drift in
  the 575 reachable Lua files during the run.
- [source-inventory.json](source-inventory.json): exact raw source hashes and load
  graph scope; [driver-sites.csv](driver-sites.csv) records 2,747 candidate sites
  across 26 top-level module groups; [module-summary.csv](module-summary.csv)
  aggregates them. These are lexical candidates, including detach sites and
  bundled libraries, not active-driver counts. Indirect calls, aliases, calls
  through `pcall`, native animations and dependency code outside the addon can be
  missed. The configured load graph covers more game types than the four targets.
- [stress_services.lua.txt](stress_services.lua.txt): 18 cases, 10,024 expectations
  per repetition, including explicit confirmations of the two observed anomalies.
- [stress_raid_scaling.lua.txt](stress_raid_scaling.lua.txt): 96 scenarios, 1,680
  expectations, 772,800 delivered events and 1,104 health-bar paints per repetition.
- [stress_hotloops.lua.txt](stress_hotloops.lua.txt): 17 cases and 34 expectations
  per repetition, measuring stable nameplate geometry and the character watcher.
- [stress_auction_sustained.lua.txt](stress_auction_sustained.lua.txt): eight cases,
  32 expectations and 1,600 sustained event steps per repetition.

Across all five repetitions this adds 695 case executions and 58,850 explicit
expectations, including 3,864,000 modeled raid-unit event deliveries. An
expectation is an assertion about the stated mock contract, not a unique native
behavior. Two anomaly reproductions are expected observations, so the process
exit status remains successful while the findings stay open.

The initial raid harness incorrectly equated health API queries with bar paints;
the real status text and health bar query health separately. The corrected harness
counts `StatusBar:SetValue` writes and records health queries separately. This
was a harness expectation correction, not an addon defect or runtime change.

## Findings for later changes

| ID | Current observation | Evidence level / priority | Feature-preserving direction |
|---|---|---|---|
| PERF-01 | Every raid paint event reassigns the same OnUpdate function. A 40-unit, 100-repeat, seven-event burst makes 28,000 mock `SetScript` arm calls, then paints 40 bars. | Production dispatcher replay; medium optimization candidate. [RaidUnit:580-585](../../RaidFrame/FluxRaidUnit.lua#L580). | Arm on the transition from no scheduled flush to scheduled flush. Keep the next-frame category merge and accept events arriving during a flush. |
| PERF-02 | Stable Forever nameplates repeatedly write level artwork alpha and health/aura anchors every frame. Forty plates over 600 modeled frames produce 144,000 `SetAlpha`, 103,400 `SetPoint`, and 5,920 `ClearAllPoints` calls. | Production source-slice replay; high investigation priority, native cost unknown. [Core:610](../../NamePlates/Core.lua#L610), [652](../../NamePlates/Core.lua#L652), [783](../../NamePlates/Core.lua#L783). | Preserve exact art/positions. Cache only public style/layout inputs or owned revision flags, repaint on real native layout changes, and bound any repair burst. Verify native provenance before selecting hooks. |
| PERF-03 | Stable Retail nameplates repeatedly call `Hide` on two native level frames. Forty plates over 600 modeled frames make 48,000 Hide calls. | Production source-slice replay; medium optimization candidate. [Core:810-831](../../NamePlates/Core.lua#L810). | Suppress levels at the verified lifecycle/refresh boundary, with an appropriately bounded repair mechanism if native code restores them. Keep instant correct visibility and preview/options exclusions. |
| PERF-04 | Forever's character microbutton watch polls each frame while idle. At 60 modeled frames/s, ten minutes gives 36,000 mouse/panel queries and zero appearance paints. Another ten minutes with its button hidden still gives 36,000 watch callbacks and IsShown reads. | Production source-slice replay; low-to-medium idle-cost candidate. [ChatColumnMicros:967-984](../../Other/FluxChatColumnMicros.lua#L967). | Stop the watch when the visible button is hidden; wake for press/release and panel state transitions using a provenance-safe path. Preserve secure native Character Info opening, plate down-state and right-click behavior. |
| PERF-05 | Callback-bearing scheduler requests do not coalesce by token. 10,000 display callbacks run in one tier flush; 10,000 inventory callbacks take 1,250 flushes. The latter copies 6,245,000 leftover references according to the exact executed queue lengths and source copy loop. | Production shared-service replay plus exact operation-count model; medium service-hardening priority. [Scheduler:105-115](../../Core/Engine/Scheduler.lua#L105), [223-264](../../Core/Engine/Scheduler.lua#L223). | Use a head cursor instead of repeatedly copying the remaining queue. Introduce explicit keyed replacement only for idempotent refresh jobs; retain distinct callback semantics and ordering elsewhere. Add budget/fairness without delaying urgent input work. |
| PERF-06 | Continuous mouseover updates suppress all shared range sweeps until the cursor is quiet. The replay stamps 101,000 mouseover events, observes zero sweeps during 1,000 consecutive storm frames, then one sweep after a quiet interval. | Production shared-service replay; intentional current policy with a freshness tradeoff. [Range:316-321](../../Core/Engine/Range.lua#L316). | If stale tint is unacceptable, bound maximum staleness while retaining cached identities and cheap distance probes. Keep item-range restrictions, no invalid world-hover fanout, and prompt final settle. |
| PERF-07 | A sustained builtin AH event stream can keep the published snapshot stale until quiet while repeatedly discarding staged work. At 20 modeled events/s for ten seconds, changed lists of 32 and 1,024 rows publish zero times during the stream, perform 381/375 native row reads, then publish the coherent final list after quiet. | Complete production auction scanner replay; liveness/latency tradeoff, not a partial-publication bug. [Auctions:134](../../Inventory/Builtin/Auctions.lua#L134), [194-206](../../Inventory/Builtin/Auctions.lua#L194). | Investigate duplicate-event coalescing and an explicit max-age/retry policy without publishing mixed generations. Genuine index-shifting updates must still invalidate the staged snapshot. Retain provider handoff, close cancellation, row/time budgets and complete-list atomicity. |
| LOGIC-01 | During an inventory flush with more than eight queued callbacks, a running callback queues a fresh request/token. The leftover assignment overwrites that newly pending bucket: nine old callbacks run, the fresh callback runs zero times, and its token never reaches listeners. | Reproduced service edge case; medium correctness priority, no verified ordinary addon path. [Scheduler:259](../../Core/Engine/Scheduler.lua#L259). | Merge old leftovers with the independently pending new bucket, preserving original-before-new ordering and both token/reason sets. Do not replace distinct callbacks with last-writer semantics. |
| LOGIC-02 | If event handler A unregisters itself while the bus iterates `[A,B,C]`, `table.remove` shifts B into the consumed index. A and C run, B is skipped for that dispatch. | Reproduced service edge case; medium correctness priority, no verified ordinary addon trigger. [Events:116](../../Core/Engine/Events.lua#L116), [174](../../Core/Engine/Events.lua#L174). | Define mutation semantics, then use dispatch-depth/tombstones with later compaction, or a stable per-dispatch view. Do not introduce a per-event full allocation if avoidable. |

The existing Syndicator auction refresh caller has an `auctionsPending` latch
([Adapter:500-510](../../Inventory/Syndicator/Adapter.lua#L500)). The 10,000
inventory-callback backlog is therefore a hostile service workload, not evidence
that ordinary auction events currently create that backlog. Similarly, current
Context unsubscription is a possible consumer of Events.Unregister, but a
gameplay chain causing self-removal from inside that event has not been proved.

Both service anomalies were observed using a stronger exactly-once delivery
expectation than the code explicitly documents. Confirm intended API semantics
before treating them as user-facing defects; retain the reproduction regardless.

## Required regression work when fixes are authorized

1. **PERF-01:** prove one scheduled arm per burst, unchanged category counts,
   nested event delivery during flush, hide/rebind cancellation, and no paint of
   old units. Cover zero/one/five/forty members, combat transitions and secret
   value display sinks. Keep next-frame cadence and raid/party appearance.
2. **PERF-02/03:** repeat 0/1/5/40 plates in all four clients, options open/closed,
   preview, plate reuse, name-only mode, classic/modern health art, native style
   changes, combat entry/exit, scaling, cast/CC/LoC geometry and delayed native
   writes. Compare actual screenshots and native taint traces separately.
3. **PERF-04:** show/hide, secure child mouse down/up, press then hide, native
   CharacterFrame keybind opening/closing, right-click repair, combat and
   gamepad behavior. Do not move addon callbacks into an unsafe native secure
   close path to save a small polling cost.
4. **PERF-05/LOGIC-01:** retain every distinct callback and token, fresh requests
   from callbacks and listeners, more than eight callbacks, high/low priority
   fairness, empty queues and error isolation. Measure queue-copy count and
   latency, not just successful eventual completion.
5. **PERF-06:** sustained hover/gap storms, enemy/friend swaps, explicit
   `@mouseover`, target-only spells, detarget, restricted friendly-item range,
   no-range results, invalid/secret values and a final stable frame. Establish an
   acceptable maximum visual staleness before changing suppression policy.
6. **PERF-07:** 0/32/1,024/10,000 rows, duplicated events versus true list changes,
   sale/removal/index shift during a scan, native getter reentry, AH close,
   Syndicator Ready/handoff, absent provider, stale callbacks and a missing-row
   retry. Preserve final counts, links/quality/auction identity, publication
   atomicity and existing native query ownership.
7. **LOGIC-02:** self-removal, remove earlier/later handler, remove all, add a new
   handler during dispatch, nested same-event dispatch and callback errors. Define
   which additions/removals affect the current delivery, then assert it explicitly.

## Existing safeguards retained and limitations

- Scheduler token-only work coalesces 10,000 identical requests to one listener
  call and one initial timer. Ticker replaces 100,000 identical keys without
  growth, visits the survivor after self-removal, and runs zero callbacks during
  10,000 idle frames after all subscribers are removed.
- All 30,000 callbacks in the event error-isolation replay run despite 10,000
  deliberately injected callback errors. Those injected errors are not addon
  failures found in ordinary scenarios.
- Structural work remains deferred during modeled combat. The replay retains
  one combat wakeup for 10,000 callbacks, then executes them after regen. This
  is an unbudgeted burst, not a native lag measurement; see the separate security
  audit's deferred-queue finding before planning the shared fix.
- The raid-unit dispatcher scales linearly with members and coalesces health,
  power, aura, prediction, threat and range bursts. Hidden cells release events
  and cancel queued paints. Aura/prediction/BigDebuffs painter bodies are mocked
  in this particular scaling fixture; the main suite has separate subsystem tests.
- Raid scale axes are four client models, 0/1/5/40 members, combat/OOC, and
  world/dungeon/raid. The unit module does not branch on instance context, so
  those world/dungeon/raid rows are repeated API-context probes, not instance
  mechanics or encounter simulations. Real headers, secure action execution,
  server restrictions, private auras and raid-instance taint are unverified here.
- Builtin auction scans retain their at-most-32 row and modeled one-ms budget.
  The fixture's synthetic per-call costs made the observed maximum 26 rows, and
  its quiet-settle delays were 0.08/0.88 simulated seconds for 32/1,024 rows.
  These are fixture-clock results, not real client latency or CPU time.
- Existing inventory heavy listeners have a two-job/1.5-ms source budget and a
  0.6-second maximum debounce window. Native auction and mailbox scanners are
  resumable and do not publish partial lists. Their timing caps can be exceeded
  by a single slow callback/getter; native worst-case cost remains to measure.
- Ordinary unit health/power polling keeps its 0.2-second health and 0.5-second
  threat cadence and timer-driven/idle-disarming ownership. Main-suite idle and
  resource lifecycle tests remain the primary functional evidence for that code.
- WindowMover's panel observer polls at 10 Hz while enabled to avoid native
  secure-script provenance. Current `WindowMover.Refresh` explicitly hides it
  when disabled ([Engine:938-943](../../WindowMover/Engine.lua#L938)); no disabled
  watcher leak is claimed. Native safe ownership takes priority over replacing
  that observer with a speculative native hook.
- Native threat panes stop work on hide and out of combat; minimap enforcer
  tickers are bounded bursts; map/provider, mail, vendor, options, respec,
  currencies, salvage, bags and dependencies have source-site coverage here and
  scenario coverage in the main runner. Source inventory is not executable
  coverage or evidence that every callback in those modules was exercised.
- Guild-bank and void-storage callback changes remain deferred. This task makes
  no changes to them or to any other runtime module.

Future optimization acceptance needs matched native baseline/candidate captures
with exact client build, source, profile, enabled modules, group size, encounter,
hardware and restored profiler preferences. Investigate observed repeat work
first; do not claim an FPS gain from lower desktop mock counts alone.
