# Very fast Shift/Ctrl/Alt consumer simulation

This supplements the frozen six-group action/binding audit. It changes no addon,
test, TOC or settings file. [The harness](modifier-spam.lua.txt) executes current
complete production ChordMap, PushPress, Bars.Clicks, Combat and SlotMath modules
through the existing counted widget fixture. [Two complete raw runs and consumed
source hashes](modifier-results.json) remain available for replay.

Each run completes **1,938,260 assertions** across **8,640 scenarios**. Both runs
reproduce the existing **R2-BIND-01** release-ownership defect in all 8,640 cases;
they add no separate finding ID. The explicit owner clear recovers every case.

| Per-run measure | Result |
| --- | ---: |
| Modifier payload deliveries | 1,399,680 |
| Physical modifier-state update attempts | 466,560 |
| Derived actual modifier transitions | 267,840 |
| Chord/route checks against physical truth | 933,120 |
| Consumer callback deliveries | 2,819,520 |
| Action-key downs / ups | 17,280 / 17,280 |
| Mouseover-context event deliveries | 8,640 |
| Regen event deliveries | 5,760 |
| Modeled OnUpdate/timer tick steps | 760,320 |
| Protected-write attempts while locked | 0 |
| Maximum coalesced deferred bar jobs | 3 |
| Queued owner work after final cleanup | 0 |
| Orphaned press visuals before explicit cleanup | 8,640 cases |

The update-attempt count includes repeated assignments of already-held/released
states. Actual transitions are derived from the fixed mask schedule: each
scenario produces `28 + 2*popcount(initialMask)` changes, averaging 31 across all
eight initial masks. Thus 198,720 attempts per run intentionally keep the same
physical state while still delivering duplicate/misleading event payloads.

The matrix combines five client identities, both supplied CVar values, all eight
held Shift/Ctrl/Alt combinations, all six modifier release permutations,
forward/reverse/fixed-seed-random action-key release, same-frame/across-frame
steps, and OOC/combat/regen windows. Both action keys overlap while modifier
states repeatedly sweep all eight combinations. It also alternates whether the
production hover watcher sees a unit-frame mouse context.

Each physical state update delivers the expected payload, a duplicate, and a
contradictory/reordered payload for another modifier. The current production
consumer queries `IsKeyDown`/modifier getters for truth. Actual ChordMap routes
remain correct for the tested public letter keys: bare, Shift and Ctrl reach
their current main/mini slot; Alt or Shift+Ctrl retain the free route. This
does not repair or conceal the separately reproduced literal-minus parser bug.

Bar click/registration requests are deliberately queued during combat to test
their real coalesced ownership and regen path alongside the modifier stream.
Spies reject attribute/override/registration/parent mutations while locked.
The zero attempted locked writes are a result for those mocked API calls, not
native taint certification. Legal OOC/regen work performs 69,336 attribute writes
and 30 override writes per run.

The same fixture is reused through 864 scenarios per client/CVar case. Ordinary
models retain nine frames/three hooks; Forever retains eleven frames/five hooks
because its current policy creates two key proxies. Neither count grows across
the matrix. All supplied timer and deferred queues drain after release, regen
and explicit cleanup. Those stable resources coexist with the visual orphan;
stable counts do not establish correct ownership.

Zero-delay reassert work varies with the existing hover/chord selection:

| Raw sample | Callbacks scheduled | Peak pending callbacks |
| --- | ---: | ---: |
| 1 | 111,863 | 26 |
| 2 | 90,230 | 22 |

The source uses unordered watched-chord iteration and several held combinations
can satisfy its press-visual selector. That is a source-based explanation to
investigate for this variation, not a measured native timing conclusion. Future
R2-BIND-01 work should coalesce the reassert kick while preserving simultaneous
held-key feedback, immediate press paint and the original settle/grace/cap
behavior. Native CPU/FPS savings have not been measured.

The replay covers press visuals, chord routing, generated bar override setup,
coalesced registration deferral and cleanup. The ButtonFX secure-click wrapper
is a policy stub in this fixture; native action bodies, actual CVar edge dispatch,
secure hardware execution and pixels are not executed here. Existing canonical
secure-input/native-source replays remain separate controls, including their
actual production click wrappers. Badge/EBS consumer work is reported separately
by the other round-2 agents. True secret values and protected-engine behavior
remain native acceptance tasks.

## Additional capability-qualified control

`state-keyer.lua.txt` reuses the complete Forever control fixture and its native
Lua source handlers. Repaired secure paging correctly keeps an unmodified main
key on slot 1 when only tertiary slot 25 has a macro overlay. Directly invoking
the insecure fallback API afterward can stamp the shared proxy from the
tertiary row. The current modifier watcher gates that call behind unsupported
secure paging. This lead is **not promoted to an ordinary current-client
finding**; it belongs in future fallback-capability validation. Native compiler
availability and engine execution remain unverified by this control.
