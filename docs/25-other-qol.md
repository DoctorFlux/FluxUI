# Chat, trade, tooltips, vehicles, and other HUD helpers

The loaded `Other/` modules complete Flux's surrounding interface. They include persistent chat setup, copy/URL tools, chat-column controls, trade food/water, equipment flyouts, native-frame positioning, vehicle affordances and HUD tooltip placement. Character-panel code now lives under `CharacterInfo/`; the old `Other/FluxCharacterStats/` tree is an unloaded predecessor, not a second active stat backend.

## Chat setup and layout ownership

[`FluxChatFrame.lua`](../Other/FluxChatFrame.lua), `RunConfiguration`, uses `_FluxUI_CharSavedVars.fluxChatConfigured` as the per-character first-setup marker. First setup configures General/Global chat, tab order, channel membership/class colors and the primary frame's position, then marks the character configured. Subsequent logins still reconcile Global channels, ordering, position, Edit Mode hooks and social-column layout. The flag does not mean the module becomes inactive after the first login.

Primary chat dimensions and neighboring Micro Menu/Raid layout inform its anchoring. The module exports `FluxChatFrame_GetPrimaryChatHeight`, bottom/tab/column geometry queries, `ApplyPrimaryPosition`, drag-hold state and `RefreshSocialLayout` for neighboring systems. Delayed retries cover late channel/frame readiness. Edit Mode restoration and drift checks reassert Flux's composed chat placement. Existing General/Global frames remain Blizzard chat windows rather than a separate chat-history store.

Relevant signals include login/world entry, combat entry, channel changes and native chat/layout hooks. Position work checks current ownership and drag/restore state rather than blindly moving a user-dragged frame on every callback. Client-specific channel setup differs between older chat APIs and post-DF channel identifiers.

## Copy, URLs, and the chat column

[`FluxChatCopyPaste.xml`](../Other/FluxChatCopyPaste.xml) declares the unlimited-letter input-scroll template; [`FluxChatCopyPaste.lua`](../Other/FluxChatCopyPaste.lua) creates the copy window, strips chat markup where appropriate and supplies URL recognition/link interactions. `FluxCCP.openFluxCCPCopyFrame(window, url)` opens a selected chat frame's recent messages or a focused URL copy field. The default copy limit is 500 lines when no stored value is supplied. Secret messages are detected rather than treated as ordinary strings for copying/parsing.

The copy frame is draggable, dismissible with Close/Escape, and separate from the selected chat window. URL filters turn recognized text into clickable copy interactions; they do not launch arbitrary URLs through an operating-system browser. Fade, URL colors and related stored preferences are applied by the copy/paste module; not every stored setting has a current visible options row.

Settings live in **`FluxOptions.db.global.chatCopyPaste`**, so they are account/global settings, not ordinary active Ace-profile fields. [`FluxOptionsChat.lua`](../AddonOptions/FluxOptionsChat.lua) exposes **Chat** controls for the available column buttons:

| Control | Purpose |
|---|---|
| Social | Friends/quick-join native affordance. |
| Channels | Native channel button. |
| Guild | Guild opener with online-member count. |
| Character Info | Character micro-button appearance with durability percentage. |
| Bags | Bag opener/count/tooltip behavior matching the Flux bag micro button. |
| Copy Chat | Copy the selected chat window. |
| FluxUI Options | Left-click Flux options; right-click Blizzard settings. |
| Chat Menu | Native chat menu button. |

Each toggle is hidden when its corresponding client/frame control does not exist. Hiding the chat gear leaves `/fluxui` and other configured options entry points available. The old documentation claim that chat had no options tab is obsolete.

`FluxCCP:InstallColumnButtons`, `PlaceColumnButtons`, `AttachColumnToDock`, and `UpdateColumnButtons` own the column. Native social/channel/menu buttons and Flux-owned buttons share placement; guild roster updates refresh the guild count. Combat-deferred dock changes retry on `PLAYER_REGEN_ENABLED`.

[`FluxChatColumnMicros.lua`](../Other/FluxChatColumnMicros.lua) creates bag and character controls whose names deliberately do not end in `MicroButton`, preventing Micro Menu discovery from collecting them. Character opening uses a secure click to the native Character micro button on clients where a direct Lua `ToggleCharacter` would taint the native panel. It refreshes portrait/durability/status state from native events and applies late-binding/combat retry guards. The bag copy reuses shared bag behavior; it does not maintain a second bag-content index.

## Trade food and water

[`FluxTradeFoodWater.lua`](../Other/FluxTradeFoodWater.lua), `Module.CreateButtons`, adds **Trade Food** and **Trade Water** below the native TradeFrame. Left-click selects an eligible conjured stack, picks it up and puts it into the next free trade slot. The session tracks used bag/slot stacks so repeated clicks advance through supplies. Mana gems are excluded from the food/water search.

Right-click uses secure macro attributes for the known preferred conjure spell; a modifier can choose a secondary conjure spell where one exists. Spell selection comes from the shared inventory/create-spell service. Attribute updates defer during combat. `TRADE_SHOW`, `TRADE_UPDATE`, `TRADE_CLOSED`, bag-delayed updates and `SPELLS_CHANGED` keep the buttons and session state current. Adding items does not automatically accept the trade, promise a particular server delivery, or conjure through a timer.

## Equipment flyouts

[`FluxEquipSlotFlyout.lua`](../Other/FluxEquipSlotFlyout.lua) provides the ItemRack-style menu shared by paperdoll/binding equipment surfaces. `Flyout.Show(anchor, slotID, opts)`, `NotifyEnter`, `NotifyLeave`, `Hide`, delayed-show/hide methods and an on-equipped callback form its interface. Candidate discovery, slot eligibility, optional empty-slot choices and live equip/unequip actions come from [`FluxEquipSlotCandidates.lua`](../Inventory/FluxEquipSlotCandidates.lua).

Docking follows the available screen edge/anchor; hover timers keep the flyout open while traversing its buttons and hide it after leaving its interaction area. Current bank accessibility determines whether bank candidates can be equipped. A remembered bank item is not automatically an actionable live candidate. Candidate/frame caches are invalidated by inventory/equipment changes; they are separate from saved Respec snapshots and protection allocations. [Character Info](27-character-info.md) describes paperdoll-specific hooks and native flyout coexistence.

## Tooltips and native-frame anchors

| Module | Current positioning/ownership |
|---|---|
| [`FluxHUDTooltip.lua`](../Other/FluxHUDTooltip.lua) | Default world/UIParent tooltip placement above the Flux Window's top-left, with a 30-pixel vertical gap. `FluxApplyHUDTooltipPosition` and `FluxSetHUDTooltipOwner` expose the same placement to other chunks. It synchronizes the default container and real tooltip and opts the HUD tooltip out of Edit Mode where supported. |
| [`FluxExtraAbilityHUD.lua`](../Other/FluxExtraAbilityHUD.lua) | Post-DF extra ability container on a secure host above/left of the Flux Window. Marks it ignored by native layout, preserves native scripts/methods, and defers reparent/anchor work during combat/Edit Mode application. |
| [`FluxBossFramePosition.lua`](../Other/FluxBossFramePosition.lua) | Finds available native boss frames and repositions them in the Flux layout, retrying on encounter/world/login and combat-end events. Native unit-frame content stays Blizzard-owned. |
| [`FluxArenaFramePosition.lua`](../Other/FluxArenaFramePosition.lua) | Resolves client arena-frame variants and positions them relative to the HUD; late addon/frame creation and combat defer application. |
| [`FluxLootRollPosition.lua`](../Other/FluxLootRollPosition.lua) | Places GroupLootFrame/GroupLootContainer six pixels above the player outer border, hooks show once, waits briefly for the player frame and defers protected positioning until combat ends. |
| [`FluxTalkingHead.lua`](../Other/FluxTalkingHead.lua) | Mainline-only TOC load: scales TalkingHeadFrame to 0.75, parks it top-left under the Micro/Status stack when either uses top placement, and coalesces layout callbacks to avoid re-entering layout. |
| [`FluxDurationBars.lua`](../Other/FluxDurationBars.lua) | Leaves native mirror timers in default placement for side-by-side player/target placement 2; otherwise anchors the first at screen-top y=-200 and stacks later timers below it. |

These modules do not all share the Window Mover's arbitrary positioning store. Some deliberately enforce composed HUD anchors. The extra-ability host preserves Blizzard's native action button behavior; moving its container is distinct from taking over the action click implementation. Tooltip owner assignment uses `ANCHOR_NONE` before applying Flux placement and rejects forbidden tooltip ownership.

Current duration-bar source uses weak `hookedShows`/`hookedFrames` installation guards for MirrorTimer_Show wrappers and frame OnEvent hooks. The earlier paragraph claiming no guard was stale. No duration-bar runtime change is justified by that historical claim.

## Vehicle exit and seat indicators

[`FluxVehicleExitButton.lua`](../Other/FluxVehicleExitButton.lua) creates a 32-pixel native-styled exit button above the Flux player outer border. It responds to bonus/override/multicast, control, vehicle and world events, then performs a short delayed refresh to catch settling state. Its earlier permanent polling path is absent in the current implementation.

`OnClick` requests early landing on taxi when supported, disables/highlights the button to acknowledge the request, or calls `VehicleExit` for a vehicle. Taxi landing requests do not mean the character instantly dismounts. The tooltip changes between flight cancellation and vehicle exit. Anchor changes defer until combat ends when required. Flux action-bar vehicle paging is owned by [Action Bars](11-action-bars.md), not by this exit button.

[`FluxVehicleSeats.lua`](../Other/FluxVehicleSeats.lua) supplies `FluxVehicleSeatIndicator` beside `FluxDurabilityFrame`, with a screen fallback. Native-shaped seat buttons show passenger state and available seat interactions; event registration is capability-tolerant. It reads vehicle art/seat layout from native APIs and updates on vehicle/passenger lifecycle events. The stock VehicleSeatIndicator stays in native layout at alpha zero rather than being hidden or reparented. Position refreshes defer in combat; `FluxVehicleSeats_UpdateAnchor` is the cross-module anchor entry point.

## Integration and diagnostic ownership

ConsolePort suppression is documented in [Integrations](29-integrations.md): it is an automatic bridge under `ConsoleportCompat/`, not another `Other/` player feature. Character-panel item level, GearScore, stat pins and TacoTip suppression are in [Character Info](27-character-info.md). The modern loaded nameplate modules are under `NamePlates/`; old `Other` implementations must not be treated as additional runtime drivers.

`Other/FluxPerfDebug.lua` and `FluxPerfCapture.lua` provide diagnostic commands/capture rather than player HUD behavior. Their source-derived interfaces and evidence limits are in [Runtime](07-runtime-architecture.md), [commands](31-commands-and-bindings.md), and [verification](41-verification.md). The [source coverage index](30-source-coverage.md) distinguishes loaded helpers, historical copies and smoke harnesses.

Live verification remains necessary for chat channel/server behavior, secure CharacterFrame/ExtraAbility interactions, trade cursor operations, vehicle seats, Edit Mode and protected frame anchoring. This documentation describes observed source ownership and guards; it does not certify every client-specific native UI path.

## Loot waiter and diagnostic retention audit

BUG-009/PERF-007 reuses loot combat/readiness frames: 203 -> 3 allocations in the
100-world-entry/100-combat-cycle replay; hooks and placement remain. BUG-010/PERF-008
releases optional capture snapshots/handle references after finish/cancel. Focused
checks: 2,050 loot, 400 retention, 383 existing capture with 12 mutations. Native
Retail idle attribution and pending gameplay/resource tests are in the [audit](RETAIL_PERFORMANCE_AUDIT.md).
No layout, option, command or feature removed.

## Shared Social column position

BUG-011 uses one eight-unit tab-row inset on all client paths. Relative offset follows
late reload pins without a tab switch; the primary dock anchors all tabs including
Combat Log/custom windows, while Copy uses the selected tab. [Evidence](CHAT_COLUMN_ALIGNMENT.md):
2,009 column checks and native seven-selection Retail geometry pass; other native
clients/secure/pixel acceptance pending. Existing buttons/settings/ownership remain.
