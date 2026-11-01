# FluxUI

A complete World of Warcraft interface built around a compact HUD: layered action bars, configurable unit frames, smart utility buttons, inventory tools, and one dock for maps, meters, and gameplay profiles.

The addon installs as **`_FluxUI`**. Open **`/fluxui`** for settings.

## Features at a glance

Features adapt to your client, class, learned abilities, and installed companion addons. The links below explain the available controls and any restrictions.

| Feature | What it does |
| --- | --- |
| [HUD layout and styling](docs/06-layout.md) | Interactive placement preview; alternate player/target, stance, micro-menu, status and Info positions; horizontal squeeze, class/custom accent colors, shared borders and chrome. |
| [Settings and profiles](docs/26-options-map.md) | Searchable configuration, account or character scopes for supported modules, profile creation/copy/reset, visibility controls, and embedded ordering/editing tools. |
| [First-time setup](docs/05-defaults-and-bindings.md) | Recommended game settings and a Flux keybinding template, with separate settings/keybinding reset commands. Review this page before first use because setup can change game preferences and keys. |
| [Action bars](docs/11-action-bars.md) | One 19-column strip with main, Shift and Ctrl layers; empty-slot promotion, modifier previews, form/stealth/vehicle/possession/override paging, hover-to-bind mode, mouseover casting, a spell blacklist, and supported spell rank-up tools. |
| [Button feedback](docs/11-action-bars.md) | Counts, charges, cooldowns, range/usability tint, proc highlights, cast/click effects, native spell flyouts, and Blizzard-assisted highlights where available. |
| [Pet and stance bars](docs/11-action-bars.md) | A 5×2 pet bar and hybrid stance bar combining forms, spell extras and custom slots; reorder/hide controls and alternate placement. An attached stance bar follows [player-frame scale](docs/UNIT_FRAME_SCALE.md). |
| [Conditional bindings](docs/13-binding-system.md) | Searchable action browser, key capture, keyboard visualizer, shared-key previews, form subprofiles, ordered target/mouseover rules, load conditions, cast flags, macro prefixes and multi-action setups within WoW's secure-action rules. |
| [Combat consumables](docs/12-extra-button-system.md) | Bandages, healing/mana potions, mana gems, healthstones and supported ammunition; best-owned-tier selection, counts/charges, use/conjure actions, creation shortcuts and configurable combat/noncombat button swapping. |
| [Food and buff presets](docs/12-extra-button-system.md) | Food/water selection and conjuring; ordered consumable presets with buff-refresh thresholds, weapon enchants, restock quantities and supported Classic Chronoboon/world-buff handling. |
| [Mounts and hearthstones](docs/12-extra-button-system.md) | Smart ground/flying mounts, favorites, utility/vendor mounts, supported bag-mount selection, hearth items/toys, random/selected hearth toys and account/character choices. |
| [Teleports and portals](docs/12-extra-button-system.md) | Known class destinations, teleport/portal switching, modifier favorites, destination flyouts, applicable reagent counts and restock targets. |
| [Utility buttons and palettes](docs/12-extra-button-system.md) | Four modifier-aware utility slots; draggable supported spells, items, macros, mounts, pets, toys and outfits; custom collapsible button categories with account/class/realm/character scope. |
| [Flyouts and trinkets](docs/12-extra-button-system.md) | Modifier favorites and per-character travel ordering/hiding; equipped-trinket buttons, bag trinket flyouts, cooldown feedback and queued swaps. Supported outfit flyouts include a clear-transmog action. |
| [Unit frames](docs/14-unit-frames.md) | Player, target, target-of-target, focus, focus-target, pet and pet-target; per-unit Flux/Blizzard ownership, portraits, health/resource text, auras, heal prediction, absorbs, class resources, threat, swing and flight timers, plus [whole-frame scaling](docs/UNIT_FRAME_SCALE.md). |
| [Cast-bar school themes](docs/14-unit-frames.md) | Shared spell-school artwork and appearance controls for supported unit-frame and [Blizzard nameplate casts](docs/NAMEPLATE_CASTBAR_SCHOOLS.md); restricted or unidentified casts retain the appropriate default presentation. |
| [Party and raid frames](docs/15-raid-frames.md) | Compact secure group frames, main-tank layouts, class colors, health/power/status text, range opacity, ready-check/role/raid markers, aura/dispel controls, supported private auras and a 5–40-player preview. |
| [Flux Window and maps](docs/10-flux-window.md) | Configurable Map/Minimap, Meter, Respec and Buttons tabs; battlefield-map navigation, supported quest/world-map pins and tooltips, and minimap embedding. |
| [Meters](docs/10-flux-window.md) | Embedded Details panes and Flux threat display, or the available Blizzard damage-meter backend; pane layout, sizing, tab and display controls. A supported meter backend is required. |
| [Respec gameplay profiles](docs/23-respec.md) | Save selected combinations of talents/loadouts, supported runes, gear, action/stance layouts, consumable presets, utility slots, bindings and Info preferences; include masks, equipment-set integration, gear protection and progress-aware application. |
| [Status bars and gold ledger](docs/16-status-bars.md) | XP/rested/available quest progress, watched reputation, gold, supported PvP points and currencies; account-character gold summaries and configurable tracked-item counters. |
| [Info display](docs/16-status-bars.md) | FPS, latency, durability and pinned character statistics; configurable order, placement and status-bar integration. |
| [Micro Menu](docs/17-micromenu.md) | Reorderable native navigation plus bags, professions, macros, configuration, reload, queues and addon shortcuts; visibility scopes, promoted minimap-addon buttons and multiple layouts. |
| [Minimap and objectives](docs/18-minimap-and-trackers.md) | Square minimap, zoom/tracking/calendar/clock controls, queue/mail indicators, optional 3×5 button strip, objective-tracker scrolling, Questie tracker handoff and player buff/debuff positioning. |
| [Nameplate additions](docs/19-nameplates.md) | Supported threat borders/rank/percent, enemy-player targeting warnings, levels, target combo resources, aura countdowns and cast-school styling around Blizzard nameplates. |
| [Chat](docs/25-other-qol.md) | Chat layout/tab/channel setup, copy-chat window, clickable URL copying, and toggles for social, channel, guild, character, bags, copy, settings and chat-menu buttons. The character shortcut also shows equipped durability. |
| [Inventory and bags](docs/21-inventory-foundation.md) | Shared item counts and cached character/location summaries, inventory tooltips, equipment/consumable facts, and built-in combined bags on Era/Anniversary; external Syndicator can provide the inventory data instead. |
| [Vendor tools](docs/20-vendor-restock-junk.md) | Auto-repair, junk classification/selling, manual junk/protection rules, inferior-tier handling, known-item tinting, bulk buying with confirmation, and coin-formatted visit summaries. |
| [Restocking and bank tools](docs/20-vendor-restock-junk.md) | Item/reagent/consumable target quantities, tier-aware merchant purchases, preset-linked supplies, bank withdrawal planning and live restock controls, with saved-gear protection. |
| [Baganator extensions](docs/24-baganator-compat.md) | Flux junk, equipment-set and consumable categories; item markers/protection, context actions and bank-restock controls when the companion's APIs are ready. |
| [Salvage](docs/22-salvage.md) | Modifier-hover, click-to-process overlay for supported disenchanting, milling, prospecting/crushing, scrapping, opening/lockpicking/keys and Forever scroll comprehension, with skill and protected-gear checks. |
| [Character and equipment helpers](docs/27-character-info.md) | Expanded supported character statistics, item-level/GearScore displays, quality chrome, stat pinning, alternate-equipment flyouts, available helmet/cloak controls and supported secondary-name display. |
| [Loot alerts and fast pickup](docs/LOOT_CURSOR.md) | Cursor-positioned item, currency and coin alerts; quality/category filters, expiry/preview controls and optional fast pickup that yields to the separate FasterLoot addon. |
| [Trade and vehicle helpers](docs/25-other-qol.md) | Food/water trade buttons, equipment flyouts, tooltip and extra-ability positioning, vehicle exit/seats, durability indicators and native HUD anchors. |
| [Movable game windows](docs/28-window-mover.md) | Move/scale supported Blizzard windows, remember position/scale, clamp/snap, modifier/lock controls and resets; separate from Flux HUD placement. |
| [Optional diagnostics](docs/31-commands-and-bindings.md) | Startup timing, bounded performance captures, lag tracing, input snapshots and subsystem reports for troubleshooting. |

For every option, default, command and integration, see the [feature inventory](docs/FEATURE_INVENTORY.md), [options reference](docs/26-options-map.md), [custom controls](docs/35-custom-widget-controls.md), and [command reference](docs/31-commands-and-bindings.md).

## Clients and companion addons

The current code targets **Retail (Midnight), Forever/Camelot, Classic Era, Anniversary/TBC and Mists Classic**. Availability differs by client; a shared feature list is not a claim that every feature works identically on all five. See the [client matrix](docs/02-multi-client-matrix.md) and [recorded validation](docs/CLIENT_VALIDATION.md) for implemented paths and pending in-game checks.

Optional integrations include **Syndicator, Baganator, Details, Questie, BigDebuffs, TacoTip, ConsolePort, SpellActivationOverlay, Clicked and Clique/ClickCastFrames**. Flux also coordinates ownership with **FasterLoot**, **AlreadyKnown**, and alternative bag addons such as **Bagnon/Bagnonium**. Each has its own scope and readiness requirements; see the [integration reference](docs/29-integrations.md). Companion addons are installed separately.

## Install and configure

1. Download the repository using **Code → Download ZIP**, or use your existing checkout.
2. Place the folder containing `_FluxUI.toc` at `World of Warcraft/<your client>/Interface/AddOns/_FluxUI/`. Avoid an extra nested repository folder.
3. Enable `_FluxUI` in the character-select addon list, then log in or reload.
4. Open `/fluxui`, review the setup defaults, and choose your layout and feature settings.

Useful entry points: `/fluxbind` for binding tools, `/fluxconsumables` for consumable presets, `/fluxhearth config` for the supported hearth-toy editor, and `/fluxui raidpreview` for the group-frame preview. Respec gameplay profiles live in the Flux Window's **Respec** tab.

## Documentation and feedback

Start with the [documentation index](docs/00-README.md). [Current status](docs/STATUS.md) separates implemented work from pending native testing; [contributing rules](CONTRIBUTING.md) explain development and validation. Bundled components and reference sources retain their notices; see [dependencies and provenance](docs/90-reference-inspirations.md).

For a bug report, include your client version/build, what you were doing, the relevant settings and any Lua error or screenshot in a [GitHub issue](https://github.com/DoctorFlux/FluxUI/issues). Performance and compatibility claims apply only to the scenarios actually recorded in the validation documents.
