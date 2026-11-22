# Decisions

22 November. Apply life and taxi restrictions in the shared Extra Button
usability painter. Keep Forever's confirmed mount data through death and
release. Life events hide the wisp and refresh the journal when the player
returns alive. [Mount evidence](CLIENT_VALIDATION.md#forever-mount-collection).

22 November. Give fixed action columns 13–19 sole ownership of their
main slots. While native page 2 is active, keep base slots 1–7 and use
20–24 in columns 8–12. Match this rule in the secure handler and Lua
model so both execute and display the same action without relocating
anything in Blizzard's action storage.
[Behavior](11-action-bars.md#pages-modifiers-and-promotion).

22 November. Hold `AREA_POIS_UPDATED` on the original Battlefield Map
after Flux has hosted it while combat restrictions apply. Retain
Blizzard's provider counts and restore the frame subscription on release.
Replay a missed update once for the visible same frame and discard
held work on hide.
[Validation](CLIENT_VALIDATION.md#battlefield-map-poi-mouse-actions-in-combat).

22 November. Leave damage meter type, additional window creation and
session selection to Blizzard’s actual controls. Keep Flux’s requested
layout and setup feedback. Defer Flux-initiated meter reveals and
geometry while combat restrictions apply. For rounded border junctions,
use triangles with an arm index for fallback ownership and retain cap
fill in the base mesh.
[Validation](CLIENT_VALIDATION.md#damage-meter-taint-and-rounded-border-junctions).

22 November. Use a default-off FluxUI nameplate preference for harmful
aura ownership. Apply Blizzard's player filter to the secure debuff and
crowd-control rows. For stock slots, require a public ownership match,
retain native order and restore alpha and hover when the slot is released.
[Behavior](19-nameplates.md#nameplate-debuff-ownership).

22 November. Display the ready craft reminder inside the active
profession window when it is open. Keep its item icon, count, caption
and existing player click behavior. Support the visible native page
with FluxUI alone and the active Flowcraft view with FluxLogistics.
Return the reminder to its normal HUD placement when the profession
window closes. Keep the native **Create** action for a prepared batch
and the Flowcraft **Process** path for its existing queue selection.
[Validation](CLIENT_VALIDATION.md#craft-reminder-in-the-profession-window).

22 November. Use the existing inventory-settled wake-up for a companion
craft action that is temporarily disabled during a bag update. Register
one callback while that action is blocked and clear it when the inventory
settles. Resolve the next action through the same accepted queue task and
live carried counts. Use a coalesced native terminal-event recheck while
readiness is blocked by the cast. A missing native form can be prepared
again for the exact queued recipe. The actual craft still uses a player
press.
[Validation](CLIENT_VALIDATION.md#fluxui-continue-craft-button).

22 November. Aggregate shared material requirements by the current
source and physical item, including across different output recipes.
Use the accepted terms of each order and credit its exact share of the
result. Revalidate the live group before an auction, vendor or bank action.
Apply a partial bank receipt in accepted order.
[Validation](CLIENT_VALIDATION.md#shared-queued-craft-materials).

22 November. Publish accepted Auction Restock vendor materials as
temporary targets in Vendor Restock. Use the merchant's existing buyer
for the eligible shortage, including when FluxLogistics is loaded.
The live merchant price, stock and receipt handling govern the buy. A
manual pass starts with the accepted requirements visible at the press.
Independent companion jobs can buy in that pass. A later material for
the same job waits for its previous carried receipt.
[Validation](CLIENT_VALIDATION.md#craft-materials-in-vendor-restock).

22 November. Use the matching player's native cast identity and timing
to track the accepted craft. Use confirmed receipts for its progress
and actual stop or failure events for interruption. Display the cast's
native duration when the spell, source and cast identity match. A
terminal event can leave the order waiting for a delayed receipt. A
prepared **Create** action follows live selection and cancellation
instead of an elapsed deadline.
[Validation](CLIENT_VALIDATION.md#flowcraft-cast-lifecycle).

22 November. Use the selected queue row to target **Process**. Show the
order's remaining output beside its current craft step, and display the
current step in the native view for that order. Update the displayed
count from matching progress during an active batch. Record settled
progress from verified receipts and resume the eligible remainder on an
explicit press. Treat overlapping result signals as one receipt. An
unrelated order in Review can wait while a selected craft proceeds.
An in-flight craft or an uncertain shared output still blocks dispatch.
At watchdog expiry, honor the expected native cast's reported end time
and allow two seconds for its receipt. Require the exact spell and the
cast GUID where available. Keep the timeout for a missing receipt or
an unrelated cast.
[Validation](CLIENT_VALIDATION.md#flowcraft-queue-progress-and-process).

22 November. Update Flowcraft's recipe identity and clear the previous
draft on the selection event. Coalesce repeated events and native echoes
through the existing refresh queue. Evaluate the current selection on an
explicit **Queue** press if the deferred refresh has yet to run. Use one
graph layout for inspection and rendering.
[Validation](CLIENT_VALIDATION.md#flowcraft-recipe-selection).

22 November. Persist verified progress for an active craft so the same
order can reconcile its remaining work after reload. An older uncertain
order with an incomplete craft record can recover verified carried order
fulfillment on an explicit **Process** or **Resume** action. Keep that
fulfillment distinct from a native craft receipt. Bind the Restock
reminder to the displayed order and task and recheck the selection on
press. Prepare the exact remainder on that press when ready. Blizzard's
**Create** submits the remainder of an older unproved Forever attempt.
[Validation](CLIENT_VALIDATION.md#flowcraft-partial-craft-after-reload).

22 November. Publish accepted companion vendor totals to the existing
Restock reminder, with names and quantities for a one- or two-material
stage and item details on each icon. Recheck the displayed vendor stage
before acting. Combine compatible whole-bundle shares for an eligible
merchant offer. A manual press buys one material type. The automatic
worker can continue when the carried receipt settles. An uncertain
same-item order blocks another grouped purchase and its reminder.
[Validation](CLIENT_VALIDATION.md#grouped-vendor-materials-and-restock-reminder).

22 November. Group active Flowcraft orders only when every member
matches the existing queue compatibility rules. Show the summed remaining
output and retain each accepted job and receipt. Keep paused and review
orders on their own rows. Use the detail menu to switch or cancel an
exact member. The grouped row's remove control cancels eligible members
as one queue update. Share a qualified material offer only for the exact
current group and preserve each member's limits and receipts. A smaller
listing leaves the remaining demand for a fresh press.
[Validation](CLIENT_VALIDATION.md#grouped-flowcraft-orders).

22 November. Publish **Open profession** for a ready craft after the
purchase, collection and withdrawal steps. Require companion external
inputs in bags for Restock and multi-step orders. Read Shopping mail
counts from the selected inventory provider's physical observations.
Show warm Syndicator counts as pending until the first fresh replacement.
Require qualified inbox evidence for spending and retain native attachment
checks for collection. Use a single-line
icon layout with an adaptive shelf and put the same verified next
craft at the bottom of Flowcraft and in the native profession view.
[Validation](CLIENT_VALIDATION.md#acquisition-first-restock-and-flowcraft).

22 November. Apply a confirmed sale to the current character's built-in auction
cache even with the Auction House closed. Use exact IDs when available. Legacy
clients remove a unique known-name match and settle ambiguous sales from the
next owner list. Keep saved rows, counts and locations in the same generation.
[Contract](BUILTIN_AUCTION_PUBLICATION.md#sold-listings-with-the-auction-house-closed).

22 November. A companion that advertises a tracked queued profession switch receives the reminder click through its verified opener. The exact painted action includes the switch mode. Standalone and older owner actions retain the secure profession spell click.

22 November. Keep the exact queue job, task, quantity and direct-action mode together in a companion HUD press. The published mode determines the action caption. If its mode or batch changes before the press, require the refreshed action. Ordinary owner recipes retain their current native handoff.

22 November. Keep Blizzard responsible for the actual **Create** action.
After native submission, verify exact carried output and retain queue
ownership while the native batch is running. Use the bounded check to
settle a matching result when the normal event is missing. Make the
prepared HUD caption passive and show the compact workbench beside the
native craft panel.
Replan an eligible unconfirmed prerequisite only from fresh carried
inventory. Link the replacement to the previous job and retain the
previous attempt and settled purchase history.
[Validation](CLIENT_VALIDATION.md#live-restock-craft-receipts).

22 November. Keep a prepared Blizzard quantity only for the same FluxUI
job, task and visible recipe page. Restore a stock reset after carried
inventory settles. Release preparation on the player's quantity edit or
native **Create** and wait for active recasts to finish. Raise the HUD
eight frame levels above the relevant visible surface, including nested
Flowchart cards.
Let general companion Process choose a ready step in the active job.
Keep specific Flowchart actions scoped to their selected step. Retain
early native craft events only for the same exact accepted Create call.
[Validation](CLIENT_VALIDATION.md#restock-native-quantity-after-stock-refresh).

22 November. Draw the Restock reminder just above the highest visible profession surface. Restore its normal HUD layer when professions close. Keep the reminder position and unchanged-state paint behavior.

22 November. Set the enabled native quantity only on the exact visible
recipe. Cap it at the current Restock need, the native craftable count
and any single-craft restriction. Delayed work belongs to the same job,
task and native page. Coalesce refreshes from the recipe response, list
update, or inventory settlement while that task is pending. The ordinary
owner yields when the companion takes over the native craft. Workbench
and Flowchart prepare the same accepted task. Use the beside-window dock
when it fits and a **Workbench** return from the native pane otherwise.
The player starts the batch through **Create**.
[Validation](CLIENT_VALIDATION.md#bounded-native-restock-craft-batches).

22 November. The Forever Restock reminder opens the exact validated
recipe and directs the player to Blizzard's **Create** control. Observe
bag output for ordinary FluxUI work and keep companion task validation in
its queue. Other clients use their existing craft dispatchers. Place the
reminder 12 UI units farther right and 10 farther down on both anchors
and put it above the tradeskill window.
[Validation](CLIENT_VALIDATION.md#restock-handoff-to-native-create).

22 November. Reuse the three authorized FlareUI aura artwork files with their
notice. Keep the stock helpful aura selector. Enable motion and disable clicks
on secure AuraButtons. Use a click-through spell tooltip only on Forever's
stock icon path because that template lacks a native hover script.

22 November. An accepted modern auction quote requires loaded item-key data and a matching result. A premature empty result gets one read-only retry.

22 November. The earlier HUD revision introduced a separate profession
action. The current workflow publishes it after material acquisition.
A fresh craft press retains the exact recipe, output, and ingredient
checks. On Forever, only the first HUD
item can carry the optional secure click for the matching player spell.
Its combat state driver retires the secure hit region. Use one bounded
mail worker and the saved default-on Auto Collect option for both owners.
Companion collection requires an approved incoming amount and a buyer
invoice. Center each private ring on its current icon and stop fading
fallbacks before a slot is resized or reused.
[Validation](CLIENT_VALIDATION.md#restock-profession-action-and-mail-auto-collect).

22 November. Use Blizzard's secure `AuraContainer` on Retail and Forever
for the approved harmful aura row replacement. Keep its scope to Debuff
and Crowd Control. Lease the stock lane's local alpha after preparing the
engine row and restore it on release. The Classic clients keep the readable
overlay. Secure Crowd Control selection follows the category filter.

22 November. Treat accepted craft material IDs as temporary protection ahead of saved junk marks. The effective mark can return when the final consumer releases the item. Queue-triggered refreshes occur only when the protected set changes.

22 November. Require a visible Recipes context before treating a modern
profession as open, and use the exact saved recipe to recover the base
skill line when needed. Prefer the matching native Book tab or supported
bootstrap path. Require a positive engine acknowledgement for a cold
open. Keep qualified carried-material actions available with the mailbox
open and block an attempted open or craft while the profession is changing.
The companion rechecks readiness after opening and keeps the craft on a
separate press.
[Validation](CLIENT_VALIDATION.md#restock-craft-reminder-opens-professions).

22 November. FluxLogistics calculates the usable shortage and the vendor bundle comparison. FluxUI validates the minimum, exact live quantity and price through its existing quote and purchase path.

22 November. Draw solid border edges around the native aura button with an
addon-owned host. Include Blizzard's dedicated player Loss of Control item.
Use a red border for an identified harmful slot with no readable type and
reserve corner glyphs for exact type data. Keep the overlay outside the
native UnitFrame and respect the client's layout permissions.

22 November. Let an explicit Find offer click take over after a completed browse or search. Passive preparation continues to yield. Active foreign purchase dialogs, quotes and transactions retain ownership.

22 November. Resolve native nameplate debuffs by readable instance ID or
the exact visible slot in Forever's native aura lane. Treat publicly
untyped harmful auras as border-only and preserve native visuals when the
type is opaque.

21 November. Drive the Restock reminder from owner offers and accepted
companion work. Display a shopping offer after an explicit quote. Read
confirmed companion receipts through the optional GetIncoming callback and
collect only matching buyer invoices within the outstanding quantity.
Dispatch collection and crafting through the existing player press. Give an
actionable owner step priority and revalidate the displayed companion task
before crafting.
[Validation](CLIENT_VALIDATION.md#restock-reminder-scope-and-placement).

21 November. Display accepted companion shortages through a read-only overlay of owner grid rows. Keep saved presets independently editable. The owner refreshes the projected snapshot when companion inventory and queue evidence changes.

21 November. Use game artwork for the shared debuff type corner. Bind type
selection through Blizzard's secure aura buttons where supported. On native
nameplates, keep the Blizzard icon and place the type artwork on a Flux host
only when the displayed aura's type is readable.

21 November. Read current price depth through a bounded lease on the existing Auction House search owner. The companion owns mixed sourcing and approved budgets. The existing purchase owner checks exact stack size and cost. Seed legacy membership edits with the Normal selection already shown in the editor.

21 November. Pass the preview dimmer's draw sublevel separately from the
optional inherited template. Validate both arguments in the desktop widget
fixture so it catches the failure seen in WoW.

21 November. Share the owner purchase button and follow-up Craft control with optional FluxLogistics. An explicit Shopping List click can prepare a plan quote. Acquisition and craft clicks validate their displayed selection before dispatch. Keep reservations, budget and reconciliation in the accepted companion job.

21 November. Restore the published nameplate overlays and use each client's
Blizzard nameplate frame. Keep the current settings layout and an independent
preview. Apply supported settings to their native or FluxUI owner.
[Nameplates](19-nameplates.md#published-nameplates-with-the-current-fluxui-options).

21 November. Let the Syndicator adapter claim inventory ownership after validating its provider. Use the built-in inventory if no source was established at startup.

21 November. Pass the item observed in the pending auction count separately to planner coverage. The tier's preferred item remains its reference for planning new acquisitions. [Contract](FLUXLOGISTICS_RESTOCK.md#lua-interface-v1).

21 November. Keep accepted procurement rows for reservations. The optional planner Shopping List projection supplies live search quantities, and the owner checks the current net row before opening either shopping path. [Contract](FLUXLOGISTICS_RESTOCK.md#lua-interface-v1).

21 November. Give the compact Focus outline its continuous bottom stroke
below the portrait join. The inner divider joins that stroke from above.
Focus uses Party's health/power split with its own saved dimensions and
external aura placement. [Validation](CLIENT_VALIDATION.md#compact-focus-border-and-party-layout).

21 November. Use one case menu and Play action in the frame settings pane.
The selected case belongs to the pane session. One four-second playback
shows the applicable configured effects with local demonstration data.
Pick the attachment component to preview an absent pet or target.
[Requirements](OPTIONS_REWORK.md#individual-frame-preview-parity).

21 November. Anchor the compact Focus health text host to the existing
partition text band. This lets the label follow the visible health region
as resource visibility and frame height change.
[Validation](CLIENT_VALIDATION.md#compact-focus-health-text-placement).

21 November. Restore the published nameplate files at `1e992c4` and the
pre-port options integration. Keep the current Combat page route and the
existing Flux quest and threat saved settings.
[Restoration](19-nameplates.md#restoration-of-published-fluxui-nameplates).

21 November. Use the shared Flux unit artwork and layout inside the Individual
Frames options pane. Keep sample values and hit regions local to the pane.
Use the normal idle frame as the default view and display the cast in its
configured header or pet power row when its section is selected.
[Requirements](OPTIONS_REWORK.md#individual-frame-preview-parity).

21 November. Use the exact accepted quantity and unit and total price limits for queued auction materials. Apply the independent vendor unit-price comparison to standalone Auction Restock. Keep offer eligibility and native quote checks on both paths. [Contract](FLUXLOGISTICS_RESTOCK.md#accepted-auction-prices-for-vendor-goods).

21 November. Commit an unfinished Syndicator mailbox publication to pending work after its scan returns normally. A later complete scan can recover from an aborted invocation while earlier asynchronous work remains accounted for.

21 November. Use the native player taxi flag to distinguish personal mounts
from flight-path travel. The same check controls the wisp, dismount action
and tooltip. Refresh when mount display or taxi control changes.
[Mount evidence](CLIENT_VALIDATION.md#forever-mount-collection).

21 November. Show accepted crafting shortages through the existing vendor and bank Restock buttons. Keep craft targets in the planner and let carried receipts retire them. Honor accepted price and quantity limits and reuse the scoped owner purchase and bank mover. [Contract](FLUXLOGISTICS_RESTOCK.md#queued-craft-materials).

21 November. Put primary and attached unit tabs together under Individual
Frames. Use Party and Raid tabs in one Party & Raid page, put Cast Bars
in General and place Nameplates in Combat. Apply a dragged frame slider
at release through its existing setter. Keep sample artwork shared with
the world previews, and reuse stable geometry during appearance edits.
[Requirements](OPTIONS_REWORK.md#three-frame-pages-and-responsive-editing).

Earlier on 21 November. Use the existing FluxUI example painters for both group
preview locations. The options pane owns its sample pool and uses a
uniform fit scale. Read EllesmereUI for the Main and Mini Frames split
and focused party and raid tabs. Use FluxUI's skin and existing settings
owners and routes. [Requirements](OPTIONS_REWORK.md#group-preview-parity-and-frame-settings).

21 November. Group the Unit Frame settings by the parts shown in the
right-hand sample. Clicking a sample opens the existing settings section
for its part, with the original callback and settings scope. Use ordinary
preview widgets and sample data so a group or target is unnecessary. Compact
party appearance continues to use the shared Raid Frames controls.
[Requirements](OPTIONS_REWORK.md#unit-frame-preview-editor).

21 November. Use the existing General setting and active unit-frame scope for
countdown text on target, focus, both party layouts and raid.
[Unit-frame requirements](14-unit-frames.md#shared-unit-frame-aura-countdowns).

21 November. Keep the last confirmed Forever journal and riding data across
combat, then sample again through the existing readiness window. Use a
visual-only wisp overlay on the existing mount face, and arm the native
conditional dismount route before combat. The same button owns click, hotkey,
modifiers and journal access. [Mount evidence](CLIENT_VALIDATION.md#forever-mount-collection).

21 November. Keep the vendor's Auto Restock checkbox independent of managed plan creation. The existing target thresholds, accepted plan coverage, reserved stock and workflow guards remain part of the vendor decision. Track a deferred purchase's automatic or manual origin through junk selling. [Merchant sequencing](20-vendor-restock-junk.md#merchant-lifecycle-and-automation-ordering).

21 November. Keep preset memberships on the owning preset and route accepted logistics work through a versioned owner service. Only opted-in activities above Normal create passive managed orders. Qualify bank and merchant offers in their live owner contexts. [Contract](FLUXLOGISTICS_RESTOCK.md).

21 November. Clear the mount macro cache when the placeholder clears the
actual secure action. Use Forever's ordinary world-exit and entry events to
hold the last action during loading and reapply it after journal and riding
data recover. Preserve a genuinely mounted lock and clear a stale cast or
dismounted lock on arrival. [Evidence](CLIENT_VALIDATION.md#forever-mount-collection).

21 November. Commit the side grid's border after a real mouseover visibility
change. When it docks below the minimap, fit the side border to the map's
bottom stroke and use that stroke through the T. Ordinary layout refreshes
settle the border with their other anchors. Anchor the embedded grid to the
middle of the Flux Window content area on the existing map-side edge.
[Evidence](validation/minimap-hover-dock-r193-2026-11-21.json).

21 November. Use the same standalone minimap restore path for an immediate
toggle and one deferred by combat. Apply the latest queued placement and retain
the original parent, anchors and layers until the standalone placement commits.
Align mail and tracking by their bottom edges. Mail uses the same inset corner
when tracking is absent or hidden.
[Evidence](validation/minimap-standalone-restore-2026-11-21.json).

21 November. Keep Flux Window and the side grid's junction paint on their own
border frames. Use the ordinary HUD stratum for side buttons and resolve clock
overlap with a local frame level during top mouseover layout.
[Evidence](validation/hud-panel-layers-r192-2026-11-21.json).

21 November. Keep flyout art in the button's stratum and sample the local border
canvas levels. When the side grid touches Flux Window, let their content contact
determine the shared stroke. Existing layout transactions publish both changes.
[Evidence](validation/hud-layer-dock-r191-2026-11-21.json).

21 November. Let the shared Extra Button painter own the mount's usability
tint. The journal's location-aware verdict feeds the Forever face, and the
existing journal eligibility check preserves its selected assignment across
temporary restrictions. Modifier and cast updates pin the same mount identity
for the icon and usability. [Client evidence](CLIENT_VALIDATION.md#forever-mount-collection).

21 November. Keep Default visible in Forever's compact mount editor and show
one row for each saved override in the current scope. Adding a row assigns the
selected journal mount through FluxUI's existing dropdown, including its
Forever gamepad fallback. Clearing hides the row. The mount tooltip keeps
saved but unavailable overrides visible and highlights the usable fallback.
[Client evidence](CLIENT_VALIDATION.md#forever-mount-collection).

21 November. Put flyout glyphs above the connected HUD seams using a passive
child or the client's existing arrow container. Keep layer updates on the
existing out-of-combat open and layout paths.
[Flyouts and trinkets](12-extra-button-system.md#flyouts-and-trinkets).

21 November. Treat the Forever client as a ground-only journal client. Keep
mount IDs under `mountConfig.forever` in the existing account and character
scopes. Read an older usable ground choice as the default until the scope is
edited. Use the native secure modifier prefixes for exact combinations and the
existing collection and riding events for refresh. Use the existing Collections
side-panel controls and the established direct implementation and Witchcraft
preferences. [Client evidence](CLIENT_VALIDATION.md#forever-mount-collection).

21 November. Capture the recurring cooldown error's collector membership
and field ownership on demand. Keep native event delivery and the
cooldown setter in Blizzard's control while collecting the evidence.
[Client evidence](CLIENT_VALIDATION.md#forever-action-button-cooldown).

20 November. Keep Forever's stock cast animation lifecycle with Blizzard.
The animation inherits the suppressed bar's alpha. Its native completion
can refresh the cooldown without a forced hide from FluxUI. Keep the
shared collector available to native controller buttons.
[Client evidence](CLIENT_VALIDATION.md#forever-action-button-cooldown).

20 November. Set Type 1's icon-side divider width in its artwork profile.
The fill-side boundary uses the registered thickness. The existing join
plan uses the same bounds for the straight stroke and its T-junctions.
[Cast divider](UNIT_OVERLAY_ATTACHMENTS.md#vertical-cast-divider).

20 November. Treat the vertical cast separator as an internal divider.
Use the registered stroke track and thickness for its paint bounds and
carry those bounds into the shared junction and fallback paths.
[Cast divider](UNIT_OVERLAY_ATTACHMENTS.md#vertical-cast-divider).

20 November. Let the paired horizontal cast rims own the inner crest at
their divider. Use the current source tracks and scale so added border
types follow the same rule. Record the rim depth in the branch plan's
inputs so cache reuse respects the painted result.
[Cast rim](UNIT_OVERLAY_ATTACHMENTS.md#continuous-cast-border-rim).

20 November. Use the client's selected taxi legs and a character's completed
flight time as the primary timing source. Treat existing overrides and bundled
durations as initial estimates. An explicit `/fluxfp save` can still pin a
direction. Continue the clock across a UI reload and restore the saved elapsed
time on a fresh login. Mark the restored login ETA approximate and keep that
ride out of route training. [Flight timing](14-unit-frames.md#flight-path-timers).

20 November. Fit the cast icon's inner edge to the existing border track
already used by the fill-effect clip. Keep the adjustment in prepared
layout so it applies to both profiles and shared timer overlays.
[Cast icon seam](UNIT_OVERLAY_ATTACHMENTS.md#type-1-cast-icon-seam).

20 November. Generate the Mana Gem button's inline sequence out of combat
using carried Ruby, Citrine, Jade and Agate copies. Compare the complete body
so a lower-rank change refreshes it even when the best item stays the same.
Let Blizzard track successful uses and read the current step for display.
Run the sequence only in combat. Use the best carried item directly outside
combat, and skip rebinding at combat exit when the body is unchanged.
Keep charged gems on the item action and leave the existing conjure policy in place.
[Button behavior](12-extra-button-system.md#mana-gem-sequence).

20 November. Apply the food and water smallest-stack tie break at the use
buttons after the existing conjured and restore priorities. Use snapshot
locations for the face and a live carried-bag address for the secure click.
Restore the item-ID action after dispatch because bag slots can be reused.
[Button behavior](12-extra-button-system.md#smallest-food-and-water-stacks).

20 November. Use positive skill-pane evidence before treating a missing native
profession-book entry as a revocation. The existing skill-cache invalidation
still applies, and the Pending action checks the live recipe before crafting.
[Auction Restock](AUCTION_RESTOCK.md#saved-recipes-and-row-hover).

20 November. Keep Forever's original World Map and third-party drawings in
Flux. Hold the hosted map's three quest refresh events at the combat boundary
and restore their subscriptions after lockdown. Retain the native event script
and the existing full-map handoff. [Evidence](validation/world-map-combat-2026-11-20.json).

<!-- LHO-FINAL-ACCEPTANCE-GOAL-20261120 -->
20 November. Reopen inventory work as a fixed six-check acceptance pass. Reuse evidence for the same tested source and setup. Retest only failed gates after a focused fix. Accepting deferred required live coverage needs the user's agreement. [Inventory finish point](INVENTORY_PERFORMANCE_ROADMAP.md#finish-point).

<!-- RELEASE-FINISH-LINE-20261120 -->
20 November. Finish the addon with a pinned release candidate, one acceptance round and a scoped retest for each reproducible blocker. Carry forward evidence for unchanged dependencies. Close the R187 HUD goal when its desktop and live gates pass. Improvements beyond the release gates belong in the backlog or in a separately requested goal. [Release roadmap](RELEASE_ROADMAP.md#how-this-ends).
<!-- /RELEASE-FINISH-LINE-20261120 -->

<!-- HUD-FIXTURE-REPAIR-20261120 -->
20 November. Keep both repaired fixtures in the R187 desktop gate. Use the renderer's current paint and source paths to verify repeat-write behavior and trusted shadow support. Live acceptance retains its existing finish line. [Acceptance evidence](validation/hud-acceptance-r187-2026-11-20.json).
<!-- /HUD-FIXTURE-REPAIR-20261120 -->

<!-- LHO-OPTIMIZATION-CLOSEOUT-20261120 -->
20 November. Use a fixed closeout for the current optimization pass. Preserve the measured changes and their exact evidence. Move unresolved native checks into a backlog organized by workflow. The native reagent comparison supports further evaluation when positive craftable stock is available. [Closeout](INVENTORY_PERFORMANCE_ROADMAP.md#finish-point).

<!-- LHO-CRAFT-FALLBACK-CATALOGUE-OWNERS-20261120 -->
20 November. Keep native reagent recovery when provider publication is late or absent. A settled selector can be reused only while its recipe and metadata dependencies and live reagent counts agree. The 19-count native reading gives a cost budget for the check. Positive craftability and incomplete recipe branches need separate evidence. [Evidence](validation/profession-bag-restock-2026-11-19.json#nativeCraftFallbackBagCatalogueOwners).

<!-- LHO-FIRST-COPY-GRID-RECEIPT-20261120 -->
20 November. Use the first-copy receipt as a baseline for detached recipe and Best recompute attribution. Keep native reagent recovery for delayed or missing Syndicator publication. Combat usability measured from the cast start includes cast edges, so a bag-only trace is needed before changing that work. [Evidence](validation/backpack-final-callback-2026-11-19.json#nativeFirstFoodCopyGridRoute).

<!-- LHO-PROTECTION-SLOT-ATTRIBUTION-20261120 -->
20 November. Keep the existing protection reveal. On the measured zero-lock profile, duplicate slot resolutions were part of only 0.083 ms against 1.387 ms for the whole refresh. Any visible-button traversal change needs actual locked equipment and parity for a returning view. [Evidence](validation/backpack-final-callback-2026-11-19.json#settledConjuredMetadataReads).

<!-- LHO-CONJURED-CACHE-READ-20261120 -->
20 November. Return the existing conjured verdict before querying metadata only after item class is available. Keep retries for unresolved facts, existing item-data and rule invalidation and the checks for explicit protection, Restock targets and live carried upgrades. [Evidence](validation/backpack-final-callback-2026-11-19.json#settledConjuredMetadataReads).

<!-- LHO-BANK-CLOSE-LATCH-20261120 -->
20 November. Once the client reports a bank close, use the current visible bank or banker interaction instead of the earlier open latch. Recheck at the next turn and once 0.15 seconds later, with provider hide reconciliation and cancellation on a genuine reopen. Continue ordinary live bank access while its physical signals persist. [Evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeBankSlotMoveAndCloseLatch).

<!-- LHO-BANK-TIER-SETTLED-KIND-20261120 -->
20 November. Allow only complete public cached kinds to rule out a different tier in the authoritative bank-target build. Keep the full checks for actual matching kinds, mana-only food, unresolved data and replaced owners. Bank and bag recovery paths and refresh timing stay as before. [Evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenBankTierKindWork).

<!-- LHO-BANK-VIEW-LOADED-20261120 -->
20 November. Keep the precomputed name list based on paired installed visibility and tier-bank timings. The open-bank warm button is already small in the observed empty-pull session. Retain current cache invalidation and target cadence until a real bank slot update or cold positive plan establishes the next cost. [Loaded comparison](validation/baganator-bank-view-index-2026-11-19.json#loadedFallbackFrameNames). [Open-bank timings](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenBankRestockButton).

<!-- LHO-BANK-VIEW-FALLBACK-NAMES-20261120 -->
20 November. Precompute only the known fallback frame names. Keep dynamic current-skin lookups, registered frames, late-created globals and the previous visitation order. Use real bank slot and aggregate queries to verify the earlier stack collection change while the player has the bank open. [Visibility evidence](validation/baganator-bank-view-index-2026-11-19.json#fallbackFrameNames). [Open-bank evidence](validation/bank-tier-live-counts-2026-11-19.json#nativeOpenCharacterBankStackParity).

<!-- LHO-RESTOCK-TARGET-ATTRIBUTION-20261120 -->
20 November. Keep the preset path and tier threshold reads at their existing cadence. The tested profile has no preset rows and the five threshold reads cost about 0.013 ms total. Prioritize the closed-bank tier reads and preserve fresh native or unresolved stock recovery. Treat the public reagent tests as independent reads because the builder can reuse its own discovery facts. [Evidence](validation/bank-tier-matcher-2026-11-19.json#nativeRestockTargetAttribution).

<!-- LHO-RESTOCK-TIER-RECORD-FILTER-20261120 -->
20 November. Discard plain mismatching records inside the owned tier query before constructing a result table. Keep the original effective restore callback, public classifier and custom records, and preserve the water-from-food path and the existing closed-bank alias. Application work remains scoped to the current read. [Evidence](validation/bank-tier-matcher-2026-11-19.json).

<!-- LHO-AUCTION-INITIAL-PLAN-PAINT-20261120 -->
20 November. Use the existing startup owner and no-quote checks to omit the transient planning paint only from the frame's owned OnShow. Keep normal direct ShowSession and replaced session or painter behavior, seal the current panel state synchronously, and continue to paint native wait, query, error and completion states. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-ROW-ORDER-ALLOCATION-20261120 -->
20 November. Read tier data only when the row has a tier list. Continue to examine every tier of a merged row and retain the original grouping, name and item-ID comparison. Keep the same sort call sites, auction state and rendering cadence. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-CATALOGUE-REVOCATION-VALIDATION-20261120 -->
20 November. Keep the eager recipe-removal snapshot. A direct membership read won on the observed plain saved catalogue, but the variant accounting for mutable or custom recipe and alias records was slower. Positive bag receipts and independent selector refreshes still use their existing paths. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-TEXT-ALIAS-20261120 -->
20 November. Reuse an already readable text key on the full owned catalogue path while the standard converter remains installed. Retain conversion when a getter installs a replacement during the call. Keep fresh catalogue reads, revocations, selection ordering and native material counts in the same paths. The positive item receipt confirms delayed-bag recovery still runs and must be preserved. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAGANATOR-LAZY-CATEGORY-ICON-20261120 -->
20 November. Defer only the category-label texture allocation. Preserve both width wrappers, the native hooks, ordinary anchor resets and managed label layout. The baseline showed that nine of 19 ordinary applications changed or normalized anchors, so retain those writes. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-CRAFT-POTION-FALLBACK-STATIC-20261120 -->
20 November. Use text-first potion checks only to defer the unchanged owned static getter. Preserve foreign getter calls, read subclasses when a qualifying name lacks potion text, and keep bandage and main classifier behavior. Live materials are still queried every time the existing contract requires them. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CAST-WIDGET-ENTRY-INDEX-20261120 -->
20 November. Index the first registration, while retaining the original traversal order for selection sweeps and unindexed or custom-equality widgets. All spells and visibility remain live reads. Keep repeated interrupt delivery and cleanup. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-AUCTION-SEARCH-PREPAINT-20261120 -->
20 November. Suppress only the paint between owned search invalidation and complete search state. Keep the pre-query paint, subsequent event paints, replaced methods and full transaction and quote paths. The earlier renderer state is transient within a single call. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-PROTECTION-EMPTY-SLOT-LOOKUP-20261120 -->
20 November. Keep the original profile enablement and slot input reads. Return false before slot key formatting when the current protected map is empty. Populated maps take the existing lookup. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-PROFESSION-NUMERIC-FULL-CATALOGUE-20261120 -->
20 November. Keep catalogue acquisition fresh for each request. Use numeric keys only on the full ordinary path. Canonical legacy and textual aliases must resolve to the original output positions. Preserve exact fallback semantics for filtered, replaced and exceptional identities. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAG-MOVE-CRAFT-CATALOGUE-20261120 -->
20 November. A real slot change still receives its Baganator layout and both grid updates. Optimize the repeated FluxUI craft catalogue beneath the bag refresh while preserving live native material reads and the Syndicator fallback. Stable aggregate stock alone cannot justify dropping an independent refresh. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-RESTOCK-REAGENT-VISIBLE-PASS-20261120 -->
20 November. Use a single visible-name pass for the owned, warm Restock build when every visible name was read through the native item-name path. Rerun unresolved name lookups. Keep fresh discovery if a generation, provider or defining method changes, data is missing, or a merchant or bank is open. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-PROFESSION-FILTER-CANDIDATES-20261120 -->
20 November. Keep the current profession row storage and rank loop. Full equality cost more than the storage interval it aimed to replace in R589, and the reverse removal lookup showed a small mixed isolated gain. The current wheel-only trinket profile already idles the binding watcher. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-CURRENT-PASSIVE-20261120 -->
20 November. Keep the live clock and metadata checks in Auction Restock refreshes. An unchanged profession result and stable inventory generations can coexist with expiring mail, newly available item metadata and changed craftability. Focus on eliminating work with unchanged inputs inside the existing callback lifecycle. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-RETAIN-SAVED-REMOVALS-20261120 -->
20 November. A ready owned profession scan may retain an existing removal as saved state when both aliases agree, the live learned list and spellbook do not include it, and no saved alias row or flag needs removal. Missing, conflicting, replaced or stale evidence takes the full path. Fresh learning, manual scans, legacy paths and event/publication timing retain their existing behavior. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-FIRST-READY-READ-COST-20261120 -->
20 November. Prioritize reductions in full unlearned-recipe queries on the ready profession source. Require current filtered-list and spellbook evidence, explicit prior observations where needed, and full output parity before using a shortcut. Preserve first-time scans, late data, learning and removals, foreign sources, filter changes and existing observer cadence. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-CAST-MATCHER-NUMERIC-20261120 -->
20 November. Use direct coercion in the spell matcher's override and base paths. Keep every live API query and the existing positive numeric-string handling. Event deduplication and cross-button spell caching need independent lifecycle evidence, including actual interrupt owners. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-CAST-POSITIONAL-PAYLOAD-20261120 -->
20 November. Decode a readable cast GUID and its positional spell ID before the legacy payload scan. A trailing cast-bar field may be numeric and an interrupter GUID can resemble text to the old decoder. Repeated native interrupt deliveries retain fresh owner selection until a safe work reduction is measured. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-OWNED-IDLE-RETICLE-CLEANUP-20261120 -->
20 November. Treat native playing, paused and pending-finish animation states explicitly. The Forever groups were already stopped even though IsDone did not allow the first candidate to qualify. Route active, replaced, uninspectable or failed cleanup through the full sequence. Keep press, highlight and owner handling. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-CAST-INTERRUPT-TARGET-RESET-20261120 -->
20 November. Keep current cancel behavior until native stop behavior and dirty reticle cases are identified. Three delivery timestamps matched, but payload identity and intermediate state were not compared. Keep dynamic owner discovery and cross-client security checks. [Evidence](validation/casting-equality-work-2026-11-15.json).

<!-- LHO-PROFESSION-SOURCE-STORE-ATTRIBUTION-20261120 -->
20 November. Prioritize the source event's full recipe reads before further alias work. A warm ready-source run spent 9.965 ms before the save and 2.555 ms across both saves. The native source boundary and fresh learned metadata still govern any change. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-COMBINED-REAGENTS-20261120 -->
20 November. Share reagent traversal within a single read of a complete native schematic. Keep optional-only and incomplete recipe fallback, quality reads and source/list publication timing. The reload-separated handler samples can vary, so the measured gain applies to the paired extraction. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-READY-SOURCE-COUNTER-20261120 -->
20 November. Retain the initial profession scan through the loading-to-ready boundary. The observed counter changed before the ready source event. The identical same-frame list publication in this sample gives a location to investigate while keeping live recipe metadata and publication timing. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-BAGANATOR-JUNK-SETTINGS-20261120 -->
20 November. Pass current settings through the FluxUI-owned Junk display checks within the same call. Retain manual Restock, explicit tags, default allowlist, caller-overridden checks and the gray fallback. No profile or Junk verdict is cached across events. The single first-open comparison is too small to attribute the full timing difference to this change. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-PENDING-IDLE-REFRESH-20261120 -->
20 November. Keep the Pending target query's paint call. Skip empty goal-map work and repeated job reads when the job is absent. A published bank goal still retires through its cache invalidation and button refresh. Active jobs recheck current settings after the bank callbacks. The smaller read cost does not establish an idle FPS improvement. [Evidence](validation/inventory-idle-followup-native-2026-11-18.json).

<!-- LHO-RESTOCK-BANK-STACKS-LOADED-CLOSED-20261120 -->
20 November. Keep the closed-bank check scoped to adoption, count parity and the withdrawal gate. The active-bank code path requires its own native verification. The character was away from a banker and Pending reported no job. [Evidence](validation/bank-tier-live-counts-2026-11-19.json).

<!-- LHO-RESTOCK-UNIQUE-BANK-STACKS-20261120 -->
20 November. Deduplicate the character-bank stack search across both container lists while retaining the first discovery order and independent account bank. Keep cold-close handling under separate validation. The closed client could validate positive aggregates in R550, while its slot APIs supplied no positions for the 22 known occupied slots. [Stack evidence](validation/bank-tier-live-counts-2026-11-19.json). [Closed-bank evidence](validation/lag-hotspots-provider-counterexamples-2026-11-14.json).

<!-- LHO-PROFESSION-SAVED-NEGATIVE-PREDICATE-20261120 -->
20 November. Preserve the full source-change scan while the first-ready optimization lacks a proven freshness boundary. The positive native comparison covers two settled callbacks on the same warm view. Blizzard uses the numeric profession source counter when the skill line changes. Its use in FrameXML supplies no guarantee that every learned or craftability change advances it. [Evidence](validation/profession-bag-restock-2026-11-19.json). [Pinned frame source](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_Professions/Blizzard_ProfessionsFrame.lua#L208).

<!-- LHO-PROFESSION-OBSERVED-REMOVALS-20261120 -->
20 November. Use the current observed set to filter the temporary ranking revocations. The lookup-by-observed-ID variant had similar timing and needs extra shape checks. Preserve the existing row winner rules, broad catalogue, both source deliveries and explicit removal publication. Treat the timing reduction as local to ranking. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-FIRST-TAILORING-PUBLICATIONS-20261120 -->
20 November. Preserve the existing source-change and list-update deliveries. Two consecutive publications matched on settled Tailoring. A later event can still carry new facts and trigger craft or Restock listeners. Pursue repeated work within a scan and only share cross-event work when a source boundary establishes freshness. The tested output fallback has zero uptake on this character. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-COUNT-NEUTRAL-MOVE-BUILTIN-20261120 -->
20 November. The same count-neutral move produces the same slot and count results through the built-in route and the Syndicator bridge. A location update remains necessary even when an item's total is unchanged. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-COUNT-NEUTRAL-MOVE-PROVIDERS-20261120 -->
20 November. Keep the location notification on a count-neutral move. Both provider traces delivered one changed location and zero count changes. An unchanged bag comparison can accompany a different bag's real slot change. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-UTILITY-CONSUMABLE-RETRY-20261119 -->
19 November. Use the verified item and spell pairs for four fully loaded utility effects after checking for positive restoration. Preserve the existing retry cadence for incomplete data and the original bag-state transitions. [Evidence](validation/consumable-non-restoring-items-2026-11-19.json).

<!-- LHO-NATIVE-BAG-REDRAW-OWNERS-20261119 -->
19 November. Preserve the individual bag-cache deliveries that change stock. In R497, two updates raised the food count first to twenty and then to twenty-eight. The earlier update kept the same food count. Validate its full slots and live widget state before considering a skip. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-NATIVE-FOOD-RECEIPT-20261119 -->
19 November. Keep both native update paths until there is an event-by-event trace. The open Baganator view can redraw from either a committed bag snapshot or a refresh request. The Food receipt capture gives aggregate timing. A per-event trace is needed to establish whether a redraw repeats work FluxUI already triggered. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-SINGLE-CATEGORY-REFRESH-20261119 -->
19 November. Use the public ItemWidgets and Searches reasons once for category data changes. Searches already schedules layout. Keep the previous separate layout fallback where the provider lacks the public reasons. Preserve unrelated layout requests that own geometry or plugin setup. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-SHIELD-CONTEXT-20261119 -->
19 November. Use the current protection snapshot for the Baganator shield context check. Standalone refreshes still query current merchant and disenchant state, and shield visibility still uses the slot-specific rule. Keep the existing Auction tooltip scope because the expanded diagnostic removed no reads. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-PROFESSION-LEARNED-LIST-AUCTION-20261119 -->
19 November. The combined test retained normal Restock notification and repaint in both halves. Keep row refresh and stock freshness on profession events while narrowing repeated work within the target list. R466 measured the target-list query separately after the row build. Its timing is a lead for the next capture. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-CONFIRMED-UNLEARNED-20261119 -->
19 November. Only a complete native scan can establish which absent recipes were unlearned. Require the same owned catalogue and native learned-only view with default category, slot, source and search filters. Require a fresh native negative spellbook result per skipped ID. New learning, changed lists or filters, missing evidence and forced scans use the existing full reads. A disagreement on any freshly read recipe repeats the scan before publishing. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-PROFESSION-NAMED-ALIAS-20261119 -->
19 November. The named profession save reuses the current scan's reconciled recipe references when the numeric and named aliases agree. Four paired saves on copies of the actual Forever Tailoring cache reduced the median from 1.225 ms to 0.890 ms. All 101 recipe records, alias order and removal flags matched. After reload, six native Tailoring events confirmed 101 matching records and separate saved arrays, with no new Lua errors. Ten syntax checks and eight regression scripts passed. All five installed sources match. Only accept the secondary reuse on a fully observed plain numeric catalogue with the original provider and matching saved and session aliases. Filtered history, stale or extra rows, legacy recipes and nonstandard owners use the prior merge. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-AUCTION-TAILORING-WARM-LOADED-20261119 -->
19 November. Eight native Tailoring updates rebuilt Auction Restock once apiece. The installed bag-tooltip path reduced the median Restock rebuild from 5.114 ms to 4.291 ms. The full handler medians were 21.504 ms and 21.258 ms, with overlapping samples. All visible and hidden rows and potion targets matched, four inventory generations stayed stable, and no Lua errors appeared. Tailoring and Auction were closed and the original empty target restored. Keep the live recipe scan and inventory notification at their existing cadence. Retain fresh metadata and eligibility checks. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-WARM-BAG-TOOLTIPS-20261119 -->
19 November. Warm Auction Restock now shares nonempty native carried-bag tooltip text during a single row assembly. Consumable eligibility, missing metadata, item moves and changed providers keep their current checks. After reload, the three paired Forever rebuilds fell from a median of 4.455 ms to 3.767 ms. Visible and hidden rows and potion targets matched, the bag generation stayed stable, and no new Lua errors were captured. The source matches five installs, with 20 syntax checks and 43 regression scripts passing. The separate consumable readiness assertion fails identically on the checkpoint and candidate. Keep the reuse scoped to row assembly and retain all reference eligibility calls. Only complete native bag text qualifies. A bag-generation change, metadata invalidation, reentry, or a changed provider breaks reuse. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-COLD-TIER-SLOTS-20261119 -->
19 November. Auction Restock shares complete occupied bag slots during one cold target-list build. Empty and incomplete slots still receive fresh reads. Recipe and tier matching retain their original order and cadence. In the installed Forever comparison, the median fell from 13.324 ms to 9.882 ms across three pairs. All seven rows and potion targets matched, the bag generation stayed stable, and no new Lua errors were captured. All five installed source copies match. Thirty syntax checks and 38 regression scripts passed. Whole-frame FPS and native checks on the other installs remain open. Limit reuse to a single build with reliable inventory and closed vendor and bank panels. Invalidate on bag-generation change. Replaced providers and vendor-aware lists retain the public traversal. [Evidence](validation/auction-final-sku-2026-11-19.json).

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

<!-- LHO-AUCTION-RESTOCK-STARTUP-20261119 -->
19 November. Auction Restock now reuses its first row build for the first synchronous scan when the data owners, inventory generations, and time boundary match. The search response still rebuilds the rows. In two paired warm Forever runs with Baganator and Syndicator loaded, median ShowSession fell from 12.603 to 6.954 ms (44.8%) and synchronous builds fell from two to one. Six visible rows, one hidden vendor row, the editor selection and the search-response refresh matched. Both warm panel pairs matched across 330,035 sampled pixels. The original build path remains available for charged or unresolved items, active receipts or craft work, unsettled inventory, and replaced data methods. Genuine Pending receipts and other native client/provider profiles still need validation. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-AUCTION-ORDINARY-CHARGE-20261119 -->
19 November. Auction Restock reuses confirmed ordinary units only within one row rebuild with the original charge and potion-replacement methods and stable bag, bank and warband generations. Changed item IDs, charged items, unresolved data and open or unsettled bank contexts retain fresh reads. On the loaded Forever client, three paired full rebuilds with commerce closed matched six visible rows and one hidden vendor row on every run. Median elapsed time fell from 4.785 to 4.480 ms. The bag generation stayed stable and no new Lua errors appeared. Thirty syntax checks passed and the sources match across five client installs. Real charged stock, open Auction and Pending, and the other provider/client configurations still need native validation. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-AUCTION-RECIPE-BATCH-20261119 -->
19 November. Three paired live Forever comparisons matched three learned recipe references in order for five carried Restock outputs. The median recipe catalogue lookup fell from 1.856 to 1.029 ms when the comparison grouped records from one catalogue. Auction Restock now shares one ranked catalogue for five or more distinct eligible items. Smaller comparisons and replacement methods keep the per-item path. Both sources match across five installations and passed twenty syntax checks. The isolated measurement excludes the full Restock workflow. [Evidence](validation/profession-bag-restock-2026-11-19.json).

<!-- LHO-FREE-ACTION-POTION-20261119 -->
19 November. A live Forever check found that Free Action Potion was the sole pending consumable. It was loaded, exposed item spell 6615 and parsed with zero restoration. The matching food control still parsed as 1338 health. FluxUI now recognizes that exact item and spell after ordinary restore classification. Other tooltip states retain their existing retry behavior. The final Lua source matches across all five installations and passed ten compiler checks. Post-reload timing is pending. [Evidence](validation/consumable-non-restoring-items-2026-11-19.json).

<!-- LHO-JUNK-CACHED-QUALITY-20261119 -->
19 November. The Junk fallback now reads an already resolved non-gray quality when the Baganator caller supplies only an item ID. Gray, missing, restricted and replacement quality paths use the original rules. Both changed Lua files pass syntax checks across five installs. [Evidence](validation/junk-cached-quality-2026-11-19.json).

<!-- LHO-PROFESSION-ALIAS-OVERLAP-20261119 -->
19 November. Profession scans now bypass the row and tombstone copy for ordinary aliases with no observed recipe or unlearned ID in common. Related entries and metatable-backed data keep the original merge. Continue to use GetRecipeInfo for learned and unlearned observations. One matching modern spellbook read is limited to the current profession and filter. [Evidence](validation/profession-alias-overlap-2026-11-19.json).


<!-- LHO-PROFESSION-BAG-RESTOCK-20261119 -->
19 November. The profession scan now ranks saved aliases only for recipe keys observed in that scan. It still resolves revocations and rank ties across all stored aliases, uses the full public query if another owner replaces it, and preserves normal scans and notifications. [Evidence](validation/profession-bag-restock-2026-11-19.json).


<!-- LHO-CONSUMABLE-NON-RESTORING-20261119 -->
19 November. The classifier now settles Jungle Remedy and Southshore Stout when their native spells match the verified cure and alcohol effects. It settles Tabetha's Instructions when the complete read-only tooltip matches. Positive classifications run first. Missing and ambiguous tooltip data follow the existing retry path. Stabilize confirmed negatives while retaining normal reads and retry cadence for actual late-loaded consumables. [Evidence](validation/consumable-non-restoring-items-2026-11-19.json).


<!-- LHO-RESTOCK-REAGENT-NAME-READS-20261119 -->
Scope name reuse to the synchronous Restock target rebuild. Retain each visible-item and spell-book discovery call and update the alias map through the existing owner. Use the available name from the pinned native getter, and continue live reads for missing names, merchant rows and public replacements. [Evidence](validation/restock-reagent-name-reads-2026-11-19.json).

<!-- LHO-AUCTION-USE-FINAL-SKU-20261119 -->
Preserve the preliminary charge units at the public ApplyPotionReplacements callback boundary and resolve final units before computing need. An earlier compatibility audit recorded two extension cases affected by removing the preliminary calls. Continue inventory checks using FluxUI, BugTabs, Baganator and Syndicator, with earlier results attributed to the profiles where they were recorded. [Evidence](validation/auction-final-sku-2026-11-19.json).

<!-- LHO-BACKPACK-FINAL-CALLBACK-20261119 -->
Keep the item-registration index after native open-bag parity and loaded-source confirmation. Use the per-item final callback entry as the upper boundary for tracing the remaining first-open hitch. R258 found the optional mark-unusable and upgrade searches disabled. Time the actual registered Flux Junk and slot guard calls separately from Baganator’s UpdateJunkItem widget method. Preserve item classification and the Baganator and Syndicator source files. [Evidence](validation/backpack-final-callback-2026-11-19.json).

<!-- LHO-BAGANATOR-ITEM-REGISTRATION-INDEX-20261119 -->
Index Baganator item-button registration positions against each skin API owner, getter and array. Extend on append and reset on replacement or shrink. Keep the full traversal for providers without skin registration. Continue reading visibility and resolving slots from live buttons. This preserves reveal timing and the registered fallback for visible buttons outside the known layouts. [Evidence](validation/baganator-item-registration-index-2026-11-19.json).

<!-- LHO-BAGANATOR-BANK-VIEW-INDEX-20261119 -->
Use Baganatorâ€™s append-only skin registry for bank-frame discovery. Keep per-call visibility reads and the named fallback lookups. Rebuild the index on a replacement registry, changed getter or smaller registry. Keep full traversal when the provider lacks the skin registration API. [Evidence](validation/baganator-bank-view-index-2026-11-19.json).

<!-- LHO-PARSER-VENDOR-LIVE-20261119 -->
The reproduced slow backpack open emitted no ADDON_LOADED events and added no loaded addons. Prioritize the native item API, widget and existing item callback boundaries for that hitch. The post-adoption whole-retry sample showed no overall improvement. Preserve the established helper performance evidence. The positive charge-cache shortcut remains untested because no qualifying entries existed. [Evidence](validation/parser-vendor-live-2026-11-19.json).

<!-- LHO-RESTORE-PARSER-PATTERNS-20261119 -->
Keep all duration patterns and potion floor formulas. Run each duration pattern only when a matching literal is present and check potion floor patterns on lines containing the corresponding resource. Retain the ordinary tooltip acquisition, retry and classification paths. [Evidence](validation/restore-parser-patterns-2026-11-19.json).

<!-- LHO-LIVING-CONSUMABLE-RETRY-20261119 -->
Do not use the wrapped Score tooltip counts as a baseline for production eligibility work. Persist checks the item class tooltip function's identity, and replacing it can trigger an extra live gate. R223 is the scoped timing baseline with this owner intact. [Evidence](validation/living-consumable-retry-2026-11-19.json).

<!-- LHO-VENDOR-FIELDS-ONCE-20261119 -->
Reuse the first name, link, numeric quality and optional icon tuple only when both API names resolve to the same getter. Keep the table response, incomplete metadata and distinct legacy-provider paths. The native comparisons establish the warm read time and field parity under the observed alias. [Evidence](validation/vendor-fields-once-2026-11-19.json).

<!-- LHO-BACKPACK-SINGLE-SLOT-20261119 -->
Prioritize the interval around Baganator's cached item callbacks, new-item visuals and item spell lookup. Native traces concentrate the first-open hitch in one detail call and show a large Lua heap increase. They establish a timing boundary and candidate causes. Keep existing product code until a load-event or call-level trace identifies the owner. [Evidence](validation/backpack-single-slot-2026-11-19.json).

<!-- LHO-RESTOCK-SETTINGS-GET-20261119 -->
Evaluate the existing migration checkpoint directly in the Restock getter. Keep the migration and defaults bodies, preserving per-character lookup and restoration from legacy data. Live repeated getter timing improved and the full Junk timings varied. Use the native profiler readings as proximity evidence only. The first open coincided with an application over-50 ms counter increment and no increase in the sampled addon counters. [Evidence](validation/restock-settings-get-2026-11-19.json).

<!-- LHO-ITEM-INFO-ONCE-20261119 -->
Keep the existing item metadata field mapping, table response parsing, fallback query, cache and async retry path. The native tuple returns the initial 14 fields together on all three pinned client declarations. On Forever, three paired native trials and an after-reload check support using that tuple directly. [Evidence](validation/item-info-once-2026-11-19.json).

<!-- LHO-BACKPACK-FLUX-COMPAT-20261119 -->
19 November. With Syndicator and Baganator active, the first category backpack open took 150.21 ms with a 161 ms frame gap. The warm open took 5.77 ms. Baganator Display contributed 123.88 ms inclusive. Across the first open, the timed FluxUI calls were 102 Junk checks at 3.79 ms and one view lookup at 0.03 ms. The other selected category and protection callbacks did not run inside the synchronous open. Both closes succeeded and all wrappers restored with zero errors. The first-open hitch still needs deeper attribution. The probe covered synchronous opens only, so deferred work remains open. A delayed follow-up after reload 201 kept the host screenshot capture outside both timed opens. The first open still took 151.67 ms with a 169 ms frame gap. The warm open took 5.14 ms. The backpack returned to its closed state and the probe produced zero new errors. [Evidence](validation/backpack-flux-compat-2026-11-19.json).

<!-- LHO-CONSUMABLE-TOOLTIP-DURATION-20261119 -->
Keep the existing exclusions and test explicit seated-use phrases before duration matching. A timed percentage restore with health or mana already qualifies through the ordinary duration branch. The shorter eat and drink literals cover their longer variants. Preserve locale duration recognition, retry cadence and update events. Predicate results matched for all nine readable native inputs. The sampled full parser digest matched after reload. [Evidence](validation/consumable-tooltip-duration-2026-11-19.json).

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

<!-- ROSTER-GEOMETRY-PORTRAITS-R71-20261118 -->
Use first-slot occupancy to trigger regular raid header layout. Keep all MT/MA slots because their count drives the packed columns. Compare actual protected geometry in its existing secure owner. Reuse 3D party models only after confirming the public member identity and loaded model. Unknown, private, changed and hidden cases use the existing refresh or repair path.
[R71 source pins, replay counts and validation](validation/roster-geometry-and-portraits-2026-11-18.json).
<!-- /ROSTER-GEOMETRY-PORTRAITS-R71-20261118 -->

<!-- ROSTER-RESTRICTED-PARSER-R72-20261118 -->
Test restricted snippets with the client parser as well as the ordinary Lua compiler. Keep layout math inline and preserve native unit binding for every roster change. Reuse border visibility only after a complete paint with matching trim, power state and adjacency.
[R72 source and validation evidence](validation/roster-restricted-parser-2026-11-18.json).
<!-- /ROSTER-RESTRICTED-PARSER-R72-20261118 -->

<!-- PARTY-ROSTER-LOCALITY-R73-20261119 -->
An established non-raid transition may narrow the roster walk only when the expected compact headers and host report public visibility. Keep full recovery on configuration, raid transitions and uncertain state. Require a public member GUID before retaining cast state across roster events.
[R73 evidence](validation/party-roster-locality-2026-11-19.json).
<!-- /PARTY-ROSTER-LOCALITY-R73-20261119 -->

<!-- GROUP-RENDER-R74-20261119 -->
Reuse a completed border dependency branch only within the same flush and observer graph revision. Reuse panel alignment only when the current eligible panel inputs match. Group notifications batch transient display refresh where native ownership allows it. Roster and group-size events continue to refresh the minimap difficulty and queue indicators. Preserve real unit replacement, protected layout guards and explicit refresh ownership.
[R74 evidence](validation/group-render-work-2026-11-19.json).
<!-- /GROUP-RENDER-R74-20261119 -->

<!-- ROSTER-REGION-ROUTING-R75-20261119 -->
Route source pieces and mesh operations into dirty regions before preparing tile fragments. Keep exact clipping, long-source context, cast scope and fresh native sources. Reuse aura anchor and dimension state only when current public getter values match. Preserve repair for missing, private or changed geometry. Raid unit event filters can survive a reveal only when the unit, writer and successful binding agree.
[R75 evidence](validation/roster-region-routing-2026-11-19.json).
<!-- /ROSTER-REGION-ROUTING-R75-20261119 -->

<!-- ROSTER-RETURN-PLANS-R76-20261119 -->
Allow one alternate numeric plan for a currently committed contact when it fits the existing retention ceilings. Validate every hit against current materials, geometry and source ownership. Publish only after successful rendering. Clear alternate retention on source removal or rollback. Defer hidden rebind paint only when the native visibility result is public and false.
[R76 evidence](validation/roster-return-plans-2026-11-19.json).
<!-- /ROSTER-RETURN-PLANS-R76-20261119 -->

<!-- ROSTER-LOCAL-FALLBACK-R77-20261119 -->
Keep same-source parallel backups separate from junction-owned continuations so each operation receives its own local candidates. Preserve candidate order and the existing metadata charge. Share raid adjacency only when all currently eligible rectangles and the overlap value match.
[R77 evidence](validation/roster-local-fallback-2026-11-19.json).
<!-- /ROSTER-LOCAL-FALLBACK-R77-20261119 -->

<!-- ROSTER-PREPARED-LAYOUT-R78-20261119 -->
Use prepared native placement as the sole geometry pass when label refresh follows directly. Retain the Lua pass for fallback, standalone layout and an already-shown legacy MT/MA column. Reuse regional indexes within a build and skip geometry comparisons only when both references point to the same retained group.
[R78 evidence](validation/roster-prepared-layout-2026-11-19.json).
<!-- /ROSTER-PREPARED-LAYOUT-R78-20261119 -->

<!-- REGIONAL-CLIPPING-R79-20261119 -->
Use current public target/focus anchors to gate repeated roster writes. Leave group gating and threat sampling on the existing path. Reuse matching strip shell geometry and take final envelope positions after side-panel layout. Skip vertex clipping planes that contain every current vertex.
[R79 evidence](validation/regional-clipping-2026-11-19.json).
<!-- /REGIONAL-CLIPPING-R79-20261119 -->

<!-- GRID-ENVELOPE-R80-20261119 -->
Let the active strip own hover-induced expansion and collapse. Read Info and the envelope after the current grid and adjacent panel bounds settle. Reuse the existing combat queue for a delayed completion that encounters lockdown. Filter the native roster cleanup through current registered membership before the native frame classifier.
[R80 evidence](validation/grid-envelope-2026-11-19.json).
<!-- /GRID-ENVELOPE-R80-20261119 -->

<!-- INDEXED-REGIONS-R81-20261119 -->
Keep the existing exact overlap test and cast-plane membership. Use the dirty tile index to find candidate regions without scanning every tile per operation. Publish each shared solved input array once and query the strip height only for contacts that need to layer above a unit.
[R81 evidence](validation/indexed-regions-2026-11-19.json).
<!-- /INDEXED-REGIONS-R81-20261119 -->

<!-- INDEXED-NEIGHBORS-R82-20261119 -->
Regional neighbor selection uses the original strict halo comparison after finding candidate tiles. Preserve complete source groups, segment order, and independent cast scopes. Keep existing protected layout guards.
[R82 evidence](validation/indexed-neighbors-2026-11-19.json).
<!-- /INDEXED-NEIGHBORS-R82-20261119 -->

<!-- RAID-CELL-NEIGHBORS-20261119 -->
Raid joined edges retain exact tolerance and ownership. Sort candidate rows and columns only when public geometry or membership changes. Pass prepared edge flags through the existing visual validation and preserve native secure layout.
[Raid cell evidence](validation/raid-cell-neighbors-2026-11-19.json).
<!-- /RAID-CELL-NEIGHBORS-20261119 -->

<!-- ROSTER-ADJUNCT-DISPATCH-20261119 -->
Keep roster adjunct dispatch under the prepared raid layout owner. Route missing-buff requests through the unit paint queue so full and aura updates can satisfy them. Preserve standalone aura updates, visible companion and target paint, and recovery for unavailable native drivers.
[Adjunct dispatch evidence](validation/roster-adjunct-dispatch-2026-11-19.json).
<!-- /ROSTER-ADJUNCT-DISPATCH-20261119 -->

<!-- SOURCE-RENDER-CONTEXT-R83-20261119 -->
Reuse current render context only within one junction operation. Keep live paint input and field reuse validation, and resolve the native source parent again for later draws. Keep raised strip ownership separate from a retained unit branch.
[R83 evidence](validation/source-render-context-2026-11-19.json).
<!-- /SOURCE-RENDER-CONTEXT-R83-20261119 -->

<!-- FRAGMENT-OWNERS-R84-20261119 -->
Keep canvas owners for every existing fragment. A new owner-phase fragment inherits the contact that first requires it and all later contacts for the group. Share those sets within the source group and retain the existing UV and visibility math.
[R84 evidence](validation/fragment-owners-2026-11-19.json).
<!-- /FRAGMENT-OWNERS-R84-20261119 -->

<!-- PREPARED-LAYERS-R85-20261119 -->
Keep layer data for one synchronous regional commit. Reuse shared owner summaries with the original exact native stratum choice and level ordering. Read the decorative canvas live and use the original source path if its public layer input is unavailable.
[R85 evidence](validation/prepared-layers-2026-11-19.json).
<!-- /PREPARED-LAYERS-R85-20261119 -->

<!-- ROSTER-MACRO-BATCH-20261119 -->
Batch roster input in the existing conditional eval owner. Reuse its normal combat-family signature and face resolver. An unchanged roster runs one eval check before the paint throttle and issues no paint.
[Macro roster batch evidence](validation/roster-macro-batch-2026-11-19.json).
<!-- /ROSTER-MACRO-BATCH-20261119 -->

<!-- TILE-FIELD-REJECTION-R86-20261119 -->
Use strict geometric rejection before polygon allocation when a field lies entirely outside the tile. Fields touching a clip boundary continue through the original clipping with the same vertex order, coordinates and source ownership.
[R86 evidence](validation/tile-field-rejection-2026-11-19.json).
<!-- /TILE-FIELD-REJECTION-R86-20261119 -->

<!-- STRIP-POSE-TOPOLOGY-R87-20261119 -->
Cache the two strip poses only on settled drag expand/collapse commits. Require exact regional geometry and current material, UV and raised-level agreement before reusing a paint-free plan. Keep native visibility, tint and opacity in the existing current-source path.
[R87 evidence](validation/strip-pose-topology-2026-11-19.json).
<!-- /STRIP-POSE-TOPOLOGY-R87-20261119 -->

<!-- INDIVIDUAL-ROSTER-BATCH-20261119 -->
Batch individual frame roster chrome in arrival order through the existing timer service. Preserve compact party delegation, standalone role and loot timing, and the existing full update and protection paths. Query one raid row from a public player index and retain the slower identity scan on uncertain rows.
[Individual unit roster evidence](validation/individual-roster-batch-2026-11-19.json).
<!-- /INDIVIDUAL-ROSTER-BATCH-20261119 -->

<!-- STRIP-CHROME-MINIMAP-ROSTER-20261119 -->
Use the exact strip face-size arguments to validate same-turn chrome. Restore revealed and changed faces through the native skin path. Group minimap notifications share one pending refresh with the current combat guard and full-layout consumption.
[Strip and minimap evidence](validation/strip-chrome-minimap-roster-2026-11-19.json).
<!-- /STRIP-CHROME-MINIMAP-ROSTER-20261119 -->

<!-- PREPARED-STRIP-SAMPLING-R88-20261119 -->
Keep strip pose texture coordinates alongside the immutable geometry. Use the existing material and mask validity checks before restore and resolve current color and alpha at draw time. Return before preparing draw state for an empty rectangle list.
[Border sampling evidence](validation/prepared-strip-sampling-2026-11-19.json).
<!-- /PREPARED-STRIP-SAMPLING-R88-20261119 -->

<!-- BORDER-SETTERS-THREAT-ROSTER-R89-20261119 -->
Compare prepared UV arrays directly before the native texture setter. Invalidate UVs on material writes and keep exact scalar arity. Use one next-turn Details threat refresh for roster bursts. Direct updates consume pending work and lifecycle changes clear it.
[Setter and threat roster evidence](validation/border-setters-threat-roster-2026-11-19.json).
<!-- /BORDER-SETTERS-THREAT-ROSTER-R89-20261119 -->

<!-- FINAL-STRIP-UNIT-ANCHORS-R90-20261119 -->
Defer duplicate drag-driven unit screen positioning until after the side panels and envelope settle. Use only confirmed public point matches to skip a rewrite. Placement changes and explicit refreshes keep the full target pass.
[Strip unit anchoring evidence](validation/final-strip-unit-anchors-2026-11-19.json).
<!-- /FINAL-STRIP-UNIT-ANCHORS-R90-20261119 -->

<!-- STRIP-GRID-PACKING-R91-20261119 -->
Offer grid packing reuse only for held-action strip changes. Require current public geometry and packing inputs to match. Keep the full paths for changed slots, explicit layout and queued protected work.
[Strip grid packing evidence](validation/strip-grid-packing-2026-11-19.json).
<!-- /STRIP-GRID-PACKING-R91-20261119 -->

<!-- STRIP-PANEL-SETTLE-R92-20261119 -->
Use a single Trinket Menu pass after adjacent grids settle on a strip crossing. Keep a settled Info mode and refresh only its strip placement when needed. Preserve the original full refresh for placement changes and standalone calls.
[Strip panel settlement evidence](validation/strip-panel-settle-2026-11-19.json).
<!-- /STRIP-PANEL-SETTLE-R92-20261119 -->

<!-- RAID-ROSTER-ATTACHMENT-PAINT-R93-20261119 -->
Use the MT/MA header as the scope for its target attachments. Keep a public one-valued wrapper alpha in place. Share only the public loot unit token within a paint batch and sample it afresh on standalone refreshes.
[Raid roster paint evidence](validation/raid-roster-attachment-paint-2026-11-19.json).
<!-- /RAID-ROSTER-ATTACHMENT-PAINT-R93-20261119 -->

<!-- STRIP-LAYER-COMMIT-R95-20261119 -->
Apply each decoration canvas’s final regional layer at its first use during a synchronous commit. Check retained canvases at publication and keep off-region paint listeners. Preserve matching strip outer anchors while the inner drag grid changes. The fallback roster sweep uses existing scheduler ownership and skips matching public values.
[Matched validation](validation/strip-layer-commit-2026-11-19.json).
<!-- /STRIP-LAYER-COMMIT-R95-20261119 -->

<!-- STRIP-RELATIVE-ANCHORS-R96-20261119 -->
Keep a strip face or unified outline attached to its existing native points when the complete public relative tuple still matches. Route unavailable points, changed neighbors and anchor drift through the normal writer. Settle each mini to its final visible or parked position in one pass.
[Matched validation](validation/strip-relative-anchors-2026-11-19.json).
<!-- /STRIP-RELATIVE-ANCHORS-R96-20261119 -->

<!-- CONSUMABLE-ROSTER-BINDINGS-R97-20261119 -->
Food and Water derive conjure and ritual precedence from the player’s learned spellbook. Group changes need no consumable bind or inventory refresh. Keep keybind, spellbook, inventory, login and combat-release wiring in their existing owners.
[Matched validation](validation/consumable-roster-bindings-2026-11-19.json).
<!-- /CONSUMABLE-ROSTER-BINDINGS-R97-20261119 -->

<!-- STRIP-SLOT-SAMPLING-R98-20261119 -->
Sample public slot occupancy only inside the current visual pass. Start that pass after secure mapping so a synchronous page change is visible. Standalone occupancy readers and later layout requests sample current state.
[Matched validation](validation/strip-slot-sampling-2026-11-19.json).
<!-- /STRIP-SLOT-SAMPLING-R98-20261119 -->

<!-- RAPID-STRIP-DROPS-R99-20261119 -->
Carry the slot used by the native pickup or drop into its immediate occupancy notification. Invalidate current consuming columns. Real expand and collapse retain repaint, and native grid events own lightweight stock suppression. Bound prepared border reuse to the two most recent matching layouts per hover state.
[Matched validation](validation/rapid-strip-drops-2026-11-19.json).
<!-- /RAPID-STRIP-DROPS-R99-20261119 -->

<!-- REGIONAL-FRAGMENT-READS-R100-20261119 -->
Reuse public source setup only during the synchronous regional commit. Sample fresh on reflow, share completed parent walks, and keep visibility observer entries tile-local. Suppress an original source once during drawing and verify its final alpha at publication.
[Matched validation](validation/regional-fragment-reads-2026-11-19.json).
<!-- /REGIONAL-FRAGMENT-READS-R100-20261119 -->

<!-- STRIP-JOIN-SOURCES-R101-20261119 -->
Read join source parents from the current regional commit when original fragments have already sampled them. Borrow a prepared canvas only after the commit has applied its layer. Unavailable data continues through the original draw path.
[Matched validation](validation/strip-join-sources-2026-11-19.json).
<!-- /STRIP-JOIN-SOURCES-R101-20261119 -->

<!-- REGIONAL-LAYOUT-INDEX-R102-20261119 -->
Store complete layout fingerprints as group-local sorted arrays keyed by existing group ID. Compare all current groups and appearance settings. An enclosing rectangle may only reject a distant group. Candidate groups must pass the existing padded edge probes, and cast scopes still use their current plane.
[Matched validation](validation/regional-layout-index-2026-11-19.json).
<!-- /REGIONAL-LAYOUT-INDEX-R102-20261119 -->

<!-- REGIONAL-TILE-MATERIALS-R103-20261119 -->
Keep all examined planner material dependencies for the prepared pose, and sample additional paint only for source fragments the affected cells actually use. A required unavailable or masked texture still takes the existing fallback. Global rebuilds still validate every selected group’s sources.
[Matched validation](validation/regional-tile-materials-2026-11-19.json).
<!-- /REGIONAL-TILE-MATERIALS-R103-20261119 -->

<!-- RAID-ROSTER-NATIVE-WRITES-R104-20261119 -->
Skip a secure ref assignment only when the same frame and its public installed handle both match. Unreadable backing attributes keep the native setter, and absent slots still clear explicitly. Use current legacy frame anchors and current public label data to skip redundant presentation writes.
[Matched validation](validation/raid-roster-native-writes-2026-11-19.json).
<!-- /RAID-ROSTER-NATIVE-WRITES-R104-20261119 -->

<!-- REGIONAL-ROSTER-POSES-R105-20261119 -->
Use the existing exact topology and material guard for recent roster geometry. Keep only small group neighborhoods, with two layouts maximum. A changed registration or global renderer retirement clears the saved layouts. Use current paint on every restored layout.
[Matched validation](validation/regional-roster-poses-2026-11-19.json).
<!-- /REGIONAL-ROSTER-POSES-R105-20261119 -->

<!-- REGIONAL-BORDER-CUTS-R106-20261119 -->
Keep subtraction order for every intersecting cut. Reuse a disjoint input list and unchanged fallback cells, which are read-only outside the next cut. Preserve visibility blocker identity, field budgets and painter order.
[Matched validation](validation/regional-border-cuts-2026-11-19.json).
<!-- /REGIONAL-BORDER-CUTS-R106-20261119 -->

<!-- HELD-ACTION-REFLOW-R107-20261119 -->
Cache the order of prepared border sources and fallback blocker groups. Resolve current paint and visibility at draw time. Preserve immediate geometry commits and the existing repaint on a genuine pose change.
[Matched validation](validation/held-action-reflow-2026-11-19.json).
<!-- /HELD-ACTION-REFLOW-R107-20261119 -->

<!-- INDEPENDENT-BORDER-REGIONS-R108-20261119 -->
Use the existing independent solver plane as the renderer region for each explicitly independent unit frame. Route casts and independent outlines through the same scoped-region path. Compute bounds from both departing and arriving geometry to retire old paint completely.
[Matched validation](validation/independent-border-regions-2026-11-19.json).
<!-- /INDEPENDENT-BORDER-REGIONS-R108-20261119 -->

<!-- COMPACT-RAID-SEAM-DELTAS-R109-20261119 -->
Keep one count per shared side. A single membership or rectangle change removes old contacts and adds new ones. Retain flags that still match and publish topology before painting so a retry cannot repeat the same update.
[Matched validation](validation/compact-raid-seam-updates-2026-11-19.json).
<!-- /COMPACT-RAID-SEAM-DELTAS-R109-20261119 -->

<!-- RAID-AURA-PRESENTATION-R110-20261119 -->
Retain group presentation for unchanged public aura policy. Reconcile native visibility against the current owned widget and keep incoming unit binding fresh. Recalculate filters for real class, hidden-buff, tail or strict-policy changes.
[Matched validation](validation/raid-aura-presentation-2026-11-19.json).
<!-- /RAID-AURA-PRESENTATION-R110-20261119 -->

<!-- RAID-UNIT-PAINT-READS-R111-20261119 -->
Reuse a paint-local health sample when the bar, text and color refer to the same unit. Full paint can reuse the verified unit token for range. Default percent text needs no extra raw health reads.
[Matched validation](validation/raid-unit-paint-reads-2026-11-19.json).
<!-- /RAID-UNIT-PAINT-READS-R111-20261119 -->

<!-- STRIP-BORDER-REFRESH-R112-20261119 -->
Reuse native widget state only after matching public scale or visibility. Keep the border owner index paired with the committed geometry and clear both together. Validate source eligibility again before the local commit.
[Matched validation](validation/strip-border-refresh-2026-11-19.json).
<!-- /STRIP-BORDER-REFRESH-R112-20261119 -->

<!-- STRIP-HOVER-PAINT-R113-20261119 -->
Admit scoped action paint only for exclusive hover requests with an initialized layout and a changed expansion state. Include pending slot dirties and every repaired face. Public size matches preserve the prepared widget, with normal writes used for denied reads or real differences.
[Matched validation](validation/strip-hover-paint-2026-11-19.json).
<!-- /STRIP-HOVER-PAINT-R113-20261119 -->

<!-- BORDER-VISIBILITY-FANOUT-R114-20261119 -->
Retain callback-local public availability only. Reuse a commit gate once the observer checklist and ordered blocker inputs match. Charge the extra gate value to the existing registration budget, and publish an observer change only after its repaint succeeds.
[Matched validation](validation/border-visibility-fanout-2026-11-19.json).
<!-- /BORDER-VISIBILITY-FANOUT-R114-20261119 -->

<!-- BORDER-DRAW-GEOMETRY-R115-20261119 -->
Keep exactly written native point, size and vertex inputs together on owned fields. Invalidate a property before writing it so a partial setter failure admits restoration. Use the existing public source read to validate four color channels once per source.
[Matched validation](validation/border-draw-geometry-2026-11-19.json).
<!-- /BORDER-DRAW-GEOMETRY-R115-20261119 -->

<!-- ROSTER-DISCOVERY-REFRESH-R116-20261119 -->
A nameplate module may declare that its successful full refresh covers the unit loop. An error leaves the ordinary unit retry. Share the live raid setting within discovery and verify native accessibility for unregistered frames.
[Matched validation](validation/roster-discovery-refresh-2026-11-19.json).
<!-- /ROSTER-DISCOVERY-REFRESH-R116-20261119 -->

<!-- STRIP-VISIBILITY-R117-20261119 -->
Keep the final real cursor edge in the current layout flush. When the mouse already returned to the applied pose, drop the hover-only request. Publish each tile’s visibility listeners as a list so the renderer can retire or attach the whole list together.
[Matched validation](validation/strip-visibility-2026-11-19.json).
<!-- /STRIP-VISIBILITY-R117-20261119 -->

<!-- RAID-PAINT-BATCH-R118-20261119 -->
Sample shared raid preferences synchronously. Let the name painter hide the standalone role icon and keep direct cleanup when the name cannot be painted. Keep the native aura owner cleanup when the readable painter supplies no completion result.
[Matched validation](validation/raid-paint-batch-2026-11-19.json).
<!-- /RAID-PAINT-BATCH-R118-20261119 -->

<!-- RAID-REASSIGNMENT-R119-20261119 -->
Bind a secure unit and register its events immediately. Queue visible full cell presentation for the existing dispatch. A reveal uses its immediate paint and consumes earlier work for that frame. Use the same queue for roster-driven temporary companions.
[Matched validation](validation/raid-reassignment-2026-11-19.json).
<!-- /RAID-REASSIGNMENT-R119-20261119 -->

<!-- STRIP-CHAT-DOCK-R120-20261119 -->
Read final strip-floor geometry before chat settlement. Reuse a pin only when its current native points, size and Edit Mode fields match. Compare the raid docking line separately because side-column chat can stay in place while the raid stack moves.
[Matched validation](validation/strip-chat-dock-2026-11-19.json).
<!-- /STRIP-CHAT-DOCK-R120-20261119 -->

<!-- STRIP-PAINT-INDEX-R121-20261119 -->
Keep a source’s regional listener list and an owner’s sprite pool attached by tile. The renderer replaces changed tiles’ memberships as a unit. Current native paint still visits the active fields.
[Matched validation](validation/strip-paint-index-2026-11-19.json).
<!-- /STRIP-PAINT-INDEX-R121-20261119 -->

<!-- BORDER-VISIBILITY-COMMIT-R122-20261119 -->
Share public visibility and opacity results only for fully observed native ancestors during the synchronous regional commit. Parent transitions discard those results, and tile-local source paint remains authoritative.
[Matched validation](validation/border-visibility-commit-2026-11-19.json).
<!-- /BORDER-VISIBILITY-COMMIT-R122-20261119 -->

<!-- PARTY-DISPEL-IDENTITY-R123-20261119 -->
A matching public party GUID and unchanged token and aura filter allow a roster-only refresh to reuse the live native debuff owners. A changed or unknown identity, native filter change and explicit refresh retain their current path.
[Matched validation](validation/party-dispel-identity-2026-11-19.json).
<!-- /PARTY-DISPEL-IDENTITY-R123-20261119 -->

<!-- UNIT-NAME-STRIP-GEOMETRY-R124-20261119 -->
Share icon placement between outer-border and visual refresh. Keep size and anchors when the current native data matches, and read the actual owner again after a repair clears the old point.
[Matched validation](validation/unit-name-strip-geometry-2026-11-19.json).
<!-- /UNIT-NAME-STRIP-GEOMETRY-R124-20261119 -->

<!-- BORDER-POSE-SAMPLES-R125-20261119 -->
Reuse already compiled source coordinates only after the current handle, masks, support and coordinate tuple match. Separate current paint from prepared texture geometry.
[Matched validation](validation/border-pose-samples-2026-11-19.json).
<!-- /BORDER-POSE-SAMPLES-R125-20261119 -->

<!-- BORDER-PREPARED-DRAW-R126-20261119 -->
Share compiled tile geometry when live inputs match. Give each active tile ownership of mutable draw records after detaching its prior listeners.
[Matched validation](validation/border-prepared-draw-2026-11-19.json).
<!-- /BORDER-PREPARED-DRAW-R126-20261119 -->

<!-- BORDER-DRAW-INPUTS-R127-20261119 -->
Retain verified public draw inputs on an exact geometry and paint match. The sprite reuse decision still requires native field checks, even when those inputs match.
[Matched validation](validation/border-draw-inputs-2026-11-19.json).
<!-- /BORDER-DRAW-INPUTS-R127-20261119 -->

<!-- BORDER-SPRITE-REUSE-R128-20261119 -->
Record triangle indices on actual draw output and keep the sprite list with the generation that owns it. Validate current native field ownership before reusing that list.
[Matched validation](validation/border-sprite-reuse-2026-11-19.json).
<!-- /BORDER-SPRITE-REUSE-R128-20261119 -->

<!-- ROSTER-ROLE-CHROME-R129-20261119 -->
Apply group role icons directly to their final size, point and visibility. Reuse the existing guarded texture geometry reads and preserve the fallback setters when state cannot be verified.
[Matched validation](validation/roster-role-chrome-2026-11-19.json).
<!-- /ROSTER-ROLE-CHROME-R129-20261119 -->

<!-- STRIP-HOVER-MAPPINGS-R130-20261119 -->
Use the fixed expanded mapping directly and read occupancy when resolving the collapsed pose. During a changed column, keep exact public attributes and preserve writes for changed or unverifiable flags.
[Matched validation](validation/strip-hover-mappings-2026-11-19.json).
<!-- /STRIP-HOVER-MAPPINGS-R130-20261119 -->

<!-- STRIP-HOVER-KEYS-R131-20261119 -->
Use the binding event to invalidate hover reuse. Verify the live route owner, hosts and native proxy actions before retaining installed keys. Coalesced content edits, lost routes and failed or invalidated refreshes use the normal path.
[Matched validation](validation/strip-hover-keys-2026-11-19.json).
<!-- /STRIP-HOVER-KEYS-R131-20261119 -->

<!-- BORDER-PARENT-GEOMETRY-R132-20261119 -->
Share public metadata by the parent sampled during a single synchronous layout read. Keep each run’s persistent priority independent and retry an unavailable sample for other runs. Each later layout reads current state.
[Matched validation](validation/border-parent-geometry-2026-11-19.json).
<!-- /BORDER-PARENT-GEOMETRY-R132-20261119 -->

<!-- BORDER-POSE-TOPOLOGY-R133-20261119 -->
Use the identity of the current public stamp table only for copies of the same geometry sample. Keep live flag and registration-key rereads, and all exact checks for a fresh snapshot.
[Matched validation](validation/border-pose-topology-2026-11-19.json).
<!-- /BORDER-POSE-TOPOLOGY-R133-20261119 -->

<!-- BORDER-FALLBACK-CONTEXT-R134-20261119 -->
Omit key preparation for absent, disjoint and blocked fallback cells. The verified base and current contributing contexts still decide reuse. When collecting regional bounds, union the precomputed group extents with the existing halo for both snapshots.
[Matched validation](validation/border-fallback-context-2026-11-19.json).
<!-- /BORDER-FALLBACK-CONTEXT-R134-20261119 -->

<!-- BORDER-ADMISSION-R135-20261119 -->
Carry the successful regional source check only from the geometry filter to the same synchronous commit. An invalidation during that read forces the existing second check. Every subsequent layout checks current sources again.
[Matched validation](validation/border-admission-2026-11-19.json).
<!-- /BORDER-ADMISSION-R135-20261119 -->

<!-- BORDER-LAYER-PLAN-R136-20261119 -->
Keep a public level sample only within the regional planning pass and retry unavailable samples. Calculate the final canvas layer from fresh sources and one mutable output record per canvas. Preserve equal-rank ordering.
[Matched validation](validation/border-layer-plan-2026-11-19.json).
<!-- /BORDER-LAYER-PLAN-R136-20261119 -->

<!-- BORDER-SNAPSHOT-COPY-R137-20261119 -->
Share only the sampled public source rectangles between structural copies. Keep operation geometry and mutable ownership records separate. Use one temporary lookup per copy to avoid retaining the producing records.
[Matched validation](validation/border-snapshot-copy-2026-11-19.json).
<!-- /BORDER-SNAPSHOT-COPY-R137-20261119 -->

<!-- BORDER-POSE-REGISTRATION-R138-20261119 -->
Retire saved layouts by their participating border owners after registration changes. Match the exact selected geometry and current paint inputs on later reuse. Keep admission and normal regional compilation for the mixed registration transaction.
[Matched validation](validation/border-pose-registration-2026-11-19.json).
<!-- /BORDER-POSE-REGISTRATION-R138-20261119 -->

<!-- BORDER-EMPTY-FRAGMENTS-R139-20261119 -->
A regional source can still claim paint without emitting normal fragments. Only actual fragments need their normal canvas. Retain the ordered indexes of nonempty fallback plans with each prepared cell.
[Matched validation](validation/border-empty-fragments-2026-11-19.json).
<!-- /BORDER-EMPTY-FRAGMENTS-R139-20261119 -->

<!-- RAID-ROSTER-SAMPLE-R140-20261119 -->
Share the same current roster rows and local player slot between legacy group visibility, main tank and assist placement. Preserve the compatibility unit policy for group columns and use readable existence for tank and assist membership.
[Matched validation](validation/raid-roster-sample-2026-11-19.json).
<!-- /RAID-ROSTER-SAMPLE-R140-20261119 -->

<!-- RAID-GRID-RECTANGLE-R141-20261119 -->
Use the public rectangle tuple only to confirm all four previously sampled compact raid edges. Read individual edges when any value differs or is unavailable. Keep the existing tolerances for compact raid joins.
[Matched validation](validation/raid-grid-rectangle-2026-11-19.json).
<!-- /RAID-GRID-RECTANGLE-R141-20261119 -->

<!-- RAID-RANGE-BURST-R142-20261119 -->
Run immediate fallback checks for the changing compact unit and coalesce broader discovery under the pending border wake. Let the optional range route retry on reveal and preserve the existing recovery for required routes.
[Matched validation](validation/raid-range-burst-2026-11-19.json).
<!-- /RAID-RANGE-BURST-R142-20261119 -->

<!-- RAID-JOIN-INDEX-R143-20261119 -->
Use exact coordinate lookup when public frame edges and overlap endpoints share an exact fractional track on each axis. Duplicate origins and other irregular coordinates use the tolerance solver.
[Matched validation](validation/raid-join-index-2026-11-19.json).
<!-- /RAID-JOIN-INDEX-R143-20261119 -->

<!-- BORDER-ANCHOR-BURSTS-R144-20261119 -->
Sample anchors after a burst of clear, point and parent setters, and again after panel alignment if it writes more anchors. Keep section paint updates immediate and only revise the observer graph when the settled dependencies change.
[Matched validation](validation/border-anchor-bursts-2026-11-19.json).
<!-- /BORDER-ANCHOR-BURSTS-R144-20261119 -->

<!-- STRIP-HOVER-ROUTES-R145-20261119 -->
Use the optional hover refresh solely for a pure cursor crossing. It refreshes live occupancy and runs the existing state calculation. Retain the full refresh for action data changes, missing optional snippets and failed optional execution.
[Matched validation](validation/strip-hover-routes-2026-11-19.json).
<!-- /STRIP-HOVER-ROUTES-R145-20261119 -->

<!-- STRIP-MODIFIER-ROUTES-R146-20261119 -->
Keep individual prepared routes only for the existing hover refresh and a matching previous page and modifier. Publish the same native packed child state. Full reprovision and the normal native page and modifier routes still clear or recalculate their existing stamps.
[Matched validation](validation/strip-modifier-routes-2026-11-19.json).
<!-- /STRIP-MODIFIER-ROUTES-R146-20261119 -->

<!-- PARTY-INDICATOR-PASS-R147-20261119 -->
Use the shared outer chrome text pass during party paint. Finish indicator positions after the roster roles have updated. Check the current public anchor, dimensions and draw layer before repairing role icons.
[Matched validation](validation/party-indicator-pass-2026-11-19.json).
<!-- /PARTY-INDICATOR-PASS-R147-20261119 -->

<!-- RAID-EXTRA-DRIVER-RETRY-R148-20261119 -->
Retry only optional cells with unready paging drivers when provider, dock, dimensions and scoped settings still match. Keep failed cells hidden and use the existing combat-release event for deferred retries.
[Matched validation](validation/raid-extra-driver-retry-2026-11-19.json).
<!-- /RAID-EXTRA-DRIVER-RETRY-R148-20261119 -->

<!-- BORDER-ROLE-ANCESTRY-R149-20261119 -->
Share public connected and overlay classifications during one read-only border phase. Drop the current memo when a setter invalidates that phase. Treat unreadable ancestry conservatively and read it again if it becomes public.
[Matched validation](validation/border-role-ancestry-2026-11-19.json).
<!-- /BORDER-ROLE-ANCESTRY-R149-20261119 -->

<!-- STRIP-FLYOUT-ARROW-R150-20261119 -->
Preserve flyout arrow anchor points verified against current native geometry during repeated layout notifications. Current host movement follows the native anchor. Retain the synchronous repair for changed or unreadable geometry.
[Matched validation](validation/strip-flyout-arrow-2026-11-19.json).
<!-- /STRIP-FLYOUT-ARROW-R150-20261119 -->

<!-- STRIP-HOVER-OCCUPANCY-R151-20261119 -->
During a pure held-action crossing, sample native minirow occupancy during the existing secure state update. Publish changed occupancy and retain confirmed packed state. Ordinary modifier reads keep their cache and a full refresh still invalidates the full set.
[Matched validation](validation/strip-hover-occupancy-2026-11-19.json).
<!-- /STRIP-HOVER-OCCUPANCY-R151-20261119 -->

<!-- STRIP-PLAN-COVERAGE-R152-20261119 -->
Allow a covering saved border plan only when each requested tile matches exact bounds, the selected neighborhood matches, and live materials and participating levels validate. Rebind current operations for the committed tiles and keep existing tiles outside the requested set.
[Matched validation](validation/strip-plan-coverage-2026-11-19.json).
<!-- /STRIP-PLAN-COVERAGE-R152-20261119 -->

<!-- RAID-CHROME-LOOKUP-R153-20261120 -->
Test direct group ownership and recognizable public native frame names before enumerating the party member pool. Keep the live pool fallback for anonymous, private and denied names.
[Matched validation](validation/raid-chrome-lookup-2026-11-20.json).
<!-- /RAID-CHROME-LOOKUP-R153-20261120 -->

<!-- RAID-STABLE-PAINT-R154-20261120 -->
Read the current raid widget visibility and percentage range before applying fixed presentation values. Keep opaque or denied reads on the existing protected setter path, and preserve live health, power and group indicators.
[Matched validation](validation/raid-stable-paint-2026-11-20.json).
<!-- /RAID-STABLE-PAINT-R154-20261120 -->

<!-- BORDER-LISTENER-INDEX-R155-20261120 -->
Reuse an empty regional observer index only inside its active synchronous commit. Retire old tile contents before paint and remove any bucket that remains empty after the attempt.
[Matched validation](validation/border-listener-index-2026-11-20.json).
<!-- /BORDER-LISTENER-INDEX-R155-20261120 -->

<!-- BORDER-FRAGMENT-MEMBERSHIP-R156-20261120 -->
Reconcile source pool membership when a fragment is added, replaced or retired. Keep live membership across synchronous redraws and clear each retired field while hiding its tile. Warm rollback retires fields from both old and staged tiles.
[Matched validation](validation/border-fragment-membership-2026-11-20.json).
<!-- /BORDER-FRAGMENT-MEMBERSHIP-R156-20261120 -->

<!-- PET-STRIP-PACKING-R157-20261120 -->
Use verified pet packing only during the deferred strip border transaction. Preserve current position and border adoption, and run the existing full pet layout if any owned geometry or sizing input needs repair.
[Matched validation](validation/pet-strip-packing-2026-11-20.json).
<!-- /PET-STRIP-PACKING-R157-20261120 -->

<!-- STANCE-STRIP-LAYOUT-R158-20261120 -->
Verify current relative stance geometry in the strip transaction after the pet owner has settled. Keep form, options, and native repair work in the existing deferred layout when shared anchors alone do not fit.
[Matched validation](validation/stance-strip-layout-2026-11-20.json).
<!-- /STANCE-STRIP-LAYOUT-R158-20261120 -->

<!-- NATIVE-GROUP-HIDE-R159-20261120 -->
Keep native group roots and child discovery intact during suppression. Reuse live zero alpha and visit small child lists directly, with bulk traversal for wider pools. Existing native suppression ownership and restore paths still apply.
[Matched validation](validation/native-group-hide-2026-11-20.json).
<!-- /NATIVE-GROUP-HIDE-R159-20261120 -->

<!-- RAID-ACTIVE-HEADERS-R160-20261120 -->
Limit known-hidden header pruning to prepared roster refreshes. Native unit and reveal handlers own visible paint. Explicit setup, uncertain visibility and fallback roster repair retain the complete pass.
[Matched validation](validation/raid-active-headers-2026-11-20.json).
<!-- /RAID-ACTIVE-HEADERS-R160-20261120 -->

<!-- STRIP-BADGE-PLACEMENT-R161-20261120 -->
Use the live geometry check for the strip crossing only. Keep chrome suppression, count-font sizing and the current VFX level calculation. Explicit squeeze, combat recovery and readers without stable geometry keep the existing layout writer.
[Matched validation](validation/strip-badge-placement-2026-11-20.json).
<!-- /STRIP-BADGE-PLACEMENT-R161-20261120 -->

<!-- BORDER-RECENT-LAYOUTS-R162-20261120 -->
Retain small exact layouts in recency order within the former two-large-plan ceilings. Index each plan by the existing geometry and registration checks. Leave a new footprint with the existing synchronous local solve.
[Matched validation](validation/border-recent-layouts-2026-11-20.json).
<!-- /BORDER-RECENT-LAYOUTS-R162-20261120 -->

<!-- BORDER-SIMPLE-INTERVALS-R163-20261120 -->
Send uncut parallel overlaps to the same interval painter without a boundary list. Keep the existing chained-owner partition and preserve coincident cap multiplicity through a pass-local key index.
[Matched validation](validation/border-simple-intervals-2026-11-20.json).
<!-- /BORDER-SIMPLE-INTERVALS-R163-20261120 -->

<!-- BORDER-FALLBACK-CLIP-R164-20261120 -->
Use local clipping bounds for known compiled public geometry to reject disjoint fallback triangles before cache work. Keep the strict touching predicate and the normal standalone validation path.
[Matched validation](validation/border-fallback-clip-2026-11-20.json).
<!-- /BORDER-FALLBACK-CLIP-R164-20261120 -->

<!-- STRIP-SHELL-ANCHORS-R165-20261120 -->
Check the strip shell anchor, size and inner scale independently before writing them. Preserve the full writer when native fields are unreadable and on explicit calls that require it. Let the current border transaction settle the changed geometry.
[Matched validation](validation/strip-shell-anchors-2026-11-20.json).
<!-- /STRIP-SHELL-ANCHORS-R165-20261120 -->

<!-- BORDER-TILE-FIELDS-R166-20261120 -->
Retain the exact half-plane clip for crossed tile bounds and the original fan for skewed quads. For fully contained standard geometry, build only the final tile vertices. Keep the same winding, emitted fields and degenerate-triangle threshold.
[Matched validation](validation/border-tile-fields-2026-11-20.json).
<!-- /BORDER-TILE-FIELDS-R166-20261120 -->

<!-- RAID-AURA-RETIREMENT-R167-20261120 -->
Keep the addon-owned subscription state keyed to the native aura container. Publish it only after a completed SetUnit call. Hide using guarded owned visibility. The native layout still owns unit assignments and actual aura rendering.
[Matched validation](validation/raid-aura-owner-retirement-2026-11-20.json).
<!-- /RAID-AURA-RETIREMENT-R167-20261120 -->

<!-- STRIP-GRID-ROOT-ANCHORS-R168-20261120 -->
Keep the current grid root point only when all public native anchors match. Compute the noncombat screen floor on the detached path. Maintain the existing native writer on mismatches, missing capability and uncertain reads.
[Matched validation](validation/strip-grid-root-anchors-2026-11-20.json).
<!-- /STRIP-GRID-ROOT-ANCHORS-R168-20261120 -->

<!-- RAID-UNIT-EVENT-RETIREMENT-R169-20261120 -->
Record a successful native event reset on the owned compact unit frame. Unit and deferred layout registrations invalidate the record. Failed clears, reentrant registration and replacement writers retain normal cleanup.
[Matched validation](validation/raid-unit-event-retirement-2026-11-20.json).
<!-- /RAID-UNIT-EVENT-RETIREMENT-R169-20261120 -->

<!-- BORDER-NEIGHBOR-RUNS-R170-20261120 -->
Build a compact sequence index during the existing raw geometry copy for a local change. Resolve neighbors by the same scope and tile tests, then copy only consecutive ranges they own in original source order. Continue reading fresh geometry through the existing observer path.
[Matched validation](validation/border-neighbor-runs-2026-11-20.json).
<!-- /BORDER-NEIGHBOR-RUNS-R170-20261120 -->

<!-- STRIP-EMPTY-PROMOTION-R171-20261120 -->
Gate main-page occupancy scans on a populated mini pair when deciding promotion. Retain fresh slot and current-page sampling after the secure mapping update and preserve the synchronous border commit.
[Matched validation](validation/strip-empty-promotion-2026-11-20.json).
<!-- /STRIP-EMPTY-PROMOTION-R171-20261120 -->

<!-- FLYOUT-ARROW-LAYERS-R172-20261120 -->
Keep the arrow layer only when live public parent, strata and level match the current owner. Validate scale separately after any layer repair. Forced creation and show retain the full writer, and all structural work stays behind the existing combat check.
[Matched validation](validation/flyout-arrow-layers-2026-11-20.json).
<!-- /FLYOUT-ARROW-LAYERS-R172-20261120 -->

<!-- BORDER-FALLBACK-PARTITION-R173-20261120 -->
Write the ordered remainders of an intersecting availability cell directly into its output list. Keep the same blocker identity and budgets. Scope the private helper to the fallback builders to preserve the Lua chunk’s local-variable headroom.
[Matched validation](validation/border-fallback-partition-2026-11-20.json).
<!-- /BORDER-FALLBACK-PARTITION-R173-20261120 -->

<!-- BORDER-LISTENER-RUNS-R174-20261120 -->
Publish regional fallback listeners as ordered entries that may share consecutive fields with the same verified observer pair. Paint each field in original order. Preserve the plain full-render lists and the fallback for uncached observer chains.
[Matched validation](validation/border-fallback-listeners-2026-11-20.json).
<!-- /BORDER-LISTENER-RUNS-R174-20261120 -->

<!-- BORDER-LISTENER-LINKS-R175-20261120 -->
Store subsequent fallback fields in a reusable tile-owned link table. Reset it after detaching the tile and drop it on retirement. Preserve global flat lists and repaint each field with current source opacity.
[Matched validation](validation/border-listener-links-2026-11-20.json).
<!-- /BORDER-LISTENER-LINKS-R175-20261120 -->

<!-- BORDER-FIELD-ANCHORS-R176-20261120 -->
Retain the single owned BOTTOMLEFT anchor when changing offsets. Check the live count and point identity and clear on a new parent or unreadable or different points. A separate pool per strip pose stays in the prototype because it increases resident widget count with mixed modeled timing.
[Matched validation](validation/border-field-anchors-2026-11-20.json).
<!-- /BORDER-FIELD-ANCHORS-R176-20261120 -->

<!-- BORDER-FIELD-PAINT-R177-20261120 -->
Cache paint values by their native setter signature. Preserve UV invalidation after SetTexture and the existing color invalidation when a pooled field changes source. The combined anchor guard stays in the desktop prototype because its full-update results were mixed.
[Matched validation](validation/border-field-paint-2026-11-20.json).
<!-- /BORDER-FIELD-PAINT-R177-20261120 -->

<!-- PARTY-ROSTER-DISPATCH-20261120 -->
Use one group event owner for prepared party slots and combine the notification with the existing paint queue. Read native visibility after the roster settles. Clear prior target identity immediately before its deferred repaint and retain independent native target and indicator events.
[Matched validation](validation/party-roster-dispatch-2026-11-20.json).
<!-- /PARTY-ROSTER-DISPATCH-20261120 -->

<!-- BORDER-ROSTER-BOUNDS-R178-20261120 -->
Allow triangles in a prepared roster junction to share a directly anchored leader on the same canvas. Reuse an existing link when its leader still matches. A new link is eligible only when it replaces both direct box writes. Keep the existing direct writer for strip changes and fresh layouts.
[Matched validation](validation/border-roster-bounds-2026-11-20.json).
<!-- /BORDER-ROSTER-BOUNDS-R178-20261120 -->

<!-- BORDER-SOURCE-ALPHA-R179-20261120 -->
Reuse only a public alpha read that found zero on a watched native source and called no setter. Invalidate that observation on reentrant alpha or RGBA writes. Clear it at transaction completion or rollback. Leave the capped alternate pool outside runtime after its visibility-write and texture cost measurements.
[Matched validation](validation/border-source-alpha-2026-11-20.json).
<!-- /BORDER-SOURCE-ALPHA-R179-20261120 -->

<!-- STRIP-EXPANDED-COLUMNS-20261120 -->
Skip collapsed-column packing while the strip is expanded. Keep current-page main occupancy and mini-slot occupancy in the expanded layout key. Preserve the established ordering of secure mapping, native placement and border publication. Leave the alternate record and tile-routing experiments outside runtime after the matched comparisons.
[Matched validation](validation/strip-expanded-columns-2026-11-20.json).
<!-- /STRIP-EXPANDED-COLUMNS-20261120 -->

<!-- BORDER-OBSERVED-SOURCES-R180-20261120 -->
Reuse a watched source snapshot only within the current regional read. Discard the sample when alignment writes, registration changes or a watched setter invalidate the observation. Keep the normal refresh for full, unavailable and foreign geometry. The numeric signature and retirement trials remain external.
[Matched validation](validation/border-observed-sources-2026-11-20.json).
<!-- /BORDER-OBSERVED-SOURCES-R180-20261120 -->

<!-- BORDER-PANEL-ALIGNMENT-POSES-R181-20261120 -->
Keep two validated panel alignment layouts. Match live panel owners, bounds, scale, priority and attachment policy before reusing solved offsets. Clear both saved layouts on failed native writes. Apply offsets to decorative border containers through the existing synchronous writer.
[Matched validation](validation/border-panel-alignment-poses-2026-11-20.json).
<!-- /BORDER-PANEL-ALIGNMENT-POSES-R181-20261120 -->

<!-- GROUP-NAMEPLATE-ANCHORS-20261120 -->
Reuse a badge only when its own visibility and single native anchor match the current layout exactly. Leave changed, private and denied placements to the same native writer. Preserve the roster update and quest follow-up poll for current data and recovery.
[Matched validation](validation/group-nameplate-anchors-2026-11-20.json).
<!-- /GROUP-NAMEPLATE-ANCHORS-20261120 -->

<!-- GROUP-NAMEPLATE-LEVELS-20261120 -->
Check the public current level of an already attached nameplate overlay before setting it. New parents, changed levels and unreadable host levels retain the established writer and layering policy.
[Matched validation](validation/group-nameplate-levels-2026-11-20.json).
<!-- /GROUP-NAMEPLATE-LEVELS-20261120 -->

<!-- STRIP-INFO-ANCHORS-20261120 -->
Reuse the native Info slot and gap-fill points on a strip crossing only when their current public owners and offsets still match. Re-sample envelope bounds per invocation and share that sample only across roles on the same widget.
[Matched validation](validation/strip-info-anchors-2026-11-20.json).
<!-- /STRIP-INFO-ANCHORS-20261120 -->

<!-- STRIP-SLOT-SETTLE-20261120 -->
Track actual action-slot requests until the existing layout pass consumes them. A warmed action-only edit can use the same current-geometry and repair checks as a hover crossing. Startup and mixed structural/settings work retain the full path.
[Matched validation](validation/strip-slot-settle-2026-11-20.json).
<!-- /STRIP-SLOT-SETTLE-20261120 -->

<!-- BORDER-CURRENT-DRAW-INPUTS-R182-20261120 -->
Reuse a border source’s paint validation only when the current render transaction installed that entry. Check private opacity on use and share a public source parent only inside that transaction.
[Matched validation](validation/border-current-draw-inputs-2026-11-20.json).
<!-- /BORDER-CURRENT-DRAW-INPUTS-R182-20261120 -->

<!-- ROSTER-AURA-PAINT-20261120 -->
Compare the current public value of an owned aura texture, stack label or visibility before writing. A real change, restricted value or unavailable read still uses the existing paint and display paths.
[Matched validation](validation/roster-aura-paint-2026-11-20.json).
<!-- /ROSTER-AURA-PAINT-20261120 -->

<!-- STRIP-EVENT-OWNERSHIP-R183-20261120 -->
The registered action-strip slot watcher owns occupied-row settling when the strip is active. Keep the immediate envelope callback for absent or replaced watchers and keep the form-storm callback. Use the current public source frame levels within one prepared strip commit. Changed or restricted layers keep the full admission and draw paths.
[Matched validation](validation/strip-event-ownership-2026-11-20.json).
<!-- /STRIP-EVENT-OWNERSHIP-R183-20261120 -->

<!-- STRIP-GRID-WIDTH-20261120 -->
Reuse Combat and Non-combat grid column decisions across a width change only when the built-in priority policies, button membership and the native geometry being retained still match. Resize through the same layout and paint, with explicit, pending, binding and changed-content updates keeping the full packing path.
[Matched validation](validation/strip-grid-width-2026-11-20.json).
<!-- /STRIP-GRID-WIDTH-20261120 -->

<!-- BORDER-FIELD-RETIREMENT-R184-20261120 -->
Hide only previously published outgoing textures in the normal regional paint pass. A field already hidden by its owner can receive an idempotent Hide when its ownership retires. Full reset, release and failed-paint cleanup still sweep their original pools.
[Matched validation](validation/border-field-retirement-2026-11-20.json).
<!-- /BORDER-FIELD-RETIREMENT-R184-20261120 -->

<!-- PARTY-TARGET-TRAIL-20261120 -->
Reuse party-target loss state only for a nonempty public target identity and matching current and prior readable health. Keep resets for changed, inactive or unreadable samples. Keep native health and absorb writes. A reset during value publication discards the reuse decision. Explicit target changes and hiding continue to clear the old trail.
[Matched validation](validation/party-target-trail-2026-11-20.json).
<!-- /PARTY-TARGET-TRAIL-20261120 -->

<!-- STRIP-PARKED-CHROME-20261120 -->
Keep the current verification of texture identities, native normal paint, backdrop visibility and applied button dimensions. New widths, art replacement and unreadable region state take the regular repair. Capture an unlocked native art update for the next verification. The locked native callback retains its original art writer and leaves validation for the next unlocked layout.
[Matched validation](validation/strip-parked-chrome-2026-11-20.json).
<!-- /STRIP-PARKED-CHROME-20261120 -->

<!-- BORDER-OBSERVER-SCRATCH-R185-20261120 -->
Use the original current native getters and preserve dependency order, cycle detection, traversal ceilings and conservative global fallback. Publish a separate weak-key link set for each real rewire. Reject opaque parents before producing a comparable snapshot.
[Matched validation](validation/border-observer-scratch-2026-11-20.json).
<!-- /BORDER-OBSERVER-SCRATCH-R185-20261120 -->

<!-- PARTY-STATUS-OWNER-20261120 -->
Apply this layout ownership in a party paint that finishes with Party.UpdateIndicators. The shared refresh still updates live role visibility and level art. Standalone frames and missing owners keep the shared placement. Invalid or unreadable party name widths retain the shared text budget. Multiple NPC label variants still run the existing measured fit.
[Matched validation](validation/party-status-owner-2026-11-20.json).
<!-- /PARTY-STATUS-OWNER-20261120 -->

<!-- STRIP-GRID-RING-20261120 -->
The shared squeeze path passes the sizing function already used to the existing button utility. Skip the duplicate ring call only while the built-in adjuster would call that same built-in sizing function. Keep equipment-border size, countdown and empty-state work in their original order. Direct callers and replaced sizing methods keep their prior behavior.
[Matched validation](validation/strip-grid-ring-2026-11-20.json).
<!-- /STRIP-GRID-RING-20261120 -->

<!-- STRIP-ARROW-OWNER-20261120 -->
Both explicit updates and the native show handler pass the completed refresh function to Trinket. A separate or replaced function still runs. Trinket keeps the two local arrow placements, including arrows outside the engine scan. Matching readable points and layer values keep their placement. Unreadable or changed points and layers retain the original repair path.
[Matched validation](validation/strip-arrow-owner-2026-11-20.json).
<!-- /STRIP-ARROW-OWNER-20261120 -->

<!-- STRIP-INFO-MEASURE-20261120 -->
The horizontal layout owns its render list for one synchronous pass. It reuses the measured width only with the same glyph text, FontStrings and font size. Changed labels, including compact-to-full and restricted values, keep measurement. The real Info frame keeps its height writes and stat refreshes. A decorative gap follows its top and bottom anchors directly without sampling unused grid heights.
[Matched validation](validation/strip-info-measure-2026-11-20.json).
<!-- /STRIP-INFO-MEASURE-20261120 -->

<!-- BORDER-PANEL-INPUTS-R186-20261120 -->
Match the existing frame, border owner, role, layer priority, scale and four public stroke coordinates before reusing an input record. Read live geometry on every alignment pass. The planner keeps its temporary nodes outside the retained records, and the output phase keeps the existing native writes and failure recovery. Removing the last owner shortens the active list and restores its border.
[Matched validation](validation/border-panel-inputs-2026-11-20.json).
<!-- /BORDER-PANEL-INPUTS-R186-20261120 -->

<!-- ROSTER-HOVER-DRIVER-20261120 -->
Only spell-hover routes qualify for the native unit-exists driver. When the last spell-hover route is removed under the mouse, the same out-of-combat lifecycle parks that driver. Public routing detection still recognizes ordinary mouse and wheel bindings. Full binding and Edit Mode refreshes, frame registration and combat deferral retain their existing owners.
[Matched validation](validation/roster-hover-driver-2026-11-20.json).
<!-- /ROSTER-HOVER-DRIVER-20261120 -->

<!-- NAMEPLATE-RANK-ROSTER-20261120 -->
Share public identity for one full refresh. Keep per-target threat payloads for non-tanking ranks and fresh guarded reads for unreadable IDs and unit existence. Standalone rank calls retain their own reads. A replaced GUID or rank provider uses the current provider. A known tanking player row returns rank one before the group walk. No settings, events or timers are added.
[Matched validation](validation/nameplate-rank-roster-2026-11-20.json).
<!-- /NAMEPLATE-RANK-ROSTER-20261120 -->

<!-- BORDER-CELL-BUDGET-R187-20261120 -->
Keep aggregate planned-field and draw-cache usage with the committed regional layout. Admission inspects the replacement keys, subtracts their existing claims and keeps unchanged claims in the totals. Commit publishes the counts with the new layout. Full release and recovery clear them. The existing resource limits remain in force.
[Matched validation](validation/border-cell-budget-2026-11-20.json).
<!-- /BORDER-CELL-BUDGET-R187-20261120 -->

<!-- HUD-ACCEPTANCE-R187-20261120 -->
Finish with the bounded acceptance matrix in the HUD performance roadmap. A failed check can reopen implementation for its owner. Keep the tested candidate while live scenarios are pending.
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
The earlier vendor row-copy optimization missed public replacement ownership:
putting a retained ordinary row into bases lets a replacement GetVendorCraftTargets
mutate the caller's row. The defining function itself copies before writes, but
Need/MailUnits/Pending/PredictedMailUnits can receive row.tiers containing the
selected source. The private defining-owner contract now requires those methods
and SetItemUnits to retain their original identities. Missing/foreign contracts
and metatable rows use the former shallow-copy path. Default plain-row reuse
stays. No crafting validation or callback is skipped. This corrects integration
isolation; no new measured performance gain. The preceding23 native food
normal/fallback match and zero-error build70959 state do not accept this24 set.
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
Use fresh count maps only for the exact defining Inventory/restock bag-query
owners. Tier consumers discard the public records' location/link fields, so
constructing those records repeats unused work. Retain source link-read branches
in a lazy private side map; do not substitute snapshot.counts or cache zeros.
Any replaced public bag getter retains the original record-query path verbatim.
This is conditional allocation reduction, not a proven CPU/FPS/spike gain.
No new settings, timers or update delay. Native acceptance of this23-file set
is pending after shutdown; do not transfer the preceding21 reload smoke.
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
17 November: use existing guarded FG/BG controller with exact current process/
window/birth and one fixed short command per run. User pause flags stop active
verification; foreign controls and other diagnostic/profiler roots remain.
A guarded reload may refuse combat/cast/channel/active watch/CF62hold; this run
returned to the world with matching15disk pairs and metadata corroboration.
Use actual BugTabs.GetSessionCounts after source inspection; absent BugGrabber
output is unconfirmed. Keep a stale formal ACK refused without restamp/replay;
personally viewed native output remains a weaker observed result. No simulations
or new FPS claim. All other workflow/client/provider requirements remain open.
[Scope](validation/inventory-native-direct-smoke-2026-11-17.json).
<!-- /LHO-NATIVE-DIRECT-SMOKE-20261117 -->

<!-- LHO-POTION-PATTERN-SETUP-20261117 -->
17 November: prepare only fixed private regex-pattern text at load. Keep all
tooltip matching, resource calculations and fresh result ownership live. Retain
original resource/mode/suffix/range order and all separator/frontier/percent/up-to
strings. Trade fixed pattern storage/setup for per-line concatenation; do not
claim measured CPU/bytes/FPS benefit or cache parsed tooltip results.
[Scope](validation/inventory-potion-pattern-setup-2026-11-17.json).
<!-- /LHO-POTION-PATTERN-SETUP-20261117 -->

<!-- LHO-CLASSIFY-RESULT-PROFESSION-WORKERS-20261117 -->
17 November: remove repeated private result-function construction with explicit
current-call captures; retain fresh result records and every classification/native
query, selection branch and minimum/maximum/percent rule. Reuse profession timer
callback with the same Start-local pending state and dynamic action lookup.
Timer.After/PolyAfter occurrence scheduling was inspected; no function-identity
deduplication. Do not add an eager per-line rate predicate without evidence: it
could increase work on ordinary nonmatching tooltip lines. No old functional
result or native gain transfers to new source.
[Scope](validation/inventory-classify-result-workers-2026-11-17.json).
<!-- /LHO-CLASSIFY-RESULT-PROFESSION-WORKERS-20261117 -->

<!-- LHO-CAST-BAG-AUCTION-WORKERS-20261117 -->
17 November: hoist successful-cast helper functions with event-local Spells
passed explicitly. Retain original sparse argument array/# bound, multiple-return
semantics, exact native matching/name queries and ritual exclusions. Reuse the
bag flush worker because it captures only existing module queue state; keep
quiet/max-delay arithmetic and state-clear ordering. Reuse auction flush after
checking Scheduler queues every array entry rather than deduplicating by
callback identity. Preserve all mail code and the prior stale-mail measure-first
decision. Process presence alone is not native test or loaded-source proof.
[Scope](validation/inventory-cast-bag-auction-workers-2026-11-17.json).
<!-- /LHO-CAST-BAG-AUCTION-WORKERS-20261117 -->

<!-- LHO-FOLLOWUP-COUNT-WORKERS-20261117 -->
17 November: extend the existing private carried-count defining-function
contract to pending/craft-readiness consumers. Match the selected getter and
namespace/Flux record; retain fresh options for replacement getters and all
reliability/memo/physical-charge semantics. Reuse the bank snapshot comparator
without changing comparisons. Do not remove bank mover OnUpdate: its hidden
frame already stops idle updates. Unloaded old scanners are outside the live
cost path. No measured-gain or native acceptance claim.
[Source review](validation/inventory-followup-count-workers-2026-11-17.json).
<!-- /LHO-FOLLOWUP-COUNT-WORKERS-20261117 -->

<!-- LHO-KEYS-ONLY-CONSUMERS-20261117 -->
17 November: reuse the already owned fresh-ID query where callers consume only
keys. Preserve the original public getter presence check, exact namespace owner
and helper identity, and the helper's facade/Index override fallback. Keep full
records for consumers of counts, links or locations. Do not add generation/name
caches or skip item-name/metadata queries to obtain allocation savings. No claim
of universal improvement: small inventories retain ID-helper overhead.
[Source and limits](validation/inventory-keys-only-consumers-2026-11-17.json).
<!-- /LHO-KEYS-ONLY-CONSUMERS-20261117 -->

<!-- LHO-DIRECT-INVENTORY-RESUME-20261117 -->
17 November: explicit resume supersedes the earlier user pause. Continue direct
inventory Lua optimization; no further simulation/benchmark/probe construction.
Reuse the existing private option sentinel and normalized scalar flags; keep
fresh output ownership. Hoist charge scanner workers with explicit data context,
preserving method/slot-mapper lookups inside pcall and all fallback/read order.
Do not interpret syntax passes or removed allocation sites as measured gain.
The stale-mail measure-first decision and external-addon exclusions remain.
[Source identities and scope](validation/inventory-direct-resume-2026-11-17.json).
<!-- /LHO-DIRECT-INVENTORY-RESUME-20261117 -->

<!-- LHO-USER-PAUSE-20261117-1305 -->
17 November: latest user steering supersedes the former simulation-first
workflow. Continue direct Inventory/EBS Lua optimization with source review and
syntax checks; do not resume simulation/benchmark/probe construction without
new user direction. The user then paused the whole goal. Keep the current six
edits, pause controls and source snapshots; the pause reload clears temporary
in-game code, so later testing needs fresh setup. Native evidence remains
separate from source-only preservation and syntax results.
[Paused state](validation/inventory-pause-2026-11-17.json).
<!-- /LHO-USER-PAUSE-20261117-1305 -->

<!-- STANCE-PORTRAIT-BACKDROP-CONTACT-20261117 -->
17 November: make attached backdrop endpoints meet their existing anchor owner.
Keep stance root/border and its left/vertical padding; use the existing anchor
gap for attached background right point. Let original mode recreation restore
detached defaults. Complete the existing portrait strip to the portrait edge;
retain round exclusions and all paint paths. No builder change or new resource.
[Evidence](validation/stance-portrait-backdrop-contact-2026-11-17.json).
<!-- /STANCE-PORTRAIT-BACKDROP-CONTACT-20261117 -->

<!-- PORTRAIT-BACKDROP-GAP-20261117 -->
17 November: address the clarified portrait backdrop gap with a single static
interior continuation, not a new junction or border mesh solve. Leave the rounded
corner footprint, model/root/background geometry and mini profiles unchanged.
Reuse existing backdrop paint ownership and guarded sampling; no event or
per-combat preparation. [Evidence](validation/portrait-backdrop-gap-2026-11-17.json).
<!-- /PORTRAIT-BACKDROP-GAP-20261117 -->

<!-- TOT-NPC-SECRET-COLORS-20261117 -->
17 November: user explicitly requires NPC Default chrome even with class/custom
Appearance. Keep reaction names separate from NPC material; public unit/owner
class policies remain. Use native class-color lookup for opaque ToT class tokens
and forward RGB only to native sinks. Store no private cache key/hex/geometry
channel; unsupported capability/unknown classification holds prepared color.
Opt in only static unit sources; preserve generic private fallback and direct
public paths. [Evidence](validation/tot-npc-secret-colors-2026-11-17.json).
<!-- /TOT-NPC-SECRET-COLORS-20261117 -->

<!-- MINI-UNIT-FIT-COLORS-20261117 -->
17 November: use a fixed mini-only75% geometry factor with canonical border
art, scaling corners and dividers together. Fit all opaque mini interiors to
3/3/5/5 rather than adding masks. Preserve root/portrait attachment owners.
Explicit false policy boundaries distinguish a unit's no-tint/no-class choice
from ordinary inheritance. Pets use owner class regardless of Appearance; party
member class settings and existing dispel eligibility remain. No new setting,
Core rebuild trigger or private-value inspection.
[Evidence](validation/mini-unit-fit-colors-2026-11-17.json).
<!-- /MINI-UNIT-FIT-COLORS-20261117 -->

<!-- CAST-UNIT-JUNCTIONS-20261117 -->
17 November: prepare optional-unit perpendicular paint only with eligible axis
ownership and backup profiles. Preserve exact generic/ambiguous/foreign fallback
policy and existing budgets; no global invalidation for ordinary target/focus
paint. Reject the cast crossbar experiment's larger alpha discontinuity. Use
measured prepared glow bounds without new masks/drivers.

Attach existing bounded read reasons and dirty counts only to optional active
cost records. These are geometry/material/UV facts, not upstream event causes.
Preserve R63 rejection and CF64's historical scope.
[Evidence](validation/cast-unit-junctions-2026-11-17.json).
<!-- /CAST-UNIT-JUNCTIONS-20261117 -->

<!-- LHO-RUNTIME-P92-P94-20261117 -->
17 November: follow the user's renewed instruction to edit addon Lua directly
and stop simulation/timing preparation. Apply only the reviewed private P92
patterns, P93 fresh-output workers and P94 stateless First Aid worker after
dated source/history/settings-metadata checkpoints. Preserve every public/native
query and traversal order; do not cache facts or alter retry cadence. P94 removes
a closure only on the eligible fallback path after profession-name lookup.
These structural changes are not measured CPU/GC/FPS wins. Six syntax passes
are recorded separately from incomplete P92 functional evidence, unrun P93/P94
models and the earlier P90 tests. Keep all initial failures and P91's stopped
draft; no new observer, simulator or timing framework is authorized here.
[Record](validation/inventory-runtime-p92-p94-2026-11-17.json).
<!-- /LHO-RUNTIME-P92-P94-20261117 -->

<!-- LHO-CLASSIFY-PARSER-LINE-P90-20261117 -->
17 November: normalize each private parser line once before its five workers.
Run percent workers only when a literal % exists, since every percent-producing
pattern requires it; keep both flat workers unconditional. Preserve public
queries, parser shape, fresh axes, caches/retries and polling cadence.

Admit this direct source change on exact ed64 inverse, actual-owner functional
parity and deterministic private-work evidence. The ordinary WoW string-primitive
contract excludes arbitrary monkey-patched string methods/private environments.
Seventy->14 normalizations and42->12 percent entries are work counts, not CPU,
allocated bytes or FPS. P88 predates f441 and cannot establish parser gain.
Native reload/loaded source and wider workflow acceptance remain pending.
[P90 source and exact evidence](validation/classify-parser-line-work-p90-2026-11-17.json).
<!-- /LHO-CLASSIFY-PARSER-LINE-P90-20261117 -->

<!-- LHO-INVENTORY-NATIVE-SCAN-P88-20261117 -->
17 November: retain P88 as current-native inclusive Scan timing/call evidence,
not matched gain, exclusive CPU/FPS, event causality or exact source adoption.
Retain Lua51 15/70 scope at packets1..11; final cleanup12 had source review and
accepted native CLEAN true3.

P89 adds three later ACKed context observations. Empty added/load tables and
four false time/raw flags cannot establish absent private pending work or false
ShouldSoftHoldOwned: aggregated reliability was not queried. Addon-loaded flags
also do not identify loaded Lua bytes.

RootF_RELEASED is a dated exact-owned release with HALT retained, allowing other
owners to resume their own coordination checks; preserve shared COMBAT/CF64
records and other guards. BG6 advancing green is calibration evidence only,
not host launch or jump authorization. Classify private NormalizeLine/percent
work remains planned/test-before-edit in this record.
[P88 source and P89 followup evidence](validation/inventory-native-scan-p88-2026-11-17.json).
<!-- /LHO-INVENTORY-NATIVE-SCAN-P88-20261117 -->

<!-- LHO-INVENTORY-EVENT-WORKERS-20261117 -->
17 November: continue direct addon edits, preserving query freshness and
features. Reuse private workers/field lists and avoid the absent-set fallback
allocation; keep copied context sets fresh. Do not cache native facts or shorten
callbacks/deadlines. Treat the EBS count-only scheduling
repair as an intentional bug fix, separate from private closure reuse: an idle
flush must execute usable/text work, and later genuine full requests must recover
the texture pass. Preserve intentional equipment/form/power skips.

Keep initial failures and the dated65-check EBS pass; final ordering coverage is
74 checks per VM. Targeted functional passes establish their stated scope only.
Reload, loaded adoption and broader native performance acceptance remain pending.
[Current source and evidence](validation/inventory-event-workers-2026-11-17.json).
<!-- /LHO-INVENTORY-EVENT-WORKERS-20261117 -->

<!-- LHO-PENDING-READ-RUNTIME-20261117 -->
17 November: follow the user's instruction to edit actual addon Lua. Permit
pending-read walk reuse only behind current owner, input and published-state
checks. Compare classification revision before the scan's own cache reset so
external metadata invalidation cannot be mistaken for that reset. Preserve
late metadata promotion, public replacement fallback, reentry, generation and
listeners. Self-followups use ordinary pending reasons; only a fresh getter
renews read demand, retaining capped retry behavior after consumers stop.

Keep the ItemClass change to one private protected worker. Desktop checks
support these contracts, not native CPU/FPS, loaded adoption or broader workflow
acceptance. [Sources and evidence](validation/consumable-pending-read-runtime-2026-11-17.json).
<!-- /LHO-PENDING-READ-RUNTIME-20261117 -->

<!-- FALLBACK-INPUT-WORK-R63-20261117 -->
17 November: reject and remove BOTH R63 trials after their declared CPU
limits failed. Combined420e stopped after24of48cells at Lua54 warm median
CPU+8.143%; scalarD558 stopped after6of48 at Lua51 cold medianCPU+9.677%.
Allocation savings and functional passes do not override these rejections.
No retiming or threshold relaxation; preserve every completed sample.

Restore exact Core4fa7c12a/LF110827 and testad065; OtherE790 remains. The
production cold/warm/changed models had zero leaf-cache hits, so CF57 or model
aggregate hits cannot establish input-vector admission or native gain.
[Both dispositions and source identities](validation/fallback-input-work-r63-2026-11-17.json).
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
16 November P75/P76: applied two measured private callback hoists after12first functional and44fixed cost jobs; no validation, map ownership, query/callback/paint work or cadence shortcut. P75 normal CPU-50%; P76 countOnly-25%/mixed-15.38%, with populated identity+4.545%(2losses/1win) retained below the declared5% gate. Allocation paired differences136B/check and40B/merge;54window floors and startup cost remain. Ordinary native-pcall/module-environment contract only, not arbitrary callback-retaining pcall/setfenv/debug overrides. No native test/input/reload; USER HOLD until explicit release. Goal ACTIVE offline. [Evidence](validation/inventory-private-callbacks-2026-11-16.json).
<!-- /LHO-INVENTORY-PRIVATE-CALLBACKS-20261116 -->

<!-- LHO-AUCTION-CLOSED-DEFINER-P73-P74-20261116 -->
16 November (`LHO-AUCTION-CLOSED-DEFINER-P73-P74-20261116`): USER HOLD: no in-game tests, live queries/testing captures, game input, jumps or reloads until the user explicitly permits them. Offline goal ACTIVE; generic continuation or offline success never releases this hold.

Accept P74 only within its proven scope: actual defining closures validate once, selected ordinary lookups stay ordered, and foreign callbacks receive fresh5/9options. Preserve the foreign CPU regression, startup cost and two-point GC limits. P74 applied the three tested Retail files at19:46:44UTC. The later19:52:16UTC read-only check matched all15 files across five primary installs; other folders have independent identities and updated externally between observations. Propagation mechanism is unproved; Root performed no manual sync. Loaded-client adoption remains unverified. Extra beta is unchanged/older and not certified. The initial linked-copy assertion is preserved as a bookkeeping failure, not a runtime/model defect. Keep P73 baseline-only and P72 rejected; do not relabel old trials. [Exact sources, proof and limits](validation/auction-closed-definer-options-2026-11-16.json).
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
16 November (`LHO-AUCTION-BASELINES-P70-P72-20261116`): Reject P72 without application or another variant: all three owned CPU pairs regressed and median+17.3913% exceeds the5% rule. Preserve conditional GC savings, foreign+4.1667%, startup memory and the R1 setup failure in evidence. P70 shows real UI reachability, not user prevalence; cap0 must retain free owned craft and public freshness/error boundaries. P67 attempts1g/1h/1i sent zero packets and never staged/armed the observer;1g preinput reason remains unknown,1h was rejected before journal, and1i user logout countdown was left untouched. Goal ACTIVE; own holds remain and any native attempt requires fresh client/world/closed-chat/ownership checks. [Baselines, rejection and native limits](validation/auction-limit-live-options-2026-11-16.json).
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
restamping or replay. P54 packets are frozen; no observer/Food action has run.
User says the other WoW test finished/chat is free; guarded root-owned input
continues. no_jump/craft_hold/INPUT_HALTED stay held; no real jump is claimed.
At that earlier checkpoint P55 bank-row reuse was read-only/no candidate;
the newer P55 milestone records application. Earlier Index/Prof changes remain.
Pause cancels work/jumps first. No generated gates, manual sync or publication.
[Exact sources, regressions and pending native checks](validation/syndicator-partial-oldrows-2026-11-16.json).

15 November `LHO-INDEX-FLAGS-20261115`: apply R2 e1cdab75 as a bounded
allocation/live-query optimization after the frozen402script/1091syntax gate;
retain R1 unapplied. Intentionally duplicate the eight-region private sum to
keep the671byte public GetCount baseline body identical and avoid the R1 direct
path regression. Preserve both capability reads, native getter lookup order,
late option mutations, public pointer/override/hook fallback and fresh options.
Strict zero-table and85case/530check fixtures retain this boundary;17consumer
pairs preserve requests, results, settings and cadence. H37/H38 plus five pinned
callers support the implementation decision; other-client native hook behavior
is still unverified. Desktop real-Core CPU improves32.47% and fallback4.62%,
but direct CPU differs by one tick/+0.18% elapsed and whole warm/cold pairs are
mixed(cold CPU+3.92%/wall+6.47%). Do not claim stable whole-event/native gain.
R1's440B/query allocation result is not a fresh R2 GC measurement: allocating
bodies are unchanged and the strict R2 constructor budget is zero. Keep current
integration separate from the frozen gate: latest408scripts/1097syntax PASS
has zero failures but full/Lua sourceStable=false after concurrent Bars/binding/
test/verification changes. Do not fix or rerun those owners inside this slice.
Existing SYNC delivered all five on-disk copies; no manual sync. I42's current
Index15/139 stack now establishes Forever R2 source-line adoption, not a loaded
function hash or all-client certification. Preserve I41d as queued203chars with
guard abort/unknown execution; debug boolean invalidates its getinfo payload.
I40 raw before/after medians1.6094999909401/1.3808999955654ms per100 queries
have different counts0/176 and scene context despite CVars0/120/30. Treat them
as UNMATCHED descriptions; compute no gain percentage or native FPS benefit. Next count work remains
source-only until an authority-preserving baseline resolves restock fallback
and charge-signal boundaries; valid default zero already makes one native
attempt. Do not revive rejected R15 hoist/R28/R18 or edit external providers.
Stop G43 at one of three planned raw FontString pairs:0.36879998445511 versus
0.34950000047684ms/1000 is an unproved tiny best-case margin. Do not turn this
into an actual SetCount candidate; secrets/hooks/format costs remain untested.
Two hidden Frame/FontString pairs have no verified cleanup; later loading screen
and chat reset do not prove reload. R4 idle worker48720/r4b launched17:42:02UTC
with seven presence-only craft_hold guards;21cases/43checks pass. R4b stopped18:20:24(stale heartbeat),
host absent18:26; exact R4 restarted18:27:03 as r4c/PID33168 under root-managed
craft_hold after captured57s cast/queued work. Root maintains heartbeat; no
movement or automatic future queue awareness is claimed; guarded in-game tests
are now explicitly permitted by the user.
Reject unconditional deletion of the two initial SetItemUnits calls before
ApplyPotionReplacements: four scenarios/18checks per variant contain two
canonical matches and two constructed public-extension counterexamples with
changed final data. No installed extension is asserted; no apply. Q44's single
public GetRows result4rows/1zero/3.095900028944ms does not prove synchronous
scan frequency, CPU/FPS, saved-target completeness or six-times cost.
Keep17:56:29 manual2 and18:00:11 combat-field3 disk aggregates separate;
neither is loaded memory or an explanation of Q44 zero. Q45a-d pre-input
stops remain historical. Later Q45e4true/no visible Z45 establishes its current
existing-row context only; it neither identifies/disproves Q44 zero nor links
epochs. Preserve normal PurchaseLimit/default initialization caveats.
Trinket's sealed40scenario baseline shows hidden/unbound already parked and a
narrow raw-key/no-target residual with zero per-tick binding-metadata reads.
Treat counts as source/model evidence only; no accepted/applied candidate or
native CPU/FPS claim. Trinket R1 and R2 are REJECTED/no apply: R1 loses four resolver/reentry
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
[Exact decisions and evidence](validation/inventory-live-count-flags-2026-11-15.json).

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



15 November instant-command and profiler-signal boundaries:
the user's latest instruction supersedes intermediate blank/draft waits for
the reviewed fixed print. Retain a fresh closed-state certificate and rapid
guarded open/29-character/submit chain, then inspect NEW output. R8's immediate
visual reply and its later stale CLI annotation refusal are distinct facts:
do not relabel the submitted journal as accepted or replay/restamp it.

Treat P36's1685 as one raw CountTimeOver50Ms value with unknown epoch/window.
It is neither elapsed milliseconds nor a bounded CPU/event/causality result.
Keep settings, observers, source and items untouched by this diagnostic route.
The count-write proposal remains a lead until real producer/recovery fixtures
and matched measurements justify a candidate; extra getters may regress work.
Qualify observer gaps using loaded Init/Containers/Builtin/Watch, not unloaded
legacy FluxInv_Events. Preserve the active Inventory/EBS frame-burst goal.
[Evidence and exact distinctions](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November inventory-spike attribution and command transport:
retain R34 as a source-work baseline, not an approved cache or slower retry.
Preserve settings/alias/error/timer freshness and the existing 200ms cadence.
Whole-client R3/R4 peaks warrant attribution; their differing foreground and
workloads cannot establish a FluxUI before/after gain. Treat final ETW loss as
unverified despite acknowledgement zeros, Dropped=0 and no positive producer
loss warning. Use the exact pinned v1 formatter and numeric checks for units.

Use R6 only for its fixed harmless command until another concrete payload is
reviewed. Fresh blank/exact/NEW-output images remain required; preserve old
journals, cancellation and owned locks. Permit other foreground apps to switch
while WoW stays background under the user's permission. WoW foreground mode
changes require fresh observation; foreground retains LastInput/all-key checks.
Native success certifies background fixed-print delivery only, not arbitrary
commands, profiling, addon source adoption or foreground operation.

Scope no_jump to complete chat/script batches per the latest user instruction.
The idle-only activation exception and three-minute schedule remain; do not
overlap jumps and input. Keep INPUT_HALTED and old blind senders stopped.
The external Events V2 proposal is not deployed and excludes raw inventory/
vendor/scheduler paths. Investigate whole-addon expensive-frame counters before
choosing instrumentation; do not report partial service spans as full attribution.
[Current evidence and limits](validation/lag-hotspots-native-attribution-2026-11-14.json).

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

15 November 09:17:18 UTC R33 (`LHO-EBS-RANGE-WORK-R33-20261115`): apply only
Paint011f126a→9c962912, one durable test and its project-local support fixture.
The two private helper hoists retain dynamic range methods, captured owner/unit,
reentry, raw error/return behavior, item marker order and0.18s cadence. No cache,
new event/frame/timer/API, option, saved-data root or omitted native query.

Full395/1083, focused165/1095, stress86872, independent80/640 and durable40/295
pass before apply; baseline durable has10 intended allocation failures and six
harmful controls are rejected. The fresh checkpoint has2838 files/126 settings
metadata;15 new identities match five installs. Direct232B/probe and mixed
2264→1104B/sequence allocation evidence is desktop-only. Keep the absent-target
elapsed regression (+.012us/call;0/5 faster), distinct whole-child quantized CPU
and all raw ranges. No native frame-spike/FPS or source-adoption acceptance.

Inventory/EBS expensive-frame/burst work remains primary. R32 legacy Usability
is unloaded; no optimization. Vendor cold-retry work remains unmeasured/no fix.
Supervised-chat BEGIN eligibility failed before keys/journal/lease; no observer
was installed. INPUT_HALTED/root hold remain; no new native control follows.
[Exact evidence and remaining scope](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November 08:41:06 UTC R31 (`LHO-COMBINED-BAG-OWNERSHIP-R31-20261115`):
apply only two same-owner predicates in FluxClassicCombinedBag8da75582→e089ec5f.
Repin checks local host visibility only after finding a parent mismatch; ReturnItems
acts only while the item is still parented to that private host. This fixes hidden
historical-host repinning and foreign-owner reparent/anchor clearing. Active scope
is Era/Anniversary; Retail/Forever/MoP exit. Layouts, cadence, current adopters,
bindings, assets, settings and saved roots remain. No new frame/event/timer/API.

Durable18/584, independent88/796, targeted10/312 and full394scripts/1082syntax pass;
baseline durable has10 intended failures and three compiled harmful controls each
fail2 checks. Five-bag fresh-open work remains12 passes/640HostFor. Per selected
foreign item, GetParent stays1 and incorrect SetParent/ClearAllPoints drop1→0.
Normal Repin adds0 IsShown reads. There is no CPU/heap/FPS measurement or native
Era/Anniversary acceptance. A verified2,835-file source/history checkpoint and
126 settings metadata entries precede application; no private settings were copied.

R28 stays rejected after200/790 unreadable/cold recovery regressions. R29 R2 is
not applied generally: ordinary elapsed time+10.74%/+13.61% in all five pairs outweighs a
conditional heavy-revocation model result; native secret/error proof is pending.
Keeping all rank calls while omitting unrelated winner pointers is also unsafe:
later callbacks can mutate/remove an earlier winner before final matching. That
variant stopped before coding. R30 confirms existing batching (37 checks); no edit.

Idle-jump permission is approved, but the new crafting/chat deferral requirement
keeps root-owned R3/PID44368 held until a reliable fresh observer exists. Preserve
INPUT_HALTED and the owned no_jump token; no new native input/source-adoption
verification follows from this application. The full performance goal stays ACTIVE.
[Evidence and remaining boundaries](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November 07:12:24 UTC R26/R27 (`LHO-CAST-PASS-R26-20261115`,
`LHO-CAST-NAME-R27-20261115`): apply the three-owner slot-pass error cleanup and
the separate private live-name closure hoist. A paint/Effects error after Begin
previously skipped End and could return a cached old action spell until a later
Begin/End. The new private serial/hoisted finisher disables only a pass opened
during the failing invocation and rethrows the same error object; no public End
callback is added on failure. Normal single-active semantics and update order
remain. The error stack/line representation can change; painted state is not
rolled back or retried. The name helper retains dynamic native/formatter reads.

R26 durable54/329 and independent69/469 checks pass; baseline has42 intended
freshness failures and harmful unconditional/omitted cleanup controls fail.
R27 durable60/181 and independent150/610 per source variant pass with exact
semantic traces; three harmful getter/normalization controls fail. Combined
composition and full desktop393/1081 PASS precede application. The dated source/
history checkpoint covers2,833 files and126 settings metadata entries; no private
settings were copied. Two durable tests and a one-line desktop extractor update
are retained; original LF restored to final6d7ecf35 after incidental conversion.

Keep R26 costs separate from R27 savings: ordinary modeled cleanup adds about
0.1–0.2us/call; the active-Effects extra1,632B post-GC envelope is fixed across
10–10,000 calls. The helper-only hoist changes104→0B/query and CPU medians
16–38% across five alternating pairs per shape, not native/whole-event/FPS gain.
The first external full run342/51 is preserved; short-path read-only fixture
redirection and the retained nine-assert extractor produce393/0 in the second.
Native R26/R27 loading is unverified after a partial-editbox reload incident;
two targeted Escapes restored the expected world; input stays halted. A reload
may have occurred, so no claim of definitely unloaded source is made. No cast
ran after application. R21 live vendor acceptance and full LHO goal remain pending.
[Exact identities, samples and native limits](validation/lag-hotspots-native-attribution-2026-11-14.json).

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

14 November — one shortage scan on AH tab opening; passive updates only repaint (AHR-105/106).

Opening Restock is the start action. Prepare only shortages, preserving old-AH
per-item behavior. Keep the explicitly requested modern full-price scan separate.
Bag/mail/profession events cannot restart completed work, discard an owned query
or replace a pending choice. Resume only an existing initial stock-loading wait;
matching purchase receipts advance preparation. Genuine preference edits may
replan once. This supersedes earlier filled-tier automatic discovery on opening.

Three per-character AH upgrade prompt choices default to healing on, mana on and
bandages off. They do not disable current-tier purchases or craft comparisons.
Keep disabled-kind stale acceptance guarded. Reuse native controls; compact Keep
and Block labels fit independent hit areas and avoid rewriting enabled states.
76 affected scripts/82 syntax; 440 checks/20 profiles; 11 harmful controls PASS.
Native UI/input/performance remains pending; meters excluded by user ownership.
[Evidence](validation/auction-passive-refresh-2026-11-14.json).

14 November — potion tiers compare minimum restore globally (AHR-104).

Use the verified minimum for healing/mana potion health, mana and effective tier
values. Keep separate maximum metadata and the existing food/water/bandage policy.
Upgrade discovery still asks; purchases still need a distinct player press.
Migrate existing refs/vendor records and saved thresholds from canonical parsed
facts, with per-kind Basis markers. Defer unknown values and preserve their saved
records; do not promote a maximum-only observation as a known minimum. Retain
potion cached text/axes through live-tooltip gaps without changing other cache
types. No item-name/ID tier catalogue, new API or configurable default.
74 affected scripts/79 syntax files; 510 checks/50 profiles; 10 harmful controls PASS.
Native minimum-ranking acceptance remains pending. Meter work belongs to its
separate agent. [Evidence](validation/potion-minimum-restore-2026-11-14.json).

Full validation: 365 scripts and 1053 Lua syntax files PASS; complete current Lua manifest verified.

14 November — restore meter choices without rebuilding native menus.

`METER-CONTROL-RECOVERY-20261114` supersedes only SECRET-UI-20261113's meter
capability withdrawal. Keep its tooltip ownership fixes and the later header
alignment fix. Explicit layout/type/tab/setup choices select original existing
native menu entries and default displayed panes to Current. Geometry/background
work preserves later manual segments and all combat history. Missing windows use
the original native New Window entry; Threat remains independent.

Require clean cached descriptions, methods, callbacks, data and New Window text.
Do not generate/register/open native menus, use DropdownButton Pick, call private
configuration setters or copy native responders/data. Unavailable provenance
refuses selection with setup feedback. Source review and pinned replay support
this narrower path; they do not certify the native secure VM. Existing direct
implementation/user-native testing choices continue. 476 control checks, 12
focused scripts, both pinned menu replays and 7 harmful controls PASS. Native
combat/taint/controller/pixels/performance remain pending.
[Evidence](validation/meter-control-recovery-2026-11-14.json).

14 November — compact AH choices and preset-first ordering (AHR-102/103).

Use two rows of ordinary native action controls in a 44px candidate card; move the
large name/effect/price block into the candidate/action tooltip. Keep all 3 explicit
choices and existing purchase checks. Sort using preset/source metadata, including
merged manual targets and virtual proposals, then names/IDs within each group.
Map proposals by row identity so sorting cannot resolve another item's choice.
Auction-focused checks,1053 syntax files and 8 harmful controls PASS. Meter work
belongs to a separate agent and is excluded from this task. Native layout,
fonts and directional navigation remain pending. [Evidence](validation/auction-compact-upgrades-2026-11-14.json).

14 November — preserve the verified source and require individual upgrade choices.

Use inline Upgrade / Keep current / Blacklist controls independently for healing,
mana and bandages. Accepting a tier creates no explicit Junk mark; global automatic
junk protection is separately configurable per kind and defaults on. The user
confirmed that manual Junk wins. Apply manual exclusions and the default-on,
case-insensitive `discolored` healing substring rule through the existing Best,
button, AH and tier owners. The keyword is explicitly requested; no tier list.

Recover the unrequested 08:32 source replacement from the immediate verified
checkpoint using guarded hashes, preserving the new work and all before versions
externally. Restore the load list rather than masking nil Skin. Writer unknown;
do not blame or disable outward sync. No branch/reset/commit/settings rollback.
Current acceptance: 365 scripts/1053 syntax and 22 harmful controls PASS. Native
meter/threat appearance observed; options/inline actions and other native checks
remain pending. [Evidence](validation/auction-inline-upgrades-2026-11-14.json),
[recovery](validation/flux-source-recovery-2026-11-14.json).

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

9 November native bag item targeting (BAG-ITEM-TARGETING-20261109): cover the
general source-item → cursor → destination-item flow after the user's crate
clarification. The native UseContainerItem stack identifies the final blocked
call, not the first taint writer. Preserve native interactions and protection
features until native evidence identifies the correction. Extend existing
opt-in metadata only; retain diagnostic roots and logging/profiler preferences.
Runtime fix/native acceptance remain open. [Scope](BAG_ITEM_TARGETING.md).

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

9 November nameplate quest progress: latest user anchor is TOPLEFT at the health
container BOTTOMLEFT,0,+4, with centreY -3 matching threat/level; stack multiple objectives downward.
Use existing Core/driver/options, Questie's active tooltip associations and public
notifications; native quest tooltip/log fallback when absent. No database or new
runtime files. Disable only Questie's world-nameplate marker via its own setting
and hide method; its other features stay independent. Default Questie artwork is
supplied locally with its source restriction notice, without publication. Secret
or unavailable mob associations stay hidden; modern instances skip lookup. User
chose direct implementation and local checks; native testing is theirs.
[Contract](19-nameplates.md#quest-kill-and-loot-progress--9-november-2026).


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

9 November repository replacement: user's explicit delete/recreate request
supersedes preservation of published ancestry for this one operation. Keep the
same URL and existing addon working folder; publish a fresh main snapshot with
DoctorFlux author/committer and no co-author trailers. Preserve old history,
uncommitted/untracked/ignored files and index externally. Preserve all licenses.
Install local metadata hooks plus read-only CI detection; do not promise a
GitHub account blacklist or protection against administrator bypass. Normal
future updates use main and never bypass the guard. [Policy](PUBLICATION.md).

Replacement verified: old repository ID1416752820, new ID1451123700; initial root
be90cdcc2f14 with no old parents and sole main. Contributor API returns DoctorFlux
only; initial identity workflow passed. The local old history remains recoverable
externally. Do not restore/push old refs or replace current files from that backup.

9 November focus input ownership: use the existing Restricted service's tested
native visibility route for focus/focus-target, keeping protected Show/Hide and
click regions under Blizzard during combat. Use native `togglemenu` for ordinary
unit frames; executing addon-written callback attributes had forbidden focus
responders. Do not patch native APIs or add a custom focus menu. Native generic
menus lack an arbitrary dependent-NPC category: user explicitly chose to keep
mini-frame callback menus and use existing native focus bindings/macros there.
Their callback Set Focus entry remains a documented restriction. No new gesture,
binding or reset; unsupported focus clients stay gated. Forever native checks
and user combat/menu acceptance pass; wider native coverage remains pending.
[Decision and regression scope](FOCUS_SECURE_VISIBILITY.md).

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
checks, five repeated scenarios and four harmful controls pass. Full validation
and source-copy evidence accompany the batch. Forever70862 public-save metadata
PASS; user reports the prior two-copy build worked. Final single-profile native
reload/persistence/save/combat/pixels and other native clients remain pending.
Keep WoW background; do not interrupt auction/mail/trade or gameplay. No profiler
change, native preset patch, commit or push. [Requirements/evidence](COOLDOWN_VIEWER_DEFAULTS.md).

8 November Edit Mode ownership (EDIT-MODE-NATIVE-20261108): use saved widget
anchor methods under existing editor/combat guards. Supersede the global spec
event opt-out; keep the legacy public helper as a readiness query. Restore native
selector alpha/click/motion when Flux unit ownership ends. Leave native profiles,
scripts, secrets and private aura tables intact. User-reported native success is
separate from loaded-source/taint/performance proof. New cooldown defaults must
preserve custom layouts. [Details](EDIT_MODE_NATIVE.md).

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

8 November universal mouseover (UNIVERSAL-MOUSEOVER-20261108): the user's
explicit preference keeps Focus/Self/cursor rules authoritative and applies
mouseover-first to Default/Target. This supersedes the earlier omission of
automatic native-client macro tails: native macros ignore the button's resolved
unit, so the existing compiler must emit compatible mouseover clauses and the
native modifier itself. Reuse protected click adapters and the existing Forever
probe; preserve native plain-action ownership, idle badge policy and deferred
combat writes. No CVar read in restricted snippets, API replacement, new hover
poller or forced settings migration. Range/LOS/cooldown rejection cannot trigger
an automatic retry. [Details](UNIVERSAL_MOUSEOVER.md).

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
separate the current-bag junk cutoff from remembered purchase thresholds. A learned
or affordable recipe is not ownership. Apply the cutoff to automatic age rules,
stored marks, pending upgrades, display and inferior sale availability; preserve
explicit lists, manual restock and food/water behavior. Cache candidates in the
existing tier cache, recheck live ownership/usability, and skip equal/lower-tier
count queries. This narrows the supplied spec's memory-based junk policy for
combat consumables under the user's explicit clarification; no settings reset.
[Contract and validation](CARRIED_COMBAT_CONSUMABLE_JUNK.md).

8 November stable owned grid buttons (GRID-STABLE-OWNED-20261108): use the
classifier's explicit negative cache for rejection; missing tooltip/pending state
alone cannot reject an owned potion. Keep a validated, positive bag latch visible
while selection refreshes; explicit modes and eligibility still take precedence.
Reuse existing count, selection and combat deferral services. This avoids adding
retry work or a time-based grace period that could retain real depleted items.
[Reproductions and boundaries](CONSUMABLE_CRAFT_IDENTITY.md).

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

7 November reagent ownership: actual spell reagent evidence controls Preset
classification. Preserve the existing shared target store, quantities and flags;
no separate preset database or destructive migration. Explicit rune names may
resolve item IDs before cache load; never infer a cost from the spell ID or
unreadable text. Identify Soul Shards by item identity, not the summoning spell's
name. Travel uses the existing reagent index and shared inline editor. Keep
flyout/cast/modifier behavior; single-destination right-click owns target editing.
Include known spellbook flyout children via the existing Core.Spell adapter,
select active overrides and deduplicate; retain legacy routes and add C_Flyout
table fallbacks without replacing any global API.
[Case](TELEPORT_REAGENT_RESTOCK.md).

7 November live aura slider follow-up: user rejected the previous slider
display and clarified that the main frames must be30% taller too. A user-owned
probe at1.45 showed capped12.1px icons; forcing0.50 through the actual scoped
refresh returned public scale0.4767 and the user confirmed normal icons shrank.
That proves prior native scale propagation. New UI exposes the responsive fitted
range with0.01 steps/current dimensions, preserves stored requests until selection,
and refreshes cached bounds without synthetic saved writes. Main heights now
multiply saved scale by1.3 (default43->56; saved1.0:36->47); width remains.
Canonical normal icons10x19.5 fit that height; duration fit and strict1â€“6 limits
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
maxDebuffs1â€“6 default6; demo counts remain separate. Strict mode retains only
HARMFUL|RAID on every original/tail owner. Exact4/5 across mixed categories uses
lazy clipped native row copies; no native child inspection or handler replacement.
Default native icon pools stay120/cell; both partial sides can add120 once, reused
and unbound while inactive. No new addon recurring work. 200 scripts/862 syntax PASS,
unchanged Lua corpus; five alternating regression pairs per aura/layout/preview
reject15 baseline runs and pass15 candidate runs. Native pixels, logical-visible
clip scheduling, combat/taint/casts and FPS remain pending on all5 clients.
Preserve unrelated work and profiler preferences; no commit/push or game input.
[Size/count record](validation/raid-aura-limits-2026-11-07.json).

7 November badge cooldowns: preserve existing scalar rules and return positions;
append public GCD metadata and use it only when timing is restricted. Unknown
restricted state keeps the badge visible. Do not read charge state or change
bindings, swaps, alpha/layout or proc art. Remove only the proven unused power
snapshot chain; live ghost feedback and its shared anchor helper remain.
Native probes use the original strict background guard; the attempted helper
change for other-app switching was rejected by automatic approval review and
was not executed. No approval bypass or foreground input.
[Case](UNIT_STATE_SECRETS.md#follow-up-badges-and-unused-power-snapshots).

6 November unit identity: test readability before branching, comparing or
formatting API values; cache readable GUIDs only. Keep prior public identity
through restricted samples, using existing identity events to invalidate swaps.
Power-cost watcher owns cast restoration, including pet replacement; Shared
resets health-loss before child paints. Do not add broad error suppression,
replace native APIs, reset settings or remove feedback. Unknown aliases never
select player-only surname behavior. Desktop safety models do not certify
native secret VM or explain the earlier random freezes.
[Case](UNIT_STATE_SECRETS.md).

6 November TacoTip ownership: fix the owning tooltip renderer rather than
adding a shared Backdrop/API workaround to FluxUI. External installed TacoTip
remains read-only by explicit user choice. No third-party edits are planned;
a SetBackdrop-only guard is incomplete because native resize still runs.
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
[Text scaling record](validation/raid-aura-text-scale-2026-11-06.json).

6 November aura clock correction: the user rejected the previous display:
duration showed ... and short buffs/debuffs had no swipe. New text uses plain
seconds then m/h/d, with7px preferred/6px fitted font from public sample
measurements on a separate hidden widget. The native cooldown starts visible
before sink registration; an explicit opaque base texture removes inherited
tint alpha. Existing transparency,3Ã—2 layout and aura filters remain.
193 desktop scripts/855 Lua syntax PASS with unchanged corpus; five alternating
pairs/case reject old source and pass the candidate. These are logic/style
contracts, not native glyph or swipe rendering proof. User was given an OOC
owned-widget diagnostic; actual C-widget result and corrected display acceptance
remain pending. Preserve all unrelated map/glow/spike-watch work/preferences.
[Clock correction record](validation/raid-aura-clock-fix-2026-11-06.json).

6 November aura duration follow-up: user confirmed a cooldown swipe over each
buff/debuff with remaining duration text above it. Raised intrinsic swipe
alpha0.3â†’0.75; centered9px outlined/shadowed timers; native labels use one
owned compact formatter when available. Readable timer text now sits above
the swipe and clears on timedâ†’permanent reuse. Alpha settings, icon sizes,
3Ã—2 blocks, eligibility and strict dispel filtering remain. No new frame,
ticker or timer owner; one cached native formatter object.
Final193 desktop scripts/855 Lua syntax PASS with all source hashes and
membership unchanged. Five alternating pairs/case reject the old display
and pass the candidate; raw outputs retained, no native CPU/FPS claim.
New native appearance/combat/taint checks remain pending. Reload and check
a timed buff/debuff plus a permanent buff; preserve the optional spike
watch/profiler preferences and all unrelated map/glow work.
[Duration record](validation/raid-aura-duration-2026-11-06.json).

6 November map ownership: clean up only discarded Flux provider owners;
retain native WorldMap owners and all available provider categories. Native
shared mixins and AcquirePin remain untouched. On canvases with protected
passthrough acquisition, defer only owned RefreshAllData, delayed bonus/quest
and ping work; use the existing Combat service with bounded latest ping args.
Refresh completion precedes ping replay; one failed owner reports normally
without dropping other queued providers. [Case](MAP_PROVIDER_LIFECYCLE.md).

6 November resumed at the user's request. Verified fresh external source,
all-ref history and on-disk settings checkpoint Random-spike-resume-20261106T170042Z
(1,660 actual files /190 settings, ZIPs and bundle verified). New Forever process
and exact window were verified; no active watch and live scriptProfile=0.
Normal Map tab activation changed shared native pin methods from secure to
_FluxUI tainted. Meter tab restored; no FPS or causal freeze claim. Fixing
owned-provider detach leaks first, then reviewing restricted pin ownership.
[Native baseline](validation/map-provider-native-baseline-2026-11-06.json).

6 November pause boundary: honor the user's pause; preserve local main,
all concurrent changes, native evidence and profiler preferences. Resume the
map ownership audit before changing its AcquirePin guard. Do not suppress
protected calls, mute native methods, discard pins, or claim that a nearby
map error caused the earlier gap. No map runtime patch has been accepted.

6 November Forever badge combat paging: prepare proc aura slots on every
badge position of a proc-capable bar slot even when the saved reverse badge
does not name that spell. Let prepared Retail alert art extend beyond the
corner SlotFrame. On badge show/hide, mask or reveal that art from the
published face. Dormant-row badges are visual only; in combat, fill their
spell/item paint fields directly and leave protected action attributes alone.
[Case](FOREVER_SAO_GLOW.md#badge-handoff-and-combat-row-icon-follow-up-current).

6 November random-spike attribution: retain the normal event/ticker/scheduler
owners and attach optional bounded timing observers only while watching.
Preserve existing traces and diagnostics; do not replace global APIs, force GC,
suppress reporters, or equate nearest profiler ticks with exact causality.
Count bursts of small callbacks without summing overlapping inclusive spans.
Global Lua heap changes alone cannot establish a leak. Preserve the user's
choice to leave automatic native Current selection blocked. See
[RANDOM_SPIKES.md](RANDOM_SPIKES.md).

6 November Forever SAO face paging: keep Blizzard's secure aura slot on every
potential main/mini/badge destination prepared outside combat. The existing
column and Extra Button face owner controls only container alpha so the Retail
art follows the displayed Arcane Missiles action during a modifier or reverse
badge swap. Invalidate candidate scans when action slots or programs change;
do not set unit, parent or shown state in combat. Native handoff pending.
[Case](FOREVER_SAO_GLOW.md#mainmini-and-badge-handoff-follow-up-newest).

6 November Forever SAO combat glow: use Blizzard's secure AuraContainer
`AddAuraShownAnimation` to drive the Retail alert flipbook for SAO's 400589
effect, which has no Forever button entry. Resolve button identity and create
the filtered slot outside combat; keep other SAO/native proc paths. Suppress
the old readable 400589 fallback after slot preparation so it cannot leave
post-combat art behind. Native acceptance remains pending.
[Case](FOREVER_SAO_GLOW.md#secure-auracontainer-button-animation-candidate-latest).

6 November consumable follow-up: retain public helpful aura additions by
instance ID so an aura event can change the selected item even when a wrapper
declines the readable index scan. Remove observations on explicit removal or
expiry. Use weapon enchant and player inventory events for temporary enchants;
read the modern paper-doll API when the legacy global is absent. Force a
protected action rewrite only for a selection change and only outside combat.
Native acceptance remains pending. [Case](CONSUMABLE_REFRESH_TIMER.md#aura-and-weapon-enchant-follow-up--6-november-2026).

6 November consumable aura advance: force an immediate selection update only
when a player aura changes the preferred displayed item. Retain coalescing for
unchanged selection and defer protected writes in combat. Fall back to ordinary
`UNIT_AURA` registration when unit-scoped registration fails on older clients.

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
Native icon pools increase80â†’120 per full cell for native category ordering;
refresh remains bounded. Other clients and native taint/combat/performance
acceptance remain pending. No further runtime changes follow acceptance.
[Exact follow-up source/check record](validation/raid-blizzard-aura-followup-2026-11-06.json).

6 November Well Fed follow-up: preserve the existing buff-equivalence and
refresh-threshold rule. Use a direct helpful-aura index lookup only when the
shared wrapper declines a readable aura, and reuse a discovered public spell
ID. Keep secret aura durations unnumbered; do not invent an expiry. Native
validation remains required for each installed client.

Final border preference: the user requested the same textured bronze as
HealKit after rejecting the plain matte candidate. The final renderer uses
original Blizzard8036209 gold bands at0.85 brightness with normal blending,
excluding dark padding. Rounded caps appear only on exterior grid corners;
shared separators have one owner. Earlier matte validation is historical.
The latest full validation fingerprints cover this native-art implementation;
native visual/secure-input/taint/performance acceptance remains pending.

6 November party/raid rewrite: the HealKit-style candidate retains outer dimensions,
chat docking, reverse group columns and Flux Binding, with the user's later
connected HealKit-style bronze borders,4px vertical overlap, horizontal0 gap,3Ã—2 buffs right /
debuffs left, visible timers/swipes,70% aura transparency and scoped0â€“100% control.
Names are10px; role12px precedes percentage; leadership/loot/marks have their
own layer. Power base isÃ—0.8. Members follow native INDEX/ASC order. Native
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

6 November explicit user decision: preserve every native feature and leave
automatic Current blocked. Freeze the Current implementation; do not add a
custom renderer, private/native writer, reset, automatic setting or manual-setup
completion claim. METER-DEFAULT-CURRENT-01 stays OPEN against the supported API
gap. Reopening implementation requires new user direction and supported evidence.
The successful runtime API/CVar inventory corroborates the source audit but does
not prove a loaded-source fingerprint, taint cleanup or combat acceptance. Keep
the assistant's corrected nil-help diagnostic error separate from native errors.
[Current scope](METER_STANDALONE.md#automatic-current-requirement-and-supported-api-gap).

6 November automatic Current scope: manual selection is not accepted as delivery.
Keep METER-DEFAULT-CURRENT-01 OPEN for all existing and future panes. Rechecked
source pins expose no supported automatic session/default route; do not restore
the native setter that already tainted fields or try another call wrapper.
A replacement renderer is not an equivalent solution while source GUID secrecy
and query restrictions prevent a promise of native combat drilldown. Do not
remove those features or substitute a reduced renderer without user agreement.
Preserve native data/history, current appearance and controls. No runtime change
or new native experiment was justified by this read-only audit.
[Evidence](validation/meter-automatic-current-capability-2026-11-06.json), [scope](METER_STANDALONE.md#automatic-current-requirement-and-supported-api-gap).

6 November native VM rejection supersedes the bounded-call experiment. Its
selection changed1/1/1 while native fields acquired Flux provenance, then ordinary
native icon/timer refreshes failed on secrets. Remove the entire operative native
call/preflight path; both legacy test commands now report UNSUPPORTED without an
operation. Do not retry through another wrapper/barrier. Public API presence,
clean original function metadata and desktop guards did not prevent data taint.
Automatic Current remains unsupported/OPEN; native UI owns the session choice.
Reload cleanup is required, without resetting sessions/history or treating synced
disk files as a native taint pass. Safe full166/823/unchanged sources passes;
the reload was refused before input, so loaded cleanup remains pending.
[Evidence](validation/meter-current-live-checks-2026-11-06.json), [safe manifest](validation/meter-rejected-current-removal-2026-11-06.json).

6 November native meter correction: the explicit pasted status says Overall
for Damage and Healing; it overrides the earlier ambiguous Current reply.
METER-DEFAULT-CURRENT-01 remains OPEN for every existing/future native meter.
Ordinary rendering/layout must keep native data/configuration ownership. The
optional user-invoked `/fbm currenttest` is a separate bounded permission
experiment using the original native method/public call boundary after build,
combat, function-owner and field checks, then re-reading configuration/provenance
and BugTabs. No automatic default, callback privilege claim or reset is inferred
from the API's presence, scratch metadata or desktop tests. Native output pending.
Keep title anchors/baselines unchanged, put the timer after the public heading,
pack14-unit header controls/art and hide Minimize while embedded; restore the
original presentation on release. [Scope](METER_STANDALONE.md#threat-timer-and-current-view-diagnosis).

6 November Forever glow revision: use the current Retail proc flipbook on
Forever when its atlases are available, following the user's updated visual
preference. Pre-acquire on secure buttons OOC. For Forever only, SAO and native
proc callbacks paint immediately in combat; ordinary refresh and other clients
retain their existing batching. Keep the Classic LBG path as a capability
fallback. Native acceptance remains pending; see [evidence](FOREVER_SAO_GLOW.md).

The first live readout showed no SAO screen-hook calls despite a visible
overlay. Use SAO's global `SpellActivationOverlayAddonFrame.overlaysInUse`
for the source-backed Missile Barrage association on player UNIT_AURA and a
coalesced next-frame check. Keep the modern glow frame shown but transparent
between procs, since combat `Show()` on its secure-button child may be blocked.
This candidate still requires native verification.

The live SAO frame list was empty during the visible proc. Follow Forever's
source-declared native `SPELL_ACTIVATION_OVERLAY_SHOW`/`HIDE` events for the
missing Missile Barrage button association, with 400589/Arcane Missiles rank
mapping. Keep an active event marker when SAO has no overlay-list entry;
otherwise the empty list incorrectly forces `Want` false. Live event payload
and button rendering remain pending.

Installed SAO uses secure AuraContainer slots for Forever secret overlays.
The first private-table hook attached zero buttons in the live client. Read
the registered static 400589 `includeSpellIDs` filters and AuraButton frames
from the global Blizzard AuraContainer slot registry instead. Hook their
OnShow/OnHide edges OOC; do not inspect secret aura values or replace native
slot logic. Native acceptance remains pending.

6 November Forever combat button glow: use SAO's resolved screen overlay
show/hide as the combat-readable trigger for its Forever Missile Barrage effect,
which omits a button assignment. Keep the general SAO AddGlow/native glow
routes for all other supported buttons. Treat unreadable combat icon values as
unknown for a known spell ID, while requiring a readable match to retain a
nil-ID face. Keep LibButtonGlow artwork/animation, which matches installed Era
SAO, and do not modify SAO or saved settings. The first global-name hook missed
SAO's cached private-table calls; hook the table methods instead. Subscribe
standalone Extra Buttons to shared glow changes on their existing eval lane.
The global-hook candidate failed the user's combat retest; the corrected
private-table candidate also failed and left a stale glow. Add global low-level
SAO screen show/terminate hooks, which cached ShowAllOverlays looks up at call
time and which do not need the private table. Use SAO's live overlay/fade state
when captured to override stale markers. This candidate's native combat and
clear acceptance failed again for combat glow. Prepare and retain one LBG frame
per Forever secure Flux button out of combat, then play/stop that same Classic
animation in combat without child creation, parenting or anchoring. Keep
prepared frames on their own button through paging and skip the birth animation
on the destination. Native combat, clearing and startup-memory acceptance are
pending for this candidate.
[Evidence](FOREVER_SAO_GLOW.md#combat-button-glow-correction).

6 November timer/session correction: include Threat in the same physical
top/left election as native panes. Forward native formatted timer arguments
opaquely into one owned FontString; no text/duration inspection. Threat-only
time is observed current combat from its existing poll, with unknown-start and
history limits. Report actual Current/Overall/history/unavailable; native UI
owns the choice and no private setter/reset is restored. The user confirmed
both meters now use Current; agent enum/two-fight/reload checks remain pending.
The timer must sit immediately right of its title without moving the title;
measure only public heading width out of combat, never actor/native value text.
A sandbox-empty process list does not prove a desktop
client exited; verify host process/window separately. Do not retry native clicks
from stale view coordinates after the layout changes.
[Scope](METER_STANDALONE.md#threat-timer-and-current-view-diagnosis).

6 November Forever SAO follow-up: user testing rejected the renderer-only fix.
SAO 2.8.9's Forever Missile Barrage effect has no button assignment although
its SoD/Wrath definitions glow Arcane Missiles. Add a narrow 400589 aura to
Arcane Missiles bridge, including ranks; keep generic SAO AddGlow and native
glow events for the rest. Refresh only on changed player aura state and guard
secret native values/IDs. Preserve SAO settings and source files. Native
verification remains pending. [Evidence](FOREVER_SAO_GLOW.md).

6 November native ownership correction: private native Lua setters are not an
AddOn-safe configuration API merely because they are callable. Remove Flux writes
to selected types/sessions, bar metrics, flags/locks/minimize and automatic native
pane creation; use existing native-selected panes and explicit setup messages.
Keep native controls available, preserve stored Flux layouts and report the
configuration gap rather than assigning misleading pane types. Preserve chosen
Current/Overall/history; never erase data or blindly migrate Overall to Current.
The single-timer requirement is presentation only: topmost then leftmost native
pane in physical screen coordinates, with stable fallback for unreadable
geometry. Preserve native time formatting/policy; no secret-duration comparison,
reset or secure-call shim. Header layout changes occur out of combat; combat
election changes alpha only. Writer/timer focused checks and the current
162-script/819-Lua full suite pass; fresh native acceptance remains pending.
[Current scope](METER_STANDALONE.md#current-native-configuration-boundary).

6 November Forever SAO glow: use SpellActivationOverlay's installed
LibButtonGlow renderer for Flux-owned proc faces on Forever, including bar,
Extra Button and badge surfaces. Keep membership from the private SAO hooks,
Flux refresh ownership, `skipBirth`, and pooled LBG hide/transfer semantics.
If LBG is unavailable, retain the existing template/LCG path. Do not change
Era/Anniversary paint, SAO files or saved options. [Evidence](FOREVER_SAO_GLOW.md).

6 November raid input: preserve Blizzard compact-frame parents, events and
scripts while Flux raid frames own the grid. Do not compare or save secret mouse
getter values, and do not infer split click/motion policy from a combined getter
when split methods exist. For an originally readable saved state that later has
a secret getter, pass the known setting directly to its native setter out of
combat; keep the existing Edit Mode and combat deferrals. An initially opaque
switch is left untouched because its original input policy cannot be restored.
This intentionally leaves that specific native widget's input unsuppressed until
a readable snapshot is available; native hit testing must be checked.
[Failure and scope](49-native-mouse-suppression.md#raid-secret-mouse-follow-up).

6 November appearance decision: replace the rejected flat approximation with
optional references to the player's installed Details WoW Interface assets.
Preserve the source atlas padding/density and body-relative nine-piece anchors;
do not compress a transparent 128-unit region into a 32-unit header. Keep stock
Friz titles and use the actual Accidental row font when it loads. Probe assets
through native texture/font setters, not addon metadata or file IDs alone.
Do not load Details/SharedMedia or redistribute assets. Missing references use
the previous Flux/Blizzard fallback. Data, wrapping, host/tab ownership, controls
and saved profiles remain. [Scope](METER_STANDALONE.md#installed-wow-interface-art-references).

5 November meter appearance: disable FontString wrapping directly without
GetText or secret-text inspection. Use shared Friz 12 titles/ArialN 14 rows and
consistent panel/row fills; normalize the texture's independent alpha so native
refreshes cannot multiply it away. Match the owned header to native 32 logical
at 0.8 scale (25.6 visual) and retain row geometry/pooling and native controls.
Reapply after native configuration plus one session UpdateBackground posthook;
source windows without that method get no fabricated hook. Released/Details
owners remain inactive. Preserve the player's current builtin 7 choice.
[Appearance scope](METER_STANDALONE.md#one-line-names-and-shared-meter-appearance).

5 November threat follow-up: establish a valid native presentation font before
SetText/SetFormattedText; do not catch and suppress incomplete construction.
Sort readable rows percentage-first with raw-value fallback, matching the
existing threat view. Out of combat clear rows and stop the update driver; keep
the wake events but perform no threat scans. Preserve opaque display/order and
the existing in-combat cadence. Compare quiet work with a separately font-ready
reference, since the published baseline aborts before that scenario can run.
[Evidence](METER_STANDALONE.md#font-readiness-and-quiet-threat-follow-up).
Latch explicit addon Hide before native enforcement because the old tab's onHide
runs before activeTab changes. Native and owned views share the effective-host
gate; only an explicit Embed/Show releases Hide. Keep this state addon-owned,
without changing Blizzard visibility or suppressing native timer dispatch.

5 November standalone meter: reuse the current threat adapter and a small shared
skin service. Recreate the accepted Flux Details look with Flux/Blizzard assets
and the client's ARIALN font; exact reserved art/font identity is not claimed.
Keep native combat-data initialization, duration formatting and menus native.
The independent threat pane belongs to Flux Content, not the native meter root.
Public threat can rank normally; opaque values remain display payloads in stable
roster order without invented ranks or ordinary Lua comparisons.

Retain native presets 1-6/default 1 and Details priority. Add opt-in threat presets
and allow three native panes plus one threat pane, preserving old saved layouts.
Hidden/Details handoff stops owned polling/events; one shared theme posthook is
permanent but releases inactive owners. Native paint/reload restores native
appearance after release; no native script-replacement or undo framework is added.

The user's checkbox report and explicit automatic-enable request authorize the
public damageMeterEnabled CVar to be enabled out of combat for this backend.
Do not write private visibility/cache fields, load Blizzard_DamageMeter from Flux
or manually dispatch native callbacks. Native visibility policy stays native;
the earlier core-only enabled-policy result is historical.
[Requirements and limits](METER_STANDALONE.md).
The enabled Meter tab must own native visibility from startup before the first
Embed; other Flux tabs hide native panes. A disabled Meter tab must leave native
policy alone. Late native anchor restore needs coalesced geometry-only repair
out of combat, with combat work deferred. Both boundaries pass desktop regressions; native reload/combat checks remain pending.

5 November wand swing visuals: use the equipped ranged wand's readable damage
school, not Shoot (5019), as the explicit visual mask for the existing cast
school renderer. Keep the item lookup on equipment/data events and the renderer
on its existing visible-only driver. Unknown, inaccessible and non-wand items
retain the ordinary swing fill. The Classic ranged-slot correction intentionally
changes a previously missed wand label/wind-up path; native cadence and pixels
remain pending. [Evidence](SWING_WAND_CAST_THEME.md).

5 November meter visibility ownership: leave `DamageMeter.visibility` to
Blizzard Edit Mode. Flux must not force Always through a setter or direct field
write; native combat updates read that field before comparing session duration.
Honor native visibility/enabled/content policy while retaining the Flux host/tab
boundary, layout, menus, selections and Details priority. Restoring the player's
native visibility choice intentionally replaces the old forced-Always behavior.
Keep timer/rendering methods native and preserve opaque combat values; do not
add a placeholder, global replacement, privilege shim or error suppression.
Reload before acceptance; remaining native configuration/Show boundaries require
real client checks. [Evidence and native steps](METER_COMBAT_VISIBILITY.md).

5 November minimap mail ownership: reuse the existing named Flux fallback after
the two existing native-frame choices. Do not adopt/reparent Forever's different
32Ã—24 native indicator or alter the accepted 20Ã—15 fallback, anchors, tooltip,
events or timing. The defect is resource ownership: repeated layouts and mail
events created more frames and listeners. A normal reload retires old instances;
the new lookup prevents their recreation. This correction is independent of
inventory provider selection. Native flicker, freeze, pixels and FPS remain
pending. Keep WoW background and external reference addons unmodified.
[Lifecycle record](MINIMAP_MAIL_LIFECYCLE.md).

Treat Retail missing tooltip data as unresolved and uncached, using the existing
uncollected paint until a later normal update has data. Do not add polling,
continuations or broad error suppression. This is a separate reproduced Retail
error-amplification fix, not native Forever freeze acceptance.
[Tooltip contract](AUCTION_COLD_TOOLTIP.md).

5 November provider row reuse: change only FluxUI's shared `FillFromList`.
Prepare complete maps, reuse an immutable previous per-index row only for exact
ID/count/link equality, and swap maps before the existing generation publication.
Keep provider facts, synchronous rebuilds, unchanged guards, callbacks and cadence;
do not reorder facts to improve reuse. Full-list validation/reconciliation remains
O(N); a temporary second index map replaces repeated normalized-record allocation
and old-map clears. Treat native progressive slowdown as unresolved. Preserve
newer consumable work and keep the external Syndicator patch proposal outside Git;
installed reference files remain unchanged until explicit authorization.
[Evidence and acceptance limits](PROVIDER_SNAPSHOT_ROW_REUSE.md).

5 November Consumables countdown: use the active buff's public expiration
minus the configured refresh threshold as the visual deadline for the button,
wisp lock, and config cell. Keep actual item cooldowns separate, and omit an
uncomputable numeric countdown when aura expiration is secret. Share the
calculation from `Consumables.lua`; do not alter buff eligibility or stored
threshold values.

5 November charge scanner: use the restock bank adapter's public
`ForEachOpenStack(opts, callback)` when scanning charge maxima for an open
bank. Include character bank and supported warband stacks. Keep the bag-only
result if the optional iterator is unavailable during partial load. This
corrects the user's native nil-call trace without changing saved data or
button selection policy.

5 November consumable editor: a verified item cursor ID is sufficient to save
the preset entry while metadata loads. Render saved configuration independently
of effective bag usability and before the live button update; display the
window before that refresh. Keep weapon compatibility limited to button
availability and preserve physical inventory/restock counts. No saved-data
migration or client-specific branch is needed.

5 November publication preparation: reuse the mail/auction scan jobs and their
existing per-frame budgets to prepare complete normalized maps before atomic
publication. Retain original equality, scan cadence, stable region objects and
Index results. Change the internal index-map identity only at completed changed
generations: the repository consumer audit found no cached inner mail/auction
index or public GetSnapshot exposure for those regions. This trades temporary
staging maps for removal of unbudgeted final copy/clear/fingerprint bursts; native
getters and downstream listeners remain separate cost boundaries. Buy-to-mail is
a distinct delivery and collection path, not an assumed direct bag update.
Keep external Syndicator's reproduced cold-post callback/retry defect separate
and unfixed here; do not wrap external globals or suppress its errors. Neither
finding attributes or resolves the reported whole-game freeze. No game input or
profiling; preserve background operation and settings.
[Flow scope](MAIL_AUCTION_REWORK.md),
[mail preparation](BUILTIN_MAIL_PUBLICATION.md),
[auction preparation](BUILTIN_AUCTION_PUBLICATION.md),
[external reference](EXTERNAL_SYNDICATOR_POSTING.md).

5 November mail/auction lifecycle: keep Blizzard responsible for posting, sales,
buying, cancellation and confirmation dialogs. Flux's built-in observer must
check provider ownership before a native owned-list query and latch its attempt
before native reentry. Reset that latch on close while preserving modern trigger
timing and cached-fact refreshes. Stop active mail jobs before an empty eligibility
scan, and stop only jobs whose owning module is disabled. Reuse wake cancellation,
settings notifications and existing cadence; leave an issued native command alone.
The reproduced failures justify these small changes, not a claim that whole-game
freezes are fixed. Preserve background operation, profile0 and enable flags while
candidate identity remains unverified in the replacement Forever process.
[Whole flow scope](MAIL_AUCTION_REWORK.md),
[auction details](AUCTION_QUERY_OWNERSHIP.md),
[mail details](MAIL_JOB_LIFECYCLE.md).

5 November built-in inventory follow-up: reuse the item-data service and its lazy
frame, coalesce native loads/callbacks, gate retry work at0.4s/earliest deadline
and cap active attempts at four requests/eight seconds. Keep bounded passive
ownership so late success and unreadable moved items still refresh their bags;
disarm idle work and retire it on external-provider handoff. Prune all-zero
derived character rows after partial bag repopulation, preserving live row
identity and other ownership facts. Stop invalid/repeated modern currency IDs
without a valid-list size cap or changing legacy iteration. These are reproduced
contract corrections, not proof of the native freeze cause. Latest native loaded
flags conflict with the user's re-enabled report; preserve flags and background
operation until clarified. Do not repeat heavy frame captures or profiler1.
[Item-data ownership](BUILTIN_ITEM_DATA.md),
[summary retention](INVENTORY_SUMMARY_PRUNING.md),
[currency contract](GOLD_CURRENCY_ITERATION.md).

5 November native mail readiness: use the public native command-pending flag in
addition to data confirmation, before advancing or finishing a worker. Reuse two
existing wake slots, retain configured minimum speed, stop busy waits at8s and
invalidate a completed foreign command's watchdog. API absence keeps prior
behavior. This corrects reproduced overlap, not the unmeasured freeze/crash cause.
[Evidence and tradeoffs](MAIL_NATIVE_COMMAND.md).

5 November follow-up: make actual raid child capacity the readiness gate and keep
native fallback until safe handoff. Reuse the existing configure/combat queues;
observe only owned frames and preserve native restricted attribute handlers.
Give mail progress/timeout wakes current-run and action identities, preserving
configured cadence and confirmation semantics. Read Copy/Forward availability
without assembling copy text. Batch Syndicator's progressive auction callbacks
inside the existing inventory bucket, before listeners, and use the appropriate
native owned-list event for empty refreshes. Keep direct rebuilds synchronous,
provider readiness/handoff and guild-bank/void scope unchanged. These reproduced
contract failures justify the fixes; they do not identify the live single-sale
stall, BugGrabber warning initiator or UNKNOWN taint writer. Do not suppress error
capture or edit third-party addons to produce a pass. The user reports Syndicator
disabled in the current failing runtime, so treat its installed 289 source as
reference evidence only. Investigate the built-in provider and fresh error history
independently; do not attribute the ongoing stall to the optional provider.
After the same freeze persisted after reload and the heavy capture was lost in
a reported crash, restore scriptProfile0 and the prior nil capture root; do not
repeat that capture. Return to background-only operation after the authorized
exception. Compare native command-pending mail checks across all five pinned
clients before the smallest further guard, and prefer narrower diagnostics that
avoid full EnumerateFrames. That guard remains pending implementation/validation.
[Source, regression and native acceptance limits](RAID_MAIL_AUCTION_FOLLOWUP.md).
[Native mail/auction comparison](NATIVE_MAIL_AUCTION_REFERENCE.md).

5 November: leave Blizzard meter rendering/Init and duration/visibility methods
native; preserve Flux tint with secure after-only hooks and actual selection
changes through native owners. Do not add another secret-field patch, sanitizer
or CVar toggle. Seed secure raid pools only after final capacity and effective
visibility out of combat; reserve bounded upfront resources and restore owned
shown states. The supplied UNKNOWN stack cannot identify a header or taint writer;
record the independent reproduced capacity bug without claiming native attribution.
[Evidence and acceptance limits](METER_RAID_NATIVE_OWNERSHIP.md).

5 November consumable targets: keep the preset and secure-button owners.
Read explicit weapon-type restrictions from the existing item tooltip service,
compare numeric equipped subclasses, and make the button's effective count
zero when no target is verified. Preserve physical counts for restock and defer
protected rewrites in combat. Unknown tooltip wording keeps the existing melee
rule and is labeled as undetected, so native item/locale acceptance stays open.
[Contract and evidence](CONSUMABLE_TARGET_DETECTION.md).

5 November: filter effective visibility in the existing shared Baganator traversal
and native overlay; retain all-button installation and provider ownership. Use
public tagged skin roots, not assumed numeric frame names. Reveal refresh runs
once after layout dispatch because Baganator assigns slots after showing roots;
merchant/BagShow debounce and unified native reveal cadence stay. No per-item
reveal hooks or ViewComplete polling. Default-overlay improvement is separate
from the normally bypassed Baganator path. Native hitch attribution remains open.
[Evidence, lifecycle cost and limits](HIDDEN_INVENTORY_WORK.md).

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

## 5 November 2026 - metadata event ownership

Global item-cache completion is not a container change. Keep the explicit
classification completion API intact, filter only automatic events to owned
records/requests, and resolve pending reagent names from the arriving record.
Retain full visible-item harvesting for real bag/bank/merchant changes. No new
API dependency or notification delay is needed. The desktop reproduction is a
justified optimization, not acceptance of the reported native Buy spike.

5 November auction metadata: global cache events no longer harvest all bag/bank
names or populate classification records for unrelated auction items. Requested
metadata, failed-load retry, static consumers, explicit completions and immediate
name-only reagent/restock updates are preserved. Five matched desktop pairs:
280,000 name reads and 2,000 container walks become zero for the unrelated burst;
230 checks pass, three mutants rejected; full 127 scripts/782 syntax pass.
The native Buy spike still needs attribution/acceptance across both providers.
[Evidence and next captures](AUCTION_METADATA_WORK.md).

## 5 November 2026 - auction refresh pool ownership

The user requested the immediate Buy spike on all clients, with and without
Syndicator. This authorizes the auction purchase path; guild-bank and void
callbacks remain excluded. Use the native active-row iterator, retain the
existing classifier and tint writes, and keep the bounded legacy UI path.
Do not claim this bounded traversal optimization fixes the reported spike: no
native capture exists. Gold refresh duplication and Syn mail publication remain
investigation leads, not proven major hotspots. See [evidence](AUCTION_PURCHASE_REFRESH.md).

## 2026-11-04 - built-in mail source and ownership

- Treat Postal v4.3.4 as a behavior reference. Its installed `LICENSE.txt`
  and CurseForge project mark it All Rights Reserved; do not vendor or adapt
  its files into FluxUI. Keep its saved data separate until a specific
  migration contract is established.
- Keep the native MailFrame and native sending/taking APIs. The Flux Open All
  control uses a single confirmed action worker and restores Blizzard's Open
  All when disabled. Add Flux-owned controls around the frame and use `Flux.Container` and the existing
  inventory character store for bag/alt facts. Do not change inventory's
  Syndicator mail-provider handoff.
- Use the fifth return of `GetInboxText` for invoice detection in each local
  Blizzard mail source mirror. Preserve the user's direct-implementation
  choice; native visual/interaction acceptance remains pending.
  [Evidence](MAIL_INTEGRATION.md).

## 2026-11-04 - combined Classic character bank

- Match the existing Era/Anniversary combined bag with a ten-column bank grid,
  a coin portrait, bank bag slot row and Blizzard's live purchase controls.
  Host native bank buttons under frames with their original container IDs;
  keep Blizzard's bank frame shown for events and purchase state.
- Bank bag slots are for viewing, dragging and equipping only. Plain clicks do
  not open or close bag frames; the combined window displays purchased bag
  contents. Restore the original button scripts and parents on close/handoff.
- Give Baganator exclusive bag and bank UI ownership at startup and late load.
  No saved-variable migration or noncharacter bank callback changes.
  [Evidence](CLASSIC_COMBINED_BANK.md).

## 2026-11-01 - dim equipped passive trinkets

- Apply the equipped-ownership usability fallback only when the managed
  trinket face has an on-use spell. No use spell means an inactive tint,
  regardless of the generic item API's usable result.
- Retain bright ready on-use faces, genuinely unusable spell dimming, secure
  slot actions and combat-grid mana gem/healthstone rules. Native checks remain
  pending. [Evidence](TRINKET_EQUIPPED_USABILITY.md).

## 2026-10-31 - count equipped trinket faces as owned for tint

- For the trinket menu's managed `/use 13|14` item face, preserve the existing
  owned-item usability fallback when native `IsUsableItem` is false. The
  equipped item is absent from bag-only counts.
- Keep use-spell unusability, cooldown paint, empty-slot desaturation,
  secure clicks, keybinds and the combat grid gem/stone rule. Native five-client
  visual, input, taint and performance acceptance remains pending.
  [Evidence](TRINKET_EQUIPPED_USABILITY.md).

## 2026-10-31 - retain chat durability through world-entry data gaps

- Treat a no-data read during `PLAYER_ENTERING_WORLD` as transient for a
  bounded two-second window. Keep the last label, accept player inventory
  and equipment events, and retry after 0.5 and then 1.5 seconds only while
  no readable value has arrived. Expire the label if both retries fail.
- Ignore a retry from an older world entry. Preserve secure button behavior,
  minimum-slot percentage, color, settings and saved data. Native teleport,
  pixel, taint and frame-time checks remain pending.
  [Evidence](CHAT_CHARACTER_DURABILITY.md).

## 2026-10-31 - default appearance for inaccessible cast schools

- Keep native/default cast appearance when the addon cannot establish a
  magic school, including items, physical spells and secret casts. Keep
  readable magic themes and Blizzard nameplate bar ownership.
- Select the channel spell ID with an explicit branch so Lua never tests a
  secret value or borrows the adjacent empowered return field. Do not infer
  a school from `castBarID`; it is only a cast identifier.
  [Evidence](SECRET_CHANNEL_FALLBACK.md).

## 2026-10-31 - place nameplate school artwork behind native chrome

- Parent nameplate backdrop textures to a Flux host at the plate's frame
  level. Follow plate parent/level changes during active casts. Keep the
  Blizzard cast bar as the fill/progress owner and retain higher edge, halo
  and particle effects.
- Preserve unit-frame artwork geometry, opacity, controls and timing. Native
  pixels, combat taint and matched frame time remain pending.
  [Evidence](NAMEPLATE_BACKDROP_LAYER.md).

## 2026-10-31 - show full chat character durability

- Show the character-button percentage for any readable equipped durability,
  including `100%`. Hide it only when no equipped slot supplies readable
  durability. Keep lowest-slot calculation, colors, event cadence, button
  geometry, secure clicks and saved options unchanged.
- Native pixel, equipment-change, combat/taint and frame-time acceptance is
  pending. [Evidence](CHAT_CHARACTER_DURABILITY.md).

## 2026-10-31 - tint conjured combat items from live usability

- Treat death/ghost as unusable for combat mana gem and healthstone faces,
  even when the native item API reports an owned item usable.
- Once bag data is reliable, let the live item usability result darken these
  faces for other situational blocks. Keep the existing empty-charge rule,
  loading-screen hold, visibility policy, secure actions and bindings.
- Use the existing life-event paint lane. Native all-client tint, input,
  taint, pixel and frame-time acceptance remains pending.
  [Evidence](COMBAT_GRID_CONJURED_USABILITY.md).

## 2026-10-31 - restore cast fill geometry and school-colored tip

- Create the school texture on the actual `TimerBar` for both Flux unit bars
  and Blizzard nameplates. Hide and restore the native source texture only
  while school colors are active, preserving progress geometry and native
  cast ownership.
- Tint the native Spark to the school color alongside the Flux leading-edge
  glow; restore its prior vertex color when the theme clears. Keep interrupt
  feedback and all existing options. Native pixels/taint remain pending.
  [Evidence](CAST_SCHOOL_FILL_TIP_FIX.md).

## 2026-10-31 - style Blizzard nameplate casts with shared school themes

- Reuse `CastBarThemes` and the existing observed-school/metadata resolver for
  target, focus and nameplate appearance. Keep Blizzard's nameplate status bar,
  cast lifecycle, text, shield and important-cast indicators as owners.
- Attach a Flux visual host and a fill region to the native status bar. Hook
  each native nameplate bar's cast transitions after Blizzard runs; never replace its
  methods or persist secret identity. Restricted/unknown identities leave the
  native bar visible. Retain the existing appearance controls and add one
  nameplate toggle in unit-frame settings. Native taint, pixels and frame time
  remain pending. [Evidence](NAMEPLATE_CASTBAR_SCHOOLS.md).

## 2026-10-30 - clear Blizzard MicroMenu children before native callbacks

- Reparent selected buttons and stage unused layout children before any
  Show/Hide path in Flux's rebuild. Finish hiding staged children after Flux
  layout. This prevents Blizzard `MicroButton_OnShow` from finding hidden,
  unpositioned children in `GetEdgeButton`.
- Keep Blizzard `Layout` and `GetEdgeButton` untouched, preserve button order,
  settings and the existing combat/Edit Mode deferral. Native post-fix
  validation is pending. [Evidence](17-micromenu.md).

## 2026-10-30 - retain pending loot sources through delayed chat

- Keep each loot session's cursor origin and captured slot identities for 30
  seconds after close, capped at 32 sessions. Match item link and stack count,
  currency ID or money slot before using a source position. Reconcile a late
  slot/chat pair by source so it displays once.
- Allow one item fallback for a window whose slots were emptied before
  capture. Linkless currency keeps the one-second close grace. Source
  attribution is ambiguous when multiple uncaptured sources remain pending;
  native ordering and placement require five-client checks.
  [Evidence](LOOT_CURSOR.md).

## 2026-10-30 - pin each loot batch to its opening cursor position

- Capture the cursor once when a loot window first becomes ready/open, and
  carry that origin through slot and delayed chat rows. Keep each row's own
  UIParent coordinates so another loot window cannot relocate it.
- For bonus/group rolls without a loot window and Preview, use the cursor at
  that alert event. Preserve three-row capacity, 3-second default, controls
  and source filtering. Native click-to-event timing and pixels remain to be
  checked. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - restrict cursor alerts to loot sources

- Exclude crafted and pushed/rewarded chat forms. Require a current or
  just-closed loot window for ordinary self-loot chat and currency chat;
  keep direct slot clears, bonus rolls and group-roll wins. Do not infer loot
  from bag changes.
- Keep a one-second close grace for chat arriving after LOOT_CLOSED. This is
  a bounded event-order compromise and needs native confirmation. Keep the
  existing fast pickup, money format and settings. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - register FluxLoot profile callbacks with the AceDB receiver

- Use `FluxOptions.db.RegisterCallback(FluxLoot, event, FluxLoot.Refresh)`,
  following the established FluxOptions call shape. The receiver is FluxLoot;
  the event is a string; the method refreshes event ownership after profile
  changes, copies and resets.
- Keep loot settings, alert appearance and pickup behavior unchanged. The
  user's stack trace is pre-fix native evidence; post-fix native validation
  is still pending. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - show looted money with denomination coin art

- Parse only the client's own received-money messages using its localized
  money templates. Show white numbers and MoneyFrame gold/silver/copper
  symbols, with a leading copper/silver/gold icon selected at 100 and 10,000
  copper. Skip unparsed or zero messages rather than repeating raw chat text.
- Reuse the coin art already used by Flux vendor chat. Keep item and currency
  alerts, timing, settings and fast pickup unchanged. Native client checks
  remain pending. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - default cursor alerts and fast pickup on

- The user clarified that both switches should default on for all five
  supported clients. Keep the separate FasterLoot ownership guard while it is
  loaded, so two addons do not call LootSlot for the same LOOT_READY event.
- Name the existing duration control **Disappear after (seconds)** and keep
  its 3-second default. Preserve saved values; do not reset profiles.
  [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - add profile-scoped cursor loot and optional fast pickup

- Keep the installed FasterLoot addon independent; Flux skips its fast pickup
  path while FasterLoot is loaded. Both switches now default on by user
  follow-up. Avoid changing the user's addon list or Auto Loot preference.
- Use existing AceDB and item services, a three-row visible-only display,
  and loot-slot/chat reconciliation for alerts. Keep loot roll positioning and
  auction, guild-bank and void-storage callbacks untouched.
- Treat desktop event fixtures as limited evidence; native acceptance on each
  supported client is still required. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - use the native negated Sticky Targeting setting on Retail

- The linked GitHub main file is the same pre-fix source. A 13 August local
  snapshot uses `Settings.GetSetting("deselectOnClick"):SetValue(false, true)`.
  Restore that route only for this uncoupled Controls setting, verify raw
  CVar `1`, and retain raw-CVar fallback when the setting is unregistered.
- Keep the general modern `Settings.SetValue` guard for protected raid and
  nameplate callback ownership. Avoid the historical repeated raw `0`
  writes and leave the camera fallback at 2.6 without an engine maximum.
  [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

## 2026-10-30 - audit native Sticky Targeting and use a writable Retail camera fallback

- Use `deselectOnClick=1` as the authoritative unchecked Sticky Targeting
  value. Include it in the first-load audit; keep the Retail Settings API
  taint guard and avoid repeated writes when already correct.
- When the engine gives no camera maximum, use 2.6 on Retail rather than
  assuming 4 from its major version. Give accounts with a prior failed
  first-load audit one settings-only retry; do not repeat binding setup.
  [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

## 2026-10-30 - complete first-load settings after world entry

- Apply first-account and new-character nonbinding defaults after the first
  world entry, then audit supported values after startup can settle. Keep the
  existing safe-write queue and the protected raid CVar guard.
- Limit mismatch repair to the armed first-load audit, with three attempts.
  Existing completed accounts keep later changes. Report completion once;
  manual reset completion and specific failures remain visible.
  [Evidence](NONBINDING_FIRST_LOAD.md).

## 2026-10-30 - use the item service for Hearthstone selector hover

- The user's native stack trace shows `GetItemInfo` is nil when the selector
  hover handler runs. Use the already-loaded `Flux.Item.GetInfo` and the Toy
  Box name for an uncached toy. Retain the existing help text and fallback.
- Do not install or enable deprecated globals for this panel. The focused
  fixture removes `GetItemInfo` and reproduces the prior failure.
  [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - gate Hearthstone editor on the earlier core capability

- The user's Toy Box still showed no Hearthstone panel. The editor loads at
  TOC line 145; `FLUX_API` is initialized only at line 204. Its original guard
  always returned during normal loading. The prior fixture incorrectly
  supplied that later API at the earlier point.
- Use `Flux.Cap.hasToyBox`, available from `Core/Capabilities.lua` at TOC line
  22. Keep the separate later `FLUX_API` flag for its existing consumers.
  Use the current item icon API before deprecated globals while building the
  panel, so icon lookup cannot abort creation on modern clients.
- Verify the actual load order in the regression, with `FLUX_API` absent.
  Native visibility and secure use remain pending.
  [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - make Toy Box capability independent of journal opening

- The first diagnosis treated the journal-toggle condition in
  `FLUX_API.hasToyBox` as the registration cause. The later TOC audit showed
  `FLUX_API` itself did not exist when the Hearthstone editor loaded.
- Define Toy Box capability by the toy query and ownership APIs. Keep journal
  opening separate, using the available modern or legacy Blizzard loader and
  native Toys-tab opener. Preserve the existing choice store and UI gestures.
- This change alone did not make the panel appear; the earlier core-capability
  decision above completes registration. Native toy selection, reload, secure
  click and performance checks remain pending.
  [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - finish first-account bindings in one native transaction

- The user saw native assignment/verification fail, then default keys return
  after reload. Blizzard's modern keybinding UI passes an action-specific
  context to binding APIs; Flux omitted it.
- Use that context where available, validate resulting actions rather than a
  single API return, retry only wrong keys up to three times, and complete
  clear/assign/save/load in the same call. Keep rollback and the one-account
  marker; do not add an automatic polling loop.
- Native performance, secure input and disk persistence remain pending.
  [Evidence](BINDING_ATOMIC_CONTEXT.md).

## 2026-10-30 - complete bindings only after native save/load verification

- The version-5 attempt gate claimed completion while the Retail account
  binding cache contained no key bindings.
- Remove SaveBindings from the PLAYER_LOGIN combat-settings pack. Apply the
  keyboard at first world entry to the account binding set, then verify
  SaveBindings, LoadBindings and the supported template before marking
  account version 6 complete after the next real login confirms the saved keys.
- Repair older version-4/5 accounts once if native bridge keys are missing.
  Preserve unmarked accounts and already bound accounts. Roll back failures
  and resume only an interrupted unsaved pass.
  [Evidence](BINDING_PERSISTENCE_REWRITE.md).

## 2026-10-30 - consume the automatic attempt before its first binding write

- The user observed full keyboard replay after reload, including accounts that
  had already loaded Flux. A final save/verification failure can leave the old
  `"pending"` marker behind after native keys were changed.
- A new account gets one automatic pass at first world entry; version 5 claims
  that pass before the first `SetBinding`. Failed partial passes do not replay.
  No-write unavailability may retry within the bounded first-login path.
- Treat old pending/completed markers and existing four bridge bindings as
  evidence to skip a repeat. Ignore overlapping full-reset requests while a
  batch is active. Manual `/fluxdefaults keybinds` remains available.
  [Evidence](ACCOUNT_BINDINGS_ONCE.md).

## 2026-10-30 - apply automatic bindings once for the whole account

- The user clarified that automatic keybindings must run on first account
  load only. Keep one account-wide pending/completed state, independent of
  Blizzard's account or character binding-set selection.
- Migrate any successful version-4 character marker to account completion;
  leave existing accounts with no pending first-account setup untouched.
  A failed first-account attempt may retry until its one successful save.
- Remove Flux keyboard replay from Blizzard Settings reset callbacks. Keep
  explicit Flux keyboard reset commands and the batched eight-write limit.
  [Evidence](ACCOUNT_BINDINGS_ONCE.md).

## 2026-10-30 - complete the full binding reset after one successful save

- Apply the full reset once for each active native account or character
  binding set. Mark version 4 complete immediately after verifying and saving
  that set; accept prior version-4 pending saves without another clear.
- Remove automatic replay on `UPDATE_BINDINGS` and cross-login verification.
  A failed or unavailable attempt may retry until one successful save, with
  the existing three-attempt login cap. Explicit user reset commands remain.
- Scan the binding registry once per reset, cap writes at eight per frame and
  separate clear, apply and save phases. Confirmed scopes do no further
  registry scans. Native FPS/latency remains unmeasured.
  [Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - reset the active native binding set before Flux defaults

- The user explicitly requested a full clear before applying the complete
  template on all clients. This supersedes the general no-forced-reset rule
  for the one-time first-load repair and replaces custom keys in unconfirmed
  account/character binding scopes.
- Require all Flux XML commands to be registered before clearing. Skip native
  template commands missing from that client. Clear all active keys in batches,
  apply the supported template, verify it, then save that active set.
- Upgrade old markers to version 4, verify across login sessions, and react to
  late `UPDATE_BINDINGS` while pending. Bound retries to three per scope per
  login; confirmed scopes preserve later edits. Native acceptance is pending.
  [Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - reset the active native binding set before Flux defaults

- The user explicitly requested a full clear before applying the complete
  template on all clients. This supersedes the general no-forced-reset rule
  for the one-time first-load repair and replaces custom keys in unconfirmed
  account/character binding scopes.
- Require all Flux XML commands to be registered before clearing. Skip native
  template commands missing from that client. Clear all active keys in batches,
  apply the supported template, verify it, then save that active set.
- Upgrade old markers to version 4, verify across login sessions, and react to
  late `UPDATE_BINDINGS` while pending. Bound retries to three per scope per
  login; confirmed scopes preserve later edits. Native acceptance is pending.
  [Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - verify default grid bindings across login sessions

- Keep post-batch and post-combat bridge binding seeds provisional until a
  delayed active-set check. A completed seed must survive a following login.
- Recheck earlier completion markers. Repair lost assignments only when their
  target is free or still has a known stock action; preserve custom target
  actions and intentional unbinds after confirmation.
- Preserve account/character binding scope and existing secure override
  refresh. Native first-load/reload checks remain pending.
  [Evidence](DEFAULT_GRID_BINDINGS.md).

## 2026-10-30 - use Flux-owned raid settings on protected clients

- The user chose to retain the Retail/Forever native compact-frame taint
  guard. Do not write native raid CVars or trigger Blizzard Settings/CUF
  callbacks from Flux on these clients.
- Use the existing account/character Flux raid options for live unit chrome,
  status text and preview. Preserve Classic native profile/CVar behavior and
  existing Flux frame dimensions. Keep Blizzard Interface values native-owned.
- Require native first-account/new-character, combat and Edit Mode acceptance
  before claiming game behavior or taint safety. [Evidence](RAID_OWNED_SETTINGS.md).

## 2026-10-30 - use Flux-owned raid settings on protected clients

- The user chose to retain the Retail/Forever native compact-frame taint
  guard. Do not write native raid CVars or trigger Blizzard Settings/CUF
  callbacks from Flux on these clients.
- Use the existing account/character Flux raid options for live unit chrome,
  status text and preview. Preserve Classic native profile/CVar behavior and
  existing Flux frame dimensions. Keep Blizzard Interface values native-owned.
- Require native first-account/new-character, combat and Edit Mode acceptance
  before claiming game behavior or taint safety. [Evidence](RAID_OWNED_SETTINGS.md).

## 2026-10-30 - complete Classic raid profiles and use Medium nameplates

- Keep missing/late Classic active raid profiles pending, then apply the full
  native raid pack after profile load through the existing writer queue.
  Bound the first-world-entry fallback and leave successful profiles alone.
- Set `nameplateSize` to `2` in both defaults sources. Migrate an existing `3`
  once; preserve any other chosen size and retry a failed or deferred write.
- Retain the Retail/Forever compact-frame write guard. Its protected callback
  ownership remains unresolved for automatic Blizzard raid-setting writes;
  native client acceptance remains pending.

## 2026-10-30 - finalize grid bindings after first world entry

- Use the first `PLAYER_ENTERING_WORLD` after login to write the active native
  binding set, then verify it again shortly afterward before persisting the
  completion marker. Queue behind full-template work or combat and retry an
  unavailable set or failed write within the same login.
- Recheck the old `true` marker once using version `2`; permit the known stock
  achievement action on `Y` to yield to smart mount. Preserve custom target
  actions and later intentional unbinds after version `2` is recorded.
- Refresh labels from `Flux.EBS.buttons`, the loaded grid registry, with a
  legacy fallback. Iterate only loaded modules in the bulk secure rebind pass
  so nil optional modules cannot truncate combat refresh.
- Native first-load input and all-client acceptance remain pending.

## 2026-10-30 - seed missing Flux keys on the active binding set

- Continue the full template on first account setup. Once per native binding
  scope, seed only missing Flux commands into free target keys; allow stock
  action buttons 6â€“8 to yield to the existing grid defaults. Preserve custom
  target actions and commands already bound elsewhere.
- Save the active account/character set and refresh secure button overrides.
  Defer through the existing combat and bulk-binding lifecycle. Persist a
  scope marker only after save succeeds, so a user unbind later is respected.
- Include previously seen characters because the earlier new-character path
  marked them seen without assigning per-character Flux keys. Native clicks
  and other clients remain pending.

## 2026-10-30 - first-login defaults by client CVar scope

- Keep the established full account-first setup and keyboard template. For later
  new characters, apply only CVars the active client reports as character-stored,
  plus the existing raid/chat setup. Unknown scope cannot authorize an account
  preference write; existing custom bindings remain untouched.
- Route character CVar and bitfield writes through the existing Blizzard Settings
  write queue and retain Retail/Forever compact-frame restrictions. Deferred or failed
  character CVar work does not mark the character seen before completion.
- Leave the unreachable post-login three-sentinel/four-mismatch check unchanged
  until a repair can avoid replaying all CVars over user preferences. Native
  fresh-character acceptance is pending for each client.

## 2026-10-30 - vendor chat coin amounts

- Keep existing vendor net accounting and repair/junk messages. Format their chat
  amounts into full gold/silver/copper denominations with native coin texture paths.
- Use the shared merchant formatter when the junk/repair module is loaded, while
  keeping standalone vendor loading capable of the same output.
- Desktop string checks do not establish native texture rendering; verify in-game
  chat on each client when background-safe access is available.

## 2026-10-30 â€” portrait and strip scale correction

- Treat `SetPoint` offsets as frame-local. Do not multiply portrait center
  offset by the frame scale again. Normalize chat/aura positions by effective
  scale before moving focus.
- Convert the action strip top to UIParent units, then the player/side-by-side
  target bottom offset to frame-local units. Keep a four-unit clearance when
  scale differs from 100%; preserve the original 100% anchor.
- Refresh a 3D portrait after an actual scale change through the existing
  display-metrics helper. [Evidence](UNIT_FRAME_SCALE.md).

## 2026-10-30 â€” whole unit-frame scale

- Give player and target one multiplier, and focus a separate multiplier, in
  their existing Unit Frames tabs and account/character scope. Keep saved
  width/height and class-power size controls independent.
- Scale root frames so their children inherit it. Match detached separators,
  atlas borders, target placeholder and Blizzard-owned class resources explicitly.
  Clear the action strip edge at changed scales. Avoid a
  second scale on ToT when it is parented to target.
- Use existing combat-deferred sizing refresh. [Behavior and pending native
  checks](UNIT_FRAME_SCALE.md).

## 2026-10-30 â€” vehicle seat corner and scale

- Reserve a seat-width slot to the left of equipment durability. When the
  visible micro menu or status strip occupies the top-left, keep the chrome
  fixed and put both indicators below whichever extends lower. Otherwise start
  the pair at the screen top-left, preserving PvP-widget clearance.
- Scale the parent indicator to 0.7 so native art and seat buttons keep their
  proportions and hit areas. Keep stock indicator mute and vehicle events intact.
- Existing combat deferral and the status owner's anchor refresh continue to
  apply. Focused desktop layout checks pass; native pixels, clicks and taint are pending.

## 2026-10-30 â€” empty unit resource bars

- Use maximum power, never current power, to classify an absent main resource.
  Compare only nonsecret numeric values. On Live/Forever, layer resource over
  full-height health and forward max power to the secret-accepting alpha sink.
  This also hides a secret zero without branching on it in Lua.
- Apply the behavior to Flux-owned unit frames and raid cells. Existing
  health-only satellites and Blizzard-owned frames keep their respective layouts.
- Use existing power events and partition code. Raid max-power changes now
  trigger updates; combat reanchoring waits for regeneration. Preserve the raid
  hide-power setting, overlays, profile data and frame sizes. Keep text/raid-icon
  anchors in their original upper area while health extends underneath.
- After user feedback, center health text across full HP when resource presence
  is absent/restricted, and retain the original split text area for a known
  positive maximum. Keep power text parented under the alpha-controlled bar.
  The Flux separator starts transparent and follows max-power alpha.
- [Desktop evidence and native limits](UNIT_POWER_VISIBILITY.md). Earlier main
  branch holds below are historical; 29 October main-only authorization applies.

## 2026-10-29 â€” teleport counts/interrupted casts

- User confirms Retail. Native display text, including empty, owns this preset's
  count. Inaccessible tooltip text cannot establish Classic rune costs.
- Reuse filtered spell actions for eligibility, skipping reagent/restock rows.
  Restore macro/face/tooltip on unlock; keep complete updates for list/options/
  favorites changes, existing combat deferral and success delay.
- Preserve saved state, known legacy rune counts, click paths and popup styling.
  Other custom flyouts remain unconfirmed; no speculative shared-effect rewrite.
- Verified external source/history/on-disk Retail settings before edits. No live
  game/profile/diagnostic changes or publication. Desktop counts are not native
  hitch-resolution/FPS/taint acceptance. [Evidence](TELEPORT_CAST_WORK.md).

## 2026-10-29

- Modernize the existing `_FluxUI` and repository in place. User's current request
  supersedes fresh-project/no-old-code/separate-repository/rename instructions in
  older specs. Product requirements remain inputs; conflicting current behavior
  is recorded, not silently removed or redesigned.
- Use the current change branch; leave `main` untouched until explicitly
  authorized. Keep the same TOC, public commands, saved roots and profiles. No push
  or merge is part of the first batch.
- Preserve all actual files and Git history outside AddOns before changes, including
  original untracked package/log and ignored local work. Relevant private settings
  remain outside Git. Exact hashes and recovery procedure are in `RECOVERY.md`.
- Reuse the existing source/reference collector, Lua validation runner, performance
  diagnostics and service architecture. Append ledgers, not a competing framework.
  Refresh generated indexes because the baseline references were stale; their larger
  diff is an audit correction, not thousands of runtime changes.
- Select BUG-001 before general lifecycle restructuring: production Currency/Store/
  Adapter replay proves stale builtin snapshot writes after external Ready. Four
  execution-time guards use the existing authoritative provider flag. Keep four
  shared-bus subscriptions inert after handoff; full provider retirement is separate.
- Preserve standalone startup, immediate money updates, token/warband cadence,
  saved ledger and provider callbacks. No appearance/secure-input code changes.
  Deliberate correction: provider-owned money must not be overwritten by a stale
  builtin event; the regression checks this exact failure.
- Runtime fix/test/fixture are a separate commit from requirements/audit/generated
  references. The supplied package is retained verbatim; no user log or settings is
  staged. Commit-only author configuration follows existing repository attribution.
- Desktop deterministic counters are valid operation evidence, not native CPU,
  memory or FPS. Requests are not executed scheduler passes. Historical native
  samples retain original context and cannot certify this candidate.
- PE versions and source version files are recorded separately from native
  GetBuildInfo. Retain original Wrath, modern Wrath and Cata as distinct rows;
  unavailable or unsupported cases are explicit. No TOC compatibility changes yet.
- Correct documentation when direct source evidence resolves it (`OptionalDeps`,
  Ready handoff, native item identity APIs, `/fluxui bliz`). Preserve unresolved
  product differences/defaults until a focused decision or reproduced defect.

## 2026-10-29 continuation â€” deferred provider work

- Followed the next-step event audit rather than assuming a historical finding was
  an active gameplay bug. Production dispatch reproduces skipped callbacks during
  removal, but the only active removal owner is Context.DisarmEvents and no current
  production call to its unsubscribe path was found. Keep this latent API defect
  documented in `EVENT_DISPATCH_AUDIT.md`; defer a hot-path redesign until a concrete
  consumer or lifecycle migration requires it.
- Prioritize BUG-002: queued/partial builtin mail and auction scans can outlive
  Syndicator readiness and overwrite the provider snapshot. Execution-time ownership
  checks belong at the beginning of each existing StepScan, before debounce/time
  checks. Cancel its data and OnUpdate work, preserving mailbox/auction open state,
  standalone scan budgets, close behavior and incomplete-data retries.
- Keep mail-send/return completion and auction/guild query ownership as separately
  tracked follow-ups. This scan fix does not claim complete builtin-provider teardown.
- Reuse the earlier complete 82-test/723-file baseline only after verifying every
  tested Lua hash matches current bytes. Capture the new focused failure before
  runtime edits and run full candidate validation after the change.
- The next controlled replay proved BUG-003 for both SendMail and ReturnInboxItem:
  completion after Ready mutates the exact character table returned by Syndicator.
  Treat loss of ownership like existing failure cleanup before resolving the
  recipient; clear the pending operation and its subscriptions. Keep this separate
  from scan cancellation, with its own checkpoint, baseline and regression.

## 2026-10-29 continuation â€” disabled Windows lifecycle

- User explicitly deferred auction, guild-bank and void-storage callback audits.
  Redirected independent inspection to the documented WindowMover disable behavior.
- Production Catalog/Engine/Init/options replay reproduced disabled attachment and
  polling, plus public SetEnabled(false) retaining an active scale gesture that
  changes saved scale. Fix BUG-004/PERF-003 using the existing Scan and Refresh.
- Gate discovery before native hook setup; hide/show the existing panel watcher
  through Refresh; call Refresh on both public enable outcomes. Keep enabled
  cadence, frame reuse, native protection guards and saved positions/scales.
- Retain existing permanent guarded hooks, startup proxy/driver, two discovery
  event subscriptions and two bounded startup callbacks. Their disabled Scan now
  returns before catalog access. Do not claim complete module teardown.
- Reused the 84-script full baseline only after verifying all 725 Lua source hashes.
  Captured a new verified external source/history/private settings checkpoint before
  edits. Matched desktop counters establish removed work; native input/pixels/taint/
  performance remain pending.

## 2026-10-29 â€” editorial maintenance

- Use conventional contribution guidelines and development tasks instead of editor
  workflow files. Archive original prompts/templates, planning Word file, old handoffs,
  local backup trees and sync log outside the addon before removing active copies.
- Rewrite conversational comments as technical explanations. Preserve every executable
  Lua token/string, native restriction invariant, license and third-party attribution.
- Retain technical specifications, tests, measurement values and revision identities.
  Use factual descriptions of the recorded procedure. Preserve
  original records in the verified checkpoint and omit optional branch metadata.
- Do not rewrite Git history or alter main as part of a working-tree cleanup.

## 2026-10-29 â€” queued merchant purchase identity

- BUG-005 is an active queue correctness issue: production replay buys a replacement
  merchant item or submits an empty slot after listings change. Index refresh alone
  cannot repair retained task references. Protect the operation, not just index build.
- Reuse ResolveMerchantSlotItemID in RunBuyPass's invalid-task condition. Discard a
  missing/mismatched listing before quantity calculation, purchase, wallet debit or
  reporting. Continue valid tasks at the original eight-call budget and cadence.
- Do not relocate stale tasks or restart the session automatically: a fresh normal
  request uses current index/remaining counts. This avoids resubmitting earlier
  purchases while inventory acknowledgements may still be settling.
- Record the extra identity lookup per valid purchase as correctness overhead.
  No native performance improvement is claimed. Unchanged-ID price/stock changes
  and purchase acknowledgement are separate unmeasured candidates.

## 2026-10-29 â€” finite merchant stock budget

- BUG-006 reproduces two related capacity defects: zero availability was uncapped,
  and repeated tasks reused the same finite snapshot count. Treat zero as a cap and
  reserve submitted quantities on the existing shared index entry.
- The shared remaining value is a reservation budget until index refresh, not proof
  of native acceptance. Do not introduce another transaction service or live polling.
  Unrelated rejections, external stock changes and acknowledgement remain separate.
- Preserve unlimited/nil helper semantics, gold/alternate-cost math, eight-call pass
  budget, UI/defaults/settings and normal refresh/new-request recovery. Extend the
  existing merchant harness with focused stock/identity groups rather than duplicate it.
- Exact read-only Blizzard source hashes support API shape/zero-stock interpretation;
  the 12.1.0.69283 snapshot predates installed clients and does not advance native rows.

## 2026-10-29 â€” vendor-open availability work

- Prioritize the user's idle vendor-open hitch, reported only on Era so far. Do not
  assume first-open/repeated-open behavior or automation settings, and do not claim
  native resolution from a desktop reduction.
- BUG-007/PERF-004 reproduces repeated fallback bag walks in the real availability
  path. Cache its exact boolean result under the existing junk owner using reliable
  bag generation and existing rule/item/list/slot invalidation. A classified count
  of zero alone is insufficient for cold gray-item data. Retain native-positive
  precedence, live retry when unready/unreliable, and all callback timing.
- Reuse the junk-smoke boot fixture and production buyer events plus unmodified UI
  availability sections. Document excluded rendering/layout/integrations. Seven API
  fixtures are regression coverage, not native client certification or original
  Wrath support. Keep cold and repeated-open counts separate.
- Retain the buyer frame and native count-query controls; add no timers/subscriptions,
  settings or generic cache service. Native query overhead, CPU/frame times and the
  remaining classification/index/Already Known/layout candidates need live evidence.

## 2026-10-29 â€” Quick Join anchor ownership

- Prioritize the user's concrete native SetPoint error. The column already anchors
  Channels to Quick Join; the old social callback reverses that edge. Existing
  isolated column/retry fixtures did not run the two owners together.
- BUG-008 returns before the fallback reanchor while either button belongs to the
  Flux column. Check both to survive a native reparent of either one. The enclosing
  callback still reconciles through PlaceColumnButtons; unmanaged fallback remains.
- Add parent/anchor cycle detection and correct bottom-point geometry to the existing
  column fixture, then execute real social/hook/retry callbacks there. Retain its
  five-branch controls. No competing owner, global API replacement or broad runtime
  error suppression is needed; preserve column geometry and the three deadlines.
- The baseline combat exception never reaches its existing waiter. The candidate
  reaches that deferral and reuses one waiter; it does not add a new runtime frame
  service. Native geometry, input/taint and performance remain pending.

## 2026-10-29 â€” repeated vendor tier candidates

- User confirms Era spikes on every same-vendor reopening. Read-only hashes showed
  the preceding junk/buyer/chat fixes already installed; do not assume a stale copy.
  Saved scriptProfile=1 is an observation requiring matched unprofiled validation,
  not proof of causality or permission to change the user's preference.
- Preserve merchant discovery/reference seeding. A blanket lazy-index skip can
  suppress that feature. PERF-005 instead filters actual tier matches before live
  usability in best selection and status; non-improving best contenders also skip
  the gate. Matching contenders retain fresh level/skill checks without a new cache.
- Reuse the existing buyer fixture and actual Score/Match/Vendor modules. Extend
  measurement to 25 reopenings with retained food/water refs and unoffered families
  after the user's cadence clarification; retain the source fix and test extension
  as separate reviewable commits.
- Ready-classification calls remain equal in measured runs. Classification now
  precedes level rejection, so cold tooltip cost can differ and needs native checks.
  Service call reductions are not native cache-miss, CPU, latency or FPS results.

## 2026-10-29 â€” native tier count attribution

- The clean Era 1.15.9.70576 four-reopen pilot reproduces a 333 ms UI interval;
  GetRestockTargetItems spends about 320 ms per call. Inclusive bag/bank count and
  tooltip rows identify a measured target; do not sum overlapping timings.
- PERF-006 filters tier membership before live usability in existing bag and cached
  personal/warband count owners. Keep live gates on matches, accounting, caches,
  fallback and protections. No new lifecycle resources or generic service.
- Five alternating native background getter pairs return identical quantities;
  median CPU is 132.199 to 15.237 ms for five bag kinds, 118.897 to 22.517 ms for
  cached-bank kinds. Bank outputs are zero on this character; positive/warband
  parity is desktop-only. Candidate bodies ran as source-derived local functions;
  no public/native API replaced. This is not full-window after acceptance.
- Honor the user's background PC use: no further game activation. Background local
  slash diagnostics preserved focus; original automation values and profiler=1
  restored, temporary exports removed and sampler/namespaces cleared by reload.
  The user's normal sync delivered source; no separate addon or sync job created.
- Native foreground repeated opens, unprofiled FPS, matched pixels, cold work,
  security/taint and other clients remain pending. Keep auction, guild-bank and
  void-storage callbacks deferred. [Evidence](TIER_COUNT_WORK.md).

## 2026-10-29 â€” whole-addon Retail resource audit

- Cover all 26 loaded source domains through current ownership/recurring-driver
  maps. Native idle execution does not exercise every lifecycle or prove leak-free
  operation; keep pending interaction/client scenarios explicit.
- BUG-009/PERF-007 reuses loot combat/readiness frames after production replay proves
  203 allocations across repeated world/combat cycles. Keep 50-update timeout,
  six-pixel anchor, native show hook and no protected writes in combat.
- BUG-010/PERF-008 explicitly releases full requested-capture snapshots and handle
  cycles. Retained-callback replay proves 20 -> 0 snapshots and 10,000 -> 0 frame
  rows per model. Retain the compact report, schema, deadlines and dormant behavior.
- Native Retail baseline has stable frame/public-cache counts but memory increases
  during diagnostics. Attribute requested capture retention before accusing the
  normal HUD. Native CPU ranks nameplates and assisted painting; do not disable
  features or slow update cadence without matched evidence.
- Discard the incomplete long-upload native comparison; no result for its missing
  candidate. Use normal file-loaded API calls for follow-up. Original profiler=0
  must be restored; no game activation, global API replacement or restriction bypass.
- Preserve the existing uncommitted tracker source/test/docs. Keep its changes out
  of the new runtime commits and record actual-file identities separately from HEAD.
  Main and excluded auction/guild-bank/void callbacks remain untouched.

## 2026-10-29 â€” common Social offset and dock ownership

- User-authorized intentional position correction: one eight-unit inset from the
  tab/menu top across client paths, preserving other layout/feature behavior.
- Use existing tab height as a relative offset. An absolute future top against a
  provisional login chat rectangle goes stale after the final pin; no timer/hook
  is needed to follow that movement.
- Anchor the column to primary ChatFrame1 on all tabs. Combat Log/custom native
  rectangles may differ; selected-tab identity remains solely for Copy/action data.
- Preserve Classic ownership/overflow handling, other menu-position fallback,
  scale conversion, combat restrictions and current retry deadlines. No framework.
- Native seven-selection Retail pass plus untouched reload image supports this
  scope. Five desktop branch models are not other-client native certification.

## 2026-10-29 - original stage tracking and countdown work

- Continue the supplied original plan through explicit stage gates; inventories
  and passing desktop checks do not complete all native acceptance.
- PERF-009 keeps the existing NamePlates owner/driver/cadence and removes repeated
  FontString discovery plus per-aura level tables. Reuse only within one poll;
  changing/opaque labels and native digit fallback remain fresh.
- Keep real unprotected native-widget results separate from actual combat aura
  rendering/taint/FPS. Background whole-addon scene changed, so that comparison
  is inconclusive even though errors remain0 and per-window frame counts stable.
- The user again explicitly requested root working rules and next-session records;
  restore those concise files alongside existing contribution/development docs.
  Do not restore retired prompt templates, narrated comments or private artifacts.
- Preserve the separate tracker work and current branch; main and excluded
  callback audits remain untouched. Keep WoW in the background and profile0.

## 2026-10-29 - action batch facts and native player auras

- Sample activation once within an existing bar paint batch. Pass explicit false;
  retain fresh standalone queries and the API helper's independent guard. No
  cross-frame cache, generic framework, animation suppression or slower cadence.
- Keep top-right player aura data/handlers/styles native. Short-idle measurements
  do not justify a competing aura painter or prove dense/restricted churn safe.
- Treat source-derived real-painter matched runs separately from complete-addon
  CPU/FPS. Both native clients use inactive highlight settings; real active combat
  input still requires acceptance. Preserve failed/inconclusive scope honestly.
- The user authorizes normal reconnect/warning dismissal and named character
  selection for testing. Same-account sessions displace each other: run serially,
  validate each executable/window and preserve foreground PC use. No credentials.
- Leave the user-owned mirror job unchanged. Verify each source transition; when
  delayed, copy only the known test file into the existing authorized client.
  Restore each original profiling preference and prior diagnostic report.

## 2026-10-29 - authorized main publication

- The user explicitly authorizes uploading the whole current addon and updating
  main. Preserve the current development branch and complete existing history.
- Include the formerly pending, already-tested objective-tracker change and its
  records; do not leave part of the authorized addon unpublished.
- Fetch/check remote main, fast-forward only when ancestry permits, and push
  ordinary refs without force. Preserve newer remote work if it appears.
- Keep private backups/settings/captures and ignored local helpers out of Git.
  Native pending checks retain their scope despite publication authorization.

## 2026-10-29 - local files authoritative, main only

- User requests no other branch and explicitly authorizes uploading all current
  local addon files. This supersedes the earlier retained-branch decision.
- The development branch equals main at b45eb5e, so remove both local/remote refs
  without losing commits. Keep normal pushes and all existing history.
- Include the newer local teleport fix and its complete tests/docs; do not reset
  the workspace to the previously published revision or omit uncommitted work.
- Keep private recoveries/settings/captures and ignored local helpers outside Git.
  Publication does not change native acceptance results or live game preferences.

## 2026-10-30 - resource separator and text refresh

- Reapply the main separator's maximum-power alpha after partition and border
  color paint; both paths can repaint its alpha aspect after a power update.
- Keep restricted-maximum health text in the health section. Only a known zero
  maximum selects the full-height text area. Do not test secret maxima for
  truth in Lua; pass them directly to `SetAlpha`.
- Include target-of-target loss and return in focused desktop regression checks.
  Native pixel and combat acceptance remain pending.

## 2026-10-30 - expanded HP text and ToT split

- For a known zero maximum, keep player/target HP labels at their existing
  horizontal sides but center them vertically in the expanded health area.
  On resource return, refresh health text anchors so nested placement returns.
- Keep ToT's UIParent separator container ten levels above the ToT button after
  side-by-side placement changes the button's frame level. Restore the original
  button level when returning to the stacked layout.
- Restricted maximum values cannot select a text layout in addon Lua; retain
  the upper HP placement until a nonsecret zero maximum is available.

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

## 1 November 2026 - repository front page

Use a root [README](../README.md) for the requested GitHub-page feature overview.
Keep each feature summary brief and link to the existing full reference; include
client gates, companion-addon ownership and first-setup effects. Publish current
local files on main with history preserved. This is a repository front-page
change; no hosted site, new addon, new branch or separate repository is needed.

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


Native continuation17:40UTC: Forever background readback confirms zero session errors, solo/OOC, profiling0, all three merchant input toggles configured, party v7 ready/secure with four hidden solo members. No runtime/settings/gameplay changes. User reports a real test party/raid with combat roster changes is unavailable now; actual combat/grouped acceptance remains pending. First consecutive unavailable-scenario audit; goal active. See FOREVER_NATIVE_PERFORMANCE.md and its validation JSON.

9 November goal blocker audit3: actual combat roster and grouped performance acceptance remain unavailable after three consecutive goal turns. User cannot arrange the real test group now. Goal blocked pending that scenario; no new runtime, input, settings or profiler changes. Completed evidence and exact pending checks remain in FOREVER_NATIVE_PERFORMANCE.md.
