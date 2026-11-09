# Input stress results — 7 November 2026

These tests execute the current addon Lua, with the existing standalone fixtures and local Gethe Blizzard Lua where indicated. This audit did not modify addon code/existing tests, write settings/profiler preferences, or control the game. Other activity during the audit is recorded separately in [preservation evidence](../evidence/preservation.json). Harnesses use `.lua.txt` so they do not change the canonical `*.lua` inventory.

Run from the addon root:

```powershell
python 'Stress test doc/input/run_input_stress.py'
```

The runner continues after findings, retains three repetitions and raw logs, checks harness syntax, and records byte hashes before and after. See [machine results](input-stress-results.json). Every repetition is deterministic in assertion counts, work counters and observed failures. Desktop wall times are recorded only to diagnose the test runner; they are not addon CPU, FPS or frame-time measurements.

| Harness | Production exercised | Volume per repetition | Result per repetition |
|---|---|---|---|
| `context_stress.lua.txt` | Full `Modifier.lua` and `Context.lua` | 690,090 delivered modeled events; 500 saturated frames per each of five client labels, each containing 256 modifier events; duplicate events, partial/reversed releases, detach, reaction transitions and unavailable GUIDs | 7,605 assertions; 15 failed expectations reproduce INPUT-001 |
| `secure_input_stress.lua.txt` | Existing utility input fixture plus production click FX, secure pool/chord map, EBS action, assignment and manager; five local Blizzard secure dispatchers/slash handlers | 61,440 press/release pairs; 20,480 selected chords; mouse and both assigned keys; all eight chords; both key-down preferences and combat states | 197,024 assertions pass |
| `mouseover_target_stress.lua.txt` | Full production mouseover module plus actual local Blizzard native mouseover target helper and control mixin | 131,072 rapid selection steps on Retail/Forever; 64 combinations of mouseover existence, friendly/hostile, helpful/harmful, held modifier, native setting and left/right button, both combat states | 262,534 assertions pass |
| `legacy_mouseover_stress.lua.txt` | Full production mouseover module; actual prepared PreClick/PostClick strings | 294,912 snippet pairs for Era/Anniversary/progression; six host types; both combat states; target/mouseover presence; held modifier; left/right/middle/conjure buttons | 1,179,804 assertions pass |
| `hover_children_stress.lua.txt` | Unmodified production hover-scan function slice, using vararg `GetChildren` | Six targeted cases per model; five client labels; modern-focus, parent-hover and no-hover controls | 30 assertions; 15 failed expectations reproduce INPUT-002 |

Each repetition has 1,646,997 assertions, including 30 failed expectations for the two documented issues. Across three repetitions that is 4,940,991 assertions and 90 repeatable failed expectations. A failing assertion here remains a reported addon issue; the runner's `FINDING` classification does not convert it to a pass. `ERROR` is reserved for unexpected failures or fixture problems.

The three repetitions repeat the same scenario definitions; they do not triple the unique scenario count. Totals across all repetitions are 2,070,270 modeled events, 184,320 utility press/release pairs, 393,216 native mouseover selection steps and 884,736 legacy snippet pairs. These are different workload units and should not be added together as unique scenarios. The evidence window is 11:21:56–11:22:39 UTC on 7 November 2026; before/after source hashes match, all five harness syntax checks pass and there are zero unexpected runner errors.

The `classic` progression model is additional coverage. It is not substituted for Classic Era or Anniversary. The core-context and hover-scan modules are client-independent code exercised under five labels; this does not constitute five native client runs. The mouseover native tests use capability configurations matching Retail/Forever; legacy tests explicitly use the fallback capability route for Era/Anniversary/progression.

## INPUT-001 — pending full context invalidation can be narrowed to mouseover only

**Reproduced functional bug; medium priority.** In `Core/Engine/Context.lua:362`, `RequestMouseover()` sets `refreshMouseoverOnly=true` before checking whether a refresh is already queued. If a target, modifier or combat event first requests a full refresh, and `UPDATE_MOUSEOVER_UNIT` arrives before that callback drains, the pending work becomes mouseover-only. At `Context.lua:186`, `DiffKinds()` then clears the `target`, `mods` and `combat` flags despite their fingerprint changes. `DoRefresh()` also accepts the new fingerprint, so an identical subsequent request can be skipped.

Reproduction: initialize/flush the production bus; change target and fire `PLAYER_TARGET_CHANGED`; change mouseover reaction and fire `UPDATE_MOUSEOVER_UNIT`; drain the timer/display tier. The subscriber receives `mouseoverOnly=true`, `target=false`. Repeat with a modifier event plus its frame callback, or `PLAYER_REGEN_DISABLED`: `mods`/`combat` is also false. Reversing each event order preserves the wider flag and passes.

This matters to `Bars/ProgramFace.lua:1410` (`ContextKinds`) and `:1445` (`OnContext`): kind-selective refresh can omit a surface requiring the lost modifier/target/combat kind. This harness proves signal loss, not a native stale-pixel reproduction or an incorrect secure action. Other native events/pollers may refresh a surface independently. Existing utility secure action selection passed its stress cases.

Future fix: merge queued invalidation kinds monotonically. Once any full-context request is pending, a later mouseover request must not narrow it. Preserve the existing shared scheduler, mouseover coalescing interval, feature behavior and event ownership. Regression acceptance: all permutations of mouseover/target/modifier/combat requests before drain deliver the union of changed kinds; include repeated requests, forced refresh, form bursts, unit-frame peek and teardown. Retain the current one-delivery-per-burst/no-extra-driver budgets. No fix has been applied.

## INPUT-002 — hover child fallback reads only the first vararg as an array

**Reproduced fallback bug; medium priority, reachability depends on client capability/state.** `Binding/Input/FluxMouseoverKeybind.lua:1822` does `local ok, children = pcall(f.GetChildren, f)`, then iterates `children` as an array. `GetChildren()` returns separate child frames. The first child is assigned to `children`, later return values are discarded, and no child-frame list is traversed. In desktop fixtures that first frame is a table without numeric children, so the loop is empty; a native frame is also not the returned array assumed by this code.

With `GetMouseFoci()` returning a descendant whose `IsDescendantOf()` succeeds, the modern control passes. With the focus API absent or throwing, hovering either immediate child while the parent itself is not reported hovered returns false. Parent-hover and no-hover controls pass. This is not evidence that any current target always lacks `GetMouseFoci`; the failure is limited to the fallback, or to modern focus results that cannot establish descendant membership.

The current Forever generated declaration confirms a strided `SimpleFrame` return, with hierarchy secrecy metadata: [Gethe, commit 9dc84f0d3bbae1768ac3405b3716000bd93eda06](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua#L323). The parent [source pin record](../evidence/upstream-pins.json) separates this declaration from runtime availability and operation.

Future fix: collect or consume all successful vararg child returns safely, respecting forbidden/hierarchy restrictions and existing bounded traversal. Preserve the 0.05-second hover-context cache and the working modern-focus route. Regression acceptance: zero/one/multiple children, hovered first/last child, missing/erroring focus API, descendant focus, hidden/forbidden owners/children, multiple registered frames and combat state. Use bounded/reusable scratch storage if collection is necessary so the corrected fallback does not allocate an unbounded list each scan. No fix has been applied.

## Future fix and regression index

| Finding | Future change | Feature/cost constraint | Acceptance |
|---|---|---|---|
| INPUT-001 | Preserve the union of queued context kinds; never narrow a pending full refresh | Keep modifier actions, cadence, shared scheduler, mouseover debounce, form narrowing, peek routing and detach behavior | Every target/modifier/combat/mouseover event ordering retains changed kinds, one delivery per saturated burst, no extra frame/timer owner |
| INPUT-002 | Consume the complete vararg child sequence safely | Keep modern focus route, hierarchy restrictions, bounded traversal and 0.05-second context cache; avoid unbounded scratch allocation | First/last hovered child works with absent/erroring focus API; modern descendant, parent-hover and empty/no-hover controls still pass; native hierarchy restrictions checked separately |

## Audited source identities

The following byte SHA-256 values identify the precise source used. The complete before/after manifest and fixture hashes are in [results](input-stress-results.json); the compact list is also [CSV](source-identities.csv).

| Module | Byte SHA-256 |
|---|---|
| `Core/Engine/Modifier.lua` | `f546dd7e98f541af680722b5ea54da2762445ac03f30d6ef7f6059c776cbad1b` |
| `Core/Engine/Context.lua` | `67b4063ebd6c71ef2724dd8d4a19bf30480a40320475240da832e79e3f112ef7` |
| `Core/Engine/MouseoverCast.lua` | `c7cce425aa459a8bd4334b16f5a9e027c2d3d3d97c6723161245468abee5cac8` |
| `Binding/Input/FluxMouseoverKeybind.lua` | `74c5614f71f18e14e3d050a12691a3ff2c725b325928d2c73e333784754314cb` |
| `Bars/ProgramFace.lua` | `40d7bc0133f68f38cace6a464503ca2d98185f1df96b4be3b279cfa4528cf4a1` |
| `ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua` | `3b14c0156cc6e8d4446078e0b8c906f56239b7fe3818dc6256791cb7c2ec8dd9` |

## Limits and remaining checks

There is no Blizzard secure VM here. The legacy snippet harness explicitly marks its execution as modeled secure context so prepared snippets may write their temporary attributes; this cannot establish native permission, provenance or taint propagation. Unknown GUIDs use the production accessor's public unavailable result; Lua values do not emulate native secrets. Native input timing, key-repeat delivery, target filters, taint, pixels, allocations, garbage collection and real performance remain unverified.

The shared input bus does not consume dungeon/raid membership APIs. Labeling its identical state as a raid would add no group coverage; the parent scenario matrix and raid/unit/performance work hold that coverage separately. This input report does not claim raid-frame or dungeon-event validation from its input counts.

An additional [instance-gate report](instance-gates-report.md) now executes the complete binding Conditions module against actual open-world/dungeon/raid/PvP/arena/scenario inputs. It passes 37,905 assertions per repetition in three repetitions, separate from the earlier five-harness totals. This checks instance-dependent load branches, zone notifications and the boundary between Lua load gates and compiled combat/modifier tokens; integrated dungeon/raid secure lifecycle remains pending.

Local Blizzard fixture paths and byte hashes are retained in the results. They are the source actually executed by the existing fixtures, distinct from the task's fresh remote branch pins. Historical fixture content is not silently relabeled as the latest client build. No log contains a new settings dump or an archive from AddOns.
