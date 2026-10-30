# Source interface and event index

Generated discovery index for [API/event contracts](../33-api-and-events.md). Function declarations are syntactic candidates: table-local methods are included, and assigned aliases/dynamically generated functions may not appear. This is not a promise that every name is globally accessible. Stable contracts and callback payloads are documented in the architecture/system chapters.

## Event and subscription sites

Literal and dynamic event expressions are preserved. Shared-bus subscription methods can subscribe to non-WoW notifications; method names alone do not establish event semantics.

| Source | Method | Arguments |
|---|---|---|
| [AddonOptions/AceGUIWidget-FluxSpellBookSlotsPanel.lua:410](../../AddonOptions/AceGUIWidget-FluxSpellBookSlotsPanel.lua#L410) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [AddonOptions/FluxOptions.lua:1596](../../AddonOptions/FluxOptions.lua#L1596) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptions.lua:1642](../../AddonOptions/FluxOptions.lua#L1642) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [AddonOptions/FluxOptionsActionBars.lua:67](../../AddonOptions/FluxOptionsActionBars.lua#L67) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsBattlezone.lua:131](../../AddonOptions/FluxOptionsBattlezone.lua#L131) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsBinding.lua:27](../../AddonOptions/FluxOptionsBinding.lua#L27) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsChat.lua:141](../../AddonOptions/FluxOptionsChat.lua#L141) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsGeneral.lua:104](../../AddonOptions/FluxOptionsGeneral.lua#L104) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsInfo.lua:173](../../AddonOptions/FluxOptionsInfo.lua#L173) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsLayout.lua:76](../../AddonOptions/FluxOptionsLayout.lua#L76) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsMicroMenu.lua:306](../../AddonOptions/FluxOptionsMicroMenu.lua#L306) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsNameplates.lua:272](../../AddonOptions/FluxOptionsNameplates.lua#L272) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsShell.lua:766](../../AddonOptions/FluxOptionsShell.lua#L766) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [AddonOptions/FluxOptionsStatusBars.lua:536](../../AddonOptions/FluxOptionsStatusBars.lua#L536) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsUnitFrames.lua:2101](../../AddonOptions/FluxOptionsUnitFrames.lua#L2101) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsWindows.lua:274](../../AddonOptions/FluxOptionsWindows.lua#L274) | `RegisterEvent` | `"ADDON_LOADED"` |
| [BaganatorCompat/FluxBaganator_BankRestock.lua:246](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L246) | `RegisterEvent` | `"BANKFRAME_OPENED"` |
| [BaganatorCompat/FluxBaganator_BankRestock.lua:247](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L247) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [BaganatorCompat/FluxBaganator_BankRestock.lua:249](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L249) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
| [BaganatorCompat/FluxBaganator_GearSets.lua:552](../../BaganatorCompat/FluxBaganator_GearSets.lua#L552) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [BaganatorCompat/FluxBaganator_GearSetShield.lua:218](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L218) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [BaganatorCompat/FluxBaganator_Protection.lua:327](../../BaganatorCompat/FluxBaganator_Protection.lua#L327) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [BaganatorCompat/FluxBaganator_Protection.lua:328](../../BaganatorCompat/FluxBaganator_Protection.lua#L328) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [BaganatorCompat/FluxBaganator_Protection.lua:329](../../BaganatorCompat/FluxBaganator_Protection.lua#L329) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [BaganatorCompat/Loader.lua:91](../../BaganatorCompat/Loader.lua#L91) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [BaganatorCompat/Loader.lua:125](../../BaganatorCompat/Loader.lua#L125) | `RegisterEvent` | `"ADDON_LOADED"` |
| [BaganatorCompat/Loader.lua:126](../../BaganatorCompat/Loader.lua#L126) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Bars/Blizzard.lua:712](../../Bars/Blizzard.lua#L712) | `RegisterEvent` | `STOCK_STANCE_LEFTOVER_EVENTS[i]` |
| [Bars/Blizzard.lua:714](../../Bars/Blizzard.lua#L714) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Bars/ProgramFace.lua:1546](../../Bars/ProgramFace.lua#L1546) | `Subscribe` | `ProgramFace.OnContext` |
| [Battlezonemap/FluxBattlefieldMap.lua:193](../../Battlezonemap/FluxBattlefieldMap.lua#L193) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxBattlefieldMap.lua:194](../../Battlezonemap/FluxBattlefieldMap.lua#L194) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Battlezonemap/FluxBattlefieldMap.lua:195](../../Battlezonemap/FluxBattlefieldMap.lua#L195) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxBattlefieldMap.lua:592](../../Battlezonemap/FluxBattlefieldMap.lua#L592) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxBattlefieldMap.lua:593](../../Battlezonemap/FluxBattlefieldMap.lua#L593) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [Battlezonemap/FluxBattlefieldMap.lua:594](../../Battlezonemap/FluxBattlefieldMap.lua#L594) | `RegisterEvent` | `"NEW_WMO_CHUNK"` |
| [Battlezonemap/FluxBattlefieldMap.lua:902](../../Battlezonemap/FluxBattlefieldMap.lua#L902) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [Battlezonemap/FluxBattlefieldMap.lua:903](../../Battlezonemap/FluxBattlefieldMap.lua#L903) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxBattlefieldMap.lua:904](../../Battlezonemap/FluxBattlefieldMap.lua#L904) | `RegisterEvent` | `"ZONE_CHANGED"` |
| [Battlezonemap/FluxBattlefieldMap.lua:905](../../Battlezonemap/FluxBattlefieldMap.lua#L905) | `RegisterEvent` | `"ZONE_CHANGED_INDOORS"` |
| [Battlezonemap/FluxBattlefieldMap.lua:906](../../Battlezonemap/FluxBattlefieldMap.lua#L906) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Battlezonemap/FluxBattlefieldMap.lua:907](../../Battlezonemap/FluxBattlefieldMap.lua#L907) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:853](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L853) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:854](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L854) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:855](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L855) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:856](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L856) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:890](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L890) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:891](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L891) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:1205](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1205) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:1206](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1206) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:1207](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1207) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1450](../../Battlezonemap/FluxBlizzardMeter.lua#L1450) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1451](../../Battlezonemap/FluxBlizzardMeter.lua#L1451) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1452](../../Battlezonemap/FluxBlizzardMeter.lua#L1452) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1521](../../Battlezonemap/FluxBlizzardMeter.lua#L1521) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1522](../../Battlezonemap/FluxBlizzardMeter.lua#L1522) | `RegisterEvent` | `"VARIABLES_LOADED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1523](../../Battlezonemap/FluxBlizzardMeter.lua#L1523) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxDetails.lua:242](../../Battlezonemap/FluxDetails.lua#L242) | `RegisterEvent` | `"DETAILS_INSTANCE_OPEN", lightRefreshIfEmbedded` |
| [Battlezonemap/FluxDetails.lua:243](../../Battlezonemap/FluxDetails.lua#L243) | `RegisterEvent` | `"DETAILS_PROFILE_APPLYED", function() -- Profiles reset instances_amount (default 5); Flux needs up to 6 panes. EnsureDetailsMaxWindows() lightRefreshIfEmbedded() end` |
| [Battlezonemap/FluxDetails.lua:1811](../../Battlezonemap/FluxDetails.lua#L1811) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxDetails.lua:1812](../../Battlezonemap/FluxDetails.lua#L1812) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxDetailsForever.lua:195](../../Battlezonemap/FluxDetailsForever.lua#L195) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Battlezonemap/FluxDetailsForever.lua:196](../../Battlezonemap/FluxDetailsForever.lua#L196) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxDetailsWoWSkinTint.lua:138](../../Battlezonemap/FluxDetailsWoWSkinTint.lua#L138) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxMeterLayout.lua:2398](../../Battlezonemap/FluxMeterLayout.lua#L2398) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Battlezonemap/FluxThreat.lua:41](../../Battlezonemap/FluxThreat.lua#L41) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxThreat.lua:208](../../Battlezonemap/FluxThreat.lua#L208) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [Battlezonemap/FluxThreat.lua:209](../../Battlezonemap/FluxThreat.lua#L209) | `RegisterUnitEvent` | `"UNIT_TARGET", "target"` |
| [Battlezonemap/FluxThreat.lua:210](../../Battlezonemap/FluxThreat.lua#L210) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Battlezonemap/FluxThreat.lua:211](../../Battlezonemap/FluxThreat.lua#L211) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxThreat.lua:909](../../Battlezonemap/FluxThreat.lua#L909) | `RegisterEvent` | `"UNIT_THREAT_LIST_UPDATE"` |
| [Battlezonemap/FluxThreat.lua:910](../../Battlezonemap/FluxThreat.lua#L910) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [Battlezonemap/FluxThreat.lua:979](../../Battlezonemap/FluxThreat.lua#L979) | `RegisterEvent` | `Threat, "COMBAT_PLAYER_ENTER"` |
| [Battlezonemap/FluxThreat.lua:980](../../Battlezonemap/FluxThreat.lua#L980) | `RegisterEvent` | `Threat, "COMBAT_PLAYER_LEAVE"` |
| [Battlezonemap/FluxThreat.lua:981](../../Battlezonemap/FluxThreat.lua#L981) | `RegisterEvent` | `Threat, "DETAILS_INSTANCE_ENDRESIZE"` |
| [Battlezonemap/FluxThreat.lua:982](../../Battlezonemap/FluxThreat.lua#L982) | `RegisterEvent` | `Threat, "DETAILS_INSTANCE_SIZECHANGED"` |
| [Battlezonemap/FluxThreat.lua:983](../../Battlezonemap/FluxThreat.lua#L983) | `RegisterEvent` | `Threat, "DETAILS_INSTANCE_STARTSTRETCH"` |
| [Battlezonemap/FluxThreat.lua:984](../../Battlezonemap/FluxThreat.lua#L984) | `RegisterEvent` | `Threat, "DETAILS_INSTANCE_ENDSTRETCH"` |
| [Battlezonemap/FluxThreat.lua:985](../../Battlezonemap/FluxThreat.lua#L985) | `RegisterEvent` | `Threat, "DETAILS_OPTIONS_MODIFIED"` |
| [Battlezonemap/FluxThreat.lua:987](../../Battlezonemap/FluxThreat.lua#L987) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [Battlezonemap/FluxThreat.lua:988](../../Battlezonemap/FluxThreat.lua#L988) | `RegisterUnitEvent` | `"UNIT_TARGET", "target"` |
| [Battlezonemap/FluxThreat.lua:989](../../Battlezonemap/FluxThreat.lua#L989) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Battlezonemap/FluxThreat.lua:990](../../Battlezonemap/FluxThreat.lua#L990) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxWindowFrame.lua:1651](../../Battlezonemap/FluxWindowFrame.lua#L1651) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxWindowFrame.lua:1652](../../Battlezonemap/FluxWindowFrame.lua#L1652) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Battlezonemap/FluxWindowFrame.lua:1653](../../Battlezonemap/FluxWindowFrame.lua#L1653) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxWindowFrame.lua:1654](../../Battlezonemap/FluxWindowFrame.lua#L1654) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Boot.lua:40](../../Binding/Boot.lua#L40) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Boot.lua:41](../../Binding/Boot.lua#L41) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Boot.lua:51](../../Binding/Boot.lua#L51) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Binding/Core/Apply.lua:2405](../../Binding/Core/Apply.lua#L2405) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Binding/Core/Apply.lua:2406](../../Binding/Core/Apply.lua#L2406) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Binding/Core/Apply.lua:2423](../../Binding/Core/Apply.lua#L2423) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Core/Apply.lua:2433](../../Binding/Core/Apply.lua#L2433) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/Apply.lua:2473](../../Binding/Core/Apply.lua#L2473) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [Binding/Core/ChordMap.lua:213](../../Binding/Core/ChordMap.lua#L213) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/Core/ChordMap.lua:214](../../Binding/Core/ChordMap.lua#L214) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/Conditions.lua:607](../../Binding/Core/Conditions.lua#L607) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [Binding/Core/Conditions.lua:608](../../Binding/Core/Conditions.lua#L608) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Binding/Core/Conditions.lua:622](../../Binding/Core/Conditions.lua#L622) | `RegisterEvent` | `"UNIT_PET"` |
| [Binding/Core/Engraving.lua:270](../../Binding/Core/Engraving.lua#L270) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Binding/Core/Engraving.lua:272](../../Binding/Core/Engraving.lua#L272) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [Binding/Core/Forms.lua:258](../../Binding/Core/Forms.lua#L258) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORMS"` |
| [Binding/Core/Forms.lua:259](../../Binding/Core/Forms.lua#L259) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/Placement.lua:2459](../../Binding/Core/Placement.lua#L2459) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/Core/Placement.lua:2460](../../Binding/Core/Placement.lua#L2460) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/PushPress.lua:388](../../Binding/Core/PushPress.lua#L388) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Binding/Core/PushPress.lua:739](../../Binding/Core/PushPress.lua#L739) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Binding/Core/PushPress.lua:836](../../Binding/Core/PushPress.lua#L836) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/PushPress.lua:837](../../Binding/Core/PushPress.lua#L837) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Input/FluxMouseoverKeybind.lua:1922](../../Binding/Input/FluxMouseoverKeybind.lua#L1922) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Binding/Input/FluxMouseoverKeybind.lua:1923](../../Binding/Input/FluxMouseoverKeybind.lua#L1923) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Input/FluxMouseoverKeybind.lua:1924](../../Binding/Input/FluxMouseoverKeybind.lua#L1924) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/Input/FluxMouseoverKeybind.lua:1925](../../Binding/Input/FluxMouseoverKeybind.lua#L1925) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Input/FluxMouseoverKeybind.lua:1926](../../Binding/Input/FluxMouseoverKeybind.lua#L1926) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [Binding/Respec.lua:355](../../Binding/Respec.lua#L355) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/UI/Browser/Core.lua:1894](../../Binding/UI/Browser/Core.lua#L1894) | `RegisterEvent` | `"ACTIONBAR_SLOT_CHANGED"` |
| [Binding/UI/Browser/Core.lua:1895](../../Binding/UI/Browser/Core.lua#L1895) | `RegisterEvent` | `"UPDATE_MACROS"` |
| [Binding/UI/Browser/Core.lua:1896](../../Binding/UI/Browser/Core.lua#L1896) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/UI/Browser/Core.lua:1897](../../Binding/UI/Browser/Core.lua#L1897) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Binding/UI/Browser/Core.lua:1898](../../Binding/UI/Browser/Core.lua#L1898) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Binding/UI/Editor/Core.lua:717](../../Binding/UI/Editor/Core.lua#L717) | `RegisterEvent` | `"ACTIONBAR_SLOT_CHANGED"` |
| [Binding/UI/Editor/Core.lua:718](../../Binding/UI/Editor/Core.lua#L718) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/UI/Editor/Core.lua:719](../../Binding/UI/Editor/Core.lua#L719) | `RegisterEvent` | `"UPDATE_MACROS"` |
| [Binding/UI/Editor/Core.lua:720](../../Binding/UI/Editor/Core.lua#L720) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Binding/UI/Editor/Core.lua:721](../../Binding/UI/Editor/Core.lua#L721) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Binding/UI/KeyVisualizer/Core.lua:1954](../../Binding/UI/KeyVisualizer/Core.lua#L1954) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Binding/UI/KeyVisualizer/Core.lua:1955](../../Binding/UI/KeyVisualizer/Core.lua#L1955) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/UI/KeyVisualizer/Core.lua:1956](../../Binding/UI/KeyVisualizer/Core.lua#L1956) | `RegisterEvent` | `"ACTIONBAR_SLOT_CHANGED"` |
| [Binding/UI/KeyVisualizer/Core.lua:1957](../../Binding/UI/KeyVisualizer/Core.lua#L1957) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [Binding/UI/SpellbookBindingHooks.lua:214](../../Binding/UI/SpellbookBindingHooks.lua#L214) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/UI/SpellbookBindingHooks.lua:466](../../Binding/UI/SpellbookBindingHooks.lua#L466) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Binding/UI/SpellbookBindingHooks.lua:467](../../Binding/UI/SpellbookBindingHooks.lua#L467) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Binding/UI/SpellbookBindingHooks.lua:468](../../Binding/UI/SpellbookBindingHooks.lua#L468) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Blizzard/Hide.lua:45](../../Blizzard/Hide.lua#L45) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Blizzard/Hide.lua:194](../../Blizzard/Hide.lua#L194) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [BlizzardSettings/Nameplates.lua:216](../../BlizzardSettings/Nameplates.lua#L216) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [BlizzardSettings/Write.lua:251](../../BlizzardSettings/Write.lua#L251) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [CharacterInfo/ItemLevel.lua:305](../../CharacterInfo/ItemLevel.lua#L305) | `RegisterEvent` | `"ADDON_LOADED"` |
| [CharacterInfo/ItemLevel.lua:306](../../CharacterInfo/ItemLevel.lua#L306) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [CharacterInfo/ItemLevel.lua:307](../../CharacterInfo/ItemLevel.lua#L307) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [CharacterInfo/ItemLevel.lua:308](../../CharacterInfo/ItemLevel.lua#L308) | `RegisterEvent` | `"GET_ITEM_INFO_RECEIVED"` |
| [CharacterInfo/PaperDollQuality.lua:165](../../CharacterInfo/PaperDollQuality.lua#L165) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [CharacterInfo/PaperDollQuality.lua:166](../../CharacterInfo/PaperDollQuality.lua#L166) | `RegisterEvent` | `"UNIT_INVENTORY_CHANGED"` |
| [CharacterInfo/PaperDollSecondaryName.lua:369](../../CharacterInfo/PaperDollSecondaryName.lua#L369) | `RegisterEvent` | `"CVAR_UPDATE"` |
| [CharacterInfo/PaperDollSecondaryName.lua:370](../../CharacterInfo/PaperDollSecondaryName.lua#L370) | `RegisterEvent` | `"UNIT_NAME_UPDATE"` |
| [CharacterInfo/PaperDollVisibility.lua:201](../../CharacterInfo/PaperDollVisibility.lua#L201) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [CharacterInfo/PaperDollVisibility.lua:202](../../CharacterInfo/PaperDollVisibility.lua#L202) | `RegisterEvent` | `"VARIABLES_LOADED"` |
| [CharacterInfo/PaperDollVisibility.lua:203](../../CharacterInfo/PaperDollVisibility.lua#L203) | `RegisterEvent` | `"UNIT_MODEL_CHANGED"` |
| [CharacterInfo/RetailPane.lua:650](../../CharacterInfo/RetailPane.lua#L650) | `RegisterEvent` | `"PLAYER_AVG_ITEM_LEVEL_UPDATE"` |
| [CharacterInfo/StatsCritCalculator.lua:398](../../CharacterInfo/StatsCritCalculator.lua#L398) | `RegisterEvent` | `"UNIT_AURA"` |
| [CharacterInfo/StatsCritCalculator.lua:401](../../CharacterInfo/StatsCritCalculator.lua#L401) | `RegisterEvent` | `"COMBAT_LOG_EVENT_UNFILTERED"` |
| [CharacterInfo/StatsCritCalculator.lua:407](../../CharacterInfo/StatsCritCalculator.lua#L407) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [CharacterInfo/StatsCustomExtensions.lua:400](../../CharacterInfo/StatsCustomExtensions.lua#L400) | `RegisterEvent` | `"ADDON_LOADED"` |
| [CharacterInfo/StatsCustomExtensions.lua:401](../../CharacterInfo/StatsCustomExtensions.lua#L401) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [CharacterInfo/StatsCustomExtensions.lua:421](../../CharacterInfo/StatsCustomExtensions.lua#L421) | `RegisterEvent` | `"ADDON_LOADED"` |
| [CharacterInfo/StatsCustomExtensions.lua:422](../../CharacterInfo/StatsCustomExtensions.lua#L422) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [CharacterInfo/StatsEra.lua:447](../../CharacterInfo/StatsEra.lua#L447) | `RegisterEvent` | `"ADDON_LOADED"` |
| [CharacterInfo/StatsEra.lua:448](../../CharacterInfo/StatsEra.lua#L448) | `RegisterEvent` | `"PLAYER_LOGOUT"` |
| [CharacterInfo/StatsEra.lua:449](../../CharacterInfo/StatsEra.lua#L449) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [CharacterInfo/StatsEra.lua:488](../../CharacterInfo/StatsEra.lua#L488) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [CharacterInfo/StatsEra.lua:489](../../CharacterInfo/StatsEra.lua#L489) | `RegisterEvent` | `"UNIT_AURA"` |
| [CharacterInfo/StatsEra.lua:490](../../CharacterInfo/StatsEra.lua#L490) | `RegisterEvent` | `"PLAYER_DAMAGE_DONE_MODS"` |
| [CharacterInfo/StatsEra.lua:491](../../CharacterInfo/StatsEra.lua#L491) | `RegisterEvent` | `"SKILL_LINES_CHANGED"` |
| [CharacterInfo/StatsEra.lua:492](../../CharacterInfo/StatsEra.lua#L492) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [CharacterInfo/StatsEra.lua:493](../../CharacterInfo/StatsEra.lua#L493) | `RegisterEvent` | `"UNIT_DAMAGE"` |
| [CharacterInfo/StatsEra.lua:494](../../CharacterInfo/StatsEra.lua#L494) | `RegisterEvent` | `"UNIT_ATTACK_SPEED"` |
| [CharacterInfo/StatsEra.lua:495](../../CharacterInfo/StatsEra.lua#L495) | `RegisterEvent` | `"UNIT_RANGEDDAMAGE"` |
| [CharacterInfo/StatsEra.lua:496](../../CharacterInfo/StatsEra.lua#L496) | `RegisterEvent` | `"UNIT_ATTACK"` |
| [CharacterInfo/StatsEra.lua:497](../../CharacterInfo/StatsEra.lua#L497) | `RegisterEvent` | `"UNIT_RESISTANCES"` |
| [CharacterInfo/StatsEra.lua:498](../../CharacterInfo/StatsEra.lua#L498) | `RegisterEvent` | `"UNIT_STATS"` |
| [CharacterInfo/StatsEra.lua:499](../../CharacterInfo/StatsEra.lua#L499) | `RegisterEvent` | `"UNIT_MAXHEALTH"` |
| [CharacterInfo/StatsEra.lua:500](../../CharacterInfo/StatsEra.lua#L500) | `RegisterEvent` | `"UNIT_ATTACK_POWER"` |
| [CharacterInfo/StatsEra.lua:501](../../CharacterInfo/StatsEra.lua#L501) | `RegisterEvent` | `"UNIT_RANGED_ATTACK_POWER"` |
| [CharacterInfo/StatsEra.lua:502](../../CharacterInfo/StatsEra.lua#L502) | `RegisterEvent` | `"COMBAT_RATING_UPDATE"` |
| [CharacterInfo/StatsEra.lua:503](../../CharacterInfo/StatsEra.lua#L503) | `RegisterEvent` | `"VARIABLES_LOADED"` |
| [CharacterInfo/StatsProgression.lua:870](../../CharacterInfo/StatsProgression.lua#L870) | `RegisterEvent` | `"ADDON_LOADED"` |
| [CharacterInfo/StatsProgression.lua:871](../../CharacterInfo/StatsProgression.lua#L871) | `RegisterEvent` | `"PLAYER_LOGOUT"` |
| [CharacterInfo/StatsProgression.lua:872](../../CharacterInfo/StatsProgression.lua#L872) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [CharacterInfo/StatsProgression.lua:923](../../CharacterInfo/StatsProgression.lua#L923) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [CharacterInfo/StatsProgression.lua:924](../../CharacterInfo/StatsProgression.lua#L924) | `RegisterEvent` | `"UNIT_AURA"` |
| [CharacterInfo/StatsProgression.lua:925](../../CharacterInfo/StatsProgression.lua#L925) | `RegisterEvent` | `"PLAYER_DAMAGE_DONE_MODS"` |
| [CharacterInfo/StatsProgression.lua:926](../../CharacterInfo/StatsProgression.lua#L926) | `RegisterEvent` | `"SKILL_LINES_CHANGED"` |
| [CharacterInfo/StatsProgression.lua:927](../../CharacterInfo/StatsProgression.lua#L927) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [CharacterInfo/StatsProgression.lua:928](../../CharacterInfo/StatsProgression.lua#L928) | `RegisterEvent` | `"UNIT_DAMAGE"` |
| [CharacterInfo/StatsProgression.lua:929](../../CharacterInfo/StatsProgression.lua#L929) | `RegisterEvent` | `"UNIT_ATTACK_SPEED"` |
| [CharacterInfo/StatsProgression.lua:930](../../CharacterInfo/StatsProgression.lua#L930) | `RegisterEvent` | `"UNIT_RANGEDDAMAGE"` |
| [CharacterInfo/StatsProgression.lua:931](../../CharacterInfo/StatsProgression.lua#L931) | `RegisterEvent` | `"UNIT_ATTACK"` |
| [CharacterInfo/StatsProgression.lua:932](../../CharacterInfo/StatsProgression.lua#L932) | `RegisterEvent` | `"UNIT_RESISTANCES"` |
| [CharacterInfo/StatsProgression.lua:933](../../CharacterInfo/StatsProgression.lua#L933) | `RegisterEvent` | `"UNIT_STATS"` |
| [CharacterInfo/StatsProgression.lua:934](../../CharacterInfo/StatsProgression.lua#L934) | `RegisterEvent` | `"UNIT_MAXHEALTH"` |
| [CharacterInfo/StatsProgression.lua:935](../../CharacterInfo/StatsProgression.lua#L935) | `RegisterEvent` | `"UNIT_ATTACK_POWER"` |
| [CharacterInfo/StatsProgression.lua:936](../../CharacterInfo/StatsProgression.lua#L936) | `RegisterEvent` | `"UNIT_RANGED_ATTACK_POWER"` |
| [CharacterInfo/StatsProgression.lua:937](../../CharacterInfo/StatsProgression.lua#L937) | `RegisterEvent` | `"COMBAT_RATING_UPDATE"` |
| [CharacterInfo/StatsProgression.lua:938](../../CharacterInfo/StatsProgression.lua#L938) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [CharacterInfo/StatsProgression.lua:939](../../CharacterInfo/StatsProgression.lua#L939) | `RegisterEvent` | `"VARIABLES_LOADED"` |
| [CharacterInfo/TacoTip.lua:64](../../CharacterInfo/TacoTip.lua#L64) | `RegisterEvent` | `"ADDON_LOADED"` |
| [CharacterInfo/TacoTip.lua:65](../../CharacterInfo/TacoTip.lua#L65) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ConsoleportCompat/Loader.lua:48](../../ConsoleportCompat/Loader.lua#L48) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ConsoleportCompat/Loader.lua:49](../../ConsoleportCompat/Loader.lua#L49) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ConsoleportCompat/Loader.lua:50](../../ConsoleportCompat/Loader.lua#L50) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/API/Container.lua:318](../../Core/API/Container.lua#L318) | `RegisterEvent` | `event` |
| [Core/ButtonFX/Overlay.lua:1827](../../Core/ButtonFX/Overlay.lua#L1827) | `RegisterEvent` | `"GLOBAL_MOUSE_UP"` |
| [Core/ButtonFX/Overlay.lua:2069](../../Core/ButtonFX/Overlay.lua#L2069) | `RegisterEvent` | `"GLOBAL_MOUSE_UP"` |
| [Core/Capabilities.lua:158](../../Core/Capabilities.lua#L158) | `RegisterEvent` | `"COMBAT_LOG_EVENT_UNFILTERED"` |
| [Core/Capabilities.lua:195](../../Core/Capabilities.lua#L195) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_RETICLE_TARGET", "player"` |
| [Core/Capabilities.lua:198](../../Core/Capabilities.lua#L198) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_RETICLE_CLEAR", "player"` |
| [Core/Capabilities.lua:526](../../Core/Capabilities.lua#L526) | `RegisterUnitEvent` | `"UNIT_HEALTH", "focus"` |
| [Core/Client_Camelot.lua:171](../../Core/Client_Camelot.lua#L171) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Core/Engine/Combat.lua:182](../../Core/Engine/Combat.lua#L182) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/Engine/Context.lua:274](../../Core/Engine/Context.lua#L274) | `Subscribe` | `fn` |
| [Core/Engine/Context.lua:512](../../Core/Engine/Context.lua#L512) | `RegisterEvent` | `"UPDATE_MOUSEOVER_UNIT"` |
| [Core/Engine/Context.lua:513](../../Core/Engine/Context.lua#L513) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [Core/Engine/Context.lua:514](../../Core/Engine/Context.lua#L514) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/Engine/Context.lua:515](../../Core/Engine/Context.lua#L515) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Core/Engine/Modifier.lua:94](../../Core/Engine/Modifier.lua#L94) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Core/Engine/Restricted.lua:304](../../Core/Engine/Restricted.lua#L304) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [Core/Engine/Restricted.lua:305](../../Core/Engine/Restricted.lua#L305) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [Core/Engine/Restricted.lua:306](../../Core/Engine/Restricted.lua#L306) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Core/Engine/Restricted.lua:307](../../Core/Engine/Restricted.lua#L307) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/Engine/Restricted.lua:308](../../Core/Engine/Restricted.lua#L308) | `RegisterEvent` | `"UNIT_PET"` |
| [Core/Engine/Restricted.lua:309](../../Core/Engine/Restricted.lua#L309) | `RegisterEvent` | `"UNIT_TARGET"` |
| [Core/Engine/Restricted.lua:310](../../Core/Engine/Restricted.lua#L310) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [Core/Engine/Restricted.lua:311](../../Core/Engine/Restricted.lua#L311) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [Core/Engine/Restricted.lua:312](../../Core/Engine/Restricted.lua#L312) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Core/Engine/Restricted.lua:313](../../Core/Engine/Restricted.lua#L313) | `RegisterEvent` | `"ACTIONBAR_PAGE_CHANGED"` |
| [Core/Engine/Restricted.lua:314](../../Core/Engine/Restricted.lua#L314) | `RegisterEvent` | `"UPDATE_BONUS_ACTIONBAR"` |
| [Core/Engine/Restricted.lua:315](../../Core/Engine/Restricted.lua#L315) | `RegisterEvent` | `"UPDATE_STEALTH"` |
| [Core/Flux.lua:173](../../Core/Flux.lua#L173) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Core/Flux.lua:174](../../Core/Flux.lua#L174) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Core/Flux.lua:175](../../Core/Flux.lua#L175) | `RegisterEvent` | `"VARIABLES_LOADED"` |
| [Core/Flux.lua:176](../../Core/Flux.lua#L176) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Core/Flux.lua:203](../../Core/Flux.lua#L203) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/FluxAPI/Auras.lua:396](../../Core/FluxAPI/Auras.lua#L396) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Core/FluxAPI/Capabilities.lua:59](../../Core/FluxAPI/Capabilities.lua#L59) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_RETICLE_TARGET", "player"` |
| [Core/FluxAPI/Capabilities.lua:62](../../Core/FluxAPI/Capabilities.lua#L62) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_RETICLE_CLEAR", "player"` |
| [Core/FluxAPI/Capabilities.lua:321](../../Core/FluxAPI/Capabilities.lua#L321) | `RegisterUnitEvent` | `"UNIT_HEALTH", "focus"` |
| [Core/FluxAPI/FluxAPI_Boot.lua:12](../../Core/FluxAPI/FluxAPI_Boot.lua#L12) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Core/FluxAPI/UI.lua:482](../../Core/FluxAPI/UI.lua#L482) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Core/FluxAPI/UI.lua:483](../../Core/FluxAPI/UI.lua#L483) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Core/FluxAPI/UI.lua:1325](../../Core/FluxAPI/UI.lua#L1325) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Core/FluxAPI/UI.lua:1326](../../Core/FluxAPI/UI.lua#L1326) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Core/FluxAPI/UI.lua:1327](../../Core/FluxAPI/UI.lua#L1327) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Core/FluxAPI/UI.lua:1328](../../Core/FluxAPI/UI.lua#L1328) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [Core/FluxAPI/UI.lua:1329](../../Core/FluxAPI/UI.lua#L1329) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [Core/FluxAPI/UI.lua:1330](../../Core/FluxAPI/UI.lua#L1330) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Core/FluxAPI/UI.lua:1331](../../Core/FluxAPI/UI.lua#L1331) | `RegisterUnitEvent` | `"UNIT_MAXPOWER", "player"` |
| [Core/SecureClickProxy.lua:209](../../Core/SecureClickProxy.lua#L209) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/Slash.lua:158](../../Core/Slash.lua#L158) | `RegisterEvent` | `"UNIT_SPELLCAST_SENT"` |
| [Core/Slash.lua:159](../../Core/Slash.lua#L159) | `RegisterEvent` | `"UNIT_SPELLCAST_SUCCEEDED"` |
| [ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua:337](../../ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua#L337) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua:338](../../ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua#L338) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua:339](../../ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua#L339) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua:340](../../ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua#L340) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua:341](../../ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua#L341) | `RegisterEvent` | `"UPDATE_INVENTORY_DURABILITY"` |
| [ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua:219](../../ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua#L219) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua:220](../../ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua#L220) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua:253](../../ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua#L253) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua:231](../../ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua#L231) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua:232](../../ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua#L232) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua:271](../../ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua#L271) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/CombatGrid/GridManager.lua:336](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L336) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/CombatGrid/GridManager.lua:337](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L337) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/CombatGrid/GridManager.lua:338](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L338) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:1872](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1872) | `RegisterEvent` | `"TRADE_SKILL_SHOW"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:2642](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2642) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:2643](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2643) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:3371](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3371) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:3372](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3372) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:3373](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3373) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/ExtraButtons/Buttons.lua:122](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L122) | `RegisterEvent` | `"CURSOR_CHANGED"` |
| [ExtraButtonSystem/ExtraButtons/UI.lua:579](../../ExtraButtonSystem/ExtraButtons/UI.lua#L579) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/ExtraButtons/UI.lua:758](../../ExtraButtonSystem/ExtraButtons/UI.lua#L758) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/ExtraButtons/UI.lua:759](../../ExtraButtonSystem/ExtraButtons/UI.lua#L759) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ExtraButtonSystem/ExtraButtons/UI.lua:760](../../ExtraButtonSystem/ExtraButtons/UI.lua#L760) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:1390](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1390) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:1391](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1391) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6049](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6049) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6050](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6050) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6051](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6051) | `RegisterUnitEvent` | `"UNIT_AURA", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6054](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6054) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6057](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6057) | `RegisterEvent` | `"UNIT_SPELLCAST_SUCCEEDED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6060](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6060) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6061](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6061) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6063](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6063) | `RegisterEvent` | `"PLAYER_DEAD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6064](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6064) | `RegisterEvent` | `"PLAYER_ALIVE"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6065](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6065) | `RegisterEvent` | `"PLAYER_UNGHOST"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6066](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6066) | `RegisterEvent` | `"SPELL_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua:1094](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1094) | `RegisterEvent` | `"SPELL_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua:1095](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1095) | `RegisterEvent` | `"ACTIONBAR_SLOT_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua:1129](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1129) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua:1130](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1130) | `RegisterUnitEvent` | `"UNIT_AURA", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua:536](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L536) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua:537](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L537) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua:538](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L538) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua:546](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L546) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua:2130](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2130) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua:2131](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2131) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua:2132](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2132) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua:2133](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2133) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua:2134](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2134) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_START", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua:2135](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2135) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_STOP", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua:2136](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2136) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua:2137](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2137) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_INTERRUPTED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua:2138](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2138) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_FAILED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua:2140](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2140) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SENT", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua:2143](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2143) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_CHANNEL_START", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3107](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3107) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3108](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3108) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3109](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3109) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3110](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3110) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3118](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3118) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3122](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3122) | `RegisterEvent` | `"SKILL_LINES_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3125](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3125) | `RegisterEvent` | `"SKILL_LINES_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3130](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3130) | `RegisterEvent` | `"MOUNT_JOURNAL_USABILITY_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3131](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3131) | `RegisterEvent` | `"NEW_MOUNT_ADDED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3134](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3134) | `RegisterEvent` | `"COLLECTIONS_UPDATED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3136](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3136) | `RegisterEvent` | `"COLLECTIONS_UPDATED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3139](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3139) | `RegisterEvent` | `"COMPANION_LEARNED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3143](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3143) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_START", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3144](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3144) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_STOP", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3145](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3145) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3146](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3146) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_INTERRUPTED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3147](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3147) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_FAILED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3148](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3148) | `RegisterEvent` | `"PLAYER_MOUNT_DISPLAY_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua:816](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L816) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua:817](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L817) | `RegisterEvent` | `"GET_ITEM_INFO_RECEIVED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2903](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2903) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2904](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2904) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2912](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2912) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2915](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2915) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_START", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2916](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2916) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2917](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2917) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_STOP", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2918](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2918) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_INTERRUPTED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2919](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2919) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_FAILED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua:174](../../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua#L174) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua:175](../../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua#L175) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua:176](../../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua#L176) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua:209](../../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua#L209) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:390](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L390) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:797](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L797) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:798](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L798) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:983](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L983) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:1000](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L1000) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:1001](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L1001) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:1002](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L1002) | `RegisterEvent` | `"NEW_MOUNT_ADDED"` |
| [ExtraButtonSystem/NonCombatGrid/GridInit.lua:139](../../ExtraButtonSystem/NonCombatGrid/GridInit.lua#L139) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/GridInit.lua:140](../../ExtraButtonSystem/NonCombatGrid/GridInit.lua#L140) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua:832](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L832) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1146](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1146) | `RegisterEvent` | `"CURSOR_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1147](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1147) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1148](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1148) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1149](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1149) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1151](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1151) | `RegisterEvent` | `"TRANSMOG_OUTFITS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1152](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1152) | `RegisterEvent` | `"TRANSMOG_DISPLAYED_OUTFIT_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1156](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1156) | `RegisterEvent` | `"SPELL_UPDATE_CHARGES"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1161](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1161) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1163](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1163) | `RegisterEvent` | `"BAG_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1164](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1164) | `RegisterEvent` | `"CURRENT_SPELL_CAST_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1165](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1165) | `RegisterEvent` | `"ACTIONBAR_UPDATE_STATE"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1166](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1166) | `RegisterEvent` | `"COMPANION_UPDATE"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1167](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1167) | `RegisterEvent` | `"PLAYER_MOUNT_DISPLAY_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1169](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1169) | `RegisterUnitEvent` | `"UNIT_PET", "player"` |
| [ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua:626](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L626) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/Shared/HotkeyUtil.lua:415](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L415) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/Shared/HotkeyUtil.lua:416](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L416) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [ExtraButtonSystem/Shared/HotkeyUtil.lua:417](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L417) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua:819](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L819) | `RegisterEvent` | `"GLOBAL_MOUSE_UP"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua:820](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L820) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:131](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L131) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:132](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L132) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:133](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L133) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:134](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L134) | `RegisterEvent` | `"ACTIONBAR_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:135](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L135) | `RegisterEvent` | `"BAG_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:136](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L136) | `RegisterEvent` | `"SPELL_UPDATE_USABLE"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:137](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L137) | `RegisterEvent` | `"ACTIONBAR_UPDATE_STATE"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:138](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L138) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:139](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L139) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:140](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L140) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:141](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L141) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:142](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L142) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:146](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L146) | `RegisterEvent` | `"PET_BATTLE_OPENING_START"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:147](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L147) | `RegisterEvent` | `"PET_BATTLE_CLOSE"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:324](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L324) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [FluxBorder.lua:33](../../FluxBorder.lua#L33) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [FluxDefaultSettings.lua:56](../../FluxDefaultSettings.lua#L56) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [FluxDefaultSettings.lua:57](../../FluxDefaultSettings.lua#L57) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [FluxDefaultSettings.lua:58](../../FluxDefaultSettings.lua#L58) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [FluxDefaultSettings.lua:59](../../FluxDefaultSettings.lua#L59) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [FluxDefaultSettings.lua:79](../../FluxDefaultSettings.lua#L79) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [FluxDefaultSettings.lua:1164](../../FluxDefaultSettings.lua#L1164) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [FluxDefaultSettings.lua:2894](../../FluxDefaultSettings.lua#L2894) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [FluxDefaultSettings.lua:2895](../../FluxDefaultSettings.lua#L2895) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [FluxDefaultSettings.lua:2896](../../FluxDefaultSettings.lua#L2896) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [FluxDefaultSettings.lua:2898](../../FluxDefaultSettings.lua#L2898) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [FluxDefaultSettings.lua:2901](../../FluxDefaultSettings.lua#L2901) | `RegisterEvent` | `"COMPACT_UNIT_FRAME_PROFILES_LOADED"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:1164](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L1164) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:2424](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2424) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:2425](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2425) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:2426](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2426) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:2427](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2427) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:2428](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2428) | `RegisterEvent` | `"CURSOR_CHANGED"` |
| [Inventory/Builtin/Mail.lua:334](../../Inventory/Builtin/Mail.lua#L334) | `RegisterEvent` | `"MAIL_SEND_SUCCESS"` |
| [Inventory/Builtin/Mail.lua:335](../../Inventory/Builtin/Mail.lua#L335) | `RegisterEvent` | `"MAIL_FAILED"` |
| [Inventory/Builtin/Mail.lua:361](../../Inventory/Builtin/Mail.lua#L361) | `RegisterEvent` | `"MAIL_SUCCESS"` |
| [Inventory/Builtin/Mail.lua:362](../../Inventory/Builtin/Mail.lua#L362) | `RegisterEvent` | `"MAIL_FAILED"` |
| [Inventory/CreateSpells.lua:441](../../Inventory/CreateSpells.lua#L441) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Inventory/CreateSpells.lua:457](../../Inventory/CreateSpells.lua#L457) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:472](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L472) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:473](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L473) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:474](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L474) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:475](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L475) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:476](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L476) | `RegisterEvent` | `"SKILL_LINES_CHANGED"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:477](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L477) | `RegisterEvent` | `"UNIT_MAXHEALTH"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:478](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L478) | `RegisterEvent` | `"UNIT_MAXPOWER"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:628](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L628) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [Inventory/FluxItemClass.lua:635](../../Inventory/FluxItemClass.lua#L635) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [Inventory/FluxItemClass.lua:636](../../Inventory/FluxItemClass.lua#L636) | `RegisterEvent` | `"GET_ITEM_INFO_RECEIVED"` |
| [Inventory/Init.lua:242](../../Inventory/Init.lua#L242) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:516](../../Inventory/Restock/Bank/FluxBankRestock.lua#L516) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:517](../../Inventory/Restock/Bank/FluxBankRestock.lua#L517) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:518](../../Inventory/Restock/Bank/FluxBankRestock.lua#L518) | `RegisterEvent` | `"ITEM_UNLOCKED"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:519](../../Inventory/Restock/Bank/FluxBankRestock.lua#L519) | `RegisterEvent` | `"PLAYERBANKBAGSLOTS_CHANGED"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:2248](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2248) | `RegisterEvent` | `"UI_ERROR_MESSAGE"` |
| [Inventory/Restock/Core/FluxRestockList.lua:1488](../../Inventory/Restock/Core/FluxRestockList.lua#L1488) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Core/FluxRestockSettings.lua:226](../../Inventory/Restock/Core/FluxRestockSettings.lua#L226) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Junk/FluxJunk.lua:1648](../../Inventory/Restock/Junk/FluxJunk.lua#L1648) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Junk/FluxJunk.lua:1649](../../Inventory/Restock/Junk/FluxJunk.lua#L1649) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1849](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1849) | `RegisterEvent` | `ev` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1933](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1933) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1934](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1934) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1935](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1935) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1936](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1936) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [Inventory/Restock/Junk/FluxVendorJunkPanel.lua:681](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L681) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [Inventory/Restock/Junk/FluxVendorJunkPanel.lua:739](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L739) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua:153](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L153) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnown.lua:485](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L485) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnown.lua:486](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L486) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua:565](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L565) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua:94](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L94) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua:3434](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3434) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua:3435](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3435) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua:3436](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3436) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1612](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1612) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1613](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1613) | `RegisterEvent` | `"MERCHANT_UPDATE"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1614](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1614) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1615](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1615) | `RegisterEvent` | `"UI_ERROR_MESSAGE"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1623](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1623) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Vendor/FluxVendorRestockPanel.lua:1048](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1048) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Vendor/FluxVendorRestockPanel.lua:1234](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1234) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Layout/UnifiedBorder.lua:857](../../Layout/UnifiedBorder.lua#L857) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Layout/UnifiedBorder.lua:858](../../Layout/UnifiedBorder.lua#L858) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Layout/UnifiedBorder.lua:859](../../Layout/UnifiedBorder.lua#L859) | `RegisterEvent` | `"ACTIONBAR_SLOT_CHANGED"` |
| [Layout/UnifiedBorder.lua:860](../../Layout/UnifiedBorder.lua#L860) | `RegisterEvent` | `"CURSOR_CHANGED"` |
| [MicroMenu/FluxAddonMicroButton.lua:103](../../MicroMenu/FluxAddonMicroButton.lua#L103) | `RegisterEvent` | `"PLAYER_STARTED_MOVING"` |
| [MicroMenu/FluxAddonMicroButton.lua:628](../../MicroMenu/FluxAddonMicroButton.lua#L628) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxAddonMicroButton.lua:629](../../MicroMenu/FluxAddonMicroButton.lua#L629) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [MicroMenu/FluxBagMicroButton.lua:160](../../MicroMenu/FluxBagMicroButton.lua#L160) | `RegisterEvent` | `"PLAYER_STARTED_MOVING"` |
| [MicroMenu/FluxBagMicroButton.lua:503](../../MicroMenu/FluxBagMicroButton.lua#L503) | `RegisterEvent` | `"ADDON_LOADED"` |
| [MicroMenu/FluxBagMicroButton.lua:742](../../MicroMenu/FluxBagMicroButton.lua#L742) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxBagMicroButton.lua:746](../../MicroMenu/FluxBagMicroButton.lua#L746) | `RegisterEvent` | `"BAG_UPDATE"` |
| [MicroMenu/FluxBagMicroButton.lua:747](../../MicroMenu/FluxBagMicroButton.lua#L747) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [MicroMenu/FluxCombinedBagHeader.lua:1079](../../MicroMenu/FluxCombinedBagHeader.lua#L1079) | `RegisterEvent` | `"ADDON_LOADED"` |
| [MicroMenu/FluxCombinedBagHeader.lua:1080](../../MicroMenu/FluxCombinedBagHeader.lua#L1080) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxCombinedBagHeader.lua:1081](../../MicroMenu/FluxCombinedBagHeader.lua#L1081) | `RegisterEvent` | `"BAG_UPDATE"` |
| [MicroMenu/FluxCombinedBagHeader.lua:1082](../../MicroMenu/FluxCombinedBagHeader.lua#L1082) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [MicroMenu/FluxLFGMicroButton.lua:153](../../MicroMenu/FluxLFGMicroButton.lua#L153) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxLFGMicroButton.lua:154](../../MicroMenu/FluxLFGMicroButton.lua#L154) | `RegisterEvent` | `"ADDON_LOADED"` |
| [MicroMenu/FluxLFGMicroButton.lua:380](../../MicroMenu/FluxLFGMicroButton.lua#L380) | `RegisterEvent` | `"LFG_LIST_ACTIVE_ENTRY_UPDATE"` |
| [MicroMenu/FluxLFGMicroButton.lua:381](../../MicroMenu/FluxLFGMicroButton.lua#L381) | `RegisterEvent` | `"LFG_LIST_APPLICANT_UPDATED"` |
| [MicroMenu/FluxLFGMicroButton.lua:382](../../MicroMenu/FluxLFGMicroButton.lua#L382) | `RegisterEvent` | `"LFG_UPDATE"` |
| [MicroMenu/FluxLFGMicroButton.lua:383](../../MicroMenu/FluxLFGMicroButton.lua#L383) | `RegisterEvent` | `"LFG_QUEUE_STATUS_UPDATE"` |
| [MicroMenu/FluxLFGMicroButton.lua:384](../../MicroMenu/FluxLFGMicroButton.lua#L384) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxLFGMicroButton.lua:385](../../MicroMenu/FluxLFGMicroButton.lua#L385) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [MicroMenu/FluxLFGMicroButton.lua:414](../../MicroMenu/FluxLFGMicroButton.lua#L414) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [MicroMenu/FluxLFGMicroButton.lua:415](../../MicroMenu/FluxLFGMicroButton.lua#L415) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxMicroMenu.lua:435](../../MicroMenu/FluxMicroMenu.lua#L435) | `RegisterEvent` | `"UNIT_PORTRAIT_UPDATE"` |
| [MicroMenu/FluxMicroMenu.lua:436](../../MicroMenu/FluxMicroMenu.lua#L436) | `RegisterEvent` | `"PORTRAITS_UPDATED"` |
| [MicroMenu/FluxMicroMenu.lua:437](../../MicroMenu/FluxMicroMenu.lua#L437) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxMicroMenu.lua:3033](../../MicroMenu/FluxMicroMenu.lua#L3033) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [MicroMenu/FluxMicroMenu.lua:3034](../../MicroMenu/FluxMicroMenu.lua#L3034) | `RegisterEvent` | `"ADDON_LOADED"` |
| [MicroMenu/FluxMicroMenu.lua:3035](../../MicroMenu/FluxMicroMenu.lua#L3035) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [MicroMenu/FluxMicroMenu.lua:3036](../../MicroMenu/FluxMicroMenu.lua#L3036) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [MicroMenu/FluxMicroMenu.lua:3037](../../MicroMenu/FluxMicroMenu.lua#L3037) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxMicroMenu.lua:3038](../../MicroMenu/FluxMicroMenu.lua#L3038) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [MicroMenu/FluxMicroMenu.lua:3039](../../MicroMenu/FluxMicroMenu.lua#L3039) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [MicroMenu/FluxMicroMenuConfigUI.lua:451](../../MicroMenu/FluxMicroMenuConfigUI.lua#L451) | `RegisterEvent` | `"PLAYER_STARTED_MOVING"` |
| [MicroMenu/FluxMinimapToMicro.lua:751](../../MicroMenu/FluxMinimapToMicro.lua#L751) | `RegisterEvent` | `"PLAYER_STARTED_MOVING"` |
| [MicroMenu/FluxMinimapToMicro.lua:1615](../../MicroMenu/FluxMinimapToMicro.lua#L1615) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [MicroMenu/FluxMinimapToMicro.lua:1616](../../MicroMenu/FluxMinimapToMicro.lua#L1616) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxTradeSkillMicro.lua:700](../../MicroMenu/FluxTradeSkillMicro.lua#L700) | `RegisterEvent` | `"PLAYER_STARTED_MOVING"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1073](../../MicroMenu/FluxTradeSkillMicro.lua#L1073) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1074](../../MicroMenu/FluxTradeSkillMicro.lua#L1074) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1075](../../MicroMenu/FluxTradeSkillMicro.lua#L1075) | `RegisterEvent` | `"SKILL_LINES_CHANGED"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1076](../../MicroMenu/FluxTradeSkillMicro.lua#L1076) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1080](../../MicroMenu/FluxTradeSkillMicro.lua#L1080) | `RegisterEvent` | `"LEARNED_SPELL_IN_SKILL_LINE"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1081](../../MicroMenu/FluxTradeSkillMicro.lua#L1081) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [Minimap/FluxBuffDebuffFrames.lua:94](../../Minimap/FluxBuffDebuffFrames.lua#L94) | `RegisterEvent` | `event` |
| [Minimap/FluxMinimap.lua:74](../../Minimap/FluxMinimap.lua#L74) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Minimap/FluxMinimap.lua:75](../../Minimap/FluxMinimap.lua#L75) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:76](../../Minimap/FluxMinimap.lua#L76) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Minimap/FluxMinimap.lua:77](../../Minimap/FluxMinimap.lua#L77) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimap.lua:79](../../Minimap/FluxMinimap.lua#L79) | `RegisterEvent` | `"UPDATE_INSTANCE_INFO"` |
| [Minimap/FluxMinimap.lua:80](../../Minimap/FluxMinimap.lua#L80) | `RegisterEvent` | `"PLAYER_DIFFICULTY_CHANGED"` |
| [Minimap/FluxMinimap.lua:81](../../Minimap/FluxMinimap.lua#L81) | `RegisterEvent` | `"INSTANCE_GROUP_SIZE_CHANGED"` |
| [Minimap/FluxMinimap.lua:82](../../Minimap/FluxMinimap.lua#L82) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [Minimap/FluxMinimap.lua:83](../../Minimap/FluxMinimap.lua#L83) | `RegisterEvent` | `"MINIMAP_UPDATE_TRACKING"` |
| [Minimap/FluxMinimap.lua:85](../../Minimap/FluxMinimap.lua#L85) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [Minimap/FluxMinimap.lua:86](../../Minimap/FluxMinimap.lua#L86) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [Minimap/FluxMinimap.lua:429](../../Minimap/FluxMinimap.lua#L429) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:430](../../Minimap/FluxMinimap.lua#L430) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [Minimap/FluxMinimap.lua:431](../../Minimap/FluxMinimap.lua#L431) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [Minimap/FluxMinimap.lua:433](../../Minimap/FluxMinimap.lua#L433) | `RegisterEvent` | `"EDIT_MODE_LAYOUTS_UPDATED"` |
| [Minimap/FluxMinimap.lua:804](../../Minimap/FluxMinimap.lua#L804) | `RegisterEvent` | `"UPDATE_PENDING_MAIL"` |
| [Minimap/FluxMinimap.lua:805](../../Minimap/FluxMinimap.lua#L805) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:1196](../../Minimap/FluxMinimap.lua#L1196) | `RegisterEvent` | `"UPDATE_BATTLEFIELD_STATUS"` |
| [Minimap/FluxMinimap.lua:1197](../../Minimap/FluxMinimap.lua#L1197) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:1198](../../Minimap/FluxMinimap.lua#L1198) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimap.lua:1199](../../Minimap/FluxMinimap.lua#L1199) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [Minimap/FluxMinimap.lua:1200](../../Minimap/FluxMinimap.lua#L1200) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [Minimap/FluxMinimap.lua:1201](../../Minimap/FluxMinimap.lua#L1201) | `RegisterEvent` | `"EDIT_MODE_LAYOUTS_UPDATED"` |
| [Minimap/FluxMinimap.lua:1202](../../Minimap/FluxMinimap.lua#L1202) | `RegisterEvent` | `"PVPQUEUE_ANYWHERE_SHOW"` |
| [Minimap/FluxMinimap.lua:1203](../../Minimap/FluxMinimap.lua#L1203) | `RegisterEvent` | `"PVPQUEUE_ANYWHERE_UPDATE_AVAILABLE"` |
| [Minimap/FluxMinimap.lua:1899](../../Minimap/FluxMinimap.lua#L1899) | `RegisterEvent` | `"ZONE_CHANGED"` |
| [Minimap/FluxMinimap.lua:1900](../../Minimap/FluxMinimap.lua#L1900) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [Minimap/FluxMinimap.lua:1901](../../Minimap/FluxMinimap.lua#L1901) | `RegisterEvent` | `"ZONE_CHANGED_INDOORS"` |
| [Minimap/FluxMinimap.lua:1902](../../Minimap/FluxMinimap.lua#L1902) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:2276](../../Minimap/FluxMinimap.lua#L2276) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimap.lua:2471](../../Minimap/FluxMinimap.lua#L2471) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimapButtons.lua:407](../../Minimap/FluxMinimapButtons.lua#L407) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Minimap/FluxMinimapButtons.lua:428](../../Minimap/FluxMinimapButtons.lua#L428) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:240](../../Minimap/FluxObjectiveTrackerScroll.lua#L240) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:610](../../Minimap/FluxObjectiveTrackerScroll.lua#L610) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:1066](../../Minimap/FluxObjectiveTrackerScroll.lua#L1066) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:1284](../../Minimap/FluxObjectiveTrackerScroll.lua#L1284) | `RegisterEvent` | `"QUEST_LOG_UPDATE"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:1517](../../Minimap/FluxObjectiveTrackerScroll.lua#L1517) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Minimap/FluxQuestie.lua:9](../../Minimap/FluxQuestie.lua#L9) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Minimap/FluxQuestie.lua:10](../../Minimap/FluxQuestie.lua#L10) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxQuestie.lua:11](../../Minimap/FluxQuestie.lua#L11) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Minimap/FluxQuestie.lua:12](../../Minimap/FluxQuestie.lua#L12) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [NamePlates/ComboPoints.lua:137](../../NamePlates/ComboPoints.lua#L137) | `RegisterEvent` | `event` |
| [NamePlates/ComboPoints.lua:141](../../NamePlates/ComboPoints.lua#L141) | `RegisterUnitEvent` | `event, "player", "vehicle"` |
| [NamePlates/ComboPoints.lua:144](../../NamePlates/ComboPoints.lua#L144) | `RegisterUnitEvent` | `"UNIT_POWER_POINT_CHARGE", "player", "vehicle"` |
| [NamePlates/Core.lua:566](../../NamePlates/Core.lua#L566) | `RegisterEvent` | `"NAME_PLATE_UNIT_ADDED"` |
| [NamePlates/Core.lua:567](../../NamePlates/Core.lua#L567) | `RegisterEvent` | `"NAME_PLATE_UNIT_REMOVED"` |
| [NamePlates/Core.lua:568](../../NamePlates/Core.lua#L568) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [NamePlates/Core.lua:569](../../NamePlates/Core.lua#L569) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [NamePlates/Core.lua:570](../../NamePlates/Core.lua#L570) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [NamePlates/Core.lua:571](../../NamePlates/Core.lua#L571) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Other/FluxArenaFramePosition.lua:133](../../Other/FluxArenaFramePosition.lua#L133) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxArenaFramePosition.lua:134](../../Other/FluxArenaFramePosition.lua#L134) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxArenaFramePosition.lua:135](../../Other/FluxArenaFramePosition.lua#L135) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxArenaFramePosition.lua:136](../../Other/FluxArenaFramePosition.lua#L136) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Other/FluxBossFramePosition.lua:131](../../Other/FluxBossFramePosition.lua#L131) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxBossFramePosition.lua:132](../../Other/FluxBossFramePosition.lua#L132) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxBossFramePosition.lua:133](../../Other/FluxBossFramePosition.lua#L133) | `RegisterEvent` | `"INSTANCE_ENCOUNTER_ENGAGE_UNIT"` |
| [Other/FluxBossFramePosition.lua:134](../../Other/FluxBossFramePosition.lua#L134) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxChatColumnMicros.lua:608](../../Other/FluxChatColumnMicros.lua#L608) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Other/FluxChatColumnMicros.lua:609](../../Other/FluxChatColumnMicros.lua#L609) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxChatColumnMicros.lua:610](../../Other/FluxChatColumnMicros.lua#L610) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatColumnMicros.lua:856](../../Other/FluxChatColumnMicros.lua#L856) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatColumnMicros.lua:857](../../Other/FluxChatColumnMicros.lua#L857) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Other/FluxChatColumnMicros.lua:858](../../Other/FluxChatColumnMicros.lua#L858) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Other/FluxChatColumnMicros.lua:1011](../../Other/FluxChatColumnMicros.lua#L1011) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Other/FluxChatColumnMicros.lua:1058](../../Other/FluxChatColumnMicros.lua#L1058) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxChatColumnMicros.lua:1059](../../Other/FluxChatColumnMicros.lua#L1059) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatColumnMicros.lua:1184](../../Other/FluxChatColumnMicros.lua#L1184) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxChatColumnMicros.lua:1185](../../Other/FluxChatColumnMicros.lua#L1185) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatColumnMicros.lua:1238](../../Other/FluxChatColumnMicros.lua#L1238) | `RegisterEvent` | `"UPDATE_INVENTORY_DURABILITY"` |
| [Other/FluxChatColumnMicros.lua:1239](../../Other/FluxChatColumnMicros.lua#L1239) | `RegisterEvent` | `"UPDATE_INVENTORY_ALERTS"` |
| [Other/FluxChatColumnMicros.lua:1240](../../Other/FluxChatColumnMicros.lua#L1240) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatColumnMicros.lua:1241](../../Other/FluxChatColumnMicros.lua#L1241) | `RegisterEvent` | `"UNIT_PORTRAIT_UPDATE"` |
| [Other/FluxChatColumnMicros.lua:1242](../../Other/FluxChatColumnMicros.lua#L1242) | `RegisterEvent` | `"PORTRAITS_UPDATED"` |
| [Other/FluxChatCopyPaste.lua:611](../../Other/FluxChatCopyPaste.lua#L611) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxChatCopyPaste.lua:972](../../Other/FluxChatCopyPaste.lua#L972) | `RegisterEvent` | `"GUILD_ROSTER_UPDATE"` |
| [Other/FluxChatCopyPaste.lua:973](../../Other/FluxChatCopyPaste.lua#L973) | `RegisterEvent` | `"PLAYER_GUILD_UPDATE"` |
| [Other/FluxChatCopyPaste.lua:974](../../Other/FluxChatCopyPaste.lua#L974) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatCopyPaste.lua:1116](../../Other/FluxChatCopyPaste.lua#L1116) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxChatCopyPaste.lua:1117](../../Other/FluxChatCopyPaste.lua#L1117) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatCopyPaste.lua:1118](../../Other/FluxChatCopyPaste.lua#L1118) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxChatCopyPaste.lua:1286](../../Other/FluxChatCopyPaste.lua#L1286) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Other/FluxChatFrame.lua:1403](../../Other/FluxChatFrame.lua#L1403) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxChatFrame.lua:1404](../../Other/FluxChatFrame.lua#L1404) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatFrame.lua:1405](../../Other/FluxChatFrame.lua#L1405) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Other/FluxChatFrame.lua:1406](../../Other/FluxChatFrame.lua#L1406) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxDurationBars.lua:101](../../Other/FluxDurationBars.lua#L101) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxDurationBars.lua:102](../../Other/FluxDurationBars.lua#L102) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxDurationBars.lua:103](../../Other/FluxDurationBars.lua#L103) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Other/FluxExtraAbilityHUD.lua:209](../../Other/FluxExtraAbilityHUD.lua#L209) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxHUDTooltip.lua:124](../../Other/FluxHUDTooltip.lua#L124) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxLootRollPosition.lua:40](../../Other/FluxLootRollPosition.lua#L40) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxLootRollPosition.lua:84](../../Other/FluxLootRollPosition.lua#L84) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxLootRollPosition.lua:85](../../Other/FluxLootRollPosition.lua#L85) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxTalkingHead.lua:193](../../Other/FluxTalkingHead.lua#L193) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Other/FluxTalkingHead.lua:215](../../Other/FluxTalkingHead.lua#L215) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxTalkingHead.lua:216](../../Other/FluxTalkingHead.lua#L216) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxTradeFoodWater.lua:629](../../Other/FluxTradeFoodWater.lua#L629) | `RegisterEvent` | `"TRADE_SHOW"` |
| [Other/FluxTradeFoodWater.lua:630](../../Other/FluxTradeFoodWater.lua#L630) | `RegisterEvent` | `"TRADE_UPDATE"` |
| [Other/FluxTradeFoodWater.lua:631](../../Other/FluxTradeFoodWater.lua#L631) | `RegisterEvent` | `"TRADE_CLOSED"` |
| [Other/FluxTradeFoodWater.lua:633](../../Other/FluxTradeFoodWater.lua#L633) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Other/FluxTradeFoodWater.lua:634](../../Other/FluxTradeFoodWater.lua#L634) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [Other/FluxTradeFoodWater.lua:678](../../Other/FluxTradeFoodWater.lua#L678) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Other/FluxVehicleExitButton.lua:151](../../Other/FluxVehicleExitButton.lua#L151) | `RegisterEvent` | `"UPDATE_BONUS_ACTIONBAR"` |
| [Other/FluxVehicleExitButton.lua:152](../../Other/FluxVehicleExitButton.lua#L152) | `RegisterEvent` | `"UPDATE_MULTI_CAST_ACTIONBAR"` |
| [Other/FluxVehicleExitButton.lua:153](../../Other/FluxVehicleExitButton.lua#L153) | `RegisterEvent` | `"UPDATE_OVERRIDE_ACTIONBAR"` |
| [Other/FluxVehicleExitButton.lua:154](../../Other/FluxVehicleExitButton.lua#L154) | `RegisterEvent` | `"UNIT_ENTERED_VEHICLE"` |
| [Other/FluxVehicleExitButton.lua:155](../../Other/FluxVehicleExitButton.lua#L155) | `RegisterEvent` | `"UNIT_EXITED_VEHICLE"` |
| [Other/FluxVehicleExitButton.lua:156](../../Other/FluxVehicleExitButton.lua#L156) | `RegisterEvent` | `"VEHICLE_UPDATE"` |
| [Other/FluxVehicleExitButton.lua:157](../../Other/FluxVehicleExitButton.lua#L157) | `RegisterEvent` | `"PLAYER_CONTROL_GAINED"` |
| [Other/FluxVehicleExitButton.lua:158](../../Other/FluxVehicleExitButton.lua#L158) | `RegisterEvent` | `"PLAYER_CONTROL_LOST"` |
| [Other/FluxVehicleExitButton.lua:160](../../Other/FluxVehicleExitButton.lua#L160) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxVehicleExitButton.lua:161](../../Other/FluxVehicleExitButton.lua#L161) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [RaidFrame/FluxRaidFrame_BigDebuffs.lua:151](../../RaidFrame/FluxRaidFrame_BigDebuffs.lua#L151) | `RegisterEvent` | `"ADDON_LOADED"` |
| [RaidFrame/FluxRaidPreview.lua:730](../../RaidFrame/FluxRaidPreview.lua#L730) | `RegisterEvent` | `"CVAR_UPDATE"` |
| [RaidFrame/FluxRaidPreview.lua:749](../../RaidFrame/FluxRaidPreview.lua#L749) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [RaidFrame/FluxRaidPreview.lua:750](../../RaidFrame/FluxRaidPreview.lua#L750) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [RaidFrame/FluxRaidPreview.lua:751](../../RaidFrame/FluxRaidPreview.lua#L751) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [RaidFrame/FluxRaidUnit.lua:64](../../RaidFrame/FluxRaidUnit.lua#L64) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Respec/FluxRespec_ActionBars.lua:544](../../Respec/FluxRespec_ActionBars.lua#L544) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:403](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L403) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:404](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L404) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:405](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L405) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:406](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L406) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_START", "player"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:407](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L407) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:408](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L408) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_STOP", "player"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:409](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L409) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_INTERRUPTED", "player"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:410](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L410) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_FAILED", "player"` |
| [Respec/FluxRespec_Core.lua:726](../../Respec/FluxRespec_Core.lua#L726) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Respec/FluxRespec_Core.lua:727](../../Respec/FluxRespec_Core.lua#L727) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_Core.lua:851](../../Respec/FluxRespec_Core.lua#L851) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [Respec/FluxRespec_Core.lua:854](../../Respec/FluxRespec_Core.lua#L854) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Respec/FluxRespec_Core.lua:855](../../Respec/FluxRespec_Core.lua#L855) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [Respec/FluxRespec_Core.lua:856](../../Respec/FluxRespec_Core.lua#L856) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Respec/FluxRespec_Core.lua:857](../../Respec/FluxRespec_Core.lua#L857) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Respec/FluxRespec_Core.lua:891](../../Respec/FluxRespec_Core.lua#L891) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_Equipment.lua:1665](../../Respec/FluxRespec_Equipment.lua#L1665) | `RegisterEvent` | `"ITEM_LOCK_CHANGED"` |
| [Respec/FluxRespec_Equipment.lua:1666](../../Respec/FluxRespec_Equipment.lua#L1666) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Respec/FluxRespec_Equipment.lua:1667](../../Respec/FluxRespec_Equipment.lua#L1667) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Respec/FluxRespec_Equipment.lua:1747](../../Respec/FluxRespec_Equipment.lua#L1747) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Respec/FluxRespec_EquipmentPresets.lua:365](../../Respec/FluxRespec_EquipmentPresets.lua#L365) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Respec/FluxRespec_EquipmentPresets.lua:366](../../Respec/FluxRespec_EquipmentPresets.lua#L366) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_EquipmentSets.lua:639](../../Respec/FluxRespec_EquipmentSets.lua#L639) | `RegisterEvent` | `"EQUIPMENT_SWAP_FINISHED"` |
| [Respec/FluxRespec_EquipmentSets.lua:960](../../Respec/FluxRespec_EquipmentSets.lua#L960) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_EquipmentSets.lua:961](../../Respec/FluxRespec_EquipmentSets.lua#L961) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Respec/FluxRespec_EquipmentSets.lua:962](../../Respec/FluxRespec_EquipmentSets.lua#L962) | `RegisterEvent` | `"EQUIPMENT_SETS_CHANGED"` |
| [Respec/FluxRespec_GearSetEquipGuard.lua:252](../../Respec/FluxRespec_GearSetEquipGuard.lua#L252) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_GearSetIndex.lua:701](../../Respec/FluxRespec_GearSetIndex.lua#L701) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_GearSetLock.lua:722](../../Respec/FluxRespec_GearSetLock.lua#L722) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_GearSetLock.lua:725](../../Respec/FluxRespec_GearSetLock.lua#L725) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [Respec/FluxRespec_GearSetLock.lua:726](../../Respec/FluxRespec_GearSetLock.lua#L726) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [Respec/FluxRespec_GearSetLock.lua:727](../../Respec/FluxRespec_GearSetLock.lua#L727) | `RegisterEvent` | `"SPELL_UPDATE_USABLE"` |
| [Respec/FluxRespec_GearSetLock.lua:728](../../Respec/FluxRespec_GearSetLock.lua#L728) | `RegisterEvent` | `"CURRENT_SPELL_CAST_CHANGED"` |
| [Respec/FluxRespec_GearSetLock.lua:730](../../Respec/FluxRespec_GearSetLock.lua#L730) | `RegisterEvent` | `"UNIT_SPELLCAST_SENT"` |
| [Respec/FluxRespec_GearSetOverlay.lua:215](../../Respec/FluxRespec_GearSetOverlay.lua#L215) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_GearSetTooltip.lua:319](../../Respec/FluxRespec_GearSetTooltip.lua#L319) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_IconPicker.lua:475](../../Respec/FluxRespec_IconPicker.lua#L475) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Respec/FluxRespec_Register.lua:38](../../Respec/FluxRespec_Register.lua#L38) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_Register.lua:39](../../Respec/FluxRespec_Register.lua#L39) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Respec/FluxRespec_RunePresets.lua:678](../../Respec/FluxRespec_RunePresets.lua#L678) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Respec/FluxRespec_RunePresets.lua:679](../../Respec/FluxRespec_RunePresets.lua#L679) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_Runes.lua:19](../../Respec/FluxRespec_Runes.lua#L19) | `RegisterEvent` | `"RUNE_UPDATED"` |
| [Respec/FluxRespec_Runes.lua:266](../../Respec/FluxRespec_Runes.lua#L266) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Respec/FluxRespec_Runes.lua:268](../../Respec/FluxRespec_Runes.lua#L268) | `RegisterEvent` | `"UNIT_SPELLCAST_SUCCEEDED"` |
| [Respec/FluxRespec_Talents.lua:644](../../Respec/FluxRespec_Talents.lua#L644) | `RegisterEvent` | `"CHARACTER_POINTS_CHANGED"` |
| [Respec/FluxRespec_Talents.lua:645](../../Respec/FluxRespec_Talents.lua#L645) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Respec/FluxRespec_Talents.lua:749](../../Respec/FluxRespec_Talents.lua#L749) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Respec/FluxRespec_Talents.lua:750](../../Respec/FluxRespec_Talents.lua#L750) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [Respec/FluxRespec_Talents.lua:1404](../../Respec/FluxRespec_Talents.lua#L1404) | `RegisterEvent` | `"GOSSIP_SHOW"` |
| [Respec/FluxRespec_Talents.lua:1405](../../Respec/FluxRespec_Talents.lua#L1405) | `RegisterEvent` | `"GOSSIP_CLOSED"` |
| [Respec/FluxRespec_Talents.lua:1406](../../Respec/FluxRespec_Talents.lua#L1406) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Respec/FluxRespec_Talents.lua:1407](../../Respec/FluxRespec_Talents.lua#L1407) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Respec/FluxRespec_Talents.lua:1408](../../Respec/FluxRespec_Talents.lua#L1408) | `RegisterEvent` | `"GOSSIP_CONFIRM"` |
| [Respec/FluxRespec_Talents.lua:1409](../../Respec/FluxRespec_Talents.lua#L1409) | `RegisterEvent` | `"CONFIRM_TALENT_WIPE"` |
| [Respec/FluxRespec_TalentsRetail.lua:532](../../Respec/FluxRespec_TalentsRetail.lua#L532) | `RegisterEvent` | `"TRAIT_CONFIG_UPDATED"` |
| [Respec/FluxRespec_TalentsRetail.lua:593](../../Respec/FluxRespec_TalentsRetail.lua#L593) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [Respec/FluxRespec_UI.lua:3114](../../Respec/FluxRespec_UI.lua#L3114) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Respec/FluxRespec_UI.lua:3115](../../Respec/FluxRespec_UI.lua#L3115) | `RegisterEvent` | `"CHARACTER_POINTS_CHANGED"` |
| [Respec/FluxRespec_UI.lua:3116](../../Respec/FluxRespec_UI.lua#L3116) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Respec/FluxRespec_UI.lua:3117](../../Respec/FluxRespec_UI.lua#L3117) | `RegisterEvent` | `"ACTIONBAR_SLOT_CHANGED"` |
| [Respec/FluxRespec_UI.lua:3118](../../Respec/FluxRespec_UI.lua#L3118) | `RegisterEvent` | `"PET_BAR_UPDATE"` |
| [Respec/FluxRespec_UI.lua:3119](../../Respec/FluxRespec_UI.lua#L3119) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [Respec/FluxRespec_UI.lua:3120](../../Respec/FluxRespec_UI.lua#L3120) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Respec/FluxRespec_UI.lua:3126](../../Respec/FluxRespec_UI.lua#L3126) | `RegisterEvent` | `"RUNE_UPDATED"` |
| [Respec/FluxRespec_UI.lua:3129](../../Respec/FluxRespec_UI.lua#L3129) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Respec/FluxRespec_UI.lua:3130](../../Respec/FluxRespec_UI.lua#L3130) | `RegisterEvent` | `"BANKFRAME_OPENED"` |
| [Respec/FluxRespec_UI.lua:3131](../../Respec/FluxRespec_UI.lua#L3131) | `RegisterEvent` | `"BANKFRAME_CLOSED"` |
| [Respec/FluxRespec_UI.lua:3132](../../Respec/FluxRespec_UI.lua#L3132) | `RegisterEvent` | `"GET_ITEM_INFO_RECEIVED"` |
| [Respec/FluxRespec_UI.lua:3133](../../Respec/FluxRespec_UI.lua#L3133) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [Respec/FluxRespec_UI.lua:3134](../../Respec/FluxRespec_UI.lua#L3134) | `RegisterEvent` | `"TRAIT_CONFIG_UPDATED"` |
| [Respec/FluxRespec_UI.lua:3139](../../Respec/FluxRespec_UI.lua#L3139) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Salvage/FluxSalvage.lua:46](../../Salvage/FluxSalvage.lua#L46) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Salvage/FluxSalvage.lua:47](../../Salvage/FluxSalvage.lua#L47) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [Salvage/FluxSalvage.lua:48](../../Salvage/FluxSalvage.lua#L48) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [Salvage/FluxSalvage.lua:49](../../Salvage/FluxSalvage.lua#L49) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Salvage/FluxSalvage_Overlay.lua:66](../../Salvage/FluxSalvage_Overlay.lua#L66) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Salvage/FluxSalvage_Overlay.lua:824](../../Salvage/FluxSalvage_Overlay.lua#L824) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Salvage/FluxSalvage_Overlay.lua:825](../../Salvage/FluxSalvage_Overlay.lua#L825) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [StatusBars/FluxGoldLedger.lua:1343](../../StatusBars/FluxGoldLedger.lua#L1343) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [StatusBars/FluxGoldLedger.lua:1344](../../StatusBars/FluxGoldLedger.lua#L1344) | `RegisterEvent` | `"PLAYER_LOGOUT"` |
| [StatusBars/FluxGoldLedger.lua:1345](../../StatusBars/FluxGoldLedger.lua#L1345) | `RegisterEvent` | `"ADDON_LOADED"` |
| [StatusBars/FluxGoldLedger.lua:1415](../../StatusBars/FluxGoldLedger.lua#L1415) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [StatusBars/FluxInfoFrame.lua:4776](../../StatusBars/FluxInfoFrame.lua#L4776) | `RegisterEvent` | `"ZONE_CHANGED"` |
| [StatusBars/FluxInfoFrame.lua:4777](../../StatusBars/FluxInfoFrame.lua#L4777) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [StatusBars/FluxInfoFrame.lua:4778](../../StatusBars/FluxInfoFrame.lua#L4778) | `RegisterEvent` | `"PLAYER_UPDATE_RESTING"` |
| [StatusBars/FluxInfoFrame.lua:4779](../../StatusBars/FluxInfoFrame.lua#L4779) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [StatusBars/FluxInfoFrame.lua:4780](../../StatusBars/FluxInfoFrame.lua#L4780) | `RegisterEvent` | `"UPDATE_INVENTORY_ALERTS"` |
| [StatusBars/FluxInfoFrame.lua:4781](../../StatusBars/FluxInfoFrame.lua#L4781) | `RegisterUnitEvent` | `"UNIT_AURA", "player"` |
| [StatusBars/FluxInfoFrame.lua:4782](../../StatusBars/FluxInfoFrame.lua#L4782) | `RegisterEvent` | `"COMBAT_RATING_UPDATE"` |
| [StatusBars/FluxInfoFrame.lua:4783](../../StatusBars/FluxInfoFrame.lua#L4783) | `RegisterEvent` | `"MASTERY_UPDATE"` |
| [StatusBars/FluxInfoFrame.lua:4784](../../StatusBars/FluxInfoFrame.lua#L4784) | `RegisterEvent` | `"SPELL_POWER_CHANGED"` |
| [StatusBars/FluxInfoFrame.lua:4785](../../StatusBars/FluxInfoFrame.lua#L4785) | `RegisterUnitEvent` | `"UNIT_STATS", "player"` |
| [StatusBars/FluxInfoFrame.lua:4786](../../StatusBars/FluxInfoFrame.lua#L4786) | `RegisterEvent` | `"PLAYER_DAMAGE_DONE_MODS"` |
| [StatusBars/FluxInfoFrame.lua:4788](../../StatusBars/FluxInfoFrame.lua#L4788) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [StatusBars/FluxInfoFrame.lua:4789](../../StatusBars/FluxInfoFrame.lua#L4789) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [StatusBars/FluxInfoFrame.lua:4790](../../StatusBars/FluxInfoFrame.lua#L4790) | `RegisterUnitEvent` | `"UNIT_SPELL_HASTE", "player"` |
| [StatusBars/FluxInfoFrame.lua:5045](../../StatusBars/FluxInfoFrame.lua#L5045) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [StatusBars/FluxInfoFrame.lua:5046](../../StatusBars/FluxInfoFrame.lua#L5046) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [StatusBars/FluxItemCurrencyTracking.lua:906](../../StatusBars/FluxItemCurrencyTracking.lua#L906) | `RegisterEvent` | `"GET_ITEM_INFO_RECEIVED"` |
| [StatusBars/FluxItemCurrencyTracking.lua:909](../../StatusBars/FluxItemCurrencyTracking.lua#L909) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [StatusBars/FluxItemCurrencyTracking.lua:912](../../StatusBars/FluxItemCurrencyTracking.lua#L912) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [StatusBars/FluxItemCurrencyTracking.lua:956](../../StatusBars/FluxItemCurrencyTracking.lua#L956) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [StatusBars/FluxPVPObjectiveMover.lua:329](../../StatusBars/FluxPVPObjectiveMover.lua#L329) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [StatusBars/FluxPVPObjectiveMover.lua:330](../../StatusBars/FluxPVPObjectiveMover.lua#L330) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [StatusBars/FluxPVPObjectiveMover.lua:331](../../StatusBars/FluxPVPObjectiveMover.lua#L331) | `RegisterEvent` | `"UPDATE_UI_WIDGET"` |
| [StatusBars/FluxPVPObjectiveMover.lua:336](../../StatusBars/FluxPVPObjectiveMover.lua#L336) | `RegisterEvent` | `"UPDATE_UI_WIDGET"` |
| [StatusBars/FluxPVPTracking.lua:370](../../StatusBars/FluxPVPTracking.lua#L370) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [StatusBars/FluxPVPTracking.lua:371](../../StatusBars/FluxPVPTracking.lua#L371) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [StatusBars/FluxPVPTracking.lua:372](../../StatusBars/FluxPVPTracking.lua#L372) | `RegisterEvent` | `"ADDON_LOADED"` |
| [StatusBars/FluxStatusBar.lua:2569](../../StatusBars/FluxStatusBar.lua#L2569) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [StatusBars/FluxStatusBar.lua:2950](../../StatusBars/FluxStatusBar.lua#L2950) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [StatusBars/FluxStatusBar.lua:2951](../../StatusBars/FluxStatusBar.lua#L2951) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [StatusBars/FluxStatusBar.lua:2952](../../StatusBars/FluxStatusBar.lua#L2952) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [StatusBars/FluxStatusBar.lua:2953](../../StatusBars/FluxStatusBar.lua#L2953) | `RegisterEvent` | `"ADDON_LOADED"` |
| [StatusBars/FluxStatusBar.lua:2954](../../StatusBars/FluxStatusBar.lua#L2954) | `RegisterEvent` | `"PLAYER_XP_UPDATE"` |
| [StatusBars/FluxStatusBar.lua:2955](../../StatusBars/FluxStatusBar.lua#L2955) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [StatusBars/FluxStatusBar.lua:2956](../../StatusBars/FluxStatusBar.lua#L2956) | `RegisterEvent` | `"UPDATE_EXHAUSTION"` |
| [StatusBars/FluxStatusBar.lua:2957](../../StatusBars/FluxStatusBar.lua#L2957) | `RegisterEvent` | `"PLAYER_UPDATE_RESTING"` |
| [StatusBars/FluxStatusBar.lua:2958](../../StatusBars/FluxStatusBar.lua#L2958) | `RegisterEvent` | `"UPDATE_FACTION"` |
| [StatusBars/FluxStatusBar.lua:2959](../../StatusBars/FluxStatusBar.lua#L2959) | `RegisterEvent` | `"QUEST_LOG_UPDATE"` |
| [StatusBars/FluxStatusBar.lua:2960](../../StatusBars/FluxStatusBar.lua#L2960) | `RegisterEvent` | `"PLAYER_MONEY"` |
| [StatusBars/FluxStatusBar.lua:2961](../../StatusBars/FluxStatusBar.lua#L2961) | `RegisterEvent` | `"CURRENCY_DISPLAY_UPDATE"` |
| [StatusBars/FluxStatusBar.lua:2962](../../StatusBars/FluxStatusBar.lua#L2962) | `RegisterEvent` | `"UPDATE_INVENTORY_ALERTS"` |
| [UnitFrames/FluxCastBar.lua:2863](../../UnitFrames/FluxCastBar.lua#L2863) | `RegisterUnitEvent` | `event, unit` |
| [UnitFrames/FluxCastBar.lua:2896](../../UnitFrames/FluxCastBar.lua#L2896) | `RegisterEvent` | `"UNIT_SPELLCAST_SENT"` |
| [UnitFrames/FluxCastBar.lua:3466](../../UnitFrames/FluxCastBar.lua#L3466) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [UnitFrames/FluxCastBar.lua:3467](../../UnitFrames/FluxCastBar.lua#L3467) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxCastBarThemes.lua:892](../../UnitFrames/FluxCastBarThemes.lua#L892) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [UnitFrames/FluxCastBarThemes.lua:893](../../UnitFrames/FluxCastBarThemes.lua#L893) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxClassPower.lua:631](../../UnitFrames/FluxClassPower.lua#L631) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxClassPower.lua:632](../../UnitFrames/FluxClassPower.lua#L632) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [UnitFrames/FluxClassPower.lua:633](../../UnitFrames/FluxClassPower.lua#L633) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [UnitFrames/FluxClassPower.lua:634](../../UnitFrames/FluxClassPower.lua#L634) | `RegisterEvent` | `"UNIT_DISPLAYPOWER"` |
| [UnitFrames/FluxClassPower.lua:635](../../UnitFrames/FluxClassPower.lua#L635) | `RegisterEvent` | `"UNIT_POWER_UPDATE"` |
| [UnitFrames/FluxClassPower.lua:636](../../UnitFrames/FluxClassPower.lua#L636) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [UnitFrames/FluxClassPower.lua:637](../../UnitFrames/FluxClassPower.lua#L637) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxClassPower.lua:638](../../UnitFrames/FluxClassPower.lua#L638) | `RegisterEvent` | `"PLAYER_TOTEM_UPDATE"` |
| [UnitFrames/FluxClassPower.lua:639](../../UnitFrames/FluxClassPower.lua#L639) | `RegisterEvent` | `"RUNE_POWER_UPDATE"` |
| [UnitFrames/FluxFlightPath.lua:551](../../UnitFrames/FluxFlightPath.lua#L551) | `RegisterEvent` | `"TAXIMAP_OPENED"` |
| [UnitFrames/FluxFlightPath.lua:552](../../UnitFrames/FluxFlightPath.lua#L552) | `RegisterEvent` | `"PLAYER_CONTROL_LOST"` |
| [UnitFrames/FluxFlightPath.lua:553](../../UnitFrames/FluxFlightPath.lua#L553) | `RegisterEvent` | `"PLAYER_CONTROL_GAINED"` |
| [UnitFrames/FluxForeverComboPoints.lua:121](../../UnitFrames/FluxForeverComboPoints.lua#L121) | `RegisterEvent` | `event` |
| [UnitFrames/FluxForeverComboPoints.lua:125](../../UnitFrames/FluxForeverComboPoints.lua#L125) | `RegisterUnitEvent` | `event, "player", "vehicle"` |
| [UnitFrames/FluxLegacyComboPoints.lua:165](../../UnitFrames/FluxLegacyComboPoints.lua#L165) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxLegacyComboPoints.lua:166](../../UnitFrames/FluxLegacyComboPoints.lua#L166) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxLegacyComboPoints.lua:167](../../UnitFrames/FluxLegacyComboPoints.lua#L167) | `RegisterEvent` | `"COMBO_TARGET_CHANGED"` |
| [UnitFrames/FluxLegacyComboPoints.lua:168](../../UnitFrames/FluxLegacyComboPoints.lua#L168) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [UnitFrames/FluxLegacyComboPoints.lua:169](../../UnitFrames/FluxLegacyComboPoints.lua#L169) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxLegacyComboPoints.lua:170](../../UnitFrames/FluxLegacyComboPoints.lua#L170) | `RegisterEvent` | `"UNIT_ENTERED_VEHICLE"` |
| [UnitFrames/FluxLegacyComboPoints.lua:171](../../UnitFrames/FluxLegacyComboPoints.lua#L171) | `RegisterEvent` | `"UNIT_EXITED_VEHICLE"` |
| [UnitFrames/FluxLegacyComboPoints.lua:174](../../UnitFrames/FluxLegacyComboPoints.lua#L174) | `RegisterUnitEvent` | `"UNIT_POWER_FREQUENT", "player", "vehicle"` |
| [UnitFrames/FluxLegacyComboPoints.lua:175](../../UnitFrames/FluxLegacyComboPoints.lua#L175) | `RegisterUnitEvent` | `"UNIT_POWER_UPDATE", "player", "vehicle"` |
| [UnitFrames/FluxLegacyComboPoints.lua:176](../../UnitFrames/FluxLegacyComboPoints.lua#L176) | `RegisterUnitEvent` | `"UNIT_MAXPOWER", "player", "vehicle"` |
| [UnitFrames/FluxLegacyComboPoints.lua:178](../../UnitFrames/FluxLegacyComboPoints.lua#L178) | `RegisterEvent` | `"UNIT_POWER_FREQUENT"` |
| [UnitFrames/FluxLegacyComboPoints.lua:179](../../UnitFrames/FluxLegacyComboPoints.lua#L179) | `RegisterEvent` | `"UNIT_POWER_UPDATE"` |
| [UnitFrames/FluxLegacyComboPoints.lua:180](../../UnitFrames/FluxLegacyComboPoints.lua#L180) | `RegisterEvent` | `"UNIT_MAXPOWER"` |
| [UnitFrames/FluxMP5Overlay.lua:340](../../UnitFrames/FluxMP5Overlay.lua#L340) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [UnitFrames/FluxMP5Overlay.lua:341](../../UnitFrames/FluxMP5Overlay.lua#L341) | `RegisterUnitEvent` | `"UNIT_POWER_UPDATE", "player"` |
| [UnitFrames/FluxMP5Overlay.lua:342](../../UnitFrames/FluxMP5Overlay.lua#L342) | `RegisterUnitEvent` | `"UNIT_POWER_FREQUENT", "player"` |
| [UnitFrames/FluxMP5Overlay.lua:343](../../UnitFrames/FluxMP5Overlay.lua#L343) | `RegisterUnitEvent` | `"UNIT_DISPLAYPOWER", "player"` |
| [UnitFrames/FluxMP5Overlay.lua:344](../../UnitFrames/FluxMP5Overlay.lua#L344) | `RegisterUnitEvent` | `"UNIT_MAXPOWER", "player"` |
| [UnitFrames/FluxMP5Overlay.lua:345](../../UnitFrames/FluxMP5Overlay.lua#L345) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxMP5Overlay.lua:346](../../UnitFrames/FluxMP5Overlay.lua#L346) | `RegisterEvent` | `"PLAYER_ALIVE"` |
| [UnitFrames/FluxMP5Overlay.lua:347](../../UnitFrames/FluxMP5Overlay.lua#L347) | `RegisterEvent` | `"PLAYER_UNGHOST"` |
| [UnitFrames/FluxPowerCostOverlay.lua:793](../../UnitFrames/FluxPowerCostOverlay.lua#L793) | `RegisterUnitEvent` | `event, unit` |
| [UnitFrames/FluxPowerCostOverlay.lua:948](../../UnitFrames/FluxPowerCostOverlay.lua#L948) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxPowerCostOverlay.lua:951](../../UnitFrames/FluxPowerCostOverlay.lua#L951) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxSwingTimer.lua:1717](../../UnitFrames/FluxSwingTimer.lua#L1717) | `RegisterEvent` | `"COMBAT_LOG_EVENT_UNFILTERED"` |
| [UnitFrames/FluxSwingTimer.lua:2017](../../UnitFrames/FluxSwingTimer.lua#L2017) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxSwingTimer.lua:2018](../../UnitFrames/FluxSwingTimer.lua#L2018) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxSwingTimer.lua:2020](../../UnitFrames/FluxSwingTimer.lua#L2020) | `RegisterEvent` | `"PLAYER_ENTER_COMBAT"` |
| [UnitFrames/FluxSwingTimer.lua:2023](../../UnitFrames/FluxSwingTimer.lua#L2023) | `RegisterEvent` | `"PLAYER_LEAVE_COMBAT"` |
| [UnitFrames/FluxSwingTimer.lua:2025](../../UnitFrames/FluxSwingTimer.lua#L2025) | `RegisterEvent` | `"UNIT_INVENTORY_CHANGED"` |
| [UnitFrames/FluxSwingTimer.lua:2026](../../UnitFrames/FluxSwingTimer.lua#L2026) | `RegisterEvent` | `"START_AUTOREPEAT_SPELL"` |
| [UnitFrames/FluxSwingTimer.lua:2027](../../UnitFrames/FluxSwingTimer.lua#L2027) | `RegisterEvent` | `"STOP_AUTOREPEAT_SPELL"` |
| [UnitFrames/FluxSwingTimer.lua:2028](../../UnitFrames/FluxSwingTimer.lua#L2028) | `RegisterEvent` | `"UNIT_SPELLCAST_SUCCEEDED"` |
| [UnitFrames/FluxSwingTimer.lua:2029](../../UnitFrames/FluxSwingTimer.lua#L2029) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxSwingTimer.lua:2031](../../UnitFrames/FluxSwingTimer.lua#L2031) | `RegisterUnitEvent` | `"UNIT_ATTACK_SPEED", "player"` |
| [UnitFrames/FluxSwingTimer.lua:2034](../../UnitFrames/FluxSwingTimer.lua#L2034) | `RegisterUnitEvent` | `"UNIT_COMBAT", "target"` |
| [UnitFrames/FluxSwingTimer.lua:2038](../../UnitFrames/FluxSwingTimer.lua#L2038) | `RegisterEvent` | `"PLAYER_SWING"` |
| [UnitFrames/FluxSwingTimer.lua:2041](../../UnitFrames/FluxSwingTimer.lua#L2041) | `RegisterEvent` | `"PLAYER_SWING_RANGE_UPDATE"` |
| [UnitFrames/FluxSwingTimer.lua:2044](../../UnitFrames/FluxSwingTimer.lua#L2044) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxSwingTimer.lua:2047](../../UnitFrames/FluxSwingTimer.lua#L2047) | `RegisterEvent` | `"WEAPON_SLOT_CHANGED"` |
| [UnitFrames/FluxSwingTimer.lua:2050](../../UnitFrames/FluxSwingTimer.lua#L2050) | `RegisterEvent` | `"ADDON_LOADED"` |
| [UnitFrames/FluxSwingTimer.lua:2066](../../UnitFrames/FluxSwingTimer.lua#L2066) | `RegisterEvent` | `"ADDON_RESTRICTION_STATE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2187](../../UnitFrames/FluxUnitFrames_Auras.lua#L2187) | `RegisterUnitEvent` | `"UNIT_AURA", frame.unit` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2188](../../UnitFrames/FluxUnitFrames_Auras.lua#L2188) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2189](../../UnitFrames/FluxUnitFrames_Auras.lua#L2189) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2190](../../UnitFrames/FluxUnitFrames_Auras.lua#L2190) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2192](../../UnitFrames/FluxUnitFrames_Auras.lua#L2192) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2194](../../UnitFrames/FluxUnitFrames_Auras.lua#L2194) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2239](../../UnitFrames/FluxUnitFrames_Auras.lua#L2239) | `RegisterEvent` | `"PLAYER_LOGOUT"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2296](../../UnitFrames/FluxUnitFrames_Auras.lua#L2296) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2297](../../UnitFrames/FluxUnitFrames_Auras.lua#L2297) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2298](../../UnitFrames/FluxUnitFrames_Auras.lua#L2298) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2299](../../UnitFrames/FluxUnitFrames_Auras.lua#L2299) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:279](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L279) | `RegisterUnitEvent` | `event, unpack(registration, 2)` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:281](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L281) | `RegisterEvent` | `event` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:374](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L374) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:375](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L375) | `RegisterEvent` | `"UNIT_ENTERED_VEHICLE"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:376](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L376) | `RegisterEvent` | `"UNIT_EXITED_VEHICLE"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:632](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L632) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:633](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L633) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:634](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L634) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:635](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L635) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:636](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L636) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_Focus.lua:180](../../UnitFrames/FluxUnitFrames_Focus.lua#L180) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Focus.lua:181](../../UnitFrames/FluxUnitFrames_Focus.lua#L181) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:124](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L124) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:125](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L125) | `RegisterEvent` | `"UNIT_TARGET"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:126](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L126) | `RegisterEvent` | `"UNIT_NAME_UPDATE"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:137](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L137) | `RegisterUnitEvent` | `"UNIT_HEALTH", "focustarget"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:138](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L138) | `RegisterUnitEvent` | `"UNIT_MAXHEALTH", "focustarget"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:169](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L169) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:170](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L170) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Pet.lua:189](../../UnitFrames/FluxUnitFrames_Pet.lua#L189) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_Pet.lua:190](../../UnitFrames/FluxUnitFrames_Pet.lua#L190) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:607](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L607) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:608](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L608) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:609](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L609) | `RegisterUnitEvent` | `"UNIT_AURA", "pet"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:611](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L611) | `RegisterEvent` | `"UNIT_AURA"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:132](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L132) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:194](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L194) | `RegisterUnitEvent` | `"UNIT_HEALTH", "pettarget"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:195](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L195) | `RegisterUnitEvent` | `"UNIT_MAXHEALTH", "pettarget"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:196](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L196) | `RegisterUnitEvent` | `"UNIT_TARGET", "pet"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:197](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L197) | `RegisterUnitEvent` | `"UNIT_PET", "player"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:198](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L198) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:199](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L199) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1027](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1027) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1028](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1028) | `RegisterEvent` | `"BANKFRAME_OPENED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1029](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1029) | `RegisterEvent` | `"BANKFRAME_CLOSED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1182](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1182) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1183](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1183) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1184](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1184) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1185](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1185) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1186](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1186) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:172](../../UnitFrames/FluxUnitFrames_Shared.lua#L172) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:173](../../UnitFrames/FluxUnitFrames_Shared.lua#L173) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:174](../../UnitFrames/FluxUnitFrames_Shared.lua#L174) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:1112](../../UnitFrames/FluxUnitFrames_Shared.lua#L1112) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:4191](../../UnitFrames/FluxUnitFrames_Shared.lua#L4191) | `RegisterUnitEvent` | `"UNIT_TARGET", "player"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:4193](../../UnitFrames/FluxUnitFrames_Shared.lua#L4193) | `RegisterEvent` | `"UNIT_TARGET"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:4857](../../UnitFrames/FluxUnitFrames_Shared.lua#L4857) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:4858](../../UnitFrames/FluxUnitFrames_Shared.lua#L4858) | `RegisterEvent` | `"PLAYER_FLAGS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:4892](../../UnitFrames/FluxUnitFrames_Shared.lua#L4892) | `RegisterEvent` | `"RAID_TARGET_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:6048](../../UnitFrames/FluxUnitFrames_Shared.lua#L6048) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8075](../../UnitFrames/FluxUnitFrames_Shared.lua#L8075) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8104](../../UnitFrames/FluxUnitFrames_Shared.lua#L8104) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8604](../../UnitFrames/FluxUnitFrames_Shared.lua#L8604) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8605](../../UnitFrames/FluxUnitFrames_Shared.lua#L8605) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8606](../../UnitFrames/FluxUnitFrames_Shared.lua#L8606) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8607](../../UnitFrames/FluxUnitFrames_Shared.lua#L8607) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8671](../../UnitFrames/FluxUnitFrames_Shared.lua#L8671) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8672](../../UnitFrames/FluxUnitFrames_Shared.lua#L8672) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8673](../../UnitFrames/FluxUnitFrames_Shared.lua#L8673) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8674](../../UnitFrames/FluxUnitFrames_Shared.lua#L8674) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8675](../../UnitFrames/FluxUnitFrames_Shared.lua#L8675) | `RegisterUnitEvent` | `"UNIT_HEALTH", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8676](../../UnitFrames/FluxUnitFrames_Shared.lua#L8676) | `RegisterUnitEvent` | `"UNIT_MAXHEALTH", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8677](../../UnitFrames/FluxUnitFrames_Shared.lua#L8677) | `RegisterUnitEvent` | `"UNIT_POWER_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8678](../../UnitFrames/FluxUnitFrames_Shared.lua#L8678) | `RegisterUnitEvent` | `"UNIT_MAXPOWER", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8679](../../UnitFrames/FluxUnitFrames_Shared.lua#L8679) | `RegisterUnitEvent` | `"UNIT_DISPLAYPOWER", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8687](../../UnitFrames/FluxUnitFrames_Shared.lua#L8687) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8688](../../UnitFrames/FluxUnitFrames_Shared.lua#L8688) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8692](../../UnitFrames/FluxUnitFrames_Shared.lua#L8692) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8694](../../UnitFrames/FluxUnitFrames_Shared.lua#L8694) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8695](../../UnitFrames/FluxUnitFrames_Shared.lua#L8695) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8696](../../UnitFrames/FluxUnitFrames_Shared.lua#L8696) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8697](../../UnitFrames/FluxUnitFrames_Shared.lua#L8697) | `RegisterEvent` | `"UNIT_THREAT_LIST_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8699](../../UnitFrames/FluxUnitFrames_Shared.lua#L8699) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8700](../../UnitFrames/FluxUnitFrames_Shared.lua#L8700) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8701](../../UnitFrames/FluxUnitFrames_Shared.lua#L8701) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8704](../../UnitFrames/FluxUnitFrames_Shared.lua#L8704) | `RegisterUnitEvent` | `"UNIT_TARGET", "target"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8709](../../UnitFrames/FluxUnitFrames_Shared.lua#L8709) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8710](../../UnitFrames/FluxUnitFrames_Shared.lua#L8710) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8715](../../UnitFrames/FluxUnitFrames_Shared.lua#L8715) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8717](../../UnitFrames/FluxUnitFrames_Shared.lua#L8717) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8719](../../UnitFrames/FluxUnitFrames_Shared.lua#L8719) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8720](../../UnitFrames/FluxUnitFrames_Shared.lua#L8720) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8721](../../UnitFrames/FluxUnitFrames_Shared.lua#L8721) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8722](../../UnitFrames/FluxUnitFrames_Shared.lua#L8722) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8723](../../UnitFrames/FluxUnitFrames_Shared.lua#L8723) | `RegisterEvent` | `"UNIT_THREAT_LIST_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8725](../../UnitFrames/FluxUnitFrames_Shared.lua#L8725) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8729](../../UnitFrames/FluxUnitFrames_Shared.lua#L8729) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8731](../../UnitFrames/FluxUnitFrames_Shared.lua#L8731) | `RegisterUnitEvent` | `"UNIT_TARGET", "focus"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8732](../../UnitFrames/FluxUnitFrames_Shared.lua#L8732) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8734](../../UnitFrames/FluxUnitFrames_Shared.lua#L8734) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8735](../../UnitFrames/FluxUnitFrames_Shared.lua#L8735) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8738](../../UnitFrames/FluxUnitFrames_Shared.lua#L8738) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8743](../../UnitFrames/FluxUnitFrames_Shared.lua#L8743) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", "player", "pet"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8747](../../UnitFrames/FluxUnitFrames_Shared.lua#L8747) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8748](../../UnitFrames/FluxUnitFrames_Shared.lua#L8748) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8749](../../UnitFrames/FluxUnitFrames_Shared.lua#L8749) | `RegisterEvent` | `"PLAYER_FLAGS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8753](../../UnitFrames/FluxUnitFrames_Shared.lua#L8753) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8754](../../UnitFrames/FluxUnitFrames_Shared.lua#L8754) | `RegisterEvent` | `"RAID_ROSTER_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8755](../../UnitFrames/FluxUnitFrames_Shared.lua#L8755) | `RegisterEvent` | `"PARTY_LEADER_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8759](../../UnitFrames/FluxUnitFrames_Shared.lua#L8759) | `RegisterEvent` | `"PARTY_LOOT_METHOD_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8763](../../UnitFrames/FluxUnitFrames_Shared.lua#L8763) | `RegisterUnitEvent` | `"UNIT_FACTION", frame.unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8764](../../UnitFrames/FluxUnitFrames_Shared.lua#L8764) | `RegisterUnitEvent` | `"PLAYER_FLAGS_CHANGED", frame.unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8768](../../UnitFrames/FluxUnitFrames_Shared.lua#L8768) | `RegisterEvent` | `"ZONE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8769](../../UnitFrames/FluxUnitFrames_Shared.lua#L8769) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8770](../../UnitFrames/FluxUnitFrames_Shared.lua#L8770) | `RegisterEvent` | `"ZONE_CHANGED_INDOORS"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8771](../../UnitFrames/FluxUnitFrames_Shared.lua#L8771) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8902](../../UnitFrames/FluxUnitFrames_Shared.lua#L8902) | `RegisterEvent` | `"CVAR_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Target.lua:13](../../UnitFrames/FluxUnitFrames_Target.lua#L13) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Target.lua:14](../../UnitFrames/FluxUnitFrames_Target.lua#L14) | `RegisterEvent` | `"UNIT_HEALTH"` |
| [UnitFrames/FluxUnitFrames_Target.lua:16](../../UnitFrames/FluxUnitFrames_Target.lua#L16) | `RegisterEvent` | `"UNIT_LEVEL"` |
| [UnitFrames/FluxUnitFrames_Target.lua:18](../../UnitFrames/FluxUnitFrames_Target.lua#L18) | `RegisterEvent` | `"UNIT_FACTION"` |
| [UnitFrames/FluxUnitFrames_Target.lua:20](../../UnitFrames/FluxUnitFrames_Target.lua#L20) | `RegisterEvent` | `"UNIT_CLASSIFICATION_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Target.lua:23](../../UnitFrames/FluxUnitFrames_Target.lua#L23) | `RegisterEvent` | `"PLAYER_FLAGS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Target.lua:25](../../UnitFrames/FluxUnitFrames_Target.lua#L25) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Target.lua:26](../../UnitFrames/FluxUnitFrames_Target.lua#L26) | `RegisterEvent` | `"RAID_TARGET_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Target.lua:28](../../UnitFrames/FluxUnitFrames_Target.lua#L28) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Target.lua:29](../../UnitFrames/FluxUnitFrames_Target.lua#L29) | `RegisterUnitEvent` | `"UNIT_AURA", unit` |
| [UnitFrames/FluxUnitFrames_Target.lua:30](../../UnitFrames/FluxUnitFrames_Target.lua#L30) | `RegisterUnitEvent` | `"UNIT_TARGET", unit` |
| [UnitFrames/FluxUnitFrames_Target.lua:33](../../UnitFrames/FluxUnitFrames_Target.lua#L33) | `RegisterUnitEvent` | `"UNIT_TARGETABLE_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Target.lua:61](../../UnitFrames/FluxUnitFrames_Target.lua#L61) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Target.lua:62](../../UnitFrames/FluxUnitFrames_Target.lua#L62) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Target.lua:306](../../UnitFrames/FluxUnitFrames_Target.lua#L306) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Target.lua:307](../../UnitFrames/FluxUnitFrames_Target.lua#L307) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Target.lua:308](../../UnitFrames/FluxUnitFrames_Target.lua#L308) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_TargetOfTarget.lua:120](../../UnitFrames/FluxUnitFrames_TargetOfTarget.lua#L120) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [WindowMover/Engine.lua:965](../../WindowMover/Engine.lua#L965) | `RegisterEvent` | `"ADDON_LOADED"` |
| [WindowMover/Engine.lua:966](../../WindowMover/Engine.lua#L966) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |

## Declared interface candidates

Each source heading links back to its owning chapter. Use search for a particular method; use the chapter to understand its lifecycle and data invariants.

### AddonOptions/AceGUIWidget-FluxExtraButtonVisibility.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `_G.FluxExtraButtonVisibilityPanel_OnOptionsClosed` | [L366](../../AddonOptions/AceGUIWidget-FluxExtraButtonVisibility.lua#L366) |

### AddonOptions/AceGUIWidget-FluxInfoStatOrder.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `_G.FluxInfoStatOrder_RequestRefresh` | [L279](../../AddonOptions/AceGUIWidget-FluxInfoStatOrder.lua#L279) |

### AddonOptions/AceGUIWidget-FluxItemCurrencySlots.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `_G.FluxItemCurrencyTrackingifFthenF._RefreshSlotsUIFromAce` | [L566](../../AddonOptions/AceGUIWidget-FluxItemCurrencySlots.lua#L566) |

### AddonOptions/AceGUIWidget-FluxNCFlyoutPanel.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `_G.FluxNCFlyoutPanel_RequestRefresh` | [L1061](../../AddonOptions/AceGUIWidget-FluxNCFlyoutPanel.lua#L1061) |
| `_G.FluxNCFlyoutPanel_OnOptionsClosed` | [L1072](../../AddonOptions/AceGUIWidget-FluxNCFlyoutPanel.lua#L1072) |

### AddonOptions/AceGUIWidget-FluxRestockPanel.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `_G.FluxRestockPanel_OnOptionsClosed` | [L308](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L308) |
| `SchedulePanelRebuild` | [L351](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L351) |
| `ConfirmResetTierReference` | [L952](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L952) |
| `ScheduleBagCellRefresh` | [L2368](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2368) |
| `_G.FluxRestockPanel_RequestRefresh` | [L2561](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2561) |
| `_G.FluxRestockPanel_OnSpellReagentCacheReady` | [L2569](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2569) |
| `_G.FluxRestockPanel_IsTabVisible` | [L2579](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2579) |
| `_G.FluxRestockPanel_IsActive` | [L2583](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2583) |
| `_G.FluxRestockPanel_RefreshMerchantAvailability` | [L2587](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2587) |
| `_G.FluxRestockPanel_RefreshJunkLists` | [L2596](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2596) |
| `_G.FluxRestockPanel_RefreshCellData` | [L2603](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2603) |

### AddonOptions/AceGUIWidget-FluxSpellBlacklistPanel.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `_G.FluxSpellBlacklistPanel_OnOptionsClosed` | [L595](../../AddonOptions/AceGUIWidget-FluxSpellBlacklistPanel.lua#L595) |

### AddonOptions/AceGUIWidget-FluxSpellBookSlotsPanel.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `trueendself._refreshHandler` | [L382](../../AddonOptions/AceGUIWidget-FluxSpellBookSlotsPanel.lua#L382) |
| `_G.FluxSpellBookSlotsPanel_OnOptionsClosed` | [L478](../../AddonOptions/AceGUIWidget-FluxSpellBookSlotsPanel.lua#L478) |

### AddonOptions/AceGUIWidget-FluxStanceBarOrderPanel.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `_G.FluxStanceBarOrderPanel_RequestRefresh` | [L845](../../AddonOptions/AceGUIWidget-FluxStanceBarOrderPanel.lua#L845) |
| `_G.FluxStanceBarOrderPanel_OnOptionsClosed` | [L856](../../AddonOptions/AceGUIWidget-FluxStanceBarOrderPanel.lua#L856) |

### AddonOptions/FluxLayoutPreviewUI.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `UI:DrawPreview` | [L1118](../../AddonOptions/FluxLayoutPreviewUI.lua#L1118) |
| `UI:OnPreviewFrameResize` | [L1451](../../AddonOptions/FluxLayoutPreviewUI.lua#L1451) |
| `UI:AttachToAceWidget` | [L1458](../../AddonOptions/FluxLayoutPreviewUI.lua#L1458) |
| `UI:DetachFromAceWidget` | [L1528](../../AddonOptions/FluxLayoutPreviewUI.lua#L1528) |
| `_G.FluxLayoutPreviewUI_OnOptionsClosed` | [L1561](../../AddonOptions/FluxLayoutPreviewUI.lua#L1561) |

### AddonOptions/FluxOptions.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `FluxOptions:IsOptionsUIReady` | [L78](../../AddonOptions/FluxOptions.lua#L78) |
| `FluxOptions:EnsureOptionsUI` | [L83](../../AddonOptions/FluxOptions.lua#L83) |
| `FluxOptions:GetModuleGen` | [L91](../../AddonOptions/FluxOptions.lua#L91) |
| `FluxOptions:ResolveModuleOptions` | [L96](../../AddonOptions/FluxOptions.lua#L96) |
| `FluxOptions:GetProfilesOptions` | [L115](../../AddonOptions/FluxOptions.lua#L115) |
| `FluxOptions:RefreshOpenPage` | [L122](../../AddonOptions/FluxOptions.lua#L122) |
| `FluxOptions:RegisterModuleOptions` | [L134](../../AddonOptions/FluxOptions.lua#L134) |
| `FluxOptions:GetDB` | [L149](../../AddonOptions/FluxOptions.lua#L149) |
| `FluxOptions:GetCharacterProfileName` | [L158](../../AddonOptions/FluxOptions.lua#L158) |
| `FluxOptions:IsCharacterProfileNameReady` | [L173](../../AddonOptions/FluxOptions.lua#L173) |
| `FluxOptions:EnforceProfileForLogin` | [L184](../../AddonOptions/FluxOptions.lua#L184) |
| `FluxOptions:IsCharacterSpecific` | [L225](../../AddonOptions/FluxOptions.lua#L225) |
| `FluxOptions:SetCharacterSpecific` | [L230](../../AddonOptions/FluxOptions.lua#L230) |
| `FluxOptions:IsActionbarsCharacterSpecific` | [L282](../../AddonOptions/FluxOptions.lua#L282) |
| `FluxOptions:GetActionbarsDB` | [L290](../../AddonOptions/FluxOptions.lua#L290) |
| `FluxOptions:SetActionbarsCharacterSpecific` | [L308](../../AddonOptions/FluxOptions.lua#L308) |
| `FluxOptions:RefreshActionbarsScopedModules` | [L349](../../AddonOptions/FluxOptions.lua#L349) |
| `FluxOptions:RefreshActionbarsAfterProfileChange` | [L390](../../AddonOptions/FluxOptions.lua#L390) |
| `FluxOptions:MigrateMicroMenuSettingsScopeFromLayoutOnce` | [L413](../../AddonOptions/FluxOptions.lua#L413) |
| `FluxOptions:IsMicroMenuSettingsCharacterSpecific` | [L427](../../AddonOptions/FluxOptions.lua#L427) |
| `FluxOptions:IsMicroMenuLayoutCharacterSpecific` | [L436](../../AddonOptions/FluxOptions.lua#L436) |
| `FluxOptions:GetMicroMenuDB` | [L440](../../AddonOptions/FluxOptions.lua#L440) |
| `FluxOptions:SetMicroMenuSettingsCharacterSpecific` | [L459](../../AddonOptions/FluxOptions.lua#L459) |
| `FluxOptions:SetMicroMenuLayoutCharacterSpecific` | [L493](../../AddonOptions/FluxOptions.lua#L493) |
| `FluxOptions:IsLayoutCharacterSpecific` | [L509](../../AddonOptions/FluxOptions.lua#L509) |
| `FluxOptions:GetLayoutDB` | [L517](../../AddonOptions/FluxOptions.lua#L517) |
| `FluxOptions:SetLayoutCharacterSpecific` | [L534](../../AddonOptions/FluxOptions.lua#L534) |
| `FluxOptions:ResetLayoutToDefaults` | [L563](../../AddonOptions/FluxOptions.lua#L563) |
| `FluxOptions:IsWindowMoverCharacterSpecific` | [L602](../../AddonOptions/FluxOptions.lua#L602) |
| `FluxOptions:GetWindowMoverDB` | [L610](../../AddonOptions/FluxOptions.lua#L610) |
| `FluxOptions:SetWindowMoverCharacterSpecific` | [L633](../../AddonOptions/FluxOptions.lua#L633) |
| `FluxOptions:ResetWindowMoverToDefaults` | [L661](../../AddonOptions/FluxOptions.lua#L661) |
| `FluxOptions:RefreshWindowMoverDependents` | [L682](../../AddonOptions/FluxOptions.lua#L682) |
| `FluxOptions:GetMicroMenuLayoutPosition` | [L691](../../AddonOptions/FluxOptions.lua#L691) |
| `FluxOptions:IsMicroMenuDetachedVerticalLayout` | [L707](../../AddonOptions/FluxOptions.lua#L707) |
| `FluxOptions:GetMicroMenuMinimapStripExpanded` | [L713](../../AddonOptions/FluxOptions.lua#L713) |
| `FluxOptions:SetMicroMenuMinimapStripExpanded` | [L719](../../AddonOptions/FluxOptions.lua#L719) |
| `FluxOptions:GetMicroMenuBesideChatColumns` | [L728](../../AddonOptions/FluxOptions.lua#L728) |
| `FluxOptions:GetInfoFramePlacement` | [L749](../../AddonOptions/FluxOptions.lua#L749) |
| `FluxOptions:GetInfoStatusSlot` | [L763](../../AddonOptions/FluxOptions.lua#L763) |
| `FluxOptions:GetStatusBarPosition` | [L773](../../AddonOptions/FluxOptions.lua#L773) |
| `FluxOptions:GetPlayerTargetPlacement` | [L789](../../AddonOptions/FluxOptions.lua#L789) |
| `FluxOptions:GetStanceBarPlacement` | [L802](../../AddonOptions/FluxOptions.lua#L802) |
| `FluxOptions:RefreshLayoutDependents` | [L821](../../AddonOptions/FluxOptions.lua#L821) |
| `FluxOptions:RefreshMicroMenuScopedModules` | [L825](../../AddonOptions/FluxOptions.lua#L825) |
| `FluxOptions:ResetMicroMenuLayoutToDefaults` | [L942](../../AddonOptions/FluxOptions.lua#L942) |
| `FluxOptions:RefreshMicroMenuAfterProfileChange` | [L959](../../AddonOptions/FluxOptions.lua#L959) |
| `FluxOptions:RefreshLayoutScopedModulesAfterProfileChange` | [L964](../../AddonOptions/FluxOptions.lua#L964) |
| `FluxOptions:IsRaidFramesCharacterSpecific` | [L985](../../AddonOptions/FluxOptions.lua#L985) |
| `FluxOptions:GetRaidFrameDB` | [L992](../../AddonOptions/FluxOptions.lua#L992) |
| `FluxOptions:SetRaidFrameCharacterSpecific` | [L1009](../../AddonOptions/FluxOptions.lua#L1009) |
| `FluxOptions:RefreshRaidFrameScopedModules` | [L1037](../../AddonOptions/FluxOptions.lua#L1037) |
| `FluxOptions:ResetRaidFramesToDefaults` | [L1047](../../AddonOptions/FluxOptions.lua#L1047) |
| `FluxOptions:RefreshRaidFramesAfterProfileChange` | [L1064](../../AddonOptions/FluxOptions.lua#L1064) |
| `FluxOptions:IsUnitFramesCharacterSpecific` | [L1085](../../AddonOptions/FluxOptions.lua#L1085) |
| `FluxOptions:GetUnitFrameDB` | [L1092](../../AddonOptions/FluxOptions.lua#L1092) |
| `FluxOptions:SetUnitFrameCharacterSpecific` | [L1109](../../AddonOptions/FluxOptions.lua#L1109) |
| `FluxOptions:RefreshUnitFrameScopedModules` | [L1137](../../AddonOptions/FluxOptions.lua#L1137) |
| `FluxOptions:ResetUnitFramesToDefaults` | [L1146](../../AddonOptions/FluxOptions.lua#L1146) |
| `FluxOptions:RefreshUnitFramesAfterProfileChange` | [L1163](../../AddonOptions/FluxOptions.lua#L1163) |
| `FluxOptions:GetItemCurrencyDB` | [L1189](../../AddonOptions/FluxOptions.lua#L1189) |
| `FluxOptions:IsStatusBarsCharacterSpecific` | [L1274](../../AddonOptions/FluxOptions.lua#L1274) |
| `FluxOptions:GetStatusBarSettingsDB` | [L1282](../../AddonOptions/FluxOptions.lua#L1282) |
| `FluxOptions:SetStatusBarsCharacterSpecific` | [L1299](../../AddonOptions/FluxOptions.lua#L1299) |
| `_G.FluxStatusBar_ScheduleActionStripAnchorSettle` | [L1359](../../AddonOptions/FluxOptions.lua#L1359) |
| `FluxOptions:RefreshStatusBarScopedModules` | [L1382](../../AddonOptions/FluxOptions.lua#L1382) |
| `FluxOptions:ResetStatusBarsToDefaults` | [L1386](../../AddonOptions/FluxOptions.lua#L1386) |
| `FluxOptions:RefreshStatusBarsAfterProfileChange` | [L1417](../../AddonOptions/FluxOptions.lua#L1417) |
| `FluxOptions:GetConfigStatusText` | [L1461](../../AddonOptions/FluxOptions.lua#L1461) |
| `FluxOptions_ApplyConfigWindowAppearance` | [L1466](../../AddonOptions/FluxOptions.lua#L1466) |
| `_G.FluxOptions_OnOptionsClosed` | [L1478](../../AddonOptions/FluxOptions.lua#L1478) |
| `FluxOptions:ShowConfig` | [L1510](../../AddonOptions/FluxOptions.lua#L1510) |
| `FluxOptions:ToggleConfig` | [L1520](../../AddonOptions/FluxOptions.lua#L1520) |
| `FluxOptions:CloseConfig` | [L1535](../../AddonOptions/FluxOptions.lua#L1535) |
| `FluxOptions:OpenToMicroMenuTab` | [L1543](../../AddonOptions/FluxOptions.lua#L1543) |
| `FluxOptions:OpenToVendorTab` | [L1548](../../AddonOptions/FluxOptions.lua#L1548) |
| `FluxOptions:OpenToSalvageTab` | [L1553](../../AddonOptions/FluxOptions.lua#L1553) |
| `FluxOptions:OpenToStatusBarsTab` | [L1558](../../AddonOptions/FluxOptions.lua#L1558) |
| `FluxOptions:OpenToBindingTab` | [L1563](../../AddonOptions/FluxOptions.lua#L1563) |
| `FluxOptions:OpenToRaidFrameTab` | [L1568](../../AddonOptions/FluxOptions.lua#L1568) |
| `FluxOptions:OpenToActionBarsTab` | [L1573](../../AddonOptions/FluxOptions.lua#L1573) |
| `FluxOptions:OpenToActionBarsBindingsTab` | [L1577](../../AddonOptions/FluxOptions.lua#L1577) |
| `FluxOptions:OpenToFluxWindowTab` | [L1582](../../AddonOptions/FluxOptions.lua#L1582) |
| `FluxOptions:OpenBlizzardOptions` | [L1588](../../AddonOptions/FluxOptions.lua#L1588) |
| `ACR:NotifyChange` | [L1743](../../AddonOptions/FluxOptions.lua#L1743) |
| `FluxOptions.EnsureSavedConfiguration` | [L1819](../../AddonOptions/FluxOptions.lua#L1819) |

### AddonOptions/FluxOptionsActionBars.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `AB.ActionbarsDB` | [L9](../../AddonOptions/FluxOptionsActionBars.lua#L9) |
| `AB.Notify` | [L16](../../AddonOptions/FluxOptionsActionBars.lua#L16) |
| `AB.RankSupported` | [L23](../../AddonOptions/FluxOptionsActionBars.lua#L23) |
| `AB.IsPreDF` | [L29](../../AddonOptions/FluxOptionsActionBars.lua#L29) |
| `AB.MouseoverCast` | [L39](../../AddonOptions/FluxOptionsActionBars.lua#L39) |

### AddonOptions/FluxOptionsActionBars_Bar.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `AB.GetBarGroup` | [L24](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L24) |

### AddonOptions/FluxOptionsActionBars_Bindings.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `AB.GetBindingsGroup` | [L5](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L5) |

### AddonOptions/FluxOptionsActionBars_Extra.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `AB.GetExtraGroup` | [L5](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L5) |

### AddonOptions/FluxOptionsActionBars_Stance.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `AB.GetStanceGroup` | [L5](../../AddonOptions/FluxOptionsActionBars_Stance.lua#L5) |

### AddonOptions/FluxOptionsRaidFrame.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `ns.FluxOptionsBuildPartyRaidTab` | [L47](../../AddonOptions/FluxOptionsRaidFrame.lua#L47) |

### AddonOptions/FluxOptionsRender.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `endrow.Refresh` | [L526](../../AddonOptions/FluxOptionsRender.lua#L526) |
| `endrow.Refresh` | [L629](../../AddonOptions/FluxOptionsRender.lua#L629) |
| `more.Refresh` | [L706](../../AddonOptions/FluxOptionsRender.lua#L706) |
| `R.ListSubpages` | [L750](../../AddonOptions/FluxOptionsRender.lua#L750) |
| `R.Build` | [L796](../../AddonOptions/FluxOptionsRender.lua#L796) |
| `page:ContentWidth` | [L813](../../AddonOptions/FluxOptionsRender.lua#L813) |
| `page:Layout` | [L823](../../AddonOptions/FluxOptionsRender.lua#L823) |
| `page:Refresh` | [L987](../../AddonOptions/FluxOptionsRender.lua#L987) |
| `page:SetQuery` | [L991](../../AddonOptions/FluxOptionsRender.lua#L991) |
| `page:SetActive` | [L996](../../AddonOptions/FluxOptionsRender.lua#L996) |
| `page:Release` | [L1030](../../AddonOptions/FluxOptionsRender.lua#L1030) |

### AddonOptions/FluxOptionsSalvage.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `_G.FluxOptionsSalvageGroup` | [L82](../../AddonOptions/FluxOptionsSalvage.lua#L82) |

### AddonOptions/FluxOptionsShell.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `Shell:IsShown` | [L46](../../AddonOptions/FluxOptionsShell.lua#L46) |
| `Shell:SetStatus` | [L50](../../AddonOptions/FluxOptionsShell.lua#L50) |
| `Shell:ApplyFluxBorder` | [L56](../../AddonOptions/FluxOptionsShell.lua#L56) |
| `Shell:ApplyAccent` | [L82](../../AddonOptions/FluxOptionsShell.lua#L82) |
| `Shell:PaintSelection` | [L91](../../AddonOptions/FluxOptionsShell.lua#L91) |
| `Shell:PaintTabs` | [L122](../../AddonOptions/FluxOptionsShell.lua#L122) |
| `Shell:ContentWidth` | [L153](../../AddonOptions/FluxOptionsShell.lua#L153) |
| `Shell:ViewHeight` | [L160](../../AddonOptions/FluxOptionsShell.lua#L160) |
| `Shell:ReleaseCache` | [L167](../../AddonOptions/FluxOptionsShell.lua#L167) |
| `Shell:OnHidden` | [L198](../../AddonOptions/FluxOptionsShell.lua#L198) |
| `Shell:Hide` | [L208](../../AddonOptions/FluxOptionsShell.lua#L208) |
| `Shell:Remember` | [L215](../../AddonOptions/FluxOptionsShell.lua#L215) |
| `Shell:ResolveGroup` | [L223](../../AddonOptions/FluxOptionsShell.lua#L223) |
| `Shell:SubpagesFor` | [L240](../../AddonOptions/FluxOptionsShell.lua#L240) |
| `Shell:Query` | [L251](../../AddonOptions/FluxOptionsShell.lua#L251) |
| `Shell:PageMatches` | [L258](../../AddonOptions/FluxOptionsShell.lua#L258) |
| `Shell:FilterSidebar` | [L283](../../AddonOptions/FluxOptionsShell.lua#L283) |
| `Shell:LayoutTabs` | [L330](../../AddonOptions/FluxOptionsShell.lua#L330) |
| `Shell:ShowPage` | [L406](../../AddonOptions/FluxOptionsShell.lua#L406) |
| `page.onLayout` | [L494](../../AddonOptions/FluxOptionsShell.lua#L494) |
| `Shell:Select` | [L517](../../AddonOptions/FluxOptionsShell.lua#L517) |
| `Shell:RefreshOpenPageNow` | [L528](../../AddonOptions/FluxOptionsShell.lua#L528) |
| `Shell:RefreshOpenPage` | [L554](../../AddonOptions/FluxOptionsShell.lua#L554) |
| `Shell:Relayout` | [L570](../../AddonOptions/FluxOptionsShell.lua#L570) |
| `Shell:BuildSidebar` | [L580](../../AddonOptions/FluxOptionsShell.lua#L580) |
| `Shell:EnsureFrame` | [L800](../../AddonOptions/FluxOptionsShell.lua#L800) |
| `Shell:Show` | [L1063](../../AddonOptions/FluxOptionsShell.lua#L1063) |
| `Shell:Open` | [L1085](../../AddonOptions/FluxOptionsShell.lua#L1085) |

### AddonOptions/FluxOptionsUnitFrames.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `opt.set` | [L306](../../AddonOptions/FluxOptionsUnitFrames.lua#L306) |

### AddonOptions/FluxOptionsWidgets.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `W.Solid` | [L24](../../AddonOptions/FluxOptionsWidgets.lua#L24) |
| `W.Accent` | [L28](../../AddonOptions/FluxOptionsWidgets.lua#L28) |
| `W.OnAccent` | [L36](../../AddonOptions/FluxOptionsWidgets.lua#L36) |
| `W.RefreshAccent` | [L42](../../AddonOptions/FluxOptionsWidgets.lua#L42) |
| `W.HasAtlas` | [L48](../../AddonOptions/FluxOptionsWidgets.lua#L48) |
| `W.ApplyBackdrop` | [L75](../../AddonOptions/FluxOptionsWidgets.lua#L75) |
| `W.HideTooltip` | [L89](../../AddonOptions/FluxOptionsWidgets.lua#L89) |
| `W.ShowTooltip` | [L95](../../AddonOptions/FluxOptionsWidgets.lua#L95) |
| `W.CreateRow` | [L117](../../AddonOptions/FluxOptionsWidgets.lua#L117) |
| `W.PaintStripe` | [L127](../../AddonOptions/FluxOptionsWidgets.lua#L127) |
| `W.CreateHeader` | [L138](../../AddonOptions/FluxOptionsWidgets.lua#L138) |
| `textrow.SetLabel` | [L152](../../AddonOptions/FluxOptionsWidgets.lua#L152) |
| `W.CreateDescription` | [L158](../../AddonOptions/FluxOptionsWidgets.lua#L158) |
| `textrow.SetBody` | [L167](../../AddonOptions/FluxOptionsWidgets.lua#L167) |
| `endrow.LayoutHeight` | [L178](../../AddonOptions/FluxOptionsWidgets.lua#L178) |
| `W.CreateToggle` | [L204](../../AddonOptions/FluxOptionsWidgets.lua#L204) |
| `row.SetLabel` | [L255](../../AddonOptions/FluxOptionsWidgets.lua#L255) |
| `endrow.SetDescription` | [L259](../../AddonOptions/FluxOptionsWidgets.lua#L259) |
| `endrow.SetValue` | [L262](../../AddonOptions/FluxOptionsWidgets.lua#L262) |
| `endrow.GetValue` | [L266](../../AddonOptions/FluxOptionsWidgets.lua#L266) |
| `returnvalueendrow.SetDisabled` | [L269](../../AddonOptions/FluxOptionsWidgets.lua#L269) |
| `endrow.SetOnChange` | [L274](../../AddonOptions/FluxOptionsWidgets.lua#L274) |
| `W.CloseDropdown` | [L302](../../AddonOptions/FluxOptionsWidgets.lua#L302) |
| `W.CreateDropdown` | [L331](../../AddonOptions/FluxOptionsWidgets.lua#L331) |
| `item.valueinfo.func` | [L469](../../AddonOptions/FluxOptionsWidgets.lua#L469) |
| `row.SetLabel` | [L487](../../AddonOptions/FluxOptionsWidgets.lua#L487) |
| `endrow.SetDescription` | [L491](../../AddonOptions/FluxOptionsWidgets.lua#L491) |
| `endrow.SetGetter` | [L494](../../AddonOptions/FluxOptionsWidgets.lua#L494) |
| `endrow.SetValue` | [L498](../../AddonOptions/FluxOptionsWidgets.lua#L498) |
| `endrow.SetDisabled` | [L502](../../AddonOptions/FluxOptionsWidgets.lua#L502) |
| `endrow.SetOnChange` | [L506](../../AddonOptions/FluxOptionsWidgets.lua#L506) |
| `W.CreateSlider` | [L530](../../AddonOptions/FluxOptionsWidgets.lua#L530) |
| `row.SetLabel` | [L603](../../AddonOptions/FluxOptionsWidgets.lua#L603) |
| `endrow.SetDescription` | [L607](../../AddonOptions/FluxOptionsWidgets.lua#L607) |
| `endrow.Configure` | [L610](../../AddonOptions/FluxOptionsWidgets.lua#L610) |
| `endrow.SetValue` | [L629](../../AddonOptions/FluxOptionsWidgets.lua#L629) |
| `endrow.SetDisabled` | [L638](../../AddonOptions/FluxOptionsWidgets.lua#L638) |
| `endrow.SetOnChange` | [L643](../../AddonOptions/FluxOptionsWidgets.lua#L643) |
| `fnendrow.SetOnCommit` | [L646](../../AddonOptions/FluxOptionsWidgets.lua#L646) |
| `W.CreateColor` | [L655](../../AddonOptions/FluxOptionsWidgets.lua#L655) |
| `hasAlphaandtrueorfalseColorPickerFrame.func` | [L726](../../AddonOptions/FluxOptionsWidgets.lua#L726) |
| `endColorPickerFrame.cancelFunc` | [L730](../../AddonOptions/FluxOptionsWidgets.lua#L730) |
| `row.SetLabel` | [L745](../../AddonOptions/FluxOptionsWidgets.lua#L745) |
| `endrow.SetDescription` | [L749](../../AddonOptions/FluxOptionsWidgets.lua#L749) |
| `endrow.SetHasAlpha` | [L752](../../AddonOptions/FluxOptionsWidgets.lua#L752) |
| `vandtrueorfalseendrow.SetValue` | [L755](../../AddonOptions/FluxOptionsWidgets.lua#L755) |
| `endrow.SetDisabled` | [L762](../../AddonOptions/FluxOptionsWidgets.lua#L762) |
| `endrow.SetOnChange` | [L767](../../AddonOptions/FluxOptionsWidgets.lua#L767) |
| `W.CreateButton` | [L774](../../AddonOptions/FluxOptionsWidgets.lua#L774) |
| `row.SetLabel` | [L821](../../AddonOptions/FluxOptionsWidgets.lua#L821) |
| `endrow.SetButtonText` | [L825](../../AddonOptions/FluxOptionsWidgets.lua#L825) |
| `endrow.SetDescription` | [L829](../../AddonOptions/FluxOptionsWidgets.lua#L829) |
| `endrow.SetDisabled` | [L832](../../AddonOptions/FluxOptionsWidgets.lua#L832) |
| `endrow.SetOnClick` | [L837](../../AddonOptions/FluxOptionsWidgets.lua#L837) |
| `W.CreateInput` | [L843](../../AddonOptions/FluxOptionsWidgets.lua#L843) |
| `row.SetLabel` | [L883](../../AddonOptions/FluxOptionsWidgets.lua#L883) |
| `endrow.SetDescription` | [L887](../../AddonOptions/FluxOptionsWidgets.lua#L887) |
| `endrow.SetValue` | [L890](../../AddonOptions/FluxOptionsWidgets.lua#L890) |
| `endrow.SetDisabled` | [L893](../../AddonOptions/FluxOptionsWidgets.lua#L893) |
| `endrow.SetOnCommit` | [L899](../../AddonOptions/FluxOptionsWidgets.lua#L899) |
| `W.CreateMoreButton` | [L905](../../AddonOptions/FluxOptionsWidgets.lua#L905) |
| `endrow.SetOpen` | [L915](../../AddonOptions/FluxOptionsWidgets.lua#L915) |
| `row.SetOnClick` | [L925](../../AddonOptions/FluxOptionsWidgets.lua#L925) |
| `W.CreateScroll` | [L933](../../AddonOptions/FluxOptionsWidgets.lua#L933) |
| `api:SetContentHeight` | [L985](../../AddonOptions/FluxOptionsWidgets.lua#L985) |
| `api:GetContentWidth` | [L997](../../AddonOptions/FluxOptionsWidgets.lua#L997) |
| `api:GetViewHeight` | [L1004](../../AddonOptions/FluxOptionsWidgets.lua#L1004) |
| `api:ResetScroll` | [L1007](../../AddonOptions/FluxOptionsWidgets.lua#L1007) |

### BaganatorCompat/FluxBaganator_BankRestock.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.ForEachBaganatorBankView` | [L44](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L44) |
| `Compat.GetActiveBaganatorBankView` | [L85](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L85) |
| `Compat.SyncBaganatorBankLive` | [L107](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L107) |
| `Compat.AttachBankRestockButton` | [L132](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L132) |
| `bankView.UpdateTransferButtonbankView.UpdateTransferButton` | [L152](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L152) |
| `bankView.OnTabFinishedbankView.OnTabFinished` | [L162](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L162) |
| `Compat.FinalizeBankRestock` | [L216](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L216) |
| `Compat.InitBankRestock` | [L222](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L222) |

### BaganatorCompat/FluxBaganator_CategoryIcons.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `origfontString.GetUnboundedStringWidth` | [L65](../../BaganatorCompat/FluxBaganator_CategoryIcons.lua#L65) |
| `Compat.ApplyCategoryLabelIcon` | [L129](../../BaganatorCompat/FluxBaganator_CategoryIcons.lua#L129) |
| `label.SetWidthlabel.SetWidth` | [L174](../../BaganatorCompat/FluxBaganator_CategoryIcons.lua#L174) |
| `Compat.InitCategoryIcons` | [L221](../../BaganatorCompat/FluxBaganator_CategoryIcons.lua#L221) |

### BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.FilterProtectedVendorMatches` | [L16](../../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua#L16) |
| `view.RunActionview.RunAction` | [L94](../../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua#L94) |
| `view.Transferview.Transfer` | [L107](../../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua#L107) |
| `view.TransferCategoryview.TransferCategory` | [L120](../../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua#L120) |
| `mixin.OnClickmixin.OnClick` | [L137](../../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua#L137) |
| `mixin.OnEntermixin.OnEnter` | [L147](../../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua#L147) |
| `mixin.OnLeavemixin.OnLeave` | [L161](../../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua#L161) |
| `Compat.WrapExistingBaganatorViews` | [L214](../../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua#L214) |
| `Compat.RefreshFluxCategoryLabels` | [L218](../../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua#L218) |
| `Compat.InitCategoryVendorBlock` | [L222](../../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua#L222) |

### BaganatorCompat/FluxBaganator_ConsumablesCategories.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.SyncConsumablesCategories` | [L228](../../BaganatorCompat/FluxBaganator_ConsumablesCategories.lua#L228) |
| `Compat.InitConsumablesCategories` | [L372](../../BaganatorCompat/FluxBaganator_ConsumablesCategories.lua#L372) |

### BaganatorCompat/FluxBaganator_EquipmentSetSection.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.EnsureEquipmentSetSection` | [L144](../../BaganatorCompat/FluxBaganator_EquipmentSetSection.lua#L144) |
| `Compat.InitEquipmentSetSection` | [L189](../../BaganatorCompat/FluxBaganator_EquipmentSetSection.lua#L189) |

### BaganatorCompat/FluxBaganator_GearSetContext.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.ShouldFadeProtectedGearSetAtVendor` | [L40](../../BaganatorCompat/FluxBaganator_GearSetContext.lua#L40) |
| `Compat.InstallBaganatorItemContextOverride` | [L77](../../BaganatorCompat/FluxBaganator_GearSetContext.lua#L77) |
| `button.GetItemContextMatchResultbutton.GetItemContextMatchResult` | [L84](../../BaganatorCompat/FluxBaganator_GearSetContext.lua#L84) |
| `Compat.InitGearSetContext` | [L101](../../BaganatorCompat/FluxBaganator_GearSetContext.lua#L101) |

### BaganatorCompat/FluxBaganator_GearSets.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.GetCategoryIcon` | [L58](../../BaganatorCompat/FluxBaganator_GearSets.lua#L58) |
| `Compat.IsFluxManagedSetName` | [L65](../../BaganatorCompat/FluxBaganator_GearSets.lua#L65) |
| `Compat.IsFluxRespecCategorySourceKey` | [L72](../../BaganatorCompat/FluxBaganator_GearSets.lua#L72) |
| `Compat.RebuildGearSetInfo` | [L374](../../BaganatorCompat/FluxBaganator_GearSets.lua#L374) |
| `Compat.InitGearSets` | [L503](../../BaganatorCompat/FluxBaganator_GearSets.lua#L503) |

### BaganatorCompat/FluxBaganator_GearSetShield.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.RefreshShieldOnBaganatorButton` | [L86](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L86) |
| `Compat.RefreshVisibleGearSetShields` | [L90](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L90) |
| `Compat.RequestGearSetShieldRefresh` | [L100](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L100) |
| `Compat.ConfigureBaganatorGearSetCorners` | [L154](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L154) |
| `Compat.InitGearSetShield` | [L196](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L196) |

### BaganatorCompat/FluxBaganator_ItemViews.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.TrackBaganatorView` | [L16](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L16) |
| `Compat.ForEachVisibleBaganatorView` | [L22](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L22) |
| `Compat.ResolveBaganatorItemButtonSlot` | [L48](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L48) |
| `Compat.ForEachRegisteredBaganatorItemButton` | [L95](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L95) |
| `Compat.ForEachBaganatorItemButton` | [L120](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L120) |
| `Compat.ForEachVisibleItemButton` | [L210](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L210) |
| `Compat.InitBaganatorViewTracking` | [L233](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L233) |

### BaganatorCompat/FluxBaganator_Junk.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.RequestBaganatorRefresh` | [L25](../../BaganatorCompat/FluxBaganator_Junk.lua#L25) |
| `Compat.InitJunk` | [L63](../../BaganatorCompat/FluxBaganator_Junk.lua#L63) |

### BaganatorCompat/FluxBaganator_Protection.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.InvalidateBaganatorProtectionCache` | [L57](../../BaganatorCompat/FluxBaganator_Protection.lua#L57) |
| `Compat.InstallBaganatorItemButtonProtection` | [L168](../../BaganatorCompat/FluxBaganator_Protection.lua#L168) |
| `Compat.InstallBaganatorItemButtonListeners` | [L184](../../BaganatorCompat/FluxBaganator_Protection.lua#L184) |
| `Compat.RefreshBaganatorClickGuards` | [L221](../../BaganatorCompat/FluxBaganator_Protection.lua#L221) |
| `Compat.RefreshBaganatorGearSetProtection` | [L227](../../BaganatorCompat/FluxBaganator_Protection.lua#L227) |
| `Compat.RequestBaganatorProtectionRefresh` | [L235](../../BaganatorCompat/FluxBaganator_Protection.lua#L235) |
| `_G.SellCursorItem_G.SellCursorItem` | [L257](../../BaganatorCompat/FluxBaganator_Protection.lua#L257) |
| `Compat.FinalizeBaganatorIntegration` | [L285](../../BaganatorCompat/FluxBaganator_Protection.lua#L285) |
| `Compat.InitProtection` | [L296](../../BaganatorCompat/FluxBaganator_Protection.lua#L296) |

### BaganatorCompat/Loader.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.Init` | [L16](../../BaganatorCompat/Loader.lua#L16) |

### Bars/BadgeHost.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `BadgeHost.SetSlotBadges` | [L741](../../Bars/BadgeHost.lua#L741) |
| `BadgeHost.ApplyMap` | [L760](../../Bars/BadgeHost.lua#L760) |
| `BadgeHost.ClearSlot` | [L774](../../Bars/BadgeHost.lua#L774) |
| `BadgeHost.GetSlotBadges` | [L778](../../Bars/BadgeHost.lua#L778) |
| `BadgeHost.HasAny` | [L782](../../Bars/BadgeHost.lua#L782) |
| `BadgeHost.EachIndexedBody` | [L786](../../Bars/BadgeHost.lua#L786) |
| `BadgeHost.NotifyDisplay` | [L807](../../Bars/BadgeHost.lua#L807) |
| `BadgeHost.RefreshFormVisibility` | [L850](../../Bars/BadgeHost.lua#L850) |
| `BadgeHost.OnIdentityChange` | [L906](../../Bars/BadgeHost.lua#L906) |
| `BadgeHost.SyncShownFaces` | [L939](../../Bars/BadgeHost.lua#L939) |
| `BadgeHost.RefreshOccupancyVisibility` | [L967](../../Bars/BadgeHost.lua#L967) |
| `BadgeHost.NotifyModifierPaging` | [L984](../../Bars/BadgeHost.lua#L984) |
| `BadgeHost.RefreshDisplays` | [L1056](../../Bars/BadgeHost.lua#L1056) |
| `BadgeHost.RefreshMouseoverDisplays` | [L1070](../../Bars/BadgeHost.lua#L1070) |
| `BadgeHost.GetVisibleBadgesForButton` | [L1099](../../Bars/BadgeHost.lua#L1099) |
| `BadgeHost.RefreshLayout` | [L1148](../../Bars/BadgeHost.lua#L1148) |
| `BadgeHost.FlushCombatQueue` | [L1173](../../Bars/BadgeHost.lua#L1173) |

### Bars/BindingMode.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `BM:ShouldForceShowAllExtraSlots` | [L12](../../Bars/BindingMode.lua#L12) |
| `BM:IsActive` | [L15](../../Bars/BindingMode.lua#L15) |
| `BM:RegisterButton` | [L18](../../Bars/BindingMode.lua#L18) |
| `BM:Activate` | [L20](../../Bars/BindingMode.lua#L20) |
| `BM:Deactivate` | [L22](../../Bars/BindingMode.lua#L22) |
| `KeyBound:Set` | [L146](../../Bars/BindingMode.lua#L146) |
| `Binder:SetKey` | [L163](../../Bars/BindingMode.lua#L163) |
| `Binder:OnEnter` | [L180](../../Bars/BindingMode.lua#L180) |
| `BM:ShouldForceShowAllExtraSlots` | [L189](../../Bars/BindingMode.lua#L189) |
| `BM:IsActive` | [L193](../../Bars/BindingMode.lua#L193) |
| `widget:GetHotkey` | [L208](../../Bars/BindingMode.lua#L208) |
| `widget:GetBindings` | [L216](../../Bars/BindingMode.lua#L216) |
| `widget:SetKey` | [L229](../../Bars/BindingMode.lua#L229) |
| `widget:ClearBindings` | [L233](../../Bars/BindingMode.lua#L233) |
| `widget:GetActionName` | [L239](../../Bars/BindingMode.lua#L239) |
| `BM:RegisterButton` | [L256](../../Bars/BindingMode.lua#L256) |
| `BM:SetBindingModeActive` | [L418](../../Bars/BindingMode.lua#L418) |
| `BM:Activate` | [L470](../../Bars/BindingMode.lua#L470) |
| `BM:Deactivate` | [L497](../../Bars/BindingMode.lua#L497) |
| `BM:Toggle` | [L512](../../Bars/BindingMode.lua#L512) |

### Bars/Blizzard.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Blizzard.GetHider` | [L129](../../Bars/Blizzard.lua#L129) |
| `Blizzard.GetActionButton` | [L140](../../Bars/Blizzard.lua#L140) |
| `Blizzard.QueueLeftoverMouse` | [L674](../../Bars/Blizzard.lua#L674) |
| `Blizzard.HideStockButtons` | [L820](../../Bars/Blizzard.lua#L820) |
| `Blizzard.KillLeftoverMouse` | [L834](../../Bars/Blizzard.lua#L834) |
| `Blizzard.HideUnusedBars` | [L876](../../Bars/Blizzard.lua#L876) |
| `widget.UpdateButtonArtwidget.UpdateButtonArt` | [L986](../../Bars/Blizzard.lua#L986) |
| `Blizzard.SkinButton` | [L997](../../Bars/Blizzard.lua#L997) |
| `Blizzard.Prepare` | [L1011](../../Bars/Blizzard.lua#L1011) |
| `Blizzard.Reassert` | [L1017](../../Bars/Blizzard.lua#L1017) |
| `Blizzard.QuietGrid` | [L1023](../../Bars/Blizzard.lua#L1023) |

### Bars/BlizzardOptions.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Options.SetupBindingDisplayNames` | [L80](../../Bars/BlizzardOptions.lua#L80) |
| `KeybindingsOverrides.AddBindingCategoriesKeybindingsOverrides.AddBindingCategories` | [L237](../../Bars/BlizzardOptions.lua#L237) |
| `ActionBarsOverrides.CreateActionBarVisibilitySettingsActionBarsOverrides.CreateActionBarVisibilitySettings` | [L257](../../Bars/BlizzardOptions.lua#L257) |
| `ActionBarsOverrides.AdjustActionBarSettingsActionBarsOverrides.AdjustActionBarSettings` | [L315](../../Bars/BlizzardOptions.lua#L315) |

### Bars/Clicks.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Clicks.UseKeyDown` | [L28](../../Bars/Clicks.lua#L28) |
| `Clicks.Prepare` | [L38](../../Bars/Clicks.lua#L38) |
| `Clicks.ApplyRegistration` | [L54](../../Bars/Clicks.lua#L54) |
| `Clicks.ReassertEmpower` | [L149](../../Bars/Clicks.lua#L149) |
| `Clicks.InvalidateKeys` | [L190](../../Bars/Clicks.lua#L190) |
| `Clicks.RefreshKeys` | [L194](../../Bars/Clicks.lua#L194) |
| `Clicks.OnCVar` | [L265](../../Bars/Clicks.lua#L265) |
| `Clicks.Start` | [L287](../../Bars/Clicks.lua#L287) |

### Bars/Effects.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Effects.SetGlow` | [L245](../../Bars/Effects.lua#L245) |
| `Effects.SyncColumn` | [L347](../../Bars/Effects.lua#L347) |
| `Effects.Refresh` | [L532](../../Bars/Effects.lua#L532) |
| `Effects.RefreshAll` | [L544](../../Bars/Effects.lua#L544) |
| `Effects.Start` | [L551](../../Bars/Effects.lua#L551) |

### Bars/Flyout.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Flyout.HasSpellFlyout` | [L34](../../Bars/Flyout.lua#L34) |
| `Flyout.Hide` | [L38](../../Bars/Flyout.lua#L38) |
| `Flyout.Attach` | [L45](../../Bars/Flyout.lua#L45) |
| `Flyout.IsFlyoutSlot` | [L57](../../Bars/Flyout.lua#L57) |
| `Flyout.Update` | [L90](../../Bars/Flyout.lua#L90) |

### Bars/Hosts.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Hosts.MiniCountFontSize` | [L42](../../Bars/Hosts.lua#L42) |
| `Hosts.ResolveParts` | [L65](../../Bars/Hosts.lua#L65) |
| `Hosts.BindingCommand` | [L90](../../Bars/Hosts.lua#L90) |
| `Hosts.LiveSlot` | [L100](../../Bars/Hosts.lua#L100) |
| `Hosts.IndexSlot` | [L117](../../Bars/Hosts.lua#L117) |
| `Hosts.ForSlot` | [L141](../../Bars/Hosts.lua#L141) |
| `Hosts.UpdateTooltip` | [L438](../../Bars/Hosts.lua#L438) |
| `Hosts.RefreshHoverTooltip` | [L478](../../Bars/Hosts.lua#L478) |
| `Hosts.CreateSurface` | [L489](../../Bars/Hosts.lua#L489) |
| `Hosts.Skin` | [L807](../../Bars/Hosts.lua#L807) |
| `Hosts.FinishSurface` | [L817](../../Bars/Hosts.lua#L817) |
| `Hosts.Build` | [L854](../../Bars/Hosts.lua#L854) |
| `Hosts.ApplyChrome` | [L911](../../Bars/Hosts.lua#L911) |
| `Hosts.InvalidateKeys` | [L917](../../Bars/Hosts.lua#L917) |
| `Hosts.RefreshKeys` | [L923](../../Bars/Hosts.lua#L923) |
| `Hosts.PrepareClicks` | [L929](../../Bars/Hosts.lua#L929) |

### Bars/Init.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Bars.GetHost` | [L37](../../Bars/Init.lua#L37) |
| `Bars.GetMain` | [L41](../../Bars/Init.lua#L41) |
| `Bars.ForEach` | [L46](../../Bars/Init.lua#L46) |
| `Bars.ForEachHost` | [L57](../../Bars/Init.lua#L57) |
| `Bars.ForEachStatic` | [L76](../../Bars/Init.lua#L76) |
| `Bars.RequestLayout` | [L102](../../Bars/Init.lua#L102) |
| `Bars.RequestStockSweep` | [L147](../../Bars/Init.lua#L147) |
| `Bars.RequestPaint` | [L168](../../Bars/Init.lua#L168) |
| `Bars.ApplyLayout` | [L216](../../Bars/Init.lua#L216) |
| `Bars.Start` | [L258](../../Bars/Init.lua#L258) |
| `Bars.ApplyPerformanceSettings` | [L353](../../Bars/Init.lua#L353) |
| `Bars.ApplyActionbarsOptions` | [L380](../../Bars/Init.lua#L380) |

### Bars/Layout.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Layout.HasContentInAnyState` | [L63](../../Bars/Layout.lua#L63) |
| `Layout.HasContentOnMain` | [L82](../../Bars/Layout.lua#L82) |
| `Layout.IsColumnEmpty` | [L94](../../Bars/Layout.lua#L94) |
| `Layout.GetPromotedMode` | [L114](../../Bars/Layout.lua#L114) |
| `Layout.IsExpanding` | [L136](../../Bars/Layout.lua#L136) |
| `Layout.SetBindingMode` | [L157](../../Bars/Layout.lua#L157) |
| `Layout.MiniAtBottom` | [L168](../../Bars/Layout.lua#L168) |
| `Layout.InvalidateMappings` | [L178](../../Bars/Layout.lua#L178) |
| `Layout.ApplyMappings` | [L202](../../Bars/Layout.lua#L202) |
| `Layout.RevealEmptyInCombat` | [L266](../../Bars/Layout.lua#L266) |
| `Layout.AnyMiniVisible` | [L399](../../Bars/Layout.lua#L399) |
| `Layout.VisibleCount` | [L409](../../Bars/Layout.lua#L409) |
| `Layout.ApplyVisual` | [L458](../../Bars/Layout.lua#L458) |
| `Layout.Invalidate` | [L598](../../Bars/Layout.lua#L598) |
| `Layout.Apply` | [L603](../../Bars/Layout.lua#L603) |
| `Layout.Request` | [L629](../../Bars/Layout.lua#L629) |
| `Layout.OnCursor` | [L686](../../Bars/Layout.lua#L686) |
| `Layout.Start` | [L705](../../Bars/Layout.lua#L705) |

### Bars/MacrotextDisplay.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Display.Request` | [L17](../../Bars/MacrotextDisplay.lua#L17) |
| `Display.RequestMouseover` | [L24](../../Bars/MacrotextDisplay.lua#L24) |
| `Display.RefreshForColumns` | [L31](../../Bars/MacrotextDisplay.lua#L31) |
| `Display.GetStats` | [L35](../../Bars/MacrotextDisplay.lua#L35) |
| `Display.ResetStats` | [L43](../../Bars/MacrotextDisplay.lua#L43) |
| `Display.HookUnitFramePeek` | [L50](../../Bars/MacrotextDisplay.lua#L50) |
| `Display.MouseoverReactionClass` | [L57](../../Bars/MacrotextDisplay.lua#L57) |

### Bars/Minis.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Minis.Build` | [L11](../../Bars/Minis.lua#L11) |

### Bars/Paint.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Paint.ShownSpellId` | [L178](../../Bars/Paint.lua#L178) |
| `Paint.UpdateName` | [L473](../../Bars/Paint.lua#L473) |
| `Paint.UpdateIcon` | [L513](../../Bars/Paint.lua#L513) |
| `Paint.UpdateCount` | [L840](../../Bars/Paint.lua#L840) |
| `Paint.UpdateCooldown` | [L1176](../../Bars/Paint.lua#L1176) |
| `Paint.UpdateUsable` | [L1239](../../Bars/Paint.lua#L1239) |
| `Paint.NotePlayerCast` | [L1364](../../Bars/Paint.lua#L1364) |
| `Paint.NeedsRange` | [L1416](../../Bars/Paint.lua#L1416) |
| `Paint.UpdateRange` | [L1474](../../Bars/Paint.lua#L1474) |
| `Paint.ApplySlotRange` | [L1493](../../Bars/Paint.lua#L1493) |
| `Paint.SweepLitChecked` | [L1621](../../Bars/Paint.lua#L1621) |
| `Paint.ArmCheckedPoll` | [L1645](../../Bars/Paint.lua#L1645) |
| `Paint.UpdateFlash` | [L1661](../../Bars/Paint.lua#L1661) |
| `Paint.UpdateChecked` | [L1687](../../Bars/Paint.lua#L1687) |
| `Paint.UpdateEquipped` | [L1764](../../Bars/Paint.lua#L1764) |
| `Paint.AbbreviateKey` | [L1875](../../Bars/Paint.lua#L1875) |
| `Paint.UpdateHotkey` | [L1889](../../Bars/Paint.lua#L1889) |
| `Paint.UpdateAssistedCombat` | [L2014](../../Bars/Paint.lua#L2014) |
| `rot.OnUpdate` | [L2047](../../Bars/Paint.lua#L2047) |
| `Paint.UpdateAssistedHighlight` | [L2122](../../Bars/Paint.lua#L2122) |
| `Paint.PaintAssistedHighlights` | [L2203](../../Bars/Paint.lua#L2203) |
| `Paint.PaintAssistedHosts` | [L2215](../../Bars/Paint.lua#L2215) |
| `Paint.UpdateDisplay` | [L2237](../../Bars/Paint.lua#L2237) |
| `Paint.UpdateAll` | [L2254](../../Bars/Paint.lua#L2254) |
| `Paint.HostIsLive` | [L2264](../../Bars/Paint.lua#L2264) |
| `Paint.MarkDirty` | [L2280](../../Bars/Paint.lua#L2280) |
| `Paint.Dirty` | [L2288](../../Bars/Paint.lua#L2288) |
| `Paint.EachDirty` | [L2293](../../Bars/Paint.lua#L2293) |
| `Paint.Flush` | [L2302](../../Bars/Paint.lua#L2302) |
| `Paint.ClearCache` | [L2487](../../Bars/Paint.lua#L2487) |

### Bars/Pet/Init.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Pet.GetFrame` | [L49](../../Bars/Pet/Init.lua#L49) |
| `Pet.GetButton` | [L53](../../Bars/Pet/Init.lua#L53) |
| `Pet.GetAllButtons` | [L57](../../Bars/Pet/Init.lua#L57) |
| `Pet.ForAll` | [L61](../../Bars/Pet/Init.lua#L61) |
| `Pet.UpdatePosition` | [L112](../../Bars/Pet/Init.lua#L112) |
| `Pet.SetBindingModeFrameOverride` | [L161](../../Bars/Pet/Init.lua#L161) |
| `Pet.FlushBindingModePending` | [L185](../../Bars/Pet/Init.lua#L185) |
| `Pet.ApplyVisibility` | [L194](../../Bars/Pet/Init.lua#L194) |
| `f.GetFrame` | [L208](../../Bars/Pet/Init.lua#L208) |
| `endf.GetButton` | [L211](../../Bars/Pet/Init.lua#L211) |
| `endf.GetAllButtons` | [L214](../../Bars/Pet/Init.lua#L214) |
| `endf.ForAll` | [L217](../../Bars/Pet/Init.lua#L217) |
| `endf.UpdatePosition` | [L220](../../Bars/Pet/Init.lua#L220) |
| `endf.SetupKeybindings` | [L223](../../Bars/Pet/Init.lua#L223) |
| `endendf.SetBindingModeFrameOverride` | [L228](../../Bars/Pet/Init.lua#L228) |
| `Pet.Start` | [L278](../../Bars/Pet/Init.lua#L278) |

### Bars/Pet/Keys.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Pet.SetupKeybindings` | [L12](../../Bars/Pet/Keys.lua#L12) |

### Bars/Pet/Layout.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Pet.LayoutButtons` | [L51](../../Bars/Pet/Layout.lua#L51) |

### Bars/Pet/Watch.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Watch.Start` | [L41](../../Bars/Pet/Watch.lua#L41) |

### Bars/ProgramFace.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `ProgramFace.BodyForSlot` | [L109](../../Bars/ProgramFace.lua#L109) |
| `ProgramFace.NoteFace` | [L147](../../Bars/ProgramFace.lua#L147) |
| `ProgramFace.ClassifyBody` | [L236](../../Bars/ProgramFace.lua#L236) |
| `ProgramFace.InvalidateIndex` | [L351](../../Bars/ProgramFace.lua#L351) |
| `ProgramFace.RebuildIndex` | [L361](../../Bars/ProgramFace.lua#L361) |
| `ProgramFace.Needs` | [L479](../../Bars/ProgramFace.lua#L479) |
| `ProgramFace.KindWanted` | [L512](../../Bars/ProgramFace.lua#L512) |
| `ProgramFace.ProbeFlags` | [L516](../../Bars/ProgramFace.lua#L516) |
| `ProgramFace.EachExtraMatching` | [L529](../../Bars/ProgramFace.lua#L529) |
| `ProgramFace.TranslateAll` | [L588](../../Bars/ProgramFace.lua#L588) |
| `ProgramFace.EachBody` | [L607](../../Bars/ProgramFace.lua#L607) |
| `ProgramFace.RequestTarget` | [L846](../../Bars/ProgramFace.lua#L846) |
| `ProgramFace.NoteMouseoverEvent` | [L865](../../Bars/ProgramFace.lua#L865) |
| `ProgramFace.ArmMouseoverPoll` | [L899](../../Bars/ProgramFace.lua#L899) |
| `ProgramFace.WakeMouseoverPoll` | [L951](../../Bars/ProgramFace.lua#L951) |
| `ProgramFace.SetMouseoverPollInterval` | [L964](../../Bars/ProgramFace.lua#L964) |
| `ProgramFace.SetMinFlushInterval` | [L977](../../Bars/ProgramFace.lua#L977) |
| `ProgramFace.FlushPending` | [L991](../../Bars/ProgramFace.lua#L991) |
| `ProgramFace.Request` | [L1050](../../Bars/ProgramFace.lua#L1050) |
| `ProgramFace.RequestConditionalRefresh` | [L1081](../../Bars/ProgramFace.lua#L1081) |
| `ProgramFace.HasAny` | [L1085](../../Bars/ProgramFace.lua#L1085) |
| `ProgramFace.SyncHost` | [L1102](../../Bars/ProgramFace.lua#L1102) |
| `ProgramFace.TranslateHost` | [L1166](../../Bars/ProgramFace.lua#L1166) |
| `ProgramFace.ShownForSlot` | [L1206](../../Bars/ProgramFace.lua#L1206) |
| `ProgramFace.Shown` | [L1230](../../Bars/ProgramFace.lua#L1230) |
| `ProgramFace.RequestHoverPeek` | [L1363](../../Bars/ProgramFace.lua#L1363) |
| `ProgramFace.OnContext` | [L1442](../../Bars/ProgramFace.lua#L1442) |
| `ProgramFace.ContextOwnsDisplay` | [L1534](../../Bars/ProgramFace.lua#L1534) |
| `ProgramFace.Start` | [L1539](../../Bars/ProgramFace.lua#L1539) |

### Bars/SlotMath.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `M.Pack` | [L7](../../Bars/SlotMath.lua#L7) |
| `M.Unpack` | [L16](../../Bars/SlotMath.lua#L16) |
| `M.Resolve` | [L46](../../Bars/SlotMath.lua#L46) |
| `M.MainSlot` | [L144](../../Bars/SlotMath.lua#L144) |
| `M.SecondarySlot` | [L156](../../Bars/SlotMath.lua#L156) |
| `M.TertiarySlot` | [L164](../../Bars/SlotMath.lua#L164) |
| `M.SelfTest` | [L178](../../Bars/SlotMath.lua#L178) |

### Bars/SlotProgram.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `SlotHost.GetAllBarSlots` | [L259](../../Bars/SlotProgram.lua#L259) |
| `SlotProgram.Apply` | [L323](../../Bars/SlotProgram.lua#L323) |
| `SlotProgram.ApplyMap` | [L362](../../Bars/SlotProgram.lua#L362) |
| `SlotProgram.Get` | [L391](../../Bars/SlotProgram.lua#L391) |
| `SlotProgram.GetIdle` | [L395](../../Bars/SlotProgram.lua#L395) |
| `SlotProgram.GetMode` | [L403](../../Bars/SlotProgram.lua#L403) |
| `SlotProgram.GetAll` | [L407](../../Bars/SlotProgram.lua#L407) |
| `SlotProgram.ClickButtonName` | [L411](../../Bars/SlotProgram.lua#L411) |
| `SlotProgram.ClickButton` | [L422](../../Bars/SlotProgram.lua#L422) |
| `SlotProgram.HasAny` | [L429](../../Bars/SlotProgram.lua#L429) |
| `SlotProgram.SetHover` | [L433](../../Bars/SlotProgram.lua#L433) |
| `SlotProgram.ApplyHoverMap` | [L445](../../Bars/SlotProgram.lua#L445) |
| `SlotProgram.GetHover` | [L483](../../Bars/SlotProgram.lua#L483) |
| `SlotProgram.GetAllHover` | [L487](../../Bars/SlotProgram.lua#L487) |
| `SlotProgram.HasHover` | [L491](../../Bars/SlotProgram.lua#L491) |
| `SlotProgram.RefreshDisplays` | [L518](../../Bars/SlotProgram.lua#L518) |
| `SlotProgram.ApplyStripDisplayOverrides` | [L555](../../Bars/SlotProgram.lua#L555) |
| `SlotProgram.ReassertAll` | [L575](../../Bars/SlotProgram.lua#L575) |
| `SlotProgram.FlushCombatQueue` | [L594](../../Bars/SlotProgram.lua#L594) |

### Bars/SpellRank.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `ApplyRankDesaturation` | [L557](../../Bars/SpellRank.lua#L557) |
| `UpdateHostDesaturation` | [L598](../../Bars/SpellRank.lua#L598) |
| `UpdateFluxButtonDesaturation` | [L605](../../Bars/SpellRank.lua#L605) |
| `UpdateAllButtonDesaturation` | [L615](../../Bars/SpellRank.lua#L615) |
| `SpellRank:RankUpAllSpells` | [L911](../../Bars/SpellRank.lua#L911) |
| `SpellRank:IsRankFeaturesSupported` | [L1294](../../Bars/SpellRank.lua#L1294) |
| `SpellRank:IsLowerRankSpell` | [L1298](../../Bars/SpellRank.lua#L1298) |
| `SpellRank:ApplyRankDesaturation` | [L1305](../../Bars/SpellRank.lua#L1305) |
| `SpellRank:RefreshColumnSurfaces` | [L1326](../../Bars/SpellRank.lua#L1326) |
| `SpellRank:RefreshColumnSurfacesPaging` | [L1356](../../Bars/SpellRank.lua#L1356) |
| `SpellRank:RefreshColumnAllRows` | [L1360](../../Bars/SpellRank.lua#L1360) |
| `SpellRank:RefreshColumnUsable` | [L1388](../../Bars/SpellRank.lua#L1388) |
| `SpellRank:ClearHostRankState` | [L1422](../../Bars/SpellRank.lua#L1422) |
| `SpellRank:ReassertDesaturation` | [L1440](../../Bars/SpellRank.lua#L1440) |
| `SpellRank:GetAutoRankUpEnabled` | [L1482](../../Bars/SpellRank.lua#L1482) |
| `SpellRank:SetAutoRankUpEnabled` | [L1489](../../Bars/SpellRank.lua#L1489) |
| `SpellRank:GetBlacklistSpellIDs` | [L1511](../../Bars/SpellRank.lua#L1511) |
| `SpellRank:ToggleSpellBlacklist` | [L1546](../../Bars/SpellRank.lua#L1546) |
| `SpellRank:ClearSpellFromBlacklist` | [L1553](../../Bars/SpellRank.lua#L1553) |
| `SpellRank:SetSpellBlacklistPanelRefreshHandler` | [L1573](../../Bars/SpellRank.lua#L1573) |
| `SpellRank:NotifySpellBlacklistPanelRefresh` | [L1577](../../Bars/SpellRank.lua#L1577) |
| `SpellRank:RefreshSpellBookRankUI` | [L1581](../../Bars/SpellRank.lua#L1581) |
| `SpellRank:RefreshAfterActionbarsScopedStorageChange` | [L1593](../../Bars/SpellRank.lua#L1593) |
| `SpellRank.RefreshAll` | [L1603](../../Bars/SpellRank.lua#L1603) |

### Bars/Stance/Extras.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Stance.InvalidateExtras` | [L225](../../Bars/Stance/Extras.lua#L225) |
| `Stance.GetMageArmorIds` | [L231](../../Bars/Stance/Extras.lua#L231) |
| `Stance.GetActivePetSpell` | [L235](../../Bars/Stance/Extras.lua#L235) |
| `Stance.NoteMageArmorCast` | [L591](../../Bars/Stance/Extras.lua#L591) |
| `Stance.IsMageArmorSpell` | [L607](../../Bars/Stance/Extras.lua#L607) |
| `Stance.GetActiveMageArmor` | [L629](../../Bars/Stance/Extras.lua#L629) |
| `Stance.ArmorPollSignature` | [L686](../../Bars/Stance/Extras.lua#L686) |
| `Stance.BeginExtraVisualPass` | [L713](../../Bars/Stance/Extras.lua#L713) |
| `Stance.EnsureAuraCountdown` | [L964](../../Bars/Stance/Extras.lua#L964) |
| `Stance.SyncAuraCountdown` | [L1066](../../Bars/Stance/Extras.lua#L1066) |
| `Stance.CustomTrackSpell` | [L1242](../../Bars/Stance/Extras.lua#L1242) |
| `Stance.IsTrackedCustomSpell` | [L1276](../../Bars/Stance/Extras.lua#L1276) |
| `Stance.NoteCustomCast` | [L1381](../../Bars/Stance/Extras.lua#L1381) |
| `Stance.CustomAuraPollSignature` | [L1408](../../Bars/Stance/Extras.lua#L1408) |
| `Stance.ApplyExtraActiveVisual` | [L1434](../../Bars/Stance/Extras.lua#L1434) |
| `Stance.GetAvailableSpells` | [L1701](../../Bars/Stance/Extras.lua#L1701) |
| `Stance.ShouldShowExtra` | [L1814](../../Bars/Stance/Extras.lua#L1814) |
| `Stance.ShouldShowCustom` | [L1847](../../Bars/Stance/Extras.lua#L1847) |

### Bars/Stance/Forms.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Stance.GetDonor` | [L19](../../Bars/Stance/Forms.lua#L19) |
| `Stance.EnsureDonor` | [L23](../../Bars/Stance/Forms.lua#L23) |
| `Stance.GetFormButton` | [L49](../../Bars/Stance/Forms.lua#L49) |
| `Stance.GetExtraButton` | [L53](../../Bars/Stance/Forms.lua#L53) |
| `Stance.EnsureFormButton` | [L57](../../Bars/Stance/Forms.lua#L57) |
| `Stance.EnsureExtraButton` | [L102](../../Bars/Stance/Forms.lua#L102) |
| `Stance.AttachReorderControls` | [L158](../../Bars/Stance/Forms.lua#L158) |
| `Stance.AttachHideControls` | [L204](../../Bars/Stance/Forms.lua#L204) |
| `Stance.ForEachPooled` | [L208](../../Bars/Stance/Forms.lua#L208) |
| `Stance.TagFormArmor` | [L219](../../Bars/Stance/Forms.lua#L219) |
| `Stance.PaintFormVisuals` | [L256](../../Bars/Stance/Forms.lua#L256) |
| `Stance.PaintExtraVisuals` | [L318](../../Bars/Stance/Forms.lua#L318) |

### Bars/Stance/Init.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Stance.GetFrame` | [L54](../../Bars/Stance/Init.lua#L54) |
| `Stance.UsesFluxPlayerFrame` | [L58](../../Bars/Stance/Init.lua#L58) |
| `Stance.ShouldAnchorToPlayerBorder` | [L62](../../Bars/Stance/Init.lua#L62) |
| `Stance.ApplyBorderChrome` | [L72](../../Bars/Stance/Init.lua#L72) |
| `Stance.ToggleSlotHidden` | [L99](../../Bars/Stance/Init.lua#L99) |
| `Stance.GetSlotOrderDescriptors` | [L104](../../Bars/Stance/Init.lua#L104) |
| `Stance.GetSlotOrderEditorRows` | [L155](../../Bars/Stance/Init.lua#L155) |
| `Stance.GetCanonicalToShapeshiftButtonBindingIndexMap` | [L170](../../Bars/Stance/Init.lua#L170) |
| `Stance.ReassignBindings` | [L204](../../Bars/Stance/Init.lua#L204) |
| `f.GetFrame` | [L264](../../Bars/Stance/Init.lua#L264) |
| `endf.Flux_ReanchorToLayout` | [L267](../../Bars/Stance/Init.lua#L267) |
| `endendf.RequestLayout` | [L279](../../Bars/Stance/Init.lua#L279) |
| `endendf.RequestSizeOnly` | [L284](../../Bars/Stance/Init.lua#L284) |
| `endendf.ReassignBindings` | [L289](../../Bars/Stance/Init.lua#L289) |
| `endf.ApplySavedSlotOrderAndRefresh` | [L292](../../Bars/Stance/Init.lua#L292) |
| `endendf.UpdateLayout` | [L297](../../Bars/Stance/Init.lua#L297) |
| `endendf.GetSlotOrderDescriptors` | [L302](../../Bars/Stance/Init.lua#L302) |
| `endf.GetSlotOrderEditorRows` | [L305](../../Bars/Stance/Init.lua#L305) |
| `endf.GetCanonicalToShapeshiftButtonBindingIndexMap` | [L308](../../Bars/Stance/Init.lua#L308) |
| `endf.ToggleStanceSlotHidden` | [L311](../../Bars/Stance/Init.lua#L311) |
| `endf.RemoveCustomSlot` | [L314](../../Bars/Stance/Init.lua#L314) |
| `endf.AddCustomFromCursor` | [L317](../../Bars/Stance/Init.lua#L317) |
| `Stance.Start` | [L324](../../Bars/Stance/Init.lua#L324) |

### Bars/Stance/Layout.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Stance.ComputeLayoutMetrics` | [L38](../../Bars/Stance/Layout.lua#L38) |
| `Stance.Anchor` | [L124](../../Bars/Stance/Layout.lua#L124) |
| `Stance.ApplyLayout` | [L204](../../Bars/Stance/Layout.lua#L204) |
| `Stance.RequestLayout` | [L397](../../Bars/Stance/Layout.lua#L397) |
| `Stance.RequestSizeOnly` | [L422](../../Bars/Stance/Layout.lua#L422) |
| `Stance.RequestFormsVisual` | [L426](../../Bars/Stance/Layout.lua#L426) |
| `Stance.RequestExtrasVisual` | [L446](../../Bars/Stance/Layout.lua#L446) |
| `Stance.RequestDiscover` | [L466](../../Bars/Stance/Layout.lua#L466) |

### Bars/Stance/Order.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Stance.MakeSlotKey` | [L19](../../Bars/Stance/Order.lua#L19) |
| `Stance.GetSavedOrder` | [L45](../../Bars/Stance/Order.lua#L45) |
| `Stance.SetSavedOrder` | [L50](../../Bars/Stance/Order.lua#L50) |
| `Stance.GetHiddenSlots` | [L58](../../Bars/Stance/Order.lua#L58) |
| `Stance.IsSlotHidden` | [L63](../../Bars/Stance/Order.lua#L63) |
| `Stance.SetSlotHidden` | [L71](../../Bars/Stance/Order.lua#L71) |
| `Stance.BuildPermutation` | [L96](../../Bars/Stance/Order.lua#L96) |
| `Stance.ReorderKey` | [L125](../../Bars/Stance/Order.lua#L125) |
| `Stance.ApplyHiddenToShouldShow` | [L154](../../Bars/Stance/Order.lua#L154) |
| `Stance.CustomIcon` | [L238](../../Bars/Stance/Order.lua#L238) |
| `Stance.GetSavedCustomSlots` | [L296](../../Bars/Stance/Order.lua#L296) |
| `Stance.SetSavedCustomSlots` | [L315](../../Bars/Stance/Order.lua#L315) |
| `Stance.HasCustomSlots` | [L336](../../Bars/Stance/Order.lua#L336) |
| `Stance.GetCustomEntries` | [L340](../../Bars/Stance/Order.lua#L340) |
| `Stance.Catalog` | [L369](../../Bars/Stance/Order.lua#L369) |
| `Stance.BuiltinHasSpell` | [L377](../../Bars/Stance/Order.lua#L377) |
| `Stance.AddCustomSlot` | [L444](../../Bars/Stance/Order.lua#L444) |
| `Stance.AddCustomFromCursor` | [L464](../../Bars/Stance/Order.lua#L464) |
| `Stance.ReplaceCustomSpellId` | [L476](../../Bars/Stance/Order.lua#L476) |
| `Stance.RemoveCustomSlot` | [L548](../../Bars/Stance/Order.lua#L548) |

### Bars/Stance/Watch.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Watch.Start` | [L14](../../Bars/Stance/Watch.lua#L14) |

### Bars/State.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `State.GetSecondarySlot` | [L72](../../Bars/State.lua#L72) |
| `State.GetTertiarySlot` | [L76](../../Bars/State.lua#L76) |
| `State.GetMainSlot` | [L80](../../Bars/State.lua#L80) |
| `State.ResolveSlot` | [L84](../../Bars/State.lua#L84) |
| `State.GetCurrentPage` | [L107](../../Bars/State.lua#L107) |
| `State.GetMinirowPosition` | [L127](../../Bars/State.lua#L127) |
| `State.BuildNativeDriver` | [L197](../../Bars/State.lua#L197) |
| `State.Attach` | [L658](../../Bars/State.lua#L658) |
| `State.HeaderFor` | [L696](../../Bars/State.lua#L696) |
| `State.Create` | [L799](../../Bars/State.lua#L799) |
| `State.RegisterDrivers` | [L828](../../Bars/State.lua#L828) |
| `State.CurrentSwap` | [L973](../../Bars/State.lua#L973) |
| `State.IndexLiveSlots` | [L987](../../Bars/State.lua#L987) |
| `State.ApplySlotsInsecure` | [L1033](../../Bars/State.lua#L1033) |
| `State.OnModFallback` | [L1078](../../Bars/State.lua#L1078) |
| `State.ForceApply` | [L1086](../../Bars/State.lua#L1086) |
| `State.GetClassStances` | [L1123](../../Bars/State.lua#L1123) |

### Bars/Strip.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Strip.GetBottomScreenOffset` | [L19](../../Bars/Strip.lua#L19) |
| `Strip.UpdatePosition` | [L35](../../Bars/Strip.lua#L35) |
| `Strip.Metrics` | [L48](../../Bars/Strip.lua#L48) |
| `Strip.ComputeExtraScale` | [L87](../../Bars/Strip.lua#L87) |
| `Strip.ComputeXFactor` | [L116](../../Bars/Strip.lua#L116) |
| `Strip.ComputeLook` | [L137](../../Bars/Strip.lua#L137) |
| `Strip.Create` | [L143](../../Bars/Strip.lua#L143) |
| `Strip.ApplyAppearanceAccent` | [L177](../../Bars/Strip.lua#L177) |
| `Strip.GetSlot` | [L189](../../Bars/Strip.lua#L189) |
| `Strip.RefreshClearance` | [L216](../../Bars/Strip.lua#L216) |
| `Strip.SyncVisibility` | [L273](../../Bars/Strip.lua#L273) |
| `Strip.ApplyGamepadHud` | [L307](../../Bars/Strip.lua#L307) |
| `Strip.WatchGamepad` | [L337](../../Bars/Strip.lua#L337) |
| `Strip.Layout` | [L349](../../Bars/Strip.lua#L349) |

### Bars/Vehicle.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `endendVehicle.OnReplacementsReady` | [L115](../../Bars/Vehicle.lua#L115) |
| `Vehicle.Apply` | [L138](../../Bars/Vehicle.lua#L138) |
| `Vehicle.QueueApply` | [L166](../../Bars/Vehicle.lua#L166) |
| `Vehicle.Start` | [L204](../../Bars/Vehicle.lua#L204) |

### Bars/Watch.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Watch.SyncRangeSlots` | [L132](../../Bars/Watch.lua#L132) |
| `Watch.SyncRange` | [L165](../../Bars/Watch.lua#L165) |
| `Watch.SetActionUsableMinInterval` | [L184](../../Bars/Watch.lua#L184) |
| `Watch.IsRangeArmed` | [L198](../../Bars/Watch.lua#L198) |
| `Watch.GetAssistantManagerRate` | [L207](../../Bars/Watch.lua#L207) |
| `Watch.SyncAssistantTicker` | [L286](../../Bars/Watch.lua#L286) |
| `Watch.InvalidateColumnStamps` | [L314](../../Bars/Watch.lua#L314) |
| `Watch.Start` | [L341](../../Bars/Watch.lua#L341) |

### Battlezonemap/FluxBattlefieldMap.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `FluxBattlefieldMap:SecureHideBlizzardMap` | [L166](../../Battlezonemap/FluxBattlefieldMap.lua#L166) |
| `mapFrame.OnEventmapFrame.OnEvent` | [L717](../../Battlezonemap/FluxBattlefieldMap.lua#L717) |
| `mapFrame.OnShowmapFrame.OnShow` | [L738](../../Battlezonemap/FluxBattlefieldMap.lua#L738) |
| `mapFrame.HidemapFrame.Hide` | [L749](../../Battlezonemap/FluxBattlefieldMap.lua#L749) |
| `FluxBattlefieldMap:Initialize` | [L1151](../../Battlezonemap/FluxBattlefieldMap.lua#L1151) |
| `FluxBattlefieldMap:Show` | [L1169](../../Battlezonemap/FluxBattlefieldMap.lua#L1169) |
| `FluxBattlefieldMap:Hide` | [L1247](../../Battlezonemap/FluxBattlefieldMap.lua#L1247) |
| `FluxBattlefieldMap:SetScaling` | [L1269](../../Battlezonemap/FluxBattlefieldMap.lua#L1269) |
| `FluxBattlefieldMap:GetScaling` | [L1281](../../Battlezonemap/FluxBattlefieldMap.lua#L1281) |
| `FluxBattlefieldMap:UpdateLayout` | [L1286](../../Battlezonemap/FluxBattlefieldMap.lua#L1286) |
| `FluxBattlefieldMap:SetParent` | [L1304](../../Battlezonemap/FluxBattlefieldMap.lua#L1304) |
| `FluxBattlefieldMap:IsActive` | [L1314](../../Battlezonemap/FluxBattlefieldMap.lua#L1314) |
| `FluxBattlefieldMap:GetMapFrame` | [L1319](../../Battlezonemap/FluxBattlefieldMap.lua#L1319) |
| `FluxBattlefieldMap:SetWorldMapFeaturesEnabled` | [L1323](../../Battlezonemap/FluxBattlefieldMap.lua#L1323) |
| `FluxBattlefieldMap:GetWorldMapFeaturesEnabled` | [L1329](../../Battlezonemap/FluxBattlefieldMap.lua#L1329) |
| `FluxBattlefieldMap:Refresh` | [L1337](../../Battlezonemap/FluxBattlefieldMap.lua#L1337) |
| `FluxBattlefieldMap:Cleanup` | [L1364](../../Battlezonemap/FluxBattlefieldMap.lua#L1364) |

### Battlezonemap/FluxBattlefieldMapPinRouter.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `FluxBattlefieldMapPinRouter:IsLibrarySupported` | [L61](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L61) |
| `FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield` | [L124](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L124) |
| `FluxBattlefieldMapPinRouter:IsHBDAvailable` | [L143](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L143) |
| `FluxBattlefieldMapPinRouter:IsHBDWorldProvider` | [L147](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L147) |
| `FluxBattlefieldMapPinRouter:GetRouteLabel` | [L166](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L166) |
| `canvaspool.createFunc` | [L231](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L231) |
| `frame.OnAcquiredframe.OnAcquired` | [L246](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L246) |
| `endendendreturnframeendpool.resetFunc` | [L257](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L257) |
| `canvaspool.createFunc` | [L325](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L325) |
| `route.battlefieldProvider.RefreshAllDataroute.battlefieldProvider.RefreshAllData` | [L574](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L574) |
| `endendworldProvider.HandlePin` | [L583](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L583) |
| `endworldProvider.RefreshAllData` | [L586](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L586) |
| `FluxBattlefieldMapPinRouter:RefreshAllThirdPartyPins` | [L706](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L706) |
| `FluxBattlefieldMapPinRouter:RequestRefresh` | [L737](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L737) |
| `FluxBattlefieldMapPinRouter:ScheduleKickstart` | [L749](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L749) |
| `FluxBattlefieldMapPinRouter:Install` | [L773](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L773) |
| `FluxBattlefieldMapPinRouter:Uninstall` | [L804](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L804) |

### Battlezonemap/FluxBattlefieldMapPinTooltips.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `FluxBattlefieldMapPinTooltips:OnHBDPinAcquired` | [L121](../../Battlezonemap/FluxBattlefieldMapPinTooltips.lua#L121) |
| `FluxBattlefieldMapPinTooltips:IsInstalled` | [L140](../../Battlezonemap/FluxBattlefieldMapPinTooltips.lua#L140) |
| `FluxBattlefieldMapPinTooltips:GetDiagnostics` | [L144](../../Battlezonemap/FluxBattlefieldMapPinTooltips.lua#L144) |
| `provider.GetMapprovider.GetMap` | [L160](../../Battlezonemap/FluxBattlefieldMapPinTooltips.lua#L160) |
| `provider.RemoveAllData` | [L169](../../Battlezonemap/FluxBattlefieldMapPinTooltips.lua#L169) |
| `FluxBattlefieldMapPinTooltips:Install` | [L230](../../Battlezonemap/FluxBattlefieldMapPinTooltips.lua#L230) |
| `FluxBattlefieldMapPinTooltips:Uninstall` | [L245](../../Battlezonemap/FluxBattlefieldMapPinTooltips.lua#L245) |

### Battlezonemap/FluxBattlefieldMapProviders.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `provider:ShouldShowQuest` | [L214](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L214) |
| `mapFrame:AcquirePin` | [L319](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L319) |
| `provider:RefreshAllData` | [L562](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L562) |
| `provider:OnHighlightedQuestPOIChange` | [L583](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L583) |
| `provider:OnCanvasSizeChanged` | [L591](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L591) |
| `pin:OnCanvasSizeChanged` | [L706](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L706) |
| `pin:OnMapChanged` | [L709](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L709) |
| `pin:Refresh` | [L712](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L712) |
| `FluxBattlefieldMapProviders:Attach` | [L1101](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L1101) |
| `FluxBattlefieldMapProviders:Detach` | [L1127](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L1127) |
| `FluxBattlefieldMapProviders:IsAttached` | [L1149](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L1149) |

### Battlezonemap/FluxBattlefieldMapWorldFeatures.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `cloneworldProvider.RefreshAllData` | [L179](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L179) |
| `FluxBattlefieldMapWorldFeatures:IsEnabled` | [L322](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L322) |
| `FluxBattlefieldMapWorldFeatures:SetEnabled` | [L347](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L347) |
| `FluxBattlefieldMapWorldFeatures:RefreshBattlefieldMapPublic` | [L535](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L535) |
| `FluxBattlefieldMapWorldFeatures:RefreshShadowClones` | [L539](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L539) |
| `FluxBattlefieldMapWorldFeatures:ClearShadowClonesOnBattlefield` | [L553](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L553) |
| `FluxBattlefieldMapWorldFeatures:StripCombatUnsafeProviders` | [L699](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L699) |
| `mapFrame.AddDataProvidermapFrame.AddDataProvider` | [L759](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L759) |
| `FluxBattlefieldMapWorldFeatures:RefreshToggleLayout` | [L921](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L921) |
| `FluxBattlefieldMapWorldFeatures:Activate` | [L1028](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1028) |
| `FluxBattlefieldMapWorldFeatures:Deactivate` | [L1046](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1046) |
| `FluxBattlefieldMapWorldFeatures:OnMapShown` | [L1072](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1072) |
| `FluxBattlefieldMapWorldFeatures:OnMapHidden` | [L1087](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1087) |
| `FluxBattlefieldMapWorldFeatures:SyncIfMapActive` | [L1097](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1097) |

### Battlezonemap/FluxBlizzardMeter.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `FluxBlizzardMeter:IsSupportedClient` | [L123](../../Battlezonemap/FluxBlizzardMeter.lua#L123) |
| `FluxBlizzardMeter:IsAvailable` | [L130](../../Battlezonemap/FluxBlizzardMeter.lua#L130) |
| `FluxBlizzardMeter:IsContentAvailable` | [L139](../../Battlezonemap/FluxBlizzardMeter.lua#L139) |
| `FluxBlizzardMeter:IsEmbedded` | [L149](../../Battlezonemap/FluxBlizzardMeter.lua#L149) |
| `FluxBlizzardMeter:ResetAllSessionsIfOutOfCombat` | [L157](../../Battlezonemap/FluxBlizzardMeter.lua#L157) |
| `DamageMeterSourceEntryMixin.InitDamageMeterSourceEntryMixin.Init` | [L375](../../Battlezonemap/FluxBlizzardMeter.lua#L375) |
| `DamageMeterSpellEntryMixin.InitDamageMeterSpellEntryMixin.Init` | [L384](../../Battlezonemap/FluxBlizzardMeter.lua#L384) |
| `nilifnotDamageMeterSessionWindowMixin.SetSessionDurationthenreturnendDamageMeterSessionWindowMixin.SetSessionDuration` | [L488](../../Battlezonemap/FluxBlizzardMeter.lua#L488) |
| `FluxBlizzardMeter:Embed` | [L1163](../../Battlezonemap/FluxBlizzardMeter.lua#L1163) |
| `dmFrame.ShouldBeShowndmFrame.ShouldBeShown` | [L1210](../../Battlezonemap/FluxBlizzardMeter.lua#L1210) |
| `dmFrame.UpdateShownStatedmFrame.UpdateShownState` | [L1220](../../Battlezonemap/FluxBlizzardMeter.lua#L1220) |
| `FluxBlizzardMeter:SyncGeometryFromLayout` | [L1296](../../Battlezonemap/FluxBlizzardMeter.lua#L1296) |
| `FluxBlizzardMeter:RefreshEmbeddedLayout` | [L1319](../../Battlezonemap/FluxBlizzardMeter.lua#L1319) |
| `FluxBlizzardMeter:Hide` | [L1330](../../Battlezonemap/FluxBlizzardMeter.lua#L1330) |
| `FluxBlizzardMeter:Show` | [L1349](../../Battlezonemap/FluxBlizzardMeter.lua#L1349) |
| `FluxBlizzardMeter:Cleanup` | [L1379](../../Battlezonemap/FluxBlizzardMeter.lua#L1379) |

### Battlezonemap/FluxDetails.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `FluxDetails:GetEffectiveLayoutPresetId` | [L103](../../Battlezonemap/FluxDetails.lua#L103) |
| `FluxDetails:IsDetailsUIReady` | [L137](../../Battlezonemap/FluxDetails.lua#L137) |
| `ApplyLightEmbedChrome` | [L168](../../Battlezonemap/FluxDetails.lua#L168) |
| `ScheduleLightChromeRefresh` | [L184](../../Battlezonemap/FluxDetails.lua#L184) |
| `EnsureDetailsSkinHooks` | [L202](../../Battlezonemap/FluxDetails.lua#L202) |
| `EnsureDetailsEventListener` | [L230](../../Battlezonemap/FluxDetails.lua#L230) |
| `EnsureDetailsMaxWindows` | [L258](../../Battlezonemap/FluxDetails.lua#L258) |
| `tbl.RefreshLinetbl.RefreshLine` | [L361](../../Battlezonemap/FluxDetails.lua#L361) |
| `SuppressDetailsInstanceChrome` | [L381](../../Battlezonemap/FluxDetails.lua#L381) |
| `SuppressDetailsStretchButton` | [L402](../../Battlezonemap/FluxDetails.lua#L402) |
| `w.SetParentw.ClearAllPoints` | [L675](../../Battlezonemap/FluxDetails.lua#L675) |
| `endw.SetPoint` | [L686](../../Battlezonemap/FluxDetails.lua#L686) |
| `endw.SetParent` | [L699](../../Battlezonemap/FluxDetails.lua#L699) |
| `inst.ReajustaGumpendinst.ReajustaGump` | [L840](../../Battlezonemap/FluxDetails.lua#L840) |
| `inst.RestoreMainWindowPositionendinst.RestoreMainWindowPosition` | [L856](../../Battlezonemap/FluxDetails.lua#L856) |
| `inst.RestoreMainWindowPositionNoResizeendinst.RestoreMainWindowPositionNoResize` | [L869](../../Battlezonemap/FluxDetails.lua#L869) |
| `D.RestoreMainWindowPositionD.RestoreMainWindowPosition` | [L888](../../Battlezonemap/FluxDetails.lua#L888) |
| `D.RestoreMainWindowPositionNoResizeD.RestoreMainWindowPositionNoResize` | [L904](../../Battlezonemap/FluxDetails.lua#L904) |
| `D.AtivarInstanciaD.AtivarInstancia` | [L919](../../Battlezonemap/FluxDetails.lua#L919) |
| `FluxDetails:Embed` | [L1403](../../Battlezonemap/FluxDetails.lua#L1403) |
| `FluxDetails:CopyLayoutPreset` | [L1571](../../Battlezonemap/FluxDetails.lua#L1571) |
| `FluxDetails:Hide` | [L1593](../../Battlezonemap/FluxDetails.lua#L1593) |
| `FluxDetails:IsEmbedded` | [L1626](../../Battlezonemap/FluxDetails.lua#L1626) |
| `FluxDetails:ApplyPostLoginState` | [L1633](../../Battlezonemap/FluxDetails.lua#L1633) |
| `FluxDetails:RefreshEmbeddedLayout` | [L1662](../../Battlezonemap/FluxDetails.lua#L1662) |
| `FluxDetails:SyncGeometryFromLayout` | [L1682](../../Battlezonemap/FluxDetails.lua#L1682) |
| `FluxDetails:StabilizeAfterLayoutChange` | [L1715](../../Battlezonemap/FluxDetails.lua#L1715) |
| `FluxDetails:ResetAllDataIfOutOfCombat` | [L1730](../../Battlezonemap/FluxDetails.lua#L1730) |

### Battlezonemap/FluxDetailsForever.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `trueparser.UpdateDamageMeterSwap` | [L116](../../Battlezonemap/FluxDetailsForever.lua#L116) |
| `thenDF.IsAddonApocalypseWow` | [L152](../../Battlezonemap/FluxDetailsForever.lua#L152) |
| `Details:IsUsingBlizzardAPI` | [L157](../../Battlezonemap/FluxDetailsForever.lua#L157) |
| `privateNs.UpdateIsAllowed` | [L164](../../Battlezonemap/FluxDetailsForever.lua#L164) |

### Battlezonemap/FluxDetailsWoWSkinTint.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `FluxDetailsWoWSkinTint.GetPlayerClassRGB` | [L20](../../Battlezonemap/FluxDetailsWoWSkinTint.lua#L20) |
| `FluxDetailsWoWSkinTint.ApplyToInstance` | [L70](../../Battlezonemap/FluxDetailsWoWSkinTint.lua#L70) |
| `FluxDetailsWoWSkinTint.RefreshAllEmbeddedInstances` | [L98](../../Battlezonemap/FluxDetailsWoWSkinTint.lua#L98) |
| `FluxDetailsWoWSkinTint.EnsureInstanceColorHook` | [L109](../../Battlezonemap/FluxDetailsWoWSkinTint.lua#L109) |

### Battlezonemap/FluxMeterLayout.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `FluxMeterLayout.IsDetailsAddonLoaded` | [L152](../../Battlezonemap/FluxMeterLayout.lua#L152) |
| `FluxMeterLayout.HasBlizzardDamageMeterClient` | [L165](../../Battlezonemap/FluxMeterLayout.lua#L165) |
| `FluxMeterLayout.GetMeterBackend` | [L180](../../Battlezonemap/FluxMeterLayout.lua#L180) |
| `FluxMeterLayout.IsBlizzardBackend` | [L190](../../Battlezonemap/FluxMeterLayout.lua#L190) |
| `FluxMeterLayout.IsDetailsBackend` | [L194](../../Battlezonemap/FluxMeterLayout.lua#L194) |
| `FluxMeterLayout.HasMeterBackend` | [L198](../../Battlezonemap/FluxMeterLayout.lua#L198) |
| `FluxMeterLayout.GetMaxPanes` | [L203](../../Battlezonemap/FluxMeterLayout.lua#L203) |
| `FluxMeterLayout.GetBuiltinLabels` | [L332](../../Battlezonemap/FluxMeterLayout.lua#L332) |
| `FluxMeterLayout.NormalizeSlot` | [L664](../../Battlezonemap/FluxMeterLayout.lua#L664) |
| `FluxMeterLayout.NormalizeColFracs` | [L668](../../Battlezonemap/FluxMeterLayout.lua#L668) |
| `FluxMeterLayout.CopyLayout` | [L672](../../Battlezonemap/FluxMeterLayout.lua#L672) |
| `FluxMeterLayout.GetWorkingLayout` | [L676](../../Battlezonemap/FluxMeterLayout.lua#L676) |
| `FluxMeterLayout.GetActiveLayoutId` | [L681](../../Battlezonemap/FluxMeterLayout.lua#L681) |
| `FluxMeterLayout.GetUserLayouts` | [L686](../../Battlezonemap/FluxMeterLayout.lua#L686) |
| `FluxMeterLayout.GetBuiltinCount` | [L691](../../Battlezonemap/FluxMeterLayout.lua#L691) |
| `FluxMeterLayout.ApplyBuiltin` | [L698](../../Battlezonemap/FluxMeterLayout.lua#L698) |
| `FluxMeterLayout.LoadUser` | [L708](../../Battlezonemap/FluxMeterLayout.lua#L708) |
| `FluxMeterLayout.SaveWorkingAsNew` | [L720](../../Battlezonemap/FluxMeterLayout.lua#L720) |
| `FluxMeterLayout.SaveWorkingOverActive` | [L731](../../Battlezonemap/FluxMeterLayout.lua#L731) |
| `FluxMeterLayout.RenameActive` | [L749](../../Battlezonemap/FluxMeterLayout.lua#L749) |
| `FluxMeterLayout.DeleteActive` | [L764](../../Battlezonemap/FluxMeterLayout.lua#L764) |
| `FluxMeterLayout.SetTopColCount` | [L778](../../Battlezonemap/FluxMeterLayout.lua#L778) |
| `FluxMeterLayout.SetBottomColCount` | [L798](../../Battlezonemap/FluxMeterLayout.lua#L798) |
| `FluxMeterLayout.CanSetTopColCount` | [L823](../../Battlezonemap/FluxMeterLayout.lua#L823) |
| `FluxMeterLayout.CanSetBottomColCount` | [L832](../../Battlezonemap/FluxMeterLayout.lua#L832) |
| `FluxMeterLayout.SetSlot` | [L841](../../Battlezonemap/FluxMeterLayout.lua#L841) |
| `FluxMeterLayout.SetTopRowFrac` | [L860](../../Battlezonemap/FluxMeterLayout.lua#L860) |
| `FluxMeterLayout.SetColFracs` | [L865](../../Battlezonemap/FluxMeterLayout.lua#L865) |
| `FluxMeterLayout.SlotIcon` | [L898](../../Battlezonemap/FluxMeterLayout.lua#L898) |
| `FluxMeterLayout.BuildCatalog` | [L1000](../../Battlezonemap/FluxMeterLayout.lua#L1000) |
| `FluxMeterLayout.SlotShortLabel` | [L1115](../../Battlezonemap/FluxMeterLayout.lua#L1115) |
| `FluxMeterLayout.SlotColor` | [L1128](../../Battlezonemap/FluxMeterLayout.lua#L1128) |
| `FluxMeterLayout.CancelPendingWork` | [L1199](../../Battlezonemap/FluxMeterLayout.lua#L1199) |
| `FluxMeterLayout.ReembedQuiet` | [L1229](../../Battlezonemap/FluxMeterLayout.lua#L1229) |
| `FluxMeterLayout.ScheduleReembed` | [L1233](../../Battlezonemap/FluxMeterLayout.lua#L1233) |
| `FluxMeterLayout.IsEditorOpen` | [L1245](../../Battlezonemap/FluxMeterLayout.lua#L1245) |
| `FluxMeterLayout.CloseEditor` | [L1249](../../Battlezonemap/FluxMeterLayout.lua#L1249) |
| `b:SetActive` | [L1587](../../Battlezonemap/FluxMeterLayout.lua#L1587) |
| `f:RefreshPicker` | [L1864](../../Battlezonemap/FluxMeterLayout.lua#L1864) |
| `f:RebuildLibList` | [L1958](../../Battlezonemap/FluxMeterLayout.lua#L1958) |
| `f:RefreshCanvas` | [L2041](../../Battlezonemap/FluxMeterLayout.lua#L2041) |
| `f:Refresh` | [L2148](../../Battlezonemap/FluxMeterLayout.lua#L2148) |
| `FluxMeterLayout.DetachFromHost` | [L2238](../../Battlezonemap/FluxMeterLayout.lua#L2238) |
| `FluxMeterLayout.AttachToHost` | [L2250](../../Battlezonemap/FluxMeterLayout.lua#L2250) |
| `FluxMeterLayout.FitEditorToHost` | [L2303](../../Battlezonemap/FluxMeterLayout.lua#L2303) |
| `FluxMeterLayout.AttachToAceWidget` | [L2333](../../Battlezonemap/FluxMeterLayout.lua#L2333) |
| `FluxMeterLayout.DetachFromAceWidget` | [L2356](../../Battlezonemap/FluxMeterLayout.lua#L2356) |
| `FluxMeterLayout.IsEmbeddedInOptions` | [L2363](../../Battlezonemap/FluxMeterLayout.lua#L2363) |
| `FluxMeterLayout.OpenEditor` | [L2367](../../Battlezonemap/FluxMeterLayout.lua#L2367) |
| `FluxMeterLayout.Init` | [L2393](../../Battlezonemap/FluxMeterLayout.lua#L2393) |

### Battlezonemap/FluxThreat.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `Threat:OnDetailsEvent` | [L139](../../Battlezonemap/FluxThreat.lua#L139) |
| `Threat:UpdateContainers` | [L225](../../Battlezonemap/FluxThreat.lua#L225) |
| `Threat:UpdateRowWidths` | [L231](../../Battlezonemap/FluxThreat.lua#L231) |
| `Threat:HideBars` | [L237](../../Battlezonemap/FluxThreat.lua#L237) |
| `Threat:SizeChanged` | [L425](../../Battlezonemap/FluxThreat.lua#L425) |
| `Threat:RefreshRow` | [L453](../../Battlezonemap/FluxThreat.lua#L453) |
| `Threat:RefreshRows` | [L474](../../Battlezonemap/FluxThreat.lua#L474) |
| `Threat:NewRow` | [L480](../../Battlezonemap/FluxThreat.lua#L480) |
| `Threat:TargetChanged` | [L807](../../Battlezonemap/FluxThreat.lua#L807) |
| `Threat:Start` | [L814](../../Battlezonemap/FluxThreat.lua#L814) |
| `Threat:Stop` | [L820](../../Battlezonemap/FluxThreat.lua#L820) |
| `Threat:Cancel` | [L824](../../Battlezonemap/FluxThreat.lua#L824) |
| `Threat:OnThreatListOrRosterEvent` | [L832](../../Battlezonemap/FluxThreat.lua#L832) |
| `Threat:SyncThreatPollingScript` | [L897](../../Battlezonemap/FluxThreat.lua#L897) |
| `Threat:SetCombatListEvents` | [L904](../../Battlezonemap/FluxThreat.lua#L904) |
| `Threat:OnEvent` | [L920](../../Battlezonemap/FluxThreat.lua#L920) |

### Battlezonemap/FluxWindowFrame.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `FluxWindowFrame:ApplyBottomLiftFromStatusBar` | [L216](../../Battlezonemap/FluxWindowFrame.lua#L216) |
| `FluxWindowFrame:GetFrame` | [L224](../../Battlezonemap/FluxWindowFrame.lua#L224) |
| `FluxWindowFrame:Show` | [L272](../../Battlezonemap/FluxWindowFrame.lua#L272) |
| `FluxWindowFrame:Hide` | [L286](../../Battlezonemap/FluxWindowFrame.lua#L286) |
| `FluxWindowFrame:Toggle` | [L300](../../Battlezonemap/FluxWindowFrame.lua#L300) |
| `FluxWindowFrame:SetSize` | [L311](../../Battlezonemap/FluxWindowFrame.lua#L311) |
| `FluxWindowFrame:SetOffset` | [L327](../../Battlezonemap/FluxWindowFrame.lua#L327) |
| `FluxWindowFrame:GetContentFrame` | [L337](../../Battlezonemap/FluxWindowFrame.lua#L337) |
| `FluxWindowFrame:SetBorderColor` | [L347](../../Battlezonemap/FluxWindowFrame.lua#L347) |
| `FluxWindowFrame:SetBackdropColor` | [L358](../../Battlezonemap/FluxWindowFrame.lua#L358) |
| `FluxWindowFrame:SetClassColor` | [L367](../../Battlezonemap/FluxWindowFrame.lua#L367) |
| `FluxWindowFrame:ShowMeterLayoutMenu` | [L380](../../Battlezonemap/FluxWindowFrame.lua#L380) |
| `FluxWindowFrame:IsMeterEditMode` | [L384](../../Battlezonemap/FluxWindowFrame.lua#L384) |
| `FluxWindowFrame:ExitMeterEditMode` | [L388](../../Battlezonemap/FluxWindowFrame.lua#L388) |
| `FluxWindowFrame:ReembedMeterQuiet` | [L394](../../Battlezonemap/FluxWindowFrame.lua#L394) |
| `FluxWindowFrame:AddTab` | [L669](../../Battlezonemap/FluxWindowFrame.lua#L669) |
| `FluxWindowFrame:SwitchToTab` | [L829](../../Battlezonemap/FluxWindowFrame.lua#L829) |
| `FluxWindowFrame:RemoveTab` | [L883](../../Battlezonemap/FluxWindowFrame.lua#L883) |
| `FluxWindowFrame:GetTabContent` | [L917](../../Battlezonemap/FluxWindowFrame.lua#L917) |
| `FluxWindowFrame:GetActiveTab` | [L922](../../Battlezonemap/FluxWindowFrame.lua#L922) |
| `FluxWindowFrame:GetManagedTabNames` | [L993](../../Battlezonemap/FluxWindowFrame.lua#L993) |
| `FluxWindowFrame:GetTabOrder` | [L997](../../Battlezonemap/FluxWindowFrame.lua#L997) |
| `FluxWindowFrame:IsTabEnabled` | [L1002](../../Battlezonemap/FluxWindowFrame.lua#L1002) |
| `FluxWindowFrame:GetFirstEnabledTab` | [L1011](../../Battlezonemap/FluxWindowFrame.lua#L1011) |
| `FluxWindowFrame:CountEnabledTabs` | [L1025](../../Battlezonemap/FluxWindowFrame.lua#L1025) |
| `FluxWindowFrame:RepositionTabs` | [L1036](../../Battlezonemap/FluxWindowFrame.lua#L1036) |
| `FluxWindowFrame:ApplyTabConfig` | [L1098](../../Battlezonemap/FluxWindowFrame.lua#L1098) |
| `FluxWindowFrame:ReleaseMinimapEmbedIfMapDisabled` | [L1105](../../Battlezonemap/FluxWindowFrame.lua#L1105) |
| `FluxWindowFrame:SetTabEnabled` | [L1125](../../Battlezonemap/FluxWindowFrame.lua#L1125) |
| `FluxWindowFrame:MoveTabInOrder` | [L1149](../../Battlezonemap/FluxWindowFrame.lua#L1149) |
| `FluxWindowFrame:SetTabOrder` | [L1176](../../Battlezonemap/FluxWindowFrame.lua#L1176) |
| `FluxWindowFrame:ResetTabConfigDefaults` | [L1206](../../Battlezonemap/FluxWindowFrame.lua#L1206) |
| `FluxWindowFrame:GetMeterLayoutConfig` | [L1217](../../Battlezonemap/FluxWindowFrame.lua#L1217) |
| `FluxWindowFrame:GetMeterPresetIndex` | [L1236](../../Battlezonemap/FluxWindowFrame.lua#L1236) |
| `FluxWindowFrame:SetMeterPresetIndex` | [L1242](../../Battlezonemap/FluxWindowFrame.lua#L1242) |
| `FluxWindowFrame_RefreshTabAccent` | [L1758](../../Battlezonemap/FluxWindowFrame.lua#L1758) |

### Binding/Core/Action.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Action.SpellDataCached` | [L42](../../Binding/Core/Action.lua#L42) |
| `Action.RequestSpellData` | [L59](../../Binding/Core/Action.lua#L59) |
| `Action.NoteSpellDataLoaded` | [L74](../../Binding/Core/Action.lua#L74) |
| `Action.Spell` | [L115](../../Binding/Core/Action.lua#L115) |
| `Action.PetSpell` | [L131](../../Binding/Core/Action.lua#L131) |
| `Action.IsPetSpell` | [L140](../../Binding/Core/Action.lua#L140) |
| `Action.Item` | [L144](../../Binding/Core/Action.lua#L144) |
| `Action.EquipSlot` | [L152](../../Binding/Core/Action.lua#L152) |
| `Action.Macro` | [L158](../../Binding/Core/Action.lua#L158) |
| `Action.Extra` | [L164](../../Binding/Core/Action.lua#L164) |
| `Action.FromCursor` | [L175](../../Binding/Core/Action.lua#L175) |
| `Action.FromSpellbookRow` | [L240](../../Binding/Core/Action.lua#L240) |
| `Action.SpellNameKey` | [L273](../../Binding/Core/Action.lua#L273) |
| `Action.ShouldOfferRankSync` | [L289](../../Binding/Core/Action.lua#L289) |
| `Action.IsRankSyncByName` | [L293](../../Binding/Core/Action.lua#L293) |
| `Action.Key` | [L303](../../Binding/Core/Action.lua#L303) |
| `Action.FamilyKey` | [L320](../../Binding/Core/Action.lua#L320) |
| `Action.SlotActionKey` | [L330](../../Binding/Core/Action.lua#L330) |
| `Action.KeysMatch` | [L341](../../Binding/Core/Action.lua#L341) |
| `Action.GetRankSubtext` | [L361](../../Binding/Core/Action.lua#L361) |
| `Action.GetNameWithRank` | [L369](../../Binding/Core/Action.lua#L369) |
| `Action.SetRankSyncByName` | [L448](../../Binding/Core/Action.lua#L448) |
| `Action.RemoveRank` | [L543](../../Binding/Core/Action.lua#L543) |
| `Action.GetName` | [L589](../../Binding/Core/Action.lua#L589) |
| `Action.GetIcon` | [L626](../../Binding/Core/Action.lua#L626) |
| `Action.InvalidateSpellBookCache` | [L715](../../Binding/Core/Action.lua#L715) |
| `Action.IsAvailable` | [L732](../../Binding/Core/Action.lua#L732) |
| `Action.GetCount` | [L803](../../Binding/Core/Action.lua#L803) |
| `Action.MacroToken` | [L822](../../Binding/Core/Action.lua#L822) |

### Binding/Core/Apply.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `FluxBinding.BindingHasLivePlace` | [L307](../../Binding/Core/Apply.lua#L307) |
| `FluxBinding.IsBindingRespecRelevant` | [L381](../../Binding/Core/Apply.lua#L381) |
| `FluxBinding.PrunePristineBindings` | [L388](../../Binding/Core/Apply.lua#L388) |
| `_G.FluxActionBarPeekSlotOccupancyChanged` | [L1067](../../Binding/Core/Apply.lua#L1067) |
| `_G.FluxActionBarPeekSlotOccupancyPrevious` | [L1087](../../Binding/Core/Apply.lua#L1087) |
| `_G.FluxActionBarConsumeOccupancyDirty` | [L1095](../../Binding/Core/Apply.lua#L1095) |
| `_G.FluxActionBarConsumeAllOccupancyDirty` | [L1104](../../Binding/Core/Apply.lua#L1104) |
| `_G.FluxActionBarSeedSlotOccupancyCache` | [L1112](../../Binding/Core/Apply.lua#L1112) |
| `_G.FluxActionBarPeekSlotOccupancy_ClearCache` | [L1123](../../Binding/Core/Apply.lua#L1123) |
| `FluxBinding.HasActiveWork` | [L2484](../../Binding/Core/Apply.lua#L2484) |
| `FluxBinding.GetActiveWorkInfo` | [L2497](../../Binding/Core/Apply.lua#L2497) |
| `FluxBinding.RequestApplyAll` | [L2515](../../Binding/Core/Apply.lua#L2515) |
| `FluxBinding.NotifyOccupancyChanged` | [L2536](../../Binding/Core/Apply.lua#L2536) |
| `FluxBinding.NotifyBarSlotChanged` | [L2585](../../Binding/Core/Apply.lua#L2585) |
| `FluxBinding.NotifyBarSlotsChanged` | [L2594](../../Binding/Core/Apply.lua#L2594) |
| `FluxBinding.NotifyBindingChanged` | [L2608](../../Binding/Core/Apply.lua#L2608) |
| `FluxBinding.NotifyBindingsAvailabilityChanged` | [L2625](../../Binding/Core/Apply.lua#L2625) |
| `FluxBinding.NormalizeChord` | [L2633](../../Binding/Core/Apply.lua#L2633) |
| `FluxBinding.FindColumnForChord` | [L2637](../../Binding/Core/Apply.lua#L2637) |
| `FluxBinding.RegisterApplied` | [L2641](../../Binding/Core/Apply.lua#L2641) |
| `FluxBinding.GetLastApplyStats` | [L2645](../../Binding/Core/Apply.lua#L2645) |
| `FluxBinding.CanUseMultiCastExtras` | [L2652](../../Binding/Core/Apply.lua#L2652) |
| `FluxBinding.GetPeersForChord` | [L2798](../../Binding/Core/Apply.lua#L2798) |
| `FluxBinding.GetEditorOverlap` | [L2848](../../Binding/Core/Apply.lua#L2848) |
| `FluxBinding.GetPreviewForBinding` | [L2919](../../Binding/Core/Apply.lua#L2919) |
| `FluxBinding.Debug` | [L3030](../../Binding/Core/Apply.lua#L3030) |

### Binding/Core/BindingTooltip.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `BT.AppendForButton` | [L382](../../Binding/Core/BindingTooltip.lua#L382) |
| `BT.OnLabTooltip` | [L673](../../Binding/Core/BindingTooltip.lua#L673) |
| `BT.InstallHooks` | [L705](../../Binding/Core/BindingTooltip.lua#L705) |

### Binding/Core/ChordMap.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `ChordMap.Parse` | [L40](../../Binding/Core/ChordMap.lua#L40) |
| `ChordMap.Normalize` | [L63](../../Binding/Core/ChordMap.lua#L63) |
| `ChordMap.IsMouseChord` | [L74](../../Binding/Core/ChordMap.lua#L74) |
| `ChordMap.Invalidate` | [L106](../../Binding/Core/ChordMap.lua#L106) |
| `ChordMap.FindColumnForChord` | [L110](../../Binding/Core/ChordMap.lua#L110) |
| `ChordMap.Route` | [L125](../../Binding/Core/ChordMap.lua#L125) |
| `ChordMap.SlotsForChord` | [L188](../../Binding/Core/ChordMap.lua#L188) |

### Binding/Core/Conditions.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Conditions.CanOfferModAlt` | [L88](../../Binding/Core/Conditions.lua#L88) |
| `Conditions.CanOfferModShiftCtrl` | [L95](../../Binding/Core/Conditions.lua#L95) |
| `Conditions.ResolvedModFlags` | [L115](../../Binding/Core/Conditions.lua#L115) |
| `Conditions.SubHasModCondition` | [L133](../../Binding/Core/Conditions.lua#L133) |
| `Conditions.SanitizeModLoadOptions` | [L139](../../Binding/Core/Conditions.lua#L139) |
| `Conditions.MacroTokensForSub` | [L159](../../Binding/Core/Conditions.lua#L159) |
| `Conditions.SubHasMacroCondition` | [L189](../../Binding/Core/Conditions.lua#L189) |
| `Conditions.SummarizeSub` | [L198](../../Binding/Core/Conditions.lua#L198) |
| `Conditions.SubPassesLoadGates` | [L469](../../Binding/Core/Conditions.lua#L469) |
| `Conditions.IsActive` | [L514](../../Binding/Core/Conditions.lua#L514) |
| `Conditions.IsParked` | [L541](../../Binding/Core/Conditions.lua#L541) |
| `Conditions.DiffAvailability` | [L553](../../Binding/Core/Conditions.lua#L553) |
| `Conditions.InvalidateAvailability` | [L573](../../Binding/Core/Conditions.lua#L573) |
| `Conditions.EnsureInventoryListener` | [L584](../../Binding/Core/Conditions.lua#L584) |

### Binding/Core/DB.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `DB.NewFormSubProfile` | [L56](../../Binding/Core/DB.lua#L56) |
| `DB.NewBinding` | [L121](../../Binding/Core/DB.lua#L121) |
| `DB.SetDocumentOverride` | [L161](../../Binding/Core/DB.lua#L161) |
| `DB.GetDocumentOverride` | [L170](../../Binding/Core/DB.lua#L170) |
| `DB.IsOverrideActive` | [L174](../../Binding/Core/DB.lua#L174) |
| `DB.Ensure` | [L178](../../Binding/Core/DB.lua#L178) |
| `DB.EnsureLive` | [L192](../../Binding/Core/DB.lua#L192) |
| `DB.IsReady` | [L205](../../Binding/Core/DB.lua#L205) |
| `DB.Get` | [L209](../../Binding/Core/DB.lua#L209) |
| `DB.All` | [L214](../../Binding/Core/DB.lua#L214) |
| `DB.SortedUids` | [L219](../../Binding/Core/DB.lua#L219) |
| `DB.Add` | [L229](../../Binding/Core/DB.lua#L229) |
| `DB.Remove` | [L242](../../Binding/Core/DB.lua#L242) |
| `DB.EnsureFormSub` | [L264](../../Binding/Core/DB.lua#L264) |
| `DB.NormalizeMacroExtras` | [L300](../../Binding/Core/DB.lua#L300) |
| `DB.IsMacroExtraAvailable` | [L322](../../Binding/Core/DB.lua#L322) |
| `DB.FilterMacroExtras` | [L350](../../Binding/Core/DB.lua#L350) |
| `DB.GetMacroExtras` | [L368](../../Binding/Core/DB.lua#L368) |
| `DB.ClampMainCastIndex` | [L374](../../Binding/Core/DB.lua#L374) |
| `DB.GetMainCastIndex` | [L388](../../Binding/Core/DB.lua#L388) |
| `DB.SetMainCastIndex` | [L396](../../Binding/Core/DB.lua#L396) |
| `DB.SetMacroExtras` | [L406](../../Binding/Core/DB.lua#L406) |
| `DB.SplitMacroExtrasAroundMain` | [L416](../../Binding/Core/DB.lua#L416) |
| `DB.BuildMultiCastOrderRows` | [L432](../../Binding/Core/DB.lua#L432) |
| `DB.ApplyMultiCastOrderRows` | [L456](../../Binding/Core/DB.lua#L456) |
| `DB.GetMacroExtraIcon` | [L478](../../Binding/Core/DB.lua#L478) |
| `DB.GetMacroExtraLabel` | [L509](../../Binding/Core/DB.lua#L509) |
| `DB.MacroExtraMatchesAction` | [L553](../../Binding/Core/DB.lua#L553) |
| `DB.MacroExtraToAction` | [L578](../../Binding/Core/DB.lua#L578) |
| `DB.DefaultBadgeOpts` | [L597](../../Binding/Core/DB.lua#L597) |
| `DB.FindBindingForMacroExtra` | [L613](../../Binding/Core/DB.lua#L613) |
| `DB.GetBadgeOptsForMacroExtra` | [L674](../../Binding/Core/DB.lua#L674) |
| `DB.FindBindingsUsingMacroExtra` | [L690](../../Binding/Core/DB.lua#L690) |
| `DB.GetMacroExtrasDisplay` | [L727](../../Binding/Core/DB.lua#L727) |
| `DB.GetFormSub` | [L750](../../Binding/Core/DB.lua#L750) |
| `DB.HasDedicatedFormSub` | [L755](../../Binding/Core/DB.lua#L755) |
| `DB.IsCustomActiveForForm` | [L763](../../Binding/Core/DB.lua#L763) |
| `DB.DeepCopyFormSub` | [L777](../../Binding/Core/DB.lua#L777) |
| `DB.CopyFormSub` | [L789](../../Binding/Core/DB.lua#L789) |
| `DB.GetChordStackOrder` | [L849](../../Binding/Core/DB.lua#L849) |
| `DB.GetBadgeCornerOrder` | [L853](../../Binding/Core/DB.lua#L853) |
| `DB.SetChordStackOrder` | [L857](../../Binding/Core/DB.lua#L857) |
| `DB.SetBadgeCornerOrder` | [L861](../../Binding/Core/DB.lua#L861) |
| `DB.IsFormPageEnabled` | [L869](../../Binding/Core/DB.lua#L869) |
| `DB.SetFormPageEnabled` | [L874](../../Binding/Core/DB.lua#L874) |
| `DB.UidsForActionKey` | [L892](../../Binding/Core/DB.lua#L892) |
| `DB.FindUidForPlace` | [L910](../../Binding/Core/DB.lua#L910) |
| `DB.FindUnplacedUidForActionKey` | [L949](../../Binding/Core/DB.lua#L949) |
| `DB.GetRankSyncNames` | [L962](../../Binding/Core/DB.lua#L962) |
| `DB.IsRankSyncName` | [L966](../../Binding/Core/DB.lua#L966) |
| `DB.SetRankSyncName` | [L971](../../Binding/Core/DB.lua#L971) |

### Binding/Core/Engraving.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Engraving.Refresh` | [L117](../../Binding/Core/Engraving.lua#L117) |
| `Engraving.ResolveLearnedSpellId` | [L129](../../Binding/Core/Engraving.lua#L129) |
| `Engraving.MapSavedRuneId` | [L157](../../Binding/Core/Engraving.lua#L157) |
| `Engraving.IsEquippedRuneAbility` | [L173](../../Binding/Core/Engraving.lua#L173) |
| `Engraving.IsOwnedRuneAbility` | [L180](../../Binding/Core/Engraving.lua#L180) |
| `Engraving.IsRuneAbilitySpell` | [L191](../../Binding/Core/Engraving.lua#L191) |
| `Engraving.ResolveCastIdAndName` | [L197](../../Binding/Core/Engraving.lua#L197) |
| `Engraving.MigrateBindingDB` | [L216](../../Binding/Core/Engraving.lua#L216) |

### Binding/Core/Forms.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Forms.Invalidate` | [L91](../../Binding/Core/Forms.lua#L91) |
| `Forms.GetTokens` | [L97](../../Binding/Core/Forms.lua#L97) |
| `Forms.GetTokenInfo` | [L101](../../Binding/Core/Forms.lua#L101) |
| `Forms.HasMultipleForms` | [L106](../../Binding/Core/Forms.lua#L106) |
| `Forms.PageForToken` | [L112](../../Binding/Core/Forms.lua#L112) |
| `Forms.MacroCondition` | [L122](../../Binding/Core/Forms.lua#L122) |
| `Forms.TokenHasMacroCondition` | [L153](../../Binding/Core/Forms.lua#L153) |
| `Forms.HasMacroConditionForms` | [L159](../../Binding/Core/Forms.lua#L159) |
| `Forms.ConditionGroupsForTokens` | [L175](../../Binding/Core/Forms.lua#L175) |
| `Forms.GetCurrentToken` | [L219](../../Binding/Core/Forms.lua#L219) |
| `Forms.GetTokenIcon` | [L243](../../Binding/Core/Forms.lua#L243) |

### Binding/Core/MacroFactory.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Factory.MacrotextMax` | [L34](../../Binding/Core/MacroFactory.lua#L34) |
| `Factory.IsFactoryMouseover` | [L606](../../Binding/Core/MacroFactory.lua#L606) |
| `Factory.IdleMacroText` | [L628](../../Binding/Core/MacroFactory.lua#L628) |
| `Factory.HasPeerOverlay` | [L689](../../Binding/Core/MacroFactory.lua#L689) |
| `Factory.NeedsHiddenClick` | [L705](../../Binding/Core/MacroFactory.lua#L705) |
| `Factory.StripOverlayMode` | [L749](../../Binding/Core/MacroFactory.lua#L749) |
| `Factory.BuildForward` | [L962](../../Binding/Core/MacroFactory.lua#L962) |
| `Factory.BuildHover` | [L1055](../../Binding/Core/MacroFactory.lua#L1055) |
| `Factory.BuildStaticBadge` | [L1072](../../Binding/Core/MacroFactory.lua#L1072) |
| `Factory.BuildReverse` | [L1120](../../Binding/Core/MacroFactory.lua#L1120) |

### Binding/Core/Placement.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Placement.PlaceId` | [L237](../../Binding/Core/Placement.lua#L237) |
| `Placement.CatalogBarSlotSet` | [L355](../../Binding/Core/Placement.lua#L355) |
| `Placement.DescribeBarSlot` | [L565](../../Binding/Core/Placement.lua#L565) |
| `Placement.FormatBarSlots` | [L706](../../Binding/Core/Placement.lua#L706) |
| `Placement.IndexExtra` | [L1803](../../Binding/Core/Placement.lua#L1803) |
| `Placement.IndexStance` | [L1816](../../Binding/Core/Placement.lua#L1816) |
| `Placement.IndexMultiCast` | [L1957](../../Binding/Core/Placement.lua#L1957) |
| `Placement.CollectForEntry` | [L2040](../../Binding/Core/Placement.lua#L2040) |
| `Placement.FormatPlaces` | [L2056](../../Binding/Core/Placement.lua#L2056) |
| `Placement.PrimaryChord` | [L2074](../../Binding/Core/Placement.lua#L2074) |
| `Placement.LabelForPlaceId` | [L2091](../../Binding/Core/Placement.lua#L2091) |
| `Placement.ChordForPlaceId` | [L2145](../../Binding/Core/Placement.lua#L2145) |
| `Placement.PlaceActionOnSlot` | [L2250](../../Binding/Core/Placement.lua#L2250) |
| `Placement.TryPlaceActionOnChord` | [L2312](../../Binding/Core/Placement.lua#L2312) |

### Binding/Core/PushPress.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `PushPress.ReleaseIfUp` | [L370](../../Binding/Core/PushPress.lua#L370) |
| `PushPress.ClearAll` | [L382](../../Binding/Core/PushPress.lua#L382) |
| `PushPress.HookButton` | [L488](../../Binding/Core/PushPress.lua#L488) |
| `PushPress.EnsureBarButtonPushHooks` | [L556](../../Binding/Core/PushPress.lua#L556) |
| `PushPress.HookKeyer` | [L569](../../Binding/Core/PushPress.lua#L569) |
| `PushPress.WakeUfHoverFromUnitFrame` | [L752](../../Binding/Core/PushPress.lua#L752) |
| `PushPress.ParkUfHoverFromUnitFrame` | [L758](../../Binding/Core/PushPress.lua#L758) |
| `PushPress.WipeUfHover` | [L765](../../Binding/Core/PushPress.lua#L765) |
| `PushPress.RegisterUfHover` | [L771](../../Binding/Core/PushPress.lua#L771) |
| `PushPress.BindButton` | [L807](../../Binding/Core/PushPress.lua#L807) |
| `PushPress.OnApplyComplete` | [L826](../../Binding/Core/PushPress.lua#L826) |

### Binding/Core/SecurePool.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Pool.Acquire` | [L36](../../Binding/Core/SecurePool.lua#L36) |
| `Pool.ArmMacroDelegate` | [L81](../../Binding/Core/SecurePool.lua#L81) |
| `Pool.Retire` | [L117](../../Binding/Core/SecurePool.lua#L117) |
| `Pool.GetStats` | [L125](../../Binding/Core/SecurePool.lua#L125) |

### Binding/Core/SpellLibrary.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `SpellLibrary.GetSpellbookSpells` | [L321](../../Binding/Core/SpellLibrary.lua#L321) |
| `SpellLibrary.InvalidatePetAbilityGate` | [L407](../../Binding/Core/SpellLibrary.lua#L407) |
| `SpellLibrary.PlayerCanUsePetAbilities` | [L444](../../Binding/Core/SpellLibrary.lua#L444) |
| `SpellLibrary.IsPetAbilitySpell` | [L595](../../Binding/Core/SpellLibrary.lua#L595) |
| `SpellLibrary.RememberPetAbilitySpell` | [L610](../../Binding/Core/SpellLibrary.lua#L610) |
| `SpellLibrary.SeedPetAbilitiesFromBindings` | [L619](../../Binding/Core/SpellLibrary.lua#L619) |
| `SpellLibrary.GetPetSpellbookSpells` | [L631](../../Binding/Core/SpellLibrary.lua#L631) |
| `SpellLibrary.PruneSpellRanks` | [L725](../../Binding/Core/SpellLibrary.lua#L725) |
| `SpellLibrary.GetRelevantItems` | [L841](../../Binding/Core/SpellLibrary.lua#L841) |
| `SpellLibrary.GetBoundMacros` | [L885](../../Binding/Core/SpellLibrary.lua#L885) |
| `SpellLibrary.IndexBars` | [L937](../../Binding/Core/SpellLibrary.lua#L937) |
| `SpellLibrary.FormatBarSlots` | [L1001](../../Binding/Core/SpellLibrary.lua#L1001) |
| `SpellLibrary.GetCatalog` | [L1064](../../Binding/Core/SpellLibrary.lua#L1064) |
| `SpellLibrary.CoalescePetCatalogEntries` | [L1281](../../Binding/Core/SpellLibrary.lua#L1281) |
| `SpellLibrary.ExpandByPlace` | [L1333](../../Binding/Core/SpellLibrary.lua#L1333) |
| `SpellLibrary.AppendDraftInstances` | [L1424](../../Binding/Core/SpellLibrary.lua#L1424) |
| `SpellLibrary.GroupByTab` | [L1509](../../Binding/Core/SpellLibrary.lua#L1509) |

### Binding/Input/FluxMouseoverKeybind.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `owner.PowerBarthenreturnfalseendreturntrueendWrapHovercastMouseChildren` | [L1140](../../Binding/Input/FluxMouseoverKeybind.lua#L1140) |
| `FluxMouseoverKeybind:HasHoverRoutingActive` | [L1711](../../Binding/Input/FluxMouseoverKeybind.lua#L1711) |
| `FluxMouseoverKeybind:IsHovercastPeekMouseContext` | [L1715](../../Binding/Input/FluxMouseoverKeybind.lua#L1715) |
| `FluxMouseoverKeybind:RegisterFrame` | [L1729](../../Binding/Input/FluxMouseoverKeybind.lua#L1729) |
| `FluxMouseoverKeybind:UnregisterBlizzardCompactRaidFrames` | [L1735](../../Binding/Input/FluxMouseoverKeybind.lua#L1735) |
| `FluxMouseoverKeybind:RefreshKeybinds` | [L1767](../../Binding/Input/FluxMouseoverKeybind.lua#L1767) |
| `FluxMouseoverKeybind:ReapplyAllRegisteredFrames` | [L1774](../../Binding/Input/FluxMouseoverKeybind.lua#L1774) |
| `FluxMouseoverKeybind:SetUfHoverRouting` | [L1783](../../Binding/Input/FluxMouseoverKeybind.lua#L1783) |
| `FluxMouseoverKeybind:SetSpellHoverKeys` | [L1812](../../Binding/Input/FluxMouseoverKeybind.lua#L1812) |
| `FluxMouseoverKeybind:FlushPendingHoverRouting` | [L1846](../../Binding/Input/FluxMouseoverKeybind.lua#L1846) |
| `FluxMouseoverKeybind:HasPendingHoverRouting` | [L1861](../../Binding/Input/FluxMouseoverKeybind.lua#L1861) |
| `FluxMouseoverKeybind:DebugRouting` | [L1865](../../Binding/Input/FluxMouseoverKeybind.lua#L1865) |
| `end_G.FluxMouseoverKeybind_DebugRouting` | [L1904](../../Binding/Input/FluxMouseoverKeybind.lua#L1904) |
| `FluxMouseoverKeybind_G.FluxRaidRegisterAllMouseoverKeybindFrames` | [L1911](../../Binding/Input/FluxMouseoverKeybind.lua#L1911) |
| `headerClique.UpdateRegisteredClicks` | [L1942](../../Binding/Input/FluxMouseoverKeybind.lua#L1942) |

### Binding/Respec.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `_G.FluxSpellBindings_CaptureDocSnapshot` | [L185](../../Binding/Respec.lua#L185) |
| `_G.FluxSpellBindings_CancelPendingApply` | [L360](../../Binding/Respec.lua#L360) |
| `_G.FluxSpellBindings_EmptySnapshot` | [L366](../../Binding/Respec.lua#L366) |
| `_G.FluxSpellBindings_CaptureSnapshot` | [L379](../../Binding/Respec.lua#L379) |
| `_G.FluxSpellBindings_MatchesSnapshot` | [L386](../../Binding/Respec.lua#L386) |
| `_G.FluxSpellBindings_IsLegacySnapshot` | [L398](../../Binding/Respec.lua#L398) |
| `_G.FluxSpellBindings_IsV3Snapshot` | [L406](../../Binding/Respec.lua#L406) |
| `_G.FluxSpellBindings_CountBoundSpells` | [L413](../../Binding/Respec.lua#L413) |
| `_G.FluxSpellBindings_CountKeyedBindings` | [L425](../../Binding/Respec.lua#L425) |
| `_G.FluxSpellBindings_CountCustomizedBindings` | [L439](../../Binding/Respec.lua#L439) |
| `_G.FluxSpellBindings_ApplySnapshot` | [L454](../../Binding/Respec.lua#L454) |

### Binding/UI/Browser/Core.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Browser.TryListMouseWheel` | [L148](../../Binding/UI/Browser/Core.lua#L148) |
| `end_G.FluxBindingBrowser_TryListMouseWheel` | [L158](../../Binding/UI/Browser/Core.lua#L158) |
| `Browser.TryTabMouseWheel` | [L163](../../Binding/UI/Browser/Core.lua#L163) |
| `thenreturntrueendendreturnfalseend_G.FluxBindingBrowser_TryTabMouseWheel` | [L197](../../Binding/UI/Browser/Core.lua#L197) |
| `Browser.ActivateLiveSource` | [L725](../../Binding/UI/Browser/Core.lua#L725) |
| `Browser.ActivateProfilePreview` | [L729](../../Binding/UI/Browser/Core.lua#L729) |
| `Browser.PersistPreview` | [L777](../../Binding/UI/Browser/Core.lua#L777) |
| `Browser.UpdatePreviewNote` | [L806](../../Binding/UI/Browser/Core.lua#L806) |
| `Browser.SelectAction` | [L1186](../../Binding/UI/Browser/Core.lua#L1186) |
| `endreturntrueend_G.FluxBindingBrowser_SelectAction` | [L1410](../../Binding/UI/Browser/Core.lua#L1410) |
| `Browser.QueueOpenArg` | [L1415](../../Binding/UI/Browser/Core.lua#L1415) |
| `Browser.ConsumePendingOpen` | [L1421](../../Binding/UI/Browser/Core.lua#L1421) |
| `Browser.RefreshList` | [L1463](../../Binding/UI/Browser/Core.lua#L1463) |
| `endend_G.FluxBindingBrowser_Refresh` | [L1533](../../Binding/UI/Browser/Core.lua#L1533) |
| `endend_G.FluxBindingBrowser_OnEditorCommit` | [L1537](../../Binding/UI/Browser/Core.lua#L1537) |
| `Browser.Show` | [L1916](../../Binding/UI/Browser/Core.lua#L1916) |
| `Browser.Hide` | [L1960](../../Binding/UI/Browser/Core.lua#L1960) |
| `Browser.AttachToAceWidget` | [L1987](../../Binding/UI/Browser/Core.lua#L1987) |
| `Browser.FitToHost` | [L2013](../../Binding/UI/Browser/Core.lua#L2013) |
| `Browser.OnHostResized` | [L2030](../../Binding/UI/Browser/Core.lua#L2030) |
| `Browser.DetachFromAceWidget` | [L2093](../../Binding/UI/Browser/Core.lua#L2093) |
| `end_G.FluxBindingBrowser_Attach` | [L2098](../../Binding/UI/Browser/Core.lua#L2098) |
| `end_G.FluxBindingBrowser_Detach` | [L2102](../../Binding/UI/Browser/Core.lua#L2102) |
| `end_G.FluxBindingBrowser_OnHostResized` | [L2106](../../Binding/UI/Browser/Core.lua#L2106) |
| `Browser.IsShown` | [L2110](../../Binding/UI/Browser/Core.lua#L2110) |
| `Browser.AddTab` | [L2115](../../Binding/UI/Browser/Core.lua#L2115) |

### Binding/UI/Editor/Chrome.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Editor.BuildToolbar` | [L73](../../Binding/UI/Editor/Chrome.lua#L73) |
| `Editor.BuildSharedKeyRow` | [L319](../../Binding/UI/Editor/Chrome.lua#L319) |
| `Editor.BuildFormStrip` | [L544](../../Binding/UI/Editor/Chrome.lua#L544) |

### Binding/UI/Editor/Core.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Editor.IsEmbedded` | [L47](../../Binding/UI/Editor/Core.lua#L47) |
| `Editor.IsStancePlace` | [L82](../../Binding/UI/Editor/Core.lua#L82) |
| `Editor.IsUtilityPlace` | [L90](../../Binding/UI/Editor/Core.lua#L90) |
| `Editor.IsConsumableExtraPlace` | [L100](../../Binding/UI/Editor/Core.lua#L100) |
| `Editor.IsExtraButtonPlace` | [L121](../../Binding/UI/Editor/Core.lua#L121) |
| `Editor.SupportsBindingTabs` | [L141](../../Binding/UI/Editor/Core.lua#L141) |
| `Editor.SupportsBindingInstances` | [L158](../../Binding/UI/Editor/Core.lua#L158) |
| `Editor.SupportsKeyEditor` | [L166](../../Binding/UI/Editor/Core.lua#L166) |
| `Editor.GetBinding` | [L180](../../Binding/UI/Editor/Core.lua#L180) |
| `Editor.GetSub` | [L187](../../Binding/UI/Editor/Core.lua#L187) |
| `Editor.EnsureEditableSub` | [L200](../../Binding/UI/Editor/Core.lua#L200) |
| `Editor.Redraw` | [L223](../../Binding/UI/Editor/Core.lua#L223) |
| `Editor.Commit` | [L237](../../Binding/UI/Editor/Core.lua#L237) |
| `Editor.SyncAfterPrune` | [L268](../../Binding/UI/Editor/Core.lua#L268) |
| `Editor.PruneOrphans` | [L324](../../Binding/UI/Editor/Core.lua#L324) |
| `Editor.SetSubject` | [L388](../../Binding/UI/Editor/Core.lua#L388) |
| `Editor.EnsureBindingRow` | [L479](../../Binding/UI/Editor/Core.lua#L479) |
| `Editor.AddInstance` | [L515](../../Binding/UI/Editor/Core.lua#L515) |
| `Editor.GetInheritedChord` | [L531](../../Binding/UI/Editor/Core.lua#L531) |
| `Editor.IsExtraSystemKeyLocked` | [L547](../../Binding/UI/Editor/Core.lua#L547) |
| `Editor.SubjectHasPhysicalPlace` | [L576](../../Binding/UI/Editor/Core.lua#L576) |
| `Editor.RefreshInheritedChord` | [L621](../../Binding/UI/Editor/Core.lua#L621) |
| `Editor.SetInheritWatchEnabled` | [L714](../../Binding/UI/Editor/Core.lua#L714) |
| `Editor.RemoveInstance` | [L729](../../Binding/UI/Editor/Core.lua#L729) |
| `Editor.AcceptCursorSubject` | [L767](../../Binding/UI/Editor/Core.lua#L767) |
| `Editor.GetContentRoot` | [L798](../../Binding/UI/Editor/Core.lua#L798) |
| `Editor.AttachHost` | [L827](../../Binding/UI/Editor/Core.lua#L827) |
| `Editor.DetachHost` | [L871](../../Binding/UI/Editor/Core.lua#L871) |
| `Editor.Rebuild` | [L896](../../Binding/UI/Editor/Core.lua#L896) |
| `_G.FluxSpellBindingEditor_Open` | [L1022](../../Binding/UI/Editor/Core.lua#L1022) |
| `_G.FluxSpellBindingEditor_ReloadLiveSession` | [L1068](../../Binding/UI/Editor/Core.lua#L1068) |
| `Editor.OpenSharedPeer` | [L1084](../../Binding/UI/Editor/Core.lua#L1084) |
| `Editor.OpenInHost` | [L1119](../../Binding/UI/Editor/Core.lua#L1119) |

### Binding/UI/Editor/Panels.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `falsescroll.FixScroll` | [L78](../../Binding/UI/Editor/Panels.lua#L78) |
| `nilendscroll.MoveScroll` | [L123](../../Binding/UI/Editor/Panels.lua#L123) |
| `Editor.BuildTabs` | [L147](../../Binding/UI/Editor/Panels.lua#L147) |
| `Editor.BuildCastPanel` | [L261](../../Binding/UI/Editor/Panels.lua#L261) |
| `Editor.BuildMultiCastPanel` | [L820](../../Binding/UI/Editor/Panels.lua#L820) |
| `Editor.BuildTargetsPanel` | [L955](../../Binding/UI/Editor/Panels.lua#L955) |
| `Editor.BuildConditionsPanel` | [L1114](../../Binding/UI/Editor/Panels.lua#L1114) |
| `Editor.BuildFormsPanel` | [L1323](../../Binding/UI/Editor/Panels.lua#L1323) |
| `Editor.BuildStatusPanel` | [L1506](../../Binding/UI/Editor/Panels.lua#L1506) |
| `Editor.BuildBadgesPanel` | [L1808](../../Binding/UI/Editor/Panels.lua#L1808) |

### Binding/UI/Editor/Theme.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Theme.ApplyAceFrame` | [L6](../../Binding/UI/Editor/Theme.lua#L6) |
| `Theme.ApplyCompactLabelFont` | [L59](../../Binding/UI/Editor/Theme.lua#L59) |

### Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `methods:OnAcquire` | [L29](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua#L29) |
| `methods:OnRelease` | [L38](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua#L38) |
| `methods:SetDisabled` | [L44](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua#L44) |
| `methods:SetLabel` | [L60](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua#L60) |
| `methods:SetText` | [L80](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua#L80) |
| `methods:SetList` | [L84](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua#L84) |
| `methods:SetValue` | [L101](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua#L101) |
| `methods:GetValue` | [L107](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua#L107) |
| `widget.disabledandtrueorfalseinfo.func` | [L171](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua#L171) |

### Binding/UI/Editor/Widgets/FluxBindingFrame.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Methods:OnAcquire` | [L19](../../Binding/UI/Editor/Widgets/FluxBindingFrame.lua#L19) |
| `Methods:MoveToFront` | [L26](../../Binding/UI/Editor/Widgets/FluxBindingFrame.lua#L26) |
| `Methods:SetMinWidth` | [L30](../../Binding/UI/Editor/Widgets/FluxBindingFrame.lua#L30) |
| `Methods:SetMinHeight` | [L35](../../Binding/UI/Editor/Widgets/FluxBindingFrame.lua#L35) |
| `Methods:OnWidthSet` | [L40](../../Binding/UI/Editor/Widgets/FluxBindingFrame.lua#L40) |
| `Methods:OnHeightSet` | [L46](../../Binding/UI/Editor/Widgets/FluxBindingFrame.lua#L46) |

### Binding/UI/Editor/Widgets/FluxBindingTabGroup.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Methods:SetTabs` | [L9](../../Binding/UI/Editor/Widgets/FluxBindingTabGroup.lua#L9) |

### Binding/UI/Editor/Widgets/FluxKeyCapture.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Methods:OnAcquire` | [L106](../../Binding/UI/Editor/Widgets/FluxKeyCapture.lua#L106) |
| `Methods:SetKey` | [L114](../../Binding/UI/Editor/Widgets/FluxKeyCapture.lua#L114) |
| `Methods:GetKey` | [L119](../../Binding/UI/Editor/Widgets/FluxKeyCapture.lua#L119) |
| `Methods:SetMarker` | [L123](../../Binding/UI/Editor/Widgets/FluxKeyCapture.lua#L123) |
| `Methods:SetInherited` | [L129](../../Binding/UI/Editor/Widgets/FluxKeyCapture.lua#L129) |
| `Methods:IsInherited` | [L134](../../Binding/UI/Editor/Widgets/FluxKeyCapture.lua#L134) |
| `Methods:SetLocked` | [L139](../../Binding/UI/Editor/Widgets/FluxKeyCapture.lua#L139) |
| `Methods:IsLocked` | [L147](../../Binding/UI/Editor/Widgets/FluxKeyCapture.lua#L147) |
| `Methods:UpdateText` | [L151](../../Binding/UI/Editor/Widgets/FluxKeyCapture.lua#L151) |

### Binding/UI/Editor/Widgets/FluxSectionHeading.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Methods:OnAcquire` | [L21](../../Binding/UI/Editor/Widgets/FluxSectionHeading.lua#L21) |
| `Methods:SetText` | [L29](../../Binding/UI/Editor/Widgets/FluxSectionHeading.lua#L29) |
| `Methods:SetLabel` | [L34](../../Binding/UI/Editor/Widgets/FluxSectionHeading.lua#L34) |
| `Methods:SetDisabled` | [L38](../../Binding/UI/Editor/Widgets/FluxSectionHeading.lua#L38) |
| `Methods:SetValue` | [L51](../../Binding/UI/Editor/Widgets/FluxSectionHeading.lua#L51) |
| `Methods:SetLabelColor` | [L57](../../Binding/UI/Editor/Widgets/FluxSectionHeading.lua#L57) |
| `Methods:GetValue` | [L61](../../Binding/UI/Editor/Widgets/FluxSectionHeading.lua#L61) |
| `Methods:ToggleChecked` | [L65](../../Binding/UI/Editor/Widgets/FluxSectionHeading.lua#L65) |

### Binding/UI/Editor/Widgets/FluxTargetRow.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Methods:OnAcquire` | [L37](../../Binding/UI/Editor/Widgets/FluxTargetRow.lua#L37) |
| `Methods:SetMoveUpButton` | [L44](../../Binding/UI/Editor/Widgets/FluxTargetRow.lua#L44) |
| `Methods:SetMoveDownButton` | [L48](../../Binding/UI/Editor/Widgets/FluxTargetRow.lua#L48) |
| `Methods:LayoutFinished` | [L52](../../Binding/UI/Editor/Widgets/FluxTargetRow.lua#L52) |
| `Methods:OnWidthSet` | [L56](../../Binding/UI/Editor/Widgets/FluxTargetRow.lua#L56) |
| `Methods:OnHeightSet` | [L61](../../Binding/UI/Editor/Widgets/FluxTargetRow.lua#L61) |

### Binding/UI/KeyVisualizer/AceGUIContainer-FluxKeyVisualizerTreeGroup.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Methods:GetContentWidth` | [L13](../../Binding/UI/KeyVisualizer/AceGUIContainer-FluxKeyVisualizerTreeGroup.lua#L13) |
| `Methods:GetContentHeight` | [L18](../../Binding/UI/KeyVisualizer/AceGUIContainer-FluxKeyVisualizerTreeGroup.lua#L18) |
| `Methods:LayoutFinished` | [L23](../../Binding/UI/KeyVisualizer/AceGUIContainer-FluxKeyVisualizerTreeGroup.lua#L23) |

### Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Methods:OnAcquire` | [L159](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L159) |
| `Methods:SetKey` | [L169](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L169) |
| `Methods:FitActionIcon` | [L190](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L190) |
| `Methods:SetActionCount` | [L205](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L205) |
| `Methods:SetIcon` | [L214](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L214) |
| `Methods:SetDesaturated` | [L221](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L221) |
| `Methods:SetBadges` | [L229](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L229) |
| `Methods:SetVisible` | [L271](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L271) |
| `Methods:SetHighlight` | [L280](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L280) |
| `Methods:GetKey` | [L289](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L289) |
| `Methods:IsVisible` | [L293](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L293) |
| `Methods:IsHighlighted` | [L297](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L297) |
| `Methods:OnWidthSet` | [L301](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L301) |
| `Methods:OnHeightSet` | [L310](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L310) |
| `widget:SetBadges` | [L389](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L389) |

### Binding/UI/KeyVisualizer/Core.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `KeyVisualizer:SetKeyboardLayout` | [L1877](../../Binding/UI/KeyVisualizer/Core.lua#L1877) |
| `KeyVisualizer:Open` | [L1981](../../Binding/UI/KeyVisualizer/Core.lua#L1981) |
| `KeyVisualizer:Close` | [L2181](../../Binding/UI/KeyVisualizer/Core.lua#L2181) |
| `KeyVisualizer:Redraw` | [L2189](../../Binding/UI/KeyVisualizer/Core.lua#L2189) |
| `KeyVisualizer:IsOpen` | [L2196](../../Binding/UI/KeyVisualizer/Core.lua#L2196) |

### Binding/UI/KeyVisualizer/KeyLayouts.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `KeyButtonMixin:GetId` | [L42](../../Binding/UI/KeyVisualizer/KeyLayouts.lua#L42) |
| `KeyButtonMixin:GetAbbreviation` | [L47](../../Binding/UI/KeyVisualizer/KeyLayouts.lua#L47) |
| `KeyLayouts:GetKeyboardLayouts` | [L519](../../Binding/UI/KeyVisualizer/KeyLayouts.lua#L519) |
| `KeyLayouts:GetKeyboardSizes` | [L536](../../Binding/UI/KeyVisualizer/KeyLayouts.lua#L536) |
| `KeyLayouts:GetKeyboardLayout` | [L626](../../Binding/UI/KeyVisualizer/KeyLayouts.lua#L626) |
| `KeyLayouts:GetMouseLayout` | [L652](../../Binding/UI/KeyVisualizer/KeyLayouts.lua#L652) |
| `KeyLayouts:GetMouseLayoutKeys` | [L733](../../Binding/UI/KeyVisualizer/KeyLayouts.lua#L733) |

### Binding/UI/Media/Media.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Media.UseMonoFont` | [L15](../../Binding/UI/Media/Media.lua#L15) |

### Blizzard/Hide.lua

Owner: [07-runtime-architecture.md](../07-runtime-architecture.md).

| Declaration | Source |
|---|---|
| `Blizz.SetMouseSuppressed` | [L175](../../Blizzard/Hide.lua#L175) |
| `Blizz.Hide` | [L235](../../Blizzard/Hide.lua#L235) |
| `Blizz.Unhide` | [L267](../../Blizzard/Hide.lua#L267) |
| `Blizz.IsHidden` | [L276](../../Blizzard/Hide.lua#L276) |

### BlizzardSettings/Nameplates.lua

Owner: [05-defaults-and-bindings.md](../05-defaults-and-bindings.md).

| Declaration | Source |
|---|---|
| `Nameplates.ApplyScalars` | [L117](../../BlizzardSettings/Nameplates.lua#L117) |
| `Nameplates.ApplyClassColor` | [L121](../../BlizzardSettings/Nameplates.lua#L121) |
| `Nameplates.ApplyNpcNames` | [L125](../../BlizzardSettings/Nameplates.lua#L125) |
| `Nameplates.ApplyBitfields` | [L129](../../BlizzardSettings/Nameplates.lua#L129) |
| `Nameplates.Differs` | [L143](../../BlizzardSettings/Nameplates.lua#L143) |
| `Nameplates.ApplyNow` | [L167](../../BlizzardSettings/Nameplates.lua#L167) |
| `Nameplates.ApplyHealthText` | [L192](../../BlizzardSettings/Nameplates.lua#L192) |
| `Nameplates.Apply` | [L207](../../BlizzardSettings/Nameplates.lua#L207) |

### BlizzardSettings/Raid.lua

Owner: [05-defaults-and-bindings.md](../05-defaults-and-bindings.md).

| Declaration | Source |
|---|---|
| `Raid.ApplyTutorials` | [L50](../../BlizzardSettings/Raid.lua#L50) |
| `Raid.ApplyProfile` | [L57](../../BlizzardSettings/Raid.lua#L57) |
| `Raid.ApplyNow` | [L98](../../BlizzardSettings/Raid.lua#L98) |
| `Raid.Apply` | [L133](../../BlizzardSettings/Raid.lua#L133) |
| `Raid.OnProfilesLoaded` | [L140](../../BlizzardSettings/Raid.lua#L140) |

### BlizzardSettings/Write.lua

Owner: [05-defaults-and-bindings.md](../05-defaults-and-bindings.md).

| Declaration | Source |
|---|---|
| `Write.IsSecretClient` | [L18](../../BlizzardSettings/Write.lua#L18) |
| `Write.MayUseSettingsAPI` | [L26](../../BlizzardSettings/Write.lua#L26) |
| `Write.Get` | [L38](../../BlizzardSettings/Write.lua#L38) |
| `Write.Exists` | [L48](../../BlizzardSettings/Write.lua#L48) |
| `Write.Matches` | [L53](../../BlizzardSettings/Write.lua#L53) |
| `Write.CanWriteNow` | [L74](../../BlizzardSettings/Write.lua#L74) |
| `Write.CVar` | [L80](../../BlizzardSettings/Write.lua#L80) |
| `Write.Bit` | [L99](../../BlizzardSettings/Write.lua#L99) |
| `Write.SetSetting` | [L123](../../BlizzardSettings/Write.lua#L123) |
| `Write.SetShownValue` | [L133](../../BlizzardSettings/Write.lua#L133) |
| `Write.SetStickyTargetingOff` | [L143](../../BlizzardSettings/Write.lua#L143) |
| `Write.RefreshShown` | [L158](../../BlizzardSettings/Write.lua#L158) |
| `Write.Notify` | [L174](../../BlizzardSettings/Write.lua#L174) |
| `Write.Run` | [L245](../../BlizzardSettings/Write.lua#L245) |
| `Write.IsQueued` | [L260](../../BlizzardSettings/Write.lua#L260) |
| `Write.Flush` | [L264](../../BlizzardSettings/Write.lua#L264) |

### CharacterInfo/GearScore.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `_G.FluxCSC_GetPlayerGearScore` | [L252](../../CharacterInfo/GearScore.lua#L252) |
| `_G.FluxCSC_GetGearScoreQualityRGB` | [L261](../../CharacterInfo/GearScore.lua#L261) |

### CharacterInfo/Init.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `CI.TryInstall` | [L19](../../CharacterInfo/Init.lua#L19) |

### CharacterInfo/ItemLevel.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `_G.FluxCSC_GetPlayerItemLevel` | [L36](../../CharacterInfo/ItemLevel.lua#L36) |
| `_G.FluxCSC_ApplyPaperDollItemLevelSetting` | [L274](../../CharacterInfo/ItemLevel.lua#L274) |
| `module.InstallItemLevel` | [L296](../../CharacterInfo/ItemLevel.lua#L296) |

### CharacterInfo/PaperDollQuality.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `module.InstallQuality` | [L160](../../CharacterInfo/PaperDollQuality.lua#L160) |

### CharacterInfo/PaperDollSecondaryName.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `module.InstallSecondaryName` | [L385](../../CharacterInfo/PaperDollSecondaryName.lua#L385) |

### CharacterInfo/PaperDollVisibility.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `module.InstallVisibility` | [L215](../../CharacterInfo/PaperDollVisibility.lua#L215) |

### CharacterInfo/RetailPane.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `_G.FluxAnniversarySpellPowerTooltip` | [L451](../../CharacterInfo/RetailPane.lua#L451) |
| `statFrame._fluxAnniversarySpellEnterthenreturnendlocalwrappedwrapped` | [L486](../../CharacterInfo/RetailPane.lua#L486) |
| `statFrame._fluxAnniversarySpellEnterthenreturnendlocalwrappedwrapped` | [L694](../../CharacterInfo/RetailPane.lua#L694) |
| `BindForeverStatRows` | [L719](../../CharacterInfo/RetailPane.lua#L719) |
| `module.InstallRetailPane` | [L784](../../CharacterInfo/RetailPane.lua#L784) |

### CharacterInfo/Shared.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `module.IsCharacterUiAddon` | [L26](../../CharacterInfo/Shared.lua#L26) |
| `module.HasCharacterFrame` | [L32](../../CharacterInfo/Shared.lua#L32) |
| `module.HasClassicAttributes` | [L36](../../CharacterInfo/Shared.lua#L36) |
| `module.GetModeKey` | [L51](../../CharacterInfo/Shared.lua#L51) |
| `module.GetGlobalDB` | [L61](../../CharacterInfo/Shared.lua#L61) |
| `module.GetCharacterDB` | [L69](../../CharacterInfo/Shared.lua#L69) |
| `module.QueuePlayerStatRefresh` | [L100](../../CharacterInfo/Shared.lua#L100) |

### CharacterInfo/StatsCritCalculator.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `CSC_ScanAuraCritBonuses` | [L524](../../CharacterInfo/StatsCritCalculator.lua#L524) |
| `CSC_BuildSpellCritData` | [L689](../../CharacterInfo/StatsCritCalculator.lua#L689) |
| `CSC_UpdateSpellCritStatFrameFromCalculator` | [L749](../../CharacterInfo/StatsCritCalculator.lua#L749) |
| `CSC_GetDisplayMeleeCritPercent` | [L779](../../CharacterInfo/StatsCritCalculator.lua#L779) |
| `CSC_GetDisplayRangedCritPercent` | [L790](../../CharacterInfo/StatsCritCalculator.lua#L790) |
| `CSC_GetDisplayRangedCritPercent_G.CSC_InfoFrame_BuildSpellCritData` | [L809](../../CharacterInfo/StatsCritCalculator.lua#L809) |

### CharacterInfo/StatsCustomExtensions.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `GetRingRuneSpellHitBonuses` | [L66](../../CharacterInfo/StatsCustomExtensions.lua#L66) |

### CharacterInfo/StatsEra.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `UIConfig:InitializeStatsFrames` | [L216](../../CharacterInfo/StatsEra.lua#L216) |
| `UIConfig:SetCharacterStats` | [L241](../../CharacterInfo/StatsEra.lua#L241) |
| `UIConfig:CreateMenu` | [L285](../../CharacterInfo/StatsEra.lua#L285) |
| `UIConfig:UpdateStats` | [L305](../../CharacterInfo/StatsEra.lua#L305) |
| `UIConfig:InitializeLeftStatsDropdown` | [L322](../../CharacterInfo/StatsEra.lua#L322) |
| `UIConfig:InitializeRightStatsDropdown` | [L332](../../CharacterInfo/StatsEra.lua#L332) |
| `UIConfig:SetupDropdown` | [L342](../../CharacterInfo/StatsEra.lua#L342) |
| `UIConfig:SetStatsPanelVisibile` | [L361](../../CharacterInfo/StatsEra.lua#L361) |
| `module.InstallClassicStatsPanel` | [L453](../../CharacterInfo/StatsEra.lua#L453) |
| `dbLoader:OnEvent` | [L466](../../CharacterInfo/StatsEra.lua#L466) |
| `CSC_QueuedUpdate` | [L543](../../CharacterInfo/StatsEra.lua#L543) |
| `CSC_HideStatsPanel` | [L548](../../CharacterInfo/StatsEra.lua#L548) |
| `CSC_ShowStatsPanel` | [L556](../../CharacterInfo/StatsEra.lua#L556) |
| `CSC_GetPlayerWeaponSkill` | [L729](../../CharacterInfo/StatsEra.lua#L729) |
| `CSC_GetPlayerMissChances` | [L761](../../CharacterInfo/StatsEra.lua#L761) |
| `CSC_HasEnchant` | [L793](../../CharacterInfo/StatsEra.lua#L793) |
| `CSC_GetAttackPowerFromArgentDawnItems` | [L807](../../CharacterInfo/StatsEra.lua#L807) |
| `CSC_GetSpellkPowerFromArgentDawnItems` | [L849](../../CharacterInfo/StatsEra.lua#L849) |
| `CSC_CacheAPFromADItems` | [L891](../../CharacterInfo/StatsEra.lua#L891) |
| `CSC_GetDefense` | [L895](../../CharacterInfo/StatsEra.lua#L895) |
| `CSC_PaperDollFrame_SetPrimaryStats` | [L929](../../CharacterInfo/StatsEra.lua#L929) |
| `CSC_PaperDollFrame_SetDamage` | [L996](../../CharacterInfo/StatsEra.lua#L996) |
| `CSC_PaperDollFrame_SetAttackBothHands` | [L1137](../../CharacterInfo/StatsEra.lua#L1137) |
| `CSC_PaperDollFrame_SetMeleeAttackPower` | [L1160](../../CharacterInfo/StatsEra.lua#L1160) |
| `CSC_PaperDollFrame_SetRangedAttackPower` | [L1176](../../CharacterInfo/StatsEra.lua#L1176) |
| `CSC_PaperDollFrame_SetCritChance` | [L1206](../../CharacterInfo/StatsEra.lua#L1206) |
| `CSC_PaperDollFrame_SetRangedCritChance` | [L1220](../../CharacterInfo/StatsEra.lua#L1220) |
| `CSC_PaperDollFrame_SetSpellCritChance` | [L1235](../../CharacterInfo/StatsEra.lua#L1235) |
| `CSC_PaperDollFrame_SetHitChance` | [L1249](../../CharacterInfo/StatsEra.lua#L1249) |
| `CSC_PaperDollFrame_SetRangedHitChance` | [L1287](../../CharacterInfo/StatsEra.lua#L1287) |
| `CSC_PaperDollFrame_SetSpellHitChance` | [L1317](../../CharacterInfo/StatsEra.lua#L1317) |
| `CSC_PaperDollFrame_SetAttackSpeed` | [L1348](../../CharacterInfo/StatsEra.lua#L1348) |
| `CSC_PaperDollFrame_SetRangedAttackSpeed` | [L1366](../../CharacterInfo/StatsEra.lua#L1366) |
| `CSC_PaperDollFrame_SetArmor` | [L1383](../../CharacterInfo/StatsEra.lua#L1383) |
| `CSC_PaperDollFrame_SetDefense` | [L1409](../../CharacterInfo/StatsEra.lua#L1409) |
| `CSC_PaperDollFrame_SetDodge` | [L1432](../../CharacterInfo/StatsEra.lua#L1432) |
| `CSC_PaperDollFrame_SetParry` | [L1440](../../CharacterInfo/StatsEra.lua#L1440) |
| `CSC_GetBlockValue` | [L1448](../../CharacterInfo/StatsEra.lua#L1448) |
| `CSC_PaperDollFrame_SetBlock` | [L1502](../../CharacterInfo/StatsEra.lua#L1502) |
| `CSC_PaperDollFrame_SetSpellPower` | [L1517](../../CharacterInfo/StatsEra.lua#L1517) |
| `CSC_PaperDollFrame_SetManaRegen` | [L1575](../../CharacterInfo/StatsEra.lua#L1575) |
| `CSC_PaperDollFrame_SetHealing` | [L1626](../../CharacterInfo/StatsEra.lua#L1626) |
| `CSC_GetTalentInfo` | [L1681](../../CharacterInfo/StatsEra.lua#L1681) |
| `CSC_TalentPoints` | [L1691](../../CharacterInfo/StatsEra.lua#L1691) |
| `CSC_GetMageCritStatsFromTalents` | [L1696](../../CharacterInfo/StatsEra.lua#L1696) |
| `CSC_GetMageSpellHitFromTalents` | [L1719](../../CharacterInfo/StatsEra.lua#L1719) |
| `CSC_GetWarlockSpellHitFromTalents` | [L1735](../../CharacterInfo/StatsEra.lua#L1735) |
| `CSC_GetWarlockCritStatsFromTalents` | [L1746](../../CharacterInfo/StatsEra.lua#L1746) |
| `CSC_GetPriestCritStatsFromTalents` | [L1754](../../CharacterInfo/StatsEra.lua#L1754) |
| `CSC_GetPriestBonusHealingModifierFromTalents` | [L1777](../../CharacterInfo/StatsEra.lua#L1777) |
| `CSC_GetPaladinCritStatsFromTalents` | [L1784](../../CharacterInfo/StatsEra.lua#L1784) |
| `CSC_GetPaladinImprovedBoWModifier` | [L1807](../../CharacterInfo/StatsEra.lua#L1807) |
| `CSC_IsBoWSpellId` | [L1815](../../CharacterInfo/StatsEra.lua#L1815) |
| `CSC_GetDefenseFromTalents` | [L1839](../../CharacterInfo/StatsEra.lua#L1839) |
| `CSC_GetShapeshiftForm` | [L1854](../../CharacterInfo/StatsEra.lua#L1854) |
| `CSC_GetShamanHitFromTalents` | [L1867](../../CharacterInfo/StatsEra.lua#L1867) |
| `CSC_GetShamanCallOfThunderCrit` | [L1874](../../CharacterInfo/StatsEra.lua#L1874) |
| `CSC_GetShamanTidalMasteryCrit` | [L1889](../../CharacterInfo/StatsEra.lua#L1889) |
| `CSC_GetMP5ModifierFromTalents` | [L1896](../../CharacterInfo/StatsEra.lua#L1896) |
| `CSC_GetMP5ModifierFromSetBonus` | [L1916](../../CharacterInfo/StatsEra.lua#L1916) |
| `CSC_GetShamanT2SpellCrit` | [L1946](../../CharacterInfo/StatsEra.lua#L1946) |
| `CSC_GetHolyCritFromBenediction` | [L1969](../../CharacterInfo/StatsEra.lua#L1969) |
| `CSC_GetBlockValueFromWarriorZGEnchants` | [L1980](../../CharacterInfo/StatsEra.lua#L1980) |
| `CSC_GetMp5FromPriestZGEnchants` | [L1994](../../CharacterInfo/StatsEra.lua#L1994) |
| `CSC_CharacterDamageFrame_OnEnter` | [L2011](../../CharacterInfo/StatsEra.lua#L2011) |
| `CSC_CharacterSpellDamageFrame_OnEnter` | [L2030](../../CharacterInfo/StatsEra.lua#L2030) |
| `CSC_CharacterSpellCritFrame_OnEnter` | [L2055](../../CharacterInfo/StatsEra.lua#L2055) |
| `CSC_CharacterManaRegenFrame_OnEnter` | [L2073](../../CharacterInfo/StatsEra.lua#L2073) |
| `CSC_CharacterBlock_OnEnter` | [L2082](../../CharacterInfo/StatsEra.lua#L2082) |
| `CSC_CharacterHitChanceFrame_OnEnter` | [L2105](../../CharacterInfo/StatsEra.lua#L2105) |
| `CSC_CharacterRangedHitChanceFrame_OnEnter` | [L2123](../../CharacterInfo/StatsEra.lua#L2123) |
| `CSC_CharacterSpellHitChanceFrame_OnEnter` | [L2141](../../CharacterInfo/StatsEra.lua#L2141) |
| `CSC_CharacterMeleeCritFrame_OnEnter` | [L2162](../../CharacterInfo/StatsEra.lua#L2162) |
| `CSC_CharacterDefenseFrame_OnEnter` | [L2205](../../CharacterInfo/StatsEra.lua#L2205) |

### CharacterInfo/StatsProgression.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `UIConfig:LayoutPaperStatRows` | [L390](../../CharacterInfo/StatsProgression.lua#L390) |
| `UIConfig:InitializeStatsFrames` | [L421](../../CharacterInfo/StatsProgression.lua#L421) |
| `UIConfig:SetCharacterStats` | [L452](../../CharacterInfo/StatsProgression.lua#L452) |
| `UIConfig:InitializeSideStatsCategory` | [L505](../../CharacterInfo/StatsProgression.lua#L505) |
| `UIConfig:InitializeSideStatsCategories` | [L543](../../CharacterInfo/StatsProgression.lua#L543) |
| `UIConfig:SetCharacterSideStats` | [L564](../../CharacterInfo/StatsProgression.lua#L564) |
| `UIConfig:InitializeSideStatsFrame` | [L607](../../CharacterInfo/StatsProgression.lua#L607) |
| `UIConfig:CreateMenu` | [L639](../../CharacterInfo/StatsProgression.lua#L639) |
| `UIConfig:UpdateStats` | [L677](../../CharacterInfo/StatsProgression.lua#L677) |
| `UIConfig:UpdateSideStats` | [L686](../../CharacterInfo/StatsProgression.lua#L686) |
| `UIConfig:InitializeLeftStatsDropdown` | [L704](../../CharacterInfo/StatsProgression.lua#L704) |
| `UIConfig:InitializeRightStatsDropdown` | [L714](../../CharacterInfo/StatsProgression.lua#L714) |
| `UIConfig:SetupDropdown` | [L724](../../CharacterInfo/StatsProgression.lua#L724) |
| `UIConfig:ToggleSideStatsFrame` | [L743](../../CharacterInfo/StatsProgression.lua#L743) |
| `UIConfig:SetStatsPanelVisibile` | [L747](../../CharacterInfo/StatsProgression.lua#L747) |
| `module.InstallClassicStatsPanel` | [L893](../../CharacterInfo/StatsProgression.lua#L893) |
| `dbLoader:OnEvent` | [L900](../../CharacterInfo/StatsProgression.lua#L900) |
| `CSC_QueuedUpdate` | [L972](../../CharacterInfo/StatsProgression.lua#L972) |
| `CSC_HideStatsPanel` | [L977](../../CharacterInfo/StatsProgression.lua#L977) |
| `CSC_ShowStatsPanel` | [L985](../../CharacterInfo/StatsProgression.lua#L985) |
| `CSC_GetCombatRatingPerUnitBonus` | [L998](../../CharacterInfo/StatsProgression.lua#L998) |
| `CSC_TalentPoints` | [L1019](../../CharacterInfo/StatsProgression.lua#L1019) |
| `CSC_GetTalentRankByName` | [L1027](../../CharacterInfo/StatsProgression.lua#L1027) |
| `CSC_GetSpellHitModifier` | [L1045](../../CharacterInfo/StatsProgression.lua#L1045) |
| `CSC_GetHitPercentFromGearByType` | [L1082](../../CharacterInfo/StatsProgression.lua#L1082) |
| `CSC_GetSpellHitPercentFromGear` | [L1111](../../CharacterInfo/StatsProgression.lua#L1111) |
| `CSC_GetTotalSpellHastePercent` | [L1116](../../CharacterInfo/StatsProgression.lua#L1116) |
| `CSC_GetDisplayHastePercent` | [L1128](../../CharacterInfo/StatsProgression.lua#L1128) |
| `CSC_FormatSpellHasteTooltipLine` | [L1137](../../CharacterInfo/StatsProgression.lua#L1137) |
| `CSC_GetPhysicalHitPercentFromGear` | [L1144](../../CharacterInfo/StatsProgression.lua#L1144) |
| `CSC_GetTotalMeleeHitPercent` | [L1150](../../CharacterInfo/StatsProgression.lua#L1150) |
| `CSC_GetTotalSpellHitPercent` | [L1157](../../CharacterInfo/StatsProgression.lua#L1157) |
| `CSC_GetPriestShadowFocusSpellHit` | [L1188](../../CharacterInfo/StatsProgression.lua#L1188) |
| `CSC_GetSpellHitSharedBase` | [L1211](../../CharacterInfo/StatsProgression.lua#L1211) |
| `CSC_GetAppropriateDamage` | [L1229](../../CharacterInfo/StatsProgression.lua#L1229) |
| `CSC_GetAppropriateAttackSpeed` | [L1238](../../CharacterInfo/StatsProgression.lua#L1238) |
| `CSC_GetAppropriateAttackRaiting` | [L1247](../../CharacterInfo/StatsProgression.lua#L1247) |
| `CSC_PaperDollFrame_SetLabelAndText` | [L1275](../../CharacterInfo/StatsProgression.lua#L1275) |
| `CSC_PaperDollFormatStat` | [L1297](../../CharacterInfo/StatsProgression.lua#L1297) |
| `CSC_HasEnchant` | [L1329](../../CharacterInfo/StatsProgression.lua#L1329) |
| `CSC_GetPlayerWeaponSkill` | [L1427](../../CharacterInfo/StatsProgression.lua#L1427) |
| `CSC_GetPlayerMissChances` | [L1459](../../CharacterInfo/StatsProgression.lua#L1459) |
| `CSC_GetPlayerCritCap` | [L1490](../../CharacterInfo/StatsProgression.lua#L1490) |
| `CSC_GetAttackPowerFromArgentDawnItems` | [L1515](../../CharacterInfo/StatsProgression.lua#L1515) |
| `CSC_GetSpellkPowerFromArgentDawnItems` | [L1557](../../CharacterInfo/StatsProgression.lua#L1557) |
| `CSC_CacheAPFromADItems` | [L1599](../../CharacterInfo/StatsProgression.lua#L1599) |
| `CSC_GetDefense` | [L1603](../../CharacterInfo/StatsProgression.lua#L1603) |
| `CSC_PaperDollFrame_SetPrimaryStats` | [L1637](../../CharacterInfo/StatsProgression.lua#L1637) |
| `CSC_PaperDollFrame_SetDamage` | [L1767](../../CharacterInfo/StatsProgression.lua#L1767) |
| `CSC_PaperDollFrame_SetAttackBothHands` | [L1905](../../CharacterInfo/StatsProgression.lua#L1905) |
| `CSC_PaperDollFrame_SetMeleeAttackPower` | [L1937](../../CharacterInfo/StatsProgression.lua#L1937) |
| `CSC_PaperDollFrame_SetRangedAttackPower` | [L1953](../../CharacterInfo/StatsProgression.lua#L1953) |
| `CSC_PaperDollFrame_SetCritChance` | [L1981](../../CharacterInfo/StatsProgression.lua#L1981) |
| `CSC_PaperDollFrame_SetRangedCritChance` | [L1996](../../CharacterInfo/StatsProgression.lua#L1996) |
| `CSC_UpdateSpellCritStatFrame` | [L2017](../../CharacterInfo/StatsProgression.lua#L2017) |
| `CSC_PaperDollFrame_SetSpellCritChance` | [L2076](../../CharacterInfo/StatsProgression.lua#L2076) |
| `CSC_PaperDollFrame_SetHitChance` | [L2100](../../CharacterInfo/StatsProgression.lua#L2100) |
| `CSC_GetTotalRangedHitPercent` | [L2133](../../CharacterInfo/StatsProgression.lua#L2133) |
| `CSC_PaperDollFrame_SetHitRating` | [L2138](../../CharacterInfo/StatsProgression.lua#L2138) |
| `CSC_PaperDollFrame_SetExpertise` | [L2184](../../CharacterInfo/StatsProgression.lua#L2184) |
| `CSC_PaperDollFrame_SetRangedHitChance` | [L2209](../../CharacterInfo/StatsProgression.lua#L2209) |
| `CSC_PaperDollFrame_SetSpellHitChance` | [L2227](../../CharacterInfo/StatsProgression.lua#L2227) |
| `CSC_PaperDollFrame_SetAttackSpeed` | [L2254](../../CharacterInfo/StatsProgression.lua#L2254) |
| `CSC_PaperDollFrame_SetRangedAttackSpeed` | [L2273](../../CharacterInfo/StatsProgression.lua#L2273) |
| `CSC_PaperDollFrame_GetArmorReduction` | [L2290](../../CharacterInfo/StatsProgression.lua#L2290) |
| `CSC_PaperDollFrame_SetArmor` | [L2309](../../CharacterInfo/StatsProgression.lua#L2309) |
| `CSC_PaperDollFrame_SetDefense` | [L2328](../../CharacterInfo/StatsProgression.lua#L2328) |
| `CSC_PaperDollFrame_SetDodge` | [L2354](../../CharacterInfo/StatsProgression.lua#L2354) |
| `CSC_PaperDollFrame_SetParry` | [L2361](../../CharacterInfo/StatsProgression.lua#L2361) |
| `CSC_GetBlockValue` | [L2368](../../CharacterInfo/StatsProgression.lua#L2368) |
| `CSC_PaperDollFrame_SetBlock` | [L2422](../../CharacterInfo/StatsProgression.lua#L2422) |
| `CSC_PaperDollFrame_SetSpellPower` | [L2436](../../CharacterInfo/StatsProgression.lua#L2436) |
| `CSC_PaperDollFrame_SetManaRegen` | [L2493](../../CharacterInfo/StatsProgression.lua#L2493) |
| `CSC_PaperDollFrame_SetSpellHaste` | [L2524](../../CharacterInfo/StatsProgression.lua#L2524) |
| `CSC_PaperDollFrame_SetPaperSpellPenetration` | [L2544](../../CharacterInfo/StatsProgression.lua#L2544) |
| `CSC_PaperDollFrame_SetPaperArmorPenetration` | [L2569](../../CharacterInfo/StatsProgression.lua#L2569) |
| `CSC_PaperDollFrame_SetResilience` | [L2610](../../CharacterInfo/StatsProgression.lua#L2610) |
| `CSC_SideFrame_SetMissChance` | [L2620](../../CharacterInfo/StatsProgression.lua#L2620) |
| `CSC_SideFrame_SetCritCap` | [L2650](../../CharacterInfo/StatsProgression.lua#L2650) |
| `CSC_SideFrame_SetMeleeHitChance` | [L2665](../../CharacterInfo/StatsProgression.lua#L2665) |
| `CSC_SideFrame_SetMeleeCritRating` | [L2676](../../CharacterInfo/StatsProgression.lua#L2676) |
| `CSC_SideFrame_SetMeleeHasteRating` | [L2682](../../CharacterInfo/StatsProgression.lua#L2682) |
| `CSC_SideFrame_SetArmorPenetration` | [L2689](../../CharacterInfo/StatsProgression.lua#L2689) |
| `CSC_SideFrame_SetRangedHitChance` | [L2700](../../CharacterInfo/StatsProgression.lua#L2700) |
| `CSC_SideFrame_SetRangedCritRating` | [L2716](../../CharacterInfo/StatsProgression.lua#L2716) |
| `CSC_SideFrame_SetRangedHasteRating` | [L2727](../../CharacterInfo/StatsProgression.lua#L2727) |
| `CSC_SideFrame_SetSpellHitChance` | [L2740](../../CharacterInfo/StatsProgression.lua#L2740) |
| `CSC_SideFrame_SetSpellCritRating` | [L2751](../../CharacterInfo/StatsProgression.lua#L2751) |
| `CSC_SideFrame_SetSpellHastePercent` | [L2757](../../CharacterInfo/StatsProgression.lua#L2757) |
| `CSC_SideFrame_SetSpellPenetration` | [L2769](../../CharacterInfo/StatsProgression.lua#L2769) |
| `CSC_SideFrame_SetDefenseRating` | [L2779](../../CharacterInfo/StatsProgression.lua#L2779) |
| `CSC_SideFrame_SetDodgeRating` | [L2788](../../CharacterInfo/StatsProgression.lua#L2788) |
| `CSC_SideFrame_SetParryRating` | [L2795](../../CharacterInfo/StatsProgression.lua#L2795) |
| `CSC_SideFrame_SetBlockRating` | [L2802](../../CharacterInfo/StatsProgression.lua#L2802) |
| `CSC_SideFrame_SetChanceToBeCrittedBy70` | [L2808](../../CharacterInfo/StatsProgression.lua#L2808) |
| `CSC_SideFrame_SetChanceToBeCrittedBy73` | [L2831](../../CharacterInfo/StatsProgression.lua#L2831) |
| `CSC_SideFrame_SetAvoidance` | [L2854](../../CharacterInfo/StatsProgression.lua#L2854) |
| `CSC_SideFrame_SetDefenseUncritableCap` | [L2876](../../CharacterInfo/StatsProgression.lua#L2876) |
| `CSC_SideFrame_SetResilienceUncritableCap` | [L2900](../../CharacterInfo/StatsProgression.lua#L2900) |
| `CSC_GetMageCritStatsFromTalents` | [L2933](../../CharacterInfo/StatsProgression.lua#L2933) |
| `CSC_GetMageSpellHitFromTalents` | [L2954](../../CharacterInfo/StatsProgression.lua#L2954) |
| `CSC_GetWarlockSpellHitFromTalents` | [L2963](../../CharacterInfo/StatsProgression.lua#L2963) |
| `CSC_GetWarlockCritStatsFromTalents` | [L2968](../../CharacterInfo/StatsProgression.lua#L2968) |
| `CSC_GetPriestCritStatsFromTalents` | [L2976](../../CharacterInfo/StatsProgression.lua#L2976) |
| `CSC_GetPriestBonusHealingModifierFromTalents` | [L2993](../../CharacterInfo/StatsProgression.lua#L2993) |
| `CSC_GetPaladinCritStatsFromTalents` | [L3001](../../CharacterInfo/StatsProgression.lua#L3001) |
| `CSC_GetPaladinImprovedBoWModifier` | [L3024](../../CharacterInfo/StatsProgression.lua#L3024) |
| `CSC_IsBoWSpellId` | [L3032](../../CharacterInfo/StatsProgression.lua#L3032) |
| `CSC_GetDefenseFromTalents` | [L3056](../../CharacterInfo/StatsProgression.lua#L3056) |
| `CSC_GetShapeshiftForm` | [L3071](../../CharacterInfo/StatsProgression.lua#L3071) |
| `CSC_GetShamanHitFromTalents` | [L3085](../../CharacterInfo/StatsProgression.lua#L3085) |
| `CSC_GetShamanHitFromElementalPrecision` | [L3090](../../CharacterInfo/StatsProgression.lua#L3090) |
| `CSC_GetShamanCallOfThunderCrit` | [L3096](../../CharacterInfo/StatsProgression.lua#L3096) |
| `CSC_GetShamanTidalMasteryCrit` | [L3102](../../CharacterInfo/StatsProgression.lua#L3102) |
| `CSC_GetMP5ModifierFromTalents` | [L3108](../../CharacterInfo/StatsProgression.lua#L3108) |
| `CSC_GetMP5FromSetBonus` | [L3129](../../CharacterInfo/StatsProgression.lua#L3129) |
| `CSC_GetMP5ModifierFromSetBonus` | [L3159](../../CharacterInfo/StatsProgression.lua#L3159) |
| `CSC_GetShamanT2SpellCrit` | [L3188](../../CharacterInfo/StatsProgression.lua#L3188) |
| `CSC_GetHolyCritFromBenediction` | [L3211](../../CharacterInfo/StatsProgression.lua#L3211) |
| `CSC_GetBlockValueFromWarriorZGEnchants` | [L3222](../../CharacterInfo/StatsProgression.lua#L3222) |
| `CSC_GetMp5FromPriestZGEnchants` | [L3236](../../CharacterInfo/StatsProgression.lua#L3236) |
| `CSC_CharacterDamageFrame_OnEnter` | [L3253](../../CharacterInfo/StatsProgression.lua#L3253) |
| `CSC_CharacterSpellDamageFrame_OnEnter` | [L3272](../../CharacterInfo/StatsProgression.lua#L3272) |
| `CSC_CharacterSpellCritFrame_OnEnter` | [L3288](../../CharacterInfo/StatsProgression.lua#L3288) |
| `CSC_CharacterManaRegenFrame_OnEnter` | [L3324](../../CharacterInfo/StatsProgression.lua#L3324) |
| `CSC_CharacterBlock_OnEnter` | [L3333](../../CharacterInfo/StatsProgression.lua#L3333) |
| `CSC_CharacterHitChanceFrame_OnEnter` | [L3357](../../CharacterInfo/StatsProgression.lua#L3357) |
| `CSC_CharacterRangedHitChanceFrame_OnEnter` | [L3375](../../CharacterInfo/StatsProgression.lua#L3375) |
| `CSC_CharacterSpellHitChanceFrame_OnEnter` | [L3393](../../CharacterInfo/StatsProgression.lua#L3393) |
| `CSC_CharacterHitRatingFrame_OnEnter` | [L3434](../../CharacterInfo/StatsProgression.lua#L3434) |
| `CSC_CharacterMeleeCritFrame_OnEnter` | [L3518](../../CharacterInfo/StatsProgression.lua#L3518) |
| `CSC_CharacterRangedCritFrame_OnEnter` | [L3562](../../CharacterInfo/StatsProgression.lua#L3562) |
| `CSC_CharacterDefenseFrame_OnEnter` | [L3595](../../CharacterInfo/StatsProgression.lua#L3595) |
| `CSC_CharacterMeleeHitChanceSideFrame_OnEnter` | [L3606](../../CharacterInfo/StatsProgression.lua#L3606) |

### CharacterInfo/TacoTip.lua

Owner: [27-character-info.md](../27-character-info.md).

| Declaration | Source |
|---|---|
| `module.InstallTacoTip` | [L58](../../CharacterInfo/TacoTip.lua#L58) |

### ConsoleportCompat/CombatQueue.lua

Owner: [29-integrations.md](../29-integrations.md).

| Declaration | Source |
|---|---|
| `Compat.RunOrDefer` | [L15](../../ConsoleportCompat/CombatQueue.lua#L15) |
| `Compat.HasDeferredWork` | [L30](../../ConsoleportCompat/CombatQueue.lua#L30) |
| `Compat.FlushDeferred` | [L34](../../ConsoleportCompat/CombatQueue.lua#L34) |

### ConsoleportCompat/Loader.lua

Owner: [29-integrations.md](../29-integrations.md).

| Declaration | Source |
|---|---|
| `Compat.ApplyAllSuppression` | [L24](../../ConsoleportCompat/Loader.lua#L24) |
| `Compat.ApplyIfReady` | [L33](../../ConsoleportCompat/Loader.lua#L33) |

### ConsoleportCompat/MicroMenuHooks.lua

Owner: [29-integrations.md](../29-integrations.md).

| Declaration | Source |
|---|---|
| `popoutFrame.SetPropspopoutFrame.SetProps` | [L136](../../ConsoleportCompat/MicroMenuHooks.lua#L136) |
| `truepopoutFrame.MoveMicroButtons` | [L152](../../ConsoleportCompat/MicroMenuHooks.lua#L152) |
| `Compat.ApplyMicroMenuSuppression` | [L238](../../ConsoleportCompat/MicroMenuHooks.lua#L238) |

### ConsoleportCompat/StatusBarHooks.lua

Owner: [29-integrations.md](../29-integrations.md).

| Declaration | Source |
|---|---|
| `Compat.ApplyStatusBarSuppression` | [L152](../../ConsoleportCompat/StatusBarHooks.lua#L152) |

### Core/API/Action.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Action.GetTexture` | [L48](../../Core/API/Action.lua#L48) |
| `Action.IsUsable` | [L55](../../Core/API/Action.lua#L55) |
| `Action.IsConsumable` | [L62](../../Core/API/Action.lua#L62) |
| `Action.IsStackable` | [L69](../../Core/API/Action.lua#L69) |
| `Action.IsItem` | [L76](../../Core/API/Action.lua#L76) |
| `Action.IsEquipped` | [L83](../../Core/API/Action.lua#L83) |
| `Action.UnpackCharges` | [L93](../../Core/API/Action.lua#L93) |
| `Action.UnpackCooldown` | [L110](../../Core/API/Action.lua#L110) |
| `Action.GetCharges` | [L117](../../Core/API/Action.lua#L117) |
| `Action.GetCount` | [L124](../../Core/API/Action.lua#L124) |
| `Action.GetCooldown` | [L131](../../Core/API/Action.lua#L131) |
| `Action.GetChargeDuration` | [L138](../../Core/API/Action.lua#L138) |
| `Action.GetInfo` | [L145](../../Core/API/Action.lua#L145) |
| `Action.OccupancyKey` | [L154](../../Core/API/Action.lua#L154) |
| `Action.GetText` | [L163](../../Core/API/Action.lua#L163) |
| `Action.HasAction` | [L170](../../Core/API/Action.lua#L170) |
| `Action.IsAttack` | [L184](../../Core/API/Action.lua#L184) |
| `Action.IsAutoRepeat` | [L188](../../Core/API/Action.lua#L188) |
| `Action.IsCurrent` | [L192](../../Core/API/Action.lua#L192) |
| `Action.IsAssistedCombat` | [L196](../../Core/API/Action.lua#L196) |
| `Action.GetAssistedNextSpell` | [L208](../../Core/API/Action.lua#L208) |
| `Action.IsAssistedHighlightActive` | [L231](../../Core/API/Action.lua#L231) |
| `Action.GetAssistedHighlightSpell` | [L248](../../Core/API/Action.lua#L248) |
| `Action.SpellForAssistedHighlight` | [L271](../../Core/API/Action.lua#L271) |
| `Action.GetDisplayCount` | [L304](../../Core/API/Action.lua#L304) |
| `Action.GetCooldownDuration` | [L314](../../Core/API/Action.lua#L314) |
| `Action.EnableRangeCheck` | [L321](../../Core/API/Action.lua#L321) |
| `Action.LeaveBlizzardCollector` | [L346](../../Core/API/Action.lua#L346) |
| `Action.WithRegistrationSuppressed` | [L352](../../Core/API/Action.lua#L352) |
| `Action.NilFromCollector` | [L359](../../Core/API/Action.lua#L359) |
| `Action.SweepFluxFromCollectors` | [L407](../../Core/API/Action.lua#L407) |
| `Action.DetachFromCollectors` | [L429](../../Core/API/Action.lua#L429) |

### Core/API/AddOn.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `AddOn.IsLoaded` | [L27](../../Core/API/AddOn.lua#L27) |
| `AddOn.GetMetadata` | [L35](../../Core/API/AddOn.lua#L35) |
| `AddOn.Load` | [L46](../../Core/API/AddOn.lua#L46) |
| `AddOn.Enable` | [L54](../../Core/API/AddOn.lua#L54) |
| `AddOn.GetInfo` | [L61](../../Core/API/AddOn.lua#L61) |
| `AddOn.Exists` | [L75](../../Core/API/AddOn.lua#L75) |
| `AddOn.IsLoadable` | [L98](../../Core/API/AddOn.lua#L98) |

### Core/API/Aura.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Aura.GetSlots` | [L20](../../Core/API/Aura.lua#L20) |
| `Aura.GetDataBySlot` | [L49](../../Core/API/Aura.lua#L49) |
| `Aura.GetDataByIndex` | [L66](../../Core/API/Aura.lua#L66) |
| `Aura.GetDataByInstanceID` | [L109](../../Core/API/Aura.lua#L109) |
| `Aura.GetPlayerAuraBySpellID` | [L125](../../Core/API/Aura.lua#L125) |
| `Aura.GetCooldownAuraBySpellID` | [L140](../../Core/API/Aura.lua#L140) |
| `Aura.GetAuraDuration` | [L160](../../Core/API/Aura.lua#L160) |
| `Aura.UnitHealth` | [L181](../../Core/API/Aura.lua#L181) |
| `Aura.UnitHealthMax` | [L185](../../Core/API/Aura.lua#L185) |
| `Aura.UnitPower` | [L189](../../Core/API/Aura.lua#L189) |
| `Aura.UnitPowerMax` | [L193](../../Core/API/Aura.lua#L193) |

### Core/API/Container.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Container.GetNumSlots` | [L32](../../Core/API/Container.lua#L32) |
| `Container.GetItemInfo` | [L87](../../Core/API/Container.lua#L87) |
| `Container.GetItemID` | [L154](../../Core/API/Container.lua#L154) |
| `Container.GetItemLink` | [L169](../../Core/API/Container.lua#L169) |
| `Container.PickupItem` | [L194](../../Core/API/Container.lua#L194) |
| `Container.UseItem` | [L208](../../Core/API/Container.lua#L208) |
| `Container.SplitItem` | [L222](../../Core/API/Container.lua#L222) |
| `Container.GetNumFreeSlots` | [L240](../../Core/API/Container.lua#L240) |
| `Container.GetTotalFreeBagSlots` | [L260](../../Core/API/Container.lua#L260) |
| `Container.RequestFreeBagSlotsRefresh` | [L298](../../Core/API/Container.lua#L298) |
| `Container.WatchFreeBagSlots` | [L308](../../Core/API/Container.lua#L308) |

### Core/API/CVar.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `CVar.IsBlocked` | [L57](../../Core/API/CVar.lua#L57) |
| `CVar.IsThreatBitfieldCVar` | [L64](../../Core/API/CVar.lua#L64) |
| `CVar.SetBitfield` | [L68](../../Core/API/CVar.lua#L68) |
| `CVar.Get` | [L86](../../Core/API/CVar.lua#L86) |
| `CVar.GetDefault` | [L95](../../Core/API/CVar.lua#L95) |
| `CVar.GetBool` | [L104](../../Core/API/CVar.lua#L104) |
| `CVar.Set` | [L112](../../Core/API/CVar.lua#L112) |

### Core/API/Item.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Item.GetInfo` | [L10](../../Core/API/Item.lua#L10) |
| `Item.GetIcon` | [L20](../../Core/API/Item.lua#L20) |
| `Item.GetCount` | [L31](../../Core/API/Item.lua#L31) |
| `Item.IsUsable` | [L85](../../Core/API/Item.lua#L85) |
| `Item.IsEquipped` | [L129](../../Core/API/Item.lua#L129) |
| `Item.UsesConsumableCharges` | [L165](../../Core/API/Item.lua#L165) |
| `Item.IsConsumable` | [L196](../../Core/API/Item.lua#L196) |
| `Item.IsCurrent` | [L235](../../Core/API/Item.lua#L235) |
| `Item.CanCheckRange` | [L258](../../Core/API/Item.lua#L258) |
| `Item.IsInRange` | [L270](../../Core/API/Item.lua#L270) |
| `Item.GetSpell` | [L306](../../Core/API/Item.lua#L306) |
| `Item.GetQuality` | [L338](../../Core/API/Item.lua#L338) |
| `Item.DoesExist` | [L346](../../Core/API/Item.lua#L346) |
| `Item.GetCooldown` | [L357](../../Core/API/Item.lua#L357) |

### Core/API/Name.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `PlayerName.GetSurnameSeparator` | [L37](../../Core/API/Name.lua#L37) |
| `PlayerName.UsesRegionalUniqueNames` | [L46](../../Core/API/Name.lua#L46) |
| `PlayerName.GetUnitNameParts` | [L65](../../Core/API/Name.lua#L65) |
| `PlayerName.GetFirstName` | [L89](../../Core/API/Name.lua#L89) |
| `PlayerName.GetFullName` | [L104](../../Core/API/Name.lua#L104) |
| `PlayerName.ShouldDisplaySurname` | [L131](../../Core/API/Name.lua#L131) |
| `PlayerName.SetDisplaySurname` | [L157](../../Core/API/Name.lua#L157) |
| `PlayerName.GetDisplayName` | [L172](../../Core/API/Name.lua#L172) |
| `PlayerName.GetRealmDisplay` | [L199](../../Core/API/Name.lua#L199) |
| `PlayerName.GetRealmToken` | [L215](../../Core/API/Name.lua#L215) |
| `PlayerName.IsCharacterIdentityReady` | [L233](../../Core/API/Name.lua#L233) |
| `PlayerName.GetCharKey` | [L245](../../Core/API/Name.lua#L245) |
| `PlayerName.SplitCharKey` | [L280](../../Core/API/Name.lua#L280) |
| `PlayerName.NamesEqual` | [L295](../../Core/API/Name.lua#L295) |
| `PlayerName.IsUnitPlayer` | [L330](../../Core/API/Name.lua#L330) |
| `PlayerName.MigrateKeyedTable` | [L338](../../Core/API/Name.lua#L338) |
| `PlayerName.GetLegacyCharKeys` | [L377](../../Core/API/Name.lua#L377) |
| `PlayerName.MigrateCurrentCharacterKeys` | [L433](../../Core/API/Name.lua#L433) |
| `PlayerName.MigrateCurrentCharacterAccountData` | [L447](../../Core/API/Name.lua#L447) |

### Core/API/Pet.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Pet.GetActionInfo` | [L25](../../Core/API/Pet.lua#L25) |
| `Pet.GetActionCooldown` | [L36](../../Core/API/Pet.lua#L36) |
| `Pet.IsSlotUsable` | [L47](../../Core/API/Pet.lua#L47) |
| `Pet.IsAttackAction` | [L63](../../Core/API/Pet.lua#L63) |

### Core/API/Secrets.lua

Owner: [03-midnight-constraints.md](../03-midnight-constraints.md).

| Declaration | Source |
|---|---|
| `Secrets.CanAccessValue` | [L30](../../Core/API/Secrets.lua#L30) |
| `Secrets.IsSecretValue` | [L34](../../Core/API/Secrets.lua#L34) |
| `Secrets.CanAccessSecrets` | [L40](../../Core/API/Secrets.lua#L40) |
| `Secrets.AurasRestricted` | [L48](../../Core/API/Secrets.lua#L48) |
| `Secrets.IsSecretTable` | [L83](../../Core/API/Secrets.lua#L83) |
| `Secrets.CanAccessTable` | [L91](../../Core/API/Secrets.lua#L91) |
| `Secrets.SafeAccessibleString` | [L99](../../Core/API/Secrets.lua#L99) |
| `Secrets.SafeGetNumber` | [L113](../../Core/API/Secrets.lua#L113) |
| `Secrets.KeepLastNumber` | [L137](../../Core/API/Secrets.lua#L137) |
| `Secrets.CoerceNumberLoose` | [L164](../../Core/API/Secrets.lua#L164) |
| `Secrets.SafeCompare` | [L178](../../Core/API/Secrets.lua#L178) |
| `Secrets.SafeEqualForCache` | [L207](../../Core/API/Secrets.lua#L207) |
| `Secrets.SafeGUIDsEqual` | [L218](../../Core/API/Secrets.lua#L218) |
| `Secrets.SafeGUIDChangedForRefresh` | [L228](../../Core/API/Secrets.lua#L228) |
| `Secrets.AccessibleGUIDForUnit` | [L236](../../Core/API/Secrets.lua#L236) |
| `Secrets.SafeBooleanTest` | [L258](../../Core/API/Secrets.lua#L258) |
| `Secrets.NormalizeTriBool` | [L284](../../Core/API/Secrets.lua#L284) |
| `Secrets.SafeCountKey` | [L333](../../Core/API/Secrets.lua#L333) |
| `Secrets.SafeLooksEmpty` | [L360](../../Core/API/Secrets.lua#L360) |
| `Secrets.AuraUpdateInfoIsNoop` | [L376](../../Core/API/Secrets.lua#L376) |
| `Secrets.AuraUpdateInfoHasSecrets` | [L413](../../Core/API/Secrets.lua#L413) |

### Core/API/Shapeshift.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Shapeshift.GetNumForms` | [L25](../../Core/API/Shapeshift.lua#L25) |
| `Shapeshift.GetForm` | [L39](../../Core/API/Shapeshift.lua#L39) |
| `Shapeshift.GetFormInfo` | [L49](../../Core/API/Shapeshift.lua#L49) |
| `Shapeshift.GetFormCooldown` | [L60](../../Core/API/Shapeshift.lua#L60) |
| `Shapeshift.MatchesActiveForm` | [L73](../../Core/API/Shapeshift.lua#L73) |
| `Shapeshift.ActiveSpellId` | [L94](../../Core/API/Shapeshift.lua#L94) |

### Core/API/Spec.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Spec.GetSpecialization` | [L22](../../Core/API/Spec.lua#L22) |
| `Spec.GetRole` | [L38](../../Core/API/Spec.lua#L38) |
| `Spec.IsPlayerEffectivelyTank` | [L71](../../Core/API/Spec.lua#L71) |
| `Spec.InstallRoleCompat` | [L93](../../Core/API/Spec.lua#L93) |
| `thenreturnfalseend_G.GetSpecializationRole` | [L104](../../Core/API/Spec.lua#L104) |

### Core/API/Spell.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `C_Spell.GetSpellInfo_GetSpellInfoRaw` | [L16](../../Core/API/Spell.lua#L16) |
| `Spell.GetInfo` | [L79](../../Core/API/Spell.lua#L79) |
| `Spell.GetName` | [L103](../../Core/API/Spell.lua#L103) |
| `Spell.GetIcon` | [L108](../../Core/API/Spell.lua#L108) |
| `Spell.GetConditionalIcon` | [L167](../../Core/API/Spell.lua#L167) |
| `Spell.GetTexture` | [L209](../../Core/API/Spell.lua#L209) |
| `Spell.GetSubtext` | [L232](../../Core/API/Spell.lua#L232) |
| `Spell.GetCooldown` | [L242](../../Core/API/Spell.lua#L242) |
| `Spell.GetCooldownDuration` | [L268](../../Core/API/Spell.lua#L268) |
| `Spell.GetCount` | [L279](../../Core/API/Spell.lua#L279) |
| `Spell.GetCharges` | [L306](../../Core/API/Spell.lua#L306) |
| `Spell.GetChargeDuration` | [L347](../../Core/API/Spell.lua#L347) |
| `Spell.GetDisplayCount` | [L361](../../Core/API/Spell.lua#L361) |
| `Spell.IsUsable` | [L411](../../Core/API/Spell.lua#L411) |
| `Spell.IsInRange` | [L472](../../Core/API/Spell.lua#L472) |
| `Spell.GetBaseSpell` | [L507](../../Core/API/Spell.lua#L507) |
| `Spell.GetOverrideSpell` | [L517](../../Core/API/Spell.lua#L517) |
| `Spell.IdsMatch` | [L537](../../Core/API/Spell.lua#L537) |
| `Spell.ClearLiveFaceCache` | [L564](../../Core/API/Spell.lua#L564) |
| `Spell.GetLiveFace` | [L721](../../Core/API/Spell.lua#L721) |
| `Spell.IsCurrent` | [L799](../../Core/API/Spell.lua#L799) |
| `Spell.IsAutoRepeat` | [L811](../../Core/API/Spell.lua#L811) |
| `Spell.IsIdCast` | [L823](../../Core/API/Spell.lua#L823) |
| `Spell.FormatCastAttribute` | [L828](../../Core/API/Spell.lua#L828) |
| `Spell.BuildCastAttribute` | [L842](../../Core/API/Spell.lua#L842) |
| `Spell.GetFlyoutInfo` | [L907](../../Core/API/Spell.lua#L907) |
| `Spell.GetFlyoutSlotInfo` | [L922](../../Core/API/Spell.lua#L922) |
| `Spell.FlyoutSlotCastID` | [L944](../../Core/API/Spell.lua#L944) |
| `Spell.FlyoutHasSpell` | [L949](../../Core/API/Spell.lua#L949) |
| `Spell.FindFlyoutSlotCastID` | [L980](../../Core/API/Spell.lua#L980) |
| `Spell.ClearCache` | [L1036](../../Core/API/Spell.lua#L1036) |

### Core/API/Threat.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Threat.HasLeadSituation` | [L100](../../Core/API/Threat.lua#L100) |
| `Threat.HasPercentageOfLead` | [L104](../../Core/API/Threat.lua#L104) |
| `Threat.ShouldDownscaleValues` | [L109](../../Core/API/Threat.lua#L109) |
| `Threat.ShouldStateBeSecret` | [L122](../../Core/API/Threat.lua#L122) |
| `Threat.ShouldValuesBeSecret` | [L132](../../Core/API/Threat.lua#L132) |
| `Threat.UnitExists` | [L142](../../Core/API/Threat.lua#L142) |
| `Threat.UnitCanAttack` | [L153](../../Core/API/Threat.lua#L153) |
| `Threat.UnitIsPlayer` | [L164](../../Core/API/Threat.lua#L164) |
| `Threat.IsEnemyNpc` | [L175](../../Core/API/Threat.lua#L175) |
| `Threat.PlayerInCombat` | [L185](../../Core/API/Threat.lua#L185) |
| `Threat.IsWarningEnabled` | [L200](../../Core/API/Threat.lua#L200) |
| `Threat.ShowNumeric` | [L217](../../Core/API/Threat.lua#L217) |
| `Threat.SetShowNumeric` | [L239](../../Core/API/Threat.lua#L239) |
| `Threat.HasNumericCVar` | [L276](../../Core/API/Threat.lua#L276) |
| `Threat.HasNameplateDisplayCVar` | [L280](../../Core/API/Threat.lua#L280) |
| `Threat.HasWarningCVar` | [L284](../../Core/API/Threat.lua#L284) |
| `Threat.NameplateDisplayEnabled` | [L308](../../Core/API/Threat.lua#L308) |
| `Threat.SetNameplateDisplay` | [L324](../../Core/API/Threat.lua#L324) |
| `Threat.GetNameplateDisplayMask` | [L346](../../Core/API/Threat.lua#L346) |
| `Threat.SetNameplateDisplayMask` | [L361](../../Core/API/Threat.lua#L361) |
| `Threat.GetWarningMode` | [L376](../../Core/API/Threat.lua#L376) |
| `Threat.SetWarningMode` | [L385](../../Core/API/Threat.lua#L385) |
| `Threat.GetSituation` | [L399](../../Core/API/Threat.lua#L399) |
| `Threat.GetLeadSituation` | [L415](../../Core/API/Threat.lua#L415) |
| `Threat.GetPercentageOfLead` | [L426](../../Core/API/Threat.lua#L426) |
| `Threat.GetDetailed` | [L446](../../Core/API/Threat.lua#L446) |
| `Threat.GetNumericDisplay` | [L498](../../Core/API/Threat.lua#L498) |
| `Threat.ShouldShowNumericOnUnit` | [L525](../../Core/API/Threat.lua#L525) |
| `Threat.IsExcludedThreatUnit` | [L536](../../Core/API/Threat.lua#L536) |
| `Threat.DisplayNumber` | [L554](../../Core/API/Threat.lua#L554) |
| `Threat.ShouldShowThreat` | [L576](../../Core/API/Threat.lua#L576) |
| `Threat.GetForeverFrameDisplay` | [L594](../../Core/API/Threat.lua#L594) |
| `Threat.IsNameplateThreatTarget` | [L622](../../Core/API/Threat.lua#L622) |
| `Threat.GetForeverNameplateStatus` | [L640](../../Core/API/Threat.lua#L640) |
| `Threat.HasNonZeroDisplay` | [L650](../../Core/API/Threat.lua#L650) |
| `Threat.AccessibleNumber` | [L667](../../Core/API/Threat.lua#L667) |
| `Threat.SetBarValue` | [L678](../../Core/API/Threat.lua#L678) |
| `Threat.GetStatusColor` | [L705](../../Core/API/Threat.lua#L705) |
| `Threat.GetPercentColor` | [L742](../../Core/API/Threat.lua#L742) |
| `Threat.GetTintColor` | [L762](../../Core/API/Threat.lua#L762) |
| `Threat.SetPercentText` | [L787](../../Core/API/Threat.lua#L787) |
| `Threat.SetRankPercentText` | [L814](../../Core/API/Threat.lua#L814) |
| `Threat.GetPlayerRank` | [L882](../../Core/API/Threat.lua#L882) |
| `Threat.GetMeterRow` | [L979](../../Core/API/Threat.lua#L979) |

### Core/ButtonFX/Cast.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Cast.IsSpellCastVFXEnabled` | [L34](../../Core/ButtonFX/Cast.lua#L34) |
| `ButtonFX.BeginSlotPass` | [L242](../../Core/ButtonFX/Cast.lua#L242) |
| `ButtonFX.EndSlotPass` | [L249](../../Core/ButtonFX/Cast.lua#L249) |
| `ButtonFX.SpellIdFromAction` | [L381](../../Core/ButtonFX/Cast.lua#L381) |
| `ButtonFX.SpellIdFromEBS` | [L401](../../Core/ButtonFX/Cast.lua#L401) |
| `ButtonFX.SpellIdsMatch` | [L674](../../Core/ButtonFX/Cast.lua#L674) |
| `Cast.PickAllMatching` | [L753](../../Core/ButtonFX/Cast.lua#L753) |
| `Cast.PickOwners` | [L771](../../Core/ButtonFX/Cast.lua#L771) |
| `Cast.PickOwner` | [L798](../../Core/ButtonFX/Cast.lua#L798) |
| `Cast.PickOwnerByName` | [L803](../../Core/ButtonFX/Cast.lua#L803) |
| `Cast.FollowColumn` | [L1619](../../Core/ButtonFX/Cast.lua#L1619) |
| `Cast.NoteChannelTimes` | [L1763](../../Core/ButtonFX/Cast.lua#L1763) |
| `StopReticleWatch` | [L2161](../../Core/ButtonFX/Cast.lua#L2161) |
| `Cast.Start` | [L2406](../../Core/ButtonFX/Cast.lua#L2406) |
| `Cast.RefreshFromOptions` | [L2410](../../Core/ButtonFX/Cast.lua#L2410) |
| `Cast.SpellBlockedAsCurrent` | [L2426](../../Core/ButtonFX/Cast.lua#L2426) |
| `Cast.NoteTargeting` | [L2433](../../Core/ButtonFX/Cast.lua#L2433) |
| `Cast.Debug` | [L2480](../../Core/ButtonFX/Cast.lua#L2480) |
| `Cast.Register` | [L2497](../../Core/ButtonFX/Cast.lua#L2497) |
| `Cast.AdoptFace` | [L2515](../../Core/ButtonFX/Cast.lua#L2515) |

### Core/ButtonFX/Charges.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Charges.Ensure` | [L276](../../Core/ButtonFX/Charges.lua#L276) |
| `Charges.Apply` | [L350](../../Core/ButtonFX/Charges.lua#L350) |
| `Charges.ClearCache` | [L448](../../Core/ButtonFX/Charges.lua#L448) |

### Core/ButtonFX/Click.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Click.SyncCVars` | [L142](../../Core/ButtonFX/Click.lua#L142) |
| `Click.MirrorTypeRelease` | [L206](../../Core/ButtonFX/Click.lua#L206) |
| `Click.UsesWrap` | [L224](../../Core/ButtonFX/Click.lua#L224) |
| `Click.Apply` | [L232](../../Core/ButtonFX/Click.lua#L232) |

### Core/ButtonFX/Flash.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Flash.Ensure` | [L131](../../Core/ButtonFX/Flash.lua#L131) |
| `Flash.Set` | [L236](../../Core/ButtonFX/Flash.lua#L236) |
| `Flash.InMeleeCombat` | [L265](../../Core/ButtonFX/Flash.lua#L265) |
| `Flash.WantSlot` | [L283](../../Core/ButtonFX/Flash.lua#L283) |
| `Flash.WantSpell` | [L308](../../Core/ButtonFX/Flash.lua#L308) |
| `Flash.WantItem` | [L345](../../Core/ButtonFX/Flash.lua#L345) |
| `Flash.OnChange` | [L380](../../Core/ButtonFX/Flash.lua#L380) |
| `Flash.Start` | [L386](../../Core/ButtonFX/Flash.lua#L386) |

### Core/ButtonFX/Glow.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Glow.OnChange` | [L38](../../Core/ButtonFX/Glow.lua#L38) |
| `Glow.IsLive` | [L71](../../Core/ButtonFX/Glow.lua#L71) |
| `Glow.Set` | [L402](../../Core/ButtonFX/Glow.lua#L402) |
| `Glow.Transfer` | [L460](../../Core/ButtonFX/Glow.lua#L460) |
| `Glow.ShouldSkipBirth` | [L510](../../Core/ButtonFX/Glow.lua#L510) |
| `Glow.NoteShown` | [L517](../../Core/ButtonFX/Glow.lua#L517) |
| `Glow.NoteHidden` | [L527](../../Core/ButtonFX/Glow.lua#L527) |
| `Glow.FaceShowsSpell` | [L559](../../Core/ButtonFX/Glow.lua#L559) |
| `Glow.SaoMembership` | [L689](../../Core/ButtonFX/Glow.lua#L689) |
| `Glow.Want` | [L738](../../Core/ButtonFX/Glow.lua#L738) |
| `Glow.AnyWanted` | [L752](../../Core/ButtonFX/Glow.lua#L752) |
| `Glow.SilenceMixin` | [L760](../../Core/ButtonFX/Glow.lua#L760) |
| `Glow.InstallSAO` | [L1187](../../Core/ButtonFX/Glow.lua#L1187) |
| `trueframe.__sao.DoesIgnoreNative` | [L1194](../../Core/ButtonFX/Glow.lua#L1194) |
| `returnfalseendframe.__sao.GetGlowID` | [L1197](../../Core/ButtonFX/Glow.lua#L1197) |
| `endframe.__sao.EnableGlow` | [L1200](../../Core/ButtonFX/Glow.lua#L1200) |
| `endframe.__sao.DisableGlow` | [L1208](../../Core/ButtonFX/Glow.lua#L1208) |
| `Glow.NotifySAO` | [L1218](../../Core/ButtonFX/Glow.lua#L1218) |
| `Glow.Start` | [L1225](../../Core/ButtonFX/Glow.lua#L1225) |

### Core/ButtonFX/Overlay.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Overlay._tickNativeFill` | [L552](../../Core/ButtonFX/Overlay.lua#L552) |
| `Overlay._tickFinish` | [L594](../../Core/ButtonFX/Overlay.lua#L594) |
| `Overlay.WatchNativeFill` | [L633](../../Core/ButtonFX/Overlay.lua#L633) |
| `Overlay.UnwatchNativeFill` | [L644](../../Core/ButtonFX/Overlay.lua#L644) |
| `Overlay.HideCooldownCover` | [L694](../../Core/ButtonFX/Overlay.lua#L694) |
| `widget.ClearReticle` | [L791](../../Core/ButtonFX/Overlay.lua#L791) |
| `endendwidget.StopTargettingReticleAnim` | [L801](../../Core/ButtonFX/Overlay.lua#L801) |
| `endendwidget.ClearInterruptDisplay` | [L811](../../Core/ButtonFX/Overlay.lua#L811) |
| `endendwidget.StopSpellCastAnim` | [L823](../../Core/ButtonFX/Overlay.lua#L823) |
| `endwidget.PlaySpellInterruptedAnim` | [L827](../../Core/ButtonFX/Overlay.lua#L827) |
| `endwidget.PlayTargettingReticleAnim` | [L831](../../Core/ButtonFX/Overlay.lua#L831) |
| `endendwidget.PlaySpellCastAnim` | [L856](../../Core/ButtonFX/Overlay.lua#L856) |
| `Overlay.StopClassicFill` | [L1134](../../Core/ButtonFX/Overlay.lua#L1134) |
| `Overlay._classicOnUpdate` | [L1163](../../Core/ButtonFX/Overlay.lua#L1163) |
| `Overlay.PlayClassicFill` | [L1317](../../Core/ButtonFX/Overlay.lua#L1317) |
| `Overlay.PlayClassicFinish` | [L1337](../../Core/ButtonFX/Overlay.lua#L1337) |
| `Overlay.PlayClassicInterrupt` | [L1362](../../Core/ButtonFX/Overlay.lua#L1362) |
| `Overlay.HideCastFill` | [L1441](../../Core/ButtonFX/Overlay.lua#L1441) |
| `Overlay.PlayBurst` | [L1461](../../Core/ButtonFX/Overlay.lua#L1461) |
| `Overlay.PlayCast` | [L1514](../../Core/ButtonFX/Overlay.lua#L1514) |
| `Overlay.StopCast` | [L1575](../../Core/ButtonFX/Overlay.lua#L1575) |
| `Overlay.PlayInterrupt` | [L1674](../../Core/ButtonFX/Overlay.lua#L1674) |
| `Overlay.PlayReticle` | [L1713](../../Core/ButtonFX/Overlay.lua#L1713) |
| `Overlay.ClearReticle` | [L1757](../../Core/ButtonFX/Overlay.lua#L1757) |
| `Overlay.ForEachPressed` | [L1811](../../Core/ButtonFX/Overlay.lua#L1811) |
| `Overlay.NotePressed` | [L1820](../../Core/ButtonFX/Overlay.lua#L1820) |
| `Overlay.ReleasePress` | [L1831](../../Core/ButtonFX/Overlay.lua#L1831) |
| `Overlay.IsCheckedSuppressed` | [L1906](../../Core/ButtonFX/Overlay.lua#L1906) |
| `Overlay.EnsureCheckedTexture` | [L1950](../../Core/ButtonFX/Overlay.lua#L1950) |
| `Overlay.CheckedVisualOn` | [L1976](../../Core/ButtonFX/Overlay.lua#L1976) |
| `Overlay.ApplyChecked` | [L2004](../../Core/ButtonFX/Overlay.lua#L2004) |
| `Overlay.IsPushed` | [L2040](../../Core/ButtonFX/Overlay.lua#L2040) |
| `Overlay.FollowChrome` | [L2058](../../Core/ButtonFX/Overlay.lua#L2058) |
| `Overlay.ResetTargetChrome` | [L2090](../../Core/ButtonFX/Overlay.lua#L2090) |
| `Overlay.IsLiveBurst` | [L2287](../../Core/ButtonFX/Overlay.lua#L2287) |
| `Overlay.IsLiveCast` | [L2300](../../Core/ButtonFX/Overlay.lua#L2300) |
| `Overlay.IsLiveReticle` | [L2323](../../Core/ButtonFX/Overlay.lua#L2323) |
| `Overlay.IsLiveInterrupt` | [L2349](../../Core/ButtonFX/Overlay.lua#L2349) |
| `Overlay.ShouldHideCooldown` | [L2361](../../Core/ButtonFX/Overlay.lua#L2361) |
| `Overlay.ForceClear` | [L2366](../../Core/ButtonFX/Overlay.lua#L2366) |
| `Overlay.SyncCast` | [L2410](../../Core/ButtonFX/Overlay.lua#L2410) |
| `Overlay.SyncInterrupt` | [L2431](../../Core/ButtonFX/Overlay.lua#L2431) |
| `Overlay.SyncBurst` | [L2444](../../Core/ButtonFX/Overlay.lua#L2444) |
| `Overlay.TickFill` | [L2456](../../Core/ButtonFX/Overlay.lua#L2456) |
| `Overlay.TransferCast` | [L2470](../../Core/ButtonFX/Overlay.lua#L2470) |
| `Overlay.TransferReticle` | [L2535](../../Core/ButtonFX/Overlay.lua#L2535) |
| `Overlay.TransferInterrupt` | [L2560](../../Core/ButtonFX/Overlay.lua#L2560) |
| `Overlay.Transfer` | [L2600](../../Core/ButtonFX/Overlay.lua#L2600) |
| `endwidget.MatchesActiveButtonSpellID` | [L2653](../../Core/ButtonFX/Overlay.lua#L2653) |
| `Overlay.Attach` | [L2663](../../Core/ButtonFX/Overlay.lua#L2663) |

### Core/Capabilities.lua

Owner: [02-multi-client-matrix.md](../02-multi-client-matrix.md).

| Declaration | Source |
|---|---|
| `Cap.IsGamepadUIEnabled` | [L20](../../Core/Capabilities.lua#L20) |
| `Cap.GamepadHudActive` | [L32](../../Core/Capabilities.lua#L32) |
| `Cap.GetGamepadActionBarFloor` | [L43](../../Core/Capabilities.lua#L43) |
| `Cap.GetMaxBagIndex` | [L211](../../Core/Capabilities.lua#L211) |
| `Cap.HasBlizzardSettingsKeybindings` | [L218](../../Core/Capabilities.lua#L218) |
| `Cap.HasBlizzardActionBarsOverrides` | [L224](../../Core/Capabilities.lua#L224) |
| `Cap.GetFluxBlizzardActionBarUIMode` | [L235](../../Core/Capabilities.lua#L235) |
| `Cap.AllowBlizzardActionBarSettingsReplace` | [L248](../../Core/Capabilities.lua#L248) |
| `Cap.HasUnifiedBankUI` | [L253](../../Core/Capabilities.lua#L253) |
| `Cap.UseLegacyBankSlotsUI` | [L264](../../Core/Capabilities.lua#L264) |
| `Cap.HasWarbandBank` | [L268](../../Core/Capabilities.lua#L268) |
| `Cap.UsesPlayerBagsInBank` | [L279](../../Core/Capabilities.lua#L279) |
| `Cap.GetCharacterBankTabSentinel` | [L292](../../Core/Capabilities.lua#L292) |
| `Cap.GetAccountBankTabSentinel` | [L296](../../Core/Capabilities.lua#L296) |
| `Cap.IsBankTabSentinel` | [L300](../../Core/Capabilities.lua#L300) |
| `Cap.HasReagentBankContainer` | [L311](../../Core/Capabilities.lua#L311) |
| `Cap.GetReagentBankContainerID` | [L322](../../Core/Capabilities.lua#L322) |
| `Cap.IsReagentBankContainer` | [L329](../../Core/Capabilities.lua#L329) |
| `Cap.FetchPurchasedBankTabIDs` | [L354](../../Core/Capabilities.lua#L354) |
| `Cap.EnumerateBankTabIDs` | [L376](../../Core/Capabilities.lua#L376) |
| `Cap.IsUnifiedBankTabBag` | [L403](../../Core/Capabilities.lua#L403) |
| `Cap.HasCompactRaidFrameManager` | [L433](../../Core/Capabilities.lua#L433) |
| `Cap.HasAtlas` | [L437](../../Core/Capabilities.lua#L437) |
| `Cap.ClientSupportsSingleButtonAssistant` | [L468](../../Core/Capabilities.lua#L468) |
| `Cap.ClientSupportsCombatAmmoExtraButton` | [L475](../../Core/Capabilities.lua#L475) |
| `Cap.RefreshFocusUnit` | [L536](../../Core/Capabilities.lua#L536) |
| `Cap.RefreshUnifiedBank` | [L541](../../Core/Capabilities.lua#L541) |
| `Cap.RefreshKeyring` | [L550](../../Core/Capabilities.lua#L550) |
| `Cap.HasVoidStorage` | [L575](../../Core/Capabilities.lua#L575) |
| `Cap.HasGuildBank` | [L579](../../Core/Capabilities.lua#L579) |
| `Cap.HasAuctionHouse` | [L583](../../Core/Capabilities.lua#L583) |
| `Cap.HasLegacyAuctionHouse` | [L593](../../Core/Capabilities.lua#L593) |
| `Cap.RefreshInventoryCaps` | [L610](../../Core/Capabilities.lua#L610) |
| `Cap.RefreshCharacterInfo` | [L620](../../Core/Capabilities.lua#L620) |
| `Cap.IsForeverGamepadUI` | [L656](../../Core/Capabilities.lua#L656) |

### Core/Client.lua

Owner: [02-multi-client-matrix.md](../02-multi-client-matrix.md).

| Declaration | Source |
|---|---|
| `Client.Is` | [L145](../../Core/Client.lua#L145) |
| `Client.Matches` | [L151](../../Core/Client.lua#L151) |

### Core/Client_Camelot.lua

Owner: [02-multi-client-matrix.md](../02-multi-client-matrix.md).

| Declaration | Source |
|---|---|
| `andC_SpellandC_Spell.GetSpellInfothenGetSpellInfo` | [L101](../../Core/Client_Camelot.lua#L101) |
| `andC_UnitAuras.GetAuraDataByIndexthenUnitAura` | [L134](../../Core/Client_Camelot.lua#L134) |
| `andC_UnitAuras.GetBuffDataByIndexthenUnitBuff` | [L139](../../Core/Client_Camelot.lua#L139) |
| `andC_UnitAuras.GetDebuffDataByIndexthenUnitDebuff` | [L144](../../Core/Client_Camelot.lua#L144) |

### Core/DB.lua

Owner: [09-persistence.md](../09-persistence.md).

| Declaration | Source |
|---|---|
| `DB.GetAccount` | [L66](../../Core/DB.lua#L66) |
| `DB.GetOptions` | [L70](../../Core/DB.lua#L70) |
| `DB.GetChar` | [L74](../../Core/DB.lua#L74) |
| `DB.EnsureAll` | [L78](../../Core/DB.lua#L78) |

### Core/Engine/Combat.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Combat.InLockdown` | [L20](../../Core/Engine/Combat.lua#L20) |
| `Combat.ScheduleRegenQueues` | [L68](../../Core/Engine/Combat.lua#L68) |
| `Combat.RegenDefer` | [L81](../../Core/Engine/Combat.lua#L81) |
| `endend_G.FluxCombatRegenDeferQueue` | [L97](../../Core/Engine/Combat.lua#L97) |
| `end_G.FluxRegenDeferHeavyQueue` | [L101](../../Core/Engine/Combat.lua#L101) |
| `Combat.Defer` | [L106](../../Core/Engine/Combat.lua#L106) |
| `Combat.Flush` | [L121](../../Core/Engine/Combat.lua#L121) |
| `Combat.HasPending` | [L172](../../Core/Engine/Combat.lua#L172) |
| `Combat.PendingCount` | [L176](../../Core/Engine/Combat.lua#L176) |

### Core/Engine/Context.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Context.Fingerprint` | [L259](../../Core/Engine/Context.lua#L259) |
| `Context.MouseoverReactionClass` | [L266](../../Core/Engine/Context.lua#L266) |
| `Context.IsUfPeek` | [L270](../../Core/Engine/Context.lua#L270) |
| `Context.Subscribe` | [L274](../../Core/Engine/Context.lua#L274) |
| `Context.Unsubscribe` | [L285](../../Core/Engine/Context.lua#L285) |
| `Context.HasSubscribers` | [L300](../../Core/Engine/Context.lua#L300) |
| `Context.Request` | [L304](../../Core/Engine/Context.lua#L304) |
| `Context.RequestMouseover` | [L338](../../Core/Engine/Context.lua#L338) |
| `Context.GetStats` | [L393](../../Core/Engine/Context.lua#L393) |
| `Context.ResetStats` | [L397](../../Core/Engine/Context.lua#L397) |
| `thenMK.RegisterFrame` | [L468](../../Core/Engine/Context.lua#L468) |
| `Context.ArmEvents` | [L478](../../Core/Engine/Context.lua#L478) |
| `Context.DisarmEvents` | [L533](../../Core/Engine/Context.lua#L533) |

### Core/Engine/Events.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Events.IsValid` | [L65](../../Core/Engine/Events.lua#L65) |
| `Events.SetTrace` | [L106](../../Core/Engine/Events.lua#L106) |
| `Events.Register` | [L110](../../Core/Engine/Events.lua#L110) |
| `Events.Unregister` | [L132](../../Core/Engine/Events.lua#L132) |
| `Events.RegisterUnit` | [L152](../../Core/Engine/Events.lua#L152) |
| `Events.SafeRegister` | [L173](../../Core/Engine/Events.lua#L173) |
| `Events.SafeRegisterUnit` | [L187](../../Core/Engine/Events.lua#L187) |
| `Events.RegisterLearnedSpell` | [L201](../../Core/Engine/Events.lua#L201) |

### Core/Engine/FormStorm.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `FormStorm.Open` | [L89](../../Core/Engine/FormStorm.lua#L89) |
| `FormStorm.IsBursting` | [L110](../../Core/Engine/FormStorm.lua#L110) |
| `FormStorm.IsSettling` | [L116](../../Core/Engine/FormStorm.lua#L116) |
| `FormStorm.GetSnapshot` | [L122](../../Core/Engine/FormStorm.lua#L122) |
| `FormStorm.Reason` | [L126](../../Core/Engine/FormStorm.lua#L126) |
| `FormStorm.OnBurst` | [L130](../../Core/Engine/FormStorm.lua#L130) |
| `FormStorm.OnSettled` | [L140](../../Core/Engine/FormStorm.lua#L140) |
| `FormStorm.Sync` | [L227](../../Core/Engine/FormStorm.lua#L227) |

### Core/Engine/HopLag.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `HopLag.Count` | [L402](../../Core/Engine/HopLag.lua#L402) |
| `HopLag.Begin` | [L417](../../Core/Engine/HopLag.lua#L417) |
| `HopLag.Stop` | [L428](../../Core/Engine/HopLag.lua#L428) |
| `HopLag.Reset` | [L839](../../Core/Engine/HopLag.lua#L839) |
| `HopLag.Enable` | [L873](../../Core/Engine/HopLag.lua#L873) |
| `HopLag.Report` | [L916](../../Core/Engine/HopLag.lua#L916) |
| `HopLag.Slash` | [L982](../../Core/Engine/HopLag.lua#L982) |

### Core/Engine/Identity.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Identity.SlotKey` | [L30](../../Core/Engine/Identity.lua#L30) |
| `Identity.BadgeKey` | [L34](../../Core/Engine/Identity.lua#L34) |
| `Identity.ParseSlotKey` | [L38](../../Core/Engine/Identity.lua#L38) |
| `Identity.ParseBadgeKey` | [L46](../../Core/Engine/Identity.lua#L46) |
| `Identity.Register` | [L59](../../Core/Engine/Identity.lua#L59) |
| `Identity.Unregister` | [L66](../../Core/Engine/Identity.lua#L66) |
| `Identity.Has` | [L75](../../Core/Engine/Identity.lua#L75) |
| `Identity.Publish` | [L80](../../Core/Engine/Identity.lua#L80) |
| `Identity.Get` | [L103](../../Core/Engine/Identity.lua#L103) |
| `Identity.GetRecord` | [L111](../../Core/Engine/Identity.lua#L111) |
| `Identity.SoftSync` | [L116](../../Core/Engine/Identity.lua#L116) |
| `Identity.OnChange` | [L125](../../Core/Engine/Identity.lua#L125) |
| `Identity.GetStats` | [L132](../../Core/Engine/Identity.lua#L132) |
| `Identity.ResetStats` | [L136](../../Core/Engine/Identity.lua#L136) |

### Core/Engine/Modifier.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Modifier.Register` | [L67](../../Core/Engine/Modifier.lua#L67) |
| `Modifier.Unregister` | [L80](../../Core/Engine/Modifier.lua#L80) |
| `Modifier.NotifyActiveChanged` | [L86](../../Core/Engine/Modifier.lua#L86) |
| `Modifier.IsArmed` | [L90](../../Core/Engine/Modifier.lua#L90) |
| `Modifier.SetTrace` | [L108](../../Core/Engine/Modifier.lua#L108) |
| `andfnornilendframe._onUpdate` | [L112](../../Core/Engine/Modifier.lua#L112) |

### Core/Engine/MouseoverCast.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `MouseoverCast.IsEnabled` | [L123](../../Core/Engine/MouseoverCast.lua#L123) |
| `MouseoverCast.UsesNativeCVar` | [L136](../../Core/Engine/MouseoverCast.lua#L136) |
| `MouseoverCast.ApplyNativeCheck` | [L152](../../Core/Engine/MouseoverCast.lua#L152) |
| `MouseoverCast.SyncDrivers` | [L523](../../Core/Engine/MouseoverCast.lua#L523) |
| `MouseoverCast.RegisterHeader` | [L549](../../Core/Engine/MouseoverCast.lua#L549) |
| `MouseoverCast.AttachHost` | [L576](../../Core/Engine/MouseoverCast.lua#L576) |
| `MouseoverCast.RegisterButton` | [L610](../../Core/Engine/MouseoverCast.lua#L610) |
| `MouseoverCast.SetButtonSpell` | [L637](../../Core/Engine/MouseoverCast.lua#L637) |
| `MouseoverCast.SetButtonItem` | [L659](../../Core/Engine/MouseoverCast.lua#L659) |
| `MouseoverCast.Apply` | [L696](../../Core/Engine/MouseoverCast.lua#L696) |
| `MouseoverCast.SetEnabled` | [L731](../../Core/Engine/MouseoverCast.lua#L731) |
| `MouseoverCast.GetStats` | [L774](../../Core/Engine/MouseoverCast.lua#L774) |
| `MouseoverCast.DebugDump` | [L785](../../Core/Engine/MouseoverCast.lua#L785) |
| `MouseoverCast.RefreshSpellBookCheckbox` | [L842](../../Core/Engine/MouseoverCast.lua#L842) |
| `PositionSpellBookCheckbox` | [L888](../../Core/Engine/MouseoverCast.lua#L888) |
| `MouseoverCast.Start` | [L975](../../Core/Engine/MouseoverCast.lua#L975) |

### Core/Engine/Perf.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Perf.Count` | [L20](../../Core/Engine/Perf.lua#L20) |
| `Perf.Begin` | [L25](../../Core/Engine/Perf.lua#L25) |
| `Perf.Stop` | [L32](../../Core/Engine/Perf.lua#L32) |
| `Perf.BeginBurst` | [L108](../../Core/Engine/Perf.lua#L108) |
| `Perf.ExtendBurst` | [L135](../../Core/Engine/Perf.lua#L135) |
| `Perf.IsBursting` | [L145](../../Core/Engine/Perf.lua#L145) |
| `Perf.LastBurst` | [L149](../../Core/Engine/Perf.lua#L149) |
| `Perf.Reset` | [L153](../../Core/Engine/Perf.lua#L153) |
| `Perf.PrintLastBurst` | [L179](../../Core/Engine/Perf.lua#L179) |
| `Perf.IsIdle` | [L207](../../Core/Engine/Perf.lua#L207) |
| `Regen.Active` | [L241](../../Core/Engine/Perf.lua#L241) |
| `Regen.OnRegen` | [L245](../../Core/Engine/Perf.lua#L245) |
| `Regen.NoteFlushKeys` | [L276](../../Core/Engine/Perf.lua#L276) |
| `Regen.Begin` | [L283](../../Core/Engine/Perf.lua#L283) |
| `Regen.Time` | [L293](../../Core/Engine/Perf.lua#L293) |
| `Regen.Last` | [L306](../../Core/Engine/Perf.lua#L306) |
| `Regen.Reset` | [L310](../../Core/Engine/Perf.lua#L310) |
| `Regen.Print` | [L341](../../Core/Engine/Perf.lua#L341) |
| `Regen.InstallHooks` | [L370](../../Core/Engine/Perf.lua#L370) |
| `_G.FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled_G.FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled` | [L387](../../Core/Engine/Perf.lua#L387) |
| `_G.FluxUnitFrames_UpdateAllEmulatedHorizontalSqueeze_G.FluxUnitFrames_UpdateAllEmulatedHorizontalSqueeze` | [L393](../../Core/Engine/Perf.lua#L393) |
| `Perf.Snapshot` | [L399](../../Core/Engine/Perf.lua#L399) |

### Core/Engine/Range.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Range.SetInterval` | [L48](../../Core/Engine/Range.lua#L48) |
| `Range.GetInterval` | [L52](../../Core/Engine/Range.lua#L52) |
| `Range.SetExtraInterval` | [L56](../../Core/Engine/Range.lua#L56) |
| `Range.GetExtraInterval` | [L60](../../Core/Engine/Range.lua#L60) |
| `Range.ResolveUnit` | [L145](../../Core/Engine/Range.lua#L145) |
| `Range.CheckSpell` | [L195](../../Core/Engine/Range.lua#L195) |
| `Range.CheckItem` | [L217](../../Core/Engine/Range.lua#L217) |
| `Range.CheckAction` | [L240](../../Core/Engine/Range.lua#L240) |
| `Range.RegisterSweep` | [L269](../../Core/Engine/Range.lua#L269) |
| `Range.Sync` | [L346](../../Core/Engine/Range.lua#L346) |
| `Range.IsArmed` | [L363](../../Core/Engine/Range.lua#L363) |
| `Range.IsHopBurst` | [L369](../../Core/Engine/Range.lua#L369) |
| `Range.Invalidate` | [L380](../../Core/Engine/Range.lua#L380) |
| `Range.InvalidateSweep` | [L386](../../Core/Engine/Range.lua#L386) |
| `Range.UnitReactionClass` | [L398](../../Core/Engine/Range.lua#L398) |
| `Range.TargetReactionClass` | [L421](../../Core/Engine/Range.lua#L421) |
| `Range.Start` | [L447](../../Core/Engine/Range.lua#L447) |

### Core/Engine/Restricted.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Restricted.Works` | [L27](../../Core/Engine/Restricted.lua#L27) |
| `Restricted.PagingWorks` | [L36](../../Core/Engine/Restricted.lua#L36) |
| `Restricted.SetPagingSnippet` | [L54](../../Core/Engine/Restricted.lua#L54) |
| `Restricted.ExecutePaging` | [L60](../../Core/Engine/Restricted.lua#L60) |
| `Restricted.RegisterPagingDriver` | [L66](../../Core/Engine/Restricted.lua#L66) |
| `Restricted.UnregisterPagingDriver` | [L74](../../Core/Engine/Restricted.lua#L74) |
| `Restricted.Execute` | [L82](../../Core/Engine/Restricted.lua#L82) |
| `Restricted.WrapScript` | [L92](../../Core/Engine/Restricted.lua#L92) |
| `Restricted.UnwrapScript` | [L105](../../Core/Engine/Restricted.lua#L105) |
| `Restricted.SetSnippet` | [L115](../../Core/Engine/Restricted.lua#L115) |
| `Restricted.RegisterAttributeDriver` | [L334](../../Core/Engine/Restricted.lua#L334) |
| `Restricted.UnregisterAttributeDriver` | [L357](../../Core/Engine/Restricted.lua#L357) |
| `Restricted.RegisterStateDriver` | [L382](../../Core/Engine/Restricted.lua#L382) |
| `Restricted.UnregisterStateDriver` | [L386](../../Core/Engine/Restricted.lua#L386) |
| `Restricted.RegisterUnitWatch` | [L393](../../Core/Engine/Restricted.lua#L393) |
| `Restricted.UnregisterUnitWatch` | [L408](../../Core/Engine/Restricted.lua#L408) |
| `Restricted.UnitWatchRegistered` | [L423](../../Core/Engine/Restricted.lua#L423) |

### Core/Engine/Scheduler.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Scheduler.Register` | [L90](../../Core/Engine/Scheduler.lua#L90) |
| `Scheduler.BeginPaging` | [L98](../../Core/Engine/Scheduler.lua#L98) |
| `Scheduler.EndPaging` | [L102](../../Core/Engine/Scheduler.lua#L102) |
| `Scheduler.IsPaging` | [L106](../../Core/Engine/Scheduler.lua#L106) |
| `Scheduler.Request` | [L111](../../Core/Engine/Scheduler.lua#L111) |
| `Scheduler.HasPending` | [L145](../../Core/Engine/Scheduler.lua#L145) |
| `Scheduler.Flush` | [L221](../../Core/Engine/Scheduler.lua#L221) |
| `Scheduler.Stats` | [L261](../../Core/Engine/Scheduler.lua#L261) |

### Core/Engine/SpellBook.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `SpellBook.OnChanged` | [L44](../../Core/Engine/SpellBook.lua#L44) |
| `SpellBook.Sync` | [L160](../../Core/Engine/SpellBook.lua#L160) |

### Core/Engine/SpellBookChrome.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Chrome.Observe` | [L21](../../Core/Engine/SpellBookChrome.lua#L21) |
| `Chrome.HasLowRankApi` | [L58](../../Core/Engine/SpellBookChrome.lua#L58) |
| `Chrome.HasBlizzardShowAllRanksDropdown` | [L62](../../Core/Engine/SpellBookChrome.lua#L62) |
| `Chrome.GetBlizzardShowAllRanksCheckbox` | [L67](../../Core/Engine/SpellBookChrome.lua#L67) |
| `Chrome.GetFluxShowAllRanksCheckbox` | [L75](../../Core/Engine/SpellBookChrome.lua#L75) |
| `Chrome.EnsureBlizzardShowAllRanks` | [L86](../../Core/Engine/SpellBookChrome.lua#L86) |
| `Chrome.ShouldCreateFluxShowAllRanks` | [L106](../../Core/Engine/SpellBookChrome.lua#L106) |
| `Chrome.RankChromeAllowed` | [L123](../../Core/Engine/SpellBookChrome.lua#L123) |
| `Chrome.GetHost` | [L136](../../Core/Engine/SpellBookChrome.lua#L136) |
| `Chrome.UsesCompactLayout` | [L146](../../Core/Engine/SpellBookChrome.lua#L146) |
| `Chrome.HideRankChrome` | [L186](../../Core/Engine/SpellBookChrome.lua#L186) |
| `Chrome.Layout` | [L258](../../Core/Engine/SpellBookChrome.lua#L258) |

### Core/Engine/Ticker.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Ticker.SetTrace` | [L50](../../Core/Engine/Ticker.lua#L50) |
| `Ticker.Add` | [L68](../../Core/Engine/Ticker.lua#L68) |
| `Ticker.Remove` | [L87](../../Core/Engine/Ticker.lua#L87) |
| `Ticker.IsArmed` | [L105](../../Core/Engine/Ticker.lua#L105) |
| `Ticker.Count` | [L109](../../Core/Engine/Ticker.lua#L109) |
| `Ticker.Ticks` | [L113](../../Core/Engine/Ticker.lua#L113) |
| `Ticker.GetSubscribers` | [L118](../../Core/Engine/Ticker.lua#L118) |

### Core/Engine/Timer.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `handle.Cancel` | [L87](../../Core/Engine/Timer.lua#L87) |
| `Timer.After` | [L101](../../Core/Engine/Timer.lua#L101) |
| `Timer.NewTicker` | [L115](../../Core/Engine/Timer.lua#L115) |
| `Timer.Defer` | [L122](../../Core/Engine/Timer.lua#L122) |
| `Timer.HasPendingPolyfill` | [L126](../../Core/Engine/Timer.lua#L126) |

### Core/Flux.lua

Owner: [07-runtime-architecture.md](../07-runtime-architecture.md).

| Declaration | Source |
|---|---|
| `Flux.AfterLoad` | [L57](../../Core/Flux.lua#L57) |
| `Flux.AfterLogin` | [L66](../../Core/Flux.lua#L66) |
| `Flux.Print` | [L74](../../Core/Flux.lua#L74) |
| `Flux.Safecall` | [L87](../../Core/Flux.lua#L87) |

### Core/FluxAPI/Actions.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `C_Spell.GetSpellInfo_GetSpellInfoRaw` | [L16](../../Core/FluxAPI/Actions.lua#L16) |
| `C_Spell.GetSpellCooldown_GetSpellCooldownImpl` | [L62](../../Core/FluxAPI/Actions.lua#L62) |
| `ns.API.GetNumSpellTabs` | [L115](../../Core/FluxAPI/Actions.lua#L115) |
| `ns.API.GetSpellTabInfo` | [L120](../../Core/FluxAPI/Actions.lua#L120) |
| `ns.API.GetSpellBookItemName` | [L125](../../Core/FluxAPI/Actions.lua#L125) |
| `ns.API.GetSpellBookItemInfo` | [L130](../../Core/FluxAPI/Actions.lua#L130) |
| `ns.API.GetSpellBookItemTexture` | [L135](../../Core/FluxAPI/Actions.lua#L135) |
| `ns.API.IsSpellKnown` | [L140](../../Core/FluxAPI/Actions.lua#L140) |
| `ns.API.GetFlyoutInfo` | [L145](../../Core/FluxAPI/Actions.lua#L145) |
| `ns.API.GetFlyoutSlotInfo` | [L150](../../Core/FluxAPI/Actions.lua#L150) |
| `ns.API.GetSpellDisplayTexture` | [L167](../../Core/FluxAPI/Actions.lua#L167) |
| `ns.API.GetItemInfo` | [L198](../../Core/FluxAPI/Actions.lua#L198) |
| `ns.API.GetAtlasInfo` | [L203](../../Core/FluxAPI/Actions.lua#L203) |
| `ns.API.HasAtlas` | [L211](../../Core/FluxAPI/Actions.lua#L211) |
| `ns.API.GetCurrentTime` | [L215](../../Core/FluxAPI/Actions.lua#L215) |
| `FluxHasAtlas` | [L222](../../Core/FluxAPI/Actions.lua#L222) |
| `FluxGetCurrentTime` | [L226](../../Core/FluxAPI/Actions.lua#L226) |
| `ns.API.GetActionTexture` | [L230](../../Core/FluxAPI/Actions.lua#L230) |
| `ns.API.IsUsableAction` | [L235](../../Core/FluxAPI/Actions.lua#L235) |
| `ns.API.IsConsumableAction` | [L240](../../Core/FluxAPI/Actions.lua#L240) |
| `ns.API.IsStackableAction` | [L245](../../Core/FluxAPI/Actions.lua#L245) |
| `ns.API.IsItemAction` | [L250](../../Core/FluxAPI/Actions.lua#L250) |
| `ns.API.IsEquippedAction` | [L255](../../Core/FluxAPI/Actions.lua#L255) |
| `ns.API.GetActionCharges` | [L260](../../Core/FluxAPI/Actions.lua#L260) |
| `ns.API.GetActionCount` | [L265](../../Core/FluxAPI/Actions.lua#L265) |
| `ns.API.GetActionCooldown` | [L270](../../Core/FluxAPI/Actions.lua#L270) |
| `ns.API.GetActionLossOfControlCooldown` | [L275](../../Core/FluxAPI/Actions.lua#L275) |
| `ns.API.IsActionInRange` | [L280](../../Core/FluxAPI/Actions.lua#L280) |
| `ns.API.NormalizeRangeResult` | [L287](../../Core/FluxAPI/Actions.lua#L287) |
| `ns.API.IsSpellUsable` | [L293](../../Core/FluxAPI/Actions.lua#L293) |
| `FluxGetSpellUsable` | [L348](../../Core/FluxAPI/Actions.lua#L348) |
| `ns.API.IsSpellInRange` | [L372](../../Core/FluxAPI/Actions.lua#L372) |
| `ns.API.CanCheckItemInRange` | [L392](../../Core/FluxAPI/Actions.lua#L392) |
| `ns.API.IsItemInRange` | [L400](../../Core/FluxAPI/Actions.lua#L400) |
| `ns.API.UnitExistsSafe` | [L414](../../Core/FluxAPI/Actions.lua#L414) |
| `ns.API.UnitInRangeSafe` | [L420](../../Core/FluxAPI/Actions.lua#L420) |
| `ns.API.IsAttackAction` | [L440](../../Core/FluxAPI/Actions.lua#L440) |
| `ns.API.IsAutoRepeatAction` | [L445](../../Core/FluxAPI/Actions.lua#L445) |
| `ns.API.IsCurrentAction` | [L450](../../Core/FluxAPI/Actions.lua#L450) |
| `ns.API.HasAction` | [L455](../../Core/FluxAPI/Actions.lua#L455) |
| `ns.API.GetNumShapeshiftForms` | [L460](../../Core/FluxAPI/Actions.lua#L460) |
| `ns.API.GetShapeshiftFormInfo` | [L465](../../Core/FluxAPI/Actions.lua#L465) |
| `ns.API.GetShapeshiftFormCooldown` | [L470](../../Core/FluxAPI/Actions.lua#L470) |
| `ns.API.HasValidStanceTexture` | [L475](../../Core/FluxAPI/Actions.lua#L475) |
| `ns.API.HasValidStances` | [L485](../../Core/FluxAPI/Actions.lua#L485) |
| `ns.API.ShouldUseLegacyComboFrameUI` | [L494](../../Core/FluxAPI/Actions.lua#L494) |
| `ns.API.GetClassPowerInfo` | [L508](../../Core/FluxAPI/Actions.lua#L508) |
| `ns.API.IsUnitPvP` | [L532](../../Core/FluxAPI/Actions.lua#L532) |
| `ns.API.GetUnitFactionGroup` | [L537](../../Core/FluxAPI/Actions.lua#L537) |
| `ns.API.IsWarModeActive` | [L542](../../Core/FluxAPI/Actions.lua#L542) |
| `ns.API.GetWarModeAsset` | [L547](../../Core/FluxAPI/Actions.lua#L547) |
| `ns.API.IsUnitInWarMode` | [L552](../../Core/FluxAPI/Actions.lua#L552) |

### Core/FluxAPI/Auras.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `SafeUnitHealth` | [L10](../../Core/FluxAPI/Auras.lua#L10) |
| `SafeUnitHealthMax` | [L14](../../Core/FluxAPI/Auras.lua#L14) |
| `SafeUnitPower` | [L18](../../Core/FluxAPI/Auras.lua#L18) |
| `SafeUnitPowerMax` | [L22](../../Core/FluxAPI/Auras.lua#L22) |
| `SafeUnitGetIncomingHeals` | [L26](../../Core/FluxAPI/Auras.lua#L26) |
| `SafeUnitGetTotalAbsorbs` | [L34](../../Core/FluxAPI/Auras.lua#L34) |
| `SafeUnitGetTotalHealAbsorbs` | [L43](../../Core/FluxAPI/Auras.lua#L43) |
| `SafeGetAuraSlots` | [L52](../../Core/FluxAPI/Auras.lua#L52) |
| `SafeGetAuraDataBySlot` | [L82](../../Core/FluxAPI/Auras.lua#L82) |
| `SafeUnitTokenAllowsC_UnitAuras` | [L126](../../Core/FluxAPI/Auras.lua#L126) |
| `SafeGetAuraDataByIndex` | [L136](../../Core/FluxAPI/Auras.lua#L136) |
| `SafeGetAuraDataByAuraInstanceID` | [L159](../../Core/FluxAPI/Auras.lua#L159) |
| `SafeGetAuraDuration` | [L190](../../Core/FluxAPI/Auras.lua#L190) |
| `SafeGetAuraApplicationDisplayCount` | [L213](../../Core/FluxAPI/Auras.lua#L213) |
| `RememberSharedRefreshableSpell` | [L245](../../Core/FluxAPI/Auras.lua#L245) |
| `IsSharedRefreshableSpell` | [L253](../../Core/FluxAPI/Auras.lua#L253) |
| `AuraDataHasRefreshPrediction` | [L288](../../Core/FluxAPI/Auras.lua#L288) |
| `AuraDataCanApplyAsOwn` | [L309](../../Core/FluxAPI/Auras.lua#L309) |
| `AuraDataSourceIsPlayerOrPet` | [L320](../../Core/FluxAPI/Auras.lua#L320) |
| `AuraDataTreatAsPlayerHarmful` | [L339](../../Core/FluxAPI/Auras.lua#L339) |
| `AuraDataIsSharedRefreshableForNameplate` | [L361](../../Core/FluxAPI/Auras.lua#L361) |
| `SafeBooleanTest` | [L430](../../Core/FluxAPI/Auras.lua#L430) |
| `SafeHealthPercent` | [L459](../../Core/FluxAPI/Auras.lua#L459) |
| `SafePowerPercent` | [L470](../../Core/FluxAPI/Auras.lua#L470) |
| `GetHealthPercent100` | [L481](../../Core/FluxAPI/Auras.lua#L481) |
| `GetPowerPercent100` | [L498](../../Core/FluxAPI/Auras.lua#L498) |

### Core/FluxAPI/Capabilities.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `ns.API.GetMaxBagIndex` | [L109](../../Core/FluxAPI/Capabilities.lua#L109) |
| `ns.API.hasBlizzardSettingsKeybindings` | [L114](../../Core/FluxAPI/Capabilities.lua#L114) |
| `ns.API.hasBlizzardActionBarsOverrides` | [L124](../../Core/FluxAPI/Capabilities.lua#L124) |
| `ns.API.GetFluxBlizzardActionBarUIMode` | [L133](../../Core/FluxAPI/Capabilities.lua#L133) |
| `FLUX_API.HasUnifiedBankUI` | [L173](../../Core/FluxAPI/Capabilities.lua#L173) |
| `FLUX_API.UseLegacyBankSlotsUI` | [L189](../../Core/FluxAPI/Capabilities.lua#L189) |
| `FLUX_API.UsesPlayerBagsInBank` | [L194](../../Core/FluxAPI/Capabilities.lua#L194) |
| `FLUX_API.HasReagentBankContainer` | [L212](../../Core/FluxAPI/Capabilities.lua#L212) |
| `FLUX_API.GetReagentBankContainerID` | [L226](../../Core/FluxAPI/Capabilities.lua#L226) |
| `FLUX_API.EnumerateBankTabIDs` | [L238](../../Core/FluxAPI/Capabilities.lua#L238) |
| `FLUX_API.IsBankTabSentinel` | [L247](../../Core/FluxAPI/Capabilities.lua#L247) |
| `FLUX_API.IsUnifiedBankTabBag` | [L261](../../Core/FluxAPI/Capabilities.lua#L261) |
| `H.RefreshUnifiedBankUIFlags` | [L270](../../Core/FluxAPI/Capabilities.lua#L270) |
| `FLUX_API.HasCompactRaidFrameManager` | [L292](../../Core/FluxAPI/Capabilities.lua#L292) |
| `FLUX_API.IsAssistedCombatLabButton` | [L297](../../Core/FluxAPI/Capabilities.lua#L297) |
| `FLUX_API.RefreshFocusUnitCapability` | [L334](../../Core/FluxAPI/Capabilities.lua#L334) |
| `FLUX_API.RefreshKeyringContainerState` | [L345](../../Core/FluxAPI/Capabilities.lua#L345) |
| `FLUX_API.ClientSupportsCombatAmmoExtraButton` | [L359](../../Core/FluxAPI/Capabilities.lua#L359) |
| `FLUX_API.ClientSupportsSingleButtonAssistant` | [L378](../../Core/FluxAPI/Capabilities.lua#L378) |
| `FLUX_API.ApplyAssistedCombatCustomActionBarCompat` | [L385](../../Core/FluxAPI/Capabilities.lua#L385) |

### Core/FluxAPI/CVars.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `thenreturntrueendendreturnfalseend_G.FluxGetCVar` | [L56](../../Core/FluxAPI/CVars.lua#L56) |
| `endreturnnilend_G.FluxGetCVarDefault` | [L65](../../Core/FluxAPI/CVars.lua#L65) |
| `endreturnnilend_G.FluxSetCVar` | [L74](../../Core/FluxAPI/CVars.lua#L74) |

### Core/FluxAPI/Events.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `FluxSafeRegisterEvent` | [L60](../../Core/FluxAPI/Events.lua#L60) |
| `FluxSafeRegisterUnitEvent` | [L74](../../Core/FluxAPI/Events.lua#L74) |
| `FluxRegisterLearnedSpellEvents` | [L88](../../Core/FluxAPI/Events.lua#L88) |

### Core/FluxAPI/RetailSecrets.lua

Owner: [03-midnight-constraints.md](../03-midnight-constraints.md).

| Declaration | Source |
|---|---|
| `ns.API.GetSpecializationRoleSafe` | [L22](../../Core/FluxAPI/RetailSecrets.lua#L22) |
| `ns.API.IsPlayerEffectivelyTankSafe` | [L55](../../Core/FluxAPI/RetailSecrets.lua#L55) |
| `ns.API.FluxInstallSpecializationRoleCompat` | [L90](../../Core/FluxAPI/RetailSecrets.lua#L90) |
| `ns.API.GetSpecializationRoleSafe_G.GetSpecializationRole` | [L102](../../Core/FluxAPI/RetailSecrets.lua#L102) |

### Core/FluxAPI/Secrets.lua

Owner: [03-midnight-constraints.md](../03-midnight-constraints.md).

| Declaration | Source |
|---|---|
| `ns.API.CanAccessValue` | [L4](../../Core/FluxAPI/Secrets.lua#L4) |
| `ns.API.SafeAccessibleString` | [L12](../../Core/FluxAPI/Secrets.lua#L12) |
| `ns.API.CanAccessSecrets` | [L26](../../Core/FluxAPI/Secrets.lua#L26) |
| `ns.API.IsSecretValue` | [L33](../../Core/FluxAPI/Secrets.lua#L33) |
| `ns.API.SafeGetNumber` | [L43](../../Core/FluxAPI/Secrets.lua#L43) |
| `ns.API.KeepLastNumber` | [L63](../../Core/FluxAPI/Secrets.lua#L63) |
| `ns.API.CoerceNumberLoose` | [L94](../../Core/FluxAPI/Secrets.lua#L94) |
| `ns.API.SafeCompare` | [L106](../../Core/FluxAPI/Secrets.lua#L106) |
| `ns.API.SafeEqualForCache` | [L133](../../Core/FluxAPI/Secrets.lua#L133) |
| `ns.API.SafeGUIDsEqual` | [L144](../../Core/FluxAPI/Secrets.lua#L144) |
| `ns.API.SafeGUIDChangedForRefresh` | [L154](../../Core/FluxAPI/Secrets.lua#L154) |
| `ns.API.AccessibleGUIDForUnit` | [L162](../../Core/FluxAPI/Secrets.lua#L162) |
| `ns.API.SafeBooleanTest` | [L182](../../Core/FluxAPI/Secrets.lua#L182) |
| `SafeGetNumber` | [L211](../../Core/FluxAPI/Secrets.lua#L211) |
| `SafeNumber` | [L221](../../Core/FluxAPI/Secrets.lua#L221) |
| `SafeCompareValues` | [L225](../../Core/FluxAPI/Secrets.lua#L225) |
| `IsWoWLegacyClient` | [L243](../../Core/FluxAPI/Secrets.lua#L243) |
| `IsWoWModernClient` | [L247](../../Core/FluxAPI/Secrets.lua#L247) |
| `IsTalentTreeClient` | [L251](../../Core/FluxAPI/Secrets.lua#L251) |

### Core/FluxAPI/Timers.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `frame.Cancel` | [L49](../../Core/FluxAPI/Timers.lua#L49) |
| `ns.API.TimerAfter` | [L60](../../Core/FluxAPI/Timers.lua#L60) |
| `ns.API.NewTicker` | [L64](../../Core/FluxAPI/Timers.lua#L64) |
| `FluxTimerAfter` | [L68](../../Core/FluxAPI/Timers.lua#L68) |
| `FluxNewTicker` | [L72](../../Core/FluxAPI/Timers.lua#L72) |
| `FluxSafeDefer` | [L76](../../Core/FluxAPI/Timers.lua#L76) |
| `FluxAPICompat.After` | [L92](../../Core/FluxAPI/Timers.lua#L92) |

### Core/FluxAPI/UI.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `FluxGetContainerItemID` | [L62](../../Core/FluxAPI/UI.lua#L62) |
| `FluxGetContainerItemLink` | [L74](../../Core/FluxAPI/UI.lua#L74) |
| `FluxGetItemCount` | [L86](../../Core/FluxAPI/UI.lua#L86) |
| `FluxIsItemUsable` | [L114](../../Core/FluxAPI/UI.lua#L114) |
| `FluxSafeTooltipSetBagItem` | [L145](../../Core/FluxAPI/UI.lua#L145) |
| `FluxSafeTooltipSetInventoryItem` | [L159](../../Core/FluxAPI/UI.lua#L159) |
| `FluxSafeGameTooltipShow` | [L173](../../Core/FluxAPI/UI.lua#L173) |
| `FluxSafeTooltipSetItemCombatMinimal` | [L180](../../Core/FluxAPI/UI.lua#L180) |
| `FluxSafeSetTooltipOwner` | [L188](../../Core/FluxAPI/UI.lua#L188) |
| `FluxFormatPortraitCombatNumber` | [L198](../../Core/FluxAPI/UI.lua#L198) |
| `FluxOpenMountCollection` | [L221](../../Core/FluxAPI/UI.lua#L221) |
| `FluxOpenCompanionMounts` | [L231](../../Core/FluxAPI/UI.lua#L231) |
| `FluxSecureUIPanelsBlockInsecureWork` | [L244](../../Core/FluxAPI/UI.lua#L244) |
| `FluxRemoveFrameFromEditMode` | [L267](../../Core/FluxAPI/UI.lua#L267) |
| `FluxRemoveFramesFromEditMode` | [L277](../../Core/FluxAPI/UI.lua#L277) |
| `FluxSilenceEditModeSpecLayoutRefresh` | [L290](../../Core/FluxAPI/UI.lua#L290) |
| `FluxEditModeBusy` | [L327](../../Core/FluxAPI/UI.lua#L327) |
| `FluxAfterEditMode` | [L365](../../Core/FluxAPI/UI.lua#L365) |
| `FLUX_API.ClientHasMicroMenuFeature` | [L587](../../Core/FluxAPI/UI.lua#L587) |
| `FLUX_API.ClientHasMinimapGroupFinder` | [L595](../../Core/FluxAPI/UI.lua#L595) |
| `FLUX_API.ClientHasBlizzardMicroGroupFinder` | [L600](../../Core/FluxAPI/UI.lua#L600) |
| `FluxClientHasMicroMenuFeature` | [L613](../../Core/FluxAPI/UI.lua#L613) |
| `FluxClientHasMinimapGroupFinder` | [L614](../../Core/FluxAPI/UI.lua#L614) |
| `FluxClientHasBlizzardMicroGroupFinder` | [L615](../../Core/FluxAPI/UI.lua#L615) |
| `FluxGetStandardMicroButtonSize` | [L620](../../Core/FluxAPI/UI.lua#L620) |
| `FluxStandardizeMicroButton` | [L625](../../Core/FluxAPI/UI.lua#L625) |
| `FluxGetMicroButtonSpacing` | [L638](../../Core/FluxAPI/UI.lua#L638) |
| `FluxDetectMicroButtonTopGap` | [L640](../../Core/FluxAPI/UI.lua#L640) |
| `FluxGetMicroButtonTopGap` | [L647](../../Core/FluxAPI/UI.lua#L647) |
| `FluxShouldApplyMicroButtonTopGapLayout` | [L653](../../Core/FluxAPI/UI.lua#L653) |
| `FluxShouldUseDfStyleVerticalMicroMenuGrid` | [L658](../../Core/FluxAPI/UI.lua#L658) |
| `FluxGetMicroMenuLayoutTopGap` | [L664](../../Core/FluxAPI/UI.lua#L664) |
| `FluxGetMicroMenuLegacyBarHeightExtra` | [L669](../../Core/FluxAPI/UI.lua#L669) |
| `FluxGetMicroButtonLayoutInfo` | [L671](../../Core/FluxAPI/UI.lua#L671) |
| `FluxPlayerCanUseTalentMicroButton` | [L687](../../Core/FluxAPI/UI.lua#L687) |
| `FluxUpdateTalentMicroButtonPreDF` | [L710](../../Core/FluxAPI/UI.lua#L710) |
| `FluxSetupPortraitModel` | [L753](../../Core/FluxAPI/UI.lua#L753) |
| `unitmodel.SetUnit` | [L787](../../Core/FluxAPI/UI.lua#L787) |
| `FluxNeedsPortraitCompat` | [L821](../../Core/FluxAPI/UI.lua#L821) |
| `ns.API.SafeSetAtlas` | [L838](../../Core/FluxAPI/UI.lua#L838) |
| `CreateLegacyBattlefieldBorderPiece` | [L870](../../Core/FluxAPI/UI.lua#L870) |
| `FluxUI_UsesAlternativeBagUI` | [L886](../../Core/FluxAPI/UI.lua#L886) |
| `FluxRegisterSettingsCategory` | [L899](../../Core/FluxAPI/UI.lua#L899) |
| `thenifSettingsandSettings.RegisterCanvasLayoutCategoryandSettings.RegisterAddOnCategorythenInterfaceOptions_AddCategory` | [L923](../../Core/FluxAPI/UI.lua#L923) |
| `FluxAPICompat.GetPlayerHasMana` | [L947](../../Core/FluxAPI/UI.lua#L947) |
| `FluxAPICompat.ResetManaCache` | [L955](../../Core/FluxAPI/UI.lua#L955) |
| `FluxAPICompat.CancelBankOpenWork` | [L988](../../Core/FluxAPI/UI.lua#L988) |
| `FluxCancelBankOpenWork` | [L993](../../Core/FluxAPI/UI.lua#L993) |
| `FluxAPICompat.DeferBankOpenWork` | [L995](../../Core/FluxAPI/UI.lua#L995) |
| `FluxDeferBankOpenWork` | [L1010](../../Core/FluxAPI/UI.lua#L1010) |
| `FluxAPICompat.IsUnifiedBankPaintReady` | [L1012](../../Core/FluxAPI/UI.lua#L1012) |
| `FluxIsUnifiedBankPaintReady` | [L1016](../../Core/FluxAPI/UI.lua#L1016) |
| `FluxAPICompat.DeferBankTransferWork` | [L1025](../../Core/FluxAPI/UI.lua#L1025) |
| `FluxDeferBankTransferWork` | [L1035](../../Core/FluxAPI/UI.lua#L1035) |
| `ns.API.GetNumPlayerTalentGroups` | [L1042](../../Core/FluxAPI/UI.lua#L1042) |
| `ns.API.GetActivePlayerTalentGroup` | [L1054](../../Core/FluxAPI/UI.lua#L1054) |
| `ns.API.SetActivePlayerTalentGroup` | [L1066](../../Core/FluxAPI/UI.lua#L1066) |
| `ns.API.TogglePlayerDualTalentGroup` | [L1076](../../Core/FluxAPI/UI.lua#L1076) |
| `ns.API.GetPlayerSpecFlyoutEntries` | [L1085](../../Core/FluxAPI/UI.lua#L1085) |
| `ns.API.GetPlayerSpecFlyoutEntriesIncludingActive` | [L1107](../../Core/FluxAPI/UI.lua#L1107) |
| `ns.API.TrySetPlayerSpecialization` | [L1122](../../Core/FluxAPI/UI.lua#L1122) |
| `ns.API.CanPlayerUseTalentSpecUI` | [L1131](../../Core/FluxAPI/UI.lua#L1131) |
| `ns.API.GetPlayerSpecSwitchMode` | [L1139](../../Core/FluxAPI/UI.lua#L1139) |
| `ns.API.HasPlayerTransmogOutfitAPI` | [L1148](../../Core/FluxAPI/UI.lua#L1148) |
| `ns.API.GetPlayerTransmogOutfitEntries` | [L1159](../../Core/FluxAPI/UI.lua#L1159) |
| `ns.API.GetPlayerTransmogOutfitAction` | [L1210](../../Core/FluxAPI/UI.lua#L1210) |
| `ns.API.IsPlayerTransmogOutfitActive` | [L1235](../../Core/FluxAPI/UI.lua#L1235) |
| `ns.API.GetPlayerTransmogOutfitIDForSpell` | [L1246](../../Core/FluxAPI/UI.lua#L1246) |
| `ns.API.TryApplyPlayerTransmogOutfit` | [L1255](../../Core/FluxAPI/UI.lua#L1255) |
| `ns.API.TryPickupPlayerTransmogOutfit` | [L1263](../../Core/FluxAPI/UI.lua#L1263) |
| `FluxIsDetailsActorLocalPlayer` | [L1286](../../Core/FluxAPI/UI.lua#L1286) |
| `FluxIsDetailsMeterSourceLocalPlayer` | [L1308](../../Core/FluxAPI/UI.lua#L1308) |

### Core/FluxBlizzardDropdown.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `DD.IsMouseOver` | [L16](../../Core/FluxBlizzardDropdown.lua#L16) |
| `DD.UseClassicMenu` | [L104](../../Core/FluxBlizzardDropdown.lua#L104) |
| `DD.WantsGamepadMenu` | [L110](../../Core/FluxBlizzardDropdown.lua#L110) |
| `DD.InstallGamepadClick` | [L120](../../Core/FluxBlizzardDropdown.lua#L120) |
| `trueinfo.func` | [L171](../../Core/FluxBlizzardDropdown.lua#L171) |
| `DD.Create` | [L179](../../Core/FluxBlizzardDropdown.lua#L179) |
| `dropdown:FluxSetText` | [L208](../../Core/FluxBlizzardDropdown.lua#L208) |
| `dropdown:FluxSetMenu` | [L235](../../Core/FluxBlizzardDropdown.lua#L235) |

### Core/Hotkey.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Hotkey.Path` | [L31](../../Core/Hotkey.lua#L31) |
| `Hotkey.Markup` | [L38](../../Core/Hotkey.lua#L38) |
| `Hotkey.IconFor` | [L49](../../Core/Hotkey.lua#L49) |
| `Hotkey.LivePrefix` | [L54](../../Core/Hotkey.lua#L54) |
| `Hotkey.Format` | [L65](../../Core/Hotkey.lua#L65) |

### Core/Module.lua

Owner: [07-runtime-architecture.md](../07-runtime-architecture.md).

| Declaration | Source |
|---|---|
| `Module.IsEligible` | [L57](../../Core/Module.lua#L57) |
| `Module.Register` | [L71](../../Core/Module.lua#L71) |
| `Module.Enable` | [L92](../../Core/Module.lua#L92) |
| `Module.Disable` | [L121](../../Core/Module.lua#L121) |
| `Module.IsEnabled` | [L133](../../Core/Module.lua#L133) |
| `Module.EnableEligible` | [L137](../../Core/Module.lua#L137) |
| `Module.List` | [L148](../../Core/Module.lua#L148) |

### Core/Optional.lua

Owner: [07-runtime-architecture.md](../07-runtime-architecture.md).

| Declaration | Source |
|---|---|
| `probes.Syndicator` | [L26](../../Core/Optional.lua#L26) |
| `endprobes.Baganator` | [L41](../../Core/Optional.lua#L41) |
| `endprobes.Details` | [L47](../../Core/Optional.lua#L47) |
| `endprobes.BigDebuffs` | [L53](../../Core/Optional.lua#L53) |
| `endprobes.TacoTip` | [L58](../../Core/Optional.lua#L58) |
| `endprobes.ConsolePort` | [L63](../../Core/Optional.lua#L63) |
| `endprobes.Questie` | [L68](../../Core/Optional.lua#L68) |
| `endprobes.Masque` | [L73](../../Core/Optional.lua#L73) |
| `endprobes.Clicked` | [L78](../../Core/Optional.lua#L78) |
| `Optional.Get` | [L83](../../Core/Optional.lua#L83) |
| `Optional.IsLoaded` | [L97](../../Core/Optional.lua#L97) |
| `Optional.IsReady` | [L101](../../Core/Optional.lua#L101) |
| `Optional.Snapshot` | [L105](../../Core/Optional.lua#L105) |

### Core/SecureClickProxy.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `EnsurePoll` | [L129](../../Core/SecureClickProxy.lua#L129) |
| `Proxy.Attach` | [L172](../../Core/SecureClickProxy.lua#L172) |

### Core/Startup.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Startup.Configure` | [L15](../../Core/Startup.lua#L15) |
| `Startup.Mark` | [L22](../../Core/Startup.lua#L22) |
| `Startup.Count` | [L31](../../Core/Startup.lua#L31) |
| `Startup.ObserveOptional` | [L36](../../Core/Startup.lua#L36) |
| `Startup.Layout` | [L70](../../Core/Startup.lua#L70) |
| `Startup.CheckLayout` | [L78](../../Core/Startup.lua#L78) |
| `Startup.IsRecording` | [L82](../../Core/Startup.lua#L82) |
| `Startup.Snapshot` | [L86](../../Core/Startup.lua#L86) |
| `SlashCmdList.FLUXSTARTUP` | [L100](../../Core/Startup.lua#L100) |

### ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Module.Create` | [L168](../../ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua#L168) |

### ExtraButtonSystem/CombatGrid/Buttons/Bandage.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Module.Create` | [L45](../../ExtraButtonSystem/CombatGrid/Buttons/Bandage.lua#L45) |

### ExtraButtonSystem/CombatGrid/Buttons/HealPotion.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Module.Create` | [L54](../../ExtraButtonSystem/CombatGrid/Buttons/HealPotion.lua#L54) |

### ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `btn.UpdateTextCountbtn.UpdateTextCount` | [L197](../../ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua#L197) |
| `Module.UpdateKeybinding` | [L210](../../ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua#L210) |
| `Module.RefreshCountOnly` | [L257](../../ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua#L257) |
| `Module.Update` | [L261](../../ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua#L261) |
| `Module.Create` | [L385](../../ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua#L385) |

### ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Module.KnowsAnyConjureSpell` | [L18](../../ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua#L18) |
| `btn.UpdateTextCountiforiginalUpdateTextCountthenbtn.UpdateTextCount` | [L209](../../ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua#L209) |
| `Module.UpdateKeybinding` | [L221](../../ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua#L221) |
| `Module.RefreshCountOnly` | [L275](../../ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua#L275) |
| `Module.Update` | [L279](../../ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua#L279) |
| `Module.Create` | [L457](../../ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua#L457) |

### ExtraButtonSystem/CombatGrid/Buttons/ManaPotion.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Module.Create` | [L59](../../ExtraButtonSystem/CombatGrid/Buttons/ManaPotion.lua#L59) |

### ExtraButtonSystem/CombatGrid/Grid.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Grid.New` | [L24](../../ExtraButtonSystem/CombatGrid/Grid.lua#L24) |
| `grid:CreateButton` | [L75](../../ExtraButtonSystem/CombatGrid/Grid.lua#L75) |
| `btn:SetPlaceholder` | [L141](../../ExtraButtonSystem/CombatGrid/Grid.lua#L141) |
| `btn:ClearPlaceholder` | [L167](../../ExtraButtonSystem/CombatGrid/Grid.lua#L167) |
| `btn:SetLocked` | [L182](../../ExtraButtonSystem/CombatGrid/Grid.lua#L182) |
| `btn:SetCount` | [L194](../../ExtraButtonSystem/CombatGrid/Grid.lua#L194) |
| `btn:ShowTooltip` | [L217](../../ExtraButtonSystem/CombatGrid/Grid.lua#L217) |
| `btn:OnEnter` | [L224](../../ExtraButtonSystem/CombatGrid/Grid.lua#L224) |
| `btn:OnLeave` | [L233](../../ExtraButtonSystem/CombatGrid/Grid.lua#L233) |
| `btn:FullRefresh` | [L241](../../ExtraButtonSystem/CombatGrid/Grid.lua#L241) |
| `btn:Show` | [L255](../../ExtraButtonSystem/CombatGrid/Grid.lua#L255) |
| `btn:Hide` | [L259](../../ExtraButtonSystem/CombatGrid/Grid.lua#L259) |
| `grid:ComputeDynamicPriorities` | [L327](../../ExtraButtonSystem/CombatGrid/Grid.lua#L327) |
| `grid:ConsolidateColumns` | [L411](../../ExtraButtonSystem/CombatGrid/Grid.lua#L411) |
| `grid:BeginLayout` | [L538](../../ExtraButtonSystem/CombatGrid/Grid.lua#L538) |
| `grid:EndLayout` | [L542](../../ExtraButtonSystem/CombatGrid/Grid.lua#L542) |
| `grid:ScheduleRelayout` | [L550](../../ExtraButtonSystem/CombatGrid/Grid.lua#L550) |
| `grid:Relayout` | [L576](../../ExtraButtonSystem/CombatGrid/Grid.lua#L576) |
| `grid:Relayout` | [L756](../../ExtraButtonSystem/CombatGrid/Grid.lua#L756) |
| `grid:RefreshAllModules` | [L765](../../ExtraButtonSystem/CombatGrid/Grid.lua#L765) |
| `grid:Show` | [L783](../../ExtraButtonSystem/CombatGrid/Grid.lua#L783) |
| `grid:Hide` | [L784](../../ExtraButtonSystem/CombatGrid/Grid.lua#L784) |
| `FluxCombatGrid_ApplyAppearanceAccent` | [L790](../../ExtraButtonSystem/CombatGrid/Grid.lua#L790) |
| `Grid.RefreshAfterVisibilityChange` | [L816](../../ExtraButtonSystem/CombatGrid/Grid.lua#L816) |

### ExtraButtonSystem/CombatGrid/GridManager.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Manager:UpdateAnchor` | [L63](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L63) |
| `Manager:FinalizeLayout` | [L91](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L91) |
| `Manager:InitializeButtons` | [L117](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L117) |
| `Manager:RegisterCombatRefresh` | [L169](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L169) |
| `Manager:UnregisterCombatRefresh` | [L179](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L179) |
| `Manager:_RunCombatRefreshers` | [L185](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L185) |
| `Manager:_StartCombatRefreshTicker` | [L193](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L193) |
| `Manager:_StopCombatRefreshTicker` | [L209](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L209) |
| `Manager:ScheduleAllUpdates` | [L220](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L220) |
| `Manager:GetDebugStats` | [L290](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L290) |

### ExtraButtonSystem/Engine/Action.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Action.GetMountInfo` | [L403](../../ExtraButtonSystem/Engine/Action.lua#L403) |
| `Action.SupportsAssistant` | [L437](../../ExtraButtonSystem/Engine/Action.lua#L437) |
| `Action.GetAssistantActionSpell` | [L445](../../ExtraButtonSystem/Engine/Action.lua#L445) |
| `Action.GetAssistantNextSpell` | [L463](../../ExtraButtonSystem/Engine/Action.lua#L463) |
| `Action.IsAssistantSpell` | [L484](../../ExtraButtonSystem/Engine/Action.lua#L484) |
| `Action.GetAssistantButton` | [L514](../../ExtraButtonSystem/Engine/Action.lua#L514) |
| `Action.LayoutAssistant` | [L584](../../ExtraButtonSystem/Engine/Action.lua#L584) |
| `Action.UpdateAssistantChrome` | [L588](../../ExtraButtonSystem/Engine/Action.lua#L588) |
| `existing.OnUpdate` | [L621](../../ExtraButtonSystem/Engine/Action.lua#L621) |
| `frame.OnUpdate` | [L636](../../ExtraButtonSystem/Engine/Action.lua#L636) |
| `Action.AttachAssistant` | [L675](../../ExtraButtonSystem/Engine/Action.lua#L675) |
| `Action.ClearAssistant` | [L698](../../ExtraButtonSystem/Engine/Action.lua#L698) |
| `Action.SyncAssistant` | [L718](../../ExtraButtonSystem/Engine/Action.lua#L718) |
| `Action.RefreshAssistantIdentity` | [L742](../../ExtraButtonSystem/Engine/Action.lua#L742) |
| `Action.RefreshAssistantChrome` | [L760](../../ExtraButtonSystem/Engine/Action.lua#L760) |
| `Action.PaintAssistantButtons` | [L774](../../ExtraButtonSystem/Engine/Action.lua#L774) |
| `Action.RebindAssistant` | [L791](../../ExtraButtonSystem/Engine/Action.lua#L791) |
| `Action.ClearEnv` | [L823](../../ExtraButtonSystem/Engine/Action.lua#L823) |
| `Action.InvalidateMacroParseCache` | [L1386](../../ExtraButtonSystem/Engine/Action.lua#L1386) |
| `Action.ShownFromBody` | [L1562](../../ExtraButtonSystem/Engine/Action.lua#L1562) |
| `Action.TranslateMacro` | [L1664](../../ExtraButtonSystem/Engine/Action.lua#L1664) |
| `Action.TranslateMatching` | [L1797](../../ExtraButtonSystem/Engine/Action.lua#L1797) |
| `Action.RefreshMacroDisplay` | [L1822](../../ExtraButtonSystem/Engine/Action.lua#L1822) |
| `Action.SyncMacroProbes` | [L1994](../../ExtraButtonSystem/Engine/Action.lua#L1994) |
| `Action.RequestMacroDisplay` | [L2029](../../ExtraButtonSystem/Engine/Action.lua#L2029) |
| `Action.RefreshMacroBindings` | [L2106](../../ExtraButtonSystem/Engine/Action.lua#L2106) |
| `Action.OnMacrosUpdated` | [L2168](../../ExtraButtonSystem/Engine/Action.lua#L2168) |
| `Action.EnableMacroPrune` | [L2177](../../ExtraButtonSystem/Engine/Action.lua#L2177) |
| `Action.ForceMacrosLoaded` | [L2184](../../ExtraButtonSystem/Engine/Action.lua#L2184) |
| `Action.RefreshOutfits` | [L2213](../../ExtraButtonSystem/Engine/Action.lua#L2213) |
| `Action.SetAction` | [L2230](../../ExtraButtonSystem/Engine/Action.lua#L2230) |
| `Action.MouseoverCastSpell` | [L2301](../../ExtraButtonSystem/Engine/Action.lua#L2301) |
| `Action.RefreshMounts` | [L2312](../../ExtraButtonSystem/Engine/Action.lua#L2312) |
| `Action.Clear` | [L2345](../../ExtraButtonSystem/Engine/Action.lua#L2345) |
| `Action.Pickup` | [L2532](../../ExtraButtonSystem/Engine/Action.lua#L2532) |
| `Action.NoteFlyoutPopupSpell` | [L2595](../../ExtraButtonSystem/Engine/Action.lua#L2595) |
| `Action.NoteFlyoutPopupItem` | [L2604](../../ExtraButtonSystem/Engine/Action.lua#L2604) |
| `Action.OnReceiveDrag` | [L2807](../../ExtraButtonSystem/Engine/Action.lua#L2807) |
| `Action.OnDragStart` | [L2865](../../ExtraButtonSystem/Engine/Action.lua#L2865) |
| `Action.OnEnter` | [L2980](../../ExtraButtonSystem/Engine/Action.lua#L2980) |
| `Action.AppendTooltipExtras` | [L3012](../../ExtraButtonSystem/Engine/Action.lua#L3012) |
| `Action.OnLeave` | [L3038](../../ExtraButtonSystem/Engine/Action.lua#L3038) |
| `Action.UpdateTooltip` | [L3127](../../ExtraButtonSystem/Engine/Action.lua#L3127) |
| `FluxButton:SetAction` | [L3280](../../ExtraButtonSystem/Engine/Action.lua#L3280) |
| `FluxButton:OnEnter` | [L3284](../../ExtraButtonSystem/Engine/Action.lua#L3284) |
| `FluxButton:OnLeave` | [L3291](../../ExtraButtonSystem/Engine/Action.lua#L3291) |
| `FluxButton:FullRefresh` | [L3295](../../ExtraButtonSystem/Engine/Action.lua#L3295) |
| `FluxButton:TranslateFace` | [L3301](../../ExtraButtonSystem/Engine/Action.lua#L3301) |
| `FluxButton:TranslateMacro` | [L3305](../../ExtraButtonSystem/Engine/Action.lua#L3305) |
| `FluxButton:ClearAction` | [L3309](../../ExtraButtonSystem/Engine/Action.lua#L3309) |
| `FluxButton:Pickup` | [L3313](../../ExtraButtonSystem/Engine/Action.lua#L3313) |

### ExtraButtonSystem/Engine/Badge.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Badge.StackCount` | [L19](../../ExtraButtonSystem/Engine/Badge.lua#L19) |
| `Badge.SyncCountFont` | [L95](../../ExtraButtonSystem/Engine/Badge.lua#L95) |
| `Badge.SyncFrameLevel` | [L139](../../ExtraButtonSystem/Engine/Badge.lua#L139) |
| `Badge.Layout` | [L225](../../ExtraButtonSystem/Engine/Badge.lua#L225) |
| `Badge.ShowVisual` | [L295](../../ExtraButtonSystem/Engine/Badge.lua#L295) |
| `Badge.HideVisual` | [L317](../../ExtraButtonSystem/Engine/Badge.lua#L317) |
| `Badge.ApplyVisualSpellTexture` | [L334](../../ExtraButtonSystem/Engine/Badge.lua#L334) |
| `Badge.Clear` | [L357](../../ExtraButtonSystem/Engine/Badge.lua#L357) |
| `Badge.New` | [L371](../../ExtraButtonSystem/Engine/Badge.lua#L371) |
| `endbtn.Layout` | [L404](../../ExtraButtonSystem/Engine/Badge.lua#L404) |
| `endbtn.ShowVisual` | [L407](../../ExtraButtonSystem/Engine/Badge.lua#L407) |
| `endbtn.HideVisual` | [L410](../../ExtraButtonSystem/Engine/Badge.lua#L410) |
| `endbtn.ApplyVisualSpellTexture` | [L413](../../ExtraButtonSystem/Engine/Badge.lua#L413) |
| `endbtn.Clear` | [L416](../../ExtraButtonSystem/Engine/Badge.lua#L416) |

### ExtraButtonSystem/Engine/ConsumableBind.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Bridge.ShouldHoldItemIdentity` | [L85](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L85) |
| `Bridge.KeepConsumableSlot` | [L90](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L90) |
| `Bridge.BagCount` | [L208](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L208) |
| `Bridge.DisplayItemCount` | [L215](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L215) |
| `Bridge.IsManaGemChargeBased` | [L246](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L246) |
| `Bridge.ShouldUseChargeBasedManaGemOnly` | [L253](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L253) |
| `Bridge.KnowsManaGemConjureSpell` | [L356](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L356) |
| `Bridge.IsManaGemConjureFree` | [L380](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L380) |
| `Bridge.ShouldStickyManaGemItem` | [L390](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L390) |
| `Bridge.GetPreferredManaGemItemID` | [L395](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L395) |
| `Bridge.GetNextManaGemConjureSpell` | [L403](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L403) |
| `Bridge.GetBestOwned` | [L485](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L485) |
| `Bridge.GetOwnedLadder` | [L637](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L637) |
| `Bridge.PromoteIfBetter` | [L843](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L843) |
| `Bridge.CanCreate` | [L895](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L895) |
| `Bridge.GetPreferredCreateSpell` | [L904](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L904) |
| `Bridge.GetFoodConjureSpell` | [L915](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L915) |
| `Bridge.GetFoodSecondaryConjureSpell` | [L923](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L923) |
| `Bridge.GetWaterConjureSpell` | [L931](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L931) |
| `Bridge.GetWaterSecondaryConjureSpell` | [L939](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L939) |
| `Bridge.ApplyRightClickMacro` | [L954](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L954) |
| `Bridge.ResolveSpellName` | [L973](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L973) |
| `Bridge.ApplyRightClickSpell` | [L1000](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1000) |
| `Bridge.ApplyShiftRightClickSpell` | [L1057](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1057) |
| `Bridge.ApplyCtrlRightClickSpell` | [L1113](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1113) |
| `Bridge.ApplyUseAndConjureBindings` | [L1172](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1172) |
| `Bridge.BuildUseItemMacro` | [L1250](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1250) |
| `Bridge.BuildCastSequenceMacro` | [L1258](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1258) |
| `Bridge.After` | [L1279](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1279) |
| `Bridge.DeleteOneOwned` | [L1290](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1290) |
| `Bridge.IsConjured` | [L1326](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1326) |
| `Bridge.DeleteOneConjuredOwned` | [L1353](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1353) |
| `Bridge.ApplyBinding` | [L1361](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1361) |
| `Bridge.FormatSpellTooltipLine` | [L1394](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1394) |
| `Bridge.ResetFluxTooltipGap` | [L1509](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1509) |
| `Bridge._EnsureFluxTooltipGap` | [L1516](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1516) |
| `Bridge.AppendConjureSpellLines` | [L1524](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1524) |
| `Bridge.AppendTierStatusLines` | [L1674](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1674) |
| `Bridge.AppendDeleteStackHint` | [L1767](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1767) |
| `Bridge.WireRestockEdit` | [L1803](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1803) |
| `Bridge.GetRestockClickHint` | [L1845](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1845) |
| `Bridge.AppendRestockEditHint` | [L1849](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1849) |
| `Bridge.GetBestCraftable` | [L1941](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1941) |
| `Bridge.CanCraft` | [L1950](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1950) |
| `Bridge.GetCraftMacro` | [L1959](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1959) |
| `Bridge.ApplyCraftOrRestockRightClick` | [L1997](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1997) |
| `Bridge.AppendCraftTooltipLines` | [L2051](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2051) |
| `Bridge.ApplyMiddleClickNoUse` | [L2088](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2088) |
| `Bridge.SuppressCheckedVisual` | [L2131](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2131) |
| `Bridge.SuppressCheckedVisualSettle` | [L2171](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2171) |
| `Bridge.GetConsumableCombatSwap` | [L2211](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2211) |
| `Bridge.SetConsumableCombatSwap` | [L2223](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2223) |
| `Bridge.CombatSwapTooltipKind` | [L2238](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2238) |
| `Bridge.SyncSwapEmptyFace` | [L2355](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2355) |
| `Bridge.ApplyCombatSwap` | [L2452](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2452) |
| `Bridge.RefreshConsumableCombatSwap` | [L2518](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2518) |
| `Bridge.QueueConsumableFaceRefresh` | [L2615](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2615) |
| `Refresh.Attach` | [L2708](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2708) |
| `Module.Update` | [L3050](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3050) |
| `Module.RefreshCountOnly` | [L3257](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3257) |
| `Module.Update` | [L3529](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3529) |

### ExtraButtonSystem/Engine/Paint.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Paint.InvalidateSpellCaches` | [L42](../../ExtraButtonSystem/Engine/Paint.lua#L42) |
| `Paint.ClearCache` | [L56](../../ExtraButtonSystem/Engine/Paint.lua#L56) |
| `Paint.IsParked` | [L81](../../ExtraButtonSystem/Engine/Paint.lua#L81) |
| `Paint.RequestShown` | [L102](../../ExtraButtonSystem/Engine/Paint.lua#L102) |
| `Paint.HasPendingIcon` | [L114](../../ExtraButtonSystem/Engine/Paint.lua#L114) |
| `Paint.UpdateEmpty` | [L230](../../ExtraButtonSystem/Engine/Paint.lua#L230) |
| `Paint.EnsureAutocast` | [L342](../../ExtraButtonSystem/Engine/Paint.lua#L342) |
| `Paint.UpdateAutocast` | [L373](../../ExtraButtonSystem/Engine/Paint.lua#L373) |
| `Paint.UpdateIcon` | [L690](../../ExtraButtonSystem/Engine/Paint.lua#L690) |
| `Paint.UpdateCount` | [L1163](../../ExtraButtonSystem/Engine/Paint.lua#L1163) |
| `Paint.UpdateCooldown` | [L1856](../../ExtraButtonSystem/Engine/Paint.lua#L1856) |
| `Paint.UpdateAllCooldowns` | [L2006](../../ExtraButtonSystem/Engine/Paint.lua#L2006) |
| `Paint.UpdateUsable` | [L2336](../../ExtraButtonSystem/Engine/Paint.lua#L2336) |
| `Paint.NotePlayerCast` | [L2556](../../ExtraButtonSystem/Engine/Paint.lua#L2556) |
| `Paint.UpdateFlash` | [L2950](../../ExtraButtonSystem/Engine/Paint.lua#L2950) |
| `Paint.FlushFlash` | [L2988](../../ExtraButtonSystem/Engine/Paint.lua#L2988) |
| `Paint.UpdateChecked` | [L3003](../../ExtraButtonSystem/Engine/Paint.lua#L3003) |
| `Paint.FlushIcons` | [L3143](../../ExtraButtonSystem/Engine/Paint.lua#L3143) |
| `Paint.RequestIcon` | [L3167](../../ExtraButtonSystem/Engine/Paint.lua#L3167) |
| `Paint.FlushChecked` | [L3201](../../ExtraButtonSystem/Engine/Paint.lua#L3201) |
| `Paint.ArmCheckedPoll` | [L3275](../../ExtraButtonSystem/Engine/Paint.lua#L3275) |
| `Paint.RequestChecked` | [L3283](../../ExtraButtonSystem/Engine/Paint.lua#L3283) |
| `Paint.RequestCheckedSettle` | [L3299](../../ExtraButtonSystem/Engine/Paint.lua#L3299) |
| `Paint.UpdateGlow` | [L3312](../../ExtraButtonSystem/Engine/Paint.lua#L3312) |
| `Paint.UpdateEquipped` | [L3436](../../ExtraButtonSystem/Engine/Paint.lua#L3436) |
| `Paint.UpdateRange` | [L3549](../../ExtraButtonSystem/Engine/Paint.lua#L3549) |
| `Paint.Update` | [L3568](../../ExtraButtonSystem/Engine/Paint.lua#L3568) |
| `Paint.UpdateLiveFace` | [L3588](../../ExtraButtonSystem/Engine/Paint.lua#L3588) |
| `Paint.FlushEval` | [L3599](../../ExtraButtonSystem/Engine/Paint.lua#L3599) |
| `Paint.FlushCounts` | [L3705](../../ExtraButtonSystem/Engine/Paint.lua#L3705) |
| `FluxButton:UpdateEmptyBackground` | [L3757](../../ExtraButtonSystem/Engine/Paint.lua#L3757) |
| `FluxButton:UpdateUsable` | [L3761](../../ExtraButtonSystem/Engine/Paint.lua#L3761) |
| `FluxButton:UpdateCooldown` | [L3765](../../ExtraButtonSystem/Engine/Paint.lua#L3765) |
| `FluxButton:UpdateEquipped` | [L3769](../../ExtraButtonSystem/Engine/Paint.lua#L3769) |

### ExtraButtonSystem/Engine/Range.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Range.IsArmed` | [L79](../../ExtraButtonSystem/Engine/Range.lua#L79) |
| `Range.RefreshButton` | [L84](../../ExtraButtonSystem/Engine/Range.lua#L84) |
| `Range.RefreshFlags` | [L98](../../ExtraButtonSystem/Engine/Range.lua#L98) |
| `Range.RefreshItemFlags` | [L113](../../ExtraButtonSystem/Engine/Range.lua#L113) |
| `Range.Sync` | [L117](../../ExtraButtonSystem/Engine/Range.lua#L117) |
| `Range.SyncDemand` | [L133](../../ExtraButtonSystem/Engine/Range.lua#L133) |
| `Range.Start` | [L137](../../ExtraButtonSystem/Engine/Range.lua#L137) |

### ExtraButtonSystem/Engine/Style.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Style.UseQuickslotRing` | [L24](../../ExtraButtonSystem/Engine/Style.lua#L24) |
| `Style.StampFace` | [L108](../../ExtraButtonSystem/Engine/Style.lua#L108) |
| `Style.RefreshSqueezeChrome` | [L121](../../ExtraButtonSystem/Engine/Style.lua#L121) |
| `Style.SizeRing` | [L415](../../ExtraButtonSystem/Engine/Style.lua#L415) |
| `Style.Apply` | [L520](../../ExtraButtonSystem/Engine/Style.lua#L520) |
| `Style.ApplySlotRing` | [L549](../../ExtraButtonSystem/Engine/Style.lua#L549) |

### ExtraButtonSystem/Engine/Watch.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Watch.SyncAssistantTicker` | [L173](../../ExtraButtonSystem/Engine/Watch.lua#L173) |
| `Watch.Start` | [L192](../../ExtraButtonSystem/Engine/Watch.lua#L192) |

### ExtraButtonSystem/Engine/Widget.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Widget.SyncCVars` | [L12](../../ExtraButtonSystem/Engine/Widget.lua#L12) |
| `Widget.ResolveKind` | [L39](../../ExtraButtonSystem/Engine/Widget.lua#L39) |
| `widget.SetCheckedifnotnativeSetCheckedthenreturnendwidget.SetChecked` | [L121](../../ExtraButtonSystem/Engine/Widget.lua#L121) |
| `Widget.AfterClickPaint` | [L376](../../ExtraButtonSystem/Engine/Widget.lua#L376) |
| `Widget.BindLockedExtraHost` | [L418](../../ExtraButtonSystem/Engine/Widget.lua#L418) |
| `Widget.Attach` | [L467](../../ExtraButtonSystem/Engine/Widget.lua#L467) |
| `Widget.Create` | [L569](../../ExtraButtonSystem/Engine/Widget.lua#L569) |
| `widget:UpdateFlyout` | [L645](../../ExtraButtonSystem/Engine/Widget.lua#L645) |
| `widget:UpdateCooldown` | [L685](../../ExtraButtonSystem/Engine/Widget.lua#L685) |

### ExtraButtonSystem/ExtraButtons/Buttons.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `B:Initialize` | [L114](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L114) |
| `B:SetupCursorMonitoring` | [L120](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L120) |
| `B:UpdateAllDeleteButtonVisibility` | [L137](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L137) |
| `B:CreateButton` | [L145](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L145) |
| `B:CreateDeleteButton` | [L188](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L188) |
| `B:GetButtonFromPool` | [L289](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L289) |
| `B:ReturnButtonToPool` | [L308](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L308) |
| `B:CalculateGridLayout` | [L339](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L339) |
| `B:RenderButtonsForCategory` | [L347](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L347) |
| `btn.OnReceiveDragCallback` | [L410](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L410) |
| `endbtn.OnDelete` | [L423](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L423) |
| `B:ButtonHasContent` | [L459](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L459) |
| `B:SetupDeleteButtonVisibility` | [L466](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L466) |
| `B:UpdateDeleteButtonVisibility` | [L507](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L507) |
| `B:AddButtonToCategory` | [L541](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L541) |

### ExtraButtonSystem/ExtraButtons/Categories.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `C:Initialize` | [L49](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L49) |
| `C:GetScopeColor` | [L55](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L55) |
| `C:ApplyScopeColoring` | [L72](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L72) |
| `C:CreateCategoryWindow` | [L128](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L128) |
| `C:GetCategoryWindowFromPool` | [L522](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L522) |
| `C:ReturnCategoryWindowToPool` | [L537](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L537) |
| `C:CreateCategory` | [L563](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L563) |
| `C:DeleteCategory` | [L597](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L597) |
| `C:MoveCategory` | [L625](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L625) |
| `C:RenderCategories` | [L653](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L653) |
| `C:RefreshCategories` | [L882](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L882) |
| `C:ShowScopeDropdown` | [L889](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L889) |
| `C:CreateScopeDropdown` | [L975](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L975) |
| `C:ChangeCategoryScope` | [L1061](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L1061) |
| `C:ToggleAll` | [L1112](../../ExtraButtonSystem/ExtraButtons/Categories.lua#L1112) |

### ExtraButtonSystem/ExtraButtons/Core.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `E:GenerateUniqueID` | [L51](../../ExtraButtonSystem/ExtraButtons/Core.lua#L51) |
| `E:LoadSavedVars` | [L56](../../ExtraButtonSystem/ExtraButtons/Core.lua#L56) |
| `E:PopulateDisplayOrder` | [L112](../../ExtraButtonSystem/ExtraButtons/Core.lua#L112) |
| `E:MigrateCategories` | [L144](../../ExtraButtonSystem/ExtraButtons/Core.lua#L144) |
| `E:GetEntriesTableForScope` | [L179](../../ExtraButtonSystem/ExtraButtons/Core.lua#L179) |
| `E:FindCategoryByID` | [L203](../../ExtraButtonSystem/ExtraButtons/Core.lua#L203) |
| `E:GetAllCategoriesInOrder` | [L232](../../ExtraButtonSystem/ExtraButtons/Core.lua#L232) |
| `E:ScopeUsesClassColor` | [L284](../../ExtraButtonSystem/ExtraButtons/Core.lua#L284) |
| `E:GetScopeColor` | [L289](../../ExtraButtonSystem/ExtraButtons/Core.lua#L289) |
| `E:GetScopeBorderColor` | [L298](../../ExtraButtonSystem/ExtraButtons/Core.lua#L298) |
| `E:GetDefaultButtonSize` | [L310](../../ExtraButtonSystem/ExtraButtons/Core.lua#L310) |
| `E:GetCategoryBlockRange` | [L320](../../ExtraButtonSystem/ExtraButtons/Core.lua#L320) |
| `E:GetButtonsForCategory` | [L347](../../ExtraButtonSystem/ExtraButtons/Core.lua#L347) |
| `E:AddButtonToEntriesTable` | [L370](../../ExtraButtonSystem/ExtraButtons/Core.lua#L370) |
| `E:RemoveButtonFromEntriesTable` | [L393](../../ExtraButtonSystem/ExtraButtons/Core.lua#L393) |
| `E:Initialize` | [L417](../../ExtraButtonSystem/ExtraButtons/Core.lua#L417) |

### ExtraButtonSystem/ExtraButtons/UI.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `E.ApplyCategoryUIScale` | [L15](../../ExtraButtonSystem/ExtraButtons/UI.lua#L15) |
| `UI:Initialize` | [L23](../../ExtraButtonSystem/ExtraButtons/UI.lua#L23) |
| `UI:CreateMainFrame` | [L30](../../ExtraButtonSystem/ExtraButtons/UI.lua#L30) |
| `self.scrollFrame.GetVerticalScrollRangeiforiginalGetVerticalScrollRangethenself.scrollFrame.GetVerticalScrollRange` | [L72](../../ExtraButtonSystem/ExtraButtons/UI.lua#L72) |
| `self.scrollFrame.GetVerticalScrolliforiginalGetVerticalScrollthenself.scrollFrame.GetVerticalScroll` | [L85](../../ExtraButtonSystem/ExtraButtons/UI.lua#L85) |
| `self.scrollFrame.SetVerticalScrollself.scrollFrame.SetVerticalScroll` | [L97](../../ExtraButtonSystem/ExtraButtons/UI.lua#L97) |
| `scrollBar.SetValuescrollBar.SetValue` | [L164](../../ExtraButtonSystem/ExtraButtons/UI.lua#L164) |
| `scrollBar.SetEnablediforiginalSetEnabledthenscrollBar.SetEnabled` | [L180](../../ExtraButtonSystem/ExtraButtons/UI.lua#L180) |
| `scrollBar.ScrollUpButton.SetEnabledscrollBar.ScrollUpButton.SetEnabled` | [L191](../../ExtraButtonSystem/ExtraButtons/UI.lua#L191) |
| `scrollBar.ScrollDownButton.SetEnabledscrollBar.ScrollDownButton.SetEnabled` | [L200](../../ExtraButtonSystem/ExtraButtons/UI.lua#L200) |
| `UI:CreateControlButtons` | [L256](../../ExtraButtonSystem/ExtraButtons/UI.lua#L256) |
| `UI:CreateAddCategoryButton` | [L286](../../ExtraButtonSystem/ExtraButtons/UI.lua#L286) |
| `UI:UpdateAddCategoryButtonPosition` | [L302](../../ExtraButtonSystem/ExtraButtons/UI.lua#L302) |
| `UI:UpdateToggleButtonIcon` | [L317](../../ExtraButtonSystem/ExtraButtons/UI.lua#L317) |
| `UI:ShowNewCategoryDialog` | [L338](../../ExtraButtonSystem/ExtraButtons/UI.lua#L338) |
| `UI:CreateNewCategoryDialog` | [L404](../../ExtraButtonSystem/ExtraButtons/UI.lua#L404) |
| `UI:AttachTo` | [L533](../../ExtraButtonSystem/ExtraButtons/UI.lua#L533) |
| `UI:UpdatePosition` | [L684](../../ExtraButtonSystem/ExtraButtons/UI.lua#L684) |
| `UI:SetupInTab` | [L704](../../ExtraButtonSystem/ExtraButtons/UI.lua#L704) |
| `UI:Show` | [L709](../../ExtraButtonSystem/ExtraButtons/UI.lua#L709) |
| `UI:Hide` | [L724](../../ExtraButtonSystem/ExtraButtons/UI.lua#L724) |

### ExtraButtonSystem/FlyoutEngine/Arrow.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Arrow.ConfigureLayer` | [L32](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L32) |
| `Arrow.Rotation` | [L61](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L61) |
| `Arrow.Anchor` | [L75](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L75) |
| `Arrow.SetTint` | [L106](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L106) |
| `Arrow.ApplyAccent` | [L145](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L145) |
| `Arrow.Ensure` | [L157](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L157) |
| `Arrow.Update` | [L201](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L201) |
| `Arrow.SetOpen` | [L215](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L215) |
| `Arrow.Show` | [L221](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L221) |
| `Arrow.Hide` | [L243](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L243) |
| `Arrow.RefreshAll` | [L258](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L258) |

### ExtraButtonSystem/FlyoutEngine/Attach.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Flyout.BindHost` | [L27](../../ExtraButtonSystem/FlyoutEngine/Attach.lua#L27) |
| `Flyout.SetButtons` | [L80](../../ExtraButtonSystem/FlyoutEngine/Attach.lua#L80) |
| `Flyout.Clear` | [L123](../../ExtraButtonSystem/FlyoutEngine/Attach.lua#L123) |
| `Flyout.PlacePopup` | [L150](../../ExtraButtonSystem/FlyoutEngine/Attach.lua#L150) |
| `Flyout.Toggle` | [L156](../../ExtraButtonSystem/FlyoutEngine/Attach.lua#L156) |
| `Flyout.Close` | [L190](../../ExtraButtonSystem/FlyoutEngine/Attach.lua#L190) |
| `Flyout.CloseAll` | [L198](../../ExtraButtonSystem/FlyoutEngine/Attach.lua#L198) |
| `Flyout.ApplyAppearanceAccent` | [L207](../../ExtraButtonSystem/FlyoutEngine/Attach.lua#L207) |
| `Flyout.RefreshArrowLayers` | [L220](../../ExtraButtonSystem/FlyoutEngine/Attach.lua#L220) |

### ExtraButtonSystem/FlyoutEngine/Chrome.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Chrome.Attach` | [L73](../../ExtraButtonSystem/FlyoutEngine/Chrome.lua#L73) |
| `Chrome.ApplyAccent` | [L120](../../ExtraButtonSystem/FlyoutEngine/Chrome.lua#L120) |
| `Chrome.Layout` | [L141](../../ExtraButtonSystem/FlyoutEngine/Chrome.lua#L141) |

### ExtraButtonSystem/FlyoutEngine/Def.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Def.NormalizeList` | [L71](../../ExtraButtonSystem/FlyoutEngine/Def.lua#L71) |
| `Def.ItemAttr` | [L91](../../ExtraButtonSystem/FlyoutEngine/Def.lua#L91) |

### ExtraButtonSystem/FlyoutEngine/Favorites.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Favorites.RegisterCategory` | [L260](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L260) |
| `Favorites.RegisterListener` | [L267](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L267) |
| `Favorites.RegisterButton` | [L273](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L273) |
| `Favorites.UnregisterButton` | [L283](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L283) |
| `Favorites.GetButtonCategory` | [L292](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L292) |
| `Favorites.GetFavorite` | [L297](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L297) |
| `Favorites.SetFavorite` | [L321](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L321) |
| `Favorites.ClearFavorite` | [L346](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L346) |
| `Favorites.ToggleFavorite` | [L404](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L404) |
| `Favorites.GetBestAvailableFavorite` | [L417](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L417) |
| `Favorites.GetFavoritesTable` | [L436](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L436) |
| `Favorites.PaintKidStar` | [L465](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L465) |
| `Favorites.UpdateAllVisibleStars` | [L482](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L482) |
| `Favorites.PromoteAvailable` | [L497](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L497) |
| `Favorites.IsFavoritedAnyMod` | [L533](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L533) |
| `Favorites.RefreshFlyoutTooltip` | [L565](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L565) |
| `Favorites.AppendTooltip` | [L588](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L588) |
| `Favorites.OnKidRightClick` | [L650](../../ExtraButtonSystem/FlyoutEngine/Favorites.lua#L650) |

### ExtraButtonSystem/FlyoutEngine/HostCompat.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Compat.ShowFlyout` | [L59](../../ExtraButtonSystem/FlyoutEngine/HostCompat.lua#L59) |
| `.onClick` | [L87](../../ExtraButtonSystem/FlyoutEngine/HostCompat.lua#L87) |
| `Compat.CloseFlyoutFor` | [L104](../../ExtraButtonSystem/FlyoutEngine/HostCompat.lua#L104) |
| `Compat.CloseFlyout` | [L111](../../ExtraButtonSystem/FlyoutEngine/HostCompat.lua#L111) |
| `Compat.IsFlyoutOpenFor` | [L117](../../ExtraButtonSystem/FlyoutEngine/HostCompat.lua#L117) |
| `Compat.GetFlyoutForButton` | [L122](../../ExtraButtonSystem/FlyoutEngine/HostCompat.lua#L122) |
| `Compat.GetActiveFlyout` | [L127](../../ExtraButtonSystem/FlyoutEngine/HostCompat.lua#L127) |
| `Compat.ShowArrow` | [L139](../../ExtraButtonSystem/FlyoutEngine/HostCompat.lua#L139) |
| `Compat.HideArrow` | [L153](../../ExtraButtonSystem/FlyoutEngine/HostCompat.lua#L153) |
| `Compat.ShowArrowFor` | [L160](../../ExtraButtonSystem/FlyoutEngine/HostCompat.lua#L160) |
| `Compat.OnDependentsLayoutChanged` | [L164](../../ExtraButtonSystem/FlyoutEngine/HostCompat.lua#L164) |

### ExtraButtonSystem/FlyoutEngine/Init.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Flyout.InLockdown` | [L34](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L34) |
| `Flyout.Defer` | [L41](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L41) |
| `Flyout.Dummy` | [L55](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L55) |
| `Flyout.EnsureDummy` | [L59](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L59) |
| `Flyout.MouseIndex` | [L82](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L82) |
| `Flyout.DirOk` | [L98](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L98) |
| `Flyout.DirPoints` | [L106](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L106) |
| `Flyout.HostOf` | [L120](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L120) |
| `Flyout.GetPopup` | [L127](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L127) |
| `Flyout.GetArrow` | [L132](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L132) |
| `Flyout.IsOpen` | [L140](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L140) |
| `Flyout.OnDependentsLayoutChanged` | [L145](../../ExtraButtonSystem/FlyoutEngine/Init.lua#L145) |

### ExtraButtonSystem/FlyoutEngine/Popup.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Popup.Ensure` | [L966](../../ExtraButtonSystem/FlyoutEngine/Popup.lua#L966) |
| `Popup.Place` | [L981](../../ExtraButtonSystem/FlyoutEngine/Popup.lua#L981) |
| `Popup.Layout` | [L1015](../../ExtraButtonSystem/FlyoutEngine/Popup.lua#L1015) |

### ExtraButtonSystem/FlyoutEngine/Secure.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Secure.HandlerOnLoad` | [L84](../../ExtraButtonSystem/FlyoutEngine/Secure.lua#L84) |
| `Secure.InstallOpener` | [L90](../../ExtraButtonSystem/FlyoutEngine/Secure.lua#L90) |
| `Secure.InstallKidClose` | [L138](../../ExtraButtonSystem/FlyoutEngine/Secure.lua#L138) |

### ExtraButtonSystem/Init.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `EBS.RegisterButton` | [L23](../../ExtraButtonSystem/Init.lua#L23) |
| `EBS.UnregisterButton` | [L42](../../ExtraButtonSystem/Init.lua#L42) |
| `EBS.RegisterBadge` | [L60](../../ExtraButtonSystem/Init.lua#L60) |
| `EBS.UnregisterBadge` | [L79](../../ExtraButtonSystem/Init.lua#L79) |
| `EBS.ActiveCount` | [L97](../../ExtraButtonSystem/Init.lua#L97) |
| `EBS.OccupiedCount` | [L101](../../ExtraButtonSystem/Init.lua#L101) |
| `FluxBtn.Create` | [L112](../../ExtraButtonSystem/Init.lua#L112) |
| `FluxBtn.Attach` | [L119](../../ExtraButtonSystem/Init.lua#L119) |
| `FluxButton.New` | [L128](../../ExtraButtonSystem/Init.lua#L128) |
| `FluxBtn.ApplyStyle` | [L132](../../ExtraButtonSystem/Init.lua#L132) |
| `FluxBtn.Register` | [L138](../../ExtraButtonSystem/Init.lua#L138) |
| `FluxBtn.Unregister` | [L142](../../ExtraButtonSystem/Init.lua#L142) |
| `FluxBtn.SafeGetItemCount` | [L146](../../ExtraButtonSystem/Init.lua#L146) |
| `FluxBtn.Compat.After` | [L178](../../ExtraButtonSystem/Init.lua#L178) |
| `EBS.Start` | [L214](../../ExtraButtonSystem/Init.lua#L214) |

### ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Timer.After` | [L316](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L316) |
| `Module.GetData` | [L426](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L426) |
| `Module.GetActivePreset` | [L431](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L431) |
| `Module.IsChronoboonFeatureEnabled` | [L544](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L544) |
| `Module.GetDefaultChronoboonItemID` | [L548](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L548) |
| `Module.GetDefaultSuperChronoboonItemID` | [L555](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L555) |
| `Module.EnsureChronoboonPresetEntry` | [L598](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L598) |
| `Module.GetConfigItems` | [L722](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L722) |
| `Module.SetConfigItems` | [L733](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L733) |
| `Module.GetItems` | [L751](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L751) |
| `Module.GetRefreshThreshold` | [L796](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L796) |
| `Module.SetRefreshThreshold` | [L802](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L802) |
| `Module.SetItems` | [L809](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L809) |
| `Module.AddItem` | [L819](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L819) |
| `Module.RemoveItem` | [L844](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L844) |
| `Module.RemoveItemAtIndex` | [L863](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L863) |
| `Module.MoveItem` | [L878](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L878) |
| `Module.AddItemAtIndex` | [L891](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L891) |
| `Module.SetActivePreset` | [L915](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L915) |
| `Module.CreatePreset` | [L926](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L926) |
| `Module.DeletePreset` | [L942](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L942) |
| `Module.GetPresetNames` | [L962](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L962) |
| `Module.GetCanonicalChronoboonID` | [L1065](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1065) |
| `Module.GetChronoboonRestockTarget` | [L1070](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1070) |
| `Module.SetChronoboonRestockTarget` | [L1118](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1118) |
| `Module.GetPresetRestockTarget` | [L1158](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1158) |
| `Module.SetPresetRestockTarget` | [L1181](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1181) |
| `Module.GetRestockUIItemIDs` | [L1233](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1233) |
| `Module.IsRestockUIItem` | [L1261](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1261) |
| `Module.GetItemChargeCount` | [L1275](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1275) |
| `Module.GetItemCount` | [L1453](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1453) |
| `Module.IsChronoboonName` | [L1702](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1702) |
| `Module.ClassifyChronoboon` | [L1707](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1707) |
| `Module.NoteChronoboonVariant` | [L1739](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1739) |
| `Module.GetRegularChronoboonVariantIDs` | [L1958](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1958) |
| `Module.CollectChronoboonIDs` | [L1978](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1978) |
| `Module.GetChronoboonBagCount` | [L2014](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2014) |
| `Module.GetChronoboonBankCount` | [L2021](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2021) |
| `Module.FindChronoboonBankSlotStacks` | [L2033](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2033) |
| `Module.ResolveMerchantRegularChronoboon` | [L2070](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2070) |
| `Module.ReadChronoboonRestockTargetCombined` | [L2096](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2096) |
| `Module.IsChronoboonItem` | [L2127](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2127) |
| `Module.IsSuperchargedChronoboonItem` | [L2140](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2140) |
| `Module.HasSuperchargedChronoboonBuff` | [L2152](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2152) |
| `Module.HasSuperchargedChronoboonInBags` | [L2215](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2215) |
| `Module.HasWorldBuff` | [L2239](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2239) |
| `Module.GetWorldBuffCount` | [L2245](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2245) |
| `Module.FindChronoboonItemIDs` | [L2306](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2306) |
| `Module.GetGroundAuraBinding` | [L2337](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2337) |
| `Module.SetGroundAuraBinding` | [L2351](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2351) |
| `Module.ClearGroundAuraBinding` | [L2365](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2365) |
| `Module.IsGroundAuraLearnerArmed` | [L2380](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2380) |
| `Module.IsGroundPlaceableItem` | [L2403](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2403) |
| `Module.FindBuffBySpellID` | [L2435](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2435) |
| `Module.TryProcessGroundAuraLearner` | [L2601](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2601) |
| `Module.OnGroundPlaceableCastSucceeded` | [L2656](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2656) |
| `Module.ItemGrantsWellFed` | [L2691](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2691) |
| `Module.FindWellFedBuff` | [L2732](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2732) |
| `Module.FindBuffForItem` | [L2814](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2814) |
| `Module.IsWeaponEnchantItem` | [L3140](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3140) |
| `Module.CanEnchantApplyToSlot` | [L3179](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3179) |
| `Module.GetWeaponEnchantSlot` | [L3243](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3243) |
| `Module.FindPreferredBagSlot` | [L3476](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3476) |
| `Module.GetWeaponEnchantSlotWithLowestCharges` | [L3521](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3521) |
| `Module.GetBagSlotWithLowestStack` | [L3525](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3525) |
| `Module.IsItemEligible` | [L3594](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3594) |
| `Module.GetFirstEligibleItem` | [L3681](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3681) |
| `Module.GetEligibleRegularChronoboonItemID` | [L3722](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3722) |
| `Module.GetChronoboonModifierOverrideChronoID` | [L3736](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3736) |
| `Module.RefreshConsumablesUsability` | [L3751](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3751) |
| `Module.RebindPreferredUseSlot` | [L3925](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3925) |
| `Module.ApplyConsumablesChronoboonModifierVisual` | [L4027](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4027) |
| `Module.ApplyChronoboonModifierLayer` | [L4076](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4076) |
| `Module.ClearChronoboonModifierLayer` | [L4111](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4111) |
| `Module.CheckWispLockState` | [L4131](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4131) |
| `Module.UseNextConsumable` | [L4208](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4208) |
| `Module.UpdateWispLockCooldown` | [L4417](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4417) |
| `Module.SetupRightClickConfig` | [L4496](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4496) |
| `falsebtn.UpdateTextCount` | [L4635](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4635) |
| `Module.RefreshAuraTimerOverlay` | [L4810](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4810) |
| `Module.UpdateBuffCooldown` | [L4824](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4824) |
| `Module.ApplyPendingChanges` | [L4833](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4833) |
| `Module.UpdateButtonState` | [L4856](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4856) |
| `Module.Register` | [L5166](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5166) |
| `Module.CreateButton` | [L5194](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5194) |
| `truebtn.UpdateUsable` | [L5219](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5219) |
| `btn.SetActionbtn.SetAction` | [L5241](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5241) |
| `btn.ClearActionbtn.ClearAction` | [L5253](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5253) |
| `btn.UpdateTexturebtn.UpdateTexture` | [L5264](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5264) |
| `btn.FullRefreshbtn.FullRefresh` | [L5316](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5316) |
| `btn.UpdateAppearancebtn.UpdateAppearance` | [L5372](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5372) |
| `btn.UpdateTextCountbtn.UpdateTextCount` | [L5424](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5424) |
| `btn.UpdateCooldownbtn.UpdateCooldown` | [L5440](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5440) |
| `Module.SetupClickHandling` | [L5479](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5479) |
| `Module.SetupTooltip` | [L5659](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5659) |
| `Module.ShowTooltip` | [L5720](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5720) |
| `Module.RefreshTooltip` | [L5922](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5922) |
| `Module.UpdateWeaponEnchantButton` | [L5934](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5934) |
| `Module.RunPostLoginConsumablesRefresh` | [L5968](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5968) |
| `Module.SeedConsumableAuraWatchSig` | [L6037](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6037) |
| `Module.RegisterEvents` | [L6043](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6043) |
| `Module._BuffWatchNeeded` | [L6107](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6107) |
| `Module._StopBuffCheckTicker` | [L6125](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6125) |
| `Module._StartBuffCheckTicker` | [L6132](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6132) |
| `Module._SyncBuffCheckTicker` | [L6139](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6139) |
| `Module.ForceUpdate` | [L6504](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6504) |
| `Module.GetButton` | [L6510](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6510) |
| `Module.UpdateKeybindings` | [L6524](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6524) |
| `Module.ClearKeybindings` | [L6553](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6553) |
| `FluxNCConsumables_OpenConfig` | [L6563](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6563) |

### ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Config.ShowDragGhost` | [L72](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L72) |
| `Config.HideDragGhost` | [L96](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L96) |
| `Timer.After` | [L107](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L107) |
| `host.onStructureChanged` | [L162](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L162) |
| `endhost.onDataChanged` | [L171](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L171) |
| `Config.ShowChronoboonRestockEdit` | [L454](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L454) |
| `Config.ShowIconTooltip` | [L525](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L525) |
| `Config.RefreshUI` | [L687](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L687) |
| `Config.UpdateIconCooldown` | [L716](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L716) |
| `Config.UpdateAllCooldowns` | [L722](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L722) |
| `Config.UpdateThresholdDisplay` | [L729](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L729) |
| `Config.ApplyThresholdChange` | [L750](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L750) |
| `Config.UpdateAllItemCounts` | [L778](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L778) |
| `Config.HandleItemDrop` | [L789](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L789) |
| `Config.AddItem` | [L799](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L799) |
| `Config.PromptNewPreset` | [L839](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L839) |
| `Config.ConfirmDeletePreset` | [L899](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L899) |
| `Config.Show` | [L944](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L944) |
| `Config.ShowChronoboonRestockFlyout` | [L995](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L995) |
| `Config.Hide` | [L1039](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1039) |
| `Config.Toggle` | [L1065](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1065) |
| `Config.IsShown` | [L1077](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1077) |
| `Config.StartUpdateTicker` | [L1086](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1086) |
| `Config.StopUpdateTicker` | [L1116](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1116) |

### ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Module.GetRecuperateSpellId` | [L108](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L108) |
| `Module.HasRecuperate` | [L144](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L144) |
| `Module.GetPreferRecuperate` | [L149](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L149) |
| `Module.SetPreferRecuperate` | [L158](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L158) |
| `Module.ToggleRecuperate` | [L175](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L175) |
| `Module.Create` | [L454](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L454) |
| `Module.Update` | [L484](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L484) |
| `Module.UpdateKeybinding` | [L515](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L515) |

### ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Timer.After` | [L197](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L197) |
| `Module.GetHearthItemId` | [L326](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L326) |
| `Module.IsCharacterSpecific` | [L468](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L468) |
| `Module.GetTeleportItems` | [L481](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L481) |
| `Module.HasTeleportItems` | [L594](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L594) |
| `Module.GetTeleportItemCount` | [L606](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L606) |
| `Module.InvalidateTeleportCache` | [L612](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L612) |
| `Module.LockToItem` | [L705](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L705) |
| `Module.OnTeleportItemPickedFromFlyout` | [L731](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L731) |
| `Module.Unlock` | [L746](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L746) |
| `Module.IsLocked` | [L775](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L775) |
| `Module.GetLockedItem` | [L780](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L780) |
| `Module.UpdateLockedState` | [L785](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L785) |
| `Module.IsItemEquipped` | [L867](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L867) |
| `Module.HandleEquipmentClick` | [L887](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L887) |
| `Module.OnEquipmentChanged` | [L915](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L915) |
| `Module.BuildTeleportFlyoutActions` | [L942](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L942) |
| `Module.HasTeleportItemFlyout` | [L968](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L968) |
| `Module.ShowTeleportFlyout` | [L974](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L974) |
| `Module.RefreshFlyoutIfOpen` | [L1009](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1009) |
| `Module.RegisterForFavorites` | [L1045](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1045) |
| `Module.BuildModifierActions` | [L1082](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1082) |
| `Module.BuildTeleportMacro` | [L1119](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1119) |
| `Module.GetBestTeleportItem` | [L1248](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1248) |
| `Module.SyncTeleportItemOverlays` | [L1364](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1364) |
| `Module.UpdateHotkeyText` | [L1405](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1405) |
| `Module.UpdateHearthKeybinding` | [L1413](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1413) |
| `Module.ClearHearthKeybinding` | [L1433](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1433) |
| `Module.Register` | [L1447](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1447) |
| `btn.UpdateUsable` | [L1526](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1526) |
| `Module.RefreshButtonMode` | [L1590](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1590) |
| `Module.CreateButton` | [L1635](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1635) |
| `Module.SetupMiddleClickToyBox` | [L1738](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1738) |
| `Module.SetupRightClickClassic` | [L1757](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1757) |
| `Module.UpdateClassicHearthstone` | [L1777](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1777) |
| `Module.SetupRightClick` | [L1838](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1838) |
| `Module.SetupPreClick` | [L1858](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1858) |
| `Module.Update` | [L1918](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1918) |
| `Module.UpdateTeleportLayout` | [L1983](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L1983) |
| `Module.SetupTooltip` | [L2499](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2499) |
| `Module.RefreshTooltip` | [L2571](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2571) |
| `Module.UpdateTeleportIcon` | [L2578](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2578) |
| `Module.SetupIconProtection` | [L2653](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2653) |
| `btn.WIcon.SetTexturebtn.WIcon.SetTexture` | [L2662](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L2662) |
| `Module.OnFlyoutButtonClick` | [L3094](../../ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua#L3094) |

### ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Timer.After` | [L109](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L109) |
| `Module.InvalidateCollectedMountCache` | [L415](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L415) |
| `Module.HasAnyMount` | [L423](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L423) |
| `Module.HasAnyMountInBags` | [L546](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L546) |
| `Module.InvalidateRidingSkillCache` | [L633](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L633) |
| `Module.HasRidingSkill` | [L638](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L638) |
| `Module.HasAnyVendorMount` | [L830](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L830) |
| `Module.GetBestVendorMount` | [L848](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L848) |
| `Module.GetMountConfig` | [L878](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L878) |
| `Module.GetGroundMount` | [L966](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L966) |
| `Module.GetFlyingMount` | [L975](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L975) |
| `Module.GetMode` | [L988](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L988) |
| `Module.SetMode` | [L1016](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1016) |
| `Module.ToggleMode` | [L1056](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1056) |
| `Module.LockToMount` | [L1152](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1152) |
| `Module.Unlock` | [L1174](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1174) |
| `Module.IsLocked` | [L1209](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1209) |
| `Module.GetLockedMount` | [L1214](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1214) |
| `Module.UpdateLockedState` | [L1219](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1219) |
| `Module.GetMountForCurrentModifiers` | [L1296](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1296) |
| `Module.CastSmartMount` | [L1412](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1412) |
| `Module.BuildSmartMountMacro` | [L1434](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1434) |
| `Module.HasBrutosaur` | [L1503](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1503) |
| `Module.HasYak` | [L1507](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1507) |
| `Module.GetBrutosaur` | [L1512](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1512) |
| `Module.GetYak` | [L1516](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1516) |
| `Module.BuildVendorMountMacro` | [L1522](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1522) |
| `Module.GetCurrentMacro` | [L1548](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1548) |
| `Module.CanDisplayMountButton` | [L1624](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1624) |
| `Module.Register` | [L1758](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1758) |
| `Module.CreateButton` | [L1873](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1873) |
| `falsebtn.UpdateUsable` | [L1914](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1914) |
| `Module.UpdateHotkeyText` | [L2033](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2033) |
| `Module.UpdateMountKeybinding` | [L2041](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2041) |
| `Module.ClearMountKeybinding` | [L2068](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2068) |
| `Module.SetupRightClick` | [L2077](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2077) |
| `Module.SetupMiddleClick` | [L2103](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2103) |
| `Module.SetupPreClick` | [L2128](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2128) |
| `Module.SetupTooltip` | [L2707](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2707) |
| `Module.RefreshTooltip` | [L2746](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2746) |
| `Module.GetCurrentScope` | [L2757](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2757) |
| `Module.UpdateButtonScope` | [L2773](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2773) |
| `Module.GetOppositeMountModeIconForBindingGhost` | [L2860](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2860) |
| `Module.UpdateTexture` | [L2869](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2869) |
| `Module.Update` | [L2940](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2940) |
| `Module.GetMountItemId` | [L3869](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3869) |
| `Module.GetBagMountItems` | [L3877](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3877) |
| `Module.BuildMountItemFlyoutActions` | [L3884](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3884) |
| `Module.OnMountPickedFromFlyout` | [L3891](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3891) |
| `Module.ShowMountItemFlyout` | [L3897](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3897) |
| `Module.RefreshFlyoutIfOpen` | [L3903](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3903) |
| `Module.RegisterForFavorites` | [L3909](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3909) |
| `Module.GetBagMountItemsSet` | [L3922](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3922) |
| `Module.GetBestAvailableMount` | [L3929](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3929) |
| `Module.GetAvailableFavorites` | [L3936](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3936) |
| `Module.GetFavoriteMount` | [L3943](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3943) |
| `Module.BuildModifierActions` | [L3969](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3969) |
| `Module.BuildBagMountMacro` | [L4027](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4027) |
| `btn.WIcon.SetTexturebtn.WIcon.SetTexture` | [L4160](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4160) |
| `Module.UpdateJournalMountIcon` | [L4218](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4218) |
| `Module.UpdateBagMountIcon` | [L4239](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4239) |
| `Module.SetupBagMountButton` | [L4359](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4359) |

### ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Coll.HasMountJournalAPI` | [L40](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L40) |
| `Coll.HasCompanionAPI` | [L47](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L47) |
| `Coll.HasMountUI` | [L52](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L52) |
| `Coll.InvalidateCollectedMountMap` | [L64](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L64) |
| `Coll.GetCollectedMountByName` | [L119](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L119) |
| `Coll.HasAnyVendorMount` | [L141](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L141) |
| `Coll.HasBrutosaur` | [L150](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L150) |
| `Coll.HasYak` | [L154](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L154) |
| `Coll.GetBestVendorMount` | [L158](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L158) |
| `Coll.GetBrutosaur` | [L168](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L168) |
| `Coll.GetYak` | [L172](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L172) |

### ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Items.InvalidateCache` | [L452](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L452) |
| `Items.InvalidateCacheForSettle` | [L473](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L473) |
| `Items.InvalidateFavoriteMap` | [L495](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L495) |
| `Items.RebuildFavoriteMap` | [L500](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L500) |
| `Items.GetBagMountItems` | [L521](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L521) |
| `Items.GetBagMountItemsSet` | [L594](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L594) |
| `Items.GetBestAvailableMount` | [L609](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L609) |
| `Items.GetAvailableFavorites` | [L625](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L625) |
| `Items.GetBindingFavoriteMounts` | [L649](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L649) |
| `Items.IsMountFlying` | [L675](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L675) |
| `Items.IsFlyableHere` | [L679](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L679) |
| `Items.IsTemporarilyDisabledMount` | [L683](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L683) |
| `Items.GetFavoriteMount` | [L687](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L687) |
| `Items.GetMountItemId` | [L701](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L701) |
| `Items.BuildMountItemFlyoutActions` | [L713](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L713) |
| `Items.HasMountItemFlyout` | [L724](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L724) |
| `Items.OnMountPickedFromFlyout` | [L729](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L729) |
| `Items.ShowMountItemFlyout` | [L746](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L746) |
| `Items.RefreshFlyoutIfOpen` | [L771](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L771) |
| `Items.HasAnyMountInBags` | [L806](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L806) |

### ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Timer.After` | [L154](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L154) |
| `Module.GetVendorOptionReagentSummary` | [L456](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L456) |
| `Module.GetKnownTeleportSpells` | [L599](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L599) |
| `Module.GetKnownPortalSpells` | [L640](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L640) |
| `Module.HasAnyTeleportSpell` | [L679](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L679) |
| `Module.HasAnyPortalSpell` | [L685](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L685) |
| `Module.HasAnyTeleportOrPortalSpell` | [L691](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L691) |
| `Module.InvalidateCache` | [L705](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L705) |
| `Module.GetFirstKnownSpell` | [L714](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L714) |
| `Module.GetMode` | [L733](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L733) |
| `Module.SetMode` | [L758](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L758) |
| `Module.ToggleMode` | [L785](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L785) |
| `Module.ClearCheckedVisual` | [L837](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L837) |
| `Module.ClearCheckedVisualNow` | [L873](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L873) |
| `Module.RefreshFlyoutIfOpen` | [L906](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L906) |
| `Module.LockToSpell` | [L944](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L944) |
| `Module.Unlock` | [L984](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L984) |
| `Module.IsLocked` | [L1033](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1033) |
| `Module.UpdateLockedState` | [L1038](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1038) |
| `Module.BuildReagentActions` | [L1138](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1138) |
| `Module.GetRestockTarget` | [L1205](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1205) |
| `Module.SetRestockTarget` | [L1221](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1221) |
| `Module.UpdateReagentButtonDisplay` | [L1239](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1239) |
| `Module.UpdateReagentButtonCountText` | [L1261](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1261) |
| `Module.ShowReagentButtonCount` | [L1280](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1280) |
| `Module.BuildFlyoutActions` | [L1294](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1294) |
| `Module.CountVisibleTeleportDestinations` | [L1343](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1343) |
| `Module.HasTeleportFlyout` | [L1356](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1356) |
| `Module.SyncFlyoutEngine` | [L1406](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1406) |
| `Module.ShowFlyout` | [L1436](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1436) |
| `Module.HookFlyoutButtons` | [L1476](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1476) |
| `Module.BuildConditionalCastLine` | [L1524](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1524) |
| `Module.BuildFlyoutMacro` | [L1577](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1577) |
| `Module.Register` | [L1616](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1616) |
| `Module.EnsureButtonForBindingMode` | [L1642](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1642) |
| `Module.CreateButton` | [L1655](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1655) |
| `btn.UpdateUsable` | [L1766](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1766) |
| `endendbtn.UpdateTextCount` | [L1793](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1793) |
| `Module.ApplyMacro` | [L1837](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1837) |
| `Module.SetupIconProtection` | [L1875](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1875) |
| `btn.WIcon.SetTexturebtn.WIcon.SetTexture` | [L1884](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1884) |
| `icon.SetTextureicon.SetTexture` | [L1904](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1904) |
| `Module.SetupClickHandlers` | [L1925](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1925) |
| `Module.SetupMiddleClick` | [L1982](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1982) |
| `Module.SetupRightClick` | [L1986](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1986) |
| `Module.SetupPreClick` | [L1991](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1991) |
| `Module.SetupTooltip` | [L2106](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2106) |
| `Module.ShowTooltip` | [L2164](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2164) |
| `Module.RefreshTooltip` | [L2300](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2300) |
| `Module.GetSpellForModifier` | [L2313](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2313) |
| `Module.GetOppositeModeDisplaySpell` | [L2401](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2401) |
| `Module.UpdateIcon` | [L2537](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2537) |
| `Module.UpdateTexture` | [L2595](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2595) |
| `Module.UpdateFlyoutArrow` | [L2654](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2654) |
| `Module.Update` | [L2674](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2674) |
| `Module.UpdateTeleportKeybinding` | [L2814](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2814) |
| `Module.ClearTeleportKeybinding` | [L2847](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2847) |
| `Module.UpdateHotkeyText` | [L2857](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2857) |
| `Module.IsTeleportOrPortalSpell` | [L3118](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L3118) |
| `Module.RefreshReagentCounts` | [L3157](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L3157) |
| `Module.RefreshAllReagentDisplays` | [L3172](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L3172) |

### ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Module.Create` | [L139](../../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua#L139) |
| `Module.UpdateKeybinding` | [L166](../../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua#L166) |

### ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `frame:UpdateDisplay` | [L680](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L680) |
| `UnregisterListenerFluxHearthConfig.IsHearthstoneToy` | [L772](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L772) |
| `SlashCmdList.FLUXHEARTH` | [L822](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L822) |

### ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Timer.After` | [L86](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L86) |
| `Config.RegisterListener` | [L383](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L383) |
| `Config.UnregisterListener` | [L388](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L388) |
| `Config.IsUsingCharacterSpecific` | [L401](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L401) |
| `Config.GetMountMode` | [L408](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L408) |
| `Config.SetMountMode` | [L415](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L415) |
| `Config.GetCurrentMountConfig` | [L423](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L423) |
| `Config.ToggleCharacterSpecific` | [L437](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L437) |
| `Config.SaveMountConfig` | [L470](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L470) |
| `Config.GetGroundMount` | [L495](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L495) |
| `Config.GetFlyingMount` | [L500](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L500) |
| `Config.GetGroundMultiMount` | [L505](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L505) |
| `Config.GetFlyingMultiMount` | [L511](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L511) |
| `Config.GetMultiMount` | [L517](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L517) |
| `Config.GetUtilityMount` | [L526](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L526) |
| `Config.GetSmartMount` | [L530](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L530) |
| `Config.GetVendorMount` | [L543](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L543) |
| `Config.GetVendorMountTexture` | [L573](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L573) |
| `Config.HasAnyVendorMount` | [L585](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L585) |
| `Config.GetMountIconTexture` | [L593](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L593) |
| `Config.OpenMountJournal` | [L665](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L665) |
| `Config.CreateMountConfigUI` | [L689](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L689) |
| `configFrame:UpdateDisplay` | [L900](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L900) |
| `Config.DebugPrint` | [L1055](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L1055) |

### ExtraButtonSystem/NonCombatGrid/Grid.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Grid.New` | [L23](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L23) |
| `grid:CreateButton` | [L74](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L74) |
| `btn:SetPlaceholder` | [L138](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L138) |
| `btn:ClearPlaceholder` | [L161](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L161) |
| `btn:SetLocked` | [L176](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L176) |
| `btn:SetCount` | [L188](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L188) |
| `btn:ShowTooltip` | [L235](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L235) |
| `btn:OnEnter` | [L242](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L242) |
| `btn:OnLeave` | [L251](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L251) |
| `btn:FullRefresh` | [L259](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L259) |
| `btn:Show` | [L273](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L273) |
| `btn:Hide` | [L277](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L277) |
| `returnnilendendgrid.SetButtonColumnPriority` | [L296](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L296) |
| `endendgrid.SetButtonOrder` | [L303](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L303) |
| `grid:ComputeDynamicPriorities` | [L365](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L365) |
| `grid:ConsolidateColumns` | [L480](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L480) |
| `grid:BeginLayout` | [L607](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L607) |
| `grid:EndLayout` | [L611](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L611) |
| `grid:ScheduleRelayout` | [L619](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L619) |
| `grid:Relayout` | [L645](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L645) |
| `grid:Relayout` | [L814](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L814) |
| `grid:RefreshAllModules` | [L823](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L823) |
| `grid:Show` | [L841](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L841) |
| `grid:Hide` | [L842](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L842) |
| `FluxNonCombatGrid_ApplyAppearanceAccent` | [L848](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L848) |
| `Grid.RefreshAfterVisibilityChange` | [L871](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L871) |

### ExtraButtonSystem/NonCombatGrid/GridInit.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `API.UpdateAnchor` | [L54](../../ExtraButtonSystem/NonCombatGrid/GridInit.lua#L54) |
| `API_G.FluxNonCombatGrid_ApplyScreenBottomAnchor` | [L172](../../ExtraButtonSystem/NonCombatGrid/GridInit.lua#L172) |

### ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Assign.GetOutfitInfo` | [L12](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L12) |
| `Assign.PickupOutfit` | [L17](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L17) |
| `Assign.GetOutfitIDForSpell` | [L22](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L22) |
| `Assign.IsOutfitActive` | [L30](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L30) |
| `Assign.GetMaxSlots` | [L52](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L52) |
| `Assign.GetSlots` | [L56](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L56) |
| `Assign.NormalizeModKey` | [L61](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L61) |
| `Assign.GetCurrentModKey` | [L78](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L78) |
| `Assign.ParseCursor` | [L206](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L206) |
| `Assign.HasAssignableCursor` | [L337](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L337) |
| `Assign.Assign` | [L351](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L351) |
| `Assign.AssignFromCursor` | [L373](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L373) |
| `Assign.ClearSlot` | [L385](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L385) |
| `Assign.ClearModifier` | [L395](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L395) |
| `Assign.SlotHasAssignment` | [L409](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L409) |
| `Assign.GetMirrorPrefOrder` | [L434](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L434) |
| `Assign.ResolveNomodEntry` | [L439](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L439) |
| `Assign.GetPreferredEntry` | [L458](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L458) |
| `Assign.MigrateLegacySpellBookSnapshot` | [L510](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L510) |
| `Assign.CaptureSnapshot` | [L546](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L546) |
| `Assign.MatchesSnapshot` | [L553](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L553) |
| `Assign.ApplySnapshot` | [L598](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L598) |
| `Assign.GetBaseSpellID` | [L657](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L657) |
| `Assign.FormatAssignmentTierLabel` | [L682](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L682) |
| `Assign.GetSpellAssignment` | [L704](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L704) |
| `Assign.GetStripImplicitMapKeyForSpell` | [L732](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L732) |
| `Assign.GetAllStripImplicitBindings` | [L816](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L816) |
| `Assign.InvalidateStripImplicitCache` | [L825](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L825) |
| `_G.FluxNCUtilitySlots_GetBaseSpellID` | [L843](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L843) |
| `_G.FluxNCUtilitySlots_GetSpellAssignment` | [L846](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L846) |
| `_G.FluxNCUtilitySlots_FormatAssignmentTierLabel` | [L849](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L849) |
| `_G.FluxNCUtilitySlots_GetAllStripImplicitBindings` | [L852](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L852) |
| `_G.FluxNCUtilitySlots_GetStripImplicitMapKeyForSpell` | [L855](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L855) |
| `_G.FluxNCUtilitySlots_CaptureSnapshot` | [L866](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L866) |
| `_G.FluxNCUtilitySlots_MatchesSnapshot` | [L870](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L870) |
| `_G.FluxNCUtilitySlots_ApplySnapshot` | [L874](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L874) |

### ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Manager.GetGrid` | [L31](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L31) |
| `Manager.OnNonCombatGridReady` | [L43](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L43) |
| `Manager.BuildMacroText` | [L159](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L159) |
| `Manager.UpdateHotkeys` | [L720](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L720) |
| `Manager.UpdateButton` | [L750](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L750) |
| `btn.UpdateChecked` | [L914](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L914) |
| `Manager.EnsureButtons` | [L920](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L920) |
| `Manager.ShouldShowEmptySlots` | [L1007](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1007) |
| `Manager.UpdateVisibility` | [L1018](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1018) |
| `Manager._DoUpdateAllSlots` | [L1051](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1051) |
| `Manager.UpdateAllSlots` | [L1105](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1105) |
| `Manager.UpdateBindings` | [L1120](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1120) |
| `ManagerA.OnSlotsChanged` | [L1393](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1393) |

### ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `GridUI.IsRightClick` | [L98](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L98) |
| `GridUI.GetCursorItemID` | [L102](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L102) |
| `GridUI.IsChargeItem` | [L160](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L160) |
| `GridUI.GetChargeAwareCount` | [L164](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L164) |
| `GridUI.GetChargeAwareBankCount` | [L182](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L182) |
| `GridUI.FormatCellMainLine` | [L217](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L217) |
| `GridUI.FormatCellBankLine` | [L230](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L230) |
| `GridUI.FormatCellCountLines` | [L238](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L238) |
| `GridUI.FormatCellCountText` | [L243](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L243) |
| `GridUI.FormatTierCellCountLines` | [L251](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L251) |
| `GridUI.FormatTierCellCountText` | [L255](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L255) |
| `GridUI.ConfigureCellCountString` | [L290](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L290) |
| `GridUI.ConfigureCellBankCountString` | [L300](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L300) |
| `GridUI.SetCellCountLabelsVisible` | [L333](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L333) |
| `GridUI.FitCellCountDisplay` | [L354](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L354) |
| `GridUI.ApplyCellCountDisplay` | [L406](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L406) |
| `GridUI.LayoutFlowGrid` | [L410](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L410) |
| `GridUI.LayoutGrid` | [L442](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L442) |
| `GridUI.RelayoutSection` | [L446](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L446) |
| `GridUI.ClearSectionCells` | [L484](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L484) |
| `GridUI.BindDropBoxHandlers` | [L494](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L494) |
| `GridUI.CreateSection` | [L549](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L549) |
| `GridUI.SetBoxItems` | [L574](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L574) |
| `GridUI.LayoutSectionAt` | [L592](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L592) |
| `GridUI.AttachCooldownOverlay` | [L670](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L670) |
| `GridUI.UpdateCellCooldown` | [L689](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L689) |
| `GridUI.SetupCellChrome` | [L817](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L817) |
| `GridUI.RefreshConsumableCell` | [L922](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L922) |
| `GridUI.CreateConsumableCell` | [L961](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L961) |
| `GridUI.RebuildConfigHost` | [L1278](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L1278) |
| `GridUI.RefreshAllCells` | [L1354](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L1354) |
| `GridUI.UpdateAllCooldowns` | [L1370](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L1370) |

### ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `EBV.ClientHasAssistedCombat` | [L101](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L101) |
| `EBV.GetOrderedIds` | [L109](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L109) |
| `EBV.GetOptionsIds` | [L129](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L129) |
| `EBV.GetBindingForce` | [L141](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L141) |
| `EBV.PlayerUsesMana` | [L146](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L146) |
| `EBV.ClientHasAmmoSlot` | [L167](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L167) |
| `EBV.GetRawMode` | [L193](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L193) |
| `EBV.SetRawMode` | [L209](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L209) |
| `EBV.GetEffectiveMode` | [L219](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L219) |
| `EBV.QuickGate` | [L236](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L236) |
| `EBV.Apply` | [L270](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L270) |
| `EBV.ApplyConsumables` | [L278](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L278) |
| `EBV.ModeDisplayName` | [L292](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L292) |
| `EBV.GetOptionsModeHelpLine` | [L387](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L387) |
| `EBV.GetOptionsTooltipNote` | [L396](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L396) |
| `EBV.Cycle` | [L403](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L403) |
| `EBV._RegisterOptionPanelWidget` | [L423](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L423) |
| `EBV._UnregisterOptionPanelWidget` | [L429](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L429) |
| `EBV._ClearOptionPanelWidgets` | [L435](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L435) |
| `EBV.RefreshOptionPanelRows` | [L442](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L442) |
| `EBV.ResetToDefaults` | [L460](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L460) |
| `EBV.RequestLayoutNow` | [L568](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L568) |
| `EBV.SetSlotShown` | [L635](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L635) |
| `EBV.NotifyChanged` | [L649](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L649) |

### ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `NFO.EnsureDB` | [L89](../../ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua#L89) |
| `NFO.GetDB` | [L118](../../ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua#L118) |
| `NFO.ResetFlyoutLayoutToDefault` | [L124](../../ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua#L124) |
| `NFO.ApplyClassTeleportSpells` | [L244](../../ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua#L244) |
| `NFO.ApplyTeleportItemActions` | [L256](../../ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua#L256) |
| `NFO.ApplyMountItemActions` | [L267](../../ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua#L267) |
| `NFO.NotifyChanged` | [L299](../../ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua#L299) |

### ExtraButtonSystem/Shared/FluxTooltipGuard.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Guard.Block` | [L37](../../ExtraButtonSystem/Shared/FluxTooltipGuard.lua#L37) |
| `Guard.Unblock` | [L52](../../ExtraButtonSystem/Shared/FluxTooltipGuard.lua#L52) |
| `Guard.BlockUntilHide` | [L64](../../ExtraButtonSystem/Shared/FluxTooltipGuard.lua#L64) |
| `Guard.GetIsolatedTooltip` | [L77](../../ExtraButtonSystem/Shared/FluxTooltipGuard.lua#L77) |
| `Guard.GetIsolatedTooltipIfExists` | [L86](../../ExtraButtonSystem/Shared/FluxTooltipGuard.lua#L86) |
| `Guard.GetTipForButton` | [L91](../../ExtraButtonSystem/Shared/FluxTooltipGuard.lua#L91) |
| `Guard.HideForButton` | [L98](../../ExtraButtonSystem/Shared/FluxTooltipGuard.lua#L98) |
| `Guard.IsOwnedByWidget` | [L110](../../ExtraButtonSystem/Shared/FluxTooltipGuard.lua#L110) |
| `Guard.FillBlizzardItem` | [L164](../../ExtraButtonSystem/Shared/FluxTooltipGuard.lua#L164) |
| `Guard.FillBlizzardSpell` | [L207](../../ExtraButtonSystem/Shared/FluxTooltipGuard.lua#L207) |

### ExtraButtonSystem/Shared/HotkeyUtil.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `HotkeyUtil.GetFormattedKeyFromKey` | [L142](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L142) |
| `HotkeyUtil.GetBindingKeyText` | [L212](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L212) |
| `HotkeyUtil.UpdateHotkeyText` | [L227](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L227) |
| `HotkeyUtil.UpdateHotkeyTextMultiple` | [L268](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L268) |
| `HotkeyUtil.AddTooltipBinding` | [L289](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L289) |
| `HotkeyUtil.AddTooltipBindings` | [L299](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L299) |
| `HotkeyUtil.RefreshAfterBindingChange` | [L332](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L332) |
| `HotkeyUtil.FlushAfterBulkBindings` | [L366](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L366) |

### ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `TM.GetTrinketInfo` | [L118](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L118) |
| `TM.FindTrinketInBags` | [L172](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L172) |
| `TM.IsPlayerReallyDead` | [L224](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L224) |
| `TM.HideTrinketTooltip` | [L235](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L235) |
| `TM.SlotWidget` | [L251](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L251) |
| `TM.GetVisibleSlotWidget` | [L256](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L256) |
| `TM.RefreshArrowLayersOnBorder` | [L308](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L308) |
| `TM.ApplyHorizontalSqueeze` | [L327](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L327) |
| `TM.CreateGrid` | [L456](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L456) |
| `TM.WidgetForTrinketBind` | [L644](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L644) |
| `TM.SyncKeybindPushWatch` | [L787](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L787) |
| `TM.HookTrinketClickScripts` | [L893](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L893) |
| `TM.SyncEquippedFace` | [L927](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L927) |
| `TM.CreateTrinketButton` | [L948](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L948) |
| `btn.UpdateUsable` | [L1036](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1036) |
| `endbtn.UpdateEquipped` | [L1040](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1040) |
| `btn.Widget.UpdateTooltip` | [L1049](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1049) |
| `button.UpdateUsable` | [L1140](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1140) |
| `endbutton.UpdateEquipped` | [L1143](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1143) |
| `TM.CreateFlyoutArrow` | [L1202](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1202) |
| `TM.UpdateArrowRotation` | [L1222](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1222) |
| `TM.UpdateArrowVisibility` | [L1236](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1236) |
| `TM.SetupButtonScripts` | [L1308](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1308) |
| `TM.OnTrinketClick` | [L1336](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1336) |
| `TM.ShowTrinketTooltip` | [L1358](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1358) |
| `TM.RestoreTrinketIconColor` | [L1391](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1391) |
| `TM.RestoreTrinketBorderColor` | [L1403](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1403) |
| `TM.HideEquippedGreenBorder` | [L1422](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1422) |
| `TM.EnsureUsabilityTextureRefs` | [L1443](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1443) |
| `TM.ApplyTrinketUsability` | [L1465](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1465) |
| `TM.ApplyMenuTrinketUsability` | [L1524](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1524) |
| `TM.UpdateTrinketButton` | [L1533](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1533) |
| `TM.UpdateTrinketCooldown` | [L1569](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1569) |
| `TM.UpdateAllTrinkets` | [L1594](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1594) |
| `TM.UpdateAllCooldowns` | [L1601](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1601) |
| `TM.UpdateAllUsability` | [L1609](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1609) |
| `TM.CreateMenuFrame` | [L1620](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1620) |
| `TM.ScanBagsForTrinkets` | [L1653](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1653) |
| `TM.SyncFlyoutEngine` | [L1770](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1770) |
| `TM.BuildMenu` | [L1838](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1838) |
| `TM.UpdateMenuButtonCooldown` | [L1863](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1863) |
| `TM.OnMenuTrinketClick` | [L1874](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1874) |
| `TM.ShowMenuTrinketTooltip` | [L1907](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1907) |
| `TM.StartMenuMouseoverTimer` | [L1940](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1940) |
| `TM.QueueTrinketSwap` | [L1988](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1988) |
| `TM.ProcessCombatQueue` | [L2008](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2008) |
| `TM.EquipTrinket` | [L2024](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2024) |
| `TM.UpdateQueueVisuals` | [L2068](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2068) |
| `TM.UpdateKeybindings` | [L2077](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2077) |
| `TM.Show` | [L2193](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2193) |
| `TM.Hide` | [L2209](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2209) |
| `TM.Toggle` | [L2235](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2235) |
| `TM.HasEquippedTrinkets` | [L2252](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2252) |
| `TM.GetEquippedTrinketSlots` | [L2257](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2257) |
| `TM.GetTrinketVisibilityState` | [L2269](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2269) |
| `TM.UpdateTrinketVisibility` | [L2286](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2286) |
| `FluxTrinketMenu_ApplyAppearanceAccent` | [L2471](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2471) |

### ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Manager:UpdateAnchor` | [L73](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L73) |
| `Manager:GetFrame` | [L376](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L376) |
| `Manager:GetButtons` | [L380](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L380) |
| `Manager:Refresh` | [L384](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L384) |
| `Manager.UpdateKeybindings` | [L393](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L393) |

### FluxBorder.lua

Owner: [04-visual-system.md](../04-visual-system.md).

| Declaration | Source |
|---|---|
| `Border:IsUntintedAtlasAccent` | [L64](../../FluxBorder.lua#L64) |
| `Border:GetForeverClientChromeRGB` | [L69](../../FluxBorder.lua#L69) |
| `Border:GetForeverClientBackdropRGB` | [L77](../../FluxBorder.lua#L77) |
| `Border:GetAccentColor` | [L86](../../FluxBorder.lua#L86) |
| `Border:RefreshAllAccentedFrames` | [L109](../../FluxBorder.lua#L109) |
| `Border:GetAccentMode` | [L125](../../FluxBorder.lua#L125) |
| `Border:GetThemedVertexRGB` | [L131](../../FluxBorder.lua#L131) |
| `Border:GetThemedBackdropFillRGB` | [L140](../../FluxBorder.lua#L140) |
| `Border:RefreshAppearanceDependents` | [L152](../../FluxBorder.lua#L152) |
| `FluxUI_RefreshAppearance` | [L210](../../FluxBorder.lua#L210) |
| `Border:CanUseAtlases` | [L241](../../FluxBorder.lua#L241) |
| `Border:ApplyTo` | [L297](../../FluxBorder.lua#L297) |
| `Border:RemoveFrom` | [L441](../../FluxBorder.lua#L441) |
| `Border:SetBorderColor` | [L460](../../FluxBorder.lua#L460) |
| `Border:SetBackdropColor` | [L478](../../FluxBorder.lua#L478) |
| `Border:SetBackdropAlpha` | [L490](../../FluxBorder.lua#L490) |
| `Border:SetClassColor` | [L506](../../FluxBorder.lua#L506) |
| `Border:HideBackground` | [L528](../../FluxBorder.lua#L528) |
| `Border:ShowBackground` | [L537](../../FluxBorder.lua#L537) |
| `Border:ApplyCircle` | [L554](../../FluxBorder.lua#L554) |
| `Border:RefreshClassColor` | [L569](../../FluxBorder.lua#L569) |

### FluxDefaultSettings.lua

Owner: [05-defaults-and-bindings.md](../05-defaults-and-bindings.md).

| Declaration | Source |
|---|---|
| `FluxDefaultSettings.RefreshConjureSharedBindingName` | [L29](../../FluxDefaultSettings.lua#L29) |
| `FluxDefaultSettings.GetMinUIScale` | [L434](../../FluxDefaultSettings.lua#L434) |
| `FluxDefaultSettings.IsUIScaleAtOrBelowMin` | [L439](../../FluxDefaultSettings.lua#L439) |
| `FluxUILayoutSqueeze.SetLastHorizontalSqueezeFactor` | [L457](../../FluxDefaultSettings.lua#L457) |
| `FluxUILayoutSqueeze.GetHorizontalSqueezeFactor` | [L467](../../FluxDefaultSettings.lua#L467) |
| `FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor` | [L475](../../FluxDefaultSettings.lua#L475) |
| `FluxUILayoutSqueeze.GetDependentsHorizontalSqueezeFactor` | [L482](../../FluxDefaultSettings.lua#L482) |
| `FluxUILayoutSqueeze.GetWidgetHorizontalSqueezeFactor` | [L487](../../FluxDefaultSettings.lua#L487) |
| `FluxUILayoutSqueeze.GetDynamicScaleTargets` | [L521](../../FluxDefaultSettings.lua#L521) |
| `FluxUILayoutSqueeze.GetDynamicScaleTargetsEmulated` | [L588](../../FluxDefaultSettings.lua#L588) |
| `FluxUILayoutSqueeze.GetDependentsHorizontalSqueezeFactorFromBarX` | [L653](../../FluxDefaultSettings.lua#L653) |
| `FluxUILayoutSqueeze.GetUnitFrameIndependentScaleTargets` | [L664](../../FluxDefaultSettings.lua#L664) |
| `FluxUILayoutSqueeze.ClampUnitFrameIndependentXSqueeze` | [L708](../../FluxDefaultSettings.lua#L708) |
| `FluxUILayoutSqueeze.ComputeEmulatedFullMainBarSqueezeFactors` | [L732](../../FluxDefaultSettings.lua#L732) |
| `FluxUILayoutSqueeze.GetEmulatedDependentCacheKey` | [L787](../../FluxDefaultSettings.lua#L787) |
| `FluxUILayoutSqueeze.InvalidateEmulatedDependentCache` | [L794](../../FluxDefaultSettings.lua#L794) |
| `FluxUILayoutSqueeze.GetCachedEmulatedDependentXFactorForUnitFrames` | [L800](../../FluxDefaultSettings.lua#L800) |
| `FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames` | [L816](../../FluxDefaultSettings.lua#L816) |
| `FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactor` | [L825](../../FluxDefaultSettings.lua#L825) |
| `FluxUILayoutSqueeze.ComputeVisibleContentWidth` | [L848](../../FluxDefaultSettings.lua#L848) |
| `FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactorForRow` | [L855](../../FluxDefaultSettings.lua#L855) |
| `FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactorForFrame` | [L879](../../FluxDefaultSettings.lua#L879) |
| `FluxUILayoutSqueeze.NotifyLayoutDependents` | [L895](../../FluxDefaultSettings.lua#L895) |
| `FluxUILayoutSqueeze.EnsureDisplayRefreshHooks` | [L991](../../FluxDefaultSettings.lua#L991) |
| `FluxUILayoutSqueeze.RequestRefresh` | [L1007](../../FluxDefaultSettings.lua#L1007) |
| `FluxDefaultSettings.GetState` | [L1055](../../FluxDefaultSettings.lua#L1055) |
| `FluxDefaultSettings.ApplyNameplateScalarDefaults` | [L1233](../../FluxDefaultSettings.lua#L1233) |
| `FluxDefaultSettings.ApplyNameplateClassColorDefault` | [L1237](../../FluxDefaultSettings.lua#L1237) |
| `FluxDefaultSettings.ApplyNameplateNpcNameDefaults` | [L1241](../../FluxDefaultSettings.lua#L1241) |
| `FluxDefaultSettings.ApplyNameplateBitfieldDefaults` | [L1245](../../FluxDefaultSettings.lua#L1245) |
| `FluxDefaultSettings.ApplyNameplateDefaultsPack` | [L1249](../../FluxDefaultSettings.lua#L1249) |
| `FluxDefaultSettings.ScheduleNameplateDefaultsPack` | [L1253](../../FluxDefaultSettings.lua#L1253) |
| `FluxDefaultSettings.ApplySpecialCVarSettings` | [L1273](../../FluxDefaultSettings.lua#L1273) |
| `FluxDefaultSettings.ApplyRaidFrameSettings` | [L1310](../../FluxDefaultSettings.lua#L1310) |
| `FluxDefaultSettings.EnsureNameplateSizeMedium` | [L1315](../../FluxDefaultSettings.lua#L1315) |
| `FluxDefaultSettings.ScheduleRaidArenaFrameDefaultsPack` | [L1332](../../FluxDefaultSettings.lua#L1332) |
| `FluxDefaultSettings.ApplyRaidArenaFrameDefaultsPackNow` | [L1336](../../FluxDefaultSettings.lua#L1336) |
| `FluxDefaultSettings.ApplyRaidArenaFrameDefaultsPack` | [L1340](../../FluxDefaultSettings.lua#L1340) |
| `FluxDefaultSettings.ApplyInterfaceDefaultsPack` | [L1346](../../FluxDefaultSettings.lua#L1346) |
| `FluxDefaultSettings.ApplyStickyTargetingOff` | [L1354](../../FluxDefaultSettings.lua#L1354) |
| `FluxDefaultSettings.GetMaxCameraDistanceZoomFactor` | [L1385](../../FluxDefaultSettings.lua#L1385) |
| `FluxDefaultSettings.ApplyMaxCameraDistance` | [L1408](../../FluxDefaultSettings.lua#L1408) |
| `FluxDefaultSettings.ApplyControlsDefaultsPack` | [L1439](../../FluxDefaultSettings.lua#L1439) |
| `FluxDefaultSettings.ApplyChatSettings` | [L1519](../../FluxDefaultSettings.lua#L1519) |
| `FluxDefaultSettings.ApplySelfCastAndFocusCastDefaults` | [L1565](../../FluxDefaultSettings.lua#L1565) |
| `FluxDefaultSettings.ApplyCombatDefaultsPack` | [L1570](../../FluxDefaultSettings.lua#L1570) |
| `FluxDefaultSettings.ApplyActionBarDefaultsPack` | [L1705](../../FluxDefaultSettings.lua#L1705) |
| `FluxDefaultSettings.ShouldSuppressBindingRefresh` | [L1797](../../FluxDefaultSettings.lua#L1797) |
| `FluxDefaultSettings.FlushBindingRefreshAfterBulk` | [L1812](../../FluxDefaultSettings.lua#L1812) |
| `FluxDefaultSettings.SavePendingModifiedClicks` | [L1893](../../FluxDefaultSettings.lua#L1893) |
| `FluxDefaultSettings.ApplyKeybinds` | [L1944](../../FluxDefaultSettings.lua#L1944) |
| `FluxDefaultSettings.PrepareAccountBindingBootstrap` | [L2217](../../FluxDefaultSettings.lua#L2217) |
| `FluxDefaultSettings.EnsureDefaultFluxBindings` | [L2282](../../FluxDefaultSettings.lua#L2282) |
| `FluxDefaultSettings.ReassertSoftTargetEnemyFromDefaults` | [L2329](../../FluxDefaultSettings.lua#L2329) |
| `FluxDefaultSettings.ScheduleSoftTargetEnemyReassertFromDefaults` | [L2358](../../FluxDefaultSettings.lua#L2358) |
| `FluxDefaultSettings.SyncSettingsRegistryProxies` | [L2367](../../FluxDefaultSettings.lua#L2367) |
| `FluxDefaultSettings.ApplyCharacterFirstLogin` | [L2403](../../FluxDefaultSettings.lua#L2403) |
| `FluxDefaultSettings.VerifyInitialNonBindingDefaults` | [L2437](../../FluxDefaultSettings.lua#L2437) |
| `FluxDefaultSettings.VerifyPostLoginDefaults` | [L2523](../../FluxDefaultSettings.lua#L2523) |
| `FluxDefaultSettings.Apply` | [L2576](../../FluxDefaultSettings.lua#L2576) |
| `FluxDefaultSettings.ApplyCVarsOnly` | [L2857](../../FluxDefaultSettings.lua#L2857) |
| `FluxDefaultSettings.PrintDebug` | [L3300](../../FluxDefaultSettings.lua#L3300) |

### Inventory/Builtin/Auctions.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Auctions.Refresh` | [L160](../../Inventory/Builtin/Auctions.lua#L160) |
| `Auctions.Start` | [L175](../../Inventory/Builtin/Auctions.lua#L175) |

### Inventory/Builtin/Bags.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Bags.MarkDirty` | [L31](../../Inventory/Builtin/Bags.lua#L31) |
| `Bags.Invalidate` | [L47](../../Inventory/Builtin/Bags.lua#L47) |
| `Bags.Refresh` | [L53](../../Inventory/Builtin/Bags.lua#L53) |
| `Bags.GetLastChangeKind` | [L112](../../Inventory/Builtin/Bags.lua#L112) |
| `Bags.GetLastAddedItemIDs` | [L116](../../Inventory/Builtin/Bags.lua#L116) |
| `Bags.GetLastRemovedItemIDs` | [L120](../../Inventory/Builtin/Bags.lua#L120) |
| `Bags.GetLastRefreshedDirtyBags` | [L125](../../Inventory/Builtin/Bags.lua#L125) |
| `Bags.TakeItemSets` | [L130](../../Inventory/Builtin/Bags.lua#L130) |

### Inventory/Builtin/Bank.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Bank.IsOpen` | [L34](../../Inventory/Builtin/Bank.lua#L34) |
| `Bank.SetOpen` | [L38](../../Inventory/Builtin/Bank.lua#L38) |
| `Bank.MarkDirty` | [L53](../../Inventory/Builtin/Bank.lua#L53) |
| `Bank.Invalidate` | [L75](../../Inventory/Builtin/Bank.lua#L75) |
| `Bank.Refresh` | [L131](../../Inventory/Builtin/Bank.lua#L131) |
| `Bank.GetLastChangeKind` | [L162](../../Inventory/Builtin/Bank.lua#L162) |
| `Bank.GetLastAddedItemIDs` | [L166](../../Inventory/Builtin/Bank.lua#L166) |
| `Bank.GetLastRemovedItemIDs` | [L170](../../Inventory/Builtin/Bank.lua#L170) |
| `Bank.GetLastRefreshedDirtyBags` | [L174](../../Inventory/Builtin/Bank.lua#L174) |
| `Bank.ScanOpenContainers` | [L179](../../Inventory/Builtin/Bank.lua#L179) |

### Inventory/Builtin/Currency.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Currency.Refresh` | [L101](../../Inventory/Builtin/Currency.lua#L101) |
| `Currency.Start` | [L120](../../Inventory/Builtin/Currency.lua#L120) |

### Inventory/Builtin/Equip.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Equip.HasChanged` | [L64](../../Inventory/Builtin/Equip.lua#L64) |
| `Equip.MarkDirty` | [L69](../../Inventory/Builtin/Equip.lua#L69) |
| `Equip.Invalidate` | [L73](../../Inventory/Builtin/Equip.lua#L73) |
| `Equip.Refresh` | [L77](../../Inventory/Builtin/Equip.lua#L77) |

### Inventory/Builtin/FluxClassicCombinedBag.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `EnsureEdgeStrips` | [L107](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L107) |
| `frame:SetPortraitToAsset` | [L186](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L186) |
| `frame:SetTitle` | [L217](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L217) |
| `slotRow:Layout` | [L1294](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L1294) |
| `combined:EnumerateValidItems` | [L1728](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L1728) |
| `end_G.FluxRefreshInBagSlots` | [L1890](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L1890) |
| `ToggleAllBags` | [L2016](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2016) |
| `ToggleBackpack` | [L2028](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2028) |
| `ToggleBag` | [L2040](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2040) |
| `OpenBag` | [L2052](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2052) |
| `OpenBackpack` | [L2062](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2062) |
| `OpenAllBags` | [L2071](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2071) |
| `CloseAllBags` | [L2089](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2089) |
| `bar.Layoutbar.Layout` | [L2132](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2132) |
| `hidden:Layout` | [L2221](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2221) |
| `bar.Layoutbar.Layout` | [L2236](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2236) |

### Inventory/Builtin/Guild.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Guild.Refresh` | [L86](../../Inventory/Builtin/Guild.lua#L86) |
| `Guild.Start` | [L151](../../Inventory/Builtin/Guild.lua#L151) |

### Inventory/Builtin/Mail.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Mail.IsOpen` | [L134](../../Inventory/Builtin/Mail.lua#L134) |
| `Mail.Refresh` | [L222](../../Inventory/Builtin/Mail.lua#L222) |
| `Mail.Start` | [L290](../../Inventory/Builtin/Mail.lua#L290) |

### Inventory/Builtin/Void.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Void.Refresh` | [L35](../../Inventory/Builtin/Void.lua#L35) |
| `Void.Start` | [L84](../../Inventory/Builtin/Void.lua#L84) |

### Inventory/Builtin/Watch.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Builtin.Flush` | [L25](../../Inventory/Builtin/Watch.lua#L25) |
| `Builtin.Start` | [L319](../../Inventory/Builtin/Watch.lua#L319) |

### Inventory/Containers.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `C.Invalidate` | [L94](../../Inventory/Containers.lua#L94) |
| `C.GetSyndicatorBankIndexes` | [L109](../../Inventory/Containers.lua#L109) |
| `C.GetSyndicatorWarbandIndexes` | [L118](../../Inventory/Containers.lua#L118) |
| `C.GetSyndicatorBagIndexes` | [L127](../../Inventory/Containers.lua#L127) |
| `C.IsLegacyBankLayout` | [L136](../../Inventory/Containers.lua#L136) |
| `C.GetBankMainContainerID` | [L148](../../Inventory/Containers.lua#L148) |
| `C.GetOpenBankScanNumSlots` | [L164](../../Inventory/Containers.lua#L164) |
| `C.BuildLegacyBankContainerIDs` | [L203](../../Inventory/Containers.lua#L203) |
| `C.IsBankReadable` | [L223](../../Inventory/Containers.lua#L223) |
| `C.GetCarriedBagIDs` | [L263](../../Inventory/Containers.lua#L263) |
| `C.GetPlayerRestockBagIDs` | [L293](../../Inventory/Containers.lua#L293) |
| `C.GetCharacterBankIDs` | [L331](../../Inventory/Containers.lua#L331) |
| `C.GetWarbandBankIDs` | [L368](../../Inventory/Containers.lua#L368) |
| `C.IsCarriedBag` | [L400](../../Inventory/Containers.lua#L400) |
| `C.IsCharacterBankContainer` | [L409](../../Inventory/Containers.lua#L409) |
| `C.IsWarbandBankContainer` | [L418](../../Inventory/Containers.lua#L418) |
| `C.IsBankContainer` | [L427](../../Inventory/Containers.lua#L427) |
| `C.GetBankTypeForContainer` | [L431](../../Inventory/Containers.lua#L431) |
| `C.GetKeyringBagID` | [L451](../../Inventory/Containers.lua#L451) |
| `C.GetReagentBagID` | [L470](../../Inventory/Containers.lua#L470) |
| `C.IsKeyringBag` | [L483](../../Inventory/Containers.lua#L483) |
| `C.IsReagentBag` | [L505](../../Inventory/Containers.lua#L505) |
| `C.IsReagentBank` | [L514](../../Inventory/Containers.lua#L514) |
| `C.SkipEquipCandidateBag` | [L533](../../Inventory/Containers.lua#L533) |
| `C.ReadSlot` | [L612](../../Inventory/Containers.lua#L612) |
| `C.PatchSlots` | [L618](../../Inventory/Containers.lua#L618) |
| `C.ScanBag` | [L645](../../Inventory/Containers.lua#L645) |
| `C.CountsFromByBag` | [L666](../../Inventory/Containers.lua#L666) |
| `C.DiffSlots` | [L690](../../Inventory/Containers.lua#L690) |
| `C.ChangedFromDelta` | [L713](../../Inventory/Containers.lua#L713) |
| `C.NewItemSetLog` | [L735](../../Inventory/Containers.lua#L735) |
| `C.NoteItemSets` | [L740](../../Inventory/Containers.lua#L740) |
| `C.TakeItemSets` | [L755](../../Inventory/Containers.lua#L755) |

### Inventory/Craft.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Craft.GetCraftableCount` | [L168](../../Inventory/Craft.lua#L168) |
| `Craft.HasProfessionForKind` | [L316](../../Inventory/Craft.lua#L316) |
| `Craft.GetOutputPerCraft` | [L535](../../Inventory/Craft.lua#L535) |
| `Craft.ListRecipesForKind` | [L550](../../Inventory/Craft.lua#L550) |
| `Craft.InvalidateCanCraftCache` | [L638](../../Inventory/Craft.lua#L638) |
| `Craft.BagChangesAffectKind` | [L644](../../Inventory/Craft.lua#L644) |
| `Craft.GetBestCraftable` | [L657](../../Inventory/Craft.lua#L657) |
| `Craft.CanCraftKind` | [L705](../../Inventory/Craft.lua#L705) |
| `Craft.GetBandageProfessionSpellName` | [L748](../../Inventory/Craft.lua#L748) |
| `Craft.ClearPendingCraft` | [L838](../../Inventory/Craft.lua#L838) |
| `Craft.TryFlushPendingCraft` | [L932](../../Inventory/Craft.lua#L932) |
| `Craft.ExecuteCraft` | [L948](../../Inventory/Craft.lua#L948) |
| `Craft.ExecuteHealPotionCraft` | [L997](../../Inventory/Craft.lua#L997) |
| `Craft.ExecuteManaPotionCraft` | [L1001](../../Inventory/Craft.lua#L1001) |
| `Craft.ExecuteBandageCraft` | [L1005](../../Inventory/Craft.lua#L1005) |

### Inventory/CreateSpells.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Spells.Refresh` | [L185](../../Inventory/CreateSpells.lua#L185) |
| `Spells.Invalidate` | [L193](../../Inventory/CreateSpells.lua#L193) |
| `Spells.IsKnown` | [L198](../../Inventory/CreateSpells.lua#L198) |
| `Spells.IsKnownByName` | [L207](../../Inventory/CreateSpells.lua#L207) |
| `Spells.GetCreateItemSpells` | [L245](../../Inventory/CreateSpells.lua#L245) |
| `Spells.GetPreferredCreateSpell` | [L253](../../Inventory/CreateSpells.lua#L253) |
| `Spells.HasCreateKind` | [L290](../../Inventory/CreateSpells.lua#L290) |
| `Spells.GetKindForSpell` | [L296](../../Inventory/CreateSpells.lua#L296) |
| `Spells.GetPreferredGroupConjureSpell` | [L318](../../Inventory/CreateSpells.lua#L318) |
| `Spells.GetPreferredFoodConjureSpell` | [L326](../../Inventory/CreateSpells.lua#L326) |
| `Spells.GetPreferredWaterConjureSpell` | [L338](../../Inventory/CreateSpells.lua#L338) |
| `Spells.GetSecondaryFoodConjureSpell` | [L350](../../Inventory/CreateSpells.lua#L350) |
| `Spells.GetSecondaryWaterConjureSpell` | [L366](../../Inventory/CreateSpells.lua#L366) |
| `Spells.HasConjureFood` | [L382](../../Inventory/CreateSpells.lua#L382) |
| `Spells.HasConjureWater` | [L391](../../Inventory/CreateSpells.lua#L391) |
| `Spells.HasConjureRefreshment` | [L400](../../Inventory/CreateSpells.lua#L400) |
| `Spells.HasRitualOfRefreshment` | [L409](../../Inventory/CreateSpells.lua#L409) |
| `Spells.HasAnyConjureSpell` | [L418](../../Inventory/CreateSpells.lua#L418) |

### Inventory/FluxConsumableBest/FluxConsumableBest.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Best._notifyListeners` | [L107](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L107) |
| `Best.RegisterListener` | [L115](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L115) |
| `Best.UnregisterListener` | [L122](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L122) |
| `Best.RequestRecompute` | [L126](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L126) |
| `Best.GetBest` | [L169](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L169) |
| `Best.GetBestRef` | [L191](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L191) |
| `Best.GetLadder` | [L222](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L222) |
| `Best.GetBestOwned` | [L279](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L279) |
| `Best.GetAllBest` | [L298](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L298) |
| `Best.FindStacks` | [L318](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L318) |
| `Best.Init` | [L434](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L434) |

### Inventory/FluxConsumableBest/Init.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Best.HasEmptyRelevantKind` | [L69](../../Inventory/FluxConsumableBest/Init.lua#L69) |
| `Best.IsLoginScanActive` | [L86](../../Inventory/FluxConsumableBest/Init.lua#L86) |
| `Best.EndLoginScan` | [L98](../../Inventory/FluxConsumableBest/Init.lua#L98) |
| `Best.BeginLoginScan` | [L107](../../Inventory/FluxConsumableBest/Init.lua#L107) |
| `Best.IsSoftHoldKind` | [L154](../../Inventory/FluxConsumableBest/Init.lua#L154) |
| `Best.ShouldSoftHoldOwned` | [L167](../../Inventory/FluxConsumableBest/Init.lua#L167) |
| `Best.BeginLoadHold` | [L205](../../Inventory/FluxConsumableBest/Init.lua#L205) |
| `Best.ArmPortalSoftHold` | [L223](../../Inventory/FluxConsumableBest/Init.lua#L223) |
| `Best.MergePendingAdded` | [L255](../../Inventory/FluxConsumableBest/Init.lua#L255) |
| `Best.IsConjureArmActive` | [L268](../../Inventory/FluxConsumableBest/Init.lua#L268) |
| `Best.ArmConjureChase` | [L274](../../Inventory/FluxConsumableBest/Init.lua#L274) |
| `Best.IsManaKind` | [L309](../../Inventory/FluxConsumableBest/Init.lua#L309) |
| `Best.IsManaKindRelevant` | [L313](../../Inventory/FluxConsumableBest/Init.lua#L313) |
| `Best.IsValidKind` | [L324](../../Inventory/FluxConsumableBest/Init.lua#L324) |

### Inventory/FluxConsumableBest/Persist.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Persist.GetRoot` | [L24](../../Inventory/FluxConsumableBest/Persist.lua#L24) |
| `Persist.GetRef` | [L28](../../Inventory/FluxConsumableBest/Persist.lua#L28) |
| `Persist.GetAllRefs` | [L53](../../Inventory/FluxConsumableBest/Persist.lua#L53) |
| `Persist.MaybeUpdateRef` | [L59](../../Inventory/FluxConsumableBest/Persist.lua#L59) |
| `Persist.GetVendorSeen` | [L111](../../Inventory/FluxConsumableBest/Persist.lua#L111) |
| `Persist.RememberVendorItem` | [L120](../../Inventory/FluxConsumableBest/Persist.lua#L120) |
| `Persist.GetAllVendorSeen` | [L140](../../Inventory/FluxConsumableBest/Persist.lua#L140) |

### Inventory/FluxConsumableBest/Scan.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Scan.Recompute` | [L335](../../Inventory/FluxConsumableBest/Scan.lua#L335) |
| `Scan.OnItemDataLoaded` | [L867](../../Inventory/FluxConsumableBest/Scan.lua#L867) |
| `Best.IsSettled` | [L927](../../Inventory/FluxConsumableBest/Scan.lua#L927) |
| `Best.GetPendingLoadCount` | [L937](../../Inventory/FluxConsumableBest/Scan.lua#L937) |
| `Best.GetClassifyQueueCount` | [L947](../../Inventory/FluxConsumableBest/Scan.lua#L947) |

### Inventory/FluxConsumableBest/Score.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Score.HealthstoneRank` | [L48](../../Inventory/FluxConsumableBest/Score.lua#L48) |
| `Score.GetPools` | [L64](../../Inventory/FluxConsumableBest/Score.lua#L64) |
| `Score.EffectiveFromClassify` | [L84](../../Inventory/FluxConsumableBest/Score.lua#L84) |
| `Score.InvalidateUsableCache` | [L105](../../Inventory/FluxConsumableBest/Score.lua#L105) |
| `Score.IsBelowRequiredLevel` | [L275](../../Inventory/FluxConsumableBest/Score.lua#L275) |
| `Score.IsKnownUnusable` | [L291](../../Inventory/FluxConsumableBest/Score.lua#L291) |
| `Score.IsBlockedForBest` | [L313](../../Inventory/FluxConsumableBest/Score.lua#L313) |
| `Score.IsUsableForVendor` | [L347](../../Inventory/FluxConsumableBest/Score.lua#L347) |
| `Score.IsUsable` | [L373](../../Inventory/FluxConsumableBest/Score.lua#L373) |
| `Score.GetMaxStack` | [L431](../../Inventory/FluxConsumableBest/Score.lua#L431) |
| `Score.FoodTier` | [L474](../../Inventory/FluxConsumableBest/Score.lua#L474) |
| `Score.WaterDrinkTier` | [L496](../../Inventory/FluxConsumableBest/Score.lua#L496) |
| `Score.IsBetter` | [L518](../../Inventory/FluxConsumableBest/Score.lua#L518) |

### Inventory/FluxConsumableBest/VendorMemory.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `VM.OnMerchantIndex` | [L71](../../Inventory/FluxConsumableBest/VendorMemory.lua#L71) |
| `VM.HookMerchantIndex` | [L134](../../Inventory/FluxConsumableBest/VendorMemory.lua#L134) |
| `VM.GetVendorCandidates` | [L164](../../Inventory/FluxConsumableBest/VendorMemory.lua#L164) |

### Inventory/FluxConsumableClassify.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `C.IsManaGemItem` | [L612](../../Inventory/FluxConsumableClassify.lua#L612) |
| `C.IsCombatUtilityPotion` | [L704](../../Inventory/FluxConsumableClassify.lua#L704) |
| `C.IsHealingPotionName` | [L708](../../Inventory/FluxConsumableClassify.lua#L708) |
| `C.IsManaPotionName` | [L712](../../Inventory/FluxConsumableClassify.lua#L712) |
| `C.ParseFoodWaterRestore` | [L740](../../Inventory/FluxConsumableClassify.lua#L740) |
| `C.ResetParseBudget` | [L819](../../Inventory/FluxConsumableClassify.lua#L819) |
| `C.InvalidateCache` | [L828](../../Inventory/FluxConsumableClassify.lua#L828) |
| `C.IsPending` | [L839](../../Inventory/FluxConsumableClassify.lua#L839) |
| `C.ForceReject` | [L847](../../Inventory/FluxConsumableClassify.lua#L847) |
| `C.Classify` | [L1047](../../Inventory/FluxConsumableClassify.lua#L1047) |
| `C.ResolveCombatTierAxes` | [L1265](../../Inventory/FluxConsumableClassify.lua#L1265) |
| `FluxNCItemDetection.ParseFoodWaterRestore` | [L1283](../../Inventory/FluxConsumableClassify.lua#L1283) |
| `endFluxNCItemDetection.ItemGrantsWellFed` | [L1288](../../Inventory/FluxConsumableClassify.lua#L1288) |
| `FluxItemDetection.ResolveCombatTierAxes` | [L1316](../../Inventory/FluxConsumableClassify.lua#L1316) |

### Inventory/FluxEquipSlotCandidates.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Candidates.PlayerCanUseEquipment` | [L330](../../Inventory/FluxEquipSlotCandidates.lua#L330) |
| `Candidates.CanItemGoInInventorySlot` | [L350](../../Inventory/FluxEquipSlotCandidates.lua#L350) |
| `Candidates.SlotHasEquippedItem` | [L401](../../Inventory/FluxEquipSlotCandidates.lua#L401) |
| `Candidates.ShouldOfferEmpty` | [L419](../../Inventory/FluxEquipSlotCandidates.lua#L419) |
| `Candidates.GetEmptySlotTexture` | [L450](../../Inventory/FluxEquipSlotCandidates.lua#L450) |
| `Candidates.UnequipInventorySlot` | [L478](../../Inventory/FluxEquipSlotCandidates.lua#L478) |
| `Candidates.Invalidate` | [L572](../../Inventory/FluxEquipSlotCandidates.lua#L572) |
| `Candidates.GetForInventorySlot` | [L577](../../Inventory/FluxEquipSlotCandidates.lua#L577) |
| `Candidates.HasAlternatives` | [L602](../../Inventory/FluxEquipSlotCandidates.lua#L602) |
| `Candidates.EquipToInventorySlot` | [L610](../../Inventory/FluxEquipSlotCandidates.lua#L610) |

### Inventory/FluxItemClass.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `IC.GetStatic` | [L87](../../Inventory/FluxItemClass.lua#L87) |
| `IC.RequestLoad` | [L165](../../Inventory/FluxItemClass.lua#L165) |
| `IC.GetInfo` | [L178](../../Inventory/FluxItemClass.lua#L178) |
| `IC.IsLoaded` | [L194](../../Inventory/FluxItemClass.lua#L194) |
| `IC.GetName` | [L198](../../Inventory/FluxItemClass.lua#L198) |
| `IC.GetLink` | [L203](../../Inventory/FluxItemClass.lua#L203) |
| `IC.GetQuality` | [L223](../../Inventory/FluxItemClass.lua#L223) |
| `IC.GetSellPrice` | [L228](../../Inventory/FluxItemClass.lua#L228) |
| `IC.GetStackSize` | [L243](../../Inventory/FluxItemClass.lua#L243) |
| `IC.GetIcon` | [L248](../../Inventory/FluxItemClass.lua#L248) |
| `IC.GetClassID` | [L257](../../Inventory/FluxItemClass.lua#L257) |
| `IC.GetSubClassID` | [L262](../../Inventory/FluxItemClass.lua#L262) |
| `IC.GetEquipLoc` | [L267](../../Inventory/FluxItemClass.lua#L267) |
| `IC.IsEquippable` | [L274](../../Inventory/FluxItemClass.lua#L274) |
| `IC.GetTooltipText` | [L353](../../Inventory/FluxItemClass.lua#L353) |
| `IC.GetRestore` | [L381](../../Inventory/FluxItemClass.lua#L381) |
| `IC.InvalidateRestoreCache` | [L450](../../Inventory/FluxItemClass.lua#L450) |
| `IC.ClassifyConsumable` | [L480](../../Inventory/FluxItemClass.lua#L480) |
| `IC.InvalidateClassification` | [L563](../../Inventory/FluxItemClass.lua#L563) |
| `IC.OnItemDataLoaded` | [L576](../../Inventory/FluxItemClass.lua#L576) |

### Inventory/FluxItemMover.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Mover.GetCursorItemCount` | [L72](../../Inventory/FluxItemMover.lua#L72) |
| `Mover.GetCursorItemID` | [L98](../../Inventory/FluxItemMover.lua#L98) |
| `Mover.ClearCursor` | [L109](../../Inventory/FluxItemMover.lua#L109) |
| `Mover.IsAnythingLocked` | [L115](../../Inventory/FluxItemMover.lua#L115) |
| `Mover.OnItemLockChanged` | [L137](../../Inventory/FluxItemMover.lua#L137) |
| `Mover.ResetLockTracking` | [L141](../../Inventory/FluxItemMover.lua#L141) |
| `Mover.ItemsCanMerge` | [L175](../../Inventory/FluxItemMover.lua#L175) |
| `Mover.FindFirstEmptyBagSlot` | [L364](../../Inventory/FluxItemMover.lua#L364) |
| `Mover.FindConsolidatedEmptySlot` | [L382](../../Inventory/FluxItemMover.lua#L382) |
| `Mover.GetBestMergeTarget` | [L439](../../Inventory/FluxItemMover.lua#L439) |
| `Mover.GetMaxMergeRoom` | [L483](../../Inventory/FluxItemMover.lua#L483) |
| `Mover.GetTotalMergeRoom` | [L511](../../Inventory/FluxItemMover.lua#L511) |
| `Mover.GetMaxPlaceableAmount` | [L540](../../Inventory/FluxItemMover.lua#L540) |
| `Mover.HasEmptyBagSlot` | [L568](../../Inventory/FluxItemMover.lua#L568) |
| `Mover.HasDestinationRoom` | [L590](../../Inventory/FluxItemMover.lua#L590) |
| `Mover.CanPlaceAmount` | [L594](../../Inventory/FluxItemMover.lua#L594) |
| `Mover.PlaceCursorInContainers` | [L651](../../Inventory/FluxItemMover.lua#L651) |
| `Mover.PlaceCursorInPlayerBags` | [L720](../../Inventory/FluxItemMover.lua#L720) |
| `Mover.PutItemInPlayerBag` | [L739](../../Inventory/FluxItemMover.lua#L739) |
| `Mover.MoveWholeStack` | [L1284](../../Inventory/FluxItemMover.lua#L1284) |
| `Mover.GetActionInterval` | [L1346](../../Inventory/FluxItemMover.lua#L1346) |
| `Mover.SetTurboMode` | [L1356](../../Inventory/FluxItemMover.lua#L1356) |
| `Mover.IsTurboMode` | [L1360](../../Inventory/FluxItemMover.lua#L1360) |
| `Mover.GetBackoffSteps` | [L1381](../../Inventory/FluxItemMover.lua#L1381) |
| `Mover.IsGateOpen` | [L1385](../../Inventory/FluxItemMover.lua#L1385) |
| `Mover.GetGateWaitRemaining` | [L1389](../../Inventory/FluxItemMover.lua#L1389) |
| `Mover.SetLockContainers` | [L1410](../../Inventory/FluxItemMover.lua#L1410) |
| `returninfoandinfo.lockedorfalseendtryPartialMergeIntoSlot` | [L1442](../../Inventory/FluxItemMover.lua#L1442) |
| `Mover.NotePendingBankUnlocked` | [L1756](../../Inventory/FluxItemMover.lua#L1756) |
| `Mover.NoteSplitRejected` | [L1808](../../Inventory/FluxItemMover.lua#L1808) |
| `Mover.NudgeTailMerge` | [L1985](../../Inventory/FluxItemMover.lua#L1985) |
| `Mover.IsActionActive` | [L1999](../../Inventory/FluxItemMover.lua#L1999) |
| `Mover.HasInFlightAction` | [L2003](../../Inventory/FluxItemMover.lua#L2003) |
| `Mover.CancelAction` | [L2008](../../Inventory/FluxItemMover.lua#L2008) |
| `Mover.ProcessActionTick` | [L2037](../../Inventory/FluxItemMover.lua#L2037) |
| `Mover.FlushAction` | [L2046](../../Inventory/FluxItemMover.lua#L2046) |
| `Mover.SubmitAction` | [L3239](../../Inventory/FluxItemMover.lua#L3239) |
| `Mover.RequestStep` | [L3387](../../Inventory/FluxItemMover.lua#L3387) |
| `Mover.AttachRunner` | [L3399](../../Inventory/FluxItemMover.lua#L3399) |
| `Mover.Run` | [L3425](../../Inventory/FluxItemMover.lua#L3425) |
| `Mover.IsRunning` | [L3455](../../Inventory/FluxItemMover.lua#L3455) |
| `Mover.Stop` | [L3459](../../Inventory/FluxItemMover.lua#L3459) |
| `Mover.ExecuteSlotMove` | [L3474](../../Inventory/FluxItemMover.lua#L3474) |

### Inventory/Index.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Index.GetCount` | [L51](../../Inventory/Index.lua#L51) |
| `Index.GetLiveCount` | [L85](../../Inventory/Index.lua#L85) |
| `Index.Find` | [L166](../../Inventory/Index.lua#L166) |
| `Index.GetFirst` | [L212](../../Inventory/Index.lua#L212) |
| `Index.GetUniqueItems` | [L219](../../Inventory/Index.lua#L219) |
| `Index.UniqueCount` | [L333](../../Inventory/Index.lua#L333) |
| `Index.ForEachLocation` | [L358](../../Inventory/Index.lua#L358) |
| `Index.GetSnapshotGeneration` | [L445](../../Inventory/Index.lua#L445) |
| `Index.GetFirstFreeBagSlot` | [L452](../../Inventory/Index.lua#L452) |
| `Inv.GetCount` | [L475](../../Inventory/Index.lua#L475) |
| `Inv.GetLiveCount` | [L479](../../Inventory/Index.lua#L479) |
| `Inv.Find` | [L483](../../Inventory/Index.lua#L483) |
| `Inv.GetFirst` | [L487](../../Inventory/Index.lua#L487) |
| `Inv.GetUniqueItems` | [L491](../../Inventory/Index.lua#L491) |
| `Inv.ForEachLocation` | [L495](../../Inventory/Index.lua#L495) |
| `Inv.GetSnapshotGeneration` | [L499](../../Inventory/Index.lua#L499) |
| `Inv.GetFirstFreeBagSlot` | [L503](../../Inventory/Index.lua#L503) |
| `Inv.GetBagGeneration` | [L507](../../Inventory/Index.lua#L507) |

### Inventory/Init.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Inv.LoadPersistedBankCounts` | [L61](../../Inventory/Init.lua#L61) |
| `Inv.PersistBankCounts` | [L84](../../Inventory/Init.lua#L84) |
| `Inv.SnapshotCountKeys` | [L119](../../Inventory/Init.lua#L119) |
| `Inv.ClassifyCountKeys` | [L132](../../Inventory/Init.lua#L132) |
| `Inv.MergeChangeKind` | [L169](../../Inventory/Init.lua#L169) |
| `Inv.IsScanPending` | [L205](../../Inventory/Init.lua#L205) |
| `Inv.RequestItemData` | [L254](../../Inventory/Init.lua#L254) |
| `Inv.NoteItemDataArrived` | [L274](../../Inventory/Init.lua#L274) |
| `Inv.IsBagStorm` | [L354](../../Inventory/Init.lua#L354) |
| `Inv.NotifyBagStorm` | [L377](../../Inventory/Init.lua#L377) |
| `Inv.EndBagStorm` | [L391](../../Inventory/Init.lua#L391) |
| `Inv.OnStormSettled` | [L399](../../Inventory/Init.lua#L399) |
| `Inv.RegisterStormSettled` | [L414](../../Inventory/Init.lua#L414) |
| `Inv.UnregisterStormSettled` | [L421](../../Inventory/Init.lua#L421) |
| `Inv.SetMerchantOpen` | [L425](../../Inventory/Init.lua#L425) |
| `Inv.IsMerchantOpen` | [L429](../../Inventory/Init.lua#L429) |
| `Inv.SetMailboxOpen` | [L434](../../Inventory/Init.lua#L434) |
| `Inv.IsMailboxOpen` | [L454](../../Inventory/Init.lua#L454) |
| `Inv.ShouldDeferHeavyWork` | [L468](../../Inventory/Init.lua#L468) |
| `Inv.GetLastAddedItemIDs` | [L673](../../Inventory/Init.lua#L673) |
| `Inv.Notify` | [L716](../../Inventory/Init.lua#L716) |
| `Inv.Register` | [L787](../../Inventory/Init.lua#L787) |
| `Inv.Unregister` | [L805](../../Inventory/Init.lua#L805) |
| `Inv.GetListenerInfo` | [L811](../../Inventory/Init.lua#L811) |
| `Inv.GetSource` | [L828](../../Inventory/Init.lua#L828) |
| `Inv.IsReady` | [L832](../../Inventory/Init.lua#L832) |
| `Inv.SnapshotLooksCollapsed` | [L871](../../Inventory/Init.lua#L871) |
| `Inv.MarkUnreliable` | [L884](../../Inventory/Init.lua#L884) |
| `Inv.BeginLoginHold` | [L918](../../Inventory/Init.lua#L918) |
| `Inv.IsLoginHold` | [L938](../../Inventory/Init.lua#L938) |
| `Inv.NoteLoginBagsDelayed` | [L950](../../Inventory/Init.lua#L950) |
| `Inv.IsReliable` | [L1005](../../Inventory/Init.lua#L1005) |
| `Inv.NoteRefreshSettling` | [L1017](../../Inventory/Init.lua#L1017) |
| `Inv.HasWarband` | [L1081](../../Inventory/Init.lua#L1081) |
| `Inv.IsBaganatorBankViewShown` | [L1161](../../Inventory/Init.lua#L1161) |
| `Inv.IsBaganatorBankLiveShown` | [L1188](../../Inventory/Init.lua#L1188) |
| `Inv.RegisterBankStateListener` | [L1207](../../Inventory/Init.lua#L1207) |
| `Inv.ShouldKeepBankOpen` | [L1243](../../Inventory/Init.lua#L1243) |
| `Inv.SetBankOpenLatch` | [L1247](../../Inventory/Init.lua#L1247) |
| `Inv.SetBaganatorBankLive` | [L1259](../../Inventory/Init.lua#L1259) |
| `Inv.IsBaganatorBankLive` | [L1282](../../Inventory/Init.lua#L1282) |
| `Inv.IsBankLive` | [L1288](../../Inventory/Init.lua#L1288) |
| `Inv.CanTakeFromBank` | [L1310](../../Inventory/Init.lua#L1310) |
| `Inv.IsBankOpen` | [L1329](../../Inventory/Init.lua#L1329) |
| `Inv.PrepareHUD` | [L1389](../../Inventory/Init.lua#L1389) |
| `Inv.Start` | [L1402](../../Inventory/Init.lua#L1402) |

### Inventory/Ledger.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Ledger.GetGoldRows` | [L45](../../Inventory/Ledger.lua#L45) |
| `Ledger.GetCurrentMoney` | [L93](../../Inventory/Ledger.lua#L93) |
| `Ledger.GetWarbandMoney` | [L104](../../Inventory/Ledger.lua#L104) |
| `Ledger.GetCurrencyRows` | [L113](../../Inventory/Ledger.lua#L113) |

### Inventory/LegacyBridge.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `FluxInv.RegisterListener` | [L14](../../Inventory/LegacyBridge.lua#L14) |
| `FluxInv.UnregisterListener` | [L21](../../Inventory/LegacyBridge.lua#L21) |
| `FluxInv.OnChanged` | [L28](../../Inventory/LegacyBridge.lua#L28) |
| `FluxInv.IsBagStorm` | [L36](../../Inventory/LegacyBridge.lua#L36) |
| `FluxInv.IsLoginHold` | [L41](../../Inventory/LegacyBridge.lua#L41) |
| `FluxInv.ShouldDeferHeavyWork` | [L47](../../Inventory/LegacyBridge.lua#L47) |
| `FluxInv.OnStormSettled` | [L52](../../Inventory/LegacyBridge.lua#L52) |
| `FluxInv.RegisterStormSettled` | [L61](../../Inventory/LegacyBridge.lua#L61) |
| `FluxInv.UnregisterStormSettled` | [L68](../../Inventory/LegacyBridge.lua#L68) |
| `FluxInv.IsMerchantOpen` | [L75](../../Inventory/LegacyBridge.lua#L75) |
| `FluxInv.IsMailboxOpen` | [L80](../../Inventory/LegacyBridge.lua#L80) |
| `FluxInv.GetCount` | [L85](../../Inventory/LegacyBridge.lua#L85) |
| `FluxInv.GetLiveCount` | [L93](../../Inventory/LegacyBridge.lua#L93) |
| `FluxInv.FindItem` | [L101](../../Inventory/LegacyBridge.lua#L101) |
| `FluxInv.GetFirst` | [L109](../../Inventory/LegacyBridge.lua#L109) |
| `FluxInv.IsBankOpen` | [L117](../../Inventory/LegacyBridge.lua#L117) |
| `FluxInv.HasWarbandBank` | [L122](../../Inventory/LegacyBridge.lua#L122) |
| `FluxInv.GetCarriedBagIDs` | [L213](../../Inventory/LegacyBridge.lua#L213) |
| `FluxInv.GetCharacterBankIDs` | [L221](../../Inventory/LegacyBridge.lua#L221) |
| `FluxInv.GetWarbandBankIDs` | [L229](../../Inventory/LegacyBridge.lua#L229) |
| `FluxInv.CountFreeSlotsInBag` | [L237](../../Inventory/LegacyBridge.lua#L237) |
| `FluxInv.GetTotalFreeBagSlots` | [L244](../../Inventory/LegacyBridge.lua#L244) |
| `FluxInventory.RegisterCountListener` | [L260](../../Inventory/LegacyBridge.lua#L260) |
| `FluxInventory.UnregisterCountListener` | [L264](../../Inventory/LegacyBridge.lua#L264) |

### Inventory/MountFlyable.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Flyable.HasIsFlyableAreaAPI` | [L176](../../Inventory/MountFlyable.lua#L176) |
| `Flyable.HasFlyableMacroCondition` | [L185](../../Inventory/MountFlyable.lua#L185) |
| `Flyable.GetCurrentInstanceMapID` | [L205](../../Inventory/MountFlyable.lua#L205) |
| `Flyable.GetCurrentContinentMapID` | [L215](../../Inventory/MountFlyable.lua#L215) |
| `Flyable.IsOutlandContinent` | [L288](../../Inventory/MountFlyable.lua#L288) |
| `Flyable.IsNorthrendContinent` | [L292](../../Inventory/MountFlyable.lua#L292) |
| `Flyable.IsOutlandOrNorthrendContinent` | [L296](../../Inventory/MountFlyable.lua#L296) |
| `Flyable.IsPlayerInOutlandOrNorthrend` | [L300](../../Inventory/MountFlyable.lua#L300) |
| `Flyable.IsInMountRestrictedInstance` | [L304](../../Inventory/MountFlyable.lua#L304) |
| `Flyable.GetMountItemLocationKey` | [L321](../../Inventory/MountFlyable.lua#L321) |
| `Flyable.BeginMountItemLocationSettle` | [L346](../../Inventory/MountFlyable.lua#L346) |
| `Flyable.EndMountItemLocationSettle` | [L357](../../Inventory/MountFlyable.lua#L357) |
| `Flyable.IsMountItemLocationSettling` | [L362](../../Inventory/MountFlyable.lua#L362) |
| `Flyable.UpdateMountItemLocationSettle` | [L367](../../Inventory/MountFlyable.lua#L367) |
| `Flyable.IsFlyableHere` | [L394](../../Inventory/MountFlyable.lua#L394) |
| `Flyable.CanPreferFlyingMountItem` | [L402](../../Inventory/MountFlyable.lua#L402) |
| `Flyable.PreferFlying` | [L455](../../Inventory/MountFlyable.lua#L455) |
| `Flyable.IsMountFlyingByRidingRequirement` | [L515](../../Inventory/MountFlyable.lua#L515) |
| `Flyable.IsMountTraitUnknown` | [L523](../../Inventory/MountFlyable.lua#L523) |
| `Flyable.IsMountZoneRestrictedToOutlandOrNorthrend` | [L527](../../Inventory/MountFlyable.lua#L527) |
| `Flyable.IsMountUsableInCurrentZone` | [L535](../../Inventory/MountFlyable.lua#L535) |
| `Flyable.InvalidateMountItemsCacheForSettle` | [L558](../../Inventory/MountFlyable.lua#L558) |
| `Flyable.InvalidateMountItemsCache` | [L562](../../Inventory/MountFlyable.lua#L562) |

### Inventory/Professions.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Prof.GetOpenProfessionInfo` | [L33](../../Inventory/Professions.lua#L33) |
| `Prof.GetRecipeLive` | [L544](../../Inventory/Professions.lua#L544) |
| `Prof.GetCompleteness` | [L571](../../Inventory/Professions.lua#L571) |
| `Prof.GetRecipe` | [L609](../../Inventory/Professions.lua#L609) |
| `Prof.GetReagents` | [L639](../../Inventory/Professions.lua#L639) |
| `Prof.GetOutput` | [L644](../../Inventory/Professions.lua#L644) |
| `Prof.IsLearned` | [L652](../../Inventory/Professions.lua#L652) |
| `Prof.ListCachedRecipes` | [L666](../../Inventory/Professions.lua#L666) |
| `Prof.ListSkillKeys` | [L678](../../Inventory/Professions.lua#L678) |
| `Prof.GetSkillInfo` | [L687](../../Inventory/Professions.lua#L687) |
| `Prof.OnProfessionEvent` | [L696](../../Inventory/Professions.lua#L696) |
| `Prof.ListAllCachedRecipes` | [L725](../../Inventory/Professions.lua#L725) |
| `Prof.OnProfessionClosed` | [L744](../../Inventory/Professions.lua#L744) |
| `Prof.OnEventPulse` | [L748](../../Inventory/Professions.lua#L748) |
| `Prof.InvalidateSkillCaches` | [L836](../../Inventory/Professions.lua#L836) |
| `Prof.HasProfessionName` | [L1007](../../Inventory/Professions.lua#L1007) |
| `Prof.GetProfessionRank` | [L1021](../../Inventory/Professions.lua#L1021) |
| `Prof.GetSkillLineRank` | [L1036](../../Inventory/Professions.lua#L1036) |
| `Prof.GetSkillRequirementFromText` | [L1091](../../Inventory/Professions.lua#L1091) |
| `Prof.GetSkillRequirementFromTooltip` | [L1104](../../Inventory/Professions.lua#L1104) |
| `Prof.GetSkillRequirementFromTooltipData` | [L1138](../../Inventory/Professions.lua#L1138) |
| `Prof.GetSkillRequirementFromBagSlot` | [L1166](../../Inventory/Professions.lua#L1166) |
| `Prof.GetItemSkillRequirement` | [L1244](../../Inventory/Professions.lua#L1244) |
| `Prof.ScheduleLoginScan` | [L1351](../../Inventory/Professions.lua#L1351) |
| `Prof.AbortLoginScan` | [L1386](../../Inventory/Professions.lua#L1386) |
| `Prof.ForceScanOpen` | [L1459](../../Inventory/Professions.lua#L1459) |
| `Prof.ResetLoginScanState` | [L1464](../../Inventory/Professions.lua#L1464) |

### Inventory/Restock/Bank/FluxBankRestock.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `BR.IsAutoEnabled` | [L858](../../Inventory/Restock/Bank/FluxBankRestock.lua#L858) |
| `BR.SetAutoEnabled` | [L862](../../Inventory/Restock/Bank/FluxBankRestock.lua#L862) |
| `BR.IsRunning` | [L866](../../Inventory/Restock/Bank/FluxBankRestock.lua#L866) |
| `BR.RegisterSessionEndCallback` | [L1711](../../Inventory/Restock/Bank/FluxBankRestock.lua#L1711) |
| `BR.Start` | [L1832](../../Inventory/Restock/Bank/FluxBankRestock.lua#L1832) |
| `BR.Stop` | [L1920](../../Inventory/Restock/Bank/FluxBankRestock.lua#L1920) |
| `BR.RunManual` | [L1940](../../Inventory/Restock/Bank/FluxBankRestock.lua#L1940) |
| `BR.GetPendingSummary` | [L2028](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2028) |
| `BR.CanRunNow` | [L2070](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2070) |
| `BR.GetCachedCanRunNow` | [L2080](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2080) |
| `BR.InvalidateCanRunCache` | [L2092](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2092) |
| `BR.GetProgress` | [L2100](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2100) |
| `BR.GetTooltipItems` | [L2114](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2114) |
| `BR.RunFastButtonRefresh` | [L2153](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2153) |
| `BR.CancelIdleCanRunWork` | [L2193](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2193) |
| `BR.RunLiveButtonRefresh` | [L2199](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2199) |
| `BR.RunMovePlanSmokeTest` | [L2299](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2299) |
| `BR.RunSimRegression` | [L2545](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2545) |
| `BR.IsDebug` | [L2569](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2569) |
| `BR.SetDebug` | [L2574](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2574) |
| `BR.DebugDumpSession` | [L2581](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2581) |
| `BR.Debug` | [L2588](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2588) |

### Inventory/Restock/Bank/FluxBankRestockButton.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Button.Refresh` | [L388](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L388) |
| `Button.RefreshIdle` | [L411](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L411) |
| `Button.RefreshLive` | [L431](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L431) |
| `Button.FindBaganatorBankView` | [L454](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L454) |
| `Button.AttachToBaganatorBank` | [L619](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L619) |
| `Button.AttachToBank` | [L721](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L721) |

### Inventory/Restock/Bank/FluxBankRestockDebug.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Dbg.IsEnabled` | [L147](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L147) |
| `Dbg.GetVerbosity` | [L151](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L151) |
| `Dbg.SetVerbosity` | [L155](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L155) |
| `Dbg.SetEnabled` | [L173](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L173) |
| `Dbg.Toggle` | [L182](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L182) |
| `Dbg.SetCategory` | [L186](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L186) |
| `Dbg.PrintImportant` | [L197](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L197) |
| `Dbg.Print` | [L209](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L209) |
| `Dbg.PrintThrottled` | [L228](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L228) |
| `Dbg.FormatStep` | [L259](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L259) |
| `Dbg.FormatAction` | [L275](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L275) |
| `Dbg.FormatResult` | [L296](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L296) |
| `Dbg.FormatTask` | [L314](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L314) |
| `Dbg.DumpLiveScan` | [L371](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L371) |
| `Dbg.DumpSession` | [L484](../../Inventory/Restock/Bank/FluxBankRestockDebug.lua#L484) |

### Inventory/Restock/Bank/FluxBankRestockInventory.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Inventory.SnapshotContainers` | [L60](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L60) |
| `Inventory.SnapshotPlayerBags` | [L88](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L88) |
| `Inventory.SnapshotBank` | [L92](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L92) |
| `Inventory.MatchItemID` | [L97](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L97) |
| `Inventory.MatchTierKind` | [L105](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L105) |
| `Inventory.FindBestFit` | [L113](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L113) |
| `Inventory.HasEmptyBagSlot` | [L160](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L160) |
| `Inventory.SlotKey` | [L181](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L181) |

### Inventory/Restock/Bank/FluxBankRestockLedger.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Ledger.Reset` | [L29](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L29) |
| `Ledger.Reserve` | [L34](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L34) |
| `Ledger.Confirm` | [L53](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L53) |
| `Ledger.Release` | [L63](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L63) |
| `Ledger.MarkSkipped` | [L80](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L80) |
| `Ledger.SetCooldown` | [L89](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L89) |
| `Ledger.ClearSkipped` | [L101](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L101) |
| `Ledger.IsReserved` | [L114](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L114) |
| `Ledger.IsSelectable` | [L125](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L125) |
| `Ledger.HasAnyReserved` | [L152](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L152) |
| `Ledger.ClearStale` | [L161](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L161) |
| `Ledger.ReleaseAll` | [L173](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L173) |
| `Ledger.WipeSkipped` | [L177](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L177) |
| `Ledger.IsSkippedStack` | [L185](../../Inventory/Restock/Bank/FluxBankRestockLedger.lua#L185) |

### Inventory/Restock/Bank/FluxBankRestockMoveContext.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Ctx.GetSlotQuantity` | [L42](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L42) |
| `Ctx.IsSlotLocked` | [L54](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L54) |
| `Ctx.CursorHasItem` | [L63](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L63) |
| `Ctx.GetCursorCount` | [L73](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L73) |
| `Ctx.SourceAcked` | [L81](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L81) |
| `Ctx.SplitSucceededBySource` | [L86](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L86) |
| `Ctx.SplitLooksUnchanged` | [L95](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L95) |
| `Ctx.ClearCursor` | [L101](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L101) |
| `Ctx.ReturnToSource` | [L112](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L112) |
| `Ctx.UseWhole` | [L132](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L132) |
| `Ctx.Split` | [L147](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L147) |
| `Ctx.SplitBag` | [L165](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L165) |
| `Ctx.Place` | [L188](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L188) |
| `Ctx.PickupWhole` | [L205](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L205) |
| `Ctx.SplitPending` | [L219](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L219) |
| `Ctx.FindBagSplitSource` | [L228](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L228) |
| `Ctx.BagStacksLocked` | [L258](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L258) |
| `Ctx.FindEmptyBankSlot` | [L274](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L274) |
| `Ctx.TryBankSplitPlace` | [L305](../../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua#L305) |

### Inventory/Restock/Bank/FluxBankRestockMoveExec.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Exec.Reset` | [L1594](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1594) |
| `Exec.Start` | [L1605](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1605) |
| `Exec.Stop` | [L1638](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1638) |
| `Exec.IsActive` | [L1650](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1650) |
| `Exec.OnSplitRejected` | [L1654](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1654) |
| `Exec.Wake` | [L1681](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1681) |

### Inventory/Restock/Bank/FluxBankRestockMovePlan.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Plan.Build` | [L243](../../Inventory/Restock/Bank/FluxBankRestockMovePlan.lua#L243) |

### Inventory/Restock/Bank/FluxBankRestockMoves.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Moves.UseWholeStackWithVerify` | [L44](../../Inventory/Restock/Bank/FluxBankRestockMoves.lua#L44) |
| `Moves.ExecuteSlotMove` | [L78](../../Inventory/Restock/Bank/FluxBankRestockMoves.lua#L78) |
| `Moves.ExecuteWholeStackToSlot` | [L154](../../Inventory/Restock/Bank/FluxBankRestockMoves.lua#L154) |
| `Moves.GetSlotCount` | [L186](../../Inventory/Restock/Bank/FluxBankRestockMoves.lua#L186) |
| `Moves.CursorHasItem` | [L200](../../Inventory/Restock/Bank/FluxBankRestockMoves.lua#L200) |
| `Moves.CanContinueBurst` | [L204](../../Inventory/Restock/Bank/FluxBankRestockMoves.lua#L204) |
| `Moves.ClearCursor` | [L208](../../Inventory/Restock/Bank/FluxBankRestockMoves.lua#L208) |
| `Moves.IssueSplit` | [L212](../../Inventory/Restock/Bank/FluxBankRestockMoves.lua#L212) |
| `Moves.ScanBankFor` | [L227](../../Inventory/Restock/Bank/FluxBankRestockMoves.lua#L227) |
| `Moves.CheckBagSpace` | [L263](../../Inventory/Restock/Bank/FluxBankRestockMoves.lua#L263) |

### Inventory/Restock/Bank/FluxBankRestockNeed.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Need.BuildFromTasks` | [L13](../../Inventory/Restock/Bank/FluxBankRestockNeed.lua#L13) |
| `Need.Credit` | [L37](../../Inventory/Restock/Bank/FluxBankRestockNeed.lua#L37) |
| `Need.TotalRemaining` | [L60](../../Inventory/Restock/Bank/FluxBankRestockNeed.lua#L60) |

### Inventory/Restock/Bank/FluxBankRestockRules.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Rules.ComputeWithdrawTarget` | [L41](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L41) |
| `Rules.ComputeWithdrawAmount` | [L85](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L85) |
| `Rules.ResolveWithdrawAmount` | [L102](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L102) |
| `Rules.GetChargeMaxAllowed` | [L107](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L107) |
| `Rules.ChargeWithdrawWouldOvershoot` | [L114](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L114) |
| `Rules.PickChargeWithdrawStack` | [L129](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L129) |
| `Rules.HasMergeBankSupply` | [L172](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L172) |
| `Rules.PickStackWithdrawStack` | [L363](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L363) |
| `Rules.ResolveNextStep` | [L541](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L541) |
| `Rules.StepWouldOvershoot` | [L881](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L881) |
| `Rules.ClampStep` | [L899](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L899) |
| `Rules.FindBagConsolidateStep` | [L932](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L932) |
| `Rules.DeriveExecKind` | [L1062](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L1062) |
| `Rules.NeedsMoverLane` | [L1119](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L1119) |
| `Rules.CanBurstExecute` | [L1125](../../Inventory/Restock/Bank/FluxBankRestockRules.lua#L1125) |

### Inventory/Restock/Core/FluxRestockList.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `FV.AddRestockItem` | [L31](../../Inventory/Restock/Core/FluxRestockList.lua#L31) |
| `FV.RemoveRestockItem` | [L55](../../Inventory/Restock/Core/FluxRestockList.lua#L55) |
| `FV.SetRestockTarget` | [L71](../../Inventory/Restock/Core/FluxRestockList.lua#L71) |
| `FV.GetRestockTargetForItem` | [L95](../../Inventory/Restock/Core/FluxRestockList.lua#L95) |
| `FV.GetRestockItemFlags` | [L101](../../Inventory/Restock/Core/FluxRestockList.lua#L101) |
| `FV.SetRestockItemFlag` | [L114](../../Inventory/Restock/Core/FluxRestockList.lua#L114) |
| `FV.DismissRestockReagent` | [L135](../../Inventory/Restock/Core/FluxRestockList.lua#L135) |
| `FV.GetRestockShowNotSold` | [L151](../../Inventory/Restock/Core/FluxRestockList.lua#L151) |
| `FV.SetRestockShowNotSold` | [L155](../../Inventory/Restock/Core/FluxRestockList.lua#L155) |
| `FV.SetRestockFoodWaterTarget` | [L189](../../Inventory/Restock/Core/FluxRestockList.lua#L189) |
| `FV.SetRestockCombatTarget` | [L196](../../Inventory/Restock/Core/FluxRestockList.lua#L196) |
| `FV.GetTierCountBankFlag` | [L203](../../Inventory/Restock/Core/FluxRestockList.lua#L203) |
| `FV.SetTierCountBankFlag` | [L208](../../Inventory/Restock/Core/FluxRestockList.lua#L208) |
| `FV.ResetTierReference` | [L215](../../Inventory/Restock/Core/FluxRestockList.lua#L215) |
| `List.CancelSpellReagentCacheWarm` | [L317](../../Inventory/Restock/Core/FluxRestockList.lua#L317) |
| `List.InvalidateSpellReagentCache` | [L320](../../Inventory/Restock/Core/FluxRestockList.lua#L320) |
| `List.OnActiveReagentsFinalized` | [L361](../../Inventory/Restock/Core/FluxRestockList.lua#L361) |
| `FV.IsStaticSpellReagentItem` | [L408](../../Inventory/Restock/Core/FluxRestockList.lua#L408) |
| `FV.IsKnownSpellReagentItem` | [L412](../../Inventory/Restock/Core/FluxRestockList.lua#L412) |
| `FV.IsSpellReagentItem` | [L423](../../Inventory/Restock/Core/FluxRestockList.lua#L423) |
| `List.RecordMerchantPrices` | [L472](../../Inventory/Restock/Core/FluxRestockList.lua#L472) |
| `List.GetItemUnitPrice` | [L482](../../Inventory/Restock/Core/FluxRestockList.lua#L482) |
| `List.GetItemUnitPriceFluxRestock.GetTargetQuantity` | [L506](../../Inventory/Restock/Core/FluxRestockList.lua#L506) |
| `endFluxRestock.SetTargetQuantity` | [L507](../../Inventory/Restock/Core/FluxRestockList.lua#L507) |
| `endFluxRestock.GetRestockCost` | [L508](../../Inventory/Restock/Core/FluxRestockList.lua#L508) |
| `endFluxRestock.IsKnownSpellReagentItem` | [L524](../../Inventory/Restock/Core/FluxRestockList.lua#L524) |
| `endFluxRestock.IsStaticSpellReagentItem` | [L525](../../Inventory/Restock/Core/FluxRestockList.lua#L525) |
| `endFluxRestock.IsSpellReagentItem` | [L526](../../Inventory/Restock/Core/FluxRestockList.lua#L526) |
| `endFluxRestock.InvalidateSpellReagentCache` | [L527](../../Inventory/Restock/Core/FluxRestockList.lua#L527) |
| `FV.InvalidateRestockOptionsPanelCache` | [L652](../../Inventory/Restock/Core/FluxRestockList.lua#L652) |
| `FV.GetRestockTargetItems` | [L657](../../Inventory/Restock/Core/FluxRestockList.lua#L657) |
| `FV.HasAnyRestockTargets` | [L809](../../Inventory/Restock/Core/FluxRestockList.lua#L809) |
| `FV.IsRestockEntrySoldAtVendor` | [L837](../../Inventory/Restock/Core/FluxRestockList.lua#L837) |
| `FV.FilterRestockListForVendor` | [L858](../../Inventory/Restock/Core/FluxRestockList.lua#L858) |
| `FV.SortRestockEntriesByVendorAvailability` | [L875](../../Inventory/Restock/Core/FluxRestockList.lua#L875) |
| `FV.GetRestockVendorItems` | [L894](../../Inventory/Restock/Core/FluxRestockList.lua#L894) |
| `FV.RefreshRestockCacheEntries` | [L906](../../Inventory/Restock/Core/FluxRestockList.lua#L906) |
| `FV.HasRestockNeeded` | [L936](../../Inventory/Restock/Core/FluxRestockList.lua#L936) |
| `FV.GetRestockTotalCost` | [L946](../../Inventory/Restock/Core/FluxRestockList.lua#L946) |
| `FV.RefreshMerchantOptionsCheckboxes` | [L962](../../Inventory/Restock/Core/FluxRestockList.lua#L962) |
| `Registry.InvalidateBankTargetsCache` | [L1011](../../Inventory/Restock/Core/FluxRestockList.lua#L1011) |
| `Registry.RegisterProvider` | [L1016](../../Inventory/Restock/Core/FluxRestockList.lua#L1016) |
| `Registry.UnregisterProvider` | [L1024](../../Inventory/Restock/Core/FluxRestockList.lua#L1024) |
| `Registry.GetBankTargets` | [L1075](../../Inventory/Restock/Core/FluxRestockList.lua#L1075) |
| `Registry.GetBankTargetList` | [L1093](../../Inventory/Restock/Core/FluxRestockList.lua#L1093) |
| `Registry.GetItemMaxStack` | [L1110](../../Inventory/Restock/Core/FluxRestockList.lua#L1110) |
| `Registry.CountItemInBank` | [L1121](../../Inventory/Restock/Core/FluxRestockList.lua#L1121) |
| `Registry.GetSlotCharges` | [L1227](../../Inventory/Restock/Core/FluxRestockList.lua#L1227) |
| `Registry.GetChargeInfo` | [L1314](../../Inventory/Restock/Core/FluxRestockList.lua#L1314) |
| `Registry.IsChargeItem` | [L1375](../../Inventory/Restock/Core/FluxRestockList.lua#L1375) |
| `Registry.GetItemMaxCharges` | [L1380](../../Inventory/Restock/Core/FluxRestockList.lua#L1380) |
| `Registry.GetChargeAwareCount` | [L1398](../../Inventory/Restock/Core/FluxRestockList.lua#L1398) |

### Inventory/Restock/Core/FluxRestockSession.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Session.NotifyItemsRemoved` | [L15](../../Inventory/Restock/Core/FluxRestockSession.lua#L15) |
| `Session.OnMerchantOpen` | [L42](../../Inventory/Restock/Core/FluxRestockSession.lua#L42) |
| `Session.OnMerchantClose` | [L46](../../Inventory/Restock/Core/FluxRestockSession.lua#L46) |
| `Session.OnBankOpen` | [L49](../../Inventory/Restock/Core/FluxRestockSession.lua#L49) |
| `Session.OnBankClose` | [L53](../../Inventory/Restock/Core/FluxRestockSession.lua#L53) |
| `Session.ApplyRemovalOnlyClose` | [L61](../../Inventory/Restock/Core/FluxRestockSession.lua#L61) |

### Inventory/Restock/Core/FluxRestockSettings.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `S.Get` | [L210](../../Inventory/Restock/Core/FluxRestockSettings.lua#L210) |
| `FluxVendorAuto.EnsureSettings` | [L238](../../Inventory/Restock/Core/FluxRestockSettings.lua#L238) |
| `FluxVendorAuto.GetSettings` | [L242](../../Inventory/Restock/Core/FluxRestockSettings.lua#L242) |

### Inventory/Restock/Core/Tiers/FluxRestockTiers.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Tiers.NotifyTierCountsOnly` | [L27](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L27) |
| `Tiers.RegisterCountsOnlyHandler` | [L31](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L31) |
| `Tiers.Init` | [L63](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L63) |
| `Combat.GetTarget` | [L225](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L225) |
| `Combat.SetTarget` | [L228](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L228) |
| `Combat.GetCurrentCount` | [L231](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L231) |
| `Combat.GetBankCountForKind` | [L234](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L234) |
| `Combat.IsTierEligible` | [L237](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L237) |
| `Combat.RememberOwnedTiers` | [L240](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L240) |
| `Combat.ApplyVendorTierStatusToEntry` | [L243](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L243) |
| `Combat.PrepareInferiorForRestock` | [L263](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L263) |
| `Combat.GetRestockState` | [L266](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L266) |
| `Combat.ToggleEditBox` | [L273](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L273) |
| `Combat.WireRestockClick` | [L278](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L278) |
| `Combat.AppendRestockTooltipLines` | [L283](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L283) |
| `FFWR.GetTierCount` | [L290](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L290) |
| `FFWR.CountBankForRestockKind` | [L293](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L293) |
| `FFWR.GetTargets` | [L296](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L296) |
| `FFWR.IsEligible` | [L302](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L302) |
| `FFWR.IsWaterEligible` | [L305](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L305) |
| `FFWR.ToggleEditBox` | [L308](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L308) |
| `FFWR.ApplyVendorTierStatusToEntry` | [L313](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L313) |
| `FFWR.VendorHasTierFoodWater` | [L316](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L316) |
| `FFWR.GetVendorTierInfo` | [L321](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L321) |
| `FluxNCFoodWaterRestockUI.ToggleEditBox` | [L327](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L327) |
| `FluxNCFoodWaterRestockUI.SuppressCheckedVisual` | [L332](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L332) |
| `JunkSync.Schedule` | [L341](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L341) |
| `JunkSync.RunNow` | [L344](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L344) |
| `JunkSync.GetInferiorTierReferences` | [L347](../../Inventory/Restock/Core/Tiers/FluxRestockTiers.lua#L347) |

### Inventory/Restock/Core/Tiers/FluxRestockTiers_Bank.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Tiers.InvalidateBankKindStacksIndex` | [L128](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Bank.lua#L128) |
| `Tiers.FindBankStacksForKind` | [L133](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Bank.lua#L133) |
| `Tiers.SumBankStacksForKind` | [L149](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Bank.lua#L149) |
| `Tiers.GetBankRestockEntries` | [L157](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Bank.lua#L157) |

### Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Tiers.CancelInferiorPass` | [L250](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L250) |
| `Tiers.RecomputeInferior` | [L274](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L274) |
| `Tiers.BumpVendorSeenGeneration` | [L376](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L376) |
| `Tiers.IsInferiorPassComplete` | [L381](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L381) |
| `Tiers.EnsureInferiorMarksForVendor` | [L385](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L385) |
| `Tiers.RunVendorTierAndInferiorPass` | [L421](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L421) |
| `Tiers.TryMarkAddedItems` | [L453](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L453) |
| `Tiers.TryUnmarkRemovedItems` | [L530](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L530) |
| `Tiers.ItemIsUpgradeInferiorForKinds` | [L562](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L562) |
| `Tiers.HasUpgradeInferiorForKinds` | [L589](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L589) |
| `Tiers.BagsHaveInferiorForPendingKinds` | [L605](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L605) |
| `Tiers.ForcePublishInferiorForKinds` | [L642](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L642) |
| `Tiers.RequestRecompute` | [L692](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L692) |
| `Tiers.TryRunDeferredLoginSettle` | [L786](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L786) |
| `Tiers.RunPulseEndLoginSettle` | [L790](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L790) |

### Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Tiers.GetTierIcon` | [L53](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L53) |
| `Tiers.GetKindLabel` | [L57](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L57) |
| `P.Settings` | [L61](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L61) |
| `P.KindStore` | [L65](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L65) |
| `P.RoundTier` | [L79](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L79) |
| `P.After` | [L88](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L88) |
| `P.Inv` | [L98](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L98) |
| `P.IC` | [L102](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L102) |
| `P.Best` | [L106](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L106) |
| `P.ClassifyMod` | [L110](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L110) |
| `P.FJ` | [L114](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L114) |
| `P.GetSavedTier` | [L118](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L118) |
| `P.SetSavedTier` | [L126](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L126) |
| `P.GetBagCacheGen` | [L150](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L150) |
| `P.GetMerchantCacheGen` | [L158](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L158) |
| `P.IsMerchantFrameOpen` | [L166](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L166) |
| `Tiers.InvalidateTierQueryCache` | [L170](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L170) |
| `Tiers.InvalidateTooltipDisplayCache` | [L185](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L185) |
| `Tiers.IsTierCountPending` | [L194](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L194) |
| `Tiers.FlushTierCountRefresh` | [L198](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L198) |
| `Tiers.CancelPendingRecompute` | [L202](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L202) |
| `Tiers.CancelBackgroundWork` | [L206](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L206) |

### Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `P.ClassifyItem` | [L152](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L152) |
| `P.ClassificationForTierCount` | [L210](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L210) |
| `P.TierAxisValue` | [L236](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L236) |
| `Tiers.Classify` | [L240](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L240) |
| `P.MerchantItemLink` | [L245](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L245) |
| `P.ClassifyMerchantItem` | [L259](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L259) |
| `P.ScanVendorBestPurchasable` | [L341](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L341) |
| `Tiers.GetItemTierValue` | [L366](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L366) |
| `Tiers.GetBagOwnedTier` | [L372](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L372) |
| `Tiers.GetOwnedTier` | [L400](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L400) |
| `Tiers.GetEffectiveReferenceTier` | [L443](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L443) |
| `Tiers.GetReferenceTier` | [L486](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L486) |
| `Tiers.RememberOwnedTiers` | [L496](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L496) |
| `Tiers.ResetTierReference` | [L504](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L504) |
| `P.GetVendorBestTier` | [L525](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L525) |
| `Tiers.GetInferiorReferenceTier` | [L530](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L530) |
| `P.GetTierRestockThreshold` | [L558](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L558) |
| `P.IsTierItemUsable` | [L578](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L578) |
| `P.ItemMatchesTier` | [L592](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L592) |
| `P.ItemMatchesTierForBank` | [L613](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L613) |
| `P.ItemMatchesTierLooseForBank` | [L624](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L624) |
| `Tiers.ItemMatchesRestockKind` | [L634](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L634) |
| `Tiers.StackMatchesBankRestockKind` | [L647](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L647) |
| `Tiers.GetTierCount` | [L675](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L675) |
| `Tiers.GetSnapshotTierCount` | [L760](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L760) |
| `Tiers.GetTierBagTotalForBankRestock` | [L764](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L764) |
| `Tiers.GetBankCountForKind` | [L842](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L842) |
| `Tiers.GetCachedTooltipReferenceTier` | [L900](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L900) |
| `Tiers.GetTooltipDisplay` | [L904](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L904) |
| `Tiers.KindsTouchedByItemID` | [L912](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L912) |

### Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Tiers.GetTarget` | [L8](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L8) |
| `Tiers.SetTarget` | [L16](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L16) |
| `Tiers.GetCountBankFlag` | [L35](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L35) |
| `Tiers.SetCountBankFlag` | [L43](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L43) |
| `Tiers.IsMarkInferiorEnabled` | [L54](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L54) |
| `Tiers.SetMarkInferiorEnabled` | [L62](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L62) |
| `Tiers.IsTierEligible` | [L71](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L71) |
| `Tiers.NeedsTierRestockTargets` | [L88](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L88) |
| `Tiers.EnsureStores` | [L97](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L97) |

### Inventory/Restock/Core/Tiers/FluxRestockTiers_UI.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Tiers.ToggleEditBox` | [L101](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_UI.lua#L101) |
| `Tiers.GetRestockProxyMacro` | [L141](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_UI.lua#L141) |
| `Tiers.WireRestockClick` | [L147](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_UI.lua#L147) |
| `Tiers.AppendRestockTooltipLines` | [L172](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_UI.lua#L172) |

### Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Tiers.GetVendorTierStatus` | [L70](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L70) |
| `Tiers.AppendTierReferenceLines` | [L89](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L89) |
| `Tiers.SeedReferenceFromVendor` | [L111](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L111) |
| `Tiers.ApplyVendorTierUpgrades` | [L151](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L151) |
| `Tiers.RefreshTierReferences` | [L211](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L211) |
| `Tiers.GetVendorUpgradeKinds` | [L223](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L223) |
| `Tiers.PeekVendorUpgradeSession` | [L229](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L229) |
| `Tiers.HasPendingVendorUpgradeRestock` | [L240](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L240) |
| `Tiers.ClearPendingVendorUpgradeKinds` | [L244](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L244) |
| `Tiers.HasPendingMerchantTierClassification` | [L302](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L302) |
| `Tiers.ScheduleVendorTierRefresh` | [L321](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L321) |
| `Tiers.WarmMerchantTierItems` | [L373](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L373) |
| `Tiers.ClearMerchantWarmSet` | [L473](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L473) |
| `Tiers.ClearVendorInferiorSnapshot` | [L481](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L481) |
| `Tiers.NotifyTierReferenceUIRefresh` | [L488](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua#L488) |

### Inventory/Restock/FluxRestock_Inv.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `RI.API` | [L91](../../Inventory/Restock/FluxRestock_Inv.lua#L91) |
| `RI.IsReady` | [L95](../../Inventory/Restock/FluxRestock_Inv.lua#L95) |
| `RI.IsReliable` | [L100](../../Inventory/Restock/FluxRestock_Inv.lua#L100) |
| `RI.IsBankOpen` | [L108](../../Inventory/Restock/FluxRestock_Inv.lua#L108) |
| `RI.IsBankLive` | [L125](../../Inventory/Restock/FluxRestock_Inv.lua#L125) |
| `RI.HasWarband` | [L139](../../Inventory/Restock/FluxRestock_Inv.lua#L139) |
| `RI.GetCarriedBagIDs` | [L145](../../Inventory/Restock/FluxRestock_Inv.lua#L145) |
| `RI.GetBagContainerIDs` | [L153](../../Inventory/Restock/FluxRestock_Inv.lua#L153) |
| `RI.GetPlayerRestockBagIDs` | [L164](../../Inventory/Restock/FluxRestock_Inv.lua#L164) |
| `RI.GetCharacterBankIDs` | [L172](../../Inventory/Restock/FluxRestock_Inv.lua#L172) |
| `RI.GetWarbandBankIDs` | [L180](../../Inventory/Restock/FluxRestock_Inv.lua#L180) |
| `RI.GetCount` | [L203](../../Inventory/Restock/FluxRestock_Inv.lua#L203) |
| `RI.GetLiveCount` | [L234](../../Inventory/Restock/FluxRestock_Inv.lua#L234) |
| `RI.GetUniqueItems` | [L242](../../Inventory/Restock/FluxRestock_Inv.lua#L242) |
| `RI.Bags.GetUniqueItems` | [L252](../../Inventory/Restock/FluxRestock_Inv.lua#L252) |
| `RI.ForEachLocation` | [L256](../../Inventory/Restock/FluxRestock_Inv.lua#L256) |
| `RI.Find` | [L263](../../Inventory/Restock/FluxRestock_Inv.lua#L263) |
| `RI.GetFirst` | [L271](../../Inventory/Restock/FluxRestock_Inv.lua#L271) |
| `RI.GetBagSnapshotGeneration` | [L279](../../Inventory/Restock/FluxRestock_Inv.lua#L279) |
| `RI.GetFirstFreeBagSlot` | [L290](../../Inventory/Restock/FluxRestock_Inv.lua#L290) |
| `RI.FindFirstBagSlot` | [L307](../../Inventory/Restock/FluxRestock_Inv.lua#L307) |
| `RI.FindBagStacks` | [L315](../../Inventory/Restock/FluxRestock_Inv.lua#L315) |
| `RI.ForEachBagSlot` | [L344](../../Inventory/Restock/FluxRestock_Inv.lua#L344) |
| `RI.GetContainerNumSlots` | [L364](../../Inventory/Restock/FluxRestock_Inv.lua#L364) |
| `RI.GetContainerNumFreeSlots` | [L372](../../Inventory/Restock/FluxRestock_Inv.lua#L372) |
| `RI.CountFreeSlotsInBag` | [L380](../../Inventory/Restock/FluxRestock_Inv.lua#L380) |
| `RI.GetTotalFreeBagSlots` | [L406](../../Inventory/Restock/FluxRestock_Inv.lua#L406) |
| `RI.GetContainerItemInfo` | [L491](../../Inventory/Restock/FluxRestock_Inv.lua#L491) |
| `RI.GetContainerItemID` | [L499](../../Inventory/Restock/FluxRestock_Inv.lua#L499) |
| `RI.GetContainerItemLink` | [L517](../../Inventory/Restock/FluxRestock_Inv.lua#L517) |
| `RI.ItemExistsInInventory` | [L529](../../Inventory/Restock/FluxRestock_Inv.lua#L529) |
| `RI.IsBankContainer` | [L546](../../Inventory/Restock/FluxRestock_Inv.lua#L546) |
| `RI.PickupContainerItem` | [L555](../../Inventory/Restock/FluxRestock_Inv.lua#L555) |
| `RI.GetLastBankUse` | [L586](../../Inventory/Restock/FluxRestock_Inv.lua#L586) |
| `RI.NoteBankUseAfter` | [L590](../../Inventory/Restock/FluxRestock_Inv.lua#L590) |
| `RI.UseContainerItem` | [L599](../../Inventory/Restock/FluxRestock_Inv.lua#L599) |
| `RI.SplitContainerItemPending` | [L685](../../Inventory/Restock/FluxRestock_Inv.lua#L685) |
| `RI.SplitContainerItem` | [L713](../../Inventory/Restock/FluxRestock_Inv.lua#L713) |
| `RI.SetMerchantOpen` | [L749](../../Inventory/Restock/FluxRestock_Inv.lua#L749) |
| `RI.IsMerchantOpen` | [L753](../../Inventory/Restock/FluxRestock_Inv.lua#L753) |
| `RI.IsAutomationQuiet` | [L766](../../Inventory/Restock/FluxRestock_Inv.lua#L766) |
| `RI.NotifyAutomationPulse` | [L784](../../Inventory/Restock/FluxRestock_Inv.lua#L784) |
| `RI.OnQuietSettled` | [L795](../../Inventory/Restock/FluxRestock_Inv.lua#L795) |
| `RI.IsBagStorm` | [L810](../../Inventory/Restock/FluxRestock_Inv.lua#L810) |
| `RI.NotifyBagStorm` | [L831](../../Inventory/Restock/FluxRestock_Inv.lua#L831) |
| `RI.OnStormSettled` | [L842](../../Inventory/Restock/FluxRestock_Inv.lua#L842) |
| `RI.RegisterStormSettled` | [L857](../../Inventory/Restock/FluxRestock_Inv.lua#L857) |
| `RI.UnregisterStormSettled` | [L864](../../Inventory/Restock/FluxRestock_Inv.lua#L864) |
| `RI.ShouldDeferHeavyWork` | [L868](../../Inventory/Restock/FluxRestock_Inv.lua#L868) |
| `RI.NotifyItemsRemoved` | [L875](../../Inventory/Restock/FluxRestock_Inv.lua#L875) |
| `RI.ForceRefreshBagCounts` | [L878](../../Inventory/Restock/FluxRestock_Inv.lua#L878) |
| `RI.FlushExtraButtonIdentityRefresh` | [L881](../../Inventory/Restock/FluxRestock_Inv.lua#L881) |
| `Bank.IsOpen` | [L929](../../Inventory/Restock/FluxRestock_Inv.lua#L929) |
| `Bank.IsLive` | [L943](../../Inventory/Restock/FluxRestock_Inv.lua#L943) |
| `Bank.GetContainerIDs` | [L947](../../Inventory/Restock/FluxRestock_Inv.lua#L947) |
| `Bank.GetScanDebug` | [L977](../../Inventory/Restock/FluxRestock_Inv.lua#L977) |
| `Bank.IsModernBank` | [L1013](../../Inventory/Restock/FluxRestock_Inv.lua#L1013) |
| `Bank.HasLegacyBankBags` | [L1017](../../Inventory/Restock/FluxRestock_Inv.lua#L1017) |
| `Bank.HasReagentBag` | [L1032](../../Inventory/Restock/FluxRestock_Inv.lua#L1032) |
| `Bank.IsBankContainer` | [L1036](../../Inventory/Restock/FluxRestock_Inv.lua#L1036) |
| `Bank.GetBankTypeForContainer` | [L1040](../../Inventory/Restock/FluxRestock_Inv.lua#L1040) |
| `Bank.Persist` | [L1129](../../Inventory/Restock/FluxRestock_Inv.lua#L1129) |
| `Bank.ForEachLiveStack` | [L1293](../../Inventory/Restock/FluxRestock_Inv.lua#L1293) |
| `Bank.Refresh` | [L1352](../../Inventory/Restock/FluxRestock_Inv.lua#L1352) |
| `Bank.GetCount` | [L1411](../../Inventory/Restock/FluxRestock_Inv.lua#L1411) |
| `Bank.GetCharacterCounts` | [L1448](../../Inventory/Restock/FluxRestock_Inv.lua#L1448) |
| `Bank.GetWarbandCounts` | [L1464](../../Inventory/Restock/FluxRestock_Inv.lua#L1464) |
| `Bank.GetGeneration` | [L1483](../../Inventory/Restock/FluxRestock_Inv.lua#L1483) |
| `Bank.FindStacks` | [L1490](../../Inventory/Restock/FluxRestock_Inv.lua#L1490) |
| `Bank.ForEachOpenStack` | [L1536](../../Inventory/Restock/FluxRestock_Inv.lua#L1536) |
| `Bank.GetItemLink` | [L1568](../../Inventory/Restock/FluxRestock_Inv.lua#L1568) |
| `Bank.RegisterBankOpen` | [L1582](../../Inventory/Restock/FluxRestock_Inv.lua#L1582) |
| `Bank.RegisterBankClose` | [L1589](../../Inventory/Restock/FluxRestock_Inv.lua#L1589) |
| `Bank.RefreshIfOpen` | [L1596](../../Inventory/Restock/FluxRestock_Inv.lua#L1596) |
| `Bank.RequestLiveRefresh` | [L1606](../../Inventory/Restock/FluxRestock_Inv.lua#L1606) |
| `Bank.SchedulePersist` | [L1610](../../Inventory/Restock/FluxRestock_Inv.lua#L1610) |
| `RI.Notify` | [L1644](../../Inventory/Restock/FluxRestock_Inv.lua#L1644) |
| `RI.Register` | [L1787](../../Inventory/Restock/FluxRestock_Inv.lua#L1787) |
| `RI.Unregister` | [L1799](../../Inventory/Restock/FluxRestock_Inv.lua#L1799) |

### Inventory/Restock/Junk/FluxJunk.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `FJ.Init` | [L83](../../Inventory/Restock/Junk/FluxJunk.lua#L83) |
| `FJ.GetFilters` | [L87](../../Inventory/Restock/Junk/FluxJunk.lua#L87) |
| `FJ.GetDisplay` | [L91](../../Inventory/Restock/Junk/FluxJunk.lua#L91) |
| `FJ.IsExplicitUseful` | [L108](../../Inventory/Restock/Junk/FluxJunk.lua#L108) |
| `FJ.IsExplicitJunk` | [L114](../../Inventory/Restock/Junk/FluxJunk.lua#L114) |
| `FJ.IsManualRestockItem` | [L148](../../Inventory/Restock/Junk/FluxJunk.lua#L148) |
| `FJ.SetInferiorSet` | [L195](../../Inventory/Restock/Junk/FluxJunk.lua#L195) |
| `FJ.IsUpgradeInferior` | [L250](../../Inventory/Restock/Junk/FluxJunk.lua#L250) |
| `FJ.MarkUpgradeInferior` | [L255](../../Inventory/Restock/Junk/FluxJunk.lua#L255) |
| `FJ.HasUpgradeInferiorEntries` | [L279](../../Inventory/Restock/Junk/FluxJunk.lua#L279) |
| `FJ.AnyUpgradeInferiorInBags` | [L285](../../Inventory/Restock/Junk/FluxJunk.lua#L285) |
| `FJ.ForEachUpgradeInferiorItemID` | [L306](../../Inventory/Restock/Junk/FluxJunk.lua#L306) |
| `FJ.UnmarkUpgradeInferior` | [L313](../../Inventory/Restock/Junk/FluxJunk.lua#L313) |
| `FJ.ClearUpgradeInferiorList` | [L322](../../Inventory/Restock/Junk/FluxJunk.lua#L322) |
| `FJ.InvalidateRules` | [L333](../../Inventory/Restock/Junk/FluxJunk.lua#L333) |
| `FJ.InvalidateItemRules` | [L342](../../Inventory/Restock/Junk/FluxJunk.lua#L342) |
| `FJ.OnItemDataLoaded` | [L352](../../Inventory/Restock/Junk/FluxJunk.lua#L352) |
| `FJ.IsConjuredConsumable` | [L473](../../Inventory/Restock/Junk/FluxJunk.lua#L473) |
| `FJ.IsLowConsumable` | [L482](../../Inventory/Restock/Junk/FluxJunk.lua#L482) |
| `FJ.IsFiltered` | [L626](../../Inventory/Restock/Junk/FluxJunk.lua#L626) |
| `FJ.IsJunk` | [L636](../../Inventory/Restock/Junk/FluxJunk.lua#L636) |
| `FJ.IsJunkForDisplay` | [L659](../../Inventory/Restock/Junk/FluxJunk.lua#L659) |
| `FJ.IsBlizzardVendorJunk` | [L725](../../Inventory/Restock/Junk/FluxJunk.lua#L725) |
| `FJ.NativeJunkCount` | [L754](../../Inventory/Restock/Junk/FluxJunk.lua#L754) |
| `FJ.HasItemInPlayerBags` | [L766](../../Inventory/Restock/Junk/FluxJunk.lua#L766) |
| `FJ.FindBagSlot` | [L771](../../Inventory/Restock/Junk/FluxJunk.lua#L771) |
| `FJ.IterateJunk` | [L856](../../Inventory/Restock/Junk/FluxJunk.lua#L856) |
| `FJ.IterateUpgradeInferiorFast` | [L866](../../Inventory/Restock/Junk/FluxJunk.lua#L866) |
| `FJ.SetUpgradeInferiorKindFilter` | [L882](../../Inventory/Restock/Junk/FluxJunk.lua#L882) |
| `FJ.ClearUpgradeInferiorKindFilter` | [L887](../../Inventory/Restock/Junk/FluxJunk.lua#L887) |
| `FJ.HasUpgradeInferiorForKinds` | [L892](../../Inventory/Restock/Junk/FluxJunk.lua#L892) |
| `FJ.InvalidateJunkWorklist` | [L950](../../Inventory/Restock/Junk/FluxJunk.lua#L950) |
| `FJ.IsSlotProtectedFromSell` | [L954](../../Inventory/Restock/Junk/FluxJunk.lua#L954) |
| `FJ.BuildJunkSlotWorklist` | [L963](../../Inventory/Restock/Junk/FluxJunk.lua#L963) |
| `FJ.EnsureJunkWorklist` | [L986](../../Inventory/Restock/Junk/FluxJunk.lua#L986) |
| `FJ.IterateJunkWorklist` | [L995](../../Inventory/Restock/Junk/FluxJunk.lua#L995) |
| `FJ.RemoveJunkSlotFromWorklist` | [L1012](../../Inventory/Restock/Junk/FluxJunk.lua#L1012) |
| `FJ.HasJunkWorklistRemaining` | [L1031](../../Inventory/Restock/Junk/FluxJunk.lua#L1031) |
| `FJ.GetUpgradeInferiorSlotCount` | [L1037](../../Inventory/Restock/Junk/FluxJunk.lua#L1037) |
| `FJ.InvalidateJunkSlotCount` | [L1057](../../Inventory/Restock/Junk/FluxJunk.lua#L1057) |
| `FJ.GetJunkSlotCount` | [L1063](../../Inventory/Restock/Junk/FluxJunk.lua#L1063) |
| `FJ.GetJunkSlotCountFast` | [L1067](../../Inventory/Restock/Junk/FluxJunk.lua#L1067) |
| `FJ.RefreshJunkSlotCountFast` | [L1075](../../Inventory/Restock/Junk/FluxJunk.lua#L1075) |
| `FJ.AdjustJunkSlotCount` | [L1079](../../Inventory/Restock/Junk/FluxJunk.lua#L1079) |
| `FJ.RegisterJunkCountListener` | [L1087](../../Inventory/Restock/Junk/FluxJunk.lua#L1087) |
| `FJ.OnBagSnapshotDiff` | [L1092](../../Inventory/Restock/Junk/FluxJunk.lua#L1092) |
| `FJ.AnyJunkInBags` | [L1103](../../Inventory/Restock/Junk/FluxJunk.lua#L1103) |
| `FJ.AnyExplicitJunkInBags` | [L1110](../../Inventory/Restock/Junk/FluxJunk.lua#L1110) |
| `FJ.AnyBlizzardVendorJunkInBags` | [L1127](../../Inventory/Restock/Junk/FluxJunk.lua#L1127) |
| `FJ.HasSellableJunkForButton` | [L1158](../../Inventory/Restock/Junk/FluxJunk.lua#L1158) |
| `FJ.RefreshSellableJunkButtonState` | [L1183](../../Inventory/Restock/Junk/FluxJunk.lua#L1183) |
| `FJ.GetSellButtonStats` | [L1192](../../Inventory/Restock/Junk/FluxJunk.lua#L1192) |
| `FJ.InvalidateSellButtonStats` | [L1228](../../Inventory/Restock/Junk/FluxJunk.lua#L1228) |
| `FJ.GetSellReport` | [L1233](../../Inventory/Restock/Junk/FluxJunk.lua#L1233) |
| `FJ.FireListChanged` | [L1252](../../Inventory/Restock/Junk/FluxJunk.lua#L1252) |
| `FJ.RegisterListChanged` | [L1266](../../Inventory/Restock/Junk/FluxJunk.lua#L1266) |
| `FJ.NotifyVisualRefresh` | [L1271](../../Inventory/Restock/Junk/FluxJunk.lua#L1271) |
| `FJ.RegisterVisualRefresh` | [L1277](../../Inventory/Restock/Junk/FluxJunk.lua#L1277) |
| `FJ.RefreshJunkVisuals` | [L1282](../../Inventory/Restock/Junk/FluxJunk.lua#L1282) |
| `FJ.ToggleJunk` | [L1292](../../Inventory/Restock/Junk/FluxJunk.lua#L1292) |
| `FJ.AddJunk` | [L1305](../../Inventory/Restock/Junk/FluxJunk.lua#L1305) |
| `FJ.MarkUseful` | [L1312](../../Inventory/Restock/Junk/FluxJunk.lua#L1312) |
| `FJ.ForgetJunk` | [L1320](../../Inventory/Restock/Junk/FluxJunk.lua#L1320) |
| `FJ.ClearAutoJunkMark` | [L1330](../../Inventory/Restock/Junk/FluxJunk.lua#L1330) |
| `FJ.InvalidateJunkTabListCache` | [L1351](../../Inventory/Restock/Junk/FluxJunk.lua#L1351) |
| `FJ.GetExplicitJunkList` | [L1369](../../Inventory/Restock/Junk/FluxJunk.lua#L1369) |
| `FJ.GetUsefulList` | [L1384](../../Inventory/Restock/Junk/FluxJunk.lua#L1384) |
| `FJ.GetAutoJunkList` | [L1403](../../Inventory/Restock/Junk/FluxJunk.lua#L1403) |
| `FJ.GetJunkTabList` | [L1424](../../Inventory/Restock/Junk/FluxJunk.lua#L1424) |
| `FJ.RebuildJunkTabListCache` | [L1449](../../Inventory/Restock/Junk/FluxJunk.lua#L1449) |
| `FJ.IsAutoJunk` | [L1454](../../Inventory/Restock/Junk/FluxJunk.lua#L1454) |
| `FJ.OnManualRestockChanged` | [L1471](../../Inventory/Restock/Junk/FluxJunk.lua#L1471) |
| `FJ.GetItemIdFromCursor` | [L1502](../../Inventory/Restock/Junk/FluxJunk.lua#L1502) |
| `FJ.HandleItemDrop` | [L1513](../../Inventory/Restock/Junk/FluxJunk.lua#L1513) |
| `FJ.WarmJunkDisplayCacheForBags` | [L1531](../../Inventory/Restock/Junk/FluxJunk.lua#L1531) |
| `FJ.WarmJunkDisplayCacheThoroughChunked` | [L1532](../../Inventory/Restock/Junk/FluxJunk.lua#L1532) |
| `FJ.IsJunkDisplayCacheWarm` | [L1535](../../Inventory/Restock/Junk/FluxJunk.lua#L1535) |
| `FJ.ResetJunkDisplayCacheWarm` | [L1536](../../Inventory/Restock/Junk/FluxJunk.lua#L1536) |
| `FJ.InvalidateJunkBag` | [L1537](../../Inventory/Restock/Junk/FluxJunk.lua#L1537) |
| `FJ.InvalidateAllJunkBags` | [L1538](../../Inventory/Restock/Junk/FluxJunk.lua#L1538) |
| `FJ.FlushDeferredJunkDisplayCaches` | [L1539](../../Inventory/Restock/Junk/FluxJunk.lua#L1539) |
| `FJ.RelocateBagJunkCache` | [L1540](../../Inventory/Restock/Junk/FluxJunk.lua#L1540) |
| `FJ.RefreshJunkDisplaySlot` | [L1541](../../Inventory/Restock/Junk/FluxJunk.lua#L1541) |
| `FJ.SetJunkDisplayCacheSlot` | [L1542](../../Inventory/Restock/Junk/FluxJunk.lua#L1542) |
| `FJ.BeginVisualPaint` | [L1543](../../Inventory/Restock/Junk/FluxJunk.lua#L1543) |
| `FJ.EndVisualPaint` | [L1544](../../Inventory/Restock/Junk/FluxJunk.lua#L1544) |
| `FJ.IsVisualPaintActive` | [L1545](../../Inventory/Restock/Junk/FluxJunk.lua#L1545) |
| `FJ.RescanAutoJunkRules` | [L1546](../../Inventory/Restock/Junk/FluxJunk.lua#L1546) |
| `FJ.SyncAutoJunkMarks` | [L1547](../../Inventory/Restock/Junk/FluxJunk.lua#L1547) |
| `FJ.ScheduleAutoJunkSync` | [L1548](../../Inventory/Restock/Junk/FluxJunk.lua#L1548) |
| `FJ.ScheduleJunkTabAuthoritativeRefresh` | [L1550](../../Inventory/Restock/Junk/FluxJunk.lua#L1550) |
| `FJ.PromoteMarkedInferiorToAutoJunk` | [L1580](../../Inventory/Restock/Junk/FluxJunk.lua#L1580) |
| `FJ.PromoteInferiorItemsToAutoJunk` | [L1581](../../Inventory/Restock/Junk/FluxJunk.lua#L1581) |
| `FJ.ReconcileUpgradeInferiorMarks` | [L1582](../../Inventory/Restock/Junk/FluxJunk.lua#L1582) |
| `FJ.EnsureInferiorConsumableMarked` | [L1583](../../Inventory/Restock/Junk/FluxJunk.lua#L1583) |
| `FJ.ScheduleConjureInferiorJunkSync` | [L1585](../../Inventory/Restock/Junk/FluxJunk.lua#L1585) |
| `FJ.AppendTierReferenceRestoreLines` | [L1592](../../Inventory/Restock/Junk/FluxJunk.lua#L1592) |
| `FJ.HasConjureJunkFilterAvailable` | [L1599](../../Inventory/Restock/Junk/FluxJunk.lua#L1599) |
| `FJ.ScanInferiorTierConsumables` | [L1623](../../Inventory/Restock/Junk/FluxJunk.lua#L1623) |
| `FJ.PrintInferiorTierScan` | [L1635](../../Inventory/Restock/Junk/FluxJunk.lua#L1635) |

### Inventory/Restock/Junk/FluxJunkOverlay.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Overlay.ArePaintTargetsVisible` | [L600](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L600) |
| `Overlay.ScheduleCharacterBagTransferPaint` | [L775](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L775) |
| `Overlay.UpdateAll` | [L890](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L890) |
| `Overlay.UpdateDirtyBags` | [L927](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L927) |
| `Overlay.UpdateAllBank` | [L1255](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1255) |
| `Overlay.ScheduleMainBankGridRefresh` | [L1264](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1264) |
| `Overlay.ApplyBankInternalContext` | [L1290](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1290) |
| `Overlay.ApplyDispatchContext` | [L1313](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1313) |
| `Overlay.ScheduleBankTransferPaint` | [L1389](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1389) |
| `Overlay.ApplyBankOnlyContext` | [L1403](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1403) |
| `Overlay.MarkBankGridDirty` | [L1413](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1413) |
| `Overlay.RepaintInferiorVisuals` | [L1491](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1491) |
| `Overlay.ScheduleInferiorRepaintBurst` | [L1500](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1500) |
| `Overlay.CancelInferiorRepaintBurst` | [L1556](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1556) |
| `Overlay.OnLoginPulseEndSettled` | [L1561](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1561) |
| `Overlay.FlushDeferredPaint` | [L1609](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1609) |
| `Overlay.NotifyBankActivity` | [L1686](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1686) |
| `Overlay.EnsureHooks` | [L1705](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1705) |
| `Overlay.RegisterSlotDecorator` | [L1858](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1858) |
| `Overlay.InvalidateSlotDecorators` | [L1866](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1866) |
| `Overlay.RepaintSlotDecorators` | [L1879](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1879) |
| `Overlay.RefreshProtectionContext` | [L1894](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1894) |

### Inventory/Restock/Junk/FluxSellJunk.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `FV.FormatVendorMoney` | [L21](../../Inventory/Restock/Junk/FluxSellJunk.lua#L21) |
| `SJ.RunBatch` | [L133](../../Inventory/Restock/Junk/FluxSellJunk.lua#L133) |
| `SJ.HasRemaining` | [L254](../../Inventory/Restock/Junk/FluxSellJunk.lua#L254) |
| `SJ.Start` | [L351](../../Inventory/Restock/Junk/FluxSellJunk.lua#L351) |
| `SJ.ContinueIfNeeded` | [L415](../../Inventory/Restock/Junk/FluxSellJunk.lua#L415) |
| `SJ.IsSelling` | [L477](../../Inventory/Restock/Junk/FluxSellJunk.lua#L477) |
| `SJ.OnMerchantBusy` | [L483](../../Inventory/Restock/Junk/FluxSellJunk.lua#L483) |
| `SJ.OnMerchantClosed` | [L492](../../Inventory/Restock/Junk/FluxSellJunk.lua#L492) |
| `SJ.TryRepair` | [L516](../../Inventory/Restock/Junk/FluxSellJunk.lua#L516) |
| `FV.IsJunkSellActive` | [L568](../../Inventory/Restock/Junk/FluxSellJunk.lua#L568) |
| `FV.TrySellJunkItems` | [L572](../../Inventory/Restock/Junk/FluxSellJunk.lua#L572) |
| `FV.TrySellUpgradeInferiorItems` | [L576](../../Inventory/Restock/Junk/FluxSellJunk.lua#L576) |
| `FV.ContinueJunkSellIfNeeded` | [L588](../../Inventory/Restock/Junk/FluxSellJunk.lua#L588) |
| `FV.OnJunkSellBusy` | [L592](../../Inventory/Restock/Junk/FluxSellJunk.lua#L592) |
| `FV.SellGrayManual` | [L596](../../Inventory/Restock/Junk/FluxSellJunk.lua#L596) |
| `FV.TriggerAutoSellGray` | [L601](../../Inventory/Restock/Junk/FluxSellJunk.lua#L601) |
| `FV.CountSellableJunkItems` | [L609](../../Inventory/Restock/Junk/FluxSellJunk.lua#L609) |
| `FV.ShouldShowGuildRepairPriorityOption` | [L616](../../Inventory/Restock/Junk/FluxSellJunk.lua#L616) |
| `FV.RepairManual` | [L620](../../Inventory/Restock/Junk/FluxSellJunk.lua#L620) |
| `FV.TriggerAutoRepair` | [L629](../../Inventory/Restock/Junk/FluxSellJunk.lua#L629) |
| `FV.ReportManualRepairDelta` | [L640](../../Inventory/Restock/Junk/FluxSellJunk.lua#L640) |

### Inventory/Restock/Junk/FluxVendorJunkPanel.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Panel:FocusItem` | [L285](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L285) |
| `Panel:NotifyListChanged` | [L329](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L329) |
| `Panel:RefreshList` | [L400](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L400) |
| `Panel:SetSubTab` | [L404](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L404) |
| `Panel:Init` | [L704](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L704) |
| `panelFrameendmerchantTab.OnSelect` | [L727](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L727) |

### Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `M:IsEnabled` | [L60](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L60) |
| `M:IsConfirmLargeEnabled` | [L65](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L65) |
| `M:SetConfirmLargeEnabled` | [L70](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L70) |
| `M:OnLoad` | [L92](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L92) |
| `M:SlashHandler` | [L138](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L138) |
| `M:MerchantFrame_OnHide` | [L160](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L160) |
| `M:CogsFreeBagSpace` | [L167](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L167) |
| `M:MerchantItemButton_OnModifiedClick` | [L174](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L174) |
| `M:AltCurrencyHandling` | [L272](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L272) |
| `M:Show` | [L324](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L324) |
| `M:VerifyPurchase` | [L341](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L341) |
| `M:onUpdate` | [L365](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L365) |
| `M:DoPurchase` | [L383](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L383) |
| `M:AltCurrRounding` | [L411](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L411) |
| `M:UpdateDisplay` | [L432](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L432) |
| `M:DoConfirmation` | [L487](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L487) |
| `M:SetStackClick` | [L492](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L492) |
| `M:DeStackClick` | [L497](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L497) |
| `M:OnClick` | [L508](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L508) |
| `M:OnChar` | [L538](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L538) |
| `M:OnKeyDown` | [L567](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L567) |
| `M:Left_Click` | [L593](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L593) |
| `M:Right_Click` | [L603](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L603) |
| `M:OnEnter` | [L635](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L635) |
| `M:CreateTooltip` | [L646](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L646) |
| `M:OnLeave` | [L660](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L660) |
| `M:OnHide` | [L664](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L664) |

### Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll_Compat.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Compat.GetPurchasableBagSpace` | [L70](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll_Compat.lua#L70) |

### Inventory/Restock/Vendor/FluxAlreadyKnown.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `f:ADDON_LOADED` | [L492](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L492) |
| `f:PLAYER_ENTERING_WORLD` | [L514](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L514) |
| `SlashCmdList.ALREADYKNOWN` | [L794](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L794) |

### Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `f:ADDON_LOADED` | [L572](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L572) |
| `SlashCmdList.ALREADYKNOWN` | [L822](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L822) |
| `_hookMerchantAK.RefreshAuctionHouse` | [L848](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L848) |

### Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `AK.GetSettings` | [L19](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L19) |
| `AK.IsStandaloneLoaded` | [L33](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L33) |
| `AK.ShouldRun` | [L37](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L37) |
| `AK.IsEnabled` | [L45](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L45) |
| `AK.IsItemKnown` | [L49](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L49) |
| `AK.ClearKnownCache` | [L57](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L57) |
| `AK.MigrateLegacySettings` | [L63](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L63) |
| `AK.NotifySettingsChanged` | [L81](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L81) |

### Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `FluxVendorAutoMerchantUI.FlushDeferredRestockDataRefresh` | [L137](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L137) |
| `FluxVendorAutoMerchantUI.DeferRestockDataRefreshForOpen` | [L141](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L141) |
| `FluxVendorAutoMerchantUI.MarkRestockSettingsDirty` | [L985](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L985) |
| `FluxVendorAutoMerchantUI.IsRestockDataDirty` | [L989](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L989) |
| `FluxVendorAutoMerchantUI.MarkJunkStatsDirty` | [L993](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L993) |
| `FluxVendorAutoMerchantUI.IsJunkStatsDirty` | [L997](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L997) |
| `FluxVendorAutoMerchantUI.OnJunkListChanged` | [L1505](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1505) |
| `FluxVendorAutoMerchantUI.ScheduleJunkUIRefresh` | [L1530](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1530) |
| `FluxVendorAutoMerchantUI.HookPanelCloseButton` | [L2230](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2230) |
| `FluxVendorAutoMerchantUI.OnBuyTabHidden` | [L2297](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2297) |
| `FluxVendorAutoMerchantUI.OnBuyTabShown` | [L2303](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2303) |
| `LayoutPostDFActionCluster` | [L2400](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2400) |
| `RefreshCheapJunkSlotCount` | [L2494](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2494) |
| `FluxVendorAutoMerchantUI.GetCachedSellJunkTotal` | [L2510](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2510) |
| `FluxVendorAutoMerchantUI.GetCachedJunkSlotCount` | [L2514](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2514) |
| `FluxVendorAutoMerchantUI.MarkVendorBagPulseDone` | [L2554](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2554) |
| `FluxVendorAutoMerchantUI.IsMerchantBuyTabActive` | [L2558](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2558) |
| `ApplyNativeSellJunkButtonState` | [L2562](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2562) |
| `FluxVendorAutoMerchantUI.GetCachedRestockItems` | [L2590](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2590) |
| `FluxVendorAutoMerchantUI.ApplyClassicSellJunkButtonState` | [L2594](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2594) |
| `FluxVendorAutoMerchantUI.RefreshVendorJunkDisplay` | [L2687](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2687) |
| `FluxVendorAutoMerchantUI.UpdateMerchantUI` | [L2779](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2779) |
| `FluxVendorAutoMerchantUI.NeedsMerchantUIDataRefresh` | [L2853](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2853) |
| `FluxVendorAutoMerchantUI.IsMerchantUIInitialized` | [L2995](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2995) |
| `FluxVendorAutoMerchantUI.PrewarmForVendorOpen` | [L2999](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2999) |
| `FluxVendorAutoMerchantUI.WarmJunkDisplayCacheIfNeeded` | [L3007](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3007) |
| `FluxVendorAutoMerchantUI.RunPipelineLayoutLight` | [L3066](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3066) |
| `FluxVendorAutoMerchantUI.RunIdleOpenLayout` | [L3098](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3098) |
| `FluxVendorAutoMerchantUI.RunPipelineLayoutStep` | [L3145](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3145) |
| `FluxVendorAutoMerchantUI.OnVendorOpenStormSettled` | [L3215](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3215) |
| `FluxVendorAutoMerchantUI.RunPipelineLayout` | [L3234](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3234) |
| `FluxVendorAutoMerchantUI.ApplyRestockPortraitIcon` | [L3320](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3320) |
| `FluxVendorAutoMerchantUI.ApplyJunkPortraitIcon` | [L3330](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3330) |
| `FluxVendorAutoMerchantUI.CreateRestockStyleButton` | [L3383](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3383) |
| `FluxVendorAutoMerchantUI.SetRestockButtonEnabled` | [L3389](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3389) |
| `FluxVendorAutoMerchantUI.ApplyRestockAutoToggleChrome` | [L3393](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3393) |
| `FluxVendorAutoMerchantUI.CreateRestockAutoToggle` | [L3397](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3397) |

### Inventory/Restock/Vendor/FluxVendorBuy.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `FV.AddBatchCopper` | [L108](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L108) |
| `Buy.MaybeRunAutoVendorBatch` | [L670](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L670) |
| `FV.GetMerchantIndexGeneration` | [L804](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L804) |
| `FV.GetMerchantItemIndex` | [L808](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L808) |
| `FV.IsMerchantIndexBuildPending` | [L828](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L828) |
| `FV.InvalidateMerchantIndex` | [L832](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L832) |
| `FV.RegisterMerchantIndexListener` | [L838](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L838) |
| `FV.ComputeRestockPurchaseQty` | [L1006](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1006) |
| `Buy.OnIndexReady` | [L1245](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1245) |
| `FV.IsRestockBuyActive` | [L1265](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1265) |
| `FV.IsVendorBurstActive` | [L1269](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1269) |
| `FV.DoRestockManual` | [L1312](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1312) |
| `FV.TriggerAutoRestock` | [L1403](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1403) |
| `FV.RunAutoVendorBatch` | [L1452](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1452) |

### Inventory/Restock/Vendor/FluxVendorItemDisplay.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `FVID.IsPostDragonflight` | [L15](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L15) |
| `FVID.GetItemFields` | [L24](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L24) |
| `FVID.GetQualityRGB` | [L74](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L74) |
| `FVID.GetDisplayText` | [L100](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L100) |
| `FVID.ApplyNameFontString` | [L124](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L124) |
| `FVID.ShowTooltip` | [L131](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L131) |
| `FVID.IsPreDragonflight` | [L157](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L157) |
| `FVID.ApplyPreDFMerchantSecureTabLayers` | [L161](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L161) |
| `FVID.GetJunkSubTabLayout` | [L195](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L195) |

### Inventory/Restock/Vendor/FluxVendorRepairUI.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `R.Register` | [L18](../../Inventory/Restock/Vendor/FluxVendorRepairUI.lua#L18) |
| `R.NormalizeButton` | [L54](../../Inventory/Restock/Vendor/FluxVendorRepairUI.lua#L54) |
| `R.NeedsLayout` | [L85](../../Inventory/Restock/Vendor/FluxVendorRepairUI.lua#L85) |
| `R.EnsureTogglesReady` | [L106](../../Inventory/Restock/Vendor/FluxVendorRepairUI.lua#L106) |
| `R.UpdateToggles` | [L158](../../Inventory/Restock/Vendor/FluxVendorRepairUI.lua#L158) |
| `R.EnsureClusterReady` | [L192](../../Inventory/Restock/Vendor/FluxVendorRepairUI.lua#L192) |
| `R.CancelRetry` | [L224](../../Inventory/Restock/Vendor/FluxVendorRepairUI.lua#L224) |
| `R.ScheduleRetry` | [L238](../../Inventory/Restock/Vendor/FluxVendorRepairUI.lua#L238) |

### Inventory/Restock/Vendor/FluxVendorRestockPanel.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Panel.InvalidateListCache` | [L251](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L251) |
| `Panel.RefreshCountsOnly` | [L255](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L255) |
| `Panel:RefreshList` | [L853](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L853) |
| `Panel:OnTabSelected` | [L922](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L922) |
| `Panel:Init` | [L1196](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1196) |
| `panelFrameendmerchantTab.OnSelect` | [L1220](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1220) |

### Inventory/SpellReagents.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Spells.IsBlacklistedReagent` | [L174](../../Inventory/SpellReagents.lua#L174) |
| `Spells.ScheduleReagentWarm` | [L735](../../Inventory/SpellReagents.lua#L735) |
| `Spells.ScheduleWarm` | [L756](../../Inventory/SpellReagents.lua#L756) |
| `Spells.Invalidate` | [L770](../../Inventory/SpellReagents.lua#L770) |
| `Spells.Refresh` | [L778](../../Inventory/SpellReagents.lua#L778) |
| `Spells.AreReagentsWarmed` | [L791](../../Inventory/SpellReagents.lua#L791) |
| `Spells.OnVisibleItemsChanged` | [L795](../../Inventory/SpellReagents.lua#L795) |
| `Spells.UsesReagents` | [L804](../../Inventory/SpellReagents.lua#L804) |
| `Spells.GetReagents` | [L814](../../Inventory/SpellReagents.lua#L814) |
| `Spells.GetReagentItemIDs` | [L820](../../Inventory/SpellReagents.lua#L820) |
| `Spells.GetReagentItemIDSet` | [L832](../../Inventory/SpellReagents.lua#L832) |
| `Spells.IsReagentItem` | [L844](../../Inventory/SpellReagents.lua#L844) |
| `Spells.GetSpellsUsingReagent` | [L874](../../Inventory/SpellReagents.lua#L874) |
| `Spells.GetSpellsUsingReagentLabeled` | [L898](../../Inventory/SpellReagents.lua#L898) |

### Inventory/Store.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Store.UsesSyndicator` | [L34](../../Inventory/Store.lua#L34) |
| `Store.SetUsesSyndicator` | [L38](../../Inventory/Store.lua#L38) |
| `Store.GetDB` | [L94](../../Inventory/Store.lua#L94) |
| `Store.GetCharacterFullName` | [L101](../../Inventory/Store.lua#L101) |
| `Store.NormalizeRecipient` | [L136](../../Inventory/Store.lua#L136) |
| `Store.GetCurrentCharacterName` | [L162](../../Inventory/Store.lua#L162) |
| `Store.GetCharacter` | [L172](../../Inventory/Store.lua#L172) |
| `Store.GetAllCharacters` | [L187](../../Inventory/Store.lua#L187) |
| `Store.HasCharacter` | [L203](../../Inventory/Store.lua#L203) |
| `Store.GetGuild` | [L207](../../Inventory/Store.lua#L207) |
| `Store.GetAllGuilds` | [L221](../../Inventory/Store.lua#L221) |
| `Store.GetCurrentGuildName` | [L236](../../Inventory/Store.lua#L236) |
| `Store.GetWarband` | [L248](../../Inventory/Store.lua#L248) |
| `Store.GetCurrentCharacter` | [L278](../../Inventory/Store.lua#L278) |
| `Store.EnsureCurrentCharacter` | [L286](../../Inventory/Store.lua#L286) |
| `Store.EnsureGuild` | [L332](../../Inventory/Store.lua#L332) |
| `Store.SetCurrentGuild` | [L359](../../Inventory/Store.lua#L359) |
| `Store.BindLive` | [L367](../../Inventory/Store.lua#L367) |
| `Store.BindWarbandBank` | [L378](../../Inventory/Store.lua#L378) |
| `Store.MarkPending` | [L388](../../Inventory/Store.lua#L388) |
| `Store.MarkGuildPending` | [L405](../../Inventory/Store.lua#L405) |
| `Store.MarkWarbandPending` | [L412](../../Inventory/Store.lua#L412) |
| `Store.TakeCharacterPending` | [L423](../../Inventory/Store.lua#L423) |
| `Store.TakeGuildPending` | [L437](../../Inventory/Store.lua#L437) |
| `Store.TakeWarbandPending` | [L451](../../Inventory/Store.lua#L451) |
| `Store.PendingBags` | [L465](../../Inventory/Store.lua#L465) |
| `Store.PendingAll` | [L469](../../Inventory/Store.lua#L469) |
| `Store.SetCurrentMoney` | [L473](../../Inventory/Store.lua#L473) |
| `Store.SetWarbandMoney` | [L492](../../Inventory/Store.lua#L492) |
| `Store.SetGoldHidden` | [L508](../../Inventory/Store.lua#L508) |
| `Store.GetConnectedRealms` | [L516](../../Inventory/Store.lua#L516) |
| `Store.GetItemKey` | [L538](../../Inventory/Store.lua#L538) |
| `Store.GetItemKeyByItemID` | [L556](../../Inventory/Store.lua#L556) |
| `Store.ImportGoldLedgerStubs` | [L564](../../Inventory/Store.lua#L564) |
| `Store.IsGoldDeleted` | [L632](../../Inventory/Store.lua#L632) |
| `Store.HydrateSnapshots` | [L691](../../Inventory/Store.lua#L691) |

### Inventory/Summaries.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Summaries.GetTooltipInfo` | [L187](../../Inventory/Summaries.lua#L187) |
| `Summaries.GetTooltipInfoByItemID` | [L267](../../Inventory/Summaries.lua#L267) |
| `Summaries.GetTooltipInfoByLink` | [L279](../../Inventory/Summaries.lua#L279) |

### Inventory/Syndicator/Adapter.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Adapter.RebuildBags` | [L147](../../Inventory/Syndicator/Adapter.lua#L147) |
| `Adapter.RebuildBank` | [L196](../../Inventory/Syndicator/Adapter.lua#L196) |
| `Adapter.GetLastBagsChangeKind` | [L244](../../Inventory/Syndicator/Adapter.lua#L244) |
| `Adapter.GetLastBagsAddedItemIDs` | [L248](../../Inventory/Syndicator/Adapter.lua#L248) |
| `Adapter.GetLastBagsRemovedItemIDs` | [L252](../../Inventory/Syndicator/Adapter.lua#L252) |
| `Adapter.GetLastBagsDirtyBags` | [L256](../../Inventory/Syndicator/Adapter.lua#L256) |
| `Adapter.GetLastBankChangeKind` | [L260](../../Inventory/Syndicator/Adapter.lua#L260) |
| `Adapter.GetLastBankAddedItemIDs` | [L264](../../Inventory/Syndicator/Adapter.lua#L264) |
| `Adapter.GetLastBankRemovedItemIDs` | [L268](../../Inventory/Syndicator/Adapter.lua#L268) |
| `Adapter.GetLastBankDirtyBags` | [L272](../../Inventory/Syndicator/Adapter.lua#L272) |
| `Adapter.TakeBagsItemSets` | [L276](../../Inventory/Syndicator/Adapter.lua#L276) |
| `Adapter.TakeBankItemSets` | [L280](../../Inventory/Syndicator/Adapter.lua#L280) |
| `Adapter.RebuildWarband` | [L284](../../Inventory/Syndicator/Adapter.lua#L284) |
| `Adapter.RebuildEquip` | [L309](../../Inventory/Syndicator/Adapter.lua#L309) |
| `Adapter.RebuildMail` | [L379](../../Inventory/Syndicator/Adapter.lua#L379) |
| `Adapter.RebuildVoid` | [L391](../../Inventory/Syndicator/Adapter.lua#L391) |
| `Adapter.RebuildAuctions` | [L409](../../Inventory/Syndicator/Adapter.lua#L409) |
| `Adapter.RebuildGuild` | [L414](../../Inventory/Syndicator/Adapter.lua#L414) |
| `Adapter.RebuildCurrencies` | [L436](../../Inventory/Syndicator/Adapter.lua#L436) |
| `Adapter.RebuildWarbandCurrency` | [L461](../../Inventory/Syndicator/Adapter.lua#L461) |
| `Adapter.RebuildAll` | [L472](../../Inventory/Syndicator/Adapter.lua#L472) |
| `Adapter.Start` | [L655](../../Inventory/Syndicator/Adapter.lua#L655) |

### Inventory/Tooltip.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Inv.GetAwarenessOptions` | [L29](../../Inventory/Tooltip.lua#L29) |
| `Tooltip.IsDelegated` | [L66](../../Inventory/Tooltip.lua#L66) |
| `Tooltip.Start` | [L441](../../Inventory/Tooltip.lua#L441) |

### Layout/UnifiedBorder.lua

Owner: [06-layout.md](../06-layout.md).

| Declaration | Source |
|---|---|
| `UnifiedBorder.GamepadStripFrames` | [L171](../../Layout/UnifiedBorder.lua#L171) |
| `UnifiedBorder.GetActionGridBorderTop` | [L967](../../Layout/UnifiedBorder.lua#L967) |
| `UnifiedBorder.RefreshGapAppearance` | [L984](../../Layout/UnifiedBorder.lua#L984) |

### MicroMenu/FluxAddonMicroButton.lua

Owner: [17-micromenu.md](../17-micromenu.md).

| Declaration | Source |
|---|---|
| `FluxAddonSystem.GetMinimapScanRoots` | [L192](../../MicroMenu/FluxAddonMicroButton.lua#L192) |
| `FluxAddonSystem:Scan` | [L289](../../MicroMenu/FluxAddonMicroButton.lua#L289) |
| `FluxAddonSystem:UpdateLayout` | [L353](../../MicroMenu/FluxAddonMicroButton.lua#L353) |
| `FluxAddonSystem.ClampPopupToScreenAndMicroMenu` | [L455](../../MicroMenu/FluxAddonMicroButton.lua#L455) |
| `FluxAddonSystem:ClampContainerToScreen` | [L529](../../MicroMenu/FluxAddonMicroButton.lua#L529) |
| `FluxAddonPopup_RefreshAccent` | [L649](../../MicroMenu/FluxAddonMicroButton.lua#L649) |

### MicroMenu/FluxBagMicroButton.lua

Owner: [17-micromenu.md](../17-micromenu.md).

| Declaration | Source |
|---|---|
| `bagSlotsWindow:Layout` | [L419](../../MicroMenu/FluxBagMicroButton.lua#L419) |

### MicroMenu/FluxCombinedBagHeader.lua

Owner: [17-micromenu.md](../17-micromenu.md).

| Declaration | Source |
|---|---|
| `header:Layout` | [L552](../../MicroMenu/FluxCombinedBagHeader.lua#L552) |
| `endend_G.FluxRefreshInBagSlots` | [L971](../../MicroMenu/FluxCombinedBagHeader.lua#L971) |

### MicroMenu/FluxLFGMicroButton.lua

Owner: [17-micromenu.md](../17-micromenu.md).

| Declaration | Source |
|---|---|
| `_G.ToggleGroupFinderFrame_G.ToggleGroupFinderFrame` | [L133](../../MicroMenu/FluxLFGMicroButton.lua#L133) |

### MicroMenu/FluxMicroMenu.lua

Owner: [17-micromenu.md](../17-micromenu.md).

| Declaration | Source |
|---|---|
| `FluxMicroMenu:ApplyCustomMicroMouseover` | [L250](../../MicroMenu/FluxMicroMenu.lua#L250) |
| `_G.FluxApplyCustomMicroMouseover` | [L258](../../MicroMenu/FluxMicroMenu.lua#L258) |
| `_G.FluxShowCharacterPortraitGlow` | [L289](../../MicroMenu/FluxMicroMenu.lua#L289) |
| `_G.FluxHideCharacterPortraitGlow` | [L293](../../MicroMenu/FluxMicroMenu.lua#L293) |
| `FluxMicroMenu:ApplyCharacterPortraitMouseover` | [L354](../../MicroMenu/FluxMicroMenu.lua#L354) |
| `_G.FluxApplyCharacterPortraitMouseover` | [L358](../../MicroMenu/FluxMicroMenu.lua#L358) |
| `FluxMicroMenu:CreateMicroButton` | [L465](../../MicroMenu/FluxMicroMenu.lua#L465) |
| `FluxMicroMenu:CreateConfigPreviewMicroButton` | [L684](../../MicroMenu/FluxMicroMenu.lua#L684) |
| `FluxMicroMenu:ShouldLeaveBlizzardButtonShown` | [L857](../../MicroMenu/FluxMicroMenu.lua#L857) |
| `FluxMicroMenu:InvalidateDiscoverCache` | [L974](../../MicroMenu/FluxMicroMenu.lua#L974) |
| `FluxMicroMenu:GetDiscoveredMicroButtonNames` | [L1026](../../MicroMenu/FluxMicroMenu.lua#L1026) |
| `FluxMicroMenu:HasBlizzardGroupFinderMicroButton` | [L1050](../../MicroMenu/FluxMicroMenu.lua#L1050) |
| `FluxMicroMenu:IsNativeRowAvailableOnClient` | [L1081](../../MicroMenu/FluxMicroMenu.lua#L1081) |
| `FluxMicroMenu:GetDefaultUnifiedRowIds` | [L1118](../../MicroMenu/FluxMicroMenu.lua#L1118) |
| `FluxMicroMenu:GetLayoutSpacing` | [L1182](../../MicroMenu/FluxMicroMenu.lua#L1182) |
| `FluxMicroMenu:GetButtonSizeScale` | [L1201](../../MicroMenu/FluxMicroMenu.lua#L1201) |
| `_G.FluxMicroMenu_GetBesideChatColumnRightX` | [L1447](../../MicroMenu/FluxMicroMenu.lua#L1447) |
| `FluxMicroMenu:RefreshLayout` | [L2609](../../MicroMenu/FluxMicroMenu.lua#L2609) |
| `FluxMicroMenu:Rebuild` | [L2950](../../MicroMenu/FluxMicroMenu.lua#L2950) |

### MicroMenu/FluxMicroMenuConfig.lua

Owner: [17-micromenu.md](../17-micromenu.md).

| Declaration | Source |
|---|---|
| `C:RegisterCallback` | [L52](../../MicroMenu/FluxMicroMenuConfig.lua#L52) |
| `C:IsMinimapRowId` | [L68](../../MicroMenu/FluxMicroMenuConfig.lua#L68) |
| `C:GetMinimapSourceName` | [L72](../../MicroMenu/FluxMicroMenuConfig.lua#L72) |
| `C:MakeMinimapRowId` | [L77](../../MicroMenu/FluxMicroMenuConfig.lua#L77) |
| `C:GetMinimapMicroGlobalName` | [L81](../../MicroMenu/FluxMicroMenuConfig.lua#L81) |
| `C:IsTradeSkillRowId` | [L86](../../MicroMenu/FluxMicroMenuConfig.lua#L86) |
| `C:GetTradeSkillKey` | [L90](../../MicroMenu/FluxMicroMenuConfig.lua#L90) |
| `C:MakeTradeSkillRowId` | [L95](../../MicroMenu/FluxMicroMenuConfig.lua#L95) |
| `C:GetTradeSkillMicroGlobalName` | [L99](../../MicroMenu/FluxMicroMenuConfig.lua#L99) |
| `C:IsTradeSkillFlyoutRowId` | [L107](../../MicroMenu/FluxMicroMenuConfig.lua#L107) |
| `C:IsTradeSkillRelatedRowId` | [L111](../../MicroMenu/FluxMicroMenuConfig.lua#L111) |
| `C:MigrateTradeSkillNativeToCharacter` | [L116](../../MicroMenu/FluxMicroMenuConfig.lua#L116) |
| `C:EnsureTradeSkillCharacterEnabled` | [L138](../../MicroMenu/FluxMicroMenuConfig.lua#L138) |
| `C:InsertDefaultRowAtCanonicalPosition` | [L152](../../MicroMenu/FluxMicroMenuConfig.lua#L152) |
| `C:InsertRowBeforeAddonMicro` | [L195](../../MicroMenu/FluxMicroMenuConfig.lua#L195) |
| `C:UnifiedRowIdFromGlobalMicroName` | [L225](../../MicroMenu/FluxMicroMenuConfig.lua#L225) |
| `C:ConsolidateMinimapMicroDuplicates` | [L247](../../MicroMenu/FluxMicroMenuConfig.lua#L247) |
| `C:IsNativeAccountEnabled` | [L286](../../MicroMenu/FluxMicroMenuConfig.lua#L286) |
| `C:IsNativeCharacterEnabled` | [L291](../../MicroMenu/FluxMicroMenuConfig.lua#L291) |
| `C:GetNativeMode` | [L296](../../MicroMenu/FluxMicroMenuConfig.lua#L296) |
| `C:GetNativeButtonOrder` | [L313](../../MicroMenu/FluxMicroMenuConfig.lua#L313) |
| `C:SetNativeButtonOrder` | [L323](../../MicroMenu/FluxMicroMenuConfig.lua#L323) |
| `C:EnableNativeForAccount` | [L332](../../MicroMenu/FluxMicroMenuConfig.lua#L332) |
| `C:DisableNativeForAccount` | [L342](../../MicroMenu/FluxMicroMenuConfig.lua#L342) |
| `C:EnableNativeForCharacter` | [L347](../../MicroMenu/FluxMicroMenuConfig.lua#L347) |
| `C:DisableNativeForCharacter` | [L357](../../MicroMenu/FluxMicroMenuConfig.lua#L357) |
| `C:GetNextNativeOrder` | [L362](../../MicroMenu/FluxMicroMenuConfig.lua#L362) |
| `C:CycleNativeMode` | [L378](../../MicroMenu/FluxMicroMenuConfig.lua#L378) |
| `C:NotifyListenersOnly` | [L405](../../MicroMenu/FluxMicroMenuConfig.lua#L405) |
| `C:CopyUnifiedOrderForScopeToggle` | [L437](../../MicroMenu/FluxMicroMenuConfig.lua#L437) |
| `C:GetUnifiedOrderList` | [L469](../../MicroMenu/FluxMicroMenuConfig.lua#L469) |
| `C:SetUnifiedOrderList` | [L477](../../MicroMenu/FluxMicroMenuConfig.lua#L477) |
| `C:NormalizeUnifiedOrderList` | [L483](../../MicroMenu/FluxMicroMenuConfig.lua#L483) |
| `C:PruneQueueStatusFromUnifiedOrder` | [L503](../../MicroMenu/FluxMicroMenuConfig.lua#L503) |
| `C:MigrateLegacyUnifiedRowIds` | [L525](../../MicroMenu/FluxMicroMenuConfig.lua#L525) |
| `C:PruneUnavailableNativeRows` | [L564](../../MicroMenu/FluxMicroMenuConfig.lua#L564) |
| `C:EnsureUnifiedDefaults` | [L680](../../MicroMenu/FluxMicroMenuConfig.lua#L680) |
| `C:MergeNewDiscoveriesIntoUnifiedOrder` | [L713](../../MicroMenu/FluxMicroMenuConfig.lua#L713) |
| `C:MergeNewDiscoveriesIntoUnifiedOrderUnlocked` | [L728](../../MicroMenu/FluxMicroMenuConfig.lua#L728) |
| `C:UpdateUnifiedOrderAfterNativeChange` | [L804](../../MicroMenu/FluxMicroMenuConfig.lua#L804) |
| `C:ShouldShowNativeOnBar` | [L812](../../MicroMenu/FluxMicroMenuConfig.lua#L812) |
| `C:ResolveRowToButtonFrame` | [L816](../../MicroMenu/FluxMicroMenuConfig.lua#L816) |
| `C:BuildOrderedMicroButtons` | [L873](../../MicroMenu/FluxMicroMenuConfig.lua#L873) |
| `C:ShouldIncludeDiscoveredButton` | [L906](../../MicroMenu/FluxMicroMenuConfig.lua#L906) |
| `C:ParkHiddenButtons` | [L946](../../MicroMenu/FluxMicroMenuConfig.lua#L946) |
| `C:NotifyChanged` | [L995](../../MicroMenu/FluxMicroMenuConfig.lua#L995) |
| `C:NotifyLayoutOnly` | [L999](../../MicroMenu/FluxMicroMenuConfig.lua#L999) |
| `C:GetEffectiveRows` | [L1007](../../MicroMenu/FluxMicroMenuConfig.lua#L1007) |
| `C:CycleRowMode` | [L1081](../../MicroMenu/FluxMicroMenuConfig.lua#L1081) |
| `C:ReorderUnifiedRows` | [L1094](../../MicroMenu/FluxMicroMenuConfig.lua#L1094) |
| `C:ReorderUnifiedRowById` | [L1127](../../MicroMenu/FluxMicroMenuConfig.lua#L1127) |
| `C:ReorderUnifiedRowAfter` | [L1149](../../MicroMenu/FluxMicroMenuConfig.lua#L1149) |
| `C:SwapUnifiedRows` | [L1170](../../MicroMenu/FluxMicroMenuConfig.lua#L1170) |
| `C:ResetUnifiedOrderToDefault` | [L1218](../../MicroMenu/FluxMicroMenuConfig.lua#L1218) |
| `C:ResetMicroMenuToFactoryDefaults` | [L1228](../../MicroMenu/FluxMicroMenuConfig.lua#L1228) |

### MicroMenu/FluxMicroMenuConfigUI.lua

Owner: [17-micromenu.md](../17-micromenu.md).

| Declaration | Source |
|---|---|
| `UI:IsAceEmbedParent` | [L274](../../MicroMenu/FluxMicroMenuConfigUI.lua#L274) |
| `UI:EnsureScrollInternal` | [L279](../../MicroMenu/FluxMicroMenuConfigUI.lua#L279) |
| `UI:EnsureContentContainer` | [L322](../../MicroMenu/FluxMicroMenuConfigUI.lua#L322) |
| `UI:EnsureEmbedResetButtons` | [L351](../../MicroMenu/FluxMicroMenuConfigUI.lua#L351) |
| `UI:EnsureFloatingFrame` | [L386](../../MicroMenu/FluxMicroMenuConfigUI.lua#L386) |
| `UI:AttachToAceWidget` | [L542](../../MicroMenu/FluxMicroMenuConfigUI.lua#L542) |
| `UI:DetachFromAceWidget` | [L564](../../MicroMenu/FluxMicroMenuConfigUI.lua#L564) |
| `UI:ShowStandalone` | [L602](../../MicroMenu/FluxMicroMenuConfigUI.lua#L602) |
| `UI:HideStandalone` | [L626](../../MicroMenu/FluxMicroMenuConfigUI.lua#L626) |
| `UI:ToggleStandalone` | [L656](../../MicroMenu/FluxMicroMenuConfigUI.lua#L656) |
| `UI:RefreshAllModeLabels` | [L1014](../../MicroMenu/FluxMicroMenuConfigUI.lua#L1014) |
| `UI:ScheduleModeLabelRefresh` | [L1022](../../MicroMenu/FluxMicroMenuConfigUI.lua#L1022) |
| `UI:CreateSlot` | [L1051](../../MicroMenu/FluxMicroMenuConfigUI.lua#L1051) |
| `UI:ComputeDropIndexFromCursor` | [L1215](../../MicroMenu/FluxMicroMenuConfigUI.lua#L1215) |
| `UI:HandleDragDropHorizontal` | [L1298](../../MicroMenu/FluxMicroMenuConfigUI.lua#L1298) |
| `UI:RefreshRows` | [L1356](../../MicroMenu/FluxMicroMenuConfigUI.lua#L1356) |

### MicroMenu/FluxMinimapToMicro.lua

Owner: [17-micromenu.md](../17-micromenu.md).

| Declaration | Source |
|---|---|
| `M:WipeAllButtonSavedState` | [L66](../../MicroMenu/FluxMinimapToMicro.lua#L66) |
| `M:IsAccountEnabled` | [L74](../../MicroMenu/FluxMinimapToMicro.lua#L74) |
| `M:IsCharacterEnabled` | [L80](../../MicroMenu/FluxMinimapToMicro.lua#L80) |
| `M:IsEnabled` | [L86](../../MicroMenu/FluxMinimapToMicro.lua#L86) |
| `M:GetMode` | [L91](../../MicroMenu/FluxMinimapToMicro.lua#L91) |
| `M:EnableForAccount` | [L101](../../MicroMenu/FluxMinimapToMicro.lua#L101) |
| `M:DisableForAccount` | [L143](../../MicroMenu/FluxMinimapToMicro.lua#L143) |
| `M:EnableForCharacter` | [L150](../../MicroMenu/FluxMinimapToMicro.lua#L150) |
| `M:DisableForCharacter` | [L192](../../MicroMenu/FluxMinimapToMicro.lua#L192) |
| `M:GetNextOrder` | [L199](../../MicroMenu/FluxMinimapToMicro.lua#L199) |
| `M:GetNaturalPosition` | [L218](../../MicroMenu/FluxMinimapToMicro.lua#L218) |
| `M:UpdateOrderList` | [L236](../../MicroMenu/FluxMinimapToMicro.lua#L236) |
| `M:GetEnabledButtonsOrdered` | [L269](../../MicroMenu/FluxMinimapToMicro.lua#L269) |
| `M:SetButtonOrder` | [L276](../../MicroMenu/FluxMinimapToMicro.lua#L276) |
| `M:GetButtonOrder` | [L289](../../MicroMenu/FluxMinimapToMicro.lua#L289) |
| `M:CycleMode` | [L300](../../MicroMenu/FluxMinimapToMicro.lua#L300) |
| `M:GetFriendlyMinimapButtonName` | [L399](../../MicroMenu/FluxMinimapToMicro.lua#L399) |
| `M:HarvestNamedMinimapButtons` | [L498](../../MicroMenu/FluxMinimapToMicro.lua#L498) |
| `M:ScanButtons` | [L574](../../MicroMenu/FluxMinimapToMicro.lua#L574) |
| `M:IsMinimapButtonPresent` | [L599](../../MicroMenu/FluxMinimapToMicro.lua#L599) |
| `M:GetButtonIcon` | [L632](../../MicroMenu/FluxMinimapToMicro.lua#L632) |
| `M:GetButtonIconTexture` | [L663](../../MicroMenu/FluxMinimapToMicro.lua#L663) |
| `M:UpdateMicroButtonIconFromMinimap` | [L688](../../MicroMenu/FluxMinimapToMicro.lua#L688) |
| `M:CreateConfigPopup` | [L709](../../MicroMenu/FluxMinimapToMicro.lua#L709) |
| `M:ShowConfigPopup` | [L772](../../MicroMenu/FluxMinimapToMicro.lua#L772) |
| `M:HideConfigPopup` | [L789](../../MicroMenu/FluxMinimapToMicro.lua#L789) |
| `M:CreateConfigButton` | [L800](../../MicroMenu/FluxMinimapToMicro.lua#L800) |
| `M:ApplyModeTint` | [L891](../../MicroMenu/FluxMinimapToMicro.lua#L891) |
| `M:UpdateConfigPopupTints` | [L905](../../MicroMenu/FluxMinimapToMicro.lua#L905) |
| `M:HandleDragDrop` | [L917](../../MicroMenu/FluxMinimapToMicro.lua#L917) |
| `M:ReorderButtons` | [L975](../../MicroMenu/FluxMinimapToMicro.lua#L975) |
| `M:RefreshConfigPopupLayout` | [L1048](../../MicroMenu/FluxMinimapToMicro.lua#L1048) |
| `M:RebuildMicroButtons` | [L1069](../../MicroMenu/FluxMinimapToMicro.lua#L1069) |
| `M:CreateMicroButtonForMinimap` | [L1168](../../MicroMenu/FluxMinimapToMicro.lua#L1168) |
| `falseGameTooltip.Show` | [L1365](../../MicroMenu/FluxMinimapToMicro.lua#L1365) |
| `M:ShouldHideFromLeftPopup` | [L1591](../../MicroMenu/FluxMinimapToMicro.lua#L1591) |
| `M:GetEnabledButtonNames` | [L1596](../../MicroMenu/FluxMinimapToMicro.lua#L1596) |
| `FluxMinimapToMicro_RefreshPopupAccent` | [L1702](../../MicroMenu/FluxMinimapToMicro.lua#L1702) |

### MicroMenu/FluxTradeSkillMicro.lua

Owner: [17-micromenu.md](../17-micromenu.md).

| Declaration | Source |
|---|---|
| `M:GetDB` | [L90](../../MicroMenu/FluxTradeSkillMicro.lua#L90) |
| `M:IsEnabled` | [L95](../../MicroMenu/FluxTradeSkillMicro.lua#L95) |
| `M:EnsureRowVisible` | [L101](../../MicroMenu/FluxTradeSkillMicro.lua#L101) |
| `M:BootstrapVisibilityIfNeeded` | [L108](../../MicroMenu/FluxTradeSkillMicro.lua#L108) |
| `M:MakeKey` | [L137](../../MicroMenu/FluxTradeSkillMicro.lua#L137) |
| `M:SafeGlobalKey` | [L155](../../MicroMenu/FluxTradeSkillMicro.lua#L155) |
| `M:GetIndividualGlobalName` | [L159](../../MicroMenu/FluxTradeSkillMicro.lua#L159) |
| `M:GetFlyoutGlobalName` | [L163](../../MicroMenu/FluxTradeSkillMicro.lua#L163) |
| `M:GetSkillDisplayName` | [L167](../../MicroMenu/FluxTradeSkillMicro.lua#L167) |
| `M:IsSkillKnown` | [L181](../../MicroMenu/FluxTradeSkillMicro.lua#L181) |
| `M:ShouldKeepRowInOrder` | [L191](../../MicroMenu/FluxTradeSkillMicro.lua#L191) |
| `M:EnumerateSkills` | [L297](../../MicroMenu/FluxTradeSkillMicro.lua#L297) |
| `M:GetLearnedSkills` | [L383](../../MicroMenu/FluxTradeSkillMicro.lua#L383) |
| `M:ResolvePlacement` | [L394](../../MicroMenu/FluxTradeSkillMicro.lua#L394) |
| `M:ShouldShowFlyoutButton` | [L448](../../MicroMenu/FluxTradeSkillMicro.lua#L448) |
| `M:IsIndividualOnBar` | [L454](../../MicroMenu/FluxTradeSkillMicro.lua#L454) |
| `M:IsRowActiveOnBar` | [L464](../../MicroMenu/FluxTradeSkillMicro.lua#L464) |
| `M:GetActiveBarRowIds` | [L480](../../MicroMenu/FluxTradeSkillMicro.lua#L480) |
| `M:MigrateSavedRowKeys` | [L553](../../MicroMenu/FluxTradeSkillMicro.lua#L553) |
| `M:OpenSkill` | [L622](../../MicroMenu/FluxTradeSkillMicro.lua#L622) |
| `M:OpenSkillByKey` | [L658](../../MicroMenu/FluxTradeSkillMicro.lua#L658) |
| `M:UpdateFlyoutLayout` | [L724](../../MicroMenu/FluxTradeSkillMicro.lua#L724) |
| `M:ClampFlyoutToScreen` | [L796](../../MicroMenu/FluxTradeSkillMicro.lua#L796) |
| `M:ToggleFlyout` | [L855](../../MicroMenu/FluxTradeSkillMicro.lua#L855) |
| `M:HideFlyout` | [L887](../../MicroMenu/FluxTradeSkillMicro.lua#L887) |
| `M:EnsureIndividualButton` | [L902](../../MicroMenu/FluxTradeSkillMicro.lua#L902) |
| `M:EnsureFlyoutButton` | [L941](../../MicroMenu/FluxTradeSkillMicro.lua#L941) |
| `M:SyncButtons` | [L986](../../MicroMenu/FluxTradeSkillMicro.lua#L986) |
| `M:Refresh` | [L1034](../../MicroMenu/FluxTradeSkillMicro.lua#L1034) |

### Minimap/FluxBuffDebuffFrames.lua

Owner: [18-minimap-and-trackers.md](../18-minimap-and-trackers.md).

| Declaration | Source |
|---|---|
| `M:PositionBuffFrames` | [L27](../../Minimap/FluxBuffDebuffFrames.lua#L27) |
| `M:RefreshBlizzardAuraFrames` | [L49](../../Minimap/FluxBuffDebuffFrames.lua#L49) |
| `M:TryInstallBlizzardAuraSqueezeHooks` | [L61](../../Minimap/FluxBuffDebuffFrames.lua#L61) |
| `M:RefreshBlizzardBuffDebuffSqueeze` | [L64](../../Minimap/FluxBuffDebuffFrames.lua#L64) |
| `M:HookConsolidatedBuffs` | [L67](../../Minimap/FluxBuffDebuffFrames.lua#L67) |
| `M:InstallOnMinimap` | [L70](../../Minimap/FluxBuffDebuffFrames.lua#L70) |
| `ifnotminimapthenreturnendminimap.RefreshBlizzardAuraFrames` | [L74](../../Minimap/FluxBuffDebuffFrames.lua#L74) |
| `endminimap.TryInstallBlizzardAuraSqueezeHooks` | [L77](../../Minimap/FluxBuffDebuffFrames.lua#L77) |
| `endminimap.RefreshBlizzardBuffDebuffSqueeze` | [L80](../../Minimap/FluxBuffDebuffFrames.lua#L80) |
| `endminimap.PositionBuffFrames` | [L83](../../Minimap/FluxBuffDebuffFrames.lua#L83) |

### Minimap/FluxMinimap.lua

Owner: [18-minimap-and-trackers.md](../18-minimap-and-trackers.md).

| Declaration | Source |
|---|---|
| `FluxMinimap:Initialize` | [L294](../../Minimap/FluxMinimap.lua#L294) |
| `FluxMinimap:RunEnforcerPass` | [L303](../../Minimap/FluxMinimap.lua#L303) |
| `FluxMinimap:RequestEnforcerBurst` | [L311](../../Minimap/FluxMinimap.lua#L311) |
| `FluxMinimap:CancelEnforcerTicker` | [L319](../../Minimap/FluxMinimap.lua#L319) |
| `FluxMinimap:EnsureEnforcerTicker` | [L328](../../Minimap/FluxMinimap.lua#L328) |
| `FluxMinimap.GetEnforcerBurstRemaining` | [L355](../../Minimap/FluxMinimap.lua#L355) |
| `FluxMinimap:Initialize` | [L364](../../Minimap/FluxMinimap.lua#L364) |
| `FluxMinimap_ApplyAppearanceAccent` | [L448](../../Minimap/FluxMinimap.lua#L448) |
| `FluxMinimap:UpdateStyle` | [L468](../../Minimap/FluxMinimap.lua#L468) |
| `FluxMinimap:CleanupBlizzardFrames` | [L482](../../Minimap/FluxMinimap.lua#L482) |
| `FluxMinimap:CleanupTimeManager` | [L568](../../Minimap/FluxMinimap.lua#L568) |
| `FluxMinimap:EnforcePosition` | [L583](../../Minimap/FluxMinimap.lua#L583) |
| `FluxMinimap:PositionIndicators` | [L623](../../Minimap/FluxMinimap.lua#L623) |
| `FluxMinimap:PositionQueueStatusEye` | [L1083](../../Minimap/FluxMinimap.lua#L1083) |
| `FluxMinimap:EnsureQueueStatusEyeHooks` | [L1129](../../Minimap/FluxMinimap.lua#L1129) |
| `FluxMinimap:HookQuestWatchFramePositioning` | [L1211](../../Minimap/FluxMinimap.lua#L1211) |
| `QuestWatchFrame.SetPointQuestWatchFrame.SetPoint` | [L1246](../../Minimap/FluxMinimap.lua#L1246) |
| `WatchFrame.SetPointWatchFrame.SetPoint` | [L1268](../../Minimap/FluxMinimap.lua#L1268) |
| `FluxMinimap:UpdateQuestTrackerPosition` | [L1281](../../Minimap/FluxMinimap.lua#L1281) |
| `FluxMinimap:HandleEditMode` | [L1630](../../Minimap/FluxMinimap.lua#L1630) |
| `FluxMinimap:CreateInfoBar` | [L1774](../../Minimap/FluxMinimap.lua#L1774) |
| `FluxMinimap:ApplyInfoBarZoneTextFit` | [L1965](../../Minimap/FluxMinimap.lua#L1965) |
| `FluxMinimap:OnInfoBarZoneHitEnter` | [L2004](../../Minimap/FluxMinimap.lua#L2004) |
| `FluxMinimap:OnInfoBarZoneHitLeave` | [L2039](../../Minimap/FluxMinimap.lua#L2039) |
| `FluxMinimap:UpdateInfoBarZoneScroll` | [L2056](../../Minimap/FluxMinimap.lua#L2056) |
| `FluxMinimap:RefreshInfoBarZoneFit` | [L2106](../../Minimap/FluxMinimap.lua#L2106) |
| `FluxMinimap:UpdateInfoBarZone` | [L2110](../../Minimap/FluxMinimap.lua#L2110) |
| `FluxMinimap:UpdateInfoBarTime` | [L2147](../../Minimap/FluxMinimap.lua#L2147) |
| `FluxMinimap:EmbedInFrame` | [L2181](../../Minimap/FluxMinimap.lua#L2181) |
| `FluxMinimap:RestoreToNormal` | [L2431](../../Minimap/FluxMinimap.lua#L2431) |
| `FluxMinimap:IsEmbedded` | [L2571](../../Minimap/FluxMinimap.lua#L2571) |
| `FluxMinimap:GetNormalWidth` | [L2576](../../Minimap/FluxMinimap.lua#L2576) |
| `FluxMinimap:HideEmbedded` | [L2588](../../Minimap/FluxMinimap.lua#L2588) |
| `FluxMinimap:ShowEmbedded` | [L2613](../../Minimap/FluxMinimap.lua#L2613) |
| `FluxMinimap.NotifyInfoFrameLayoutChanged` | [L2635](../../Minimap/FluxMinimap.lua#L2635) |
| `FluxMinimap:Refresh` | [L2648](../../Minimap/FluxMinimap.lua#L2648) |

### Minimap/FluxMinimapButtons.lua

Owner: [18-minimap-and-trackers.md](../18-minimap-and-trackers.md).

| Declaration | Source |
|---|---|
| `btn.OnReceiveDragCallback` | [L172](../../Minimap/FluxMinimapButtons.lua#L172) |
| `endbtn.OnMacroRebound` | [L178](../../Minimap/FluxMinimapButtons.lua#L178) |
| `endbtn.OnDelete` | [L182](../../Minimap/FluxMinimapButtons.lua#L182) |
| `M:CreateContainer` | [L194](../../Minimap/FluxMinimapButtons.lua#L194) |
| `M:CreateButtons` | [L223](../../Minimap/FluxMinimapButtons.lua#L223) |
| `M:RefreshButtons` | [L252](../../Minimap/FluxMinimapButtons.lua#L252) |
| `M:LayoutSlots` | [L272](../../Minimap/FluxMinimapButtons.lua#L272) |
| `M:RefreshAppearanceAccent` | [L325](../../Minimap/FluxMinimapButtons.lua#L325) |
| `M:Show` | [L334](../../Minimap/FluxMinimapButtons.lua#L334) |
| `M:Hide` | [L340](../../Minimap/FluxMinimapButtons.lua#L340) |
| `M:IsShown` | [L346](../../Minimap/FluxMinimapButtons.lua#L346) |
| `M:PositionInWindow` | [L354](../../Minimap/FluxMinimapButtons.lua#L354) |
| `M:OnEmbedStateChanged` | [L385](../../Minimap/FluxMinimapButtons.lua#L385) |
| `M:Initialize` | [L399](../../Minimap/FluxMinimapButtons.lua#L399) |

### Minimap/FluxObjectiveTrackerScroll.lua

Owner: [18-minimap-and-trackers.md](../18-minimap-and-trackers.md).

| Declaration | Source |
|---|---|
| `FluxObjectiveTrackerScroll:UpdateQuestieVisibility` | [L68](../../Minimap/FluxObjectiveTrackerScroll.lua#L68) |
| `FluxObjectiveTrackerScroll.IsActiveFor` | [L184](../../Minimap/FluxObjectiveTrackerScroll.lua#L184) |
| `FluxObjectiveTrackerScroll:GetQuestTimer` | [L188](../../Minimap/FluxObjectiveTrackerScroll.lua#L188) |
| `FluxObjectiveTrackerScroll:PinTopModulePadding` | [L195](../../Minimap/FluxObjectiveTrackerScroll.lua#L195) |
| `FluxObjectiveTrackerScroll:PinLayoutHeight` | [L204](../../Minimap/FluxObjectiveTrackerScroll.lua#L204) |
| `FluxObjectiveTrackerScroll:ReassertDock` | [L251](../../Minimap/FluxObjectiveTrackerScroll.lua#L251) |
| `FluxObjectiveTrackerScroll:RecoverStuckDirty` | [L287](../../Minimap/FluxObjectiveTrackerScroll.lua#L287) |
| `FluxObjectiveTrackerScroll:CollapseModuleTopGap` | [L301](../../Minimap/FluxObjectiveTrackerScroll.lua#L301) |
| `FluxObjectiveTrackerScroll:AnchorHeader` | [L324](../../Minimap/FluxObjectiveTrackerScroll.lua#L324) |
| `mixin:ShouldDisplayQuest` | [L406](../../Minimap/FluxObjectiveTrackerScroll.lua#L406) |
| `tracker:BuildQuestWatchInfos` | [L425](../../Minimap/FluxObjectiveTrackerScroll.lua#L425) |
| `tracker:UpdateSingle` | [L461](../../Minimap/FluxObjectiveTrackerScroll.lua#L461) |
| `_G.SetQuestTitleLevelAndDifficultyColor_G.SetQuestTitleLevelAndDifficultyColor` | [L486](../../Minimap/FluxObjectiveTrackerScroll.lua#L486) |
| `ObjectiveTrackerBlockMixin:UpdateHighlight` | [L519](../../Minimap/FluxObjectiveTrackerScroll.lua#L519) |
| `FluxObjectiveTrackerScroll:DockQuestTimer` | [L533](../../Minimap/FluxObjectiveTrackerScroll.lua#L533) |
| `FluxObjectiveTrackerScroll:MeasureContentHeight` | [L652](../../Minimap/FluxObjectiveTrackerScroll.lua#L652) |
| `FluxObjectiveTrackerScroll:AnchorTrackerRightInScroll` | [L667](../../Minimap/FluxObjectiveTrackerScroll.lua#L667) |
| `FluxObjectiveTrackerScroll:SizeScrollContent` | [L684](../../Minimap/FluxObjectiveTrackerScroll.lua#L684) |
| `FluxObjectiveTrackerScroll:SettleTrackerHeight` | [L735](../../Minimap/FluxObjectiveTrackerScroll.lua#L735) |
| `FluxObjectiveTrackerScroll:EnsureVisibleBody` | [L769](../../Minimap/FluxObjectiveTrackerScroll.lua#L769) |
| `FluxObjectiveTrackerScroll:QueueFullLayout` | [L796](../../Minimap/FluxObjectiveTrackerScroll.lua#L796) |
| `FluxObjectiveTrackerScroll:LayoutScrollArea` | [L827](../../Minimap/FluxObjectiveTrackerScroll.lua#L827) |
| `FluxObjectiveTrackerScroll:_DoSyncAfterUpdate` | [L894](../../Minimap/FluxObjectiveTrackerScroll.lua#L894) |
| `FluxObjectiveTrackerScroll:SyncAfterUpdate` | [L978](../../Minimap/FluxObjectiveTrackerScroll.lua#L978) |
| `ObjectiveTrackerContainerMixin.UpdateObjectiveTrackerContainerMixin.Update` | [L1138](../../Minimap/FluxObjectiveTrackerScroll.lua#L1138) |
| `self._fluxSecureDirtyCbthencallback` | [L1142](../../Minimap/FluxObjectiveTrackerScroll.lua#L1142) |
| `FluxObjectiveTrackerScroll:StartForeverLoginPulse` | [L1272](../../Minimap/FluxObjectiveTrackerScroll.lua#L1272) |
| `FluxObjectiveTrackerScroll:InstallForeverCompat` | [L1307](../../Minimap/FluxObjectiveTrackerScroll.lua#L1307) |
| `FluxObjectiveTrackerScroll:ReadyForScrollDock` | [L1323](../../Minimap/FluxObjectiveTrackerScroll.lua#L1323) |
| `FluxObjectiveTrackerScroll:KickScrollLayoutOnce` | [L1339](../../Minimap/FluxObjectiveTrackerScroll.lua#L1339) |
| `FluxObjectiveTrackerScroll:EnsureViewport` | [L1359](../../Minimap/FluxObjectiveTrackerScroll.lua#L1359) |
| `outerViewport:ToggleCollapsed` | [L1404](../../Minimap/FluxObjectiveTrackerScroll.lua#L1404) |
| `FluxObjectiveTrackerScroll:ApplyViewportSize` | [L1474](../../Minimap/FluxObjectiveTrackerScroll.lua#L1474) |
| `FluxObjectiveTrackerScroll:RefreshLayout` | [L1495](../../Minimap/FluxObjectiveTrackerScroll.lua#L1495) |

### Minimap/FluxQuestie.lua

Owner: [18-minimap-and-trackers.md](../18-minimap-and-trackers.md).

| Declaration | Source |
|---|---|
| `FluxQuestie:IsTrackerEnabled` | [L26](../../Minimap/FluxQuestie.lua#L26) |
| `FluxQuestie:RequestLayout` | [L33](../../Minimap/FluxQuestie.lua#L33) |
| `FluxQuestie:HookHeader` | [L53](../../Minimap/FluxQuestie.lua#L53) |
| `FluxQuestie:Initialize` | [L61](../../Minimap/FluxQuestie.lua#L61) |
| `FluxQuestie:UpdateLayout` | [L108](../../Minimap/FluxQuestie.lua#L108) |
| `FluxQuestie:ReleaseQuestTimer` | [L154](../../Minimap/FluxQuestie.lua#L154) |
| `FluxQuestie:DockQuestTimer` | [L163](../../Minimap/FluxQuestie.lua#L163) |
| `FluxQuestie:UpdateScrollRange` | [L197](../../Minimap/FluxQuestie.lua#L197) |
| `FluxQuestie:StyleBaseFrame` | [L218](../../Minimap/FluxQuestie.lua#L218) |
| `FluxQuestie:SizeQuestFrame` | [L298](../../Minimap/FluxQuestie.lua#L298) |
| `FluxQuestie:StyleLines` | [L371](../../Minimap/FluxQuestie.lua#L371) |

### NamePlates/ComboPoints.lua

Owner: [19-nameplates.md](../19-nameplates.md).

| Declaration | Source |
|---|---|
| `Combo.Added` | [L126](../../NamePlates/ComboPoints.lua#L126) |
| `Combo.Removed` | [L127](../../NamePlates/ComboPoints.lua#L127) |
| `Combo.Refresh` | [L130](../../NamePlates/ComboPoints.lua#L130) |
| `Combo.RefreshAll` | [L133](../../NamePlates/ComboPoints.lua#L133) |

### NamePlates/Core.lua

Owner: [19-nameplates.md](../19-nameplates.md).

| Declaration | Source |
|---|---|
| `NP.IsClassicFamily` | [L28](../../NamePlates/Core.lua#L28) |
| `NP.IsSecretClient` | [L45](../../NamePlates/Core.lua#L45) |
| `NP.IsLiveClient` | [L54](../../NamePlates/Core.lua#L54) |
| `NP.PlateTextOffsetY` | [L63](../../NamePlates/Core.lua#L63) |
| `NP.IsThreatSupported` | [L74](../../NamePlates/Core.lua#L74) |
| `NP.IsLevelSupported` | [L78](../../NamePlates/Core.lua#L78) |
| `NP.GetDB` | [L96](../../NamePlates/Core.lua#L96) |
| `NP.IsSecret` | [L123](../../NamePlates/Core.lua#L123) |
| `NP.IsUsable` | [L140](../../NamePlates/Core.lua#L140) |
| `NP.BoolTest` | [L152](../../NamePlates/Core.lua#L152) |
| `NP.GetPlate` | [L166](../../NamePlates/Core.lua#L166) |
| `NP.GetParts` | [L181](../../NamePlates/Core.lua#L181) |
| `NP.CreateHost` | [L206](../../NamePlates/Core.lua#L206) |
| `NP.AttachHost` | [L216](../../NamePlates/Core.lua#L216) |
| `NP.ReleaseHost` | [L232](../../NamePlates/Core.lua#L232) |
| `NP.UsesClassicHealthBar` | [L241](../../NamePlates/Core.lua#L241) |
| `NP.CreateClientPlate` | [L272](../../NamePlates/Core.lua#L272) |
| `NP.FitPlate` | [L287](../../NamePlates/Core.lua#L287) |
| `NP.IsUnitTarget` | [L303](../../NamePlates/Core.lua#L303) |
| `NP.ShowPlate` | [L311](../../NamePlates/Core.lua#L311) |
| `NP.SetThreatTint` | [L335](../../NamePlates/Core.lua#L335) |
| `NP.ThreatTint` | [L346](../../NamePlates/Core.lua#L346) |
| `NP.TintPlateChrome` | [L406](../../NamePlates/Core.lua#L406) |
| `NP.ResetPlateChrome` | [L426](../../NamePlates/Core.lua#L426) |
| `NP.RegisterModule` | [L465](../../NamePlates/Core.lua#L465) |
| `NP.RefreshUnit` | [L535](../../NamePlates/Core.lua#L535) |
| `NP.RefreshAll` | [L541](../../NamePlates/Core.lua#L541) |

### NamePlates/Countdown.lua

Owner: [19-nameplates.md](../19-nameplates.md).

| Declaration | Source |
|---|---|
| `Countdown.Added` | [L245](../../NamePlates/Countdown.lua#L245) |
| `Countdown.Removed` | [L249](../../NamePlates/Countdown.lua#L249) |
| `Countdown.Refresh` | [L253](../../NamePlates/Countdown.lua#L253) |
| `Countdown.Poll` | [L257](../../NamePlates/Countdown.lua#L257) |

### NamePlates/Level.lua

Owner: [19-nameplates.md](../19-nameplates.md).

| Declaration | Source |
|---|---|
| `Level.Added` | [L206](../../NamePlates/Level.lua#L206) |
| `Level.Removed` | [L212](../../NamePlates/Level.lua#L212) |
| `Level.Refresh` | [L220](../../NamePlates/Level.lua#L220) |
| `Level.Poll` | [L226](../../NamePlates/Level.lua#L226) |

### NamePlates/Threat.lua

Owner: [19-nameplates.md](../19-nameplates.md).

| Declaration | Source |
|---|---|
| `Threat.Added` | [L271](../../NamePlates/Threat.lua#L271) |
| `Threat.Removed` | [L275](../../NamePlates/Threat.lua#L275) |
| `Threat.Refresh` | [L285](../../NamePlates/Threat.lua#L285) |
| `Threat.Poll` | [L289](../../NamePlates/Threat.lua#L289) |

### Other/FluxChatColumnMicros.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `true_G.CharacterFrame_OnShow` | [L594](../../Other/FluxChatColumnMicros.lua#L594) |
| `true_G.CharacterFrame_OnHide` | [L601](../../Other/FluxChatColumnMicros.lua#L601) |
| `FluxChatColumnMicros.Create` | [L1268](../../Other/FluxChatColumnMicros.lua#L1268) |

### Other/FluxChatCopyPaste.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `FluxCCP.openFluxCCPCopyFrame` | [L109](../../Other/FluxChatCopyPaste.lua#L109) |
| `FluxCCP.createBnetString` | [L178](../../Other/FluxChatCopyPaste.lua#L178) |
| `FluxCCP.removeChatJunk` | [L201](../../Other/FluxChatCopyPaste.lua#L201) |
| `FluxCCP.SocialChatButtonName` | [L435](../../Other/FluxChatCopyPaste.lua#L435) |
| `FluxCCP.IsChatButtonEnabled` | [L445](../../Other/FluxChatCopyPaste.lua#L445) |
| `FluxCCP.AttachColumnToDock` | [L556](../../Other/FluxChatCopyPaste.lua#L556) |
| `FluxCCP.PinClassicButtonFrame` | [L671](../../Other/FluxChatCopyPaste.lua#L671) |
| `FluxCCP.PlaceColumnButtons` | [L721](../../Other/FluxChatCopyPaste.lua#L721) |
| `FluxCCP:UpdateColumnButtons` | [L867](../../Other/FluxChatCopyPaste.lua#L867) |
| `FluxCCP:InstallColumnButtons` | [L897](../../Other/FluxChatCopyPaste.lua#L897) |
| `FluxCCP:loadUrlColor` | [L1144](../../Other/FluxChatCopyPaste.lua#L1144) |
| `FluxCCP.fluxccpChatWebLinks` | [L1166](../../Other/FluxChatCopyPaste.lua#L1166) |
| `ItemRefTooltip:SetHyperlink` | [L1238](../../Other/FluxChatCopyPaste.lua#L1238) |
| `FluxCCP.createUrlLinkFrame` | [L1245](../../Other/FluxChatCopyPaste.lua#L1245) |
| `FluxCCP:updateChatOptions` | [L1249](../../Other/FluxChatCopyPaste.lua#L1249) |
| `FluxCCP:RGBToHex` | [L1272](../../Other/FluxChatCopyPaste.lua#L1272) |

### Other/FluxChatFrame.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `_G.FluxChatFrame_GetPrimaryChatHeight` | [L458](../../Other/FluxChatFrame.lua#L458) |
| `_G.FluxChatFrame_GetPrimaryBottomInsetY` | [L484](../../Other/FluxChatFrame.lua#L484) |
| `_G.FluxChatFrame_GetPrimaryColumnBottomY` | [L490](../../Other/FluxChatFrame.lua#L490) |
| `_G.FluxChatFrame_GetPrimaryTabHeight` | [L495](../../Other/FluxChatFrame.lua#L495) |
| `_G.FluxChatFrame_GetPrimaryColumnTopY` | [L500](../../Other/FluxChatFrame.lua#L500) |
| `_G.FluxChatFrame_GetPrimaryChatTop` | [L505](../../Other/FluxChatFrame.lua#L505) |
| `_G.FluxChatFrame_GetBesideMicromenuGap` | [L534](../../Other/FluxChatFrame.lua#L534) |
| `_G.FluxChatFrame_ApplyPrimaryPosition` | [L851](../../Other/FluxChatFrame.lua#L851) |
| `_G.FluxChatFrame_SetDragHold` | [L861](../../Other/FluxChatFrame.lua#L861) |
| `_G.FluxChatFrame_RefreshSocialLayout` | [L1200](../../Other/FluxChatFrame.lua#L1200) |

### Other/FluxEquipSlotFlyout.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `Flyout.CancelHideTimer` | [L47](../../Other/FluxEquipSlotFlyout.lua#L47) |
| `Flyout.CancelShowTimer` | [L51](../../Other/FluxEquipSlotFlyout.lua#L51) |
| `Flyout.IsOpenFor` | [L55](../../Other/FluxEquipSlotFlyout.lua#L55) |
| `Flyout.Hide` | [L68](../../Other/FluxEquipSlotFlyout.lua#L68) |
| `truebtn.SetChecked` | [L232](../../Other/FluxEquipSlotFlyout.lua#L232) |
| `region.Show` | [L258](../../Other/FluxEquipSlotFlyout.lua#L258) |
| `Flyout.ScheduleHideSoon` | [L278](../../Other/FluxEquipSlotFlyout.lua#L278) |
| `Flyout.Show` | [L433](../../Other/FluxEquipSlotFlyout.lua#L433) |
| `Flyout.NotifyEnter` | [L499](../../Other/FluxEquipSlotFlyout.lua#L499) |
| `Flyout.NotifyLeave` | [L518](../../Other/FluxEquipSlotFlyout.lua#L518) |
| `Flyout.SetOnEquipped` | [L523](../../Other/FluxEquipSlotFlyout.lua#L523) |

### Other/FluxHUDTooltip.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `ns.ApplyHUDTooltipPosition` | [L25](../../Other/FluxHUDTooltip.lua#L25) |
| `ns.SetHUDTooltipOwner` | [L40](../../Other/FluxHUDTooltip.lua#L40) |

### Other/FluxInputDebug.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `Debug.Capture` | [L100](../../Other/FluxInputDebug.lua#L100) |
| `SlashCmdList.FLUXINPUT` | [L175](../../Other/FluxInputDebug.lua#L175) |

### Other/FluxPerfCapture.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Capture.Print` | [L232](../../Other/FluxPerfCapture.lua#L232) |
| `Capture.Cancel` | [L275](../../Other/FluxPerfCapture.lua#L275) |
| `Capture.Start` | [L284](../../Other/FluxPerfCapture.lua#L284) |

### Other/FluxPerfDebug.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `P.ResetStats` | [L233](../../Other/FluxPerfDebug.lua#L233) |

### Other/FluxTradeFoodWater.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `Module.CreateButtons` | [L452](../../Other/FluxTradeFoodWater.lua#L452) |
| `Module.UpdateButtonVisibility` | [L555](../../Other/FluxTradeFoodWater.lua#L555) |
| `Module.Initialize` | [L618](../../Other/FluxTradeFoodWater.lua#L618) |

### Other/FluxVehicleExitButton.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `FluxVehicleExitButton:Create` | [L76](../../Other/FluxVehicleExitButton.lua#L76) |
| `FluxVehicleExitButton:RegisterEvents` | [L145](../../Other/FluxVehicleExitButton.lua#L145) |
| `FluxVehicleExitButton:OnEvent` | [L169](../../Other/FluxVehicleExitButton.lua#L169) |
| `FluxVehicleExitButton:CanExitVehicle` | [L200](../../Other/FluxVehicleExitButton.lua#L200) |
| `FluxVehicleExitButton:Update` | [L218](../../Other/FluxVehicleExitButton.lua#L218) |
| `FluxVehicleExitButton:OnClick` | [L258](../../Other/FluxVehicleExitButton.lua#L258) |
| `FluxVehicleExitButton:OnEnter` | [L283](../../Other/FluxVehicleExitButton.lua#L283) |
| `FluxVehicleExitButton:UpdatePosition` | [L328](../../Other/FluxVehicleExitButton.lua#L328) |

### Other/FluxVehicleSeats.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `FluxVehicleSeats_UpdateAnchor` | [L329](../../Other/FluxVehicleSeats.lua#L329) |

### RaidFrame/FluxRaidCompat.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaidCompat.UnitTokenValid` | [L70](../../RaidFrame/FluxRaidCompat.lua#L70) |
| `FluxRaidCompat.CallCUF` | [L89](../../RaidFrame/FluxRaidCompat.lua#L89) |
| `FluxRaidCompat.ShouldDisplayBorder` | [L103](../../RaidFrame/FluxRaidCompat.lua#L103) |
| `FluxRaidCompat.HasCompactRaidFrameManager` | [L116](../../RaidFrame/FluxRaidCompat.lua#L116) |
| `FluxRaidCompat.CanPositionRaidManager` | [L125](../../RaidFrame/FluxRaidCompat.lua#L125) |
| `FluxRaidCompat.CanUsePetBattleStateDriver` | [L130](../../RaidFrame/FluxRaidCompat.lua#L130) |
| `FluxRaidCompat.GetChatTabLift` | [L136](../../RaidFrame/FluxRaidCompat.lua#L136) |
| `FluxRaidCompat.ApplyPrivateAuraMixin` | [L141](../../RaidFrame/FluxRaidCompat.lua#L141) |
| `FluxRaidCompat.GetOutOfRange` | [L193](../../RaidFrame/FluxRaidCompat.lua#L193) |
| `FluxRaidCompat.ApplyRangeAlpha` | [L219](../../RaidFrame/FluxRaidCompat.lua#L219) |
| `FluxRaidCompat.BuildVisibleGroupsReverse` | [L254](../../RaidFrame/FluxRaidCompat.lua#L254) |
| `FluxRaidCompat.ComputeReverseColumnLayout` | [L267](../../RaidFrame/FluxRaidCompat.lua#L267) |
| `FluxRaidCompat.IsSecret` | [L308](../../RaidFrame/FluxRaidCompat.lua#L308) |
| `FluxRaidCompat.PlainBool` | [L312](../../RaidFrame/FluxRaidCompat.lua#L312) |
| `FluxRaidCompat.HasHealthPercent` | [L316](../../RaidFrame/FluxRaidCompat.lua#L316) |
| `FluxRaidCompat.HasPowerPercent` | [L322](../../RaidFrame/FluxRaidCompat.lua#L322) |
| `FluxRaidCompat.HasPrivateAuraContainer` | [L328](../../RaidFrame/FluxRaidCompat.lua#L328) |
| `FluxRaidCompat.HasRangeAlphaBoolean` | [L336](../../RaidFrame/FluxRaidCompat.lua#L336) |
| `FluxRaidCompat.GetHealthPercent` | [L342](../../RaidFrame/FluxRaidCompat.lua#L342) |
| `FluxRaidCompat.GetPowerPercent` | [L379](../../RaidFrame/FluxRaidCompat.lua#L379) |

### RaidFrame/FluxRaidFrame.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaid_GetCVarBool` | [L7](../../RaidFrame/FluxRaidFrame.lua#L7) |
| `FluxRaid_ShouldClassColorNames` | [L18](../../RaidFrame/FluxRaidFrame.lua#L18) |
| `FluxRaid_DisplayMainTankAndAssistCVarEnabled` | [L26](../../RaidFrame/FluxRaidFrame.lua#L26) |
| `FluxRaid_IsDispelHighlightEnabled` | [L30](../../RaidFrame/FluxRaidFrame.lua#L30) |
| `FluxRaid_IsFluxRaidEnabled` | [L41](../../RaidFrame/FluxRaidFrame.lua#L41) |
| `FluxRaid_ApplyRangePollInterval` | [L52](../../RaidFrame/FluxRaidFrame.lua#L52) |
| `FluxRaid_GetRangePollStats` | [L55](../../RaidFrame/FluxRaidFrame.lua#L55) |
| `FluxRaid_GetMTMAPollStats` | [L59](../../RaidFrame/FluxRaidFrame.lua#L59) |
| `FluxRaid_ApplyOptionsFromDB` | [L75](../../RaidFrame/FluxRaidFrame.lua#L75) |
| `EventHandlers:GROUP_ROSTER_UPDATE` | [L177](../../RaidFrame/FluxRaidFrame.lua#L177) |
| `EventHandlers:PARTY_MEMBERS_CHANGED` | [L183](../../RaidFrame/FluxRaidFrame.lua#L183) |
| `EventHandlers:CVAR_UPDATE` | [L189](../../RaidFrame/FluxRaidFrame.lua#L189) |
| `EventHandlers:PLAYER_ENTERING_WORLD` | [L193](../../RaidFrame/FluxRaidFrame.lua#L193) |
| `EventHandlers:PLAYER_REGEN_ENABLED` | [L200](../../RaidFrame/FluxRaidFrame.lua#L200) |
| `EventHandlers:COMPACT_UNIT_FRAME_PROFILES_LOADED` | [L206](../../RaidFrame/FluxRaidFrame.lua#L206) |
| `EventHandlers:DISPLAY_SIZE_CHANGED` | [L212](../../RaidFrame/FluxRaidFrame.lua#L212) |
| `EventHandlers:UI_SCALE_CHANGED` | [L218](../../RaidFrame/FluxRaidFrame.lua#L218) |
| `EventHandlers:PLAYER_TARGET_CHANGED` | [L224](../../RaidFrame/FluxRaidFrame.lua#L224) |
| `EventHandlers:PLAYER_ROLES_ASSIGNED` | [L230](../../RaidFrame/FluxRaidFrame.lua#L230) |
| `EventHandlers:READY_CHECK` | [L236](../../RaidFrame/FluxRaidFrame.lua#L236) |
| `EventHandlers:READY_CHECK_CONFIRM` | [L242](../../RaidFrame/FluxRaidFrame.lua#L242) |
| `EventHandlers:READY_CHECK_FINISHED` | [L248](../../RaidFrame/FluxRaidFrame.lua#L248) |
| `EventHandlers:RAID_TARGET_UPDATE` | [L254](../../RaidFrame/FluxRaidFrame.lua#L254) |
| `FluxRaid_OnLoad` | [L260](../../RaidFrame/FluxRaidFrame.lua#L260) |
| `FluxRaid_OnEvent` | [L304](../../RaidFrame/FluxRaidFrame.lua#L304) |

### RaidFrame/FluxRaidFrame_BigDebuffs.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `BigDebuffs:Refresh` | [L118](../../RaidFrame/FluxRaidFrame_BigDebuffs.lua#L118) |

### RaidFrame/FluxRaidLayout.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaid_GetColumnHeight` | [L45](../../RaidFrame/FluxRaidLayout.lua#L45) |
| `FluxRaid_GetMTMAChildStep` | [L49](../../RaidFrame/FluxRaidLayout.lua#L49) |
| `FluxRaid_QueueWork` | [L57](../../RaidFrame/FluxRaidLayout.lua#L57) |
| `FluxRaid_GetMTMARosterCount` | [L129](../../RaidFrame/FluxRaidLayout.lua#L129) |
| `FluxRaid_GetPreviewStackVerticalPosition` | [L214](../../RaidFrame/FluxRaidLayout.lua#L214) |
| `FluxRaidFrame_UpdatePosition` | [L219](../../RaidFrame/FluxRaidLayout.lua#L219) |
| `FluxRaid_ComputeSyntheticGroup2ColumnLeftX` | [L237](../../RaidFrame/FluxRaidLayout.lua#L237) |
| `FluxRaid_GetPlacement2FocusAnchorBottomRight` | [L265](../../RaidFrame/FluxRaidLayout.lua#L265) |
| `FluxRaid_GetFirstGroupNthMemberBottomFromScreen` | [L579](../../RaidFrame/FluxRaidLayout.lua#L579) |
| `FluxRaid_QueueConfigureAndRefresh` | [L654](../../RaidFrame/FluxRaidLayout.lua#L654) |
| `FluxRaid_InstallManagerHooks` | [L757](../../RaidFrame/FluxRaidLayout.lua#L757) |
| `FluxRaid_ScheduleBlizzardGridHideCheck` | [L773](../../RaidFrame/FluxRaidLayout.lua#L773) |
| `FluxRaid_ApplyBlizzardCompactGridHidden` | [L786](../../RaidFrame/FluxRaidLayout.lua#L786) |
| `FluxRaid_RestoreBlizzardRaidFrames` | [L807](../../RaidFrame/FluxRaidLayout.lua#L807) |
| `FluxRaid_RunPendingCombatWork` | [L830](../../RaidFrame/FluxRaidLayout.lua#L830) |
| `FluxRaid_OnRosterOrPartyChanged` | [L856](../../RaidFrame/FluxRaidLayout.lua#L856) |
| `FluxRaid_InitLayoutFrames` | [L873](../../RaidFrame/FluxRaidLayout.lua#L873) |
| `FluxRaid_InstallPetBattleDriver` | [L894](../../RaidFrame/FluxRaidLayout.lua#L894) |
| `FluxRaid_DisableBlizzardNow` | [L933](../../RaidFrame/FluxRaidLayout.lua#L933) |
| `FluxRaid_PositionContainer` | [L937](../../RaidFrame/FluxRaidLayout.lua#L937) |

### RaidFrame/FluxRaidPreview.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaidPreviewUnit_OnLoad` | [L298](../../RaidFrame/FluxRaidPreview.lua#L298) |
| `FluxRaidPreview_ApplyIdleHighlights` | [L373](../../RaidFrame/FluxRaidPreview.lua#L373) |
| `FluxRaidPreview_RefreshLayout` | [L642](../../RaidFrame/FluxRaidPreview.lua#L642) |
| `FluxRaidPreview.Show` | [L674](../../RaidFrame/FluxRaidPreview.lua#L674) |
| `FluxRaidPreview.Hide` | [L684](../../RaidFrame/FluxRaidPreview.lua#L684) |
| `FluxRaidPreview.Toggle` | [L691](../../RaidFrame/FluxRaidPreview.lua#L691) |
| `FluxRaidPreview.RefreshFromOptions` | [L699](../../RaidFrame/FluxRaidPreview.lua#L699) |
| `FluxRaidPreviewUnit_OnEnter` | [L708](../../RaidFrame/FluxRaidPreview.lua#L708) |
| `FluxRaidPreviewUnit_OnLeave` | [L723](../../RaidFrame/FluxRaidPreview.lua#L723) |

### RaidFrame/FluxRaidUnit.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaid_ShouldShowPowerBar` | [L47](../../RaidFrame/FluxRaidUnit.lua#L47) |
| `FluxRaid_UpdateHealth` | [L84](../../RaidFrame/FluxRaidUnit.lua#L84) |
| `FluxRaid_UpdatePower` | [L106](../../RaidFrame/FluxRaidUnit.lua#L106) |
| `FluxRaid_UpdateHealPrediction` | [L177](../../RaidFrame/FluxRaidUnit.lua#L177) |
| `FluxRaid_UpdateName` | [L214](../../RaidFrame/FluxRaidUnit.lua#L214) |
| `FluxRaid_UpdateStatusText` | [L241](../../RaidFrame/FluxRaidUnit.lua#L241) |
| `FluxRaid_UpdateSelectionHighlight` | [L320](../../RaidFrame/FluxRaidUnit.lua#L320) |
| `FluxRaid_UpdateAggroHighlight` | [L337](../../RaidFrame/FluxRaidUnit.lua#L337) |
| `FluxRaid_UpdateRoleIcon` | [L380](../../RaidFrame/FluxRaidUnit.lua#L380) |
| `FluxRaid_UpdateCenterStatus` | [L422](../../RaidFrame/FluxRaidUnit.lua#L422) |
| `FluxRaid_UpdateReadyCheck` | [L450](../../RaidFrame/FluxRaidUnit.lua#L450) |
| `FluxRaid_UpdateRange` | [L474](../../RaidFrame/FluxRaidUnit.lua#L474) |
| `FluxRaid_UpdateAuras` | [L570](../../RaidFrame/FluxRaidUnit.lua#L570) |
| `FluxRaid_UpdateDispelHighlight` | [L609](../../RaidFrame/FluxRaidUnit.lua#L609) |
| `FluxRaid_PaintUnit` | [L658](../../RaidFrame/FluxRaidUnit.lua#L658) |
| `FluxRaid_BindUnit` | [L763](../../RaidFrame/FluxRaidUnit.lua#L763) |
| `FluxRaid_OnUnitAttributeChanged` | [L786](../../RaidFrame/FluxRaidUnit.lua#L786) |
| `FluxRaidUnit_OnLoad` | [L797](../../RaidFrame/FluxRaidUnit.lua#L797) |
| `FluxRaidUnit_OnShow` | [L834](../../RaidFrame/FluxRaidUnit.lua#L834) |
| `FluxRaidUnit_OnHide` | [L843](../../RaidFrame/FluxRaidUnit.lua#L843) |
| `FluxRaidUnit_OnEnter` | [L868](../../RaidFrame/FluxRaidUnit.lua#L868) |
| `FluxRaidUnit_OnLeave` | [L876](../../RaidFrame/FluxRaidUnit.lua#L876) |
| `ns.FluxRaidRegisterAllMouseoverKeybindFrames` | [L886](../../RaidFrame/FluxRaidUnit.lua#L886) |
| `FluxRaid_ForEachHeaderChild` | [L896](../../RaidFrame/FluxRaidUnit.lua#L896) |
| `FluxRaid_SyncHeaderChildUnits` | [L921](../../RaidFrame/FluxRaidUnit.lua#L921) |
| `FluxRaid_ApplyChromeToChildren` | [L933](../../RaidFrame/FluxRaidUnit.lua#L933) |
| `FluxRaid_SyncAllFluxUnitAuraSettings` | [L956](../../RaidFrame/FluxRaidUnit.lua#L956) |
| `FluxRaid_RefreshVisibleUnits` | [L964](../../RaidFrame/FluxRaidUnit.lua#L964) |
| `FluxRaid_RefreshSelfDisplayNames` | [L983](../../RaidFrame/FluxRaidUnit.lua#L983) |
| `FluxRaid_EnsureRangePoll` | [L1015](../../RaidFrame/FluxRaidUnit.lua#L1015) |
| `FluxRaid_IsMTMAChild` | [L1024](../../RaidFrame/FluxRaidUnit.lua#L1024) |
| `FluxCompactMiniFrameSetup` | [L1055](../../RaidFrame/FluxRaidUnit.lua#L1055) |
| `FluxRaid_AttachOrUpdateMTMATarget` | [L1100](../../RaidFrame/FluxRaidUnit.lua#L1100) |
| `FluxRaid_RefreshMTMATargetAttachments` | [L1135](../../RaidFrame/FluxRaidUnit.lua#L1135) |
| `FluxCompactMiniFrameSetup_G.FluxCompactUnitFrameSetup` | [L1149](../../RaidFrame/FluxRaidUnit.lua#L1149) |

### RaidFrame/FluxRaidVisuals.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaidVisuals.ApplyRaidFrameTunables` | [L52](../../RaidFrame/FluxRaidVisuals.lua#L52) |
| `FluxRaidVisuals.ApplyRaidHighlightVertexColors` | [L106](../../RaidFrame/FluxRaidVisuals.lua#L106) |
| `FluxRaidVisuals.SafeSetUnitFrameSize` | [L122](../../RaidFrame/FluxRaidVisuals.lua#L122) |
| `FluxRaidVisuals.EnsureFluxOverlays` | [L147](../../RaidFrame/FluxRaidVisuals.lua#L147) |
| `FluxRaidVisuals.GetAuraFocusMode` | [L230](../../RaidFrame/FluxRaidVisuals.lua#L230) |
| `FluxRaidVisuals.GetAuraOrganizationType` | [L242](../../RaidFrame/FluxRaidVisuals.lua#L242) |
| `FluxRaidVisuals.UsesPrivateAuras` | [L273](../../RaidFrame/FluxRaidVisuals.lua#L273) |
| `FluxRaidVisuals.GetFluxRaidOptionTable` | [L282](../../RaidFrame/FluxRaidVisuals.lua#L282) |
| `FluxRaidVisuals.UseOwnRaidSettings` | [L299](../../RaidFrame/FluxRaidVisuals.lua#L299) |
| `FluxRaidVisuals.SyncAuraDisplayOptions` | [L304](../../RaidFrame/FluxRaidVisuals.lua#L304) |
| `FluxRaidVisuals.EnsureAuraMaxSlots` | [L344](../../RaidFrame/FluxRaidVisuals.lua#L344) |
| `FluxRaidVisuals.ConfigurePrivateAuras` | [L377](../../RaidFrame/FluxRaidVisuals.lua#L377) |
| `FluxRaidVisuals.UpdatePrivateAuraUnit` | [L430](../../RaidFrame/FluxRaidVisuals.lua#L430) |
| `FluxRaidVisuals.SyncPrivateAuraSettings` | [L452](../../RaidFrame/FluxRaidVisuals.lua#L452) |
| `FluxRaidVisuals.PushAuraDisplayToFrame` | [L476](../../RaidFrame/FluxRaidVisuals.lua#L476) |
| `FluxRaidVisuals.NeutralizeBlizzardSharedUpdateAllSetup` | [L486](../../RaidFrame/FluxRaidVisuals.lua#L486) |
| `FluxRaidVisuals.ResealCompactUnitFrameOnUpdate` | [L489](../../RaidFrame/FluxRaidVisuals.lua#L489) |
| `FluxRaidVisuals.ApplyCellChrome` | [L493](../../RaidFrame/FluxRaidVisuals.lua#L493) |
| `FluxRaidVisuals.ApplyVisuals` | [L604](../../RaidFrame/FluxRaidVisuals.lua#L604) |
| `FluxRaidVisuals.SetupHealAbsorbLayers` | [L609](../../RaidFrame/FluxRaidVisuals.lua#L609) |
| `FluxRaidVisuals.SetupReadyCheckIcon` | [L612](../../RaidFrame/FluxRaidVisuals.lua#L612) |
| `FluxRaidVisuals.RefreshNeutralBarTracks` | [L615](../../RaidFrame/FluxRaidVisuals.lua#L615) |

### Respec/FluxRespec_ActionBars.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `ActionBars.CollectSlots` | [L59](../../Respec/FluxRespec_ActionBars.lua#L59) |
| `ActionBars.RewriteStanceSpellId` | [L252](../../Respec/FluxRespec_ActionBars.lua#L252) |
| `ActionBars.RewriteSavedStanceSpellId` | [L324](../../Respec/FluxRespec_ActionBars.lua#L324) |
| `ActionBars.CaptureStanceLayout` | [L354](../../Respec/FluxRespec_ActionBars.lua#L354) |
| `ActionBars.ApplyStanceLayout` | [L376](../../Respec/FluxRespec_ActionBars.lua#L376) |
| `ActionBars.Capture` | [L420](../../Respec/FluxRespec_ActionBars.lua#L420) |
| `ActionBars.Apply` | [L571](../../Respec/FluxRespec_ActionBars.lua#L571) |
| `ActionBars.MatchesSnapshot` | [L582](../../Respec/FluxRespec_ActionBars.lua#L582) |
| `ActionBars.FilledCount` | [L608](../../Respec/FluxRespec_ActionBars.lua#L608) |

### Respec/FluxRespec_Apply.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Apply.IsRunning` | [L152](../../Respec/FluxRespec_Apply.lua#L152) |
| `Apply.IsWaitingForRuneEngrave` | [L156](../../Respec/FluxRespec_Apply.lua#L156) |
| `Apply.IsEngraveButtonMode` | [L162](../../Respec/FluxRespec_Apply.lua#L162) |
| `Apply.WillSwitchSpec` | [L172](../../Respec/FluxRespec_Apply.lua#L172) |
| `Apply.Cancel` | [L177](../../Respec/FluxRespec_Apply.lua#L177) |
| `Apply.IsProfileFullyApplied` | [L317](../../Respec/FluxRespec_Apply.lua#L317) |
| `Apply.NextStepLabel` | [L389](../../Respec/FluxRespec_Apply.lua#L389) |
| `Apply.Run` | [L888](../../Respec/FluxRespec_Apply.lua#L888) |

### Respec/FluxRespec_AtieshDualSpecFix.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Fix.OnDualSpecSwitchStart` | [L299](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L299) |
| `origFix._wrappedSetActiveTalentGroup` | [L344](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L344) |
| `CSI.SetActiveSpecGroupFix._wrappedSetActiveSpecGroup` | [L360](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L360) |

### Respec/FluxRespec_Compat.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Compat.IsSoD` | [L20](../../Respec/FluxRespec_Compat.lua#L20) |
| `Compat.HasDualSpec` | [L35](../../Respec/FluxRespec_Compat.lua#L35) |
| `Compat.NeedsTrainerReset` | [L53](../../Respec/FluxRespec_Compat.lua#L53) |
| `Compat.HasTalentLoadouts` | [L65](../../Respec/FluxRespec_Compat.lua#L65) |
| `Compat.CanUseEquipmentSets` | [L71](../../Respec/FluxRespec_Compat.lua#L71) |
| `Compat.EquipmentSlotMax` | [L83](../../Respec/FluxRespec_Compat.lua#L83) |
| `Compat.ClientTag` | [L96](../../Respec/FluxRespec_Compat.lua#L96) |
| `Compat.GetActiveGroup` | [L110](../../Respec/FluxRespec_Compat.lua#L110) |
| `Compat.GetNumGroups` | [L122](../../Respec/FluxRespec_Compat.lua#L122) |
| `Compat.SetActiveGroup` | [L134](../../Respec/FluxRespec_Compat.lua#L134) |
| `Compat.GetContainerNumSlots` | [L148](../../Respec/FluxRespec_Compat.lua#L148) |
| `Compat.GetContainerItemID` | [L160](../../Respec/FluxRespec_Compat.lua#L160) |
| `Compat.GetContainerItemLink` | [L172](../../Respec/FluxRespec_Compat.lua#L172) |
| `Compat.PickupContainerItem` | [L184](../../Respec/FluxRespec_Compat.lua#L184) |
| `Compat.ParseItemID` | [L204](../../Respec/FluxRespec_Compat.lua#L204) |
| `Compat.ShallowCopy` | [L216](../../Respec/FluxRespec_Compat.lua#L216) |
| `Compat.DeepCopy` | [L224](../../Respec/FluxRespec_Compat.lua#L224) |
| `Compat.SecureUIPanelsBlockRespecWork` | [L240](../../Respec/FluxRespec_Compat.lua#L240) |

### Respec/FluxRespec_Consumables.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Consumables.Capture` | [L16](../../Respec/FluxRespec_Consumables.lua#L16) |
| `Consumables.Apply` | [L29](../../Respec/FluxRespec_Consumables.lua#L29) |
| `Consumables.IsDifferent` | [L69](../../Respec/FluxRespec_Consumables.lua#L69) |

### Respec/FluxRespec_Core.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `R.Print` | [L12](../../Respec/FluxRespec_Core.lua#L12) |
| `R.Warn` | [L18](../../Respec/FluxRespec_Core.lua#L18) |
| `R.GetStore` | [L50](../../Respec/FluxRespec_Core.lua#L50) |
| `R.GetPersistedTrainerUnlearnCostCopper` | [L55](../../Respec/FluxRespec_Core.lua#L55) |
| `R.RememberTrainerUnlearnCostCopper` | [L63](../../Respec/FluxRespec_Core.lua#L63) |
| `R.On` | [L77](../../Respec/FluxRespec_Core.lua#L77) |
| `R.Fire` | [L83](../../Respec/FluxRespec_Core.lua#L83) |
| `R.GetProfileNames` | [L99](../../Respec/FluxRespec_Core.lua#L99) |
| `R.GetActiveName` | [L112](../../Respec/FluxRespec_Core.lua#L112) |
| `R.LinkProfilePresets` | [L117](../../Respec/FluxRespec_Core.lua#L117) |
| `R.SetActiveName` | [L137](../../Respec/FluxRespec_Core.lua#L137) |
| `R.HasActiveProfile` | [L158](../../Respec/FluxRespec_Core.lua#L158) |
| `R.GetProfile` | [L163](../../Respec/FluxRespec_Core.lua#L163) |
| `R.CreateProfile` | [L170](../../Respec/FluxRespec_Core.lua#L170) |
| `R.DefaultIcon` | [L222](../../Respec/FluxRespec_Core.lua#L222) |
| `R.GetIcon` | [L231](../../Respec/FluxRespec_Core.lua#L231) |
| `R.SetIcon` | [L244](../../Respec/FluxRespec_Core.lua#L244) |
| `R.DeleteProfile` | [L257](../../Respec/FluxRespec_Core.lua#L257) |
| `R.RenameProfile` | [L278](../../Respec/FluxRespec_Core.lua#L278) |
| `R.DuplicateProfile` | [L308](../../Respec/FluxRespec_Core.lua#L308) |
| `R.SetSection` | [L334](../../Respec/FluxRespec_Core.lua#L334) |
| `R.CaptureInto` | [L346](../../Respec/FluxRespec_Core.lua#L346) |
| `R.LoadProfile` | [L462](../../Respec/FluxRespec_Core.lua#L462) |
| `R.ApplyInfoFrameForProfile` | [L471](../../Respec/FluxRespec_Core.lua#L471) |
| `R.ClearUnitFrameRespecArmed` | [L488](../../Respec/FluxRespec_Core.lua#L488) |
| `R.SetUnitFrameRespecArmed` | [L492](../../Respec/FluxRespec_Core.lua#L492) |
| `R.IsUnitFrameRespecArmedForActiveProfile` | [L502](../../Respec/FluxRespec_Core.lua#L502) |
| `R.SelectActiveProfileOnly` | [L510](../../Respec/FluxRespec_Core.lua#L510) |
| `R.RunLoadProfileButtonAction` | [L536](../../Respec/FluxRespec_Core.lua#L536) |
| `R.ActiveProfileGearMatches` | [L562](../../Respec/FluxRespec_Core.lua#L562) |
| `R.ActiveProfileBuildMatches` | [L614](../../Respec/FluxRespec_Core.lua#L614) |
| `R.GetActiveProfileBuildIcon` | [L629](../../Respec/FluxRespec_Core.lua#L629) |
| `R.SetLoadCheckpoint` | [L648](../../Respec/FluxRespec_Core.lua#L648) |
| `R.ClearLoadCheckpoint` | [L654](../../Respec/FluxRespec_Core.lua#L654) |
| `R.GetLoadCheckpoint` | [L660](../../Respec/FluxRespec_Core.lua#L660) |
| `R.RefreshPlayerSpecIconDecor` | [L670](../../Respec/FluxRespec_Core.lua#L670) |
| `endend_G.FluxRespec_GetPlayerSpecIconOverride` | [L790](../../Respec/FluxRespec_Core.lua#L790) |

### Respec/FluxRespec_Equipment.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Equipment.GetSlotMax` | [L35](../../Respec/FluxRespec_Equipment.lua#L35) |
| `Equipment.IsMainHandTwoHanded` | [L73](../../Respec/FluxRespec_Equipment.lua#L73) |
| `Equipment.ShouldIgnoreOffHandSlot` | [L92](../../Respec/FluxRespec_Equipment.lua#L92) |
| `Equipment.InvalidateItemKeyCache` | [L402](../../Respec/FluxRespec_Equipment.lua#L402) |
| `Equipment.GetItemKeyForInventorySlot` | [L419](../../Respec/FluxRespec_Equipment.lua#L419) |
| `Equipment.GetItemKeyForBagSlot` | [L483](../../Respec/FluxRespec_Equipment.lua#L483) |
| `Equipment.Capture` | [L509](../../Respec/FluxRespec_Equipment.lua#L509) |
| `Equipment.CaptureSlot` | [L537](../../Respec/FluxRespec_Equipment.lua#L537) |
| `Equipment.CaptureSlots` | [L556](../../Respec/FluxRespec_Equipment.lua#L556) |
| `Equipment.IsWantEmpty` | [L571](../../Respec/FluxRespec_Equipment.lua#L571) |
| `Equipment.IsInventorySlotEmpty` | [L576](../../Respec/FluxRespec_Equipment.lua#L576) |
| `Equipment.WantHasSpecificLink` | [L691](../../Respec/FluxRespec_Equipment.lua#L691) |
| `Equipment.WantHasItemKey` | [L695](../../Respec/FluxRespec_Equipment.lua#L695) |
| `Equipment.WantsSameIdentity` | [L700](../../Respec/FluxRespec_Equipment.lua#L700) |
| `Equipment.WantsMatchSavedWant` | [L725](../../Respec/FluxRespec_Equipment.lua#L725) |
| `Equipment.PaperdollSlotMatchesWant` | [L835](../../Respec/FluxRespec_Equipment.lua#L835) |
| `Equipment.StartParallelBankWithdrawForLoad` | [L1340](../../Respec/FluxRespec_Equipment.lua#L1340) |
| `Equipment.BagSlotMatchesSavedWant` | [L1382](../../Respec/FluxRespec_Equipment.lua#L1382) |
| `Equipment.IsBagSlotInSavedGearSet` | [L1387](../../Respec/FluxRespec_Equipment.lua#L1387) |
| `Equipment.ApplyWithCallback` | [L1725](../../Respec/FluxRespec_Equipment.lua#L1725) |
| `Equipment.Apply` | [L1739](../../Respec/FluxRespec_Equipment.lua#L1739) |
| `Equipment.SlotRelevantToProfileEquipment` | [L1768](../../Respec/FluxRespec_Equipment.lua#L1768) |
| `Equipment.DiffCount` | [L1789](../../Respec/FluxRespec_Equipment.lua#L1789) |
| `Equipment.AnyGearChangeNeeded` | [L1812](../../Respec/FluxRespec_Equipment.lua#L1812) |
| `Equipment.SlotMatchesEntry` | [L1838](../../Respec/FluxRespec_Equipment.lua#L1838) |
| `Equipment.FindBagSlotByItemLink` | [L1851](../../Respec/FluxRespec_Equipment.lua#L1851) |
| `Equipment.GetProfileGearAvailability` | [L1894](../../Respec/FluxRespec_Equipment.lua#L1894) |
| `Equipment.GetSlotGearStatus` | [L1993](../../Respec/FluxRespec_Equipment.lua#L1993) |
| `Equipment.ProfileHasMissingGear` | [L2007](../../Respec/FluxRespec_Equipment.lua#L2007) |
| `Equipment.ProfileHasGearIssue` | [L2017](../../Respec/FluxRespec_Equipment.lua#L2017) |
| `Equipment.GetProfileGearIssueKind` | [L2027](../../Respec/FluxRespec_Equipment.lua#L2027) |
| `Equipment.CanItemGoInInventorySlot` | [L2093](../../Respec/FluxRespec_Equipment.lua#L2093) |
| `Equipment.GetBagCandidatesForInventorySlot` | [L2112](../../Respec/FluxRespec_Equipment.lua#L2112) |
| `Equipment.EquipBagSlotToInventorySlot` | [L2153](../../Respec/FluxRespec_Equipment.lua#L2153) |
| `Equipment.NotifyActiveProfileMayNeedBankWithdraw` | [L2179](../../Respec/FluxRespec_Equipment.lua#L2179) |

### Respec/FluxRespec_EquipmentPresets.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Presets.EnsureStore` | [L36](../../Respec/FluxRespec_EquipmentPresets.lua#L36) |
| `Presets.GetActivePreset` | [L44](../../Respec/FluxRespec_EquipmentPresets.lua#L44) |
| `Presets.SetActivePreset` | [L48](../../Respec/FluxRespec_EquipmentPresets.lua#L48) |
| `Presets.GetPresetNames` | [L61](../../Respec/FluxRespec_EquipmentPresets.lua#L61) |
| `Presets.GetPreset` | [L75](../../Respec/FluxRespec_EquipmentPresets.lua#L75) |
| `Presets.CreatePreset` | [L86](../../Respec/FluxRespec_EquipmentPresets.lua#L86) |
| `Presets.RenamePreset` | [L113](../../Respec/FluxRespec_EquipmentPresets.lua#L113) |
| `Presets.DeletePreset` | [L155](../../Respec/FluxRespec_EquipmentPresets.lua#L155) |
| `Presets.SaveActivePresetFromLive` | [L179](../../Respec/FluxRespec_EquipmentPresets.lua#L179) |
| `Presets.Apply` | [L219](../../Respec/FluxRespec_EquipmentPresets.lua#L219) |
| `Presets.LinkProfileEquipmentPreset` | [L266](../../Respec/FluxRespec_EquipmentPresets.lua#L266) |
| `Presets.MatchesProfileLink` | [L283](../../Respec/FluxRespec_EquipmentPresets.lua#L283) |
| `Presets.IsDefault` | [L294](../../Respec/FluxRespec_EquipmentPresets.lua#L294) |
| `Presets.GetActivePresetEquipment` | [L299](../../Respec/FluxRespec_EquipmentPresets.lua#L299) |
| `Presets.GetTargetEquipmentSnapshot` | [L314](../../Respec/FluxRespec_EquipmentPresets.lua#L314) |
| `Presets.GetTargetEquipmentDiffCount` | [L325](../../Respec/FluxRespec_EquipmentPresets.lua#L325) |
| `Presets.PresetEquipmentMatchLive` | [L342](../../Respec/FluxRespec_EquipmentPresets.lua#L342) |

### Respec/FluxRespec_EquipmentSets.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `EquipmentSets.CanUse` | [L23](../../Respec/FluxRespec_EquipmentSets.lua#L23) |
| `EquipmentSets.NameMaxLetters` | [L47](../../Respec/FluxRespec_EquipmentSets.lua#L47) |
| `EquipmentSets.TruncName` | [L54](../../Respec/FluxRespec_EquipmentSets.lua#L54) |
| `EquipmentSets.GetNum` | [L131](../../Respec/FluxRespec_EquipmentSets.lua#L131) |
| `EquipmentSets.HasQuotaForNew` | [L145](../../Respec/FluxRespec_EquipmentSets.lua#L145) |
| `GetInfo` | [L149](../../Respec/FluxRespec_EquipmentSets.lua#L149) |
| `EquipmentSets.GetInfo` | [L172](../../Respec/FluxRespec_EquipmentSets.lua#L172) |
| `EquipmentSets.GetLink` | [L192](../../Respec/FluxRespec_EquipmentSets.lua#L192) |
| `EquipmentSets.GetIgnoredSlotSet` | [L211](../../Respec/FluxRespec_EquipmentSets.lua#L211) |
| `EquipmentSets.WouldViolateWanted` | [L231](../../Respec/FluxRespec_EquipmentSets.lua#L231) |
| `EquipmentSets.IsMuted` | [L287](../../Respec/FluxRespec_EquipmentSets.lua#L287) |
| `EquipmentSets.PickIcon` | [L315](../../Respec/FluxRespec_EquipmentSets.lua#L315) |
| `EquipmentSets.DisplayIcon` | [L339](../../Respec/FluxRespec_EquipmentSets.lua#L339) |
| `EquipmentSets.DisplayName` | [L359](../../Respec/FluxRespec_EquipmentSets.lua#L359) |
| `EquipmentSets.ResolveId` | [L373](../../Respec/FluxRespec_EquipmentSets.lua#L373) |
| `EquipmentSets.SyncManaged` | [L414](../../Respec/FluxRespec_EquipmentSets.lua#L414) |
| `EquipmentSets.PushIcon` | [L481](../../Respec/FluxRespec_EquipmentSets.lua#L481) |
| `EquipmentSets.PushName` | [L506](../../Respec/FluxRespec_EquipmentSets.lua#L506) |
| `EquipmentSets.DeleteIfManaged` | [L531](../../Respec/FluxRespec_EquipmentSets.lua#L531) |
| `EquipmentSets.QuotaTooltip` | [L557](../../Respec/FluxRespec_EquipmentSets.lua#L557) |
| `EquipmentSets.TryApply` | [L600](../../Respec/FluxRespec_EquipmentSets.lua#L600) |
| `EquipmentSets.SnapshotFromSet` | [L741](../../Respec/FluxRespec_EquipmentSets.lua#L741) |
| `EquipmentSets.ImportBlizzardAsPresets` | [L856](../../Respec/FluxRespec_EquipmentSets.lua#L856) |
| `EquipmentSets.ReconcileAll` | [L922](../../Respec/FluxRespec_EquipmentSets.lua#L922) |

### Respec/FluxRespec_GearPicker.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `P.GetExtraScrollBottom` | [L16](../../Respec/FluxRespec_GearPicker.lua#L16) |
| `P.CancelHideTimer` | [L56](../../Respec/FluxRespec_GearPicker.lua#L56) |
| `P.CancelShowTimer` | [L60](../../Respec/FluxRespec_GearPicker.lua#L60) |
| `P.IsOpenFor` | [L64](../../Respec/FluxRespec_GearPicker.lua#L64) |
| `P.HasAlternatives` | [L77](../../Respec/FluxRespec_GearPicker.lua#L77) |
| `P.Hide` | [L86](../../Respec/FluxRespec_GearPicker.lua#L86) |
| `P.NotifyStripEnter` | [L119](../../Respec/FluxRespec_GearPicker.lua#L119) |
| `P.NotifyStripLeave` | [L138](../../Respec/FluxRespec_GearPicker.lua#L138) |
| `P.ScheduleHideSoon` | [L143](../../Respec/FluxRespec_GearPicker.lua#L143) |
| `P.Show` | [L160](../../Respec/FluxRespec_GearPicker.lua#L160) |

### Respec/FluxRespec_GearSetEquipGuard.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `thenreturnfalseendifguard.ShouldButtonPassThroughthenguard.ShouldButtonPassThrough` | [L132](../../Respec/FluxRespec_GearSetEquipGuard.lua#L132) |
| `EquipGuard.RefreshAll` | [L202](../../Respec/FluxRespec_GearSetEquipGuard.lua#L202) |

### Respec/FluxRespec_GearSetIndex.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `GearSetIndex.Rebuild` | [L75](../../Respec/FluxRespec_GearSetIndex.lua#L75) |
| `GearSetIndex.GetEntries` | [L108](../../Respec/FluxRespec_GearSetIndex.lua#L108) |
| `GearSetIndex.GetEntriesForItemID` | [L112](../../Respec/FluxRespec_GearSetIndex.lua#L112) |
| `GearSetIndex.WantIdentityKey` | [L139](../../Respec/FluxRespec_GearSetIndex.lua#L139) |
| `GearSetIndex.RequiredCopiesForWant` | [L143](../../Respec/FluxRespec_GearSetIndex.lua#L143) |
| `GearSetIndex.AreAllocationsFresh` | [L381](../../Respec/FluxRespec_GearSetIndex.lua#L381) |
| `GearSetIndex.RefreshAllocations` | [L395](../../Respec/FluxRespec_GearSetIndex.lua#L395) |
| `GearSetIndex.IsBagSlotAllocatedForEntry` | [L481](../../Respec/FluxRespec_GearSetIndex.lua#L481) |
| `GearSetIndex.IsInventorySlotAllocatedForEntry` | [L490](../../Respec/FluxRespec_GearSetIndex.lua#L490) |
| `GearSetIndex.IsBagSlotAllocatedForGearSet` | [L500](../../Respec/FluxRespec_GearSetIndex.lua#L500) |
| `GearSetIndex.IsInventorySlotAllocatedForGearSet` | [L507](../../Respec/FluxRespec_GearSetIndex.lua#L507) |
| `GearSetIndex.ForEachAllocatedBagSlot` | [L523](../../Respec/FluxRespec_GearSetIndex.lua#L523) |
| `GearSetIndex.GetMatchingIdentityKeyForBagSlot` | [L553](../../Respec/FluxRespec_GearSetIndex.lua#L553) |
| `GearSetIndex.GetMatchingIdentityKeyForInventorySlot` | [L573](../../Respec/FluxRespec_GearSetIndex.lua#L573) |
| `GearSetIndex.IsBagSlotInSavedGearSet` | [L598](../../Respec/FluxRespec_GearSetIndex.lua#L598) |
| `GearSetIndex.IsInventorySlotInSavedGearSet` | [L608](../../Respec/FluxRespec_GearSetIndex.lua#L608) |
| `GearSetIndex.GetMatchingSetNames` | [L633](../../Respec/FluxRespec_GearSetIndex.lua#L633) |

### Respec/FluxRespec_GearSetLock.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `GearSetLock.IsEnabled` | [L51](../../Respec/FluxRespec_GearSetLock.lua#L51) |
| `GearSetLock.SetEnabled` | [L62](../../Respec/FluxRespec_GearSetLock.lua#L62) |
| `GearSetLock.GetProtectedSlotCount` | [L74](../../Respec/FluxRespec_GearSetLock.lua#L74) |
| `GearSetLock.IsInventorySlotProtected` | [L78](../../Respec/FluxRespec_GearSetLock.lua#L78) |
| `GearSetLock.IsSlotProtected` | [L89](../../Respec/FluxRespec_GearSetLock.lua#L89) |
| `GearSetLock.NotifyBlocked` | [L101](../../Respec/FluxRespec_GearSetLock.lua#L101) |
| `GearSetLock.IsMerchantSellContext` | [L107](../../Respec/FluxRespec_GearSetLock.lua#L107) |
| `GearSetLock.IsSalvageDisenchantHoverContext` | [L188](../../Respec/FluxRespec_GearSetLock.lua#L188) |
| `GearSetLock.IsManualDisenchantTargeting` | [L204](../../Respec/FluxRespec_GearSetLock.lua#L204) |
| `GearSetLock.IsDisenchantContext` | [L223](../../Respec/FluxRespec_GearSetLock.lua#L223) |
| `GearSetLock.ShouldBlockContainerUse` | [L230](../../Respec/FluxRespec_GearSetLock.lua#L230) |
| `GearSetLock.ShouldBlockContainerPickup` | [L237](../../Respec/FluxRespec_GearSetLock.lua#L237) |
| `thenifguard.ShouldButtonPassThroughthenguard.ShouldButtonPassThrough` | [L323](../../Respec/FluxRespec_GearSetLock.lua#L323) |
| `GearSetLock.HideItemButtonClickGuard` | [L341](../../Respec/FluxRespec_GearSetLock.lua#L341) |
| `GearSetLock.UpdateItemButtonClickGuard` | [L348](../../Respec/FluxRespec_GearSetLock.lua#L348) |
| `GearSetLock.ResolveBagSlotFromOwner` | [L403](../../Respec/FluxRespec_GearSetLock.lua#L403) |
| `GearSetLock.ResolveBagSlotFromTooltip` | [L426](../../Respec/FluxRespec_GearSetLock.lua#L426) |
| `GearSetLock.Rebuild` | [L524](../../Respec/FluxRespec_GearSetLock.lua#L524) |
| `GearSetLock.WithContextSnapshot` | [L596](../../Respec/FluxRespec_GearSetLock.lua#L596) |
| `GearSetLock.ShouldShowManualInventoryClickGuard` | [L652](../../Respec/FluxRespec_GearSetLock.lua#L652) |
| `GearSetLock.GetManualInventoryClickGuardMode` | [L662](../../Respec/FluxRespec_GearSetLock.lua#L662) |
| `GearSetLock.ShouldShowManualClickGuard` | [L666](../../Respec/FluxRespec_GearSetLock.lua#L666) |
| `GearSetLock.ShouldShowShieldVisual` | [L689](../../Respec/FluxRespec_GearSetLock.lua#L689) |
| `GearSetLock.GetManualClickGuardModeForSlot` | [L693](../../Respec/FluxRespec_GearSetLock.lua#L693) |
| `GearSetLock.GetManualClickGuardMode` | [L717](../../Respec/FluxRespec_GearSetLock.lua#L717) |

### Respec/FluxRespec_GearSetOverlay.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `GearOverlay.SetEnabled` | [L198](../../Respec/FluxRespec_GearSetOverlay.lua#L198) |
| `GearOverlay.IsEnabled` | [L203](../../Respec/FluxRespec_GearSetOverlay.lua#L203) |
| `GearOverlay.ApplyDispatchContext` | [L208](../../Respec/FluxRespec_GearSetOverlay.lua#L208) |
| `GearOverlay.ApplyBankInternalContext` | [L211](../../Respec/FluxRespec_GearSetOverlay.lua#L211) |

### Respec/FluxRespec_GearSetTooltip.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `GearSetLock.DecorateProtectedInventoryTooltip` | [L115](../../Respec/FluxRespec_GearSetTooltip.lua#L115) |
| `GearSetLock.DecorateProtectedTooltip` | [L145](../../Respec/FluxRespec_GearSetTooltip.lua#L145) |
| `GearSetLock.InstallTooltipHooks` | [L276](../../Respec/FluxRespec_GearSetTooltip.lua#L276) |

### Respec/FluxRespec_IconPicker.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Picker.RefreshIconsOnly` | [L164](../../Respec/FluxRespec_IconPicker.lua#L164) |
| `Picker.Refresh` | [L377](../../Respec/FluxRespec_IconPicker.lua#L377) |
| `Picker.Open` | [L450](../../Respec/FluxRespec_IconPicker.lua#L450) |
| `Picker.Close` | [L468](../../Respec/FluxRespec_IconPicker.lua#L468) |

### Respec/FluxRespec_Includes.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Includes.Ensure` | [L112](../../Respec/FluxRespec_Includes.lua#L112) |
| `Includes.EnsureEquipmentPreset` | [L141](../../Respec/FluxRespec_Includes.lua#L141) |
| `Includes.EnsureRunePreset` | [L155](../../Respec/FluxRespec_Includes.lua#L155) |
| `Includes.MigrateAll` | [L166](../../Respec/FluxRespec_Includes.lua#L166) |
| `Includes.GetDraft` | [L195](../../Respec/FluxRespec_Includes.lua#L195) |
| `Includes.SectionOwner` | [L210](../../Respec/FluxRespec_Includes.lua#L210) |
| `Includes.ApplyDraftToProfile` | [L220](../../Respec/FluxRespec_Includes.lua#L220) |
| `Includes.SectionEnabled` | [L239](../../Respec/FluxRespec_Includes.lua#L239) |
| `Includes.SetSection` | [L251](../../Respec/FluxRespec_Includes.lua#L251) |
| `Includes.EquipSlotEnabled` | [L273](../../Respec/FluxRespec_Includes.lua#L273) |
| `Includes.SetEquipSlot` | [L285](../../Respec/FluxRespec_Includes.lua#L285) |
| `Includes.RuneSlotEnabled` | [L297](../../Respec/FluxRespec_Includes.lua#L297) |
| `Includes.SetRuneSlot` | [L309](../../Respec/FluxRespec_Includes.lua#L309) |
| `Includes.PresetEquipSlotEnabled` | [L321](../../Respec/FluxRespec_Includes.lua#L321) |
| `Includes.SetPresetEquipSlot` | [L329](../../Respec/FluxRespec_Includes.lua#L329) |
| `Includes.PresetRuneSlotEnabled` | [L342](../../Respec/FluxRespec_Includes.lua#L342) |
| `Includes.SetPresetRuneSlot` | [L350](../../Respec/FluxRespec_Includes.lua#L350) |
| `Includes.ActiveEquipmentPreset` | [L364](../../Respec/FluxRespec_Includes.lua#L364) |
| `Includes.ActiveRunePreset` | [L381](../../Respec/FluxRespec_Includes.lua#L381) |
| `Includes.GearStripOwner` | [L399](../../Respec/FluxRespec_Includes.lua#L399) |
| `Includes.RuneStripOwner` | [L412](../../Respec/FluxRespec_Includes.lua#L412) |
| `Includes.GearStripSlotEnabled` | [L425](../../Respec/FluxRespec_Includes.lua#L425) |
| `Includes.SetGearStripSlot` | [L436](../../Respec/FluxRespec_Includes.lua#L436) |
| `Includes.RuneStripSlotEnabled` | [L447](../../Respec/FluxRespec_Includes.lua#L447) |
| `Includes.SetRuneStripSlot` | [L458](../../Respec/FluxRespec_Includes.lua#L458) |
| `Includes.CopyEnabledEquipment` | [L484](../../Respec/FluxRespec_Includes.lua#L484) |
| `Includes.CopyEnabledPresetEquipment` | [L499](../../Respec/FluxRespec_Includes.lua#L499) |
| `Includes.CopyEnabledRunes` | [L512](../../Respec/FluxRespec_Includes.lua#L512) |
| `Includes.CopyEnabledPresetRunes` | [L527](../../Respec/FluxRespec_Includes.lua#L527) |
| `Includes.MergeEnabledEquipment` | [L541](../../Respec/FluxRespec_Includes.lua#L541) |
| `Includes.MergeEnabledPresetEquipment` | [L556](../../Respec/FluxRespec_Includes.lua#L556) |
| `Includes.MergeEnabledRunes` | [L575](../../Respec/FluxRespec_Includes.lua#L575) |
| `Includes.MergeEnabledPresetRunes` | [L589](../../Respec/FluxRespec_Includes.lua#L589) |
| `Includes.WantedEquipmentSlotSet` | [L607](../../Respec/FluxRespec_Includes.lua#L607) |
| `Includes.WantedPresetEquipmentSlotSet` | [L622](../../Respec/FluxRespec_Includes.lua#L622) |
| `Includes.GetBlizzardSet` | [L637](../../Respec/FluxRespec_Includes.lua#L637) |
| `Includes.InfoFrameMatches` | [L665](../../Respec/FluxRespec_Includes.lua#L665) |
| `Includes.InfoFrameSummary` | [L704](../../Respec/FluxRespec_Includes.lua#L704) |

### Respec/FluxRespec_Inv.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `RI.API` | [L29](../../Respec/FluxRespec_Inv.lua#L29) |
| `RI.IsReady` | [L33](../../Respec/FluxRespec_Inv.lua#L33) |
| `RI.IsBankOpen` | [L38](../../Respec/FluxRespec_Inv.lua#L38) |
| `RI.IsBankLive` | [L43](../../Respec/FluxRespec_Inv.lua#L43) |
| `RI.CanTakeFromBank` | [L52](../../Respec/FluxRespec_Inv.lua#L52) |
| `RI.HasCachedBank` | [L61](../../Respec/FluxRespec_Inv.lua#L61) |
| `RI.GetCachedBankCount` | [L82](../../Respec/FluxRespec_Inv.lua#L82) |
| `RI.HasWarband` | [L99](../../Respec/FluxRespec_Inv.lua#L99) |
| `RI.GetBagIDs` | [L104](../../Respec/FluxRespec_Inv.lua#L104) |
| `RI.GetBankIDs` | [L112](../../Respec/FluxRespec_Inv.lua#L112) |
| `RI.GetGeneration` | [L142](../../Respec/FluxRespec_Inv.lua#L142) |
| `RI.GetBagGeneration` | [L151](../../Respec/FluxRespec_Inv.lua#L151) |
| `RI.Find` | [L207](../../Respec/FluxRespec_Inv.lua#L207) |
| `RI.ForEachLocation` | [L225](../../Respec/FluxRespec_Inv.lua#L225) |
| `RI.GetFirstFreeBagSlot` | [L240](../../Respec/FluxRespec_Inv.lua#L240) |
| `RI.GetItemID` | [L262](../../Respec/FluxRespec_Inv.lua#L262) |
| `RI.GetItemLink` | [L276](../../Respec/FluxRespec_Inv.lua#L276) |
| `RI.IsMerchantOpen` | [L290](../../Respec/FluxRespec_Inv.lua#L290) |
| `RI.Register` | [L348](../../Respec/FluxRespec_Inv.lua#L348) |
| `RI.Unregister` | [L360](../../Respec/FluxRespec_Inv.lua#L360) |

### Respec/FluxRespec_PresetBundle.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Bundle.GetActiveGroup` | [L14](../../Respec/FluxRespec_PresetBundle.lua#L14) |
| `Bundle.GroupLabel` | [L24](../../Respec/FluxRespec_PresetBundle.lua#L24) |
| `Bundle.SkipBarsOnClient` | [L33](../../Respec/FluxRespec_PresetBundle.lua#L33) |
| `Bundle.MigrateLegacyBars` | [L37](../../Respec/FluxRespec_PresetBundle.lua#L37) |
| `Bundle.MigrateLegacyBarsTalent` | [L48](../../Respec/FluxRespec_PresetBundle.lua#L48) |
| `Bundle.MigrateLegacySpellBook` | [L55](../../Respec/FluxRespec_PresetBundle.lua#L55) |
| `Bundle.MigratePreset` | [L84](../../Respec/FluxRespec_PresetBundle.lua#L84) |
| `Bundle.CaptureTalentSnapshot` | [L118](../../Respec/FluxRespec_PresetBundle.lua#L118) |
| `Bundle.TalentTreeLabel` | [L125](../../Respec/FluxRespec_PresetBundle.lua#L125) |
| `Bundle.PresetHasAnyBars` | [L150](../../Respec/FluxRespec_PresetBundle.lua#L150) |
| `Bundle.PresetBarsTalentMatchesAnySpec` | [L162](../../Respec/FluxRespec_PresetBundle.lua#L162) |
| `Bundle.ResolveBarsBundleForPreset` | [L184](../../Respec/FluxRespec_PresetBundle.lua#L184) |
| `Bundle.GetPrimaryTalentSnapshotForPreset` | [L231](../../Respec/FluxRespec_PresetBundle.lua#L231) |
| `Bundle.ApplyBarsSnapshot` | [L250](../../Respec/FluxRespec_PresetBundle.lua#L250) |
| `Bundle.SaveBarsForActiveGroup` | [L258](../../Respec/FluxRespec_PresetBundle.lua#L258) |
| `Bundle.ApplyBarsForActiveGroup` | [L269](../../Respec/FluxRespec_PresetBundle.lua#L269) |
| `Bundle.HasBarsForActiveGroup` | [L277](../../Respec/FluxRespec_PresetBundle.lua#L277) |
| `Bundle.SaveSpellBookForActiveGroup` | [L284](../../Respec/FluxRespec_PresetBundle.lua#L284) |
| `Bundle.ApplySpellBookForActiveGroup` | [L296](../../Respec/FluxRespec_PresetBundle.lua#L296) |
| `Bundle.HasSpellBookForActiveGroup` | [L305](../../Respec/FluxRespec_PresetBundle.lua#L305) |
| `Bundle.SaveSuffixForActiveGroup` | [L313](../../Respec/FluxRespec_PresetBundle.lua#L313) |

### Respec/FluxRespec_Register.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Register.AddTab` | [L11](../../Respec/FluxRespec_Register.lua#L11) |

### Respec/FluxRespec_RunePicker.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `P.GetExtraScrollBottom` | [L26](../../Respec/FluxRespec_RunePicker.lua#L26) |
| `P.CancelHideTimer` | [L66](../../Respec/FluxRespec_RunePicker.lua#L66) |
| `P.CancelShowTimer` | [L70](../../Respec/FluxRespec_RunePicker.lua#L70) |
| `P.IsOpenFor` | [L74](../../Respec/FluxRespec_RunePicker.lua#L74) |
| `P.HasAlternatives` | [L121](../../Respec/FluxRespec_RunePicker.lua#L121) |
| `P.Hide` | [L125](../../Respec/FluxRespec_RunePicker.lua#L125) |
| `P.NotifyStripEnter` | [L146](../../Respec/FluxRespec_RunePicker.lua#L146) |
| `P.NotifyStripLeave` | [L165](../../Respec/FluxRespec_RunePicker.lua#L165) |
| `P.ScheduleHideSoon` | [L170](../../Respec/FluxRespec_RunePicker.lua#L170) |
| `P.Show` | [L187](../../Respec/FluxRespec_RunePicker.lua#L187) |

### Respec/FluxRespec_RunePresets.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Presets.GetBarsApplyChoice` | [L21](../../Respec/FluxRespec_RunePresets.lua#L21) |
| `Presets.SetBarsApplyChoice` | [L25](../../Respec/FluxRespec_RunePresets.lua#L25) |
| `Presets.ShouldSkipBarsOnClient` | [L33](../../Respec/FluxRespec_RunePresets.lua#L33) |
| `Presets.NeedsBarsConfirm` | [L46](../../Respec/FluxRespec_RunePresets.lua#L46) |
| `Presets.ShouldSaveBarsForActivePreset` | [L70](../../Respec/FluxRespec_RunePresets.lua#L70) |
| `Presets.ShouldApplyBarsForPreset` | [L80](../../Respec/FluxRespec_RunePresets.lua#L80) |
| `Presets.ApplyBarsForPreset` | [L97](../../Respec/FluxRespec_RunePresets.lua#L97) |
| `Presets.EnsureStore` | [L134](../../Respec/FluxRespec_RunePresets.lua#L134) |
| `Presets.GetActivePreset` | [L142](../../Respec/FluxRespec_RunePresets.lua#L142) |
| `Presets.SetActivePreset` | [L146](../../Respec/FluxRespec_RunePresets.lua#L146) |
| `Presets.GetPresetNames` | [L159](../../Respec/FluxRespec_RunePresets.lua#L159) |
| `Presets.GetPreset` | [L173](../../Respec/FluxRespec_RunePresets.lua#L173) |
| `Presets.CreatePreset` | [L184](../../Respec/FluxRespec_RunePresets.lua#L184) |
| `Presets.DeletePreset` | [L203](../../Respec/FluxRespec_RunePresets.lua#L203) |
| `Presets.SaveActivePresetFromLive` | [L223](../../Respec/FluxRespec_RunePresets.lua#L223) |
| `Presets.Apply` | [L313](../../Respec/FluxRespec_RunePresets.lua#L313) |
| `Presets.ApplyAndStartEngrave` | [L392](../../Respec/FluxRespec_RunePresets.lua#L392) |
| `Presets.LinkProfilePreset` | [L414](../../Respec/FluxRespec_RunePresets.lua#L414) |
| `Presets.OnApplyQueueStarted` | [L433](../../Respec/FluxRespec_RunePresets.lua#L433) |
| `Presets.GetActivePresetRunes` | [L472](../../Respec/FluxRespec_RunePresets.lua#L472) |
| `Presets.PresetRunesMatchLive` | [L487](../../Respec/FluxRespec_RunePresets.lua#L487) |
| `Presets.GetActivePresetRuneDiffCount` | [L506](../../Respec/FluxRespec_RunePresets.lua#L506) |
| `Presets.GetTargetRunesSnapshotForStrip` | [L520](../../Respec/FluxRespec_RunePresets.lua#L520) |
| `Presets.GetTargetRunesSnapshot` | [L546](../../Respec/FluxRespec_RunePresets.lua#L546) |
| `Presets.GetTargetRunesSnapshotForProfile` | [L555](../../Respec/FluxRespec_RunePresets.lua#L555) |
| `Presets.MatchesProfileLink` | [L564](../../Respec/FluxRespec_RunePresets.lua#L564) |
| `Presets.IsDefault` | [L576](../../Respec/FluxRespec_RunePresets.lua#L576) |
| `Presets.GetTargetRuneDiffCount` | [L581](../../Respec/FluxRespec_RunePresets.lua#L581) |
| `Presets.HandleFlyoutPick` | [L596](../../Respec/FluxRespec_RunePresets.lua#L596) |
| `Presets.ShouldPreserveProfileRunesOnSave` | [L610](../../Respec/FluxRespec_RunePresets.lua#L610) |
| `Presets.AdvanceEngrave` | [L635](../../Respec/FluxRespec_RunePresets.lua#L635) |
| `Presets.ShouldShowUnitFrameRuneGlow` | [L662](../../Respec/FluxRespec_RunePresets.lua#L662) |

### Respec/FluxRespec_Runes.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Runes.Capture` | [L87](../../Respec/FluxRespec_Runes.lua#L87) |
| `Runes.BuildQueue` | [L116](../../Respec/FluxRespec_Runes.lua#L116) |
| `Runes.DiffCount` | [L144](../../Respec/FluxRespec_Runes.lua#L144) |
| `Runes.SlotMatchesSnapshot` | [L150](../../Respec/FluxRespec_Runes.lua#L150) |
| `Runes.EngraveFromProfileSlot` | [L161](../../Respec/FluxRespec_Runes.lua#L161) |
| `Runes.HasActiveQueue` | [L213](../../Respec/FluxRespec_Runes.lua#L213) |
| `Runes.HeadBlockedByProfileGear` | [L219](../../Respec/FluxRespec_Runes.lua#L219) |
| `Runes.GetActiveQueue` | [L241](../../Respec/FluxRespec_Runes.lua#L241) |
| `Runes.ClearQueue` | [L245](../../Respec/FluxRespec_Runes.lua#L245) |
| `Runes.StartQueue` | [L252](../../Respec/FluxRespec_Runes.lua#L252) |
| `Runes.CastNext` | [L299](../../Respec/FluxRespec_Runes.lua#L299) |
| `Runes.CastSkillLineOnSlot` | [L350](../../Respec/FluxRespec_Runes.lua#L350) |
| `Runes.Apply` | [L382](../../Respec/FluxRespec_Runes.lua#L382) |

### Respec/FluxRespec_Talents.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Talents.ReadGroup` | [L56](../../Respec/FluxRespec_Talents.lua#L56) |
| `Talents.SpecIconFromSnapshot` | [L78](../../Respec/FluxRespec_Talents.lua#L78) |
| `Talents.LiveSummaryForUI` | [L207](../../Respec/FluxRespec_Talents.lua#L207) |
| `Talents.ToggleDualSpecGroup` | [L231](../../Respec/FluxRespec_Talents.lua#L231) |
| `Talents.Capture` | [L242](../../Respec/FluxRespec_Talents.lua#L242) |
| `Talents.Matches` | [L285](../../Respec/FluxRespec_Talents.lua#L285) |
| `Talents.WouldSwitchSpec` | [L302](../../Respec/FluxRespec_Talents.lua#L302) |
| `Talents.FindMatchingGroupIndex` | [L319](../../Respec/FluxRespec_Talents.lua#L319) |
| `Talents.ComputeDelta` | [L365](../../Respec/FluxRespec_Talents.lua#L365) |
| `Talents.ComputeDeltaForGroup` | [L374](../../Respec/FluxRespec_Talents.lua#L374) |
| `Talents.CanApplyWithoutTrainerReset` | [L384](../../Respec/FluxRespec_Talents.lua#L384) |
| `Talents.AbortApply` | [L471](../../Respec/FluxRespec_Talents.lua#L471) |
| `Talents.SwitchToMatchingGroup` | [L791](../../Respec/FluxRespec_Talents.lua#L791) |
| `Talents.Apply` | [L852](../../Respec/FluxRespec_Talents.lua#L852) |
| `Talents.RememberUnlearnCost` | [L964](../../Respec/FluxRespec_Talents.lua#L964) |
| `Talents.SetTrainerPayPreauthorized` | [L975](../../Respec/FluxRespec_Talents.lua#L975) |
| `Talents.IsTrainerPayPreauthorized` | [L979](../../Respec/FluxRespec_Talents.lua#L979) |
| `Talents.ClearTrainerPayPreauth` | [L983](../../Respec/FluxRespec_Talents.lua#L983) |
| `Talents.GetTrainerUnlearnCostCopper` | [L988](../../Respec/FluxRespec_Talents.lua#L988) |
| `Talents.BuildNeedTrainerPopupText` | [L1015](../../Respec/FluxRespec_Talents.lua#L1015) |
| `Talents.SyncTrainerUnlearnQueueForActiveProfile` | [L1040](../../Respec/FluxRespec_Talents.lua#L1040) |

### Respec/FluxRespec_TalentsRetail.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `TR.Capture` | [L252](../../Respec/FluxRespec_TalentsRetail.lua#L252) |
| `TR.Matches` | [L334](../../Respec/FluxRespec_TalentsRetail.lua#L334) |
| `TR.WouldSwitchSpec` | [L423](../../Respec/FluxRespec_TalentsRetail.lua#L423) |
| `TR.AbortApply` | [L464](../../Respec/FluxRespec_TalentsRetail.lua#L464) |
| `TR.Apply` | [L837](../../Respec/FluxRespec_TalentsRetail.lua#L837) |
| `TR.SpecIconFromSnapshot` | [L912](../../Respec/FluxRespec_TalentsRetail.lua#L912) |
| `TR.LiveSummaryForUI` | [L924](../../Respec/FluxRespec_TalentsRetail.lua#L924) |
| `TR.CanApplyWithoutTrainerReset` | [L950](../../Respec/FluxRespec_TalentsRetail.lua#L950) |
| `TR.FindMatchingGroupIndex` | [L955](../../Respec/FluxRespec_TalentsRetail.lua#L955) |
| `TR.ToggleDualSpecGroup` | [L961](../../Respec/FluxRespec_TalentsRetail.lua#L961) |
| `TR.Summary` | [L966](../../Respec/FluxRespec_TalentsRetail.lua#L966) |

### Respec/FluxRespec_UI.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `UI.RefreshOnEquipChange` | [L1869](../../Respec/FluxRespec_UI.lua#L1869) |
| `dd.Refresh` | [L2009](../../Respec/FluxRespec_UI.lua#L2009) |
| `UI.SyncRespecScrollForFlyout` | [L2273](../../Respec/FluxRespec_UI.lua#L2273) |
| `UI.Refresh` | [L2668](../../Respec/FluxRespec_UI.lua#L2668) |
| `UI.Show` | [L3013](../../Respec/FluxRespec_UI.lua#L3013) |
| `UI.Hide` | [L3044](../../Respec/FluxRespec_UI.lua#L3044) |

### Respec/FluxRespec_UI_Gear.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Gear.AttachSlotChecks` | [L15](../../Respec/FluxRespec_UI_Gear.lua#L15) |
| `Gear.RefreshSlotChecks` | [L59](../../Respec/FluxRespec_UI_Gear.lua#L59) |

### Respec/FluxRespec_UI_Rows.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Rows.AttachAll` | [L13](../../Respec/FluxRespec_UI_Rows.lua#L13) |
| `Rows.RefreshAll` | [L43](../../Respec/FluxRespec_UI_Rows.lua#L43) |
| `Rows.MakeInfoFrameRow` | [L57](../../Respec/FluxRespec_UI_Rows.lua#L57) |
| `Rows.RefreshInfoFrame` | [L74](../../Respec/FluxRespec_UI_Rows.lua#L74) |

### Respec/FluxRespec_UI_Runes.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `RunesUI.AttachSlotChecks` | [L15](../../Respec/FluxRespec_UI_Runes.lua#L15) |
| `RunesUI.RefreshSlotChecks` | [L59](../../Respec/FluxRespec_UI_Runes.lua#L59) |

### Respec/FluxRespec_UI_Shared.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `UI.MakeIncludeCheck` | [L14](../../Respec/FluxRespec_UI_Shared.lua#L14) |
| `UI.WireIncludeTooltip` | [L29](../../Respec/FluxRespec_UI_Shared.lua#L29) |
| `UI.AttachSectionCheck` | [L43](../../Respec/FluxRespec_UI_Shared.lua#L43) |
| `UI.RefreshSectionCheck` | [L81](../../Respec/FluxRespec_UI_Shared.lua#L81) |
| `UI.AttachSlotIncludeCheck` | [L98](../../Respec/FluxRespec_UI_Shared.lua#L98) |
| `UI.SetSlotIncludeVisual` | [L110](../../Respec/FluxRespec_UI_Shared.lua#L110) |

### Salvage/FluxSalvage_Classify.lua

Owner: [22-salvage.md](../22-salvage.md).

| Declaration | Source |
|---|---|
| `S.IsCarriedBag` | [L55](../../Salvage/FluxSalvage_Classify.lua#L55) |
| `S.GetContainerItemID` | [L94](../../Salvage/FluxSalvage_Classify.lua#L94) |
| `S.GetContainerItemStackCount` | [L137](../../Salvage/FluxSalvage_Classify.lua#L137) |
| `S.KnowsSpell` | [L195](../../Salvage/FluxSalvage_Classify.lua#L195) |
| `S.InvalidateSpellCache` | [L199](../../Salvage/FluxSalvage_Classify.lua#L199) |
| `S.InvalidateClassifyCache` | [L206](../../Salvage/FluxSalvage_Classify.lua#L206) |
| `S.HintFromTooltipText` | [L312](../../Salvage/FluxSalvage_Classify.lua#L312) |
| `S.GetComprehendSpell` | [L442](../../Salvage/FluxSalvage_Classify.lua#L442) |
| `S.GetComprehendSpellID` | [L484](../../Salvage/FluxSalvage_Classify.lua#L484) |
| `S.IsComprehendSpell` | [L489](../../Salvage/FluxSalvage_Classify.lua#L489) |
| `S.IsComprehensible` | [L549](../../Salvage/FluxSalvage_Classify.lua#L549) |
| `S.IsProspectable` | [L578](../../Salvage/FluxSalvage_Classify.lua#L578) |
| `S.IsMillable` | [L598](../../Salvage/FluxSalvage_Classify.lua#L598) |
| `S.IsCrushable` | [L618](../../Salvage/FluxSalvage_Classify.lua#L618) |
| `S.IsScrappable` | [L626](../../Salvage/FluxSalvage_Classify.lua#L626) |
| `S.IsShatterable` | [L634](../../Salvage/FluxSalvage_Classify.lua#L634) |
| `S.IsTransmutable` | [L642](../../Salvage/FluxSalvage_Classify.lua#L642) |
| `S.NonDisenchantable` | [L650](../../Salvage/FluxSalvage_Classify.lua#L650) |
| `S.IsDisenchantable` | [L654](../../Salvage/FluxSalvage_Classify.lua#L654) |
| `S.IsOpenable` | [L701](../../Salvage/FluxSalvage_Classify.lua#L701) |
| `S.IsSalvageable` | [L735](../../Salvage/FluxSalvage_Classify.lua#L735) |
| `S.IsOpenableProfession` | [L794](../../Salvage/FluxSalvage_Classify.lua#L794) |
| `S.IsBagSlotProtected` | [L818](../../Salvage/FluxSalvage_Classify.lua#L818) |

### Salvage/FluxSalvage_Overlay.lua

Owner: [22-salvage.md](../22-salvage.md).

| Declaration | Source |
|---|---|
| `S.Defer` | [L88](../../Salvage/FluxSalvage_Overlay.lua#L88) |
| `S.DeferMethod` | [L96](../../Salvage/FluxSalvage_Overlay.lua#L96) |
| `S.AnchorOverlayToOwner` | [L144](../../Salvage/FluxSalvage_Overlay.lua#L144) |
| `S.ApplySpellToBagSlot` | [L316](../../Salvage/FluxSalvage_Overlay.lua#L316) |
| `S.ApplySpell` | [L333](../../Salvage/FluxSalvage_Overlay.lua#L333) |
| `S.ApplyItem` | [L367](../../Salvage/FluxSalvage_Overlay.lua#L367) |
| `S.UpdateAttributeDriver` | [L391](../../Salvage/FluxSalvage_Overlay.lua#L391) |
| `S.SetOverlayColor` | [L591](../../Salvage/FluxSalvage_Overlay.lua#L591) |
| `S.HideOverlay` | [L613](../../Salvage/FluxSalvage_Overlay.lua#L613) |
| `S.HandleTooltip` | [L680](../../Salvage/FluxSalvage_Overlay.lua#L680) |
| `S.OnModifierChanged` | [L776](../../Salvage/FluxSalvage_Overlay.lua#L776) |

### Salvage/FluxSalvage_Settings.lua

Owner: [22-salvage.md](../22-salvage.md).

| Declaration | Source |
|---|---|
| `S.IsEnabled` | [L20](../../Salvage/FluxSalvage_Settings.lua#L20) |
| `S.SetEnabled` | [L25](../../Salvage/FluxSalvage_Settings.lua#L25) |
| `S.GetModifier` | [L30](../../Salvage/FluxSalvage_Settings.lua#L30) |
| `S.SetModifier` | [L35](../../Salvage/FluxSalvage_Settings.lua#L35) |
| `S.RegisterModifierCallback` | [L43](../../Salvage/FluxSalvage_Settings.lua#L43) |
| `S.ModifierActive` | [L49](../../Salvage/FluxSalvage_Settings.lua#L49) |
| `S.ModifierReleased` | [L63](../../Salvage/FluxSalvage_Settings.lua#L63) |

### Salvage/FluxSalvage_Tooltip.lua

Owner: [22-salvage.md](../22-salvage.md).

| Declaration | Source |
|---|---|
| `S.ResolveBagSlotFromOwner` | [L17](../../Salvage/FluxSalvage_Tooltip.lua#L17) |
| `S.ResolveBagItem` | [L80](../../Salvage/FluxSalvage_Tooltip.lua#L80) |
| `S.ResolveItemID` | [L112](../../Salvage/FluxSalvage_Tooltip.lua#L112) |
| `S.HandleBagButton` | [L154](../../Salvage/FluxSalvage_Tooltip.lua#L154) |
| `S.HookBagButtons` | [L256](../../Salvage/FluxSalvage_Tooltip.lua#L256) |
| `S.HookTooltip` | [L282](../../Salvage/FluxSalvage_Tooltip.lua#L282) |

### StatusBars/FluxGoldLedger.lua

Owner: [16-status-bars.md](../16-status-bars.md).

| Declaration | Source |
|---|---|
| `G:LedgerKey` | [L124](../../StatusBars/FluxGoldLedger.lua#L124) |
| `G:CharKeyForPlayer` | [L128](../../StatusBars/FluxGoldLedger.lua#L128) |
| `G:FormatCopper` | [L416](../../StatusBars/FluxGoldLedger.lua#L416) |
| `G:SaveCurrentMoney` | [L900](../../StatusBars/FluxGoldLedger.lua#L900) |
| `G:InvalidateCache` | [L986](../../StatusBars/FluxGoldLedger.lua#L986) |
| `G:ShowAccountGoldTooltip` | [L991](../../StatusBars/FluxGoldLedger.lua#L991) |
| `G:GetSummedContext` | [L1053](../../StatusBars/FluxGoldLedger.lua#L1053) |
| `G:GetSortedRowsInScope` | [L1061](../../StatusBars/FluxGoldLedger.lua#L1061) |
| `G:OnAfterGoldBarUpdate` | [L1073](../../StatusBars/FluxGoldLedger.lua#L1073) |
| `G:AttachBagMoneyTooltip` | [L1084](../../StatusBars/FluxGoldLedger.lua#L1084) |
| `G:GetConfigLedgerIndex` | [L1196](../../StatusBars/FluxGoldLedger.lua#L1196) |
| `G:DeleteLedgerEntryByKey` | [L1264](../../StatusBars/FluxGoldLedger.lua#L1264) |
| `G:ConsolidateDuplicateGoldLedger` | [L1294](../../StatusBars/FluxGoldLedger.lua#L1294) |

### StatusBars/FluxInfoFrame.lua

Owner: [16-status-bars.md](../16-status-bars.md).

| Declaration | Source |
|---|---|
| `InfoFrame.GetCharDB` | [L142](../../StatusBars/FluxInfoFrame.lua#L142) |
| `InfoFrame.SerializeRespecProfileSnapshot` | [L147](../../StatusBars/FluxInfoFrame.lua#L147) |
| `InfoFrame._IsCamelotClient` | [L186](../../StatusBars/FluxInfoFrame.lua#L186) |
| `InfoFrame._CamelotCombatStatKey` | [L211](../../StatusBars/FluxInfoFrame.lua#L211) |
| `InfoFrame._FoldCamelotCombatPins` | [L218](../../StatusBars/FluxInfoFrame.lua#L218) |
| `InfoFrame._CamelotCombatStatValue` | [L250](../../StatusBars/FluxInfoFrame.lua#L250) |
| `InfoFrame._CamelotLiveCombatText` | [L312](../../StatusBars/FluxInfoFrame.lua#L312) |
| `InfoFrame._RenderCamelotLiveText` | [L366](../../StatusBars/FluxInfoFrame.lua#L366) |
| `InfoFrame._ClassicSpellPinKey` | [L568](../../StatusBars/FluxInfoFrame.lua#L568) |
| `InfoFrame._UseClassicSpellPowerLine` | [L591](../../StatusBars/FluxInfoFrame.lua#L591) |
| `InfoFrame._FoldClassicSpellPins` | [L598](../../StatusBars/FluxInfoFrame.lua#L598) |
| `InfoFrame._PlainStatNumber` | [L640](../../StatusBars/FluxInfoFrame.lua#L640) |
| `InfoFrame._EnsureCamelotSpellSnapshotHooks` | [L666](../../StatusBars/FluxInfoFrame.lua#L666) |
| `InfoFrame._CamelotSpellBonus` | [L673](../../StatusBars/FluxInfoFrame.lua#L673) |
| `InfoFrame._ClassicSpellDamageColorHex` | [L741](../../StatusBars/FluxInfoFrame.lua#L741) |
| `.get` | [L1205](../../StatusBars/FluxInfoFrame.lua#L1205) |
| `InfoFrame.GetStatRegistry` | [L1536](../../StatusBars/FluxInfoFrame.lua#L1536) |
| `InfoFrame._RefreshCamelotLiveText` | [L1545](../../StatusBars/FluxInfoFrame.lua#L1545) |
| `InfoFrame.RefreshIntegratedStripBackdrop` | [L1610](../../StatusBars/FluxInfoFrame.lua#L1610) |
| `InfoFrame.IsDockedToActionStrip` | [L1629](../../StatusBars/FluxInfoFrame.lua#L1629) |
| `InfoFrame.GetEffectivePlacement` | [L1633](../../StatusBars/FluxInfoFrame.lua#L1633) |
| `InfoFrame.SetAnchoredByStatusBarColumn` | [L1638](../../StatusBars/FluxInfoFrame.lua#L1638) |
| `_GetTooltipMeasureFS` | [L2878](../../StatusBars/FluxInfoFrame.lua#L2878) |
| `_MeasureTooltipTextWidth` | [L2890](../../StatusBars/FluxInfoFrame.lua#L2890) |
| `_SplitMergedSegments` | [L2901](../../StatusBars/FluxInfoFrame.lua#L2901) |
| `_BuildTooltipLabelKeyMap` | [L2921](../../StatusBars/FluxInfoFrame.lua#L2921) |
| `_StripTooltipCodes` | [L2949](../../StatusBars/FluxInfoFrame.lua#L2949) |
| `_InferKeyFromSegmentText` | [L2954](../../StatusBars/FluxInfoFrame.lua#L2954) |
| `_ResolveTooltipKeysForEntry` | [L2967](../../StatusBars/FluxInfoFrame.lua#L2967) |
| `_BuildSegmentSpansForEntry` | [L2993](../../StatusBars/FluxInfoFrame.lua#L2993) |
| `_GetHoveredKeyFromEntryFS` | [L3107](../../StatusBars/FluxInfoFrame.lua#L3107) |
| `_PositionFluxInfoTooltipAnchor` | [L3229](../../StatusBars/FluxInfoFrame.lua#L3229) |
| `gt.SetOwnergt.SetOwner` | [L3281](../../StatusBars/FluxInfoFrame.lua#L3281) |
| `_InvalidateTooltipStatFrameCache` | [L3325](../../StatusBars/FluxInfoFrame.lua#L3325) |
| `_G.FluxAutoRepairEnabled` | [L3329](../../StatusBars/FluxInfoFrame.lua#L3329) |
| `_G.FluxToggleAutoRepair` | [L3338](../../StatusBars/FluxInfoFrame.lua#L3338) |
| `_SetDurabilityRepairTooltip` | [L3354](../../StatusBars/FluxInfoFrame.lua#L3354) |
| `_SetCompactPairTooltip` | [L3422](../../StatusBars/FluxInfoFrame.lua#L3422) |
| `_SetEquipmentRatingTooltip` | [L3432](../../StatusBars/FluxInfoFrame.lua#L3432) |
| `_GetCompactInfoPairValues` | [L3450](../../StatusBars/FluxInfoFrame.lua#L3450) |
| `_GetTooltipSourceStatFrames` | [L3471](../../StatusBars/FluxInfoFrame.lua#L3471) |
| `_GetTooltipSourceStatFrame` | [L3499](../../StatusBars/FluxInfoFrame.lua#L3499) |
| `InfoFrame._CharacterPanelStatNumber` | [L3505](../../StatusBars/FluxInfoFrame.lua#L3505) |
| `InfoFrame._ShowCamelotSpellPinTooltip` | [L3526](../../StatusBars/FluxInfoFrame.lua#L3526) |
| `_ShowInfoTooltipForKey` | [L3616](../../StatusBars/FluxInfoFrame.lua#L3616) |
| `InfoFrame.StatLabel` | [L3836](../../StatusBars/FluxInfoFrame.lua#L3836) |
| `InfoFrame._CollectVisibleStatKeys` | [L3868](../../StatusBars/FluxInfoFrame.lua#L3868) |
| `InfoFrame._NormalizeStatOrder` | [L3923](../../StatusBars/FluxInfoFrame.lua#L3923) |
| `InfoFrame.HasVisibleLines` | [L3959](../../StatusBars/FluxInfoFrame.lua#L3959) |
| `InfoFrame.GetOrderedVisibleStats` | [L3975](../../StatusBars/FluxInfoFrame.lua#L3975) |
| `InfoFrame.SetStatOrder` | [L4000](../../StatusBars/FluxInfoFrame.lua#L4000) |
| `InfoFrame._FlushPlayerStatRefresh` | [L4239](../../StatusBars/FluxInfoFrame.lua#L4239) |
| `InfoFrame.RequestStatRefresh` | [L4246](../../StatusBars/FluxInfoFrame.lua#L4246) |
| `InfoFrame.PrepareIntegratedStripLayout` | [L4302](../../StatusBars/FluxInfoFrame.lua#L4302) |
| `InfoFrame.PositionActionStripSlotFrame` | [L4439](../../StatusBars/FluxInfoFrame.lua#L4439) |
| `InfoFrame._LayoutScreenTopLeft` | [L4508](../../StatusBars/FluxInfoFrame.lua#L4508) |
| `InfoFrame.GetFrame` | [L5089](../../StatusBars/FluxInfoFrame.lua#L5089) |
| `InfoFrame.GetStableIntegratedColumnWidth` | [L5094](../../StatusBars/FluxInfoFrame.lua#L5094) |
| `InfoFrame.ForceUpdatePosition` | [L5106](../../StatusBars/FluxInfoFrame.lua#L5106) |
| `InfoFrame.ForceRebuild` | [L5127](../../StatusBars/FluxInfoFrame.lua#L5127) |
| `InfoFrame.TogglePinnedStat` | [L5150](../../StatusBars/FluxInfoFrame.lua#L5150) |
| `InfoFrame.IsStatPinned` | [L5226](../../StatusBars/FluxInfoFrame.lua#L5226) |
| `_RebuildTooltipStatFrameCache` | [L5905](../../StatusBars/FluxInfoFrame.lua#L5905) |
| `InfoFrame.ResolveStatFramesForTooltip` | [L5973](../../StatusBars/FluxInfoFrame.lua#L5973) |
| `InfoFrame.RefreshAllPinIndicators` | [L6019](../../StatusBars/FluxInfoFrame.lua#L6019) |
| `InfoFrame.ApplyRespecProfileSnapshot` | [L6024](../../StatusBars/FluxInfoFrame.lua#L6024) |
| `InfoFrame.HookClassicCSCStatFrame` | [L6068](../../StatusBars/FluxInfoFrame.lua#L6068) |
| `InfoFrame.HookRetailPaperDollStatFrame` | [L6077](../../StatusBars/FluxInfoFrame.lua#L6077) |
| `InfoFrame.HookRetailPaperDollPoolStatFrame` | [L6088](../../StatusBars/FluxInfoFrame.lua#L6088) |
| `InfoFrame.ReadForeverDisplayText` | [L6101](../../StatusBars/FluxInfoFrame.lua#L6101) |
| `InfoFrame.RememberPinnedStatValue` | [L6152](../../StatusBars/FluxInfoFrame.lua#L6152) |
| `InfoFrame.HookForeverScrollBoxStatFrame` | [L6196](../../StatusBars/FluxInfoFrame.lua#L6196) |
| `InfoFrame.InstallRetailPaperDollHooks` | [L6224](../../StatusBars/FluxInfoFrame.lua#L6224) |
| `InfoFrame.AfterCharacterShown` | [L6230](../../StatusBars/FluxInfoFrame.lua#L6230) |
| `InfoFrame._StartCamelotCharacterWatch` | [L6238](../../StatusBars/FluxInfoFrame.lua#L6238) |
| `InfoFrame.InstallCharacterInfoPinHooks` | [L6270](../../StatusBars/FluxInfoFrame.lua#L6270) |

### StatusBars/FluxItemCurrencyTracking.lua

Owner: [16-status-bars.md](../16-status-bars.md).

| Declaration | Source |
|---|---|
| `FluxItemCurrencyTracking.MaintainItemCurrencySlotList` | [L15](../../StatusBars/FluxItemCurrencyTracking.lua#L15) |
| `FluxItemCurrencyTracking.EnsureItemCurrencyData` | [L61](../../StatusBars/FluxItemCurrencyTracking.lua#L61) |
| `FluxItemCurrencyTracking.NotifyItemCurrencyChanged` | [L95](../../StatusBars/FluxItemCurrencyTracking.lua#L95) |
| `FluxItemCurrencyTracking.GetItemIdFromCursor` | [L112](../../StatusBars/FluxItemCurrencyTracking.lua#L112) |
| `FluxItemCurrencyTracking.AcceptItemDropOnCurrencyBar` | [L153](../../StatusBars/FluxItemCurrencyTracking.lua#L153) |
| `FluxItemCurrencyTracking.ClearItemCurrencySlot` | [L184](../../StatusBars/FluxItemCurrencyTracking.lua#L184) |
| `FluxItemCurrencyTracking.GetItemIcon` | [L330](../../StatusBars/FluxItemCurrencyTracking.lua#L330) |
| `FluxItemCurrencyTracking.EnsureTrackedIconsLoaded` | [L390](../../StatusBars/FluxItemCurrencyTracking.lua#L390) |
| `FluxItemCurrencyTracking.GetText` | [L437](../../StatusBars/FluxItemCurrencyTracking.lua#L437) |
| `FluxItemCurrencyTracking.GetGoldTextBlockWidth` | [L442](../../StatusBars/FluxItemCurrencyTracking.lua#L442) |
| `FluxItemCurrencyTracking.AnchorGoldBarTextBlock` | [L494](../../StatusBars/FluxItemCurrencyTracking.lua#L494) |
| `FluxItemCurrencyTracking.LayoutGoldItemHovers` | [L625](../../StatusBars/FluxItemCurrencyTracking.lua#L625) |

### StatusBars/FluxPVPTracking.lua

Owner: [16-status-bars.md](../16-status-bars.md).

| Declaration | Source |
|---|---|
| `endendFluxPVPTracking.GetTrackedPVPText` | [L309](../../StatusBars/FluxPVPTracking.lua#L309) |
| `endFluxPVPTracking.ShouldEnable` | [L343](../../StatusBars/FluxPVPTracking.lua#L343) |
| `FluxPVPTracking.SyncHonorArenaCheckboxesFromSavedVars` | [L351](../../StatusBars/FluxPVPTracking.lua#L351) |

### StatusBars/FluxStatusBar.lua

Owner: [16-status-bars.md](../16-status-bars.md).

| Declaration | Source |
|---|---|
| `UpdateExpBar` | [L1766](../../StatusBars/FluxStatusBar.lua#L1766) |
| `UpdateFluxDurabilityFramePosition` | [L2310](../../StatusBars/FluxStatusBar.lua#L2310) |
| `_G.FluxStatusBar_GetLocation2MinBottomOffset` | [L2406](../../StatusBars/FluxStatusBar.lua#L2406) |
| `_G.FluxStatusBar_GetBottomOverlayHeight` | [L2427](../../StatusBars/FluxStatusBar.lua#L2427) |
| `_G.FluxStatusBar_GetBottomOverlayHeightForAlignedChrome` | [L2446](../../StatusBars/FluxStatusBar.lua#L2446) |
| `UpdateLayout` | [L2635](../../StatusBars/FluxStatusBar.lua#L2635) |
| `endend_G.FluxStatusBarUpdateLayout` | [L3113](../../StatusBars/FluxStatusBar.lua#L3113) |

### UnitFrames/FluxCastBar.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `CB.StopCustomTimer` | [L1794](../../UnitFrames/FluxCastBar.lua#L1794) |
| `CB.StartCustomTimer` | [L1800](../../UnitFrames/FluxCastBar.lua#L1800) |
| `CB.RefreshCastForUnit` | [L2207](../../UnitFrames/FluxCastBar.lua#L2207) |
| `CB.CreateCastBar` | [L2689](../../UnitFrames/FluxCastBar.lua#L2689) |
| `castBar.SetValue` | [L2713](../../UnitFrames/FluxCastBar.lua#L2713) |
| `endcastBar.GetValue` | [L2714](../../UnitFrames/FluxCastBar.lua#L2714) |
| `endcastBar.SetMinMaxValues` | [L2715](../../UnitFrames/FluxCastBar.lua#L2715) |
| `endcastBar.GetMinMaxValues` | [L2716](../../UnitFrames/FluxCastBar.lua#L2716) |
| `endcastBar.SetStatusBarColor` | [L2717](../../UnitFrames/FluxCastBar.lua#L2717) |
| `endcastBar.SetStatusBarTexture` | [L2718](../../UnitFrames/FluxCastBar.lua#L2718) |
| `endcastBar.GetStatusBarTexture` | [L2719](../../UnitFrames/FluxCastBar.lua#L2719) |
| `endiftimerBar.SetTimerDurationthencastBar.SetTimerDuration` | [L2730](../../UnitFrames/FluxCastBar.lua#L2730) |
| `endendiftimerBar.GetTimerDurationthencastBar.GetTimerDuration` | [L2733](../../UnitFrames/FluxCastBar.lua#L2733) |
| `RegisterUnitCastEventscastBar.DisablePetCastBar` | [L2901](../../UnitFrames/FluxCastBar.lua#L2901) |
| `endcastBar.UpdateLayout` | [L3102](../../UnitFrames/FluxCastBar.lua#L3102) |
| `CB.SyncBlizzardCastBars` | [L3424](../../UnitFrames/FluxCastBar.lua#L3424) |
| `FluxCastBar_ApplyAppearanceAccent` | [L3455](../../UnitFrames/FluxCastBar.lua#L3455) |

### UnitFrames/FluxCastBarSchools.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `Schools.Resolve` | [L69](../../UnitFrames/FluxCastBarSchools.lua#L69) |
| `Schools.Learn` | [L78](../../UnitFrames/FluxCastBarSchools.lua#L78) |
| `Schools.InvalidateAliases` | [L100](../../UnitFrames/FluxCastBarSchools.lua#L100) |

### UnitFrames/FluxCastBarThemes.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FX.ThemeForMask` | [L259](../../UnitFrames/FluxCastBarThemes.lua#L259) |
| `FX.ResolveTheme` | [L299](../../UnitFrames/FluxCastBarThemes.lua#L299) |
| `FX.Layout` | [L421](../../UnitFrames/FluxCastBarThemes.lua#L421) |
| `FX.Reset` | [L513](../../UnitFrames/FluxCastBarThemes.lua#L513) |
| `FX.Update` | [L644](../../UnitFrames/FluxCastBarThemes.lua#L644) |
| `FX.Apply` | [L714](../../UnitFrames/FluxCastBarThemes.lua#L714) |
| `FX.Begin` | [L746](../../UnitFrames/FluxCastBarThemes.lua#L746) |
| `FX.Finish` | [L756](../../UnitFrames/FluxCastBarThemes.lua#L756) |
| `FX.Attach` | [L779](../../UnitFrames/FluxCastBarThemes.lua#L779) |
| `FX.Refresh` | [L787](../../UnitFrames/FluxCastBarThemes.lua#L787) |
| `FX.ObserveCast` | [L796](../../UnitFrames/FluxCastBarThemes.lua#L796) |
| `FX.SyncEvents` | [L864](../../UnitFrames/FluxCastBarThemes.lua#L864) |

### UnitFrames/FluxCastBarVisuals.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `Visuals.Resolve` | [L141](../../UnitFrames/FluxCastBarVisuals.lua#L141) |
| `Visuals.Invalidate` | [L166](../../UnitFrames/FluxCastBarVisuals.lua#L166) |

### UnitFrames/FluxClassPower.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `trueframe.SetScale` | [L55](../../UnitFrames/FluxClassPower.lua#L55) |
| `ns.ClassPower.ApplyVisibility` | [L420](../../UnitFrames/FluxClassPower.lua#L420) |
| `ns.ClassPower.UpdatePosition` | [L442](../../UnitFrames/FluxClassPower.lua#L442) |
| `ns.ClassPower.Initialize` | [L513](../../UnitFrames/FluxClassPower.lua#L513) |

### UnitFrames/FluxFlightPath.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FP.GetNodeName` | [L103](../../UnitFrames/FluxFlightPath.lua#L103) |
| `FP.GetFlightTimeForNodes` | [L120](../../UnitFrames/FluxFlightPath.lua#L120) |
| `FP.SetOverride` | [L124](../../UnitFrames/FluxFlightPath.lua#L124) |
| `FP.ClearOverride` | [L138](../../UnitFrames/FluxFlightPath.lua#L138) |
| `FP.GetFlightHash` | [L171](../../UnitFrames/FluxFlightPath.lua#L171) |

### UnitFrames/FluxForeverComboPoints.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `Combo.CanShowForPlayer` | [L21](../../UnitFrames/FluxForeverComboPoints.lua#L21) |
| `Combo.UpdatePoints` | [L58](../../UnitFrames/FluxForeverComboPoints.lua#L58) |
| `Combo.GetValues` | [L87](../../UnitFrames/FluxForeverComboPoints.lua#L87) |
| `Combo.RefreshAll` | [L99](../../UnitFrames/FluxForeverComboPoints.lua#L99) |
| `Combo.CreatePoints` | [L141](../../UnitFrames/FluxForeverComboPoints.lua#L141) |
| `Combo.Initialize` | [L159](../../UnitFrames/FluxForeverComboPoints.lua#L159) |

### UnitFrames/FluxHealthLossOverlay.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `HLO.DisableForHealthBar` | [L261](../../UnitFrames/FluxHealthLossOverlay.lua#L261) |
| `HLO.OnBeforeHealthValueSet` | [L302](../../UnitFrames/FluxHealthLossOverlay.lua#L302) |
| `HLO.OnAfterHealthValueSet` | [L309](../../UnitFrames/FluxHealthLossOverlay.lua#L309) |
| `HLO.Initialize` | [L359](../../UnitFrames/FluxHealthLossOverlay.lua#L359) |

### UnitFrames/FluxLegacyComboPoints.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `ns.LegacyComboPoints.RefreshAll` | [L132](../../UnitFrames/FluxLegacyComboPoints.lua#L132) |
| `ns.LegacyComboPoints.Initialize` | [L304](../../UnitFrames/FluxLegacyComboPoints.lua#L304) |

### UnitFrames/FluxMP5Overlay.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `MP5.Shutdown` | [L290](../../UnitFrames/FluxMP5Overlay.lua#L290) |
| `MP5.Initialize` | [L310](../../UnitFrames/FluxMP5Overlay.lua#L310) |

### UnitFrames/FluxPortraitCombatFeedback.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.PortraitCombatFeedback_OnCombatEvent` | [L88](../../UnitFrames/FluxPortraitCombatFeedback.lua#L88) |
| `UF.CreatePortraitCombatFeedback` | [L160](../../UnitFrames/FluxPortraitCombatFeedback.lua#L160) |

### UnitFrames/FluxPowerCostOverlay.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `PCO.CreateOverlay` | [L130](../../UnitFrames/FluxPowerCostOverlay.lua#L130) |
| `PCO.ApplySegmentArt` | [L140](../../UnitFrames/FluxPowerCostOverlay.lua#L140) |
| `PCO.UpdateOverlayColor` | [L160](../../UnitFrames/FluxPowerCostOverlay.lua#L160) |
| `PCO.RefreshPrediction` | [L307](../../UnitFrames/FluxPowerCostOverlay.lua#L307) |
| `PCO.BeforePowerApplied` | [L576](../../UnitFrames/FluxPowerCostOverlay.lua#L576) |
| `PCO.AfterPowerApplied` | [L675](../../UnitFrames/FluxPowerCostOverlay.lua#L675) |
| `PCO.DisableForFrame` | [L796](../../UnitFrames/FluxPowerCostOverlay.lua#L796) |
| `PCO.Initialize` | [L818](../../UnitFrames/FluxPowerCostOverlay.lua#L818) |

### UnitFrames/FluxSwingTimer.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `ST.HideForCastBarClaim` | [L1118](../../UnitFrames/FluxSwingTimer.lua#L1118) |
| `ST.OnCastBarSlotReleased` | [L1123](../../UnitFrames/FluxSwingTimer.lua#L1123) |
| `FluxSwingTimer_IsCleuRegistered` | [L1730](../../UnitFrames/FluxSwingTimer.lua#L1730) |
| `ST.AttachToCastBar` | [L2277](../../UnitFrames/FluxSwingTimer.lua#L2277) |
| `ST.SetPlayerSwingTimerEnabled` | [L2381](../../UnitFrames/FluxSwingTimer.lua#L2381) |

### UnitFrames/FluxUnitFrames_Auras.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `button.GetFilter` | [L864](../../UnitFrames/FluxUnitFrames_Auras.lua#L864) |
| `UF.UpdateAuraPosition` | [L1452](../../UnitFrames/FluxUnitFrames_Auras.lua#L1452) |
| `_G.FluxUnitFrames_UpdateFocusAuraLayoutForRaidStack` | [L1503](../../UnitFrames/FluxUnitFrames_Auras.lua#L1503) |
| `UF.ApplyAuraOptionsToFrame` | [L1900](../../UnitFrames/FluxUnitFrames_Auras.lua#L1900) |
| `UF.EnableAuras` | [L1925](../../UnitFrames/FluxUnitFrames_Auras.lua#L1925) |
| `UF.DisableAuras` | [L2215](../../UnitFrames/FluxUnitFrames_Auras.lua#L2215) |
| `UF.UpdateAuras` | [L2220](../../UnitFrames/FluxUnitFrames_Auras.lua#L2220) |
| `UF.CleanupAuras` | [L2229](../../UnitFrames/FluxUnitFrames_Auras.lua#L2229) |

### UnitFrames/FluxUnitFrames_AurasEngine.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.UseEngineAuras` | [L37](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L37) |
| `UF.ContainerUsesEngine` | [L49](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L49) |
| `UF.FrameUsesEngineAuras` | [L53](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L53) |
| `UF.PokeEngineAuras` | [L395](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L395) |
| `UF.SyncEngineAuras` | [L409](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L409) |
| `UF.AttachEngineAuras` | [L458](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L458) |

### UnitFrames/FluxUnitFrames_AurasOwn.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `AuraOwn.IsSecretValue` | [L38](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L38) |
| `AuraOwn.IsAccessible` | [L54](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L54) |
| `AuraOwn.HasPackedAuraAPI` | [L68](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L68) |
| `AuraOwn.HasFilterNegation` | [L79](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L79) |
| `AuraOwn.GetHarmfulFilter` | [L86](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L86) |
| `AuraOwn.GetOwnHarmfulFilter` | [L97](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L97) |
| `AuraOwn.GetOtherHarmfulFilter` | [L110](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L110) |
| `AuraOwn.ClampMinScale` | [L129](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L129) |
| `AuraOwn.GetOwnSizeMultiplier` | [L143](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L143) |
| `AuraOwn.GetOwnFitScale` | [L151](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L151) |
| `AuraOwn.GetIconSizes` | [L164](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L164) |
| `AuraOwn.GetAuraInstanceID` | [L178](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L178) |
| `AuraOwn.BuildPlayerDebuffInstanceSet` | [L207](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L207) |
| `AuraOwn.SourceIsPlayerPetOrVehicle` | [L230](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L230) |
| `AuraOwn.IsOwnHarmful` | [L256](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L256) |
| `AuraOwn.SortDebuffsOwnFirst` | [L281](../../UnitFrames/FluxUnitFrames_AurasOwn.lua#L281) |

### UnitFrames/FluxUnitFrames_BigDebuffs.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.SyncBigDebuffsFrameLevelForUnitFrame` | [L165](../../UnitFrames/FluxUnitFrames_BigDebuffs.lua#L165) |

### UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_SetBlizzardPlayerPredictionMuted` | [L231](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L231) |
| `FluxUnitFrames_SuppressBlizzardUnitFrame` | [L393](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L393) |
| `FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled` | [L415](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L415) |
| `FluxUnitFrames_RefreshBothSidesAfterToggle` | [L486](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L486) |
| `FluxUnitFrames_ApplyFluxVsBlizzardRuntime` | [L581](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L581) |

### UnitFrames/FluxUnitFrames_Focus.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUIPositionFocusFrameDefault` | [L9](../../UnitFrames/FluxUnitFrames_Focus.lua#L9) |
| `FluxUnitFrames_ApplyRuntimeFocus` | [L232](../../UnitFrames/FluxUnitFrames_Focus.lua#L232) |

### UnitFrames/FluxUnitFrames_FocusTarget.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_ApplyRuntimeFocusTarget` | [L190](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L190) |
| `FluxUnitFrames_MatchFocusTargetToFocus` | [L271](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L271) |

### UnitFrames/FluxUnitFrames_Lifecycle.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.DeferProtected` | [L28](../../UnitFrames/FluxUnitFrames_Lifecycle.lua#L28) |
| `UF.IsInitialized` | [L32](../../UnitFrames/FluxUnitFrames_Lifecycle.lua#L32) |
| `UF.RunInitializer` | [L37](../../UnitFrames/FluxUnitFrames_Lifecycle.lua#L37) |
| `UF.RegisterInitializer` | [L65](../../UnitFrames/FluxUnitFrames_Lifecycle.lua#L65) |

### UnitFrames/FluxUnitFrames_OptionsBridge.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_ShouldUseFlux` | [L6](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L6) |
| `FluxUnitFrames_IsFeatureEnabled` | [L52](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L52) |
| `FluxUnitFrames_ShouldShowPortrait` | [L80](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L80) |
| `FluxUnitFrames_DisplayEnabled` | [L106](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L106) |
| `FluxUnitFrames_GetHealthTextMode` | [L114](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L114) |
| `FluxUnitFrames_ShouldShowCastTime` | [L126](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L126) |
| `FluxUnitFrames_ShouldShowPowerText` | [L130](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L130) |
| `FluxUnitFrames_ShouldShowHealPrediction` | [L134](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L134) |
| `FluxUnitFrames_ShouldShowAbsorbs` | [L138](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L138) |
| `FluxUnitFrames_ShouldShowClassPower` | [L142](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L142) |
| `FluxUnitFrames_GetClassPowerScale` | [L146](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L146) |
| `FluxUnitFrames_GetWholeFrameScale` | [L155](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L155) |
| `FluxUnitFrames_ShouldShowLevel` | [L163](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L163) |
| `FluxUnitFrames_ShouldShowClassIcon` | [L167](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L167) |
| `FluxUnitFrames_ShouldShowPvp` | [L171](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L171) |
| `FluxUnitFrames_ShouldShowCombatIcon` | [L175](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L175) |
| `FluxUnitFrames_ShouldShowRaidIcon` | [L179](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L179) |
| `FluxUnitFrames_ShouldShowPortraitCombat` | [L183](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L183) |
| `FluxUnitFrames_ShouldShowMouseover` | [L187](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L187) |
| `FluxUnitFrames_ShouldShowCastBar` | [L192](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L192) |
| `FluxUnitFrames_ShouldShowPetTooltipAuras` | [L204](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L204) |
| `FluxUnitFrames_ShouldUse3DPortrait` | [L213](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L213) |
| `FluxUnitFrames_IsPortraitCombatTintEnabled` | [L222](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L222) |
| `FluxUnitFrames_RefreshPortraitCombatTint` | [L230](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L230) |
| `FluxUnitFrames_ShouldShowTargetNoTargetPlaceholder` | [L245](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L245) |
| `FluxUnitFrames_RefreshTargetPlaceholderFromDB` | [L253](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L253) |
| `FluxUnitFrames_GetPlayerTargetPlacement` | [L262](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L262) |
| `FluxUnitFrames_GetScreenAnchorCenterOffsetX` | [L272](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L272) |
| `_G.FluxUnitFrames_GetPlayerScreenBottomOffset` | [L321](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L321) |
| `_G.FluxUnitFrames_ApplyPlayerStatusBarLayout` | [L356](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L356) |
| `FluxUnitFrames_SyncTargetChromeForPlacement` | [L369](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L369) |
| `FluxUnitFrames_RefreshTargetOfTargetAnchor` | [L404](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L404) |
| `FluxUnitFrames_ReanchorUnitFrameScreenPosition` | [L416](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L416) |
| `FluxUnitFrames_ApplyThreatBarOptionsFromDB` | [L477](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L477) |
| `FluxUnitFrames_ApplyPortraitOptionsFromDB` | [L523](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L523) |
| `FluxUnitFrames_RefreshPortraitRenderModeFromDB` | [L593](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L593) |
| `FluxUnitFrames_GetAuraConfigTables` | [L644](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L644) |
| `FluxUnitFrames_ApplyAuraLayoutFromDB` | [L704](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L704) |
| `FluxUnitFrames_ApplyOptionsFromDB` | [L734](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L734) |
| `FluxUnitFrames_GetPlayerTargetPlacement2RelativeUIScale` | [L870](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L870) |
| `FluxUnitFrames_UnitFrameStorageToEffectiveDimension` | [L878](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L878) |
| `FluxUnitFrames_UnitFrameEffectiveToStorageDimension` | [L889](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L889) |
| `FluxUnitFrames_EnsureAndGetFrameSizesBucket` | [L925](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L925) |
| `FluxUnitFrames_GetPlacement1TargetLeftForMicroMenuCap` | [L952](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L952) |
| `FluxUnitFrames_GetUnitFrameDefaultDimension` | [L988](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L988) |
| `FluxUnitFrames_GetConfiguredFrameSize` | [L1012](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1012) |
| `FluxUnitFrames_GetConfiguredPetTargetBarWidth` | [L1060](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1060) |
| `FluxUnitFrames_FullUnitFrameLayoutRefresh` | [L1073](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1073) |
| `FluxUnitFrames_GetHealthPartitionPct` | [L1110](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1110) |
| `FluxUnitFrames_RefreshBarPartitionsFromDB` | [L1140](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1140) |
| `FluxUnitFrames_ApplyFrameSizesFromDB` | [L1161](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1161) |

### UnitFrames/FluxUnitFrames_Pet.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_ApplyRuntimePet` | [L268](../../UnitFrames/FluxUnitFrames_Pet.lua#L268) |

### UnitFrames/FluxUnitFrames_PetAuraTooltip.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.ShowPetAuraTooltip` | [L558](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L558) |
| `UF.HidePetAuraTooltip` | [L591](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L591) |
| `UF.ShowUnitTooltip` | [L646](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L646) |
| `UF.HideUnitTooltip` | [L657](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L657) |

### UnitFrames/FluxUnitFrames_PetTarget.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_ApplyRuntimePetTarget` | [L243](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L243) |

### UnitFrames/FluxUnitFrames_Player.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_ApplyRuntimePlayer` | [L207](../../UnitFrames/FluxUnitFrames_Player.lua#L207) |

### UnitFrames/FluxUnitFrames_PlayerSpecClick.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `PSC.HideProfileSubmenu` | [L244](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L244) |
| `PSC.UpdateInteractionState` | [L1115](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1115) |
| `PSC.Initialize` | [L1145](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1145) |
| `trueplayerFrame.UpdateOuterBorder` | [L1198](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1198) |
| `trueplayerFrame.UpdatePartition` | [L1208](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1208) |
| `_G.FluxUnitFrames_PlayerSpecClick_Refresh` | [L1218](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1218) |

### UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `PTC.ToggleOutfitFlyout` | [L427](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L427) |
| `PTC.UpdateInteractionState` | [L747](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L747) |
| `TransmogWatcher_OnUpdatestate.ArmTransmogWatcher` | [L825](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L825) |
| `PTC.Initialize` | [L837](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L837) |
| `trueplayerFrame.UpdateOuterBorder` | [L873](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L873) |
| `trueplayerFrame.UpdatePartition` | [L882](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L882) |

### UnitFrames/FluxUnitFrames_Shared.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.RegisterUnitFramePoll` | [L123](../../UnitFrames/FluxUnitFrames_Shared.lua#L123) |
| `UF.UnregisterUnitFramePoll` | [L136](../../UnitFrames/FluxUnitFrames_Shared.lua#L136) |
| `FluxUI_GetUnitFramePollStats` | [L143](../../UnitFrames/FluxUnitFrames_Shared.lua#L143) |
| `UF.SyncBigDebuffsFrameLevelForUnitFrame` | [L297](../../UnitFrames/FluxUnitFrames_Shared.lua#L297) |
| `UF.UnitTokenIsResolved` | [L350](../../UnitFrames/FluxUnitFrames_Shared.lua#L350) |
| `UF.ShouldShowWatchedUnitFrame` | [L408](../../UnitFrames/FluxUnitFrames_Shared.lua#L408) |
| `UF.HideEmptyUnitPortrait` | [L549](../../UnitFrames/FluxUnitFrames_Shared.lua#L549) |
| `UF.SyncTargetPlaceholderVisibility` | [L571](../../UnitFrames/FluxUnitFrames_Shared.lua#L571) |
| `UF.SyncWatchedUnitFrameVisibility` | [L631](../../UnitFrames/FluxUnitFrames_Shared.lua#L631) |
| `UF.GetHudBarTexture` | [L775](../../UnitFrames/FluxUnitFrames_Shared.lua#L775) |
| `UF.UsesHudUnitBars` | [L783](../../UnitFrames/FluxUnitFrames_Shared.lua#L783) |
| `UF.GetPowerPredictionColor` | [L828](../../UnitFrames/FluxUnitFrames_Shared.lua#L828) |
| `UF.GetPowerStatusAtlas` | [L847](../../UnitFrames/FluxUnitFrames_Shared.lua#L847) |
| `UF.UpdateResourceSpark` | [L901](../../UnitFrames/FluxUnitFrames_Shared.lua#L901) |
| `pulse:StartAnimIfFull` | [L1119](../../UnitFrames/FluxUnitFrames_Shared.lua#L1119) |
| `pulse:RemoveAnims` | [L1142](../../UnitFrames/FluxUnitFrames_Shared.lua#L1142) |
| `UF.SetFullResourcePulseActive` | [L1157](../../UnitFrames/FluxUnitFrames_Shared.lua#L1157) |
| `UF.UpdateFullResourcePulse` | [L1180](../../UnitFrames/FluxUnitFrames_Shared.lua#L1180) |
| `UF.PowerValueForDisplay` | [L1204](../../UnitFrames/FluxUnitFrames_Shared.lua#L1204) |
| `UF.ApplyResourceBarStyle` | [L1240](../../UnitFrames/FluxUnitFrames_Shared.lua#L1240) |
| `UF.RefreshResourceConnection` | [L1334](../../UnitFrames/FluxUnitFrames_Shared.lua#L1334) |
| `UF.ApplyStaggerBarStyle` | [L1352](../../UnitFrames/FluxUnitFrames_Shared.lua#L1352) |
| `UF.LayoutPetHappinessIcon` | [L1434](../../UnitFrames/FluxUnitFrames_Shared.lua#L1434) |
| `UF.ForeverNpcChrome` | [L1929](../../UnitFrames/FluxUnitFrames_Shared.lua#L1929) |
| `AnimatedHealthLossMixin:OnLoad` | [L2030](../../UnitFrames/FluxUnitFrames_Shared.lua#L2030) |
| `AnimatedHealthLossMixin:SetDuration` | [L2038](../../UnitFrames/FluxUnitFrames_Shared.lua#L2038) |
| `AnimatedHealthLossMixin:SetStartDelay` | [L2042](../../UnitFrames/FluxUnitFrames_Shared.lua#L2042) |
| `AnimatedHealthLossMixin:SetPauseDelay` | [L2046](../../UnitFrames/FluxUnitFrames_Shared.lua#L2046) |
| `AnimatedHealthLossMixin:SetPostponeDelay` | [L2050](../../UnitFrames/FluxUnitFrames_Shared.lua#L2050) |
| `AnimatedHealthLossMixin:SetUnitHealthBar` | [L2054](../../UnitFrames/FluxUnitFrames_Shared.lua#L2054) |
| `AnimatedHealthLossMixin:UpdateHealthMinMax` | [L2064](../../UnitFrames/FluxUnitFrames_Shared.lua#L2064) |
| `AnimatedHealthLossMixin:GetHealthLossAnimationData` | [L2069](../../UnitFrames/FluxUnitFrames_Shared.lua#L2069) |
| `AnimatedHealthLossMixin:CancelAnimation` | [L2086](../../UnitFrames/FluxUnitFrames_Shared.lua#L2086) |
| `AnimatedHealthLossMixin:SetDisplayedLoss` | [L2092](../../UnitFrames/FluxUnitFrames_Shared.lua#L2092) |
| `AnimatedHealthLossMixin:BeginAnimation` | [L2102](../../UnitFrames/FluxUnitFrames_Shared.lua#L2102) |
| `AnimatedHealthLossMixin:PostponeStartTime` | [L2111](../../UnitFrames/FluxUnitFrames_Shared.lua#L2111) |
| `AnimatedHealthLossMixin:UpdateHealth` | [L2115](../../UnitFrames/FluxUnitFrames_Shared.lua#L2115) |
| `AnimatedHealthLossMixin:ReadableAbsorbBlocks` | [L2133](../../UnitFrames/FluxUnitFrames_Shared.lua#L2133) |
| `AnimatedHealthLossMixin:UpdateLossAnimation` | [L2141](../../UnitFrames/FluxUnitFrames_Shared.lua#L2141) |
| `AnimatedHealthLossMixin:ShowPixelDriver` | [L2160](../../UnitFrames/FluxUnitFrames_Shared.lua#L2160) |
| `AnimatedHealthLossMixin:UpdateFromPixels` | [L2183](../../UnitFrames/FluxUnitFrames_Shared.lua#L2183) |
| `UF.ApplyHealAbsorbOptionVisibility` | [L2460](../../UnitFrames/FluxUnitFrames_Shared.lua#L2460) |
| `UF.UpdateHealPrediction` | [L2488](../../UnitFrames/FluxUnitFrames_Shared.lua#L2488) |
| `UF.UnitIsAFKDisplay` | [L2717](../../UnitFrames/FluxUnitFrames_Shared.lua#L2717) |
| `UF.ShouldShowAFKHealthOverlay` | [L2727](../../UnitFrames/FluxUnitFrames_Shared.lua#L2727) |
| `UF.GetHealthDeadGhostStatusText` | [L2734](../../UnitFrames/FluxUnitFrames_Shared.lua#L2734) |
| `UF.UpdateHealth` | [L2754](../../UnitFrames/FluxUnitFrames_Shared.lua#L2754) |
| `UF.CreateHealthBar` | [L2895](../../UnitFrames/FluxUnitFrames_Shared.lua#L2895) |
| `UF.UpdateHealthColor` | [L3139](../../UnitFrames/FluxUnitFrames_Shared.lua#L3139) |
| `UF.UpdatePower` | [L3187](../../UnitFrames/FluxUnitFrames_Shared.lua#L3187) |
| `UF.CreatePowerBar` | [L3341](../../UnitFrames/FluxUnitFrames_Shared.lua#L3341) |
| `UF.CreatePortrait` | [L3606](../../UnitFrames/FluxUnitFrames_Shared.lua#L3606) |
| `UF.FrameUsesPortraitLayout` | [L3818](../../UnitFrames/FluxUnitFrames_Shared.lua#L3818) |
| `UF.LayoutBigDebuffsCornerPlaceholder` | [L3835](../../UnitFrames/FluxUnitFrames_Shared.lua#L3835) |
| `UF.UpdatePortrait` | [L3975](../../UnitFrames/FluxUnitFrames_Shared.lua#L3975) |
| `UF.SyncPortraitModelGeometry` | [L4052](../../UnitFrames/FluxUnitFrames_Shared.lua#L4052) |
| `UF.RefreshPortraitAfterDisplayMetrics` | [L4078](../../UnitFrames/FluxUnitFrames_Shared.lua#L4078) |
| `UF.UpdatePlayerSpecIconOnly` | [L4206](../../UnitFrames/FluxUnitFrames_Shared.lua#L4206) |
| `_G.FluxUnitFrames_RefreshPlayerSpecIcon` | [L4265](../../UnitFrames/FluxUnitFrames_Shared.lua#L4265) |
| `_G.FluxUnitFrames_GetPlayerSpecIcon` | [L4326](../../UnitFrames/FluxUnitFrames_Shared.lua#L4326) |
| `UF.CreateAtlasBorder` | [L4364](../../UnitFrames/FluxUnitFrames_Shared.lua#L4364) |
| `UF.UpdateAtlasBorder` | [L4412](../../UnitFrames/FluxUnitFrames_Shared.lua#L4412) |
| `UF.GuardTooltipStatusBar` | [L4456](../../UnitFrames/FluxUnitFrames_Shared.lua#L4456) |
| `mixin:ResetUnitHealth` | [L4484](../../UnitFrames/FluxUnitFrames_Shared.lua#L4484) |
| `mixin:UpdateUnitHealth` | [L4491](../../UnitFrames/FluxUnitFrames_Shared.lua#L4491) |
| `UF.ShowUnitTooltip` | [L4499](../../UnitFrames/FluxUnitFrames_Shared.lua#L4499) |
| `endGameTooltip.UpdateTooltip` | [L4528](../../UnitFrames/FluxUnitFrames_Shared.lua#L4528) |
| `UF.HideUnitTooltip` | [L4540](../../UnitFrames/FluxUnitFrames_Shared.lua#L4540) |
| `UF.CreateMouseoverHighlight` | [L4582](../../UnitFrames/FluxUnitFrames_Shared.lua#L4582) |
| `UF.CreateOuterBorder` | [L4662](../../UnitFrames/FluxUnitFrames_Shared.lua#L4662) |
| `outerBorderFrame.SetRightClickMenu` | [L4895](../../UnitFrames/FluxUnitFrames_Shared.lua#L4895) |
| `UF.SetFrameLevelIfChanged` | [L5013](../../UnitFrames/FluxUnitFrames_Shared.lua#L5013) |
| `UF.UpdatePortraitCombatTint` | [L5114](../../UnitFrames/FluxUnitFrames_Shared.lua#L5114) |
| `UF.UpdateBorderColors` | [L5140](../../UnitFrames/FluxUnitFrames_Shared.lua#L5140) |
| `UF.UpdateOuterBorder` | [L6036](../../UnitFrames/FluxUnitFrames_Shared.lua#L6036) |
| `UF.UpdateAdditionalPower` | [L6719](../../UnitFrames/FluxUnitFrames_Shared.lua#L6719) |
| `UF.CreateAdditionalPowerBar` | [L6875](../../UnitFrames/FluxUnitFrames_Shared.lua#L6875) |
| `UF.GetThreatBarPosition` | [L7060](../../UnitFrames/FluxUnitFrames_Shared.lua#L7060) |
| `UF.CreateThreatBar` | [L7368](../../UnitFrames/FluxUnitFrames_Shared.lua#L7368) |
| `UF.LayoutThreatBar` | [L7435](../../UnitFrames/FluxUnitFrames_Shared.lua#L7435) |
| `UF.UpdateThreatBar` | [L7552](../../UnitFrames/FluxUnitFrames_Shared.lua#L7552) |
| `UF.UpdateFrameVisualElements` | [L7756](../../UnitFrames/FluxUnitFrames_Shared.lua#L7756) |
| `UF.UpdateFramePartitionSeparators` | [L7901](../../UnitFrames/FluxUnitFrames_Shared.lua#L7901) |
| `UF.GetFluxStylePartitionHealthHeight` | [L7934](../../UnitFrames/FluxUnitFrames_Shared.lua#L7934) |
| `UF.UpdateFramePartition` | [L7948](../../UnitFrames/FluxUnitFrames_Shared.lua#L7948) |
| `UF.ApplyEmulatedHorizontalSqueezeForFrame` | [L8575](../../UnitFrames/FluxUnitFrames_Shared.lua#L8575) |
| `UF.UpdateAllEmulatedHorizontalSqueeze` | [L8579](../../UnitFrames/FluxUnitFrames_Shared.lua#L8579) |
| `FluxUnitFrames_UpdateAllEmulatedHorizontalSqueeze` | [L8591](../../UnitFrames/FluxUnitFrames_Shared.lua#L8591) |
| `UF.RegisterEmulatedHorizontalSqueeze` | [L8595](../../UnitFrames/FluxUnitFrames_Shared.lua#L8595) |
| `UF.CreateBaseFrame` | [L8640](../../UnitFrames/FluxUnitFrames_Shared.lua#L8640) |
| `UF.RefreshSelfDisplayNames` | [L8889](../../UnitFrames/FluxUnitFrames_Shared.lua#L8889) |
| `FluxUnitFrames_RefreshAppearanceChrome` | [L8911](../../UnitFrames/FluxUnitFrames_Shared.lua#L8911) |

### UnitFrames/FluxUnitFrames_Target.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `frame:UpdateFluxTargetPlaceholderVisibility` | [L279](../../UnitFrames/FluxUnitFrames_Target.lua#L279) |
| `FluxUnitFrames_RefreshTargetAndTotTogether` | [L330](../../UnitFrames/FluxUnitFrames_Target.lua#L330) |
| `FluxUnitFrames_ApplyRuntimeTarget` | [L401](../../UnitFrames/FluxUnitFrames_Target.lua#L401) |

### UnitFrames/FluxUnitFrames_TargetOfTarget.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_RestoreBlizzardTotDefaultParent` | [L277](../../UnitFrames/FluxUnitFrames_TargetOfTarget.lua#L277) |
| `FluxUnitFrames_ApplyRuntimeToT` | [L289](../../UnitFrames/FluxUnitFrames_TargetOfTarget.lua#L289) |

### WindowMover/Catalog.lua

Owner: [28-window-mover.md](../28-window-mover.md).

| Declaration | Source |
|---|---|
| `WindowMover.IsBlacklisted` | [L263](../../WindowMover/Catalog.lua#L263) |
| `WindowMover.ShouldSkip` | [L280](../../WindowMover/Catalog.lua#L280) |
| `WindowMover.Catalog` | [L313](../../WindowMover/Catalog.lua#L313) |

### WindowMover/Engine.lua

Owner: [28-window-mover.md](../28-window-mover.md).

| Declaration | Source |
|---|---|
| `WindowMover.Settings` | [L135](../../WindowMover/Engine.lua#L135) |
| `WindowMover.Apply` | [L295](../../WindowMover/Engine.lua#L295) |
| `WindowMover._OnProxyUpdate` | [L473](../../WindowMover/Engine.lua#L473) |
| `WindowMover.ResetFrame` | [L618](../../WindowMover/Engine.lua#L618) |
| `WindowMover.ResetAll` | [L635](../../WindowMover/Engine.lua#L635) |
| `WindowMover.SetLocked` | [L647](../../WindowMover/Engine.lua#L647) |
| `WindowMover.IsLocked` | [L654](../../WindowMover/Engine.lua#L654) |
| `WindowMover.Attach` | [L816](../../WindowMover/Engine.lua#L816) |
| `WindowMover.Scan` | [L910](../../WindowMover/Engine.lua#L910) |
| `WindowMover.Refresh` | [L938](../../WindowMover/Engine.lua#L938) |
| `WindowMover.Start` | [L955](../../WindowMover/Engine.lua#L955) |
| `WindowMover.AttachedCount` | [L984](../../WindowMover/Engine.lua#L984) |
| `WindowMover.Smoke` | [L994](../../WindowMover/Engine.lua#L994) |

### WindowMover/Init.lua

Owner: [28-window-mover.md](../28-window-mover.md).

| Declaration | Source |
|---|---|
| `WindowMover.SetEnabled` | [L14](../../WindowMover/Init.lua#L14) |

### WindowMover/Resolve.lua

Owner: [28-window-mover.md](../28-window-mover.md).

| Declaration | Source |
|---|---|
| `WindowMover.IsFrame` | [L21](../../WindowMover/Resolve.lua#L21) |
| `WindowMover.Resolve` | [L25](../../WindowMover/Resolve.lua#L25) |
| `WindowMover.FindDragHandles` | [L79](../../WindowMover/Resolve.lua#L79) |
