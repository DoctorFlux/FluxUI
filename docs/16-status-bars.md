# Status bars, gold, currencies and Info Frame

Flux's status system has six loaded components: XP/reputation/gold-strip composition, account gold ledger, item-currency tracking, Info Frame, legacy PvP tracking and PvP objective placement. They share layout/chrome but own different data. [FluxStatusBar.lua](../StatusBars/FluxStatusBar.lua) creates the bar container and reconciles active cells.

## Strip composition and updates

XP displays progress/rested/predicted quest progress where supported; reputation reads the watched faction through modern/legacy adapters, including available friendship/standing presentation. The gold/currency strip displays money and supported tracked currencies/items. XP can hide at max level; the currency bar is separately toggleable. Defaults clamp bar height to 10–40px, initially 18px. HUD atlas art vs Classic vertex colors is selected by capabilities.

`UpdateLayout` selects placement-specific composition, separators, row/column widths and integrated Info Frame cells. `UpdateExpBar`, reputation/gold update functions and composition signatures avoid full geometry changes on every number update. Gold/item layout has dedicated hit regions so money, currency and tracked-item tooltips/clicks can coexist. Currency/reputation/XP clicks forward to the relevant game panels or contextual interaction rather than a new Flux progression database.

Events include player XP/level/rested changes, faction, money/currency, quest log, durability and combat exit. Inventory listeners refresh tracked counts; composition changes notify unified layout, PvP anchors and the Flux Window through a coalesced path. Stock status presentation is suppressed while Flux provides these strips. ConsolePort suppression is a separate integration; see [integrations](29-integrations.md).

The equipment durability frame and vehicle seats form a horizontal pair below whichever visible micro menu or status strip extends lower in the top-left corner. When that corner is clear, the pair starts at the screen top-left, except that a top-left PvP objective widget keeps its existing clearance. The strip's own position remains unchanged.

## Account gold ledger

[FluxGoldLedger.lua](../StatusBars/FluxGoldLedger.lua) stores `FluxUIGoldLedger` and identifies characters using normalized name/realm keys. It saves current money, consolidates duplicate entries, scopes/sorts account rows and caches summed contexts. The gold hover presents known characters and totals with realm/faction policy; bag money widgets can share the tooltip.

This is last-observed money, not a live query of logged-out characters. `GetConfigLedgerIndex` and `DeleteLedgerEntryByKey` support explicit cleanup in options. Inventory's store/ledger provides related ownership facts and may import money stubs, but gold-tooltip settings and character deletion remain separately identifiable. See [inventory](21-inventory-foundation.md).

## Item currencies and older PvP points

[FluxItemCurrencyTracking.lua](../StatusBars/FluxItemCurrencyTracking.lua) reads `FluxOptions:GetItemCurrencyDB()` **always per character**, regardless of broader status scope. Slots hold item IDs; adding an item makes it tracked on the bar. The list maintains one trailing empty add slot and caps total rows at 40. Dragging an item onto the gold strip or options slot resolves cursor identity; clearing removes it. Icon data loads asynchronously and listeners refresh when item information arrives. Counts consume inventory facts; an uncached icon is not an absent stack.

`AcceptItemDropOnCurrencyBar`, `ClearItemCurrencySlot`, `MaintainItemCurrencySlotList`, `NotifyItemCurrencyChanged` and `LayoutGoldItemHovers` are the integration points. Rebuilding the bar updates individual item hit regions and available money text width.

[FluxPVPTracking.lua](../StatusBars/FluxPVPTracking.lua) adds honor/arena tracking controls on older/no-currency-tab paths. Its booleans live at `_FluxUI_CharSavedVars.PVPTracking`; compatible modern-currency, legacy-function and UI-text fallbacks obtain values. [FluxPVPObjectiveMover.lua](../StatusBars/FluxPVPObjectiveMover.lua) positions Blizzard capture/objective widgets in the HUD and responds to `UPDATE_UI_WIDGET`; it does not compute battleground objectives itself.

## Info Frame providers and persistence

[FluxInfoFrame.lua](../StatusBars/FluxInfoFrame.lua) owns `FluxInfoFrame`, an extensible stat registry plus FPS, latency and durability lines. `_FluxUI_CharSavedVars.infoFrame` stores line toggles, `pinnedStats`, `statOrder` and `spellDisplayMode` (`off|sp|heal|both`). Current defaults enable FPS/ping and disable the separate durability line; an explicit one-time default marker resets older durability defaults.

Registry entries supply label/order/getter/format and, for some stats, formatted display text. Providers cover primary stats, armor/defense, attack/spell/healing, hit/crit/haste, mastery/secondary stats where available, weapon speed, movement/health and equipped ilvl/GearScore. Availability differs by client. Dynamic character-panel rows can provide display/tooltip associations; supported providers and guarded snapshots avoid unsafe reads. A missing/secret value must not become a fabricated zero or an old plausible reading.

`GetStatRegistry`, `TogglePinnedStat`, `IsStatPinned`, `GetOrderedVisibleStats` and `SetStatOrder` expose the model. Character panel hooks install separately for Classic custom-stat rows, modern PaperDoll pools and Forever ScrollBox elements. [Character Info](27-character-info.md) explains the pin flow and client differences.

### Forever shared combat statistics

`_CamelotCombatStatKey` folds melee/ranged/spell aliases into three shared keys: `crit` (**Crit**), `haste` (**Haste**) and `meleeHit` (**Hit**). `_FoldCamelotCombatPins` merges existing saved pins and deduplicates their order while preserving the first canonical position. Toggling any alias toggles that shared pin, and Respec imports are normalized again. Other clients retain their separate supported hit/crit identities; an explicit canonical `Flux.Client.isCamelot=false` takes precedence over stale compatibility flags.

`_CamelotCombatStatValue` follows native shared-stat calculations while values are readable: maximum melee/ranged/spell crit; maximum melee/spell/ranged haste with ranged ammo haste included and `GetHaste` as a final fallback; maximum supported mainhand/offhand/ranged/spell rating-plus-modifier hit. During restrictions, live values pass directly to `FontString:SetFormattedText`, while Lua measures and merges separate plain layout samples. A visible native player row supplies its current combined total. Otherwise Forever's shared crit/haste channel is displayed directly; hit shows the live rating and modifier contributions because addon Lua cannot add secret numbers. Hidden native rows and previous snapshots are not treated as current values. Zero remains valid, and `RememberPinnedStatValue` rejects and clears secret numeric/text cache entries.

`_CamelotLiveCombatText` keeps the native-renderer arguments separate from its ordinary `999.99%` layout samples. `_RenderCamelotLiveText` substitutes each current formatted value into the final FontString, including lines that merge several stats with ordinary text. `_RefreshCamelotLiveText` also runs on `UpdateStats`' unchanged-text/unchanged-geometry return path: a stable sample does not freeze the displayed combat number. Switching between the native combined hit total and its two-contribution fallback invalidates the relevant width caches when the sample shape changes.

## Info layout and refresh

The same model can render as a vertical HUD, an integrated status/action-strip region, minimap-area strip or other configured placement. `GetEffectivePlacement`, `PrepareIntegratedStripLayout`, `PositionActionStripSlotFrame` and `ForceUpdatePosition` coordinate this with neighboring systems. Long stat text merges/wraps/scrolls rather than truncating arbitrary names. Stable worst-case widths prevent changing FPS or stat numbers from continually resizing the HUD. Re-entry/signature guards prevent layout callbacks repeatedly triggering each other.

One-second stat refresh is started/stopped with visible-frame demand; player-stat events request coalesced provider refreshes. Forever also listens for combat entry/exit and player `UNIT_SPELL_HASTE`. Placement watchers are distinct from stat refresh. `ForceRebuild` reconstructs lines after settings changes; count/value updates need not do that. On Forever, a combat rebuild request sets `_rebuildAfterCombat` and replays after `PLAYER_REGEN_ENABLED`; saved pin intent can change before its structural rendering catches up. Row binding/indicator refresh similarly waits outside combat.

`AfterCharacterShown(fn)` callbacks use an independent Forever watcher. Opening the character panel in combat, or keeping it open through combat, schedules one refresh when combat ends. Closing the panel first cancels that pending post-open refresh. This keeps row installation and consumer geometry out of the native character-show path; [WindowMover](28-window-mover.md) also consumes the callback.

`SerializeRespecProfileSnapshot` captures line toggles, pins, spell mode and order as plain data. `ApplyRespecProfileSnapshot` restores them, validates spell mode, rebuilds and refreshes pin indicators. Selecting a Respec profile alone does not apply the snapshot; loading its included Info Frame section does.

## Controls and checks

Status Bar/Info settings and Layout placement have separate scope getters; Info pins and item-currency slots remain per character. Inventory-tooltip realm/faction/equipped/guild policy and gold-entry deletion appear alongside these options but affect inventory/ledger consumers. [Options](26-options-map.md) distinguishes the controls. `/fluxstatus refresh` forces bar/layout refresh and `testdurability` exercises alert placement; its advertised `debug` branch is currently a no-op. [Commands](31-commands-and-bindings.md) records the parser.

Verify rested/max-level transitions, faction/currency changes, item drag/clear and async icon completion, scoped gold totals, deleted character recovery, Info pin order across reload/Respec, unavailable providers, long text, all placements and ConsolePort coexistence. The updated [Forever stat smoke](../CharacterInfo/_tmp_foreverstatssmoke.lua) passed on Lua 5.4.6 on 2026-10-22 after the latest concurrent Info Frame change. It exercises shared values/alias migration, restricted-value rejection, live formatted/merged text, refresh with unchanged layout samples, visible/hidden native-total selection, row clicks/indicators/tooltips, Respec import and combat/post-open recovery against real addon functions with mocked WoW APIs. Its secret tokens and native text renderer are simulated; actual secret-value/taint behavior and tooltip forwarding still require in-game checks. [Verification](41-verification.md) identifies the tested source contents.
