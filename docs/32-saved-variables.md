# SavedVariables and schemas

The [TOC](../_FluxUI.toc) declares **nine account-wide roots and fourteen per-character roots**. [Core/DB.lua](../Core/DB.lua) ensures tables for most retained names; individual features own schema/defaults/migrations. `FluxPerfCaptureDB` is declared but is owned directly by the capture module, not the Core bootstrap lists.

This is schema documentation, not a dump of personal saved values. [Declaration/reference evidence](reference/declarations.md) distinguishes loaded consumers from unloaded source. Exact-token references are discovery aids: alias-based access and constructed keys require tracing the owner.

## Account-wide roots

| Root | Current owner, shape and role |
|---|---|
| `FluxUI_DB` | Shared feature roots, setup flags, per-character setup markers, legacy/account customization. Current branches include `defaultFluxBindingsChecked` (one-time account/character native binding-set seed), `nameplateSizeDefaultV2` (one-time old-size migration), `nameplateThreat`, `CharacterStats`, `MicroMenu`, `ExtraButtonCategories`, `ExtraButtonSettings`, and flight-route data. Owners apply their own defaults; there is no single universal versioned schema. See [persistence](09-persistence.md). |
| `FluxUI_Options` | AceDB store created by `AceDB:New`. AceDB manages profile keys/profiles plus `char` and `global` domains. `FluxOptions.db.profile` is the effective profile, not a persistent top-level `FluxUI_Options.profile` field. [Options bootstrap](../AddonOptions/FluxOptions.lua#L1628); [declared defaults](reference/defaults.md). |
| `FluxNonCombatGridDB` | Smart hearth/mount and retained teleport/food data. Includes a `global` block and character-keyed records; individual smart-button scopes select their stores. Food's `preferRecuperate` migrates to true character storage. [Hearth](../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua), [mount](../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua), [food migration](../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua). |
| `FluxFlyoutFavorites_Data` | Account file containing character-keyed favorite categories/modifier entries. Account-wide declaration does not make favorites shared between characters. [Favorites](../ExtraButtonSystem/FlyoutEngine/Favorites.lua). |
| `FluxUIGoldLedger` | Account gold history/character rows and visibility/deletion state. Inventory Store/Ledger participates in current reads; legacy-compatible ledger behavior remains. [Gold ledger](../StatusBars/FluxGoldLedger.lua), [Store](../Inventory/Store.lua), [Ledger](../Inventory/Ledger.lua). |
| `FluxSalvageDB` | `enabled=true`, `modifier="ALT"` when absent. `CTRL` and `SHIFT` represent Alt+Ctrl and Alt+Shift, not those keys alone. [settings](../Salvage/FluxSalvage_Settings.lua). |
| `FluxInvDB` | Still active for profession cache: `professions[characterKey].bySkillLine`. It is not proof that the old FluxInv scanner is loaded. [profession store](../Inventory/Professions.lua#L160). |
| `FluxUIInventoryDB` | Builtin account inventory ledger, schema initialized with `Version=1`, `Characters`, `Guilds`, `Warband`, `Pending`, `Summaries`. When Syndicator supplies storage, the Store facade delegates instead of maintaining this as the current writer. [Store](../Inventory/Store.lua#L42), [inventory](21-inventory-foundation.md). |
| `FluxPerfCaptureDB` | Last completed diagnostic capture. Stores client/build/profiling information, CPU/FPS/environment data and ranked sampled rows. Replaced by subsequent completed captures; not an ongoing telemetry database. [capture owner](../Other/FluxPerfCapture.lua). |

## Per-character roots

| Root | Current role |
|---|---|
| `_FluxUI_CharSavedVars` | Main feature-owned character root. See branch map below. Independent from AceDB's `char` domain. |
| `FluxNCUtilitySlotsDB` | Active four utility slots: `slots[1..4][modifierKey] = actionDescriptor`. [assignment and snapshot owner](../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua). |
| `FluxBindingDB3` | Active binding schema version 3, normalized by Binding/Core/DB. No automatic migration from the retained old dual binding DB. [schema](../Binding/Core/DB.lua). |
| `FluxNCFlyoutCharDB` | Active per-character flyout hide/order: `classSpells`, `teleportItems`, `mountItems`, each with `hidden` and `order`; `_importedLegacyAceNcFlyout` guards one-time import from old Ace actionbar settings. [owner](../ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua). |
| `FluxSpellBookSlotsDB` | Retained/bootstrap declaration; current utility assignments use `FluxNCUtilitySlotsDB`. No active feature consumer beyond bootstrap was found in the current load closure. |
| `FluxSpellBindingProfilesDB` | Retained/bootstrap legacy declaration; current binding document is `FluxBindingDB3`. |
| `FluxSpellDirectBindDB` | Retained/bootstrap legacy declaration; current binding document is `FluxBindingDB3`. |
| `FluxSpellProfileBindingsDB` | Retained/bootstrap legacy declaration; current binding document is `FluxBindingDB3`. |
| `FluxBindingProfilesPerStateDB` | Retained/bootstrap legacy declaration; form subprofiles now live inside binding rows. |
| `FluxBindingDBv2` | Retained/bootstrap legacy declaration; not the active v3 document. |
| `FluxTradeSkillScannerDB` | Retained/bootstrap declaration; current recipe cache uses `FluxInvDB.professions`. |
| `TrinketMenuOptions` | Retained/bootstrap declaration. Current loaded FluxTrinketMenu implementation does not read/write this root; visual state and runtime combat queue must not be inferred from this name. |
| `TrinketMenuPerOptions` | Retained/bootstrap declaration, no active feature consumer found. |
| `TrinketMenuQueue` | Retained/bootstrap declaration. Current `FluxTrinketMenu.CombatQueue` is a separate runtime table. |

“Retained/bootstrap” means declared and ensured, with no active feature use found in this snapshot. It is not permission to delete the saved table or a compatibility guarantee for external addons.

## Main character branch map

| Branch / fields | Owner and contents |
|---|---|
| `Restock` | Merchant/restock/junk settings, targets, overrides and tier state. See defaults below and [economy](20-vendor-restock-junk.md). |
| `Bank` | FluxBank-owned remembered bank/settings state; distinct from deleted legacy restock snapshots. [bank adapter](../Inventory/Restock/FluxRestock_Inv.lua). |
| `ConsumableBest` | `refs` and `vendorSeen`; only non-conjured eligible best references persist. A reference records item ID, effective/percentage restoration, count and source. [persist owner](../Inventory/FluxConsumableBest/Persist.lua). |
| `respec` | `activeName`, `profiles`, `settings.protectGearSetItems=true`, selected/armed state, last trainer fee, and persisted load checkpoints. Presets/indexes use their separate feature-owned branches. [core](../Respec/FluxRespec_Core.lua), [respec schemas](23-respec.md). |
| `infoFrame` | `showFPS=true`, `showPing=true`, `showDurability=false`, `pinnedStats={}`, `spellDisplayMode="off"`, `statOrder={}`, plus owner-normalized extensions. [InfoFrame](../StatusBars/FluxInfoFrame.lua#L99). |
| `MicroMenu` | Native row state/visibility/order bridges and `tradeSkills={enabled=true,layoutMode="fixedSplit",globalStyle="allIndividual",perSkill={}}`. Profession visibility is character-only regardless of bar scope. [config](../MicroMenu/FluxMicroMenuConfig.lua), [professions](../MicroMenu/FluxTradeSkillMicro.lua#L42). |
| `CharacterStats` | Character-specific stat-panel preferences, paired with account `FluxUI_DB.CharacterStats`. [shared owner](../CharacterInfo/Shared.lua). |
| `ExtraButtonCategories`, `characterDisplayOrder`, `hiddenGlobalCategories` | Character category entries, mixed-scope display order and local hiding of shared categories. Shared categories remain in `FluxUI_DB.ExtraButtonCategories.Account/Class/Realm`. [category bootstrap](../ExtraButtonSystem/ExtraButtons/Core.lua#L56). |
| `food.preferRecuperate` | True character preference, with one-time import of older character-keyed account data. [food](../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua). |
| Hearth/mount character-mode fields | `hearthConfig` / `mountConfig` / `mountMode`, using the shared `_FluxUI_CharSavedVars.useCharacterSpecific` flag for hearth/mount character mode; independent of Ace Action Bars scope. [hearth](../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua), [mount](../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua). |
| `consumables` | `{presets[name]={items,restockTargets},activePreset="default",refreshThreshold=300,groundAuras}` plus owner-normalized extensions; time threshold is seconds. [consumable owner](../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua), [grid config](../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua). |
| `fluxWindowActiveTab`, `fluxWindowMapMode`, tab configuration and meter layout | Selected tab/map mode, hidden/order state and backend-specific meter cells. [window](../Battlezonemap/FluxWindowFrame.lua), [meter layout](../Battlezonemap/FluxMeterLayout.lua). |
| `fluxBattlefieldWorldMapFeatures` | World-map provider feature setting normalized by its owner. [world features](../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua). |
| `buyEmAllEnabled`, `buyEmAllConfirmLarge` | Both default enabled; true per-character bulk-buy settings. [BuyEmAll](../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua). |
| `minimapExtraButtons[1..15]` | Minimap-strip assignments and macro recovery. [owner](../Minimap/FluxMinimapButtons.lua). |
| `chronoboonVariants` | Consumable Chronoboon variant tracking. [owner](../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua). |
| `PVPTracking` | `trackHonor=false`, `trackArena=false`; character flags independent from Status scope. [owner](../StatusBars/FluxPVPTracking.lua). |
| `flightPathNodes` | Character route/node observations, alongside account `FluxUI_DB.flightPath.overrides[faction]`. [owner](../UnitFrames/FluxFlightPath.lua). |
| `fluxChatConfigured` and chat-related state | First-run chat setup marker/feature-owned values; copy/URL settings instead live in AceDB global storage. [chat frame](../Other/FluxChatFrame.lua), [chat copy](../Other/FluxChatCopyPaste.lua). |
| Rank-up, PvP and inventory-mode state | Character runtime-policy preferences and compatibility values owned by SpellRank, PvPTracking and Inventory. See [bars](11-action-bars.md), [status](16-status-bars.md), [inventory](21-inventory-foundation.md). |

This map groups related feature branches; exact key names for extensions are defined by the linked owner. It does not flatten account/character/profile stores into one schema.

Stance order, hidden slots and custom slots live in AceDB `db.char.actionbars` rather than this character root. Item-currency rows likewise use AceDB `char.itemCurrency`, capped at 40 total rows with a trailing empty row appended while capacity remains. The `paperDollCollapsed` character field stores collapsed stat categories; its owner is [RetailPane](../CharacterInfo/RetailPane.lua).

## Binding v3 document

`FluxBindingDB3` contains `version=3`, `nextUid`, `bindings[uid]`, `chordStackOrder`, `badgeCornerOrder`, `formPageEnabled`, and `rankSyncNames`.

A binding row contains `uid`, `action={type,id,name,...}`, `key`, optional `placeId`, `fallback="ACTION_BAR"|"BINDING"`, `stickyRespec`, and `forms[formToken]`. Form rows contain `active`, `action`, `targets`, `load`, `macro`, and `badge` blocks. These structures are authored intent; secure buttons and compiled macros are derived runtime objects.

`DB.SetDocumentOverride(doc)` temporarily redirects normal document access for Respec preview. `EnsureLive()` explicitly bypasses the override. Sticky rows survive Respec snapshot application. Full field vocabulary/defaults and capture/apply behavior: [binding schema source](../Binding/Core/DB.lua), [binding system](13-binding-system.md).

Utility slot descriptors use spell/item/macro/mount/battlepet/toy/outfit identities plus their required action fields, keyed by canonical modifier chords. Outfit ID `0` is the clear action; positive sparse outfit IDs retain identity across player-facing index changes. Utility chords normalize in SHIFT/CTRL/ALT order with hyphens. Flyout favorites normalize CTRL/SHIFT/ALT with plus signs and `nomod`. These formats are different contracts; do not reuse one formatter for both.

## Restock defaults and normalization

[FluxRestockSettings](../Inventory/Restock/Core/FluxRestockSettings.lua) normalizes these fields in `_FluxUI_CharSavedVars.Restock`:

| Fields | Missing-value behavior |
|---|---|
| `autoRepair`, `autoRestock`, `autoSellGray`, `autoBankRestock` | Enabled only when explicitly `true`; default off. |
| `repairPriority`, `restockItems`, `restockShowNotSold` | `"personal"`, empty table, false. |
| `restockFoodWater` | `foodTarget=0`, `waterTarget=0`, inferior-food/water marking true. |
| `restockCombat` | Bandage/heal-potion/mana-potion targets 0; each inferior-tier marking true. |
| `pendingVendorTierSell.kinds`, `junkList` | Empty tables when absent. |
| `junkFilters` | `consumable`, `unusable`, `destroy`, `safe`, `conjureInferiorFoodWater` default true; `consumableLvl=0.15`. |
| `junkDisplay` | `glow=true`, `icons=true`. |
| `alreadyKnown` | Enabled; RGB 0/1/0; monochrome/debug/exclude false. |

`_defaultsApplied` is an owner optimization reset on addon load; consumers re-fetch this store rather than keeping a stale pointer across loading screens.

## Migrations, reset and persistence boundaries

- Character-name normalization is centralized in [PlayerName](../Core/API/Name.lua), including migrations for setup flags, AceDB identities, gold/inventory, favorites and noncombat stores. Canonical display names and persistent key formats are not interchangeable.
- Micro Menu imports customized old account profession settings into character storage and removes the old trade-skill branch. Food imports its old character-keyed account preference. Flyout layouts import old Ace `actionbars.ncFlyout` once.
- Restock deliberately **drops**, rather than migrates, `VendorAuto`, legacy `bankSnapshot`/`bankSnapshotTime`, nested restock snapshots and global `FluxRestockDB` on addon load. Current Bank storage is separate. Active Consumables Chronoboon paths can later recreate `_FluxUI_CharSavedVars.VendorAuto`; deletion at load does not imply the root has no remaining active consumers. [consumer](../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L441).
- Binding v3 begins from its own normalized document; old binding roots remaining in the TOC do not imply migration.
- Ace profile resets, independent tab resets, Micro Menu factory reset, clearing restock targets, and defaults-pack application affect different stores. See [options](26-options-map.md) and [defaults](05-defaults-and-bindings.md).
- The game persists declared SavedVariables on normal reload/logout. These docs do not read or edit WTF files, and an in-memory change is not proof it was flushed to disk.

## Recent compatibility state

`Cap.hasSecureBarPaging`, paging-probe results, pending grid/tracker work and pin-router refresh generations are session state. They add no SavedVariable root, schema version or profile selector. Questie owns its `trackerEnabled` and persisted `TrackerWidth`; those companion fields are outside FluxUI's TOC declarations. Flux's existing Map Pins control and layout settings continue to use their existing stores. [Persistence](09-persistence.md), [integrations](29-integrations.md).
