# Combat entry and exit performance

<!-- RANK-CACHE-BUILD-COST-R65-20261117 -->
17 November R65 adds optional-watch attribution for existing rank-cache builds,
following CF64's14.6901ms usability-listener observation. It does not establish
that the historical listener rebuilt the cache. `rankCacheBuild` schema1 stores
count, lastMs/lastAt and peakMs/peakAt only after completed builds, into the same
still-active owned report. Loaded capability marker is
`_G.FluxSpellRankManager.cacheCostVersion == 1`; native observation is pending.

No parse cache, skipped native metadata query or build-cadence change. OFF adds
one protected Lua Capture lookup during an existing build and no native clocks,
privacy queries, tables, timer/event or per-icon check. Active clocks/guards/status
add overhead: ms includes ending owner verification and excludes subsequent
WatchStatus/final publication. Original metadata errors propagate; optional
record failures are contained. Both VMs pass70scenes/545new+224existing checks;
four compiles and exact preimage projection pass. This is observability, with
no native CPU/FPS improvement claim. Combined mini-frame READY, exact loaded
adoption and broader combat/group acceptance remain pending.
[Source identities and bounded evidence](validation/rank-cache-build-cost-r65-2026-11-17.json).
<!-- /RANK-CACHE-BUILD-COST-R65-20261117 -->

<!-- COMBAT-CF64-20261117 -->
17 November native CF64: the user reproduced lag during a finite120s Forever
70938 watch. It retained31 frame gaps and3 slow callbacks. All16 entries and16
exits were delivered and sampled; first/invalid/stopped cohorts are zero.
Worst next eligible driver gaps were25ms/17ms. These measure frame correlation,
not handler CPU or reaction time, and do not rule out deferred combat lag.

The deferred `border.junctions` callback cost105.5655ms at8.779s; the enclosing
Combat structural flush cost105.6152ms. These inclusive spans overlap: do not
sum them. The105.5446ms build spent13.8457 geometry,17.3564 solve,32.6114 plan
and41.3149 commit. Mesh24.0711ms split into prepare8.8707/draw15.2004ms.
The14.6901ms `Bars/Init.lua:199` listener carried `ebs.usable,bars.usable`.

The815ms gap at40.995s remains UNATTRIBUTED. Its nearest profiler tick reports
application815ms/all addons19.1767ms/Flux18.5329ms; coarse heap/context and
callback correlations do not establish its cause. Only20of31 ring rows survive;
the8.779s border row and original requester were not retained.

DiagnosticVersion3 and the R60 border family are observed; exact loaded Core
hash is UNKNOWN. This capture does not accept newer Core, FPS, pixel, controller,
taint or party/raid changes. CF64 deep retention passes; the original7-gap/
2-callback report remains in `CF62hold.old`, with restoration pending the owned
background guard. No capture lease is held. Profiler preferences were not written;
start/end errors are zero and Bank actions zero. R63 rejection remains unchanged.
[Sanitized evidence and detailed phases](validation/combat-cf64-2026-11-17.json).
<!-- /COMBAT-CF64-20261117 -->

<!-- FALLBACK-INPUT-WORK-R63-20261117 -->
17 November R63 is REJECTED/REMOVED. Combined420e failed Lua54 warm median
CPU+8.143% after24of48cells; scalarD558 failed Lua51 coldCPU+9.677% after6of48.
Functional42,524checks perVM and the mixed514/1204trial pass do not establish
performance acceptance. Exact Core4fa7c12a/LF110827 and testad065 are restored;
OtherE790 remains.

Production cold/warm/changed models had zero leaf-cache hits. CF57 is historical
city attribution, not a paired combat result. Root's later baseline CF64 watch
was reported armed at07:34:09UTC; retention and combat-event results remain
pending. Combat/group latency, FPS, taint and visual acceptance stay open.
[Failed gates and restoration](validation/fallback-input-work-r63-2026-11-17.json).
<!-- /FALLBACK-INPUT-WORK-R63-20261117 -->

<!-- COMBAT-WATCH-R61-20261117 -->
17 November R61 repairs the OPTIONAL finite spike watch and adds delivered
combat-entry/exit counts with next eligible driver-frame gap correlation. Failed
arming preserves prior diagnostics and cleans owned resources; stale callbacks
cannot overwrite or expire a replacement watch. First, invalid and stopped
batches stay explicitly unmeasured; valid zero and subthreshold worst gaps remain
distinct, and counts survive multiple events and spike-ring wrap.

Other changes from678efe to e7908c04; Core110827 and its R60 mesh detail remain.
Installed tests pass89scenes/562new plus133original checks on each Lua5.1.5/5.4.6;
four test compiler checks pass. Fourteen compiled mutants per VM are rejected at
behavioral assertions; two parity runs retain86read order/report projection/console
output. Fresh wholeLua54 accepts513scripts/1203syntax,0failures;1282source/support pins stable. This does not certify wholeLua51/native behavior.

No ongoing OFF native work is added. Startup helper closures and active scalar,
privacy, event and protected-Update overhead remain; diagnostic clocks omit part
of that overhead. Final native security predicates/Lua primitives are trusted,
without an arbitrary-mutator atomicity guarantee. This is observability and
ownership repair, not event CPU/latency, party attribution or a CPU/FPS gain.

Root-only Mario native adoption/delivery testing still waits for the existing
device handoff; Ready was answered. Bank is entirely excluded. Historical CF57
R57 city watch, R58 scoped gains, rejected R59 candidates and R60 validation remain
separate. Combat enter/exit and party/raid join/leave hitch acceptance stays OPEN.
[Exact repairs, sources, proof history and limits](validation/combat-watch-r61-2026-11-17.json).
<!-- /COMBAT-WATCH-R61-20261117 -->

<!-- WATCH-MESH-PHASES-R60-20261117 -->
17 November R60 `watch-mesh-phases-r60` is applied as standalone OPTIONAL
existing-watch observability, independently descended from preexisting4ec7.
Only cost.meshPhases.prepare/draw scalar detail is added; aggregate mesh and
five-line output stay. Default-off adds0clocks/watch queries/frames/scans/tables;
active watch adds one protected midpoint. Midpoint clock lies inside mesh;
nested allocation/comparisons occur after mesh-end and count in following
retire/overall. This is not observer-free timing or a CPU/hardware/FPS gain.

Separate external gate passes46scenarios/442checks perVM,7controls perVM,
8actual fixture runs and181prototypes/max55/56captures; exact whole-body
projection and independent review pass. Installed durable border_reflow_cost
passes148checks perVM and both compilers; test94bca1c5 is frozen. Fresh fullR60
Lua54 accepts512scripts/1202syntax,0failures;1281source/support pins stable;
historical R58perf/full512/1202 and R59tuple/combined REJECTION stay separate.
No tuple code, combat-transition counters, events/frames/timers or Other edit.

Ready was ANSWERED for Mario background. Actual foreground stayed unsafe:
cf60-mainreload-a1/a2 both timed out with0input/no journal/lease/command.
Separate same-PC/another-device handoff question is pending; no more retries
until handoff. Root passive main loaded-UI observation sent no input/focus/Bank
and does not prove loaded R60. Repo/game five-file equality is not adoption.
Permission remains main-only; this is a BGconstraint, not revocation. Bank
entirely excluded. Native loaded version/combat/group/FPS results remain pending.
[Exact observability source/proof and current pending native state](validation/watch-mesh-phases-r60-2026-11-17.json).
<!-- /WATCH-MESH-PHASES-R60-20261117 -->


<!-- FIELDSET-SPECIALIZATION-R59-REJECTED-20261117 -->
17 November R59 FieldSet tuplee37/combined34ce is UNAPPLIED/REJECTED by
Root fitness; installed R58 exact540 and full512/1202acceptance stay unchanged.
All140fixed cells (1163.234s) and70shape/checksum/clock pairs passed, pins stable.
No median5%CPU threshold breach is insufficient fitness: common changed scenes
regress (+.336%51, all3pairs slower;+.611%54);54strip has one+9.735%CPU/
+11.169%wall loss. All14case medians/19adverse pairs/rawcells remain. Allocation
is mostly flat/noisy: NO allocation gain. Startup/live cost rises~4.43KiB51
(watch4.71),~5.1-5.3KiB54, including a strip6.55KiB outlier.

Cold here clears FieldSet caches on pooled widgets, not addon startup. Reuse
still forces complete78ops with56meshReuse/1232fields,5320PrepareGETS/0DrawGETS.
Tuple equivalence assumes stock select. Historical768checks/VM,18states,
38430calls and134734/135366numericselect opportunities do not prove benefit.
Separate preexisting metrics4ec7 remains UNAPPLIED observability-only; not a
post-timing performance fallback or CPU gain. Combat-watch counters are only
unimplemented source design. No new variant/retest without fresh attribution.

Native R58adoption remains unproved: cf59-mainreload-a1/a2/a3 background preflight
timeouts sent0input, no lease/journal/command. Ready coordination unanswered;
this is a background constraint, not native permission revocation. Root alone
owns further main-client admission. CF57maincommands3/Bank0 remain historical;
Bank entirely excluded, no CF58watch. Goal ACTIVE; no combat/group/FPS/A-B gain.
[Exact rejection, all samples, scopes and separate proposals](validation/fieldset-specialization-r59-rejected-2026-11-17.json).
<!-- /FIELDSET-SPECIALIZATION-R59-REJECTED-20261117 -->


<!-- SOLVER-ALLOCATION-R58-20261117 -->
17 November R58 (`solver-allocation-work-r58`) is applied: only private H/V
tuple and nil point/patch temporary arrays are elided. Original string keys,
nine-probe/last-match order, callbacks and native queries remain. Fresh fullLua54
512scripts/1202syntax PASS;1281pins stable. Separate313checks perVM/eight controls/
six durable jobs and12focused+twoCorecompiler jobs pass; not wholeLua51/native.

Fixed84CPU+56allocation cells passed Root review; all70shape pairs match.
Connected/HUD1/HUD8/HUD20 medianCPU51 -9.596/-6.358/-5.729/-7.853%;
54 -9.524/-5.645/-3.797/-11.976%. These are Solve/model intervals, not native
discovery/ReadLayout/planning/commit or FPS. Empty51lost all three pairs:
median+4.762%CPU/+5.048%wall, zero allocation saving; below declared median5%CPU
reject but retained as risk. Minimum51gain is one clock tick; individual54HUD8
+3.165%/HUD20+1.130% losses remain. Positive startup/live delta<1.3KiB;
stoppedGC HUD20slopes save339744/299024B percall51/54.

The complete frozen2444Solve shares other current helpers intentionally; future
helper changes are outside that independent oracle. Numeric indexing remains
REJECTED (owner-equality changes plane:14concat calls became4; final14).
Validated56canvas attribution retains1232fields/5320reusePrepare getters, zero
canvas churn; no unsafe native layer/getter cache was introduced.

Native R58adoption/performance remains pending Root confirmation. Historical
CF57R57CITY124ms is not R58 or combat/group/FPS/A-B acceptance. Root alone owns
main-client diagnostics; Bank entirely excluded. Controllers are preparation
only as last reported, not a loaded-version result. Goal ACTIVE.
[Exact sources, fixed gate, raw risks and pending native acceptance](validation/solver-allocation-r58-2026-11-17.json).
<!-- /SOLVER-ALLOCATION-R58-20261117 -->


<!-- USER-NATIVE-TEST-RELEASE-20261116 -->
The user explicitly released the game-testing hold: “we can test ingame now if
needed”. This supersedes earlier native-test holds in this chat. Root may inspect
the current client and perform sequential bounded UI diagnostics for combat/group
performance; keep WoW in the background, preserve profiler preferences and prior
diagnostics, and verify client/window/world/combat state before input. Gameplay
transitions remain user performed. Unrelated jump/crafting/commerce/session holds
are retained. No native result or current-source adoption is inferred from the
permission. [Release scope and record](validation/native-test-release-2026-11-16.json).
<!-- /USER-NATIVE-TEST-RELEASE-20261116 -->


<!-- COMBAT-CALLBACK-WORK-20261116 -->
16 November (`COMBAT-CALLBACK-WORK-20261116`): two additional offline fixes are applied.
Portrait camera/SetUnit/clear/geometry protected callbacks reuse private bodies
while all current lookups, native calls, errors, recovery and finite timers stay.
Range discovery reuses two helpers with current globals/pools and fresh250ms
ticker callbacks. Portrait114scenarios/105609checks perVM/7controls;range175checks
perVM/5controls/85matching stage traces. Portrait durable gate105623checks perVM
includes all seven controls; the external105609check gate is retained separately.
Independent source review passed.

Declared cost gates passed; all raw samples and small regressions remain.
Portrait48cells:51empty CPU median+3.398% (onepair+9.338%);54 has slower individual
2D/3D/max pairs. Startup retained increases are recorded separately from GC slope.
Range96cells retains54native+1.512%/hidden+0.694%;active fallback transient work
decreases. These standalone results do not establish native speedup.

17 November R57: `shadow-wake-owner-r57` is applied. The original b8e0fac3
snapshot passed502scripts/1192syntax with stable1192Lua+38support/art pins;
strict80comparisons/six controls perVM and installed32job proof stay scoped to it.
Later244413aa now passes five scripts on both VMs (328/20/63/111147/486467checks)
and two Core compilers. Initial6PASS/4Lua51load-signature fixture failures remain;
an external loader wrapper supplies the four corrected passes. Initial1200Lua
and corrected8Lua+33TGA raw pins stayed stable. No R57CPU benchmark was run.

Root attested NEW Watching for mainowned-a3 (epoch1794872215); its180s native
CITY crafting/travel/UI watch expired at180.009s:36gaps,4slow callbacks,0errors.
The r57-family border peak was124.0745ms (commit49.5446,mesh31.0705;
plan39.5957,fallbackMesh20.1392;geometry14.633,solve19.9651). This is not exact
loaded-hash adoption, combat/group/FPS acceptance or an A/B improvement. Zero
retained combat gaps does not prove zero transitions; counters are absent.

NEW CF57saved retention was attested; old spikeWatch was restored exactly and
new CF57result matches the held new report; CF57prev stayed absent/untouched.
Mainflush transport acknowledgment is false because its PNG showed Loading;
fresh on-disk capture timestamps plus matching CF57result prove reload/save
separately. scriptProfile0/maxFPS120/Bk30 stayed; no SetCVar was used.

Only Root owns Mario main-client diagnostics; Bank commands0, entirely excluded.
No second watch is active as last confirmed: CF58 main-owned background preflight
timed out without input/command/journal/lease; controller preparation is not arming.
Future600s admission stays pending fresh Root confirmation. Goal ACTIVE; native
combat/group acceptance and changed-layout builder latency remain open.
[Exact R57 source, scoped replay, curated native evidence and limits](validation/border-wake-owner-r57-2026-11-17.json).
<!-- /COMBAT-CALLBACK-WORK-20261116 -->

<!-- NATIVE-TEST-HOLD-20261116 -->
16 November: the user explicitly prohibits all in-game testing until they say otherwise. Do not run game tests, native Lua/profiling, input, client/window/process inspection, screen captures or saved-diagnostic collection. Previous passive observations remain historical only. No native action from this chat or its assigned agents is live or queued. Offline source work and standalone regression checks may continue; the overall lag goal is ACTIVE. Automatic goal continuations do not release this restriction.
<!-- /NATIVE-TEST-HOLD-20261116 -->



<!-- COMBAT-FANOUT-20261116 -->
16 November combat fan-out (`COMBAT-FANOUT-20261116`): three further offline fixes are
applied. Full class/spec/combat/rest visual refreshes now skip only matching
native geometry; both trinket squeeze/recovery passes retain Style/arrow/border/
clip work while matching geometry setters stop repeating; exit notifications
reuse five protected callback bodies with the same current lookup/order/arguments.
496 offline scripts PASS/1 new shadow assertion FAIL; 1187 syntax PASS; composed current-source observations; owned runtime stable. StockLua5.1 runtime compilation:
690 files/max53 captures; eleven unchanged BOM files use external BOM-only
compiler inputs, without installed edits or native-loader certification.

Modeled30 entry writes210to0/rest300to0 add210/300 getter reads. Modeled10 exit
notifications retain20 trinket squeeze calls/40 styles/40 clips;260 geometry
writes become0 with260 extra reads. Exact comparisons may miss native float32
rounding; no native CPU/FPS/pixel/taint gain is claimed. Whole notification body
model default CPU medians51 .180to.160s and54 .169to.145s per100k calls; callback
counts retained, allocation585.9375to0KiB/5000 calls.51empty CPU .039to.040s and
load-window heap limitations remain recorded.

All three border prototypes remain REJECTED/UNAPPLIED despite exact modeled
scene/native-read parity:360 cost samples expose common CPU regressions. A prior
passive saved watch recorded258.9176ms border cost (planning101.7966/commit90.8235),
but lacks loaded-source/transition provenance and proves no current native gain.
The overall lag goal remains ACTIVE. In-game testing/inspection is prohibited
until the user explicitly releases the hold; automatic continuation is no release.
The new unowned shadow assertion was retained and fails identically with exact
pre-root Core+Strip on both Lua VMs. Renderer versus model/sampler correctness
remains unresolved; the three optimizations are outside that test's dependencies.
No native action is live/queued. [Requirements CF01–05, exact sources, all tradeoffs
and remaining checks](validation/combat-fanout-2026-11-16.json).
<!-- /COMBAT-FANOUT-20261116 -->



<!-- COMBAT-FANOUT-FINAL-POSTCHECK-20261116 -->
Final offline postcheck: the three owned combat runtime files and five
owned tests remain identical to their verified sources. The recorded composed
gate is 496 PASS / 1 baseline-equivalent shadow assertion FAIL, with 1187 syntax
passes. A bounded final replay preserved exact updated shadow-test bytes and
failed the same first sample on both VMs with current and exact checkpoint
renderer dependencies. Concurrent shadow-test work continued after collection:
the final documentation checker reported stale `tests/border_shadow_material.lua`
inventory and a changed `tests/border_junction_shadows.lua` verification hash.
These failures and exact snapshots are retained; current whole-corpus acceptance
is OPEN. No owned native action is live or queued. In-game tests/inspection stay
HELD until explicit user release. [Final postcheck and evidence](validation/combat-fanout-2026-11-16.json).
<!-- /COMBAT-FANOUT-FINAL-POSTCHECK-20261116 -->

<!-- GROUP-COMBAT-SPIKES-20261116 -->
16 November combat-first transition audit (`GROUP-COMBAT-SPIKES-20261116`): applied seven bounded
fixes across stance geometry, unsupported assistant binding, duplicate hidden
TrinketMenu regen recovery, per-pass nameplate quest lookups, minimap indicators,
raid fallback discovery and LFG bursts. Fresh native-state checks, full paint/
binding repair, original error/retry/order semantics, aura cadence and saved data
remain. 491 scripts/1181 syntax PASS; final Lua corpus stable. Lua5.1 compiler:690 runtime files,
max53 captures; eleven unchanged third-party BOM inputs compiled externally after
removing only their initial UTF-8 BOM. Initial raw compiler/fixture failures stay
recorded. No native timing/FPS/taint/pixel acceptance is claimed.

Combat remains the user's priority. Broad player entry visuals and squeeze exit
dependent fan-out still need attribution; neither was blindly suppressed. Both
combat-icon placements remain because name fitting needs the first icon's width.
Current native acceptance and the historical218–232ms border hitch remain open
in this slice. Concurrent event-reflow-r54 border/raid/focus edits are preserved.
No client input/focus/clipboard or profiler/settings changes. Source/history and
eight available settings metadata entries verified outside AddOns before edits.
See [exact sources, work proofs and remaining combat checks](validation/group-combat-spikes-2026-11-16.json).

CT18: Inventory group transitions alongside combat, including raw/secure visibility
and actual TOC ownership. The current union includes602 Lua files/625 paths;
104 files mention tracked transition tokens and19 mention group tokens. These
are source-reference counts, not live native callback counts.

CT19: Reduce only verified duplicate transition work and preserve recovery.
Seven scoped fixes and their negative controls are recorded in the evidence.
The final gate is frozen; initial extractor failures and the rejected overly broad
TrinketMenu consolidation are retained. Native first/repeated combat, friendly
dispel/class paint, secure input, taint and matched timing acceptance remain open.
<!-- /GROUP-COMBAT-SPIKES-20261116 -->

Change `COMBAT-TRANSITIONS-20261116` continues the connected-border work. The
user requested finding and optimizing combat entry/exit lag across the whole
addon, preparing stable borders during loading, and rebuilding only affected
parts after a real layout change. Work remains on main in the existing folder.
The accepted border appearance, action IDs, saved data, input, integrations and
refresh cadence remain requirements.

## Requirements and acceptance

| ID | Requirement | Evidence and remaining work |
| --- | --- | --- |
| CT01 | Inventory loaded direct and indirect combat work throughout the addon. | Source ledgers cover raw frames, shared events, deferred work, secure visibility, unit flags and native aura/nameplate work. Reachable source is distinct from callbacks registered in the current native session. |
| CT02 | Attribute entry and exit hitches to individual owners. | Finite `/fluxperf watch` now includes named/light/heavy Combat queues and registration sources for anonymous tier listeners and both combat events. Raw frame callbacks and native rendering remain coverage gaps; frame gaps are not addon CPU. |
| CT03 | Keep diagnostic work optional and bounded. | No new recurring driver, global API replacement, profiler/CVar change or frame scan. Queue timing makes no clock calls without an observer and releases its token when the existing watch stops. |
| CT04 | Reuse prepared border geometry for combat/class/dispel paint. | Existing static/load preparation and current paint sinks retained. Native R41/R39 transition checks remain historical; whole-consumer cold/warm acceptance is still open. |
| CT05 | Reflow only parts affected by actual layout changes. | Current border caches reuse validated prepared operations; first grid/Info reflow still causes a measured hitch. Native R50 total218.36ms is unresolved. No performance improvement is inferred from fewer setters. |
| CT06 | Avoid redundant native aura-layout invalidation. | Successful public layout arguments cached per actual addon-owned engine/group/method, invalidated on recreation/failure. Full aura refresh and fresh membership/frame queries retained. Dedicated1702 checks and14 focused scripts PASS; native timing pending. |
| CT07 | Correct minimap placement without repeatedly resetting already-correct native state. | Fresh-state idempotence investigated; no persistent position cache. Implementation and acceptance recorded in the validation report. |
| CT08 | Preserve consumable secure recovery while reducing redundant writes. | Blind removal of forced refresh rejected: it fails native item-attribute recovery after a setter failure. Conservative actual-applied-bundle work is under review; no change to action slots/modifier routes. |
| CT09 | Preserve all required refreshes, binding repair and combat-lockdown deferral. | No queue reordering, dropped callbacks, timer/cadence changes, native aura refresh removal or protected-operation bypass. Error and reentrant-lockdown regressions required. |
| CT10 | Support the existing client targets. | Existing pinned Retail, Forever and Classic progression sources retained; Era/Anniversary regression models remain supplementary. Native Forever is the user's test route; other native clients pending. |
| CT11 | Keep exact source, checkpoint, settings and measurement scope. | External source/history checkpoint `combat-whole-addon-before-20261116T150228Z` verified; private settings remain outside AddOns. Baseline/candidate work proofs and native samples recorded separately. |
| CT12 | Verify first and repeated combat transitions without competing test jobs. | Complete owned CPU/test/docs jobs before native capture. Pending native enter/exit, friendly dispel/combat paint, target/focus transitions, secure input, taint and visual parity acceptance. |
| CT13 | Prioritize the combat-exit border hitch and rebuild only changed parts after dragging actions. | User renewed this priority after R51 validation. Prepared numeric per-piece/per-operation plan reuse is under investigation; full current privacy/geometry validation and exact output remain required. |
| CT14 | Keep the action strip's top edge seamless when only some buttons are shown. | User screenshot `codex-clipboard-5fd4187d-48a0-4764-b0c6-1cbba99bf2b6.png` shows the remaining partial-occupancy case. Actual strip/slot ownership audit and reproduction pending. |
| CT15 | Restore combat red tint through paint on prepared unit borders. | User identifies tint exit as a lag trigger. Trace normal→red intermediate paint, repeated identical public paint and deferred outer-layout work. Opaque alpha must continue directly to native sinks; combat/dispel/class colors and priority must remain correct. Native cause and timing require separate confirmation. |
| CT16 | Avoid embedded-minimap toggle hitches with side buttons present. | Quiet native R52 toggle:232.41ms border build,274ms frame gap. Synchronous UI transactions are outside shared-service observer coverage; zero slow service callbacks does not clear the border builder. Preserve final dimensions and the current embedded/side-button behavior. |
| CT17 | Reduce work in every builder phase while retaining exact output and native guards. | Reuse immutable plans for unchanged operations; reduce solver discovery and repeated commit traversal. Fresh source/private/mask/geometry checks, budgets, transactional rollback and current paint ownership remain required. Native timing acceptance remains open. |
| CT18 | Investigate severe party/raid join and leave hitches alongside combat exit. | Trace loaded roster handlers and their focus/aura/outer-shell layout bridge. Preserve secure roster reconciliation, real geometry changes and notifications; repeated unchanged events should not reset the same layout. Native attribution and acceptance remain pending. |
| CT19 | Keep repeated direct unit opacity writes on prepared paint. | The static-unit SetAlpha hook still visits derived fields for identical public authored alpha. Test public idempotence separately from the existing SetVertexColor guard; changed/opaque alpha, source suppression and fallback ownership must remain correct. |

## Findings

The current priority is the builder's genuine layout-change cost. The user
confirmed R52 loaded and still reports a severe hitch. A quiet embedded-minimap
toggle with side buttons measured232.41ms:19.01ms geometry,50.60ms solve,
88.94ms plan and73.45ms commit. Fallback planning took47.33ms; mesh commit took
41.80ms. There were317 operations,521 fragments and3673 triangles. The observed
274ms frame gap is a separate correlation. This raw UI transaction produced
zero slow shared-service callbacks, which does not contradict its direct border
phase measurement. No repeated-solve storm was established for this toggle.

R53 has95 focused script passes against that baseline; native timing remains pending. Immutable full-operation fallback
plans now reuse unchanged numeric fields after fresh source descriptors, and
solver pair discovery uses per-pass identity keys. These changes do not reuse
old native positions or private paint values. Cold preparation and warm/local
reflow costs are recorded separately; reduced work counts alone do not establish
the native hitch improvement. Action-strip visual/mapping changes remain held.

The preceding R52 priority was unit-frame out-of-combat and combat-exit paint.
Action-strip drag/seam changes and wider module optimizations are held. Runtime
`static-unit-paint-r52` now skips derived repaint only when both the previous and
new authored RGBA are identical public values. Native source suppression and
fallback visibility work still run; opaque opacity always reaches the approved
native sinks. The actual producer/prepared-renderer replay found2037 redundant
derived opacity reads in a type2 seven-surface exit refresh; the guard removes
those reads without removing real color/opacity changes. Dedicated98 checks and
12 focused scripts pass. Native latency, taint and pixel acceptance remain open.
The final-portrait producer now chooses normal/combat paint once; party portrait
material classification still updates while red. The100-stage3560-check producer
regression and20 focused scripts pass, including class/NPC/default/custom,
friendly dispel, restricted-opacity and event/deferred-layout routing cases.
Actual native unlocked `UpdateOuterBorder` still has a separate geometry path;
these paint fixes do not establish that every exit callback avoids rebuilding.

WowSim was reviewed read-only at commit
[`c85495655605de1f3756cc0824c4c7faa30be2a3`](https://github.com/Photronix2020/WowSim/commit/c85495655605de1f3756cc0824c4c7faa30be2a3).
Its Lua/event sandbox could supplement public-state regression tests. Its
[widget model](https://github.com/Photronix2020/WowSim/blob/c85495655605de1f3756cc0824c4c7faa30be2a3/lua/widgets.lua)
omits the vertex offsets our junction triangles require and differs from the
observed Forever recolor/alpha coupling. The
[documented limits](https://github.com/Photronix2020/WowSim/blob/c85495655605de1f3756cc0824c4c7faa30be2a3/README.md)
and security/performance stubs prevent native taint, private-value, pixel and
FPS certification. Nothing was installed, executed or vendored for this review.

The confirmed native border owner is Scheduler structural callback token
`border.junctions`. The genuine layout change widened the noncombat grid from
95.788 to128.278 and moved Info from101.656 to134.146. Idle counters and paint
checks do not explain that rebuild: its geometry/plan/commit work must improve.
Quiet R49 total207.94ms and R50 total218.36ms remain failures of the hitch goal.
R50 spent26.03ms reading geometry,31.48ms solving,93.71ms planning and66.15ms
committing. Its fallback planning alone took59.16ms despite only3292 candidate
probes. These are inclusive phase measurements from the user's native capture,
not an FPS result or a sum of unrelated frame gaps.

The broader audit found unconditional native aura-group layout writes, repeated
consumable secure item/key work, stance layout on combat exit, broad secure aura
candidate invalidation, nameplate refreshes, minimap enforcement, and duplicate
player visual geometry through both regen and unit-flag events. These are
source/work candidates until individually measured; legitimate state, usability,
aura, secure binding and deferred-layout updates cannot simply be removed.

Legacy EBS Events/Button/Flyout and refresh files outside the actual TOC loading
closure are explicitly excluded from native owner claims. The Collector sweep
is a no-op on Forever. Raid HoT description learning may depend on changing
spell/equipment state and has not been cached speculatively. Guild-bank and
void-storage behavior remain unchanged.

## Validation scope

See [structured evidence](validation/combat-transitions-2026-11-16.json) and
[border evidence](validation/border-connections-2026-11-15.json). Desktop work
counts and exact state checks establish their stated regression scope only.
They do not certify native latency, pixel rendering, secure input or taint.
Decorative borders add no controller focus stops; existing controller routes
and bindings remain unchanged and native acceptance is pending.

<!-- BORDER-EVENT-REFLOW-R54-20261116 -->
Current border runtime is `event-reflow-r54`: public direct-opacity reuse, bounded
commit-phase observer-pair reuse, fresh matching outer-shell guards, and
roster-only prepared focus-layout reuse. All required paints and notifications
remain. 129 current focused scripts pass; no native latency/FPS/taint acceptance
is inferred. Genuine layout changes still require fresh global discovery/solve.
[Sources, getter tax and native checks](validation/border-event-reflow-2026-11-16.json).
<!-- /BORDER-EVENT-REFLOW-R54-20261116 -->

<!-- ACTION-STRIP-BORDER-R55-20261116 -->
R55 `strip-updates-r55`: matching occupied-swap layouts skip redundant decorative
writes/player-layout fanout using fresh native geometry; nearby strip/envelope
crests align in both types. 144 focused scripts pass. Real packing/expansion and
all mapping/binding recovery remain. Actual drag prefixes had0cache hits, so no
extra cut cache was admitted. Native checks are deferred by the user.
[Requirements](ACTION_STRIP_BORDER_UPDATES.md); [scoped evidence](validation/action-strip-borders-2026-11-16.json).
<!-- /ACTION-STRIP-BORDER-R55-20261116 -->
