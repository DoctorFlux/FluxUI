# Scenario coverage and limits

The canonical suite runs each existing script once, exactly as checked in the
current working folder. Its 222 results mix production-code fixtures, native Lua
source replays and static contract assertions. A pass is scoped to that script's
model. It is not a run of the whole addon inside four complete client emulators.

The complete TOC/XML graph has 598 reachable paths and no missing references.
[SOURCE_COVERAGE.csv](SOURCE_COVERAGE.csv) keeps every selected/excluded path for
each requested client. Era/Anniversary select 583 paths each, Retail 584 and
Forever 582. Capability/dependency checks can narrow actual execution further.
575 of the union paths are Lua. All 885 existing Lua files, including libraries,
inactive code and tests, compile in desktop Lua 5.4.6; WoW's modified Lua/security
environment differs. All 24 SavedVariable declarations remain unchanged.

314 reachable paths have a literal reference in an existing test; 284 have none.
This is a discovery index: indirect loading may exercise an unmentioned source,
and a mention can be only a text assertion. No statement/branch-coverage percentage
is claimed. Every module is inventoried, but every branch/integration combination
is not dynamically covered. The source inventory and review matrix identify the
remaining surfaces for later work.

| Scenario family | Evidence here | Boundary |
|---|---|---|
| Login/reload/readiness/late dependencies | Existing startup, optional, capability, retry, settings and migration fixtures | Full client login/SavedVariables disk persistence not executed |
| Shift/Ctrl and overlapping chords | New saturated Modifier/Context stress; all eight utility chords; press/release and both key-down settings | Native event delivery, actual hardware edges and secure VM remain unverified |
| Rapid target/mouseover changes | Native-source modern mouseover helper; legacy prepared snippets; reaction/missing target routes; invalidation interleavings | Real secret values, forbidden native frame hierarchy and pixels remain unverified |
| Combat entry/exit/reentry | Existing guards, new Combat queue stress, utility and mouseover combat flags, cancelled Respec operation | Lua mocks trap selected writes; true protected-state propagation and native taint are not emulated |
| Solo/party/raid scaling | New raid replay uses 0/1/5/40 owners, four client parameter sets, combat/OOC and world/dungeon/raid labels: 96 rows | Unit dispatcher consumes group size/combat inputs; zone labels do not introduce native instance rules |
| Dense raid health/power/aura/threat/prediction/range churn | Production dispatcher burst/scaling plus existing healer/secure/header/marker/party/aura fixtures | Full mixed healer UI + all integration callbacks is not one integrated emulation |
| Instance transitions | Existing lifecycle/retry and prepared header/layout fixtures; zone labels retained in scale replay | Loading screens, native roster delivery and dungeon/raid C-side restrictions remain NOT RUN |
| Real instance-type Lua branches | Full Binding Conditions module across six instance types, zone/spec gates and actual modeled zone events; full MountFlyable helper across type/map/API/continent/settle paths | Exercises real Lua decisions; does not grant native secure actions or reproduce server-side instance rules |
| Spell/item/macros/pet/stance/vehicles/possession | Existing focused fixtures and utility/legacy-input stress | All classes/spells/macros/protected actions are not exhaustively enumerated |
| Inventory/auction/mail/restock/loot | Existing publication/query/cold-cache/visible-row/late-item/close/cleanup fixtures; sustained auction replay | Network/server throttle, item pickup/merchant permissions and actual server latency remain unmodeled |
| Native bank/Baganator/Questie/Details/SAO/ConsolePort | Existing matching feature fixtures, source review and dependency gates | Real enabled-addon load order and native callback provenance remain pending |
| Maps/meters/chat/nameplates/Character Info/window mover | Existing lifecycle/layout/source-ownership fixtures; new stable-frame work counters | Native rendering/secure geometry/FPS and every option combination remain pending |
| Disabled and hidden features | Existing idle/disabled tests, new modifier detach and polling/driver inventories | Permanent posthooks/native animation costs require native observation |
| Empty/missing/restricted data | Existing secret guard fixtures and public unavailable-GUID input stress | Tables/tokens do not emulate native opaque values or taint provenance |
| Respec interruption/failure/cancellation | New production orchestrator/action-owner failure/defer/cancel experiments | Demonstrates result/ownership defects; does not establish the native denial's cause |
| Reported native outgoing-fade taint | USER-001: exact user Forever error retained; pinned source/caller trace and arithmetic-sensitive desktop reproduction | Agent did not reproduce in game; actual frame/action and first taint provenance remain unconfirmed |
| Long session/cache cleanup | High-volume teardown/coalescing/provider snapshots and existing retention/pruning tests | No multi-hour native heap/GC leak certification |
| Guild-bank/void-storage callbacks | Existing files inventoried; no new callback experiment or changes | Remain outside the renewed callback scope under repository instructions |

For every requested client, native combat/OOC, dungeon/world, raid/world, taint,
rendering and matched performance acceptance are **NOT RUN**, by the explicit
simulation-only request. Running these later requires an exact client/build,
addons/options and repeatable scene, with the user's background-input constraint
preserved. Do not fill those cells with a simulator pass.

Future coverage should prioritize the reproduced findings and their callers,
then dynamic coverage of the unreferenced/indirect paths, integration load-order
permutations, same-frame mixed events, and native-only boundary checks if requested.
No runtime fix or feature change is part of this audit.
