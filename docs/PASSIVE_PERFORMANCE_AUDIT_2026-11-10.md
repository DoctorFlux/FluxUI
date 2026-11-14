# FluxUI passive performance audit

Implementation follow-up: [before/after optimization results](PASSIVE_PERFORMANCE_OPTIMIZATION.md). The counts below remain the original unchanged-source audit.

10 November 2026. **24 current optimization candidates and 2 retained feature costs to measure.** The first places to investigate are threat ranking across many nameplates, per-frame nameplate layout checks, repeated aura styling, and forced native aura rebuilds.

This is an audit of the current working tree on main at `26f886e3ea5371b196ab235d2dace0c156002285`, including existing uncommitted work. Operation counts below come from unchanged production functions driven by synthetic inputs. They establish repeated work and scaling; they do not measure native CPU time, frame time, GPU cost, or recovered FPS. Lua 5.4 ran the desktop fixtures; the WoW runtime, secure environment and native widgets were not emulated faithfully.

No FluxUI Lua, XML, TOC, preferences, saved data or installed copies were changed. No client input, reload, profiling or publication occurred. Guild-bank and void-storage callbacks were excluded. Existing party/raid implementation and native-test pauses remain in effect; this audit adds findings only.

## Requirements and evidence

| Requirement | Result |
| --- | --- |
| REQ-RPF-01 Identify current background and passive costs without changing addon Lua | Current loaded source audited; all 953 Lua byte identities checked before/after, including the one file excluded by the existing runner |
| REQ-RPF-02 Explain triggers, scaling and realistic optimization directions | 24 candidates below, separated from 2 feature costs needing measurement |
| REQ-RPF-03 Compare relevant behavior with Blizzard source | Five branch heads freshly pinned; 21 source records and 17 distinct Git blob identities verified |
| REQ-RPF-04 Simulate repeated work where useful | 22 nameplate scenarios, 6 threat-rank scenarios, 6 spellbook scenarios, 4 mail phases and 1 aura dirty-request replay |
| REQ-RPF-05 Leave a usable optimization order and native acceptance plan | First measurement batch and preservation requirements below; native FPS acceptance remains pending |

Raw replay results, exact source identities and external artifact paths are retained in [the audit evidence](validation/passive-performance-audit-2026-11-10.json). Replay harnesses live outside AddOns. Existing tests and unrelated modifications were preserved.

## Where to measure first

Priority means expected investigation value, based on work volume and scaling. It is not a measured ranking of CPU milliseconds.

| Order | Candidate | Why it comes first |
| --- | --- | --- |
| 1 | RPF-03 Nameplate threat rank | Rebuilds group identity and sorts a threat list per eligible mob; group-size cost compounds with plate count |
| 2 | RPF-01 and RPF-02 Nameplate frame checks | Unchanged alpha/anchor/visibility checks multiply directly with displayed FPS and plate count |
| 3 | RPF-04 and RPF-07 Aura updates | Rewrites settled text/layout or asks the native container for a full rebuild despite native incremental delivery |
| 4 | RPF-08 and RPF-09 Closed-window/unused-hover observers | Background dispatch continues with no active interaction |
| 5 | RPF-15 through RPF-19 Inventory and provider bursts | Full-list work and trailing slot probes can create hitches during mail/auction/bag/tooltip activity |

### Nameplates and unit auras

| ID | Current source and trigger | Repeated work | Optimization direction and preservation |
| --- | --- | --- | --- |
| RPF-01 | [NamePlates/Core.lua](../NamePlates/Core.lua), line 1171; Forever, active plates, options closed | Every rendered frame walks all plates and calls `ApplyForeverPlate`. Settled state still reads level-region alpha and verifies health/aura anchors. The 0.25s throttle controls text placement only. | Cache stable plate/layout inputs and invalidate on native layout changes. Retain immediate correction when combat badges shorten the bar; do not simply slow the entire driver. |
| RPF-02 | [NamePlates/Core.lua](../NamePlates/Core.lua), line 1220; Retail, active plates, options closed | Every frame resolves every plate and checks up to two native level regions. The already-hidden regions avoid Hide writes, but the lookups/checks remain. | Apply suppression at plate creation/show/rebind with a verified recovery path for native resets. Avoid adding insecure native hooks without testing. |
| RPF-03 | [NamePlates/Threat.lua](../NamePlates/Threat.lua), line 248; [Core/API/Threat.lua](../Core/API/Threat.lua), line 882 | Each eligible NPC at the existing 0.25s cadence builds group+pets again, linearly deduplicates identities, allocates detailed/row tables and sorts the complete list. Rank is computed before numeric-display gating. | Cache roster identity across mobs, reuse scratch storage, determine player placement without sorting every row, and skip rank when neither enabled text nor tint requires it. Preserve threat semantics and secret-safe output. |
| RPF-04 | [NamePlates/Countdown.lua](../NamePlates/Countdown.lua), lines 182 and 257; active aura labels, 0.1s cadence | Even unchanged labels receive SetText, ClearAllPoints, SetPoint, SetFrameLevel, Show and native digit suppression. List traversal also allocates a child-results table. | Cache readable label, anchor target and level; apply only changes. Retain countdown freshness, native digit recovery and reparent/recycle handling. Pool/list overlap is a separate unverified topology risk, not an assumed live doubling. |
| RPF-05 | [NamePlates/Level.lua](../NamePlates/Level.lua), lines 128–203 and 226; supported non-Retail clients, 0.25s cadence | Settled level badges repeat unit metadata reads, font/style updates, text measurement, fit/show and anchor work. | Cache level/classification/color/geometry and invalidate at binding, level, layout and appearance changes. Keep the existing 4Hz fallback until native lifecycle coverage is proven. |
| RPF-06 | [NamePlates/Level.lua](../NamePlates/Level.lua), line 212; [NamePlates/Threat.lua](../NamePlates/Threat.lua), line 286 | Removal releases/hides the host then drops its state reference. A later binding allocates another host rather than acquiring a released one. Churn accumulates widget allocations even though warm steady state creates none. | Pool the addon-owned overlay hosts or retain them per recyclable plate. Completely reset unit association, pending clears, anchors and visibility. Actual native retained memory was not measured. |
| RPF-07 | [UnitFrames/FluxUnitFrames_Auras.lua](../UnitFrames/FluxUnitFrames_Auras.lua), line 2265; [AurasEngine.lua](../UnitFrames/FluxUnitFrames_AurasEngine.lua), line 398; Retail/Forever engine aura path | Each matching UNIT_AURA explicitly calls UpdateAllAuras on both existing buff/debuff engines. Native containers already register unit events and process incremental updates. Explicit UpdateAllAuras marks FullAuraRebuild, including for an empty incremental payload. | Let native unit-event delivery own incremental updates; retain explicit refreshes for actual rebinding and recovery. Native dirty phases coalesce requests: this is not evidence of two synchronous full scans per event. Same-token SetUnit already has a native equality guard. |
| RPF-24 | [RaidFrame/FluxRaidAuras.lua](../RaidFrame/FluxRaidAuras.lua), lines 683–713; readable fallback only when native aura ownership is unavailable | Three initial aura scans run even with both buff/debuff displays disabled. Class-buff and dispel handling can rescan HELPFUL and HARMFUL\|RAID. The five-pass case makes 2×helpful + harmful + 2×raid-harmful + five terminating queries. | Reuse scanned lists and honor display gates while preserving filters/sort/order. Native _fluxAuraNative returns before this work; do not generalize to all Classic or every raid frame. Existing per-frame event coalescing remains. Lower-priority fallback finding; no raid implementation change. |

RPF-03 requires supported nameplate threat display, visibility allowed (normally grouped), an attackable live NPC in combat, the player on its threat list and a nonzero/tanking display while the player is in combat. It is a combat/plate scaling hotspot, not an empty-city idle cost. The rank path has no universal Retail/secret early exit; restricted data must remain in supported native sinks.

### Other passive and animation work

| ID | Current source and trigger | Repeated work | Optimization direction and preservation |
| --- | --- | --- | --- |
| RPF-08 | [Core/Engine/SpellBookChrome.lua](../Core/Engine/SpellBookChrome.lua), line 21; modern Retail/Forever observers | One permanently attached OnUpdate checks a 0.1s accumulator; even a closed book resolves its host, checks visibility, traverses observers and invokes onPoll. No unregister lifecycle exists. | A managed timer can preserve the 0.1s observation policy while eliminating frame-frequency deadline checks. Sleeping completely also needs reliable wake sources; preserve the independent observer/no-native-hook policy. |
| RPF-09 | [Bars/ProgramFace.lua](../Bars/ProgramFace.lua), line 1298; any configured hover program | Watcher stays shown while HasHover is true even with no current hover context. Every-frame dispatch delivers a 0.05s context check. | Wake through existing hover paths and sleep without a relevant context; retain active 50ms fallback and existing coalescing. Verify entering/leaving all native/Flux hover surfaces. |
| RPF-10 | [FluxTrinketMenu.lua](../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua), lines 787 and 836; trinket grid visible | Watcher runs even with two empty binding lists and no active presses; visits binding lists, wipes scratch state and walks presses each frame. | Demand-gate the empty state and wake through binding/mouse changes. Preserve secure release-only clicks and held-key release detection. |
| RPF-11 | [Battlezonemap/FluxThreat.lua](../Battlezonemap/FluxThreat.lua), line 850; optional Details threat plugin active | Per-frame plugin/target/combat reads happen before event-led/deadline exits, including OOC. Event-led mode defaults on. | Sleep when no fallback/deferred/targettarget/combat work exists; wake through the existing threat/target/combat events. Preserve immediate updates and fallback targeting. |
| RPF-12 | [Core/Engine/Restricted.lua](../Core/Engine/Restricted.lua), lines 292–302; compatibility fallback active and OOC | Event callback sets its timer to zero and runs ApplyAll; next OnUpdate necessarily runs ApplyAll again. The regular 0.2s sweep also uses a frame-frequency deadline check. | Remove the redundant scheduling condition only after event-order tests. Timer dispatch can retain cadence; native secure drivers and lockdown rules must remain intact. Existing per-string parser deduplication is already fixed. |
| RPF-13 | [Bars/Stance/Extras.lua](../Bars/Stance/Extras.lua), lines 933 and 1077; readable active aura timer | Each frame repeats native countdown suppression, font-string discovery and alpha/text-color writes. The displayed integer text itself is already cached. | Cache owned suppression state, reconcile after native resets, retain frame-responsive expiry and current swipe animation. |
| RPF-14 | [Core/ButtonFX/Overlay.lua](../Core/ButtonFX/Overlay.lua), lines 140, 383 and 552; active cast/channel widgets | Per-widget cast-time queries plus unchanged parent/level setters; channel underlay repeats anchors, color, alpha and draw layer during progress animation. | Share supported per-unit/per-frame timing reads and cache static style/geometry with invalidation. Keep animation frame-synchronous; native timing/secret behavior needs testing. |
| RPF-21 | [Battlezonemap/FluxThreatMeter.lua](../Battlezonemap/FluxThreatMeter.lua), lines 89 and 206; Forever, Details absent, visible Meter tab, combat | Existing 0.2s collection rebuilds sample tables and repaints identity/style for unchanged rows. A 40-member group can require up to 80 player/pet existence checks per collection. | Reuse sample rows and cache readable identity/style. Keep fresh values and secret-safe native sinks; do not reduce cadence. |
| RPF-22 | [Other/FluxLoot.lua](../Other/FluxLoot.lua), line 86; up to three active alerts | Writes alpha=1 every frame throughout the stable display, before the final 0.5s fade. Default duration is 3s. | Skip unchanged owned-alpha writes while preserving the same per-frame fade and expiry. Small bounded saving. |
| RPF-23 | [MicroMenu/FluxLFGMicroButton.lua](../MicroMenu/FluxLFGMicroButton.lua), line 350; queued/listing/applications | Per-frame accumulator dispatch for an approximately 10Hz texture animation; already stops when inactive. | Consider a timer/native animation preserving 0.1s texture cadence and hidden visibility. Small conditional saving. |

### Window, provider and event bursts

These can produce frame hitches while the addon is in use; they do not all contribute to settled passive idle.

| ID | Current source and trigger | Repeated work | Optimization direction and preservation |
| --- | --- | --- | --- |
| RPF-15 | [Inventory/Builtin/Mail.lua](../Inventory/Builtin/Mail.lua), lines 110 and 137–187; builtin mail scans | Probes every possible attachment position even after collecting the numeric expected count. Unchanged scans still allocate capture records. | Verify native count reliability per client, then consider early completion once the expected attachments have actually been found. Preserve sparse slots, boolean-header clients and incomplete-data retries. |
| RPF-16 | [Inventory/Syndicator/Adapter.lua](../Inventory/Syndicator/Adapter.lua), lines 343–422; mail/owned-auction provider snapshots | ListMatchesSnapshot walks the provider list and old keys; changed generations synchronously traverse the list again in FillFromList and rebuild index/count maps. Normalized row reuse does not remove these traversals. | Use stable provider identities/deltas where available or stage complete generations. Preserve sparse keys, metadata, immediate authoritative facts and atomic publication. Existing progressive-growth evidence remains relevant; no new native transaction timing was taken. |
| RPF-17 | [Inventory/Syndicator/Adapter.lua](../Inventory/Syndicator/Adapter.lua), lines 155–199 and 562–600; BagCacheUpdate bursts | Affected bag snapshots rebuild before downstream token coalescing. Even incremental refresh classifies the item-count key set and replaces dirty-bag rows per callback. | Merge compatible dirty sets before expensive work or update per-item deltas. Do not defer facts that protect transfer/vendor/crafting correctness. |
| RPF-18 | [Inventory/Init.lua](../Inventory/Init.lua), lines 690 and 754; deferred heavy jobs awaiting quiet deadlines | Frame callback repeatedly visits waiting jobs/reads clocks during 0.05/0.12/0.18s settle periods, bounded by 0.6s maximum wait. The 2-callback/1.5ms limit cannot preempt one long callback. | Wake at the nearest deadline and retain the existing bounded drain. Split genuinely long listeners into cooperative slices; preserve final publication. |
| RPF-19 | [Inventory/Summaries.lua](../Inventory/Summaries.lua), lines 56, 156 and 212; first inventory tooltip after changes | Tooltip read synchronously flushes all pending character summaries; each rebuild visits retained locations beyond the hovered item. Cross-character stored data increases the burst. | Prepare summaries incrementally or maintain per-item totals. Preserve complete character/location awareness. This is a summary consumer finding; excluded guild/void callbacks were not audited. |
| RPF-20 | [Minimap/FluxQuestie.lua](../Minimap/FluxQuestie.lua), lines 81, 207 and 371; optional Questie tracker Update, OOC | Every update triggers layout/style over the pool high-water mark, repeated anchors/width/wrapping and string-height measurement, then another scroll-range walk. | Cache content/width/mode per recycled line, invalidate on assignment and actual layout changes; preserve immediate wrapping and scroll bounds. |

## Production code replay results

Fixtures load complete current modules, except the native aura replay which executes exact verified native method excerpts alongside the complete Flux aura-engine module. Widgets/API responses are counted stubs. No candidate code was installed or optimized.

| Scenario | Observed work |
| --- | --- |
| Closed spellbook, 60 simulated seconds | 3,600 OnUpdate calls at 60 FPS; 8,640 at 144; 14,400 at 240. Closed-host visibility and synthetic owner poll run 514/576/576 times respectively. Frame quantization explains the difference from ideal 600. Three synthetic observer registrations match the current consumer shape. |
| Forever, 40 plates, 60s, 144 FPS | 2,073,600 GetAlpha calls, 691,200 GetNumPoints and 691,200 GetPoint calls in settled layout verification |
| Forever, same scene, 240 FPS | 3,456,000 GetAlpha, 1,152,000 GetNumPoints and 1,152,000 GetPoint calls; increasing FPS alone increases these checks |
| Retail, 40 plates, 60s | GetNamePlateForUnit rises from 378,240 at 144 FPS to 608,640 at 240. Other module polls are included, but the 230,400 difference exactly matches 40 plates × 60s × 96 extra frames/s in the unthrottled level-hide walk. |
| Four unchanged aura labels/plate, 40 plates, 240 FPS, 60s | 92,160 GetCountdownFontString reads. The combined module replay records 101,760 SetText/ClearAllPoints/SetPoint calls on Retail and 111,360 on Forever; combined totals include threat/level painters and must not all be attributed to Countdown. |
| 1,000 actual add/remove event cycles on one reusable plate | Retail creates 1,004 overlay/countdown Frames; Forever 2,004. Four initial countdown hosts are included. Steady-state runs create zero Frames after warm-up. This measures allocation churn, not native retained bytes. |
| Threat ranking, 40 members + 40 pets, 20 engaged mobs, 240 polls over 60s | 4,800 rank calls perform 384,000 UnitDetailedThreatSituation and 15,192,000 UnitIsUnit calls with synthetic public positive threat. That is 253,200 identity calls/s. Doubling to 40 mobs would be an algebraic extrapolation, not another observed replay. |
| 50 messages, one attachment each in slot 1, maximum 12 slots | 650 header/item reads on arrival and 650 on unchanged rescan; maximum 48 reads/frame. Unchanged scan creates 50 capture records but zero normalized rows/publications. |
| Same mailbox fixture, maximum 16 slots | 850 reads on arrival and 850 unchanged; this is a separate configured fixture, not a claim that every client has 16 slots. |
| Native empty incremental aura payload | Native processing marks zero full rebuilds; the unchanged Flux PokeEngineAuras then requests one full rebuild. Multiple requests may coalesce in native dirty phases. |

The nameplate replay contains 22 scenarios across Retail/Forever, 1/20/40 plates and 60/144/240 FPS. Four constant synthetic aura labels, positive threat, options closed and quest overlay disabled define its scope. Forever has six synthetic level-art regions plus health and crowd-control anchors; loss-of-control and dynamic health-readout placement are outside those counts. Pool-only results support the table. A separate pool+list-overlap scenario is retained only as a diagnostic hypothesis until live topology is verified. Threat rank is measured in a separate actual-code replay; its calls must not be added to the nameplate replay as though both were a native capture.

## What Blizzard source establishes

| Client source | Pinned commit | Source version |
| --- | --- | --- |
| Retail live | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` | 12.1.5.70783 |
| Forever | `9dc84f0d3bbae1768ac3405b3716000bd93eda06` | 1.60.1.70862 |
| Classic progression | `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` | 5.5.4.70631 |
| Classic Era, existing repository scope | `4192ac60067fc55566182291bc67c85dd9b6794d` | 1.15.9.70576 |
| Anniversary, existing repository scope | `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` | 2.5.6.70577 |

These identify source snapshots; installed client builds were not probed.

The native AuraContainer registers UNIT_AURA for visible enabled containers; its shared SetUnit returns without refreshing for an unchanged unit. Its managed implementation handles incremental payloads and reserves FullAuraRebuild for full refreshes or explicit UpdateAllAuras. Consequently RPF-07 can defeat the incremental path even though the native scheduler coalesces requests. [Aura event and unit lifecycle](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainer.lua#L40), [managed refresh and incremental processing](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_AuraContainer/Blizzard_ManagedAuraContainer.lua#L63). Retail files have the same verified blobs.

The native global OnUpdate registry invokes registered owners independently of owner visibility. A hidden owner's name in an inclusive profiler row therefore does not identify the work beneath it. Current ownership still needs capture; it is not evidence that FluxUI owns the entire dispatcher cost. [Native dispatcher](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXMLBase/GlobalCallbackRegistry.lua#L63).

## Retained feature costs needing native measurement

1. **Visible embedded map.** [FluxBattlefieldMap.lua](../Battlezonemap/FluxBattlefieldMap.lua), line 161, calls the native MapCanvas OnUpdate. The native pipeline performs pin suppression/nudging, cursor handling and registered provider updates each frame. This is a plausible passive cost with the Map tab visible, but no safe removal is established. Measure visible map versus another tab/hidden window with the same camera and pin providers. Fresh WorldMap Lua contains no OnUpdate registration; do not repeat the old hidden-WorldMap ownership attribution as a current fact. [Native MapCanvas pipeline](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_MapCanvas/Blizzard_MapCanvas.lua#L30).
2. **Character micro button.** [FluxChatColumnMicros.lua](../Other/FluxChatColumnMicros.lua), line 976, intentionally polls frame-synchronous mouse/press/panel state. Its unchanged painting is already cached. Retail/Classic have show/hide hooks; Forever intentionally avoids them for security. Profile its dispatch before considering an input-driven wake design; preserve press/release and secure panel opening.

Portrait/model rendering, native aura internals, other addons and GPU/rendering work are not measured by these fixtures. Lua operation counts cannot rank their relative cost.

## Findings deliberately not carried forward

- Party health/prediction traffic no longer performs the old complete chrome rebuild; the 9 November steady-party changes remain present.
- Chat character-button settled layout writes and bag-counter timer coalescing were already corrected.
- Quest badge settled layout is already cached; no new quest-data polling claim is made.
- ObjectiveTracker synchronization already coalesces via its pending flag.
- Legacy ExtraButtonSystem Engine Events/Button/Util files not loaded by the current TOC were excluded.
- Historical native captures are context only; no old FPS/CPU result is acceptance for this working tree.
- An existing scheduler budget is not a guarantee that a synchronous listener completes within it.

## Next optimization batch

Start with RPF-03, RPF-01/02 and RPF-07/04 as separate changes so each has a reviewable cost and regression surface. Cheap dispatch gates RPF-08/09/10 can follow independently. Inventory/provider work needs its own transaction replay and complete-generation correctness checks.

For each approved change, retain the exact current source/configuration, preserve appearance, cadence, bindings, settings and integrations, and compare matched repeated native captures. Use the same client/build, addon list, graphics/background-FPS settings, scene/camera, plate/group count and profiler mode. Capture idle solo, grouped idle, 20/40 engaged plates, aura churn, a visible map and mail/auction growth separately. Record raw frame times, callback CPU, p50/p95/p99, variation and profiler preferences; restore preferences afterward.

No native scenario was run in this audit. Current FPS loss, recovered milliseconds, taint safety, pixel parity, native event order and retained-memory impact remain pending. Background-client results also need their focus/FPS-cap context; do not compare them with unmatched foreground rates.

The existing documentation validator reports 10 stale generated-inventory/verification/line-reference issues involving the current minimap sources and generated views. These references were already stale relative to the unchanged starting Lua manifest; no audit source changed. Unrelated generated records were not regenerated. New audit links, evidence, CSV schemas and unchanged Lua identities are checked separately.
