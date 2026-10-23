# Command and SavedVariable declaration evidence

Generated companion to [commands](../31-commands-and-bindings.md) and [saved data](../32-saved-variables.md). Only reachable production files are included below. A registration site can still have runtime guards; execution and callback ordering must be traced in the implementation.

## Slash registrations in union load order

| Source | Kind | Command key / registration | Value |
|---|---|---|---|
| [Core/Engine/HopLag.lua:1079](../../Core/Engine/HopLag.lua#L1079) | alias | `SLASH_FLUXHOP1` | `/fluxhop` |
| [Core/Engine/HopLag.lua:1080](../../Core/Engine/HopLag.lua#L1080) | alias | `SLASH_FLUXHOP2` | `/fluxlag` |
| [Core/Engine/HopLag.lua:1081](../../Core/Engine/HopLag.lua#L1081) | handler | `FLUXHOP` | `` |
| [Core/Startup.lua:99](../../Core/Startup.lua#L99) | alias | `SLASH_FLUXSTARTUP1` | `/fluxstartup` |
| [Core/Startup.lua:100](../../Core/Startup.lua#L100) | handler | `FLUXSTARTUP` | `` |
| [Core/Slash.lua:245](../../Core/Slash.lua#L245) | alias | `SLASH_FLUXAPI1` | `/fluxapi` |
| [Core/Slash.lua:246](../../Core/Slash.lua#L246) | handler | `FLUXAPI` | `` |
| [Core/Slash.lua:250](../../Core/Slash.lua#L250) | alias | `SLASH_FLUXCLICK1` | `/fluxclick` |
| [Core/Slash.lua:251](../../Core/Slash.lua#L251) | handler | `FLUXCLICK` | `` |
| [Core/Slash.lua:255](../../Core/Slash.lua#L255) | alias | `SLASH_FLUXCAST1` | `/fluxcast` |
| [Core/Slash.lua:256](../../Core/Slash.lua#L256) | handler | `FLUXCAST` | `` |
| [Core/Slash.lua:279](../../Core/Slash.lua#L279) | alias | `SLASH_FLUXPERF1` | `/fluxperf` |
| [Core/Slash.lua:280](../../Core/Slash.lua#L280) | handler | `FLUXPERF` | `` |
| [WindowMover/Init.lua:51](../../WindowMover/Init.lua#L51) | alias | `SLASH_FLUXWINDOWS1` | `/fluxwindows` |
| [WindowMover/Init.lua:52](../../WindowMover/Init.lua#L52) | handler | `FLUXWINDOWS` | `` |
| [Inventory/Init.lua:1529](../../Inventory/Init.lua#L1529) | alias | `SLASH_FLUXINV1` | `/fluxinv` |
| [Inventory/Init.lua:1530](../../Inventory/Init.lua#L1530) | handler | `FLUXINV` | `` |
| [ExtraButtonSystem/Init.lua:268](../../ExtraButtonSystem/Init.lua#L268) | alias | `SLASH_FLUXEBS1` | `/fluxebs` |
| [ExtraButtonSystem/Init.lua:269](../../ExtraButtonSystem/Init.lua#L269) | handler | `FLUXEBS` | `` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:337](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L337) | alias | `SLASH_FLUXTRINKETMENU1` | `/fluxtrinket` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:338](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L338) | alias | `SLASH_FLUXTRINKETMENU2` | `/ftm` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:339](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L339) | handler | `FLUXTRINKETMENU` | `` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:805](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L805) | alias | `SLASH_FLUXHEARTH1` | `/fluxhearth` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:806](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L806) | alias | `SLASH_FLUXHEARTH2` | `/fhc` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:808](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L808) | handler | `FLUXHEARTH` | `` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:4516](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4516) | alias | `SLASH_FLUXMOUNTDEBUG1` | `/fluxmount` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:4517](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4517) | handler | `FLUXMOUNTDEBUG` | `` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:3212](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L3212) | alias | `SLASH_FLUXTELEPORT1` | `/fluxtp` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:3213](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L3213) | alias | `SLASH_FLUXTELEPORT2` | `/fluxtp` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:3214](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L3214) | handler | `FLUXTELEPORT` | `` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6572](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6572) | alias | `SLASH_FLUXCONSUMABLES1` | `/fluxconsumables` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6573](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6573) | handler | `FLUXCONSUMABLES` | `` |
| [Bars/Init.lua:486](../../Bars/Init.lua#L486) | alias | `SLASH_FLUXBARS1` | `/fluxbars` |
| [Bars/Init.lua:487](../../Bars/Init.lua#L487) | handler | `FLUXBARS` | `` |
| [Other/FluxPerfDebug.lua:804](../../Other/FluxPerfDebug.lua#L804) | alias | `SLASH_FLUXPERF1` | `/fluxperf` |
| [Other/FluxPerfDebug.lua:805](../../Other/FluxPerfDebug.lua#L805) | handler | `FLUXPERF` | `` |
| [Other/FluxInputDebug.lua:137](../../Other/FluxInputDebug.lua#L137) | alias | `SLASH_FLUXINPUT1` | `/fluxinput` |
| [Other/FluxInputDebug.lua:138](../../Other/FluxInputDebug.lua#L138) | handler | `FLUXINPUT` | `` |
| [FluxDefaultSettings.lua:2774](../../FluxDefaultSettings.lua#L2774) | alias | `SLASH_FLUXDEFAULTS1` | `/fluxdefaults` |
| [FluxDefaultSettings.lua:2775](../../FluxDefaultSettings.lua#L2775) | handler | `FLUXDEFAULTS` | `` |
| [Binding/Slash.lua:4](../../Binding/Slash.lua#L4) | alias | `SLASH_FLUXBIND1` | `/fluxbind` |
| [Binding/Slash.lua:6](../../Binding/Slash.lua#L6) | handler | `FLUXBIND` | `` |
| [AddonOptions/FluxOptions.lua:1798](../../AddonOptions/FluxOptions.lua#L1798) | alias | `SLASH_FLUXUI_OPTIONS1` | `/fluxui` |
| [AddonOptions/FluxOptions.lua:1799](../../AddonOptions/FluxOptions.lua#L1799) | alias | `SLASH_FLUXUI_OPTIONS2` | `/fluxoptions` |
| [AddonOptions/FluxOptions.lua:1800](../../AddonOptions/FluxOptions.lua#L1800) | handler | `FLUXUI_OPTIONS` | `` |
| [UnitFrames/FluxFlightPath.lua:543](../../UnitFrames/FluxFlightPath.lua#L543) | alias | `SLASH_FLUXFLIGHTPATH1` | `/fluxfp` |
| [UnitFrames/FluxFlightPath.lua:544](../../UnitFrames/FluxFlightPath.lua#L544) | handler | `FLUXFLIGHTPATH` | `` |
| [MicroMenu/FluxMicroMenu.lua:3130](../../MicroMenu/FluxMicroMenu.lua#L3130) | alias | `SLASH_FLUXMICRO1` | `/fluxmicro` |
| [MicroMenu/FluxMicroMenu.lua:3131](../../MicroMenu/FluxMicroMenu.lua#L3131) | handler | `FLUXMICRO` | `` |
| [StatusBars/FluxStatusBar.lua:3052](../../StatusBars/FluxStatusBar.lua#L3052) | alias | `SLASH_FLUXSTATUS1` | `/fluxstatus` |
| [StatusBars/FluxStatusBar.lua:3053](../../StatusBars/FluxStatusBar.lua#L3053) | handler | `FLUXSTATUS` | `` |
| [StatusBars/FluxPVPObjectiveMover.lua:374](../../StatusBars/FluxPVPObjectiveMover.lua#L374) | alias | `SLASH_FLUXPVP1` | `/fluxpvp` |
| [StatusBars/FluxPVPObjectiveMover.lua:375](../../StatusBars/FluxPVPObjectiveMover.lua#L375) | handler | `FLUXPVP` | `` |
| [Battlezonemap/FluxWindowFrame.lua:1254](../../Battlezonemap/FluxWindowFrame.lua#L1254) | alias | `SLASH_FLUXWINDOW1` | `/fluxwindow` |
| [Battlezonemap/FluxWindowFrame.lua:1255](../../Battlezonemap/FluxWindowFrame.lua#L1255) | alias | `SLASH_FLUXWINDOW2` | `/fw` |
| [Battlezonemap/FluxWindowFrame.lua:1256](../../Battlezonemap/FluxWindowFrame.lua#L1256) | handler | `FLUXWINDOW` | `` |
| [Battlezonemap/FluxBlizzardMeter.lua:1556](../../Battlezonemap/FluxBlizzardMeter.lua#L1556) | alias | `SLASH_FLUXBLIZZMETER1` | `/fluxblizzmeter` |
| [Battlezonemap/FluxBlizzardMeter.lua:1557](../../Battlezonemap/FluxBlizzardMeter.lua#L1557) | alias | `SLASH_FLUXBLIZZMETER2` | `/fbm` |
| [Battlezonemap/FluxBlizzardMeter.lua:1558](../../Battlezonemap/FluxBlizzardMeter.lua#L1558) | handler | `FLUXBLIZZMETER` | `` |
| [Battlezonemap/FluxBattlefieldMap.lua:1410](../../Battlezonemap/FluxBattlefieldMap.lua#L1410) | alias | `SLASH_FLUXBATTLEFIELDMAP1` | `/fluxmap` |
| [Battlezonemap/FluxBattlefieldMap.lua:1411](../../Battlezonemap/FluxBattlefieldMap.lua#L1411) | handler | `FLUXBATTLEFIELDMAP` | `` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:1261](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1261) | alias | `SLASH_FLUXWORLDMAP1` | `/fluxwm` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:1262](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1262) | handler | `FLUXWORLDMAP` | `` |
| [Respec/FluxRespec_Core.lua:755](../../Respec/FluxRespec_Core.lua#L755) | alias | `SLASH_FLUXRESPEC1` | `/fluxrespec` |
| [Respec/FluxRespec_Core.lua:756](../../Respec/FluxRespec_Core.lua#L756) | alias | `SLASH_FLUXRESPEC2` | `/respec` |
| [Respec/FluxRespec_Core.lua:757](../../Respec/FluxRespec_Core.lua#L757) | handler | `FLUXRESPEC` | `` |
| [Salvage/FluxSalvage.lua:78](../../Salvage/FluxSalvage.lua#L78) | alias | `SLASH_FLUXSALVAGE1` | `/fsalvage` |
| [Salvage/FluxSalvage.lua:79](../../Salvage/FluxSalvage.lua#L79) | alias | `SLASH_FLUXSALVAGE2` | `/fluxsalvage` |
| [Salvage/FluxSalvage.lua:80](../../Salvage/FluxSalvage.lua#L80) | handler | `FLUXSALVAGE` | `` |
| [Inventory/Restock/Bank/FluxBankRestockDebug.lua:523](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L523) | alias | `SLASH_FLUXBANKRESTOCKDEBUG1` | `/fluxbankdebug` |
| [Inventory/Restock/Bank/FluxBankRestockDebug.lua:524](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L524) | alias | `SLASH_FLUXBANKRESTOCKDEBUG2` | `/fbrdebug` |
| [Inventory/Restock/Bank/FluxBankRestockDebug.lua:525](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L525) | handler | `FLUXBANKRESTOCKDEBUG` | `` |
| [Inventory/Restock/Vendor/FluxAlreadyKnown.lua:740](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L740) | alias | `SLASH_ALREADYKNOWN1` | `/alreadyknown` |
| [Inventory/Restock/Vendor/FluxAlreadyKnown.lua:741](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L741) | alias | `SLASH_ALREADYKNOWN2` | `/ak` |
| [Inventory/Restock/Vendor/FluxAlreadyKnown.lua:794](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L794) | handler | `ALREADYKNOWN` | `` |
| [Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua:768](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L768) | alias | `SLASH_ALREADYKNOWN1` | `/alreadyknown` |
| [Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua:769](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L769) | alias | `SLASH_ALREADYKNOWN2` | `/ak` |
| [Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua:822](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L822) | handler | `ALREADYKNOWN` | `` |
| [Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua:132](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L132) | alias | `SLASH_BUYEMALL1` | `/buyemall` |
| [Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua:133](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L133) | handler | `BUYEMALL` | `` |

## SavedVariable reference sites

References include exact identifier and string-key tokens. Counts do not prove writes or active ownership. Core/DB table initialization and retained migration references must be distinguished from actual feature consumers.

| SavedVariable | Declared scope | Active reference files | Inactive reference files |
|---|---|---|---|
| `FluxUI_DB` | account | [AddonOptions/FluxOptionsNameplates.lua:22](../../AddonOptions/FluxOptionsNameplates.lua#L22)<br>[Bars/SpellRank.lua:754](../../Bars/SpellRank.lua#L754)<br>[CharacterInfo/Shared.lua:42](../../CharacterInfo/Shared.lua#L42)<br>[Core/API/Name.lua:455](../../Core/API/Name.lua#L455)<br>[Core/API/Threat.lua:255](../../Core/API/Threat.lua#L255)<br>[Core/DB.lua:9](../../Core/DB.lua#L9)<br>[Core/Startup.lua:16](../../Core/Startup.lua#L16)<br>[ExtraButtonSystem/ExtraButtons/Core.lua:58](../../ExtraButtonSystem/ExtraButtons/Core.lua#L58)<br>[FluxDefaultSettings.lua:2055](../../FluxDefaultSettings.lua#L2055)<br>[MicroMenu/FluxMicroMenuConfig.lua:24](../../MicroMenu/FluxMicroMenuConfig.lua#L24)<br>[MicroMenu/FluxMinimapToMicro.lua:44](../../MicroMenu/FluxMinimapToMicro.lua#L44)<br>[MicroMenu/FluxTradeSkillMicro.lua:65](../../MicroMenu/FluxTradeSkillMicro.lua#L65)<br>[NamePlates/Core.lua:97](../../NamePlates/Core.lua#L97)<br>[UnitFrames/FluxFlightPath.lua:24](../../UnitFrames/FluxFlightPath.lua#L24) | [Other/FluxCharacterStats/FluxCharacterStatsShared.lua:48](../../Other/FluxCharacterStats/FluxCharacterStatsShared.lua#L48)<br>[tests/binding_respec_regression.lua:54](../../tests/binding_respec_regression.lua#L54)<br>[tests/startup_lifecycle.lua:12](../../tests/startup_lifecycle.lua#L12) |
| `FluxUI_Options` | account | [AddonOptions/FluxOptions.lua:1628](../../AddonOptions/FluxOptions.lua#L1628)<br>[Core/API/Name.lua:463](../../Core/API/Name.lua#L463)<br>[Core/DB.lua:10](../../Core/DB.lua#L10) | — |
| `FluxNonCombatGridDB` | account | [Core/API/Name.lua:502](../../Core/API/Name.lua#L502)<br>[Core/DB.lua:11](../../Core/DB.lua#L11)<br>[ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua:30](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L30)<br>[ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:995](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L995)<br>[ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:747](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L747)<br>[ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:62](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L62)<br>[ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:127](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L127) | — |
| `FluxFlyoutFavorites_Data` | account | [Core/API/Name.lua:497](../../Core/API/Name.lua#L497)<br>[Core/DB.lua:12](../../Core/DB.lua#L12)<br>[ExtraButtonSystem/FlyoutEngine/Favorites.lua:13](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L13) | [ExtraButtonSystem/Flyout/FluxFlyoutFavorites.lua:25](../../ExtraButtonSystem/Flyout/FluxFlyoutFavorites.lua#L25) |
| `FluxUIGoldLedger` | account | [Core/API/Name.lua:476](../../Core/API/Name.lua#L476)<br>[Core/DB.lua:13](../../Core/DB.lua#L13)<br>[Inventory/Store.lua:568](../../Inventory/Store.lua#L568)<br>[StatusBars/FluxGoldLedger.lua:353](../../StatusBars/FluxGoldLedger.lua#L353) | — |
| `FluxSalvageDB` | account | [Core/DB.lua:14](../../Core/DB.lua#L14)<br>[Salvage/FluxSalvage_Settings.lua:10](../../Salvage/FluxSalvage_Settings.lua#L10) | — |
| `FluxInvDB` | account | [Core/API/Name.lua:492](../../Core/API/Name.lua#L492)<br>[Core/DB.lua:15](../../Core/DB.lua#L15)<br>[Inventory/Professions.lua:160](../../Inventory/Professions.lua#L160) | [Inventory/FluxInv/FluxInv.lua:11](../../Inventory/FluxInv/FluxInv.lua#L11)<br>[Inventory/FluxInv/FluxInv_Professions.lua:19](../../Inventory/FluxInv/FluxInv_Professions.lua#L19) |
| `FluxUIInventoryDB` | account | [Core/API/Name.lua:484](../../Core/API/Name.lua#L484)<br>[Core/DB.lua:16](../../Core/DB.lua#L16)<br>[Inventory/Store.lua:43](../../Inventory/Store.lua#L43) | — |
| `FluxPerfCaptureDB` | account | [Other/FluxInputDebug.lua:70](../../Other/FluxInputDebug.lua#L70)<br>[Other/FluxPerfCapture.lua:114](../../Other/FluxPerfCapture.lua#L114) | [tests/input_diagnostics.lua:28](../../tests/input_diagnostics.lua#L28)<br>[tests/perf_capture.lua:142](../../tests/perf_capture.lua#L142) |
| `_FluxUI_CharSavedVars` | character | [AddonOptions/FluxOptionsInfo.lua:7](../../AddonOptions/FluxOptionsInfo.lua#L7)<br>[AddonOptions/FluxOptionsStatusBars.lua:11](../../AddonOptions/FluxOptionsStatusBars.lua#L11)<br>[AddonOptions/FluxOptionsVendor.lua:45](../../AddonOptions/FluxOptionsVendor.lua#L45)<br>[BaganatorCompat/FluxBaganator_GearSets.lua:98](../../BaganatorCompat/FluxBaganator_GearSets.lua#L98)<br>[Bars/SpellRank.lua:69](../../Bars/SpellRank.lua#L69)<br>[Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:323](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L323)<br>[Battlezonemap/FluxBlizzardMeter.lua:1533](../../Battlezonemap/FluxBlizzardMeter.lua#L1533)<br>[Battlezonemap/FluxMeterLayout.lua:512](../../Battlezonemap/FluxMeterLayout.lua#L512)<br>[Battlezonemap/FluxWindowFrame.lua:131](../../Battlezonemap/FluxWindowFrame.lua#L131)<br>[CharacterInfo/RetailPane.lua:498](../../CharacterInfo/RetailPane.lua#L498)<br>[CharacterInfo/Shared.lua:45](../../CharacterInfo/Shared.lua#L45)<br>[Core/DB.lua:20](../../Core/DB.lua#L20)<br>[Core/Engine/MouseoverCast.lua:128](../../Core/Engine/MouseoverCast.lua#L128)<br>[ExtraButtonSystem/ExtraButtons/Categories.lua:587](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L587)<br>[ExtraButtonSystem/ExtraButtons/Core.lua:93](../../ExtraButtonSystem/ExtraButtons/Core.lua#L93)<br>[ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:346](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L346)<br>[ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua:15](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L15)<br>[ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:73](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L73)<br>[ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:138](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L138)<br>[Inventory/FluxConsumableBest/Persist.lua:13](../../Inventory/FluxConsumableBest/Persist.lua#L13)<br>[Inventory/Init.lua:52](../../Inventory/Init.lua#L52)<br>[Inventory/Restock/Bank/FluxBankRestockButton.lua:38](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L38)<br>[Inventory/Restock/Core/FluxRestockList.lua:1199](../../Inventory/Restock/Core/FluxRestockList.lua#L1199)<br>[Inventory/Restock/Core/FluxRestockSettings.lua:119](../../Inventory/Restock/Core/FluxRestockSettings.lua#L119)<br>[Inventory/Restock/FluxRestock_Inv.lua:1095](../../Inventory/Restock/FluxRestock_Inv.lua#L1095)<br>[Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua:41](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L41)<br>[Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua:14](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L14)<br>[MicroMenu/FluxMicroMenuConfig.lua:41](../../MicroMenu/FluxMicroMenuConfig.lua#L41)<br>[MicroMenu/FluxMinimapToMicro.lua:55](../../MicroMenu/FluxMinimapToMicro.lua#L55)<br>[MicroMenu/FluxTradeSkillMicro.lua:43](../../MicroMenu/FluxTradeSkillMicro.lua#L43)<br>[Minimap/FluxMinimapButtons.lua:28](../../Minimap/FluxMinimapButtons.lua#L28)<br>[Other/FluxChatFrame.lua:886](../../Other/FluxChatFrame.lua#L886)<br>[Respec/FluxRespec_Core.lua:29](../../Respec/FluxRespec_Core.lua#L29)<br>[Respec/FluxRespec_EquipmentPresets.lua:16](../../Respec/FluxRespec_EquipmentPresets.lua#L16)<br>[Respec/FluxRespec_GearSetIndex.lua:80](../../Respec/FluxRespec_GearSetIndex.lua#L80)<br>[Respec/FluxRespec_Includes.lua:175](../../Respec/FluxRespec_Includes.lua#L175)<br>[Respec/FluxRespec_RunePresets.lua:113](../../Respec/FluxRespec_RunePresets.lua#L113)<br>[StatusBars/FluxInfoFrame.lua:103](../../StatusBars/FluxInfoFrame.lua#L103)<br>[StatusBars/FluxPVPTracking.lua:15](../../StatusBars/FluxPVPTracking.lua#L15)<br>[UnitFrames/FluxFlightPath.lua:33](../../UnitFrames/FluxFlightPath.lua#L33) | [ExtraButtonSystem/NonCombat/Food.lua:14](../../ExtraButtonSystem/NonCombat/Food.lua#L14)<br>[ExtraButtonSystem/NonCombat/Roles.lua:13](../../ExtraButtonSystem/NonCombat/Roles.lua#L13)<br>[ExtraButtonSystem/Shared/FluxMouseoverRefresh.lua:147](../../ExtraButtonSystem/Shared/FluxMouseoverRefresh.lua#L147)<br>[Inventory/FluxInv/FluxInv_Bank.lua:89](../../Inventory/FluxInv/FluxInv_Bank.lua#L89)<br>[Other/FluxCharacterStats/FluxCharacterStatsShared.lua:51](../../Other/FluxCharacterStats/FluxCharacterStatsShared.lua#L51)<br>[tests/data_integrity.lua:38](../../tests/data_integrity.lua#L38)<br>[tests/idle_hud.lua:102](../../tests/idle_hud.lua#L102)<br>[tests/window_runtime_spec.lua:19](../../tests/window_runtime_spec.lua#L19) |
| `FluxSpellBookSlotsDB` | character | [Core/DB.lua:21](../../Core/DB.lua#L21) | — |
| `FluxNCUtilitySlotsDB` | character | [Bars/SpellRank.lua:783](../../Bars/SpellRank.lua#L783)<br>[Core/DB.lua:22](../../Core/DB.lua#L22)<br>[ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua:39](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L39) | — |
| `FluxSpellBindingProfilesDB` | character | [Core/DB.lua:23](../../Core/DB.lua#L23) | [tests/startup_lifecycle.lua:239](../../tests/startup_lifecycle.lua#L239) |
| `FluxSpellDirectBindDB` | character | [Core/DB.lua:24](../../Core/DB.lua#L24) | — |
| `FluxSpellProfileBindingsDB` | character | [Core/DB.lua:25](../../Core/DB.lua#L25) | — |
| `FluxBindingProfilesPerStateDB` | character | [Core/DB.lua:26](../../Core/DB.lua#L26) | — |
| `FluxBindingDBv2` | character | [Core/DB.lua:27](../../Core/DB.lua#L27) | — |
| `FluxBindingDB3` | character | [Binding/Boot.lua:13](../../Binding/Boot.lua#L13)<br>[Binding/Core/Action.lua:297](../../Binding/Core/Action.lua#L297)<br>[Binding/Core/Apply.lua:14](../../Binding/Core/Apply.lua#L14)<br>[Binding/Core/BindingTooltip.lua:133](../../Binding/Core/BindingTooltip.lua#L133)<br>[Binding/Core/Conditions.lua:388](../../Binding/Core/Conditions.lua#L388)<br>[Binding/Core/DB.lua:35](../../Binding/Core/DB.lua#L35)<br>[Binding/Core/Engraving.lua:217](../../Binding/Core/Engraving.lua#L217)<br>[Binding/Core/Placement.lua:1962](../../Binding/Core/Placement.lua#L1962)<br>[Binding/Core/SpellLibrary.lua:8](../../Binding/Core/SpellLibrary.lua#L8)<br>[Binding/Respec.lua:13](../../Binding/Respec.lua#L13)<br>[Binding/UI/Browser/Core.lua:9](../../Binding/UI/Browser/Core.lua#L9)<br>[Binding/UI/Editor/Chrome.lua:14](../../Binding/UI/Editor/Chrome.lua#L14)<br>[Binding/UI/Editor/Core.lua:16](../../Binding/UI/Editor/Core.lua#L16)<br>[Binding/UI/Editor/Panels.lua:15](../../Binding/UI/Editor/Panels.lua#L15)<br>[Binding/UI/Editor/Widgets/AceGUIWidget-FluxMultiCastOrderPanel.lua:34](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxMultiCastOrderPanel.lua#L34)<br>[Binding/UI/KeyVisualizer/Core.lua:92](../../Binding/UI/KeyVisualizer/Core.lua#L92)<br>[Core/DB.lua:28](../../Core/DB.lua#L28) | [tests/binding_respec_regression.lua:201](../../tests/binding_respec_regression.lua#L201) |
| `FluxTradeSkillScannerDB` | character | [Core/DB.lua:29](../../Core/DB.lua#L29) | — |
| `TrinketMenuOptions` | character | [Core/DB.lua:30](../../Core/DB.lua#L30) | — |
| `TrinketMenuPerOptions` | character | [Core/DB.lua:31](../../Core/DB.lua#L31) | — |
| `TrinketMenuQueue` | character | [Core/DB.lua:32](../../Core/DB.lua#L32) | — |
| `FluxNCFlyoutCharDB` | character | [Core/DB.lua:33](../../Core/DB.lua#L33)<br>[ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua:90](../../ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua#L90) | — |
