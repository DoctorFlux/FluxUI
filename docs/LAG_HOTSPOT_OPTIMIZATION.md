# Casting and inventory lag optimization

<!-- LHO-CRAFT-FALLBACK-CATALOGUE-OWNERS-20261120 -->
20 November. A real bag-only move rebuilt three catalogues per direction in the right-click craft refresh. The native reagent read cost was 0.242 ms at the median on 19 known item IDs, compared with 2.958 ms for the three selectors. These are independent reads. Cache eligibility and the whole-frame effect remain open. [Evidence](validation/profession-bag-restock-2026-11-19.json#nativeCraftFallbackBagCatalogueOwners).

<!-- LHO-FIRST-COPY-GRID-RECEIPT-20261120 -->
20 November. The real item 1487 receipt advanced carried stock from zero to 14 and switched the food face. Two grid count flushes totaled 0.369 ms, three consumable recomputes totaled 10.324 ms and six catalogue reads totaled 5.033 ms. Some of these timings may overlap. [Evidence](validation/backpack-final-callback-2026-11-19.json#nativeFirstFoodCopyGridRoute).

<!-- LHO-CONJURED-CACHE-READ-20261120 -->
20 November. R678/R680 recorded 48.55 and 39.26 ms cold backpack opens, with nearby frame intervals of 67 and 57 ms. Junk display accounted for 3.684 and 3.015 ms over 98 calls. R679/R681 recorded 608 and zero repeat metadata reads in the conjured check over eight passes of 41 actual item IDs. Category filtering differed by 4.484 ms across the two opens. The single cold pair does not establish an overall FPS gain. [Evidence](validation/backpack-final-callback-2026-11-19.json#settledConjuredMetadataReads).

<!-- LHO-BANK-CLOSE-LATCH-20261120 -->
20 November. A single-bank slot move and return triggered two Restock summaries in each direction, totaling 13.970 and 10.907 ms. All stock was restored. The old latch remained active after both native close events and after the physical access signals went false. On the loaded fix, R676 observed both close events, all five checks clearing and 21 cached counts matching live. Repeat the bank move with the tier optimization loaded for a new summary timing. [Evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeBankSlotMoveAndCloseLatch).

The [inventory performance roadmap](INVENTORY_PERFORMANCE_ROADMAP.md) tracks current priorities and the remaining verification. This file retains the detailed evidence.

<!-- LHO-BANK-TIER-SETTLED-KIND-20261120 -->
20 November. The live Forever bank registered 21 item IDs at open. Six summary callbacks consumed 18.902 ms across the observation window and five physical walks totaled 5.538 ms. Natural bag changes and overlapping callbacks limit attribution. With the bank open, rebuilding the actual summary after registry invalidation took 6.779 to 6.941 ms. One trace spent 6.388 ms in five tier bag totals and made no raw slot reads. A paired candidate skipped 132 wrong-tier checks across six builds and reduced the median from 10.0165 to 9.3595 ms. The current profile produced zero tier withdrawals. [Evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenBankTierKindWork).

<!-- LHO-BANK-VIEW-LOADED-20261120 -->
20 November. With the visibility changes loaded on Forever, the median for 48 live predicates fell from 0.5130 to 0.4245 ms, and for five tier-bank reads from 0.6775 to 0.6230 ms. All six pairs improved on both measured scopes. The full target list changed from 2.3755 to 2.3955 ms and Auction rebuild went from 3.6250 to 3.5265 ms at the medians. Both spans overlap. The actual open-bank Restock warm button took 0.007 to 0.008 ms after its first measured call, with four rows and zero eligible withdrawals. [Loaded comparison](validation/baganator-bank-view-index-2026-11-19.json#loadedFallbackFrameNames). [Open-bank timings](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenBankRestockButton).

<!-- LHO-BANK-VIEW-FALLBACK-NAMES-20261120 -->
20 November. In Forever with both inventory addons, six pairs of 48 closed-bank visibility queries took a median of 0.500 ms with the loaded original and 0.402 ms with the exact candidate. Enumeration alone fell from 0.2605 to 0.211 ms per 48 calls. All frame identities and their order matched. A separate open-bank capture found 21 positive item IDs and all 22 stacks with no extra or missing result. Full Restock and frame-time gains remain pending. [Visibility evidence](validation/baganator-bank-view-index-2026-11-19.json#fallbackFrameNames). [Open-bank evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenCharacterBankStackParity).

<!-- LHO-RESTOCK-TARGET-ATTRIBUTION-20261120 -->
20 November. With both optional inventory addons active in Forever and commerce panels closed, four warm shared Restock builds took 2.352 to 2.539 ms, including exact comparisons of all nine row records. The corresponding stand-alone five tier bank reads cost 0.655 to 0.712 ms with the normal food and water stock omissions and same-call positive count reuse. The five tier bag reads cost 0.020 to 0.025 ms, and four independent item bank rows cost 0.149 to 0.164 ms. Stand-alone timing scopes can overlap. The preset lookup accounted for about 0.002 ms on this profile, which had no selected presets. [Evidence](validation/bank-tier-matcher-2026-11-19.json#nativeRestockTargetAttribution).

<!-- LHO-RESTOCK-TIER-RECORD-FILTER-20261120 -->
20 November. Four actual Auction row builds took 6.580, 3.691, 3.596 and 3.602 ms. Separate shared target builds took 2.298 to 2.493 ms. On the corrected loaded source, eight alternating in-game pairs using 41 items and five kinds cut the median for 1025 isolated tier queries from 1.108 to 1.061 ms with exact verdicts. Cold and warm whole builds across reload are separate samples and do not prove that the frame spikes fell. [Evidence](validation/bank-tier-matcher-2026-11-19.json).

<!-- LHO-AUCTION-INITIAL-PLAN-PAINT-20261120 -->
20 November. Warm R645 produced idle/changed and two searching paints. The loaded cold R648 produced searching and two auction-waiting paints with one row build. This verifies removal of the obsolete paint stage in an actual opening, while total synchronous paint counts were three in both samples. The first-open timing and frame-time effects remain unverified because the cache and native throttle states differed. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-ROW-ORDER-ALLOCATION-20261120 -->
20 November. The exact native comparator change reduced the median from 3.621 to 2.618 ms per 340 sorts over six actual rows, including array refill, with exact order. Loaded R643 spent 0.129 ms across 132 comparator calls during a real Auction workflow, and first ShowSession took 13.814 ms. This trims a repeated allocation. Matched whole-window and frame-time gains remain open. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-CATALOGUE-REVOCATION-VALIDATION-20261120 -->
20 November. After the text alias edit loaded, the real stack move and return spent 4.355 and 4.759 ms in the three recipe lists per direction. Earlier values were 4.818 and 3.634 ms with fewer observers. A follow-up native direct removal lookup won on the current 1110 flags, but with checks it took a median 9.6895 ms for 12 builds versus 8.997 ms for the current eager snapshot. Overall bag-spike improvement remains unverified. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-TEXT-ALIAS-20261120 -->
20 November. An actual Conjure Food finish caused 3 delayed bag events, 6 Craft lists and 5.096 ms in catalogue work out of 6.644 ms for the lists. Counts rose 56 to 70 and zero new Lua errors appeared. Eight alternating live catalogue comparisons using 149 returned rows and 9 aliases reduced median time from 13.006 to 12.161 ms for 18 builds. The production source now skips repeated conversion of ordinary text aliases. Whole-receipt frame-time effects remain open. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAGANATOR-LAZY-CATEGORY-ICON-20261120 -->
20 November. Actual Forever cold backpack opens before and after the lazy label edit ran 19 icon applications each. The number of ordinary labels with hidden FluxUI icon textures fell from nine to zero. One open per revision took 45.385 and 37.403 ms, with ordinary icon application at 0.142 and 0.131 ms. Those separate samples establish the allocation count reduction. Frame-time improvement remains unverified. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-CRAFT-POTION-FALLBACK-STATIC-20261120 -->
20 November. In eight alternating in-game pairs, actual potion and bandage fallback inputs took 2.469 ms before and 1.890 ms with the exact candidate at the median for 3,144 checks. All sampled fallback results were negative. The loaded real move and return timed the full craft lists at 4.818 and 3.634 ms against 4.468 and 3.713 ms previously. The isolated path is faster. A whole-callback or FPS improvement remains unverified. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CAST-WIDGET-ENTRY-INDEX-20261120 -->
20 November. Six in-game sweeps of 780 FollowExtra calls fell from a 7.959 ms median to 5.133 ms on the same 195 real button count. The Food cancel totals were 12.601 and 12.496 ms across three callbacks. Both retained all 555 resets. These were separate pre- and post-reload cancels. Whole-frame and visible-owner effects remain open. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-AUCTION-SEARCH-PREPAINT-LIVE-20261120 -->
20 November. The warm actual search after the edit removed idle/searching from the captured viewport paint sequence. The two retained complete searching paints and the three later paints still ran. The warm 8.131 ms sample was slower than either before sample. Time-to-open and frame-time improvement remain unverified. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-SEARCH-PREPAINT-20261120 -->
20 November. The native Auction panel produced a nearby 116 ms frame gap with 0.285 ms across two FluxUI tab attachments. The first Restock ShowSession was 12.567 ms with one synchronous row build. Two warm Restock opens took 6.180 and 7.713 ms and each made four synchronous and three later viewport paints. The warm trace showed an obsolete idle/searching paint immediately before the complete search paint. The installed comparison is pending. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROTECTION-EMPTY-SLOT-LOOKUP-20261120 -->
20 November. Actual Forever bag slot protection fell from 0.600 to 0.375 ms per 416 lookups at the median in six batches per revision. All 52 occupied slots had the same verdicts. The cold backpack recorded 3.38 ms in display junk, 0.23 ms in slot protection and 0.73 ms in vendor fade, with nested time possible. The warm open took 3.55 ms. The first-open hitch remains open. R616 retrieved 44.32 ms for the first open with a nearby 63 ms frame gap. Baganator layout reached 42.41 ms inclusive, with 21.65 ms in display and 10.364 ms in 53 item-detail calls. Nine layout groups were created. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-NUMERIC-CATALOGUE-OPEN-BAG-20261120 -->
20 November. The first observed Forever backpack open in R612 took 52.76 ms versus 47.15 ms in R602. Open-backpack redraws took 5.374 and 4.916 ms versus 4.908 and 4.315 ms. Each direction still performed one redraw. Nearby frame gaps were 35 and 29 ms versus 21 and 17 ms in the earlier capture. These reload-separated samples confirm the first-open hitch is still present. They do not isolate the catalogue change as the cause of the timing difference. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-NUMERIC-CATALOGUE-LIVE-BAG-20261120 -->
20 November. Following R610, the three Craft recipe lists took 4.468 ms during the outward move and 3.713 ms on return, compared with 4.592 and 4.362 ms in R603. Each direction delivered one delayed event and kept the same item totals and grid selections. These are separate observations surrounding a reload. Nearby gaps of 26 ms during R611 do not establish a frame-time reduction. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-NUMERIC-FULL-CATALOGUE-20261120 -->
20 November. On the actual saved Forever catalogue, host Lua 5.1 timed ten pairs of 150 builds. Every pair was faster and both functions selected the same 149 row references in the same order. The median fell from 0.407 to 0.343 ms per full build. Repeat the R603 bag move in-game to measure total Craft callback and nearby frame time. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAG-MOVE-CRAFT-CATALOGUE-20261120 -->
20 November. The R602 category backpack took 47.15 ms to open. The actual move and return spent 4.908 and 4.315 ms in the Baganator view and 0.603 and 0.573 ms in FluxUI Notify, with overlapping timings. The closed-bag repeat exposed 4.592 and 4.362 ms in three extra craft lists per delivery. In the direct R605 split, catalogue lookup accounted for 2.965 of 4.883 ms across heal potion, mana potion and bandage. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-RESTOCK-REAGENT-VISIBLE-PASS-20261120 -->
20 November. Five original Forever Restock rebuilds built fifteen reagent sets across four manual configuration entries. R601's installed warm-path median was 3.555 ms versus 3.890 ms for the full fallback, with six wins in six pairs. One fallback first sample took 12.042 ms. The same six shown rows, one hidden row and potion targets matched. Measurements cover direct row rebuilds with commerce closed. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-PROFESSION-FILTER-CANDIDATES-20261120 -->
20 November. Eight exact comparisons of the 102 native Tailoring rows took 2.816–3.021 ms each. Six of eight reverse removal lookup pairs were faster in rank work, with medians of 0.496 and 0.4305 ms. Both ideas remain unapplied. Live filter switching preserved the saved catalogue and retained full fresh observation for the filter transitions. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-CURRENT-PASSIVE-20261120 -->
20 November. In R588 the first post-open list took 7.528 ms and a passive list after 26.57 seconds took 8.632 ms. Three R589 list callbacks took 8.890–12.341 ms, including 5.553–8.323 ms of work before storage. The two stores accounted for 2.322–2.685 ms across those three list callbacks. R588 recorded one 53 ms peak frame with no owner attributed. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-RETAIN-SAVED-REMOVALS-20261120 -->
20 November. The full-read Tailoring callback took 19.555–37.938 ms and the loaded path 13.870–20.920 ms in four alternating pairs. The medians were 25.81 and 15.188 ms. Both used the loaded event handler and real open profession data. The diagnostic withheld the pending craft flush in both paths, with exact saved results. The first natural loaded source took 9.824 ms, compared with 14.026 ms in the previous separate reload sequence. Whole-frame attribution remains open. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-FIRST-READY-READ-COST-20261120 -->
20 November. The first ready Tailoring event took 14.026 ms. Four later sweeps on the same source measured 5.921–6.721 ms for 369 negative recipe-info calls and 0.207–0.250 ms for 369 negative spellbook calls. The 102 learned recipe-info calls took 1.589–2.281 ms, schematics 0.933–1.105 ms, output items 0.557–0.665 ms and quality lookups 0.061–0.075 ms. Prioritize the negative recipe path. The read probe did not change FluxUI's scan. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CAST-MATCHER-NUMERIC-20261120 -->
20 November. R584 paired the loaded spell matcher with the exact previous helper bodies on 117 comparisons captured from a live Food interrupt. Median elapsed time fell from 1.122 to 0.6475 ms, with eight wins in eight alternating pairs. All live override, base and name reads remain. The sample measures the matcher loop; the three-delivery cancel path still needs matched frame timing. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-CAST-POSITIONAL-PAYLOAD-20261120 -->
20 November. The three native Forever interrupt deliveries carried the same cast GUID and spell ID in one frame. Both revisions made 117 spell comparisons, 250 override reads and 234 base reads per interrupt. The positional spell correction keeps that event work and prevents trailing metadata from becoming the spell. The separate completed cast verified one bag generation change. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-OWNED-IDLE-RETICLE-CLEANUP-20261120 -->
20 November. The final loaded reticle loop fell from 0.962 to 0.887 ms at the median for 200 buttons, with six wins in six pairs. The prototype's larger saving did not carry through to the loaded routine. The earlier whole-cancel reset sample was essentially flat. Keep the next pass on the larger owner scans and actual frame spikes. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-CAST-INTERRUPT-TARGET-RESET-20261120 -->
20 November. During a single Forever Food cancel, R566 recorded 15.905 ms across three same-frame interrupt handlers, including 7.511 ms for six owner scans and 4.037 ms for 600 button resets. None of those handlers played an interrupt animation. The first cancel independently showed the same work counts. Both probes preserve the original behavior and report inclusive callback time. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-PROFESSION-SOURCE-STORE-ATTRIBUTION-20261120 -->
20 November. R564 attributed 9.965 of 13.493 ms in the warm ready source callback to the interval before first storage. The first and second saves took 1.614 and 0.941 ms. The following two list deliveries took 8.369 and 8.640 ms, with 4.674 and 5.074 ms before storage. The timings cover the FluxUI event body and its synchronous listeners. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-COMBINED-REAGENTS-20261120 -->
20 November. Across six alternating native pairs, the reagent and crafting-data extractor median fell from 1.164 to 1.027 ms and all results matched. The previously sampled first ready source and list took 24.16 and 13.63 ms. The corresponding events after reload took 23.17 and 8.63 ms. The handler samples were taken once per revision. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-READY-SOURCE-COUNTER-20261120 -->
20 November. R560 found 24.16 ms in the ready Tailoring source handler and 13.63 ms in the same-frame list handler. Both used source counter 33 and matched the observed saved rows and removals. The first ready source remains a major FluxUI-owned spike. This observer did not measure the full client frame. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAGANATOR-JUNK-SETTINGS-20261120 -->
20 November. The warm FluxUI Junk display pass used 65 settings lookups instead of 120 and sampled 0.314 ms instead of 0.393 ms. The first category backpack open sampled 57.08 and 47.32 ms, with nearby gaps of 69 and 56 ms. Warm reopen sampled 3.09 and 2.74 ms with 12 ms gaps. The first open still made 100 FluxUI Junk calls, taking 3.38 and 3.22 ms. There was one timing per revision. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-PENDING-IDLE-REFRESH-20261120 -->
20 November. Loaded Forever idle Pending queries reduced the median for 48 calls from 0.317 to 0.146 ms. Settings reads fell from 192 to 48 per batch while paint count and empty returns matched. No automatic refresh occurred in either idle window. This is an explicit query improvement. Active receipts and frame-time effects remain open. [Evidence](validation/inventory-idle-followup-native-2026-11-18.json).

<!-- LHO-RESTOCK-BANK-STACKS-LOADED-CLOSED-20261120 -->
20 November. The edited stack finder is loaded on Forever. The closed-bank validation kept positive counts intact and returned no withdrawal locations. Active bank movement and frame timings remain open. [Evidence](validation/bank-tier-live-counts-2026-11-19.json).

<!-- LHO-RESTOCK-UNIQUE-BANK-STACKS-20261120 -->
20 November. Restock walks each character-bank bag once when constructing withdrawal stacks. The fixture using the real stack collector reduced five entries to three and five slot charge reads to three. Its corrected charge sum was nine. Closed-bank R550 measured 0.489 ms to read both native aggregates for 21 known item IDs. All counts matched the cache. The cold-close race and whole-frame cost remain open. [Stack evidence](validation/bank-tier-live-counts-2026-11-19.json). [Closed-bank evidence](validation/lag-hotspots-provider-counterexamples-2026-11-14.json).

<!-- LHO-PROFESSION-SAVED-NEGATIVE-PREDICATE-20261120 -->
20 November. At a real ready source callback, a probe used two saved aliases, the current learned-only list and current spellbook to cut full recipe reads from 471 to 102. Isolated getter time was 6.61/1.80 ms at source and 5.42/1.43 ms at list. The learned and removal sets matched on both. This study leaves runtime callbacks and the first-open spike unchanged. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-OBSERVED-REMOVALS-20261120 -->
20 November. Recipe alias ranking only collects removal flags for observed IDs. Six paired in-game rounds using the actual Tailoring cache reduced the isolated median from 0.529 to 0.413 ms, with identical winners for all 102 recipes. R536 loaded the edit. The first source/list pair took 15.44/9.66 ms and the warm pair took 16.47/8.24 ms. Timing varied across the reload and the warm handler remained above earlier samples. No overall frame-time gain has been established. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-FIRST-TAILORING-PUBLICATIONS-20261120 -->
20 November. The first Forever Tailoring open loaded Blizzard professions, then FluxUI spent 16.75 ms in the source-change handler and 12.76 ms in the list handler in the same frame. Those timings include 0.70 and 0.69 ms in Notify. The follow-up list took 13.76 ms with 0.75 ms in Notify. The nearby 149 ms gap includes other client work. Both warm source/list pairs reproduced synchronous scans. The second pair compared the saved recipe and removal arrays captured at each event boundary and matched all 102 learned recipes. Runtime behavior is unchanged. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-COUNT-NEUTRAL-MOVE-BUILTIN-20261120 -->
20 November. R521 used the built-in provider for the same closed-backpack move and return. The two FluxUI notifications took 0.793 and 0.732 ms. The grid count updates took 0.177 and 0.178 ms and the nearby window peaks were 17 and 16 ms. Both delayed bag events carried a slot change with stable stock. No classifier scans or Lua errors were recorded. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-COUNT-NEUTRAL-MOVE-PROVIDERS-20261120 -->
20 November. R513 and R515 measured the same closed-backpack move and return. With both addons, synchronous FluxUI notifications took 0.611 and 0.644 ms and grid count updates took 0.186 and 0.178 ms. With Syndicator alone, notifications took 0.741 and 0.588 ms and grid count updates took 0.201 and 0.183 ms. Both profiles kept the classifier settled and restored the original item slot. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-UTILITY-CONSUMABLE-RETRY-20261119 -->
19 November. FluxUI eliminated the four utility items' passive scan loop, from 35.275 ms per six seconds to zero in the loaded Forever comparison. Separately, the first backpack open after reconnect created nine category layout groups. Baganator layout took 47.42 ms of the 49.80 ms toggle and the FluxUI reveal callback took 1.39 ms. Warm reopen took 2.88 ms. [Classifier evidence](validation/consumable-non-restoring-items-2026-11-19.json). [Backpack evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-NATIVE-BAG-REDRAW-OWNERS-20261119 -->
19 November. In the open Forever category backpack, three genuine bag-cache deliveries produced 5.782, 5.400 and 5.858 ms Baganator updates. The first had a nearby 35 ms frame. FluxUI adapter rebuilds took 0.093 ms combined. Notifications took 2.414 ms and the observed subscribers outside Notify took 3.955 ms. The redraws were owned by Baganator's ItemData callback. The first update kept the same food count and the next two changed it. Compare complete slots before attempting to skip the count-stable refresh. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-NATIVE-FOOD-RECEIPT-20261119 -->
19 November. R494 captured two delayed bag events during a real cast and receipt sequence. Their nearby frame gap reached 28 ms. The largest observed frame gap was 33 ms, also reached near an interrupted event. The two Baganator redraws took 16.988 ms total, including layout and display. FluxUI's two synchronous notifications took 1.432 ms total, excluding deferred listeners. Capture redraw triggers and the per-event snapshot changes before changing refresh cadence. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-REDRAW-FRAME-GAP-20261119 -->
19 November. The installed single-request path reduced nearby frame gaps in all four paired redraws on an open Forever category backpack. Gaps were 52, 37, 36 and 33 ms with the former requests and 37, 34, 33 and 31 ms with the installed request. Median inclusive redraw work fell from 28.25 to 24.78 ms. Frame gaps include the rest of the client's work. The first-open hitch still needs a separate trace. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-SINGLE-CATEGORY-REFRESH-20261119 -->
19 November. Gear-set contents, the Equipment Set section and consumable preset categories now request one Baganator refresh through the public widget/search reasons. After reload, four Forever pairs reduced category update calls from two to one and median redraw time from 31.482 ms to 27.103 ms. Category order, item counts and view dimensions matched. No Lua errors occurred. The unchanged-content test measured the normal display callback. Genuine preset or gear changes and whole-frame effects remain native follow-ups. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-SHIELD-CONTEXT-20261119 -->
19 November. FluxUI's Baganator gear-set shields reuse the existing merchant and disenchant context during protection refresh. Four installed Forever pairs matched all 52 widget results. Context reads fell from 106 to two, and median refresh time fell from 0.882 ms to 0.791 ms. All five installed copies match. This is a shield refresh timing. The 72 ms frame gap from the first observed backpack open still warrants investigation. The bulk of its measured toggle time was inside Baganator category layout. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-PROFESSION-LEARNED-LIST-AUCTION-20261119 -->
19 November. Four native Forever Tailoring updates with Auction Restock open produced the same learned recipes, removal flags, visible and hidden rows, and potion targets as immediate full scans. Median combined time was 16.014 ms with the forced full scan and 12.798 ms with the installed settled path. Each half refreshed Restock once. All four inventory generations stayed stable and no Lua errors appeared. The active row builder still took about 4.1 ms in the paired test. The independent breakdown measured a 2.675 ms median for the target-list query. The paired diagnostic executes two scans per captured event, so it yields callback timings only. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-CONFIRMED-UNLEARNED-20261119 -->
19 November. Settled owned-profession scans can skip full metadata reads for recipes previously confirmed unlearned when the native recipe list, filters and live spellbook still agree. On live Forever Tailoring, median isolated read time dropped from 4.157 ms to 1.173 ms and full metadata calls from 471 to 101. After reload, four native events paired with immediate full scans matched all learned rows and removal flags. Median total scan time fell from 13.293 ms to 8.346 ms. The normal event cadence and native positive and uncertain recipe reads remain in use. This measures the callback on the loaded client. Whole-frame effects and the combined Auction Restock workload still need capture. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-NAMED-ALIAS-20261119 -->
19 November. The named profession save reuses the current scan's reconciled recipe references when the numeric and named aliases agree. Four paired saves on copies of the actual Forever Tailoring cache reduced the median from 1.225 ms to 0.890 ms. All 101 recipe records, alias order and removal flags matched. After reload, six native Tailoring events confirmed 101 matching records and separate saved arrays, with no new Lua errors. Ten syntax checks and eight regression scripts passed. All five installed sources match. The paired secondary-save reduction was 0.335 ms. Unpaired loaded callbacks still reached 33.564 ms, with 31.275 ms spent before secondary reconciliation at that spike. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-AUCTION-TAILORING-WARM-LOADED-20261119 -->
19 November. Eight native Tailoring updates rebuilt Auction Restock once apiece. The installed bag-tooltip path reduced the median Restock rebuild from 5.114 ms to 4.291 ms. The full handler medians were 21.504 ms and 21.258 ms, with overlapping samples. All visible and hidden rows and potion targets matched, four inventory generations stayed stable, and no Lua errors appeared. Tailoring and Auction were closed and the original empty target restored. The installed row portion saved 0.823 ms at the median. The rest of the profession callback still needs optimization. No whole-frame gain was measured. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-WARM-BAG-TOOLTIPS-20261119 -->
19 November. Warm Auction Restock now shares nonempty native carried-bag tooltip text during a single row assembly. Consumable eligibility, missing metadata, item moves and changed providers keep their current checks. After reload, the three paired Forever rebuilds fell from a median of 4.455 ms to 3.767 ms. Visible and hidden rows and potion targets matched, the bag generation stayed stable, and no new Lua errors were captured. The source matches five installs, with 20 syntax checks and 43 regression scripts passing. The separate consumable readiness assertion fails identically on the checkpoint and candidate. The installed warm row-build median fell by 15.4%. The separately measured natural Tailoring handler still needs a loaded comparison. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-COLD-TIER-SLOTS-20261119 -->
19 November. Auction Restock shares complete occupied bag slots during one cold target-list build. Empty and incomplete slots still receive fresh reads. Recipe and tier matching retain their original order and cadence. In the installed Forever comparison, the median fell from 13.324 ms to 9.882 ms across three pairs. All seven rows and potion targets matched, the bag generation stayed stable, and no new Lua errors were captured. All five installed source copies match. Thirty syntax checks and 38 regression scripts passed. Whole-frame FPS and native checks on the other installs remain open. The complete-slot diagnostic read 238 instead of 450 slots. The installed comparison saved 3.442 ms at the median. The warm Tailoring handler remains a distinct hotspot. [Evidence](validation/auction-final-sku-2026-11-19.json).

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
19 November. With Tailoring open and Auction Restock closed on Forever, a 24-second hands-off window produced three native list refreshes at 7.49, 20.91 and 23.53 seconds. FluxUI spent 12.652, 13.336 and 13.709 ms in those handlers. No delayed bag, item-data or player cast event was observed. Bag generation stayed stable and the probe reported zero new errors. An earlier pass recorded 47 profession publications. The displayed comparisons kept all 101 recipe records and tombstones equal, including with the native Have Materials filter changed and restored. The displayed list handlers reached 38.023 ms while publication took under 1 ms. The main cost was inside the scan and store path. Observers were restored and the panel closed. The next candidate must preserve late metadata and genuine learned, unlearned and craftability changes. Runtime Lua was not changed in this pass. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-AUCTION-RESTOCK-STARTUP-20261119 -->
19 November. Auction Restock now reuses its first row build for the first synchronous scan when the data owners, inventory generations, and time boundary match. The search response still rebuilds the rows. In two paired warm Forever runs with Baganator and Syndicator loaded, median ShowSession fell from 12.603 to 6.954 ms (44.8%) and synchronous builds fell from two to one. Six visible rows, one hidden vendor row, the editor selection and the search-response refresh matched. Both warm panel pairs matched across 330,035 sampled pixels. The original build path remains available for charged or unresolved items, active receipts or craft work, unsettled inventory, and replaced data methods. Genuine Pending receipts and other native client/provider profiles still need validation. Both Lua files match across five installs and passed 20 Lua 5.1 and 5.4 syntax checks. The test observer was removed, the window was closed and the original empty target was restored. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-NATIVE-AUCTION-LIFECYCLE-20261119 -->
19 November. Opening Forever's native Auction House Buy window for the first time after reload loaded Blizzard_AuctionHouseUI. The nearby frame gap was 118 ms on first open, 30 ms on warm reopen and 22 ms on the first close. FluxUI spent 0.231 and 0.090 ms attaching Restock, with no Restock row builds. The native observer expired before the second close, which was verified visually. Opening the actual FluxUI Restock tab took 25.407 ms inside ShowSession. Two synchronous row rebuilds took 8.979 and 8.630 ms, then the search response rebuilt the rows once more at 5.335 ms. All six displayed targets were stocked. The panel and original empty target were restored, and the observer reported no new Lua errors. Active Pending still needs a session with genuine receipts. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-ORDINARY-CHARGE-20261119 -->
19 November. Auction Restock reuses confirmed ordinary units only within one row rebuild with the original charge and potion-replacement methods and stable bag, bank and warband generations. Changed item IDs, charged items, unresolved data and open or unsettled bank contexts retain fresh reads. On the loaded Forever client, three paired full rebuilds with commerce closed matched six visible rows and one hidden vendor row on every run. Median elapsed time fell from 4.785 to 4.480 ms. The bag generation stayed stable and no new Lua errors appeared. Thirty syntax checks passed and the sources match across five client installs. Real charged stock, open Auction and Pending, and the other provider/client configurations still need native validation. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json). 19 November. The refreshed 180-second helper uses host 41128 (live20261119zi). It submitted one complete Space key pair at the check. Previous host 34796 stopped after seven pairs. Character movement remains unverified.

<!-- LHO-RESTOCK-REBUILD-ATTRIBUTION-20261119 -->
19 November. Three current Forever Auction Restock row builds took 13.465, 5.150 and 4.907 ms with commerce closed and the backpack open. The shared target builder accounted for 16.618 ms inclusive. Closed-bank tier reads took 4.026 ms and charge checks took 2.715 ms. Reagent-set lookups took 0.049 ms. The first observer setup used a missing spell API owner and left two temporary observers until the verified cleanup reload. The corrected probe restored its observers with zero new errors. A paired native check matched all 21 closed-bank item IDs. Reusing the ID union saved a median 0.279 ms per 12 rebuilds, so that candidate stayed out of FluxUI. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json). 19 November. Host 37328 recorded three complete Space key pairs before the diagnostic cleanup reload, including foreground and background activation. The cue was reinstalled. Current host 34796 (live20261119zh) recorded two complete key pairs. Character movement remains unverified.

<!-- LHO-JUMP-CURRENT-20261119 -->
19 November. After the observed Forever reload, the readiness cue was reinstalled and acknowledged. The running 180-second helper uses the renewed foreground policy. It can attempt a jump when WoW already has focus without a 15-second idle gate. It still waits for crafting, chat and physical input races to clear. Background activation still needs 15 seconds idle since targeted background Space did not move the character in previous tests. Read-only background calibration passed. Host 37328 (live20261119zg) is current. The first jump after reload remains unverified.

<!-- LHO-JUNK-CACHED-QUALITY-20261119 -->
19 November. Three paired native reads matched all 48 carried-item verdicts each time. Every sampled item had known non-gray quality. The isolated median was 0.148 ms for the original gray fallback and 0.013 ms when the probe used quality established before timing. One pair was slower. The Junk fallback now reads an already resolved non-gray quality when the Baganator caller supplies only an item ID. Gray, missing, restricted and replacement quality paths use the original rules. Both changed Lua files pass syntax checks across five installs. The live client still needs to load the change for full repaint timing. The prior cold single-item backpack hitch remains unassigned. Restock row equivalence is pending. The idle helper recorded three Space key pairs near its three-minute cadence. Character movement was unverified. [Evidence](validation/junk-cached-quality-2026-11-19.json).

<!-- LHO-PROFESSION-ALIAS-OVERLAP-20261119 -->
19 November. On Forever, 471 native Tailoring recipe observations overlapped one of eight saved aliases. Three isolated paired four-sweep tests agreed on every alias. The prototype median fell from 1.577 to 0.627 ms per four sweeps. Profession scans now bypass the row and tombstone copy for ordinary aliases with no observed recipe or unlearned ID in common. Related entries and metatable-backed data keep the original merge. The modern spellbook predicate matched 471 current Tailoring flags. The legacy predicate missed all 101 learned recipes and the profession predicate marked all 370 unlearned recipes as true. Continue using the full live recipe flags. Lua 5.1 and 5.4 syntax passed across all five installations. The exact native follow-up was released before typing when the host detected a held key. Restock and Tailoring remain open. [Evidence](validation/profession-alias-overlap-2026-11-19.json).


<!-- LHO-PROFESSION-BAG-RESTOCK-20261119 -->
19 November. With Tailoring and Auction Restock open on Forever, moving a stack out and back produced two delayed bag updates and five Restock builds totaling 45.959 ms. A second trace attributed the three additional builds to professions notifications. The three Tailoring handlers took 28.540, 20.529 and 33.149 ms inclusive. Both trials verified the original stack, empty temporary slot, clear cursor and zero new Lua errors. The profession scan now ranks saved aliases only for recipe keys observed in that scan. It still resolves revocations and rank ties across all stored aliases, uses the full public query if another owner replaces it, and preserves normal scans and notifications. Five paired native helper checks matched all 505 current Tailoring recipe references. The median fell from 0.891 to 0.581 ms with the key table prepared before timing. The source matches across five installs and compiled on Lua 5.1 and 5.4. Full event timing needs the candidate loaded. [Evidence](validation/profession-bag-restock-2026-11-19.json).


<!-- LHO-CONSUMABLE-NON-RESTORING-20261119 -->
19 November. On Forever with Baganator and Syndicator, 15 unchanged consumable scans took 36.094 ms total in six seconds. The Combat Grid and consumable binding reads fed the retry loop. Native inspection identified three loaded non-restoring items in the retry queue. The classifier now settles Jungle Remedy and Southshore Stout when their native spells match the verified cure and alcohol effects. It settles Tabetha's Instructions when the complete read-only tooltip matches. Positive classifications run first. Missing and ambiguous tooltip data follow the existing retry path. The extracted candidate guard recognized all three live inputs and left the restoring food control eligible. Lua 5.1 and 5.4 accepted the source across all five installations. The client still needs a suitable reload and a matched passive timing run. [Evidence](validation/consumable-non-restoring-items-2026-11-19.json).


<!-- LHO-RESTOCK-REAGENT-NAME-READS-20261119 -->
19 November. With the modern auction browser open, three current Restock row builds took 10.501, 6.066 and 5.032 ms. The shared target builder took 13.180 ms across those builds. A subsequent trace counted nine visible item-name harvests for three row builds, totaling 2.566 ms. Three paired reads of real inventory returned identical names and reduced native name requests from 207 to 69 per pair. Median for the isolated reads fell from 0.580 to 0.363 ms. FluxUI now shares available native item names within a single Restock rebuild and keeps every discovery pass. Missing values, merchant reads and replacement methods use their original paths. Both Lua files match across five installations and pass Lua 5.1 and 5.4 syntax. Loaded-source and full workflow timing still need a suitable reload. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

19 November. With Restock and Tailoring visible, three complete row builds took 5.926, 5.461 and 5.772 ms. All six visible rows and the hidden vendor row had identical fingerprints. A real count-neutral bag move triggered one delayed bag event and one touched-item pulse. The capture recorded two Restock row builds totaling 21.907 ms, two paints totaling 0.620 ms, one grid count flush at 0.155 ms and ten consumable scans totaling 28.042 ms. The nearby peak frame gap was 72 ms. The spans can overlap and the frame gap has no attribution. The move probe checked the new slots before the bag update and missed its automatic return. A separate native verification confirmed all 18 items restored to their original slot, the temporary slot empty and the cursor clear. Future timed moves must confirm the native slot update before deciding whether to return the stack. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

After the stack was restored, R290 counted 20 natural classifyPendingRead passes in eight seconds with the original tooltip getter installed. The passes totaled 49.612 ms and peaked at 4.486 ms. All retained the published runtime table. Bag generation remained stable, the observer restored its method and BugTabs reported zero new errors. Focus on the normal eligibility and pending-read work. Preserve original getters during attribution. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-AUCTION-USE-FINAL-SKU-20261119 -->
19 November. With FluxUI, BugTabs, Baganator and Syndicator, Forever’s first observed backpack open took 37.14 ms with a nearby 55 ms gap. The auction candidate matched seven ordinary rows at medians of 7.119 ms baseline and 6.514 ms candidate across three mixed pairs. The prior charged-row audit identified two extension compatibility failures from omitting the preliminary calls. The original implementation was restored. R268 observed 14 calls totaling 0.685 ms on the live original source. [Evidence](validation/auction-final-sku-2026-11-19.json).

A five-second Forever capture with FluxUI, BugTabs, Baganator and Syndicator recorded 12 passive consumable validation passes. It made 180 tooltip reads. In the same pass, 72 repeated an identical item ID and link, and the returned text matched on all 72. The pass total was 38.980 ms, the slowest was 3.744 ms and the 180 tooltip reads accounted for 26.765 ms inclusive. The nearby peak frame gap was 36 ms. The probe restored both wrapped methods with stable bag generation and zero new Lua errors. R274 attributed the 24 repeats across four natural passes to the saved-reference fallback. Both R270 and R274 replaced GetTooltipText, which is pinned by Persist.EligibilityOwnersMatch. That change disables existing same-pass reuse and accounts for the repeated checks. R276 kept the tooltip owner intact and observed zero scans in 5.012 seconds with the auction browser open. Preserve the guarded reuse. A normal-path sample with active classification remains needed. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-BACKPACK-FINAL-CALLBACK-20261119 -->
19 November. Open-bag item-index candidate timing was 1.780 to 0.960 ms for two traversals at the median, with all 55 visible buttons matched. The running Forever build then reproduced a 169 ms first-open frame gap. A 98.63 ms interval on item 6172 ended before Baganator checked the item spell. Six isolated warm native item reads were individually under 0.2 ms and the optional unusable-item tooltip branch was disabled. The cold-path source of the interval remains open. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-ITEM-REGISTRATION-INDEX-20261119 -->
19 November. Baganator’s closed-bag traversal scanned 5,621 skin registrations to find 550 item buttons. Indexing those positions cut the median cost of four warm visibility passes from 2.773 to 1.330 ms and retained the registered button sequence. Visibility remains a live query. The running bank index separately reduced the full shared closed-commerce Restock rebuild from 14.899 to 3.330 ms at the median. All nine rows matched. Overall FPS and the first-open frame spike remain unverified on these timings. [Evidence](validation/baganator-item-registration-index-2026-11-19.json).

<!-- LHO-BAGANATOR-BANK-VIEW-INDEX-20261119 -->
19 November. Closed-bank status queries repeatedly walked Baganatorâ€™s full skin registration list. One Forever capture found 5,696 registered regions for two bank views. The indexed candidate reduced the median shared Restock target rebuild from 13.565 to 2.817 ms. Three alternating native pairs matched all nine rows. The change has no new refresh timer. R244 and R246 confirmed after-reload adoption. In-game bank open remains pending. [Evidence](validation/baganator-bank-view-index-2026-11-19.json).

<!-- LHO-PARSER-VENDOR-LIVE-20261119 -->
19 November. The live vendor reader retained its warm lookup improvement after reload. The 209 ms backpack frame gap reproduced without addon loading. The passive retry averaged 6.17 ms and peaked at 9.52 ms across seven calls. The after-reload sample leaves whole-retry improvement unverified. A separate 23.83 ms closed-AH rebuild spent 21.26 ms in the shared target builder. Charge metadata accounted for 0.99 ms across 20 calls in that same trace. These spans overlap. [Evidence](validation/parser-vendor-live-2026-11-19.json).

<!-- LHO-RESTORE-PARSER-PATTERNS-20261119 -->
19 November. Two parser changes skip duration patterns with impossible literal matches and potion floor scans on lines lacking the matching resource. They preserve native settings, inventory updates and tooltip retries. Live isolated helper medians went 4.87 to 0.60 ms per 288 duration checks and 1.43 to 1.03 ms per 64 potion floor reads. Full idle retry and frame-time improvement have yet to be measured. [Evidence](validation/restore-parser-patterns-2026-11-19.json).

<!-- LHO-LIVING-CONSUMABLE-RETRY-20261119 -->
19 November. Forever's periodic consumable retry still cost 5.61 ms on average and 7.04 ms at peak across eight live passes in three seconds. This timing kept tooltip and eligibility owners intact. The separate caller count replaced a tooltip function guarded by Persist and can overstate the normal eligibility work. [Evidence](validation/living-consumable-retry-2026-11-19.json).

<!-- LHO-VENDOR-FIELDS-ONCE-20261119 -->
19 November. The vendor display helper now reads ready item metadata once when C_Item.GetItemInfo and GetItemInfo resolve to the same function. The exact edited reader matched all four fields for 42 actual carried items and reduced the median from 4.3233 to 2.1802 ms per 336 reads in three paired Forever trials. Overall frame time and actual merchant repaint impact still need native validation. [Evidence](validation/vendor-fields-once-2026-11-19.json).

<!-- LHO-BACKPACK-SINGLE-SLOT-20261119 -->
19 November. A single item-detail call accounted for around 100 ms in both observed cold backpack opens. The second trace measured 96.94 ms between return from BGRUpdateQuests and entry into BGRUpdateCooldown on item 6172. The Lua heap grew by 8,779.6 KiB during that call. The code interval includes new-item animation, item decoration, plugin callbacks and item spell lookup. No module-load attribution has been established. [Evidence](validation/backpack-single-slot-2026-11-19.json).

<!-- LHO-RESTOCK-SETTINGS-GET-20261119 -->
19 November. The native paired settings getter median fell from 2.7274 ms to 1.9019 ms per 10,000 reads. The 88 Junk verdict positions matched, with variable paired total Junk times. The first-open backpack gap reproduced after reload with profiling preferences preserved. The closest native LastTime sample reported FluxUI 0.05 ms, Baganator 5.85 ms and total addons 5.96 ms against a 161 ms application frame. The profiled application counter advanced by one over 50 ms, and the sampled addon counters remained flat. The residual hitch still needs native attribution. [Evidence](validation/restock-settings-get-2026-11-19.json).

<!-- LHO-ITEM-INFO-ONCE-20261119 -->
19 November. The shared item loader avoids a redundant C_Item.GetItemInfo query when building a record from a tuple. Three paired tests with 42 actual carried item IDs cut median elapsed time 45.8 percent across 336 forced record builds with native item data ready. Every field matched the baseline. After reload, all 42 production records and counts matched. This measures the record-build path. Frequency on live workflows and frame impact remain open. [Evidence](validation/item-info-once-2026-11-19.json).

<!-- LHO-BACKPACK-FLUX-COMPAT-20261119 -->
19 November. With Syndicator and Baganator active, the first category backpack open took 150.21 ms with a 161 ms frame gap. The warm open took 5.77 ms. Baganator Display contributed 123.88 ms inclusive. Across the first open, the timed FluxUI calls were 102 Junk checks at 3.79 ms and one view lookup at 0.03 ms. The other selected category and protection callbacks did not run inside the synchronous open. Both closes succeeded and all wrappers restored with zero errors. The first-open hitch still needs deeper attribution. The probe covered synchronous opens only, so deferred work remains open. A delayed follow-up after reload 201 kept the host screenshot capture outside both timed opens. The first open still took 151.67 ms with a 169 ms frame gap. The warm open took 5.14 ms. The backpack returned to its closed state and the probe produced zero new errors. [Evidence](validation/backpack-flux-compat-2026-11-19.json).

<!-- LHO-CONSUMABLE-TOOLTIP-DURATION-20261119 -->
19 November. Removed repeated tooltip string scans in food and drink classification. The measured predicate cut 12.4 percent from the median batch on nine real pre-read tooltips. All nine verdicts matched, including all three previously pending items present in the sample. One loaded parser read on each side of reload returned matching digests. The sample ran while the character was a ghost. Living passive retry and frame-gap benefits remain unmeasured. [Evidence](validation/consumable-tooltip-duration-2026-11-19.json).

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

<!-- LHO-CACHED-REJECTION-BUDGET-20261118 -->
18 November: edited actual Inventory/FluxConsumableClassify.lua (2718aaba) and FluxConsumableBest/Scan.lua (8f9ebfdb), on main. Addon-private defining-owner/cache query exempts only already-loaded, exact cached false classifications from budget decrement while budget remains. Still calls ordinary classifier; actual candidate/parse work stays capped24. Exhausted-budget queue path, retries/cadence/live counts/ranking/render bodies unchanged. Replaced Classify/IsPending, metatables or absent private record keep old accounting.8before/after Lua5.1/5.4 syntax jobs PASS; removing only new chunks restores both entire baseline files after LF normalization;24Retail/Forever pairs match. External history bundle verified;12FluxUI settings stat records and byte-exact source checkpoint external, no private contents copied. Native before: generations1918to2152 in186.240s with bagGen10 unchanged, pending load0 and classify queue2to3; contexts flight then vendor, so no controlled idle CPU/FPS inference. IB24 nineteen consumable IDs/47cached negatives across whole bag set, overlap unmeasured. No new simulation/mock. Timing24 setup expired0calls; late arm diagnostic assertion preserved, original method untouched.25arm never succeeded;26batch source-only abort. Native CPU gain unproven. NEW LUA NOT LOADED/NOT NATIVE-TESTED yet. Next guarded reload/adoption and actual queue/selection/count/replacement checks; preserve both grids and all clients. Jump host39428 is STOPPED since11:18 on stale heartbeat, after2successful FG/BG key pairs; current process absent. Restore helper with explicit pause/goal stops and auth lifetime that survives long agent/tool waits; do not claim running yet. Goal ACTIVE.
[Evidence](validation/inventory-cached-rejection-budget-2026-11-18.json).
<!-- /LHO-CACHED-REJECTION-BUDGET-20261118 -->

<!-- LHO-JUMP-RESTORED-20261118 -->
18 November jump reminder: current external r5 periodic host PID39428 RUNNING. Supervisor48892 observed native BG red advancing counter and launched the host, then exited. Interval180s after completed pair; latest state linked below. It waits for15s PC idle and fresh readiness before each jump. Due jump stays queued while chat/scripts, casting/crafting, movement or taxi flight blocks it; all actual Space requires original fresh GREEN + chat-open red/heartbeat-green acknowledgement and shared input.lock. First Space pair not yet accepted at this receipt. User currently on taxi (~11min remaining at last photo), so red/queued is expected. Old helpers25000 and49400 stopped with0pairs; do not revive them. Apparent UI restart cleared old cue after earlier vendor checks. New RAM cue _J19q/j18n5p8: first24 setup packets fully queued, Ctrl in packet gap stopped before25; batch terminal, not replayed. Actual INIT true viewed; separately sent only missing enable command, new J83CUE visually ACKed. No addon Lua/settings/item actions. Idle activation/minimized restore paths preserved; native activation repair and first jump remain pending. Stop promptly via P4/CANCEL on pause; verify helper exit and perform requested guarded reload. Reload clears cue; reinstall fresh when continuing. Refresh native/agent-heartbeat every5min during active work;600s stale heartbeat stops it. Inventory24 unchanged; VC24 nine-row2.313ms/empty VR24.115ms remain scoped pre-restart single samples without paired FPS benefit. Goal ACTIVE.
[Evidence](validation/inventory-jump-restored-2026-11-18.json).
<!-- /LHO-JUMP-RESTORED-20261118 -->

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
18 November: preceding23 real fallback/readiness verification completed on
Forever70959/16001/project18. Normal and forwarding-fallback GetBagOwnedTier(food)
both return1338/item4601; final1487 counts0/0, ready syndicator, both external
addons loaded, profile0/errors0. Single behavior check, no matched timing claim.
A subsequent source review found the earlier vendor copy reduction exposed retained
ordinary rows to a replacement craft-target getter. List030b8a41 now borrows only
through AuctionCraft8462442f's private defining-owner/dependency check; replacements,
missing contract and metatable rows receive shallow copies. Canonical default
savings remain, with a small ownership-check cost. Existing craft body unchanged.
Eight Lua5.1/5.4 syntax checks PASS;24 source pairs match. Native24 acceptance
PENDING normal reload/vendor and real craft routes. No simulation or extra
native input for this edit; preceding23 results are explicitly separate.
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
18 November: added a fresh numeric bag-count view for the canonical restock
bag-query chain. Tier owned-reference, junk candidate, current tier-count and
bank-restock bag-total queries no longer build discarded per-ID location rows.
Public getter replacement keeps original record behavior; no persistent cache,
zero memoization, native/live walk removal or delayed selection. For N>0 IDs,
source accounting removes N temporary tables per reached query, allowing for
the new lazy link-read side map. This is not measured memory/CPU/FPS evidence.
Three Lua edits;12 Lua5.1/5.4 syntax checks PASS, exact body-conservation proof
PASS,23 Retail/Forever source pairs match. No simulations or native input.
Last21-file native reload evidence is separate;23-file reload, actual counts,
provider overrides/combinations, vendor/bank/craft paths and spikes pending.
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
17 November first direct-batch native smoke:15source identities match Forever
disk and fresh combined gate passes30syntax compiles. Guarded reload observed
loading then world plus21:16:03UTC saved-file timestamps. Live70938/16001 with
Syndicator+Baganator reportsreadytrue/scriptProfile0. BugTabs current captured
count0; actual query50IDs/0symmetric key mismatches. Neither result is a CPU/FPS/
lag-spike comparison or complete feature/taint/pixel acceptance.

Keys' image was viewed immediately but later formal ACK was stale-refused;
record it as observed-only. BugGrabber's no-marker attempt is unconfirmed.
Status/post/BugTabs bounded ACKs succeeded. No actor/input lease remains; no
persistent game probe/jump helper installed and no commerce/item/cast actions.
[Evidence and remaining scope](validation/inventory-native-direct-smoke-2026-11-17.json).
<!-- /LHO-NATIVE-DIRECT-SMOKE-20261117 -->

<!-- LHO-POTION-PATTERN-SETUP-20261117 -->
17 November direct parser setup: Classifyd7037d85 prepares2generic and40fixed
potion-range/upper pattern strings at load (source-derived structure only).
Runtime still matches each line in original suffix/range order and uses unchanged
maximum/factor/duration/tolerance/minimum logic. No tooltip/native read or match
is skipped. Fixed private storage/setup replaces repeated concatenation.
2syntax-only checks pass; current15source hashes stable. No CPU/GC/FPS/native
acceptance is claimed and no new simulation/benchmark ran.
[Record](validation/inventory-potion-pattern-setup-2026-11-17.json).
<!-- /LHO-POTION-PATTERN-SETUP-20261117 -->

<!-- LHO-CLASSIFY-RESULT-PROFESSION-WORKERS-20261117 -->
17 November direct parser/EBS continuation: food/water and potion result builders
are constructed once, with current parsed/pct/conjured values passed explicitly.
Fresh output records, all8potion/2food-water decisions, resource/native queries,
minimum/maximum/rate data and pending cache behavior remain. EBS profession
refresh reuses one callback per Watch.Start with original0.25s scheduling.

2files/4syntax-only passes; current source snapshot covers15direct-edit owners.
No new model/native cost run or combined functional suite; CPU/FPS/lag-spike
improvement is unmeasured. Older Classify proofs stay attached to their old hashes.
[Record](validation/inventory-classify-result-workers-2026-11-17.json).
<!-- /LHO-CLASSIFY-RESULT-PROFESSION-WORKERS-20261117 -->

<!-- LHO-CAST-BAG-AUCTION-WORKERS-20261117 -->
17 November direct casting/bag/auction continuation: successful-player-cast
matching reuses fixed name/kind workers with the current event spell service
passed explicitly. The original raw argument array and native/preferred-name
reads stay. Bag pulse flushing keeps its0.10s quiet/0.30s maximum wait but no
longer constructs a callback per burst. Syndicator auction flushing reuses its
fixed callback with the same queue/source/publication semantics. Scheduler was
inspected read-only: callback occurrences remain distinct, even with one function.

2files/4syntax-only checks pass. The current direct pass has14pinned owners across
dated records. This is source/syntax evidence only; no new simulation/native
capture, start/interrupt acceptance, CPU/GC/FPS or lag-spike gain is claimed.
The stale-mail measure-first decision remains; mail code is unchanged.
[Exact source set](validation/inventory-cast-bag-auction-workers-2026-11-17.json).
<!-- /LHO-CAST-BAG-AUCTION-WORKERS-20261117 -->

<!-- LHO-FOLLOWUP-COUNT-WORKERS-20261117 -->
17 November direct pending/bank continuation: AH follow-up counts and craft
fallback availability reuse the same authenticated carried-live query already
used by auction rows. Canonical count options are reused; foreign getters keep
fresh original option tables and current selection. Existing reliability/memo,
physical/charge, material-read and craft authorization behavior remains.
Bank snapshot item groups reuse one private comparator with identical reads/ties.

3files/6syntax-only checks pass. No new simulation or native trial ran and no
CPU/allocated-byte/FPS/lag-spike gain is established. Bank mover idle handler was
not changed: its frame is already hidden while idle. Old FluxInv queues are
unloaded by the current TOC.
[Record](validation/inventory-followup-count-workers-2026-11-17.json).
<!-- /LHO-FOLLOWUP-COUNT-WORKERS-20261117 -->

<!-- LHO-KEYS-ONLY-CONSUMERS-20261117 -->
17 November: three keys-only consumers now reuse the existing trusted fresh-ID
query: Best.Scan bag enumeration (including conjure priority), Craft's unresolved
reagent-name search and login bag counting. This avoids constructing unused item
record rows on the owned route, retaining original snapshot count/link reads.
Public overrides and foreign/copied helper owners retain their original route.

C1's old native51-ID allocation/key parity is a mechanism lead only; current
Index and consumers have newer hashes. No current CPU/GC-pause/FPS improvement
or universal small-inventory allocation win is claimed.6syntax-only passes cover
these3new source hashes. No new simulation or native test was run.
[Exact identities and pending scope](validation/inventory-keys-only-consumers-2026-11-17.json).
<!-- /LHO-KEYS-ONLY-CONSUMERS-20261117 -->

<!-- LHO-DIRECT-INVENTORY-RESUME-20261117 -->
17 November resumed direct Lua work: shared Index location queries now consume
the existing normalized flag scalars instead of allocating private option rows;
canonical unique defaults reuse the existing private empty options table.
Location walkers are built once and receive the current callback explicitly.
Restock charge scans reuse protected tooltip workers and per-line getters with
an explicit current data context. Every returned/emitted row remains fresh;
native reads, filters, metadata/cache behavior and update timing are preserved.

Late commodity-offer/tooltip comparators and legacy spell-reagent workers are
also now fully recorded. The earlier native Scan spans identify a broad lead,
not exclusive attribution or acceptance for these sources.14syntax-only passes
cover7current files; no new simulations or performance measurements ran.
[Exact before/after identities and limits](validation/inventory-direct-resume-2026-11-17.json).
<!-- /LHO-DIRECT-INVENTORY-RESUME-20261117 -->

<!-- LHO-PENDING-READ-RUNTIME-20261117 -->
17 November: the actual Best pending-read path now avoids repeated full unique
walks only while the completed publication and guarded inputs remain unchanged.
Unresolved metadata is still queried; resolved items, invalidations, changed
inventory or public replacements rebuild normally. Real read demand retains
generation/listener publication; stopping demand returns to ordinary capped
pending followups. ItemClass also reuses its private protected tooltip worker.

Final installed validation passed 22,400 assertions plus eight compiles across
28 jobs. P87's older native getter counts explain the lead but do not measure
this source's gain. No new CPU/FPS or loaded-source acceptance is claimed;
casting, bag, vendor/AH, bank/mail and client/provider workflow work remains
open within the existing scope. [Validation](validation/consumable-pending-read-runtime-2026-11-17.json).
<!-- /LHO-PENDING-READ-RUNTIME-20261117 -->

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

<!-- LHO-WORKFLOW-DIAGNOSTIC-P84-20261117 -->
17 November: P84 is EXTERNAL/PREPARED. The six-envelope body passed31mock cases/1,272checks perVM (54pins). Actual builtin/Syndicator routes passedR1 two pairs/four contexts/62checks perVM; R2 adds the missing direct observer-row proof:88checks perVM/130pins, current and automaticpost entered=completed=valid [1,1,1,0,1,0]. Same-VM selected query/callback order and state match. R1 raw cross-VM listener-order/metadata-overassert history stays preserved; no model rerun.

Root formally ACKed dated P84CTX: Forever1.60.1/70938/16001, Syndicator ready, Food Button table, both selected roots absent. This was one pure253-character status command; NO P84 OBSERVER TYPED and NO FOOD ACTOR as of that snapshot. Root archived/released its short CTX holds and reports helperB5872 resumed; INPUT_HALTED remains. This is readiness, not native event delivery, loaded body adoption or FPS. Existing jump launch/history is unchanged and was not inspected by this draft.

Goal ACTIVE; P83 stays REJECTED/UNAPPLIED and ConsumableBind7d758903 is unchanged. Native protocol proof is pending. Count tracing covers first3 native arguments only; full EBS/Bars eval dispatch, private heavy queue and upstream Syndicator remain unqualified. [Evidence and pending native gate](validation/inventory-workflow-diagnostic-p84-2026-11-17.json).
<!-- /LHO-WORKFLOW-DIAGNOSTIC-P84-20261117 -->

<!-- LHO-NATIVE-PAINT-P83-COST-20261117 -->
17 November: P83 is REJECTED/UNAPPLIED; ConsumableBind remains7d758903. The fixed28-child/four-profile batch supersedes the22-child proposal: retained-zero CPU796.875→875ms (+9.8039%,2of3pairs slower) rejects despite other wins and64B/unit51/56B54 transient-GC savings. R3 admissions passed500checks/VM; R1 startup-timer and R2 depletion-to-nil setup failures remain preserved. All raw regressions, intercepts and retention deltas are linked below; no retiming or P83 runtime application.

Root accepted passive30.018s and separate120.016s leaf windows. The latter contained Food caststart; orange bread/A-D showed13 before/active and27 in the first later image AFTER expiry. Displaydelta14 proves no exact item/produced quantity or in-window finish. Late actor ACK remained STALE/false; no recast/restamp. Both captures have formal cleanup. Inclusive overlapping spans prove no matched gain, exclusive Food cost, loaded-byte adoption or FPS result.

Goal ACTIVE: prioritize whole cast/craft/bag→EBS/Bars and restock workflows plus provider/client/bank/mail gaps. PaintOne/CountOne is an unbuilt one-closure-per-PASS lead, not per widget; extra arguments can regressCPU. Preserve stale-mail USER-MEASURE-FIRST, simulation-only commerce and guild/void exclusion.
[Exact costs, native limits and corrected chronology](validation/inventory-native-paint-count-cost-2026-11-17.json).
<!-- /LHO-NATIVE-PAINT-P83-COST-20261117 -->

<!-- LHO-EBS-COUNT-OPTIONS-P82-P83-20261117 -->
17 November: goal ACTIVE. P82 baselined the actual loaded ConsumableBind owner in8 contexts/216checks per stock51/54 VM. P83 remains EXTERNAL/UNAPPLIED with cost pending: its private options/freeze scalar change passed8paired contexts/440checks per VM and12unchanged consumer runs. Each baseline/candidate VM has5,059 consumer checks; complete same-VM outputs match. The focused public/state/error/flag traces match, including actual bag-event→Inventory.Notify→light listener delivery, face/hold/reliability ordering, opaque errors and reentry.

Ten private default constructions become zero in the focused protocol; eight supplied private tables are harness inputs, not eight claimed production allocations. All27escaping public option tables per variant remain fresh. Constructor counts establish no heap/CPU/FPS gain. The fixed22-child CPU/GC proposal is accepted for source preparation only; no cost batch or addon Lua application has occurred.

Root observed F81A readiness on Forever1.60.1/70938 with _FluxUI, Syndicator and Baganator loaded. This is readiness only, not exact loaded-source adoption or performance acceptance. Root owns native and separate jump receipts. The full LHO01–13 goal/native gaps remain open, including representative cast/craft/bag whole-event attribution, restock lifecycle, provider/bank/mail and requested client expansion.
[Exact proof, private/public limits and remaining coverage](validation/inventory-count-options-2026-11-17.json).
<!-- /LHO-EBS-COUNT-OPTIONS-P82-P83-20261117 -->


<!-- LHO-BURST-BASELINES-P77-P78-P80-20261116 -->
16 November: goal ACTIVE. User permission for in-game testing is restored; Root alone owns fresh guarded inspection/input. Status attempts A-D entered no command; later E also stopped before input when foreground became unknown. The A-D receipt stays historical; no fresh loaded-status, client-exit or native performance result is inferred.

P77 public AH reuse traces match for two N1/N25 cycles (7/103 forced builds;19/5,551 modeled item calls per cycle). Its fixed16 desktop cost gate passed: CPU medians-9.375%/-0.6024%, the latter one15.625ms tick. N25 pair2 +31.25msCPU/+62mswall, N1 pair3 +16mswall, positive GC slopes and prepared retention+3642B51/+2967B54 remain recorded. This is whole-child modeled CPU/GC, not native FPS or event-exclusive CPU.

P78's corrected9case/281check baseline per VM distinguishes9GetRows calls from1forced rebuild. The second resolver observes later metadata, public-list edits and raw errors; blind skipping is unsafe. Earlier fixture/metric failures stay preserved; no candidate.

P80 passed functional and corrected quiet admission proofs, then failed its fixed34job cost gate: small-lifecycle median is flat but2/3 CPU pairs are slower. Distributed/warm wins cannot override it. Cold GC/retention increases and no-pending wall+13.13% remain visible. Candidatefba020 remains external/unapplied; actual Init98d3 and applied Index80acf are unchanged. No addon Lua changed in this slice. Keep this rejected candidate unapplied; investigate the next distinct lead with tests first.
[Exact evidence, regressions and scope](validation/inventory-burst-baselines-2026-11-16.json).
<!-- /LHO-BURST-BASELINES-P77-P78-P80-20261116 -->

<!-- USER-NATIVE-TESTING-RESUMED-20261116 -->
16 November: the user explicitly permitted in-game testing when needed ("we can test ingame now if needed"). This permission supersedes historical hold notices below. Root alone owns native inspection/input and must freshly verify the exact client, world/chat state and ownership guards. Buying, selling, deleting and mail actions remain forbidden. Existing jump/chat/crafting locks remain until Root explicitly releases the suitable ones for the current runner. No client presence, loaded-source adoption or performance acceptance is established by this permission.
<!-- /USER-NATIVE-TESTING-RESUMED-20261116 -->

<!-- LHO-INVENTORY-PRIVATE-CALLBACKS-20261116 -->
16 November: P75/P76 are applied after offline behavior and fixed-cost gates. USER native hold remains: no game tests, input, queries, captures, jumps or reloads until explicit release. Goal ACTIVE for offline work.

Only two private callbacks changed: slot validation reuses its protected numeric body; inventory change merging reuses its union helper. All validations, native/query reads, fresh maps, callbacks, repaint work and update cadence remain. Twelve first functional jobs passed: P75 32paired/235checks per VM plus unchanged65check visible-bag regression B/C; P76 8groups/45checks per VM plus unchanged263check passive-inventory regression B/C. Existing same-VM output is byte-identical.

Fixed44cost jobs passed with80pins stable and all children reaped. Whole-child stock51 CPU medians: slot valid-50%,nil-58.14%,throw-29.41%; merge countOnly-25%,mixed-15.38%. Populated identity is+4.545%(2slower/1faster), retained below its declared5% rejection gate. Paired allocation savings136B/slot check and40B/merge hold at both1000/2000 windows on51/54. Shared54 first-window floors and retained startup increases(+148/+150B slot,+91/+62B merge) stay recorded. These are conditional leaf models, not native FPS or whole-workflow timing.

The addon source files now match the exact tested candidates; no client reload/input, temporary code, settings, external addon edit, manual sync or publication occurred. Loaded adoption and other installations were not checked. Native/whole-client acceptance remains pending. [Exact sources, all samples, contract boundaries and regressions](validation/inventory-private-callbacks-2026-11-16.json).
<!-- /LHO-INVENTORY-PRIVATE-CALLBACKS-20261116 -->

<!-- LHO-AUCTION-CLOSED-DEFINER-P73-P74-20261116 -->
16 November (`LHO-AUCTION-CLOSED-DEFINER-P73-P74-20261116`): USER HOLD: no in-game tests, live queries/testing captures, game input, jumps or reloads until the user explicitly permits them. Offline goal ACTIVE; generic continuation or offline success never releases this hold.

P74 applied the three tested Retail files at19:46:44UTC. The later19:52:16UTC read-only check matched all15 files across five primary installs; other folders have independent identities and updated externally between observations. Propagation mechanism is unproved; Root performed no manual sync. Loaded-client adoption remains unverified. Extra beta is unchanged/older and not certified. Focused16/683 per VM, four whole-row pairs per VM(51:10,646checks;54:10,346) and16 unchanged regression jobs passed. New fixed cost16jobs found owned CPU median-11.5385%(3wins), foreign+4.1667%(2one-tick losses/1win), below its declared rejection gate. Qualified GC savings retain startup+3842B51/+3167B54 and observed54intercepts; no native/full-workflow CPU or FPS gain is proved. P73 baseline12contexts passed536/535checks, with manual/tier/merged/craft default counts2/0/0/5; arbitrary iterator retention/order/errors block an assumed-pure shortcut. No P73 candidate or cost run. Original P72 remains REJECTED with its own untouched trials; P74 uses separately changed code and new samples. AH natural limited-zero6builds+6reopen remains dated UI-reachability evidence, not user/native frequency; no cached-row/query-pruning claim is revived. [Exact sources, proof and limits](validation/auction-closed-definer-options-2026-11-16.json).
<!-- /LHO-AUCTION-CLOSED-DEFINER-P73-P74-20261116 -->

<!-- LHO-AUCTION-NIL-TIERS-P73-20261116 -->
16 November P73 source-only finding: ordinary provider rows and new craft ingredients can retain nil `tiers` through GetRows into Need's `ipairs(row.tiers or {})`. Actual tier merges attach arrays; saved/native prevalence is unmeasured. No candidate or model/cost run exists. Baseline manual-only, tier-only, merged and craft-material paths before changing this loop, including iterator selection before the tiers getter, proxy iteration and raw errors. P72's residual64B51/48B54 is not isolated attribution or a CPU/FPS gain; global iterator purity must not be assumed.
<!-- /LHO-AUCTION-NIL-TIERS-P73-20261116 -->

<!-- LHO-AUCTION-BASELINES-P70-P72-20261116 -->
16 November (`LHO-AUCTION-BASELINES-P70-P72-20261116`): P70 actual limited-zero UI toggle/reopen each caused six forced builds in modern/legacy N1 models; free owned craft at cap0 remained valid. P70 passed6/131 and P71 passed6/251 per stock51/54 VM, with exactly two first jobs per stage. P72 is REJECTED/UNAPPLIED:12paired scenarios/546checks per VM preserved logical/native traces and opaque-error identity, while generated field/local error wording differs and is retained. Fixed cost16jobs found owned CPU359.375to421.875ms median(+17.3913%),3/3slower, breaching the declared rejection rules; foreign median+4.1667% retains one slower/two ties. Qualified GC savings do not override rejection; startup retained growth was+5973B51/+4998B54. GC51owned/empty two-point slopes448to64B/Need and54owned264to48/empty296to48 retain raw points and nonzero/different intercepts; foreign/no-api controls are unchanged. These model counts/whole-child costs establish no native FPS/spike attribution. P67 attempts1g/1h/1i sent zero packets and never staged/armed the observer;1g preinput reason remains unknown,1h was rejected before journal, and1i user logout countdown was left untouched. Goal ACTIVE; own holds remain and any native attempt requires fresh client/world/closed-chat/ownership checks. [Baselines, rejection and native limits](validation/auction-limit-live-options-2026-11-16.json).
<!-- /LHO-AUCTION-BASELINES-P70-P72-20261116 -->

<!-- LHO-BARS-USABLE-CLOSURE-P69-20261116 -->
16 November P69 (`LHO-BARS-USABLE-CLOSURE-P69-20261116`) APPLIED at17:27:37UTC: `Bars/Paint.lua`7b6273f replaces the per-eligible-host usable-paint closure with one private helper; three call sites preserve queries, captured palette/charge state, features and cadence. Pipeline6cases/642checks per VM matched36,072 paired scalar fields total; focused16/361 each VM and existing54stress86,872checks per source passed. Read-only postcheck matched11expected pins and5installed file identities; loaded-client adoption remains pending.

Modeled leaf whole-child CPU medians improved19.0476% (one host) and13.6364% (57 hosts). Empty/OOR CPU medians tied; wall medians regressed10.6383%/5.6391%, including empty pair3CPU+31.25ms. All pairs remain recorded. GC slopes51:200to0 and54:192to0B/call retain the qualified128B54window floor. The R1before-work harness failure is preserved. No native FPS/spike/retained-heap/full-workflow gain is proved; five model labels/providers were distributed, not a native factorial. P67 remains prepared and never installed natively; the goal stays ACTIVE. [Exact proof, all costs/regressions and remaining native limits](validation/bars-usable-closure-2026-11-16.json).
<!-- /LHO-BARS-USABLE-CLOSURE-P69-20261116 -->

<!-- WOWSIM-STOCK-READINESS-20261116 -->
16 November WowSim stock readiness (`WOWSIM-STOCK-READINESS-20261116`): the isolated stock load timed out at30.016s without health output. A separate global2M-instruction diagnostic reached texture creation during login; it does not identify the timeout cause or prove an infinite loop. WowSim needs explicit fixtures/bootstrap compatibility work as a supplementary route under the active goal. Empty API defaults and missing XML/security/secret behavior cannot establish native FPS, GC or pixels. The final P67 R3/protocol desktop-tested55-packet observer remains prepared, never natively installed in this sealed checkpoint; native attribution is pending. [Bounded results, exact proof identities and limits](validation/inventory-native-current-checkpoint-2026-11-16.json).
<!-- /WOWSIM-STOCK-READINESS-20261116 -->

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

16 November (`LHO-SYNDICATOR-BANK-ROW-REUSE-P55-20261116`): unchanged
partial Syndicator bank rows now reuse immutable records behind exact owner/helper
identity. Foreign exposure revokes reuse until reload; late shared rows detach
before the original public callback. Containersd043/Adapter66b8/testfc8d are applied.
Whole-child CPU models improve12.61%/14.29% for unchanged/one-changed98rows;
transient slopes save21,952/21,728B per callback. All-changed CPU+0.67% and
revoked-fallback+2.50% remain; small8's second pair regresses, foreign is mixed
and full-path timing noise is unattributed. All raw controls/lateN1 are retained.
Captured8/37,612+1121syntax and actual5/847+owned51/54+15disk hashes pass;
359component pins are exact. No new full sweep/native P55 adoption/FPS proof.
[Exact sources, paired samples and limits](validation/syndicator-bank-row-reuse-2026-11-16.json).

16 November (`LHO-SYNDICATOR-PARTIAL-OLDROWS-20261116`): partial Syndicator
bag/bank rebuilds now capture first presence in the existing subtraction pass,
removing one old-row walk. Adapter8ce1a745/test702faa13 are applied; full routes,
public callbacks, persistence, notifications, data and cadence remain. Whole-child
CPU models improve6.67%/8.11%/9.00% on three partial shapes; all allocation slopes
match. Full-control pair2 +4.7619% CPU/+3.9989% wall and foreign CPU ties remain.
Frozen421/1110, captured focused10/81,363+1111 syntax and postapply4/815 plus owned
5.1/5.4 syntax/10 disk hashes have distinct scopes. Newer unrelated edits are
preserved; no current whole full PASS/native adoption/FPS gain. Goal stays ACTIVE.
[Source, controls and native limits](validation/syndicator-partial-oldrows-2026-11-16.json).

15 November21:26:58UTC (`LHO-PROF-ALIAS-REMOVAL-20261115`): Professions now
records explicit owned removals in the existing unlearned output map during its
first alias pass, replacing the per-negative-ID membership rescan. No scan/native
query, public callback, publication, update cadence or saved-data contract is
removed. Unknown/foreign/closed data remains conservative; legacy facts remain.
Original748cff40→e096bf70 and durable04f156c4 passed the external420/1,109 gate;
post-apply actual projection/four focused2,040checks and owned51/54syntax pass.
StockLua5.1 models show FIRST/REPEAT M1000 whole-child CPU-28.67%/-65.24%; M0
median unchanged, no-owned+2.27%CPU/+3.34%wall retained (includes owned warm/setup).
All five allocator-growth slopes match baseline, including59,768B/event when all
64cached recipes are removed; superseded/unapplied R1's+5,120B stays recorded.
These are conditional desktop models: Forever defaults unlearned visibility off
and requires the native frame ownership gate. Native source adoption, FPS/spikes
and complete workflows remain pending; the full lag goal stays ACTIVE.
[Evidence, limits and preserved R1 costs](validation/profession-alias-removal-2026-11-15.json).

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
[R8 data comparison and design limits](validation/lag-hotspots-empty-mailbox-2026-11-14.json).

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
[R7 current-only evidence](validation/lag-hotspots-native-attribution-2026-11-14.json).

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
[R6 native evidence and exact source](validation/casting-equality-work-2026-11-15.json).

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
[Exact bank visibility evidence](validation/bank-effective-visibility-2026-11-15.json).

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
[Exact cast equality evidence](validation/casting-equality-work-2026-11-15.json).

15 November 00:09:36CET (14 November 23:09:36UTC): reagent-name lowercase reuse
is applied after exact-source replay and independent review. Full post-change
integration passes **388 scripts / 1,076 syntax checks**, with all source
identities stable. One extracted-test dependency was corrected; its independent
legacy oracle still rejects the blocked C0 getter regression. Native after-validation for this new slice is NOT RUN.
The full casting/inventory goal and all remaining requirements stay ACTIVE.
[Current lowercase-work evidence](validation/reagent-name-lower-work-2026-11-15.json).

14 November 22:20UTC resumption: the full casting/inventory goal is ACTIVE.
The fresh item-ID query correction C1 is applied after independent review,
pre-edit comparisons and a fresh source/history checkpoint. Its C1 integration
passes **387 scripts / 1,075 Lua syntax checks**, with final identities verified.
The newer tooltip, unit-frame and profession-button work is preserved. The
client reloaded at 22:49:37UTC under an idle/combat/cast/profession-window guard.
Three native same-VM query pairs over 51 IDs allocate 22,464 -> 10,800 bytes;
exact key sets match. CPU medians 0.0608 -> 0.0577 ms are brief uncontrolled
samples; no FPS or whole-workflow gain is claimed. Source Syndicator and profiler
preferences remain unchanged. All probes used locals; no temporary helper remains.
Native whole-workflow/provider-off/all-client acceptance is still pending.
Earlier pause and C0 records below remain
historical; the rejected C0 version was never applied.
[C1 requirements, exact sources and remaining acceptance](validation/passive-inventory-item-ids-2026-11-14.json).

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

14 November 2026 — `LAG-HOTSPOTS-20261114`. This is the current broad task,
not completion of the older passive-only passes. The user requests finding and
fixing lag and spikes throughout casting, restock, auction, pending actions,
crafting, buying/selling, inventory providers, banks, mail, loot and bag updates.
Features, appearance, update speed, integrations, commands and saved data must
remain. Newer source recovery, r27 shortage preparation, minimum potion restore,
independent upgrade choices and explicit per-purchase input are the baseline.

Current resumed checkpoint: **390 scripts / 1,078 syntax checks pass**,
with all Lua stable throughout the current bank visibility run. The crafting,
catalogue, notification, C1 fresh-ID, primitive-name and Cast equality changes
remain. Bank effective visibility is applied; guarded Forever bundle reload
and the specific false-bank-access native acceptance pass. Current raw Cast
callback attribution and Food cancel/completion pass; matched
native cost and full workflows stay pending. Main is
`6b444eba4573092b57919ee3e497d86d2ebb3ece` plus preserved local work.
R7 retains7same-callback profession spans and1unattributed eval.listener span;
the four evicted slow labels remain unknown. Current-only service timing does
not establish matched native CPU/FPS improvement. Grid source audit is sealed; the duplicate usability lead remains unproven.
Earlier checkpoint counts and observations below remain historical.
[Current source identities and narrow native acceptance](validation/bank-effective-visibility-2026-11-15.json).

## Requirements and acceptance matrix

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

| ID | Required path and preserved behavior | Owner / current evidence | Remaining acceptance |
| --- | --- | --- | --- |
| LHO-01 | Cast start, delay, channel, interruption, rejection, success, stop and completion; player/party/raid/nameplate/button consumers; unchanged live progress and fade timing | R6 is historical. R23/R25 valid current-at-capture windows retain17raw spans;R25 total24.2692ms/max5.8177ms with overlapping owned-method envelopes. R26/R27 Cast5902f1bc is disk-applied;native adoption unverified Native33 scoped current-client Food START/cancel/three INTERRUPTED deliveries/second START/SUCCEEDED/STOP pass;30.007s0>=50ms gaps,1border.junctions15.8371ms callback;watch errors0/0. Exact loaded cast revision unpinned; do not certify R26 adoption. | No exclusive CPU/event-specific maximum or matched gain/FPS. Channels/pet/delayed work/restricted contexts,taint/pixels/controller and other native clients pending |
| LHO-02 | Bag bursts, receiving/looting, live zero/charges, metadata completion and both EBS grids | Current classifier663a539a/paneldc6de0aa adopted through ownreloads. Native32 actual4599x18 relocation/return, generation5to7;18/18count and all53carried IDs match;selected food4599/18/1338,errors0/profile0. Native33 actual received14Conjured Pumpernickel1487;Flux/native14/14,all54IDs0mismatches,generation7->9;selected1487/14/841;no recorded>=50ms gap in30s. Later report-printer1error separate from watch0/0. Queue minimum3c3ba2e5 applied/reloaded;real35/36moves and counts54/54pass,Notifymeans0.57115->0.5208ms in onepair;no causalFPS claim. Final36a7b896 ownreload37/native38 scoped PASS:54IDs0mismatch,selection retained,Notify0.5092/0.4752ms,errors0;bothaddonsloaded. Singlewindow,no causal FPS gain;otherclients/forcedpaths open. Scorec542c20d ownreload39/native40-42:7real fixed outputs equal,3paired scorer samples faster;fullfood query slower/causeOPEN,no FPS claim. Parser689c630a ownreload48/native49-51 scopedPASS:54counts match,classification matches/selection retained,7fixed records equal scorebody,errors0. Local50parse median2.3639->1.7711ms;fullfoodcost/caller/clientcoverageOPEN,no FPS claim.  Current Score13f28db1 adopted58/native60-62:unsupported typed-color query skipped;54counts/selection retained/errors0;first4pass mean6.169875->5.447525ms observed acrossreload,not causal FPS gain;reuse identity retained/notification~0.04ms.  Current Scan94c403db own64reload/native63-68:real23table/158entry paired comparison faster;54counts/selection retained/errors0;runtime reuse retained;fullpass variation overlaps (~5ms);no FPS claim.  Native69-71 current28pins:real4599x18move/automaticreturn;baggen5->7;54counts match;food1487/14/841;postfreshpublicationruntimeidentityretained2169->2170;30.003s0gaps>=50ms/0observedcallbacks>=10ms/peak34ms;errors0/rootsrestored;onewindow/noFPSgainclaim. | This one both-addon relocation window has no recorded>=50ms gap after move starts. Earlier3gaps/2slow callbacks are pre-move border.junctions. Cold/loot/quantity depletion/charges,other-provider mutations,both-grid pixels/taint and matched native gains remain open. |
| LHO-03 | Built-in provider and FluxUI bridge with legal Syndicator/Baganator combinations | Native31 all3legal combos11/10/00 each ready18/18/errors0/profile0. Original character/global flags2/2 and both loaded restored/verified. Native32 both-addon relocation/return all53carried IDs match. Native33 both-addon received-item counts54IDs0mismatches;provider-off mutation coverage remains open.  Native69-71 current28pins:real4599x18move/automaticreturn;baggen5->7;54counts match;food1487/14/841;postfreshpublicationruntimeidentityretained2169->2170;30.003s0gaps>=50ms/0observedcallbacks>=10ms/peak34ms;errors0/rootsrestored;onewindow/noFPSgainclaim. | Actual mutation workflows with provider-off combinations,bank/mail/AH/vendor/crafting authority and other-client native coverage remain open. Older bag UI lifecycle smoke retained at its original source identity. |
| LHO-04 | Bank open/close, character/reagent/account banks, partial updates, moves, final-copy removal, persistence and provider publication | P55 98-row unchanged/one-changed models reduce row churn and preserve bank publication/errors. P52 earlier fused pass and visibility fixes remain dated history. | All-changed/revoked CPU regressions retained; full timing is a control. Native bank open/close, cold-cache, moves and frame spikes remain pending. |
| LHO-05 | Mail show/close, inbox changes, receive/take, attach/send, Open All, pending restock reconciliation and command ownership | Earlier attachment/stale-mail proof retained. R8 actual visible1mail/1attachment/qty3:six exact full/early ID/quantity matches;17vs2reads;data-pass medians0.0663vs0.0697ms,all below1ms | DATA-PASS ONLY;high variation/no CPU gain. Hidden-tail early-stop counterexample unresolved;100real-mails/end-to-end latency and correction trigger/handoff/summaries/variants/pets/predictions/retirement unaccepted;no production fix |
| LHO-06 | Vendor open/close, restock/Junk, limited stock, caps, metadata, buy/sell and acknowledgements | Current paneldc6de0aa coalesces duplicate OnSelect/OnShow After0 rebuilds;earliest callback and metadata/burst delays preserved,source-only guard proof and5.1/5.4syntax PASS. Adopted through own31reloads. Older9row2.313ms/empty-panel.1148ms counts are scoped history. | Current tab first-open/hide-show/reentry/cold-metadata,quantity/craft/bank/sold-row costs and native timing remain open. No agent purchases/sales/deletion;unattended merchant opening must not trigger automation.  Entry review Buy3e0b50e0:private nativeShift skip only;otherwise immediate sell/repair;no unattended open without proved transaction suppression. |
| LHO-07 | AH open/close/search/refresh, modern and legacy paths, shortage preparation, prices, receipts, independent upgrades and no automatic purchase | r27 retained; viewport work117,900 +actions88,620 +geometry11,404 checks;17 controls/three pairs/44 existing scripts; reviewPASS | Native AH timing/pixels/controller/secure VM pending; small-list fixture overhead10–40us disclosed |
| LHO-08 | Pending/follow-up button, stages, readiness, count/tint/disabled state, mail/vendor/craft consumers and idle stop | R29 actual-owner followup model confirms4catalogue builds/feed and8/twofeed sequence;R2 preserves20fullconsumer traces but ordinaryelapsedLuaos.clock+10.74%/+13.61% in5pairs/profile. Heavy-revocation model-12.52% is conditional;general apply REJECTED. No R29 product change Fresh P56 feed4/51 makes5harvests/263names; R1 rejected despite5,082fewer conversions in stress. | R7 profession22–31ms spans remain historical inclusive owner inference;eval.listener owner unproved. Followupcfb392c6 preceding21 no-job query0 targets/errors0 after ownreload; active-job/frequency/after-timing/readiness/interactions and secret/error contract remain open;no whole-workflow/FPS gain |
| LHO-09 | Crafting open/close, legacy/modern recipe facts, saved closed-profession recipes, start/cancel/finish and reagent/output updates | Latest R2 top block and validation: Prof alias-removal e096 applied; 2490 checks/variant, 72 paired observations/720 fields, actual four focused tests/2040 checks. Earlier R29/Craft findings remain dated history. P56 default-rewarm CPU+6.67%/wall+3.46%; no application. Native34 Craft853273d8 removes private client-flag table only;availability/list sizes5/2/9/no-affordable selections match after reload. Single before/after calls vary both ways;no gain proven. Full legacy pending readiness/craft action remains open.  CurrentProfessions9a12130d own75reload/native73-78:single fresh schematic shared per live query;3real learnedrecipes/fullfield/reagent equality;3postpairs9queries0.2428/0.2630/0.2608->0.1901/0.1867/0.2030ms;54counts/selection retained/errors0;29diskpairs;localqueryonly/notFPS. | Native crafting/event-spike acceptance remains pending; no query cache, slower refresh or integration reduction. |
| LHO-10 | All existing target clients; appearance/features/cadence/commands/settings/integrations preserved | Current source24Retail/Forever disk pair checks and edited-source5.1/5.4syntax retained. Forever70959/16001 native31provider counts and32actual bag relocation/return scoped PASS;both profiling preferences and diagnostic history preserved. Native33 Forever70959 Food cancel/finish/receive/count/selection scoped PASS;no allclient/FPS proof. Current Craft853273d8 syntax5.1/5.4/source-restoration proof;26disk pairs match;Forever scoped readiness after-reload PASS. Other native clients remain pending. Queue helper remains pure existingLua/API paths;27diskpairs and5.1/5.4syntax/source restoration PASS;native35/36Forever70959scope only. Final36a7b896 ownreload37/native38 scoped PASS:54IDs0mismatch,selection retained,Notify0.5092/0.4752ms,errors0;bothaddonsloaded. Singlewindow,no causal FPS gain;otherclients/forcedpaths open. Scorec542c20d ownreload39/native40-42:7real fixed outputs equal,3paired scorer samples faster;fullfood query slower/causeOPEN,no FPS claim. Parser689c630a ownreload48/native49-51 scopedPASS:54counts match,classification matches/selection retained,7fixed records equal scorebody,errors0. Local50parse median2.3639->1.7711ms;fullfoodcost/caller/clientcoverageOPEN,no FPS claim.  Current Score13f28db1 adopted58/native60-62:unsupported typed-color query skipped;54counts/selection retained/errors0;first4pass mean6.169875->5.447525ms observed acrossreload,not causal FPS gain;reuse identity retained/notification~0.04ms.  Current Scan94c403db own64reload/native63-68:real23table/158entry paired comparison faster;54counts/selection retained/errors0;runtime reuse retained;fullpass variation overlaps (~5ms);no FPS claim.  Native69-71 current28pins:real4599x18move/automaticreturn;baggen5->7;54counts match;food1487/14/841;postfreshpublicationruntimeidentityretained2169->2170;30.003s0gaps>=50ms/0observedcallbacks>=10ms/peak34ms;errors0/rootsrestored;onewindow/noFPSgainclaim.  CurrentProfessions9a12130d own75reload/native73-78:single fresh schematic shared per live query;3real learnedrecipes/fullfield/reagent equality;3postpairs9queries0.2428/0.2630/0.2608->0.1901/0.1867/0.2030ms;54counts/selection retained/errors0;29diskpairs;localqueryonly/notFPS. | Other native clients,full workflow/rendering/controller/taint/cold data and repeated matched FPS/spike acceptance remain open;native counts are not pixel or all-feature proof. |
| LHO-11 | Exact source/history/settings recovery before runtime edits; preserve newer work | Dated external before/after source files and verified71d1 history bundle;125stat-only settings paths refreshed per edit batch. Current24 pins retained. Fresh queuee42893e4 source/history checkpoint plus12settings stat rows before3c3ba2e5. | No settings contents copied; no new commit/publication/manual sync. Native functionality is separately scoped. |
| LHO-12 | Use existing simulation findings for direct Lua optimization; user now forbids new simulations | User explicitly retired further simulation. New work uses prior evidence, source/compiler checks and actual native observations; rejected P72/P80/P83 remain unapplied. Queue35/36 uses real moves only;0new simulations;conditional source work reduction,not native matched-FPS acceptance. | No new simulation/cost batches. Actual matched native CPU/FPS/spike benefit remains unproven; do not call source allocation reductions measured gains. |
| LHO-13 | Authorized FG/BG tests; prompt pause; preserve input/profiling/items and external addons | Own75reload readiness ACKed/freshstartup viewed;R16host37972 stopped/verifiedabsent. Fresh R17 _J76q/j18n76a7 installed/ACKed,host42332/live20261118q liveverified;owned73/74/78rootsremoved/installedqueryunchanged;preferences/errorspreserved. Useraway:noquestions;onlyintentionaljumpcue remains. | Keep180s timer queued during commands/casts/crafting/unsafe input;15sidle activation/prior-app restore;CANCEL/GOAL_DONE/native JUMP_STOP. Only owned hold/stop markers removed;INPUT_HALTED retained. Motion not visually verified. No buy/sell/delete/consume. |

Guild-bank and void-storage callback bodies remain excluded by the repository
rules; ordinary bank inventory remains in scope. The external Syndicator folder
must never be edited. No foreground activation, clipboard control, publication,
manual client synchronization, automatic purchase or feature removal is authorized
by this optimization task. The user permits testing in the existing foreground or
background client without changing focus; preserve the current input owner and
prohibited item operations. No mock-up is needed because the accepted UI is being preserved. Existing native
keyboard/controller/input owners remain and need separate operation acceptance.

## Fresh item-ID query C1

C1 changes only `Inventory/Index.lua` and `Inventory/SpellReagents.lua`. The
reagent-name harvester previously requested complete fresh unique-item records
while consuming only their keys. It now uses a fresh ID-keyed query for the
inventory/helper pair vouched for by Index in the private addon namespace. Values
are opaque; clients needing counts or locations continue using the unchanged
public `GetUniqueItems` record query. Unknown Inventory objects, copied/replaced
facade helpers and missing capability records retain the original public path.
The facade privately captures its owned Index helper, so a replacement public
Index ID helper cannot redirect harvesting.
The facade and delegated getter are captured once per invocation, preserving
metatable accessor count/order, raw errors and public overrides before or after
consumer loading. No persistent fact cache is added.

Every unconditional name harvest, native name query, metadata read, duplicate
count/link branch, fresh count and scan/update interval remains. In the actual
source fixture with 20 manual restock records and 121 visible IDs, one forced
`GetRows(true)` still makes 21 inventory harvests, 2,541 harvest name reads and
40 blacklist name reads. C1 reduces unused record construction; it does not
remove this N+1 harvesting or establish that the earlier native 40–59ms spans
are resolved. Skipping initial harvests or freezing the first reagent set was
rejected because it loses later-discovered names, changed aliases or public
predicate side effects.

Three alternating baseline/C1 desktop samples run the actual full
`GetRows(true)` path with native APIs represented by counted fixtures:

| Fixture shape: 20 manual records, 121 visible IDs | Baseline | C1 | Scope |
| --- | ---: | ---: | --- |
| Allocation per forced row refresh | 494.914 KiB | 207.477 KiB | GC stopped; 58.1% fewer allocated bytes |
| Provider-off median CPU per 30 refreshes | 79 ms | 70 ms | Lua 5.4 fixture, GC enabled |
| Provider-on median CPU per 30 refreshes | 76 ms | 71 ms | Simulated provider shape, not actual Syndicator replay |

Raw variation is retained. Isolated empty ID queries add about 181 bytes per
call; measured nonempty 7–500-ID queries allocate less. These samples do not
measure native retained heap, GC pauses, frame time or FPS. A separate Forever
70938 same-VM query comparison after idle reload returns identical51-ID key sets:
three alternating pairs allocate22,464->10,800bytes/query (51.9% less). Native
CPU medians0.0608->0.0577ms are brief uncontrolled samples. Profiler preferences
remain unchanged; no persistent diagnostic helper was installed. Native full-row
and whole-workflow cost, provider-off, all-client secure VM, input/controller and
pixels remain pending. No external
Syndicator source or provider publication policy was changed.

The durable `tests/passive_inventory_item_ids.lua` regression checks fresh key
sets, region/alias options, exact record/option reads, reentry and raw errors,
cold historical names, alias migration and an allocation bound at 121 IDs. Its
independent legacy-query oracle checks 34 before/after consumer-load authority
cases and rejects the blocked C0 accessor failure. The complete C1 checkpoint
passed 387 scripts / 1,075 syntax checks. The baseline unique-record query body
is unchanged. C1 capture SHA256 identities are Index
`054731cefbb168b674174d6fdd1e78bced3ec7911f312cbab7392b9d9564afe7`
and SpellReagents
`724e4a406a3bacff5c3183fc62fecda7e0aed7370a18f86b93603b5d1f7508dc`.
External `resume4-20261114T222014Z/followup-data-audit/c1-seal.json` has SHA256
`3ca7a94417368a0127c6742c4f2b03a8f98cb790d96b757518e941b27308df6c`.
[Public evidence, controls and remaining requirements](validation/passive-inventory-item-ids-2026-11-14.json).

## Reagent-name lowercase reuse

Applied at 15 November 00:09:36CET, this slice changes only the existing
`RememberItemName` function in `Inventory/SpellReagents.lua`. For a primitive
string name, it computes the lowercase key once and uses it for the current
blacklist lookup, current name-to-ID assignment and pending-name removal. The
original nonstring branch remains, retaining its two method/getter calls,
side effects, reentry, distinct keys and raw errors. No global cache is added.
Later observations still replace prior alias IDs and learn localized blacklist
names. Unconditional harvests, native/API reads, name history, finalization,
notifications and update/scan cadence remain.

The same actual-source forced-refresh fixture, with 20 manual records and 121
visible IDs, reduces primitive `string.lower` intrinsic calls from **7,663 to
2,581 per refresh**. The 2,581 native name API calls and 21 harvests are unchanged;
these are different work counters. Three alternating desktop comparison pairs
against the applied C1 baseline give:

| Per 30 forced `GetRows(true)` rebuilds | C1 baseline | Lowercase reuse | Scope |
| --- | ---: | ---: | --- |
| Provider-off median CPU | 0.077 s | 0.062 s | Lua fixture; native APIs mocked |
| Provider-on median CPU | 0.082 s | 0.064 s | Simulated provider shape, not actual Syndicator replay |
| Allocation | Unchanged | Unchanged | No additional allocation reduction claimed |

These are new paired samples; their timings should not be combined with the
earlier C1 samples. The C1 empty-query overhead of about 181 bytes and its native
51-ID key/allocation result are unchanged. Native after-lower validation is
**NOT RUN**: no claim is made about native whole-workflow cost, frame time, FPS,
secure input or all-client acceptance.

The durable `tests/spell_reagent_name_work.lua` and independent whole-source
replay cover cold/history names, alias changes, pending/finalization, dynamic
localized Soul Shard names, case/localized bytes, native fallback order and
nonstring errors/reentry. Independent replay passes 1,121 checks in 15 scenarios
and rejects four compiled harmful controls. Full integration passes 388 scripts /
1,076 syntax checks. The older extracted fixtures now supply their private
blacklist dependency; current/prior owners pass and C0 still fails its original
getter regression. No production behavior was changed to accommodate a test.
Applied SpellReagents SHA256 is
`754c85309af3e5019b87619440a871daca3e99e63e75cd5dde65afdf836d2e67`;
regression SHA256 begins `43ebeebc`.
[Exact comparisons, controls and remaining native acceptance](validation/reagent-name-lower-work-2026-11-15.json).

## Checkpoint and current progress

Main stays at `26f886e3ea5371b196ab235d2dace0c156002285` plus newer local work.
The complete external checkpoint is
`lag-hotspots-20261114/checkpoint-20261114T092731Z` under this chat's visualization
directory. Its source ZIP CRC and SHA256 manifest, all-ref Git bundle and immediate
source stability passed. All Lua baseline copies are external. Settings were
inspected as metadata only; no settings restore or quiescent backup is claimed.

`baseline-full.json` and `baseline-stability.json` record 367 passing scripts,
1,055 syntax files, no failures and unchanged source during the run. A missing
PATH/runtime attempt is retained separately; the successful helper prepended only
its own process PATH with the existing Lua 5.4.6 runtime and records binary hashes.
Desktop Lua results do not certify WoW's secure VM, native secret values, rendering,
FPS, retained memory or input. No runtime Lua was edited before this baseline gate.

Fresh source pins resolved once: Retail
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`; Forever
`bebcb6bf309cf41b41bd74f8ca651e6a105b2676`; progression
`e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`; Era
`4192ac60067fc55566182291bc67c85dd9b6794d`; Anniversary
`68e0a2ec559d9761dfc4e7f864c3944f9d758a49`.
These are source versions, not the observed running client build.

## Verified implementation checkpoint

The first six measured slices are implemented across eight runtime files:

| Production workload | Exact baseline | Current candidate | Preserved work |
| --- | ---: | ---: | --- |
| 1,000 cast lifecycles: distinct protected callback functions | 9,669 | 9 | 11,001 protected calls, 1,000 native cast reads and 3,000 text/geometry paints |
| 1,000 button-VFX lifecycles: routing callback functions | 2,333 | 1 | 2,333 routing calls, 1,666 native cast reads, 999 channel reads, 3,334 paints |
| 1,000 warm macro metadata resolutions | 2,000 | 1,000 | Fresh resolution on the next invocation; existing cold link retry |
| 100 dirty-bag updates in a 320-slot built-in bank: Lua pairs iterations | 192,787 | 76,307 | 4,000 native slot reads, 32,000 aggregate-copy and 32,000 persistence visits |
| Same bank updates through FluxUI's Syndicator bridge: Lua pairs iterations | 147,987 | 28,307 | Current provider publication/classification, final-copy removal and update cadence |
| 100 genuinely clean bank refreshes: persistent copies | 100 | 0 | Pending publication debt still retries after errors and nested updates |
| 50 potion row refreshes: need/mail calculations | 150 | 100 | Final calculation follows replacement and merge; standalone replacement behavior retained |
| Same row refreshes: live bag reads | 251 | 151 | Charge, receipt, minimum-restore, source and price policies |
| Mail category scan of 200 nonmatching bag slots: capacity reads | 2,412 | 212 | Initial exact free-slot count and fresh per-slot availability; native QuickAttach safety checks |

Each slice has three alternating exact-source comparisons and matching semantic
traces. The six new tests total 46,482 focused checks per set and reject 57 compiled
harmful changes. One existing timer-fixture extraction follows the new hoisted
reader; its functional timing assertions remain. The combined integration passes
373 scripts and 1,061 syntax files with every Lua hash stable throughout that run.
This is an intermediate current checkpoint: later vendor fixes require new checks.
All 252 appearance/XML/TOC files and 80 options/binding sources remain unchanged.

Independent review reproduced two bank publication failures that ordinary work
tests missed: a failed Store/summary/persistence write after scans committed, and
a failed nested publication caught by an outer callback. The candidate retains
publication debt across failures with a revision guard, preserves error propagation
and allows the original nested call order. Both exact counterexamples pass after
correction. A single protected publication call is an explicit added cost; dirty
refresh still copies the existing aggregate and persists current counts.

An external crafting integration replay covers 120 scenarios across five client
families, two providers and two yields. Its three baseline/current pairs pass 380
checks and retain 280 semantic/work rows each. Partial-output storms and unrelated
cast events do not revive completed work; settlement retains five count reads,
one row read and one paint, followed by one completion hide. This replays the
actual follow-up, craft driver, inventory storm owner and HUD with native/provider
seams modeled. It is not native crafting time or permission evidence.

## Native Forever investigation and rejected experiment

The exact Forever process/window was verified from the desktop host without
activation. The running client reports 1.60.1 / build 70938 / interface 16001,
current auction build r27 and external Syndicator loaded. Profiler preferences
remain `scriptProfile=0`, `maxFPS=120`, `maxFPSBk=30`.

A contextual 30.013-second watch observed 2,152 frames, 3,211 Flux service callbacks,
two frame gaps of 52–55 ms, zero observed Flux callbacks over 10 ms and no new Lua
errors. The nearest recorded callbacks were about 2.3 ms; this does not attribute
the frame gaps to them. Focus/activity and concurrent desktop work were uncontrolled,
so this is not an FPS comparison or whole-addon CPU verdict. Original diagnostic
root identity and profiler preferences were restored and the watch stopped.

The proposed AH paint guards were rejected after native testing. The same protected
getter helper on fresh hidden native widgets took roughly 2.29–2.48 ms per 3,000
settled writes, versus 0.47–0.64 ms for direct setters, in three paired trials for
text, texture, enabled, shown and checked states. Fewer modeled setters did not
mean cheaper execution. Original AH UI bytes were restored exactly; no paint gain
is claimed. The failed experiment, including its one mock raw-field failure and
native contract research, remains external. These tests isolate method/helper
cost, not rendered AH FPS.

The user additionally authorized highest-rank Conjure Food starts/cancellations
and one completion to test item receipt, and explicitly allowed the specific cast
test while WoW stayed foreground. Native spellbook/source queries confirm rank 4 /
spell ID 6129. Initial background guards stopped a partial diagnostic setup; the
user then reloaded, clearing temporary probes and loading current Lua files. After
a fresh window observation, the helper sent four normal `/cast Conjure Food(Rank 4)`
requests and three `/stopcasting` commands without changing focus. Native captures
show Interrupted, one completed creation of eight Conjured Pumpernickel, the food
button updated to eight and no cast display remaining afterward. They prove that
observed lifecycle only, not every submitted event or a native CPU/FPS gain.
No additional Lua probes were used after that reload. No buy, sell, delete or
material-consuming craft test is authorized; crafting is simulated. Item moves are
allowed. The foreground exception does not apply to other native operations.

## Merchant lifecycle and final verification

The bulk-buy vendor path reproduced a stale captured-slot purchase loop surviving
merchant close. Its current candidate cancels through the existing native OnHide,
retires the loop before a native purchase and rearms only the same generation.
Three modeled pairs pass 181 checks across ten client/provider labels and reject
seven compiled harmful changes. Closing for ten seconds changes stale purchase
attempts 18 to zero and idle callbacks 200 to zero. Normal 45-unit buying retains
20 units at 0.5 seconds, 20 at 1 second and 5 at 1.5 seconds. Native errors propagate
once with the old loop retired; a same-stack new request keeps its own generation.
All buys and sales in tests are stubs; actual item transactions remain prohibited.

That independent bulk review now passes the 181 checks plus nine additional
argument/return/error/reentry cases. The known-item audit reproduced hidden
merchant scans and changes only the actual merchant paint: `ShouldRun` still runs
first, and only a readable native `IsShown()==false` skips it. Classic visible
callbacks remain synchronous; Retail retains its existing deferred coalescing.
Missing/error/nil/opaque visibility falls back to the original paint. One hundred
closed Classic callbacks change 1,200 link/item/tooltip/paint calls each to zero;
the coalesced Retail path changes 12 each to zero. The added cost is one protected
visibility read per actual paint, including visible paints. Three pairs pass 262
checks/110 scenarios and seven compiled controls; independent review passes.
Full-file reconstruction guards prove auction/guild/shared-known/settings bodies
remain byte-identical. No negative knowledge cache or additional delay was added.

The final source set comprises eleven runtime owners, eight new tests and one
existing extraction fixture. **375 scripts / 1,063 syntax files pass**, with all
Lua source stable throughout the final run. The read-only guard verifies all 55
owned installed copies and external Syndicator's 41 files. Current and backup
Forever saves both serialize the diagnostic root as nil with matching literal
hashes; no temporary spike-watch table was saved. This corroborates those two
saved states without making a claim about older diagnostic history.

The accepted source changes, raw pairs, controls, reviews, native observations,
source guards and final checks are indexed in the
[evidence record](validation/lag-hotspots-2026-11-14.json). Documentation validation
passes 1,096 classified sources, 623 reachable sources, 444 settings, 24 saved roots
and 17,310 local links. Continuity and parity/client/performance ledgers record the
final files. The last vendor changes were written after the user's reload and need
a later reload when ready; installed file identity does not prove a loaded version.

Native bank/mail/vendor lifecycle and timing, provider-disabled/native other-client
checks, pixels/controller and secure-VM acceptance remain unverified. No matched
native FPS gain or completely lag-free addon is claimed. The broader goal remains
active for that acceptance work; the verified implementation pass is not a
substitute for it.

## Empty-mailbox native observation

The user opened an empty inbox on the existing Forever1.60.1.70938 client.
Read-only commands confirmed mailbox shown, inbox0/total0, Flux snapshot0,
Syndicator source, reliabletrue and no native mail command pending. Three native
GetInboxNumItems trials of1,000 calls each took0.0418/0.0405/0.0398ms, including
the Lua loop. They exclude headers, attachments, metadata and publication.

In a separate12.922s passive observation, same-session _FluxUI profiler threshold
deltas for >1/5/10/50/100/500/1000ms were230/0/0/0/0/0/0. These are nested counters;
they cannot be summed or attributed to mailbox processing. The crowded city,
other addons and desktop activity were uncontrolled. This establishes no matched
optimization result, FPS gain or populated/cold-mail latency.

No mail was taken/sent/returned/deleted; no item was bought/sold/deleted/moved.
No activation, system-wide input, clipboard, profiler/FPS preference change,
saved diagnostic-root replacement or persistent Lua probe was used. All commands
used the exact verified background window; a focus change between other desktop
apps is recorded in the raw submission. The user requested native measurement
before accepting a bounded stale-mail validation delay. Empty mail cannot settle
that populated-inbox decision, which remains pending.
[Readouts and limitations](validation/lag-hotspots-empty-mailbox-2026-11-14.json).

## Continuation: recipe scans, output lookup and bulk capacity

The fresh continuation checkpoint contains 2,792 files and all-ref history; 125 settings metadata records were inspected without copying private values. The 375-script/1,063-syntax source set was the new pre-edit baseline. Current three-owner raw hashes match the sealed external candidates exactly. This continuation leaves r27 shortage preparation, saved minimum tiers, explicit purchases, appearance and update cadence under their existing owners.

Profession updates still query native recipe information, schematics, outputs and qualities on every scan. A stateless reagent collector replaces per-recipe closures. Fresh complete records avoid a redundant top-level prior-record copy; missing, partial, reagent or custom inherited facts retain the original merge policy. All craft invalidation and inventory publication pulses occur as before.

Modern output lookup reads the current mutable catalogue on each invocation, identifies matching IDs, ranks every alias of those candidates in the original order and filters the winning record. Global unlearning still applies. Legacy/unknown identities and public catalogue overrides retain the complete path. There is no output index, native fact cache, event suppression or delayed refresh.

Bulk capacity can reuse one warm owned info result for its link and count. Getter overrides are checked before and after the first read; cold links and missing info preserve the original link-then-info sequence, including the second read that may recover a count. Existing GetContainerItemLink return values remain unchanged. Slot capacity, bag-family checks and transaction consent are unchanged.

Three alternating baseline/candidate pairs pass 637 profession checks and 133 capacity checks per set, across five existing client labels and both fixture provider modes. Thirteen compiled harmful controls fail, including inheritance, alias selection, revocation, public overrides, cold recovery, reentry, link arity and specialty bags. Fifteen existing scripts pass against the preview; 61 installed affected scripts pass with all 1,065 Lua hashes stable. An independent review reproduces all 770 checks with no blockers. A new whole-suite acceptance result must be reported separately after all continuation owners are final.

| Production workload | Baseline | Candidate | Preserved work |
| --- | --- | --- | --- |
| 64 modern recipes / 3 profession events | 192 collector function identities; 384 prior-record copies | 1 collector identity; 0 prior-record copies | 192 collector calls; all native scans; 9 craft invalidations; 3 publications |
| 64 legacy recipes / 3 events | 192 prior-record copies | 0 prior-record copies | All scans; 6 craft invalidations; 3 publications; original full output-query path |
| 20 modern output queries / 64 recipes / two aliases | 2,560 alias ranks | 40 matching-alias ranks | Mutable current facts, every candidate alias, revocation, order and output qualities |
| 200 occupied capacity slots | 400 native info calls / 400 normalized rows | 200 calls / 200 rows | Same slot capacity, stack policy, overrides, errors and cold fallback |
| 40 occupied + 160 empty slots | 240 info calls / 80 normalized rows | 200 calls / 40 rows | 160 native link fallbacks; capacity 3,800 |
| 200 empty / cold-link / cold-info slots | 200 / 400 / 400 info calls | 200 / 400 / 400 info calls | Original cold and empty sequence; no read reduction claimed |

Lua 5.4 fixture timing is separate from native WoW CPU/FPS. For 500 recipes and 500 output queries, Retail median changes 0.445s to 0.131s and Forever 0.437s to 0.124s; raw ranges are retained. A 50-query allocation sample with desktop GC stopped changes about 4,756KB to 28KB. These are fixture allocations, not retained WoW heap or GC-pause measurements. Bulk empty/cold cases retain their native reads but add helper/identity dispatch: the modeled empty 200-slot scan is about 18 microseconds slower per capacity call in the first pair. Dense warm work removes actual normalization rows and native-query invocations; raw empty/cold timing regressions remain part of the evidence. Native merchant/profession timing, taint, input/controller and pixel acceptance remain pending.

Prior native food/watch/widget observations do not accept these new profession/capacity changes. The empty-mailbox observation is separate; the populated-mail latency decision remains pending. No child native input, material-consuming craft, purchase, sale, deletion, preference change, manual sync or external Syndicator edit occurred.
[Exact identities, work, regressions and review](validation/lag-hotspots-commerce-continuation-2026-11-14.json).

## Actual producer counterexamples

A continuation replay executes the installed read-only Syndicator producer,
public API and real metadata utility alongside FluxUI's actual bridge, Store,
Sync and Scheduler. Earlier provider fixtures supplied producer facts directly;
this replay covers the producer itself. Three baseline repeats, three isolation
pairs per fault and three extra controls reproduce two unresolved correctness
problems in38 checks/run:

- A cold bank metadata completion after close can re-read an unavailable native
  container, replace a real5-item bank stack with an empty provider row and reduce
  the Flux count5→0. Warm-before-close or readable-after-close controls do not fail.
- An older cold mail job can finish after inbox indices change and overwrite the
  newer result. The simple case counts an actual single attachment twice. Further
  equal-cardinality cases replace the wrong item IDs even when header/row totals
  agree. Legitimate duplicate attachments must remain separately counted.

These are actual-source failures under synthetic native facts, not observed
native bank/mail failures. No producer or mail/bank remedy was applied in this
continuation. A safe bank remedy needs independent tri-state count evidence,
count-only provenance, future-delta ownership and provider-off persistence; an
aggregate cannot establish a slot location. Existing count helpers collapse
unavailable facts to0 and cannot prove an empty bank by themselves.

All five pinned native MailFrame sources use the eighth header return as a numeric
attachment count. Header checking detects some count mismatches but cannot validate
equal-cardinality wrong identities. The provider has no public mail scan generation
or pending-state contract. An external prototype reuses the existing bounded reader;
its100-mail/16-attachment scheduling model takes about0.396–0.75s at144/60fps versus
the bridge's0.2s debounce. These are models, not native measurements. The user chose
in-game measurement before accepting that exceptional delay. An empty inbox cannot
settle the populated/cold case; mail policy remains pending.

The immutable external scanner itself performs6,501 selected native queries in
one modeled100-mail/1,600-attachment update; its metadata utility retries25 times
in10 simulated seconds when data never arrives. FluxUI cannot remove synchronous
producer work or cancel the private external queue within this bridge-only scope.
The external41 files remain unchanged. No duplicate-row removal, blanket closed-bank
suppression, circular snapshot validation or private producer mutation is accepted.
[Exact causal evidence and limitations](validation/lag-hotspots-provider-counterexamples-2026-11-14.json).

## Current continuation integration

The five new owners and four new tests are now integrated; two existing paint/scroll
fixtures follow the viewport renderer while retaining their functional checks.
The current whole suite passes379 scripts and1,067 syntax files with every Lua
hash stable throughout. Independent review passes. The original eleven-owner
checkpoint above remains historical; the broad task has sixteen cumulative owners.

For1,000 configured AH rows, opening modeled objects falls15,021→4,549 while
native frame count remains4,012. Twenty refreshes use960 width measurements,
4,940 text writes and960 icon writes versus20,000/100,140/20,000. All rows,
prices, proposals, geometry, fixed currency editing and immediate visible updates
remain. Native scroll handlers are retained. The original ordinal control pool
remains bounded by maximum simultaneous row count; a per-item lifetime cache was
rejected after101 disjoint20-row models retained2,020 controls instead of20.

Decorations initialize on the first visible/overscan visit and persist per original
slot. A full traversal converges to the original15,021 objects; it shifts some
first-use work to scrolling. The original goal of a fully viewport-bounded native
physical pool was not met and is explicitly superseded. Native navigation creation
scan cost remains. This is a reduction in eager decoration and passive repaint
work, not an O(viewport) lifetime-memory or native FPS claim.

Reviews fixed same-owner refresh swallowing a held click, stale owner/proposal
gestures, interrupted old paint after nested scroll-away, and repeated passive
tooltip queries. Current fresh same-owner snapshots create no extra bindings or
tooltip/market queries. Raw native setter errors still propagate unchanged.

Three matched source pairs have identical complete1,335,636-byte semantic traces;
117,900 work checks,88,620 action checks,11,404 geometry checks,17 compiled harmful
controls and44 existing scripts pass. Independent7/20/80/1,000-row timing pairs
include ordinary/proposal hover. Small7/20-row desktop cases add10–40us/refresh;
20-row warm allocations add44KB/10 refreshes. Larger80/1,000-row cases improve.
The extra small-case staging/cleanup cost is retained and disclosed; no visible
cadence or asynchronous delay was added. These desktop fixtures do not measure
native CPU/FPS, retained heap, pixels, controller input or taint.

All1,057 other Lua files,257 assets/XML/TOCs,85 options/bindings,7 defaults/settings
owners and5 license files match the fresh checkpoint. All80 cumulative runtime
files match across five installed copies read-only; external Syndicator41 files
are unchanged. No manual sync/publication/settings/profiler preference changes.
New source requires a later reload; no automatic reload was performed.

The actual-source closed-bank/stale-mail defects remain unresolved. Three53-check
bank-boundary runs show why scalar-only correction misses Index and provider-off
restore; a modeled zero/physical-five alternative is not a native finding. The
empty-mailbox observation cannot settle populated fallback latency. User's request
to measure in-game first still governs that decision. The broad goal remains active.
[Current combined evidence](validation/lag-hotspots-continuation-2026-11-14.json);
[AH source comparison and tradeoffs](validation/auction-viewport-performance-2026-11-14.json).

## Explicit pause and reload

The user requested a complete pause. The Forever client was reloaded at12:27UTC on14 November and returned to the world; prior temporary Lua diagnostics must be treated as gone. No temporary chat code was installed after reload. All workers are interrupted. The notification-copy optimization is applied and focused-tested, but the current whole suite remains pending alongside newer independent mouse/ghost-hover edits. Craft/account prototypes are unaccepted and external; bank/mail fixes remain pending. Resume only when the user says continue. [Exact state, hashes and next steps](validation/lag-hotspots-pause-2026-11-14.json).

## Resumed crafting and notification verification

The user explicitly resumed the full goal after the confirmed13:27CET reload.
Fresh2,806-file source/history and125settings metadata verification preceded this
pass. Current380-script/1,068-syntax baseline passed with stable Lua. The applied
notification merge optimization is now included in current whole-tree validation.

Crafting's accepted change removes private recipe/effective wrapper tables,
preserves per-occurrence values in parallel arrays, stably compacts only those
private arrays for First Aid, and hoists the stateless comparator. Public output
rows remain fresh. All classification, count, yield, stack, dependency and public
callback order remains. Lazy-count and count-memo prototypes were rejected for
concrete public-seam failures; neither was applied.

Three pairs pass4,020 checks/90scenarios with identical366,699-byte complete scalar
traces. Independent mixed-filter review adds3,380 assertions/90paired cases across
all five client policies and three kinds. Eight compiled harmful variants fail.
For100matching recipes, private wrapper objects drop100→0; eleven list builds use
one comparator identity instead of eleven. Reagent reads stay200/120/100 in both
sources for strongest/lower/no affordable recipe. Public lists and late helper
overrides retain all original reads and error propagation.

Across three desktop timing/allocation pairs, ten500-recipe selections allocate
about428–508KiB less. CPU results are mixed; this is no consistent CPU improvement,
native FPS, retained-heap or GC-pause claim. Empty/small cases and raw ranges are
retained in the evidence. Update cadence and protected action ownership remain.

The account audit found demand-only work, not an account rescan per bag update.
The tested shortcut reduced getter counts but made a100-character missing query
67→123us, with identical allocations and additional provenance gaps. Both account
variants stay external; Store/Summaries/Sync are unchanged.

Current full validation passes383scripts and1,071syntax files with every Lua hash
stable, including newer group-hover changes from their separate owner. Those
changes are preserved and verified against that owner's record. All1,065 other
Lua files,257assets,84other options/bindings,7defaults and5licenses match the fresh
checkpoint; the remaining changed binding belongs to the concurrent owner.
All90 cumulative performance-owner copies match across five installs read-only;
external Syndicator41files are unchanged. No publication/manual sync occurred.

The user granted an explicit exception for temporary read-only profiling commands
in background WoW chat. Automatic approval initially rejected this under the
keyboard rule; the explicit exception resolved approval. The runtime window guard
then prevented every command because it did not verify a stable background desktop.
No new temporary code/probe was installed. An active user tailoring queue was only
observed; no craft/item/mail/profiler setting was changed. Native measurement is
pending. Future pause cancels active tests before recording state, and does not
automatically reload unless requested.
[Craft source, controls and allocation samples](validation/craft-selector-allocation-2026-11-14.json);
[notification copy evidence](validation/inventory-notification-performance-2026-11-14.json);
[full current state and remaining acceptance](validation/lag-hotspots-resumed-2026-11-14.json).

## Latest requested pause and reload

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
[Exact pause state](validation/lag-hotspots-pause-final-2026-11-14.json).

## Native rebuild measurements and private catalogue allocation

The user resumed after the14:44CET reload and explicitly permits profiling with
WoW foreground or background. Fresh Forever70938/interface16001 reports native
profiling enabled, scriptProfile0, caps120/30 and Syndicator. All27 commands used
local variables; no persistent probe, watcher, preference or queue change occurred.
The old command/capture filename collision was caught before input. New capture
metadata uses a separate suffix and batches are checked against reviewed hashes.

Three rotated current-source measurements return5healing/2mana/8bandage entries:
full-list calls take3.54–4.20ms and allocate250,392–275,665bytes. Each call scans
the complete cached catalogue, not only those matching rows. Three direct121-row
catalogue calls take0.90–1.08ms and allocate110,672bytes each. Empty controls take
0.0002ms/0bytes. Normal same-generation bandage-cache reads take0.0068/0.001ms
and allocate0bytes. Rebuild cost is therefore distinct from normal cache-hit cost.

A separate46.593s passive interval during natural crafting/AH activity records
overlapping Flux tick-count deltas295/27/23/8/2/0/0 for>1/5/10/50/100/500/1000ms.
It has no recipe stress calls or watcher inside it. These counts do not identify
the slow callback or prove FPS effects. Recent60-tick Flux and Syndicator readings
are separate snapshots, not interval averages or matched old/new measurements.

An actual-source101-check/7-scenario replay plus isolation controls confirms that
an unrelated delayed-bag event can rebuild all3craft kinds. The same fallback
is required for live depletion/refill before delayed provider publication; loading
and combat gates also matter. Global bag generation can cause additional misses.
No invalidation removal or change in update speed was accepted from that model.

The accepted catalogue change replaces each private seen-record table with an
output index and two lazy parallel rank/key arrays. First encounter/replacement
order, revocations, legacy exemptions, rank ties, tostring/metatable/reentry/error
boundaries and returned recipe references remain. It adds no cache/native API,
event/timer/poll, option, saved data or UI change. Empty lists allocate no extra
arrays. The native watcher was left unarmed: preserving the previous saved
diagnostic root across unexpected reload/logout needs separate lifecycle proof,
and that watcher misses the relevant raw-frame/native-timer callbacks.

Three before/after pairs pass3,063 durable assertions/145scenarios each. Eight
compiled harmful controls fail, three existing scripts pass against both owners,
and independent static review passes. The final seal explicitly distinguishes
tested candidate hashes from the earlier runner's live-owner preservation label.
At121entries, desktop allocation changes23.96→10.11KiB/query; CPU median190→183us,
with overlapping ranges and slower individual trials retained. Tested sizes are
0/7/20/121/500/2000. These do not establish native after-change allocations or FPS.

The fresh2,815-file/source/history checkpoint and126settings metadata inspection
precede the edit. Current full validation passes384scripts/1,072syntax with stable
Lua. All1,071other checkpoint Lua files,257assets,85options,7defaults and5licenses
remain unchanged. All90 cumulative owned copies match read-only across five
installs; Syndicator41files remain untouched. No publication/manual sync/reload
occurred. The client needs a later reload to load this final change; an active
user craft queue was left alone. Broad native, bank/mail and other-client gaps
remain active. Quick-pause controls and exact continuity are saved.
[Native rows and limits](validation/lag-hotspots-native-resume-2026-11-14.json);
[candidate, regressions and current integration](validation/profession-catalogue-allocation-2026-11-14.json).
