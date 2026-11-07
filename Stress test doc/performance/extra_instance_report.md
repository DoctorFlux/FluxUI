# Actual instance/geography branch extension — 7 November 2026

This extension executes the complete, unchanged
[Inventory/MountFlyable.lua](../../Inventory/MountFlyable.lua) with explicit
synthetic API returns. It closes a narrow gap in the raid scaling replay: the
raid unit-paint module ignores instance type, while this production helper
actually branches on `GetInstanceInfo` and `IsInInstance`.

Run from the repository root:

```powershell
python 'Stress test doc/performance/extra_instance_mount.py'
```

[Results](extra_instance_results.json) contain five successful runs with identical
counts and no source-hash drift. **Per run:** 136 geography/restriction scenarios,
eight transition/settle cases, 80,000 rapid world/dungeon transitions and 81,043
expectations. **Across five runs:** 720 case executions, 400,000 rapid transitions
and 405,215 expectations. These are additional to the main performance audit's
20-process totals; they are not included in that earlier report.

The four client models are Era, TBC Anniversary, Retail live and Forever. Their
flags follow the current client implementation: Anniversary is TBC; Forever is
Retail-family for this helper, with an early-version build. Each model is tested
with the IsFlyableArea capability present and absent. The absent-API cases on
modern clients are defensive fallback tests, not a claim about installed API
availability. The exact source hashes of MountFlyable, Client and Capabilities
are retained in the results.

## Actual production decisions exercised

| Scenario group | Independent expected behavior verified |
|---|---|
| Outland world | Era never prefers flying bag items; eligible other clients can. |
| Indoor Outland | The no-API geographic fallback rejects flying indoors; a positive native flyable API remains authoritative on its API path. |
| Native no-fly Outland | The API path rejects flying. The API-absent fallback has no native no-fly signal and follows its geographic/riding rules instead. |
| Missing riding skill | Bag-item flying preference rejects it. Journal-style `PreferFlying` remains a geography/native flyable preference, rather than an overall usability test. |
| Eastern Kingdoms | TBC bag-item preference rejects flying outside Outland; modern native-flyable preference can be positive. |
| Northrend / missing Cold Weather Flying | TBC rejects flying outside Outland; API-absent modern fallback requires Cold Weather Flying. |
| Wintergrasp no-fly | Both the negative native signal and the fallback Wintergrasp exclusion reject flying. |
| Map-parent fallback | A synthetic child map whose parent is the production Outland map constant resolves to Outland when the world context permits parent walking. |
| Dungeon / raid / PvP / arena / scenario | Every actual restricted instance type rejects bag-item flying preference, and does not follow an Outland-looking map/zone fallback into a false continent match. |
| Restricted instance type with stale world map ID | The type restriction itself remains effective; it is not accidentally accepted only because of a synthetic non-world map ID. |
| IsInInstance true with unknown type/world map ID | The independent IsInInstance restriction branch remains effective. |
| Unknown positive instance map ID | The current whitelist conservatively treats it as restricted for this bag-item helper. This does not prove modern journal mounts are unusable there. |

The native API fixture signature follows the production calls: `GetInstanceInfo`
returns the instance type in position 2 and map ID in position 8. Synthetic
location names and non-world map IDs are fixture values, not claimed real
dungeon or raid identities. The tests do not emulate encounter mechanics.

## Transition and stale-state checks

Each client/capability pair alternates Outland world and a restricted dungeon
10,000 times through `CanPreferFlyingMountItem`. The correct current geography
is used on each call; no old flying preference survives a dungeon transition.

The actual location-settle implementation is also executed. The first changed
sample stays unsettled; one stable sample before the minimum time stays
unsettled; two stable polls after at least 0.25 seconds finish early. The
API-absent fallback conservatively refuses flying while settling. A following
raid transition changes the real location key, resets stable sampling and
rejects flying immediately. The settle deadline remains bounded.

## What this does not claim

This source file has no functions named `IsMountableArea` or
`CanUseFlyingMount`; no such APIs were invented for the test. Its actual public
functions tested here are `IsInMountRestrictedInstance`, `IsOutlandContinent`,
`IsNorthrendContinent`, `CanPreferFlyingMountItem`, `PreferFlying`, the location
key function and the location-settle protocol.

Dead, swimming and combat flags are supplied and varied, and counted native
API stubs receive **zero calls** from this helper. This confirms its limited
ownership of geography and icon/item preference. It does not certify that a
mount can execute while dead, swimming, in combat, indoors or inside any
particular instance. Actual mount execution, native macro evaluation, protected
input, real client restrictions, secure value semantics, taint and FPS remain
outside this desktop helper test.

No new addon defect was established by this extension. API/native-flyable paths
and geographic fallbacks intentionally have different contracts. Any future
optimization must preserve those differences, instance restriction precedence,
the stable-poll/minimum-time settle protocol and conservative behavior while
native location data changes. Actual instance execution still requires the
separately tracked native acceptance checks.
