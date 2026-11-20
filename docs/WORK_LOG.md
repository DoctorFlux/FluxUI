# Work log

20 November. `FOOD-WATER-STACKS-20261120` passed 27 focused Lua scripts. The
new regression rejects the previous 16-versus-4 selection and covers 20 plus
20/10, count-neutral splits, moved and locked slots, conjured and restore
priority, combo drinks, use keys, combat swaps, and action restoration.
`ExtraButtonSystem/Engine/ConsumableBind.lua` SHA-256 changed from
`42366bf9eec33ae31193378dc58cd980a4c7d28fdbea43bb1b3f99126d65e508` to
`0576edeae4e0e5ae9bcd1987644dff2c3fef4a947d2eb91e2f9ef3bb2e425ebe`.
External checkpoint `food-water-before-20261120T114945440` contains 3,366
verified working files and the complete history at main
`6b444eba4573092b57919ee3e497d86d2ebb3ece`. Two Retail settings files were
verified on disk by metadata. All five installed copies match the corrected
hash. The initial click hook indexed the local `Bridge` accessor as a table.
The focused regression caught it, and the user reported the same error from
the earlier loaded code. The corrected hook calls `Bridge()`.
The broader desktop run compiled 1,251 Lua files and returned 553 passes.
All eight failures reproduced with identical output against the pre-change
source. The focused set was rerun on the corrected file.
[Button behavior](12-extra-button-system.md#smallest-food-and-water-stacks).

20 November. Reproduced the numeric-cap tooltip crash with a native-style
mouse-motion argument. Replayed actual saved structured First Aid recipes
against a modeled incomplete profession book. The two fixes passed 35 Auction
Restock scripts and eight profession scripts. Before editing, verified the
external history bundle at main `6b444eba4573092b57919ee3e497d86d2ebb3ece`,
copied and checked the original touched files in external checkpoint
`auction-known-recipes-20261120T103806Z`, and verified saved settings exist
on disk for every client. No private settings were copied.
[Auction Restock](AUCTION_RESTOCK.md#saved-recipes-and-row-hover).

20 November. Restored source-map hosting at the user's request and deferred the
three Blizzard quest pin refresh events on the hosted Forever map. The desktop
check retains the original scene, addon children, native event script and
normal full-map handoff across combat and reentry. Both previous paths fail
their respective regression checks. [Evidence](validation/world-map-combat-2026-11-20.json).

20 November. Traced the Forever combat-transition report through Blizzard's
World Map quest event to `SetPassThroughButtons`. Routed Forever's Map Pins to
the existing battlefield providers and HBD router. The desktop regression
rejects the prior activation path. The Forever disk copy matches the candidate.
[Evidence](validation/world-map-combat-2026-11-20.json).

<!-- LHO-FINAL-ACCEPTANCE-GOAL-20261120 -->
20 November. Reconciled the inventory, HUD and Round 2 roadmaps with the addon-wide release gates. Recorded six final inventory and casting acceptance checks and rechecked the 90 source hashes. The first live bank setup was unavailable in the checked Forever session. [Inventory acceptance](INVENTORY_PERFORMANCE_ROADMAP.md#final-acceptance-checklist).

<!-- RELEASE-FINISH-LINE-20261120 -->
20 November. Reviewed the development, HUD, inventory and historical stress-test roadmaps. Added the addon release gates and reconciled status with the bounded R187 acceptance round. Rechecked 62 pinned paths against the HUD desktop receipt and 14 runtime paths in each of the five installed trees. All matched. Live results remain pending. [Release roadmap](RELEASE_ROADMAP.md) · [HUD evidence](validation/hud-acceptance-r187-2026-11-20.json).
<!-- /RELEASE-FINISH-LINE-20261120 -->

<!-- HUD-FIXTURE-REPAIR-20261120 -->
20 November. Repaired the render-basis and shadow-material fixtures against the current R187 renderer. The first now tests texture, layer and RGBA setter reuse. The second reads canonical support through the current source reader and the actual Border factory. Two controlled regressions failed at their intended assertions. The expanded 50-script desktop gate passed and the pinned addon Lua stayed byte-identical. [Acceptance evidence](validation/hud-acceptance-r187-2026-11-20.json).
<!-- /HUD-FIXTURE-REPAIR-20261120 -->

<!-- LHO-OPTIMIZATION-CLOSEOUT-20261120 -->
20 November. Ran the bounded closeout across bank, inventory, providers, vendor, Auction, Pending, mail, crafting, casting and party regressions. Fixed the test loader arguments for the bank-charge check and restored exact expectations for the existing parser dispatcher. All 82 scripts passed. The 90 scoped production Lua files compiled and matched all five installed copies. [Closeout](INVENTORY_PERFORMANCE_ROADMAP.md#finish-point).

<!-- LHO-CRAFT-FALLBACK-CATALOGUE-OWNERS-20261120 -->
20 November. Captured the two actual bag-move directions and the native crafting dependency cost. R686 restored the stack and all observers. R687 verified stable selector outcomes and unchanged native counts in four pairs. Replaced the missing jump cue with R100 after correcting the nonce length in local preflight. [Evidence](validation/profession-bag-restock-2026-11-19.json#nativeCraftFallbackBagCatalogueOwners).

<!-- LHO-FIRST-COPY-GRID-RECEIPT-20261120 -->
20 November. R684 armed the single receipt observer and R685 cast Conjure Food once. Both native delayed bag events arrived and all observers were restored. FluxUI and native counts agreed, both grids were checked, and there were zero new Lua errors. [Evidence](validation/backpack-final-callback-2026-11-19.json#nativeFirstFoodCopyGridRoute).

<!-- LHO-CONJURED-CACHE-LIVE-20261120 -->
20 November. R682 reloaded the junk candidate. R680 and R681 recorded loaded cold and warm timings with zero new Lua errors and a stable bag generation. R683 traced the warm protection reveal and restored the closed bag view. R99 replaced the old jump helper and recorded a Space pair with movement unverified. [Evidence](validation/backpack-final-callback-2026-11-19.json#settledConjuredMetadataReads).

<!-- LHO-CONJURED-CACHE-READ-20261120 -->
20 November. Captured a cold category open and a real item metadata read in R678 and R679. Verified the dated source checkpoint, complete history bundle and recorded settings metadata. The new focused checks exposed repeat metadata reads against the exact archive. Updated FluxJunk.lua, passed 1,998 checks across four scripts, and syntax-checked all five matching installed copies and the focused regression. The scratch junk smoke runner fails at the same line on both source versions. [Evidence](validation/backpack-final-callback-2026-11-19.json#settledConjuredMetadataReads).

<!-- LHO-BANK-CLOSE-LIVE-20261120 -->
20 November. R674 successfully reloaded Forever on its third reservation. In R676 the player-opened bank reported 21 live counts. The actual close delivered both events, cleared five public access checks and preserved all 21 cached counts, money and an empty cursor. BugTabs reported zero new Lua errors. R98 restored the 180-second jump helper after reload and logged a Space pair with movement unverified. [Evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeBankSlotMoveAndCloseLatch).

<!-- LHO-BANK-CLOSE-LATCH-20261120 -->
20 November. Recorded the real bank move and return, native close and stale latch reads. Created the inventory performance roadmap, verified a dated source and history checkpoint and settings metadata, and added a regression before editing the bank latch. The archived source fails 85 assertions. The final Lua passes ten scripts and matches all five installs. [Evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeBankSlotMoveAndCloseLatch).

<!-- LHO-BANK-TIER-SETTLED-KIND-20261120 -->
20 November. Captured the player-opened bank and localized pending-summary work to the bank-tier provider. Recorded the interrupted R668 setup and its cleanup in R669. R671 measured six live candidate pairs. Verified the dated source, history and settings metadata, then updated the FluxUI classifier handoff and tier matcher. Eight regressions and eleven syntax checks passed. A separate parser test showed the same pre-existing call-count failure against the archived source. Recalibrated the three-minute helper against the resized client without a reload. [Evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenBankTierKindWork).

<!-- LHO-BANK-VIEW-LOADED-20261120 -->
20 November. Captured actual open-bank Restock button timings, released R664 when the bank closed, and confirmed the R661b reload through fresh startup. Retired R96 after seven Space pairs and rearmed R97. Removed the empty heartbeat chat with Escape. R665 completed six installed timing pairs with unchanged row fields and zero Lua errors. [Loaded comparison](validation/baganator-bank-view-index-2026-11-19.json#loadedFallbackFrameNames). [Open-bank timings](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenBankRestockButton).

<!-- LHO-BANK-VIEW-FALLBACK-NAMES-20261120 -->
20 November. R659 measured actual closed-bank stock, classification and map reads. R660 compared the existing visibility paths with exact candidate fragments. Verified dated source copies, settings metadata and main history before editing Inventory/Init.lua and BaganatorCompat/FluxBaganator_BankRestock.lua. Nine regression scripts and eleven syntax checks passed. Released the reload reservation when the bank opened and captured the native live count and stack comparison in R662. [Visibility evidence](validation/baganator-bank-view-index-2026-11-19.json#fallbackFrameNames). [Open-bank evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenCharacterBankStackParity).

<!-- LHO-RESTOCK-TARGET-ATTRIBUTION-20261120 -->
20 November. Ran R656 and R657 in background on Forever. The first two R658 reservations stopped before input and its third reservation finished. Captured all nine row fields, both inventory generations, money and zero new Lua errors. Reconfirmed the native helper process and one complete key pair. [Evidence](validation/bank-tier-matcher-2026-11-19.json#nativeRestockTargetAttribution).

<!-- LHO-RESTOCK-TIER-RECORD-FILTER-20261120 -->
20 November. R651 timed actual Restock target builds and an exact classifier candidate. After a dated source/history/settings checkpoint, edited FluxRestockTiers_Match.lua. R653 detected the missing classifier alias on the owned closed-bank path. Reproduced it with a failing regression, corrected it, and passed seven scripts and five matching client syntax checks. R654 and R655 loaded and verified the corrected source. R96 rearmed the 180-second helper. [Evidence](validation/bank-tier-matcher-2026-11-19.json).

<!-- LHO-AUCTION-INITIAL-PLAN-PAINT-20261120 -->
20 November. R645 recorded actual warm startup. Verified dated source, history and settings, then updated FluxAuctionRestock.lua and FluxAuctionRestockUI.lua and extended the existing Auction regression. The new test failed before the edit and 44 Auction scripts passed after. Ten syntax checks and five matching installed copies per file passed. R646 reloaded. R648 confirmed the loaded stop points and clean native closure, and R650 restored observers on timeout. R95 rearmed the requested jump helper. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-ROW-ORDER-ALLOCATION-20261120 -->
20 November. R641 timed the exact comparator change against actual Forever Restock rows. Verified the dated source, history and settings checkpoint, changed FluxAuctionRestockData.lua from 5e17c5603a68 to 694f33f6f185, and passed 44 Auction regressions and five Lua 5.4 syntax checks. R642 reloaded. R643 third reservation verified a complete native open and close with ordered row parity, restored its observers and recorded no changes in stock or money. R94 restored the 180-second helper. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-CATALOGUE-REVOCATION-VALIDATION-20261120 -->
20 November. Completed the loaded R636 stack move on its third reservation. R638 read the original timings after two input/drawability guards held. R639 and R640 timed alternate removal lookups using live saved data without applying them. The guarded version lost the timing gain. Verified that the Forever client and R93 jump helper remain running. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-TEXT-ALIAS-20261120 -->
20 November. R632 captured a real positive bag receipt without commerce and restored seven method observers. R633 first used the wrong diagnostic character key. R634 corrected it to the owned resolver and ran eight native timing pairs. Verified dated source, history and settings before updating Professions.lua from 091ba4391223 to 358014c828dd and extending the existing late-converter regression. Eight scripts and six Lua 5.4 syntax checks passed. Five installed source hashes match. R635 reloaded, and both R636 reservations released after stopping before input. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAGANATOR-LAZY-CATEGORY-ICON-20261120 -->
20 November. R629 profiled a real Baganator first open. Verified dated source, history and settings metadata before editing FluxBaganator_CategoryIcons.lua from 813be7c24cb7 to aff900d0a5f8. Two nearby integration regressions and five Lua 5.4 syntax checks passed. R630 reloaded and R631 confirmed the ordinary label allocation result. R92 retired the stale jump worker and installed and calibrated its replacement. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-CRAFT-POTION-FALLBACK-STATIC-20261120 -->
20 November. R626 ran the exact pre-edit comparison against the current live catalogue. After verifying a dated source checkpoint, history and settings presence, edited Inventory/Craft.lua from 853273d8aa9c to 60559e25f69f and extended the existing First Aid regression. Nine scripts and ten syntax checks passed. R627 reloaded. R628 preserved item placement, cursor, both grids and observers with no new errors. R91 rearmed the jump helper. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CAST-WIDGET-ENTRY-INDEX-20261120 -->
20 November. R623 measured 195 real registered buttons and a Food cancel. Verified a dated source and history checkpoint and settings presence, edited Core/ButtonFX/Cast.lua from 2babe5a717f2 to 5188485bfff6, and passed 23 existing scripts and ten syntax checks. R624 loaded and R625 repeated the workload, restored its observers and reported no new errors. R90 restored the three-minute helper. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-AUCTION-SEARCH-PREPAINT-LIVE-20261120 -->
20 November. After a verified nonactivating window restore, R620 reloaded the exact source. R621 completed two live Restock opens and removed the partial R88 cue. R89 rearmed the 180-second worker. R622 measured the actual warm search after the prices aged, restored its observers and closed the panel. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-SEARCH-PREPAINT-20261120 -->
20 November. R617 observed a cold native Auction open. R618 and R619 profiled real warm panels with the row, UI and authorization method identities intact. Verified source, history and settings before changing FluxAuctionRestock.lua from aa07f334b8cd to d82b016c5fc6. All 43 Auction regressions passed. Updated source hashes match five installed paths and ten syntax checks passed. R620 stopped before input because the confirmed window was minimized. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROTECTION-EMPTY-SLOT-LOOKUP-20261120 -->
20 November. R613 timed a live candidate before editing. After verifying a dated source checkpoint, the history bundle and settings presence, changed Respec/FluxRespec_GearSetLock.lua from 3a13b69160be to cdcfe749747c. Six regressions and ten syntax checks passed. R614 reloaded. R615 verified live slots and restored the closed backpack. R87 calibrated the three-minute helper. R616 retrieved 44.32 ms for the first open with a nearby 63 ms frame gap. Baganator layout reached 42.41 ms inclusive, with 21.65 ms in display and 10.364 ms in 53 item-detail calls. Nine layout groups were created. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-NUMERIC-CATALOGUE-OPEN-BAG-20261120 -->
20 November. R612 reopened the category backpack, compared the actual bag-update paths, moved and restored the same stack, restored observers and closed the backpack. No new Lua errors. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-NUMERIC-CATALOGUE-LIVE-BAG-20261120 -->
20 November. Recalibrated the jump cue when the client resized and confirmed the actual 1,890 by 993 client area. R610 reloaded with commerce and professions closed. R86 restored the cue and R611 used the same real move and return trace as R603. Eleven regressions passed. The five installed Professions.lua files parse in Lua 5.1 and Lua 5.4 and match the recorded hash. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-NUMERIC-FULL-CATALOGUE-20261120 -->
20 November. Verified a dated source and history checkpoint and settings presence, updated Inventory/Professions.lua from 30dd26404e9e to 091ba4391223, and added key-collision coverage to the existing catalogue regression. All 3,153 Lua 5.4 checks passed. R606 and R607 produced no live timing. The exact source pair returned all 149 saved rows in order. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAG-MOVE-CRAFT-CATALOGUE-20261120 -->
20 November. R602 and R603 verified two actual 18-item stack moves and returns. Repeated craft list work was identified in R603 and timed by worker in R605. Restored every observer, item location and backpack. R604 aborted during input, then targeted Escape closed the diagnostic draft and R605 cleared the partial Lua root. No production Lua change in this pass. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-RESTOCK-REAGENT-VISIBLE-PASS-20261120 -->
20 November. Optimized Inventory/SpellReagents.lua and Inventory/Restock/Core/FluxRestockList.lua. Eleven Lua regression scripts and twenty compiler checks across five matching client installations passed. Updated a stale test locator to keep checking the actual resolver functions. R600 loaded both files and R601 verified the exact branch and rows. R84 restored the three-minute helper. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-PROFESSION-FILTER-CANDIDATES-20261120 -->
20 November. R590 and R591 timed two isolated recipe ideas against actual Forever data. R595 tested the live filter while preserving its setting. R597 confirmed both trinket actions use wheel bindings and verified one error from the earlier diagnostic frame enumeration. The diagnostic error remains in BugTabs history. No production edits in this pass. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-CURRENT-PASSIVE-20261120 -->
20 November. Captured the installed profession revision 30dd26404e9e in R588 and R589. Recorded exact saved alias data, a 34-second passive window and four natural callback breakdowns. Cleared the temporary observations and closed Tailoring. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-RETAIN-SAVED-REMOVALS-20261120 -->
20 November. Updated Inventory/Professions.lua from d2b48f6b0812 to 30dd26404e9e. Twelve existing Lua 5.4 regressions and the focused Lua 5.1 regression passed. The five installed sources match and passed ten syntax checks. R586 reloaded, R587 checked exact saved Tailoring facts and took four live diagnostic pairs, and R83 resumed the 180-second jump interval. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-FIRST-READY-READ-COST-20261120 -->
20 November. R585 measured the first ready Tailoring source and four alternating in-game getter sweeps. Used source d2b48f6b0812, source counter 37 and the original production event. The observer restored and Tailoring closed with stable bags and zero new Lua errors. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CAST-MATCHER-NUMERIC-20261120 -->
20 November. Changed Core/ButtonFX/Cast.lua from 9e4df7a0b51b to 2babe5a717f2 and covered string return values. R582 verified the isolated before-edit candidate. R583 confirmed fresh startup, R584 verified the loaded matcher and R82 restored the three-minute helper. Nine regressions, ten syntax checks and five installed copies passed. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-CAST-POSITIONAL-PAYLOAD-20261120 -->
20 November. Captured the actual Food cast and identified the same GUID and payload on three interrupts. Added a failing cast-bar ID regression before editing Cast.lua, checkpointed the source, and validated the corrected decoder. R579 reloaded, R580 rechecked cancel, and R581 completed a real Food receipt. All temporary observers restored. R81 resumed the three-minute jump helper. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-OWNED-IDLE-RETICLE-CLEANUP-20261120 -->
20 November. Verified both FluxUI stop methods share the same native actions. Compared real idle, playing and paused reticles, checkpointed the source, and applied the guarded cleanup. The initial reload showed little gain, so the final branch performs the verified native calls directly. After R575, R576 timed the same 200 buttons and R577 checked playing and paused cleanup. Both test paths left no Lua errors. R80 restored the jump timer. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-CAST-INTERRUPT-TARGET-RESET-20261120 -->
20 November. R565's second reservation ran the actual Food start and immediate cancel. R566 repeated it with a button-state census. Both observers restored, bag generation held, no Lua errors were recorded and the character was no longer casting. The three-minute worker continued. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-PROFESSION-SOURCE-STORE-ATTRIBUTION-20261120 -->
20 November. R564 opened Tailoring, timed the existing load/store and notification boundaries, restored all five observer hooks and closed the panel. R565's guarded cast attempt stopped before any input. Released its own reservation and checked the active jump worker. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-COMBINED-REAGENTS-20261120 -->
20 November. Measured the old and combined recipe extractors on live Tailoring data, checkpointed the exact source and history, then applied the edit. Updated the existing collector tracer to recognize both entry points. Both sources passed the traced fixture. R562 reloaded, R563 checked the ready source and list, and R78 restored the three-minute worker. No craft or item action occurred. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-READY-SOURCE-COUNTER-20261120 -->
20 November. Captured one real Tailoring open after the latest Forever reload. The source counter advanced during loading and returned to nil when the panel closed. The original handler was restored, the bag generation held and no Lua errors were recorded. No craft was started. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAGANATOR-JUNK-SETTINGS-20261120 -->
20 November. Measured the cold and warm backpack paths, checkpointed the source and history, and removed repeated profile lookups in the FluxUI Junk display check. R558 loaded the edit. R559 queued the probe, but its immediate screenshot guard stopped on a changed input stamp. The independent read-only capture verified the probe finished and closed the test backpack with all hooks restored. The matching result had stable bag generation and zero new Lua errors. The jump helper was verified alive. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-PENDING-IDLE-REFRESH-20261120 -->
20 November. R553 measured the installed idle Pending query. After a dated source/history checkpoint, removed redundant job reads and empty bank-goal work. R554 loaded the edit. R555 repeated the same timing batches and restored all four wrapped methods. No new Lua errors or item changes occurred. Jump cue R76 resumed as process 42164. [Evidence](validation/inventory-idle-followup-native-2026-11-18.json).

<!-- LHO-RESTOCK-BANK-STACKS-LOADED-CLOSED-20261120 -->
20 November. R551 completed a guarded reload and fresh startup. R75 restored the jump helper using the resized 1903 by 1000 client rectangle. R552 verified the closed-bank gate and positive totals with Syndicator and Baganator loaded. No item changes were performed. [Evidence](validation/bank-tier-live-counts-2026-11-19.json).

<!-- LHO-RESTOCK-UNIQUE-BANK-STACKS-20261120 -->
20 November. R550 compared positive stored character-bank slots and counts with the closed native client. Verified a dated source/history checkpoint and settings presence. The new exact-owner stack test failed against the checkpoint on both Lua versions and passed after the edit. Completed five-client disk and syntax checks. Two older test loaders needed namespace arguments in scratch harnesses. No reload or item action ran in this pass. [Stack evidence](validation/bank-tier-live-counts-2026-11-19.json). [Closed-bank evidence](validation/lag-hotspots-provider-counterexamples-2026-11-14.json).

<!-- LHO-PROFESSION-SAVED-NEGATIVE-PREDICATE-20261120 -->
20 November. R543 and R544 compared live recipe reads against saved flags under both Tailoring aliases. The temporary probe restored its observer and closed Tailoring. R545 armed a separate source-counter observer. R546 through R548 stopped before sending their open commands because the capture was stale or input changed. The counter remains unmeasured at a ready event. No addon Lua changed. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-OBSERVED-REMOVALS-20261120 -->
20 November. R535 timed three ranking variants in rotating order on 102 learned recipes across nine actual saved aliases. Retained the simple observed-ID filter after verifying the external source/history checkpoint and settings metadata. R536 loaded the exact change. R537, R538, R540 and R541 checked first and warm events, then restored the probes and closed Tailoring. Both installed captures reported zero new errors. R74 rearmed the timed helper. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-FIRST-TAILORING-PUBLICATIONS-20261120 -->
20 November. R526 and R527 timed the first native Tailoring open. R528 compared output fallbacks and found the primary native getter returned all 102 item IDs and links. R529 and R530 compared a warm reopen. R532 and R533 repeated it holding the recipe and removal arrays at each event boundary to guard against alias replacement. Both warm passes restored the probe and closed Tailoring. No runtime Lua changed. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-COUNT-NEUTRAL-MOVE-BUILTIN-20261120 -->
20 November. R520 and R523 selected built-in inventory. R521 moved the exact 18-item stack to bag 3 slot 5 and restored it to slot 0:8 on the first attempt. Each phase emitted one delayed update and zero scans. R522, R524 and R525 restored the original provider and both addon enable reads. R73 restored the jump cue. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-COUNT-NEUTRAL-MOVE-PROVIDERS-20261120 -->
20 November. Early probes found the old destination occupied and the requested bag full. They made no moves. R513 and R515 chose empty bag 3 slot 5 and restored the original 18-item stack to slot 0:8. Both passes reported one delayed event per direction and no new Lua errors. R514 and R518 loaded Syndicator alone. R516 through R519 restored Baganator and verified the original enable flags. R72 restored the jump cue. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-UTILITY-CONSUMABLE-RETRY-20261119 -->
19 November. Forever reconnected normally. R500 measured a 49.80 ms first backpack open with a 62 ms frame gap, followed by a 2.88 ms warm reopen. The R502 receipt returned matching counts, but passive scans filled the slot trace before the event. R503 through R506 identified four utility effects. The exact item and spell rule reduced the R508 and R509 comparison from 15 passive scans to zero. The jump cue was restored after reload. [Backpack evidence](validation/backpack-final-callback-2026-11-19.json). [Classifier evidence](validation/consumable-non-restoring-items-2026-11-19.json).

<!-- LHO-NATIVE-BAG-REDRAW-OWNERS-20261119 -->
19 November. R496 armed a temporary observer and R497 completed one Food cast with 14 already owned. All three redraws were the ItemData branch of the Baganator bag-cache callback. Counts ended at 28 in the native and FluxUI readers. The observer restored its four functions without errors and both user panels stayed open. Product Lua was unchanged. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-NATIVE-FOOD-RECEIPT-20261119 -->
19 November. R493 checked readiness inside chat and did not arm. R495 armed after chat released focus. The R494 actor's first preflight rejected the stale process identity without sending input. After retargeting, R494 canceled one cast and completed one, yielding 14 food with matching counts. The additional readiness print still ran inside chat and reported false. The native observer had already armed and covered the full sequence. It restored all four active timed paths and the reveal wrapper with no conflicts or Lua errors. No addon Lua edit was made. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-REDRAW-FRAME-GAP-20261119 -->
19 November. R490 expired during the taxi flight. A focus change stopped R489 before submission and stopped R491 before its execution packet. R492 submitted successfully in the background. Four paired redraws reduced the median nearby frame gap from 36.5 to 33.5 ms and median redraw time from 28.25 to 24.78 ms. The source matches Retail and Forever. The probe restored the original function and left the backpack open as found. No Lua source edit was needed. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-SINGLE-CATEGORY-REFRESH-20261119 -->
19 November. Gear-set contents, the Equipment Set section and consumable preset categories now request one Baganator refresh through the public widget/search reasons. After reload, four Forever pairs reduced category update calls from two to one and median redraw time from 31.482 ms to 27.103 ms. Category order, item counts and view dimensions matched. No Lua errors occurred. R479 isolated the redraw, R483 established the comparison before Lua editing, and R487 measured the installed path after R484 reloaded. Four desktop scripts and 40 syntax checks passed. The incomplete cue was removed and new readiness markers verified independently. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-SHIELD-CONTEXT-20261119 -->
19 November. FluxUI's Baganator gear-set shields reuse the existing merchant and disenchant context during protection refresh. Four installed Forever pairs matched all 52 widget results. Context reads fell from 106 to two, and median refresh time fell from 0.882 ms to 0.791 ms. All five installed copies match. R469 through R472 narrowed the shared Restock stock-list costs. R473 separated the backpack layout and FluxUI reveal callbacks. R474 established the context query cost before changes. R476 loaded the source and R477 confirmed live results. Twenty compiles and 702 focused assertions passed. The world view was restored and the jump cue and helper resumed. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-PROFESSION-LEARNED-LIST-AUCTION-20261119 -->
19 November. Four native Forever Tailoring updates with Auction Restock open produced the same learned recipes, removal flags, visible and hidden rows, and potion targets as immediate full scans. Median combined time was 16.014 ms with the forced full scan and 12.798 ms with the installed settled path. Each half refreshed Restock once. All four inventory generations stayed stable and no Lua errors appeared. R464 attached the temporary observer and R465 opened Tailoring. R466 measured three row builds and independent target-list queries, with all rows and potion targets equal. R467 restored the target after both panels were closed. This verification pass required no runtime edit. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-CONFIRMED-UNLEARNED-20261119 -->
19 November. Settled owned-profession scans can skip full metadata reads for recipes previously confirmed unlearned when the native recipe list, filters and live spellbook still agree. On live Forever Tailoring, median isolated read time dropped from 4.157 ms to 1.173 ms and full metadata calls from 471 to 101. After reload, four native events paired with immediate full scans matched all learned rows and removal flags. Median total scan time fell from 13.293 ms to 8.346 ms. R456 verified native membership. R457 isolated query work. Six R459 events verified independent saved alias arrays after R458 reloaded the source. R463 recovered all four R462 paired timings. Tailoring was closed and test observers released. Eight regression scripts and ten syntax checks passed. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-NAMED-ALIAS-20261119 -->
19 November. The named profession save reuses the current scan's reconciled recipe references when the numeric and named aliases agree. Four paired saves on copies of the actual Forever Tailoring cache reduced the median from 1.225 ms to 0.890 ms. All 101 recipe records, alias order and removal flags matched. After reload, six native Tailoring events confirmed 101 matching records and separate saved arrays, with no new Lua errors. Ten syntax checks and eight regression scripts passed. All five installed sources match. R448 measured 6.438 ms across 471 recipe-info calls. Combining the two schematic passes saved about 0.06 ms at the median and stayed out of production. R450 timed out during command upload. Its blank chat box was closed, and R451's independent capture retained all four completed pairs. R453 confirmed installed parity. Tailoring was closed. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-AUCTION-TAILORING-WARM-LOADED-20261119 -->
19 November. Eight native Tailoring updates rebuilt Auction Restock once apiece. The installed bag-tooltip path reduced the median Restock rebuild from 5.114 ms to 4.291 ms. The full handler medians were 21.504 ms and 21.258 ms, with overlapping samples. All visible and hidden rows and potion targets matched, four inventory generations stayed stable, and no Lua errors appeared. Tailoring and Auction were closed and the original empty target restored. R443 captured alternating paths on ordinary client callbacks, and R445 recovered all eight diagnostic lines. R446 verified world restoration. The earlier pending-read failure was a test observer mismatch. Both provider-mode runs now pass 39 checks each. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-WARM-BAG-TOOLTIPS-20261119 -->
19 November. Warm Auction Restock now shares nonempty native carried-bag tooltip text during a single row assembly. Consumable eligibility, missing metadata, item moves and changed providers keep their current checks. After reload, the three paired Forever rebuilds fell from a median of 4.455 ms to 3.767 ms. Visible and hidden rows and potion targets matched, the bag generation stayed stable, and no new Lua errors were captured. The source matches five installs, with 20 syntax checks and 43 regression scripts passing. The separate consumable readiness assertion fails identically on the checkpoint and candidate. R438 counted nine validations for three complete references. R439 and R440 narrowed the repeated work to six native bag-tooltip reads. R442 measured installed code with commerce closed. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-COLD-TIER-SLOTS-20261119 -->
19 November. Auction Restock shares complete occupied bag slots during one cold target-list build. Empty and incomplete slots still receive fresh reads. Recipe and tier matching retain their original order and cadence. In the installed Forever comparison, the median fell from 13.324 ms to 9.882 ms across three pairs. All seven rows and potion targets matched, the bag generation stayed stable, and no new Lua errors were captured. All five installed source copies match. Thirty syntax checks and 38 regression scripts passed. Whole-frame FPS and native checks on the other installs remain open. The broader R431 diagnostic reduced 450 native reads to 90. The complete-slot-only R432 test reduced the total to 238. R434 used the installed traversal and public fallback after reloading. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-IDLE-MATERIAL-PLAN-20261119 -->
19 November. Auction Restock skips craft-material assembly when the owner has no craft plans. In Forever, 256 calls on six actual visible rows took a median of 0.653 ms before and 0.044 ms with the early return. The full rebuild kept all seven rows and potion targets identical. This removes three temporary tables and a row traversal in the idle case. The saving was about 2.4 microseconds per rebuild on this character. All 35 auction regression scripts and ten Lua syntax checks passed. The source matches all five installs and Forever loaded the source in R433. Four ordinary carried reads matched their earlier values within each build, but timing varied. Skipping discarded food and water bag reads with saved references retained was also negligible in warm builds. Both read paths remain as installed. The warm synchronous Restock rebuild remains open. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROFESSION-IDENTICAL-RECORD-MERGE-20261119-LOADED -->
19 November. Reloaded the installed profession merge change in Forever. The loaded Tailoring observer processed five updates and restored itself with a stable bag generation and no new Lua errors. All four retained result lines show 101 matching references in both aliases and identical revocation data. Displayed callback timings ranged from 13.676 to 23.003 ms. These unpaired timings do not establish a whole-handler gain. Tailoring was closed and the jump helper resumed. [Profession evidence](validation/profession-bag-restock-2026-11-19.json). A separate settled Restock stock check found 21 saved bank IDs with known static classes, no pending classification on the bank IDs or Restock rows, and an empty mail snapshot. A populated inbox and live consumable usability remain separate dependencies. In particular, situational false usability results are deliberately uncached. [Stock evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROFESSION-IDENTICAL-RECORD-MERGE-20261119 -->
19 November. Profession storage skips the field scan when the prior and incoming alias already point at the same plain recipe record. Distinct records and custom tables still use the existing merge. All 101 actual named and numeric Tailoring recipe references matched. Six isolated native timing passes over those saved rows reduced the median for 16 merge-check traversals from 2.035 to 0.477 ms. The individual saving is about 0.10 ms per traversal, and the whole callback remains unmeasured. Nine existing regressions passed, the file matches all five installs, and loaded verification is recorded above. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-AUCTION-SETTINGS-SAME-PASS-20261119-LOADED -->
19 November. The installed Auction Restock settings change was verified in Forever with Syndicator and Baganator. Three pairs against the original fallback halved tier-target reads from ten to five and reduced median callback time from 10.640 to 5.749 ms. All seven rows, potion targets and status text matched. No new Lua errors occurred. The jump helper resumed after the reload and both test panels and the original empty target were restored. Eight actual idle Tailoring events confirmed the separate passive hotspot. Preserving the existing rows during the callback reduced its median from 18.705 to 13.930 ms. The test ran the full rebuild immediately afterward outside the timer and confirmed exact parity. Mail expiration and late item data can change without a stock generation update, so this diagnostic bypass remains out of the addon. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-SETTINGS-SAME-PASS-20261119 -->
19 November. FluxUI now reuses the Auction Restock rows that a settings change just built when the initial planner still has the same stock, owners and clock. The existing guards retain fresh reads for other owners, receipts, pending or saved craft plans, unknown counts and changed inventory. Three paired comparisons of the real settings callback in warm Forever reduced two synchronous row builds to one and took a median of 10.177 ms versus 5.496 ms. All seven rows and potion targets matched. The test did not change a setting or transact. The initial cold probe hit an assertion because an ordinary native price lookup was still running. The measured pass waited for that lookup to complete and reported no new errors. The installed source matches five clients and all 35 existing auction scripts passed. Loaded verification is recorded in the following entry. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-SETTLED-PAINT-20261119 -->
19 November. The six-row Restock repaint took 0.160–0.200 ms on the loaded Forever client. All six native size calls requested dimensions that differed from the current exact values. Checking dimensions before writing produced no consistent timing gain. All tested cell geometry and visible states matched, and no Lua errors occurred. The sizing path stays as installed. Prior native evidence places the larger cost inside rebuilding the stock rows. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-UNUSED-TIER-BANK-20261119-LOADED -->
19 November. Revalidated the installed Auction Restock change on Forever after a reload with FluxUI, BugTabs, Baganator and Syndicator. All six visible rows, the hidden row and potion targets matched the original fallback in three paired comparisons. The installed path eliminated 21 food and 21 water bank-tier match calls in a separate count. Timing medians were close at 4.688 and 4.661 ms. The bag generation stayed stable and no new errors were captured. The Auction House was closed and the original empty target restored. The three-minute jump helper resumed after reload. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-UNUSED-TIER-BANK-20261119 -->
19 November. With Auction Restock and Tailoring open on Forever, six native Tailoring updates synchronously rebuilt identical Restock rows. The rebuilds spent 31.488 ms total inside 16.577–21.616 ms handlers. FluxUI now skips food and water bank-stock aggregation when its own Auction Restock path discards those rows, while keeping reference-tier evaluation and the original path for live banks, replaced providers or vendor craft plans. Three pairs using actual stock and preserving reference evaluation reduced the median row rebuild from 4.888 to 4.456 ms. All six shown rows and the one hidden row matched. All five installed copies match and existing regressions passed. The installed path was verified in the next entry. The rest of the repeated rebuild remains a hotspot. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROFESSION-BULK-AND-LOADED-ALIAS-20261119 -->
19 November. Forever's GetProfessionSpells returned zero entries for Tailoring and Alchemy with five tested signatures, even though live recipe flags confirmed 101 and 23 learned recipes. The native filtered list matched the default views. Applying Have Materials hid all 23 learned Alchemy recipes while the learned toggle stayed enabled. The filter was restored. After reload, the installed unchanged-alias optimization kept all 101 Tailoring recipe references equal between its numeric and named entries in six displayed samples. Fifteen live profession publications cleared the craftability cache 60 times, including 15 clears after dispatch. No synchronous Craft.ListRecipesForKind work ran in those handlers. The six displayed handlers took 12.157–23.011 ms and were unpaired. Bag generation held steady, BugTabs counted zero new errors, and the observers and panel were restored. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-UNCHANGED-ALIAS-20261119 -->
19 November. Quiet Tailoring produced 15, 5 and 5 native list events in three 36-second windows. The middle window bypassed only FluxUI's passive list handler. The source remained stable, bag generation held and the profiler restored its owner with zero new errors. FluxUI now skips copying an already reconciled recipe alias when the row references and removal flags match. Changed data and older saved entries with missing tables take the usual path. Three paired tests on eight live saved aliases reduced 16 repeat reconciliations from a median of 3.446 to 1.370 ms, about 0.130 ms per pass. One redundant alias copy was avoided. The source hash matches five installs, all ten syntax checks and five existing regression scripts passed, and loaded verification awaits a reload. A separate read-only query comparison matched 699 recipe flags across Tailoring, Alchemy and First Aid. The faster predicate narrowed Tailoring's median learnedness pass from 5.668 to 1.360 ms. These samples do not cover recipe learning, changing providers, late metadata or other clients, so the production scanner keeps the native recipe checks. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-OBSERVED-RANK-20261119 -->
19 November. FluxUI now ranks ordinary modern observed recipe IDs directly into the saved-alias lookup. Legacy and unusual IDs retain the text-key path, as do replaced catalogue methods. On Forever, three paired tests matched 101 exact saved recipe references. Median for six lookups fell from 4.731 to 3.038 ms, which is 35.8%. The earlier shortcut that retained the ordered list had mixed timings and stayed out. After reload, the loaded Tailoring scan showed 101 matching references by name and numeric ID in six displayed callbacks, no new Lua errors and a stable bag generation. The unpaired whole handler still reached 39.977 ms. Current data proves the isolated lookup gain. The source matches all five installs and passed ten syntax checks. The allocation regression's stale function locator was corrected, and the baseline and candidate passed all 3,063 checks. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-IDLE-LIST-20261119 -->
19 November. With Tailoring open and Auction Restock closed on Forever, a 24-second hands-off window produced three native list refreshes at 7.49, 20.91 and 23.53 seconds. FluxUI spent 12.652, 13.336 and 13.709 ms in those handlers. No delayed bag, item-data or player cast event was observed. Bag generation stayed stable and the probe reported zero new errors. An earlier pass recorded 47 profession publications. The displayed comparisons kept all 101 recipe records and tombstones equal, including with the native Have Materials filter changed and restored. The displayed list handlers reached 38.023 ms while publication took under 1 ms. The main cost was inside the scan and store path. Observers were restored and the panel closed. The next candidate must preserve late metadata and genuine learned, unlearned and craftability changes. Runtime Lua was not changed in this pass. The first observer used the wrong global and raised an assertion before installing wrappers. The corrected observer attached to Flux.Inventory. The second opener was stopped by its identity check before input and succeeded after correcting its fixture. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-AUCTION-RESTOCK-STARTUP-20261119 -->
19 November. Auction Restock now reuses its first row build for the first synchronous scan when the data owners, inventory generations, and time boundary match. The search response still rebuilds the rows. In two paired warm Forever runs with Baganator and Syndicator loaded, median ShowSession fell from 12.603 to 6.954 ms (44.8%) and synchronous builds fell from two to one. Six visible rows, one hidden vendor row, the editor selection and the search-response refresh matched. Both warm panel pairs matched across 330,035 sampled pixels. The original build path remains available for charged or unresolved items, active receipts or craft work, unsettled inventory, and replaced data methods. Genuine Pending receipts and other native client/provider profiles still need validation. Both Lua files match across five installs and passed 20 Lua 5.1 and 5.4 syntax checks. The test observer was removed, the window was closed and the original empty target was restored. The cold candidate opened in 22.419 ms on one full build. R363's cold baseline was a separate run. A follow-up capture verified that the jump cue had installed after the installer screenshot lease expired. The replacement helper logged three complete Space key pairs with no general PC-idle requirement. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-NATIVE-AUCTION-LIFECYCLE-20261119 -->
19 November. Opening Forever's native Auction House Buy window for the first time after reload loaded Blizzard_AuctionHouseUI. The nearby frame gap was 118 ms on first open, 30 ms on warm reopen and 22 ms on the first close. FluxUI spent 0.231 and 0.090 ms attaching Restock, with no Restock row builds. The native observer expired before the second close, which was verified visually. Opening the actual FluxUI Restock tab took 25.407 ms inside ShowSession. Two synchronous row rebuilds took 8.979 and 8.630 ms, then the search response rebuilt the rows once more at 5.335 ms. All six displayed targets were stocked. The panel and original empty target were restored, and the observer reported no new Lua errors. Active Pending still needs a session with genuine receipts. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-ORDINARY-CHARGE-20261119 -->
19 November. Auction Restock reuses confirmed ordinary units only within one row rebuild with the original charge and potion-replacement methods and stable bag, bank and warband generations. Changed item IDs, charged items, unresolved data and open or unsettled bank contexts retain fresh reads. On the loaded Forever client, three paired full rebuilds with commerce closed matched six visible rows and one hidden vendor row on every run. Median elapsed time fell from 4.785 to 4.480 ms. The bag generation stayed stable and no new Lua errors appeared. Thirty syntax checks passed and the sources match across five client installs. Real charged stock, open Auction and Pending, and the other provider/client configurations still need native validation. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-RESTOCK-REBUILD-ATTRIBUTION-20261119 -->
19 November. Three current Forever Auction Restock row builds took 13.465, 5.150 and 4.907 ms with commerce closed and the backpack open. The shared target builder accounted for 16.618 ms inclusive. Closed-bank tier reads took 4.026 ms and charge checks took 2.715 ms. Reagent-set lookups took 0.049 ms. The first observer setup used a missing spell API owner and left two temporary observers until the verified cleanup reload. The corrected probe restored its observers with zero new errors. A paired native check matched all 21 closed-bank item IDs. Reusing the ID union saved a median 0.279 ms per 12 rebuilds, so that candidate stayed out of FluxUI. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-AUCTION-RECIPE-LOADED-20261119 -->
19 November. The installed Auction Restock refresh on Forever used the grouped catalogue branch with five eligible carried item IDs. The same three learned inputs reached recipe verification in the same order. A single timed pair took 2.417 ms for the five per-item queries and 1.650 ms for the loaded refresh. The bag generation and Lua error count remained stable. Auction and Pending were inactive. Native price scan, real Pending work and other clients still need timings. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BACKPACK-REAL-UPDATE-20261119 -->
19 November. A real count-neutral bag move on Forever with Syndicator and Baganator produced one delayed bag event, a 6.40 ms inclusive Baganator view refresh, and 0.16 ms in FluxUI button-face callbacks. The ExtraButton grids kept the same selected items. The bag generation advanced once and the consumable classifier did no full rescan. The one 42 ms frame gap is unattributed. The temporary test tried to schedule restoration while the moved stack was locked. A follow-up after an independently observed reload verified the 18-item stack back in its original slot, the temporary slot empty and the cursor clear. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-AUCTION-RECIPE-BATCH-20261119 -->
19 November. Three paired live Forever comparisons matched three learned recipe references in order for five carried Restock outputs. The median recipe catalogue lookup fell from 1.856 to 1.029 ms when the comparison grouped records from one catalogue. Auction Restock now shares one ranked catalogue for five or more distinct eligible items. Smaller comparisons and replacement methods keep the per-item path. Both sources match across five installations and passed twenty syntax checks. The isolated measurement excludes the full Restock workflow. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CONSUMABLE-LOADED-QUEUE-MATCH-20261119 -->
19 November. In two six-second Forever samples with the backpack open, the loaded classifier removed 15 passive retries totaling 28.314 ms. The queue went from one item to zero. Food, water, healing potion, mana potion and bandage kept identical selected IDs, counts and grid button IDs. Both samples had a stable bag generation, restored the timed function and showed zero new errors. A diagnostic timer call to reload was blocked, then the ordinary /reload command succeeded. [Evidence](validation/consumable-non-restoring-items-2026-11-19.json).

<!-- LHO-BACKPACK-FIRST-LAYOUT-20261119 -->
19 November. Restoring the prior backpack after the successful reload took 44.86 ms on its first observed open. Baganator layout took 41.45 ms inclusive and display was 21.60 ms inclusive. All 52 item-detail calls totaled 9.80 ms. The slowest item-detail call was 0.60 ms. The prior larger item interval did not recur. The backpack remained open. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-FREE-ACTION-POTION-20261119 -->
19 November. A live Forever check found that Free Action Potion was the sole pending consumable. It was loaded, exposed item spell 6615 and parsed with zero restoration. The matching food control still parsed as 1338 health. FluxUI now recognizes that exact item and spell after ordinary restore classification. Other tooltip states retain their existing retry behavior. The final Lua source matches across all five installations and passed ten compiler checks. Post-reload timing is pending. [Evidence](validation/consumable-non-restoring-items-2026-11-19.json).

<!-- LHO-CONSUMABLE-LIVE-RETRY-20261119 -->
19 November. A loaded Forever check confirmed cached rejection for Jungle Remedy, Southshore Stout and Tabetha’s Instructions. One other item remained in the classifier queue. With panels closed, 15 passive read-driven scans still ran in 6.01 seconds and took 28.944 ms inclusive. The prior open-panel sample took 36.094 ms at the same count. The samples differ in UI state. The follow-up had stable bag generation, zero pending native item loads and zero session errors. [Evidence](validation/consumable-non-restoring-items-2026-11-19.json).

<!-- LHO-BACKPACK-OPEN-WARM-BOUNDARY-20261119 -->
19 November. The first observed Baganator backpack open after the intervening reload took 103.61 ms. Lost Supplies took 0.95 ms this time, including 0.02 ms for FluxUI slot protection and 0.03 ms for Junk. The rest of the first-open time is unassigned. The first probe attempted to close the backpack within the same frame, which Baganator suppresses. A follow-up restored the closed backpack. Two warm reopens took 4.18 and 3.88 ms, performed no item button repaint, and closed successfully on later frames. All three measurements held the bag generation steady and showed zero current-session errors. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BACKPACK-WARM-CALLBACKS-20261119 -->
19 November. On Forever with Baganator and Syndicator, two warm FluxUI backpack callbacks took 0.518 ms across 48 occupied slots. The item-existence, GUID and cosmetic reads totaled 0.139, 0.092 and 0.232 ms respectively. The bag generation stayed stable and BugTabs reported zero new errors. Forever uses Baganator’s Retail-style live item button. GUID and equipment-set lookups finish before the 98.63 ms cold interval. The cold callback trace and installed-candidate repaint timing are pending. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-JUNK-CACHED-QUALITY-20261119 -->
19 November. Three paired native reads matched all 48 carried-item verdicts each time. Every sampled item had known non-gray quality. The isolated median was 0.148 ms for the original gray fallback and 0.013 ms when the probe used quality established before timing. One pair was slower. The Junk fallback now reads an already resolved non-gray quality when the Baganator caller supplies only an item ID. Gray, missing, restricted and replacement quality paths use the original rules. Both changed Lua files pass syntax checks across five installs. The live client still needs to load the change for full repaint timing. The prior cold single-item backpack hitch remains unassigned. Restock row equivalence is pending. The idle helper recorded three Space key pairs near its three-minute cadence. Character movement was unverified. [Evidence](validation/junk-cached-quality-2026-11-19.json).

<!-- LHO-CLIENT-LOAD-AUDIT-20261119 -->
19 November. The scoped client load audit found all 181 direct manifest files and the same TOC in Retail, Forever, Classic, Classic Era and Anniversary. The audit pinned all five executable versions and compared 905 file entries. The 180 Lua files passed the Lua 5.1 and 5.4 checks after normalizing byte-order marks on ten temporary BuyEmAll localization copies. The BuyEmAll XML parsed. [Evidence](validation/inventory-client-load-audit-2026-11-19.json).


<!-- LHO-PROFESSION-ALIAS-OVERLAP-20261119 -->
19 November. On Forever, 471 native Tailoring recipe observations overlapped one of eight saved aliases. Three isolated paired four-sweep tests agreed on every alias. The prototype median fell from 1.577 to 0.627 ms per four sweeps. Profession scans now bypass the row and tombstone copy for ordinary aliases with no observed recipe or unlearned ID in common. Related entries and metatable-backed data keep the original merge. The modern spellbook predicate matched 471 current Tailoring flags. The legacy predicate missed all 101 learned recipes and the profession predicate marked all 370 unlearned recipes as true. Continue using the full live recipe flags. Lua 5.1 and 5.4 syntax passed across all five installations. The exact native follow-up was released before typing when the host detected a held key. Restock and Tailoring remain open. [Evidence](validation/profession-alias-overlap-2026-11-19.json).


<!-- LHO-PROFESSION-BAG-RESTOCK-20261119 -->
19 November. With Tailoring and Auction Restock open on Forever, moving a stack out and back produced two delayed bag updates and five Restock builds totaling 45.959 ms. A second trace attributed the three additional builds to professions notifications. The three Tailoring handlers took 28.540, 20.529 and 33.149 ms inclusive. Both trials verified the original stack, empty temporary slot, clear cursor and zero new Lua errors. The profession scan now ranks saved aliases only for recipe keys observed in that scan. It still resolves revocations and rank ties across all stored aliases, uses the full public query if another owner replaces it, and preserves normal scans and notifications. Five paired native helper checks matched all 505 current Tailoring recipe references. The median fell from 0.891 to 0.581 ms with the key table prepared before timing. The source matches across five installs and compiled on Lua 5.1 and 5.4. Full event timing needs the candidate loaded. [Evidence](validation/profession-bag-restock-2026-11-19.json).


<!-- LHO-CONSUMABLE-NON-RESTORING-20261119 -->
19 November. On Forever with Baganator and Syndicator, 15 unchanged consumable scans took 36.094 ms total in six seconds. The Combat Grid and consumable binding reads fed the retry loop. Native inspection identified three loaded non-restoring items in the retry queue. The classifier now settles Jungle Remedy and Southshore Stout when their native spells match the verified cure and alcohol effects. It settles Tabetha's Instructions when the complete read-only tooltip matches. Positive classifications run first. Missing and ambiguous tooltip data follow the existing retry path. The extracted candidate guard recognized all three live inputs and left the restoring food control eligible. Lua 5.1 and 5.4 accepted the source across all five installations. The client still needs a suitable reload and a matched passive timing run. Restock and Tailoring stay open. The R48 three-minute worker is running as PID 10224. Windows refused background activation, so the jump remains queued. [Evidence](validation/consumable-non-restoring-items-2026-11-19.json).


<!-- LHO-RESTOCK-REAGENT-NAME-READS-20261119 -->
19 November. With the modern auction browser open, three current Restock row builds took 10.501, 6.066 and 5.032 ms. The shared target builder took 13.180 ms across those builds. A subsequent trace counted nine visible item-name harvests for three row builds, totaling 2.566 ms. Three paired reads of real inventory returned identical names and reduced native name requests from 207 to 69 per pair. Median for the isolated reads fell from 0.580 to 0.363 ms. FluxUI now shares available native item names within a single Restock rebuild and keeps every discovery pass. Missing values, merchant reads and replacement methods use their original paths. Both Lua files match across five installations and pass Lua 5.1 and 5.4 syntax. Loaded-source and full workflow timing still need a suitable reload. The R47 jump worker sent five Space pairs before its in-game cue went missing. R48 restored the cue and is live as PID 10224. Windows refused its latest request to activate WoW during an idle window, so it deferred the jump. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

19 November. With Restock and Tailoring visible, three complete row builds took 5.926, 5.461 and 5.772 ms. All six visible rows and the hidden vendor row had identical fingerprints. A real count-neutral bag move triggered one delayed bag event and one touched-item pulse. The capture recorded two Restock row builds totaling 21.907 ms, two paints totaling 0.620 ms, one grid count flush at 0.155 ms and ten consumable scans totaling 28.042 ms. The nearby peak frame gap was 72 ms. The spans can overlap and the frame gap has no attribution. The move probe checked the new slots before the bag update and missed its automatic return. A separate native verification confirmed all 18 items restored to their original slot, the temporary slot empty and the cursor clear. Future timed moves must confirm the native slot update before deciding whether to return the stack. The Restock and Tailoring windows remain open. The recent source change still needs live adoption and an exact full-row comparison. The jump worker remained live and Windows continued to refuse background activation. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

After the stack was restored, R290 counted 20 natural classifyPendingRead passes in eight seconds with the original tooltip getter installed. The passes totaled 49.612 ms and peaked at 4.486 ms. All retained the published runtime table. Bag generation remained stable, the observer restored its method and BugTabs reported zero new errors. Focus on the normal eligibility and pending-read work. Preserve original getters during attribution. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-AUCTION-USE-FINAL-SKU-20261119 -->
19 November. R266 verified the selected four-addon profile and restored the backpack after a 37.14 ms open. R267 matched seven ordinary rows and stable bag generations. Its three baseline/candidate pairs were 10.222/4.696, 6.171/8.267 and 7.119/6.514 ms. After installing the removal, the earlier charged-row audit showed two public-extension compatibility cases that the ordinary rows missed. Restored the two preliminary calls and verified exact checkpoint bytes, Lua 5.1 and 5.4 syntax and all five installed hashes. R268 observed the retained source at line 538 in the running client, with 14 calls totaling 0.685 ms, no positive charge reads, stable generation and zero new errors. No reload was needed. [Evidence](validation/auction-final-sku-2026-11-19.json).

A five-second Forever capture with FluxUI, BugTabs, Baganator and Syndicator recorded 12 passive consumable validation passes. It made 180 tooltip reads. In the same pass, 72 repeated an identical item ID and link, and the returned text matched on all 72. The pass total was 38.980 ms, the slowest was 3.744 ms and the 180 tooltip reads accounted for 26.765 ms inclusive. The nearby peak frame gap was 36 ms. The probe restored both wrapped methods with stable bag generation and zero new Lua errors. R274 attributed the 24 repeats across four natural passes to the saved-reference fallback. Both R270 and R274 replaced GetTooltipText, which is pinned by Persist.EligibilityOwnersMatch. That change disables existing same-pass reuse and accounts for the repeated checks. R276 kept the tooltip owner intact and observed zero scans in 5.012 seconds with the auction browser open. Preserve the guarded reuse. A normal-path sample with active classification remains needed. The R47 jump worker PID 36164 now handles the current four-addon setup. It submitted two Space pairs, with the second deferred briefly for recent input. Character movement is unverified. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-BACKPACK-FINAL-CALLBACK-20261119 -->
19 November. R249 matched 55 ordered visible buttons and kept the bag generation stable. Open-bag baseline/candidate pairs were 1.849/0.960, 1.780/0.881 and 1.446/1.170 ms per two passes with no error delta. Its immediate close was ignored by Baganator. R250 verified closed again. Two R251 preflights sent no reload. R254 timed six current native item lookups, with each first call below 0.2 ms on the warmed item. R255 confirmed the new line 184 and no old jump cue. R256/R257 recorded an instrumented first open of 150.08 ms and a warm open of 3.02 ms. Frame gaps were 169 and 29 ms. One item detail took 99.00 ms with 98.63 ms between instrumented callbacks and a Lua heap increase of 8,779.7 KiB during the call. The probe restored its temporary methods, closed both opens and reported zero errors. R258 identified enabled Flux Junk and disabled mark-unusable. R39 launched the verified three-minute worker PID 21428. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-ITEM-REGISTRATION-INDEX-20261119 -->
19 November. R243 and the first R244 attempt sent no input. R244 confirmed production bank view code at line 65 and measured two bank views, 5,621 registered regions, 550 registered item buttons across four parents and zero visible rows. Six registered-only and six full visible passes took 2.720 and 6.296 ms respectively. R245 paired four full visibility passes per variant and matched all 550 references in order. The pairs were 2.401/1.237, 2.785/1.621 and 2.773/1.330 ms. No new Lua errors. Applied ItemViews 0bf0e29b to 6833655b after checking the external checkpoint, history and 21 available settings metadata entries. All five installed source hashes match. R246 measured the installed bank visitor at 3.330 ms median versus 14.899 ms and all nine Restock rows matched. Both visitors restored and all leases released. The R35 jump worker has stopped. R37 launched PID 12080 and recorded two Space key pairs by the subsequent read. Character movement remains unverified. R247 observed 1,227 frames and no scoped events. Peak was 50 ms. R248 stopped before input during foreground activity. [Evidence](validation/baganator-item-registration-index-2026-11-19.json).

<!-- LHO-BAGANATOR-BANK-VIEW-INDEX-20261119 -->
19 November. R238 wrapped a guarded tier method, so R239 repeated the measurement with classifier identities preserved. The target builder took 17.441 ms, of which 12.676 ms was closed-bank tiers. R240 found four reads of a single tooltip totaling 0.469 ms. R241 found two bank views among 5,696 skin registry records. In R242 the exact private candidate cut the median from 13.565 to 2.817 ms across three pairs. Both views retained order and all nine target rows matched. Bag and bank generations held, the observer restored, and the session had zero Lua errors. Applied BaganatorCompat/FluxBaganator_BankRestock.lua 2b5489ee to d10005f7. The running session was left in place. [Evidence](validation/baganator-bank-view-index-2026-11-19.json).

<!-- LHO-PARSER-VENDOR-LIVE-20261119 -->
19 November. R231 stopped before input. R233 confirmed the updated parser call site at line 840, versus 833 in the archived source. R230 matched all 42 carried counts, 18 parser records and 42 vendor records by field digest, with zero session errors. R234 opened in 192.31 ms with a 209 ms gap, both addon load counts zero and the closed view restored. R235 timed seven retries totaling 43.186 ms with a 9.516 ms peak. R236 matched all four fields for 42 items across three pairs and timed the running vendor helper at a 2.1036 ms median versus 3.9530 ms. R237 identified the shared targets at 21.264 ms of a 23.826 ms closed-AH row rebuild. R232 had no resolved positive charge sample. All input leases released. R35 restored the jump cue and worker 40692 sent three Space pairs by the final check. Visual movement was unverified. [Evidence](validation/parser-vendor-live-2026-11-19.json).

<!-- LHO-RESTORE-PARSER-PATTERNS-20261119 -->
19 November. Updated Inventory/FluxConsumableClassify.lua 37606d4f to fc5f7329. R224 matched 18 live tooltip duration verdicts and cut the paired median from 4.8663 to 0.6035 ms per 288 calls. R225 matched two ranged potion floors and cut the median from 1.4344 to 1.0319 ms per 64 calls. R226 took the production pre-reload snapshot with 42 bag IDs, 18 parsed records, four potion records, zero count mismatches and zero errors. Lua 5.1/5.4 and the five installed hashes passed. R228 was released before entering the reload after recent user input. [Evidence](validation/restore-parser-patterns-2026-11-19.json).

<!-- LHO-LIVING-CONSUMABLE-RETRY-20261119 -->
19 November. R219 and R221 counted tooltip calls during Forever's periodic consumable retry. R221 found 60 Score tooltip reads across six items and 20 classification reads across four items in two seconds. The tooltip observer trips Persist's identity guard, so the Score counts may include observer-induced work. R223 left the tooltip and eligibility functions intact. It timed eight retries totaling 44.914 ms and peaking at 7.043 ms. Both observers restored in the caller trace and the sole wrapper restored in the final trace. R220 and R222 released on input guards. No consumable source edit. [Evidence](validation/living-consumable-retry-2026-11-19.json).

<!-- LHO-VENDOR-FIELDS-ONCE-20261119 -->
19 November. Updated Inventory/Restock/Vendor/FluxVendorItemDisplay.lua 8399fc26 to a481a7ec. R216 aborted during a foreground change and released the input reservation. R217 compared the short candidate with the live reader before the edit. R218 used the exact edited function against the loaded baseline and found no mismatches across 42 items. The median for 336 reads fell from 4.3233 to 2.1802 ms across three paired trials. The bag generation stayed stable. Both Lua syntax versions passed before and after, and all five installed hashes agree. The current session was left running. [Evidence](validation/vendor-fields-once-2026-11-19.json).

<!-- LHO-BACKPACK-SINGLE-SLOT-20261119 -->
19 November. R209 and R211 recorded first-open gaps of 171 and 158 ms. The two slowest detail calls took 102.84 and 97.20 ms. Both tests restored the backpack to closed, preserved bag generation and reported zero errors and zero restoration failures. R213 stopped before opening on a transient group state. R214 released after foreground input changed, and R215 released before input after the character resumed gameplay. No product Lua edits. The three-minute worker resumed after the final reload. [Evidence](validation/backpack-single-slot-2026-11-19.json).

<!-- LHO-RESTOCK-SETTINGS-GET-20261119 -->
19 November. Applied Inventory/Restock/Core/FluxRestockSettings.lua 1acf3b02 to c2a9e393. Lua 5.1 and 5.4 passed both revisions and all five installed copies match. R205 kept the original returned table, preserved the migration record and matched every sampled Junk decision. R206 reloaded to the world. R207 closed both backpack opens, checked store identity and bag generation, and reported zero new-session Lua errors. Native first and warm opens took 149.69 and 5.23 ms. Jump helper 30624 resumed and sent one verified Space pair, with movement unverified. [Evidence](validation/restock-settings-get-2026-11-19.json).

<!-- LHO-ITEM-INFO-ONCE-20261119 -->
19 November. Applied Inventory/FluxItemClass.lua 6e1ed983 to 85c16cb1. Lua 5.1 and 5.4 passed for both revisions and the five installed copies match. In Forever, all 42 loaded native item tuples produced matching full records. Across three 336-record batches, median time decreased from 4.1317 ms to 2.2385 ms. The initial after-reload diagnostic referenced a nil Bags field. Its corrected read matched 42 metadata records and 42 counts, with the prior diagnostic error retained and no new errors. Three-minute jump worker 39308 was verified live with one Space pair. [Evidence](validation/item-info-once-2026-11-19.json).

<!-- LHO-BACKPACK-FLUX-COMPAT-20261119 -->
19 November. With Syndicator and Baganator active, the first category backpack open took 150.21 ms with a 161 ms frame gap. The warm open took 5.77 ms. Baganator Display contributed 123.88 ms inclusive. Across the first open, the timed FluxUI calls were 102 Junk checks at 3.79 ms and one view lookup at 0.03 ms. The other selected category and protection callbacks did not run inside the synchronous open. Both closes succeeded and all wrappers restored with zero errors. The first-open hitch still needs deeper attribution. The probe covered synchronous opens only, so deferred work remains open. A delayed follow-up after reload 201 kept the host screenshot capture outside both timed opens. The first open still took 151.67 ms with a 169 ms frame gap. The warm open took 5.14 ms. The backpack returned to its closed state and the probe produced zero new errors. [Evidence](validation/backpack-flux-compat-2026-11-19.json).

<!-- LHO-CONSUMABLE-TOOLTIP-DURATION-20261119 -->
19 November. Applied Inventory/FluxConsumableClassify.lua 689c630a to 37606d4f. Lua 5.1 and 5.4 syntax passed. The Retail, Forever, Classic, Classic Era and Anniversary source copies match. R195 measured three live predicate pairs, with a median of 2.8363 ms before and 2.4852 ms after for 288 calls. R196 and R198 gave the same nine-record parser digest with stable bag generation, both addons loaded and zero errors. The R197 submit screenshot showed an empty chat field, and a separate capture confirmed the reload via fresh startup output. Jump worker 40076 is running for this client. [Evidence](validation/consumable-tooltip-duration-2026-11-19.json).

<!-- LHO-BACKPACK-ITEM-UPDATE-COST-20261119 -->
19 November. Forever's category backpack first open took 155.39 ms, with a 167 ms frame gap. Baganator's 54 item-detail calls took 117.61 ms. Acquiring 55 pooled buttons took 0.55 ms and reported zero new frames. The retry measured 123.06 ms across the same 54 detail calls. FluxUI Junk checks contributed 2.96 ms in that retry, and the instrumented quest, cooldown and context methods each took under 3 ms.

The native combined backpack first open took 155.73 ms with a 166 ms frame gap. The item update took 125.85 ms, and 18.54 ms was inside the observed button methods. Junk accounted for 12.57 ms in that group. A separate read of all 76 carried slots with the backpack closed took 0.63 ms for item data and 0.14 ms for quest data. The closed-bag read ran after the automatic spirit release with both addons enabled. It leaves cold first-open metadata behavior unverified.

The character died after the native capture finished. The release timer elapsed and the character is at the graveyard as a ghost. The first deeper probe encountered Syndicator's frozen Search API. A reload cleared that probe, and the instance-level retry reported zero errors and zero restoration failures. Both provider flags were restored and the idle jump helper is running. The measured backpack hitch remains open. Continue investigating nearby item widget and per-addon work, and use the prior measurements for separate Pending, consumable retry, cast and inventory integration fixes. [Evidence](validation/backpack-item-update-cost-2026-11-19.json).

<!-- LHO-NATIVE-BACKPACK-JUNK-GLOW-20261119 -->
19 November. Forever allocated 76 hidden Junk glows on the first native combined backpack open. The corrected probe identified FluxUI's specific glow texture and found zero instances before open, 76 immediately after open, and 76 after warm reopen. `FluxJunkOverlay.lua` now creates the glow on its first visible use and reuses it on later paints. The coin path and repaint timing are unchanged.

The same backpack test after reload found zero allocated glows. The before and after opens each ran 112 Junk checks with zero positive verdicts, matched all 76 visible slot positions and frame dimensions, preserved the bag generation and restored the closed state. Both samples reported zero Lua errors. The positive display transition, bank buttons and other clients still need native coverage.

The first open took 155.23 ms before and 157.93 ms after, with frame gaps of 164 and 169 ms. The warm opens took 24.74 and 27.66 ms. The pair confirms fewer allocations and provides no timing improvement. `UpdateItems` still accounted for 125.00 and 128.57 ms on the first opens. Measure item and quest reads, the quality and extended appearance path, then cooldown and tooltip work separately. Continue the Pending, mail, bank, vendor, receive, craft and cast checks. Both external addons were verified loaded with all four original enable readings restored. The idle-only three-minute jump worker resumed. [Evidence](validation/native-backpack-junk-glow-2026-11-19.json).

<!-- LHO-NATIVE-BACKPACK-JUNK-QUALITY-20261119 -->
19 November. On Forever with Syndicator and the native combined backpack, the original first open took 156.52 ms and coincided with a 164 ms frame gap. Across its first and second opens, native `UpdateItems` accounted for 136.83 ms inclusive. Of that, 127.31 ms fell outside the explicitly nested observers. This remainder can include unmeasured Lua descendants. FluxUI Junk display checks accounted for 16.69 ms across 224 calls.

The warm baseline found 194 native Junk fallback calls, all on slots with known non-gray quality and all returning false. `FluxJunk.lua` now returns that result directly for ordinary slot tables with a readable numeric quality above poor. Explicit and rule-based Junk decisions still run through their existing entry points. Gray and unresolved slot qualities follow the existing checks.

Across two warm opens, fallback work fell from 1.1866 ms for 194 calls to 0.2709 ms for 196 calls. The 224 display checks took 6.77 ms before and 3.79 ms after, and observed settings reads fell from 1,682 to 1,285. Slot order and geometry signatures matched. The bag generation and final closed state were preserved and all captures reported zero errors. One before and one after warm sample across reloads establish the scope of this observation. Positive gray or unknown quality and other clients still need native checks.

The first open after the edit still took 150.95 ms with a 159 ms frame gap. Trace the work inside `UpdateItems` at the item-button allocation, update, and icon or skin hook boundaries. Keep the Baganator category layout and Pending, mail, bank, vendor, receive and cast validation open. Both external addons were restored and verified loaded with their original character and overall enable flags. The idle-only jump worker resumed. [Evidence](validation/native-backpack-junk-quality-2026-11-19.json).

<!-- LHO-COLD-BACKPACK-PROVIDER-MATRIX-20261119 -->
19 November. The first backpack hitch reproduced across all three supported Forever provider configurations. Syndicator alone opened the native combined backpack in 155.7002 ms with a 163 ms frame gap. The built-in provider opened the same frame in 150.7081 ms with a 158 ms gap. Their second opens took 25.7392 and 25.6534 ms, with 34 and 36 ms gaps. Both samples opened and closed twice, retained the bag generation and reported zero Lua errors.

Both addons were restored and verified loaded. The active provider was Syndicator and all four original character and overall enable readings were 2. The restored Baganator category backpack still took 150.0066 ms to open, with a 162 ms gap. Its display call took 122.95 ms, of which 122.19 ms fell outside the explicit nested observers. That remainder still includes other descendants. The shared cold hitch does not require either external addon. The native display and FluxUI hooks need separate measurements before any runtime change.

The first test set the character flag, but the timer-driven reload triggered a blocked action in Forever. A direct guarded reload applied that flag. All measured provider sessions had script profiling off. The current jump helper has been rearmed and verified live. [Evidence](validation/cold-backpack-provider-matrix-2026-11-19.json).
<!-- /LHO-COLD-BACKPACK-PROVIDER-MATRIX-20261119 -->

<!-- LHO-BAGANATOR-COLD-OPEN-JUNK-20261119 -->
19 November. With Syndicator and Baganator loaded in Forever, the first category backpack open took 155.4001 ms and coincided with a 168 ms frame gap. Reload 146 reproduced it at 159.3961 ms with a 172 ms gap. Baganator's inclusive category layout took 158.35 ms across the two opens. That timing includes callbacks. The measured FluxUI Junk display callback totaled 4.89 ms over 102 calls. Warm opens took 5.47–7.83 ms and did not invoke the Junk callback in the warm trace. Both opens and closes restored the original closed state and retained the bag generation.

FluxUI now reuses the same per-call junk-list mark for protection and explicit decisions, including the native gray fallback's own check. Per-slot protection, the legacy string key, gray quality and value checks, and the freshness of separate fallback calls are preserved. Lua 5.1 and 5.4 passed and the five installed source copies match.

Reload 150 loaded the change. A warm read over 44 occupied slots cut Restock settings reads from 252 to 170. Both slot-order outputs were entirely false and all observers restored with zero Lua errors. The two unwrapped warm follow-ups took 0.3190/0.3319 ms before and 0.2652/0.2601 ms after. The instrumented read was slower after reload. The result proves fewer settings reads in this workload. The post-change first category backpack open still took 149.1494 ms with a 161 ms frame gap. Junk verdicts were already warm and the measured timing is an unmatched observation. The frame hitch persists. Positive junk marks, other addon combinations and other clients still need native checks. [Evidence](validation/baganator-cold-open-junk-2026-11-19.json).
<!-- /LHO-BAGANATOR-COLD-OPEN-JUNK-20261119 -->

<!-- LHO-RESTOCK-BANK-NONCONSUMABLE-20261119 -->
19 November. A current Forever Auction Restock rebuild took 19.1985 ms, with 13.2688 ms attributable to five bank-tier totals. The closed bank supplied 17 known non-consumable IDs and four consumable IDs. All 17 excluded classes had positive counts whose reads took 3.9094 ms. The follow-up found 105 classifications and zero matching usability checks.

The shared tier matcher now skips the quantity read only when the original classifiers and matching rules rule a known non-consumable out of all tiers. This exclusion lives within one reliable closed-bank list build. Unknown metadata, open banks and replacement providers retain the original path. Native zero counts are never memoized. No new timers or refresh events were added. Both Lua syntax versions pass and the Retail and Forever source hashes match.

After reload 142, two live paired rebuilds in opposite order improved from 31.0528 to 15.4413 ms and from 21.6121 to 17.6776 ms. The paired reads matched every field across nine shared, six visible and one hidden row. Each candidate skipped 17 quantity reads and retained four positive bank quantities. Both generations held, temporary observers restored, and the error count was zero. Commerce windows were closed and there was no active Pending job. Overall FPS spikes and the other client families still need direct verification. [Evidence](validation/restock-bank-nonconsumable-2026-11-19.json).
The three-minute helper was reattached to the current Forever process after the measurements. Native cue setup and calibration passed in the background. Input receipts and a later read-only capture show the first key pair cleared Away and focus returned to the previous app.
<!-- /LHO-RESTOCK-BANK-NONCONSUMABLE-20261119 -->

<!-- LHO-RESTOCK-CLOSED-BANK-COUNTS-20261119 -->
19 November. The idle Pending getter took 0.0146 ms and returned no bank targets. The shared Restock list was the larger cost. The five tier bank totals accounted for 28.115 ms of one 31.8841 ms rebuild. The next native read found 105 positive bank quantities for 21 distinct IDs, with all 84 repeated results agreeing.

Restock now shares positive closed-bank quantities within one list rebuild for the original count owners. Bag and bank generations guard reuse, and open or unsettled inventory retains the original queries. Both Lua files pass Lua 5.1 and 5.4 syntax and match the Forever files. Reload 138 returned to the world. In two opposite-order live Auction House data comparisons with commerce windows closed, the full rebuild took 46.4809/34.6308 ms before and 18.2090/19.5612 ms after. All fields matched across nine shared, six visible, and one hidden vendor row. Each candidate rebuilt its own 21 positive quantities. Both generations held, the observers restored, and zero errors were reported. Active Pending jobs, open commerce windows, other clients and overall frame spikes remain unverified. [Evidence](validation/restock-closed-bank-counts-2026-11-19.json).
<!-- /LHO-RESTOCK-CLOSED-BANK-COUNTS-20261119 -->

<!-- LHO-BANK-TIER-LIVE-COUNTS-20261119 -->
19 November. After the Forever world refresh, one native tier build queried 290 positive bag quantities across 51 item IDs. All 239 repeated results agreed. The bank builder now shares positive counts across tiers within that one rebuild, using the existing public path during reliability holds or with replacement providers. Zero and fallback reads remain live.

Both Lua files pass Lua 5.1 and 5.4 syntax and match the installed Forever copies. Reload 133 returned to the world. Two opposite-order live comparisons reduced tier rebuilds from 16.0921/15.2402 ms to 10.1717/11.1664 ms. Each candidate build used 51 distinct positive counts. All five tier totals matched in both comparisons, neither returned withdrawal rows, and the observer restored with zero errors. This covers the closed-bank rebuild. [Evidence](validation/bank-tier-live-counts-2026-11-19.json).
<!-- /LHO-BANK-TIER-LIVE-COUNTS-20261119 -->

<!-- LHO-BANK-TIER-MATCHER-20261119 -->
19 November. The Forever Bank Restock tooltip's first read took 44.7333 ms for four rows. All four had Count Bank off. The warm read took 1.1500 ms. The 39.9320 ms registry build included 39.712 ms in the consumable tier builder. A follow-up found 250 usability checks, with 135 tooltip reads taking 22.1383 ms before matching native unusable answers.

The tier matcher now checks numeric non-consumable metadata against the defining classifiers before running usability. Unknown metadata, consumable classes and replacement methods keep the existing matching path. Lua 5.1 and 5.4 syntax pass. Retail and Forever file hashes match. Native 129 confirmed reload and world return. Two same-session Forever pairs in opposite order reduced tier rebuilds from 43.3845/44.7337 to 13.8876/15.3005 ms. Usability calls fell 250→90 in both. All five tier totals matched in each pair. Both builders returned zero tier withdrawal rows, all temporary functions were restored, and error counts were zero. Bank-open, eligible withdrawals, active Pending, other clients and frame-spike acceptance remain open. [Evidence](validation/bank-tier-matcher-2026-11-19.json).
<!-- /LHO-BANK-TIER-MATCHER-20261119 -->

<!-- LHO-EBS-BAG-COUNT-PULSE-20261119 -->
19 November. On Forever 1.60.1/70959, reload 120 returned to the world and loaded the current Containers.lua and Mail/Restock.lua revisions. Probe 122 moved and returned Roast Quail ×18. All six slot diffs matched both outputs. Bag generation advanced 5→7, the original slot and count were restored, the destination and cursor were empty, and BugTabs reported zero errors. Both EBS pulses touched the moved item with no total count change. Slot-diff totals were 0.0702/0.0562 ms with asymmetric instrumentation, and EBS baseline paint totaled 0.3059 ms. This is one live event pair. Native frame spikes and the populated mail path remain open.

EBS Paint.lua `808e15ec` → `7bcb33ab` now iterates the same faces in the count pass without allocating a closure or calling it per face. The button and badge order, per-face checks and synchronous delivery are preserved. Before/after Lua 5.1 and 5.4 syntax passed, and Retail and Forever disk hashes match. Reload 123 loaded the edited painter in Forever. Probe 124 repeated the exact item move and return with two matching bag paints and zero reported errors. EBS totaled 0.3059 ms before and 0.3577 ms after. Both slot-diff totals also rose in the second capture. Timing varies across the two reload-separated samples, so the measured benefit remains unverified. The jump helper remains stopped. [Evidence](validation/ebs-bag-count-pulse-2026-11-19.json).
<!-- /LHO-EBS-BAG-COUNT-PULSE-20261119 -->

<!-- LHO-SLOT-DIFF-TOUCH-20261119 -->
19 November. `Inventory/Containers.lua` `d043cfe0` → `372664bf` simplifies the shared built-in and Syndicator slot-diff path. The old-slot pass records same-item count and link changes. The new-slot pass on normalized maps only needs to mark new slots and replacement IDs. Both delta loops retain their original arithmetic and order. Map metatables retain the full comparison. Provider coordination and count delivery cadence stay in place.

Lua 5.1 and 5.4 passed for both files in the before/after check. Retail and Forever disk copies match. Native 119 was a read-only view of fresh raid join and leave activity. No test command, item move, jump or reload was sent in this slice. The next live proof needs a safe opportunity to reload, then a real bag or bank update on the new revision. Earlier cast-to-bag and item move captures remain valid for their dated source sets.
[Source and current native evidence](validation/inventory-slot-diff-touch-2026-11-19.json).
<!-- /LHO-SLOT-DIFF-TOUCH-20261119 -->

<!-- LHO-RECIPE-PAIR-MAIL-QUEUE-20261119 -->
19 November. Forever native 118 paired the loaded modern recipe lookup with its full-catalogue fallback in the same session. Three passes over 147 eligible saved recipes returned the same knownness and exact saved record in all 441 pairs. Median pass total fell from 138.5646 ms to 43.3418 ms (68.7%). Both method identities were restored and the session error count was zero. The fallback used one forwarding call. The longest diagnostic batch took 5.902 ms. Full workflow and frame-spike timing remain open.

`Mail/Restock.lua` `09f764dc` → `952b6a19` creates the action row only on the first matching restock attachment. An eligible message with no match now allocates none of the three queue tables. It contributes the same attachment counts to the authority scan. Header and attachment reads, scan budget, COD and GM checks, retries and publication stay intact. Before/after Lua 5.1 and 5.4 syntax passed. The Forever disk copy now matches, and native adoption is pending. The existing populated-mail authority decision remains open. No new simulation, item action or jump was performed.
[Native recipe comparison](validation/modern-recipe-paired-native-2026-11-19.json). [Mail source and verification](validation/mail-lazy-queue-rows-2026-11-19.json).
<!-- /LHO-RECIPE-PAIR-MAIL-QUEUE-20261119 -->

<!-- LHO-FIXED-RECIPE-SLOTS-20261119 -->
18–19 November. Auction craft planning now appends each fixed reagent to its private variant in place. This removes the prefix copies for single-option slots. Multi-option expansion, the 64-variant cap, allocation order and native recipe verification stay on their existing paths. `FluxAuctionRestockCraft.lua` changes from `8462442f` to `143c59c1`. Four before/after Lua 5.1 and 5.4 syntax checks and six Retail/Forever disk hash comparisons passed.

Forever reload 115 completed and native 116 returned the same IDs, yield, variant count and slot count for actual bandage items 8544 and 3530. The two individual full-query pairs were 0.9445→1.0710 ms and 0.7717→0.7018 ms. Native 117 confirmed recipe 18560 known with one reagent and a present item 1191 hyperlink matching the snapshot with the bank closed. Current build was 1.60.1/70959/16001 with the Syndicator provider and zero session errors reported. All accepted reads were visually confirmed and released. No craft, item transaction, profiler setting change or jump occurred. Full field, frame-spike, multi-option and remaining workflow/client checks stay open. No further reload is needed for these exact source files while the current session remains loaded.
[Exact files and live results](validation/fixed-recipe-slots-2026-11-19.json).
<!-- /LHO-FIXED-RECIPE-SLOTS-20261119 -->

<!-- LHO-BANK-SNAPSHOT-LINK-20261118 -->
18 November. Cold item metadata can fall back to one link from the bank and carried snapshots. Index.lua (`e2f7919a` → `452aa904`) and FluxRestock_Inv.lua (`4488ee52` → `f3890c5e`) now read that link in the same carried, character bank and supported warband order without allocating an item map or its per-item records. The existing live stack check runs first. Replacement public getters keep the full-map path.

Eight before/after Lua 5.1 and 5.4 syntax checks passed. Both edited files match the Forever copies on disk. After the diagnostic text closed, native 113 queued two read-only queries. The output capture guard stopped during a focus change. An independent screenshot showed fresh startup messages and a group invitation, with neither result visible. The reservation was released. Native adoption and timing of the link and modern recipe lookups remain pending, as do the stale closed-bank case and populated-mail authority decision. The full goal stays active.
[Exact source, observed client state and validation limits](validation/bank-snapshot-link-2026-11-18.json).
<!-- /LHO-BANK-SNAPSHOT-LINK-20261118 -->

<!-- LHO-MODERN-RECIPE-KNOWLEDGE-20261118 -->
18 November. The goal dashboard is active again. Professions.lua `9a12130d` → `24b89db1` limits a standard modern `GetRecipeKnowledge` query to catalogue keys for the requested recipe. It still walks the saved records, applies the same revocation rules and ranks every matching alias in the original order. Legacy descriptors and replacement catalogue getters still take the full path. There is no persistent cache or change to recipe validation cadence.

All four before/after Lua 5.1 and 5.4 syntax checks passed. Retail and Forever disk hashes match. The earlier native capture supplied 148 real catalogue records and exercised a different live recipe query. AH111 and charge112 stopped before input, with both reservations released. The client showed a focused BugTabs copy field and one raid secure-handler stack with its top error line clipped. No reload or jump was sent by this continuation. Candidate adoption and timing remain pending. Keep the full inventory, casting, client and provider acceptance matrix open.
[Exact source and native evidence](validation/modern-recipe-knowledge-2026-11-18.json).
<!-- /LHO-MODERN-RECIPE-KNOWLEDGE-20261118 -->

<!-- LHO-CARRIED-SCAN-COUNT-20261118 -->
18 November continuation. The carried-consumable scan skips one options-table allocation per canonical bag snapshot count. It reads the same current snapshot through the same index method and capability check. The public fallback still receives its original fresh options when either getter is replaced. Saved-potion eligibility reuse now also requires the original classifier methods and a plain classifier table.

Lua 5.1 and 5.4 before/after syntax passed. Native 109 in Forever 1.60.1 / 70959 observed zero eligible saved-reference passes and restored the temporary wrappers. Probe 110 ended before input. These captures preceded the new Lua edits. Native adoption, matched frame times and remaining LHO-01–13 workflow acceptance are pending. The jump helper remains stopped from the earlier pause. The goal dashboard still reports paused despite the text request to continue.
[Exact source identities and native evidence](validation/carried-scan-count-2026-11-18.json).
<!-- /LHO-CARRIED-SCAN-COUNT-20261118 -->

<!-- LHO-PAUSED-20261118-FINAL -->
USER PAUSED FULLY: no commands/tests/edits/jumps until explicit "continue". Saved18November. Actual Persist7082172e/Scan21883c7d edits adopted by101guardedreload/freshstartup;native10354counts match,food1487-14-841 unchanged,bothprovidersready,queue4/errors0/preferences0-120-30,cursorclear. After-timing104did NOT run:104a modifierguard stopped before input;pending retry auto-review rejected because user paused. Gain/fullrecord/override/reentry/native-otherclient/FPS/hitch acceptance remainsPENDING. Baseline99/100 samples and source proof/8syntaxchecks retained.

All testing/jumps stopped. R20supervisor37448 stopped-before-launch/verified absent;noR20host. EarlierR19host33664 stopped before101reload. CANCEL/nativeJUMP_STOP remain. Pause-only guardedReloadUI was queued bypause1811reload_b;fresh startup confirmation failed because WoW was minimized. Do not claim confirmed final reload/world return. Latest user insists fullstop,so no further verification now. On continue revalidate actual session/current source;temporary probes/cue must be freshly installed only if needed. Never replay spent commands. Preserve all newer/unrelated work. Full original optimization scope unfinished.
[Resume checkpoint](validation/persist-ref-eligibility-2026-11-18.json).
<!-- /LHO-PAUSED-20261118-FINAL -->

<!-- ROSTER-GEOMETRY-PORTRAITS-R71-20261118 -->
R71 covers the remaining duplicate roster geometry and party model work. In five matched desktop trials, raid header anchor writes fell from 21,600 to 2,500 per trial and container width writes from 2,400 to 200. Twenty same-member party paints issued one model reset. Final layout snapshots matched. The five source-family combat fixture exercised 1,800 transitions with zero combat frame allocations.
[R71 source pins, replay counts and validation](validation/roster-geometry-and-portraits-2026-11-18.json).
<!-- /ROSTER-GEOMETRY-PORTRAITS-R71-20261118 -->

<!-- ROSTER-RESTRICTED-PARSER-R72-20261118 -->
Reproduced the exact archived R71 startup rejection and validated R72 across all five supplied client parsers. Matched desktop raid-border replays reduced visibility setter calls from 1,120 to zero for an unchanged 40-cell grid and from 1,092 to 56 when one member leaves. The visible trim results matched in every sample.
[R72 source and validation evidence](validation/roster-restricted-parser-2026-11-18.json).
<!-- /ROSTER-RESTRICTED-PARSER-R72-20261118 -->

<!-- PARTY-ROSTER-LOCALITY-R73-20261119 -->
Matched R72 and R73 production-source replays over 20 party transitions. Player-style party skipped all 20 hidden compact layouts, and raid-style party cut unit reads from 1,600 to 100 while keeping the active column paint. Twenty additional stable-member roster paints issued zero cast resets. Replacements, hidden frames and private identity still refresh.
[R73 evidence](validation/party-roster-locality-2026-11-19.json).
<!-- /PARTY-ROSTER-LOCALITY-R73-20261119 -->

<!-- GROUP-RENDER-R74-20261119 -->
Audited 19 reachable Lua owners referencing roster and group transition events, plus the indirect native raid suppression and border builder. Matched source replays reduced dependency visits from 3,260 to 80 in the shared-branch case and nameplate refreshes from 640 to 32 for twenty notifications with 32 plates. Native raid overlays already hidden received zero repeated paint writes. Twenty minimap group notifications still update difficulty and queues twenty times and skip tracking and landing-page updates.
[R74 evidence](validation/group-render-work-2026-11-19.json).
<!-- /GROUP-RENDER-R74-20261119 -->

<!-- ROSTER-REGION-ROUTING-R75-20261119 -->
Compared R74 and R75 source directly. Regional planning preserved 144 output fields and reduced clipping helper calls from 2,816 to 144 in the modeled group scene. Five matched median samples were 2.660 ms before and 0.960 ms after. Twenty prepared focus aura refreshes preserve paint while removing 40 anchor writes and 40 to 80 size writes. Raid reveal event writes fell from 1,920 to 960 per policy across the tested lifecycle.
[R75 evidence](validation/roster-region-routing-2026-11-19.json).
<!-- /ROSTER-REGION-ROUTING-R75-20261119 -->

<!-- ROSTER-RETURN-PLANS-R76-20261119 -->
Paired canonical-art regional replays covered both border types. Returning to a known shape cut median branch recompiles from 16 to zero and fallback geometry computations from 896 to 56. Complete field fingerprints matched in both poses. Repeat switch median in the desktop fixture was 133 ms before and 97.5 ms after. Across five modeled client policies, twenty paired raid reveal sequences reduced aura refreshes from 60 to 40 while retaining all 960 event registrations.
[R76 evidence](validation/roster-return-plans-2026-11-19.json).
<!-- /ROSTER-RETURN-PLANS-R76-20261119 -->

<!-- ROSTER-LOCAL-FALLBACK-R77-20261119 -->
Matched canonical regional replays for both styles and both poses. The first switch visits 345 fallback candidates instead of 867 and copies zero duplicate metadata scalars instead of 33,408. Twenty same-geometry raid rebinds stop repeating 44,400 geometry comparisons. Optional part tests again reject the old missing-branch policy. A texture-coordinate memo stayed external after inconsistent timing.
[R77 evidence](validation/roster-local-fallback-2026-11-19.json).
<!-- /ROSTER-LOCAL-FALLBACK-R77-20261119 -->

<!-- ROSTER-PREPARED-LAYOUT-R78-20261119 -->
The paired roster fixture removes 80 to 92 roster-info reads per modeled raid update and one duplicate layout per modeled party transition. Sixty regional switches cut owner index passes from six to three and operation-scope checks from 1,125–1,126 to 951 per switch. Exact rendered fields match.
[R78 evidence](validation/roster-prepared-layout-2026-11-19.json).
<!-- /ROSTER-PREPARED-LAYOUT-R78-20261119 -->

<!-- REGIONAL-CLIPPING-R79-20261119 -->
Exact polygon/texture coordinate checks matched 5,976 fields, with clipping plane calls reduced from 32,768 to 17,544. The target/focus roster replay removes 960 repeated anchor writes across 160 stable updates. An internal mini reorder avoids three shell clears, three anchors and one player relayout. A dense renderer replay is inconclusive because the R78 same-version control showed output drift.
[R79 evidence](validation/regional-clipping-2026-11-19.json).
<!-- /REGIONAL-CLIPPING-R79-20261119 -->

<!-- GRID-ENVELOPE-R80-20261119 -->
The held-action replay skips eight pre-layout envelope calls across four enter/leave edges. The paired panel replay reduces Info refreshes from four to one, envelope calls from three to one and explicit border commits from two to one. Roster native-name reads fall from 99 to six with the same unregister order.
[R80 evidence](validation/grid-envelope-2026-11-19.json).
<!-- /GRID-ENVELOPE-R80-20261119 -->

<!-- INDEXED-REGIONS-R81-20261119 -->
The two-style, 24-pair local replay reduces strip overlap checks from 837–867 to 53 per update, segment writes from 864 to 36, and strip level reads from 56–58 to 13. The modeled dock update reduces overlap checks from 513–515 to 41 and segment writes from 640 to 32. Geometry counts and sampled fields match. The mixed-scope oracle reduces checks from 36,444 to 272.
[R81 evidence](validation/indexed-regions-2026-11-19.json).
<!-- /INDEXED-REGIONS-R81-20261119 -->

<!-- INDEXED-NEIGHBORS-R82-20261119 -->
The R82 source model kept the same selections for 692 segments and reduced overlap checks from 44,374 to 128. The isolated search took 1.913 to 0.821 ms at the median. Full rebuild timings varied. The two styles retain matching sampled fields.
[R82 evidence](validation/indexed-neighbors-2026-11-19.json).
<!-- /INDEXED-NEIGHBORS-R82-20261119 -->

<!-- RAID-CELL-NEIGHBORS-20261119 -->
Compared both overlap models with 1,338 connected-grid checks. Thirty-six alternate-order timing pairs measured the membership refresh median at 0.115 to 0.080 ms for both models. Native widget work and other roster callbacks lie outside this timing.
[Raid cell evidence](validation/raid-cell-neighbors-2026-11-19.json).
<!-- /RAID-CELL-NEIGHBORS-20261119 -->

<!-- ROSTER-ADJUNCT-DISPATCH-20261119 -->
In five alternating pairs over five client models, aura reads fell from 880 to 440 for a 40-cell roster burst with optional marks enabled. The complete unit paints stayed at 40. With optional marks disabled the standalone sweep fell from 40 calls to zero. Both cases use one roster timer instead of two.
[Adjunct dispatch evidence](validation/roster-adjunct-dispatch-2026-11-19.json).
<!-- /ROSTER-ADJUNCT-DISPATCH-20261119 -->

<!-- SOURCE-RENDER-CONTEXT-R83-20261119 -->
R83 paired renders preserve mesh fingerprints. A 96-field raised seam reduces source-parent reads from 96 to 2 and strip strata reads from 48 to 1. Full modeled rebuild timing varied. The isolated renderer and operation counts are recorded.
[R83 evidence](validation/source-render-context-2026-11-19.json).
<!-- /SOURCE-RENDER-CONTEXT-R83-20261119 -->

<!-- FRAGMENT-OWNERS-R84-20261119 -->
R84 keeps sampled screen output and operation counts while reducing strip fragment owner writes from 828–916 to 131–152. Isolated owner planning went from a 0.224 ms median to 0.072 ms. Full desktop rebuild elapsed remained mixed.
[R84 evidence](validation/fragment-owners-2026-11-19.json).
<!-- /FRAGMENT-OWNERS-R84-20261119 -->

<!-- PREPARED-LAYERS-R85-20261119 -->
R85 passed 24 paired work replays, 80 paired elapsed samples, and nine isolated timing pairs. The held-action model medians moved from 16 to 15 ms and 18 to 17.5 ms. The 40-parent isolated layer model moved from 0.075 to 0.028 ms. Both measure desktop Lua and modeled widgets.
[R85 evidence](validation/prepared-layers-2026-11-19.json).
<!-- /PREPARED-LAYERS-R85-20261119 -->

<!-- ROSTER-MACRO-BATCH-20261119 -->
Five paired desktop runs kept the strip action slot and both macro display identities across join, conversion and leave sequences. The 60-event conversion burst with both watchers moved from 120 full snapshots and three eval requests to one snapshot and one request. Unchanged bursts add one scheduler check and skip macro parsing.
[Macro roster batch evidence](validation/roster-macro-batch-2026-11-19.json).
<!-- /ROSTER-MACRO-BATCH-20261119 -->

<!-- TILE-FIELD-REJECTION-R86-20261119 -->
R86 passed 24 paired work replays, 80 paired elapsed samples and nine isolated timing pairs. The isolated clipping median was 2.61 to 1.59 ms. Whole-reflow desktop timings were mixed and do not establish native latency.
[R86 evidence](validation/tile-field-rejection-2026-11-19.json).
<!-- /TILE-FIELD-REJECTION-R86-20261119 -->

<!-- STRIP-POSE-TOPOLOGY-R87-20261119 -->
R87 action-strip replay in both styles reduces six crossings from six solves and plans to two each. Warm desktop border reflow medians moved from 16.0 and 18.5 ms to 7.0 ms. The adjoining panels are part of the matched replay. The first two poses in each model still build synchronously.
[R87 evidence](validation/strip-pose-topology-2026-11-19.json).
<!-- /STRIP-POSE-TOPOLOGY-R87-20261119 -->

<!-- INDIVIDUAL-ROSTER-BATCH-20261119 -->
Paired individual frame runs cover solo, party and raid joins, leaving and conversion. The 40-member subgroup case drops from 40 row reads to one. Same-subgroup rejoin, timerless clients, reentrant work, a failed frame, and private indices are checked.
[Individual unit roster evidence](validation/individual-roster-batch-2026-11-19.json).
<!-- /INDIVIDUAL-ROSTER-BATCH-20261119 -->

<!-- STRIP-CHROME-MINIMAP-ROSTER-20261119 -->
Matched models cover Retail/Forever and Classic strip art, two repeated hover cycles, changed art, float-rounded colors, opaque opacity, explicit accents and squeezed width. Minimap exercise covers four shapes, combat crossover, timerless dispatch and a full indicator pass replacing queued work.
[Strip and minimap evidence](validation/strip-chrome-minimap-roster-2026-11-19.json).
<!-- /STRIP-CHROME-MINIMAP-ROSTER-20261119 -->

<!-- PREPARED-STRIP-SAMPLING-R88-20261119 -->
The paired desktop replay eliminates 317 to 401 texture-coordinate calculations on repeated strip crossings. Empty fallback setup falls from 139 to 143 calls down to 22 to 23. The exact field comparison covers both styles and a synthetic dock transition.
[Border sampling evidence](validation/prepared-strip-sampling-2026-11-19.json).
<!-- /PREPARED-STRIP-SAMPLING-R88-20261119 -->

<!-- BORDER-SETTERS-THREAT-ROSTER-R89-20261119 -->
The setter microbenchmark compares archived and current source across twelve paired runs per path. Equal UV arrays, four and eight coordinate forms and art invalidation preserve exact native writes. The Details replay reduces 20 scans to one for each of four modeled roster bursts, retaining final group state.
[Setter and threat roster evidence](validation/border-setters-threat-roster-2026-11-19.json).
<!-- /BORDER-SETTERS-THREAT-ROSTER-R89-20261119 -->

<!-- FINAL-STRIP-UNIT-ANCHORS-R90-20261119 -->
The paired strip replay covers 36 crossings across both target placements and three scales. The screen-position pass runs twice before and once afterward, with no full target pass for stable placement. The changed-envelope case now uses its final top at the junction commit.
[Strip unit anchoring evidence](validation/final-strip-unit-anchors-2026-11-19.json).
<!-- /FINAL-STRIP-UNIT-ANCHORS-R90-20261119 -->

<!-- STRIP-GRID-PACKING-R91-20261119 -->
Twenty matched crossings with 16 buttons avoid 116 modeled grid widget writes, 16 face refreshes and both internal packing passes per crossing. The final model geometry and Info agree. Squeeze and slot changes, drift repair and protected deferral are exercised.
[Strip grid packing evidence](validation/strip-grid-packing-2026-11-19.json).
<!-- /STRIP-GRID-PACKING-R91-20261119 -->

<!-- STRIP-PANEL-SETTLE-R92-20261119 -->
The Info replay spans 32 matched crossings in four placements. The Trinket Menu replay covers 40 matched crossings with one squeeze and no steady anchor reset. Regression cases include changing gap width, replacement at identical bounds and native anchor repair.
[Strip panel settlement evidence](validation/strip-panel-settle-2026-11-19.json).
<!-- /STRIP-PANEL-SETTLE-R92-20261119 -->

<!-- RAID-ROSTER-ATTACHMENT-PAINT-R93-20261119 -->
Ten matched replays cover five client models and 5/40 member groups. The 40-member case reduces MT/MA child reads from 50 to two, raid paint loot queries from 41 to one and indicator loot queries from 42 to one. Aura paints and per-unit looter matching agree.
[Raid roster paint evidence](validation/raid-roster-attachment-paint-2026-11-19.json).
<!-- /RAID-ROSTER-ATTACHMENT-PAINT-R93-20261119 -->

<!-- STRIP-LAYER-COMMIT-R95-20261119 -->
Six simulated crossings across both border types and three scales reduce decorative canvas layer reads from 2,940–3,912 to 192–240. Stable-width crossings reduce exterior writes from 36 to zero. Each 20-notification fallback roster burst reduces public condition parses from 42 to four. Compared exact archived source and candidate in desktop models.
[Matched validation](validation/strip-layer-commit-2026-11-19.json).
<!-- /STRIP-LAYER-COMMIT-R95-20261119 -->

<!-- STRIP-RELATIVE-ANCHORS-R96-20261119 -->
Across six matched crossings, action-button point writes fell from 834 to 312 for sparse layouts and 924 to 300 for dense layouts. The outer border retained its four native points across eight crossings for each of the four Info placements. Both replays kept final points and mapped actions equivalent.
[Matched validation](validation/strip-relative-anchors-2026-11-19.json).
<!-- /STRIP-RELATIVE-ANCHORS-R96-20261119 -->

<!-- CONSUMABLE-ROSTER-BINDINGS-R97-20261119 -->
Thirty matched 20-event roster bursts across five modeled clients and two spellbook paths reduce Food and Water binding refresh calls from 21 to zero and Food updates from 20 to zero. The routes and inventory counts agree. Food retains middle-click suppression through the roster changes. The separate pending-read fixture fails the same foreign-readiness assertion with archived and current Food and Water for both providers.
[Matched validation](validation/consumable-roster-bindings-2026-11-19.json).
<!-- /CONSUMABLE-ROSTER-BINDINGS-R97-20261119 -->

<!-- STRIP-SLOT-SAMPLING-R98-20261119 -->
Across eight matched held-cursor crossings in each of four layouts, the visual pass cuts modeled action reads from 1,212–1,448 to 432–460 and active-page reads from 156–160 to four. Final mapped actions, geometry, promotion flags and panel and border callbacks match.
[Matched validation](validation/strip-slot-sampling-2026-11-19.json).
<!-- /STRIP-SLOT-SAMPLING-R98-20261119 -->

<!-- RAPID-STRIP-DROPS-R99-20261119 -->
Twelve matched pickups and drops reduce mapping writes from 2,052 to 108 and avoid twelve repeat full stock sweeps and twelve full paints. In the separate regional replay, eight width changes use two solves and two plans instead of eight for each border type. Six reuse verified side joins, with matching sampled output.
[Matched validation](validation/rapid-strip-drops-2026-11-19.json).
<!-- /RAPID-STRIP-DROPS-R99-20261119 -->

<!-- REGIONAL-FRAGMENT-READS-R100-20261119 -->
Eight paired strip width updates reduce source draw-layer reads from 1,296 to 488 and opacity reads from 1,600 to 976 per border type. The local join replay reduces draw-layer reads from 208 to 64. Both samples preserve the final fields and react to changed layers and live paint.
[Matched validation](validation/regional-fragment-reads-2026-11-19.json).
<!-- /REGIONAL-FRAGMENT-READS-R100-20261119 -->

<!-- STRIP-JOIN-SOURCES-R101-20261119 -->
Eight held-action crossings reduce modeled source-parent reads from 2,448 to 1,232 in type 1 and from 2,280 to 1,216 in type 2. Samples match the archived renderer and keep reacting to changes in layer, paint and visibility. Local join changes and same-pose width changes also pass.
[Matched validation](validation/strip-join-sources-2026-11-19.json).
<!-- /STRIP-JOIN-SOURCES-R101-20261119 -->

<!-- REGIONAL-LAYOUT-INDEX-R102-20261119 -->
Six held-action reflows with 40 raid outlines present reduce sorted stamp entries from 2,352 to 192 and exact edge probes from 1,998 to 78 per style. Six roster movement reflows reduce edge probes from 1,932 to 60. Sampled joins and retained cell identity match the archived renderer.
[Matched validation](validation/regional-layout-index-2026-11-19.json).
<!-- /REGIONAL-LAYOUT-INDEX-R102-20261119 -->

<!-- REGIONAL-TILE-MATERIALS-R103-20261119 -->
Local tile material collection reduces source reads from 144 to 129 in the first two held-action crossings and from 288 to 258 across four repeats, per style. The roster replay drops from 160 to 66 and 320 to 132. Art samples and solve counts match. The mask controls cover both unused caps and participating strokes.
[Matched validation](validation/regional-tile-materials-2026-11-19.json).
<!-- /REGIONAL-TILE-MATERIALS-R103-20261119 -->

<!-- RAID-ROSTER-NATIVE-WRITES-R104-20261119 -->
The six-update exact-source replay removes 60 secure reference writes, 108 legacy anchor writes, six width writes and 102 label writes from stable passes. It covers drift repairs, opaque backing handles, changed labels and combat deferral. The active roster suite also covers join, leave, conversion and secure failure recovery.
[Matched validation](validation/raid-roster-native-writes-2026-11-19.json).
<!-- /RAID-ROSTER-NATIVE-WRITES-R104-20261119 -->

<!-- REGIONAL-ROSTER-POSES-R105-20261119 -->
Eight paired party or raid geometry changes reduce solves and plans from eight to two per style. Modeled join pixels and listener indexes agree. Fresh UV invalidates a saved paint plan and a new position still solves. The identical-tile alternative found no useful reuse in these reflows. The timing replay shows the first two builds can cost slightly more, with both styles faster across the next 32 moves.
[Matched validation](validation/regional-roster-poses-2026-11-19.json).
<!-- /REGIONAL-ROSTER-POSES-R105-20261119 -->

<!-- REGIONAL-BORDER-CUTS-R106-20261119 -->
The first two held-action layouts use 13–14 percent fewer subtraction result lists. Roster moves with resource and portrait dividers use 18–20 percent fewer. The longer overlap model uses about 41 percent fewer lists and matches exact fallback drawing. The standalone subtraction loop is faster in all seven paired trials. Complete reflow timings are mixed. Raw timing and the initial slower variant are retained with the replay.
[Matched validation](validation/regional-border-cuts-2026-11-19.json).
<!-- /REGIONAL-BORDER-CUTS-R106-20261119 -->

<!-- HELD-ACTION-REFLOW-R107-20261119 -->
Prepared border descriptor visits fell to 990 from 3810 in type 1, 930 from 4284 in type 2 over twelve crossings. The final scope passed 23 desktop replays and 1249 Lua syntax checks. The earlier prototype exceeded the fixture's Lua local-slot budget and was replaced by a scoped helper.
[Matched validation](validation/held-action-reflow-2026-11-19.json).
<!-- /HELD-ACTION-REFLOW-R107-20261119 -->

<!-- INDEPENDENT-BORDER-REGIONS-R108-20261119 -->
Each movement of one party member replaces one output region, compared with six to nine screen tiles. Hover replays retain all four party paint generations and plan half as many source segments. The final scope passed 32 desktop replays and 1250 Lua syntax checks. Timed comparisons record first builds and prepared crossings separately.
[Matched validation](validation/independent-border-regions-2026-11-19.json).
<!-- /INDEPENDENT-BORDER-REGIONS-R108-20261119 -->

<!-- COMPACT-RAID-SEAM-DELTAS-R109-20261119 -->
A single leave uses 111 instead of 627 seam distance checks, a join uses 111 instead of 660, and a moved cell uses 210 instead of 648. The final scope passed 37 desktop replays and 1250 Lua syntax checks. Bulk refresh and movement timings are recorded separately.
[Matched validation](validation/compact-raid-seam-updates-2026-11-19.json).
<!-- /COMPACT-RAID-SEAM-DELTAS-R109-20261119 -->

<!-- RAID-AURA-PRESENTATION-R110-20261119 -->
Twenty stable 40-cell repaints skip 8,000 redundant visibility writes. With one cell leaving and rejoining, writes fall from 8,000 to 70 and all 210 necessary unit writes agree. The final scope passed 39 desktop replays and 1250 Lua syntax checks. Repeated strict-filter edits show mixed desktop timings.
[Matched validation](validation/raid-aura-presentation-2026-11-19.json).
<!-- /RAID-AURA-PRESENTATION-R110-20261119 -->

<!-- RAID-UNIT-PAINT-READS-R111-20261119 -->
A full 40-cell roster pass uses 160 health and connection-related reads instead of 520 in the Forever and Retail models. Classic models use 200 instead of 600. The final scope passed 39 desktop replays and 1250 Lua syntax checks. Complete desktop timings were mixed.
[Matched validation](validation/raid-unit-paint-reads-2026-11-19.json).
<!-- /RAID-UNIT-PAINT-READS-R111-20261119 -->

<!-- STRIP-BORDER-REFRESH-R112-20261119 -->
Twelve held-action crossings eliminate 402 to 456 repeated scale writes. Border group visits drop from 1176 to 784 per eight reflows. The final scope passed 44 desktop replays and 1250 Lua syntax checks. Complete desktop timings were mixed.
[Matched validation](validation/strip-border-refresh-2026-11-19.json).
<!-- /STRIP-BORDER-REFRESH-R112-20261119 -->

<!-- STRIP-HOVER-PAINT-R113-20261119 -->
Twelve settled crossings skip 612 to 684 repeated size writes and reduce icon updates from 276 to 108 or from 336 to 84. The final scope passed 50 desktop replays and 1250 Lua syntax checks. The matched desktop median was 63 to 62 ms for 320 sparse crossings and 64 to 58 ms for dense crossings.
[Matched validation](validation/strip-hover-paint-2026-11-19.json).
<!-- /STRIP-HOVER-PAINT-R113-20261119 -->

<!-- BORDER-VISIBILITY-FANOUT-R114-20261119 -->
Eight prepared border visibility updates reduce parent reads from 42886 to 274 in both border types. Repeated gate queries during the synthetic commit fall from 64 to 16. The final scope passed 57 desktop replays and 1250 Lua syntax checks. The isolated visibility model improved substantially. Warm reflow medians for the populated HUD moved by 0 to 6 ms per eight transitions.
[Matched validation](validation/border-visibility-fanout-2026-11-19.json).
<!-- /BORDER-VISIBILITY-FANOUT-R114-20261119 -->

<!-- BORDER-DRAW-GEOMETRY-R115-20261119 -->
For the same fields across eight warm held-action reflows, vertex-offset comparisons drop from 7040 to 3024 in Type 1 and from 8112 to 3424 in Type 2. The final scope passed 63 desktop replays and 1250 Lua syntax checks. The timing evidence covers 24 warm reflows per paired trial.
[Matched validation](validation/border-draw-geometry-2026-11-19.json).
<!-- /BORDER-DRAW-GEOMETRY-R115-20261119 -->

<!-- ROSTER-DISCOVERY-REFRESH-R116-20261119 -->
A 40-plate roster batch needs one combo target lookup, down from 41 when the target has no visible plate. Across twenty hover discoveries, raid ownership reads fall from 2200 to 20 and forbidden checks from 1960 to 21. The final scope passed 71 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/roster-discovery-refresh-2026-11-19.json).
<!-- /ROSTER-DISCOVERY-REFRESH-R116-20261119 -->

<!-- STRIP-VISIBILITY-R117-20261119 -->
Eight warm crossings reduce visibility listener attach and detach entries from 1952 to 704 in Type 1 and from 1696 to 704 in Type 2. The sixty same-update cursor reversals skip 60 key refreshes and 180 native width reads. The final scope passed 71 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/strip-visibility-2026-11-19.json).
<!-- /STRIP-VISIBILITY-R117-20261119 -->

<!-- RAID-PAINT-BATCH-R118-20261119 -->
A 40-cell compact paint reads each shared option once and halves class lookups from 80 to 40. The name painter owns the role-icon hide, removing 40 duplicate writes. The readable aura path paints dispel highlights once per cell. The final scope passed 76 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/raid-paint-batch-2026-11-19.json).
<!-- /RAID-PAINT-BATCH-R118-20261119 -->

<!-- RAID-REASSIGNMENT-R119-20261119 -->
Three reassignment waves across 40 compact cells drop from 160 full paints to 40. Paired companion roster requests drop from 82 to 41 paints for the raid and from 12 to 6 for the party. The final scope passed 76 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/raid-reassignment-2026-11-19.json).
<!-- /RAID-REASSIGNMENT-R119-20261119 -->

<!-- STRIP-CHAT-DOCK-R120-20261119 -->
Twenty settled held-action crossings with matching chat and raid positions remove 100 chat widget writes, 40 saved-position and dimension calls, 40 focus partition calls and 60 focus aura layout entries in the desktop replay. The final scope passed 81 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/strip-chat-dock-2026-11-19.json).
<!-- /STRIP-CHAT-DOCK-R120-20261119 -->

<!-- STRIP-PAINT-INDEX-R121-20261119 -->
Eight warm cursor crossings with a held action reduce regional paint membership visits from 10,560 to 1,664 for type 1 and 12,264 to 1,640 for type 2. The final scope passed 81 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/strip-paint-index-2026-11-19.json).
<!-- /STRIP-PAINT-INDEX-R121-20261119 -->

<!-- BORDER-VISIBILITY-COMMIT-R122-20261119 -->
Eight warm cursor crossings reduce parent-frame visibility and opacity reads from 944 to 80 in each border style. Matched desktop seam and color samples agree. The final scope passed 81 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-visibility-commit-2026-11-19.json).
<!-- /BORDER-VISIBILITY-COMMIT-R122-20261119 -->

<!-- PARTY-DISPEL-IDENTITY-R123-20261119 -->
A stable four-member roster batch now triggers zero native debuff owner refreshes in the Retail and Forever models. A one-member replacement uses three refreshes instead of twelve. The final scope passed 84 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/party-dispel-identity-2026-11-19.json).
<!-- /PARTY-DISPEL-IDENTITY-R123-20261119 -->

<!-- UNIT-NAME-STRIP-GEOMETRY-R124-20261119 -->
Thirty settled unit border refreshes remove 360 size and point writes per frame with class and spec icons plus their two dividers in the desktop replay. The final scope passed 91 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/unit-name-strip-geometry-2026-11-19.json).
<!-- /UNIT-NAME-STRIP-GEOMETRY-R124-20261119 -->

<!-- BORDER-POSE-SAMPLES-R125-20261119 -->
Eight prepared cursor crossings share 516 exact texture-coordinate arrays per border style. The renderer still samples every live source, and modeled heap growth falls by roughly 176 to 182 KiB. The final scope passed 92 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-pose-samples-2026-11-19.json).
<!-- /BORDER-POSE-SAMPLES-R125-20261119 -->

<!-- BORDER-PREPARED-DRAW-R126-20261119 -->
Eight prepared held-action crossings share 312 existing tile plans in the desktop replay. Median heap growth falls by 27.2 to 289.7 KiB across the strip and roster fixtures. The final scope passed 96 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-prepared-draw-2026-11-19.json).
<!-- /BORDER-PREPARED-DRAW-R126-20261119 -->

<!-- BORDER-DRAW-INPUTS-R127-20261119 -->
Eight warmed held-action crossings reused 48 draw-input lists per style. New input entries fell from 12,996 to 9,588 in type 1 and from 12,232 to 8,960 in type 2. The final scope passed 96 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-draw-inputs-2026-11-19.json).
<!-- /BORDER-DRAW-INPUTS-R127-20261119 -->

<!-- BORDER-SPRITE-REUSE-R128-20261119 -->
Eight warmed held-action crossings removed 1,556 type 1 and 1,776 type 2 per-sprite binding tables in the median replay. Heap growth fell by 151 to 176 KiB. The final scope passed 96 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-sprite-reuse-2026-11-19.json).
<!-- /BORDER-SPRITE-REUSE-R128-20261119 -->

<!-- ROSTER-ROLE-CHROME-R129-20261119 -->
Twenty settled role refreshes across player, target and focus reduce modeled texture writes from 3,120 to zero. Matched geometry is identical in the five paired runs. The final scope passed 97 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/roster-role-chrome-2026-11-19.json).
<!-- /ROSTER-ROLE-CHROME-R129-20261119 -->

<!-- STRIP-HOVER-MAPPINGS-R130-20261119 -->
Six crossings with an action held reduce modeled protected attribute writes from 1,026 to 594 and mapping slot queries from 300 to 186 in both mini-row positions. The final scope passed 100 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/strip-hover-mappings-2026-11-19.json).
<!-- /STRIP-HOVER-MAPPINGS-R130-20261119 -->

<!-- STRIP-HOVER-KEYS-R131-20261119 -->
Six held-action crossings remove 114 binding key queries in both the wrapped and Forever proxy desktop replays. Installed routes and settled geometry match on every edge. The final scope passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/strip-hover-keys-2026-11-19.json).
<!-- /STRIP-HOVER-KEYS-R131-20261119 -->

<!-- BORDER-PARENT-GEOMETRY-R132-20261119 -->
Across six modeled strip crossings, three frame getter counts fell from 552 to 72. Across six modeled roster moves, they fell from 456 to 72. Both border types matched sampled seams and retained their solve counts. The final scope passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-parent-geometry-2026-11-19.json).
<!-- /BORDER-PARENT-GEOMETRY-R132-20261119 -->

<!-- BORDER-POSE-TOPOLOGY-R133-20261119 -->
Across six modeled held-action crossings, median prepared-layout field checks fall from 4,816 to 3,016. Across six modeled roster position changes they fall from 7,553 to 2,693. Both border styles keep the same prepared hits and match sampled seams. The final scope passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-pose-topology-2026-11-19.json).
<!-- /BORDER-POSE-TOPOLOGY-R133-20261119 -->

<!-- BORDER-FALLBACK-CONTEXT-R134-20261119 -->
Four modeled held-action crossings reduce fallback cache keys from 80 to 30 per border type. Four modeled party geometry appearances and removals reduce bounds union visits from 160 to 48. The represented joins and contributing fallback contexts match. The final scope passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-fallback-context-2026-11-19.json).
<!-- /BORDER-FALLBACK-CONTEXT-R134-20261119 -->

<!-- BORDER-ADMISSION-R135-20261119 -->
Four modeled transitions in the strip, party and raid-linked replays each cut regional source checks from 3,296 to 1,648. Frame visits fall from 392 to 196, while both styles retain matching sampled edges and rebuild counts. The final scope passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-admission-2026-11-19.json).
<!-- /BORDER-ADMISSION-R135-20261119 -->

<!-- BORDER-LAYER-PLAN-R136-20261119 -->
Four modeled held-action crossings cut raised-strip level reads from 26 to eight and temporary layer records from 310 to 52. Four modeled party or raid-linked geometry transitions cut layer records from 276 to 44. Both styles preserve canvas layers and sampled seams. The final scope passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-layer-plan-2026-11-19.json).
<!-- /BORDER-LAYER-PLAN-R136-20261119 -->

<!-- BORDER-SNAPSHOT-COPY-R137-20261119 -->
Four modeled held-action crossings eliminate 552 duplicate source rectangles and reduce copy lookup tables from 106 to six. Four modeled party or raid-linked geometry transitions eliminate 192 duplicate rectangles and reduce those tables from 36 to three. The visible samples and matching rebuild counts agree in both styles. The final scope passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-snapshot-copy-2026-11-19.json).
<!-- /BORDER-SNAPSHOT-COPY-R137-20261119 -->

<!-- BORDER-POSE-REGISTRATION-R138-20261119 -->
Unrelated border registration and removal preserve the prepared action-strip, party and raid-linked layouts. Four subsequent transitions per modeled replay go from four solves and plans to zero in both border types. Matching modeled output passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-pose-registration-2026-11-19.json).
<!-- /BORDER-POSE-REGISTRATION-R138-20261119 -->

<!-- BORDER-EMPTY-FRAGMENTS-R139-20261119 -->
Four warm held-action crossings remove 236 to 240 empty normal-canvas preparations and 474 empty fallback visits in both border styles. Four modeled party or raid-linked outline appearances and removals skip 148 empty fallback visits. All sampled fields match. Matching modeled output passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/border-empty-fragments-2026-11-19.json).
<!-- /BORDER-EMPTY-FRAGMENTS-R139-20261119 -->

<!-- RAID-ROSTER-SAMPLE-R140-20261119 -->
One legacy raid roster sample supplies group occupancy and tank or assist placement. The 40-member desktop replay drops from 194 roster-row reads to 40 with the column enabled and from 114 to 40 with it disabled. The matching player-slot reads fall from 117 or 77 to one. Layout and secure-mode regressions pass. The final scope passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/raid-roster-sample-2026-11-19.json).
<!-- /RAID-ROSTER-SAMPLE-R140-20261119 -->

<!-- RAID-GRID-RECTANGLE-R141-20261119 -->
Compact raid border refreshes confirm retained bounds with a single rectangle read. Eight five-cell leave and return transitions reduce geometry getter calls from 1,200 to 360 in both modeled row-overlap arrangements. Each newly visible or changed cell still uses exact native edge getters. The final scope passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/raid-grid-rectangle-2026-11-19.json).
<!-- /RAID-GRID-RECTANGLE-R141-20261119 -->

<!-- RAID-RANGE-BURST-R142-20261119 -->
Compact-cell lifecycle callbacks share one range discovery per queued border update. A modeled 40-cell join and leave reduce pool searches from 160 to two with native range events and from 120 to two with fallback range. When only the range event fails, required event registrations fall from 1,840 to 920. The final scope passed 103 desktop replays and 1250 Lua syntax checks.
[Matched validation](validation/raid-range-burst-2026-11-19.json).
<!-- /RAID-RANGE-BURST-R142-20261119 -->

<!-- RAID-JOIN-INDEX-R143-20261119 -->
Aligned compact groups locate joined edges by exact row and column coordinates. The first 40-cell border pass avoids 660 tolerance calculations and two sorts. Eight aligned five-cell departures and returns avoid 4,740 tolerance calculations and 16 sorts in both overlap models. Matching desktop evidence includes 600 varied layouts and 103 focused replays. 1250 Lua syntax checks pass.
[Matched validation](validation/raid-join-index-2026-11-19.json).
<!-- /RAID-JOIN-INDEX-R143-20261119 -->

<!-- BORDER-ANCHOR-BURSTS-R144-20261119 -->
The border builder reads watched anchors once from the settled layout and preserves unchanged reverse dependencies during strip and roster reflow. A four-panel, twelve-transition matched replay reduced point-count queries from 144 to 48 and per-point queries from 144 to 96 in both styles. The committed mesh and number of geometry passes match. Desktop verification passed 103 focused replays and 1250 syntax checks.
[Matched validation](validation/border-anchor-bursts-2026-11-19.json).
<!-- /BORDER-ANCHOR-BURSTS-R144-20261119 -->

<!-- STRIP-HOVER-ROUTES-R145-20261119 -->
Held spell, item and macro crossings refresh page and live occupancy while retaining valid click routes. Six transitions on page one reduced button attribute setters from 20,151 to 9,192. Page two reduced them from 20,142 to 9,189. Desktop verification passed 103 focused replays and 1250 syntax checks.
[Matched validation](validation/strip-hover-routes-2026-11-19.json).
<!-- /STRIP-HOVER-ROUTES-R145-20261119 -->

<!-- STRIP-MODIFIER-ROUTES-R146-20261119 -->
Keep each confirmed modifier route during a pure held-action crossing. Six crossings avoid another 1,740 button attribute setters on each tested page. Current type, action, macro text and alternate modifier aliases agree with the full-refresh oracle. Desktop verification passed 103 focused replays and 1250 syntax checks.
[Matched validation](validation/strip-modifier-routes-2026-11-19.json).
<!-- /STRIP-MODIFIER-ROUTES-R146-20261119 -->

<!-- PARTY-INDICATOR-PASS-R147-20261119 -->
One shared text refresh and one final indicator layout now cover an ordinary party roster paint. Four settled batches reduce text passes from eight to four and indicator layouts from twelve to four. The three tracked role icons stop making 96 redundant geometry writes in the same replay. Desktop verification passed 103 focused replays and 1250 syntax checks.
[Matched validation](validation/party-indicator-pass-2026-11-19.json).
<!-- /PARTY-INDICATOR-PASS-R147-20261119 -->

<!-- RAID-EXTRA-DRIVER-RETRY-R148-20261119 -->
Roster recovery keeps prepared optional pet and target frames when one paging driver fails. A single rejected route goes from 46 driver attempts and 278 protected writes to one attempt and eight writes in the desktop replay. A repeat notification while the same provider is unavailable performs zero extra protected writes. Desktop verification passed 103 focused replays and 1250 syntax checks.
[Matched validation](validation/raid-extra-driver-retry-2026-11-19.json).
<!-- /RAID-EXTRA-DRIVER-RETRY-R148-20261119 -->

<!-- BORDER-ROLE-ANCESTRY-R149-20261119 -->
The regional border builder shares public parent-chain role reads within one geometry pass. Six modeled held-action changes reduce classification parent reads from 1,194 to 312. Six roster-related moves reduce them from 1,218 to 312. Sampled seams and retained regions match in both border types. Desktop verification passed 103 focused replays and 1250 syntax checks.
[Matched validation](validation/border-role-ancestry-2026-11-19.json).
<!-- /BORDER-ROLE-ANCESTRY-R149-20261119 -->

<!-- STRIP-FLYOUT-ARROW-R150-20261119 -->
Flyout arrows retain confirmed native size and anchor points when extra-button hosts move during action-strip changes. Twelve modeled crossings reduce arrow geometry setters from 36 to zero per visible arrow. A changed squeeze, direction, anchor owner or unreadable geometry still takes the existing synchronous repair. Desktop verification passed 104 focused replays and 1250 syntax checks.
[Matched validation](validation/strip-flyout-arrow-2026-11-19.json).
<!-- /STRIP-FLYOUT-ARROW-R150-20261119 -->

<!-- STRIP-HOVER-OCCUPANCY-R151-20261119 -->
The held-action hover pass reads live minirow occupancy during its existing secure update. Six modeled crossings remove 36 reset broadcasts and 1,710 button attribute writes on each tested page. Early native slot changes, the no-probe fallback, and real drops match the full-refresh oracle. Desktop verification passed 105 focused replays and 1250 syntax checks.
[Matched validation](validation/strip-hover-occupancy-2026-11-19.json).
<!-- /STRIP-HOVER-OCCUPANCY-R151-20261119 -->

<!-- STRIP-PLAN-COVERAGE-R152-20261119 -->
A saved action-strip border plan can now cover a smaller set of changed tiles at the same destination geometry. Nine matched width changes reduce border planning from nine passes to six in each style. Nearby seams, active operation owners and retained tile listeners match the uncached replay. Desktop verification passed 105 focused replays and 1250 syntax checks.
[Matched validation](validation/strip-plan-coverage-2026-11-19.json).
<!-- /STRIP-PLAN-COVERAGE-R152-20261119 -->

<!-- RAID-CHROME-LOOKUP-R153-20261120 -->
Native selection suppression now checks grouped raid frame names before walking the active party pool. Two modeled passes over forty raid cells avoid eighty pool enumerations and four hundred entry visits. Anonymous frames retain pool recognition, including when the name is private or inaccessible. Desktop verification passed 106 focused replays and 1250 syntax checks.
[Matched validation](validation/raid-chrome-lookup-2026-11-20.json).
<!-- /RAID-CHROME-LOOKUP-R153-20261120 -->

<!-- RAID-STABLE-PAINT-R154-20261120 -->
Full compact raid roster paint retains native ranges and visibility when the widgets report the expected values. A forty-cell pass avoids 320 visibility setters and 80 health or power range setters. A five-cell pass avoids 40 visibility setters and 10 range setters. Current or unreadable changes retain the protected writer path. Desktop verification passed 106 focused replays and 1250 syntax checks.
[Matched validation](validation/raid-stable-paint-2026-11-20.json).
<!-- /RAID-STABLE-PAINT-R154-20261120 -->

<!-- BORDER-LISTENER-INDEX-R155-20261120 -->
The regional border commit reuses color, sprite and visibility index tables across a tile redraw. Eight held-action crossings avoid 344 replacements in border type one and 384 in type two. Forty warmed crossings reduce median temporary Lua heap growth by 158 and 187 KiB. Sampled joins and live updates match the archived renderer. Desktop verification passed 107 focused replays and 1250 syntax checks.
[Matched validation](validation/border-listener-index-2026-11-20.json).
<!-- /BORDER-LISTENER-INDEX-R155-20261120 -->

<!-- BORDER-FRAGMENT-MEMBERSHIP-R156-20261120 -->
The regional border commit keeps live fragments in their source paint pools during a redraw. Eight held-action crossings reduce pool insertions and removals from 1,789 to three for border type one and from 1,821 to three for type two. Sampled joins and live layer, tint and visibility match the prior renderer. Desktop verification passed 107 focused replays and 1250 syntax checks.
[Matched validation](validation/border-fragment-membership-2026-11-20.json).
<!-- /BORDER-FRAGMENT-MEMBERSHIP-R156-20261120 -->

<!-- PET-STRIP-PACKING-R157-20261120 -->
Action-strip crossings preserve settled pet slots when live geometry, content ownership and sizing inputs match. Eight matched crossings each remove 168 size writes, 160 point writes, 160 parent writes and 80 chrome rebuilds in both modeled client shapes. The pet root update and final border transaction keep their order. Desktop verification passed 28 focused replays and 1251 syntax checks.
[Matched validation](validation/pet-strip-packing-2026-11-20.json).
<!-- /PET-STRIP-PACKING-R157-20261120 -->

<!-- STANCE-STRIP-LAYOUT-R158-20261120 -->
The action-strip transaction samples stance after pet placement and keeps settled stance geometry on a crossing. Eight modeled crossings keep eight shared border commits and remove eight extra commits, eight stance catalog checks, 24 button paints and eight binding passes. Player-docked and pet-docked stance geometry match. Changed inputs still use the normal repair path. Desktop verification passed 28 focused replays and 1251 syntax checks.
[Matched validation](validation/stance-strip-layout-2026-11-20.json).
<!-- /STANCE-STRIP-LAYOUT-R158-20261120 -->

<!-- NATIVE-GROUP-HIDE-R159-20261120 -->
Twenty-four modeled native group-suppression sweeps remove 72 redundant alpha writes and reduce median heap growth from 562 to 200 KiB. The same 4,872 native child reads catch new and reparented controls. The longer 240-sweep process clock samples range around medians of 54 and 50 ms. Native group hitch timing is pending. Desktop verification passed 31 focused replays and 1252 syntax checks.
[Matched validation](validation/native-group-hide-2026-11-20.json).
<!-- /NATIVE-GROUP-HIDE-R159-20261120 -->

<!-- RAID-ACTIVE-HEADERS-R160-20261120 -->
Prepared roster reconciliation skips headers confirmed hidden by the native visibility getter. Eight modeled unscoped raid passes with a hidden tank/assist header reduce child attribute reads from 1,024 to 384 and attachment calls from 320 to zero. Visible paint and border dispatch match. Explicit recovery, private visibility and actual header reveals still use their current event owners. Desktop verification passed 35 focused replays and 1252 syntax checks.
[Matched validation](validation/raid-active-headers-2026-11-20.json).
<!-- /RAID-ACTIVE-HEADERS-R160-20261120 -->

<!-- STRIP-BADGE-PLACEMENT-R161-20261120 -->
Held-action strip crossings now retain matching corner-badge placement and layer levels. Eight matched crossings with 135 prepared badge faces remove 14,040 placement and layer writes in the desktop model. Changed size, clipping, anchoring and layers still take the existing repair path. Desktop verification passed 17 focused replays and 1252 syntax checks.
[Matched validation](validation/strip-badge-placement-2026-11-20.json).
<!-- /STRIP-BADGE-PLACEMENT-R161-20261120 -->

<!-- BORDER-RECENT-LAYOUTS-R162-20261120 -->
The border builder keeps up to four small exact layouts per strip hover state and three roster layouts within the previous combined geometry and clipped-field bounds. Twelve modeled width transitions now compile four times instead of twelve. Nine modeled roster layout transitions compile three times instead of nine. Both styles match sampled joins. New geometry still compiles locally, and cached output checks current materials and paint. Desktop verification passed 34 focused replays and 1252 syntax checks.
[Matched validation](validation/border-recent-layouts-2026-11-20.json).
<!-- /BORDER-RECENT-LAYOUTS-R162-20261120 -->

<!-- BORDER-SIMPLE-INTERVALS-R163-20261120 -->
Cold border builds skip boundary allocation and sorting for unpartitioned parallel overlaps. Two modeled strip changes per style remove 19 walks and sorts and 608 keeper corner candidate visits. Two modeled roster changes remove eight walks and sorts. All sampled joins and the chained ownership oracle match. Desktop verification passed 40 focused replays and 1252 syntax checks.
[Matched validation](validation/border-simple-intervals-2026-11-20.json).
<!-- /BORDER-SIMPLE-INTERVALS-R163-20261120 -->

<!-- BORDER-FALLBACK-CLIP-R164-20261120 -->
Cold regional reflows reject strictly disjoint compiled triangles before the per-triangle guard or cache record. Median guard counts across two strip changes fall from 226 to 127 and 201 to 117 in border order. Across two roster changes, they fall from 704 to 540 and 784 to 512. Sampled joins and revealed backups match. Desktop verification passed 40 focused replays and 1252 syntax checks.
[Matched validation](validation/border-fallback-clip-2026-11-20.json).
<!-- /BORDER-FALLBACK-CLIP-R164-20261120 -->

<!-- STRIP-SHELL-ANCHORS-R165-20261120 -->
The action strip retains matching screen and sensing anchors across resizes. For six held-action crossings, desktop replays eliminate 24 exterior anchor writes and six redundant scale writes. Six slot edits also eliminate 12 inner anchor writes. Final positions, action routes and one border commit per resize match the previous source. The 27 focused scripts and 1252 Lua syntax checks passed.
[Matched validation](validation/strip-shell-anchors-2026-11-20.json).
<!-- /STRIP-SHELL-ANCHORS-R165-20261120 -->

<!-- BORDER-TILE-FIELDS-R166-20261120 -->
The border renderer writes fully contained tile triangles and rectangular quads directly. In two cold action-strip reflows, temporary polygon builds fall from 429 to 216 and from 496 to 216 in border style order. Clipped vertices, artwork coordinates and sampled seams match the archived source. Desktop end-to-end elapsed samples are mixed. The 39 focused scripts and 1252 exact-hash Lua syntax checks passed. The separate Bars smoke script failed two reticle source-order checks against the current Overlay source.
[Matched validation](validation/border-tile-fields-2026-11-20.json).
<!-- /BORDER-TILE-FIELDS-R166-20261120 -->

<!-- RAID-AURA-RETIREMENT-R167-20261120 -->
Prepared group cells remember unit bindings through cleanup. In the forty-cell replay, two cleanup calls per frame issue 120 native SetUnit calls and 120 native Hide calls, down from 400 of each. In the five-cell replay each count falls from 50 to 15. The second cleanup performs zero native owner writes. Active subscriptions match on join and rejoin. All 30 focused scripts and 1252 exact-hash Lua syntax checks passed.
[Matched validation](validation/raid-aura-owner-retirement-2026-11-20.json).
<!-- /RAID-AURA-RETIREMENT-R167-20261120 -->

<!-- STRIP-GRID-ROOT-ANCHORS-R168-20261120 -->
Combat and noncombat grid roots keep verified relative anchors when the action strip resizes. Across ten modeled crossings, 50 root anchor writes and ten unused floor queries fall to zero. Each crossing still settles the envelope once. Both client models keep the same relative anchors and offsets. All 27 focused scripts and 1252 exact-hash Lua syntax checks passed.
[Matched validation](validation/strip-grid-root-anchors-2026-11-20.json).
<!-- /STRIP-GRID-ROOT-ANCHORS-R168-20261120 -->

<!-- RAID-UNIT-EVENT-RETIREMENT-R169-20261120 -->
Compact group frames keep completed event clears through duplicate unbind and hide callbacks. In matched leave and rejoin replays, native event reset calls fall from 15 to five for a five-person party and from 120 to 40 for a forty-person raid. Active event subscriptions and registration counts match. All 30 focused scripts and 1252 exact-hash Lua syntax checks passed.
[Matched validation](validation/raid-unit-event-retirement-2026-11-20.json).
<!-- /RAID-UNIT-EVENT-RETIREMENT-R169-20261120 -->

<!-- BORDER-NEIGHBOR-RUNS-R170-20261120 -->
The regional border planner checks neighbor membership once per consecutive group and reuses the group during geometry copying. Two cold strip or roster changes reduce membership checks from 392 to 98 across both styles. Isolated copy and selection medians fall from 45 to 38 ms and from 44 to 37 ms per 1000 passes in border style order. Full desktop reflow timings are mixed. Source ordering and sampled seams match. All 43 focused scripts and 1252 current Lua syntax checks passed.
[Matched validation](validation/border-neighbor-runs-2026-11-20.json).
<!-- /BORDER-NEIGHBOR-RUNS-R170-20261120 -->

<!-- STRIP-EMPTY-PROMOTION-R171-20261120 -->
The action strip checks alternate main pages during promotion only when a secondary or tertiary button has an action. Eight paired cursor crossings remove 72 action reads from mapping and 52 from placement in each tested layout. Click routes, placement and the border transaction match the archived Lua. All 43 focused scripts and 1252 current Lua syntax checks passed.
[Matched validation](validation/strip-empty-promotion-2026-11-20.json).
<!-- /STRIP-EMPTY-PROMOTION-R171-20261120 -->

<!-- FLYOUT-ARROW-LAYERS-R172-20261120 -->
The shared flyout refresh keeps an arrow’s confirmed parent, frame strata, level and scale during strip movement. Twelve matched moves cut layer and scale writes from 48 to zero per arrow. Replacement owners, layer drift and denied getters still use native repair. The shared border and visibility-parent paths agree with the archived source. All 32 focused scripts and 1252 current Lua syntax checks passed.
[Matched validation](validation/flyout-arrow-layers-2026-11-20.json).
<!-- /FLYOUT-ARROW-LAYERS-R172-20261120 -->

<!-- BORDER-FALLBACK-PARTITION-R173-20261120 -->
The border planner writes each split fallback fragment directly into its final list. Across two matched changes per style, strip resizing removes 38 temporary tables, roster movement removes 64, and a dense overlap replay removes 172. Draw counts, sampled joins and borders revealed when a keeper hides match the original. All 44 focused scripts and 1252 current Lua syntax checks passed.
[Matched validation](validation/border-fallback-partition-2026-11-20.json).
<!-- /BORDER-FALLBACK-PARTITION-R173-20261120 -->

<!-- BORDER-LISTENER-RUNS-R174-20261120 -->
The regional border commit shares watcher entries for consecutive fallback fields with the same source and blockers. Twelve warmed strip crossings reduce observer visits from medians of 1,464 to 1,056 and from 1,272 to 1,044 in border style order. Twelve roster reflows reduce them from 6,624 to 6,060 and from 15,648 to 14,040. The same fields paint in their original order, including when a keeper hides and returns. All 47 focused scripts and 1252 current Lua syntax checks passed.
[Matched validation](validation/border-fallback-listeners-2026-11-20.json).
<!-- /BORDER-LISTENER-RUNS-R174-20261120 -->

<!-- BORDER-LISTENER-LINKS-R175-20261120 -->
The renderer reuses one visibility-link table per changed tile. Observer lists keep the head of each consecutive fallback run, and its existing visibility check supplies the whole run. Twelve warmed strip crossings save a median 13.5 to 16.0 KiB of temporary Lua allocation. The roster fixture saves 30.5 to 152.5 KiB. Observer visits also fall, with equal logical memberships and paint order. Whole-reflow timing is mixed. All 47 focused scripts and 1252 current Lua syntax checks passed.
[Matched validation](validation/border-listener-links-2026-11-20.json).
<!-- /BORDER-LISTENER-LINKS-R175-20261120 -->

<!-- BORDER-FIELD-ANCHORS-R176-20261120 -->
Moving border fields update a verified existing anchor in place. Across twelve warmed strip crossings the median point clears fall from 1,764 and 1,932 to 12 in each style. The roster replay falls from 4,164 and 6,720 to zero. Point writes, sampled joins and widget counts match. Temporary heap use falls with mixed full-update timing. All 47 focused scripts and 1252 current Lua syntax checks passed.
[Matched validation](validation/border-field-anchors-2026-11-20.json).
<!-- /BORDER-FIELD-ANCHORS-R176-20261120 -->

<!-- BORDER-FIELD-PAINT-R177-20261120 -->
Border paint caches texture and layer values directly and compares public RGBA through its fixed setter. Twelve warmed strip crossings take 53 to 53 ms and 97 to 96 ms at the desktop median in style order. Temporary Lua allocation falls by 32.4 and 33.6 KiB. Attempted setter counts and sampled seams agree. All 47 focused scripts and 1252 current Lua syntax checks passed.
[Matched validation](validation/border-field-paint-2026-11-20.json).
<!-- /BORDER-FIELD-PAINT-R177-20261120 -->

<!-- PARTY-ROSTER-DISPATCH-20261120 -->
The existing raid event handler queues one settled paint for normal party members, pets, and targets. In a twenty-event desktop burst with eight active member/pet slots, dispatch calls fall from 180 to 20 and synchronous visibility reads from 160 to zero. The same eight paints, cast refreshes and range wake occur in one deferred callback. All 28 focused scripts and 1252 current Lua syntax checks passed. The rectangular clip and canvas reuse prototypes stayed external.
[Matched validation](validation/party-roster-dispatch-2026-11-20.json).
<!-- /PARTY-ROSTER-DISPATCH-20261120 -->

<!-- BORDER-ROSTER-BOUNDS-R178-20261120 -->
Prepared roster reflows share a bounding box among eligible textures in the same junction. Twelve warmed reflows cut modeled box calls from 5,664 to 4,236 and from 9,864 to 7,368 in border-style order. The first two compiles keep the original setter counts. First prepared restores and one unseen layout after warming also use fewer box calls. Strip crossings match the original setter counts. Desktop elapsed comparisons were mixed. All 51 focused scripts and 1252 current Lua syntax checks passed.
[Matched validation](validation/border-roster-bounds-2026-11-20.json).
<!-- /BORDER-ROSTER-BOUNDS-R178-20261120 -->

<!-- BORDER-SOURCE-ALPHA-R179-20261120 -->
Regional paint reuses the observation of zero source opacity through publication. Sixty warmed strip crossings save 3,540 modeled opacity reads per style. Sixty warmed roster reflows save 2,700 reads per style. Alpha and mesh writes, sampled seams and texture counts match. The measured desktop elapsed times were mixed. All 51 focused scripts and 1252 current Lua syntax checks passed. Both hook-omission controls fail at the reentrant publication assertion.
[Matched validation](validation/border-source-alpha-2026-11-20.json).
<!-- /BORDER-SOURCE-ALPHA-R179-20261120 -->

<!-- STRIP-EXPANDED-COLUMNS-20261120 -->
The expanded strip uses its full column count and checks current-page main and mini occupancy for drop placement. Sixty modeled cursor crossings per fixture remove 1,770 to 1,800 collapsed packing checks during expansion. Action reads, action routes, point and visibility writes, and border commits match the archived Lua. All 51 focused scripts and 1252 current Lua syntax checks passed.
[Matched validation](validation/strip-expanded-columns-2026-11-20.json).
<!-- /STRIP-EXPANDED-COLUMNS-20261120 -->

<!-- BORDER-OBSERVED-SOURCES-R180-20261120 -->
A regional read reuses public preflight snapshots for watched source textures. Sixty warmed strip crossings per style remove 5,760 modeled getter calls and about 1.22 MiB of temporary allocation. Sixty roster moves per style remove 7,920 calls. Actual source geometry and paint still use live inputs. Matched setter counts, sampled joins and texture counts agree. Desktop elapsed timing was mixed. All 55 focused scripts and 1252 exact-source syntax checks passed. The old implementation and both omitted-guard controls fail the intended regression assertions.
[Matched validation](validation/border-observed-sources-2026-11-20.json).
<!-- /BORDER-OBSERVED-SOURCES-R180-20261120 -->

<!-- BORDER-PANEL-ALIGNMENT-POSES-R181-20261120 -->
Panel alignment retains offsets for its two most recent successful layouts. For both border types and both tested scales, 60 warmed crossings eliminate 60 alignment graph builds. The same 60 anchor updates and sampled junctions remain. Median alignment-phase time falls by 45 to 48 percent across the paired desktop runs. Full transaction timings were mixed. All 55 focused scripts and 1252 exact-source syntax checks passed. The archived source fails the warmed alignment reuse assertion.
[Matched validation](validation/border-panel-alignment-poses-2026-11-20.json).
<!-- /BORDER-PANEL-ALIGNMENT-POSES-R181-20261120 -->

<!-- GROUP-NAMEPLATE-ANCHORS-20261120 -->
Roster refreshes retain verified quest badge anchors on visible nameplates. In 60 modeled roster bursts with 32 active plates, anchor writes fall from 7,680 to zero in each of five client models. Objective refresh counts and follow-up polls match. The desktop Lua median is 10 ms before and 11 ms after across all 60 bursts per model. Native write and frame-time costs remain unmeasured. All 64 focused scripts and 1252 exact-source syntax checks passed. The archived source fails the settled anchor regression.
[Matched validation](validation/group-nameplate-anchors-2026-11-20.json).
<!-- /GROUP-NAMEPLATE-ANCHORS-20261120 -->

<!-- GROUP-NAMEPLATE-LEVELS-20261120 -->
Nameplate overlays keep a verified frame level while attached to the same plate. Across 60 modeled roster bursts with 32 plates, frame-level writes fall from 7,680 to zero in each of five client models. Two seconds of steady 20-plate polling reduce writes from 184 to 5 in Retail and 364 to 6 in Forever. Fresh attachment and repair preserve their existing writes. Modeled elapsed timings were mixed. All 64 focused scripts and 1252 exact-source syntax checks passed. The archived source fails the settled frame-level regression.
[Matched validation](validation/group-nameplate-levels-2026-11-20.json).
<!-- /GROUP-NAMEPLATE-LEVELS-20261120 -->

<!-- STRIP-INFO-ANCHORS-20261120 -->
Held-action strip crossings now keep verified native anchors on the Info slot and its gap fill. Over 60 modeled crossings, point writes fall from 180 to zero when both poses are wide and from 90 to zero when one pose hides the slot. The envelope samples the shared left, top and bottom owner once instead of three times. All four Info placements preserve their settled shown states, points and sizes. All 29 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/strip-info-anchors-2026-11-20.json).
<!-- /STRIP-INFO-ANCHORS-20261120 -->

<!-- STRIP-SLOT-SETTLE-20261120 -->
Warmed action-slot edits use the strip settlement for face placement, chrome, nearby panels and unit roots even without a cursor edge. Sixty alternating column additions and removals reduce modeled strip point writes from 2,610 to 3 and ring sizing calls from 3,420 to 30 across three client fixtures. On both unit placements and three scales, ten edits replace twenty full unit refreshes with ten checks of the final root anchors. Every modeled junction commit still runs after the final panel and unit geometry. All 29 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/strip-slot-settle-2026-11-20.json).
<!-- /STRIP-SLOT-SETTLE-20261120 -->

<!-- BORDER-CURRENT-DRAW-INPUTS-R182-20261120 -->
The regional border draw reuses the current validated source paint and samples the parent once per junction-only source during the commit. Twelve warmed strip crossings remove 990 and 924 repeat paint validations in border style order. Twelve roster reflows remove 522 and 702. The same setters, sampled seams and texture counts remain. Desktop elapsed timings were mixed. All 35 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/border-current-draw-inputs-2026-11-20.json).
<!-- /BORDER-CURRENT-DRAW-INPUTS-R182-20261120 -->

<!-- ROSTER-AURA-PAINT-20261120 -->
Raid and party aura refreshes retain matching owned icon textures, stack text and visibility. Twenty modeled forty-cell reflows with one joining/leaving slot reduce visibility writes from 895 to 95 on the Retail and Forever native-container profiles and from 15,960 to 95 on the readable Classic profiles. Readable icon and stack writes each fall from 1,580 to zero there. Aura queries, native assignments and cooldown timing match. Desktop timing samples vary by profile. All 33 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/roster-aura-paint-2026-11-20.json).
<!-- /ROSTER-AURA-PAINT-20261120 -->

<!-- STRIP-EVENT-OWNERSHIP-R183-20261120 -->
Sixty matched slot changes, each with two native notifications, cut early envelope reads from 120 to zero. The same 60 final layout passes and border commits still run. Six warmed held-cursor replays across both styles and three UI scales use 8 to 16 fewer parent level reads per six crossings. Settled action routes, button geometry, raised layers and sampled border artwork match the archived sources. All 23 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/strip-event-ownership-2026-11-20.json).
<!-- /STRIP-EVENT-OWNERSHIP-R183-20261120 -->

<!-- STRIP-GRID-WIDTH-20261120 -->
Combat and Non-combat grids retain their verified column order when an action-strip crossing changes the horizontal squeeze. Across 60 modeled crossings, geometry setters fell from 6,844 to 4,484 and column sorts from 1,239 to zero in each client fixture. Both grid shapes, icon refreshes, clipping and Info/envelope notification order match. Five alternating desktop pairs per profile measured 20 to 12 ms median for 320 crossings of this layout path. All 21 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/strip-grid-width-2026-11-20.json).
<!-- /STRIP-GRID-WIDTH-20261120 -->

<!-- BORDER-FIELD-RETIREMENT-R184-20261120 -->
The regional border renderer hides outgoing fragments and junction textures through their current ownership records. Twelve modeled held-action crossings removed 1,446 and 1,818 visibility reads in border style order. Twelve roster-layout moves removed 876 and 1,914. Native setter counts, sampled joins, and texture counts match in the model. Desktop timings improved for the two held-action medians and were mixed across roster reflows. All 27 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/border-field-retirement-2026-11-20.json).
<!-- /BORDER-FIELD-RETIREMENT-R184-20261120 -->

<!-- PARTY-TARGET-TRAIL-20261120 -->
Party-target roster refreshes keep the existing damage trail when the same readable unit and health sample remain current. Sixty modeled roster batches that change one of four targets reduce trail resets from 240 to 60 and hide calls from 1,440 to 360. With all four targets unchanged those counts fall to zero. Main health and color paint remain current. Replacements use their existing fresh identity read after reset, including one extra GUID read when the replacement has the same health. Desktop elapsed gains are small and vary by scenario. All 28 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/party-target-trail-2026-11-20.json).
<!-- /PARTY-TARGET-TRAIL-20261120 -->

<!-- STRIP-PARKED-CHROME-20261120 -->
The strip retains verified button chrome when a face returns from off-screen parking. The first crossing refits 19 versus 5 faces in each desktop client model. Sixty warmed crossings refit 571 faces before and zero after. Button positions, action slots and visible art match. The held-cursor watcher also leaves the sensing frame alone once its live visibility matches. All 25 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/strip-parked-chrome-2026-11-20.json).
<!-- /STRIP-PARKED-CHROME-20261120 -->

<!-- BORDER-OBSERVER-SCRATCH-R185-20261120 -->
Regional preflight uses a flat dependency stack and one scratch link set per settled anchor batch. Twelve modeled strip crossings remove 768 temporary dependency entries and 432 temporary snapshot validation tables per style. Twelve modeled roster moves remove 1,056 entries and 576 validation tables. Each replay reduces scratch link sets from 48 to 12, with identical dependency visits and snapshot counts. Texture setters, sampled seams and operation counts match. All 23 focused scripts and 1252 exact-source Lua syntax checks passed.
[Matched validation](validation/border-observer-scratch-2026-11-20.json).
<!-- /BORDER-OBSERVER-SCRATCH-R185-20261120 -->

<!-- PARTY-STATUS-OWNER-20261120 -->
The normal party roster paint keeps its portrait indicator anchors through the shared update. Sixty paired roster batches reduce role position writes from 290 to 23 and level position writes from 360 to zero. Final visibility, positions and level label paint match. The master-loot check uses only the assigned party slot. Sixty party name fits with a public host width and a single level label remove 120 unused outer-width reads and 120 level text measurements. All 25 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/party-status-owner-2026-11-20.json).
<!-- /PARTY-STATUS-OWNER-20261120 -->

<!-- STRIP-GRID-RING-20261120 -->
Width changes in Combat and Non-Combat Grid now size each button ring once. Sixty modeled crossings cut ring fits from 1,920 to 960. Cosmetic setter calls fall from 102,720 to 62,400 in the Retail and Forever models and from 108,480 to 66,240 in the Classic model. Grid positions, ring art, checked and pressed textures, equipped glow and cooldown layout match. All 23 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/strip-grid-ring-2026-11-20.json).
<!-- /STRIP-GRID-RING-20261120 -->

<!-- STRIP-ARROW-OWNER-20261120 -->
The action-strip envelope now shares its completed flyout refresh with the Trinket Menu. Across 60 modeled crossings with 20 attached arrows, explicit shared scans fell from 180 to 120 and all visible arrow updates from 4,800 to 3,600. Trinket layer setters fell from 720 to zero with matching slot anchors, size, scale and atlas layering. All 25 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/strip-arrow-owner-2026-11-20.json).
<!-- /STRIP-ARROW-OWNER-20261120 -->

<!-- STRIP-INFO-MEASURE-20261120 -->
Info now reuses the width just measured when its hybrid labels match, and adjusts the current render list in place. In 60 modeled width changes, the usual FPS and ping row uses 120 width queries instead of 240. The dense row uses 2,010 instead of 2,220. The item-level and GearScore case keeps all 960 queries because the labels change. The decorative slot skips 120 grid-height reads over 60 crossings. Text, fonts, anchors, tooltip contents and slot visibility match. All 28 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/strip-info-measure-2026-11-20.json).
<!-- /STRIP-INFO-MEASURE-20261120 -->

<!-- BORDER-PANEL-INPUTS-R186-20261120 -->
R186 reuses the nearby-panel records that match either prepared layout. In both styles, 60 repeated scans of a stable seven-panel HUD and 60 alternating warmed strip widths cut 420 new panel records to zero. Sixty new widths create 300 records and retain the same 60 alignment graphs. The native-style rectangle reads, changed decorative boxes and final coordinates match. The phase fixture models panel geometry and does not measure the whole border rebuild. All 37 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/border-panel-inputs-2026-11-20.json).
<!-- /BORDER-PANEL-INPUTS-R186-20261120 -->

<!-- ROSTER-HOVER-DRIVER-20261120 -->
Stable mouse-only roster discovery now skips an action-bar binding scan. Thirty modeled bursts across each client profile go from 570 native binding reads to zero. Early registrations still sample each action binding once per scan, including keys after nil or empty results. Forty newly discovered raid cells cut binding reads from 1,179 to 600 in the Forever model and from 419 to 120 in the Era model. Mouse and wheel routes, discovery and protected write counts match. All 46 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/roster-hover-driver-2026-11-20.json).
<!-- /ROSTER-HOVER-DRIVER-20261120 -->

<!-- NAMEPLATE-RANK-ROSTER-20261120 -->
Nameplate threat refreshes now share successful public group identity reads for one pass. With 32 visible plates, a modeled party entry uses 10 GUID queries instead of 320. The raid case uses 82 instead of 2,624. A confirmed tanking player already has rank one, allowing the same raid replay to use 64 detailed threat queries instead of 2,592. Matched text, tint and plate lookups remain equal in all three client models. All 56 focused scripts and 1252 exact-source syntax checks passed.
[Matched validation](validation/nameplate-rank-roster-2026-11-20.json).
<!-- /NAMEPLATE-RANK-ROSTER-20261120 -->

<!-- BORDER-CELL-BUDGET-R187-20261120 -->
R187 reduces capacity checks from 7,560 region visits to 2,340 across 60 warmed action-strip crossings per border style. The modeled fields, sampled colors and opacity, and admitted draw records match. 70 focused scripts and 1252 exact-source syntax checks passed. Two source-extraction fixtures fail identically on R186.
[Matched validation](validation/border-cell-budget-2026-11-20.json).
<!-- /BORDER-CELL-BUDGET-R187-20261120 -->

<!-- HUD-ACCEPTANCE-R187-20261120 -->
R187 is the HUD acceptance candidate. The combined desktop pass covers action-strip crossings and rapid drops, party and raid conversion, local border publication, minimap side buttons and combat regressions. All 48 selected scripts and 1252 Lua syntax checks passed. The two recorded baseline-equivalent fixture failures remain in the prior R187 validation. Current native acceptance is pending. The installed border file matches in all five local client trees. Loaded client identity, frame times, pixels, input and taint require live evidence.
[Matched validation](validation/hud-acceptance-r187-2026-11-20.json).
<!-- /HUD-ACCEPTANCE-R187-20261120 -->




































































































<!-- LHO-PERSIST-REF-ELIGIBILITY-20261118 -->
18 November: applied private same-pass saved-reference eligibility reuse in Persist.lua7082172e and Scan.lua21883c7d;**native adoption/performance acceptance PENDING**. Current client still runs preceding source until the next guarded reload. Direct public reads retain live checks. Matching numeric ID/kind can reuse only this synchronous scan's already-checked allowed result;clock/frame/scan serial/classifier revision/bag generation/runtime publication and defining owner checks guard reuse. Changed public persist/score/item helpers,metatables,secret IDs,missing approvals,reentry or later frames take ordinary checks. Normalization/scrub/ratchet/cold retries/features/look/cadence retained. Professions loads later than Persist;its owner pins on first query.

Dated external source/history verified;12settings stat rows. Before/afterLua5.1/5.4syntax8checks PASS;original GetRef/MaybeUpdateRef cores restored exactly after removing only approval plumbing,remaining vendor bodies unchanged;30Retail/Forever sourcepairs match. Native99/100 baseline7passes/3s,4stored full4.618000/4.336800/5.275400/5.667300ms;notify0.036400/0.036700/0.055700/0.043300ms. Runtime retained/errors0,methods restored/rootsclean. No new simulation. Native92-98 prior evidence found17tooltipreads/13for7valid IDs;no proposed gain accepted yet.

Next: stop currentR19host33664 before guarded adoption reload,install freshjumpcue,then current counts/fullrecords and same scan-only timing protocol. Keep allclient/override/reentry/secret/taint/pixel/controller/fullworkflow/FPS acceptance OPEN;do not infer from source checks. Useraway:asknoquestions;pause promptly withCANCEL/nativeJUMP_STOP before requestedreload. FullLHO01-13ACTIVE. Preserve all unrelatedwork/no commits or external addon edits.
[Exact checkpoint and pending validation](validation/persist-ref-eligibility-2026-11-18.json).
<!-- /LHO-PERSIST-REF-ELIGIBILITY-20261118 -->


<!-- LHO-PASSIVE-TOOLTIP-ATTRIBUTION-20261118 -->
18 November native92-98: actual passive validation attribution,**no productLua edit/new simulation/reload**. Three-second trace7passes/4stored,all classifyPendingRead retain runtime. Full envelopes4.410900/4.180900/5.288500/4.404300ms;17tooltipreads each cost2.240000/2.080900/2.305200/2.164900ms. GetInfo82calls cost0.0580/0.0573/0.0603/0.0581ms;GetFirst17calls cost0.1352/0.1391/0.1407/0.1357ms. Nested inclusive costs overlap/include wrappers;not additive/FPS/hitch/beforeafter evidence. Rounded6decimal transcriptions;original PNGs retained.

One94pass has17reads/11IDs:1487x1,1645x2,2633x1,3703x1,3928x2,4599x3,4601x1,5634x1,6149x2,7516x1,8544x2. Pending2633/3703/5634/7516 eachreadonce;7valid IDs account13reads. Returned pending strings describe cure/alcohol/movement immunity/readable item. Do not force-reject or change0.4s cold retries on current strings alone.

Correction:94broad caller-tag search matched the classifier filename embedded in unnamed loadstring source;all classify labels INVALID,counts/pendingflags remainvalid.96rawstack overflowedchat;97filteredstack partlyclipped. Complete caller attribution remainsunproven;use explicit chunk names/anchored addon frames next.97PNG personally viewed butACK attempted too late and rejected asstale;not restamped/replayed or called ACKed.98fresh independentread/ACK confirms all owned92/94code/reports absent,jumpcueactive,cursorclear/errors0,food1487-14-841/preferences0-120-30 unchanged;freshbuild1.60.1/70959/16001/project18. All addon-method wrappers restored byidentity;no nativeAPI replacement/item actions/external-addon edits.29Retail/Forever sourcepairs freshlymatch.

CurrentR19_J90q/j18n90a7 host33664/supervisor14932 remains;180s queue forchat/casts/crafting/unsafeinput,15sPCidle exception,movementunverified. Pause promptly viaCANCEL/nativeJUMP_STOP before requestedguardedreload. Useraway:asknoquestions. Next: shared per-pass eligibility for repeated valid-item reads with defining-method/override/reentry guards;no candidate yet implemented/measured. Keepfreshness/features/cadence and coldretry contracts. FullLHO01-13ACTIVE;~5ms path and broader workflow/provider-off/client/taint/pixel/controller/matchedFPS-spikes remainOPEN. Accepted Score13f/Scan94c/parser689/recipe9a and priorwork intact;no unattended merchant automation.
[Exact attribution and limits](validation/passive-tooltip-attribution-2026-11-18.json).
<!-- /LHO-PASSIVE-TOOLTIP-ATTRIBUTION-20261118 -->


<!-- LHO-SCORE-REQUIREMENT-PREFILTER-REJECTED-20261118 -->
18 November: rejected the requirement-parser literal guard after checking the actual active workload. The two-line candidate in Inventory/FluxConsumableBest/Score.lua13f28db1 ->86b4fe20 skipped patterns when lowercase text lacked "requir". Native81/82 used54real carried-item tooltips,34without the fragment:three alternating270-call pairs old0.780300/0.739700/0.725000ms,new0.576400/0.561700/0.531800ms,all54results equal. Acquisition/native restriction reads were outside these parser timings. This mixed inventory includes materials/gear and does not establish the consumable hotspot's benefit.

Native88 narrowed the same private comparison to7actual published consumables,allwith requirement text:three alternating140-call pairs old0.511600/0.497400/0.512500ms,new0.535200/0.525100/0.518200ms. Allresults match,but every candidate pair is slower. Removed ONLY the two inserted lines;whole file restored exactly13f28db1,all earlier accepted Score/parser/Scan/queue/recipe/vendor/EBS work retained. No new simulation. Fresh before/after/restoredLua5.1/5.4syntax and29Retail/Forever sourcepairs pass;dated source/history and12settings-stat records retained externally. Initial immediate diskpair check failed after write;later allmatch,no manualsync;visibility cause unproven.

Own83reload adopted the trial;native85 retained54counts/food1487-14-841,providers/errors/preferences. Native86/87 full IsKnownUnusable comparison on54actual items also matched,0failures/0errors,both variants blocked0 (no real rejection branch induced). After rejection,own89guardedreload readiness ACKed and fresh startup separately viewed;native91 freshly1.60.1/70959/16001/project18,bothSyndicator+Baganatorloaded/source syndicator/readytrue,54counts0mismatches,samefood/queue4/errors0/preferences0-120-30,cursorclear. Owned probes/reports removed;no installed/native API replacements,craft/mail/item transactions or external addon edits. Unrelated party/loot-setting traffic is a retained confound,not this goal's commands. No causal full-validation/FPS/hitch claim.

Current jump R19 _J90q/j18n90a7,supervisor14932/host33664/live20261118s verifiedlive. R17host42332 andR18host42984 stopped/verified absent before respective reloads;only matching ownedstop/setupholdsremoved,INPUT_HALTED retained. Keep180s queued forchat/casts/crafting/unsafeinput;15sPCidle activation/priorapp restoration exception;Space injection is not visual movement proof. Pause promptly with CANCEL/nativeJUMP_STOP before requested guardedreload;freshnonce afterresume. Useraway:asknoquestions. All trial inputs spent;do not replay.

FullLHO01-13ACTIVE. Prior recipe9a12130d still accepted:148cached fullrecords/reagents match native79/80;local warm-query saving only. Next: real tooltip-acquisition/repeated eligibility work for the active consumable set,then established-evidence Inventory/EBS fixes. Do not reapply this guard,the rejectedR29catalogue/taskcopy caches or unmeasuredlegacy-index hint. Broader vendor/AH/bank/mail/pending/craft/cast/provider-off mutation,otherclients/taint/pixels/controller and matchedFPS/spikes remainOPEN. Vendor unattended opening remains unsafe without native Shift skip.
[Exact rejection and restoration evidence](validation/score-requirement-prefilter-2026-11-18.json).
<!-- /LHO-SCORE-REQUIREMENT-PREFILTER-REJECTED-20261118 -->


<!-- LHO-PROFESSION-LIVE-SCHEMATIC-20261118 -->
18 November: actual **Inventory/Professions.lua39c656ae -> 9a12130d** removes a duplicate native schematic read from GetRecipeLive. A successful quantity helper now returns its fresh schematic as a third private result;the same call passes it to the existing reagent extractor. Three substitutions only;no persistent cache/event/timer/cadence/public-result changes. Other callers consume their original two results;nil/error/non-table quantity lookups still leave the ordinary reagent retry/fallback. Whole-file three-substitution restoration and measured-worker equivalence PASS;before/afterLua5.1/5.4parse PASS. Dated external source/history verified,12settings stat rows;29Retail/Forever diskpairs match,no manualsync or new simulation. Preserve existing17November profession edits;8095e63c followup execution unchanged.

Native73 finds148cached recipes and modern APIs while professioninfo is absent;actual learned IDs1263032SpinningWheel/1263425FactionBanner/18560Mooncloth returnlive quantity1 and3/2/1reagentrows. Before edit,74 compares unmodified public query vs private candidate:threealternatingpairs,9queries pervariant perpair,old0.258700/0.263900/0.271200ms,new0.202700/0.211700/0.214800ms. All returned fields/nested reagent rows match3of3perpair;installed method unchanged. After own75reload,78 compares exact preceding private helpers with current installed query:old0.242800/0.263000/0.260800ms,new0.190100/0.186700/0.203000ms;again3of3fullrecordmatches eachpair/installedidentityretained,errors0,ownedrootsremoved. Local warm-query saving only;public/private placement,cache/world/system/GC/unrelated party activity are confounds. No overall FPS/hitch/Pendingbutton/end-to-end crafting claim;no party actions were this goal's commands.

Own75guardedreload readiness ACKed/freshstartup separately viewed. Native77 freshly1.60.1/70959/16001/project18,bothaddonsloaded/source syndicator/readytrue,54counts0mismatches,food1487/14/841 unchanged,queue4,errors0,preferences0/120/30,cursorclear. No craft/consume/buy/sell/delete/mail/window-opening or nativeAPI overrides. Packaged pinned schema says Retail/Forever GetRecipeSchematic returns CraftingRecipeSchematic;Forever snapshot70862 differs from actual70959. Classic declaration miss is unknown,not removal. Node18 narrow-query launch hit EPERM/insufficientversion;read only matching packaged JSON instead. Otherclients,quality/foreign/partial/cold/skill-change paths,largecatalogue/currentrecipe-change/actual craft lifecycle,taint/pixels/controller and matchedFPS/spikes remainOPEN. FullLHO01-13ACTIVE;~5ms consumable validation and broader vendor/AH/bank/mail/pending/craft/cast/provider-off mutation work remains.

Fresh R17 _J76q/j18n76a7 installed/ACKed;supervisor46232 launchedhost42332/live20261118q,host liveverified,3Spacepairs at recordtime,motionunverified. R16host37972 stopped/verified absent before reload;only ownedstop/setupholdsremoved,INPUT_HALTEDretained. Keep180s queued during commands/casts/crafting/unsafeinput;15sPCidle activation/priorapp restoration exception. Pause promptly viaCANCEL/nativeJUMP_STOP before requestedguardedreload;freshnonce afterresume. Useraway:asknoquestions. PreserveScan94c403db/Score13f28db1/parser689c630a/queue36a7b896/Craft853273d8/paneldc6de0aa/Watch08350be5 and unrelatedwork. Next: other real recipe IDs/full-field query coverage and established-evidence inventory/crafting fixes;do not apply unmeasured legacy-index or rejected catalogue/task-copy caches. Vendor unattended opening remains unsafe without genuine Shift skip.
[Exact source and native evidence](validation/profession-live-schematic-2026-11-18.json).
Native79/80 follow-up: all148actual cached recipes returnlive from both exact preceding private worker and installed current query;148full-record/nested-reagent matches,0mismatches/0failures,101learned,148withreagents,4quantityMin~=1. Three recipes per0.1s batch;5.078s walltime,maxpaired-query-plus-comparison1.1447ms (not frame/FPS). Installed method identity unchanged;probe/report removed,jumpcue restored,cursorclear/sessionerrors0. This closes current cached-catalogue field parity only;foreign/partial/quality/cold/skill-change/end-to-end UI and otherclient checks remainOPEN. Fresh29Retail/Forever sourcepairs unchanged;no addonLua edit or new simulation in this follow-up.

<!-- /LHO-PROFESSION-LIVE-SCHEMATIC-20261118 -->


<!-- LHO-NATIVE-CURRENT-BAG69-20261118 -->
18 November: current-source real bag mutation acceptance,**no addon Lua edit or new simulation in this slice**. Food4599x18 moved0:8->2:6 and returned automatically on firstattempt;final0:8has4599x18,destinationempty,cursorclear,baggen5->7. All54carried counts match WoW;food1487/count14/effective841 retained,bothSyndicator+Baganatorloaded/source syndicator/readytrue,queue4,errors0. Current Scan94c403db/Score13f28db1/parser689c630a/queue36a7b896 and all28Retail/Forever pins freshlymatch. After ordinary inventory changes rebuild publication, later Bestgeneration2169->2170 retains the same runtime across0.6s:reuse continues with fresh snapshot cardinalities. Full REUSE69 tuple personally viewed in finishcapture;helperREUSE70 prints only its first tuple value because of Lua and-expression adjustment,not an addon error.

One existing optional watch30.003s/4289driverframes/220observedcallbacks:peak34ms,0recorded>=50ms gaps,0observed>=10ms callbacks,watcherrors0/0. Directmove/return envelopes4.7003/3.4735ms at442388.800/442390.801;Notify0.710400/0.526700ms at442388.986/442390.987. No matched before/after FPS/spike gain or regression inferred from earlier source/windows. Watch covers specific service seams,not every handler/GPU/taint/pixel/controller/client. OriginalNotify/prior diagnostic root/prior spike report restored by identity;watchstopped,owned_M69/_M69r removed,originaljumpcueflag restored. Preferences0/120/30 unchanged;no buy/sell/delete/consume/mail/craftqueue/external-addon actions. Nativewatchfreshly1.60.1/70959;interface16001/project18 retained from native68.

Read-only vendor entry review pins Buy3e0b50e0:MERCHANT_SHOW latches private native Shift skip;otherwise After0 begins fastselling/repair. No public session-suppression setter found in inspected Buy/Session modules. Do not open unattended or replace native modifier APIs;vendor lifecycle acceptance remains pending. FullLHO01-13 staysACTIVE. Cold/newloot/quantitydepletion/charges,provider-off mutations,allkind/fullfield selection parity,bank/mail/vendor/AH/pending/craft/cast/otherclients and matched FPS/hitch benefits remainOPEN. Next: current-source Food cast/cancel/receive check if needed,then established-evidence Inventory/EBS fixes;keep0.4s cold retries/liveeligibility and ordinary notifications. No new simulation or foreign-addon edits.

R16 _J65q/j18n65a7 remains current,host37972/live20261118p via supervisor42708;liveverified,7Space pairs at recordtime,motionunverified. No reload69;temporaryjumpcue remains valid. Keep180s queued aroundcommands/casts/crafting/unsafeinput;15sPCidle activation/priorapp restoration exception. Stop promptly onpause viaCANCEL/nativeJUMP_STOP before requestedguardedreload;freshnonce afterresume. Only ownedprobe state touched;INPUT_HALTED retained. Useraway:asknoquestions. Preserve unrelatedwork/main;no commit/publication.
[Exact current native evidence](validation/inventory-current-native-bag69-2026-11-18.json).
Native72 follow-up: currentclient/session GetTradeSkillLine/GetNumTradeSkills/GetTradeSkillInfo/GetTradeSkillReagentInfo allnil,TradeSkillFrameabsent/Skilletclosed,cursorclear/errors0;no windows opened or crafting. Do not apply the unmeasured legacy-readiness index hint on this evidence. CanCraft discards Prepare index while CraftClick consumes it;future readonly hint must revalidate full live recipe and retain execution search/order. Review modern profession path next. This is current-session absence,not allclient removal. Gate rejected initial incorrect controller hash before native input;fresh label used with actual builder hash.
<!-- /LHO-NATIVE-CURRENT-BAG69-20261118 -->


<!-- LHO-PUBLICATION-CARDINALITY-20261118 -->
18 November: actual Scan.lua **8f9ebfdb -> 94c403db** saves each private publication row's entry count during ordinary snapshot creation. The original secret-value checker path verifies live key/value matches once plus cardinality for removals; the exact preceding two-pass worker remains for checker replacement. All secret/metatable/depth/128-table guards and scan/classifier/count/persist/selection/notification/retry/cadence paths remain. Cardinality uses pairs,including false values,not length. Whole-source restoration and measured-worker source equivalence (comments/whitespace/local names only) PASS;before/afterLua5.1/5.4parse PASS. An initial overly strict blank-line text comparison failed; normalized worker comparison passes. Dated external source/history verified,12settings stat rows,28Retail/Forever diskpairs match,no manualsync or new simulation.

Before editing, native63 privately compares exact preceding worker against candidate on **23real current published tables/158entries**,5calls pervariant perpair,three alternating pairs. Old0.599500/0.554200/0.900700ms;new0.344900/0.334800/0.532000ms;all true/true,real public tables unchanged,private root removed,errors0. Applied candidate worker matches measured worker. This establishes an isolated native comparison saving; snapshot construction/cardinality capture was outside that timing. No mocked item data,synthetic mutation suite or nativeAPI/installed-dispatcher replacements. Removal/addition/change equivalence is source proof; intentional secret/metatable/checker replacement cases were not natively induced.

Own64guardedreload readiness ACKed/freshstartup separately viewed. Current-source66/67 retains runtime identity on all4stored of7passive passes/3s,reason classifyPendingRead,4invalidations perpass,ordinary notifications;both dispatchers restored and roots removed. Fullpass4.8186/6.0142/5.4133/5.0837ms versus previous-source4.8335/5.6013/5.6334/5.7219ms:overlapping variation acrossreload. Mean5.447525->5.332450ms does NOT prove overall gain or regression;~5ms remains OPEN. Native68 freshly1.60.1/70959/16001/project18,bothaddonsloaded/source syndicator/readytrue,54nativecounts0mismatches,food1487/14/841 unchanged,queue4,errors0,preferences0/120/30,cursorclear. No FPS/hitch/all-workflow/otherclient/taint/pixel/controller claim.

Fresh R16 _J65q/j18n65a7 installed/ACKed;supervisor42708 launchedhost37972/live20261118p,host liveverified,2Space pairs at lastread,motionunverified. R15host56040 stopped/verified absent before reload;only ownedstop/setupholdsremoved,INPUT_HALTEDretained. Keep180s queue around commands/casts/crafting/unsafeinput;15sPCidle activation/priorapp restoration exception remains. Pause promptly viaCANCEL/nativeJUMP_STOP before requestedguardedreload;freshnonce afterresume. Useraway:asknoquestions. FullLHO01-13 ACTIVE. PreserveScore13f28db1/parser689c630a/queue36a7b896/Craft853273d8/paneldc6de0aa/Watch08350be5 and unrelatedwork. Next: safe real bag relocation/automaticreturn on current sources,verify fresh publication/count/selection and restored inputs;then remaining Inventory/EBS validation/tooltip costs. Cold/depletion/charges/provider-off mutations,bank/mail/vendor/AH/pending/craft/cast/allclients and matchedspike gains remainOPEN. No unattended merchant transactions or new simulation.
[Exact source and native evidence](validation/publication-cardinality-2026-11-18.json).
<!-- /LHO-PUBLICATION-CARDINALITY-20261118 -->


<!-- LHO-SCORE-RESTRICTION-CAPABILITY-20261118 -->
18 November: actual Score.lua **c542c20d -> 13f28db1** now checks the four existing restriction enum members before fetching native tooltip data. Native57 Forever70959 exposes their table but all four members are nil; food1487 native lines have types22/0/44/43. Unsupported typed-color checks now return false without the unusable native read; existing textual level/skill fallback stays live. Supported-member fetch/line body remains. Intentional compatibility fix: nil line.type must not match a nonexistent enum member as positive restriction evidence; that unknown/red case was not natively induced. No cache, timer, event, retry or cadence changes. Whole-source restoration proof and before/after Lua5.1/5.4 parse PASS; dated external source/history verified,12settings stat rows,28Retail/Forever disk pairs match; no manual sync or new simulation.

Native52 identifies classifyPendingRead:4invalidations every~0.4s,5.31-7.11ms inclusive. Native55/56 corrects the earlier rebuild hypothesis: runtime identity is retained on all four stored passes, so reuse works. Notification envelopes only0.0381/0.0617/0.0430/0.0411ms; the repeated validation/retry path owns most observed cost. Before55 first4of7 passes:5.4691/5.9857/7.2414/5.9833ms. After60 first4of7:4.8335/5.6013/5.6334/5.7219ms; runtime identity retained,4invalidations and ordinary notifications continue. One3s window per source acrossreload; mean6.169875->5.447525ms (11.7% lower observed),median5.98450->5.61735ms (6.1%). World/cache/system/GC differences and transparent-wrapper overhead remain. No causal FPS/hitch or full-workflow claim;~5ms passive cost remains open.

Own guardedreload58 readiness ACKed and freshstartup separately viewed. Native61:1.60.1/build70959/interface16001/project18;both Syndicator+Baganator loaded,source syndicator/readytrue,all54carried counts match native;food1487/count14/effective841 unchanged;queue4,errors0,scriptProfile0/maxFPS120/maxFPSBk30,cursorclear. Five actual eligible IDs remain unblocked;empty managem remains blocked. All trace dispatchers restored by identity;owned roots removed and prior diagnostics untouched. Four after rows scrolled off61;62 reads existing chat history only,not a replay. Percentage/cold/depletion/charges/other-provider mutations,typed-red/locale/otherclient/taint/pixels/controller and bank/mail/vendor/AH/pending/craft/matched spike coverage remain OPEN. Do not drop cold retries or change0.4s cadence.

Fresh R15 _J59q/j18n59a7 installed/ACKed;supervisor55536 launched host56040/live20261118o,host liveverified and2Space pairs at last read. R14host20380 stopped/verified absent before reload. Only owned stop/setup holds removed;INPUT_HALTED retained. Keep180s jumps queued during commands/casts/crafting/unsafeinput;15sPCidle activation/prior-app restoration exception remains,motion unverified. Pause promptly viaCANCEL/nativeJUMP_STOP before requestedguardedreload;freshnonce afterresume. Useraway:ask noquestions. FullLHO01-13 goal ACTIVE;preserve parser689c630a/queue36a7b896/Scan8f9ebfdb/Craft853273d8/paneldc6de0aa/Watch08350be5 and unrelated work. Next: reduce remaining live eligibility/tooltip validation cost without stale caching or skipped callbacks;safe real workflows only. No unattended merchant transactions.
[Exact source and native evidence](validation/score-restriction-capability-2026-11-18.json).
<!-- /LHO-SCORE-RESTRICTION-CAPABILITY-20261118 -->


<!-- LHO-PARSER-KEYWORD-POOLS-20261118 -->
18 November: parser source **689c630a** is loaded through our guarded reload48 and a separately viewed fresh startup. Native50 freshly reports Forever1.60.1/build70959/interface16001/project18, both Syndicator and Baganator loaded, source syndicator and ready. All54carried item counts match WoW; selectedfood1487/count14/effective841 is unchanged. Native51 retains3food/1water/1bandage/1heal/1mana classification matches;7current fixed records match unchanged scoring with live pools. Errors0,scriptProfile0,maxFPS120/maxFPSBk30;owned probes cleaned. Percentage/cold/otherclient/taint/pixel/controller and full-field comparisons remain open.

Native parser samples,50calls per sample on10real tooltips: before663a539a2.325100/2.471400/2.363900ms;after689c630a1.740600/1.904900/1.771100ms. Median2.36390->1.77110ms (~25.1% lower observed). Same collection method/inputcount/pools1037/2637;exact strings/IDs/order not exported. One sequential batch per revision acrossreload with cache/world/system differences supports a local observation,not causal FPS/fullworkflow/hitch gain. Source proof and5.1/5.4parse remain;28Retail/Forever diskpairs freshly match,0new simulations/manualsync. Three changes only:impossible flatcombo/generic resource guards and unused nonpercentage pool reads;no cache/retry/cadence changes.

The larger cost remains open. Prior native43-45 identifies actual2633/5634/7516 and3tooltip reads0.6039ms within1.0674ms nested query;source663a539a retained separately. Current full food query0.593300ms remains above initial0.147600ms baseline and below later0.818500/0.703600ms observations;states differ,so no fullquery gain claim. Native47 shows4invalidations betweencommands,but none inside its3GetAllBest calls;caller remains unproven. Next: trace actual tooltip collection and background invalidation owner,keeping live text/latecold recovery and0.4s read cadence. Do not drop pending retries or transfer old native acceptance.

Current jump helper is R14 _J49q/j18n49a7,host20380/live20261118n via supervisor26456,installed/ACKed and freshly liveverified. R13host51700 stopped/verified absent before reload. Guarded180s Space pairs/prior-app restoration requested;visual movement unverified. Queue aroundcommands/casts/crafting/unsafeinput;retain15sPCidle exception. Only our stop/setup markers removed;INPUT_HALTED retained. Stop promptly onpause viaCANCEL/nativeJUMP_STOP before requestedguardedreload;installfreshnonce onresume. All native probes finished;only intentional jumpcue remains. Useraway:ask noquestions. FullLHO01–13 ACTIVE;preserveScorec542c20d/queue36a7b896/Scan8f9ebfdb/Craft853273d8/paneldc6de0aa/Watch08350be5 and unrelated work. Broader workflow/provider/client coverage and matched spike gains remainOPEN.
[Exact source and native evidence](validation/parser-keyword-pools-2026-11-18.json).
<!-- /LHO-PARSER-KEYWORD-POOLS-20261118 -->

<!-- LHO-SCORE-FIXED-RESTORE-20261118 -->
18 November: Inventory/FluxConsumableBest/Score.lua a1d84a7d->c542c20d skips unused health/mana pool queries when missing pool arguments, original pool getter, plain nonpercentage record and numeric effective fully determine the result. No pool cache; supplied-pool/percent/nonnumeric/metatable/replacementgetter paths retain original full body. Removing only capture/early guard restores preceding whole source. Before/afterLua5.1/5.4parse and whitespace PASS; dated external source/history verified,12settingsstat rows;28Retail/Forever disk pairs match, no manual sync/new simulation. Tiers Match allocation idea was not applied;1a02bc12 remains.

Own guardedreload39 readiness ACKed/freshstartup separately viewed. Real queries over54IDs keep matches3food/1water/1bandage/1heal/1mana;7actual fixed restore values equal original explicit-live-pool calculation,selectedfood1487/14/841 unchanged,bothaddonsloaded/source syndicator/readytrue,errors0,cursorclear. Exact preceding scorer retained privately for native42 comparison against live candidate on7actual cached records:3pairs,140calculations pervariant perpair,old0.989300/0.979100/0.988300ms,new0.074500/0.081100/0.095500ms. All7outputs equal;public candidate identity unchanged. This is an isolated native computation gain,NOT FPS/full workflow proof.

OPEN regression/uncertainty: full first food query0.147600ms before versus0.818500after and0.703600followup;all samples retained. Othercategory samples smaller, but full query gain is unproven. Isolated scorer is faster;food-path cause not isolated. Revalidate actual pending items/cold classification/retries next;do not attribute to tooltip/cache/world or reject cold food without evidence. Previous4pending IDs are historical,not freshly queried39-42. Percentage/override/metatable paths source-reviewed,not natively induced. Full merchant/AH/pending/bank/mail/crafting/provider/cast/client/taint/pixel/controller/matched spike acceptance remains OPEN.

All owned _T39/_T40/_T41/_S42 code/data removed;no native APIs overridden,transactions or item moves;preferences preserved. CurrentR13 _J40q/j18n40a7 installed/ACKed,supervisor56212 launchedhost51700/live20261118m,live verified;oldR12host48628 stopped/verified absent. Guarded180s Space pairs and prior-app restoration requested;movement unverified. Queue during commands/casts/crafting/unsafe input,retain15s idle exception. Stop promptly onpause viaCANCEL/native JUMP_STOP before requested guardedreload;freshnonce afterresume. Only owned holds removed,INPUT_HALTED retained. Useraway:ask noquestions. Whole LHO01–13 ACTIVE;preserve queue36a7b896/classifier663a539a/Scan8f9ebfdb/Craft853273d8/paneldc6de0aa/Watch08350be5 and unrelatedwork.
[Exact source and native evidence](validation/score-fixed-restore-2026-11-18.json).
<!-- /LHO-SCORE-FIXED-RESTORE-20261118 -->

<!-- LHO-INVENTORY-QUEUE-MINIMUM-20261118 -->

Final source **36a7b896** is now adopted through own guarded reload37 and a separately viewed fresh startup. Native38 moved food4599x18 from0:8 to2:6 and returned it; source/destination/cursor restored, all54carried IDs match native, food selection1487/14/841 retained, generation5->7. Both Syndicator and Baganator explicitly loaded; source syndicator/readytrue, classification queue4 remains. Original Notify and prior diagnostic root/report restored by identity; owned watch/code/data _M38/_M38r removed, jump cue restored. Errors0/0; preferences0/120/30 unchanged. Lua5.1/5.4 syntax/source proof retained; all27Retail/Forever source pairs freshly match without manual sync or new simulation.

Final-source Notify envelopes0.509200/0.475200ms (mean0.49220ms), baseline0.571000/0.571300ms (mean0.57115ms). One sequential window each; reload/cache/world differences and231vs136observed callbacks prevent causal CPU/FPS/hitch claims. Final30.001s watch5254frames/136callbacks,peak30.000001ms,0>=50ms gaps/0slowcallbacks. Native35before e42893e4,36intermediate3c3ba2e5 and38final36a7b896 remain separate evidence. The positive-minimum guard handles unknown/ghost ordered entries through the original scan; forced error/reentry paths are source-reviewed, not natively induced.

Current R12 _J38q/j18n38a7 is installed/ACKed; oldR11host47908 stopped and verified absent. R12host48628/live20261118l is verified live, with guarded180s Space pairs and prior-app restoration requested; visual movement is unverified. Queue jumps during commands/casts/crafting/unsafe input, retain15s idle exception and shared input ownership. Stop promptly on pause via CANCEL/native JUMP_STOP before requested guarded reload; fresh nonce after resume. All native probes cleaned, only intentional jump cue remains. User away: ask no questions.

Full LHO01–13 remains ACTIVE. Preserve appearance/features/cadence/settings, classifier663a539a/Scan8f9ebfdb/Craft853273d8/paneldc6de0aa/Watch08350be5 and unrelated work. Continue Inventory/EBS fixes from existing evidence with safe native workflows; no new simulations or unattended merchant transactions. Other provider mutations, cold/depletion/charges, merchant/AH/pending/bank/mail/crafting/cast paths, other clients/taint/pixels/controller and matched hitch improvements remain OPEN. Historical paragraphs below refer to their stated earlier source/helper, not current acceptance.

18 November: Inventory/Init.lua e42893e4->3c3ba2e5 avoids repeated full queue-minimum scans when a new deferred job is the only mutation since the cached minimum. Append/update/cancel/dequeue advance a private version before fallible work;reentry/interrupted enqueue,existing updates,cancel/dequeue/wakes use original full scan. Entire deadline/timer/frame/budget suffix and all other source restore exactly to preceding file after removing only this metadata/hint patch. No callback batching or slower cadence:queue/context/order,inline counts,quiet/maxwait,2jobs/frame,1.5ms and idle detach remain. Before/after5.1/5.4syntax and whitespace PASS;27Retail/Forever source/helper pairs match;dated external source/history verified,12settings stat-only records;no private contents copied/manual sync/new simulations. Source-derived fresh-append work n(n+1)/2 queue visits becomes1visit+n-1 scalar comparisons;15registered scan listeners is NOT proof15actuallyqueued.

Real native35/36 before/after:4599x18 moves0:8->2:6 and returns;both windows restore source/destination/cursor,all54carried counts match,food1487/14/841 retained,gen5->7,errors0. Two Notify envelopes before0.571000/0.571300ms,after0.554600/0.487000ms;mean0.57115->0.52080ms (~8.8% lower observed). One sequential pair/reload/cache/world differences and231vs127observed Flux callbacks prevent causal CPU/FPS/spike claims. Both30s watches record0>=50msgaps/0slowcallbacks;peaks40vs36ms are not a proven gain. Notify original/prior diagnostic root AND report restored by identity;owned watches/code/data roots _M35/_M35r/_M36/_M36r removed. ScriptProfile0/caps120/30 unchanged. Own guarded reload readiness ACKed and fresh startup separately viewed;no loaded-byte hash.

Fresh R11 _J36q/j18n36a7 installed/ACKed after reload;R10b host50368 stopped/verified absent. Current host47908/live20261118k via supervisor5416 verified live,first Space pair15:27:19UTC/prior-app restoration requested,motion unverified. Own stop/setup holds removed only by matching ownership;retained INPUT_HALTED preserved. Keep180s jumps queued during commands/casts/crafting/unsafe input;15sidle activation/prior-app restore exception unchanged. All native probes finished;only intentional jump cue remains. Pause promptly via CANCEL/GOAL_DONE/native JUMP_STOP before requested guardedreload;fresh nonce after resume. User away:ask no questions.

Full LHO01–13 ACTIVE. Existing-job update scans remain;native cancellation/reentry/forced/cold/provider-off mutation coverage,all clients/taint/pixels/controller and merchant/AH/pending/bank/mail/crafting/cast workflows/matched hitch gains remain OPEN. Preserve classifier663a539a,Scan8f9ebfdb,Craft853273d8,paneldc6de0aa,Watch08350be5 and unrelated owners. Next: continue Inventory/EBS source fixes from existing evidence;use safe real workflows only,no simulation or unattended merchant transactions. Before another reload stop/replace current47908 helper;never replay spent packets.
[Exact source, native samples and limits](validation/inventory-queue-minimum-2026-11-18.json).
<!-- /LHO-INVENTORY-QUEUE-MINIMUM-20261118 -->

<!-- LHO-CRAFT-CLIENT-PREDICATES-20261118 -->
18 November: actual Inventory/Craft.lua edit75197d0a->853273d8 removes private8-field ClientFlags allocation. Dynamic scalar IsPostDF/IsCamelot preserve original relevant primary/fallback precedence,Forever aliases,truthiness and FirstAid rules. No flag/recipe/native-fact caching. Restoring only private predicate region plus old IsPostDF definition exactly restores preceding whole source after newline normalization;all other public/native/classification/count/reagent/rank/cache/event/refresh bodies remain. Before/after5.1/5.4syntax and whitespace PASS;26Inventory/EBS/helper Retail/Forever disk pairs match without manual sync. Dated external source/history verified and12settings stat-only rows available;no private settings contents copied or new simulation.

Native34 before/after scoped crafting readiness PASS:availabilitytrue/true/true,list sizes5heal/2mana/9bandage,same no-affordable best selections,plain client/API flags. Before list calls1.6934/1.2390/1.0011ms;after1.6667/1.1857/1.1918ms. One sample each and reload/cache/world differences do NOT prove CPU/FPS/hitch improvement or causal regression;only allocation removal is established. Own ReloadUI command fully queued;initial submitted capture was too early/blankchat and remains unaccepted. Separate personally viewed fresh startup verifies reload association;controller correctly refused submitted-phase refresh,no replay. After-read batch formally ACKed;generation9->5reset,scriptProfile0,no new session errors. Prior diagnostic-only session1 becomes0on normal reload;logs not manually cleared. Native actual crafting/ingredients/active pending legacy execution,full row equality,other clients/taint/pixels/controller remain OPEN.

Reload resets temporary code. R9host49768 stopped/verified absent through owned marker. Fresh R10b _J34q/j18n34a7 cue installed/ACKed;supervisor55884 launched host50368/live20261118j,verified live at15:00:02UTC,3Space pairs/latest14:57:52UTC/prior-app restore requested,motion unverified. Own setup no_jump released;retained INPUT_HALTED preserved. R10source-only package neverexecuted;R10b byte lengths recomputed for longer nonce. Initial install_a begin stopped before input because setup hold absent;fresh install_b accepted,never replay spent packets. Current stop protocol CANCEL/GOAL_DONE/native JUMP_STOP;queue during commands/casts/crafting/unsafe input,15sidle activation/prior-app restore. Pause promptly. User away:ask no questions.

Whole LHO01–13 goal ACTIVE. Other current classifier663a539a/scan8f9ebfdb/paneldc6de0aa and Watch08350be5 preserved. Source review flags pending legacy readiness full-list lookup;do not add a stale index cache without full current recipe/reagent validation and real path coverage. No change to FollowupCraft8095e63c and no revival of rejected catalogue/task-copy candidates. Continue actual Inventory/EBS fixes from existing evidence;no new simulations. Vendor/AH/pending/bank/mail/crafting/provider-off mutations/cold/deplete/charges,allclient and matched spike gains remain OPEN;avoid unattended merchant automation and all buy/sell/delete/consume/mail actions.
[Exact source, native observations and limits](validation/craft-client-predicates-2026-11-18.json).
<!-- /LHO-CRAFT-CLIENT-PREDICATES-20261118 -->

<!-- LHO-NATIVE-CAST-RECEIVE33-20261118 -->
18 November: actual highest-rank Food cast/cancel/complete and received-item check, no simulation or new addon Lua edit. Native trace START+8.438s/STOP+8.682s, three INTERRUPTED+8.814s, second START+9.111s, SUCCEEDED/STOP+12.017s, BAG_UPDATE_DELAYED+12.074/+12.437s relative428631.826. Completed cast creates14Conjured Pumpernickel1487; native/Flux14/14, all54carried IDs0mismatches, generation7->9. Food selection changes to1487/count14/effective841 as new food arrives; queue4 remains. Items retained; no buy/sell/delete/use/mail/craftqueue/external-addon changes.

Existing optional30s watch:30.007s/4362driver frames/998observed callbacks,0recorded>=50ms gaps,peak45ms;1slow inclusive Scheduler structural.callback at+12.455s/15.8371ms,only border.junctions token. This does not prove inventory-exclusive CPU or matched FPS/spike gain. Diagnostic sections69.8221ms total/.1544ms peak,watch errors0/0,scriptProfile0/maxFPS120/maxFPSBk30 unchanged. Exact loaded border/cast hashes not captured; no revision-specific attribution or allclient/taint/pixel certification. PrintWindow/world/system/party activity remains a confound; unrelated party/loot actions were not this goal's commands.

Owned event frame detached and watch stopped; prior diagnostic root/report restored by identity; _C33/_C33r removed, R9 cue prior flag resumed. A later read-only report printer incorrectly table.concat'ed native string tokens, causing1diagnostic-only error AFTER watch/cleanup; corrected tostring print verifies string. Error log preserved; session is NOT zero-error. Final count/selection/root results were personally viewed and formally ACKed. R9 host49768/client42724 freshly verified live at14:35:01UTC,22guarded Space pairs/latest14:32:15UTC; motion not visually verified. Keep180s queue during commands/casts/crafting and15s idle activation/prior-app restore. No reload in33; only intentional jump cue remains. Pause promptly using CANCEL/native JUMP_STOP before cleanup/reload. User away: ask no questions.

Full LHO01–13 stays ACTIVE. Current classifier663a539a,scan8f9ebfdb,paneldc6de0aa and all24Inventory/EBS pins remain unchanged through33. Scoped cast cancel/finish/new-food count/selection acceptance now recorded on Forever70959. Native crafting/channel/delay/pet,provider-off mutations,cold/deplete/charges,merchant/AH/pending/bank/mail workflows and other clients/matched gains remain OPEN. Continue actual Lua fixes from established evidence; no new simulations or unnecessary captures. Avoid unattended merchant opening that could run buying/selling automation.
[Exact native trace, source pins and limits](validation/inventory-native-cast-receive-2026-11-18.json).
<!-- /LHO-NATIVE-CAST-RECEIVE33-20261118 -->

<!-- LHO-NATIVE-BAG-MOVE32-20261118 -->
18 November: real authorized food-stack relocation, no simulation. Unlocked4599x18 moved backpack0:8->genericbag2:4 and automatically returned on first attempt. Final0:8has4599x18,2:4empty,cursorclear;bag generation5->7;native/Flux food18/18,selected food4599/count18/tier1338;all53unique carried IDs still match native,0errors. Both addons remain loaded from restored prior flags. Native70959/1.60.1 observed;scriptProfile0,maxFPS120,maxFPSBk30 unchanged. Existing optional30s watch used;prior diagnostic root AND prior spike report restored by identity, own watch stopped, _M32/_M32r removed, owned jump cue resumed. No buy/sell/delete/use,craft queue,external-addon edits or addon Lua change in this slice.

Actual watch30.001s:4667driver frames/273observed callbacks,3gaps120/248/93ms at+2.540/+2.788/+4.976s. Two slow inclusive scheduler callbacks190.0694/72.3385ms at+2.540/+4.883s, both only tokenborder.junctions;generic label unmapped. They precede the deliberately delayed move (minimum+8s). Direct guarded move/return envelopes4.2417/3.0836ms,GetTime426712.797/426714.801. No recorded>=50ms gap or>=10ms observed Flux-service callback during/after the move phases in this one window. This does not certify all inventory handlers or a paired FPS gain. PrintWindow/setup/system/party activity are confounds;248ms is not attributed to inventory. Exact loaded BorderJunctions hash was not captured;no claim that a particular border revision regressed,and no border source edits here. Recorded diagnostic sections78.3133ms total/.4415ms peak exclude some observer overhead.

Full LHO01–13 remains ACTIVE. Native actual relocation with both addons now has scoped acceptance;cold/loot/new quantities/depletion/charges,provider-off mutations,bank/mail/vendor/AH/pending/crafting,cast/channel/interrupt/finish,all clients/taint/pixels/controller and matched spike improvements remain OPEN. Next: native Food cast/cancel/completion and received-item updates, reusing bounded existing watch with prior diagnostic roots/preferences preserved. CurrentR9 _J23q/j18n9p9 keepalive remains authorized;host49768 last verified live, reverify now rather than trusting a state file. Pause promptly using CANCEL/native JUMP_STOP before cleanup/reload. No questions while user away. Current process42724/window50333792/birth134394624880288175.
[Native phases and ownership evidence](validation/inventory-native-bag-move-2026-11-18.json).
<!-- /LHO-NATIVE-BAG-MOVE32-20261118 -->

<!-- LHO-NATIVE-COUNT-COMBOS31-20261118 -->
18 November: all3legal live addon combinations checked on same Forever client: both11/Syndicator-only10/built-in00 each ready and Flux/native food4599count18/18, scriptProfile0/errors0. Original flags captured before changes; both restored and natively verified loadedtrue, character2/global2. Final restored state compares all53unique carried item IDs with native counts:0mismatches. Seven current best rows recorded; no complete before/after selection equality inferred from the obscured earlier baseline. No agent purchases/sales/deletions/moves/craft queues or external-addon source edits. Unrelated party/loot-setting messages are not this goal's actions and do not establish another test's provenance.

Actual Vendor panel dc6de0aa is now adopted by observed ownC1/restoration reload association, as is classifier663a539a. Vendor tab first-open/hide-show/reentry/cold metadata and actual bag mutation/loot/zero/bank/mail/AH/native frame-spike acceptance remain OPEN; count smoke is not those workflows or a measured performance gain. Existing single30s parser pair remains1168calls/71.3209ms vs1152/60.4172ms, no causal overall FPS claim. All broad LHO01–13 requirements remain ACTIVE. No questions while user away.

Combo reloads reset temporary code. Fresh R9 _J23q/j18n9p9 cue installed/ACKed after original addons restored; supervisor38984 launched host49768/live20261118h. Host49768 verified live at13:32:49UTC;2Space pairs delivered, latest13:30:22UTC, with prior-app restoration requested. Movement not visually verified. Final read-only client capture shows world/chatclosed and refresh notice gone;no reconnect performed;new maxHP1297 versus prior1037 timing windows. Keep180s timer queued during commands/casts/crafting/unsafe physical input. Stop promptly on pause; CANCEL/GOAL_DONE/native JUMP_STOP remain authoritative. Reinstall fresh nonce after a real reload rather than replaying spent packets. Actual world-refresh countdown observed, about13:33UTC due; normal warning/Reconnect/named-character selection already authorized, verify exact client first. Current process42724/window50333792/birth134394624880288175. Next safe checks: native real bag move/return or Food cast/receive under optional bounded existing watch, preserve prior diagnostic roots/preferences; first review current client/cursor/item locations and shared input ownership. No simulation.
[Native evidence and limits](validation/inventory-native-count-combos-current-2026-11-18.json).
<!-- /LHO-NATIVE-COUNT-COMBOS31-20261118 -->

<!-- ROSTER-TRANSITIONS-R70-20261118 -->
18 November: user reports R69 still hitches, authorizes full party/raid join/leave
review/rework, and is away: **ask no questions or native tests**. R70
`roster-layout-r70` changes22runtime files after reviewing40signal owners.
Prepared unit-root snapshots now observe public authored layout rather than
transient computed bounds. Regional drawing uses the existing guarded sprite
reuse with per-cell epochs and shared cache bounds.17player-only spec consumers
ignore confirmed other units; unknown/private/alias handling stays conservative.
Raid spell updates reuse aura paint; unchanged secure attributes skip writes
while every native roster execution/reference reconciliation remains.

179unique focused scripts PASS;1225stable syntax checks plus2final fixture parses;
1427prototypes maximum51captures. Five archived negative controls rejected.
A pre-existing1200character smoke window missed the unchanged color helper at
1286; its routine boundary is corrected and helper/raw-key checks retained.
Regional setter checks3531->1803/type1 and6393->2793/type2 atscale1/four moves;
other scales/art/paint/index checks pass. These are desktop results only.
Native hitch/GPU/FPS/taint acceptance remains OPEN. No native input/profiling or
settings changes; preserve other owners and saved captures.
[Exact sources, audit and evidence](validation/roster-transitions-2026-11-18.json).
<!-- /ROSTER-TRANSITIONS-R70-20261118 -->

<!-- LHO-VENDOR-SELECT-COALESCE-20261118 -->
18 November: user is away for a long time and explicitly says ask no questions. Continue autonomously within existing permissions; unavailable native state stays OPEN, no purchases/sales/deletion or external Syndicator/Baganator edits. Active three-minute jump host is41780 (R8 _J22q/j18n8p9); stop promptly on pause and queue around commands/casts/crafting/input activity.

Edited actual Vendor/FluxVendorRestockPanel.lua e42f40bf->dc6de0aa. Verified SecureTabs.Update invokes OnSelect before SetShown; Restock OnSelect and OnShow both invoke OnTabSelected and queued duplicate After0 rebuilds. One private boolean now preserves the first next-frame callback, reading latest state and resetting before QueryItems so reentrant requests still schedule. Both synchronous tab handlers, invalidation/settings/scroll, hidden-panel checks, row/list/query/count/render bodies,0.2s metadata retry and0.2/0.35s bag/burst refresh remain. Removing only the guard/reset/declaration restores the entire exact preceding source after newline normalization. Before/after Lua5.1/5.4 syntax and whitespace PASS;24Retail/Forever disk pairs match. Dated external source/history verified and12settings stat-only records available. No new simulation; no settings/private contents copied.

This coalescing edit is NOT LOADED yet. Native first-open/tab/hide-show/reentrant/cold-metadata and timing acceptance remain pending; earlier9row2.313ms/empty-panel0.1148ms observations are historical scope, not acceptance or measured reduction. Avoid merchant opening that could trigger buying/selling while unattended. Current adopted classifier663a539a has the recorded30s samples1168/71.3209ms before and1152/60.4172ms after, both restore/error0; one sequential pair is not causal FPS/spike proof. Whole LHO01–13 goal remains ACTIVE. Next safe adoption batch should load dc6de0aa and restore temporary readiness cue after reload; resume legal addon-combination/query/bag UI validation with original flags restored and no transactions.
[Exact sources and limits](validation/inventory-vendor-select-coalesce-2026-11-18.json).
<!-- /LHO-VENDOR-SELECT-COALESCE-20261118 -->

<!-- LHO-PARSER-AXIS-PREFILTER-20261118 -->
18 November: continued actual Inventory Lua work; no new simulation. Direct `FluxConsumableClassify.lua` source663a539a now skips per-line health/mana axis workers only when the normalized line lacks that required literal, and combo-percent only when both are present. All22existing private patterns require their axis word; workers, amounts, percent pools, retry/load/invalidation/budget/cadence and public entry points remain unchanged. Removing only the loop gates restores the entire preceding source. Before/after Lua5.1/5.4 syntax and whitespace PASS;24Retail/Forever disk pairs match. Verified external history/source checkpoint and12settings stat-only rows; no settings contents copied. Concurrent Engine/Watch.lua change08350be5 preserved.

Actual native baseline:30seconds,1168ParseFoodWaterRestore calls,71.320901ms total,0.231800ms maximum; original parser restored, BugTabs session0, bags generation5, queue4, merchant closed. New source adopted through own guarded reload `parserAxisReload_c`, loading screen personally viewed and formal ACK accepted. Native after:30seconds/1152calls/60.417198ms total/0.208700ms maximum; original restored/error0, bagGen5/queue4/merchantclosed unchanged. Observed mean0.06106to0.05245ms (14.1% lower) is a single sequential sample pair with camera/mode/roster and concurrent Watch source differences, not repeated matched causal FPS/spike acceptance. Queue4 remains. No overall FPS/spike gain or other-client certification claimed. Previous cached-negative budget correction was adopted/tested, but controlled scans still queue3; seven-kind equality and restoration true, single6–10ms envelopes do not establish gain.27formal result ACK was late/rejected. Accepted28trace identifies pending5634Free Action Potion,7516Tabetha instructions,2633Jungle Remedy,3703Southshore Stout; observer restored/error0. Read-demand resets and late-tooltip retries remain open; do not simply remove them.

User confirms no other WoW test is running.28also confirms prior jump globals nil, cause unproven. R6waiting supervisor57056 stopped. Fresh R7cue installed/ACKed; host57060 delivered3Space down/up pairs then was explicitly stopped for our reload. Key delivery is not visually verified character motion. R8fresh cue `_J22q`/`j18n8p9` installed/ACKed after own reload; supervisor43356 started for live20261118g. Host41780 process verified live at12:55:17UTC; current readiness calibration passed and a foreground Space key pair completed with input lock released. Three-minute timer active; no visual character-motion certification. Inspect current state on resume. Explicit CANCEL/GOAL_DONE/JUMP_STOP, auth lifetime, idle15 focus exception, advancing readiness/chat/crafting/combat/input ownership gates retained; parent AND capture-child no longer silently expire after600s of agent/tool latency. Failed calibration backs off15s. On pause stop immediately, honor requested guarded reload and record temporary-root reset. Goal ACTIVE; broad Inventory/EBS/vendor/AH/pending/bank/mail/casting/provider combinations remain tracked.
[Exact evidence](validation/inventory-parser-axis-prefilter-2026-11-18.json).
<!-- /LHO-PARSER-AXIS-PREFILTER-20261118 -->

<!-- REGIONAL-PLAN-R69-20261118 -->
18 November: native R68 party join/leave still blocks `border.junctions` for
161.4/123.1ms. The161.39ms peak spends105.40ms planning with59active regions,
6changed; repeated target/focus availability reasons remain recorded. Direct
`regional-plan-r69` keeps complete source cuts/ownership but compiles branch and
fallback meshes only for changed output. Unchanged committed numeric compile
records now survive partial publication, under existing storage limits.

78focused scripts and1220Lua syntax PASS;226Core prototypes maximum51 captures.
Repeated actual-source desktop moves compile6 fresh meshes versus24 per sequence;
matched median CPU44->29ms/style1 and53->34ms/style2 for six moves. These are model
measurements, not native latency/FPS/taint/GPU acceptance. R69 native party checks
remain OPEN; R68 is confirmed insufficient. No native input/profiler/settings or
protected routing changes; other owners preserved. Test/benchmark jobs stopped.
[Exact sources and evidence](validation/border-regional-plan-2026-11-18.json).
<!-- /REGIONAL-PLAN-R69-20261118 -->

<!-- PARTY-MATERIAL-OWNERSHIP-R68-20261118 -->
18 November: user corrects R67 acceptance: party join/leave still hitches and
requests all roster handlers checked with combat/taint safety retained. Direct
Lua follow-up `party-paint-r68` removes whole-addon material ownership scans from
SetUnitColor/SetUntinted. Weak texture buckets track actual ancestors and detached
unit owners; existing reparent observers maintain them. No private unit identity
cache, protected layout/input change, extra event/timer, settings or native input.

A four-member/96-unrelated-border replay makes548 parent queries versus31844;
material/RGBA/UV results match.77 focused scripts PASS (76initial plus corrected
existing preview-colour fixture);1219syntax PASS;292prototypes max51. Existing
secure roster, member identity/model/cast refreshes, aura/dispels, hover/bars/EBS,
minimap/LFG/nameplate/stats/threat consumers remain. Native party/taint/FPS
acceptance is pending; earlier general no-hitch acceptance did not cover this
remaining case. All benchmark jobs stopped. No agent game input/profiler edits.
[Evidence](validation/party-material-ownership-2026-11-18.json).
<!-- /PARTY-MATERIAL-OWNERSHIP-R68-20261118 -->

<!-- LHO-CACHED-REJECTION-BUDGET-20261118 -->
18 November: edited actual Inventory/FluxConsumableClassify.lua (2718aaba) and FluxConsumableBest/Scan.lua (8f9ebfdb), on main. Addon-private defining-owner/cache query exempts only already-loaded, exact cached false classifications from budget decrement while budget remains. Still calls ordinary classifier; actual candidate/parse work stays capped24. Exhausted-budget queue path, retries/cadence/live counts/ranking/render bodies unchanged. Replaced Classify/IsPending, metatables or absent private record keep old accounting.8before/after Lua5.1/5.4 syntax jobs PASS; removing only new chunks restores both entire baseline files after LF normalization;24Retail/Forever pairs match. External history bundle verified;12FluxUI settings stat records and byte-exact source checkpoint external, no private contents copied. Native before: generations1918to2152 in186.240s with bagGen10 unchanged, pending load0 and classify queue2to3; contexts flight then vendor, so no controlled idle CPU/FPS inference. IB24 nineteen consumable IDs/47cached negatives across whole bag set, overlap unmeasured. No new simulation/mock. Timing24 setup expired0calls; late arm diagnostic assertion preserved, original method untouched.25arm never succeeded;26batch source-only abort. Native CPU gain unproven. NEW LUA NOT LOADED/NOT NATIVE-TESTED yet. Next guarded reload/adoption and actual queue/selection/count/replacement checks; preserve both grids and all clients. Jump host39428 is STOPPED since11:18 on stale heartbeat, after2successful FG/BG key pairs; current process absent. Restore helper with explicit pause/goal stops and auth lifetime that survives long agent/tool waits; do not claim running yet. Goal ACTIVE.
[Evidence](validation/inventory-cached-rejection-budget-2026-11-18.json).
<!-- /LHO-CACHED-REJECTION-BUDGET-20261118 -->

<!-- BORDER-R67-USER-ACCEPTED-20261118 -->
18 November: the user first reports "The hitches are much better", then answers
"No noticeable hitches remain" to the explicit R67 residual-hitch question.
The direct Lua border-builder goal is complete on that user acceptance and the
stable68-script/1218-syntax gate. No new runtime edits since the frozen R67 hash.
This is general user feedback, not an independently observed loaded source hash,
per-event test matrix, quantitative native CPU/FPS, GPU or all-client taint proof.
Other-client/native certification remains unperformed; no agent native input or
profiler changes occurred. This supersedes earlier ACTIVE/OPEN delivery status.
[Evidence](validation/border-regional-render-2026-11-18.json).
<!-- /BORDER-R67-USER-ACCEPTED-20261118 -->

<!-- LHO-JUMP-RESTORED-20261118 -->
18 November jump reminder: current external r5 periodic host PID39428 RUNNING. Supervisor48892 observed native BG red advancing counter and launched the host, then exited. Interval180s after completed pair; latest state linked below. It waits for15s PC idle and fresh readiness before each jump. Due jump stays queued while chat/scripts, casting/crafting, movement or taxi flight blocks it; all actual Space requires original fresh GREEN + chat-open red/heartbeat-green acknowledgement and shared input.lock. First Space pair not yet accepted at this receipt. User currently on taxi (~11min remaining at last photo), so red/queued is expected. Old helpers25000 and49400 stopped with0pairs; do not revive them. Apparent UI restart cleared old cue after earlier vendor checks. New RAM cue _J19q/j18n5p8: first24 setup packets fully queued, Ctrl in packet gap stopped before25; batch terminal, not replayed. Actual INIT true viewed; separately sent only missing enable command, new J83CUE visually ACKed. No addon Lua/settings/item actions. Idle activation/minimized restore paths preserved; native activation repair and first jump remain pending. Stop promptly via P4/CANCEL on pause; verify helper exit and perform requested guarded reload. Reload clears cue; reinstall fresh when continuing. Refresh native/agent-heartbeat every5min during active work;600s stale heartbeat stops it. Inventory24 unchanged; VC24 nine-row2.313ms/empty VR24.115ms remain scoped pre-restart single samples without paired FPS benefit. Goal ACTIVE.
[Evidence](validation/inventory-jump-restored-2026-11-18.json).
<!-- /LHO-JUMP-RESTORED-20261118 -->

<!-- BORDER-REGIONAL-RENDER-R67-20261118 -->
18 November: direct border Lua `regional-render-r67` is frozen at Core LF/raw
`ec17fc10294fc35578fb24a59a54281d90a64e4f878d4c62d201a8c58c57b843`. Changed parent/dependency geometry and nearby joins update only their
prepared regions. Indexed listeners/source pools retain unrelated arrays and
fields. Existing native RGB/alpha/private recovery, rounded caps and unsplit cast
sections remain supported. No action routes, settings, native input or profiler
preferences changed.

Current exact-source gate:68 focused scripts PASS;1218 syntax PASS;226 Core
prototypes, maximum51 captures. Divider movement updates4 regions, retains
34/46/60 and reads2 model rectangles versus26. Alternating model CPU medians
4/5ms versus6/7ms are desktop evidence only. Native combat/group/raid/drag/minimap,
GPU/taint/controller/FPS acceptance remains OPEN. Goal stays ACTIVE. No native
lease here; preserve other owners' changes/controllers and CF62/CF64/CF65.
[Requirements](BORDER_BUILDER_LOCALITY.md), [evidence](validation/border-regional-render-2026-11-18.json).
<!-- /BORDER-REGIONAL-RENDER-R67-20261118 -->

<!-- LHO-VENDOR-COUNTS-LIVE-20261118 -->
18 November: current24 Retail/Forever source pairs remain identical; no addon Lua edits in this slice. Native VC24 successfully refreshed nine actual options rows in 2.3129999637604ms. New VS24 normal tab display and VR24 shown empty sold-only panel count refresh (0.11480003595352ms) visually ACKed. Session count1 is Skillet recipe drag-start nil skill at Skillet.lua:1784; bounded stack read shows SetSelectedSkill/SkillButton_OnDragStart. Counter remained1 through VR24; errors were preserved. No item actions, filters, profiler changes, temporary globals/hooks or simulations. These are single current24 timings, without a matched baseline, per-entry parity or populated panel render certification. Earlier selectionC queued final Enter but failed capture on Foreground unknown; terminal and unaccepted, never replay. BG capture policy now permits switching between other apps while preserving WoW mode/input guards. All command locks released and five lease observer PIDs absent in host read. Duplicate scheduling remains unapplied pending native evidence/cold-readiness review. User renewed three-minute jump request; restore helper next and record actual running state separately. Goal ACTIVE.
[Evidence](validation/inventory-vendor-counts-live-2026-11-18.json).
<!-- /LHO-VENDOR-COUNTS-LIVE-20261118 -->

<!-- LHO-VENDOR-PANEL-LIVE-20261118 -->
18 November: current24 source pairs remain stable; no new addon Lua edits.
User opened Edna Mullby merchant. Initial ID24 source-only probe sent no command;
its lease ended Not drawable when client minimized. Restored exact WoW window
behind other windows with documented NOACTIVATE flags; foreground692126702
unchanged across that call, no keys/mouse/cursor/clipboard/activation API used.
Then actual SecureTabs normal handler selected Restock; VS24/new panel display
visually ACKed. Sold-only list empty; filter remains unchecked and unchanged.
VR24 count preflight aborted before Enter/characters on foreground physical
input; lock released and run terminal. Later reads still showed active foreground
mouse input; do not type into that or replay retired runs. Count/zero-error/native
spike acceptance has NOT advanced. No items, filters/profiler preferences or
persistent probe roots/hooks changed. Native24 earlier ownreload stands.
New UNAPPLIED source lead: enabled tab OnSelect and panel OnShow each schedule
After0 QueryItems/full rebuild; size change may add another cache miss. Actual
multiplicity/timing unmeasured. Preserve ordinary metadata0.2s retry and separate
tier/classification readiness; do not blindly coalesce a cold-data useful retry.
Next when input is idle/background: prepared VR24 actual panel count; use VC24
real options rows if populated coverage is needed without changing filter. Then
measure tab-open query count before optimizing duplicate scheduling. No simulations.
Goal ACTIVE; no input/jump helper running. Pause promptly on request.
[Evidence](validation/inventory-vendor-panel-live-2026-11-18.json).
<!-- /LHO-VENDOR-PANEL-LIVE-20261118 -->

<!-- LHO-VENDOR-ROW-RELOAD-20261118 -->
18 November: own guarded reload vendorowner_reload_20261118a observed loading
then world, adopting current24 source set. No further reload needed for vendor
check. Standalone VC24 count preflight sent NO input: a physical foreground key
was held. Released only its unused lease; run is retired, do not replay it.
User says can open vendor with Shift. Latest passive view shows Edna Mullby
before merchant opening; leave input alone while user moves/opens. Prepared
VR24 actor requires shown MerchantFrame and named Restock panel before actual
RefreshCountsOnly. Native24 count/panel/craft/override/spike checks remain
pending. Input lock absent; no jump helper. Goal ACTIVE.
[Evidence](validation/inventory-vendor-row-ownership-2026-11-18.json).
<!-- /LHO-VENDOR-ROW-RELOAD-20261118 -->

<!-- LHO-VENDOR-ROW-OWNERSHIP-20261118 -->
18 November: actual foreground native reads confirmed build70959/interface16001/
project18, source syndicator ready, both addons loaded,1487 counts0/0 and
profile0/errors0. Food GetBagOwnedTier normal vs actual forwarding wrapper both
returned1338/4601; pcall true, original getter restored before output. All three
runs freshly viewed/ACKed; observers gone, input lock absent. No fake API data.
Then checkpointed List2178f495 and AuctionCraft54bc0444 outside AddOns, verified
71d1 history and statted125 settings paths. Applied List030b8a41/Craft8462442f
private row-borrow ownership guard, preserving default reuse and restoring copies
for replacements/meta rows. All prior craft bodies remain text-identical;
8 before/after Lua5.1/5.4 syntax checks PASS;24 source pairs match. No native
input after this edit, no simulations/mock tests or external-addon changes.
[Ownership evidence](validation/inventory-vendor-row-ownership-2026-11-18.json); [preceding23 native evidence](validation/inventory-tier-bag-native-followup-2026-11-18.json).
<!-- /LHO-VENDOR-ROW-OWNERSHIP-20261118 -->

<!-- LHO-TIER-BAG-COUNT-NATIVE-20261118 -->
18 November08:55UTC passive capture found the verified Forever client still
in world; shutdown warning alone did not prove it unavailable. Normal guarded
own reload then loaded the current23 set. Real five-kind tier queries after
transient query-cache invalidation completed: food19/2.9794ms, water19/2.4582,
bandage20/2.1829, healPotion5/2.6480 and manaPotion5/2.4950. One sample each,
not a matched comparison or FPS/spike gain. No direct item-total parity or
post-reload BugTabs count was read. Public-getter fallback preflight sent NO
input: foreground mode changed before attestation, then same unsent run's fresh
observation aborted on foreground input activity. Wrapper never installed.
That run is terminal; do not replay it. Current23 hashes still match both disk
folders. Two successful runs were freshly viewed/ACKed. Host observers and
shared input lock absent; no jump helper. No items, persistent probe globals,
profiler preferences or external addon code changed. Goal ACTIVE. Next: fresh
readiness/build/errors and normal-vs-fallback actual counts when input is stable;
quantity/zero, populated vendor/craft/pending/bank, legal combos and other-client
native spike acceptance remain open. No further simulations.
[Evidence](validation/inventory-tier-bag-count-view-2026-11-18.json).
<!-- /LHO-TIER-BAG-COUNT-NATIVE-20261118 -->

<!-- LHO-TIER-BAG-COUNT-VIEW-20261118 -->
18 November: checkpointed Index1b74de66, Restock_Inv38db8778 and TierMatch4dea0444
outside AddOns; reverified71d1b554 history bundle and statted125 settings paths.
Added private numeric bag-count view, restock ownership adapter and tier-only
consumer selection. Final Indexf6611444/Restock_Inv4488ee52/TierMatch1a02bc12.
Twelve exact before/after Lua5.1/5.4 syntax checks PASS. Removing additions
restores all three baseline files exactly after newline decoding; fallback and
other bodies unchanged. All23 Retail/Forever source pairs match, no manual
sync. No simulation, new mock test, native input or external-addon edit.
Current process still has preceding21 set until next normal reload. Native
count/override/vendor/bank/crafting and spike checks remain pending.
[Evidence](validation/inventory-tier-bag-count-view-2026-11-18.json).
<!-- /LHO-TIER-BAG-COUNT-VIEW-20261118 -->

<!-- LHO-IDLE-FOLLOWUP-NATIVE-SHUTDOWN-20261118 -->
18 November, before the announced server shutdown: verified new Forever
process42724/window50333792 and retargeted fixed guarded actors to its exact
birth identity. Status read: inventory ready/source syndicator, Syndicator and
Baganator both loaded, item1487 snapshot/native0/0, scriptProfile0, BugTabs0.
Status screenshot was personally viewed after certificate expiry: its journal
remains unacknowledged; no restamping or replay. Three subsequent runs were
freshly viewed and ACKed: idle pending-work0 targets/0.014899969100952ms/errors0,
normal guarded reload with observed loading screen, then actual zero-job
GetBankTargets0 targets/0.02209997177124ms/errors0 after world return.
The pre-reload in-memory source identity is uncertain; these are single smoke
observations, NOT a matched baseline/candidate comparison or FPS/spike gain.
Current21 Retail/Forever disk source pairs were rehashed and all match the
recorded candidate pins. Own reload establishes loading of this disk set;
only the canonical zero-job pending-work call was exercised after reload.
Active jobs and merchant burst/close/cancellation remain PENDING, along with
remaining client/provider and matched frame-spike acceptance. No new runtime
Lua edits, simulations, item transactions, addon toggles or profiler-setting
changes in this slice. No persistent probe globals/hooks were installed.
Stopped game input ahead of shutdown; input lock absent and native observers
absent in host check. No jump helper runs. Goal remains ACTIVE: shutdown is
an external testing interruption, not a user-requested goal pause. After restart,
verify client/window/world, build/providers/settings anew; reinsert only needed
temporary diagnostics because reload reset earlier runtime state.
[Evidence](validation/inventory-idle-followup-native-2026-11-18.json).
<!-- /LHO-IDLE-FOLLOWUP-NATIVE-SHUTDOWN-20261118 -->

<!-- LHO-IDLE-FOLLOWUP-VENDOR-WORKERS-20261118 -->
18 November resumed after user pause/reactivation: host inspection found a NEW
Forever process42724/window50333792, birth134394624880288175, launched09:01:28
CET. Passive capture shows Mario Super38 at Stormwind AH with Auctionator and
Skillet open. No input, reload, addon toggles, profiler changes or item actions
this slice. Old PID26544/window460342 controllers MUST NOT be reused for this
client; prepare and review exact new-target actors before future native input.
All preceding20 runtime hashes were unchanged on resumption. Followupb1488189
is now cfb392c6: F.Refresh creates the three count-memo tables only when a valid
job exists and Build will consume them. Active job Build/memo use and fresh
GetBankTargets return copies remain. VendorUI69bed000 is now f97f0873:
protected cancellation and both debounce callbacks reuse private workers.
Three moved bodies match exactly after indentation normalization. Timer field
clearing, all visibility/tab/burst guards, queries, writes and fallback branches
remain. Delays stay0.2/0.35 seconds for data and0.15 for frame updates.
This removes conditional temporary allocations; no new cache/framework/event
or update delay. Eight before/after Lua5.1/5.4 syntax checks PASS and whitespace
check passes. Current source set now21 files; all Retail/Forever pairs match.
Dated external source/history verified;125 settings paths statted, values not
read/copied. External Syndicator/Baganator code untouched. No simulations or
mock tests. Three callbacks now allocate once at module load rather than at
those scheduling/cancellation sites. Native CPU/FPS/spike gain is UNMEASURED.
Candidate native acceptance is PENDING a normal reload and actual zero-job,
active pending-work and merchant burst/close/cancellation checks. The prior
seven-ladder pass stays evidence for its exact earlier source set; it does not
accept these new followup/vendor workers. New client build/provider flags and
profiling preferences have not been queried; do not carry prior-process values.
Goal ACTIVE. Continue Inventory/EBS lag-spike work with all LHO01-13 requirements
preserved. Avoid interrupting live AH/craft activity; no native input helper or
jump helper is running. Pause promptly if requested and save exact continuity.
[Evidence](validation/inventory-idle-followup-vendor-workers-2026-11-18.json).
<!-- /LHO-IDLE-FOLLOWUP-VENDOR-WORKERS-20261118 -->

<!-- LHO-LADDER-USABILITY-NATIVE-20261118 -->
18 November: guarded own reload now adopted the current20 disk set, including
Best53df5afe, Bridge42366bf9 and List2178f495. Seven actual ladder queries and
selected IDs/counts completed. Inventory ready/source syndicator; both external
addons loaded; item1487 snapshot/native0/0; profile0 and final BugTabs0.
Current top picks: food4599/18, water1645/19, bandage8544/20,
heal3928/5, mana6149/5, healthstone nil, mana gem5513/1. List lengths are
2/1/1/1/1/0/2. Single native ms: food2.0235, water1.2141, bandage0.2829,
heal0.2614, mana0.2335, healthstone0.4280, mana gem0.1869.
A real forwarding checker wrapper activated the compatibility path: success,
four original checker calls for two food candidates, exact function restoration.
A real forwarding tooltip-text wrapper on the normal path recorded two original
tooltip-text calls for two food candidates, success and exact restoration.
No fake API data or simulations; wrappers lived only within one synchronous
command each. These are different call-site counts; source explains their
relationship. Before/after food/water lengths and stock differ, so timings do
NOT establish matched CPU/FPS/frame-spike gain. All seven runs visually ACKed.
An earlier source-only reload preflight terminated because WoW was minimized,
not timer expiry; it sent no command. No window-restoration helper was needed
or implemented: read-only placement inspection later found it already restored.
The actual successful reload was observed; merchant/bags stayed or reappeared,
so the earlier expectation that reload would close vendor is not acceptance.
Agent issued no item-action commands, addon toggles or profiler-setting changes.
All eight current watchdogs absent at01:52:20UTC; input lock absent; both wrappers
restored. Twenty source pairs remain stable. No jump helper runs.
Native test work finished before announced server shutdown (last image8:00).
Current client HAS reloaded: previous temporary globals reset; the new queries
leave no persistent instrumentation. After shutdown, verify exact client/world
again before any input and reinject only necessary temporary diagnostics.
Goal ACTIVE. Next native scope: unchanged-stock paired costs/spikes, combo-food
kind/fallback-cache paths, C1/C2 with these identities, retained vendor quantity
changes and craft routes, plus bank/mail/AH/pending/craft and other clients.
List2178f495 is loaded but its crafting-row optimization remains separately
unaccepted; ladder smoke cannot prove that vendor/craft path.
[Evidence](validation/inventory-ladder-usability-native-2026-11-18.json).
<!-- /LHO-LADDER-USABILITY-NATIVE-20261118 -->

<!-- LHO-LADDER-USABILITY-PASS-20261118 -->
18 November: native seven real ladder queries measured food4.8051ms,
water3.7481, bandage1.2613, healPotion1.1158, manaPotion1.1464,
healthstone0.8998 and managem0.1975; lengths3/2/1/1/1/0/2. One sample each,
not a latency distribution. Source tracing shows Best.GetLadder and its immediate
binding filter both call tooltip-based IsBlockedForBest for the same candidate.
Best123a8f7d -> 53df5afe and Bridgeb9f20c0f -> 42366bf9 now share approvals
only for exact fresh records within that call. The addon-private namespace owns
the helper; the public GetLadder signature/result stays. Replaced Best getter or
named Score/checker dependencies use original checks. Combo food with a different
kind is rechecked; ordinary ladder-cache hits keep full live usability filtering.
Live bag/charge counts, stale/login fallbacks, fresh outputs, retries, settings,
commands, timers and update cadence remain. No across-call usability cache.
Eight before/after Lua5.1/5.4 syntax checks PASS; 20 Retail/Forever disk pairs
match. External source/history verified;125 settings paths statted, no values.
Native AFTER is NOT RUN: reload preflight stopped on physical key/activity;
a fresh preflight then found the client non-drawable before creating a run.
No reload command entered, no temporary globals reset, no game-item actions or
profiler changes. Both finished watchdogs absent; input lock absent. Previous
native timings/combination checks do not accept these new Lua identities.
Goal ACTIVE. Next when drawable/idle: guarded normal reload, then candidate
seven-kind IDs/counts/timing and combo/fallback/overridden-checker validation.
List2178f495 also remains pending reload/vendor/craft-route acceptance.
Other full-goal bank/mail/AH/pending/craft/quantity-change/client and FPS/spike
requirements stay open. No new simulations or mock tests. No jump helper runs.
[Evidence](validation/inventory-ladder-usability-pass-2026-11-18.json).
<!-- /LHO-LADDER-USABILITY-PASS-20261118 -->

<!-- LHO-VENDOR-COUNT-ROW-COPIES-20261118 -->
18 November: List 1586463f -> 2178f495 limits count-refresh row copies to rows
with craftBaseTarget (including zero). A fresh bases array still contains every
row in the same order. Ordinary rows are borrowed read-only by the canonical
GetVendorCraftTargets consumer, which already copies before SetItemUnits/Need
or DirectItems; crafting rows retain the original full shallow copy and target
rebase. The crafting getter still runs once, including mail/settings/invalid-plan
side effects. Counts, bank rules, fields, timers, rendering and transactions stay.
This removes one temporary row table and one field traversal per ordinary row;
CPU/FPS/spike gain is UNMEASURED. No skipped crafting validation or new cache.
Before/after Lua 5.1/5.4 syntax PASS (four checks); 20 Retail/Forever source pairs
match. External source/history checkpoint verified; 125 settings paths statted
without reading values. No simulations, benchmarks, native input or external
addon edits this slice. Current WoW still has preceding List1586463f loaded;
its earlier seven-row 3.0051ms/zero-error smoke is baseline evidence ONLY.
Native acceptance after a normal reload remains PENDING, including active and
removed craft routes. Preserve present vendor context; no reload this slice.
Empty merchant-list rebuild lead remains UNAPPLIED: do not cache unresolved
empty results without proving metadata/stock membership invalidation.
Goal ACTIVE; continue Inventory/EBS Lua optimization and native quantity-change,
vendor/button/cost, craft, AH/pending, bank/mail and other-client checks.
Original addon flags/effective filter remain restored; no jump helper runs.
[Evidence](validation/inventory-vendor-count-row-copies-2026-11-18.json).
<!-- /LHO-VENDOR-COUNT-ROW-COPIES-20261118 -->

<!-- LHO-NATIVE-COMBOS-VENDOR-20261118 -->
18 November: current20 C1 Syndicator-only and C2 built-in actual bag open/close
checks PASS: ready true, food 42/42, profile 0, BugTabs 0. All 12 runs viewed
and acknowledged; original GUID/account enable states 2/2 for both external
addons restored and verified. With the earlier both-addon check, all three legal
combinations now have current-source bag UI lifecycle coverage, not mutation or
whole-workflow acceptance. External addon sources were not edited.
User then opened Helenia Olden with Shift and left Restock visible. The real
empty panel refresh completed in 0.10749995708466 ms; temporarily showing unsold
rows exposed five tier plus two item rows. A real populated refresh completed in
3.0051000118256 ms, with the same displayed counts and BugTabs 0. This accepts
the repaired local renderer call on actual populated data; stable quantities do
not prove bag-change propagation. These are different-scenario single candidate
samples, NOT a before/after comparison or FPS/spike gain. The original unchecked
view filter is restored. No targets or transactions changed; raw nil/false
SavedVariables representation was not captured, so byte identity is not claimed.
All 16 finished watchdogs absent on host check 01:01:39 UTC; input lock absent,
foreign halt retained. No runtime edits, new simulations, item actions or profiler
changes in these slices. All 20 current Retail/Forever disk source pairs match.
Goal ACTIVE. Next: real retained-tier bag quantity changes/zero and bank-included
counts; vendor button/cost, AH, pending, craft, mail and other-client native
checks remain open. Do not reload/toggle addons for the present vendor context.
No jump helper runs. Stop promptly on pause and save continuity before pausing.
[Combo evidence](validation/inventory-native-bag-combos-2026-11-18.json);
[vendor evidence](validation/inventory-native-vendor-refresh-2026-11-18.json).
<!-- /LHO-NATIVE-COMBOS-VENDOR-20261118 -->

<!-- LHO-NATIVE-BAG-LIFECYCLE-20261118 -->
18 November: current 20-file disk set is stable across a guarded Forever
reload. Readiness/source true/syndicator, both external addons loaded, food
42/42, profile 0. Actual Baganator bag open and final toggle-close were observed;
BugTabs 0 throughout the queried points. CloseAllBags printed successfully but
left the bag visible even later: NOT accepted as close. Read-only Baganator
source identifies ToggleAllBags as its normal toggle; a fresh distinct action
closed it. Original closed-bag state restored. Four accepted runs plus one
unaccepted close receipt retained; all five watchdogs exited; input lock absent.
No items moved/used/bought/sold/deleted, simulations, profiling or runtime edits
this slice. External Syndicator 37 / Baganator 157 sources remain unchanged.
This establishes current startup and one both-addon bag UI lifecycle only;
merchant count/name changes and actual spikes are NOT accepted by this smoke.
Full-build bank-query shortcut remains unapplied because raw rows/query behavior
would change. Vendor unavailable at tailor; optional question remains pending.
Goal ACTIVE. Next: current-source C1/C2 real bag lifecycle, then available native
vendor/bank/mail/AH/craft scenarios; preserve original addon enable states after
any combo test. No jump helper runs; pause promptly when requested.
[Evidence](validation/inventory-native-bag-lifecycle-2026-11-18.json).
<!-- /LHO-NATIVE-BAG-LIFECYCLE-20261118 -->

<!-- LHO-VENDOR-TIER-COUNTS-20261118 -->
18 November: List 1586463f fixes stale tier counts in retained merchant rows.
BuildTierEntry creates tier rows without itemID; the count-only cache updater
previously updated only itemID rows. Panel and merchant button data updates
could therefore render/use previous tier quantities. The updater now calls the
existing Tiers.GetTierCount with the current merchant index and refreshes the
count-bank flag. It queries bank counts only when bank inclusion is enabled.
This intentionally adds necessary reads; positive counts use the existing tier
cache and cold/zero metadata still retries. No new timer/cache or timing change.
Item rows, row identity, targets, list membership, availability fields and
purchase validation remain. It is a correctness fix, not a measured speed win.
Lua 5.1/5.4 syntax and whitespace pass; all 20 current Retail/Forever source
pairs match. External source/history checkpoint and 125 settings metadata paths
verified. No simulations/benchmarks/native input this slice. Actual vendor bag
updates, zero/depletion, included-bank and button/cost checks remain PENDING.
This resolves the preceding source lead; other clients/workflows and native
FPS/lag-spike gain remain OPEN. Goal ACTIVE; continue inventory Lua work.
Vendor availability question remains optional/pending. No jump helper runs.
[Evidence](validation/inventory-vendor-tier-counts-2026-11-18.json).
<!-- /LHO-VENDOR-TIER-COUNTS-20261118 -->

<!-- LHO-VENDOR-PANEL-REFRESH-20261118 -->
18 November: vendor Restock panel count refresh now captures the local renderer.
Compiler evidence changes GETGLOBAL RefreshScrollList to GETUPVAL; the old call
preceded the local declaration and could call nil when shown with cached rows.
Private tab-selection and bag-debounce callbacks are reused at their original
zero/0.2/0.35-second delays. Item rows pass complete, freshly read metadata into
the existing name formatter, avoiding a second lookup in the canonical path.
Missing data still retries; existing formatter callers retain their old call.
No across-frame metadata cache, visual-write removal, purchase/settings change.
Final Panel e42f40bf / ItemDisplay 8399fc26 pass Lua 5.1/5.4 syntax; final local
binding verified. Twenty current Retail/Forever source pairs match; external
Syndicator 37 / Baganator 157 source files are unchanged. Source/history and
125 settings metadata paths verified. No simulations, benchmarks or native input
this slice; last native reload accepted the preceding 18-file set only.
Actual shown vendor-panel bag updates/rendering and FPS/spike gains are pending.
Goal ACTIVE. Vendor availability requested asynchronously; continue independent
Inventory/EBS edits. Additional source lead: count-only cache refresh skips tier
rows; validate/fix live tier count propagation next. Original addon setup retained;
no jump helper runs. Never infer new-source acceptance from earlier warm smoke.
[Binding and callback evidence](validation/inventory-vendor-panel-refresh-2026-11-18.json);
[metadata reuse evidence](validation/inventory-vendor-name-metadata-2026-11-18.json).
<!-- /LHO-VENDOR-PANEL-REFRESH-20261118 -->

<!-- LHO-SCAN-PRIVATE-WORKERS-20261118 -->
18 November: Scan 0f73c69e reuses its private recursive publication walker
with fresh traversal/snapshot maps, constant mana-gem order and resume-ticker
body. Live reads, retries, cancellation, 1.5-second ticker and scan timing remain.
Lua 5.1/5.4 syntax and whitespace pass; 18 Retail/Forever disk pairs are stable.
After guarded reload, Forever 70938/16001 with both addons reports ready=true,
food 42/42 and all seven lengths/top IDs/counts unchanged; BugTabs 0, profile 0.
All three native runs were viewed/acknowledged; watchdogs exited, lock absent.
No new simulations or benchmarks. This smoke does not isolate the recursive
walker/ticker branch or prove FPS/CPU/lag-spike gains. Earlier C1/C2 checks precede
this helper edit. Other clients and bank/vendor/AH/mail/craft acceptance stay open.
Dated external source/history and 125 settings metadata paths verified.
Original addons remain loaded; no jump helper runs. Goal ACTIVE. Next work stays
on Inventory/EBS Lua using existing evidence. Latest world-refresh banner was
four minutes; reverify the exact client/world before further native input.
[Evidence](validation/inventory-scan-private-workers-2026-11-18.json).
<!-- /LHO-SCAN-PRIVATE-WORKERS-20261118 -->

<!-- LHO-PROVIDER-COMBOS-20261118 -->
18 November: the current 18-file source set passed scoped Forever 70938/16001
readiness, food-count and seven-kind top-selection checks with Syndicator only,
neither external addon, and restored Syndicator+Baganator. All returned food
42/42, the same seven lengths/top IDs/counts, profile 0 and BugTabs 0.
Both original GUID/account enable states 2/2 and loaded=true were restored.
An initial name-key toggle did not unload Baganator; excluded from C1 coverage.
Pinned Blizzard AddonList identifies UnitGUID as the in-game character key.
All 12 successful runs were personally viewed and promptly acknowledged;
watchdogs exited, input lock absent. External Syndicator 37 and Baganator 157
source files remained byte-identical. No new simulations or timing trials.
This covers warm state and top selections, not full ladders, bag mutations in
each combo, FPS/spike improvement, other clients or commerce/bank/mail workflows.
No jump helper runs. Goal ACTIVE. This evidence precedes Scan private-worker edit.
[Evidence](validation/inventory-provider-combos-2026-11-18.json).
<!-- /LHO-PROVIDER-COMBOS-20261118 -->

<!-- LHO-SCAN-RESOLVED-IDS-NATIVE-20261117 -->
17 November: Scanc88a6e83 native repeat PASS for the reproduced duplicate
candidate case. Before: rawfood1487appeared twice/count20 after real creation;
livebridgecount28. After guarded reload and same cast workflow:28to42food,
raw1487once/count42;bridge/snapshot/nativeall42;4599/18and4601/1unchanged.
BugTabs0;Syndicator+Baganatortrue.2syntax passes;18disk pairs stable. All8native
runs personally viewed/promptly ACKed;8watchdogs host-verified absent22:47:37UTC;
input lock absent;foreign halt retained. No simulations/benchmarks/profiler changes.
This is one correctness pair at different stock totals, NOT FPS/CPU/spike gain
or all-client/workflow acceptance. Initial food4to3comparison remains not full
parity; later raw duplicate was reproduced and intentionally fixed. Other contexts
and provider combinations remain OPEN;goalACTIVE. No jump host runs. Final
screen had server world refresh4minutes;verify scene/process before next input.
[Complete before/after evidence](validation/inventory-scan-resolved-ids-2026-11-17.json).
<!-- /LHO-SCAN-RESOLVED-IDS-NATIVE-20261117 -->

<!-- LHO-SCAN-RESOLVED-IDS-20261117 -->
17 November: real18file reload/ladder comparison found foodlength4to3 while
all7topIDs/counts and other lengths matched. Readiness/profile/errors:true/0/0.
Real repeated Conjure Food created14more (28total): raw1487twice/count20;
live bridge1487once/count28. Current duplicate scan path is natively reproduced;
initial pre4fullIDs were not captured, so do not call original full parity PASS.
Applied Scanc88a6e83: per-scan successful-ID set behind existing SameOwners;
7callers skip repeated resolved work, unresolved retries unchanged; budgets now
serve distinct ready candidates. No across-frame cache or timer/cadence change.
2syntax/whitespace checks pass;18current sources/Forever pair match. Native FIX
still PENDING reload/repeat; CPU/FPS/spike benefit unmeasured. No simulations.
Goal ACTIVE; continue immediate native repeat;retain source and all5ACKjournals.
[Evidence](validation/inventory-scan-resolved-ids-2026-11-17.json).
<!-- /LHO-SCAN-RESOLVED-IDS-20261117 -->

<!-- LHO-LADDER-CACHE-QUERY-20261117 -->
17 November: Index1b74de66 and ConsumableBindb9f20c0f defer the canonical
whole-bag record builder until an existing fallback ladder cache misses. Valid
hits keep FilterLiveOwned live count/charge/usability reads and fresh results.
Private source-owner metadata admits only unchanged facade/index/generation
methods; replacements/legacy paths retain original eager queries and type gate.
Cache keys/generation tests, complete ladders, events/timers/UI remain.4syntax
passes and whitespace checks pass; current direct set18. P83 remains rejected;
no first-result shortcut or count-flag candidate was applied. Source tradeoff:
ownership checks versus discarded record allocations; actual CPU/FPS/spike gain
and native cache-route behavior remain PENDING. Previous17file real cast/receipt
smoke is dated and does not accept this new pair. No new simulation/native input;
no jump host. Goal ACTIVE; next verify loaded18files and actual grid/cache paths.
[Evidence](validation/inventory-ladder-cache-query-2026-11-17.json).
<!-- /LHO-LADDER-CACHE-QUERY-20261117 -->

<!-- LHO-NATIVE-CAST-RECEIVE-20261117 -->
17 November: current17source disk pairs verified; entered selected Mario Super
on Forever70938/16001 and observed world/startup. Source syndicator/readytrue;
profile0;Syndicator+Baganatortrue. Real Conjure Food6129 native3s cast cancelled
early: castingnil;bagGen6unchanged;BugTabs0. One completed cast created14
Pumpernickel1487;bagGen6to8;selector1487/count14;actual native and Flux counts14/14.
Initial probes used wrongfood1114; retain their0reads as irrelevant to1487,
not an initial1487baseline. All5runs personally viewed and promptly ACKed;
5watchdogPIDs host-verified absent;input lock absent;foreign halt retained.
No simulations/benchmarks, purchase/sale/delete, profiling changes or new Lua
globals. No jump host runs. This is scoped correctness smoke, NOT measured FPS/
lag-spike gain or acceptance of parse-budget/AH/modern-bank branches/all clients.
Goal ACTIVE; broader workflows and legal provider combinations remain OPEN.
[Evidence](validation/inventory-native-cast-receive-2026-11-17.json).
<!-- /LHO-NATIVE-CAST-RECEIVE-20261117 -->

<!-- LHO-AUCTION-REFRESH-NEEDS-20261117 -->
17 November: Auction controller5eab7dfd now reuses final row.need within two
synchronous refresh paths after GetRows(true), including material target updates.
This removes duplicate A.Need stock/tier/mail/pending calculations in Advance
and the offered-item refresh check. Purchase/reservation/asynchronous/click-time
live validation remains. No result survives a refresh boundary via this change.
Lua5.1/5.4 syntax and diff whitespace checks pass. Other16direct source pins
remain stable; current set17. No simulations, benchmarks, native input or jump
host this slice. Real auction workflow, client/provider parity and lag-spike
benefit remain OPEN; prior15file smoke does not accept this17source set.
Goal ACTIVE; continue direct Inventory/EBS work and eventual native verification.
[Evidence](validation/inventory-auction-refresh-needs-2026-11-17.json).
<!-- /LHO-AUCTION-REFRESH-NEEDS-20261117 -->

<!-- LHO-CLASSIFY-BUDGET-LOADS-20261117 -->
17 November: Classify92954c18 skips its explicit metadata request when the
tooltip parse budget is spent and ItemClass already reports metadata loaded.
Pending state, budget, retries and timers remain; unknown metadata still requests.
This addresses a source-visible unnecessary request/invalidation path; P85/P87
repeated-scan observations do not prove this branch caused their native cost.
Lua5.1/5.4 syntax pass. No new simulation, benchmark, native input or jump helper.
Other15direct sources stable; current16-file record updated. Prior native smoke
does not accept this changed classifier. Actual lag-spike gain/client/provider
and full workflow acceptance remain OPEN; goal ACTIVE. Keep direct edits going;
do not blindly change pending-read retry caps or stale-mail measure-first.
[Evidence](validation/inventory-classify-budget-loads-2026-11-17.json).
<!-- /LHO-CLASSIFY-BUDGET-LOADS-20261117 -->

<!-- LHO-JUNK-OVERLAY-WORKERS-20261117 -->
17 November: applied direct junk-overlay callback reuse in bag enumeration and
dirty/full modern-bank paint paths. Overlaya26645f6 passes Lua5.1/5.4 syntax.
Original loops, per-frame duplicate checks, paint flags, protected boundaries and
cadence remain. Three private load-time workers replace repeated callback
construction; CPU/FPS/lag-spike benefit and native behavior are unmeasured.
Previous15direct sources remain stable; current direct set now16files.
No simulations, benchmarks or native input this slice; no jump host running.
Continue direct Inventory/EBS work; stale-mail remains measure-first and
external Syndicator/Baganator remain untouched. Whole goal ACTIVE.
[Evidence](validation/inventory-junk-overlay-workers-2026-11-17.json).
<!-- /LHO-JUNK-OVERLAY-WORKERS-20261117 -->

<!-- LHO-NATIVE-DIRECT-SMOKE-20261117 -->
17 November: progressed to real-client verification. Verified exact Forever
process26544/window460342/birth; passively captured world. Repinned existing
fixed-command guards, preserving serialization/fast commit/focus/pause controls.
Native pre-read ready/source/profile succeeded. Rechecked15Retail/Forever pairs,
ran30syntax-only compiles, performed guarded reload and observed loading/world
return +2settings writes at21:16:03UTC. Post-read70938/16001;Syndicator+Baganator;
ready/profiletrue/0. BugGrabber read had no marker; inspected actual BugTabs API,
read current captured count0. Real bag queries showed50IDs/0key mismatches.
Late keys formal ACK failed120s age guard; preserved refusal and observed image,
with no restamp/replay. Six watchdog PIDs absent; leases released; foreign halt
unchanged. No item/cast/jump actions, profiler change, simulation or benchmark.
[Native scope and receipts](validation/inventory-native-direct-smoke-2026-11-17.json).
<!-- /LHO-NATIVE-DIRECT-SMOKE-20261117 -->

<!-- LHO-POTION-PATTERN-SETUP-20261117 -->
17 November: found per-line fixed range-pattern string assembly in PotionMinimum
and per-call generic unit/pattern setup. Applied private prepared patterns while
retaining matches/order/math/native queries and fresh outputs. Exact external
source/history and125settings metadata availability verified.2syntax-only51/54
compiles pass;15current direct file hashes stable. No simulations/native work
or performance measurements; fixed-storage/startup tradeoff recorded.
[Evidence](validation/inventory-potion-pattern-setup-2026-11-17.json).
<!-- /LHO-POTION-PATTERN-SETUP-20261117 -->

<!-- LHO-CLASSIFY-RESULT-PROFESSION-WORKERS-20261117 -->
17 November: inspected parser/extra-button consumers. Applied two private
classification result workers and one reusable queued profession refresh callback.
First source-edit guard expected7potion callers but found8 and stopped before
addon writes; corrected after source inspection. Actual8potion/2food-water
callers updated; result bodies/queries/branches/freshness remain. Timer source
inspected read-only.2files pass4syntax compiles; zero new simulations/benchmarks/
native actions. Updated15current direct source hashes and scoped continuity.
[Exact evidence](validation/inventory-classify-result-workers-2026-11-17.json).
<!-- /LHO-CLASSIFY-RESULT-PROFESSION-WORKERS-20261117 -->

<!-- LHO-CAST-BAG-AUCTION-WORKERS-20261117 -->
17 November: previous goal turn made runtime/continuity progress. Inspected
mail/provider notifications and successful-cast matching. Read-only elevated host
enumeration found ForeverPID26544; no game window/input inspected. Preserved
foreign INPUT_HALTED and current native-owner reports. Applied3fixed cast helpers,
shared bag flush callback and static auction flush callback after reviewing
Scheduler's occurrence-based queue/reentry behavior. No mail data logic changed.
Exact source/history and125settings metadata availability checkpoint retained.
2files/4syntax-only compiles pass. Consolidated14current direct-edit hashes and
dated syntax provenance without rerunning simulations or claiming native gain.
[Record](validation/inventory-cast-bag-auction-workers-2026-11-17.json).
<!-- /LHO-CAST-BAG-AUCTION-WORKERS-20261117 -->

<!-- LHO-FOLLOWUP-COUNT-WORKERS-20261117 -->
17 November: inspected vendor/AH/pending/bank/queue paths against actual TOC.
Bank mover is already hidden idle; old FluxInv heavy queue is unloaded. Applied
existing carried-count query reuse in Followup.Count and craft fallback
BagOperations, preserving lookup/short-circuit order and original optional query
priority. Hoisted bank snapshot slot comparator with unchanged numeric reads/ties.
External source/history/125path settings availability checkpoint verified.
All3changed files pass6syntax-only compiles. No new tests/models/benchmarks,
native commands, item actions or preference changes. Current gain unmeasured.
[Exact before/after and open scope](validation/inventory-followup-count-workers-2026-11-17.json).
<!-- /LHO-FOLLOWUP-COUNT-WORKERS-20261117 -->

<!-- LHO-KEYS-ONLY-CONSUMERS-20261117 -->
17 November: audited all unique-record consumers in Inventory/EBS. Applied
trusted ID-only query reuse in Scan.Recompute's bags query, Craft.ReagentItemID's
missing-ID name search and Best.Init.UniqueBagCount. Same query options, public
override paths, key loops, native name reads, reagent mutation and login/scan
timing remain. Reviewed TOC ordering and current Index helper source. Full-record
bank/equipment/tier consumers were retained.3files pass6syntax-only compiles;
no new models, benchmarks, native commands or item operations ran. Fresh external
source/history/settings-availability checkpoints retain before/after identities.
[Record](validation/inventory-keys-only-consumers-2026-11-17.json).
<!-- /LHO-KEYS-ONLY-CONSUMERS-20261117 -->

<!-- LHO-DIRECT-INVENTORY-RESUME-20261117 -->
17 November: resumed the inventory goal, verified six saved source hashes plus
the external history bundle and125 available settings paths (metadata only).
Released only exact owned pause controls. Applied Index normalized scalar flags,
private default reuse and explicit-callback walkers; applied RestockList fixed
charge-tooltip workers/getters. Preserved fresh rows, current callbacks, dynamic
snapshot/native reads, protection, caches and cadence. Corrected an intermediate
Index line-ending conversion before validation; original LF is retained.
Reviewed the saved commodity/tooltip/reagent diffs and closed their ledger backlog.
Seven exact current files pass14 syntax-only51/54 compiles. No addon chunk,
simulation, benchmark, reload or native input ran. In-game/performance acceptance
remains open; prior native spans do not measure these edits.
[Evidence](validation/inventory-direct-resume-2026-11-17.json).
<!-- /LHO-DIRECT-INVENTORY-RESUME-20261117 -->

<!-- LHO-USER-PAUSE-20261117-1305 -->
17 November: user stopped simulations and requested direct inventory Lua edits.
Applied private tooltip patterns, inventory output workers, profession fallback,
commodity comparator, tooltip comparators and protected spell-reagent workers.
Source/history checkpoints and settings availability were recorded externally;
twelve syntax-only compiles passed. No native gain is claimed. At the user's
complete-pause request, stopped all own jobs, retained pause flags, issued one
guarded reload and observed world return plus13:05:16 UTC settings writes.
A subsequent blank-chat preparation sent no input and was released. Saved all
six source files externally and the exact resume state; late ledger entries
remain explicitly pending for continuation.
[Paused state](validation/inventory-pause-2026-11-17.json).
<!-- /LHO-USER-PAUSE-20261117-1305 -->

<!-- STANCE-PORTRAIT-BACKDROP-CONTACT-20261117 -->
17 November: user clarified vertical gap with stance present. Fresh external
source/history/settings-metadata checkpoint precedes stance edit. Corrected one
portrait fill anchor and attached stance backdrop endpoint. Six scripts pass;
new2208checks/288contact scenes plus26496portrait checks. Corrected fixture native
SetPoint replacement; initial duplicate-anchor failure retained. Archived stance
and prior one-unit fill fail actual coverage. Four compiles;90 runtime prototypes
max9. Core/Shared/Layout unchanged; no native action/performance claim.
[Evidence](validation/stance-portrait-backdrop-contact-2026-11-17.json).
<!-- /STANCE-PORTRAIT-BACKDROP-CONTACT-20261117 -->

<!-- PORTRAIT-BACKDROP-GAP-20261117 -->
17 November: verified a fresh external source/history checkpoint and eight
on-disk settings metadata records. User narrowed the crop to the player portrait
backdrop. Border/Shared now prepare one straight interior fill texture before
first paint.17 source scripts pass; new final regression26496checks/288scenes
plus30816 existing geometry assertions. Archived Shared fails actual interior
coverage. Three scoped compiles and448 runtime prototypes/max20 pass. No Core
edit, native input/reload/capture or profiler write; visual acceptance pending.
[Evidence](validation/portrait-backdrop-gap-2026-11-17.json).
<!-- /PORTRAIT-BACKDROP-GAP-20261117 -->

<!-- TOT-NPC-SECRET-COLORS-20261117 -->
17 November: after verified external source/history and settings-metadata
checkpoint, changed Core/Border/Shared for NPC Default and native-only ToT class
paint. Added two actual-source regressions; updated old NPC/name fixture policy.
Broad76 passed before final Shared name pacing/publicOnly refinement; final9 and
7 compiles pass with stable hashes.636 prototypes/max56. Retained meaningful
old-renderer/old-NPC-policy/missing-name-paint rejections plus initial fixture
and predicate failures. No native reload, capture, input or profiler change.
[Evidence](validation/tot-npc-secret-colors-2026-11-17.json).
<!-- /TOT-NPC-SECRET-COLORS-20261117 -->

<!-- RANK-CACHE-BUILD-COST-R65-20261117 -->
17 November R65: after the dated rank-cost source/history checkpoint and four
MAIN-only settings metadata records, added bounded timing around existing rank
cache builds. Frozen SpellRankcfc560a5 descends from exact7ed2a24d; testc7ac1432.
Removing diagnostic helpers, two hooks and version marker recovers the preimage.
Actual70scenes/545new plus224existing checks pass on each Lua5.1.5/5.4.6; four
compiles pass, source85prototypes/max12/13upvalues.

The optional summary records completed builds only in the same active owned
watch. No parse cache, skipped metadata query or rank-cadence change. OFF has
one protected Lua Capture lookup per existing build, no native clock/privacy/
table/per-icon work. Active observer overhead remains; reported ms includes the
ending owner check and excludes WatchStatus/final publication. Metadata errors
still propagate; diagnostic failures drop only optional records. Native combined
adoption waits for mini-frame READY and cooperative foreign-marker cleanup.
No new native action or CPU/FPS claim; CF64 and R63 histories remain unchanged.
[Exact source and validation](validation/rank-cache-build-cost-r65-2026-11-17.json).
<!-- /RANK-CACHE-BUILD-COST-R65-20261117 -->

<!-- MINI-UNIT-FIT-COLORS-20261117 -->
17 November: after fresh external source/history/settings-metadata verification,
applied mini profile/inset and owner-color changes. Source-art probe supports
3/3/5/5 inside both rounded contours. Fixed ToT inheritance of natural material
and parent class; included constructor, preview, Appearance and pet-cast consumers.
Partial-source fixtures now load actual new dependencies/signature; their failed
receipts remain. Scoped static/paint/color tests pass; no native operations or
CPU benchmark were performed. Core and Bars remain unchanged by this slice.
[Exact sources and checks](validation/mini-unit-fit-colors-2026-11-17.json).
<!-- /MINI-UNIT-FIT-COLORS-20261117 -->

<!-- COMBAT-CF64-20261117 -->
17 November: Root ran the main-only native CF64 watch while the user reproduced
combat lag, then retained/flushed it. A strict data-only main-root extraction
passed18 literal controls; raw settings/diagnostics remain external. The report
shows31 gaps/3 callbacks,16 entries/16 exits sampled, and25/17ms worst next-driver
gaps. These do not measure handler CPU or exclude deferred combat work.

Deferred border105.5655ms and enclosing flush105.6152ms overlap. Build105.5446ms
includes mesh prepare8.8707/draw15.2004; usability listener14.6901ms is separate.
The815ms gap remains UNATTRIBUTED; its nearest application/addon/Flux tick is
815/19.1767/18.5329ms. Ring retains20of31; the border peak context is lost.
CF64 deep retention passes. Original `CF62hold.old`7-gap/2-callback report stays
retained; prepared restoration was not executed under the main foreground guard.
No own lease remains, no profiler preference write, errors0start/end, Bank0.
Exact loaded Core bytes and newer-source native acceptance remain unknown;
R63 rejection and other-owner content are preserved. This entry edits docs only.
[Sanitized evidence and ownership limits](validation/combat-cf64-2026-11-17.json).
<!-- /COMBAT-CF64-20261117 -->

<!-- CAST-UNIT-JUNCTIONS-20261117 -->
17 November: verified external source/history/settings metadata checkpoints,
then applied scoped optional-unit preparation and glow clip fitting. Initial
59-script gate found seven regressions; corrected synthetic-cell accounting and
source-specific fixture semantics without raising limits. Added eligibility guard
after reproduced foreign-profile double blending. Final59/59 pass with stable
pins;357 optional and342 cost checks pass. Syntax13/prototypes463/max56 pass.
All failed raw receipts remain.

Read collaboration note and added requested existing reason/count fields without
new native reads/traversal. No native input, reload or profiling was performed.
[Exact changes and evidence](validation/cast-unit-junctions-2026-11-17.json).
<!-- /CAST-UNIT-JUNCTIONS-20261117 -->

<!-- LHO-RUNTIME-P92-P94-20261117 -->
17 November: after dated external source/history checkpoints and 125 known
settings-path metadata checks, applied P92 private pattern prebuild, P93 two
GetUniqueItems worker hoists and P94 First Aid fallback hoist. Independent
P93/P94 source reconstruction preserves fresh output/state and live query order.
All six syntax checks passed; no addon chunk ran for those checks. Preserved
P92's successful partial pattern traces, subsequent host-decoding failure and
baseline-fixture _ENV failure; the complete functional batch did not pass.
P93's prewrite Python syntax failure is retained. User stopped remaining
simulation/timing work; no cost batch or new native action followed. Root's
Retail/Forever disk match is not loaded-source proof. P91 stays stopped.
[Exact receipts](validation/inventory-runtime-p92-p94-2026-11-17.json).
<!-- /LHO-RUNTIME-P92-P94-20261117 -->

<!-- LHO-CLASSIFY-PARSER-LINE-P90-20261117 -->
17 November: Root verified the dated ed64/history/settings-metadata checkpoint;
Hook applied the four inverse edits under Root authorization/checkpoint GO,
yielding Classify f441813c. Added actual-owner parser test6ee9cc32; no metadata/
native query, cache, retry or cadence change.
Independent source review reconstituted exact ed64 and checked private callers/
percent-pattern necessity.

First baseline10 and candidate12 jobs all exited0/reaped/stderr empty,1,346
assertions each; two candidate compiles. Per VM:56parser/510potion/29owned/39+39
provider-pending. All8 full result vectors and four retained test stdout pairs
match; fresh results/axes preserved. Fourteen lines reduce Normalize70->14 and
percent-worker42->12 entries, with no timing/byte measurement.

This documentation task rehashed44 raw logs, ran no tests/native actions and
preserved other-chat/P88/P89 bytes. P90 loaded adoption/native gain remain pending.
[P90 source and exact evidence](validation/classify-parser-line-work-p90-2026-11-17.json).
<!-- /LHO-CLASSIFY-PARSER-LINE-P90-20261117 -->

<!-- LHO-INVENTORY-NATIVE-SCAN-P88-20261117 -->
17 November: P88 stage/arm/read/clean received Root timely ACKs:73/73/73 calls,
650.01569991ms inclusive sum/21.199100010563ms max over30.017s, Best9792->9865,
bags85->85, fault0/CLEAN true3. No gain or item/cast attribution claimed.

Root later ACKed P89P pending-added/load0/0; P89F four false raw/time components,
raw ready true/source syndicator; P89A three addons loaded/profile0. Aggregated
soft hold/private reliability UNQUERIED; later context is not retroactive.
BG6 recorded three advancing-green background samples at1890x993/y982 after
user AH close; no keys/chat or host launch.

RootF_RELEASED11:22:29UTC exact cf0a87d/08b104, archived externally; input.lock
absent/HALT6990 retained, native operations terminal. This file-only followup
preserves prior evidence/shared ownership. Classify NormalizeLine/percent guard
is planned/test-before-edit, not applied/native accepted by this record.
[P88 source and P89 followup evidence](validation/inventory-native-scan-p88-2026-11-17.json).
<!-- /LHO-INVENTORY-NATIVE-SCAN-P88-20261117 -->

<!-- LHO-INVENTORY-EVENT-WORKERS-20261117 -->
17 November: applied Init field-list reuse/absent-set traversal, two Professions workers,
two Restock bank workers and EBS batch/Legacy worker reuse after scoped recovery
checks. EBS tests first reproduced skipped count-only work, then the reverse-order
texture gap. Both were repaired; missing fixture UpdateUsable and an unsupported
ForceRefresh/RefSpells expectation were corrected with all failed receipts kept.

Final targeted totals: Init168 assertions/2 compiles with independent paired peer,
Professions2,806/2, Restock6,836/2, EBS148/4. Init includes baseline/installed pairs.
No new native performance result is claimed. This update changes documentation
only and preserves earlier/other-chat records; loaded-source validation remains
pending and the goal ACTIVE.
[Current source and evidence](validation/inventory-event-workers-2026-11-17.json).
<!-- /LHO-INVENTORY-EVENT-WORKERS-20261117 -->

<!-- LHO-PENDING-READ-RUNTIME-20261117 -->
17 November: applied the direct Best facade/Scan and classifier revision changes
after the external source/history/settings checkpoint. Source peer findings led
to IsReady/Score replacement guards, published-table mutation detection and
ordinary self-followup reasons. The durable pending-read test covers late
metadata, real inventory changes, public mutation and stopped read demand.
ItemClass's private tooltip worker passed its existing 29-check test per VM.

Root's final stable-source run passed 28 jobs, 22,400 assertions and eight
compiles; logs were independently rehashed. This documentation update changes
no runtime source, settings or native controls. Native adoption and wider LHO
acceptance remain pending. [Exact record](validation/consumable-pending-read-runtime-2026-11-17.json).

Supplemental built-in/Syndicator coverage passed four runs of 39 checks. The
first provider attempt's Lua51 fixture-loader failure remains recorded; only
the test-local portable load adapter changed before these supplemental runs.
<!-- /LHO-PENDING-READ-RUNTIME-20261117 -->

<!-- FALLBACK-INPUT-WORK-R63-20261117 -->
17 November R63: after the external recovery/settings checkpoint, trialled
scalar fallback inputs directly in addon Lua, then the combined private append
edit. Focused42,524checks perVM passed; scalar514scripts/1204syntax is a
historical mixed-snapshot pass with an unrelated Scan.lua change.

BOTH trials are REJECTED/REMOVED: combined24of48cost cells failed Lua54 warm
CPU+8.143%; scalar6of48failed Lua51 coldCPU+9.677%. Raw samples, allocation
savings, regressions and counter evidence remain. At07:17:21UTC Root restored
exact Core4fa7c12a/LF110827 and array testad065, preserving OtherE790 and other
owners' work. The later main-only reload and CF62/CF64 watches use that baseline;
CF64 was reported armed at07:34:09UTC, with retention/results pending. No R63
native adoption, combat/FPS gain or Bank action is claimed.
[Exact sources, failed gates and restoration](validation/fallback-input-work-r63-2026-11-17.json).
<!-- /FALLBACK-INPUT-WORK-R63-20261117 -->

<!-- LHO-ITEM-HELPER-ADOPTION-20261117 -->
17 November: Root applied Item870e at06:17:54 and added durable test530b after
its exact external bytes passed. This new engineering adoption uses functional/
quiet parity, bounded allocation evidence and qualified warm-route CPU-3.100775%.
The original28-job experiment remains INCONCLUSIVE with three sub128-tick direct
profiles; prior HOLD is historical. No user-approved precision waiver, all-FIT,
retiming or nativeFPS claim.

Focused installed checks passed14 jobs:9,868 assertions plus4 compiles, pins stable/
children reaped. Only product owner Core/API/Item.lua changed; Other e790 stayed.
Checkpointb830, fresh125settings metadata/history verification and Item-before
restore remain. GC184B/direct savings retain boot+125/+104B qualifiers.

Root reports Retail/Forever disk Item870e, without manualsync/reload or loaded-byte
proof; native adoption remains pending. P87's native getter counts/strict cleanup
and R1FAIL/R2proof remain unchanged. C3864 is active as a dated Root report,
not a liveness or movement observation. Goal ACTIVE; P83 remains REJECTED. Next
retry work must preserve late metadata, callbacks and cadence; broader workflow/
client acceptance remains pending.
[Adoption decision and limits](validation/item-count-helper-adoption-2026-11-17.json).
<!-- /LHO-ITEM-HELPER-ADOPTION-20261117 -->

<!-- LHO-BEST-REASON-ITEM-HELPER-P87-20261117 -->
17 November: P87 native recorded 1,466 requests and74 completed scans
(getBest38/getLadder36), generation+74 with bag13 unchanged. Root ACKed both pages
and CLEANtrue3. No native private-attempt, actual-duration, CPU/FPS or loaded-byte proof.

R1 first51 failed only the Scan33=33 aggregate oracle;54 unrun. R2 actual-owner
replay passed277checks/VM, preserving late-metadata recovery asymmetry. Item helper
functional24contexts/VM and quiet232checks/VM passed. All28 cost jobs completed,
but three direct profiles missed128ticks: precision HOLD/UNAPPLIED, not a CPU veto.
Warm CPU median4031.25->3906.25(-3.100775%) retains one-tick loss warning; GC184B/
direct-call savings and boot+125/+104B cannot waive precision. No rerun/retune.

Root launched C3864 at06:04:27 after B's600s-heartbeat stop; first injected pair
06:04:30.327-.383 has no movement proof. Cue/idle/chat/craft/stop guards remain.
Checkpointb830 covers four disk sources only. Goal ACTIVE; P83 remains REJECTED;
no product Lua/adoption. Retry design must preserve fresh metadata, callbacks and
current cadence. Broader workflow/client acceptance remains pending.
[Evidence and remaining scope](validation/inventory-best-reasons-p87-2026-11-17.json).
<!-- /LHO-BEST-REASON-ITEM-HELPER-P87-20261117 -->

<!-- LHO-P84-P85-NATIVE-WORKFLOW-20261117 -->
17 November: Root accepted P84 passive30.0099s and P85 mixed120.0192s native windows on Forever70938/Syndicator. P84 had no cast/bag events, stable bagGeneration8 and Best73 spans (561.038ms/max21.023ms); its Food27to41 was outside. P85 had one player SUCCEEDED, nine cast/bag stamps and the automatic+2s typed Food41to55 state, bagGeneration10to13. All six report pages and CLEANtrue3 were personally viewed/formally ACKed for both captures.

P85 inclusive totals: provider3/0.2088ms; Notify3/3.2080ms; Best.Scan296/2292.8931ms(max21.8516); EBS eval173/194.3774ms; counts3/0.7576ms; Bars132/272.1369ms. All eight retained slow-ring spans are Scan, with three overwritten; cumulative post counters include pre-cast passive work. These are instrumented overlapping elapsed spans, not exclusive Food CPU, FPS causality or a matched comparison. P86 does not expose private retry state; the getter-feedback cause remains unconfirmed.

Goal ACTIVE. P85 first2 combined jobs passed31body/1272 plus14protocol/1511checks perVM; its label-only route copy stays UNRUN. Item.GetCount first2 actual-owner baseline jobs passed8direct groups plus2partial-route pairs/VM; Helper identity counts do not measure allocated bytes or CPU. No optimization is applied. Next: bounded reason-enum trace plus actual Scan/Classify/ItemClass retry reproduction, preserving queries/cadence. P83 stays REJECTED/UNAPPLIED; no addon Lua changed in this slice. Root reports holds released/jumps resumed, without current liveness/movement proof. Broader client/provider/workflows remain open; stale-mail USER-MEASURE-FIRST, commerce simulation only, guild/void excluded.
[Native records, exact limits and next causal gate](validation/inventory-native-workflow-p84-p85-2026-11-17.json).
<!-- /LHO-P84-P85-NATIVE-WORKFLOW-20261117 -->

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

<!-- LHO-WORKFLOW-DIAGNOSTIC-P84-20261117 -->
17 November: P84 is EXTERNAL/PREPARED. The six-envelope body passed31mock cases/1,272checks perVM (54pins). Actual builtin/Syndicator routes passedR1 two pairs/four contexts/62checks perVM; R2 adds the missing direct observer-row proof:88checks perVM/130pins, current and automaticpost entered=completed=valid [1,1,1,0,1,0]. Same-VM selected query/callback order and state match. R1 raw cross-VM listener-order/metadata-overassert history stays preserved; no model rerun.

Root formally ACKed dated P84CTX: Forever1.60.1/70938/16001, Syndicator ready, Food Button table, both selected roots absent. This was one pure253-character status command; NO P84 OBSERVER TYPED and NO FOOD ACTOR as of that snapshot. Root archived/released its short CTX holds and reports helperB5872 resumed; INPUT_HALTED remains. This is readiness, not native event delivery, loaded body adoption or FPS. Existing jump launch/history is unchanged and was not inspected by this draft.

Goal ACTIVE; P83 stays REJECTED/UNAPPLIED and ConsumableBind7d758903 is unchanged. Native protocol proof is pending. Count tracing covers first3 native arguments only; full EBS/Bars eval dispatch, private heavy queue and upstream Syndicator remain unqualified. [Evidence and pending native gate](validation/inventory-workflow-diagnostic-p84-2026-11-17.json).
<!-- /LHO-WORKFLOW-DIAGNOSTIC-P84-20261117 -->

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


<!-- LHO-NATIVE-PAINT-P83-COST-20261117 -->
17 November: P83 is REJECTED/UNAPPLIED; ConsumableBind remains7d758903. The fixed28-child/four-profile batch supersedes the22-child proposal: retained-zero CPU796.875→875ms (+9.8039%,2of3pairs slower) rejects despite other wins and64B/unit51/56B54 transient-GC savings. R3 admissions passed500checks/VM; R1 startup-timer and R2 depletion-to-nil setup failures remain preserved. All raw regressions, intercepts and retention deltas are linked below; no retiming or P83 runtime application.

Root accepted passive30.018s and separate120.016s leaf windows. The latter contained Food caststart; orange bread/A-D showed13 before/active and27 in the first later image AFTER expiry. Displaydelta14 proves no exact item/produced quantity or in-window finish. Late actor ACK remained STALE/false; no recast/restamp. Both captures have formal cleanup. Inclusive overlapping spans prove no matched gain, exclusive Food cost, loaded-byte adoption or FPS result.

Goal ACTIVE: prioritize whole cast/craft/bag→EBS/Bars and restock workflows plus provider/client/bank/mail gaps. PaintOne/CountOne is an unbuilt one-closure-per-PASS lead, not per widget; extra arguments can regressCPU. Preserve stale-mail USER-MEASURE-FIRST, simulation-only commerce and guild/void exclusion.
[Exact costs, native limits and corrected chronology](validation/inventory-native-paint-count-cost-2026-11-17.json).
<!-- /LHO-NATIVE-PAINT-P83-COST-20261117 -->

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


<!-- LHO-EBS-COUNT-OPTIONS-P82-P83-20261117 -->
17 November: goal ACTIVE. P82 baselined the actual loaded ConsumableBind owner in8 contexts/216checks per stock51/54 VM. P83 remains EXTERNAL/UNAPPLIED with cost pending: its private options/freeze scalar change passed8paired contexts/440checks per VM and12unchanged consumer runs. Each baseline/candidate VM has5,059 consumer checks; complete same-VM outputs match. The focused public/state/error/flag traces match, including actual bag-event→Inventory.Notify→light listener delivery, face/hold/reliability ordering, opaque errors and reentry.

Ten private default constructions become zero in the focused protocol; eight supplied private tables are harness inputs, not eight claimed production allocations. All27escaping public option tables per variant remain fresh. Constructor counts establish no heap/CPU/FPS gain. The fixed22-child CPU/GC proposal is accepted for source preparation only; no cost batch or addon Lua application has occurred.

Root observed F81A readiness on Forever1.60.1/70938 with _FluxUI, Syndicator and Baganator loaded. This is readiness only, not exact loaded-source adoption or performance acceptance. Root owns native and separate jump receipts. The full LHO01–13 goal/native gaps remain open, including representative cast/craft/bag whole-event attribution, restock lifecycle, provider/bank/mail and requested client expansion.
[Exact proof, private/public limits and remaining coverage](validation/inventory-count-options-2026-11-17.json).
<!-- /LHO-EBS-COUNT-OPTIONS-P82-P83-20261117 -->


<!-- CAST-DIVIDER-FLARE-20261117 -->
17 November (`CAST-DIVIDER-FLARE-20261117`): shared non-pet cast fill/trough extends two UI units farther under the icon divider to cover the native rounded leading cap; cast, swing/Shoot and flight labels keep their prior positions and time spacing. Profession fill and wide flare now share the existing progress mask. No added mask, region or driver; header/icon/pet geometry, recipe classification, timers, prepared layout and green success remain. Fourteen focused scripts pass, including archived-source negatives; seven syntax checks and 286 compiler prototypes pass (maximum 52 upvalues). New Mooncloth and ordinary-cast visual comparison after reload is pending. Broader performance work remains open. [Requirements](UNIT_OVERLAY_ATTACHMENTS.md#leading-edge-and-crafting-flare-follow-up) and [evidence](validation/cast-divider-flare-2026-11-17.json).
<!-- /CAST-DIVIDER-FLARE-20261117 -->

<!-- PARTY-BORDER-WORK-20261117 -->
17 November (`PARTY-BORDER-WORK-20261117`): removed unnecessary geometry scans on visibility/alpha changes to the unit-only raid container, and duplicate header positioning before the existing secure layout. Full roster data refresh, secure execution, paint and focus notifications remain. All 13 focused scripts pass, including 164 container checks across eight paired scenes and 5,428 roster checks. Syntax and upvalue checks pass (92 RaidLayout prototypes, maximum 16 upvalues); the earlier accepted UI sources are unchanged.

In the model, each container visibility transition drops from one wake/read/alignment to zero; neither version solves unchanged geometry. Prepared header clear/set pairs drop from 18 to 9, and width writes from two to one. Partial execution failures retain fallback/retry, with documented differences in hidden intermediate poses. The adjacency-cache prototype remains unapplied because it slows genuinely changed layouts. Native party join/leave hitch feedback is pending. [Requirements](PARTY_BORDER_PERFORMANCE.md) and [source/evidence](validation/party-border-work-2026-11-17.json).
<!-- /PARTY-BORDER-WORK-20261117 -->


<!-- UNIT-OVERLAYS-ACTIVE-CASTS-20261116 -->
17 November (`UNIT-OVERLAYS-ACTIVE-CASTS-20261116`, started16November): mini pet/target-of-target/party-pet borders now meet their parent portrait without moving bodies or merging unit scopes. Five-piece open frames retain outside-cap ownership; detached scales and private-width/setter retry cache repaired. Known crafting uses normal chrome and public icon fallback; two-pixel cast core fit both styles and green success retained.25 unique focused scripts PASS, including218,107 attachment checks/216 main scenes and786 crafting checks;868 owned runtime compiler prototypes/max55 upvalues. User after reload confirmed “Connections look right” and “Crafting and fit look right”. No FPS/taint, exhaustive client/state or full contact shadow-partition claim. [Requirements](UNIT_OVERLAY_ATTACHMENTS.md) and [exact source/proof](validation/unit-overlays-active-casts-2026-11-16.json).
<!-- /UNIT-OVERLAYS-ACTIVE-CASTS-20261116 -->


<!-- LHO-BURST-BASELINES-P77-P78-P80-20261116 -->
16 November: goal ACTIVE. User permission for in-game testing is restored; Root alone owns fresh guarded inspection/input. Status attempts A-D entered no command; later E also stopped before input when foreground became unknown. The A-D receipt stays historical; no fresh loaded-status, client-exit or native performance result is inferred.

P77 public AH reuse traces match for two N1/N25 cycles (7/103 forced builds;19/5,551 modeled item calls per cycle). Its fixed16 desktop cost gate passed: CPU medians-9.375%/-0.6024%, the latter one15.625ms tick. N25 pair2 +31.25msCPU/+62mswall, N1 pair3 +16mswall, positive GC slopes and prepared retention+3642B51/+2967B54 remain recorded. This is whole-child modeled CPU/GC, not native FPS or event-exclusive CPU.

P78's corrected9case/281check baseline per VM distinguishes9GetRows calls from1forced rebuild. The second resolver observes later metadata, public-list edits and raw errors; blind skipping is unsafe. Earlier fixture/metric failures stay preserved; no candidate.

P80 passed functional and corrected quiet admission proofs, then failed its fixed34job cost gate: small-lifecycle median is flat but2/3 CPU pairs are slower. Distributed/warm wins cannot override it. Cold GC/retention increases and no-pending wall+13.13% remain visible. Candidatefba020 remains external/unapplied; actual Init98d3 and applied Index80acf are unchanged. No addon Lua changed in this slice. Keep this rejected candidate unapplied; investigate the next distinct lead with tests first.
[Exact evidence, regressions and scope](validation/inventory-burst-baselines-2026-11-16.json).
<!-- /LHO-BURST-BASELINES-P77-P78-P80-20261116 -->

<!-- RESPEC-ACTION-SAFETY-20261116 -->
16 November (`RESPEC-ACTION-SAFETY-20261116`): explicit native bar slots now save/load on Retail, Forever and Classic after talents. Failed reads, pickup/no-cursor, malformed snapshots, active loads and player drags cannot become destructive empty restores. Stable flyout/macro/mount/set/outfit routes and legacy missing-stance preservation are covered. Auto-rank now verifies the exact spell cursor and destination before advancing saved IDs; binder opening preserves the native account/character set and unsaved keys. Frozen 14 scripts on each Lua5.1/5.4 PASS (28 runs); 18 owned syntax results and 611 compiler prototypes/max25 captures PASS. Native operation/taint/controller/persistence/FPS remain pending. Reload then re-save old Retail/Forever profiles to capture bars; previous snapshots contain stance only. [Requirements, exact sources, checkpoint, regressions and pending checks](validation/respec-action-safety-2026-11-16.json).
<!-- /RESPEC-ACTION-SAFETY-20261116 -->


<!-- CAST-GREEN-FINISH-20261116 -->
16 November (`CAST-GREEN-FINISH-20261116`): successful unit casts now finish plain green, including school/profession casts, using the existing .35 hold/.75 fade. Completed protected casts clear red chrome/shield; active cues and failure feedback remain. Only FluxCastBar.lua changes at runtime; native-nameplate theme Finish stays with its owner. User reloaded and confirmed “Green finish looks right”. The general in-game testing hold was explicitly lifted during this task; background/no foreground or gameplay control rules remain. Twelve focused offline scripts PASS (including9,973 terminal checks); 13 scoped syntax checks and147 compiler prototypes/max33 captures PASS; no FPS/taint or automated native test claim. [Requirements and exact scoped evidence](validation/cast-green-finish-2026-11-16.json).
<!-- /CAST-GREEN-FINISH-20261116 -->


<!-- USER-NATIVE-TESTING-RESUMED-20261116 -->
16 November: the user explicitly permitted in-game testing when needed ("we can test ingame now if needed"). This permission supersedes historical hold notices below. Root alone owns native inspection/input and must freshly verify the exact client, world/chat state and ownership guards. Buying, selling, deleting and mail actions remain forbidden. Existing jump/chat/crafting locks remain until Root explicitly releases the suitable ones for the current runner. No client presence, loaded-source adoption or performance acceptance is established by this permission.
<!-- /USER-NATIVE-TESTING-RESUMED-20261116 -->

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

<!-- USER-NATIVE-TEST-HOLD-20261116 -->
Historical general testing hold: the user explicitly lifted it later on 16 November (“we can test ingame now if needed”). Relevant UI tests may resume; preserve background operation and separate input/gameplay restrictions. Earlier evidence collected under the hold remains offline-only. See CAST-GREEN-FINISH-20261116 above.
<!-- /USER-NATIVE-TEST-HOLD-20261116 -->

<!-- CAST-COMPLETION-20261116 -->
16 November (`CAST-COMPLETION-20261116`): completed modern unit-frame casts use a quiet plain muted-gold fill instead of the bright patterned full success atlas. Classic green, active casts, channels finishing empty, .35hold/.75fade, interrupts, school/profession overlays, rapid recast and header/swing release remain. Eleven focused scripts PASS, including12,535 new lifecycle/appearance assertions across150 consumer/client scenes; owned compiler146prototypes/max33 captures. No geometry/topology, settings, localization, input, new timer/driver or native operation. All in-game testing remains deferred by the user. [Exact sources and scoped validation](validation/cast-completion-2026-11-16.json).
<!-- /CAST-COMPLETION-20261116 -->


<!-- BORDER-JUNCTION-SHADOWS-R56-20261116 -->
16 November junction shadows (`BORDER-JUNCTION-SHADOWS-R56-20261116`): `shadow-support-r56` restores the measured source shadow footprint in all four T directions and X, both styles, including aura/retained-strip joins. Current interval keepers are suppressed once; exact current-material/UV guards and committed support snapshots preserve static natural/tint/RGB paint. 486,467 shadow checks/56 scenes/240,576 footprint samples and 111,147 material checks PASS. Final 147 focused scripts/1,190 composed syntax checks PASS; two runtime files/235 compiler prototypes, maximum54 captures; Lua stable during the gate. Earlier fixture failures and alpha-gradient/field-count costs are retained. Native pixels, perceptual smoothness, taint and FPS remain deferred by the user; CB-36 broader reflow latency stays open. [Exact sources, proof and limits](validation/junction-shadows-2026-11-16.json).
R56 post-gate continuity: a later parallel portrait-only Shared change is preserved. Twenty affected scripts, fresh Shared syntax and381 compiler prototypes/max20 captures PASS with Shared/Core/Border stable. The original147-script source-frozen gate and this later scoped replay remain separate evidence. Later unrelated tests receive syntax checks only; exact composition is in the R56 record. Native testing stays deferred.
<!-- /BORDER-JUNCTION-SHADOWS-R56-20261116 -->


<!-- LHO-INVENTORY-PRIVATE-CALLBACKS-20261116 -->
16 November: P75/P76 are applied after offline behavior and fixed-cost gates. USER native hold remains: no game tests, input, queries, captures, jumps or reloads until explicit release. Goal ACTIVE for offline work.

Only two private callbacks changed: slot validation reuses its protected numeric body; inventory change merging reuses its union helper. All validations, native/query reads, fresh maps, callbacks, repaint work and update cadence remain. Twelve first functional jobs passed: P75 32paired/235checks per VM plus unchanged65check visible-bag regression B/C; P76 8groups/45checks per VM plus unchanged263check passive-inventory regression B/C. Existing same-VM output is byte-identical.

Fixed44cost jobs passed with80pins stable and all children reaped. Whole-child stock51 CPU medians: slot valid-50%,nil-58.14%,throw-29.41%; merge countOnly-25%,mixed-15.38%. Populated identity is+4.545%(2slower/1faster), retained below its declared5% rejection gate. Paired allocation savings136B/slot check and40B/merge hold at both1000/2000 windows on51/54. Shared54 first-window floors and retained startup increases(+148/+150B slot,+91/+62B merge) stay recorded. These are conditional leaf models, not native FPS or whole-workflow timing.

The addon source files now match the exact tested candidates; no client reload/input, temporary code, settings, external addon edit, manual sync or publication occurred. Loaded adoption and other installations were not checked. Native/whole-client acceptance remains pending. [Exact sources, all samples, contract boundaries and regressions](validation/inventory-private-callbacks-2026-11-16.json).
<!-- /LHO-INVENTORY-PRIVATE-CALLBACKS-20261116 -->

<!-- LHO-AUCTION-CLOSED-DEFINER-P73-P74-20261116 -->
16 November (`LHO-AUCTION-CLOSED-DEFINER-P73-P74-20261116`): USER HOLD: no in-game tests, live queries/testing captures, game input, jumps or reloads until the user explicitly permits them. Offline goal ACTIVE; generic continuation or offline success never releases this hold.

P74 applied the three tested Retail files at19:46:44UTC. The later19:52:16UTC read-only check matched all15 files across five primary installs; other folders have independent identities and updated externally between observations. Propagation mechanism is unproved; Root performed no manual sync. Loaded-client adoption remains unverified. Extra beta is unchanged/older and not certified. Focused16/683 per VM, four whole-row pairs per VM(51:10,646checks;54:10,346) and16 unchanged regression jobs passed. New fixed cost16jobs found owned CPU median-11.5385%(3wins), foreign+4.1667%(2one-tick losses/1win), below its declared rejection gate. Qualified GC savings retain startup+3842B51/+3167B54 and observed54intercepts; no native/full-workflow CPU or FPS gain is proved. P73 retained its12context negative baseline. Preapply recovery verified three source restores, existing dated source/history archive and125settings metadata entries(4changed), without settings values. Initial application snapshot and later disk observations remain separate; no source undo, extra cost trial or manual sync. [Exact sources, proof and limits](validation/auction-closed-definer-options-2026-11-16.json).
<!-- /LHO-AUCTION-CLOSED-DEFINER-P73-P74-20261116 -->

<!-- ACTION-STRIP-BORDER-R55-20261116 -->
16 November action-strip borders (`ACTION-STRIP-BORDER-R55-20261116`): `strip-updates-r55` skips matching same-occupancy decorative layouts after fresh public native checks and connects the nearby strip/envelope top nodes. Secure mappings,171 cursor flag writes, ForceApply, visibility and real expand/collapse stay. 144 focused scripts PASS;1187 composed syntax PASS;7 runtime files/782 prototypes max54 captures; source stable during gate.157 guard controls;5,798 seam checks/144 scenes/1,080 one-source samples. Extra cut cache REJECTED: actual drag has0 reusable prefixes. Native testing is DEFERRED until explicit user availability; no reload/capture request. [Exact sources, limitations and remaining work](validation/action-strip-borders-2026-11-16.json).

R55 final offline review: the ten paired drag-work states isolate the Strip guard on identical R54 Core. Combined R55 dynamic seam checks cover type 1 occupied/grow/shrink only; the separate 144 static seam scenes cover both styles. All five owned runtime/test hashes remain stable. Documentation generation passed (1,219 sources); its full validator remains pending because three concurrently edited Inventory files made eight unrelated references stale. No inventory edits were overwritten. All owned jobs are stopped; native testing remains deferred.
<!-- /ACTION-STRIP-BORDER-R55-20261116 -->

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
<!-- /GROUP-COMBAT-SPIKES-20261116 -->

<!-- LHO-AUCTION-BASELINES-P70-P72-20261116 -->
16 November (`LHO-AUCTION-BASELINES-P70-P72-20261116`): P70 actual limited-zero UI toggle/reopen each caused six forced builds in modern/legacy N1 models; free owned craft at cap0 remained valid. P70 passed6/131 and P71 passed6/251 per stock51/54 VM, with exactly two first jobs per stage. P72 is REJECTED/UNAPPLIED:12paired scenarios/546checks per VM preserved logical/native traces and opaque-error identity, while generated field/local error wording differs and is retained. Fixed cost16jobs found owned CPU359.375to421.875ms median(+17.3913%),3/3slower, breaching the declared rejection rules; foreign median+4.1667% retains one slower/two ties. Qualified GC savings do not override rejection; startup retained growth was+5973B51/+4998B54. R1 failed path setup before owners/warm/work with zero valid pairs; R2 was an unused byte-exact copy, and R3 changed resolved paths only under the same declaration. No product Lua changed this slice. P67 attempts1g/1h/1i sent zero packets and never staged/armed the observer;1g preinput reason remains unknown,1h was rejected before journal, and1i user logout countdown was left untouched. Goal ACTIVE; own holds remain and any native attempt requires fresh client/world/closed-chat/ownership checks. [Baselines, rejection and native limits](validation/auction-limit-live-options-2026-11-16.json).
<!-- /LHO-AUCTION-BASELINES-P70-P72-20261116 -->

<!-- BORDER-EVENT-REFLOW-R54-20261116 -->
16 November event reflow (`BORDER-EVENT-REFLOW-R54-20261116`): `event-reflow-r54` reuses bounded current observer pairs, skips identical PUBLIC direct-alpha derived work, avoids matching native shell rewrites and redundant roster-driven focus partition/outer passes. Changed/private/unknown/pending/direct-settings paths, source suppression, notifications and rollback remain. 129 focused scripts PASS;1182 composed syntax PASS (29 fresh);5 runtime files/717 prototypes max54 captures; source stable during gate. Model pet exits120 shell setters become0 with40 paints retained;20 prepared roster events20 full focus partitions become0 with20 default notifications retained. Native combat-exit and join/leave latency/pixels/taint acceptance is PENDING. [Exact sources, work tax and remaining checks](validation/border-event-reflow-2026-11-16.json).
<!-- /BORDER-EVENT-REFLOW-R54-20261116 -->

<!-- BORDER-BUILDER-R53-20261116 -->
16 November border builder (`BORDER-BUILDER-R53-20261116`): `local-plans-r53` reuses unchanged immutable fallback plans, uses per-pass solver identity keys, and reuses complete public unit-owner walks only inside the existing readonly commit phase. Fresh source/geometry/private/native-field checks, paint, budgets and atomic rollback remain.95 focused scripts PASS;1170 composed syntax PASS;3 owned runtime files/608 prototypes max54 captures; no source changes during gate. Native R52 minimap toggle with side buttons still costs232.41ms (solve50.60/plan88.94/commit73.45); R53 native timing is PENDING. Modeled work reductions and staged CPU samples are not native speedup. Actionstrip mappings/seam changes remain held. [Evidence, tradeoffs and native check](validation/border-builder-2026-11-16.json).
<!-- /BORDER-BUILDER-R53-20261116 -->

<!-- LHO-BARS-USABLE-CLOSURE-P69-20261116 -->
16 November P69 (`LHO-BARS-USABLE-CLOSURE-P69-20261116`) APPLIED at17:27:37UTC: `Bars/Paint.lua`7b6273f replaces the per-eligible-host usable-paint closure with one private helper; three call sites preserve queries, captured palette/charge state, features and cadence. Pipeline6cases/642checks per VM matched36,072 paired scalar fields total; focused16/361 each VM and existing54stress86,872checks per source passed. Read-only postcheck matched11expected pins and5installed file identities; loaded-client adoption remains pending.

Modeled leaf whole-child CPU medians improved19.0476% (one host) and13.6364% (57 hosts). Empty/OOR CPU medians tied; wall medians regressed10.6383%/5.6391%, including empty pair3CPU+31.25ms. All pairs remain recorded. GC slopes51:200to0 and54:192to0B/call retain the qualified128B54window floor. The R1before-work harness failure is preserved. No native FPS/spike/retained-heap/full-workflow gain is proved; five model labels/providers were distributed, not a native factorial. P67 remains prepared and never installed natively; the goal stays ACTIVE. [Exact proof, all costs/regressions and remaining native limits](validation/bars-usable-closure-2026-11-16.json).
<!-- /LHO-BARS-USABLE-CLOSURE-P69-20261116 -->

<!-- WORLD-MAP-ANCHOR-20261117 -->
17 November (`WORLD-MAP-ANCHOR-20261117`): reopened missing original-map content despite
Map Pins enabled. Live root kept the saved `BOTTOMLEFT:UIParent:16,374` anchor
outside the Flux clip. Anchor-only candidate814ae567 passed22,168 isolated
checks per VM but still failed natively: actual WindowMover SetPoint/SetScale
posthooks synchronously reapplied saved/session WorldMap coordinates. Surface
now exposes exact preparation/embedded layout ownership; mover yields at its
apply/layout/input gates and cancels active gestures before saving temporary
host geometry. Full-map moving and saved records remain owned by the mover.
Actual root/scroll anchor validation and coalesced native reflow recovery remain;
no polling, pin work or new driver. Scoped22,168 surface +315 actual map/mover
checks pass per Lua5.1/5.4; exact old Engine rejects. Normal mover220 checks and
character-combat smoke pass;4 owned files compile on both VMs;130 runtime
prototypes/max25 captures pass. Current sources stayed stable and both installed
copies match read-only. Earlier scene/opacity confirmations and historical478
scripts remain scoped to their earlier sources. Current native reload acceptance
remains pending.
[Sources, regressions and scope](validation/world-map-anchor-recovery-2026-11-17.json).
<!-- /WORLD-MAP-ANCHOR-20261117 -->

16 November original map scene (`WORLD-MAP-SURFACE-20261116`): implemented.
User confirms map fill/addon pins, large-map key open/close, uniform complete-map
scaling including player arrow, and full opacity while moving on the current
Forever client. The original map/canvas/pools/providers/callbacks remain the
source; no addon dependency, adapter list or copied pin/route content. A fixed
normal source viewport and one outer transform preserve all relative sizes.
Native renderer flags change only while hidden; normal full-map geometry,
controls and movement fade return on handoff. Mounted movement fading removes
only this frame from the native service; mapFade/profiler preferences retained.
No added polling, canvas scan or per-frame copy. 11,064 Lua5.1/5.4 scene checks,
1,969 HBD checks and final full478 scripts/1,168 syntax files PASS; Lua corpus
unchanged during full run. Native acceptance covers the stated user scenarios,
not other clients, exhaustive addons, controller, combat/taint, pixels or FPS.
[Requirements](WORLD_MAP_SURFACE.md) and [final evidence](validation/world-map-surface-final-2026-11-16.json).
Documentation refresh found one subsequently changed unrelated Bars/Paint.lua
verification hash;current map files still match the final tested version. That
newer user/parallel work is preserved;the captured full-run pass is not a claim
about its later revision.

<!-- WOWSIM-STOCK-READINESS-20261116 -->
16 November WowSim stock readiness (`WOWSIM-STOCK-READINESS-20261116`): upstream `c854956` was evaluated outside AddOns with Lupa2.8/Pillow12.3 and612 copied source/license files; all18 upstream Git blobs matched. One stock load hit the30s parent bound (30.016s), with no health output. A separate 2M-instruction diagnostic stopped during texture construction at login; this does not establish the timeout cause or an infinite loop.

WowSim is supplementary: meaningful use needs explicit data fixtures/bootstrap compatibility work under the active goal. Empty API defaults, missing XML/security/secret behavior and browser timing provide no native FPS/GC/pixel acceptance. Final P67 R3 body/protocol proofs passed20/106 and14/135 cases/checks per Lua VM; its55-packet package remained prepared, never natively staged or armed in this sealed checkpoint. Delegated keepalive work is separate and pending Root review; no jump outcome is added here. The full Inventory/EBS lag goal remains ACTIVE. [Bounded results, exact proof identities and limits](validation/inventory-native-current-checkpoint-2026-11-16.json).
<!-- /WOWSIM-STOCK-READINESS-20261116 -->

16 November unit-frame exit priority (`COMBAT-TRANSITIONS-20261116` CT15): `static-unit-paint-r52` skips identical PUBLIC derived paint, keeps native source suppression/private opacity forwarding, and chooses final portrait normal/combat paint once while preserving party material classification. 98 unitpaint +3560 producer/100-stage checks;20 focused scripts and5 changed-file syntax PASS; Core max57/SharedParty max20 captures. Model type2 repeated exit2037 derived alpha reads become0; native latency/whole unlocked UpdateOuterBorder geometry/taint/pixels remain PENDING. Actionstrip/seam and local-plan runtime work are held. WowSim was reviewed read-only; missing triangle/UV/security/native-alpha behavior prevents native border/FPS certification. [Evidence and remaining checks](COMBAT_TRANSITION_PERFORMANCE.md).

Earlier implementation checkpoint (superseded by the final native follow-up above):

16 November original World Map surface (`WORLD-MAP-SURFACE-20261116`): user
selected reuse of the original map for universal addon content and shared map
state. Map Pins embeds that root in the battlefield area; no addon-specific
adapters/dependency, copied drawings, canvas scans or new polling. Native large
map gets priority. Exact parent/anchors/scale/order return on release; combat,
occupied native panels and hidden custom owners defer restricted acquisition.
First-show native layout is measured after initialization. Fallback providers
and HBD detach before source Show; stale discovery cannot reacquire over it.
HBD fallback now supports all clients and retains one removal hook per library.
Desktop: 6,616 source/integration +1,969 HBD checks; eight focused scripts PASS;
1,164 syntax files PASS, changed runtime Lua5.1 PASS, sources stable. Full
474 scripts PASS/0 FAIL with unchanged Lua corpus; documentation refreshed. Five root
harmful controls and seven independent controls reject broken ownership/state.
No settings writes, client input or manual installation copy. Native all-client
pixels/input/controller/taint/CPU/FPS remain PENDING, including native open-map
sounds/emote/fade and panel behavior. Earlier native-only and pin-only limits
are superseded. [Requirements and evidence](WORLD_MAP_SURFACE.md).

16 November combat transitions (`COMBAT-TRANSITIONS-20261116`): the expanded
source audit covers101 remaining consumers,36 loaded Bars/EBS consumers and8
Engine/border owners, including raw frames, unit flags and secure visibility
cascades. This is source coverage, not a census of native registered callbacks.
R51 `prepared-guards-r51` is being prepared: aura layout reuse has1702 checks/
14 focused scripts PASS; fresh-state minimap guards have166 checks/18 focused
scripts PASS. Conservative consumable recovery has525 checks/20 focused scripts
PASS: item-attribute writes1190→140 with840 added fresh reads; all140 binding
clears/rebinds remain. These counts do not establish native performance.
Combined R51 validation is474 PASS/0FAIL: the initial474-script sweep had
473 passes and one legacy extractor failure; the corrected fixture and four
bounded replays pass with a stable current manifest. All eight owned runtime
files stayed stable, but an unrelated World Map file and the fixture changed,
so this is not one globally frozen sweep. Syntax:1165 PASS. Global Lua compiler:
690 runtime files/24916 prototypes, max57 upvalues/0fail. Border guard regressions:
31944 checks PASS. R51 native acceptance remains pending.

Quiet R50's actual218.36ms border reflow remains unresolved versus quiet
R49's207.94ms. Reduced setter/dirty counts do not prove native FPS or taint safety.
Keep native captures quiet until all owned CPU/test/docs/validator work finishes.
Existing cadence, full aura refreshes, live native/private checks, secure recovery,
settings and input ownership remain requirements. Source/history checkpoint:
`combat-whole-addon-before-20261116T150228Z`.
[Requirements and findings](COMBAT_TRANSITION_PERFORMANCE.md);
[structured evidence](validation/combat-transitions-2026-11-16.json).

15 November cast-target range (`CAST-RANGE-TARGET-20261115`): plain actions now
range the unit their cast can select, using native helpful/harmful eligibility.
User confirms native unbound Frostbolt button1 follows the selected enemy while
hovering a nearby friendly frame. Full executable macro clauses, explicit
self/focus/mouseover targets and original badge-action clauses supply range;
idle/reverse/tooltip display targets cannot override them. Unknown/inactive
casts clear range. Existing cadence, probe memo, layout, settings and secure
programs retained. New4,288 plain +66 macro +380 integration checks PASS;
final14 scripts/1,104 syntaxPASS stable. Frozen full413/415 before two scoped
fixture/stopmacro refinements; unrelated portrait mock remains. Native broader
coverage/controller/taint/FPS pending. [Requirements and evidence](CAST_RANGE_TARGETING.md).

15 November out-of-range hotkeys (`HOTKEY-RANGE-GLYPHS-20261115`): action bars,
combat/noncombat grids and TrinketMenu now tint both text and mouse/scroll/space
artwork red from existing range results. Original gray/white returns in range;
empty/placeholder binding refresh cannot revive stale red. No added probes,
timers, input/secure changes or settings writes. 1,144 four-surface and951 Bars
checks PASS; archived consumer and five harmful controls fail as expected.
Full411PASS/1unrelatedportraitfixtureFAIL;1,101 syntaxPASS. Final fallback
guards:10 focused scripts and1,101 syntaxPASS with stable sources. Concurrent unrelated
BorderJunctions change prevents frozen whole-corpus acceptance. Native new glyph
rendering/controller/taint/FPS remain pending; earlier Fire Ward cast and modifier
release confirmation remains valid. [Requirements and evidence](HOTKEY_RANGE_GLYPHS.md).

15 November action routing (`ACTION-ROUTING-RELIABILITY-20261115`): native
PreClick proved Shift globals are consumed while the large main already shows66;
old inheritance selected action6. Secure main now publishes its LIVE keyboard
bundle, with independent mouse modifier sets. Native Ctrl-Shift-½ capture selects
macro66 and macro parser reports both despite rawkeysfalse. User confirms:
"Fire Ward casts; icons return correctly." This verifies that reported cast and
release, not all19/pages/clients/taint/controller/FPS. No macro-condition rewrite.

Also corrected mini inverse page updates, temporary fallback overlays, shared-slot
badge prewarm, OOC and late-callback display indexing, held-modifier page bursts,
and hover native/free ownership/reconfigure/retry. New native restricted-builder
regression rejects the intermediate quoted-function error and accepts correction.
Focused:363885modifier;864nativehandler;21532visual;547hover;510badge;25920control
checks PASS. Full408/410 before final control-fixture repair; repaired25920PASS;
one unrelated portrait fixture misses GetUnitClassColor. No settings/action reset,
agent input/focus/profiler operation or manual installation copy. Nine Forever
runtime files match. Native broad acceptance and FPS measurement remain pending.
[Requirements, sources and measured limits](ACTION_ROUTING_RELIABILITY.md).

16 November border work (`CONNECTED-BORDERS-V2-20261115`): frozen runtime
`adaptive-fallback-r50`; dedicated1226 checks/Cost74 PASS. Full467 scripts PASS/
0FAIL and1157 Lua syntax PASS, changedDuringRun=[] stable; global Lua5.1 compiler/
upvalues689 runtime files/24857 prototypes max57/0fail PASS. Existing fixture edit
keeps script/syntax counts the same as R49. R49 flat publication and buckets≤4 stay unchanged;
only queried buckets>4 lazily build texture→b→c lookup. Exact numeric/current-paint/
generation-token/budget guards remain; native coordinates stay fresh, with no
persistent position cache. No solve optimization is implemented.

Unconditional tuple index REJECTED for common CPU+2.75%/+3.23% and publication/
memory regressions. Adaptive connected24/56 proofs retain exact meshes,49/113
publication tables and0 index builds; retained pre-window heap about2.4–2.8KB
higher is not an allocation rate. Three alternating full-generation CPU pairs
(seconds) for24: .555→.495/.488→.514/.485→.480, median+1.43% mixed; for56:
1.269→1.235/1.489→1.347/1.436→1.394, median−6.20%. Dense1024 fullCPU−78.12% and
probes524800→2560 are stress-only; no common/native FPS claim.

Quiet native R50 capture completed: 218.36ms total, including geometry26.03,
solve31.48, plan93.71 and commit66.15ms. The hitch remains unresolved against
quiet R49's207.94ms; these phase readings do not establish FPS or whole-addon
gain. CB36 all-consumer load-ready/warm affected-part acceptance stays OPEN.
R50 full467/1157 stable/global Lua5.1 max57 proof and the earlier native compile
fix remain historical. Source/private/paint guards, combat/dispel preparation,
accepted fits, settings/diagnostics/profiling preferences remain intact.
[Whole-addon continuation](COMBAT_TRANSITION_PERFORMANCE.md) tracks the pending
R51 gate/native checks. External border checkpoint:
border-indexed-fallback-before-20261116T142859Z.


15 November read-only saved-variable follow-up for shared bindings: account/
character current and backup data audited at user request. Nine valid DB3 rows,
seven placements, no structural corruption or saved layout/badge conflict.
Latest SHIFT-½ entry has ShiftCtrl on/ALT off and both regular/hover input off;
it emits no conditional cast. R remains hover-only. Native F maps11 with no
explicit Shift-F override; hidden11/71 profiles match the reproduced source bug.
No settings changes; client action contents/page and loaded state unverified.
[Audit](SHARED_BINDING_MODIFIERS.md#read-only-saved-variable-follow-up).

15 November shared binding modifiers (`SHARED-BINDING-MODIFIERS-20261115`): fixed the
keyboard proxy selector leak across main/mini rows and obsolete live LeftButton
selectors. The saved hidden main11/Shift71/native35 pattern reproduces Shift-F
casting main11 in the linked GitHub version; candidate selects71 and releases
back to11 before display updates. 2,271 focused checks; exact246; three harmful
controls and12 focused scripts PASS. Regular key press OFF still disables that
binding including ALT; profiles/badges/compiler/settings remain unchanged.
The first full sweep400PASS/2FAIL preceded final test refinement and concurrent
changes. Final modifier checks and the bar smoke now PASS; fresh1,092-file
syntax passes. Other full-sweep results remain historical for newer unrelated
sources. Native casting/taint/controller/render/FPS acceptance remains pending;
no client input or manual installation copy. [Requirements and evidence](SHARED_BINDING_MODIFIERS.md).
Initial documentation gate: one unrelated broken CONNECTED_BORDERS link.
Final check also sees newer border source/assets/references, seven concurrent
owner issues total. Task source/test hashes still match; owner files retained.

16 November (`LHO-INVENTORY-NATIVE-CURRENT-20261116`): P54 window/cleanup
`4a7b230f` is accepted; fast package `851b20e5`, nonce `3960591a`, is CONSUMED.
Never replay it after reload; a new capture needs a fresh nonce/package.
Foreground Space pairs finished 10:53:24.500810 and 11:00:33.973756 UTC.
The first cleared AFK; no movement or background-focus restoration was observed.
No executable daemon: current chat agent `addon_combo_protocol` owns guarded
>=180s keepalive with fresh Idle proof, PC-idle >=15s and no craft/chat.
Root must send `NATIVE_CAPTURE_RESERVATION` and await quiescence before any
native input; `CANCEL` / `JUMP_STOP` stop owned work promptly.

On explicit user pause, stop input/jump first; write both stop markers with
exact contents `User requested complete pause before reload`, cancel/reap
owned tests, and preserve owned `no_jump`/`craft_hold`/HALT holds. Reviewed reload
helper `8eb845ff` requires fresh closed-chat/image guards; verify loading,
world entry and the new epoch before marking paused. On continue, temporary
runtime code must be gone; P54 was already CLEAN nil. Never assume probes
active or replay spent packets. The goal is currently ACTIVE.

P57 R1 is REJECTED/unapplied; Followup remains `428d277c`.
Correctness parity and transient allocation savings pass in models; common/default CPU
results reject the prototype. P56 remains rejected. No P57 rerun, new variant
or application is authorized. [Exact current checkpoint](validation/inventory-native-current-checkpoint-2026-11-16.json).

16 November (`LHO-EVAL-FOOD-CURRENT-P62-P66-20261116`): saved P62 diagnostics are historic:
1,665 observed callbacks/four slow rows over14.607s, with12 gaps. Anonymous
eval labels/tokens cannot identify which Bars/EBS/Perf listener was slow.
P65 remains an eight-scenario/54-check-per-VM baseline, not an optimization.

Two current P64 readouts have different counter-table identities and lower
lane/inventory totals at the second read: UNMATCHED GENERATIONS. The interval
is unusable; no subtraction, percentages or gain. P66's one consumed Food cast
did complete, with creation chat and button12. This is functional evidence only.
P63 default/effective SPACE returned JUMP; no actual background jump is proved.

The user answered “Ready in another app” for the20s coordination window;
root refreshed the source after an early mode switch. This grants no future
quiet window. P61/P63/P64/P66 installed no new observer/global/hook/timer;
P67 is external preparation, not natively installed. Root-reported holds remain
exact and input lock absent; background jumping is queued behind commands and
PC-idle rules. Existing pause/reload procedure and P58/P59/P60 remain intact.
The Inventory/EBS goal is ACTIVE; no FPS/frame-spike/source-adoption claim.
[Current evidence and exact limits](validation/inventory-eval-food-current-2026-11-16.json).

16 November P60 snapshot (`LHO-NATIVE-TRINKET-SCAN-P60-20261116`), recorded14:03UTC:
one background current-only pulse printed `P60SCAN 253693.607 0 0.23160001635551`.
Three ordinary direct scans took0.23160001635551ms gross elapsed and reported
zero bagged trinkets; this does not establish empty bags. Root visually attested
the new line against the source image. The255-character packet queued in157ms;
the other foreground window stayed unchanged, own lock auto-released and lease
ended. Only locals/existing scan calls were used; normal cache/metadata effects
remain. No temporary observer/global/hook/timer was installed.

Bag rows, readiness/provider/profiler flags and in-memory source identity were
not queried. Startup is not reload proof. This is neither an actual bag-event
lifecycle nor matched before/after CPU/FPS/frame-spike/taint acceptance.
At this dated snapshot JumpR2b was external/native-pending and keepalive was
foreground-only; background P60 transport does not prove background jumping.
P58/P59 evidence stays separate and the Inventory/EBS goal remains ACTIVE.
[Exact result, provenance and limits](validation/trinket-native-three-scan-2026-11-16.json).

16 November13:21UTC (`LHO-TRINKET-BAG-SCAN-P58-20261116`): P58 is APPLIED;
TrinketMenu `7d8f645c` and regression `8a2d11da` replace private per-slot
location wrappers with scalar maps. All three scans, itemID/count/link reads,
duplicate selection, metadata calls, public caches and foreign fallback remain.
Paired proof:17 scenarios/648 combined checks per VM,34 pairs/4,800 fields. Post-check:
five behavior jobs, four owned syntax jobs and10 read-only disk identities pass.
Captured integration has eight candidate scripts/seven baseline coverage;
earlier missing-reference setup failures and the corrected test observer remain
recorded. No new whole-project full sweep or native adoption is claimed.

One fixed36-CPU/48-GC model batch gives dense32/dense160/duplicate CPU medians
-10.345%/-23.810%/-38.889%, each three paired wins. Growth saves
17,472/94,560/103,488B per pulse. Small1 regresses +1.887% CPU/+2.586% wall;
foreign CPU+4.348% and wall-2.488% remain. Empty/control variation, all raw
pairs and unchanged intercepts are retained. Whole-child setup/warmup,15.625ms
CPU quantization, modeled APIs and one-bag160 stress limit interpretation.
No native FPS/frame-spike/taint gain. P59 row reuse is DEFERRED: public rows,
extra fields and retained references need a separate ownership proof; no candidate
or cost. The Inventory/EBS goal remains ACTIVE.
[Exact sources, controls, checkpoint and limits](validation/trinket-bag-scan-allocation-2026-11-16.json).

16 November (`LHO-PENDING-TASK-COPY-P57-20261116`): P57 R1 is REJECTED and unapplied.
Followup remains `428d277c`; external `b780c478` and comment-only `36e2ade4`
retain the original first-task snapshot and traverse every nonfirst field/key.
Same-VM proof passes 21 contexts per variant/runtime, 66 observation pairs
and 853/850 combined Lua5.1/5.4 checks. Full-debug bytecode matches after the
two inline comments; no product or test Lua was changed.

One fixed 60-child batch records CPU medians +2.326% one output, +7.273% two,
+8.750% vendor and +1.316% ten two-slot outputs. Bank/waiting improve;
wide/busy and raw pairs remain mixed. No-job CPU ties; mail's one-tick result
comes from a path that never reaches task copying. Every wall/CPU sample,
range and pair is retained with 15.625ms process-CPU quantization.

The 32 quiet stopped-GC windows save 0/2,344/21,928/44,824B per refresh for
one/two/ten/wide plans, with unchanged intercepts. These transient savings do
not justify the common/default CPU regressions. Whole-child setup/warmup and
modeled endpoints remain in scope; native FPS, spikes and taint are unproved.
No P57 rerun, new variant or application is authorized. The external durable
source draft is uncompiled/unexecuted. The Inventory/EBS goal remains ACTIVE.
[Exact sources, all ten profiles and limits](validation/pending-task-copy-candidate-2026-11-16.json).

16 November (`LHO-REAGENT-NORMALIZATION-P56-20261116`): P56 R1 is REJECTED,
not applied. SpellReagents remains `754c8530`; the external prototype is
`778dcd49`. Both Lua versions pass 31 contexts / 951 checks per variant.
Paired trace/value proof covers 585 fields per runtime (1,170 total), plus
146 paired name checks. Stress removes 5,082 conversions while retaining
21 harvests and all 2,581 native name reads; no cache or cadence shortcut.

One fixed 54-CPU / 2-GC batch improves ready20 stress by 13.95% CPU / 14.51%
wall, but missing names regress 18.18% / 21.01% and default callers regress
6.67% / 3.46%. Known/small CPU medians tie with two slower pairs each;
empty/merchant controls and every raw pair remain recorded. All paired GC
windows, slopes and intercepts match across nine profiles. There is no
allocation gain. These whole-child desktop models include setup/warmup and
divergent snapshot/native facts; they establish no native FPS or spike gain.
No further P56 tests, durable compile, cost rerun or product application.

P54 now has one accepted 20.009-second instrumented Cast-handler window:
11 valid raw spans and 377 matcher spans. Captured functions/timers were
restored at WINDOW; CLEAN later actually queried `_P54==nil`. ReadClean is
visually verified with its formal host ACK false. These inclusive elapsed
envelopes include diagnostic overhead and overlap; they prove no exclusive
CPU, FPS or P55/P56 gain/adoption. Earlier `c05ffe3c` failures remain history.
The Inventory/EBS goal is ACTIVE; preserve newer border/UI work and earlier
applied slices.
[Exact sources, all nine raw profiles and limits](validation/reagent-normalization-candidate-2026-11-16.json).

16 November 08:24:40 UTC (`LHO-SYNDICATOR-BANK-ROW-REUSE-P55-20261116`):
Containers d043cfe0, Adapter 66b85fd5 and durable test fc8d5790 are APPLIED.
Partial character-bank updates reuse unchanged normalized rows only with the
exact canonical owner/helper. Foreign exposure disables reuse until reload;
late replacement detaches shared rows before the original public lookup/call.
Native reads, callbacks, errors, notification/persistence and cadence remain.

One stock Lua 5.1 batch gives whole-child CPU medians -12.61%/-14.29% for98rows
unchanged/one changed, with transient slopes reduced21,952/21,728B per callback.
All-changed CPU is+0.67% (all three pairs slower); revoked fallback is+2.50%.
Small8 saves1,792B/callback but its second CPU pair is slower. Foreign timing is
mixed; the unchanged full route's large first-pair variation is not a gain claim.
Raw pairs/wall results, equal control/lateN1 allocations and15.625ms CPU quantum
remain recorded. These modeled whole-child results include setup and warmup.

The fresh2,925-file archive and verified parent history cover restoration;
125settings metadata entries were available without reading/copying values.
Two-layout tests pass90cases/2,160 comparisons per runtime; durable32checks
and harmful controls pass. Captured component8scripts/37,612checks and1,121
syntax pass; actual postapply5/847, owned51/54syntax and15disk identities pass.
The359-file component is exact; no new current whole-project full sweep ran.
P52 history and unrelated work remain. Native P55 adoption, bank frame spikes,
pixels/taint and FPS remain pending. P54 Food/cancel smoke is separate evidence;
no observer installation follows. The full Inventory/EBS goal stays ACTIVE.
[Sources, controls and pending native checks](validation/syndicator-bank-row-reuse-2026-11-16.json).

16 November 06:25:40 UTC (`LHO-SYNDICATOR-PARTIAL-OLDROWS-20261116`):
Adapter 8ce1a745 and durable test 702faa13 are APPLIED. Partial Syndicator bag/
bank rebuilds capture first aggregate presence in the existing subtraction pass,
removing one old-row walk while retaining native reads, results, public callbacks and cadence.
One stock Lua 5.1 batch models whole-pipeline CPU medians -6.67%/-8.11%/-9.00%
for bag32/bank98/bags160. All five allocation slopes are unchanged. Keep the
full-bank control's pair2 +4.7619% CPU/+3.9989% wall and foreign CPU ties visible;
15.625 ms process-CPU quantization, setup and modeled endpoints limit the result.

The 06:00 source/history checkpoint and 06:20 delta addendum verified 125 settings
metadata entries without copying values. Frozen full421/1110 remains dated.
The current captured component passed10 scripts/81,363 checks plus1,111 syntax;
postapply actual default-CWD4/815, owned5.1/5.4 syntax and10 disk hashes pass.
Only the357-pin P52 component is exact; newer unrelated UI changes are preserved.
There is no current whole-project full PASS or native adoption/FPS/spike claim.

The old client40032 and jumper33168 are gone. Current Forever PID46260/window
600248958 has birth FILETIME134392816726299937, build70938/interface16001.
P54N1 queued170 characters and produced a NEW readiness/absence print with
scriptProfile0/source syndicator/ready true and _R53/_P54 absent. Formal ACK
failed the120s age guard: a separate manual observation preserves it, without
restamping or replay. At that earlier checkpoint P54 packets were frozen; no observer/Food action had run.
User says the other WoW test finished/chat is free; guarded root-owned input
continues. no_jump/craft_hold/INPUT_HALTED stay held; no real jump is claimed.
At that earlier checkpoint P55 bank-row reuse was read-only/no candidate;
the newer P55 milestone records application. Earlier Index/Prof changes remain.
Pause cancels work/jumps first. No generated gates, manual sync or publication.
16 November 07:34 UTC native diagnostic addendum: TYPE confirmed five callable getters;
protected D1 observed nonsecret first results; E1 found no current-group
matching error. A separate visual P54Z observation confirms zero cast/channel
returns: old type(getter()) failed with value expected; type((getter())) is nil.
Its formal ACK expired at120s; the journal is preserved without restamp/replay.
Temporary IdleR2 a7e68bc1 changes only both return-adjusting parentheses;
actor94a960ef changes only that fixed source binding. Both remain external;
the actor has not run and no observer is installed at this checkpoint.
No addon Lua, settings, source-adoption or native performance claim follows.

16 November 07:54-08:27 UTC native setup addendum: fresh IdleR2 received a
formal visual ACK. The unwrapped Food/cancel smoke queued both commands and
root observed red Interrupted with chat closed; host cancel enqueue was1016ms
and total enqueue1032ms. Its actor ACK remains false by design. This verifies
the reported functional smoke, not callback cost, native frame gaps or FPS.
Later one guarded local Escape closed Copy and cleared the target; key-up and
lock release were recorded, without activation or global input. General was
already selected: the prepared selector never ran and no tab restore is owed.
The earlier fully queued PRE had no visible marker in CombatLog; no ACK,
replay or execution/absence claim follows. A fresh P54CTX formal ACK reports
scriptProfile0, caps120/30, Syndicator/Baganator and native profiler true,
SPACE JUMP. The actual helper-literal authority is _P54/z53/tagP54_b84e619a,
with600s staging/20s active; stock5.1/5.4 models each76cases/548checks pass
and three harmful controls fail. The unused z54 proposed body is historical.
No observer is installed at this checkpoint; native attribution remains pending.

[Exact sources, regressions and pending native checks](validation/syndicator-partial-oldrows-2026-11-16.json).

15 November `LHO-INDEX-FLAGS-20261115`: applied reviewed R2 at15:53:07UTC
after a verified source/history checkpoint, scoped three-file backup and125
settings metadata entries; no private settings copied. Index e1cdab75 and tests
2ef703a9/3734c343 are the only applied files. Private eight-region duplication
retains the public baseline body.85cases/530checks, strict99,237 checks,
independent237 checks and17consumer pairs pass. Exact short-root copies resolve
two long-path smoke failures without changing their bytes; frozen baseline
401/1090 and candidate402/1091 PASS with full manifests stable and19R34 pins
matching current source. Original drift rejection and failed long-root run stay.
R2 real-Core CPU1203.125->812.5ms/1million queries(-32.47%); fallback-4.62%.
Direct public body is identical(one CPU tick higher/+0.18% elapsed). Whole
warm/cold timings are mixed; cold CPU+3.92%/wall+6.47%. R1 remained unapplied;
its desktop440B/query,44KB/100rows and about264KB/six-delivery allocation saving
is supported for R2 by unchanged allocating bodies/zero-table proof, without
new R2 GC measurement. Earlier current run402pass/1Bars failure was unstable;
the one justified latest run16:27:16UTC passes408scripts/1097syntax with zero
failures but full/Lua sourceStable=false amid Bars State/Watch, input binding,
route test and generated verification edits. No fixes/retries; changes preserved.
Existing SYNC delivered e1cdab75 to all five client disks by15:59. I42a NEW
boolean/function output and Index15(ReadOpts11)/Index139(GetLiveCount134) frames
observe current R2 loaded in Forever; no cryptographic function/all-client claim.
I41d queued203chars/109ms then guarded out; execution unknown, getinfo invalid
because debug is boolean. I40 before count0 median1.6094999909401ms/100 and
after count176 median1.3808999955654ms/100 retain seven raw batches each and
CVars0/120/30. Scene/count differ, so comparison UNMATCHED with no gain percent;
native frame/spike, taint, pixels and controller acceptance remain pending. Next count audit
is source-only with no candidate; ordinary default zero already uses one modern
attempt and restock/charge seams remain guarded. Goal ACTIVE. R3 PID35680
stopped16:31:04UTC on stale heartbeat. R4b PID48720 later stopped18:20:24;
host confirmed absent18:26. Exact reviewed R4 source4b9baecb restarted18:27:03,
idleapproved20261115r4c/PID33168, alive/empty stderr per root. Pre-launch capture
showed57s cast and queued crafting, so root-crafting-deferral-20261115T1825Z
craft_hold is present. Held/no movement claimed; root maintains heartbeat,
earlier chat locks released, guarded native tests
now explicitly permitted. Presence-only hold
is root-managed and provides no automatic future craft detection. No transactions/deletes/provider or profiler preference edits,
manual sync or publication. Recorded G43 raw calibration only: baseline g43b20261115e shown=true
0.36879998445511ms/1000 and conditional g43c20261115a0.34950000047684ms/1000;
6focused/4models pass. a-d guarded before input; f loading screen and g BG->FG
released with no input. Only two successful calls created2hidden Frames+2FS,
no handlers/timers. Later loadscreen/chat reset/windows closed do not prove
reload or cleanup. Stop at1of3pairs; real SetCount costs untested, no candidate
Lua edit or native gain claim.
AH synchronous skip amplification audit is BASELINE ONLY: modern/legacy
n1/10/100 manual no-recipe/preferCrafting=false limited-zero-cap workloads give
6/42/402full builds and6/420/40200row reconstructions. Six workloads plus five
freshness/error controls PASS;14audited sources stable. At100:40200List name
reads,85851modeled live calls,80400SetItemUnits. Naive reuse loses public target/
name mutations and a late raw name error; positive-cap async reharvest remains
required. No timings/native frequency/product/candidate claim. AH audit seal: `C:/Users/mario/.codex/visualizations/2026/11/10/01a1c551-7947-7cf1-8aac-c0891cf4fa6b/lag-hotspots-20261114/resume4-20261114T222014Z/auction-synchronous-skip-audit/seal.json`.
Q44 native q44workload20261115c ACK:4returned rows,1zero PurchaseLimit,
one public GetRows3.095900028944ms. Reconciliation and post-clock cap-default
initialization remain; source vendor sale predates the probe. One sample is not
CPU/FPS, PrepareNext frequency, six-times extrapolation or all saved targets;
Q44 zero remains unexplained by disk snapshots; live row epoch is unestablished. Initial two-SetItemUnits deletion
is REJECTED/no apply:4scenarios/18checks per variant,2canonical matches but2
constructed public-extension counterexamples change final data. No installed
third-party extension is asserted; no product/candidate change.
Recorded separate stable disk reads:17:56:29 SHA9f88f971 shows2positive
manual/0limited-zero and missing preferCrafting=>true;18:00:11 SHA247b7983
shows0false-price flags/0limited-zero anywhere,3positive combat fields/0saved
vendor plans. No combined2+3 census or memory inference; Q44 zero unexplained.
Q45a-d guards stopped before input; user then explicitly permitted in-game
tests. Q45e NEW4true with no Z45 line between header/chat bottom was ACKed at
18:33–34UTC; locks/no_jump released. Later existing rows do not identify/disprove
Q44 zero or establish its epoch; no rebuild and PurchaseLimit/default caveat retained. Awaited sealed Trinket40scenario baseline(5x8,1000ticks):
hidden/unbound0work; shown rawQ/E1000callbacks/2000key/1000clock and0binding
metadata per tick, including none/bag_only with nil canonical bind widget.
Mouse release2callbacks; wheel200x1ms. Nine source pins stable; initial wipe
instrumentation failure retained with unobservable count removed. No product
candidate/native CPU/FPS claim. Trinket R1 and R2 are REJECTED/no apply: R1 loses four resolver/reentry
controls; R2 has two conditional passes but six constructed preinstalled API-
wrapper result/error parity failures. No installed foreign wrapper is asserted;
no performance/allocation/native trials or application. Baseline remains sealed.
C46f baseline ACKed all4new lines at18:53–54UTC after a user-confirmed quiet
window: CVars0/120/30; healPotion5rows/2.6513999998569ms, manaPotion2rows/
2.5431999862194ms, bandage8rows/2.1509999930859ms. FG both captures, one call
per kind; chat/locks/no_jump released, craft_hold1825 retained. Skillet7836/
Blackmouth Oil error already existed in SOURCE; probe did not craft/cancel/open/
trade. Earlier a-e were0input. Normal cache/reagent/metadata/count side effects
remain; on-disk615d4be0 is not a cryptographic loaded-function or all-client proof.
Desktop24child/26pin timing preserves work/checksums/native counts. Whole CPU
medians stay812.5ms(Forever)/781.25ms(Retail/Syndicator); Forever wall+0.066%
is mixed, Retail/Syndicator wall-1.745% is CPU-quantized. No native after or FPS
gain; candidate stays external, with stock Lua5.1 language checks separate.
[Evidence](validation/inventory-live-count-flags-2026-11-15.json).

15 November main-row acceptance status: BLOCKED pending in-game verification.
The same user-deferred native check remains unavailable for the third consecutive
goal turn. The previous turn made progress by fixing secure recovery indexing;
this audit confirms the candidate, full tested corpus and Forever installation
are unchanged. Source recovery and offline gates remain valid, but actual actions
for all 19 buttons, especially 13-19, are not established. No additional runtime
change or test rerun is justified without new evidence. Resume native acceptance
when testing is available; preserve player actions, bindings and preferences.

15 November main-row recovery (`MAIN-ROW-RECOVERY-20261115`): current user goal
is restoring main buttons 1-19, especially 13-19 on Forever, with other clients
checked against the docs. Connected borders remain cancelled. Explicit
`/fluxbars restore` rebuilds the 19 owned routes through existing State/Layout/
Clicks owners, clears shadowing mouse/proxy action fields, refreshes cached
mapping/key state and retains slot programs/binding profiles. It does not run
automatically or replace player-stored action contents. `/fluxbars audit` adds
native click/proxy/key/spell/icon evidence missing from earlier dumps.

9,448 recovery and 700 audit functional checks PASS across five client models;
six harmful recovery controls rejected; seven focused scripts PASS.
Full offline validation: 399 scripts and 1,087 Lua syntax files PASS. Native calculator/helper bodies match five pinned sources;
installed routing sources were checked. Only scoped Bars/Init.lua was updated in
Forever after backup/hash verification. No native input/focus/profiler or saved
action/binding reset. The user cannot test in game yet: actual recovery and native
taint/render/controller/FPS acceptance are PENDING, not complete. Second unavailable
native acceptance audit; do not mark the goal achieved or resume connected borders.
[Requirements, commands and evidence](MAIN_ROW_RECOVERY.md).

15 November secure-paging recovery review: `/fluxbars restore` now calls the
existing slot indexer after secure force-apply. When the native action attribute
was already correct, its unchanged value did not fire the index callback, leaving
a stale display/tooltip slot behind. The archived command fails that case; the
current command passes 9,448 checks across five client families and fallback plus
secure-header paths. Driver/attribute transport is modeled; native casting and
taint remain unverified. Seven routing owners match the pre-connection ZIP byte
for byte and all 35 installed copies after newline normalization. The user still
cannot test in game; live recovery remains open.

15 November exact pre-connection restore (`FLUX-BORDER-CONNECTION-ROLLBACK-20261115`):
the user requested restoring everything to before connected borders after the
texture failures and continued wrong-action reports. Connected-border development
is cancelled. Core/BorderJunctions, its TOC entry/callbacks/roles, masks and join
assets/tests are removed. The later fixed-weight/previews/Trinket styling slice
is also restored to the verified12:03:41UTC checkpoint, including its prior
border thickness control and20art canvases. Every prior runtime Lua file and
repo TOC matches that checkpoint byte-for-byte; unrelated prior work stays.
Action routing files match GitHub main6b444eba4573092b57919ee3e497d86d2ebb3ece.

The page2 dump explained duplicate6/18; /changeactionbar1 restored the normal
page per user. The user then reported columns13-19 still wrong. Their18/19 dumps
show action18/19 andID0; expected/actual spell contents were not supplied. Do not
claim those remaining buttons repaired. Their recovery needs a fresh native check
after the exact restore; game-stored action contents are outside source backups.
No native input/focus, action-content/settings reset, profiler writes, manual
installation sync or publication. A pre-rollback full source/history checkpoint
preserves the experimental version externally. Full397scripts/1085syntax PASS.
Focused restored652border and714startup checks;170raster checks PASS.
[Exact restore, checkpoints, unresolved native state](validation/border-types-2026-11-15.json).

15 November native mask-limit correction (`FLUX-BORDER-MASK-LIMIT-20261115`):
the user reported the client maximum is three masks/texture, at13:58:53 and14:07:02.
The prior eight-mask budget was wrong; a strict three-mask model reproduces that
exception. Junction planning now reserves pre-existing masks with GetNumMaskTextures,
accepts only complete operations within the remaining capacity and leaves original
paint locally when full. Missing/private mask counts retain original art. Cleanup
tracks successful attachments and preserves other effects' masks; a native failure
leaves the geometry retryable instead of caching a partial plan.

The action-bar dump separately showed native page2, swap0 and ID0 hosts. Main
column1 correctly resolved slot13; dynamic column6 and static column18 both used
slot18. The user confirmed expected actions return after /changeactionbar 1.
Native page selection stays user-controlled; action layouts/contents are unchanged.
All eight routing owners match the pre-border checkpoint. A production startup
regression also verifies the earlier size-script exception aborts before headers/
mappings and the handler fix permits all57 surfaces and page/modifier mappings.

147 junction checks, 3,822 startup/retry checks and11focused scripts PASS;
seven harmful controls rejected. Full399scripts/1088syntax PASS. External current
source/history checkpoint and five settings metadata entries verified. No native
input/focus, private settings/profiler writes, reset, manual sync or publication.
Page1 recovery is user-confirmed native evidence; fresh clean-start/mask rendering,
combat taint, controller and FPS acceptance remain pending for the final candidate.
[Exact reports, source identities, tests and remaining limits](validation/border-types-2026-11-15.json).

15 November border startup correction (`FLUX-BORDER-SCRIPT-SUPPORT-20261115`):
the user's 13:51:25/13:52:06 error reports show Texture:HookScript rejecting
OnSizeChanged during MicroMenu load and RaidFrame enable. The previous desktop
mock incorrectly allowed frame scripts on textures. A stricter widget model
reproduced the exact failure before the runtime fix. The shared watcher now
checks each handler with HasScript, rejects inaccessible/absent capability
results and preserves supported visibility/parent-frame size hooks. Existing
geometry method hooks, event coalescing, 20Hz ceiling, art and input stay intact.

97 junction checks and six focused scripts PASS; three harmful handler-guard
mutations are rejected. 399 scripts / 1,088 syntax PASS for that handler-fix stage. Checkpoint: current source/history
plus five settings metadata entries verified externally; no private settings
contents copied. The user's error is native negative evidence for the prior
candidate, not a native pass for this correction. New loaded-source/startup,
combat/taint, rendering/controller and FPS checks remain pending. No native
input/focus/reload/settings/profiler changes; inventory diagnostic holds remain.
[Failure, reproduction, source identities and validation](validation/border-types-2026-11-15.json).

15 November COMPLETE PAUSE at the user's request. The requested /reload is
VERIFIED: loading screen, then the expected Mario-Super world and fresh addon
startup messages. Client PID40032/HWND7995860 remains; temporary Lua state has
reset. Re-add only needed diagnostics after explicit "continue"; do not reuse
P36's pre-reload1685 as a same-VM baseline. CANCEL, JUMP_STOP, INPUT_HALTED and
the intentional pause no_jump hold remain; input.lock is absent. Host process
enumeration found no owned probe/test/trace/jump workers. PID42220 and the
reload lease27860 are absent. Do not restart work or jumps until resumed.

Resume at the Index count-allocation gate. The unchanged054731ce source passed
99,232 semantic checks with15,405 trace samples;20,000 live queries create20,000
normalized tables. R34 targets100 such tables/callback (600 over six deliveries),
not the deeper1,180 native calls. No candidate exists. Reviewed H37cef4acd1 is
ready but NEVER executed: test its isolated local-table hook on the current
client before any public-count bypass. Preserve both capability/conversion
passes, dynamic getter/fresh override table and late warband mutations.
Use the verified R8 atomic open/type/Enter route for separately reviewed code.
The border/TrinketMenu request was CANCELLED; leave that scope alone and preserve
newer unrelated border work. Full Inventory/EBS lag goal and native/client
acceptance remain unfinished. Exact evidence and resume artifacts are in the
external pause-20261115-after-reload-final.json under the existing P4 root.


15 November border follow-up (`FLUX-BORDER-JUNCTIONS-20261115`): the user's renewed
instructions authorize this border/Trinket source and art work. The independent
native inventory pause and all input/diagnostic holds remain untouched.
Thickness is no longer a setting: type 1 always uses its original 100% artwork;
type 2 uses extracted Forever gold at a fixed 150%. Obsolete saved thickness is
ignored without deleting profile data. Consumer geometry and outward pixel padding
remain; corrected cap/edge endpoints and extruded seam gutters address filtering
cuts. Dropdown entries show complete 80x20 borders, with 192x48 tooltip previews.
Trinket appearance/usability restoration uses the live EBS ring/backplate owner.

Registered structural borders now share an event-driven junction pass: collinear
intervals keep one paint owner; spatial buckets find T/X nodes; original source
textures receive owned cut masks and one matching T/X patch. Close patches partition
their overlap. Unchanged geometry skips solving/allocation. The shared structural
scheduler coalesces layout/visibility/style changes and defers discovery in combat;
there is no idle OnUpdate or ticker. Candidate/segment/operation/mask limits keep
pathological layouts bounded and retain original art when a limit is reached.
Combat portrait and debuff overlays, cast bars, pet/ToT/focus-target/party-target
owners keep their intentional layering. Hide/removal/overlay transitions release
incident masks so a neighbour cannot retain a hole.

Focused: 532 border lifecycle/consumer, 86 junction/workload, 33 Trinket appearance
and 3,334 raster checks PASS. Whole-suite 399 scripts / 1,088 syntax PASS, with 12 final focused replays. No native input, reload, focus,
WTF/profiler writes or manual installation sync. Native GPU/mask capacity, pixels
at actual UI scales, secure taint, controller and FPS acceptance remain pending.
[Source, checkpoints and limits](validation/border-types-2026-11-15.json).



15 November fast diagnostics follow-up: R7's background fixed-print send
returned accepted NEW JQ4p1 158981.621 with63ms sender time including40ms hold.
R8's complete open/type/submit chain queued33 events in15ms; root immediately
observed NEW JQ4p1 159296.682, closed chat and continued crafting. Its late
CLI ACK annotation exceeded120s and refused; journal stays submitted/false.
No retry/restamping or invented accepted certificate followed.

The read-only exact-build P36 query returned NEW P36F1685. Its unknown
threshold epoch/window permits only raw signal/availability, not bounded CPU
or inventory causality. Root replaced heartbeat-stopped PID36188 with reviewed
jump PID42220 at11:26:22, released the scoped chat hold after completion and
retains180s/idle15s conditions; no movement is verified. Preserved the external
grid-write proposal with no fixture/candidate and clarified that legacy
FluxInv_Events is unloaded; active raw owners remain outside Events coverage.
[Native evidence and remaining limits](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November inventory frame baselines and command transport follow-up:
recorded two independently checked current-client presentation samples and
R34's whole-source cold-vendor work counts without applying an inventory fix.
R3's maximum is 308.2077ms with 11 intervals above 100ms; R4's is 114.1185ms with
one above 100ms under different foreground/activity conditions. Pinned source
confirms v1 QPCTime seconds; final ETW loss remains unverified. These are
whole-client observations, not addon CPU, matched gains or inventory causality.

Preserved failed transport attempts: R3a/b stopped in BEGIN before keys; R4c
opened blank chat then stopped on a BG modifier; R5d observed closed chat and
did not type; R5e stopped before characters after another foreground app changed.
R6 permits switching other apps while WoW stays background, retains strict WoW
foreground checks and requires fresh visual certificates. Native run
dualfinal20261115f produced NEW JQ4p1 157283.9; chat closed and its input lock
released. Native foreground/profiler/observer/source adoption remain pending.

Root released scoped no_jump after commands. Reviewed helper PID36188 replaced
heartbeat-stopped PID44368, retaining the 180s/idle-15s rules and batch holds;
11:09:33 deferred without activation, Space or movement. The external four-tag
Events V2 prototype passed 75/1,168 plus six harmful controls but is not deployed.
No addon Lua, profiler preferences, external Syndicator/Baganator or agent item
actions changed in this documentation slice.
[Current evidence and identities](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November shared border types (`FLUX-BORDER-TYPES-20261115`):
General Settings → Appearance now offers Border type 1 (existing battlefield)
and Border type 2 (the options window metal family, rectangular corner).
Both choices have accent-aware top-border swatches in the native dropdown.
No tint preserves natural artwork; Forever bronze applies only to type 1.
The shared service swaps existing texture art and retains all anchors, sizes,
layers, explicit colors/alpha, backdrops and consumer ownership. No consumer
files, timers, input, native preferences or other installed clients changed.
User chose Implement directly; prior Witchcraft preference retained. Six focused
scripts pass 11,080 checks; final combined gate passes 397 scripts / 1,085 syntax files. Native pixel joins,
UI-scale fit, persistence, taint and controller acceptance are NOT RUN.
[Exact source, checkpoint, scope and acceptance](validation/border-types-2026-11-15.json).


15 November 08:58:53 UTC current clock correction: this exact desktop Lua
5.4.6 binary advances `os.clock` while blocked on stdin (0.512s/1.011s),
while whole-child GetProcessTimes CPU was 0.015625s/0s. Earlier `os.clock`
figures therefore measure elapsed time, not isolated CPU. R29
+10.74%/+13.61%/-12.52% and R27 16–38% are matched desktop elapsed results.
Historical CPU labels and raw reports are retained with this overriding
interpretation. R27 104→0 transient bytes/query and other GC-controlled
allocation counts retain their stated scope; no CPU/FPS gain follows.
Future timings must identify their clock and distinguish measured-chunk
elapsed time from independently captured whole-child process CPU.

15 November 09:17:18 UTC R33 (`LHO-EBS-RANGE-WORK-R33-20261115`) is APPLIED
ON DISK: two private range helpers in EBS Paint011f126a→9c962912 now reuse
functions. Current btn/range owner/unit arguments, dynamic public methods,
raw errors, return arity, item keepLast writes and reentry remain. The existing
0.18-second range lane and immediate invalidation/callback work are unchanged.

External full395 scripts/1,083 syntax checks passed before application with
stable source. Focused165/1,095 and existing86,872 stress checks per source,
independent80/640, durable40/295 and six rejected harmful controls support the
modeled behavior; baseline durable replay exposes10 intended allocation failures.
The fresh2,838-file source/history checkpoint and126 settings metadata entries
precede application. Fifteen new raw identities across three files/five installs
match;1,082 other raw Lua files and five selected external Syndicator files stay
unchanged. Current1,083 normalized sources match the pretested corpus.

Eligible direct probes remove a232-byte transient slope; the candidate retains
only a bounded36–256-byte control envelope. The mixed producer model changes
2,264→1,104 bytes/sequence; absent-target allocation is unchanged. Five pairs
give inner ELAPSED medians295→239,236→183,121→124 and77→71ms. The absent-target
path regresses3ms/250,000 calls (+0.012us/call), with zero of five pairs faster.
Separate WHOLE-CHILD process CPU medians are312.5→250,250→203.125,
140.625→140.625 and125→109.375ms; these include boot/warmup/allocation and
15.625ms quantization. Neither measurement establishes inner CPU, native
event/worst-frame/burst latency, FPS, GC-pause, taint, pixels or controller gain.

R33 runtime adoption is UNVERIFIED: no chat/reload or native test follows this
application. The bounded range side check is complete; return to Inventory/EBS
event-spike work. R32 found a legacy Usability owner unloaded; no optimization
was applied. The separate vendor cold-retry audit is UNMEASURED: six builds/
600 probes is a proposed shape, with no fix or safe cache; preserve200ms cadence.

At this handoff, frozen supervised-chat JQ4/bootstrap5d48148b has27 mock checks
and three controls. Only BEGIN read-only preflight was attempted; eligibility
failed BEFORE keys, journal or lease. No chat opened and no observer installed.
The background-only read-only route/Inventory observer remains a proposal. Keep
INPUT_HALTED and root-owned no_jump/R3 hold; no verified movement or fresh
craft/chat eligibility is inferred. Root owns all native/helper controls.

[R33 exact identities, ranges and native limits](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November 08:41:06 UTC R31 (`LHO-COMBINED-BAG-OWNERSHIP-R31-20261115`)
is APPLIED ON DISK: two predicates in the Era/Anniversary combined-bag shim stop
repinning into hidden historical hosts and stop returning items already owned by
a foreign frame. Normal layout/adoption cadence remains: the five-bag/16-slot
model still makes 12 refresh/layout passes and 640 HostFor calls. A selected
foreign return keeps its GetParent read but removes the incorrect SetParent and
ClearAllPoints writes (one each→zero). Normal Repin adds no IsShown read; a
genuinely displaced shown host adds one. This is an ownership bug fix, not FPS gain.

Owner8da75582→e089ec5f and durable testbd05350d/two support fixtures passed the
external full gate394 scripts/1,082 syntax checks with zero failures and stable
source before application. Durable18 cases/584 checks and independent88/796 pass;
the baseline durable replay exposes10 intended failures. The dated source/history
checkpoint contains2,835 files and126 settings metadata entries. Retail, Forever
and MoP exit this owner; native Era/Anniversary reopening, protection, pixels,
controller and performance acceptance remain PENDING. No reload/source-adoption
verification was performed; source identity does not establish runtime loading.

R28 is REJECTED/UNAPPLIED: exact-false existence skipped required unreadable/cold
recovery and failed200/790 existing checks (baseline0/790). R29 R2 is rejected for
general application: five pairs show ordinary elapsed time+10.74%/+13.61%, while one
revocation-heavy model improves12.52%; allocation savings remain model-only and
the native secret/error contract is unproved. The rank-preserving follow-on was
stopped at a source counterexample: a later callback can turn an earlier retained
winner into the first match. No replacement framework was implemented. R30's
37-check baseline confirms existing provider burst batching; no candidate/apply.

The user approved idle jumps in foreground/background, then required postponing
them during temporary chat code or crafting. Root reports R3c40bb8d2/PID44368
running but HELD by `native/no_jump` token
`craft-input-guard-upgrade-20261115T0836-root`; movement is unverified. No reliable
fresh craft/chat observer exists yet. Root owns the helper/gate: do not clear the
hold, restart it or infer eligibility from old captures/SavedVariables. Keep
`native/INPUT_HALTED`; no automated chat, profiling or reload. On pause set
CANCEL/JUMP_STOP first. Full LHO-01 through LHO-13 remains ACTIVE. Earlier helper,
permission, adoption and gate statements below are dated historical states.
[Exact decisions, source identities, modeled costs and pending native gates](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November R26/R27 application (`LHO-CAST-PASS-R26-20261115`,
`LHO-CAST-NAME-R27-20261115`): Cast/Paint/Effects now close the existing slot
memo after an outward paint error, then rethrow the original error object.
An error before this invocation begins a pass preserves an unrelated outer pass.
Normal callbacks, getter order, single-active-pass semantics and cadence remain.
The separate LiveCastName helper hoist removes one transient closure per query;
native getters and formatters are still looked up when used.

The combined Cast5902f1bc/Paint3cddc870/Effects8b785f47 bytes passed independent
composition review and 393 desktop scripts/1,081 syntax checks before application
at 07:12:24 UTC. Two durable tests and one source-layout extractor line accompany
the three runtime owners. All nine extractor assertions remain; original LF was
restored (final fixture6d7ecf35) without changing tested normalized source.
The dated 2,833-file source/history checkpoint and 126 settings metadata entries
preceded application; 30 changed-file identities across five installed clients
match. No new frame, timer, event, native API, option or saved-data root was added.

R26 is a correctness fix with measured desktop cost: ordinary small paths add
about 0.1–0.2 microseconds per call; an independent 57-host paint shape adds
1 microsecond/call. The active-Effects extra 1,632-byte post-GC envelope stays
fixed from 10 to 10,000 calls, rather than growing per call.
R27's separate helper model removes 104 transient bytes/query and reduces CPU
medians 16–38% across five alternating pairs per shape (250,000 queries/run).
These helper results do not attribute R25 PickOwners spans, establish whole-event
CPU savings, or measure native FPS/GC. Native error frequency is unknown.

R26/R27 are APPLIED ON DISK; native source adoption is NOT VERIFIED. The guarded
reload transport completed, but a later capture showed an open editbox containing
partial Lua. Execution scope is uncertain; native input was halted.
Two targeted Escapes then restored the expected world with no editbox/menu;
the input halt remains. No cast ran after application, and a reload may have
occurred, so loaded-source adoption remains unverified. No native
performance, taint, pixels, controller or other-client execution is accepted.
R21 vendor workflow acceptance remains PENDING; R23/R25 captures retain their
historical source identities and inclusive-span limits. R18/R19 remain rejected.
Goal stays ACTIVE, with no keepalive helper; idle-focus permission is pending.
[Source, controls, samples and pending native gates](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November R25 native stage attribution (`LHO-CAST-STAGES-R25-20261115`):
one valid 20.0107638-second Food cancel/completion window recorded 17 complete
raw spans totaling 24.269199937582 ms (maximum 5.8176999986172 ms).
SpellIdFromAction: 351 spans, 2.3977000713348 ms total / 0.24150002002716 ms max;
SpellIdFromEBS: 393, 1.8775001466274 / 0.051800012588501 ms;
PickOwners: 10, 16.2417999506 / 2.3553000092506 ms. PlayInterrupt was unsampled.
All entries finished with valid clocks and zero final depths. Method nesting660
means these inclusive spans overlap: do not sum/subtract them as exclusive CPU,
assign the maximum to an event, or claim matched gain/FPS. Native observer cost,
taint, pixels, controller and other-client acceptance remain pending.

Independent screenshot/scalar and all11 submission reviews agree. Exact four
original methods/raw script/namespaces, disposed timers and explicit root removal
are verified; original addons/preferences/focus remain. No new casting code was
applied. ARM and the authorized actor ran without a tool handoff; timing was
accepted afterward. R23A remains the separate inconclusive empty/late-actor case.

Fresh reconnect/login now observes startup with matching applied R21 source
d260f7d6 on repository/Forever disk; loading that source is inferred from the
fresh world/facade, while actual vendor close/reopen workflow acceptance remains
PENDING. Earlier NOT LOADED statements below are dated capture/application states.
R18/R19 remain rejected and unapplied; R26 is a separate offline proposal. No
keepalive helper or pending diagnostic root remains; idle-focus permission is
pending and full LHO-01 through LHO-13 stays ACTIVE. The last docs gate at
06:38:13 UTC passed 1,112 sources/623 reachable/444 settings/24 SavedVariables/
17,548 links; this R25 delta receives its own final gate.
[Source, observed aggregates, startup scope and cleanup](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November R23 native casting attribution (`LHO-CAST-MATCH-R23-20261115`):
the valid 20.00793-second current-source window contains the authorized Food
cast/cancel/completion sequence. Seventeen complete raw spans total
24.42019996047 ms (maximum 6.0662000179291 ms). The 476 matcher spans inside
those callbacks total 4.9502003788948 ms (maximum 0.090500026941299 ms).
All spans completed, depths returned to zero and no nesting/invalid clock was
reported. Exact original method/script restoration, disposed timers, unchanged
namespace and explicit diagnostic-root removal are verified. Original Syndicator
and Baganator remain loaded; profiler preferences and focus are unchanged.

Attempt A expired before the Food commands and had zero samples; it is retained
as inconclusive. B sends ARM and the already authorized Food sequence without a
model/tool handoff; native timestamps establish overlap afterward. These are
inclusive instrumented spans, not exclusive CPU: do not subtract matcher totals,
assign a maximum to a specific event or compare the older R6 workload as a gain.
Native observer calibration, FPS, pixels, taint and other-client acceptance remain
pending. No casting product edit follows from this sample. R21 is still on disk
only and NOT LOADED. No keepalive helper is active; idle-focus permission remains
pending. R24's source map guides the next R25 attribution plan; the R26 slot-pass
lifecycle replay is offline-only. Goal remains ACTIVE.
[Aggregated source, controls, native results and cleanup](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November R18/R19 final decisions (`LHO-R18-R19-REJECTED-20261115`):
R18 reagent-query reuse is REJECTED and UNAPPLIED; all four product owners stay
unchanged. Independent controls collected 50 results: 45 passed and 5 failed, so
this is not a PASS. The mixed plain/proxy row gap was fixed only in the external
partial prototype. Merchant getter, public HasWarband and late snapshot getter
callback/freshness failures remain. The simple options-proxy replay was equal;
that boundary remains unproved rather than a confirmed failure. The stopped
partial prototype would add 186/remove 9 lines across four owners and register two
metadata events on an existing frame (no new frame/timer); none was applied.

Only pre-proxy V2 identities have the five-pair timing evidence: conditional
flag-only/already-seen shapes reduce modeled CPU about 85.48%/73.6-73.9% and name
reads 2,581->244. Ordinary new-row work stays 2,581 names/40 counts, with overlapping
tiny CPU changes and 12.8 extra transient bytes/query. These results do not apply
to the later partial hash or establish native gain. The actual native settings
snapshot has 4 entries (1 nonpositive/3 positive), with eligibility and natural
query frequency unknown; it does not represent the 20-no-op stress fixture.

R19 cast-entry lookup is also REJECTED and UNAPPLIED after 194 desktop checks.
The safe gate cannot accelerate the observed native MainBtn6 table/metatable
shape. A broader gate loses protected-metatable equality behavior. At 100 entries,
CPU medians are 488->492 ms with overlapping ranges; the single 500-entry stress
pair is 1914->1993 ms with unchanged allocation. Eight frozen inputs remain
unchanged; no native gain is accepted.

R21 remains the separate applied change, with 391 scripts/1,079 syntax checks
passing and no client reload: R21 is NOT LOADED. The last completed docs gate at
05:41:35 UTC passed 1,112 sources/623 reachable/444 settings/24 SavedVariables/
17,542 links; the 05:45:13 UTC guard found zero mismatches across 1,079 Lua files.
The R18/R19 docs gate passed at 06:00:23 UTC with 17,545 links; the R23 delta
awaits its final docs gate. Goal remains ACTIVE.
R23 native casting attribution completed and explicit cleanup is verified; no
pending diagnostic roots remain. Idle-focus permission remains pending; R2 is stopped
and R3 is not deployed. Existing feature, cadence and all-client gates remain.
[Versioned rejected evidence and current acceptance scope](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November 05:28:26 UTC R21 application (`LHO-VENDOR-SESSION-R21-20261115`):
old vendor refresh timers and parked quiet callbacks are now scoped to the closed
session. They cannot reuse old options against a reopened merchant or clear its
pending work. A failed public close hook also cannot strand the new session's
pending/quiet state. Only VendorSession changed (6b84ca26 -> d260f7d6 raw;
23ec74d1 normalized); durable tests/vendor_session_lifecycle.lua was added.
Existing license notices, options, active-session 150 ms refresh, After0 quiet
handoff, public callbacks and repeated Begin/direct SetOpen behavior are retained.

Before application, 137 scenarios/502 exact-source checks passed; baseline fails
100 intended regression checks. Start-only and repeated-Begin harmful controls
fail 44/8 checks; both earlier failed candidates and their evidence remain.
Independent /root/addon_combo_protocol review passes 54 checks and rejects all
five negative controls, including the failed-End quiet callback orderings.
Three alternating whole-facade pairs per timer route/scenario retain 36 raw
samples. Reopen scenarios reduce UI scheduling requests 6->2 per cycle and timers
3->2 (delayed) or4->3 (quiet). These controlled endpoints exclude downstream UI
rendering/native work. Ordinary modeled facade cost rises 2.53%/4.94% (2/4 ms per
50,000 cycles, about 0.04/0.08 microseconds per cycle) and 48 transient bytes per
request; those costs are retained in the result. No native CPU, GC-spike or FPS
gain is inferred. The real client has not reloaded this source: R21 is NOT LOADED.

A verified external 2,832-file source/history checkpoint and 126 settings metadata
entries preceded application. Focused 502 checks and owner/test syntax pass.
The full source gate passes 391 scripts/1,079 syntax checks at 05:31 UTC, with
all source identities stable throughout. This records current progress; the
goal remains active. R18 remains an unapplied
external prototype; R19 is rejected. Idle-focus jump permission remains pending,
R2 is stopped and R3 is not deployed. Full LHO-01 through LHO-13 remains ACTIVE.
[Exact R21 source, controls, samples and native limits](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November R16 cost map and R17 native follow-up
(`LHO-NATIVE-PASSIVE-R17-20261115`): the same validated R7 service observer,
with bank and bags open, recorded 3,475 callbacks over 30.008 seconds, none over
10 ms. Inclusive total was 304.21050059795 ms and maximum 2.6844000220299 ms.
Release handles0/timernil/cleanuptrue/no arm failure and explicit L7FREE/L7CLEAR
are verified; scriptProfile0 and caps120/30 are preserved. No agent gameplay or
runtime edit occurred; transport receipts retain the foreground. Incidental city
traffic and a different workload from R7 prevent a matched gain claim. Service spans can overlap and
exclude raw handlers, native timers and external addons; no exclusive CPU or FPS
result follows.

R16's corrected shared-namespace fixture passes 1,304 checks with nine source
owners unchanged. Of 2,581 native-name calls, 2,541 are 21 visible-name harvests
and 40 are blacklist guards. Twenty flag-only settings with zero UI rows still
produce 2,581 name calls in that model. Canonical trusted-ID query allocation is
237.551 KiB with the actual Item count path; R15's compatibility path is 526 KiB.
These different fixture routes establish no optimization gain. No R16 candidate
was applied. Root's R18 guarded query-snapshot design remains pending; no new
candidate is accepted. Idle-focus jump permission is pending, R2 is stopped and
R3 is not deployed; no keepalive helper is active. Full LHO-01 through LHO-13
remains ACTIVE.
[Current native scope and exact-source cost map](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November R13/R15 and jump follow-up (`LHO-R13-R15-J14-20261115`):
R13 installed and armed a temporary wrapper on the public auction-restock GetRows
slot for a scheduled 20-second natural-call window. It observed zero entries,
completions and valid spans. The stop timestamp was not recorded; the later read
was 128.527 seconds after arm. Exact method/namespace restoration, disposed timer
and absent _FluxR13 are verified, with preferences 0/true/120/30 unchanged. This
establishes no hot-path attribution, callback cost, native gain or FPS result.

R15's Item.GetCount helper hoist is rejected and not applied. Seven alternating
matched pairs per mocked provider mode give whole-query CPU changes -0.56%/+2.26%
with overlapping ranges, despite 7.1875 KiB less transient allocation per query.
The 20-manual-row/121-ID fixture made 40 actual GetCount/native count calls and
2,581 native-name calls. A separate namespace per loaded file lost the private
trusted-ID stamp, so it measured the compatibility GetUniqueItems branch; its
526 KiB allocation envelope is not the canonical trusted-ID path. Independent
semantic review passes 464 cases/2,348 checks, including dynamic lookup timing,
reentry, zero authority and opaque/error identities. No native secrets, taint,
GC-spike or FPS acceptance follows from these ordinary Lua models.

R2 process46504/session52455 stopped at 04:16:02 UTC after its heartbeat expired.
Its 40 recorded targeted Space posts (last 04:14:46 UTC) prove submissions only,
not actual jumps or continued online status. J14 observed 83 false falling
samples and zero edges; AFK clearance cannot distinguish ARM chat/Enter from
Space input. Native J14CLEAN true at 04:52:37 UTC verifies J14 cleanup. The Z
follow-up at 04:54:49 UTC observed 87 valid samples with zero maximum absolute
height delta and no change. Its two-second sampler self-cleaned; explicit native
J14CLEAN true at 04:55:45 UTC verifies Z cleanup and pendingCleanup=false. R2
remains stopped, R3 is not deployed and no keepalive is active at this snapshot.
Successful background jumping and continued online status remain unproved. Root
owns subsequent keepalive verification and stop-before-pause handling.

Original Syndicator/Baganator enablement is restored. No new runtime optimization
was applied; features, look, update cadence and all-client acceptance gates stay
in force. Full LHO-01 through LHO-13 remains ACTIVE. Earlier active-helper and
uninstalled-wrapper statements below are dated historical states.
[Native attribution, cleanup and pending acceptance](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November R11 follow-up (`LHO-NATIVE-PROFILER-R11-20261115`):
existing native-profiler counters during active user crafting/receipts/bank and
window changes increased over382.313s:742ticks>1ms,290>5ms,242>10ms,15>50ms;
>100/500/1000ms counts were unchanged. Counts overlap and include diagnostic
reads/minimization; no idle FPS, exclusive function CPU or optimization gain.
Recent averages2.7872 and0.2185ms are different rolling snapshots; the unchanged
4195.9795ms peak is historical. Corrected zero-return status query passes native
APCTXOK; no product Lua edits or profiler settings writes. Both original addons
remain restored. User returned to bank; nil/nil casts and Space=JUMP verified.
At that R11 capture, the craft hold was removed and R2 sent Space at
03:47:03/03:50:03 UTC. R2 later stopped; the current follow-up above supersedes
that helper state. Stop-before-pause and capture-hold guards remain required.
R12 cold-load-request suppression is rejected for20modeled readiness failures;
10,549targeted desktop checks pass,32scoped owners unchanged. At that stage
the rows-only wrapper was not installed; the subsequent R13 result above
supersedes that state. Do not invoke rows or refresh work merely to time a read.
Full390/1078pass retains its unchanged
1078normalized-source scope; ignored scratch remains preserved and unloaded.
Full LHO-01–13 stays ACTIVE.
[Native profiler observations and limits](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November 04:18 CET bank addon-combination follow-up
(`LHO-BANK-NATIVE-COMBO-20261115`): requested Syndicator-only, neither and
restored-both closed-bank checks are complete; original both-enabled flags2,
aggregate2/defaulttrue and loadedtrue,true are verified after a fresh reload on
the same player. The latest external native/combo-journal.json records
comboFinalSamplesReady=true, restoreRequired=false and pendingReload=false.

In all three closed contexts, live flags are false with BankFrame hidden and
BankPanel shown but invisible. Positive bank IDs1191/3343 retain snapshot1 at
generation1, public1 and native carried0/includeBank1 for3/4/5 arguments through
the same backend. Item1101 remains missing/public0/native0: physical absence and
cold-zero authority are unproved. Initial both-enabled custom-bank context and
a later user-opened Syndicator-only native bank pass positive-count checks;
neither-provider live-bank workflow remains pending. The54-slot native walk
found10positive rows and44ambiguous rows; ambiguous does not establish empty.

Five2000-call snapshot-query samples have medians1.6419/1.6452/1.6463ms for
Syndicator-only/neither/restored-both. These similar query envelopes measure no
bank refresh, whole-addon CPU, workflow gain or FPS. Desktop read-only probe
checks pass15sealed-state and138error/secret cases. Runtime source is unchanged;
the prior390scripts/1078syntax PASS remains historical, with no new full run.

Automatic bank reopening failed with both hidden and shown temporary owners;
positive arm/key gates do not prove interaction and the cause remains unknown.
User-opened bank evidence is separate. Final reload leaves C5/L7/M9/CXO nil,
F24 raw/effective blank and Shift-V unchanged; scriptProfile0, caps120/30 and
native profilertrue are preserved. One minimized-window recovery used no
activation; possible geometry effects remain unverified. Some unrelated capture
foreground changed naturally, so no blanket unchanged-foreground claim applies.
R2 was still owned at that capture; its later stop is recorded above.
Full LHO-01–13 stays ACTIVE; no item move, purchase, sale or delete occurred.
[Banks, samples, restoration and limits](validation/bank-effective-visibility-2026-11-15.json).

15 November R10 source-attribution audit (`LHO-RECIPE-EVENT-ATTRIBUTION-R10-20261115`):
current source has one central-bus recipe-update owner; its identity in the native
22–31ms R7 spans remains an inference. Exact-source desktop work passes1010checks
across30profiles and still invokes2581native-name reads per20-row/121-ID query;
these counts do not attribute native cost. The optional metadata probe passes95
desktop checks and was not installed. LowerMemo and RowOrder candidates remain
rejected; no new runtime candidate, native gain or FPS acceptance.
[Attribution boundary and rejected audits](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November 02:38 CET R8 follow-up (`LHO-MAIL-NATIVE-R8-20261115`):
one user-left-open mail with one attachment/quantity3 passes six native full/early
ID/quantity comparisons. Reads17->2; full median0.0663ms(range0.0577–0.3949), early
0.0697ms(range0.0486–0.2694). All timed DATA passes are below1ms; guards/comparison/
print and end-to-end publication are excluded. Variation retained; no CPU gain,
early-stop application or100-mail/fallback-delay acceptance. Hidden-tail and full
mail-authority design gates remain. Mail untouched; M9nil/timerdisposed/no frame,
preferences and sender foreground unchanged. R2 jump helper46504/session52455
has recorded background sends after the hold; current NEXT_SESSION opening is
authoritative. R1 stopped after34sends for exact target unavailable; hidden/minimized
cause unproved. Full LHO-01–13 stays ACTIVE; no new source candidate approved.
[R8 samples, data-only scope and unresolved acceptance](validation/lag-hotspots-empty-mailbox-2026-11-14.json).

15 November 02:16 CET R7 follow-up (`LHO-NATIVE-PASSIVE-R7-20261115`):
a30.009s passive window records2,979callbacks,12spans>10ms,562.468700ms inclusive
total/max31.461300ms. Latest eight:seven TRADE_SKILL_LIST_UPDATE spans22.7667–
31.4613ms share one callback; one Scheduler eval.listener takes11.0443ms. All
eight failure flags are false; four earlier slow labels were evicted. Prior
Followup source attribution remains inference for R7; Bars versus EBS eval owner
is unproven. Workload/observer/bundle differ from earlier windows: no native gain
or FPS claim. Observers detached, handles0/timernil/cleanupOK/_FluxL7nil; script0/
caps120/30 unchanged; profilertrue at preflight with no agent writes. no_jump
released; the external jump helper was active then. Full390/1078source gate
still matches. Full LHO-01–13 remains ACTIVE; grid eval audit continues and no new
candidate is approved. Incidental user crafting/AH; no agent commerce/queue action.
[R7 samples, attribution limits and rejected audits](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November 01:56 CET R6 follow-up (`LHO-CAST-NATIVE-R6-20261115`):
current Forever raw Cast callback attribution and highest-Food6129 cancel/completion
observations PASS. One30.003s window recorded17 valid callbacks,24.890500ms total
and6.407100ms max; three INTERRUPTED callbacks account for17.5991ms. Aggregate
bag quantity164->174 is a snapshot delta, with no item-ID attribution. R5 used a
different observer/UI and one cancel; its10.0534ms maximum cannot establish a
native gain against R6. Matched desktop improvement remains separate.
Exact handler/owner restoration, C5nil and unchanged0/true/120/30 preferences
confirmed; no_jump released and the external helper was active then. Current
390scripts/1078syntax source identities still match. LHO-01–13 stays ACTIVE;
matched native CPU/FPS, channels/pet, all-client taint/pixels/controller and full
workflow acceptance remain pending. No agent commerce or queue action.
[Dated native evidence and comparison limits](validation/casting-equality-work-2026-11-15.json).

15 November 01:13:03 CET (00:13:03 UTC),
`LHO-BANK-EFFECTIVE-VISIBILITY-20261115`: native BankPanel fallback now requires
IsVisible rather than its own IsShown bit. This intentionally fixes false bank
access from a shown but invisible panel. Only those two tokens in Init changed
69ee82e1->02fcf9ee; durable bank regressionff3d3e8f added. Native PIM/BankFrame,
event latches, cached/live Baganator priority, warm data, true live zero, error
behavior and original throttle/refresh cadence remain.

Three exact-source pairs each pass 3,285 checks/340 gate scenarios, including
430 actual restock-consumer checks across five family models and two providers;
baseline fails 625 checks. Six compiled harmful controls and 11 focused fixtures
are retained; independent review PASS. Twenty spaced hidden-panel modeled queries
reduce capacity probes20->0, item-info probes1,920->0 and item-ID probes2,560->0.
This is conditional query/callback work, with no unconditional polling or native
CPU/FPS claim. Full **390 scripts / 1,078 syntax checks PASS**, all Lua stable.

Guarded idle bundle reload began 00:22:04 UTC / 01:22:04 CET. Loading then world
was observed in the same Forever70938/16001 PID40032/window7995860; foreground
unchanged. The specific native bug now PASSES: IsBankOpen=false/IsBankLive=false
with the same BankPanel shown=true/visible=false, sourceSyndicator/readytrue.
The runtime parent chain was not queried; pinned XML supports the source model.
C5 global absent; Cast OnEvent function and public same-ID matcher ready. Actual
after-Cast casts/performance remain pending. Profilertrue/scriptProfile0/caps120/30
unchanged. Earlier pre-candidate raw cast10.0534ms maximum remains separate.

A modern provider cached row has item1101 quantity1; canonical snapshot count=nil
at generation739, and successful native C_Item3/4/5-argument calls return carried0/
includeBank0 through the same global/C backend. This does not establish physical
absence, aggregate bank totals or native cold-zero authority. After reload the
count is nil/generation1; this is no data fix. Syndicator cold-close/stale-mail
races remain. Closed-mailbox cached0/0 proves neither emptiness nor freshness;
the user-populated100-mail measure-first gate stays open.

Fresh 2,830-file external source/history checkpoint and 126 settings metadata
preceded edit; 1,077 other Lua/1,840 other non-doc files and 41 Syndicator files
unchanged. Twenty identities across four owners/five installs match read-only;
no manual sync. Full LHO-01–13 remains ACTIVE: count/provider authority, native
whole workflows/after-Cast completion/channels/pet, all clients, taint/pixels/
controller and matched FPS remain pending. Preserve the first NEXT_SESSION jump
helper history; subsequent stopped-helper state is recorded above.
No item, mail, purchase/sale/delete, queue or preference action by this slice.
[Exact sources, native scope and remaining acceptance](validation/bank-effective-visibility-2026-11-15.json).

15 November 00:54:09 CET (14 November 23:54:09 UTC),
`LHO-CAST-EQUALITY-20261115`: ButtonFX spell matching reuses private protected
comparison helpers. Public/getter/native/paint calls, repeated interrupt/reticle
handling, progress/fades and event/update cadence remain. Cast98458939 becomes
773cd852; durable equality regression180c5b16 added. Exact-source tests and two
independent reviews preceded application; **389 scripts / 1,077 syntax checks
PASS**, with all normalized Lua identities stable.

Five fresh-process unwrapped desktop pairs over 200 modeled sequences reduce
median CPU 377->306 ms and transient GC-stopped allocation 50,961.934->3,919.746 KiB;
independent three pairs reproduce 377->305 ms. The 60-entry/57-added-face fixture
is synthetic. Protected equality callback identities per interrupt 509->1 while
all 509 comparisons and other measured work remain. Existing 10,075 plus new
1,043 checks pass across five models; exact baseline and two compiled harmful
controls are rejected. Initial failed fixture and preliminary wrapped samples
are retained. These measurements establish no native CPU, memory, taint or FPS gain.

Before-candidate Forever70938/16001 confirmed highest Food6129 active then
canceled before completion. Raw 30.009 s observation: 11 callbacks, 24.654100 ms
total, 10.053400 ms max; START1/STOP1/FAILED0/INTERRUPTED3/SUCCEEDED0 plus six
other callbacks. Per-event/unit CPU is unproven. Exact script/global cleanup and
unchanged profiler preferences confirmed. Candidate773 native NOT RUN; no agent
reload since C1. No native success/completion or old/new gain is inferred.

Fresh 2,828-file external source/history checkpoint and 126 settings metadata
preceded application; 1,076 other Lua/1,839 other non-doc files and 41 Syndicator
files unchanged. Fifteen source copies match read-only across five installs;
no manual sync. New bank context shows hidden BankPanel shown=true/visible=false
while native banker flags=false; modern bank tabs are active. External regression
is underway; no bank fix yet. Closed-mailbox cached0/0 proves no freshness or
emptiness; the user-populated100-mail measure-first gate remains. City crafting
is incidental context.

Full LHO-01–13 goal stays ACTIVE: native after-candidate cast completion/channels/
pet, provider-off/all-client whole workflows, bank/mail authority/readiness,
taint/pixels/controller and matched FPS remain. The 35-command cost-breakdown
probe is external only, not installed. Preserve the NEXT_SESSION jump-helper
opening and stop owned helpers on CANCEL/JUMP_STOP before pause/done. No item,
queue, profiler preference, publication or manual sync action by this slice.
[Exact sources, raw samples and remaining acceptance](validation/casting-equality-work-2026-11-15.json).

15 November `LHO-REAGENT-NAME-LOWER-20261115`: primitive-string reagent-name
normalization computes one lowercase key per RememberItemName call. All harvests/
native-name reads, blacklist/history/aliases, non-string side effects, features,
look, grids/bridge integration and update cadence remain. Intrinsic lower calls
7663->2581 per20-row/121-ID desktop rebuild. Three matched pairs give30-rebuild
CPU medians77->62ms provider-off and82->64ms simulated-on; allocation unchanged.
These are desktop measurements, with no native FPS claim.

One runtime owner plus durable name-work test changed. Initial full gate387PASS/
1FAIL/1076syntax exposed an old extracted fixture's missing private blacklist
table; two local dependencies were added without changing its authority oracle
or work bounds. Current/prior-C1 fixture passes and C0 remains rejected.
Final388scripts/1076syntax PASS with exact stable manifest. Durable146checks/
32owner-cases/5work-cases and3controls plus independent1121checks/15scenarios/
89arbitrary names pass. Final fixture SHAde6b7759 is recorded in the report.

Fresh2826-file source/history checkpoint+126settings metadata preceded edit;
external Syndicator41files and all assets/options/defaults/licenses remain.
Earlier C1 native51-ID22464->10800byte query result is distinct retained evidence.
Native after-lower NOT RUN; latest reload predates this change. Actual casting
and whole restock/pending/auction/crafting/vendor/bank/mail/loot/receive/bag/grid
before-after, provider-off and all-client native acceptance stay pending.
City crafting is incidental; no item-specific test or forced action.

External user-requested180second jump helper stays separate from passive
evidence; preserve its NEXT_SESSION top instructions. Stop helper/owned workers
on resume4/CANCEL or native/JUMP_STOP before pause/done; native/no_jump excludes
cast captures. No raw cast probe installed. No purchase/sale/delete or queue
action, profiler preference change, publication or manual sync by this change.
[Exact sources, measurements, fixture correction and remaining work](validation/reagent-name-lower-work-2026-11-15.json).

14 November `LHO-FRESH-IDS-20261114`: full lag goal resumed and ACTIVE.
C1 is APPLIED after correcting C0's getter-count and foreign-owner regressions.
Index fresh ID maps avoid unused item records in SpellReagents harvesting; public
queries, native-name reads, history, predicates and all refresh cadence remain.
Only two runtime owners and one durable test changed. Exact-source pairs and two
independent reviews PASS; full387scripts/1075syntax PASS with stable identities.
20rows/121IDs desktop allocation494.914->207.477KiB/query (58.1% less);30-call
CPU medians79->70ms off and76->71ms simulated-on. Empty query adds181bytes;
all N+1 traversals remain. This does not remove the native40-59ms callback.

Safe conditional idle reload completed; new API readiness confirmed in Forever
70938/16001. Three same-VM query pairs over51IDs allocate22464->10800bytes
(51.9% less); exact key sets match. CPU medians0.0608->0.0577ms are close and uncontrolled, so no
FPS claim. SourceSyndicator; profilertrue/scriptProfile0/caps120/30 unchanged.
Queries used locals only; no diagnostic global/frame/wrapper/timer remains.
Fresh2824-file source/history checkpoint+126settings metadata preceded edit;
other1073Lua and newer tooltip/EBS/unitframe work preserved; Syndicator41files
unchanged. No publication/manual sync or item/mail/queue actions by agent.

Native whole workflows/provider-off/other clients/actual cast edges and bank/mail
readiness/populated timing remain. Quick pause uses resume4-20261114T222014Z/CANCEL
first, then stop owned workers/children; save small delta. Reload only if requested
on pause. Historical pause3/C0 records below are superseded by this resumption.
[Exact sources, samples, native scope and next steps](validation/passive-inventory-item-ids-2026-11-14.json).

14 November `TOOLTIP-SCALE-20261114`: whole-tooltip shrinking now has a
HUD ownership correction. Default-anchor/HUD placement restores normal native
UI-relative scale after a prior hover leaves a smaller size; scaled-parent
inheritance is compensated. Explicit TacoTip tooltip_scale remains honored.
The existing Blizzard tooltip, exact (0,30) anchor, native scripts/fonts/health,
input and update cadence remain. No added hook/event/frame/timer/polling.

202 focused scale checks across five client models PASS; pre-change scale leak
reproduced and six compiled harmful controls rejected. Unit/pet/raid and Edit Mode
regressions plus pinned native-update desktop replay PASS. Full 386 scripts /
1074 Lua syntax PASS; every final Lua identity verified.
Fresh 2817-file external source/history checkpoint and 130 settings metadata
entries verified; one runtime owner and one new regression only. No native
client input/reload/settings/profiler writes, external addon edits or publication.
Actual incident writer, native pixels/taint/controller acceptance remain NOT RUN.
The unrelated profiling goal stays paused. Reload OOC and repeat the tiny-tooltip
hover sequence, including professions/scaled buttons then unit/pet/raid/world.
[Requirements, limits and exact source](validation/tooltip-scale-2026-11-14.json).

14 November `BLIZZARD-TOOLTIP-20261114`: unit/raid/pet tooltips now share
Blizzard's existing GameTooltip; no separate FluxUnitTooltip is created. Exact
HUD anchor remains BOTTOMLEFT to FluxWindowFrame TOPLEFT at (0,30); pet happiness
keeps its adjacent anchor. Flux bookkeeping stays in UF, native scripts/health
mixins remain untouched, and native owner callbacks retain update cadence.
Hide/clear/owner handoff retire old callbacks and pet icons; stale leaves cannot
hide newer item/world/unit tips. Six runtime owners and two existing tests changed.

725 focused checks across all five client models and pinned Blizzard update
replays PASS; five compiled harmful controls rejected. Final combined desktop
index: 385 scripts / 1073 syntax PASS. Initial two stale-fixture failures were
corrected and replayed; complete final Lua manifest verified. Fresh external
2816-file source/history checkpoint and 130 settings metadata entries verified.
All other Lua/XML/TOC and settings preserved. Native visual/taint/combat/controller
acceptance remains NOT RUN. Reload out of combat and test rapid unit/pet/raid to
item/world hovers. No client input/reload/profiling/publication or manual sync.
The unrelated profiling goal remains paused.
[Requirements, exact source pins and acceptance](validation/blizzard-tooltip-2026-11-14.json).

14 November COMPLETE PAUSE3. Requested /reload submitted19:53:16CET
(18:53:16UTC); same Forever client returned and settings rewrite/startup observed.
All temporary test code/counters/function pointers are cleared. No profiling or
tests after reload; all workers stopped and resume3/CANCEL stays set. Resume ONLY
when user says continue; re-add optional diagnostics then if needed.

No new product Lua edit in this continuation. Earlier optimizations and newer
EBS/unit-frame/user work remain. Latest exact source gate385scripts/1073syntax
matches current files; docs validation passed before pause. Fresh2820file/history
checkpoint+126settingsmetadata verified; no private settings copies.

Native shared restock callback59.4ms money/52.1ms bag/40.7-42.3ms profession-list;
same8callback identities. Natural30s methods:198Rows calls/2530.85ms inclusive,
64Targets calls/1700.84ms; originals restored. No exclusiveCPU/FPS claim. Rawcast
window0edges and food attempt no active-cast readout do not establish cast cost.
City crafting is incidental, not an item-specific test.

Fresh-ID C0 stays EXTERNAL/BLOCKED:58%desktop full-row allocation saving, but
independent tests expose changed facade/delegated getter lookups and copied
namespace authority. DO NOT APPLY. Correction not started; use followup_task on
continue, capture getters once and prove trusted-owner fallback before retesting.
TinyIndex hoist/global harvest skips remain rejected. Original broad goal,
bank/mail readiness/populated timing and all-client/native acceptance remain.
[Exact pause, reload and resume order](validation/lag-hotspots-pause3-2026-11-14.json).

14 November19:08CET native hotspot: all eight retained slow spans used the same
callback. PLAYER_MONEY took59.4ms; BAG_UPDATE_DELAYED52.1ms; six profession-list
updates40.7–42.3ms. Source points to the pending restock reminder's OnChange /
Refresh / Build path; native function equality connects all three event kinds.
This is shared addon work triggered by incidental user crafting, not a test or
problem specific to the crafted item. The30s window recorded2927callbacks and
12spans>10ms; inclusive timings do not establish exclusiveCPU or an FPS gain.
All temporary diagnostics released; profiler settings unchanged. No productLua
edits by this pass. TinyIndex prototype rejected:136bytes/query saved but
200-item medianCPU61→64us. Next: faithful Followup/GetRows work proof and natural
helper timing before editing; raw cast probe externally tested but unarmed.
The newer EBS profession-rank owner now reports385scripts/1073syntaxPASS; its
changes are preserved. Earlier docs-check failure was stale references during
that work; rerun after the current documentation update. Full LHO goal ACTIVE.
[Exact native rows and continuity](validation/lag-hotspots-native-attribution-2026-11-14.json).

14 November `EBS-PROFESSION-RANKS-20261114`: profession buttons now follow the
currently learned rank after training, including replacements that keep spellbook
slot counts unchanged. Shared EBS assignment covers extra/category/minimap hosts
and badges; utility modifiers and flyouts use the same resolver. Saved assignments,
favorites and deliberately chosen combat spell ranks remain. Modern/legacy books,
localized names, secondary-only skills, passive gathering, cold data and combat
deferral are covered. Skill/learn/world signals use one 250ms burst refresh; a
configured profession utility slot also uses its existing 75ms rebuild debounce.

34,376 focused checks across five client models, three baseline-fail/candidate-pass
pairs and eight compiled harmful controls PASS. Full 385 scripts /
1073 Lua syntax PASS with all Lua identities stable. Fresh external
2,816-file source/history checkpoint and 130 settings metadata entries verified.
Other runtime Lua preserved. No client input/reload/profiler/settings writes or
publication. Native rank training/input/taint/controller/pixels remain pending.
[Requirements, exact identities and native steps](validation/extra-profession-ranks-2026-11-14.json).

14 November18:51CET native attribution continuation: full LHO goal ACTIVE.
Two volatile30s windows ended; both diagnostic globals released. Travel control:
0recipe calls;18service callbacks/max3.0121ms. Natural quest/receipt window:
3recipe calls10.0094ms total/max3.6228ms;1659service callbacks/max41.5553ms;
no observed service span>100ms. Inclusive/current-only; no FPS or causal claim.
Food command/cancel pair submitted; live readout showed no active cast, so
successful cast validation remains pending. Raw cast frame readiness confirmed;
its optional timer plan is not installed. No productLua edits by this pass,
SavedVariables/preferences/newframes/reload. User explained jumping caused /say
and requested the same route; stray text is cleared. Automatic foreground and
background permission retained. Last384/1072pass predates four newer EBS edits
and extra_profession_ranks.lua; preserved, not certified here. All41external
Syndicator files match. Quick pause uses resume3/CANCEL then reviewed cleanup.
[Native values and exact continuity](validation/lag-hotspots-native-attribution-2026-11-14.json).

14 November second RESUMPTION verified: full LHO goal remains ACTIVE.
Current 384scripts/1072syntax PASS; all Lua stable. Professions748cff40
now removes private catalogue seen-record allocations with lazy rank/key arrays;
public rows/references, alias/revocation/rank order, errors, reads and cadence kept.
New durable e34a52c2:3pairs/3063checks/145scenarios;8compiled bad controls;static
peer PASS.121-entry desktop allocation23.96→10.11KiB/query;CPU190→183us median,
overlapping ranges and slower individual samples retained. No native FPS claim.
Fresh2815-file/history checkpoint+126settingsmetadata precedes edit. Other1071Lua,
257assets/85options/7defaults/5licenses unchanged;90copiesmatch;Syndicator41unchanged.
Earlier Craft615d4be and Init69ee82e retained; newer user/group-hover work preserved.
Native27local-only queries after14:44CET reload measured full-list3.54–4.20ms and
121-row catalogue0.90–1.08ms/110672bytes;normal cache hits0.001–0.0068ms/0bytes.
Passive46.593s counters had2Flux ticks>100ms; not callback/FPS attribution.
Unrelated native bag fallback rebuilds all3kinds in actual-source replay, but is
needed for immediate pre-provider live zero/refill. No invalidation suppression.
No watcher installed; saved diagnostic root preservation/coverage gap recorded.
No reload this pass and no temporary global/frame/hook/watch to clean up. Native
after-candidate/all-client/input/taint/pixel checks plus bank/mail races/readiness
and populated-mail latency decision remain. Foreground/background read-only input
permission retained. Quick pause: resume3-20261114T160712Z/CANCEL +activejob/CANCEL,
stop owned child first; no automatic reload unless requested. No publication/sync.
[Current native measurements, source comparisons and remaining work](validation/profession-catalogue-allocation-2026-11-14.json).

14 November17:35CET catalogue allocation change APPLIED; full integration RUNNING.
Professions.lua748cff40 replaces private seen records with index/rank/key arrays;
new durable test e34a52c2. Three pairs/3063checks/145scenarios,8controls,static peer
PASS. Fresh2815-file source/history checkpoint +126settingsmetadata verified.
Only this owner/newtest changed this pass; all older user/group-hover work kept.
No native reload/after-candidate/FPS claim. Native diagnostics remain locals-only;
no watcher installed. Quick pause: write resume3-20261114T160712Z/CANCEL and
integration-job/CANCEL first; stop owned child via0.1s wrapper, then save delta.
[Current applied source and pending integration](validation/profession-catalogue-allocation-2026-11-14.json).

14 November second RESUMPTION: full LHO goal active after14:44CET reload.
All prior383-script/1071-syntax manifest paths still match; Syndicator41files
unchanged. Fresh native Forever70938/interface16001, profilertrue/scriptProfile0,
caps120/30 and Syndicator confirmed. Automatic foreground/background read-only
profiling is authorized; no focus activation or item/mail/queue/settings changes.
Three rotated current-source samples: recipe queries3.54–4.20ms/250–276KB;
catalogue121rows0.90–1.08ms/110672bytes. Normal cache hits0.001–0.0068ms/0bytes.
Passive46.593s overlapping threshold deltas295/27/23/8/2/0/0 (>1/5/10/50/100/
500/1000ms); natural crafting/AH, not causal callback/FPS or old/new comparison.
Actual-source replay proves unrelated delayed-bag updates rebuild all3kinds, but
fallback is needed for immediate pre-provider live depletion/receipt updates.
Do not remove it. Private catalogue allocation candidate is EXTERNAL/in progress;
no addon Lua edits this pass. All native diagnostics so far use locals only;
no temporary global/frame/watch remains to restore. Quick pause root is the new
resume3-20261114T160712Z/CANCEL; stop candidate children/agents first on pause.
Bank/mail producer races/native readiness and populated-mail delay gate remain.
[Native samples and current resume state](validation/lag-hotspots-native-resume-2026-11-14.json).

14 November COMPLETE PAUSE AGAIN — requested /reload submitted 2026-11-14T14:44:27.872850+01:00.
Forever40032/window7995860 verified; reload/settings rewrite observed; no focus
change. No further tests/chat probes after reload. Treat old diagnostics/counters
as cleared. Resume only on explicit "continue"; original broad goal remains.
Current Craft615d4be and Init69ee82e are applied;383scripts/1071syntax PASS,
normalized Lua still matches; final pre-pause docs validation PASS. Preserve newer
group-hover/input work. All settings/assets/features/cadence remain as recorded.
Latest explicit user permission allows automatic read-only profiling chat input
with WoW foreground OR background. Keep focus unchanged and no item/mail/queue or
profiler-setting actions. Two preflight queries succeeded before this reload:
70938/interface16001, scriptProfile0, native profiler true, Syndicator; recipes
5heal/2mana/8bandage. No timing batch/before-after comparison ran yet.
Both account variants and lazy/memo Craft variants stay external/rejected.
Bank/mail producer races/native readiness/latency decision remain pending.
Root/job CANCEL flags set; workers stopped, no active owned child. On continue,
read exact pause record, inspect current source, intentionally clear owned flags,
verify fresh client context and re-add diagnostics only if needed. Next native
slice is short recipe timing plus passive natural cast/item event attribution.
[Exact pause state, new permission, reload boundary and resume order](validation/lag-hotspots-pause-final-2026-11-14.json).

14 November LHO RESUMED by explicit user instruction; full original scope active.
Previous client reload13:27CET is retained; old temporary diagnostics are cleared.
Fresh2,806-file source/history checkpoint +125settings metadata precedes edits.
Current baseline380scripts/1068syntax PASS. Craft615d4be now removes private
recipe/effective tuple allocation and hoists the stateless comparator; every live
query, count/metadata order, fresh output row and existing cache/cadence remains.
Three source pairs/4020checks/90scenarios,3380 independent mixed-filter assertions,
8controls and two peer reviews PASS.500recipes/10selections allocate428–508KiB
less in desktop samples; CPU mixed, no native FPS/retained heap claim.
Earlier Init69ee82e notification copy fix is included in current full validation.
Both account shortcuts remain external/rejected:100-character miss query67us
became123us with guards; no per-bag account rescan existed.

Current whole383scripts/1071syntax PASS, all Lua stable; includes the newer
group-hover owner's changes, preserved against its own identities. Source guard:
1065 other Lua/257assets/84other options/7defaults/5licenses unchanged; one binding
file belongs to that concurrent owner.90 performance-owner copies match read-only;
external Syndicator41 files unchanged. No publication/manual sync/settings writes.
User explicitly permits background read-only profiling chat input for this goal.
Approval issue resolved; foreground/desktop guard still sent0commands. No new
temporary probe is installed; native timing is pending, not inferred from mocks.
Quick pause: cancel active child first via recorded CANCEL paths; all long suites
are cancellable, direct focused tests<=5s. Save delta/interrupt workers; no automatic
reload on a future pause unless requested. Bank/mail authority and native gaps remain.
[Current resume state, permission and pause controls](validation/lag-hotspots-resumed-2026-11-14.json).

14 November `GROUP-GHOST-HOVER-20261114`: the new screenshot identifies the
Flux UIParent separator anchored to `FluxUnitFrame_party4` (old Shared.lua:9452).
It initialized from local IsShown while a group ancestor was hidden; the later
Hide produced no effective OnHide. Separator/atlas initialization and OnShow now
use IsVisible; the separator explicitly disables mouse input. Both hover scans
reject hidden ancestors. Secure casting validates current effective visibility
and actual unit existence, including wrapped children. Prepared secure unit
attribute callbacks clear/rearm overrides during combat reassignment without
requiring mouse movement; leave/hide clears remembered enter ownership.

Requirements include solo empty slots, combat join/leave, party↔raid conversion,
pet/target disappearance and reused unit slots. Existing roster visibility
drivers and original native callbacks remain; no ordinary protected combat
mutation, new frame, event, ticker, state driver, option or saved schema is added.
There is one extra secure attribute wrapper per existing hover surface.

Full 381 scripts/1,069 syntax PASS with all Lua hashes stable. New 120-check
regression/five client models; 9 compiled harmful controls; 3 pairs per old owner
PASS. Two runtime owners and one existing harness changed; one new harness.
All 10 runtime copies match across five installations read-only. Fresh external
2,801-file source/history/index checkpoint and 113 settings metadata verified;
private settings untouched. Native combat/taint/casting/pixels/controller remains
NOT RUN; reload OOC and reproduce the requested real group transitions.
The linked TheMizeGuy guide was reviewed at f928572a9428d29327a96c2549b0068101961c4e
as supplemental guidance; pinned Blizzard contracts remain authoritative.
No client input, preferences, manual sync or publication. The separate paused
diagnostic goal remains paused; no temporary native probes were introduced.
[Causes, source identities, comparisons and pending acceptance](validation/group-ghost-hover-2026-11-14.json).

14 November `PLAYER-GHOST-SECURE-FOLLOWUP-20261114`: user reloaded and still
reports intermittent hovercast interference; screenshot identifies PlayerFrame.
The prior geometric/context candidate is not native-accepted. Actual secure
registration could still arm overrides independently of that visual scan. The
new candidate removes suppressed native-player/legacy-child registrations,
clears their active overrides through Flux's header, balances retained legacy
hooks and restores registration on Blizzard selection. Peer casts remain.
Combat/Edit Mode gates retain all protected mutations outside those boundaries.

User additionally requests literal deletion, including all Frame Stack listings.
That requirement is unsupported by the addon API: Blizzard constructs this
native frame before addon loading and exposes no supported destruction method.
The frame still exists and can remain in normal or hidden-frame inspection.
No global nil assignment, native source replacement, root hide/reparent or
debugger filtering is introduced. Do not report the frame as fully removed.

15 affected desktop scripts and 1,068 syntax checks PASS; 300 casting checks on
five client models, 9 compiled harmful controls and 3 old/current pairs PASS.
Other script observations remain historical; no fresh whole-suite claim. Two
runtime owners/one existing test changed; 10 installed copies match read-only.
Fresh external 2,799-file source/history/index checkpoint and 113 settings
metadata entries verified; private settings untouched. Candidate native casts,
combat/taint/controller acceptance remains NOT RUN. Existing background/user
retest preference retained; no client input, preferences or publication changes.
[Failure, implementation and API limit](validation/player-ghost-secure-followup-2026-11-14.json).

14 November USER-REQUESTED COMPLETE PAUSE — client RELOADED before pause.
Only/reload was sent to the verified Forever70938 process40032/window7995860 at
12:27UTC; loading screen, SavedVariables rewrite and return to world/startup
messages observed. No temporary code/probe was installed afterwards. Treat all
earlier temporary globals/hooks as cleared. Re-add diagnostics only after the
user says continue, with fresh native baselines/preferences/context checks.
All goal workers, including the pending AH review child, are interrupted.

Current main6b444eba4573092b57919ee3e497d86d2ebb3ece; preserve newer user work.
Applied since the last whole run: Inventory/Init.lua69ee82e... plus new
notification_context_work b1daa747...;3pairs/1001 producer checks/42context
checks/8controls/7installed focused scripts PASS. No delivery/cadence changes.
Craft main3d539a... is untouched: lazy70344d... REJECTED (cold/warm helper
interleaving); memo fb2c8b... NOT SAFE (nested Index/Item count seams). Both stay
external. Account Store/Summaries v1 is rejected for record/Sync provenance;
v2 was being prepared, unsealed/unapplied. No bank/mail remedy was applied.

Latest full379scripts/1067syntax is historical: current tree also includes the
new Init/test and five Lua changes from another mouse/ghost-hover owner. Preserve
those changes; current whole integration/reference/docs checks are pending.
External pause checkpoint2804files/history +125settings metadata is verified.
The exact pause record includes hashes, prototypes, peer counterexamples, source
delta, constraints and ordered resume steps. Goal scope stays intact; PAUSED,
not complete. Resume only on explicit continue.
[Exact pause and resume state](validation/lag-hotspots-pause-2026-11-14.json).

14 November `PLAYER-GHOST-HOVER-20261114`: user confirms invisible native
`PlayerFrame` intercepts hover casting on Forever. The replaced root now has an
empty hit rectangle in addition to the existing artwork/mouse suppression.
Flux's binding scan also excludes suppressed roots/subtrees instead of treating
their shown geometry as an active hover surface. Native player/unit/vehicle/aura
handlers and independent pet/resources controls remain; original hit rectangle
and input policy restore on Blizzard selection. Combat/Edit Mode gates retained.

Three runtime owners/two existing harnesses; 3,387 focused checks across five
client models and 20 harmful controls PASS. Three repeated comparisons per old
owner reproduce the regression; three candidate repeats PASS. Initial full snapshot
379 scripts/1,067 syntax PASS; refreshed combined 380 scripts/
1,068 syntax PASS after unrelated inventory changes; current Lua hashes stable.
At the original seal 1,062 other Lua and 252 assets/XML/TOCs/fonts were unchanged;
newer inventory work is retained. All 15 runtime copies match read-only. Fresh
external 2,797-file source/history/index checkpoint and 113 settings metadata
entries verified; no private settings copied. No new callbacks, options or data.
Candidate native hover/combat/taint/controller acceptance remains NOT RUN; reload
outside combat and test the former rectangle plus the visible Flux player frame.
Blizzard's retained object may still appear in Frame Stack with show-all filters.
No client input/focus, settings/profiler writes, manual sync or publication.
[Evidence and exact source pins](validation/player-ghost-hover-2026-11-14.json).

14 November LHO continuation sealed: five additional runtime owners reduce
profession scan/output-lookup allocations, warm bulk capacity reads and large AH
grid repaint work. Fresh2,792-file checkpoint precedes edits. Three paired source
comparisons/slice;770 profession/capacity checks and13 controls; AH206,520 new
checks/11,404 geometry checks/17 controls/44 existing scripts; independent reviews
PASS. Current combined379 scripts/1,067 syntax PASS with every Lua hash stable.
Original maxN AH native slot pool retained; eager regions paint only on viewport
visits. Small7/20-row desktop cases add10–40us/refresh and20-row warm allocations
add44KB/10 refreshes; no extra passive tooltip queries/callbacks or cadence change.
Source guard:1,057 other Lua/257 assets/85 options/7 defaults/5 licenses unchanged;
80 cumulative runtime copies match across five installations read-only; external
Syndicator41 files unchanged. New files need a later reload; disk identity does
not prove loaded code. Empty-mailbox native observation is separate and unpaired.
Actual-source closed-bank/stale-mail counterexamples remain unresolved; no bank
or mail remedy was applied. User requires populated native timing before accepting
the exceptional mail delay. Broad goal remains active; native whole-workflow FPS,
other clients, provider-off, pixels/controller/secure-VM acceptance remain pending.
[Current identities, results and remaining work](validation/lag-hotspots-continuation-2026-11-14.json).

14 November `ADDON-PUBLICATION-20261114`: the user requested publication of the
full current addon snapshot to DoctorFlux/FluxUI on main, including completed
auction, consumable, UI/options and casting/inventory work. Preserve all newer
source and licenses. This task updates documentation, the stale commerce renderer
regression and Git state. The regression permits fewer hidden-row writes while
retaining native repair, opacity, reentry and exact-error propagation checks;
addon runtime code, settings and client/profiler state remain under their owners.

Both author and committer must be DoctorFlux
`<100806234+DoctorFlux@users.noreply.github.com>`, with no co-author trailers.
The existing identity hooks remain active. Five identity regressions and all four
prior reachable commits passed; GitHub's pre-upload contributor API lists only
DoctorFlux. Check the new main history and contributor/workflow state after push.
GitHub has no contributor blacklist; enforce publication metadata at each upload.

Current source evidence: 365 fresh desktop scripts passed; 52 auction/shared-grid
dependents were replayed after the last concurrent UI edits, with all Lua stable.
The index retains 14 unchanged meter/threat observations from their owner instead
of rerunning them. All 1067 syntax hashes match current files; 379 passing
observations are recorded. The adapted commerce test rejects four compiled
harmful controls. Existing native
acceptance gaps remain; publishing establishes no new native/performance result.
External source/history/index checkpoint: 2794 files and
113 settings metadata entries; no private settings copied.
No branch/reset/force push/tag/repository replacement. [Publication record](validation/addon-publication-2026-11-14.json).

14 November LHO actual producer audit reproduces two unresolved synthetic
counterexamples using installed Syndicator code: cold closed-bank completion5→0,
and an old cold-mail job overwriting newer inbox facts (including equal-cardinality
wrong IDs). Three baseline repeats/three isolation pairs per fault/three extra
controls;38checks/run. External41 files unchanged. No bank/mail remedy applied.
Native tri-state count/provenance and persisted handoff need proof; header counts
alone cannot validate mail identities. User requires native populated-mail timing
before a fallback-delay decision; the available empty mailbox cannot establish it.
[Causal evidence and pending decisions](validation/lag-hotspots-provider-counterexamples-2026-11-14.json).

14 November lag continuation: after the fresh 2,792-file source/history checkpoint and 375-script/1,063-syntax baseline gate, three commerce owners reduce recipe-scan allocations, select only relevant modern output aliases and reuse warm owned bag facts within a capacity call. Three paired source comparisons pass 770 focused checks/set and reject 13 compiled harmful controls. Affected installed checks pass 61 scripts with all 1,065 Lua hashes stable in that run; independent review reproduces 770 checks. Every profession native scan, craft invalidation and publication remains; aliases, partial/closed recipes, public overrides, cold bag retries and existing link return values remain. Desktop timings and allocation samples establish their modeled scope; no profession/vendor native CPU or FPS comparison is claimed. Keep the earlier full run historical until a new combined run seals current source.
[Source comparison and limits](validation/lag-hotspots-commerce-continuation-2026-11-14.json).

14 November LHO empty-mailbox native observation: user opened the mailbox;
Forever70938 reports inbox0, Flux mail0, Syndicator source, reliabletrue and no
pending native mail command. Three 1,000-call GetInboxNumItems trials take
0.0418/0.0405/0.0398ms. Same-session _FluxUI native profiler counters over12.922s
increase230 for >1ms and0 for >5/10/50/100/500/1000ms; nested counters are not summed.
This is an unpaired existing-city observation, not a before/after FPS result or
populated/cold-mail latency measurement. No mail/item operations, activation,
profiler preference changes or persistent probes. User requires in-game measurement
before accepting the stale-mail fallback delay; that decision remains pending.
[Exact scope and readouts](validation/lag-hotspots-empty-mailbox-2026-11-14.json).

14 November casting/inventory lag (LAG-HOTSPOTS-20261114; LHO-01–13):
pre-edit 367 scripts/1,055 syntax PASS with unchanged source; external 2,781-file
source/history checkpoint and 125 settings metadata entries, no private copy.
Eight measured slices now change eleven runtime owners: protected cast/VFX helpers,
same-call macro metadata, dirty-bank aggregation/publication retries, merged potion
needs, live mail capacity, bulk merchant queue retirement and hidden merchant paints.
Three pairs/slice; 46,925 focused checks/set; 71 compiled harmful controls rejected.
Final 375 scripts/1,063 syntax PASS; full source stable throughout. Craft/pending
integration adds 380 checks/120 scenarios. Independent reviews caught and fixed
two bank retry/reentry cases; native getters slowed the AH paint experiment, so
original UI bytes were restored. All 257 assets/XML/TOCs, 85 options/bindings,
7 defaults/settings owners and 5 license files unchanged; all 55 owned files match
across five installed copies read-only; external Syndicator's 41 files unchanged.
Forever70938 native watch:2 gaps52–55ms,0observedFluxcallbacks>10ms,0newLuaerrors;
not FPS attribution. After user reload and a specific foreground exception, food
rank4 starts/stops were submitted; Interrupted and eight Pumpernickel/count8 are
observed with cast cleared. No buying/selling/deletion, craft materials, focus
activation, profiler preferences, manual sync or publication. Other native timing,
provider-off/client/pixel/controller acceptance remains pending. Documentation validator PASS.
[Requirements, remaining acceptance and evidence](LAG_HOTSPOT_OPTIMIZATION.md).

14 November `AUCTION-PASSIVE-REFRESH-20261114` / AHR-105/106, build
`AH-restock-explicit-start-20261114-r27`: opening the Restock tab prepares missing
targets once. Filled known items/tiers are skipped. Bag, mail and profession
updates refresh counts without canceling a search, replacing upgrade choices or
restarting completed work. A user-started initial stock-loading wait can resume;
matching purchase receipts still prepare the next shortage. Buying and upgrading
retain their separate player choices. An actual setting edit can replan once.

Loot & Items → Restock now has independent AH upgrade prompt options: healing
and mana on by default, bandages off. Saved choices are per character. Turning
one off keeps its current-tier direct/crafting restock and rejects stale upgrade
actions. The compact native actions read Keep / Block, with full tooltip labels;
unchanged enabled states are not rewritten on passive refreshes.

The explicitly requested modern Scan all restock remains a full pricing action.
Old AH remains per-item scan/buy without Scan all. The latest opening-shortages
request supersedes earlier filled-tier discovery on opening, not manual scans.
76 affected scripts/82 syntax files PASS; 440 passive checks/20 client-provider
models; 3 matched baseline/candidate trials and 11 compiled harmful controls.
Other test observations remain historical; no whole-suite or meter test rerun.
All 5 installed copies match the 6 runtime files read-only. Verified external
checkpoint: 2780 source files/all-ref history and 129 settings metadata entries;
no private contents copied/restored. Main/.githooks and concurrent work retained.

Native flicker, text fit, controller, protected input/taint and performance remain
NOT RUN. No client input/reload, upgrade acceptance, purchase or profiler change.
Reload when ready. Meter work remains with its separate agent. [Evidence](validation/auction-passive-refresh-2026-11-14.json).

14 November `POTION-MINIMUM-RESTORE-20261114` / AHR-104: healing and mana
potion tiers use their minimum restore across the whole addon. A larger maximum
cannot promote a lower-floor potion: 500–1500 loses to 600–800; 650–700 can upgrade.
The shared classifier supplies minimum health/mana/effective values; maximum
metadata remains available. Food, water and bandage ranking is preserved.

Potion buttons, Best ranking, cached recipes, vendors, AH choices and automatic
junk use the same floor. Old saved potion refs/vendor observations and restock
thresholds migrate only after verified classification. Unknown old facts remain
saved but cannot compete/promote as verified minima. Potion-only cached effect
text/axes preserve floors across tooltip gaps. Targets/price limits/manual Junk
priority and explicit AH choice/purchase presses remain under existing owners.

74 affected scripts and 79 syntax files PASS; 510 checks/50 minimum-ranking models,
388/20 restore checks; 10 compiled harmful controls rejected; 3 matched trials.
Global verification is explicitly incremental: other test observations remain
historical, not a whole-suite rerun. Meters are excluded and left to their agent.
Five installed copies match the 5 runtime files read-only. External checkpoint 2778
source/history files and 129 accessible settings metadata verified; no private
contents copied/restored. Main/.githooks/newer work retained; no publication.

Minimum-ranking native acceptance is NOT RUN. Existing background test preference
continues; no client input/reload, purchase, upgrade acceptance or profiler change.
Reload when ready to apply the new shared logic. [Evidence](validation/potion-minimum-restore-2026-11-14.json).

Full validation: 365 scripts and 1053 Lua syntax files PASS; complete current Lua manifest verified.

14 November `METER-CONTROL-RECOVERY-20261114`: audited the supplied Damage Taken /
Dispels placeholder screenshot and lost Current defaults. The current meter files
match the 14 November recovery checkpoint; 13 November's explicit selection
withdrawal is the cause. Restored the narrow selection functions and setup action
without replacing whole files or losing tooltip/header/newer work.

Fresh Gethe Retail/Forever pins remain 297d7aaaa736f346b3e036f38ee088eaf7f8c07f /
bebcb6bf309cf41b41bd74f8ca651e6a105b2676. Native-generated caches and original
proxy Pick preserve native data/responders; provenance checks reject modified
fields/methods and misleading New Window labels. No private setters/menu cache
writes/history reset. 476 control checks and both exact native menu replays,
12 focused scripts, 3 matched baseline-fail/candidate-pass pairs and 7 compiled
harmful controls PASS. Scope is desktop behavior/provenance, not native VM/FPS.

Verified external checkpoint `meter-recovery/checkpoint-20261114T081300Z`:
2771 source files/all-ref history, main/.githooks, 53 settings metadata entries;
no private settings contents copied/restored. No client control/input/clipboard,
profiler write, manual sync or publication. Existing user-native test route:
reload outside combat, choose Dispels/Interrupts layouts, verify Current/two fights
and later manual Overall/history. Native/controller/taint/pixels/CPU/FPS NOT RUN.
[Requirements](METER_STANDALONE.md#meter-control-recovery--14-november-2026);
[exact evidence](validation/meter-control-recovery-2026-11-14.json).

14 November `AUCTION-COMPACT-UPGRADES-20261114` (AHR-102/103), build
`AH-restock-compact-upgrades-20261114-r26`: upgrade cards now occupy 44px instead
of 174px. A 24px candidate icon sits beside Upgrade; Keep and Blacklist form the
second action row. Candidate name, restore comparison, unit price and current
funds remain in the native tooltip. Each candidate still needs its own choice.

Cell order is healing potion, mana potion, bandage, spell reagents, consumable
configuration, then other items. Preset/source metadata drives ordering; names
and item IDs break ties only within each group. Merged manual/preset targets and
virtual proposals without a saved tier retain preset priority. Proposals stay
bound to row identity while sorting. No new API, saved-root/default change or
automatic purchase was introduced; old-AH per-item behavior remains.

Inline 1220/20, confirmation 672/20 and geometry 780/20 checks PASS; 8 compiled harmful
controls rejected with 3 matched baseline/candidate trials per regression.
All auction scripts and 1053 syntax files PASS; owned source hashes and recovered
TOC retained. The wider run has a separate meter failure; the user assigned meter
work to another agent. No further meter inspection, testing or changes in this task.
Verified external checkpoint 2776 files/history and 129 settings metadata; no private
values copied. Four runtime files plus two relevant tests changed. Five installed
copies match read-only. Native capture found the user crafting with AH closed;
no input/reload was sent. Native compact pixels/fonts/controller/other-client
acceptance and CPU/FPS remain pending. [Evidence](validation/auction-compact-upgrades-2026-11-14.json).

14 November `AUCTION-INLINE-UPGRADES-20261114` / AHR-96–101 is current,
build `AH-restock-inline-upgrades-20261114-r25`. Healing, mana and bandage
upgrade choices are independent controls on their cells; no modal prompt.
Accepting changes the saved tier only. Three default-on global settings keep
weaker items until a better usable tier is carried; explicit manual Junk wins.
The shared item blacklist and default-on `discolored` healing-name substring
toggle affect Best, the healing button, AH planning and junk replacement checks.
No item-ID/full-name tier catalogue was added. Buying still needs a player press.

`FLUX-SOURCE-RECOVERY-20261114` recovered an unrequested source replacement
around 08:32 Copenhagen: 79 whole Lua files, lost fixes in 4 shared files and 45
TOC load entries. This restores chat anchor ownership, options Skin loading,
meter/threat presentation and other verified fixes while retaining the new work.
Writer remains unknown; the user reports no other writer known. Existing outward
sync is not evidence of the cause. No checkout/reset or saved settings restore.

Final 365 scripts/1053 syntax files PASS. Inline 880/20 profiles, shared button
exclusions 240/10 profiles and global junk 1230/30 scenarios PASS; 22 compiled
harmful changes rejected. Chat's reported source fails in 3 repeated comparisons;
recovered source passes. All 91 checked files match across five installations.
Two external source/history checkpoints 2772/2773 files and 129 settings metadata
each verified; private values/archives remain outside AddOns. Main/.githooks and
existing dirty work retained; no commit/push.

Forever background observation after a reload shows the meter skin and Threat
pane restored. A chat diagnostic produced no result while the player moved and
is excluded from acceptance; input tests stopped. Options opening, new inline
native interactions, accepted upgrades, real buys, controller, other clients,
taint and CPU/FPS remain pending. No agent purchase/upgrade/reload was sent.
See [inline evidence](validation/auction-inline-upgrades-2026-11-14.json) and
[source recovery](validation/flux-source-recovery-2026-11-14.json).
This supersedes the older r24 modal and explicit automatic-Junk description below.

14 November Forever potion discovery and upgrade approval (AUCTION-POTION-BROWSE-20261114;
AHR-93–95), build AH-restock-potion-browse-20261114-r24. Upgrade/Keep current now
precedes any saved tier, inherited policy or previous-item junk change. Decline,
Escape, combat, closing and stale callbacks preserve current state; buying needs
its own player press. This supersedes AHR-92's automatic promotion.

Independent health/mana range parsing avoids mixed axes and cooldown/level
digits. A completed empty modern phrase browse gets one name-free potion-category
fallback. An unsent request owns no results; the ready event wakes its existing
bounded wait and native unavailability is shown explicitly. Dynamically linked
spell text loads once per item/job; late text can revive a negative parse once.
Loaded item metadata is no longer re-requested by the pending classifier, which
otherwise repeatedly lost retry evidence to duplicate metadata events. Known
unusable items are rejected before parsing. No new potion-name/tier/ID catalogue;
old AH remains per-item only. Existing price/vendor/buy owners and limits remain.

Actual Forever1.60.1.70938 background test: normal Buy was empty too and the native
queue was unready. Fresh Mario Super character login restored62 catalogue rows.
Native text parsed Superior Healing900 health at level35 and Greater Mana900
mana at requiredlevel31. r24 Restock now displays an upgrade from Greater Healing
to Superior Discolored Healing at22s93c/unit. Its Upgrade/Keep current prompt is
left unanswered; the current5/5 target remains unchanged. No buy/upgrade decision
was submitted. Native mana prompt follows the healing choice and remains pending.
Other clients, accepted native tier/junk persistence, buys/receipts, controller,
taint and CPU/FPS remain unverified. Earlier misfocused/protected exploratory
probes are excluded from acceptance; errors retained, no addon disabled.

Confirmation672/20 and restore/browse388/20 focused checks PASS. Three matched
before/after trials per20 models for each regression retain raw outcomes.
363 scripts/1051 syntax;15 harmful controls;complete current Lua manifest PASS. Four verified external source/history checkpoints
(2769/2770/2771/2771 files), each129 settings metadata; no private contents copied.
All five installed copies match five runtime files read-only; no manual sync.
Main/.githooks/concurrent work retained. Explicit background testing authorization
used; no foreground/global input/clipboard, settings/profiler write or publication.
[Requirements/native scope](AUCTION_RESTOCK.md#forever-empty-browse-and-restore-amounts);
[exact sources and acceptance](validation/auction-potion-browse-2026-11-14.json).

14 November usable potion upgrades (AUCTION-POTION-TIER-20261114; AHR-92), build
AH-restock-potion-tier-20261114-r20: per-item AH preparation now checks stronger
usable healing/mana tiers even when weaker potions fill the target. A real
eligible listing promotes the saved tier and fills the full stronger target;
the next purchase still needs a player press. Old AH remains per-item only.
Fresh kind catalogues are reused at the same level; character-level changes
invalidate usable-only coverage so newly usable tiers can be found immediately
on the next preparation. Caps/No limit, restrictions/vendor policy, target0 and
native gesture guards remain. New240/20 checks and existing potion580, speed492,
price820, craft836 and scan284 checks PASS. Three matched before/after trials
per20 models retain raw tier/query observations. 361 scripts/1049 syntax;3 controls;complete current Lua manifest PASS.
The obsolete filled-legacy-idle assertion was updated; safety checks retained.
Verified external2767-file source/history checkpoint and 129 settings metadata;
private contents not copied. No new event/timer/poll/frame/settings. Main/.githooks
and concurrent work retained. No foreground/input/clipboard, settings/profiler
write, manual client sync or publication. Native eligibility/search/tier display,
buying/provider coexistence/controller/taint/CPU/FPS remain NOT RUN; existing
user-native test route retained.
[Requirements/native checks](AUCTION_RESTOCK.md#usable-potion-tier-upgrades-during-per-item-scans); [evidence](validation/auction-potion-tier-2026-11-14.json).

14 November restock mail cadence (AUCTION-MAIL-SPEED-20261114; AHR-91), build
AH-restock-mail-speed-20261114-r19: the existing Opening Speed sets the interval
between restock take requests, including0. Reply time is no longer added; an
acknowledged batch does not wait for a full inbox rescan before every attachment.
Initial snapshot and live header/COD/GM/item/quantity/receipt/free-space/native
command checks remain. Snapshot publication wakes the same worker. Successful
message compaction preserves cadence; abort/failure resets it. Setting changes
update an active deadline. Ordinary Select/Open All settings/behavior remain.
Focused940/20, existing mail3100 and automation1260 PASS. Three matched trials
per20 models at six speeds; simulated200msreply with0.5speed gives requests at
0/0.5/1.0 versus0/0.7/1.4. These are desktop timestamps, not native throughput.
360 scripts/1048 syntax;5 controls;complete current Lua manifest PASS. Verified external2765-file source/history checkpoint
and 129 settings metadata; no private contents copied. No new event/frame/ticker/
poller; existing timers and48-read/1ms/8s scan bounds retained. Main/.githooks and
concurrent work preserved. No foreground/input/clipboard, settings/profiler write,
manual client sync or publication. Native collection/throughput/taint/CPU/FPS
remain NOT RUN; retain the user-native test route.
[Requirements/native checks](AUCTION_RESTOCK.md#restock-mail-opening-speed); [evidence](validation/auction-mail-speed-2026-11-14.json).

13 November duplicate system debuffs (UNIT-DEBUFF-OVERLAP-20261113; UDO-01–03):
user confirms the two XP icons show the same effect. The larger native own group
now also requires a player-origin flag; exact PLAYER/!PLAYER ownership filters,
other-player effects, own sizes and separate same-spell instances remain.
100 focused checks PASS; exact baseline and four harmful variants rejected;
359 scripts/1,047 syntax PASS with the complete current Lua manifest verified.
Native filter overlap is a hypothesis, not captured C behavior; actual XP removal,
player/pet/vehicle metadata, pixels/tooltips/controller/taint/CPU/FPS NOT RUN.
Verified external 2,758-file source/history checkpoint; 70 settings metadata entries,
no private values copied. One native predicate; no new driver/resources/settings.
Direct correction/user-native route retained; reload OOC and retarget. No game
input/focus/clipboard, settings/profiler writes, manual sync or publication.
[Requirements/native steps](14-unit-frames.md#duplicate-system-debuffs--13-november-2026); [evidence](validation/unit-debuff-overlap-2026-11-13.json).

13 November steady craft completion and measured restock work (AUCTION-CRAFT-STEADY-20261113;
AHR-89/90), build AH-restock-craft-steady-20261113-r18: known same-job craft items
remain visible/disabled during bag settlement; reliable counts update in place
and completion hides once. Actual service/driver/storm/HUD regression412/20
passes, including coalesced outputs, partial/no-output cancellation and unsafe
tokens. A public observed cast can hold presentation only, never credit inventory
or authorize another craft. Legacy name-mismatch fallback remains native UNKNOWN.
Data1900/20: an80-row refresh cuts deficit/bag reads160→80 and mail reads320→80;
service carried reads275→250 per25 refreshes. UI63063 plus render1020/integration290
pass: identical paints do no avoidable setter/layout/show/hide work; quantity-only
updates avoid reflow. Three matched trials per20 data/service and5 proc-enabled
UI profiles; counts are desktop work, not native timing/atlas/FPS evidence.
358 scripts/1046 syntax;16 controls;complete current Lua manifest PASS. Verified external2758-file source/history checkpoint
and 129 settings metadata; private contents not copied. One job-owned START
observer; no new timer/poller. Old per-item AH, modern full scan, settings and
native click/receipt owners preserved. Main/.githooks/concurrent work retained;
no foreground/input/clipboard, settings/profiler write, manual sync or publication.
Native ordering/art/controller/taint/CPU/FPS remain NOT RUN; existing user-native
test route retained.
[Requirements/native checks](AUCTION_RESTOCK.md#stable-craft-completion-and-restock-work); [evidence](validation/auction-craft-steady-2026-11-13.json).

13 November 20:38/20:39 secret texture and tooltip follow-up
(TOOLTIP-VISUAL-FOLLOWUP-20261113; CLASS-TIP-01–03): both class-icon paths now
filter UnitClass filenames through the existing safe-string helper before
concatenation. Restricted class data hides stale art until public data returns;
ordinary art/fallback/corners/settings remain. 560 icon and 766 diagnostic checks
PASS; checkpoint concatenation fails; four harmful variants rejected. Full
355 scripts/1,043 syntax PASS. External 2,753-file source/history checkpoint and
129 settings metadata verified; private contents not copied. The new color error
names _FluxUI taint, but the originating field/build/reload status are unknown.
Tooltip resolution remains UNRESOLVED. Existing taint logs predate this report.
Reload out of combat; if it recurs run /fluxinput tooltip and hover within three
seconds, then share the printed field/writer/build lines. Opt-in metadata only;
no native tooltip data/actions/hooks, logging/profiler change or idle driver.
Prior diagnostics/settings/roots retained. Native class/tooltip resolution,
pixels/controller/taint/CPU/FPS NOT RUN. No client control/sync/publication.
[Requirements and steps](SECRET_TOOLTIP_METER_ERRORS.md#secret-class-texture-and-tooltip-provenance-follow-up);
[evidence](validation/tooltip-visual-followup-2026-11-13.json).

13 November 20:29 world-cursor tooltip follow-up (WORLD-TOOLTIP-20261113;
WORLD-TIP-01–04): binding ownership, spellbook hints, protected-gear flags and
consumable separators use private weak-key tables. Native clear/hide callbacks
no longer write these fields on shared GameTooltip. Content/deduplication,
HUD/cadence, native APIs/processors, input owners and settings remain. 115 new
bookkeeping checks; 66 spellbook checks; five pre-fix source cases and five harmful
variants rejected. Full suite: 353 scripts and 1,041 syntax checks PASS. Verified
external checkpoint: 2,750 files/history and 129 settings metadata entries;
private contents not copied.
Gethe Retail/Forever pins rechecked. The report lacks originating taint/source/
build attribution;native resolution is NOT RUN. Reload out of combat and retest
world units before/after addon hovers and in combat. Existing user-native route
retained;native pixels/controller/taint/CPU/FPS pending. No new frame/hook/event/
timer/poll or client/input/settings/profiler/publication operation.
[Requirements and native steps](SECRET_TOOLTIP_METER_ERRORS.md#world-cursor-follow-up-at-202955);
[evidence](validation/world-tooltip-state-2026-11-13.json).

13 November old auction-house per-item flow (AUCTION-LEGACY-ITEM-20261113; AHR-88),
build AH-restock-legacy-item-20261113-r17: old AH has no Scan all restock control
or bulk-scan backend. The main action prepares one shortage and its relevant
recipe inputs/current potion kind, buys one listing per player press, then
prepares the next after its receipt. Even retained full-scan requests use this
path. Old help describes Search then Buy; modern explicit full scans remain.
Saved settings, caps, excess policy and native purchase/receipt guards are
preserved. 352 scripts/1040 syntax PASS with complete current
Lua manifest; three harmful controls rejected. Initial obsolete price-policy
fixture failure and its correction are retained in evidence. Verified external
2750-file source/history checkpoint and95 settings metadata;
private contents not copied. No new event/timer/poller; one fewer old-AH button.
Main/.githooks and concurrent work retained; no foreground/input, settings or
profiler writes, manual client sync or publication. Native transactions, layout,
controller, taint and CPU/FPS remain NOT RUN; use the existing native test route.
[Requirements/native checks](AUCTION_RESTOCK.md#old-auction-house-per-item-searches); [evidence](validation/auction-legacy-item-2026-11-13.json).

13 November meter title alignment (METER-TITLE-20261113; METER-TITLE-01–03):
native labels recover Threat's five-pixel inset/shared baseline when the initial
width is zero, the first hidden pane opens or native anchors/width reset. Combat
resize uses existing deferred header refresh. One guarded show hook per native
session pane; no new frame/texture/timer/event/poll. Original geometry restores
on release; native localized text/menu/input/controller owners and saved data
remain. 206 skin checks PASS; exact checkpoint baseline rejects 25 new cases
(27 final failures including two hook-count expectations). Full352 scripts/
1040 syntax PASS with complete current Lua manifest verified. External2748-file
source/history checkpoint and76 settings metadata verified; private contents
not copied. Prior direct implementation/user-native test route retained.
Native pixels/localized clipping/input/controller/taint/CPU/FPS NOT RUN. No
foreground/input/clipboard control, settings/profiler writes, manual sync or
publication. Reload out of combat and compare reopened pane titles with Threat.
[Fix and native steps](METER_STANDALONE.md#header-alignment-recovery--13-november-2026);
[evidence](validation/meter-title-2026-11-13.json).

13 November fast auction restock and usable pending item buttons
(AUCTION-SPEED-READY-20261113; AHR-81–87), build AH-restock-speed-ready-20261113-r16:
routine preparation prices the next shortage and its recipe inputs, then prepares
the next item after its receipt. Explicit Scan all restock retains full-list and
filled-target potion upgrades. Three direct purchases take1 query before the
first ready item and3 total, versus4 and6 before, with3 player presses in both
desktop models; these are query counts, not native timing. Item buttons remain
32–44px with exact1px gaps and ordinary pressed art. Only visible actionable
items have private proc glow; busy/submitted/closed/combat states stop it.
Crafting updates remaining planned output quantities automatically. The mailbox
Restock button/adjacent checkbox are removed; settings and the selective worker
remain. Closed-profession mail→bank/vendor progression uses durable owned recipe
facts across serialized reloads. Partial alias/roster responses preserve complete
facts; live crafting still verifies ownership, materials and output. Snapshot
dispatch fixes storm-listener mutation; strict receipt reconciliation protects
new transit from stale mail. Full-bag mail retry is covered by the owner tests.
352 scripts/1040 syntax;complete current Lua manifest PASS. Current harmful controls and exact
source identities are linked below. Verified external2743/2745-file source/history
checkpoints and95 settings metadata each; private values not copied. Main and
.githooks retained; concurrent work preserved. No foreground/input, settings/
profiler write, manual client sync or publication. Native protected transactions,
mail/bank/vendor coexistence, login persistence, proc/pressed art/clipping,
localized/controller behavior, taint and matched CPU/FPS remain NOT RUN. Use the
existing user-managed native test route across all five clients.
[Requirements/native checks](AUCTION_RESTOCK.md#fast-purchases-and-usable-pending-item-buttons); [evidence](validation/auction-speed-ready-2026-11-13.json).

13 November auction follow-up overview (AUCTION-FOLLOWUP-ITEMS-20261113;
AHR-74–80), build AH-restock-followup-items-20261113-r13: every current-step item
has a sorted icon and physical quantity; icons shrink/wrap inside one ordinary
stage hit/focus host. Caption is larger, outlined and contrast-backed. Matching
live bank/vendor/mail contexts glow; cached bank views, closed contexts, waiting,
completion and combat do not. One press delegates all scoped step items through
existing owners, without unrelated targets or duplicate submitted work.
Loot & Items → Restock has independent auction follow-up automation (default off),
compatible with both existing bank/vendor auto settings. No limit defaults on for
new/unset items; existing positive AH caps are preserved. With it off, zero is a
real cap; saved craft/potion source policies retain the mode. Explicit Scan prices
all listed items including full/zero/free-route inputs. Full weaker healing/mana
stock can upgrade its saved tier and fill the entire stronger target. Clear pending
is absent. Grouped Auctionator availability stays distinct from one-item bids.
348 scripts/1036 syntax PASS with complete current Lua manifest;36 harmful controls
rejected. UI16763, actual-owner integration270, automation800, price788 and scan340
checks PASS. Fixed readiness recursion, scoped vendor price fallback and bounded
failed-auto retry. External2729-file source/history checkpoint and95 settings
metadata verified; private values not copied. Concurrent minimap work preserved.
No foreground/input, settings/profiler writes, manual sync or publication. Native
operation/glow/pixels/controller/taint/persistence/CPU/FPS remain NOT RUN; retain
the existing user-managed reproduction across all five clients.
[Requirements and native checks](AUCTION_RESTOCK.md#item-overview-follow-up-automation-and-explicit-price-limits);
[evidence](validation/auction-followup-items-2026-11-13.json).

13 November side-grid border/layering (MINIMAP-SIDE-BORDER-20261113;
REQ-MBL-24/25): the screenshot's clarified defect was minimap cluster/clock
layering over buttons. The screen-side root/gate/native-template widgets now use
HIGH; embedded mode restores MEDIUM. Actual FluxBorder is applied once to a
mouse-disabled decorative host inside the existing secure visibility gate.
Border/backdrop inherit hover and secure combat hiding, scale and inactive/empty
grid visibility. The backdrop stays above native chrome but below buttons, with
border below existing flyout arrows. Native map/clock frames and handlers, grid
geometry, saved settings/actions and dynamic minimum behavior are preserved.
2794 actual border/arrow checks,30 atlas/legacy-scale cases,seven harmful controls,
three paired layer trials and nine existing integration scripts PASS. Broad
snapshot:341 pass/four unrelated auction failures;1033 syntax PASS. Concurrent
auction work is preserved; the snapshot is not a claim about later global files.
External2724-file source/history checkpoint and99 settings metadata verified;
private values not copied. No new poll/event/driver;one lazy host plus the shared
border's two frames/normal textures. Native visual/input/taint/controller/CPU/FPS
remain NOT RUN; reload out of combat and use the retained user-native route.
No foreground/input, settings/profiler write, manual sync or publication.
[Requirements and acceptance](MINIMAP_EXTRA_LAYOUT.md#screen-side-border-and-minimap-clock-layering);
[evidence](validation/minimap-side-border-2026-11-13.json).

13 November action/badge/extra counts (ACTION-COUNT-REFRESH-20261113; ACR-01–05): normal bars now receive light bag-count publications; validated spell-use events refresh count/tint through existing coalesced lanes. Count-held form settle also restores badge tint. Two watch owners; no new frame/timer/poll/hook/scan or secure action change. Read-only Gethe five-client pins and Bartender4/LibActionButton/installed ButtonForge comparison retained. 666 focused checks across five client models/both providers; three exact checkpoint pairs reject224 old failures; seven harmful controls rejected. Full343scripts/1031syntax PASS with current complete manifest. External2712-file source/history checkpoint and47 settings metadata verified; private values not copied. Concurrent auction/minimap work preserved. Native event delivery/operation/taint/pixels/controller/CPU/FPS NOT RUN; existing user-native route retained. No foreground/input, settings/profiler writes, manual sync or publication.
[Requirements, comparison and native steps](ACTION_COUNT_REFRESH.md); [evidence](validation/action-count-refresh-2026-11-13.json).

13 November auction restock recovery (AUCTION-RESTOCK-RECOVERY-20261113;
AHR-66–73), candidate AH-restock-recovery-20261113-r12: waiting is silent;
changed ingredients reprice safely; each ingredient's Count Bank flag controls
AH/vendor quantities and source costs. Latest verified vendor stock replaces the
opposite classification. Saved recipes retain profession, recipe, materials,
output and yield while closed. Modern commodities can buy forty at once; modern
item bids and old listings still require their own native press. Grouped modern
availability is separate from purchased quantity: one five-charge oil reserves
five uses once. Excess stacks apply only to old-AH ordinary items; the control
is hidden on modern AH. Target nine uses/five per item still rounds to two items.
Desktop suite341/1029 PASS with all owned auction hashes matching;26 harmful
controls rejected. Later unrelated source changes are preserved and recorded,
so that captured suite is not a claim about newer global files. Source checkpoint
2699/history and95 settings metadata verified; no private settings copy.
No foreground/input, settings/profiler writes, manual sync or publication.
Old corrupted reservations cannot safely be halved; reconcile from the mailbox.
Native purchase/mail/vendor/bank/craft, pixels/controller/taint and CPU/FPS remain
NOT RUN. Existing user-managed native reproduction retained.
[Requirements and acceptance](AUCTION_RESTOCK.md#silent-waiting-and-changed-ingredient-stock);
[evidence](validation/auction-restock-recovery-2026-11-13.json).

13 November dynamic minimap buttons (MINIMAP-DYNAMIC-20261113; REQ-MBL-22/23)
supersedes the earlier growth/movement choices: Dynamic button count keeps the
configured count as a saved minimum. With fifteen full slots, carrying offers
sixteen; cancel/drop elsewhere returns to fifteen; filling the preview keeps
sixteen. Deleting assignments compacts toward the minimum, including interior
holes, without renumbering saved indices. Both layouts share this behavior;
hide-empty may still hide screen-side minimum placeholders. The independent
movement control is removed: Always shown automatically reserves room for
minimap/Questie/objectives/auras; mouseover overlays their normal dock. The old
sideMoveFrames value stays saved but is ignored. Cursor observation also covers
active embedded dynamic layouts; no new frame/timer/poll/native API is added.
10480 dynamic checks/30 layout-scale cases/six harmful controls, paired baseline
and candidate (three trials per layout), nine existing integration scripts and
full 342 scripts/1030 syntax PASS for the captured snapshot. Later concurrent
action-count edits stale global evidence; task-owned source identities match.
External 2706-file source/history checkpoint
and 99 settings metadata verified; private values not copied. Native input/taint/
pixels/persistence/controller/CPU/FPS remain NOT RUN. No foreground/input,
settings/profiler write, manual sync or publication. Reload outside combat and
follow the retained user-managed native reproduction route.
[Current requirements and acceptance](MINIMAP_EXTRA_LAYOUT.md#dynamic-minimum-and-automatic-frame-movement);
[evidence](validation/minimap-dynamic-2026-11-13.json).

13 November minimap extra-button visibility (MINIMAP-VISIBILITY-20261113;
REQ-MBL-18–21): optional screen-side empty-slot filtering preserves numbered
assignments and reveals one drop target while carrying an action. Optional shared
auto-growth adds one slot after a full successful drop, up to 120. Movement can
be disabled for minimap/Questie/objectives/auras. Always shown or mouseover mode
combines with the existing secure combat-hide toggle; hover freezes during
combat and embedded buttons ignore side-only visibility/empty filtering. Defaults
retain the current layout. One 0.1s hover ticker runs only in active side mouseover
mode and stops in combat/embedded/disabled/always mode; cursor observation is
scoped to active side hide-empty mode. No input-capturing frame is added.
4540 focused checks/15 scale cases/5 harmful controls and eight existing
layout/options/action/ownership scripts PASS. Full 341 scripts/1029 syntax PASS;
two transient auction failures during concurrent edits passed on the full rerun.
Verified external 2697-file source/history checkpoint and 99 settings metadata;
no private settings copy, foreground/input, settings/profiler write, manual sync
or publication. Native input/taint/pixels/controller/persistence/CPU/FPS remain
NOT RUN; reload out of combat and follow the retained user-managed reproduction.
[Requirements and acceptance](MINIMAP_EXTRA_LAYOUT.md#empty-slots-automatic-growth-and-optional-overlay-visibility);
[evidence](validation/minimap-visibility-2026-11-13.json).

13 November mailbox restock tooltip (MAIL-RESTOCK-TOOLTIP-20261113; AHR-65):
Restock and Auto help now clear/add one wrapped white line instead of passing
boolean true in SetText's numeric alpha slot. Owner/anchor/localized help and
hover/leave behavior are preserved; no settings or input actions change.
Strict native-argument hover regressions fail before the fix and pass after it:
3160 mail checks/20 profiles,21 Select,18 OpenAll,880 lifecycle,654 follow-up and
300 workflow checks PASS; full338scripts/1026syntax PASS with current manifest
verified. Restoring the bad call fails the
intended alpha assertion. External2695-file source/history checkpoint and95
settings metadata verified; private settings not copied. No foreground/input,
settings/profiler writes, manual sync or publication. Native hover retest pending.
[Fix and acceptance](AUCTION_RESTOCK.md#mailbox-tooltip-argument-correction);
[evidence](validation/mail-restock-tooltip-2026-11-13.json).

13 November tooltip/meter errors (SECRET-UI-20261113): Flux unit/pet/raid/preview
hovers now use one private reusable native-template tooltip; shared GameTooltip
state and health mixin methods stay native. Meter menus/configuration remain
with actual Blizzard dropdown clicks; addon generation/open/pick removed. Saved
layout requests/history/segments retained. Automatic native type/window/Current
application is intentionally pending a verified clean route. Meter106checks,
three baseline pairs/three harmful controls;tooltip three baseline pairs/two
harmful controls;337 scripts/1025 Lua syntax files PASS.
External2690-file source/history checkpoint and127 settings metadata verified;
36 pinned source records. Reload needed to clear previously tainted objects.
Native secret/taint/pixels/controller/CPU/FPS NOT RUN; user retest retained. No
client control, settings/profiler writes, manual sync or publication.
[Requirements, sources and acceptance](SECRET_TOOLTIP_METER_ERRORS.md).

13 November integrated restock workflow (AUCTION-WORKFLOW-20261113; AHR-57–64)
implements shortage-only scanning, compact scrolling cells/coin price editing,
and temporary recipe targets through normal vendor/bank owners. Mailbox Restock
and saved Auto collect acknowledged matching items through Postal's space/speed/
command gates. Complete empty native inbox proof clears private pending, saved
collection job and Collect restock mail HUD. Partial loaded inboxes collect
visible matches while keeping inaccessible receipts. Native failure/index shifts
cannot claim delivery; inbox removal and delayed bag arrivals credit once.
Saved recipes/source plans survive reload; shared bank/vendor-owned inputs,
physical charges, direct targets and recipe budgets remain protected. Manual clear
preserves real mail/permanent targets and rejects transactions/commodity quotes.
Current focused40scripts, owned syntax and26 harmful controls PASS with no restock
source drift. Initial full336scripts/1024syntax PASS; later shared-tree sweeps
changed during unrelated Bars/meter/raid/unit work, which is preserved. Carry
that global validation separately; do not claim current whole-tree acceptance.
Latest combined sweep334/336: unrelated Bars smoke/contract failures. Docs checker
reports7 stale unrelated generated-source/view entries after concurrent edits.
Refresh global validation once that work settles; scoped restock40 remains PASS.
External2684-file source/history checkpoint and95 settings metadata verified;
private settings not copied. Existing implementation/user-native choices retained.
Native operation, pixels/controller, delivery, taint/CPU/FPS remain NOT RUN on all
five clients. Read-only installed-file checks find all15 changed runtime files
matching Forever/MoP/Era; no manual synchronization was performed. No client focus/
input, settings/profiler writes or publication.
[Behavior](AUCTION_RESTOCK.md#integrated-restock-workflow-13-november-2026);
[evidence](validation/auction-workflow-2026-11-13.json).

13 November Blizzard party dispel setting (PARTY-BLIZZARD-DISPEL-20261113): both
party styles and their previews honor Blizzard's dispellable-only checkbox through
a read-only per-frame predicate, retaining Flux's existing strict option and raid
scope. Existing CVar events refresh visible party auras, including combat; hidden
owners stay retired. 418 focused checks and the full 338-script/1,026-Lua-syntax
run PASS; the complete current Lua manifest and documentation validate. External 2,694-file source/history checkpoint and 183 settings
metadata entries verified. Native pixels/combat/taint/controller/CPU/FPS NOT RUN;
existing user retest retained. No client control or settings/profiler writes.
[Behavior and native checks](PARTY_DEBUFF_VISIBILITY.md#blizzards-dispellable-only-checkbox--13-november-2026).

13 November vendor catalogue and AH discounts (AUCTION-VENDOR-ROUTES-20261113;
AHR-52–56): the user accepted a bundled catalogue combined with learned vendor
data, without item-name exceptions. All five selected client types have their
own source profile. Across seven retained profiles:15,327 stock/15,310 prices;
Retail3710/3693,Forever849,MoP3005,Era862,TBC1708. Only selected maps allocate.
All11,617 legacy raw prices/counts match their client build; Retail3710 stock
records derive from pinned current world-vendor/condition data plus ItemSparse.
MIT/GPL notices, compact public inputs and reproducible generator are retained.
Learned stock/prices override catalogue assumptions. Unlimited goods stay hidden
unless fresh usable AH unit prices are strictly lower; equal/dearer/owned/stale/
historical offers cannot authorize buying. Known stock without price stays out.
Repair/sell/manual-only configured visits learn through the existing paced index.
Every recipe input is priced; actual whole-stack invoices decide vendor vs AH,
and stable per-plan routes/prices preserve mixed-source quantities and budgets.
Physical-unit bundle normalization, exact fractions, invoices and affordability
avoid rounding ties/underbuys; vendor-only temporary targets never leak into AH.
Pending-only mail/vendor/craft HUD, combat hiding, saved closed-profession recipes,
charges, source ownership and one action per press remain. Full332scripts/1019
syntax PASS;complete current Lua manifest verified. Focused30990catalog/1170price/
1130queue/600route/415learning checks and16 harmful controls PASS. External2670-file
source/history checkpoint and95currently present settings metadata verified;
private settings not copied. Native buying/crafting/discounts/access/HUD/controller/
delivery/taint/CPU/FPS remain NOT RUN. Existing direct implementation/user-native
choices retained. No client focus/input,settings/profiler writes,sync or publication.
[Behavior](AUCTION_RESTOCK.md#vendor-catalogue-observations-and-auction-discounts);
[evidence](validation/auction-vendor-routes-2026-11-13.json).

13 November restock follow-up (AUCTION-FOLLOWUP-20261113;AHR-46–51): one ordinary
HUD button beside the extra-action area follows acknowledged restock purchases
through matching mail, missing vendor materials and exact recipe batches. Jobs
survive reload, hide in combat and remove demand subscriptions when complete.
Each action requires a press; callbacks only prepare state. Current vendor
identity/price/wallet and exact live craft output/reagents/allocation are checked;
shared direct targets and partial charged copies stay protected. Authoritative
owned-take proof handles net physicalbags1→1 after an old last charge is used.
Closed/wrong profession native data can no longer override complete saved learned
recipes for cost comparison; exact execution still requires live proof.
854state/1692driver/209UI/848charactercache/824crafting checks PASS;fiveclient
models with optional providers. Full327scripts/1012syntax PASS with current
complete Lua manifest verified. External2663-file source/history checkpoint,
103settings metadata entries and26pinned profession blobs verified. No newtimer/
poller/nativebinding;one lazy ordinary button. Native permission,placement,
gamepad,delivery,taint/FPS remain NOT RUN;Forever directopening is unverified.
Existing implementdirect/user-native choices remain;no foreground/input,
private settings/profiler writes,manualsync,commit or publication.
[Behavior](AUCTION_RESTOCK.md#follow-up-button-and-closed-profession-recipes);
[evidence](validation/auction-followup-2026-11-13.json).

13 November auction purchase/charges (AUCTION-PURCHASE-CHARGES-20261113;AHR-41–45):
an unmatched item-completion event no longer turns potion1 into extra cloth38.
Live commodity shortages rebuild before quoting (38→2 even with excess enabled).
Selected price-editor cells have a thick gold outline and warm fill. Charge
targets reuse Registry capacity:9uses/5per item buys2physical=10uses; recipe
ingredients/prices remain physical. New reservation itemCount/unitScale facts
reconcile delivery and target/material role changes without rebasing active
transaction units; legacy records retain their fallback. Shared direct/craft
invoices charge only recipe share to the crafting budget; surplus stays included.
14,292 charge checks;400 full purchase-flow checks;743 receipt checks PASS across
five client models/optional providers. Seven harmful controls rejected; full
324scripts/1,006syntax PASS and complete current source manifest verified.
Seven existing runtime owners;no new event/timer/hook/poller/interactive frame.
External2,654-file source/history checkpoint and103settings metadata verified.
Four concurrent minimap/options changes preserved. Native purchase/charge/mail/
controller/pixel/taint/FPS checks remain pending; earlier Forever BLOCKED is not
certified fixed. Existing wrong predictions require one normal mailbox refresh;
no Clear pending or cache pruning. No foreground/input/settings/profiler writes,
manual sync,commit or publication. Build AH-purchase-charges-20261113-r8.
[Behavior](AUCTION_RESTOCK.md#purchase-identity-selection-and-charged-items);
[evidence](validation/auction-purchase-charges-2026-11-13.json).

13 November combat-hide scope (MINIMAP-SIDE-COMBAT-20261113;REQ-MBL-17): the setting
stays visible while embedded and applies only to normal-map screen-side buttons.
Embedding removes the existing combat driver; embedded grid remains visible in
combat. Saved hideInCombat persists and resumes on returning to the side layout.
UI label/help clarify that scope; capability gating and deferred protected layout
remain. Two runtime owners;no new frame,event,timer,hook,poll or native API.
50,034 grid/113 map/2,287 aura/168 flyout/6,407 options checks PASS;three matched
runs reject exact baseline and3harmful controls. Full snapshot 324 scripts/1,006
syntax PASS;task files remain current. Concurrent later auction edits are preserved;
global source freshness remains pending for that unrelated work. External
2,652-file source/history checkpoint and103settings metadata verified. Native
pixels/input/controller/persistence/taint/FPS NOT RUN;user-native route retained.
No client control,private settings/profiler writes,sync,commit or publication.
[Requirement](MINIMAP_EXTRA_LAYOUT.md#combat-hiding-applies-only-to-the-screen-side-grid); [evidence](validation/minimap-side-combat-2026-11-13.json).


13 November side-grid scale normalization (MINIMAP-SCALE-BASIS-20261113;REQ-MBL-16):
new displayed 100% is the previous 85% size and remains the default. The slider is
10–200%, effective frame scale0.085–1.7. Legacy explicit scales convert by /0.85
without rounding or rewriting records; new choices mark version2 to prevent repeat
conversion. Old values beyond the new ceiling are capped by new200%;raw data stays.
Automatic columns, zero padding, shared actions, aura/flyout geometry and combat
queues retained. Two runtime owners; no new frame/event/timer/hook/poll/native API.
50,007 grid checks;113 map/2,287 aura/168 flyout/6,397 options checks PASS. Three
actual checkpoint comparisons preserve9,408 geometry fields/run for old25–170 and
new100=old85;four harmful controls rejected. Full322scripts/1,004syntax PASS and
current manifest verified. External2,644-file source/history checkpoint and103
settings metadata entries verified;no private contents copied. Native pixels,
input/controller/persistence/taint/FPS remain NOT RUN;existing user-native route
retained. No client control,settings/profiler file write,sync,commit or publication.
[Current requirement](MINIMAP_EXTRA_LAYOUT.md#scale-normalization-100-equals-the-previous-85); [evidence](validation/minimap-scale-basis-2026-11-13.json).


13 November automatic minimap grids (MINIMAP-AUTO-LAYOUT-20261113;REQ-MBL-12–15):
both layouts now choose columns and largest fitted button size from count/space.
Embedded minimap size is automatic; embedded columns/map-size and side-column
controls removed. Screen-side whole-grid scale remains 25–200%, default100%; every scale refits
above Flux Window. User screenshot gap follow-up removes container/screen/start/
window padding and fractional-row slack. Completed side columns touch the window;
embedded buttons touch the map. Map/tracker/aura reservation follows scaled width. Downward side
column order, shared numbered actions, widget reuse, hidden-tab/window state,
flyouts and combat deferral retained. Retired saved keys preserved but ignored;
sideScale preserved and extended. Three runtime owners; no new frame,event,timer,
ticker,hook,polling or native API.48,866grid/113map/2,287aura/168flyout checks;6,397
options-navigation checks;three matched pairs/scenario;11 external and4 map harmful
controls PASS. Full322scripts/1,004syntax PASS,current complete manifest verified.
Fresh external2,638-file source/history checkpoint and103settings metadata verified.
Existing dated Gethe pins/direct implementation/user-native route retained;native
pixels/input/taint/controller/persistence/FPS NOT RUN. No client control,private
settings/profiler write,manual sync,commit or publication.
[Current requirements](MINIMAP_EXTRA_LAYOUT.md#current-behavior-automatic-grids-and-screen-side-grid-scale); [evidence](validation/minimap-auto-layout-2026-11-13.json).


13 November screen-side resize/aura follow-up (MINIMAP-SIDE-AURA-20261113;
REQ-MBL-10–11): the existing 25–100% button-size slider now scales after height
fitting, so crowded 120-slot layouts respond at 50%/25%. Defaults, shared actions,
column order/bounds and saved setting identities stay intact. Beside-map buttons
now reserve the same left offset for native BuffFrame/DebuffFrame. Existing aura
placement runs from shared strip layout before the hidden branch, restoring old
positions for below/off/embedded states. Native aura content/style/input remains
Blizzard-owned; combat/Edit Mode guards retained. Two runtime owners; no new frame,
event, timer, ticker, hook or polling. 3,415 resize +1,855 aura checks, three matched
pairs per scenario and five harmful controls PASS; full 322 scripts/1,004 syntax
PASS with the complete current Lua manifest verified. Documentation validator PASS.
23 narrow Gethe records/21 Git blobs verified at retained source pins. Fresh
external 2,630-file/source-history checkpoint and 69 settings metadata entries
verified; no private contents copied. Direct implementation/user-native route
retained; native pixels/input/controller/persistence/taint/FPS NOT RUN. No client
control, settings/profiler write, manual sync, commit or publication.
[Requirements and native checks](MINIMAP_EXTRA_LAYOUT.md#follow-up-screen-side-resizing-and-aura-placement); [evidence](validation/minimap-side-aura-2026-11-13.json).


13 November trinket visual recovery (TRINKET-DARKENING-20261113; TD-01–04):
held presses restore the newest public usability color; empty/re-equipped faces
invalidate stale tint; equipped cooldown refreshes share slot data and one paint
cache. Passive trinkets remain dim; real cooldowns stay visible. Two runtime owners,
no new frame/event/timer/hook/poll. 245 integrated checks across five models;
exact checkpoint fails 55 checks; five regressions rejected. Existing 10/1,563 focused checks
and 321 scripts/1,003 syntax checks PASS with documented final test refresh. Verified
external source/history checkpoint (2,627 files) and seven Retail settings metadata entries;
15 fresh source records. Native pixels/input/controller/taint/FPS/memory NOT RUN;
user-native reproduction/direct implementation retained. No client control,
private settings/profiler write, sync, commit or publication.
[Task evidence and native checks](TRINKET_EQUIPPED_USABILITY.md#13-november-follow-up-intermittent-dark-faces-and-cooldown-overlays).

13 November Syndicator continuity (SYNDICATOR-SYNC-20261113; SYN-SYNC-01-05):
while delegated, FluxUI saves Syndicator's live v2 root by reference, including
alts/deletions. Next standalone startup imports detached facts once; later reloads
retain standalone changes. Exact three-way field/container comparisons update
unchanged stale external data; independent external edits/deletions and current
native cash/tokens win. No scan timestamps are fabricated. Dense slots, offsets,
capacities and list/auction metadata retained; no phantom bank tabs.
Transition-only notifications refresh views/search without alt live-player changes;
guild/void callbacks unchanged. No new frame/event/timer/subscription/poll; existing
scanner records capacity without extra native queries. 309 focused checks and three
harmful controls PASS across five desktop models; full snapshot320 scripts/1002
syntax PASS, task sources still match. A new concurrent trinket recovery test after
suite enumeration now passes200 checks after its separate source edits; unrelated
work preserved and whole-workspace freshness remains pending. External2612-file/source-history checkpoint and58
settings metadata entries verified; Syndicator290 read-only reference, ARR preserved.
Native persistence/Baganator pixels/taint/CPU/FPS pending; existing user reproduction
route retained. No client input/focus, private settings/profiler write, manual
installation sync, commit or publication.
[Requirements and native checks](SYNDICATOR_SYNC.md); [evidence](validation/syndicator-sync-2026-11-13.json).

13 November saved character recipes (CHARACTER-RECIPES-20261113; CRP-01–06): existing
profession SavedVariables now retain complete learned material/output/yield/slot
facts for AH and future shared consumers. Filtered and partial scans preserve
known facts; explicit unlearn removes them; unknown learned state and NPC/legacy
linked knowledge are rejected. Output-based per-character queries deduplicate
modern aliases. Proven deterministic recipes work after closing/reloading the
profession; uncertain grades still require native operation proof. Finished-item
caps include crafting/vendor acquisition cost;0 stays unlimited. Selected missing
vendor inputs create temporary per-character targets in the ordinary vendor list.
They sum shared requirements, subtract bags/mail once, survive the vendor trip
and reload, and retire on completion/invalidation without changing permanent
targets. Live vendor price ceilings protect the plan; permanent base targets
still buy independently. Pure temporary rows are read-only; no new controls.
704 new recipe checks;20 models;17 harmful controls;320 scripts/1002 syntax PASS at captured run;17,229 combined auction/recipe checks. Five repeated
work models:4→2 schematic reads,4→2 duplicate-free catalogue rows,0→1 usable
closed-profession AH variants. These are work models, not native time/FPS.
Scoped guard:5 existing runtime files and1 new test;2,609-file external checkpoint
and47 settings metadata entries verified. Concurrent unrelated workspace edits
are retained and listed separately; captured full-run scope is explicit.
Open each relevant profession once after updating to populate the new facts.
Current native capture/reload/vendor/coexistence/controller/taint acceptance and
the prior Forever purchase BLOCKED resolution remain pending. No client input,
private settings/profiler write, manual sync, commit or publication.
Global documentation validation remains pending solely for concurrent
Syndicator sync source/evidence edits; owned recipe/restock hashes remain verified.
[Behavior/API](CHARACTER_RECIPES.md);[evidence](validation/character-recipes-2026-11-13.json).

13 November minimap layouts (MINIMAP-LAYOUT-20261113; REQ-MBL-01–09): shared character
slots now support 1–120 buttons; embedded columns auto-fit beside a 40–100% square
right-aligned map. Optional normal-map side layout defaults off; 1/2 columns retain
44-point buttons when space permits; 3+ fit two-column width and can shrink further.
Fill down the rightmost column to above Flux Window, then continue left. Start
below map or beside it from screen top; native/Questie docks reserve matching room.
Secure combat-hide option covers buttons/arrows/open flyouts and releases Escape;
unsupported secure engines explain unavailable. All structural changes defer;
queued combat embed/restore reconciles correctly. Hidden slots keep actions and
widgets; existing cadence/input/integrations retained. 760 focused checks; 22 harmful
controls; exact old baseline rejected; combined 320 scripts/1002 syntax PASS (319/1001
full run plus one concurrently added test checked separately). Final owned sources pass scoped retests; unrelated concurrent
inventory edits leave global freshness pending. 46 fresh Gethe source
records/36 Git blobs verified; Forever pin now bebcb6bf309cf41b41bd74f8ca651e6a105b2676.
External 2608-file/source-history checkpoint and 69 settings metadata verified.
Eight task runtime owners; unrelated concurrent inventory work preserved. No new
addon poll/ticker/timer. Direct implementation/user-native route retained; native
pixels/input/persistence/controller/taint/FPS/memory NOT RUN. No client control,
settings/profiler write, manual sync, commit or publication.
[Requirements and native checks](MINIMAP_EXTRA_LAYOUT.md); [evidence](validation/minimap-layout-2026-11-13.json).


13 November options follow-up (OPTIONS-SHARED-THREAT-20261113; REQ-OPT-35–38):
sidebar order is Combat → Loot & Items → Utilities → HUD → Unit Frame. Bindings
and Keybindings share one Bindings entry with two original-tool tabs; old links,
macro search and editor lifecycle remain. Threat warning visibility renames the
existing scoped threatBarVisibility setting; General/Nameplates share Always,
In raid, In party, Off. Party includes raids; raid-only excludes parties. All
nameplate and target/focus positions share one gate; between-bar exception removed.
Old nameplate values/legacy keys preserved. Explicit changes request the existing
guarded native warning CVar; wrapper CVar-presence call signature corrected.
870 warning/6,272 placement/1,243 shell checks; suite snapshot316 scripts/997 syntax PASS.
External2,609-file/source-history checkpoint and141 settings metadata entries
verified. Seven runtime owners changed; no new driver/event/timer/hook/poll.
Direct implementation/user native reproduction retained; native pixels, persistence,
combat/taint, controller and FPS NOT RUN. No client input/focus, private settings/
profiler write, manual sync, commit or publication. Fresh source lookup unavailable;
existing dated pins retained; no new native API contract.
[Requirements and acceptance](OPTIONS_REWORK.md#13-november-sidebar-bindings-and-shared-threat-warnings);
[evidence](validation/options-shared-threat-2026-11-13.json).

12 November potion discovery stall (AUCTION-POTION-STALL-20261112; AHR-38–40): the new
screenshot remains Finding stronger usable potions. The real parser reproduced
a spent shared-budget failure that the earlier classification stub missed. Each
deferred AH batch now renews that budget (still at most8 IDs). Potion results mark
whether restore is known; name-only placeholders retry until real tooltip data
arrives and cannot be ranked as restore1. Known unusable potions are skipped first.
Native ADDED browse payloads now contribute later rows and cumulative unique-key
progress, preserving the initial catalog instead of repeatedly reading its first
batch. Read-only /fluxah debug adds search phase/term/results/page/deadline.
Five repeated desktop work models: baseline refs100/101,734 load requests and
timeout; candidate refs201/300,30 requests and ready. Simulated elapsed times are
not native measurements. 552 potion/16525 auction checks;20 restock/15 receipt models;6 new harmful controls;314 scripts/995 syntax PASS.
Four existing runtime/test files changed;0 new; external2,608-file source/history
checkpoint and47 settings metadata entries verified. Existing UI, settings,
unquoted terms, price/usability/shared tiers and per-press buying are preserved.
User native reproduction route/direct implementation remain selected. Current
native retest and earlier Forever purchase BLOCKED resolution remain pending.
No client input/focus, private settings/profiler write, manual sync or publication.
[Current behavior](AUCTION_RESTOCK.md);[evidence](validation/auction-restock-potion-stall-2026-11-12.json).

12 November auction density/source/potion correction (AUCTION-DENSE-STOCK-20261112; AHR-28–37)
replaces the recipe/cost pane with a full-width paged grid and Direct/Craftable
labels (24cells at modeled800×600), retaining three money fields and one Buy next.
Old/unacknowledged pending attempts are pruned; real receipt/private/provider
incoming credits still reconcile once. Only typed unlimited merchant supply
excludes an item; limited/unknown/price-only/extended-cost records stay eligible.
Food/water are absent, including manual entries; vendor spell reagents use that
same unlimited-supply rule. All listed eligible items, including full/zero targets,
are price-scanned. Optional Auctionator public hints and guarded unit-price/history
write-back coalesce one notification; historical prices never authorize buys.
Plain unquoted partial healing potion / mana potion searches collect all native
result pages, validate usability/live offers/caps, choose stronger tiers and update
the real shared reference/tier. Weaker bag/bank stock cannot fill the stronger
target. Original caps survive a scrubbed ref; unknown metadata holds potion buys.
Craft preference, exact yields/shared inputs, price caps and one transaction per
press remain. 16413 focused checks;20 restock/15 receipt models;41 harmful controls;314 scripts/995 syntax PASS; 226 pinned upstream blobs verified.
Source guard:15 existing changed runtime/test files and4 new since the verified
2,602-file external checkpoint;47 settings metadata entries, no private values.
Earlier Forever mouse BLOCKED failures and screenshot defects remain prior native
evidence; current live purchases/pixels/coexistence/controller/taint/FPS NOT RUN.
No client input/focus, manual sync, settings/profiler write, commit or publication.
[Behavior and remaining native checks](AUCTION_RESTOCK.md);
[current evidence](validation/auction-restock-dense-potions-2026-11-12.json).

12 November auction follow-up (AUCTION-AUTO-CRAFT-TAB-20261112; AHR-10–27) supersedes the
initial popup/two-press/zero-disables/clear-pending design below. Real AH tab uses
shared restock cells/current icons and three currency fields; top edge/height
match neighboring tabs. Whole-list/material planning is automatic; cell selection
only edits. One press quotes/confirms one qualifying transaction; next needs a new
press. Zero/unset is unlimited. Saved Prefer crafting materials toggle is in AH
and Vendor→Restock; equal/cheaper learned recipes use exact missing inputs/yield,
vendor costs/shared stock and finite parent budgets. Incoming inbox plus transit
credit reconciles automatically (19/20 feathers +1 pending blocks rebuy); there is
no Clear pending UI/API. Built-in inventory now publishes confirmed AH purchases
to its mail snapshot/ledger immediately, including other auction controls; provider
Ready handoff stays inert. Prediction/private transit credit counts once and an
early empty inbox cannot discard the own reservation. Proven owned failures and
synchronously blocked calls release their own credits without phantom delivery.
13078 focused checks;20 restock/15 receipt models;34 harmful controls;312 scripts/991 syntax PASS;202 upstream Git blobs verified;
source guard permits10 existing changed files/5 new files in this follow-up;
shared cells/professions/Syndicator adapter remain byte-identical. Built-in Mail/
Auctions are intentionally extended. External2,595/2,598-
file source/history checkpoint and47 settings metadata entries verified.
Two prior Forever mouse-click BLOCKED failures remain native evidence; direct
calls/action-before-disable candidate has NOT passed native retest. No-search,
pixels, transactions/coexistence, persistence, controller, taint and FPS acceptance
pending. Auctionator345/TSM4.15.6/Syndicator290 inspected read-only at explicit request;
ARR notices preserved; no copied code. No client focus/input, settings/profiler
write, manual sync or publication. Reload after user-managed synchronization.
[Current behavior and native checks](AUCTION_RESTOCK.md).

12 November auction restock (AUCTION-RESTOCK-20261112; AHR-01–09): native-API
standalone implementation for Retail/Forever/MoP and Era/Anniversary. One action
button searches/quotes/buys; every purchase requires a press. Per-item saved unit
caps include active presets; known vendor stock excluded, unclassified items need
an explicit cap. Legacy default fits whole stacks; optional excess shows surplus
and total. Charge/tier/bank math and persistent pending-mail reservations prevent
duplicate refill. Competing queries/quotes yield; partial batches request more
selected-item rows. No Auctionator source/dependency or new inventory provider.
6,496 focused checks/20 models;12 harmful controls; full309 scripts/986 syntax PASS;
all final manifest hashes match. 87 pinned Git blobs verified. External2,587-file
source/history checkpoint and47 WTF metadata entries; private settings not copied.
Four new modules,one test;three existing runtime files changed;all other existing
Lua/XML/TOC bytes preserved. Direct implementation selected12November; prior
user native reproduction route retained. Native transactions/addon coexistence,
pixels/controller/persistence/taint/FPS NOT RUN. Reload after user-managed sync;
use Vendor→Restock→Auction restock & prices, `/fluxah` or auction-house button.
No foreground/input, settings/profiler-file write, manual sync or publication.
[Requirements and remaining native acceptance](AUCTION_RESTOCK.md).

11 November all-consumable audit (CONSUMABLE-ALL-BUTTON-AUDIT-20261111;
CGLC-23 through CGLC-27): all seven real Create paths and both grid count methods
run together across five models, both providers and two gem policies. Repeated
loading, charged remnants, isolated depletion/refill and regen placeholders PASS.
2,580 checks; old native-failing source 940/current 0 in three matched pairs;
ten harmful controls rejected. One shared watcher; 100 use signals coalesce to
one immediate and one 100ms settle callback, 14 recounts; 100 unrelated events add 0;
idle 12s adds 0 scans/timers. Full 308 scripts/981 syntax PASS; manifest current.
No production Lua/XML/TOC changes; one new test. External 2,585-file source/history
checkpoint and 55 settings metadata entries verified; 75 installed runtime copies
match user sync. Current repair native acceptance/FPS/taint/pixels/input remains
NOT RUN. No client focus/input, settings/profiler write, manual sync or publication.
[Coverage, source ownership and native limits](COMBAT_GRID_LIVE_COUNTS.md#all-seven-real-button-modules-audited-together).

11 November native loading-hold fix (CONSUMABLE-LOAD-END-20261111;CGLC-19 through
CGLC-22): failing-state capture proves food 1 with every source 0 while inventory
is reliable and Best's loading latch remains open. Ordinary bag events cannot
release it. One Inventory handler now completes unfinished loads on validated
optional LOADING_SCREEN_DISABLED, restarts cancelled existing slot refresh and
reuses bounded portal recovery. Normal PEW/duplicate completion add no work;
newer loads remain protected. All seven kinds/providers/five models covered.
2,230 checks; exact checkpoint fails 660; three matched pairs and five controls;
full 307 scripts/980 syntax PASS with current manifest. One runtime owner and
one test added; one event subscription; no new frame/ticker/timer call site,
background polling, settings or action writes. Five pinned blobs and external
2,583-file source/history checkpoint verified; 55 settings metadata entries;
all five installed runtime copies match via user sync. Prior candidate FAILED
natively; new handler symptom/taint/pixels/input/FPS acceptance NOT RUN. Reload
and retest loading/depletion; retain /fluxinv buttons output during recurrence.
No foreground/input, profiler write, manual sync, commit or publication.
[Native evidence and completion recovery](COMBAT_GRID_LIVE_COUNTS.md#native-capture-loading-completion-left-open).

11 November consumable screenshot follow-up (COUNT-SOURCE-RECONCILIATION-20261111;
CGLC-14 through CGLC-18): all seven kinds and other assigned item faces share
count-source/recovery corrections. Actual world entry releases an orphaned
open loading latch; startup during real loading remains held. The existing
portal timer publishes inventory count recovery even without an identity change.
A valid carried-only modern zero no longer falls through to a stale deprecated
positive; missing/error and extended-bank compatibility remain. Optional
`/fluxinv buttons` captures physical slots, APIs, provider/text/hold facts once;
no automatic polling, new event/frame/timer/hook, settings or protected writes.
2,104 hold/diagnostic +245 source checks PASS; exact checkpoint fails 583/150;
three matched pairs per workstream and eight harmful controls rejected.
Full 306 scripts/979 syntax PASS; normalized manifest current; four runtime
owners only and two new tests. 22 fresh pinned Gethe blobs verified; external
2,580-file source/history checkpoint and 55 settings metadata entries. All 20
installed runtime copies match via user sync. User's healthy Syndicator/reliable/
no-hold sample and unbound gem do not explain the intermittent screenshot.
Follow-up food/water probe prints no rows; raw API agreement is unverified.
Native candidate symptom/pixels/taint/input/FPS remains NOT RUN; reload and
capture `/fluxinv buttons` during recurrence before another reload. No client
input, settings/profiler write, manual sync or publication.
[Requirements and remaining native acceptance](COMBAT_GRID_LIVE_COUNTS.md#screenshot-follow-up-count-sources-and-loading-holds).

10 November profession fill/glow correction (TRADESKILL-CAST-FILL-FIX-20261110;
TCAST-06–08): user reports missing fill and excessive flare, then requests a
visible skill-up-style glow after softening. Animated fill now belongs directly
to TimerBar ARTWORK7; an opaque native mask follows progress with black-outside
wrap. Flare is explicitly above fill at OVERLAY0 and below native text/shields;
60% intensity and 44x14 instead of 53x16 at 18px bar height. Glow persists through
the existing completion fade. No new frames, drivers, events, timers, hooks,
options or data; one clip frame removed, one mask added per themed bar.
455 focused checks; exact old clipped implementation plus seven harmful variants
rejected; full 304 scripts/977 syntax PASS; current source attested.
Six mask-API blobs verify at the retained Retail/Forever pins. External 2,578-file
source/history checkpoint and four settings metadata entries verified. Initial
native failure is user evidence; candidate pixels/taint/input/controller/FPS
NOT RUN. Direct implementation/user retest retained; reload OOC and craft.
No client input/focus, settings/profiler writes, manual sync or publication.
[Correction and remaining acceptance](TRADESKILL_CAST_THEMES.md#fill-and-visible-glow-correction).


10 November profession cast themes (TRADESKILL-CAST-THEMES-20261110; TCAST-01–05):
readable tradeskill casts now use Blizzard's animated profession rank-bar fill
and optional flare on capable Forever/Retail clients. Recipe API plus native
profession enum selects the kit; unknown/restricted data and absent art keep
the ordinary cast. Existing master/unit/colors/edge/glow controls and complete
cast/channel/completion/interruption lifecycle retained. No new Lua driver,
event, timer, hook, options, text or saved data. Focused five-client models PASS;
old behavior and five harmful controls rejected; full 304 scripts /
977 syntax PASS with current source manifest. Fourteen fresh pinned Gethe
blobs verified. External 2,574-file/source-history checkpoint; four settings
metadata entries only. Direct implementation/user reproduction retained.
Native pixels/taint/input/controller/FPS NOT RUN; reload OOC and craft with
two professions. No client input/focus, settings/profiler write, manual sync
or publication. [Requirements, implementation and checks](TRADESKILL_CAST_THEMES.md).


10 November focus without resource (FOCUS-NO-RESOURCE-20261110): the compact focus
divider now follows resource opacity, including focused-unit chrome refreshes.
No-resource focus retains full HP with no dividing line; empty current power
with positive capacity keeps its bar/divider. Native opaque alpha passes
directly; combat geometry stays deferred. Two exact-baseline regressions
rejected; 22,015 color checks and full 304 scripts / 976 syntax PASS.
One runtime owner; dated external source checkpoint and history verified;
four Retail settings metadata entries read-only. Direct implementation/user
reproduction retained. Native pixels/taint/input NOT RUN; reload OOC and
focus units with/without resources. No new driver, settings or binding; no
client input, preference write, manual sync or publication. [Evidence](validation/focus-no-resource-2026-11-10.json).


10 November party HP/resource fit (PARTY-HEALTH-FIT-20261110): player-style party health
now stops above the resource bar at the existing two-unit gap instead of
extending behind it on HUD clients. Planned prediction geometry matches;
known no-resource units still expand health. Main/compact-focus layouts and
combat deferral remain. 396 fit checks reject the exact checkpoint; 675
combat-join checks and full 304 scripts / 976 syntax PASS.
One runtime owner; external 2,566-file/history checkpoint and 26 settings
metadata entries verified. Direct implementation/user reproduction retained.
Native pixels, combat/taint and input NOT RUN; reload OOC and check a party.
No new input/focus targets, options, strings or runtime drivers. No client
input, settings/profiler writes, manual sync or publication. Fresh upstream
heads unavailable; existing dated pins retained. [Evidence](validation/party-health-fit-2026-11-10.json).


10 November passive pass 3 (PASSIVE-PERFORMANCE-PASS3-20261110; PP3-01–06;
PP3-H01–12): twelve new hotspots across eight loaded runtime owners. Core numeric/
aura/checked helpers reuse callbacks; Index avoids normalized tables and full
first-location result construction. Mana/swing owned styles settle without slowing
live movement/values; raid flags recycle after paint. Active Classic character
calculations drop unused metadata/palette work; quality keeps every query/sink.
Three pairs/workstream; 99,781 focused checks/set; 57 harmful controls rejected.
Full 303 scripts / 975 syntax PASS; source stable throughout. One obsolete rebind
mutation now breaks both cleanup steps; unchanged functional assertion rejects it.
Generated 1,008 sources / 607 reachable / 427 settings / 24 saved roots. Documentation validator PASS.
21 source records / 10 Git blobs verified; canonical native fade replay and
35 setter-return checks. 252 appearance files / 80 options-binding sources unchanged.
Fresh party/vendor fixes and inactive character copies are byte-preserved.
Concurrent ConsumableBind/Paint and use-event test edits are retained and included
in the combined full run; other runtime owners match the checkpoint. External
2,561-file/history checkpoint; settings
metadata only. Native FPS/memory/pixels/taint/input pending; no input, preferences/
profiler write, manual sync or publication. Unrelated party/raid work stays paused.
[Findings, comparisons and native limits](PASSIVE_PERFORMANCE_PASS3.md).

10 November combat grid use/depletion follow-up (COMBAT-GRID-USE-EVENTS-20261110;
CGLC-07–13): user confirmed dark gem1 after use on Forever/Syndicator; wants dark0
in combat and next owned item/empty placeholder OOC for all seven kinds/providers.
Cooldown-only notifications and wrong nonblank cached digits now refresh. Shared
watch has one immediate plus one100ms settle pass; no idle ticker or predicted
decrement. Reliable exhausted gem clears sticky face; gem/stone selection and
charge/refill recovery use existing owners. Tint follows displayed item, including
prepared macro faces. Combat actions and loading holds remain.
1219use +672transition +2175prior checks PASS; three matched pairs each workstream;
12harmful controls rejected. Full304scripts/976syntax PASS; entire source manifest
matches. Hidden340-check trace/budgets and unrelated-bag zero-scan behavior retained.
Three runtime owners; two new tests; two existing fixture expectations updated to
the clarified behavior.22exact Gethe records; external2566-file/history checkpoint;
33initial+22Anniversary settings metadata only. All15installed runtime copies match
through user sync; no manual propagation. Candidate native symptom/taint/pixels/
input/FPS remains NOT RUN; reload and user retest required. No input/focus,
settings/profiler write, manual sync or publication.
[Correction, regression and native steps](COMBAT_GRID_LIVE_COUNTS.md).

10 November party debuff visibility (PARTY-DEBUFF-VISIBILITY-20261110; PDV-01–05):
enemy target/focus tint is revoked immediately; friendly tint remains. Player-style
party icons have rectangular type borders. Both party styles get a Salvage-style
type-colored glow only for native/readable dispellable auras, with an atlas fallback.
18,618 tint / 408 visibility / 11,410 aura checks PASS; two focused runs and six
new controls. Full 298 scripts / 970 syntax PASS; current manifest matches.
Native pixels/combat animation/taint/input/FPS NOT RUN. Three runtime
owners only; concurrent inventory edits preserved. External 2,551-file history/source
checkpoint and 61 settings metadata entries verified. No input, settings/profiler
write, manual sync or publication; direct/user reproduction route retained.
[Requirements, sources and acceptance](PARTY_DEBUFF_VISIBILITY.md).

10 November vendor Junk tab freeze fix (VENDOR-JUNK-TAB-FREEZE-20261110):
two runtime owners; name snapshots remove comparator loads; visual/item completions
share the existing 200 ms retry; reentrant/unchanged scroll painting is suppressed.
Three matched pairs across five client models: 400 cold entries request
13,768→1,200 loads; 400 completions rebuild 400→1 times and paint 6,834→17 rows.
85 focused checks PASS; four harmful controls rejected; vendor/timer regressions PASS.
Full run: 295 scripts PASS, two raid-aura failures amid concurrent unrelated edits;
969 syntax PASS. No clean current full-suite or native freeze/FPS/pixels/taint/input
acceptance claimed. Concurrent edits retained; exact Junk sources match full run.
External 2,545-file/history checkpoint verified; four settings metadata entries only.
No input/focus, settings/profiler write, manual sync or publication. Reload and
user-performed vendor/Junk retest pending. Fresh upstream commit lookup unavailable.
[Cause, fix, evidence and native limits](VENDOR_JUNK_TAB_FREEZE.md).

10 November combat grid live counts (COMBAT-GRID-LIVE-COUNTS-20261110;
CGLC-01–06): food/water/bandage/potions/gem/healthstone reach zero with both
providers. Syndicator's native fallback now includes both conjured kinds;
count/tint and ownership use live carried copies while metadata delays publishing.
Same-frame bag bursts coalesce; combat actions and loading holds remain.
Three matched pairs: 2,175 checks PASS; checkpoint rejects 244; seven harmful
controls rejected. Forty provider burst fixtures: recounts2,500→40, native count
queries2,500→159; no combat scans/rebinds/new frames. Existing craft/hidden-button
regressions pass. Full suite completed297scripts/969syntax PASS; task source hashes
match; unrelated subsequent/concurrent vendor/raid edits retain separate acceptance.
Final docs check has four stale inventory/verification records in concurrently edited
raid/debuff owners; own task sources match all passing focused checks.
Twenty-two pinned Gethe records verified across five clients. External2,550-file/
history checkpoint;33settings metadata entries read-only. Native input/pixels/taint/
FPS/memory NOT RUN; no client input, settings/profiler write, manual sync or publication.
User-managed Retail-only writes and prior party/raid native pause retained.
[Fix, comparisons and native steps](COMBAT_GRID_LIVE_COUNTS.md).

10 November additional passive optimization (PASSIVE-PERFORMANCE-PASS2-20261110;
PP2-01–06, PP2-H01–10): ten new hotspots across eight runtime files. Combat
class-resource retry storms coalesce; synchronous cast text shares a revision-guarded
clock sample; raid prediction uses scalars. Parked Extra Buttons stop checked/count/
metadata work, with count/tint/equipped state refreshed before first visible paint.
Core protected/range helpers and meter timer election reuse functions; collector
keeps linear child snapshots and all discovery cadence with fewer pattern matches.
Three pairs/workstream; 783 focused checks/set; 60 harmful controls rejected.
Full 295 scripts / 967 syntax PASS; exact source matches. Generated 1,000 sources,
607 reachable files, 427 settings and 24 SavedVariables roots. Documentation validator PASS.
25 pinned records / 20 Git blobs verified; Forever advanced to 4cd0ab752a77.
252 appearance files / 80 options-binding sources and all other runtime owners
unchanged, including prior combat/resource fixes. External 2,543-file/history
checkpoint; settings metadata only. Native FPS/memory/pixels/taint/input pending;
no client input, preferences/profiler writes, manual sync or publication. Guild/
void callbacks and unrelated party/raid feature work remain excluded.
[Findings, comparisons and limits](PASSIVE_PERFORMANCE_PASS2.md).

10 November resource-effects follow-up (RESOURCE-EFFECTS-PERFORMANCE-20261110;
RFX-01–06): power ghost bursts coalesce at the original After0 boundary;
1,000 same-frame paints queue 1 callback instead of 1,000; unchanged public sinks
retry only when needed. Secret animation Lua callbacks fall 120→0 in 0.5 s/240 Hz.
Prepared shown helper containers use texture visibility and active-only drivers;
shared spark guards geometry before arithmetic; eligible HUD main bars prewarm
unchanged pulse trees. Bounded dormant allocation tradeoff recorded, no idle driver.
Three pairs/workstream; 122 Shared/168 PCO checks; 9+12 controls; 3×84 combined
checks and 2 disconnection controls. Full 290 scripts/962 syntax PASS; source attested.
Documentation validator PASS: 995 sources, 607 reachable files, 16,146 local links.
88 pinned records/54 blobs and 50 ownership checks; Frame Show/Hide correction.
Earlier partition/value painter and all other runtime owners byte-preserved.
252 appearance files/80 options-binding sources unchanged; external 2,539-file/history
checkpoint; settings metadata only. No native FX/taint/pixels/FPS/input acceptance,
settings/profiler write, manual sync or publication. Prior scoped pauses remain.
[Changes, tradeoffs and evidence](RESOURCE_EFFECTS_PERFORMANCE.md).

10 November combat-invite power partition correction (POWER-PARTITION-COMBAT-JOIN-20261110;
PWRJOIN-01–06): native user trace exposed protected SetHeight/Show in ordinary
post-reveal painting. Shared partition now defers structural geometry before all
text-anchor/prediction/layout mutations; native reveal and value paints continue.
Absent prepared slots retain unknown resource capability so combat joins have a
ready power bar. Existing queue coalesces per frame; Party retains its regen owner.
675 focused checks/15 cases across five clients; three exact-baseline pairs;
eight harmful controls rejected; full 288 scripts / 960 syntax PASS. Documentation
validator PASS: 993 sources / 607 reachable / 16,131 local links. 44 pinned
source records / 31 blobs verified. Only one runtime file changed; earlier 23
performance owners unchanged. External 2,536-file/history checkpoint; settings
metadata only. No native retest/pixels/taint/FPS claim, input/focus, settings/profiler
write, manual sync or publication. Prior mocks omitted protected child permissions.
[Cause, correction and native limits](POWER_PARTITION_COMBAT_JOIN.md).

10 November passive performance optimization (PASSIVE-PERFORMANCE-OPTIMIZATION-20261110;
PPO-01–06): all 24 audited candidates optimized with preserved nominal cadence,
features and tested geometry/input/lifecycle behavior. Three exact-checkpoint pairs
per workstream; 23 runtime files, seven new tests. Full 287 scripts / 959 syntax
PASS; current source matches validation and comparison hashes. Documentation
validator PASS: 992 sources / 607 reachable / 16,117 local links; records current. Native reset reads,
secret sinks, sparse-slot probes and complete provider validation remain where
correctness requires them. 31 pinned source records / 25 unique Git blobs verified.
252 appearance/XML/TOC files and 79 options/binding sources byte-preserved.
External 2,525-file/source-history checkpoint; settings metadata only. No native
FPS/pixels/taint/input acceptance, client input, settings/profiler writes, manual
sync, commit or publication. Scoped optimization includes readable raid fallback;
unrelated party/raid feature work and native sessions remain paused.
[Before/after results and constraints](PASSIVE_PERFORMANCE_OPTIMIZATION.md).

10 November passive performance audit (PASSIVE-PERFORMANCE-AUDIT-20261110;
REQ-RPF-01–05): 24 current optimization candidates plus 2 retained feature costs.
Priority: per-mob group/pet threat ranking; per-frame nameplate layout checks;
settled aura styling and explicit native full-aura rebuild requests; idle observers;
mail/provider bursts. 39 synthetic replay scenarios load unchanged production code
or exact verified native methods; five existing focused regressions PASS. Five
fresh Gethe branch pins; 21 source records / 17 unique blobs verified. All 953 Lua
byte identities unchanged. No runtime/settings/profiler/client-input/sync/publication
change; guild/void callbacks excluded. Actual native CPU/FPS/taint/pixels/memory
remain NOT RUN. Existing generated minimap docs/verification have 10 stale issues;
unrelated generated records not regenerated. Party/raid implementation/native-test
pause preserved. [Findings and optimization order](PASSIVE_PERFORMANCE_AUDIT_2026-11-10.md).

10 November built-in minimap target/focus tracking (MINIMAP-TRACKING-20261110;
REQ-MT-01–06): native tracking-menu extension restores actual hidden Target/Focus
entries on capable Retail/Forever clients. Target defaults on; Focus stays native
until chosen; character choices survive reload/world resets with a bounded 3s retry.
Native show-all, existing rows, game-rule restrictions and enabled standalone owner
remain. Classic family without GetTrackingFilter stays inactive; enum names alone
never fabricate markers. One shared world subscription/menu modifier; no new frames,
tickers/OnUpdate/global hooks.412 focused checks x3; 8 harmful controls rejected;
full 280 scripts / 952 syntax PASS;33 source records / 26 exact Git blobs at five fresh pins.
External 2,510-source/history checkpoint and 46 read-only settings metadata entries.
Native markers/input/controller/pixels/taint/persistence/FPS NOT RUN. Prior direct
implementation/user reproduction retained. User confirms running sync program and
explicitly requests Retail-only writes; no manual cross-client install or publication.
No game input/focus or private-settings/profiler writes. Party/raid work stays paused.
[Requirements and evidence](MINIMAP_TARGET_FOCUS.md).

10 November NPC-to-window speed audit (NPC-WINDOW-OPENING-AUDIT-20261110;
REQ-VG-09): user locates delay before bank/vendor appearance. Current selection
already runs in the same gossip event without an added timer/icon lookup/UI
allocation.29exact pinned native blobs verify normal startup-loaded panels and
Forever direct show registrations;no extra preloader justified. No runtime or
settings changes, new frames/events/timers/hooks, input/focus/profiler operation
or publication. All950Lua identities and4installed gossip copies still match the
279-script passing source;no full rerun. Actual native click→response→first-draw
latency remains unmeasured;network/native/other-addon contributions unresolved.
Native timing is required before promising any additional opening-speed gain.
Earlier paused party/raid work remains paused.
[Exact source evidence and limits](validation/npc-window-opening-audit-2026-11-10.json).

10 November bank/vendor gossip checkbox and immediate selection follow-up
(BANK-VENDOR-GOSSIP-20261110; REQ-VG-05–08): separate Auto open bank defaults off;
vendor preference survives. One native checkbox appears lower-left beside Goodbye
for one available bank/vendor choice without quests. Checking saves that service
and opens now; Shift reveals it later to disable. Icons prime at login;automatic
selection runs in the same event with0asset lookups/0checkbox allocations/no added
timer. Pending refreshes cannot duplicate selection. Server/native latency/FPS
remain unmeasured. One lazy reused checkbox;two shared lifecycle subscriptions
are now required even with automation off;Forever adds its valid refresh event.
No new timers/tickers/hooks/OnUpdate/protected propagation setters.702focused x3;
10harmful controls and old source rejected;6237navigation/1253shell/36data checks;
full279scripts/950syntax PASS.82exact Gethe source blobs at existing five pins.
External2505-source/history checkpoint and105read-only settings metadata entries.
Three tested files installed inForever/progression/Era/Anniversary after approved
escalation;12copies verified;originals external. Reload required. Native NPC/
input/controller/pixels/taint/persistence/latency NOT RUN. Prior direct-design and
user reproduction choices retained. No game input/focus, private-settings/
profiler writes or publication. Paused party/raid native work remains paused.
[Requirements and evidence](20-vendor-restock-junk.md#bank-and-vendor-gossip-checkbox--10-november-2026).

10 November single-choice vendor gossip (VENDOR-GOSSIP-20261110; REQ-VG-01–04):
Loot & Items → Vendor → Automation has Auto open vendor, off by default and
per-character. On GOSSIP_SHOW it immediately selects only a sole available vendor
icon choice without quests; Shift preserves gossip. Uses native orderIndex;
Blizzard retains its own automatic selection and confirmations. One shared event
only while enabled; zero new frames/timers/tickers/hooks/OnUpdate. Retail inactive.
Fresh Gethe sources: all five pinned commits and 46 exact blobs; 321 focused
checks in three fresh runs; six harmful controls rejected; full279 scripts and
950 syntax PASS. Options navigation6222/shell1253/data-integrity36 PASS. External
2495-source/history checkpoint verified;105 settings metadata entries read-only.
Four verified feature files installed in Forever/progression/Era/Anniversary after
approved filesystem escalation;16 copies match and originals backed up externally.
Native NPC/input/controller/taint/pixels/persistence/performance NOT RUN; reload
required. Prior direct implementation/user native reproduction route retained.
No foreground/input, private-settings/profiler writes or publication. Earlier
paused party/raid native work remains paused.
[Behavior, source identities and evidence](20-vendor-restock-junk.md#single-choice-vendor-gossip--10-november-2026).

9 November Classic border fix (OPTIONS-NATIVE-BORDER-20261109; REQ-OPT-34):
Era error traced to inherited SetBorder with absent PortraitFrameTemplate layout.
Removed forced layout call; each client retains native template initialization.
Old regression stub missed this; real pinned native Lua now runs in the full shell.
Old source reproduces userLayout nil on progression/Era/Anniversary; candidate
passes1,253 checks across five models in three fresh processes.28 exact upstream
Git blobs verified with load/XML contracts. Decoration only; no focus/input/text/
settings/controller integration change. Native Era/other client retest pending;
no game input/focus, profiler/settings writes or publication. After approved
filesystem escalation, only the verified Skin file was installed in Forever,
progression, Era and Anniversary; all five copies match. Prior files backed up externally.
[Evidence](validation/options-native-border-2026-11-09.json).

9 November Forever native performance follow-up (FOREVER-NATIVE-PERFORMANCE-20261109;
REQ-RF-99): actual background-client preview stress completed with explicit
targeted diagnostic-input authorization. Solo/OOC only; server combat/roster APIs
untouched. Cold40-member preview196.1003ms, warm11.1176ms; warm party4.8791ms.
These single trials do not measure live joins or an FPS improvement. Fixed secret
resource-pulse geometry arithmetic and permission-gated vendor checkbox mouse
setters, reusing the combat queue.185 pulse/285 vendor/17050 tint checks PASS;
three vendor pairs and four harmful controls; full276 scripts/946 syntax PASS.
Ten exact API blobs;15 installed file copies match. Old debuff reader is absent.
Diagnostic18:07 errors were my lost-table readback after reload; commands guarded,
original performance report restored with3843 equal values, preview/prefs restored.
Real combat joins/leaves/subgroups and merchant input remain pending. Final client
foreground preflight caused no input. Source/history checkpoints and private
recovery data remain external; no manual sync or publication.
[Detailed evidence and limitations](FOREVER_NATIVE_PERFORMANCE.md).

9 November Inventory Awareness placement (OPTIONS-AWARENESS-20261109; REQ-OPT-33):
Inventory Awareness is inside Loot & Items > Loot, removed from Status Bars.
Original controls/callbacks/storage scope/Syndicator delegation remain. No new
sidebar entry or gameplay driver.6,207 placement/1,242 complete-shell checks PASS;
previous catalog rejected by both harnesses. Native acceptance remains NOT RUN.
[Evidence](validation/options-awareness-2026-11-09.json).

9 November HUD correction (OPTIONS-HUD-20261109; REQ-OPT-30 through32):
HUD replaces the Quality of Life sidebar page and contains Layout, Chat, Info,
Micro Menu, Flux Window and Status Bars. Windows moves to Utilities. Layout is
visible again with its original independent scope/reset and preview editor.
Flux Window contains General/Damage Meter tabs; actual Meter right-click opens
Damage Meter and expands minimized HUD. General shortcut selects General explicitly.
Old QoL links redirect; original sources/scopes/data/skins and other categories stay.
6,057 real-builder/1,217 complete-shell checks PASS across five models; five old or
harmful controls rejected and three fresh candidate runs each; full275 scripts /
945 syntax PASS with exact current corpus. External2,477-source/history checkpoint
verified;43 read-only settings metadata entries. Native visuals/drag/persistence/
input/taint/FPS NOT RUN; Witchcraft unavailable. No input/focus, settings/profiler
writes, manual sync, publication or new background goal.
[Current requirements and evidence](OPTIONS_REWORK.md).

9 November merged layout and follow-up fixes (OPTIONS-MERGED-LAYOUT-20261109):
General includes Appearance; Individual Frames has user-selected Player/Target/
Focus/Pet tabs. Unit Frame retains six sidebar entries. Loot & Items is a header
with Loot/Vendor/Restock; Restock uses the native bag icon. QoL has seven per-feature
tabs. Raid preview starts at10; explicit party preview stays5; legacy reads do not
reset data and combat entry stays guarded. Header buttons minimize/expand; search
reveals/restores state and old links expand parents. Forever background restores
visibility/alpha and disables inherited rock tiling on resize; other client skins
remain. 5,847 builder/877 shell/280 raid option-session/78 party checks PASS;
13 controls, three fresh candidate overlay runs each; full275-script/945-syntax
PASS. External2,468-source/history checkpoint and43 settings metadata entries.
Native visuals/input/persistence/taint/FPS pending. No game input/focus, private
settings/profiler writes, manual sync, publication or new background goal.
[REQ-OPT-23 through29 and evidence](OPTIONS_REWORK.md).

9 November all-client combat roster audit (COMBAT-GROUP-LIFECYCLE-20261109;
REQ-RF-98/83): checked current Blizzard secure header, visibility and event-manager
code across Retail, Forever, progression, Era and Anniversary. No new runtime
gap found. New regression executes the full native event-to-next-update manager
plus four callback orders:247385 checks over1800 transitions per run;three repeated
passes;six harmful controls rejected;50 exact source blobs and30 contracts.
Both party styles, solo/group/raid conversions, full/sparse/empty raids, subgroup
moves, MT changes, hidden parents, pets/targets and leave cleanup are covered.
Full274 scripts/944 syntax PASS; all current Lua matches the manifest and existing
runtime matches the external2463-source/history checkpoint.43 settings metadata
entries read-only;25 installed runtime copies match. No runtime change, game input,
settings/profiler write, manual sync or publication. Native taint/input/pixels/
latency acceptance remains NOT RUN. Preparation must complete before combat;
prepared roster changes do not wait for combat exit. [Mechanism, sources and
acceptance](COMBAT_GROUP_LIFECYCLE.md).

9 November sidebar header clarification (OPTIONS-UNIT-FRAME-SIDEBAR-20261109):
Unit Frame is now a framed sidebar header like Combat, with General, Appearance,
Player, Target, Focus, Pet, Party Frames, Raid Frames, Cast Bars and Nameplates as
ten clickable child rows with fitting icons. Each opens its section directly;
there is no category button or horizontal frame tab strip. One row is selected;
search/counts/hidden gates apply per child; short windows scroll above the fixed
footer. Original source roots/info paths/scopes/aliases and data remain. 5,832
real-builder +876 production-shell checks across five models; nine controls;
full273-script/943-syntax PASS. Verified external2,458-source/history checkpoint
and43 read-only settings metadata entries. Native acceptance remains NOT RUN;
no input/focus, settings/profiler writes, manual sync or publication.
[REQ-OPT-22, current hierarchy and evidence](OPTIONS_REWORK.md).

9 November steady party performance (PARTY-STEADY-PERFORMANCE-20261109;
REQ-RF-97): bar/prediction traffic now uses the existing shared painters without
full chrome/font/cast-cover rebuilds. Pet prediction is corrected, UNIT_PET is
owner-scoped, unchanged power text anchors are reused, and cold appearance events
refresh metadata immediately. Features, settings, range cadence and secure
roster/binding drivers remain. Five matched pairs/model remove936 full chrome,
800 pet style and3280 power-anchor operations in the replay; actual native lag
and FPS remain unmeasured.305 focused,1035 party and163 roster checks PASS;
full273 scripts/943 syntax PASS.51 exact upstream blobs across all five clients;
external2456-source/history checkpoint and43 read-only settings metadata entries.
All five installed copies match through existing sync. No game input, settings/
profiler writes, manual sync or publication. Prior manual testing route retained;
native latency/pixels/taint acceptance still pending. [Details and evidence](PARTY_STEADY_PERFORMANCE.md).

9 November combined quest objectives (NAMEPLATE-QUEST-LAYOUT-20261109): kill and
loot counters now share one horizontal 12-unit row, including additional objectives.
Badges fit full counts at the existing10-unit font/icon size and extend left when
the plate narrows or centered threat grows. No second row over casts; actual
native style clearance remains pending. Existing0.25s poll adjusts changed geometry
without quest rescans or settled anchor writes. No new driver resources/settings.
1,261 focused checks across five models plus8 actual threat-module checks PASS;
three old/new pairs and three harmful controls; full272-script/942-syntax PASS.
Verified external2,455-source/history checkpoint and87 settings metadata entries.
Prior direct implementation/local-check choice retained; user performs native
pixels/casts/combat/taint checks. No game input, settings/profiler writes, manual
sync or publication. [Requirements and evidence](19-nameplates.md#combined-objectives-and-dynamic-width--9-november-follow-up).

9 November category correction (OPTIONS-UNIT-FRAME-CATEGORY-20261109): Unit Frame
is now an independent top-level category beside Quality of Life, with that exact
singular label and all ten frame tabs. Combat contains Action Bars, Bindings and
Keybindings. Internal IDs, original builders, settings, scopes, aliases and icon
remain. 5,782 placement +441 shell checks across five models PASS; both wrong
nesting/name controls rejected. Native acceptance remains pending; no game input,
settings/profiler writes, manual sync or publication. REQ-OPT-21 supersedes the
earlier Combat nesting. [Current requirements and evidence](OPTIONS_REWORK.md).

9 November Unit Frames options organization (OPTIONS-UNITFRAMES-20261109): user
confirmed moving QoL Combat content into Unit Frames. Combat now contains Unit
Frames, Action Bars, Bindings and Keybindings; Utilities contains Loot & Items
and Professions. Unit Frames has General, Appearance, Player, Target, Focus, Pet,
Party Frames, Raid Frames, Cast Bars and Nameplates. Shared appearance is separated
from setup/scopes, party-style controls from compact raid/party controls; child
targets remain with their parents. Every original option object/root/info path,
handler, scope, reset, hidden/disabled condition and saved schema remains. Old
links redirect. 5,777 real-builder placement +441 complete-shell checks across
five models PASS; seven harmful controls rejected; full272-script/942-syntax PASS.
Native rendering/input/persistence/taint/performance remain NOT RUN; prior Witchcraft
setup request remains unanswered. Verified external2,447-file source/history
checkpoint and43 read-only FluxUI settings metadata entries. No foreground/input,
settings/profiler writes, manual sync or publication. The earlier native blocked
audit predates this new user-authorized implementation work.
[Requirements, current tab map and validation](OPTIONS_REWORK.md).

9 November RestedXP battlefield pins (RXP-PINS-20261109): Forever now admits
standard HereBeDragons-Pins-2.0 alongside Questie through the existing Map Pins
bridge. Original guide icons/style/tooltips and source settings remain; World Map
priority, guide-owner removal, combat deferral and toggle restoration are covered.
RestedXP v4.11.35 / HBD minor 17 inspected read-only; route lines/arrow unchanged. Six
old/new pairs reject the old rule and pass the candidate, including installed-HBD
provider replay. Full 272-script / 942-syntax validation PASS. Existing sync copied
the runtime change to Forever; no manual sync, settings/profiler writes or game
input. Verified external 2,438-file source/history checkpoint; 60 settings metadata files.
Native pixels/taint/FPS NOT RUN; prior Witchcraft route unavailable on this host.
[Requirements, exact sources and native steps](10-flux-window.md#restedxp-pins--9-november-2026).

9 November functional options sorting (OPTIONS-SORTING-20261109): latest user
clarifications are recorded in the active goal and supersede earlier taxonomy.
Action Bars has Bars, Extra Buttons and Stance Order. Consumables, Trinket Menu,
travel buttons, visibility and utility slots share the original Extra Buttons
group; Swing Timer and flight-path settings stay in Unit Frames > Player.
Loot & Items has its own Utilities sidebar page with Loot, Vendor & Junk and
Restock tabs; restock switches are grouped with the targets/editor. Bindings and Keybindings remain
separate; Quality of Life has four implemented tabs. The Meter right-click now
opens Damage Meter through a dedicated accessor; the real OnClick-to-shell route
passes and restoring the old destination fails. Compact framed icons, native
client skins and Escape entry remain. Original option identities, callbacks,
saved schemas and old links are retained. 5,158 mapping +391 shell checks across
five models; eight negative controls rejected; related meter/window checks PASS.
Full suite:272 scripts/942 syntax PASS. Native visuals/input/persistence/taint/FPS
NOT RUN; selected Witchcraft setup approval remains pending. No foreground/input
control, private settings/profiler writes, manual sync or publication.
[Current requirements and evidence](OPTIONS_REWORK.md).

9 November supported combat text audit (DEBUFF-BINDING-AUDIT-20261109): renewed
user request checked against35 freshly fetched pinned Gethe files across Retail,
Forever, Classic progression, Era and Anniversary.16 checks execute the actual
Retail/Forever Lua validators: native dispel Texture registration rejects a
FontString; aura animations reject external health/resource targets. Native type
text supports content/symbols; duration text exposes only temporal color inputs;
direct aura color lookup requires aura access. No supported binding was found for
the existing numeric labels while Retail/Forever aura data is restricted. The
all-client combat numeric-color requirement remains OPEN; no runtime workaround
was installed. Prior forbidden read stays removed; portrait/native border path,
readable Classic colors, options and saved data remain. Existing focused17,050
checks PASS; owned runtime/test hashes unchanged from the correction. No new
native operations, settings/profiler writes, sync, publication or performance claim.
[Source findings and remaining requirement](UNITFRAME_DEBUFF_COMBAT.md#supported-route-audit--renewed-request).

9 November supplied sidebar reference: accepted180x675 screenshot now drives compact framed categories, 24-unit feature rows, fixed22-unit system buttons and16-unit fitting icons on every client including Forever. Earlier icon-free styling superseded. User category relocation is implemented with4908 actual-builder mapping checks and421 complete-shell checks PASS; prior source objects/roots/info paths, valid mode lists and saved data retained. Quality of Life10tabs;Adventure/Combat/Utilities;fixed Settings/Profiles/Patch Notes/Credits. Native art/input/persistence/taint/performance NOT RUN; Witchcraft setup approval remains pending. No game input, settings/profiler writes, manual sync or publication. [Requirements and accepted reference](OPTIONS_REWORK.md).

9 November options category clarification (OPTIONS-NAVIGATION-20261109): user explicitly authorizes moving settings to match the reference. Quality of Life has all10 reference tabs; Adventure/Combat/Utilities groups and fixed Settings/Profiles/Patch Notes/Credits footer. Original controls have one primary location each; original roots/info paths/owners and saved data remain. 4898 real-builder mapping checks and266 full-shell checks PASS across five desktop clients; three harmful catalogs rejected. Forever Options tabs/minimal sliders/list headers/scroll art and Journeys backdrop use native assets; other client families retain native templates. Native pixels/input/persistence/taint/performance remain NOT RUN; selected Witchcraft setup still awaits approval. No game input/settings/profiler writes/manual sync/publication. [Requirements and placement map](OPTIONS_REWORK.md).

Craft-tier final evidence note: documentation checker reports four stale
records for concurrent options test edits after the second full run. Preserved
those edits; exact craft runtime/test hashes remain validated. Whole-tree
documentation acceptance is pending; see craft-tier source guard/report.

9 November craftable consumable tiers (CRAFT-TIER-FALLBACK-20261109): bandage,
healing-potion and mana-potion Auto slots now use the highest ranked affordable
learned recipe. Lower tiers remain available when stronger recipes lack bag
materials; material gains promote normally. Supersedes the old top-only rule.
1,609 focused checks across five client models and builtin/Syndicator; three
baseline/candidate pairs reject old source with 540 failures and pass candidate.
Full 272-script/942-syntax validation PASS twice; owned sources unchanged.
Concurrent options source changes preserved and checked; see source guard.
Existing cache/dependencies, profession routing, owned outputs and settings remain;
no new driver resources. Verified external 2,417-source/history checkpoint and
116 read-only settings metadata entries. Five installed source copies match.
No game input, settings/profiler writes, manual sync or publication. Native
clicks/pixels/taint/performance pending; no connected native tool.
[Requirements, evidence and native steps](CONSUMABLE_CRAFT_TIERS.md).

9 November forbidden debuff Texture read (DEBUFF-FORBIDDEN-READ-20261109):
user13:45:15 native GetVertexColor failure rejects the previous color bridge;
reported client/build unspecified. Removed both descendant getter operations,
retained Texture reference and prepared color objects. Keep portrait border-parent
layer fix on all five clients and native dispel border ownership. Numeric colors
use readable types and restore normal color during aura restrictions; the original
restricted numeric-color requirement remains OPEN. Fixture now rejects registered
Texture descendant access too:17,050 focused checks;five baseline forbidden-error
rejects/candidate passes;three controls;full271scripts/940syntax PASS with complete
current Lua corpus match. All five installed runtime copies match via existing
sync. External2411-source/history checkpoint and120 settings metadata verified.
No new frame/event/hook/timer/polling or suppression;no game input/settings/profiler
writes/manual sync/publication. Post-correction native error absence, portrait
pixels and taint/performance remain pending. Original desktop result is historical
rejected evidence, not native acceptance.
[Correction, source restrictions and native steps](UNITFRAME_DEBUFF_COMBAT.md).

Earlier DEBUFF-COMBAT-COLORS-20261109 is REJECTED by the user's13:45:15 native forbidden-object error. Its desktop mock allowed an inaccessible registered Texture. Retained comparisons are historical evidence only; see the [correction and open requirement](UNITFRAME_DEBUFF_COMBAT.md).

9 November options rework (OPTIONS-REWORK-20261109): replaced HUD-tinted options chrome with the running client's native portrait/inset/tab skin; reference-style grouped navigation, collapsible settings and cross-page search across all 15 existing pages. Added Escape > FluxUI Settings; existing commands, builders, data and embedded editors retained. 240 focused lifecycle checks across five desktop client models and full271-script/940-syntax checks PASS; native pixels/input/persistence/taint/performance remain NOT RUN. User chose Witchcraft in-game; it is neither installed nor connected, so setup authorization/client restart remain needed. No game input, private settings/profiler writes, manual sync or publication. [Requirements, source pins and resume steps](OPTIONS_REWORK.md).

9 November current-addon publication: include all current non-ignored source, assets, documentation and validation on main. External 2400-file source/history checkpoint and166 on-disk settings files verified. Existing full270-script/937-Lua PASS report matches the complete current Lua manifest; five publication-policy tests pass. DoctorFlux author/committer and no co-author trailers are required by active hooks. Native acceptance limitations remain unchanged.

9 November native bag item targeting (BAG-ITEM-TARGETING-20261109): matched
Forever saved12:44:34/count3 report and pinned70862 native right-click body;
user clarified an item targeting another item. First taint writer unresolved;
no speculative interaction fix. Added bounded `/fluxinput bags` before/10-second
metadata;574 focused checks and five related suites PASS, old-source rejection.
External2395-source/history checkpoint verified;120 settings metadata entries.
Host verified running Forever window read-only; no input/settings/profiler writes,
manual sync or publication. Full270-script/937-syntax validation PASS; complete Lua corpus unchanged.
User lacks original items; latest verbose log has no matching bag/action trace
or saved bag capture. No new crate required. [Future reproduction](BAG_ITEM_TARGETING.md).

9 November Baganator junk activation (BAGANATOR-JUNK-ACTIVATION-20261109):
user explicitly requested the addon fix after the detector diagnosis. The junk
bridge now selects FluxUI once per active Baganator profile, retains the previous
detector in additive profile metadata, emits the normal setting notification and
refreshes widgets/searches/layout. Later manual choices persist; inactive profiles,
consumable ranking, Useful/restock/conjured/gear protections remain. One BagShow
callback; no new frame/timer/polling.403 focused checks; five old/new pairs reject
old code (162 failures) and pass candidate. Full269 scripts/936 syntax files PASS;
source corpus unchanged after validation. Native coins/categories and actual
settings persistence pending user reproduction; no connected native tool.
Verified external2389-file/history checkpoint and56 read-only settings metadata.
No game input, on-disk settings/profiler writes, manual sync or publication.
[Requirements, sources and acceptance](BAGANATOR_JUNK_ACTIVATION.md).

9 November Baganator missing consumable junk (BAGANATOR-JUNK-DETECTOR-20261109):
read-only diagnosis found Forever Baganator846 saved DEFAULT junk detector
RXPGuides; sampled FluxUI inferior switches are enabled. Baganator calls one
selected plugin; registering FluxUI does not activate it over RXPGuides.
Select General > Junk detection > FluxUI, reopen bags and verify lower potions,
bandages, food and water against a better usable carried tier. Preserve explicit
Useful/manual restock/conjured protections. Saved disk state is not a live-session
observation. Existing combat1020checks and junk/Baganator smoke PASS; native
selection/coins/category acceptance pending user reproduction. No runtime edit,
settings write, game input, profiler change or publication; no new performance
claim. [Exact inspected sources and checks](validation/baganator-junk-detector-2026-11-09.json).

9 November focus colors (FOCUS-TARGET-COLORS-20261109): compact focus now
uses the shared target color painter for its own focused unit instead of the
party/player accent policy. Main/portrait/outer/atlas borders, backdrops, compact
divider, cast shell/icon and threat shell follow target's class/NPC palette;
combat portrait red restores those colors. Party class-color controls remain
party-only; focus layout, HP/resource fills, aura options and settings remain.
21,985 focused checks across five client models and 66 portrait-restore checks
pass; five old-source rejects/candidate passes and 10 matching installed source
copies retained. External 2382-file/history checkpoint verified; 120 settings
metadata entries read-only. No new frame, event, timer, polling or settings;
native pixels/taint/performance pending. All 268 scripts and 935 syntax files
PASS with no source drift.
[Scope and evidence](UNITFRAME_COMBAT_TRANSITIONS.md#focus-colors--9-november-follow-up).

9 November quest badge compact follow-up (NAMEPLATE-QUEST-COMPACT-20261109):
user requested shorter/smaller tags and an icon that fits inside without crowding
threat. Quest-only count font12->10, icon12->10, host14->12; total horizontal
padding/icon space28->16 with2-unit left/gap/right insets and1-unit vertical icon
clearance. TOPLEFT Y+3 preserves centreY-3 shared with threat/level; row spacing16.
Quest associations/progress, optional Questie policy and native fallback unchanged.
371 focused checks plus existing combo/cast-school regressions and syntax PASS.
Full267-script/934-syntax verification PASS with no source drift; native visual
check remains user-owned.
External current source/history checkpoint verified;87 settings metadata inspected.
No game input, settings/profiler writes, manual sync or publication.
[Feature and acceptance](19-nameplates.md#quest-kill-and-loot-progress--9-november-2026).


9 November unit-frame combat transitions (UNITFRAME-COMBAT-20261109): target
click host now retains prepared mouse input under native visibility; compact
focus-target width survives global squeeze and deferred combat sizing. Party
widths are verified through modeled combat roster transitions. Focus/party/pet
vertical strips support shields and heal absorbs through shared full-height
native sinks/clipping, existing options and safe events. 285 visibility/30 width/
2785 vertical/1035 party checks pass, plus existing menu/geometry checks. Five
baseline-reject/candidate-pass pairs per fault retained; all 267 scripts and 934 syntax files
PASS, no source drift; 20 installed runtime copies match.
External verified 2362-file/history checkpoint and 120 settings metadata retained.
Four display frames per strip plus modern calculator and one target native
visibility registration are explicit feature costs; no new poll/ticker/event
frame. Native clicks/taint/pixels/performance pending on all five clients; no
connected test tool, game input, settings/profiler writes or publication.
[Scope, sources and steps](UNITFRAME_COMBAT_TRANSITIONS.md).

9 November rejected cast bar (CAST-REJECTED-20261109): terminal failure/stop
feedback now requires an active visible cast/channel. Cooldown and other rejected
attempts cannot summon an idle bar or replace finish/interrupt/custom-timer state.
Valid interruption/completion, secret-safe routing and appearance retained.
24,775 focused checks across five clients; five baseline/candidate pairs and
three rejected controls; party215/timer379 and full267-script/934-syntax checks
PASS with no source drift. Five mirrored runtime
copies match. Native input/events/taint/pixels/performance pending; no connected
test tool, client/settings/profiler interaction or manual sync. Verified external
2,364-file/history checkpoint and125 read-only settings metadata entries.
[Scope and evidence](CAST_REJECTED_ATTEMPTS.md).

9 November nameplate quest progress (NAMEPLATE-QUEST-PROGRESS-20261109):
added default-enabled own kill/loot icon and current/required counts, TOPLEFT at
health-container BOTTOMLEFT 0,+4 (14-high host centreY -3, matching threat/level); additional objectives stack down. Inline existing
Core/defaults/options; no new runtime module or quest database. Questie lookup
and ready/update notifications; native tooltip + active-objective fallback;
duplicate Questie world-nameplate option disabled and old markers cleared.
Two exact supplied default icon textures with original restriction notice.
311 focused checks, baseline rejection and seven harmful controls PASS; six related
regression scripts PASS and four owned Lua identities unchanged; latest full263/265 scripts PASS with two
unrelated unit-frame mock failures;932Lua syntax PASS. Five desktop contracts; native render/combat/taint/CPU/FPS
pending. User chose direct implementation and will test in-game. External dated
source ZIP/history bundle verified;87 on-disk settings metadata entries inspected.
No game input/settings/profiler/sync/publication. Existing dirty work preserved.
[Requirements and acceptance](19-nameplates.md#quest-kill-and-loot-progress--9-november-2026).


9 November menu press input (MENU-PRESS-20261109): food/water/bandage/healing
potion/mana gem/mana potion/healthstone/trinket HUD mouse and use/conjure bindings
now activate on press. Shared wrapped policy ignores release CVar for HUD keys;
Forever unwrapped policy honors onDown with native AnyDown. Ordinary hosts retain
their existing policy. 4,284 focused checks across five existing clients; five
baseline-reject/candidate-pass pairs and two rejected Forever controls. All five
mirrored runtime hashes match.
Native physical input/combat/taint/pixels/performance pending; no connected test
tool, client interaction, settings/profiler writes or manual sync. External dated
2,351-file/history checkpoint and125 settings metadata verified. Full265-script/
932-syntax validation PASS; no source drift. Result linked in [scope and evidence](MENU_PRESS_INPUT.md).

9 November repository replacement completed per explicit request. Verified
2,340-file source ZIP,166-file on-disk settings ZIP and all-ref bundle externally;
preserved original index/config and both patches. Exported remote metadata;
zero issues/pulls/releases/tags/forks. GitHub device authorization completed for
the required deletion scope. Deleted old1416752820, created new1451123700 at the
same URL, and pushed fresh main root be90cdcc2f14 with2,344 files. Verified exact
remote tree, no parents, DoctorFlux author/committer and sole main branch; only
DoctorFlux in contributor API. Local main adopted that verified snapshot without
changing working files. Identity workflow42587961744 succeeded; five policy tests
and actual hook rejection pass. Lua manifest unchanged from263/930 PASS;
docs963sources/602reachable/15630links PASS. No runtime/settings changes or force
push. The CLI unexpectedly copied its device code despite no clipboard flag;
reported promptly. Later browser opening was explicitly authorized by the user.
Completion records are a normal follow-up publication commit.
Final repeat-push check reproduced an empty-input hook rejection on an already
up-to-date main. Allow that no-op while retaining complete checks for real
updates; regression and actual dry-run checks pass.
[Evidence](validation/repository-publication-2026-11-09.json).

9 November FOCUS-SECURE-VISIBILITY-20261109: preserved actual-file/history/settings
checkpoint before three runtime-owner edits. Replaced focus alpha-only watch
with existing native visibility service; paired lifecycle registration/removal;
retained prepared combat clicks. Broadened native unit-menu routing after user
reported player callback failures despite target success. Kept dependent menus
and native focus macros per explicit choice. Source verification covered20
primary blobs; local references stayed read-only, including a documented test
adjustment for Forever's no-argument native ClearFocus responder.70/670/620
focused checks PASS; five alternating before/after pairs and three old-owner
controls retained; full263 scripts/930 syntax PASS; manifest stable;15 synced
runtime copies match. Guarded background reload/read and native focus/clear test
passed on Forever70862 with BugTabs0, no foreground change and empty focus
restored. User confirms player-menu and combat macro acceptance. No profiling,
binding/settings changes, new polling, commit or push. Native group-menu,
physical hit testing, pixels/performance and other clients still pending.
[Report](FOCUS_SECURE_VISIBILITY.md).

9 November remaining native acceptance is blocked by the background-only rule:
Windows repeatedly reports Forever foreground. The latest alias probe refused
before its first key; the bounded35second availability process ended with no
stable non-game foreground and no input. Same condition recurred across three
goal turns; prior native progress is retained, not marked complete. Native slash
entry/Escape source ownership is verified, but no editor interaction ran. Current
261/928 source manifest still matches; no runtime/settings/profiler changes.
Resume with browser/chat continuously active and Forever behind it; verify normal
Edit Mode/custom save, matched previews, resource characters and other clients.
[Blocked audit](validation/cooldown-native-blocker-2026-11-09.json).

9 November native cooldown acceptance: Forever1.60.1/70862/16001 retained
exactly one selected FluxUI profile after a guarded native reload. BugTabs0;
all four sampled aura-map fields secure. All requested settings match the native
active layout. Four viewer positions match planned column offsets and4UI-unit
clearance from current player bounds within0.001units. This mage has no visible
class-resource row; Arcane/combo/form cases and other native clients remain open.
Native custom-save and matched preview pixels are also pending. Full261/928 and
documentation961sources/602reachable PASS. No runtime changes or preferences
changed; no foreground/mouse/clipboard control, gameplay or publication.
[Native evidence](validation/cooldown-native-acceptance-2026-11-09.json).

8 November every Info Frame stat audit (INFO-ALL-STATS-20261108): expanded the
earlier combat fix to all42 built-in keys and unknown dynamic pins.35 additional
keys now have live native display paths or retain public inventory providers;
spell/heal bypass old snapshots and partial CSC scans. Corrected signed AP,
versatility bonus and leech/avoidance totals; preserve compact merging and live
proc expiry. Native sums/scaling can require live component expressions; speed
can use yards/second. Hidden row-only custom stats remain unavailable. Do not
claim universal exact single-number support.645 new +234 prior focused checks;
five baseline rejects/candidate passes and four controls; full261/261 scripts,
928 syntax PASS with no source drift. No new frame/timer/hook/settings;13 native
event registrations reuse existing coalescer. Native acceptance remains OPEN;
no connected test tool. External verified2310-source/history checkpoint and52
read-only settings metadata retained. No game input/settings/profiler/diagnostic
writes or publication. [Scope and limits](INFO_ALL_STATS.md).

8 November cooldown acceptance audit: full current checkout261 scripts/928 Lua
PASS; complete normalized source manifest matches. This supersedes the previous
unrelated verification drift while preserving the newer stat files. All four
accepted images re-inspected; implementation remains unchanged. Completion is
not established: native saved settings/geometry, second reload/custom-save,
class-resource cases and other available clients still need matching evidence.
Forever was verified active/foreground; reload and settings probes refused before
input. Read-only screenshot confirms ongoing play, without changing focus. No
runtime/settings/profiler changes or publication. Keep the full goal active.
[Requirement audit](validation/cooldown-final-audit-2026-11-08.json).

8 November missing FluxUI profile (COOLDOWN-PRESENCE-20261108): latest user
instruction supersedes the earlier deliberate-deletion policy. Check actual native
layout existence, create one FluxUI profile when absent even after a prior save,
and leave an existing profile/custom selection unchanged. Reuse shared readiness,
combat/editor queues; retain recovery data and avoid repeating legacy retirement.
202 focused checks/five alternating baseline-candidate pairs PASS; old source
reproduces the failure. Full260 scripts/926 Lua PASS; owned sources unchanged.
Later unrelated FluxInfoFrame work preserved and its234checks PASS.
Forever70862 guarded reload created/selected exactly one FluxUI; BugTabs0 and
tracker top gap0/clampfalse. Reload persistence pending: foreground guard refused before input. Other clients,
matched visuals/combat/performance remain pending. No profiler change, foreground,
mouse or clipboard control, gameplay, commit or push.
[Evidence](COOLDOWN_VIEWER_DEFAULTS.md).
Documentation checker exposed newer unrelated FluxInfoFrameStats/source changes;
refresh full verification/inventory after that independent batch settles. Preserve
those files; current presence owner/tests still match the passing capture.

8 November tracker top recovery (TRACKER-TOP-20261108): native Forever evidence
confirmed the inner tracker's screen clamp displaced its first quests above the
viewport at scroll offset0. Disable that clamp inside the fixed viewport; settle
cached height and schedule coalesced sync after native profile anchors, deferring
while Edit Mode owns the frame.62 source-model checks/five baseline-candidate
pairs and full260 scripts/926 Lua PASS; source manifest stable. Permanent source
reload and native wheel down90/back0 pass on Forever70862 with BugTabs0; native
profile refresh, sustained combat and other clients remain separate checks.
The earlier deletion was intentional. The subsequent missing-profile request
supersedes that policy: create FluxUI when absent; preserve existing layouts. No settings/profiler changes, foreground/mouse/
clipboard control, gameplay, commit or push. [Evidence](OBJECTIVE_TRACKER_TOP.md).

8 November cooldown defaults (COOLDOWN-DEFAULTS-20261108): latest user choice
is one FluxUI layout for all four native cooldown groups. Single-profile source
and migration implemented; custom/native layouts remain. Only recorded,
unchanged test copies can be retired after exact native export comparison, with
bounded recovery data. Edited/unverifiable profiles stay intact.186 focused
checks, five repeated scenarios and four harmful controls pass. Full260-script/926-Lua validation and documentation959-source/601-load-closure
checks pass with zero source drift;15 installed source files match. Forever70862 public-save metadata
PASS; user reports the prior two-copy build worked. The final guarded reload was refused before input because WoW was foreground.
Single-profile native reload/persistence/save/combat/pixels and other clients
remain pending.
Keep WoW background; do not interrupt auction/mail/trade or gameplay. No profiler
change, native preset patch, commit or push. [Requirements/evidence](COOLDOWN_VIEWER_DEFAULTS.md).

8 November Edit Mode ownership (EDIT-MODE-NATIVE-20261108): read both logs,
current state and fresh five-client pins; verified external source/history/settings
checkpoint. Corrected four existing owners; actual-owner/native-method regression
and evidence-retention tests reject old code.295 focused; full259/924 PASS with
stable Lua corpus;22 blobs/60 exact native excerpts and20 installed copies verified.
User-operated Forever save/viewer reports no new errors; saved snapshots absent.
Background command guards refused before input; read-only capture left focus
unchanged. No automated saves/reloads/settings/profiling/gameplay. New cooldown
reference/default goal recorded; implementation in progress.
[Evidence](EDIT_MODE_NATIVE.md).

8 November combat numeric-color capability audit
(COMBAT-NUMERIC-TINT-CAPABILITY-20261108; REQ-RF-96): user again requests actual
HP/resource values and percent to match the native border during combat on
player/target/focus/party. Latest branch heads re-resolved for all five clients;
Retail12.1.5.70783 and Forever1.60.1.70862 retain texture-only private dispel-color
sinks. SetDispelTypeText replaces values with a symbol/static label; it does not
color arbitrary live numeric text. Descendant/object-type/access restrictions
prevent registering external numeric fonts or reading private texture colors.
106pinned callback/validator probe checks plus13230existing lifecycle checks pass;
this does not implement the requested restricted-combat text change. Unrestricted
combat coloring remains available; native private border coloring remains. No
runtime changes, new polling/caches, game input or profiler/settings writes.
Exact all-client restricted numeric coloring remains unavailable through verified
exposed APIs and must not be marked complete. [Evidence](COMBAT_NUMERIC_TINT.md).

8 November universal mouseover (UNIVERSAL-MOUSEOVER-20261108): verified main
and external source/history/settings checkpoint before changing three runtime
owners. Preserved all existing dirty work, including Apply's prior pool-name fix.
Reproduced compiler gating/free-chord/extra and click-polarity failures against
the actual archived sources. Added tests with 916 assertions, native/fallback
modifiers, explicit rules, flags, form/rank, equipment extras and badge contracts;
five pairs reject203 old assertions and pass current; each old owner rejects
independently. Existing native4984/binding3210/bar suites pass. Full258 scripts/
923 syntax PASS; no Lua source drift. Fifteen fresh upstream blobs and15 installed
copy hashes recorded. Host process/window and read-only screenshot verify Forever;
foreground guard prevented input. No gameplay, reload, settings/profiler write,
focus/clipboard control or publication. Native checks remain pending.
[Evidence and steps](UNIVERSAL_MOUSEOVER.md).

8 November group roster performance (GROUP-ROSTER-PERFORMANCE-20261108;
REQ-RF-95): ordinary invites now reconcile prepared membership without hiding/
reconfiguring all headers or reapplying party/extra layouts. Retry incomplete party/optional-driver setup; keep full startup,
settings and readiness recovery, with combat visibility owned by native drivers.
Reuse the raid paint batch; combine party/pet show+roster paints, cast resampling
and range wake; coalesce optional pet/target paints and hover discovery. Roster
changes skip stable binding-data rebuilds; Edit Mode, settings/routing changes and
deferred combat registration still refresh. Aura checkbox/type/unit isolation stays.
Five matched pairs on five client models have invariant counts:213direct header
attribute writes->0;60hover discovery passes->1;920extra rebinds->0;5520extra protected
writes->0;800raid paints->40;168normal-party/pet paints->8. These are20-event replay
counts, not native FPS or latency measurements.163focused checks and twelve harmful
controls pass/reject; benign redundant-guard removal stays safe via inner guards.
Fresh35pinned upstream blobs verify; native source replays pass255908secure and58
member-order checks in desktop models. Full257/257scripts and922Lua syntax pass;
owned hashes and five installed copies match. New paints use bounded coalesced
After queues; no new ticker/event frame/OnUpdate. Source/history98files and47settings
metadata retained outside AddOns; no game input/profiler/settings writes/publication.
Actual client invite latency, rendering, protected VM/taint and performance pending.
[Evidence](GROUP_ROSTER_PERFORMANCE.md).

8 November friendly aura checkbox policy (FRIENDLY-AURA-POLICY-20261108;
REQ-RF-94): supersedes only RF93's unconditional dispellable-only rule. Checkbox
off now allows known typed harmful debuffs; on restricts to HARMFUL|RAID. Keep RF93
per-unit ownership, event routing and same-token target/focus refresh. Explicit
frame/Flux checkbox false wins over unrelated native CVars; use the relevant
Blizzard preference only without a Flux override. No combined global OR state.
One native owner per chrome part switches its public slot filter in place;
includeDispelTypes skips unknown candidates. Public/legacy bounded scans skip
unknown types too, so an untyped first entry cannot mask a later known one.
Portrait backdrop/fills and saved values remain unchanged. Native private border
colors/public-only numeric tint remain; real game pixels/taint/performance pending.
13270 focused checks pass across five clients/two providers, including both toggle
directions, conflicting settings, known-after-unknown and independent live-unit
palettes. Baseline plus eight controls rejected; five matched correctness pairs
retained. Full256/256scripts and921Lua syntax pass; owned hashes match tested source.
External source/history plus47settings metadata retained; all five installed
copies match via user sync. No game input/settings/profiler writes or publication.
[Evidence](validation/friendly-aura-policy-2026-11-08.json).

8 November Info Frame live combat stats (INFO-COMBAT-STATS-20261108): the user chose
to keep the previously highest category live while combined stats are restricted.
Forever now remembers category identity rather than switching to melee; Retail
Crit/Haste use native getters throughout instead of partial CSC scans. Procs and
expiration stay live; ammo haste and correct hit rating/modifiers are retained.
No cached percentages or new runtime driver/settings. 234 focused checks pass;
five baseline rejects/candidate passes and four negative controls; final
256/256 scripts and 921 Lua syntax files pass with no source drift.
Native secrets/taint/pixels/performance remain pending; prior UIForever preference
retained but no connected testing tool. External verified source/history and
52 read-only settings metadata entries retained. No game input, settings,
profiler, diagnostic-root writes or publication. [Contract](INFO_COMBAT_STATS.md).

8 November friendly dispel isolation (FRIENDLY-DISPEL-ISOLATION-20261108;
REQ-RF-93): supersedes RF92's ordinary-debuff tint fallback. A known type alone
cannot trigger frame color: live chrome/numbers now use only HARMFUL|RAID, the
client player-dispellable filter, even when other debuff icons are visible. Unknown
or non-dispellable effects leave normal colors. Native SetUnit skips unchanged
unit tokens and has no target/focus identity event: explicitly refresh the public
owner on target/focus swaps, roster/world/show/options invalidation. UNIT events
only queue the matching unit or a verified alias; no shared color/strict state.
Regression now gives player, target, focus and party different simultaneous aura
data; covers alias swaps without UNIT_AURA, target=self, hostile/roster changes and
combat no-allocation. 9686 focused checks pass across five clients/two providers;
exact native SetUnit replay, baseline plus six rejected controls and five matched
correctness pairs retained. Full255/255scripts and920Lua syntax pass. Up to three
native owners/frame replace six; addon driver/timers unchanged. Native private
border colors/public-only numeric tint remain as documented; actual game pixels,
secret data, protected VM/taint and CPU/memory/FPS still pending. External verified
source/history plus47settings metadata retained; owned source hashes and all five
installed copies match. No game input/settings/profiler writes or publication.
[Evidence](validation/friendly-dispel-isolation-2026-11-08.json).

8 November friendly debuff chrome (FRIENDLY-DEBUFF-TINT-20261108; REQ-RF-92):
known debuff types tint portrait and HP/resource border overlays plus numeric
value/percent text on friendly player, player-style party and friendly target/focus.
Portrait backdrop and HP/resource fills remain unchanged. Missing/unknown types
keep normal colors. Prefer dispellable types; honor Blizzard showDispelDebuffs and
raidFramesDisplayOnlyDispellableDebuffs plus the party strict option; refresh on
CVAR_UPDATE. Restore on hide, hostile transition, option disable or removal.
Native descendant Texture slots handle private border colors on Retail/Forever;
existing HP/resource FontStrings have no native private dispel-color binding, so
text uses readable known types and restores normal color while restricted. Classic
uses its client display table and guarded public aura data. No private-child reads,
new settings or protected combat construction. Preview uses the same public color
path. 8632 focused checks across five client models/current and legacy providers,
six rejected controls, 255/255 scripts and 920 Lua syntax files pass. Owned hashes
match tested source; all five installed copies match through user sync. One event
driver/coalesced batch; up to six native slot owners per eligible frame; their
native update cost is not measured. Real pixels, secret data, protected VM/taint
and performance acceptance remain pending. External source/history and 47 read-only
settings metadata entries retained; no game input, manual sync or publication.
[Evidence](validation/friendly-debuff-tint-2026-11-08.json).

8 November carried combat-consumable junk (JUNK-CARRIED-COMBAT-20261108):
verified external checkpoint2264source/188on-disk settings/history on main;
preserved unrelated work. Three runtime owners now use actual carried upgrades
for automatic marks/rules/display/availability/pending sales. Added1020checks;
five matched pairs reject baseline720failures and pass candidate; four controls
reject. Five optimization pairs remove6000warm redundant count queries with no
warm bag walks. Final255scripts/920syntax PASS
with unchanged source; earlier independent debuff-tint changes retained.
Twelve destination copies match via user sync. Native pending; no game input,
settings/profiler writes, commit or push. Source documentation and15,439local
links also PASS. [Results](CARRIED_COMBAT_CONSUMABLE_JUNK.md).

8 November stable owned grid buttons (GRID-STABLE-OWNED-20261108): external
checkpoint Craft-grid-placeholder-20261108T090008Z verified2258source files,
179on-disk settings and history; unrelated main work retained. Changed only the
classifier rejection query, potion eligibility and existing owned-slot gate.
Added620transition/craft/zero/mode/combat checks; five alternating matched pairs
reject baseline224assertions and pass candidate, with three negative controls.
Placeholder calls36 ->0; visibility transitions76 ->0; rebinds20 ->0 across30cases.
Full253/253scripts and917syntax PASS; source guard unchanged. Twelve installed
copies match via existing continuous sync. Native pending; no input/reload,
profiler/settings writes, commit or push. Generated documentation/source coverage
and15,410local links also PASS. [Results](CONSUMABLE_CRAFT_IDENTITY.md).

8 November native combat unit menus (UNIT-COMBAT-MENUS-20261108; REQ-RF-91):
unit-frame hit rectangles now use Blizzard's secure menu action and direct
native callback, including party/pet/vertical targets, raid and MT mini cells.
Target/focus retain their specific native menu; generic slots follow their
current secure unit attribute through combat group changes. Prepare attributes
OOC; defer optional menu edits through the existing queue. Keep native click-
cast and explicit Flux hover-program precedence. No addon popup dispatcher,
new event/frame/polling or saved-data change. Ten source blobs fetched across
Retail, Forever, progression, Era and Anniversary; exact pinned native replay
passes 680 checks and rejects three controls. Existing 1010 party, 182 raid
binding and 310 party hover checks pass; 252/252 scripts and 916 Lua syntax files pass.
Owned final hashes and five installed copies match. Actual hardware/protected
VM/taint/native menu input remains pending. Dated source/history and 45 read-only
settings metadata entries retained. [Evidence](validation/unit-combat-menus-2026-11-08.json).

8 November grid bag/craft visibility (GRID-BAG-CRAFT-20261108): user clarified
that Auto potion/bandage slots stay visible with no carried output and no
currently affordable craft; Forever healing potions must use First Aid.
Reliable live bag reagent counts now override delayed positive snapshots.
The existing native notification invalidates craft cache and reuses the bounded
craft timer to refresh right-click and visibility, including empty output slots;
Off skips that native craft work. Existing Forever FirstAid129 versus Alchemy171
routing is retained/tested. Secondary metadata fix preserves pending state across
cache invalidation before selector notification. Four small runtime edits; no
new frames/events/hooks/tickers/saved roots or settings reset.1,030+439 focused
checks pass across5client models with/without provider; native acceptance pending.
Final full validation:251/251 scripts and915 Lua syntax files PASS; source
hashes unchanged throughout. Five alternating pairs per component reject the
baseline(100metadata/45craft assertions) and pass all1,469candidate checks;
six faulty mutations reject. Existing zero-reset375 and consumable1475 checks
also pass. All16 existing client file copies match through user continuous sync;
three read passes, no manual copy/second overwrite. Native candidate checks
remain pending; no new game input, settings/profiler writes, commit or push.
After that completed full/doc run, independent unit-frame files changed.
The four consumable owners and both tests remain at their tested hashes; those
later edits and current global generated freshness require their own validation.
No later whole-addon pass is inferred. See the recorded post-run drift list.
[Case](CONSUMABLE_BAG_VISIBILITY.md).

8 November Blizzard party debuff borders (PARTY-BLIZZARD-DEBUFF-BORDER-20261108; REQ-RF-90):
latest user clarification replaces the custom red/black rim in REQ-RF-89 with
Blizzard's own type border. Retail/Forever use native colored border atlases;
Classic preserves and tints UI-Debuff-Overlays through client AuraUtil. Native
owners handle restricted types, including the default untyped harmful border.
Readable icons and preview use the same client helpers; type colors remain
independent of the whole-frame dispel-highlight toggle. Layout/opacity/timers/
strict filters/input remain. One border texture replaces the custom edges.
12776 aura, 1010 party, 2944 layout and 1580 native-style routing checks pass;
250/250 scripts and 914 Lua syntax files pass. Final owned hashes and five installed copies
match. Native appearance/taint/performance remain pending. Source/history and
45 read-only settings metadata entries retained. [Evidence](validation/party-blizzard-debuff-borders-2026-11-08.json).

8 November party debuff borders (PARTY-DEBUFF-BORDER-20261108; REQ-RF-89):
normal party debuffs now have a solid dark-backed rim on their existing text
host above the cooldown swipe, including plain/non-dispellable categories.
Native dispel colors remain native-owned; readable and preview edges share
styling. Preserve icon sizes, zero gaps, opacity, timers, filters and input.
12776 aura, 1010 party and 3310 external style/ownership checks pass; full
249/249 scripts and 913 Lua syntax files pass. Final source hashes match the
suite and all five installed copies. Native contrast/pixels/taint/performance
remain pending. Eight textures per prepared party debuff; no new frame,
event, polling or timer. Dated source/history checkpoint and 45 read-only
settings metadata entries retained. [Evidence](validation/party-debuff-borders-2026-11-08.json).

7 November unit names/ToT and party cast lifecycle (UNIT-NAME-PARTY-CAST-20261107;
REQ-RF-87/88): fitted public names now retain their final text/font on repaint,
using unclipped metrics and the actual compact header width. Restricted current
names/surnames use native text sinks; unavailable identity clears old names.
ToT fitting guards restricted label reads and keeps its public fitted result.
Party cast hide/rebind clears stale cast/hold/fade/art/text; show and roster
updates read the current cast. Scoped terminal events accept missing GUIDs while
rejecting distinct readable identities/spells. Existing appearance, finish/
interrupt cadence, options, Flux bindings and saved-name settings remain.
681 name/ToT, 215 cast lifecycle and 1010 party/focus integration checks pass;
379 timer, 55 name-secret and 13942 school checks pass. Both regressions reject
the dated baseline. Full 249/249 scripts and 913 Lua syntax files pass, with
exact final owned hashes and all five installed copies matching. Native
Retail/Forever appearance, real secrets, input, taint and performance remain
pending. Exact existing Gethe pins revalidated; current branch-head lookup was
unavailable, so no latest-build claim. Verified external source/history and
45 settings metadata entries retained; no live settings/input/profiler changes.
[Evidence](validation/unit-name-party-cast-2026-11-07.json).

7 November roadmap implementation (ROADMAP-FIXES-20261107): all25 qualified
round-2 groups now have source fixes and focused desktop acceptance. Bindings
retain distinct punctuation/minus chords, exact modifier truth and latest held
tint; cancellation/reentrant completion belongs to the latest request. Owned
timers/retries/proxies are bounded, salvage defers protected combat writes and
public frame-level/color facts avoid opaque arithmetic. Vendor mount lookup is
localized/cached; disabled optional reticle work stops scanning faces. Range
uses unit-scoped fresh memo answers, action-scoped unknown state and independent
usable/red/pressed layers, retaining existing palette/art/features/saved data.
Full combined validation: 247/247 scripts PASS, 911 Lua syntax files PASS;
exact final suite hashes match. Rapid core/binding/EBS/utility/badge, same-slot
Context and range/usability/darkening replays pass with matched baseline rejects.
Prior Forever startAlpha fade-manager replay passes again. These are desktop
models; native secure VM/real secrets/input/pixels/taint/CPU/FPS remain pending.
Newer consumable, aura, vertical target health, PvP and minimap work is preserved.
External source/history checkpoint plus45 settings metadata entries retained;
no settings reset, foreground/game/profiler/WTF writes, branch, commit or push.
[Evidence](../Stress%20test%20doc/roadmap-fixes/README.md).

7 November universal vertical target health (VERTICAL-TARGET-HEALTH-20261107; REQ-RF-86):
party, compact focus and pet target strips now share HP/color/effect handling.
The loss gap follows the vertical height with native .25/.1/.05/.05 timing;
repeat hits retain the trailing edge. Target replacement, hide, resizing,
healing, max-health changes and zero maximum clear old trails. Secret values
use native StatusBar sinks and generation-cancelled catch-up without arithmetic;
status colors and optional target class colors remain. Effects prewarm OOC even
when disabled; target geometry defers in combat. Existing secure visibility,
Flux hover bindings, sizes/anchors and focus aura packing remain unchanged.
Five pinned Gethe UnitFrame blobs verified. 1243 vertical,995 party/focus,
80 public geometry,46 secret overlay and206 identity checks pass; full 236/236
scripts and 900 Lua syntax checks pass. Exact final owned hashes match the suite.
Native rendering/taint/input/combat/performance acceptance remains pending.
Fresh external source/history checkpoint and 45 read-only settings metadata
entries retained; no live settings/profiler/input or manual mirror actions.
[Evidence](validation/vertical-target-health-2026-11-07.json).

7 November focus aura packing only (FOCUS-AURA-PACKING-ONLY-20261107; REQ-RF-85):
latest user instruction supersedes the target-inclusive width in REQ-RF-82.
Restore original focus body/portrait aura width and remove the right target-strip
extension. Keep full-width native/Lua icon packing so more fit before wrapping;
icon size, spacing, timer/filter controls and corrected header anchor remain.
Target settings no longer resize aura panels. Existing secure combat group reveal
and portrait backdrop restore are retained.1011 geometry/packing,995 party/focus,
66 portrait,47 scale and36 timer-policy checks PASS; 235/235 scripts PASS; 899 syntax files/0 failures.
Owned final hashes match. Native visual acceptance remains pending. No new runtime
resources or saved-data change; unused target-width helper/lookup removed. Fresh
external history/source checkpoint and 45 read-only settings metadata entries kept;
no foreground control, game/WTF/profiler write, manual sync, branch or push.
[Evidence](validation/focus-aura-packing-only-2026-11-07.json).

7 November group visibility/focus row/portrait restore (GROUP-VISIBILITY-FOCUS-ROW-RESTORE-20261107; REQ-RF-82/83/84):
user screenshot shows remaining focus aura mismatch; user explicitly includes the
right target strip and wants more icons per row. Aura halves now cover that full
configured row and attach directly to the compact header (including initial/
re-enable paths), avoiding the old threat-shell reservation. Compact native/Lua
packing uses full width before wrapping. Existing independent icon/caption origin
changes are preserved; native offsets refresh on changes and cache steady writes.
Blizzard SecureStateDriver/SecureGroupHeaders and party/target sources were fetched
at21 exact blobs across5 pins. Native header roster updates require visible parents;
Flux secure group handlers now reveal the prepared parent too. Normal party uses
one added native group driver on the existing hub, removed on disable. Existing
OOC slot preallocation/native leaf visibility remains; no addon combat allocation
or ordinary protected Show/Hide. Party/focus normal portrait paint now hides the
red plate before restoring its theme, including unit-combat exit during lockdown.

1011 aura geometry,995 party/focus,255908 native-source secure-model,1160 pool/
readiness,66 portrait,310 binding,78 restricted,47 scale and36 timer-policy checks
PASS. Old party/portrait source rejects the regressions. 235/235 scripts PASS; 899 syntax files/0 failures;
owned final hashes match. Native current pixels/taint/real combat/input/CPU/FPS
NOT RUN; screenshot is prior user evidence, not current-source acceptance. No new
runtime regions/timer/ticker/global hook; one native driver reuses the hub.
Fresh external checkpoint/history and 45 read-only settings metadata entries kept;
independent concurrent edits preserved. No foreground control, game/WTF/profiler
write, manual sync, branch or push. [Evidence](validation/group-visibility-focus-row-restore-2026-11-07.json).

7 November consumable tint and focus aura positioning (CONS-TINT-01;
UF-FOCUS-AURA-02): ready item state now owns the shared tint; reliable native
unknown/false results stay item states rather than being replaced by an
uncastable use-effect spell. Regular items and item macros share native item
range. Empty/mana/unusable/OOR feedback remains; managed item pins survive both
macro-translation cache lanes, and item changes clear stale tint/charge state.
Wisp and buff countdown behavior remains. Recovery fixture now exercises real
item restrictions, with a control rejecting cold-effect false darkening.
User pictures identify focus icons/captions shifted inward/up versus target.
Compact focus content now uses target-derived body-relative origins converted
into panel coordinates, in both Lua and native aura rendering. Exact accepted
panel widths, icon/font sizes and row fitting remain. Creation/re-enable and
relayout share their anchor helper; caption x/y anchors cache unchanged values.
Initial five paired runs reject both old paths and pass75 consumable/939 focus
checks; five final integration runs pass75/1011, retaining newer focus-target
width/full-row packing and cached native placement. Changed-scale anchors also
pass without redundant writes. Full validation:234/234 scripts PASS;898 Lua
syntax checks/0 failures; normalized source manifest and owned hashes match.
1475 consumable smoke,10 trinket,14 conjured and36 timer-policy checks PASS.
No new runtime frame/texture/event/hook/timer/ticker/OnUpdate. User focus/target
images and current verified history/source checkpoint retained externally;121
settings metadata entries read-only. Native pixels/consumable symptom/taint/
combat/FPS acceptance remains NOT RUN. [Evidence](validation/consumable-tint-focus-aura-2026-11-07.json).

7 November exact focus aura width (FOCUS-AURA-EXACT-WIDTH-20261107; REQ-RF-81):
user clarifies remaining mismatch is aura-panel length. Compact focus no longer
adds13 units per half or a -10 buff offset: the pair spans exactly the focus outer
frame, with/without portrait. Its faint battlefield border follows focus body
scale and the same2-unit/corner offsets as FluxBorder; Classic fallback corners
use matching crops/sizes. Icons/timers/captions keep their existing panel scale;
only border geometry follows body scale. Legacy target/focus aura geometry and
focus screen anchor/vertical target remain. Border-scale/corner writes cache;
no new runtime frames/textures/events/hooks/timers/tickers.577 actual geometry/
border checks,975 party-focus,47 anchor/scale and36 timer-policy checks PASS.
Checkpoint source rejects exact width. 233/233 scripts PASS; 897 syntax files/0 failures; owned hashes match.
Native pixel alignment/combat/taint/FPS NOT RUN; user acceptance pending. External
source/history checkpoint and 45 read-only settings metadata entries verified.
No foreground control, game/WTF/profiler write, manual sync, branch or push.
[Evidence](validation/focus-aura-exact-width-2026-11-07.json).

7 November focus anchor/aura scale correction (FOCUS-ANCHOR-AURA-SCALE-20261107; REQ-RF-80):
user rejects the previous focus position above party/raid and aura-panel layout.
The previous unchanged-anchor-code assertion was insufficient: the new compact
body scale changed its screen result. Raid coordinates now convert UIParent to
focus-local units, preserving the original helper/gap; this branch does not
require chat construction. External buff/debuff panels convert public body
metrics to their own inverse-scaled coordinate space before sizing. Their width
tracks half the visible focus plus original transparent border padding; original
icon sizes/spacing/timers/filters and above-header anchors remain. For260x85 at
body scale.4, each panel is82 units rather than185.5. Original transparent16-unit
border nesting remains. Aura artwork sits above status icons and below casts.

47 scale/anchor,265 actual aura geometry,975 party/focus,36 timer-policy and310
binding checks PASS; old source rejects both physical-anchor and panel-width
regressions. 233/233 scripts PASS; 897 syntax files/0 failures; owned final manifest identities match.
Native screen pixels/position/combat/taint/FPS NOT RUN; the earlier user-visible
regression is recorded as rejected, not accepted by prior mock results.
No new runtime frames/textures/events/hooks/timers/tickers; one panel-scale cache
and constant layout arithmetic. External history/source checkpoint verified and 45
settings metadata entries read-only; prior complete private recovery retained.
No foreground control, game/WTF/profiler write, manual sync, branch or push.
[Evidence](validation/focus-anchor-aura-fix-2026-11-07.json).

7 November focus party presentation (FOCUS-PARTY-PRESENTATION-20261107; REQ-RF-78/79):
PvP artwork is another35% larger on a scaled noninteractive host, still behind
level text; native/private atlas rendering and timer-below-level policy retained.
Focus now reuses normal-party portrait-left/body fonts, text/status layers,
textured HP/resource separator and raised cast header. Its target is the narrow
vertical HP-only bar on the right, as selected by the user. It keeps the focus
unit/capability/secure visibility and binding paths; it never becomes a party
slot or uses party in-frame aura filtering. Existing external buff/debuff panels
stay above, with their screen-size settings preserved. Focus sizing uses the
normal-party baseline plus independent saved focus proportions/whole scale;
no saved size is reset. The previous focus positioning function is byte-identical
(after line-ending normalization), including chat and placement2 behavior.

970 party/focus and319 badge checks PASS across five source models;28 scale,
80 public geometry,310 binding and78 restricted contracts PASS. 232/232 scripts PASS; 896 syntax files/0 failures.
Owned final manifest drift: []. Focus target partition changes defer through
the existing protected queue in combat; live secure behavior/taint remains pending.
Native pixels/position/aura sizes/portraits/target/CPU/FPS NOT RUN. One generic
badge host per outer frame is reused by normal party; focus adds four text/status
hosts and existing indicator helpers/events/hooks, with no new timer/ticker/global
hook. Exact sources and fresh external history/source checkpoint retained;45
settings metadata entries read-only. No foreground control, game/WTF/profiler
write, manual sync, branch or push. [Evidence](validation/focus-party-presentation-2026-11-07.json).

7 November shared unit-frame PvP correction (UNIT-NATIVE-PVP-BADGE-20261107; REQ-RF-77):
user reports no visible unit-frame change after RF76. Root cause: RF76 only
handled normal party; player/target/focus retained the small status-chain icon.
Their shared outer-frame factory/paint now uses the same full native badge as
party: faction/FFA native atlas size (Classic64x64), prestige50x52/background
and30x30 badge. Badge sits behind level; timer sits below level. Only the player
keeps its real existing countdown; others stay empty as explicitly requested.
Native UnitFrameUtil handles private flag/prestige state; player-only mercenary
check matches native PlayerFrame. Status packing and secondary-name fitting no
longer query or shrink native badge regions. Normal party keeps its existing
layer and now reuses the shared prestige textures. Other roles/layout unchanged.

299 indicator/905 party/78 restricted/206 identity checks PASS. Checkpoint source
rejects the new indicator regression. 232/232 scripts PASS; 896 syntax files/0 failures; final owned
hashes match the suite manifest. Actual badge pixels, flag changes, combat/taint
and CPU/FPS remain pending: user has not accepted this correction in-game.
Two prestige textures per shared outer frame; no extra party prestige pair, new
event/timer/ticker/hook or paint driver. External source/history checkpoint and
45 settings metadata entries verified; prior complete recovery retained.
No foreground control, game/WTF/profiler writes, manual sync, branch or push.
[Evidence](validation/unit-native-pvp-badge-2026-11-07.json).

7 November native party PvP badge (PARTY-NATIVE-PVP-BADGE-20261107; REQ-RF-76):
latest user placement is full client player-frame badge behind level, with timer
slot below level. Badge sits on noninteractive owner+20 layer below level+80 and
auras+90. Modern client UnitFrameUtil.UpdateUnitPvPIndicator owns faction/FFA/
prestige selection and secret-safe texture visibility. Native player XML supplies
prestige50x52/background and30x30 badge; faction atlas uses native size. Classic
uses full64x64 native player UI-PVP faction/FFA texture. No small square packing.
Shared packing/name-budget avoids party icon visibility/width reads, since native
delegates can set private state. Other party role/status icons remain.

Blizzard GetPVPTimer has no unit parameter and native code uses it for player.
User explicitly chose Leave it empty for unsupported member countdowns. Existing
party timer text anchors below level but stays hidden: no guessed timer, copied
player timer, status substitute or new polling. Own player timer is unchanged.
Layout-only calls do not repeat native badge data rendering.

905 party/59 indicator/78 restricted/206 identity checks PASS across existing
five-client models, including legacy faction/FFA/full sizing, restricted fallback,
native delegate routing, prestige dimensions and no foreign GetPVPTimer reads.
232/232 scripts PASS; 896 syntax files/0 failures. New resources: one badge layer/two textures per member; reused icon/
timer; no new event/ticker/timer/global hook. Native badge pixels, secret delegate
execution/combat/taint/FPS pending; no performance claim. Exact source XML/API
blobs and recovery identities retained. No game input, WTF/profiler write, manual
sync, branch or push. [Evidence](validation/party-native-pvp-badge-2026-11-07.json).

<!-- AUDIT-R2-20261107 -->
7 November second addon audit (AUDIT-R2-20261107): documentation/proposals only; no audit-issued runtime, existing-test, TOC, art, settings or profiler edits. Fresh main/source snapshot, four Gethe pins and current232-script/896-Lua pass retained.929 classified sources/599 loaded paths screened. 25 qualified groups:15 active-source behavior/contract reproductions,4 conditional models,2 API edges with ordinary reach unproved,3 work candidates and1 dormant helper. Prioritize punctuation pool-name collisions, cancelled gear work, and the conditional visible-salvage combat path; preserve all features and saved data. Explicit rapid Shift/Ctrl/Alt work includes over10million core state edges per run plus separate actual Binding/EBS/badge consumer matrices. Core bus settles in isolated storms; mixed mouseover can starve full display context; stale press ownership and actual combat index work remain recorded. Large fallback setter counts are an unsupported-paging countermodel, not ordinary repaired Forever. Independent Party/PvP source and fixture edits were preserved and revalidated by the current232/896 suite plus affected probe; initial snapshots remain. New fixes remain OPEN. Native taint/input/pixels/instances/CPU/FPS are not accepted by desktop results; previous USER-001 attribution/recurrence is still unknown. [Audit and roadmap](../Stress%20test%20doc/round-2/README.md).
<!-- /AUDIT-R2-20261107 -->

7 November clock calendar correction (MINIMAP-CLOCK-CALENDAR-20261107): user
clarifies calendar belongs on left-click of the displayed minimap time. Remove
the separate calendar icon, restore GameTimeFrame cleanup, and use runtime
ToggleCalendar availability for the existing clock click/tooltip. Right-click
TimeManager/stopwatch and native mail artwork remain. No new driver or resources.
720 focused checks PASS; prior source rejects. Full 232 scripts / 896 Lua syntax
PASS; post-suite hashes unchanged. Validation is recorded in
[the evidence](validation/minimap-clock-calendar-2026-11-07.json). Direct UI choice
and UIForever preference retained; simulator/native input/visuals/taint/FPS NOT RUN.
Fresh external source/history checkpoint verified;16 settings metadata entries
inspected read-only. No game input, settings write, commit/push or manual sync.

7 November author correction: user explicitly approved the prepared one-time
exception to the no-force-push rule. Main was updated with an exact expected-head
lease from d3db4c5 to e0bcdc2. One old author/committer identity was corrected;
30 commit IDs changed, with every tree, message and timestamp preserved. The
published-history recovery bundle remains verified outside AddOns. GitHub's
author query returns zero old-identity commits; its contributor list was still
cached at capture. Check after the documented refresh period (about24hours),
then contact GitHub Support if it remains incorrect. Future publications keep
DoctorFlux author/committer metadata and the standing no-force-push rule.
Runtime files remain at the passing232-script/896-Lua identities; no native
input, settings or profiler change occurred.
[Correction evidence](validation/attribution-correction-2026-11-07.json).

7 November native minimap indicators (MINIMAP-NATIVE-20261107): user chose direct
implementation and UIForever testing. Reuse Forever's native 32x24 cluster mail
frame/art before the retained fallback; retire late-superseded fallback listeners.
Keep native GameTimeFrame at minimap top-left when ToggleCalendar exists, retaining
size/art, scripts, alerts and disable state. Clock-only clients retain cleanup.
Calendar resumes its native OnUpdate; no new addon driver/event/timer/ticker.
717 focused checks PASS; pre-edit source rejects. Full 232 scripts / 896 Lua syntax
PASS; post-suite Lua hashes unchanged. All five installed owner copies match via
the existing mirror. Gethe Forever 1.60.1.70862, pin 9dc84f0d3bbae1768ac3405b3716000bd93eda06.
External dated source/history checkpoint verified; 16 on-disk settings metadata
entries inspected read-only. UIForever NOT RUN: browser automation unavailable;
clean import ZIP and steps prepared. Native visuals/input/mail/invites/combat/taint
and CPU/FPS pending. No game input/settings write, commit, push or manual sync.
[Evidence](validation/minimap-native-indicators-2026-11-07.json).

7 November publication batch: current local addon updates and audit/test records
were uploaded to main in 7d35d33 with a normal fast-forward push. The newer minimap
records are included in the following documentation commit. Fresh validation passes all
232 scripts and 896 Lua syntax files with unchanged Lua hashes. External recovery
checkpoint GitHub-publication-20261107T135245Z preserves 2,039 actual source files,
179 on-disk settings and all-ref Git history; archives are outside AddOns.
Publication author/committer is DoctorFlux, with no automated co-author trailers.
An older author attribution needs a published-history correction; the standing
no-force-push rule remains until the user explicitly approves that exception.
Native combat/taint, visual and performance checks retain their recorded pending
status. This publication changes no runtime behavior or game/profiler settings.
[Fresh validation](validation/github-publication-2026-11-07.json).

<!-- STRESS-FIXES-20261107 -->
7 November stress fixes (STRESS-FIXES-20261107): the user authorized implementation after the audit/proposal phase. Applied public fade ownership, secret-safe alpha/geometry handling, local Forever driver adapters, accurate/cancellable Respec completion, input invalidation, mutation-safe event delivery, retained FIFO scheduler work, bounded combat drains, raid/nameplate work reduction, hidden-watch suspension, bounded range freshness and auction retry churn. Settings, saved roots, commands, artwork and foreign library ownership are preserved. Combined desktop validation: 232/232 scripts and 896 Lua syntax files PASS; post-suite Lua hashes match. No game input, WTF/profiler writes, commit, push or manual cross-install copy was performed. USER-001 actual failing frame/first taint source, native taint, pixels and CPU/FPS remain pending. Visible character-button polling and coherent auction publication after quiet are intentional safety limits, not claimed eliminated costs. [Applied changes and evidence](../Stress%20test%20doc/applied-fixes/README.md).
<!-- /STRESS-FIXES-20261107 -->

7 November modifier key routing (UTL-CHORD-13): user confirms no-mod works
but modifiers fail. Ordinary utility key overrides now carry their triggering
chord as a distinct virtual button. Wildcard-modifier native payloads and
release types preserve that selection independently of live modifier queries
during dispatch. Click wrappers retain the virtual button and CVar edge;
cached nonwrap keyers inherit its fields. Mouseover uses the same encoded
prefix and retains its native modifier gate. Physical mouse attributes stay
prepared for each chord. Bindings now install after action preparation in
the real slot-update lifecycle; clearing removes all encoded actions.
A masked-dispatch fixture reproduces the prior normal-action fallback;
the engine masking mechanism itself is unobserved. Five baselines fail and
five candidates pass41255 checks; four mutations rejected.12634 face/count/CD,
1473 VFX and4973 mouseover checks PASS; existing320-transition paint budget
unchanged. No new frame/event/timer/ticker/poll. Actual new modifier input/
mouseover/combat/taint/pixels/FPS acceptance remains NOT RUN.
Full run:894 syntax PASS; 229/230 scripts PASS. The sole failure is the
unrelated portrait_camera.lua fixture missing GetFramePublicDimensions;
concurrent portrait work is preserved. Utility source owners/tests remain
at their recorded hashes; all five installed copies match via the existing
mirror. Native modifier acceptance is still pending.
[Evidence](validation/utility-chord-routing-2026-11-07.json).

7 November party auras over portrait indicators (PARTY-AURA-PORTRAIT-LAYER-20261107; REQ-RF-75):
normal party aura host was owner+60 below portrait indicators+80. It now uses+90
in the shared live/preview factory, above portrait icons and below cast header+110.
Native and readable rows, cooldowns and duration text inherit that host. Existing
positions/sizing, filters/limits, strict dispels, timer policy and opacity remain.
This changes draw order only; no new frame/event/hook/timer/ticker/recurring work.

865 party checks include live ordering above indicators/below casts and matching
preview ordering on five source models;12776 aura-renderer checks PASS. 228/229 scripts PASS; 893 syntax files/0 failures.
Native overlap/opacity, combat/taint/FPS checks pending per client; no native
performance claim or benchmark for this low-impact change. External dated
source/history/settings retained; no game input/WTF/profiler write, manual sync,
branch or push. [Evidence](validation/party-aura-portrait-layer-2026-11-07.json).
Later unrelated corpus drift: Respec/FluxRespec_Consumables.lua, Respec/FluxRespec_PresetBundle.lua, tests/hover_children_varargs.lua, tests/prediction_public_geometry.lua, UnitFrames/FluxUnitFrames_Shared.lua.

7 November utility execution rework (UTL-EXEC-11; UTL-MO-12): user rejects the
ranked-spell attempt as still nonfunctional. Ordinary spell/item utilities now
prepare native secure action attributes for every exact modifier chord before
combat, removing macro-text/delegate execution. Saved IDs directly drive
icon/count/cooldown/VFX; rank names are used only as native spell cast tokens.
Both keys, base/preferred fallback, combat release, clearing and cursor drops
are covered; special macro/pet/mount/toy/outfit assignments retain their route.
Mouseover follows the existing setting/modifier through shared click-time
target wrappers, using the selected action help/harm gate and clearing unit
afterward. Range follows the same reaction during existing hover cadence.
Forever target wrappers require the existing repaired-VM probe; failed probe
or partial installation retains normal native targeting and is not a
mouseover pass. Existing combat setting deferral remains. No new event,
timer, ticker, OnUpdate or hover driver; existing320-transition paint budget
is unchanged.26962 input,10234 face/count/CD,1033 VFX and4973 mouseover checks
PASS; five old-contract rejections/five candidates and three mutations.
Full222 scripts/885 syntax PASS; tested Lua corpus unchanged; all five installed
client copies match the six runtime owners through the existing mirror.
Actual native casts, mouseover probe, combat/taint/visual/FPS remain NOT RUN.
[Evidence](validation/utility-native-actions-2026-11-07.json).

7 November utility ranked spells (UTL-RANK-10): user reports Arcane Intellect
and other utility spells fail. Read-only saved assignments include Arcane
Intellect(Rank 2). Native CAST prechecks the full ranked string; USE sends a
nonitem string directly to the protected cast function. Ranked/subtext utility
spells now use USE, retaining their exact rank; bare spells retain CAST priority
over same-name items. Mixed ranked/bare slots keep a single stable hidden macro
with mutually exclusive exact-chord lines. Item modifiers, both keys, release
and special assignments remain. No new events/timers/frames/polling or combat
action writes. Five baseline rejections and five candidate15491-check passes
exercise a ranked-lookup miss through five dated native dispatcher/handler
sources. This is a desktop failure model, not confirmation of the native root
cause or spell cast success. Full222 scripts/885 syntax PASS; corpus unchanged;
all five manager copies match. Existing6894 modifier/488 VFX checks PASS.
Native reload/target/mouseover/input/combat/taint/
visual/FPS acceptance is pending. [Evidence](validation/utility-ranked-spells-2026-11-07.json).

7 November utility item cooldown correction (UTL-CD-09): utility slots no longer
claim consumable buff durations as cooldowns. Clear already latched aura fields
before cooldown dispatch, including combat modifier release back to a spell.
The dedicated consumables button keeps its supplied aura countdown; existing
nonutility potion and food/water policy remains. No new timers, events, frames,
polling or protected action writes. Five paired desktop runs reproduce 30
baseline failures and pass 6894 candidate checks each; utility aura lookups
drop from five to zero per run. Full validation: 222 scripts and 885 Lua syntax
files PASS; post-run corpus unchanged. Native cooldown/input/combat/taint/visual/FPS
acceptance remains pending. [Evidence](validation/utility-item-cooldown-2026-11-07.json).

7 November utility conditional macro key fix (UTL-MACRO-08): user reports
Shift item keypress still attempts the normal spell; prior input acceptance is
REJECTED for that native report. Ordinary spell/item slots now execute one
compact conditional macro command with explicit item:ID tokens; native /cast
handles both. The same body supplies display identity. Modifier-specific action
attributes no longer choose the execution branch for these slots. Named macro/
pet/outfit paths retain their prior route. Nonwrap keys now use one cached
AnyDown proxy per bound utility (max4), inheriting prepared host attributes;
visible mouse timing and wrap-client CVar policy remain. This fixes the tested
AnyUp release-order gap: Shift item executes on key-down before Shift is released,
and key-up cannot then run the normal spell. No modifier-time secure rewrites
or new event/timer/ticker/poll. Both keys and explicit modifier chords remain.
Read-only saved slot1 Study/Shift-water and native U binding verified. Actual
five-client SecureTemplates plus CAST/USE handlers replay 11114 checks; saved
setup, cold item no-fallback and early Shift-release cases pass. Five old-source
contract rejections/five candidate passes; isolated pre-proxy timing rejection;
three mutations rejected.6609 count/modifier and488 VFX checks pass; prior
count-paint budgets retained. Full222 scripts/885 syntax PASS; tested
corpus unchanged; all5 manager copies match through existing mirror. No game input,
WTF/profiler writes or settings reset. Native reload/input/combat/taint/FPS
acceptance remains pending; no connected Witchcraft/native input tool.
[Evidence](validation/utility-conditional-macro-key-2026-11-07.json).

7 November target-style party separator (PARTY-TARGET-SEPARATOR-20261107; REQ-RF-74):
user screenshot rejects the flat party line; user selects the bottom-right target
as reference. Party now calls the exact target/player CreateSeparator factory via
UF.CreateBarSeparator: same battlefieldminimap-border-top atlas, or same legacy
texture/crop, and17 logical height including transparent artwork padding. Tint
uses SetVertexColor so recoloring cannot replace artwork with a solid fill. The
underlying shared health/power separator hides when the owned party divider exists
to avoid a doubled/shiny edge. Resource-top seam and existing bar-height controls
remain. Reference screenshot retained externally with hash; new native comparison
is pending. This supersedes RF73's solid four-unit divider appearance.

144 checks compare the actual party construction with the target constructor
across atlas/fallback, HUD/legacy and multiple heights/resource scales; verify
seam coordinates, no bar resizing and no duplicate separator. Five alternating
checkpoint/candidate pairs reject the former flat artwork and pass current code.
840 party checks PASS. 222/222 scripts PASS; 885 syntax files/0 failures. No new frame/event/hook/timer/ticker/driver;
no native CPU/FPS claim. Native pixels/combat/taint pending per client. External
source/history/settings retained; no game input/WTF/profiler write, manual sync,
branch or push. [Evidence](validation/party-target-separator-2026-11-07.json).
Later unrelated corpus drift: ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua.

7 November party divider thickness/tint (PARTY-DIVIDER-STYLE-20261107; REQ-RF-73):
user confirms RF72 divider is visible and requests it slightly thicker with the
same color as the other borders. Height increases3 to4; resource-top anchors,
bar/frame dimensions and opacity stay. Divider and outer borders now use the
same appearance accent or party member class override through Party.PaintChrome.
Existing global appearance refresh repaints live and preview party chrome, so
changing accent/class choices cannot leave the divider at its old hardcoded tint.
No new frame/event/hook/timer/ticker/recurring driver; bounded appearance repaint.

Existing54 real-partition/840 party/59 indicator checks PASS; expectations updated
for height4. 222/222 scripts PASS; 885 syntax files/0 failures. This small visual change adds no new tests/benchmark
that mirror its implementation; no native performance claim. User acceptance is
prior divider presence only; new thickness/tint native visual/combat/taint/FPS
checks remain pending. External source/history/settings retained; no game input,
WTF/profiler write, manual sync, branch or push.
[Evidence](validation/party-divider-style-2026-11-07.json).

7 November utility modifier VFX (UTL-VFX-07): utility face changes now
settle cast/channel/empower/reticle/finish/interrupt through the existing Cast
and Overlay owners. A departed face clears its paint and player owner-bag
membership; returning matching faces resume via existing progress/window
helpers. Context refreshes with unchanged identity skip this work. Macro item
faces resolve their use-spell proc without comparing item art to spell art;
cleared utility slots drop stale proc/cast effects. Existing strip/pet ownership
and pre-DF VFX preference remain. No new event/frame/timer/ticker/poll or secure
action writes; hold/release and prior count work budgets stay unchanged.
578 focused VFX checks across five models,7329 modifier/count checks and11015
native-source input checks PASS; five baseline rejects/five candidate passes;
four mutations rejected. Full222 scripts/885 syntax PASS; tested
corpus unchanged; all15 installed runtime copies match via existing mirror. Native pixels/input/
combat/taint/FPS remain pending; actual drawing and unit data are modeled.
External source/history/settings metadata verified; no game/WTF/profiler/input
control or manual client sync.
[Evidence](validation/utility-modifier-vfx-2026-11-07.json).

7 November party HP/resource divider edge (PARTY-DIVIDER-EDGE-20261107; REQ-RF-72):
user reports divider absent; prior RF67 desktop checks did not validate the HUD seam.
HUD health fills extend behind resource; its bottom is not the seam. The existing
party divider now anchors to Power top with+1 offset, matching the shared two-unit
gap midpoint. Height3, bronze color, opacity, raised layer, bar dimensions, frame
size and existing range/visibility ownership remain unchanged. No new resource
owner/event/hook/timer/ticker or refresh loop; native anchors track resource.

54 checks execute the real shared partition function and production divider
creation across HUD/legacy,35/85/150 height and0.5/0.8/1.5 resource scale. They
resolve divider coordinates against the actual shared separator, and assert no
bar resize. Five alternating checkpoint/candidate runs reject the old HUD edge
and pass current code;840 party checks PASS. 221/221 scripts PASS; 884 syntax files/0 failures. Native seam pixels,
combat/taint/FPS pending per client; no native performance claim. External dated
source/history/settings retained; no game input, WTF/profiler write, manual sync,
branch or push. [Evidence](validation/party-divider-edge-2026-11-07.json).
Later unrelated corpus drift: tests/bank_restock_icon.lua.

7 November default Blizzard bank direct UI lifecycle (BANK-NATIVE-06): user
renews the no-Baganator close/layering fix. Source audit proves a missed path:
restock inventory fireCloseIfGone suppresses its private close callback while
Bank.IsOpen stays true. Earlier tests always delivered that callback. The bank
button now uses BANKFRAME_OPENED/CLOSED directly through the existing shared
Flux.Events dispatcher for native UI, independent of that inventory latch. A raw
close hides immediately, invalidates delayed attaches and blocks manual/stale
inventory-open resurrection until the next real open. Private callbacks remain
for Baganator and as fallback if direct registration is unavailable. Two native
subscriptions, no new frame/timer/ticker/polling or native-script hook.
Native layering now uses at least HIGH and the highest parent/search/panel/close/
NineSlice strata; level clears those children as well as the root. Native parent
and left-of-search position remain. GetControl exposes the actual owned widget
for diagnostics; no command/settings change. Baganator footer remains intact.
Full221 scripts/884 Lua syntax PASS; final bank1780 checks rechecked after a
baseline-fixture refinement. Later unrelated Cast/EBS source drift recorded; no current whole-addon PASS
claimed. Bank runtime owner remains at its tested hash.
All5 installed bank owner hashes match via existing mirror; no manual sync.
Two production mutations (missed close and low strata) rejected.
1780 production checks across five clients/both owners/cold-warm merchant/direct-
events-fallback modes PASS. Includes suppressed inventory close, stale shown
flags, stale open callbacks, HIGH/DIALOG children and reopen. Native ownership168,
visible Baganator260 and combined33 per Era/Anniversary PASS. Prior checkpoint
rejects. Fresh Gethe Forever9dc84f0d3bbae1768ac3405b3716000bd93eda06 (1.60.1.70862)
verifies close function/events/search owner. Native visuals/open-close/purchase/
combat/taint/FPS remain pending; actual hovered-frame evidence still unavailable.
Fresh external source/history/45 on-disk settings metadata verified. No game,
foreground, WTF/profiler or manual-sync operation.
[Evidence](validation/bank-direct-lifecycle-2026-11-07.json).

7 November native bank owner investigation (BANK-NATIVE-05): user confirms
Forever after /reload still shows the control behind/detached from the window
and not disappearing on close. BANK-NATIVE-04 native acceptance is REJECTED;
its desktop checks do not establish actual-client behavior. No further runtime
layout change made yet. Read-only host enumeration confirms two running
_forever_/Wow.exe clients; installed bank source matches current workspace hash.
Available saved BugTabs has no bank/restock error entry, but is not live state.
The current source already parents its native control to BankFrame, making the
actual hovered frame/owner identity necessary before another speculative fix.
User requested to type /fstack, hover the visible restock control and provide
frame names, then disable /fstack. Await this evidence. No connected Witchcraft,
UIForever or computer-use tool exists; no foreground/mouse/keyboard/clipboard
control, game input or WTF/profiler writes. Fresh source/history checkpoint and
45 settings metadata entries verified outside AddOns. Native placement/layering/
hide/taint remain unresolved; preserve the Baganator footer and newer party work.

7 November party cast name/level coverage (PARTY-CAST-COVER-20261107; REQ-RF-71):
latest user correction keeps player-style cast art/icon but requires it over the
party name and level. This supersedes RF68's unmodified cast placement. Shared
cast dimensions/lifecycle remain; shell now anchors across the prepared party
header at owner+110, above name+70 and metadata+80. Name/level alpha conceals
underlying glyphs during casts/holds and restores previous public alpha on hide
or disable. Metadata repaint cannot raise the level over the cast. Show/Hide
callbacks change text alpha only; existing OOC layout prepares geometry.

Party / Raid > Party frames > Show party cast bars retains partyShowCastBar and
combat deferral. Disabling hides an active cast immediately outside combat;
enabling refreshes the current cast through existing CB.RefreshCastForUnit.
840 party/310 binding/379 timer/2730 marker checks PASS; five fresh alternating
baseline/candidate harnesses reject the prior lower/unplaced cast shell and pass
current code. 220/220 scripts PASS; 883 syntax files/0 failures. Markers remain fixed by RF70. No new frame/event/
ticker/timer/secure condition; four layout wrappers and Show/Hide coverage hooks.
Native pixels/toggle/combat/taint/FPS pending per client; no performance claim.
External source/history/settings retained; no game input/WTF/profiler write,
manual sync, branch or push. [Evidence](validation/party-cast-cover-2026-11-07.json).

7 November native bank attachment (BANK-NATIVE-04): user reports the no-Baganator
button below the window and detached during opening/closing. Forever's control
was deliberately a UIParent sibling; it now uses the native BankFrame parent and
existing inside left-of-search anchor, inheriting visibility, movement and scale.
This supersedes the earlier UIParent parent restriction for this owned control.
Native scripts, purchases, mover and item decoration exclusions remain. Visible
ancestor checks hide stale/unattached controls on all clients. Existing two open
retries keep their cadence but use a close/reopen generation token, so stale
callbacks cannot resurrect a closed control. No new frame/event/hook/timer/ticker.
Baganator's full-size inside footer and existing settings/commands are retained.
Full runner:219 scripts PASS,1 unrelated raid_party_frames cast-layout failure;
883 syntax/0 failures. No current whole-addon PASS claimed. Final bank828 checks
rechecked after the hidden-ancestor test extension. All5 installed runtime hashes
match through existing mirror; no manual client copy.
828 production checks across5 clients/both owners/cold+warm merchants PASS,
including parent hide/show without callbacks, close/reopen retries, explicit
hidden-bank attachment and a shown frame under a hidden owner. Prior checkpoint
rejects; current code passes. Native ownership168/visibleBaganator260/combined33
per Era/Anniversary PASS. Fresh dated source/history/45 settings metadata entries
verified externally; no game/WTF/profiler/manual-sync operation. Existing pinned
Gethe9dc84f0d3bbae1768ac3405b3716000bd93eda06 source retains search/template evidence.
Native candidate placement/open-close/purchase/combat/taint/FPS remain pending;
no connected native tool.
[Evidence](validation/bank-native-attachment-2026-11-07.json).

7 November raid-target marker rendering (RAID-MARKER-RENDER-20261107; REQ-RF-70):
raid/normal-party icons hid every secret GetRaidTargetIndex return. Raid textures
also lacked a base sprite sheet: native SetRaidTargetIconTexture sets coordinates,
not the image. Both are fixed. Retail/Forever opaque indices pass directly to
the AllowedWhenTainted native SetSpriteSheetCell sink; no private comparison or
UV arithmetic. Readable markers retain legacy fallback. Sheet is explicitly set;
nil/invalid/removal hides stale icons. Ordinary player/target/focus marker state
uses the same guarded approach instead of index truth tests. Existing player/party
HP-centered geometry, settings, textures and events stay; no new frame/driver.

2730 checks exercise all eight markers, replacement/removal, readable/restricted
indices, six unit tokens, native and legacy paths across five client models.
Five alternating checkpoint/candidate pairs reject the prior missing-sheet path
and pass current code. Existing428 raid runtime/810 party/59 indicator checks PASS.
220/220 scripts PASS; 883 syntax files/0 failures. No native pixels/combat/taint/FPS certification. External dated
source/history/settings retained; no game input/WTF/profiler write, manual sync,
branch or push. [Evidence](validation/raid-marker-render-2026-11-07.json).
Later unrelated source drift: Inventory/Restock/Bank/FluxBankRestockButton.lua, tests/bank_restock_icon.lua.

7 November Baganator full-size inside action row (BANK-ICON-03): user rejects
the22px toolbar button and explicitly requires a location inside the window.
Existing restock control is now36x36 at scale1 in an owned48px bottom row, with
Bank Restock label and full-size auto checkbox. Native tab, currency/reagent/
purchase controls and item layout sit above that row. Existing completed-layout
wrapper releases owned geometry before native sizing; repeated attachment never
accumulates height. Tall windows reuse/shorten their existing scroll viewport;
owned heights restore on hide, locked tab or native/combined handoff. No native
bank placement changes; Forever remains left of search. No settings migration,
new frame/event/hook/timer/ticker; one lazy FontString and transient footer state.
Full220 scripts/883 Lua syntax PASS; current Lua corpus unchanged.
All10 runtime owners across5 installed copies match via existing mirror.
668 production checks cover five clients, both bag owners, cold/warm merchant,
full-size geometry, viewport bounds, exact native completion ordering, repeated
refresh, lock and handoff. Ownership168/visibleBaganator260/combined33 per Era
and Anniversary PASS. Native candidate visuals/input/taint/FPS remain pending;
user reproduction route retained. Baganator843 interfaces inspected read-only;
rights retained, no implementation/art copied. Dated external source/history and
45 on-disk settings metadata verified. No game input/WTF/profiler/manual sync.
[Evidence](validation/bank-restock-footer-2026-11-07.json).

7 November cast timer synchronization (CAST-TIMER-SYNC-20261107; REQ-RF-69):
party/focus/target text could prefer stale cached value/maxValue while the fill
used its StatusBar or engine DurationObject. Restricted duration also selected
a guessed wall clock for text. Shared countdown now reads the bound engine
remaining duration, or actual bar current/max values for readable/manual casts
and channels. This follows all five native CastingBarMixin timer formulas.
Opaque engine remaining duration forwards unchanged to the native formatted-text
sink; font widths are secret-guarded. Unavailable timing clears stale text rather
than estimating. Cast fill, geometry, lifecycle, options and0.05s paint cadence
stay unchanged; no new frame/event/hook/ticker/timer. Player and pet share the fix.

379 focused checks cover five source families, party1/party4/target/focus/player,
casts/channels/delays/replacement, stale caches, engine duration, restricted text
and font geometry. Full production start/update/delay events replay on each
family, including Retail/Forever engine-owned opaque countdowns. Five alternating
checkpoint/candidate pairs reject old code and pass current; three timer mutants
rejected.13942 existing cast theme checks PASS. 219/219 scripts PASS; 882 syntax files/0 failures.
Native rendering/secret sink/combat/taint/FPS remain pending per client; desktop
models do not certify them. Dated external source/history/settings recovery
retained. No game input, settings/profiler write, manual sync, branch or push.
[Evidence](validation/cast-timer-sync-2026-11-07.json).

7 November bank restock slot follow-up (BANK-ICON-02): user rejects the first
icon-only fix and the Forever outside-window placement. Baganator843's toolbar
uses32x22 buttons; resizing only the hit rectangle left fixed64px merchant slot
art at its36px design size. The whole36px control now scales uniformly to the
shorter toolbar edge, including icon, frame, highlight/push and auto toggle.
Native/combined handoff resets scale1. Transfer/Sort/Customise references work.
Forever remains an addon-owned UIParent child but is visually inside BankFrame,
RIGHT of button to LEFT of BankItemSearchBox,4px gap, vertically centered; this
supersedes the previous external TOPRIGHT placement. Native bank hierarchy,
scripts/purchase/movement/decorations stay untouched. Fresh Gethe Forever source
9dc84f0d3bbae1768ac3405b3716000bd93eda06 (1.60.1.70862) verifies Mainline template
and Camelot loading/search owner. Baganator read-only reference retains rights.
Full219 scripts/882 syntax PASS; no current Lua corpus drift.
All five installed bank runtime hashes match via existing mirror; no manual sync.
358 production geometry/lifecycle checks PASS across5 clients/both bag owners/
cold+warm merchant; prior checkpoint rejects. Native ownership168 and combined33
per Era/Anniversary PASS. Native candidate pixels/input/taint/FPS remain pending;
user screenshot reproductions retained; no connected client tool or game input.
External fresh source/history verified;45 on-disk settings metadata read-only.
No new frame/event/hook/timer/ticker. Existing bounded retries/click/drop/tooltip/
auto settings retained.
[Evidence](validation/bank-restock-slot-2026-11-07.json).

7 November player-layout parity for normal party (PARTY-PLAYER-LAYOUT-20261107; REQ-RF-68):
user supersedes the prior portrait-corner class/spec/raid marker layout and
header-overlay cast variant. Class/spec now retain the shared player factory's
anchors, size, borders and visibility; no forced class show or party reparenting.
Party casts use the unwrapped player cast layout including spell icon. The party
cast toggle remains. Player and party share UF.LayoutRaidMarker: center of HP,
90 percent of HP/text-anchor height; party retains secret-guarded marker updates.
Leader/assistant/MT/MA/loot move onto portrait so class/spec header slots are free.
Spec data availability follows the existing provider; no fabricated spec.

810 party and78 restricted checks pass; 218/218 scripts pass; 881 syntax files/0 failures.
No new frame/event/timer/ticker/condition. Four cast wrappers and OnShow hooks
removed. Native pixels/casting/combat/taint/FPS pending on each client. External
source/history/settings recovery retained; no game input/WTF/profiler write,
manual sync, branch or push. [Evidence](validation/party-player-layout-2026-11-07.json).

7 November compact normal-party indicators (PARTY-INDICATORS-20261107, REQ-RF-63..67):
restored class icon; class/spec/PVP/role/raid marker have dedicated portrait corners,
leader/assistant/MT/MA/master loot use a compact header grid, and level has its own
readable corner. Casts cover the header above both text and metadata, with the
existing Party member cast bars toggle; shared cast lifecycle retained. Pet text
hosts use symmetric left/right margins so percentage-only labels center on X.
Party reuses raid ready-check/center-status helpers for ready, resurrection,
incoming summon, leader/loot/raid markers, plus native role atlas. Ready finish
hides without a new timer. A dedicated divider restores the HP/resource seam
independently of the HUD fill's alpha. Party raid markers bypass the older shared
marker truth-test and use the existing secret-guarded raid helper.

800 party,78 restricted-contract,310 binding and59 indicator checks pass on the
existing source models. Whole run: 218/218 scripts pass; 881 Lua syntax files, 0 failures. No native visuals/combat/taint/FPS certification.
Four textures/member, no new frame/ticker/timer/secure condition. External dated
source/history/settings retained; no game input, settings/profiler write, manual
sync, branch or push. [Evidence](validation/party-indicators-2026-11-07.json).

7 November bank restock icon (BANK-ICON-01): user supplied Forever screenshot
showing a small icon and requested all clients with/without Baganator. The bank
icon now fills its own button with a one-pixel inset, following native/combined
and Baganator toolbar sizing instead of copied merchant icon dimensions. The
requested no-Baganator Forever route restores an addon-owned UIParent button
beside BankFrame; no native bank child, script, mover or item decoration changes.
This intentionally supersedes only the prior native-restock suppression. Existing
bounded open retries, close cleanup, click/drop/tooltip/auto settings remain.
312 production-module geometry/lifecycle checks cover five clients, both bag
owners and cold/warm merchant icons; prior checkpoint rejects, candidate passes.
Ownership168, combined33 per Era/Anniversary, charge12 and click784 checks pass.
Full run reports218 scripts/881 Lua syntax PASS at its captured snapshot.
Three unrelated raid/party Lua files subsequently drifted; bank runtime/test
owners remain stable, so no whole-addon PASS is claimed for the changing tree.
All five installed bank runtime copies match through the existing mirror;
no manual client copy performed. Source/history checkpoint and 45 on-disk Flux settings metadata entries verified
outside AddOns. No game input, WTF/profiler writes or new recurring driver.
Native candidate pixels/input/taint/FPS remain pending; no connected client tool.
[Evidence](validation/bank-restock-icon-2026-11-07.json).

7 November utility combat release/optimization (UTL-REL-05;UTL-PERF-06):
normal spell/item action, icon and latest count restore on every modifier
release while combat remains active. Partial/full release, counts changed
while held, zero/blank digits and50 repeated cycles are covered. Native input
continues through prepared modifier attributes without visual callbacks or
secure rewrites. Utility display now uses one loop and shared translator paint;
unchanged selected faces and duplicate chord events skip repeated work. Special
pet/outfit cleanup remains; bag/charge updates stay independent. Actual shared
Modifier bus + painter regression passes7329 checks; five-source native input
replay passes11015. Five paired desktop measurements:320 transitions reduce
icon320->120, count640->120, usable660->140, checked640->120; duplicate paints
1120->0. These are scoped callback work counts, not native CPU/FPS measurements.
Prior behavior restored correctly; optimization removes duplicate work. Two
mutations rejected. Full217 scripts/880 syntax PASS at snapshot;
subsequent unrelated native-bank test drift recorded. Utility runtime and all5
installed copies match tested hashes; docs check pending2 bank-test inventory/
verification issues. No whole-current-tree acceptance claimed. Existing events/cadence/
settings unchanged; one transient chord memo; no new recurring driver. Native
input/taint/pixels/FPS remain pending; no game/WTF/profiler/input control.
[Evidence](validation/utility-modifier-release-2026-11-07.json).

7 November utility secure use/cast follow-up (UTL-USE-04): user requires
universal execution as well as the displayed spell/item, including combat.
Exact macro actions now stay on the existing hidden EBS delegate; visible
modifier attributes forward clicks there. The long visual body cannot execute
through an unmapped/right button. Nonwrap clients bind native LeftButton;
wrap clients retain KeyBind. Both assigned keys gain each explicit utility
modifier override, including items, while unassigned bindings stay available.
8135 actual Blizzard-dispatcher desktop checks across5 source trees cover
mouse/two keys/all8 chords/both CVar edges/combat and deferred edits;5 baseline
rejections/5 candidate passes and3 rejected mutations. Prior face/count/pet/
transmog regressions pass. The old bars fixture incorrectly forbade native
LeftButton universally; corrected to follow wrap capability. Full217 scripts/880 Lua syntax PASS; tested corpus unchanged at audit. No new frame/event/timer/ticker owner; existing pool and
bindings owner reused. Actual native secure combat input/taint/pixels/FPS
remain pending: no Witchcraft tool available. No game/WTF/profiler input.
[Evidence](validation/utility-secure-input-2026-11-07.json).

7 November normal-party follow-up (PARTY-NATIVE-FOLLOWUP-20261107,
REQ-RF-51 through REQ-RF-62): fixed native visibility with prepared fixed-token
buttons and Blizzard's built-in state-visibility driver. User confirms player-style
frames appear and preview works. Four fixed rows keep the full stack within the
current raid-column height, with zero gap; the fourth slot retains the old full
party corner. This supersedes the earlier partial-roster last-member relocation.
Pet/target existence changes use native secure drivers; option edits defer.

Party HP/resource text is 15 percent larger with independent name fitting;
pet offset no longer consumes name-header space. Metadata occupies separate
portrait-side slots and a level corner. HP-only 60x28 pets show only percentage;
HP text moves into a top band with a pet and centers without one. Resource height
defaults to 80 percent. Independent values/percent/both/hidden modes default to
HP values and resource percentage. Bigger party auras have their own 1.50 factor;
portrait-side harmful auras preserve strict filters, limits, packed flow and clocks.
HP/resource fills gray for dead/ghost/AFK/offline and recover on status return.
All portrait surfaces inherit alpha; missing 3D models use native SetPortraitTexture
and recover on model loading. Optional player-class HP colors cover own pet target,
party targets and focus target; NPCs retain their normal color. Party class chrome
remains independent of HP. Threat uses only an owned transparent border overlay
with native warning/dead/status rules and GetThreatStatusColor, guarding secrets.

Actual restricted-method regressions cover underscore attributes and inherited
parent handles; $parent fixes invalid relative handles. The secret-alpha portrait
comparison is removed. 760 party, 310 binding, 78 native-contract and 255903 secure
checks pass across five source models, plus existing aura/clock checks. Five fresh
alternating pairs reject the checkpoint alpha branch and pass current code.
Final217 scripts/880 Lua syntax PASS at the tested snapshot. Party runtime
owners remain unchanged; later unrelated utility/runtime-test edits cause global
corpus drift and retain their separate validation. All65 party runtime file
comparisons across five installed copies match through existing sync. No duplicate
copy, new recurring party driver, game input, profiler/WTF write, branch or push.
Dated external source/history and 158 on-disk settings verified. Final visuals,
combat/input/secret/taint/FPS acceptance remains pending separately on each client.
Meter work stays excluded. [Evidence](validation/party-native-followup-2026-11-07.json).

7 November utility spell/item modifier faces (UTL-MIX-01 through UTL-MIX-03):
exact held chords select one action and matching icon/tooltip/cooldown/range,
with the existing preferred-base fallback. Native modifier attributes prepare
outside combat. Utility counts use shared EBS live rules for stacks, item
charges, reagents and spell charges; bag changes repaint during combat without
protected writes. Existing settings/layout/cadence remain; no new recurring
driver. 3269 focused checks, five baseline-rejecting pairs and three rejected
mutations; full215 scripts/878 syntax PASS at the tested snapshot. A later
unrelated UnitFrames/FluxUnitFrames_Party.lua edit causes global corpus drift;
both utility runtime owners remain at their tested hashes. Preserve that work.
Later party-test edits also drift; docs check has5 unrelated party inventory/
view/verification issues and no utility source errors.
All five installed manager copies match through the existing mirror. External
source/history/settings recovery verified; fresh source/history checkpoint and
settings metadata captured. Fresh upstream lookup unavailable; packaged/local
contracts recorded. Native input/pixels/combat/taint/secrets/FPS pending; no
Witchcraft tool available. No game input or WTF/profiler writes.
[Evidence](validation/utility-mixed-faces-2026-11-07.json).

7 November split aura timer policy (UF-AURA-02): user rejected separate
Target/Focus controls, then narrowed the all-frame suggestion to two families.
Unit Frames > General controls normal party + target + focus via the scoped
unitFrames.auraTimersUnderMinute key (default off). Party / Raid independently
controls raid + compact party using its existing key/default. Normal party had
shared raid's formatter; it now binds a separate formatter at native creation
and refresh. Plain clocks and previews choose the same family. At>=60 only text
blanks; icons/swipes/stacks remain. Target/focus native formatter and legacy
sweep also follow General; ms-to-seconds fix retained. Existing combat deferral
and cadence/resources remain; no new event/ticker/timer.36 focused checks plus
1696 raid-option/12776 renderer checks PASS; five paired regressions PASS.
Final 214 scripts/877 syntax PASS; tested corpus unchanged. All nine feature
files match across all five client copies through existing sync; no duplicate
copy performed. Final native visuals/secret/combat/taint/FPS remain pending.
[Evidence](validation/unit-aura-minute-split-2026-11-07.json).

7 November meter menu/tab routes (METER-WINDOW-ROUTES-20261107): fixed the
remaining geometry-only routes in FluxWindow's active Meter-tab cycle and
preset setter. Explicit native tab entry now commits the requested types and
Current; FluxUI options choices switch from Map before committing, so an old
runtime layout cannot be applied instead. Details retains its existing immediate
quiet re-embed path and eleven-preset wrap. No visual/layout/type list change.
If native UI is not ready, one explicit apply intent reuses existing readiness
Embed/retries. The latest working layout wins, it consumes once, and Hide/Cleanup
cancel it. Startup without that explicit intent still does no native type/session
configuration. No new frame/event/hook/timer/ticker; one transient boolean only.
User reloaded and confirmed both routes configure panes and Current automatically
without the setup-pane click. Native acceptance is selected Forever UI/function;
combat/secret/taint/gamepad/other-client/FPS remain pending. Exact source,
paired/focused/full results and source/history/settings recovery are in evidence.
Final focused validation:12 meter/window scripts PASS;404 control checks,
448 per pinned menu replay; five paired baseline rejects/candidate passes and
four rejected mutations. All15 installed runtime hashes match through the
existing mirror. Whole run:876 syntax PASS,212 scripts PASS and1 unrelated
concurrent party-frame fixture failure; global source drift, meter owners stable.
Preserve the unrelated work; no whole-addon PASS is claimed.
Documentation check reports5 unrelated raid/party inventory/verification
issues and no meter-source errors.

No foreground/input control, direct WTF/profiler writes or manual client sync.
[Evidence](validation/meter-window-routes-2026-11-07.json).

7 November Current segment default (METER-LAYOUT-CURRENT-20261107):
explicit FluxUI layout/type/setup choices now default every displayed native
pane to Current through its original Blizzard session-menu radio entry. Native
stored {type=Current,sessionID=nil} data/responders remain untouched; no private
session setter or history reset is called. Already-Current panes skip selection.
All ten presets, unchanged types, Overall/history, same-layout reselection,
manual overrides and historical-ID clearing have focused coverage. Geometry,
menu opening and background events preserve later manual segment choices;
the next layout choice restores Current. Threat remains independent.
User reloaded and confirmed: all native panes switch to Current on layout choice.
Acceptance is selected Forever UI/function only; native combat/secret/taint,
gamepad, other-client execution and FPS remain pending. No new frame/event/hook/
timer/recurring driver, direct WTF writes, profiler change or game input.
Fresh source pins and external source/history/settings recovery verified.
Final validation:212 scripts/875 Lua syntax files PASS with unchanged corpus;
all5 installed backend/layout pairs match. No duplicate sync performed.
Exact paired/focused/full results and source identities are in the evidence.
[Evidence](validation/meter-layout-current-2026-11-07.json).

7 November party mode and aura columns (REQ-RF-44 through REQ-RF-50):
Party / Raid keeps compact mode as default and adds smaller player-style party
frames, portraits/casts, optional player-pet-style companions and scale controls.
Four other members and four pets use shared UF factories; actual outer hit
rectangles register with Flux bindings. The new final member matches the old
compact party bottom-right at every roster count. Existing raid/compact anchors
stay unchanged. Prepared native state conditions handle combat joins/leaves,
raid conversion and pet existence; option edits defer. Preview party uses the
same visual factory and shared aura sample renderer with isolated non-secure
cells. Aura grids fill columns first (top then bottom), debuffs left, buffs
mirrored right. Uniform glyph/slot sizes remove former boss-slot gaps; limits,
strict dispellable-only, X scale, duration and opacity remain supported.
Reported Secure.lua:445 nil call fixed: ordinary cleanup uses owned references;
GetFrameRef remains inside restricted snippets. Five native secure-handler
models reject ordinary getter access. 535 focused party checks, 210 actual binding checks, 12776 aura
checks and full 213-script/876-syntax suite PASS with unchanged tested corpus.
Five fresh alternating pairs reject the prior grid, and five reject the reported
cleanup mutant. Default mode creates no extra live cells; alternate mode uses
8 cells/8 state conditions and existing active-cast work, no new recurring Lua
roster/range driver. Native visuals/input/combat/taint/FPS remain pending on each
client. External dated source/history and158 on-disk settings files verified;
no game input, WTF/profiler writes, manual sync, branch or push. Meter work was
explicitly excluded and no meter files were edited by this task.
Follow-up: zero spacing between new party members; actual outer buttons reuse
the owned party/raid primary/modifier mouse path and existing hover engine.
Final documentation validation and whitespace checks PASS; all12 feature files
match across all5 installed clients through the existing mirror. Native checks
retain the pending scope above.
[Evidence](validation/raid-party-mode-2026-11-07.json).

7 November native meter controls/presets (METER-NATIVE-CONTROLS-20261107):
the previous picker changed only a layout request. Native type rows now come
from Blizzard's actual menu descriptions and use their public Pick selection
API with untouched responders/data. Explicit type/setup/preset/custom/structure
clicks use native menu entries; missing panes use the original New Window entry.
Preset clicks apply every requested native type immediately. Startup, geometry
repair and combat events never select types/create native windows. Existing
session/history and Save controls remain; no private native setter calls return.
Native responses update both the runtime snapshot and matching active editor
slot, with stale layout/type guards. Absorbs is removed from the catalog and
builtin5 now uses HPS. Legacy unavailable requests normalize in working views/
previews only; untouched saved custom layouts retain their original requests
until explicit Save. New builtin10 is Threat/Damage over Interrupts/Healing.
Threat remains a separate owned Content child and consumes zero native windows.
User confirmed native menu/type/Flux-label changes, direct Dispels pane creation,
and finally both Dispels and new Interrupts four-pane presets work immediately.
Acceptance is selected Forever UI/function only; native combat/secret/taint,
gamepad, other-client execution and FPS remain pending. Fresh pinned source,
paired desktop/mutation/full results and exact identities are in the evidence.
Final meter checks: all11 focused meter/threat scripts PASS; 220 native-control
checks,256 checks per pinned client menu replay, five baseline-rejecting pairs
and five rejected mutations. All5 installed backend/layout pairs match the final
tested hashes through the existing mirror. The final whole run has874 syntax
PASS,205 scripts PASS and6 unrelated concurrent raid-test failures; global corpus
drift prevents a whole-addon PASS. Meter owners stayed unchanged; preserve the
unrelated raid work. Documentation validation reports19 unrelated unit/raid
inventory/verification issues and no meter-source errors. Native acceptance
remains selected-client UI/function only.
Source/history recovery and available on-disk settings verified; no foreground
control, direct WTF writes, profiler changes or manual client copy operation.
[Evidence](validation/meter-native-controls-2026-11-07.json).

7 November mouseover casting (MOUSEOVER-NATIVE-20261107): the toggle remains
directly in the spellbook. Retail/Forever use Blizzard's actual Click Casting
checkbox with its original click/tooltip handlers; it returns to its original
owner/anchors when Click Casting opens or the book closes. Native state and
modifier are authoritative; unsupported clients retain the custom toggle and
saved preference. Defaults and binding saves no longer reset native state or
modifier. Native slot targeting stays prepared through combat; standalone
spell/item adapters on wrap clients follow the same setting/modifier with the
existing combat deferral. Reuses the shared observer; no new recurring driver.
388 focused checks pass, including actual pinned Blizzard click/target methods;
five baseline rejections/five candidate passes. Final whole-addon run: 211 scripts
and 873 Lua syntax files PASS; complete tested Lua corpus unchanged. Native visuals/input/gamepad/
taint/FPS remain pending. All five installed source sets match through the
existing mirror; no manual copy, game input, WTF/profiler writes or push.
External source/history recovery and settings archive verified before edits.
[Evidence](validation/mouseover-native-2026-11-07.json).

7 November screenshot default preset (REQ-RF-43): user chose member width
0.70, height0.95, power1.00, aura scale1.82, aura X0.50, timer font1.72,
manager1.20 and enabled under-one-minute timers as the default. Both saved
scopes now use these values. Reset sizes copies these eight fields from the
default table, preserving counts/filters/opacity/positions and unrelated data.
Full raid reset uses the same preset; existing explicit custom values are
not migrated. Scale units/rendering remain unchanged, including manager
1.00=70percent native; new default1.20 is effective0.84. Screenshot preserved
externally with hash. Actual scoped reset/refresh checks verify69x42 cells
and10.01x20.02 normal aura geometry; combat changes still defer.
209 scripts/871 syntax PASS with unchanged corpus; five
fresh alternating pairs reject the old all-one default/reset behavior. Eight
other-client files already match; no duplicate copy. No new resource owners
or recurring driver. Separate new native reset check not performed; prior
native renderer acceptances retain their original scope.
Final preset hashes and8 other-client copies remain matched. Global docs
validation is pending18 stale-view/verification issues caused by newer
unrelated meter/binding/core edits; checker made no edits. Preserve those
changes and do not infer whole-current-tree PASS from the209/871 snapshot.
[Evidence](validation/raid-screenshot-defaults-2026-11-07.json).

7 November native meter presets (METER-ALL-OPTIONS-20261107): fixed blank
slots when a requested type/window does not already exist in Blizzard's native
configuration. Reserve all exact matches first, then keep unused native panes
accessible for type selection. Mismatched rows have an explicit setup cover;
uncreated slots use the same shared artwork/title/font/color/scale as Damage
and Healing. A native type choice or new-window action triggers one coalesced
layout repair; combat changes defer to the existing regeneration path.
The user chose to keep native meters and configure extra windows once using
Blizzard's menus. No custom renderer, automatic native configuration/creation,
session reset or new recurring driver. Already configured Absorbs and all eleven
enum types skin normally; pinned Retail/Forever native menus omit Absorbs, so
that unavailable selection remains explicitly disclosed. The earlier screenshot
showed the pre-shared-skin setup pane; final native visual/interaction/combat/
taint/FPS acceptance remains pending. 128 focused checks and five alternating
baseline/candidate pairs pass; baseline fails the missing-pane case. Final whole
suite: 209 scripts/871 syntax PASS with unchanged Lua corpus; documentation
validation PASS. Exact identities are in the evidence record. External dated
source/history recovery and existing settings archive verified; fresh settings
metadata only. No game input, settings/profiler writes or manual client sync.
[Evidence](validation/meter-all-options-2026-11-07.json).

7 November Forever talent-group icon (UF-SPEC-03): user's native dump returned
Mage/spec1482/class icon626001/zero points with no dual spec. Forever's loaded
Camelot talent UI uses trait group headers, not Classic specialization tabs.
Resolver now reads active spec group's combat config, tree group display icons
and matching group currency spent; largest investment wins. No profile or
nonmatching profile uses that icon; matching Respec override stays first. No
class placeholder is fabricated for zero/missing data. Single spec works.
59 focused checks; five old-source rejects/five candidate passes. Existing
geometry, events, debounce, settings and other-client policy remain. Native
candidate visual/combat/taint/FPS acceptance pending.
Final rerun: 209/209 scripts and 871 Lua syntax files PASS. The earlier run
caught a concurrent meter-source/test transition; its focused rerun and this
complete rerun pass. The tested unit-frame runtime is unchanged and all five
installed copies match. Native icon/combat/taint/FPS acceptance remains pending.

[Group-icon evidence](validation/forever-talent-group-icon-2026-11-07.json).

7 November MT target opacity (REQ-RF-42): in-range target minis now use
the configured base opacity directly, without the extra member in-range
dimming factor. Unavailable or opaque checkedRange also keeps base opacity
instead of treating an enemy target as far away. A genuinely checked far
result still uses configured out-of-range alpha. Secret checks precede every
checkedRange comparison. Normal member/pet fading and user base transparency
remain. Preview target strip uses the same base opacity. No new range call,
frame/pool/event/ticker/timer. User reloaded: Yes, opacity looks right.
Final scoped audit: all7 raid runtime files and28 other-client copies match
tested identities. Global docs validation remains pending because concurrent
UnitFrames/FluxUnitFrames_Shared.lua and tests/unit_spec_icon.lua edits made
the generated interfaces and verification index stale; checker made no edits.
Preserve those newer unrelated changes; do not infer whole-current-tree PASS.
208 scripts/870 syntax PASS, unchanged final corpus; five
fresh alternating pairs reject the previous in-range mini fade. Eight other
client files already match. Earlier manager/highlight and HP-only target
checks remain accepted. Native acceptance is selected-client visual/function
only; broader native combat/taint/other-client/FPS checks remain pending.
[Evidence](validation/raid-mt-opacity-2026-11-07.json).

7 November talent spec-icon follow-up (UF-SPEC-02): fixed client flags lookup
from nonexistent ns.Client to the actual ns.Flux.Client export. The prior mock
supplied the same invented namespace and missed the skipped Forever/Classic
committed-points path. Fixtures now execute Core/Client.lua before resolving
icons, including live point changes and matching/no/nonmatching profile states.
38 checks PASS; five alternating pairs reject all five old-source runs and pass
all five candidates. Existing icon geometry, profile matching, refresh debounce,
events/timers and settings remain. Full 208 scripts/870 syntax PASS, tested runtime hash unchanged. All five
installed runtime copies match; no duplicate sync performed. Native icon
acceptance is still pending.
[Spec evidence](validation/unit-spec-talents-2026-11-07.json).

7 November MT target HP strip (REQ-RF-41): target minis now show only the
target name left and plain HP percent right on one centered row, with no
resource bar and the full strip available to HP. Target percent is separate
from the main member health-text preference and contains no role prefix.
Power events cannot re-enable the target resource bar or query its power.
Pets/full members retain their policies; secure target routing/casts and
reserved mini height remain. The MT preview now includes a pooled target
strip using the same chrome; reused roster samples retire old target strips.
Preview minis skip aura construction. User reloaded: Yes, looks right.
208 scripts/870 syntax PASS with unchanged final corpus;
ten fresh alternating unit/chrome pairs reject the old behavior. Sixteen
other-client files already match. No new event/ticker/timer; at most one
reusable plain target preview per displayed MT owner. Source/history/settings
checkpoint verified with these four runtime owners unchanged despite other
workspace edits during collection. Manager/highlight fixes remain accepted.
Native acceptance is selected-client visual/function; broader combat/taint/
other-client/FPS checks remain pending.
[Evidence](validation/raid-mt-target-2026-11-07.json).

7 November unit indicators/spec: player/target/focus share a fitted grid above
health beside class/spec, including native enum master loot. User rejected moved
raid-group labels, shortened names and the health-inset prototype; final grid
reserves no name width and keeps name-relative group placement. ZZZ animates
beside the visible level with static fallback. Matching Respec profile overrides
live spec; No profile/nonmatching uses the most-invested committed tree on
Era/Anniversary/Forever, then active specialization where available. Fixed the
forward-local resolver and current namespace fields. User Forever loot dump
2,0,1 confirms master loot/ownership API; candidate visual acceptance pending.
Desktop evidence and native pending scope: [unit indicators](UNIT_FRAME_INDICATORS.md).
208 scripts/870 syntax PASS; tested runtime hashes unchanged. All five installed
Shared.lua copies match through the existing mirror; no duplicate copy. Native
visual/combat/taint/FPS acceptance remains pending.
No game input/settings/profiler changes; preserve unrelated main work.

7 November currency clicks (STATUS-CURRENCY-20261107): left-click opens/toggles
native Currency where supported, including Retail and Forever, outside combat.
Right-click opens FluxUI Status Bars settings. Existing no-tab fallback and
item drag/clear actions remain. Verified pinned loaded sources: Retail 297d7aaa
(12.1.5.70783), Forever 9dc84f0d (1.60.1.70862). External source/history/settings
recovery verified; fresh settings metadata read only. 640 currency checks and
180 reputation checks pass; preceding currency source fails 44 checks.
Validation run: 208 scripts and 870 Lua syntax files pass. Later concurrent
unit/raid edits leave documentation inventory/verification stale (12 issues);
currency source still matches its tested hash. The initial run
caught a concurrent unrelated unit-indicator test syntax error, since corrected
by its owner. Existing mirror delivered matching Retail/Forever currency files.
No new recurring resources or performance claim. Native clicks/gamepad/taint
remain pending; no game input, settings/profiler writes or manual client sync.
[Evidence](validation/status-currency-clicks-2026-11-07.json).

7 November manager/hidden native highlights (REQ-RF-39/40): manager1.00
now uses a70percent native baseline, as explicitly requested; saved values
and physical vertical alignment/native X/collapse behavior remain. Hidden
selection/ready-check layers now inherit ancestor opacity, including when
their own alpha is opaque. Original flags/known alphas restore on disable.
Two secure post-hooks catch late native setup/selection updates, including
anonymous pooled children. Unprotected alpha/inheritance changes suppress
late combat highlights; structural changes still defer. Native events,
scripts, parents, visibility, profiles and restricted aura subtrees remain.
206 scripts/868 syntax PASS with unchanged final corpus;
ten fresh alternating pairs reject the previous size/ghost behavior. Twelve
other-client files already match. No new pool/frame/ticker/event or polling.
Final workspace refresh after unrelated UnitFrames changes:207 scripts/869
Lua syntax PASS with unchanged corpus; the earlier206/868 raid run is retained.
Five fresh pinned API sources verify the display methods are unprotected.
User reloaded and confirmed: Both fixed. Native acceptance is selected-client
visual/function only; broader native combat/taint/FPS checks remain pending.
[Evidence](validation/raid-manager-overlay-2026-11-07.json).

7 November final live aura width (REQ-RF-38): native width now follows the
slider through scoped refresh. Stored initializer metadata supplies sizes;
out-of-combat styling first checks canaccesstable for all native buttons and
labels. No native size/unit/visibility is read. If native access is denied,
keep the existing icons and geometry and mark pendingWidth for later safe
refresh. Public group layout updates the flow widths. Native source uses
DenyTaintedAccessWhenAurasAreSecret, correcting the earlier blanket assumption
that every styling change needs reload. The external display-sibling attempt
failed native visibility and was rolled back; rejected source/logs remain
external. The guarded replacement was accepted: Live icons resize correctly.
User also accepted preview parity, live timer font, zero-gap side grids,
black outline/shadow and below-one-minute timer policy in earlier checks.
206 scripts/868 syntax PASS, unchanged final corpus; five
fresh alternating pairs reject the old preview-only width callback. Eight
other-client runtime files match; no duplicate copy. Metadata only, no new
frame/pool/event/ticker/timer. Native acceptance is selected-client visual
behavior; other-client/combat/taint/FPS checks remain pending.
[Evidence](validation/raid-live-width-guarded-2026-11-07.json).

7 November live timer/grid/policy (REQ-RF-35..37): timer-font slider now
updates a shared public Font inherited by already registered native labels,
instead of a size captured at reload. Combat changes defer; X width still
requires reload. Buffs remain right and debuffs left, up to three columns
and two rows with zero icon/row gaps. User reloaded and confirmed: Both work.
Added black OUTLINE plus black shadow, and an optional Show aura timers only
below 1 minute toggle (default off in both scopes). One shared numeric
formatter blanks60seconds and above, retaining icons/swipes/stacks without
reading restricted durations. Native bindings and preview/readable clocks
share that formatter. User also confirmed shadow/threshold behavior: Yes, all work.
206 scripts/868 syntax PASS with unchanged final corpus;
ten alternating pairs reject the earlier grid/options behavior. All20
other-client files match; no duplicate copy. One shared Font/formatter,
no new native aura family or addon event/ticker/timer. Other-client native
combat/taint/FPS checks remain pending.
[Evidence](validation/raid-timer-policy-2026-11-07.json).

7 November preview/live parity (REQ-RF-34): user reported differences in
both frames and auras. Live and preview now inherit one visual XML template
with separate secure/plain behavior. Shared owned-health aura bounds and
canonical duration-font projection remove independent sizing rules; preview
side hosts clip like live rows. All health-text modes use one formatter;
offline colors, center host/layer/size, overflow atlas/geometry and prediction
sample colors/order now match live. Readable large aura X scale is corrected.
Positions, joins, ordering, bindings, saved scopes, filters/counts/opacity and
swipes remain. X/font native changes still require the documented reload.
206 scripts/868 syntax checks PASS; unchanged final Lua corpus.
Five fresh alternating pairs reject the old preview. All20 other-client
files already match; no duplicate copy. Two public clip hosts per preview,
no new addon event/ticker/timer. User reloaded and confirmed: Looks consistent
now. Acceptance is selected-client visual/function only; other-client native
combat/taint/FPS checks remain pending.
[Evidence](validation/raid-preview-parity-2026-11-07.json).

7 November aura width/font controls (REQ-RF-33): added Aura width (X) and
Aura duration text size, both 0.50..2.50 with default/reset 1.00 in both
scopes. Preview updates immediately. Live native glyph/text dimensions are
prepared only by their one-time initializer, so these controls explicitly
require /reload; ordinary refresh retains the loaded native width. Normal
and large glyph widths/slots scale together, height stays unchanged, and
duration font size multiplies the fitted text size. Existing overall size,
filters, counts, opacity, swipes and combat deferral remain.
206 scripts/868 syntax checks PASS with unchanged sources;
five alternating baseline/candidate pairs reject missing X scaling. All20
other-client files already match; no duplicate copy performed. No new
pools/events/tickers/timers. Native visuals/combat/CPU/FPS remain pending.
[Evidence](validation/raid-aura-width-font-2026-11-07.json).

7 November aura-only scaling: user explicitly chose to resize only auras,
keeping frame size fixed and permitting larger blocks outside the frame.
Removed the hidden inside-fit cap from actual geometry and the slider;
0.50..2.50 now applies directly, with Blizzard 11px/16.5px at 1.00.
Counts, filters, opacity, swipes, fitted fonts and combat deferral remain.
206 scripts/868 Lua syntax PASS with unchanged sources;
five fresh alternating baseline/candidate pairs reject the old cap. Eight
other-client files already match; no duplicate copy performed. No recurring
resources added. New native visual/combat checks remain pending.
[RAID-AURA-INDEPENDENT-SCALE-20261107](validation/raid-aura-independent-scale-2026-11-07.json).

7 November final native-size contract: user chose all Blizzard default sizes,
then explicitly required no toggle and1.00 as every size slider's native baseline.
Frame/power/aura/manager scales now use source defaults without the earlier1.3,
power0.8 or manager0.85/MT0.9 multipliers. Reset sizes changes only five size keys;
full defaults also1. Existing stored requests remain until reset. Fonts, normal11
and boss/role16.5 squares, insets/bars/indicators follow pinned native equations;
one-pixel joins and half-height minis preserve the native body. Counts/strict
RAID filters/class buffs/Flux casts/visible fitted timers and bronze theme remain.
The screenshot's oversized Offline/health label reproduced cumulative FontString
scaling; absolute Font-object baselines now pass50-refresh/locale regressions.
User reloaded, used Reset sizes and confirmed: Yes, sizing and fonts look right.
206 scripts/868 Lua syntax PASS with unchanged corpus;20 baseline/20candidate pairs and
five font-specific pairs reject the old failures. All five client folders match;
36 other-copy file hashes verified with no duplicate overwrite. Native acceptance
is limited to the selected test client; other-client/combat/taint/FPS checks remain.
Latest Forever source is5987a8e (70840); other four pins unchanged. Preserve all
unrelated main work and preferences; no agent game input/commit/push/WTF writes.
[Native-size record](validation/raid-blizzard-default-sizing-2026-11-07.json).

7 November class travel/restock: inspected current main, rules/specifications
and travel/reagent/preset owners; preserved concurrent aura work. Verified three
external source/history/settings checkpoints. Reproduced cold rune, Soul Shard,
missing editor and preset-classification failures. A final audit found native
spellbook flyout costs were skipped; extended existing Core.Spell fallbacks and
indexed known children with override selection/deduplication. Four runtime files
reuse existing persistence/editor/index; no new polling.
130 travel + 47 scanner/list/facade checks; 16 faulty mutations rejected; five
alternating pairs per component. Warmed travel fixture: 1,000 tooltip scans to
zero, unchanged reagent results; raw host samples retained, no native FPS claim.
Scoped replay passes all six required scripts with unchanged reagent sources.
The last whole-addon run passed 200 of 204 scripts and all 866 syntax files;
four raid-test failures and unrelated source drift prevent a whole-tree PASS.
All four runtime files match the four existing client copies (16 hashes). A
manual-copy verification stopped during active continuous sync; three later
read passes confirmed every candidate, with external destination backups.
Documentation validation also remains blocked by concurrent raid edits: one stale source-inventory entry and three verification hashes. The checker made no edits; reagent source/test hashes remain matched.
Baseline background transport completed without a visible FX marker in the busy
auction/craft capture; native candidate checks pending. No test purchases,
settings/profiler change, new branch or commit/push.
[Case](TELEPORT_REAGENT_RESTOCK.md).

7 November final user check: after reload the user confirmed, Yes, height and
normal auras work, for the taller frames and normal aura/duration-text slider.
All five client folders match the tested feature files;20 destination hashes
verified. This task performed no second overwrite because those exact candidates
were already installed. Other-client native execution, combat/taint and FPS
remain pending; this is visual/function acceptance in the selected test client.
[Native acceptance](validation/raid-aura-slider-live-2026-11-07.json).

7 November live aura slider follow-up: user rejected the previous slider
display and clarified that the main frames must be30% taller too. A user-owned
probe at1.45 showed capped12.1px icons; forcing0.50 through the actual scoped
refresh returned public scale0.4767 and the user confirmed normal icons shrank.
That proves prior native scale propagation. New UI exposes the responsive fitted
range with0.01 steps/current dimensions, preserves stored requests until selection,
and refreshes cached bounds without synthetic saved writes. Main heights now
multiply saved scale by1.3 (default43->56; saved1.0:36->47); width remains.
Canonical normal icons10x19.5 fit that height; duration fit and strict1–6 limits
remain. Mini targets stay within their18px reservation. 203 scripts/865 Lua syntax PASS,
with all runtime/aura/renderer sources stable during both complete runs;
20 matched baseline runs rejected/20 candidate runs pass. An unrelated teleport
test changed during both runs, and its runtime owner changed that subsystem
afterward. Both raw manifests remain; the global corpus is not called frozen.
All five delivered feature files match the tested manifest; unrelated work stays.
Final new UI/height/native combat/taint/pixels/FPS acceptance is pending all5.
No agent game input, WTF writes, profiler change, commit or push. The user probe
set aura scale0.50; choose the desired new value after reload.
[Live slider record](validation/raid-aura-slider-live-2026-11-07.json).

7 November aura size/count correction: user chose to keep icons inside and
cap their size. Canonical10x15 native creation removes startup-dependent sizing;
live/readable/preview share uniform fitted geometry. User's later x1.30 request
uses the confirmed30%-taller choice:1.00 requests14.3px height vs old11px;
minimum0.50 permits shrinking; inside-fit cap remains. Duration fonts fit the
actual icon rectangle, including m/h/d suffixes at partial clip edges.
New scoped maxBuffs and
maxDebuffs1–6 default6; demo counts remain separate. Strict mode retains only
HARMFUL|RAID on every original/tail owner. Exact4/5 across mixed categories uses
lazy clipped native row copies; no native child inspection or handler replacement.
Default native icon pools stay120/cell; both partial sides can add120 once, reused
and unbound while inactive. No new addon recurring work. 200 scripts/862 syntax PASS,
unchanged Lua corpus; five alternating regression pairs per aura/layout/preview
reject15 baseline runs and pass15 candidate runs. Native pixels, logical-visible
clip scheduling, combat/taint/casts and FPS remain pending on all5 clients.
Preserve unrelated work and profiler preferences; no commit/push or game input.

Installed the five tested Lua files into all four existing client copies after
external guarded backups; all20 destination hashes match the tested source.
Retail remains the working copy. No game input/settings/profiler change.
Reload outside combat to test the new normal-aura sizes and limits.
[Size/count record](validation/raid-aura-limits-2026-11-07.json).

7 November background/native follow-up: verified current main and new external
Unit-secret-followup-20261106T224752Z checkpoint (1683 actual files/179 settings;
ZIPs/all-ref history verified). Forever background name probes showed earlier
fix functions loaded/profile0/BugTabs0; later short count also0. Read-only
captures show user-driven auction/mail/casting activity, not measured latency.
Reproduced restricted cooldown comparisons through actual BadgeHost; retained
scalar/tuple/public output rules and added public metadata for restricted timers.
Removed proven unused PCO width snapshots; active ghost/animation bodies intact.
150 new checks/10 mutants; final199/861 full validation PASS, unchanged source.
Five matched pairs/client or power scenario record counts/raw host intervals;
no native FPS claim. Copied five files to four clients with external backups,
20 hashes match. User reloaded and performed ordinary combat; native cleanup
marker=nil and BugTabs0 afterward. Combat frame/action/cooldown/threat rendering
observed; direct restricted-case/swap/pixel/performance/other-client checks pending.
An app-switch helper change was auto-review rejected and not run; original
strict background guard retained. Interrupted probes are unexecuted and not
acceptance; no verified owned draft remained in later captures. No commit/push.
[Case](UNIT_STATE_SECRETS.md#follow-up-badges-and-unused-power-snapshots).

6 November unit-state errors: verified actual main/dirty source and external
Secret-unit-state-20261106T215659Z checkpoint (1674 files/197 settings plus all-ref
history; archives verified). Reproduced Name/ProgramFace/overlay failures with
actual modules; corrected predicate order and readable identity caches. Review
also caught opaque-start/public-finish feedback and pet replacement, now covered.
Four new scripts:344 checks/23 mutants; final197-script/859-Lua suite PASS with
unchanged source. Public names/key formats and feedback work/resource counts
preserved in five alternating desktop pairs; safety gates add host overhead.
Copied only five runtime files to four existing clients after verified external
backups;20 hashes match. Exact Forever host/window verified; capture succeeded,
background reload refused before input because game was active. No profiler or
settings change, native acceptance, random-freeze resolution or commit/push claim.
User reports TacoTip unloaded and chose read-only; no third-party edit.
[Case](UNIT_STATE_SECRETS.md), [samples](validation/unit-state-secret-comparison-2026-11-06.json).

6 November TacoTip error audit: inspected current tree/continuity and preserved
newer raid/aura changes. Read installed0.9.4 source/license and compared native
Backdrop size callback/arithmetic. The owned overlay is a source-matched suspect;
exact native frame remains unverified. Existing Flux tooltip integration does
not implement its border. Desktop fragment replay reproduces secret-width
arithmetic; no native safety or performance claim. Requested scope clarification
before any third-party edit; the user chose read-only. No TacoTip changes are planned. No runtime or game changes from that audit.
[Finding](TACOTIP_BACKDROP.md).

6 November aura text scaling: user returned the native owned-clock probe.
It confirms automatic positive/zero visibility and plain59/1m/30m formatting
for that isolated widget. Known59 measured15.2 inside12px; the previous6px
font floor was insufficient. Duration text now uses proportional SetTextScale
against public sample width/height, before native registration. Text shrinks
below the old floor and grows with larger icons; cached measuring owner,
layout, opacity, swipes and aura filters remain.193 scripts/855 syntax PASS
with unchanged source; five alternating pairs/case reject the old code.
These are logic/source contracts; actual fitted aura pixels, combat/taint/FPS
and other-client execution remain pending. Preserve unrelated work/preferences.
Installed the three changed Lua files in each of the four existing client copies
after external backups; all12 destination hashes match the tested source.
XML/TOCs/settings and profiler preferences remain unchanged. Reload and inspect
actual aura text for final native fitting acceptance.

[Text scaling record](validation/raid-aura-text-scale-2026-11-06.json).

6 November aura clock correction: the user rejected the previous display:
duration showed ... and short buffs/debuffs had no swipe. New text uses plain
seconds then m/h/d, with7px preferred/6px fitted font from public sample
measurements on a separate hidden widget. The native cooldown starts visible
before sink registration; an explicit opaque base texture removes inherited
tint alpha. Existing transparency,3×2 layout and aura filters remain.
193 desktop scripts/855 Lua syntax PASS with unchanged corpus; five alternating
pairs/case reject old source and pass the candidate. These are logic/style
contracts, not native glyph or swipe rendering proof. User was given an OOC
owned-widget diagnostic; actual C-widget result and corrected display acceptance
remain pending. Preserve all unrelated map/glow/spike-watch work/preferences.
Installed the four corrected runtime files into all four existing client copies
after guarded external backups; all16 destination hashes match. The earlier
Forever diagnostic-only file was preserved and replaced by this tested candidate.
The user may check the new display directly after reload; the owned diagnostic
is optional if the display remains wrong. New native acceptance is pending.

[Clock correction record](validation/raid-aura-clock-fix-2026-11-06.json).

6 November aura duration follow-up: user confirmed a cooldown swipe over each
buff/debuff with remaining duration text above it. Raised intrinsic swipe
alpha0.3→0.75; centered9px outlined/shadowed timers; native labels use one
owned compact formatter when available. Readable timer text now sits above
the swipe and clears on timed→permanent reuse. Alpha settings, icon sizes,
3×2 blocks, eligibility and strict dispel filtering remain. No new frame,
ticker or timer owner; one cached native formatter object.
Final193 desktop scripts/855 Lua syntax PASS with all source hashes and
membership unchanged. Five alternating pairs/case reject the old display
and pass the candidate; raw outputs retained, no native CPU/FPS claim.
New native appearance/combat/taint checks remain pending. Reload and check
a timed buff/debuff plus a permanent buff; preserve the optional spike
watch/profiler preferences and all unrelated map/glow work.
Installed only the four changed raid runtime files in each of the four existing
Forever/Classic client copies after external backups. All16 destination hashes
match the tested source; TOCs/settings and profiler preferences are unchanged.
The new native display remains pending a user reload/retest.

[Duration record](validation/raid-aura-duration-2026-11-06.json).

6 November native follow-up: after the background guard again refused input
before sending any command, the user ran the read-only map probe with Map
visible and pasted `FXMAP true true 0`. Recorded as user-reported native
provenance/error acceptance only. No hot restoration of native fields, reporter
suppression, profiler change or physical input was used. Requested a fresh
optional600-second spike watch to investigate any remaining random freeze.
[After](validation/map-provider-native-after-2026-11-06.json).

6 November map batches completed: verified external recovery checkpoints
Random-spike-resume-20261106T170042Z and Map-provider-combat-before-20261106T171453Z.
Actual normal Map tab activation changed shared method provenance from secure
to_FluxUI. Fixed detached quest/waypoint callback and handler retention, stale
quest timers, then removed shared native overrides and guarded owned restricted
acquisition.31/36 focused checks and mutation regressions pass; five alternating
pairs retain exact source/count/raw host-clock scope.193 scripts/855 syntax pass
with unchanged corpus. Preserved old copies externally and copied this one
changed runtime file to all four existing client installs. Forever reloaded
17:28:52UTC; native post-activation probe blocked while game foreground, with
no completed command on the ready attempt. No native performance or all-client
acceptance claim. [Case](MAP_PROVIDER_LIFECYCLE.md).

6 November resumed at the user's request. Verified fresh external source,
all-ref history and on-disk settings checkpoint Random-spike-resume-20261106T170042Z
(1,660 actual files /190 settings, ZIPs and bundle verified). New Forever process
and exact window were verified; no active watch and live scriptProfile=0.
Normal Map tab activation changed shared native pin methods from secure to
_FluxUI tainted. Meter tab restored; no FPS or causal freeze claim. Fixing
owned-provider detach leaks first, then reviewing restricted pin ownership.
[Native baseline](validation/map-provider-native-baseline-2026-11-06.json).

6 November user-requested pause: stopped audit agents and all further native
input/runtime work. Preserved final191/853 no-drift desktop validation and the
current local main work. The v2 native watch ended early at a reload/logout
boundary after239.516s; recorded one3185ms gap with2.2509ms nearest Flux time,
plus12 later SetPassThroughButtons blocked-action repeats. Exact freeze cause
is not established. A shared native-map mixin rewrite is an unsafe source lead
requiring owned-provider lifecycle verification; no map change was made.
NEXT_SESSION.md records exact next steps. No lag-batch commit or push.

6 November Forever badge handoff follow-up: user accepted main↔mini glow in
combat, but reported bar→badge glow disappearance and missing badge icon on
combat row swap. Verified the dated external badge-handoff source/history
checkpoint and existing SAO saved-setting key. Traced reverse badge candidate
omission, clipped proc border, and dormant badge without ActionType/SpellId.
Changed badge preparation/show/hide and combat-only visual face paint. Old
BadgeHost fails the new icon fixture; candidate passes 11/25/7 focused paging,
preparation and row-swap checks plus 77 glow checks. Full desktop run passes
190 scripts / 852 Lua syntax files. After `/reload`, user confirmed modern
glow following bar↔badge both ways and clearing at proc end, plus badge
icon/count/cooldown following the action main↔mini during combat. Taint,
pixels, matched frame time, other procs and clients remain unverified.
[Case](FOREVER_SAO_GLOW.md#badge-handoff-and-combat-row-icon-follow-up-current).

Native follow-up16:29UTC: ExtraButtons, CombatGrid and NonCombatGrid enabled;
current-session BugTabs errors0; profiler0. Watchv2 confirmed running600s /
200ms in Forever; completion/save and analysis pending.
[Startup](validation/ebs-glow-startup-native-2026-11-06.json),
[arming](validation/forever-random-spikes-v2-armed-2026-11-06.json).

6 November random-spike evidence and bounded fixes: preserved external
Random-spike-diagnosis-20261106T143953Z and
Random-spike-finer-capture-20261106T153942Z source/history/settings checkpoints.
Reproduced1000 duplicate same-frame EBS layout callbacks and coalesced them to1
while preserving reasons, reentrancy and direct Flush. Added exclusive owned
callback timing observers and optional bounded watchv2 in existing FluxPerf.
Cached only unchanged writes to the stance module's owned aura text; formatting,
expiry, native digit reconciliation and per-frame response remain intact.
Focused checks:89 layout,1066 observers,119 watch,2075 aura text. The frozen
v2 full-tree run passed186 scripts /848 Lua syntax files before concurrent glow
changes. Read and preserved the user's native seven-gap watch and120-second
CPU profile; scriptProfile0 was independently read live. Specific random-spike
cause, leaks and native optimization acceptance remain pending.

Preserved the newer Grid-startup-error-20261106T161936Z checkpoint
(1638 actual files,184 settings, verified ZIPs/all-ref bundle) before checking
reported Paint3403 startup errors. Saved history has 3 records/38 repeats,
all before the current file; Retail/Forever disk copies match. A diagnostic
using unavailable debug.getinfo failed separately and was replaced by a
nil-safe read-only probe. Background guards block input whenever WoW is active.
[RANDOM_SPIKES.md](RANDOM_SPIKES.md) records scope and remaining checks.

6 November Forever SAO main/mini and badge follow-up: user confirmed the
previous secure slot starts the Retail glow during combat, then reported failed
modifier and badge handoff. Verified external
`FluxUI-forever-secure-proc-paging-20261106` checkpoint and existing enabled
SAO setting. Prepared potential row/badge destinations OOC and added alpha-only
face gating in the existing effects owners. Saved Effects.lua fails the new
first assertion; candidate paging model passes 9, glow model 77, and full
desktop runner 187 scripts / 849 Lua syntax files. Native handoff, clearing,
taint, pixels and frame time remain pending.
[Case](FOREVER_SAO_GLOW.md#mainmini-and-badge-handoff-follow-up-newest).

6 November Forever SAO combat glow: verified external
`FluxUI-forever-secure-proc-20261106` source/history checkpoint and read the
installed SAO glow-enabled setting. Compared Gethe Retail/Forever/Era/
Anniversary button alert flow and Forever secure AuraContainer source.
Added a filtered 400589 secure slot with Retail flipbook animation to resolved
Arcane Missiles widgets; removed duplicate readable fallback once prepared.
Focused tests pass 69 checks, full runner 186 scripts / 848 Lua syntax files.
Installed Forever Glow.lua matches the repository hash. Native combat and
proc-end validation are pending.
[Case](FOREVER_SAO_GLOW.md#secure-auracontainer-button-animation-candidate-latest).

6 November consumable follow-up: verified external all-ref checkpoint at
`48ea994`; inspected Retail/Forever settings read-only. Added public aura-delta
tracking, direct readable flask scan, weapon-enchant events and modern API
fallback. Five paired loaded-module runs: 46 baseline / 66 candidate checks;
candidate binds the next secure item action for flask and weapon cases. Timer
35 and weapon-target 30 checks pass. Full desktop runner passes 185 scripts /
847 Lua files. Read-only docs checker reports 23 stale generated entries in
this and concurrent raid/performance work; native acceptance is pending.
[Case](CONSUMABLE_REFRESH_TIMER.md#aura-and-weapon-enchant-follow-up--6-november-2026).

6 November consumable aura advance: verified external all-ref bundle at
`ef813e0`; read-only Retail/Forever settings inspection. Five baseline/candidate
loaded-module pairs reproduce the 200 ms wait and pass immediate advance on
modern/legacy aura APIs (11/22 checks each). Existing refresh/weapon fixtures
pass 35/30; all 845 Lua files pass syntax. Native results remain pending.
[Details](CONSUMABLE_REFRESH_TIMER.md#immediate-advance-after-aura-gain--6-november-2026).

6 November aura follow-up: the user reported low aura layering and requested
Blizzard raid-frame aura selection. Complete icons, swipes, durations and
counts now sit above names/trim/highlights, with leader/loot/status above
them. Blizzard classifications and priority replace duration/shield rules;
helpful boss/role auras can occupy the debuff side. Public hidden-buff
preferences refresh without protected layout work. The requested strict
six-slot dispel policy and aura transparency remain. Explicit OOC present
class buffs override native hidden-group preferences. The user returned
a Forever stage-b diagnostic showing valid active native binding with15
hidden buff types after reporting no buffs. Stage-c corrects the OOC
class exclusion interaction. The user returned its diagnostic and then
confirmed that it works fully on Forever. This accepts observed aura
behavior only, not combat/taint/FPS or all-client execution. Native owners
still reject ProcessAura.None before supplemental filtering; the126-case
desktop model omits that gate, so complete native assignment is not proven.
Restricted private hideOnPartyFrames parity remains an API limitation.
Final 181 desktop scripts / 843 Lua syntax files pass; source hashes/membership
are unchanged across the run. Five alternating functional pairs per case
reject the old filters/layers and pass the candidate; no native FPS claim.
Native icon pools increase80→120 per full cell for native category ordering;
refresh remains bounded. Other clients and native taint/combat/performance
acceptance remain pending. No further runtime changes follow acceptance.
Shared documentation verification remains pending because an unrelated concurrent
ExtraButtonSystem/Layout.lua edit postdates the recorded shared test source.
The accepted aura hashes remain unchanged; its earlier frozen181/843 check is
retained. Do not overwrite the concurrent work or imply a current full-tree pass.

[Exact follow-up source/check record](validation/raid-blizzard-aura-followup-2026-11-06.json).

6 November Well Fed refresh follow-up: prechange main `582d868` and a verified
external all-ref bundle preserved; installed settings were inspected read-only.
The previous source failed a loaded-module alternate Well Fed aura fixture.
The candidate finds it, reuses its public ID, and shows the shared 25 minute
timer in the button/config until the 5 minute threshold. Focused timer and
weapon-target fixtures pass 35/30 checks; native client results are pending.
[Details](CONSUMABLE_REFRESH_TIMER.md#well-fed-follow-up--6-november-2026).

Final border preference: the user requested the same textured bronze as
HealKit after rejecting the plain matte candidate. The final renderer uses
original Blizzard8036209 gold bands at0.85 brightness with normal blending,
excluding dark padding. Rounded caps appear only on exterior grid corners;
shared separators have one owner. Earlier matte validation is historical.
The latest full validation fingerprints cover this native-art implementation;
native visual/secure-input/taint/performance acceptance remains pending.

6 November party/raid rewrite: the HealKit-style candidate retains outer dimensions,
chat docking, reverse group columns and Flux Binding, with the user's later
connected HealKit-style bronze borders,4px vertical overlap, horizontal0 gap,3×2 buffs right /
debuffs left, visible timers/swipes,70% aura transparency and scoped0–100% control.
Names are10px; role12px precedes percentage; leadership/loot/marks have their
own layer. Power base is×0.8. Members follow native INDEX/ASC order. Native
headers prepare80 cells and handle combat joins/leaves/subgroup moves;40 shared
conditions manage actual MT target visibility. Strict dispellable-only covers
all six slots; present class buffs show OOC, missing reminders remain off.
The manager is15% smaller, retains native X and uses one invariant full-panel Y
above the grid in collapsed/expanded/hidden/shown states. Native selection and
both ready-check ghost layers suppress/restore without replacing handlers.
Final desktop checks pass 179 scripts / 841 Lua syntax files; complete Lua membership/hashes are unchanged
across the run. Earlier user screenshots and the13:01:05 secret-mouse stack are
rejected-stage evidence. Final native pixels, casts, taint and performance remain
pending. No game input, profiler change, settings reset or other-client sync ran.
[Requirements and limits](RAID_HEALKIT_REWORK.md), [exact source/check record](validation/raid-healkit-rework-2026-11-06.json).

6 November runtime inventory and scope decision: main was clean at
`0f2e3fdaddb2105eea6afdd1058b96e85308180a`. External
Meter-runtime-inventory-20261106T113256Z preserves 1,596 actual sources,
177 settings files and all-ref history; ZIP/bundle checks pass. Source archive
SHA256: `3eebba4234ea4d02b899dde9d3e4e479319e05bd34845a57d26165d633ff01f5`.
User live `FXDM` returned the eight documented methods; corrected `FXCV` showed
only enable/show-UI and new-instance reset, then `FXCV DONE`. The original helper
macro concatenated nil help and caused its own 12:27:14 RunScript error. It was
acknowledged and corrected; scratch checks cover nil help/nil command and the
user's corrected query succeeded. No addon runtime edit or setting change.
Separate user reports at 11:45:22 (durationSeconds:929) and 11:45:26
(specIconID:535) remain native taint evidence. Inventory after a reload request
is not an explicit loaded fingerprint or error-clean acceptance. The 30-second
background read-only attempt at 11:25:15 UTC was refused before the first posted
message and zero characters were typed. Native cleanup/combat checks remain pending.
The user explicitly chose every native feature preserved and automatic Current
left blocked. Its implementation is frozen; no substitute/manual setup completion,
writer/reset or new experiment. Concurrent glow state preserved.
[Scope](METER_STANDALONE.md#automatic-current-requirement-and-supported-api-gap), [source audit](validation/meter-automatic-current-capability-2026-11-06.json).

6 November supported-route audit: main was clean at
`d4a45fbdc63229074af97853d7ec871cbb857162`. External
Meter-supported-current-audit-20261106T110157Z preserves 1,595 actual sources,
177 settings files and all-ref history; ZIP and bundle checks pass. Source archive
SHA256: `c6f2d2a58c8c226c42e7e16f3e486e714a612d406edd47a76953cf50ba860e50`.
Fresh Forever 70790 and Retail 70783 source at the pinned commits matched the
prior audit. Native owner/factory defaults are Overall; public DamageMeter APIs,
Edit Mode fields, Advanced Options and XML supply no Current default/setter.
The native session menu calls the already rejected private setter. An owned
Current renderer cannot promise combat source drilldown with the audited GUID/
query restrictions. Automatic Current for every existing/future pane remains
OPEN; manual selection is not completion. No runtime edit or new experiment.
Passive captures at 11:02:01 and 11:06:07 UTC found Forever PID 37088/window
341447356 and host executable 70790, with game foreground. The guarded reload
wait expired before any input or completed command. Loaded identity, cleanup and
combat/two-fight acceptance remain pending. No settings, profiler or hardware
changes. Concurrent glow state preserved. [Audit](validation/meter-automatic-current-capability-2026-11-06.json).

6 November real-client Current experiment rejected: user output showed pane/
owner/saved1/1/1, changed-field metadata true to false and pane/owner _FluxUI.
BugTabs reported2/2; delayed ordinary native specIconID:535/durationSeconds:929
errors at11:20 prove the route taints native state despite desktop guard passes.
Removed operative test/preflight/securecallmethod block. Both preserved slash
commands are now read-only UNSUPPORTED; no further native experiments. Safe
backend normalized SHA256 `c093068e4e1409f87684e2911ad8cf30874feba89222c8d591bb9ba184e74788`
is byte-equal in all five client copies. 126 no-operation/provenance, 561 ownership
and Core focused checks pass. Safe full 166 scripts / 823 syntax checks passes, unchanged
source hashes/membership, corpus `826008fbce898c35a480e1f3752b1bb86e0eb59e71ecfad0d4c8247d369a8039`.
[Safe manifest](validation/meter-rejected-current-removal-2026-11-06.json). Capture-only at 10:36:31Z verified
Forever PID37088/window/Meter visible; a later reload guard refused before any
input because the game was foreground. No agent reload or memory cleanup pass.
Earlier166/823 experiment remains historical/rejected evidence. Reload must
clear retained native objects before fresh acceptance; no settings/history reset.
Use native OOC session selector immediately left of the cog in each header, then Current, not Advanced AutoReset.
Default Current every existing/future meter remains OPEN/unsupported. Preserve
concurrent glow work. [Decisive native record](validation/meter-current-live-checks-2026-11-06.json).

6 November final header and Current probe: header172/threat87 checks pass five
alternating pairs/ten rejected mutants. The earlier heading144/87 five-pair/
eight-mutant report is retained as its own source stage. Full166scripts/823syntax
passes with unchanged source hashes/membership, corpus
`d53d2e5e0c0390aa18ba620a9ab30e713b221b6b952db16060a2feca9eb085ba`.
Title left anchors/baselines are retained; timer uses public heading width and
remaining menu-bounded space. Header controls/art fit14 display units; embedded
Minimize is hidden/excluded and original native geometry/visibility restores.
The user's later explicit status paste still shows Damage+Healing Overall,
superseding the earlier Current reply. Default Current for all existing/future
meters remains OPEN. Implemented only a separately user-invoked, build/OOC/
provenance-guarded one-view native Current experiment plus read-only status.
127 probe/provenance and 561 ownership checks pass; requested native output is
pending, no automatic default/history reset. Scratch ForceTaint_Strong metadata
is not proof of ordinary addon call permission and changed no native config.
Passive08:31 capture showed Advanced Options/new-instance reset, not two-fight
acceptance; later09:57 capture showed town/Map/bags without probe output. No
extra UI input or agent-initiated reload. Prior misclick and process-visibility
correction remain preserved. External T084055 checkpoint preserves1,586 sources /
177 settings/all-ref history. Concurrent glow work is included in the captured
full source manifest and remains preserved. [Manifest](validation/meter-current-selection-probe-2026-11-06.json),
[header pairs](validation/meter-header-controls-comparison-2026-11-06.json).

6 November Forever SAO follow-up: the user tested the prepared Classic LBG
candidate and still saw button glow only after combat. They requested the
button glow to start with the screen overlay and use modern Retail art. Added
Forever-only immediate combat paint for mapped screen, generic SAO button and
native glow events; pre-acquired Retail LCG ProcGlow frame OOC; retained
Classic fallback. Added a compact diagnostic readout and focused tests.
Desktop checks passed; native result, taint and performance are pending.

The user's next in-combat diagnostic reported `screen=0/0`, `modern=158/0/0`
and no button glow. The first diagnostic command had failed inside its readout;
the simplified readout worked after reload. The screen hook is therefore not
the live signal on this client. Added the global SAO overlay-frame state as a
combat-readable source, one coalesced next-frame aura check and registration
fallback; changed the modern frame to stay shown at zero alpha between procs.
Focused checks pass; a new live test is pending.

The global-frame/alpha candidate also failed in the user's next combat test.
Readout: `screen=0/0 notify=330 modern=158/0/0 failed=0 classic=0 aura=7/1
frame=334`. Aura event dispatch and frame access are present; no button show
was attempted. Requested the live SAO overlay keys, `Want(5143)` and bar
matching counters during the proc before changing the association again.

Live check returned `want5143=0`, no SAO `overlaysInUse` keys. Inspected the
installed SAO native event handlers and Forever source-pinned event payloads.
Connected native screen show/hide to the mapped Arcane Missiles button and
fixed an empty-list state override. Focused fixture covers native 400589,
base/ranked spell IDs and hide; 20 signal checks pass. Native retest pending.

Native-event retest failed: `screen=0/1`, `native=0/15/0`, `aura=1/0`,
`modern=158/0/0`, `want5143=0`, `bars=0/342/0/0`. Installed SAO's Forever
secret overlays use Blizzard AuraContainer, bypassing earlier show paths.
First private-table AuraButton hook candidate also failed live with
`container=0/0/0`. Inspected Forever Blizzard slot registry; the latest code
finds the mapped 400589 AuraButtons through the global AuraContainer even
when SAO's private table cannot be captured. Twelve focused tests pass;
native acceptance pending.

6 November heading follow-up: the user confirmed both native meters now use
Current through Blizzard UI, then specified the timer immediately right of each
window title with titles unmoved. Current setup is user-confirmed; no agent enum,
two-fight or reload acceptance is claimed. No global/history reset was performed.
The08:26 live Threat view showed centered heading/clipped timer, motivating a
placement correction using public heading width out of combat and unchanged
title left anchor/baseline. Revised source/tests are still being finalized.
Earlier134skin/85threat/full162/819 results retain their pre-heading scope.
Concurrent glow work and latest user choices remain preserved.

6 November Forever combat glow follow-up: user specified action bar button
glows in combat and confirmed SAO's Missile Barrage screen overlay appears.
Verified installed SAO 2.8.9's show/hide functions, Era/Forever LBG artwork and
18 matching animation setup calls, and the current Forever process/window
(PID 37088, `F:\World of Warcraft\_forever_\Wow.exe`). Before edits, placed
Glow.lua, test, private settings and verified main-history bundle in a dated
external checkpoint. Hooked SAO screen activation after the original for the
missing Forever Arcane Missiles association; secret or unreadable combat icon
data no longer rejects a known spell face. General SAO/native triggers and
Classic-style LBG paint remain. The user reloaded and retested that first
candidate: no button glow in combat, then glow after combat if the proc
remained. SAO calls cached methods on its private table, so the global-name
hook missed them; the corrected candidate hooks those methods. Standalone
EBS buttons also lacked a glow-change subscription, now routed through the
existing `ebs.glow` eval lane. The user retested that private-table candidate:
still no combat glow, followed by a glow that remained after the proc ended.
Added lower-level global `ShowOverlay`/`TerminateOverlay` post-hooks, which do
not require private SAO capture, and live SAO overlay/fade checks to prevent a
stale marker. The user's next live retest still had no combat glow. Flux's
secure Hosts code forbids first combat child/anchor creation; LBG did exactly
that on first proc. Prepared and retained each LBG frame during OOC button
installation, so combat activation and removal play existing Classic animations
without LBG CreateFrame/SetParent/SetPoint. Prepared frames stay with their
button across paging, with skip-birth on the destination. Focused glow 53,
low-level combat signal 5 and EBS refresh 8
checks pass;
full desktop manifest
at [combat evidence](validation/forever-sao-combat-glow-2026-11-06.json).
The current run passes 164 scripts and 821 Lua syntax files; the saved HEAD
EBS.Init fails the new missing-listener assertion.
No window focus, input, reload or settings changes were made by Codex. The
user's first three native retests failed; the prepared-renderer candidate
combat/clear/visual/taint/FPS and
Era/Anniversary acceptance are pending.

6 November Threat timer/current-view follow-up: published main b6cb2c7 was
clean; external Meter-threat-timer-current-view-checkpoint-20261106T080249Z
preserves 1,579 actual sources /177 settings/all-ref history, archives/bundle PASS,
source SHA256 `403e098a8f63b1a6875e6eff2dc0ff9e5727c6bd8d97a89f497e4ae1fbcee8fd`.
Skin134/threat85 pass five alternating pairs/eight mutants; diagnostics42/
ownership561 pass five pairs/seven mutants. Full current suite passes 162 scripts /
819 syntax files with unchanged source hashes/membership, corpus
`d9a7742aeb101cc26b97d45274365f05831f2a599796628a8d396077499b000d`.
At08:05:58UTC two guarded read-only native commands found Forever70790, native
Damage+Healing Overall0, Details false, Meter active and BugTabs0. Reset-on-new-
instance1 is distinct from per-fight Current1. Three root click attempts were
refused before dispatch. One later attempt posted three targeted window messages
without activation/system input; it used stale menu coordinates despite a changed
stock layout. Later capture showed loading; no Current selection/setting was
verified. Input stopped; view-change cause is unknown. No automatic session
setter, reset, profiler preference change or foreground takeover was performed.
Correction: sandbox process isolation hid the live desktop client; the same
PID37088/window remained live. The earlier closed-client inference was wrong.
Raw historical reports/concurrent glow work remain preserved.
[Full manifest](validation/meter-threat-timer-current-view-2026-11-06.json), [native evidence](validation/meter-current-live-checks-2026-11-06.json).

6 November Forever SAO follow-up: user reported no Forever button glow after
the LibButtonGlow renderer change, with Missile Barrage as a reproducible proc
and all SAO-supported spells/procs in scope. Read installed SAO 2.8.9 Mage
definition and saved glow setting (`enabled=true`), plus Forever native glow and
aura API source. Dated external checkpoint holds pre-edit Glow.lua, private
settings and verified main bundle; no client process was running and no game
input or settings changed. Added a source-backed Missile Barrage aura to Arcane
Missiles rank-aware bridge, guarded secret native API/event values, and changed
player-aura refresh to fire only when that proc changes. Generic SAO/native
membership and bar/Extra/badge renderer remain shared. Focused 41 checks pass;
pre-edit Glow.lua fails the Missile Barrage assertion; full desktop suite passes
162 scripts and 819 Lua syntax files. Native proc, art, taint, frame-time and
Era/Anniversary regression remain pending. [Evidence](FOREVER_SAO_GLOW.md),
[manifest](validation/forever-sao-glow-followup-2026-11-06.json).

6 November native secret failures at 07:45/07:55 (specIconID) and 07:57
(durationSeconds) invalidate a blanket taint-safe claim for prior art/grid stages.
The current candidate keeps visual docking/native controls without
direct Lua data/configuration writers. Missing native pane types require explicit
native-control setup; selected sessions remain native, with no reset/data deletion.
Implemented one topmost/leftmost native timer using physical screen geometry,
original native time text/policy, out-of-combat header layout and combat alpha
election. Writer 26/timer 113 focused checks pass in five alternating pairs each;
5/9 mutants are rejected. Frozen source identities and raw samples are recorded
in [writer evidence](validation/meter-native-writer-comparison-2026-11-06.json) and
[timer evidence](validation/meter-single-timer-comparison-2026-11-06.json).
Final full validation passes 162 scripts /819 Lua syntax files with zero failures;
all 819 source hashes/membership remain unchanged (corpus
`5b008deec37a9e32ebf53442630c19012f9ce52a78ae0e7cc46e900552b2e377`).
[Current manifest](validation/meter-timer-native-boundary-2026-11-06.json). The first full run
failed four stale Core meter assertions; only the fixture contract was updated,
without restoring unsafe production setters. Older reports retain their scopes.
External Meter-timer-and-taint-checkpoint-20261106T072904Z preserves 1,571 actual
source files /177 settings/all-ref history, including concurrent raid/glow work;
ZIP/bundle PASS, source SHA256
`7dc36164c7a5abdd83e66e472990ebd560897fbd39ccc7d0aac6dd76c81d4205`.
At 07:31 UTC no WoW process remained; no controlled fresh reload or new live
candidate/taint/visual check ran. Native commands were not issued this turn.
[Boundary record](METER_STANDALONE.md#current-native-configuration-boundary).

6 November FOREVER-SAO-GLOW-01: verified main `a07c449`, the external
`FluxUI-forever-sao-20261106` source/history checkpoint, installed SAO 2.8.9
source hashes and read-only `glow.enabled=true` setting. Edited only the shared
Glow renderer and a focused fixture; preserved unrelated meter/raid work.
Saved pre-edit source fails the bar-render check; candidate passes 25 checks,
and Bars smoke passes 17,454 refresh checks. Full desktop validation: 819/819
Lua syntax, 160/162 scripts; the failures are in-progress meter Core smoke
and native skin assertions (neither script loads Glow.lua).
No native reload, gameplay, input, profiler or settings change. Native visual,
taint and performance acceptance pending. [Record](FOREVER_SAO_GLOW.md).

6 November raid secret mouse follow-up: user stack at 07:08:57 identifies
`Blizzard/Hide.lua:139`, reached from `FluxRaidLayout.lua:778` while hiding the
native grid. Baseline main `a07c449b1783a7bc876943e5909c3573cfec267a` is
present locally; the dated external Meter-texture-checkpoint-20261106T053635Z
and its verified source/history/settings identity remain recorded below.
On-disk Retail WTF Config.wtf and Flux-named settings were found read-only; no
settings were reset or copied into AddOns. Existing unrelated meter work is
preserved. [Forever 70790 source](https://github.com/Gethe/wow-ui-source/commit/eac30af597e5aaa43a60f6675ef5fdcea100375f)
and [Retail 70783 source](https://github.com/Gethe/wow-ui-source/commit/297d7aaaa736f346b3e036f38ee088eaf7f8c07f)
were checked on 6 November; the pinned Forever FrameScript documentation declares
`issecretvalue`, while SimpleScriptRegionAPI declares the mouse getters as bool.
The supplied native stack proves this particular getter can be secret in tainted
execution; declarations alone do not certify addon access or setter behavior.
The focused mouse fixture passes 2,545 checks across five modeled branches and
rejects 14 mutants; raid startup passes 2,073 assertions. Native secure VM,
hit testing, raid/party/combat/Edit Mode, visual and frame-time acceptance remain
pending. [Implementation and checks](49-native-mouse-suppression.md#raid-secret-mouse-follow-up).
Full desktop validation passes 159 scripts / 816 Lua syntax files with zero
failures; [current source manifest](validation/raid-secret-mouse-2026-11-06.json).
Normalized candidate `Blizzard/Hide.lua` SHA256 is
`901e468da994df71b907ebe51b19916410d6c09622c48212045356723711185b`.
The generated source indexes were refreshed and the read-only documentation
validator passes 849 sources / 14,101 local links. No WoW process was running;
native checks were not attempted.
During documentation refresh, the current uncommitted meter artwork candidate
exposed two stale standalone-threat test anchors (old 32-unit header geometry).
Only those assertions were reconciled to its existing 14-unit header; focused
threat now passes 70 checks. The historical 69-check meter reports below retain
their original source scope. No meter runtime behavior was changed in this batch.

6 November installed-art follow-up: clean main baseline
`a07c449b1783a7bc876943e5909c3573cfec267a`. Verified external checkpoint
Meter-texture-checkpoint-20261106T053635Z preserves 1,561 actual files, 175 settings
including Details and all-ref history; source SHA256
`345f0c8fd943cc0780635ef64a470c0c31f7dddc9898ac382cde22560db527ee`.
A helper initially targeted AddOns; its three verified archives were moved
outside before runtime edits, and mirrored copies were verified absent from all
five clients. No backup/private settings are included in Git.
Read-only inspection confirms Forever Details #Details.20261104.15400.172 and
the source nine-piece atlas/Ground/DGround/Accidental mapping. Code references
installed paths without running providers or copying files; fallback remains.
Final hashes, paired results and candidate native inspection are being recorded.
[Requirement](METER_STANDALONE.md#installed-wow-interface-art-references).

5 November one-line/shared appearance follow-up uses actual pre-style checkpoint
Mail-auction-publication-20261105T215820Z: 1,557 files /160 settings/all-ref history,
ZIP/bundle PASS; source SHA256
`d07305d83bef4f45d4e50ff45a8ace8f0c977f81db57d336fa1a1dba37c779ec`.
The user's multiword-wrap and differing-pane reports justify direct one-line
font layout and shared Friz/ArialN fills/header geometry. No native text values
are read; native data/controls/row pools and canvas scale remain.
Skin 54/threat 69 checks, five paired runs/eight mutants pass against that source.
Native-owner 463 checks pass versus 14 baseline failures, five pairs/five mutants.
All four configured panes paint in ordinary/gamepad fixtures; 1,000 native resets
per fixture restore both sessions, with no new frames/timers/content/policy writes.
The old 68-check integration fixture now checks unique physical window resources
and permanent entry hooks rather than treating paint-call count as ownership.
Final desktop validation passes 159 scripts / 816 Lua syntax files; all 816
source hashes and membership are unchanged across the run. [Full source](validation/meter-theme-consistency-2026-11-05.json). Guard SHA256:
`66cb6ac3bf32f8fb90cf2ca37cd0e0d86b8ef1fa6649a9760d8516b435b4d010`.
Raw font/tab-stage 159/816 and its exact hashes remain historical evidence.
After final native reload 22:06:45.511Z, Meter/builtin 7/profile 0/current BugTabs 0
were retained; Friz 15 titles/ArialN 17.5 rows and name/value wrap false/false were
observed and shared header/panel fill inspected. Final OOC native tab handoff passes; actual owned-threat combat rows were not captured, so combat secret/taint and performance remain inconclusive.
[Style pairs](validation/meter-shared-style-comparison-2026-11-05.json),
[native-background pairs](validation/native-meter-background-comparison-2026-11-05.json).

Final native OOC captures (UTC): reload22:06:45.511; Map22:08:39.557,
Respec22:08:58.688 and Buttons22:09:18.418 all report native=false/threat=false;
returnMeter22:09:39.197 reports true/true. Summary22:10:13.490 reports Flux loaded,
Details absent, currentBugTabs0 and Meter/builtin7/profile0. Validated target-window
background commands used no PC foreground, mouse, keyboard or clipboard control;
no profiling preference changed. [Native metadata](validation/native-meter-background-checks-2026-11-05.json).
Shared header/panel fills were visually inspected. Live owned-threat rows were
not captured during the short fight, only pre/post states; combat secret/taint,
matched pixel parity, memory and FPS remain inconclusive/unmeasured.

Earlier font/tab-stage evidence (its native pending notes are superseded by final OOC handoff above):

5 November threat font/quiet-state follow-up: baseline
`db42efb10efb0d39cf991dacc27db606000ad7b3`. Verified external checkpoint
Mail-auction-publication-20261105T213107Z preserves 1,554 actual files, 160 settings
and all-ref history; ZIP integrity and bundle verification pass. Source SHA256:
`a6ffa0fee4832870a4ba2dd20c3f6afc1c2363e8f787be4ed78e5bc2558b8132`.
Font-before-text corrects the exact construction error and permits later geometry
cleanup. Percentage-first readable ordering and combat-only rows match the
intended threat presentation. Focused 65 checks, five original matched pairs,
five font-ready reference pairs and nine rejected mutants pass.
[Raw comparison](validation/threat-font-readiness-comparison-2026-11-05.json).
Full desktop validation passes 159 scripts / 816 Lua syntax files; all 816
source hashes and membership are unchanged across the run.
[Full source manifest](validation/meter-threat-readiness-2026-11-05.json). Native acceptance for that earlier font/tab source was pending; final OOC handoff is recorded in the shared-theme stage above.
Native Forever 1.60.1/70790/interface16001, Details absent and scriptProfile 0 are
observed; Map reload/session FXERR0 and layout 8 construction are partial checks.
Current combat, pixel/taint and performance acceptance remain pending.
The native font-candidate pane constructs fully with ARIALN 15 OUTLINE. Normal
Map/Respec/Buttons handoff then reproduced native-hidden/threat-visible overlays.
Checkpoint Mail-auction-publication-20261105T215012Z preserves that actual font
candidate and records: 1,555 files, 160 settings and all-ref history; integrity PASS,
source SHA256: 6616a4f3a12864b60b2a999923631943cc0b3c313459834b0abdd6eaa7d60f08.
An explicit addon hidden latch now covers onHide-before-activeTab-update ordering.
The final owner regression passes 429 checks versus 19 failures; five alternating
pairs/four mutants reduce 4,000 threat/1,000 root resurrections and 1,000 mixed-Always
repair wakes to 0, with no frame growth/content walks/policy writes and native
timer dispatch retained. [Handoff pairs](validation/native-meter-tab-hide-comparison-2026-11-05.json).
Root and threat runtime SHA256s are 07acfae4ed9090c8e6226e140062e254cfef9ec8ca6fca64033ee71228750a8a
and 478d82e865a9b49ccf720e60b50b7aa66154c9eabd44c2f0ab41a4be268f7cc7.
Final 816-file source guard: 6147668476e15329af4ee536ea2c047296d74a7f9b225649520d948c549a2c32.
No shared skin or 112% canvas change is included; native post-fix handoff/combat
and performance results remain pending.

5 November standalone native meter: feature baseline
`8006494fd5f10b54818471933467b9bb867c6543`. External checkpoint
Mail-auction-publication-20261105T203228Z preserves 1,537 actual files, 122 on-disk
settings and all-ref history; source SHA256
`efe44322cd86f787161b91509af8f63cf4709fdfdeaef72e6f6f750c51b5a537`.
New shared skin and Forever-only independent threat view reuse existing services
and Flux/Blizzard assets. Existing native preset/default IDs remain; three opt-in
threat presets and a maximum three-native-plus-one-owned grid are added.

Final publication preparation: final runtime/manifest bytes match all five
synced client folders (7/7 each). External Meter-native-
settings-20261105T212227Z supplements recovery with 38 native meter/Edit Mode
tables and layout caches; ZIP integrity passes, SHA256
210a34953ed1a01433edd268ec9353d68a10b02d2fc17722e9dea516113b4c9a. Unsaved game
memory excluded. Existing validated wand/cast-bar work is preserved separately
as 92dfb49. These checks used no game input or settings mutation.

Skin 47 checks/five alternating pairs/six mutants pass. Standalone threat 51 and
coherent-sample 510 checks pass with five pairs/11 mutants. Shared sample queries
fall 1,000 to 500 per 500 rows. New skin/pane allocation is reported as feature cost;
500-event bursts coalesce one scan and 80 roster/pet facts remain intact.
[Skin samples](validation/meter-skin-comparison-2026-11-05.json),
[threat samples](validation/standalone-threat-comparison-2026-11-05.json).
Final desktop validation passes 159 scripts / 816 Lua syntax files; all 816
normalized source hashes and file membership match before/after the run.
[Final source manifest](validation/meter-standalone-2026-11-05.json).

The user's empty-tab checkbox diagnosis led to METER-ENABLE-01: native-backend
startup/tab/embed/Show may enable only the public damageMeterEnabled option out
of combat; native events and natural addon readiness remain native. No private
visibility/cache writes, native manual timer update or addon load was added.
Concurrent wand/cast-bar code and continuity entries are preserved separately.
Before the docking follow-up, external checkpoint
Mail-auction-publication-20261105T205512Z preserved all 1,549 current dirty files,
122 settings and all-ref history, source SHA256
`c01241bfe2564ab2baabaecd4023dd06c4c17193fb211e86b3f45e1276a24b32`.
METER-OWNERSHIP-01 now gates native panes before the first Embed;64 checks pass
versus 22 failures in actual T205512 source, five pairs/four mutants. Docking
repair uses native widget aliases, coalesced post-native geometry restoration
and deferred combat cleanup;60 checks pass versus 30 T205512 failures, five
pairs/11 mutants. The 500-burst test schedules one wake per plain/gamepad fixture;
fixture frames stay 4, addon snap writes 76 to 0, native callbacks 4,064 to 4,072.
This adds repair work, not a native performance gain; no extra type/session
setters or entry walks occur. The 22:04 CET user screenshot establishes the
pre-embed Map/floating failure, not the candidate's loaded identity.
[Startup comparison](validation/meter-startup-comparison-2026-11-05.json),
[docking comparison](validation/meter-reload-docking-comparison-2026-11-05.json).
Earlier 68-check feature/enable pairs retain their preDock source identity;
the final 816-file manifest covers the current runtime and all preserved user
changes, including separately committed wand/cast-bar work 92dfb49. Source guard
SHA256: 376815eacb8a9a89cb3cd8b306c482dab0601f73111cdc39dba5e61fcb947cec.
No new native input, reload, profiling or screenshot comparison occurred; all
combat/taint, art/font, frame-time and memory acceptance remains pending.
[Full feature scope](METER_STANDALONE.md).
One background-only capture at 21:56:22 CET verified the same Forever PID 39984
and an in-world Map tab. Meter docking was not visible; loaded code/build was
not queried. No focus/input/reload/profiler change occurred. This single view is
not meter, combat, pixel or performance acceptance.

5 November wand swing theme: started from main `72704d19` with an external
dated source/history bundle and read-only confirmation of Era, Anniversary and
Forever on-disk `Config.wtf`. Pinned Gethe commits `4192ac6`, `68e0a2e` and
`eac30af`. The shared cast renderer accepts an explicit wand-school mask; the
equipped ranged item supplies it from localized damage text, with cold-item
retry and unchanged-item caching. The ranged strip is a StatusBar and its
trough matches the player cast bar. Existing swing timing, cast priority and
settings remain. Focused 13,942-check desktop fixture and full validation
pass; native rendering, combat taint and matched performance remain pending.
[Source and exact identities](SWING_WAND_CAST_THEME.md).

5 November damage meter combat visibility: clean baseline
`72704d19cec2190495acb51d0ab82659e945d71a`. External verified checkpoint
Mail-auction-publication-20261105T202207Z preserves 1,534 actual files, 122
available on-disk settings and all-ref history. Source ZIP SHA256:
`10f43e0b24068defd30e84f170beeb1ab50537a14f7b4acd70c70296959cb946`.
Archive integrity and history verification passed; unsaved game memory excluded.

The user's 21:18:13 stack matches Forever's native secret-duration comparison at
line929. Flux's forced visibility field is read by the native combat event before
the timer traversal. The earlier mock omitted that initial field and traversal.
The follow-up removes the native policy write, checks native visibility before
showing, and retains the Flux host/tab boundary and native timer/entry methods.
Native visibility settings now govern the embedded meter instead of forced Always.
[Exact sources and regressions](METER_COMBAT_VISIBILITY.md).

Focused native-function replay passes 332 checks versus 80 baseline failures / 332.
Five alternating pairs per pinned Retail/Forever source (ten total) and six
rejected mutants pass; native event/timer/text-update counts remain unchanged.
Full desktop validation passes 153 scripts / 808 Lua syntax files; all 808 source
hashes and file membership match before/after the run.
[Full report](validation/meter-combat-visibility-2026-11-05.json).
No game input, foreground, profiling, settings or external addon changes were
used. Native combat/taint, pixels and performance remain pending on Retail and
Forever; other clients retain Details/capability absence. Prior native checks
predate this candidate and cannot establish its acceptance.

5 November minimap mail lifecycle and Retail tooltip readiness: baseline
`c1a5f901467ff5015938442c74580d6d4781cbaa`. Verified external checkpoint
Mail-auction-publication-20261105T194013Z preserves 1,529 actual files, 122
available on-disk settings files and all-ref Git history, including the pending
tooltip work. Source ZIP SHA256:
`a6fb41fd4042442bd9d9c6d5c70320fe9001feadd068312e3b328d0dfb694449`.
Archive integrity and history verification passed; unsaved game memory is
excluded. The minimap production-function replay reproduces 500 frames from
500 layouts and 1,024 from ten unchanged mail events. Reusing the named fallback
retains one frame without changing appearance, native preference or cadence.
Reload is required to discard previously accumulated frames.
[Minimap evidence](MINIMAP_MAIL_LIFECYCLE.md).
Focused 504 checks pass versus 100 failures / 494 baseline attempts; five alternating
pairs and five rejected mutants pass with identical resource counts.
[Raw comparison](validation/minimap-mail-lifecycle-comparison-2026-11-05.json).

The separate Retail tooltip guard passes 48 checks versus six baseline failures;
five alternating pairs reproduce 1,002→0 errors and four semantic mutants are
rejected. Existing active-row checks pass. Combined validation passes
153 scripts / 808 Lua syntax files with an unchanged
808-file source drift guard.
[Full report](validation/minimap-mail-lifecycle-2026-11-05.json),
[tooltip evidence](AUCTION_COLD_TOOLTIP.md).
No game input, foreground control, profiler/settings changes or external addon
edits occurred. Historical 19:15 Forever source/reload checks predate both changes.
Native transactions, flicker, pixels, taint and performance remain pending;
the user's whole-game freeze is not yet accepted as resolved.
Read-only host inspection around 19:45 UTC confirmed the same Forever PID39984;
both runtime candidates matched byte-for-byte in all five synced client folders.
Minimap SHA256 `448c762562c5bb2d62aeca43139d1ca5e42eb56b41ad86f4254caa34f78d670a`;
AlreadyKnown SHA256 `ee9042d3a8e3cb6dec70f7658b355b9595ce84b1e80803fbd81f97dd578db6f1`.
This is on-disk parity, not loaded-candidate or native operation acceptance.

5 November provider row reuse: baseline `7f47a566e573a132dcac4a0e67f8b590cee8d08a`,
Adapter SHA256 `d242e0c07e789197335bde1d0deb27586c41b6fad24560add6846452408df561`.
Verified checkpoint Mail-auction-publication-20261105T183839Z preserved 1,520
actual files, 122 on-disk settings and all-ref history, including newer consumable
work subsequently committed as `e2c6464`; source ZIP SHA256
`b3a39827bbd2e50cc271fce7c5930ea80b1174e3215bc42105b380d36523f55f`.
Only adapter `FillFromList` now reuses matching immutable rows in complete maps.
Focused candidate passes 700 checks; baseline fails 190 of 700. Five alternating
pairs and five rejected mutants pass. Per-region 500 appends construct
125,250→500 rows; source visits remain 250,500. Index-shifting cancellation
constructs 250,000→125,250, stable-suffix cancellation 250,000→500 and clears
250,000→0. Full validation passes 151 scripts / 806 syntax files; the complete
806-file source drift guard matched before/after. Independent review passed
700/210/365 checks and 13 extra edge cases.
[Raw pairs and source hashes](validation/provider-snapshot-row-reuse-comparison-2026-11-05.json),
[full report](validation/provider-snapshot-row-reuse-2026-11-05.json),
[tradeoffs and native steps](PROVIDER_SNAPSHOT_ROW_REUSE.md).

No new native input or profiler change was used for this adapter slice. The
approved Forever reload at 19:15 predates it; source Syndicator/profile0 and all
three loaded addons were subsequently verified with empty caches, without a
transaction test. The user-confirmed 19:18:25 logger error came from an incorrect
diagnostic API probe. Native acceptance remains pending. The private Syndicator
patch is still under review outside Git; installed external files are unmodified
and applying that proposal requires authorization under the read-only rule.

5 November Consumables timer: verified baseline `2c0e7b8`, external all-ref
history checkpoint and on-disk settings before editing. The old button and
config timer ran to full buff expiry after the item had become eligible at
the refresh threshold. Shared refresh deadline now drives button digits,
wisp swipe, and config cell swipe/digits. Five baseline/candidate pairs pass;
full worktree validation passes 150 scripts/805 Lua files. Native checks
pending. [Case record](CONSUMABLE_REFRESH_TIMER.md).

Preserved newer main commits for consumable visibility and bank charge iteration
through `2c0e7b8`. All then-current normalized Lua hashes/file membership match their
combined passing 149-script/804-Lua report; the earlier 147/802 snapshot result
is not relabelled. New external recovery Mail-auction-publication-20261105T183217Z
preserves 1,519 actual files, 122 settings and history including all pending work,
source SHA256 `eb8e2855cc54ad55cfa43a670b4b4d1957f0ffa6c3d6c424c8dbef3ba10d3557`.

5 November native stack follow-up: user trace at 19:19:57 identified
`FluxRestockList.lua:1307` calling missing `FluxRestock.Inv.Bank.ForEachSlot`
while the Consumables config grid queried charges. Verified baseline main
`d71f2b9`, external all-ref history checkpoint and on-disk settings. Switched
to the supported open-stack iterator with character/warband options. Five
baseline/candidate loaded-module pairs pass; full worktree validation passes
149 scripts/804 Lua files. Native fix confirmation pending.
[Case record](RESTOCK_CHARGE_BANK_ITERATOR.md).

5 November consumable config visibility: verified published main `437fda7`,
external all-ref bundle, worktree copy and four Retail/Forever on-disk settings
files before editing. Fixed deferred item save and button-first refresh in the
shared config. Five baseline/candidate desktop pairs pass eight checks each;
full validation passes 148 scripts and 803 Lua files. Native client checks
pending. [Case and hashes](CONSUMABLE_TARGET_DETECTION.md).

5 November renewed report: each Buy or Cancel adds lag to the next operation.
Added explicit operation-count and retained-resource curves to the flow scope;
source/provider audits continue separately from the validated snapshot batch.

Approved native check: Forever70790/interface16001, FluxUI/Syndicator/Baganator
all loaded, source Syndicator, profiler0. Candidate files byte-matched and reloaded
19:15:51 CET; source/marker/profile0 verified19:17. Mail/auction caches0/0 at19:18.
No transaction, profiler toggle or enable change. BugTabs1.4.9 owns capture;
an incorrect BugGrabber method query caused a probe error, not a runtime regression.
Previous foregrounds restored when changed; captures remain private. Transaction,
freeze, rendering, taint and leak acceptance remain pending.

5 November snapshot preparation, desktop validation complete: verified baseline
`437fda79136582282dde0f3989f3cb70c4411bad` and external checkpoint
Mail-auction-publication-20261105T173546Z (1,503 actual files, 122 on-disk settings,
verified all-ref history), source SHA256
`4921e61d4bce4f648bd95b428f7a0acea9eb11dfc99b0c66d1d5b32fd9a31f48`.
Moved built-in mail/auction snapshot preparation inside existing scan budgets,
with private completed maps and atomic publication. Consumer inspection supports
the intentional internal-map identity change; region objects, public Index APIs,
original equality/cadence and publication counts remain. Auction replay passes
5,884 checks versus baseline 144 failures in 5,436; peak metered work 5,216→104,
unchanged fingerprint visits 10,240→0, getter-reentry errors 20→0, publications
20→20. Mail replay passes 8,194 checks versus baseline 25 failures in 8,203.
Arrival normalization remains 1,600 records, with peak per-update constructors
1,600→46; five unchanged scans retain all 8,000 capture rows but fingerprint
fields fall 8,000→0 and normalization stays zero. A quantity change normalizes
1 record instead of 1,600; old-map clears fall 1,600→0 on that change and on the
last two money-only messages. Ten alternating pairs and eight rejected mutants
pass. Full validation passes 147 scripts / 802 Lua syntax files; all 802 current
normalized hashes match the manifest. Independent review accepted both sources
and reentry guards. [Raw comparisons and candidate hashes](validation/builtin-publication-comparison-2026-11-05.json),
[full report](validation/builtin-publication-2026-11-05.json).
No native freeze, latency, allocation-byte or FPS claim.
External Syndicator 289 cold-post callback/retry failure was reproduced read-only
and left unchanged; it does not explain unloaded-provider freezes. No game input,
profiling or enable-flag change was used. [Flow scope](MAIL_AUCTION_REWORK.md),
[mail preparation](BUILTIN_MAIL_PUBLICATION.md),
[auction preparation](BUILTIN_AUCTION_PUBLICATION.md),
[external evidence](EXTERNAL_SYNDICATOR_POSTING.md). Money-update cost inspection
is a separate read-only finding; no money-path runtime change was made.

5 November publication: ordinary push to main completed for runtime
`7a06b85f633d1945b7d6bf615636f486f3d7e627`, tree
`4e31f10131923c3d002faffe8036e631d1537402`; remote read-back matched and
the working tree was clean. All 800 Lua files match the tested manifest.
This final publication record changes documentation only. No native acceptance
is implied by publication or synced on-disk files.

5 November lifecycle follow-up: verified published main baseline
`e860ce6de499a7702b91e8a8d74f115fbc9e0293` and external checkpoint
Mail-auction-lifecycle-20261105T171132Z (1,496 actual files, 75 on-disk settings,
verified all-ref history), source SHA256
`38c16e1f0d1d928ffb6015a89ad10e78f991dc038d0d738f7d3483ace86a0e5e`.
Fixed duplicate/reentrant built-in auction queries and queries after provider
handoff, final-mail job cancellation and work after owning-module disable.
Auction candidate passes 628 checks; baseline fails 72 of 1,330 dynamic checks.
Duplicate queries 714→10, foreign-provider queries 700→0 and reentry queries
278→10. Mail candidate passes 880 checks; baseline fails 330. Disabled requests
90→0, disabled readiness reads 810→0 and missed final cancellation 20→0.
Ten alternating baseline/candidate pairs and eight rejected mutants pass;
full validation passes 145 scripts / 800 Lua syntax files. Counts are mocked operations, not native
latency or a freeze cure. [Raw comparisons](validation/mail-auction-lifecycle-comparison-2026-11-05.json),
[flow coverage](MAIL_AUCTION_REWORK.md), [queries](AUCTION_QUERY_OWNERSHIP.md),
[mail lifecycle](MAIL_JOB_LIFECYCLE.md).

Background host inspection found the prior PID47424 gone and Forever PID25172
started at 17:55 CET. Its candidate identity is unverified; the historical unloaded
probe still does not establish the state during reported freezes. No game input,
profiling or addon-enable mutations were used this batch. Preserve profile0 and
background operation. Native freeze attribution and all-client acceptance remain
pending. Prior three inventory fixes are already published in main `e860ce6`.

5 November built-in inventory phase: baseline `b664bb0b93ac566a34744aec5895e927a7a1ffff`
already committed/pushed to main contains the prior five contract fixes. Verified
external Builtin-inventory-20261105T152153Z checkpoint:1,488 actual files,75 on-disk
settings and all-ref history; source SHA256
`c2a7f2c073d38a90133cff6e5fc494164430338149ef65343ca61ab507ca537a`.
Added bounded/coalesced built-in item loading with late/unknown-slot ownership,
all-zero summary pruning and defensive modern currency termination. The final
corrected fixtures pass790/81/512 checks; five alternating pairs each (15 total)
and12 rejected mutants, plus full143 scripts /798 syntax checks, pass.
Modeled requests/waiters10,000→10, dirty marks/pulses10,200→20 and ambiguous retained
IDs10,020→20. Summary rows2,000→1, zero rows1,999→0 and visits1,999,000→5,998.
Repeated currency replies change13,000 queries/no completion to400 queries/200
completions; actual native bad replies remain unverified. These are desktop
counts, not native CPU, memory-byte, frame-time or freeze-removal measurements.
[Raw comparisons](validation/builtin-inventory-comparison-2026-11-05.json),
[full validation](validation/builtin-inventory-2026-11-05.json),
[item data](BUILTIN_ITEM_DATA.md), [summaries](INVENTORY_SUMMARY_PRUNING.md),
[currency](GOLD_CURRENCY_ITERATION.md).

Earlier native evidence: the user reports re-enabled FluxUI and continued whole-
game freezes on sold auctions, cancellation-to-mail, individual mail items and
Open All's second-last/final transition. The only verified active Forever process
was PID47424. At17:35 CET FXBUILD showed legacy/nil source revision/profile0 and
Syndicator false;17:37 FXLOADED was false/false, FXCLIENT1.60.1/70790/16001 and
FXGLOBALS nil/nil. The observed unloaded client conflicts with the reported
enabled state; final revision20261105.1 and all three changes are native-pending.
No addon flags were changed, no profiler1/heavy frame capture was repeated and
the previous foreground was restored. Private images remain outside Git.

Earlier published phase: the native mail-command guard prevents progression/completion
while C_Mail reports pending, with bounded8s wait and existing cadence retained.
Five matched desktop pairs reproduce360 to0 unsafe requests and40 to0 premature
completions; three mutants rejected. Final full validation:140 scripts /795 Lua
syntax files pass. Earlier139/794 evidence describes the preceding four-fix tree.
The user still reports live sale/mail freezes, including Open All at Processing
Message2 and final mail; no live cure is claimed.
[Guard, source contract and pending native checks](MAIL_NATIVE_COMMAND.md).

5 November follow-up: preserved clean main `8681672` in external
Raid-mail-followup-20261105T132922Z (1,476 actual source files, verified all-ref
history, 127 on-disk Flux settings files). Fixed incomplete raid readiness,
duplicate/stale mail wakes, hidden/disabled mail availability work and quadratic
progressive Syndicator auction rebuilds. Five alternating baseline/candidate
pairs per scenario repeat unchanged counts; 290 raid, 3,140 mail-worker, 380
mail-availability and 365 auction checks pass. Eight mutants are rejected; full
139 scripts / 794 Lua syntax checks pass. Read-only host inspection corrected
the sandbox-limited no-client inference and captured Forever without changing
foreground. Its saved UNKNOWN event predates baseline 868; the fresh user report
contains only reporter execution-limit warnings at 14:53:50, 15:03:09 and 15:27:44.
The user clarified Syndicator is not loaded in this failing runtime; installed
289 is reference evidence, not an enabled-addon observation. Built-in inventory
and the initial warning remain under investigation. No native lag/taint acceptance
is claimed. Approved Forever reload succeeded15:32:54CET; read-only commands confirmed
1.60.1/build70790/interface16001, FluxUI loaded, Syndicator unloaded, raid ready
and scriptProfile0 unchanged. No current-session errors printed at15:35:48.
Saved old history has reporter-only counter50; private four-file archive verified.
A split chat attempt activated shortcuts; atomic final commands succeeded and
restored the previous window. No controlled lag/combat/transaction pass claimed.
The user then confirmed the same freeze after reload. Optional scriptProfile1
reload completed15:41:45 and a 60s CPU capture began15:42:20; a reported crash
while opening many auction mails ended PID38964 and replacement PID33872 started
15:48:36. No new Errors/Logs crash report was found. Capture was lost before save,
so no benchmark was obtained. Restored scriptProfile0 plus reload15:50:55;
15:51:34 chat verified FLUXCLEANUP0 true false. Literal-only comparison against
the private archive preserved the original nil capture root. Previous foreground
restored; no profiling cleanup remains and the foreground exception is complete.
New external native-command-baseline checkpoint at14:53:38UTC preserves1,484
source files and verified settings ZIP; original Git history stays at8681672.
The next native command-pending guard is pending; the 139/794 count above covers
the completed four-fix batch only.
[Raw evidence](RAID_MAIL_AUCTION_FOLLOWUP.md) and
[native mail/auction source comparison](NATIVE_MAIL_AUCTION_REFERENCE.md).

5 November: read all 17 supplied errors (15 Forever icon warnings, two UNKNOWN
header blocks); preserved clean main aa253cc and all newer consumable work in
Meter-header-errors-20261105T125630Z (1,471 files, verified Git history, 127 on-disk
settings). Removed meter renderer interceptions and redundant geometry refreshes;
retained tint/layout. Fixed raid precreation visibility/capacity. Five alternating
pairs, 330 focused checks, five rejected mutants and full 136 scripts / 791 syntax
pass. Documentation passes 824 sources / 13,746 links after correcting a stale
command source line. No game input or settings/profiler change. Native warnings
and UNKNOWN attribution need post-reload acceptance.
[Source hashes, raw samples, tradeoffs and native steps](METER_RAID_NATIVE_OWNERSHIP.md).

5 November: verified main a6cc94d and closed Retail on-disk settings;
created/verified an external all-ref Git bundle and copied account/character
Flux settings outside AddOns. Fixed staff-restricted consumable targeting,
effective button counts, equipment refresh and tooltip explanation while
retaining restock's physical counts. Five fresh baseline/candidate pairs
reproduce/reject the wrong dagger target; 30 focused checks and full 134/789
desktop validation pass. No native interaction or profiler change.
[Source hashes, raw pairs, and native checks](CONSUMABLE_TARGET_DETECTION.md).

5 November: preserved clean main 2dd6cfd in external
Hidden-inventory-work-20261105T121000Z (1,462 files, verified history, 123 on-disk
settings). Reproduced hidden-parent protection/paint work; corrected filtering,
skin root discovery and final-layout reveal refresh. Five matched pairs stable;
260 Baganator / 65 default-bag checks pass, six mutants rejected. Initial core
smoke literal-call check failed after aliasing and was generalized; final 133
scripts / 788 syntax files pass. No native/input/settings/transaction control.
[Raw results and pending acceptance](HIDDEN_INVENTORY_WORK.md).

5 November Syndicator mail/auction snapshots: unchanged mail now compares
normalized records without sorted fingerprint strings; unchanged auction callbacks
retain records/count maps and skip FluxUI publication. Link-only mail metadata now
updates correctly. Five matched desktop pairs:500 sorts/500,000 string keys,
500,000 auction row replacements,500 maps and500 pulses become zero for the
synthetic unchanged burst.80 checks pass, three mutants rejected; full131 scripts/
786 syntax pass. Real changed lists still publish at the original cadence; native
Forever Baganator+Syndicator lag attribution/improvement remains pending.
[Evidence and next checks](MAIL_AUCTION_GUARDS.md#snapshot-change-checks).

5 November mail/auction safeguard: user reports Forever lag with Baganator840
and Syndicator289 on mailbox open/close, auction buying and sales; cannot run
native captures and requested safeguards. Resolved owned item-data completions
now notify consumers once, preserving explicit refreshes, incomplete metadata and
parser retries. Five desktop pairs: stable duplicate burst4,000 junk callbacks,
8,000 selector invalidations and2,000 Baganator timer creates/cancels become zero.
140 checks pass, three mutants rejected; full130 scripts/785 syntax pass.
Actual lag attribution/native improvement remains unverified.
[Evidence and remaining checks](MAIL_AUCTION_GUARDS.md).

5 November clarification: Forever retains Blizzard's ProfessionMicroButton.
Only FluxUI's custom trade-skill buttons, flyout and related options are disabled.
Removed the native-button exclusion/parking added in the preceding batch; the
normal discovery/configuration path restores it without a settings reset.
Adventure Guide remains hidden. Five matched desktop pairs: baseline2 failures
versus0 of54 checks; custom service startup frames remain unchanged (zero per
Forever model). Full129 scripts/784 syntax pass; native bar click/pixel/taint
acceptance remains pending after reload. [Evidence](17-micromenu.md#forever-native-profession-button-restored---5-november-2026).

5 November Forever trade-skill micro removal: the module now exits before
creating buttons/flyout frames or registering scans/events on Forever. The native
ProfessionMicroButton is excluded and parked through the existing micro menu
policy; trade-skill option controls are omitted only there. Saved profession
preferences remain stored; other clients and native profession access stay.
Focused48 checks pass (baseline10 failures); five matched pairs remove4 startup
frames per Forever model, with no startup event/timer work. Full129 scripts/784
Lua syntax pass. Native menu/config/pixel/taint confirmation pending after reload.
[Evidence](17-micromenu.md#forever-trade-skill-micro-removal---5-november-2026).

5 November Forever native bank and micro menu: at the user's request, Forever's
Blizzard bank is excluded from window movement, bank-frame latch scripts, bank
junk/item decoration and native restock-button attachment. Bank tracking remains
on existing BANKFRAME/PIM events; carried-bag and optional Baganator features stay.
The supplied PurchaseBankTab stack confirms a protected native first-tab path,
not the original taint writer. Guide button EJMicroButton is excluded only from
Forever's micro menu via the existing eligibility/parking paths. Focused checks:
168 native-bank and34 guide checks pass; baseline36/8 failures. Full129 scripts/
784 Lua syntax pass. Native bank opening/purchase/taint and guide pixels pending.
[Bank evidence](FOREVER_NATIVE_BANK.md); [micro menu](17-micromenu.md).

5 November Forever reputation click fix: the user confirmed the native
ToggleCharacter("ReputationFrame") call opens Reputation out of combat after
WoW's custom-script prompt. Both bars now call that API directly; the wrong
CharacterMicroButton overlays and Forever early return were removed for these
bars only. Combat guard, other client behavior, tooltips and other proxies remain.
Five desktop pairs: baseline18 failures versus0 of180 checks; full128 scripts/783
syntax pass. Final native bar clicks/taint/gamepad checks remain pending; no
/run macro or confirmation popup is introduced by the addon.
[Evidence and native checks](FOREVER_REPUTATION_CLICK.md).

5 November auction opening regression: the user's Retail stack showed Update
running before the ScrollBox view exists. Both modern highlighting variants now
check GetView before iterating; later initialized updates still paint normally.
The real delegate contract reproduces20 baseline failures versus0 of156 candidate
checks across five client/two provider labels. Five matched pairs retain600 active
visits/200 classifications; no new timers/events. Full127/782 passes; native
reopening and the original Buy spike remain pending.
[Reproduction and evidence](AUCTION_PURCHASE_REFRESH.md#view-initialization-regression).

## 2026-11-05 - auction metadata fan-out

Verified clean main at6d4ceba and dated external source/history/settings
checkpoint Auction-metadata-20261105T081044Z before runtime edits. Traced the
shared global item-data handlers and reproduced unnecessary bag/bank name
harvests, unsolicited session-cache growth and selector/junk invalidations.
Narrowed event ownership while preserving explicit API, cold retries, static
consumers and immediate reagent finalization. No external addon changed, game
input taken or profiler preference modified. Native Buy latency remains pending.

5 November auction metadata: global cache events no longer harvest all bag/bank
names or populate classification records for unrelated auction items. Requested
metadata, failed-load retry, static consumers, explicit completions and immediate
name-only reagent/restock updates are preserved. Five matched desktop pairs:
280,000 name reads and 2,000 container walks become zero for the unrelated burst;
230 checks pass, three mutants rejected; full 127 scripts/782 syntax pass.
The native Buy spike still needs attribution/acceptance across both providers.
[Evidence and next captures](AUCTION_METADATA_WORK.md).

## 2026-11-05 - auction refresh traversal

Verified external source/history/settings recovery at Auction-buy-20261105T075700Z
before edits on clean main24cffd22. Read external Syndicator289 read-only.
5 November auction Buy investigation: active-row highlighting uses the native
view instead of the retained child pool. Five matched desktop pairs:200,600
versus600 traversal visits;200 classifications unchanged;116 checks pass and
two mutants rejected. Full126/781 passes. Native Buy spike and every client/provider
integration remain pending. [Evidence and steps](AUCTION_PURCHASE_REFRESH.md).

## 2026-11-04 - Postal-like mail conveniences

Read repository continuity, Postal v4.3.4 and five local Blizzard mail source
mirrors. Verified a clean main at `1b319d19aa00fffa7e798a66d045e55902af6706`,
made a dated Git bundle outside AddOns, and privately copied 20 available
settings files outside AddOns while no WoW process was visible. The CurseForge
source page and installed license both say All Rights Reserved; no Postal code
was incorporated. The user chose direct UI implementation and explicitly
allowed use of FluxUI inventory services.

Added nine Flux-owned mail modules and an additive `FluxMailDB` root. The
Postal-shaped Open All button delegates to the native take APIs through a
single confirmed action worker; the native Open All button is restored when
the module is disabled. `GetInboxText` invoice is the fifth return, correcting
the outdated Postal assumption. Included category attachment, expiry action,
trade blocking with CVar restoration, module submenus, speed/free-slot options
and named profile snapshots. The full desktop runner passes 122 scripts and
777 Lua syntax files; the generated source inventory was rebuilt. No client
was launched or foregrounded, no game preference was changed, and no native
performance or taint result is claimed. Open requirements and client steps are in
[MAIL_INTEGRATION.md](MAIL_INTEGRATION.md).

User follow-up: the top and Open All dropdowns were not working as expected,
and Select reported completion while leaving attachments. Split the dropdowns
into two menu frames with level-specific routing; restored the Retail menu
button frame level and keep the custom Open All above native redraws. Fixed
the worker to scan all receive slots, including sparse high slots, retry
delayed item metadata, and report remaining mail. Added Shift range and Ctrl
sender selection. Rechecked local Blizzard dropdown/item APIs for Retail,
Forever, Era, Anniversary and MoP; desktop tests cover the shared paths but
native client behavior remains pending. The full 122-script/777-file suite
passes after the corrections.
The user then reported the top arrow still had no usable mouse hit area.
The button now explicitly enables mouse input, registers left-button release,
uses its exact 25x25 hit rect and sits above mail title/close chrome on every
client. The direct button click is covered by a focused desktop test. No WoW
process was visible for native pointer verification.

## 2026-11-04 - Era/Anniversary combined bank

The user requested a bank equivalent of Flux's combined bag, bank bag slot
visibility and purchases, then clarified that Baganator must own both views
when loaded and bank bag slot clicks must never toggle separate bags. Read
continuity/specs, checked the clean main tree, verified the dated external
source/history bundle and on-disk Era/Anniversary settings, and inspected
Gethe's loaded Vanilla/TBC bank paths. Added a ten-column bank window with
native item buttons, purchased bag contents, native slot row and purchase
footer; late Baganator handoff restores original native parents/scripts.
The user's subsequent native trace showed a newly equipped bank bag could
cause Blizzard `ContainerFrame_GenerateFrame` to anchor an item still hosted
by Flux. The opener now returns hosted buttons before opening missing bank
bags and rehosts them afterward. The full-slot state also hides the purchase
button and next-slot cost while retaining current gold. The bank restock button
now anchors beside the new window's bag slot row and returns to Baganator's
view on handoff. Focused Era and Anniversary models pass 33 checks each;
the full desktop suite and native status are in [evidence](CLASSIC_COMBINED_BANK.md).
Native visual, input, taint and performance acceptance remains pending.
Published the complete validated payload to main as
`410f32e3adb29addbe0380952f5caf0b99522bfd`; GitHub main readback matched.

## 2026-11-01 - dim passive equipped trinkets

The user clarified that a trinket without an on-use effect must be dim. The
previous fixture explicitly expected passive trinkets bright. Read current
continuity/source and on-disk settings; verified a dated external source/
history checkpoint and copied closed Retail config outside AddOns. Added a
passive check in the equipped-face paint path and updated the loaded-paint
fixture to distinguish passive, ready on-use and unusable on-use. Baseline
fails at passive; candidate passes 10 focused checks and the isolated
112-test/757-Lua desktop suite. Native acceptance pending.
[Evidence](TRINKET_EQUIPPED_USABILITY.md).

## 2026-10-31 - restore ready equipped trinket color

The user observed that equipped trinkets with a use effect stayed dark while
alive and off cooldown after the combat-grid tint update. Read continuity,
the shared painter and trinket owner; preserved ongoing unrelated chat and
cast work; inspected settings and verified a new external source/history and
closed-client settings checkpoint. The item painter now treats the trinket
menu's managed equipped face as owned without changing other macro faces.
The baseline fails the focused ready-trinket check; the candidate passes eight
trinket and 14 combat-grid checks. Isolated published-source desktop validation
passes 112 tests/757 Lua syntax files. Native acceptance remains pending.
[Evidence](TRINKET_EQUIPPED_USABILITY.md).

## 2026-10-31 - chat durability after teleport

The user reported that the character-button percentage disappears after a
teleport loading screen. The previous candidate scanned immediately on
`PLAYER_ENTERING_WORLD` and hid the label on a transient no-data return.
Checked main, the working tree, continuity records, the dated external
checkpoint's presence and current Retail WTF setting read-only before
editing; no setting override or user data was changed.

The painter now retains the last visible percentage through a bounded
world-entry data gap. Player inventory/equipment events or one 0.5-second
retry restore it; a final retry 1.5 seconds later hides it only if data is
still absent. Stale callbacks from an older world entry do no work. The
focused fixture covers event timing, repeated transitions, full/damaged/
empty/secret data; full 112-test/757-Lua desktop suite passes. Native
teleport, clicks, pixels, combat taint and matched frame time remain pending.
[Evidence](CHAT_CHARACTER_DURABILITY.md). WoW stayed in the background.

## 2026-10-31 - keep default cast appearance for inaccessible schools

The user clarified that item, channel, physical and other casts with no
accessible magic school should keep their default appearance. The earlier
neutral-effect candidate was removed before publication. A read-only audit
of Retail/Forever API declarations found no school in the never-secret
castBarID. The published nameplate channel code could boolean-test a secret
ID with `and/or`; explicit selection now lets the existing fallback run.
The new fixture fails on baseline by borrowing the adjacent empowered field,
then passes 56 nameplate checks with the fix. The shared renderer still passes
13,898 checks. Native secret, pixel, taint and frame-time checks pending.
[Evidence](SECRET_CHANNEL_FALLBACK.md).

## 2026-10-31 - chat character durability percentage

The user reported no percentage under the chat-frame character button. Main
was `0c197f5`; the working tree was initially clean. During inspection,
unrelated cast-bar source/test edits appeared; they were left untouched.
Read contribution/continuity/spec records and checked the dated external
29 October source/history/settings tree and current Retail WTF account
settings read-only. The external checkpoint `.git` was inaccessible to this
sandbox, while prior source/history verification is recorded in this log.
The current account settings have no explicit `chat_btn_durability` override.

The loaded painter hid the label at `lowest >= 100`. It now tracks whether
any equipped slot has readable durability and shows `100%` in that case,
while preserving the hidden state for empty/restricted data. Existing
events, slot scan, secure button, colors and settings remain. Source hashes,
focused cases and pending native checks are in
[CHAT_CHARACTER_DURABILITY.md](CHAT_CHARACTER_DURABILITY.md). The focused
test and full 112-test/757-Lua desktop suite pass; native client checks and
matched performance measurements remain pending. WoW and settings were not
controlled or changed. Regenerated source-derived reference pages and the
verification index from the current workspace; `validate_docs.py` passes
with 790 classified sources and 580 TOC/XML-reachable files.

## 2026-10-31 - lower nameplate cast-school backdrop artwork

The user reported school backdrop art appearing in front of Blizzard
nameplate chrome. Read continuity, current renderer and the read-only
Blizzard NamePlates XML; verified a dated external history/source and
four-settings checkpoint before edits. Moved only nameplate backdrop art
to a separate noninteractive plate-level host, with level reconciliation
while casts run. Unit-frame artwork and fill/edge/halo/particle ownership
remain as before. The focused regression fails on the baseline at the
backdrop-layer assertion and passes after correction; full desktop suite:
112 tests/757 Lua files. Native visual/taint/performance checks pending.
[Evidence](NAMEPLATE_BACKDROP_LAYER.md).

## 2026-10-31 - correct conjured combat-item usability tint

The user reported that mana gem and healthstone stayed bright when the other
combat grid items darkened on death, and asked for other unusable states to
work too. Read continuity and the combat-grid paint path, inspected on-disk
Retail settings, and verified a dated external Git history/source checkpoint.
WoW was closed. The shared paint path now honors death/ghost and reliable
live item usability for those two faces while preserving empty-charge and
loading-screen holds. The loaded-paint fixture fails on baseline and passes
14 candidate checks; full desktop validation passes 111 tests/756 Lua files.
Native tint, clicks, taint, pixels and performance remain pending.
[Evidence](COMBAT_GRID_CONJURED_USABILITY.md).

## 2026-10-31 - repair missing school fill and moving-tip tint

The user observed absent school color on all clients, no unit-frame cast fill
and an uncolored tip glow. Inspected the published renderer, Blizzard cast
source and existing options/tests; verified a fresh external source/history
bundle and copied four closed-client settings files outside AddOns. Restored
fill creation on `TimerBar`, hid/restored the underlying native nameplate fill
and tinted/restored the native Spark. Expanded the shared renderer regression;
it fails on the published source at the wrong fill parent and passes on the
candidate. Full desktop validation passes 110 scripts/755 syntax files.
Native pixels, combat taint and matched frame time remain pending.
[Evidence](CAST_SCHOOL_FILL_TIP_FIX.md).

## 2026-10-31 - school colors and effects on Blizzard nameplate cast bars

The user requested the same school visuals as target/focus on Retail, Forever,
Era and Anniversary nameplates while keeping Blizzard's own cast bar. Read
continuity, current unit/nameplate source and read-only Gethe client snapshots;
verified a dated external Git bundle and copied four closed-client settings
files outside AddOns before editing. Extended the shared renderer for a
Blizzard status bar with a Flux visual host, preserving native progress/text/
shield ownership. Added native nameplate-bar post-hooks and a default-on unit-frame
option. Secret/unknown spell identities fall back to native appearance.
Focused 48-check nameplate model and full 110-test/755-syntax desktop suite
pass. Native client pixels, combat taint and matched frame-time measurements
remain pending. [Evidence](NAMEPLATE_CASTBAR_SCHOOLS.md).

## 2026-10-30 - fix MicroMenu nil-center startup error

The user's stack shows Blizzard `GetEdgeButton` comparing nil centers during
`FluxMicroMenu:UpdateLayout()` after the LFG button starts a rebuild.
Reviewed continuity, on-disk Retail settings, the current code and read-only
Era Blizzard reference; verified the dated history bundle and preserved
pre-edit source/settings outside AddOns. Reordered selected/unused child
parking before native Show/Hide callbacks, with final hiding after layout.
The focused regression reproduces old ordering and passes after the fix;
MicroMenu smoke and full desktop validation pass (109 tests / 753 syntax
files). Native post-fix five-client checks remain pending. Other local work
was preserved. [Evidence](17-micromenu.md).

## 2026-10-30 - retain delayed loot source positions

The user reports lagged loot from mobs/chests arriving after the cursor moves
or another source opens. Read continuity and settings, verified the dated
external Git bundle, and preserved pre-edit source outside AddOns. Added
bounded pending sessions with captured item/currency/money identities and
per-source slot/chat reconciliation. The focused fixture checks two reversed
late item messages, a ten-second duplicate, an uncaptured fast-loot window,
late currency/money, and expired sessions. Full desktop validation passes
108 scripts / 752 Lua syntax files. Native five-client event order, pixels,
taint and frame time remain pending. Unrelated shared work was preserved.
[Evidence](LOOT_CURSOR.md).

## 2026-10-30 - keep loot alerts at the looting cursor position

The user reports that alerts should stay at the cursor's loot position when
the mouse moves. Read current source, continuity and on-disk settings;
verified the dated external history bundle and preserved pre-edit source
outside AddOns. Replaced per-alert shared-anchor movement with one origin
captured at loot-window start and retained per visible row. The focused
fixture covers cursor movement before delayed chat, LOOT_OPENED after
LOOT_READY, a second overlapping loot batch and after-close currency. Full
desktop validation passes 108 scripts / 752 Lua syntax files; exact
candidate hashes are recorded. Native event timing, pixels and frame time
remain pending on all five clients. Unrelated stance work was preserved.
[Evidence](LOOT_CURSOR.md).


## 2026-10-30 - exclude non-loot bag gains from cursor alerts

The user reports crafted and other incoming bag items as false loot alerts.
Read current source, continuity and on-disk Retail settings; verified a fresh
main-history bundle and preserved pre-edit loot source outside AddOns. The
chat fallback now accepts ordinary self-loot only near a loot window, plus
bonus rolls; crafted and pushed forms are excluded. Currency follows the
loot-window gate and currency slots cannot become item alerts. Direct slots,
won rolls, money formatting, defaults and fast pickup remain. Focused fixture
and full desktop validation pass (108 scripts / 752 Lua syntax files);
candidate hashes are recorded. Native classification and five-client checks
remain pending. Unrelated stance work was preserved. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - correct FluxLoot AceDB callback registration

The user's native stack showed CallbackHandler rejecting a table event name
at FluxLoot line 402. Read current source, continuity and present on-disk
settings; verified the external history bundle and preserved a dated external
pre-fix source archive. The focused test was tightened to CallbackHandler's
receiver/event/method signature and reproduced the old error. Corrected the
one registration call to match FluxOptions. Focused and full desktop checks
pass (107 scripts / 751 Lua syntax files); candidate hashes are recorded.
Native post-fix login and profile changes remain pending on five clients.
[Evidence](LOOT_CURSOR.md).


## 2026-10-30 - denomination art for cursor money alerts

Read current source, continuity and on-disk Retail settings; verified the
external Git bundle and preserved the uncommitted pre-edit loot source in a
dated external archive. Replaced generic money chat rows with localized
positive-amount parsing, white numbers and denomination coin art. The leading
icon switches at 1 silver and 1 gold. The focused fixture exercises both
thresholds, mixed amounts, plural grammar and rejected non-loot chat. Full
desktop validation passes 107 scripts / 751 Lua files; candidate hashes are
recorded. Native five-client pixels, locale, taint and performance remain
pending. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - cursor loot default follow-up

The user clarified on/on defaults across five clients and a visible
three-second disappearance setting. Verified the earlier external Git history
bundle, inspected present Retail saved variables and preserved the current
uncommitted loot source in a dated external archive before editing. Set the
Flux fast pickup default on, retained the cursor-alert and 3-second defaults,
and renamed the duration control. The focused fixture now loads actual
defaults, exercises the control and checks expiry. Full desktop validation:
107 scripts / 751 syntax files, zero failures. The exact runtime candidate
hashes are recorded; native acceptance remains pending. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - cursor loot and optional fast pickup

Verified clean main `b68f2545`, a dated external source/history bundle and
present on-disk Retail settings before edits. Inspected the installed
FasterLoot 20261016 and Looti 4.1.2 source/license read-only. Added Tools →
Loot controls, a three-row cursor display and optional LOOT_READY pickup.
The separate FasterLoot addon retains ownership while loaded. Focused mock
event checks pass; full desktop validation passes 107 scripts and 751 Lua
syntax files. Native loot, pixels, taint and performance remain pending for
all five clients. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - compare historical FluxUI default-settings route

Compared the linked GitHub main file and local Git history: both have the
same pre-fix Sticky Targeting routine. Read older on-disk FluxUI snapshots
without changing them; the 13 August pre-rewrite file used the registered
native negated setting on Retail. Preserved the current source and Git history
in another dated external checkpoint, then added a single-setting native
Controls route with CVar readback and raw fallback. The existing modern
Settings guard for raid/nameplate callbacks stays in force. Focused first-
load tests pass 76 checks. Native behavior and frame time remain pending.
[Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

## 2026-10-30 - Retail Sticky Targeting and camera audit follow-up

The user supplied native Retail readback `1.900000 / nil / 0` for camera
factor, engine maximum and `deselectOnClick`. Verified the current Gethe Live
Controls/setting source, inspected available on-disk settings and saved a dated
external source/history/settings checkpoint before edits. Added native sticky
CVar to the first-load table and audit, changed the no-maximum Retail camera
fallback to 2.6, and allowed one settings-only retry of an earlier failed
audit. Focused first-load fixture passes 68 checks; post-fix native execution
and performance remain pending because no WoW process/window was visible.
[Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

## 2026-10-30 - first-load nonbinding settings and chat output

Verified a dated external source/history checkpoint and inspected available
on-disk settings before edits. Moved first-account/new-character setting
passes from `PLAYER_LOGIN` to the first world-entry frame. Added a bounded
post-startup audit for supported CVars and setting packs, including Controls,
character nameplate values and Classic raid CVars. Removed progress and chat
class-color messages; manual reset categories now report completion once.
Focused first-load checks: 60; binding model: 507. Full desktop validation:
106 scripts and 748 Lua files. Native settings, reload scope, taint and frame
time remain pending. [Evidence](NONBINDING_FIRST_LOAD.md).

## 2026-10-30 - Hearthstone selector hover error

The user supplied a native stack trace at `FluxSmartHearthConfig.lua:491`:
hovering the Toy Box selector called a nil `GetItemInfo`. Preserved the current
local source, Git history and two on-disk WTF settings files in a third dated
external checkpoint while WoW was closed. The focused fixture reproduced the
hover failure with the deprecated global unavailable. Replaced the direct
call with the existing `Flux.Item.GetInfo` service and Toy Box name fallback.
The 19-check fixture and full 106-script/748-Lua desktop suite pass. Native
hover, toy choice, secure click, reload persistence and taint need recheck.
[Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - Hearthstone panel load-order follow-up

The user still did not see the Hearthstone panel beside Toy Box, unlike the
mount config. Read-only TOC inspection found Hearthstone loads at line 145
before `FLUX_API` exists at line 204. The previous fixture had injected
`FLUX_API`, masking the real early return. Preserved the current local tree
and Git history in a second dated external checkpoint and copied two current
on-disk WTF settings files there while WoW was closed. Then switched the
editor guard to the earlier `Flux.Cap.hasToyBox` and routed the default icon
through the existing resolver with the modern item API. The updated 17-check fixture
fails against the prior guard and passes with the fix. Full desktop validation
passes 106 scripts/748 Lua syntax files; native panel and toy use remain
pending. WoW stayed closed and settings were untouched.
[Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - Hearthstone Toy Box config window

The user could not use the Hearthstone config window on toy-collection clients
and needs to choose the Hearthstone toy. Started from clean main
`52659bd8d22559dc0943ddd999e681d84d705d8e`. Verified an external dated
source/history checkpoint; with WoW closed, copied two relevant on-disk WTF
files outside AddOns. The first diagnosis attributed the editor's early return
to `FLUX_API.hasToyBox` requiring a particular journal toggle. Removed that
unrelated gate and made the journal opener use modern or legacy load/show APIs.
The 14-check fixture missed the earlier TOC load-order defect, as documented
above. Native toy selection, actual secure click, reload persistence,
taint and frame time remain pending. No game input or settings changes.
[Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - atomic context-aware first-account bindings

The user reported exact native assignment/verification failure and asked for
all keys to clear, apply, verify and save in one pass. Used the dated external
`binding-native-failure-checkpoint-20261030` before edits. Source inspection
found false/nil return handling could reject a correct native action, and
Blizzard's Retail UI supplies per-action binding context that Flux omitted.
Updated the transaction to use context where available, retry only mismatches
up to three times, name unresolved keys, and save/load in one call. Updated the
five-client model for context-required writes, transient failure and nil
successful returns. Focused 507 checks, binding/respec 110 checks and full
105-script/747-Lua desktop suite pass. Process/window and WTF inspection did
not expose the user's open clients. WTF folders appeared transiently during
read-only inspection, including an Era account cache with 117 binding rows and
four bridge rows; that does not prove live state or post-change reload.
Mariosuper Era/Pandasans Retail native verification, taint and frame time
remain pending. [Evidence](BINDING_ATOMIC_CONTEXT.md).

## 2026-10-30 - native binding persistence rewrite

The user reported that first-load keybindings returned to game defaults after
reload. With WoW closed, the Retail account cache measured 29 bytes and only
one modified-click row; character bindings were empty, while SavedVariables
recorded account binding marker 5. Backed up these private settings, source,
tests and Git history outside AddOns. The early SaveBindings call in
ApplyCombatDefaultsPack was consistent with the empty cache, and marker 5 did
not prove a native save.

Replaced the binding pipeline with account-set selection, one preflight scan,
eight-write batches, template verification, SaveBindings/LoadBindings
round-trip verification, success-only version-6 completion and rollback on
failure. Removed the early SaveBindings; modified clicks now save only after
native bindings are available or with the full template. Added a one-time
version-5 empty-cache repair. Focused 501 checks across five client models
and full 105-script/747-Lua desktop validation pass; native acceptance and
performance remain pending. [Evidence](BINDING_PERSISTENCE_REWRITE.md).

## 2026-10-30 - stop full binding replay after reload

The user confirmed Flux prints the exact "Applying keybindings..." message
again after reload. Inspected all production call sites and on-disk account
metadata with WoW closed. Preserved the current source/test/history and
available Era account settings and binding cache in a dated external
checkpoint. The previous successful-save-only marker could remain pending
after a partial native write, authorizing another full reset next login.
Changed the automatic first-account pass to claim version 5 before its first
binding write, migrate old pending markers to consumed, skip when four native
Flux bridge bindings already exist, and ignore overlapping batch requests.
No-write missing registration can still start in the same login. Focused 544
checks across five client models, full 105-script/747-Lua suite pass; native
input and frame time remain pending. [Evidence](ACCOUNT_BINDINGS_ONCE.md).

## 2026-10-30 - account-only automatic keybindings

The user reports that the full keyboard reset still runs on character logins.
Read the linked DoctorFlux/FluxUI repository and local main history: its
original bootstrap was gated by the first-account defaults flag. Inspected
the closed Retail client read-only: the account binding cache has the four
reported bridge commands, while the newer completion table is empty.
Preserved current source/history and account settings in a dated external
checkpoint. Replaced per-character eligibility with one account-wide pending
state captured before account defaults are marked applied. Existing accounts
and prior successful character markers migrate without another reset. Removed
automatic keybind replays from Blizzard Settings reset callbacks. Focused
528-check five-client desktop model and full 105-script/747-Lua suite pass;
native key presses, persistence and frame time remain pending.
[Evidence](ACCOUNT_BINDINGS_ONCE.md).

## 2026-10-30 - one-time binding reset and frame pacing

The user clarified that the full binding setup should run once and requested
an optimized, lag-free path. Created a new external source/history checkpoint;
WoW was closed, and available account/character binding caches and Flux saved
settings were copied outside AddOns. Removed cross-login confirmation and
`UPDATE_BINDINGS` reset replay. A verified successful save now marks the
active scope complete; an earlier pending version-4 marker is accepted
without replay. Combined the registry preflight and clear-list collection
into one scan, and separated clear/apply/save across frames with at most
eight native binding writes per frame. The focused production test passes
521 checks across five modeled clients; native frame time remains pending.
[Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - full first-load binding reset

The user reported that bridge bindings were still never applied and requested
clearing all keys before setting the full template on every client. Read
continuity, development and binding specifications; preserved the current
source and history in an external dated checkpoint. WoW was closed; the
inspected Retail WTF tree had AddOns.txt files but no binding cache. Replaced
the missing-Flux-key seed with a one-time full active-set clear/apply for old
markers, with registration preflight, supported-command filtering, full
verification before save, late-binding event repair and version-4 cross-login
confirmation. Expanded the production-source test to 521 checks across five
client models and retained the 110-check binding/Respec regression. Full
105-script/747-Lua desktop suite passes. Native input, hotkey labels,
persistence, taint and timing remain pending.
[Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - full first-load binding reset

The user reported that bridge bindings were still never applied and requested
clearing all keys before setting the full template on every client. Read
continuity, development and binding specifications; preserved the current
source and history in an external dated checkpoint. WoW was closed; the
inspected Retail WTF tree had AddOns.txt files but no binding cache. Replaced
the missing-Flux-key seed with a one-time full active-set clear/apply for old
markers, with registration preflight, supported-command filtering, full
verification before save, late-binding event repair and version-4 cross-login
confirmation. Expanded the production-source test to 521 checks across five
client models and retained the 110-check binding/Respec regression. Full
105-script/747-Lua desktop suite passes. Native input, hotkey labels,
persistence, taint and timing remain pending.
[Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - grid binding persistence after reload

The user reported that first-load bridge keys did not stay bound after reload.
Found a path where the full first-account keybind batch resumed a queued seed
and finalized version 2 before its delayed verification. Created an external
dated source/history checkpoint and checked the local Gethe Settings binding
set loader. The post-batch/combat path now uses the same provisional and
delayed check as world entry. Version 3 waits for cross-login confirmation;
missing saved Flux commands get repaired and retried, while confirmed
intentional unbinds stay untouched. Focused 37-check simulated reload test
and full 105-script/747-Lua desktop validation pass. Native persistence,
secure clicks and hotkey labels remain pending.
[Evidence](DEFAULT_GRID_BINDINGS.md).

## 2026-10-30 - protected-client raid options

The user selected the taint guard after the native Blizzard raid settings
request. Checked Gethe's CUF profile callbacks and Interface Settings source,
created a dated external source/history checkpoint and checked available WTF
settings. Flux's existing raid options now remain authoritative for live
status text and power-bar chrome on Retail/Forever, and the preview uses the
same options for class colors, power, health text and auras. Classic retains
native reads; no native raid writes were added. Nine focused tests, raid
startup/aura smoke, Edit Mode safety and the full 105-script/747-Lua desktop
suite pass. Native appearance, Settings values, protected execution and
performance remain unverified. [Evidence](RAID_OWNED_SETTINGS.md).

## 2026-10-30 - protected-client raid options

The user selected the taint guard after the native Blizzard raid settings
request. Checked Gethe's CUF profile callbacks and Interface Settings source,
created a dated external source/history checkpoint and checked available WTF
settings. Flux's existing raid options now remain authoritative for live
status text and power-bar chrome on Retail/Forever, and the preview uses the
same options for class colors, power, health text and auras. Classic retains
native reads; no native raid writes were added. Nine focused tests, raid
startup/aura smoke, Edit Mode safety and the full 105-script/747-Lua desktop
suite pass. Native appearance, Settings values, protected execution and
performance remain unverified. [Evidence](RAID_OWNED_SETTINGS.md).

## 2026-10-30 - raid profile and nameplate defaults

The user reported that Blizzard raid power bars, class colors and frame size
did not apply, and requested nameplate size `2` instead of `3`. Read continuity,
the defaults writer and local Gethe source; verified main and on-disk settings
availability. Preserved the three affected sources and verified Git history in
an external dated checkpoint. No private settings or WoW process were changed.

The Classic raid profile helper previously returned success when no active
profile existed. It now keeps work pending, completes the full raid pack after
profile load and retries briefly after first world entry. Retail/Forever native
compact-frame callbacks remain excluded by the existing taint guard. Updated
both nameplate default tables to `2` and added a one-time old-`3` migration
that retains other sizes. Classic native frame size now applies even with Flux
raid frames enabled. Focused 15 checks, existing 363-check five-client
Edit Mode guard regression and full 104-script/746-Lua desktop validation pass.
Native all-client settings/taint/pixel checks remain pending.
[Evidence](RAID_NAMEPLATE_DEFAULTS.md).

## 2026-10-30 - same-login grid binding correction

The user reported the first repair required another reload, then that it was
not assigning the keys at all. Read current repository continuity and Gethe
binding-set source; inspected available on-disk settings read-only; preserved
the current candidate and verified Git history in a second external checkpoint.
The old path saved a completion marker at `PLAYER_LOGIN`, before later native
binding-set selection could be checked, and excluded Blizzard's stock `Y`
achievement action from smart mount replacement.

Moved the seed to first world entry, added a second in-login verification and
bounded retries, upgraded old markers to version `2`, and allowed stock `Y`.
After the user reported both grids' labels absent, traced the refresh to an
unused legacy button list and a sparse module array. The live EBS registry and
dense loaded-module list now refresh labels and secure click owners. Focused
29 binding and 7 hotkey checks and full 103-script/745-Lua desktop validation
pass. No WoW window or settings were controlled. Native first-load key clicks, labels and
combat/taint on each client remain pending. [Evidence](DEFAULT_GRID_BINDINGS.md).

## 2026-10-30 - missing default grid bindings

The user reported Hearthstone, teleport and mount grid keys missing after
first-login defaults, then confirmed those keys should be set by the defaults.
Read continuity and binding owners, preserved other working-tree changes and
made an external dated source/history checkpoint; its Git bundle verified.
Read-only Retail on-disk inspection found two binding caches, one with the four
reported Flux commands and one without; the target keys were unbound in the
latter. No account names, private settings or game state were exported.

Added a one-time, active-binding-set seed for missing Flux commands, preserving
custom target keys and alternate assignments. It queues behind bulk setup or
combat and refreshes the existing secure override owners. Focused 21 checks,
prior 42/110 defaults/binding checks and full 102-script/744-Lua desktop suite
pass. Native key clicks and all-client verification remain pending; no WoW
process, setting or profiler was controlled. [Source/evidence](DEFAULT_GRID_BINDINGS.md).

## 2026-10-30 - first-login defaults on new characters

Read repository rules, continuity, defaults/persistence specs and current
runtime. Preserved the large pre-existing working tree. Created an external
dated source/history checkpoint before runtime edits; verified its Git bundle
and confirmed 11 on-disk account WTF files were available. Read Gethe branch
versions for Live, Forever, Era, Anniversary and MoP and the Live Controls/CUF
source. No WoW process, settings, input or profiler was touched.

New-character setup now filters `FLUX_DEFAULTS` and nameplate bitfields by
client-reported character CVar scope. It keeps raid/chat setup and preserves
account CVars/bindings. First-account and new-character seen flags require their
respective setup to succeed; the new-character marker waits for its queued CVar
job. The focused regression passes 42 checks; binding regression passes 110.
At the user's direction, removed the
untracked obsolete `tests/minecraft_appearance.lua`; the fresh full suite then
passes 101 scripts/743 Lua syntax files. Generated source and verification
indexes were refreshed. Native all-client acceptance and performance remain
pending. See [the exact-source record](DEFAULTS_FIRST_LOGIN.md).

## 2026-10-30 — merchant chat coin denominations

User reported `Repaired for 3494236c` and requested denomination amounts with
gold/silver/copper symbols for all vendor chat. Read continuity and vendor specs;
preserved unrelated working-tree changes. Verified the dated external 1,307-file
source ZIP against its recorded SHA-256 and the complete Git bundle; Retail on-disk
settings were present. Changed the three merchant money chat paths to use explicit
coin textures and denomination math, retaining transaction accounting/messages.
Focused chat and vendor identity tests pass. Full desktop validation passes 100
scripts/741 Lua syntax files with zero failures. Native texture rendering is
pending; no client, settings, profiler or sync interaction.

## 2026-10-30 — scale follow-up: portrait and strip

User reported displaced 3D portrait and unit frame overlap with the action
strip. Preserved newer vehicle/durability and status-bar work. Before editing,
verified an external 1,307-file source ZIP and complete Git bundle plus presence
of on-disk Retail settings. Corrected portrait offset double scaling, converted
focus chat/aura coordinates, normalized strip top and player bottom anchor
across frame scales, and refreshed the model/camera only when scale changes.
Player and target also apply the corrected anchor on first creation.
Focused production tests pass 23 checks, including 50% and 135% strip clearance;
portrait camera control passes 1,191 checks. Full desktop suite passes 99
scripts/740 Lua syntax files. Native pixels, clicks, combat/taint and FPS
remain pending. No game, settings, profiler or sync interaction.

## 2026-10-30 — whole unit-frame scale

Read continuity, options and unit-frame requirements; preserved the concurrent
vehicle-seat changes. Baseline main `021b524893229fece34eff503a8ac1cf66388363`.
Verified a fresh dated external 1,303-file source archive and complete Git
history bundle, plus presence of on-disk Retail settings, before editing.
Added 50–200% shared player/target and independent focus scale controls to the
existing unit-frame scope/defaults. Root frames, satellites, detached chrome,
class resources and micro-menu target cap follow scale; combat uses the existing
deferred layout pass. The production-bridge regression passes 17 checks and
the full desktop validation report is linked in [the scale record](UNIT_FRAME_SCALE.md).
Native geometry, input, combat/taint, pixels and performance remain pending.
No game, settings, profiler or sync interaction.

After the user supplied a screenshot showing an unscaled border and overlap
with the action strip, traced the atlas border to its `UIParent` host. Matched
its effective scale to the unit root and added clearance when the player or
side-by-side target grows beyond 100%. The 100% Y anchor remains unchanged.
Full 98-script/739-Lua suite passes after the correction; native pixels and
click acceptance remain pending.

## 2026-10-30 — vehicle seat layout

Read continuity and QoL specifications on clean main `021b524893229fece34eff503a8ac1cf66388363`.
The dated external `Publish-unit-power-20261030T101822` source/history checkpoint
is recorded in the publication ledger; on-disk Retail WTF settings remain present.
Changed only the Flux-owned seat indicator: micro menu position 2 puts its top-left
at the screen corner; parent scale 0.7 reduces artwork and seat hit areas together.
Other menu positions keep the durability anchor. Combat deferral and native
stock-indicator ownership remain. Focused layout check and the original
97-script/738-Lua desktop suite passed. Native geometry/input/taint and client pixels pending.
No client, settings, profiler or sync interaction. Candidate source SHA-256
`5a460a55026dcc320a2308299028c908b939a5135d5098a890638e9d525dff83`.

User screenshot showed the frame still low. The first condition wrongly required
status position 2 as well; existing defaults use menu 2/status 3. Removed that
extra gate and expanded the regression to cover menu 2 with status 1, 2 and 3.
Focused regression passes. A 98-script/739-Lua suite passed, but parallel unit
frame edits changed source afterward and the documentation validator reports
their verification manifest stale. Native screenshot recheck remains pending.
Revised source SHA-256: `d55b22025caad3edbc96931fe9ae9681affb39c4105c1ad6cf9f1acb9820fd64`.

User clarified that top-left micro/status chrome must stay fixed, with vehicle
seats and equipment durability together below it. The durability owner now
reserves the scaled seat width and chooses the lower visible top-left chrome;
vehicle seats anchor to its left. Empty chrome starts the pair at the screen
top-left, with prior PvP clearance retained. Focused production-slice checks
cover menu only, status only, both, neither, PvP, load order and combat.
Full actual-file desktop validation passes 99 scripts/740 Lua syntax files;
generated source inventory and documentation validation pass. This includes
the preserved concurrent unit-frame scale changes; it does not establish
native rendering or input.
Candidate source SHA-256: seats `12bbd63adfdffc520a646be83ea9a36a888cf36d3029ce9bde3892270149c06d`;
status owner `8312374088485e5bbe9811f02960eda627e1163ff6412b6c1b38c83325c09b44`.
Native geometry, input, taint and pixels remain pending.

## 2026-10-30 — unit power visibility

Read the continuity/specification records; verified clean main
`058efb8192b537d73e7e1e7f1a7e6afe2fbde575`, the dated external
source/history/settings checkpoint and present on-disk Retail settings before
runtime edits. Inspected Gethe's `live` UI source and local client contracts.
Flux-owned main and raid frames now hide known zero-maximum power bars and let
health fill the inner region; power returns on capacity changes. After user
feedback that Live/Forever health still looked split, verified source annotations
and placed full-height health behind a power layer with native secret-safe alpha.
Raid combat reanchoring waits for regeneration. Existing
health-only satellites require no change. [Details](UNIT_POWER_VISIBILITY.md).
Follow-up: health text now follows full-height HP for absent/restricted power;
known positive power keeps the split-area text anchor. The Flux separator starts
transparent and follows max-power alpha. Verified the existing dated external
source/history/settings checkpoint still exists; Retail on-disk `Config.wtf`
changed outside this work and was not opened for writing.

Focused models pass. Full desktop validation passes 96 scripts / 737 Lua files.
Native checks across clients, secure combat, restricted values and pixels remain
pending. WoW remained in the background; no settings/profiler/diagnostic or
other addon state changed. Main contains uncommitted source, test and records.

## 2026-10-29 — teleport counts and interrupted casts

User confirms Retail interrupted teleport/portal lag and unwanted reagent-free
count. Read continuity/travel requirements, inspected clean main b45eb5e and
verified fresh external source/history/on-disk Retail settings before edits.
BUG-012/PERF-011 uses native count text, clears reagent-free legacy digits, stops
fabricating runes from opaque text, skips reagent construction for eligibility
and restores the host without popup/key rebuild. No settings/default/cadence or
other flyout-owner changes. [Exact identities/limits](TELEPORT_CAST_WORK.md).

527 assertions: baseline 14 failures, candidate zero. Three rejected mutations.
Five alternating desktop pairs: per 100 integrated casts, tooltip calls 2,000 -> 0
and popup rebuild boundaries 100 -> 0, zero variation. Full 95 scripts / 736 Lua
files pass. Native reported-hitch resolution/combat/taint/pixels and general
custom flyouts pending. WoW/profile/diagnostic/settings untouched; no foreground
input, sync job, commit or push. Existing history preserved.

## 2026-10-29 â€” audit baseline and first provider fix

Inspected actual main `7436820`, remote, manifests, tests, diagnostics, documentation
and supplied Word/Markdown plans/templates/specifications. Initial tracked tree was
clean; `new docs/` and sync log were untracked. No root/ancestor instructions existed.
Merged durable rules without modifying supplied documents. Read-only audits
covered all supplied specs, lifecycle ownership and installed clients/references.

Before repository edits, created and verified source ZIP (1,177 files), Git history
bundle and private settings ZIP (403 files), while no WoW process was running. See
`RECOVERY.md`. Created the current change branch; main was preserved.

Ran `python tests/run_validation.py --output docs/validation/modernization-baseline-2026-10-29.json`:
81 tests passed; 722 Lua syntax files, zero failures. Lua/luac 5.4.6, Python 3.10.6.
Existing historical P0 fixes remain regression controls, not reimplemented work.

Reproduced BUG-001 in real Store/Currency/Syndicator adapter code with native APIs
and unrelated regions mocked. Before editing runtime, added a focused test and
captured `lua tests/currency_provider_handoff.lua --measure` output: 150 checks,
50 failures. A 400-event burst after Ready reads builtin money 100 times, requests
300/400 redundant refreshes and overwrites provider money 999 with 654. Saved
standalone ledger was already protected by Store; the shared snapshot was not.

Added four provider guards and an ownership comment in Currency.lua. Preserved
the baseline source as a nonloaded `.txt` fixture with matching checkpoint hash.
Targeted candidate and existing late-inventory regression passed. Five alternating
baseline/candidate process pairs each exercised five capability models and five
400-event repetitions. Candidate passed 150 checks every invocation; all stale
read/request/generation counts became zero with zero range. Four shared-bus callbacks
remain subscribed; external update and standalone timing checks pass. Raw samples
and identities are in `validation/currency-provider-comparison-2026-10-29.json`.

Ran `python tests/run_validation.py --output docs/validation/modernization-candidate-2026-10-29.json --sync-docs`:
82 tests passed; 723 syntax files, zero failures. Independent diff review found no
actionable correctness defect and confirmed limits of the mocked evidence.
Runtime/test/fixture committed separately as `2a7de26052e1b9662deef1b606b5ec95ebefe3aa`,
tree `86ed71c06dc9bc2117fb60e30d5417976506912a`. Initial commit attempt found no Git
author configuration; retry used this repository's existing DoctorFlux name/noreply
address through command-only settings, without changing global/local config.

Created feature/options/default/command/integration inventory (1,384 rows, all 26
specs, 17 discrepancies), client/reference matrix, ownership/dependency/API maps,
prioritized implementation plan and performance protocol/results. Refreshed existing
generated references with `python -B docs/tools/build_reference.py`: 756 Lua/XML
sources, 577 reachable, 361 option definitions, 519 defaults. Corrected stale prose
about load order, OptionalDeps, provider timeout/global item wrappers and `/fluxui bliz`.
The generated diff includes previously stale references, not additional runtime work.

`python -B docs/tools/validate_docs.py` passed: 756 classified sources, 577 reachable,
361 setting definitions, 23 saved roots and 12,649 valid local links. All six CSV
ledger row shapes passed. All 723 current Lua files match the candidate manifest;
the 42 original supplied-package/log files match the recovery hashes byte-for-byte.
`git diff --check` passed. Generated/explanatory reference refresh is committed
separately from the new audit, continuity and preserved requirements package.
The later full staged check flags the supplied specs' intentional Markdown
two-space line breaks and their verbatim CSV copies. They are preserved; the
staged check passes with end-of-line whitespace excluded. No source normalization
was applied to the user's package to silence those warnings.

No native clients launched, no settings mutated, no reference addon copied or edited,
and no deploy/sync to another installation. Native visual/input/secure/taint/secret,
CPU, allocations, latency and frame-time/FPS acceptance remains pending. Larger
architecture/lifecycle migration is unfinished. Next investigation is event-dispatch
mutation and its actual consumers, with a separate baseline before any fix.

## 2026-10-29 continuation â€” deferred scans and mail completion

Resumed on `201bc83`; tracked tree was clean and only the original sync log was
untracked. Read instructions, status, decisions, ownership/performance records and
relevant inventory specs. Preserved verified checkpoints at 09:32 and 09:41 UTC
outside AddOns, including actual files, Git history and private WTF while WoW was
closed. Main stayed at `7436820` throughout.

Production event-dispatch replay confirmed skipped handlers under removal and
inconsistent same-event additions. Traced the real Ev alias through Context:
DisarmEvents is called only from Unsubscribe, with no production caller found.
Recorded the latent API issue and six reproducible sequences in
`EVENT_DISPATCH_AUDIT.md`; no shared dispatcher changes were justified for this batch.

Prioritized BUG-002 after reproducing real Store/Mail/Auctions/Adapter handoff:
queued/partial builtin scans overwrite external snapshots after Ready. Unchanged
provider mail fingerprints can leave that corruption in place. Verified all 723
previously tested Lua hashes before reusing the existing full baseline, captured
new focused baseline (210 checks/42 failures), then added execution-time ownership
checks and cancellation in the two StepScan callbacks. Mailbox/open state, retry
and standalone close behavior remain. Five alternating pairs report zero variation:
queued/partial mail reads 105/56 to zero, auctions 71/38 to zero, stale publication
one to zero. Existing inventory pipeline passes 1,732 checks; full candidate passes
83 scripts/724 syntax files. Runtime/test/fixtures committed as `05e9f79`.

Separately reproduced BUG-003 for SendMail and ReturnInboxItem using controlled
post-hooks/events and actual local Syndicator 288 API/Main.lua returned references.
Completion after Ready appended directly to provider-owned alt mail. Portable tests
model that verified contract without adding an external fixture dependency. The
next baseline verifies all 724 tested Lua hashes and preserves the current Mail
fixture. Focused baseline: 410 checks/8 failures. A single ownership condition now
routes stale completion through existing failure cleanup before destination lookup.
Five alternating pairs pass all 410 candidate checks; four success cases change
one provider lookup/foreign row append to zero. Each action's 100 standalone cycles
retain one frame, zero subscriptions and 50 valid credits before/after. Independent
reviews found no actionable issue. Committed separately as `ab4e658`.

Commands/results:

- `lua tests/deferred_inventory_handoff.lua`: 210 checks pass; baseline `--measure`
  with both retained fixture arguments reports 42 expected failures.
- `lua tests/pending_mail_provider_handoff.lua`: 410 checks pass; baseline with
  `--source tests/fixtures/pending_mail_provider_before.txt --measure` reports 8 failures.
- `lua Inventory/_tmp_inventorylag_smoke.lua`: 1,732 checks pass across seven models.
- `python tests/run_validation.py --output docs/validation/deferred-inventory-full-2026-10-29.json --sync-docs`:
  83 scripts and 724 syntax files pass, before BUG-003.
- `python tests/run_validation.py --output docs/validation/pending-mail-full-2026-10-29.json --sync-docs`:
  final 84 scripts and 725 syntax files pass. All final Lua bytes match its manifest.
- Matched samples and exact commands/source hashes are preserved in the deferred
  inventory and pending mail comparison JSONs; continuation-identities pins both
  commit/trees and final normalized corpus. Process durations are not native CPU/FPS.

Updated parity, ownership/API/dependency, client, plan, performance, continuity and
recovery records. No new abstraction, native API replacement, settings migration,
client deployment, push or merge. Original user package/log remains preserved.
Native visual/input/secure/taint/performance results remain pending. Next source
investigation is auction/guild/Void query/request work after Ready; it is currently
an unmeasured finding rather than a claimed fixed defect.

Final reference regeneration reports 758 classified sources/577 reachable;
`python -B docs/tools/validate_docs.py` passes with 361 settings, 23 saved roots and
12,685 valid local links. All six CSV ledgers have valid row shapes and all 725 Lua
hashes match final validation. The 41 supplied package files match the original
archive. The sync log grew to 142,774 bytes before this continuation (09:30:44 UTC);
it matches both new checkpoints and was left untouched/untracked. This explains the
initial final-preservation check's mismatch against the older 111,922-byte log;
no rollback or overwrite was performed. Whitespace checks pass with intentional
verbatim Markdown line breaks retained.

## 2026-10-29 continuation â€” Windows enable/disable (user excludes provider queries)

Resumed on `f1a3bc7`, same modernization branch, with only the original sync log
untracked. Read durable records, lifecycle/feature/API/client/performance records,
Windows requirements/options, actual Catalog/Engine/Init, existing tests and runner.
The user explicitly excluded auction, guild-bank and void callback investigation;
no runtime edits were made in those domains.

Before edits, created and hash-verified a fresh external checkpoint at 10:07:52 UTC:
1,219 actual source files, all Git refs/history, and 403 private settings files with
WoW closed. Rechecked all 725 Lua hashes against the previous passing full report
before reusing that baseline. Main remains `7436820`; no push/merge/deployment.

Production mover/options replay reproduced BUG-004/PERF-003: disabled startup still
runs catalog discovery and native attachment, Player Spells keeps polling, and the
public SetEnabled(false) leaves a scaling driver able to change saved scale.
Captured 220 checks/108 failures before editing. The two-file runtime diff gates
Scan by existing settings, hides/shows the panel watcher through Refresh and calls
Refresh for both public enable outcomes. Existing options setter already uses it.
No saved data migration, new framework or native API replacement.

Commands and evidence:

- `lua tests/window_mover_disabled.lua --baseline --measure`: 108 expected failures
  in 220 checks using retained pre-fix source fixtures. Initial baseline was captured
  from unchanged runtime before applying the fix. Measure mode deliberately exits 0.
- `lua tests/window_mover_disabled.lua`: 220 checks pass, including real options and
  module startup, event/delayed discovery, 100 enable/disable cycles, scale persistence,
  public disable during scaling and combat-deferred Apply.
- `lua WindowMover/_tmp_charactercombatsmoke.lua`: passes existing modeled Forever
  mouse/gamepad hook isolation and combat recovery controls.
- Five alternating fresh-process pairs: disabled-start discovery 24 to zero,
  resolution calls 2,546 to zero, hooks seven to zero. After enabled startup, 20
  disabled event scans/2,120 resolves and 100 polls in ten modeled seconds become
  zero. Public disable stops post-disable saved scale change and both update loops.
  Count ranges are zero; 100 cycles retain seven fixture frames/hooks and scale 1.2.
- `python tests/run_validation.py --output docs/validation/window-mover-full-2026-10-29.json --sync-docs`:
  85 scripts/726 syntax files, zero failures. These are desktop mocks, not native
  UI/secure/taint/secret/FPS acceptance. Process durations are advisory only.

Runtime/test/fixtures committed separately as `19c40a0c84212b24fdf221a9653a4116d32f9020`,
tree `92973edadfdd5ebfc5935621bc2b77f1e0655066`. Review of the small runtime diff
confirmed enabled geometry paths/restriction guards are unchanged.  Evidence/native steps are in
`WINDOW_MOVER_LIFECYCLE.md`; current baseline/candidate hashes and matched outputs
are pinned in `validation/window-mover-comparison-2026-10-29.json`.

Latest documentation validation passes: 759 classified sources, 577 reachable,
361 setting definitions, 23 SavedVariables roots and 12,704 local links. All six
CSV ledgers have valid row shapes (1,384 parity, 35 ownership, 18 API contracts,
eight client, 77 reference and 109 performance rows). All 726 current Lua hashes
match full validation; all 42 supplied package/log files match the fresh checkpoint.
Generated references were refreshed with the existing tools. Whitespace checks pass
with intentional verbatim Markdown hard breaks retained.

## 2026-10-29 â€” repository editorial cleanup

Baseline f57fc79; main unchanged. Before edits, verified a fresh external source,
history and private settings checkpoint at 10:19 UTC with WoW closed. Retired editor
plans, prompts/templates, original Word plan, old handoffs, ignored local backups
and sync log into that checkpoint. Replaced useful rules/tasks with conventional
contribution and development documentation. Retained all 26 specifications and the
Markdown implementation plan; three terminology edits preserve gameplay requirements.

Rewrote conversational comments in 39 Lua files across bars, binding, window/map,
extra buttons, inventory/restock, layout, menu, minimap, other helpers, Respec and
unit frames. Existing lexer comparison against recovered sources proves identical
non-comment tokens and exact string bytes for every changed Lua file. Data, licenses,
assets, saved roots, manifests and runtime behavior are preserved. Historical capture
numbers remain unchanged; only process descriptions/optional branch metadata changed.

Evidence: validation/comment-cleanup-tokens-2026-10-29.json. No new runtime benchmark
is needed for identical executable code; native acceptance remains at its prior status.

Final checks use `python tests/run_validation.py --output docs/validation/editorial-cleanup-full-2026-10-29.json --sync-docs`, the existing
reference builder and documentation validator. The final source manifest supersedes
intermediate reports made before the last inline comment edit. Libraries/assets/
manifests (318 files) and historical measurement values were byte/value checked;
38 retired original files match the external checkpoint. All six CSV ledgers retain
valid row shapes. Explicit development-tool markers are absent from actual addon
files outside Git; legitimate game labels/item names/local variables are retained.

Editorial validation completed: 85 desktop tests and 726 Lua syntax checks pass;
all current Lua hashes match the final report. Documentation validation passes
with 759 classified sources, 577 reachable files, 361 setting definitions,
23 SavedVariables roots and 12,709 local links. All six CSV ledgers are valid.
The final scope scan covers 1,195 actual files and finds zero development-tool
markers outside Git. Native acceptance retains its prior pending status.

## 2026-10-29 â€” queued merchant purchase identity

Resumed on 07b11ce with a clean working tree, same branch and main 7436820. Read
contribution/status/development/decision records, vendor ownership/performance
records, supplied vendor requirements, production seller/classifier/buyer and tests.
The auction, guild-bank and void-storage callback audits remain deferred.

Before edits, verified a fresh external checkpoint at 10:40:48 UTC: 1,195 source
files, Git history/refs and 403 private settings files while WoW was closed. Verified
all 726 previous Lua hashes before reusing the 85-script full baseline.

BUG-005 reproduction executes production FluxVendorBuy through public restock and
merchant event handlers. After the initial eight purchases, replacing slot 9 and
removing slot 10 causes wrong/empty purchases on the next bag pulse, even after the
index rebuild. Baseline: 660 checks/36 failures. Added one execution-time identity
condition using the existing resolver; no new service or settings change. Invalid
tasks leave the queue before purchase/accounting while valid trailing tasks continue.

Validation:

- `lua tests/vendor_slot_identity.lua --source tests/fixtures/vendor_buy_slot_before.txt --measure`:
  retained baseline records 36 expected failures; measure mode deliberately exits 0.
- `lua tests/vendor_slot_identity.lua`: all 660 checks pass. Four merchant API/identity
  models, manual/tier targets, pulses before/after index rebuild, same-pass changes,
  fresh request recovery, merchant close and stable 40-target queues are covered.
- `lua Inventory/Restock/Junk/_tmp_junksmoke.lua`: existing sale/protection/visual
  regression passes; no seller code changes.
- Five alternating process pairs: all 20 metric cases have zero count variation.
  Each changed tail goes from one wrong + one empty purchase to zero; valid trailing
  purchases remain two. Stable 40-item queues retain five passes/eight-call budget
  and one event frame; each valid purchase adds one ID or link identity read.
- `python tests/run_validation.py --output docs/validation/vendor-slot-full-2026-10-29.json --sync-docs`:
  86 scripts/727 syntax files, zero failures. Native screenshots/input/taint/security,
  resource costs, latency and FPS remain pending; fixture money is simulated.

Runtime/test/fixture committed as cdd752abd060588bc1602e880d997a60dd0b34a9, tree
d18478f458e670f18931c070a00d53a708387fee. Source review confirms only the invalid-task
condition/comment changed; purchase math/UI/defaults/restriction guards are preserved.
Evidence and exact native steps are in VENDOR_PURCHASE_IDENTITY.md. No new native
client run, settings mutation, deployment, push or main change.

Merchant identity documentation validation passes: 760 classified sources, 577
reachable files, 361 setting definitions, 23 SavedVariables roots and 12,733 local
links. All six ledgers have valid row shapes (1,384 parity, 35 ownership, 19 API,
eight client, 77 reference and 118 performance rows). All 727 Lua hashes match
the full report. Requirements/libraries/assets/manifests (346 files) match the fresh
checkpoint, and the development-tool marker scan remains clear outside Git.

## 2026-10-29 â€” finite merchant stock budget

Resumed on 0d05acc with a clean working tree, same branch and main 7436820. Read
contribution/development/status/decisions, vendor requirements/ownership/performance
records, production quantity/queue code and existing tests. Read-only local Blizzard
12.1.0.69283 merchant source and existing bulk-buy code confirm separate zero-stock
handling; no reference code/assets were copied. Deferred callback scope is unchanged.

Before edits, verified an external source/history/private-settings checkpoint at
10:54:48 UTC while WoW was closed. All 727 Lua hashes matched the prior 86-script
full report before baseline reuse. Extended the existing merchant harness instead
of creating another fixture framework; retained the pre-edit runtime as a nonloaded
source fixture. Baseline stock replay: 177 checks, 39 failures.

Changed ComputeRestockPurchaseQty to cap zero stock. RunBuyPass now reserves finite
submitted quantities on the existing shared index entry, preventing reuse within
and across passes/duplicate entries. The reservation is not native acknowledgement.
Settings, UI, cadence, unlimited/nil helper semantics and other affordability math
remain. Normal index refresh/new request can buy replenished stock.

Commands/results:

- `lua tests/vendor_slot_identity.lua --stock-only --source tests/fixtures/vendor_stock_before.txt --measure`:
  39 expected baseline failures; measure mode deliberately exits zero.
- `lua tests/vendor_slot_identity.lua --stock-only`: 177 checks pass.
- `lua tests/vendor_slot_identity.lua --identity-only`: original 660 checks pass.
- Default execution: 837 checks pass. Existing junk smoke passes.
- Five alternating fresh-process pairs: all 20 metric cases have zero count range.
  Zero-stock rejection calls 5 to zero; finite stock 3/max stack 2 rejections 4 to zero,
  actual units 2 to 3 and accounted/actual copper 50/10 to 15/15. Across-pass stock
  rejection calls 2 to zero; unlimited 40 purchases/five passes and one event frame
  remain. No extra merchant-info reads. Money values are simulated, not native losses.
- `python tests/run_validation.py --output docs/validation/vendor-stock-full-2026-10-29.json --sync-docs`:
  86 scripts/727 syntax files, zero failures. Native screenshots/input/taint/security,
  CPU/resources/latency/frame times/FPS remain pending; no speedup is claimed.

Runtime/test/fixture committed as b505bb880aeefbab414d957d8d7fbee6820c20a8, tree
cc067974b724c82188d52f24a9800ad485ca261e. Small runtime diff reviewed for ownership,
negative/nil sentinels and shared-entry capacity. Evidence/native steps are in
VENDOR_STOCK_BUDGET.md. No settings mutation, client deployment, push or main change.

Finite-stock documentation validation passes: 760 classified sources, 577
reachable files, 361 setting definitions, 23 SavedVariables roots and 12,750 local
links. All six ledgers have valid row shapes (1,384 parity, 35 ownership, 20 API,
eight client, 77 reference and 129 performance rows). All 727 current Lua hashes
match the full report; requirements/libraries/assets/manifests (346 files) match
the checkpoint. The development-tool marker scan remains clear outside Git.

## 2026-10-29 â€” vendor-open junk availability

User reports lag simply opening a vendor on Classic Era and requests all-client
coverage. First/repeated-open behavior and automation settings are unknown. Kept
main and the deferred auction/guild-bank/void-storage callback scope unchanged.
Inspected current contribution/status/decision records and actual merchant/junk/
inventory source before editing. Preserved the clean 9e17e28 baseline at 11:14:06 UTC
in a verified external source/history/private-settings checkpoint with WoW closed.
All prior 727 Lua hashes matched the 86-script full report before baseline reuse.

Production availability calls repeatedly walked unchanged non-junk bags. BUG-007/
PERF-004 adds two scalar values to the existing junk owner, keyed by reliable bag
generation and cleared by existing rule/item/list/slot invalidation. Native-positive
precedence, cold gray fallback, unready retries, UI cadence and automation remain.
No new frames/hooks/timers/subscriptions/settings. The native hitch is not certified
fixed; other open-path work remains unmeasured.

Commands/results:

- `lua tests/vendor_open_work.lua --source tests/fixtures/vendor_open_junk_before.txt --measure`:
  265 checks, seven expected baseline failures; measure mode exits zero.
- `lua tests/vendor_open_work.lua`: all 265 checks pass across Era, Anniversary,
  modern Wrath Classic, Cata, Mists, Retail and Forever fixtures. Real buyer events,
  inventory/junk modules and extracted production UI availability callbacks run;
  rendering/layout/restock data/other integrations are modeled or excluded.
- Five alternating fresh-process pairs, all automation off: each legacy fixture's
  first-open slot reads 300 to 200; 25 unchanged reopens 5,000 to zero. Retail/Forever
  360 to 240 and 6,000 to zero. All counts have zero trial range. Buyer event frame
  remains one, native junk-count queries remain 182 on modern fixtures/zero legacy.
- Existing junk seller smoke passes; merchant stock/identity controls retain 837
  checks. `python tests/run_validation.py --output docs/validation/vendor-open-full-2026-10-29.json --sync-docs`:
  87 scripts/728 syntax files, no failures. Every current Lua hash matches the report.
- Native builds/settings/addon list, screenshots/input/combat/taint/secrets, CPU/
  memory/latency/frame times/FPS remain pending. Process timings include fixture
  startup and do not measure native vendor-open latency.

Runtime/test/nonloaded fixture: `e02139ab1c6b8099b02fb4506ff150a50d6555ef`, tree
`0a23a38a04809c0a087089586cb5842496fb5c64`. Focused evidence and exact native steps:
[VENDOR_OPEN_WORK.md](VENDOR_OPEN_WORK.md). No settings reset, deployment or push.

Vendor-open documentation validation passes: 761 classified sources, 577 reachable
files, 361 setting definitions, 23 SavedVariables roots and 12,769 local links. All
six ledgers have valid row shapes (1,384 parity, 35 ownership, 21 API, eight client,
77 reference and 157 performance rows). All 728 Lua hashes match the full report.
The checkpoint comparison finds no missing files and preserves 348 specification/
library/asset/manifest files byte-for-byte. Explicit development-tool markers remain
absent across 1,218 actual files outside Git. Legacy fixture labels share one API
route; Retail/Forever share another, rather than proving seven native contracts.

## 2026-10-29 — Quick Join anchor cycle

User supplied the native QuickJoinToastButton:SetPoint cycle at FluxChatFrame.lua
line 1248; client/build unspecified. Current branch was clean; main remained
7436820453d2248c84c99fff71507553efc47c19. Read current rules/records, chat options/
specification, both layout owners and existing tests. A fresh verified external
checkpoint at 11:47:07 UTC (12:47 Copenhagen) covers all 1,218 files, Git history
and 403 private settings files with WoW closed. All 728 baseline Lua hashes match
the previous full 87-script report.

The column anchors Channels below Quick Join. Its older social callback reverses
that dependency, reproducing the supplied failure. BUG-008 adds a six-line owner
guard when either button belongs to the column; the surrounding normal layout
still reconciles it. Native fallback, defaults/settings, dimensions, click scripts
and 0/0.1/1-second retry deadlines remain. No runtime hooks/timers/frames added.

Extended the existing column test with a cycle-aware parent/anchor graph and
bottom-point geometry, executing actual social and retry callbacks with the column.
Baseline passes the original 1,311 checks, then fails 448 of 508 ownership checks.
Candidate passes all 1,819, including four existing rejected mutations. Other chat
layout/startup/retry controls pass. Five alternating fresh-process pairs across
Live/Forever, both sides: cycle failures per three queued callbacks 3 to zero;
retry callbacks 3 to 3; burst frames zero to zero. Candidate reaches/reuses the
existing combat waiter that baseline exceptions prevent from being queued.

Commands: `lua tests/chat_column_layout.lua --source tests/fixtures/chat_quickjoin_before.txt --measure`,
`lua tests/chat_column_layout.lua`, `lua tests/idle_layout_retries.lua`,
`lua tests/chat_layout.lua`, `lua tests/chat_startup.lua`.
`python tests/run_validation.py --output docs/validation/chat-quickjoin-full-2026-10-29.json --sync-docs`:
87 scripts/728 syntax files pass. Measure mode deliberately exits zero for the
known failing baseline. Native rendering/input/security/CPU/resources/latency/frame
times/FPS remain pending; preventing an exception is not measured native speedup.

Runtime/test/nonloaded fixture: `5198ded001dde5bbc3fc5d6011239652cbe79dac`, tree
`ffeca6fce85ff9606c7dab3f38b065bdbfdfeb70`. [Evidence and native steps](CHAT_QUICKJOIN_ANCHOR.md).
No client sync/deployment, settings reset, main update or push. Vendor-open native
hitch confirmation remains pending; deferred callbacks remain outside this batch.

Chat-anchor documentation validation passes: 761 classified sources, 577 reachable
files, 361 setting definitions, 23 SavedVariables roots and 12,788 local links.
All six ledgers have valid row shapes (1,384 parity, 35 ownership, 22 API, eight
client, 77 reference and 173 performance rows). All 728 Lua hashes match the full
report. The fresh checkpoint comparison finds no missing files or unexpected
changes and preserves 348 specification/library/asset/manifest files byte-for-byte.
Explicit development-tool markers remain absent across 1,225 actual files outside
Git. Main remains unchanged; native acceptance remains pending.

## 2026-10-29 — repeated vendor tier work

Continued on the clean existing branch; main and deferred callback scope unchanged.
User clarified that the Era spike occurs on every same-vendor reopening. Read-only
Era hashes matched the earlier junk/buyer/chat fixes. Era Config.wtf saves
scriptProfile=1; active runtime state was not observed and no preference was changed.
Fresh verified external checkpoint at 12:04:44 UTC / 13:04 Copenhagen includes all
1,225 files, history and 403 private settings files with WoW closed. Verified all
728 baseline Lua hashes against the prior 87-script suite.

A blanket index skip would suppress consumable reference seeding. Instead, PERF-005
moves live usability after classification in two vendor tier loops, retaining
reference discovery, level/skill checks on matching contenders, thresholds, ties,
Well Fed/food-water rules, retries and UI timing. No new resources or caches.
Classification before level rejection can shift cold work; native cost remains
pending.

`lua tests/vendor_tier_work.lua --baseline --measure`: 340 checks, 12 expected
baseline failures; measure mode exits zero. Candidate passes 340. Actual production
buyer/index/post-index seed and Score/tier modules run with classification/native
facts modeled. Five alternating pairs cover legacy/modern APIs and 20/200 listings.
Large-vendor initial seed info/ownership lookups 1,000 to 10 each; separate status
2,000 to 20 each. After the cadence clarification, added 25 same-vendor reopens with
retained food/water refs and three unoffered families: 15,000 info and ownership
lookups each to zero (small vendor 1,500 each to zero). Classification counts remain;
all count ranges zero, buyer frame one and purchases zero. These are service calls,
not native CPU/cache misses or FPS.

Bag-tier controls pass 16,527 checks; merchant identity/stock 837 and junk availability
265. Final `python tests/run_validation.py --output docs/validation/vendor-tier-full-2026-10-29.json --sync-docs`:
88 scripts/729 syntax files pass. The final full run includes the repeated-open
extension. Native pixels/input/taint/security/CPU/memory/latency/frame times/FPS remain
pending. No sync/deployment/settings reset/push or main update.

Runtime `17628269f0e3b7fbeb1b8c2d7f9c7196829e67f3`, tree `0c681c46987fc5b136274bba59e5e5bb3dd90990`.
Repeated-open test carrier `e7ec46a4070c132ff8bf6033d6bef5e2c92f90aa`, tree
`4507ccd1456e42f9acdea0e2be4aaad073ff72ae`. [Evidence/native procedure](VENDOR_TIER_WORK.md).

Vendor-tier documentation validation passes: 762 classified sources, 577 reachable
files, 361 setting definitions, 23 SavedVariables roots and 12,807 local links.
All six ledgers have valid row shapes (1,384 parity, 35 ownership, 23 API, eight
client, 77 reference and 217 performance rows). All 729 current Lua hashes match
the full report. The fresh checkpoint comparison preserves 348 specification/
library/asset/manifest files byte-for-byte, with no missing files or unexpected
changes. Explicit development-tool markers remain absent across 1,234 actual files
outside Git. Main remains unchanged; native repeated-open acceptance is pending.

## 2026-10-29 — native Era vendor tier counts

Continued on the existing clean branch at d3bce5b; main stayed
7436820453d2248c84c99fff71507553efc47c19. Read current contribution rules,
requirements, diagnostics and affected tier sources/tests. Fresh verified external
checkpoint at 12:35:23.862522 UTC covers 1,234 actual files, history and 403 private
WTF files. Both clients were running: on-disk settings only, not a quiescent state.
Verified all 729 baseline Lua hashes against the prior complete report.

User authorized native vendor commands, then requested ordinary PC use with WoW
in the background. Clean foreground Era 1.15.9.70576 capture with four reopenings,
three automations temporarily off and profile=1 reproduces a 333 ms maximum UI
interval. GetRestockTargetItems: four calls / 1,281.123 inclusive ms; GetTierCount:
20 / 707.280 ms; cached-bank getter: 20 / 457.873 ms. 5,250 tooltip calls expose
unrelated live usability checks in those count loops. Earlier interrupted captures
are excluded; this one pilot is attribution, not five full-window matched pairs.

PERF-006 moves tier membership ahead of live usability in the existing two count
functions. Retains matching live gates, caches, quantities, inferior protection,
strict/loose bank semantics, vendor-first deduplication and live fallback. No new
runtime resources/settings; no auction, guild-bank or void callback edits.
Runtime/test/nonloaded fixture commit `013bf40db1d5b57c238ac3ac377e8ced98446fd1`,
tree `4f0d827bb26bba3ee8b20e21de891596fad0e98b`.

`lua tests/tier_count_work.lua --source tests/fixtures/tier_count_match_before.txt --measure`:
1,710 checks with ten expected baseline performance failures. Candidate passes all
1,710; five alternating fresh-process pairs reduce initial/repeated legacy live
checks 1,350/33,750 to 17/425; modern 1,500/37,500 to 18/450. Bank-store reads remain.
Existing tiers 16,527 checks, vendor tiers 340, stock/identity 837 and junk 265 pass.
Full `python tests/run_validation.py --output docs/validation/tier-count-full-2026-10-29.json --sync-docs`:
89 scripts, 730 syntax files, zero failures.

Native comparison continued without activating Era: original loaded references
versus exact source-derived local candidate count functions, one warm pass, query
cache invalidation and five alternating pairs. Median CPU per five kinds:
bags 132.199 -> 15.237 ms; cached bank 118.897 -> 22.517 ms. Tooltip calls 455 -> 5
and 450 -> 5. Quantities identical in every pair; personal-bank results all zero.
Native positive-bank/warband acceptance remains pending. Net memory deltas include
harness and GC and are not allocation measurements. No native API replaced.

Original three automation flags restored true, profiler preference remains 1;
temporary sampler/namespaces cleared by reload and diagnostic SavedVariable exports
removed. User's existing sync delivered candidate source, verified before reload.
WoW remains in the background; no further focus/input access. Full vendor after
latency, matched pixels/input, unprofiled FPS, cold work, taint/security and other
clients remain pending. [Evidence and exact steps](TIER_COUNT_WORK.md).

Tier-count documentation validation passes: 763 classified sources, 577 reachable,
361 setting definitions, 519 literal defaults, 23 saved roots and 12,824 local links.
Six ledgers have valid shapes: 1,384 parity, 35 ownership, 24 API, eight client,
77 reference, 242 performance. All 730 normalized Lua hashes match the full report;
raw/normalized candidate hashes match committed source and the native probe hash
matches the exported source-derived chunk. Checkpoint comparison preserves 361
specification/library/asset/manifest/XML files byte-for-byte, with no missing or
unexpected changes. Explicit development-tool markers remain absent across 1,244
actual files outside Git. Main unchanged; native after whole-vendor acceptance
remains pending. No additional foreground/game input used during final file work.


## 2026-10-29 — objective tracker first-module scroll gap

User screenshot shows Campaign below an empty gap while fully scrolled up; requested
Retail and Forever coverage. Baseline HEAD e1132d0948906acef72be9e4c28dff60a5736931
was clean. Verified external source/history checkpoint
`tracker-checkpoint-20261029T141542Z` preserves 1,244 actual files and all Git refs.
No settings modified; WoW remained in the background. Existing sync was left alone.

The supplied Retail native XML reserves topModulePadding=38; its OnLoad callback
captures Frame.Update before Flux hooks and directly invokes ContainerMixin.Update.
The previous container after-hook was Forever-only, so Retail restored the blank
header gap and bypassed scroll sync. Both clients now share that after-hook, with
a combat early return. Deferred sync repairs the first module before its unchanged-
height shortcut. Native padding/providers remain untouched. SizeScrollContent also
restores zero after a child-rectangle refresh, removing the positive-offset-only gate.

New tests/objective_tracker_scroll.lua replays the supplied native Retail/Forever
container and frame code, including the callback captured before hooks. Original
source: 11 failures among 40 checks; candidate: all 40 pass. Covers Campaign/Quests,
equal-height section replacement, overwritten anchors, wheel targets, preserved
scroll offsets, shortened lists, zero restoration and Questie ownership. Existing
combat and Questie smoke checks pass. Full validation: 90 scripts, 731 Lua syntax
files, zero failures in validation/objective-tracker-scroll-2026-10-29.json.
These are desktop dispatch/geometry results using reference trees; installed-client
rendering, secure execution and taint remain pending. No native performance claim.

## 2026-10-29 — whole-addon Retail performance and resource audit

Preserved the pre-existing uncommitted tracker correction/test/docs in a verified
external actual-file checkpoint at 14:39:06 UTC (15:39 Copenhagen): 1,246 files,
all Git history, 403 private on-disk WTF files while Retail ran. Verified all 731
baseline Lua hashes against the 90-script tracker report. Main unchanged.

Whole-addon ownership/recurring map covers 577 reachable files and 26 source
folders. Native Retail 12.1.5.70575/interface120105/project1, level81 Mage in
Stormwind, built-in inventory, three loaded addons, original profiler0. Five
20-second background profile1 captures after 30-second warm-up: median addon CPU
30.772 ms/s (30.107-37.046). All ten endpoints retain 14,742 total frames, 1,449
Flux-source frames, 458 visible, 212 registered OnUpdates and one shared subscriber;
eight sampled public cache sizes unchanged. Requested-capture memory grows after
GC; ordinary gameplay leak rate is not inferred. Nameplate/assistant CPU remains
for separate matched timing-preserving work. No foreground/mouse/clipboard control.

BUG-009/PERF-007 replay reproduces repeated readiness/combat frame allocations.
Runtime/test/fixture `6ac4389` reuses owners; five alternating desktop pairs reduce
203 frames to 3 with one hook/101 geometry writes unchanged. 2,050 checks pass,
20 baseline failures. Cleared requests disarm regen. Same timeout and six-pixel
anchor; native loot/combat trigger remains pending.

BUG-010/PERF-008 runtime/test/fixture `3046478` clears completed/cancelled full
capture snapshot and timer references. Five alternating desktop pairs retain
20 -> 0 full snapshots / 10,000 -> 0 frame rows per model; 400 checks after 200
baseline failures. Existing capture 383 checks/12 rejected mutations pass. The
full current actual-file suite passes 92 scripts/733 syntax files, including the
preserved pending tracker test. New runtime commits exclude that separate work.

Source checks find existing mirror-timer installation guards; corrected stale QoL
prose, with no duration runtime change. Binding/macro/spell/visual cache controls
retained; older inspect GUID TTL without eviction remains an unmeasured candidate.
Incomplete long-upload private native comparison was discarded after truncation;
no missing candidate result invented. Follow-up uses direct file-loaded capture
calls. Native foreground FPS/pixels/input/taint, long-session/private-cache churn,
other clients and full interaction acceptance remain pending. Excluded callbacks
untouched. [Detailed evidence](RETAIL_PERFORMANCE_AUDIT.md).

Native direct follow-up completed five actual file-loaded20-second profile1
captures. Post-GC addon memory24,105->24,928 KiB across retained reports versus
24,115->64,565 KiB before; median capture-associated delta186 versus7,860 KiB.
Endpoint gaps90-235sec versus22sec and changed camera/frame totals(14,588 versus
14,742) prevent strict gameplay/CPU/FPS causal acceptance. After CPU21.315 ms/s
median is context, not a claimed speedup. A later failed scripted export was also
discarded. Original profiler0 restored and temporary SavedVariable/namespaces
cleared by normal reload. WoW remains open in the background; no native API replaced.
Public raw samples and commands contain no private settings/account names.

## 2026-10-29 — shared Social offset, reload and all-tab geometry

User supplied cropped alignment reference, requested a slight downward adjustment,
then reported reload/tab-only recovery and Combat Log displacement. Fresh verified
15:32 UTC checkpoint includes1,263 actual files, history and403 on-disk WTF files
while Retail ran. All prior tracker/audit work preserved; main unchanged.

Final shared inset8 UI units uses existing primary tab-height service in column
owner coordinates. Relative height survives a provisional chat rectangle moving
later at login without another tab selection. All holder placement now anchors to
ChatFrame1 instead of selected Combat Log/Global/custom window geometry. Selected
Copy target, buttons/actions/art, settings, native ownership, scales, overflow,
combat waiter and three retry deadlines remain. No new runtime resource/framework.
Commits78fe4e7 and7f13000; exact identities/raw results in CHAT_COLUMN_ALIGNMENT.md.

Expanded actual column/social fixture:1,311 original plus508 ownership plus190 new
checks=2,009 passing; frozen baseline fails100 new assertions. Five alternating
pairs have zero count variation;100 layouts add no frames, same point writes;
shared tab-height reads are explicit correctness overhead. Existing chat layout165,
startup478 and retries5,869 controls pass. Final whole actual-file suite92 scripts/
733 syntax files passes, including the preserved pending tracker test.

Native Retail12.1.5.70575/interface120105/profile0 geometry has Social8 units below
menu/tab top (was33); measured surrounding rectangles unchanged. A private untouched
post-reload image was inspected before chat/tab input. Seven native out-of-combat
General1/Global3/CombatLog2 selections sample identical visible Social left57.600/
top361.059 after2seconds without further chat input; original observed tab restored.
No OS activation/mouse/clipboard/native API replacement. Temporary geometry/tab
exports removed by normal reload; original profile0 retained. Other native clients,
combat/taint and full-screen pixel/FPS acceptance remain pending.

Final combined verification:92 scripts/733 normalized Lua hashes pass. Source
inventory766, reachable577, setting definitions361, literal defaults519, saved
roots23, local links12,868. Ledger shapes valid:1,384 parity/35 ownership/28 API/
eight clients/77 references/308 performance/26 audit-domain rows. Protected361
files remain byte-identical; tracker source/test preserved. Explicit development-
tool markers absent across1,271 actual files outside Git. Main unchanged. Native
temporary data removed; original profile0 retained. Generated records remain with
the user's separate pending tracker work; focused runtime/evidence commits exclude it.

## 2026-10-29 - PERF-009 and original-plan continuation

Reviewed actual branch/main/dirty tree, contribution/status/decision/work records,
supplied original plan and relevant nameplate/action-bar specifications. Confirmed
all26 specification requirement ledgers remain available; added explicit original
stage-gate tracking and restored root continuity files as the user requested.
Verified external actual-file/history/settings recovery before runtime edits.
Preserved the unrelated pending objective-tracker source/test/docs.

Reproduced duplicate countdown discovery and temporary per-aura level tables in
real Core/Countdown replay. Runtime `efca305` reuses the current poll's discovered
region and unrolls the same guarded three level reads; no cross-poll cache or new
resource. Five alternating desktop pairs retain same text/anchor/level/frame counts
while discovery halves and measured transient desktop heap falls.1,160 checks,
100 remove/re-add cycles and5 mutation controls pass. The first full run exposed an
existing source guard tied to the exact two-argument helper spelling; adjusted it
to accept optional arguments while retaining label-before-fade ordering. Full
rerun passes93 scripts/734 syntax files; no unexplained runtime failure remains.

At the user's reminder, executed background Retail12.1.5.70575 real-widget native
checks and full-addon20s before/after windows after30s scheduled warm-up. Frozen
baseline file loaded by normal reload; candidate restored in normal folder and
loaded by normal reload. Source transport changed header comment punctuation only;
exported source executable lines/literals and full ASCII diagnostic probe verified.
Five alternating2,000-update native widget pairs: medians33.371 ->31.712ms; all raw
samples/ranges retained, one candidate slower. Geometry/font/alpha/hide-reuse match;
BugTabs counts0 before, after fixture and after candidate window. Private baseline/
candidate screenshots retained outside Git. Camera/mount/plate density changed,
so full-addon performance/pixel comparison is inconclusive. Legacy CPU is
unavailable with profile0; do not interpret its zero as no addon work.

Native diagnostics/root/globals/temporary frames removed by normal reload; original
profile0 unchanged and WoW stays open in background. No mouse/clipboard/activation,
API replacement, settings reset, new addon/repo, deferred callback audit or main
change. Actual protected aura rendering/security/FPS, long sessions and other
clients remain pending. Updated stage/evidence/client/parity/performance/API records.

## 2026-10-29 - PERF-010, action bars and player auras

Inspected current branch/main/dirty work, root rules/continuity, original action/
unit/minimap requirements, manifests, current paint/watch/API/auras and existing
regressions. Verified fresh external recovery of1,284 actual files/history and404
on-disk settings files with both clients/sync running. Preserved pending tracker
source/test/records. Read the supplied sync script as context; did not execute or
modify it. Actual timeout1s despite60s text remains external measurement load.

PERF-010 `677d85c` shares one activation boolean within existing highlight/Flush
batches. False is explicit, direct callers stay fresh and next-spell helper keeps
its guard. No cache/resource/framework/cadence change. Real-source regression1420
checks covers100 toggles per branch, state/identity, minirow construction, cleanup,
geometry and combat effects. Frozen baseline20 work failures; five alternating
fresh-process pairs have identical operation/resource budgets except activation
5800 ->100 disabled/5900 ->200 enabled. Five mutations rejected. Full94 scripts/
735 syntax files pass. Native aura smoke, player ownership and17454 bar-refresh
checks/19 mutations retain their scope.

Logged in requested Retail/Era characters using observed normal warning dismissal,
Reconnect and Enter World controls; same-account sessions conflict, so tests ran
serially. No OS activation/mouse/foreground keyboard/clipboard, credentials,
restriction bypass or API/script replacement. Retail12.1.5.70575/project1 and
Era1.15.9.70576/project2(SoD) each pass five alternating real57-button inactive-
highlight pairs. Exact received ASCII source/probe strings verify;5800 ->100 calls
per100 passes, medians5.303 ->2.728ms Retail/8.568 ->3.079ms Era. All57 button
shapes and native aura root anchors/scales/visibility match; matched-run errors0.
Root native OnEvent references stable during baseline observations. Separate20s
complete-addon windows after30s warm-up remain inconclusive for overall CPU/FPS.
Native player aura inclusive idle cost is small; no aura rewrite justified.

Verified577 potentially reachable source files equal on Era baseline. Existing
mirror lagged the temporary version; copied only verified Paint.lua between the
known versions and restored candidate in normal source/Era, byte-equal. No second
addon/repo or extra mirror job. Restored Retail profile0/root nil and Era profile1/
pre-existing diagnostic report, deep-equal after reload. Temporary namespaces and
closures cleared; both processes left open, Era in world, Retail warning dismissed.
Updated ownership/client/parity/API/performance/original-plan records. Actual active
combat/secure input, dense/restricted aura and long-session acceptance stays pending.

## 2026-10-29 - complete GitHub publication preparation

User requested uploading the complete current addon, then explicitly authorized
main. Inspected working tree/rules/continuity/remotes and preserved a fresh external
checkpoint including dirty/untracked files/history and404 on-disk settings files.
Checked/fetched GitHub main at7436820; existing development history descends from
it. Audited outgoing files/history for private credentials/account paths/archives;
no findings. No force push, game interaction, settings change or new sync job.

Included the formerly pending tracker source/test/chapter/API row and historical
focused report in73ca9d2. Focused40 checks pass; the prior complete report's735 Lua
hashes match the actual combined source. Rerun the full publication suite, reconcile
generated references and validate docs before pushing both main/development refs.
Private recoveries/settings/captures and ignored helper files remain local. Current
native limitations and remaining optimization gates are not promoted to complete
by this upload. Git ref verification establishes publication outcome.

Publication outcome: atomic push advanced GitHub main from7436820 to421c05a and
created the retained development branch at the same payload. Remote refs read
back exact; local main clean and0 ahead/behind. All735 runtime/test Lua hashes
still match the passing94-script report. This completion receipt adds docs only;
no game interaction or source/settings change during upload.

## 2026-10-29 - main-only current local snapshot

User requested main only, then clarified that the actual local files must all be
uploaded. Found newer uncommitted teleport source/test/docs, preserved them in a
verified external recovery covering1,302 actual files/history and404 on-disk
settings files. Both branch refs equaled b45eb5e; deleted the fully merged branch
locally/remotely. Main retains every published commit.

Inspected the local teleport delta and existing evidence. Its full95-script/
736-Lua report exactly matches current code; focused527 checks pass again. Include
this local fix and all current records, run the fresh local-snapshot suite, refresh
references and publish only main. No older checkout, runtime rewrite, force push,
new branch, private data upload, game input/settings or sync-job change.

## 2026-10-30 - unit power separator and text follow-up

User observed a middle border after target/ToT changes, misplaced text on
resource units, and a missing ToT split border. Retained the existing full-height
health layer. Reapplied separator alpha after partition and border-color paint,
kept restricted-max health text in the upper health area, and removed a Lua
truthiness test of a secret maximum. Expanded the focused desktop model with a
separator repaint and ToT zero/positive/secret transitions. Full validation:
96 scripts, 737 Lua syntax files, zero failures. Native all-client geometry,
secret and combat checks remain pending. No game or settings changes.

Follow-up: user specified that HP text should be vertically centered when
there is no resource, with the prior placement when resource returns, and asked
to repair ToT's HP/resource split. Player/target known-zero transitions now
refresh text anchors, including on `UNIT_MAXPOWER`. ToT's UIParent separator
container follows the raised ToT button level in side-by-side placement and
returns to its original level in stacked placement. Focused power and idle
geometry checks pass; full validation again passes 96 scripts and 737 Lua
syntax files. Native pixels remain pending.

Publication: preserved a fresh external source/history checkpoint
`Publish-unit-power-20261030T101822` with 25 changed files and a verified
history bundle. The outgoing archive had no private paths or credential-pattern
matches. GitHub main matched local parent `058efb8`; ordinary push published
`c313dc98a1e782aee1224554c347cd616f3ad7af`, and GitHub ref readback
matched. Native acceptance remains pending; no game or settings interaction.

## 30 October 2026 - combined local updates publication

User requested all current updates on main again. The publication includes the
local unit-frame scale controls and alignment fixes, vehicle/durability placement,
status-bar changes, vendor denomination messages, tests and their records.
The fresh [combined validation](validation/main-publication-2026-10-30.json)
passes 100 scripts and 741 Lua syntax files with zero failures. Native acceptance
retains the pending scope recorded in the feature chapters. No game/settings
interaction or runtime edits were made for publication.

Remote main matched parent `021b524893229fece34eff503a8ac1cf66388363`.
External checkpoint `Publish-all-20261030T104001Z` preserves 1,314 actual local
files and verified Git history. Source ZIP SHA-256:
`f7fb816f0651d264fbd30e9187afb2af8e17170aa39da02580d785b44c5f2176`.
Private archives/settings/captures and ignored local sync helpers stay outside Git.
Publish by ordinary push to main and verify remote identity and worktree status.

## 30 October 2026 - latest local updates publication

User requested another upload of all current local updates to main. This batch
includes first-load nonbinding settings reconciliation, Retail Sticky Targeting
and camera follow-ups, capability detection and Hearthstone editor load-order /
item-info fixes, plus their tests and documentation. The fresh combined report
`docs/validation/main-publication-latest-2026-10-30.json` passes 106 desktop
scripts and 748 Lua syntax files, with zero failures. Native checks retain
their pending status; no game input, settings changes or runtime edits were
performed for publication.

Remote main matched parent `52659bd8d22559dc0943ddd999e681d84d705d8e`.
External checkpoint `Publish-all-20261030T180617Z` preserves 1,350 actual
local files and verified Git history; source ZIP SHA-256
`0c5cb6547bf035eb33ec362603ca544f53079e71f6d31e0e5185d24ef80422d7`.
Private settings/captures/archives and ignored local helpers remain outside Git.
Use an ordinary push on main and verify remote identity and clean status.

## 30 October 2026 - cursor loot publication

User requested uploading all current local updates to main again. Include the
cursor loot and fast-pickup module, Tools / Loot options, money alert coin art,
profile callback correction, tests and evidence. Native post-fix acceptance
remains pending as documented in `docs/LOOT_CURSOR.md`. Publication makes no
runtime edits and does not interact with the game or saved settings.

External checkpoint `Publish-loot-20261030T190738Z` preserves 1,363 actual
local files and verified Git history, including untracked work. Source archive
SHA-256: `ef98ebb61f9e132697f5b69b699b544b82059444c436c4d56c8123cfd8af24d3`.
GitHub main matched parent `b68f2545fa53e83a7eb8482b73e2c0569ecdcc38`.
The combined publication evidence is `docs/validation/loot-publication-2026-10-30.json`.
Private settings, archives, captures and ignored local helpers stay outside Git.
Use an ordinary main push, verify remote identity and preserve history.

Fresh combined desktop validation: **107 scripts /751 Lua syntax files, zero failures**.

## 30 October 2026 - attached stance scale

30 October 2026: attached stance bars now follow player-frame scale, including
immediate slider changes and reload; detached placement restores normal size.
Existing combat deferral is retained. 21 stance and 28 bridge checks pass;
full suite: 108 scripts /752 Lua syntax files, zero failures. Native pixels,
input and taint remain pending (no visible WoW process).

Match effective parent scales at the existing stance anchor/layout entrypoints.
Refresh only the anchor after a player whole-scale change; avoid rediscovery
and binding work for this geometry correction. Source/history/settings recovery
and exact before/after hashes are in [the scale record](UNIT_FRAME_SCALE.md).
No game/settings interaction or competing framework; excluded callbacks unchanged.

## 30 October 2026 - stance, loot and Micro Menu publication

User requested uploading all current local updates to main. The complete payload
includes attached stance scaling, loot source filtering / cursor pinning / delayed
source routing, the Micro Menu nil-center fix, tests and their records. All 753
current normalized Lua hashes exactly match the passing 109-test combined report
`docs/validation/micromenu-nil-center-full-2026-10-30.json`; no Lua file is missing
from that report. Reused this verified combined evidence without rerunning an
unchanged suite. Documentation references and verification index are refreshed.
Native pending checks retain their stated scope; no game/settings interaction
or runtime edits were made for publication.

External checkpoint `Publish-updates-20261030T202520Z` preserves 1,376 actual
local files and verified complete Git history. Source ZIP SHA-256:
`f6351660aa5a58daffb70c8aa9c3d2a70d5774f1eb112d8ae36d4f8070c1025b`.
GitHub main matched parent `57a252e0e2b467cf7788c3f52aa5d1dd8d83779e`.
Private settings/captures/archives and ignored local helpers remain outside Git.
Publish by ordinary push to main, then verify remote identity and clean status.

## 1 November 2026 - GitHub feature overview and current local publication

1 November 2026 GitHub publication: added a root README with a compact feature
overview covering the current inventory, links to all detailed feature controls,
client-specific availability, companion integrations, installation and command
entry points. The complete local payload includes the pending chat durability
loading-screen correction. Fresh combined desktop validation passes 113 scripts
and 758 Lua syntax files; native pending checks retain their recorded scope.

The README describes shipped feature families, not every historical specification
as implemented. Existing detailed feature/options/commands/integration references
remain authoritative for controls and client gates; no new competing inventory
or universal client-certification claim was added. No runtime edits, live game
interaction, settings/profiler changes or excluded callback work in this task.

External checkpoint `Publish-readme-20261101T130027Z` preserves 1,396 actual
files and verified Git history, including all pending/untracked work. Source
archive SHA-256: `5981eedb563317b7e56ea089022528741a966a4ec72ac3672a5c3aef6a6b873f`.
Remote main matched parent `0e73e74a6e782a30fd04289bc84bbf551c440fd8`.
The [fresh publication report](validation/github-readme-publication-2026-11-01.json)
covers the complete local Lua source. Publish all current addon/test/docs and the
new README by ordinary push to main, then read back the remote identity. Private
settings, recoveries, captures and ignored sync helpers stay outside Git.

## 4 November 2026 - publish current local mail work

User requested all current local updates on GitHub main. Include the built-in
mail modules, TOC/settings wiring, tests, README feature summary and existing
implementation/validation records. All 777 current normalized Lua hashes and
the complete Lua file set match the passing 122-script report
`docs/validation/mail-integration-2026-11-04.json`; no runtime edit or repeat
full suite was needed for publication. Mail attachment forwarding, repeat send,
advanced completion and native acceptance retain their documented pending scope.

External checkpoint `Publish-all-20261104T175541Z` preserves 1,421 actual
local files and verified complete Git history, including untracked work.
Source ZIP SHA-256: `fe1f8879d41952e1cc9debc30c000fef49fdcaa6f1dddb09295ca7994e1b76ef`.
GitHub main matched parent `1b319d19aa00fffa7e798a66d045e55902af6706`.
Private recoveries/settings/captures and ignored local helpers remain outside
Git. Use an ordinary push to main; verify remote identity and clean status.
No game, settings, sync-job or profiler interaction during publication.

## 5 November 2026 - Syndicator consumable batch metadata

5 November Syndicator consumables: batched bag callbacks now retain every
added/removed item and dirty bag until publication. This fixes a reproduced
missed selector update for better items and last-use depletion across food,
water, potions and bandages. Five desktop pairs: baseline 200 failures versus
candidate 0 per400 checks; three mutations rejected. Full suite123/778 passes.
Native gameplay, pixels, taint and performance remain pending.

Reuse the existing bag item-set log as the batch lifetime and merge classifications
with the existing inventory helper. Keep last-change getters readable; begin a
fresh classification after publication. No polling, framework, client API change,
settings reset or excluded callback modification. User authorizes publication
to main. [Source/recovery/native limits](SYNDICATOR_CONSUMABLE_UPDATES.md).

## 5 November 2026 - live-zero consumable reset

5 November live-zero follow-up: exhausted food/water/potion/bandage buttons
now reset from reliable live bags before Syndicator's delayed cache callback.
The painter retains the verified count; loading holds and combat deferral
remain. Button-level375 checks pass (baseline200 failures), three mutations
rejected; full124 scripts/779 Lua syntax pass. Native acceptance pending.

The prior notification regression did not cover provider-cache delay. Keep
external inventory ownership but verify these stack counts through the existing
live-count adapter; reuse the shared watcher and existing reset/combat paths.
The previous upload authorization remains applicable to this follow-up.
[Exact source, recovery and limitations](SYNDICATOR_CONSUMABLE_UPDATES.md).
No settings reset, native interaction or excluded callback change.

## 5 November 2026 - utility pet display ownership

5 November utility pet faces: the user clarified a question-mark/wrong-icon
symptom. The manager now owns the selected journal-pet icon and tooltip via
existing override surfaces, with modifier changes, metadata completion and
cleanup. Summon macros/GUID storage remain intact. 920 checks pass (old40
failures), three mutants rejected; full125/780 passes. Native checks pending.

Use the utility manager's resolved display entry and the existing icon/tooltip
override contract. Preserve generic macro parsing, secure summon bodies and
all saved assignments; metadata events reuse the existing refresh queue.
[Recovery, exact sources and limitations](UTILITY_PET_FACES.md).

Options native-readiness audit (9 November): all twelve owned runtime/test files
remain identical to the sorting evidence; their Lua identities also match the
later 272-script/942-syntax RestedXP validation. Current tools, all five installed
client folders and MCP headers confirm no Witchcraft connection/installation.
Read-only host verification and PrintWindow show Forever gameplay with settings
closed; no native candidate appearance/input pass is inferred. No input/focus,
settings/profiler writes or setup changes. Required native acceptance remains
open; see `validation/options-native-readiness-2026-11-09.json`.


Native continuation17:40UTC: Forever background readback confirms zero session errors, solo/OOC, profiling0, all three merchant input toggles configured, party v7 ready/secure with four hidden solo members. No runtime/settings/gameplay changes. User reports a real test party/raid with combat roster changes is unavailable now; actual combat/grouped acceptance remains pending. First consecutive unavailable-scenario audit; goal active. See FOREVER_NATIVE_PERFORMANCE.md and its validation JSON.

9 November goal blocker audit3: actual combat roster and grouped performance acceptance remain unavailable after three consecutive goal turns. User cannot arrange the real test group now. Goal blocked pending that scenario; no new runtime, input, settings or profiler changes. Completed evidence and exact pending checks remain in FOREVER_NATIVE_PERFORMANCE.md.
