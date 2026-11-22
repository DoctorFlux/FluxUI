# FluxLogistics restock handoff

Temporary companion auction requirements are projected into the existing Restock grid. These rows distinguish still-needed units from incoming items and disappear when carried stock is credited. Clicking a temporary row prepares that exact requirement and the existing main button checks the selected job and live quote before spending. An optional ready companion craft appears in the existing follow-up control.

The optional ScanLogisticsBooks function captures observed quantities and prices through the existing Auction House search owner. Books contain sanitized commodity tiers or whole listings and report whether the search completed. The scan never buys or changes presets. Approved stack quantities and their price caps filter eligible listings before the existing Restock button can submit one purchase. A legacy consumable preset keeps its implicit Normal membership when first edited.

Shopping and the FluxUI Restock tab can quote the combined eligible need
for a shared material, such as 40 Silk Cloth or six Heavy Leather. The
group can include different output recipes. The owner checks the current
group before using one approved commodity quote or whole auction listing
per press. Each order keeps its accepted spending limits and receives its
exact share of the purchase. A smaller qualified listing leaves the
remaining quantity for another press. On Classic, an approved lot can
still serve an individual order when a combined stack is unavailable.
[Validation](CLIENT_VALIDATION.md#shared-queued-craft-materials).

An explicit shopping-row quote can use the open FluxUI Restock tab. Its main purchase button and the Shopping List both submit the same accepted offer through FluxUI and revalidate the job, quantity, offer and spending limits. Passive preparation continues to leave an active owner tab alone.

The optional Followup registration accepts `GetReady`, `Process` and `GetIncoming` callbacks from FluxLogistics. `GetReady` returns the next eligible queued craft with enough carried materials. The button checks the displayed job, task, revision and quantities before a player press reaches the companion processor. Actionable FluxUI follow-up steps retain priority over companion work.

`GetProfession` publishes the next exact queued craft's profession after the order's external inputs are available in bags and the next task is ready. Mail collection, purchases and bank withdrawals come first. `OpenProfession` verifies the displayed job, revision, task and profession on the ordinary click path. Forever can also open the owned profession through the secure spell action. The companion observes the resulting native profession session.

If a partial craft triggers a bag update, FluxUI rechecks a temporarily
disabled companion action as soon as the inventory settles. The action
still uses the pending task and exact remaining quantity from the queue.
FluxLogistics rechecks the action after the native cast stops. If the
prepared native form is gone, the next press prepares that same recipe
and quantity again.
[Validation](CLIENT_VALIDATION.md#fluxui-continue-craft-button).

When materials are ready on Forever, the FluxUI craft reminder prepares the accepted job in the Workbench. Its item icon, quantity and caption move into the active Flowcraft or native profession window while the window is open. Closing the window returns the action to the HUD. FluxLogistics selects the exact recipe, including a required intermediate, and fills the native quantity up to the queued count and available reagents. Press Blizzard's **Create** for the displayed batch. FluxLogistics checks the matching native result and carried output, then prepares the next ready step of that job in the same profession. The Workbench and Flowchart stay beside the native controls when there is room. At narrower widths the native controls include a **Workbench** return.

Flowcraft lists the plan in single-line rows with item icons. Compatible active orders share a row with the combined outstanding output, such as 2× Green Silk Pack. The detail menu selects or cancels an individual order, and the grouped remove control checks and cancels the row's eligible members together. The shelf adapts to the visible content and window size. The bottom control and the next craft in the native profession window resolve the same accepted queue task. The native action is available across profession tabs.

Select an order row to target **Process**. The row shows the remaining
final output and the current step separately. The matching native view
shows that step beside the craft controls. During a batch the displayed
quantity follows matching progress while the reservation remains in place.
Once the batch stops, **Process** uses the verified remainder when that
order is eligible. An unrelated order in Review can wait while the selected
order proceeds. An active batch or ambiguous shared output blocks another
dispatch. Flowcraft follows the matching native cast and its receipts.
The row shows the client's reported cast duration. When the native
cast ends before its receipt arrives, Flowcraft can show **Waiting for
the craft result** while it keeps the same order selected. A prepared
**Create** action stays available until the native selection or the
player changes it.
[Validation](CLIENT_VALIDATION.md#flowcraft-cast-lifecycle).
[Validation](CLIENT_VALIDATION.md#flowcraft-queue-progress-and-process).

Forever updates the selected recipe immediately and coalesces the
plan refresh when recipes change in quick succession. An immediate
**Queue** press plans the current recipe, including when a Flowcraft card
selected it through Blizzard's recipe list.
[Validation](CLIENT_VALIDATION.md#flowcraft-recipe-selection).

The general queue action can select another ready step of the selected job when an earlier step lacks materials. **Craft this** stays with its selected Flowchart step. FluxLogistics retains craft events delivered before the native Create handler returns and credits them only once the recipe, amount, reagents and carried output agree.

On Forever, **Prepare** selects a ready batch and the HUD points to Blizzard's **Create** once its quantity is verified. FluxLogistics keeps the queue active while the matching native repeat count progresses. When a deterministic craft result is missing, the receipt can use the matched native recipe, carried output and exact consumed ingredients to credit just the verified operations.

**Replan from bags** can recover an eligible unfinished prerequisite after an unconfirmed craft. It retains the original job and any settled purchase history, checks the same remaining output against current carried materials, and links the replacement job. Replanning prepares a new route without spending, submitting a craft, or crediting the old attempt.

Verified craft progress carries across reload so the active order shows the
remaining quantity. When an older interrupted craft has incomplete evidence,
the selected **Process** or **Resume** action can reconcile verified carried
packs against the accepted output. That records fulfillment of the order.
The exact native receipt requires its own craft evidence. The same press
can process the eligible remainder on Forever. A client restriction can
route the exact remainder to Blizzard's **Create**. When the remainder
is blocked, the next acquisition or profession stage takes over after
the carried amount is recorded. The Restock reminder can present the
same recovery and checks the order and task again on press.
[Validation](CLIENT_VALIDATION.md#flowcraft-partial-craft-after-reload).

The optional `RevealNativeCraft(recipeID, operations)` callback exposes the native controls for an ordinary FluxUI Restock recipe and reports the prepared count. `IsNativeCraftBusy` lets a delayed FluxUI quantity request yield to the pending or active companion craft.

`GetIncoming` returns item quantities for confirmed Shopping List purchases that the current character is still waiting to receive. The queue owns these receipts and credits them after a carried inventory observation. The HUD can remind before arrival. When the mailbox opens, the default-on Auto Collect setting starts the bounded collection worker for both purchase sources. Companion collection checks the buyer invoice, item and outstanding quantity. The receipt remains tracked through an empty early inbox or a replaced queue entry until the purchase is credited.

The HUD offers a purchase when FluxUI Restock has a ready offer or an explicit Shopping List selection has prepared an approved quote. The click revalidates the exact offer in the existing auction owner, and an expired quote removes the purchase action. FluxLogistics runs on Forever, Classic progression, Anniversary and Classic Era. Retail runs standalone FluxUI Restock and uses its native profession window for the same attached craft reminder. [Client checks](CLIENT_VALIDATION.md#craft-reminder-in-the-profession-window).

_FluxUI owns restock targets, preset membership, tier eligibility, inventory observations and physical buy or withdraw actions. FluxLogistics is the optional planner for this interface. _FluxUI can still run independently and has no hard dependency on FluxLogistics.

## Policy

Consumable membership is stored on each existing preset. A legacy preset follows the selected HUD preset until its membership is explicitly edited. Explicit memberships are inherited from Normal to Open world to Raid/dungeon. All modes is an explicit common membership. Disabled presets remain disabled. An item in overlapping eligible presets uses the largest compatible refill target once. Ties favor the currently selected preset and then preset names in alphabetical order.

Common manual, tier and spell-reagent targets remain in their original stores. A per-target refill trigger can be set in the Restock plans menu. The owner target remains the refill quantity. Default triggers equal the target. Below-trigger stock or existing accepted coverage can continue to the refill target in eligible passive modes. Normal permits manual order creation only while FluxLogistics is registered. The owner passive setting is off by default and independent of the existing vendor repair and junk controls.

Rules use stable item or tier keys on the current character and retain ordinary-item or charge counting, bank participation and owner flags. A tier matches the existing FluxUI eligibility predicate and can only be routed to a qualified reference item. For bank sourcing, tier targets apply the owner's stricter withdrawal threshold to that reference. Exact-item demand gets first use of matching observed stock. A transfer between locations already counted in the same target scope cannot increase coverage.

The vendor's existing Auto Restock toggle still authorizes native merchant
purchases in every activity mode. Normal and the managed-order toggle control
automatic plan creation. Vendor purchases use the uncovered target, existing
refill thresholds and reserved-stock checks. Active competing workflows still
block a purchase. See [merchant sequencing](20-vendor-restock-junk.md#merchant-lifecycle-and-automation-ordering).

Enabled activity modes consider all current passive demands in batches of
at most 12 requests. A rejected rule counts once per pass. A mode change
stops the pending pass before further requests.

## Lua interface v1

Use dot calls on Flux.RestockPolicy and check its version field. Readiness comes from the existing inventory service selected by FluxUI. The bridge adds no inventory scanner and never accesses Syndicator directly.

- GetDemands with the manual option returns effective requirements including covered targets. Without it the service returns only eligible passive deficits. Missing reliable inventory produces an empty result and reason. Each row exposes id, itemID where a current reference can be qualified, tierKind, target, trigger, ready, bank, covered, uncovered, units, actorKey, destination, countBank, owner and revision.
- GetMode, SetMode, GetManaged, SetManaged, GetTrigger and SetTrigger expose validated policy settings. Per-preset membership uses the existing FluxNCConsumables owner with GetPresetRestockMembership and SetPresetRestockMembership.
- RegisterPlanner accepts one provider. GetCoverage returns accepted allocations with globally unique id and quantity. Optional units, kind and demandId disambiguate eligibility and counted storage. The optional third argument identifies the item whose pending auction units are already counted by FluxUI. It can differ from the preferred item used to plan a tier target. The planner uses this identity to match existing receipts to the reported quantity. Request receives the current rule, restock/craft/view action and context. Optional GetRequirements returns plan procurement requirements and supports owner reservation checks. Optional IsWorkflowBusy and GetPlanStatus share operation and progress state.
- GetRevision, Subscribe and NotifyCoverageChanged propagate revisions. A successful request refreshes coverage before another surface can submit the same demand. Inventory and settings notifications coalesce. The existing merchant index runs when a planner is registered and publishes the "merchant" reason after ready, price changes and close. This leaves the standalone idle path unchanged and preserves typed buy terms after close. An opted-in activity mode can create accepted plans without executing inventory actions.
- GetAcquisitions returns live owner-qualified current-character offers. Merchant offers carry bundle cost, availability, slot and merchant identity. The owner only supplies gold offers with validated purchasing eligibility. Character-bank offers require the actual open live bank. Catalog and price estimates are separate from those executable offers.
- GetVendorPriceEstimate returns a price per physical item, bundle cost, bundle size and provenance from typed merchant observations or a qualified vendor catalogue. The unit and bundle values must agree. The estimate has no offer identity, executable qualification or availability. Unknown and limited terms give no estimate.
- ExecuteAcquisition receives the accepted offer, quantity and validation callback. It returns an issuance result, reason, and bounded issued or scheduled quantity. The owner checks the current actor, context, terms, funds, cursor and competing workflow. Bank movement uses the existing scoped mover and validates each command against the accepted task. Vendor purchases use one qualified native stack per request. FluxLogistics confirms physical outcomes from inventory observations before advancing the plan.
- GetShoppingRequirements exposes materials still needed in the Auction Restock dropdown. A planner may provide GetShoppingRequirements with live net quantities after inbox deliveries and stock-target limits. Older planners use the accepted procurement rows from GetRequirements. GetRequirements continues to drive reservation checks. Optional planner.OpenAuctionShopping receives the existing Auction House Restock panel and the selected material. The menu checks the current job, revision, requirement, SKU and net quantity before handing off. OpenAuctionRequirement applies the same check before prefilling native Buy or Browse.
- FluxAuctionRestock.ExecuteLogistics receives an accepted auction requirement with its job, revision, SKU, need and price limits, a physical count bounded by the requirement, and authorization and observation callbacks. It searches the exact SKU in the open Auction House. Results delivered after the initial press require a new physical press to submit the available eligible buyout or commodity quote. Each press covers at most one listing or one commodity quantity. The owner rechecks the accepted plan, the live quote or listing, the price limits, buyer funds and competing workflows before a purchase. Auctionator's public search remains available independently of the native transaction.
- FluxAuctionRestock.GetLogisticsState exposes the matching search, offer, quote or purchase state. A fresh ready offer also returns a copy of its available purchase quantity and total copper. The observation callback receives state changes for asynchronous UI updates and purchase receipts keyed by attempt, plan revision, requirement and SKU. A matching native outcome confirms the bounded physical quantity once. Expected deliveries use the existing FluxUI inventory backend, including Syndicator when selected. Receipts can constrain the accepted job while delivery is pending. General auction restock continues to use its existing pending reservations and owner preferences.

The owner dropdown appears on the bank restock control, merchant Restock tab and Auction House Restock view. It displays the effective target and accepted coverage and offers Order restock, Craft missing, View plan and trigger editing. It uses FluxUI's normal native dropdown and its Forever gamepad fallback. Controller reachability and visual fit still require native validation.

## Queued craft materials

The vendor and bank Restock buttons can read accepted planner requirements for their current surface. These requirements come from the crafting queue and follow its quantity, reservations and lifecycle. An issued action stays pending until reliable carried counts confirm it. Partial receipts reduce the remaining target. Full receipts remove it. Previewing a recipe creates no restock target.

The merchant's regular Restock button buys eligible Auction Restock
materials and accepted companion requirements in the same visit.
Independent approved companion jobs can progress in one press. A
dependent purchase continues after its receipt settles and uses the
same accepted order. The tooltip shows eligible shortages and pending
materials on the ordinary merchant list.
[Validation](CLIENT_VALIDATION.md#craft-materials-in-vendor-restock).

The optional `GetVendorStage` and `BuyVendorStage` callbacks publish the
current accepted totals and live merchant availability to the Restock
reminder. A press rechecks the displayed stage and starts the same
merchant buyer. Accepted requirements for the same material can share
an eligible merchant bundle across output recipes. Approved merchant
fallbacks for auction requirements can also share the live offer.
Purchases for the same order continue after confirmed carried receipts,
and an uncertain same-item receipt blocks another purchase of that item.
[Validation](CLIENT_VALIDATION.md#craft-materials-in-vendor-restock).

At a matching merchant, eligible queued purchases can start automatically. Shift when opening the merchant defers automatic action. The existing Restock button can still start a purchase. An accepted vendor estimate can match a different live bundle size when the physical quantity and accepted unit and total price caps permit it. A live quote accepted when the plan was queued retains its exact terms.

At the character bank, the existing Restock button can use eligible live
stock for the shared demand across queued crafts. The bank mover checks
physical stock, carried room and the remaining requirement at every step.
The receipt assigns each accepted order its share. A partial receipt
fills the accepted requirements in queue order.
[Validation](CLIENT_VALIDATION.md#shared-queued-craft-materials).

21 November. Craft Shopping can prepare a single exact auction offer before the player presses Buy Needed. Preparation reuses the owner search with the accepted item, quantity and caps. It preserves a foreign or ordinary Restock session. A player press remains the authority for one modern commodity purchase or one complete legacy listing. After the receipt, verified inbox and carried counts determine the next amount.

### Accepted auction prices for vendor goods

The queued job's approved quantity and auction price limits apply to its exact material. The planner compares the number of items needed against the full vendor bundle cost when it builds the plan. For example, one Empty Vial at 5 copper can cost less than a five-vial bundle at 20 copper. The owner validates the exact live listing or quote, both accepted price limits, and buyer funds before each purchase. Standalone Auction Restock applies its vendor unit-price comparison.

## Inbox observation for accepted purchases

Shopping can display positive physical attachment counts from `Flux.Inventory.Mail.GetObservedCount(itemID)` as soon as the selected built-in or Syndicator inventory provider has published them. The reader uses existing inventory observations. It excludes predicted purchases and waits for qualified coverage before reporting zero. At Syndicator startup, the reader can return a positive warm count separately as pending. Shopping uses it for the displayed shortage until Syndicator publishes fresh mail. Collection checks and the qualified inbox spending gate still apply.

`Flux.Inventory.Mail.HasObservedInbox()` reports whether the active inventory
source has completed an inbox observation for this character. The inbox
snapshot generation can also change during hydration or receipt prediction.
An active provider switch clears the prior observation. The built-in backend
persists verified counts across reloads. Syndicator can verify a full scan
during the current session when its publication can be attributed to that scan.
An overlapping or unqualified publication can update cached counts without
making them eligible for a new purchase authorization. Auctionator search
remains available while the inbox is unverified.

A Syndicator scan that aborts before publication gives no observation proof. The owner retires its provisional scan state so a later complete observation in the same session can establish readiness. Asynchronous publications from normally returned scans still retain their attribution and overlap checks.

## Migration and rollback

New settings use the existing per-character _FluxUI_CharSavedVars root. RestockPolicy stores activity mode, passive opt-in and trigger overrides. Presets gain only restockMembership and restockEnabled. Existing targets, item-use ordering, saved settings names and disabled preferences are retained. No account stock or legacy recipe data migrates to the planner.

For source rollback, restore the changed owner source and TOC entries from the verified checkpoint. The added fields are inert with the earlier owner source and may be left in place. Do not restore older saved variables over current settings. Dated recovery includes original changed sources, verified Git history and hashes of available on-disk settings.

## Validation

The acquisition-first workspace and selected mailbox reader pass the
focused owner fixtures and all 16 installed FluxLogistics suites. The
eleven changed runtime files match across five installs. Native reload,
provider delivery, input and layout remain pending.
[Exact sources and tests](validation/restock-carried-flowcraft-2026-11-22.json).

The desktop bridge fixture covers shared target arithmetic and deduplication, Normal and managed ordering, threshold hysteresis, disabled and inherited presets, owner scope flags, overlap exclusion, and scoped live-action mocks for bank and vendor. Existing auction, vendor, bank-restock and consumable fixtures exercise the standalone owner paths. The desktop runs use Lua 5.4 fixtures. They do not qualify native load, bank or merchant behavior, the Auction House, controller focus or visual fit on Forever or Classic.

A completed external commodity purchase releases Craft Shopping when `C_AuctionHouse.GetQuoteDurationRemaining()` confirms the quote is inactive. An active quote keeps its ownership. The desktop auction fixture passed 12,172 checks across 34 profiles, including Auctionator handoffs with built-in and Syndicator inventory. [Forever quote API](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua#L570).
