# Next session

20 November. R189 addresses the vertical strip beside the spell icon.
Compare a visible cast on both styles after reload, checking the two
sides of the divider and the top and bottom joins.
[Cast divider](docs/UNIT_OVERLAY_ATTACHMENTS.md#vertical-cast-divider).

20 November. R188 supersedes the R187 candidate for live HUD acceptance
following the cast border report. Verify the horizontal rim at both ends
of the cast divider in either border style, then continue the existing
HUD acceptance cases. [Cast rim evidence](docs/validation/cast-rim-r188-2026-11-20.json).

20 November. Measure one uninterrupted taxi flight, then check the tooltip for
that route. Repeat the ride through `/reload` and through a separate logout
and login. Compare the countdown with the actual landing and verify early
landing on a multi-stop route. [Native checks](docs/CLIENT_VALIDATION.md#flight-timer-rework).

20 November. The cast icon now reaches the type 1 divider. The next image
comparison is a type 1 Fire cast after reload, with type 2 as a control.
Swing and Shoot share the verified layout.
[Cast icon seam](docs/UNIT_OVERLAY_ATTACHMENTS.md#type-1-cast-icon-seam).

20 November. After reload on a mage with Ruby and Jade in the bags, use Ruby
on the Mana Gem button while in combat. When the gem cooldown ends, use the
same button or its keybind to spend Jade without leaving the fight. Check the
next-step icon and count, right-click conjure, and blocked-action errors.
Repeat with a lower step active at combat exit and with a stronger gem added
both in and out of combat. Check that the face returns to the best carried rank.
[Native checklist](docs/CLIENT_VALIDATION.md#mana-gem-sequence).

20 November. After reloading the corrected installed copy, use the Food or Water
button and its keybind with equal-tier stock split into 20, 20 and 10. Verify
that the 10-stack drops first. Check conjured priority and the optional combat
swap across combat entry and exit. All five installed files match the correction
for the early `Bridge` error. [Button behavior](docs/12-extra-button-system.md#smallest-food-and-water-stacks).

20 November. The Auction Restock recipe and hover fixes are on disk. The
remaining native check is to hover a capped Restock row and plan from a
previously captured recipe with its profession closed after a reload.
[Auction Restock](docs/AUCTION_RESTOCK.md#saved-recipes-and-row-hover).

20 November. On Forever after reload, verify the original map and a direct
addon drawing stay visible on Flux's Map tab in combat. Trigger a quest-watch
update, then exit combat and check for one refresh and any blocked call. Repeat
with the normal World Map to verify the handoff. [Evidence](docs/validation/world-map-combat-2026-11-20.json).

<!-- LHO-FINAL-ACCEPTANCE-GOAL-20261120 -->
20 November. The resumed goal reached live acceptance. Use the six fixed [acceptance checks](docs/INVENTORY_PERFORMANCE_ROADMAP.md#final-acceptance-checklist) alongside the addon-wide [release roadmap](docs/RELEASE_ROADMAP.md). The post-resume check verified all 90 closeout Lua hashes in each install, the common TOC, and the five exact executable versions. Forever was the only running client and was in use in Desolace. The user confirmed no bank, vendor or mailbox setup is available now. The next acceptance check can use whichever listed setup becomes available first. Reopen implementation only for a reproducible acceptance failure. [Client evidence](docs/CLIENT_VALIDATION.md).

Use [release status](docs/STATUS.md#release-acceptance) to choose the next acceptance check. The [release roadmap](docs/RELEASE_ROADMAP.md) defines the addon-wide endpoint.

<!-- RELEASE-FINISH-LINE-20261120 -->
20 November. The expanded R187 desktop gate passed 50 scripts. The pinned runtime files match all five installed copies. Three checks after the desktop gate found no current playtest result and the goal is blocked. Start live acceptance with player-performed held-action crossings and rapid drops, then party and raid transitions. Open a new implementation slice only for a failed gate. [HUD finish line](docs/HUD_PERFORMANCE_ROADMAP.md#finish-line).
<!-- /RELEASE-FINISH-LINE-20261120 -->

<!-- LHO-OPTIMIZATION-CLOSEOUT-20261120 -->
20 November. The user requested a real endpoint. Closed out the current optimization pass with 82 of 82 regression scripts passing and 90 relevant Lua files compiled and matched across five installations. Corrected two stale test fixtures. The production Craft and ConsumableBind Lua retains the verified checkpoint. The proposed craft selector cache and remaining live acceptance cases are in the roadmap backlog. Use one explicitly scoped workflow for any follow-up.

The bounded bank follow-up stopped at preflight on three consecutive checks. The verified Forever client was in transit each time, with no bank or other live test fixture open. R677 remains deferred until an actual bank session is available. The R100 jump worker ended with two key pairs and movement unverified.

<!-- LHO-CRAFT-FALLBACK-CATALOGUE-OWNERS-20261120 -->
20 November. R686 moved and returned the same 18-item stack. Counts, cursor and both grids passed. Each direction invoked one native delayed-bag invalidation and three catalogue builds from owned ApplyRightClick, totaling 3.471 and 3.126 ms including instrumentation. R687 measured 149 catalogue rows and 19 known reagent dependencies across the three selectors. Four median pairs were 2.958 ms for the selectors and 0.242 ms for native reagent reads. This profile had no positive craftable recipe. Preserve recovery for incomplete recipe and item state and late providers when implementing unchanged-stock reuse. R100 rearmed after the earlier cue cleared and is running as 25324 with one Space pair and movement unverified. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json#nativeCraftFallbackBagCatalogueOwners).

<!-- LHO-FIRST-COPY-GRID-RECEIPT-20261120 -->
20 November. R684/R685 traced the real Conjure Food item 1487 count from 0 to 14 on Forever with Syndicator and Baganator. Non-combat selected the new stack and combat faces stayed stable. Two count flushes totaled 0.369 ms. Six recipe catalogue reads totaled 5.033 ms and three consumable recomputes totaled 10.324 ms, with overlap possible. Attribute the repeated catalogue reads by caller before touching the delayed-bag fallback that handles late provider counts. Continue real depletion and charge checks. R99 remains active as 5616. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json#nativeFirstFoodCopyGridRoute).

<!-- LHO-CONJURED-CACHE-READ-20261120 -->
20 November. R682 reloaded the junk edit. R680/R681 matched the 98-call cold junk display and the 41-ID warm read. The cold junk total fell from 3.684 to 3.015 ms and the warm exemption's repeat metadata reads from 608 to zero. R683 found 0.083 ms of slot resolution within 1.387 ms of warm protection with zero protected slots. Leave slot resolution alone on this evidence and move to actual item-count changes through both grids. Run the prepared R677 exact move when the bank is available. R99 is running as 5616 with one Space pair and jump movement unverified. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json#settledConjuredMetadataReads).

<!-- LHO-BANK-RELOAD-ROADMAP-20261120 -->
20 November. R674 reloaded Forever on the third reservation. R676 confirmed the loaded close fix after a player-opened bank session. Both close events arrived, all five gates cleared, and 21 cached item counts matched live with zero new Lua errors. R97 retired after one Space pair. R98 is running as process 29944 and recorded one new Space pair, with jump movement unverified. R677 is syntax-checked and prepared for the exact R672 slot move, but the subsequent targeted click did not reopen the bank. Run R677 when the bank is available. For the next cold backpack trace, retain the R615 nested timings and measure FluxUI's BagShow consumers and category callbacks separately. [Bank evidence](docs/validation/bank-tier-live-counts-2026-11-19.json#nativeBankSlotMoveAndCloseLatch) [Backpack evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BANK-CLOSE-LATCH-20261120 -->
20 November. R672 returned the real bank stack to 6:1. Combined summary timings were 13.970 and 10.907 ms, with stable stock and money. R673 visually closed the bank and received both events, yet remained logically open/live. R675 localized it to the shared latch. FluxUI now lets actual access own the gates after a native close, with finite event-driven recovery and reopen cancellation. The original source fails 85 new assertions and the current build passes all 3,782 checks and ten regressions. R676 verified the loaded close. The matched move remains due. [Evidence](docs/validation/bank-tier-live-counts-2026-11-19.json#nativeBankSlotMoveAndCloseLatch).

<!-- LHO-BANK-TIER-SETTLED-KIND-20261120 -->
20 November. R666 observed a real bank open with automation off and no new Lua errors. The bank stayed open and bag generation changed during the long capture. R667 isolated four cold-registry summaries at 6.779 to 6.941 ms. R669 counted 240 tier matches and 90 usability calls. R671 skipped 132 wrong-tier calls and reduced paired median from 10.0165 to 9.3595 ms with exact zero-withdrawal results. Two FluxUI Lua files now use the settled kind only in the owned bank-target build. Eight regressions pass and five installs match. The historical parser call-count test fails identically before and after. After the bank closes, reload and verify the installed comparison and positive triage while keeping live retry behavior. The resize-aware R97 helper is running as 29036. [Evidence](docs/validation/bank-tier-live-counts-2026-11-19.json#nativeOpenBankTierKindWork).

<!-- LHO-BANK-VIEW-LOADED-20261120 -->
20 November. R663 measured the actual open-bank Restock button with four rows and zero eligible withdrawals. R664 released before typing when the player closed the bank. R661b reloaded after close. R665 matched both frame identities and all nine target rows, six shown Auction rows and one hidden row. Median for 48 visibility queries fell from 0.513 to 0.4245 ms, and for five tier-bank queries from 0.6775 to 0.623 ms. Whole-list samples overlap. R97 is running as process 24080. The interrupted first heartbeat left a blank chat that was cleared with Escape before timing. No Space pair was verified on R97 yet. Continue actual changed bank slots, cold open and close, active Pending, vendor and populated mail when available. [Loaded comparison](docs/validation/baganator-bank-view-index-2026-11-19.json#loadedFallbackFrameNames). [Open-bank timings](docs/validation/bank-tier-live-counts-2026-11-19.json#nativeOpenBankRestockButton).

<!-- LHO-BANK-VIEW-FALLBACK-NAMES-20261120 -->
20 November. R659 isolated repeated closed-bank visibility work. R660 kept two real Baganator frame identities and order and reduced the 48-call query median from 0.500 to 0.402 ms. Both FluxUI visibility paths now build fixed frame names once, with nine regression scripts and five matching installs. R661 was released before reload when the player opened the bank. R662 validated 21 positive item counts and all 22 native stacks in the real Forever bank. After the bank session ends, reload, rearm the prepared R97 helper and repeat the visibility timing with installed code. R96 recorded five complete Space pairs, with movement unverified. [Visibility evidence](docs/validation/baganator-bank-view-index-2026-11-19.json#fallbackFrameNames). [Open-bank evidence](docs/validation/bank-tier-live-counts-2026-11-19.json#nativeOpenCharacterBankStackParity).

<!-- LHO-RESTOCK-TARGET-ATTRIBUTION-20261120 -->
20 November. R656 measured the empty preset lookup at about 0.002 ms per build. R657 timed independent reagent discovery and row bank reads. R658 matched all nine actual target rows and isolated the five closed-bank tier reads at 0.655 to 0.712 ms total, with normal food and water stock skips. Warm tier bag reads were 0.020 to 0.025 ms. Keep live and missing count recovery. Next isolate which closed-bank reads repeat across the three stock-bearing tier branches before editing. R96 recorded one complete foreground Space pair, with movement unverified. [Evidence](docs/validation/bank-tier-matcher-2026-11-19.json#nativeRestockTargetAttribution).

<!-- LHO-RESTOCK-TIER-RECORD-FILTER-20261120 -->
20 November. R651 localized warm Auction rebuilds near 3.6 ms and the shared target list near 2.4 ms. Exact tier filters matched 205 actual verdicts. R653 caught a missed local alias in the initial build's closed-bank branch. Corrected it, added the exact regression, and R654 reloaded the matching files. R655 completed the actual row and closed-bank reads, matched all 205 checks and reduced the median for 1025 isolated tier queries from 1.108 to 1.061 ms. No new Lua errors on the corrected build. The shared target-list work remains the larger measured cost. R96 resumed as process 32196 and was deferred when Windows refused activation. Continue the warm AH, live vendor, active Pending, open-bank and populated mail scope. [Evidence](docs/validation/bank-tier-matcher-2026-11-19.json).

<!-- LHO-AUCTION-INITIAL-PLAN-PAINT-20261120 -->
20 November. R645 live warm Restock showed the early idle/changed repaint before two searching paints. The owned OnShow flow now omits that one paint while keeping a completed paint in the same call. R646 reloaded the two matching files. R647 stopped before the auction button input and restored on timeout. R648 completed a genuine cold Auction open, omitted idle/changed, showed the native throttle wait and closed with six visible rows, one hidden row, no changes in stock or money and no Lua errors. R650 armed after a focus change and timed out cleanly without a second open. R95 runs as process 38368 and logged one Space pair with movement unverified. Repeat the matching warm path when available. Continue the larger row-build and Pending, mail, bank and vendor work. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-ROW-ORDER-ALLOCATION-20261120 -->
20 November. R641 compared the actual six Restock rows while commerce was closed. Median for 340 exact sorts fell from 3.621 to 2.618 ms with identical order. The runtime comparator no longer allocates a temporary empty tier list for an ordinary row. R642 reloaded and R643 third reservation matched the old order across all six rows on a real native Auction open, then closed without a transaction, item change or new Lua error. First Restock startup took 13.814 ms, with 132 comparisons taking 0.129 ms across the workflow. R94 resumed as process 12756 and recorded one foreground Space pair with movement unverified. Continue profiling the larger row-build and startup work, and keep active Pending, vendor, open-bank and populated mail checks pending. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-CATALOGUE-REVOCATION-VALIDATION-20261120 -->
20 November. R636 third reservation successfully moved and restored the live 18-item stack after loading the text alias edit. R638 retrieved both timing lines. Both directions kept grid selections and counts, delivered one bag event and made three catalogue builds. Catalogue totals were 2.934 and 3.436 ms. R639 measured a simple removal lookup over 1110 saved flags at 8.418 to 7.097 ms per 12 builds. R640 included shape checks and took 9.6895 ms against 8.997 ms. Retain the eager removal snapshot. Keep R93 running, and continue live inventory-specific restock/vendoring, bank, Pending and mail when available. Focus the next optimization on a measured callback beyond repeated removal lookup. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-TEXT-ALIAS-20261120 -->
20 November. R632 completed a real Food cast. FluxUI and native counts went 56 to 70, with three bag events, six recipe-list rebuilds and 5.096 of 6.644 ms in the catalogue. R633 missed the owned character-key normalization and collected no timings. R634 used the owned key and reduced the median for 18 catalogue builds from 13.006 to 12.161 ms, with all 149 recipe references and order matched. FluxUI now reuses readable string alias keys while retaining replacement converters. R635 reloaded. Both R636 bag-move reservations stopped before input on foreground changes and were released. R93 restarted the 180-second helper as process 36096. Windows refused the observed activation attempt, with no keys sent. Retry the loaded move once stable, then examine repeat catalogue work across the three scheduled selectors, with native count recovery intact. Live Pending, vendor, bank and populated mail remain open. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAGANATOR-LAZY-CATEGORY-ICON-20261120 -->
20 November. R629 opened the actual Forever Baganator backpack and saw nine ordinary labels with a hidden gear-set icon texture. R630 restored the minimized client without activation and reloaded the lazy allocation edit. R631 reached 19 label applications again, with zero eager textures, ten unchanged anchor observations in both runs, stable bags, zero new Lua errors and the closed backpack restored. Neither run had an equipment-set label. R92 restored the 180-second jump worker as process 40108. Windows refused its observed activation attempt before any input. Continue a real equipment-set label check, the remaining layout cost, live Pending, vendor, bank and populated mail. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-CRAFT-POTION-FALLBACK-STATIC-20261120 -->
20 November. R626 compared the exact potion fallback on 131 actual fallback rows out of 149 cached recipes. Median time was 2.469 to 1.890 ms for 3,144 checks, with exact verdicts. The candidate skipped owned static reads when potion name text settled the verdict. R627 loaded and R628 returned the real 18-item stack, preserved counts and both grids, and recorded 4.818 and 3.634 ms across the three lists per direction. Full callback speed remains unverified. R91 restored the 180-second helper as process 42760. Continue live vendor, Pending, bank and populated mail as available. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CAST-WIDGET-ENTRY-INDEX-20261120 -->
20 November. R623 and R625 used the same 195 real buttons before and after the cast registration lookup edit. The median for 780 FollowExtra calls was 7.959 to 5.133 ms. Each confirmed Food cancel delivered three interrupts with 185 resets per callback and zero visible interrupt plays on this profile. Whole interrupt time remained similar. R624 completed the reload after a nonactivating background restore and R90 rearmed process 39216. Resume native vendor, Pending, bank and populated mail plus casting owner and frame checks. [Evidence](docs/validation/casting-equality-work-2026-11-15.json).

<!-- LHO-AUCTION-SEARCH-PREPAINT-LIVE-20261120 -->
20 November. R620 restored Forever behind the current app and reloaded d82b016c5fc6. R621 tested cold and warm Restock, restored the closed panel and cleared the interrupted R88 cue. R89 brought the three-minute helper back as process 11436. R622's warm search after the actual price cache aged did one synchronous row build and three synchronous plus three later paints. The previous flow made four synchronous paints. The same six visible and one hidden rows were present, money and bag generation held, no transaction or Lua error appeared, and the Auction House closed. Continue live Pending, vendor, bank, mail and casting as available. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-SEARCH-PREPAINT-20261120 -->
20 November. R617 confirmed one synchronous Restock build and 12.567 ms first ShowSession with the loaded code. R618 and R619 reached the real warm panel and counted four synchronous paints followed by three later paints. R619 recorded idle/changed, idle/searching and two searching/searching paints. FluxUI now omits the intermediate idle/searching paint for the two owned search starters. All 43 Auction regressions passed. R620 stopped before typing because Forever was minimized. Next reload, restore R88 and repeat the same live flow. R87 remains active until the actual reload. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROTECTION-EMPTY-SLOT-LOOKUP-20261120 -->
20 November. R613 identified repeated formatting in the protected-slot query when the map was empty. R614 loaded the fast return and R615 matched all 52 actual slots, with the median per 416 queries falling from 0.600 to 0.375 ms. Both backpack test opens closed. The first R616 reservation stopped before typing. The second retrieved the trace in the background. R87 rearmed process 9740. Continue the cold layout attribution and live Restock, Pending, vendor, bank and populated mail. R616 retrieved 44.32 ms for the first open with a nearby 63 ms frame gap. Baganator layout reached 42.41 ms inclusive, with 21.65 ms in display and 10.364 ms in 53 item-detail calls. Nine layout groups were created. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-NUMERIC-CATALOGUE-OPEN-BAG-20261120 -->
20 November. R612 repeated the real move and return with the category backpack open after R610. The observed first open still took 52.76 ms. One Baganator redraw per direction took 5.374 and 4.916 ms, with counts and checked grid selections equal. Closed bags and the original stack slot were restored. R86 logged two Space pairs with the second deferred until after the command and bag probe. Next isolate the cold layout and continue actual commerce workflows. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-NUMERIC-CATALOGUE-LIVE-BAG-20261120 -->
20 November. R610 reloaded the numeric Craft catalogue and R611 repeated the real closed-backpack stack move. The three recipe lists took 4.468 and 3.713 ms across the two directions. Counts and grid assignments matched and the stack returned to 0:8. R86 replaced the readiness cue cleared by reload and process 18360 recorded one complete Space pair. Use the first backpack-open opportunity if still available, then check real Restock, Pending, bank and populated mail. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-NUMERIC-FULL-CATALOGUE-20261120 -->
20 November. The full Craft catalogue now uses numeric keys for ordinary public recipe IDs. Ten paired samples on 149 actual saved Forever recipes across nine aliases preserved exact recipe references and order. The host Lua median was 0.407 to 0.343 ms per build. R606 and R607 stopped on changed input before a diagnostic ran. Next load the matching source and repeat the real slot move with the same closed-bag and open-bag checks. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAG-MOVE-CRAFT-CATALOGUE-20261120 -->
20 November. R602 moved and returned the 18-item stack with Baganator open. One provider redraw per direction took 4.908 and 4.315 ms. FluxUI Notify took 0.603 and 0.573 ms, with unchanged grid selections and zero classifier scans. R603 repeated the same move with bags closed and measured three craft lists per delivery at 4.592 and 4.362 ms total. R605 identified the full cached profession catalogue as 2.965 of 4.883 ms across the three direct recipe branches. R604 aborted on a physical modifier, its blank chat was dismissed with targeted Escape and its private root cleared by R605. Preserve independent live count updates. Next optimize the repeated fresh catalogue work and retest real stack events. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-RESTOCK-REAGENT-VISIBLE-PASS-20261120 -->
20 November. R598 established three reagent-set builds per Restock rebuild, R599 found a shorter lookup with exact row parity, and R600 loaded the guarded fix. R601's six installed Forever pairs fell from 3.890 to 3.555 ms at the median. Six visible rows, one hidden row and potion targets matched. A separate trace confirmed the new branch. Real Auction Restock-open and Pending workflows still need native coverage. R84 is running as process 16104. [Evidence](docs/validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-PROFESSION-FILTER-CANDIDATES-20261120 -->
20 November. R595 verified live Have Materials with the loaded profession optimization. Visible Tailoring recipes went 102 to zero and back to 102, both aliases retained all exact facts and 369 removals, and the setting was restored. R590's full row comparison took 2.864 ms at the median. R591 reduced only 0.066 ms in saved alias ranking with reverse lookup. Both candidates stayed out of runtime. R597 established wheel-only trinket bindings in the current profile and identified the single R592 diagnostic frame-enumeration error. Tailoring is closed, R83 is still running, and real Restock-open and inventory-triggered paths remain next. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-CURRENT-PASSIVE-20261120 -->
20 November. R588 watched the loaded Tailoring revision for 34 seconds. The source took 7.748 ms and two list events took 7.528 and 8.632 ms, including a passive delivery at 26.57 seconds. Both saves kept all 102 recipes and 369 removals under both keys. R589 attributed 5.553–8.323 ms to the interval before the first store, with four natural callbacks at 8.890–12.341 ms. Both probes restored, Tailoring closed and no Lua errors appeared. The current character is in the Wizard's Sanctum with Auction Restock closed. The real Restock-open repeat and exact fresh-data shortcut remain open. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-RETAIN-SAVED-REMOVALS-20261120 -->
20 November. R586 loaded 30dd26404e9e and R587 confirmed the first ready Tailoring callback in 9.824 ms. Both alias keys retained all 102 learned rows and 369 removals. Four alternating diagnostic pairs took 25.81 ms at the median for a full-read callback and 15.188 ms for the optimized callback. The observer restored, the bag generation held, zero new Lua errors appeared and Tailoring closed. R83 resumed as process 32468. Next measure natural idle list deliveries and the same profession events with Restock open. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-FIRST-READY-READ-COST-20261120 -->
20 November. R585 captured the first ready Tailoring source after R583. Its real callback took 14.026 ms. Four read-only sweeps under the same source found 369 unlearned recipe-info calls at 5.921–6.721 ms and the matching negative spellbook queries at 0.207–0.250 ms. All 102 learned IDs returned schematics and output item IDs. The observer restored, Tailoring closed, the bag generation held and zero new errors appeared. Next compare full saved rows and removals with a guarded source candidate, including missing, filtered and stale cases. R82 remains the active three-minute helper. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CAST-MATCHER-NUMERIC-20261120 -->
20 November. R583 reloaded the numeric spell matcher change on Forever. R584 observed a real Food interrupt and matched all 117 comparisons in eight alternating pairs. The loaded median was 0.648 ms versus 1.122 ms for the prior matcher. No food completed, the bag generation stayed stable, both observers restored and the probe reported no new Lua errors. Full interrupt fan-out and frame time remain open. R82 resumed as process 30156. Next prioritize the first ready profession scan and repeated list deliveries. [Evidence](docs/validation/casting-equality-work-2026-11-15.json).

<!-- LHO-CAST-POSITIONAL-PAYLOAD-20261120 -->
20 November. Cast start, interrupt and completion now use the real spell ID when a readable cast GUID identifies the positional payload. R580 kept all three same-frame interrupts for the same Food cast and still recorded 117 matcher calls and 250 override reads per interrupt. R581 completed Food and both counts went 42 to 56 after one delayed bag event. No Lua errors. Focus next on repeated spell identity queries within owner lookup. R81 resumed as process 20864. [Evidence](docs/validation/casting-equality-work-2026-11-15.json).

<!-- LHO-OWNED-IDLE-RETICLE-CLEANUP-20261120 -->
20 November. The loaded ButtonFX reticle cleanup now uses one stop and hide for a verifiably idle frame with both FluxUI-owned methods. R576's six pairs over 200 real buttons cut the median from 0.962 to 0.887 ms and kept their state. R577 cleared playing and paused reticles on both a bar and an Extra Button. The first loaded variant showed little gain, and the full cancel still needs matched timings. Focus next on the larger owner scans and exact event payload identity. R80 jump worker resumed as process 12576. [Evidence](docs/validation/casting-equality-work-2026-11-15.json).

<!-- LHO-CAST-INTERRUPT-TARGET-RESET-20261120 -->
20 November. R565 retry and R566 captured two real Conjure Food cancels. Each delivered three interrupts. R566's three shared one frame timestamp, with 600 chrome resets and six owner scans. No inspected button reported a non-normal press state or a visible reticle or spell highlight. Every button had a reticle frame and both FluxUI stop methods. Check dirty reticle and pressed-button cases and exact event payloads before changing cleanup or owner selection. No items changed. R78 remains live. [Evidence](docs/validation/casting-equality-work-2026-11-15.json).

<!-- LHO-PROFESSION-SOURCE-STORE-ATTRIBUTION-20261120 -->
20 November. R564 isolated the warm ready Tailoring source at 13.493 ms, with 9.965 ms before the first save, 1.614 ms in the first save, and 0.941 ms in the alias save. Two list events spent 4.674 and 5.074 ms before saving. Focus on the full source recipe reads and keep the first-ready and late-data checks. R565 cast/cancel stopped before input on foreground activity and released its lease. Tailoring is closed and R78 remains running. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-COMBINED-REAGENTS-20261120 -->
20 November. Complete modern recipe scans now collect flat reagents and saved crafting details in one schematic pass. Six native pairs over 102 Tailoring recipes and 298 slots matched all fields, with median extraction down from 1.164 to 1.027 ms. R562 loaded the edit. R563 preserved the first ready source and list publications, all 102 rows and removal flags, and closed Tailoring. Those handlers took 23.17 and 8.63 ms in one frame. The source handler and first store still need work. R78 jump worker is running as process 32412. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-READY-SOURCE-COUNTER-20261120 -->
20 November. R560 confirmed the live Tailoring source boundary on the first open after R558. Closed source was nil, the loading show used counter 32 and ready source/list used counter 33. Those FluxUI callbacks took 24.16 and 13.63 ms in the same frame and matched all 102 saved rows and removal flags. The observer restored, Tailoring closed and R77 logged three Space pairs. Keep first-source metadata reads while isolating the expensive learned extraction and first store. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAGANATOR-JUNK-SETTINGS-20261120 -->
20 November. R559 verified the loaded FluxUI Junk display change with 65 settings lookups instead of 120 on the same 59 occupied slots. Both revisions classified zero as Junk and kept 48 gray fallback calls. First backpack open sampled 57.08 ms before and 47.32 ms after. The larger Baganator layout cost and repeatable frame-time effects remain open. Continue the first ready profession source/list cost breakdown with fresh learned and removal evidence. The backpack is closed, the observer restored and R77 was verified running. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-PENDING-IDLE-REFRESH-20261120 -->
20 November. Pending bank-target reads without a job now use one settings lookup instead of four. The existing paint and active-job lifecycle remain. Four loaded Forever batches of 48 reads took a median of 0.317 ms before and 0.146 ms after. All returned zero targets and matched paint counts. Neither idle window had an automatic refresh. R554 loaded the edit, R555 restored the probe and R76 restored the jump helper as process 42164. Native active Pending, positive open-bank results and the remaining workflow and client checks are open. [Evidence](docs/validation/inventory-idle-followup-native-2026-11-18.json).

<!-- LHO-RESTOCK-BANK-STACKS-LOADED-CLOSED-20261120 -->
20 November. R551 reloaded Forever and R552 confirmed the closed-bank path with the edited Restock source. All 21 positive counts matched native aggregates and FindStacks correctly returned no withdrawable stacks while closed. There was no Pending job or new Lua error. Open-bank stack acceptance and genuine Pending still need their respective live contexts. The character is in the Wizard's Sanctum, away from a banker. The resized client was recalibrated, R75 is active as process 30528 and logged two three-minute Space cycles. Character movement remains unverified. [Evidence](docs/validation/bank-tier-live-counts-2026-11-19.json).

<!-- LHO-RESTOCK-UNIQUE-BANK-STACKS-20261120 -->
20 November. Restock's live stack finder now visits each bank bag once per region, even when its display and fallback lists overlap. The direct regression went from five duplicate-inclusive entries and 14 charges to the expected three entries and nine charges. All five installed source hashes match. The running client still needs a reload and a real open-bank check. R550 separately verified 21 positive closed-bank totals against native counts. None of the 22 cached slots yielded a native slot record. The original cold-close race still needs a native trace. [Stack evidence](docs/validation/bank-tier-live-counts-2026-11-19.json). [Closed-bank evidence](docs/validation/lag-hotspots-provider-counterexamples-2026-11-14.json).

<!-- LHO-PROFESSION-SAVED-NEGATIVE-PREDICATE-20261120 -->
20 November. R543 and R544 compared a first ready source event on a real warm Tailoring reopen. Saved removal flags agreed across both alias keys, the live learned-only list and the spellbook for 369 IDs. The isolated getter loop took 6.61 ms versus 1.80 ms while learned and removal sets matched. The existing list optimization already covers settled list updates. The native source-counter probe armed, but its open commands stopped before input. Its timer expired and Tailoring is closed. Validate a fresh source boundary before reusing any saved flags, especially when metadata or spellbook updates arrive late. The runtime Lua was left as loaded. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-OBSERVED-REMOVALS-20261120 -->
20 November. Professions now only collects saved revocations relevant to the observed recipe ranking. The isolated native median fell from 0.529 to 0.413 ms, with all 102 winning references matched. After R536, both first and warm Tailoring opens preserved 102 rows, removal flags and event timing. The warm source/list sample took 16.47/8.24 ms and the larger frame spike remains open. Other clients and live crafting remain pending. Tailoring was closed and three-minute helper R74 resumed as process 2292. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-FIRST-TAILORING-PUBLICATIONS-20261120 -->
20 November. Native Tailoring first open showed source/list handlers at 16.75 and 12.76 ms in the same frame, followed by a 13.76 ms list handler. Nearby frame gaps reached 149 ms. Two warm reopens reproduced two synchronous scans. The stronger comparison retained each publication's arrays and found the same 102 learned rows and removal flags under the numeric and named keys. Isolate native learned-recipe and first-store work before changing event cadence. The output fallback never ran for these recipes. Tailoring is closed and all probes restored. The three-minute helper was verified running and logged a Space pair with movement unverified. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-COUNT-NEUTRAL-MOVE-BUILTIN-20261120 -->
20 November. R521 completed the same closed-backpack move on Forever with built-in inventory. All three tested profiles now match for this scenario. The 18-item stack was restored to 0:8, with one delayed update per direction and zero classifier scans. Restored both addon flags and verified both loaded. The three-minute helper resumed as process 10920. Continue the separate crafting, Auction Pending and client checks. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-COUNT-NEUTRAL-MOVE-PROVIDERS-20261120 -->
20 November. Real bag move and return passed with both addons loaded and with Syndicator alone. Both phases carried one touched item and zero changed counts. The checked Extra Button assignments matched and zero classifier scans ran. The 18-item stack returned to its original slot and the cursor was clear. Both addons were restored and verified loaded with all four enable reads at 2. The jump helper resumed as process 6572. The same native move on built-in inventory is still due. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-UTILITY-CONSUMABLE-RETRY-20261119 -->
19 November. The loaded Forever fix settled four utility consumables without delaying retries for incomplete item data. With bags and commerce closed, passive scans fell from 15 and 35.275 ms per six seconds to zero. The five checked consumable selections, counts and related Extra Button IDs matched. All five installed source paths match. The post-reload three-minute helper is process 33116. Continue real workflow and provider checks. [Evidence](docs/validation/consumable-non-restoring-items-2026-11-19.json).

<!-- LHO-NATIVE-BAG-REDRAW-OWNERS-20261119 -->
19 November. R496 and R497 captured a second real Forever Food receipt with the backpack already open. The food went 14 → 14 → 20 → 28 across three snapshots. All three redraws came through Baganator's bag-cache callback. The adapter took 0.093 ms total, notifications took 2.414 ms, and the observed deferred subscribers took 3.955 ms outside Notify. The first pulse had a 35 ms nearby frame. Compare full slot facts and live grid state before treating the first pulse as redundant. Both existing panels stayed open. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-NATIVE-FOOD-RECEIPT-20261119 -->
19 November. A real Forever Conjure Food start, cancel and completed cast added 14 food. The native and FluxUI counts matched. Two bag events had a nearby maximum frame gap of 28 ms. The two Baganator redraws took 16.988 ms total and synchronous FluxUI notifications took 1.432 ms. The observer cleaned up and both user panels stayed open. Trace each redraw's trigger and generation on the next real item change. First-open timing remains separate. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-REDRAW-FRAME-GAP-20261119 -->
19 November. R492 measured four paired redraws on an already-open Forever category backpack. The median nearby frame gap fell from 36.5 to 33.5 ms and the redraw median from 28.25 to 24.78 ms. The probe kept the backpack and item-text panel open and restored the timed function. No bag generation or error count changed. Next trace the first-open frame spike separately and capture real inventory changes and active workflows. The 180-second helper is still running as process 12028. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-SINGLE-CATEGORY-REFRESH-20261119 -->
19 November. Gear-set contents, the Equipment Set section and consumable preset categories now request one Baganator refresh through the public widget/search reasons. After reload, four Forever pairs reduced category update calls from two to one and median redraw time from 31.482 ms to 27.103 ms. Category order, item counts and view dimensions matched. No Lua errors occurred. The first-open display hitch is still separate. Next prioritize native workflow and frame-time checks across the client and provider matrix. The backpack was closed. The post-reload cue was confirmed and its jump supervisor began recalibrating. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-SHIELD-CONTEXT-20261119 -->
19 November. FluxUI's Baganator gear-set shields reuse the existing merchant and disenchant context during protection refresh. Four installed Forever pairs matched all 52 widget results. Context reads fell from 106 to two, and median refresh time fell from 0.882 ms to 0.791 ms. All five installed copies match. The first observed category backpack open in R473 took 54.80 ms with a nearby 72 ms frame gap. Baganator layout took 48.41 ms during the open. FluxUI's separate reveal refresh took 1.94 ms. Next isolate the larger layout spike and verify protection in an actual merchant or disenchant context when available. Both panels are closed. The 180-second jump helper is running as process 33828. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-PROFESSION-LEARNED-LIST-AUCTION-20261119 -->
19 November. Four native Forever Tailoring updates with Auction Restock open produced the same learned recipes, removal flags, visible and hidden rows, and potion targets as immediate full scans. Median combined time was 16.014 ms with the forced full scan and 12.798 ms with the installed settled path. Each half refreshed Restock once. All four inventory generations stayed stable and no Lua errors appeared. R466 narrowed the next target to the shared stock list, with a median 2.675 ms in the direct query and 4.704 ms in the instrumented row build. Profile the repeated tier, bank and reagent reads without weakening stock freshness. Both panels were closed, the empty target restored and the jump helper stayed active. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-CONFIRMED-UNLEARNED-20261119 -->
19 November. Settled owned-profession scans can skip full metadata reads for recipes previously confirmed unlearned when the native recipe list, filters and live spellbook still agree. On live Forever Tailoring, median isolated read time dropped from 4.157 ms to 1.173 ms and full metadata calls from 471 to 101. After reload, four native events paired with immediate full scans matched all learned rows and removal flags. Median total scan time fell from 13.293 ms to 8.346 ms. Next, check this path with Auction Restock open and exercise live crafting or recipe learning when available. The 180-second jump helper remains active without a PC idle requirement. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-NAMED-ALIAS-20261119 -->
19 November. The named profession save reuses the current scan's reconciled recipe references when the numeric and named aliases agree. Four paired saves on copies of the actual Forever Tailoring cache reduced the median from 1.225 ms to 0.890 ms. All 101 recipe records, alias order and removal flags matched. After reload, six native Tailoring events confirmed 101 matching records and separate saved arrays, with no new Lua errors. Ten syntax checks and eight regression scripts passed. All five installed sources match. The largest observed callback still reached 33.564 ms, with 31.275 ms in extraction and the first save. The next pass should isolate that portion using the native getter and first-store boundaries, keeping fresh learned flags. The 180-second jump helper resumed as process 25892. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-AUCTION-TAILORING-WARM-LOADED-20261119 -->
19 November. Eight native Tailoring updates rebuilt Auction Restock once apiece. The installed bag-tooltip path reduced the median Restock rebuild from 5.114 ms to 4.291 ms. The full handler medians were 21.504 ms and 21.258 ms, with overlapping samples. All visible and hidden rows and potion targets matched, four inventory generations stayed stable, and no Lua errors appeared. Tailoring and Auction were closed and the original empty target restored. The next hotspot is the portion outside the notification, which still took a median of 15.709 ms in the installed path. Separate live recipe getters from saved recipe reconciliation without skipping recipe learning, revocation or metadata recovery. The 180-second timer remains active as process 31072. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-WARM-BAG-TOOLTIPS-20261119 -->
19 November. Warm Auction Restock now shares nonempty native carried-bag tooltip text during a single row assembly. Consumable eligibility, missing metadata, item moves and changed providers keep their current checks. After reload, the three paired Forever rebuilds fell from a median of 4.455 ms to 3.767 ms. Visible and hidden rows and potion targets matched, the bag generation stayed stable, and no new Lua errors were captured. The source matches five installs, with 20 syntax checks and 43 regression scripts passing. The separate consumable readiness assertion fails identically on the checkpoint and candidate. The following entry records the natural Tailoring comparison. The 180-second timer resumed as process 31072 with no PC-idle requirement. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-COLD-TIER-SLOTS-20261119 -->
19 November. Auction Restock shares complete occupied bag slots during one cold target-list build. Empty and incomplete slots still receive fresh reads. Recipe and tier matching retain their original order and cadence. In the installed Forever comparison, the median fell from 13.324 ms to 9.882 ms across three pairs. All seven rows and potion targets matched, the bag generation stayed stable, and no new Lua errors were captured. All five installed source copies match. Thirty syntax checks and 38 regression scripts passed. Whole-frame FPS and native checks on the other installs remain open. Focus the next pass on the warm Tailoring callback. Retain stock freshness when mail or item data can change between events. The 3-minute jump timer resumed as process 4180 without a PC-idle threshold. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-IDLE-MATERIAL-PLAN-20261119 -->
19 November. Auction Restock skips craft-material assembly when the owner has no craft plans. In Forever, 256 calls on six actual visible rows took a median of 0.653 ms before and 0.044 ms with the early return. The full rebuild kept all seven rows and potion targets identical. This removes three temporary tables and a row traversal in the idle case. The saving was about 2.4 microseconds per rebuild on this character. All 35 auction regression scripts and ten Lua syntax checks passed. The source matches all five installs and Forever loaded the source in R433. Four ordinary carried reads matched their earlier values within each build, but timing varied. Skipping discarded food and water bag reads with saved references retained was also negligible in warm builds. Both read paths remain as installed. The warm synchronous Restock rebuild remains open. R433 replaced the pre-reload timer. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROFESSION-IDENTICAL-RECORD-MERGE-20261119-LOADED -->
19 November. Reloaded the installed profession merge change in Forever. The loaded Tailoring observer processed five updates and restored itself with a stable bag generation and no new Lua errors. All four retained result lines show 101 matching references in both aliases and identical revocation data. Displayed callback timings ranged from 13.676 to 23.003 ms. These unpaired timings do not establish a whole-handler gain. Tailoring was closed and the jump helper resumed. [Profession evidence](docs/validation/profession-bag-restock-2026-11-19.json). A separate settled Restock stock check found 21 saved bank IDs with known static classes, no pending classification on the bank IDs or Restock rows, and an empty mail snapshot. A populated inbox and live consumable usability remain separate dependencies. In particular, situational false usability results are deliberately uncached. [Stock evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROFESSION-IDENTICAL-RECORD-MERGE-20261119 -->
19 November. Profession storage skips the field scan when the prior and incoming alias already point at the same plain recipe record. Distinct records and custom tables still use the existing merge. All 101 actual named and numeric Tailoring recipe references matched. Six isolated native timing passes over those saved rows reduced the median for 16 merge-check traversals from 2.035 to 0.477 ms. The individual saving is about 0.10 ms per traversal, and the whole callback remains unmeasured. Nine existing regressions passed, the file matches all five installs, and loaded verification is recorded above. Continue with loaded alias parity and separate Restock invalidation. The current jump helper was left in place. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-AUCTION-SETTINGS-SAME-PASS-20261119-LOADED -->
19 November. The installed Auction Restock settings change was verified in Forever with Syndicator and Baganator. Three pairs against the original fallback halved tier-target reads from ten to five and reduced median callback time from 10.640 to 5.749 ms. All seven rows, potion targets and status text matched. No new Lua errors occurred. The jump helper resumed after the reload and both test panels and the original empty target were restored. Eight actual idle Tailoring events confirmed the separate passive hotspot. Preserving the existing rows during the callback reduced its median from 18.705 to 13.930 ms. The test ran the full rebuild immediately afterward outside the timer and confirmed exact parity. Mail expiration and late item data can change without a stock generation update, so this diagnostic bypass remains out of the addon. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-SETTINGS-SAME-PASS-20261119 -->
19 November. FluxUI now reuses the Auction Restock rows that a settings change just built when the initial planner still has the same stock, owners and clock. The existing guards retain fresh reads for other owners, receipts, pending or saved craft plans, unknown counts and changed inventory. Three paired comparisons of the real settings callback in warm Forever reduced two synchronous row builds to one and took a median of 10.177 ms versus 5.496 ms. All seven rows and potion targets matched. The test did not change a setting or transact. The initial cold probe hit an assertion because an ordinary native price lookup was still running. The measured pass waited for that lookup to complete and reported no new errors. The installed source matches five clients and all 35 existing auction scripts passed. Loaded verification is recorded in the following entry. The original target and window state were restored and jump worker 41660 is running. The idle Tailoring rebuild remains open. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-SETTLED-PAINT-20261119 -->
19 November. The six-row Restock repaint took 0.160–0.200 ms on the loaded Forever client. All six native size calls requested dimensions that differed from the current exact values. Checking dimensions before writing produced no consistent timing gain. All tested cell geometry and visible states matched, and no Lua errors occurred. The sizing path stays as installed. Prior native evidence places the larger cost inside rebuilding the stock rows. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-UNUSED-TIER-BANK-20261119-LOADED -->
19 November. Revalidated the installed Auction Restock change on Forever after a reload with FluxUI, BugTabs, Baganator and Syndicator. All six visible rows, the hidden row and potion targets matched the original fallback in three paired comparisons. The installed path eliminated 21 food and 21 water bank-tier match calls in a separate count. Timing medians were close at 4.688 and 4.661 ms. The bag generation stayed stable and no new errors were captured. The Auction House was closed and the original empty target restored. The three-minute jump helper resumed after reload. The remaining hotspot is the full rebuild triggered by idle profession notifications. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-UNUSED-TIER-BANK-20261119 -->
19 November. With Auction Restock and Tailoring open on Forever, six native Tailoring updates synchronously rebuilt identical Restock rows. The rebuilds spent 31.488 ms total inside 16.577–21.616 ms handlers. FluxUI now skips food and water bank-stock aggregation when its own Auction Restock path discards those rows, while keeping reference-tier evaluation and the original path for live banks, replaced providers or vendor craft plans. Three pairs using actual stock and preserving reference evaluation reduced the median row rebuild from 4.888 to 4.456 ms. All six shown rows and the one hidden row matched. All five installed copies match and existing regressions passed. The installed path was verified in the next entry. The rest of the repeated rebuild remains a hotspot. Next, verify the loaded guard and identify which profession notifications can leave the existing Restock rows in place. The three-minute jump worker is still running. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROFESSION-BULK-AND-LOADED-ALIAS-20261119 -->
19 November. Forever's GetProfessionSpells returned zero entries for Tailoring and Alchemy with five tested signatures, even though live recipe flags confirmed 101 and 23 learned recipes. The native filtered list matched the default views. Applying Have Materials hid all 23 learned Alchemy recipes while the learned toggle stayed enabled. The filter was restored. After reload, the installed unchanged-alias optimization kept all 101 Tailoring recipe references equal between its numeric and named entries in six displayed samples. Fifteen live profession publications cleared the craftability cache 60 times, including 15 clears after dispatch. No synchronous Craft.ListRecipesForKind work ran in those handlers. The six displayed handlers took 12.157–23.011 ms and were unpaired. Bag generation held steady, BugTabs counted zero new errors, and the observers and panel were restored. The helper was restored as host 25264 with the three-minute interval and no PC-idle requirement. The current profession source is loaded. The next branch investigation can measure Auction Restock refreshes while the profession panel is visible or another inventory path. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-UNCHANGED-ALIAS-20261119 -->
19 November. Quiet Tailoring produced 15, 5 and 5 native list events in three 36-second windows. The middle window bypassed only FluxUI's passive list handler. The source remained stable, bag generation held and the profiler restored its owner with zero new errors. FluxUI now skips copying an already reconciled recipe alias when the row references and removal flags match. Changed data and older saved entries with missing tables take the usual path. Three paired tests on eight live saved aliases reduced 16 repeat reconciliations from a median of 3.446 to 1.370 ms, about 0.130 ms per pass. One redundant alias copy was avoided. The source hash matches five installs, all ten syntax checks and five existing regression scripts passed, and loaded verification awaits a reload. A separate read-only query comparison matched 699 recipe flags across Tailoring, Alchemy and First Aid. The faster predicate narrowed Tailoring's median learnedness pass from 5.668 to 1.360 ms. These samples do not cover recipe learning, changing providers, late metadata or other clients, so the production scanner keeps the native recipe checks. Tailoring was reselected before the panel closed. The existing three-minute jump worker remains active. There was no reload in this pass. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-OBSERVED-RANK-20261119 -->
19 November. FluxUI now ranks ordinary modern observed recipe IDs directly into the saved-alias lookup. Legacy and unusual IDs retain the text-key path, as do replaced catalogue methods. On Forever, three paired tests matched 101 exact saved recipe references. Median for six lookups fell from 4.731 to 3.038 ms, which is 35.8%. The earlier shortcut that retained the ordered list had mixed timings and stayed out. After reload, the loaded Tailoring scan showed 101 matching references by name and numeric ID in six displayed callbacks, no new Lua errors and a stable bag generation. The unpaired whole handler still reached 39.977 ms. Current data proves the isolated lookup gain. The source matches all five installs and passed ten syntax checks. The allocation regression's stale function locator was corrected, and the baseline and candidate passed all 3,063 checks. Tailoring and chat are closed. The three-minute jump helper was restored as host 10920 under the no-idle policy after reload. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-IDLE-LIST-20261119 -->
19 November. With Tailoring open and Auction Restock closed on Forever, a 24-second hands-off window produced three native list refreshes at 7.49, 20.91 and 23.53 seconds. FluxUI spent 12.652, 13.336 and 13.709 ms in those handlers. No delayed bag, item-data or player cast event was observed. Bag generation stayed stable and the probe reported zero new errors. An earlier pass recorded 47 profession publications. The displayed comparisons kept all 101 recipe records and tombstones equal, including with the native Have Materials filter changed and restored. The displayed list handlers reached 38.023 ms while publication took under 1 ms. The main cost was inside the scan and store path. Observers were restored and the panel closed. The next candidate must preserve late metadata and genuine learned, unlearned and craftability changes. Runtime Lua was not changed in this pass. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-AUCTION-RESTOCK-STARTUP-20261119 -->
19 November. Auction Restock now reuses its first row build for the first synchronous scan when the data owners, inventory generations, and time boundary match. The search response still rebuilds the rows. In two paired warm Forever runs with Baganator and Syndicator loaded, median ShowSession fell from 12.603 to 6.954 ms (44.8%) and synchronous builds fell from two to one. Six visible rows, one hidden vendor row, the editor selection and the search-response refresh matched. Both warm panel pairs matched across 330,035 sampled pixels. The original build path remains available for charged or unresolved items, active receipts or craft work, unsettled inventory, and replaced data methods. Genuine Pending receipts and other native client/provider profiles still need validation. Both Lua files match across five installs and passed 20 Lua 5.1 and 5.4 syntax checks. The test observer was removed, the window was closed and the original empty target was restored. The three-minute jump helper was restored after reload and no longer requires 15 seconds of general PC inactivity. It still defers for chat, crafting, held keys or an input race. Three complete Space key pairs were recorded during the pass, with movement unobserved. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-NATIVE-AUCTION-LIFECYCLE-20261119 -->
19 November. Opening Forever's native Auction House Buy window for the first time after reload loaded Blizzard_AuctionHouseUI. The nearby frame gap was 118 ms on first open, 30 ms on warm reopen and 22 ms on the first close. FluxUI spent 0.231 and 0.090 ms attaching Restock, with no Restock row builds. The native observer expired before the second close, which was verified visually. Opening the actual FluxUI Restock tab took 25.407 ms inside ShowSession. Two synchronous row rebuilds took 8.979 and 8.630 ms, then the search response rebuilt the rows once more at 5.335 ms. All six displayed targets were stocked. The panel and original empty target were restored, and the observer reported no new Lua errors. Active Pending still needs a session with genuine receipts. [Evidence](docs/validation/auction-final-sku-2026-11-19.json). The 180-second helper host 41128 had seven complete Space key pairs at the check. Movement remains unverified.

<!-- LHO-AUCTION-ORDINARY-CHARGE-20261119 -->
19 November. Auction Restock reuses confirmed ordinary units only within one row rebuild with the original charge and potion-replacement methods and stable bag, bank and warband generations. Changed item IDs, charged items, unresolved data and open or unsettled bank contexts retain fresh reads. On the loaded Forever client, three paired full rebuilds with commerce closed matched six visible rows and one hidden vendor row on every run. Median elapsed time fell from 4.785 to 4.480 ms. The bag generation stayed stable and no new Lua errors appeared. Thirty syntax checks passed and the sources match across five client installs. Real charged stock, open Auction and Pending, and the other provider/client configurations still need native validation. [Evidence](docs/validation/restock-reagent-name-reads-2026-11-19.json). 19 November. The refreshed 180-second helper uses host 41128 (live20261119zi). It submitted one complete Space key pair at the check. Previous host 34796 stopped after seven pairs. Character movement remains unverified.

<!-- LHO-RESTOCK-REBUILD-ATTRIBUTION-20261119 -->
19 November. Three current Forever Auction Restock row builds took 13.465, 5.150 and 4.907 ms with commerce closed and the backpack open. The shared target builder accounted for 16.618 ms inclusive. Closed-bank tier reads took 4.026 ms and charge checks took 2.715 ms. Reagent-set lookups took 0.049 ms. The first observer setup used a missing spell API owner and left two temporary observers until the verified cleanup reload. The corrected probe restored its observers with zero new errors. A paired native check matched all 21 closed-bank item IDs. Reusing the ID union saved a median 0.279 ms per 12 rebuilds, so that candidate stayed out of FluxUI. [Evidence](docs/validation/restock-reagent-name-reads-2026-11-19.json). 19 November. Host 37328 recorded three complete Space key pairs before the diagnostic cleanup reload, including foreground and background activation. The cue was reinstalled. Current host 34796 (live20261119zh) recorded two complete key pairs. Character movement remains unverified.

<!-- LHO-AUCTION-RECIPE-LOADED-20261119 -->
19 November. The installed Auction Restock refresh on Forever used the grouped catalogue branch with five eligible carried item IDs. The same three learned inputs reached recipe verification in the same order. A single timed pair took 2.417 ms for the five per-item queries and 1.650 ms for the loaded refresh. The bag generation and Lua error count remained stable. Auction and Pending were inactive. Native price scan, real Pending work and other clients still need timings. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-JUMP-CURRENT-20261119 -->
19 November. After the observed Forever reload, the readiness cue was reinstalled and acknowledged. The running 180-second helper uses the renewed foreground policy. It can attempt a jump when WoW already has focus without a 15-second idle gate. It still waits for crafting, chat and physical input races to clear. Background activation still needs 15 seconds idle since targeted background Space did not move the character in previous tests. Read-only background calibration passed. Host 37328 (live20261119zg) is current. The first jump after reload remains unverified.

<!-- LHO-BACKPACK-REAL-UPDATE-20261119 -->
19 November. A real count-neutral bag move on Forever with Syndicator and Baganator produced one delayed bag event, a 6.40 ms inclusive Baganator view refresh, and 0.16 ms in FluxUI button-face callbacks. The ExtraButton grids kept the same selected items. The bag generation advanced once and the consumable classifier did no full rescan. The one 42 ms frame gap is unattributed. The temporary test tried to schedule restoration while the moved stack was locked. A follow-up after an independently observed reload verified the 18-item stack back in its original slot, the temporary slot empty and the cursor clear. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-AUCTION-RECIPE-BATCH-20261119 -->
19 November. Three paired live Forever comparisons matched three learned recipe references in order for five carried Restock outputs. The median recipe catalogue lookup fell from 1.856 to 1.029 ms when the comparison grouped records from one catalogue. Auction Restock now shares one ranked catalogue for five or more distinct eligible items. Smaller comparisons and replacement methods keep the per-item path. Both sources match across five installations and passed twenty syntax checks. The isolated measurement excludes the full Restock workflow. The exact isolated worker then matched all three live recipe records, reducing the single follow-up pair from 2.020 to 0.928 ms. The follow-up above confirms the loaded branch. Full native price-scan timing remains due. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CONSUMABLE-LOADED-QUEUE-MATCH-20261119 -->
19 November. In two six-second Forever samples with the backpack open, the loaded classifier removed 15 passive retries totaling 28.314 ms. The queue went from one item to zero. Food, water, healing potion, mana potion and bandage kept identical selected IDs, counts and grid button IDs. Both samples had a stable bag generation, restored the timed function and showed zero new errors. A diagnostic timer call to reload was blocked, then the ordinary /reload command succeeded. The three-minute cue was restored and its supervisor launched. Remaining work includes real inventory changes under this loaded classifier, Baganator layout attribution, and the other inventory workflows and providers. [Evidence](docs/validation/consumable-non-restoring-items-2026-11-19.json).

<!-- LHO-BACKPACK-FIRST-LAYOUT-20261119 -->
19 November. Restoring the prior backpack after the successful reload took 44.86 ms on its first observed open. Baganator layout took 41.45 ms inclusive and display was 21.60 ms inclusive. All 52 item-detail calls totaled 9.80 ms. The slowest item-detail call was 0.60 ms. The prior larger item interval did not recur. The backpack remained open. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-FREE-ACTION-POTION-20261119 -->
19 November. A live Forever check found that Free Action Potion was the sole pending consumable. It was loaded, exposed item spell 6615 and parsed with zero restoration. The matching food control still parsed as 1338 health. FluxUI now recognizes that exact item and spell after ordinary restore classification. Other tooltip states retain their existing retry behavior. The final Lua source matches across all five installations and passed ten compiler checks. Post-reload timing is pending. R326 is prepared for a suitable idle reload. Verify the installed negative, both grids and the passive read count. The previous jump cue disappeared. A new cue was installed and its 180-second supervisor started. [Evidence](docs/validation/consumable-non-restoring-items-2026-11-19.json).

<!-- LHO-CONSUMABLE-LIVE-RETRY-20261119 -->
19 November. A loaded Forever check confirmed cached rejection for Jungle Remedy, Southshore Stout and Tabetha’s Instructions. One other item remained in the classifier queue. With panels closed, 15 passive read-driven scans still ran in 6.01 seconds and took 28.944 ms inclusive. The prior open-panel sample took 36.094 ms at the same count. The samples differ in UI state. The follow-up had stable bag generation, zero pending native item loads and zero session errors. Identify the remaining queued item when WoW is drawable, then test whether it resolves after metadata or inventory changes. [Evidence](docs/validation/consumable-non-restoring-items-2026-11-19.json).

<!-- LHO-BACKPACK-OPEN-WARM-BOUNDARY-20261119 -->
19 November. The first observed Baganator backpack open after the intervening reload took 103.61 ms. Lost Supplies took 0.95 ms this time, including 0.02 ms for FluxUI slot protection and 0.03 ms for Junk. The rest of the first-open time is unassigned. The first probe attempted to close the backpack within the same frame, which Baganator suppresses. A follow-up restored the closed backpack. Two warm reopens took 4.18 and 3.88 ms, performed no item button repaint, and closed successfully on later frames. All three measurements held the bag generation steady and showed zero current-session errors. Trace the whole layout and all item details across a genuinely cold or bag-invalidated open. Use a later frame for closing every test open. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BACKPACK-WARM-CALLBACKS-20261119 -->
19 November. On Forever with Baganator and Syndicator, two warm FluxUI backpack callbacks took 0.518 ms across 48 occupied slots. The item-existence, GUID and cosmetic reads totaled 0.139, 0.092 and 0.232 ms respectively. The bag generation stayed stable and BugTabs reported zero new errors. Forever uses Baganator’s Retail-style live item button. GUID and equipment-set lookups finish before the 98.63 ms cold interval. The cold callback trace and installed-candidate repaint timing are pending. The same client showed fresh addon startup messages and closed UI panels. Verify the loaded Lua versions before replaying. The readiness cue was restored and the replacement three-minute worker is running. Windows refused the first activation request and the jump stayed queued. Character movement remains unverified. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-JUNK-CACHED-QUALITY-20261119 -->
19 November. Three paired native reads matched all 48 carried-item verdicts each time. Every sampled item had known non-gray quality. The isolated median was 0.148 ms for the original gray fallback and 0.013 ms when the probe used quality established before timing. One pair was slower. The Junk fallback now reads an already resolved non-gray quality when the Baganator caller supplies only an item ID. Gray, missing, restricted and replacement quality paths use the original rules. Both changed Lua files pass syntax checks across five installs. The live client still needs to load the change for full repaint timing. The prior cold single-item backpack hitch remains unassigned. Restock row equivalence is pending. The idle helper recorded three Space key pairs near its three-minute cadence. Character movement was unverified. [Evidence](docs/validation/junk-cached-quality-2026-11-19.json).

<!-- LHO-CLIENT-LOAD-AUDIT-20261119 -->
19 November. The scoped client load audit found all 181 direct manifest files and the same TOC in Retail, Forever, Classic, Classic Era and Anniversary. The audit pinned all five executable versions and compared 905 file entries. The 180 Lua files passed the Lua 5.1 and 5.4 checks after normalizing byte-order marks on ten temporary BuyEmAll localization copies. The BuyEmAll XML parsed. Native R306 stopped on a physical modifier during upload. The post-check verified closed chat and both panels intact. Repeat exact alias and Restock row checks when input is clear. [Evidence](docs/validation/inventory-client-load-audit-2026-11-19.json).


<!-- LHO-PROFESSION-ALIAS-OVERLAP-20261119 -->
19 November. On Forever, 471 native Tailoring recipe observations overlapped one of eight saved aliases. Three isolated paired four-sweep tests agreed on every alias. The prototype median fell from 1.577 to 0.627 ms per four sweeps. Profession scans now bypass the row and tombstone copy for ordinary aliases with no observed recipe or unlearned ID in common. Related entries and metatable-backed data keep the original merge. The modern spellbook predicate matched 471 current Tailoring flags. The legacy predicate missed all 101 learned recipes and the profession predicate marked all 370 unlearned recipes as true. Continue using the full live recipe flags. Lua 5.1 and 5.4 syntax passed across all five installations. The exact native follow-up was released before typing when the host detected a held key. Restock and Tailoring remain open. [Evidence](docs/validation/profession-alias-overlap-2026-11-19.json).


<!-- LHO-PROFESSION-BAG-RESTOCK-20261119 -->
19 November. With Tailoring and Auction Restock open on Forever, moving a stack out and back produced two delayed bag updates and five Restock builds totaling 45.959 ms. A second trace attributed the three additional builds to professions notifications. The three Tailoring handlers took 28.540, 20.529 and 33.149 ms inclusive. Both trials verified the original stack, empty temporary slot, clear cursor and zero new Lua errors. The profession scan now ranks saved aliases only for recipe keys observed in that scan. It still resolves revocations and rank ties across all stored aliases, uses the full public query if another owner replaces it, and preserves normal scans and notifications. Five paired native helper checks matched all 505 current Tailoring recipe references. The median fell from 0.891 to 0.581 ms with the key table prepared before timing. The source matches across five installs and compiled on Lua 5.1 and 5.4. Full event timing needs the candidate loaded. Restock and Tailoring remain open. The three-minute worker is live. Windows refused foreground activation, so the jump stayed queued. Continue the remaining catalogue read and separate professions-triggered Restock rebuilds. [Evidence](docs/validation/profession-bag-restock-2026-11-19.json).


<!-- LHO-CONSUMABLE-NON-RESTORING-20261119 -->
19 November. On Forever with Baganator and Syndicator, 15 unchanged consumable scans took 36.094 ms total in six seconds. The Combat Grid and consumable binding reads fed the retry loop. Native inspection identified three loaded non-restoring items in the retry queue. The classifier now settles Jungle Remedy and Southshore Stout when their native spells match the verified cure and alcohol effects. It settles Tabetha's Instructions when the complete read-only tooltip matches. Positive classifications run first. Missing and ambiguous tooltip data follow the existing retry path. The extracted candidate guard recognized all three live inputs and left the restoring food control eligible. Lua 5.1 and 5.4 accepted the source across all five installations. The client still needs a suitable reload and a matched passive timing run. Restock and Tailoring stay open. The R48 three-minute worker is running as PID 10224. Windows refused background activation, so the jump remains queued. [Evidence](docs/validation/consumable-non-restoring-items-2026-11-19.json).


<!-- LHO-RESTOCK-REAGENT-NAME-READS-20261119 -->
19 November. With the modern auction browser open, three current Restock row builds took 10.501, 6.066 and 5.032 ms. The shared target builder took 13.180 ms across those builds. A subsequent trace counted nine visible item-name harvests for three row builds, totaling 2.566 ms. Three paired reads of real inventory returned identical names and reduced native name requests from 207 to 69 per pair. Median for the isolated reads fell from 0.580 to 0.363 ms. FluxUI now shares available native item names within a single Restock rebuild and keeps every discovery pass. Missing values, merchant reads and replacement methods use their original paths. Both Lua files match across five installations and pass Lua 5.1 and 5.4 syntax. Loaded-source and full workflow timing still need a suitable reload. The R47 jump worker sent five Space pairs before its in-game cue went missing. R48 restored the cue and is live as PID 10224. Windows refused its latest request to activate WoW during an idle window, so it deferred the jump. Leave the current Restock and Tailoring windows as found. [Evidence](docs/validation/restock-reagent-name-reads-2026-11-19.json).

19 November. With Restock and Tailoring visible, three complete row builds took 5.926, 5.461 and 5.772 ms. All six visible rows and the hidden vendor row had identical fingerprints. A real count-neutral bag move triggered one delayed bag event and one touched-item pulse. The capture recorded two Restock row builds totaling 21.907 ms, two paints totaling 0.620 ms, one grid count flush at 0.155 ms and ten consumable scans totaling 28.042 ms. The nearby peak frame gap was 72 ms. The spans can overlap and the frame gap has no attribution. The move probe checked the new slots before the bag update and missed its automatic return. A separate native verification confirmed all 18 items restored to their original slot, the temporary slot empty and the cursor clear. Future timed moves must confirm the native slot update before deciding whether to return the stack. The Restock and Tailoring windows remain open. The recent source change still needs live adoption and an exact full-row comparison. The jump worker remained live and Windows continued to refuse background activation. [Evidence](docs/validation/restock-reagent-name-reads-2026-11-19.json).

After the stack was restored, R290 counted 20 natural classifyPendingRead passes in eight seconds with the original tooltip getter installed. The passes totaled 49.612 ms and peaked at 4.486 ms. All retained the published runtime table. Bag generation remained stable, the observer restored its method and BugTabs reported zero new errors. Focus on the normal eligibility and pending-read work. Preserve original getters during attribution. [Evidence](docs/validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-AUCTION-USE-FINAL-SKU-20261119 -->
19 November. R266 verified the selected Forever profile with FluxUI, BugTabs, Baganator and Syndicator. Its first observed backpack open took 37.14 ms with a nearby 55 ms gap. R267 matched seven ordinary auction rows across three pairs. The earlier charged-row compatibility audit shows replacement callbacks can read the preliminary units, so the auction source was restored from its dated checkpoint. All five installs match dc7edb6d. R268 confirmed Forever was already running that implementation and counted 14 unit calls across six visible and one hidden vendor row. Next capture a normal bag event with both Extra Button System grids, then continue active Pending and the remaining inventory workflows. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

A five-second Forever capture with FluxUI, BugTabs, Baganator and Syndicator recorded 12 passive consumable validation passes. It made 180 tooltip reads. In the same pass, 72 repeated an identical item ID and link, and the returned text matched on all 72. The pass total was 38.980 ms, the slowest was 3.744 ms and the 180 tooltip reads accounted for 26.765 ms inclusive. The nearby peak frame gap was 36 ms. The probe restored both wrapped methods with stable bag generation and zero new Lua errors. R274 attributed the 24 repeats across four natural passes to the saved-reference fallback. Both R270 and R274 replaced GetTooltipText, which is pinned by Persist.EligibilityOwnersMatch. That change disables existing same-pass reuse and accounts for the repeated checks. R276 kept the tooltip owner intact and observed zero scans in 5.012 seconds with the auction browser open. Preserve the guarded reuse. A normal-path sample with active classification remains needed. The R47 jump worker PID 36164 now handles the current four-addon setup. It submitted two Space pairs, with the second deferred briefly for recent input. Character movement is unverified. [Evidence](docs/validation/auction-final-sku-2026-11-19.json).

<!-- LHO-BACKPACK-FINAL-CALLBACK-20261119 -->
19 November. Forever loaded ItemViews 6833655b at callback line 184 after a reload outside this test. R249 had already compared the exact index against the prior function with 55 visible buttons and matched their order. R250 restored the backpack after Baganator ignored an attempt to close it on the same frame. R256 and R257 measured a 169 ms first-open frame gap and 29 ms warm gap. Item 6172 spent 98.63 ms between the first quest callback return and final callback entry. The measured interval ends before item-spell lookup. R258 confirmed mark-unusable off, no upgrade plugin, no named classic scan tooltip, FluxUI as the configured Junk provider, and Lost Supplies class 12. R259 is prepared to measure the actual Flux Junk callbacks on the next cold open. Preserve exact native API owners and measure before editing. R39 jump worker 21428 is running after the reload. Active Pending, bank, mail, casts, other providers and other clients are still in scope. [Evidence](docs/validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-ITEM-REGISTRATION-INDEX-20261119 -->
19 November. R244 confirmed the production bank-view callback at line 65 and the old jump cue was gone. R246 confirmed full closed-commerce Restock target parity after reload, with a 14.899 to 3.330 ms median and nine identical rows. R245 timed the exact ItemViews candidate using four closed-bag visibility traversals per half of each pair. The median fell from 2.773 to 1.330 ms. All 550 registered button references retained order and there were no visible buttons. ItemViews 6833655b is on disk in all five clients. The next eligible reload and open backpack and bank checks should verify production visibility with actual buttons. The first-open 209 ms frame hitch, active Pending and the other provider and native-client combinations remain open. The session remains in place with the R37 jump worker PID 12080 and 180-second cadence. R247 recorded 1,227 frames with a 50 ms peak and zero scoped events. The attempted open-backpack check stopped before input when foreground activity was detected. [Evidence](docs/validation/baganator-item-registration-index-2026-11-19.json).

<!-- LHO-BAGANATOR-BANK-VIEW-INDEX-20261119 -->
19 November. The bank view index is on disk with five matching client hashes. R242 measured a 13.565 to 2.817 ms median reduction in full shared Restock targets with closed commerce windows. All fields in nine rows and both bank view callbacks matched. The same client was active again by the final check. R244 and R246 confirmed production adoption. Check late bank view registration, live versus cached views, Pending and other provider setups. The previous backpack hitch is still 209 ms in R234 and remains separate. Jump worker 40692 was verified live with ten Space key pairs and a recent PC-input deferral. This turn left the current session running. [Evidence](docs/validation/baganator-bank-view-index-2026-11-19.json).

<!-- LHO-PARSER-VENDOR-LIVE-20261119 -->
19 November. The previous parser and vendor changes are live on Forever. R233 saw line 840 and confirmed the old temporary jump cue had cleared. R230 matched the R226 digests and counts. R234 reproduced a 192.31 ms observed bag open with a 209 ms gap and no addon load events or new modules. Move the next cold-backpack trace to native item data and callbacks after the quest update. The shared Restock target builder remains the actionable commerce seam. R237 recorded 21.264 ms out of 23.826 ms, while the no-job sample cannot cover Pending automation. Keep active Pending, cast, crafting, vendor, bank, mail, other client and provider acceptance in scope. R35 worker 40692 is live on the exact Forever window, with three Space key pairs and all chat reservations released. [Evidence](docs/validation/parser-vendor-live-2026-11-19.json).

<!-- LHO-RESTORE-PARSER-PATTERNS-20261119 -->
19 November. The consumable parser and prior vendor metadata changes are ready on disk in all five installs. R226 documented the loaded baseline. The guarded reload reservation R228 was released after PC input resumed. At the next idle reload, restore the currently open backpack while watching for synchronous addon-module loads with R229 or a fresh equivalent. Then run R230 to compare 42 bag counts, 18 parser records and 42 vendor field digests against R226. Continue measuring the full retry with normal owners intact. The old three-minute jump worker PID 29940 was stopped for the planned reload. No reload occurred. Supervisor PID 16796 confirmed the retained cue and launched a new running worker on 19 November at 06:02:44 UTC. Windows reused PID 29940. Host command and creation time verify the new process, which still defers during recent PC input. R35 is ready if a later reload clears it. [Evidence](docs/validation/restore-parser-patterns-2026-11-19.json).

<!-- LHO-LIVING-CONSUMABLE-RETRY-20261119 -->
19 November. Forever R223 established a living-character baseline with normal eligibility owners. Eight periodic retries took 44.914 ms in all, with a 7.043 ms peak. The earlier caller counts can include extra checks caused by replacing a guarded tooltip function. Keep its identity pinned when validating a candidate. [Evidence](docs/validation/living-consumable-retry-2026-11-19.json).

<!-- LHO-VENDOR-FIELDS-ONCE-20261119 -->
19 November. The vendor metadata reader change is on disk in all five client installs. Forever R217 and R218 verified the improvement with real carried items, with R218 testing the exact new source against the still-loaded prior function. Leave the active session in place. On a natural or guarded idle reload, verify the installed reader on live vendor Restock and Junk rows, using Shift to skip merchant automation on opening. The cold backpack still needs a genuinely cold module-load trace. Continue remaining casting, crafting, bank, mail and active Pending acceptance. Jump worker 29940 remains active and queues requests around busy PC input.

[Evidence](docs/validation/vendor-fields-once-2026-11-19.json).

<!-- LHO-BACKPACK-SINGLE-SLOT-20261119 -->
19 November. Two cold backpack traces narrowed the largest hitch to one item-detail call. The first slow call took 102.84 ms. On the second, item 6172 was the nineteenth detail call. It spent 96.94 ms between the quest update return and the first cooldown update entry, with 8,779.6 KiB of Lua heap growth across the call. The addon-load test stopped before opening because the existing group state changed, and the next attempt stopped before input when the user resumed playing. The new background screenshot showed the character alive near a vendor. Verify a fresh cold state before repeating the load-event trace. Keep live vendor, cast, item receipt and Pending checks in scope. Jump worker 29940 was verified live earlier in this slice and retains its idle checks. [Evidence](docs/validation/backpack-single-slot-2026-11-19.json).

<!-- LHO-RESTOCK-SETTINGS-GET-20261119 -->
19 November. Restock now skips the migration helper for an already-migrated character. The native paired getter samples were 30.3 percent faster at the median. All 88 sampled Junk decisions matched and the full Junk timings varied. Reload 206 returned to the Forever world and the live getter returned the same initialized store. The three-minute worker is running again. The character remains a ghost. The first backpack open still took 149.69 ms with a 161 ms frame gap. The nearest native profiler sample reported 5.96 ms total addon time, and the application alone added an over-50 ms sample. Continue tracing native widget or client work that can account for the gap, alongside live inventory, Pending and commerce acceptance. [Evidence](docs/validation/restock-settings-get-2026-11-19.json).

<!-- LHO-ITEM-INFO-ONCE-20261119 -->
19 November. The shared item metadata loader now reads the native tuple once per FluxUI cache miss. Reload 201 loaded the update and check 203 matched all 42 observed metadata records and bag counts. The corrected check preserved one attributed temporary diagnostic error from 202. Both external addons are loaded and the three-minute jump helper is running in the same background Forever window. The character remains a ghost. The first-open bag hitch still needs direct attribution, and living cast, item receive and commerce acceptance remain open. [Evidence](docs/validation/item-info-once-2026-11-19.json).

<!-- LHO-BACKPACK-FLUX-COMPAT-20261119 -->
19 November. With Syndicator and Baganator active, the first category backpack open took 150.21 ms with a 161 ms frame gap. The warm open took 5.77 ms. Baganator Display contributed 123.88 ms inclusive. Across the first open, the timed FluxUI calls were 102 Junk checks at 3.79 ms and one view lookup at 0.03 ms. The other selected category and protection callbacks did not run inside the synchronous open. Both closes succeeded and all wrappers restored with zero errors. The first-open hitch still needs deeper attribution. The probe covered synchronous opens only, so deferred work remains open. A delayed follow-up after reload 201 kept the host screenshot capture outside both timed opens. The first open still took 151.67 ms with a 169 ms frame gap. The warm open took 5.14 ms. The backpack returned to its closed state and the probe produced zero new errors. [Evidence](docs/validation/backpack-flux-compat-2026-11-19.json).

<!-- LHO-CONSUMABLE-TOOLTIP-DURATION-20261119 -->
19 November. Food and drink classification is optimized in the loaded Forever client. All nine carried-tooltip verdicts matched in the paired test. The loaded full parser produced the same nine-record digest before and after reload 197. Both external addons are loaded. The three-minute helper resumed, with one Space pair verified and movement unverified. The character remains a ghost in Dustwallow Marsh. Live living-character retry timing is pending. Continue the unresolved first-open backpack item cost and active Pending, vendor, mail, bank and cast checks. [Evidence](docs/validation/consumable-tooltip-duration-2026-11-19.json).

<!-- LHO-BACKPACK-ITEM-UPDATE-COST-20261119 -->
19 November. Forever's category backpack first open took 155.39 ms, with a 167 ms frame gap. Baganator's 54 item-detail calls took 117.61 ms. Acquiring 55 pooled buttons took 0.55 ms and reported zero new frames. The retry measured 123.06 ms across the same 54 detail calls. FluxUI Junk checks contributed 2.96 ms in that retry, and the instrumented quest, cooldown and context methods each took under 3 ms.

The native combined backpack first open took 155.73 ms with a 166 ms frame gap. The item update took 125.85 ms, and 18.54 ms was inside the observed button methods. Junk accounted for 12.57 ms in that group. A separate read of all 76 carried slots with the backpack closed took 0.63 ms for item data and 0.14 ms for quest data. The closed-bag read ran after the automatic spirit release with both addons enabled. It leaves cold first-open metadata behavior unverified.

The character died after the native capture finished. The release timer elapsed and the character is at the graveyard as a ghost. The first deeper probe encountered Syndicator's frozen Search API. A reload cleared that probe, and the instance-level retry reported zero errors and zero restoration failures. Both provider flags were restored and the idle jump helper is running. The measured backpack hitch remains open. Continue investigating nearby item widget and per-addon work, and use the prior measurements for separate Pending, consumable retry, cast and inventory integration fixes. [Evidence](docs/validation/backpack-item-update-cost-2026-11-19.json).

<!-- LHO-NATIVE-BACKPACK-JUNK-GLOW-20261119 -->
19 November. Forever allocated 76 hidden Junk glows on the first native combined backpack open. The corrected probe identified FluxUI's specific glow texture and found zero instances before open, 76 immediately after open, and 76 after warm reopen. `FluxJunkOverlay.lua` now creates the glow on its first visible use and reuses it on later paints. The coin path and repaint timing are unchanged.

The same backpack test after reload found zero allocated glows. The before and after opens each ran 112 Junk checks with zero positive verdicts, matched all 76 visible slot positions and frame dimensions, preserved the bag generation and restored the closed state. Both samples reported zero Lua errors. The positive display transition, bank buttons and other clients still need native coverage.

The first open took 155.23 ms before and 157.93 ms after, with frame gaps of 164 and 169 ms. The warm opens took 24.74 and 27.66 ms. The pair confirms fewer allocations and provides no timing improvement. `UpdateItems` still accounted for 125.00 and 128.57 ms on the first opens. Measure item and quest reads, the quality and extended appearance path, then cooldown and tooltip work separately. Continue the Pending, mail, bank, vendor, receive, craft and cast checks. Both external addons were verified loaded with all four original enable readings restored. The idle-only three-minute jump worker resumed. [Evidence](docs/validation/native-backpack-junk-glow-2026-11-19.json).

<!-- LHO-NATIVE-BACKPACK-JUNK-QUALITY-20261119 -->
19 November. On Forever with Syndicator and the native combined backpack, the original first open took 156.52 ms and coincided with a 164 ms frame gap. Across its first and second opens, native `UpdateItems` accounted for 136.83 ms inclusive. Of that, 127.31 ms fell outside the explicitly nested observers. This remainder can include unmeasured Lua descendants. FluxUI Junk display checks accounted for 16.69 ms across 224 calls.

The warm baseline found 194 native Junk fallback calls, all on slots with known non-gray quality and all returning false. `FluxJunk.lua` now returns that result directly for ordinary slot tables with a readable numeric quality above poor. Explicit and rule-based Junk decisions still run through their existing entry points. Gray and unresolved slot qualities follow the existing checks.

Across two warm opens, fallback work fell from 1.1866 ms for 194 calls to 0.2709 ms for 196 calls. The 224 display checks took 6.77 ms before and 3.79 ms after, and observed settings reads fell from 1,682 to 1,285. Slot order and geometry signatures matched. The bag generation and final closed state were preserved and all captures reported zero errors. One before and one after warm sample across reloads establish the scope of this observation. Positive gray or unknown quality and other clients still need native checks.

The first open after the edit still took 150.95 ms with a 159 ms frame gap. Trace allocation and layout separately from the valid-slot loop in `UpdateItems`. The pinned Forever source places the container and quest metadata reads before texture, appearance, quality, extended state, badges, context, cooldown, tooltip and search. Measure a few of those item work groups per pass before deciding where another FluxUI optimization fits. Keep the Baganator category layout and Pending, mail, bank, vendor, receive and cast validation open. Both external addons were restored and verified loaded with their original character and overall enable flags. The idle-only jump worker resumed. [Evidence](docs/validation/native-backpack-junk-quality-2026-11-19.json), [Forever source](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua#L1189).

<!-- LHO-COLD-BACKPACK-PROVIDER-MATRIX-20261119 -->
19 November. The first backpack hitch reproduced across all three supported Forever provider configurations. Syndicator alone opened the native combined backpack in 155.7002 ms with a 163 ms frame gap. The built-in provider opened the same frame in 150.7081 ms with a 158 ms gap. Their second opens took 25.7392 and 25.6534 ms, with 34 and 36 ms gaps. Both samples opened and closed twice, retained the bag generation and reported zero Lua errors.

Both addons were restored and verified loaded. The active provider was Syndicator and all four original character and overall enable readings were 2. The restored Baganator category backpack still took 150.0066 ms to open, with a 162 ms gap. Its display call took 122.95 ms, of which 122.19 ms fell outside the explicit nested observers. That remainder still includes other descendants. The shared cold hitch does not require either external addon. The native display and FluxUI hooks need separate measurements before any runtime change.

The first test set the character flag, but the timer-driven reload triggered a blocked action in Forever. A direct guarded reload applied that flag. All measured provider sessions had script profiling off. The current jump helper has been rearmed and verified live. [Evidence](docs/validation/cold-backpack-provider-matrix-2026-11-19.json).

The next shared target is the native combined backpack's first and warm opens. Time the public combined bag update, item layout, item painting and FluxUI overlay and header calls under the same first-open scenario. Use the existing guard/reload flow and keep the Baganator and Syndicator flags restored at the end. Keep the separate Pending, mail, bank, vendor, receive and cast verification open.
<!-- /LHO-COLD-BACKPACK-PROVIDER-MATRIX-20261119 -->

<!-- LHO-BAGANATOR-COLD-OPEN-JUNK-20261119 -->
19 November. With Syndicator and Baganator loaded in Forever, the first category backpack open took 155.4001 ms and coincided with a 168 ms frame gap. Reload 146 reproduced it at 159.3961 ms with a 172 ms gap. Baganator's inclusive category layout took 158.35 ms across the two opens. That timing includes callbacks. The measured FluxUI Junk display callback totaled 4.89 ms over 102 calls. Warm opens took 5.47–7.83 ms and did not invoke the Junk callback in the warm trace. Both opens and closes restored the original closed state and retained the bag generation.

FluxUI now reuses the same per-call junk-list mark for protection and explicit decisions, including the native gray fallback's own check. Per-slot protection, the legacy string key, gray quality and value checks, and the freshness of separate fallback calls are preserved. Lua 5.1 and 5.4 passed and the five installed source copies match.

Reload 150 loaded the change. A warm read over 44 occupied slots cut Restock settings reads from 252 to 170. Both slot-order outputs were entirely false and all observers restored with zero Lua errors. The two unwrapped warm follow-ups took 0.3190/0.3319 ms before and 0.2652/0.2601 ms after. The instrumented read was slower after reload. The result proves fewer settings reads in this workload. The post-change first category backpack open still took 149.1494 ms with a 161 ms frame gap. Junk verdicts were already warm and the measured timing is an unmatched observation. The frame hitch persists. Positive junk marks, other addon combinations and other clients still need native checks. [Evidence](docs/validation/baganator-cold-open-junk-2026-11-19.json).

The current Forever session is running in the inn with both external addons loaded. The three-minute jump helper was rearmed after reload 150 and the first key receipt passed. A later reload clears the cue. Use the current host ownership markers when pausing. The next comparison is the cold backpack transition with Baganator disabled, first with Syndicator and then with the built-in provider. Restore the original addon enable states afterward. Continue independent commerce, Pending, bag and mail verification when available.
<!-- /LHO-BAGANATOR-COLD-OPEN-JUNK-20261119 -->

<!-- LHO-RESTOCK-BANK-NONCONSUMABLE-20261119 -->
19 November. A current Forever Auction Restock rebuild took 19.1985 ms, with 13.2688 ms attributable to five bank-tier totals. The closed bank supplied 17 known non-consumable IDs and four consumable IDs. All 17 excluded classes had positive counts whose reads took 3.9094 ms. The follow-up found 105 classifications and zero matching usability checks.

The shared tier matcher now skips the quantity read only when the original classifiers and matching rules rule a known non-consumable out of all tiers. This exclusion lives within one reliable closed-bank list build. Unknown metadata, open banks and replacement providers retain the original path. Native zero counts are never memoized. No new timers or refresh events were added. Both Lua syntax versions pass and the Retail and Forever source hashes match.

After reload 142, two live paired rebuilds in opposite order improved from 31.0528 to 15.4413 ms and from 21.6121 to 17.6776 ms. The paired reads matched every field across nine shared, six visible and one hidden row. Each candidate skipped 17 quantity reads and retained four positive bank quantities. Both generations held, temporary observers restored, and the error count was zero. Commerce windows were closed and there was no active Pending job. Overall FPS spikes and the other client families still need direct verification. [Evidence](docs/validation/restock-bank-nonconsumable-2026-11-19.json).

The matcher file hash matches in the Retail, Forever, Classic, Classic Era and Anniversary installs. Host process enumeration showed only two Forever windows. The test client was last verified in the inn after reload 142. Seek native coverage of live vendor, bank and mail transitions and event-time hitches. The idle Pending getter is already measured. Its active job path remains unverified. The three-minute jump helper is running for this exact Forever process after live background cue calibration. The first key pair cleared Away and the previous app returned to the foreground. A reload clears the in-game cue. Future input uses the shared ownership lock and the helper defers while chat, crafting or user input is active.
<!-- /LHO-RESTOCK-BANK-NONCONSUMABLE-20261119 -->

<!-- LHO-RESTOCK-CLOSED-BANK-COUNTS-20261119 -->
19 November. The idle Pending getter took 0.0146 ms and returned no bank targets. The shared Restock list was the larger cost. The five tier bank totals accounted for 28.115 ms of one 31.8841 ms rebuild. The next native read found 105 positive bank quantities for 21 distinct IDs, with all 84 repeated results agreeing.

Restock now shares positive closed-bank quantities within one list rebuild for the original count owners. Bag and bank generations guard reuse, and open or unsettled inventory retains the original queries. Both Lua files pass Lua 5.1 and 5.4 syntax and match the Forever files. Reload 138 returned to the world. In two opposite-order live Auction House data comparisons with commerce windows closed, the full rebuild took 46.4809/34.6308 ms before and 18.2090/19.5612 ms after. All fields matched across nine shared, six visible, and one hidden vendor row. Each candidate rebuilt its own 21 positive quantities. Both generations held, the observers restored, and zero errors were reported. Active Pending jobs, open commerce windows, other clients and overall frame spikes remain unverified. [Evidence](docs/validation/restock-closed-bank-counts-2026-11-19.json).
Last verified client in the inn. Active Pending requires real job data and remains open. Keep shared and inactive samples scoped to the tested paths. Input reservations released, jump host stopped.
<!-- /LHO-RESTOCK-CLOSED-BANK-COUNTS-20261119 -->

<!-- LHO-BANK-TIER-LIVE-COUNTS-20261119 -->
19 November. After the Forever world refresh, one native tier build queried 290 positive bag quantities across 51 item IDs. All 239 repeated results agreed. The bank builder now shares positive counts across tiers within that one rebuild, using the existing public path during reliability holds or with replacement providers. Zero and fallback reads remain live.

Both Lua files pass Lua 5.1 and 5.4 syntax and match the installed Forever copies. Reload 133 returned to the world. Two opposite-order live comparisons reduced tier rebuilds from 16.0921/15.2402 ms to 10.1717/11.1664 ms. Each candidate build used 51 distinct positive counts. All five tier totals matched in both comparisons, neither returned withdrawal rows, and the observer restored with zero errors. This covers the closed-bank rebuild. [Evidence](docs/validation/bank-tier-live-counts-2026-11-19.json).
Open-bank target rows, hover, withdrawals and the Pending path are still pending. Latest native client is still in the inn, verified after the world refresh and reload. All this turn's input reservations were released. Jump host is still stopped.
<!-- /LHO-BANK-TIER-LIVE-COUNTS-20261119 -->

<!-- LHO-BANK-TIER-MATCHER-20261119 -->
19 November. The Forever Bank Restock tooltip's first read took 44.7333 ms for four rows. All four had Count Bank off. The warm read took 1.1500 ms. The 39.9320 ms registry build included 39.712 ms in the consumable tier builder. A follow-up found 250 usability checks, with 135 tooltip reads taking 22.1383 ms before matching native unusable answers.

The tier matcher now checks numeric non-consumable metadata against the defining classifiers before running usability. Unknown metadata, consumable classes and replacement methods keep the existing matching path. Lua 5.1 and 5.4 syntax pass. Retail and Forever file hashes match. Native 129 confirmed reload and world return. Two same-session Forever pairs in opposite order reduced tier rebuilds from 43.3845/44.7337 to 13.8876/15.3005 ms. Usability calls fell 250→90 in both. All five tier totals matched in each pair. Both builders returned zero tier withdrawal rows, all temporary functions were restored, and error counts were zero. Bank-open, eligible withdrawals, active Pending, other clients and frame-spike acceptance remain open. [Evidence](docs/validation/bank-tier-matcher-2026-11-19.json).
The duplicate bank display read and active Pending path were not exercised. Do not change Count Bank or create a purchase job to force either. Client was in the inn, with roughly five minutes to a world refresh. Recheck session and background input ownership before the next capture. Jump host remains stopped.
<!-- /LHO-BANK-TIER-MATCHER-20261119 -->

<!-- LHO-EBS-BAG-COUNT-PULSE-20261119 -->
19 November. On Forever 1.60.1/70959, reload 120 returned to the world and loaded the current Containers.lua and Mail/Restock.lua revisions. Probe 122 moved and returned Roast Quail ×18. All six slot diffs matched both outputs. Bag generation advanced 5→7, the original slot and count were restored, the destination and cursor were empty, and BugTabs reported zero errors. Both EBS pulses touched the moved item with no total count change. Slot-diff totals were 0.0702/0.0562 ms with asymmetric instrumentation, and EBS baseline paint totaled 0.3059 ms. This is one live event pair. Native frame spikes and the populated mail path remain open.

EBS Paint.lua `808e15ec` → `7bcb33ab` now iterates the same faces in the count pass without allocating a closure or calling it per face. The button and badge order, per-face checks and synchronous delivery are preserved. Before/after Lua 5.1 and 5.4 syntax passed, and Retail and Forever disk hashes match. Reload 123 loaded the edited painter in Forever. Probe 124 repeated the exact item move and return with two matching bag paints and zero reported errors. EBS totaled 0.3059 ms before and 0.3577 ms after. Both slot-diff totals also rose in the second capture. Timing varies across the two reload-separated samples, so the measured benefit remains unverified. The jump helper remains stopped. [Evidence](docs/validation/ebs-bag-count-pulse-2026-11-19.json).
The bank tooltip separately reads the availability and display totals for the same ordinary item row when Count Bank is enabled. Tier rows have different fallback rules. Trace the live Bank Restock tooltip and Pending target publication before changing either path.
<!-- /LHO-EBS-BAG-COUNT-PULSE-20261119 -->

<!-- LHO-SLOT-DIFF-TOUCH-20261119 -->
19 November. `Inventory/Containers.lua` `d043cfe0` → `372664bf` simplifies the shared built-in and Syndicator slot-diff path. The old-slot pass records same-item count and link changes. The new-slot pass on normalized maps only needs to mark new slots and replacement IDs. Both delta loops retain their original arithmetic and order. Map metatables retain the full comparison. Provider coordination and count delivery cadence stay in place.

Lua 5.1 and 5.4 passed for both files in the before/after check. Retail and Forever disk copies match. Native 119 was a read-only view of fresh raid join and leave activity. No test command, item move, jump or reload was sent in this slice. The next live proof needs a safe opportunity to reload, then a real bag or bank update on the new revision. Earlier cast-to-bag and item move captures remain valid for their dated source sets.
[Source and current native evidence](docs/validation/inventory-slot-diff-touch-2026-11-19.json).
<!-- /LHO-SLOT-DIFF-TOUCH-20261119 -->

<!-- LHO-RECIPE-PAIR-MAIL-QUEUE-20261119 -->
19 November. Forever native 118 paired the loaded modern recipe lookup with its full-catalogue fallback in the same session. Three passes over 147 eligible saved recipes returned the same knownness and exact saved record in all 441 pairs. Median pass total fell from 138.5646 ms to 43.3418 ms (68.7%). Both method identities were restored and the session error count was zero. The fallback used one forwarding call. The longest diagnostic batch took 5.902 ms. Full workflow and frame-spike timing remain open.

`Mail/Restock.lua` `09f764dc` → `952b6a19` creates the action row only on the first matching restock attachment. An eligible message with no match now allocates none of the three queue tables. It contributes the same attachment counts to the authority scan. Header and attachment reads, scan budget, COD and GM checks, retries and publication stay intact. Before/after Lua 5.1 and 5.4 syntax passed. The Forever disk copy now matches, and native adoption is pending. The existing populated-mail authority decision remains open. No new simulation, item action or jump was performed.
[Native recipe comparison](docs/validation/modern-recipe-paired-native-2026-11-19.json). [Mail source and verification](docs/validation/mail-lazy-queue-rows-2026-11-19.json).
<!-- /LHO-RECIPE-PAIR-MAIL-QUEUE-20261119 -->

<!-- LHO-FIXED-RECIPE-SLOTS-20261119 -->
18–19 November. Auction craft planning now appends each fixed reagent to its private variant in place. This removes the prefix copies for single-option slots. Multi-option expansion, the 64-variant cap, allocation order and native recipe verification stay on their existing paths. `FluxAuctionRestockCraft.lua` changes from `8462442f` to `143c59c1`. Four before/after Lua 5.1 and 5.4 syntax checks and six Retail/Forever disk hash comparisons passed.

Forever reload 115 completed and native 116 returned the same IDs, yield, variant count and slot count for actual bandage items 8544 and 3530. The two individual full-query pairs were 0.9445→1.0710 ms and 0.7717→0.7018 ms. Native 117 confirmed recipe 18560 known with one reagent and a present item 1191 hyperlink matching the snapshot with the bank closed. Current build was 1.60.1/70959/16001 with the Syndicator provider and zero session errors reported. All accepted reads were visually confirmed and released. No craft, item transaction, profiler setting change or jump occurred. Full field, frame-spike, multi-option and remaining workflow/client checks stay open. No further reload is needed for these exact source files while the current session remains loaded.
[Exact files and live results](docs/validation/fixed-recipe-slots-2026-11-19.json).
<!-- /LHO-FIXED-RECIPE-SLOTS-20261119 -->

<!-- LHO-BANK-SNAPSHOT-LINK-20261118 -->
18 November. Cold item metadata can fall back to one link from the bank and carried snapshots. Index.lua (`e2f7919a` → `452aa904`) and FluxRestock_Inv.lua (`4488ee52` → `f3890c5e`) now read that link in the same carried, character bank and supported warband order without allocating an item map or its per-item records. The existing live stack check runs first. Replacement public getters keep the full-map path.

Eight before/after Lua 5.1 and 5.4 syntax checks passed. Both edited files match the Forever copies on disk. After the diagnostic text closed, native 113 queued two read-only queries. The output capture guard stopped during a focus change. An independent screenshot showed fresh startup messages and a group invitation, with neither result visible. The reservation was released. Native adoption and timing of the link and modern recipe lookups remain pending, as do the stale closed-bank case and populated-mail authority decision. The full goal stays active.
[Exact source, observed client state and validation limits](docs/validation/bank-snapshot-link-2026-11-18.json).
<!-- /LHO-BANK-SNAPSHOT-LINK-20261118 -->

<!-- LHO-MODERN-RECIPE-KNOWLEDGE-20261118 -->
18 November. The goal dashboard is active again. Professions.lua `9a12130d` → `24b89db1` limits a standard modern `GetRecipeKnowledge` query to catalogue keys for the requested recipe. It still walks the saved records, applies the same revocation rules and ranks every matching alias in the original order. Legacy descriptors and replacement catalogue getters still take the full path. There is no persistent cache or change to recipe validation cadence.

All four before/after Lua 5.1 and 5.4 syntax checks passed. Retail and Forever disk hashes match. The earlier native capture supplied 148 real catalogue records and exercised a different live recipe query. AH111 and charge112 stopped before input, with both reservations released. The client showed a focused BugTabs copy field and one raid secure-handler stack with its top error line clipped. No reload or jump was sent by this continuation. Candidate adoption and timing remain pending. Keep the full inventory, casting, client and provider acceptance matrix open.
[Exact source and native evidence](docs/validation/modern-recipe-knowledge-2026-11-18.json).
<!-- /LHO-MODERN-RECIPE-KNOWLEDGE-20261118 -->

<!-- LHO-CARRIED-SCAN-COUNT-20261118 -->
18 November continuation. The carried-consumable scan skips one options-table allocation per canonical bag snapshot count. It reads the same current snapshot through the same index method and capability check. The public fallback still receives its original fresh options when either getter is replaced. Saved-potion eligibility reuse now also requires the original classifier methods and a plain classifier table.

Lua 5.1 and 5.4 before/after syntax passed. Native 109 in Forever 1.60.1 / 70959 observed zero eligible saved-reference passes and restored the temporary wrappers. Probe 110 ended before input. These captures preceded the new Lua edits. Native adoption, matched frame times and remaining LHO-01–13 workflow acceptance are pending. The jump helper remains stopped from the earlier pause. The goal dashboard still reports paused despite the text request to continue.
[Exact source identities and native evidence](docs/validation/carried-scan-count-2026-11-18.json).
<!-- /LHO-CARRIED-SCAN-COUNT-20261118 -->

<!-- LHO-PAUSED-20261118-FINAL -->
USER PAUSED FULLY: no commands/tests/edits/jumps until explicit "continue". Saved18November. Actual Persist7082172e/Scan21883c7d edits adopted by101guardedreload/freshstartup;native10354counts match,food1487-14-841 unchanged,bothprovidersready,queue4/errors0/preferences0-120-30,cursorclear. After-timing104did NOT run:104a modifierguard stopped before input;pending retry auto-review rejected because user paused. Gain/fullrecord/override/reentry/native-otherclient/FPS/hitch acceptance remainsPENDING. Baseline99/100 samples and source proof/8syntaxchecks retained.

All testing/jumps stopped. R20supervisor37448 stopped-before-launch/verified absent;noR20host. EarlierR19host33664 stopped before101reload. CANCEL/nativeJUMP_STOP remain. Pause-only guardedReloadUI was queued bypause1811reload_b;fresh startup confirmation failed because WoW was minimized. Do not claim confirmed final reload/world return. Latest user insists fullstop,so no further verification now. On continue revalidate actual session/current source;temporary probes/cue must be freshly installed only if needed. Never replay spent commands. Preserve all newer/unrelated work. Full original optimization scope unfinished.
[Resume checkpoint](docs/validation/persist-ref-eligibility-2026-11-18.json).
<!-- /LHO-PAUSED-20261118-FINAL -->

<!-- ROSTER-GEOMETRY-PORTRAITS-R71-20261118 -->
R71 is on disk in the working tree. This update followed the user report that R70 improved group hitches but some remain. The border core still identifies itself as roster-layout-r70. Native validation is pending. Continue to respect the separate Inventory pause and the user request for no questions or test requests.
[R71 source pins, replay counts and validation](docs/validation/roster-geometry-and-portraits-2026-11-18.json).
<!-- /ROSTER-GEOMETRY-PORTRAITS-R71-20261118 -->

<!-- ROSTER-RESTRICTED-PARSER-R72-20261118 -->
R72 replaces the rejected R71 secure roster body. Preserve the native parser regression in the secure roster harness. Native reload, taint, frame time and visual acceptance remain pending. Continue the existing no-question and no-test-request instruction.
[R72 source and validation evidence](docs/validation/roster-restricted-parser-2026-11-18.json).
<!-- /ROSTER-RESTRICTED-PARSER-R72-20261118 -->

<!-- PARTY-ROSTER-LOCALITY-R73-20261119 -->
R73 is on disk. This work follows the user report of continued party-only hitches after R72 and covers both party appearance settings. Native join/leave latency and combat taint are pending. Preserve the existing no-questions and no-native-test-request instruction.
[R73 evidence](docs/validation/party-roster-locality-2026-11-19.json).
<!-- /PARTY-ROSTER-LOCALITY-R73-20261119 -->

<!-- GROUP-RENDER-R74-20261119 -->
R74 is on disk in the existing main workspace. The remaining reports cover both party and raid transitions. Offline evidence covers roster bursts, retained overlay state, shared border dependencies, and real layout invalidation. Live latency, visuals and combat taint are pending. Keep the no-questions and no-native-test-request instruction.
[R74 evidence](docs/validation/group-render-work-2026-11-19.json).
<!-- /GROUP-RENDER-R74-20261119 -->

<!-- ROSTER-REGION-ROUTING-R75-20261119 -->
R75 is prepared in main. The active goal remains the reported party and raid hitch across the whole addon. The historical saved capture attributes the two longest callbacks to border.junctions. The latest source comparisons prove less work but do not establish live latency. The saved R68 plan spent 52.21 ms on fallback mesh and 34.43 ms on branch work across six changed regions. An external disjoint triangle/cell cutoff replay preserved output and showed no work reduction in 52 comparable cases. The cutoff remains unapplied. Compare branch and fallback planning across repeated roster layouts and check whether unchanged raid cells still repeat full aura work. Continue the wider roster callback audit and keep the no-questions and no-native-test-request instruction.
[R75 evidence](docs/validation/roster-region-routing-2026-11-19.json).
<!-- /ROSTER-REGION-ROUTING-R75-20261119 -->

<!-- ROSTER-RETURN-PLANS-R76-20261119 -->
R76 is on disk. A repeated roster layout reuses prepared numerical geometry. The first change into a new layout and active-unit refresh work remain possible hitch sources. Resume the wider roster callback audit with current native evidence when available. Preserve the standing no-questions and no-native-test-request instruction.
[R76 evidence](docs/validation/roster-return-plans-2026-11-19.json).
<!-- /ROSTER-RETURN-PLANS-R76-20261119 -->

<!-- ROSTER-LOCAL-FALLBACK-R77-20261119 -->
R77 is on disk. The historical native trace points to border planning. Cold planning now avoids repeated continuation discovery and duplicate numeric storage. Current native party and raid acceptance is still required. Compare remaining solve, plan and commit work using matched real trigger evidence when available. Keep the no-questions and no-native-test-request instruction.
[R77 evidence](docs/validation/roster-local-fallback-2026-11-19.json).
<!-- /ROSTER-LOCAL-FALLBACK-R77-20261119 -->

<!-- ROSTER-PREPARED-LAYOUT-R78-20261119 -->
R78 is on disk. Continue from the confirmed R68 native border attribution and the current prepared-roster replays. Native group entry and exit latency, combat taint and rendered output remain open. The user is away and requested Lua changes without new probes or questions.
[R78 evidence](docs/validation/roster-prepared-layout-2026-11-19.json).
<!-- /ROSTER-PREPARED-LAYOUT-R78-20261119 -->

<!-- REGIONAL-CLIPPING-R79-20261119 -->
R79 is on disk. Continue profiling or replaying the local contact work for action-bar expansion and column changes as well as first party/raid transitions. Both grid Relayout methods still schedule an Info and envelope refresh independently after zero delay. Check those callbacks and the Info action-strip geometry first on the next pass. Test both strip side seams and current live taint when available. The goal remains active and includes the user’s scope addition below.
[R79 evidence](docs/validation/regional-clipping-2026-11-19.json).
<!-- /REGIONAL-CLIPPING-R79-20261119 -->

<!-- GRID-ENVELOPE-R80-20261119 -->
R80 is on disk. The held-cursor enter/leave path has its own actual-source replay. Next check the cost of a single local border pass during expansion and collapse and the first group transition. The stance size request still runs on its existing deferred path. Native timing, combat taint and both strip side seams remain open.
[R80 evidence](docs/validation/grid-envelope-2026-11-19.json).
<!-- /GRID-ENVELOPE-R80-20261119 -->

<!-- INDEXED-REGIONS-R81-20261119 -->
R81 is on disk. Continue with the group and held-action cases at their single regional build. Source selection still visits expanded dirty tiles per piece before the solve, and drawing still validates source layouts in changed tiles. Test live timing, side seams and protected behavior when available. The full goal remains open.
[R81 evidence](docs/validation/indexed-regions-2026-11-19.json).
<!-- /INDEXED-REGIONS-R81-20261119 -->

<!-- INDEXED-NEIGHBORS-R82-20261119 -->
The goal includes party and raid join or leave and the held-action boundary on the action strip. R82 limits source selection for both paths to candidate tiles. Full desktop rebuild timing varied. Continue the remaining group consumers and border planning and draw pass. Verify native latency, left/right panel seams and combat taint when available.
[R82 evidence](docs/validation/indexed-neighbors-2026-11-19.json).
<!-- /INDEXED-NEIGHBORS-R82-20261119 -->

<!-- RAID-CELL-NEIGHBORS-20261119 -->
The active goal includes party or raid join and leave, and cursor enter or leave while holding an action. The raid-specific joined-border pass now avoids comparing distant cells and reuses prepared edges. The isolated desktop improvement is small. The next roster candidate is the optional missing-class-buff pass, where the roster callback calls UpdateAll and native cell reconciliation can also reach the same display through full paint. Verify both call orders and keep cast, aura and private-state updates independent. Regional border planning and draw work also remain open. Native hitch, side seams and combat behavior remain open.
[Raid cell evidence](docs/validation/raid-cell-neighbors-2026-11-19.json).
<!-- /RAID-CELL-NEIGHBORS-20261119 -->

<!-- ROSTER-ADJUNCT-DISPATCH-20261119 -->
The active goal covers party and raid join or leave and held cursor enter or leave at the action strip. The roster owner now merges optional raid buff requests with queued full/aura paint. Next investigate group-driven macro evaluation and reusing output in regional rebuilds. In-game group latency, action-strip edges and taint still need verification.
[Adjunct dispatch evidence](docs/validation/roster-adjunct-dispatch-2026-11-19.json).
<!-- /ROSTER-ADJUNCT-DISPATCH-20261119 -->

<!-- SOURCE-RENDER-CONTEXT-R83-20261119 -->
R83 is on disk. Both the held-action strip replay and a modeled dock switch render with fewer source/canvas reads. Continue expensive regional planning and draw revalidation, and verify actual group or held-action latency and side seams when a native scenario is available.
[R83 evidence](docs/validation/source-render-context-2026-11-19.json).
<!-- /SOURCE-RENDER-CONTEXT-R83-20261119 -->

<!-- FRAGMENT-OWNERS-R84-20261119 -->
R84 is on disk and the active goal remains both group transitions and held-cursor strip edges. The shared fragment owners are now available to reduce repeated canvas validation. A long border resize can change its texture mapping across its full span. Profile or replay subsequent planner and draw work, and keep actual join/leave, strip seam and combat verification pending.
[R84 evidence](docs/validation/fragment-owners-2026-11-19.json).
<!-- /FRAGMENT-OWNERS-R84-20261119 -->

<!-- PREPARED-LAYERS-R85-20261119 -->
R85 removes repeated native layer reads within a regional draw. The active goal still covers group joins/leaves and cursor enter/leave while holding an action. Current visual parity is sampled. Native hitch, actual side seams and combat taint still require verification. Continue reduction of changed-cell plan and commit work, and group-sensitive callbacks outside the border builder.
[R85 evidence](docs/validation/prepared-layers-2026-11-19.json).
<!-- /PREPARED-LAYERS-R85-20261119 -->

<!-- ROSTER-MACRO-BATCH-20261119 -->
Roster-driven macro evaluation joins the current optimization set. The active goal still includes party or raid joins and leaves and drag-cursor entry or exit at the strip. Native hitch and combat verification remain pending. Continue looking for repeated work in separate roster consumers and regional border commits.
[Macro roster batch evidence](docs/validation/roster-macro-batch-2026-11-19.json).
<!-- /ROSTER-MACRO-BATCH-20261119 -->

<!-- TILE-FIELD-REJECTION-R86-20261119 -->
R86 removes clipping work from the regional renderer for fields outside a tile. The active goal covers group joins/leaves and held-action cursor entry/exit with neighboring panel movement. Native hitch, seams and combat taint remain open.
[R86 evidence](docs/validation/tile-field-rejection-2026-11-19.json).
<!-- /TILE-FIELD-REJECTION-R86-20261119 -->

<!-- STRIP-POSE-TOPOLOGY-R87-20261119 -->
R87 skips solving and clipping when held-action expand/collapse returns to a validated prepared plan. Native first-entry and warm hitches, seams, group/raid event latency and combat taint remain open. The remaining warm path reads materials and commits replacement fields. The roster audit also found repeated full individual unit-frame chrome refreshes on roster events.
[R87 evidence](docs/validation/strip-pose-topology-2026-11-19.json).
<!-- /STRIP-POSE-TOPOLOGY-R87-20261119 -->

<!-- INDIVIDUAL-ROSTER-BATCH-20261119 -->
Individual unit-frame roster events now share one next-turn batch, reducing redundant full paints before border invalidation. The remaining action-strip path still visits all host button skins on a moved layout. Native first-entry and warm hitches, party and raid join/leave timing, seams and combat taint remain open.
[Individual unit roster evidence](docs/validation/individual-roster-batch-2026-11-19.json).
<!-- /INDIVIDUAL-ROSTER-BATCH-20261119 -->

<!-- STRIP-CHROME-MINIMAP-ROSTER-20261119 -->
Strip drag edges reuse stable button chrome as well as R87 prepared borders. Minimap group and size notifications now run the native difficulty and queue layout once per next-turn burst. Native first-entry and warm hitches, group joins and leaves, seams and combat taint remain open.
[Strip and minimap evidence](docs/validation/strip-chrome-minimap-roster-2026-11-19.json).
<!-- /STRIP-CHROME-MINIMAP-ROSTER-20261119 -->

<!-- PREPARED-STRIP-SAMPLING-R88-20261119 -->
Prepared strip poses retain fragment and junction sampling in R88. Review the remaining regional commit work if native held-action crossings still hitch. Native group timing, seam fidelity and combat taint are still open.
[Border sampling evidence](docs/validation/prepared-strip-sampling-2026-11-19.json).
<!-- /PREPARED-STRIP-SAMPLING-R88-20261119 -->

<!-- BORDER-SETTERS-THREAT-ROSTER-R89-20261119 -->
R89 reduces shared junction setter overhead without changing mesh layout. The optional Details threat meter handles each in-combat roster burst once. Actual party and raid hitches, held-action hitches, native seams and combat taint remain open.
[Setter and threat roster evidence](docs/validation/border-setters-threat-roster-2026-11-19.json).
<!-- /BORDER-SETTERS-THREAT-ROSTER-R89-20261119 -->

<!-- FINAL-STRIP-UNIT-ANCHORS-R90-20261119 -->
Held-action strip crossings now settle unit root anchors after the envelope and before junction geometry is read. Native strip/cast/target relationships, group join/leave latency and combat taint remain open.
[Strip unit anchoring evidence](docs/validation/final-strip-unit-anchors-2026-11-19.json).
<!-- /FINAL-STRIP-UNIT-ANCHORS-R90-20261119 -->

<!-- STRIP-GRID-PACKING-R91-20261119 -->
Combat and non-combat strip neighbors keep their packed slot geometry on pure strip movement. A changed grid still follows its original packing path. Live strip seam, group hitch and combat-taint acceptance remain open.
[Strip grid packing evidence](docs/validation/strip-grid-packing-2026-11-19.json).
<!-- /STRIP-GRID-PACKING-R91-20261119 -->

<!-- STRIP-PANEL-SETTLE-R92-20261119 -->
Trinket Menu and Info now finish strip crossings with scoped updates. The shared envelope compares actual anchor owners and checks both fills on each crossing. Native strip seams, group hitch and combat-taint acceptance remain open.
[Strip panel settlement evidence](docs/validation/strip-panel-settle-2026-11-19.json).
<!-- /STRIP-PANEL-SETTLE-R92-20261119 -->

<!-- RAID-ROSTER-ATTACHMENT-PAINT-R93-20261119 -->
MT/MA roster attachment work now visits its dedicated header. Raid paint and indicator work sample the loot assignment once per batch. Native group hitch, strip motion and combat-taint acceptance remain open.
[Raid roster paint evidence](docs/validation/raid-roster-attachment-paint-2026-11-19.json).
<!-- /RAID-ROSTER-ATTACHMENT-PAINT-R93-20261119 -->

<!-- STRIP-LAYER-COMMIT-R95-20261119 -->
Held-spell cursor crossings now reuse the final draw layer per canvas and retain matching shell anchors. Fallback roster notifications coalesce into the existing next-frame reconciliation. Desktop parity passed. Real group hitch, held-cursor hitch, client pixel and combat-taint acceptance remain open.
[Matched validation](docs/validation/strip-layer-commit-2026-11-19.json).
<!-- /STRIP-LAYER-COMMIT-R95-20261119 -->

<!-- STRIP-RELATIVE-ANCHORS-R96-20261119 -->
Current strip crossings retain matching button and outline anchors and place unused minis directly off-screen. The exact-source replay covers sparse and dense strips and all Info placements. The group scan identified synchronous Food roster binds and a delayed Water bind refresh. Review that path with the existing inventory and spellbook owners. Native group and held-cursor validation remain open.
[Matched validation](docs/validation/strip-relative-anchors-2026-11-19.json).
<!-- /STRIP-RELATIVE-ANCHORS-R96-20261119 -->

<!-- CONSUMABLE-ROSTER-BINDINGS-R97-20261119 -->
Food and Water no longer subscribe to group roster events. The offline matrix verifies both spellbook paths, actual binding callbacks and deferred combat recovery. Native group and held-cursor timing, seams and taint remain open.
[Matched validation](docs/validation/consumable-roster-bindings-2026-11-19.json).
<!-- /CONSUMABLE-ROSTER-BINDINGS-R97-20261119 -->

<!-- STRIP-SLOT-SAMPLING-R98-20261119 -->
Visual action-strip layout now reads each slot once per pass and reads the active page only on expansion. The replay covers slot and overlay mutations and a page switch during secure mapping. Native group and held-cursor timing, seams and taint remain open.
[Matched validation](docs/validation/strip-slot-sampling-2026-11-19.json).
<!-- /STRIP-SLOT-SAMPLING-R98-20261119 -->

<!-- RAPID-STRIP-DROPS-R99-20261119 -->
The user reports improvements on held-action crossings and continuing hitches on rapid drops, including borders. Current source limits remaps to consuming columns and restores repeated side-join layouts when the geometry and materials match. Cold or different widths still build locally. Native rapid drag, party or raid join or leave, seam and taint checks remain open.
[Matched validation](docs/validation/rapid-strip-drops-2026-11-19.json).
<!-- /RAPID-STRIP-DROPS-R99-20261119 -->

<!-- REGIONAL-FRAGMENT-READS-R100-20261119 -->
Regional border drawing shares source setup for the duration of each commit. The current replays cover cold and warm strip width changes, local join movement and live layer or paint updates. Native party/raid, rapid drag, border pixels and combat-taint acceptance remain open.
[Matched validation](docs/validation/regional-fragment-reads-2026-11-19.json).
<!-- /REGIONAL-FRAGMENT-READS-R100-20261119 -->

<!-- STRIP-JOIN-SOURCES-R101-20261119 -->
The user confirms that crossing the strip edge with an action held can hitch without a drop. The current renderer shares original source parents and prepared canvases during regional paint. Native held-action, rapid drop and group transitions remain open, along with seam pixel and combat-taint checks.
[Matched validation](docs/validation/strip-join-sources-2026-11-19.json).
<!-- /STRIP-JOIN-SOURCES-R101-20261119 -->

<!-- REGIONAL-LAYOUT-INDEX-R102-20261119 -->
Regional geometry and join discovery now skip unrelated fingerprint sorting and distant edge queries. Exact desktop replays cover strip crossings and a populated roster. Cold mesh planning and commit cost remain areas for inspection. Native group join or leave, held-action seams and combat taint remain open.
[Matched validation](docs/validation/regional-layout-index-2026-11-19.json).
<!-- /REGIONAL-LAYOUT-INDEX-R102-20261119 -->

<!-- REGIONAL-TILE-MATERIALS-R103-20261119 -->
Regional preparation now samples only the materials needed by the planner or redrawn tiles. Both prepared hover poses validate that smaller set. Roster replay and safe masked-art fallback passed. Native join or leave, held-action seams and combat taint remain open.
[Matched validation](docs/validation/regional-tile-materials-2026-11-19.json).
<!-- /REGIONAL-TILE-MATERIALS-R103-20261119 -->

<!-- RAID-ROSTER-NATIVE-WRITES-R104-20261119 -->
Raid roster reconciliation now skips matching native refs and stable CVar-off or legacy anchors, reducing geometry invalidations at the source. Matched label and reference replays and active roster transition tests pass. Native group latency, action-strip latency, seam pixels and combat taint remain open.
[Matched validation](docs/validation/raid-roster-native-writes-2026-11-19.json).
<!-- /RAID-ROSTER-NATIVE-WRITES-R104-20261119 -->

<!-- REGIONAL-ROSTER-POSES-R105-20261119 -->
Repeated public party and raid geometry now shares the localized prepared-layout mechanism with the existing action-strip cache. Bounded exact comparisons cover new geometry, current paint, fresh materials and combat deferral. Native join or leave, held-action seams and combat taint remain open.
[Matched validation](docs/validation/regional-roster-poses-2026-11-19.json).
<!-- /REGIONAL-ROSTER-POSES-R105-20261119 -->

<!-- REGIONAL-BORDER-CUTS-R106-20261119 -->
Cold border planning now skips disjoint cutter calls and reuses unchanged fallback lists. Roster moves with HP/resource and portrait joins and the held-action replay pass. Heavy parallel edge output agrees exactly. Native roster, strip, seam and combat acceptance remain open.
[Matched validation](docs/validation/regional-border-cuts-2026-11-19.json).
<!-- /REGIONAL-BORDER-CUTS-R106-20261119 -->

<!-- HELD-ACTION-REFLOW-R107-20261119 -->
Held-action pointer transitions use compact prepared paint descriptors. A queued hover reversal that leaves the layout unchanged now keeps the existing paint. Native held-action and group transition hitching, seamless pixels and combat taint remain pending.
[Matched validation](docs/validation/held-action-reflow-2026-11-19.json).
<!-- /HELD-ACTION-REFLOW-R107-20261119 -->

<!-- INDEPENDENT-BORDER-REGIONS-R108-20261119 -->
The border renderer now retains independent party outlines when neighboring HUD elements move. A party member changing position triggers its own region. Compact raid uses a separate joined-edge renderer and still needs native timing coverage. Held-action, group-transition, seamless pixel and taint acceptance remain pending.
[Matched validation](docs/validation/independent-border-regions-2026-11-19.json).
<!-- /INDEPENDENT-BORDER-REGIONS-R108-20261119 -->

<!-- COMPACT-RAID-SEAM-DELTAS-R109-20261119 -->
Compact raid and party-as-raid preserve neighbor counts when one cell joins, leaves or moves. Multiple changed cells or a new row overlap take the full sorted calculation. The shared HUD renderer and independent party path keep their previous validation. Actual join/leave, held-action hitching and combat taint remain pending.
[Matched validation](docs/validation/compact-raid-seam-updates-2026-11-19.json).
<!-- /COMPACT-RAID-SEAM-DELTAS-R109-20261119 -->

<!-- RAID-AURA-PRESENTATION-R110-20261119 -->
Compact raid aura display policy now survives roster paint for unchanged boxes. The same pass still checks native visibility, current unit binding and the current friendly dispel owner. Evaluate full roster paint outside native aura controls and repeat real in-game join, leave, border/drag and taint trials when available.
[Matched validation](docs/validation/raid-aura-presentation-2026-11-19.json).
<!-- /RAID-AURA-PRESENTATION-R110-20261119 -->

<!-- RAID-UNIT-PAINT-READS-R111-20261119 -->
Compact raid repaint samples common health and connection data once per cell, including range opacity. Each separate event still samples live data. In-game group transition and held-action timing, seamless pixels and taint remain pending.
[Matched validation](docs/validation/raid-unit-paint-reads-2026-11-19.json).
<!-- /RAID-UNIT-PAINT-READS-R111-20261119 -->

<!-- STRIP-BORDER-REFRESH-R112-20261119 -->
Held-action layout verifies current button scale and shown state before writing. Regional border reads select watched parents during the same guarded registry traversal, and the committed layout retains its owner index. Native hitching, combat taint and visual seam acceptance remain pending.
[Matched validation](docs/validation/strip-border-refresh-2026-11-19.json).
<!-- /STRIP-BORDER-REFRESH-R112-20261119 -->

<!-- STRIP-HOVER-PAINT-R113-20261119 -->
While the cursor keeps the same action, the strip repaints only faces changed by the settled layout and pending slot paint. Other drag or structural requests retain a full paint. Live hitching, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/strip-hover-paint-2026-11-19.json).
<!-- /STRIP-HOVER-PAINT-R113-20261119 -->

<!-- BORDER-VISIBILITY-FANOUT-R114-20261119 -->
Share public border availability within one paint callback. During a commit, reuse the gate only after matching the existing verified ordered observer pair. Source opacity still comes from the live paint entry. Native hitching, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-visibility-fanout-2026-11-19.json).
<!-- /BORDER-VISIBILITY-FANOUT-R114-20261119 -->

<!-- BORDER-DRAW-GEOMETRY-R115-20261119 -->
Prepared border fields reconcile their exact point and size together and preserve confirmed zero offsets across rectangular draws. Validate public RGBA at source read. A partial native writer failure can retry the old placement. Native hitching, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-draw-geometry-2026-11-19.json).
<!-- /BORDER-DRAW-GEOMETRY-R115-20261119 -->

<!-- ROSTER-DISCOVERY-REFRESH-R116-20261119 -->
Roster-driven nameplate refresh can reuse a successful whole-module combo paint. Native mouseover discovery shares one raid ownership read. Prepared registered raid buttons already have their handlers. Native group latency and combat taint remain pending.
[Matched validation](docs/validation/roster-discovery-refresh-2026-11-19.json).
<!-- /ROSTER-DISCOVERY-REFRESH-R116-20261119 -->

<!-- STRIP-VISIBILITY-R117-20261119 -->
Held-cursor enter and leave can cancel a queued layout when the final pose matches and the queue has only hover work. Regional borders attach fallback visibility per cell. Verify live settled crossings, rapid placements, first roster transitions, seam pixels and combat taint.
[Matched validation](docs/validation/strip-visibility-2026-11-19.json).
<!-- /STRIP-VISIBILITY-R117-20261119 -->

<!-- RAID-PAINT-BATCH-R118-20261119 -->
Compact group paints sample current shared settings once in each dispatch and class once per member. Readable auras report a completed dispel paint to the unit dispatcher. Native group and held-cursor timing, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/raid-paint-batch-2026-11-19.json).
<!-- /RAID-PAINT-BATCH-R118-20261119 -->

<!-- RAID-REASSIGNMENT-R119-20261119 -->
Visible secure reassignments share the current raid paint driver with roster reconciliation and companion refreshes. Native event routing updates before paint. Actual party and raid join or leave timing, held-action crossings, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/raid-reassignment-2026-11-19.json).
<!-- /RAID-REASSIGNMENT-R119-20261119 -->

<!-- STRIP-CHAT-DOCK-R120-20261119 -->
Pure held-action crossings settle chat after the final grid envelope. Matching chat points, size, and layout metadata bypass the pin. A changed raid dock still updates with the new floor. Native crossings, drop, roster transitions, seams and taint remain pending.
[Matched validation](docs/validation/strip-chat-dock-2026-11-19.json).
<!-- /STRIP-CHAT-DOCK-R120-20261119 -->

<!-- STRIP-PAINT-INDEX-R121-20261119 -->
Prepared held-action crossings reuse affected tiles’ source paint lists and sprite pools. Native crossing, drop, roster timing, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/strip-paint-index-2026-11-19.json).
<!-- /STRIP-PAINT-INDEX-R121-20261119 -->

<!-- BORDER-VISIBILITY-COMMIT-R122-20261119 -->
Regional border rebuilds share confirmed public parent visibility during a commit. Native cursor crossing, drop, roster timing, seamless pixels and combat taint remain pending.
[Matched validation](docs/validation/border-visibility-commit-2026-11-19.json).
<!-- /BORDER-VISIBILITY-COMMIT-R122-20261119 -->

<!-- PARTY-DISPEL-IDENTITY-R123-20261119 -->
Party debuff owners preserve their native aura data when the current unit token, public GUID and filter agree. The next member change or unresolved identity still refreshes. Native party/raid latency and rapid held-action or drop latency remain pending.
[Matched validation](docs/validation/party-dispel-identity-2026-11-19.json).
<!-- /PARTY-DISPEL-IDENTITY-R123-20261119 -->

<!-- UNIT-NAME-STRIP-GEOMETRY-R124-20261119 -->
Name-strip class/spec geometry uses the current public widget dimensions and anchors before changing registered dividers. True changes and clear-hook reentry follow the original live writes. Native join/leave, cursor crossing, drop latency and seam rendering remain pending.
[Matched validation](docs/validation/unit-name-strip-geometry-2026-11-19.json).
<!-- /UNIT-NAME-STRIP-GEOMETRY-R124-20261119 -->

<!-- BORDER-POSE-SAMPLES-R125-20261119 -->
Prepared strip and roster border draws validate the live UV tuple and share the compiled source array on an exact public match. Changed source data take the existing planner. Native cursor, drop, roster timing and seam acceptance remain pending.
[Matched validation](docs/validation/border-pose-samples-2026-11-19.json).
<!-- /BORDER-POSE-SAMPLES-R125-20261119 -->

<!-- BORDER-PREPARED-DRAW-R126-20261119 -->
Prepared strip and roster draws now reuse compiled tile plans and tile-owned draw records after the existing live material checks. Native held-action crossing, drop, group latency, and seam checks remain pending.
[Matched validation](docs/validation/border-prepared-draw-2026-11-19.json).
<!-- /BORDER-PREPARED-DRAW-R126-20261119 -->

<!-- BORDER-DRAW-INPUTS-R127-20261119 -->
Prepared draw reuse checks current junction inputs against the previous list in one pass. The native field repair regression covers hidden sprites with unchanged source inputs. Native strip and roster latency, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-draw-inputs-2026-11-19.json).
<!-- /BORDER-DRAW-INPUTS-R127-20261119 -->

<!-- BORDER-SPRITE-REUSE-R128-20261119 -->
Cached junction draws retain their validated sprite list and record triangle indices during paint. Paired process CPU measurements cover held-action crossings and a scoped roster control. Live group and cursor latency and combat taint remain pending.
[Matched validation](docs/validation/border-sprite-reuse-2026-11-19.json).
<!-- /BORDER-SPRITE-REUSE-R128-20261119 -->

<!-- ROSTER-ROLE-CHROME-R129-20261119 -->
Roster-triggered outer-border updates now retain matching status icon geometry and visibility on player, target and focus. Membership and role changes still use current native state. Native join and leave latency and taint remain pending.
[Matched validation](docs/validation/roster-role-chrome-2026-11-19.json).
<!-- /ROSTER-ROLE-CHROME-R129-20261119 -->

<!-- STRIP-HOVER-MAPPINGS-R130-20261119 -->
Expanded action-strip mappings skip redundant occupancy reads. During a changed column, matching public flags stay in place. Current slot repair, secure updates and the settled border transaction remain covered. Native held-action crossing, drop and group latency checks remain pending.
[Matched validation](docs/validation/strip-hover-mappings-2026-11-19.json).
<!-- /STRIP-HOVER-MAPPINGS-R130-20261119 -->

<!-- STRIP-HOVER-KEYS-R131-20261119 -->
Pure drag-hover edges reuse installed bindings when the active event subscription owns binding changes and the current route endpoints and proxy actions validate. Native strip, roster and combat acceptance remain pending.
[Matched validation](docs/validation/strip-hover-keys-2026-11-19.json).
<!-- /STRIP-HOVER-KEYS-R131-20261119 -->

<!-- BORDER-PARENT-GEOMETRY-R132-20261119 -->
R132 shares verified frame scale, origin, and layer across the outline and dividers during one border layout read. Native acceptance is pending for held-action crossings, rapid drops, party and raid membership changes, pixels and combat taint.
[Matched validation](docs/validation/border-parent-geometry-2026-11-19.json).
<!-- /BORDER-PARENT-GEOMETRY-R132-20261119 -->

<!-- BORDER-POSE-TOPOLOGY-R133-20261119 -->
R133 reuses the identity of unchanged public border samples when validating prepared strip and roster layouts. Live registration flags and paint still validate. Actual held-action latency, rapid drops, group join and leave, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-pose-topology-2026-11-19.json).
<!-- /BORDER-POSE-TOPOLOGY-R133-20261119 -->

<!-- BORDER-FALLBACK-CONTEXT-R134-20261119 -->
R134 lazily prepares fallback keys and unions affected party scope bounds from the old and new snapshots. The initial visible-layout and cursor-edge comparisons both match. Actual membership and cursor latency, rapid drops, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-fallback-context-2026-11-19.json).
<!-- /BORDER-FALLBACK-CONTEXT-R134-20261119 -->

<!-- BORDER-ADMISSION-R135-20261119 -->
R135 shares regional eligibility within one geometry transaction. An invalidation observed during the read discards the proof. Actual membership and cursor latency, rapid drops, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-admission-2026-11-19.json).
<!-- /BORDER-ADMISSION-R135-20261119 -->

<!-- BORDER-LAYER-PLAN-R136-20261119 -->
R136 shares public strip and unit levels during a regional plan and reuses one result per canvas during layer aggregation. The current layer, source paint and visibility checks still apply. Actual membership and cursor latency, rapid drops, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-layer-plan-2026-11-19.json).
<!-- /BORDER-LAYER-PLAN-R136-20261119 -->

<!-- BORDER-SNAPSHOT-COPY-R137-20261119 -->
R137 shares immutable sampled source bounds between the layout and solver and releases the temporary copy map immediately. Fresh geometry and the mutable solver records retain their own ownership. Actual membership and cursor latency, rapid drops, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-snapshot-copy-2026-11-19.json).
<!-- /BORDER-SNAPSHOT-COPY-R137-20261119 -->

<!-- BORDER-POSE-REGISTRATION-R138-20261119 -->
R138 keeps prepared border layouts across unrelated decorative registration changes. A mixed registration transaction still takes the guarded regional path. Actual held-cursor movement, rapid drops, membership latency, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-pose-registration-2026-11-19.json).
<!-- /BORDER-POSE-REGISTRATION-R138-20261119 -->

<!-- BORDER-EMPTY-FRAGMENTS-R139-20261119 -->
R139 omits nonexistent fragment and fallback render work. Source paint stays live and existing regional level reconciliation still runs. Native held-cursor behavior, rapid drops, membership latency, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-empty-fragments-2026-11-19.json).
<!-- /BORDER-EMPTY-FRAGMENTS-R139-20261119 -->

<!-- RAID-ROSTER-SAMPLE-R140-20261119 -->
R140 reuses one legacy raid roster sample through visibility and header placement. The prepared native roster and combat paths have matching offline coverage. Native group join and leave latency, held-cursor movement, rapid drops, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/raid-roster-sample-2026-11-19.json).
<!-- /RAID-ROSTER-SAMPLE-R140-20261119 -->

<!-- RAID-GRID-RECTANGLE-R141-20261119 -->
R141 adds a public rectangle check for retained compact raid cell geometry. Cold and changed cells use exact edges. The modeled joins match across both overlap arrangements. Actual membership latency, held-action crossings, rapid drops, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/raid-grid-rectangle-2026-11-19.json).
<!-- /RAID-GRID-RECTANGLE-R141-20261119 -->

<!-- RAID-RANGE-BURST-R142-20261119 -->
R142 shares compact-cell range discovery with the existing joined-border wake and retries an unavailable range event independently of installed unit routes. Native membership latency, cursor crossings, rapid drops, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/raid-range-burst-2026-11-19.json).
<!-- /RAID-RANGE-BURST-R142-20261119 -->

<!-- RAID-JOIN-INDEX-R143-20261119 -->
R143 indexes exact compact border contacts for aligned group layouts. The irregular path keeps the original tolerance comparisons and single-cell changes retain incremental joining. Live group timing, held-action crossings, rapid drops, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/raid-join-index-2026-11-19.json).
<!-- /RAID-JOIN-INDEX-R143-20261119 -->

<!-- BORDER-ANCHOR-BURSTS-R144-20261119 -->
R144 batches anchor bookkeeping until the existing synchronous border commit. The remaining reported hitch is on the action strip during held spell, item or macro crossings. Native action-strip and group timing, seam pixels and combat taint remain open. The held-cursor path still changes secure mapping flags and runs the current force refresh when those flags change.
[Matched validation](docs/validation/border-anchor-bursts-2026-11-19.json).
<!-- /BORDER-ANCHOR-BURSTS-R144-20261119 -->

<!-- STRIP-HOVER-ROUTES-R145-20261119 -->
R145 preserves unchanged secure routes on held-action hover. Full slot refresh still handles pickup, drop, macro programming, control and recovery events. Device timing and secure taint testing remain pending. The remaining hover mapping cost includes legitimate route repoints, and native border transition cost remains to be confirmed.
[Matched validation](docs/validation/strip-hover-routes-2026-11-19.json).
<!-- /STRIP-HOVER-ROUTES-R145-20261119 -->

<!-- STRIP-MODIFIER-ROUTES-R146-20261119 -->
R146 shares prepared modifier routes when the held cursor moves across the strip and the child state is unchanged. All eight modifier aliases and the current click route remain covered by the desktop comparisons. Native timing, group and raid joins, border pixels and combat taint remain pending. The regional border renderer still performs a publication pass for moved side panels and roster regions.
[Matched validation](docs/validation/strip-modifier-routes-2026-11-19.json).
<!-- /STRIP-MODIFIER-ROUTES-R146-20261119 -->

<!-- PARTY-INDICATOR-PASS-R147-20261119 -->
R147 removes duplicate party text and indicator passes and retains unchanged public role geometry. Party and raid native join and leave latency, action-strip crossing and drop timing, exact seams and combat taint remain pending. Compact raid cells and moved regional border commits retain their existing paths.
[Matched validation](docs/validation/party-indicator-pass-2026-11-19.json).
<!-- /PARTY-INDICATOR-PASS-R147-20261119 -->

<!-- RAID-EXTRA-DRIVER-RETRY-R148-20261119 -->
R148 isolates failed optional pet or friendly-target setup to the unready cell in a matching layout. The existing combat gate delays retry and actual changes still take full setup. Native group latency, action-strip crossings, exact seams and combat taint remain pending. Normal roster operation and regional painting remain separate investigation paths.
[Matched validation](docs/validation/raid-extra-driver-retry-2026-11-19.json).
<!-- /RAID-EXTRA-DRIVER-RETRY-R148-20261119 -->

<!-- BORDER-ROLE-ANCESTRY-R149-20261119 -->
R149 retains only public role classifications within one read phase and invalidates them on observed changes, including reentrant parent edits. Party and raid native join and leave frame time, rapid held-action crossings and drops, exact native pixels and combat taint remain pending.
[Matched validation](docs/validation/border-role-ancestry-2026-11-19.json).
<!-- /BORDER-ROLE-ANCESTRY-R149-20261119 -->

<!-- STRIP-FLYOUT-ARROW-R150-20261119 -->
Rapid held-action crossings and actual drops remain the priority. Native party and raid transitions, seam pixels and combat taint still need verification. R150 removes repeated flyout arrow geometry setters. Two border tile-routing candidates gave no useful improvement in the matched crossing replay and were discarded.
[Matched validation](docs/validation/strip-flyout-arrow-2026-11-19.json).
<!-- /STRIP-FLYOUT-ARROW-R150-20261119 -->

<!-- STRIP-HOVER-OCCUPANCY-R151-20261119 -->
R151 eliminates the separate hover reset broadcast while keeping current occupancy and click routes. Rapid native held-action crossings and actual drops remain the priority. Party and raid transitions, exact seam pixels and combat taint still need native verification.
[Matched validation](docs/validation/strip-hover-occupancy-2026-11-19.json).
<!-- /STRIP-HOVER-OCCUPANCY-R151-20261119 -->

<!-- STRIP-PLAN-COVERAGE-R152-20261119 -->
R152 reuses a covering prepared plan after real strip width changes and held-action layout changes. Check costs for new footprints and continued roster work. Actual native crossings, drops, party and raid transitions, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/strip-plan-coverage-2026-11-19.json).
<!-- /STRIP-PLAN-COVERAGE-R152-20261119 -->

<!-- RAID-CHROME-LOOKUP-R153-20261120 -->
R153 removes the native party pool walk from positively identified grouped raid frame callbacks. Actual native raid and party transitions, rapid strip crossings and drops, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/raid-chrome-lookup-2026-11-20.json).
<!-- /RAID-CHROME-LOOKUP-R153-20261120 -->

<!-- RAID-STABLE-PAINT-R154-20261120 -->
R154 retains settled raid widget visibility and percentage ranges during the roster repaint. The full current paint still reconciles changed widgets and new units. Native membership and action-strip hitch timing, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/raid-stable-paint-2026-11-20.json).
<!-- /RAID-STABLE-PAINT-R154-20261120 -->

<!-- BORDER-LISTENER-INDEX-R155-20261120 -->
R155 retains listener index tables during a single border commit and prunes those with no returning listeners. Local draw, current tint or visibility, and broader source checks pass. Native membership and strip hitch timing, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-listener-index-2026-11-20.json).
<!-- /BORDER-LISTENER-INDEX-R155-20261120 -->

<!-- BORDER-FRAGMENT-MEMBERSHIP-R156-20261120 -->
R156 retains live border fragment membership during strip and other regional redraws. Rapid held-action crossings and drops are the current priority. Native hitch timing, party and raid transitions, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-fragment-membership-2026-11-20.json).
<!-- /BORDER-FRAGMENT-MEMBERSHIP-R156-20261120 -->

<!-- PET-STRIP-PACKING-R157-20261120 -->
R157 avoids pet slot repacking during strip crossings with verified local geometry. Continue auditing remaining hover work and roster transitions. Native frame time, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/pet-strip-packing-2026-11-20.json).
<!-- /PET-STRIP-PACKING-R157-20261120 -->

<!-- STANCE-STRIP-LAYOUT-R158-20261120 -->
R158 removes the deferred stance repaint after held-action crossings with settled geometry. Continue auditing group changes and action-strip input latency. Native frame time, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/stance-strip-layout-2026-11-20.json).
<!-- /STANCE-STRIP-LAYOUT-R158-20261120 -->

<!-- NATIVE-GROUP-HIDE-R159-20261120 -->
R159 cuts settled native raid and party suppression work while retaining the same child coverage and combat/Edit Mode path. Continue auditing raid-cell paint and the action-strip transition. Native group latency, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/native-group-hide-2026-11-20.json).
<!-- /NATIVE-GROUP-HIDE-R159-20261120 -->

<!-- RAID-ACTIVE-HEADERS-R160-20261120 -->
R160 avoids the hidden prepared header walk during roster reconciliation. Continue auditing active unit repaint work, native group hitch timing, and rapid action-strip changes. Native seam pixels and combat taint remain pending.
[Matched validation](docs/validation/raid-active-headers-2026-11-20.json).
<!-- /RAID-ACTIVE-HEADERS-R160-20261120 -->

<!-- STRIP-BADGE-PLACEMENT-R161-20261120 -->
R161 avoids repeated corner-badge reanchoring during held-action crossings. The remaining action-bar checks are real rapid crossings and drops, including layouts that move the side panels or create a new border footprint. Native party and raid transition timing, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/strip-badge-placement-2026-11-20.json).
<!-- /STRIP-BADGE-PLACEMENT-R161-20261120 -->

<!-- BORDER-RECENT-LAYOUTS-R162-20261120 -->
R162 retains more recurring width and roster layouts under the existing budget. Prioritize fresh layouts and native first-party or raid transition timing, action-strip crossing and drop latency, seam pixels and combat taint.
[Matched validation](docs/validation/border-recent-layouts-2026-11-20.json).
<!-- /BORDER-RECENT-LAYOUTS-R162-20261120 -->

<!-- BORDER-SIMPLE-INTERVALS-R163-20261120 -->
R163 reduces cold overlap work on the strip and in roster geometry. Native first and repeated action crossings and drops, party/raid latency, seam pixels and combat taint remain pending. Continue with the compiler and paint side of previously unseen footprints.
[Matched validation](docs/validation/border-simple-intervals-2026-11-20.json).
<!-- /BORDER-SIMPLE-INTERVALS-R163-20261120 -->

<!-- BORDER-FALLBACK-CLIP-R164-20261120 -->
R164 removes unused per-triangle cache work from new strip and roster layouts. Inspect remaining cold branch/commit work and group event fanout. Native action and roster timing, seam pixels and combat taint remain pending.
[Matched validation](docs/validation/border-fallback-clip-2026-11-20.json).
<!-- /BORDER-FALLBACK-CLIP-R164-20261120 -->

<!-- STRIP-SHELL-ANCHORS-R165-20261120 -->
The action strip now keeps its anchors through real width changes. Remaining priority is the cost of unseen widths and dependent panel work during held-action crossings and slot changes. Party and raid join or leave timing, native strip seams and combat taint still need confirmation.
[Matched validation](docs/validation/strip-shell-anchors-2026-11-20.json).
<!-- /STRIP-SHELL-ANCHORS-R165-20261120 -->

<!-- BORDER-TILE-FIELDS-R166-20261120 -->
Tile preparation now avoids intermediate polygons for contained fields. The modeled roster transition has no tile polygon work. Continue investigating the separate party and raid transition path and remaining first-time strip rebuild cost. Native latency, seams and combat taint remain pending.
[Matched validation](docs/validation/border-tile-fields-2026-11-20.json).
<!-- /BORDER-TILE-FIELDS-R166-20261120 -->

<!-- RAID-AURA-RETIREMENT-R167-20261120 -->
Repeated group aura cleanup now reuses the retired owners and settles active subscriptions once. Continue auditing native event retirement and remaining group first-transition cost. Action-strip first-build timing, in-game seams and combat taint remain open.
[Matched validation](docs/validation/raid-aura-owner-retirement-2026-11-20.json).
<!-- /RAID-AURA-RETIREMENT-R167-20261120 -->

<!-- STRIP-GRID-ROOT-ANCHORS-R168-20261120 -->
Grid roots now keep their attached points across strip resizes. Continue examining the cost of unseen widths and remaining group membership fanout. Native first and repeated action crossings, party and raid latency, seam appearance and combat taint remain open.
[Matched validation](docs/validation/strip-grid-root-anchors-2026-11-20.json).
<!-- /STRIP-GRID-ROOT-ANCHORS-R168-20261120 -->

<!-- RAID-UNIT-EVENT-RETIREMENT-R169-20261120 -->
Compact group event reset now runs once across the normal unbind and hide callbacks. Continue auditing roster appearance and side-contact reflow work, and keep native group and action-strip timing, seams and combat taint pending until verified.
[Matched validation](docs/validation/raid-unit-event-retirement-2026-11-20.json).
<!-- /RAID-UNIT-EVENT-RETIREMENT-R169-20261120 -->

<!-- BORDER-NEIGHBOR-RUNS-R170-20261120 -->
The border builder now selects adjacent source runs and shares group lookups while copying. Timing remains unverified in game. Continue investigating the larger cost of first-time planning and native event fanout on action crossings and group changes.
[Matched validation](docs/validation/border-neighbor-runs-2026-11-20.json).
<!-- /BORDER-NEIGHBOR-RUNS-R170-20261120 -->

<!-- STRIP-EMPTY-PROMOTION-R171-20261120 -->
The action strip now skips promotion scans for empty secondary and tertiary pairs. Native hover and drag/drop timing remain pending. Continue reducing work when a real strip width or slot change moves the side seams. Party and raid latency acceptance stays open.
[Matched validation](docs/validation/strip-empty-promotion-2026-11-20.json).
<!-- /STRIP-EMPTY-PROMOTION-R171-20261120 -->

<!-- FLYOUT-ARROW-LAYERS-R172-20261120 -->
Shared flyout arrow refreshes now keep verified layer and scale values when an action-strip move preserves them. Check the remaining duplicate Trinket Menu refresh and cold border work. Native strip and party/raid latency acceptance remain open.
[Matched validation](docs/validation/flyout-arrow-layers-2026-11-20.json).
<!-- /FLYOUT-ARROW-LAYERS-R172-20261120 -->

<!-- BORDER-FALLBACK-PARTITION-R173-20261120 -->
Fallback rectangles now split directly into retained fields. Continue reducing the larger cold fallback-mesh and prepared paint costs. Live action-strip, party/raid and combat-taint confirmation remains open.
[Matched validation](docs/validation/border-fallback-partition-2026-11-20.json).
<!-- /BORDER-FALLBACK-PARTITION-R173-20261120 -->

<!-- BORDER-LISTENER-RUNS-R174-20261120 -->
Warmed strip and roster borders now share consecutive fallback watcher entries. Continue measuring the larger prepared paint cost and first native transitions when available.
[Matched validation](docs/validation/border-fallback-listeners-2026-11-20.json).
<!-- /BORDER-LISTENER-RUNS-R174-20261120 -->

<!-- BORDER-LISTENER-LINKS-R175-20261120 -->
Regional visibility links remove the temporary per-run arrays. The modeled warm crossing still performs about 650 to 680 field writes per strip transition across both styles. Determine how to retain verified native fields through both strip states. Native strip and party/raid latency and taint remain open.
[Matched validation](docs/validation/border-listener-links-2026-11-20.json).
<!-- /BORDER-LISTENER-LINKS-R175-20261120 -->

<!-- BORDER-FIELD-ANCHORS-R176-20261120 -->
Moving border fields now update verified live anchors without erasing points first. The rejected alternate mesh pool and residual writes by category are in the matched record. Continue reducing repeated geometry writes with existing texture resources. Native strip and roster timing and taint remain open.
[Matched validation](docs/validation/border-field-anchors-2026-11-20.json).
<!-- /BORDER-FIELD-ANCHORS-R176-20261120 -->

<!-- BORDER-FIELD-PAINT-R177-20261120 -->
The action-strip priority is the render cost of real expand, collapse and slot-width changes. Prepared replays still apply the changed seam fields. Continue reducing the committed geometry writes and confirm native latency and combat taint when a live capture is available.
[Matched validation](docs/validation/border-field-paint-2026-11-20.json).
<!-- /BORDER-FIELD-PAINT-R177-20261120 -->

<!-- PARTY-ROSTER-DISPATCH-20261120 -->
Party roster dispatch is consolidated and matched against the archived source. Live join and leave hitches remain open. Action-strip crossings still incur renderer work after the prepared border plan is restored. The evidence includes two rejected strip candidates for tile clipping and canvas lookup. It also records repeated bounding-box updates among triangles that share the same canvas and operation, for a narrower render-path comparison.
[Matched validation](docs/validation/party-roster-dispatch-2026-11-20.json).
<!-- /PARTY-ROSTER-DISPATCH-20261120 -->

<!-- BORDER-ROSTER-BOUNDS-R178-20261120 -->
Shared anchor geometry now reduces roster border writes while preserving the tested first compiles and strip crossings. Action-strip changes need a different strategy. Reassigning existing active fields could preserve at most four additional relative shapes per crossing in the measured fixture. Native performance and combat taint remain open for each scenario.
[Matched validation](docs/validation/border-roster-bounds-2026-11-20.json).
<!-- /BORDER-ROSTER-BOUNDS-R178-20261120 -->

<!-- BORDER-SOURCE-ALPHA-R179-20261120 -->
Regional publication avoids duplicate opacity reads on watched sources. Capped alternate strip meshes need more resident textures and visibility writes. The remaining strip cost includes actual geometry changes and replay bookkeeping, with native latency still pending.
[Matched validation](docs/validation/border-source-alpha-2026-11-20.json).
<!-- /BORDER-SOURCE-ALPHA-R179-20261120 -->

<!-- STRIP-EXPANDED-COLUMNS-20261120 -->
Held-action edge crossings omit collapsed packing on entry to the expanded strip. The remaining native latency checks are rapid hover crossings, repeated pickup and drop, and party or raid join and leave. A retained draw-record trial took longer in the modeled replays. The border renderer still republishes the affected seams when strip dimensions change.
[Matched validation](docs/validation/strip-expanded-columns-2026-11-20.json).
<!-- /STRIP-EXPANDED-COLUMNS-20261120 -->

<!-- BORDER-OBSERVED-SOURCES-R180-20261120 -->
The regional renderer reuses observed preflight fields across the same border pass. Armed strip crossings and group changes still need native latency checks. Painter publication at moving joins remains the larger desktop workload. The numeric signature and retirement variants did not reduce the measured workload reliably.
[Matched validation](docs/validation/border-observed-sources-2026-11-20.json).
<!-- /BORDER-OBSERVED-SOURCES-R180-20261120 -->

<!-- BORDER-PANEL-ALIGNMENT-POSES-R181-20261120 -->
Alternating strip states reuse the alignment of their neighboring panels after the initial builds. Remaining native acceptance includes the first and repeated strip edges and drops, party and raid join and leave, and preserved seams and secure input. Sampled full-transaction time remains mixed.
[Matched validation](docs/validation/border-panel-alignment-poses-2026-11-20.json).
<!-- /BORDER-PANEL-ALIGNMENT-POSES-R181-20261120 -->

<!-- GROUP-NAMEPLATE-ANCHORS-20261120 -->
Group-triggered nameplate updates now leave verified quest badge anchors in place. Live group and held-action latency still need verification. The existing roster and follow-up quest updates continue to read provider data on their original schedule. The external attachment replay also isolates 7,680 unchanged frame-level writes per model in the same fixture.
[Matched validation](docs/validation/group-nameplate-anchors-2026-11-20.json).
<!-- /GROUP-NAMEPLATE-ANCHORS-20261120 -->

<!-- GROUP-NAMEPLATE-LEVELS-20261120 -->
Group and periodic nameplate refreshes retain verified levels in addition to their queued quest update and anchor checks. Live group and action strip hitch timing is still open.
[Matched validation](docs/validation/group-nameplate-levels-2026-11-20.json).
<!-- /GROUP-NAMEPLATE-LEVELS-20261120 -->

<!-- STRIP-INFO-ANCHORS-20261120 -->
The modeled action-strip settle path now keeps verified Info and gap-fill anchors and shares envelope geometry reads. Native rapid held-action entry/exit, actual rapid drops, side seams and party/raid timing still need acceptance.
[Matched validation](docs/validation/strip-info-anchors-2026-11-20.json).
<!-- /STRIP-INFO-ANCHORS-20261120 -->

<!-- STRIP-SLOT-SETTLE-20261120 -->
Slot-driven resizing now routes through existing guarded strip settlement. Check rapid drops with actual grid/Info/Trinket movement and first/warm junction commits when native testing is available. Party and raid timing remain open.
[Matched validation](docs/validation/strip-slot-settle-2026-11-20.json).
<!-- /STRIP-SLOT-SETTLE-20261120 -->

<!-- BORDER-CURRENT-DRAW-INPUTS-R182-20261120 -->
The current border version is current-draw-inputs-r182. Prepared strip and roster reflows reuse current native decorative inputs within each commit. Native acceptance for the strip, side panels, combat and group transitions is still open.
[Matched validation](docs/validation/border-current-draw-inputs-2026-11-20.json).
<!-- /BORDER-CURRENT-DRAW-INPUTS-R182-20261120 -->

<!-- ROSTER-AURA-PAINT-20261120 -->
The prepared party and raid aura renderer now retains matching icon/text/visibility through roster paint. Whole-group native hitch timing and the rapid action-strip border cases remain open.
[Matched validation](docs/validation/roster-aura-paint-2026-11-20.json).
<!-- /ROSTER-AURA-PAINT-20261120 -->

<!-- STRIP-EVENT-OWNERSHIP-R183-20261120 -->
The current border version is settled-slot-borders-r183. The remaining action-bar check is repeated held-action crossings and rapid edits with their actual side-panel attachments, followed by party and raid transitions. Measure native frame time and verify combat and seam behavior when those scenarios are available.
[Matched validation](docs/validation/strip-event-ownership-2026-11-20.json).
<!-- /STRIP-EVENT-OWNERSHIP-R183-20261120 -->

<!-- STRIP-GRID-WIDTH-20261120 -->
With the width-only grid path in place, verify live held-cursor crossings on layouts where the strip changes width and where only its inner buttons move. Remaining action-strip cost includes applying the affected grid/Info/Trinket border cells. Live action-strip latency, connected side-panel pixels and protected input remain pending. Party/raid join and leave, embedded minimap and combat timing remain open in the broader task.
[Matched validation](docs/validation/strip-grid-width-2026-11-20.json).
<!-- /STRIP-GRID-WIDTH-20261120 -->

<!-- BORDER-FIELD-RETIREMENT-R184-20261120 -->
Border version regional-field-retirement-r184 removes repeat visibility reads before hiding outgoing textures. The remaining regional work includes current paint checks and applying fields that actually change. Live cursor crossings, party/raid join and leave, side seam appearance and combat taint remain pending. Embedded minimap toggles remain open for the broader goal.
[Matched validation](docs/validation/border-field-retirement-2026-11-20.json).
<!-- /BORDER-FIELD-RETIREMENT-R184-20261120 -->

<!-- PARTY-TARGET-TRAIL-20261120 -->
Party-target roster paint retains verified damage trails across unrelated membership updates. Broader group paint and renderer work remains in scope. Actual party and raid join and leave timing, protected state behavior and the in-game damage trail remain pending. Native held-action strip and border acceptance remain open.
[Matched validation](docs/validation/party-target-trail-2026-11-20.json).
<!-- /PARTY-TARGET-TRAIL-20261120 -->

<!-- STRIP-PARKED-CHROME-20261120 -->
The most recent Lua change reduces the repeated button-art cost on held-action crossings. Width changes still settle the strip, grids, Info, Trinket Menu and join boundaries through the existing transaction. Live rapid cursor crossings and drops, including changing side-panel contacts, remain pending for frame time, seams and combat taint. Party and raid join and leave, embedded minimap toggles and combat exit remain open for the broader goal.
[Matched validation](docs/validation/strip-parked-chrome-2026-11-20.json).
<!-- /STRIP-PARKED-CHROME-20261120 -->

<!-- BORDER-OBSERVER-SCRATCH-R185-20261120 -->
Border version observer-scratch-r185 reduces temporary allocation before the regional compile and paint. Native held-action and rapid-drop latency, real strip-to-panel seams, and party and raid join/leave timing remain pending. Embedded minimap toggles and combat-exit timing and taint also remain open.
[Matched validation](docs/validation/border-observer-scratch-2026-11-20.json).
<!-- /BORDER-OBSERVER-SCRATCH-R185-20261120 -->

<!-- PARTY-STATUS-OWNER-20261120 -->
Normal party roster paints now place role and level indicators a single time per frame. Actively changing role icons still move to their final portrait slot. Live party and raid membership frame times, combat behavior and exact indicator rendering remain unverified. Held-action crossings, rapid drops, embedded minimap toggles and combat-exit timing remain open for the wider goal.
[Matched validation](docs/validation/party-status-owner-2026-11-20.json).
<!-- /PARTY-STATUS-OWNER-20261120 -->

<!-- HUD-PERFORMANCE-ROADMAP -->
Use the [HUD performance roadmap](docs/HUD_PERFORMANCE_ROADMAP.md) for the active performance goal. HUD-1 is the current action-strip priority. Update the matching roadmap row and checkpoint whenever implementation or verification makes measurable progress.
<!-- /HUD-PERFORMANCE-ROADMAP -->

<!-- STRIP-GRID-RING-20261120 -->
HUD-1 remains the current priority. The grid width crossing now skips duplicate ring refits. Review work that remains when the strip and its neighboring panels really move. Live held-action and rapid-drop timing, actual side seams and combat taint remain open. Party and raid membership timing, embedded minimap transitions and combat exit remain open for the wider goal.
[Matched validation](docs/validation/strip-grid-ring-2026-11-20.json).
<!-- /STRIP-GRID-RING-20261120 -->

<!-- STRIP-ARROW-OWNER-20261120 -->
HUD-1 remains the current priority. The action-strip envelope now shares its completed flyout refresh with the Trinket Menu. Across 60 modeled crossings with 20 attached arrows, explicit shared scans fell from 180 to 120 and all visible arrow updates from 4,800 to 3,600. Trinket layer setters fell from 720 to zero with matching slot anchors, size, scale and atlas layering. Follow the actual held-action boundary and repeated drop through the remaining affected regions. Live held-action and rapid-drop timing, actual side seams and combat taint remain open. Party and raid membership timing, embedded minimap transitions and combat exit remain open for the wider goal.
[Matched validation](docs/validation/strip-arrow-owner-2026-11-20.json).
<!-- /STRIP-ARROW-OWNER-20261120 -->

<!-- STRIP-INFO-MEASURE-20261120 -->
HUD-1 remains the current priority. Info now reuses the width just measured when its hybrid labels match, and adjusts the current render list in place. In 60 modeled width changes, the usual FPS and ping row uses 120 width queries instead of 240. The dense row uses 2,010 instead of 2,220. The item-level and GearScore case keeps all 960 queries because the labels change. The decorative slot skips 120 grid-height reads over 60 crossings. Text, fonts, anchors, tooltip contents and slot visibility match. Follow the settled strip and nearby border regions through held-action crossings and rapid drops. Live held-action and rapid-drop frame time, actual seams and combat taint remain open. The broader goal also keeps group transitions, embedded minimap toggles and combat exits open.
[Matched validation](docs/validation/strip-info-measure-2026-11-20.json).
<!-- /STRIP-INFO-MEASURE-20261120 -->

<!-- BORDER-PANEL-INPUTS-R186-20261120 -->
HUD-1 and HUD-3 now share the panel-record reuse. R186 reuses the nearby-panel records that match either prepared layout. In both styles, 60 repeated scans of a stable seven-panel HUD and 60 alternating warmed strip widths cut 420 new panel records to zero. Sixty new widths create 300 records and retain the same 60 alignment graphs. The native-style rectangle reads, changed decorative boxes and final coordinates match. The phase fixture models panel geometry and does not measure the whole border rebuild. Live held-action crossings, rapid drops, group join and leave, seams and combat taint remain pending. Unchanged-panel scans in the desktop model establish the cost of that phase during unrelated HUD or unit reflows.
[Matched validation](docs/validation/border-panel-inputs-2026-11-20.json).
<!-- /BORDER-PANEL-INPUTS-R186-20261120 -->

<!-- ROSTER-HOVER-DRIVER-20261120 -->
HUD-2 roster binding work now avoids repeated reads. Stable mouse-only roster discovery now skips an action-bar binding scan. Thirty modeled bursts across each client profile go from 570 native binding reads to zero. Early registrations still sample each action binding once per scan, including keys after nil or empty results. Forty newly discovered raid cells cut binding reads from 1,179 to 600 in the Forever model and from 419 to 120 in the Era model. Mouse and wheel routes, discovery and protected write counts match. Current live invite, leave, raid conversion timing and combat taint remain pending. Full action-strip, border seams, minimap and combat exit acceptance remain part of the active roadmap.
[Matched validation](docs/validation/roster-hover-driver-2026-11-20.json).
<!-- /ROSTER-HOVER-DRIVER-20261120 -->

<!-- NAMEPLATE-RANK-ROSTER-20261120 -->
HUD-2 nameplate rank work now shares its group identity reads. Nameplate threat refreshes now share successful public group identity reads for one pass. With 32 visible plates, a modeled party entry uses 10 GUID queries instead of 320. The raid case uses 82 instead of 2,624. A confirmed tanking player already has rank one, allowing the same raid replay to use 64 detailed threat queries instead of 2,592. Matched text, tint and plate lookups remain equal in all three client models. Live party and raid join or leave timing and native secret-value and combat checks remain pending. Action strip, border seams, embedded minimap and combat exit acceptance remain open for the wider goal.
[Matched validation](docs/validation/nameplate-rank-roster-2026-11-20.json).
<!-- /NAMEPLATE-RANK-ROSTER-20261120 -->

<!-- BORDER-CELL-BUDGET-R187-20261120 -->
R187 reduces capacity checks from 7,560 region visits to 2,340 across 60 warmed action-strip crossings per border style. The modeled fields, sampled colors and opacity, and admitted draw records match. HUD-1 remains the priority. Continue with retained draw and layer work around the strip and nearby panels. Native action-strip latency, party and raid transitions, seam pixels and combat taint remain pending. The desktop replay counts capacity work and does not measure client frame time.
[Matched validation](docs/validation/border-cell-budget-2026-11-20.json).
<!-- /BORDER-CELL-BUDGET-R187-20261120 -->

<!-- HUD-ACCEPTANCE-R187-20261120 -->
Finish with the bounded acceptance matrix in the HUD performance roadmap when a live test opportunity opens. A failed check can reopen implementation for its owner. All 14 pinned runtime paths match in each local client tree. The goal is blocked after three consecutive readiness checks found the desktop in use. The live scenarios and confirmation of the loaded revision remain pending.
[Matched validation](docs/validation/hud-acceptance-r187-2026-11-20.json).
<!-- /HUD-ACCEPTANCE-R187-20261120 -->



























































































<!-- BORDER-BUILDER-EXPANDED-GOAL-20261119 -->
The active performance goal covers party and raid joins and leaves and action-bar
drag and drop. The reported drag hitch occurs while holding the same action as
the cursor enters or leaves the strip sensing area. Test expansion and collapse
before any slot changes, as well as slot swaps, column growth and shrinkage.
When a real change moves the combat grid, Info frame,
Trinket Menu, or action strip, their shared borders must settle on both sides
from the final positions. Keep other borders prepared, preserve the current
appearance in both styles, and respect combat lockdown. Verify live timing,
combat taint and rendered seams when the scenarios are available.
<!-- /BORDER-BUILDER-EXPANDED-GOAL-20261119 -->










<!-- LHO-PERSIST-REF-ELIGIBILITY-20261118 -->
18 November: applied private same-pass saved-reference eligibility reuse in Persist.lua7082172e and Scan.lua21883c7d;**native adoption/performance acceptance PENDING**. Current client still runs preceding source until the next guarded reload. Direct public reads retain live checks. Matching numeric ID/kind can reuse only this synchronous scan's already-checked allowed result;clock/frame/scan serial/classifier revision/bag generation/runtime publication and defining owner checks guard reuse. Changed public persist/score/item helpers,metatables,secret IDs,missing approvals,reentry or later frames take ordinary checks. Normalization/scrub/ratchet/cold retries/features/look/cadence retained. Professions loads later than Persist;its owner pins on first query.

Dated external source/history verified;12settings stat rows. Before/afterLua5.1/5.4syntax8checks PASS;original GetRef/MaybeUpdateRef cores restored exactly after removing only approval plumbing,remaining vendor bodies unchanged;30Retail/Forever sourcepairs match. Native99/100 baseline7passes/3s,4stored full4.618000/4.336800/5.275400/5.667300ms;notify0.036400/0.036700/0.055700/0.043300ms. Runtime retained/errors0,methods restored/rootsclean. No new simulation. Native92-98 prior evidence found17tooltipreads/13for7valid IDs;no proposed gain accepted yet.

Next: stop currentR19host33664 before guarded adoption reload,install freshjumpcue,then current counts/fullrecords and same scan-only timing protocol. Keep allclient/override/reentry/secret/taint/pixel/controller/fullworkflow/FPS acceptance OPEN;do not infer from source checks. Useraway:asknoquestions;pause promptly withCANCEL/nativeJUMP_STOP before requestedreload. FullLHO01-13ACTIVE. Preserve all unrelatedwork/no commits or external addon edits.
[Exact checkpoint and pending validation](docs/validation/persist-ref-eligibility-2026-11-18.json).
<!-- /LHO-PERSIST-REF-ELIGIBILITY-20261118 -->


<!-- LHO-PASSIVE-TOOLTIP-ATTRIBUTION-20261118 -->
18 November native92-98: actual passive validation attribution,**no productLua edit/new simulation/reload**. Three-second trace7passes/4stored,all classifyPendingRead retain runtime. Full envelopes4.410900/4.180900/5.288500/4.404300ms;17tooltipreads each cost2.240000/2.080900/2.305200/2.164900ms. GetInfo82calls cost0.0580/0.0573/0.0603/0.0581ms;GetFirst17calls cost0.1352/0.1391/0.1407/0.1357ms. Nested inclusive costs overlap/include wrappers;not additive/FPS/hitch/beforeafter evidence. Rounded6decimal transcriptions;original PNGs retained.

One94pass has17reads/11IDs:1487x1,1645x2,2633x1,3703x1,3928x2,4599x3,4601x1,5634x1,6149x2,7516x1,8544x2. Pending2633/3703/5634/7516 eachreadonce;7valid IDs account13reads. Returned pending strings describe cure/alcohol/movement immunity/readable item. Do not force-reject or change0.4s cold retries on current strings alone.

Correction:94broad caller-tag search matched the classifier filename embedded in unnamed loadstring source;all classify labels INVALID,counts/pendingflags remainvalid.96rawstack overflowedchat;97filteredstack partlyclipped. Complete caller attribution remainsunproven;use explicit chunk names/anchored addon frames next.97PNG personally viewed butACK attempted too late and rejected asstale;not restamped/replayed or called ACKed.98fresh independentread/ACK confirms all owned92/94code/reports absent,jumpcueactive,cursorclear/errors0,food1487-14-841/preferences0-120-30 unchanged;freshbuild1.60.1/70959/16001/project18. All addon-method wrappers restored byidentity;no nativeAPI replacement/item actions/external-addon edits.29Retail/Forever sourcepairs freshlymatch.

CurrentR19_J90q/j18n90a7 host33664/supervisor14932 remains;180s queue forchat/casts/crafting/unsafeinput,15sPCidle exception,movementunverified. Pause promptly viaCANCEL/nativeJUMP_STOP before requestedguardedreload. Useraway:asknoquestions. Next: shared per-pass eligibility for repeated valid-item reads with defining-method/override/reentry guards;no candidate yet implemented/measured. Keepfreshness/features/cadence and coldretry contracts. FullLHO01-13ACTIVE;~5ms path and broader workflow/provider-off/client/taint/pixel/controller/matchedFPS-spikes remainOPEN. Accepted Score13f/Scan94c/parser689/recipe9a and priorwork intact;no unattended merchant automation.
[Exact attribution and limits](docs/validation/passive-tooltip-attribution-2026-11-18.json).
<!-- /LHO-PASSIVE-TOOLTIP-ATTRIBUTION-20261118 -->


<!-- LHO-SCORE-REQUIREMENT-PREFILTER-REJECTED-20261118 -->
18 November: rejected the requirement-parser literal guard after checking the actual active workload. The two-line candidate in Inventory/FluxConsumableBest/Score.lua13f28db1 ->86b4fe20 skipped patterns when lowercase text lacked "requir". Native81/82 used54real carried-item tooltips,34without the fragment:three alternating270-call pairs old0.780300/0.739700/0.725000ms,new0.576400/0.561700/0.531800ms,all54results equal. Acquisition/native restriction reads were outside these parser timings. This mixed inventory includes materials/gear and does not establish the consumable hotspot's benefit.

Native88 narrowed the same private comparison to7actual published consumables,allwith requirement text:three alternating140-call pairs old0.511600/0.497400/0.512500ms,new0.535200/0.525100/0.518200ms. Allresults match,but every candidate pair is slower. Removed ONLY the two inserted lines;whole file restored exactly13f28db1,all earlier accepted Score/parser/Scan/queue/recipe/vendor/EBS work retained. No new simulation. Fresh before/after/restoredLua5.1/5.4syntax and29Retail/Forever sourcepairs pass;dated source/history and12settings-stat records retained externally. Initial immediate diskpair check failed after write;later allmatch,no manualsync;visibility cause unproven.

Own83reload adopted the trial;native85 retained54counts/food1487-14-841,providers/errors/preferences. Native86/87 full IsKnownUnusable comparison on54actual items also matched,0failures/0errors,both variants blocked0 (no real rejection branch induced). After rejection,own89guardedreload readiness ACKed and fresh startup separately viewed;native91 freshly1.60.1/70959/16001/project18,bothSyndicator+Baganatorloaded/source syndicator/readytrue,54counts0mismatches,samefood/queue4/errors0/preferences0-120-30,cursorclear. Owned probes/reports removed;no installed/native API replacements,craft/mail/item transactions or external addon edits. Unrelated party/loot-setting traffic is a retained confound,not this goal's commands. No causal full-validation/FPS/hitch claim.

Current jump R19 _J90q/j18n90a7,supervisor14932/host33664/live20261118s verifiedlive. R17host42332 andR18host42984 stopped/verified absent before respective reloads;only matching ownedstop/setupholdsremoved,INPUT_HALTED retained. Keep180s queued forchat/casts/crafting/unsafeinput;15sPCidle activation/priorapp restoration exception;Space injection is not visual movement proof. Pause promptly with CANCEL/nativeJUMP_STOP before requested guardedreload;freshnonce afterresume. Useraway:asknoquestions. All trial inputs spent;do not replay.

FullLHO01-13ACTIVE. Prior recipe9a12130d still accepted:148cached fullrecords/reagents match native79/80;local warm-query saving only. Next: real tooltip-acquisition/repeated eligibility work for the active consumable set,then established-evidence Inventory/EBS fixes. Do not reapply this guard,the rejectedR29catalogue/taskcopy caches or unmeasuredlegacy-index hint. Broader vendor/AH/bank/mail/pending/craft/cast/provider-off mutation,otherclients/taint/pixels/controller and matchedFPS/spikes remainOPEN. Vendor unattended opening remains unsafe without native Shift skip.
[Exact rejection and restoration evidence](docs/validation/score-requirement-prefilter-2026-11-18.json).
<!-- /LHO-SCORE-REQUIREMENT-PREFILTER-REJECTED-20261118 -->


<!-- LHO-PROFESSION-LIVE-SCHEMATIC-20261118 -->
18 November: actual **Inventory/Professions.lua39c656ae -> 9a12130d** removes a duplicate native schematic read from GetRecipeLive. A successful quantity helper now returns its fresh schematic as a third private result;the same call passes it to the existing reagent extractor. Three substitutions only;no persistent cache/event/timer/cadence/public-result changes. Other callers consume their original two results;nil/error/non-table quantity lookups still leave the ordinary reagent retry/fallback. Whole-file three-substitution restoration and measured-worker equivalence PASS;before/afterLua5.1/5.4parse PASS. Dated external source/history verified,12settings stat rows;29Retail/Forever diskpairs match,no manualsync or new simulation. Preserve existing17November profession edits;8095e63c followup execution unchanged.

Native73 finds148cached recipes and modern APIs while professioninfo is absent;actual learned IDs1263032SpinningWheel/1263425FactionBanner/18560Mooncloth returnlive quantity1 and3/2/1reagentrows. Before edit,74 compares unmodified public query vs private candidate:threealternatingpairs,9queries pervariant perpair,old0.258700/0.263900/0.271200ms,new0.202700/0.211700/0.214800ms. All returned fields/nested reagent rows match3of3perpair;installed method unchanged. After own75reload,78 compares exact preceding private helpers with current installed query:old0.242800/0.263000/0.260800ms,new0.190100/0.186700/0.203000ms;again3of3fullrecordmatches eachpair/installedidentityretained,errors0,ownedrootsremoved. Local warm-query saving only;public/private placement,cache/world/system/GC/unrelated party activity are confounds. No overall FPS/hitch/Pendingbutton/end-to-end crafting claim;no party actions were this goal's commands.

Own75guardedreload readiness ACKed/freshstartup separately viewed. Native77 freshly1.60.1/70959/16001/project18,bothaddonsloaded/source syndicator/readytrue,54counts0mismatches,food1487/14/841 unchanged,queue4,errors0,preferences0/120/30,cursorclear. No craft/consume/buy/sell/delete/mail/window-opening or nativeAPI overrides. Packaged pinned schema says Retail/Forever GetRecipeSchematic returns CraftingRecipeSchematic;Forever snapshot70862 differs from actual70959. Classic declaration miss is unknown,not removal. Node18 narrow-query launch hit EPERM/insufficientversion;read only matching packaged JSON instead. Otherclients,quality/foreign/partial/cold/skill-change paths,largecatalogue/currentrecipe-change/actual craft lifecycle,taint/pixels/controller and matchedFPS/spikes remainOPEN. FullLHO01-13ACTIVE;~5ms consumable validation and broader vendor/AH/bank/mail/pending/craft/cast/provider-off mutation work remains.

Fresh R17 _J76q/j18n76a7 installed/ACKed;supervisor46232 launchedhost42332/live20261118q,host liveverified,3Spacepairs at recordtime,motionunverified. R16host37972 stopped/verified absent before reload;only ownedstop/setupholdsremoved,INPUT_HALTEDretained. Keep180s queued during commands/casts/crafting/unsafeinput;15sPCidle activation/priorapp restoration exception. Pause promptly viaCANCEL/nativeJUMP_STOP before requestedguardedreload;freshnonce afterresume. Useraway:asknoquestions. PreserveScan94c403db/Score13f28db1/parser689c630a/queue36a7b896/Craft853273d8/paneldc6de0aa/Watch08350be5 and unrelatedwork. Next: other real recipe IDs/full-field query coverage and established-evidence inventory/crafting fixes;do not apply unmeasured legacy-index or rejected catalogue/task-copy caches. Vendor unattended opening remains unsafe without genuine Shift skip.
[Exact source and native evidence](docs/validation/profession-live-schematic-2026-11-18.json).
Native79/80 follow-up: all148actual cached recipes returnlive from both exact preceding private worker and installed current query;148full-record/nested-reagent matches,0mismatches/0failures,101learned,148withreagents,4quantityMin~=1. Three recipes per0.1s batch;5.078s walltime,maxpaired-query-plus-comparison1.1447ms (not frame/FPS). Installed method identity unchanged;probe/report removed,jumpcue restored,cursorclear/sessionerrors0. This closes current cached-catalogue field parity only;foreign/partial/quality/cold/skill-change/end-to-end UI and otherclient checks remainOPEN. Fresh29Retail/Forever sourcepairs unchanged;no addonLua edit or new simulation in this follow-up.

<!-- /LHO-PROFESSION-LIVE-SCHEMATIC-20261118 -->


<!-- LHO-NATIVE-CURRENT-BAG69-20261118 -->
18 November: current-source real bag mutation acceptance,**no addon Lua edit or new simulation in this slice**. Food4599x18 moved0:8->2:6 and returned automatically on firstattempt;final0:8has4599x18,destinationempty,cursorclear,baggen5->7. All54carried counts match WoW;food1487/count14/effective841 retained,bothSyndicator+Baganatorloaded/source syndicator/readytrue,queue4,errors0. Current Scan94c403db/Score13f28db1/parser689c630a/queue36a7b896 and all28Retail/Forever pins freshlymatch. After ordinary inventory changes rebuild publication, later Bestgeneration2169->2170 retains the same runtime across0.6s:reuse continues with fresh snapshot cardinalities. Full REUSE69 tuple personally viewed in finishcapture;helperREUSE70 prints only its first tuple value because of Lua and-expression adjustment,not an addon error.

One existing optional watch30.003s/4289driverframes/220observedcallbacks:peak34ms,0recorded>=50ms gaps,0observed>=10ms callbacks,watcherrors0/0. Directmove/return envelopes4.7003/3.4735ms at442388.800/442390.801;Notify0.710400/0.526700ms at442388.986/442390.987. No matched before/after FPS/spike gain or regression inferred from earlier source/windows. Watch covers specific service seams,not every handler/GPU/taint/pixel/controller/client. OriginalNotify/prior diagnostic root/prior spike report restored by identity;watchstopped,owned_M69/_M69r removed,originaljumpcueflag restored. Preferences0/120/30 unchanged;no buy/sell/delete/consume/mail/craftqueue/external-addon actions. Nativewatchfreshly1.60.1/70959;interface16001/project18 retained from native68.

Read-only vendor entry review pins Buy3e0b50e0:MERCHANT_SHOW latches private native Shift skip;otherwise After0 begins fastselling/repair. No public session-suppression setter found in inspected Buy/Session modules. Do not open unattended or replace native modifier APIs;vendor lifecycle acceptance remains pending. FullLHO01-13 staysACTIVE. Cold/newloot/quantitydepletion/charges,provider-off mutations,allkind/fullfield selection parity,bank/mail/vendor/AH/pending/craft/cast/otherclients and matched FPS/hitch benefits remainOPEN. Next: current-source Food cast/cancel/receive check if needed,then established-evidence Inventory/EBS fixes;keep0.4s cold retries/liveeligibility and ordinary notifications. No new simulation or foreign-addon edits.

R16 _J65q/j18n65a7 remains current,host37972/live20261118p via supervisor42708;liveverified,7Space pairs at recordtime,motionunverified. No reload69;temporaryjumpcue remains valid. Keep180s queued aroundcommands/casts/crafting/unsafeinput;15sPCidle activation/priorapp restoration exception. Stop promptly onpause viaCANCEL/nativeJUMP_STOP before requestedguardedreload;freshnonce afterresume. Only ownedprobe state touched;INPUT_HALTED retained. Useraway:asknoquestions. Preserve unrelatedwork/main;no commit/publication.
[Exact current native evidence](docs/validation/inventory-current-native-bag69-2026-11-18.json).
Native72 follow-up: currentclient/session GetTradeSkillLine/GetNumTradeSkills/GetTradeSkillInfo/GetTradeSkillReagentInfo allnil,TradeSkillFrameabsent/Skilletclosed,cursorclear/errors0;no windows opened or crafting. Do not apply the unmeasured legacy-readiness index hint on this evidence. CanCraft discards Prepare index while CraftClick consumes it;future readonly hint must revalidate full live recipe and retain execution search/order. Review modern profession path next. This is current-session absence,not allclient removal. Gate rejected initial incorrect controller hash before native input;fresh label used with actual builder hash.
<!-- /LHO-NATIVE-CURRENT-BAG69-20261118 -->


<!-- LHO-PUBLICATION-CARDINALITY-20261118 -->
18 November: actual Scan.lua **8f9ebfdb -> 94c403db** saves each private publication row's entry count during ordinary snapshot creation. The original secret-value checker path verifies live key/value matches once plus cardinality for removals; the exact preceding two-pass worker remains for checker replacement. All secret/metatable/depth/128-table guards and scan/classifier/count/persist/selection/notification/retry/cadence paths remain. Cardinality uses pairs,including false values,not length. Whole-source restoration and measured-worker source equivalence (comments/whitespace/local names only) PASS;before/afterLua5.1/5.4parse PASS. An initial overly strict blank-line text comparison failed; normalized worker comparison passes. Dated external source/history verified,12settings stat rows,28Retail/Forever diskpairs match,no manualsync or new simulation.

Before editing, native63 privately compares exact preceding worker against candidate on **23real current published tables/158entries**,5calls pervariant perpair,three alternating pairs. Old0.599500/0.554200/0.900700ms;new0.344900/0.334800/0.532000ms;all true/true,real public tables unchanged,private root removed,errors0. Applied candidate worker matches measured worker. This establishes an isolated native comparison saving; snapshot construction/cardinality capture was outside that timing. No mocked item data,synthetic mutation suite or nativeAPI/installed-dispatcher replacements. Removal/addition/change equivalence is source proof; intentional secret/metatable/checker replacement cases were not natively induced.

Own64guardedreload readiness ACKed/freshstartup separately viewed. Current-source66/67 retains runtime identity on all4stored of7passive passes/3s,reason classifyPendingRead,4invalidations perpass,ordinary notifications;both dispatchers restored and roots removed. Fullpass4.8186/6.0142/5.4133/5.0837ms versus previous-source4.8335/5.6013/5.6334/5.7219ms:overlapping variation acrossreload. Mean5.447525->5.332450ms does NOT prove overall gain or regression;~5ms remains OPEN. Native68 freshly1.60.1/70959/16001/project18,bothaddonsloaded/source syndicator/readytrue,54nativecounts0mismatches,food1487/14/841 unchanged,queue4,errors0,preferences0/120/30,cursorclear. No FPS/hitch/all-workflow/otherclient/taint/pixel/controller claim.

Fresh R16 _J65q/j18n65a7 installed/ACKed;supervisor42708 launchedhost37972/live20261118p,host liveverified,2Space pairs at lastread,motionunverified. R15host56040 stopped/verified absent before reload;only ownedstop/setupholdsremoved,INPUT_HALTEDretained. Keep180s queue around commands/casts/crafting/unsafeinput;15sPCidle activation/priorapp restoration exception remains. Pause promptly viaCANCEL/nativeJUMP_STOP before requestedguardedreload;freshnonce afterresume. Useraway:asknoquestions. FullLHO01-13 ACTIVE. PreserveScore13f28db1/parser689c630a/queue36a7b896/Craft853273d8/paneldc6de0aa/Watch08350be5 and unrelatedwork. Next: safe real bag relocation/automaticreturn on current sources,verify fresh publication/count/selection and restored inputs;then remaining Inventory/EBS validation/tooltip costs. Cold/depletion/charges/provider-off mutations,bank/mail/vendor/AH/pending/craft/cast/allclients and matchedspike gains remainOPEN. No unattended merchant transactions or new simulation.
[Exact source and native evidence](docs/validation/publication-cardinality-2026-11-18.json).
<!-- /LHO-PUBLICATION-CARDINALITY-20261118 -->


<!-- LHO-SCORE-RESTRICTION-CAPABILITY-20261118 -->
18 November: actual Score.lua **c542c20d -> 13f28db1** now checks the four existing restriction enum members before fetching native tooltip data. Native57 Forever70959 exposes their table but all four members are nil; food1487 native lines have types22/0/44/43. Unsupported typed-color checks now return false without the unusable native read; existing textual level/skill fallback stays live. Supported-member fetch/line body remains. Intentional compatibility fix: nil line.type must not match a nonexistent enum member as positive restriction evidence; that unknown/red case was not natively induced. No cache, timer, event, retry or cadence changes. Whole-source restoration proof and before/after Lua5.1/5.4 parse PASS; dated external source/history verified,12settings stat rows,28Retail/Forever disk pairs match; no manual sync or new simulation.

Native52 identifies classifyPendingRead:4invalidations every~0.4s,5.31-7.11ms inclusive. Native55/56 corrects the earlier rebuild hypothesis: runtime identity is retained on all four stored passes, so reuse works. Notification envelopes only0.0381/0.0617/0.0430/0.0411ms; the repeated validation/retry path owns most observed cost. Before55 first4of7 passes:5.4691/5.9857/7.2414/5.9833ms. After60 first4of7:4.8335/5.6013/5.6334/5.7219ms; runtime identity retained,4invalidations and ordinary notifications continue. One3s window per source acrossreload; mean6.169875->5.447525ms (11.7% lower observed),median5.98450->5.61735ms (6.1%). World/cache/system/GC differences and transparent-wrapper overhead remain. No causal FPS/hitch or full-workflow claim;~5ms passive cost remains open.

Own guardedreload58 readiness ACKed and freshstartup separately viewed. Native61:1.60.1/build70959/interface16001/project18;both Syndicator+Baganator loaded,source syndicator/readytrue,all54carried counts match native;food1487/count14/effective841 unchanged;queue4,errors0,scriptProfile0/maxFPS120/maxFPSBk30,cursorclear. Five actual eligible IDs remain unblocked;empty managem remains blocked. All trace dispatchers restored by identity;owned roots removed and prior diagnostics untouched. Four after rows scrolled off61;62 reads existing chat history only,not a replay. Percentage/cold/depletion/charges/other-provider mutations,typed-red/locale/otherclient/taint/pixels/controller and bank/mail/vendor/AH/pending/craft/matched spike coverage remain OPEN. Do not drop cold retries or change0.4s cadence.

Fresh R15 _J59q/j18n59a7 installed/ACKed;supervisor55536 launched host56040/live20261118o,host liveverified and2Space pairs at last read. R14host20380 stopped/verified absent before reload. Only owned stop/setup holds removed;INPUT_HALTED retained. Keep180s jumps queued during commands/casts/crafting/unsafeinput;15sPCidle activation/prior-app restoration exception remains,motion unverified. Pause promptly viaCANCEL/nativeJUMP_STOP before requestedguardedreload;freshnonce afterresume. Useraway:ask noquestions. FullLHO01-13 goal ACTIVE;preserve parser689c630a/queue36a7b896/Scan8f9ebfdb/Craft853273d8/paneldc6de0aa/Watch08350be5 and unrelated work. Next: reduce remaining live eligibility/tooltip validation cost without stale caching or skipped callbacks;safe real workflows only. No unattended merchant transactions.
[Exact source and native evidence](docs/validation/score-restriction-capability-2026-11-18.json).
<!-- /LHO-SCORE-RESTRICTION-CAPABILITY-20261118 -->


<!-- LHO-PARSER-KEYWORD-POOLS-20261118 -->
18 November: parser source **689c630a** is loaded through our guarded reload48 and a separately viewed fresh startup. Native50 freshly reports Forever1.60.1/build70959/interface16001/project18, both Syndicator and Baganator loaded, source syndicator and ready. All54carried item counts match WoW; selectedfood1487/count14/effective841 is unchanged. Native51 retains3food/1water/1bandage/1heal/1mana classification matches;7current fixed records match unchanged scoring with live pools. Errors0,scriptProfile0,maxFPS120/maxFPSBk30;owned probes cleaned. Percentage/cold/otherclient/taint/pixel/controller and full-field comparisons remain open.

Native parser samples,50calls per sample on10real tooltips: before663a539a2.325100/2.471400/2.363900ms;after689c630a1.740600/1.904900/1.771100ms. Median2.36390->1.77110ms (~25.1% lower observed). Same collection method/inputcount/pools1037/2637;exact strings/IDs/order not exported. One sequential batch per revision acrossreload with cache/world/system differences supports a local observation,not causal FPS/fullworkflow/hitch gain. Source proof and5.1/5.4parse remain;28Retail/Forever diskpairs freshly match,0new simulations/manualsync. Three changes only:impossible flatcombo/generic resource guards and unused nonpercentage pool reads;no cache/retry/cadence changes.

The larger cost remains open. Prior native43-45 identifies actual2633/5634/7516 and3tooltip reads0.6039ms within1.0674ms nested query;source663a539a retained separately. Current full food query0.593300ms remains above initial0.147600ms baseline and below later0.818500/0.703600ms observations;states differ,so no fullquery gain claim. Native47 shows4invalidations betweencommands,but none inside its3GetAllBest calls;caller remains unproven. Next: trace actual tooltip collection and background invalidation owner,keeping live text/latecold recovery and0.4s read cadence. Do not drop pending retries or transfer old native acceptance.

Current jump helper is R14 _J49q/j18n49a7,host20380/live20261118n via supervisor26456,installed/ACKed and freshly liveverified. R13host51700 stopped/verified absent before reload. Guarded180s Space pairs/prior-app restoration requested;visual movement unverified. Queue aroundcommands/casts/crafting/unsafeinput;retain15sPCidle exception. Only our stop/setup markers removed;INPUT_HALTED retained. Stop promptly onpause viaCANCEL/nativeJUMP_STOP before requestedguardedreload;installfreshnonce onresume. All native probes finished;only intentional jumpcue remains. Useraway:ask noquestions. FullLHO01–13 ACTIVE;preserveScorec542c20d/queue36a7b896/Scan8f9ebfdb/Craft853273d8/paneldc6de0aa/Watch08350be5 and unrelated work. Broader workflow/provider/client coverage and matched spike gains remainOPEN.
[Exact source and native evidence](docs/validation/parser-keyword-pools-2026-11-18.json).
<!-- /LHO-PARSER-KEYWORD-POOLS-20261118 -->

<!-- LHO-SCORE-FIXED-RESTORE-20261118 -->
18 November: Inventory/FluxConsumableBest/Score.lua a1d84a7d->c542c20d skips unused health/mana pool queries when missing pool arguments, original pool getter, plain nonpercentage record and numeric effective fully determine the result. No pool cache; supplied-pool/percent/nonnumeric/metatable/replacementgetter paths retain original full body. Removing only capture/early guard restores preceding whole source. Before/afterLua5.1/5.4parse and whitespace PASS; dated external source/history verified,12settingsstat rows;28Retail/Forever disk pairs match, no manual sync/new simulation. Tiers Match allocation idea was not applied;1a02bc12 remains.

Own guardedreload39 readiness ACKed/freshstartup separately viewed. Real queries over54IDs keep matches3food/1water/1bandage/1heal/1mana;7actual fixed restore values equal original explicit-live-pool calculation,selectedfood1487/14/841 unchanged,bothaddonsloaded/source syndicator/readytrue,errors0,cursorclear. Exact preceding scorer retained privately for native42 comparison against live candidate on7actual cached records:3pairs,140calculations pervariant perpair,old0.989300/0.979100/0.988300ms,new0.074500/0.081100/0.095500ms. All7outputs equal;public candidate identity unchanged. This is an isolated native computation gain,NOT FPS/full workflow proof.

OPEN regression/uncertainty: full first food query0.147600ms before versus0.818500after and0.703600followup;all samples retained. Othercategory samples smaller, but full query gain is unproven. Isolated scorer is faster;food-path cause not isolated. Revalidate actual pending items/cold classification/retries next;do not attribute to tooltip/cache/world or reject cold food without evidence. Previous4pending IDs are historical,not freshly queried39-42. Percentage/override/metatable paths source-reviewed,not natively induced. Full merchant/AH/pending/bank/mail/crafting/provider/cast/client/taint/pixel/controller/matched spike acceptance remains OPEN.

All owned _T39/_T40/_T41/_S42 code/data removed;no native APIs overridden,transactions or item moves;preferences preserved. CurrentR13 _J40q/j18n40a7 installed/ACKed,supervisor56212 launchedhost51700/live20261118m,live verified;oldR12host48628 stopped/verified absent. Guarded180s Space pairs and prior-app restoration requested;movement unverified. Queue during commands/casts/crafting/unsafe input,retain15s idle exception. Stop promptly onpause viaCANCEL/native JUMP_STOP before requested guardedreload;freshnonce afterresume. Only owned holds removed,INPUT_HALTED retained. Useraway:ask noquestions. Whole LHO01–13 ACTIVE;preserve queue36a7b896/classifier663a539a/Scan8f9ebfdb/Craft853273d8/paneldc6de0aa/Watch08350be5 and unrelatedwork.
[Exact source and native evidence](docs/validation/score-fixed-restore-2026-11-18.json).
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
[Exact source, native samples and limits](docs/validation/inventory-queue-minimum-2026-11-18.json).
<!-- /LHO-INVENTORY-QUEUE-MINIMUM-20261118 -->

<!-- LHO-CRAFT-CLIENT-PREDICATES-20261118 -->
18 November: actual Inventory/Craft.lua edit75197d0a->853273d8 removes private8-field ClientFlags allocation. Dynamic scalar IsPostDF/IsCamelot preserve original relevant primary/fallback precedence,Forever aliases,truthiness and FirstAid rules. No flag/recipe/native-fact caching. Restoring only private predicate region plus old IsPostDF definition exactly restores preceding whole source after newline normalization;all other public/native/classification/count/reagent/rank/cache/event/refresh bodies remain. Before/after5.1/5.4syntax and whitespace PASS;26Inventory/EBS/helper Retail/Forever disk pairs match without manual sync. Dated external source/history verified and12settings stat-only rows available;no private settings contents copied or new simulation.

Native34 before/after scoped crafting readiness PASS:availabilitytrue/true/true,list sizes5heal/2mana/9bandage,same no-affordable best selections,plain client/API flags. Before list calls1.6934/1.2390/1.0011ms;after1.6667/1.1857/1.1918ms. One sample each and reload/cache/world differences do NOT prove CPU/FPS/hitch improvement or causal regression;only allocation removal is established. Own ReloadUI command fully queued;initial submitted capture was too early/blankchat and remains unaccepted. Separate personally viewed fresh startup verifies reload association;controller correctly refused submitted-phase refresh,no replay. After-read batch formally ACKed;generation9->5reset,scriptProfile0,no new session errors. Prior diagnostic-only session1 becomes0on normal reload;logs not manually cleared. Native actual crafting/ingredients/active pending legacy execution,full row equality,other clients/taint/pixels/controller remain OPEN.

Reload resets temporary code. R9host49768 stopped/verified absent through owned marker. Fresh R10b _J34q/j18n34a7 cue installed/ACKed;supervisor55884 launched host50368/live20261118j,verified live at15:00:02UTC,3Space pairs/latest14:57:52UTC/prior-app restore requested,motion unverified. Own setup no_jump released;retained INPUT_HALTED preserved. R10source-only package neverexecuted;R10b byte lengths recomputed for longer nonce. Initial install_a begin stopped before input because setup hold absent;fresh install_b accepted,never replay spent packets. Current stop protocol CANCEL/GOAL_DONE/native JUMP_STOP;queue during commands/casts/crafting/unsafe input,15sidle activation/prior-app restore. Pause promptly. User away:ask no questions.

Whole LHO01–13 goal ACTIVE. Other current classifier663a539a/scan8f9ebfdb/paneldc6de0aa and Watch08350be5 preserved. Source review flags pending legacy readiness full-list lookup;do not add a stale index cache without full current recipe/reagent validation and real path coverage. No change to FollowupCraft8095e63c and no revival of rejected catalogue/task-copy candidates. Continue actual Inventory/EBS fixes from existing evidence;no new simulations. Vendor/AH/pending/bank/mail/crafting/provider-off mutations/cold/deplete/charges,allclient and matched spike gains remain OPEN;avoid unattended merchant automation and all buy/sell/delete/consume/mail actions.
[Exact source, native observations and limits](docs/validation/craft-client-predicates-2026-11-18.json).
<!-- /LHO-CRAFT-CLIENT-PREDICATES-20261118 -->

<!-- LHO-NATIVE-CAST-RECEIVE33-20261118 -->
18 November: actual highest-rank Food cast/cancel/complete and received-item check, no simulation or new addon Lua edit. Native trace START+8.438s/STOP+8.682s, three INTERRUPTED+8.814s, second START+9.111s, SUCCEEDED/STOP+12.017s, BAG_UPDATE_DELAYED+12.074/+12.437s relative428631.826. Completed cast creates14Conjured Pumpernickel1487; native/Flux14/14, all54carried IDs0mismatches, generation7->9. Food selection changes to1487/count14/effective841 as new food arrives; queue4 remains. Items retained; no buy/sell/delete/use/mail/craftqueue/external-addon changes.

Existing optional30s watch:30.007s/4362driver frames/998observed callbacks,0recorded>=50ms gaps,peak45ms;1slow inclusive Scheduler structural.callback at+12.455s/15.8371ms,only border.junctions token. This does not prove inventory-exclusive CPU or matched FPS/spike gain. Diagnostic sections69.8221ms total/.1544ms peak,watch errors0/0,scriptProfile0/maxFPS120/maxFPSBk30 unchanged. Exact loaded border/cast hashes not captured; no revision-specific attribution or allclient/taint/pixel certification. PrintWindow/world/system/party activity remains a confound; unrelated party/loot actions were not this goal's commands.

Owned event frame detached and watch stopped; prior diagnostic root/report restored by identity; _C33/_C33r removed, R9 cue prior flag resumed. A later read-only report printer incorrectly table.concat'ed native string tokens, causing1diagnostic-only error AFTER watch/cleanup; corrected tostring print verifies string. Error log preserved; session is NOT zero-error. Final count/selection/root results were personally viewed and formally ACKed. R9 host49768/client42724 freshly verified live at14:35:01UTC,22guarded Space pairs/latest14:32:15UTC; motion not visually verified. Keep180s queue during commands/casts/crafting and15s idle activation/prior-app restore. No reload in33; only intentional jump cue remains. Pause promptly using CANCEL/native JUMP_STOP before cleanup/reload. User away: ask no questions.

Full LHO01–13 stays ACTIVE. Current classifier663a539a,scan8f9ebfdb,paneldc6de0aa and all24Inventory/EBS pins remain unchanged through33. Scoped cast cancel/finish/new-food count/selection acceptance now recorded on Forever70959. Native crafting/channel/delay/pet,provider-off mutations,cold/deplete/charges,merchant/AH/pending/bank/mail workflows and other clients/matched gains remain OPEN. Continue actual Lua fixes from established evidence; no new simulations or unnecessary captures. Avoid unattended merchant opening that could run buying/selling automation.
[Exact native trace, source pins and limits](docs/validation/inventory-native-cast-receive-2026-11-18.json).
<!-- /LHO-NATIVE-CAST-RECEIVE33-20261118 -->

<!-- LHO-NATIVE-BAG-MOVE32-20261118 -->
18 November: real authorized food-stack relocation, no simulation. Unlocked4599x18 moved backpack0:8->genericbag2:4 and automatically returned on first attempt. Final0:8has4599x18,2:4empty,cursorclear;bag generation5->7;native/Flux food18/18,selected food4599/count18/tier1338;all53unique carried IDs still match native,0errors. Both addons remain loaded from restored prior flags. Native70959/1.60.1 observed;scriptProfile0,maxFPS120,maxFPSBk30 unchanged. Existing optional30s watch used;prior diagnostic root AND prior spike report restored by identity, own watch stopped, _M32/_M32r removed, owned jump cue resumed. No buy/sell/delete/use,craft queue,external-addon edits or addon Lua change in this slice.

Actual watch30.001s:4667driver frames/273observed callbacks,3gaps120/248/93ms at+2.540/+2.788/+4.976s. Two slow inclusive scheduler callbacks190.0694/72.3385ms at+2.540/+4.883s, both only tokenborder.junctions;generic label unmapped. They precede the deliberately delayed move (minimum+8s). Direct guarded move/return envelopes4.2417/3.0836ms,GetTime426712.797/426714.801. No recorded>=50ms gap or>=10ms observed Flux-service callback during/after the move phases in this one window. This does not certify all inventory handlers or a paired FPS gain. PrintWindow/setup/system/party activity are confounds;248ms is not attributed to inventory. Exact loaded BorderJunctions hash was not captured;no claim that a particular border revision regressed,and no border source edits here. Recorded diagnostic sections78.3133ms total/.4415ms peak exclude some observer overhead.

Full LHO01–13 remains ACTIVE. Native actual relocation with both addons now has scoped acceptance;cold/loot/new quantities/depletion/charges,provider-off mutations,bank/mail/vendor/AH/pending/crafting,cast/channel/interrupt/finish,all clients/taint/pixels/controller and matched spike improvements remain OPEN. Next: native Food cast/cancel/completion and received-item updates, reusing bounded existing watch with prior diagnostic roots/preferences preserved. CurrentR9 _J23q/j18n9p9 keepalive remains authorized;host49768 last verified live, reverify now rather than trusting a state file. Pause promptly using CANCEL/native JUMP_STOP before cleanup/reload. No questions while user away. Current process42724/window50333792/birth134394624880288175.
[Native phases and ownership evidence](docs/validation/inventory-native-bag-move-2026-11-18.json).
<!-- /LHO-NATIVE-BAG-MOVE32-20261118 -->

<!-- LHO-NATIVE-COUNT-COMBOS31-20261118 -->
18 November: all3legal live addon combinations checked on same Forever client: both11/Syndicator-only10/built-in00 each ready and Flux/native food4599count18/18, scriptProfile0/errors0. Original flags captured before changes; both restored and natively verified loadedtrue, character2/global2. Final restored state compares all53unique carried item IDs with native counts:0mismatches. Seven current best rows recorded; no complete before/after selection equality inferred from the obscured earlier baseline. No agent purchases/sales/deletions/moves/craft queues or external-addon source edits. Unrelated party/loot-setting messages are not this goal's actions and do not establish another test's provenance.

Actual Vendor panel dc6de0aa is now adopted by observed ownC1/restoration reload association, as is classifier663a539a. Vendor tab first-open/hide-show/reentry/cold metadata and actual bag mutation/loot/zero/bank/mail/AH/native frame-spike acceptance remain OPEN; count smoke is not those workflows or a measured performance gain. Existing single30s parser pair remains1168calls/71.3209ms vs1152/60.4172ms, no causal overall FPS claim. All broad LHO01–13 requirements remain ACTIVE. No questions while user away.

Combo reloads reset temporary code. Fresh R9 _J23q/j18n9p9 cue installed/ACKed after original addons restored; supervisor38984 launched host49768/live20261118h. Host49768 verified live at13:32:49UTC;2Space pairs delivered, latest13:30:22UTC, with prior-app restoration requested. Movement not visually verified. Final read-only client capture shows world/chatclosed and refresh notice gone;no reconnect performed;new maxHP1297 versus prior1037 timing windows. Keep180s timer queued during commands/casts/crafting/unsafe physical input. Stop promptly on pause; CANCEL/GOAL_DONE/native JUMP_STOP remain authoritative. Reinstall fresh nonce after a real reload rather than replaying spent packets. Actual world-refresh countdown observed, about13:33UTC due; normal warning/Reconnect/named-character selection already authorized, verify exact client first. Current process42724/window50333792/birth134394624880288175. Next safe checks: native real bag move/return or Food cast/receive under optional bounded existing watch, preserve prior diagnostic roots/preferences; first review current client/cursor/item locations and shared input ownership. No simulation.
[Native evidence and limits](docs/validation/inventory-native-count-combos-current-2026-11-18.json).
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
[Exact sources, audit and evidence](docs/validation/roster-transitions-2026-11-18.json).
<!-- /ROSTER-TRANSITIONS-R70-20261118 -->

<!-- LHO-VENDOR-SELECT-COALESCE-20261118 -->
18 November: user is away for a long time and explicitly says ask no questions. Continue autonomously within existing permissions; unavailable native state stays OPEN, no purchases/sales/deletion or external Syndicator/Baganator edits. Active three-minute jump host is41780 (R8 _J22q/j18n8p9); stop promptly on pause and queue around commands/casts/crafting/input activity.

Edited actual Vendor/FluxVendorRestockPanel.lua e42f40bf->dc6de0aa. Verified SecureTabs.Update invokes OnSelect before SetShown; Restock OnSelect and OnShow both invoke OnTabSelected and queued duplicate After0 rebuilds. One private boolean now preserves the first next-frame callback, reading latest state and resetting before QueryItems so reentrant requests still schedule. Both synchronous tab handlers, invalidation/settings/scroll, hidden-panel checks, row/list/query/count/render bodies,0.2s metadata retry and0.2/0.35s bag/burst refresh remain. Removing only the guard/reset/declaration restores the entire exact preceding source after newline normalization. Before/after Lua5.1/5.4 syntax and whitespace PASS;24Retail/Forever disk pairs match. Dated external source/history verified and12settings stat-only records available. No new simulation; no settings/private contents copied.

This coalescing edit is NOT LOADED yet. Native first-open/tab/hide-show/reentrant/cold-metadata and timing acceptance remain pending; earlier9row2.313ms/empty-panel0.1148ms observations are historical scope, not acceptance or measured reduction. Avoid merchant opening that could trigger buying/selling while unattended. Current adopted classifier663a539a has the recorded30s samples1168/71.3209ms before and1152/60.4172ms after, both restore/error0; one sequential pair is not causal FPS/spike proof. Whole LHO01–13 goal remains ACTIVE. Next safe adoption batch should load dc6de0aa and restore temporary readiness cue after reload; resume legal addon-combination/query/bag UI validation with original flags restored and no transactions.
[Exact sources and limits](docs/validation/inventory-vendor-select-coalesce-2026-11-18.json).
<!-- /LHO-VENDOR-SELECT-COALESCE-20261118 -->

<!-- LHO-PARSER-AXIS-PREFILTER-20261118 -->
18 November: continued actual Inventory Lua work; no new simulation. Direct `FluxConsumableClassify.lua` source663a539a now skips per-line health/mana axis workers only when the normalized line lacks that required literal, and combo-percent only when both are present. All22existing private patterns require their axis word; workers, amounts, percent pools, retry/load/invalidation/budget/cadence and public entry points remain unchanged. Removing only the loop gates restores the entire preceding source. Before/after Lua5.1/5.4 syntax and whitespace PASS;24Retail/Forever disk pairs match. Verified external history/source checkpoint and12settings stat-only rows; no settings contents copied. Concurrent Engine/Watch.lua change08350be5 preserved.

Actual native baseline:30seconds,1168ParseFoodWaterRestore calls,71.320901ms total,0.231800ms maximum; original parser restored, BugTabs session0, bags generation5, queue4, merchant closed. New source adopted through own guarded reload `parserAxisReload_c`, loading screen personally viewed and formal ACK accepted. Native after:30seconds/1152calls/60.417198ms total/0.208700ms maximum; original restored/error0, bagGen5/queue4/merchantclosed unchanged. Observed mean0.06106to0.05245ms (14.1% lower) is a single sequential sample pair with camera/mode/roster and concurrent Watch source differences, not repeated matched causal FPS/spike acceptance. Queue4 remains. No overall FPS/spike gain or other-client certification claimed. Previous cached-negative budget correction was adopted/tested, but controlled scans still queue3; seven-kind equality and restoration true, single6–10ms envelopes do not establish gain.27formal result ACK was late/rejected. Accepted28trace identifies pending5634Free Action Potion,7516Tabetha instructions,2633Jungle Remedy,3703Southshore Stout; observer restored/error0. Read-demand resets and late-tooltip retries remain open; do not simply remove them.

User confirms no other WoW test is running.28also confirms prior jump globals nil, cause unproven. R6waiting supervisor57056 stopped. Fresh R7cue installed/ACKed; host57060 delivered3Space down/up pairs then was explicitly stopped for our reload. Key delivery is not visually verified character motion. R8fresh cue `_J22q`/`j18n8p9` installed/ACKed after own reload; supervisor43356 started for live20261118g. Host41780 process verified live at12:55:17UTC; current readiness calibration passed and a foreground Space key pair completed with input lock released. Three-minute timer active; no visual character-motion certification. Inspect current state on resume. Explicit CANCEL/GOAL_DONE/JUMP_STOP, auth lifetime, idle15 focus exception, advancing readiness/chat/crafting/combat/input ownership gates retained; parent AND capture-child no longer silently expire after600s of agent/tool latency. Failed calibration backs off15s. On pause stop immediately, honor requested guarded reload and record temporary-root reset. Goal ACTIVE; broad Inventory/EBS/vendor/AH/pending/bank/mail/casting/provider combinations remain tracked.
[Exact evidence](docs/validation/inventory-parser-axis-prefilter-2026-11-18.json).
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
[Exact sources and evidence](docs/validation/border-regional-plan-2026-11-18.json).
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
[Evidence](docs/validation/party-material-ownership-2026-11-18.json).
<!-- /PARTY-MATERIAL-OWNERSHIP-R68-20261118 -->

<!-- LHO-CACHED-REJECTION-BUDGET-20261118 -->
18 November: edited actual Inventory/FluxConsumableClassify.lua (2718aaba) and FluxConsumableBest/Scan.lua (8f9ebfdb), on main. Addon-private defining-owner/cache query exempts only already-loaded, exact cached false classifications from budget decrement while budget remains. Still calls ordinary classifier; actual candidate/parse work stays capped24. Exhausted-budget queue path, retries/cadence/live counts/ranking/render bodies unchanged. Replaced Classify/IsPending, metatables or absent private record keep old accounting.8before/after Lua5.1/5.4 syntax jobs PASS; removing only new chunks restores both entire baseline files after LF normalization;24Retail/Forever pairs match. External history bundle verified;12FluxUI settings stat records and byte-exact source checkpoint external, no private contents copied. Native before: generations1918to2152 in186.240s with bagGen10 unchanged, pending load0 and classify queue2to3; contexts flight then vendor, so no controlled idle CPU/FPS inference. IB24 nineteen consumable IDs/47cached negatives across whole bag set, overlap unmeasured. No new simulation/mock. Timing24 setup expired0calls; late arm diagnostic assertion preserved, original method untouched.25arm never succeeded;26batch source-only abort. Native CPU gain unproven. NEW LUA NOT LOADED/NOT NATIVE-TESTED yet. Next guarded reload/adoption and actual queue/selection/count/replacement checks; preserve both grids and all clients. Jump host39428 is STOPPED since11:18 on stale heartbeat, after2successful FG/BG key pairs; current process absent. Restore helper with explicit pause/goal stops and auth lifetime that survives long agent/tool waits; do not claim running yet. Goal ACTIVE.
[Evidence](docs/validation/inventory-cached-rejection-budget-2026-11-18.json).
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
[Evidence](docs/validation/border-regional-render-2026-11-18.json).
<!-- /BORDER-R67-USER-ACCEPTED-20261118 -->

<!-- LHO-JUMP-RESTORED-20261118 -->
18 November jump reminder: current external r5 periodic host PID39428 RUNNING. Supervisor48892 observed native BG red advancing counter and launched the host, then exited. Interval180s after completed pair; latest state linked below. It waits for15s PC idle and fresh readiness before each jump. Due jump stays queued while chat/scripts, casting/crafting, movement or taxi flight blocks it; all actual Space requires original fresh GREEN + chat-open red/heartbeat-green acknowledgement and shared input.lock. First Space pair not yet accepted at this receipt. User currently on taxi (~11min remaining at last photo), so red/queued is expected. Old helpers25000 and49400 stopped with0pairs; do not revive them. Apparent UI restart cleared old cue after earlier vendor checks. New RAM cue _J19q/j18n5p8: first24 setup packets fully queued, Ctrl in packet gap stopped before25; batch terminal, not replayed. Actual INIT true viewed; separately sent only missing enable command, new J83CUE visually ACKed. No addon Lua/settings/item actions. Idle activation/minimized restore paths preserved; native activation repair and first jump remain pending. Stop promptly via P4/CANCEL on pause; verify helper exit and perform requested guarded reload. Reload clears cue; reinstall fresh when continuing. Refresh native/agent-heartbeat every5min during active work;600s stale heartbeat stops it. Inventory24 unchanged; VC24 nine-row2.313ms/empty VR24.115ms remain scoped pre-restart single samples without paired FPS benefit. Goal ACTIVE.
[Evidence](docs/validation/inventory-jump-restored-2026-11-18.json).
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
[Requirements](docs/BORDER_BUILDER_LOCALITY.md), [evidence](docs/validation/border-regional-render-2026-11-18.json).
<!-- /BORDER-REGIONAL-RENDER-R67-20261118 -->

<!-- LHO-VENDOR-COUNTS-LIVE-20261118 -->
18 November: current24 Retail/Forever source pairs remain identical; no addon Lua edits in this slice. Native VC24 successfully refreshed nine actual options rows in 2.3129999637604ms. New VS24 normal tab display and VR24 shown empty sold-only panel count refresh (0.11480003595352ms) visually ACKed. Session count1 is Skillet recipe drag-start nil skill at Skillet.lua:1784; bounded stack read shows SetSelectedSkill/SkillButton_OnDragStart. Counter remained1 through VR24; errors were preserved. No item actions, filters, profiler changes, temporary globals/hooks or simulations. These are single current24 timings, without a matched baseline, per-entry parity or populated panel render certification. Earlier selectionC queued final Enter but failed capture on Foreground unknown; terminal and unaccepted, never replay. BG capture policy now permits switching between other apps while preserving WoW mode/input guards. All command locks released and five lease observer PIDs absent in host read. Duplicate scheduling remains unapplied pending native evidence/cold-readiness review. User renewed three-minute jump request; restore helper next and record actual running state separately. Goal ACTIVE.
[Evidence](docs/validation/inventory-vendor-counts-live-2026-11-18.json).
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
[Evidence](docs/validation/inventory-vendor-panel-live-2026-11-18.json).
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
[Evidence](docs/validation/inventory-vendor-row-ownership-2026-11-18.json).
<!-- /LHO-VENDOR-ROW-RELOAD-20261118 -->

<!-- LHO-VENDOR-ROW-OWNERSHIP-20261118 -->
18 November: latest disk set is24 source files. List030b8a41 + AuctionCraft8462442f
add private row-borrow ownership guard: default ordinary plain rows still reused;
replaced craft getter/SetItemUnits/Need/MailUnits/Pending/PredictedMailUnits,
missing record or metatable row uses original shallow copies. Craft body unchanged.
Eight exact before/after Lua5.1/5.4 syntax checks PASS;24 source pairs match.
NOT YET RELOADED. Last own reload accepted preceding23. Current exact client is
Forever42724/window50333792/birth134394624880288175, version1.60.1/build70959/
interface16001/project18 (fresh BS23 read). It was in world; server warning
alone never established current unavailability. Prior23 normal/fallback actual
food tier1338/item4601 MATCH; final ready/source syndicator, both addons loaded,
1487 snapshot/native0/0, profiling0/errors0. Wrapper restored before print.
Next: verify actual UI/queue, normal guarded reload for24, vendor default and
forwarded-getter isolation/craft route checks. Optional question pending for
user to open vendor with Shift and Restock visible; last viewed world was AH,
not vendor. Do not trigger vendor automation. Retain quantity/zero, active
pending/craft/bank/mail/AH, legal provider combos and other-client spike work.
No simulations. No input observer or jump helper running; lock absent. Pause
promptly on request. Goal ACTIVE; no source acceptance/gain transfer from23.
[Ownership evidence](docs/validation/inventory-vendor-row-ownership-2026-11-18.json); [preceding23 native evidence](docs/validation/inventory-tier-bag-native-followup-2026-11-18.json).
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
[Evidence](docs/validation/inventory-tier-bag-count-view-2026-11-18.json).
<!-- /LHO-TIER-BAG-COUNT-NATIVE-20261118 -->

<!-- LHO-TIER-BAG-COUNT-VIEW-20261118 -->
18 November: latest runtime set is now23 source files. New Indexf6611444,
Restock_Inv4488ee52 and TierMatch1a02bc12 provide a fresh numeric bag-count view
for four tier consumers; original record query remains on public replacement.
No count cache, source-count substitution or cadence change.12 syntax checks
and unchanged-body proof pass;23 Retail/Forever source pairs match.
IMPORTANT: last own reload/newidle_20261118b accepted preceding21 set only.
These three files have NOT been reloaded/native tested. Server shutdown was
announced; no new game input this slice. Verify actual process/window/world,
build, provider flags and profile preferences before next guarded normal reload.
Then real tier totals (including duplicate stacks/zero), populated vendor
refresh and private/overridden getter restoration; retain active pending jobs,
bank/craft/mail/AH, legal combos and other-client requirements. No simulations.
Goal ACTIVE. No input helper/jump helper running; pause promptly on request.
[Evidence](docs/validation/inventory-tier-bag-count-view-2026-11-18.json).
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
[Evidence](docs/validation/inventory-idle-followup-native-2026-11-18.json).
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
[Evidence](docs/validation/inventory-idle-followup-vendor-workers-2026-11-18.json).
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
[Evidence](docs/validation/inventory-ladder-usability-native-2026-11-18.json).
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
[Evidence](docs/validation/inventory-ladder-usability-pass-2026-11-18.json).
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
[Evidence](docs/validation/inventory-vendor-count-row-copies-2026-11-18.json).
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
[Combo evidence](docs/validation/inventory-native-bag-combos-2026-11-18.json);
[vendor evidence](docs/validation/inventory-native-vendor-refresh-2026-11-18.json).
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
[Evidence](docs/validation/inventory-native-bag-lifecycle-2026-11-18.json).
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
[Evidence](docs/validation/inventory-vendor-tier-counts-2026-11-18.json).
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
[Binding and callback evidence](docs/validation/inventory-vendor-panel-refresh-2026-11-18.json);
[metadata reuse evidence](docs/validation/inventory-vendor-name-metadata-2026-11-18.json).
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
[Evidence](docs/validation/inventory-scan-private-workers-2026-11-18.json).
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
[Evidence](docs/validation/inventory-provider-combos-2026-11-18.json).
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
[Complete before/after evidence](docs/validation/inventory-scan-resolved-ids-2026-11-17.json).
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
[Evidence](docs/validation/inventory-scan-resolved-ids-2026-11-17.json).
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
[Evidence](docs/validation/inventory-ladder-cache-query-2026-11-17.json).
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
[Evidence](docs/validation/inventory-native-cast-receive-2026-11-17.json).
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
[Evidence](docs/validation/inventory-auction-refresh-needs-2026-11-17.json).
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
[Evidence](docs/validation/inventory-classify-budget-loads-2026-11-17.json).
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
[Evidence](docs/validation/inventory-junk-overlay-workers-2026-11-17.json).
<!-- /LHO-JUNK-OVERLAY-WORKERS-20261117 -->

<!-- LHO-NATIVE-DIRECT-SMOKE-20261117 -->
17 November: first native smoke for the15-file direct batch completed on
Forever70938/interface16001, Mario, Syndicator+Baganator loaded. All15disk pairs
match; fresh combined gate passes30syntax checks. Guarded reload completed at
21:16:03UTC (loading/world images +2settings metadata timestamps). Post-reload
source=syndicator, ready=true, scriptProfile0. BugTabs current session count0.
Actual full-record versus ID-only bag queries agree on50IDs/0key mismatches.

Protocol scopes matter: status/post/BugTabs bounded visual ACKs pass. Keys were
personally viewed immediately; the later formal ACK refused its120s age guard,
so that journal stays submitted/unacked. Original BugGrabber read produced no
marker and is unconfirmed, not zero errors. No guard was relaxed or command
replayed. Reload's immediate journal shows loading; delayed confirmation is
separate. Native byte hashes, workflow branches and performance remain unproved.

All6watchdog PIDs are absent, input lock absent, foreign INPUT_HALTED retained.
No persistent game probe code or jump host installed; no purchases/sales/deletes/
moves/casts. Future testing needs fresh fixed tags/runs, never consumed scripts.
Next: actual casting/bag/crafting workflow checks, then remaining contexts/combos;
keep simulations OFF and preserve other goals' reports/preferences/source.
[Native record and exact current15source hashes](docs/validation/inventory-native-direct-smoke-2026-11-17.json).
<!-- /LHO-NATIVE-DIRECT-SMOKE-20261117 -->

<!-- LHO-POTION-PATTERN-SETUP-20261117 -->
17 November: Classifyd7037d85 now prepares generic and potion-range patterns
once instead of concatenating them per tooltip line. Original resource/mode,
suffix/range order and minimum/percent/up-to math remain.2syntax-only51/54 checks
pass. Latest record pins15current direct owners; older Classify proofs are dated.
Fixed private pattern storage/load setup is the tradeoff; no native gain measured.
Simulations stay OFF; continue direct work with native acceptance still pending.
[Current source and open scope](docs/validation/inventory-potion-pattern-setup-2026-11-17.json).
<!-- /LHO-POTION-PATTERN-SETUP-20261117 -->

<!-- LHO-CLASSIFY-RESULT-PROFESSION-WORKERS-20261117 -->
17 November: classifier result builders and EBS profession refresh callback
now reuse fixed private functions. Classifyd1a07334 and Watch6432864a pass4syntax-
only51/54 compiles. Two result helpers take former captures explicitly; all8potion
and2food/water callers retain fresh records, min/max/percent logic and queries.
The profession callback keeps its Start-local pending flag and0.25s delay.
Latest evidence pins15current direct owners; this is not a new whole functional
run or native gain proof. Simulations remain OFF. Continue direct Inventory/EBS
work while retaining client/provider/workflow/native checks as open.
[Current15-file source snapshot](docs/validation/inventory-classify-result-workers-2026-11-17.json).
<!-- /LHO-CLASSIFY-RESULT-PROFESSION-WORKERS-20261117 -->

<!-- LHO-CAST-BAG-AUCTION-WORKERS-20261117 -->
17 November: direct source pass now has14exact current runtime-file identities
in the latest record. New Best123a8f7d and Adapterf96593fb pass4syntax-only51/54
compiles. Cast matching functions are constructed once with the current event
spell service explicit; bag flush and Syndicator auction flush callbacks are
reused. Raw cast args, native queries, ritual rules and queue timing stay intact.
Only success handling changed; start/cancel/interrupt acceptance is still open.
Prior native measurements do not establish benefit for this source set.

Read-only host enumeration found ForeverPID26544/pathForever/Wow.exe, newer than
the old pause process. No window/login/character/loaded source was inspected;
no chat/probe/jump/reload was sent. Foreign INPUT_HALTED remains. Keep simulations
and probe construction OFF; continue direct work and retain native verification
as pending. Stale-mail remains measure-first; other owners' reports untouched.
[Current14-file snapshot and remaining scope](docs/validation/inventory-cast-bag-auction-workers-2026-11-17.json).
<!-- /LHO-CAST-BAG-AUCTION-WORKERS-20261117 -->

<!-- LHO-FOLLOWUP-COUNT-WORKERS-20261117 -->
17 November: pending follow-up and exact-craft fallback counts now use the
existing authenticated carried-live helper; bank snapshots share one private
sort comparator across item groups. Followupb1488189, FollowupCraft8095e63c,
BankInventory5b699a18 pass6syntax-only51/54 compiles. No simulation/native work.
Original getter fallback, countMemo, physical/charge flags, material reads,
craft authorization, bank selection and all timer/callback cadence remain.
The full goal stays ACTIVE; native gain/correctness/client/provider acceptance
is open. Preserve previous direct batches and current other-chat changes.
[Current batch](docs/validation/inventory-followup-count-workers-2026-11-17.json).
<!-- /LHO-FOLLOWUP-COUNT-WORKERS-20261117 -->

<!-- LHO-KEYS-ONLY-CONSUMERS-20261117 -->
17 November: direct keys-only consumer optimization applied to Best.Scan,
Craft reagent-name resolution and Best.Init login bag counting. Scan43f9a81e,
Craft75197d0a and Inita6d93c5b pass6syntax-only compiles across51/54.
All three use the existing authenticated Index helper and preserve public-query
fallbacks, fresh options, key traversal, name reads and update cadence. Full
bank/count/location consumers stay on full records. No new simulation/native
capture or gain claim. The earlier seven-file source list is dated; Craft is
now75197d0a. Continue direct Inventory/EBS work; do not rebuild probe/model tools.
[Current batch and remaining scope](docs/validation/inventory-keys-only-consumers-2026-11-17.json).
<!-- /LHO-KEYS-ONLY-CONSUMERS-20261117 -->

<!-- LHO-DIRECT-INVENTORY-RESUME-20261117 -->
17 November 20:23 UTC: user resumed the inventory goal and the app reports ACTIVE.
Continue direct addon Lua edits using existing findings; simulations/benchmark and
probe construction remain off. New Index options/walkers and RestockList charge
workers are applied; the late auction/tooltip/reagent records are now completed.
All seven current direct-edit owners pass fourteen syntax-only compiles across
Lua 5.1/5.4. This is not functional, native or measured performance acceptance.

Exact owned pause markers were archived/released; foreign INPUT_HALTED stays.
No native input/jump helper runs. The prior13:05:16UTC reload cleared temporary
test code; none was installed this slice. Preserve all other thread changes.
Next: continue bounded Inventory/EBS source improvements while preserving reads,
fallbacks, output ownership and cadence; keep all-client/provider and workflow
native checks open. Do not restart simulations or replay old consumed scripts.
[Current sources and remaining work](docs/validation/inventory-direct-resume-2026-11-17.json).
<!-- /LHO-DIRECT-INVENTORY-RESUME-20261117 -->

<!-- LHO-USER-PAUSE-20261117-1305 -->
17 November: USER PAUSED this entire inventory goal. All own code, capture,
input and jump jobs are stopped; exact pause controls remain set. Six direct
Lua edits are saved in Classify, Index, Craft, AuctionData, Tooltip and
SpellReagents. All twelve Lua 5.1/5.4 syntax checks passed; this is not native
behavior or performance acceptance.

WoW reloaded at13:05:16 UTC and returned to the world, corroborated by the
issued guarded reload, SavedVariables timestamps and fresh world image.
Temporary test/jump globals were cleared. On explicit continue, preserve newer
edits, use the saved six hashes, clear only owned pause controls and install
fresh temporary code only if needed; never replay consumed nonce7/8.

The latest user instruction disables simulations and prioritizes direct addon
Lua editing. Do not restart P91, model/benchmark batches or cost-driver repair
on continue alone. Finish the late auction/tooltip/reagent continuity entries
from saved receipts, then continue the direct optimization work.
[Exact paused state and resume steps](docs/validation/inventory-pause-2026-11-17.json).
<!-- /LHO-USER-PAUSE-20261117-1305 -->

<!-- STANCE-PORTRAIT-BACKDROP-CONTACT-20261117 -->
17 November: attached stance/player backdrop gap correction supersedes the
one-unit-only fill freeze. Read [current handoff](docs/COMBAT_COLLABORATION_BORDER_REPLY.md)
for new Border and Bars/Stance/Init hashes. Core/Shared/Layout unchanged. Actual
contact/inset source checks pass; native screenshot/taint/performance untested.
Performance chat owns Mario combined gate/reload; preserve foreign reservations
and CF62/CF64/CF65/profiler state.
[Evidence](docs/validation/stance-portrait-backdrop-contact-2026-11-17.json).
<!-- /STANCE-PORTRAIT-BACKDROP-CONTACT-20261117 -->

<!-- PORTRAIT-BACKDROP-GAP-20261117 -->
17 November: portrait backdrop gap fix adds one static left interior fill in
full portrait constructors; rounded corners and mini profiles remain. Read the
[current handoff](docs/COMBAT_COLLABORATION_BORDER_REPLY.md) for updated Border/Shared
hashes; Core remains native-unit-rgb-r66 unchanged.17 focused source scripts and
coverage negative control pass. Performance chat owns coordinated Mario reload
and live screenshot/combat acceptance; no native proof from desktop counts.
Preserve foreign reservations and CF62/CF64/CF65/profiler state.
[Evidence](docs/validation/portrait-backdrop-gap-2026-11-17.json).
<!-- /PORTRAIT-BACKDROP-GAP-20261117 -->

<!-- COMBAT-NATIVE-COORDINATION-BLOCKED-20261117 -->
17 November: the combat/group lag goal is BLOCKED, not complete, after three
consecutive no-progress goal turns with the same external blockers. The top
ToT/NPC restricted-paint HOLD still supersedes older READY hashes in the border
reply; ROOT-JUMP-F-20261117 still owns native no_jump and the JSON reservation.
Neither marker establishes a live job. The user confirmed relaying requests to
both owners. New ToT validation/docs appeared at10:47UTC, but the explicit HOLD
has not been replaced. All this performance chat's agents/jobs are terminal.

Resume on actual owner release/current READY. Restore the original CF62 report
with the prepared guarded report-only action, then run the stable combined gate
and coordinated Mario reload/CF65 capture. Foreground and background are both
authorized; no further Alt-Tab request is needed. Bank remains excluded. Preserve
CF57/CF62/CF64, newer source, profiler settings and other owners' markers. CF65
logical-tag retention and R66 controllers are frozen externally. Native combat,
party/raid and FPS acceptance remain open. Read the current
[handoff](docs/COMBAT_COLLABORATION.md) before continuing.
<!-- /COMBAT-NATIVE-COORDINATION-BLOCKED-20261117 -->

<!-- TOT-NPC-SECRET-COLORS-20261117 -->
17 November: read the current [border handoff](docs/COMBAT_COLLABORATION_BORDER_REPLY.md)
for native-unit-rgb-r66 hashes. NPC Default is independent of Appearance; ToT
private class/name colors use guarded native sinks and prepared geometry. Final
focused/source checks pass; no native pixel/security/FPS acceptance. Performance
chat owns combined gate/Mario capture; preserve foreign ROOT-JUMP-F reservation
and CF62/CF64/CF65 diagnostics. Do not treat older READY hashes as current.
[Evidence](docs/validation/tot-npc-secret-colors-2026-11-17.json).
<!-- /TOT-NPC-SECRET-COLORS-20261117 -->

<!-- RANK-CACHE-BUILD-COST-R65-20261117 -->
17 November R65 SpellRankcfc560a5/testc7ac1432 are frozen; optional completed-build
watch summary and cacheCostVersion1 are ready for combined validation. Both VMs
pass70scenes/545new+224existing checks, four compiles and exact preimage projection.
Preserve queries, metadata errors and build cadence; no rank-performance gain
is established. Wait for the border chat's active mini-frame hashes/current READY
before the final combined gate/reload and native capture.

Latest user permission permits verified main foreground or background, retaining
identity/ownership guards and no activation/global input/mouse/clipboard; Bank
excluded. Foreign ROOT-JUMP-F marker is not proof of liveness. Its source-only
prepared owner artifact was located at09:14; Root requested cooperative cleanup.
Do not remove foreign markers or reset CF62/CF64 diagnostics. Root owns the shared
coordination file. [R65 evidence](docs/validation/rank-cache-build-cost-r65-2026-11-17.json).
<!-- /RANK-CACHE-BUILD-COST-R65-20261117 -->

<!-- MINI-UNIT-FIT-COLORS-20261117 -->
17 November: mini profile/fill/unit-color follow-up is applied; read the current
[border handoff](docs/COMBAT_COLLABORATION_BORDER_REPLY.md) before reload. Older
freeze hashes below are historical. Performance chat owns the final combined
gate and next Mario capture; preserve CF62/CF64, reservations and profiler state.
Native compare: both types on ToT/player pet/party pet, full and partial bars,
parent PC/NPC changes and Appearance modes. Source/model passes do not certify
pixel/FPS/taint. [Evidence](docs/validation/mini-unit-fit-colors-2026-11-17.json).
<!-- /MINI-UNIT-FIT-COLORS-20261117 -->

<!-- CAST-UNIT-JUNCTIONS-20261117 -->
17 November: optional-unit/glow corrections and bounded capture reasons are
applied; exact hashes and reload state are in
[the border reply](docs/COMBAT_COLLABORATION_BORDER_REPLY.md). Performance chat
owns next Mario reload/capture and CF62/CF64 restoration; Bank excluded. Do not
overlap input or CPU jobs, reset diagnostics or reuse rejected R63 changes.

Final border/unit59 plus separate342-check cost test pass;13 syntax/max56
upvalues. Next acceptance is exact-loaded-source native notch/glow/optional-part
visibility, combat and party/raid transitions. No FPS/taint inference from models.
[Evidence](docs/validation/cast-unit-junctions-2026-11-17.json).
<!-- /CAST-UNIT-JUNCTIONS-20261117 -->

<!-- COMBAT-CROSS-CHAT-20261117 -->
The user requested collaboration with the other border chat. Read
[the shared ownership and native CF64 handoff](docs/COMBAT_COLLABORATION.md).
That chat owns Core/BorderJunctions.lua; this performance chat preserves its newer
edits. Combat capture is saved; no own native input lease is active. The latest
user instruction permits both foreground and background Mario, using targeted
commands with the remaining input/identity guards. Original diagnostic
restoration is prepared but blocked by a foreign temporary jump-cue reservation.
Do not reset CF62/CF64 data or overlap native reloads. The border chat replies in the separate
`docs/COMBAT_COLLABORATION_BORDER_REPLY.md` file.
<!-- /COMBAT-CROSS-CHAT-20261117 -->

<!-- LHO-RUNTIME-P92-P94-20261117 -->
17 November: P92–P94 are applied to the actual Lua: Classify prebuilds private
health/mana patterns, Index shares two private GetUniqueItems workers while
keeping fresh outputs, and Craft shares the First Aid fallback worker. All six
Lua 5.1/5.4 syntax checks pass. Follow the user's direct-edit priority; simulation
and timing work is stopped. P92's partial pattern checks and both failed host/
fixture batches remain recorded, with no complete regression-pass claim. P93/P94
functional models were not run. P91 remains a stopped source draft. Earlier
P90 tests and P88/P89 captures do not accept these new bytes. Loaded-source,
whole-workflow and native performance acceptance remain pending; no FPS gain
is claimed. The last Root keepalive phase ended without a launched host/jumps.
Goal ACTIVE. [Exact sources and limits](docs/validation/inventory-runtime-p92-p94-2026-11-17.json).
<!-- /LHO-RUNTIME-P92-P94-20261117 -->

<!-- LHO-CLASSIFY-PARSER-LINE-P90-20261117 -->
17 November: Classify f441813c is now applied, superseding the earlier P88/P89
planned status. Each tooltip line is normalized once; percent-free lines skip
only the three private percent workers. Native queries, caches, retries and
0.4s pending cadence remain. Durable parser test6ee9cc32 loads the real owner.

First baseline10 and candidate12 jobs passed1,346 assertions each; candidate
includes two compiles. Per VM:56 parser,510 potion,29 owned,39 builtin-pending
and39 Syndicator-pending checks. Eight cases/14lines retain full result vectors
and fresh axes; private calls Normalize70->14 and percent42->12. These are work
counts, not time/bytes/FPS.

P90 reload/loaded bytes/native benefit remain pending. P88 preceded f441 and
is not parser attribution or matched gain; keep P88/P89/release evidence below.
Goal ACTIVE; broader Inventory/EBS workflow/client acceptance remains open.
[P90 source and exact evidence](docs/validation/classify-parser-line-work-p90-2026-11-17.json).
<!-- /LHO-CLASSIFY-PARSER-LINE-P90-20261117 -->

<!-- LHO-INVENTORY-NATIVE-SCAN-P88-20261117 -->
Nonce8 is installed: Root timely-ACKed J83INIT/CUE after all25 commands/4,369
characters queued. Nonce8 SPENT is consumed; NEVER replay/reinstall7 or8.
The first begin failed minimized before lock/input; Root restored behind the
active app at11:53:57UTC without activation/input/cursor/clipboard changes.

BG8 has three GREEN samples at1890x993, centers11/17/24/30,y982. Strict foreground
calibration11:58:02 verified PCidle15 but Windows SetForegroundWindow returned
FALSE, foreground692126702 unchanged. No keys/chat/FG proof or helper launch;
JUMPS STILL STOPPED pending foreground proof. This was Windows refusal, not
automatic-review denial; no AttachThreadInput workaround. Calibration authority
is finite/read-only, not host authorization.

RootF_RELEASED remains: F holds absent/HALT6990 retained, shared input lock
released. No Root reload/P90 loaded proof or native gain. Preserve P88 passive
73calls/30.017s/inclusive timing and P89 later-context limits below. P90 disk
f441 is applied; current-candidate native acceptance remains pending. Preserve
COMBAT/CF64 ownership; goal ACTIVE.
[P88/P89 and nonce8 native evidence](docs/validation/inventory-native-scan-p88-2026-11-17.json).
<!-- /LHO-INVENTORY-NATIVE-SCAN-P88-20261117 -->

<!-- LHO-INVENTORY-EVENT-WORKERS-20261117 -->
17 November: four more actual owners are applied: Inventory field-list/set merging,
profession protected workers, Restock bank workers and EBS event workers. The
EBS repair also makes idle count-only refreshes run, while later full/spell
requests restore textures. Targeted receipts contain 9,958 assertions and ten
compiles; Init's total includes baseline/installed pairs.

Root saw fresh nonce7 J83INIT/CUE after25 commands/4,369 characters queued;
its later formal ACK was rejected stale. BG2 found the palette at1920x1009,
all red; BG3 child failure awaits Root review. No helper launch/jumps: F holds
remain active, C stopped. Nonce6 is historical/spent, never replay.

I88IDLE endpoints span805.524s: Best generation+1,942, classification revision
+19,420, bags85 unchanged, dirty true. Before was visually observed without
formal ACK; after had timely ACK. Mixed AH activity is not a matched-cost/FPS
comparison. Ten revisions/publication does not prove reuse failed; own pending
resets can produce it. All-nine loaded bytes/native gain remain pending. No Root
reload/item actions this turn. Preserve COMBAT/CF64 ownership. Goal ACTIVE.
[Current source and evidence](docs/validation/inventory-event-workers-2026-11-17.json).
<!-- /LHO-INVENTORY-EVENT-WORKERS-20261117 -->

<!-- LHO-PENDING-READ-RUNTIME-20261117 -->
17 November: the runtime inventory batch is applied: Best pending-read reuse,
classifier invalidation revision and the private ItemClass tooltip worker; the
earlier Item helper adoption remains. Final installed checks passed 28 jobs:
22,400 assertions plus eight compiles. Fresh getter demand is required to renew
read reuse; ordinary retry limits and 0.4s followups remain.

Next is Root-owned loaded-source and native workflow validation when the client
is usable. The earlier minimized preflight sent zero input and did not reload.
C3864's guarded deferral is a dated Root report, not current liveness proof.
No new FPS/native gain is established; the broader LHO goal remains ACTIVE.
[Current sources and checks](docs/validation/consumable-pending-read-runtime-2026-11-17.json).
<!-- /LHO-PENDING-READ-RUNTIME-20261117 -->

<!-- FALLBACK-INPUT-WORK-R63-20261117 -->
17 November R63 is REJECTED/REMOVED. Both declared CPU gates failed; do not
resume from either trial. Exact installed baseline is Core4fa7c12a/LF110827,
array testad065 and unchanged OtherE790, restored at07:17:21UTC. Functional
trial passes and all raw cost/counter evidence remain historical.

Root owns the main-only background capture/retention sequence. CF64 was reported
armed at07:34:09UTC after combat-ready coordination; its result and the earlier
CF62 city report still require owned retention/restoration and review. Preserve
nested prior diagnostics and profiler preferences. Combat entry/exit and
party/raid join/leave in both display modes remain unaccepted. Bank excluded.
[Resume disposition and evidence](docs/validation/fallback-input-work-r63-2026-11-17.json).
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
[Adoption decision and limits](docs/validation/item-count-helper-adoption-2026-11-17.json).
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
[Evidence and remaining scope](docs/validation/inventory-best-reasons-p87-2026-11-17.json).
<!-- /LHO-BEST-REASON-ITEM-HELPER-P87-20261117 -->

<!-- LHO-P84-P85-NATIVE-WORKFLOW-20261117 -->
17 November: Root accepted P84 passive30.0099s and P85 mixed120.0192s native windows on Forever70938/Syndicator. P84 had no cast/bag events, stable bagGeneration8 and Best73 spans (561.038ms/max21.023ms); its Food27to41 was outside. P85 had one player SUCCEEDED, nine cast/bag stamps and the automatic+2s typed Food41to55 state, bagGeneration10to13. All six report pages and CLEANtrue3 were personally viewed/formally ACKed for both captures.

P85 inclusive totals: provider3/0.2088ms; Notify3/3.2080ms; Best.Scan296/2292.8931ms(max21.8516); EBS eval173/194.3774ms; counts3/0.7576ms; Bars132/272.1369ms. All eight retained slow-ring spans are Scan, with three overwritten; cumulative post counters include pre-cast passive work. These are instrumented overlapping elapsed spans, not exclusive Food CPU, FPS causality or a matched comparison. P86 does not expose private retry state; the getter-feedback cause remains unconfirmed.

Goal ACTIVE. P85 first2 combined jobs passed31body/1272 plus14protocol/1511checks perVM; its label-only route copy stays UNRUN. Item.GetCount first2 actual-owner baseline jobs passed8direct groups plus2partial-route pairs/VM; Helper identity counts do not measure allocated bytes or CPU. No optimization is applied. Next: bounded reason-enum trace plus actual Scan/Classify/ItemClass retry reproduction, preserving queries/cadence. P83 stays REJECTED/UNAPPLIED; no addon Lua changed in this slice. Root reports holds released/jumps resumed, without current liveness/movement proof. Broader client/provider/workflows remain open; stale-mail USER-MEASURE-FIRST, commerce simulation only, guild/void excluded.
[Native records, exact limits and next causal gate](docs/validation/inventory-native-workflow-p84-p85-2026-11-17.json).
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
[Exact repairs, sources, proof history and limits](docs/validation/combat-watch-r61-2026-11-17.json).
<!-- /COMBAT-WATCH-R61-20261117 -->

<!-- LHO-WORKFLOW-DIAGNOSTIC-P84-20261117 -->
17 November: P84 is EXTERNAL/PREPARED. The six-envelope body passed31mock cases/1,272checks perVM (54pins). Actual builtin/Syndicator routes passedR1 two pairs/four contexts/62checks perVM; R2 adds the missing direct observer-row proof:88checks perVM/130pins, current and automaticpost entered=completed=valid [1,1,1,0,1,0]. Same-VM selected query/callback order and state match. R1 raw cross-VM listener-order/metadata-overassert history stays preserved; no model rerun.

Root formally ACKed dated P84CTX: Forever1.60.1/70938/16001, Syndicator ready, Food Button table, both selected roots absent. This was one pure253-character status command; NO P84 OBSERVER TYPED and NO FOOD ACTOR as of that snapshot. Root archived/released its short CTX holds and reports helperB5872 resumed; INPUT_HALTED remains. This is readiness, not native event delivery, loaded body adoption or FPS. Existing jump launch/history is unchanged and was not inspected by this draft.

Goal ACTIVE; P83 stays REJECTED/UNAPPLIED and ConsumableBind7d758903 is unchanged. Native protocol proof is pending. Count tracing covers first3 native arguments only; full EBS/Bars eval dispatch, private heavy queue and upstream Syndicator remain unqualified. Next: Root protocol first2 proof, fresh source/Idle and eligible Root-only fast Food inside30s; automatic+2s snapshot, paged read/Stop and current cleanup proof. [Evidence and pending native gate](docs/validation/inventory-workflow-diagnostic-p84-2026-11-17.json).
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
[Exact observability source/proof and current pending native state](docs/validation/watch-mesh-phases-r60-2026-11-17.json).
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
[Exact rejection, all samples, scopes and separate proposals](docs/validation/fieldset-specialization-r59-rejected-2026-11-17.json).
<!-- /FIELDSET-SPECIALIZATION-R59-REJECTED-20261117 -->


<!-- LHO-NATIVE-PAINT-P83-COST-20261117 -->
17 November: P83 is REJECTED/UNAPPLIED; ConsumableBind remains7d758903. The fixed28-child/four-profile batch supersedes the22-child proposal: retained-zero CPU796.875→875ms (+9.8039%,2of3pairs slower) rejects despite other wins and64B/unit51/56B54 transient-GC savings. R3 admissions passed500checks/VM; R1 startup-timer and R2 depletion-to-nil setup failures remain preserved. All raw regressions, intercepts and retention deltas are linked below; no retiming or P83 runtime application.

Root accepted passive30.018s and separate120.016s leaf windows. The latter contained Food caststart; orange bread/A-D showed13 before/active and27 in the first later image AFTER expiry. Displaydelta14 proves no exact item/produced quantity or in-window finish. Late actor ACK remained STALE/false; no recast/restamp. Both captures have formal cleanup. Inclusive overlapping spans prove no matched gain, exclusive Food cost, loaded-byte adoption or FPS result.

Goal ACTIVE: prioritize whole cast/craft/bag→EBS/Bars and restock workflows plus provider/client/bank/mail gaps. PaintOne/CountOne is an unbuilt one-closure-per-PASS lead, not per widget; extra arguments can regressCPU. Preserve stale-mail USER-MEASURE-FIRST, simulation-only commerce and guild/void exclusion.
The next read-only capture plan is prepared; see evidence.nextWorkflowPlan in the linked record. Event-contract checks and implementation remain pending.
[Exact costs, native limits and corrected chronology](docs/validation/inventory-native-paint-count-cost-2026-11-17.json).
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
[Exact sources, fixed gate, raw risks and pending native acceptance](docs/validation/solver-allocation-r58-2026-11-17.json).
<!-- /SOLVER-ALLOCATION-R58-20261117 -->


<!-- LHO-JUMP-KEEPALIVE-R2-20261117 -->
Latest dated Root launch: B PID5872/live20261117b at01:49:45UTC replaces A PID50140, which stopped after600s stale heartbeat during held scripts. Root must refresh heartbeat well inside600s. One overdue jump queues around unsafe cue/chat/casting/Skillet/movement/combat and shared guards; shared scripts must own no_jump/input.lock. Foreground and background tests are authorized. Jump activation requires15s PCidle; restore the previous window when allowed and no external race. Windows may deny restoration. No independent movement/FPS acknowledgement.

Root cleaned both P67 captures and released its archived Food120 holds; INPUT_HALTED remains. For complete pause/reload, stop input/helper FIRST with CANCEL/JUMP_STOP, cancel/reap owned tests and preserve holds/halt, then perform only the requested reload. Reload removes temporary cue/probes; do not assume probes active on continue or replay consumed nonces. Cue_J83q/k83n6p5 has24-hour renewable lease and one fixed82-character heartbeat. This dated launch is not a new liveness inspection.
[Current evidence](docs/validation/inventory-native-paint-count-cost-2026-11-17.json).
<!-- /LHO-JUMP-KEEPALIVE-R2-20261117 -->

<!-- LHO-EBS-COUNT-OPTIONS-P82-P83-20261117 -->
17 November: goal ACTIVE. P82 baselined the actual loaded ConsumableBind owner in8 contexts/216checks per stock51/54 VM. P83 remains EXTERNAL/UNAPPLIED with cost pending: its private options/freeze scalar change passed8paired contexts/440checks per VM and12unchanged consumer runs. Each baseline/candidate VM has5,059 consumer checks; complete same-VM outputs match. The focused public/state/error/flag traces match, including actual bag-event→Inventory.Notify→light listener delivery, face/hold/reliability ordering, opaque errors and reentry.

Ten private default constructions become zero in the focused protocol; eight supplied private tables are harness inputs, not eight claimed production allocations. All27escaping public option tables per variant remain fresh. Constructor counts establish no heap/CPU/FPS gain. The fixed22-child CPU/GC proposal is accepted for source preparation only; no cost batch or addon Lua application has occurred.

Root observed F81A readiness on Forever1.60.1/70938 with _FluxUI, Syndicator and Baganator loaded. This is readiness only, not exact loaded-source adoption or performance acceptance. Root owns native and separate jump receipts. The full LHO01–13 goal/native gaps remain open, including representative cast/craft/bag whole-event attribution, restock lifecycle, provider/bank/mail and requested client expansion.
[Exact proof, private/public limits and remaining coverage](docs/validation/inventory-count-options-2026-11-17.json).
<!-- /LHO-EBS-COUNT-OPTIONS-P82-P83-20261117 -->


<!-- CAST-DIVIDER-FLARE-20261117 -->
17 November (`CAST-DIVIDER-FLARE-20261117`): shared non-pet cast fill/trough extends two UI units farther under the icon divider to cover the native rounded leading cap; cast, swing/Shoot and flight labels keep their prior positions and time spacing. Profession fill and wide flare now share the existing progress mask. No added mask, region or driver; header/icon/pet geometry, recipe classification, timers, prepared layout and green success remain. Fourteen focused scripts pass, including archived-source negatives; seven syntax checks and 286 compiler prototypes pass (maximum 52 upvalues). New Mooncloth and ordinary-cast visual comparison after reload is pending. Broader performance work remains open. [Requirements](docs/UNIT_OVERLAY_ATTACHMENTS.md#leading-edge-and-crafting-flare-follow-up) and [evidence](docs/validation/cast-divider-flare-2026-11-17.json).
<!-- /CAST-DIVIDER-FLARE-20261117 -->

<!-- PARTY-BORDER-WORK-20261117 -->
17 November (`PARTY-BORDER-WORK-20261117`): removed unnecessary geometry scans on visibility/alpha changes to the unit-only raid container, and duplicate header positioning before the existing secure layout. Full roster data refresh, secure execution, paint and focus notifications remain. All 13 focused scripts pass, including 164 container checks across eight paired scenes and 5,428 roster checks. Syntax and upvalue checks pass (92 RaidLayout prototypes, maximum 16 upvalues); the earlier accepted UI sources are unchanged.

In the model, each container visibility transition drops from one wake/read/alignment to zero; neither version solves unchanged geometry. Prepared header clear/set pairs drop from 18 to 9, and width writes from two to one. Partial execution failures retain fallback/retry, with documented differences in hidden intermediate poses. The adjacency-cache prototype remains unapplied because it slows genuinely changed layouts. Native party join/leave hitch feedback is pending. [Requirements](docs/PARTY_BORDER_PERFORMANCE.md) and [source/evidence](docs/validation/party-border-work-2026-11-17.json).
<!-- /PARTY-BORDER-WORK-20261117 -->


<!-- UNIT-OVERLAYS-ACTIVE-CASTS-20261116 -->
17 November (`UNIT-OVERLAYS-ACTIVE-CASTS-20261116`, started16November): mini pet/target-of-target/party-pet borders now meet their parent portrait without moving bodies or merging unit scopes. Five-piece open frames retain outside-cap ownership; detached scales and private-width/setter retry cache repaired. Known crafting uses normal chrome and public icon fallback; two-pixel cast core fit both styles and green success retained.25 unique focused scripts PASS, including218,107 attachment checks/216 main scenes and786 crafting checks;868 owned runtime compiler prototypes/max55 upvalues. User after reload confirmed “Connections look right” and “Crafting and fit look right”. No FPS/taint, exhaustive client/state or full contact shadow-partition claim. [Requirements](docs/UNIT_OVERLAY_ATTACHMENTS.md) and [exact source/proof](docs/validation/unit-overlays-active-casts-2026-11-16.json).
<!-- /UNIT-OVERLAYS-ACTIVE-CASTS-20261116 -->


<!-- LHO-BURST-BASELINES-P77-P78-P80-20261116 -->
16 November: goal ACTIVE. User permission for in-game testing is restored; Root alone owns fresh guarded inspection/input. Status attempts A-D entered no command; later E also stopped before input when foreground became unknown. The A-D receipt stays historical; no fresh loaded-status, client-exit or native performance result is inferred.

P77 public AH reuse traces match for two N1/N25 cycles (7/103 forced builds;19/5,551 modeled item calls per cycle). Its fixed16 desktop cost gate passed: CPU medians-9.375%/-0.6024%, the latter one15.625ms tick. N25 pair2 +31.25msCPU/+62mswall, N1 pair3 +16mswall, positive GC slopes and prepared retention+3642B51/+2967B54 remain recorded. This is whole-child modeled CPU/GC, not native FPS or event-exclusive CPU.

P78's corrected9case/281check baseline per VM distinguishes9GetRows calls from1forced rebuild. The second resolver observes later metadata, public-list edits and raw errors; blind skipping is unsafe. Earlier fixture/metric failures stay preserved; no candidate.

P80 passed functional and corrected quiet admission proofs, then failed its fixed34job cost gate: small-lifecycle median is flat but2/3 CPU pairs are slower. Distributed/warm wins cannot override it. Cold GC/retention increases and no-pending wall+13.13% remain visible. Candidatefba020 remains external/unapplied; actual Init98d3 and applied Index80acf are unchanged. No addon Lua changed in this slice. Keep this rejected candidate unapplied; investigate the next distinct lead with tests first.

Next source-only lead: ConsumableBind's private ApplyCount options/freeze scratch. Baseline the actual owner in8bounded contexts before any edit; no candidate/model/cost is built or queued.
[Exact evidence, regressions and scope](docs/validation/inventory-burst-baselines-2026-11-16.json).
<!-- /LHO-BURST-BASELINES-P77-P78-P80-20261116 -->

<!-- RESPEC-ACTION-SAFETY-20261116 -->
16 November (`RESPEC-ACTION-SAFETY-20261116`): explicit native bar slots now save/load on Retail, Forever and Classic after talents. Failed reads, pickup/no-cursor, malformed snapshots, active loads and player drags cannot become destructive empty restores. Stable flyout/macro/mount/set/outfit routes and legacy missing-stance preservation are covered. Auto-rank now verifies the exact spell cursor and destination before advancing saved IDs; binder opening preserves the native account/character set and unsaved keys. Frozen 14 scripts on each Lua5.1/5.4 PASS (28 runs); 18 owned syntax results and 611 compiler prototypes/max25 captures PASS. Native operation/taint/controller/persistence/FPS remain pending. Reload then re-save old Retail/Forever profiles to capture bars; previous snapshots contain stance only. [Requirements, exact sources, checkpoint, regressions and pending checks](docs/validation/respec-action-safety-2026-11-16.json).
<!-- /RESPEC-ACTION-SAFETY-20261116 -->


<!-- CAST-GREEN-FINISH-20261116 -->
16 November (`CAST-GREEN-FINISH-20261116`): successful unit casts now finish plain green, including school/profession casts, using the existing .35 hold/.75 fade. Completed protected casts clear red chrome/shield; active cues and failure feedback remain. Only FluxCastBar.lua changes at runtime; native-nameplate theme Finish stays with its owner. User reloaded and confirmed “Green finish looks right”. The general in-game testing hold was explicitly lifted during this task; background/no foreground or gameplay control rules remain. Twelve focused offline scripts PASS (including9,973 terminal checks); 13 scoped syntax checks and147 compiler prototypes/max33 captures PASS; no FPS/taint or automated native test claim. [Requirements and exact scoped evidence](docs/validation/cast-green-finish-2026-11-16.json).
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
permission. [Release scope and record](docs/validation/native-test-release-2026-11-16.json).
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
[Exact R57 source, scoped replay, curated native evidence and limits](docs/validation/border-wake-owner-r57-2026-11-17.json).
<!-- /COMBAT-CALLBACK-WORK-20261116 -->

<!-- USER-NATIVE-TESTING-HOLD-20261116 -->
Historical general testing hold: the user explicitly lifted it later on 16 November (“we can test ingame now if needed”). Relevant UI tests may resume; preserve background operation and separate input/gameplay restrictions. Earlier evidence collected under the hold remains offline-only. See CAST-GREEN-FINISH-20261116 above.
<!-- /USER-NATIVE-TESTING-HOLD-20261116 -->

<!-- USER-NATIVE-TEST-HOLD-20261116 -->
Historical general testing hold: the user explicitly lifted it later on 16 November (“we can test ingame now if needed”). Relevant UI tests may resume; preserve background operation and separate input/gameplay restrictions. Earlier evidence collected under the hold remains offline-only. See CAST-GREEN-FINISH-20261116 above.
<!-- /USER-NATIVE-TEST-HOLD-20261116 -->

<!-- CAST-COMPLETION-20261116 -->
16 November (`CAST-COMPLETION-20261116`): completed modern unit-frame casts use a quiet plain muted-gold fill instead of the bright patterned full success atlas. Classic green, active casts, channels finishing empty, .35hold/.75fade, interrupts, school/profession overlays, rapid recast and header/swing release remain. Eleven focused scripts PASS, including12,535 new lifecycle/appearance assertions across150 consumer/client scenes; owned compiler146prototypes/max33 captures. No geometry/topology, settings, localization, input, new timer/driver or native operation. All in-game testing remains deferred by the user. [Exact sources and scoped validation](docs/validation/cast-completion-2026-11-16.json).
<!-- /CAST-COMPLETION-20261116 -->


<!-- BORDER-JUNCTION-SHADOWS-R56-20261116 -->
16 November junction shadows (`BORDER-JUNCTION-SHADOWS-R56-20261116`): `shadow-support-r56` restores the measured source shadow footprint in all four T directions and X, both styles, including aura/retained-strip joins. Current interval keepers are suppressed once; exact current-material/UV guards and committed support snapshots preserve static natural/tint/RGB paint. 486,467 shadow checks/56 scenes/240,576 footprint samples and 111,147 material checks PASS. Final 147 focused scripts/1,190 composed syntax checks PASS; two runtime files/235 compiler prototypes, maximum54 captures; Lua stable during the gate. Earlier fixture failures and alpha-gradient/field-count costs are retained. Native pixels, perceptual smoothness, taint and FPS remain deferred by the user; CB-36 broader reflow latency stays open. [Exact sources, proof and limits](docs/validation/junction-shadows-2026-11-16.json).
R56 post-gate continuity: a later parallel portrait-only Shared change is preserved. Twenty affected scripts, fresh Shared syntax and381 compiler prototypes/max20 captures PASS with Shared/Core/Border stable. The original147-script source-frozen gate and this later scoped replay remain separate evidence. Later unrelated tests receive syntax checks only; exact composition is in the R56 record. Native testing stays deferred.
<!-- /BORDER-JUNCTION-SHADOWS-R56-20261116 -->


<!-- LHO-INVENTORY-PRIVATE-CALLBACKS-20261116 -->
16 November: P75/P76 are applied after offline behavior and fixed-cost gates. USER native hold remains: no game tests, input, queries, captures, jumps or reloads until explicit release. Goal ACTIVE for offline work.

Only two private callbacks changed: slot validation reuses its protected numeric body; inventory change merging reuses its union helper. All validations, native/query reads, fresh maps, callbacks, repaint work and update cadence remain. Twelve first functional jobs passed: P75 32paired/235checks per VM plus unchanged65check visible-bag regression B/C; P76 8groups/45checks per VM plus unchanged263check passive-inventory regression B/C. Existing same-VM output is byte-identical.

Fixed44cost jobs passed with80pins stable and all children reaped. Whole-child stock51 CPU medians: slot valid-50%,nil-58.14%,throw-29.41%; merge countOnly-25%,mixed-15.38%. Populated identity is+4.545%(2slower/1faster), retained below its declared5% rejection gate. Paired allocation savings136B/slot check and40B/merge hold at both1000/2000 windows on51/54. Shared54 first-window floors and retained startup increases(+148/+150B slot,+91/+62B merge) stay recorded. These are conditional leaf models, not native FPS or whole-workflow timing.

The addon source files now match the exact tested candidates; no client reload/input, temporary code, settings, external addon edit, manual sync or publication occurred. Loaded adoption and other installations were not checked. Native/whole-client acceptance remains pending. [Exact sources, all samples, contract boundaries and regressions](docs/validation/inventory-private-callbacks-2026-11-16.json).

Next offline step: the P74 whole-AH loading-recovery proposal atN1/N25 is source-only, with expected6/102forced builds not yet observed in the combined real-Index model. Prove query/callback/row/plan/UI parity first; do not prune observable builds, retime rejectedP72, or bypass the stale-mail measure-first gate. Native permission is still required before any game activity.
<!-- /LHO-INVENTORY-PRIVATE-CALLBACKS-20261116 -->

<!-- LHO-AUCTION-CLOSED-DEFINER-P73-P74-20261116 -->
16 November (`LHO-AUCTION-CLOSED-DEFINER-P73-P74-20261116`): USER HOLD: no in-game tests, live queries/testing captures, game input, jumps or reloads until the user explicitly permits them. Offline goal ACTIVE; generic continuation or offline success never releases this hold.

P74 application and repository/five-primary-disk checks are complete; loaded adoption remains unverified under this hold. No game cleanup/reload for unused P67 is needed. P74 applied the three tested Retail files at19:46:44UTC. The later19:52:16UTC read-only check matched all15 files across five primary installs; other folders have independent identities and updated externally between observations. Propagation mechanism is unproved; Root performed no manual sync. Loaded-client adoption remains unverified. Extra beta is unchanged/older and not certified. Continue offline from a different substantive lead; keep P73 iteration shortcut unapproved and original P72 rejected without retiming. No native test is queued or authorized by these offline results. [Exact sources, proof and limits](docs/validation/auction-closed-definer-options-2026-11-16.json).
P73 baseline12contexts/536checks51 and535checks54 supersedes the earlier source-only note; its loop remains unchanged. Next offline lead: inspect private return-packing and per-call closure allocations in Inventory burst paths. Whole-AH CPU and native FPS remain unproved; no gameplay action is queued.
<!-- /LHO-AUCTION-CLOSED-DEFINER-P73-P74-20261116 -->

<!-- ACTION-STRIP-BORDER-R55-20261116 -->
16 November action-strip borders (`ACTION-STRIP-BORDER-R55-20261116`): `strip-updates-r55` skips matching same-occupancy decorative layouts after fresh public native checks and connects the nearby strip/envelope top nodes. Secure mappings,171 cursor flag writes, ForceApply, visibility and real expand/collapse stay. 144 focused scripts PASS;1187 composed syntax PASS;7 runtime files/782 prototypes max54 captures; source stable during gate.157 guard controls;5,798 seam checks/144 scenes/1,080 one-source samples. Extra cut cache REJECTED: actual drag has0 reusable prefixes. Native testing is DEFERRED until explicit user availability; no reload/capture request. [Exact sources, limitations and remaining work](docs/validation/action-strip-borders-2026-11-16.json).

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
and remaining checks](docs/validation/combat-fanout-2026-11-16.json).
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
HELD until explicit user release. [Final postcheck and evidence](docs/validation/combat-fanout-2026-11-16.json).
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
See [exact sources, work proofs and remaining combat checks](docs/validation/group-combat-spikes-2026-11-16.json).
<!-- /GROUP-COMBAT-SPIKES-20261116 -->

<!-- LHO-AUCTION-NIL-TIERS-P73-20261116 -->
16 November P73 is a source-only lead: ordinary manual, consumable, reagent and new craft-material rows can reach `A.Need` without `tiers`; tier-reference merges attach real arrays. No P73 candidate, model or timing run exists. Next, baseline actual GetRows/Need for manual-only, tier-only, merged and craft-material rows, with nil/false, proxy and raw-error controls. Preserve selection of global `ipairs` before the `row.tiers` read; foreign iterator purity is not established. P72's residual64B51/48B54 per modeled Need does not isolate this allocation or prove CPU/FPS benefit. Keep P72 rejected and the broad goal ACTIVE.
<!-- /LHO-AUCTION-NIL-TIERS-P73-20261116 -->

<!-- LHO-AUCTION-BASELINES-P70-P72-20261116 -->
16 November (`LHO-AUCTION-BASELINES-P70-P72-20261116`): P70/P71 baselines are sealed and P72 is REJECTED/UNAPPLIED; do not apply its three files or rerun/retune the cost batch. Retain the12/546 per-VM functional proof, explicit generated-error wording difference, CPU regressions, qualified two-point GC observations and startup cost. Continue the broad inventory/frame-spike goal from a different substantive lead. P67 attempts1g/1h/1i sent zero packets and never staged/armed the observer;1g preinput reason remains unknown,1h was rejected before journal, and1i user logout countdown was left untouched. Goal ACTIVE; own holds remain and any native attempt requires fresh client/world/closed-chat/ownership checks. Do not cancel/reconnect/jump/reload the user logout. [Baselines, rejection and native limits](docs/validation/auction-limit-live-options-2026-11-16.json).
<!-- /LHO-AUCTION-BASELINES-P70-P72-20261116 -->

<!-- BORDER-EVENT-REFLOW-R54-20261116 -->
16 November event reflow (`BORDER-EVENT-REFLOW-R54-20261116`): `event-reflow-r54` reuses bounded current observer pairs, skips identical PUBLIC direct-alpha derived work, avoids matching native shell rewrites and redundant roster-driven focus partition/outer passes. Changed/private/unknown/pending/direct-settings paths, source suppression, notifications and rollback remain. 129 focused scripts PASS;1182 composed syntax PASS (29 fresh);5 runtime files/717 prototypes max54 captures; source stable during gate. Model pet exits120 shell setters become0 with40 paints retained;20 prepared roster events20 full focus partitions become0 with20 default notifications retained. Native combat-exit and join/leave latency/pixels/taint acceptance is PENDING. [Exact sources, work tax and remaining checks](docs/validation/border-event-reflow-2026-11-16.json).
<!-- /BORDER-EVENT-REFLOW-R54-20261116 -->

<!-- BORDER-BUILDER-R53-20261116 -->
16 November border builder (`BORDER-BUILDER-R53-20261116`): `local-plans-r53` reuses unchanged immutable fallback plans, uses per-pass solver identity keys, and reuses complete public unit-owner walks only inside the existing readonly commit phase. Fresh source/geometry/private/native-field checks, paint, budgets and atomic rollback remain.95 focused scripts PASS;1170 composed syntax PASS;3 owned runtime files/608 prototypes max54 captures; no source changes during gate. Native R52 minimap toggle with side buttons still costs232.41ms (solve50.60/plan88.94/commit73.45); R53 native timing is PENDING. Modeled work reductions and staged CPU samples are not native speedup. Actionstrip mappings/seam changes remain held. [Evidence, tradeoffs and native check](docs/validation/border-builder-2026-11-16.json).
<!-- /BORDER-BUILDER-R53-20261116 -->

R53 is historical. R54 observer-pair privacy/mutation/budget controls are resolved
and the bounded cache is admitted. Test combat exit first after all owned jobs
stop, then party/raid transitions separately; capture the loaded R54 version.
The complete all-consumer affected-part latency goal remains open.

<!-- LHO-BARS-USABLE-CLOSURE-P69-20261116 -->
16 November P69 (`LHO-BARS-USABLE-CLOSURE-P69-20261116`) APPLIED at17:27:37UTC: `Bars/Paint.lua`7b6273f replaces the per-eligible-host usable-paint closure with one private helper; three call sites preserve queries, captured palette/charge state, features and cadence. Pipeline6cases/642checks per VM matched36,072 paired scalar fields total; focused16/361 each VM and existing54stress86,872checks per source passed. Read-only postcheck matched11expected pins and5installed file identities; loaded-client adoption remains pending.

Modeled leaf whole-child CPU medians improved19.0476% (one host) and13.6364% (57 hosts). Empty/OOR CPU medians tied; wall medians regressed10.6383%/5.6391%, including empty pair3CPU+31.25ms. All pairs remain recorded. GC slopes51:200to0 and54:192to0B/call retain the qualified128B54window floor. The R1before-work harness failure is preserved. No native FPS/spike/retained-heap/full-workflow gain is proved; five model labels/providers were distributed, not a native factorial. P67 remains prepared and never installed natively; the goal stays ACTIVE. [Exact proof, all costs/regressions and remaining native limits](docs/validation/bars-usable-closure-2026-11-16.json).
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
[Sources, regressions and scope](docs/validation/world-map-anchor-recovery-2026-11-17.json).
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
[Requirements](docs/WORLD_MAP_SURFACE.md) and [final evidence](docs/validation/world-map-surface-final-2026-11-16.json).
Documentation refresh found one subsequently changed unrelated Bars/Paint.lua
verification hash;current map files still match the final tested version. That
newer user/parallel work is preserved;the captured full-run pass is not a claim
about its later revision.

<!-- WOWSIM-STOCK-READINESS-20261116 -->
16 November WowSim stock readiness (`WOWSIM-STOCK-READINESS-20261116`): upstream `c854956` was evaluated outside AddOns with Lupa2.8/Pillow12.3 and612 copied source/license files; all18 upstream Git blobs matched. One stock load hit the30s parent bound (30.016s), with no health output. A separate 2M-instruction diagnostic stopped during texture construction at login; this does not establish the timeout cause or an infinite loop.

WowSim is supplementary: meaningful use needs explicit data fixtures/bootstrap compatibility work under the active goal. Empty API defaults, missing XML/security/secret behavior and browser timing provide no native FPS/GC/pixel acceptance. Final P67 R3 body/protocol proofs passed20/106 and14/135 cases/checks per Lua VM; its55-packet package remained prepared, never natively staged or armed in this sealed checkpoint. Delegated keepalive work is separate and pending Root review; no jump outcome is added here. The full Inventory/EBS lag goal remains ACTIVE. [Bounded results, exact proof identities and limits](docs/validation/inventory-native-current-checkpoint-2026-11-16.json).
<!-- /WOWSIM-STOCK-READINESS-20261116 -->

16 November unit-frame exit priority (`COMBAT-TRANSITIONS-20261116` CT15): `static-unit-paint-r52` skips identical PUBLIC derived paint, keeps native source suppression/private opacity forwarding, and chooses final portrait normal/combat paint once while preserving party material classification. 98 unitpaint +3560 producer/100-stage checks;20 focused scripts and5 changed-file syntax PASS; Core max57/SharedParty max20 captures. Model type2 repeated exit2037 derived alpha reads become0; native latency/whole unlocked UpdateOuterBorder geometry/taint/pixels remain PENDING. Actionstrip/seam and local-plan runtime work are held. WowSim was reviewed read-only; missing triangle/UV/security/native-alpha behavior prevents native border/FPS certification. [Evidence and remaining checks](docs/COMBAT_TRANSITION_PERFORMANCE.md).

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
[Requirements and findings](docs/COMBAT_TRANSITION_PERFORMANCE.md);
[structured evidence](docs/validation/combat-transitions-2026-11-16.json).

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
coverage/controller/taint/FPS pending. [Requirements and evidence](docs/CAST_RANGE_TARGETING.md).

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
release confirmation remains valid. [Requirements and evidence](docs/HOTKEY_RANGE_GLYPHS.md).

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
[Requirements, sources and measured limits](docs/ACTION_ROUTING_RELIABILITY.md).

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
[Whole-addon continuation](docs/COMBAT_TRANSITION_PERFORMANCE.md) tracks the pending
R51 gate/native checks. External border checkpoint:
border-indexed-fallback-before-20261116T142859Z.


15 November read-only saved-variable follow-up for shared bindings: account/
character current and backup data audited at user request. Nine valid DB3 rows,
seven placements, no structural corruption or saved layout/badge conflict.
Latest SHIFT-½ entry has ShiftCtrl on/ALT off and both regular/hover input off;
it emits no conditional cast. R remains hover-only. Native F maps11 with no
explicit Shift-F override; hidden11/71 profiles match the reproduced source bug.
No settings changes; client action contents/page and loaded state unverified.
[Audit](docs/SHARED_BINDING_MODIFIERS.md#read-only-saved-variable-follow-up).

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
no client input or manual installation copy. [Requirements and evidence](docs/SHARED_BINDING_MODIFIERS.md).

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
or application is authorized. [Exact current checkpoint](docs/validation/inventory-native-current-checkpoint-2026-11-16.json).

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
[Current evidence and exact limits](docs/validation/inventory-eval-food-current-2026-11-16.json).

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
[Exact result, provenance and limits](docs/validation/trinket-native-three-scan-2026-11-16.json).

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
[Exact sources, controls, checkpoint and limits](docs/validation/trinket-bag-scan-allocation-2026-11-16.json).

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
[Exact sources, all ten profiles and limits](docs/validation/pending-task-copy-candidate-2026-11-16.json).

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
[Exact sources, all nine raw profiles and limits](docs/validation/reagent-normalization-candidate-2026-11-16.json).

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
[Sources, controls and pending native checks](docs/validation/syndicator-bank-row-reuse-2026-11-16.json).

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

[Exact sources, regressions and pending native checks](docs/validation/syndicator-partial-oldrows-2026-11-16.json).

15 November inventory lag goal ACTIVE (`LHO-INDEX-FLAGS-20261115`). R2 was
APPLIED at15:53:07UTC to Inventory/Index.lua e1cdab75 and two durable tests
(strict zero-table budget2ef703a9;85cases/530checks3734c343). The private
eight-region summation is intentionally duplicated so public GetCount retains
its exact baseline body; public overrides/hooks keep fresh normalized options.
Existing99,232 checks, nine independent cases/237 checks and17consumer pairs
pass; the strict durable test passes99,237 checks and rejects the baseline's
20,000 normalized tables. Frozen full baseline401/1090 and candidate402/1091
PASS with stable full manifests and19current R34 pins. Latest current-source
run(16:27:16UTC) has408scripts/1097syntax PASS with zero failures, but both full
and Lua sourceStable=false: Bars State/Watch, input binding, binding route test
and generated verification changed concurrently. No retry or unrelated fix;
preserve those edits and keep current whole-corpus acceptance open.
Desktop real-Core CPU falls1203.125->812.5ms/1million queries(-32.47%); fallback
CPU-4.62%. Direct public body is identical; its median is one CPU tick higher
and elapsed+0.18%. Whole warm/cold results are mixed; cold medians CPU+3.92%
and wall+6.47%. No stable whole-event or native FPS/spike gain is established.
R1 stayed unapplied; its measured440B/query,44KB/100rows and about264KB/six
deliveries are desktop Lua5.4 allocation evidence. R2 has unchanged allocating
bodies plus strict zero-table proof, without a fresh R2 GC measurement.
Existing SYNC put e1cdab75 on all five client disks; no manual copy. I42a now
observes current R2 loaded in Forever70938: NEW boolean/function types and
Index15(ReadOpts11)/Index139(GetLiveCount134) stack. This is source-line evidence,
not a loaded-function cryptographic hash or other-client certification. I41d
queued203characters then guarded out with unknown execution; debug is boolean,
so its getinfo payload is invalid. I40 before count0 median1.6094999909401ms/100
and after count176 median1.3808999955654ms/100 each have seven raw batches and
CVars0/120/30. Scene/count differ: comparison UNMATCHED; no gain percentage.
Next count audit is source-only: valid default zero already makes one modern
attempt; restock last-resort/charge probes need authority-preserving baselines.
No new candidate or positive-cache frequency proof; do not revive R15/R28/R18.
R3 idle jump PID35680/idleapproved20261115r4a stopped16:31:04UTC on stale
heartbeat. R4b PID48720 stopped18:20:24UTC on stale heartbeat; host confirmed
absent18:26. Exact reviewed R4 restarted18:27:03 as idleapproved20261115r4c,
PID33168, source4b9baecb. Root verified alive/empty stderr; craft_hold token
root-crafting-deferral-20261115T1825Z is present after a pre-launch capture of a
57s cast and queued crafting. Held; no movement claim or automatic future craft
detection. Root keeps heartbeat; earlier chat locks released; native tests now
explicitly permitted under root-owned guards. On pause set CANCEL/JUMP_STOP first, stop owned workers, then
perform only the requested reload/continuity and record the diagnostic epoch. No purchases/sales/deletes, provider
edits, profiler preference changes, manual sync or publication by this slice.
G43 raw FontString calibration stops after1of3planned pairs: baseline shown=true
0.36879998445511ms/1000, conditional0.34950000047684ms/1000. Tiny best-case margin
unproved; actual SetCount secrets/hooks/format cost untested; no candidate/gain.
Two successful calls created2hidden Frames+2FontStrings, no handlers/timers.
Later loading screen/chat reset/windows closed do not prove reload or cleanup.
AH synchronous skip amplification audit is BASELINE ONLY: modern/legacy
n1/10/100 manual no-recipe/preferCrafting=false limited-zero-cap workloads give
6/42/402full builds and6/420/40200row reconstructions. Six workloads plus five
freshness/error controls PASS;14audited sources stable. At100:40200List name
reads,85851modeled live calls,80400SetItemUnits. Naive reuse loses public target/
name mutations and a late raw name error; positive-cap async reharvest remains
required. No timings/native frequency/product/candidate claim. [AH audit seal](<C:/Users/mario/.codex/visualizations/2026/11/10/01a1c551-7947-7cf1-8aac-c0891cf4fa6b/lag-hotspots-20261114/resume4-20261114T222014Z/auction-synchronous-skip-audit/seal.json>).
Q44 native q44workload20261115c ACK:4returned rows,1zero PurchaseLimit,
one public GetRows3.095900028944ms. Reconciliation and post-clock cap-default
initialization remain; source vendor sale predates the probe. One sample is not
CPU/FPS, PrepareNext frequency, six-times extrapolation or all saved targets;
Q44 zero remains unexplained by disk snapshots; live row epoch is unestablished. Initial two-SetItemUnits deletion
is REJECTED/no apply:4scenarios/18checks per variant,2canonical matches but2
constructed public-extension counterexamples change final data. No installed
third-party extension is asserted; no product/candidate change.
Saved relevance snapshots are separate:17:56:29(9f88f971) has2positive
manual/0limited-zero and preferCrafting missing=>true; newer18:00:11(247b7983)
has0false-price flags/0limited-zero anywhere,3positive combat fields,0saved
vendor plans. Do not combine old2+new3 as one census; disk is not memory and
does not explain Q44's zero. Reload at18:00 is only a hint. Q45a-d guarded before input; e later ACKed
Q45 4 true with no Z45 line visible below the header. These later existing rows
do not identify/disprove Q44 zero or establish its epoch. No rebuild requested;
normal PurchaseLimit/default initialization caveat remains.
Awaited Trinket baseline sealed:40scenarios/5families/1000ticks,9pins stable.
Hidden/unbound already park; shown rawQ/E idle uses1000callbacks/2000key reads/
1000clocks and0binding-metadata reads per tick. none/bag_only retain that work
despite nil canonical bind widget. Mouse release parks after2callbacks; wheel
expires after200x1ms ticks. Counts only, no native/CPU/FPS or accepted candidate;
Trinket R1 and R2 are REJECTED/no apply: R1 loses four resolver/reentry
controls; R2 has two conditional passes but six constructed preinstalled API-
wrapper result/error parity failures. No installed foreign wrapper is asserted;
no performance/allocation/native trials or application. Baseline remains sealed. Native tests are now explicitly permitted; root owns guarded commands.
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
[Exact evidence and remaining native checks](docs/validation/inventory-live-count-flags-2026-11-15.json).

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
[Requirements, commands and evidence](docs/MAIN_ROW_RECOVERY.md).

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
[Exact restore, checkpoints, unresolved native state](docs/validation/border-types-2026-11-15.json).

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
[Exact reports, source identities, tests and remaining limits](docs/validation/border-types-2026-11-15.json).

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
[Failure, reproduction, source identities and validation](docs/validation/border-types-2026-11-15.json).

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
[Source, checkpoints and limits](docs/validation/border-types-2026-11-15.json).



Next inventory lead: `Inventory/Index.lua` creates 100 normalized option tables
per callback in the R34 model (600 over six deliveries); the deeper 1,180 native
count calls per callback are a different count. No candidate has been built.
The external `index-live-count-flags/design-gate.json` records the proposed scalar
path and the unresolved hook-identity contract. Verify table-form hook behavior
with an isolated owned function before bypassing a public count call. Preserve
both HasWarband/tonumber passes, the second original charges read, fresh override
options and their late warband mutations. Do not revive the rejected R18 cache.

15 November 11:40 UTC current continuation: the user now requests the whole
open/type/Enter chain immediately, superseding intermediate blank/full-draft
image waits for the fixed harmless print. Reviewed R8 c7ffadf8 queued the
33-event chain in15ms in run instantall20261115a. Root immediately viewed a
NEW JQ4p1 159296.682 reply; chat closed and crafting continued. The later CLI
ACK annotation exceeded120s and was REFUSED. Its journal correctly remains
submitted with commandAcknowledged=false, not ack-visually-attested. Preserve
the immediate visual result and refused annotation separately; do not rerun
or restamp. Functional native delivery is VERIFIED; only the later CLI metadata
annotation expired. Use R8 run for future separately reviewed payload variants;
older staged routes are historical. Do not repeat the print to convert its flag.
15ms is sender enqueue time, not ACK latency or inventory performance.
Earlier R7 fastsend20261115b has an accepted NEW JQ4p1 158981.621 ACK and63ms
sender time including40ms Enter hold. Native foreground acceptance remains pending.

Read-only P36 returned NEW P36F1685 from GetAddOnMetric('_FluxUI',8), the exact
Forever70938 CountTimeOver50Ms selector. This is a raw threshold-count signal
with unknown epoch/window, not bounded CPU, an inventory event, causality or
an optimization result. All62 command characters were verified before the
earlier staged submit. No profiler settings, observers, items or product Lua
changed in this diagnostic slice; newer unrelated border work is preserved.

Current jump helper is reviewed R3 PID42220, started11:26:22 under label
idleapproved20261115r3. PID36188 stopped11:13:33 on heartbeat expiry. The current
helper last deferred11:38:45 because PC input was active; no activation, Space
pair or movement is verified. Root released scoped no_jump after commands;
no_jump and input.lock were absent at this read, INPUT_HALTED remains. Use
scoped holds for complete command batches and retain180s/idle15s rules.

The grid count-write lead is source-only: loaded Combat/NonCombat SetCount may
repeat Show/SetText, but state/secret/repair semantics and added-getter costs
need proof. No fixture or candidate exists. Legacy FluxInv_Events is UNLOADED;
the remaining observer gap concerns active Init/Containers/Builtin/Watch raw
frames and vendor/timer/provider work. The goal stays ACTIVE, focused on
Inventory/EBS expensive frames and event bursts without feature/cadence loss.

15 November 11:10 UTC current inventory-spike continuation (supersedes older
chat/helper status below): the R6 background command route is now verified.
Run dualfinal20261115f used a fresh blank capture, typed the exact harmless
print command and produced a NEW local JQ4p1 157283.9 acknowledgement.
Root verified pre/post images; the journal is ack-visually-attested, chat is
closed and its input lock is released. This accepts only the fixed-print
background route. Foreground source/mocks pass, but native foreground use,
observer deployment and loaded-addon source adoption remain unverified.
INPUT_HALTED remains and old blind senders stay stopped. No profiler settings,
items or addon Lua files changed in this continuation.

The user now permits jumps except during chat/script input. Root released the
scoped no_jump after acknowledgement. Reviewed R3 helper PID36188, started
10:47:49 UTC, uses the three-minute interval and 15-second PC-idle condition.
At 11:09:33 it deferred because the PC was not idle; no activation, Space pair
or movement is verified. Reinstate scoped no_jump before a complete command
batch and release it after all commands finish. Prior PID44368's 10:19:20
heartbeat stop is historical, not the current helper state.

Both native presentation samples passed independent numeric checks. R3 has
969 intervals: median 16.7194ms, p95 31.18788ms, p99 104.64202ms, max 308.2077ms
and 11 above 100ms. R4 has 1,113: median 15.9503ms, p95 27.4937ms, p99 37.570912ms,
max 114.1185ms and one above 100ms. Foreground/activity conditions differ;
this is no before/after optimization gain. Neither has synchronized inventory
event attribution or checked final ETW loss counters. The pinned v1 output
uses QPCTime seconds despite its flag name. No positive producer loss warning
was reported, which does not establish losslessness.

R34 remains a measured desktop lead with no candidate: the 100-target/
100-visible-ID cold model makes 10,300 name calls and 1,180 count calls per
callback; six existing 200ms deliveries make 61,800 and 7,080. Native cost is
pending. The external four-tag Events V2 prototype has 75 cases/1,168 checks
and six rejected controls, but is not deployed and misses raw Inventory/
vendor retry costs. Root is examining built-in whole-addon profiler threshold
counts before selecting another probe. The goal remains ACTIVE with Inventory/
EBS expensive frames and event bursts primary; earlier acceptance remains pending.

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
[Exact source, checkpoint, scope and acceptance](docs/validation/border-types-2026-11-15.json).


15 November 10:37 UTC current continuation (overrides earlier native-startup
and chat-state summaries below): official PresentMon 2.6.0 captured 969 valid
whole-client presentation intervals in 20.141 seconds. Median was 16.7194ms,
p95 31.18788ms, p99 104.64202ms and maximum 308.2077ms; 15 intervals exceeded
50ms and 11 exceeded 100ms. This single observation has no synchronized
inventory event markers, addon/source A/B or proven FluxUI causality. Loss
counters were zero only at session acknowledgement; final loss is unverified.
The owned process exited 0, its session is absent and holds stayed unchanged.
No input, focus activation, preference or item action occurred. Earlier NVIDIA
R1/R2 startup failures remain preserved with unknown causes.

R34 now has an accepted whole-source desktop baseline: R2 has 11 profiles/
278 checks, with R1's 22 profiles/313 freshness checks retained. A defined
100-target/100-visible-ID cold-metadata model performs 10,300 modeled native
name calls and 1,180 count calls per actual vendor QueryItems callback.
Initial delivery plus five unchanged 200ms retries gives six full list builds,
61,800 name calls and 7,080 count calls. This conditional repeated discovery
is a lead for native attribution, not measured frame cost or a safe cache fix.
No R34 candidate, timing benchmark, addon Lua or external-addon edit follows.

The user explicitly wants profiling chat to work automatically with WoW in
either foreground or background, without waiting solely for window focus.
A separate reviewed dual-mode route is being prepared. The strict ready90a
attempt typed the full harmless command, then refused submit because the
capture expired BEFORE Enter; no new acknowledgement or observer resulted.
Root's fresh read-only capture at 10:33:19 UTC shows world view, no editbox
and no remaining draft. Do not submit or adopt the old typed capture.
INPUT_HALTED and root-owned no_jump remain. R3/PID44368 STOPPED at
10:19:20 UTC because the heartbeat expired; it has not restarted, and no
movement is verified. Root refreshed the heartbeat around 10:37 UTC, which
does not restart the helper. Keep jumps queued until commands and crafting
are clear. The goal stays ACTIVE with Inventory/EBS frame and event spikes primary.

15 November current priority (explicit user steering): all `Inventory/` and
related `ExtraButtonSystem/` paths are primary for now. The goal includes
ANY inventory-triggered FPS/frame-time lag spike: expensive individual frames
and event bursts, as well as steady work and average FPS. Attribute and fix
inventory/EBS consumer work triggered by cast/craft completion, bags, loot,
receipts, vendor/AH/pending work, bank and mail opening/closing or updates.
Track worst-frame, per-event and burst latency plus passive overhead; preserve
features, appearance and cadence. Desktop timings/allocation counts do not
prove native spike relief. The bounded R33 range side check is complete on disk;
return to inventory work. Do not expand casting or other UI work or reset the
active goal; earlier acceptance requirements remain pending.

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

15 November current native continuity: the user now permits chat commands,
but the 30-second read-only eligibility wait deferred with idle 1.781s, drawable
true and keys up, BEFORE keys, journal or lease. No chat opened and no observer
was installed. Frozen bootstrap `5d48148b`, INPUT_HALTED, root-owned no_jump
and held R3/PID44368 remain. Permission does not establish a working input path.

The installed signed NVIDIA PresentMon `045a5c14` alternative passed host and
unique-session-absent preflight. Controller `5c1c082e` requested a 20-second
capture; it ended INCOMPLETE after 0.031s: owned child 46520 exited 1, with no
session acknowledgement, CSV or output bytes. Final own-session query was
absent; the child exited, pending restoration was false and holds were unchanged.
The preceding image shows taxi/travel, so this episode is a CONTROL, not an
inventory capture. There are zero native frame-time results and no causal or
performance acceptance. Startup cause remains unknown; do not infer permission
denial or UAC. No retry has run. No focus, input, preference, item or source
change follows. Inventory-spike work remains primary and the goal ACTIVE.
The prior R33 docs gate passed at 09:32:52 UTC with 1116 sources, 623 reachable,
444 settings, 24 saved roots and 17576 links, writing no files. It predates this
continuity delta and does not validate native performance.

[Attempt, cleanup and permission boundaries](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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

[R33 exact identities, ranges and native limits](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[Exact decisions, source identities, modeled costs and pending native gates](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November 07:45 UTC current helper state: the user explicitly approved jumps
while the PC is idle. Reviewed R3 source c40bb8d2 is running as PID44368,
label `idleapproved20261115r1`: check every180 seconds, require15 seconds without
PC input, briefly activate the exact Forever window, pair Space and restore the
prior window when no external input/focus race is observed. First movement is
not yet verified. The external launch record is
`native/jump-real-r3-idleapproved20261115r1-launch.json` under the existing
resume4 evidence root. Keep heartbeat current. On pause set CANCEL/JUMP_STOP
first and verify this owned process stops. This permission covers jumps only;
`native/INPUT_HALTED` remains and automated chat/profiling stays halted.
Earlier no-helper/pending-permission statements below are dated prior states.

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
Keep external `native/INPUT_HALTED`; do not use blind Enter/WM_CHAR or remove
the halt on continue. A requested reload needs a verified safe control path.
On pause, set CANCEL first. No helper/probe is active; current reload adoption
remains unverified.
[Source, controls, samples and pending native gates](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[Source, observed aggregates, startup scope and cleanup](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[Aggregated source, controls, native results and cleanup](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

Current continuation checkpoint: R26/R27 are applied to disk after 393 scripts/
1,081 syntax checks; native adoption remains unverified and input is halted.
R21 fresh-login startup source is inferred with matching installed bytes; vendor
workflow acceptance is still PENDING. R18/R19 remain rejected and unapplied;
R23/R25 attribution completed with exact cleanup verified.
No keepalive helper is active: R2 is stopped, R3 is not deployed and idle-focus
permission is pending. Stop any newly owned helper before pause/done; retain
CANCEL/JUMP_STOP, input.lock, no_jump and heartbeat guards. Space posts/AFK clearance do not prove
jumps or guarantee online status. Explicit J14/Z cleanup remains verified.
Original helper sources/state/logs remain external and preserved.

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
[Versioned rejected evidence and current acceptance scope](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[Exact R21 source, controls, samples and native limits](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[Current native scope and exact-source cost map](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[Native attribution, cleanup and pending acceptance](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[Native profiler observations and limits](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[Banks, samples, restoration and limits](docs/validation/bank-effective-visibility-2026-11-15.json).

15 November R10 source-attribution audit (`LHO-RECIPE-EVENT-ATTRIBUTION-R10-20261115`):
current source has one central-bus recipe-update owner; its identity in the native
22–31ms R7 spans remains an inference. Exact-source desktop work passes1010checks
across30profiles and still invokes2581native-name reads per20-row/121-ID query;
these counts do not attribute native cost. The optional metadata probe passes95
desktop checks and was not installed. LowerMemo and RowOrder candidates remain
rejected; no new runtime candidate, native gain or FPS acceptance.
[Attribution boundary and rejected audits](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[R8 samples, data-only scope and unresolved acceptance](docs/validation/lag-hotspots-empty-mailbox-2026-11-14.json).

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
[R7 samples, attribution limits and rejected audits](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[Dated native evidence and comparison limits](docs/validation/casting-equality-work-2026-11-15.json).

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
[Exact sources, native scope and remaining acceptance](docs/validation/bank-effective-visibility-2026-11-15.json).

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
[Exact sources, raw samples and remaining acceptance](docs/validation/casting-equality-work-2026-11-15.json).

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
[Exact sources, measurements, fixture correction and remaining work](docs/validation/reagent-name-lower-work-2026-11-15.json).

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
[Exact sources, samples, native scope and next steps](docs/validation/passive-inventory-item-ids-2026-11-14.json).

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
[Requirements, limits and exact source](docs/validation/tooltip-scale-2026-11-14.json).

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
[Requirements, exact source pins and acceptance](docs/validation/blizzard-tooltip-2026-11-14.json).

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
[Exact pause, reload and resume order](docs/validation/lag-hotspots-pause3-2026-11-14.json).

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
[Exact native rows and continuity](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[Requirements, exact identities and native steps](docs/validation/extra-profession-ranks-2026-11-14.json).

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
[Native values and exact continuity](docs/validation/lag-hotspots-native-attribution-2026-11-14.json).

Native attribution control completed; both globals _FluxRKA3/LHO3O released.
Check attribution-state.json for live phase before any further temporary test. On pause, set resume3
CANCEL first, then run its reviewed attribution-cleanup-commands.json through
send_attribution.py with --cleanup and SHA87cac1ae71bf1638ac00116f2cbe62ff862e4ccb20d029a28e0935c489ad0226.
Both probes use30s cancellable timers once armed, zero SavedVariables/frames/prefs.
User confirmed the prior /say was concurrent jumping and requests resuming same
chat route; sender now clears stray input. No addon Lua changed this turn.


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
[Current native measurements, source comparisons and remaining work](docs/validation/profession-catalogue-allocation-2026-11-14.json).

14 November17:35CET catalogue allocation change APPLIED; full integration RUNNING.
Professions.lua748cff40 replaces private seen records with index/rank/key arrays;
new durable test e34a52c2. Three pairs/3063checks/145scenarios,8controls,static peer
PASS. Fresh2815-file source/history checkpoint +126settingsmetadata verified.
Only this owner/newtest changed this pass; all older user/group-hover work kept.
No native reload/after-candidate/FPS claim. Native diagnostics remain locals-only;
no watcher installed. Quick pause: write resume3-20261114T160712Z/CANCEL and
integration-job/CANCEL first; stop owned child via0.1s wrapper, then save delta.
[Current applied source and pending integration](docs/validation/profession-catalogue-allocation-2026-11-14.json).

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
[Native samples and current resume state](docs/validation/lag-hotspots-native-resume-2026-11-14.json).

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
[Exact pause state, new permission, reload boundary and resume order](docs/validation/lag-hotspots-pause-final-2026-11-14.json).

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
[Current resume state, permission and pause controls](docs/validation/lag-hotspots-resumed-2026-11-14.json).

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
[Causes, source identities, comparisons and pending acceptance](docs/validation/group-ghost-hover-2026-11-14.json).

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
[Failure, implementation and API limit](docs/validation/player-ghost-secure-followup-2026-11-14.json).

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
[Exact pause and resume state](docs/validation/lag-hotspots-pause-2026-11-14.json).

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
[Evidence and exact source pins](docs/validation/player-ghost-hover-2026-11-14.json).

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
[Current identities, results and remaining work](docs/validation/lag-hotspots-continuation-2026-11-14.json).

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
No branch/reset/force push/tag/repository replacement. [Publication record](docs/validation/addon-publication-2026-11-14.json).

Resume feature-specific native acceptance from the preceding records; the
publication task does not close the broader casting/inventory optimization work.

14 November LHO actual producer audit reproduces two unresolved synthetic
counterexamples using installed Syndicator code: cold closed-bank completion5→0,
and an old cold-mail job overwriting newer inbox facts (including equal-cardinality
wrong IDs). Three baseline repeats/three isolation pairs per fault/three extra
controls;38checks/run. External41 files unchanged. No bank/mail remedy applied.
Native tri-state count/provenance and persisted handoff need proof; header counts
alone cannot validate mail identities. User requires native populated-mail timing
before a fallback-delay decision; the available empty mailbox cannot establish it.
[Causal evidence and pending decisions](docs/validation/lag-hotspots-provider-counterexamples-2026-11-14.json).

14 November lag continuation: after the fresh 2,792-file source/history checkpoint and 375-script/1,063-syntax baseline gate, three commerce owners reduce recipe-scan allocations, select only relevant modern output aliases and reuse warm owned bag facts within a capacity call. Three paired source comparisons pass 770 focused checks/set and reject 13 compiled harmful controls. Affected installed checks pass 61 scripts with all 1,065 Lua hashes stable in that run; independent review reproduces 770 checks. Every profession native scan, craft invalidation and publication remains; aliases, partial/closed recipes, public overrides, cold bag retries and existing link return values remain. Desktop timings and allocation samples establish their modeled scope; no profession/vendor native CPU or FPS comparison is claimed. Keep the earlier full run historical until a new combined run seals current source.
[Source comparison and limits](docs/validation/lag-hotspots-commerce-continuation-2026-11-14.json).

14 November LHO empty-mailbox native observation: user opened the mailbox;
Forever70938 reports inbox0, Flux mail0, Syndicator source, reliabletrue and no
pending native mail command. Three 1,000-call GetInboxNumItems trials take
0.0418/0.0405/0.0398ms. Same-session _FluxUI native profiler counters over12.922s
increase230 for >1ms and0 for >5/10/50/100/500/1000ms; nested counters are not summed.
This is an unpaired existing-city observation, not a before/after FPS result or
populated/cold-mail latency measurement. No mail/item operations, activation,
profiler preference changes or persistent probes. User requires in-game measurement
before accepting the stale-mail fallback delay; that decision remains pending.
[Exact scope and readouts](docs/validation/lag-hotspots-empty-mailbox-2026-11-14.json).

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
[Requirements, remaining acceptance and evidence](docs/LAG_HOTSPOT_OPTIMIZATION.md).

Resume LHO native acceptance: keep the broader goal active. The final source set
is frozen and 375 scripts/1,063 syntax files passed with a current manifest. The
last vendor changes need a user-ready reload; no further source edits without a
new causal baseline. Next collect matched native cast/bag and bank/mail/vendor
timings through the existing optional profiling route when those contexts are
available. Do not automate travel or buy/sell/delete items. Item moves are allowed;
crafting remains simulated. The user's foreground exception covered only the
specific Conjure Food/cancel test, which finished with eight food received and a
matching button count; other native work remains background only. All temporary
Lua probes were cleared by the user's reload. Current/backup diagnostic roots are
both nil; preserve prior roots and profiler preferences in future captures.

14 November — current AH build is r27 (AHR-105/106). Opening Restock starts
one shortage-only preparation. Filled targets are skipped; passive bag/mail/
profession changes refresh counts without replacing choices, canceling searches
or reviving completed work. Matching purchase receipts still prepare the next
shortage. Buy next can start again after later stock changes; purchases remain
player presses. Explicit modern Scan all is still full pricing; old AH per-item.

Loot & Items → Restock: healing/mana AH upgrade prompts default on; bandage off.
Saved independent choices retain current-tier crafting/direct restock. Compact
native Keep / Block labels now fit; passive paints preserve native enabled states.
76 affected scripts/82 syntax PASS; 440 checks/20 profiles; 3 matched trials and
11 compiled harmful controls. Other verification records are historical, not a
full rerun. External `explicit-restock-20261114T090141Z`: 2780 files/history,
129 settings metadata; 5 installed copies match 6 runtime files read-only.

Next: user-ready reload, then native shortage opening, stable upgrade cards,
text fit/controller and purchases. No native input/reload/profiling this slice.
Preserve the other agent's meter work and test ownership. [Evidence](docs/validation/auction-passive-refresh-2026-11-14.json).

14 November — AHR-104 is current: all healing/mana potion tiers use actual
minimum restore, including buttons, crafting, vendor memory, AH and automatic
junk. Minimum 600 beats 500 even if the latter's maximum is higher. Existing AH
approval and per-purchase player presses remain; compact r26 controls stay.

Saved refs/vendor records and positive thresholds migrate from verified parsed
facts. `savedHealPotionTierBasis` / `savedManaPotionTierBasis` mark minimum-valued
thresholds. Unknown old facts stay saved but cannot rank/promote as verified
minimum candidates. Potion cache stores effect text/axes/minima; legacy maximum
alone is unresolved. Food/water/bandage ranking and manual Junk precedence stay.
74 affected scripts/79 syntax; 510 minimum checks/50 profiles; 10 harmful controls
PASS. Global verification labels other test results historical; no full rerun.
External `potion-minimum-20261114T083404Z`: 2778 files/history; 129 settings metadata.

Next: user-ready reload and native minimum-tooltip/button/AH acceptance checks,
without choosing an upgrade or buying for the user. No native client input or
profiling was used in this slice. Preserve the other agent's meter work and its
test/verification ownership. [Evidence](docs/validation/potion-minimum-restore-2026-11-14.json).

Full validation: 365 scripts and 1053 Lua syntax files PASS; complete current Lua manifest verified.

14 November — meter controls restored in `METER-CONTROL-RECOVERY-20261114`.
Explicit type/preset/custom/structure/tab/setup choices apply native windows and
default every displayed native pane to Current. Geometry/reopen/background keeps
later manual Overall/history. Keep the 13 November tooltip ownership and header
fixes; do not restore old GenerateMenu/OpenMenu/private-setter paths.

476 control checks, 12 focused scripts, both pinned native menu replays and
7 compiled harmful controls PASS. Original cached native entries are selected
only after provenance checks; missing/tainted caches retain setup feedback.
Use the existing user-native test route: reload outside combat, reselect the
Dispels/Interrupts layouts and verify titles/data/Current, two fights, history,
drilldown and controller. Native combat/taint/pixels/CPU/FPS remain NOT RUN.
External `meter-recovery/checkpoint-20261114T081300Z` preserves 2771 files/history
and 53 settings metadata entries; no settings restore or client input. Main and
concurrent work preserved; no commit/push/manual sync.
[Requirements](docs/METER_STANDALONE.md#meter-control-recovery--14-november-2026);
[evidence](docs/validation/meter-control-recovery-2026-11-14.json).

14 November — current AH build is r26 (AHR-102/103). Upgrade cards are 44px with
candidate icon/Upgrade above Keep/Blacklist; details are in tooltips. Order:
healing, mana, bandage, spell reagents, consumable configuration, then others.
Both real merged targets and virtual no-reference proposals use that order and
keep independent actions. Auction scripts/1053 syntax; 1220 inline, 672 confirmation
and 780 geometry checks; 8 harmful controls PASS. The verified recovery/load list
remains intact. Existing source checkpoint is external in
`compact-upgrades-20261114T080946Z` (2776 files/history; 129 settings metadata).

The user explicitly assigned meters to another agent. Leave meter inspection,
testing and changes to that agent while working on this AH task.

Next native check: after the user's crafting is finished and they choose to
reload/reopen AH, inspect the compact text fit, hover details, three independent
choices, next row and scrolling. Check controller/native other-client behavior
separately; desktop geometry is not pixel or input certification. The background
capture showed active crafting and AH closed; no input/reload was sent. No
upgrade decision or purchase was made for the user. Do not rerun old recovery
scripts on newer work. [Evidence](docs/validation/auction-compact-upgrades-2026-11-14.json).

14 November — current source is r25 with inline multi-item upgrades and shared
exclusions; the unrequested source/load-list rollback has been recovered.

365 scripts/1053 syntax files PASS; full normalized source manifest matches.
Keep the recovered TOC entries for options Skin, meters/threat, mail, auction,
party and cast helpers. Before versions and verified archives are external in
`restock-shared-blacklist-20261114T072300Z`; recovery scripts are historical,
guarded operations, not commands to rerun on newer work. Writer remains unknown.

Next safe native checks: wait until the user is idle, then open recovered options
and inspect healing/mana/bandage inline choices without accepting for the user.
Verify multiple independent actions, scrolling/controller, saved tier changes,
mail/vendor/bank/craft follow-up and explicit purchase receipts separately.
Keep Forever in the background; never send a chat probe without verifying current
empty input. The last attempt produced no output during player movement and was
excluded. Meter skin/Threat visibility after reload is observed; it does not prove
options/input/taint/other-client parity or FPS. No agent purchase/upgrade/reload.

Settings: Loot & Items → Restock contains the default-on Discolored filter and
manual item blacklist; Loot & Items → Vendor has 3 default-on carried-upgrade junk
protections. Manual Junk wins. Old AH still prepares one item/whole stack per
player press, with no full Scan all restock control. [Current evidence](docs/validation/auction-inline-upgrades-2026-11-14.json),
[recovery evidence](docs/validation/flux-source-recovery-2026-11-14.json).

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
[Requirements/native scope](docs/AUCTION_RESTOCK.md#forever-empty-browse-and-restore-amounts);
[exact sources and acceptance](docs/validation/auction-potion-browse-2026-11-14.json).

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
[Requirements/native checks](docs/AUCTION_RESTOCK.md#usable-potion-tier-upgrades-during-per-item-scans); [evidence](docs/validation/auction-potion-tier-2026-11-14.json).

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
[Requirements/native checks](docs/AUCTION_RESTOCK.md#restock-mail-opening-speed); [evidence](docs/validation/auction-mail-speed-2026-11-14.json).

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
[Requirements/native steps](docs/14-unit-frames.md#duplicate-system-debuffs--13-november-2026); [evidence](docs/validation/unit-debuff-overlap-2026-11-13.json).

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
[Requirements/native checks](docs/AUCTION_RESTOCK.md#stable-craft-completion-and-restock-work); [evidence](docs/validation/auction-craft-steady-2026-11-13.json).

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
[Requirements and steps](docs/SECRET_TOOLTIP_METER_ERRORS.md#secret-class-texture-and-tooltip-provenance-follow-up);
[evidence](docs/validation/tooltip-visual-followup-2026-11-13.json).

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
[Requirements and native steps](docs/SECRET_TOOLTIP_METER_ERRORS.md#world-cursor-follow-up-at-202955);
[evidence](docs/validation/world-tooltip-state-2026-11-13.json).

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
[Requirements/native checks](docs/AUCTION_RESTOCK.md#old-auction-house-per-item-searches); [evidence](docs/validation/auction-legacy-item-2026-11-13.json).

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
[Fix and native steps](docs/METER_STANDALONE.md#header-alignment-recovery--13-november-2026);
[evidence](docs/validation/meter-title-2026-11-13.json).

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
[Requirements/native checks](docs/AUCTION_RESTOCK.md#fast-purchases-and-usable-pending-item-buttons); [evidence](docs/validation/auction-speed-ready-2026-11-13.json).

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
[Requirements and native checks](docs/AUCTION_RESTOCK.md#item-overview-follow-up-automation-and-explicit-price-limits);
[evidence](docs/validation/auction-followup-items-2026-11-13.json).

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
[Requirements and acceptance](docs/MINIMAP_EXTRA_LAYOUT.md#screen-side-border-and-minimap-clock-layering);
[evidence](docs/validation/minimap-side-border-2026-11-13.json).

13 November action/badge/extra counts (ACTION-COUNT-REFRESH-20261113; ACR-01–05): normal bars now receive light bag-count publications; validated spell-use events refresh count/tint through existing coalesced lanes. Count-held form settle also restores badge tint. Two watch owners; no new frame/timer/poll/hook/scan or secure action change. Read-only Gethe five-client pins and Bartender4/LibActionButton/installed ButtonForge comparison retained. 666 focused checks across five client models/both providers; three exact checkpoint pairs reject224 old failures; seven harmful controls rejected. Full343scripts/1031syntax PASS with current complete manifest. External2712-file source/history checkpoint and47 settings metadata verified; private values not copied. Concurrent auction/minimap work preserved. Native event delivery/operation/taint/pixels/controller/CPU/FPS NOT RUN; existing user-native route retained. No foreground/input, settings/profiler writes, manual sync or publication.
[Requirements, comparison and native steps](docs/ACTION_COUNT_REFRESH.md); [evidence](docs/validation/action-count-refresh-2026-11-13.json).

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
[Requirements and acceptance](docs/AUCTION_RESTOCK.md#silent-waiting-and-changed-ingredient-stock);
[evidence](docs/validation/auction-restock-recovery-2026-11-13.json).

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
[Current requirements and acceptance](docs/MINIMAP_EXTRA_LAYOUT.md#dynamic-minimum-and-automatic-frame-movement);
[evidence](docs/validation/minimap-dynamic-2026-11-13.json).

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
[Requirements and acceptance](docs/MINIMAP_EXTRA_LAYOUT.md#empty-slots-automatic-growth-and-optional-overlay-visibility);
[evidence](docs/validation/minimap-visibility-2026-11-13.json).

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
[Fix and acceptance](docs/AUCTION_RESTOCK.md#mailbox-tooltip-argument-correction);
[evidence](docs/validation/mail-restock-tooltip-2026-11-13.json).

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
[Requirements, sources and acceptance](docs/SECRET_TOOLTIP_METER_ERRORS.md).

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
[Behavior](docs/AUCTION_RESTOCK.md#integrated-restock-workflow-13-november-2026);
[evidence](docs/validation/auction-workflow-2026-11-13.json).

13 November Blizzard party dispel setting (PARTY-BLIZZARD-DISPEL-20261113): both
party styles and their previews honor Blizzard's dispellable-only checkbox through
a read-only per-frame predicate, retaining Flux's existing strict option and raid
scope. Existing CVar events refresh visible party auras, including combat; hidden
owners stay retired. 418 focused checks and the full 338-script/1,026-Lua-syntax
run PASS; the complete current Lua manifest and documentation validate. External 2,694-file source/history checkpoint and 183 settings
metadata entries verified. Native pixels/combat/taint/controller/CPU/FPS NOT RUN;
existing user retest retained. No client control or settings/profiler writes.
[Behavior and native checks](docs/PARTY_DEBUFF_VISIBILITY.md#blizzards-dispellable-only-checkbox--13-november-2026).

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
[Behavior](docs/AUCTION_RESTOCK.md#vendor-catalogue-observations-and-auction-discounts);
[evidence](docs/validation/auction-vendor-routes-2026-11-13.json).

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
[Behavior](docs/AUCTION_RESTOCK.md#follow-up-button-and-closed-profession-recipes);
[evidence](docs/validation/auction-followup-2026-11-13.json).

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
[Behavior](docs/AUCTION_RESTOCK.md#purchase-identity-selection-and-charged-items);
[evidence](docs/validation/auction-purchase-charges-2026-11-13.json).

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
[Requirement](docs/MINIMAP_EXTRA_LAYOUT.md#combat-hiding-applies-only-to-the-screen-side-grid); [evidence](docs/validation/minimap-side-combat-2026-11-13.json).


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
[Current requirement](docs/MINIMAP_EXTRA_LAYOUT.md#scale-normalization-100-equals-the-previous-85); [evidence](docs/validation/minimap-scale-basis-2026-11-13.json).


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
[Current requirements](docs/MINIMAP_EXTRA_LAYOUT.md#current-behavior-automatic-grids-and-screen-side-grid-scale); [evidence](docs/validation/minimap-auto-layout-2026-11-13.json).


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
[Requirements and native checks](docs/MINIMAP_EXTRA_LAYOUT.md#follow-up-screen-side-resizing-and-aura-placement); [evidence](docs/validation/minimap-side-aura-2026-11-13.json).


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
[Task evidence and native checks](docs/TRINKET_EQUIPPED_USABILITY.md#13-november-follow-up-intermittent-dark-faces-and-cooldown-overlays).

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
[Requirements and native checks](docs/SYNDICATOR_SYNC.md); [evidence](docs/validation/syndicator-sync-2026-11-13.json).

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
[Behavior/API](docs/CHARACTER_RECIPES.md);[evidence](docs/validation/character-recipes-2026-11-13.json).

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
[Requirements and native checks](docs/MINIMAP_EXTRA_LAYOUT.md); [evidence](docs/validation/minimap-layout-2026-11-13.json).


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
[Requirements and acceptance](docs/OPTIONS_REWORK.md#13-november-sidebar-bindings-and-shared-threat-warnings);
[evidence](docs/validation/options-shared-threat-2026-11-13.json).

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
[Current behavior](docs/AUCTION_RESTOCK.md);[evidence](docs/validation/auction-restock-potion-stall-2026-11-12.json).

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
[Behavior and remaining native checks](docs/AUCTION_RESTOCK.md);
[current evidence](docs/validation/auction-restock-dense-potions-2026-11-12.json).

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
[Current behavior and native checks](docs/AUCTION_RESTOCK.md).

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
[Requirements and remaining native acceptance](docs/AUCTION_RESTOCK.md).

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
[Coverage, source ownership and native limits](docs/COMBAT_GRID_LIVE_COUNTS.md#all-seven-real-button-modules-audited-together).

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
[Native evidence and completion recovery](docs/COMBAT_GRID_LIVE_COUNTS.md#native-capture-loading-completion-left-open).

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
[Requirements and remaining native acceptance](docs/COMBAT_GRID_LIVE_COUNTS.md#screenshot-follow-up-count-sources-and-loading-holds).

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
[Correction and remaining acceptance](docs/TRADESKILL_CAST_THEMES.md#fill-and-visible-glow-correction).


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
or publication. [Requirements, implementation and checks](docs/TRADESKILL_CAST_THEMES.md).


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
client input, preference write, manual sync or publication. [Evidence](docs/validation/focus-no-resource-2026-11-10.json).


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
heads unavailable; existing dated pins retained. [Evidence](docs/validation/party-health-fit-2026-11-10.json).


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
[Findings, comparisons and native limits](docs/PASSIVE_PERFORMANCE_PASS3.md).

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
[Correction, regression and native steps](docs/COMBAT_GRID_LIVE_COUNTS.md).

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
[Requirements, sources and acceptance](docs/PARTY_DEBUFF_VISIBILITY.md).

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
[Cause, fix, evidence and native limits](docs/VENDOR_JUNK_TAB_FREEZE.md).

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
[Fix, comparisons and native steps](docs/COMBAT_GRID_LIVE_COUNTS.md).

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
[Findings, comparisons and limits](docs/PASSIVE_PERFORMANCE_PASS2.md).

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
[Changes, tradeoffs and evidence](docs/RESOURCE_EFFECTS_PERFORMANCE.md).

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
[Cause, correction and native limits](docs/POWER_PARTITION_COMBAT_JOIN.md).

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
[Before/after results and constraints](docs/PASSIVE_PERFORMANCE_OPTIMIZATION.md).

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
pause preserved. [Findings and optimization order](docs/PASSIVE_PERFORMANCE_AUDIT_2026-11-10.md).

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
[Requirements and evidence](docs/MINIMAP_TARGET_FOCUS.md).

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
[Exact source evidence and limits](docs/validation/npc-window-opening-audit-2026-11-10.json).

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
[Requirements and evidence](docs/20-vendor-restock-junk.md#bank-and-vendor-gossip-checkbox--10-november-2026).

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
[Behavior, source identities and evidence](docs/20-vendor-restock-junk.md#single-choice-vendor-gossip--10-november-2026).

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
[Evidence](docs/validation/options-native-border-2026-11-09.json).

9 November 19:27 Copenhagen — USER PAUSED live party/raid work.
Temporary native recorder stopped; FXPAUSED true true confirms original report
restored and recorder finished; probe/setup/last globals cleared; profiling0.
New shared fix is installed and loaded (raid-units), but candidate combat retest
has NOT RUN. Baseline native capture proved a defect: IsInRaid=true in combat
while native group:raid parsed party; raid-unit existence correctly parsed raid.
Player-style party remained visible. Both APIs reported secure. Fix uses native
roster-token drivers on EVERY client, covering40raid slots and party/pets/targets/
optional raid pets. No new production events/timers/frames. Full278scripts and
948syntax PASS;53615focused checks/2800combat transitions;baseline rejected,
3candidate repeats and4harmful controls. External2484-source/history checkpoint,
all baseline84rows and callback/gap screenshots, comparison and full reports:
forever-group-live-20261109T174833Z under the authorized visualizations root.
See its PAUSED.json. Source changes: FluxRaidSecure.lua/FluxRaidHealerExtras.lua;
new tests raid_group_conversion_conditions.lua and support/group_condition_parser.lua;
existing secure/party/combat/extras fixtures now parse actual clauses. Baseline
409.277s had12frame gaps (peak1231ms) and20slow callbacks; includes loading/scene
changes, so not all are Flux/group cost. Candidate only solo/OOC before pause.
Resume: native bidirectional conversion/roster retest, inspect exported baseline
rows/spikes, finish affected docs/ledgers/reference freshness. Foreground targeted
diagnostics were explicitly allowed for THIS test; default background rule remains.


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
[Detailed evidence and limitations](docs/FOREVER_NATIVE_PERFORMANCE.md).

9 November Inventory Awareness placement (OPTIONS-AWARENESS-20261109; REQ-OPT-33):
Inventory Awareness is inside Loot & Items > Loot, removed from Status Bars.
Original controls/callbacks/storage scope/Syndicator delegation remain. No new
sidebar entry or gameplay driver.6,207 placement/1,242 complete-shell checks PASS;
previous catalog rejected by both harnesses. Native acceptance remains NOT RUN.
[Evidence](docs/validation/options-awareness-2026-11-09.json).

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
[Current requirements and evidence](docs/OPTIONS_REWORK.md).

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
[REQ-OPT-23 through29 and evidence](docs/OPTIONS_REWORK.md).

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
acceptance](docs/COMBAT_GROUP_LIFECYCLE.md).

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
[REQ-OPT-22, current hierarchy and evidence](docs/OPTIONS_REWORK.md).

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
native latency/pixels/taint acceptance still pending. [Details and evidence](docs/PARTY_STEADY_PERFORMANCE.md).

Follow-up: immediate party/raid visibility on combat joins remains required
(REQ-RF-83). Fresh pinned secure-source replay passes255908 checks plus1035
party checks, including revealing a hidden prepared parent. The existing native
secure drivers already own this path; the optimization does not defer it to
combat exit. Actual client timing/taint acceptance remains pending.

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
sync or publication. [Requirements and evidence](docs/19-nameplates.md#combined-objectives-and-dynamic-width--9-november-follow-up).

9 November category correction (OPTIONS-UNIT-FRAME-CATEGORY-20261109): Unit Frame
is now an independent top-level category beside Quality of Life, with that exact
singular label and all ten frame tabs. Combat contains Action Bars, Bindings and
Keybindings. Internal IDs, original builders, settings, scopes, aliases and icon
remain. 5,782 placement +441 shell checks across five models PASS; both wrong
nesting/name controls rejected. Native acceptance remains pending; no game input,
settings/profiler writes, manual sync or publication. REQ-OPT-21 supersedes the
earlier Combat nesting. [Current requirements and evidence](docs/OPTIONS_REWORK.md).

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
[Requirements, current tab map and validation](docs/OPTIONS_REWORK.md).

Earlier native-readiness audit is retained in `docs/validation/options-native-readiness-2026-11-09.json`; the user subsequently authorized the Unit Frames reorganization below. Native acceptance still awaits the selected test route.

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
[Requirements, exact sources and native steps](docs/10-flux-window.md#restedxp-pins--9-november-2026).

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
[Current requirements and evidence](docs/OPTIONS_REWORK.md).

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
[Source findings and remaining requirement](docs/UNITFRAME_DEBUFF_COMBAT.md#supported-route-audit--renewed-request).

9 November supplied sidebar reference: accepted180x675 screenshot now drives compact framed categories, 24-unit feature rows, fixed22-unit system buttons and16-unit fitting icons on every client including Forever. Earlier icon-free styling superseded. User category relocation is implemented with4908 actual-builder mapping checks and421 complete-shell checks PASS; prior source objects/roots/info paths, valid mode lists and saved data retained. Quality of Life10tabs;Adventure/Combat/Utilities;fixed Settings/Profiles/Patch Notes/Credits. Native art/input/persistence/taint/performance NOT RUN; Witchcraft setup approval remains pending. No game input, settings/profiler writes, manual sync or publication. [Requirements and accepted reference](docs/OPTIONS_REWORK.md).

9 November options category clarification (OPTIONS-NAVIGATION-20261109): user explicitly authorizes moving settings to match the reference. Quality of Life has all10 reference tabs; Adventure/Combat/Utilities groups and fixed Settings/Profiles/Patch Notes/Credits footer. Original controls have one primary location each; original roots/info paths/owners and saved data remain. 4898 real-builder mapping checks and266 full-shell checks PASS across five desktop clients; three harmful catalogs rejected. Forever Options tabs/minimal sliders/list headers/scroll art and Journeys backdrop use native assets; other client families retain native templates. Native pixels/input/persistence/taint/performance remain NOT RUN; selected Witchcraft setup still awaits approval. No game input/settings/profiler writes/manual sync/publication. [Requirements and placement map](docs/OPTIONS_REWORK.md).

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
[Requirements, evidence and native steps](docs/CONSUMABLE_CRAFT_TIERS.md).

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
[Correction, source restrictions and native steps](docs/UNITFRAME_DEBUFF_COMBAT.md).

Earlier DEBUFF-COMBAT-COLORS-20261109 is REJECTED by the user's13:45:15 native forbidden-object error. Its desktop mock allowed an inaccessible registered Texture. Retained comparisons are historical evidence only; see the [correction and open requirement](docs/UNITFRAME_DEBUFF_COMBAT.md).

9 November options rework (OPTIONS-REWORK-20261109): replaced HUD-tinted options chrome with the running client's native portrait/inset/tab skin; reference-style grouped navigation, collapsible settings and cross-page search across all 15 existing pages. Added Escape > FluxUI Settings; existing commands, builders, data and embedded editors retained. 240 focused lifecycle checks across five desktop client models and full271-script/940-syntax checks PASS; native pixels/input/persistence/taint/performance remain NOT RUN. User chose Witchcraft in-game; it is neither installed nor connected, so setup authorization/client restart remain needed. No game input, private settings/profiler writes, manual sync or publication. [Requirements, source pins and resume steps](docs/OPTIONS_REWORK.md).

9 November current-addon publication: include all current non-ignored source, assets, documentation and validation on main. External 2400-file source/history checkpoint and166 on-disk settings files verified. Existing full270-script/937-Lua PASS report matches the complete current Lua manifest; five publication-policy tests pass. DoctorFlux author/committer and no co-author trailers are required by active hooks. Native acceptance limitations remain unchanged.

9 November native bag item targeting (BAG-ITEM-TARGETING-20261109): runtime
fault remains OPEN. Forever native bags/bag addon off; crate-like item starts an
item-target cursor. Saved12:44:34/count3 stack ends in native UseContainerItem;
first taint writer unknown. Existing `/fluxinput bags` now captures read-only
before/10-second targeting and native field ownership;574 focused checks and
five related suites PASS. User no longer has the original items; do not require
obtaining another crate. If any equivalent case recurs, reload and capture with
optional taintLog2, restore prior logging value and reload to save. Read Forever Logs and
FluxPerfCaptureDB.bagInputDebug; do not publish private settings/logs. Preserve
old focus acceptance/mini-menu limitation;00:53:20 matches historical report.
New13:00 log has no matching bag/action trace; no saved bag capture yet.
No native action, feature removal or runtime interaction fix yet. External
2395-source/history checkpoint and120 settings metadata verified.
Full270-script/937-syntax validation PASS; complete Lua corpus unchanged.
[Scope, source identities and exact steps](docs/BAG_ITEM_TARGETING.md).

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
[Requirements, sources and acceptance](docs/BAGANATOR_JUNK_ACTIVATION.md).

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
claim. [Exact inspected sources and checks](docs/validation/baganator-junk-detector-2026-11-09.json).

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
[Scope and evidence](docs/UNITFRAME_COMBAT_TRANSITIONS.md#focus-colors--9-november-follow-up).

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
[Feature and acceptance](docs/19-nameplates.md#quest-kill-and-loot-progress--9-november-2026).


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
[Scope, sources and steps](docs/UNITFRAME_COMBAT_TRANSITIONS.md).

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
[Scope and evidence](docs/CAST_REJECTED_ATTEMPTS.md).

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
[Requirements and acceptance](docs/19-nameplates.md#quest-kill-and-loot-progress--9-november-2026).


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
932-syntax validation PASS; no source drift. Result linked in [scope and evidence](docs/MENU_PRESS_INPUT.md).

9 November repository replacement completed. DoctorFlux/FluxUI now has new ID
1451123700 at the same URL; old1416752820 was deleted. Root be90cdcc2f14 contains
the current addon snapshot, no old parents, DoctorFlux author/committer and no
co-author trailers. Sole main and exact remote tree verified; only DoctorFlux in
contributor API; initial identity workflow passed. Old source/history/index and
settings are externally recoverable; do not republish old refs. Hooks are active;
never bypass them. Future uploads: policy test, identity check, normal main push.
No more repository deletion is needed. [Publication policy](docs/PUBLICATION.md).

9 November focus fix is implemented and loaded on Forever70862. Background
native focus/clear shows then truly hides its mouse region; BugTabs0. User
confirms player Set Focus menu and combat focus/clear macros both work; target
menu passed earlier. Mini-frame menus remain; user chose native bindings/macros
for their restricted callback focus action. Full263/930 PASS with current
manifest;15 synchronized owners match. No commit/push or settings reset.

Next focus acceptance: physical click-through behind empty focus during combat;
pet/party/raid menus; feature disable/re-enable and matched pixels; other native
focus-capable clients. Old unrepaired Forever fallback is not certified fixed.
Do not add gestures or replace protected APIs. Keep WoW background, preserve any
existing focus before tests, and do not automate combat. Desktop reproduction:
`lua tests/focus_secure_visibility.lua`, `lua tests/focus_native_menus.lua`,
`lua tests/unit_combat_menus.lua`. [Scope/evidence](docs/FOCUS_SECURE_VISIBILITY.md).
The older cooldown acceptance blocker below is a separate unresolved task.

9 November remaining native acceptance is blocked by the background-only rule:
Windows repeatedly reports Forever foreground. The latest alias probe refused
before its first key; the bounded35second availability process ended with no
stable non-game foreground and no input. Same condition recurred across three
goal turns; prior native progress is retained, not marked complete. Native slash
entry/Escape source ownership is verified, but no editor interaction ran. Current
261/928 source manifest still matches; no runtime/settings/profiler changes.
Resume with browser/chat continuously active and Forever behind it; verify normal
Edit Mode/custom save, matched previews, resource characters and other clients.
[Blocked audit](docs/validation/cooldown-native-blocker-2026-11-09.json).

9 November native cooldown acceptance: Forever1.60.1/70862/16001 retained
exactly one selected FluxUI profile after a guarded native reload. BugTabs0;
all four sampled aura-map fields secure. All requested settings match the native
active layout. Four viewer positions match planned column offsets and4UI-unit
clearance from current player bounds within0.001units. This mage has no visible
class-resource row; Arcane/combo/form cases and other native clients remain open.
Native custom-save and matched preview pixels are also pending. Full261/928 and
documentation961sources/602reachable PASS. No runtime changes or preferences
changed; no foreground/mouse/clipboard control, gameplay or publication.
[Native evidence](docs/validation/cooldown-native-acceptance-2026-11-09.json).

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
writes or publication. [Scope and limits](docs/INFO_ALL_STATS.md).

Next: native reload outside combat; pin damage/healing/AP/primary/weapon stats,
close the panel and trigger/expire procs. Verify combined/compact placements,
current native visible totals and explicit hidden-custom unavailability. Record
actual build/errors/taint and native performance separately; leave WoW background.
Desktop command: `lua tests/info_all_stats.lua`.

8 November cooldown acceptance audit: full current checkout261 scripts/928 Lua
PASS; complete normalized source manifest matches. This supersedes the previous
unrelated verification drift while preserving the newer stat files. All four
accepted images re-inspected; implementation remains unchanged. Completion is
not established: native saved settings/geometry, second reload/custom-save,
class-resource cases and other available clients still need matching evidence.
Forever was verified active/foreground; reload and settings probes refused before
input. Read-only screenshot confirms ongoing play, without changing focus. No
runtime/settings/profiler changes or publication. Keep the full goal active.
[Requirement audit](docs/validation/cooldown-final-audit-2026-11-08.json).

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
[Evidence](docs/COOLDOWN_VIEWER_DEFAULTS.md).
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
clipboard control, gameplay, commit or push. [Evidence](docs/OBJECTIVE_TRACKER_TOP.md).

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
change, native preset patch, commit or push. [Requirements/evidence](docs/COOLDOWN_VIEWER_DEFAULTS.md).

8 November current goal: Edit Mode ownership batch implemented;295 focused/
full259 scripts/924 syntax PASS, no Lua drift;20 installed copies match. User
reports successful Forever save/viewer without new errors. Saved edit snapshots
absent; exact loaded build/source/full taint and other clients/combat/pixels remain
pending. Reproduce with lua tests/edit_mode_native_ownership.lua and
lua tests/perf_spike_watch.lua. [Evidence](docs/EDIT_MODE_NATIVE.md).

Active goal also adds four screenshot cooldown defaults above player/class power.
User explicitly preserves custom Edit Mode layouts; only untouched layouts may
receive defaults. [Requirements](docs/COOLDOWN_VIEWER_DEFAULTS.md).
Copy implementation now exists. C_EditMode.SaveLayouts fires synchronous updates;
do not assume addon-triggered native refresh is taint-safe, call native Lua setters
or mutate private maps. Viewer TOC allows standard/camelot. Public-save metadata passed on Forever70862; complete final single-profile native
acceptance without touching native Lua setters. Keep WoW background.

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
exposed APIs and must not be marked complete. [Evidence](docs/COMBAT_NUMERIC_TINT.md).
Do not retry private-child color reads, cached/guessed types, fake widget types or
privileged callback routing. No runtime fix or all-client combat text parity was
accepted. Revisit only with a supported font-color binding or new client evidence.

8 November universal mouseover (UNIVERSAL-MOUSEOVER-20261108): implementation
and desktop validation complete on main; native acceptance pending. Read
[scope/tests](docs/UNIVERSAL_MOUSEOVER.md). Native Forever capture found the game
foreground, so no commands or reload were sent. Keep WoW background; let the user
perform actual casts. Outside combat reload and check helpful/harmful items and
spells with valid/incompatible/absent mouseover, DEFAULT/TARGET, explicit Focus/
Self/cursor, native held/unheld modifier, stopcasting, free chords, multi-cast,
form/rank, wheel/unit-frame keys, badges and combat transitions. Plain native
actions react to the live CVar; compiled changes defer to combat end. Repeat on
all five installed clients, collect fresh errors and matched screenshots, record
actual GetBuildInfo/addons/profile and restore any optional diagnostics.
Reproduce: `lua tests/universal_mouseover_priority.lua`,
`lua tests/mouseover_native.lua`, `lua tests/binding_roadmap_regression.lua`.
Full258/923 PASS; source guard has no drift;15 runtime copies match. Source/archive
identities are in docs/validation/universal-mouseover-comparison-2026-11-08.json.
No native performance or taint acceptance, commit or push claimed.

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
[Evidence](docs/GROUP_ROSTER_PERFORMANCE.md).
Next native acceptance: reload outside combat, then invite/join/leave/reorder
party and raid groups, with player-style party mode and raid-style party mode.
Include optional pets/target, combat join/leave/regroup, new member hover casts,
ready checks and real Edit Mode/binding edits. Verify group order/anchor/colors,
cast cleanup, no stale routing and actual invite latency. Record build/addon list,
errors/taint and matched native timing only with authorized profiling; preserve
profiler preferences and leave WoW in background. Desktop command:
`lua tests/group_roster_performance.lua`.

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
[Evidence](docs/validation/friendly-aura-policy-2026-11-08.json).
Next native acceptance: reload OOC. With display-only-dispellable OFF, a known
typed harmful effect should tint even when not dispellable by the player. With it
ON, that effect must stop tinting; player-dispellable effects still tint. Unknown
types never tint. Keep different types on player/target/focus and test same-token
swaps, hostility, party joins/leaves and combat. Verify normal text during secret
restrictions and native borders. No foreground game/input control. Focused command:
`lua tests/friendly_debuff_tint.lua`.

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
profiler, diagnostic-root writes or publication. [Contract](docs/INFO_COMBAT_STATS.md).

Next native check: reload outside combat; compare pinned Crit/Haste/Hit with the
native panel. Close it, enter combat, trigger/expire a stat proc, then leave combat.
Check ranged ammo and spell/offhand hit plus merged placements. Record actual
build/errors/taint; leave WoW in background. Desktop: `lua tests/info_combat_stats.lua`.

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
[Evidence](docs/validation/friendly-dispel-isolation-2026-11-08.json).
Next native acceptance: reload OOC; a typed effect you cannot dispel must not tint
any frame. Give player and another friendly unit different dispellable types;
switch target/focus repeatedly without aura changes. Each frame must show its own
current color, clearing on a non-dispellable/clean/hostile target. Toggle Blizzard
only-dispellable and Flux party choices, then repeat target/group swaps in combat.
Record actual build/taint/errors; leave WoW in background. Focused desktop command:
`lua tests/friendly_debuff_tint.lua`.

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
[Evidence](docs/validation/friendly-debuff-tint-2026-11-08.json).
Next native acceptance: reload OOC and compare known types on player, party and
friendly target/focus. Toggle Blizzard dispellable-only; ordinary debuffs must stop
highlighting immediately. Untyped debuffs leave normal chrome/text. Check removal,
hostile/pet transitions and portrait backdrop. Restricted Retail/Forever combat
should keep native borders with normal numeric text. Capture real build/errors/
taint; desktop checks do not certify native safety. Focused command:
`lua tests/friendly_debuff_tint.lua`.

8 November carried combat-consumable junk (JUNK-CARRIED-COMBAT-20261108):
implementation/owned desktop checks complete; native Junk preview/coin acceptance
next. Read [carried-tier contract](docs/CARRIED_COMBAT_CONSUMABLE_JUNK.md). After
normal OOC reload, keep only a lower potion/bandage with higher bank stock and
learned/affordable recipes: it stays useful. A finished carried upgrade permits
lower-tier junk; removing its last copy restores the remaining best tier. Check
Alchemy/FirstAid/Tailoring routes, provider on/off and explicit overrides. Do not
automate sales/focus. Command: `lua tests/combat_consumable_junk.lua` (1020PASS).
Final255scripts/920syntax PASS with unchanged source; newer independent debuff-
tint work retained. Owned hashes stable and12client copies matched.
No game/settings/profiler/publication operation. Preserve all newer local work.

8 November stable owned grid buttons (GRID-STABLE-OWNED-20261108): source fix
and desktop acceptance complete; native acceptance next. Read
[craft identity evidence](docs/CONSUMABLE_CRAFT_IDENTITY.md), then out of combat
reload normally and keep a positive potion/bandage stack while looting/crafting,
including last-material crafts and other-kind loot. Verify no transient placeholder
or hide/show, then true-zero Auto/Always/Off, better-tier promotion and combat gains.
Repeat with/without provider; record actual build/addon list/item/recipe IDs/errors.
Desktop command: `lua tests/consumable_craft_identity.lua`; full runner:
`python tests/run_validation.py`. Latest source-stable pass253/253scripts/917syntax;
all12client copies matched. No game input/settings/profiler changes or publication.

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
settings metadata entries retained. [Evidence](docs/validation/unit-combat-menus-2026-11-08.json).

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
[Case](docs/CONSUMABLE_BAG_VISIBILITY.md).

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
45 read-only settings metadata entries retained. [Evidence](docs/validation/party-blizzard-debuff-borders-2026-11-08.json).

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
settings metadata entries retained. [Evidence](docs/validation/party-debuff-borders-2026-11-08.json).

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
[Evidence](docs/validation/unit-name-party-cast-2026-11-07.json).

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
[Evidence](Stress%20test%20doc/roadmap-fixes/README.md).

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
[Evidence](docs/validation/vertical-target-health-2026-11-07.json).

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
[Evidence](docs/validation/focus-aura-packing-only-2026-11-07.json).

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
write, manual sync, branch or push. [Evidence](docs/validation/group-visibility-focus-row-restore-2026-11-07.json).

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
combat/FPS acceptance remains NOT RUN. [Evidence](docs/validation/consumable-tint-focus-aura-2026-11-07.json).

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
[Evidence](docs/validation/focus-aura-exact-width-2026-11-07.json).

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
[Evidence](docs/validation/focus-anchor-aura-fix-2026-11-07.json).

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
write, manual sync, branch or push. [Evidence](docs/validation/focus-party-presentation-2026-11-07.json).

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
[Evidence](docs/validation/unit-native-pvp-badge-2026-11-07.json).

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
sync, branch or push. [Evidence](docs/validation/party-native-pvp-badge-2026-11-07.json).

<!-- AUDIT-R2-20261107 -->
7 November second addon audit (AUDIT-R2-20261107): documentation/proposals only; no audit-issued runtime, existing-test, TOC, art, settings or profiler edits. Fresh main/source snapshot, four Gethe pins and current232-script/896-Lua pass retained.929 classified sources/599 loaded paths screened. 25 qualified groups:15 active-source behavior/contract reproductions,4 conditional models,2 API edges with ordinary reach unproved,3 work candidates and1 dormant helper. Prioritize punctuation pool-name collisions, cancelled gear work, and the conditional visible-salvage combat path; preserve all features and saved data. Explicit rapid Shift/Ctrl/Alt work includes over10million core state edges per run plus separate actual Binding/EBS/badge consumer matrices. Core bus settles in isolated storms; mixed mouseover can starve full display context; stale press ownership and actual combat index work remain recorded. Large fallback setter counts are an unsupported-paging countermodel, not ordinary repaired Forever. Independent Party/PvP source and fixture edits were preserved and revalidated by the current232/896 suite plus affected probe; initial snapshots remain. New fixes remain OPEN. Native taint/input/pixels/instances/CPU/FPS are not accepted by desktop results; previous USER-001 attribution/recurrence is still unknown. [Start here](Stress%20test%20doc/round-2/README.md). Continue in audit-only mode until the user authorizes another code phase.
<!-- /AUDIT-R2-20261107 -->

7 November clock calendar correction (MINIMAP-CLOCK-CALENDAR-20261107): user
clarifies calendar belongs on left-click of the displayed minimap time. Remove
the separate calendar icon, restore GameTimeFrame cleanup, and use runtime
ToggleCalendar availability for the existing clock click/tooltip. Right-click
TimeManager/stopwatch and native mail artwork remain. No new driver or resources.
720 focused checks PASS; prior source rejects. Full 232 scripts / 896 Lua syntax
PASS; post-suite hashes unchanged. Validation is recorded in
[the evidence](docs/validation/minimap-clock-calendar-2026-11-07.json). Direct UI choice
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
[Correction evidence](docs/validation/attribution-correction-2026-11-07.json).

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
[Evidence](docs/validation/minimap-native-indicators-2026-11-07.json).

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
[Fresh validation](docs/validation/github-publication-2026-11-07.json).

<!-- STRESS-FIXES-20261107 -->
7 November stress fixes (STRESS-FIXES-20261107): the user authorized implementation after the audit/proposal phase. Applied public fade ownership, secret-safe alpha/geometry handling, local Forever driver adapters, accurate/cancellable Respec completion, input invalidation, mutation-safe event delivery, retained FIFO scheduler work, bounded combat drains, raid/nameplate work reduction, hidden-watch suspension, bounded range freshness and auction retry churn. Settings, saved roots, commands, artwork and foreign library ownership are preserved. Combined desktop validation: 232/232 scripts and 896 Lua syntax files PASS; post-suite Lua hashes match. No game input, WTF/profiler writes, commit, push or manual cross-install copy was performed. USER-001 actual failing frame/first taint source, native taint, pixels and CPU/FPS remain pending. Visible character-button polling and coherent auction publication after quiet are intentional safety limits, not claimed eliminated costs. [Applied changes and remaining native checks](Stress%20test%20doc/applied-fixes/README.md). Load the changed code with a normal user-controlled reload before assessing recurrence; earlier in-memory taint is not cleared by editing files.
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
Documentation check is blocked by eight stale inventory/verification entries
from concurrent unit-frame/public-geometry source changes; no utility error was
reported. Preserve that work and refresh its global records when stable.
[Evidence](docs/validation/utility-chord-routing-2026-11-07.json).

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
branch or push. [Evidence](docs/validation/party-aura-portrait-layer-2026-11-07.json).
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
[Evidence](docs/validation/utility-native-actions-2026-11-07.json).

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
visual/FPS acceptance is pending. [Evidence](docs/validation/utility-ranked-spells-2026-11-07.json).

7 November utility item cooldown correction (UTL-CD-09): utility slots no longer
claim consumable buff durations as cooldowns. Clear already latched aura fields
before cooldown dispatch, including combat modifier release back to a spell.
The dedicated consumables button keeps its supplied aura countdown; existing
nonutility potion and food/water policy remains. No new timers, events, frames,
polling or protected action writes. Five paired desktop runs reproduce 30
baseline failures and pass 6894 candidate checks each; utility aura lookups
drop from five to zero per run. Full validation: 222 scripts and 885 Lua syntax
files PASS; post-run corpus unchanged. Native cooldown/input/combat/taint/visual/FPS
acceptance remains pending. [Evidence](docs/validation/utility-item-cooldown-2026-11-07.json).

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
[Evidence](docs/validation/utility-conditional-macro-key-2026-11-07.json).

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
branch or push. [Evidence](docs/validation/party-target-separator-2026-11-07.json).
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
[Evidence](docs/validation/party-divider-style-2026-11-07.json).

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
[Evidence](docs/validation/utility-modifier-vfx-2026-11-07.json).

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
branch or push. [Evidence](docs/validation/party-divider-edge-2026-11-07.json).
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
[Evidence](docs/validation/bank-direct-lifecycle-2026-11-07.json).

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
manual sync, branch or push. [Evidence](docs/validation/party-cast-cover-2026-11-07.json).

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
[Evidence](docs/validation/bank-native-attachment-2026-11-07.json).

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
branch or push. [Evidence](docs/validation/raid-marker-render-2026-11-07.json).
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
[Evidence](docs/validation/bank-restock-footer-2026-11-07.json).

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
[Evidence](docs/validation/cast-timer-sync-2026-11-07.json).

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
[Evidence](docs/validation/bank-restock-slot-2026-11-07.json).

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
manual sync, branch or push. [Evidence](docs/validation/party-player-layout-2026-11-07.json).

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
sync, branch or push. [Evidence](docs/validation/party-indicators-2026-11-07.json).

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
[Evidence](docs/validation/bank-restock-icon-2026-11-07.json).

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
[Evidence](docs/validation/utility-modifier-release-2026-11-07.json).

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
[Evidence](docs/validation/utility-secure-input-2026-11-07.json).

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
Meter work stays excluded. [Evidence](docs/validation/party-native-followup-2026-11-07.json).

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
[Evidence](docs/validation/utility-mixed-faces-2026-11-07.json).

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
[Evidence](docs/validation/unit-aura-minute-split-2026-11-07.json).

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
[Evidence](docs/validation/meter-window-routes-2026-11-07.json).

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
[Evidence](docs/validation/meter-layout-current-2026-11-07.json).

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
[Evidence](docs/validation/raid-party-mode-2026-11-07.json).

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
[Evidence](docs/validation/meter-native-controls-2026-11-07.json).

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
[Evidence](docs/validation/mouseover-native-2026-11-07.json).

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
[Evidence](docs/validation/raid-screenshot-defaults-2026-11-07.json).

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
[Evidence](docs/validation/meter-all-options-2026-11-07.json).

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

[Group-icon evidence](docs/validation/forever-talent-group-icon-2026-11-07.json).

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
[Evidence](docs/validation/raid-mt-opacity-2026-11-07.json).

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
[Spec evidence](docs/validation/unit-spec-talents-2026-11-07.json).

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
[Evidence](docs/validation/raid-mt-target-2026-11-07.json).

7 November unit indicators/spec: player/target/focus share a fitted grid above
health beside class/spec, including native enum master loot. User rejected moved
raid-group labels, shortened names and the health-inset prototype; final grid
reserves no name width and keeps name-relative group placement. ZZZ animates
beside the visible level with static fallback. Matching Respec profile overrides
live spec; No profile/nonmatching uses the most-invested committed tree on
Era/Anniversary/Forever, then active specialization where available. Fixed the
forward-local resolver and current namespace fields. User Forever loot dump
2,0,1 confirms master loot/ownership API; candidate visual acceptance pending.
Desktop evidence and native pending scope: [unit indicators](docs/UNIT_FRAME_INDICATORS.md).
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
[Evidence](docs/validation/status-currency-clicks-2026-11-07.json).

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
[Evidence](docs/validation/raid-manager-overlay-2026-11-07.json).

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
[Evidence](docs/validation/raid-live-width-guarded-2026-11-07.json).

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
[Evidence](docs/validation/raid-timer-policy-2026-11-07.json).

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
[Evidence](docs/validation/raid-preview-parity-2026-11-07.json).

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
[Evidence](docs/validation/raid-aura-width-font-2026-11-07.json).

7 November aura-only scaling: user explicitly chose to resize only auras,
keeping frame size fixed and permitting larger blocks outside the frame.
Removed the hidden inside-fit cap from actual geometry and the slider;
0.50..2.50 now applies directly, with Blizzard 11px/16.5px at 1.00.
Counts, filters, opacity, swipes, fitted fonts and combat deferral remain.
206 scripts/868 Lua syntax PASS with unchanged sources;
five fresh alternating baseline/candidate pairs reject the old cap. Eight
other-client files already match; no duplicate copy performed. No recurring
resources added. New native visual/combat checks remain pending.
[RAID-AURA-INDEPENDENT-SCALE-20261107](docs/validation/raid-aura-independent-scale-2026-11-07.json).

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
[Native-size record](docs/validation/raid-blizzard-default-sizing-2026-11-07.json).

Class travel/restock: spell reagents, including runes and native spellbook
flyout children, route to Preset through the existing index/store. Saved quantities,
bank flags and ordinary Manual rows remain. Single-destination right-click edits
its reagent target; free/Soul Shard-only costs gain no automatic target. The
existing Core.Spell adapter supports C_Flyout tables alongside legacy APIs.
130 travel + 47 scanner/list/facade checks pass; 16 faulty mutations rejected.
Scoped replay passes all six required scripts with unchanged reagent sources.
The last whole-addon run passed 200 of 204 scripts and all 866 syntax files;
four raid-test failures and unrelated source drift prevent a whole-tree PASS.
All four runtime files match the four existing client copies (16 hashes). A
manual-copy verification stopped during active continuous sync; three later
read passes confirmed every candidate, with external destination backups.
Documentation validation also remains blocked by concurrent raid edits: one stale source-inventory entry and three verification hashes. The checker made no edits; reagent source/test hashes remain matched.
Native UI/vendor/secure checks remain pending: the busy auction/craft baseline
had no visible FX marker. Close those windows and leave combat before reload;
verify Preset quantities, right-click Enter/Escape/zero, both modes/modifiers,
known flyout children and multi-destination flyouts. No automated purchases/casts
or foreground/mouse/keyboard/clipboard control.
Commands: `lua tests/teleport_restock.lua`; `lua tests/spell_reagent_presets.lua`;
`lua tests/teleport_cast_work.lua`. Preserve unrelated local main work/settings.
[Case](docs/TELEPORT_REAGENT_RESTOCK.md).

7 November final user check: after reload the user confirmed, Yes, height and
normal auras work, for the taller frames and normal aura/duration-text slider.
All five client folders match the tested feature files;20 destination hashes
verified. This task performed no second overwrite because those exact candidates
were already installed. Other-client native execution, combat/taint and FPS
remain pending; this is visual/function acceptance in the selected test client.
[Native acceptance](docs/validation/raid-aura-slider-live-2026-11-07.json).

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
[Live slider record](docs/validation/raid-aura-slider-live-2026-11-07.json).

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
[Size/count record](docs/validation/raid-aura-limits-2026-11-07.json).

Current batch: safe cooldown-only badge visibility +unused power snapshot
cleanup. Final199 scripts/861 syntax PASS; unchanged source;150 new checks/
10 rejected mutants. Five changed runtime files match all four existing client
copies after external backups. Main and unrelated work preserved; no push.
Earlier identity fixes were live in Forever with profile0 and three sampled
BugTabs counts0. TacoTip unloaded; Syndicator/Baganator loaded at that capture.
Current batch is now loaded in Forever: user reloaded and fought; native cleanup
marker=nil and BugTabs0 afterward. Direct restricted badge/swap cases; matched
pixels/FPS and other-client checks remain pending. Use original strict background helper only; an app-switch variant was
auto-review rejected and not executed. Never send foreground/physical input.
Next native checks: modern cooldown adapter public metadata forwarding and
cooldown-only badges through non-GCD/GCD/ready transitions; main/mini and badge
swaps. Sample BugTabs before/after; no new reload is required without changes.
Commands: `lua tests/badge_cooldown_secrets.lua`, `lua tests/power_snapshot_cleanup.lua`;
full `python tests/run_validation.py --output docs/validation/<new-id>.json`.
Optional spike watch remains unarmed/unverified; never assume it is active.
Do not automate combat or user transactions. Inspect any new error's actual
session/timestamp; earlier0samples do not certify later code or random lag.
Then handle pet-name/family fallback and cast/overlay guarded arithmetic as
separate proven batches; preserve features and avoid guessing secret state.
Potential unmatched-state health maximum label incompleteness was observed;
formatter/update/creation bodies match HEAD. Check native formatting/geometry
with a matched combat state before attributing it to this batch or editing it.
[Case](docs/UNIT_STATE_SECRETS.md#follow-up-badges-and-unused-power-snapshots).

Latest unit-state batch is tested/synced, awaiting native reload. Five files:
Core/API/Name.lua; Bars/ProgramFace.lua; UnitFrames/FluxHealthLossOverlay.lua;
UnitFrames/FluxPowerCostOverlay.lua; UnitFrames/FluxUnitFrames_Shared.lua.
Final197 scripts/859 syntax PASS; unchanged corpus.344 focused checks/23 mutants.
All four existing client copies match after external backups. Forever background
reload was blocked before input because WoW was active; do not weaken guard.
Outside combat run `/reload`, then target-cycle/mouse-select/focus/child-target,
cast/channel and pet-swap checks; inspect new-session BugTabs for the old four
paths. Preserve errors and profiler preferences; do not assume a spike watch runs.
Native secret VM, taint, feedback pixels and performance remain pending. TacoTip
is unloaded per user and must stay read-only. Automatic native Current remains
blocked by user choice. Preserve all unrelated main work; no commit/push yet.
[Case](docs/UNIT_STATE_SECRETS.md), [native status](docs/validation/unit-state-secret-native-2026-11-06.json).

Latest user error:22:42:30 TacoTip-tainted secret width in native Backdrop.lua.
Source matches installed Forever TacoTip0.9.4's owned BackdropTemplate overlay;
exact native frame/client remains unverified. The user chose to keep TacoTip
read-only and later reported it unloaded. No TacoTip edits are planned.
Do not patch global Backdrop/native tooltip methods or silently disable borders.
No runtime changes from this audit. [Finding](docs/TACOTIP_BACKDROP.md).

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

[Text scaling record](docs/validation/raid-aura-text-scale-2026-11-06.json).

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

[Clock correction record](docs/validation/raid-aura-clock-fix-2026-11-06.json).

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

[Duration record](docs/validation/raid-aura-duration-2026-11-06.json).

Continue the random-spike investigation. The user has been asked to run
`/fluxperf watch 600 200`; await “watch started” before assuming it is active.
Play normally, preserve its metadata and do no profiler changes. After a gap
or expiry, outside combat run `/fluxperf watch off` and `/reload` to save.
Read FluxPerfCaptureDB.spikeWatch using the existing safe literal parser;
retain all prior reports privately. Compare exact source/client/scenario and
small-callback/heap context; nearest profiler ticks do not establish causality.

Completed map candidate: owned-provider detach cleanup, native mixin/AcquirePin
overrides removed, restricted owned pin acquisition uses the existing Combat
service. Provider SHA256:
3aac4df59ece5b96dde666c2a6f03fa34b211c44eea97ecdbda948ea2bf63578.
193 scripts /855 Lua syntax files PASS, frozen corpus
fd41765411f9201d3a49645b88580fed2745b41986af8e0547b99c1283daa1cd.
All four existing client copies match after external backups. Forever reload
was observed; user confirmed `FXMAP true true 0` with Map visible. This accepts
two provenance fields and sampled errors only, not native FPS/pixels/leaks,
full combat recovery or other clients. [Case](docs/MAP_PROVIDER_LIFECYCLE.md).

Remaining independent leads: owned quest-area/focus hooks may queue work after
detach; read lifecycle before editing. Later4 native QuickJoinToastButton
protected-anchor errors occurred outside the stopped watch and are unattributed.
Do not resume unsafe automatic Blizzard Current selection; preserve native
features as the user requested. Do not use native debug.getinfo.

Keep all current local main work and unrelated raid/binding/glow changes.
No lag/map commit or push yet. Respect background-only input; verify host PID,
window and current context before any command. The old handles are stale:
latest verified Forever PID24848/HWND133690, which must be checked again.
See docs/WORK_LOG.md for historical pause/resume and checkpoint evidence.

Forever badge native behavior accepted for the tested Missile Barrage setup:
after `/reload`, the user confirmed modern glow following bar↔badge both ways
and clearing at proc end. The user also confirmed badge icon/count/cooldown
following an action main↔mini in combat. The earlier main↔mini proc glow was
already confirmed. If revisiting, check other SAO procs, other clients,
Lua/taint errors, pixel parity and matched frame time separately; these were
not established by this visual test.
[Case](docs/FOREVER_SAO_GLOW.md#badge-handoff-and-combat-row-icon-follow-up-current).

Forever SAO paging/badge handoff native acceptance pending: after `/reload`,
trigger Missile Barrage in combat, hold/release the modifier that swaps Arcane
Missiles between main and mini rows, and check that only the displayed face
glows. Repeat for a configured reverse badge/action-bar swap and when the proc
ends. Capture build, visual result, Lua/taint errors and frame time. If a face
does not follow, read `/run print(FluxEffectGlow.Diagnostics())`; the secure
suffix is ready/failed/alpha-failed. Native combat-start was confirmed in the
preceding user test; handoff and clearing were not.
[Case](docs/FOREVER_SAO_GLOW.md#mainmini-and-badge-handoff-follow-up-newest).

Forever SAO secure proc glow native check pending: after `/reload`, trigger
Missile Barrage with Arcane Missiles on a Flux action bar and Extra Button/
badge. Confirm the Retail flipbook appears during combat and stops when the
proc ends, including repeated procs and an OOC action change. If it fails,
record `/run print(FluxEffectGlow.Diagnostics())`; the new suffix
`secure=ready/failed` distinguishes setup failure from secure rendering.
Capture build, Lua/taint errors, visuals and frame-time before acceptance.
[Case](docs/FOREVER_SAO_GLOW.md#secure-auracontainer-button-animation-candidate-latest).

Consumable aura follow-up native acceptance pending: after `/reload`, on Retail
and Forever first, consume configured Well Fed food, a flask/elixir, and a
weapon enchant with a later eligible item. Confirm icon and secure click change
on the buff/enchant event, then final-item all-buffed state, combat exit and
refresh threshold. Capture client build, item/aura IDs, any Lua errors and
actual latency. Repeat on other supported clients before parity claims.
[Case](docs/CONSUMABLE_REFRESH_TIMER.md#aura-and-weapon-enchant-follow-up--6-november-2026).

Consumable aura advance native check pending: on Retail, Forever and other
available clients, consume configured Well Fed food with another item after it
and confirm the button changes on aura gain. Repeat for a weapon enchant,
combat exit, and reload. Capture build, aura/item IDs, errors, secure click,
and actual latency before native acceptance.
[Case](docs/CONSUMABLE_REFRESH_TIMER.md#immediate-advance-after-aura-gain--6-november-2026).

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

[Exact follow-up source/check record](docs/validation/raid-blizzard-aura-followup-2026-11-06.json).

Consumable Well Fed native check pending: on Retail, Forever and other
available clients, test real configured food above/at/below its refresh
threshold in the button and config, then reload and check combat behavior.
Capture food/aura IDs, client build and errors. Desktop fixture passes 35
timer checks and 30 weapon-target checks; these do not prove native parity.
[Case](docs/CONSUMABLE_REFRESH_TIMER.md#well-fed-follow-up--6-november-2026).

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
[Requirements and limits](docs/RAID_HEALKIT_REWORK.md), [exact source/check record](docs/validation/raid-healkit-rework-2026-11-06.json).

Next native acceptance: reload this exact source, verify connected borders and
the manager at the second reference image's invariant Y, then test actual Flux
casts, dispel-only six slots, aura transparency/timers and self/other combat
joins/leaves/subgroup moves. Preserve diagnostic roots and profiler preferences.
Do not mark native success from the desktop/source suites. Earlier continuity
below retains its own source stages; preserve unrelated glow/meter work.

Forever glow priority: the latest candidate directly paints action bars and
Extra Buttons on SAO's screen/button callbacks in combat and uses pre-acquired
Retail proc art when available. The user has been asked to `/reload` and test
Missile Barrage combat show and proc clear. If it fails, request the single
in-combat `/run print(FluxEffectGlow.Diagnostics())` line; its counters separate
missing SAO signal, bar match, and modern frame draw. Earlier Classic candidate
failed live after reload. See [full record](docs/FOREVER_SAO_GLOW.md).

Latest signal evidence: `screen=0/0 notify=128 modern=158/0/0 failed=0
classic=0` during visible Missile Barrage. The new candidate samples SAO's
global screen-frame list on UNIT_AURA and next frame, and reveals the retained
Retail glow by alpha/animation without combat Show. If live test fails, get
the new diagnostic line including `aura` and `frame` counters.

The user did retest: still post-combat-only; `aura=7/1 frame=334` but
`modernShow=0`. Await live `/run` read of SAO overlay keys, Want(5143), and
Bars.Effects counters before further code changes.

The read returned `want5143=0` and an empty SAO overlay list. The latest
candidate observes Forever native screen overlay show/hide events (which the
installed SAO addon also registers) and fixes an empty SAO-list override.
Await fresh `/reload` Missile Barrage show/clear and diagnostics including
`native=` event counts/last ID if it still fails.

Native-event retest and private SAO AuraContainer lookup both failed;
`container=0/0/0`. Latest candidate finds the static 400589 filter through
Blizzard's global AuraContainer slot registry and hooks mapped AuraButtons
OOC. Await reload/combat acceptance; if dark, read `container=` hook/show/hide
counts and `modern=` show count.

Forever action bar button glow: the user confirmed SAO's Missile Barrage
screen overlay appears in combat while Flux buttons remain dark. The new
candidate follows SAO's private-table screen show/hide for that missing button association,
accepts unreadable combat icon state for a known spell ID, and retains the
Classic Era LibButtonGlow art and generic SAO/native paths. The user retested
the prior global-hook candidate and saw glow only after combat; SAO's cached
private-table method missed that hook, and standalone EBS lacked a glow-change
subscription. The corrected candidate has focused glow 46 and EBS refresh 8
checks passing. The user retested it and still saw glow only after combat;
the glow then stayed after the proc. The newest candidate adds global low-level
SAO screen show/termination hooks independent of private capture and checks
SAO's live overlay/fade state. Focused glow 48, low-level signal 5 and EBS
refresh 8 checks pass. The user retested that candidate and combat glow was
still absent. Flux now prepares and retains the Classic LBG frame OOC on each
secure button, then plays existing animations in combat; focused glow 53 checks
pass. Combined desktop suite 164 scripts/821 Lua syntax.
After a normal background reload, verify Missile Barrage plus a
second SAO-supported proc on action bars, Extra Buttons and badges in combat;
check show/hide, matching art, paging, secure input, taint and frame time. Keep
WoW in the background and preserve profiler/settings/diagnostic roots. See
[combat record](docs/FOREVER_SAO_GLOW.md#combat-button-glow-correction).

Forever glow follow-up: the user confirmed the earlier renderer-only fix did
not show a glow. The installed SAO Forever Missile Barrage effect omits the
Arcane Missiles button association; Flux now checks aura 400589 for that spell
and its ranks, with changed-state `UNIT_AURA` refresh and secret native guards.
Generic SAO/native support still covers other registered button glows. Focused
41-check fixture and 162-script/819-file desktop suite pass, but native behavior
is unverified. With Forever running in the background, reload once and trigger
Missile Barrage plus another SAO-supported button proc on bar, Extra Button and
badge; check show/hide, art, paging, icon changes, taint and frame time. Then
check Era/Anniversary separately. Keep settings and diagnostic roots intact.
[Evidence](docs/FOREVER_SAO_GLOW.md).

Current meter scope is accepted: preserve every native feature and leave
automatic Current blocked. METER-DEFAULT-CURRENT-01 remains OPEN; freeze its
implementation. Do not add a custom renderer, native/private writer, reset,
automatic setting or manual-setup completion. Reopen only with new user direction
and supported evidence. Keep native controls, sessions/history and current UI.
[Decision and limits](docs/METER_STANDALONE.md#automatic-current-requirement-and-supported-api-gap).

Successful user inventory returned all eight documented DamageMeter methods
and only enable/show-UI plus new-instance-reset CVars (`FXCV DONE`). The original
nil-help concatenation diagnostic was corrected and retested successfully; its
12:27:14 RunScript error is separate from native 11:45:22/11:45:26 taint errors.
Do not rerun the broken macro or infer clean native state from the inventory.
No explicit loaded-source fingerprint or clean-error/combat acceptance followed
the reload request. Native cleanup remains pending. The 30-second background
attempt at 11:25:15 UTC was refused before any posted message/typed character.
Keep background guards and preferences; do not take foreground control.

Independent header/Threat, native combat/secret/taint, pixel and performance
checks remain pending at their recorded scopes. No runtime change in this batch;
preserve concurrent glow work and diagnostic roots. Earlier desktop passes are
source-specific evidence, not a native cleanup or automatic-Current success.

Historical meter links: [METER_STANDALONE.md#installed-wow-interface-art-references](docs/METER_STANDALONE.md#installed-wow-interface-art-references), [meter-theme-consistency-2026-11-05.json](docs/validation/meter-theme-consistency-2026-11-05.json), [METER_STANDALONE.md#one-line-names-and-shared-meter-appearance](docs/METER_STANDALONE.md#one-line-names-and-shared-meter-appearance), [native-meter-background-checks-2026-11-05.json](docs/validation/native-meter-background-checks-2026-11-05.json), [METER_STANDALONE.md](docs/METER_STANDALONE.md), [meter-standalone-2026-11-05.json](docs/validation/meter-standalone-2026-11-05.json), [METER_COMBAT_VISIBILITY.md](docs/METER_COMBAT_VISIBILITY.md), [meter-combat-visibility-2026-11-05.json](docs/validation/meter-combat-visibility-2026-11-05.json).

Forever SAO priority: after a normal background reload, trigger real
SpellActivationOverlay 2.8.9 procs on the action bar, Extra Button and badge;
check LibButtonGlow art, hide, SHIFT/CTRL paging, macro/icon changes, taint and
frame time. Then verify Era/Anniversary glow regression separately. Source fix
and focused desktop checks are recorded in [FOREVER_SAO_GLOW](docs/FOREVER_SAO_GLOW.md).
The current combined full suite passes 162/162 scripts and 819/819 Lua syntax
files; the earlier SAO-stage meter assertion failures are resolved.
Preserve current WoW settings, profiler and diagnostic roots.

Raid-frame priority: after a normal reload, reproduce party/raid and Edit Mode
hide/restore with Flux raid frames enabled and disabled. Check BugTabs for the
07:08:57 secret mouse comparison and any new taint, then verify native/Flux
click, hover and wheel hit testing, combat roster changes and group ordering.
The 6 November `Hide.lua` fix is desktop-validated only; initially secret native
switches are left untouched to preserve their unknown policy. See
[the raid input record](docs/49-native-mouse-suppression.md#raid-secret-mouse-follow-up).
Keep WoW background, profiler preferences and diagnostic roots intact.

Wand swing theme native follow-up: [record](docs/SWING_WAND_CAST_THEME.md).
Era, Anniversary and Forever desktop models pass 13,942 focused checks; the
full suite passes, but Fire/Frost wand pixels, cast-slot handoff, combat taint,
localization and frame time are pending on real clients. Verify exact loaded
source/build, keep WoW in the background and preserve existing settings and
profiler preferences. Test each client sequentially because sessions displace
one another. Keep the separate meter and threat work below in scope.

Priority: load and accept the minimap mail lifecycle fix. Read
[the lifecycle record](docs/MINIMAP_MAIL_LIFECYCLE.md) and
[Retail tooltip readiness](docs/AUCTION_COLD_TOOLTIP.md). Baseline `c1a5f90`;
external Mail-auction-publication-20261105T194013Z preserves 1,529 actual files,
122 settings and all-ref history, source SHA256
`a6fb41fd4042442bd9d9c6d5c70320fe9001feadd068312e3b328d0dfb694449`.
Combined validation passes 153 scripts / 808 Lua syntax files with an unchanged
808-file source drift guard.
[Full report](docs/validation/minimap-mail-lifecycle-2026-11-05.json). Reproduce with
`lua tests/minimap_mail_lifecycle.lua` and `lua tests/auction_cold_tooltip.lua`.
Minimap 504 checks, five alternating pairs and five mutants pass; tooltip 48 checks,
five pairs and four mutants pass. Raw comparison reports accompany the full run.

A normal reload after source sync is required: retained WoW frames/listeners
from the old lookup survive disk edits. Leave WoW in the background while the
user uses the PC; no new foreground permission is inferred from old checks.
Read-only checks around 19:45 UTC found both runtime candidates already identical
in all five client folders and Forever PID39984 still running; no reload occurred.
Verify loaded file identity and build before measuring. Separately check mailbox
open/close, item/money loot, second-last/final Open All, Buy-to-mail, cancel,
post and buyer-sale bursts, minimap mail visibility/tooltip and normal/embedded
geometry. Repeat on every installed client with/without external Syndicator and
Baganator where available. Match resolution, scale, profile and game state.
Preserve profile0, settings and BugTabs history. Native freeze/flicker removal,
CPU, memory bytes, frame times, pixels and taint remain pending. The earlier
19:15 Forever reload predates these fixes. External Syndicator's private proposal
is deferred and uninstalled; do not apply it without authorization or discard
known inventory facts. Guild-bank and void callbacks remain excluded.

Provider row-reuse slice: read
[scope and exact identities](docs/PROVIDER_SNAPSHOT_ROW_REUSE.md). Preserve newer
consumable work through `e2c6464`, and external recovery
Mail-auction-publication-20261105T183839Z (1,520 files, 122 settings, all-ref history;
source SHA256 `b3a39827bbd2e50cc271fce7c5930ea80b1174e3215bc42105b380d36523f55f`).
Focused 700 checks, five alternating pairs and five mutants pass; full 151 scripts
/ 806 syntax files pass with the whole-source drift guard unchanged. Reports:
`docs/validation/provider-snapshot-row-reuse-comparison-2026-11-05.json` and
`docs/validation/provider-snapshot-row-reuse-2026-11-05.json`.
Reproduce with `lua tests/provider_snapshot_row_reuse.lua`.

Native acceptance for the new adapter is entirely pending: the approved 19:15
Forever reload and later source Syndicator/profile0/all-three-loaded checks
precede this slice and observed empty caches, not transaction performance.
The logger error confirmed at 19:18:25 came from the wrong diagnostic API probe;
preserve it and do not classify it as a runtime regression. Verify loaded candidate
identity before any later authorized Buy-to-mail, sale/cancel, collection and
10/100/500-operation curves. Keep all real facts; source visits still grow with
full-list validation and temporary maps remain. Do not claim progressive lag is
fully fixed. Keep WoW in the background, settings and profile0 unchanged.
The separate private Syndicator patch is under review outside Git; installed
references remain unmodified. Applying it requires explicit authorization under
the read-only reference rule. Guild-bank/void callbacks remain excluded.

Consumables timer native follow-up: on Retail, Forever, Era, Anniversary,
and supported progression, verify a buff shows `remaining − threshold` on
the main button, wisp lock, and config cell, and the buff timer clears at
the threshold while normal item cooldowns still display. Check a live
threshold change, reload, combat, secret aura, and pixels. Desktop 150/805
passes; see docs/CONSUMABLE_REFRESH_TIMER.md.

Earlier combined Lua source matched all 804 hashes in
`docs/validation/restock-charge-bank-iterator-2026-11-05.json` (149 passes).
Preserve the newer consumable commits through main `2c0e7b8`; they arrived during
this audit. Recovery Mail-auction-publication-20261105T183217Z covers all 1,519
actual files, 122 on-disk settings and full history, including uncommitted work;
source SHA256 `eb8e2855cc54ad55cfa43a670b4b4d1957f0ffa6c3d6c424c8dbef3ba10d3557`.
Original snapshot comparison and 147/802 source report retain their own identities.

Consumables config native follow-up: reopen with a charged item while the
bank is open and closed on Retail and Forever, then on Era, Anniversary, and
supported progression clients. Confirm the nil iterator error is gone,
configured icons remain visible, charge maxima/counts are correct, and weapon
target, secure click, combat, and layout behavior hold. Shared desktop fix
passes 149/804; see docs/RESTOCK_CHARGE_BANK_ITERATOR.md.

Consumables config follow-up: on Retail and Forever, verify configured icons
remain visible after adding an uncached item and reloading, including a
staff-only enchant while a dagger/sword is equipped. Repeat preset switching,
tooltip, secure click, error and layout checks across supported clients. The
shared source desktop fix passes five paired fixtures and full 148/803 suite;
native evidence is pending. See docs/CONSUMABLE_TARGET_DETECTION.md.

Latest steering: each Buy or Cancel makes the next operation slower. Continue
the progressive-cost audit after publishing this validated snapshot batch.
Capture 10/100/500-operation curves for retained pending mail, source reads,
copied rows, frames, callbacks, timers, hooks and error history with each provider.
The current snapshot changes do not establish that this growth has been removed.
Preserve all real mail facts and check collection cleanup rather than truncating.

Fresh native state: approved checks at 19:14–19:20 CET verified Forever70790,
FluxUI/Syndicator/Baganator loaded and source Syndicator; byte-matched files were
reloaded19:15:51 and profiler0/source marker20261105.1 confirmed afterward.
Provider mail/auction caches were empty; no transactions/performance test ran.
Use BugTabs1.4.9's public `BugTabs.sessionErrors`/own saved schema; BugGrabberDB
is nil in this session. An attempted BugGrabber method query generated one probe
error. Do not clear it or mistake it for an addon regression. Foreground checks
are finished; resume background work and preserve all preferences.

Desktop-validated continuation: Buy-to-mail is explicitly in scope. Baseline main
`437fda79136582282dde0f3989f3cb70c4411bad` is published; verified external
Mail-auction-publication-20261105T173546Z preserves 1,503 actual files, 122
on-disk settings files and all-ref history (source SHA256
`4921e61d4bce4f648bd95b428f7a0acea9eb11dfc99b0c66d1d5b32fd9a31f48`).
`Inventory/Builtin/Mail.lua` and `Auctions.lua` now prepare
completed index/count maps within their existing scan budget. Baseline desktop
replays prove an unbudgeted final fingerprint/copy/clear phase, including clearing
a large old attachment map when only two money messages remain. Keep the region
object, publish only complete generations, preserve original equality/cadence and
retain public Index APIs. The consumer audit found no cached inner mail/auction
index maps or public GetSnapshot exposure for these regions; internal map identity
changes are intentional and documented.
Tests `builtin_mail_publication.lua` and `builtin_auction_publication.lua` pass
baseline-rejecting replays. Auction replay is frozen at 5,884 passing checks; baseline fails
144 of 5,436 dynamic checks. Peak metered work 5,216→104, unchanged fingerprint
visits 10,240→0, getter-reentry errors 20→0; publications stay 20. Mail passes
8,194 checks versus baseline 25 failures in 8,203; peak arrival normalization
falls 1,600→46 constructors/update while retaining 1,600 total. Ten alternating
pairs, eight mutants and full 147 scripts / 802 syntax checks pass; all 802
normalized source hashes match. Reports:
`docs/validation/builtin-publication-comparison-2026-11-05.json` and
`docs/validation/builtin-publication-2026-11-05.json`.
Read [flow scope](docs/MAIL_AUCTION_REWORK.md),
[mail preparation](docs/BUILTIN_MAIL_PUBLICATION.md) and
[auction preparation](docs/BUILTIN_AUCTION_PUBLICATION.md). No connected native
test tool is available. Current native candidate identity, freeze removal and all-client
acceptance remain pending; leave WoW background and profiler0 untouched.
Read [external Syndicator finding](docs/EXTERNAL_SYNDICATOR_POSTING.md) separately:
the reference-only cold-post callback error does not explain an unloaded-provider
freeze. Do not patch or suppress external globals/errors.
Money-update cost inspection remains a separate read-only finding for a future
justified slice; no money-path runtime change is included here.

Earlier published runtime is `7a06b85f633d1945b7d6bf615636f486f3d7e627` (tree
`4e31f10131923c3d002faffe8036e631d1537402`), verified on GitHub main.
Publication-record updates are documentation only; the 800-file Lua manifest
still matches. Start with native loaded-source verification as described below.

Earlier lifecycle phase starts from published main
`e860ce6de499a7702b91e8a8d74f115fbc9e0293`. Read
[mail/auction flow scope](docs/MAIL_AUCTION_REWORK.md),
[query ownership](docs/AUCTION_QUERY_OWNERSHIP.md) and
[mail job lifecycle](docs/MAIL_JOB_LIFECYCLE.md). Preserve external checkpoint
Mail-auction-lifecycle-20261105T171132Z (1,496 files, 75 settings, verified history;
source SHA256 `38c16e1f0d1d928ffb6015a89ad10e78f991dc038d0d738f7d3483ace86a0e5e`).
Focused 628 auction / 880 mail checks pass; ten alternating pairs and eight mutants
are in `docs/validation/mail-auction-lifecycle-comparison-2026-11-05.json`.
Full validation passes 145 scripts / 800 Lua syntax files. Reproduce with
`lua tests/auction_query_ownership.lua` and `lua tests/mail_job_lifecycle.lua`;
the final full report is `docs/validation/mail-auction-lifecycle-2026-11-05.json`.

The freeze remains unresolved. Before native acceptance, establish actual loaded
source/client identity: the old PID47424 exited; later background inspection found
Forever PID25172 started at 17:55 CET. No native input, profiling or enable-flag
change was made in this batch. Keep WoW background, profile0 and flags unchanged.
Do not repeat heavy frame captures. Separate mailbox open/close, individual/final
Open All, post, sell, buy, cancel-to-mail and provider handoff; verify configured
cadence, last-mail cancellation and module/profile disable on each available
client/provider combination. Include Buy-to-mail delivery, later mailbox entry
and looting separately from immediate bag delivery. Native performance, taint
and pixels remain pending.
Guild-bank and void-storage callbacks remain excluded; ordinary main publication
is authorized without force push.

Earlier published phase `e860ce6`, based on
`b664bb0b93ac566a34744aec5895e927a7a1ffff`: three runtime fixes are published and
desktop-validated, not yet native-verified. Read [item data](docs/BUILTIN_ITEM_DATA.md),
[summary pruning](docs/INVENTORY_SUMMARY_PRUNING.md) and
[currency iteration](docs/GOLD_CURRENCY_ITERATION.md). Preserve external
Builtin-inventory-20261105T152153Z (1,488 files,75 settings, verified history;
source SHA256 `c2a7f2c073d38a90133cff6e5fc494164430338149ef65343ca61ab507ca537a`).
Final full validation passes143 scripts /798 syntax files; five alternating
pairs per scenario and12 mutants are in
`docs/validation/builtin-inventory-comparison-2026-11-05.json`.
Reproduce with `lua tests/item_data_request_coalescing.lua`,
`lua tests/inventory_summary_pruning.lua`, `lua tests/gold_currency_iteration.lua`
and `python tests/run_validation.py --output docs/validation/builtin-inventory-2026-11-05.json --sync-docs`.

Historical source/client identity investigation: the user
reports re-enabled FluxUI and continued whole-game freezes on sold auctions,
cancellation-to-mail, individual items and Open All's second-last/final step.
The only verified active Forever process PID47424 reported17:35 CET legacy/nil
source revision/profile0, then17:37 FluxUI false/Syndicator false and nil globals;
client1.60.1/build70790/interface16001. This contradicts the reported enabled
state; final `Inv.itemDataRevision='20261105.1'` has not been verified in game.
Keep addon flags unchanged until clarified, leave WoW in the background and
preserve profile0/diagnostic roots. The previous foreground was restored. Do not
repeat profiler1 or heavy EnumerateFrames capture. Native checks for all three
fixes and all client/provider combinations remain pending; do not infer a cure
or FPS from desktop counts. Guild-bank/void callbacks remain excluded.

Earlier published phase: the native mail-command guard prevents progression/completion
while C_Mail reports pending, with bounded8s wait and existing cadence retained.
Five matched desktop pairs reproduce360 to0 unsafe requests and40 to0 premature
completions; three mutants rejected. Final full validation:140 scripts /795 Lua
syntax files pass. Earlier139/794 evidence describes the preceding four-fix tree.
The user still reports live sale/mail freezes, including Open All at Processing
Message2 and final mail; no live cure is claimed.
[Guard, source contract and pending native checks](docs/MAIL_NATIVE_COMMAND.md).

Reproduce with `lua tests/mail_native_command.lua`; final full report:
`docs/validation/mail-native-command-2026-11-05.json`. Native source comparison:
`docs/NATIVE_MAIL_AUCTION_REFERENCE.md`. Do not repeat the failed heavy frame
capture; preserve profile0 and prior nil report. Prioritize narrow attribution of
mailbox/auction events and retain crash evidence before any optional profiler.

5 November raid/mail/auction follow-up: read
[current evidence and acceptance steps](docs/RAID_MAIL_AUCTION_FOLLOWUP.md) first.
Baseline `8681672`; preserve the external Raid-mail-followup-20261105T132922Z
checkpoint. Full validation passes 139 scripts / 794 Lua syntax files:
`python tests/run_validation.py --output docs/validation/raid-mail-auction-followup-2026-11-05.json --sync-docs`.
Focused reproduction commands: `lua tests/raid_header_precreation.lua`,
`lua tests/mail_loot_scheduling.lua`, `lua tests/mail_copy_availability.lua` and
`lua tests/auction_refresh_batching.lua`. Five alternating pairs and eight
rejected mutants are in the linked comparison report. Progressive auction
refresh batching is linear in the modeled burst; a single formatted sale was
already linear, so its live spike/error chain remains unresolved. UNKNOWN header
attribution and native pet-driver capability remain pending. Forever is running;
the earlier no-client inference came from sandbox-limited process visibility.
The user reports Syndicator is not loaded in the current failing setup. Installed
Syndicator 289 is reference material; investigate the built-in provider and fresh
error history independently. Reporter-only warnings occurred at 14:53:50,
15:03:09 and 15:27:44; the initiating error remains unknown.
Approved native reload completed15:32:54CET. Read-only commands confirmed
Forever1.60.1/build70790/interface16001, FluxUI loaded, Syndicator unloaded;
at15:35:48 raid setup ready, scriptProfile0, session23 with11 historical /0 current
errors. The user confirmed the same freeze after reload; it is not resolved.
The old error history was saved privately; reporter counter50 still lacks an
initiating fault. Initial focus checks safely refused input, but a later split
chat attempt activated shortcuts; use atomic verified chat input only during an
authorized brief exception. A subsequent optional60s CPU capture started15:42:20
after scriptProfile1/reload15:41:45. User-reported crash during many auction-mail
opens ended PID38964; replacement PID33872 started15:48:36. No new crash report
was found and capture data was lost before save: no benchmark. Restored0/reload
15:50:55; FLUXCLEANUP0 true false verified15:51:34, original capture root nil
preserved by literal-only comparison. Prior foreground was restored. No profiling
cleanup remains; the exception is complete and background-only operation resumes.
Do not repeat the heavy capture. Read
[native mail/auction comparison](docs/NATIVE_MAIL_AUCTION_REFERENCE.md), finish
the smallest native command-pending guard and its regression (currently pending),
then consider narrower diagnostics avoiding full EnumerateFrames. Keep the new
external native-command-baseline checkpoint from14:53:38UTC (1,484 source files,
verified settings ZIP);139/794 remains the preceding completed batch's result.
Reproduce mailbox open/close, text/invoice/loot and auction refresh/sales separately
on available clients and provider/bag combinations; do not infer FPS, taint or
pixel parity from desktop counts. Guild-bank/void callbacks remain excluded.

5 November meter/header error fix: read
[exact failures, source pins and pending native steps](docs/METER_RAID_NATIVE_OWNERSHIP.md).
`lua tests/native_meter_ownership.lua` passes 180 checks;
`lua tests/raid_header_precreation.lua` passes 150. Full desktop validation passes
136 scripts / 791 syntax files. Comparison/raw samples:
`docs/validation/meter-raid-ownership-comparison-2026-11-05.json`.
Native reload is required to discard old in-memory meter method replacements.
Verify Forever first (source line535 matches log), then Retail meter tab/resize/
selection/row colors/timer/gamepad and each client's secure party/raid/MTMA roster
growth, disable and combat recovery. The two UNKNOWN blocks have no identified
header or taint writer; do not claim the capacity fix proves their cause. Prebuilt
raid children rise to the intended bounded 80 in the raid fixture (startup/native
memory cost unmeasured). Preserve newer consumable work and keep WoW background;
no renewed capture request or foreground control. Guild-bank/void remain excluded.

5 November consumable target work: read
[contract/evidence](docs/CONSUMABLE_TARGET_DETECTION.md) before changing the
noncombat consumables button. `lua tests/consumable_weapon_targets.lua` passes
30 checks and the full desktop runner passes 134 scripts/789 syntax files.
Native Retail/Forever/Classic staff-only item, general oil, flask/elixir/food,
equipment-swap, combat, locale, secure-click, pixel, taint and matched frame
time checks are pending. Keep the existing external bundle/settings checkpoint
and prior hidden-inventory checkpoint; leave WoW in the background.

5 November hidden inventory changes validated for publication on main; see
[reproduction, source identities and native checklist](docs/HIDDEN_INVENTORY_WORK.md).
Run `lua tests/visible_baganator_work.lua` (260 checks) and
`lua tests/visible_native_bag_work.lua` (65 checks). Full validation:
`python tests/run_validation.py --output docs/validation/hidden-inventory-work-2026-11-05.json --sync-docs`;
final 133 scripts / 788 syntax pass. Native checks are pending, not failed or
certified. When captures become possible, prioritize Forever mailbox open/close,
receive/open-message and buy/sell with Baganator 840 + Syndicator 289, then each
available client/provider combination and reveal/skin/protection parity. The user
cannot capture now; leave WoW in the background and preserve preferences. The
skin registry still scans linearly; do not infer live hitch removal from the
400,800-to-800 synthetic callback reduction. Guild-bank/void callbacks stay out
of scope. Continue independent justified work if native access remains absent.

5 November Syndicator mail/auction snapshots: unchanged mail now compares
normalized records without sorted fingerprint strings; unchanged auction callbacks
retain records/count maps and skip FluxUI publication. Link-only mail metadata now
updates correctly. Five matched desktop pairs:500 sorts/500,000 string keys,
500,000 auction row replacements,500 maps and500 pulses become zero for the
synthetic unchanged burst.80 checks pass, three mutants rejected; full131 scripts/
786 syntax pass. Real changed lists still publish at the original cadence; native
Forever Baganator+Syndicator lag attribution/improvement remains pending.
[Evidence and next checks](docs/MAIL_AUCTION_GUARDS.md#snapshot-change-checks).

5 November mail/auction safeguard: user reports Forever lag with Baganator840
and Syndicator289 on mailbox open/close, auction buying and sales; cannot run
native captures and requested safeguards. Resolved owned item-data completions
now notify consumers once, preserving explicit refreshes, incomplete metadata and
parser retries. Five desktop pairs: stable duplicate burst4,000 junk callbacks,
8,000 selector invalidations and2,000 Baganator timer creates/cancels become zero.
140 checks pass, three mutants rejected; full130 scripts/785 syntax pass.
Actual lag attribution/native improvement remains unverified.
[Evidence and remaining checks](docs/MAIL_AUCTION_GUARDS.md).

5 November clarification: Forever retains Blizzard's ProfessionMicroButton.
Only FluxUI's custom trade-skill buttons, flyout and related options are disabled.
Removed the native-button exclusion/parking added in the preceding batch; the
normal discovery/configuration path restores it without a settings reset.
Adventure Guide remains hidden. Five matched desktop pairs: baseline2 failures
versus0 of54 checks; custom service startup frames remain unchanged (zero per
Forever model). Full129 scripts/784 syntax pass; native bar click/pixel/taint
acceptance remains pending after reload. [Evidence](docs/17-micromenu.md#forever-native-profession-button-restored---5-november-2026).

5 November Forever trade-skill micro removal: the module now exits before
creating buttons/flyout frames or registering scans/events on Forever. The native
ProfessionMicroButton is excluded and parked through the existing micro menu
policy; trade-skill option controls are omitted only there. Saved profession
preferences remain stored; other clients and native profession access stay.
Focused48 checks pass (baseline10 failures); five matched pairs remove4 startup
frames per Forever model, with no startup event/timer work. Full129 scripts/784
Lua syntax pass. Native menu/config/pixel/taint confirmation pending after reload.
[Evidence](docs/17-micromenu.md#forever-trade-skill-micro-removal---5-november-2026).

5 November Forever native bank and micro menu: at the user's request, Forever's
Blizzard bank is excluded from window movement, bank-frame latch scripts, bank
junk/item decoration and native restock-button attachment. Bank tracking remains
on existing BANKFRAME/PIM events; carried-bag and optional Baganator features stay.
The supplied PurchaseBankTab stack confirms a protected native first-tab path,
not the original taint writer. Guide button EJMicroButton is excluded only from
Forever's micro menu via the existing eligibility/parking paths. Focused checks:
168 native-bank and34 guide checks pass; baseline36/8 failures. Full129 scripts/
784 Lua syntax pass. Native bank opening/purchase/taint and guide pixels pending.
[Bank evidence](docs/FOREVER_NATIVE_BANK.md); [micro menu](docs/17-micromenu.md).

5 November Forever reputation click fix: the user confirmed the native
ToggleCharacter("ReputationFrame") call opens Reputation out of combat after
WoW's custom-script prompt. Both bars now call that API directly; the wrong
CharacterMicroButton overlays and Forever early return were removed for these
bars only. Combat guard, other client behavior, tooltips and other proxies remain.
Five desktop pairs: baseline18 failures versus0 of180 checks; full128 scripts/783
syntax pass. Final native bar clicks/taint/gamepad checks remain pending; no
/run macro or confirmation popup is introduced by the addon.
[Evidence and native checks](docs/FOREVER_REPUTATION_CLICK.md).

5 November auction opening regression: the user's Retail stack showed Update
running before the ScrollBox view exists. Both modern highlighting variants now
check GetView before iterating; later initialized updates still paint normally.
The real delegate contract reproduces20 baseline failures versus0 of156 candidate
checks across five client/two provider labels. Five matched pairs retain600 active
visits/200 classifications; no new timers/events. Full127/782 passes; native
reopening and the original Buy spike remain pending.
[Reproduction and evidence](docs/AUCTION_PURCHASE_REFRESH.md#view-initialization-regression).

5 November auction metadata: global cache events no longer harvest all bag/bank
names or populate classification records for unrelated auction items. Requested
metadata, failed-load retry, static consumers, explicit completions and immediate
name-only reagent/restock updates are preserved. Five matched desktop pairs:
280,000 name reads and 2,000 container walks become zero for the unrelated burst;
230 checks pass, three mutants rejected; full 127 scripts/782 syntax pass.
The native Buy spike still needs attribution/acceptance across both providers.
[Evidence and next captures](docs/AUCTION_METADATA_WORK.md).

5 November auction Buy investigation: active-row highlighting now uses the
ScrollBox view rather than enumerating its retained child pool. Five matched
production-module desktop replays: 200,600 versus 600 traversal visits, with
200 item classifications unchanged; 116 checks pass, two mutations rejected.
Full126 scripts/781 Lua syntax pass. Both provider labels exercise the shared
UI path; native provider integration and the reported Buy spike remain pending.
No game process or connected runtime tool was available; no foreground input.
[Evidence and exact next captures](docs/AUCTION_PURCHASE_REFRESH.md).

5 November utility pet faces: the user clarified a question-mark/wrong-icon
symptom. The manager now owns the selected journal-pet icon and tooltip via
existing override surfaces, with modifier changes, metadata completion and
cleanup. Summon macros/GUID storage remain intact. 920 checks pass (old40
failures), three mutants rejected; full125/780 passes. Native checks pending.
[Evidence and native steps](docs/UTILITY_PET_FACES.md).

5 November live-zero follow-up: exhausted food/water/potion/bandage buttons
now reset from reliable live bags before Syndicator's delayed cache callback.
The painter retains the verified count; loading holds and combat deferral
remain. Button-level375 checks pass (baseline200 failures), three mutations
rejected; full124 scripts/779 Lua syntax pass. Native acceptance pending.
[Evidence and native steps](docs/SYNDICATOR_CONSUMABLE_UPDATES.md).

5 November Syndicator consumables: batched bag callbacks now retain every
added/removed item and dirty bag until publication. This fixes a reproduced
missed selector update for better items and last-use depletion across food,
water, potions and bandages. Five desktop pairs: baseline 200 failures versus
candidate 0 per400 checks; three mutations rejected. Full suite123/778 passes.
Native gameplay, pixels, taint and performance remain pending.
[Evidence and exact native checks](docs/SYNDICATOR_CONSUMABLE_UPDATES.md).

4 November publication batch: all current local mail work included for main.
All 777 Lua files match the passing 122-test combined report. Native checks
and unfinished mail parity remain pending as recorded below.

4 November built-in mail: the user requires 1:1 Postal v4.3.4 controls and
settings. Read the [integration matrix](docs/MAIL_INTEGRATION.md). The current
controls match the inspected sizes/anchors, with separate fast opening and
bag reserve menus, but attachment forwarding, Express repeat send and advanced
BlackBook completion still need implementation. Native-check the menus,
buttons, recent-send persistence, selected take/return, C.O.D./full-bag guards,
category and Alt-left attachment, copy/invoices, subject, trade CVar restoration
and mailbox gain on Retail, Forever, Era, Anniversary and MoP. Leave clients
in the background and test sequentially. Preserve the All Rights Reserved
source boundary. Desktop suite: 122 scripts/777 Lua syntax pass; native pixels,
input, taint and matched performance pending.
The latest correction split main/Open All dropdown frames and fixed sparse
attachments/delayed item metadata; test these exact flows in each client.

4 November Classic combined bank: verify Era and Anniversary native banker
interaction, ten-column layout, six/seven bank bag slots, cursor drag/drop,
purchase confirmation/cost, item clicks, Baganator early/late ownership and
the bank restock button's click/drag/auto toggle. Desktop lifecycle models pass; native screenshots,
taint and matched performance are pending. Keep WoW in the background and
test named characters sequentially. [Evidence](docs/CLASSIC_COMBINED_BANK.md).

1 November 2026 GitHub publication: added a root README with a compact feature
overview covering the current inventory, links to all detailed feature controls,
client-specific availability, companion integrations, installation and command
entry points. The complete local payload includes the pending chat durability
loading-screen correction. Fresh combined desktop validation passes 113 scripts
and 758 Lua syntax files; native pending checks retain their recorded scope.

1 November trinket tint: on every client compare an equipped passive trinket
with a ready on-use trinket; then check unusable use spell, cooldown, dead/
revived state, tooltip, slot 13/14 clicks and bag flyout. Native pixels,
taint and frame time remain pending after 10 focused desktop checks.
[Evidence](docs/TRINKET_EQUIPPED_USABILITY.md).

31 October equipped trinket tint: sequentially verify ready equipped on-use
and passive trinkets, cooldown, dead/revive and bag flyout on all supported
clients. Check `/use 13|14`, keys, swap queue, gem/stone tint, pixels, taint
and matched frame time. Focused trinket and combat-grid desktop fixtures pass;
native acceptance remains pending.
[Evidence](docs/TRINKET_EQUIPPED_USABILITY.md).

31 October chat durability teleport follow-up: after reload, teleport through
a loading screen and confirm the character-button percentage remains visible
or returns when player equipment loads. Repeat with damaged/full gear, gear
swap and no readable durability; check clicks, text pixels, combat taint and
matched frame time on each client. Desktop timing/event fixture and full
112-test/757-Lua suite pass; native acceptance is pending.
[Evidence](docs/CHAT_CHARACTER_DURABILITY.md).

31 October secret-channel fallback: on Retail and Forever, test target/focus
and Blizzard nameplate casts in combat. Readable magic should keep school
colors; secret, item, physical and unidentified casts should keep default
appearance. Include channels, plate reuse, text/shield, combat taint, pixels
and matched frame time. Desktop 56-check nameplate regression passes;
native acceptance is pending. [Evidence](docs/SECRET_CHANNEL_FALLBACK.md).

31 October nameplate backdrop: sequentially check single/hybrid school casts
on Retail, Forever, Era and Anniversary at several plate sizes and during
target switching/reuse. Confirm artwork stays behind cast text, shield,
health text and selection chrome while fill/tip/halo/particles remain visible.
Check secret fallback, combat taint, pixels and matched frame time. Desktop
112-test/757-Lua suite passes; native acceptance remains pending.
[Evidence](docs/NAMEPLATE_BACKDROP_LAYER.md).

31 October chat character durability: sequentially check the native chat
button on each supported client with fully repaired, damaged and no readable
durability gear. Confirm `100%` is visible, lower values/color update on
inventory events, empty data hides text, and button clicks, pixels, combat
taint and frame time remain correct. Desktop 112 tests/757 syntax files pass;
native acceptance is pending. [Evidence](docs/CHAT_CHARACTER_DURABILITY.md).

31 October combat grid usability: sequentially check mana gem and healthstone
beside potion/bandage on every supported client while alive, dead/ghost and
revived; also at full health/mana, on cooldown, at zero/replenished charges and
during a zone-load bag hold. Confirm visual tint, counts, secure clicks,
hotkeys, combat taint and matched frame time. Desktop 111-test/756-Lua suite
passes; native acceptance is pending.
[Evidence](docs/COMBAT_GRID_CONJURED_USABILITY.md).

31 October cast fill/tip correction: sequentially verify actual target,
focus and Blizzard nameplate casts on every supported client. Check visible
school fill and matching moving-tip Spark for single/hybrid schools; finish,
interrupt, option toggle, plate reuse, Retail/Forever secret fallback and
combat `SetUnit` taint. Desktop 110-test/755-Lua suite passes; native pixels
and matched performance remain pending.
[Evidence](docs/CAST_SCHOOL_FILL_TIP_FIX.md).

31 October nameplate school themes: sequentially validate Retail, Forever,
Era and Anniversary native Blizzard cast bars in combat. Check target/focus
and nameplate school color/effect parity, finish/interrupt/reuse/toggle,
secret fallback, text/shield/important-cast visibility, `SetUnit` taint and
matched frame time. Desktop 110 tests/755 syntax files pass; native evidence
is pending. [Evidence](docs/NAMEPLATE_CASTBAR_SCHOOLS.md).

Latest publication batch (30 October): all local stance-scale, loot-source and
Micro Menu fixes included for main. All 753 Lua hashes match the passing
109-test combined report. Native acceptance remains pending.

MicroMenu nil-center correction (30 October): on the client that produced
the user's stack and then each supported client, reload with the Flux LFG
button enabled, open/close Edit Mode, change Micro Menu placement and verify
native buttons retain their order/visibility without a `GetEdgeButton`
error. Check combat deferral, pixels, taint and frame time. The user's stack
is pre-fix evidence; desktop 109-test/753-syntax suite passes, native
post-fix checks pending. [Evidence](docs/17-micromenu.md).

Delayed loot correction (30 October): sequentially on each supported client,
loot two mobs/chests at distinct cursor locations, move the cursor and delay
chat through LOOT_CLOSED/next source. Confirm each item remains at its own
source position and late slot/chat does not duplicate. Check fast pickup with
FasterLoot enabled and disabled, currency and money, UI scale, taint, pixels
and frame time. Ambiguous uncaptured/linkless sources require native review.
Desktop 108-script/752-syntax suite passes; native checks pending.
[Evidence](docs/LOOT_CURSOR.md).

Cursor-position correction (30 October): in each supported client, loot a
multi-item mob/chest, move the cursor before all chat/slot alerts arrive,
then loot another source while the first rows remain visible. Verify each
batch stays at its opening cursor position, delayed currency follows it,
and UI scale/clamping remain correct. Check native pixels, taint and frame
time. Desktop 108-script/752-syntax suite passes; native checks pending.
[Evidence](docs/LOOT_CURSOR.md).


Loot-source correction (30 October): on each supported client, create an
item, receive a quest/pushed item, loot a mob/chest, win a group or bonus
roll, and gain currency both through loot and a quest. Confirm only loot
appears at cursor, including chat after LOOT_CLOSED; check the one-second
currency grace, duplicates, taint and frame time. Desktop 108-script/
752-syntax suite passes; native checks remain pending.
[Evidence](docs/LOOT_CURSOR.md).


30 October 2026: attached stance bars now follow player-frame scale, including
immediate slider changes and reload; detached placement restores normal size.
Existing combat deferral is retained. 21 stance and 28 bridge checks pass;
full suite: 108 scripts /752 Lua syntax files, zero failures. Native pixels,
input and taint remain pending (no visible WoW process).
[Evidence and native steps](docs/UNIT_FRAME_SCALE.md).

Current publication batch (30 October): all local cursor loot, fast pickup,
options, coin art and callback updates are included for main. Native checks
retain their pending scope in the loot chapter.

FluxLoot callback correction (30 October): verify a real login/reload emits
no `RegisterCallback` event-name error, then change, copy and reset a profile
and confirm loot events follow the selected profile. Repeat on each supported
client when available in the background; preserve settings and profiler
preferences. The user's stack proves the old failure, while desktop fixture
and full suite pass after correction. [Evidence](docs/LOOT_CURSOR.md).


Cursor money alert follow-up (30 October): verify real received amounts on
all five supported clients: copper-only, exactly 1 silver, mixed silver and
copper, exactly 1 gold, and mixed gold/silver/copper. Check white numbers,
coin symbols, threshold-selected leading icon, localized chat variants,
3-second expiry, pixels, taint and frame time. Desktop checks pass; native
acceptance remains pending. [Evidence](docs/LOOT_CURSOR.md).


Cursor loot default follow-up (30 October): verify new profiles on each of the
five supported clients start with fast pickup and cursor alerts on and
**Disappear after (seconds)** at 3. Check that existing saved choices persist
and the installed FasterLoot still owns pickup while enabled. Native checks
remain pending. [Evidence](docs/LOOT_CURSOR.md).


Cursor loot (30 October 2026): verify Tools → Loot on Era, Anniversary,
MoP Classic, Retail Midnight and Forever, sequentially in the background.
Check loot speed with FasterLoot both enabled and disabled, cursor placement,
localized self-loot/money/currency, repeated identical items, group rolls,
rarity, toggles, reload persistence, combat/taint, pixels and frame time.
Desktop event fixture and 107-script/751-Lua suite pass; these do not certify
native acceptance. [Evidence](docs/LOOT_CURSOR.md).


Latest publication batch (30 October 2026): current first-load settings and
Hearthstone fixes included for main. Combined desktop validation: 106 scripts,
748 Lua syntax files, zero failures. Native acceptance remains pending.

Historical Sticky Targeting follow-up (30 October 2026): verify the new
single-setting native Controls route on Pandasans Retail when its process is
available in the background. Check `deselectOnClick=1`, unchecked Settings
checkbox, first-load completion, reload persistence, manual Controls reset,
taint and frame time. The linked GitHub main source itself matches the old
local route; the 13 August local pre-rewrite snapshot supplied the distinct
native setting call. Focused desktop fixture passes 76 checks.
[Evidence](docs/RETAIL_CONTROLS_CAMERA_FIX.md).

Retail Controls follow-up (30 October 2026): check Pandasans in the real
Retail client when available in the background. Verify Sticky Targeting is
unchecked (`deselectOnClick=1`), camera factor reaches the accepted 2.6
fallback, the prior failed audit retries once without keybinding work, and
the next reload stays quiet. Check manual Controls reset, taint and frame
time. Mariosuper Era and other client checks remain pending. The user's
pre-fix Retail values were `1.900000 / nil / 0`; desktop fixture passes 68
checks. [Evidence](docs/RETAIL_CONTROLS_CAMERA_FIX.md).

First-load settings follow-up (30 October 2026): native first-account and
new-character checks are pending. Verify Controls (auto loot, sticky target,
interact, camera), nameplate size 2 and character scope, raid appearance,
quiet single completion, later reload preservation, and manual Reset All /
Reset These Settings. Check Mariosuper Era and Pandasans Retail in the
background when available, plus Anniversary, Mists and Forever. Record
protected-frame taint and frame-time evidence without changing profiler
preferences. Desktop suite: 106 scripts/748 Lua; first-load fixture: 60
checks. [Evidence](docs/NONBINDING_FIRST_LOAD.md).

Hearthstone selector hover follow-up (30 October 2026): the user's native
error at line 491 was a direct `GetItemInfo` call with that global absent.
The selector now uses `Flux.Item.GetInfo` and Toy Box name fallback. Focused
19-check regression and full 106-script/748-Lua desktop suite pass. Verify
hover, owned-toy choice, actual button use and reload persistence in the
native Toy Box client; combat/taint, pixels and frame time remain pending.
[Evidence](docs/HEARTH_CONFIG_TOY_COLLECTION.md).

Hearthstone Toy Box panel follow-up (30 October 2026): the earlier candidate
still showed no panel because `FluxSmartHearthConfig.lua` loads before
`FLUX_API` is initialized. Its guard now reads already-loaded `Flux.Cap`.
The corrected 17-check TOC-order regression and 106-script/748-Lua full
desktop suite pass. Native Toy Box visibility, owned-toy selection, secure
button use and reload persistence remain pending.
[Evidence](docs/HEARTH_CONFIG_TOY_COLLECTION.md).

Earlier Hearthstone Toy Box config attempt (30 October 2026): the Toy Box
capability and journal opener were corrected, but the 14-check fixture missed
the TOC load-order failure. Verify `/fluxhearth config`,
owned-toy selection, button use and account/character persistence after reload
on a real Toy Box client; combat/taint, pixels and frame time remain pending.
[Evidence](docs/HEARTH_CONFIG_TOY_COLLECTION.md).

Atomic binding follow-up (30 October 2026): first-account keys now clear,
assign, verify, save and load in one call, with Blizzard action contexts on
modern clients and three immediate attempts only for wrong keys. Focused 507
checks and 105-script/747-Lua desktop validation pass. The user's Mariosuper
Era and Pandasans Retail clients were not visible in this workspace process
or window view, so native first-login/reload keys, labels, no replay, taint and
frame time remain pending. [Evidence](docs/BINDING_ATOMIC_CONTEXT.md).

Binding persistence rewrite (30 October 2026): first-load Retail account
cache was 29 bytes with no bindings although marker 5 claimed completion.
Source now avoids SaveBindings during PLAYER_LOGIN, selects account bindings
at first world entry, applies and verifies the template, SaveBindings(1),
LoadBindings(1), verifies again, then checks disk persistence on the next
login before recording version 6. Old version-5 empty
cache gets one migration repair. Focused 501 checks and 105-script/747-Lua
desktop suite pass. Native first-load/reload persistence, bridge key presses,
labels, taint and frame time remain pending.
[Evidence](docs/BINDING_PERSISTENCE_REWRITE.md).

Binding repeat follow-up (30 October 2026): the user confirmed the exact
"Applying keybindings..." line repeated after reload on existing clients.
Version 5 now claims a truly new account's first pass before its first native
write. Old pending markers and four already bound Flux bridge commands skip
repeat setup; overlapping requests cannot queue a second clear. The new
account still starts on the first world-entry frame. Focused 544 checks and
105-script/747-Lua desktop validation pass. Native reload/no-replay, bridge
key presses, hotkey labels, persistence and frame time remain pending.
[Evidence](docs/ACCOUNT_BINDINGS_ONCE.md).

Account-only binding correction (30 October 2026): user requires exactly one
automatic full template application on the first load of the whole account.
The previous per-character marker caused repeats; Settings reset callbacks
also had keyboard replay paths. Now only a pending first-account bootstrap
starts a full pass, and completion is account-wide. Existing accounts and
successful old character markers migrate without reset. Focused 528 checks
and full 105-script/747-Lua desktop validation pass. Native first-account
key presses, later character/no-replay, persistence and frame time pending.
[Evidence](docs/ACCOUNT_BINDINGS_ONCE.md).

One-time binding correction (30 October 2026): user requires exactly one
successful full setup per active binding set and no repeated login reset.
Version 4 now marks completion after the verified save, accepts preceding
pending version-4 markers, and removes `UPDATE_BINDINGS` replay. The setup
uses one registry scan and a maximum of eight binding writes per frame, with
clear/apply/save phases separated. Focused 521-check desktop test passes;
native first-load keys, reload persistence and frame time remain pending.
[Evidence](docs/FULL_BINDING_RESET.md).

Full binding reset follow-up (30 October 2026): user explicitly requested
clearing the active native binding set before applying the complete Flux
keyboard template on every client. Version 4 forces one batched full reset
for older markers, verifies the supported template before save, repairs late
native binding-set replacement in the same login and confirms persistence
after a later login. Focused 521 checks and full 105-script/747-Lua desktop
suite pass. Native first-login/reload key presses, grid labels, account and
character sets, combat and taint checks remain pending on each client.
[Evidence](docs/FULL_BINDING_RESET.md).

Binding persistence follow-up (30 October 2026): first-account full keybind
batch could finalize its queued seed before the late native-set check. Version
3 keeps saved Flux keys pending across login sessions and repairs a key lost
on reload before marking success. Old version-2 markers recheck. Focused 35
checks and full 105-script/747-Lua desktop validation pass. Native first
login/reload and actual bridge key/button/label tests remain pending on each
client and binding scope. [Evidence](docs/DEFAULT_GRID_BINDINGS.md).

Protected-client raid settings follow-up (30 October 2026): user chose to keep
the taint guard. Retail/Forever Flux raid cells and preview now follow own
class color, power, health text and aura options despite native CVar values;
existing own frame sizing applies at world entry. Blizzard Interface values
stay native-owned. Nine focused checks and full 105-script/747-Lua desktop
validation pass. Verify first account/new character, real raid cells, combat,
Edit Mode and Settings in native clients before acceptance.
[Evidence](docs/RAID_OWNED_SETTINGS.md).

Protected-client raid settings follow-up (30 October 2026): user chose to keep
the taint guard. Retail/Forever Flux raid cells and preview now follow own
class color, power, health text and aura options despite native CVar values;
existing own frame sizing applies at world entry. Blizzard Interface values
stay native-owned. Nine focused checks and full 105-script/747-Lua desktop
validation pass. Verify first account/new character, real raid cells, combat,
Edit Mode and Settings in native clients before acceptance.
[Evidence](docs/RAID_OWNED_SETTINGS.md).

Raid/nameplate defaults follow-up (30 October 2026): user reported Blizzard
raid power bars, class colors and frame size missing at first login and asked
for Medium nameplate size `2`. Classic profile application now waits for the
active native profile and reapplies its CVar pack after load, with bounded
first-world-entry retries. Both nameplate default tables use `2`; existing
size `3` migrates once, preserving other choices. Retail/Forever native raid
settings remain guarded because addon-owned compact-frame callbacks can taint
protected frames. Focused 15 checks and full 104-script/746-Lua desktop suite
pass. Native first-load checks on every client remain pending.
[Evidence](docs/RAID_NAMEPLATE_DEFAULTS.md).

Same-login binding follow-up (30 October 2026): the user reports no bridge
keys on first load. The revised path writes at first world entry and verifies
again five seconds later before marking the active binding set complete. The
old `true` marker is upgraded to version `2`; stock achievement `Y` can become
smart mount, while custom assignments are retained. The live EBS grid registry
now refreshes hotkey labels, and a dense module list refreshes combat click
owners. Focused 29 binding and 7 label checks and full 103-script/745-Lua
desktop validation pass. Native first-load presses for
Hearthstone `7`, teleport `8`, smart mount `Y`, vendor mount `6`, labels and
combat/taint remain pending on all clients. [Evidence](docs/DEFAULT_GRID_BINDINGS.md).

Default grid binding repair (30 October 2026): missing Flux template keys now
seed once into the current account or character binding set. The reported
Hearthstone (`7`), teleport (`8`), smart mount (`Y`) and vendor mount (`6`)
routes are covered. Existing custom targets and alternate bindings survive;
combat/full-template work defers the seed. Focused 21 checks and full desktop
102 scripts/744 Lua syntax files pass. Reload the affected character for the
one-time repair when native checking is appropriate. Verify actual key clicks,
labels, persistence, combat/taint and every client; no game/settings interaction
was performed. [Evidence](docs/DEFAULT_GRID_BINDINGS.md).

First-login defaults (30 October 2026): new characters apply only CVars and
nameplate bitfields that the active client reports as character-stored, then the
existing raid/chat setup. Full account setup and keyboard-template behavior are
unchanged. The focused 42 checks and full 101-script/743-Lua desktop suite pass.
Native fresh-account/fresh-character behavior across the client roster, queue
completion and secure/visual checks remain pending. The post-login three-sentinel
check still has an unreachable four-mismatch threshold; preserve customized
values when addressing it. [Evidence](docs/DEFAULTS_FIRST_LOGIN.md).

Current publication batch (30 October 2026): all local scale, vehicle/durability,
status-bar and vendor message updates are included for main. Fresh combined
validation passes **100 scripts /741 Lua syntax files, zero failures**.
See [publication record](docs/GITHUB_PUBLICATION.md). Native pending checks remain pending.

Vendor chat amounts now split copper into gold/silver/copper with matching coin
symbols in repair, junk sale and net vendor lines. Full desktop validation passes
100 scripts/741 Lua syntax files; native chat rendering remains pending. The
reported 3,494,236-copper repair should read 349 gold, 42 silver, 36 copper.
Preserve unrelated unit-frame, vehicle and status-bar working-tree changes.

Unit-frame scale follow-up: portrait offsets and focus alignment now use
frame-local coordinates; player and side-by-side target clear the action strip
at 50–200% scale. 3D portrait camera refreshes on an actual scale change.
Focused 23 checks and full 99-script/740-Lua desktop suite pass.
[Evidence](docs/UNIT_FRAME_SCALE.md). Native pixels, click areas and
combat/taint remain pending. Preserve concurrent vehicle/durability and
status-bar changes.

New unit-frame scale controls: Player tab sets shared player/target size;
Focus tab sets focus size (50–200%, default 100%). The root and attached
elements, dependent target frames, detached chrome and class resources scale
together. [Scope and pending native checks](docs/UNIT_FRAME_SCALE.md). The
focused bridge model passes 17 checks; full 98-script/739-Lua report is in that chapter.
Preserve concurrent vehicle-seat work and verify native pixels, hit areas and
combat/taint when background-safe access is available.

Latest vehicle/durability change (30 October 2026): the 70%-scale seat indicator
sits left of equipment durability. If the micro menu or status strip is visible
at the top-left, both indicators sit below the lower strip without moving it.
Otherwise the pair starts at the screen top-left, subject to PvP-widget clearance.
Focused source-driven checks and the full 99-script/740-Lua desktop suite pass.
Native vehicle art, seat clicks, combat,
taint and all-client pixels remain pending. No client/settings interaction.

Latest work (30 October 2026): [unit power visibility](docs/UNIT_POWER_VISIBILITY.md)
hides Flux-owned main/raid power bars for known zero maximum and expands health.
Live/Forever keep full-height health behind power and pass maximum power through
secret-safe alpha; zero current keeps the resource visible. Focus-target and
pet-target were health-only already. Focused models and full 96-script/737-Lua
desktop suite pass; native all-client geometry/combat/taint/secret checks pending.
Health text uses full-height HP for a known zero maximum and stays in the health
section for restricted maxima. The Flux separator restores resource alpha after
partition/chrome repaints, including ToT refreshes; secret maxima are never
tested for truth in Lua. Player/target labels move to the expanded HP bar's
vertical middle for known zero power and restore nested placement on return;
ToT's separator container follows its raised side-by-side frame level. Native
text/border pixels remain pending.
WoW and on-disk settings/profilers were untouched. Source/test/docs were
published on main in `c313dc98a1e782aee1224554c347cd616f3ad7af`.
Preserve newer user changes before further work.

Latest user work: [teleport counts/interruption](docs/TELEPORT_CAST_WORK.md),
BUG-012/PERF-011. User confirms Retail. Candidate uses native count text and
restores the host without popup/binding rebuild. 527 focused checks, three
mutations, five desktop pairs and full 95 scripts / 736 Lua files pass. Native
reload/interrupted casts and comparison with non-travel custom flyouts pending.
No live game/settings changes. This fix is included in the current local-snapshot
publication payload; native acceptance retains its pending scope.

Continue in the existing `_FluxUI` folder/repository. On 29 October 2026 the user
requested that the current local files be uploaded to main, with no other branch.
Work on main only and preserve existing history/newer local edits; no force pushes.
See [publication record](docs/GITHUB_PUBLICATION.md).
Read [status](docs/STATUS.md), [decisions](docs/DECISIONS.md),
[development tasks](docs/DEVELOPMENT.md) and the [original stage tracker](docs/MODERNIZATION_PROGRESS.md).
The formerly pending objective-tracker source/test/records are included in commit
`73ca9d2`. Inspect current status before new work and preserve any newer user edits.

Earlier runtime `677d85c` shares activation within bar paint batches. Current full
workspace evidence: [95 scripts/736 Lua files](docs/validation/main-local-snapshot-2026-10-29.json).
[Action/player-aura audit](docs/ACTION_AURA_WORK.md) has five matched native pairs
per Retail/Era client, exact sources, unchanged57 button/aura-root geometries and
zero recorded matched-run errors. Native highlight was inactive; active combat/
secure input, dense/restricted auras and long-session leak acceptance remain pending.

Next priorities:

1. Attribute assisted-host icon/count/cooldown/usable work and repeated next-spell
   queries before sharing facts. Retail baseline4.814ms/s is inclusive, not a sum
   with its children. Preserve identity, effects and response cadence.
2. Exercise live enabled effects, paging/forms/modifiers/pet/stance/vehicle/input,
   aura expiry/reapply/reuse and combat/Edit Mode on exact builds. Top-right player
   aura data/handlers/style remain Blizzard-owned; no replacement painter.
3. Continue original API/lifecycle/private-cache and long-session gates. Keep
   auction, guild-bank and void-storage callbacks excluded.

Both clients remain open. Account sessions displace each other: test the named
characters sequentially using normal warning dismissal/Reconnect/selection.
Verify current executable/PID/window before messages; do not take foreground or
PC mouse/keyboard/clipboard. Final state: Era in world, Retail reconnect screen.
Original profiler0 Retail/1 Era and prior diagnostic roots restored. The existing
mirror job stays running unchanged (actual timeout1s despite60s text); verify file
hashes before reload and preserve unknown destination changes. No extra sync job.

Reproduction from the addon root:

```powershell
lua tests/assisted_highlight_work.lua --source tests/fixtures/assisted_highlight_before.txt --measure
lua tests/assisted_highlight_work.lua
lua Core/_tmp_playeraurassmoke.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Baseline measure intentionally exits0 with20 unmet work budgets; candidate must
pass. Feature removal, settings reset, history rewrites and a separate release
remain outside the authorization. Main publication is authorized for this batch.

Final freshness note: independent unit-frame work continued after the full capture.
The last documentation check reported only inventory/verification freshness for
`tests/raid_party_frames.lua`; refresh whole-project evidence after that batch.
Six related quest/nameplate/Questie scripts pass and this feature's four owned
Lua identities remain unchanged. See the quest validation JSON for scope.


Native continuation17:40UTC: Forever background readback confirms zero session errors, solo/OOC, profiling0, all three merchant input toggles configured, party v7 ready/secure with four hidden solo members. No runtime/settings/gameplay changes. User reports a real test party/raid with combat roster changes is unavailable now; actual combat/grouped acceptance remains pending. First consecutive unavailable-scenario audit; goal active. See FOREVER_NATIVE_PERFORMANCE.md and its validation JSON.

9 November goal blocker audit3: actual combat roster and grouped performance acceptance remain unavailable after three consecutive goal turns. User cannot arrange the real test group now. Goal blocked pending that scenario; no new runtime, input, settings or profiler changes. Completed evidence and exact pending checks remain in FOREVER_NATIVE_PERFORMANCE.md.
