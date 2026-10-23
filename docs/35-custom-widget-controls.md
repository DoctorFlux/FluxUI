# Custom option widgets and embedded editors

This chapter documents controls created **inside** custom widgets, beyond the native Ace option rows in [Options](26-options-map.md). It includes their gestures, storage owner, callbacks, defaults and lifecycle. A registered widget is not automatically a currently displayed options control: some remain compatibility constructors while the page renderer uses native rows.

## Hosting and common contracts

[`FluxOptionsRender.lua`](../AddonOptions/FluxOptionsRender.lua), `HostEmbed`, creates a named `dialogControl` through AceGUI, parents its frame into a native options row, sets width/text where supported and records it for release. These widgets generally read/write their owning module directly; their icon/grid interactions are not synthesized from the containing description row's `get`/`set`. Width/height callbacks keep the native row and embedded frame synchronized.

`OnAcquire` installs/attaches the visible surface and current-state listeners; `OnRelease` detaches hosts, hides ghosts/tooltips, clears active-widget references and unregisters or invalidates callbacks as implemented. Deferred callbacks check release/acquire generations in the widgets that use them. Closing options calls defensive cleanup hooks for active drag/grid editors. These lifecycles explain why an options page can have active event/timer work while open without a corresponding permanent HUD driver.

[`FluxOptionsWidgets.lua`](../AddonOptions/FluxOptionsWidgets.lua) provides the native text/toggle/range/select/color/execute row constructors around the embeds. Their page definitions, defaults, scope and hide/disable predicates are cataloged in chapter 26. The entries below are the additional authored editor behavior.

## Layout preview: placement choices rather than free dragging

`FluxLayoutPreview` is the Ace wrapper in [`AceGUIWidget-FluxLayoutPreview.lua`](../AddonOptions/AceGUIWidget-FluxLayoutPreview.lua); [`FluxLayoutPreviewUI.lua`](../AddonOptions/FluxLayoutPreviewUI.lua) owns the shared canvas. `AttachToAceWidget`, `DetachFromAceWidget`, `DrawPreview`, resize handling and options-close cleanup control that one surface.

Click a colored movable tile to select it, then click a faded allowed placement to apply it. Click the selected tile or empty canvas to cancel. Gray frames are references, not draggable free-position controls. The schematic combines live dimensions where available with client/layout fallbacks; it is not a screenshot and does not independently move every HUD frame.

| Movable piece | Stored field and allowed values | Default |
|---|---|---|
| Micro Menu | Layout DB `microMenuPosition`: 1 top, 2 beside chat, 3 beside minimap. | 2 |
| Status Bar | `statusBarPosition`: 1 under micro, 2 above action bar, 3 screen bottom. | 3 |
| Player/target pair | `playerTargetPlacement`: 1 Classic, 2 side-by-side. | 2 |
| Stance | `stanceBarPlacement`: 1 beside player, 2 by Flux Window. | 1 |
| Info | `infoFramePlacement`: `actionStrip`, `statusIntegrated`, `minimapTop`, `screenTopLeft`. | `actionStrip` |
| Micro columns | `microMenuBesideChatColumns`, integer slider 1–8 for applicable multi-column placement. | 2 |

`ApplyPosition` writes `FluxOptions:GetLayoutDB()` and calls `RefreshLayoutDependents`; the column slider does the same on value change. Layout's independent account/character scope owns these values. Player and target selection is coordinated as a pair. Reference layers include minimap/objectives/chat, raid/focus, action strip, pet bar and Flux Window; available client geometry changes their preview. See [Layout](06-layout.md) for actual placement relationships.

## Action Bars: visibility, utility, stance, flyout, and rank blacklist

| Widget | Actual controls and persistence |
|---|---|
| [`FluxExtraButtonVisibilityPanel`](../AddonOptions/AceGUIWidget-FluxExtraButtonVisibility.lua) | Click an icon to cycle that button's supported visibility modes through `FluxExtraButtonVisibility.Cycle(id)`. Border/badge and tooltip show current mode and relevant help. Stored under `GetActionbarsDB().extraButtonVisibility`, following **Action Bars scope**. |
| [`FluxSpellBookSlotsPanel`](../AddonOptions/AceGUIWidget-FluxSpellBookSlotsPanel.lua) | Four utility cells. Put an accepted spell/item/macro/mount/battlepet/toy on the cursor and left-release a cell; the currently held modifiers select that assignment variant. Right-click offers clearing one stored modifier or the whole slot. Uses `FluxNCUtilitySlots`, with per-character utility storage, not the surrounding Action Bars scope. |
| [`FluxStanceBarOrderPanel`](../AddonOptions/AceGUIWidget-FluxStanceBarOrderPanel.lua) | Left-drag native/custom stance icons to reorder. Right-click a native row toggles hidden; right-click a removable custom row deletes it. The **+ Add** cell accepts a spell/item/macro/mount/toy/pet cursor. Shows current binding labels and participates in binding-mode visuals. Always uses the character Action Bars DB. |
| [`FluxNCFlyoutPanel`](../AddonOptions/AceGUIWidget-FluxNCFlyoutPanel.lua) | Class teleport/portal, teleport-item and mount-item rows: left-click hide/show, left-drag reorder, right-click favorite using the current modifier combination. **Reset order and hide** clears those layout overrides. Hide/order lives in per-character `FluxNCFlyoutCharDB`; favorites use their separate owner/store. |
| [`FluxSpellBlacklistPanel`](../AddonOptions/AceGUIWidget-FluxSpellBlacklistPanel.lua) | Drop a spell to toggle its rank-up blacklist membership. Click an existing icon without a cursor spell to clear it; dropping the same spell toggles it off. Shows actual spell/rank tooltip. Uses `_FluxUI_CharSavedVars.spellRankManager.blacklist`; unsupported clients show **Classic only**. |

Visibility modes are not identical for every row. [`FluxExtraButtonVisibility.lua`](../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua) is the policy owner:

| Button family | Cycle and default |
|---|---|
| Single-Button Assistant | Policy declares Off/Auto/Always, default Off, but `GetOptionsIds` excludes this row from the current widget. |
| Bandage/heal potion/mana potion/healthstone/ammo | Off → Auto → Always; default Auto; client/character relevance still applies. |
| Mana Gem | Off → Auto; default Auto. |
| Hearthstone | Off → Auto → Always; default Always. |
| Food, Water | Declared list includes Auto, but saved Auto reads back as Always; the effective click cycle is Off/Always, default Always. |
| Mount, Trinket Menu | Off → Auto → Always; default Auto. |
| Class Teleport | Off → Auto; default Auto. |
| Consumables | Hidden → Always; default Always. |

Legacy/effective normalization also converts Mana Gem or Class Teleport Always to Auto; Food/Water/Mana Potion Always acts like Auto for a non-mana character. The mode display uses O/A/+/H badges. The containing page's reset action is separate from clicking a cell. `Always` does not manufacture missing class/client abilities. The panel's fixed-height strategy deliberately avoids parent-layout feedback loops while responsive icon positioning follows available width.

Utility visuals respond to `MODIFIER_STATE_CHANGED`; an unassigned modifier can fall back to the no-mod/mirror assignment like the live utility button. Tooltips enumerate stored variants. `A.OnPanelSlotsChanged` refreshes all cells, and release removes that handler only if it still belongs to this widget. The context-menu opener returns on Forever gamepad UI; it is therefore not an unconditional clear-menu promise on that client. Underlying assignment and secure application behavior remain in [Extra Buttons](12-extra-button-system.md).

Stance reorder writes `stanceBarSlotOrder` then calls `ApplySavedSlotOrderAndRefresh`; hidden/custom operations delegate to the stance owner. Manual drag code supplies an icon ghost and cancels safely on release/close. Empty/not-yet-loaded stance state has its own message. Binding-mode transitions suppress conflicting tooltip/drag presentation rather than treating editor preview icons as gameplay casts.

Flyout layout merges known entries with stored order and prunes unavailable class identities. Teleport/portal representatives can share destination grouping. Right-click favorites choose the corresponding Teleport/Portal identity for the current mode; item rows use their configured favorite category. Tooltips/stars show modifier-specific favorites. The panel calls `FluxNCFlyoutOptions.NotifyChanged` and listens for favorite changes. Resetting hide/order does **not** clear the separate favorites table. The migration from legacy Action Bars `ncFlyout` to `FluxNCFlyoutCharDB` belongs to [`FluxNCFlyoutOptions.lua`](../ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua).

Blacklist cursor acceptance asks `FluxSpellRankManager` to toggle the spell ID, then clears the cursor. Refresh hooks and item/spell readiness update names/icons; the visible rank label matters because different Classic ranks are distinct identities. This affects auto-rank and manual rank-all behavior, not a combat-time cast preference.

## Status Bars and Info custom editors

[`FluxItemCurrencySlots`](../AddonOptions/AceGUIWidget-FluxItemCurrencySlots.lua) reads `FluxItemCurrencyTracking.EnsureItemCurrencyData()` and edits the **per-character** `char.itemCurrency.slots` rows supplied by `GetItemCurrencyDB`.

| Gesture | Effect |
|---|---|
| Drop an item or cursor-item + click | Set the row's `itemId`, mark tracked, clear cursor, normalize row list and notify the status bar. |
| Left-drag an existing cell | Reorder the row table, normalize and notify. A movement threshold separates reordering from cursor placement. |
| Right-click | Set `itemId = 0`, `show = false`, normalize and notify. |
| Hover | Show the item/current slot and the replacement/reorder/clear instructions. |

The owner [`FluxItemCurrencyTracking.lua`](../StatusBars/FluxItemCurrencyTracking.lua) caps **total rows at 40** and appends one trailing empty add row while capacity remains. `show` is normalized from `itemId > 0`; there is no independent per-row on-bar toggle. At the cap, the code does not append another empty row. The separate containing-page enable toggle remains independent of row contents. This replaces historical six-slot descriptions.

[`FluxInfoStatOrder`](../AddonOptions/AceGUIWidget-FluxInfoStatOrder.lua) lists `FluxInfoFrame.GetOrderedVisibleStats()`: enabled FPS/ping/durability plus pinned stats. Left-drag reorders the shown entries and calls `FluxInfoFrame.SetStatOrder(keys)`. It changes per-character `statOrder`, not which stats are enabled or pinned. Empty state instructs the user to enable/pin a stat. Active-widget refresh and release cleanup keep the list synchronized with the [Info/Character](16-status-bars.md) providers.

## Inventory: restock grid and contained controls

[`FluxRestockPanel`](../AddonOptions/AceGUIWidget-FluxRestockPanel.lua) is the Inventory → Restock embed. It reads the shared target/classification service and creates five persistent sections: **Preset restock**, **Consumables**, **Manual restock**, **Useful**, and **Junk**. It has item/tier cells and direct module calls beyond any native Ace option row.

| Control/action | Data owner and behavior |
|---|---|
| Preset drop area | Accepts spell reagents; adds an item target, initially 1. Non-reagents are rejected here. Reagent warming populates automatically discovered candidates. |
| Manual drop area | Accepts items, initially target 1; detected spell reagents route to preset handling. |
| Manual item cell | Left-click edits target; right-click removes manual entry. Target ≤0 removes the manual target. |
| Reagent cell | Click edits its target; tooltip lists reagent-using spells. The displayed row is not a cast action. |
| Tier cells | Food/water/bandage/heal/mana target editing through the tier owner. Tiers appear before reagents in Preset restock; eligibility follows character/client services. Defaults are zero targets. |
| Item/tier coin | Toggle `countBank` through item flags or tier flags; refresh counts and merchant/target UI. It counts known bank stock toward policy, not a withdrawal command. |
| Tier refresh/reset icon | Confirmation forgets saved learned tier baseline and clears auto-junk marks for that kind, preserving the target and count-bank choice. |
| Consumables drop/cursor insert | Add or insert an NC consumable into the active preset; Chronoboon is excluded from ordinary item insertion. |
| Consumable left-drag | Reorder priority through `FluxNCConsumables.MoveItem`; left/right half insertion and drop handlers share the grid helper. |
| Consumable left-click | Edit its active-preset restock target; this target belongs to `FluxNCConsumables`, not automatically to a manual Restock item. |
| Consumable right-click | Remove that item from the preset. Shift-right-click first clears a learned ground-aura binding when one exists. |
| Consumables **Preset** menu | Switch active NC preset, refresh its cells and force dependent button evaluation. |
| **New** / **Delete** preset | Delegate name prompt/delete confirmation to `FluxConsumablesConfig`. They edit the shared NC preset collection. |
| **Refresh threshold** min/sec | NC aura-refresh threshold; each component clamps to integer 0–59 and combined zero becomes one second. Current fallback/default is 300 seconds. Enter applies; Escape restores the stored display. |
| Useful/Junk drop | `MarkUseful` or `AddJunk` changes the shared manual classification list. |
| Useful/Junk left-click | Move the item to the opposite manual list. |
| Useful/Junk right-click | Forget the explicit list decision and return to automatic classification. M/A markers distinguish manual and auto-marked rows. |

The target edit box commits on **Enter** or ordinary focus loss. **Escape** cancels/restores the previous target. Active edits postpone structural grid rebuilds so an item-data or bag event does not destroy the field being edited. Zero/default targets and list-removal semantics are routed according to the cell's source; item target rows and preset consumable rows are not interchangeable settings.

[`FluxConsumablesGridUI.lua`](../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua), `CreateConsumableCell(mode = restock)`, is the current shared implementation for consumable cells; the options widget retains fallback handlers too. The helper delegates Chronoboon target reads/writes to dedicated NC methods when that row is used. Its config-mode cells can show aura/cooldown state; those display timers are not new target values.

Count labels show bags/target plus relevant bank amount, with enough/short color feedback. Merchant-aware entries can dim unsold items or annotate lower available tiers. Inventory count pulses update mapped cells; list/category changes or newly resolved reagents require structural refresh. Bank/vendor/bag storms can defer heavy work; options close unregisters its inventory listener, stops panel timers and cancels pending rebuilds.

Inferior marking defaults live in tier settings and feed the **A** junk rows. The custom panel exposes the tier-baseline reset and list decisions; it does not create a new independent per-kind inferior checkbox merely because a persisted mark-inferior setting exists. Full classification/sale behavior is in [Vendor](20-vendor-restock-junk.md).

`FluxOptionsToggleGrid` is also registered by [`AceGUIWidget-FluxOptionsToggleGrid.lua`](../AddonOptions/AceGUIWidget-FluxOptionsToggleGrid.lua). `SetText(sectionKey)` resolves shared Automation/Junk/Display descriptors, creates responsive checkboxes, honors their hidden/disabled functions and calls each descriptor's setter. The **current** vendor builder converts those same descriptors into ordinary native toggle options using `AddSectionToggles`; it does not select this widget through a dialogControl. Native controls include repair/bulk-buy/large-confirm/guild-first/sell/restock/bank-restock, junk filters and bag indicators, with the exact defaults/gates in chapter 26.

## Flux Window tabs and meter layout editor

[`AceGUIWidget-FluxBattlezone.lua`](../AddonOptions/AceGUIWidget-FluxBattlezone.lua) registers two different types:

| Widget | Controls and owner |
|---|---|
| `FluxBattlezoneTabStrip` | Map/Meter/Respec/Buttons chips: click toggles enabled; drag reorders. Calls FluxWindowFrame `Get/SetTabOrder` and `Is/SetTabEnabled`, so storage follows the host's tab settings rather than this widget. Disabling the final enabled tab is refused with a message. Defaults are all enabled in normal order; reset is a separate containing-page action. |
| `FluxMeterLayoutEmbed` | Attaches the shared `FluxMeterLayout` editor, measures available width and resizes its row. If no Details/native meter backend is available it detaches and shrinks. Acquire/release and options resize control the editor host. |

The editor owner is [`FluxMeterLayout.lua`](../Battlezonemap/FluxMeterLayout.lua). The embedded and standalone editors operate on the same working layout/library:

| Meter control | Effect and limits |
|---|---|
| **Built-in** / **Saved** library tabs | Choose backend-specific built-ins or named user layouts. Details has eleven built-ins; native meter has six. Initial active ID is `builtin:1`. |
| **New** | Save a copy of the working layout as a new named library entry. |
| **Save** | Overwrite an active user layout or save a built-in-derived layout as a new user entry. |
| **Rename** / **Delete** | Rename via prompt or delete active saved layout; built-ins are not editable library records. |
| **Top 1/2/3**, **No Bot/Bot 1/2/3** | Change pane structure subject to backend constraints. Details permits up to three columns per row; native meter caps total panes at three. |
| Preview pane click | Select the pane whose meter type will be changed. |
| Type picker | Choose supported Details attribute/subattribute or available plugin, or a native meter category. Native path has no Flux threat-plugin pane. |
| Divider drag | Adjust row height split and column fractions, then re-embed/synchronize geometry. Row split source limits are 0.25–0.75; column minimum fraction is 0.10. |
| **Done** | Exit the standalone editor; the options embed uses its own host lifecycle. |

Details library/active ID are per-character `fluxWindowMeterLayouts`/`fluxWindowMeterActiveLayoutId`; native layouts use separate `fluxWindowBlizzardMeterLayouts`/`fluxWindowBlizzardMeterActiveLayoutId`. Legacy CSV/split/preset settings can migrate to the Details library. Backend switching does not flatten both libraries into one format. Preview fits the Flux Window's size; it does not replay measured combat data. [Flux Window](10-flux-window.md) explains actual meter hosting and capability gates.

## Micro Menu row editor

[`FluxMicroMenuConfigEmbed`](../MicroMenu/AceGUIWidget-FluxMicroMenuEmbed.lua) attaches/detaches [`FluxMicroMenuConfigUI.lua`](../MicroMenu/FluxMicroMenuConfigUI.lua), which also has a standalone editor. It displays one unified list of native rows, discovered minimap buttons and trade-skill rows. Each preview is backed by the actual row ID/source rather than an independent copied button configuration.

| Gesture/control | Behavior and storage |
|---|---|
| Left-drag icon | Reorder visible rows within the unified order, with wrapped-row drop calculation and an icon ghost. Unified ordering follows **Micro Menu bar scope**, separate from Layout placement. |
| Right/middle-click preview or click its mode strip | Cycle Off → Account → Character → Off for native/minimap rows. Native state lives under `FluxUI_DB.MicroMenu.native` / `_FluxUI_CharSavedVars.MicroMenu.native`; minimap rows delegate to MinimapToMicro. |
| Trade-skill row mode strip | Off → Character → Off; profession rows are always character-specific. |
| **Reset order** | Rebuild canonical unified ordering while preserving Account/Character/Off choices. |
| **Reset defaults…** | Confirmation restores canonical order, account-native rows, character-only profession rows and minimap rows Off; it clears both native visibility stores and minimap saved button state. |

Off previews are desaturated; character mode has its own tint overlay; labels/tooltips explain the cycle. Native row IDs, `M2M:` minimap IDs and `TSK:` profession IDs remain distinct. The editor updates `FluxMinimapToMicro.isConfigShown`, listens to config callbacks, and hides drag ghosts/detaches when closed. [Micro Menu](17-micromenu.md) gives its canonical default set and live bar rebuilding rules.

## Binding browser and editor-specific widgets

[`FluxBindingBrowserEmbed`](../Binding/UI/Browser/AceGUIWidget-FluxBindingBrowserEmbed.lua) delegates to `FluxBindingBrowser_Attach/Detach/OnHostResized` and synchronizes height with the native options viewport. It supplies no independent binding DB. The browser's source menu selects Live or a Respec profile; filters include All, Unbound, Bar/EBS key only, Default, Customized, and On bar/Stance/Extra; search and ABC/Key sort affect browsing. Group/flyout expansion, equipment/pet entries, keyboard visualization and the embedded editor are owned by [Binding](13-binding-system.md), with live-vs-profile commit semantics there.

The binding editor's additional registered widgets are implementation controls with explicit callbacks:

| Widget/source | Contract |
|---|---|
| [`FluxKeyCapture`](../Binding/UI/Editor/Widgets/FluxKeyCapture.lua) | Left-click begins key capture; key/mouse/wheel/gamepad input forms a chord and emits `OnKeyChanged(chord)`. Escape cancels capture. Right-click clears a manual key and emits an empty chord; inherited/locked keys cannot be cleared here. SetKey/Inherited/Locked/Disabled presentation is supplied by the editor. |
| [`FluxTargetRow`](../Binding/UI/Editor/Widgets/FluxTargetRow.lua) | Target row container with optional up/down arrow buttons; emits `OnMoveUp`/`OnMoveDown`. Caller owns actual target order/data. |
| [`FluxSectionHeading`](../Binding/UI/Editor/Widgets/FluxSectionHeading.lua) | Section master checkbox; `SetValue`/`SetDisabled` and label color control presentation, click emits `OnValueChanged(checked)`, hover emits OnEnter/OnLeave. |
| [`FluxBlizzardDropdown`](../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua) | AceGUI wrapper around supported native dropdown/menu paths. Caller supplies list/order/value/disabled state; selection emits `OnValueChanged(value)`. This differs from the Core helper's directly created dropdown frame. |
| [`FluxBindingFrame`](../Binding/UI/Editor/Widgets/FluxBindingFrame.lua) | Ace frame wrapper with minimum-size support and dialog layering. Escape hides out of combat; it is not an extra settings store. |
| [`FluxBindingTabGroup`](../Binding/UI/Editor/Widgets/FluxBindingTabGroup.lua) | Ace TabGroup wrapper that reapplies selected-state visuals when tabs are replaced. |
| [`FluxMultiCastOrderPanel`](../Binding/UI/Editor/Widgets/AceGUIWidget-FluxMultiCastOrderPanel.lua) | Drag ordered main/extra cast rows; right-click removes **extra** rows only. Drop spell/item actions when `SetCanAdd` permits it, with default cap twenty extras. `SetRows` clones without firing a change; edits emit `OnRowsChanged(clonedRows)` and successful drop also emits `OnCursorAccepted`. `SetCanEdit` is a compatibility alias for add permission, not a blanket reorder/remove lock. |

Multicast row order can move the main row, but removal preserves it. Unsupported cursor types do not become arbitrary macros. The editor decides how emitted rows alter a document/snapshot and when secure application occurs. Widget callbacks alone do not grant protected execution or write to an unrelated active profile.

## Key visualizer controls

[`KeyVisualizer/Core.lua`](../Binding/UI/KeyVisualizer/Core.lua) opens a resizable keyboard/mouse display with account/global `FluxOptions.db.global.keyVisualizer` preferences. **Loaded** defaults on, **Empty** off, **Extra** on and **Mouse** on. Keyboard layout/size default QWERTY/100 and are retained by the owner. The source selector All/Binding/Bars/Extra and Ctrl/Alt/Shift/Meta filters are current-open state; closing resets these transient filters. Physical modifier events synchronize the displayed filter state.

Selecting keyboard/layout size updates its tree; resizing fits the grid. Mouse display includes relevant mouse bindings rather than assuming every mouse button is used. [`FluxKeyVisualizerButton`](../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua) renders key geometry, action icon/count, up to the configured corner badges, highlight and tooltip events. It is a visualization cell, not a replacement key-capture control. [`FluxKeyVisualizerTreeGroup`](../Binding/UI/KeyVisualizer/AceGUIContainer-FluxKeyVisualizerTreeGroup.lua) exposes measured content width/height for fitting.

Visualizer runtime listeners for modifiers, binding/action/form changes and binding-apply notifications activate while open and are removed on close. The display combines documents, bar actions and extra-button routes; hover evidence is a source-derived explanation of bindings, not verification that a protected action will fire in the game.

## Completeness and verification

The [source inventory](30-source-coverage.md) lists every loaded widget file, and [API/events](33-api-and-events.md) indexes constructors/method registrations. This chapter covers registered AddonOptions widgets, their live backing editors/helpers, and the Binding/Micro Menu embeds. Native page rows and their literal defaults remain in chapter 26; [saved variables](32-saved-variables.md) identifies the actual persisted domains. Local inspection validates these control contracts; icon hit testing, drag across scroll boundaries, menu ownership, combat deferral and native taint require in-game interaction checks.
