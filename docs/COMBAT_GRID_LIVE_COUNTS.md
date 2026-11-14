# Combat grid live consumable counts

## All seven real button modules audited together

11 November 2026 — CONSUMABLE-ALL-BUTTON-AUDIT-20261111. The user explicitly requests checking every consumable type with both providers across all five supported clients while preserving bounded work. The current shared loading repair covers every main kind; this audit adds stronger regression coverage and makes **no additional runtime changes**.

| Requirement | Audit / observed desktop result |
| --- | --- |
| CGLC-23 Real module ownership | Food, water, healing potion, mana potion, bandage, mana gem and healthstone all execute their actual Create functions in one inventory; actual noncombat and combat SetCount implementations used |
| CGLC-24 Shared loading recovery | Three repeated loads per profile, with all faces depleted, leave the hold and recover to dark 0 in combat and placeholders after regen |
| CGLC-25 Independent use and refill | Consume each type while six remain owned, validate all faces, refill without provider publication; one type cannot leave another digit pinned |
| CGLC-26 Preserve charged ownership | Both gem policies and client-dependent stone charges; physical charged remnants with uses 0 are empty uses; bound refill restores digits/tint |
| CGLC-27 Keep work bounded | One shared use watcher; 100 same-frame signals produce one immediate and one 100ms settle callback, 14 recounts total for seven; 100 unrelated item events add 0 work; measured idle 12s adds 0 scans/timers |

[The integrated regression](../tests/consumable_all_buttons_recovery.lua) passes **2,580 checks across 20 profiles** (five existing client branch models x two providers x two gem policies). Three alternating matched pairs reject the exact earlier native-failing source with 940 failures; current code passes each pair. Ten harmful controls are rejected: missing live refresh for each of seven kinds, positive-pinned gem/stone counts and removed burst coalescing. Full 308 scripts/981 syntax checks pass with every normalized source entry current. The existing 672 transition checks retain next-owned promotion coverage; loading, live counts/use events, parked-paint trace, Index, Syndicator, option and input tests remain green.

All seven Create/count owners were inspected. The old FluxInv event scanner has a similar load holder but is outside the active TOC closure; the live compatibility bridge delegates to current inventory. The source guard confirms **every preexisting Lua/XML/TOC file is unchanged** during this audit; only one new test is added. The external 2,585-file source/history checkpoint, 55 settings metadata entries, exact hashes for 15 relevant runtime files and 75 read-only matching installed copies are retained in [audit evidence](validation/consumable-all-buttons-audit-2026-11-11.json). Existing user sync supplies installed copies; no manual propagation occurred.

Native acceptance remains pending for the current loading repair. This is a logic/work audit with mocked game APIs/widgets; it does not establish real client event delivery, protected execution, pixel parity, controller input, memory or FPS. Load the repair with OOC reload if needed, then retest loading/use/refill; during a recurrence retain `/fluxinv buttons` output before another reload. No new options, translations, frame, timer, event, ticker, background polling, action/input route or saved data is introduced by this audit.

## Native capture: loading completion left open

11 November 2026 — CONSUMABLE-LOAD-END-20261111. The user's failing-state capture now identifies a persistent phase hold: `reliable=true hold=true load=true`. Food 1487 still displays/forces 1 while physical slots, Syndicator snapshot, modern API, legacy API, wrapped count and uses all report 0. Other assigned items in this capture agree with their carried counts. This is native failure of the preceding candidate, not a native pass. Both API counts agree here; the open loading latch is sufficient to explain why normal updates preserve the stale food digit. The earlier native event sequence was not captured.

| Requirement | Implementation / acceptance |
| --- | --- |
| CGLC-19 Complete loading independently of world entry | Existing inventory event owner also handles validated optional `LOADING_SCREEN_DISABLED`; no later PEW is required |
| CGLC-20 Resume cancelled facts and bounded recovery | Only an unfinished load restarts the existing world slot-refresh generation and portal settle; count/identity recovery uses existing fan-out |
| CGLC-21 Preserve work and protected ownership | Normal PEW and repeated disabled events add no work; newer loads cancel old refreshes; existing grace, real-loading hold, combat actions, regen, providers and saved settings remain |
| CGLC-22 Reject the captured failure pattern | All source counts 0 with positive held digit reproduced across all seven kinds, both providers and five client models; native candidate retest remains pending |

[The one runtime change](../Inventory/Init.lua) adds the missing completion subscription and a guarded handler. Previously loading start cancelled world refresh and opened an indefinite Best latch; only PEW could close that latch. Loading screens without another PEW, or beginning after PEW, therefore stayed held after inventory became reliable. The completion handler restarts the cancelled existing slot refresh and enters the existing 2.5s portal grace. It does not bypass genuine loading protection or write protected actions. There is one additional low-frequency event subscription, no new frame, ticker, timer call site, hook, background poll, settings, localization surface or input route. Optional registration failure preserves ordinary PEW recovery.

[Loading completion regression](../tests/consumable_loading_end.lua) passes **2,230 checks across 240 scenarios**. Three alternating exact-checkpoint/candidate pairs fail 660 checks before and 0 after; five harmful controls are rejected. Full 307 scripts / 980 syntax checks pass with every normalized source entry current; previous loading/count/use/depletion, parked-paint budgets, Index and Syndicator tests remain green. Five exact Gethe LoadingScreen blobs verify at the retained five-client session pins. External 2,583-file source/history checkpoint, 55 settings metadata entries and five read-only matching installed runtime hashes are retained in [validation evidence](validation/consumable-load-end-2026-11-11.json).

The captured native failure is established; **the new candidate's native acceptance is pending**. Reload to load this handler, then retest loading and food depletion. OOC should promote another owned food or show its empty placeholder; combat keeps the prepared action with dark 0. If a wrong face remains, capture `/fluxinv buttons` before another reload. No client foreground/input, settings/profiler write, manual propagation or publication occurred.

## Screenshot follow-up: count sources and loading holds

COUNT-SOURCE-RECONCILIATION-20261111 — the user again reports intermittent stale water, mana gem, healing potion and bandage faces, and explicitly includes food, mana potions and other inventory-backed extra buttons. The supplied screenshot is retained externally. The requested bad-state diagnostic was run while the problem was absent: `syndicator`, reliable `true`, soft hold/load hold `false`, and gem unbound. That healthy sample does not identify the screenshot's native trigger, and no failing-state raw count trace is claimed. The follow-up food/water probe printed no rows (user: "there is nothing"); it exposed no item ID to compare, so modern/legacy API agreement and actual ownership remain unverified. Module names and shared Button attachment were checked against current source; this reply requires no runtime change.

| Requirement | Implementation / acceptance |
| --- | --- |
| CGLC-14 Correct loading phase handoff | First login/reload/missing-argument world entry closes the open-ended consumable loading latch; deferred startup alone cannot close a genuine loading screen |
| CGLC-15 Release count-only holds | The existing portal-grace callback publishes shared inventory recovery even when the selected Best identity stays unchanged; existing listeners restore live counts and selection |
| CGLC-16 Honor carried zero | A successful modern bag-only zero cannot fall through to a stale positive legacy result; nil/error/legacy-only and existing extended bank/reagent/account compatibility remain |
| CGLC-17 Capture intermittent facts | Optional `/fluxinv buttons` prints seven known faces plus up to twelve other item faces, physical carried slots, provider snapshot, raw APIs, wrapped count, use count and hold/text state; opaque text is redacted |
| CGLC-18 Preserve ordinary operation | No new frame, event, ticker, background scan, settings/default/profile change or input route; existing count/tint/regen/placeholder/charge/durability/equipment owners remain |

Production replays reproduce three shared defects left outside the earlier paint/use-event tests. `LOADING_SCREEN_ENABLED` can open Best's hold before the first `PLAYER_ENTERING_WORLD`; the login branches previously started a new inventory hold without closing Best's open flag. Separately, ending the shorter portal grace requested only a Best recompute, which can leave count latches untouched when the identity is unchanged. Finally, `Flux.Item.GetCount` discarded a valid modern zero and could return a stale positive from the deprecated global.

The correction changes the count source and recovery owners: [item API](../Core/API/Item.lua), [inventory](../Inventory/Init.lua), [Best phase state](../Inventory/FluxConsumableBest/Init.lua) and [Best world-entry owner](../Inventory/FluxConsumableBest/FluxConsumableBest.lua). It adds no further painter workaround. World-entry callers explicitly mark the phase transition; normal startup remains guarded. The original portal timer now uses the existing inventory recovery fan-out. Zero authority applies to carried-only queries; the existing extended-location fallback is preserved.

[Hold regression](../tests/consumable_hold_reconciliation.lua) covers first login, reload, omitted world-event arguments, deferred inventory startup, genuine long loading, portal grace after earlier inventory recovery, all seven kinds (both gem policies), five client models and both providers. It also checks the diagnostic's read-only behavior and opaque-text guard. [Count-source regression](../tests/item_count_zero_authority.lua) covers the seven kinds plus other item IDs, positive/zero results, deprecated API disagreement, absent/failed APIs and strict legacy bank signatures. Exact matched checkpoint/candidate runs, harmful controls, raw outputs, hashes and the final full-suite/documentation results are retained in [source-reconciliation evidence](validation/count-source-reconciliation-2026-11-11.json).

Final desktop validation: **2,104 hold/diagnostic checks +245 count-source checks** pass. Three alternating matched pairs reject the exact checkpoint with 583 and 150 failures respectively; eight harmful controls are rejected. All 306 scripts and 979 syntax checks pass with every normalized source-manifest entry current. The prior 2,175 live-count,1,219 use-event and 672 depletion-transition checks remain green; parked-paint trace/budgets and Index/Syndicator checks remain unchanged. For 100 successful carried-zero queries, deprecated fallback reads drop 100 to 0 while modern reads remain; this is a call-count result, not native timing. All 20 installed runtime copies match through the user's existing sync. 22 fresh pinned source records, the verified 2,580-file source/history checkpoint and 55 settings metadata entries remain external; no private settings are copied.

The on-demand diagnostic performs one physical carried-slot read when explicitly invoked; it creates no ongoing driver and writes no settings or protected actions. Its English field names form a developer diagnostic schema, matching the existing `/fluxinv` command. Nonconsumable equipment/durability/collection behavior is not replaced with a blanket stack-count policy. Guild-bank/void callbacks remain outside scope.

**Native acceptance remains open.** Reload to load the source correction. If the bad faces reappear, run `/fluxinv buttons` while they are still wrong and retain the output before another reload. This separates an actual API disagreement, a held digit and a mismatched display owner. The supplied screenshot proves the prior symptom; source inspection and desktop replays do not prove the candidate fixes the intermittent native case, pixels, secure permissions, input, memory or FPS. No client foreground/input, private settings/profiler write, manual sync or publication was performed.

## Native symptom follow-up: use events and depletion transitions

10 November 2026 — COMBAT-GRID-USE-EVENTS-20261110. The user confirmed the first candidate still showed a dark mana gem with `1` on Forever with Syndicator. That is a native baseline failure; earlier mock passes did not establish a native fix. The clarified requirement applies to all seven kinds and both providers: combat retains the prepared action with **dark `0` for its exhausted item**; outside combat select the next owned usable item, or the empty placeholder.

| Requirement | Correction and evidence |
| --- | --- |
| CGLC-07 Count use-only signals | Existing watch handles common `BAG_UPDATE_COOLDOWN` and optional modern `ITEM_COUNT_CHANGED`; no provider publication required for known carried faces |
| CGLC-08 Repair the visible digit | Count-cache hits compare existing readable text with the desired text; another `SetCount` writer leaving visible `1` cannot suppress a requested `0` |
| CGLC-09 Bound event work | One immediate recount and one 100ms settle callback per same-frame use burst; no predicted decrement, permanent ticker or additional frame |
| CGLC-10 Keep both providers current | Explicit grid kinds read live carried copies through the existing facade; generic non-grid and ordinary built-in delayed-bag work retain their original paths |
| CGLC-11 Preserve safe lifecycle | Loading holds, optional-event registration failure, dead/ghost behavior, parked work budgets, actions, keys, controller ownership and saved settings remain |
| CGLC-12 Dark zero in combat | Count and tint follow the displayed item, including a prepared gem macro when another gem tier is still owned; no protected action rewrite |
| CGLC-13 Promote or placeholder OOC | Specialized gem/stone updates run after observed depletion; reliable exhausted gems clear the sticky item face; known conjured recharge/reacquisition can return from the placeholder |

The previous fallback listened only for delayed bag updates. Cooldown-only use could therefore leave all seven digits unchanged. Separately, the painter accepted a cached `0` even if another owner had written a nonblank `1` to the same FontString. Both omissions are reproduced by [use-event regression](../tests/combat_grid_use_events.lua): **1,219 checks**, 80 client/provider/item scenarios, three alternating checkpoint/candidate pairs and seven rejected harmful controls. The exact checkpoint fails **817** checks; the candidate passes all checks. A burst of 100 use notifications per scenario produces 80 immediate recounts and 160 including the single settle pass across all scenarios. This adds required work the baseline omitted; it is not a CPU/FPS speedup claim. Ten idle seconds add no polling, scans, frames or secure rebinds.

[Transition regression](../tests/combat_grid_depletion_transitions.lua) adds **672 checks** for dark zero, current-item tint with another gem owned, promotion on regen, OOC empty placeholders, known conjured reacquisition, and stack-unchanged charge recovery. Three exact pairs reject the checkpoint; five additional harmful controls are rejected. The existing count regression still passes **2,175 checks**. The 340-check parked-paint fixture retains its previous visible trace and work counters, and unrelated bag bursts still cause no selection/classification/rebind work.

This clarification intentionally supersedes the earlier empty sticky-gem behavior: a reliably exhausted OOC gem now uses the placeholder instead of keeping a dead item action. Load-screen latches still retain their prior face. The old smoke's OOC-zero expectation was updated to require the placeholder; its refill check remains and passes. Four comment-string assertions in the bars smoke were replaced with the actual transition regression, including owned-gem brightness when the other tier is missing. No acceptance check was removed without replacement.

The same source pins below were freshly resolved for this follow-up, and 22 downloaded source records were verified against their Git-tree blobs. `ITEM_COUNT_CHANGED` is declared for the pinned Retail/Forever sources; Classic-family clients use the common cooldown signal and tolerate unavailable optional registration. Three strict mock initialization checks reject the optional event safely. Source declarations do not establish actual addon registration/delivery in a live client.

The dated external `checkpoint-20261110T175623Z` preserves 2,566 files and verified history on main. Initial settings inspection retained 33 metadata entries, with a 22-entry supplement from the actual `_anniversary_` installation; private settings were not copied. Only the three runtime owners (shared bind, paint, mana gem), two new regressions and two existing test fixtures change in this follow-up. Settings, input/profiler preferences and other runtime owners remain unchanged.

The final full-suite result, exact task hashes, matched samples, controls, source verification, read-only installed-copy receipts and documentation check are recorded in [follow-up evidence](validation/combat-grid-use-events-2026-11-10.json). User synchronization owns cross-client propagation. The actual candidate symptom, native combat/taint/permissions/pixels/controller or physical input/FPS/memory remain **NOT RUN**: this host has no connected native/simulator/input tool. Do not treat the passing desktop counts as a native pass.

After the updated files arrive through the user's sync program, **reload the client**. In combat, consume the displayed last item or final charge and verify dark `0`; leave combat and verify the next owned item or empty placeholder. Repeat OOC depletion, refills/recharge, and a loading transition. Right-click creation/crafting and existing bindings remain with their original owners. No manual sync, client input/focus, settings/profiler write, commit or publication was performed.

## Initial bag-event correction (historical)

10 November 2026 — COMBAT-GRID-LIVE-COUNTS-20261110. Correct intermittent stale counts after using food, water, mana potions, mana gems, healthstones, bandages and healing potions, with and without Syndicator. Preserve update speed, appearance, secure actions, bindings and saved data.

| Requirement | Implementation and acceptance |
| --- | --- |
| CGLC-01 All seven consumable kinds reach zero | Native bag events recount all seven; repeat paint cannot restore a stale positive count |
| CGLC-02 Both inventory providers | Built-in snapshots retain their existing dispatch; Syndicator uses the existing live-count facade while publication waits |
| CGLC-03 Charges and carried copies | Single-use gems/stones use live copies; charged items use remaining uses with the existing multiple-copy display policy; noncarried charge answers cannot restore ownership |
| CGLC-04 Combat and recovery | Zero/tint update without secure writes; existing regen owners settle selection; loading holds retain the previous count and expire normally |
| CGLC-05 Bounded work | Same-frame native bag-event bursts coalesce to one recount; no new frame, ticker, polling interval or full-bag scan; disabled empty craft buttons schedule no additional callback |
| CGLC-06 Client/data parity | Retail, Forever, Classic progression, Era and Anniversary models; existing optional integrations, controls, profiles and persistence remain; native acceptance recorded separately |

## Cause and correction

The earlier Syndicator native-event fallback listed only five kinds. Mana gem and healthstone overrides could therefore wait for a provider callback even after native item counts changed. Syndicator v290's `Tracking/BagCache.lua` delays `BagCacheUpdate` until pending item metadata resolves. A separate paint path still read provider snapshot copies, including single-use conjured items and multiple charged copies. Plain-item forced counts also retained a positive-count tint exemption intended for loading holds.

[ConsumableBind](../ExtraButtonSystem/Engine/ConsumableBind.lua) now validates live carried copies before the charged/single-use split, includes both conjured kinds in its existing native-event watch, and coalesces count work at `After(0)`. Craft invalidation retains its original timing and existing disabled-feature gate. Empty untracked buttons do not queue this recount. Combat selection remains deferred to the existing owners.

[Paint](../ExtraButtonSystem/Engine/Paint.lua) reads the same live carried copies for recognized Syndicator consumables and passes that result to the charge query without another copy lookup. Known single-use and charged policies stay in `Flux.Item`. Ordinary count writes keep live tracking; only actual reliability holds freeze a count. Generic nonconsumable/equipped faces retain their prior snapshot ownership contract. Built-in snapshot dispatch is unchanged.

This corrects counts and empty tint; it adds no UI design, configurable preference, visible text, focus stop, input handler, macro policy or SavedVariables field. The existing direct-implementation and user-reproduction testing route is retained. Controller/key/mouse actions keep their current owners; native controller/physical-input acceptance is NOT RUN.

## Evidence

The dated external `combat-counts/checkpoint-20261110T165303Z` contains 2,550 verified source files and a verified Git history bundle from main `26f886e3ea5371b196ab235d2dace0c156002285`. Available on-disk settings were inspected as 33 read-only metadata entries; no private settings were copied and no quiescent settings backup is claimed. The full location is recorded in the [evidence record](validation/combat-grid-live-counts-2026-11-10.json).

[Regression](../tests/combat_grid_live_counts.lua) loads the production inventory, selector, shared binding and paint code plus the actual specialized mana-gem/healthstone modules. Five client models and two providers cover eight cases each (both single-use and charged mana gems): 2→1→0, repeated paint, charge remnants, stale provider callbacks, refill, uncached metadata, load holds/expiry, combat writes and regen. The test also preserves generic equipped-item ownership.

Three alternating matched pairs each reject the exact checkpoint with **244 failures** and pass the candidate's **2,175 checks**. Seven harmful controls are rejected: omitted conjured events, snapshot-only paint, stale conjured ownership, uncoalesced events, frozen ordinary counts, generic equipped-count adoption and retained empty charges.

For forty provider fixtures, each receiving a burst of 100 native delayed-bag events, recount calls change **2,500→40** and instrumented native count queries **2,500→159**. The baseline omits the fifteen conjured fixtures entirely; the candidate adds their required refreshes. These synthetic work counters do not establish native CPU/FPS or a percentage speedup. No bag classification scan, secure rebind or new frame occurs in these combat bursts. The earlier hidden-button performance fixture retains its 340 passing checks and previous visible trace/counters.

The full desktop suite completed **297 scripts / 969 Lua syntax checks** with no failures. These three task files match the tested sources. Concurrent vendor/raid edits in the shared workspace are preserved and have separate acceptance. A subsequent full run overlapped raid edits and failed one raid test; the current test, both other direct aura-owner regressions and the consumable regression then passed in four bounded rechecks with stable inputs. Raw runs and the composed validation record are retained; this is not described as an uninterrupted stable full run. Existing consumable smoke, zero-reset, Syndicator, conjured usability, craft visibility/identity and bag-detection regressions pass. The first candidate's unnecessary empty-disabled-button callback was caught by the existing craft-visibility test and corrected; that test was not weakened. Generated inventories were refreshed. The final whole-workspace documentation check reports four stale inventory/verification records in concurrently edited raid/debuff owners; none concerns these three task files. That check remains pending for the unrelated work, with the actual errors retained in the evidence record.

Run:

```text
lua tests/combat_grid_live_counts.lua
python tests/run_validation.py --output <external-result.json> --sync-docs
python docs/tools/build_reference.py
python docs/tools/validate_docs.py
```

## Source contracts

All five Gethe branches were resolved once for this task. Twenty-two downloaded source records were verified against their exact Git-tree blob identities. Item declarations retain separate `includeBank`/`includeUses` arguments; container declarations retain `BAG_UPDATE_DELAYED`. The fix reuses the existing client count wrapper and event registration. Declarations and loaded-source inspection do not certify native event ordering or addon permissions.

| Client | Source version | Commit |
| --- | --- | --- |
| Retail | 12.1.5.70783 | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` |
| Forever | 1.60.1.70888 | `4cd0ab752a77164f654ccbca9d0c1fe8dafceebe` |
| Classic progression | 5.5.4.70631 | `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` |
| Era | 1.15.9.70576 | `4192ac60067fc55566182291bc67c85dd9b6794d` |
| Anniversary | 2.5.6.70577 | `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` |

Examples: [Forever item count declaration](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), [Retail bag event declaration](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua). Installed builds were not probed. The supplied Syndicator installation is a read-only reference; its TOC, bag-cache source and license hashes are in the evidence record. No third-party code was copied or changed.

## Native acceptance still pending

After the user-managed sync and a reload, test each native client with Syndicator enabled and disabled. Use the last food/water/potion/bandage, single-use gem/stone and final charge of a charged item. Check zero and dimming during combat; refill and better-tier fallback after combat; charged-copy display; repeated paint/hover; conjure/craft right-clicks; existing keyboard/controller use; and a portal/loading transition. Preserve prior diagnostic roots and optional profiler preferences.

No connected Witchcraft/UIForever or computer-use capability is available in this session. Native event delivery, physical/controller input, secure/taint behavior, rendered pixels, persistence, FPS and memory remain NOT RUN. WoW stayed in the background. No client input, private-settings/profiler write, manual cross-client sync, commit or publication was performed; the existing user-managed Retail-only write policy and paused party/raid native work remain.
