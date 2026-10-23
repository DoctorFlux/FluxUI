# Baganator integration: categories, protection, bank state, and wrappers

`FluxBaganatorCompat` connects Flux junk, Respec equipment, consumable presets and bank restock to Baganator. It also changes Baganator configuration and wraps selected global item/cursor APIs. Its ownership extends beyond drawing a coin on a bag slot. Inventory data delegation to Syndicator is a separate integration and does not depend on the Baganator view layer being present.

## Startup and dependencies

[`Loader.lua`](../BaganatorCompat/Loader.lua), `Compat.Init`, waits for `Baganator.API`. It immediately installs the item-identity cache and bank-restock bridge; bank controls deliberately do not wait for all Respec modules. The remaining bridge initialization requires `FluxRespec.GearSetLock`, `GearSetIndex`, `R.Inv` and `Flux.Inventory`, or retries from login. Guard flags make installations idempotent. `ADDON_LOADED` for Baganator/_FluxUI and `PLAYER_LOGIN` provide late-start opportunities.

The compatibility files are TOC-loaded even when Baganator is absent; most meaningful work returns until its API/dependencies exist. Missing optional APIs suppress individual registrations instead of making Baganator a required dependency. Available Baganator API/mixin/config shapes still define what the bridge can do; this is not a version-independent public compatibility guarantee.

[`FluxBaganator_ItemViews.lua`](../BaganatorCompat/FluxBaganator_ItemViews.lua) tracks visible backpack/bank views, skin-registered item buttons and pooled items. `ResolveBaganatorItemButtonSlot` resolves live bag/slot identity rather than relying on a button's display label. New pooled frames receive installation hooks; visible-only traversal keeps refresh work tied to actual surfaces.

## Features and ownership

| Bridge | Implemented behavior |
|---|---|
| [`FluxBaganator_Junk.lua`](../BaganatorCompat/FluxBaganator_Junk.lua) | Registers the `FluxUI` / `fluxui` junk plugin. It asks Flux's slot protection and display classifier, then lets Baganator provide junk/category presentation. Rule/item-data changes request coalesced widget/search refreshes. Ordinary bag moves already refresh through the bag ecosystem. |
| [`FluxBaganator_GearSets.lua`](../BaganatorCompat/FluxBaganator_GearSets.lua) | Publishes Respec profiles and named equipment presets through Baganator's item-set source. Builds identity-aware live gear mappings and icons, using the current inventory facade rather than the unloaded old FluxInv scanner. Double buffering avoids requesting a layout pass when the mapping did not change. |
| [`FluxBaganator_EquipmentSetSection.lua`](../BaganatorCompat/FluxBaganator_EquipmentSetSection.lua) | Ensures a separate **Equipment Set** section in Baganator's active configuration containing `default_auto_equipment_sets`, apart from ordinary Weapons/Armor equipment categories. |
| [`FluxBaganator_CategoryIcons.lua`](../BaganatorCompat/FluxBaganator_CategoryIcons.lua) | Applies saved/live profile or preset icons to managed category labels. |
| [`FluxBaganator_ConsumablesCategories.lua`](../BaganatorCompat/FluxBaganator_ConsumablesCategories.lua) | Maintains **Consumable Presets**, one category per NC preset including Default. Explicit added-item categories have higher priority than Baganator's ordinary food/potion/consumable categories. |
| [`FluxBaganator_Protection.lua`](../BaganatorCompat/FluxBaganator_Protection.lua) | Installs per-button Respec click guards, batches protection refreshes, and guards the cursor-sale path. |
| [`FluxBaganator_CategoryVendorBlock.lua`](../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua) | Filters protected items from wrapped merchant actions/transfers and blocks bulk transfer/right-click actions for Flux-managed set categories. |
| [`FluxBaganator_GearSetContext.lua`](../BaganatorCompat/FluxBaganator_GearSetContext.lua) | Treats protected vendor gear as a context mismatch so it fades like an unsellable item when Baganator context fading is enabled. |
| [`FluxBaganator_GearSetShield.lua`](../BaganatorCompat/FluxBaganator_GearSetShield.lua) | Registers the Flux gear-set corner widget and replaces competing built-in equipment-set corner/border decoration with the Flux shield configuration. |
| [`FluxBaganator_BankRestock.lua`](../BaganatorCompat/FluxBaganator_BankRestock.lua) | Tracks bank views/live-state signals, attaches the Flux restock button, and connects bank visibility/lifecycle to shared inventory state. |

Consumable category ownership is deterministic when a listed item belongs to multiple presets: the active preset wins; otherwise the first alphabetically traversed owner is retained. Source keys use the `flux_nc_cons_` prefix and a sanitized preset-name key. The bridge reconciles its managed sources/order entries instead of treating every Baganator category as Flux-owned.

Gear categories represent the retained saved snapshots and allocated live items; an unchecked apply-mask slot may still belong to saved equipment and remain protected. Category naming, membership, shield visibility, sale permission, and actual withdrawal access are separate decisions. The category blocks do not require the user to stop equipping or inspecting their saved gear.

## Configuration and global API effects

The bridge reads the active profile inside `BAGANATOR_CONFIG.Profiles` when available, otherwise the older flat configuration. Section/category order and contents, the Equipment Set section, managed consumable categories and corner arrays therefore persist through **Baganator's** own settings store. There is no separate Flux Baganator options tab or standalone compatibility SavedVariable.

`ConfigureBaganatorGearSetCorners` removes `equipment_set` and `equipment_set_icon` from configured corner arrays, inserts the Flux shield at bottom-left, and sets `icon_equipment_set_border = false`. It triggers `PluginsUpdated` and a layout/widget refresh. This is a deliberate configuration change, not simply an extra transient texture.

`InstallItemIdentityCache` in `Loader.lua` wraps the global `C_Item.GetItemGUID` and `C_Item.DoesItemExist` functions once Baganator is ready. For table locations with `bagID`/`slotIndex`, it caches answers per bag/slot until relevant `BAG_UPDATE` or `PLAYERBANKSLOTS_CHANGED` invalidation. Other location shapes delegate to the original function. The GUID wrapper returns nil without querying the original GUID for known non-Armor/non-Weapon item classes. These wrappers are shared global behavior while installed, not Baganator-private API calls.

`InstallSellCursorBlock` wraps global `SellCursorItem`. If cursor metadata identifies a Respec-protected bag slot in merchant/disenchant context, it clears the cursor, reports the block and declines the original call. Otherwise it delegates. Category/vendor integration also wraps view `RunAction`, `Transfer`, `TransferCategory`, and available category-button mixin interaction methods, retaining originals for unhandled paths. Existing hook flags avoid stacking the same wrappers repeatedly.

## Refresh and protection data flow

Respec profile/preset changes rebuild set information; inventory changes refresh live allocations. `GEAR_SET_LOCK_CHANGED`, bag-show, merchant-open/close and relevant skin/widget callbacks request protection refreshes. `WithContextSnapshot` shares merchant/disenchant state while walking visible buttons. Generation/cache keys skip unchanged button work.

The bridge deliberately avoids attaching an expensive full protection refresh to every `SetItemDetails` or view-complete callback. Corner-plugin and targeted invalidations handle pooled slot changes. Junk list/visual listeners debounce refreshes, and `RequestBaganatorRefresh(includeLayout)` copies its base reason list before adding layout, so a one-time layout request does not permanently alter every later widget update.

An icon/shield is presentation; the final live action still checks bag/slot protection and context. Unknown/missing item identities and recycled buttons require refreshing through those generation/skin paths. Source inspection does not prove that every third-party view or future Baganator mixin is intercepted.

## Bank integration

`ForEachBaganatorBankView` visits discovered native/skin-specific bank views; `GetActiveBaganatorBankView` prefers the bank restock button's resolver. `SyncBaganatorBankLive` considers shown view state, live tabs, transfer controls and shared fallback detection, then calls `Inv.SetBaganatorBankLive`. `BankViewChanged`, `BankShow`, `BankHide`, `SetButtonsShown`, native banker events and skin callbacks can trigger attachment/state refreshes.

Shared inventory exposes open/readable, live-bank and withdrawal checks separately. The compatibility layer uses UI/latch heuristics to bridge versions where live markers arrive late. A bank count in the account ledger does not establish server access; actual pickup/split verification remains in the [bank engine](20-vendor-restock-junk.md). The bridge's visibility heuristics should be read as source behavior rather than a proof that every cached/alternate-character bank view is classified correctly in game.

## Related references and limits

[Inventory](21-inventory-foundation.md) owns facts and Syndicator delegation; [Vendor/Junk](20-vendor-restock-junk.md) owns targets, verdicts, sale sessions and movement; [Respec](23-respec.md) owns identities and protection; [Extra Buttons](12-extra-button-system.md) owns consumable presets. The [integration matrix](29-integrations.md), [saved variables](32-saved-variables.md) and [source coverage](30-source-coverage.md) describe the surrounding ownership.

Integration is automatic when dependencies become available. Its global wrappers, persistent Baganator configuration edits, pooled-button assumptions and bank heuristics need live checks with the actual installed Baganator/Syndicator versions. No compatibility repairs or settings changes were made by this documentation rewrite.
