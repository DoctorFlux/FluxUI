# PERF-01–04 permanent work-budget regressions

The root owner applied the runtime changes. This follow-up adds only
`tests/performance_work_budgets.lua` and documentation/evidence. The permanent
test passes **697 checks**; three repeated complete runs pass.
[Raw runs and exact normalized source identities](results.json) include four
independent dated-checkpoint baseline rejections and the applied counterparts.

| Finding | Verified work reduction | Preserved controls |
| --- | --- | --- |
| PERF-01 | A 40-member burst of 100 repetitions × seven events produces **one** outstanding OnUpdate arm instead of 28,000. | No synchronous burst paint; all 40 members receive health, power, aura and prediction paints; reentrant dirtiness survives; hidden queued cells stay idle. |
| PERF-02 | After the initial public-state paint, 40 Forever plates over another 600 modeled updates perform **zero** repeated level-art alpha or health/aura structural anchor writes. The old paths would perform 144,000 alpha and 96,000 structural anchor writes. | Initial six artwork fades and four structural anchors per plate; exact health/CC/LOC geometry; prompt native drift repair; existing quarter-second health/name text painting. |
| PERF-03 | After initially hiding both native level frames, 40 live plates over another 600 modeled updates perform **zero** repeated Hide calls instead of 48,000. | Native re-show repairs on the next active update; live health geometry remains untouched. |
| PERF-04 | A hidden character button, including a hidden ancestor, receives **zero** watch callbacks across 600 modeled updates instead of 600. | One watcher per button; visible cadence remains unchanged; press/hold/release, outside presses, panel/keybinding open/close and reappearance still update the plate. |

The Forever budgets above separate structural health/aura anchors from the
health/name text anchors that intentionally keep painting at their established
cadence. They do not claim that all nameplate writes stop. Visible character
button polling also remains intentional: removing it would need a separately
verified native-safe event path that preserves press and panel state cadence.

## Executed code and scope

The raid cases load the full production `FluxRaidCompat.lua` and
`FluxRaidUnit.lua` through the existing `raid_healer_runtime.lua` fixture. Only
the mock widget's SetScript counter is instrumented. Forty combinations cover
five client identities, 0/1/5/40 members and both combat states. The tested paint
queue itself does not depend on dungeon/raid instance APIs. Existing native
header/security acceptance is a separate scope.

The nameplate cases load the **complete production Core module** through the
existing `nameplate_countdown_work.lua` fixture, isolating Countdown so unrelated
text enumeration does not contaminate the style counts. Native objects expose
read-only fields and controlled getter/setter methods; addon field writes fail
the test. Cases cover 0/1/5/40 plates, initial styling, public stable state,
external native drift, options-open exclusion and repair after closing options,
preview exclusion, replacement native regions under the same unit token, and
last-plate removal/driver sleep. Era/Anniversary/progression retain their own
native style policy.

Opaque, missing and throwing native getters preserve the original repeated
repair writes. The opaque sentinel is a Lua surrogate for an unreadable native
value; it does not emulate the true engine secret-number type or secure VM.
This control prevents an optimization from pretending that unknown native state
is known to match. It also shows why native work reduction can differ from the
public-state counts above.

The character case executes the actual bounded `TrackCharacterPress` function
from `FluxChatColumnMicros.lua`. Its mock dispatcher delivers OnUpdate only to
effectively visible frames, including their ancestor chain. It verifies the
owned watch's parent relationship through behavior, without calling protected
Character Info actions or adding native show/close hooks. Full module secure
click handling and pixel parity are not established by this fragment replay.

Current implementation locations:

- `RaidFrame/FluxRaidUnit.lua:555`, `:586`: outstanding paint-arm ownership.
- `NamePlates/Core.lua:613`, `:626`, `:632`: public-point/public-alpha checks with
  the existing unknown-state repair path.
- `NamePlates/Core.lua:836`: skip an already hidden readable native level frame.
- `Other/FluxChatColumnMicros.lua:967`, `:975`: owned character watcher inherits
  the button's native visibility.

## Reproduce

```powershell
lua tests/performance_work_budgets.lua
```

An optional source-root and finding argument runs the same acceptance control
against a frozen source tree, for example:

```powershell
lua tests/performance_work_budgets.lua '<source-root>' PERF-02
```

The evidence extracts four production files from the authorized external
`apply-fixes-20261107T125749Z/source.zip` into an external baseline-control
directory. Every PERF-01/02/03/04 baseline case rejects its original repeated-work
behavior; every applied case passes. Nothing is restored over the live addon.

Existing production controls also pass: raid healer runtime **428** checks with
three rejected negative controls, nameplate Countdown **1,160** checks, and chat
column layout **1,311** checks/four rejected regressions plus **190** reference
alignment checks. The root's combined validation records the complete suite.

## Limits

These are counted operations under deterministic desktop mocks. They establish
neither actual CPU savings/FPS nor native taint safety, secure frame legality,
real secret-value behavior, engine event delivery or rendered parity. No client
input, foreground control, settings changes, profiling or native execution was
performed. Native acceptance remains pending on the four pinned clients in
`Stress test doc/evidence/upstream-pins.json`.
