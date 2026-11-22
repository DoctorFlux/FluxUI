# Client and reference validation — 29 October 2026

## Action strip page two ownership

The earlier Forever capture showed column 6 and fixed column 18 both
reading Blizzard slot 18 with native page 2 selected. The supplied WTF
snapshot has no saved Flux page override or explicit native page-switch
binding. The event that selected page 2 in the affected session is unknown.

On the candidate, select native page 2 outside combat and verify the
resting main row with `/fluxbars audit`. Expect slots 1–7 in columns 1–7,
20–24 in columns 8–12 and 13–19 in the fixed columns when no mini action
is promoted. Compare the icon, mouse click and assigned key in columns
1, 7, 8, 12, 13 and 19. Return to page 1, then check Shift and Ctrl,
dragging an action, forms and a temporary control bar. Record the loaded
build and watch the Lua error log. Check all five client families and use
the established Witchcraft route for Forever when available.

Desktop coverage includes the shared model, restricted snippets, native
slot calculation and Forever's key proxy. Both routing files match across
all five installations. Live input, native taint and controller
verification are pending.
[Source and replay evidence](validation/action-bar-page-two-2026-11-22.json).

## Battlefield Map POI mouse actions in combat

After a reload outside combat, open the Flux Map tab in Battlefield
Map mode. Check ordinary POIs, event POIs, tooltips and mouse handling.
With the map visible, enter combat where POIs change and watch the
Lua error log. Existing pins should stay visible. On combat exit, check
that current POIs and their normal interactions return. Include a zone
change, a hide or reopen around combat exit, and a full World Map view.
Check controller navigation on Forever through the original controls.

The report matches Forever 1.60.1.71037. The desktop fixture checks both
stock providers, combat activation before lockdown, reentry, hide/reopen
and a single catch-up for a burst of missed updates. In-game verification
of the mouse blocks, taint and timing is pending.
[Source and replay evidence](validation/battlefield-poi-combat-2026-11-22.json).

## Damage meter taint and rounded border junctions

After a reload outside combat, select a Flux Meter layout that needs a
new pane. Add it through Blizzard’s meter settings menu, select its
requested type from its title dropdown, and select **Current** from its
session dropdown. Confirm the setup pane clears and the chosen type
displays live rows. Leave another pane on **Overall** or a historical
fight and confirm its selection survives a tab switch and resize.
Repeat with populated rows while out of combat. Check two fights with
the meter visible, including timer rollover, row icons, class colors and
source drilldown. Include Blizzard’s **In Combat** visibility mode and
the native controller dropdowns in Forever.

With rounded unit borders, show and clear an aura panel where its stem
joins the target or focus border. Include a corner with perpendicular
unit arms. Verify the cap, stem and fallback remain visible and check
for errors from the scheduled border update.

The meter trace matches the pinned Forever 1.60.1.71037 native source
locations. Desktop replays cover the reported addon routes and replay
pinned Blizzard methods. The changed files match on disk across five
installs. Native taint, timing, pixels and controller checks are pending.
[Checkpoint and replay evidence](validation/meter-border-fixes-2026-11-22.json).

## Craft reminder in the profession window

Prepare a craft with all required materials in bags. With the profession
window closed, check the item icon, remaining quantity and caption on
the FluxUI reminder. Open the native crafting page and then Flowcraft.
Check that the same information and click action appear inside the
active window. Move and resize the window, switch views, and close it.
Confirm that a ready action appears at one location through those
transitions and that the separate **Process** control still works.
Repeat the native path with FluxUI alone. When a recipe needs the native
**Create** action, check the displayed batch and the disabled reminder
while Blizzard’s **Create** remains available. Verify pointer activation
and focus, native controller cursor reachability, and back/close behavior
in each supported view.

The verified Forever window was observed in the background with Flowcraft
open. A Green Silk Pack cast continued as the visible queue count fell
from seven to six. Both observations kept the foreground unchanged.
The existing item icon, badge and caption in the supplied screenshot
are the visual reference. The post-install guard found the exact Forever
window in the foreground. The candidate layout comparison and native
pointer and controller checks remain pending. The HUD fixture passed
63,801 checks and integration passed 310. The installed companion passed
17 Lua 5.4 and six targeted Lua 5.1 suites.
[Exact sources and tests](validation/fluxui-craft-reminder-dock-2026-11-22.json).

## FluxUI continue craft button

Queue a two-step Forever craft and acquire all the materials. Complete
the intermediate and stop the final batch after one confirmed result.
Check that FluxUI shows the remaining batch on the HUD and places the
craft action inside the open profession window. Verify the quantities
after a second result, closing and reopening the profession, and
reload. Confirm that the action still requires a player press and
that a remaining acquisition keeps the craft unavailable.

The reported state had nine crafts remaining after one verified result.
The on-disk craft receipt, material reservations and same-time builtin
bag counts agreed. No FluxUI auction follow-up or pending purchase was
saved. A later background capture showed eight Green Silk Packs queued
with the matching **Craft next** action in Flowcraft and on the FluxUI
HUD. A candidate reload and a subsequent native craft press remain to
be verified. The desktop tests cover both controls, the native stop
wake-up, bag settlement, and preparing a missing native craft form.
[Exact sources and tests](validation/flowcraft-continue-button-2026-11-22.json).

## Shared queued craft materials

Queue crafts with a shared material and check the combined amount for
each eligible source. Compare matching and different output recipes.
Verify Shopping, the vendor and the bank assign the exact acquired
shares to the accepted orders. Include an offer smaller than the
combined demand and check the outstanding quantities after settlement.
The vendor group must fit the exact live offer, stock and each order's
limits. An approved merchant fallback for an auction requirement can
share the offer with an accepted vendor requirement. Bank coverage
includes a partial withdrawal across two orders,
physical stack checks after the first order is credited, and a changed
group with the same total.
The new 50-unit auction case across different output recipes fails on
the frozen baseline. The candidate also checks a combined Classic
stack and smaller individually approved lots. The focused owner
fixtures pass 2,100 bank icon checks and 153 policy bridge checks.
The installed companion passes 17 Lua 5.4 and six targeted Lua 5.1
suites. The full Lua 5.1 run reaches the existing auction income
fixture's `table.pack` dependency. The 66 bank snapshot and vendor-open
operation vectors match across three frozen and candidate pairs. Four
runtime files match across five installs.

The exact Forever window was verified on the host before and after
installation. It owned foreground both times, so the background-only
check stopped before acquiring an image. Native auction, merchant and
bank verification remain pending.
[Exact sources and tests](validation/flowcraft-shared-materials-2026-11-22.json).

## Craft materials in Vendor Restock

An accepted Auction Restock craft can add its vendor ingredients to the
ordinary Vendor Restock list as temporary targets. At a matching vendor,
available materials use the current merchant price and remaining
quantity. Verify that the normal buy action fills all eligible items and
that automatic buying on merchant open follows its setting. Repeat both
cases with FluxLogistics loaded and unloaded. Include a material with an
existing regular target and check retirement after carried receipt.
The companion reminder rechecks its displayed stage before opening the
same merchant buy pass.

The owner source suite passes 1,624 checks across 20 profiles, including
manual and automatic passes for multiple materials. The merchant
fixtures cover merged rows, delayed receipt handoff and live slot and
stock checks. Companion tests cover independent accepted jobs in one
pass, the same job advancing after its receipt, and current merchant
price, capacity and wallet limits. All 17 installed companion Lua 5.4
and six targeted Lua 5.1 suites pass. The five runtime files match across
five installations. All 21 ordinary vendor-open operation vectors match
in three paired trials.

Forever 1.60.1 build 71037 was observed in the background with
Auctionator Selling, Tailoring and an empty Flowcraft queue. The final
capture showed the Auction House and no merchant or pending Restock
action. Foreground stayed unchanged and no game input was sent. Native
reload and merchant buys remain pending.
[Exact sources and tests](validation/restock-craft-vendor-targets-2026-11-22.json).

## Flowcraft cast lifecycle

Flowcraft follows the player's cast for the accepted craft and its
matching result. The row shows the client's reported duration when the
current spell, source and cast identity match. It can show **Waiting
for the craft result** when the terminal signal arrives first.
Verify a long craft that crosses the earlier deadline and check the
queue and Restock count after each completed result. Interrupt a batch
and check that its terminal event and verified output leave the correct
remainder.
[Forever cast API](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua#L828-L850).

The regression runs two matching 44.8-second casts and checks the
remaining count after each native result. A matching stop can wait
across 180 simulated seconds until a delayed receipt. The fixtures
also cover mismatched cast identity and a prepared **Create** action
that remains available until cancellation. Installed verification passed
17 Lua 5.4 and 11 Lua 5.1 suites, 231 owner bridge checks and the two
cross-owner click routes with native stubs. The scale fixture retains
1,636 recipes and a 121-card graph with 40 craft tasks. Three runtime
files and two fixtures match across five installed copies.

Forever 1.60.1 build 71037 was observed in the background. After
installation, the workbench showed an empty queue and Mooncloth on
cooldown. The observation sent no game input and kept foreground
unchanged. Native reload and a fresh eligible cast remain pending.
[Exact sources and tests](validation/flowcraft-cast-lifecycle-2026-11-22.json).

## Flowcraft queue progress and Process

An accepted order row shows its remaining final output and its current
craft or material step. Craft steps show their position in the order.
Selecting the row keeps that exact order targeted for **Process**. The
matching native profession view shows progress beside the craft controls.
Exact native result signals update the displayed remainder during the
batch. Partial self-created output must match the fixed yield and the
carried reagent changes before it settles. The fixtures cover overlapping
result streams and verify that a display update keeps the reservation
until settlement.

The desktop integration runs the actual FluxUI Restock and companion
modules with native API stubs. Pressing a stale four-pack reminder first
refreshes it to two. The next press submits exactly two for the same
task. A separate case uses the profession-window action after a verified
stop and submits the same two-pack remainder. The companion bridge
passes 231 checks, the HUD 63,577 and the standalone craft driver 3,279.
Five runtime files and three fixtures match across five installed copies.
The installed Forever source passes 17 Lua 5.4 and 11 Lua 5.1 suites.
The existing recipe-selection benchmark matched its operation counts
on all three paired trials.

Check a multi-step order during the first craft and after the final
receipt. Stop partway through and verify the selected order retains the
verified remainder when **Process** becomes eligible. Select another
order while the first is in Review and verify that **Process** follows
the selected order's eligible step. Repeat with a shared output to
verify that ambiguous work stays in Review. Compare the actual carried
count and native recipe at each transition. When the FluxUI Restock
reminder offers the same ready task, verify its press reaches that
accepted craft.

Forever 1.60.1 build 71037 was verified on the host. The later background
capture showed the native Auction House Restock tab and the **Open
Tailoring** reminder. An authorized background reload and press of
**Open Tailoring** showed **2/2 Next 3**. At 10:24:29 UTC, the actual
Flowcraft **Process** press for the selected three-pack order started its
44.8-second native cast and showed **Crafting 3**. At 10:25:08 UTC the
queue showed a timeout with 5.9 seconds left on the cast bar. At 10:25:52
UTC the capture showed one create message and the row and reminder at a
two-pack remainder. The window-targeted actions left foreground
unchanged. Watchdog follow-up and each completed count remain under
verification.

The installed watchdog follows the exact native cast's end time and
allows two seconds for its receipt. The focused fixture runs two
successive 44.8-second native casts and verifies the remainder changes
from four to three to two before carried inventory refresh. It also
covers a different spell, a mismatched cast GUID and a missing receipt
after the grace period.
All 17 installed Lua 5.4 suites, 11 targeted Lua 5.1 suites and the
owner integration pass after the watchdog repair.

The player independently crafted the remaining two before the repaired
source reloaded. The 10:31:23 UTC reload showed **Count 2** for the
two carried packs. The foreground guard deferred that press and a
subsequent 30-second observation still found the game in foreground.
The player had used the remaining reagents. Verification of another
long cast, each live decrement and the post-stop resume awaits an
eligible order on the repaired source.
[Exact sources and tests](validation/flowcraft-queue-rework-2026-11-22.json).

## Flowcraft recipe selection

Forever changes the selected recipe immediately, clears the previous
draft and coalesces rapid selection notifications. Clicking **Queue**
before the refresh evaluates the current recipe. The Flowcraft card's
native selection echo uses the same refresh. The existing graph layout
now supplies the inspected node and the rendered cards.

In a desktop burst of twelve alternating 40-task selections, plan,
inventory snapshot, price quote and queue refresh counts each fall from
12 to one. Graph layouts fall from 25 to two. Total modeled CPU falls
from 365 to 30 ms. With twelve isolated selections, all twelve plans
still run, graph layouts fall from 25 to 13, and total modeled CPU moves
from 354 to 356 ms. The candidate's input callback work fell below the
desktop timer's resolution in both scenarios. The scale fixture still
covers 1,636 recipes and a
121-card graph with 40 craft tasks. All 17 Lua 5.4 and eight targeted
Lua 5.1 fixtures pass against the installed Forever source.
The two runtime files and two fixtures match across five installed copies.

Host verification found Forever 1.60.1 build 71037. The game window
already owned foreground, so the background capture stopped before
image acquisition. Native reload, selection latency, FPS and taint
remain pending.
[Exact sources and tests](validation/fluxlogistics-recipe-selection-2026-11-22.json).

## Flowcraft partial craft after reload

The 09:35:08 UTC Forever character save recorded 20 completed Bolts of
Silk Cloth and an uncertain four-pack task with all four remaining. Its
pack attempt timed out after **Process**. It saved the pre-action output
count of zero and the requested batch of four. The companion save ties
the order and recipe catalog to the same character and build. In the
selected built-in inventory save at the same timestamp, one matching
character entry changed from zero packs and zero bolts to two packs and
ten bolts. The inventory entry lacks the companion's character GUID. Its
timestamp and quantities corroborate the player report, while the pack
attempt lacks a saved native craft receipt.

The installed companion passes 16 Lua 5.4 and seven Lua 5.1 suites.
The owner passes 231 bridge checks across 13 profiles and 63,577 HUD
checks across five models and overflow cases. The focused craft,
closed-profession, vendor routes and integration fixtures also pass.
Mail Restock passes 4,500 checks across 20 profiles.
The renderer matches all 45 operation samples across 15 paired desktop
trials. Eight changed runtime files match across five installs. The
read-only Forever capture showed Auctionator Selling and the backpack
with the foreground unchanged. The candidate still needs a native reload.

After the updated pair is loaded, verify that a craft with durable
evidence resumes at the confirmed remaining quantity. For the older
uncertain order, verify that **Process** or **Resume** can use verified
carried order fulfillment and prepare exactly two remaining packs for
Blizzard's **Create**. If the remainder is blocked, check that the press
records the carried amount and the appropriate acquisition or profession
stage appears. Check both the Flowcraft workspace and the FluxUI Restock
reminder. Change the selected order before pressing a displayed reminder
and verify that the previous action expires. Native reload, recovery and
craft confirmation remain pending.
[Exact sources and tests](validation/flowcraft-partial-craft-2026-11-22.json).

## Grouped vendor materials and Restock reminder

The HUD receives accepted companion vendor totals. One or two materials
show their names and quantities in the caption, and each icon carries its
own tooltip. The matching live merchant can make the stage actionable.
A press verifies the currently displayed provider, stage and item totals
before it reaches the merchant owner.

The owner bridge passes 226 checks across 13 profiles. The HUD fixture
passes 63,540 across five models and overflow scenarios. Existing
follow-up, vendor routes, craft driver, closed-profession, vendor button
and Restock policy fixtures pass.

The installed companion fixtures combine two approved five-unit shares
in one 10-unit merchant request on both the manual and automatic paths.
They check actual cost, carried settlement at five and ten units,
a native cap that issues one share, and the single-order path for finite
stock. An uncertain same-item order blocks grouping and the reminder.
A manual press buys one material type. The automatic worker can continue
after that receipt settles. All 16 installed companion suites and six
Lua 5.1 suites pass. The four changed runtime files match across five
installs. Native reload, merchant interaction and receipt checks remain
pending.
[Exact sources and tests](validation/flowcraft-grouped-vendor-2026-11-22.json).

## Grouped Flowcraft orders

Two compatible Green Silk Pack orders appear as one **2× Green Silk Pack**
row. A row sums outstanding output and reduces the count when an order
settles. Matching queued and running orders can share a row. Paused or
review orders stay individually visible. The detail menu switches or
cancels an exact member. The grouped remove control checks and cancels
eligible members together. Each accepted order retains its own records.

Shopping and the FluxUI Restock tab combine eligible accepted material
needs for the exact current group. The desktop fixtures verify one
40-Silk Cloth offer and one six-Heavy Leather offer, with the receipt
assigned to each order within its approved limits. A four-leather
listing leaves two for another press. Each press retains the limit of
one qualified native offer.

All 16 installed companion suites pass. Focused owner coverage includes
12,708 auction checks across 46 profiles, 206 bridge checks across 13,
90 actual-owner rows, 50 exact-stack and 38 depth checks. Nine files
compile under Lua 5.1 and six installed suites pass there. The five
changed runtime files match across five installs. Native reload, input, purchase
and layout remain pending.
[Exact sources and tests](validation/flowcraft-grouped-queue-2026-11-22.json).

## Acquisition-first Restock and Flowcraft

The workflow presents purchases, mailbox collection and bank withdrawals
before **Open profession**. The owner checks carried materials for the
matching craft. For Restock and multi-step orders, FluxLogistics checks
the external inputs before the first task. Produced intermediates follow
the queued dependency steps. Both in-window craft controls use the same
accepted next task.

Shopping reads observed physical attachments from the selected FluxUI
built-in or Syndicator inventory publication. Positive observations can
appear while inbox coverage is partial. At Syndicator startup, a positive
warm count can appear as pending until the first fresh replacement. The
pending display gives no authority to collect or buy. A qualified full
observation supports an empty result and remains necessary for spending.
The workbench uses single-line rows with icons, adjusts its shelf to its
content and window size, and presents the next craft at the bottom.
The native profession window makes that action available across tabs.

The owner fixtures pass 12,708 auction, 674 follow-up, 3,279 craft
driver, 1,220 closed-profession, 206 companion bridge, 63,535 HUD,
476 vendor route, 4,500 mail worker and 77 mailbox observation checks.
The mailbox fixture loads both providers, including the installed
Syndicator publisher. All 16 companion suites pass against installed
source. The eleven changed runtime files match across all five installs.

The 10:10:16 Copenhagen background capture before companion installation
showed the Forever 1.60.1.71037 native Professions Book and merchant.
Foreground stayed unchanged. Candidate reload and interaction remain
pending. Compare physical mail under both providers, incomplete and
collected orders, compact and wide layout, and the matching next craft
action from both surfaces.
[Exact sources and tests](validation/restock-carried-flowcraft-2026-11-22.json).

## Built-in sold auction counts

22 November. The focused desktop replay passes 6,264 checks across Retail,
Forever, Classic progression, Era and Anniversary with the built-in provider
active, including provider-pending startup. It covers a closed sale against the
hydrated cache, duplicate notices, sibling listings, sparse saves, provider
handoff, legacy ambiguity and stale native rows. All five installed auction
trackers match and compile. [Source and recovery evidence](BUILTIN_AUCTION_PUBLICATION.md#sold-listings-with-the-auction-house-closed).

Native acceptance is pending. With Syndicator unloaded and two player listings
cached, close the Auction House and observe a real sale. Check the saved and
displayed auction counts before reopening, and verify the other listing remains.
On Era and Anniversary, repeat with two listings sharing a name and confirm
Blizzard's next owner update removes only the sold row. Record typed event
delivery while closed on Classic progression. Verify the Syndicator-loaded
control and the absence of new Lua errors.

## Tracked FluxLogistics profession switch

The desktop companion fixture passes 198 checks across 13 profiles. It covers the exact queued profession action, changed modes before the press and the earlier spell overlay for owner-driven and older companion actions. Five related owner suites pass. Native switching remains pending.

## Direct FluxLogistics craft action

22 November. The companion reminder labels a direct queue action Craft. The desktop harness passes 186 checks across 12 profiles, including mode changes after paint. Five related owner suites pass. Native direct API permission and queue settlement remain pending.

## Live Restock craft receipts

The baseline background run used Forever 1.60.1.71037. The 02:10:19
Copenhagen capture showed Blizzard's quantity at 25 after **Process**.
A background click on Blizzard's actual **Create** at 02:10:44 started
the Bolt of Mageweave cast and put the queued step **In progress**.
The 02:11:37 capture showed six create messages and quantity 19.
Both clicks left the foreground and global cursor unchanged.

The 02:14:36 capture showed **Check result** without matching output.
The player also shared a screenshot of that state. The bolt recipe
then showed 13 craftable instead of the earlier 25, and the bag recipe
showed two craftable. Those counts are consistent with 12 bolts
produced, an inference from the before and after UI. Automatic approval
rejected a later diagnostic chat probe and hover under the repository's
desktop control rule. The available live results stop at those captures.
[Exact baseline and candidate evidence](validation/restock-native-live-receipts-2026-11-22.json).

The installed companion fix retains the exact accepted native batch
while recasts progress and matches carried output against consumed
reagents. The desktop fixtures reconcile a complete long batch with no
craft-result events and a stopped 12-of-25 batch. The **Replan from bags**
fixture uses 12 carried bolts and 65 cloth to prepare a replacement
plan for 13 bolts and five bags. The old job and its settled receipt
stay in history. The verified owner HUD is passive and Flowcraft fits a
compact dock beside native **Create** when space permits.

Desktop checks pass, including 3,279 owner craft checks across 20
profiles, 178 bridge checks across 11, 63,443 HUD checks and 1,020
render checks across 15 trials. The broad desktop runs pass 43 FluxUI
and 16 FluxLogistics suites including the companion adapter catalog.
Native validation of the installed candidate remains pending, including
replanning the existing job and following its new batch through carried
output.

## Restock native quantity after stock refresh

The earlier screenshot showed Restock guidance for 25 craft operations
and one in Blizzard's quantity field. Separately, the 01:52:54
Copenhagen SavedVariables snapshot on Forever 1.60.1.71037 still
showed 25 bolts and five bags pending, with zero completed executions
and no new durable attempt. The snapshot ends at that time.
Live quantity, native permission and a physical **Create** after that
cutoff remain unverified.

The solo Restock handoff holds its verified quantity for the exact
selected job, recipe and native page. After a stock reset, it waits for
settled carried inventory before restoring the amount. A direct edit
or a physical **Create** releases the hold. The owner waits for active
native recasts before offering another craft.

The reminder moves a further 12 UI units right and 10 down. Its native
host anchor is (+16, -68) and its fallback anchor is (-66, +26). The
frame uses eight levels of clearance for visible profession surfaces
and nested Flowchart cards.

The owner driver passes 3,279 checks across 20 profiles. The companion
bridge passes 173 across 11 profiles. The HUD passes 63,431 checks and
the renderer passes 1,020 checks across 15 paired trials with 45 matching
counter samples.

The installed companion's general queue action can choose another ready
step of the same job when earlier materials are missing. The explicit
Flowchart craft action retains its selected step. FluxLogistics observes
craft events arriving during the matching native Create call and uses
them only after checking the exact recipe, amount and reagents. The
desktop replay of the outstanding order matches 25 bolts and five bags
to carried output. Fifteen companion suites and the adapter catalog pass.
[Exact sources and tests](validation/restock-native-craft-repeat-2026-11-22.json).

Native acceptance remains pending. Verify a stock reset while materials
are settling, a direct quantity edit, a physical **Create** and the
transition after recasts. Confirm the carried output advances the exact
job. Check both HUD anchors and the nested Flowchart z-order.

## Restock reminder profession layer

22 November. The HUD suite passes 63,401 desktop checks across five profiles. The render suite passes 1,020. Tests cover the native or companion layer, closing professions and restoring a secure opener without repainting an unchanged layout. Native stacking and input remain pending.

## Bounded native Restock craft batches

In Forever, the FluxUI HUD selects the exact outstanding recipe and
sets its native quantity when the field is enabled. The prepared count
uses the lower of the outstanding craft operations and the amount
Blizzard can currently craft, subject to single-craft recipes. Press
Blizzard's **Create** to use the prepared quantity. Blizzard's **Create
All** uses its full craftable amount.
[Forever Create handler](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_Professions/Blizzard_ProfessionsCrafting.lua#L1106-L1141).

For a delayed recipe selection, matching recipe responses, list updates
and inventory settlement coalesce while the exact owner job, task and
page remain pending. The ordinary owner yields when the companion takes
the native craft. Synchronous preparation adds zero driver frames or
timers in the checked fixture sequences.

On the paired FluxLogistics desktop candidate, Workbench and Flowchart
prepare the next task for the same accepted job. The replay prepares
25 bolts, then five bags after the carried bolt result. The workbench
docks beside the native craft pane when there is space. The narrower
configuration keeps the native pane and exposes a **Workbench** return.

The owner craft fixture passes 3,239 checks across 20 profiles. The
companion bridge passes 166 across 11 profiles. The HUD fixture passes
63,351 checks. The renderer passes 1,020 across 15 paired trials with
45 matching phase samples. All 15 companion scripts and the catalog
check pass. Four FluxUI and five FluxLogistics runtime files match
across five client installations.
[Exact sources and tests](validation/restock-native-craft-batch-2026-11-22.json).

Native acceptance remains pending. Verify a stable and an asynchronous
recipe, a smaller native craftable amount, and a changed job before
the delayed response. Confirm **Create** issues the shown batch and
the actual output advances the intended job. Check the native
permissions, the docked layout, and the narrower **Workbench** return.

## Restock handoff to native Create

The player reported that both craft actions still failed from the HUD.
The FluxLogistics native evidence records a blocked addon-issued
CraftRecipe on Forever 1.60.1.71037 and two attempts with no matched
result. The revised Forever path presents **Open recipe**. It prepares
the exact validated recipe, reveals the companion's native craft panel
when available, and points the player to Blizzard's **Create** button.
Ordinary FluxUI work advances from observed carried output. FluxLogistics
checks the exact accepted job and observes the native craft. Other client
paths retain their existing dispatchers.

The layout moves 12 UI units farther right and 10 farther down on both
HUD anchors and uses a higher frame stratum. The owner craft driver
passes 3,143 assertions across 20 desktop profiles. Both-owner integration
passes 153 checks across 11 profiles. The checked sequences keep the
driver frame and pending-timer counts steady.
The HUD passes 63,345 checks. All 15 paired render trials have identical
widget counts. The broader desktop run passes 43 FluxUI suites and 16
FluxLogistics suites. The four runtime files for each addon match across
the five client installations.
[Exact sources and tests](validation/restock-native-craft-hud-2026-11-22.json).

After a safe Forever reload, verify both owners, the displayed recipe,
the native Create reachability, and matching bag output. Cover a closed
profession and a live profession panel. Verify the reminder's placement
and layering on both anchors, then check native input and taint.
The new path's live behavior and visual fit remain pending.

## Nameplate debuff ownership

22 November. With **Only show my debuffs** enabled, apply an ordinary
debuff and a crowd-control effect while a second player applies comparable
effects. Include a pet or vehicle when available. Repeat with the setting
off and confirm the stock selection returns. Check the buff row,
Loss of Control, setting persistence, tooltip hover, combat and a
recycled plate. The stock fallback can omit effects with unreadable
ownership. Native verification, combat taint and rendering remain pending
on Retail, Forever, Classic progression, Classic Era and Anniversary.
Reach and activate the standard checkbox with the existing controller cursor,
then verify its checked state and return to the Auras tab after reopening.

The client ledger retains the exact Blizzard nameplate source pins from
the live debuff lookup record. The stock adapter calls
`C_UnitAuras.IsAuraFilteredOutByInstanceID` for a public instance ID. The
Retail and Forever declarations require aura access for this query.

The desktop replay passed 1,290 countdown and stock-filter checks across five
client models, 101 secure-row checks and 297 options and preview checks. The
five-client options navigation and shell suites passed 8,011 and 1,343 checks.
The pre-change countdown source fails 20 ownership assertions. The four
candidate runtime files match in all five installations.
[Source pins and desktop evidence](validation/live-nameplate-debuff-2026-11-22.json).

## Nameplate aura art and hover

22 November. Secure aura buttons use the reference square icon mask, bevel,
cooldown edge and type colors. Mouse motion reaches the Blizzard aura tooltip
with clicks disabled on the icon. The preview and stock overlay share the
same bevel and icon crop. Forever's stock aura button provides a spell tooltip
from its readable spell ID. Retail and the three Classic clients keep their
stock native aura tooltip scripts. A fallback tooltip closes when its owner
is hidden or replaced.

The verified Forever window was in an indoor city scene without a world
nameplate aura. Native hover, click-through, rendering and controller pointer
behavior remain pending on a live buff and debuff after reload.
[Sources, assets and test results](validation/nameplate-aura-style-hover-2026-11-22.json).

## Restock profession action and mail auto collect

22 November. The user reported that the earlier profession opener still
failed in game. The running Forever `1.60.1.71037` window was verified by
executable path and window handle. This check sent no game input. Live
behavior of the new candidate remains pending.

The earlier desktop fixture allowed **Open profession** during collection.
The current workflow waits for carried materials. Pending receipts keep
their workflow owner. Crafting gets a separate press after the exact recipe
and available materials are verified. The first HUD item can use Forever's
secure click proxy for an exact owned profession spell. The secure region
retires in combat and when the stage changes. The model also covers the
ordinary client opener.
[Current workflow](#acquisition-first-restock-and-flowcraft).
[Forever profession spell lookup](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_Professions/Camelot/Blizzard_ProfessionsFrame.lua#L39-L55)
[Blizzard's secure spell click](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L371-L379).

The one bounded mailbox worker follows the existing Auto Collect setting
for both owners. Auto Collect defaults on and honors the saved opt-out.
Companion mail must match an approved incoming amount and a buyer invoice.
The HUD model verifies a total 28-unit drop on both anchors and tests
centered glow bounds, slot reuse, and immediate fallback retirement.

Forty-five FluxUI, 16 installed FluxLogistics, and two staged companion
fixtures passed. The craft and proxy fixture covers 3,083 checks, the
dual-owner fixture 148, the HUD 63,336, mail 4,500, and cadence 940.
All 45 render counter records match across 15 trials. The ten runtime
files match across the five install trees. Native release input, controller reachability, profession opening,
exact batch submission, mail eligibility, glow geometry, combat and taint,
and CPU or FPS remain pending.
[Exact sources and tests](validation/restock-profession-mail-2026-11-22.json).

## Secure nameplate debuff and CC rows

22 November. The user's screenshot showed three red borders at RGB
`242,82,71`. That is the previous FluxUI fallback color. The attachment
establishes live border placement and does not establish which effects
have a dispel type. The user approved secure harmful aura rows after the
FlareUI comparison. The new candidate uses Blizzard's `AuraContainer` to
paint typed and untyped effects directly in Retail and Forever.

The desktop check covers secure registration, fallback, release, and the
existing timer controls. The secure CC category and the stock player Loss
of Control selection can differ. Classic progression, Era and Anniversary
retain the readable overlay. The next native check needs a typed debuff and
CC effect, an untyped debuff, a hidden row, an expiry and a recycled plate.
[Exact sources and tests](validation/secure-nameplate-auras-2026-11-22.json).

## Restock craft reminder opens professions

On modern clients, the craft owner checks the visible Recipes context and
resolves a saved recipe to its positive base profession when needed. For
an open Forever Book, use the matching native right tab. The supported
bootstrap handles the matching Recipes context. A cold open requires the
native OpenTradeSkill acknowledgement. The owner also recognizes a hidden
legacy window, blocks during profession changes, and permits ready work
while the mailbox is open if carried inventory is settled.
[Forever recipe profession API](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua#L442-L455)
[Forever profession Book tabs](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsTemplates.lua#L895-L918)
[Forever native opener](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_Professions/Blizzard_Professions_Bootstrap.lua#L13-L21).

An accepted companion craft can use the shared Forever opener. The
companion rechecks readiness immediately after a synchronous open and
requires a new press to craft. The FluxUI owner can continue the existing
click when the correct profession opens synchronously and its recipe is
validated.

Forty-one FluxUI and 15 FluxLogistics desktop fixtures passed. The owner
driver covers 3,040 checks across 20 profiles, including a stale recipe
identity that matches the wrong visible profession and a retained base
without ready recipe data. Its frame and pending-timer counters report zero
added driver frames or background timers in the checked sequences. All four
runtime files match across the five install trees. The consumer workspace
fixture reports the same `auctionEntry` error on both revisions.
[Exact sources and tests](validation/restock-craft-opener-2026-11-22.json).

Native acceptance remains pending. Compare the closed profession, an
open Book, the matching Recipes page, another profession, and a change
in progress. Include the mailbox with settled inventory, a hidden
legacy window, and a companion opening press followed by an explicit
craft press. Verify native permissions, keyboard or controller
reachability, and the exact recipe and batch.
[Restock handoff](FLUXLOGISTICS_RESTOCK.md).

## World nameplate debuff and CC artwork

22 November. The live artwork now follows the visible native aura button,
including Blizzard's separate player Loss of Control slot. The focused
fixture rejects missing values sent to the native access check. It covers
the top-right glyph, four visible border edges, missing and inaccessible
cooldowns, public and unreadable types, and pooled cleanup. A visible harmful
slot gets a red border when its type is unavailable. The glyph requires the
exact readable type.

The local FlareUI comparison creates `CustomAuraContainerTemplate` containers
for its live nameplates. It registers the border and the corner through
`AddDispelTypeTexture` on the resulting AuraButtons. The Blizzard nameplate
template instantiates a plain Frame without that method. The FluxUI overlay
uses the existing Blizzard icon and its exact readable aura data.

Forever's background window was observed in an Auction House scene without
a world debuff on screen. The current candidate still needs in-game checks
for a timed debuff, a PvE CC icon and a player Loss of Control icon after
reload. Keep one untyped debuff in the check to confirm the red border and
verify the countdown and native mouse target after removal.
[Source and regression evidence](validation/nameplate-debuff-artwork-2026-11-22.json)

## Live nameplate debuff lookup

22 November. The old live path missed first display on Forever and could
skip readable instance queries in a restricted context. The regression
fixtures model pre-existing native buttons, duplicate spells at distinct
visible positions, the player's pet source filter, a transient instance
lookup, and pooled reuse. The 190 appearance checks passed on Lua 5.1 and
5.4. Twenty-five existing countdown work-count scenarios matched across
three pairs. The corrected files match across all five client installs.

The open client was confirmed as Forever without moving focus or sending
input. After a reload, verify the corner and border on an actual typed
debuff and the red border on a readable untyped debuff. Native rendering
and combat validation remain pending.
[Exact source and test record](validation/live-nameplate-debuff-2026-11-22.json)

## Restock reminder scope and placement

Both anchors for the existing HUD reminder move down 16 UI units. FluxUI
shows an actionable Restock offer or expressly quoted FluxLogistics
Shopping List offer. Confirmed shopping receipts appear in the reminder as
incoming mail. A player press at the mailbox uses the existing bounded
collector for matching buyer invoices and quantities. A ready companion
craft can surface from any accepted sourcing path. An actionable FluxUI
step has priority, and a companion craft press revalidates the exact
displayed job and task.
[Forever buyer invoice code](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua#L790-L802).

Forty-five FluxUI and 16 FluxLogistics desktop fixtures passed. The layout
fixture covers 63,213 checks across five client models, the companion-owner
fixture covers 128 checks, and the mailbox fixture covers 3,960. All 45
render-work counter records match across 15 baseline and candidate pairs.
Stable and hidden updates perform zero metered widget writes. The eight
runtime files match in all five install trees. FluxLogistics is disabled on
Retail.
[Exact sources and test results](validation/restock-reminder-2026-11-22.json).

Native acceptance remains pending. Verify both HUD anchors and combat
visibility, ordinary Restock and explicit Shopping List purchases,
buyer-invoice collection alongside unrelated mail, and ready crafts
through both material routes. Include an unquoted shopping draft and an
unrelated external auction purchase as hidden cases. Check controller
reachability and the action after any quote, receipt or craft selection
changes.
[Restock handoff](FLUXLOGISTICS_RESTOCK.md).

## Debuff type corners and borders

The five desktop client models cover typed debuffs, helpful and opaque
auras, pooled nameplate reuse, secure icon and border registrations, and
settings previews. The game owns type selection on supported secure aura
buttons. Native nameplate items use public aura data or the observed
Blizzard assignment. [Retail aura artwork and types](https://github.com/Gethe/wow-ui-source/blob/ab5cb850a3f65e742959e379c4689353a2f4549f/Interface/AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua)

Compare Magic, Curse, Disease, Poison and Bleed on nameplates, target/focus,
pet tooltip, normal and compact party, and raid after reload. Check an aura
replacement, combat, and the member-frame dispel highlight. Native pixels
and taint remain pending.
[Exact source and test record](validation/debuff-type-corners-2026-11-21.json)

## Nameplate preview texture creation

The in-game 23:20 report identified the dimmer's texture constructor.
The third argument is an optional inherited template and the fourth is
the draw sublevel. Three paired desktop replays reject the original call
and pass all 139 appearance checks with the correction. All five installed
preview files match. Reopening the page after a native reload remains pending.
[Generated widget API](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua#L131-L140)
[Exact source and test record](validation/nameplate-preview-texture-2026-11-21.json)

## Published nameplates with the current settings

The live frames use the installed clients' Blizzard nameplate drivers.
The published FluxUI level, quest, threat, combo, and cast school files
match main at \`1e992c4\`. The countdown extension preserves the published
centered default and exposes the current placement and size settings.
[Exact source and validation record](validation/published-nameplate-options-2026-11-21.json).

Native acceptance is pending. Restart each installed client and compare its
normal nameplates with the published appearance. Check a quest mob with
kill and loot progress, positive threat, an interruptible cast and a timed
aura. In FluxUI's Nameplates page, verify that supported controls affect
the expected native display and that the preview and Test in Game remain
separate from the live plates.

## Compact Focus border and Party layout

21 November. The supplied Forever screenshot shows a break along the lower
bevel where the portrait meets the bars. The intended shape is the compact
player-style Party body with Focus's two aura panels above its name strip.
The baseline has SHA-256
`e0fb20a1884e6adf0538d21e8193bc091dbad5af8b5251c2eda1736a6f37f553`.

The external checkpoint `focus-border-before-20261121T202242Z` verified
127 subsystem sources, 26 saved-settings metadata entries, and complete history
through `1e992c449d59b2f1f472efc40e7ca10ea6c494cf`. Shared.lua's baseline is
`adf15cf4fe258339e5b30b3fc30817f20943bdfcd05904f5ca99f07e42ef6cc9`.
BorderJunctions.lua's baseline is
`49c64f3fc920346de680f4f88e4ae9098909f6916b10d2a885965c4f51dbb6d1`.

The 684 Party divider checks, 8,530 prediction geometry checks, 1,480
Party frame checks, 285 Focus visibility checks, and 1,075 Focus aura geometry
checks passed with the shared bar split. Health uses the full interior when
the focused unit has a publicly known absent resource. Prediction geometry
uses the same layout as the rendered Health bar.

The lower junction now draws the outer bottom bevel beneath the portrait
divider. The 20,215-check raster fixture samples the two shipped RGBA sheets
through the Core renderer. It covers the 83 × 35 body, fractional scales and
moves, the previous Party paint, and the top aura and rounded corner fields.
The same fixture rejects the checkpoint Core at the lower bevel. The 698
branch-cache, 930 unit contour, 72 Party isolation, 18,804 cap, and 21,902
cast junction checks pass. The existing structural pass builds the rim.
[Rim fixture](../tests/focus_portrait_rim.lua).

| Candidate runtime source | SHA-256 |
| --- | --- |
| `Core/BorderJunctions.lua` | `5a2ca0e3c4331bb4e89f028287a06403b33266c28bfadad9ab794a0fdbe5e674` |
| `UnitFrames/FluxUnitFrames_Shared.lua` | `4f32bd961f6338a79239ea30b308618daa361463b8da4900133a157a79319de2` |

Both runtime files match across all five installations. Native Forever
visual comparison after reload remains pending. The read-only window capture
did not contain a Focus frame.

## Unit frame preview cases and playback

21 November. The case selector offers the default sample, player and NPC
identities on target frames, buffs and debuffs where those frames display
them, and combat effects. Play runs for four seconds and repaints at most
15 times per second. It restores the selected scene on completion. Switching
cases, changing the individual component, or leaving a pane stops its
playback. The group scene animates up to three sample members and can play
one cast in a player-style Party when that setting is enabled.

Five-client desktop checks passed for the options shell (1,318), cast and
playback (2,425), prediction geometry (8,530), real Party cast overlay (835),
Party preview and Focus text anchors (1,480), Raid visuals (628), Focus aura
geometry (1,075), aura timing policy (74) and Pet tooltip ownership (605).
The focused scene fixture checks all seven layouts, friendly and hostile NPC
selection, countdown and expiry, reuse on resize, and driver cleanup. All
nine files below match all five installations (45 SHA-256 comparisons).

| Runtime source | Candidate SHA-256 |
| --- | --- |
| `_FluxUI.toc` | `ad8bfcdad64c7648c626fcf20996a8d72c880eba88984fa793c18929119566c8` |
| `AddonOptions/FluxOptionsFramePreview.lua` | `5b03ba4d0ca1e0a1b78b4e36591d10afdffb9975341541b1446bfe1d59bf5c02` |
| `UnitFrames/FluxUnitFrames_OptionsPreview.lua` | `9e33a08990fe4f6156a1e5a82c36ac513822de1e91685b17e4465f682148295b` |
| `UnitFrames/FluxUnitFrames_PreviewAnimation.lua` | `07fe5286a1e6022436c2c4b1ecfade7233c29ea7016d60240b25b3329b8e7a36` |
| `UnitFrames/FluxUnitFrames_Shared.lua` | `adf15cf4fe258339e5b30b3fc30817f20943bdfcd05904f5ca99f07e42ef6cc9` |
| `UnitFrames/FluxCastBar.lua` | `38c24532285d178d1ccb0e689d07780ee756caeaf807737e5dfcc15971d000d9` |
| `UnitFrames/FluxUnitFrames_Auras.lua` | `4aadccf7d6a7c4affc2b7bd5a1c65107f2816bedab146afb17b9b4a255f11032` |
| `UnitFrames/FluxUnitFrames_PetAuraTooltip.lua` | `9d064c98f5dbbfc8f8336635c581adb1f7615583d06bd547cf83df076aa8f759` |
| `UnitFrames/FluxUnitFrames_Party.lua` | `318f7172a83f48b93f006e76d6ccfac86662eddabf54ddfc17791abde7823447` |

Forever 1.60.1 (71037) displayed the case menu and Play. A read-only capture
at 20:09 UTC shows Player mid-playback with a cast countdown, reduced health
and power, and charged class points. A second capture shows Focus in the
Combat effects case with prediction and a raid marker. These captures were
taken before the attachment visibility and Focus text refinements. Native
NPC portraits, aura countdowns, group playback and edit timing are pending.
[Requirements](OPTIONS_REWORK.md#individual-frame-preview-parity).

## Compact Focus health text placement

21 November. The user's Forever screenshot showed Focus's health percentage
clipped at the Power boundary. The compact Focus health text host now follows
the partition's visible health band. Its fallback uses the Health bar on
clients with separate bar heights. The options sample uses the same text
hosts, scaling, divider, and indicator layout. Five-client desktop assertions
exercise the health host and power anchors, including the no-power layout.
The 285 Focus visibility and 1,480 Party/Focus fixture checks pass.
Native comparison after the Focus text correction is pending.

The final focused reruns also pass options navigation and the options shell.
The broader desktop run was taken during concurrent changes. Eight other
failure paths reproduce against the pre-change source checkpoint and still
fail when rerun in the workspace.

The shared aura sources changed during the parallel nameplate restoration.
The current mirror matches on all five installations. The independent scene
fixture passed again using the restored aura painters. The wider group aura
timer and raid tooltip fixtures reported failures after that restoration.
The updated raw SHA-256 values are listed here for those three files.

| Runtime source | SHA-256 after parallel restoration |
| --- | --- |
| `_FluxUI.toc` | `0b80edce8e6951390f66e3c57471196f7e6c634b75330d56dd52ae5183b4d279` |
| `UnitFrames/FluxUnitFrames_Auras.lua` | `a54ec6f9d45f9ab70519762b7d0c294b9f69c58111b8888cdb4f3435e9b8aecc` |
| `UnitFrames/FluxUnitFrames_PetAuraTooltip.lua` | `b02b38d0ed5040370bf38c8c8248544f6f34a4af0a36f35c72990727d9c86cd2` |

## Individual frame preview parity

21 November. The user supplied the previous Forever Player preview and an
in-world Player and Target comparison. The candidate uses the Flux unit
frame artwork and layout paths. It inherits the five supported client shapes
and the [options widget source pins](#unit-frame-settings-preview).

In the five-client desktop cast fixture, the sample uses the actual outer
header anchor for Player, Target and Focus and the actual power row for Pet.
The sample stays idle until selected and respects both cast switches. Across
all 2,215 layout checks, selected cast samples have no live cast events, update
loop, BigDebuffs sync or protected-layout defer. Repeated unchanged sample
paints allocate no frames or textures and perform zero anchor or size writes
in the fixture. The cast junction, party overlay and school theme regressions
pass 21,902, 835 and 14,411 checks respectively.

The focused desktop snapshot also passes 1,258 options shell checks, 7,277
navigation checks, 298 dynamic range checks, 1,460 player-style Party checks,
305 steady Party lifecycle checks and 628 Raid preview checks. The scene smoke
exercises all seven layouts, Target with no power bar, editor hit regions and
passive aura initialization. The portrait fit (30,816), portrait overlay
attachment (228,227), mini fit (3,634), Target chrome (2,420), combat power
layout (675), power snapshot (70), resource (122), Focus aura (1,075),
aura layout (1,702), aura policy (74) and Pet tooltip (605) fixtures pass.

The frozen runtime files match the installed bytes on all five clients.

| Runtime source | Before SHA-256 | Candidate SHA-256 |
| --- | --- | --- |
| `_FluxUI.toc` | `9b5a351f336ea1ff526d159a191e4f6e6adbf9338afdc4b217259f41ce25c206` | `c3780f031e59d6f67c1151ea5cde2e9d0aef641101c76ac2dfc90943736370fe` |
| `AddonOptions/FluxOptionsFramePreview.lua` | `b43445cbbfa759cbece1f015e0b9370f540c243bc731227791f6301588e07fa1` | `b1497afa1be2272704be2c40daba55a96ac11b7167ac35d2d9dc038fece28370` |
| `UnitFrames/FluxUnitFrames_OptionsPreview.lua` | New file | `185fe51dc497ca7fecac8a5f7810ef9f15fcd2e65e28c31483b1d7f569971d58` |
| `UnitFrames/FluxUnitFrames_Shared.lua` | `36941fc8b4fb69f262cb8584355dfa7856b4d7d43a116123023dfcdc97ac996b` | `c8f76662990a9d4eac81765fd9b9ba353e9ffe618f505001b317dc95b163ec26` |
| `UnitFrames/FluxUnitFrames_Auras.lua` | `dbeefea85945d8c2e88c6607e6fe773dc77e29539620f37803d4b3f5041b58a1` | `81a0e875701622082392d62c65d99dd6357faff505392cdb8d587f1021f0f7dd` |
| `UnitFrames/FluxUnitFrames_PetAuraTooltip.lua` | `4ec8524b82307f7c4d09af22e5d3f995f7dcd675a2820884be787c8b4a721ee5` | `75859b3497a682e8ae12cd9468acb029296aabfe71bd5f9d7e24f197de89f253` |
| `UnitFrames/FluxCastBar.lua` | `b00b2e58cbe0fb21d0c122a7fa4b85125690f494ebd87d47ed20873d657b688b` | `d416e1cecccf118e976cd8c8c20176aed1e5152b9db9f9a17385ede8d339649e` |

After the user's reload on Forever 1.60.1 (71037), read-only captures of the
first preview revision showed Player's 3D portrait, green health, blue power,
and cast sample in the same header location as the HUD. Target showed the
right-side portrait slot, a full-height health bar, and both aura holders.
There was no active target in the second capture, so it used the fallback
portrait. The 19:58:00 and 19:58:36 UTC captures are retained in the external
session folder. This confirms visible Player and Target layouts on Forever.
The other tabs, clients, edit timing and combat remain pending.

For native acceptance compare all supported Individual Frames tabs with
their HUD equivalents on each client. Include stacked and side-by-side
placement, 2D and 3D portraits, Focus presentation, the three attached frames,
and aura and cast controls. Click the name, portrait, bars and auras to verify
that each opens its existing settings. Check a size edit, a cast-time edit,
the options viewport after shrinking it, and a second open after switching
profiles. Check native input, combat, taint and edit timing separately.
[Requirements](OPTIONS_REWORK.md#individual-frame-preview-parity).

## Published FluxUI nameplates

21 November. Confirmed published main at `1e992c4` and compared the restored
nameplate module and options to that revision. The existing mirror
propagated the restored source to Retail,
Forever, Classic progression, Classic Era and Anniversary. Desktop
replays cover restored quest badges and batching, threat and visibility,
cast themes, level and countdown work, combo points, and the original settings
route. The current options shell and frame preview fixture passes 1,318 checks
across the five client models. Native game rendering and interaction after
reload remain pending. [Restoration evidence](validation/nameplate-restore-2026-11-21.json).

## Frame options edit responsiveness

21 November. The desktop fixtures pass 8,322 navigation, 1,228 shell,
1,460 player-style party, 628 compact renderer and 1,501 live raid
options checks. The slider fixture moves the thumb through 21 pointer
values and applies the latest value and draws the sample once on release.
A non-pointer adjustment applies immediately. Source checks cover the three Unit Frame pages,
legacy routes and combined tabs. The raid apply owner now refreshes the
active world preview once. Selecting another part on the same page updates
the selection marker on its own. A matched negative control that dispatches
every pointer value fails the 21-step fixture.

The integrated run in `frame-options-edit-validation.json` passed all
1,261 syntax checks and 558 smoke scripts. Eight failures reproduced at
the checkpoint. Two other scripts ran with stale navigation expectations. The current
navigation and shell replays above pass with those expectations
reconciled. A fresh syntax sweep passes all 1,265 currently discovered
Lua files. Eight focused scripts pass at the current source. The broad
run and the fresh focused checks cover different snapshots.

Five alternating desktop pairs exercised 20 warm renders of a 40-cell
embedded raid. Unchanged draws and aura-opacity edits both went from
800 cell chrome passes and 800 reparent calls to zero. Clearing anchors
fell from 42,560 to 9,600 calls. Setting anchors fell from 51,360 to
9,600 calls, and sizing calls fell from 19,220 to 4,800. The cooldown
write count stayed at 9,600. Median Lua fixture time went from 128 to
81 ms for unchanged draws and 138 to 79 ms for opacity edits. The
external `compact-options-edit-measurement.json` contains the individual
samples. The fixtures check aura-size and member-dimension changes,
the world preview repaint path and player-style portrait, accent and
layout edits. Native timing and FPS remain pending.

The checkpoint and frozen responsive-edit hashes identify this stage by
its exact local bytes. Read-only checks after the automatic mirror found
matching bytes for all ten listed runtime files in Retail, Forever,
Classic progression, Classic Era and Anniversary.

| Runtime source | Before | Candidate |
| --- | --- | --- |
| `AddonOptions/FluxOptions.lua` | `f2dfd1dfd43e5ad0669075667c08d7d3c42ec27339a9f8daf8f685c406c6c554` | `ab977249954fbff648313ee46fac0a00e6e9b96c2cfb4f5e164c29e2032a25e2` |
| `AddonOptions/FluxOptionsCatalog.lua` | `0d608e0d5fbea69dede155f8ccfdd49985aaefebd943af3ee8152e8870b26fbf` | `68221d0ab3fc8e7929ae010269595f3a8fbd552486e83130ab951fa586c7dd79` |
| `AddonOptions/FluxOptionsFramePreview.lua` | `688261f0b4d27b338f487c800d49cba126e36d475ec5faec2e28dc8cb26f974e` | `b43445cbbfa759cbece1f015e0b9370f540c243bc731227791f6301588e07fa1` |
| `AddonOptions/FluxOptionsNavigation.lua` | `c8244749f203ed633922e9f9067ac1c633c77eaf3e282717ef74127d9ff6e89b` | `7a4380c49711b91a13c21490e0a37e24da853740f900cfdf4dc6f3d4d45a77a0` |
| `AddonOptions/FluxOptionsRender.lua` | `d4ba130c2316c53554b91e9548e097b16b7634c0a018f986f20959fc364a9ed3` | `e6eedb6b842bc4138ff415da65335dd9a64980128a6e963b48089a940dd234e8` |
| `AddonOptions/FluxOptionsShell.lua` | `98381541c619082d4b9c1f0de881374391a13d88bdfd7c508c7ebc7fc492cb7d` | `50ba075aa098855e5b003fc0c094c880009e7826ab0d6a03dafec966b6c99183` |
| `AddonOptions/FluxOptionsWidgets.lua` | `c32d2ab1fe49cd2bf32585bd97cebbf87cc8f84d4ba00168144a0c99d3a563da` | `345f57192045b8427ffe5aa8fc1fb5e26c7b018b64be2750624e2c6b7b9663b7` |
| `RaidFrame/FluxRaidFrame.lua` | `7c90b47027774a13b5a386275ee94880b9ac9120cf165204e8c481e124293de0` | `2ad0b9cc9e652a00950cdab03558d57c1c46b0f76e3dd407a4700c677ddd896d` |
| `RaidFrame/FluxRaidPreview.lua` | `0b497fd95cb5f9d384cdf7cf2dbd22a667e7427ace81fdca91817549d546da25` | `83482828c0c3486c1512db92d414cf5fe545c1a43ec1ba19e08c52de61c04d20` |
| `UnitFrames/FluxUnitFrames_Party.lua` | `baf5d8b2855d164a05a6999f1f4e766b3697c9a4a6654c7a694f16d30faec059` | `be768ae442ba8167238c40258e6482c31733e4a9a0ad16a435fb9bffedc43697` |

Forever 1.60.1.71037 (PID 35620, window 1379206) showed Alchemy in the
initial read-only capture. The 19:48 CET report named `PlaceFrameTabs`
and a dependent Catalog nil error. The refreshed source builds the tabs
directly from the catalog and passes the Lua load fixture.

After the user's reload, native visual smoke showed Individual Frames
with Player active and all seven supported tabs, plus the consolidated
sidebar. A second capture showed the Party tab in Party & Raid and its
four world-style examples, including the Offline, Dead and Away states,
artwork and target strips. The external captures are
`forever-options-pre-reload.png` and `forever-options-chat-open.png`.
The first name was assigned before observing that the user had reloaded.
Enter opened chat, and the user resumed Auction House activity. Native
Pet selection, settings edits, repeated lag timings and the other
clients remain pending.

Open General, Individual Frames and Party & Raid on the pending clients.
Verify Cast Bars under General and Nameplates under Combat, drag and
release a size or aura slider, navigate and return, compare both group
previews and check pointer, keyboard, controller cursor, label fit and
combat deferral.
[Requirements](OPTIONS_REWORK.md#three-frame-pages-and-responsive-editing).

## Group preview parity

21 November. The prior parity-only snapshot used the same player-style and
compact frame painters as the world samples. The options pane owns its
own passive frame pools and click regions. It scales the entire group inside
the available area and preserves the relative size and position of its parts.
The player-style party sample uses four synthetic world rows. The compact
party uses five regular members, and the raid uses the selected 10–40
members. The compact painter also draws the optional tank and target column.

All five client source pins in the [previous options matrix](#unit-frame-settings-preview)
declare `GetFrameStrata` and `SetFrameStrata` in the generated Frame API
and `EnableMouse` in the inherited ScriptRegion API. The compact cells
inherit FluxUI's local preview template. Decorative cells share the
pane's strata and leave mouse input to the options overlay.

The desktop raid fixture passes 623 checks. The 57 additions compare
world and embedded cells for dimensions, relative positions, aura art,
health and power values, status text, range fading and prediction states.
The fixture verifies isolated party mode and dispel settings, independent
visibility and synthetic unit selection. The related aura and tooltip
suites pass.

The focused desktop replays pass 7,177 source-navigation checks,
1,393 shell checks and 1,310 player-style party checks across five
client models. The shell exercises the Main and Mini pages, party and
raid tabs, cross-tab preview clicks and separate world controls.
All 53 affected desktop scripts pass. The complete parity-only desktop
run passes all 1,260 syntax checks and 559 smoke scripts. The eight
failures reproduce at its pre-edit checkpoint, including the inventory
fixture's missing Syndicator `snapshots` state. This run preceded the
three-page and edit responsiveness revisions.

The external checkpoint and parity-only candidate hashes identify the
runtime source by its exact local bytes.

| Runtime source | Before | Candidate |
| --- | --- | --- |
| `AddonOptions/FluxOptionsCatalog.lua` | `c3e98f4dedf347fce76be774baaa8359890cff3460f104951bb5f056a1eb2714` | `0d608e0d5fbea69dede155f8ccfdd49985aaefebd943af3ee8152e8870b26fbf` |
| `AddonOptions/FluxOptionsFramePreview.lua` | `c43122d775232420c87554accaa6009a8cb24708bc0f2cdb6e071988a6b05607` | `688261f0b4d27b338f487c800d49cba126e36d475ec5faec2e28dc8cb26f974e` |
| `AddonOptions/FluxOptionsNavigation.lua` | `4d9245c28949ed79f1ed678c8b3183e8756f21d9e861f7db0e7ca6dbf4ff4c85` | `c8244749f203ed633922e9f9067ac1c633c77eaf3e282717ef74127d9ff6e89b` |
| `AddonOptions/FluxOptionsRender.lua` | `abe820d90a65240768677a4281cc1fccf1232724af3a6d16e97b9480fc8cf0e3` | `d4ba130c2316c53554b91e9548e097b16b7634c0a018f986f20959fc364a9ed3` |
| `AddonOptions/FluxOptionsShell.lua` | `265ae35260620f3e369d3f65eb7116ab85af498429db79969f21b7632b11504a` | `98381541c619082d4b9c1f0de881374391a13d88bdfd7c508c7ebc7fc492cb7d` |
| `RaidFrame/FluxRaidPreview.lua` | `89408b157a16488b35604e38a3bf41397d415752099c2362f9d30880be4e2c22` | `0b497fd95cb5f9d384cdf7cf2dbd22a667e7427ace81fdca91817549d546da25` |
| `UnitFrames/FluxUnitFrames_Party.lua` | `35e44755c1679474640f01a3047e6862f38b34c29161ea39fb0c2d82b50556b8` | `baf5d8b2855d164a05a6999f1f4e766b3697c9a4a6654c7a694f16d30faec059` |
| `UnitFrames/FluxUnitFrames_Shared.lua` | `af962698d17f8126fda1f85f8759950f0dd81d9edeb8a3e85e0f4637e854834a` | `36941fc8b4fb69f262cb8584355dfa7856b4d7d43a116123023dfcdc97ac996b` |

Native acceptance remains pending. On each client, compare the solo world
and right-hand samples using both party layouts and a raid with the same
selected settings. Check four player-style rows, five compact members, both
ends of the raid roster range and the tank column. Compare at matching
scale, including Offline, Dead and Away samples, both aura sides and
attached target strips. Verify editing from preview regions and shortcuts,
switching between the Main and Mini pages, the party and raid tabs,
narrow-window fit, controller cursor operation, isolated world toggle,
scope persistence and combat deferral. Use the established Witchcraft
route for Forever.
[Requirements](OPTIONS_REWORK.md#group-preview-parity-and-frame-settings).

## Unit-frame settings preview

21 November. The inline samples use ordinary frames, buttons, textures and
font strings drawn from synthetic values. The five pinned source contracts
declare texture and font-string creation, clipping, scaling, click registration
and button highlighting. All five executable file versions were read on disk.

| Client | Executable file version | Interface | Pinned frame declarations |
| --- | --- | --- | --- |
| Retail | 12.1.5.70961 | 120105 | [live](https://github.com/Gethe/wow-ui-source/blob/ab5cb850a3f65e742959e379c4689353a2f4549f/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua) |
| Forever | 1.60.1.71037 | 16001 | [forever](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua) |
| Classic progression | 5.5.4.70631 | 50504 | [installed build](https://github.com/Gethe/wow-ui-source/blob/e5d9b3a22c3f0f6f41ebac0e454f4969594261cf/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua), [5.5.4.71060 branch head](https://github.com/Gethe/wow-ui-source/blob/e171ae99b8e582ce9547bd8fc87054fe2e348f20/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua) |
| Classic Era | 1.15.9.70576 | 11509 | [classic_era](https://github.com/Gethe/wow-ui-source/blob/4192ac60067fc55566182291bc67c85dd9b6794d/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua) |
| Anniversary | 2.5.6.70577 | 20506 | [classic_anniversary](https://github.com/Gethe/wow-ui-source/blob/68e0a2ec559d9761dfc4e7f864c3944f9d758a49/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua) |

The progression pins carry identical generated declarations for Frame,
Button, Region, Texture and FontString. Source verification covers the widget
API. Native render and operation checks remain pending.

The desktop model passes 1,333 shell and menu checks, 6,847 source navigation
checks and 298 dynamic range checks across five client contracts. The raid
aura and existing world preview fixture passes 280 checks. The scoped raid
aura apply fixture passes 1,495 checks. The shell replay covers the new pane,
component clicks, unit type switching, automatic refresh after an edit,
compact party routing, 40-member bounds at narrow width, and cleanup when
closing or leaving the frame pages.

The full desktop suite passes 1,259 Lua syntax checks and 559 smoke scripts.
The seven failing smoke scripts also fail at the pre-edit checkpoint.
[Recorded desktop run](reference/verification.json).

The candidate and external checkpoint SHA-256 values identify the exact
local file bytes, including work already present before the rework.

| Runtime source | Before | Candidate |
| --- | --- | --- |
| `AddonOptions/FluxOptionsCatalog.lua` | `502cf4c5979b2be078a09ddb76609d1ef30b663e5850763bc4441f21b00db55f` | `c3e98f4dedf347fce76be774baaa8359890cff3460f104951bb5f056a1eb2714` |
| `AddonOptions/FluxOptionsNavigation.lua` | `036071bdbc179a2b91518d8a2539bbab1d66373a327e69869313db270f9bb55a` | `4d9245c28949ed79f1ed678c8b3183e8756f21d9e861f7db0e7ca6dbf4ff4c85` |
| `AddonOptions/FluxOptionsRender.lua` | `d891a227a481648c67d6cab1ace2acfdeb1ffb75e179c3307d7a94f8164553aa` | `abe820d90a65240768677a4281cc1fccf1232724af3a6d16e97b9480fc8cf0e3` |
| `AddonOptions/FluxOptionsShell.lua` | `959b7acd841abe231935ab8f95610d982f9ca4a24bbc2b32cb6a4ce73b22f133` | `265ae35260620f3e369d3f65eb7116ab85af498429db79969f21b7632b11504a` |
| `AddonOptions/FluxOptionsWidgets.lua` | `3aa27fd77435cf632d1849cef195d970e56721065101d3a2fb361e06aeaee7dc` | `c32d2ab1fe49cd2bf32585bd97cebbf87cc8f84d4ba00168144a0c99d3a563da` |
| `AddonOptions/FluxOptionsFramePreview.lua` | New file | `c43122d775232420c87554accaa6009a8cb24708bc0f2cdb6e071988a6b05607` |
| `_FluxUI.toc` | `0a6bdd516bfc1e7a7fc528bbab341ce2a35033f5a24a1e0fb299234d5c3161aa` | `e3dad2d45012864dbbf04fbfc2402492341550e44d4adcff662eeba55cec69bd` |

In each client, open FluxUI through AddOns in Settings and the Escape menu.
Switch the individual unit tabs, check the two party layouts and resize the
raid roster. Click a bar, a text region and both aura types, edit a visible
setting, and verify that the preview and the saved profile agree after
closing and reopening the options. Check the narrowest window width,
controller cursor reachability, section scrolling, Escape and combat
deferral. Test world previews separately. Forever keeps the preferred
Witchcraft route. Native pixels, taint, controller access and localized
layout remain pending.
[Requirements](OPTIONS_REWORK.md#unit-frame-preview-editor).

## Shared unit-frame aura countdowns

21 November. Verify the General countdown toggle on target, focus, both party
layouts and raid. At 60 seconds the labels are hidden when the toggle is on,
then appear below 60 seconds while the cooldown swipes continue. Check both
buffs and debuffs, scoped settings and a change applied after combat.

| Client | Installed version | Interface | Pinned Blizzard source |
| --- | --- | --- | --- |
| Retail | 12.1.5.70961 | 120105 | [live](https://github.com/Gethe/wow-ui-source/tree/ab5cb850a3f65e742959e379c4689353a2f4549f) |
| Forever | 1.60.1.71037 | 16001 | [forever](https://github.com/Gethe/wow-ui-source/tree/734f065329cff4992835b01a84f210a297db91b6) |
| Classic progression | 5.5.4.70631 | 50504 | [installed source](https://github.com/Gethe/wow-ui-source/tree/e5d9b3a22c3f0f6f41ebac0e454f4969594261cf), [branch head](https://github.com/Gethe/wow-ui-source/tree/e171ae99b8e582ce9547bd8fc87054fe2e348f20) |
| Classic Era | 1.15.9.70576 | 11509 | [classic_era](https://github.com/Gethe/wow-ui-source/tree/4192ac60067fc55566182291bc67c85dd9b6794d) |
| Anniversary | 2.5.6.70577 | 20506 | [classic_anniversary](https://github.com/Gethe/wow-ui-source/tree/68e0a2ec559d9761dfc4e7f864c3944f9d758a49) |

The inspected client builds declare numeric rule formatters and the cooldown
countdown binding. Classic progression's installed pin and branch head use the
same formatter and cooldown declarations. [Classic cooldown options](https://github.com/Gethe/wow-ui-source/blob/e5d9b3a22c3f0f6f41ebac0e454f4969594261cf/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPICooldownDocumentation.lua#L345).

The current focused replay passes 74 checks of the timer policy. Party, raid,
tooltip and preview replays cover the restored FluxUI aura artwork and dispel
indicators. Verify the resulting artwork and eligible dispel highlights in the
native clients alongside the countdown transition and post-combat refresh.
[Source and desktop evidence](validation/unit-frame-auras-2026-11-21.json).

21 November. Vendor automation passed desktop replay for Retail, Forever, Classic progression, Era and Anniversary merchant layouts. All five installed `FluxVendorBuy.lua` files match SHA-256 `7539c3e5ac07067a1dee38297be7ba55200dab7c2037e8a5f6f6c246d9b66366`. Native transactions and the loaded client remain unverified. [Merchant sequencing](20-vendor-restock-junk.md#merchant-lifecycle-and-automation-ordering).

21 November. The FluxLogistics owner bridge has automated desktop coverage for inherited/disabled restock policy, competing coverage, and native action arguments routed through bank and vendor fixtures. Forever and Classic native input, layout, controller, client calls and stock confirmation remain pending. [Contract](FLUXLOGISTICS_RESTOCK.md).

## Side-button border reveal

21 November. R193 passes modeled first-frame join and rim stability checks in
both border types across mixed map, grid and UI scales. The runtime sources
match the five installations on disk. The embedded grid is centered through
window resizing, Map tab changes and deferred count updates in the desktop
model. Native appearance, input, timing and taint checks remain pending.
[Evidence](validation/minimap-hover-dock-r193-2026-11-21.json).

## Standalone minimap restore

21 November. The desktop integration fixture restores the standalone header
and layers with side buttons disabled for modern and legacy minimap widths.
It covers immediate restore, combat deferral and rapid toggles in combat.
Mail lifecycle tests cover different icon heights, both inset policies and
hidden tracking. The updated source matches all five local installations.
Native placement, input and taint checks remain pending.
[Evidence](validation/minimap-standalone-restore-2026-11-21.json).

## Forever mount collection

22 November life-state follow-up. The 317 focused checks reproduce the prior
bright icon while dead even with a usable journal answer. The candidate dims
on death and release, hides a stale mounted wisp, retains the binding and mount
selection when the journal turns cold, and recovers after resurrection. The
shared usability lane also dims the mount on a taxi. Seven related scripts pass.
Native visuals, combat and input remain pending. Both changed sources match
the Forever install on disk.
[Forever life queries](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua#L1931-L1946).

21 November taxi follow-up. The personal-mount display uses the native player
taxi flag alongside the mounted flag. The 283 desktop checks cover both flags
being true, boarding through the control event, landing, personal mounts
after travel and a visual update during combat with no protected writes.
The prior source fails the combined-flags assertion. The flight timer, vendor
mount and bag mount scripts pass. Native boarding and landing remain pending.
[Forever taxi query](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua#L2570-L2582).

21 November combat dismount follow-up. The existing secure button runs
Forever's native conditionals and `/dismount` command. Default and modifier
actions have a combat dismount branch before combat starts. Mounted display
events toggle the wisp texture on the existing frame. Combat invalidations
retain the current journal and riding cache while the existing readiness
window handles recovery after combat. The 275 desktop checks include the
modifier race, a dismount in the macro model, unchanged hotkeys, cold journal
recovery, and no protected writes in combat. Eight related scripts pass.
Native combat dismount, wisp pixels and controller activation remain pending.
[Forever dismount command](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_ChatFrameBase/Shared/SlashCommands.lua#L1285-L1289).
[Secure macro execution](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L450-L464).

21 November world-entry follow-up. Ordinary Forever `PLAYER_ENTERING_WORLD`
arrives with both startup flags false. The button keeps the prior action from
`PLAYER_LEAVING_WORLD` through one readiness check at 0.25 seconds and one
optional retry at 1 second after entry. A new world transition cancels older
checks. The action cache resets when the placeholder clears secure attributes.
The arrival update reapplies the base, modifier and journal actions and the
keyboard binding. Combat defers protected writes to the existing regen path.
The 239 focused desktop checks and nine related scripts pass. The previous
runtime and cache-only control reproduce the two failures. Source matches
the Forever installation. Native teleport, pixels, input and taint remain pending.
[Forever world events](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/SystemDocumentation.lua#L133-L148).

21 November usability follow-up. The standard Extra Button tint now remains
applied when the mount icon refreshes. The selected journal mount's live
usability includes indoor restrictions, as in the native Mounts tooltip.
Combat dims the face through the existing event and preserves its identity.
The 176 desktop checks cover a usable journal mount with a false generic
spell result, indoor and combat transitions, exact modifiers, sticky lock,
and the ordinary shared usability refresh. Ten related scripts pass. Two
mixed-source replays independently reproduce the prior icon and painter bugs.
Both candidate files match the Forever install. Native tint, casting, gamepad
and taint checks remain pending through the preferred Witchcraft route.
[Journal contract](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/MountJournalDocumentation.lua#L339-L356).
[Native tooltip](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_Collections/Mainline/Blizzard_MountCollection.lua#L843-L861).

21 November compact panel follow-up. The 148 focused checks exercise dynamic
height and visibility, the Add modifier choice list, journal selection and
drag/drop, scope switching, and the tooltip through the actual modifier and
hover callbacks. They include a saved but unavailable override that returns to
Default and a placeholder with no usable collected mount. Five related scripts
pass. The previous panel fails the hidden-unassigned-slot assertion. Both changed
runtime files match the Forever installation on disk.

The picker uses `Core/FluxBlizzardDropdown.lua` with its existing Forever gamepad
menu routing and the pinned native dropdown generator. Set and Clear actions
have native buttons. The desktop test exercises the menu entries without a
native UI renderer. Native panel fit, hover and gamepad navigation remain pending.
[Forever dropdown](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_Menu/DropdownButton.lua#L229-L268).

21 November. The installed build manifest lists Forever `1.60.1.71037` with
FluxUI interface `16001`. Gethe's matching source commit is
`734f065329cff4992835b01a84f210a297db91b6`. The native pane owns the selected
mount ID, the journal exposes ownership and usability, and the secure template
orders modifier prefixes Alt, Ctrl, Shift. The riding path reads the skill rank
and tracks `SKILL_LINES_CHANGED` alongside existing spellbook and journal events.
[Mount pane](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_Collections/Mainline/Blizzard_MountCollection.lua#L790-L857).
[Journal API](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/MountJournalDocumentation.lua#L275-L360).
[Skills API](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/SkillInfoDocumentation.lua#L74-L121).
[Secure buttons](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L70-L129).

The 106 focused checks exercise the actual configuration and button modules,
including skill training, collection updates, all eight routes, tooltip/icon
identity inputs, account/character data, drag/drop, clearing, sticky mount and
combat deferral. Modifier previews make zero additional journal reads on the
warm cache in this test. The vendor and bag-mount regression suites also pass.
The runtime sources match the Forever installation on disk.

The repository-wide desktop run compiled 1,255 Lua files and reported 556
passing scripts and nine failures. Eight failures reproduced with the prior
mount sources. The remaining bars smoke check passed with both mount revisions
when replayed after concurrent bars changes.

The panel uses native Set and Clear buttons as alternatives to dragging and
follows the native Mounts pane when switching tabs or closing Collections.
Its new hints use English fallback text. Directional controller focus, glyphs,
native cast and dismount, pixels, persistence after reload, taint and timing
remain pending. The preferred Witchcraft route had no connection in this session.

## Forever action button cooldown

21 November. The player posted the same Forever collector stack again at
00:14:28 and 00:15:53 and reported the symptom on Retail as well. The two
pasted stacks match Forever 1.60.1.70959. The installed Retail build
12.1.5.70783 has the same native route at lines 220–223, 823–847 and
966–967, at source commit `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`.
Whether the 20 November code had loaded in the reported session remains
unverified. The current taint logs predate the reports. The pasted
messages omit the failing cooldown frame's name.
[Retail source](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButton.lua#L823-L849).

`/fluxinput cooldown` records one opt-in snapshot of the active client's
build, Flux bar readiness, the collector's cooldown subscription, and
metadata for the collector's button entries, callbacks, and cooldown
widget setters. It preserves two snapshots. It reads field ownership
without calling the collector or reading spell cooldown values. Reload
to load the command, use it before and after reproducing the fight, then
reload after combat to save. In BugTabs, retain the failing frame's name
if the Locals section contains it. Two diagnostic scripts and two Lua
syntax checks pass. The command is present on disk in both installations.
Native attribution remains pending.
[Diagnostic](../Other/FluxInputDebug.lua).

20 November. `FOREVER-ACTION-COOLDOWN-20261120` matches each Lua frame
in the 22:46:28 stack to Forever 1.60.1.70959, source commit
`3d8abb1da73acd38e412e24fb3f99454a6392346`. The failing route is
`ACTIONBAR_UPDATE_COOLDOWN` through the shared button collector to the
normal cooldown. `SetCooldown` accepts secret arguments only during
untainted execution. The player reported that the error occurred while
casting or fighting. The running Forever executable and main window were
verified. Its retained taint log predates this report, so the first
writer remains unknown.
[Collector](https://github.com/Gethe/wow-ui-source/blob/3d8abb1da73acd38e412e24fb3f99454a6392346/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButton.lua#L230-L235)
[Cooldown contract](https://raw.githubusercontent.com/Gethe/wow-ui-source/3d8abb1da73acd38e412e24fb3f99454a6392346/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPICooldownDocumentation.lua).

The stock FX pass directly hid `SpellCastAnimFrame`. Its native
`OnHide` invokes `ActionButton_UpdateCooldown` from that caller's
execution context. Forever now leaves this child to its native
animation lifecycle under the existing alpha suppression. The desktop
replay ran the pinned collector, button event, cast hide, and cooldown
methods with a modeled secret argument. The checkpoint attempted one
addon-driven cooldown call per tested pass, and the candidate attempted
zero. Both applied one cooldown through the native event. The 61-check
bar suppression script and nine related scripts passed, as did both Lua
syntax checks. All five installed runtime files match on disk.
[Cast animation handler](https://github.com/Gethe/wow-ui-source/blob/3d8abb1da73acd38e412e24fb3f99454a6392346/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButton.lua#L1840-L1846)
[Regression](../tests/bars_edit_mode.lua).

After reloading outside combat, repeat the original fight or cast the
same spell in combat and watch its cooldown through cast completion.
Check for the shared-collector stack and verify mouse, key, and controller
input. Forever retains the existing Witchcraft preference. This session
offered no Witchcraft connection.

## Flight timer rework

20 November. `FLIGHT-TIMER-20261120` passed 120 checks across Retail, Forever,
Classic progression, Era and Anniversary desktop models. They exercise the
real taxi owner and cast bar, including modern pin and legacy button tooltips,
directed multi-stop estimates, automatic correction, elapsed-only display,
reload, fresh login, cancellation, death and stale records. The idle model
does zero taxi polls. The active driver polls about five times per second.

The repository-wide desktop run compiled all 1,254 Lua files. It recorded
555 passing scripts and nine failures in the Bars, Junk, alpha-reader,
restock, combat-grid, map and raid fixtures. The passive unit-style failure
reproduced with the archived cast bar at the same raid health accessor.
The 11 focused flight, cast, options and timer-header scripts passed.

API declarations were checked against the bundled Retail `12.1.5.70783`,
Forever `1.60.1.70938` and Classic progression `5.5.4.70631` source pins.
Current branch tips could not be resolved. Retail and Forever's flight map
source uses taxi slot indices to preview and take a route. Era and Anniversary
retain the legacy slot and coordinate adapter. That branch has desktop coverage.
[Retail declarations](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/TaxiMapDocumentation.lua)
[Forever pin provider](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_FlightMap/FM_FlightPathDataProvider.lua)
[Classic declarations](https://github.com/Gethe/wow-ui-source/blob/e5d9b3a22c3f0f6f41ebac0e454f4969594261cf/Interface/AddOns/Blizzard_APIDocumentationGenerated/TaxiMapDocumentation.lua).

Native acceptance remains pending. On each client, hover then select a different
node, measure one complete trip and check the next tooltip. Repeat the learned
route with a UI reload and a separate logout/login, compare the ETA with actual
landing, and check an early landing on a multi-stop route. Verify the native
tooltips and cast bar through landing and check for Lua errors. Retain the
prior Witchcraft testing preference for Forever. No Witchcraft tool was connected.

## Other client validation

20 November. `FOOD-WATER-STACKS-20261120` passed 27 focused desktop checks.
Pinned Retail `12.1.5.70783` and Forever `1.60.1.70938` FrameXML route the
secure item argument through `SecureCmdItemParse` and accept the `bag slot`
form. The local Classic progression `5.5.4.69155`, Era `1.15.9.68808`, and
Anniversary `2.5.6.68775` snapshots have the same parser. Latest source tips
could not be resolved in this environment. The initial loaded hook produced a
user-reported `Bridge` accessor error. All five installed copies now match the
corrected source. Native mouse and key use, the optional swap, and blocked-action
checks remain pending after reload.
[Retail source](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua#L1104-L1127)
[Forever source](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua#L1118-L1141).

20 November at 12:14 CET. The repeat report named line 2957. The running
window was verified as the Forever executable, whose installed file had the
corrected SHA-256 `0576edeae4e0e5ae9bcd1987644dff2c3fef4a947d2eb91e2f9ef3bb2e425ebe`.
That line is a macro guard in the corrected file. The last logged UI shutdown
and saved-variable write were at 11:51:50, before the fixed file's 11:56:25
write. The click regression passed again against the installed source.

20 November. The Auction Restock tooltip and profession cache fixes passed
desktop checks for Retail, Forever, Classic progression, Era and Anniversary.
Both installed Lua files match byte for byte across all five clients.
`Inventory/Professions.lua` SHA-256
`41d039dc13612f058367366d63f09e002681cfe8030bf6e8b8ee6da8cd50144b`.
`Inventory/Restock/Auction/FluxAuctionRestockUI.lua` SHA-256
`8880d3435748662a164efb792941f30fb7959e7d53d5529c7f11b4338a3870f0`.
Native hover, closed-profession planning and Pending execution remain pending.
[Auction Restock](AUCTION_RESTOCK.md#saved-recipes-and-row-hover).

20 November. Forever 1.60.1.70959 was running in the verified WoW window. The
original-map candidate passes the desktop combat lifecycle checks on Lua 5.1
and 5.4. Live combat event ordering and taint remain pending after reload.
[Evidence](validation/world-map-combat-2026-11-20.json).

<!-- LHO-ACCEPTANCE-INSTALL-BASELINE-20261120 -->
20 November. After the performance goal resumed, all five installations matched all 90 closeout Lua hashes and the shared `_FluxUI.toc` hash `50dd0fa7c812000e357e0a5be5885773ace4cc1ec2fc1e7c8675a35e74f52dc5`. The installed executable versions are Retail 12.1.5.70783, Forever 1.60.1.70959, Classic progression 5.5.4.70631, Era 1.15.9.70576, and Anniversary 2.5.6.70577. These are on-disk identities. The live smoke checks still need evidence from the loaded clients. [Acceptance checklist](INVENTORY_PERFORMANCE_ROADMAP.md#final-acceptance-checklist).

<!-- LHO-OPTIMIZATION-CLOSEOUT-20261120 -->
20 November. The closeout compiled 90 scoped Lua files and verified byte-for-byte matches across Retail, Forever, Classic progression, Era and Anniversary. All 82 selected regression scripts passed. The roadmap retains the exact remaining native scenarios. [Closeout](INVENTORY_PERFORMANCE_ROADMAP.md#finish-point).

<!-- LHO-CONJURED-CACHE-READ-20261120 -->
20 November. Forever with Syndicator and Baganator passed the loaded cold-open and settled metadata check for the 41 item IDs sampled. The test restored the closed backpack and recorded zero new Lua errors. Positives were unavailable in the live sample. Other native clients still need validation. [Evidence](validation/backpack-final-callback-2026-11-19.json#settledConjuredMetadataReads).

<!-- LHO-BANK-CLOSE-LATCH-20261120 -->
20 November. Forever with Syndicator and Baganator reproduced a visually closed bank while all shared inventory and Restock gates remained live. On the loaded fix, R676 observed the same close events, five clear gates, 21 cached counts matching live, and zero new Lua errors. Focused tests cover close and fresh reopen across all five families. Checks on the other native clients remain pending. [Evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeBankSlotMoveAndCloseLatch).

<!-- LHO-BANK-TIER-SETTLED-KIND-20261120 -->
20 November. The Forever bank open ran with Syndicator and Baganator. The real tier-candidate comparisons matched the zero-withdrawal result across six pairs with zero Lua errors. All five installed sources match. Positive withdrawal, loaded comparison, cold close and native checks on other clients are pending. [Evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenBankTierKindWork).

<!-- LHO-BANK-VIEW-LOADED-20261120 -->
20 November. Forever R665 verified the installed visibility sources and exact matches for two frames, nine shared targets, six visible Auction rows, one hidden row and potion facts. Money and inventory stayed stable with zero new Lua errors. R663 separately covered the warm open-bank tooltip and button for its four-row zero-pull profile. Real bank changes and additional clients remain pending. [Loaded comparison](validation/baganator-bank-view-index-2026-11-19.json#loadedFallbackFrameNames). [Open-bank timings](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenBankRestockButton).

<!-- LHO-BANK-VIEW-FALLBACK-NAMES-20261120 -->
20 November. Forever R662 compared 21 actual character-bank item counts and 22 slots against the independent native reads. All aggregate, stack, lock and location checks matched with zero Lua errors and unchanged carried generation and money. R660 compared isolated candidate visibility reads with the loaded original. A reload was deferred while the actual bank remained open. [Visibility evidence](validation/baganator-bank-view-index-2026-11-19.json#fallbackFrameNames). [Open-bank evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenCharacterBankStackParity).

<!-- LHO-RESTOCK-TARGET-ATTRIBUTION-20261120 -->
20 November. R656 to R658 recorded native Forever 70959 timings with Syndicator and Baganator. R658 reproduced nine exact target rows with stable money, bag and bank generations and zero new Lua errors. Open bank, real commerce updates and other clients remain pending. [Evidence](validation/bank-tier-matcher-2026-11-19.json#nativeRestockTargetAttribution).

<!-- LHO-RESTOCK-TIER-RECORD-FILTER-20261120 -->
20 November. On Forever with Syndicator and Baganator, R655 matched all 205 carried tier verdicts, completed six visible and one hidden Restock rows and the closed-bank count reads, and kept money and bag generation stable with zero new Lua errors. The exact ownership regression covers the initial failed branch. Native open-bank, vendor and other client acceptance remain pending. [Evidence](validation/bank-tier-matcher-2026-11-19.json).

<!-- LHO-AUCTION-INITIAL-PLAN-PAINT-20261120 -->
20 November. Forever with Syndicator and Baganator loaded both startup-paint edits. A real Auction open showed the native auction-waiting status and kept the same six visible and one hidden row. Money, stock and errors were stable, and the panel and observers were cleaned up. Warm repeat and other native clients remain pending. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-ROW-ORDER-ALLOCATION-20261120 -->
20 November. Forever with both external inventory addons loaded the row comparator edit. In the real Auction Restock open, the six visible rows matched the exact prior order. Money and bag generation were stable. The observer restored and the Auction House closed with no new Lua errors or transaction. Other native clients and active buy and Pending flows remain open. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-CATALOGUE-REVOCATION-VALIDATION-20261120 -->
20 November. On Forever with both providers loaded, R636 after reload matched native and Flux counts of 18, kept both Extra Button grid selections, completed the stack return with empty cursor and destination, and reported zero new errors. Two experimental native removal paths matched 149 ordered row identities. The full guarded alternative stayed out of production. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-TEXT-ALIAS-20261120 -->
20 November. Forever with Syndicator and Baganator matched the item receipt and food face. The native before/candidate catalogue comparison matched all 149 ordered record identities. The updated production source was loaded. Focus changes stopped both post-reload move checks before input. Loaded workflow and other client measurements remain open. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAGANATOR-LAZY-CATEGORY-ICON-20261120 -->
20 November. Forever with Syndicator and Baganator 862 tested ordinary backpack category labels before and after reload. Both runs returned to closed bags, kept bag generation stable, restored the observer and reported zero new Lua errors. Both saw the same count of anchor-preserving and anchor-normalizing applications. Real managed icons and recycled-label transitions need native coverage. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-CRAFT-POTION-FALLBACK-STATIC-20261120 -->
20 November. Forever with both inventory providers loaded the potion fallback change and passed the closed-backpack move and return. Both grid signatures and counts matched, one delayed event arrived per direction and no Lua errors appeared. Positive fallback parity and provider replacement are covered on five desktop family shapes. Positive native fallback and the other client checks remain open. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CAST-WIDGET-ENTRY-INDEX-20261120 -->
20 November. Forever with both inventory providers loaded and matched the ButtonFX registration index across 195 actual buttons in R625. The real Food cancel retained three callbacks and 185 target resets each, with the bag generation stable and no Lua errors. This profile showed no active interrupt owner for Food. Active reticle, other spells and other native client coverage remain pending. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-AUCTION-SEARCH-PREPAINT-LIVE-20261120 -->
20 November. Forever with both inventory providers confirmed native cold startup, warm reopen using current prices, and warm startup after natural expiry. R622 preserved row counts, bag generation, player money and closed state. Observers were removed, with no transaction or new Lua errors. Native potion browsing and other client checks remain pending. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-SEARCH-PREPAINT-20261120 -->
20 November. Forever Baseline R617 through R619 opened and closed the live Auction House and Restock panel with both providers loaded. The observed bag generation, money and transaction state were stable, no new errors appeared and all observers restored. The optimized path on native Forever and the other clients remains pending. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROTECTION-EMPTY-SLOT-LOOKUP-20261120 -->
20 November. Forever with both providers matched 52 actual slot verdicts with an empty protected map. Bag generation held and no Lua errors appeared. Both backpack passes closed. Populated protected slots, live vendor context and native checks on other clients remain pending. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-NUMERIC-CATALOGUE-OPEN-BAG-20261120 -->
20 November. R612 passed the open-backpack move on Forever with Syndicator and Baganator. One redraw per direction matched the R602 callback count. Bag contents, checked Extra Button assignments and cleanup passed. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-NUMERIC-CATALOGUE-LIVE-BAG-20261120 -->
20 November. Forever with Syndicator and Baganator loaded the updated catalogue and passed one real closed-backpack move and return. Three Craft lists ran in each direction. Checked Extra Button selections, both count readers and the restored cursor and item slot matched. Native adoption on other clients and the open-backpack repeat remain pending. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-NUMERIC-FULL-CATALOGUE-20261120 -->
20 November. The exact Professions source matches five installed client paths. The recipe data and row parity came from the Forever saved catalogue in host Lua. Native callback timing, client-specific event delivery and reload adoption are pending. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAG-MOVE-CRAFT-CATALOGUE-20261120 -->
20 November. Forever build 70959 with both inventory addons passed an open-category bag slot relocation and return. Each direction delivered one bag event and kept all 18 items, the original grid selections and clear cursor. Scope covers one count-neutral stack. Native changed-count, additional providers and client editions remain open for these latest measurements. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-RESTOCK-REAGENT-VISIBLE-PASS-20261120 -->
20 November. Forever build 70959 with Syndicator and Baganator passed the installed warm Restock reagent optimization. All six visible rows, one hidden vendor row and the potion targets matched across six paired rebuilds. Observers restored and no Lua errors appeared. Commerce windows were closed. Native cold, open-session, Pending and other-client checks remain due. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-PROFESSION-FILTER-CANDIDATES-20261120 -->
20 November. Forever 70959 with both providers passed the native Have Materials guard and restoration for Tailoring. The saved catalogue and all 369 removals matched across 102 visible, zero visible and 102 restored recipes. Other clients, active craft and Restock-open checks remain pending. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-CURRENT-PASSIVE-20261120 -->
20 November. Forever with both providers passed the scoped passive Tailoring observation. Saved learned and removal facts matched at the observed list events and there were no delayed bag events or new errors. Restock was closed. Cross-client/provider, active crafting and whole-frame comparisons remain open. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-RETAIN-SAVED-REMOVALS-20261120 -->
20 November. Forever 70959 with Syndicator, Baganator and BugTabs passed the loaded ready-source check, with all 102 recipe rows and 369 persistent removals equal under both keys. All four paired runs matched. Tailoring closed and the probe reported zero new Lua errors. Real changed filters and learning, other clients/providers, frame time and visual parity remain pending. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-FIRST-READY-READ-COST-20261120 -->
20 November. Forever build 70959 with both providers passed the Tailoring read-cost probe. All 369 unlearned records and spellbook negatives agreed in the sampled profession, and all 102 learned records returned an output item ID. Native absence and exclusion cases, changed filters and other clients remain open for the proposed first-ready-source reduction. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CAST-MATCHER-NUMERIC-20261120 -->
20 November. Forever 1.60.1 build 70959 interface 16001 with Syndicator, Baganator and BugTabs passed loaded casting matcher parity for 117 pairs from a real Conjure Food interrupt. The case found zero owning-button matches. The bag generation stayed stable and no new Lua errors appeared. Positive matches, legacy rank and string cases have focused regression coverage. Whole-cancel frame-time, other clients and actual owner animations still need native checks. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-CAST-POSITIONAL-PAYLOAD-20261120 -->
20 November. The new positional payload regression passes across five client models. All five installed sources match and pass Lua 5.1 and 5.4 syntax. Loaded Forever kept spell 6129 on start, cancel and successful completion. Native and FluxUI food totals matched at 42 before and 56 after the completed cast. Native restricted Retail and other clients still need checking. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-OWNED-IDLE-RETICLE-CLEANUP-20261120 -->
20 November. Forever 1.60.1/70959/16001 with Syndicator and Baganator verified 200 matching idle reticles per paired pass. Real playing and paused groups cleared on a bar and an Extra Button. Eight regression scripts and ten installed syntax checks passed. Native combat and the other clients remain open. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-CAST-INTERRUPT-TARGET-RESET-20261120 -->
20 November. Forever 1.60.1/70959/16001 with Syndicator and Baganator delivered three interrupts on each of two real Food cancels. R566 matched frame time for the three interrupts and observed no visible or playing target reticle or visible spell highlight on the 200 reset calls per event. Completion, combat interrupts, active target effects and other clients remain separate acceptance cases. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-PROFESSION-SOURCE-STORE-ATTRIBUTION-20261120 -->
20 November. Native Forever Tailoring reopen recorded one ready source and two list deliveries. The test panel closed, all observers restored and no new errors or generation changes were observed. The cast replay remains pending after the foreground guard rejected the input epoch. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-COMBINED-REAGENTS-20261120 -->
20 November. The loaded Forever edit preserved all 102 Tailoring recipes and saved removal flags on the new ready source and the same-frame list event. Tailoring closed and its observer restored, with no new errors or bag generation change. All five installed copy hashes match and passed Lua 5.1 and 5.4 syntax checks. Native checks outside this Forever context remain open. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-READY-SOURCE-COUNTER-20261120 -->
20 November. Forever 1.60.1/70959/16001 reached Tailoring counters 32 on loading show and 33 on the first ready source and list events, then returned to nil on close. Each event left 102 saved entries. The ready source and list both matched the preceding read of saved rows and removal data. No errors or bag generation change occurred. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAGANATOR-JUNK-SETTINGS-20261120 -->
20 November. Forever 1.60.1/70959/16001 with Syndicator and Baganator verified the installed Junk display settings change. Both 59-slot reads matched the verdict and fallback counts. The earlier and loaded category views acquired 54 item buttons from the pool, created none and built nine live layout groups on first open. All five installs match source. Native parity on the other clients and provider setups remains open. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-PENDING-IDLE-REFRESH-20261120 -->
20 November. Forever 1.60.1/70959/16001 with both external inventory addons retired the temporary observer after matching all 192 no-job reads per revision. No Lua error or bag generation change occurred. All five installs match and passed ten Lua syntax checks. Eight Lua 5.4 scripts and four Lua 5.1 scripts with the fixture compatibility shim passed. Live jobs still need native coverage. [Evidence](validation/inventory-idle-followup-native-2026-11-18.json).

<!-- LHO-RESTOCK-BANK-STACKS-LOADED-CLOSED-20261120 -->
20 November. With the updated files loaded on Forever 1.60.1/70959/16001, R552 confirmed 21 of 21 cached counts against native aggregate counts, zero closed-bank stack results and zero new Lua errors. Bag generation was stable, bank generation was one and both external inventory addons were loaded. Positive native stack, charge and timing checks remain open. [Evidence](validation/bank-tier-live-counts-2026-11-19.json).

<!-- LHO-RESTOCK-UNIQUE-BANK-STACKS-20261120 -->
20 November. The Restock stack change matches all five installed source copies and passed ten syntax checks. The target regression passed on Lua 5.1 and 5.4. Running client adoption and open-bank workflow timing are pending. The independent Forever R550 closed-bank check matched all 21 positive counts, with stable generations and no new Lua errors. [Stack evidence](validation/bank-tier-live-counts-2026-11-19.json). [Closed-bank evidence](validation/lag-hotspots-provider-counterexamples-2026-11-14.json).

<!-- LHO-PROFESSION-SAVED-NEGATIVE-PREDICATE-20261120 -->
20 November. Forever with both inventory addons reported identical learned and removed sets across 471 native Tailoring IDs during the two observed callbacks. The alternate predicate consumed 102 full reads, the timing probe kept both production handlers, and no Lua errors appeared. Confirm actual recipe learning, delayed metadata and other clients separately. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-OBSERVED-REMOVALS-20261120 -->
20 November. Matching source in all five installed clients passed ten Lua 5.1 and 5.4 compiler checks. Eight focused scripts passed under Lua 5.4. Five also passed with the stock Lua 5.1 fixture shim and three failed at the same points on the checkpoint. Loaded Forever 1.60.1/70959/16001 with both inventory addons published the same 102 learned records and removal flags in both first and warm open checks. No new errors or inventory changes occurred. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-FIRST-TAILORING-PUBLICATIONS-20261120 -->
20 November. Forever 1.60.1/70959/16001 with FluxUI, BugTabs, Syndicator and Baganator exercised one first and two warm native Tailoring opens. The warm runs spent 11.85/7.62 ms and 12.38/8.50 ms in the same-frame source/list callbacks. The repeat compared all 102 learned records and removal flags under both saved keys. Bag generation and session error counts stayed stable. Observers restored and the test panel closed. No craft or transaction ran. Other clients and active crafting remain open. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-COUNT-NEUTRAL-MOVE-BUILTIN-20261120 -->
20 November. The exact closed-backpack move now passes on Forever with built-in inventory, Syndicator alone, and Syndicator with Baganator. Scope includes unchanged counts and selected grid IDs, real slot deltas, and restoration. The original addon combination was verified after reload. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-COUNT-NEUTRAL-MOVE-PROVIDERS-20261120 -->
20 November. A real count-neutral move and return on Forever passed with Syndicator and Baganator and with Syndicator alone. The same slot deltas arrived in both profiles. Final native and FluxUI counts were 18, all five checked button assignments matched, and the classifier remained settled. The built-in provider still needs the equivalent move. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-UTILITY-CONSUMABLE-RETRY-20261119 -->
19 November. The utility consumable classifier source matches at all five installed paths, with five compiler checks and 588 existing assertions passing. Loaded Forever confirmed zero six-second passive scans after reload, with five matching consumable records and Extra Button assignments and zero new Lua errors. Other native client and provider checks are pending. [Evidence](validation/consumable-non-restoring-items-2026-11-19.json).

<!-- LHO-NATIVE-BAG-REDRAW-OWNERS-20261119 -->
19 November. On Forever with Syndicator and Baganator, receiving 14 Food into existing stock advanced the FluxUI bag generation from 17 to 20 and kept final native and FluxUI counts at 28. Three real bag pulses reached the visible category layout. All probe functions were restored and no new Lua errors appeared. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-NATIVE-FOOD-RECEIPT-20261119 -->
19 November. On Forever with Syndicator and Baganator, a real Food cast and cancel sequence produced one completed cast and 14 food. Native and FluxUI counts matched. The bag generation rose from 15 to 17 and two delayed bag updates were seen. The observer restored the temporary wrappers and reported zero new Lua errors. This covers the existing open category view and one production receipt. Other providers, clients and a real profession craft remain open. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-REDRAW-FRAME-GAP-20261119 -->
19 November. R492 covered the settled Forever category backpack with FluxUI, BugTabs, Syndicator and Baganator. The native frame-gap median fell from 36.5 to 33.5 ms across four paired redraws. Every pair used the same snapshot and reduced two redraws to one. Error count stayed stable, the test function was restored, and the backpack stayed open. No timing claim extends to the first open or other client and provider combinations. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-SINGLE-CATEGORY-REFRESH-20261119 -->
19 November. Gear-set contents, the Equipment Set section and consumable preset categories now request one Baganator refresh through the public widget/search reasons. After reload, four Forever pairs reduced category update calls from two to one and median redraw time from 31.482 ms to 27.103 ms. Category order, item counts and view dimensions matched. No Lua errors occurred. Native build 1.60.1/70959/16001 used Baganator 862 and Syndicator. Other client/provider and bank-view replay remains pending. Forty syntax checks passed and all five installed copies matched. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-SHIELD-CONTEXT-20261119 -->
19 November. FluxUI's Baganator gear-set shields reuse the existing merchant and disenchant context during protection refresh. Four installed Forever pairs matched all 52 widget results. Context reads fell from 106 to two, and median refresh time fell from 0.882 ms to 0.791 ms. All five installed copies match. The native pair used Forever 1.60.1/70959/16001 with Baganator and Syndicator loaded, commerce closed and no active disenchant. The focused desktop tests cover merchant and standalone disenchant logic. Frame effect and native action protection across other profiles remain pending. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-PROFESSION-LEARNED-LIST-AUCTION-20261119 -->
19 November. Four native Forever Tailoring updates with Auction Restock open produced the same learned recipes, removal flags, visible and hidden rows, and potion targets as immediate full scans. Median combined time was 16.014 ms with the forced full scan and 12.798 ms with the installed settled path. Each half refreshed Restock once. All four inventory generations stayed stable and no Lua errors appeared. Native build 1.60.1/70959/16001, with FluxUI, BugTabs, Baganator and Syndicator. No inventory or pending changes occurred. The observer restored both owned methods. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-CONFIRMED-UNLEARNED-20261119 -->
19 November. Settled owned-profession scans can skip full metadata reads for recipes previously confirmed unlearned when the native recipe list, filters and live spellbook still agree. On live Forever Tailoring, median isolated read time dropped from 4.157 ms to 1.173 ms and full metadata calls from 471 to 101. After reload, four native events paired with immediate full scans matched all learned rows and removal flags. Median total scan time fell from 13.293 ms to 8.346 ms. The test used Forever 1.60.1/70959/16001 with commerce panels closed. Ten Lua syntax checks passed across the five identical installed copies. Live crafting, learning, FPS and other client-provider combinations are pending. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-NAMED-ALIAS-20261119 -->
19 November. The named profession save reuses the current scan's reconciled recipe references when the numeric and named aliases agree. Four paired saves on copies of the actual Forever Tailoring cache reduced the median from 1.225 ms to 0.890 ms. All 101 recipe records, alias order and removal flags matched. After reload, six native Tailoring events confirmed 101 matching records and separate saved arrays, with no new Lua errors. Ten syntax checks and eight regression scripts passed. All five installed sources match. Native checks used Forever with Syndicator and Baganator loaded, Tailoring idle and commerce closed. The test did not submit a craft or change items. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-AUCTION-TAILORING-WARM-LOADED-20261119 -->
19 November. Eight native Tailoring updates rebuilt Auction Restock once apiece. The installed bag-tooltip path reduced the median Restock rebuild from 5.114 ms to 4.291 ms. The full handler medians were 21.504 ms and 21.258 ms, with overlapping samples. All visible and hidden rows and potion targets matched, four inventory generations stayed stable, and no Lua errors appeared. Tailoring and Auction were closed and the original empty target restored. This native run covers Forever with both Syndicator and Baganator loaded, no craft, and no transactions. The pending-read test covers the two provider modes in its fixture. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-WARM-BAG-TOOLTIPS-20261119 -->
19 November. Warm Auction Restock now shares nonempty native carried-bag tooltip text during a single row assembly. Consumable eligibility, missing metadata, item moves and changed providers keep their current checks. After reload, the three paired Forever rebuilds fell from a median of 4.455 ms to 3.767 ms. Visible and hidden rows and potion targets matched, the bag generation stayed stable, and no new Lua errors were captured. The source matches five installs, with 20 syntax checks and 43 regression scripts passing. The separate consumable readiness assertion fails identically on the checkpoint and candidate. Forever used FluxUI, BugTabs, Baganator and Syndicator. Open commerce, other client/provider combinations, and whole-frame timing remain open. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-COLD-TIER-SLOTS-20261119 -->
19 November. Auction Restock shares complete occupied bag slots during one cold target-list build. Empty and incomplete slots still receive fresh reads. Recipe and tier matching retain their original order and cadence. In the installed Forever comparison, the median fell from 13.324 ms to 9.882 ms across three pairs. All seven rows and potion targets matched, the bag generation stayed stable, and no new Lua errors were captured. All five installed source copies match. Thirty syntax checks and 38 regression scripts passed. Whole-frame FPS and native checks on the other installs remain open. The live setup used FluxUI, BugTabs, Syndicator and Baganator with commerce panels closed. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-IDLE-MATERIAL-PLAN-20261119 -->
19 November. Auction Restock skips craft-material assembly when the owner has no craft plans. In Forever, 256 calls on six actual visible rows took a median of 0.653 ms before and 0.044 ms with the early return. The full rebuild kept all seven rows and potion targets identical. This removes three temporary tables and a row traversal in the idle case. The saving was about 2.4 microseconds per rebuild on this character. All 35 auction regression scripts and ten Lua syntax checks passed. The source matches all five installs and Forever loaded the source in R433. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROFESSION-IDENTICAL-RECORD-MERGE-20261119-LOADED -->
19 November. Reloaded the installed profession merge change in Forever. The loaded Tailoring observer processed five updates and restored itself with a stable bag generation and no new Lua errors. All four retained result lines show 101 matching references in both aliases and identical revocation data. Displayed callback timings ranged from 13.676 to 23.003 ms. These unpaired timings do not establish a whole-handler gain. Tailoring was closed and the jump helper resumed. [Profession evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-IDENTICAL-RECORD-MERGE-20261119 -->
19 November. Profession storage skips the field scan when the prior and incoming alias already point at the same plain recipe record. Distinct records and custom tables still use the existing merge. All 101 actual named and numeric Tailoring recipe references matched. Six isolated native timing passes over those saved rows reduced the median for 16 merge-check traversals from 2.035 to 0.477 ms. The individual saving is about 0.10 ms per traversal, and the whole callback remains unmeasured. Nine existing regressions passed, the file matches all five installs, and loaded verification is recorded above. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-AUCTION-SETTINGS-SAME-PASS-20261119-LOADED -->
19 November. The installed Auction Restock settings change was verified in Forever with Syndicator and Baganator. Three pairs against the original fallback halved tier-target reads from ten to five and reduced median callback time from 10.640 to 5.749 ms. All seven rows, potion targets and status text matched. No new Lua errors occurred. The jump helper resumed after the reload and both test panels and the original empty target were restored. Eight actual idle Tailoring events confirmed the separate passive hotspot. Preserving the existing rows during the callback reduced its median from 18.705 to 13.930 ms. The test ran the full rebuild immediately afterward outside the timer and confirmed exact parity. Mail expiration and late item data can change without a stock generation update, so this diagnostic bypass remains out of the addon. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-SETTINGS-SAME-PASS-20261119 -->
19 November. FluxUI now reuses the Auction Restock rows that a settings change just built when the initial planner still has the same stock, owners and clock. The existing guards retain fresh reads for other owners, receipts, pending or saved craft plans, unknown counts and changed inventory. Three paired comparisons of the real settings callback in warm Forever reduced two synchronous row builds to one and took a median of 10.177 ms versus 5.496 ms. All seven rows and potion targets matched. The test did not change a setting or transact. The initial cold probe hit an assertion because an ordinary native price lookup was still running. The measured pass waited for that lookup to complete and reported no new errors. The installed source matches five clients and all 35 existing auction scripts passed. Loaded verification is recorded in the following entry. [Evidence](validation/auction-final-sku-2026-11-19.json).

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
19 November. Auction Restock reuses confirmed ordinary units only within one row rebuild with the original charge and potion-replacement methods and stable bag, bank and warband generations. Changed item IDs, charged items, unresolved data and open or unsettled bank contexts retain fresh reads. On the loaded Forever client, three paired full rebuilds with commerce closed matched six visible rows and one hidden vendor row on every run. Median elapsed time fell from 4.785 to 4.480 ms. The bag generation stayed stable and no new Lua errors appeared. Thirty syntax checks passed and the sources match across five client installs. Real charged stock, open Auction and Pending, and the other provider/client configurations still need native validation. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-AUCTION-RECIPE-LOADED-20261119 -->
19 November. The installed Auction Restock refresh on Forever used the grouped catalogue branch with five eligible carried item IDs. The same three learned inputs reached recipe verification in the same order. A single timed pair took 2.417 ms for the five per-item queries and 1.650 ms for the loaded refresh. The bag generation and Lua error count remained stable. Auction and Pending were inactive. Native price scan, real Pending work and other clients still need timings. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BACKPACK-REAL-UPDATE-20261119 -->
19 November. A real count-neutral bag move on Forever with Syndicator and Baganator produced one delayed bag event, a 6.40 ms inclusive Baganator view refresh, and 0.16 ms in FluxUI button-face callbacks. The ExtraButton grids kept the same selected items. The bag generation advanced once and the consumable classifier did no full rescan. The one 42 ms frame gap is unattributed. The temporary test tried to schedule restoration while the moved stack was locked. A follow-up after an independently observed reload verified the 18-item stack back in its original slot, the temporary slot empty and the cursor clear. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-JUNK-CACHED-QUALITY-20261119 -->
19 November. The Junk fallback now reads an already resolved non-gray quality when the Baganator caller supplies only an item ID. Gray, missing, restricted and replacement quality paths use the original rules. Both changed Lua files pass syntax checks across five installs. Three paired native reads matched all 48 carried-item verdicts each time. Every sampled item had known non-gray quality. The isolated median was 0.148 ms for the original gray fallback and 0.013 ms when the probe used quality established before timing. One pair was slower. [Evidence](validation/junk-cached-quality-2026-11-19.json).

<!-- LHO-CLIENT-LOAD-AUDIT-20261119 -->
19 November. The scoped client load audit found all 181 direct manifest files and the same TOC in Retail, Forever, Classic, Classic Era and Anniversary. The audit pinned all five executable versions and compared 905 file entries. The 180 Lua files passed the Lua 5.1 and 5.4 checks after normalizing byte-order marks on ten temporary BuyEmAll localization copies. The BuyEmAll XML parsed. [Evidence](validation/inventory-client-load-audit-2026-11-19.json).


<!-- LHO-PROFESSION-ALIAS-OVERLAP-20261119 -->
19 November. Lua 5.1 and 5.4 syntax passed across all five installations. Forever verified alias overlap using real Tailoring data. Loaded production timing remains open. [Evidence](validation/profession-alias-overlap-2026-11-19.json).


<!-- LHO-PROFESSION-BAG-RESTOCK-20261119 -->
19 November. Five paired native helper checks matched all 505 current Tailoring recipe references. The median fell from 0.891 to 0.581 ms with the key table prepared before timing. The source matches across five installs and compiled on Lua 5.1 and 5.4. Full event timing needs the candidate loaded. [Evidence](validation/profession-bag-restock-2026-11-19.json).


<!-- LHO-CONSUMABLE-NON-RESTORING-20261119 -->
19 November. The extracted candidate guard recognized all three live inputs and left the restoring food control eligible. Lua 5.1 and 5.4 accepted the source across all five installations. The client still needs a suitable reload and a matched passive timing run. [Evidence](validation/consumable-non-restoring-items-2026-11-19.json).


<!-- LHO-RESTOCK-REAGENT-NAME-READS-20261119 -->
19 November. Forever 1.60.1/70959/16001 with FluxUI, BugTabs, Baganator and Syndicator confirmed the secure item-name getter and a visible Restock tab. The native worker comparisons matched 207 names in each of three pairs. The two exact source copies match on all five installations. The current session retains the prior loaded versions until an eligible reload. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

19 November. With Restock and Tailoring visible, three complete row builds took 5.926, 5.461 and 5.772 ms. All six visible rows and the hidden vendor row had identical fingerprints. A real count-neutral bag move triggered one delayed bag event and one touched-item pulse. The capture recorded two Restock row builds totaling 21.907 ms, two paints totaling 0.620 ms, one grid count flush at 0.155 ms and ten consumable scans totaling 28.042 ms. The nearby peak frame gap was 72 ms. The spans can overlap and the frame gap has no attribution. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-AUCTION-USE-FINAL-SKU-20261119 -->
19 November. Forever 1.60.1/70959/16001 reported FluxUI, BugTabs, Baganator and Syndicator. R266 restored the closed backpack with no new errors. R267 matched seven ordinary candidate auction rows. R268 confirmed the retained auction implementation at line 538. The exact restored file matches all five client installations. Active Pending, charged live rows and other clients still require native checks. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-BACKPACK-FINAL-CALLBACK-20261119 -->
19 November. Forever 1.60.1/70959/16001 with Syndicator and Baganator 862 loaded the button index on line 184. The earlier same-session candidate test returned the same 55 visible references, order and stable bag generation. Two post-adoption backpack opens restored closed state. Open bank, alternate client/provider combinations and full frame-spike improvement require separate verification. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-ITEM-REGISTRATION-INDEX-20261119 -->
19 November. Forever 1.60.1/70959/16001 with Baganator 862 and Syndicator confirmed the bank index in the running addon. The closed-commerce comparison returned the same nine rows and both view refs. The item-button index was compared before editing Lua and matched all 550 references while bags were closed. Exact source copies match across all five installations. Open-bag behavior, active commerce and other native client/provider configurations need separate runs. [Evidence](validation/baganator-item-registration-index-2026-11-19.json).

<!-- COMBAT-CF64-20261117 -->
17 November: native main-only Forever1.60.1/70938 CF64 finished with31 gaps/
3 slow callbacks and16 delivered/sampled entries plus16 exits. Worst next
eligible driver gaps25/17ms are not handler CPU or absence of deferred lag.
The105.5655ms border callback overlaps its105.6152ms enclosing flush; the815ms
general gap remains UNATTRIBUTED. Only20of31 ring rows survive.

DiagnosticVersion3/R60 family is observed; exact loaded Core hash is UNKNOWN,
so newer border work has no native acceptance from CF64. Profiler settings were
not written; start/end errors0, Bank0. CF64 deep retention passes; original
`CF62hold.old`7-gap/2-callback report remains retained, restoration pending the
owned background guard. No own capture lease. Controller/client compatibility,
taint, pixels, FPS and combat/group hitch acceptance remain open.
[Sanitized native evidence](validation/combat-cf64-2026-11-17.json).
<!-- /COMBAT-CF64-20261117 -->

<!-- FALLBACK-INPUT-WORK-R63-20261117 -->
17 November R63 is REJECTED/REMOVED after BOTH declared desktop CPU gates
failed. Exact Core4fa7c12a/LF110827 and array testad065 were restored at07:17:21UTC;
OtherE790 is unchanged. No R63 native test or adoption is claimed. The42,524checks
perVM and514/1204mixed-snapshot trial pass retain their historical scope.

Root reported the later main-only background reload completed after restoration;
pre-command disk equality is not loaded-byte proof. CF64 was reported armed
at07:34:09UTC; retention, event-delivery and combat/group results remain pending.
Bank is excluded; native CPU/FPS, secure/taint and visual acceptance remain open.
[Rejected sources and validation](validation/fallback-input-work-r63-2026-11-17.json).
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


<!-- RESPEC-ACTION-SAFETY-20261116 -->
16 November (`RESPEC-ACTION-SAFETY-20261116`): explicit native bar slots now save/load on Retail, Forever and Classic after talents. Failed reads, pickup/no-cursor, malformed snapshots, active loads and player drags cannot become destructive empty restores. Stable flyout/macro/mount/set/outfit routes and legacy missing-stance preservation are covered. Auto-rank now verifies the exact spell cursor and destination before advancing saved IDs; binder opening preserves the native account/character set and unsaved keys. Frozen 14 scripts on each Lua5.1/5.4 PASS (28 runs); 18 owned syntax results and 611 compiler prototypes/max25 captures PASS. Native operation/taint/controller/persistence/FPS remain pending. Reload then re-save old Retail/Forever profiles to capture bars; previous snapshots contain stance only. [Requirements, exact sources, checkpoint, regressions and pending checks](validation/respec-action-safety-2026-11-16.json).
<!-- /RESPEC-ACTION-SAFETY-20261116 -->


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
The user explicitly deferred all in-game testing until they say it is available again. Continue source changes and offline tests only. Previous reload/watch/capture requests are on hold; do not initiate client input, game Lua probes or profiling, and do not infer renewed permission from elapsed time. Native acceptance remains deferred; the already supplied R54 sample is historical evidence.
<!-- /USER-NATIVE-TEST-HOLD-20261116 -->

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

16 November `COMBAT-TRANSITIONS-20261116`: R51 `prepared-guards-r51` preserves
the existing Retail/Forever/Classic adapter and pinned-source contracts. The
101/36/8 source-consumer audit includes raw frames and indirect state/visibility
paths; it does not prove every callback is registered in the current session.
Aura-group work has1702 checks/14 focused scripts PASS; fresh-state minimap
guards have166 checks/18 focused scripts PASS; consumable525/20 focused and31944
border guard checks PASS. Combined R51 aggregate474 PASS/0FAIL and1165 syntax PASS
follows an initial473/474 sweep, one extractor correction and four bounded replays.
All eight owned runtime files stayed stable; unrelated World Map/fixture changes
mean this is not one globally frozen sweep. Global690 runtime files/24916
prototypes max57/0fail PASS. Native R51 entry/exit, friendly dispel/combat paint,
input, taint and rendering checks remain pending on all native clients.
Quiet Forever R50 measured218.36ms reflow versus
R49's207.94ms; both remain unresolved hitch evidence, not FPS acceptance.
[Requirements](COMBAT_TRANSITION_PERFORMANCE.md) and
[evidence](validation/combat-transitions-2026-11-16.json).

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

15 November corrected border types and thickness (`FLUX-BORDER-TYPES-20261115`):
the earlier stretched artwork was rejected. Type 2 now uses exact gold c60-2x
pixels extracted read-only from installed Forever 1.60.1.70938, on every client.
Native padding/title band are removed. The same eight canvas cells, consumer
sizes, anchors and padding are retained, with matched cap/edge alpha/color joins.
Appearance adds Border thickness: 50%-200% in 25% steps, default 100% aligned
to the original type-1 stroke and outward pixel padding. Both types, status
row/column splits, HP/resource splits, class/spec icon edges and target/focus
aura panels participate. Natural gold and neutral accent masks share alpha;
type 1 at 100% restores original atlas/UV and its Forever bronze exception.
Full 397 scripts / 1,085 syntax PASS, including 652 direct-piece checks; 170 raster
checks cover all 20 canvases, thickness values, seams and outward padding.
Installed Forever runtime/art files match read-only. No manual sync, reload,
input/focus, WTF/profiler writes or new driver. Native source adoption, pixels at
actual UI scales, taint, controller and performance remain NOT RUN.
[Corrected source, extraction provenance, checkpoints and limits](validation/border-types-2026-11-15.json).


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


15 November 01:56 CET R6 follow-up (`LHO-CAST-NATIVE-R6-20261115`):
current Forever raw Cast callback attribution and highest-Food6129 cancel/completion
observations PASS. One30.003s window recorded17 valid callbacks,24.890500ms total
and6.407100ms max; three INTERRUPTED callbacks account for17.5991ms. Aggregate
bag quantity164->174 is a snapshot delta, with no item-ID attribution. R5 used a
different observer/UI and one cancel; its10.0534ms maximum cannot establish a
native gain against R6. Matched desktop improvement remains separate.
Exact handler/owner restoration, C5nil and unchanged0/true/120/30 preferences
confirmed; no_jump released and the external jump helper remains active. Current
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
helper paragraph; external helper still runs under its existing stop/lock rules.
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

14 November `LHO-FRESH-IDS-20261114`: full lag goal ACTIVE; current387scripts/
1075syntax PASS. Only Index/SpellReagents and one durable regression changed.
Five-family desktop/provider shapes and independent legacy-override/history
reviews pass. Forever1.60.1/build70938/interface16001 reloaded under an idle guard;
new API readiness plus three same-VM query pairs and51-key equality PASS. Query
allocation22464->10800bytes; CPU0.0608->0.0577ms medians in brief uncontrolled
samples, no FPS claim. Profilertrue/scriptProfile0/caps120/30 unchanged; source
Syndicator. No persistent test helper, item/mail/queue actions or external edits.
Native whole workflows/provider-off/other clients/actual cast edges/taint/pixels/
controller and bank/mail populated timing remain pending. Exact disk hashes do
not certify loaded bytecode. Newer tooltip/EBS/unitframe work is preserved.
[Current sources, raw samples and acceptance limits](validation/passive-inventory-item-ids-2026-11-14.json).

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
After /reload, exercise both trinket slots: ready/on-use/passive/empty; actual
use/shared/swap cooldown and completion; usability changes while held; mouse,
wheel and key release; hiding/reopening; same-item re-equip; flyout/queued swaps
and combat/controller input. No connected client execution tool; user reproduces
in the background. Native builds/operation/rendering/persistence/taint/performance
remain NOT RUN. See [task acceptance](TRINKET_EQUIPPED_USABILITY.md#13-november-follow-up-intermittent-dark-faces-and-cooldown-overlays).

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

NAMEPLATE-QUEST-LAYOUT-20261109 (9 November): desktop geometry/data checks pass
for Retail/Forever/Classic progression and retained Era/Anniversary models. Native
one-row kill/loot plus simultaneous casts/threat/level, minimum legibility at
small plate widths, complete/abandon/reuse and combat/taint remain NOT RUN. User
chose local checks and their own in-game testing for this feature; retain that
choice. No foreground/input, settings or profiler operation. See
[requirements and native steps](19-nameplates.md#combined-objectives-and-dynamic-width--9-november-follow-up).

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

9 November native bag item targeting (BAG-ITEM-TARGETING-20261109): user
Forever crate-like item/native bags fault unresolved; actual source use/cursor/
destination/cancel, native taint and protections remain pending. Pinned70862
source matches right-click line1611; it does not locate first taint. Opt-in bag
metadata574checks and five related suites PASS; no engine/taint VM emulation
claim. Host executable/window verified read-only, no game input. User reproduction
and verbose trace needed; prior settings/logging/profiling retained. User lacks
the original items. Latest13:00 log contains no matching bag/action trace and
no saved bag capture exists; equivalent future reproduction remains open.
Full270-script/937-syntax validation PASS; complete Lua corpus unchanged.
[Exact reproduction and limitations](BAG_ITEM_TARGETING.md).

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

9 November compact quest badge:371 focused geometry/data/lifecycle checks PASS;
existing combo and56cast-school checks PASS. Smaller10-unit icon/font,12-unit
host and tight16-unit icon/padding allowance preserve centreY-3. Native overlap,
icon fit/legibility and all-client pixels remain for the user's in-game test.
[Compact record](validation/nameplate-quest-compact-2026-11-09.json).


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

9 November nameplate quest progress: five desktop contract models,311 checks and
seven rejected harmful controls PASS; baseline has no feature. Current source pins:
Retail70783, Forever70862, progression70631; existing Era/Anniversary paths
retained. Native quest/drop association, pixels with level/threat/casts, combat,
taint, profile/reload and world/instance transitions NOT RUN. User will test in-game;
no Witchcraft/UIForever tool connected, no client input or source synchronization.
[Acceptance](19-nameplates.md#quest-kill-and-loot-progress--9-november-2026).


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

9 November focus visibility/menu validation: Forever native1.60.1/70862/16001,
verified exact executable/window, guarded background reload and readbacks.
Empty focus/focus-target roots and their mouse children are really hidden;
ordinary player/target/focus/pet actions are `togglemenu`. Native focus-player
then clear restores empty focus and BugTabs remains0; foreground unchanged.
User confirms player Set Focus and combat focus/clear macros work without errors;
target menu passed earlier. Group/pet menus and physical combat click-through
remain pending. Five pinned desktop contracts pass70 visibility/670 native-menu
checks; full263/930 PASS.20 primary bodies verified and15 runtime copies match.
Retail70783, progression70631, Era70576 and Anniversary70577 native acceptance
is pending; original Wrath unavailable. Existing focus capability gates retained.
No CPU/FPS/taint/pixel certification from models. Mini-frame callback menus remain
with native focus macros by explicit user choice.
[Build matrix and steps](FOCUS_SECURE_VISIBILITY.md).

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

8 November Edit Mode ownership (EDIT-MODE-NATIVE-20261108): five models/
native method replays pass295 checks; full259/924 PASS, no source drift;20 installed
copies match.22 primary blobs/60 exact used native method bodies verified.
User Forever save/viewer report passes without new errors; nine secure metadata
fields reported. On-disk edit snapshots absent: loaded GetBuildInfo/profile/addon
list and comprehensive security acceptance uninstrumented. Other native clients,
sustained combat, pixels and performance pending.
[Scope and steps](EDIT_MODE_NATIVE.md).

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

8 November universal mouseover (UNIVERSAL-MOUSEOVER-20261108): all five
installed executable versions/pinned references and15 runtime copies are recorded
in [client copy evidence](validation/universal-mouseover-client-copy-2026-11-08.json).
Five adapter models pass916 assertions; existing native setting/checkbox resolver
and complete258/923 suite pass. These models do not execute a protected client
click or real cast. Verified Forever process/window was foreground; read-only
capture only, no input/reload/settings or profiler changes. Loaded build/profile/
addon list, actual casts, combat, badges, pixels, gamepad and taint remain pending
for every client. Follow [native regression steps](UNIVERSAL_MOUSEOVER.md);
original Wrath is not installed/tested here.

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
Documentation check is blocked by eight stale inventory/verification entries
from concurrent unit-frame/public-geometry source changes; no utility error was
reported. Preserve that work and refresh its global records when stable.
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

7 November class travel/reagent presets: five travel capability models and
modern/legacy actual scanner/list/facade cases pass 130 + 47 checks; 16 faulty
mutations rejected. Native flyout children, C_Flyout-only APIs, active overrides,
unlearned children and deduplication are covered in desktop fixtures.
Scoped replay passes all six required scripts with unchanged reagent sources.
The last whole-addon run passed 200 of 204 scripts and all 866 syntax files;
four raid-test failures and unrelated source drift prevent a whole-tree PASS.
All four runtime files match the four existing client copies (16 hashes). A
manual-copy verification stopped during active continuous sync; three later
read passes confirmed every candidate, with external destination backups.
Forever process/window was verified; baseline transport completed but no FX
marker appeared with auction/crafting panels open. Native result is inconclusive;
candidate editor/click/pixel/vendor checks remain pending on every client.
No foreground input, test purchases or profiler changes.
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

7 November follow-up: five capability models cover readable legacy cooldown
rules and modern restricted metadata; action/badge row-swap, proc and secure
snippet regressions pass.150 new checks/10 mutants; final199scripts/861syntax.
Five files copied to four existing client copies,20 hashes match. Actual Forever
background probes of the preceding identity candidate: functions loaded,
profile0, three BugTabs samples0, TacoTipfalse/Syndicatortrue/Baganatortrue.
New batch: user reload plus observed ordinary combat; cleanup marker nil and
BugTabs0 afterward. Restricted badge transitions; swaps; matched pixels; native
performance and other-client acceptance remain pending. [Case](UNIT_STATE_SECRETS.md#follow-up-badges-and-unused-power-snapshots),
[native record](validation/unit-state-native-followup-2026-11-06.json).

6 November restricted identity candidate: actual-module fixtures cover Retail,
Forever, Era, Anniversary and Classic API shapes;344 focused checks/23 mutants,
final197 scripts/859 syntax pass. Five files copied to the four existing client
copies,20 checksums match. Forever1.60.1/build70790/interface16001 host/window
reverified; only read-only capture succeeded. Native reload refused before input
because WoW was foreground. Native combat/secret VM/taint/pixels/performance are
pending on every client; desktop counts certify none of those. User reports
TacoTip unloaded. [Case](UNIT_STATE_SECRETS.md), [native record](validation/unit-state-secret-native-2026-11-06.json).

6 November TacoTip backdrop error: user stack shows secret-width arithmetic
under TacoTip; report client/frame not identified. Installed Forever0.9.4 has a
source-matched owned backdrop path, reproduced with modeled secret geometry.
Era/Anniversary0.5.1 differ; Retail/Classic copies absent. No runtime change or
native acceptance; the user chose read-only, with no edits planned.
[Audit](TACOTIP_BACKDROP.md).

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

6 November Forever70790 user native confirmation after candidate reload and
Map activation: `FXMAP true true 0`; both queried native method fields secure,
current-session BugTabs errors0. Agent-observed Map rendering is separate from
this user-reported probe. Other fields/clients, matched pixels, right-click and
combat recovery are not certified. [After](validation/map-provider-native-after-2026-11-06.json).

6 November map provider candidate: native Forever70790 baseline normal Map
activation tainted shared native methods and BF AcquirePin.31 detach/36 combat
model checks preserve all11 available layers and legacy capability cadence;
193/855 complete desktop PASS with frozen hashes. Candidate file installed in
existing Retail/Forever/Era/Anniversary/Classic copies, previous files preserved
externally. Forever reload observed, post-activation provenance/input/combat and
other-client native acceptance pending. [Case](MAP_PROVIDER_LIFECYCLE.md).

6 November Forever badge follow-up: native user report confirms modern proc
glow follows main↔mini combat paging. Bar→badge loses glow, and an action-bar
badge loses its icon/display on main↔mini combat swap. The new candidate
prepares reverse badge slots, allows the Retail border to extend beyond the
corner, and paints dormant badge spell/item fields in combat without secure
attribute writes. Desktop baseline rejects the icon regression; candidate
passes 190 scripts / 852 syntax files. After `/reload`, the user confirmed
bar↔badge glow in both directions, proc-end clearing, and badge icon/count/
cooldown during main↔mini combat swaps. Taint, pixels, frame time, other
procs and clients remain unverified.
[Evidence](FOREVER_SAO_GLOW.md#badge-handoff-and-combat-row-icon-follow-up-current).

Native follow-up16:29UTC: ExtraButtons, CombatGrid and NonCombatGrid enabled;
current-session BugTabs errors0; profiler0. Watchv2 confirmed running600s /
200ms in Forever; completion/save and analysis pending.
[Startup](validation/ebs-glow-startup-native-2026-11-06.json),
[arming](validation/forever-random-spikes-v2-armed-2026-11-06.json).

6 November Forever random-spike capture: actual1.60.1 build70790 watch600s,
scriptProfile0, retained7 gaps /0 central spans>=10ms. Two nearest Flux ticks
were214/181ms; longest gaps had little addon billing. The user's120-second
profile1 capture provides function rankings only, not causal or matched FPS
acceptance. Original profile0 restored and read live. Desktop layout/observer/
watch/aura fixtures cover their stated scope only. Watchv2 and new grid/glow
startup regression native checks are pending; other clients need separate runs.
[Evidence](RANDOM_SPIKES.md).

6 November Forever SAO paging follow-up: user confirmed in-combat Missile
Barrage proc art on Arcane Missiles after the first secure AuraContainer change.
The same user test found main/mini modifier and badge/action-bar handoff
incorrect. The follow-up prewarms possible faces OOC and gates art by displayed
face in the existing refresh path. Paging model rejects baseline and passes 9
candidate checks; full desktop validation passes 187 scripts / 849 Lua syntax
files. Native handoff, proc-end, taint, pixels and frame time remain pending;
Era/Anniversary/Retail paths were not changed by this Forever-only branch.
[Evidence](FOREVER_SAO_GLOW.md#mainmini-and-badge-handoff-follow-up-newest).

6 November Forever SAO secure proc glow candidate: Gethe Retail/Forever
action buttons use the same alert template; Forever's secret aura visibility
and animation registration are owned by Blizzard AuraContainer. The new
filtered 400589 slot uses that secure path on resolved Arcane Missiles
surfaces. Desktop checks pass 186 scripts / 848 Lua syntax files, including
69 focused glow checks. Forever native combat appearance, clearing, paging,
taint, pixels and frame time remain pending; other clients retain their
existing paths and need regression checks.
[Evidence](FOREVER_SAO_GLOW.md#secure-auracontainer-button-animation-candidate-latest).

6 November consumable follow-up: five matched loaded-module baseline/candidate
runs pass 46/66 checks for Well Fed, flask aura, weapon enchant, event route,
actual item action and secure item attribute. Refresh-timer and weapon-target
fixtures pass 35/30; full desktop runner passes 185 scripts and 847 Lua files.
The native client/window could not be verified from this
sandbox, so Retail, Forever, Era, Anniversary and progression latency, secure
input, taint and visuals remain pending. Settings and profiler preferences were
left untouched. [Evidence](CONSUMABLE_REFRESH_TIMER.md#aura-and-weapon-enchant-follow-up--6-november-2026).

6 November consumable aura advance: modern/legacy loaded-module pairs confirm
immediate next-item selection after Well Fed aura gain (22 candidate checks
each, five repeated pairs). Ordinary `UNIT_AURA` registration is retained as
the legacy fallback; combat changes queue until exit. Native Retail, Forever,
Era, Anniversary and progression acceptance remains pending.
[Evidence](CONSUMABLE_REFRESH_TIMER.md#immediate-advance-after-aura-gain--6-november-2026).

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

6 November Well Fed refresh candidate: a loaded-module fixture covers alternate
food aura discovery, learned spell ID reuse, and the 25 minute countdown at a
5 minute refresh threshold (35 checks). Weapon target regression passes 30.
Native Retail, Forever, Era, Anniversary and progression checks remain pending;
see [case record](CONSUMABLE_REFRESH_TIMER.md#well-fed-follow-up--6-november-2026).

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

6 November user decision: preserve every native feature and leave automatic Current blocked. User-supplied runtime inventory matches the eight documented meter functions and lists the enable/reset-on-new-instance CVars. The first inventory macro failed on missing help text; the corrected nil-safe macro completed. These metadata reads do not establish native combat safety or cleared taint. No runtime files changed. [Evidence](validation/meter-automatic-current-capability-2026-11-06.json).

6 November automatic Current requirement: manual session selection is not an accepted solution. The renewed pinned-source audit found no supported selection/default API on Forever 70790 or Retail 70783. The private setter remains rejected, and a replacement renderer has unresolved combat drilldown parity. No runtime files changed. Captures verified Forever; after the user confirmed background readiness, the Windows background guard still refused reload before any input. Reload cleanup, two-fight behavior and automatic defaults have no new native acceptance. [Capability evidence](validation/meter-automatic-current-capability-2026-11-06.json).

6 November actual Forever70790 native result: FAIL. Current selection became
pane/owner/saved1/1/1, with changed-field metadata true to false and _FluxUI
provenance; BugTabs2/2 plus delayed11:20 ordinary specIconID:535/durationSeconds:929
errors reject the experiment. Operative call removed; both test commands now
read-only UNSUPPORTED. Safe disk backend matches all five clients, but reload
cleanup and fresh loaded-source/ordinary combat/native secret checks remain
pending.126 no-operation/provenance and561 ownership/Core focused checks pass;
safe full166/823 passes unchanged sources ([manifest](validation/meter-rejected-current-removal-2026-11-06.json)).
Capture-only10:36:31Z confirmed the live native window/Meter; subsequent reload
was refused before input. No cleaned-memory/native acceptance is claimed.
Prior166/823 experimental source remains historical/rejected evidence. Automatic Current OPEN/unsupported; native UI session selector→Current
is distinct from Advanced AutoReset. No history/settings reset.
[Native failure](validation/meter-current-live-checks-2026-11-06.json), [scope](METER_STANDALONE.md#threat-timer-and-current-view-diagnosis).

6 November current native meter status: the explicit pasted DamageDone:Overall /
HealingDone:Overall overrides the earlier ambiguous Current reply. Automatic
Current for every existing/future meter is OPEN; two-fight/reload behavior remains
unverified. The optional guarded Forever70790 `/fbm currenttest` native output
is required/pending; desktop127-probe/561-ownership checks do not prove client
call permission or secret safety. Header172/threat87 and full166/823 pass stated
desktop scopes with unchanged sources. Native header/Minimize/timer geometry,
combat/taint/pixels/FPS and other clients remain pending. Passive captures did
not show the requested output or two fights. Preserve latest settings/history,
BugTabs, background-only rules and concurrent glow. [Scope](METER_STANDALONE.md#threat-timer-and-current-view-diagnosis),
[full manifest](validation/meter-current-selection-probe-2026-11-06.json).

6 November Forever proc candidate: user confirmed the prewarmed Classic LBG
frame still only glowed after combat. The revised Retail ProcGlow frame and
same-callback SAO/native button paint pass desktop checks only. A fresh
`/reload` and live Missile Barrage show/clear retest is pending. Era and
Anniversary native regression, atlas/pixel match, taint and frame time remain
pending; no desktop result is treated as in-client acceptance. See
[Forever SAO glow](FOREVER_SAO_GLOW.md).

Native readout from the direct-callback candidate: SAO screen hooks 0/0,
prepared Retail frames 158, show calls 0. The global-frame aura sampling and
alpha-only reveal candidate has not yet been tested in client.

Subsequent native retest also failed for the global-frame/alpha candidate:
combat readout had aura events 7, frame reads 334, Retail frames 158, shows 0.
The next requested read-only client check is SAO's active overlay IDs and
Flux's spell/button match during the visible proc.

That check returned `want5143=0` with no SAO overlay-list keys. The native
screen show/hide event candidate is installed on disk but has not yet received
an in-client acceptance test. If it fails, record `native` event counts and
ID from the readout during the proc.

Native-event retest and private-table AuraContainer hook both failed:
native show0/hide15, then AuraButton hooks0. The global Blizzard slot-registry
candidate is installed and requires a fresh in-client combat show/clear test.

6 November Forever combat button glow candidate: the user confirmed SAO's
Missile Barrage screen overlay appears in combat, while action bar button glow
does not. The user's first reload/retest still had no combat button glow,
with glow appearing after combat while the proc remained. SAO cached its
screen functions on a private table; the global-name hook missed those calls.
The corrected candidate hooks the table methods and subscribes standalone
Extra Buttons to glow changes on the existing eval lane. Flux accepts unknown
icon texture for a known spell ID. The
Classic Era SAO LibButtonGlow artwork and animation declarations match the
Forever paint route. The user retested the private-table candidate and still
saw glow only after combat, with stale glow after proc end. The newest
candidate adds global low-level SAO show/termination hooks and checks live
overlay/fade state. The user retested that signal candidate and still saw no
combat glow. Flux now prepares and retains each Classic LBG frame on its secure
button OOC, then plays existing animations without first-combat parenting.
Focused glow 53, low-level signal 5 and EBS refresh 8-check
desktop fixtures
pass; the full
[combat manifest](validation/forever-sao-combat-glow-2026-11-06.json) passes
164 scripts and 821 Lua syntax files. Elevated read-only host inspection found Forever PID
37088 and the exact WoW window; Codex sent no input or reload. The user's
first three live tests rejected the earlier candidates; the prepared-renderer disk code
still needs native combat verification. Pixels, taint,
frame time and Era/Anniversary regression remain pending.

6 November current Forever70790 evidence: host inspection confirms the same
PID37088/window remained live; sandbox-empty enumeration did not prove an exit.
At08:05:58UTC read-only native checks found Damage+Healing Overall0, Details false,
Meter active and BugTabs0. New-instance-reset1 does not select per-fight Current1.
Three initial native UI attempts were refused before dispatch; one final attempt
posted three targeted messages without activation/system input, but used stale
coordinates after a stock-layout change. Later loading capture did not confirm
Current or any setting change. The user later confirmed both native meters
now use Current. Setup is user-confirmed; agent enum/two-fight/reload checks
remain pending. The08:26 view showed centered Threat title/clipped timer;
revise the timer immediately after unchanged titles before final acceptance.
Earlier full162/819/unchanged sources is pre-heading stage evidence.
Native combat/secret/taint/pixels/FPS and other clients remain pending.
[Current scope](METER_STANDALONE.md#threat-timer-and-current-view-diagnosis), [native evidence](validation/meter-current-live-checks-2026-11-06.json).

6 November Forever SAO follow-up: user testing confirmed no button glow after
the earlier renderer correction. Installed SAO 2.8.9 Forever Missile Barrage
defines aura 400589's screen overlay but omits an Arcane Missiles button; Flux
now reads that aura for the base spell and its ranks, while generic SAO and
native glow paths cover other supported spells/procs. Secret native values and
event IDs are guarded. Focused 41 checks and the follow-up 162-script/819-file
desktop suite pass; native proc/visual/taint/frame-time and Era/Anniversary
regression checks are pending. [Source and scope](FOREVER_SAO_GLOW.md).

6 November current Forever 70790 candidate is not natively accepted. Reported
specIconID/durationSeconds failures under Flux taint require removal of direct
native Lua configuration writers, not just a texture correction. The candidate
removes those writers; native controls
must select missing pane types/row options and Current/Overall/history; their
state is not silently overwritten or reset. One native timer is implemented by
physical screen geometry without reading durations. Writer 26/timer 113 focused
checks pass (five pairs each, 5/9 mutants); final full validation passes
162 scripts /819 Lua syntax files with all source hashes/membership unchanged.
[Current manifest](validation/meter-timer-native-boundary-2026-11-06.json).
These models do not certify the native secure VM.
The 07:31 UTC sandbox-empty process result did not prove an exit; the same
Forever process/window was later verified live. Older captures/passes are
stage-specific. Other-client native behavior remains unverified.
[Current capability limits](METER_STANDALONE.md#current-native-configuration-boundary).

6 November Forever SAO glow candidate: installed SpellActivationOverlay 2.8.9,
interface 16001, saved glow enabled. Source route and focused 25-check fixture
pass for bar, Extra Button and badge faces; pre-edit source fails. Native
proc/paging/clear/pixel/taint and frame-time acceptance is pending on Forever.
Era and Anniversary routes are unchanged in source, with native regression
checks pending. Its earlier SAO-stage run passed 160/162 scripts; the current
combined validation passes all 162 scripts /819 syntax files after meter fixes.
[Evidence](FOREVER_SAO_GLOW.md).

6 November raid input: the user supplied a native secret-boolean failure at
`Hide.lua:139` during `FluxRaidLayout` native-grid hiding. Desktop mouse and
startup fixtures pass across five modeled client branches; this does not prove
native secret handling or protected setter legality. Normal reload plus party,
raid, Edit Mode, combat roster, input hit testing and enable/disable restoration
are pending on Forever and Retail; the other installed clients remain pending.
Preserve existing BugTabs roots and scriptProfile preference. [Raid record](49-native-mouse-suppression.md#raid-secret-mouse-follow-up).

6 November current Forever installation includes Details #Details.20261104.15400.172
(interface 16001); presence is separate from addon load state. The exact atlas/
fill/font mapping is read-only evidence, not proof of file loading in the game.
The new native backend references these installed files without loading Details
or SharedMedia; absent assets use the existing fallback per client. Final
candidate native inspection is pending. Fresh-process preflight captured only
the previous flat presentation; it cannot accept this candidate.
[Current scope](METER_STANDALONE.md#installed-wow-interface-art-references).
Other-client native, combat/taint and whole-UI pixel claims remain unverified.

5 November shared theme: source fixes one-line text and panel/header consistency
without reading native text or replacing rendering. Skin 54/threat 69 checks,
five style pairs/eight mutants and native-owner 463 checks/five pairs/five mutants
pass. Final desktop validation passes 159 scripts / 816 Lua syntax files; all 816
source hashes and membership are unchanged across the run. [Final manifest](validation/meter-theme-consistency-2026-11-05.json).
Forever 70790/interface16001 post-style reload 22:06:45Z retains Meter/builtin 7,
Details absent, scriptProfile 0/current BugTabs 0. Friz 15 title, ArialN 17.5 row and
name/value CanWordWrap=false are observed; shared header/panel fill inspected.
Final OOC native tab handoff passes; actual owned-threat combat rows were not captured, so combat secret/taint and performance remain inconclusive. Other clients retain prior route/validation limits.
[Exact stage scope](METER_STANDALONE.md#one-line-names-and-shared-meter-appearance).

Final Forever OOC handoff passes: Map/Respec/Buttons both views hidden, returning
Meter both visible; currentBugTabs0, Details absent, builtin7/profile0 retained.
[Exact background captures](validation/native-meter-background-checks-2026-11-05.json). Native name/value wrap flags are false and
shared header/panel fills inspected. No actual owned-threat combat row was
captured; do not certify that case, combat secrets/taint, native FPS or other clients.

Earlier font/tab-stage evidence (its native pending notes are superseded by final OOC handoff above):

5 November threat readiness: strict font-before-text replay reproduces the
native first-title error; candidate 65 checks, five original pairs, five
font-ready lifecycle pairs and nine mutants pass. Native Forever 1.60.1/70790/
interface16001, Details absent and scriptProfile 0 are current observations.
Map reload/session FXERR0 and layout 8 construction are partial checks only;
native combat, opaque values, taint, screenshots and frame times remain pending.
Full desktop validation passes 159 scripts / 816 Lua syntax files; all 816
source hashes and membership are unchanged across the run.
[Full source manifest](validation/meter-threat-readiness-2026-11-05.json). Native acceptance for that earlier font/tab source was pending; final OOC handoff is recorded in the shared-theme stage above.
[Exact scope and native follow-up](METER_STANDALONE.md#font-readiness-and-quiet-threat-follow-up).
Other clients retain prior routes; no new native certification follows.
The native font-candidate title/body is ready with ARIALN 15 OUTLINE, but normal
Map/Respec/Buttons switches exposed an owned-threat overlay while native panes
were hidden. The owner fix passes 429 checks/five pairs/four mutants versus 19
baseline failures. That stage preceded final OOC handoff, which now passes;
actual owned-threat combat and secret/taint acceptance stay inconclusive.

5 November standalone meter: Forever 1.60.1.70790 gains a Flux/Blizzard-asset
native skin and an independent optional threat pane when Details is absent.
Retail 12.1.5.70783 uses the native skin/enable path; standalone threat remains
Forever-only. Era, Anniversary and progression retain Details/capability absence;
generated API presence does not make their pinned native meter TOCs load.
[Full requirements and native checklist](METER_STANDALONE.md).

Skin 47 checks/five pairs/six mutants and threat 51 plus sample 510 checks/five
pairs/11 mutants pass. Opaque values are display payloads without false ranks;
80 player/pet facts, scrolling and hidden/Details cleanup are covered by mocks.
Final desktop validation passes 159 scripts / 816 Lua syntax files; all 816
normalized source hashes and file membership match before/after the run.
[Final source manifest](validation/meter-standalone-2026-11-05.json).

The user-reported checkbox diagnosis supports automatic out-of-combat enable of
the public damageMeterEnabled option; native visibility/cache and UI loading
remain native. Current candidate operation is not observed in game. Reload and
verify exact client/build/settings, disabled-startup and combat-deferred enable,
all old/new/custom layouts, source windows, timers, scrolling, group/pet churn,
native secret/taint, Edit Mode/gamepad and Details takeover. Match screenshots
against the approved reference. No native input, profiling or pixel comparison
ran; original Wrath and unavailable clients remain separate. A background-only
21:56:22 CET capture showed the same Forever process with Map active, not native
Meter docking. No loaded-code/build query or reload ran; this is partial visual
context only, not native meter/docking/combat acceptance. Separately, the user's
22:04 CET screenshot establishes floating native Damage/Healing on Map after
reload before first Meter selection. Startup ownership and late-anchor repair
need candidate native checks; that screenshot is not loaded-source proof.

5 November wand school swing candidate: Era 1.15.9.70576, Anniversary
2.5.6.70577 and Forever 1.60.1.70790 use pinned Gethe source and a shared
cast-school renderer on equipped wands. The focused production-module fixture
passes 13,942 checks; full desktop validation passes. No native reload,
gameplay, pixel comparison, taint check or frame-time capture was run.
Test Fire/Frost and unknown-school wands, weapon swaps, Shoot timing, option
toggle, cast interruption/slot ownership and localization sequentially in the
background. [Exact scope and source links](SWING_WAND_CAST_THEME.md).

5 November damage meter combat follow-up: the user-supplied duration warning
matches Forever1.60.1.70790 line929; Retail12.1.5.70783 has the same native
comparison at line930. Flux no longer writes the native Edit Mode visibility
field. It honors the native policy while retaining the host/tab visibility
boundary; timer and entry methods remain native.
[Pinned source contracts, policy and native checklist](METER_COMBAT_VISIBILITY.md).

Focused native-function replay passes 332 checks versus 80 baseline failures / 332.
Five alternating pairs per pinned Retail/Forever source (ten total) and six
rejected mutants pass; native event/timer/text-update counts remain unchanged.
Full desktop validation passes 153 scripts / 808 Lua syntax files; all 808 source
hashes and file membership match before/after the run.
[Full report](validation/meter-combat-visibility-2026-11-05.json).
No current native input, reload, profiler or settings changes occurred. Reload
before candidate acceptance and record exact build, loaded revision, addon list,
profile, hardware, resolution and scale. Test combat timer/rows and every native
visibility policy, group/content gates, host/tab changes, pane controls, source
windows, Edit Mode and Details takeover. Native taint, pixels and frame times
remain pending; other native setters are separate unverified provenance paths.
Pinned progression 5.5.4.70631, Era 1.15.9.70576 and Anniversary 2.5.6.70577 meter
TOCs select standard rather than their game types. Keep Details/capability
fallback, not a promise of native meter availability. Original Wrath remains
distinct and is not newly certified.

5 November minimap/mail follow-up: Forever's pinned native XML places mail at
`MinimapCluster.IndicatorFrame.MailFrame`, whereas the existing Flux lookup
checked older native locations and omitted its own named fallback. The corrected
lookup reuses that fallback with the same 20×15 appearance and cadence. Actual
production-function replay reproduces frame/listener growth without an inventory
provider. This is source/desktop evidence, not a native rendering or FPS result.
[Exact lifecycle scope and steps](MINIMAP_MAIL_LIFECYCLE.md).
Focused 504 checks pass versus 100 baseline failures / 494 attempts; five alternating
pairs and five rejected mutants pass.

A reload is required to retire previously retained frames. No new foreground
control, game input or profiling occurred. All new native client/provider/bag
transaction, minimap flicker, geometry, protection and performance checks remain
pending. The approved 19:15 Forever reload predates this fix. Retail tooltip
readiness separately passes 48 checks, five matched pairs and four mutants;
its Forever loader selection remains unverified. Original Wrath stays distinct
and unsupported by these native claims. Combined validation passes
153 scripts / 808 Lua syntax files with an unchanged
808-file source drift guard.
[Full report](validation/minimap-mail-lifecycle-2026-11-05.json),
[Retail tooltip scope](AUCTION_COLD_TOOLTIP.md).
Read-only host/file checks around 19:45 UTC verified the same Forever PID39984
and both runtime candidates byte-identical in all five synced client folders.
Loaded-code identity was not checked; on-disk parity is not native acceptance.

5 November provider snapshot row reuse, baseline `7f47a566`: the real Adapter/
Scheduler fixture passes all 700 checks; its exact baseline fails 190 of 700.
Five alternating pairs and five rejected mutants cover mail and owned-auction
rows, sparse/count/link semantics, immutable prior generations, cadence, direct
synchronous rebuilds, provider readiness and legacy/modern event routing. Full
151 scripts / 806 Lua syntax files pass. The complete 806-file source membership
and normalized hashes remain identical before/after validation, including the
newer consumable changes through `e2c6464`.
[Row-reuse scope and native checklist](PROVIDER_SNAPSHOT_ROW_REUSE.md),
[matched evidence](validation/provider-snapshot-row-reuse-comparison-2026-11-05.json).

Only private FillFromList changes: it prepares completed maps and reuses immutable
rows at the same index when ID/count/link match. The unchanged early guard,
synchronous Rebuild APIs, notifications and configured cadence remain. Full
prefix validation still visits O(N) facts. Temporary index maps are a storage
tradeoff, not proof of lower native CPU, memory bytes, FPS or freeze removal.
All five client/provider/bag transaction, pixel, protection and leak checks remain
pending for this new Adapter. The approved 19:15 Forever reload/source check with
Syndicator/profile0 and empty caches predates this code and cannot accept it.
The user-provided BugTabs1.4.9 report at 19:18:25 confirms the one-off diagnostic
BugGrabber/nil probe failure, not a native FluxUI runtime regression. No new game
input or settings/profiler change was used. The external provider is unchanged;
its separate private patch is not installed and requires separate authorization
after validation. Original/modern Wrath remain distinct and unverified.

5 November Consumables refresh timer: shared button/wisp/config countdown
uses public buff expiration minus refresh threshold. Five paired loaded-module
fixtures pass baseline and candidate (14/25 checks); full 150-script/805-Lua
desktop validation passes. Retail, Forever, Era, Anniversary, and progression
native confirmation remains pending, including visual and combat checks.
[Timer evidence](CONSUMABLE_REFRESH_TIMER.md).

5 November user native trace: open-bank charge detection in the Consumables
config called an absent restock-bank method and stopped grid construction.
The shared adapter call now uses `ForEachOpenStack` with character/warband
options. Five paired loaded-module baseline/candidate runs and full
149-script/804-Lua desktop validation pass. Retail, Forever, Era,
Anniversary, and progression in-game confirmation is pending; the supplied
stack establishes the baseline failure, not candidate acceptance. See
[charge scan evidence](RESTOCK_CHARGE_BANK_ITERATOR.md).

5 November consumable config visibility: shared editor path saves a valid
dropped item ID before its name loads and renders saved entries before the live
button update. Five baseline/candidate desktop pairs (eight checks each) and
full 148-script/803-Lua validation pass. Retail and Forever native verification
is pending, as are Era, Anniversary and progression client checks. Inspect
reload persistence, zero-effective-count weapon enchant visibility, tooltips,
secure click, and actual layout. See [case record](CONSUMABLE_TARGET_DETECTION.md).

5 November built-in snapshot preparation, baseline published `437fda7`: auction
and mail production fixtures pass 5,884 and 8,194 checks. Five alternating pairs
per fixture, eight rejected mutants and final full 147 scripts / 802 Lua syntax
files pass. The auction baseline fails 144 of 5,436 dynamic checks; the final mail
baseline fails 25 of 8,203. Client/provider labels are shared contracts with mocked
native APIs, not native client or provider certification. See
[auction preparation](BUILTIN_AUCTION_PUBLICATION.md),
[inbox preparation](BUILTIN_MAIL_PUBLICATION.md),
[raw comparison and source hashes](validation/builtin-publication-comparison-2026-11-05.json)
and [complete flow scope](MAIL_AUCTION_REWORK.md).

Both sources stage normalized index/count maps inside existing scan budgets and
publish only completed changed generations. Region objects, public Index APIs,
original equality and cadence remain. The intentional internal byIndex map
identity change follows the consumer search; current callers neither retain
those inner maps nor expose mail/auction regions through GetSnapshot. Staging
adds temporary maps; reduced preparation bursts do not establish lower total
native CPU, memory bytes or FPS improvement.

Partial native startup/source check: the user approved brief read-only access to
Forever PID 39984, the verified Forever executable, with MarioSuper in world.
At 19:14 CET, GetBuildInfo returned 1.60.1/build70790/interface16001 (build date
Nov3), and FluxUI, Syndicator and Baganator all reported loaded. At 19:15:37,
the source was Syndicator, itemDataRevision was 20261105.1 and scriptProfile was 0.
Byte parity of both changed source files plus Init was verified before the
19:15:51 reload. At 19:17:31, source/revision/profile0 were confirmed again;
at 19:18, cache mail and auction counts were both zero. This is partial startup
and source evidence, not acceptance of the changed built-in scan paths: the
active source was Syndicator. The older 17:37 unloaded setup is separate history.

No Buy, cancel, loot, enabling/disabling or profiling was performed. Previous
windows were restored and no further foreground work is planned. The user
identifies BugTabs1.4.9; BugGrabberDB was nil. One GetSessionId diagnostic failed because of an incorrect probe assumption;
that failure is not a native FluxUI regression.
Error history and logger settings were not cleared or changed; private raw
captures remain outside Git. All native transactions, freeze removal, taint,
pixels and long-session retention remain pending across clients/providers/bags,
including Buy-to-mail and final Open All. The [external Syndicator cold-post
finding](EXTERNAL_SYNDICATOR_POSTING.md) remains read-only and unfixed. Original
and modern Wrath remain distinct and unverified. No native freeze cure is claimed.

5 November mail/auction lifecycle candidate, baseline `e860ce6` already published:
real auction modules pass 628 checks and real Settings/Select/OpenAll modules
pass 880 checks. Five alternating pairs per fixture, eight rejected mutants and
full 145 scripts / 800 Lua syntax files pass. The two fixes prevent duplicate or
foreign-provider owned-list queries, permit final-mail cancellation and stop a
job when its owning module is disabled. Client labels, timer variants and provider
states exercise shared contracts, not native client emulation.
[Query ownership](AUCTION_QUERY_OWNERSHIP.md),
[mail job lifecycle](MAIL_JOB_LIFECYCLE.md) and
[full flow/ownership matrix](MAIL_AUCTION_REWORK.md).

Background host inspection found only Forever PID 25172, started at 17:55 CET.
The 17:37 unloaded observation below belongs to an earlier process; it does not
establish the current loaded state. No current candidate identity, transactions
or freeze removal have been verified. No game input, profiling or settings
mutation occurred in this phase. All five clients still need native mail/auction
and provider/bag acceptance with and without supported Syndicator/Baganator
configurations, including the last two messages, owner disable/profile changes,
reopen, post/buy/cancel and naturally observed sales. Original and modern Wrath
remain separate and unverified. Desktop query/action counts cannot certify
native CPU, allocations, latency, taint, rendering or FPS.

5 November built-in inventory/currency candidate, baseline `b664bb0`: production
module fixtures pass 790 metadata-ownership, 81 summary-pruning and 512 currency
iteration checks. Five alternating pairs per scenario and twelve rejected mutants
are recorded; final full validation passes 143 scripts / 798 Lua syntax files.
The metadata labels cover shared client/provider contracts, not native emulation.
Modern currency structures are source-verified for Forever/Retail; the three
legacy branches retain their existing code. Original/modern Wrath remain distinct
and unverified. See [item data](BUILTIN_ITEM_DATA.md),
[summary retention](INVENTORY_SUMMARY_PRUNING.md) and
[currency iteration](GOLD_CURRENCY_ITERATION.md).

Earlier inventory-phase native observations: the user
reports re-enabling FluxUI and whole-game freezes during many buyer sales with a
delayed spike, auction cancellation followed by mailbox entry, Open All from two
messages to one, and individual attachment mail. Read-only checks at 17:35 CET
returned a legacy/nil source marker; direct checks at 17:37 showed both addon
loaded flags false and Flux/FluxUI globals nil. The only observed game was Forever
PID 47424, reporting 1.60.1 / 70790 / interface16001, scriptProfile0 and Syndicator
unloaded. The exact candidate tree is therefore not verified as loaded, despite
the user's re-enable report. Previous window restored; no enabling or CPU capture
was performed. All new native feature, transaction, protection, pixel, retention
and performance acceptance remains pending. The next permitted check must verify
`Flux.Inventory.itemDataRevision == "20261105.1"` before interpreting results.
Historical startup observations and earlier phase results below do not certify
this candidate.

Latest phase: the native mail-command guard prevents progression/completion
while C_Mail reports pending, with bounded8s wait and existing cadence retained.
Five matched desktop pairs reproduce360 to0 unsafe requests and40 to0 premature
completions; three mutants rejected. Final full validation:140 scripts /795 Lua
syntax files pass. Earlier139/794 evidence describes the preceding four-fix tree.
The user still reports live sale/mail freezes, including Open All at Processing
Message2 and final mail; no live cure is claimed.
[Guard, source contract and pending native checks](MAIL_NATIVE_COMMAND.md).

Latest native outcome: the user confirmed the same freeze after reload with
Syndicator unloaded. A later optional60s CPU capture was lost before save when
the old process exited during reported bulk mail. No new crash report identifies
a cause. Profile0 and the prior nil capture root were restored/verified15:51:34;
foreground returned. This is failed/inconclusive operational evidence, not a
benchmark pass. See [capture details and cleanup](RAID_MAIL_AUCTION_FOLLOWUP.md).

5 November raid/mail/auction follow-up: baseline `8681672`; shared loaded-module
contracts pass 290 raid, 3,140 mail-worker, 380 mail-detail and 365 auction checks;
full 139 scripts / 794 Lua syntax pass. Five alternating pairs per scenario and
eight rejected mutants cover incomplete raid pools, duplicate/stale mail wakes,
hidden/disabled detail work and progressive Syndicator auction lists. Client and
provider labels are shared-contract models, not native-client emulation.

Sandbox process enumeration initially hid the game; host inspection confirmed
Forever 1.60.1.70790 and a background 1906 by 1032 auction/bag capture without
changing focus. Approved reload completed15:32:54CET. Native commands confirmed
1.60.1/build70790/interface16001, FluxUI loaded and Syndicator unloaded; at15:35:48
raid setup ready, scriptProfile0 and no current-session error messages printed.
Prior windows were restored after successful checks. This is partial startup
sanity only; the full addon list remains uncaptured. All-client mailbox loot,
secure raid/pet-battle behavior, native errors, pixels and matched performance
remain pending. The stored UNKNOWN event predates the previous correction; the
new reporter warnings still do not identify an initiating addon. Original and
modern Wrath remain separate and uncertified.
The user subsequently reports Syndicator is not loaded in the current failing
session, while AH/mail lag and reporter warnings at 15:03:09 and 15:27:44 remain.
This differs from the installed-provider source fixture; it does not establish an
active Syndicator route. The runtime enabled-addon list is still uncaptured.
[Exact source pins, observations and remaining steps](RAID_MAIL_AUCTION_FOLLOWUP.md).

5 November meter/header ownership: compared Forever 1.60.1.70790 and Retail
12.1.5.70783 native meter paths; checked visible-header allocation gate on pinned
Era 1.15.9.70576, Anniversary 2.5.6.70577 and MoP 5.5.4.70631 sources too. Shared
capability/absence mocks pass 180 meter + 150 raid checks; full 136/791 pass.
No secret VM, native rendering or secure CreateFrame acceptance is simulated.
Native reload/taint/pixels and UNKNOWN header attribution remain pending;
original/modern Wrath remain distinct and uncertified.
[Exact commits and native checklist](METER_RAID_NATIVE_OWNERSHIP.md).

5 November consumable target detection: a generic 30-check loaded-module
desktop fixture verifies staff-only mismatch/count zero, staff/off-hand
selection, general oil, categories, cached metadata and equipment/combat
refresh. Five baseline/candidate pairs reproduce the old dagger target.
All native clients still need real item/tooltips, protected clicks, combat,
locale, pixels, taint and matched performance checks.
[Exact scope](CONSUMABLE_TARGET_DETECTION.md).

5 November hidden inventory: freshly read executables Era 1.15.9.70576,
Anniversary 2.5.6.70577, MoP 5.5.4.70631, Retail 12.1.5.70783, Forever
1.60.1.70790. Installed Baganator 840/Syndicator 289 references checked read-only.
Shared-contract desktop checks: 260 integration + 65 native-bag pass; full 133/788
pass. Labels do not emulate native clients/providers. Native timings, secure
behavior, pixels and mailbox/AH lag improvement remain pending in every provider
configuration; original/modern Wrath remain distinct and uncertified.
[Reproduction and per-client checklist](HIDDEN_INVENTORY_WORK.md).

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

5 November auction metadata: global cache events no longer harvest all bag/bank
names or populate classification records for unrelated auction items. Requested
metadata, failed-load retry, static consumers, explicit completions and immediate
name-only reagent/restock updates are preserved. Five matched desktop pairs:
280,000 name reads and 2,000 container walks become zero for the unrelated burst;
230 checks pass, three mutants rejected; full 127 scripts/782 syntax pass.
The native Buy spike still needs attribution/acceptance across both providers.
[Evidence and next captures](AUCTION_METADATA_WORK.md).

5 November auction Buy investigation: active-row highlighting uses the native
view instead of the retained child pool. Five matched desktop pairs:200,600
versus600 traversal visits;200 classifications unchanged;116 checks pass and
two mutants rejected. Full126/781 passes. Native Buy spike and every client/provider
integration remain pending. [Evidence and steps](AUCTION_PURCHASE_REFRESH.md).

5 November utility pet faces: the user clarified a question-mark/wrong-icon
symptom. The manager now owns the selected journal-pet icon and tooltip via
existing override surfaces, with modifier changes, metadata completion and
cleanup. Summon macros/GUID storage remain intact. 920 checks pass (old40
failures), three mutants rejected; full125/780 passes. Native checks pending.
[Evidence and native steps](UTILITY_PET_FACES.md).

5 November live-zero follow-up: exhausted food/water/potion/bandage buttons
now reset from reliable live bags before Syndicator's delayed cache callback.
The painter retains the verified count; loading holds and combat deferral
remain. Button-level375 checks pass (baseline200 failures), three mutations
rejected; full124 scripts/779 Lua syntax pass. Native acceptance pending.
[Evidence and native steps](SYNDICATOR_CONSUMABLE_UPDATES.md).

5 November Syndicator consumables: batched bag callbacks now retain every
added/removed item and dirty bag until publication. This fixes a reproduced
missed selector update for better items and last-use depletion across food,
water, potions and bandages. Five desktop pairs: baseline 200 failures versus
candidate 0 per400 checks; three mutations rejected. Full suite123/778 passes.
Native gameplay, pixels, taint and performance remain pending.
[Evidence and exact native checks](SYNDICATOR_CONSUMABLE_UPDATES.md).

4 November built-in mail: all five local Blizzard mirrors declare `MAIL_SHOW`,
`MAIL_CLOSED`, `MAIL_SEND_SUCCESS` and native Open All; Retail/Forever use
`Blizzard_MailFrame`, Era/Anniversary/MoP use the Classic MailFrame path.
Retail/Forever inbox redraw differs (`InboxFrame:Update()` on Forever), so
Flux selected checkboxes hook the available method or global function. The
local mirrors are older than some installed builds; bundled live/forever/
classic commit pins are inventory evidence only. Focused desktop checks 67;
full suite 118 scripts/768 syntax files, zero failures. Native per-client
mailbox open/close, actual item/money operations, visual placement, combat
taint and timing remain pending. [Evidence](MAIL_INTEGRATION.md).

4 November Era/Anniversary combined bank: inspected versioned Gethe Vanilla
and TBC bank source mirrors and their loaded TOC paths; installed clients are
newer and upstream mirror commits are unavailable. Loaded-module desktop
models pass 33 checks each for native button/container IDs, six/seven bank
bag slots, compact purchase controls, no-toggle slot clicks, drag/drop,
restock attachment, late Baganator
handoff and close/restore. The full suite result is in
[evidence](CLASSIC_COMBINED_BANK.md). Native screenshots, item operations,
purchase confirmation, taint, FPS and frame time are pending.

1 November passive trinket correction: the user's intended rule is dim for an
equipped trinket with no on-use spell and bright for a ready on-use trinket.
Baseline fails the new passive check; candidate passes 10 focused checks and
112 isolated desktop tests/757 Lua syntax files. Native five-client use
effect, cooldown, click, pixel and taint acceptance remains pending.
[Evidence](TRINKET_EQUIPPED_USABILITY.md).

31 October equipped trinket tint: the user's native observation is that an
equipped, ready trinket with a use effect stays dark while alive. The
baseline loaded-paint test reproduces this, the candidate passes 8 focused
checks, and combat gem/stone controls pass 14 checks. Isolated published-source
desktop validation passes 112 tests/757 Lua syntax files. Five-client native
ready/cooldown/dead/revive tint, clicks, keybinds, pixels and taint remain
pending. [Evidence](TRINKET_EQUIPPED_USABILITY.md).

31 October chat durability teleport follow-up: focused desktop events model
empty durability at world entry, first/late return, player-only inventory
refresh, expiry and repeated teleports. Full 112-test/757-Lua suite passes.
Native loading-screen recovery, clicks, pixels, combat taint and frame time
remain pending on all five supported clients.
[Evidence](CHAT_CHARACTER_DURABILITY.md).

31 October secret-channel fallback: Retail/Forever unit API declarations
confirm cast identity can be secret; castBarID supplies no magic school.
Explicit channel-ID selection keeps the native/default bar when identity
cannot be read. Baseline rejects the 56-check nameplate fixture; the shared
renderer passes 13,898 checks. Native combat, pixels, taint and frame time
remain pending. [Evidence](SECRET_CHANNEL_FALLBACK.md).

31 October chat character durability: the loaded painter distinguishes
readable full durability from absent/restricted values. The focused desktop
fixture covers `100%`, `75%`, `0%`, secret and empty readings; full
112-test/757-Lua validation passes. Native character-button text, equipment
changes, pixels, clicks, combat/taint and frame time remain pending on every
supported client. [Evidence](CHAT_CHARACTER_DURABILITY.md).

31 October nameplate backdrop: desktop renderer checks place single/hybrid
artwork below native chrome, including plate-level changes during a cast;
the prior source fails the new layer assertion. Full 112-test/757-Lua suite
passes. Native four-client pixels, combat taint and frame time remain pending.
[Evidence](NAMEPLATE_BACKDROP_LAYER.md).

31 October combat grid conjured-item tint: the user's native observation is
that mana gem and healthstone stay bright while other combat items darken on
death. The corrected loaded-paint desktop fixture passes 14 checks, baseline
fails at dead gem, and the full 111-test/756-Lua suite passes. Actual Retail,
Forever, Era, Anniversary and MoP Classic death/revival, full-resource,
cooldown, count, input, pixel and taint checks remain pending.
[Evidence](COMBAT_GRID_CONJURED_USABILITY.md).

31 October cast fill/tip follow-up: the user reported missing color and
unit-frame fill on all clients. The desktop regression fails against the
published source and passes with progress-bar parenting, native source
hide/restore and school Spark tint. Full 110-test/755-Lua suite passes.
Native all-client pixels, combat taint and frame time remain pending.
[Evidence](CAST_SCHOOL_FILL_TIP_FIX.md).

31 October nameplate cast-school styling: desktop 48-check native-bar lifecycle
model plus shared renderer checks pass on Retail, Forever, Era and Anniversary
branches; full 110-test/755-Lua validation passes. Native client cast/channel,
secret fallback, interrupt/fade, native text/shield visibility, `SetUnit` taint,
pixel parity and matched performance checks remain pending.
[Evidence](NAMEPLATE_CASTBAR_SCHOOLS.md).

30 October MicroMenu nil-center correction: the user's native Classic-path
stack identifies a pre-fix `GetEdgeButton` failure during Flux's LFG rebuild.
The focused desktop model reproduces old callback ordering and passes with
selected/unused children moved before Show/Hide; full suite passes 109 tests /
753 Lua syntax files. The read-only Era reference confirms synchronous
`MicroButton_OnShow` layout, but the stack does not name the user's build.
Native post-fix reload, Edit Mode, placement, combat, pixels, taint and frame
time remain pending on Era, Anniversary, MoP Classic, Retail Midnight and
Forever. [Evidence](17-micromenu.md).

30 October delayed loot correction: desktop fixture checks two closed
mob/chest sources with reversed late item messages, a ten-second duplicate,
fast-loot capture race, late currency/money, and session expiry. Full suite
passes 108 scripts / 752 Lua syntax files. Native event order, source
attribution, UI scale, pixels, taint and frame time remain pending on Era,
Anniversary, MoP Classic, Retail Midnight and Forever.
[Evidence](LOOT_CURSOR.md).

30 October cursor-position correction: desktop fixture verifies the cursor
snapshot at LOOT_READY/LOOT_OPENED, delayed item/currency rows, and two
overlapping batches with separate retained positions. Full suite passes
108 scripts / 752 Lua syntax files. Native click-to-event timing, UI scale,
pixels, taint and frame time remain pending on Era, Anniversary, MoP Classic,
Retail Midnight and Forever. [Evidence](LOOT_CURSOR.md).


30 October loot-source correction: desktop fixture excludes crafted,
pushed/rewarded and outside-window self-loot chat while retaining slot,
bonus and won-roll loot; currency follows the loot-window gate. Full suite
passes 108 scripts / 752 Lua syntax files. Native event order, source
classification, taint, pixels and frame time remain pending on Era,
Anniversary, MoP Classic, Retail Midnight and Forever.
[Evidence](LOOT_CURSOR.md).


30 October 2026: attached stance bars now follow player-frame scale, including
immediate slider changes and reload; detached placement restores normal size.
Existing combat deferral is retained. 21 stance and 28 bridge checks pass;
full suite: 108 scripts /752 Lua syntax files, zero failures. Native pixels,
input and taint remain pending (no visible WoW process).
[Evidence and native steps](UNIT_FRAME_SCALE.md).

30 October FluxLoot callback correction: the user's native stack identifies
the pre-fix CallbackHandler argument shift at line 402. A signature-aware
desktop fixture reproduces the error against the old call and passes with
the corrected receiver/event/method order; full suite passes 107 scripts /
751 Lua syntax files. Native post-fix login and profile change/copy/reset
remain pending on all five supported clients. [Evidence](LOOT_CURSOR.md).


30 October cursor money follow-up: desktop checks pass for localized positive
money parsing, gold/silver/copper symbols, white numbers and exact 1 silver/
1 gold leading-icon thresholds. Full suite passes 107 scripts / 751 syntax
files. Native money text, icons, pixels, taint and frame time remain pending
on Era, Anniversary, MoP Classic, Retail Midnight and Forever.
[Evidence](LOOT_CURSOR.md).


30 October cursor loot default follow-up: the shared default table now starts
fast pickup and cursor alerts on, with 3-second expiry, on all five supported
clients. The desktop fixture exercises the actual default and option control.
Native new-profile, existing-profile and FasterLoot coexistence checks remain
pending. [Evidence](LOOT_CURSOR.md).


30 October cursor loot: the new profile-scoped fast pickup and cursor alerts
have a focused desktop event fixture and a passing 107-script/751-Lua full
suite. Native loot behavior, locale parsing, cursor pixels, FasterLoot
coexistence, combat/taint and frame time are pending for Era, Anniversary,
MoP Classic, Retail Midnight and Forever. No client or profiler was changed.
[Evidence](LOOT_CURSOR.md).


30 October historical Sticky Targeting follow-up: the linked GitHub main
source matches the pre-fix local routine. The older 13 August snapshot uses
the registered negated setting on Retail; the current targeted route passes
76 desktop checks. Native Retail/Forever checkbox value, reload persistence,
taint and frame time remain pending; no WoW process was visible.
[Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

30 October Retail Controls/camera report: the user's native pre-fix readback
was camera factor `1.900000`, engine maximum `nil`, Sticky Targeting CVar
`deselectOnClick=0`, with first-load verification failing on the camera.
The revised 68-check desktop fixture passes; post-fix Retail acceptance is
pending. No WoW process/window was visible for a background check. Era and
other clients remain native pending. [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

30 October first-load settings follow-up: the five-client source-driven
desktop suite passes 60 first-load checks and 507 binding checks; full
validation passes 106 scripts/748 Lua. Native Controls, nameplates, raid
appearance, single completion message, reload preservation, Settings reset,
taint and frame time remain pending for all clients. No WoW process was
visible; no client was controlled. [Evidence](NONBINDING_FIRST_LOAD.md).

30 October Hearthstone selector native report: the Toy Box choice selector's
hover handler threw at line 491 because the client's `GetItemInfo` global was
nil. The new source-driven fixture reproduces that failure and passes 19
checks after using the shared item service and Toy Box name fallback. Full
desktop validation passes 106 scripts/748 Lua files. The user's report
establishes the hover error, not successful toy selection or native post-fix
acceptance. Hover, choice, secure use, reload persistence, combat/taint and
pixels remain pending. [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

30 October Hearthstone panel follow-up: the user reports the panel remained
absent beside Toy Box. The previous fixture supplied `FLUX_API` before its
actual TOC position and could not prove registration. A corrected 17-check
source-driven fixture verifies the editor registers using earlier `Flux.Cap`
while `FLUX_API` is absent; full desktop validation passes 106 scripts/748
Lua syntax files. Native panel visibility, toy selection/use, reload scope,
combat/taint and pixels remain pending on each Toy Box client.
[Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

30 October Hearthstone Toy Box config: a source-driven desktop fixture passes
14 checks for a toy-capable client without `ToggleCollectionsJournal`, modern
Collections loading, editor visibility, owned-toy selection/readback and a
second native opener. Full validation passes 106 scripts/748 Lua syntax files.
Every Toy Box client still needs native Toy Box opening, tab switching, toy
choice, actual Hearthstone button use, reload/scope persistence and combat/
taint checks. Basic fallback on non-toy clients remains to be checked natively.
No WoW process was visible or controlled. [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

30 October atomic-context binding follow-up: the five-client production-source
model passes 507 checks, with 105 scripts/747 Lua files passing the full desktop
suite. Mariosuper Era and Pandasans Retail were requested for native testing,
but no WoW process/window was visible in the workspace. Client WTF folders
appeared only transiently during read-only inspection, so they cannot prove
the live client state or a post-change reload.
Actual first-login/reload persistence, bridge clicks, grid labels, no replay,
taint and frame time remain pending. [Evidence](BINDING_ATOMIC_CONTEXT.md).

30 October binding persistence rewrite: 501 focused checks across five
modeled clients verify first-account native account-set save/load, empty-cache
version-5 repair, reload preservation, rollback and eight-write batches.
Full 105-script/747-Lua desktop suite passes. Actual client disk persistence,
bridge key presses, labels, taint and frame time remain pending.
[Evidence](BINDING_PERSISTENCE_REWRITE.md).

30 October binding repeat correction: 544 focused desktop checks across five
modeled clients cover first-account same-login application, strict no-replay
after partial writes/save failure, old pending marker migration, lost account
marker with existing native bridge keys, overlap suppression and the
eight-write frame bound. Full 105-script/747-Lua suite passes. Actual client
reload, binding persistence, hotkey labels and secure input remain pending.
[Evidence](ACCOUNT_BINDINGS_ONCE.md).

30 October account-only binding correction: 528 focused desktop checks across
five modeled clients cover first-account arming, single global completion,
old-marker migration, no character/binding-set replay, Settings callback
isolation and the eight-write frame bound. Full 105-script/747-Lua suite
passes. Actual first-account keys, later character behavior, persistence and
frame time remain pending. [Evidence](ACCOUNT_BINDINGS_ONCE.md).

30 October one-time binding correction: 521 focused desktop checks cover a
single full reset, completed-scope no-scan/no-write behavior across reload,
one registry scan and at most eight binding writes per frame on five modeled
clients. Native first-load keys, persistence, secure clicks, labels, combat
and actual frame time remain pending. [Evidence](FULL_BINDING_RESET.md).

30 October full binding reset: 521 focused desktop checks cover all-key clear,
supported Flux template apply, active-set save, late native replacement,
cross-login confirmation, combat and failure paths across five client models.
The full 105-script/747-Lua suite passes. Actual first-login/reload bindings,
secure key presses, hotkey labels, account/character scope and taint remain
pending on every client. [Evidence](FULL_BINDING_RESET.md).

30 October binding persistence: 35 focused desktop checks now cover a Flux
bridge assignment lost on reload, repair, and cross-login completion. The
full 105-script/747-Lua suite passes. Native first login, first reload,
account/character binding sets, real bridge clicks and both grids' hotkey
labels remain pending on every client. [Evidence](DEFAULT_GRID_BINDINGS.md).

30 October protected-client raid options: nine focused checks cover Flux-owned
class colors, power bars and health text against conflicting native CVars,
preview ownership and retained Classic reads. The full 105-script/747-Lua
desktop suite passes. Native first-login/new-character appearance, Blizzard
Settings values, real protected raid cells, combat and Edit Mode remain
pending. [Evidence](RAID_OWNED_SETTINGS.md).

30 October raid/nameplate follow-up: 15 focused desktop checks cover late
Classic raid profile completion and Medium nameplate defaults/migration;
104 scripts/746 Lua files pass in full validation. Native Classic power bars,
class colors and frame size, all-client nameplate size and Retail/Forever
protected raid behavior remain pending. [Evidence](RAID_NAMEPLATE_DEFAULTS.md).

30 October same-login binding follow-up: the prior repair did not assign keys
on the user's first load; the user also reports missing combat/noncombat grid
labels. The revised world-entry and delayed check pass 29 focused binding
checks; the live EBS hotkey refresh passes 7 focused checks. Full validation
passes 103 scripts/745 Lua files.
Each client still needs a first-load native check of `7`, `8`, `Y`, `6`, labels,
binding-set persistence and combat/taint. [Evidence](DEFAULT_GRID_BINDINGS.md).

30 October grid binding follow-up: the active native binding-set seed passes
21 desktop checks for default grid commands, custom-key preservation, account/
character scopes and deferred work. Full validation passes 102 scripts/744 Lua
files. Every client in `CLIENT_MATRIX.csv` still needs a reload on a suitable
test character, actual key click and hotkey label checks, persistence across
reload and combat/taint observation. [Evidence](DEFAULT_GRID_BINDINGS.md).

30 October first-login defaults: 42 production-source checks cover modern table,
tuple and legacy CVarInfo shapes, character/account/missing scopes and filtered
nameplate bitfields. The full 101-script/743-Lua desktop suite passes. For every
client in `CLIENT_MATRIX.csv`, native fresh-account and new-character CVar
classification/application, queue completion, bindings, Settings UI, combat and
taint remain pending. Gethe branch versions and exact candidate source identities
are in [the defaults record](DEFAULTS_FIRST_LOGIN.md). No client was controlled.

30 October vendor chat: desktop checks cover full denominations and gold, silver,
copper texture tokens for gain, expense and manual repair. The existing vendor
identity fixture passes. Native chat texture rendering and merchant transaction
checks remain pending on every client; no game interaction was performed.

30 October scale follow-up: desktop checks now cover 50% and 135% player
clearance, portrait centering, focus/chat mixed scales and conditional 3D
portrait refresh. Full 99-script/740-Lua suite passes. Native portrait crop,
action-strip clearance, hit areas, combat and pixels remain pending for every
client in `CLIENT_MATRIX.csv`. [Scale record](UNIT_FRAME_SCALE.md).

30 October whole unit-frame scale: the focused production-bridge model covers
dependent roots, detached chrome and both ToT parent layouts; full desktop
validation is in [the scale record](UNIT_FRAME_SCALE.md). Each client in
`CLIENT_MATRIX.csv` still needs native player/target/focus size, class resource,
cast/aura/indicator alignment, hit-area, combat/taint and pixel checks. No
client was controlled for this change.

30 October vehicle/durability layout: [the seat owner](../Other/FluxVehicleSeats.lua)
and [durability owner](../StatusBars/FluxStatusBar.lua) pass source-driven desktop
checks for menu-only, status-only, both and clear top-left chrome, PvP clearance,
load order, 70% seat scale and combat deferral. All clients in
`CLIENT_MATRIX.csv` have desktop coverage from the full 99-script/740-Lua suite;
native seat/durability art, click target, combat/taint and pixel checks remain
pending for this change.

30 October unit-frame follow-up: [zero-maximum resource behavior](UNIT_POWER_VISIBILITY.md)
passes desktop models and the 96-script/737-Lua full suite. Native checks are
pending for every client in `CLIENT_MATRIX.csv`, including combat, restricted
values, raid cells and pixels. Prior native results below do not certify this change.

[BUG-012/PERF-011 teleport follow-up](TELEPORT_CAST_WORK.md): user confirms Retail.
527 desktop assertions pass, including native display empty/opaque models and
legacy rune controls. Full 95 scripts/736 syntax files pass. No native input,
reload or capture this batch. Actual interruption latency/combat/taint/pixels and
non-travel custom-flyout comparisons remain pending.

This record began as a local installation/source audit. Era now has a native vendor attribution capture and five alternating background getter pairs; full visual/security and whole-vendor after acceptance remain pending. [Native evidence](TIER_COUNT_WORK.md). [CLIENT_MATRIX.csv](CLIENT_MATRIX.csv) records installed executable versions separately from `_FluxUI.toc` interface declarations, reference-source versions, and test status. [REFERENCE_MANIFEST.csv](REFERENCE_MANIFEST.csv) pins inspected metadata/license files; its hashes identify those files, not entire upstream packages.

## Installed roster and evidence limits

The requested Era, Anniversary, MoP, Retail, and Forever executables are accessible. Their Windows PE FileVersion values are respectively `1.15.9.70576`, `2.5.6.70577`, `5.5.4.70631`, `12.1.5.70575`, and `1.60.1.70685`. These values are installation facts, not executed `GetBuildInfo()` results or evidence of successful addon loading. Era runtime GetBuildInfo confirms 1.15.9 / 70576 / interface 11509. Its numeric project ID was not recorded; other runtime build/interface values remain pending.

The supplied spec calls Retail 12.1.0. The installed executable is 12.1.5.70575 and Flux's advertised interface remains 120100. All five named local Blizzard source trees are older than the corresponding installed executable. Do not silently relabel their builds or use them to certify current native callback contracts. They have no `.git` directory; upstream commit IDs are unpinned.

Modern Wrath and retained Cata remain separate rows with no matching installed executable found in the inspected immediate client directories. `_Ascension/Wow.exe` and `Ascension.exe` report `3, 3, 5, 12340`; this is a custom original-3.3.5 installation, not modern Wrath Classic. The supplied original Wrath UI tree has a descriptive README but no pinned build/commit. Current project-constant branches and filtered files do not establish original-3.3.5 support. Keep that row unsupported/unverified pending an explicit adapter and native validation; do not copy the addon to that client as part of this audit.

Other executables observed, outside the primary acceptance roster: `_beta_/WowB.exe` 12.0.1.66220, `_ptr_/WowT.exe` 12.1.7.70493, `_classic_era_ptr_/WowClassicT.exe` 2.5.6.70006, and `TurtleWoW/WoW.exe` 1.12.1.5875. Folder labels alone are insufficient to classify a client. No new deployment was made to any installation.

## Optional providers and local references

Retail's active AddOns root contains no top-level Syndicator, Baganator, Details, or Questie folder. Read-only reference availability is different from enabled-addon state: `__AddonsForRef/Syndicator` is version 267. Current Syndicator 288, Baganator 839, Details `#Details.20261015.15339.172`, and Questie 12.3.1 are present under both Era and Anniversary. AddOns.txt and private character settings were not used to infer an enabled load list. Record the actual loaded list in each native run.

Syndicator 288 source exposes `API.IsReady`, `GetCurrentCharacter`, `GetCharacter`, `GetWarband`, and the `Ready`, `BagCacheUpdate`, `CurrencyCacheUpdate`, and `WarbandCurrencyCacheUpdate` callbacks used by Flux. Its callbacks publish current-character identity and dirty bag maps in the expected source shapes. This verifies inspected API spelling/shapes only. Flux's adapter retains built-in facts while waiting, changes `Inv.source` to `syndicator` on `Ready`, proxies the account store, and avoids duplicate location tooltip lines. Baganator readiness is separate: its deferred bridge waits for `Baganator.API` and installs categories, gear protection, and bank controls.

The currency handoff audit found that four built-in currency event callbacks remain registered after `Store.SetUsesSyndicator(true)`. Before the fix, `PLAYER_MONEY` can still write the shared currency snapshot and the other callbacks schedule unnecessary inventory work. The modernization change addresses this narrowly; the root work log/performance ledger records its regression and before/after results. Native confirmation is still required. This does not claim all built-in provider resources have been retired; other region callbacks, timers and permanent mail hooks need their own lifecycle checks.

The continuation fixes two more deferred ownership paths: mail/auction scans now
cancel on their next callback after handoff, and pending send/return completion
discards builtin attribution before resolving a provider-owned character table.
See [provider lifecycle evidence](PROVIDER_HANDOFF_LIFECYCLE.md). Its desktop checks
do not change native acceptance status. Add queued/partial scans, forced final
inbox scan/retries, known-alt send/return success/failure and late Ready between
capture and completion to native scenarios where naturally reproducible. Preserve
standalone mailbox-open behavior and all existing interaction timing. Auction/guild/
void event ownership still needs separate evidence.

The baseline documentation contained several discrepancies corrected in this batch. `29-integrations.md` and `90-reference-inspirations.md` listed external companions in TOC OptionalDeps, but the actual TOC declares only Blizzard_UnitFrame and Blizzard_CompactRaidFrames. `21-inventory-foundation.md` and `29-integrations.md` described a Syndicator timeout/session fallback; the current adapter performs Ready-driven handoff. `29-integrations.md` described global Baganator item-identity wrappers, while current `BaganatorCompat/Loader.lua` leaves Blizzard item identity APIs intact, as `24-baganator-compat.md` already documented. Related stale architecture/command descriptions in `07-runtime-architecture.md` and `31-commands-and-bindings.md` are reconciled with the loaded source. The preserved baseline and supplied specifications retain the prior wording as evidence; these corrections do not restore obsolete runtime behavior.

Reference copies were inspected read-only. MoveAny, EllesmereUI, the local Bartender4 variant, Scrap, Syndicator, and Baganator contain reserved-rights notices. Clicked includes GPLv3. ButtonForge, Buffet, Restocker, and TrinketMenu did not supply a verified root-level reuse grant in the inspected files; bundled-library licenses do not license their host addons. ThreatClassic2 2.67 declares MIT in its TOC, but it is not assumed to be the requested `classicthreat`. ItemRack and a package named `classicthreat` were not found in the inspected reference/primary addon locations. No new code or assets were copied.

## Desktop checks actually executed

On 29 October 2026, from this checkout:

```powershell
lua tests/late_inventory.lua
lua tests/optional_startup.lua
lua Inventory/_tmp_inventorylag_smoke.lua
```

All exited 0 on Lua 5.4.6. The adapter test passed absent/pending/ready/repeated-readiness cases; optional startup passed BigDebuffs late initialization/idempotency/combat deferral; the inventory harness reported 1,732 checks across mocked Retail, Forever, Mists, Cata, Era, Anniversary and Wrath, for built-in and Syndicator pipelines. These particular harnesses do not load `Inventory/Builtin/Currency.lua` and do not cover the new currency regression. Their unchanged source inputs are in the recovered baseline; the final validation report identifies the candidate corpus and whole-suite result. They do not execute the installed provider addons or certify native WoW behavior.

Historical native captures remain under `docs/validation/`, including Retail and Forever CPU/presentation samples. They describe earlier trees/configurations and do not become before/after evidence for this change. Keep their original timestamps, build values and limitations. No current FPS, frame-time, taint, secret-value or pixel-parity result is claimed.

## Native acceptance procedure

Use one `_FluxUI` identity and the same saved profile for baseline/candidate, sequentially. Keep the recovery archive outside Interface/AddOns. Before any sequential source swap, close WoW, preserve the current working tree and relevant WTF data, and select only the recorded addon revision without resetting user changes. Do not enable a second addon copy. Initial baseline is commit `7436820453d2248c84c99fff71507553efc47c19` plus the recovered actual-file manifest; obtain the candidate identity from `STATUS.md` and the result ledger.

1. For each available primary client, record `/dump GetBuildInfo()` and `/dump WOW_PROJECT_ID`, hardware/driver/OS, loaded addons with versions, character/class/spec, zone/camera, keyboard or gamepad mode, resolution, render/UI scale, graphics settings, fonts, Flux options/profile, and profiling settings. Treat unavailable API outputs as unavailable rather than inventing a value.
2. Capture baseline screenshots at the same UI state: full idle HUD; Flux Window Map/Meter/Options; native and Flux unit-frame modes; bags/bank; currency/gold strip and tooltips. Repeat equivalent candidate screenshots and compare pixels and frame geometry. Keep mouse position, selected target, combat state, buffs, animation phase and scroll positions matched; document masks for unavoidable dynamic regions. Check option defaults/scopes, input edges, hover timing, held modifiers, menus, binds, slash commands and reload persistence.
3. Validate standalone inventory with Syndicator/Baganator disabled through the normal addon UI, then reload. `/fluxinv` should report `source=builtin` and eventual readiness. Observe gold and token changes, bank deposits/withdrawals where supported, item counts and location tooltips. Close/reopen bags and bank and traverse a loading screen. Restore the original addon selection after this scenario.
4. Enable the installed external Syndicator normally and reload with the same profile. `/fluxinv` should eventually report `source=syndicator`, `ready=yes`, and `syndicator=yes` in the store line. With `/fluxstartup on` followed by `/reload`, the startup report can expose the provider-ready milestone. A naturally fast Ready event may not exercise delayed handoff: mark that case unobserved rather than forcing provider globals or manipulating protected game APIs.
5. For the currency fix, after confirmed Syndicator ownership, earn/spend a recorded small amount of money through ordinary gameplay and open/close the bank; exercise a token update where available. Verify Flux gold/currency displays and tooltips follow provider updates once and do not regress to a stale built-in snapshot. In the standalone scenario verify those same native events still update immediately. Duplicate callback counts require a narrowly scoped diagnostic/native trace; visual correctness alone does not measure eliminated work.
6. Add Baganator and repeat bank/restock, gear-set shields and protection, junk/consumable categories, live versus cached-bank checks and profile reload. Repeat late native frame loads and combat entry/exit. Check existing Questie tracker/map ownership and Details meter behavior with their recorded versions; absent dependencies must retain supported standalone behavior. Do not execute destructive junk sales or equipment changes merely to populate a benchmark; use controlled items and reversible operations appropriate to the scenario.
7. Measure startup, steady idle and burst scenarios separately. For CPU captures, use `/console scriptProfile 1`, `/reload`, 30 seconds warm-up, then `/fluxperf capture 30` and `/fluxperf last`. Run at least five matched baseline/candidate pairs, alternating order, preserving each raw capture before the next overwrites the last-result slot. Record `/fluxstartup` separately and disable it with `/fluxstartup off` when done. Repeat unprofiled runs using `/console scriptProfile 0` and `/reload`; restore original profiling preferences afterward. If the client lacks a capture API, record that result explicitly.
8. Preserve raw samples and report variation, resource counts, CPU attribution, available memory deltas and operation latency. The capture's one-second FPS samples and recent profiler averages do not supply a frame-time distribution or reliable tails. Use a separately documented native frame-time trace where available; otherwise those fields remain pending. Never sum overlapping inclusive timings or equate reduced addon CPU with improved FPS.
9. Check Lua errors, blocked actions and taint attribution while exercising secure bindings, vehicle/possess/form transitions and combat-deferred operations. If collecting taint logs, record prior logging state and restore it afterward. Retail/Forever secret-value behavior must be observed through supported display APIs, without replacing globals or hiding illegal calls. Record each client/scenario as passed, failed, inconclusive, unavailable or pending with artifacts.

Reproduction of the read-only installation metadata:

```powershell
Get-Item 'F:\World of Warcraft\_retail_\Wow.exe' | ForEach-Object { $_.VersionInfo.FileVersion }
Get-Content '..\__AddonsForRef\wow-ui-source-live\version.txt'
Get-FileHash '..\__AddonsForRef\wow-ui-source-live\version.txt' -Algorithm SHA256
```

Use the corresponding verified path in the CSV for other clients/references. No native row can move to passed solely because these commands or desktop mocks pass.

## Windows lifecycle continuation — native checks pending

BUG-004/PERF-003 changes only mover discovery/watcher/disable lifecycle. The desktop
suite passes 85 scripts/726 syntax files and its focused production-code replay
passes 220 checks, including 100 toggle cycles. These do not advance any native
client row. Follow [Windows native steps](WINDOW_MOVER_LIFECYCLE.md): disabled reload,
late panel discovery, options/public API disable and re-enable, gesture cancellation,
saved geometry/scopes, protected combat Apply and matched screenshots/input. Capture
matched native startup/idle/burst performance with profiling overhead accounted for.
Auction/guild-bank/void callback audits are currently deferred by user direction.

## Queued merchant identity — native acceptance pending

BUG-005 uses the existing item-ID/link resolver before a queued purchase. The desktop
replay passes 660 checks and the full suite 86 scripts/727 syntax files; no native
client row advances. Follow [merchant identity native checks](VENDOR_PURCHASE_IDENTITY.md):
stable manual/automatic restock, naturally changed/missing listings before/after
index refresh, normal fresh-request recovery, quantities, money, tier/alternate-cost
behavior, close/reopen, input/combat/taint and matched screenshots/performance. No
native API replacement or forced live-data manipulation is part of the procedure.

## Finite merchant stock — native acceptance pending

BUG-006 caps zero availability and reserves finite submitted quantities on shared
merchant index entries. Desktop stock/identity replay passes 837 checks, with the
full 86-script/727-syntax suite passing. No native client row advances. Follow
[stock native checks](VENDOR_STOCK_BUDGET.md) for sold-out/limited/unlimited merchants,
partial funds and alternate costs, cross-pass/shared targets, replenishment/new
requests, real acceptance/error totals, screenshots/input/combat/taint and matched
startup/idle/purchase profiling. Reservations do not certify native acknowledgement.

## Vendor-open hitch — native attribution recorded; after acceptance pending

The user reports a spike on every Era vendor reopening. A clean four-reopen capture
now confirms a 333 ms maximum UI interval on 1.15.9.70576 with automation off and
profiling=1. [PERF-006](TIER_COUNT_WORK.md) records attribution and native getter
comparisons; whole-vendor after acceptance remains pending.
BUG-007/PERF-004 removes a desktop-reproduced redundant junk scan contributor. Seven
API fixtures pass 265 checks and the full suite 87 scripts/728 syntax files. This
advances no native client row. Original Wrath 3.3.5 is not covered by the modern
Wrath fixture. Follow [vendor-open native procedure](VENDOR_OPEN_WORK.md): Era first,
matched first/repeated opens without actions, recorded settings/addons and raw
frame-time evidence, cold data/protection/Useful controls, standalone/external
provider readiness, then each available client. Compare pixels/input/cadence and
profiling overhead. Do not deploy to another installation without authorization.

## Quick Join SetPoint cycle — native recheck pending

The user's stack names the social callback and a Channels frame on FluxCCPChatColumn;
no affected client/build was specified. BUG-008 reproduces and fixes that reversed
anchor dependency in production-backed Live/Forever Quick Join fixtures on both
sides. Existing five-branch column controls remain; the full 87-script/728-syntax
suite passes. No native row advances. Follow [chat native steps](CHAT_QUICKJOIN_ANCHOR.md)
for reload, native alerts, tab/side changes, Social/Channels visibility, Edit Mode,
combat/regen, matched screenshots/geometry, input/taint and profiling. Clients with
only FriendsMicroButton retain their separate path. Original Wrath is unverified.

## Repeated Era vendor spike — prior PERF-005 scope

User confirms every same-vendor reopening spikes. Prior junk/buyer/chat sources
matched the Era install before this batch; no sync was performed. Saved Config.wtf
has scriptProfile=1; runtime state was unobserved in that prior batch. [PERF-005](VENDOR_TIER_WORK.md)
reduces repeated usability work in legacy/modern API fixtures: 340 checks, five
matched pairs and full 88 scripts/729 syntax pass. No native row advances. Prioritize
matched repeated-open profiling on/off runs, retaining the original preference;
record actual build/profile/addons and raw hitch evidence. Check reference discovery,
levels/skills, cold rejected items, thresholds, ties, pixels/input/combat/taint.

## Era native count comparison — partial pass

Actual runtime 1.15.9.70576 / interface 11509, level 60 Mage, built-in inventory,
recorded addon list/hardware/settings. Five alternating background baseline/local
candidate pairs preserve all getter results and reduce measured CPU. [PERF-006
protocol and raw samples](TIER_COUNT_WORK.md). Personal-bank outputs are all zero;
positive bank and warband quantities are desktop-only. User's normal sync delivered
candidate source; original automation flags and profiler=1 restored. WoW stays in
the background without further foreground access.

Only Era's matrix row gains this partial native result. Full repeated-open after,
matched screenshots/input, cold work, unprofiled FPS, security/taint, external
providers and other clients remain pending. Original Wrath remains unverified.

## Retail native idle and resource audit — partial evidence

Retail is now observed running 12.1.5.70575, interface120105, project1, level81 Mage
in Stormwind. Five background profile1 idle captures and ten GC/frame censuses
record actual addons/settings/hardware. Frame/public-cache sizes stay stable while
requested diagnostics retain memory; [audit](RETAIL_PERFORMANCE_AUDIT.md) separates
that observation from a normal HUD leak claim. Source fixes reuse loot waiters and
release full capture snapshots. Original profiler=0 is restored after measurement;
no game activation or public/native API replacement. Complete foreground FPS,
visual/input/taint/secrets, combat/loot, long sessions, external providers and other
clients remain pending. This partial row does not certify all Retail features.

## Shared chat column follow-up

Retail BUG-011 native partial pass: Social gap8 UI units, untouched post-reload screenshot inspected before chat/tab input, and seven General/Global/Combat Log selections with identical visible coordinates. Profiler0 restored; temporary exports removed. [Evidence](CHAT_COLUMN_ALIGNMENT.md). Custom-tab desktop checks do not certify other native clients or combat/taint.

## Countdown native follow-up

PERF-009 Retail 12.1.5.70575 / interface 120105 / project 1: five alternating
real-widget pairs retain identical owned-widget geometry, alpha and hide/reuse,
with zero recorded errors. Median elapsed time per 2,000 updates is 33.371 ->
31.712 ms; one candidate pair is slower. Full-addon scene changes make its separate
before/after capture inconclusive. Profile 0 stays unchanged and diagnostics are
removed by normal reload. [Exact evidence and remaining steps](NAMEPLATE_COUNTDOWN_WORK.md).
Other clients have desktop controls only for this batch; actual plate-aura pixels,
secret values, combat/taint, foreground FPS and long-session acceptance remain pending.

## Action-bar/player-aura follow-up

PERF-010 runs sequentially on Retail12.1.5.70575/interface120105/project1 and
Era1.15.9.70576/interface11509/project2 (SoD realm). Requested characters verified.
Five alternating real57-button pairs per client reduce activation calls5800 ->100
per100 passes. Button shapes and native player-aura root anchors/scales/visibility
match; recorded errors0. Native highlight setting is inactive; enabled combat
painting and protected input still need real gameplay checks. Small short-idle
native aura CPU readings do not certify dense/restricted aura churn or leak-free
sessions. [Evidence](ACTION_AURA_WORK.md). Original profile0 Retail/1 Era restored;
Retail diagnostic root nil and Era prior report restored, deep-equal. Sessions
conflict on this account: both processes stay open but testing is sequential.

<!-- NPQ-FULL-CURRENT -->
Latest full checkout:263/265 standalone scripts PASS;932Lua syntax PASS.
Concurrent unit-frame changes produced two mock failures: `public_geometry_writers.lua`
needs `DeferProtected` in its test double; `raid_party_frames.lua` needs
`SetClipsChildren` in its test double. Both reproduce separately. This quest task
did not edit those owners or tests. Earlier265/265 captures retain their exact
source scope externally. Quest checks311PASS, seven harmful controls rejected;
full current source identities/failures are retained in the quest validation JSON.
<!-- /NPQ-FULL-CURRENT -->

<!-- STRIP-FLYOUT-ARROW-R150-20261119 -->
RefreshAll anchor tests exercise Retail, Forever and Classic models. The legacy model still checks secure wrapper absence. Native cursor latency, artwork and taint remain pending.
[Matched validation](validation/strip-flyout-arrow-2026-11-19.json).
<!-- /STRIP-FLYOUT-ARROW-R150-20261119 -->

<!-- STRIP-HOVER-OCCUPANCY-R151-20261119 -->
The matched held-action fixture executes production secure bodies using pinned Forever Lua helpers and modeled button transport. Protected native dispatch, taint and latency are pending.
[Matched validation](validation/strip-hover-occupancy-2026-11-19.json).
<!-- /STRIP-HOVER-OCCUPANCY-R151-20261119 -->

<!-- STRIP-PLAN-COVERAGE-R152-20261119 -->
Nine matched strip-width transitions in both border styles compare the production planner and cached replay. Native cursor latency, pixel parity and taint remain pending.
[Matched validation](validation/strip-plan-coverage-2026-11-19.json).
<!-- /STRIP-PLAN-COVERAGE-R152-20261119 -->

<!-- RAID-CHROME-LOOKUP-R153-20261120 -->
The compact raid native selection hook replays grouped cells, pooled party frames and unrelated or addon-owned frames in five client models. Native latency, rendering and taint remain pending.
[Matched validation](validation/raid-chrome-lookup-2026-11-20.json).
<!-- /RAID-CHROME-LOOKUP-R153-20261120 -->

<!-- RAID-STABLE-PAINT-R154-20261120 -->
Production compact roster repaint uses the live widget getter contract in five client models. Native latency, rendering and taint remain pending.
[Matched validation](validation/raid-stable-paint-2026-11-20.json).
<!-- /RAID-STABLE-PAINT-R154-20261120 -->

<!-- BORDER-LISTENER-INDEX-R155-20261120 -->
Regional repaint tests cover both border styles, retained listeners, current owner changes and fallback publication. Native latency, rendering and taint remain pending.
[Matched validation](validation/border-listener-index-2026-11-20.json).
<!-- /BORDER-LISTENER-INDEX-R155-20261120 -->

<!-- BORDER-FRAGMENT-MEMBERSHIP-R156-20261120 -->
Regional redraw fixtures cover both border types, retained source pool membership, live paint and warm rollback. Rapid crossings, roster transitions, native rendering and taint remain pending.
[Matched validation](validation/border-fragment-membership-2026-11-20.json).
<!-- /BORDER-FRAGMENT-MEMBERSHIP-R156-20261120 -->

<!-- PET-STRIP-PACKING-R157-20261120 -->
Desktop fixtures cover post-DF and Classic pet packing, live anchor and clipping drift, protected-read failure, actual squeeze change and combat deferral. Native timing, pixels and taint remain pending.
[Matched validation](validation/pet-strip-packing-2026-11-20.json).
<!-- /PET-STRIP-PACKING-R157-20261120 -->

<!-- STANCE-STRIP-LAYOUT-R158-20261120 -->
Stance strip fixtures cover both dock modes, live size and clip drift, updated pet height and window owner, private reads, dirty form changes and combat deferral. Native timing, pixels and taint remain pending.
[Matched validation](validation/stance-strip-layout-2026-11-20.json).
<!-- /STANCE-STRIP-LAYOUT-R158-20261120 -->

<!-- NATIVE-GROUP-HIDE-R159-20261120 -->
Native group suppression fixtures cover protected reads, shared input owners, dynamic children, late combat-created ghost indicators, and Edit Mode deferral. Native timing, seams and taint remain pending.
[Matched validation](validation/native-group-hide-2026-11-20.json).
<!-- /NATIVE-GROUP-HIDE-R159-20261120 -->

<!-- RAID-ACTIVE-HEADERS-R160-20261120 -->
Prepared roster fixtures cover a hidden tank/assist pool, unscoped party and solo states, shown alpha-zero headers, unavailable visibility, explicit configuration and native unit reveal sequencing. Native timing and taint remain pending.
[Matched validation](validation/raid-active-headers-2026-11-20.json).
<!-- /RAID-ACTIVE-HEADERS-R160-20261120 -->

<!-- STRIP-BADGE-PLACEMENT-R161-20261120 -->
Action-strip corner-badge fixtures cover exact draw placement, inactive page stacks, squeeze, frame-level drift, glow clipping and unreadable geometry. The modeled combat pass defers protected layout. Native timing and taint remain pending.
[Matched validation](validation/strip-badge-placement-2026-11-20.json).
<!-- /STRIP-BADGE-PLACEMENT-R161-20261120 -->

<!-- BORDER-RECENT-LAYOUTS-R162-20261120 -->
Desktop checks cover four recurring widths with the side grids, Info and Trinket borders, three recurring roster layouts, a first-use footprint, eviction, large-plan bounds, native material changes and combat deferral. Actual client timing, pixels and taint remain pending.
[Matched validation](validation/border-recent-layouts-2026-11-20.json).
<!-- /BORDER-RECENT-LAYOUTS-R162-20261120 -->

<!-- BORDER-SIMPLE-INTERVALS-R163-20261120 -->
Both border styles pass desktop comparisons for cold strip and roster layouts, chained visibility backups, duplicate same-side caps, opposing sides and operation budgets. Actual client timing, pixels and taint remain pending.
[Matched validation](validation/border-simple-intervals-2026-11-20.json).
<!-- /BORDER-SIMPLE-INTERVALS-R163-20261120 -->

<!-- BORDER-FALLBACK-CLIP-R164-20261120 -->
Both border styles pass desktop checks for disjoint and intersecting fallback triangles, keeper removal, changed geometry, private paint and rollback. Actual client timing, pixels and taint remain pending.
[Matched validation](validation/border-fallback-clip-2026-11-20.json).
<!-- /BORDER-FALLBACK-CLIP-R164-20261120 -->

<!-- STRIP-SHELL-ANCHORS-R165-20261120 -->
Three matched desktop runs preserve layout and action routes during hover crossovers and slot changes, with the mini row above and below. Live action-strip timing, seam pixels, action input and combat taint remain pending. Party and raid transition timing also remains open.
[Matched validation](validation/strip-shell-anchors-2026-11-20.json).
<!-- /STRIP-SHELL-ANCHORS-R165-20261120 -->

<!-- BORDER-TILE-FIELDS-R166-20261120 -->
Both border styles match the archived regional tile output during desktop tests. Live cursor crossing and slot resize cost, group join and leave cost, seam pixels and combat taint remain pending.
[Matched validation](validation/border-tile-fields-2026-11-20.json).
<!-- /BORDER-TILE-FIELDS-R166-20261120 -->

<!-- RAID-AURA-RETIREMENT-R167-20261120 -->
Matched native aura owner models cover five and forty units on Retail and Forever. Classic client models retain readable fallback coverage. Live party and raid transition timing, native aura pixels and combat taint remain pending.
[Matched validation](validation/raid-aura-owner-retirement-2026-11-20.json).
<!-- /RAID-AURA-RETIREMENT-R167-20261120 -->

<!-- STRIP-GRID-ROOT-ANCHORS-R168-20261120 -->
The grid root comparison covers both the modern and Classic-shaped desktop models, including alternate gamepad anchoring and guarded repair. Live held-action crossing timing, attached seams, combat input and taint remain pending.
[Matched validation](validation/strip-grid-root-anchors-2026-11-20.json).
<!-- /STRIP-GRID-ROOT-ANCHORS-R168-20261120 -->

<!-- RAID-UNIT-EVENT-RETIREMENT-R169-20261120 -->
Group transition event reset and repaint signatures match in five desktop client shapes with both hide and unbind orders. Native party and raid transition timing, actual event delivery, combat taint and action-strip hitch confirmation remain pending.
[Matched validation](validation/raid-unit-event-retirement-2026-11-20.json).
<!-- /RAID-UNIT-EVENT-RETIREMENT-R169-20261120 -->

<!-- BORDER-NEIGHBOR-RUNS-R170-20261120 -->
Both modeled border styles keep the same neighboring sources, routing order and sampled joins. Native held-action crossing and roster transition timing, seam pixels and combat taint remain pending.
[Matched validation](validation/border-neighbor-runs-2026-11-20.json).
<!-- /BORDER-NEIGHBOR-RUNS-R170-20261120 -->

<!-- STRIP-EMPTY-PROMOTION-R171-20261120 -->
Four modeled action strip layouts keep the same secure mapping decisions, face placement and border commit counts. Native held-action crossing and rapid drop timing, seam pixels and combat taint remain pending.
[Matched validation](validation/strip-empty-promotion-2026-11-20.json).
<!-- /STRIP-EMPTY-PROMOTION-R171-20261120 -->

<!-- FLYOUT-ARROW-LAYERS-R172-20261120 -->
All three target model shapes retain the same parent, layer, scale and protected-write behavior on shared flyout refresh. Native held-action crossing timing, arrow and border pixels, and combat taint remain pending.
[Matched validation](validation/flyout-arrow-layers-2026-11-20.json).
<!-- /FLYOUT-ARROW-LAYERS-R172-20261120 -->

<!-- BORDER-FALLBACK-PARTITION-R173-20261120 -->
Both styles retain rectangles, visibility owners, budgets and sampled output in the desktop replay. Native strip/roster hitch timing, seam pixels, and combat taint remain pending.
[Matched validation](validation/border-fallback-partition-2026-11-20.json).
<!-- /BORDER-FALLBACK-PARTITION-R173-20261120 -->

<!-- BORDER-LISTENER-RUNS-R174-20261120 -->
Both modeled border styles retain watcher ownership, field paint order and sampled output. Native hold/drag and party/raid timing, seam pixels, and combat taint remain pending.
[Matched validation](validation/border-fallback-listeners-2026-11-20.json).
<!-- /BORDER-LISTENER-RUNS-R174-20261120 -->

<!-- BORDER-LISTENER-LINKS-R175-20261120 -->
Both border styles retain opacity, listener order and sampled seams through the displayed old and new layouts. Native action drag and roster hitch timing, border pixels and combat taint remain pending.
[Matched validation](validation/border-listener-links-2026-11-20.json).
<!-- /BORDER-LISTENER-LINKS-R175-20261120 -->

<!-- BORDER-FIELD-ANCHORS-R176-20261120 -->
The desktop replay preserves field placement and both styles through strip and roster changes. The verified same-anchor pattern is present in the local Retail, Forever and Classic scroll UI snapshots. Live strip drag/drop and party/raid latency, pixels and combat taint remain pending.
[Matched validation](validation/border-field-anchors-2026-11-20.json).
<!-- /BORDER-FIELD-ANCHORS-R176-20261120 -->

<!-- BORDER-FIELD-PAINT-R177-20261120 -->
Both style replays match the archived renderer in field work and sampled seams after the Lua paint cache change. Native action-strip latency and appearance, party/raid join and leave latency, and combat taint remain open.
[Matched validation](validation/border-field-paint-2026-11-20.json).
<!-- /BORDER-FIELD-PAINT-R177-20261120 -->

<!-- PARTY-ROSTER-DISPATCH-20261120 -->
Desktop roster replay covers compact party, target identity reset, hidden slots, queued and standalone indicator paints, and combat ownership. Native party and raid join/leave latency, action-strip reflow and combat taint remain pending.
[Matched validation](validation/party-roster-dispatch-2026-11-20.json).
<!-- /PARTY-ROSTER-DISPATCH-20261120 -->

<!-- BORDER-ROSTER-BOUNDS-R178-20261120 -->
Desktop border replay covers both styles, texture counts, sampled seams, independent paint, failed attachment cleanup and native-point restoration. Native join and leave latency, action-strip hitches, pixel parity and combat taint remain pending.
[Matched validation](validation/border-roster-bounds-2026-11-20.json).
<!-- /BORDER-ROSTER-BOUNDS-R178-20261120 -->

<!-- BORDER-SOURCE-ALPHA-R179-20261120 -->
Desktop strip and roster replays preserve source opacity, alpha reentry, sampled seams and artwork. Live action-strip and group-change latency, pixel parity and combat taint remain pending.
[Matched validation](validation/border-source-alpha-2026-11-20.json).
<!-- /BORDER-SOURCE-ALPHA-R179-20261120 -->

<!-- STRIP-EXPANDED-COLUMNS-20261120 -->
Desktop sparse, dense and paged strip fixtures match protected update requests and face placement during hover changes. Live action-strip and group-change latency, pixel parity and combat taint remain pending.
[Matched validation](validation/strip-expanded-columns-2026-11-20.json).
<!-- /STRIP-EXPANDED-COLUMNS-20261120 -->

<!-- BORDER-OBSERVED-SOURCES-R180-20261120 -->
Modeled strip and roster changes preserve source geometry and paint, panel alignment, late setter rejection, and client lockdown paths. Live strip and roster latency, pixel parity and combat taint remain pending.
[Matched validation](validation/border-observed-sources-2026-11-20.json).
<!-- /BORDER-OBSERVED-SOURCES-R180-20261120 -->

<!-- BORDER-PANEL-ALIGNMENT-POSES-R181-20261120 -->
Modeled border alignment reuses exact prior layouts at two scales with matching backdrop boundaries, T/X contacts, sampled paint, partial write recovery and combat deferral. Native held-action and roster hitch timing, pixel parity and combat taint remain pending.
[Matched validation](validation/border-panel-alignment-poses-2026-11-20.json).
<!-- /BORDER-PANEL-ALIGNMENT-POSES-R181-20261120 -->

<!-- GROUP-NAMEPLATE-ANCHORS-20261120 -->
Five desktop client models cover coalesced group refresh and follow-up, hidden or replaced anchors, native getter denial and secret offsets. Native group join and leave latency, nameplate rendering and combat taint remain pending.
[Matched validation](validation/group-nameplate-anchors-2026-11-20.json).
<!-- /GROUP-NAMEPLATE-ANCHORS-20261120 -->

<!-- GROUP-NAMEPLATE-LEVELS-20261120 -->
Modeled group and steady updates verify exact overlay layering, reparenting, mismatch, getter denial and private-value handling. Live group join and leave latency, nameplate rendering, combat taint and held-action border timing remain pending.
[Matched validation](validation/group-nameplate-levels-2026-11-20.json).
<!-- /GROUP-NAMEPLATE-LEVELS-20261120 -->

<!-- STRIP-INFO-ANCHORS-20261120 -->
Desktop action-strip settlement covers all Info placements, changing owners and widths, point drift, private or denied points, and layout guards. Native rapid crossings and drops, actual side-seam pixels, in-combat restrictions and group hitch timing remain pending.
[Matched validation](validation/strip-info-anchors-2026-11-20.json).
<!-- /STRIP-INFO-ANCHORS-20261120 -->

<!-- STRIP-SLOT-SETTLE-20261120 -->
Modeled slot grow and shrink preserve the visible art and routed actions across three client profiles. Unit anchor settlement and option coalescing pass. Native rapid pickup/drop and held-action crossings, side seam pixels, combat taint and party/raid hitch timing remain pending.
[Matched validation](validation/strip-slot-settle-2026-11-20.json).
<!-- /STRIP-SLOT-SETTLE-20261120 -->

<!-- BORDER-CURRENT-DRAW-INPUTS-R182-20261120 -->
Desktop replays cover warmed strip crossings, roster moves, private/native paint and changed source material or layer. Native first and repeated drag or drop, cursor crossings, party/raid transitions, side seam appearance and combat taint remain pending.
[Matched validation](validation/border-current-draw-inputs-2026-11-20.json).
<!-- /BORDER-CURRENT-DRAW-INPUTS-R182-20261120 -->

<!-- ROSTER-AURA-PAINT-20261120 -->
Desktop aura reflows cover five client profiles, readable texture and text drift, missing and restricted reads, private descendants, removal, cooldown timing and lockout. Native party and raid join/leave frame time, combat taint and rapid action-strip transitions remain pending.
[Matched validation](validation/roster-aura-paint-2026-11-20.json).
<!-- /ROSTER-AURA-PAINT-20261120 -->

<!-- STRIP-EVENT-OWNERSHIP-R183-20261120 -->
Slot notification, existing action-route and drawn-layer desktop checks pass. Native action-strip crossings, side seams and rapid slot edits still need verification. Party and raid join/leave, embedded minimap and combat taint remain pending for the wider goal.
[Matched validation](validation/strip-event-ownership-2026-11-20.json).
<!-- /STRIP-EVENT-OWNERSHIP-R183-20261120 -->

<!-- STRIP-GRID-WIDTH-20261120 -->
Desktop grid tests cover width changes, full repair on changed anchors or owner, unknown size being replaced in the same pass, existing binding behavior and lockdown deferral. Live action-strip latency, connected side-panel pixels and protected input remain pending. Party/raid join and leave, embedded minimap and combat timing remain open in the broader task.
[Matched validation](validation/strip-grid-width-2026-11-20.json).
<!-- /STRIP-GRID-WIDTH-20261120 -->

<!-- BORDER-FIELD-RETIREMENT-R184-20261120 -->
Regional retirement, source paint, held-action transitions, reused roster layouts, combat deferral and full cleanup passed desktop checks. Live cursor crossings, party/raid join and leave, side seam appearance and combat taint remain pending. Embedded minimap toggles remain open for the broader goal.
[Matched validation](validation/border-field-retirement-2026-11-20.json).
<!-- /BORDER-FIELD-RETIREMENT-R184-20261120 -->

<!-- PARTY-TARGET-TRAIL-20261120 -->
Matched desktop party-target tests cover an active trail, a shield, changed health, a replacement, missing or restricted identity, private health and a reset during a write. Actual party and raid join and leave timing, protected state behavior and the in-game damage trail remain pending. Native held-action strip and border acceptance remain open.
[Matched validation](validation/party-target-trail-2026-11-20.json).
<!-- /PARTY-TARGET-TRAIL-20261120 -->

<!-- STRIP-PARKED-CHROME-20261120 -->
The three desktop client-style replays preserve visible art, geometry, action IDs and per-crossing border commits. Real drops, width changes, substitute/private artwork, gamepad sensing and lockdown are covered by the focused replay suite. Live rapid cursor crossings and drops, including changing side-panel contacts, remain pending for frame time, seams and combat taint. Party and raid join and leave, embedded minimap toggles and combat exit remain open for the broader goal.
[Matched validation](validation/strip-parked-chrome-2026-11-20.json).
<!-- /STRIP-PARKED-CHROME-20261120 -->

<!-- BORDER-OBSERVER-SCRATCH-R185-20261120 -->
Desktop comparison covers held-action crossings, roster reflows, multiple independent anchor changes, restricted-parent recovery, loops and fallback ceilings. Native held-action and rapid-drop latency, real strip-to-panel seams, and party and raid join/leave timing remain pending. Embedded minimap toggles and combat-exit timing and taint also remain open.
[Matched validation](validation/border-observer-scratch-2026-11-20.json).
<!-- /BORDER-OBSERVER-SCRATCH-R185-20261120 -->

<!-- PARTY-STATUS-OWNER-20261120 -->
Desktop replays cover changing party counts, leadership, shared role layout, native anchor repair, public and private name widths, multiple NPC labels, and the existing five client-style party and raid control paths. Live party and raid membership frame times, combat behavior and exact indicator rendering remain unverified. Held-action crossings, rapid drops, embedded minimap toggles and combat-exit timing remain open for the wider goal.
[Matched validation](validation/party-status-owner-2026-11-20.json).
<!-- /PARTY-STATUS-OWNER-20261120 -->

<!-- STRIP-GRID-RING-20261120 -->
The width-change replay exercises actual side-grid layout, art and cooldown writers, direct utility calls and replacement methods. Separate Trinket Menu, input and regional join regressions pass. Live held-action and rapid-drop timing, actual side seams and combat taint remain open. Party and raid membership timing, embedded minimap transitions and combat exit remain open for the wider goal.
[Matched validation](validation/strip-grid-ring-2026-11-20.json).
<!-- /STRIP-GRID-RING-20261120 -->

<!-- STRIP-ARROW-OWNER-20261120 -->
The crossing replay includes modern and legacy trinket widgets, all 20 attached arrows, unreadable anchors and distinct refresh callbacks. Live held-action and rapid-drop timing, actual side seams and combat taint remain open. Party and raid membership timing, embedded minimap transitions and combat exit remain open for the wider goal.
[Matched validation](validation/strip-arrow-owner-2026-11-20.json).
<!-- /STRIP-ARROW-OWNER-20261120 -->

<!-- STRIP-INFO-MEASURE-20261120 -->
Info text coverage includes changed hybrid labels, tight fit thresholds, stable and replaced owners, and all four Info placements. Live held-action and rapid-drop frame time, actual seams and combat taint remain open. The broader goal also keeps group transitions, embedded minimap toggles and combat exits open.
[Matched validation](validation/strip-info-measure-2026-11-20.json).
<!-- /STRIP-INFO-MEASURE-20261120 -->

<!-- BORDER-PANEL-INPUTS-R186-20261120 -->
R186 regression coverage includes both border types, fractional mixed scales, first and repeated widths, disappearing and returning panel owners, deferred combat writes and recovery from interrupted alignment. Live held-action crossings, rapid drops, group join and leave, seams and combat taint remain pending. Unchanged-panel scans in the desktop model establish the cost of that phase during unrelated HUD or unit reflows.
[Matched validation](validation/border-panel-inputs-2026-11-20.json).
<!-- /BORDER-PANEL-INPUTS-R186-20261120 -->

<!-- ROSTER-HOVER-DRIVER-20261120 -->
The group binding fixture covers Retail, Forever, Classic progression, Era and Anniversary models, including native-style wheel bindings with nil results and parking a formerly active spell-hover driver. Current live invite, leave, raid conversion timing and combat taint remain pending. Full action-strip, border seams, minimap and combat exit acceptance remain part of the active roadmap.
[Matched validation](validation/roster-hover-driver-2026-11-20.json).
<!-- /ROSTER-HOVER-DRIVER-20261120 -->

<!-- NAMEPLATE-RANK-ROSTER-20261120 -->
The nameplate replays cover three client models and fixed group sizes across join and leave. The direct rank checks cover public, inaccessible, missing and mixed identities, alias and threat ties, and changed providers. Live party and raid join or leave timing and native secret-value and combat checks remain pending. Action strip, border seams, embedded minimap and combat exit acceptance remain open for the wider goal.
[Matched validation](validation/nameplate-rank-roster-2026-11-20.json).
<!-- /NAMEPLATE-RANK-ROSTER-20261120 -->

<!-- BORDER-CELL-BUDGET-R187-20261120 -->
R187 desktop coverage includes both border styles, capacity-limit admission, cold reset, retained source ownership and replayed strip transitions. Native action-strip latency, party and raid transitions, seam pixels and combat taint remain pending. The desktop replay counts capacity work and does not measure client frame time.
[Matched validation](validation/border-cell-budget-2026-11-20.json).
<!-- /BORDER-CELL-BUDGET-R187-20261120 -->

<!-- HUD-ACCEPTANCE-R187-20261120 -->
R187 is the HUD acceptance candidate. The combined desktop pass covers action-strip crossings and rapid drops, party and raid conversion, local border publication, minimap side buttons and combat regressions. All 48 selected scripts and 1252 Lua syntax checks passed. Current native acceptance is pending. The installed border file matches in all five local client trees. Loaded client identity, frame times, pixels, input and taint require live evidence.
[Matched validation](validation/hud-acceptance-r187-2026-11-20.json).
<!-- /HUD-ACCEPTANCE-R187-20261120 -->

## Mana Gem sequence

20 November reset follow-up. All 155 sequence checks and 29 focused scripts
pass across the existing models. The replay holds a stale combat cursor through
the addon’s combat-exit handler and verifies the best carried face immediately.
Replenishing an identical layout takes zero secure use-action writes. Native
verification remains pending after reload, including gem acquisition in and
out of combat, both click paths, and the next fight's initial gem.

20 November. The dedicated test passes 165 checks across Retail, Forever,
Classic progression, Era and Anniversary models. The 28 focused scripts
pass. The live Forever window was verified as `1.60.1.70959` on disk and left
in the background. Check actual successful use, shared cooldown, key and
mouse input, next-gem icon/count and blocked actions on a stocked mage.

Forever source `1.60.1.70938` shows item use on the current step, advancement
on matching successful casts, and a combat-exit reset. The client source tip
could not be resolved during this check. [Pinned Blizzard sequence manager](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_ChatFrameBase/Shared/CastSequenceManager.lua)
· [Desktop regression](../tests/mana_gem_sequence.lua).

## Find offer after browsing

22 November. The desktop owner tests run an explicit Find offer click after a foreign browse query. Passive preparation yields and the native buyout dialog still blocks the explicit action. Once the dialog closes, the click starts exactly one read-only query and exposes an eligible offer. Legacy and modern fixtures verify zero purchase calls. The player reloaded Forever and confirmed Find offer displayed Buy and a price. This live check stopped at the displayed offer.

## Vendor bundle auction choice

22 November. Companion auction requests can carry a minimum useful quantity. The legacy and modern owner fixtures skip smaller single listings, and the modern commodity path verifies an affordable quantity and validates it again on the real purchase path. The companion uses this minimum when replacing a whole vendor pack. Native confirmation is pending.

## Craft queue junk protection

22 November. Desktop fixtures cover saved manual and gray junk, uncached materials, Baganator classification, direct mark attempts and a stale sell or destroy candidate. The merchant gate skips accepted inputs. Releasing a material restores its earlier classification without a bag update. Equivalent coverage notifications do not repaint the bag. Native confirmation remains pending.

## Modern auction item-key handoff

22 November. With a cold modern item key the accepted auction query waits for item data. It retries a premature empty response once and prepares the exact offer when matching results arrive. The desktop fixtures cover commodities and individual item listings. Native testing remains pending.
