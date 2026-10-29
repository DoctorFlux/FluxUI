# Commands and keybindings

`/fluxinput` captures a read-only input/taint snapshot immediately and once after three seconds. Hover the affected frame, then reload to flush `FluxPerfCaptureDB.inputDebug`. It never changes click bindings or native input. [Behavior and evidence](51-input-and-native-callbacks.md), [handler](../Other/FluxInputDebug.lua).

`/fluxstartup on` enables the opt-in capture for the next reload; `/fluxstartup` prints separate visual/input milestones, startup layout/defer/managed-timer counters and heap delta; `/fluxstartup off` disables capture. [Metrics and limitations](43-startup-optimization.md#startup-diagnostics).

This reference follows reachable source and actual handlers, including assignments that replace earlier registrations. [Declaration evidence](reference/declarations.md) lists every source registration; [source coverage](30-source-coverage.md) retains client filters. A registered command can still require a feature/API that is unavailable on the current client.

## Player and configuration commands

| Command / aliases | Arguments and actual effect | Source |
|---|---|---|
| `/fluxui`, `/fluxoptions` | Empty/other input toggles the options shell. `bliz` / `blizzard` opens the Flux options shell through `ShowConfig`; `raidpreview` toggles raid preview. | [options registration](../AddonOptions/FluxOptions.lua#L1798) |
| `/fluxbind` | Empty: open a pending binding editor, with options-page fallback. Positive spell ID: open that action. `viz` / `visualizer` / `keyboard`: keyboard view. `apply`: request recompile/apply. `debug`: diagnostics. Only the visualizer aliases use the lowercased copy; other comparisons retain the input's case. | [handler](../Binding/Slash.lua) |
| `/fluxwindow`, `/fw` | `show`, `hide`, `toggle`; `tab <name>` switches outside combat; `addtab <name>` creates a placeholder tab; `removetab <name>` removes it. **Empty/unrecognized input does nothing** in the current handler. | [handler](../Battlezonemap/FluxWindowFrame.lua#L1195) |
| `/fluxrespec`, `/respec` | `list`, `save <name>`, `load <name>`, `delete <name>`. Profile names can contain spaces. Empty input prints usage; it does not open the Respec UI. Load can coordinate protected/asynchronous actions. | [handler](../Respec/FluxRespec_Core.lua#L755), [pipeline](23-respec.md) |
| `/fluxsalvage`, `/fsalvage` | `toggle`, `on`, `off`: change overlay enablement/hooks. `status`: show enabled/modifier/hooks and Comprehend status. Otherwise open the salvage settings, with legacy Blizzard-category fallback. | [handler](../Salvage/FluxSalvage.lua#L78) |
| `/fluxconsumables` | Toggle the consumables grid configuration; arguments are ignored. | [handler](../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6567) |
| `/fluxhearth`, `/fhc` | Empty/`help`: usage. `config`: Toy Box; `show`: Toy Box plus delayed hearth panel display; `toggle`: account/character mode; `default`: basic Hearthstone; `item`: current item ID. | [handler](../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L805) |
| `/fluxtrinket`, `/ftm` | Empty/`toggle`, `show`, `hide`, `reset` position. Show/toggle checks whether there are trinkets to display. | [handler](../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua) |
| `/fluxtp` | `set <itemID> <target>` changes reagent restock quantity and refreshes displays; `refresh` refreshes displays. `targets` and unrecognized input currently produce no output. Both declared aliases are the identical `/fluxtp`. | [handler](../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L3197) |
| `/buyemall` | Empty: help. `confirm`: toggle large-purchase confirmation. The command is registered during the bulk-buy module initialization. | [handler](../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L132) |
| `/alreadyknown`, `/ak` | Color presets `green`, `blue`, `yellow`, `cyan`, `purple`, `gray`; `custom` opens the color picker; `monochrome` toggles desaturation. Additional `debug`, `itemtest`, `future` diagnostics and Live `exclude` handlers are defined in the respective handler table. Missing/unknown input prints the public color help. | [Live handlers](../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L740), [Classic handlers](../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L768) |
| `/fluxwindows` | Empty: status. `lock`, `unlock`, `reset`, `scan`, `smoke`, `help`. Changes Blizzard-window mover state; HUD placement is separate. | [handler](../WindowMover/Init.lua#L50) |
| `/fluxmicro` | `gap`, `debug`: inspect layout. `resetorder` / `reset order`: order only. `resetall` / `reset all`: factory visibility plus order. Other input re-hijacks/refreshes buttons and prints usage. | [handler](../MicroMenu/FluxMicroMenu.lua#L3068) |
| `/fluxdefaults` | `apply` / `force`: full defaults; `keybinds`: binding pack; `cvars`: CVar pack; `reset`: clear account setup flag; `resetchar`: clear current character's seen flag. Empty/unknown: debug and usage. Resetting flags is different from applying immediately. | [handler](../FluxDefaultSettings.lua#L2782), [effects](05-defaults-and-bindings.md) |
| `/fluxfp` | `save <sourceNodeID> <destinationNodeID> <seconds>`, `clear <source> <destination>`, `list`, `measure`, `help`. Persists faction-specific route overrides; measure prints elapsed time from the recorded flight start and is an estimate. | [flight helper](../UnitFrames/FluxFlightPath.lua#L465) |

## Diagnostic and developer commands

| Command / aliases | Arguments and behavior | Source |
|---|---|---|
| `/fluxapi` | Client/capability/secrets/optional-addon, module and inventory/extra-engine summary. | [Core commands](../Core/Slash.lua#L245) |
| `/fluxclick` | Secure click attributes and recorded click trace. | [Core commands](../Core/Slash.lua#L250) |
| `/fluxcast` | Cast VFX dispatcher/owner/entry and last-spell state. | [Core commands](../Core/Slash.lua#L255) |
| `/fluxbars` | Empty: strip/host diagnostics. `<column>`: main/secondary/tertiary details. `page` / `paging`: paging chain, including separate `securePaging` and general snippet capability decisions. `mo` / `mouseover`: mouseover dump. `smoke`: slot-math self-test. | [handler](../Bars/Init.lua#L456) |
| `/fluxebs` | Extra-button enablement/counts/range, inventory source and cast VFX summary. | [handler](../ExtraButtonSystem/Init.lua#L266) |
| `/fluxinv` | Empty: inventory source/snapshot diagnostics. `count <itemID>`: snapshot versus live count and locations. `listeners`: listener keys, tiers and region/defer/sync options. | [handler](../Inventory/Init.lua#L1521) |
| `/fluxmount` | Mount detection diagnostics; `update` additionally forces a mount-button update. | [handler](../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4516) |
| `/fluxperf` | Empty/`report` (or unrecognized input): report. `capture [seconds]`, `last`, `cancel`: measured capture. `burst` / `form`: last burst. `reset`, `probe`, `combat`, `regen`, `spells`, `help`: corresponding diagnostic paths. Probe temporarily hides UI and is different from capture. | [effective handler](../Other/FluxPerfDebug.lua#L804), [capture](../Other/FluxPerfCapture.lua) |
| `/fluxhop`, `/fluxlag` | Empty: toggle tracing. `on` / `start`, `off` / `stop`, `overlay`, `report` / `dump`, `reset`, `watch`, `thresh <ms>` / `threshold <ms>`, `cpu`, `help`. Hiding the overlay need not stop tracing. CPU starts a five-second sample and resets CPU counters. | [dispatcher](../Core/Engine/HopLag.lua#L982) |
| `/fluxbankdebug`, `/fbrdebug` | `on` / `1` / `true`, `off` / `0` / `false`, `toggle`, `dump`, `cats`, `quiet` / `normal` / `verbose`, `cat` / `category <name> on\|off`, `help`. | [handler](../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L523) |
| `/fluxmap` | `testload`, `scale <x> [y]`, `show`, `hide`, `refresh`, `cleanup`. Empty input does nothing. | [handler](../Battlezonemap/FluxBattlefieldMap.lua#L1379) |
| `/fluxwm` | `on` / `1` / `true`, `off` / `0` / `false`, `toggle`: world-map feature mirroring. Otherwise status. | [handler](../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1262) |
| `/fluxblizzmeter`, `/fbm` | `available`, `api`, `embed`, `hide`, `show`, `cleanup`. Requires usable native meter APIs for the corresponding operation. | [handler](../Battlezonemap/FluxBlizzardMeter.lua#L1516) |
| `/fluxpvp` | `debug`, `reposition`; otherwise usage for objective/capture-bar positioning. | [handler](../StatusBars/FluxPVPObjectiveMover.lua#L374) |
| `/fluxstatus` | `refresh`: bars/layout refresh. `testdurability`: position/show test. `debug` is currently a no-op despite help text advertising it. | [handler](../StatusBars/FluxStatusBar.lua#L3041) |

## Effective registration and retired commands

`Core/Slash.lua` first registers `/fluxperf`, including a `watch` subcommand. The later-loaded `Other/FluxPerfDebug.lua` replaces the same `SlashCmdList.FLUXPERF` entry. The effective handler supports burst/capture/report paths, but **does not implement Core's watch branch**. Use `/fluxhop watch` for its separate tracing facility. This is a load-order conclusion from the [TOC](../_FluxUI.toc) and both implementations.

AlreadyKnown uses separate TOC-filtered Live and Classic files. Camelot is absent from both filters, so these aliases are not promised there. Other runtime early returns can similarly suppress a registration; see [clients](02-multi-client-matrix.md).

The former `/flyout` registration is in the unloaded old flyout implementation. It is not part of the current active command set. Command-like text in an old document or a print string does not establish a registration.

## Blizzard keybinding entries

[Bindings.xml](../Bindings.xml) declares the entries in the following generated table. Most bodies are intentionally no-ops: Lua installs override-click routes onto live widgets. `FLUXRELOADUI` calls `ReloadUI()` directly. Therefore a binding name's existence does not prove its widget exists or is currently usable.

<!-- binding-table -->

| Binding entry | XML body / routing |
|---|---|
| `FLUXRELOADUI` | ReloadUI() |
| `FLUXGRIDSMARTMOUNT` | -- No-op: actual click is bound via SetOverrideBindingClick to the mount button widget |
| `FLUXGRIDHEARTH` | -- No-op: actual click is bound via SetOverrideBindingClick to the hearthstone button widget |
| `FLUXGRIDVENDORMOUNT` | -- No-op: actual toggle is bound via SetOverrideBinding in Mount.lua |
| `FLUXGRID_FOOD_OR_RECUP` | -- No-op: actual click is bound via SetOverrideBindingClick to the food button widget |
| `FLUXGRID_WATER_OR_COMBINED` | -- No-op: actual click is bound via SetOverrideBindingClick to the water/combined button widget |
| `FLUXCOMBAT_HEALPOT` | -- No-op: actual click is bound via SetOverrideBindingClick |
| `FLUXCOMBAT_BANDAGE` | -- No-op: actual click is bound via SetOverrideBindingClick |
| `FLUXCOMBAT_HEALTHSTONE` | -- No-op: actual click is bound via SetOverrideBindingClick |
| `FLUXCOMBAT_MANAPOT` | -- No-op: actual click is bound via SetOverrideBindingClick |
| `FLUXCOMBAT_MANAGEM` | -- No-op: actual click is bound via SetOverrideBindingClick |
| `FLUX_ASSISTED_COMBAT` | -- No-op: Extra Button single-button assistant. SetOverrideBindingClick in ExtraButtonSystem/Engine/Action.lua onto the live EBS widget. |
| `FLUXCLASS_TELEPORT` | -- No-op: actual click is bound via SetOverrideBindingClick to the teleport button widget |
| `FLUXMAGE_TOGGLE_TPPT` | -- No-op: actual toggle is bound via SetOverrideBinding in TeleportPortal.lua |
| `FLUXMAGE_CONJURE_FOOD` | -- No-op: actual click is bound via SetOverrideBindingClick to food button RightButton |
| `FLUXMAGE_CONJURE_WATER` | -- No-op: actual click is bound via SetOverrideBindingClick to water button RightButton |
| `FLUXMAGE_RITUAL_OF_REFRESHMENT` | -- No-op: actual click is bound via SetOverrideBindingClick to hidden Ritual button |
| `FLUXMAGE_CONJURE_MANAGEM` | -- No-op: actual click is bound via SetOverrideBindingClick |
| `FLUXGRID_CONSUMABLES` | -- No-op: actual click is bound via SetOverrideBindingClick to the consumables button widget |
| `FLUXSPELLBOOKSLOT1` | -- Utility slot 1 |
| `FLUXSPELLBOOKSLOT2` | -- Utility slot 2 |
| `FLUXSPELLBOOKSLOT3` | -- Utility slot 3 |
| `FLUXSPELLBOOKSLOT4` | -- Utility slot 4 |
| `FLUXTRINKET1` | -- No-op: actual click is bound via SetOverrideBindingClick to top trinket (slot 13) |
| `FLUXTRINKET2` | -- No-op: actual click is bound via SetOverrideBindingClick to bottom trinket (slot 14) |

Default chords and automatic pack application are listed in [defaults](05-defaults-and-bindings.md). Binding-mode routes, free-key overrides, hovercast and row-specific conflicts are explained in [bars](11-action-bars.md), [binding](13-binding-system.md) and [extra buttons](12-extra-button-system.md). The game's normal binding sets and Flux-authored binding documents are separate stores.
