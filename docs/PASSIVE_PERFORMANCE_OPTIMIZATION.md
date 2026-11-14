# Passive performance optimization

All 24 candidates in the [10 November audit](PASSIVE_PERFORMANCE_AUDIT_2026-11-10.md) received an optimization pass. Three matched before/after pairs cover each workstream. The changes preserve existing nominal intervals, frame-synchronous animation, input policies, options and saved-data roots.

**The simulations show less repeated work with matching tested behavior. They do not measure recovered WoW FPS or certify native pixels, input or taint safety.** Native reset checks needed to preserve appearance remain at their original cadence.

The later [resource-effects follow-up](RESOURCE_EFFECTS_PERFORMANCE.md) adds ghost-callback coalescing, active-only secret feedback ownership, guarded spark geometry and prepared combat helpers. Its 290-script current validation supersedes the older run counts below; the original 24-candidate results remain historical evidence for their stated workloads.

[Additional passive pass 2](PASSIVE_PERFORMANCE_PASS2.md) covers ten more hotspots across eight runtime owners. Its 295-script/967-syntax result is the latest full validation; all preceding runtime owners outside those eight remain byte-preserved.

## Measured differences

These are separate synthetic workloads. Counts and percentages must not be summed into an overall CPU/FPS saving. Plain native API/widget stubs run under Lua 5.4; host wall time is diagnostic only.

| Workload | Baseline | Candidate | Preservation evidence |
| --- | ---: | ---: | --- |
| Rank identity checks; 100 calls; 40 members+pets | 321,500 | 5,200 | Same 8000 detailed queries and ranks; GUID fallback retained |
| Rank identity checks; 100 calls; 40 members; no pets | 80,700 | 2,600 | Same 4000 detailed queries and ranks |
| Forever plate lookups; 40 plates/144 FPS/60 s+reset probes | 388,121 | 40 | Same immediate native reset repair |
| Retail plate lookups; same workload | 378,401 | 40 | Same every-frame level suppression |
| Forever Settings visibility checks; same workload | 363,963 | 8,643 | One check per batch; same open/close recovery |
| Forever settled label/font writes; same workload | 111,600 / 9,640 | 0 / 0 | Readable labels/styles reused; secret and failed sinks retry |
| Forever anchor writes; same workload | 111,602 | 6 | Includes identical rebind/reset probes |
| Frames created; 1000 add/remove cycles; Retail / Forever | 1,004 / 2,004 | 5 / 6 | Released overlays reused; four initial countdown hosts included |
| Hover dispatches; 60 s/240 FPS | 14,400 | 1,200 | Same nominal 50 ms fallback |
| Spellbook OnUpdate calls; 10 s/240 FPS | 2,400 | 0 | Same 96 polls and callback-time trace |
| Compatibility OnUpdate calls; 10 s/240 FPS | 2,400 | 6 | Same 51 parses and every-frame visibility trace |
| Cast timing reads; 10 animated widgets/720 frames | 7,201 | 2,161 | Same progress/geometry trace; direct refresh stays fresh |
| Cast parent / level setters; same workload | 7,201 / 7,201 | 10 / 50 | Native reset repaired on same frame |
| Owned channel color writes; same workload+failed sink | 4,320 | 8 | Exact color/opacity; next-frame retry |
| Classic fill anchor / color writes; 720 frames | 720 / 720 | 0 / 0 | Same progress; actual transfer/clear/reuse tested |
| Explicit full-aura rebuild requests; 500 matching events/2 engines | 1,000 | 0 | Native incremental owner retained; explicit rebind refreshes unchanged |
| Unbound trinket watcher dispatches | 1,000 | 0 | Press/release/binding wake retained |
| Stable stance aura text formatting | 1,000 | 1 | Native digit sinks still reconcile each frame |
| Stable loot alpha writes | 3,000 | 3 | Same stable duration; per-frame fade/expiry |
| LFG dispatches during 100 visible texture steps | 400 | 100 | Same 100 steps; hidden phase and timerless recovery |
| Details targettarget fallback probes | 4,000 | 12 | Same due/event/target/combat policy |
| Questie setters; 100 updates | 6,700 | 2,700 | Fresh text-height measurement and native ordering |
| Native threat sample tables / settled style writes | 500 / 3,000 | 5 / 0 | Same fresh values; identity/style invalidation |
| Mail captures; five 50-item unchanged rescans | 250 | 0 | Same 4250 native reads; sparse slots/metadata preserved |
| Old provider index visits; 100 unchanged 1000-row snapshots | 100,000 | 0 | All 100000 provider rows still validated |
| Whole bag-count map visits / dirty-row allocations; 100 updates | 40,000 / 4,000 | 0 / 100 | Immediate facts/moves/notification merge retained |
| Heavy queue callbacks; 20 listeners | 22 | 10 | Same first 50 ms paint; max 2/frame; 0.6 smaxwait |
| Filtered summary key parses; 1000+1000 rows | 2,000 | 1,000 | Excluded character stays pending |
| Repeated summary key parses; 20 x 1000 unchanged rows | 20,000 | 0 | In-place link/itemID edits invalidate cache |

The plate scenario uses four constant aura labels/plate, public values, positive threat, options closed and quest overlay disabled. The rank scenario is separate. Native aura delivery in the core fixture is modeled; actual client registration/delivery remains a native acceptance check.

## Coverage of every candidate

| Audit ID | Current owner | Optimization | Work deliberately retained |
| --- | --- | --- | --- |
| RPF-01 | [NamePlates/Core.lua](../NamePlates/Core.lua) | Lifecycle-cache native plate identities; share settings/client checks in existing batch | Original per-frame alpha/anchor reads and repair |
| RPF-02 | [NamePlates/Core.lua](../NamePlates/Core.lua) | Use lifecycle plate cache for Retail level suppression | Original every-frame visibility checks |
| RPF-03 | [Core/API/Threat.lua](../Core/API/Threat.lua) | Deduplicate public GUID aliases; retain exact original sort | Fresh detailed threat; ties and unknown/secret GUID walk |
| RPF-04 | [NamePlates/Countdown.lua](../NamePlates/Countdown.lua) | Cache readable owned labels/anchors/levels; deduplicate aura-item visits | Original 0.1 s reads; native digit suppression; secret/error retry |
| RPF-05 | [NamePlates/Level.lua](../NamePlates/Level.lua) | Cache owned font/text/fit/attachment | Original 0.25 s metadata/color recovery; unreliable metrics retry |
| RPF-06 | [NamePlates/Threat.lua](../NamePlates/Threat.lua) | Pool detached threat and level hosts | Complete unit/attachment/visibility reset; Level.lua also changed |
| RPF-07 | [UnitFrames/FluxUnitFrames_Auras.lua](../UnitFrames/FluxUnitFrames_Auras.lua) | Leave matching UNIT_AURA to native incremental owners | Explicit target/focus/world/combat recovery paths |
| RPF-08 | [Core/Engine/SpellBookChrome.lua](../Core/Engine/SpellBookChrome.lua) | Use native ticker for existing 0.1 s observations | Independent no-native-hook policy; original frame fallback |
| RPF-09 | [Bars/ProgramFace.lua](../Bars/ProgramFace.lua) | Use native 0.05 s ticker | Secure native hover probing; coalescing; timerless/error recovery |
| RPF-10 | [ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua](../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua) | Park empty binding/press watcher | Immediate input/binding wake and release tracking |
| RPF-11 | [Battlezonemap/FluxThreat.lua](../Battlezonemap/FluxThreat.lua) | Check deadlines before fallback probes; avoid comparator closure churn | Event-led primary target checks and required fallback |
| RPF-12 | [Core/Engine/Restricted.lua](../Core/Engine/Restricted.lua) | Sleep 0.2 s waits after next-frame reconciliation; guard reentrant ownership | Both immediate and next-frame event passes; timerless retry |
| RPF-13 | [Bars/Stance/Extras.lua](../Bars/Stance/Extras.lua) | Cache readable formatting/owned holder; avoid legacy vararg arrays | Every-frame native digit suppression/color/alpha |
| RPF-14 | [Core/ButtonFX/Overlay.lua](../Core/ButtonFX/Overlay.lua) | Share samples only within synchronous pass; cache owned geometry/style; skip unchanged parent/level setters | Frame-synchronous animation; native reset/transfer/clear/retry |
| RPF-15 | [Inventory/Builtin/Mail.lua](../Inventory/Builtin/Mail.lua) | Reuse exact immutable captures | All slot probes; inaccurate count/sparse/metadata retries |
| RPF-16 | [Inventory/Syndicator/Adapter.lua](../Inventory/Syndicator/Adapter.lua) | Cache private index cardinality with map/generation ownership | Every provider-row check; complete atomic publication |
| RPF-17 | [Inventory/Syndicator/Adapter.lua](../Inventory/Syndicator/Adapter.lua) | Classify touched IDs; reuse equal dirty-bag rows | Immediate synchronous authoritative facts |
| RPF-18 | [Inventory/Init.lua](../Inventory/Init.lua) | Sleep until heavy deadline using native After | Same budgets/first-paint/max-wait; original polyfill fallback |
| RPF-19 | [Inventory/Summaries.lua](../Inventory/Summaries.lua) | Validated weak item-key cache; preserve excluded pending characters | First uncached all-visible traversal for immediate totals |
| RPF-20 | [Minimap/FluxQuestie.lua](../Minimap/FluxQuestie.lua) | Cache owned line layout/style inputs | Pool enumeration and fresh text-height measurement |
| RPF-21 | [Battlezonemap/FluxThreatMeter.lua](../Battlezonemap/FluxThreatMeter.lua) | Reuse sample rows; cache readable identity/style | Existing 0.2 s fresh values and secret-safe sinks |
| RPF-22 | [Other/FluxLoot.lua](../Other/FluxLoot.lua) | Skip unchanged full-alpha writes | Same per-frame fade and expiration |
| RPF-23 | [MicroMenu/FluxLFGMicroButton.lua](../MicroMenu/FluxLFGMicroButton.lua) | Use native After chain and owned visibility lifecycle | Same 0.1 s steps/phase; rearm before potentially failing paint |
| RPF-24 | [RaidFrame/FluxRaidAuras.lua](../RaidFrame/FluxRaidAuras.lua) | Share per-filter snapshots; skip fully disabled displays | Same filter/sort/class-buff/dispel output; native owners unchanged |

The existing [Timer service](../Core/Engine/Timer.lua) exposes captured native capability flags. These remain correct if later compatibility code adds globals. No global client API was replaced.

## Requirements and validation

| Requirement | Evidence |
| --- | --- |
| PPO-01 Optimize all 24 audited candidates | Coverage table and exact source manifests |
| PPO-02 Preserve appearance/features | Production behavior/geometry/style traces; native-reset/recycle/error/input regressions; full suite |
| PPO-03 Preserve update speed | Same nominal intervals and frame-synchronous animation; event/deadline/hidden-phase comparisons |
| PPO-04 Show before/after difference | Exact checkpoint baselines; three matched pairs/workstream; raw work counts and negative controls |
| PPO-05 Preserve data/security/integrations | No settings/default/load-order change; secret/forbidden/optional-provider/ownership tests |
| PPO-06 Retain reviewable identities and scope | External checkpoint; candidate hashes; pinned upstream; generated inventories and ledgers |

The final full run passes **287 scripts and 959 Lua syntax checks**. The read-only documentation validator also passes: 992 classified sources, 607 reachable files and 16,117 local links; generated source records are current. Seven dedicated optimization tests are included. Full results, source identities, raw comparisons and exact commands are in [the evidence record](validation/passive-performance-optimization-2026-11-10.json).

Core comparisons preserve callback-time, visibility and geometry traces. They cover direct cast refresh, player/pet timing, actual transfer/clear/reuse, reentrant state-driver ownership, failed style sinks and actual Timer-service error recovery without native APIs. Rank tests cover ties, tank placement, missing/secret GUIDs and errors. Nameplate tests cover add/remove/rebind, native alpha/anchor resets, inaccessible preceding anchors, options visibility, failed labels/font metrics and reparent level invalidation. Inventory tests cover sparse/inaccurate attachment counts, metadata edits, in-place provider changes, bag moves, cancellation/max-wait and filtered pending summaries. UI tests cover input/release, texture phase, recycling, native digit resets and transient errors.

Independent review caught and corrected candidate defects before final validation: timer polyfills could stop polling after an error; an anchor-index shortcut could bypass the original preceding-anchor access/order checks; and removed-unit callbacks could see a stale cached plate. The anchor shortcut was removed completely. Retry and reentrant-ownership regressions were added.

A deliberately broken inventory mutant exposed the existing PolyAfter loop behavior. Its exact helper process was stopped and zero matching helpers verified; mutation runs are now timeout-bounded. This was an isolated desktop test process, with no game input/settings operation.

Appearance assets, XML, TOC/load order, defaults, commands and SavedVariables declarations are unchanged. Guild-bank and void-storage callback bodies remain out of scope. The existing Questie, Details and Syndicator owners remain. No manual cross-client synchronization, commit or publication occurred.

## Source identity and reproduction

The baseline is external checkpoint `checkpoint-20261110T125124Z`: 2,525 files, 103,013,089 bytes, full SHA256 manifest and verified Git history at main `26f886e3ea5371b196ab235d2dace0c156002285`, including the current uncommitted work. Settings metadata was inspected read-only; no quiescent settings backup is claimed.

Five fresh Gethe branch pins match the audit:Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`, Forever `9dc84f0d3bbae1768ac3405b3716000bd93eda06`, progression `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`, Era `4192ac60067fc55566182291bc67c85dd9b6794d`, Anniversary `68e0a2ec559d9761dfc4e7f864c3944f9d758a49`. Full pinned nameplate/frame-method sources supplement the native aura/lifecycle records; Git blob identities were verified.

Native containers own incremental aura updates; explicit UpdateAllAuras marks a full rebuild. The optimization retains lifecycle refreshes and avoids upgrading ordinary matching diffs. [Pinned native event/unit lifecycle](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainer.lua#L81),[managed full/incremental paths](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_AuraContainer/Blizzard_ManagedAuraContainer.lua#L63).

Run current-source checks from this repository:

```text
lua tests/passive_core_optimization.lua
lua tests/passive_inventory_work.lua
lua tests/passive_nameplate_optimization.lua
lua tests/passive_nameplate_metric_recovery.lua
lua tests/passive_threat_rank.lua
lua tests/passive_raid_aura_snapshots.lua
lua tests/passive_world_optimization.lua
python tests/run_validation.py --output <external-result.json>
python docs/tools/validate_docs.py
```

Comparison fixtures accept an external source root. The evidence retains exact arguments, raw outputs, candidate hashes and replay controllers. Earlier nameplate `final`, `sealed` and `reviewed` artifacts are superseded by `nameplates/final-reviewed`.

## Remaining native checks and necessary costs

The visible embedded map still runs its native frame pipeline, and the secure character micro button still mirrors frame-synchronous state. Removing or throttling them would change retained features; neither was established as an avoidable defect.

Forever still performs 2,074,320 native alpha reads and 691,440 anchor-count reads in the 40-plate/144-FPS replay including probes. These remain because native resets must recover on the same frame. Full provider input validation, native digit reconciliation, secret sinks and first uncached visible summaries also remain where freshness requires them.

No foreground/mouse/keyboard/clipboard control, reload, native profiling or client-setting write occurred. Actual native FPS, p95/p99 frame times, allocation bytes, screenshots, secure input and taint acceptance remain **NOT RUN** on all five clients. This is a measured reduction in modeled Lua/API/widget work with preserved tested behavior; no native FPS gain is claimed.
