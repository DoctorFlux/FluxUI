# Actual instance-dependent binding coverage

The supplementary [harness](instance_gates.lua.txt) executes the complete current `Binding/Core/Conditions.lua`. Its private `InstanceTypeMatches()` is exercised through the public `SubPassesLoadGates()` API and the `IsActive()` wrapper. There is no current function named `SubEntryMeetsLoadConditions` in this module.

This closes a specific gap left by putting a dungeon/raid label on an otherwise identical input-bus test: production code here actually consumes `IsInInstance()`'s boolean/type and branches on the result. It does not establish integrated raid-frame, dungeon loading, protected binding application or native secure-macro behavior.

Run from the addon root:

```powershell
lua 'Stress test doc/input/instance_gates.lua.txt'
```

[Machine evidence](instance-gates-results.json) and `instance-gates-run-1.txt` through `instance-gates-run-3.txt` retain three identical repetitions. All pass; there are no new findings. This audit did not modify addon code/existing tests, write settings/profiler preferences or control the game.

| Coverage | Evidence per repetition |
|---|---|
| Actual instance values | Open world (`false,"none"`), dungeon (`true,"party"`), raid (`true,"raid"`), battleground (`true,"pvp"`), arena (`true,"arena"`), scenario (`true,"scenario"`) |
| Instance settings | Selected/unselected; positive/negated; uppercase/lowercase; six supported type tokens plus unknown token; absent desired value defaults to `NONE` |
| Load/active behavior | `SubPassesLoadGates()` and `IsActive()` agree on the actual instance gate result; `never` and absent configuration controls |
| Zone/spec composition | Main-zone match, subzone match, wrong zone and empty desired zone; combination with instance gate; specialization match/mismatch/negation using modern or legacy getter configurations |
| Rapid transitions | 12,480 modeled `ZONE_CHANGED_NEW_AREA` events reach the real production handler and notify the binding owner 12,480 times; event-frame count stays at two |
| Combat/modifier distinction | Each instance/load setting combination is reevaluated across combat/out-of-combat and none/Shift/Ctrl/Shift+Ctrl physical state; Lua load gate never reads those state functions; generated `combat`, `nocombat`, `mod:shift`, `mod:ctrl`, `mod:alt` tokens retain the chosen configuration |
| Pet non-escalation control | Unrelated unit pet event is ignored; player pet event invalidates its catalog gate without a load-gate notification |

There are **37,905 assertions**, **12,480 instance-gate evaluations** and **12,480 modeled zone-event deliveries per repetition**, all passing. Across three repetitions: **113,715 assertions**, **37,440 gate evaluations** and **37,440 zone-event deliveries**. Repetitions reuse the same scenario definitions and do not multiply unique coverage. These counts are separate from the earlier five-harness/15-run input report.

The main matrix contains 6 actual instance values × 13 desired strings × 2 selected states × 2 negated states × 2 combat states × 4 modifier states × 5 client-model labels = 12,480 evaluations. Additional assertions check zone/spec composition, absent/never gates and token semantics. The five labels include the four requested targets and additional Classic progression; shared Conditions code runs under each explicit API configuration. Labels do not represent native client launches. Scenario type is tested as an API input; its actual availability in a given target client is not inferred.

Combat and modifiers are deliberately represented as macro condition tokens, as the production file's contract requires. This test verifies those strings and verifies that physical flips do not turn into Lua load-gate polling. It does **not** execute Blizzard's native macro parser or prove secure dispatch/application during combat. `ZONE_CHANGED_NEW_AREA` registration and notification execute against model frames; native event validity, delivery timing and actual binding-owner deferral remain outside this test.

Production byte SHA-256 before and after: `6403b5c3e587b542b40b69a11ac57b859a22d0180a3b65e33fd2ee3c258cc661`. All three outputs are identical and the standalone harness passes `luac -p`. The raw logs and JSON retain the exact harness hash. No timing claim is made. The separate performance audit owns `MountFlyable.lua` restriction/geography coverage; it is not counted here.
