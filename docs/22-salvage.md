# Salvage: modifier-driven item processing

`FluxSalvage` supplies a single secure overlay over an eligible bag item. Hold the configured modifier, hover the item, inspect the colored affordance, and click to perform the selected profession/opening action. It is an interactive item-processing surface; it does not queue an unattended full-bag salvage pass.

## Runtime pieces and activation

[`FluxSalvage.lua`](../Salvage/FluxSalvage.lua), `InstallHooks`, starts tooltip/bag hooks on login, retries after Blizzard bag/UI loads, and subscribes to inventory bag changes. Spellbook, specialization, and skill changes invalidate spell/classification/profession caches. `RegisterInvListener` uses the shared `FluxInv` bridge with bag-region light delivery and deferred-heavy work.

| Source | Responsibility |
|---|---|
| [`FluxSalvage_Settings.lua`](../Salvage/FluxSalvage_Settings.lua) | Account-wide `FluxSalvageDB`, enable state, modifier selection and modifier callbacks. |
| [`FluxSalvage_Classify.lua`](../Salvage/FluxSalvage_Classify.lua) | Spell knowledge, profession/skill rank requirements, supported item families, positive/negative classification cache, opening keys and Respec protection query. |
| [`FluxSalvage_Tooltip.lua`](../Salvage/FluxSalvage_Tooltip.lua) | Resolve bag/slot from native or compatible button owners, hook native bag enters and tooltip setters/post-calls. |
| [`FluxSalvage_Overlay.lua`](../Salvage/FluxSalvage_Overlay.lua) | `FluxSalvageOverlay`, secure click attributes, owner anchoring, action setup, modifier visibility and combat-deferred mutations. |
| [`FluxSalvage_Colors.lua`](../Salvage/FluxSalvage_Colors.lua) | Shared color identities for processing families. |
| [`Data`](../Salvage/Data/keys.lua) | Loaded key/opening and salvage eligibility tables; the complete resource inventory is in [Assets](34-assets.md). |

The loaded data covers keys, non-disenchantable and exceptional disenchantable items, millable herbs, prospectable ores, crushable/scrappable/shatterable/transmutable items, and openables. These tables are evidence of supported candidates, not a promise that every listed operation is present on every client or character. Spell/rank checks still govern the live action. Attribution remains with [Salvage's attribution file](../Salvage/ATTRIBUTION.txt).

## Hover-to-action flow

`HandleBagButton` first checks enabled state, combat, modifier, carried-container membership and tooltip availability. `ResolveBagSlotFromOwner` understands native slot/bag methods and compatible button fields; `ResolveBagItem` can provide a bag-backed item even where item-location methods are absent. The tooltip path also handles the recipient's nontraded trade slot for opening/lockpicking.

`HandleTooltip` rejects combat, vehicle UI, visible equipment flyouts and auction windows, then resolves the actual item and live skill hint. `IsSalvageable` tries a comprehension hint, the registered profession salvagers, then spell-based opening. If none matches, usable opening-key items are considered. A miss is cached only when item information is ready, so cold data does not permanently classify an item as unsupported.

Disenchant (spell 13262) additionally excludes the non-disenchantable list, cosmetic items when that API is available, and bag slots protected by `FluxRespec.GearSetLock`. Required stack quantities are checked before arming the overlay; insufficient quantity adds the game error hint and leaves the action unarmed. The overlay performs one selected action on the resolved location.

| Action family | Visible identity and selection evidence |
|---|---|
| Prospect / crush | Red; data match plus available spell/skill checks. |
| Mill | Green; eligible herb and learned milling capability. |
| Disenchant | Purple; learned spell, eligible quality/item, exclusions and saved-gear protection. |
| Comprehend Scroll | Mage blue; learned spell plus Comprehension skill meeting the scroll requirement. |
| Open / lockpick / opening key | White; spell or usable key matched against the item's requirement. |
| Scrap | Cyan; supported data and available action. |
| Transmute | Blue; supported data and available action. |

Colors identify the family; they do not establish whether an operation can succeed server-side. The full decision order and exceptional IDs remain in the classifier/data sources rather than being approximated as item-name rules.

## Client differences and secure execution

The overlay inherits secure action/handler templates and registers down/up clicks. `ApplySpellToBagSlot` writes the bag, slot and spell action; `ApplyItem` writes an opening-key action. `SetOverlaySpellAction` selects the supported spell/macro path. Retail salvage can use the `CraftSalvage` macro route where appropriate; Classic-style spells and Forever's bag-slot casts follow their separate path. Trade-slot opening uses a cast plus target-trade-slot click macro.

Forever identifies Comprehend Scroll through learned spellbook knowledge and localized name fallbacks, then checks the **Comprehension secondary skill**. It is not treated as a profession or automatically learned from possessing a scroll. Its mill/prospect/disenchant paths use Classic spell identities and profession rank gates. The combined-bag hook reads bag/slot directly instead of depending on `Item:GetItemLocation`.

`S.Defer` and `DeferMethod` retain protected changes during combat and flush on `PLAYER_REGEN_ENABLED`. Modifier attribute drivers are installed when restricted snippets work; the module also has explicit non-snippet behavior. `AnchorOverlayToOwner` checks owner visibility and anchoring restrictions/secrets before positioning; a visible overlay refreshes its owner anchor on a short interval. Existing OnUpdate work therefore belongs to an active interaction, not an unconditional full inventory scan.

Changing modifier or releasing it updates/hides the overlay, and delayed bag updates re-evaluate its current context. The code declines unsafe hover processing during combat; it does not promise that an already-hovered item will automatically process when combat ends. Native protected execution and client taint still require in-game verification.

## Settings, storage, and command surface

`FluxSalvageDB.enabled` defaults true and `modifier` defaults `ALT`; this is account-wide storage independent of General/Ace profiles. The selector's internal values are easy to misread:

| Stored value | Player combination |
|---|---|
| `ALT` | Alt without Ctrl or Shift. |
| `CTRL` | Alt + Ctrl. |
| `SHIFT` | Alt + Shift. |

`SetModifier` invokes registered callbacks with the stored modifier value; settings UI also installs hooks when enabled, hides the overlay when disabled, and refreshes visibility drivers. The settings builder is [`FluxOptionsSalvage.lua`](../AddonOptions/FluxOptionsSalvage.lua), currently embedded under **Inventory → Salvage**.

`/fsalvage` and `/fluxsalvage` accept `toggle`, `on`, `off`, and `status`; other/empty input opens the Salvage options surface when available. Status prints enabled/modifier/hook state and Comprehend spell/rank diagnostics. Hook installation is guarded, so toggling on reuses existing hooks rather than registering a second complete set.

## Dependencies and interpretation

[Inventory](21-inventory-foundation.md) supplies carried-container facts, spell/profession knowledge and invalidation. [Respec](23-respec.md) supplies slot-aware disenchant protection; [Baganator](24-baganator-compat.md) supplies compatible view/button contexts when installed. [Options](26-options-map.md), [commands](31-commands-and-bindings.md), [saved variables](32-saved-variables.md) and [API/events](33-api-and-events.md) list the complete interfaces.

An absent overlay can be intentional: disabled setting, wrong modifiers, missing spell/rank, unsupported data, cold item data, insufficient stack, protected gear, vehicle/AH/equipment-flyout context, or combat. Those source-derived gates should be checked before interpreting absence as a rendering failure. The existing Core smoke includes a failing historical visual-fill assertion; this reference does not claim that all fallback glow artwork has been validated in game.
