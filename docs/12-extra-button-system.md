# Extra buttons, consumables, travel and flyouts

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

<!-- STRESS-FIXES-20261107 -->
7 November applied stress fixes: Effective-alpha readiness tolerates a denied getter without treating it as declassified data. Classic cooldown-ring alpha uses its existing public write ownership. Ordinary utility execution and saved assignments are preserved. [Evidence](../Stress%20test%20doc/applied-fixes/README.md). Native taint/pixels/performance acceptance remains pending.
<!-- /STRESS-FIXES-20261107 -->

The Extra Button System provides reusable secure buttons for combat/noncombat grids, utility slots, custom categories, minimap buttons, pet/stance faces and badges. `Flux.EBS` is its implementation namespace; global `FluxBtn`/`FluxButton` facades support older consumers. [Init.lua](../ExtraButtonSystem/Init.lua) is authoritative. Older `Engine/` and `Flyout/` implementations coexist on disk but are not all TOC-loaded.

## Shared engine

| Loaded component | Responsibility |
|---|---|
| [Widget](../ExtraButtonSystem/Engine/Widget.lua) | Create/attach native secure widgets, choose kind, register clicks, bind locked hosts and expose facade methods. |
| [Action](../ExtraButtonSystem/Engine/Action.lua) | Assign/clear/pick up/receive dragged actions; resolve spell/item/macro/mount/assistant identities; translate macro display. |
| [Paint](../ExtraButtonSystem/Engine/Paint.lua) | Cached icons, counts, cooldowns, usability, flash, checked/equipped/glow display and dirty batching. |
| [Watch](../ExtraButtonSystem/Engine/Watch.lua) / [Range](../ExtraButtonSystem/Engine/Range.lua) | Connect shared context/events/inventory to targeted refresh; arm range work only when demanded. |
| [Style](../ExtraButtonSystem/Engine/Style.lua) / [Badge](../ExtraButtonSystem/Engine/Badge.lua) | Native/Flux ring chrome, scope colors, squeeze sizing and badge display. |

`FluxBtn.Create(parent, config)` creates a button; `Attach(widget, config)` adapts an existing one. Registry methods maintain `EBS.buttons`, `EBS.badges` and widget lookup. Action assignment differs from painting: a context change can alter the apparent macro face without rewriting protected attributes.

Template selection is client- and kind-specific. Only an eligible post-DF `kind="strip"` outside Forever/Camelot uses `ActionBarButtonTemplate`; Forever uses `ActionButtonTemplate, SecureActionButtonTemplate` and retains native mouse-up/key-down handling. The action adapter's historically named `WithRegistrationSuppressed` now calls through without replacing shared collector methods. The bar paging execution probe does not change EBS's other restricted-click/visibility policies. See [shared services](08-shared-services.md) and [binding routing](13-binding-system.md).

Macro parsing identifies required display probes and watches relevant context. Shared macro-click proxies provide stable `/click` destinations. [FluxTooltipGuard](../ExtraButtonSystem/Shared/FluxTooltipGuard.lua) isolates button tooltips; [HotkeyUtil](../ExtraButtonSystem/Shared/HotkeyUtil.lua) formats chords and batches binding refresh. Assisted Combat APIs are capability-gated; a visible setting does not create support on an older client.

## Combat grid

[Grid](../ExtraButtonSystem/CombatGrid/Grid.lua) supplies slots; [GridManager](../ExtraButtonSystem/CombatGrid/GridManager.lua) anchors them, creates modules and coordinates inventory/combat refresh. Loaded kinds are bandage, healing potion, mana potion, mana gem, healthstone and ammo. Consumables read shared inventory/best-of-kind facts rather than scanning every paint.

[ConsumableBind.lua](../ExtraButtonSystem/Engine/ConsumableBind.lua) supplies owned ladders, better-tier promotion, charge-aware counts, use/conjure macros, creation right-clicks, key overrides and tooltips. Mana gems distinguish charged later gems from single-use Vanilla gems, retaining the preferred usable item and choosing the next conjure spell. Healthstones similarly separate creation/use and learned-spell support.

Mana gem and healthstone item faces follow live item usability once bags are reliable, and both darken while dead or ghost. Empty charges remain dark; an unreliable load-screen snapshot retains the prior face. [The correction record](COMBAT_GRID_CONJURED_USABILITY.md) separates desktop checks from pending native tint and secure-use validation.

Portal/login snapshots can briefly collapse. `ShouldHoldItemIdentity()` and `KeepConsumableSlot()` retain useful faces while facts are unreliable; secure changes wait for safe application. A retained icon is not evidence that a fresh bag scan finished.

[Ammo.lua](../ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua) supports older ammunition and Forever durable throwing weapons. Durable throws display remaining durability, refreshed by equipment/durability events, rather than a stack count. Visibility also depends on class/client relevance.

## Travel, food and water

[GridInit](../ExtraButtonSystem/NonCombatGrid/GridInit.lua) constructs the noncombat grid. Its geometry shares squeeze/anchors with the action strip, combat buttons and trinkets.

| Module | Behavior |
|---|---|
| [Hearthstone](../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua) | Configured hearth/toy, item 6948 fallback, owned teleport items and modifier favorites. Simple mode right-click opens Toy Box when available; multi-item mode uses right-click flyout and middle-click Toy Box. Equipment teleports can require equipping; cast/equip locks retain selected identity. |
| [Mount](../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua) | Smart ground/flying selection and optional vendor mode. Middle-click toggles smart/vendor when relevant. Collection clients use journal/companion helpers and configured selections; bag clients use `MountItems.lua`, zone eligibility and favorites. Right-click follows the collection/bag path. |
| [TeleportPortal](../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua) | Known class teleports/portals, modifier favorites, reagent counts/restock links and flyout. Left-click casts; right-click opens the flyout or edits the reagent preset target for a single destination; middle-click toggles teleport/portal. Selection stays locked through its cast. |
| [Food](../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua) / [Water](../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua) | Best owned food/water, learned conjure/ritual alternatives, group-aware creation and counts. Food has a per-character Recuperate preference on clients supplying that spell; default remains food. |

[SmartMount config](../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua) supports account/character ground/flying/multi/utility selections and vendor discovery. [SmartHearth config](../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua) only loads when Toy Box capability exists; the basic hearth fallback remains usable without that editor. Their current character/account selection shares `_FluxUI_CharSavedVars.useCharacterSpecific`; the config tables themselves are separate. This scope flag is independent of Ace Action Bars scope.

Toy Box capability checks toy information and ownership separately from the
Collections Journal opener. The editor uses the earlier `Flux.Cap` capability
because `FLUX_API` is initialized after it in the TOC. `/fluxhearth config`
opens Toys; the adjacent Hearthstone selector's left-click flyout chooses an
owned toy or random mode,
and right-click restores the basic Hearthstone. The journal loader/opener
accepts the available modern or legacy client API. [Regression and native
limits](HEARTH_CONFIG_TOY_COLLECTION.md).

The selector tooltip reads item names through the shared `Flux.Item` service
and falls back to Toy Box metadata when item data is uncached. This keeps the
hover help available on clients without the deprecated `GetItemInfo` global.

## Buff-consumables presets

Shared item usability/range own consumable tint. A ready item is not darkened
by an uncastable effect spell or a stale parsed spell/charge identity. Genuine
empty/unusable/mana/OOR feedback and buff countdowns remain. Managed item faces
survive both macro-evaluation paths; switching items resets stale tint caches.
[Evidence](validation/consumable-tint-focus-aura-2026-11-07.json).

[Consumables.lua](../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua) stores ordered named presets in `_FluxUI_CharSavedVars.consumables`: active preset, items, refresh threshold and learned ground-aura associations. Left-click uses the first eligible item; right-click opens [ConsumablesConfig](../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua). The editor manages item order/presets, thresholds/restock targets and displays cooldown/charge/bag/bank counts using shared [grid cells](../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua).

Eligibility checks ownership, cooldown, aura duration, Well Fed equivalence, weapon enchant applicability and supported families. When covered buffs exceed the refresh threshold, the display enters **wisp lock**. Weapon-enchant selection can prefer the weapon needing replenishment. Ground-placeable items can learn their aura association. Applicable Classic clients also handle regular/supercharged Chronoboon variants, world buffs and restock quantities.

The button, wisp lock, and config cell buff countdowns end at the refresh threshold (`buff remaining − threshold`), when the item becomes eligible again. Actual item cooldowns remain separate; see [consumable refresh timer](CONSUMABLE_REFRESH_TIMER.md).

Configured items now show detected flask/elixir/Well Fed food/weapon-enchant
category in the existing tooltips. A weapon enchant with an explicit tooltip
weapon-type restriction is counted and targeted only when an equipped weapon
matches its numeric subclass; equipment changes refresh the selection. The
button's effective zero does not erase physical bag counts for restock. Unknown
tooltip restrictions and native acceptance are tracked in
[CONSUMABLE_TARGET_DETECTION.md](CONSUMABLE_TARGET_DETECTION.md).

The helper prepares protected actions while allowed. Combat or unreliable inventory can defer a newly selected action; eligibility Lua does not allow arbitrary secure rewrites mid-fight. Respec restores the selected preset link, while [restock](20-vendor-restock-junk.md) consumes quantities from these presets.

Preset quantities live in `presets[name].restockTargets`. Chronoboon code also retains an active `VendorAuto.restockItems` compatibility reader/writer and can recreate that old character branch after restock's startup cleanup. Treat this as the current mixed persistence path, not proof that all legacy restock data has disappeared; see [saved variables](32-saved-variables.md) and [findings](40-findings.md).

## Utility slots and custom categories

Four utility slots use [Assign.lua](../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua) for cursor parsing, normalized modifier assignments, clearing, base/preferred fallback and snapshots. [Manager.lua](../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua) builds macros, paints the modifier face and installs keys. Spell/item/macro/mount/battlepet/toy/outfit support follows available cursor/client APIs. Native outfit ID `0` represents the draggable clear action; outfit variants use exact modifier attributes to prevent unintended clears. Assignments are per character; snapshot helpers support Respec and legacy spellbook-slot conversion. Empty slots are exposed for assignment/binding workflows as needed. See [transmog actions](48-transmog-actions.md) for clear-first flyouts, EBS dragging and validation.

Utility spell/item modifier combinations prepare native spell/item attributes for
all eight exact modifier chords outside combat. Spell/item actions use the native
secure handlers; macro-text execution and hidden click delegates are removed
from this ordinary path. Exact saved IDs drive icons, tooltips, counts, cooldowns
and VFX, including ranks whose names cannot be reverse-resolved. Utility items
show their actual item cooldown; consumable aura timers remain on the dedicated
consumables button. Counts update live and combat release restores the base face.
Both keys include assigned modifiers. Each ordinary utility key carries its
triggering chord in a distinct native virtual button, so dispatch does not
re-infer it from the current modifier queries. Mouseover uses the same encoded
prefix. Binding installation follows action preparation; clear retires every
virtual payload. Already modified primary/secondary keys keep their full chord.
Existing AnyDown parent-inheriting keyers
serve clients without KeyBind remapping; other clients retain CVar timing.

Enabled mouseover uses the shared service's secure click-time target picker,
with each modifier action's helpful/harmful classification and native modifier
gate. Ineligible/missing mouseovers retain normal targeting; the temporary unit
clears after clicking. Range shares the selected reaction during existing hover
cadence. No hover driver or polling is added. Forever uses the existing repaired
VM probe for these target wrappers; a failed probe or partial installation is
not mouseover acceptance. Special macro/pet/mount/toy/outfit routes remain.
Clearing removes all native modifier actions; dropping an assignment suppresses
the old native action. Shared cast/reticle/finish/interrupt/proc effects follow
the current identity and clear when it departs.
[Regression and native limits](UTILITY_MIXED_FACES.md).

[ExtraButtons/Core.lua](../ExtraButtonSystem/ExtraButtons/Core.lua) stores category/button entries at account/class/realm/character scope and tracks display order. Categories can be created, deleted, reordered, collapsed and moved between scopes. [Categories](../ExtraButtonSystem/ExtraButtons/Categories.lua), [Buttons](../ExtraButtonSystem/ExtraButtons/Buttons.lua) and [UI](../ExtraButtonSystem/ExtraButtons/UI.lua) pool frames, render palettes, handle cursor drops/deletion controls and embed into the Flux Window **Buttons** tab. Saved entries are separate from pooled runtime frames. The minimap's 3×5 strip is another EBS consumer; see [minimap](18-minimap-and-trackers.md).

## Flyouts and trinkets

Teleport/portal counts follow native display text where available; reagent-free
spells clear the number. Interrupted casts restore the preset host without popup/
binding rebuild; destination eligibility skips reagent scans. Known legacy rune
counts/restock controls remain. [Regression/native limits](TELEPORT_CAST_WORK.md).

The loaded [FlyoutEngine](../ExtraButtonSystem/FlyoutEngine/Init.lua) supports up to 36 secure popup children. `BindHost`, `SetButtons`, `Toggle`, `Close` and `CloseAll` attach consumer-defined lists. Definitions, secure opener/child-close snippets, popup geometry, chrome, arrows and compatibility facades are separated. List/construction changes defer outside combat; prepared handlers can open/close in combat where supported. Only OPEN behavior is implemented in this pass; PRIME/RANDOM/CYCLE constants are not additional shipped behavior.

[Favorites](../ExtraButtonSystem/FlyoutEngine/Favorites.lua) stores per-modifier favorites, promotes available choices, paints stars and extends tooltips. [FluxNCFlyoutOptions](../ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua) stores per-character travel hide/order choices. Missing/zone-unusable favorites fall through to available entries. Favorites and popup layout are different data.

[TrinketMenu](../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua) presents equipped trinkets, scans bag alternatives, builds shared-engine flyouts and maintains the runtime `TM.CombatQueue` for swaps. The three older TrinketMenu SavedVariables remain declared but are not consumed by these active files. [Manager](../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua) anchors it and reacts to equipment, cooldown, keys, pet battles, scale and combat. Binding mode and trinket commands route to live widgets.

Equipped `/use 13` and `/use 14` faces retain the owned-item usability fallback even though the equipped item is absent from bag counts. A genuinely unusable use spell can still darken; empty slots remain desaturated. [The trinket tint correction](TRINKET_EQUIPPED_USABILITY.md) records the focused check and native limits.

1 November clarification: an equipped trinket without an on-use spell is dim; a ready on-use trinket remains bright.

## Controls and checks

[FluxExtraButtonVisibility](../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua) supplies mode cycles, relevance gates, binding-mode forcing and layout notifications. Mana Gem/Class Teleport offer Off/Auto; consumables use Hidden/Always. Food/water normalize saved Auto to Always, with further mana/relevance gates. The assistant policy exists but `GetOptionsIds()` currently excludes its icon from the visibility editor. [Options](26-options-map.md) records scopes/defaults, [custom widgets](35-custom-widget-controls.md) records detailed gestures and effective-mode rules, and [commands](31-commands-and-bindings.md) lists aliases.

Check use/conjure distinction, modifier favorites, empty/uncached items, charge exhaustion, portal holds, combat edits, zone-disabled bag mounts, cast locks and queued trinket swaps in game. Consumable/ammo mock harnesses cover selected logic, not Blizzard secure execution.

Syndicator bag updates now preserve every added/removed item across a batched
notification, so better consumables and last-use depletion reach selection.
[Regression and native checks](SYNDICATOR_CONSUMABLE_UPDATES.md).

Utility pet assignments now display the selected Pet Journal icon and GUID
tooltip, including modifiers and late journal metadata. The secure summon
macro and saved assignments stay intact. [Regression/native checks](UTILITY_PET_FACES.md).

Spell reagents, including class travel runes, appear in Preset restock; Soul Shards
are excluded from automatic reagent targets. Saved quantities and flags remain.
See [travel reagent controls](TELEPORT_REAGENT_RESTOCK.md).

8 November grid bag/craft correction: reliable live bags override stale positive
reagent snapshots. Existing craft coalescing also reevaluates Auto visibility;
Forever healing-potion First Aid routing is retained and regression checked.
Pending item classification survives metadata invalidation. Stored items do
not count as carried outputs/materials. [Scope and native checks](CONSUMABLE_BAG_VISIBILITY.md).
