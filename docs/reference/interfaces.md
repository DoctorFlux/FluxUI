# Source interface and event index

Generated discovery index for [API/event contracts](../33-api-and-events.md). Function declarations are syntactic candidates: table-local methods are included, and assigned aliases/dynamically generated functions may not appear. This is not a promise that every name is globally accessible. Stable contracts and callback payloads are documented in the architecture/system chapters.

## Event and subscription sites

Literal and dynamic event expressions are preserved. Shared-bus subscription methods can subscribe to non-WoW notifications; method names alone do not establish event semantics.

| Source | Method | Arguments |
|---|---|---|
| [AddonOptions/AceGUIWidget-FluxSpellBookSlotsPanel.lua:410](../../AddonOptions/AceGUIWidget-FluxSpellBookSlotsPanel.lua#L410) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [AddonOptions/FluxOptions.lua:1601](../../AddonOptions/FluxOptions.lua#L1601) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptions.lua:1647](../../AddonOptions/FluxOptions.lua#L1647) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [AddonOptions/FluxOptionsActionBars.lua:67](../../AddonOptions/FluxOptionsActionBars.lua#L67) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsBattlezone.lua:275](../../AddonOptions/FluxOptionsBattlezone.lua#L275) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsBinding.lua:27](../../AddonOptions/FluxOptionsBinding.lua#L27) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsChat.lua:141](../../AddonOptions/FluxOptionsChat.lua#L141) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsGameMenu.lua:40](../../AddonOptions/FluxOptionsGameMenu.lua#L40) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [AddonOptions/FluxOptionsGameMenu.lua:41](../../AddonOptions/FluxOptionsGameMenu.lua#L41) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsGeneral.lua:104](../../AddonOptions/FluxOptionsGeneral.lua#L104) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsInfo.lua:173](../../AddonOptions/FluxOptionsInfo.lua#L173) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsLayout.lua:76](../../AddonOptions/FluxOptionsLayout.lua#L76) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsLoot.lua:66](../../AddonOptions/FluxOptionsLoot.lua#L66) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsMicroMenu.lua:312](../../AddonOptions/FluxOptionsMicroMenu.lua#L312) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsNameplates.lua:239](../../AddonOptions/FluxOptionsNameplates.lua#L239) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsShell.lua:867](../../AddonOptions/FluxOptionsShell.lua#L867) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [AddonOptions/FluxOptionsStatusBars.lua:536](../../AddonOptions/FluxOptionsStatusBars.lua#L536) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsUnitFrames.lua:2086](../../AddonOptions/FluxOptionsUnitFrames.lua#L2086) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsWindows.lua:274](../../AddonOptions/FluxOptionsWindows.lua#L274) | `RegisterEvent` | `"ADDON_LOADED"` |
| [BaganatorCompat/FluxBaganator_BankRestock.lua:254](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L254) | `RegisterEvent` | `"BANKFRAME_OPENED"` |
| [BaganatorCompat/FluxBaganator_BankRestock.lua:255](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L255) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [BaganatorCompat/FluxBaganator_BankRestock.lua:257](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L257) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
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
| [Bars/ProgramFace.lua:1566](../../Bars/ProgramFace.lua#L1566) | `Subscribe` | `ProgramFace.OnContext` |
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
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:854](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L854) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:855](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L855) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:856](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L856) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:857](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L857) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:890](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L890) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:891](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L891) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:1205](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1205) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:1206](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1206) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:1207](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1207) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1647](../../Battlezonemap/FluxBlizzardMeter.lua#L1647) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1648](../../Battlezonemap/FluxBlizzardMeter.lua#L1648) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1649](../../Battlezonemap/FluxBlizzardMeter.lua#L1649) | `RegisterEvent` | `"EDIT_MODE_LAYOUTS_UPDATED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1725](../../Battlezonemap/FluxBlizzardMeter.lua#L1725) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1726](../../Battlezonemap/FluxBlizzardMeter.lua#L1726) | `RegisterEvent` | `"VARIABLES_LOADED"` |
| [Battlezonemap/FluxBlizzardMeter.lua:1727](../../Battlezonemap/FluxBlizzardMeter.lua#L1727) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxDetails.lua:242](../../Battlezonemap/FluxDetails.lua#L242) | `RegisterEvent` | `"DETAILS_INSTANCE_OPEN", lightRefreshIfEmbedded` |
| [Battlezonemap/FluxDetails.lua:243](../../Battlezonemap/FluxDetails.lua#L243) | `RegisterEvent` | `"DETAILS_PROFILE_APPLYED", function() -- Profiles reset instances_amount (default 5); Flux needs up to 6 panes. EnsureDetailsMaxWindows() lightRefreshIfEmbedded() end` |
| [Battlezonemap/FluxDetails.lua:1833](../../Battlezonemap/FluxDetails.lua#L1833) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxDetails.lua:1834](../../Battlezonemap/FluxDetails.lua#L1834) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxDetailsForever.lua:195](../../Battlezonemap/FluxDetailsForever.lua#L195) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Battlezonemap/FluxDetailsForever.lua:196](../../Battlezonemap/FluxDetailsForever.lua#L196) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxDetailsWoWSkinTint.lua:138](../../Battlezonemap/FluxDetailsWoWSkinTint.lua#L138) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxMeterLayout.lua:2610](../../Battlezonemap/FluxMeterLayout.lua#L2610) | `RegisterEvent` | `"PLAYER_LOGIN"` |
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
| [Battlezonemap/FluxThreatMeter.lua:333](../../Battlezonemap/FluxThreatMeter.lua#L333) | `RegisterEvent` | `event` |
| [Battlezonemap/FluxThreatMeter.lua:334](../../Battlezonemap/FluxThreatMeter.lua#L334) | `RegisterUnitEvent` | `"UNIT_TARGET", "target"` |
| [Battlezonemap/FluxWindowFrame.lua:1668](../../Battlezonemap/FluxWindowFrame.lua#L1668) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxWindowFrame.lua:1669](../../Battlezonemap/FluxWindowFrame.lua#L1669) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Battlezonemap/FluxWindowFrame.lua:1670](../../Battlezonemap/FluxWindowFrame.lua#L1670) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxWindowFrame.lua:1671](../../Battlezonemap/FluxWindowFrame.lua#L1671) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Boot.lua:40](../../Binding/Boot.lua#L40) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Boot.lua:41](../../Binding/Boot.lua#L41) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Boot.lua:51](../../Binding/Boot.lua#L51) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Binding/Core/Apply.lua:2412](../../Binding/Core/Apply.lua#L2412) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Binding/Core/Apply.lua:2413](../../Binding/Core/Apply.lua#L2413) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Binding/Core/Apply.lua:2430](../../Binding/Core/Apply.lua#L2430) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Core/Apply.lua:2440](../../Binding/Core/Apply.lua#L2440) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/Apply.lua:2480](../../Binding/Core/Apply.lua#L2480) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [Binding/Core/ChordMap.lua:211](../../Binding/Core/ChordMap.lua#L211) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/Core/ChordMap.lua:212](../../Binding/Core/ChordMap.lua#L212) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/Conditions.lua:607](../../Binding/Core/Conditions.lua#L607) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [Binding/Core/Conditions.lua:608](../../Binding/Core/Conditions.lua#L608) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Binding/Core/Conditions.lua:622](../../Binding/Core/Conditions.lua#L622) | `RegisterEvent` | `"UNIT_PET"` |
| [Binding/Core/Engraving.lua:270](../../Binding/Core/Engraving.lua#L270) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Binding/Core/Engraving.lua:272](../../Binding/Core/Engraving.lua#L272) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [Binding/Core/Forms.lua:258](../../Binding/Core/Forms.lua#L258) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORMS"` |
| [Binding/Core/Forms.lua:259](../../Binding/Core/Forms.lua#L259) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/Placement.lua:2459](../../Binding/Core/Placement.lua#L2459) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/Core/Placement.lua:2460](../../Binding/Core/Placement.lua#L2460) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/PushPress.lua:436](../../Binding/Core/PushPress.lua#L436) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Binding/Core/PushPress.lua:771](../../Binding/Core/PushPress.lua#L771) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Binding/Core/PushPress.lua:868](../../Binding/Core/PushPress.lua#L868) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/PushPress.lua:869](../../Binding/Core/PushPress.lua#L869) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Input/FluxMouseoverKeybind.lua:2059](../../Binding/Input/FluxMouseoverKeybind.lua#L2059) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Binding/Input/FluxMouseoverKeybind.lua:2060](../../Binding/Input/FluxMouseoverKeybind.lua#L2060) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Input/FluxMouseoverKeybind.lua:2061](../../Binding/Input/FluxMouseoverKeybind.lua#L2061) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/Input/FluxMouseoverKeybind.lua:2062](../../Binding/Input/FluxMouseoverKeybind.lua#L2062) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Input/FluxMouseoverKeybind.lua:2063](../../Binding/Input/FluxMouseoverKeybind.lua#L2063) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [Binding/Respec.lua:364](../../Binding/Respec.lua#L364) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
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
| [Binding/UI/SpellbookBindingHooks.lua:216](../../Binding/UI/SpellbookBindingHooks.lua#L216) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/UI/SpellbookBindingHooks.lua:468](../../Binding/UI/SpellbookBindingHooks.lua#L468) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Binding/UI/SpellbookBindingHooks.lua:469](../../Binding/UI/SpellbookBindingHooks.lua#L469) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Binding/UI/SpellbookBindingHooks.lua:470](../../Binding/UI/SpellbookBindingHooks.lua#L470) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Blizzard/Hide.lua:46](../../Blizzard/Hide.lua#L46) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Blizzard/Hide.lua:206](../../Blizzard/Hide.lua#L206) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [BlizzardSettings/Nameplates.lua:216](../../BlizzardSettings/Nameplates.lua#L216) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [BlizzardSettings/Write.lua:251](../../BlizzardSettings/Write.lua#L251) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [CharacterInfo/ItemLevel.lua:305](../../CharacterInfo/ItemLevel.lua#L305) | `RegisterEvent` | `"ADDON_LOADED"` |
| [CharacterInfo/ItemLevel.lua:306](../../CharacterInfo/ItemLevel.lua#L306) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [CharacterInfo/ItemLevel.lua:307](../../CharacterInfo/ItemLevel.lua#L307) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [CharacterInfo/ItemLevel.lua:308](../../CharacterInfo/ItemLevel.lua#L308) | `RegisterEvent` | `"GET_ITEM_INFO_RECEIVED"` |
| [CharacterInfo/PaperDollQuality.lua:164](../../CharacterInfo/PaperDollQuality.lua#L164) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [CharacterInfo/PaperDollQuality.lua:165](../../CharacterInfo/PaperDollQuality.lua#L165) | `RegisterEvent` | `"UNIT_INVENTORY_CHANGED"` |
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
| [Core/ButtonFX/Overlay.lua:1872](../../Core/ButtonFX/Overlay.lua#L1872) | `RegisterEvent` | `"GLOBAL_MOUSE_UP"` |
| [Core/ButtonFX/Overlay.lua:2114](../../Core/ButtonFX/Overlay.lua#L2114) | `RegisterEvent` | `"GLOBAL_MOUSE_UP"` |
| [Core/Capabilities.lua:158](../../Core/Capabilities.lua#L158) | `RegisterEvent` | `"COMBAT_LOG_EVENT_UNFILTERED"` |
| [Core/Capabilities.lua:195](../../Core/Capabilities.lua#L195) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_RETICLE_TARGET", "player"` |
| [Core/Capabilities.lua:198](../../Core/Capabilities.lua#L198) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_RETICLE_CLEAR", "player"` |
| [Core/Capabilities.lua:526](../../Core/Capabilities.lua#L526) | `RegisterUnitEvent` | `"UNIT_HEALTH", "focus"` |
| [Core/Client_Camelot.lua:171](../../Core/Client_Camelot.lua#L171) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Core/Engine/Combat.lua:181](../../Core/Engine/Combat.lua#L181) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/Engine/Context.lua:281](../../Core/Engine/Context.lua#L281) | `Subscribe` | `fn` |
| [Core/Engine/Context.lua:537](../../Core/Engine/Context.lua#L537) | `RegisterEvent` | `"UPDATE_MOUSEOVER_UNIT"` |
| [Core/Engine/Context.lua:538](../../Core/Engine/Context.lua#L538) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [Core/Engine/Context.lua:539](../../Core/Engine/Context.lua#L539) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/Engine/Context.lua:540](../../Core/Engine/Context.lua#L540) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Core/Engine/Modifier.lua:94](../../Core/Engine/Modifier.lua#L94) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Core/Engine/Restricted.lua:336](../../Core/Engine/Restricted.lua#L336) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [Core/Engine/Restricted.lua:337](../../Core/Engine/Restricted.lua#L337) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [Core/Engine/Restricted.lua:338](../../Core/Engine/Restricted.lua#L338) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Core/Engine/Restricted.lua:339](../../Core/Engine/Restricted.lua#L339) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/Engine/Restricted.lua:340](../../Core/Engine/Restricted.lua#L340) | `RegisterEvent` | `"UNIT_PET"` |
| [Core/Engine/Restricted.lua:341](../../Core/Engine/Restricted.lua#L341) | `RegisterEvent` | `"UNIT_TARGET"` |
| [Core/Engine/Restricted.lua:342](../../Core/Engine/Restricted.lua#L342) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [Core/Engine/Restricted.lua:343](../../Core/Engine/Restricted.lua#L343) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [Core/Engine/Restricted.lua:344](../../Core/Engine/Restricted.lua#L344) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Core/Engine/Restricted.lua:345](../../Core/Engine/Restricted.lua#L345) | `RegisterEvent` | `"ACTIONBAR_PAGE_CHANGED"` |
| [Core/Engine/Restricted.lua:346](../../Core/Engine/Restricted.lua#L346) | `RegisterEvent` | `"UPDATE_BONUS_ACTIONBAR"` |
| [Core/Engine/Restricted.lua:347](../../Core/Engine/Restricted.lua#L347) | `RegisterEvent` | `"UPDATE_STEALTH"` |
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
| [Core/FluxAPI/UI.lua:503](../../Core/FluxAPI/UI.lua#L503) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Core/FluxAPI/UI.lua:504](../../Core/FluxAPI/UI.lua#L504) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Core/FluxAPI/UI.lua:1346](../../Core/FluxAPI/UI.lua#L1346) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Core/FluxAPI/UI.lua:1347](../../Core/FluxAPI/UI.lua#L1347) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Core/FluxAPI/UI.lua:1348](../../Core/FluxAPI/UI.lua#L1348) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Core/FluxAPI/UI.lua:1349](../../Core/FluxAPI/UI.lua#L1349) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [Core/FluxAPI/UI.lua:1350](../../Core/FluxAPI/UI.lua#L1350) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [Core/FluxAPI/UI.lua:1351](../../Core/FluxAPI/UI.lua#L1351) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Core/FluxAPI/UI.lua:1352](../../Core/FluxAPI/UI.lua#L1352) | `RegisterUnitEvent` | `"UNIT_MAXPOWER", "player"` |
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
| [ExtraButtonSystem/Engine/ConsumableBind.lua:1887](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1887) | `RegisterEvent` | `"TRADE_SKILL_SHOW"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:2660](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2660) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:2661](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2661) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:2662](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2662) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:2663](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2663) | `RegisterEvent` | `"BAG_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:3518](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3518) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:3519](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3519) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:3520](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3520) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/ExtraButtons/Buttons.lua:122](../../ExtraButtonSystem/ExtraButtons/Buttons.lua#L122) | `RegisterEvent` | `"CURSOR_CHANGED"` |
| [ExtraButtonSystem/ExtraButtons/UI.lua:579](../../ExtraButtonSystem/ExtraButtons/UI.lua#L579) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/ExtraButtons/UI.lua:758](../../ExtraButtonSystem/ExtraButtons/UI.lua#L758) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/ExtraButtons/UI.lua:759](../../ExtraButtonSystem/ExtraButtons/UI.lua#L759) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ExtraButtonSystem/ExtraButtons/UI.lua:760](../../ExtraButtonSystem/ExtraButtons/UI.lua#L760) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:1415](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1415) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:1416](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1416) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6333](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6333) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6334](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6334) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6336](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6336) | `RegisterUnitEvent` | `"UNIT_AURA", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6339](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6339) | `RegisterEvent` | `"UNIT_AURA"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6343](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6343) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6346](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6346) | `RegisterEvent` | `"UNIT_SPELLCAST_SUCCEEDED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6349](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6349) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6350](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6350) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6352](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6352) | `RegisterEvent` | `"PLAYER_DEAD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6353](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6353) | `RegisterEvent` | `"PLAYER_ALIVE"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6354](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6354) | `RegisterEvent` | `"PLAYER_UNGHOST"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6355](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6355) | `RegisterEvent` | `"SPELL_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6356](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6356) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6357](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6357) | `RegisterEvent` | `"WEAPON_ENCHANT_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6359](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6359) | `RegisterUnitEvent` | `"UNIT_INVENTORY_CHANGED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua:6362](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6362) | `RegisterEvent` | `"UNIT_INVENTORY_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua:1105](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1105) | `RegisterEvent` | `"SPELL_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua:1106](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1106) | `RegisterEvent` | `"ACTIONBAR_SLOT_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua:1140](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1140) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua:1141](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1141) | `RegisterUnitEvent` | `"UNIT_AURA", "player"` |
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
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3130](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3130) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3131](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3131) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3132](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3132) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3133](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3133) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3141](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3141) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3145](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3145) | `RegisterEvent` | `"SKILL_LINES_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3148](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3148) | `RegisterEvent` | `"SKILL_LINES_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3153](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3153) | `RegisterEvent` | `"MOUNT_JOURNAL_USABILITY_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3154](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3154) | `RegisterEvent` | `"NEW_MOUNT_ADDED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3157](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3157) | `RegisterEvent` | `"COLLECTIONS_UPDATED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3159](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3159) | `RegisterEvent` | `"COLLECTIONS_UPDATED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3162](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3162) | `RegisterEvent` | `"COMPANION_LEARNED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3166](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3166) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_START", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3167](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3167) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_STOP", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3168](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3168) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3169](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3169) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_INTERRUPTED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3170](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3170) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_FAILED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua:3171](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3171) | `RegisterEvent` | `"PLAYER_MOUNT_DISPLAY_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua:816](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L816) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua:817](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua#L817) | `RegisterEvent` | `"GET_ITEM_INFO_RECEIVED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2890](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2890) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2891](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2891) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2899](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2899) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2902](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2902) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_START", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2903](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2903) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2904](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2904) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_STOP", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2905](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2905) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_INTERRUPTED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua:2906](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2906) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_FAILED", "player"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua:174](../../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua#L174) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua:175](../../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua#L175) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua:176](../../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua#L176) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua:209](../../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua#L209) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:390](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L390) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:797](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L797) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:798](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L798) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:967](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L967) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:984](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L984) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:985](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L985) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:986](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L986) | `RegisterEvent` | `"NEW_MOUNT_ADDED"` |
| [ExtraButtonSystem/NonCombatGrid/GridInit.lua:139](../../ExtraButtonSystem/NonCombatGrid/GridInit.lua#L139) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/GridInit.lua:140](../../ExtraButtonSystem/NonCombatGrid/GridInit.lua#L140) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua:832](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L832) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1155](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1155) | `RegisterEvent` | `"CURSOR_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1156](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1156) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1157](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1157) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1158](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1158) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1160](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1160) | `RegisterEvent` | `"TRANSMOG_OUTFITS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1161](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1161) | `RegisterEvent` | `"TRANSMOG_DISPLAYED_OUTFIT_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1165](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1165) | `RegisterEvent` | `"SPELL_UPDATE_CHARGES"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1170](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1170) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1172](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1172) | `RegisterEvent` | `"BAG_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1173](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1173) | `RegisterEvent` | `"CURRENT_SPELL_CAST_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1174](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1174) | `RegisterEvent` | `"ACTIONBAR_UPDATE_STATE"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1175](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1175) | `RegisterEvent` | `"COMPANION_UPDATE"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1177](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1177) | `RegisterEvent` | `"PET_JOURNAL_LIST_UPDATE"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1179](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1179) | `RegisterEvent` | `"PLAYER_MOUNT_DISPLAY_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1181](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1181) | `RegisterUnitEvent` | `"UNIT_PET", "player"` |
| [ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua:626](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L626) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/Shared/HotkeyUtil.lua:415](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L415) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/Shared/HotkeyUtil.lua:416](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L416) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [ExtraButtonSystem/Shared/HotkeyUtil.lua:417](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L417) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua:828](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L828) | `RegisterEvent` | `"GLOBAL_MOUSE_UP"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua:829](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L829) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
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
| [FluxDefaultSettings.lua:1163](../../FluxDefaultSettings.lua#L1163) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [FluxDefaultSettings.lua:2885](../../FluxDefaultSettings.lua#L2885) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [FluxDefaultSettings.lua:2886](../../FluxDefaultSettings.lua#L2886) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [FluxDefaultSettings.lua:2887](../../FluxDefaultSettings.lua#L2887) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [FluxDefaultSettings.lua:2889](../../FluxDefaultSettings.lua#L2889) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [FluxDefaultSettings.lua:2892](../../FluxDefaultSettings.lua#L2892) | `RegisterEvent` | `"COMPACT_UNIT_FRAME_PROFILES_LOADED"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:1165](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L1165) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:2425](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2425) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:2426](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2426) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:2427](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2427) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:2428](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2428) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Inventory/Builtin/FluxClassicCombinedBag.lua:2429](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2429) | `RegisterEvent` | `"CURSOR_CHANGED"` |
| [Inventory/Builtin/FluxClassicCombinedBank.lua:500](../../Inventory/Builtin/FluxClassicCombinedBank.lua#L500) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Builtin/FluxClassicCombinedBank.lua:501](../../Inventory/Builtin/FluxClassicCombinedBank.lua#L501) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Inventory/Builtin/FluxClassicCombinedBank.lua:502](../../Inventory/Builtin/FluxClassicCombinedBank.lua#L502) | `RegisterEvent` | `"BANKFRAME_OPENED"` |
| [Inventory/Builtin/FluxClassicCombinedBank.lua:503](../../Inventory/Builtin/FluxClassicCombinedBank.lua#L503) | `RegisterEvent` | `"BANKFRAME_CLOSED"` |
| [Inventory/Builtin/FluxClassicCombinedBank.lua:504](../../Inventory/Builtin/FluxClassicCombinedBank.lua#L504) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Inventory/Builtin/FluxClassicCombinedBank.lua:505](../../Inventory/Builtin/FluxClassicCombinedBank.lua#L505) | `RegisterEvent` | `"PLAYERBANKSLOTS_CHANGED"` |
| [Inventory/Builtin/FluxClassicCombinedBank.lua:506](../../Inventory/Builtin/FluxClassicCombinedBank.lua#L506) | `RegisterEvent` | `"PLAYERBANKBAGSLOTS_CHANGED"` |
| [Inventory/Builtin/FluxClassicCombinedBank.lua:507](../../Inventory/Builtin/FluxClassicCombinedBank.lua#L507) | `RegisterEvent` | `"PLAYER_MONEY"` |
| [Inventory/Builtin/Mail.lua:402](../../Inventory/Builtin/Mail.lua#L402) | `RegisterEvent` | `"MAIL_SEND_SUCCESS"` |
| [Inventory/Builtin/Mail.lua:403](../../Inventory/Builtin/Mail.lua#L403) | `RegisterEvent` | `"MAIL_FAILED"` |
| [Inventory/Builtin/Mail.lua:429](../../Inventory/Builtin/Mail.lua#L429) | `RegisterEvent` | `"MAIL_SUCCESS"` |
| [Inventory/Builtin/Mail.lua:430](../../Inventory/Builtin/Mail.lua#L430) | `RegisterEvent` | `"MAIL_FAILED"` |
| [Inventory/CreateSpells.lua:441](../../Inventory/CreateSpells.lua#L441) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Inventory/CreateSpells.lua:457](../../Inventory/CreateSpells.lua#L457) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:473](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L473) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:474](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L474) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:475](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L475) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:476](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L476) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:477](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L477) | `RegisterEvent` | `"SKILL_LINES_CHANGED"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:478](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L478) | `RegisterEvent` | `"UNIT_MAXHEALTH"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:479](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L479) | `RegisterEvent` | `"UNIT_MAXPOWER"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:629](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L629) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [Inventory/FluxItemClass.lua:665](../../Inventory/FluxItemClass.lua#L665) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [Inventory/FluxItemClass.lua:666](../../Inventory/FluxItemClass.lua#L666) | `RegisterEvent` | `"GET_ITEM_INFO_RECEIVED"` |
| [Inventory/Init.lua:315](../../Inventory/Init.lua#L315) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:516](../../Inventory/Restock/Bank/FluxBankRestock.lua#L516) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:517](../../Inventory/Restock/Bank/FluxBankRestock.lua#L517) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:518](../../Inventory/Restock/Bank/FluxBankRestock.lua#L518) | `RegisterEvent` | `"ITEM_UNLOCKED"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:519](../../Inventory/Restock/Bank/FluxBankRestock.lua#L519) | `RegisterEvent` | `"PLAYERBANKBAGSLOTS_CHANGED"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:2334](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2334) | `RegisterEvent` | `"UI_ERROR_MESSAGE"` |
| [Inventory/Restock/Core/FluxRestockList.lua:1569](../../Inventory/Restock/Core/FluxRestockList.lua#L1569) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Core/FluxRestockSettings.lua:228](../../Inventory/Restock/Core/FluxRestockSettings.lua#L228) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Junk/FluxJunk.lua:1693](../../Inventory/Restock/Junk/FluxJunk.lua#L1693) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Junk/FluxJunk.lua:1694](../../Inventory/Restock/Junk/FluxJunk.lua#L1694) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1868](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1868) | `RegisterEvent` | `ev` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1952](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1952) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1953](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1953) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1954](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1954) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1955](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1955) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [Inventory/Restock/Junk/FluxVendorJunkPanel.lua:714](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L714) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [Inventory/Restock/Junk/FluxVendorJunkPanel.lua:760](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L760) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua:154](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L154) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnown.lua:496](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L496) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnown.lua:497](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L497) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua:574](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L574) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua:94](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L94) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua:3456](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3456) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua:3457](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3457) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua:3458](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3458) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1717](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1717) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1718](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1718) | `RegisterEvent` | `"MERCHANT_UPDATE"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1719](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1719) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1720](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1720) | `RegisterEvent` | `"UI_ERROR_MESSAGE"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1728](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1728) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Vendor/FluxVendorRestockPanel.lua:1068](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1068) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Vendor/FluxVendorRestockPanel.lua:1255](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1255) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Layout/UnifiedBorder.lua:857](../../Layout/UnifiedBorder.lua#L857) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Layout/UnifiedBorder.lua:858](../../Layout/UnifiedBorder.lua#L858) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Layout/UnifiedBorder.lua:859](../../Layout/UnifiedBorder.lua#L859) | `RegisterEvent` | `"ACTIONBAR_SLOT_CHANGED"` |
| [Layout/UnifiedBorder.lua:860](../../Layout/UnifiedBorder.lua#L860) | `RegisterEvent` | `"CURSOR_CHANGED"` |
| [Mail/CategoryAttach.lua:170](../../Mail/CategoryAttach.lua#L170) | `RegisterEvent` | `"MAIL_SHOW"` |
| [Mail/CategoryAttach.lua:171](../../Mail/CategoryAttach.lua#L171) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
| [Mail/Contacts.lua:278](../../Mail/Contacts.lua#L278) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Mail/Contacts.lua:279](../../Mail/Contacts.lua#L279) | `RegisterEvent` | `"MAIL_SHOW"` |
| [Mail/Contacts.lua:280](../../Mail/Contacts.lua#L280) | `RegisterEvent` | `"MAIL_CLOSED"` |
| [Mail/Contacts.lua:281](../../Mail/Contacts.lua#L281) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
| [Mail/Contacts.lua:282](../../Mail/Contacts.lua#L282) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_HIDE"` |
| [Mail/Contacts.lua:283](../../Mail/Contacts.lua#L283) | `RegisterEvent` | `"MAIL_SEND_SUCCESS"` |
| [Mail/Contacts.lua:284](../../Mail/Contacts.lua#L284) | `RegisterEvent` | `"MAIL_FAILED"` |
| [Mail/Conveniences.lua:191](../../Mail/Conveniences.lua#L191) | `RegisterEvent` | `"MAIL_SHOW"` |
| [Mail/Conveniences.lua:192](../../Mail/Conveniences.lua#L192) | `RegisterEvent` | `"MAIL_CLOSED"` |
| [Mail/Conveniences.lua:193](../../Mail/Conveniences.lua#L193) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
| [Mail/Conveniences.lua:194](../../Mail/Conveniences.lua#L194) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_HIDE"` |
| [Mail/Conveniences.lua:195](../../Mail/Conveniences.lua#L195) | `RegisterEvent` | `"MAIL_INBOX_UPDATE"` |
| [Mail/Conveniences.lua:196](../../Mail/Conveniences.lua#L196) | `RegisterEvent` | `"MAIL_SEND_SUCCESS"` |
| [Mail/Conveniences.lua:197](../../Mail/Conveniences.lua#L197) | `RegisterEvent` | `"PLAYER_LEAVING_WORLD"` |
| [Mail/DoNotWant.lua:101](../../Mail/DoNotWant.lua#L101) | `RegisterEvent` | `"MAIL_SHOW"` |
| [Mail/DoNotWant.lua:102](../../Mail/DoNotWant.lua#L102) | `RegisterEvent` | `"MAIL_CLOSED"` |
| [Mail/DoNotWant.lua:103](../../Mail/DoNotWant.lua#L103) | `RegisterEvent` | `"MAIL_INBOX_UPDATE"` |
| [Mail/DoNotWant.lua:104](../../Mail/DoNotWant.lua#L104) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
| [Mail/DoNotWant.lua:105](../../Mail/DoNotWant.lua#L105) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_HIDE"` |
| [Mail/OpenAll.lua:130](../../Mail/OpenAll.lua#L130) | `RegisterEvent` | `"MAIL_SHOW"` |
| [Mail/OpenAll.lua:131](../../Mail/OpenAll.lua#L131) | `RegisterEvent` | `"MAIL_CLOSED"` |
| [Mail/OpenAll.lua:132](../../Mail/OpenAll.lua#L132) | `RegisterEvent` | `"MAIL_INBOX_UPDATE"` |
| [Mail/OpenAll.lua:133](../../Mail/OpenAll.lua#L133) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
| [Mail/OpenAll.lua:134](../../Mail/OpenAll.lua#L134) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_HIDE"` |
| [Mail/QuickAttach.lua:73](../../Mail/QuickAttach.lua#L73) | `RegisterEvent` | `"MAIL_SHOW"` |
| [Mail/QuickAttach.lua:74](../../Mail/QuickAttach.lua#L74) | `RegisterEvent` | `"MAIL_CLOSED"` |
| [Mail/QuickAttach.lua:75](../../Mail/QuickAttach.lua#L75) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
| [Mail/QuickAttach.lua:76](../../Mail/QuickAttach.lua#L76) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_HIDE"` |
| [Mail/QuickAttach.lua:77](../../Mail/QuickAttach.lua#L77) | `RegisterEvent` | `"PLAYER_LEAVING_WORLD"` |
| [Mail/Restock.lua:208](../../Mail/Restock.lua#L208) | `RegisterEvent` | `event` |
| [Mail/Select.lua:464](../../Mail/Select.lua#L464) | `RegisterEvent` | `"MAIL_SHOW"` |
| [Mail/Select.lua:465](../../Mail/Select.lua#L465) | `RegisterEvent` | `"MAIL_CLOSED"` |
| [Mail/Select.lua:466](../../Mail/Select.lua#L466) | `RegisterEvent` | `"MAIL_INBOX_UPDATE"` |
| [Mail/Select.lua:467](../../Mail/Select.lua#L467) | `RegisterEvent` | `"MAIL_FAILED"` |
| [Mail/Select.lua:468](../../Mail/Select.lua#L468) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
| [Mail/Select.lua:469](../../Mail/Select.lua#L469) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_HIDE"` |
| [Mail/Select.lua:470](../../Mail/Select.lua#L470) | `RegisterEvent` | `"PLAYER_LEAVING_WORLD"` |
| [Mail/Settings.lua:334](../../Mail/Settings.lua#L334) | `RegisterEvent` | `"MAIL_SHOW"` |
| [Mail/Settings.lua:335](../../Mail/Settings.lua#L335) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
| [Mail/TradeBlock.lua:30](../../Mail/TradeBlock.lua#L30) | `RegisterEvent` | `"MAIL_SHOW"` |
| [Mail/TradeBlock.lua:31](../../Mail/TradeBlock.lua#L31) | `RegisterEvent` | `"MAIL_CLOSED"` |
| [Mail/TradeBlock.lua:32](../../Mail/TradeBlock.lua#L32) | `RegisterEvent` | `"PLAYER_LEAVING_WORLD"` |
| [Mail/TradeBlock.lua:33](../../Mail/TradeBlock.lua#L33) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
| [Mail/TradeBlock.lua:34](../../Mail/TradeBlock.lua#L34) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_HIDE"` |
| [MicroMenu/FluxAddonMicroButton.lua:103](../../MicroMenu/FluxAddonMicroButton.lua#L103) | `RegisterEvent` | `"PLAYER_STARTED_MOVING"` |
| [MicroMenu/FluxAddonMicroButton.lua:638](../../MicroMenu/FluxAddonMicroButton.lua#L638) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxAddonMicroButton.lua:639](../../MicroMenu/FluxAddonMicroButton.lua#L639) | `RegisterEvent` | `"PLAYER_LOGIN"` |
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
| [MicroMenu/FluxLFGMicroButton.lua:422](../../MicroMenu/FluxLFGMicroButton.lua#L422) | `RegisterEvent` | `"LFG_LIST_ACTIVE_ENTRY_UPDATE"` |
| [MicroMenu/FluxLFGMicroButton.lua:423](../../MicroMenu/FluxLFGMicroButton.lua#L423) | `RegisterEvent` | `"LFG_LIST_APPLICANT_UPDATED"` |
| [MicroMenu/FluxLFGMicroButton.lua:424](../../MicroMenu/FluxLFGMicroButton.lua#L424) | `RegisterEvent` | `"LFG_UPDATE"` |
| [MicroMenu/FluxLFGMicroButton.lua:425](../../MicroMenu/FluxLFGMicroButton.lua#L425) | `RegisterEvent` | `"LFG_QUEUE_STATUS_UPDATE"` |
| [MicroMenu/FluxLFGMicroButton.lua:426](../../MicroMenu/FluxLFGMicroButton.lua#L426) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxLFGMicroButton.lua:427](../../MicroMenu/FluxLFGMicroButton.lua#L427) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [MicroMenu/FluxLFGMicroButton.lua:456](../../MicroMenu/FluxLFGMicroButton.lua#L456) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [MicroMenu/FluxLFGMicroButton.lua:457](../../MicroMenu/FluxLFGMicroButton.lua#L457) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxMicroMenu.lua:435](../../MicroMenu/FluxMicroMenu.lua#L435) | `RegisterEvent` | `"UNIT_PORTRAIT_UPDATE"` |
| [MicroMenu/FluxMicroMenu.lua:436](../../MicroMenu/FluxMicroMenu.lua#L436) | `RegisterEvent` | `"PORTRAITS_UPDATED"` |
| [MicroMenu/FluxMicroMenu.lua:437](../../MicroMenu/FluxMicroMenu.lua#L437) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxMicroMenu.lua:3066](../../MicroMenu/FluxMicroMenu.lua#L3066) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [MicroMenu/FluxMicroMenu.lua:3067](../../MicroMenu/FluxMicroMenu.lua#L3067) | `RegisterEvent` | `"ADDON_LOADED"` |
| [MicroMenu/FluxMicroMenu.lua:3068](../../MicroMenu/FluxMicroMenu.lua#L3068) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [MicroMenu/FluxMicroMenu.lua:3069](../../MicroMenu/FluxMicroMenu.lua#L3069) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [MicroMenu/FluxMicroMenu.lua:3070](../../MicroMenu/FluxMicroMenu.lua#L3070) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxMicroMenu.lua:3071](../../MicroMenu/FluxMicroMenu.lua#L3071) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [MicroMenu/FluxMicroMenu.lua:3072](../../MicroMenu/FluxMicroMenu.lua#L3072) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [MicroMenu/FluxMicroMenuConfigUI.lua:451](../../MicroMenu/FluxMicroMenuConfigUI.lua#L451) | `RegisterEvent` | `"PLAYER_STARTED_MOVING"` |
| [MicroMenu/FluxMinimapToMicro.lua:751](../../MicroMenu/FluxMinimapToMicro.lua#L751) | `RegisterEvent` | `"PLAYER_STARTED_MOVING"` |
| [MicroMenu/FluxMinimapToMicro.lua:1327](../../MicroMenu/FluxMinimapToMicro.lua#L1327) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [MicroMenu/FluxMinimapToMicro.lua:1328](../../MicroMenu/FluxMinimapToMicro.lua#L1328) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxTradeSkillMicro.lua:703](../../MicroMenu/FluxTradeSkillMicro.lua#L703) | `RegisterEvent` | `"PLAYER_STARTED_MOVING"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1076](../../MicroMenu/FluxTradeSkillMicro.lua#L1076) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1077](../../MicroMenu/FluxTradeSkillMicro.lua#L1077) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1078](../../MicroMenu/FluxTradeSkillMicro.lua#L1078) | `RegisterEvent` | `"SKILL_LINES_CHANGED"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1079](../../MicroMenu/FluxTradeSkillMicro.lua#L1079) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1083](../../MicroMenu/FluxTradeSkillMicro.lua#L1083) | `RegisterEvent` | `"LEARNED_SPELL_IN_SKILL_LINE"` |
| [MicroMenu/FluxTradeSkillMicro.lua:1084](../../MicroMenu/FluxTradeSkillMicro.lua#L1084) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [Minimap/FluxBuffDebuffFrames.lua:96](../../Minimap/FluxBuffDebuffFrames.lua#L96) | `RegisterEvent` | `event` |
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
| [Minimap/FluxMinimap.lua:438](../../Minimap/FluxMinimap.lua#L438) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:439](../../Minimap/FluxMinimap.lua#L439) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [Minimap/FluxMinimap.lua:440](../../Minimap/FluxMinimap.lua#L440) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [Minimap/FluxMinimap.lua:442](../../Minimap/FluxMinimap.lua#L442) | `RegisterEvent` | `"EDIT_MODE_LAYOUTS_UPDATED"` |
| [Minimap/FluxMinimap.lua:826](../../Minimap/FluxMinimap.lua#L826) | `RegisterEvent` | `"UPDATE_PENDING_MAIL"` |
| [Minimap/FluxMinimap.lua:827](../../Minimap/FluxMinimap.lua#L827) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:1218](../../Minimap/FluxMinimap.lua#L1218) | `RegisterEvent` | `"UPDATE_BATTLEFIELD_STATUS"` |
| [Minimap/FluxMinimap.lua:1219](../../Minimap/FluxMinimap.lua#L1219) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:1220](../../Minimap/FluxMinimap.lua#L1220) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimap.lua:1221](../../Minimap/FluxMinimap.lua#L1221) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [Minimap/FluxMinimap.lua:1222](../../Minimap/FluxMinimap.lua#L1222) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [Minimap/FluxMinimap.lua:1223](../../Minimap/FluxMinimap.lua#L1223) | `RegisterEvent` | `"EDIT_MODE_LAYOUTS_UPDATED"` |
| [Minimap/FluxMinimap.lua:1224](../../Minimap/FluxMinimap.lua#L1224) | `RegisterEvent` | `"PVPQUEUE_ANYWHERE_SHOW"` |
| [Minimap/FluxMinimap.lua:1225](../../Minimap/FluxMinimap.lua#L1225) | `RegisterEvent` | `"PVPQUEUE_ANYWHERE_UPDATE_AVAILABLE"` |
| [Minimap/FluxMinimap.lua:1929](../../Minimap/FluxMinimap.lua#L1929) | `RegisterEvent` | `"ZONE_CHANGED"` |
| [Minimap/FluxMinimap.lua:1930](../../Minimap/FluxMinimap.lua#L1930) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [Minimap/FluxMinimap.lua:1931](../../Minimap/FluxMinimap.lua#L1931) | `RegisterEvent` | `"ZONE_CHANGED_INDOORS"` |
| [Minimap/FluxMinimap.lua:1932](../../Minimap/FluxMinimap.lua#L1932) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:2305](../../Minimap/FluxMinimap.lua#L2305) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimap.lua:2542](../../Minimap/FluxMinimap.lua#L2542) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimapButtons.lua:710](../../Minimap/FluxMinimapButtons.lua#L710) | `RegisterEvent` | `"CURSOR_CHANGED"` |
| [Minimap/FluxMinimapButtons.lua:751](../../Minimap/FluxMinimapButtons.lua#L751) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Minimap/FluxMinimapButtons.lua:752](../../Minimap/FluxMinimapButtons.lua#L752) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Minimap/FluxMinimapButtons.lua:753](../../Minimap/FluxMinimapButtons.lua#L753) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimapButtons.lua:754](../../Minimap/FluxMinimapButtons.lua#L754) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [Minimap/FluxMinimapButtons.lua:755](../../Minimap/FluxMinimapButtons.lua#L755) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:248](../../Minimap/FluxObjectiveTrackerScroll.lua#L248) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:630](../../Minimap/FluxObjectiveTrackerScroll.lua#L630) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:1089](../../Minimap/FluxObjectiveTrackerScroll.lua#L1089) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:1307](../../Minimap/FluxObjectiveTrackerScroll.lua#L1307) | `RegisterEvent` | `"QUEST_LOG_UPDATE"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:1541](../../Minimap/FluxObjectiveTrackerScroll.lua#L1541) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Minimap/FluxQuestie.lua:9](../../Minimap/FluxQuestie.lua#L9) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Minimap/FluxQuestie.lua:10](../../Minimap/FluxQuestie.lua#L10) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxQuestie.lua:11](../../Minimap/FluxQuestie.lua#L11) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Minimap/FluxQuestie.lua:12](../../Minimap/FluxQuestie.lua#L12) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [NamePlates/ComboPoints.lua:137](../../NamePlates/ComboPoints.lua#L137) | `RegisterEvent` | `event` |
| [NamePlates/ComboPoints.lua:141](../../NamePlates/ComboPoints.lua#L141) | `RegisterUnitEvent` | `event, "player", "vehicle"` |
| [NamePlates/ComboPoints.lua:144](../../NamePlates/ComboPoints.lua#L144) | `RegisterUnitEvent` | `"UNIT_POWER_POINT_CHARGE", "player", "vehicle"` |
| [NamePlates/Core.lua:582](../../NamePlates/Core.lua#L582) | `RegisterEvent` | `"NAME_PLATE_UNIT_ADDED"` |
| [NamePlates/Core.lua:583](../../NamePlates/Core.lua#L583) | `RegisterEvent` | `"NAME_PLATE_UNIT_REMOVED"` |
| [NamePlates/Core.lua:584](../../NamePlates/Core.lua#L584) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [NamePlates/Core.lua:585](../../NamePlates/Core.lua#L585) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [NamePlates/Core.lua:586](../../NamePlates/Core.lua#L586) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [NamePlates/Core.lua:587](../../NamePlates/Core.lua#L587) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
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
| [Other/FluxChatColumnMicros.lua:1014](../../Other/FluxChatColumnMicros.lua#L1014) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Other/FluxChatColumnMicros.lua:1061](../../Other/FluxChatColumnMicros.lua#L1061) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxChatColumnMicros.lua:1062](../../Other/FluxChatColumnMicros.lua#L1062) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatColumnMicros.lua:1187](../../Other/FluxChatColumnMicros.lua#L1187) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxChatColumnMicros.lua:1188](../../Other/FluxChatColumnMicros.lua#L1188) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatColumnMicros.lua:1271](../../Other/FluxChatColumnMicros.lua#L1271) | `RegisterEvent` | `"UPDATE_INVENTORY_DURABILITY"` |
| [Other/FluxChatColumnMicros.lua:1272](../../Other/FluxChatColumnMicros.lua#L1272) | `RegisterEvent` | `"UPDATE_INVENTORY_ALERTS"` |
| [Other/FluxChatColumnMicros.lua:1273](../../Other/FluxChatColumnMicros.lua#L1273) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Other/FluxChatColumnMicros.lua:1274](../../Other/FluxChatColumnMicros.lua#L1274) | `RegisterEvent` | `"UNIT_INVENTORY_CHANGED"` |
| [Other/FluxChatColumnMicros.lua:1275](../../Other/FluxChatColumnMicros.lua#L1275) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatColumnMicros.lua:1276](../../Other/FluxChatColumnMicros.lua#L1276) | `RegisterEvent` | `"UNIT_PORTRAIT_UPDATE"` |
| [Other/FluxChatColumnMicros.lua:1277](../../Other/FluxChatColumnMicros.lua#L1277) | `RegisterEvent` | `"PORTRAITS_UPDATED"` |
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
| [Other/FluxHUDTooltip.lua:131](../../Other/FluxHUDTooltip.lua#L131) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxLoot.lua:454](../../Other/FluxLoot.lua#L454) | `RegisterEvent` | `"LOOT_READY"` |
| [Other/FluxLoot.lua:457](../../Other/FluxLoot.lua#L457) | `RegisterEvent` | `event` |
| [Other/FluxLoot.lua:543](../../Other/FluxLoot.lua#L543) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Other/FluxLootRollPosition.lua:40](../../Other/FluxLootRollPosition.lua#L40) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxLootRollPosition.lua:84](../../Other/FluxLootRollPosition.lua#L84) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxLootRollPosition.lua:85](../../Other/FluxLootRollPosition.lua#L85) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxPerfCapture.lua:617](../../Other/FluxPerfCapture.lua#L617) | `RegisterEvent` | `"PLAYER_LOGOUT"` |
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
| [RaidFrame/FluxRaidFrame_BigDebuffs.lua:152](../../RaidFrame/FluxRaidFrame_BigDebuffs.lua#L152) | `RegisterEvent` | `"ADDON_LOADED"` |
| [RaidFrame/FluxRaidHoTs.lua:194](../../RaidFrame/FluxRaidHoTs.lua#L194) | `RegisterEvent` | `"UNIT_AURA"` |
| [RaidFrame/FluxRaidHoTs.lua:314](../../RaidFrame/FluxRaidHoTs.lua#L314) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SENT", "player"` |
| [RaidFrame/FluxRaidHoTs.lua:315](../../RaidFrame/FluxRaidHoTs.lua#L315) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [RaidFrame/FluxRaidHoTs.lua:319](../../RaidFrame/FluxRaidHoTs.lua#L319) | `RegisterEvent` | `event` |
| [RaidFrame/FluxRaidPreview.lua:918](../../RaidFrame/FluxRaidPreview.lua#L918) | `RegisterEvent` | `"CVAR_UPDATE"` |
| [RaidFrame/FluxRaidPreview.lua:939](../../RaidFrame/FluxRaidPreview.lua#L939) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [RaidFrame/FluxRaidPreview.lua:940](../../RaidFrame/FluxRaidPreview.lua#L940) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [RaidFrame/FluxRaidPreview.lua:941](../../RaidFrame/FluxRaidPreview.lua#L941) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [RaidFrame/FluxRaidPreview.lua:942](../../RaidFrame/FluxRaidPreview.lua#L942) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [RaidFrame/FluxRaidUnit.lua:113](../../RaidFrame/FluxRaidUnit.lua#L113) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [RaidFrame/FluxRaidUnit.lua:552](../../RaidFrame/FluxRaidUnit.lua#L552) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Respec/FluxRespec_ActionBars.lua:622](../../Respec/FluxRespec_ActionBars.lua#L622) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
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
| [Respec/FluxRespec_Equipment.lua:1713](../../Respec/FluxRespec_Equipment.lua#L1713) | `RegisterEvent` | `"ITEM_LOCK_CHANGED"` |
| [Respec/FluxRespec_Equipment.lua:1714](../../Respec/FluxRespec_Equipment.lua#L1714) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Respec/FluxRespec_Equipment.lua:1715](../../Respec/FluxRespec_Equipment.lua#L1715) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Respec/FluxRespec_Equipment.lua:1811](../../Respec/FluxRespec_Equipment.lua#L1811) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
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
| [Respec/FluxRespec_GearSetTooltip.lua:322](../../Respec/FluxRespec_GearSetTooltip.lua#L322) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_IconPicker.lua:475](../../Respec/FluxRespec_IconPicker.lua#L475) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Respec/FluxRespec_Register.lua:38](../../Respec/FluxRespec_Register.lua#L38) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_Register.lua:39](../../Respec/FluxRespec_Register.lua#L39) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Respec/FluxRespec_RunePresets.lua:678](../../Respec/FluxRespec_RunePresets.lua#L678) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Respec/FluxRespec_RunePresets.lua:679](../../Respec/FluxRespec_RunePresets.lua#L679) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_Runes.lua:19](../../Respec/FluxRespec_Runes.lua#L19) | `RegisterEvent` | `"RUNE_UPDATED"` |
| [Respec/FluxRespec_Runes.lua:266](../../Respec/FluxRespec_Runes.lua#L266) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Respec/FluxRespec_Runes.lua:268](../../Respec/FluxRespec_Runes.lua#L268) | `RegisterEvent` | `"UNIT_SPELLCAST_SUCCEEDED"` |
| [Respec/FluxRespec_Talents.lua:651](../../Respec/FluxRespec_Talents.lua#L651) | `RegisterEvent` | `"CHARACTER_POINTS_CHANGED"` |
| [Respec/FluxRespec_Talents.lua:652](../../Respec/FluxRespec_Talents.lua#L652) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Respec/FluxRespec_Talents.lua:756](../../Respec/FluxRespec_Talents.lua#L756) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Respec/FluxRespec_Talents.lua:757](../../Respec/FluxRespec_Talents.lua#L757) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [Respec/FluxRespec_Talents.lua:1417](../../Respec/FluxRespec_Talents.lua#L1417) | `RegisterEvent` | `"GOSSIP_SHOW"` |
| [Respec/FluxRespec_Talents.lua:1418](../../Respec/FluxRespec_Talents.lua#L1418) | `RegisterEvent` | `"GOSSIP_CLOSED"` |
| [Respec/FluxRespec_Talents.lua:1419](../../Respec/FluxRespec_Talents.lua#L1419) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Respec/FluxRespec_Talents.lua:1420](../../Respec/FluxRespec_Talents.lua#L1420) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Respec/FluxRespec_Talents.lua:1421](../../Respec/FluxRespec_Talents.lua#L1421) | `RegisterEvent` | `"GOSSIP_CONFIRM"` |
| [Respec/FluxRespec_Talents.lua:1422](../../Respec/FluxRespec_Talents.lua#L1422) | `RegisterEvent` | `"CONFIRM_TALENT_WIPE"` |
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
| [Salvage/FluxSalvage_Overlay.lua:72](../../Salvage/FluxSalvage_Overlay.lua#L72) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Salvage/FluxSalvage_Overlay.lua:867](../../Salvage/FluxSalvage_Overlay.lua#L867) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Salvage/FluxSalvage_Overlay.lua:868](../../Salvage/FluxSalvage_Overlay.lua#L868) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [StatusBars/FluxGoldLedger.lua:1343](../../StatusBars/FluxGoldLedger.lua#L1343) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [StatusBars/FluxGoldLedger.lua:1344](../../StatusBars/FluxGoldLedger.lua#L1344) | `RegisterEvent` | `"PLAYER_LOGOUT"` |
| [StatusBars/FluxGoldLedger.lua:1345](../../StatusBars/FluxGoldLedger.lua#L1345) | `RegisterEvent` | `"ADDON_LOADED"` |
| [StatusBars/FluxGoldLedger.lua:1415](../../StatusBars/FluxGoldLedger.lua#L1415) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [StatusBars/FluxInfoFrame.lua:4900](../../StatusBars/FluxInfoFrame.lua#L4900) | `RegisterEvent` | `"ZONE_CHANGED"` |
| [StatusBars/FluxInfoFrame.lua:4901](../../StatusBars/FluxInfoFrame.lua#L4901) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [StatusBars/FluxInfoFrame.lua:4902](../../StatusBars/FluxInfoFrame.lua#L4902) | `RegisterEvent` | `"PLAYER_UPDATE_RESTING"` |
| [StatusBars/FluxInfoFrame.lua:4903](../../StatusBars/FluxInfoFrame.lua#L4903) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [StatusBars/FluxInfoFrame.lua:4904](../../StatusBars/FluxInfoFrame.lua#L4904) | `RegisterEvent` | `"UPDATE_INVENTORY_ALERTS"` |
| [StatusBars/FluxInfoFrame.lua:4905](../../StatusBars/FluxInfoFrame.lua#L4905) | `RegisterUnitEvent` | `"UNIT_AURA", "player"` |
| [StatusBars/FluxInfoFrame.lua:4906](../../StatusBars/FluxInfoFrame.lua#L4906) | `RegisterEvent` | `"COMBAT_RATING_UPDATE"` |
| [StatusBars/FluxInfoFrame.lua:4907](../../StatusBars/FluxInfoFrame.lua#L4907) | `RegisterEvent` | `"MASTERY_UPDATE"` |
| [StatusBars/FluxInfoFrame.lua:4908](../../StatusBars/FluxInfoFrame.lua#L4908) | `RegisterEvent` | `"SPELL_POWER_CHANGED"` |
| [StatusBars/FluxInfoFrame.lua:4909](../../StatusBars/FluxInfoFrame.lua#L4909) | `RegisterUnitEvent` | `"UNIT_STATS", "player"` |
| [StatusBars/FluxInfoFrame.lua:4910](../../StatusBars/FluxInfoFrame.lua#L4910) | `RegisterEvent` | `"PLAYER_DAMAGE_DONE_MODS"` |
| [StatusBars/FluxInfoFrame.lua:4912](../../StatusBars/FluxInfoFrame.lua#L4912) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [StatusBars/FluxInfoFrame.lua:4913](../../StatusBars/FluxInfoFrame.lua#L4913) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [StatusBars/FluxInfoFrame.lua:4914](../../StatusBars/FluxInfoFrame.lua#L4914) | `RegisterUnitEvent` | `"UNIT_SPELL_HASTE", "player"` |
| [StatusBars/FluxInfoFrame.lua:5178](../../StatusBars/FluxInfoFrame.lua#L5178) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [StatusBars/FluxInfoFrame.lua:5179](../../StatusBars/FluxInfoFrame.lua#L5179) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
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
| [StatusBars/FluxStatusBar.lua:2570](../../StatusBars/FluxStatusBar.lua#L2570) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [StatusBars/FluxStatusBar.lua:2933](../../StatusBars/FluxStatusBar.lua#L2933) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [StatusBars/FluxStatusBar.lua:2934](../../StatusBars/FluxStatusBar.lua#L2934) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [StatusBars/FluxStatusBar.lua:2935](../../StatusBars/FluxStatusBar.lua#L2935) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [StatusBars/FluxStatusBar.lua:2936](../../StatusBars/FluxStatusBar.lua#L2936) | `RegisterEvent` | `"ADDON_LOADED"` |
| [StatusBars/FluxStatusBar.lua:2937](../../StatusBars/FluxStatusBar.lua#L2937) | `RegisterEvent` | `"PLAYER_XP_UPDATE"` |
| [StatusBars/FluxStatusBar.lua:2938](../../StatusBars/FluxStatusBar.lua#L2938) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [StatusBars/FluxStatusBar.lua:2939](../../StatusBars/FluxStatusBar.lua#L2939) | `RegisterEvent` | `"UPDATE_EXHAUSTION"` |
| [StatusBars/FluxStatusBar.lua:2940](../../StatusBars/FluxStatusBar.lua#L2940) | `RegisterEvent` | `"PLAYER_UPDATE_RESTING"` |
| [StatusBars/FluxStatusBar.lua:2941](../../StatusBars/FluxStatusBar.lua#L2941) | `RegisterEvent` | `"UPDATE_FACTION"` |
| [StatusBars/FluxStatusBar.lua:2942](../../StatusBars/FluxStatusBar.lua#L2942) | `RegisterEvent` | `"QUEST_LOG_UPDATE"` |
| [StatusBars/FluxStatusBar.lua:2943](../../StatusBars/FluxStatusBar.lua#L2943) | `RegisterEvent` | `"PLAYER_MONEY"` |
| [StatusBars/FluxStatusBar.lua:2944](../../StatusBars/FluxStatusBar.lua#L2944) | `RegisterEvent` | `"CURRENCY_DISPLAY_UPDATE"` |
| [StatusBars/FluxStatusBar.lua:2945](../../StatusBars/FluxStatusBar.lua#L2945) | `RegisterEvent` | `"UPDATE_INVENTORY_ALERTS"` |
| [UnitFrames/FluxCastBar.lua:2892](../../UnitFrames/FluxCastBar.lua#L2892) | `RegisterUnitEvent` | `event, unit` |
| [UnitFrames/FluxCastBar.lua:2925](../../UnitFrames/FluxCastBar.lua#L2925) | `RegisterEvent` | `"UNIT_SPELLCAST_SENT"` |
| [UnitFrames/FluxCastBar.lua:3512](../../UnitFrames/FluxCastBar.lua#L3512) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [UnitFrames/FluxCastBar.lua:3513](../../UnitFrames/FluxCastBar.lua#L3513) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxCastBarThemes.lua:978](../../UnitFrames/FluxCastBarThemes.lua#L978) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [UnitFrames/FluxCastBarThemes.lua:979](../../UnitFrames/FluxCastBarThemes.lua#L979) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxClassPower.lua:713](../../UnitFrames/FluxClassPower.lua#L713) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxClassPower.lua:714](../../UnitFrames/FluxClassPower.lua#L714) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [UnitFrames/FluxClassPower.lua:715](../../UnitFrames/FluxClassPower.lua#L715) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [UnitFrames/FluxClassPower.lua:716](../../UnitFrames/FluxClassPower.lua#L716) | `RegisterEvent` | `"UNIT_DISPLAYPOWER"` |
| [UnitFrames/FluxClassPower.lua:717](../../UnitFrames/FluxClassPower.lua#L717) | `RegisterEvent` | `"UNIT_POWER_UPDATE"` |
| [UnitFrames/FluxClassPower.lua:718](../../UnitFrames/FluxClassPower.lua#L718) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [UnitFrames/FluxClassPower.lua:719](../../UnitFrames/FluxClassPower.lua#L719) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxClassPower.lua:720](../../UnitFrames/FluxClassPower.lua#L720) | `RegisterEvent` | `"PLAYER_TOTEM_UPDATE"` |
| [UnitFrames/FluxClassPower.lua:721](../../UnitFrames/FluxClassPower.lua#L721) | `RegisterEvent` | `"RUNE_POWER_UPDATE"` |
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
| [UnitFrames/FluxMP5Overlay.lua:369](../../UnitFrames/FluxMP5Overlay.lua#L369) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [UnitFrames/FluxMP5Overlay.lua:370](../../UnitFrames/FluxMP5Overlay.lua#L370) | `RegisterUnitEvent` | `"UNIT_POWER_UPDATE", "player"` |
| [UnitFrames/FluxMP5Overlay.lua:371](../../UnitFrames/FluxMP5Overlay.lua#L371) | `RegisterUnitEvent` | `"UNIT_POWER_FREQUENT", "player"` |
| [UnitFrames/FluxMP5Overlay.lua:372](../../UnitFrames/FluxMP5Overlay.lua#L372) | `RegisterUnitEvent` | `"UNIT_DISPLAYPOWER", "player"` |
| [UnitFrames/FluxMP5Overlay.lua:373](../../UnitFrames/FluxMP5Overlay.lua#L373) | `RegisterUnitEvent` | `"UNIT_MAXPOWER", "player"` |
| [UnitFrames/FluxMP5Overlay.lua:374](../../UnitFrames/FluxMP5Overlay.lua#L374) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxMP5Overlay.lua:375](../../UnitFrames/FluxMP5Overlay.lua#L375) | `RegisterEvent` | `"PLAYER_ALIVE"` |
| [UnitFrames/FluxMP5Overlay.lua:376](../../UnitFrames/FluxMP5Overlay.lua#L376) | `RegisterEvent` | `"PLAYER_UNGHOST"` |
| [UnitFrames/FluxPowerCostOverlay.lua:893](../../UnitFrames/FluxPowerCostOverlay.lua#L893) | `RegisterUnitEvent` | `event, unit` |
| [UnitFrames/FluxPowerCostOverlay.lua:1057](../../UnitFrames/FluxPowerCostOverlay.lua#L1057) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxPowerCostOverlay.lua:1060](../../UnitFrames/FluxPowerCostOverlay.lua#L1060) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxSwingTimer.lua:1919](../../UnitFrames/FluxSwingTimer.lua#L1919) | `RegisterEvent` | `"COMBAT_LOG_EVENT_UNFILTERED"` |
| [UnitFrames/FluxSwingTimer.lua:2235](../../UnitFrames/FluxSwingTimer.lua#L2235) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxSwingTimer.lua:2236](../../UnitFrames/FluxSwingTimer.lua#L2236) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxSwingTimer.lua:2238](../../UnitFrames/FluxSwingTimer.lua#L2238) | `RegisterEvent` | `"PLAYER_ENTER_COMBAT"` |
| [UnitFrames/FluxSwingTimer.lua:2241](../../UnitFrames/FluxSwingTimer.lua#L2241) | `RegisterEvent` | `"PLAYER_LEAVE_COMBAT"` |
| [UnitFrames/FluxSwingTimer.lua:2243](../../UnitFrames/FluxSwingTimer.lua#L2243) | `RegisterEvent` | `"UNIT_INVENTORY_CHANGED"` |
| [UnitFrames/FluxSwingTimer.lua:2244](../../UnitFrames/FluxSwingTimer.lua#L2244) | `RegisterEvent` | `"GET_ITEM_INFO_RECEIVED"` |
| [UnitFrames/FluxSwingTimer.lua:2245](../../UnitFrames/FluxSwingTimer.lua#L2245) | `RegisterEvent` | `"START_AUTOREPEAT_SPELL"` |
| [UnitFrames/FluxSwingTimer.lua:2246](../../UnitFrames/FluxSwingTimer.lua#L2246) | `RegisterEvent` | `"STOP_AUTOREPEAT_SPELL"` |
| [UnitFrames/FluxSwingTimer.lua:2247](../../UnitFrames/FluxSwingTimer.lua#L2247) | `RegisterEvent` | `"UNIT_SPELLCAST_SUCCEEDED"` |
| [UnitFrames/FluxSwingTimer.lua:2248](../../UnitFrames/FluxSwingTimer.lua#L2248) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxSwingTimer.lua:2250](../../UnitFrames/FluxSwingTimer.lua#L2250) | `RegisterUnitEvent` | `"UNIT_ATTACK_SPEED", "player"` |
| [UnitFrames/FluxSwingTimer.lua:2253](../../UnitFrames/FluxSwingTimer.lua#L2253) | `RegisterUnitEvent` | `"UNIT_COMBAT", "target"` |
| [UnitFrames/FluxSwingTimer.lua:2257](../../UnitFrames/FluxSwingTimer.lua#L2257) | `RegisterEvent` | `"PLAYER_SWING"` |
| [UnitFrames/FluxSwingTimer.lua:2260](../../UnitFrames/FluxSwingTimer.lua#L2260) | `RegisterEvent` | `"PLAYER_SWING_RANGE_UPDATE"` |
| [UnitFrames/FluxSwingTimer.lua:2263](../../UnitFrames/FluxSwingTimer.lua#L2263) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxSwingTimer.lua:2266](../../UnitFrames/FluxSwingTimer.lua#L2266) | `RegisterEvent` | `"WEAPON_SLOT_CHANGED"` |
| [UnitFrames/FluxSwingTimer.lua:2269](../../UnitFrames/FluxSwingTimer.lua#L2269) | `RegisterEvent` | `"ADDON_LOADED"` |
| [UnitFrames/FluxSwingTimer.lua:2285](../../UnitFrames/FluxSwingTimer.lua#L2285) | `RegisterEvent` | `"ADDON_RESTRICTION_STATE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2306](../../UnitFrames/FluxUnitFrames_Auras.lua#L2306) | `RegisterUnitEvent` | `"UNIT_AURA", frame.unit` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2307](../../UnitFrames/FluxUnitFrames_Auras.lua#L2307) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2308](../../UnitFrames/FluxUnitFrames_Auras.lua#L2308) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2309](../../UnitFrames/FluxUnitFrames_Auras.lua#L2309) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2311](../../UnitFrames/FluxUnitFrames_Auras.lua#L2311) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2313](../../UnitFrames/FluxUnitFrames_Auras.lua#L2313) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2358](../../UnitFrames/FluxUnitFrames_Auras.lua#L2358) | `RegisterEvent` | `"PLAYER_LOGOUT"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2415](../../UnitFrames/FluxUnitFrames_Auras.lua#L2415) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2416](../../UnitFrames/FluxUnitFrames_Auras.lua#L2416) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2417](../../UnitFrames/FluxUnitFrames_Auras.lua#L2417) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2418](../../UnitFrames/FluxUnitFrames_Auras.lua#L2418) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_DebuffTint.lua:323](../../UnitFrames/FluxUnitFrames_DebuffTint.lua#L323) | `RegisterEvent` | `event` |
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
| [UnitFrames/FluxUnitFrames_Focus.lua:196](../../UnitFrames/FluxUnitFrames_Focus.lua#L196) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Focus.lua:197](../../UnitFrames/FluxUnitFrames_Focus.lua#L197) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:174](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L174) | `RegisterUnitEvent` | `"UNIT_CONNECTION", "focustarget"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:175](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L175) | `RegisterUnitEvent` | `"UNIT_FLAGS", "focustarget"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:176](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L176) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:177](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L177) | `RegisterEvent` | `"UNIT_TARGET"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:178](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L178) | `RegisterEvent` | `"UNIT_NAME_UPDATE"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:190](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L190) | `RegisterUnitEvent` | `"UNIT_HEALTH", "focustarget"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:191](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L191) | `RegisterUnitEvent` | `"UNIT_MAXHEALTH", "focustarget"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:223](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L223) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:224](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L224) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Party.lua:460](../../UnitFrames/FluxUnitFrames_Party.lua#L460) | `RegisterUnitEvent` | `event, unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:463](../../UnitFrames/FluxUnitFrames_Party.lua#L463) | `RegisterUnitEvent` | `"UNIT_TARGET", owner.unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:464](../../UnitFrames/FluxUnitFrames_Party.lua#L464) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Party.lua:548](../../UnitFrames/FluxUnitFrames_Party.lua#L548) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:549](../../UnitFrames/FluxUnitFrames_Party.lua#L549) | `RegisterUnitEvent` | `"UNIT_PORTRAIT_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:550](../../UnitFrames/FluxUnitFrames_Party.lua#L550) | `RegisterUnitEvent` | `"UNIT_MODEL_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:551](../../UnitFrames/FluxUnitFrames_Party.lua#L551) | `RegisterUnitEvent` | `"UNIT_CONNECTION", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:552](../../UnitFrames/FluxUnitFrames_Party.lua#L552) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_Party.lua:553](../../UnitFrames/FluxUnitFrames_Party.lua#L553) | `RegisterUnitEvent` | `"UNIT_FLAGS", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:554](../../UnitFrames/FluxUnitFrames_Party.lua#L554) | `RegisterUnitEvent` | `"PLAYER_FLAGS_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:555](../../UnitFrames/FluxUnitFrames_Party.lua#L555) | `RegisterUnitEvent` | `"UNIT_FACTION", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:556](../../UnitFrames/FluxUnitFrames_Party.lua#L556) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:557](../../UnitFrames/FluxUnitFrames_Party.lua#L557) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:558](../../UnitFrames/FluxUnitFrames_Party.lua#L558) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Party.lua:564](../../UnitFrames/FluxUnitFrames_Party.lua#L564) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [UnitFrames/FluxUnitFrames_Party.lua:578](../../UnitFrames/FluxUnitFrames_Party.lua#L578) | `RegisterEvent` | `"CVAR_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Party.lua:581](../../UnitFrames/FluxUnitFrames_Party.lua#L581) | `RegisterUnitEvent` | `"UNIT_AURA", unit` |
| [UnitFrames/FluxUnitFrames_Pet.lua:200](../../UnitFrames/FluxUnitFrames_Pet.lua#L200) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_Pet.lua:201](../../UnitFrames/FluxUnitFrames_Pet.lua#L201) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:610](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L610) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:611](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L611) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:612](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L612) | `RegisterUnitEvent` | `"UNIT_AURA", "pet"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:614](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L614) | `RegisterEvent` | `"UNIT_AURA"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:104](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L104) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:173](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L173) | `RegisterUnitEvent` | `"UNIT_HEALTH", "pettarget"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:174](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L174) | `RegisterUnitEvent` | `"UNIT_MAXHEALTH", "pettarget"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:177](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L177) | `RegisterUnitEvent` | `"UNIT_CONNECTION", "pettarget"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:178](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L178) | `RegisterUnitEvent` | `"UNIT_FLAGS", "pettarget"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:179](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L179) | `RegisterUnitEvent` | `"UNIT_FACTION", "pettarget"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:180](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L180) | `RegisterUnitEvent` | `"UNIT_TARGET", "pet"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:181](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L181) | `RegisterUnitEvent` | `"UNIT_PET", "player"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:182](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L182) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_PetTarget.lua:183](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L183) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1027](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1027) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1028](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1028) | `RegisterEvent` | `"BANKFRAME_OPENED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1029](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1029) | `RegisterEvent` | `"BANKFRAME_CLOSED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1182](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1182) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1183](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1183) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1184](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1184) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1185](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1185) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [UnitFrames/FluxUnitFrames_PlayerSpecClick.lua:1186](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1186) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:217](../../UnitFrames/FluxUnitFrames_Shared.lua#L217) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:218](../../UnitFrames/FluxUnitFrames_Shared.lua#L218) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:219](../../UnitFrames/FluxUnitFrames_Shared.lua#L219) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:1359](../../UnitFrames/FluxUnitFrames_Shared.lua#L1359) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:4821](../../UnitFrames/FluxUnitFrames_Shared.lua#L4821) | `RegisterUnitEvent` | `"UNIT_TARGET", "player"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:4823](../../UnitFrames/FluxUnitFrames_Shared.lua#L4823) | `RegisterEvent` | `"UNIT_TARGET"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:5596](../../UnitFrames/FluxUnitFrames_Shared.lua#L5596) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:5597](../../UnitFrames/FluxUnitFrames_Shared.lua#L5597) | `RegisterEvent` | `"PLAYER_FLAGS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:5632](../../UnitFrames/FluxUnitFrames_Shared.lua#L5632) | `RegisterEvent` | `"RAID_TARGET_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:6765](../../UnitFrames/FluxUnitFrames_Shared.lua#L6765) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8622](../../UnitFrames/FluxUnitFrames_Shared.lua#L8622) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9241](../../UnitFrames/FluxUnitFrames_Shared.lua#L9241) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9242](../../UnitFrames/FluxUnitFrames_Shared.lua#L9242) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9243](../../UnitFrames/FluxUnitFrames_Shared.lua#L9243) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9244](../../UnitFrames/FluxUnitFrames_Shared.lua#L9244) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9316](../../UnitFrames/FluxUnitFrames_Shared.lua#L9316) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9317](../../UnitFrames/FluxUnitFrames_Shared.lua#L9317) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9318](../../UnitFrames/FluxUnitFrames_Shared.lua#L9318) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9319](../../UnitFrames/FluxUnitFrames_Shared.lua#L9319) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9320](../../UnitFrames/FluxUnitFrames_Shared.lua#L9320) | `RegisterUnitEvent` | `"UNIT_HEALTH", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9321](../../UnitFrames/FluxUnitFrames_Shared.lua#L9321) | `RegisterUnitEvent` | `"UNIT_MAXHEALTH", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9322](../../UnitFrames/FluxUnitFrames_Shared.lua#L9322) | `RegisterUnitEvent` | `"UNIT_POWER_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9323](../../UnitFrames/FluxUnitFrames_Shared.lua#L9323) | `RegisterUnitEvent` | `"UNIT_MAXPOWER", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9324](../../UnitFrames/FluxUnitFrames_Shared.lua#L9324) | `RegisterUnitEvent` | `"UNIT_DISPLAYPOWER", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9332](../../UnitFrames/FluxUnitFrames_Shared.lua#L9332) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9333](../../UnitFrames/FluxUnitFrames_Shared.lua#L9333) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9337](../../UnitFrames/FluxUnitFrames_Shared.lua#L9337) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9339](../../UnitFrames/FluxUnitFrames_Shared.lua#L9339) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9340](../../UnitFrames/FluxUnitFrames_Shared.lua#L9340) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9341](../../UnitFrames/FluxUnitFrames_Shared.lua#L9341) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9342](../../UnitFrames/FluxUnitFrames_Shared.lua#L9342) | `RegisterEvent` | `"UNIT_THREAT_LIST_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9344](../../UnitFrames/FluxUnitFrames_Shared.lua#L9344) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9345](../../UnitFrames/FluxUnitFrames_Shared.lua#L9345) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9346](../../UnitFrames/FluxUnitFrames_Shared.lua#L9346) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9349](../../UnitFrames/FluxUnitFrames_Shared.lua#L9349) | `RegisterUnitEvent` | `"UNIT_TARGET", "target"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9354](../../UnitFrames/FluxUnitFrames_Shared.lua#L9354) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9355](../../UnitFrames/FluxUnitFrames_Shared.lua#L9355) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9360](../../UnitFrames/FluxUnitFrames_Shared.lua#L9360) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9362](../../UnitFrames/FluxUnitFrames_Shared.lua#L9362) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9364](../../UnitFrames/FluxUnitFrames_Shared.lua#L9364) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9365](../../UnitFrames/FluxUnitFrames_Shared.lua#L9365) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9366](../../UnitFrames/FluxUnitFrames_Shared.lua#L9366) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9367](../../UnitFrames/FluxUnitFrames_Shared.lua#L9367) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9368](../../UnitFrames/FluxUnitFrames_Shared.lua#L9368) | `RegisterEvent` | `"UNIT_THREAT_LIST_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9370](../../UnitFrames/FluxUnitFrames_Shared.lua#L9370) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9374](../../UnitFrames/FluxUnitFrames_Shared.lua#L9374) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9376](../../UnitFrames/FluxUnitFrames_Shared.lua#L9376) | `RegisterUnitEvent` | `"UNIT_TARGET", "focus"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9377](../../UnitFrames/FluxUnitFrames_Shared.lua#L9377) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9379](../../UnitFrames/FluxUnitFrames_Shared.lua#L9379) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9380](../../UnitFrames/FluxUnitFrames_Shared.lua#L9380) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9383](../../UnitFrames/FluxUnitFrames_Shared.lua#L9383) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9388](../../UnitFrames/FluxUnitFrames_Shared.lua#L9388) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", "player", "pet"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9392](../../UnitFrames/FluxUnitFrames_Shared.lua#L9392) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9393](../../UnitFrames/FluxUnitFrames_Shared.lua#L9393) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9394](../../UnitFrames/FluxUnitFrames_Shared.lua#L9394) | `RegisterEvent` | `"PLAYER_UPDATE_RESTING"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9395](../../UnitFrames/FluxUnitFrames_Shared.lua#L9395) | `RegisterEvent` | `"PLAYER_FLAGS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9399](../../UnitFrames/FluxUnitFrames_Shared.lua#L9399) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9400](../../UnitFrames/FluxUnitFrames_Shared.lua#L9400) | `RegisterEvent` | `"RAID_ROSTER_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9401](../../UnitFrames/FluxUnitFrames_Shared.lua#L9401) | `RegisterEvent` | `"PARTY_LEADER_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9405](../../UnitFrames/FluxUnitFrames_Shared.lua#L9405) | `RegisterEvent` | `"PARTY_LOOT_METHOD_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9409](../../UnitFrames/FluxUnitFrames_Shared.lua#L9409) | `RegisterUnitEvent` | `"UNIT_FACTION", frame.unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9410](../../UnitFrames/FluxUnitFrames_Shared.lua#L9410) | `RegisterUnitEvent` | `"PLAYER_FLAGS_CHANGED", frame.unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9414](../../UnitFrames/FluxUnitFrames_Shared.lua#L9414) | `RegisterEvent` | `"ZONE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9415](../../UnitFrames/FluxUnitFrames_Shared.lua#L9415) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9416](../../UnitFrames/FluxUnitFrames_Shared.lua#L9416) | `RegisterEvent` | `"ZONE_CHANGED_INDOORS"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9417](../../UnitFrames/FluxUnitFrames_Shared.lua#L9417) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9548](../../UnitFrames/FluxUnitFrames_Shared.lua#L9548) | `RegisterEvent` | `"CVAR_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Target.lua:19](../../UnitFrames/FluxUnitFrames_Target.lua#L19) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Target.lua:20](../../UnitFrames/FluxUnitFrames_Target.lua#L20) | `RegisterEvent` | `"UNIT_HEALTH"` |
| [UnitFrames/FluxUnitFrames_Target.lua:22](../../UnitFrames/FluxUnitFrames_Target.lua#L22) | `RegisterEvent` | `"UNIT_LEVEL"` |
| [UnitFrames/FluxUnitFrames_Target.lua:24](../../UnitFrames/FluxUnitFrames_Target.lua#L24) | `RegisterEvent` | `"UNIT_FACTION"` |
| [UnitFrames/FluxUnitFrames_Target.lua:26](../../UnitFrames/FluxUnitFrames_Target.lua#L26) | `RegisterEvent` | `"UNIT_CLASSIFICATION_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Target.lua:29](../../UnitFrames/FluxUnitFrames_Target.lua#L29) | `RegisterEvent` | `"PLAYER_FLAGS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Target.lua:31](../../UnitFrames/FluxUnitFrames_Target.lua#L31) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Target.lua:32](../../UnitFrames/FluxUnitFrames_Target.lua#L32) | `RegisterEvent` | `"RAID_TARGET_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Target.lua:34](../../UnitFrames/FluxUnitFrames_Target.lua#L34) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Target.lua:35](../../UnitFrames/FluxUnitFrames_Target.lua#L35) | `RegisterUnitEvent` | `"UNIT_AURA", unit` |
| [UnitFrames/FluxUnitFrames_Target.lua:36](../../UnitFrames/FluxUnitFrames_Target.lua#L36) | `RegisterUnitEvent` | `"UNIT_TARGET", unit` |
| [UnitFrames/FluxUnitFrames_Target.lua:39](../../UnitFrames/FluxUnitFrames_Target.lua#L39) | `RegisterUnitEvent` | `"UNIT_TARGETABLE_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Target.lua:67](../../UnitFrames/FluxUnitFrames_Target.lua#L67) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Target.lua:68](../../UnitFrames/FluxUnitFrames_Target.lua#L68) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Target.lua:312](../../UnitFrames/FluxUnitFrames_Target.lua#L312) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Target.lua:313](../../UnitFrames/FluxUnitFrames_Target.lua#L313) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Target.lua:314](../../UnitFrames/FluxUnitFrames_Target.lua#L314) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_TargetOfTarget.lua:128](../../UnitFrames/FluxUnitFrames_TargetOfTarget.lua#L128) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
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
| `_G.FluxRestockPanel_OnOptionsClosed` | [L324](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L324) |
| `SchedulePanelRebuild` | [L367](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L367) |
| `ConfirmResetTierReference` | [L968](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L968) |
| `ScheduleBagCellRefresh` | [L2384](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2384) |
| `_G.FluxRestockPanel_RequestRefresh` | [L2585](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2585) |
| `_G.FluxRestockPanel_OnSpellReagentCacheReady` | [L2593](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2593) |
| `_G.FluxRestockPanel_IsTabVisible` | [L2603](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2603) |
| `_G.FluxRestockPanel_IsActive` | [L2607](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2607) |
| `_G.FluxRestockPanel_RefreshMerchantAvailability` | [L2611](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2611) |
| `_G.FluxRestockPanel_RefreshJunkLists` | [L2620](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2620) |
| `_G.FluxRestockPanel_RefreshCellData` | [L2627](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2627) |

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
| `FluxOptions:OpenToDamageMeterTab` | [L1587](../../AddonOptions/FluxOptions.lua#L1587) |
| `FluxOptions:OpenBlizzardOptions` | [L1593](../../AddonOptions/FluxOptions.lua#L1593) |
| `ACR:NotifyChange` | [L1748](../../AddonOptions/FluxOptions.lua#L1748) |
| `FluxOptions.EnsureSavedConfiguration` | [L1824](../../AddonOptions/FluxOptions.lua#L1824) |

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
| `AB.GetBarGroup` | [L20](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L20) |

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

### AddonOptions/FluxOptionsCatalog.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `C.HelpText` | [L148](../../AddonOptions/FluxOptionsCatalog.lua#L148) |

### AddonOptions/FluxOptionsNavigation.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `N.Route` | [L6](../../AddonOptions/FluxOptionsNavigation.lua#L6) |
| `N.Generation` | [L43](../../AddonOptions/FluxOptionsNavigation.lua#L43) |
| `endifnottab.noticeandnottab.actionthenview.hidden` | [L79](../../AddonOptions/FluxOptionsNavigation.lua#L79) |
| `N.Resolve` | [L87](../../AddonOptions/FluxOptionsNavigation.lua#L87) |
| `viewendifentry.checkAvailabilitythengroup.hidden` | [L115](../../AddonOptions/FluxOptionsNavigation.lua#L115) |

### AddonOptions/FluxOptionsRaidFrame.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `ns.FluxOptionsBuildPartyRaidTab` | [L93](../../AddonOptions/FluxOptionsRaidFrame.lua#L93) |

### AddonOptions/FluxOptionsRender.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `endrow.Refresh` | [L547](../../AddonOptions/FluxOptionsRender.lua#L547) |
| `endrow.Refresh` | [L647](../../AddonOptions/FluxOptionsRender.lua#L647) |
| `more.Refresh` | [L729](../../AddonOptions/FluxOptionsRender.lua#L729) |
| `R.SourceHidden` | [L785](../../AddonOptions/FluxOptionsRender.lua#L785) |
| `R.ListSubpages` | [L789](../../AddonOptions/FluxOptionsRender.lua#L789) |
| `R.Search` | [L837](../../AddonOptions/FluxOptionsRender.lua#L837) |
| `R.Build` | [L871](../../AddonOptions/FluxOptionsRender.lua#L871) |
| `page:ContentWidth` | [L889](../../AddonOptions/FluxOptionsRender.lua#L889) |
| `page:Layout` | [L899](../../AddonOptions/FluxOptionsRender.lua#L899) |
| `page:Refresh` | [L1084](../../AddonOptions/FluxOptionsRender.lua#L1084) |
| `page:SetQuery` | [L1088](../../AddonOptions/FluxOptionsRender.lua#L1088) |
| `page:SetActive` | [L1093](../../AddonOptions/FluxOptionsRender.lua#L1093) |
| `page:Release` | [L1129](../../AddonOptions/FluxOptionsRender.lua#L1129) |

### AddonOptions/FluxOptionsSalvage.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `_G.FluxOptionsSalvageGroup` | [L82](../../AddonOptions/FluxOptionsSalvage.lua#L82) |

### AddonOptions/FluxOptionsShell.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `Shell:IsShown` | [L50](../../AddonOptions/FluxOptionsShell.lua#L50) |
| `Shell:SetStatus` | [L54](../../AddonOptions/FluxOptionsShell.lua#L54) |
| `Shell:ApplyFluxBorder` | [L60](../../AddonOptions/FluxOptionsShell.lua#L60) |
| `Shell:ApplyAccent` | [L65](../../AddonOptions/FluxOptionsShell.lua#L65) |
| `Shell:PaintSelection` | [L74](../../AddonOptions/FluxOptionsShell.lua#L74) |
| `Shell:PaintTabs` | [L86](../../AddonOptions/FluxOptionsShell.lua#L86) |
| `Shell:ContentWidth` | [L98](../../AddonOptions/FluxOptionsShell.lua#L98) |
| `Shell:ViewHeight` | [L105](../../AddonOptions/FluxOptionsShell.lua#L105) |
| `Shell:ReleaseCache` | [L112](../../AddonOptions/FluxOptionsShell.lua#L112) |
| `Shell:OnHidden` | [L143](../../AddonOptions/FluxOptionsShell.lua#L143) |
| `Shell:Hide` | [L153](../../AddonOptions/FluxOptionsShell.lua#L153) |
| `Shell:Remember` | [L160](../../AddonOptions/FluxOptionsShell.lua#L160) |
| `Shell:ResolveGroup` | [L168](../../AddonOptions/FluxOptionsShell.lua#L168) |
| `Shell:SubpagesFor` | [L186](../../AddonOptions/FluxOptionsShell.lua#L186) |
| `Shell:Query` | [L197](../../AddonOptions/FluxOptionsShell.lua#L197) |
| `Shell:PageMatches` | [L204](../../AddonOptions/FluxOptionsShell.lua#L204) |
| `Shell:ContentQuery` | [L239](../../AddonOptions/FluxOptionsShell.lua#L239) |
| `Shell:NavMatches` | [L256](../../AddonOptions/FluxOptionsShell.lua#L256) |
| `Shell:ToggleCategory` | [L275](../../AddonOptions/FluxOptionsShell.lua#L275) |
| `Shell:FilterSidebar` | [L281](../../AddonOptions/FluxOptionsShell.lua#L281) |
| `Shell:SearchChanged` | [L350](../../AddonOptions/FluxOptionsShell.lua#L350) |
| `Shell:LayoutTabs` | [L375](../../AddonOptions/FluxOptionsShell.lua#L375) |
| `Shell:ShowPage` | [L454](../../AddonOptions/FluxOptionsShell.lua#L454) |
| `page.onLayout` | [L560](../../AddonOptions/FluxOptionsShell.lua#L560) |
| `Shell:Select` | [L583](../../AddonOptions/FluxOptionsShell.lua#L583) |
| `Shell:RefreshOpenPageNow` | [L600](../../AddonOptions/FluxOptionsShell.lua#L600) |
| `Shell:RefreshOpenPage` | [L626](../../AddonOptions/FluxOptionsShell.lua#L626) |
| `Shell:Relayout` | [L642](../../AddonOptions/FluxOptionsShell.lua#L642) |
| `Shell:BuildSidebar` | [L656](../../AddonOptions/FluxOptionsShell.lua#L656) |
| `Shell:EnsureFrame` | [L901](../../AddonOptions/FluxOptionsShell.lua#L901) |
| `Shell:Show` | [L1191](../../AddonOptions/FluxOptionsShell.lua#L1191) |
| `Shell:Open` | [L1213](../../AddonOptions/FluxOptionsShell.lua#L1213) |

### AddonOptions/FluxOptionsSkin.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `Skin.IsForever` | [L7](../../AddonOptions/FluxOptionsSkin.lua#L7) |
| `Skin.CreateWindow` | [L38](../../AddonOptions/FluxOptionsSkin.lua#L38) |
| `Skin.CreateInset` | [L58](../../AddonOptions/FluxOptionsSkin.lua#L58) |
| `Skin.PaintTab` | [L62](../../AddonOptions/FluxOptionsSkin.lua#L62) |
| `Skin.CreateTab` | [L76](../../AddonOptions/FluxOptionsSkin.lua#L76) |
| `Skin.SetTabText` | [L84](../../AddonOptions/FluxOptionsSkin.lua#L84) |
| `Skin.SizeTab` | [L88](../../AddonOptions/FluxOptionsSkin.lua#L88) |
| `Skin.StyleHeader` | [L99](../../AddonOptions/FluxOptionsSkin.lua#L99) |
| `row.SetExpanded` | [L110](../../AddonOptions/FluxOptionsSkin.lua#L110) |
| `Skin.StyleScrollBar` | [L115](../../AddonOptions/FluxOptionsSkin.lua#L115) |
| `Skin.StyleCategory` | [L132](../../AddonOptions/FluxOptionsSkin.lua#L132) |
| `Skin.StyleSystemButton` | [L141](../../AddonOptions/FluxOptionsSkin.lua#L141) |
| `Skin.PaintNav` | [L146](../../AddonOptions/FluxOptionsSkin.lua#L146) |

### AddonOptions/FluxOptionsUnitFrames.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `ns.FluxOptionsThreatVisibilityOption` | [L170](../../AddonOptions/FluxOptionsUnitFrames.lua#L170) |
| `opt.set` | [L298](../../AddonOptions/FluxOptionsUnitFrames.lua#L298) |

### AddonOptions/FluxOptionsWidgets.lua

Owner: [26-options-map.md](../26-options-map.md).

| Declaration | Source |
|---|---|
| `W.Solid` | [L24](../../AddonOptions/FluxOptionsWidgets.lua#L24) |
| `W.Accent` | [L28](../../AddonOptions/FluxOptionsWidgets.lua#L28) |
| `W.OnAccent` | [L36](../../AddonOptions/FluxOptionsWidgets.lua#L36) |
| `W.ReleaseAccent` | [L42](../../AddonOptions/FluxOptionsWidgets.lua#L42) |
| `W.RefreshAccent` | [L46](../../AddonOptions/FluxOptionsWidgets.lua#L46) |
| `W.HasAtlas` | [L52](../../AddonOptions/FluxOptionsWidgets.lua#L52) |
| `W.ApplyBackdrop` | [L79](../../AddonOptions/FluxOptionsWidgets.lua#L79) |
| `W.HideTooltip` | [L93](../../AddonOptions/FluxOptionsWidgets.lua#L93) |
| `W.ShowTooltip` | [L99](../../AddonOptions/FluxOptionsWidgets.lua#L99) |
| `W.CreateRow` | [L121](../../AddonOptions/FluxOptionsWidgets.lua#L121) |
| `W.PaintStripe` | [L131](../../AddonOptions/FluxOptionsWidgets.lua#L131) |
| `W.CreateHeader` | [L142](../../AddonOptions/FluxOptionsWidgets.lua#L142) |
| `row.SetExpanded` | [L161](../../AddonOptions/FluxOptionsWidgets.lua#L161) |
| `textrow.SetLabel` | [L164](../../AddonOptions/FluxOptionsWidgets.lua#L164) |
| `W.CreateDescription` | [L172](../../AddonOptions/FluxOptionsWidgets.lua#L172) |
| `textrow.SetBody` | [L181](../../AddonOptions/FluxOptionsWidgets.lua#L181) |
| `endrow.LayoutHeight` | [L192](../../AddonOptions/FluxOptionsWidgets.lua#L192) |
| `W.CreateSectionCard` | [L205](../../AddonOptions/FluxOptionsWidgets.lua#L205) |
| `W.CreateEmpty` | [L213](../../AddonOptions/FluxOptionsWidgets.lua#L213) |
| `W.CreateToggle` | [L238](../../AddonOptions/FluxOptionsWidgets.lua#L238) |
| `row.SetLabel` | [L277](../../AddonOptions/FluxOptionsWidgets.lua#L277) |
| `endrow.SetDescription` | [L281](../../AddonOptions/FluxOptionsWidgets.lua#L281) |
| `endrow.SetValue` | [L284](../../AddonOptions/FluxOptionsWidgets.lua#L284) |
| `endrow.GetValue` | [L288](../../AddonOptions/FluxOptionsWidgets.lua#L288) |
| `returnvalueendrow.SetDisabled` | [L291](../../AddonOptions/FluxOptionsWidgets.lua#L291) |
| `endrow.SetOnChange` | [L296](../../AddonOptions/FluxOptionsWidgets.lua#L296) |
| `W.CloseDropdown` | [L324](../../AddonOptions/FluxOptionsWidgets.lua#L324) |
| `W.CreateDropdown` | [L353](../../AddonOptions/FluxOptionsWidgets.lua#L353) |
| `item.valueinfo.func` | [L491](../../AddonOptions/FluxOptionsWidgets.lua#L491) |
| `row.SetLabel` | [L509](../../AddonOptions/FluxOptionsWidgets.lua#L509) |
| `endrow.SetDescription` | [L513](../../AddonOptions/FluxOptionsWidgets.lua#L513) |
| `endrow.SetGetter` | [L516](../../AddonOptions/FluxOptionsWidgets.lua#L516) |
| `endrow.SetValue` | [L520](../../AddonOptions/FluxOptionsWidgets.lua#L520) |
| `endrow.SetDisabled` | [L524](../../AddonOptions/FluxOptionsWidgets.lua#L524) |
| `endrow.SetOnChange` | [L528](../../AddonOptions/FluxOptionsWidgets.lua#L528) |
| `W.CreateSlider` | [L552](../../AddonOptions/FluxOptionsWidgets.lua#L552) |
| `row.SetLabel` | [L633](../../AddonOptions/FluxOptionsWidgets.lua#L633) |
| `endrow.SetDescription` | [L637](../../AddonOptions/FluxOptionsWidgets.lua#L637) |
| `endrow.Configure` | [L640](../../AddonOptions/FluxOptionsWidgets.lua#L640) |
| `endrow.SetValue` | [L659](../../AddonOptions/FluxOptionsWidgets.lua#L659) |
| `endrow.SetDisabled` | [L668](../../AddonOptions/FluxOptionsWidgets.lua#L668) |
| `endrow.SetOnChange` | [L673](../../AddonOptions/FluxOptionsWidgets.lua#L673) |
| `fnendrow.SetOnCommit` | [L676](../../AddonOptions/FluxOptionsWidgets.lua#L676) |
| `W.CreateColor` | [L685](../../AddonOptions/FluxOptionsWidgets.lua#L685) |
| `hasAlphaandtrueorfalseColorPickerFrame.func` | [L756](../../AddonOptions/FluxOptionsWidgets.lua#L756) |
| `endColorPickerFrame.cancelFunc` | [L760](../../AddonOptions/FluxOptionsWidgets.lua#L760) |
| `row.SetLabel` | [L775](../../AddonOptions/FluxOptionsWidgets.lua#L775) |
| `endrow.SetDescription` | [L779](../../AddonOptions/FluxOptionsWidgets.lua#L779) |
| `endrow.SetHasAlpha` | [L782](../../AddonOptions/FluxOptionsWidgets.lua#L782) |
| `vandtrueorfalseendrow.SetValue` | [L785](../../AddonOptions/FluxOptionsWidgets.lua#L785) |
| `endrow.SetDisabled` | [L792](../../AddonOptions/FluxOptionsWidgets.lua#L792) |
| `endrow.SetOnChange` | [L797](../../AddonOptions/FluxOptionsWidgets.lua#L797) |
| `W.CreateButton` | [L804](../../AddonOptions/FluxOptionsWidgets.lua#L804) |
| `row.SetLabel` | [L851](../../AddonOptions/FluxOptionsWidgets.lua#L851) |
| `endrow.SetButtonText` | [L855](../../AddonOptions/FluxOptionsWidgets.lua#L855) |
| `endrow.SetDescription` | [L859](../../AddonOptions/FluxOptionsWidgets.lua#L859) |
| `endrow.SetDisabled` | [L862](../../AddonOptions/FluxOptionsWidgets.lua#L862) |
| `endrow.SetOnClick` | [L867](../../AddonOptions/FluxOptionsWidgets.lua#L867) |
| `W.CreateInput` | [L873](../../AddonOptions/FluxOptionsWidgets.lua#L873) |
| `row.SetLabel` | [L913](../../AddonOptions/FluxOptionsWidgets.lua#L913) |
| `endrow.SetDescription` | [L917](../../AddonOptions/FluxOptionsWidgets.lua#L917) |
| `endrow.SetValue` | [L920](../../AddonOptions/FluxOptionsWidgets.lua#L920) |
| `endrow.SetDisabled` | [L923](../../AddonOptions/FluxOptionsWidgets.lua#L923) |
| `endrow.SetOnCommit` | [L929](../../AddonOptions/FluxOptionsWidgets.lua#L929) |
| `W.CreateMoreButton` | [L935](../../AddonOptions/FluxOptionsWidgets.lua#L935) |
| `endrow.SetOpen` | [L945](../../AddonOptions/FluxOptionsWidgets.lua#L945) |
| `row.SetOnClick` | [L955](../../AddonOptions/FluxOptionsWidgets.lua#L955) |
| `W.CreateScroll` | [L963](../../AddonOptions/FluxOptionsWidgets.lua#L963) |
| `api:SetContentHeight` | [L1017](../../AddonOptions/FluxOptionsWidgets.lua#L1017) |
| `api:GetContentWidth` | [L1029](../../AddonOptions/FluxOptionsWidgets.lua#L1029) |
| `api:GetViewHeight` | [L1036](../../AddonOptions/FluxOptionsWidgets.lua#L1036) |
| `api:ResetScroll` | [L1039](../../AddonOptions/FluxOptionsWidgets.lua#L1039) |

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
| `Compat.FinalizeBankRestock` | [L224](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L224) |
| `Compat.InitBankRestock` | [L230](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L230) |

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
| `Compat.TrackBaganatorView` | [L43](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L43) |
| `Compat.ForEachVisibleBaganatorView` | [L66](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L66) |
| `Compat.ResolveBaganatorItemButtonSlot` | [L95](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L95) |
| `Compat.ForEachRegisteredBaganatorItemButton` | [L142](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L142) |
| `Compat.ForEachBaganatorItemButton` | [L167](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L167) |
| `Compat.ForEachVisibleItemButton` | [L257](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L257) |
| `Compat.InitBaganatorViewTracking` | [L284](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L284) |

### BaganatorCompat/FluxBaganator_Junk.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.RequestBaganatorRefresh` | [L25](../../BaganatorCompat/FluxBaganator_Junk.lua#L25) |
| `Compat.ConfigureBaganatorJunkDetector` | [L65](../../BaganatorCompat/FluxBaganator_Junk.lua#L65) |
| `Compat.InitJunk` | [L96](../../BaganatorCompat/FluxBaganator_Junk.lua#L96) |

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
| `BadgeHost.PrepareSecureAuraForSlot` | [L654](../../Bars/BadgeHost.lua#L654) |
| `BadgeHost.SetSlotBadges` | [L837](../../Bars/BadgeHost.lua#L837) |
| `BadgeHost.ApplyMap` | [L856](../../Bars/BadgeHost.lua#L856) |
| `BadgeHost.ClearSlot` | [L870](../../Bars/BadgeHost.lua#L870) |
| `BadgeHost.GetSlotBadges` | [L874](../../Bars/BadgeHost.lua#L874) |
| `BadgeHost.HasAny` | [L878](../../Bars/BadgeHost.lua#L878) |
| `BadgeHost.EachIndexedBody` | [L882](../../Bars/BadgeHost.lua#L882) |
| `BadgeHost.NotifyDisplay` | [L903](../../Bars/BadgeHost.lua#L903) |
| `BadgeHost.RefreshFormVisibility` | [L946](../../Bars/BadgeHost.lua#L946) |
| `BadgeHost.OnIdentityChange` | [L1002](../../Bars/BadgeHost.lua#L1002) |
| `BadgeHost.SyncShownFaces` | [L1035](../../Bars/BadgeHost.lua#L1035) |
| `BadgeHost.RefreshOccupancyVisibility` | [L1063](../../Bars/BadgeHost.lua#L1063) |
| `BadgeHost.NotifyModifierPaging` | [L1080](../../Bars/BadgeHost.lua#L1080) |
| `BadgeHost.RefreshDisplays` | [L1152](../../Bars/BadgeHost.lua#L1152) |
| `BadgeHost.RefreshMouseoverDisplays` | [L1166](../../Bars/BadgeHost.lua#L1166) |
| `BadgeHost.GetVisibleBadgesForButton` | [L1195](../../Bars/BadgeHost.lua#L1195) |
| `BadgeHost.RefreshLayout` | [L1247](../../Bars/BadgeHost.lua#L1247) |
| `BadgeHost.FlushCombatQueue` | [L1272](../../Bars/BadgeHost.lua#L1272) |

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
| `Effects.GlowDiagnostics` | [L17](../../Bars/Effects.lua#L17) |
| `Effects.SetGlow` | [L257](../../Bars/Effects.lua#L257) |
| `Effects.InvalidateSecureAuraCandidates` | [L374](../../Bars/Effects.lua#L374) |
| `Effects.SyncColumn` | [L430](../../Bars/Effects.lua#L430) |
| `Effects.Refresh` | [L627](../../Bars/Effects.lua#L627) |
| `Effects.RefreshAll` | [L647](../../Bars/Effects.lua#L647) |
| `Effects.Start` | [L654](../../Bars/Effects.lua#L654) |

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
| `Hosts.ForSlot` | [L161](../../Bars/Hosts.lua#L161) |
| `Hosts.UpdateTooltip` | [L458](../../Bars/Hosts.lua#L458) |
| `Hosts.RefreshHoverTooltip` | [L498](../../Bars/Hosts.lua#L498) |
| `Hosts.CreateSurface` | [L509](../../Bars/Hosts.lua#L509) |
| `Hosts.Skin` | [L827](../../Bars/Hosts.lua#L827) |
| `Hosts.FinishSurface` | [L837](../../Bars/Hosts.lua#L837) |
| `Hosts.Build` | [L874](../../Bars/Hosts.lua#L874) |
| `Hosts.ApplyChrome` | [L931](../../Bars/Hosts.lua#L931) |
| `Hosts.InvalidateKeys` | [L937](../../Bars/Hosts.lua#L937) |
| `Hosts.RefreshKeys` | [L943](../../Bars/Hosts.lua#L943) |
| `Hosts.PrepareClicks` | [L949](../../Bars/Hosts.lua#L949) |

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
| `Paint.UpdateCooldown` | [L1179](../../Bars/Paint.lua#L1179) |
| `Paint.UpdateUsable` | [L1250](../../Bars/Paint.lua#L1250) |
| `Paint.NotePlayerCast` | [L1373](../../Bars/Paint.lua#L1373) |
| `Paint.NeedsRange` | [L1426](../../Bars/Paint.lua#L1426) |
| `Paint.UpdateRange` | [L1495](../../Bars/Paint.lua#L1495) |
| `Paint.ApplySlotRange` | [L1516](../../Bars/Paint.lua#L1516) |
| `Paint.SweepLitChecked` | [L1646](../../Bars/Paint.lua#L1646) |
| `Paint.ArmCheckedPoll` | [L1670](../../Bars/Paint.lua#L1670) |
| `Paint.UpdateFlash` | [L1686](../../Bars/Paint.lua#L1686) |
| `Paint.UpdateChecked` | [L1712](../../Bars/Paint.lua#L1712) |
| `Paint.UpdateEquipped` | [L1789](../../Bars/Paint.lua#L1789) |
| `Paint.AbbreviateKey` | [L1900](../../Bars/Paint.lua#L1900) |
| `Paint.UpdateHotkey` | [L1914](../../Bars/Paint.lua#L1914) |
| `Paint.UpdateAssistedCombat` | [L2039](../../Bars/Paint.lua#L2039) |
| `rot.OnUpdate` | [L2072](../../Bars/Paint.lua#L2072) |
| `Paint.UpdateAssistedHighlight` | [L2147](../../Bars/Paint.lua#L2147) |
| `Paint.PaintAssistedHighlights` | [L2228](../../Bars/Paint.lua#L2228) |
| `Paint.PaintAssistedHosts` | [L2240](../../Bars/Paint.lua#L2240) |
| `Paint.UpdateDisplay` | [L2262](../../Bars/Paint.lua#L2262) |
| `Paint.UpdateAll` | [L2279](../../Bars/Paint.lua#L2279) |
| `Paint.HostIsLive` | [L2289](../../Bars/Paint.lua#L2289) |
| `Paint.MarkDirty` | [L2305](../../Bars/Paint.lua#L2305) |
| `Paint.Dirty` | [L2313](../../Bars/Paint.lua#L2313) |
| `Paint.EachDirty` | [L2318](../../Bars/Paint.lua#L2318) |
| `Paint.Flush` | [L2327](../../Bars/Paint.lua#L2327) |
| `Paint.ClearCache` | [L2512](../../Bars/Paint.lua#L2512) |

### Bars/Pet/Init.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Pet.GetFrame` | [L55](../../Bars/Pet/Init.lua#L55) |
| `Pet.GetButton` | [L59](../../Bars/Pet/Init.lua#L59) |
| `Pet.GetAllButtons` | [L63](../../Bars/Pet/Init.lua#L63) |
| `Pet.ForAll` | [L67](../../Bars/Pet/Init.lua#L67) |
| `Pet.UpdatePosition` | [L118](../../Bars/Pet/Init.lua#L118) |
| `Pet.SetBindingModeFrameOverride` | [L167](../../Bars/Pet/Init.lua#L167) |
| `Pet.FlushBindingModePending` | [L191](../../Bars/Pet/Init.lua#L191) |
| `Pet.ApplyVisibility` | [L200](../../Bars/Pet/Init.lua#L200) |
| `f.GetFrame` | [L214](../../Bars/Pet/Init.lua#L214) |
| `endf.GetButton` | [L217](../../Bars/Pet/Init.lua#L217) |
| `endf.GetAllButtons` | [L220](../../Bars/Pet/Init.lua#L220) |
| `endf.ForAll` | [L223](../../Bars/Pet/Init.lua#L223) |
| `endf.UpdatePosition` | [L226](../../Bars/Pet/Init.lua#L226) |
| `endf.SetupKeybindings` | [L229](../../Bars/Pet/Init.lua#L229) |
| `endendf.SetBindingModeFrameOverride` | [L234](../../Bars/Pet/Init.lua#L234) |
| `Pet.Start` | [L284](../../Bars/Pet/Init.lua#L284) |

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
| `ProgramFace.BodyForSlot` | [L111](../../Bars/ProgramFace.lua#L111) |
| `ProgramFace.NoteFace` | [L149](../../Bars/ProgramFace.lua#L149) |
| `ProgramFace.ClassifyBody` | [L238](../../Bars/ProgramFace.lua#L238) |
| `ProgramFace.InvalidateIndex` | [L353](../../Bars/ProgramFace.lua#L353) |
| `ProgramFace.RebuildIndex` | [L363](../../Bars/ProgramFace.lua#L363) |
| `ProgramFace.Needs` | [L481](../../Bars/ProgramFace.lua#L481) |
| `ProgramFace.KindWanted` | [L514](../../Bars/ProgramFace.lua#L514) |
| `ProgramFace.ProbeFlags` | [L518](../../Bars/ProgramFace.lua#L518) |
| `ProgramFace.EachExtraMatching` | [L531](../../Bars/ProgramFace.lua#L531) |
| `ProgramFace.TranslateAll` | [L590](../../Bars/ProgramFace.lua#L590) |
| `ProgramFace.EachBody` | [L609](../../Bars/ProgramFace.lua#L609) |
| `ProgramFace.RequestTarget` | [L850](../../Bars/ProgramFace.lua#L850) |
| `ProgramFace.NoteMouseoverEvent` | [L869](../../Bars/ProgramFace.lua#L869) |
| `ProgramFace.ArmMouseoverPoll` | [L903](../../Bars/ProgramFace.lua#L903) |
| `ProgramFace.WakeMouseoverPoll` | [L955](../../Bars/ProgramFace.lua#L955) |
| `ProgramFace.SetMouseoverPollInterval` | [L968](../../Bars/ProgramFace.lua#L968) |
| `ProgramFace.SetMinFlushInterval` | [L981](../../Bars/ProgramFace.lua#L981) |
| `ProgramFace.FlushPending` | [L995](../../Bars/ProgramFace.lua#L995) |
| `ProgramFace.Request` | [L1054](../../Bars/ProgramFace.lua#L1054) |
| `ProgramFace.RequestConditionalRefresh` | [L1085](../../Bars/ProgramFace.lua#L1085) |
| `ProgramFace.HasAny` | [L1089](../../Bars/ProgramFace.lua#L1089) |
| `ProgramFace.SyncHost` | [L1106](../../Bars/ProgramFace.lua#L1106) |
| `ProgramFace.TranslateHost` | [L1170](../../Bars/ProgramFace.lua#L1170) |
| `ProgramFace.ShownForSlot` | [L1210](../../Bars/ProgramFace.lua#L1210) |
| `ProgramFace.Shown` | [L1234](../../Bars/ProgramFace.lua#L1234) |
| `ProgramFace.RequestHoverPeek` | [L1387](../../Bars/ProgramFace.lua#L1387) |
| `ProgramFace.OnContext` | [L1462](../../Bars/ProgramFace.lua#L1462) |
| `ProgramFace.ContextOwnsDisplay` | [L1554](../../Bars/ProgramFace.lua#L1554) |
| `ProgramFace.Start` | [L1559](../../Bars/ProgramFace.lua#L1559) |

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
| `SlotHost.GetAllBarSlots` | [L264](../../Bars/SlotProgram.lua#L264) |
| `SlotProgram.Apply` | [L353](../../Bars/SlotProgram.lua#L353) |
| `SlotProgram.ApplyMap` | [L392](../../Bars/SlotProgram.lua#L392) |
| `SlotProgram.Get` | [L421](../../Bars/SlotProgram.lua#L421) |
| `SlotProgram.GetIdle` | [L425](../../Bars/SlotProgram.lua#L425) |
| `SlotProgram.GetMode` | [L433](../../Bars/SlotProgram.lua#L433) |
| `SlotProgram.GetAll` | [L437](../../Bars/SlotProgram.lua#L437) |
| `SlotProgram.ClickButtonName` | [L441](../../Bars/SlotProgram.lua#L441) |
| `SlotProgram.ClickButton` | [L452](../../Bars/SlotProgram.lua#L452) |
| `SlotProgram.HasAny` | [L459](../../Bars/SlotProgram.lua#L459) |
| `SlotProgram.SetHover` | [L463](../../Bars/SlotProgram.lua#L463) |
| `SlotProgram.ApplyHoverMap` | [L475](../../Bars/SlotProgram.lua#L475) |
| `SlotProgram.GetHover` | [L513](../../Bars/SlotProgram.lua#L513) |
| `SlotProgram.GetAllHover` | [L517](../../Bars/SlotProgram.lua#L517) |
| `SlotProgram.HasHover` | [L521](../../Bars/SlotProgram.lua#L521) |
| `SlotProgram.RefreshDisplays` | [L548](../../Bars/SlotProgram.lua#L548) |
| `SlotProgram.ApplyStripDisplayOverrides` | [L585](../../Bars/SlotProgram.lua#L585) |
| `SlotProgram.ReassertAll` | [L605](../../Bars/SlotProgram.lua#L605) |
| `SlotProgram.FlushCombatQueue` | [L624](../../Bars/SlotProgram.lua#L624) |

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
| `Stance.EnsureAuraCountdown` | [L981](../../Bars/Stance/Extras.lua#L981) |
| `Stance.SyncAuraCountdown` | [L1095](../../Bars/Stance/Extras.lua#L1095) |
| `Stance.CustomTrackSpell` | [L1275](../../Bars/Stance/Extras.lua#L1275) |
| `Stance.IsTrackedCustomSpell` | [L1309](../../Bars/Stance/Extras.lua#L1309) |
| `Stance.NoteCustomCast` | [L1414](../../Bars/Stance/Extras.lua#L1414) |
| `Stance.CustomAuraPollSignature` | [L1441](../../Bars/Stance/Extras.lua#L1441) |
| `Stance.ApplyExtraActiveVisual` | [L1467](../../Bars/Stance/Extras.lua#L1467) |
| `Stance.GetAvailableSpells` | [L1734](../../Bars/Stance/Extras.lua#L1734) |
| `Stance.ShouldShowExtra` | [L1847](../../Bars/Stance/Extras.lua#L1847) |
| `Stance.ShouldShowCustom` | [L1880](../../Bars/Stance/Extras.lua#L1880) |

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
| `Stance.Anchor` | [L133](../../Bars/Stance/Layout.lua#L133) |
| `Stance.ApplyLayout` | [L214](../../Bars/Stance/Layout.lua#L214) |
| `Stance.RequestLayout` | [L408](../../Bars/Stance/Layout.lua#L408) |
| `Stance.RequestSizeOnly` | [L433](../../Bars/Stance/Layout.lua#L433) |
| `Stance.RequestFormsVisual` | [L437](../../Bars/Stance/Layout.lua#L437) |
| `Stance.RequestExtrasVisual` | [L457](../../Bars/Stance/Layout.lua#L457) |
| `Stance.RequestDiscover` | [L477](../../Bars/Stance/Layout.lua#L477) |

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
| `State.GetSecondarySlot` | [L78](../../Bars/State.lua#L78) |
| `State.GetTertiarySlot` | [L82](../../Bars/State.lua#L82) |
| `State.GetMainSlot` | [L86](../../Bars/State.lua#L86) |
| `State.ResolveSlot` | [L90](../../Bars/State.lua#L90) |
| `State.GetCurrentPage` | [L113](../../Bars/State.lua#L113) |
| `State.GetMinirowPosition` | [L133](../../Bars/State.lua#L133) |
| `State.BuildNativeDriver` | [L203](../../Bars/State.lua#L203) |
| `State.Attach` | [L664](../../Bars/State.lua#L664) |
| `State.HeaderFor` | [L702](../../Bars/State.lua#L702) |
| `State.Create` | [L805](../../Bars/State.lua#L805) |
| `State.RegisterDrivers` | [L834](../../Bars/State.lua#L834) |
| `State.CurrentSwap` | [L979](../../Bars/State.lua#L979) |
| `State.IndexLiveSlots` | [L993](../../Bars/State.lua#L993) |
| `State.ApplySlotsInsecure` | [L1039](../../Bars/State.lua#L1039) |
| `State.OnModFallback` | [L1084](../../Bars/State.lua#L1084) |
| `State.ForceApply` | [L1092](../../Bars/State.lua#L1092) |
| `State.GetClassStances` | [L1129](../../Bars/State.lua#L1129) |

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
| `FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield` | [L125](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L125) |
| `FluxBattlefieldMapPinRouter:IsHBDAvailable` | [L144](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L144) |
| `FluxBattlefieldMapPinRouter:IsHBDWorldProvider` | [L148](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L148) |
| `FluxBattlefieldMapPinRouter:GetRouteLabel` | [L167](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L167) |
| `canvaspool.createFunc` | [L232](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L232) |
| `frame.OnAcquiredframe.OnAcquired` | [L247](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L247) |
| `endendendreturnframeendpool.resetFunc` | [L258](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L258) |
| `canvaspool.createFunc` | [L326](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L326) |
| `route.battlefieldProvider.RefreshAllDataroute.battlefieldProvider.RefreshAllData` | [L575](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L575) |
| `endendworldProvider.HandlePin` | [L584](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L584) |
| `endworldProvider.RefreshAllData` | [L587](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L587) |
| `FluxBattlefieldMapPinRouter:RefreshAllThirdPartyPins` | [L707](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L707) |
| `FluxBattlefieldMapPinRouter:RequestRefresh` | [L738](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L738) |
| `FluxBattlefieldMapPinRouter:ScheduleKickstart` | [L750](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L750) |
| `FluxBattlefieldMapPinRouter:Install` | [L774](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L774) |
| `FluxBattlefieldMapPinRouter:Uninstall` | [L805](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L805) |

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
| `provider:ShouldShowQuest` | [L257](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L257) |
| `provider:RefreshAllData` | [L506](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L506) |
| `provider:OnHighlightedQuestPOIChange` | [L530](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L530) |
| `provider:OnCanvasSizeChanged` | [L538](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L538) |
| `pin:OnCanvasSizeChanged` | [L653](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L653) |
| `pin:OnMapChanged` | [L656](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L656) |
| `pin:Refresh` | [L659](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L659) |
| `provider:RefreshAllData` | [L781](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L781) |
| `provider:PingPin` | [L793](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L793) |
| `provider:GetPinTemplateFromTask` | [L809](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L809) |
| `FluxBattlefieldMapProviders:Attach` | [L1118](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L1118) |
| `FluxBattlefieldMapProviders:Detach` | [L1143](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L1143) |
| `FluxBattlefieldMapProviders:IsAttached` | [L1166](../../Battlezonemap/FluxBattlefieldMapProviders.lua#L1166) |

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
| `FluxBlizzardMeter:IsSupportedClient` | [L215](../../Battlezonemap/FluxBlizzardMeter.lua#L215) |
| `FluxBlizzardMeter:IsAvailable` | [L222](../../Battlezonemap/FluxBlizzardMeter.lua#L222) |
| `FluxBlizzardMeter:EnsureEnabled` | [L246](../../Battlezonemap/FluxBlizzardMeter.lua#L246) |
| `FluxBlizzardMeter:IsContentAvailable` | [L253](../../Battlezonemap/FluxBlizzardMeter.lua#L253) |
| `FluxBlizzardMeter:IsEmbedded` | [L263](../../Battlezonemap/FluxBlizzardMeter.lua#L263) |
| `FluxBlizzardMeter:ResetAllSessionsIfOutOfCombat` | [L271](../../Battlezonemap/FluxBlizzardMeter.lua#L271) |
| `FluxBlizzardMeter:OpenNativeMenu` | [L692](../../Battlezonemap/FluxBlizzardMeter.lua#L692) |
| `FluxBlizzardMeter:GetNativeTypeChoices` | [L807](../../Battlezonemap/FluxBlizzardMeter.lua#L807) |
| `FluxBlizzardMeter:SelectNativeType` | [L827](../../Battlezonemap/FluxBlizzardMeter.lua#L827) |
| `FluxBlizzardMeter:ApplyRequestedTypes` | [L859](../../Battlezonemap/FluxBlizzardMeter.lua#L859) |
| `FluxBlizzardMeter:QueueUserLayoutApply` | [L879](../../Battlezonemap/FluxBlizzardMeter.lua#L879) |
| `FluxBlizzardMeter:ApplyCurrentSegments` | [L885](../../Battlezonemap/FluxBlizzardMeter.lua#L885) |
| `FluxBlizzardMeter:Embed` | [L1274](../../Battlezonemap/FluxBlizzardMeter.lua#L1274) |
| `FluxBlizzardMeter:SyncGeometryFromLayout` | [L1373](../../Battlezonemap/FluxBlizzardMeter.lua#L1373) |
| `FluxBlizzardMeter:RefreshEmbeddedLayout` | [L1396](../../Battlezonemap/FluxBlizzardMeter.lua#L1396) |
| `FluxBlizzardMeter:GetLayoutStatus` | [L1407](../../Battlezonemap/FluxBlizzardMeter.lua#L1407) |
| `FluxBlizzardMeter:GetCallBoundaryStatus` | [L1439](../../Battlezonemap/FluxBlizzardMeter.lua#L1439) |
| `FluxBlizzardMeter:TestCurrentSelection` | [L1487](../../Battlezonemap/FluxBlizzardMeter.lua#L1487) |
| `FluxBlizzardMeter:GetCurrentSelectionTestStatus` | [L1491](../../Battlezonemap/FluxBlizzardMeter.lua#L1491) |
| `FluxBlizzardMeter:Hide` | [L1501](../../Battlezonemap/FluxBlizzardMeter.lua#L1501) |
| `FluxBlizzardMeter:Show` | [L1531](../../Battlezonemap/FluxBlizzardMeter.lua#L1531) |
| `FluxBlizzardMeter:Cleanup` | [L1563](../../Battlezonemap/FluxBlizzardMeter.lua#L1563) |

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
| `FluxDetails:Embed` | [L1425](../../Battlezonemap/FluxDetails.lua#L1425) |
| `FluxDetails:CopyLayoutPreset` | [L1593](../../Battlezonemap/FluxDetails.lua#L1593) |
| `FluxDetails:Hide` | [L1615](../../Battlezonemap/FluxDetails.lua#L1615) |
| `FluxDetails:IsEmbedded` | [L1648](../../Battlezonemap/FluxDetails.lua#L1648) |
| `FluxDetails:ApplyPostLoginState` | [L1655](../../Battlezonemap/FluxDetails.lua#L1655) |
| `FluxDetails:RefreshEmbeddedLayout` | [L1684](../../Battlezonemap/FluxDetails.lua#L1684) |
| `FluxDetails:SyncGeometryFromLayout` | [L1704](../../Battlezonemap/FluxDetails.lua#L1704) |
| `FluxDetails:StabilizeAfterLayoutChange` | [L1737](../../Battlezonemap/FluxDetails.lua#L1737) |
| `FluxDetails:ResetAllDataIfOutOfCombat` | [L1752](../../Battlezonemap/FluxDetails.lua#L1752) |

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
| `FluxMeterLayout.IsDetailsAddonLoaded` | [L157](../../Battlezonemap/FluxMeterLayout.lua#L157) |
| `FluxMeterLayout.HasBlizzardDamageMeterClient` | [L170](../../Battlezonemap/FluxMeterLayout.lua#L170) |
| `FluxMeterLayout.GetMeterBackend` | [L185](../../Battlezonemap/FluxMeterLayout.lua#L185) |
| `FluxMeterLayout.IsBlizzardBackend` | [L195](../../Battlezonemap/FluxMeterLayout.lua#L195) |
| `FluxMeterLayout.IsDetailsBackend` | [L199](../../Battlezonemap/FluxMeterLayout.lua#L199) |
| `FluxMeterLayout.HasMeterBackend` | [L203](../../Battlezonemap/FluxMeterLayout.lua#L203) |
| `FluxMeterLayout.HasStandaloneThreat` | [L208](../../Battlezonemap/FluxMeterLayout.lua#L208) |
| `FluxMeterLayout.IsThreatSlot` | [L212](../../Battlezonemap/FluxMeterLayout.lua#L212) |
| `FluxMeterLayout.GetMaxPanes` | [L216](../../Battlezonemap/FluxMeterLayout.lua#L216) |
| `FluxMeterLayout.GetBuiltinLabels` | [L368](../../Battlezonemap/FluxMeterLayout.lua#L368) |
| `FluxMeterLayout.NormalizeSlot` | [L736](../../Battlezonemap/FluxMeterLayout.lua#L736) |
| `FluxMeterLayout.NormalizeColFracs` | [L740](../../Battlezonemap/FluxMeterLayout.lua#L740) |
| `FluxMeterLayout.CopyLayout` | [L744](../../Battlezonemap/FluxMeterLayout.lua#L744) |
| `FluxMeterLayout.GetWorkingLayout` | [L748](../../Battlezonemap/FluxMeterLayout.lua#L748) |
| `FluxMeterLayout.GetActiveLayoutId` | [L754](../../Battlezonemap/FluxMeterLayout.lua#L754) |
| `FluxMeterLayout.GetUserLayouts` | [L759](../../Battlezonemap/FluxMeterLayout.lua#L759) |
| `FluxMeterLayout.GetBuiltinCount` | [L764](../../Battlezonemap/FluxMeterLayout.lua#L764) |
| `FluxMeterLayout.ApplyBuiltin` | [L771](../../Battlezonemap/FluxMeterLayout.lua#L771) |
| `FluxMeterLayout.LoadUser` | [L781](../../Battlezonemap/FluxMeterLayout.lua#L781) |
| `FluxMeterLayout.SaveWorkingAsNew` | [L793](../../Battlezonemap/FluxMeterLayout.lua#L793) |
| `FluxMeterLayout.SaveWorkingOverActive` | [L804](../../Battlezonemap/FluxMeterLayout.lua#L804) |
| `FluxMeterLayout.RenameActive` | [L822](../../Battlezonemap/FluxMeterLayout.lua#L822) |
| `FluxMeterLayout.DeleteActive` | [L837](../../Battlezonemap/FluxMeterLayout.lua#L837) |
| `FluxMeterLayout.SetTopColCount` | [L864](../../Battlezonemap/FluxMeterLayout.lua#L864) |
| `FluxMeterLayout.SetBottomColCount` | [L886](../../Battlezonemap/FluxMeterLayout.lua#L886) |
| `FluxMeterLayout.CanSetTopColCount` | [L913](../../Battlezonemap/FluxMeterLayout.lua#L913) |
| `FluxMeterLayout.CanSetBottomColCount` | [L922](../../Battlezonemap/FluxMeterLayout.lua#L922) |
| `FluxMeterLayout.SetSlot` | [L931](../../Battlezonemap/FluxMeterLayout.lua#L931) |
| `FluxMeterLayout.SetTopRowFrac` | [L958](../../Battlezonemap/FluxMeterLayout.lua#L958) |
| `FluxMeterLayout.SetColFracs` | [L963](../../Battlezonemap/FluxMeterLayout.lua#L963) |
| `FluxMeterLayout.SlotIcon` | [L996](../../Battlezonemap/FluxMeterLayout.lua#L996) |
| `FluxMeterLayout.BuildCatalog` | [L1105](../../Battlezonemap/FluxMeterLayout.lua#L1105) |
| `FluxMeterLayout.SlotShortLabel` | [L1220](../../Battlezonemap/FluxMeterLayout.lua#L1220) |
| `FluxMeterLayout.SlotColor` | [L1233](../../Battlezonemap/FluxMeterLayout.lua#L1233) |
| `FluxMeterLayout.CancelPendingWork` | [L1304](../../Battlezonemap/FluxMeterLayout.lua#L1304) |
| `FluxMeterLayout.ReembedQuiet` | [L1334](../../Battlezonemap/FluxMeterLayout.lua#L1334) |
| `FluxMeterLayout.ScheduleReembed` | [L1338](../../Battlezonemap/FluxMeterLayout.lua#L1338) |
| `FluxMeterLayout.OnNativeMeterTypeChanged` | [L1344](../../Battlezonemap/FluxMeterLayout.lua#L1344) |
| `FluxMeterLayout.OpenNativeMenu` | [L1362](../../Battlezonemap/FluxMeterLayout.lua#L1362) |
| `FluxMeterLayout.SelectNativeType` | [L1374](../../Battlezonemap/FluxMeterLayout.lua#L1374) |
| `FluxMeterLayout.CommitUserLayout` | [L1388](../../Battlezonemap/FluxMeterLayout.lua#L1388) |
| `FluxMeterLayout.GetPickerGroups` | [L1404](../../Battlezonemap/FluxMeterLayout.lua#L1404) |
| `FluxMeterLayout.IsEditorOpen` | [L1448](../../Battlezonemap/FluxMeterLayout.lua#L1448) |
| `FluxMeterLayout.CloseEditor` | [L1452](../../Battlezonemap/FluxMeterLayout.lua#L1452) |
| `b:SetActive` | [L1791](../../Battlezonemap/FluxMeterLayout.lua#L1791) |
| `f:RefreshPicker` | [L2068](../../Battlezonemap/FluxMeterLayout.lua#L2068) |
| `f:RebuildLibList` | [L2170](../../Battlezonemap/FluxMeterLayout.lua#L2170) |
| `f:RefreshCanvas` | [L2253](../../Battlezonemap/FluxMeterLayout.lua#L2253) |
| `f:Refresh` | [L2360](../../Battlezonemap/FluxMeterLayout.lua#L2360) |
| `FluxMeterLayout.DetachFromHost` | [L2450](../../Battlezonemap/FluxMeterLayout.lua#L2450) |
| `FluxMeterLayout.AttachToHost` | [L2462](../../Battlezonemap/FluxMeterLayout.lua#L2462) |
| `FluxMeterLayout.FitEditorToHost` | [L2515](../../Battlezonemap/FluxMeterLayout.lua#L2515) |
| `FluxMeterLayout.AttachToAceWidget` | [L2545](../../Battlezonemap/FluxMeterLayout.lua#L2545) |
| `FluxMeterLayout.DetachFromAceWidget` | [L2568](../../Battlezonemap/FluxMeterLayout.lua#L2568) |
| `FluxMeterLayout.IsEmbeddedInOptions` | [L2575](../../Battlezonemap/FluxMeterLayout.lua#L2575) |
| `FluxMeterLayout.OpenEditor` | [L2579](../../Battlezonemap/FluxMeterLayout.lua#L2579) |
| `FluxMeterLayout.Init` | [L2605](../../Battlezonemap/FluxMeterLayout.lua#L2605) |

### Battlezonemap/FluxMeterSkin.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `Skin:StyleFont` | [L98](../../Battlezonemap/FluxMeterSkin.lua#L98) |
| `Skin:StyleTitleFont` | [L108](../../Battlezonemap/FluxMeterSkin.lua#L108) |
| `Skin:StyleRowBackground` | [L112](../../Battlezonemap/FluxMeterSkin.lua#L112) |
| `Skin:ApplyToEntry` | [L123](../../Battlezonemap/FluxMeterSkin.lua#L123) |
| `ifnotstate.repairHeaderControlsthenstate.repairHeaderControls` | [L446](../../Battlezonemap/FluxMeterSkin.lua#L446) |
| `Skin:RefreshHeaderControls` | [L508](../../Battlezonemap/FluxMeterSkin.lua#L508) |
| `Skin:SyncNativeTimer` | [L727](../../Battlezonemap/FluxMeterSkin.lua#L727) |
| `Skin:SetOwnedTimerText` | [L764](../../Battlezonemap/FluxMeterSkin.lua#L764) |
| `Skin:ApplyToWindow` | [L806](../../Battlezonemap/FluxMeterSkin.lua#L806) |
| `Skin:ApplyToOwnedPane` | [L830](../../Battlezonemap/FluxMeterSkin.lua#L830) |
| `Skin:RefreshTheme` | [L891](../../Battlezonemap/FluxMeterSkin.lua#L891) |
| `Skin:ReleaseWindow` | [L896](../../Battlezonemap/FluxMeterSkin.lua#L896) |
| `Skin:ReleaseAllNative` | [L924](../../Battlezonemap/FluxMeterSkin.lua#L924) |

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
| `Threat:TargetChanged` | [L806](../../Battlezonemap/FluxThreat.lua#L806) |
| `Threat:Start` | [L813](../../Battlezonemap/FluxThreat.lua#L813) |
| `Threat:Stop` | [L819](../../Battlezonemap/FluxThreat.lua#L819) |
| `Threat:Cancel` | [L823](../../Battlezonemap/FluxThreat.lua#L823) |
| `Threat:OnThreatListOrRosterEvent` | [L831](../../Battlezonemap/FluxThreat.lua#L831) |
| `Threat:SyncThreatPollingScript` | [L897](../../Battlezonemap/FluxThreat.lua#L897) |
| `Threat:SetCombatListEvents` | [L904](../../Battlezonemap/FluxThreat.lua#L904) |
| `Threat:OnEvent` | [L920](../../Battlezonemap/FluxThreat.lua#L920) |

### Battlezonemap/FluxThreatMeter.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `Meter:IsAvailable` | [L50](../../Battlezonemap/FluxThreatMeter.lua#L50) |
| `Meter:RefreshLayout` | [L371](../../Battlezonemap/FluxThreatMeter.lua#L371) |
| `Meter:Embed` | [L384](../../Battlezonemap/FluxThreatMeter.lua#L384) |
| `Meter:GetFrame` | [L396](../../Battlezonemap/FluxThreatMeter.lua#L396) |
| `Meter:Show` | [L398](../../Battlezonemap/FluxThreatMeter.lua#L398) |
| `Meter:Hide` | [L406](../../Battlezonemap/FluxThreatMeter.lua#L406) |
| `Meter:Cleanup` | [L411](../../Battlezonemap/FluxThreatMeter.lua#L411) |

### Battlezonemap/FluxWindowFrame.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `FluxWindowFrame:ApplyBottomLiftFromStatusBar` | [L224](../../Battlezonemap/FluxWindowFrame.lua#L224) |
| `FluxWindowFrame:GetFrame` | [L235](../../Battlezonemap/FluxWindowFrame.lua#L235) |
| `FluxWindowFrame:Show` | [L283](../../Battlezonemap/FluxWindowFrame.lua#L283) |
| `FluxWindowFrame:Hide` | [L297](../../Battlezonemap/FluxWindowFrame.lua#L297) |
| `FluxWindowFrame:Toggle` | [L311](../../Battlezonemap/FluxWindowFrame.lua#L311) |
| `FluxWindowFrame:SetSize` | [L322](../../Battlezonemap/FluxWindowFrame.lua#L322) |
| `FluxWindowFrame:SetOffset` | [L341](../../Battlezonemap/FluxWindowFrame.lua#L341) |
| `FluxWindowFrame:GetContentFrame` | [L354](../../Battlezonemap/FluxWindowFrame.lua#L354) |
| `FluxWindowFrame:SetBorderColor` | [L364](../../Battlezonemap/FluxWindowFrame.lua#L364) |
| `FluxWindowFrame:SetBackdropColor` | [L375](../../Battlezonemap/FluxWindowFrame.lua#L375) |
| `FluxWindowFrame:SetClassColor` | [L384](../../Battlezonemap/FluxWindowFrame.lua#L384) |
| `FluxWindowFrame:ShowMeterLayoutMenu` | [L397](../../Battlezonemap/FluxWindowFrame.lua#L397) |
| `FluxWindowFrame:IsMeterEditMode` | [L401](../../Battlezonemap/FluxWindowFrame.lua#L401) |
| `FluxWindowFrame:ExitMeterEditMode` | [L405](../../Battlezonemap/FluxWindowFrame.lua#L405) |
| `FluxWindowFrame:ReembedMeterQuiet` | [L411](../../Battlezonemap/FluxWindowFrame.lua#L411) |
| `FluxWindowFrame:AddTab` | [L686](../../Battlezonemap/FluxWindowFrame.lua#L686) |
| `FluxWindowFrame:SwitchToTab` | [L847](../../Battlezonemap/FluxWindowFrame.lua#L847) |
| `FluxWindowFrame:RemoveTab` | [L901](../../Battlezonemap/FluxWindowFrame.lua#L901) |
| `FluxWindowFrame:GetTabContent` | [L935](../../Battlezonemap/FluxWindowFrame.lua#L935) |
| `FluxWindowFrame:GetActiveTab` | [L940](../../Battlezonemap/FluxWindowFrame.lua#L940) |
| `FluxWindowFrame:GetManagedTabNames` | [L1011](../../Battlezonemap/FluxWindowFrame.lua#L1011) |
| `FluxWindowFrame:GetTabOrder` | [L1015](../../Battlezonemap/FluxWindowFrame.lua#L1015) |
| `FluxWindowFrame:IsTabEnabled` | [L1020](../../Battlezonemap/FluxWindowFrame.lua#L1020) |
| `FluxWindowFrame:GetFirstEnabledTab` | [L1029](../../Battlezonemap/FluxWindowFrame.lua#L1029) |
| `FluxWindowFrame:CountEnabledTabs` | [L1043](../../Battlezonemap/FluxWindowFrame.lua#L1043) |
| `FluxWindowFrame:RepositionTabs` | [L1054](../../Battlezonemap/FluxWindowFrame.lua#L1054) |
| `FluxWindowFrame:ApplyTabConfig` | [L1116](../../Battlezonemap/FluxWindowFrame.lua#L1116) |
| `FluxWindowFrame:ReleaseMinimapEmbedIfMapDisabled` | [L1123](../../Battlezonemap/FluxWindowFrame.lua#L1123) |
| `FluxWindowFrame:SetTabEnabled` | [L1143](../../Battlezonemap/FluxWindowFrame.lua#L1143) |
| `FluxWindowFrame:MoveTabInOrder` | [L1167](../../Battlezonemap/FluxWindowFrame.lua#L1167) |
| `FluxWindowFrame:SetTabOrder` | [L1194](../../Battlezonemap/FluxWindowFrame.lua#L1194) |
| `FluxWindowFrame:ResetTabConfigDefaults` | [L1224](../../Battlezonemap/FluxWindowFrame.lua#L1224) |
| `FluxWindowFrame:GetMeterLayoutConfig` | [L1235](../../Battlezonemap/FluxWindowFrame.lua#L1235) |
| `FluxWindowFrame:GetMeterPresetIndex` | [L1254](../../Battlezonemap/FluxWindowFrame.lua#L1254) |
| `FluxWindowFrame:SetMeterPresetIndex` | [L1260](../../Battlezonemap/FluxWindowFrame.lua#L1260) |
| `FluxWindowFrame_RefreshTabAccent` | [L1775](../../Battlezonemap/FluxWindowFrame.lua#L1775) |

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
| `FluxBinding.BindingHasLivePlace` | [L309](../../Binding/Core/Apply.lua#L309) |
| `FluxBinding.IsBindingRespecRelevant` | [L383](../../Binding/Core/Apply.lua#L383) |
| `FluxBinding.PrunePristineBindings` | [L390](../../Binding/Core/Apply.lua#L390) |
| `_G.FluxActionBarPeekSlotOccupancyChanged` | [L1069](../../Binding/Core/Apply.lua#L1069) |
| `_G.FluxActionBarPeekSlotOccupancyPrevious` | [L1089](../../Binding/Core/Apply.lua#L1089) |
| `_G.FluxActionBarConsumeOccupancyDirty` | [L1097](../../Binding/Core/Apply.lua#L1097) |
| `_G.FluxActionBarConsumeAllOccupancyDirty` | [L1106](../../Binding/Core/Apply.lua#L1106) |
| `_G.FluxActionBarSeedSlotOccupancyCache` | [L1114](../../Binding/Core/Apply.lua#L1114) |
| `_G.FluxActionBarPeekSlotOccupancy_ClearCache` | [L1125](../../Binding/Core/Apply.lua#L1125) |
| `FluxBinding.HasActiveWork` | [L2491](../../Binding/Core/Apply.lua#L2491) |
| `FluxBinding.GetActiveWorkInfo` | [L2504](../../Binding/Core/Apply.lua#L2504) |
| `FluxBinding.RequestApplyAll` | [L2522](../../Binding/Core/Apply.lua#L2522) |
| `FluxBinding.NotifyOccupancyChanged` | [L2543](../../Binding/Core/Apply.lua#L2543) |
| `FluxBinding.NotifyBarSlotChanged` | [L2592](../../Binding/Core/Apply.lua#L2592) |
| `FluxBinding.NotifyBarSlotsChanged` | [L2601](../../Binding/Core/Apply.lua#L2601) |
| `FluxBinding.NotifyBindingChanged` | [L2615](../../Binding/Core/Apply.lua#L2615) |
| `FluxBinding.NotifyBindingsAvailabilityChanged` | [L2632](../../Binding/Core/Apply.lua#L2632) |
| `FluxBinding.NormalizeChord` | [L2640](../../Binding/Core/Apply.lua#L2640) |
| `FluxBinding.FindColumnForChord` | [L2644](../../Binding/Core/Apply.lua#L2644) |
| `FluxBinding.RegisterApplied` | [L2648](../../Binding/Core/Apply.lua#L2648) |
| `FluxBinding.GetLastApplyStats` | [L2652](../../Binding/Core/Apply.lua#L2652) |
| `FluxBinding.CanUseMultiCastExtras` | [L2659](../../Binding/Core/Apply.lua#L2659) |
| `FluxBinding.GetPeersForChord` | [L2805](../../Binding/Core/Apply.lua#L2805) |
| `FluxBinding.GetEditorOverlap` | [L2855](../../Binding/Core/Apply.lua#L2855) |
| `FluxBinding.GetPreviewForBinding` | [L2926](../../Binding/Core/Apply.lua#L2926) |
| `FluxBinding.Debug` | [L3037](../../Binding/Core/Apply.lua#L3037) |

### Binding/Core/BindingTooltip.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `BT.AppendForButton` | [L385](../../Binding/Core/BindingTooltip.lua#L385) |
| `BT.OnLabTooltip` | [L676](../../Binding/Core/BindingTooltip.lua#L676) |
| `BT.InstallHooks` | [L708](../../Binding/Core/BindingTooltip.lua#L708) |

### Binding/Core/ChordMap.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `ChordMap.Parse` | [L40](../../Binding/Core/ChordMap.lua#L40) |
| `ChordMap.Normalize` | [L61](../../Binding/Core/ChordMap.lua#L61) |
| `ChordMap.IsMouseChord` | [L72](../../Binding/Core/ChordMap.lua#L72) |
| `ChordMap.Invalidate` | [L104](../../Binding/Core/ChordMap.lua#L104) |
| `ChordMap.FindColumnForChord` | [L108](../../Binding/Core/ChordMap.lua#L108) |
| `ChordMap.Route` | [L123](../../Binding/Core/ChordMap.lua#L123) |
| `ChordMap.SlotsForChord` | [L186](../../Binding/Core/ChordMap.lua#L186) |

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
| `Factory.IsFactoryMouseover` | [L711](../../Binding/Core/MacroFactory.lua#L711) |
| `Factory.IdleMacroText` | [L733](../../Binding/Core/MacroFactory.lua#L733) |
| `Factory.HasPeerOverlay` | [L794](../../Binding/Core/MacroFactory.lua#L794) |
| `Factory.NeedsHiddenClick` | [L810](../../Binding/Core/MacroFactory.lua#L810) |
| `Factory.StripOverlayMode` | [L854](../../Binding/Core/MacroFactory.lua#L854) |
| `Factory.BuildForward` | [L1067](../../Binding/Core/MacroFactory.lua#L1067) |
| `Factory.BuildHover` | [L1161](../../Binding/Core/MacroFactory.lua#L1161) |
| `Factory.BuildStaticBadge` | [L1178](../../Binding/Core/MacroFactory.lua#L1178) |
| `Factory.BuildReverse` | [L1226](../../Binding/Core/MacroFactory.lua#L1226) |

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
| `PushPress.SetIconColor` | [L208](../../Binding/Core/PushPress.lua#L208) |
| `PushPress.ReleaseIfUp` | [L429](../../Binding/Core/PushPress.lua#L429) |
| `PushPress.ClearAll` | [L431](../../Binding/Core/PushPress.lua#L431) |
| `PushPress.HookButton` | [L528](../../Binding/Core/PushPress.lua#L528) |
| `PushPress.EnsureBarButtonPushHooks` | [L588](../../Binding/Core/PushPress.lua#L588) |
| `PushPress.HookKeyer` | [L601](../../Binding/Core/PushPress.lua#L601) |
| `PushPress.WakeUfHoverFromUnitFrame` | [L784](../../Binding/Core/PushPress.lua#L784) |
| `PushPress.ParkUfHoverFromUnitFrame` | [L790](../../Binding/Core/PushPress.lua#L790) |
| `PushPress.WipeUfHover` | [L797](../../Binding/Core/PushPress.lua#L797) |
| `PushPress.RegisterUfHover` | [L803](../../Binding/Core/PushPress.lua#L803) |
| `PushPress.BindButton` | [L839](../../Binding/Core/PushPress.lua#L839) |
| `PushPress.OnApplyComplete` | [L858](../../Binding/Core/PushPress.lua#L858) |

### Binding/Core/SecurePool.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `Pool.Acquire` | [L41](../../Binding/Core/SecurePool.lua#L41) |
| `Pool.ArmMacroDelegate` | [L86](../../Binding/Core/SecurePool.lua#L86) |
| `Pool.Retire` | [L122](../../Binding/Core/SecurePool.lua#L122) |
| `Pool.GetStats` | [L130](../../Binding/Core/SecurePool.lua#L130) |

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
| `FluxMouseoverKeybind:HasHoverRoutingActive` | [L1848](../../Binding/Input/FluxMouseoverKeybind.lua#L1848) |
| `FluxMouseoverKeybind:IsHovercastPeekMouseContext` | [L1852](../../Binding/Input/FluxMouseoverKeybind.lua#L1852) |
| `FluxMouseoverKeybind:RegisterFrame` | [L1866](../../Binding/Input/FluxMouseoverKeybind.lua#L1866) |
| `FluxMouseoverKeybind:UnregisterBlizzardCompactRaidFrames` | [L1872](../../Binding/Input/FluxMouseoverKeybind.lua#L1872) |
| `FluxMouseoverKeybind:RefreshKeybinds` | [L1904](../../Binding/Input/FluxMouseoverKeybind.lua#L1904) |
| `FluxMouseoverKeybind:ReapplyAllRegisteredFrames` | [L1911](../../Binding/Input/FluxMouseoverKeybind.lua#L1911) |
| `FluxMouseoverKeybind:SetUfHoverRouting` | [L1920](../../Binding/Input/FluxMouseoverKeybind.lua#L1920) |
| `FluxMouseoverKeybind:SetSpellHoverKeys` | [L1949](../../Binding/Input/FluxMouseoverKeybind.lua#L1949) |
| `FluxMouseoverKeybind:FlushPendingHoverRouting` | [L1983](../../Binding/Input/FluxMouseoverKeybind.lua#L1983) |
| `FluxMouseoverKeybind:HasPendingHoverRouting` | [L1998](../../Binding/Input/FluxMouseoverKeybind.lua#L1998) |
| `FluxMouseoverKeybind:DebugRouting` | [L2002](../../Binding/Input/FluxMouseoverKeybind.lua#L2002) |
| `end_G.FluxMouseoverKeybind_DebugRouting` | [L2041](../../Binding/Input/FluxMouseoverKeybind.lua#L2041) |
| `FluxMouseoverKeybind_G.FluxRaidRegisterAllMouseoverKeybindFrames` | [L2048](../../Binding/Input/FluxMouseoverKeybind.lua#L2048) |
| `headerClique.UpdateRegisteredClicks` | [L2079](../../Binding/Input/FluxMouseoverKeybind.lua#L2079) |

### Binding/Respec.lua

Owner: [13-binding-system.md](../13-binding-system.md).

| Declaration | Source |
|---|---|
| `_G.FluxSpellBindings_CaptureDocSnapshot` | [L186](../../Binding/Respec.lua#L186) |
| `_G.FluxSpellBindings_CancelPendingApply` | [L369](../../Binding/Respec.lua#L369) |
| `_G.FluxSpellBindings_EmptySnapshot` | [L376](../../Binding/Respec.lua#L376) |
| `_G.FluxSpellBindings_CaptureSnapshot` | [L389](../../Binding/Respec.lua#L389) |
| `_G.FluxSpellBindings_MatchesSnapshot` | [L396](../../Binding/Respec.lua#L396) |
| `_G.FluxSpellBindings_IsLegacySnapshot` | [L408](../../Binding/Respec.lua#L408) |
| `_G.FluxSpellBindings_IsV3Snapshot` | [L416](../../Binding/Respec.lua#L416) |
| `_G.FluxSpellBindings_CountBoundSpells` | [L423](../../Binding/Respec.lua#L423) |
| `_G.FluxSpellBindings_CountKeyedBindings` | [L435](../../Binding/Respec.lua#L435) |
| `_G.FluxSpellBindings_CountCustomizedBindings` | [L449](../../Binding/Respec.lua#L449) |
| `_G.FluxSpellBindings_ApplySnapshot` | [L464](../../Binding/Respec.lua#L464) |

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
| `Blizz.SetMouseSuppressed` | [L187](../../Blizzard/Hide.lua#L187) |
| `Blizz.Hide` | [L248](../../Blizzard/Hide.lua#L248) |
| `Blizz.Unhide` | [L281](../../Blizzard/Hide.lua#L281) |
| `Blizz.IsHidden` | [L290](../../Blizzard/Hide.lua#L290) |

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
| `_G.FluxCSC_GetPlayerGearScore` | [L245](../../CharacterInfo/GearScore.lua#L245) |
| `_G.FluxCSC_GetGearScoreQualityRGB` | [L254](../../CharacterInfo/GearScore.lua#L254) |

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
| `module.InstallQuality` | [L159](../../CharacterInfo/PaperDollQuality.lua#L159) |

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
| `Action.GetCharges` | [L122](../../Core/API/Action.lua#L122) |
| `Action.GetCount` | [L129](../../Core/API/Action.lua#L129) |
| `Action.GetCooldown` | [L136](../../Core/API/Action.lua#L136) |
| `Action.GetChargeDuration` | [L143](../../Core/API/Action.lua#L143) |
| `Action.GetInfo` | [L150](../../Core/API/Action.lua#L150) |
| `Action.OccupancyKey` | [L159](../../Core/API/Action.lua#L159) |
| `Action.GetText` | [L168](../../Core/API/Action.lua#L168) |
| `Action.HasAction` | [L175](../../Core/API/Action.lua#L175) |
| `Action.IsAttack` | [L189](../../Core/API/Action.lua#L189) |
| `Action.IsAutoRepeat` | [L193](../../Core/API/Action.lua#L193) |
| `Action.IsCurrent` | [L197](../../Core/API/Action.lua#L197) |
| `Action.IsAssistedCombat` | [L201](../../Core/API/Action.lua#L201) |
| `Action.GetAssistedNextSpell` | [L213](../../Core/API/Action.lua#L213) |
| `Action.IsAssistedHighlightActive` | [L236](../../Core/API/Action.lua#L236) |
| `Action.GetAssistedHighlightSpell` | [L253](../../Core/API/Action.lua#L253) |
| `Action.SpellForAssistedHighlight` | [L276](../../Core/API/Action.lua#L276) |
| `Action.GetDisplayCount` | [L309](../../Core/API/Action.lua#L309) |
| `Action.GetCooldownDuration` | [L319](../../Core/API/Action.lua#L319) |
| `Action.EnableRangeCheck` | [L326](../../Core/API/Action.lua#L326) |
| `Action.LeaveBlizzardCollector` | [L351](../../Core/API/Action.lua#L351) |
| `Action.WithRegistrationSuppressed` | [L357](../../Core/API/Action.lua#L357) |
| `Action.NilFromCollector` | [L364](../../Core/API/Action.lua#L364) |
| `Action.SweepFluxFromCollectors` | [L412](../../Core/API/Action.lua#L412) |
| `Action.DetachFromCollectors` | [L434](../../Core/API/Action.lua#L434) |

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
| `Item.IsUsable` | [L87](../../Core/API/Item.lua#L87) |
| `Item.IsEquipped` | [L131](../../Core/API/Item.lua#L131) |
| `Item.UsesConsumableCharges` | [L167](../../Core/API/Item.lua#L167) |
| `Item.IsConsumable` | [L198](../../Core/API/Item.lua#L198) |
| `Item.IsCurrent` | [L237](../../Core/API/Item.lua#L237) |
| `Item.CanCheckRange` | [L260](../../Core/API/Item.lua#L260) |
| `Item.IsInRange` | [L272](../../Core/API/Item.lua#L272) |
| `Item.GetSpell` | [L308](../../Core/API/Item.lua#L308) |
| `Item.GetQuality` | [L340](../../Core/API/Item.lua#L340) |
| `Item.DoesExist` | [L348](../../Core/API/Item.lua#L348) |
| `Item.GetCooldown` | [L359](../../Core/API/Item.lua#L359) |

### Core/API/Name.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `PlayerName.GetSurnameSeparator` | [L50](../../Core/API/Name.lua#L50) |
| `PlayerName.UsesRegionalUniqueNames` | [L59](../../Core/API/Name.lua#L59) |
| `PlayerName.GetUnitNameParts` | [L77](../../Core/API/Name.lua#L77) |
| `PlayerName.GetFirstName` | [L101](../../Core/API/Name.lua#L101) |
| `PlayerName.GetFullName` | [L116](../../Core/API/Name.lua#L116) |
| `PlayerName.ShouldDisplaySurname` | [L143](../../Core/API/Name.lua#L143) |
| `PlayerName.SetDisplaySurname` | [L169](../../Core/API/Name.lua#L169) |
| `PlayerName.GetDisplayName` | [L184](../../Core/API/Name.lua#L184) |
| `PlayerName.GetRealmDisplay` | [L208](../../Core/API/Name.lua#L208) |
| `PlayerName.GetRealmToken` | [L224](../../Core/API/Name.lua#L224) |
| `PlayerName.IsCharacterIdentityReady` | [L242](../../Core/API/Name.lua#L242) |
| `PlayerName.GetCharKey` | [L254](../../Core/API/Name.lua#L254) |
| `PlayerName.SplitCharKey` | [L289](../../Core/API/Name.lua#L289) |
| `PlayerName.NamesEqual` | [L304](../../Core/API/Name.lua#L304) |
| `PlayerName.IsUnitPlayer` | [L339](../../Core/API/Name.lua#L339) |
| `PlayerName.MigrateKeyedTable` | [L353](../../Core/API/Name.lua#L353) |
| `PlayerName.GetLegacyCharKeys` | [L392](../../Core/API/Name.lua#L392) |
| `PlayerName.MigrateCurrentCharacterKeys` | [L448](../../Core/API/Name.lua#L448) |
| `PlayerName.MigrateCurrentCharacterAccountData` | [L462](../../Core/API/Name.lua#L462) |

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
| `Secrets.KeepLastNumber` | [L142](../../Core/API/Secrets.lua#L142) |
| `Secrets.CoerceNumberLoose` | [L167](../../Core/API/Secrets.lua#L167) |
| `Secrets.SafeCompare` | [L215](../../Core/API/Secrets.lua#L215) |
| `Secrets.SafeEqualForCache` | [L229](../../Core/API/Secrets.lua#L229) |
| `Secrets.SafeGUIDsEqual` | [L238](../../Core/API/Secrets.lua#L238) |
| `Secrets.SafeGUIDChangedForRefresh` | [L248](../../Core/API/Secrets.lua#L248) |
| `Secrets.AccessibleGUIDForUnit` | [L256](../../Core/API/Secrets.lua#L256) |
| `Secrets.SafeBooleanTest` | [L278](../../Core/API/Secrets.lua#L278) |
| `Secrets.NormalizeTriBool` | [L299](../../Core/API/Secrets.lua#L299) |
| `Secrets.SafeCountKey` | [L340](../../Core/API/Secrets.lua#L340) |
| `Secrets.SafeLooksEmpty` | [L367](../../Core/API/Secrets.lua#L367) |
| `Secrets.AuraUpdateInfoIsNoop` | [L397](../../Core/API/Secrets.lua#L397) |
| `Secrets.AuraUpdateInfoHasSecrets` | [L428](../../Core/API/Secrets.lua#L428) |

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
| `Spell.GetCooldownDuration` | [L271](../../Core/API/Spell.lua#L271) |
| `Spell.GetCount` | [L282](../../Core/API/Spell.lua#L282) |
| `Spell.GetCharges` | [L316](../../Core/API/Spell.lua#L316) |
| `Spell.GetChargeDuration` | [L357](../../Core/API/Spell.lua#L357) |
| `Spell.GetDisplayCount` | [L371](../../Core/API/Spell.lua#L371) |
| `Spell.IsUsable` | [L421](../../Core/API/Spell.lua#L421) |
| `Spell.IsInRange` | [L482](../../Core/API/Spell.lua#L482) |
| `Spell.GetBaseSpell` | [L517](../../Core/API/Spell.lua#L517) |
| `Spell.GetOverrideSpell` | [L527](../../Core/API/Spell.lua#L527) |
| `Spell.IdsMatch` | [L547](../../Core/API/Spell.lua#L547) |
| `Spell.ClearLiveFaceCache` | [L574](../../Core/API/Spell.lua#L574) |
| `Spell.GetLiveFace` | [L731](../../Core/API/Spell.lua#L731) |
| `Spell.IsCurrent` | [L825](../../Core/API/Spell.lua#L825) |
| `Spell.IsAutoRepeat` | [L832](../../Core/API/Spell.lua#L832) |
| `Spell.IsIdCast` | [L839](../../Core/API/Spell.lua#L839) |
| `Spell.FormatCastAttribute` | [L844](../../Core/API/Spell.lua#L844) |
| `Spell.BuildCastAttribute` | [L858](../../Core/API/Spell.lua#L858) |
| `Spell.GetFlyoutInfo` | [L923](../../Core/API/Spell.lua#L923) |
| `Spell.GetFlyoutSlotInfo` | [L941](../../Core/API/Spell.lua#L941) |
| `Spell.FlyoutSlotCastID` | [L966](../../Core/API/Spell.lua#L966) |
| `Spell.FlyoutHasSpell` | [L971](../../Core/API/Spell.lua#L971) |
| `Spell.FindFlyoutSlotCastID` | [L1002](../../Core/API/Spell.lua#L1002) |
| `Spell.ClearCache` | [L1058](../../Core/API/Spell.lua#L1058) |

### Core/API/Threat.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Threat.GetVisibilityMode` | [L36](../../Core/API/Threat.lua#L36) |
| `Threat.IsVisibilityAllowed` | [L45](../../Core/API/Threat.lua#L45) |
| `Threat.SetVisibilityMode` | [L53](../../Core/API/Threat.lua#L53) |
| `Threat.HasLeadSituation` | [L134](../../Core/API/Threat.lua#L134) |
| `Threat.HasPercentageOfLead` | [L138](../../Core/API/Threat.lua#L138) |
| `Threat.ShouldDownscaleValues` | [L143](../../Core/API/Threat.lua#L143) |
| `Threat.ShouldStateBeSecret` | [L156](../../Core/API/Threat.lua#L156) |
| `Threat.ShouldValuesBeSecret` | [L166](../../Core/API/Threat.lua#L166) |
| `Threat.UnitExists` | [L176](../../Core/API/Threat.lua#L176) |
| `Threat.UnitCanAttack` | [L187](../../Core/API/Threat.lua#L187) |
| `Threat.UnitIsPlayer` | [L198](../../Core/API/Threat.lua#L198) |
| `Threat.IsEnemyNpc` | [L209](../../Core/API/Threat.lua#L209) |
| `Threat.PlayerInCombat` | [L219](../../Core/API/Threat.lua#L219) |
| `Threat.IsWarningEnabled` | [L234](../../Core/API/Threat.lua#L234) |
| `Threat.ShowNumeric` | [L251](../../Core/API/Threat.lua#L251) |
| `Threat.SetShowNumeric` | [L273](../../Core/API/Threat.lua#L273) |
| `Threat.HasNumericCVar` | [L310](../../Core/API/Threat.lua#L310) |
| `Threat.HasNameplateDisplayCVar` | [L314](../../Core/API/Threat.lua#L314) |
| `Threat.HasWarningCVar` | [L318](../../Core/API/Threat.lua#L318) |
| `Threat.NameplateDisplayEnabled` | [L342](../../Core/API/Threat.lua#L342) |
| `Threat.SetNameplateDisplay` | [L358](../../Core/API/Threat.lua#L358) |
| `Threat.GetNameplateDisplayMask` | [L380](../../Core/API/Threat.lua#L380) |
| `Threat.SetNameplateDisplayMask` | [L395](../../Core/API/Threat.lua#L395) |
| `Threat.GetWarningMode` | [L410](../../Core/API/Threat.lua#L410) |
| `Threat.SetWarningMode` | [L419](../../Core/API/Threat.lua#L419) |
| `Threat.GetSituation` | [L433](../../Core/API/Threat.lua#L433) |
| `Threat.GetLeadSituation` | [L449](../../Core/API/Threat.lua#L449) |
| `Threat.GetPercentageOfLead` | [L460](../../Core/API/Threat.lua#L460) |
| `Threat.GetDetailed` | [L480](../../Core/API/Threat.lua#L480) |
| `Threat.GetNumericDisplay` | [L532](../../Core/API/Threat.lua#L532) |
| `Threat.ShouldShowNumericOnUnit` | [L559](../../Core/API/Threat.lua#L559) |
| `Threat.IsExcludedThreatUnit` | [L570](../../Core/API/Threat.lua#L570) |
| `Threat.DisplayNumber` | [L588](../../Core/API/Threat.lua#L588) |
| `Threat.ShouldShowThreat` | [L610](../../Core/API/Threat.lua#L610) |
| `Threat.GetForeverFrameDisplay` | [L628](../../Core/API/Threat.lua#L628) |
| `Threat.IsNameplateThreatTarget` | [L656](../../Core/API/Threat.lua#L656) |
| `Threat.GetForeverNameplateStatus` | [L674](../../Core/API/Threat.lua#L674) |
| `Threat.HasNonZeroDisplay` | [L684](../../Core/API/Threat.lua#L684) |
| `Threat.AccessibleNumber` | [L701](../../Core/API/Threat.lua#L701) |
| `Threat.SetBarValue` | [L712](../../Core/API/Threat.lua#L712) |
| `Threat.GetStatusColor` | [L739](../../Core/API/Threat.lua#L739) |
| `Threat.GetPercentColor` | [L776](../../Core/API/Threat.lua#L776) |
| `Threat.GetTintColor` | [L796](../../Core/API/Threat.lua#L796) |
| `Threat.SetPercentText` | [L821](../../Core/API/Threat.lua#L821) |
| `Threat.SetRankPercentText` | [L849](../../Core/API/Threat.lua#L849) |
| `Threat.GetPlayerRank` | [L917](../../Core/API/Threat.lua#L917) |
| `Threat.GetMeterRow` | [L1022](../../Core/API/Threat.lua#L1022) |

### Core/ButtonFX/Cast.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Cast.IsSpellCastVFXEnabled` | [L34](../../Core/ButtonFX/Cast.lua#L34) |
| `ButtonFX.BeginSlotPass` | [L242](../../Core/ButtonFX/Cast.lua#L242) |
| `ButtonFX.EndSlotPass` | [L249](../../Core/ButtonFX/Cast.lua#L249) |
| `ButtonFX.SpellIdFromAction` | [L381](../../Core/ButtonFX/Cast.lua#L381) |
| `ButtonFX.SpellIdFromEBS` | [L401](../../Core/ButtonFX/Cast.lua#L401) |
| `ButtonFX.SpellIdsMatch` | [L687](../../Core/ButtonFX/Cast.lua#L687) |
| `Cast.PickAllMatching` | [L766](../../Core/ButtonFX/Cast.lua#L766) |
| `Cast.PickOwners` | [L784](../../Core/ButtonFX/Cast.lua#L784) |
| `Cast.PickOwner` | [L811](../../Core/ButtonFX/Cast.lua#L811) |
| `Cast.PickOwnerByName` | [L816](../../Core/ButtonFX/Cast.lua#L816) |
| `Cast.FollowColumn` | [L1632](../../Core/ButtonFX/Cast.lua#L1632) |
| `Cast.FollowExtra` | [L1724](../../Core/ButtonFX/Cast.lua#L1724) |
| `Cast.NoteChannelTimes` | [L1826](../../Core/ButtonFX/Cast.lua#L1826) |
| `StopReticleWatch` | [L2224](../../Core/ButtonFX/Cast.lua#L2224) |
| `Cast.Start` | [L2475](../../Core/ButtonFX/Cast.lua#L2475) |
| `Cast.RefreshFromOptions` | [L2479](../../Core/ButtonFX/Cast.lua#L2479) |
| `Cast.SpellBlockedAsCurrent` | [L2495](../../Core/ButtonFX/Cast.lua#L2495) |
| `Cast.NoteTargeting` | [L2502](../../Core/ButtonFX/Cast.lua#L2502) |
| `Cast.Debug` | [L2549](../../Core/ButtonFX/Cast.lua#L2549) |
| `Cast.Register` | [L2566](../../Core/ButtonFX/Cast.lua#L2566) |
| `Cast.AdoptFace` | [L2584](../../Core/ButtonFX/Cast.lua#L2584) |

### Core/ButtonFX/Charges.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Charges.Ensure` | [L294](../../Core/ButtonFX/Charges.lua#L294) |
| `Charges.Apply` | [L368](../../Core/ButtonFX/Charges.lua#L368) |
| `Charges.ClearCache` | [L466](../../Core/ButtonFX/Charges.lua#L466) |

### Core/ButtonFX/Click.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Click.SyncCVars` | [L117](../../Core/ButtonFX/Click.lua#L117) |
| `Click.MirrorTypeRelease` | [L181](../../Core/ButtonFX/Click.lua#L181) |
| `Click.UsesWrap` | [L199](../../Core/ButtonFX/Click.lua#L199) |
| `Click.Apply` | [L207](../../Core/ButtonFX/Click.lua#L207) |

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
| `Glow.OnChange` | [L50](../../Core/ButtonFX/Glow.lua#L50) |
| `Glow.IsLive` | [L89](../../Core/ButtonFX/Glow.lua#L89) |
| `Glow.Set` | [L473](../../Core/ButtonFX/Glow.lua#L473) |
| `Glow.Transfer` | [L611](../../Core/ButtonFX/Glow.lua#L611) |
| `Glow.ShouldSkipBirth` | [L673](../../Core/ButtonFX/Glow.lua#L673) |
| `Glow.NoteShown` | [L680](../../Core/ButtonFX/Glow.lua#L680) |
| `Glow.NoteHidden` | [L690](../../Core/ButtonFX/Glow.lua#L690) |
| `Glow.FaceShowsSpell` | [L722](../../Core/ButtonFX/Glow.lua#L722) |
| `Glow.SaoMembership` | [L860](../../Core/ButtonFX/Glow.lua#L860) |
| `Glow.Want` | [L1011](../../Core/ButtonFX/Glow.lua#L1011) |
| `Glow.AnyWanted` | [L1028](../../Core/ButtonFX/Glow.lua#L1028) |
| `Glow.SilenceMixin` | [L1036](../../Core/ButtonFX/Glow.lua#L1036) |
| `Glow.Diagnostics` | [L1207](../../Core/ButtonFX/Glow.lua#L1207) |
| `Glow.DiagnosticsWanted` | [L1225](../../Core/ButtonFX/Glow.lua#L1225) |
| `Glow.DiagnosticsBars` | [L1233](../../Core/ButtonFX/Glow.lua#L1233) |
| `Glow.IsSecureAuraSpell` | [L1719](../../Core/ButtonFX/Glow.lua#L1719) |
| `Glow.CanPrepareSecureAura` | [L1723](../../Core/ButtonFX/Glow.lua#L1723) |
| `Glow.MayShowSecureAuraText` | [L1732](../../Core/ButtonFX/Glow.lua#L1732) |
| `Glow.MayShowSecureAuraSlot` | [L1741](../../Core/ButtonFX/Glow.lua#L1741) |
| `Glow.SyncSecureAura` | [L1770](../../Core/ButtonFX/Glow.lua#L1770) |
| `Glow.EnsureSecureAura` | [L1871](../../Core/ButtonFX/Glow.lua#L1871) |
| `Glow.InstallSAO` | [L1878](../../Core/ButtonFX/Glow.lua#L1878) |
| `trueframe.__sao.DoesIgnoreNative` | [L1885](../../Core/ButtonFX/Glow.lua#L1885) |
| `returnfalseendframe.__sao.GetGlowID` | [L1888](../../Core/ButtonFX/Glow.lua#L1888) |
| `endframe.__sao.EnableGlow` | [L1891](../../Core/ButtonFX/Glow.lua#L1891) |
| `endframe.__sao.DisableGlow` | [L1899](../../Core/ButtonFX/Glow.lua#L1899) |
| `Glow.NotifySAO` | [L1913](../../Core/ButtonFX/Glow.lua#L1913) |
| `Glow.Start` | [L1920](../../Core/ButtonFX/Glow.lua#L1920) |

### Core/ButtonFX/Overlay.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Overlay._tickNativeFill` | [L591](../../Core/ButtonFX/Overlay.lua#L591) |
| `Overlay._tickFinish` | [L633](../../Core/ButtonFX/Overlay.lua#L633) |
| `Overlay.WatchNativeFill` | [L673](../../Core/ButtonFX/Overlay.lua#L673) |
| `Overlay.UnwatchNativeFill` | [L684](../../Core/ButtonFX/Overlay.lua#L684) |
| `Overlay.HideCooldownCover` | [L734](../../Core/ButtonFX/Overlay.lua#L734) |
| `widget.ClearReticle` | [L831](../../Core/ButtonFX/Overlay.lua#L831) |
| `endendwidget.StopTargettingReticleAnim` | [L841](../../Core/ButtonFX/Overlay.lua#L841) |
| `endendwidget.ClearInterruptDisplay` | [L851](../../Core/ButtonFX/Overlay.lua#L851) |
| `endendwidget.StopSpellCastAnim` | [L863](../../Core/ButtonFX/Overlay.lua#L863) |
| `endwidget.PlaySpellInterruptedAnim` | [L867](../../Core/ButtonFX/Overlay.lua#L867) |
| `endwidget.PlayTargettingReticleAnim` | [L871](../../Core/ButtonFX/Overlay.lua#L871) |
| `endendwidget.PlaySpellCastAnim` | [L896](../../Core/ButtonFX/Overlay.lua#L896) |
| `Overlay.StopClassicFill` | [L1174](../../Core/ButtonFX/Overlay.lua#L1174) |
| `Overlay._classicOnUpdate` | [L1203](../../Core/ButtonFX/Overlay.lua#L1203) |
| `Overlay.PlayClassicFill` | [L1362](../../Core/ButtonFX/Overlay.lua#L1362) |
| `Overlay.PlayClassicFinish` | [L1382](../../Core/ButtonFX/Overlay.lua#L1382) |
| `Overlay.PlayClassicInterrupt` | [L1407](../../Core/ButtonFX/Overlay.lua#L1407) |
| `Overlay.HideCastFill` | [L1486](../../Core/ButtonFX/Overlay.lua#L1486) |
| `Overlay.PlayBurst` | [L1506](../../Core/ButtonFX/Overlay.lua#L1506) |
| `Overlay.PlayCast` | [L1559](../../Core/ButtonFX/Overlay.lua#L1559) |
| `Overlay.StopCast` | [L1620](../../Core/ButtonFX/Overlay.lua#L1620) |
| `Overlay.PlayInterrupt` | [L1719](../../Core/ButtonFX/Overlay.lua#L1719) |
| `Overlay.PlayReticle` | [L1758](../../Core/ButtonFX/Overlay.lua#L1758) |
| `Overlay.ClearReticle` | [L1802](../../Core/ButtonFX/Overlay.lua#L1802) |
| `Overlay.ForEachPressed` | [L1856](../../Core/ButtonFX/Overlay.lua#L1856) |
| `Overlay.NotePressed` | [L1865](../../Core/ButtonFX/Overlay.lua#L1865) |
| `Overlay.ReleasePress` | [L1876](../../Core/ButtonFX/Overlay.lua#L1876) |
| `Overlay.IsCheckedSuppressed` | [L1951](../../Core/ButtonFX/Overlay.lua#L1951) |
| `Overlay.EnsureCheckedTexture` | [L1995](../../Core/ButtonFX/Overlay.lua#L1995) |
| `Overlay.CheckedVisualOn` | [L2021](../../Core/ButtonFX/Overlay.lua#L2021) |
| `Overlay.ApplyChecked` | [L2049](../../Core/ButtonFX/Overlay.lua#L2049) |
| `Overlay.IsPushed` | [L2085](../../Core/ButtonFX/Overlay.lua#L2085) |
| `Overlay.FollowChrome` | [L2103](../../Core/ButtonFX/Overlay.lua#L2103) |
| `Overlay.ResetTargetChrome` | [L2135](../../Core/ButtonFX/Overlay.lua#L2135) |
| `Overlay.IsLiveBurst` | [L2332](../../Core/ButtonFX/Overlay.lua#L2332) |
| `Overlay.IsLiveCast` | [L2345](../../Core/ButtonFX/Overlay.lua#L2345) |
| `Overlay.IsLiveReticle` | [L2368](../../Core/ButtonFX/Overlay.lua#L2368) |
| `Overlay.IsLiveInterrupt` | [L2394](../../Core/ButtonFX/Overlay.lua#L2394) |
| `Overlay.ShouldHideCooldown` | [L2406](../../Core/ButtonFX/Overlay.lua#L2406) |
| `Overlay.ForceClear` | [L2411](../../Core/ButtonFX/Overlay.lua#L2411) |
| `Overlay.SyncCast` | [L2455](../../Core/ButtonFX/Overlay.lua#L2455) |
| `Overlay.SyncInterrupt` | [L2476](../../Core/ButtonFX/Overlay.lua#L2476) |
| `Overlay.SyncBurst` | [L2489](../../Core/ButtonFX/Overlay.lua#L2489) |
| `Overlay.TickFill` | [L2501](../../Core/ButtonFX/Overlay.lua#L2501) |
| `Overlay.TransferCast` | [L2515](../../Core/ButtonFX/Overlay.lua#L2515) |
| `Overlay.TransferReticle` | [L2580](../../Core/ButtonFX/Overlay.lua#L2580) |
| `Overlay.TransferInterrupt` | [L2605](../../Core/ButtonFX/Overlay.lua#L2605) |
| `Overlay.Transfer` | [L2645](../../Core/ButtonFX/Overlay.lua#L2645) |
| `endwidget.MatchesActiveButtonSpellID` | [L2698](../../Core/ButtonFX/Overlay.lua#L2698) |
| `Overlay.Attach` | [L2708](../../Core/ButtonFX/Overlay.lua#L2708) |

### Core/ButtonFX/ThreatGlow.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `math.ceilAnimateTexCoords` | [L188](../../Core/ButtonFX/ThreatGlow.lua#L188) |
| `lib.ButtonGlow_Start` | [L327](../../Core/ButtonFX/ThreatGlow.lua#L327) |
| `lib.ButtonGlow_Stop` | [L415](../../Core/ButtonFX/ThreatGlow.lua#L415) |
| `lib.GetFrame` | [L429](../../Core/ButtonFX/ThreatGlow.lua#L429) |

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
| `Cap.RefreshInventoryCaps` | [L616](../../Core/Capabilities.lua#L616) |
| `Cap.RefreshCharacterInfo` | [L626](../../Core/Capabilities.lua#L626) |
| `Cap.IsForeverGamepadUI` | [L662](../../Core/Capabilities.lua#L662) |

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
| `Combat.ScheduleRegenQueues` | [L67](../../Core/Engine/Combat.lua#L67) |
| `Combat.RegenDefer` | [L80](../../Core/Engine/Combat.lua#L80) |
| `endend_G.FluxCombatRegenDeferQueue` | [L96](../../Core/Engine/Combat.lua#L96) |
| `end_G.FluxRegenDeferHeavyQueue` | [L100](../../Core/Engine/Combat.lua#L100) |
| `Combat.Defer` | [L105](../../Core/Engine/Combat.lua#L105) |
| `Combat.Flush` | [L120](../../Core/Engine/Combat.lua#L120) |
| `Combat.HasPending` | [L171](../../Core/Engine/Combat.lua#L171) |
| `Combat.PendingCount` | [L175](../../Core/Engine/Combat.lua#L175) |

### Core/Engine/Context.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Context.Fingerprint` | [L266](../../Core/Engine/Context.lua#L266) |
| `Context.MouseoverReactionClass` | [L273](../../Core/Engine/Context.lua#L273) |
| `Context.IsUfPeek` | [L277](../../Core/Engine/Context.lua#L277) |
| `Context.Subscribe` | [L281](../../Core/Engine/Context.lua#L281) |
| `Context.Unsubscribe` | [L292](../../Core/Engine/Context.lua#L292) |
| `Context.HasSubscribers` | [L307](../../Core/Engine/Context.lua#L307) |
| `Context.Request` | [L311](../../Core/Engine/Context.lua#L311) |
| `Context.RequestMouseover` | [L357](../../Core/Engine/Context.lua#L357) |
| `Context.GetStats` | [L418](../../Core/Engine/Context.lua#L418) |
| `Context.ResetStats` | [L422](../../Core/Engine/Context.lua#L422) |
| `thenMK.RegisterFrame` | [L493](../../Core/Engine/Context.lua#L493) |
| `Context.ArmEvents` | [L503](../../Core/Engine/Context.lua#L503) |
| `Context.DisarmEvents` | [L558](../../Core/Engine/Context.lua#L558) |

### Core/Engine/Events.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Events.IsValid` | [L65](../../Core/Engine/Events.lua#L65) |
| `Events.ObserveTiming` | [L89](../../Core/Engine/Events.lua#L89) |
| `Events.SetTrace` | [L161](../../Core/Engine/Events.lua#L161) |
| `Events.Register` | [L165](../../Core/Engine/Events.lua#L165) |
| `Events.Unregister` | [L187](../../Core/Engine/Events.lua#L187) |
| `Events.RegisterUnit` | [L213](../../Core/Engine/Events.lua#L213) |
| `Events.SafeRegister` | [L242](../../Core/Engine/Events.lua#L242) |
| `Events.SafeRegisterUnit` | [L256](../../Core/Engine/Events.lua#L256) |
| `Events.RegisterLearnedSpell` | [L270](../../Core/Engine/Events.lua#L270) |

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
| `MouseoverCast.UsesNativeCVar` | [L185](../../Core/Engine/MouseoverCast.lua#L185) |
| `MouseoverCast.IsEnabled` | [L197](../../Core/Engine/MouseoverCast.lua#L197) |
| `MouseoverCast.IsActive` | [L212](../../Core/Engine/MouseoverCast.lua#L212) |
| `MouseoverCast.OpenNativeOptions` | [L224](../../Core/Engine/MouseoverCast.lua#L224) |
| `MouseoverCast.ApplyNativeCheck` | [L256](../../Core/Engine/MouseoverCast.lua#L256) |
| `MouseoverCast.SyncDrivers` | [L654](../../Core/Engine/MouseoverCast.lua#L654) |
| `MouseoverCast.RegisterHeader` | [L680](../../Core/Engine/MouseoverCast.lua#L680) |
| `MouseoverCast.AttachHost` | [L707](../../Core/Engine/MouseoverCast.lua#L707) |
| `MouseoverCast.RegisterButton` | [L741](../../Core/Engine/MouseoverCast.lua#L741) |
| `MouseoverCast.SetButtonSpell` | [L769](../../Core/Engine/MouseoverCast.lua#L769) |
| `MouseoverCast.SetButtonItem` | [L793](../../Core/Engine/MouseoverCast.lua#L793) |
| `MouseoverCast.ConfigureUtility` | [L807](../../Core/Engine/MouseoverCast.lua#L807) |
| `MouseoverCast.AttachUtilityKeyer` | [L828](../../Core/Engine/MouseoverCast.lua#L828) |
| `MouseoverCast.UtilityRangeUnit` | [L835](../../Core/Engine/MouseoverCast.lua#L835) |
| `MouseoverCast.Apply` | [L868](../../Core/Engine/MouseoverCast.lua#L868) |
| `MouseoverCast.RefreshSetting` | [L919](../../Core/Engine/MouseoverCast.lua#L919) |
| `MouseoverCast.SetEnabled` | [L954](../../Core/Engine/MouseoverCast.lua#L954) |
| `MouseoverCast.GetStats` | [L965](../../Core/Engine/MouseoverCast.lua#L965) |
| `MouseoverCast.DebugDump` | [L976](../../Core/Engine/MouseoverCast.lua#L976) |
| `MouseoverCast.GetSpellBookCheckbox` | [L1064](../../Core/Engine/MouseoverCast.lua#L1064) |
| `MouseoverCast.RefreshSpellBookCheckbox` | [L1071](../../Core/Engine/MouseoverCast.lua#L1071) |
| `PositionSpellBookCheckbox` | [L1123](../../Core/Engine/MouseoverCast.lua#L1123) |
| `MouseoverCast.Start` | [L1253](../../Core/Engine/MouseoverCast.lua#L1253) |

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
| `Range.SetInterval` | [L49](../../Core/Engine/Range.lua#L49) |
| `Range.GetInterval` | [L53](../../Core/Engine/Range.lua#L53) |
| `Range.SetExtraInterval` | [L57](../../Core/Engine/Range.lua#L57) |
| `Range.GetExtraInterval` | [L61](../../Core/Engine/Range.lua#L61) |
| `Range.GetUnitRevision` | [L89](../../Core/Engine/Range.lua#L89) |
| `Range.ResolveUnit` | [L163](../../Core/Engine/Range.lua#L163) |
| `Range.CheckSpell` | [L243](../../Core/Engine/Range.lua#L243) |
| `Range.CheckItem` | [L255](../../Core/Engine/Range.lua#L255) |
| `Range.CheckAction` | [L272](../../Core/Engine/Range.lua#L272) |
| `Range.RegisterSweep` | [L290](../../Core/Engine/Range.lua#L290) |
| `Range.Sync` | [L373](../../Core/Engine/Range.lua#L373) |
| `Range.IsArmed` | [L391](../../Core/Engine/Range.lua#L391) |
| `Range.IsHopBurst` | [L397](../../Core/Engine/Range.lua#L397) |
| `Range.Invalidate` | [L408](../../Core/Engine/Range.lua#L408) |
| `Range.InvalidateSweep` | [L415](../../Core/Engine/Range.lua#L415) |
| `Range.UnitReactionClass` | [L428](../../Core/Engine/Range.lua#L428) |
| `Range.TargetReactionClass` | [L451](../../Core/Engine/Range.lua#L451) |
| `Range.Start` | [L477](../../Core/Engine/Range.lua#L477) |

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
| `Restricted.RegisterAttributeDriver` | [L368](../../Core/Engine/Restricted.lua#L368) |
| `Restricted.UnregisterAttributeDriver` | [L391](../../Core/Engine/Restricted.lua#L391) |
| `Restricted.RegisterStateDriver` | [L416](../../Core/Engine/Restricted.lua#L416) |
| `Restricted.UnregisterStateDriver` | [L420](../../Core/Engine/Restricted.lua#L420) |
| `Restricted.RegisterUnitWatch` | [L427](../../Core/Engine/Restricted.lua#L427) |
| `Restricted.UnregisterUnitWatch` | [L442](../../Core/Engine/Restricted.lua#L442) |
| `Restricted.UnitWatchRegistered` | [L457](../../Core/Engine/Restricted.lua#L457) |

### Core/Engine/Scheduler.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Scheduler.ObserveTiming` | [L80](../../Core/Engine/Scheduler.lua#L80) |
| `Scheduler.Register` | [L137](../../Core/Engine/Scheduler.lua#L137) |
| `Scheduler.BeginPaging` | [L145](../../Core/Engine/Scheduler.lua#L145) |
| `Scheduler.EndPaging` | [L149](../../Core/Engine/Scheduler.lua#L149) |
| `Scheduler.IsPaging` | [L153](../../Core/Engine/Scheduler.lua#L153) |
| `Scheduler.Request` | [L158](../../Core/Engine/Scheduler.lua#L158) |
| `Scheduler.HasPending` | [L189](../../Core/Engine/Scheduler.lua#L189) |
| `Scheduler.Flush` | [L281](../../Core/Engine/Scheduler.lua#L281) |
| `Scheduler.Stats` | [L331](../../Core/Engine/Scheduler.lua#L331) |

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
| `Chrome.Observe` | [L51](../../Core/Engine/SpellBookChrome.lua#L51) |
| `Chrome.HasLowRankApi` | [L70](../../Core/Engine/SpellBookChrome.lua#L70) |
| `Chrome.HasBlizzardShowAllRanksDropdown` | [L74](../../Core/Engine/SpellBookChrome.lua#L74) |
| `Chrome.GetBlizzardShowAllRanksCheckbox` | [L79](../../Core/Engine/SpellBookChrome.lua#L79) |
| `Chrome.GetFluxShowAllRanksCheckbox` | [L87](../../Core/Engine/SpellBookChrome.lua#L87) |
| `Chrome.EnsureBlizzardShowAllRanks` | [L98](../../Core/Engine/SpellBookChrome.lua#L98) |
| `Chrome.ShouldCreateFluxShowAllRanks` | [L118](../../Core/Engine/SpellBookChrome.lua#L118) |
| `Chrome.RankChromeAllowed` | [L135](../../Core/Engine/SpellBookChrome.lua#L135) |
| `Chrome.GetHost` | [L148](../../Core/Engine/SpellBookChrome.lua#L148) |
| `Chrome.UsesCompactLayout` | [L158](../../Core/Engine/SpellBookChrome.lua#L158) |
| `Chrome.HideRankChrome` | [L199](../../Core/Engine/SpellBookChrome.lua#L199) |
| `Chrome.Layout` | [L271](../../Core/Engine/SpellBookChrome.lua#L271) |

### Core/Engine/Ticker.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Ticker.ObserveTiming` | [L29](../../Core/Engine/Ticker.lua#L29) |
| `Ticker.SetTrace` | [L82](../../Core/Engine/Ticker.lua#L82) |
| `Ticker.Add` | [L100](../../Core/Engine/Ticker.lua#L100) |
| `Ticker.Remove` | [L119](../../Core/Engine/Ticker.lua#L119) |
| `Ticker.IsArmed` | [L137](../../Core/Engine/Ticker.lua#L137) |
| `Ticker.Count` | [L141](../../Core/Engine/Ticker.lua#L141) |
| `Ticker.Ticks` | [L145](../../Core/Engine/Ticker.lua#L145) |
| `Ticker.GetSubscribers` | [L150](../../Core/Engine/Ticker.lua#L150) |

### Core/Engine/Timer.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `handle.Cancel` | [L92](../../Core/Engine/Timer.lua#L92) |
| `Timer.After` | [L106](../../Core/Engine/Timer.lua#L106) |
| `Timer.NewTicker` | [L120](../../Core/Engine/Timer.lua#L120) |
| `Timer.Defer` | [L127](../../Core/Engine/Timer.lua#L127) |
| `Timer.HasPendingPolyfill` | [L131](../../Core/Engine/Timer.lua#L131) |

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
| `FluxSilenceEditModeSpecLayoutRefresh` | [L285](../../Core/FluxAPI/UI.lua#L285) |
| `FluxEditModeBusy` | [L310](../../Core/FluxAPI/UI.lua#L310) |
| `FluxAfterEditMode` | [L348](../../Core/FluxAPI/UI.lua#L348) |
| `FLUX_API.ClientHasMicroMenuFeature` | [L608](../../Core/FluxAPI/UI.lua#L608) |
| `FLUX_API.ClientHasMinimapGroupFinder` | [L616](../../Core/FluxAPI/UI.lua#L616) |
| `FLUX_API.ClientHasBlizzardMicroGroupFinder` | [L621](../../Core/FluxAPI/UI.lua#L621) |
| `FluxClientHasMicroMenuFeature` | [L634](../../Core/FluxAPI/UI.lua#L634) |
| `FluxClientHasMinimapGroupFinder` | [L635](../../Core/FluxAPI/UI.lua#L635) |
| `FluxClientHasBlizzardMicroGroupFinder` | [L636](../../Core/FluxAPI/UI.lua#L636) |
| `FluxGetStandardMicroButtonSize` | [L641](../../Core/FluxAPI/UI.lua#L641) |
| `FluxStandardizeMicroButton` | [L646](../../Core/FluxAPI/UI.lua#L646) |
| `FluxGetMicroButtonSpacing` | [L659](../../Core/FluxAPI/UI.lua#L659) |
| `FluxDetectMicroButtonTopGap` | [L661](../../Core/FluxAPI/UI.lua#L661) |
| `FluxGetMicroButtonTopGap` | [L668](../../Core/FluxAPI/UI.lua#L668) |
| `FluxShouldApplyMicroButtonTopGapLayout` | [L674](../../Core/FluxAPI/UI.lua#L674) |
| `FluxShouldUseDfStyleVerticalMicroMenuGrid` | [L679](../../Core/FluxAPI/UI.lua#L679) |
| `FluxGetMicroMenuLayoutTopGap` | [L685](../../Core/FluxAPI/UI.lua#L685) |
| `FluxGetMicroMenuLegacyBarHeightExtra` | [L690](../../Core/FluxAPI/UI.lua#L690) |
| `FluxGetMicroButtonLayoutInfo` | [L692](../../Core/FluxAPI/UI.lua#L692) |
| `FluxPlayerCanUseTalentMicroButton` | [L708](../../Core/FluxAPI/UI.lua#L708) |
| `FluxUpdateTalentMicroButtonPreDF` | [L731](../../Core/FluxAPI/UI.lua#L731) |
| `FluxSetupPortraitModel` | [L774](../../Core/FluxAPI/UI.lua#L774) |
| `unitmodel.SetUnit` | [L808](../../Core/FluxAPI/UI.lua#L808) |
| `FluxNeedsPortraitCompat` | [L842](../../Core/FluxAPI/UI.lua#L842) |
| `ns.API.SafeSetAtlas` | [L859](../../Core/FluxAPI/UI.lua#L859) |
| `CreateLegacyBattlefieldBorderPiece` | [L891](../../Core/FluxAPI/UI.lua#L891) |
| `FluxUI_UsesAlternativeBagUI` | [L907](../../Core/FluxAPI/UI.lua#L907) |
| `FluxRegisterSettingsCategory` | [L920](../../Core/FluxAPI/UI.lua#L920) |
| `thenifSettingsandSettings.RegisterCanvasLayoutCategoryandSettings.RegisterAddOnCategorythenInterfaceOptions_AddCategory` | [L944](../../Core/FluxAPI/UI.lua#L944) |
| `FluxAPICompat.GetPlayerHasMana` | [L968](../../Core/FluxAPI/UI.lua#L968) |
| `FluxAPICompat.ResetManaCache` | [L976](../../Core/FluxAPI/UI.lua#L976) |
| `FluxAPICompat.CancelBankOpenWork` | [L1009](../../Core/FluxAPI/UI.lua#L1009) |
| `FluxCancelBankOpenWork` | [L1014](../../Core/FluxAPI/UI.lua#L1014) |
| `FluxAPICompat.DeferBankOpenWork` | [L1016](../../Core/FluxAPI/UI.lua#L1016) |
| `FluxDeferBankOpenWork` | [L1031](../../Core/FluxAPI/UI.lua#L1031) |
| `FluxAPICompat.IsUnifiedBankPaintReady` | [L1033](../../Core/FluxAPI/UI.lua#L1033) |
| `FluxIsUnifiedBankPaintReady` | [L1037](../../Core/FluxAPI/UI.lua#L1037) |
| `FluxAPICompat.DeferBankTransferWork` | [L1046](../../Core/FluxAPI/UI.lua#L1046) |
| `FluxDeferBankTransferWork` | [L1056](../../Core/FluxAPI/UI.lua#L1056) |
| `ns.API.GetNumPlayerTalentGroups` | [L1063](../../Core/FluxAPI/UI.lua#L1063) |
| `ns.API.GetActivePlayerTalentGroup` | [L1075](../../Core/FluxAPI/UI.lua#L1075) |
| `ns.API.SetActivePlayerTalentGroup` | [L1087](../../Core/FluxAPI/UI.lua#L1087) |
| `ns.API.TogglePlayerDualTalentGroup` | [L1097](../../Core/FluxAPI/UI.lua#L1097) |
| `ns.API.GetPlayerSpecFlyoutEntries` | [L1106](../../Core/FluxAPI/UI.lua#L1106) |
| `ns.API.GetPlayerSpecFlyoutEntriesIncludingActive` | [L1128](../../Core/FluxAPI/UI.lua#L1128) |
| `ns.API.TrySetPlayerSpecialization` | [L1143](../../Core/FluxAPI/UI.lua#L1143) |
| `ns.API.CanPlayerUseTalentSpecUI` | [L1152](../../Core/FluxAPI/UI.lua#L1152) |
| `ns.API.GetPlayerSpecSwitchMode` | [L1160](../../Core/FluxAPI/UI.lua#L1160) |
| `ns.API.HasPlayerTransmogOutfitAPI` | [L1169](../../Core/FluxAPI/UI.lua#L1169) |
| `ns.API.GetPlayerTransmogOutfitEntries` | [L1180](../../Core/FluxAPI/UI.lua#L1180) |
| `ns.API.GetPlayerTransmogOutfitAction` | [L1231](../../Core/FluxAPI/UI.lua#L1231) |
| `ns.API.IsPlayerTransmogOutfitActive` | [L1256](../../Core/FluxAPI/UI.lua#L1256) |
| `ns.API.GetPlayerTransmogOutfitIDForSpell` | [L1267](../../Core/FluxAPI/UI.lua#L1267) |
| `ns.API.TryApplyPlayerTransmogOutfit` | [L1276](../../Core/FluxAPI/UI.lua#L1276) |
| `ns.API.TryPickupPlayerTransmogOutfit` | [L1284](../../Core/FluxAPI/UI.lua#L1284) |
| `FluxIsDetailsActorLocalPlayer` | [L1307](../../Core/FluxAPI/UI.lua#L1307) |
| `FluxIsDetailsMeterSourceLocalPlayer` | [L1329](../../Core/FluxAPI/UI.lua#L1329) |

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
| `Module.Create` | [L453](../../ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua#L453) |

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
| `Action.GetMountInfo` | [L419](../../ExtraButtonSystem/Engine/Action.lua#L419) |
| `Action.SupportsAssistant` | [L453](../../ExtraButtonSystem/Engine/Action.lua#L453) |
| `Action.GetAssistantActionSpell` | [L461](../../ExtraButtonSystem/Engine/Action.lua#L461) |
| `Action.GetAssistantNextSpell` | [L479](../../ExtraButtonSystem/Engine/Action.lua#L479) |
| `Action.IsAssistantSpell` | [L500](../../ExtraButtonSystem/Engine/Action.lua#L500) |
| `Action.GetAssistantButton` | [L530](../../ExtraButtonSystem/Engine/Action.lua#L530) |
| `Action.LayoutAssistant` | [L600](../../ExtraButtonSystem/Engine/Action.lua#L600) |
| `Action.UpdateAssistantChrome` | [L604](../../ExtraButtonSystem/Engine/Action.lua#L604) |
| `existing.OnUpdate` | [L637](../../ExtraButtonSystem/Engine/Action.lua#L637) |
| `frame.OnUpdate` | [L652](../../ExtraButtonSystem/Engine/Action.lua#L652) |
| `Action.AttachAssistant` | [L691](../../ExtraButtonSystem/Engine/Action.lua#L691) |
| `Action.ClearAssistant` | [L714](../../ExtraButtonSystem/Engine/Action.lua#L714) |
| `Action.SyncAssistant` | [L734](../../ExtraButtonSystem/Engine/Action.lua#L734) |
| `Action.RefreshAssistantIdentity` | [L758](../../ExtraButtonSystem/Engine/Action.lua#L758) |
| `Action.RefreshAssistantChrome` | [L776](../../ExtraButtonSystem/Engine/Action.lua#L776) |
| `Action.PaintAssistantButtons` | [L790](../../ExtraButtonSystem/Engine/Action.lua#L790) |
| `Action.RebindAssistant` | [L807](../../ExtraButtonSystem/Engine/Action.lua#L807) |
| `Action.ClearEnv` | [L839](../../ExtraButtonSystem/Engine/Action.lua#L839) |
| `Action.InvalidateMacroParseCache` | [L1403](../../ExtraButtonSystem/Engine/Action.lua#L1403) |
| `Action.ShownFromBody` | [L1579](../../ExtraButtonSystem/Engine/Action.lua#L1579) |
| `Action.TranslateMacro` | [L1685](../../ExtraButtonSystem/Engine/Action.lua#L1685) |
| `Action.TranslateMatching` | [L1844](../../ExtraButtonSystem/Engine/Action.lua#L1844) |
| `Action.RefreshMacroDisplay` | [L1869](../../ExtraButtonSystem/Engine/Action.lua#L1869) |
| `Action.SyncMacroProbes` | [L2041](../../ExtraButtonSystem/Engine/Action.lua#L2041) |
| `Action.RequestMacroDisplay` | [L2076](../../ExtraButtonSystem/Engine/Action.lua#L2076) |
| `Action.RefreshMacroBindings` | [L2153](../../ExtraButtonSystem/Engine/Action.lua#L2153) |
| `Action.OnMacrosUpdated` | [L2215](../../ExtraButtonSystem/Engine/Action.lua#L2215) |
| `Action.EnableMacroPrune` | [L2224](../../ExtraButtonSystem/Engine/Action.lua#L2224) |
| `Action.ForceMacrosLoaded` | [L2231](../../ExtraButtonSystem/Engine/Action.lua#L2231) |
| `Action.RefreshOutfits` | [L2260](../../ExtraButtonSystem/Engine/Action.lua#L2260) |
| `Action.SetAction` | [L2277](../../ExtraButtonSystem/Engine/Action.lua#L2277) |
| `Action.MouseoverCastSpell` | [L2348](../../ExtraButtonSystem/Engine/Action.lua#L2348) |
| `Action.RefreshMounts` | [L2359](../../ExtraButtonSystem/Engine/Action.lua#L2359) |
| `Action.Clear` | [L2392](../../ExtraButtonSystem/Engine/Action.lua#L2392) |
| `Action.Pickup` | [L2581](../../ExtraButtonSystem/Engine/Action.lua#L2581) |
| `Action.NoteFlyoutPopupSpell` | [L2644](../../ExtraButtonSystem/Engine/Action.lua#L2644) |
| `Action.NoteFlyoutPopupItem` | [L2653](../../ExtraButtonSystem/Engine/Action.lua#L2653) |
| `Action.OnReceiveDrag` | [L2856](../../ExtraButtonSystem/Engine/Action.lua#L2856) |
| `Action.OnDragStart` | [L2914](../../ExtraButtonSystem/Engine/Action.lua#L2914) |
| `Action.OnEnter` | [L3029](../../ExtraButtonSystem/Engine/Action.lua#L3029) |
| `Action.AppendTooltipExtras` | [L3061](../../ExtraButtonSystem/Engine/Action.lua#L3061) |
| `Action.OnLeave` | [L3087](../../ExtraButtonSystem/Engine/Action.lua#L3087) |
| `Action.UpdateTooltip` | [L3176](../../ExtraButtonSystem/Engine/Action.lua#L3176) |
| `FluxButton:SetAction` | [L3329](../../ExtraButtonSystem/Engine/Action.lua#L3329) |
| `FluxButton:OnEnter` | [L3333](../../ExtraButtonSystem/Engine/Action.lua#L3333) |
| `FluxButton:OnLeave` | [L3340](../../ExtraButtonSystem/Engine/Action.lua#L3340) |
| `FluxButton:FullRefresh` | [L3344](../../ExtraButtonSystem/Engine/Action.lua#L3344) |
| `FluxButton:TranslateFace` | [L3350](../../ExtraButtonSystem/Engine/Action.lua#L3350) |
| `FluxButton:TranslateMacro` | [L3354](../../ExtraButtonSystem/Engine/Action.lua#L3354) |
| `FluxButton:ClearAction` | [L3358](../../ExtraButtonSystem/Engine/Action.lua#L3358) |
| `FluxButton:Pickup` | [L3362](../../ExtraButtonSystem/Engine/Action.lua#L3362) |

### ExtraButtonSystem/Engine/Badge.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Badge.StackCount` | [L19](../../ExtraButtonSystem/Engine/Badge.lua#L19) |
| `Badge.SyncCountFont` | [L95](../../ExtraButtonSystem/Engine/Badge.lua#L95) |
| `Badge.SyncFrameLevel` | [L139](../../ExtraButtonSystem/Engine/Badge.lua#L139) |
| `Badge.Layout` | [L225](../../ExtraButtonSystem/Engine/Badge.lua#L225) |
| `Badge.ShowVisual` | [L311](../../ExtraButtonSystem/Engine/Badge.lua#L311) |
| `Badge.HideVisual` | [L337](../../ExtraButtonSystem/Engine/Badge.lua#L337) |
| `Badge.ApplyVisualSpellTexture` | [L358](../../ExtraButtonSystem/Engine/Badge.lua#L358) |
| `Badge.Clear` | [L381](../../ExtraButtonSystem/Engine/Badge.lua#L381) |
| `Badge.New` | [L395](../../ExtraButtonSystem/Engine/Badge.lua#L395) |
| `endbtn.Layout` | [L428](../../ExtraButtonSystem/Engine/Badge.lua#L428) |
| `endbtn.ShowVisual` | [L431](../../ExtraButtonSystem/Engine/Badge.lua#L431) |
| `endbtn.HideVisual` | [L434](../../ExtraButtonSystem/Engine/Badge.lua#L434) |
| `endbtn.ApplyVisualSpellTexture` | [L437](../../ExtraButtonSystem/Engine/Badge.lua#L437) |
| `endbtn.Clear` | [L440](../../ExtraButtonSystem/Engine/Badge.lua#L440) |

### ExtraButtonSystem/Engine/ConsumableBind.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Bridge.ShouldHoldItemIdentity` | [L85](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L85) |
| `Bridge.KeepConsumableSlot` | [L90](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L90) |
| `Bridge.BagCount` | [L221](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L221) |
| `Bridge.DisplayItemCount` | [L228](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L228) |
| `Bridge.IsManaGemChargeBased` | [L259](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L259) |
| `Bridge.ShouldUseChargeBasedManaGemOnly` | [L266](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L266) |
| `Bridge.KnowsManaGemConjureSpell` | [L369](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L369) |
| `Bridge.IsManaGemConjureFree` | [L393](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L393) |
| `Bridge.ShouldStickyManaGemItem` | [L403](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L403) |
| `Bridge.GetPreferredManaGemItemID` | [L408](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L408) |
| `Bridge.GetNextManaGemConjureSpell` | [L416](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L416) |
| `Bridge.GetBestOwned` | [L498](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L498) |
| `Bridge.GetOwnedLadder` | [L650](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L650) |
| `Bridge.PromoteIfBetter` | [L856](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L856) |
| `Bridge.CanCreate` | [L908](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L908) |
| `Bridge.GetPreferredCreateSpell` | [L917](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L917) |
| `Bridge.GetFoodConjureSpell` | [L928](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L928) |
| `Bridge.GetFoodSecondaryConjureSpell` | [L936](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L936) |
| `Bridge.GetWaterConjureSpell` | [L944](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L944) |
| `Bridge.GetWaterSecondaryConjureSpell` | [L952](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L952) |
| `Bridge.ApplyRightClickMacro` | [L967](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L967) |
| `Bridge.ResolveSpellName` | [L986](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L986) |
| `Bridge.ApplyRightClickSpell` | [L1013](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1013) |
| `Bridge.ApplyShiftRightClickSpell` | [L1070](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1070) |
| `Bridge.ApplyCtrlRightClickSpell` | [L1126](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1126) |
| `Bridge.ApplyUseAndConjureBindings` | [L1185](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1185) |
| `Bridge.BuildUseItemMacro` | [L1263](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1263) |
| `Bridge.BuildCastSequenceMacro` | [L1271](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1271) |
| `Bridge.After` | [L1292](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1292) |
| `Bridge.DeleteOneOwned` | [L1303](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1303) |
| `Bridge.IsConjured` | [L1339](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1339) |
| `Bridge.DeleteOneConjuredOwned` | [L1366](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1366) |
| `Bridge.ApplyBinding` | [L1374](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1374) |
| `Bridge.FormatSpellTooltipLine` | [L1407](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1407) |
| `Bridge.ResetFluxTooltipGap` | [L1524](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1524) |
| `Bridge._EnsureFluxTooltipGap` | [L1531](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1531) |
| `Bridge.AppendConjureSpellLines` | [L1539](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1539) |
| `Bridge.AppendTierStatusLines` | [L1689](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1689) |
| `Bridge.AppendDeleteStackHint` | [L1782](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1782) |
| `Bridge.WireRestockEdit` | [L1818](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1818) |
| `Bridge.GetRestockClickHint` | [L1860](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1860) |
| `Bridge.AppendRestockEditHint` | [L1864](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1864) |
| `Bridge.GetBestCraftable` | [L1956](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1956) |
| `Bridge.CanCraft` | [L1965](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1965) |
| `Bridge.GetCraftMacro` | [L1974](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1974) |
| `Bridge.ApplyCraftOrRestockRightClick` | [L2012](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2012) |
| `Bridge.AppendCraftTooltipLines` | [L2066](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2066) |
| `Bridge.ApplyMiddleClickNoUse` | [L2103](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2103) |
| `Bridge.SuppressCheckedVisual` | [L2146](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2146) |
| `Bridge.SuppressCheckedVisualSettle` | [L2186](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2186) |
| `Bridge.GetConsumableCombatSwap` | [L2226](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2226) |
| `Bridge.SetConsumableCombatSwap` | [L2238](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2238) |
| `Bridge.CombatSwapTooltipKind` | [L2253](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2253) |
| `Bridge.SyncSwapEmptyFace` | [L2370](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2370) |
| `Bridge.ApplyCombatSwap` | [L2467](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2467) |
| `Bridge.RefreshConsumableCombatSwap` | [L2533](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2533) |
| `Bridge.QueueConsumableFaceRefresh` | [L2633](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2633) |
| `Refresh.Attach` | [L2831](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2831) |
| `Module.Update` | [L3173](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3173) |
| `Module.RefreshCountOnly` | [L3380](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3380) |
| `Module.RefreshCraftState` | [L3444](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3444) |
| `Module.Update` | [L3676](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3676) |

### ExtraButtonSystem/Engine/Paint.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Paint.InvalidateSpellCaches` | [L42](../../ExtraButtonSystem/Engine/Paint.lua#L42) |
| `Paint.ClearCache` | [L56](../../ExtraButtonSystem/Engine/Paint.lua#L56) |
| `Paint.IsParked` | [L81](../../ExtraButtonSystem/Engine/Paint.lua#L81) |
| `Paint.RequestShown` | [L102](../../ExtraButtonSystem/Engine/Paint.lua#L102) |
| `Paint.HasPendingIcon` | [L123](../../ExtraButtonSystem/Engine/Paint.lua#L123) |
| `Paint.UpdateEmpty` | [L240](../../ExtraButtonSystem/Engine/Paint.lua#L240) |
| `Paint.EnsureAutocast` | [L352](../../ExtraButtonSystem/Engine/Paint.lua#L352) |
| `Paint.UpdateAutocast` | [L383](../../ExtraButtonSystem/Engine/Paint.lua#L383) |
| `Paint.UpdateIcon` | [L701](../../ExtraButtonSystem/Engine/Paint.lua#L701) |
| `Paint.UpdateCount` | [L1172](../../ExtraButtonSystem/Engine/Paint.lua#L1172) |
| `Paint.UpdateCooldown` | [L1866](../../ExtraButtonSystem/Engine/Paint.lua#L1866) |
| `Paint.UpdateAllCooldowns` | [L2023](../../ExtraButtonSystem/Engine/Paint.lua#L2023) |
| `Paint.UpdateUsable` | [L2375](../../ExtraButtonSystem/Engine/Paint.lua#L2375) |
| `Paint.NotePlayerCast` | [L2619](../../ExtraButtonSystem/Engine/Paint.lua#L2619) |
| `Paint.UpdateFlash` | [L3013](../../ExtraButtonSystem/Engine/Paint.lua#L3013) |
| `Paint.FlushFlash` | [L3051](../../ExtraButtonSystem/Engine/Paint.lua#L3051) |
| `Paint.UpdateChecked` | [L3066](../../ExtraButtonSystem/Engine/Paint.lua#L3066) |
| `Paint.FlushIcons` | [L3206](../../ExtraButtonSystem/Engine/Paint.lua#L3206) |
| `Paint.RequestIcon` | [L3230](../../ExtraButtonSystem/Engine/Paint.lua#L3230) |
| `Paint.FlushChecked` | [L3264](../../ExtraButtonSystem/Engine/Paint.lua#L3264) |
| `Paint.ArmCheckedPoll` | [L3339](../../ExtraButtonSystem/Engine/Paint.lua#L3339) |
| `Paint.RequestChecked` | [L3347](../../ExtraButtonSystem/Engine/Paint.lua#L3347) |
| `Paint.RequestCheckedSettle` | [L3363](../../ExtraButtonSystem/Engine/Paint.lua#L3363) |
| `Paint.UpdateGlow` | [L3376](../../ExtraButtonSystem/Engine/Paint.lua#L3376) |
| `Paint.UpdateEquipped` | [L3522](../../ExtraButtonSystem/Engine/Paint.lua#L3522) |
| `Paint.UpdateRange` | [L3641](../../ExtraButtonSystem/Engine/Paint.lua#L3641) |
| `Paint.Update` | [L3660](../../ExtraButtonSystem/Engine/Paint.lua#L3660) |
| `Paint.UpdateLiveFace` | [L3680](../../ExtraButtonSystem/Engine/Paint.lua#L3680) |
| `Paint.FlushEval` | [L3691](../../ExtraButtonSystem/Engine/Paint.lua#L3691) |
| `Paint.FlushCounts` | [L3797](../../ExtraButtonSystem/Engine/Paint.lua#L3797) |
| `FluxButton:UpdateEmptyBackground` | [L3851](../../ExtraButtonSystem/Engine/Paint.lua#L3851) |
| `FluxButton:UpdateUsable` | [L3855](../../ExtraButtonSystem/Engine/Paint.lua#L3855) |
| `FluxButton:UpdateCooldown` | [L3859](../../ExtraButtonSystem/Engine/Paint.lua#L3859) |
| `FluxButton:UpdateEquipped` | [L3863](../../ExtraButtonSystem/Engine/Paint.lua#L3863) |

### ExtraButtonSystem/Engine/Range.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Range.IsArmed` | [L81](../../ExtraButtonSystem/Engine/Range.lua#L81) |
| `Range.RefreshButton` | [L86](../../ExtraButtonSystem/Engine/Range.lua#L86) |
| `Range.RefreshFlags` | [L100](../../ExtraButtonSystem/Engine/Range.lua#L100) |
| `Range.RefreshItemFlags` | [L115](../../ExtraButtonSystem/Engine/Range.lua#L115) |
| `Range.Sync` | [L119](../../ExtraButtonSystem/Engine/Range.lua#L119) |
| `Range.SyncDemand` | [L135](../../ExtraButtonSystem/Engine/Range.lua#L135) |
| `Range.Start` | [L139](../../ExtraButtonSystem/Engine/Range.lua#L139) |

### ExtraButtonSystem/Engine/Style.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Style.UseQuickslotRing` | [L24](../../ExtraButtonSystem/Engine/Style.lua#L24) |
| `Style.StampFace` | [L108](../../ExtraButtonSystem/Engine/Style.lua#L108) |
| `Style.RefreshSqueezeChrome` | [L121](../../ExtraButtonSystem/Engine/Style.lua#L121) |
| `Style.SizeRing` | [L419](../../ExtraButtonSystem/Engine/Style.lua#L419) |
| `Style.Apply` | [L524](../../ExtraButtonSystem/Engine/Style.lua#L524) |
| `Style.ApplySlotRing` | [L553](../../ExtraButtonSystem/Engine/Style.lua#L553) |

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
| `Widget.AfterClickPaint` | [L390](../../ExtraButtonSystem/Engine/Widget.lua#L390) |
| `Widget.BindLockedExtraHost` | [L432](../../ExtraButtonSystem/Engine/Widget.lua#L432) |
| `Widget.Attach` | [L481](../../ExtraButtonSystem/Engine/Widget.lua#L481) |
| `Widget.Create` | [L583](../../ExtraButtonSystem/Engine/Widget.lua#L583) |
| `widget:UpdateFlyout` | [L659](../../ExtraButtonSystem/Engine/Widget.lua#L659) |
| `widget:UpdateCooldown` | [L699](../../ExtraButtonSystem/Engine/Widget.lua#L699) |

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
| `Arrow.Rotation` | [L68](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L68) |
| `Arrow.Anchor` | [L82](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L82) |
| `Arrow.SetTint` | [L113](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L113) |
| `Arrow.ApplyAccent` | [L152](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L152) |
| `Arrow.Ensure` | [L164](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L164) |
| `Arrow.Update` | [L208](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L208) |
| `Arrow.SetOpen` | [L222](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L222) |
| `Arrow.Show` | [L228](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L228) |
| `Arrow.Hide` | [L250](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L250) |
| `Arrow.RefreshAll` | [L265](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L265) |

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
| `Popup.CloseReagentRestockEdit` | [L297](../../ExtraButtonSystem/FlyoutEngine/Popup.lua#L297) |
| `Popup.Ensure` | [L984](../../ExtraButtonSystem/FlyoutEngine/Popup.lua#L984) |
| `Popup.Place` | [L999](../../ExtraButtonSystem/FlyoutEngine/Popup.lua#L999) |
| `Popup.Layout` | [L1037](../../ExtraButtonSystem/FlyoutEngine/Popup.lua#L1037) |

### ExtraButtonSystem/FlyoutEngine/Secure.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Secure.HandlerOnLoad` | [L98](../../ExtraButtonSystem/FlyoutEngine/Secure.lua#L98) |
| `Secure.SetVisibilityParent` | [L104](../../ExtraButtonSystem/FlyoutEngine/Secure.lua#L104) |
| `Secure.InstallOpener` | [L123](../../ExtraButtonSystem/FlyoutEngine/Secure.lua#L123) |
| `Secure.InstallKidClose` | [L176](../../ExtraButtonSystem/FlyoutEngine/Secure.lua#L176) |

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
| `Timer.After` | [L317](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L317) |
| `Module.GetData` | [L427](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L427) |
| `Module.GetActivePreset` | [L432](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L432) |
| `Module.IsChronoboonFeatureEnabled` | [L545](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L545) |
| `Module.GetDefaultChronoboonItemID` | [L549](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L549) |
| `Module.GetDefaultSuperChronoboonItemID` | [L556](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L556) |
| `Module.EnsureChronoboonPresetEntry` | [L599](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L599) |
| `Module.GetConfigItems` | [L723](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L723) |
| `Module.SetConfigItems` | [L734](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L734) |
| `Module.GetItems` | [L752](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L752) |
| `Module.GetRefreshThreshold` | [L797](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L797) |
| `Module.GetRefreshTimerInfo` | [L804](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L804) |
| `Module.SetRefreshThreshold` | [L827](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L827) |
| `Module.SetItems` | [L834](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L834) |
| `Module.AddItem` | [L844](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L844) |
| `Module.RemoveItem` | [L869](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L869) |
| `Module.RemoveItemAtIndex` | [L888](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L888) |
| `Module.MoveItem` | [L903](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L903) |
| `Module.AddItemAtIndex` | [L916](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L916) |
| `Module.SetActivePreset` | [L940](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L940) |
| `Module.CreatePreset` | [L951](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L951) |
| `Module.DeletePreset` | [L967](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L967) |
| `Module.GetPresetNames` | [L987](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L987) |
| `Module.GetCanonicalChronoboonID` | [L1090](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1090) |
| `Module.GetChronoboonRestockTarget` | [L1095](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1095) |
| `Module.SetChronoboonRestockTarget` | [L1143](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1143) |
| `Module.GetPresetRestockTarget` | [L1183](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1183) |
| `Module.SetPresetRestockTarget` | [L1206](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1206) |
| `Module.GetRestockUIItemIDs` | [L1258](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1258) |
| `Module.IsRestockUIItem` | [L1286](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1286) |
| `Module.GetItemChargeCount` | [L1300](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1300) |
| `Module.GetPhysicalItemCount` | [L1478](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1478) |
| `Module.GetItemCount` | [L1504](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1504) |
| `Module.IsChronoboonName` | [L1749](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1749) |
| `Module.ClassifyChronoboon` | [L1754](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1754) |
| `Module.NoteChronoboonVariant` | [L1786](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1786) |
| `Module.GetRegularChronoboonVariantIDs` | [L2005](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2005) |
| `Module.CollectChronoboonIDs` | [L2025](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2025) |
| `Module.GetChronoboonBagCount` | [L2061](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2061) |
| `Module.GetChronoboonBankCount` | [L2068](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2068) |
| `Module.FindChronoboonBankSlotStacks` | [L2080](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2080) |
| `Module.ResolveMerchantRegularChronoboon` | [L2117](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2117) |
| `Module.ReadChronoboonRestockTargetCombined` | [L2143](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2143) |
| `Module.IsChronoboonItem` | [L2174](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2174) |
| `Module.IsSuperchargedChronoboonItem` | [L2187](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2187) |
| `Module.HasSuperchargedChronoboonBuff` | [L2199](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2199) |
| `Module.HasSuperchargedChronoboonInBags` | [L2262](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2262) |
| `Module.HasWorldBuff` | [L2286](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2286) |
| `Module.GetWorldBuffCount` | [L2292](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2292) |
| `Module.FindChronoboonItemIDs` | [L2353](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2353) |
| `Module.GetGroundAuraBinding` | [L2475](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2475) |
| `Module.SetGroundAuraBinding` | [L2489](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2489) |
| `Module.ClearGroundAuraBinding` | [L2503](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2503) |
| `Module.IsGroundAuraLearnerArmed` | [L2518](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2518) |
| `Module.IsGroundPlaceableItem` | [L2541](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2541) |
| `Module.FindBuffBySpellID` | [L2573](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2573) |
| `Module.TryProcessGroundAuraLearner` | [L2739](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2739) |
| `Module.OnGroundPlaceableCastSucceeded` | [L2794](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2794) |
| `Module.ItemGrantsWellFed` | [L2829](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2829) |
| `Module.FindWellFedBuff` | [L2871](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2871) |
| `Module.FindBuffForItem` | [L2988](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L2988) |
| `Module.GetWeaponEnchantTargetRule` | [L3361](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3361) |
| `Module.GetConsumableDescription` | [L3396](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3396) |
| `Module.IsWeaponEnchantItem` | [L3427](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3427) |
| `Module.CanEnchantApplyToSlot` | [L3474](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3474) |
| `Module.GetWeaponEnchantSlot` | [L3544](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3544) |
| `Module.FindPreferredBagSlot` | [L3783](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3783) |
| `Module.GetWeaponEnchantSlotWithLowestCharges` | [L3828](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3828) |
| `Module.GetBagSlotWithLowestStack` | [L3832](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3832) |
| `Module.IsItemEligible` | [L3901](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3901) |
| `Module.GetFirstEligibleItem` | [L3988](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L3988) |
| `Module.GetEligibleRegularChronoboonItemID` | [L4029](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4029) |
| `Module.GetChronoboonModifierOverrideChronoID` | [L4043](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4043) |
| `Module.RefreshConsumablesUsability` | [L4058](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4058) |
| `Module.RebindPreferredUseSlot` | [L4237](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4237) |
| `Module.ApplyConsumablesChronoboonModifierVisual` | [L4338](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4338) |
| `Module.ApplyChronoboonModifierLayer` | [L4387](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4387) |
| `Module.ClearChronoboonModifierLayer` | [L4422](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4422) |
| `Module.CheckWispLockState` | [L4442](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4442) |
| `Module.UseNextConsumable` | [L4519](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4519) |
| `Module.UpdateWispLockCooldown` | [L4728](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4728) |
| `Module.SetupRightClickConfig` | [L4779](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4779) |
| `falsebtn.UpdateTextCount` | [L4916](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L4916) |
| `Module.RefreshAuraTimerOverlay` | [L5086](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5086) |
| `Module.UpdateBuffCooldown` | [L5100](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5100) |
| `Module.ApplyPendingChanges` | [L5109](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5109) |
| `Module.UpdateButtonState` | [L5132](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5132) |
| `Module.Register` | [L5442](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5442) |
| `Module.CreateButton` | [L5470](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5470) |
| `truebtn.UpdateUsable` | [L5495](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5495) |
| `btn.SetActionbtn.SetAction` | [L5517](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5517) |
| `btn.ClearActionbtn.ClearAction` | [L5529](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5529) |
| `btn.UpdateTexturebtn.UpdateTexture` | [L5540](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5540) |
| `btn.FullRefreshbtn.FullRefresh` | [L5592](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5592) |
| `btn.UpdateAppearancebtn.UpdateAppearance` | [L5648](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5648) |
| `btn.UpdateTextCountbtn.UpdateTextCount` | [L5700](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5700) |
| `btn.UpdateCooldownbtn.UpdateCooldown` | [L5716](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5716) |
| `Module.SetupClickHandling` | [L5755](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5755) |
| `Module.SetupTooltip` | [L5935](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5935) |
| `Module.ShowTooltip` | [L5996](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L5996) |
| `Module.RefreshTooltip` | [L6205](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6205) |
| `Module.UpdateWeaponEnchantButton` | [L6217](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6217) |
| `Module.RunPostLoginConsumablesRefresh` | [L6251](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6251) |
| `Module.SeedConsumableAuraWatchSig` | [L6321](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6321) |
| `Module.RegisterEvents` | [L6327](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6327) |
| `Module._BuffWatchNeeded` | [L6404](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6404) |
| `Module._StopBuffCheckTicker` | [L6422](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6422) |
| `Module._StartBuffCheckTicker` | [L6429](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6429) |
| `Module._SyncBuffCheckTicker` | [L6436](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6436) |
| `Module.ForceUpdate` | [L6848](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6848) |
| `Module.GetButton` | [L6854](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6854) |
| `Module.UpdateKeybindings` | [L6868](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6868) |
| `Module.ClearKeybindings` | [L6897](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6897) |
| `FluxNCConsumables_OpenConfig` | [L6907](../../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L6907) |

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
| `Config.RefreshUI` | [L702](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L702) |
| `Config.UpdateIconCooldown` | [L732](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L732) |
| `Config.UpdateAllCooldowns` | [L738](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L738) |
| `Config.UpdateThresholdDisplay` | [L745](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L745) |
| `Config.ApplyThresholdChange` | [L766](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L766) |
| `Config.UpdateAllItemCounts` | [L795](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L795) |
| `Config.HandleItemDrop` | [L806](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L806) |
| `Config.AddItem` | [L816](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L816) |
| `Config.PromptNewPreset` | [L850](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L850) |
| `Config.ConfirmDeletePreset` | [L910](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L910) |
| `Config.Show` | [L955](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L955) |
| `Config.ShowChronoboonRestockFlyout` | [L1006](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1006) |
| `Config.Hide` | [L1050](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1050) |
| `Config.Toggle` | [L1076](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1076) |
| `Config.IsShown` | [L1088](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1088) |
| `Config.StartUpdateTicker` | [L1097](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1097) |
| `Config.StopUpdateTicker` | [L1127](../../ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua#L1127) |

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
| `Module.GetBestVendorMount` | [L850](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L850) |
| `Module.GetMountConfig` | [L882](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L882) |
| `Module.GetGroundMount` | [L970](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L970) |
| `Module.GetFlyingMount` | [L979](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L979) |
| `Module.GetMode` | [L992](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L992) |
| `Module.SetMode` | [L1020](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1020) |
| `Module.ToggleMode` | [L1060](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1060) |
| `Module.LockToMount` | [L1156](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1156) |
| `Module.Unlock` | [L1178](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1178) |
| `Module.IsLocked` | [L1213](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1213) |
| `Module.GetLockedMount` | [L1218](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1218) |
| `Module.UpdateLockedState` | [L1223](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1223) |
| `Module.GetMountForCurrentModifiers` | [L1300](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1300) |
| `Module.CastSmartMount` | [L1416](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1416) |
| `Module.BuildSmartMountMacro` | [L1438](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1438) |
| `Module.HasBrutosaur` | [L1507](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1507) |
| `Module.HasYak` | [L1513](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1513) |
| `Module.GetBrutosaur` | [L1520](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1520) |
| `Module.GetYak` | [L1526](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1526) |
| `Module.BuildVendorMountMacro` | [L1534](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1534) |
| `Module.GetCurrentMacro` | [L1562](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1562) |
| `Module.CanDisplayMountButton` | [L1638](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1638) |
| `Module.Register` | [L1772](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1772) |
| `Module.CreateButton` | [L1887](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1887) |
| `falsebtn.UpdateUsable` | [L1928](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L1928) |
| `Module.UpdateHotkeyText` | [L2047](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2047) |
| `Module.UpdateMountKeybinding` | [L2055](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2055) |
| `Module.ClearMountKeybinding` | [L2082](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2082) |
| `Module.SetupRightClick` | [L2091](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2091) |
| `Module.SetupMiddleClick` | [L2117](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2117) |
| `Module.SetupPreClick` | [L2142](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2142) |
| `Module.SetupTooltip` | [L2721](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2721) |
| `Module.RefreshTooltip` | [L2760](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2760) |
| `Module.GetCurrentScope` | [L2771](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2771) |
| `Module.UpdateButtonScope` | [L2787](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2787) |
| `Module.GetOppositeMountModeIconForBindingGhost` | [L2874](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2874) |
| `Module.UpdateTexture` | [L2883](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2883) |
| `Module.Update` | [L2954](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L2954) |
| `Module.GetMountItemId` | [L3892](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3892) |
| `Module.GetBagMountItems` | [L3900](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3900) |
| `Module.BuildMountItemFlyoutActions` | [L3907](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3907) |
| `Module.OnMountPickedFromFlyout` | [L3914](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3914) |
| `Module.ShowMountItemFlyout` | [L3920](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3920) |
| `Module.RefreshFlyoutIfOpen` | [L3926](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3926) |
| `Module.RegisterForFavorites` | [L3932](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3932) |
| `Module.GetBagMountItemsSet` | [L3945](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3945) |
| `Module.GetBestAvailableMount` | [L3952](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3952) |
| `Module.GetAvailableFavorites` | [L3959](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3959) |
| `Module.GetFavoriteMount` | [L3966](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3966) |
| `Module.BuildModifierActions` | [L3992](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L3992) |
| `Module.BuildBagMountMacro` | [L4050](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4050) |
| `btn.WIcon.SetTexturebtn.WIcon.SetTexture` | [L4183](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4183) |
| `Module.UpdateJournalMountIcon` | [L4241](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4241) |
| `Module.UpdateBagMountIcon` | [L4262](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4262) |
| `Module.SetupBagMountButton` | [L4382](../../ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua#L4382) |

### ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Coll.HasMountJournalAPI` | [L47](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L47) |
| `Coll.HasCompanionAPI` | [L54](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L54) |
| `Coll.HasMountUI` | [L59](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L59) |
| `Coll.InvalidateCollectedMountMap` | [L71](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L71) |
| `Coll.GetCollectedMountByName` | [L134](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L134) |
| `Coll.HasAnyVendorMount` | [L169](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L169) |
| `Coll.HasBrutosaur` | [L173](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L173) |
| `Coll.HasYak` | [L177](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L177) |
| `Coll.GetBestVendorMount` | [L181](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L181) |
| `Coll.GetBrutosaur` | [L191](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L191) |
| `Coll.GetYak` | [L195](../../ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua#L195) |

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
| `Module.GetVendorOptionReagentSummary` | [L428](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L428) |
| `Module.GetKnownTeleportSpells` | [L571](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L571) |
| `Module.GetKnownPortalSpells` | [L612](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L612) |
| `Module.HasAnyTeleportSpell` | [L651](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L651) |
| `Module.HasAnyPortalSpell` | [L657](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L657) |
| `Module.HasAnyTeleportOrPortalSpell` | [L663](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L663) |
| `Module.InvalidateCache` | [L677](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L677) |
| `Module.GetFirstKnownSpell` | [L686](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L686) |
| `Module.GetMode` | [L705](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L705) |
| `Module.SetMode` | [L730](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L730) |
| `Module.ToggleMode` | [L757](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L757) |
| `Module.ClearCheckedVisual` | [L809](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L809) |
| `Module.ClearCheckedVisualNow` | [L845](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L845) |
| `Module.RefreshFlyoutIfOpen` | [L878](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L878) |
| `Module.LockToSpell` | [L916](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L916) |
| `Module.Unlock` | [L956](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L956) |
| `Module.IsLocked` | [L1005](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1005) |
| `Module.UpdateLockedState` | [L1010](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1010) |
| `Module.BuildReagentActions` | [L1110](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1110) |
| `Module.GetRestockTarget` | [L1157](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1157) |
| `Module.SetRestockTarget` | [L1173](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1173) |
| `Module.UpdateReagentButtonDisplay` | [L1191](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1191) |
| `Module.UpdateReagentButtonCountText` | [L1213](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1213) |
| `Module.ShowReagentButtonCount` | [L1232](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1232) |
| `Module.BuildFlyoutActions` | [L1246](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1246) |
| `Module.CountVisibleTeleportDestinations` | [L1295](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1295) |
| `Module.HasTeleportFlyout` | [L1308](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1308) |
| `Module.SyncFlyoutEngine` | [L1358](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1358) |
| `Module.ShowFlyout` | [L1388](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1388) |
| `Module.HookFlyoutButtons` | [L1428](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1428) |
| `Module.BuildConditionalCastLine` | [L1476](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1476) |
| `Module.BuildFlyoutMacro` | [L1529](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1529) |
| `Module.Register` | [L1568](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1568) |
| `Module.EnsureButtonForBindingMode` | [L1594](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1594) |
| `Module.CreateButton` | [L1607](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1607) |
| `btn.UpdateUsable` | [L1718](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1718) |
| `endendbtn.UpdateTextCount` | [L1745](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1745) |
| `Module.ApplyMacro` | [L1789](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1789) |
| `Module.SetupIconProtection` | [L1827](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1827) |
| `btn.WIcon.SetTexturebtn.WIcon.SetTexture` | [L1836](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1836) |
| `icon.SetTextureicon.SetTexture` | [L1856](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1856) |
| `Module.GetRightClickReagentItemID` | [L1875](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1875) |
| `Module.SetupClickHandlers` | [L1893](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1893) |
| `Module.SetupMiddleClick` | [L1966](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1966) |
| `Module.SetupRightClick` | [L1970](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1970) |
| `Module.SetupPreClick` | [L1975](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L1975) |
| `Module.SetupTooltip` | [L2090](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2090) |
| `Module.ShowTooltip` | [L2148](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2148) |
| `Module.RefreshTooltip` | [L2286](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2286) |
| `Module.GetSpellForModifier` | [L2299](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2299) |
| `Module.GetOppositeModeDisplaySpell` | [L2387](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2387) |
| `Module.UpdateIcon` | [L2523](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2523) |
| `Module.UpdateTexture` | [L2581](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2581) |
| `Module.UpdateFlyoutArrow` | [L2641](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2641) |
| `Module.Update` | [L2661](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2661) |
| `Module.UpdateTeleportKeybinding` | [L2801](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2801) |
| `Module.ClearTeleportKeybinding` | [L2834](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2834) |
| `Module.UpdateHotkeyText` | [L2844](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L2844) |
| `Module.IsTeleportOrPortalSpell` | [L3105](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L3105) |
| `Module.RefreshReagentCounts` | [L3144](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L3144) |
| `Module.RefreshAllReagentDisplays` | [L3166](../../ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua#L3166) |

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
| `Config.GetVendorMountTexture` | [L557](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L557) |
| `Config.HasAnyVendorMount` | [L569](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L569) |
| `Config.GetMountIconTexture` | [L577](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L577) |
| `Config.OpenMountJournal` | [L649](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L649) |
| `Config.CreateMountConfigUI` | [L673](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L673) |
| `configFrame:UpdateDisplay` | [L884](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L884) |
| `Config.DebugPrint` | [L1039](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L1039) |

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
| `Manager.BuildMacroText` | [L188](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L188) |
| `Manager.UpdateHotkeys` | [L600](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L600) |
| `Manager.UpdateButton` | [L696](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L696) |
| `btn.UpdateChecked` | [L866](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L866) |
| `Manager.EnsureButtons` | [L872](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L872) |
| `Manager.ShouldShowEmptySlots` | [L959](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L959) |
| `Manager.UpdateVisibility` | [L970](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L970) |
| `Manager._DoUpdateAllSlots` | [L1003](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1003) |
| `Manager.UpdateAllSlots` | [L1057](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1057) |
| `Manager.UpdateBindings` | [L1095](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1095) |
| `ManagerA.OnSlotsChanged` | [L1416](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1416) |

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
| `GridUI.CreateCellEditBox` | [L776](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L776) |
| `GridUI.SetupCellChrome` | [L790](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L790) |
| `GridUI.RefreshConsumableCell` | [L891](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L891) |
| `GridUI.CreateConsumableCell` | [L930](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L930) |
| `GridUI.RebuildConfigHost` | [L1247](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L1247) |
| `GridUI.RefreshAllCells` | [L1323](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L1323) |
| `GridUI.UpdateAllCooldowns` | [L1339](../../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua#L1339) |

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
| `TM.WidgetForTrinketBind` | [L647](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L647) |
| `TM.SyncKeybindPushWatch` | [L795](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L795) |
| `TM.HookTrinketClickScripts` | [L906](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L906) |
| `TM.SyncEquippedFace` | [L940](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L940) |
| `TM.CreateTrinketButton` | [L971](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L971) |
| `btn.UpdateUsable` | [L1059](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1059) |
| `endbtn.UpdateEquipped` | [L1063](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1063) |
| `btn.Widget.UpdateTooltip` | [L1072](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1072) |
| `button.UpdateUsable` | [L1163](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1163) |
| `endbutton.UpdateEquipped` | [L1166](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1166) |
| `TM.CreateFlyoutArrow` | [L1225](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1225) |
| `TM.UpdateArrowRotation` | [L1245](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1245) |
| `TM.UpdateArrowVisibility` | [L1259](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1259) |
| `TM.SetupButtonScripts` | [L1331](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1331) |
| `TM.OnTrinketClick` | [L1359](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1359) |
| `TM.ShowTrinketTooltip` | [L1381](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1381) |
| `TM.RestoreTrinketIconColor` | [L1414](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1414) |
| `TM.RestoreTrinketBorderColor` | [L1426](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1426) |
| `TM.HideEquippedGreenBorder` | [L1445](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1445) |
| `TM.EnsureUsabilityTextureRefs` | [L1466](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1466) |
| `TM.ApplyTrinketUsability` | [L1488](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1488) |
| `TM.ApplyMenuTrinketUsability` | [L1547](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1547) |
| `TM.UpdateTrinketButton` | [L1556](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1556) |
| `TM.UpdateTrinketCooldown` | [L1592](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1592) |
| `TM.UpdateAllTrinkets` | [L1626](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1626) |
| `TM.UpdateAllCooldowns` | [L1633](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1633) |
| `TM.UpdateAllUsability` | [L1641](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1641) |
| `TM.CreateMenuFrame` | [L1652](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1652) |
| `TM.ScanBagsForTrinkets` | [L1685](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1685) |
| `TM.SyncFlyoutEngine` | [L1802](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1802) |
| `TM.BuildMenu` | [L1870](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1870) |
| `TM.UpdateMenuButtonCooldown` | [L1895](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1895) |
| `TM.OnMenuTrinketClick` | [L1906](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1906) |
| `TM.ShowMenuTrinketTooltip` | [L1939](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1939) |
| `TM.StartMenuMouseoverTimer` | [L1972](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1972) |
| `TM.QueueTrinketSwap` | [L2020](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2020) |
| `TM.ProcessCombatQueue` | [L2040](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2040) |
| `TM.EquipTrinket` | [L2056](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2056) |
| `TM.UpdateQueueVisuals` | [L2100](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2100) |
| `TM.UpdateKeybindings` | [L2109](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2109) |
| `TM.Show` | [L2225](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2225) |
| `TM.Hide` | [L2241](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2241) |
| `TM.Toggle` | [L2267](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2267) |
| `TM.HasEquippedTrinkets` | [L2284](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2284) |
| `TM.GetEquippedTrinketSlots` | [L2289](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2289) |
| `TM.GetTrinketVisibilityState` | [L2301](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2301) |
| `TM.UpdateTrinketVisibility` | [L2318](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2318) |
| `FluxTrinketMenu_ApplyAppearanceAccent` | [L2503](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2503) |

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
| `FluxDefaultSettings.GetMinUIScale` | [L433](../../FluxDefaultSettings.lua#L433) |
| `FluxDefaultSettings.IsUIScaleAtOrBelowMin` | [L438](../../FluxDefaultSettings.lua#L438) |
| `FluxUILayoutSqueeze.SetLastHorizontalSqueezeFactor` | [L456](../../FluxDefaultSettings.lua#L456) |
| `FluxUILayoutSqueeze.GetHorizontalSqueezeFactor` | [L466](../../FluxDefaultSettings.lua#L466) |
| `FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor` | [L474](../../FluxDefaultSettings.lua#L474) |
| `FluxUILayoutSqueeze.GetDependentsHorizontalSqueezeFactor` | [L481](../../FluxDefaultSettings.lua#L481) |
| `FluxUILayoutSqueeze.GetWidgetHorizontalSqueezeFactor` | [L486](../../FluxDefaultSettings.lua#L486) |
| `FluxUILayoutSqueeze.GetDynamicScaleTargets` | [L520](../../FluxDefaultSettings.lua#L520) |
| `FluxUILayoutSqueeze.GetDynamicScaleTargetsEmulated` | [L587](../../FluxDefaultSettings.lua#L587) |
| `FluxUILayoutSqueeze.GetDependentsHorizontalSqueezeFactorFromBarX` | [L652](../../FluxDefaultSettings.lua#L652) |
| `FluxUILayoutSqueeze.GetUnitFrameIndependentScaleTargets` | [L663](../../FluxDefaultSettings.lua#L663) |
| `FluxUILayoutSqueeze.ClampUnitFrameIndependentXSqueeze` | [L707](../../FluxDefaultSettings.lua#L707) |
| `FluxUILayoutSqueeze.ComputeEmulatedFullMainBarSqueezeFactors` | [L731](../../FluxDefaultSettings.lua#L731) |
| `FluxUILayoutSqueeze.GetEmulatedDependentCacheKey` | [L786](../../FluxDefaultSettings.lua#L786) |
| `FluxUILayoutSqueeze.InvalidateEmulatedDependentCache` | [L793](../../FluxDefaultSettings.lua#L793) |
| `FluxUILayoutSqueeze.GetCachedEmulatedDependentXFactorForUnitFrames` | [L799](../../FluxDefaultSettings.lua#L799) |
| `FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames` | [L815](../../FluxDefaultSettings.lua#L815) |
| `FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactor` | [L824](../../FluxDefaultSettings.lua#L824) |
| `FluxUILayoutSqueeze.ComputeVisibleContentWidth` | [L847](../../FluxDefaultSettings.lua#L847) |
| `FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactorForRow` | [L854](../../FluxDefaultSettings.lua#L854) |
| `FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactorForFrame` | [L878](../../FluxDefaultSettings.lua#L878) |
| `FluxUILayoutSqueeze.NotifyLayoutDependents` | [L894](../../FluxDefaultSettings.lua#L894) |
| `FluxUILayoutSqueeze.EnsureDisplayRefreshHooks` | [L990](../../FluxDefaultSettings.lua#L990) |
| `FluxUILayoutSqueeze.RequestRefresh` | [L1006](../../FluxDefaultSettings.lua#L1006) |
| `FluxDefaultSettings.GetState` | [L1054](../../FluxDefaultSettings.lua#L1054) |
| `FluxDefaultSettings.ApplyNameplateScalarDefaults` | [L1232](../../FluxDefaultSettings.lua#L1232) |
| `FluxDefaultSettings.ApplyNameplateClassColorDefault` | [L1236](../../FluxDefaultSettings.lua#L1236) |
| `FluxDefaultSettings.ApplyNameplateNpcNameDefaults` | [L1240](../../FluxDefaultSettings.lua#L1240) |
| `FluxDefaultSettings.ApplyNameplateBitfieldDefaults` | [L1244](../../FluxDefaultSettings.lua#L1244) |
| `FluxDefaultSettings.ApplyNameplateDefaultsPack` | [L1248](../../FluxDefaultSettings.lua#L1248) |
| `FluxDefaultSettings.ScheduleNameplateDefaultsPack` | [L1252](../../FluxDefaultSettings.lua#L1252) |
| `FluxDefaultSettings.ApplySpecialCVarSettings` | [L1272](../../FluxDefaultSettings.lua#L1272) |
| `FluxDefaultSettings.ApplyRaidFrameSettings` | [L1309](../../FluxDefaultSettings.lua#L1309) |
| `FluxDefaultSettings.EnsureNameplateSizeMedium` | [L1314](../../FluxDefaultSettings.lua#L1314) |
| `FluxDefaultSettings.ScheduleRaidArenaFrameDefaultsPack` | [L1331](../../FluxDefaultSettings.lua#L1331) |
| `FluxDefaultSettings.ApplyRaidArenaFrameDefaultsPackNow` | [L1335](../../FluxDefaultSettings.lua#L1335) |
| `FluxDefaultSettings.ApplyRaidArenaFrameDefaultsPack` | [L1339](../../FluxDefaultSettings.lua#L1339) |
| `FluxDefaultSettings.ApplyInterfaceDefaultsPack` | [L1345](../../FluxDefaultSettings.lua#L1345) |
| `FluxDefaultSettings.ApplyStickyTargetingOff` | [L1353](../../FluxDefaultSettings.lua#L1353) |
| `FluxDefaultSettings.GetMaxCameraDistanceZoomFactor` | [L1384](../../FluxDefaultSettings.lua#L1384) |
| `FluxDefaultSettings.ApplyMaxCameraDistance` | [L1407](../../FluxDefaultSettings.lua#L1407) |
| `FluxDefaultSettings.ApplyControlsDefaultsPack` | [L1438](../../FluxDefaultSettings.lua#L1438) |
| `FluxDefaultSettings.ApplyChatSettings` | [L1518](../../FluxDefaultSettings.lua#L1518) |
| `FluxDefaultSettings.ApplySelfCastAndFocusCastDefaults` | [L1564](../../FluxDefaultSettings.lua#L1564) |
| `FluxDefaultSettings.ApplyCombatDefaultsPack` | [L1569](../../FluxDefaultSettings.lua#L1569) |
| `FluxDefaultSettings.ApplyActionBarDefaultsPack` | [L1697](../../FluxDefaultSettings.lua#L1697) |
| `FluxDefaultSettings.ShouldSuppressBindingRefresh` | [L1789](../../FluxDefaultSettings.lua#L1789) |
| `FluxDefaultSettings.FlushBindingRefreshAfterBulk` | [L1804](../../FluxDefaultSettings.lua#L1804) |
| `FluxDefaultSettings.SavePendingModifiedClicks` | [L1885](../../FluxDefaultSettings.lua#L1885) |
| `FluxDefaultSettings.ApplyKeybinds` | [L1936](../../FluxDefaultSettings.lua#L1936) |
| `FluxDefaultSettings.PrepareAccountBindingBootstrap` | [L2208](../../FluxDefaultSettings.lua#L2208) |
| `FluxDefaultSettings.EnsureDefaultFluxBindings` | [L2273](../../FluxDefaultSettings.lua#L2273) |
| `FluxDefaultSettings.ReassertSoftTargetEnemyFromDefaults` | [L2320](../../FluxDefaultSettings.lua#L2320) |
| `FluxDefaultSettings.ScheduleSoftTargetEnemyReassertFromDefaults` | [L2349](../../FluxDefaultSettings.lua#L2349) |
| `FluxDefaultSettings.SyncSettingsRegistryProxies` | [L2358](../../FluxDefaultSettings.lua#L2358) |
| `FluxDefaultSettings.ApplyCharacterFirstLogin` | [L2394](../../FluxDefaultSettings.lua#L2394) |
| `FluxDefaultSettings.VerifyInitialNonBindingDefaults` | [L2428](../../FluxDefaultSettings.lua#L2428) |
| `FluxDefaultSettings.VerifyPostLoginDefaults` | [L2514](../../FluxDefaultSettings.lua#L2514) |
| `FluxDefaultSettings.Apply` | [L2567](../../FluxDefaultSettings.lua#L2567) |
| `FluxDefaultSettings.ApplyCVarsOnly` | [L2848](../../FluxDefaultSettings.lua#L2848) |
| `FluxDefaultSettings.PrintDebug` | [L3291](../../FluxDefaultSettings.lua#L3291) |

### Inventory/Builtin/AuctionPurchases.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `P.TrackRestock` | [L35](../../Inventory/Builtin/AuctionPurchases.lua#L35) |
| `P.FinishRestock` | [L44](../../Inventory/Builtin/AuctionPurchases.lua#L44) |
| `P.AbortRestock` | [L45](../../Inventory/Builtin/AuctionPurchases.lua#L45) |
| `P.ConsumeFailure` | [L51](../../Inventory/Builtin/AuctionPurchases.lua#L51) |
| `P.Start` | [L88](../../Inventory/Builtin/AuctionPurchases.lua#L88) |

### Inventory/Builtin/Auctions.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Auctions.Refresh` | [L200](../../Inventory/Builtin/Auctions.lua#L200) |
| `Auctions.Start` | [L219](../../Inventory/Builtin/Auctions.lua#L219) |

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
| `Bank.IsOpen` | [L44](../../Inventory/Builtin/Bank.lua#L44) |
| `Bank.SetOpen` | [L48](../../Inventory/Builtin/Bank.lua#L48) |
| `Bank.MarkDirty` | [L63](../../Inventory/Builtin/Bank.lua#L63) |
| `Bank.Invalidate` | [L85](../../Inventory/Builtin/Bank.lua#L85) |
| `Bank.Refresh` | [L206](../../Inventory/Builtin/Bank.lua#L206) |
| `Bank.GetLastChangeKind` | [L242](../../Inventory/Builtin/Bank.lua#L242) |
| `Bank.GetLastAddedItemIDs` | [L246](../../Inventory/Builtin/Bank.lua#L246) |
| `Bank.GetLastRemovedItemIDs` | [L250](../../Inventory/Builtin/Bank.lua#L250) |
| `Bank.GetLastRefreshedDirtyBags` | [L254](../../Inventory/Builtin/Bank.lua#L254) |
| `Bank.ScanOpenContainers` | [L259](../../Inventory/Builtin/Bank.lua#L259) |

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
| `EnsureEdgeStrips` | [L108](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L108) |
| `frame:SetPortraitToAsset` | [L187](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L187) |
| `frame:SetTitle` | [L218](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L218) |
| `slotRow:Layout` | [L1295](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L1295) |
| `combined:EnumerateValidItems` | [L1729](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L1729) |
| `end_G.FluxRefreshInBagSlots` | [L1891](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L1891) |
| `ToggleAllBags` | [L2017](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2017) |
| `ToggleBackpack` | [L2029](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2029) |
| `ToggleBag` | [L2041](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2041) |
| `OpenBag` | [L2053](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2053) |
| `OpenBackpack` | [L2063](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2063) |
| `OpenAllBags` | [L2072](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2072) |
| `CloseAllBags` | [L2090](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2090) |
| `bar.Layoutbar.Layout` | [L2133](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2133) |
| `hidden:Layout` | [L2222](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2222) |
| `bar.Layoutbar.Layout` | [L2237](../../Inventory/Builtin/FluxClassicCombinedBag.lua#L2237) |

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
| `Mail.GetPredictedCount` | [L111](../../Inventory/Builtin/Mail.lua#L111) |
| `Mail.RecordAuctionDelivery` | [L120](../../Inventory/Builtin/Mail.lua#L120) |
| `Mail.IsOpen` | [L187](../../Inventory/Builtin/Mail.lua#L187) |
| `Mail.Refresh` | [L290](../../Inventory/Builtin/Mail.lua#L290) |
| `Mail.Start` | [L358](../../Inventory/Builtin/Mail.lua#L358) |

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
| `C.ReadSlot` | [L625](../../Inventory/Containers.lua#L625) |
| `C.PatchSlots` | [L653](../../Inventory/Containers.lua#L653) |
| `C.ScanBag` | [L687](../../Inventory/Containers.lua#L687) |
| `C.CountsFromByBag` | [L725](../../Inventory/Containers.lua#L725) |
| `C.DiffSlots` | [L749](../../Inventory/Containers.lua#L749) |
| `C.ChangedFromDelta` | [L772](../../Inventory/Containers.lua#L772) |
| `C.NewItemSetLog` | [L794](../../Inventory/Containers.lua#L794) |
| `C.NoteItemSets` | [L799](../../Inventory/Containers.lua#L799) |
| `C.TakeItemSets` | [L814](../../Inventory/Containers.lua#L814) |

### Inventory/Craft.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Craft.GetCraftableCount` | [L175](../../Inventory/Craft.lua#L175) |
| `Craft.HasProfessionForKind` | [L323](../../Inventory/Craft.lua#L323) |
| `Craft.GetOutputPerCraft` | [L542](../../Inventory/Craft.lua#L542) |
| `Craft.ListRecipesForKind` | [L557](../../Inventory/Craft.lua#L557) |
| `Craft.InvalidateCanCraftCache` | [L644](../../Inventory/Craft.lua#L644) |
| `Craft.BagChangesAffectKind` | [L650](../../Inventory/Craft.lua#L650) |
| `Craft.GetBestCraftable` | [L663](../../Inventory/Craft.lua#L663) |
| `Craft.CanCraftKind` | [L712](../../Inventory/Craft.lua#L712) |
| `Craft.GetBandageProfessionSpellName` | [L755](../../Inventory/Craft.lua#L755) |
| `Craft.ClearPendingCraft` | [L845](../../Inventory/Craft.lua#L845) |
| `Craft.TryFlushPendingCraft` | [L939](../../Inventory/Craft.lua#L939) |
| `Craft.ExecuteCraft` | [L954](../../Inventory/Craft.lua#L954) |
| `Craft.ExecuteHealPotionCraft` | [L1003](../../Inventory/Craft.lua#L1003) |
| `Craft.ExecuteManaPotionCraft` | [L1007](../../Inventory/Craft.lua#L1007) |
| `Craft.ExecuteBandageCraft` | [L1011](../../Inventory/Craft.lua#L1011) |

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
| `Best.GetBestRef` | [L192](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L192) |
| `Best.GetLadder` | [L223](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L223) |
| `Best.GetBestOwned` | [L280](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L280) |
| `Best.GetAllBest` | [L299](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L299) |
| `Best.FindStacks` | [L319](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L319) |
| `Best.Init` | [L435](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L435) |

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
| `Best.EndLoadHold` | [L205](../../Inventory/FluxConsumableBest/Init.lua#L205) |
| `Best.BeginLoadHold` | [L211](../../Inventory/FluxConsumableBest/Init.lua#L211) |
| `Best.ArmPortalSoftHold` | [L229](../../Inventory/FluxConsumableBest/Init.lua#L229) |
| `Best.MergePendingAdded` | [L265](../../Inventory/FluxConsumableBest/Init.lua#L265) |
| `Best.IsConjureArmActive` | [L278](../../Inventory/FluxConsumableBest/Init.lua#L278) |
| `Best.ArmConjureChase` | [L284](../../Inventory/FluxConsumableBest/Init.lua#L284) |
| `Best.IsManaKind` | [L319](../../Inventory/FluxConsumableBest/Init.lua#L319) |
| `Best.IsManaKindRelevant` | [L323](../../Inventory/FluxConsumableBest/Init.lua#L323) |
| `Best.IsValidKind` | [L334](../../Inventory/FluxConsumableBest/Init.lua#L334) |

### Inventory/FluxConsumableBest/Persist.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Persist.GetRoot` | [L24](../../Inventory/FluxConsumableBest/Persist.lua#L24) |
| `Persist.NormalizePotion` | [L28](../../Inventory/FluxConsumableBest/Persist.lua#L28) |
| `Persist.GetRef` | [L43](../../Inventory/FluxConsumableBest/Persist.lua#L43) |
| `Persist.GetAllRefs` | [L68](../../Inventory/FluxConsumableBest/Persist.lua#L68) |
| `Persist.MaybeUpdateRef` | [L74](../../Inventory/FluxConsumableBest/Persist.lua#L74) |
| `Persist.GetVendorSeen` | [L129](../../Inventory/FluxConsumableBest/Persist.lua#L129) |
| `Persist.RememberVendorItem` | [L138](../../Inventory/FluxConsumableBest/Persist.lua#L138) |
| `Persist.GetAllVendorSeen` | [L159](../../Inventory/FluxConsumableBest/Persist.lua#L159) |

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
| `Score.IsExcludedFromBest` | [L313](../../Inventory/FluxConsumableBest/Score.lua#L313) |
| `Score.IsBlockedForBest` | [L332](../../Inventory/FluxConsumableBest/Score.lua#L332) |
| `Score.IsUsableForVendor` | [L369](../../Inventory/FluxConsumableBest/Score.lua#L369) |
| `Score.IsUsable` | [L395](../../Inventory/FluxConsumableBest/Score.lua#L395) |
| `Score.GetMaxStack` | [L453](../../Inventory/FluxConsumableBest/Score.lua#L453) |
| `Score.FoodTier` | [L496](../../Inventory/FluxConsumableBest/Score.lua#L496) |
| `Score.WaterDrinkTier` | [L518](../../Inventory/FluxConsumableBest/Score.lua#L518) |
| `Score.IsBetter` | [L540](../../Inventory/FluxConsumableBest/Score.lua#L540) |

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
| `C.IsManaGemItem` | [L642](../../Inventory/FluxConsumableClassify.lua#L642) |
| `C.IsCombatUtilityPotion` | [L734](../../Inventory/FluxConsumableClassify.lua#L734) |
| `C.IsHealingPotionName` | [L738](../../Inventory/FluxConsumableClassify.lua#L738) |
| `C.IsManaPotionName` | [L742](../../Inventory/FluxConsumableClassify.lua#L742) |
| `C.ParseFoodWaterRestore` | [L770](../../Inventory/FluxConsumableClassify.lua#L770) |
| `C.ResetParseBudget` | [L859](../../Inventory/FluxConsumableClassify.lua#L859) |
| `C.InvalidateCache` | [L868](../../Inventory/FluxConsumableClassify.lua#L868) |
| `C.IsPending` | [L879](../../Inventory/FluxConsumableClassify.lua#L879) |
| `C.IsRejected` | [L886](../../Inventory/FluxConsumableClassify.lua#L886) |
| `C.ForceReject` | [L893](../../Inventory/FluxConsumableClassify.lua#L893) |
| `C.Classify` | [L1110](../../Inventory/FluxConsumableClassify.lua#L1110) |
| `C.ResolveCombatTierAxes` | [L1333](../../Inventory/FluxConsumableClassify.lua#L1333) |
| `FluxNCItemDetection.ParseFoodWaterRestore` | [L1351](../../Inventory/FluxConsumableClassify.lua#L1351) |
| `endFluxNCItemDetection.ItemGrantsWellFed` | [L1356](../../Inventory/FluxConsumableClassify.lua#L1356) |
| `FluxItemDetection.ResolveCombatTierAxes` | [L1384](../../Inventory/FluxConsumableClassify.lua#L1384) |

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
| `IC.GetStatic` | [L88](../../Inventory/FluxItemClass.lua#L88) |
| `IC.RequestLoad` | [L166](../../Inventory/FluxItemClass.lua#L166) |
| `IC.GetInfo` | [L180](../../Inventory/FluxItemClass.lua#L180) |
| `IC.IsLoaded` | [L196](../../Inventory/FluxItemClass.lua#L196) |
| `IC.GetName` | [L200](../../Inventory/FluxItemClass.lua#L200) |
| `IC.GetLink` | [L205](../../Inventory/FluxItemClass.lua#L205) |
| `IC.GetQuality` | [L225](../../Inventory/FluxItemClass.lua#L225) |
| `IC.GetSellPrice` | [L230](../../Inventory/FluxItemClass.lua#L230) |
| `IC.GetStackSize` | [L245](../../Inventory/FluxItemClass.lua#L245) |
| `IC.GetIcon` | [L250](../../Inventory/FluxItemClass.lua#L250) |
| `IC.GetClassID` | [L259](../../Inventory/FluxItemClass.lua#L259) |
| `IC.GetSubClassID` | [L264](../../Inventory/FluxItemClass.lua#L264) |
| `IC.GetEquipLoc` | [L269](../../Inventory/FluxItemClass.lua#L269) |
| `IC.IsEquippable` | [L276](../../Inventory/FluxItemClass.lua#L276) |
| `IC.GetTooltipText` | [L355](../../Inventory/FluxItemClass.lua#L355) |
| `IC.GetRestore` | [L383](../../Inventory/FluxItemClass.lua#L383) |
| `IC.InvalidateRestoreCache` | [L457](../../Inventory/FluxItemClass.lua#L457) |
| `IC.ClassifyConsumable` | [L487](../../Inventory/FluxItemClass.lua#L487) |
| `IC.InvalidateClassification` | [L570](../../Inventory/FluxItemClass.lua#L570) |
| `IC.OnItemDataLoaded` | [L583](../../Inventory/FluxItemClass.lua#L583) |
| `IC.OnItemDataEvent` | [L645](../../Inventory/FluxItemClass.lua#L645) |

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
| `Index.GetCount` | [L58](../../Inventory/Index.lua#L58) |
| `Index.GetLiveCount` | [L103](../../Inventory/Index.lua#L103) |
| `Index.Find` | [L174](../../Inventory/Index.lua#L174) |
| `Index.GetFirst` | [L242](../../Inventory/Index.lua#L242) |
| `Index.GetUniqueItems` | [L290](../../Inventory/Index.lua#L290) |
| `Index.UniqueCount` | [L404](../../Inventory/Index.lua#L404) |
| `Index.ForEachLocation` | [L429](../../Inventory/Index.lua#L429) |
| `Index.GetSnapshotGeneration` | [L516](../../Inventory/Index.lua#L516) |
| `Index.GetFirstFreeBagSlot` | [L523](../../Inventory/Index.lua#L523) |
| `Inv.GetCount` | [L546](../../Inventory/Index.lua#L546) |
| `Inv.GetLiveCount` | [L550](../../Inventory/Index.lua#L550) |
| `Inv.Find` | [L554](../../Inventory/Index.lua#L554) |
| `Inv.GetFirst` | [L558](../../Inventory/Index.lua#L558) |
| `Inv.GetUniqueItems` | [L562](../../Inventory/Index.lua#L562) |
| `Inv.ForEachLocation` | [L566](../../Inventory/Index.lua#L566) |
| `Inv.GetSnapshotGeneration` | [L570](../../Inventory/Index.lua#L570) |
| `Inv.GetFirstFreeBagSlot` | [L574](../../Inventory/Index.lua#L574) |
| `Inv.GetBagGeneration` | [L578](../../Inventory/Index.lua#L578) |

### Inventory/Init.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Inv.LoadPersistedBankCounts` | [L62](../../Inventory/Init.lua#L62) |
| `Inv.PersistBankCounts` | [L85](../../Inventory/Init.lua#L85) |
| `Inv.SnapshotCountKeys` | [L120](../../Inventory/Init.lua#L120) |
| `Inv.ClassifyCountKeys` | [L133](../../Inventory/Init.lua#L133) |
| `Inv.MergeChangeKind` | [L170](../../Inventory/Init.lua#L170) |
| `Inv.IsScanPending` | [L211](../../Inventory/Init.lua#L211) |
| `Inv.RequestItemData` | [L323](../../Inventory/Init.lua#L323) |
| `Inv.PruneItemDataForBag` | [L355](../../Inventory/Init.lua#L355) |
| `Inv.NoteItemDataArrived` | [L394](../../Inventory/Init.lua#L394) |
| `Inv.IsBagStorm` | [L474](../../Inventory/Init.lua#L474) |
| `Inv.NotifyBagStorm` | [L502](../../Inventory/Init.lua#L502) |
| `Inv.EndBagStorm` | [L516](../../Inventory/Init.lua#L516) |
| `Inv.OnStormSettled` | [L524](../../Inventory/Init.lua#L524) |
| `Inv.RegisterStormSettled` | [L539](../../Inventory/Init.lua#L539) |
| `Inv.UnregisterStormSettled` | [L546](../../Inventory/Init.lua#L546) |
| `Inv.SetMerchantOpen` | [L550](../../Inventory/Init.lua#L550) |
| `Inv.IsMerchantOpen` | [L554](../../Inventory/Init.lua#L554) |
| `Inv.SetMailboxOpen` | [L559](../../Inventory/Init.lua#L559) |
| `Inv.IsMailboxOpen` | [L579](../../Inventory/Init.lua#L579) |
| `Inv.ShouldDeferHeavyWork` | [L593](../../Inventory/Init.lua#L593) |
| `Inv.GetLastAddedItemIDs` | [L832](../../Inventory/Init.lua#L832) |
| `Inv.Notify` | [L875](../../Inventory/Init.lua#L875) |
| `Inv.Register` | [L946](../../Inventory/Init.lua#L946) |
| `Inv.Unregister` | [L964](../../Inventory/Init.lua#L964) |
| `Inv.GetListenerInfo` | [L970](../../Inventory/Init.lua#L970) |
| `Inv.GetSource` | [L987](../../Inventory/Init.lua#L987) |
| `Inv.IsReady` | [L991](../../Inventory/Init.lua#L991) |
| `Inv.SnapshotLooksCollapsed` | [L1030](../../Inventory/Init.lua#L1030) |
| `Inv.MarkUnreliable` | [L1043](../../Inventory/Init.lua#L1043) |
| `Inv.BeginLoginHold` | [L1077](../../Inventory/Init.lua#L1077) |
| `Inv.IsLoginHold` | [L1104](../../Inventory/Init.lua#L1104) |
| `Inv.NoteLoginBagsDelayed` | [L1116](../../Inventory/Init.lua#L1116) |
| `Inv.IsReliable` | [L1171](../../Inventory/Init.lua#L1171) |
| `Inv.NoteRefreshSettling` | [L1183](../../Inventory/Init.lua#L1183) |
| `Inv.HasWarband` | [L1247](../../Inventory/Init.lua#L1247) |
| `Inv.IsBaganatorBankViewShown` | [L1327](../../Inventory/Init.lua#L1327) |
| `Inv.IsBaganatorBankLiveShown` | [L1354](../../Inventory/Init.lua#L1354) |
| `Inv.RegisterBankStateListener` | [L1373](../../Inventory/Init.lua#L1373) |
| `Inv.ShouldKeepBankOpen` | [L1409](../../Inventory/Init.lua#L1409) |
| `Inv.SetBankOpenLatch` | [L1413](../../Inventory/Init.lua#L1413) |
| `Inv.SetBaganatorBankLive` | [L1432](../../Inventory/Init.lua#L1432) |
| `Inv.IsBaganatorBankLive` | [L1455](../../Inventory/Init.lua#L1455) |
| `Inv.IsBankLive` | [L1461](../../Inventory/Init.lua#L1461) |
| `Inv.CanTakeFromBank` | [L1483](../../Inventory/Init.lua#L1483) |
| `Inv.IsBankOpen` | [L1502](../../Inventory/Init.lua#L1502) |
| `Inv.PrepareHUD` | [L1563](../../Inventory/Init.lua#L1563) |
| `Inv.Start` | [L1576](../../Inventory/Init.lua#L1576) |

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
| `Prof.GetCharacterKey` | [L189](../../Inventory/Professions.lua#L189) |
| `Prof.GetRecipeLive` | [L699](../../Inventory/Professions.lua#L699) |
| `Prof.GetCompleteness` | [L728](../../Inventory/Professions.lua#L728) |
| `Prof.GetRecipe` | [L766](../../Inventory/Professions.lua#L766) |
| `Prof.GetReagents` | [L796](../../Inventory/Professions.lua#L796) |
| `Prof.GetOutput` | [L801](../../Inventory/Professions.lua#L801) |
| `Prof.IsLearned` | [L809](../../Inventory/Professions.lua#L809) |
| `Prof.ListCachedRecipes` | [L823](../../Inventory/Professions.lua#L823) |
| `Prof.ListSkillKeys` | [L835](../../Inventory/Professions.lua#L835) |
| `Prof.GetSkillInfo` | [L844](../../Inventory/Professions.lua#L844) |
| `Prof.OnProfessionEvent` | [L853](../../Inventory/Professions.lua#L853) |
| `Prof.ListAllCachedRecipes` | [L922](../../Inventory/Professions.lua#L922) |
| `Prof.ListRecipesForOutput` | [L950](../../Inventory/Professions.lua#L950) |
| `Prof.OnProfessionClosed` | [L996](../../Inventory/Professions.lua#L996) |
| `Prof.OnEventPulse` | [L1000](../../Inventory/Professions.lua#L1000) |
| `Prof.InvalidateSkillCaches` | [L1088](../../Inventory/Professions.lua#L1088) |
| `Prof.GetProfessionKnowledge` | [L1266](../../Inventory/Professions.lua#L1266) |
| `Prof.GetRecipeKnowledge` | [L1314](../../Inventory/Professions.lua#L1314) |
| `Prof.HasProfessionName` | [L1341](../../Inventory/Professions.lua#L1341) |
| `Prof.GetProfessionRank` | [L1346](../../Inventory/Professions.lua#L1346) |
| `Prof.GetSkillLineRank` | [L1361](../../Inventory/Professions.lua#L1361) |
| `Prof.GetSkillRequirementFromText` | [L1416](../../Inventory/Professions.lua#L1416) |
| `Prof.GetSkillRequirementFromTooltip` | [L1429](../../Inventory/Professions.lua#L1429) |
| `Prof.GetSkillRequirementFromTooltipData` | [L1463](../../Inventory/Professions.lua#L1463) |
| `Prof.GetSkillRequirementFromBagSlot` | [L1491](../../Inventory/Professions.lua#L1491) |
| `Prof.GetItemSkillRequirement` | [L1569](../../Inventory/Professions.lua#L1569) |
| `Prof.ScheduleLoginScan` | [L1676](../../Inventory/Professions.lua#L1676) |
| `Prof.AbortLoginScan` | [L1711](../../Inventory/Professions.lua#L1711) |
| `Prof.ForceScanOpen` | [L1784](../../Inventory/Professions.lua#L1784) |
| `Prof.ResetLoginScanState` | [L1789](../../Inventory/Professions.lua#L1789) |

### Inventory/Restock/Auction/FluxAuctionRestock.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `A.PrintStatus` | [L31](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L31) |
| `A.Invalidate` | [L91](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L91) |
| `A.IsLegacy` | [L154](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L154) |
| `A.Select` | [L161](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L161) |
| `A.BeginPotionBrowse` | [L507](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L507) |
| `A.PrepareNext` | [L516](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L516) |
| `A.ScanQueue` | [L663](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L663) |
| `A.Primary` | [L829](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L829) |
| `A.ShowSession` | [L942](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L942) |
| `A.HideSession` | [L957](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L957) |
| `A.SettingsChanged` | [L964](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L964) |

### Inventory/Restock/Auction/FluxAuctionRestockCraft.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `A.CraftRecipes` | [L150](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L150) |
| `A.SavedRecipeKnowledge` | [L177](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L177) |
| `A.RefreshCraftRecipes` | [L248](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L248) |
| `A.BookCost` | [L255](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L255) |
| `A.CraftCountsBank` | [L313](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L313) |
| `A.CraftBankFlagsMatch` | [L323](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L323) |
| `A.GetCraftBankAvailable` | [L375](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L375) |
| `A.GetCraftBagAvailable` | [L378](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L378) |
| `A.CompareCraft` | [L399](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L399) |
| `A.ResetCraftPlans` | [L467](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L467) |
| `A.CancelCraftPricing` | [L476](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L476) |
| `A.IsCraftOutput` | [L477](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L477) |
| `A.HasCraftPlans` | [L478](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L478) |
| `A.ClearVendorCraftPlan` | [L480](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L480) |
| `A.GetVendorCraftTargets` | [L512](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L512) |
| `A.MaterialRows` | [L600](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L600) |
| `A.MaterialLimit` | [L665](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L665) |
| `A.CheckCraftSpend` | [L714](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L714) |
| `A.RecordCraftSpend` | [L718](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L718) |
| `A.ReleaseCraftSpend` | [L724](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L724) |
| `A.StartCraftPricing` | [L728](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L728) |
| `A.RouteText` | [L791](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L791) |
| `A.RepriceMaterial` | [L797](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L797) |
| `A.CraftStatus` | [L810](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L810) |
| `A.RecipeDetails` | [L839](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L839) |

### Inventory/Restock/Auction/FluxAuctionRestockData.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `A.Number` | [L8](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L8) |
| `A.Settings` | [L15](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L15) |
| `A.IsUpgradeEnabled` | [L28](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L28) |
| `A.SetUpgradeEnabled` | [L34](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L34) |
| `A.UpgradeItemID` | [L42](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L42) |
| `A.IsUpgradeBlacklisted` | [L47](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L47) |
| `A.RefreshConsumableExclusions` | [L52](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L52) |
| `A.ExcludesDiscoloredHealing` | [L58](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L58) |
| `A.SetExcludeDiscoloredHealing` | [L59](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L59) |
| `A.SetUpgradeBlacklisted` | [L68](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L68) |
| `A.UpgradeBlacklistItems` | [L78](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L78) |
| `A.GetMaxPrice` | [L86](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L86) |
| `A.IsPriceUnlimited` | [L89](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L89) |
| `A.PriceLimit` | [L100](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L100) |
| `A.PricePolicyMatches` | [L103](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L103) |
| `A.PreferCrafting` | [L107](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L107) |
| `A.SetPreferCrafting` | [L108](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L108) |
| `A.PurchaseLimit` | [L113](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L113) |
| `A.SetMaxPrice` | [L119](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L119) |
| `A.SetPriceUnlimited` | [L132](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L132) |
| `A.ParsePrice` | [L137](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L137) |
| `A.PriceText` | [L155](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L155) |
| `A.VendorSource` | [L164](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L164) |
| `A.HasUnlimitedVendor` | [L185](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L185) |
| `A.IsVendorItem` | [L189](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L189) |
| `A.VendorPrice` | [L192](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L192) |
| `A.VendorTerms` | [L196](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L196) |
| `A.IsFoodWater` | [L213](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L213) |
| `A.SetItemUnits` | [L229](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L229) |
| `A.AllowExcessStacks` | [L247](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L247) |
| `A.IsInventoryReliable` | [L258](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L258) |
| `A.IsReliable` | [L264](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L264) |
| `A.NoteRestockMailbox` | [L272](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L272) |
| `A.RefreshMailFacts` | [L282](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L282) |
| `A.MailUnits` | [L293](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L293) |
| `A.PredictedMailUnits` | [L306](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L306) |
| `A.Pending` | [L328](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L328) |
| `A.Need` | [L368](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L368) |
| `A.Reserve` | [L408](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L408) |
| `A.AcceptReservation` | [L418](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L418) |
| `A.Release` | [L424](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L424) |
| `A.RowLess` | [L445](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L445) |
| `A.GetRows` | [L453](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L453) |
| `A.GetVendorScanRows` | [L529](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L529) |
| `A.FindRow` | [L531](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L531) |
| `A.SelectStack` | [L538](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L538) |
| `A.CommodityOffer` | [L561](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L561) |

### Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `F.Capture` | [L112](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L112) |
| `F.Purchased` | [L162](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L162) |
| `F.HasWork` | [L177](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L177) |
| `F.IsAutoEnabled` | [L181](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L181) |
| `F.SetAutoEnabled` | [L182](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L182) |
| `F.IsContextOpen` | [L187](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L187) |
| `F.CanAct` | [L209](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L209) |
| `F.GetMailItems` | [L232](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L232) |
| `F.MailTakeStarted` | [L242](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L242) |
| `F.MailTakeFinished` | [L255](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L255) |
| `F.MailTakeCancelled` | [L263](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L263) |
| `F.OwnerRejected` | [L270](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L270) |
| `F.MailSnapshotComplete` | [L279](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L279) |
| `F.Planned` | [L310](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L310) |
| `F.Clear` | [L319](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L319) |
| `F.GetState` | [L553](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L553) |
| `F.GetBankTargets` | [L554](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L554) |
| `F.GetVendorTargets` | [L558](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L558) |
| `F.Refresh` | [L563](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L563) |
| `F.Click` | [L623](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L623) |
| `F.Resume` | [L652](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L652) |

### Inventory/Restock/Auction/FluxAuctionRestockFollowupCraft.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `F.CraftIsBusy` | [L64](../../Inventory/Restock/Auction/FluxAuctionRestockFollowupCraft.lua#L64) |
| `F.CanCraft` | [L188](../../Inventory/Restock/Auction/FluxAuctionRestockFollowupCraft.lua#L188) |
| `F.CraftClick` | [L192](../../Inventory/Restock/Auction/FluxAuctionRestockFollowupCraft.lua#L192) |

### Inventory/Restock/Auction/FluxAuctionRestockFollowupUI.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `F.Paint` | [L324](../../Inventory/Restock/Auction/FluxAuctionRestockFollowupUI.lua#L324) |

### Inventory/Restock/Auction/FluxAuctionRestockPotions.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `A.GetUpgradeProposals` | [L10](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L10) |
| `A.ResolveUpgrade` | [L17](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L17) |
| `A.CapturePotionTargets` | [L42](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L42) |
| `A.PotionReplacement` | [L63](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L63) |
| `A.ApplyPotionReplacements` | [L72](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L72) |
| `A.CancelPotionDiscovery` | [L106](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L106) |
| `A.ResetPotionUpgradeChoices` | [L111](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L111) |
| `A.ResetPotionDiscovery` | [L112](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L112) |
| `A.HasPotionCatalog` | [L119](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L119) |
| `A.HasBlockedPotionTargets` | [L125](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L125) |
| `A.PotionRowBlocked` | [L126](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L126) |
| `A.DiscoverPotionUpgrades` | [L209](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L209) |
| `proposal.resolve` | [L304](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L304) |

### Inventory/Restock/Auction/FluxAuctionRestockPrices.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `A.VendorOfferAllowed` | [L35](../../Inventory/Restock/Auction/FluxAuctionRestockPrices.lua#L35) |
| `A.FilterVendorOffers` | [L46](../../Inventory/Restock/Auction/FluxAuctionRestockPrices.lua#L46) |
| `A.HasCheaperVendorBook` | [L58](../../Inventory/Restock/Auction/FluxAuctionRestockPrices.lua#L58) |
| `A.CommodityVendorLimit` | [L66](../../Inventory/Restock/Auction/FluxAuctionRestockPrices.lua#L66) |
| `A.MarketPrice` | [L75](../../Inventory/Restock/Auction/FluxAuctionRestockPrices.lua#L75) |
| `A.LoadMarketHints` | [L89](../../Inventory/Restock/Auction/FluxAuctionRestockPrices.lua#L89) |
| `A.PublishPriceBook` | [L92](../../Inventory/Restock/Auction/FluxAuctionRestockPrices.lua#L92) |
| `A.FlushAuctionatorPrices` | [L121](../../Inventory/Restock/Auction/FluxAuctionRestockPrices.lua#L121) |

### Inventory/Restock/Auction/FluxAuctionRestockUI.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `f.PaintViewport` | [L223](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L223) |
| `f.Reveal` | [L249](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L249) |
| `f.CreateCell` | [L257](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L257) |
| `cell.EnsureChrome` | [L271](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L271) |
| `cell.Bind` | [L299](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L299) |
| `cell.RefreshTip` | [L328](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L328) |
| `cell.ShowTip` | [L344](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L344) |
| `cell.EnsureUpgrade` | [L364](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L364) |
| `card.BindProposal` | [L393](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L393) |
| `cardcontrol.RefreshTip` | [L400](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L400) |
| `A.UpdateUI` | [L499](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L499) |
| `A.Toggle` | [L610](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L610) |
| `A.AttachButton` | [L624](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L624) |
| `SlashCmdList.FLUXAUCTIONRESTOCK` | [L671](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L671) |

### Inventory/Restock/Auction/FluxAuctionRestockVendorCatalog.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `catalog.Has` | [L13082](../../Inventory/Restock/Auction/FluxAuctionRestockVendorCatalog.lua#L13082) |
| `catalog.GetTerms` | [L13086](../../Inventory/Restock/Auction/FluxAuctionRestockVendorCatalog.lua#L13086) |
| `catalog.Get` | [L13091](../../Inventory/Restock/Auction/FluxAuctionRestockVendorCatalog.lua#L13091) |

### Inventory/Restock/Bank/FluxBankRestock.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `BR.IsAutoEnabled` | [L858](../../Inventory/Restock/Bank/FluxBankRestock.lua#L858) |
| `BR.SetAutoEnabled` | [L862](../../Inventory/Restock/Bank/FluxBankRestock.lua#L862) |
| `BR.IsRunning` | [L866](../../Inventory/Restock/Bank/FluxBankRestock.lua#L866) |
| `BR.RegisterSessionEndCallback` | [L1748](../../Inventory/Restock/Bank/FluxBankRestock.lua#L1748) |
| `BR.Start` | [L1877](../../Inventory/Restock/Bank/FluxBankRestock.lua#L1877) |
| `BR.Stop` | [L1968](../../Inventory/Restock/Bank/FluxBankRestock.lua#L1968) |
| `BR.RunManual` | [L1988](../../Inventory/Restock/Bank/FluxBankRestock.lua#L1988) |
| `BR.CanAuctionFollowup` | [L2009](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2009) |
| `BR.RunAuctionFollowup` | [L2021](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2021) |
| `BR.GetPendingSummary` | [L2114](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2114) |
| `BR.CanRunNow` | [L2156](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2156) |
| `BR.GetCachedCanRunNow` | [L2166](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2166) |
| `BR.InvalidateCanRunCache` | [L2178](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2178) |
| `BR.GetProgress` | [L2186](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2186) |
| `BR.GetTooltipItems` | [L2200](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2200) |
| `BR.RunFastButtonRefresh` | [L2239](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2239) |
| `BR.CancelIdleCanRunWork` | [L2279](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2279) |
| `BR.RunLiveButtonRefresh` | [L2285](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2285) |
| `BR.RunMovePlanSmokeTest` | [L2385](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2385) |
| `BR.RunSimRegression` | [L2631](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2631) |
| `BR.IsDebug` | [L2655](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2655) |
| `BR.SetDebug` | [L2660](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2660) |
| `BR.DebugDumpSession` | [L2667](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2667) |
| `BR.Debug` | [L2674](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2674) |

### Inventory/Restock/Bank/FluxBankRestockButton.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Button.GetControl` | [L407](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L407) |
| `Button.Refresh` | [L411](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L411) |
| `Button.RefreshIdle` | [L434](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L434) |
| `Button.RefreshLive` | [L454](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L454) |
| `Button.FindBaganatorBankView` | [L477](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L477) |
| `Button.ReleaseBaganatorFooter` | [L644](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L644) |
| `Button.AttachToBaganatorBank` | [L720](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L720) |
| `Button.AttachToBank` | [L845](../../Inventory/Restock/Bank/FluxBankRestockButton.lua#L845) |

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
| `Exec.Reset` | [L1601](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1601) |
| `Exec.Start` | [L1612](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1612) |
| `Exec.Stop` | [L1645](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1645) |
| `Exec.IsActive` | [L1657](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1657) |
| `Exec.OnSplitRejected` | [L1661](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1661) |
| `Exec.Wake` | [L1688](../../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua#L1688) |

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
| `List.GetItemUnitPrice` | [L505](../../Inventory/Restock/Core/FluxRestockList.lua#L505) |
| `List.GetItemUnitPriceFluxRestock.GetTargetQuantity` | [L529](../../Inventory/Restock/Core/FluxRestockList.lua#L529) |
| `endFluxRestock.SetTargetQuantity` | [L530](../../Inventory/Restock/Core/FluxRestockList.lua#L530) |
| `endFluxRestock.GetRestockCost` | [L531](../../Inventory/Restock/Core/FluxRestockList.lua#L531) |
| `endFluxRestock.IsKnownSpellReagentItem` | [L547](../../Inventory/Restock/Core/FluxRestockList.lua#L547) |
| `endFluxRestock.IsStaticSpellReagentItem` | [L548](../../Inventory/Restock/Core/FluxRestockList.lua#L548) |
| `endFluxRestock.IsSpellReagentItem` | [L549](../../Inventory/Restock/Core/FluxRestockList.lua#L549) |
| `endFluxRestock.InvalidateSpellReagentCache` | [L550](../../Inventory/Restock/Core/FluxRestockList.lua#L550) |
| `FV.InvalidateRestockOptionsPanelCache` | [L677](../../Inventory/Restock/Core/FluxRestockList.lua#L677) |
| `FV.GetRestockTargetItems` | [L682](../../Inventory/Restock/Core/FluxRestockList.lua#L682) |
| `FV.HasAnyRestockTargets` | [L865](../../Inventory/Restock/Core/FluxRestockList.lua#L865) |
| `FV.IsRestockEntrySoldAtVendor` | [L893](../../Inventory/Restock/Core/FluxRestockList.lua#L893) |
| `FV.FilterRestockListForVendor` | [L914](../../Inventory/Restock/Core/FluxRestockList.lua#L914) |
| `FV.SortRestockEntriesByVendorAvailability` | [L931](../../Inventory/Restock/Core/FluxRestockList.lua#L931) |
| `FV.GetRestockVendorItems` | [L950](../../Inventory/Restock/Core/FluxRestockList.lua#L950) |
| `FV.RefreshRestockCacheEntries` | [L962](../../Inventory/Restock/Core/FluxRestockList.lua#L962) |
| `FV.HasRestockNeeded` | [L1014](../../Inventory/Restock/Core/FluxRestockList.lua#L1014) |
| `FV.GetRestockTotalCost` | [L1024](../../Inventory/Restock/Core/FluxRestockList.lua#L1024) |
| `FV.RefreshMerchantOptionsCheckboxes` | [L1041](../../Inventory/Restock/Core/FluxRestockList.lua#L1041) |
| `Registry.InvalidateBankTargetsCache` | [L1092](../../Inventory/Restock/Core/FluxRestockList.lua#L1092) |
| `Registry.RegisterProvider` | [L1097](../../Inventory/Restock/Core/FluxRestockList.lua#L1097) |
| `Registry.UnregisterProvider` | [L1105](../../Inventory/Restock/Core/FluxRestockList.lua#L1105) |
| `Registry.GetBankTargets` | [L1156](../../Inventory/Restock/Core/FluxRestockList.lua#L1156) |
| `Registry.GetBankTargetList` | [L1174](../../Inventory/Restock/Core/FluxRestockList.lua#L1174) |
| `Registry.GetItemMaxStack` | [L1191](../../Inventory/Restock/Core/FluxRestockList.lua#L1191) |
| `Registry.CountItemInBank` | [L1202](../../Inventory/Restock/Core/FluxRestockList.lua#L1202) |
| `Registry.GetSlotCharges` | [L1308](../../Inventory/Restock/Core/FluxRestockList.lua#L1308) |
| `Registry.GetChargeInfo` | [L1395](../../Inventory/Restock/Core/FluxRestockList.lua#L1395) |
| `Registry.IsChargeItem` | [L1456](../../Inventory/Restock/Core/FluxRestockList.lua#L1456) |
| `Registry.GetItemMaxCharges` | [L1461](../../Inventory/Restock/Core/FluxRestockList.lua#L1461) |
| `Registry.GetChargeAwareCount` | [L1479](../../Inventory/Restock/Core/FluxRestockList.lua#L1479) |

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
| `S.Get` | [L212](../../Inventory/Restock/Core/FluxRestockSettings.lua#L212) |
| `FluxVendorAuto.EnsureSettings` | [L240](../../Inventory/Restock/Core/FluxRestockSettings.lua#L240) |
| `FluxVendorAuto.GetSettings` | [L244](../../Inventory/Restock/Core/FluxRestockSettings.lua#L244) |

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
| `Tiers.ForcePublishInferiorForKinds` | [L644](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L644) |
| `Tiers.RequestRecompute` | [L696](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L696) |
| `Tiers.TryRunDeferredLoginSettle` | [L790](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L790) |
| `Tiers.RunPulseEndLoginSettle` | [L794](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua#L794) |

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
| `P.SetSavedTier` | [L135](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L135) |
| `P.GetBagCacheGen` | [L160](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L160) |
| `P.GetMerchantCacheGen` | [L168](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L168) |
| `P.IsMerchantFrameOpen` | [L176](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L176) |
| `Tiers.InvalidateTierQueryCache` | [L180](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L180) |
| `Tiers.InvalidateTooltipDisplayCache` | [L195](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L195) |
| `Tiers.IsTierCountPending` | [L204](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L204) |
| `Tiers.FlushTierCountRefresh` | [L208](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L208) |
| `Tiers.CancelPendingRecompute` | [L212](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L212) |
| `Tiers.CancelBackgroundWork` | [L216](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua#L216) |

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
| `Tiers.GetJunkReferenceTier` | [L444](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L444) |
| `Tiers.GetEffectiveReferenceTier` | [L499](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L499) |
| `Tiers.GetReferenceTier` | [L542](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L542) |
| `Tiers.RememberOwnedTiers` | [L552](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L552) |
| `Tiers.ResetTierReference` | [L560](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L560) |
| `P.GetVendorBestTier` | [L581](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L581) |
| `Tiers.GetInferiorReferenceTier` | [L586](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L586) |
| `P.GetTierRestockThreshold` | [L614](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L614) |
| `P.IsTierItemUsable` | [L634](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L634) |
| `P.ItemMatchesTier` | [L649](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L649) |
| `P.ItemMatchesTierForBank` | [L670](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L670) |
| `P.ItemMatchesTierLooseForBank` | [L681](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L681) |
| `Tiers.ItemMatchesRestockKind` | [L691](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L691) |
| `Tiers.StackMatchesBankRestockKind` | [L704](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L704) |
| `Tiers.GetTierCount` | [L732](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L732) |
| `Tiers.GetSnapshotTierCount` | [L817](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L817) |
| `Tiers.GetTierBagTotalForBankRestock` | [L821](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L821) |
| `Tiers.GetBankCountForKind` | [L899](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L899) |
| `Tiers.GetCachedTooltipReferenceTier` | [L958](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L958) |
| `Tiers.GetTooltipDisplay` | [L962](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L962) |
| `Tiers.KindsTouchedByItemID` | [L970](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L970) |

### Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Tiers.GetTarget` | [L8](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L8) |
| `Tiers.SetTarget` | [L16](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L16) |
| `Tiers.GetCountBankFlag` | [L35](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L35) |
| `Tiers.SetCountBankFlag` | [L43](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L43) |
| `Tiers.IsMarkInferiorEnabled` | [L54](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L54) |
| `Tiers.IsCarriedUpgradeRequired` | [L62](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L62) |
| `Tiers.SetCarriedUpgradeRequired` | [L67](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L67) |
| `Tiers.SetMarkInferiorEnabled` | [L82](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L82) |
| `Tiers.IsTierEligible` | [L91](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L91) |
| `Tiers.NeedsTierRestockTargets` | [L108](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L108) |
| `Tiers.ApplyAuctionTierUpgrade` | [L119](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L119) |
| `Tiers.EnsureStores` | [L146](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua#L146) |

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
| `RI.GetContainerItemSnapshot` | [L533](../../Inventory/Restock/FluxRestock_Inv.lua#L533) |
| `RI.ItemExistsInInventory` | [L554](../../Inventory/Restock/FluxRestock_Inv.lua#L554) |
| `RI.IsBankContainer` | [L571](../../Inventory/Restock/FluxRestock_Inv.lua#L571) |
| `RI.PickupContainerItem` | [L580](../../Inventory/Restock/FluxRestock_Inv.lua#L580) |
| `RI.GetLastBankUse` | [L611](../../Inventory/Restock/FluxRestock_Inv.lua#L611) |
| `RI.NoteBankUseAfter` | [L615](../../Inventory/Restock/FluxRestock_Inv.lua#L615) |
| `RI.UseContainerItem` | [L624](../../Inventory/Restock/FluxRestock_Inv.lua#L624) |
| `RI.SplitContainerItemPending` | [L710](../../Inventory/Restock/FluxRestock_Inv.lua#L710) |
| `RI.SplitContainerItem` | [L738](../../Inventory/Restock/FluxRestock_Inv.lua#L738) |
| `RI.SetMerchantOpen` | [L774](../../Inventory/Restock/FluxRestock_Inv.lua#L774) |
| `RI.IsMerchantOpen` | [L778](../../Inventory/Restock/FluxRestock_Inv.lua#L778) |
| `RI.IsAutomationQuiet` | [L791](../../Inventory/Restock/FluxRestock_Inv.lua#L791) |
| `RI.NotifyAutomationPulse` | [L809](../../Inventory/Restock/FluxRestock_Inv.lua#L809) |
| `RI.OnQuietSettled` | [L820](../../Inventory/Restock/FluxRestock_Inv.lua#L820) |
| `RI.IsBagStorm` | [L835](../../Inventory/Restock/FluxRestock_Inv.lua#L835) |
| `RI.NotifyBagStorm` | [L856](../../Inventory/Restock/FluxRestock_Inv.lua#L856) |
| `RI.OnStormSettled` | [L867](../../Inventory/Restock/FluxRestock_Inv.lua#L867) |
| `RI.RegisterStormSettled` | [L882](../../Inventory/Restock/FluxRestock_Inv.lua#L882) |
| `RI.UnregisterStormSettled` | [L889](../../Inventory/Restock/FluxRestock_Inv.lua#L889) |
| `RI.ShouldDeferHeavyWork` | [L893](../../Inventory/Restock/FluxRestock_Inv.lua#L893) |
| `RI.NotifyItemsRemoved` | [L900](../../Inventory/Restock/FluxRestock_Inv.lua#L900) |
| `RI.ForceRefreshBagCounts` | [L903](../../Inventory/Restock/FluxRestock_Inv.lua#L903) |
| `RI.FlushExtraButtonIdentityRefresh` | [L906](../../Inventory/Restock/FluxRestock_Inv.lua#L906) |
| `Bank.IsOpen` | [L954](../../Inventory/Restock/FluxRestock_Inv.lua#L954) |
| `Bank.IsLive` | [L968](../../Inventory/Restock/FluxRestock_Inv.lua#L968) |
| `Bank.GetContainerIDs` | [L972](../../Inventory/Restock/FluxRestock_Inv.lua#L972) |
| `Bank.GetScanDebug` | [L1002](../../Inventory/Restock/FluxRestock_Inv.lua#L1002) |
| `Bank.IsModernBank` | [L1038](../../Inventory/Restock/FluxRestock_Inv.lua#L1038) |
| `Bank.HasLegacyBankBags` | [L1042](../../Inventory/Restock/FluxRestock_Inv.lua#L1042) |
| `Bank.HasReagentBag` | [L1057](../../Inventory/Restock/FluxRestock_Inv.lua#L1057) |
| `Bank.IsBankContainer` | [L1061](../../Inventory/Restock/FluxRestock_Inv.lua#L1061) |
| `Bank.GetBankTypeForContainer` | [L1065](../../Inventory/Restock/FluxRestock_Inv.lua#L1065) |
| `Bank.Persist` | [L1154](../../Inventory/Restock/FluxRestock_Inv.lua#L1154) |
| `Bank.ForEachLiveStack` | [L1318](../../Inventory/Restock/FluxRestock_Inv.lua#L1318) |
| `Bank.Refresh` | [L1377](../../Inventory/Restock/FluxRestock_Inv.lua#L1377) |
| `Bank.GetCount` | [L1436](../../Inventory/Restock/FluxRestock_Inv.lua#L1436) |
| `Bank.GetCharacterCounts` | [L1473](../../Inventory/Restock/FluxRestock_Inv.lua#L1473) |
| `Bank.GetWarbandCounts` | [L1489](../../Inventory/Restock/FluxRestock_Inv.lua#L1489) |
| `Bank.GetGeneration` | [L1508](../../Inventory/Restock/FluxRestock_Inv.lua#L1508) |
| `Bank.FindStacks` | [L1515](../../Inventory/Restock/FluxRestock_Inv.lua#L1515) |
| `Bank.ForEachOpenStack` | [L1561](../../Inventory/Restock/FluxRestock_Inv.lua#L1561) |
| `Bank.GetItemLink` | [L1593](../../Inventory/Restock/FluxRestock_Inv.lua#L1593) |
| `Bank.RegisterBankOpen` | [L1607](../../Inventory/Restock/FluxRestock_Inv.lua#L1607) |
| `Bank.RegisterBankClose` | [L1614](../../Inventory/Restock/FluxRestock_Inv.lua#L1614) |
| `Bank.RefreshIfOpen` | [L1621](../../Inventory/Restock/FluxRestock_Inv.lua#L1621) |
| `Bank.RequestLiveRefresh` | [L1631](../../Inventory/Restock/FluxRestock_Inv.lua#L1631) |
| `Bank.SchedulePersist` | [L1635](../../Inventory/Restock/FluxRestock_Inv.lua#L1635) |
| `RI.Notify` | [L1669](../../Inventory/Restock/FluxRestock_Inv.lua#L1669) |
| `RI.Register` | [L1812](../../Inventory/Restock/FluxRestock_Inv.lua#L1812) |
| `RI.Unregister` | [L1824](../../Inventory/Restock/FluxRestock_Inv.lua#L1824) |

### Inventory/Restock/Junk/FluxJunk.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `FJ.Init` | [L116](../../Inventory/Restock/Junk/FluxJunk.lua#L116) |
| `FJ.GetFilters` | [L120](../../Inventory/Restock/Junk/FluxJunk.lua#L120) |
| `FJ.GetDisplay` | [L124](../../Inventory/Restock/Junk/FluxJunk.lua#L124) |
| `FJ.IsExplicitUseful` | [L141](../../Inventory/Restock/Junk/FluxJunk.lua#L141) |
| `FJ.IsExplicitJunk` | [L147](../../Inventory/Restock/Junk/FluxJunk.lua#L147) |
| `FJ.IsManualRestockItem` | [L181](../../Inventory/Restock/Junk/FluxJunk.lua#L181) |
| `FJ.SetInferiorSet` | [L228](../../Inventory/Restock/Junk/FluxJunk.lua#L228) |
| `FJ.IsUpgradeInferior` | [L284](../../Inventory/Restock/Junk/FluxJunk.lua#L284) |
| `FJ.MarkUpgradeInferior` | [L289](../../Inventory/Restock/Junk/FluxJunk.lua#L289) |
| `FJ.HasUpgradeInferiorEntries` | [L314](../../Inventory/Restock/Junk/FluxJunk.lua#L314) |
| `FJ.AnyUpgradeInferiorInBags` | [L320](../../Inventory/Restock/Junk/FluxJunk.lua#L320) |
| `FJ.ForEachUpgradeInferiorItemID` | [L341](../../Inventory/Restock/Junk/FluxJunk.lua#L341) |
| `FJ.UnmarkUpgradeInferior` | [L348](../../Inventory/Restock/Junk/FluxJunk.lua#L348) |
| `FJ.ClearUpgradeInferiorList` | [L357](../../Inventory/Restock/Junk/FluxJunk.lua#L357) |
| `FJ.InvalidateRules` | [L368](../../Inventory/Restock/Junk/FluxJunk.lua#L368) |
| `FJ.InvalidateItemRules` | [L377](../../Inventory/Restock/Junk/FluxJunk.lua#L377) |
| `FJ.OnItemDataLoaded` | [L387](../../Inventory/Restock/Junk/FluxJunk.lua#L387) |
| `FJ.IsConjuredConsumable` | [L508](../../Inventory/Restock/Junk/FluxJunk.lua#L508) |
| `FJ.IsLowConsumable` | [L517](../../Inventory/Restock/Junk/FluxJunk.lua#L517) |
| `FJ.IsFiltered` | [L661](../../Inventory/Restock/Junk/FluxJunk.lua#L661) |
| `FJ.IsJunk` | [L672](../../Inventory/Restock/Junk/FluxJunk.lua#L672) |
| `FJ.IsJunkForDisplay` | [L696](../../Inventory/Restock/Junk/FluxJunk.lua#L696) |
| `FJ.IsBlizzardVendorJunk` | [L763](../../Inventory/Restock/Junk/FluxJunk.lua#L763) |
| `FJ.NativeJunkCount` | [L792](../../Inventory/Restock/Junk/FluxJunk.lua#L792) |
| `FJ.HasItemInPlayerBags` | [L804](../../Inventory/Restock/Junk/FluxJunk.lua#L804) |
| `FJ.FindBagSlot` | [L809](../../Inventory/Restock/Junk/FluxJunk.lua#L809) |
| `FJ.IterateJunk` | [L894](../../Inventory/Restock/Junk/FluxJunk.lua#L894) |
| `FJ.IterateUpgradeInferiorFast` | [L904](../../Inventory/Restock/Junk/FluxJunk.lua#L904) |
| `FJ.SetUpgradeInferiorKindFilter` | [L920](../../Inventory/Restock/Junk/FluxJunk.lua#L920) |
| `FJ.ClearUpgradeInferiorKindFilter` | [L925](../../Inventory/Restock/Junk/FluxJunk.lua#L925) |
| `FJ.HasUpgradeInferiorForKinds` | [L930](../../Inventory/Restock/Junk/FluxJunk.lua#L930) |
| `FJ.InvalidateJunkWorklist` | [L988](../../Inventory/Restock/Junk/FluxJunk.lua#L988) |
| `FJ.IsSlotProtectedFromSell` | [L992](../../Inventory/Restock/Junk/FluxJunk.lua#L992) |
| `FJ.BuildJunkSlotWorklist` | [L1001](../../Inventory/Restock/Junk/FluxJunk.lua#L1001) |
| `FJ.EnsureJunkWorklist` | [L1024](../../Inventory/Restock/Junk/FluxJunk.lua#L1024) |
| `FJ.IterateJunkWorklist` | [L1033](../../Inventory/Restock/Junk/FluxJunk.lua#L1033) |
| `FJ.RemoveJunkSlotFromWorklist` | [L1050](../../Inventory/Restock/Junk/FluxJunk.lua#L1050) |
| `FJ.HasJunkWorklistRemaining` | [L1069](../../Inventory/Restock/Junk/FluxJunk.lua#L1069) |
| `FJ.GetUpgradeInferiorSlotCount` | [L1075](../../Inventory/Restock/Junk/FluxJunk.lua#L1075) |
| `FJ.InvalidateJunkSlotCount` | [L1095](../../Inventory/Restock/Junk/FluxJunk.lua#L1095) |
| `FJ.GetJunkSlotCount` | [L1101](../../Inventory/Restock/Junk/FluxJunk.lua#L1101) |
| `FJ.GetJunkSlotCountFast` | [L1105](../../Inventory/Restock/Junk/FluxJunk.lua#L1105) |
| `FJ.RefreshJunkSlotCountFast` | [L1113](../../Inventory/Restock/Junk/FluxJunk.lua#L1113) |
| `FJ.AdjustJunkSlotCount` | [L1117](../../Inventory/Restock/Junk/FluxJunk.lua#L1117) |
| `FJ.RegisterJunkCountListener` | [L1125](../../Inventory/Restock/Junk/FluxJunk.lua#L1125) |
| `FJ.OnBagSnapshotDiff` | [L1130](../../Inventory/Restock/Junk/FluxJunk.lua#L1130) |
| `FJ.AnyJunkInBags` | [L1141](../../Inventory/Restock/Junk/FluxJunk.lua#L1141) |
| `FJ.AnyExplicitJunkInBags` | [L1148](../../Inventory/Restock/Junk/FluxJunk.lua#L1148) |
| `FJ.AnyBlizzardVendorJunkInBags` | [L1165](../../Inventory/Restock/Junk/FluxJunk.lua#L1165) |
| `FJ.HasSellableJunkForButton` | [L1196](../../Inventory/Restock/Junk/FluxJunk.lua#L1196) |
| `FJ.RefreshSellableJunkButtonState` | [L1221](../../Inventory/Restock/Junk/FluxJunk.lua#L1221) |
| `FJ.GetSellButtonStats` | [L1230](../../Inventory/Restock/Junk/FluxJunk.lua#L1230) |
| `FJ.InvalidateSellButtonStats` | [L1266](../../Inventory/Restock/Junk/FluxJunk.lua#L1266) |
| `FJ.GetSellReport` | [L1271](../../Inventory/Restock/Junk/FluxJunk.lua#L1271) |
| `FJ.FireListChanged` | [L1290](../../Inventory/Restock/Junk/FluxJunk.lua#L1290) |
| `FJ.RegisterListChanged` | [L1304](../../Inventory/Restock/Junk/FluxJunk.lua#L1304) |
| `FJ.NotifyVisualRefresh` | [L1309](../../Inventory/Restock/Junk/FluxJunk.lua#L1309) |
| `FJ.RegisterVisualRefresh` | [L1315](../../Inventory/Restock/Junk/FluxJunk.lua#L1315) |
| `FJ.RefreshJunkVisuals` | [L1320](../../Inventory/Restock/Junk/FluxJunk.lua#L1320) |
| `FJ.ToggleJunk` | [L1330](../../Inventory/Restock/Junk/FluxJunk.lua#L1330) |
| `FJ.AddJunk` | [L1343](../../Inventory/Restock/Junk/FluxJunk.lua#L1343) |
| `FJ.MarkUseful` | [L1350](../../Inventory/Restock/Junk/FluxJunk.lua#L1350) |
| `FJ.ForgetJunk` | [L1358](../../Inventory/Restock/Junk/FluxJunk.lua#L1358) |
| `FJ.ClearAutoJunkMark` | [L1368](../../Inventory/Restock/Junk/FluxJunk.lua#L1368) |
| `FJ.InvalidateJunkTabListCache` | [L1389](../../Inventory/Restock/Junk/FluxJunk.lua#L1389) |
| `FJ.GetExplicitJunkList` | [L1414](../../Inventory/Restock/Junk/FluxJunk.lua#L1414) |
| `FJ.GetUsefulList` | [L1429](../../Inventory/Restock/Junk/FluxJunk.lua#L1429) |
| `FJ.GetAutoJunkList` | [L1448](../../Inventory/Restock/Junk/FluxJunk.lua#L1448) |
| `FJ.GetJunkTabList` | [L1469](../../Inventory/Restock/Junk/FluxJunk.lua#L1469) |
| `FJ.RebuildJunkTabListCache` | [L1494](../../Inventory/Restock/Junk/FluxJunk.lua#L1494) |
| `FJ.IsAutoJunk` | [L1499](../../Inventory/Restock/Junk/FluxJunk.lua#L1499) |
| `FJ.OnManualRestockChanged` | [L1516](../../Inventory/Restock/Junk/FluxJunk.lua#L1516) |
| `FJ.GetItemIdFromCursor` | [L1547](../../Inventory/Restock/Junk/FluxJunk.lua#L1547) |
| `FJ.HandleItemDrop` | [L1558](../../Inventory/Restock/Junk/FluxJunk.lua#L1558) |
| `FJ.WarmJunkDisplayCacheForBags` | [L1576](../../Inventory/Restock/Junk/FluxJunk.lua#L1576) |
| `FJ.WarmJunkDisplayCacheThoroughChunked` | [L1577](../../Inventory/Restock/Junk/FluxJunk.lua#L1577) |
| `FJ.IsJunkDisplayCacheWarm` | [L1580](../../Inventory/Restock/Junk/FluxJunk.lua#L1580) |
| `FJ.ResetJunkDisplayCacheWarm` | [L1581](../../Inventory/Restock/Junk/FluxJunk.lua#L1581) |
| `FJ.InvalidateJunkBag` | [L1582](../../Inventory/Restock/Junk/FluxJunk.lua#L1582) |
| `FJ.InvalidateAllJunkBags` | [L1583](../../Inventory/Restock/Junk/FluxJunk.lua#L1583) |
| `FJ.FlushDeferredJunkDisplayCaches` | [L1584](../../Inventory/Restock/Junk/FluxJunk.lua#L1584) |
| `FJ.RelocateBagJunkCache` | [L1585](../../Inventory/Restock/Junk/FluxJunk.lua#L1585) |
| `FJ.RefreshJunkDisplaySlot` | [L1586](../../Inventory/Restock/Junk/FluxJunk.lua#L1586) |
| `FJ.SetJunkDisplayCacheSlot` | [L1587](../../Inventory/Restock/Junk/FluxJunk.lua#L1587) |
| `FJ.BeginVisualPaint` | [L1588](../../Inventory/Restock/Junk/FluxJunk.lua#L1588) |
| `FJ.EndVisualPaint` | [L1589](../../Inventory/Restock/Junk/FluxJunk.lua#L1589) |
| `FJ.IsVisualPaintActive` | [L1590](../../Inventory/Restock/Junk/FluxJunk.lua#L1590) |
| `FJ.RescanAutoJunkRules` | [L1591](../../Inventory/Restock/Junk/FluxJunk.lua#L1591) |
| `FJ.SyncAutoJunkMarks` | [L1592](../../Inventory/Restock/Junk/FluxJunk.lua#L1592) |
| `FJ.ScheduleAutoJunkSync` | [L1593](../../Inventory/Restock/Junk/FluxJunk.lua#L1593) |
| `FJ.ScheduleJunkTabAuthoritativeRefresh` | [L1595](../../Inventory/Restock/Junk/FluxJunk.lua#L1595) |
| `FJ.PromoteMarkedInferiorToAutoJunk` | [L1625](../../Inventory/Restock/Junk/FluxJunk.lua#L1625) |
| `FJ.PromoteInferiorItemsToAutoJunk` | [L1626](../../Inventory/Restock/Junk/FluxJunk.lua#L1626) |
| `FJ.ReconcileUpgradeInferiorMarks` | [L1627](../../Inventory/Restock/Junk/FluxJunk.lua#L1627) |
| `FJ.EnsureInferiorConsumableMarked` | [L1628](../../Inventory/Restock/Junk/FluxJunk.lua#L1628) |
| `FJ.ScheduleConjureInferiorJunkSync` | [L1630](../../Inventory/Restock/Junk/FluxJunk.lua#L1630) |
| `FJ.AppendTierReferenceRestoreLines` | [L1637](../../Inventory/Restock/Junk/FluxJunk.lua#L1637) |
| `FJ.HasConjureJunkFilterAvailable` | [L1644](../../Inventory/Restock/Junk/FluxJunk.lua#L1644) |
| `FJ.ScanInferiorTierConsumables` | [L1668](../../Inventory/Restock/Junk/FluxJunk.lua#L1668) |
| `FJ.PrintInferiorTierScan` | [L1680](../../Inventory/Restock/Junk/FluxJunk.lua#L1680) |

### Inventory/Restock/Junk/FluxJunkOverlay.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Overlay.ArePaintTargetsVisible` | [L612](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L612) |
| `Overlay.ScheduleCharacterBagTransferPaint` | [L781](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L781) |
| `Overlay.UpdateAll` | [L897](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L897) |
| `Overlay.UpdateDirtyBags` | [L934](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L934) |
| `Overlay.UpdateAllBank` | [L1263](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1263) |
| `Overlay.ScheduleMainBankGridRefresh` | [L1272](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1272) |
| `Overlay.ApplyBankInternalContext` | [L1298](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1298) |
| `Overlay.ApplyDispatchContext` | [L1321](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1321) |
| `Overlay.ScheduleBankTransferPaint` | [L1397](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1397) |
| `Overlay.ApplyBankOnlyContext` | [L1411](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1411) |
| `Overlay.MarkBankGridDirty` | [L1421](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1421) |
| `Overlay.RepaintInferiorVisuals` | [L1501](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1501) |
| `Overlay.ScheduleInferiorRepaintBurst` | [L1510](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1510) |
| `Overlay.CancelInferiorRepaintBurst` | [L1566](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1566) |
| `Overlay.OnLoginPulseEndSettled` | [L1571](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1571) |
| `Overlay.FlushDeferredPaint` | [L1619](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1619) |
| `Overlay.NotifyBankActivity` | [L1705](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1705) |
| `Overlay.EnsureHooks` | [L1724](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1724) |
| `Overlay.RegisterSlotDecorator` | [L1877](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1877) |
| `Overlay.InvalidateSlotDecorators` | [L1885](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1885) |
| `Overlay.RepaintSlotDecorators` | [L1898](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1898) |
| `Overlay.RefreshProtectionContext` | [L1913](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1913) |

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
| `Panel:FocusItem` | [L314](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L314) |
| `Panel:NotifyListChanged` | [L358](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L358) |
| `Panel:RefreshList` | [L440](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L440) |
| `Panel:SetSubTab` | [L444](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L444) |
| `Panel:Init` | [L725](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L725) |
| `panelFrameendmerchantTab.OnSelect` | [L748](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L748) |

### Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `M:IsEnabled` | [L61](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L61) |
| `M:IsConfirmLargeEnabled` | [L66](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L66) |
| `M:SetConfirmLargeEnabled` | [L71](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L71) |
| `M:OnLoad` | [L93](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L93) |
| `M:SlashHandler` | [L139](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L139) |
| `M:MerchantFrame_OnHide` | [L161](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L161) |
| `M:CogsFreeBagSpace` | [L169](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L169) |
| `M:MerchantItemButton_OnModifiedClick` | [L176](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L176) |
| `M:AltCurrencyHandling` | [L274](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L274) |
| `M:Show` | [L326](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L326) |
| `M:VerifyPurchase` | [L343](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L343) |
| `M:onUpdate` | [L374](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L374) |
| `M:DoPurchase` | [L401](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L401) |
| `M:AltCurrRounding` | [L432](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L432) |
| `M:UpdateDisplay` | [L453](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L453) |
| `M:DoConfirmation` | [L508](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L508) |
| `M:SetStackClick` | [L513](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L513) |
| `M:DeStackClick` | [L518](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L518) |
| `M:OnClick` | [L529](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L529) |
| `M:OnChar` | [L559](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L559) |
| `M:OnKeyDown` | [L588](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L588) |
| `M:Left_Click` | [L614](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L614) |
| `M:Right_Click` | [L624](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L624) |
| `M:OnEnter` | [L656](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L656) |
| `M:CreateTooltip` | [L667](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L667) |
| `M:OnLeave` | [L681](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L681) |
| `M:OnHide` | [L685](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L685) |

### Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll_Compat.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Compat.GetPurchasableBagSpace` | [L70](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll_Compat.lua#L70) |

### Inventory/Restock/Vendor/FluxAlreadyKnown.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `f:ADDON_LOADED` | [L503](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L503) |
| `f:PLAYER_ENTERING_WORLD` | [L525](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L525) |
| `SlashCmdList.ALREADYKNOWN` | [L805](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L805) |

### Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `f:ADDON_LOADED` | [L581](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L581) |
| `SlashCmdList.ALREADYKNOWN` | [L831](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L831) |
| `_hookMerchantAK.RefreshAuctionHouse` | [L857](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L857) |

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
| `FluxVendorAutoMerchantUI.MarkRestockSettingsDirty` | [L1007](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1007) |
| `FluxVendorAutoMerchantUI.IsRestockDataDirty` | [L1011](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1011) |
| `FluxVendorAutoMerchantUI.MarkJunkStatsDirty` | [L1015](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1015) |
| `FluxVendorAutoMerchantUI.IsJunkStatsDirty` | [L1019](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1019) |
| `FluxVendorAutoMerchantUI.OnJunkListChanged` | [L1527](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1527) |
| `FluxVendorAutoMerchantUI.ScheduleJunkUIRefresh` | [L1552](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1552) |
| `FluxVendorAutoMerchantUI.HookPanelCloseButton` | [L2252](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2252) |
| `FluxVendorAutoMerchantUI.OnBuyTabHidden` | [L2319](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2319) |
| `FluxVendorAutoMerchantUI.OnBuyTabShown` | [L2325](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2325) |
| `LayoutPostDFActionCluster` | [L2422](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2422) |
| `RefreshCheapJunkSlotCount` | [L2516](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2516) |
| `FluxVendorAutoMerchantUI.GetCachedSellJunkTotal` | [L2532](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2532) |
| `FluxVendorAutoMerchantUI.GetCachedJunkSlotCount` | [L2536](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2536) |
| `FluxVendorAutoMerchantUI.MarkVendorBagPulseDone` | [L2576](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2576) |
| `FluxVendorAutoMerchantUI.IsMerchantBuyTabActive` | [L2580](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2580) |
| `ApplyNativeSellJunkButtonState` | [L2584](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2584) |
| `FluxVendorAutoMerchantUI.GetCachedRestockItems` | [L2612](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2612) |
| `FluxVendorAutoMerchantUI.ApplyClassicSellJunkButtonState` | [L2616](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2616) |
| `FluxVendorAutoMerchantUI.RefreshVendorJunkDisplay` | [L2709](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2709) |
| `FluxVendorAutoMerchantUI.UpdateMerchantUI` | [L2801](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2801) |
| `FluxVendorAutoMerchantUI.NeedsMerchantUIDataRefresh` | [L2875](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2875) |
| `FluxVendorAutoMerchantUI.IsMerchantUIInitialized` | [L3017](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3017) |
| `FluxVendorAutoMerchantUI.PrewarmForVendorOpen` | [L3021](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3021) |
| `FluxVendorAutoMerchantUI.WarmJunkDisplayCacheIfNeeded` | [L3029](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3029) |
| `FluxVendorAutoMerchantUI.RunPipelineLayoutLight` | [L3088](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3088) |
| `FluxVendorAutoMerchantUI.RunIdleOpenLayout` | [L3120](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3120) |
| `FluxVendorAutoMerchantUI.RunPipelineLayoutStep` | [L3167](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3167) |
| `FluxVendorAutoMerchantUI.OnVendorOpenStormSettled` | [L3237](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3237) |
| `FluxVendorAutoMerchantUI.RunPipelineLayout` | [L3256](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3256) |
| `FluxVendorAutoMerchantUI.ApplyRestockPortraitIcon` | [L3342](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3342) |
| `FluxVendorAutoMerchantUI.ApplyJunkPortraitIcon` | [L3352](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3352) |
| `FluxVendorAutoMerchantUI.CreateRestockStyleButton` | [L3405](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3405) |
| `FluxVendorAutoMerchantUI.SetRestockButtonEnabled` | [L3411](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3411) |
| `FluxVendorAutoMerchantUI.ApplyRestockAutoToggleChrome` | [L3415](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3415) |
| `FluxVendorAutoMerchantUI.CreateRestockAutoToggle` | [L3419](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3419) |

### Inventory/Restock/Vendor/FluxVendorBuy.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `FV.AddBatchCopper` | [L108](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L108) |
| `Buy.MaybeRunAutoVendorBatch` | [L696](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L696) |
| `FV.GetMerchantIndexGeneration` | [L831](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L831) |
| `FV.GetMerchantItemIndex` | [L835](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L835) |
| `FV.IsMerchantIndexBuildPending` | [L855](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L855) |
| `FV.InvalidateMerchantIndex` | [L859](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L859) |
| `FV.RegisterMerchantIndexListener` | [L865](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L865) |
| `FV.ComputeRestockPurchaseQty` | [L1033](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1033) |
| `Buy.OnIndexReady` | [L1319](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1319) |
| `FV.IsRestockBuyActive` | [L1349](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1349) |
| `FV.IsAuctionFollowupBusy` | [L1352](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1352) |
| `FV.DoAuctionFollowup` | [L1356](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1356) |
| `FV.CanAuctionFollowup` | [L1364](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1364) |
| `FV.IsVendorBurstActive` | [L1374](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1374) |
| `FV.DoRestockManual` | [L1417](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1417) |
| `FV.TriggerAutoRestock` | [L1508](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1508) |
| `FV.RunAutoVendorBatch` | [L1557](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1557) |

### Inventory/Restock/Vendor/FluxVendorGossip.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `FV.IsVendorGossipSupported` | [L15](../../Inventory/Restock/Vendor/FluxVendorGossip.lua#L15) |
| `FV.SetGossipAutoOpen` | [L61](../../Inventory/Restock/Vendor/FluxVendorGossip.lua#L61) |
| `FV.RefreshVendorGossip` | [L144](../../Inventory/Restock/Vendor/FluxVendorGossip.lua#L144) |

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
| `Panel.InvalidateListCache` | [L271](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L271) |
| `Panel.RefreshCountsOnly` | [L275](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L275) |
| `Panel:RefreshList` | [L874](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L874) |
| `Panel:OnTabSelected` | [L942](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L942) |
| `Panel:Init` | [L1217](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1217) |
| `panelFrameendmerchantTab.OnSelect` | [L1241](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1241) |

### Inventory/SpellReagents.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Spells.IsBlacklistedReagent` | [L163](../../Inventory/SpellReagents.lua#L163) |
| `Spells.ScheduleReagentWarm` | [L753](../../Inventory/SpellReagents.lua#L753) |
| `Spells.ScheduleWarm` | [L774](../../Inventory/SpellReagents.lua#L774) |
| `Spells.Invalidate` | [L788](../../Inventory/SpellReagents.lua#L788) |
| `Spells.Refresh` | [L796](../../Inventory/SpellReagents.lua#L796) |
| `Spells.AreReagentsWarmed` | [L809](../../Inventory/SpellReagents.lua#L809) |
| `Spells.OnVisibleItemsChanged` | [L813](../../Inventory/SpellReagents.lua#L813) |
| `Spells.UsesReagents` | [L822](../../Inventory/SpellReagents.lua#L822) |
| `Spells.GetReagents` | [L832](../../Inventory/SpellReagents.lua#L832) |
| `Spells.GetReagentItemIDs` | [L838](../../Inventory/SpellReagents.lua#L838) |
| `Spells.GetReagentItemIDSet` | [L850](../../Inventory/SpellReagents.lua#L850) |
| `Spells.IsReagentItem` | [L862](../../Inventory/SpellReagents.lua#L862) |
| `Spells.GetSpellsUsingReagent` | [L892](../../Inventory/SpellReagents.lua#L892) |
| `Spells.GetSpellsUsingReagentLabeled` | [L916](../../Inventory/SpellReagents.lua#L916) |

### Inventory/Store.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Store.UsesSyndicator` | [L34](../../Inventory/Store.lua#L34) |
| `Store.SetUsesSyndicator` | [L38](../../Inventory/Store.lua#L38) |
| `Store.GetSyncDB` | [L97](../../Inventory/Store.lua#L97) |
| `Store.GetDB` | [L101](../../Inventory/Store.lua#L101) |
| `Store.GetCharacterFullName` | [L108](../../Inventory/Store.lua#L108) |
| `Store.NormalizeRecipient` | [L143](../../Inventory/Store.lua#L143) |
| `Store.GetCurrentCharacterName` | [L169](../../Inventory/Store.lua#L169) |
| `Store.GetCharacter` | [L179](../../Inventory/Store.lua#L179) |
| `Store.GetAllCharacters` | [L194](../../Inventory/Store.lua#L194) |
| `Store.HasCharacter` | [L210](../../Inventory/Store.lua#L210) |
| `Store.GetGuild` | [L214](../../Inventory/Store.lua#L214) |
| `Store.GetAllGuilds` | [L228](../../Inventory/Store.lua#L228) |
| `Store.GetCurrentGuildName` | [L243](../../Inventory/Store.lua#L243) |
| `Store.GetWarband` | [L255](../../Inventory/Store.lua#L255) |
| `Store.GetCurrentCharacter` | [L285](../../Inventory/Store.lua#L285) |
| `Store.EnsureCurrentCharacter` | [L293](../../Inventory/Store.lua#L293) |
| `Store.EnsureGuild` | [L339](../../Inventory/Store.lua#L339) |
| `Store.SetCurrentGuild` | [L366](../../Inventory/Store.lua#L366) |
| `Store.BindLive` | [L374](../../Inventory/Store.lua#L374) |
| `Store.BindWarbandBank` | [L385](../../Inventory/Store.lua#L385) |
| `Store.MarkPending` | [L395](../../Inventory/Store.lua#L395) |
| `Store.MarkGuildPending` | [L412](../../Inventory/Store.lua#L412) |
| `Store.MarkWarbandPending` | [L419](../../Inventory/Store.lua#L419) |
| `Store.TakeCharacterPending` | [L430](../../Inventory/Store.lua#L430) |
| `Store.TakeGuildPending` | [L444](../../Inventory/Store.lua#L444) |
| `Store.TakeWarbandPending` | [L458](../../Inventory/Store.lua#L458) |
| `Store.PendingBags` | [L472](../../Inventory/Store.lua#L472) |
| `Store.PendingAll` | [L476](../../Inventory/Store.lua#L476) |
| `Store.SetCurrentMoney` | [L480](../../Inventory/Store.lua#L480) |
| `Store.SetWarbandMoney` | [L499](../../Inventory/Store.lua#L499) |
| `Store.SetGoldHidden` | [L515](../../Inventory/Store.lua#L515) |
| `Store.GetConnectedRealms` | [L523](../../Inventory/Store.lua#L523) |
| `Store.GetItemKey` | [L545](../../Inventory/Store.lua#L545) |
| `Store.GetItemKeyByItemID` | [L563](../../Inventory/Store.lua#L563) |
| `Store.ImportGoldLedgerStubs` | [L571](../../Inventory/Store.lua#L571) |
| `Store.IsGoldDeleted` | [L639](../../Inventory/Store.lua#L639) |
| `Store.HydrateSnapshots` | [L698](../../Inventory/Store.lua#L698) |

### Inventory/Summaries.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Summaries.GetTooltipInfo` | [L222](../../Inventory/Summaries.lua#L222) |
| `Summaries.GetTooltipInfoByItemID` | [L301](../../Inventory/Summaries.lua#L301) |
| `Summaries.GetTooltipInfoByLink` | [L313](../../Inventory/Summaries.lua#L313) |

### Inventory/Syndicator/Adapter.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Adapter.RebuildBags` | [L176](../../Inventory/Syndicator/Adapter.lua#L176) |
| `Adapter.RebuildBank` | [L229](../../Inventory/Syndicator/Adapter.lua#L229) |
| `Adapter.GetLastBagsChangeKind` | [L281](../../Inventory/Syndicator/Adapter.lua#L281) |
| `Adapter.GetLastBagsAddedItemIDs` | [L285](../../Inventory/Syndicator/Adapter.lua#L285) |
| `Adapter.GetLastBagsRemovedItemIDs` | [L289](../../Inventory/Syndicator/Adapter.lua#L289) |
| `Adapter.GetLastBagsDirtyBags` | [L293](../../Inventory/Syndicator/Adapter.lua#L293) |
| `Adapter.GetLastBankChangeKind` | [L297](../../Inventory/Syndicator/Adapter.lua#L297) |
| `Adapter.GetLastBankAddedItemIDs` | [L301](../../Inventory/Syndicator/Adapter.lua#L301) |
| `Adapter.GetLastBankRemovedItemIDs` | [L305](../../Inventory/Syndicator/Adapter.lua#L305) |
| `Adapter.GetLastBankDirtyBags` | [L309](../../Inventory/Syndicator/Adapter.lua#L309) |
| `Adapter.TakeBagsItemSets` | [L313](../../Inventory/Syndicator/Adapter.lua#L313) |
| `Adapter.TakeBankItemSets` | [L317](../../Inventory/Syndicator/Adapter.lua#L317) |
| `Adapter.RebuildWarband` | [L321](../../Inventory/Syndicator/Adapter.lua#L321) |
| `Adapter.RebuildEquip` | [L346](../../Inventory/Syndicator/Adapter.lua#L346) |
| `Adapter.RebuildMail` | [L430](../../Inventory/Syndicator/Adapter.lua#L430) |
| `Adapter.RebuildVoid` | [L440](../../Inventory/Syndicator/Adapter.lua#L440) |
| `Adapter.RebuildAuctions` | [L458](../../Inventory/Syndicator/Adapter.lua#L458) |
| `Adapter.RebuildGuild` | [L466](../../Inventory/Syndicator/Adapter.lua#L466) |
| `Adapter.RebuildCurrencies` | [L488](../../Inventory/Syndicator/Adapter.lua#L488) |
| `Adapter.RebuildWarbandCurrency` | [L513](../../Inventory/Syndicator/Adapter.lua#L513) |
| `Adapter.RebuildAll` | [L524](../../Inventory/Syndicator/Adapter.lua#L524) |
| `Adapter.Start` | [L733](../../Inventory/Syndicator/Adapter.lua#L733) |

### Inventory/Syndicator/Sync.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Sync.Restore` | [L103](../../Inventory/Syndicator/Sync.lua#L103) |
| `Sync.NoteCapacity` | [L122](../../Inventory/Syndicator/Sync.lua#L122) |
| `Sync.Bind` | [L310](../../Inventory/Syndicator/Sync.lua#L310) |

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

### Mail/CategoryAttach.lua

Owner: [34-assets.md](../34-assets.md).

| Declaration | Source |
|---|---|
| `Mail.AttachCategory` | [L80](../../Mail/CategoryAttach.lua#L80) |

### Mail/Contacts.lua

Owner: [34-assets.md](../34-assets.md).

| Declaration | Source |
|---|---|
| `Mail.AddContact` | [L48](../../Mail/Contacts.lua#L48) |
| `Mail.RemoveContact` | [L55](../../Mail/Contacts.lua#L55) |
| `Mail.RecordRecipient` | [L62](../../Mail/Contacts.lua#L62) |
| `Mail.GetRecipients` | [L94](../../Mail/Contacts.lua#L94) |
| `Mail.FillDraft` | [L132](../../Mail/Contacts.lua#L132) |

### Mail/Conveniences.lua

Owner: [34-assets.md](../34-assets.md).

| Declaration | Source |
|---|---|
| `Mail.ForwardOpenText` | [L139](../../Mail/Conveniences.lua#L139) |

### Mail/OpenAll.lua

Owner: [34-assets.md](../34-assets.md).

| Declaration | Source |
|---|---|
| `Mail.OpenAll` | [L75](../../Mail/OpenAll.lua#L75) |
| `Mail.OnJobStateChangedMail.OnJobStateChanged` | [L92](../../Mail/OpenAll.lua#L92) |

### Mail/QuickAttach.lua

Owner: [34-assets.md](../34-assets.md).

| Declaration | Source |
|---|---|
| `Mail.AttachBagItem` | [L29](../../Mail/QuickAttach.lua#L29) |

### Mail/Restock.lua

Owner: [34-assets.md](../34-assets.md).

| Declaration | Source |
|---|---|
| `Mail.TakeRestockItems` | [L155](../../Mail/Restock.lua#L155) |
| `Mail.IsRestockContextOpen` | [L161](../../Mail/Restock.lua#L161) |
| `Mail.CanTakeRestockItems` | [L164](../../Mail/Restock.lua#L164) |
| `Mail.OnJobStateChangedMail.OnJobStateChanged` | [L191](../../Mail/Restock.lua#L191) |

### Mail/Select.lua

Owner: [34-assets.md](../34-assets.md).

| Declaration | Source |
|---|---|
| `Mail.GetJobGroup` | [L339](../../Mail/Select.lua#L339) |
| `Mail.NotifyRestockSnapshotReady` | [L340](../../Mail/Select.lua#L340) |
| `Mail.StopRestockItems` | [L345](../../Mail/Select.lua#L345) |
| `Mail.ProcessRestockItems` | [L348](../../Mail/Select.lua#L348) |
| `Mail.ProcessSelected` | [L377](../../Mail/Select.lua#L377) |
| `Mail.TakeSelected` | [L400](../../Mail/Select.lua#L400) |

### Mail/Settings.lua

Owner: [34-assets.md](../34-assets.md).

| Declaration | Source |
|---|---|
| `Mail.GetProfileName` | [L58](../../Mail/Settings.lua#L58) |
| `Mail.SwitchProfile` | [L60](../../Mail/Settings.lua#L60) |
| `Mail.CopyProfile` | [L71](../../Mail/Settings.lua#L71) |
| `Mail.ResetProfile` | [L79](../../Mail/Settings.lua#L79) |
| `Mail.DeleteProfile` | [L84](../../Mail/Settings.lua#L84) |
| `Mail.GetSetting` | [L91](../../Mail/Settings.lua#L91) |
| `Mail.SetSetting` | [L103](../../Mail/Settings.lua#L103) |
| `Mail.IsEnabled` | [L120](../../Mail/Settings.lua#L120) |
| `Mail.Print` | [L124](../../Mail/Settings.lua#L124) |
| `Mail.OnSettingsChanged` | [L130](../../Mail/Settings.lua#L130) |
| `Mail.OpenSettingsMenu` | [L135](../../Mail/Settings.lua#L135) |
| `Mail.OpenModuleMenu` | [L141](../../Mail/Settings.lua#L141) |

### MicroMenu/FluxAddonMicroButton.lua

Owner: [17-micromenu.md](../17-micromenu.md).

| Declaration | Source |
|---|---|
| `FluxAddonSystem.GetMinimapScanRoots` | [L210](../../MicroMenu/FluxAddonMicroButton.lua#L210) |
| `FluxAddonSystem:Scan` | [L349](../../MicroMenu/FluxAddonMicroButton.lua#L349) |
| `FluxAddonSystem:UpdateLayout` | [L363](../../MicroMenu/FluxAddonMicroButton.lua#L363) |
| `FluxAddonSystem.ClampPopupToScreenAndMicroMenu` | [L465](../../MicroMenu/FluxAddonMicroButton.lua#L465) |
| `FluxAddonSystem:ClampContainerToScreen` | [L539](../../MicroMenu/FluxAddonMicroButton.lua#L539) |
| `FluxAddonPopup_RefreshAccent` | [L659](../../MicroMenu/FluxAddonMicroButton.lua#L659) |

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
| `FluxMicroMenu:IsNativeRowAvailableOnClient` | [L1084](../../MicroMenu/FluxMicroMenu.lua#L1084) |
| `FluxMicroMenu:GetDefaultUnifiedRowIds` | [L1121](../../MicroMenu/FluxMicroMenu.lua#L1121) |
| `FluxMicroMenu:GetLayoutSpacing` | [L1185](../../MicroMenu/FluxMicroMenu.lua#L1185) |
| `FluxMicroMenu:GetButtonSizeScale` | [L1204](../../MicroMenu/FluxMicroMenu.lua#L1204) |
| `_G.FluxMicroMenu_GetBesideChatColumnRightX` | [L1450](../../MicroMenu/FluxMicroMenu.lua#L1450) |
| `FluxMicroMenu:RefreshLayout` | [L2617](../../MicroMenu/FluxMicroMenu.lua#L2617) |
| `FluxMicroMenu:Rebuild` | [L2983](../../MicroMenu/FluxMicroMenu.lua#L2983) |

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
| `operation.run` | [L1141](../../MicroMenu/FluxMinimapToMicro.lua#L1141) |
| `M:RebuildMicroButtons` | [L1229](../../MicroMenu/FluxMinimapToMicro.lua#L1229) |
| `M:CreateMicroButtonForMinimap` | [L1259](../../MicroMenu/FluxMinimapToMicro.lua#L1259) |
| `M:ShouldHideFromLeftPopup` | [L1303](../../MicroMenu/FluxMinimapToMicro.lua#L1303) |
| `M:GetEnabledButtonNames` | [L1308](../../MicroMenu/FluxMinimapToMicro.lua#L1308) |
| `FluxMinimapToMicro_RefreshPopupAccent` | [L1414](../../MicroMenu/FluxMinimapToMicro.lua#L1414) |

### MicroMenu/FluxTradeSkillMicro.lua

Owner: [17-micromenu.md](../17-micromenu.md).

| Declaration | Source |
|---|---|
| `M:GetDB` | [L93](../../MicroMenu/FluxTradeSkillMicro.lua#L93) |
| `M:IsEnabled` | [L98](../../MicroMenu/FluxTradeSkillMicro.lua#L98) |
| `M:EnsureRowVisible` | [L104](../../MicroMenu/FluxTradeSkillMicro.lua#L104) |
| `M:BootstrapVisibilityIfNeeded` | [L111](../../MicroMenu/FluxTradeSkillMicro.lua#L111) |
| `M:MakeKey` | [L140](../../MicroMenu/FluxTradeSkillMicro.lua#L140) |
| `M:SafeGlobalKey` | [L158](../../MicroMenu/FluxTradeSkillMicro.lua#L158) |
| `M:GetIndividualGlobalName` | [L162](../../MicroMenu/FluxTradeSkillMicro.lua#L162) |
| `M:GetFlyoutGlobalName` | [L166](../../MicroMenu/FluxTradeSkillMicro.lua#L166) |
| `M:GetSkillDisplayName` | [L170](../../MicroMenu/FluxTradeSkillMicro.lua#L170) |
| `M:IsSkillKnown` | [L184](../../MicroMenu/FluxTradeSkillMicro.lua#L184) |
| `M:ShouldKeepRowInOrder` | [L194](../../MicroMenu/FluxTradeSkillMicro.lua#L194) |
| `M:EnumerateSkills` | [L300](../../MicroMenu/FluxTradeSkillMicro.lua#L300) |
| `M:GetLearnedSkills` | [L386](../../MicroMenu/FluxTradeSkillMicro.lua#L386) |
| `M:ResolvePlacement` | [L397](../../MicroMenu/FluxTradeSkillMicro.lua#L397) |
| `M:ShouldShowFlyoutButton` | [L451](../../MicroMenu/FluxTradeSkillMicro.lua#L451) |
| `M:IsIndividualOnBar` | [L457](../../MicroMenu/FluxTradeSkillMicro.lua#L457) |
| `M:IsRowActiveOnBar` | [L467](../../MicroMenu/FluxTradeSkillMicro.lua#L467) |
| `M:GetActiveBarRowIds` | [L483](../../MicroMenu/FluxTradeSkillMicro.lua#L483) |
| `M:MigrateSavedRowKeys` | [L556](../../MicroMenu/FluxTradeSkillMicro.lua#L556) |
| `M:OpenSkill` | [L625](../../MicroMenu/FluxTradeSkillMicro.lua#L625) |
| `M:OpenSkillByKey` | [L661](../../MicroMenu/FluxTradeSkillMicro.lua#L661) |
| `M:UpdateFlyoutLayout` | [L727](../../MicroMenu/FluxTradeSkillMicro.lua#L727) |
| `M:ClampFlyoutToScreen` | [L799](../../MicroMenu/FluxTradeSkillMicro.lua#L799) |
| `M:ToggleFlyout` | [L858](../../MicroMenu/FluxTradeSkillMicro.lua#L858) |
| `M:HideFlyout` | [L890](../../MicroMenu/FluxTradeSkillMicro.lua#L890) |
| `M:EnsureIndividualButton` | [L905](../../MicroMenu/FluxTradeSkillMicro.lua#L905) |
| `M:EnsureFlyoutButton` | [L944](../../MicroMenu/FluxTradeSkillMicro.lua#L944) |
| `M:SyncButtons` | [L989](../../MicroMenu/FluxTradeSkillMicro.lua#L989) |
| `M:Refresh` | [L1037](../../MicroMenu/FluxTradeSkillMicro.lua#L1037) |

### Minimap/FluxBuffDebuffFrames.lua

Owner: [18-minimap-and-trackers.md](../18-minimap-and-trackers.md).

| Declaration | Source |
|---|---|
| `M:PositionBuffFrames` | [L27](../../Minimap/FluxBuffDebuffFrames.lua#L27) |
| `M:RefreshBlizzardAuraFrames` | [L51](../../Minimap/FluxBuffDebuffFrames.lua#L51) |
| `M:TryInstallBlizzardAuraSqueezeHooks` | [L63](../../Minimap/FluxBuffDebuffFrames.lua#L63) |
| `M:RefreshBlizzardBuffDebuffSqueeze` | [L66](../../Minimap/FluxBuffDebuffFrames.lua#L66) |
| `M:HookConsolidatedBuffs` | [L69](../../Minimap/FluxBuffDebuffFrames.lua#L69) |
| `M:InstallOnMinimap` | [L72](../../Minimap/FluxBuffDebuffFrames.lua#L72) |
| `ifnotminimapthenreturnendminimap.RefreshBlizzardAuraFrames` | [L76](../../Minimap/FluxBuffDebuffFrames.lua#L76) |
| `endminimap.TryInstallBlizzardAuraSqueezeHooks` | [L79](../../Minimap/FluxBuffDebuffFrames.lua#L79) |
| `endminimap.RefreshBlizzardBuffDebuffSqueeze` | [L82](../../Minimap/FluxBuffDebuffFrames.lua#L82) |
| `endminimap.PositionBuffFrames` | [L85](../../Minimap/FluxBuffDebuffFrames.lua#L85) |

### Minimap/FluxMinimap.lua

Owner: [18-minimap-and-trackers.md](../18-minimap-and-trackers.md).

| Declaration | Source |
|---|---|
| `FluxMinimap:Initialize` | [L303](../../Minimap/FluxMinimap.lua#L303) |
| `FluxMinimap:RunEnforcerPass` | [L312](../../Minimap/FluxMinimap.lua#L312) |
| `FluxMinimap:RequestEnforcerBurst` | [L320](../../Minimap/FluxMinimap.lua#L320) |
| `FluxMinimap:CancelEnforcerTicker` | [L328](../../Minimap/FluxMinimap.lua#L328) |
| `FluxMinimap:EnsureEnforcerTicker` | [L337](../../Minimap/FluxMinimap.lua#L337) |
| `FluxMinimap.GetEnforcerBurstRemaining` | [L364](../../Minimap/FluxMinimap.lua#L364) |
| `FluxMinimap:Initialize` | [L373](../../Minimap/FluxMinimap.lua#L373) |
| `FluxMinimap_ApplyAppearanceAccent` | [L457](../../Minimap/FluxMinimap.lua#L457) |
| `FluxMinimap:UpdateStyle` | [L477](../../Minimap/FluxMinimap.lua#L477) |
| `FluxMinimap:CleanupBlizzardFrames` | [L491](../../Minimap/FluxMinimap.lua#L491) |
| `FluxMinimap:CleanupTimeManager` | [L577](../../Minimap/FluxMinimap.lua#L577) |
| `FluxMinimap:EnforcePosition` | [L592](../../Minimap/FluxMinimap.lua#L592) |
| `FluxMinimap:PositionIndicators` | [L634](../../Minimap/FluxMinimap.lua#L634) |
| `FluxMinimap:PositionQueueStatusEye` | [L1105](../../Minimap/FluxMinimap.lua#L1105) |
| `FluxMinimap:EnsureQueueStatusEyeHooks` | [L1151](../../Minimap/FluxMinimap.lua#L1151) |
| `FluxMinimap:HookQuestWatchFramePositioning` | [L1233](../../Minimap/FluxMinimap.lua#L1233) |
| `QuestWatchFrame.SetPointQuestWatchFrame.SetPoint` | [L1268](../../Minimap/FluxMinimap.lua#L1268) |
| `WatchFrame.SetPointWatchFrame.SetPoint` | [L1290](../../Minimap/FluxMinimap.lua#L1290) |
| `FluxMinimap:UpdateQuestTrackerPosition` | [L1303](../../Minimap/FluxMinimap.lua#L1303) |
| `FluxMinimap:HandleEditMode` | [L1660](../../Minimap/FluxMinimap.lua#L1660) |
| `FluxMinimap:CreateInfoBar` | [L1804](../../Minimap/FluxMinimap.lua#L1804) |
| `FluxMinimap:ApplyInfoBarZoneTextFit` | [L1994](../../Minimap/FluxMinimap.lua#L1994) |
| `FluxMinimap:OnInfoBarZoneHitEnter` | [L2033](../../Minimap/FluxMinimap.lua#L2033) |
| `FluxMinimap:OnInfoBarZoneHitLeave` | [L2068](../../Minimap/FluxMinimap.lua#L2068) |
| `FluxMinimap:UpdateInfoBarZoneScroll` | [L2085](../../Minimap/FluxMinimap.lua#L2085) |
| `FluxMinimap:RefreshInfoBarZoneFit` | [L2135](../../Minimap/FluxMinimap.lua#L2135) |
| `FluxMinimap:UpdateInfoBarZone` | [L2139](../../Minimap/FluxMinimap.lua#L2139) |
| `FluxMinimap:UpdateInfoBarTime` | [L2176](../../Minimap/FluxMinimap.lua#L2176) |
| `FluxMinimap:EmbedInFrame` | [L2210](../../Minimap/FluxMinimap.lua#L2210) |
| `FluxMinimap:RefreshEmbeddedLayout` | [L2462](../../Minimap/FluxMinimap.lua#L2462) |
| `FluxMinimap:CalculateEmbeddedMapSize` | [L2495](../../Minimap/FluxMinimap.lua#L2495) |
| `FluxMinimap:RestoreToNormal` | [L2502](../../Minimap/FluxMinimap.lua#L2502) |
| `FluxMinimap:IsEmbedded` | [L2642](../../Minimap/FluxMinimap.lua#L2642) |
| `FluxMinimap:GetNormalWidth` | [L2647](../../Minimap/FluxMinimap.lua#L2647) |
| `FluxMinimap:HideEmbedded` | [L2659](../../Minimap/FluxMinimap.lua#L2659) |
| `FluxMinimap:ShowEmbedded` | [L2684](../../Minimap/FluxMinimap.lua#L2684) |
| `FluxMinimap.NotifyInfoFrameLayoutChanged` | [L2706](../../Minimap/FluxMinimap.lua#L2706) |
| `FluxMinimap:Refresh` | [L2719](../../Minimap/FluxMinimap.lua#L2719) |
| `Tracking.IsActive` | [L2821](../../Minimap/FluxMinimap.lua#L2821) |
| `Tracking.SetActive` | [L2827](../../Minimap/FluxMinimap.lua#L2827) |

### Minimap/FluxMinimapButtons.lua

Owner: [18-minimap-and-trackers.md](../18-minimap-and-trackers.md).

| Declaration | Source |
|---|---|
| `M:GetSetting` | [L71](../../Minimap/FluxMinimapButtons.lua#L71) |
| `M:SetSetting` | [L86](../../Minimap/FluxMinimapButtons.lua#L86) |
| `M:CanHideInCombat` | [L97](../../Minimap/FluxMinimapButtons.lua#L97) |
| `M:QueueRefresh` | [L274](../../Minimap/FluxMinimapButtons.lua#L274) |
| `M:OnAssignmentChanged` | [L285](../../Minimap/FluxMinimapButtons.lua#L285) |
| `btn.OnReceiveDragCallback` | [L336](../../Minimap/FluxMinimapButtons.lua#L336) |
| `endbtn.OnMacroRebound` | [L343](../../Minimap/FluxMinimapButtons.lua#L343) |
| `endbtn.OnDelete` | [L347](../../Minimap/FluxMinimapButtons.lua#L347) |
| `M:CreateContainer` | [L362](../../Minimap/FluxMinimapButtons.lua#L362) |
| `M:CreateButtons` | [L375](../../Minimap/FluxMinimapButtons.lua#L375) |
| `M:RefreshButtons` | [L388](../../Minimap/FluxMinimapButtons.lua#L388) |
| `M:GetSideWidth` | [L452](../../Minimap/FluxMinimapButtons.lua#L452) |
| `M:GetMinimapOffset` | [L459](../../Minimap/FluxMinimapButtons.lua#L459) |
| `M:GetTrackerOffset` | [L465](../../Minimap/FluxMinimapButtons.lua#L465) |
| `M:GetEmbeddedWidthReserve` | [L473](../../Minimap/FluxMinimapButtons.lua#L473) |
| `M:LayoutSlots` | [L477](../../Minimap/FluxMinimapButtons.lua#L477) |
| `M:UpdateSideBorder` | [L553](../../Minimap/FluxMinimapButtons.lua#L553) |
| `M:RefreshAppearanceAccent` | [L584](../../Minimap/FluxMinimapButtons.lua#L584) |
| `M:Show` | [L658](../../Minimap/FluxMinimapButtons.lua#L658) |
| `M:Hide` | [L665](../../Minimap/FluxMinimapButtons.lua#L665) |
| `M:IsShown` | [L678](../../Minimap/FluxMinimapButtons.lua#L678) |
| `M:PositionInWindow` | [L682](../../Minimap/FluxMinimapButtons.lua#L682) |
| `M:OnEmbedStateChanged` | [L689](../../Minimap/FluxMinimapButtons.lua#L689) |
| `M:RefreshLayout` | [L694](../../Minimap/FluxMinimapButtons.lua#L694) |
| `M:RequestRefresh` | [L721](../../Minimap/FluxMinimapButtons.lua#L721) |
| `M:Initialize` | [L743](../../Minimap/FluxMinimapButtons.lua#L743) |

### Minimap/FluxObjectiveTrackerScroll.lua

Owner: [18-minimap-and-trackers.md](../18-minimap-and-trackers.md).

| Declaration | Source |
|---|---|
| `FluxObjectiveTrackerScroll:UpdateQuestieVisibility` | [L76](../../Minimap/FluxObjectiveTrackerScroll.lua#L76) |
| `FluxObjectiveTrackerScroll.IsActiveFor` | [L192](../../Minimap/FluxObjectiveTrackerScroll.lua#L192) |
| `FluxObjectiveTrackerScroll:GetQuestTimer` | [L196](../../Minimap/FluxObjectiveTrackerScroll.lua#L196) |
| `FluxObjectiveTrackerScroll:PinTopModulePadding` | [L203](../../Minimap/FluxObjectiveTrackerScroll.lua#L203) |
| `FluxObjectiveTrackerScroll:PinLayoutHeight` | [L212](../../Minimap/FluxObjectiveTrackerScroll.lua#L212) |
| `FluxObjectiveTrackerScroll:ReassertDock` | [L259](../../Minimap/FluxObjectiveTrackerScroll.lua#L259) |
| `FluxObjectiveTrackerScroll:RecoverStuckDirty` | [L307](../../Minimap/FluxObjectiveTrackerScroll.lua#L307) |
| `FluxObjectiveTrackerScroll:CollapseModuleTopGap` | [L321](../../Minimap/FluxObjectiveTrackerScroll.lua#L321) |
| `FluxObjectiveTrackerScroll:AnchorHeader` | [L344](../../Minimap/FluxObjectiveTrackerScroll.lua#L344) |
| `mixin:ShouldDisplayQuest` | [L426](../../Minimap/FluxObjectiveTrackerScroll.lua#L426) |
| `tracker:BuildQuestWatchInfos` | [L445](../../Minimap/FluxObjectiveTrackerScroll.lua#L445) |
| `tracker:UpdateSingle` | [L481](../../Minimap/FluxObjectiveTrackerScroll.lua#L481) |
| `_G.SetQuestTitleLevelAndDifficultyColor_G.SetQuestTitleLevelAndDifficultyColor` | [L506](../../Minimap/FluxObjectiveTrackerScroll.lua#L506) |
| `ObjectiveTrackerBlockMixin:UpdateHighlight` | [L539](../../Minimap/FluxObjectiveTrackerScroll.lua#L539) |
| `FluxObjectiveTrackerScroll:DockQuestTimer` | [L553](../../Minimap/FluxObjectiveTrackerScroll.lua#L553) |
| `FluxObjectiveTrackerScroll:MeasureContentHeight` | [L672](../../Minimap/FluxObjectiveTrackerScroll.lua#L672) |
| `FluxObjectiveTrackerScroll:AnchorTrackerRightInScroll` | [L687](../../Minimap/FluxObjectiveTrackerScroll.lua#L687) |
| `FluxObjectiveTrackerScroll:SizeScrollContent` | [L704](../../Minimap/FluxObjectiveTrackerScroll.lua#L704) |
| `FluxObjectiveTrackerScroll:SettleTrackerHeight` | [L755](../../Minimap/FluxObjectiveTrackerScroll.lua#L755) |
| `FluxObjectiveTrackerScroll:EnsureVisibleBody` | [L789](../../Minimap/FluxObjectiveTrackerScroll.lua#L789) |
| `FluxObjectiveTrackerScroll:QueueFullLayout` | [L816](../../Minimap/FluxObjectiveTrackerScroll.lua#L816) |
| `FluxObjectiveTrackerScroll:LayoutScrollArea` | [L847](../../Minimap/FluxObjectiveTrackerScroll.lua#L847) |
| `FluxObjectiveTrackerScroll:_DoSyncAfterUpdate` | [L914](../../Minimap/FluxObjectiveTrackerScroll.lua#L914) |
| `FluxObjectiveTrackerScroll:SyncAfterUpdate` | [L1001](../../Minimap/FluxObjectiveTrackerScroll.lua#L1001) |
| `ObjectiveTrackerContainerMixin.UpdateObjectiveTrackerContainerMixin.Update` | [L1161](../../Minimap/FluxObjectiveTrackerScroll.lua#L1161) |
| `self._fluxSecureDirtyCbthencallback` | [L1165](../../Minimap/FluxObjectiveTrackerScroll.lua#L1165) |
| `FluxObjectiveTrackerScroll:StartForeverLoginPulse` | [L1295](../../Minimap/FluxObjectiveTrackerScroll.lua#L1295) |
| `FluxObjectiveTrackerScroll:InstallForeverCompat` | [L1330](../../Minimap/FluxObjectiveTrackerScroll.lua#L1330) |
| `FluxObjectiveTrackerScroll:ReadyForScrollDock` | [L1346](../../Minimap/FluxObjectiveTrackerScroll.lua#L1346) |
| `FluxObjectiveTrackerScroll:KickScrollLayoutOnce` | [L1362](../../Minimap/FluxObjectiveTrackerScroll.lua#L1362) |
| `FluxObjectiveTrackerScroll:EnsureViewport` | [L1382](../../Minimap/FluxObjectiveTrackerScroll.lua#L1382) |
| `outerViewport:ToggleCollapsed` | [L1427](../../Minimap/FluxObjectiveTrackerScroll.lua#L1427) |
| `FluxObjectiveTrackerScroll:ApplyViewportSize` | [L1498](../../Minimap/FluxObjectiveTrackerScroll.lua#L1498) |
| `FluxObjectiveTrackerScroll:RefreshLayout` | [L1519](../../Minimap/FluxObjectiveTrackerScroll.lua#L1519) |

### Minimap/FluxQuestie.lua

Owner: [18-minimap-and-trackers.md](../18-minimap-and-trackers.md).

| Declaration | Source |
|---|---|
| `FluxQuestie:IsTrackerEnabled` | [L57](../../Minimap/FluxQuestie.lua#L57) |
| `FluxQuestie:RequestLayout` | [L64](../../Minimap/FluxQuestie.lua#L64) |
| `FluxQuestie:HookHeader` | [L84](../../Minimap/FluxQuestie.lua#L84) |
| `FluxQuestie:Initialize` | [L92](../../Minimap/FluxQuestie.lua#L92) |
| `FluxQuestie:UpdateLayout` | [L139](../../Minimap/FluxQuestie.lua#L139) |
| `FluxQuestie:ReleaseQuestTimer` | [L185](../../Minimap/FluxQuestie.lua#L185) |
| `FluxQuestie:DockQuestTimer` | [L194](../../Minimap/FluxQuestie.lua#L194) |
| `FluxQuestie:UpdateScrollRange` | [L228](../../Minimap/FluxQuestie.lua#L228) |
| `FluxQuestie:StyleBaseFrame` | [L249](../../Minimap/FluxQuestie.lua#L249) |
| `FluxQuestie:SizeQuestFrame` | [L331](../../Minimap/FluxQuestie.lua#L331) |
| `FluxQuestie:StyleLines` | [L404](../../Minimap/FluxQuestie.lua#L404) |

### NamePlates/CastBarSchools.lua

Owner: [19-nameplates.md](../19-nameplates.md).

| Declaration | Source |
|---|---|
| `module.Added` | [L81](../../NamePlates/CastBarSchools.lua#L81) |
| `module.Removed` | [L116](../../NamePlates/CastBarSchools.lua#L116) |
| `module.Refresh` | [L125](../../NamePlates/CastBarSchools.lua#L125) |
| `module.Poll` | [L135](../../NamePlates/CastBarSchools.lua#L135) |

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
| `NP.IsClassicFamily` | [L26](../../NamePlates/Core.lua#L26) |
| `NP.IsSecretClient` | [L43](../../NamePlates/Core.lua#L43) |
| `NP.IsLiveClient` | [L52](../../NamePlates/Core.lua#L52) |
| `NP.PlateTextOffsetY` | [L61](../../NamePlates/Core.lua#L61) |
| `NP.IsThreatSupported` | [L72](../../NamePlates/Core.lua#L72) |
| `NP.IsLevelSupported` | [L76](../../NamePlates/Core.lua#L76) |
| `NP.GetDB` | [L95](../../NamePlates/Core.lua#L95) |
| `NP.IsSecret` | [L125](../../NamePlates/Core.lua#L125) |
| `NP.IsUsable` | [L142](../../NamePlates/Core.lua#L142) |
| `NP.BoolTest` | [L154](../../NamePlates/Core.lua#L154) |
| `NP.GetPlate` | [L171](../../NamePlates/Core.lua#L171) |
| `NP.GetParts` | [L188](../../NamePlates/Core.lua#L188) |
| `NP.CreateHost` | [L213](../../NamePlates/Core.lua#L213) |
| `NP.AttachHost` | [L223](../../NamePlates/Core.lua#L223) |
| `NP.ReleaseHost` | [L239](../../NamePlates/Core.lua#L239) |
| `NP.UsesClassicHealthBar` | [L248](../../NamePlates/Core.lua#L248) |
| `NP.CreateClientPlate` | [L279](../../NamePlates/Core.lua#L279) |
| `NP.FitPlate` | [L294](../../NamePlates/Core.lua#L294) |
| `NP.IsUnitTarget` | [L313](../../NamePlates/Core.lua#L313) |
| `NP.ShowPlate` | [L321](../../NamePlates/Core.lua#L321) |
| `NP.SetThreatTint` | [L345](../../NamePlates/Core.lua#L345) |
| `NP.ThreatTint` | [L358](../../NamePlates/Core.lua#L358) |
| `NP.TintPlateChrome` | [L418](../../NamePlates/Core.lua#L418) |
| `NP.ResetPlateChrome` | [L438](../../NamePlates/Core.lua#L438) |
| `NP.RegisterModule` | [L477](../../NamePlates/Core.lua#L477) |
| `NP.RefreshUnit` | [L549](../../NamePlates/Core.lua#L549) |
| `NP.RefreshAll` | [L555](../../NamePlates/Core.lua#L555) |
| `Quest.Added` | [L926](../../NamePlates/Core.lua#L926) |
| `Quest.Removed` | [L929](../../NamePlates/Core.lua#L929) |
| `Quest.Refresh` | [L933](../../NamePlates/Core.lua#L933) |
| `Quest.RefreshAll` | [L934](../../NamePlates/Core.lua#L934) |
| `Quest.Poll` | [L943](../../NamePlates/Core.lua#L943) |

### NamePlates/Countdown.lua

Owner: [19-nameplates.md](../19-nameplates.md).

| Declaration | Source |
|---|---|
| `Countdown.Added` | [L266](../../NamePlates/Countdown.lua#L266) |
| `Countdown.Removed` | [L270](../../NamePlates/Countdown.lua#L270) |
| `Countdown.Refresh` | [L274](../../NamePlates/Countdown.lua#L274) |
| `Countdown.Poll` | [L278](../../NamePlates/Countdown.lua#L278) |

### NamePlates/Level.lua

Owner: [19-nameplates.md](../19-nameplates.md).

| Declaration | Source |
|---|---|
| `Level.Added` | [L224](../../NamePlates/Level.lua#L224) |
| `Level.Removed` | [L230](../../NamePlates/Level.lua#L230) |
| `Level.Refresh` | [L240](../../NamePlates/Level.lua#L240) |
| `Level.Poll` | [L246](../../NamePlates/Level.lua#L246) |

### NamePlates/Threat.lua

Owner: [19-nameplates.md](../19-nameplates.md).

| Declaration | Source |
|---|---|
| `NP.GetThreatPlateWidth` | [L20](../../NamePlates/Threat.lua#L20) |
| `Threat.Added` | [L293](../../NamePlates/Threat.lua#L293) |
| `Threat.Removed` | [L297](../../NamePlates/Threat.lua#L297) |
| `Threat.Refresh` | [L310](../../NamePlates/Threat.lua#L310) |
| `Threat.Poll` | [L314](../../NamePlates/Threat.lua#L314) |

### Other/FluxChatColumnMicros.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `true_G.CharacterFrame_OnShow` | [L594](../../Other/FluxChatColumnMicros.lua#L594) |
| `true_G.CharacterFrame_OnHide` | [L601](../../Other/FluxChatColumnMicros.lua#L601) |
| `FluxChatColumnMicros.Create` | [L1310](../../Other/FluxChatColumnMicros.lua#L1310) |

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

### Other/FluxCooldownDefaults.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `Defaults.IsAvailable` | [L33](../../Other/FluxCooldownDefaults.lua#L33) |
| `Defaults.BuildPlan` | [L57](../../Other/FluxCooldownDefaults.lua#L57) |
| `Defaults.BuildDefaults` | [L165](../../Other/FluxCooldownDefaults.lua#L165) |
| `Defaults.GetGeometry` | [L204](../../Other/FluxCooldownDefaults.lua#L204) |
| `Defaults.Request` | [L349](../../Other/FluxCooldownDefaults.lua#L349) |
| `Defaults.TestBoundary` | [L357](../../Other/FluxCooldownDefaults.lua#L357) |
| `Defaults.Status` | [L372](../../Other/FluxCooldownDefaults.lua#L372) |
| `SlashCmdList.FLUXCOOLDOWNS` | [L406](../../Other/FluxCooldownDefaults.lua#L406) |

### Other/FluxEquipSlotFlyout.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `operation:Cancel` | [L51](../../Other/FluxEquipSlotFlyout.lua#L51) |
| `Flyout.CancelHideTimer` | [L63](../../Other/FluxEquipSlotFlyout.lua#L63) |
| `Flyout.CancelShowTimer` | [L67](../../Other/FluxEquipSlotFlyout.lua#L67) |
| `Flyout.IsOpenFor` | [L71](../../Other/FluxEquipSlotFlyout.lua#L71) |
| `Flyout.Hide` | [L84](../../Other/FluxEquipSlotFlyout.lua#L84) |
| `truebtn.SetChecked` | [L248](../../Other/FluxEquipSlotFlyout.lua#L248) |
| `region.Show` | [L274](../../Other/FluxEquipSlotFlyout.lua#L274) |
| `Flyout.ScheduleHideSoon` | [L294](../../Other/FluxEquipSlotFlyout.lua#L294) |
| `Flyout.Show` | [L450](../../Other/FluxEquipSlotFlyout.lua#L450) |
| `Flyout.NotifyEnter` | [L517](../../Other/FluxEquipSlotFlyout.lua#L517) |
| `Flyout.NotifyLeave` | [L537](../../Other/FluxEquipSlotFlyout.lua#L537) |
| `Flyout.SetOnEquipped` | [L542](../../Other/FluxEquipSlotFlyout.lua#L542) |

### Other/FluxHUDTooltip.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `ns.ApplyHUDTooltipPosition` | [L29](../../Other/FluxHUDTooltip.lua#L29) |
| `ns.SetHUDTooltipOwner` | [L59](../../Other/FluxHUDTooltip.lua#L59) |

### Other/FluxInputDebug.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `Debug.Capture` | [L100](../../Other/FluxInputDebug.lua#L100) |
| `Debug.CaptureEditMode` | [L175](../../Other/FluxInputDebug.lua#L175) |
| `Debug.CaptureBags` | [L219](../../Other/FluxInputDebug.lua#L219) |
| `Debug.CaptureTooltip` | [L310](../../Other/FluxInputDebug.lua#L310) |
| `SlashCmdList.FLUXINPUT` | [L364](../../Other/FluxInputDebug.lua#L364) |

### Other/FluxLoot.lua

Owner: [25-other-qol.md](../25-other-qol.md).

| Declaration | Source |
|---|---|
| `FluxLoot:Refresh` | [L450](../../Other/FluxLoot.lua#L450) |
| `FluxLoot:Preview` | [L476](../../Other/FluxLoot.lua#L476) |

### Other/FluxPerfCapture.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Capture.Print` | [L233](../../Other/FluxPerfCapture.lua#L233) |
| `Capture.Cancel` | [L277](../../Other/FluxPerfCapture.lua#L277) |
| `Capture.Start` | [L287](../../Other/FluxPerfCapture.lua#L287) |
| `Capture.StopWatch` | [L550](../../Other/FluxPerfCapture.lua#L550) |
| `Capture.WatchStatus` | [L570](../../Other/FluxPerfCapture.lua#L570) |
| `Capture.StartWatch` | [L576](../../Other/FluxPerfCapture.lua#L576) |
| `Capture.PrintSpikes` | [L680](../../Other/FluxPerfCapture.lua#L680) |

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

### RaidFrame/FluxRaidAuras.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `A.OnHiddenGroupBuffsChanged` | [L68](../../RaidFrame/FluxRaidAuras.lua#L68) |
| `A.Setup` | [L497](../../RaidFrame/FluxRaidAuras.lua#L497) |
| `A.Update` | [L722](../../RaidFrame/FluxRaidAuras.lua#L722) |
| `A.UpdateDispel` | [L793](../../RaidFrame/FluxRaidAuras.lua#L793) |
| `A.Refresh` | [L821](../../RaidFrame/FluxRaidAuras.lua#L821) |
| `A.Clear` | [L831](../../RaidFrame/FluxRaidAuras.lua#L831) |
| `A.Diagnostics` | [L841](../../RaidFrame/FluxRaidAuras.lua#L841) |
| `A.DebugDuration` | [L876](../../RaidFrame/FluxRaidAuras.lua#L876) |

### RaidFrame/FluxRaidCompat.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaidCompat.UnitTokenValid` | [L71](../../RaidFrame/FluxRaidCompat.lua#L71) |
| `FluxRaidCompat.CallCUF` | [L90](../../RaidFrame/FluxRaidCompat.lua#L90) |
| `FluxRaidCompat.ShouldDisplayBorder` | [L104](../../RaidFrame/FluxRaidCompat.lua#L104) |
| `FluxRaidCompat.HasCompactRaidFrameManager` | [L117](../../RaidFrame/FluxRaidCompat.lua#L117) |
| `FluxRaidCompat.CanPositionRaidManager` | [L126](../../RaidFrame/FluxRaidCompat.lua#L126) |
| `FluxRaidCompat.CanUsePetBattleStateDriver` | [L131](../../RaidFrame/FluxRaidCompat.lua#L131) |
| `FluxRaidCompat.GetChatTabLift` | [L137](../../RaidFrame/FluxRaidCompat.lua#L137) |
| `FluxRaidCompat.ApplyPrivateAuraMixin` | [L142](../../RaidFrame/FluxRaidCompat.lua#L142) |
| `FluxRaidCompat.GetOutOfRange` | [L194](../../RaidFrame/FluxRaidCompat.lua#L194) |
| `FluxRaidCompat.ApplyRangeAlpha` | [L220](../../RaidFrame/FluxRaidCompat.lua#L220) |
| `FluxRaidCompat.BuildVisibleGroupsReverse` | [L278](../../RaidFrame/FluxRaidCompat.lua#L278) |
| `FluxRaidCompat.ComputeReverseColumnLayout` | [L291](../../RaidFrame/FluxRaidCompat.lua#L291) |
| `FluxRaidCompat.IsSecret` | [L332](../../RaidFrame/FluxRaidCompat.lua#L332) |
| `FluxRaidCompat.PlainBool` | [L336](../../RaidFrame/FluxRaidCompat.lua#L336) |
| `FluxRaidCompat.HasHealthPercent` | [L340](../../RaidFrame/FluxRaidCompat.lua#L340) |
| `FluxRaidCompat.HasPowerPercent` | [L346](../../RaidFrame/FluxRaidCompat.lua#L346) |
| `FluxRaidCompat.HasPrivateAuraContainer` | [L352](../../RaidFrame/FluxRaidCompat.lua#L352) |
| `FluxRaidCompat.HasRangeAlphaBoolean` | [L360](../../RaidFrame/FluxRaidCompat.lua#L360) |
| `FluxRaidCompat.GetHealthPercent` | [L367](../../RaidFrame/FluxRaidCompat.lua#L367) |
| `FluxRaidCompat.GetPowerPercent` | [L404](../../RaidFrame/FluxRaidCompat.lua#L404) |

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
| `EventHandlers:GROUP_ROSTER_UPDATE` | [L198](../../RaidFrame/FluxRaidFrame.lua#L198) |
| `EventHandlers:PARTY_MEMBERS_CHANGED` | [L204](../../RaidFrame/FluxRaidFrame.lua#L204) |
| `EventHandlers:CVAR_UPDATE` | [L210](../../RaidFrame/FluxRaidFrame.lua#L210) |
| `EventHandlers:PLAYER_ENTERING_WORLD` | [L214](../../RaidFrame/FluxRaidFrame.lua#L214) |
| `EventHandlers:PLAYER_REGEN_ENABLED` | [L221](../../RaidFrame/FluxRaidFrame.lua#L221) |
| `EventHandlers:PLAYER_REGEN_DISABLED` | [L232](../../RaidFrame/FluxRaidFrame.lua#L232) |
| `EventHandlers:SPELLS_CHANGED` | [L240](../../RaidFrame/FluxRaidFrame.lua#L240) |
| `EventHandlers:HIDDEN_GROUP_BUFFS_CHANGED` | [L246](../../RaidFrame/FluxRaidFrame.lua#L246) |
| `EventHandlers:PET_BATTLE_CLOSE` | [L258](../../RaidFrame/FluxRaidFrame.lua#L258) |
| `EventHandlers:COMPACT_UNIT_FRAME_PROFILES_LOADED` | [L262](../../RaidFrame/FluxRaidFrame.lua#L262) |
| `EventHandlers:DISPLAY_SIZE_CHANGED` | [L268](../../RaidFrame/FluxRaidFrame.lua#L268) |
| `EventHandlers:UI_SCALE_CHANGED` | [L274](../../RaidFrame/FluxRaidFrame.lua#L274) |
| `EventHandlers:PLAYER_TARGET_CHANGED` | [L280](../../RaidFrame/FluxRaidFrame.lua#L280) |
| `EventHandlers:PLAYER_ROLES_ASSIGNED` | [L286](../../RaidFrame/FluxRaidFrame.lua#L286) |
| `EventHandlers:READY_CHECK` | [L292](../../RaidFrame/FluxRaidFrame.lua#L292) |
| `EventHandlers:READY_CHECK_CONFIRM` | [L298](../../RaidFrame/FluxRaidFrame.lua#L298) |
| `EventHandlers:READY_CHECK_FINISHED` | [L304](../../RaidFrame/FluxRaidFrame.lua#L304) |
| `EventHandlers:RAID_TARGET_UPDATE` | [L310](../../RaidFrame/FluxRaidFrame.lua#L310) |
| `FluxRaid_OnLoad` | [L319](../../RaidFrame/FluxRaidFrame.lua#L319) |
| `FluxRaid_OnEvent` | [L373](../../RaidFrame/FluxRaidFrame.lua#L373) |

### RaidFrame/FluxRaidFrame_BigDebuffs.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `BigDebuffs:Refresh` | [L119](../../RaidFrame/FluxRaidFrame_BigDebuffs.lua#L119) |

### RaidFrame/FluxRaidHealerExtras.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `E.GetClassBuffFilter` | [L90](../../RaidFrame/FluxRaidHealerExtras.lua#L90) |
| `E.InvalidateClassBuffFilter` | [L108](../../RaidFrame/FluxRaidHealerExtras.lua#L108) |
| `E.Clear` | [L138](../../RaidFrame/FluxRaidHealerExtras.lua#L138) |
| `E.Setup` | [L142](../../RaidFrame/FluxRaidHealerExtras.lua#L142) |
| `E.Update` | [L185](../../RaidFrame/FluxRaidHealerExtras.lua#L185) |
| `E.RefreshLayout` | [L292](../../RaidFrame/FluxRaidHealerExtras.lua#L292) |
| `E.OnEvent` | [L334](../../RaidFrame/FluxRaidHealerExtras.lua#L334) |
| `endendE.GetExtraCells` | [L366](../../RaidFrame/FluxRaidHealerExtras.lua#L366) |

### RaidFrame/FluxRaidHoTs.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `H.IsSupported` | [L48](../../RaidFrame/FluxRaidHoTs.lua#L48) |
| `H.Learn` | [L81](../../RaidFrame/FluxRaidHoTs.lua#L81) |
| `H.OnEvent` | [L256](../../RaidFrame/FluxRaidHoTs.lua#L256) |
| `H.Setup` | [L325](../../RaidFrame/FluxRaidHoTs.lua#L325) |
| `H.Update` | [L358](../../RaidFrame/FluxRaidHoTs.lua#L358) |
| `H.Clear` | [L372](../../RaidFrame/FluxRaidHoTs.lua#L372) |
| `H.GetStatus` | [L382](../../RaidFrame/FluxRaidHoTs.lua#L382) |

### RaidFrame/FluxRaidLayout.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaid_GetColumnHeight` | [L71](../../RaidFrame/FluxRaidLayout.lua#L71) |
| `FluxRaid_GetMTMAChildStep` | [L75](../../RaidFrame/FluxRaidLayout.lua#L75) |
| `FluxRaid_QueueWork` | [L83](../../RaidFrame/FluxRaidLayout.lua#L83) |
| `FluxRaid_GetMTMARosterCount` | [L155](../../RaidFrame/FluxRaidLayout.lua#L155) |
| `FluxRaid_GetPreviewStackVerticalPosition` | [L276](../../RaidFrame/FluxRaidLayout.lua#L276) |
| `FluxRaidFrame_UpdatePosition` | [L281](../../RaidFrame/FluxRaidLayout.lua#L281) |
| `FluxRaid_ComputeSyntheticGroup2ColumnLeftX` | [L299](../../RaidFrame/FluxRaidLayout.lua#L299) |
| `FluxRaid_GetPlacement2FocusAnchorBottomRight` | [L327](../../RaidFrame/FluxRaidLayout.lua#L327) |
| `FluxRaid_GetFirstGroupNthMemberBottomFromScreen` | [L723](../../RaidFrame/FluxRaidLayout.lua#L723) |
| `FluxRaid_QueueReadinessRetry` | [L848](../../RaidFrame/FluxRaidLayout.lua#L848) |
| `FluxRaid_QueueConfigureAndRefresh` | [L853](../../RaidFrame/FluxRaidLayout.lua#L853) |
| `FluxRaid_InstallManagerHooks` | [L1062](../../RaidFrame/FluxRaidLayout.lua#L1062) |
| `FluxRaid_ScheduleBlizzardGridHideCheck` | [L1084](../../RaidFrame/FluxRaidLayout.lua#L1084) |
| `FluxRaid_ApplyBlizzardCompactGridHidden` | [L1097](../../RaidFrame/FluxRaidLayout.lua#L1097) |
| `FluxRaid_RestoreBlizzardRaidFrames` | [L1125](../../RaidFrame/FluxRaidLayout.lua#L1125) |
| `FluxRaid_RunPendingCombatWork` | [L1148](../../RaidFrame/FluxRaidLayout.lua#L1148) |
| `FluxRaid_OnRosterOrPartyChanged` | [L1189](../../RaidFrame/FluxRaidLayout.lua#L1189) |
| `FluxRaid_InitLayoutFrames` | [L1209](../../RaidFrame/FluxRaidLayout.lua#L1209) |
| `FluxRaid_InstallPetBattleDriver` | [L1240](../../RaidFrame/FluxRaidLayout.lua#L1240) |
| `FluxRaid_DisableBlizzardNow` | [L1288](../../RaidFrame/FluxRaidLayout.lua#L1288) |
| `FluxRaid_PositionContainer` | [L1292](../../RaidFrame/FluxRaidLayout.lua#L1292) |

### RaidFrame/FluxRaidPrediction.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `Prediction.Setup` | [L116](../../RaidFrame/FluxRaidPrediction.lua#L116) |
| `Prediction.Update` | [L262](../../RaidFrame/FluxRaidPrediction.lua#L262) |
| `Prediction.UpdatePowerCost` | [L310](../../RaidFrame/FluxRaidPrediction.lua#L310) |
| `Prediction.Clear` | [L337](../../RaidFrame/FluxRaidPrediction.lua#L337) |

### RaidFrame/FluxRaidPreview.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaidPreviewUnit_OnLoad` | [L332](../../RaidFrame/FluxRaidPreview.lua#L332) |
| `FluxRaidPreview_ApplyIdleHighlights` | [L415](../../RaidFrame/FluxRaidPreview.lua#L415) |
| `FluxRaidPreview_RefreshLayout` | [L798](../../RaidFrame/FluxRaidPreview.lua#L798) |
| `FluxRaidPreview.PaintPartyAuras` | [L835](../../RaidFrame/FluxRaidPreview.lua#L835) |
| `FluxRaidPreview.Show` | [L844](../../RaidFrame/FluxRaidPreview.lua#L844) |
| `FluxRaidPreview.Hide` | [L858](../../RaidFrame/FluxRaidPreview.lua#L858) |
| `FluxRaidPreview.Toggle` | [L866](../../RaidFrame/FluxRaidPreview.lua#L866) |
| `FluxRaidPreview.IsPartyShown` | [L874](../../RaidFrame/FluxRaidPreview.lua#L874) |
| `FluxRaidPreview.ToggleParty` | [L879](../../RaidFrame/FluxRaidPreview.lua#L879) |
| `FluxRaidPreview.RefreshFromOptions` | [L886](../../RaidFrame/FluxRaidPreview.lua#L886) |
| `FluxRaidPreviewUnit_OnEnter` | [L895](../../RaidFrame/FluxRaidPreview.lua#L895) |
| `FluxRaidPreviewUnit_OnLeave` | [L910](../../RaidFrame/FluxRaidPreview.lua#L910) |

### RaidFrame/FluxRaidSecure.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `Secure.GetGroupConditionPolicy` | [L35](../../RaidFrame/FluxRaidSecure.lua#L35) |
| `Secure.GetCompanionVisibilityCondition` | [L39](../../RaidFrame/FluxRaidSecure.lua#L39) |
| `Secure.SuspendTargetWatches` | [L164](../../RaidFrame/FluxRaidSecure.lua#L164) |
| `Secure.AttachTarget` | [L187](../../RaidFrame/FluxRaidSecure.lua#L187) |
| `Secure.ConfigureHeader` | [L267](../../RaidFrame/FluxRaidSecure.lua#L267) |
| `Secure.DisableHeader` | [L321](../../RaidFrame/FluxRaidSecure.lua#L321) |
| `Secure.ConfigurePartyFrames` | [L407](../../RaidFrame/FluxRaidSecure.lua#L407) |
| `Secure.DisablePartyFrames` | [L453](../../RaidFrame/FluxRaidSecure.lua#L453) |
| `Secure.GetPartyStates` | [L473](../../RaidFrame/FluxRaidSecure.lua#L473) |
| `Secure.AttachHeaderChild` | [L484](../../RaidFrame/FluxRaidSecure.lua#L484) |
| `Secure.RefreshRosterLayout` | [L499](../../RaidFrame/FluxRaidSecure.lua#L499) |

### RaidFrame/FluxRaidUnit.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaid_RefreshJoinedBorders` | [L49](../../RaidFrame/FluxRaidUnit.lua#L49) |
| `FluxRaid_RequestJoinedBorderRefresh` | [L81](../../RaidFrame/FluxRaidUnit.lua#L81) |
| `FluxRaid_ShouldShowPowerBar` | [L94](../../RaidFrame/FluxRaidUnit.lua#L94) |
| `FluxRaid_UpdateHealth` | [L134](../../RaidFrame/FluxRaidUnit.lua#L134) |
| `FluxRaid_UpdatePower` | [L156](../../RaidFrame/FluxRaidUnit.lua#L156) |
| `FluxRaid_UpdateHealPrediction` | [L201](../../RaidFrame/FluxRaidUnit.lua#L201) |
| `FluxRaid_UpdateName` | [L206](../../RaidFrame/FluxRaidUnit.lua#L206) |
| `FluxRaid_UpdateStatusText` | [L232](../../RaidFrame/FluxRaidUnit.lua#L232) |
| `FluxRaid_UpdateSelectionHighlight` | [L288](../../RaidFrame/FluxRaidUnit.lua#L288) |
| `FluxRaid_UpdateAggroHighlight` | [L305](../../RaidFrame/FluxRaidUnit.lua#L305) |
| `FluxRaid_UpdateRoleIcon` | [L349](../../RaidFrame/FluxRaidUnit.lua#L349) |
| `FluxRaid_UpdateCenterStatus` | [L376](../../RaidFrame/FluxRaidUnit.lua#L376) |
| `FluxRaid_UpdateReadyCheck` | [L440](../../RaidFrame/FluxRaidUnit.lua#L440) |
| `FluxRaid_UpdateRange` | [L466](../../RaidFrame/FluxRaidUnit.lua#L466) |
| `FluxRaid_UpdateAuras` | [L473](../../RaidFrame/FluxRaidUnit.lua#L473) |
| `FluxRaid_UpdateDispelHighlight` | [L479](../../RaidFrame/FluxRaidUnit.lua#L479) |
| `FluxRaid_PaintUnit` | [L483](../../RaidFrame/FluxRaidUnit.lua#L483) |
| `FluxRaid_BindUnit` | [L645](../../RaidFrame/FluxRaidUnit.lua#L645) |
| `FluxRaid_OnUnitAttributeChanged` | [L677](../../RaidFrame/FluxRaidUnit.lua#L677) |
| `FluxRaidUnit_OnLoad` | [L688](../../RaidFrame/FluxRaidUnit.lua#L688) |
| `FluxRaidUnit_OnShow` | [L727](../../RaidFrame/FluxRaidUnit.lua#L727) |
| `FluxRaidUnit_OnHide` | [L740](../../RaidFrame/FluxRaidUnit.lua#L740) |
| `FluxRaidUnit_UpdateTooltiptooltip.UpdateTooltip` | [L781](../../RaidFrame/FluxRaidUnit.lua#L781) |
| `FluxRaidUnit_OnEnter` | [L796](../../RaidFrame/FluxRaidUnit.lua#L796) |
| `FluxRaidUnit_OnLeave` | [L804](../../RaidFrame/FluxRaidUnit.lua#L804) |
| `ns.FluxRaidRegisterAllMouseoverKeybindFrames` | [L815](../../RaidFrame/FluxRaidUnit.lua#L815) |
| `FluxRaid_ForEachHeaderChild` | [L825](../../RaidFrame/FluxRaidUnit.lua#L825) |
| `FluxRaid_SyncHeaderChildUnits` | [L850](../../RaidFrame/FluxRaidUnit.lua#L850) |
| `FluxRaid_ApplyChromeToChildren` | [L863](../../RaidFrame/FluxRaidUnit.lua#L863) |
| `FluxRaid_SyncAllFluxUnitAuraSettings` | [L887](../../RaidFrame/FluxRaidUnit.lua#L887) |
| `FluxRaid_RefreshVisibleUnits` | [L895](../../RaidFrame/FluxRaidUnit.lua#L895) |
| `FluxRaid_RefreshSelfDisplayNames` | [L914](../../RaidFrame/FluxRaidUnit.lua#L914) |
| `FluxRaid_EnsureRangePoll` | [L958](../../RaidFrame/FluxRaidUnit.lua#L958) |
| `FluxRaid_IsMTMAChild` | [L967](../../RaidFrame/FluxRaidUnit.lua#L967) |
| `FluxCompactMiniFrameSetup` | [L1004](../../RaidFrame/FluxRaidUnit.lua#L1004) |
| `FluxRaid_AttachOrUpdateMTMATarget` | [L1072](../../RaidFrame/FluxRaidUnit.lua#L1072) |
| `FluxRaid_RefreshMTMATargetAttachments` | [L1114](../../RaidFrame/FluxRaidUnit.lua#L1114) |
| `FluxCompactMiniFrameSetup_G.FluxCompactUnitFrameSetup` | [L1128](../../RaidFrame/FluxRaidUnit.lua#L1128) |

### RaidFrame/FluxRaidVisuals.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaidVisuals.GetBlizzardDefaultSizing` | [L42](../../RaidFrame/FluxRaidVisuals.lua#L42) |
| `FluxRaidVisuals.GetAuraLayout` | [L110](../../RaidFrame/FluxRaidVisuals.lua#L110) |
| `FluxRaidVisuals.GetAuraDurationFontScale` | [L159](../../RaidFrame/FluxRaidVisuals.lua#L159) |
| `FluxRaidVisuals.GetAuraScaleLimit` | [L163](../../RaidFrame/FluxRaidVisuals.lua#L163) |
| `FluxRaidVisuals.GetFrameAuraLayout` | [L168](../../RaidFrame/FluxRaidVisuals.lua#L168) |
| `FluxRaidVisuals.GetFrameAuraAnchor` | [L195](../../RaidFrame/FluxRaidVisuals.lua#L195) |
| `FluxRaidVisuals.EnsurePartyDebuffBorder` | [L204](../../RaidFrame/FluxRaidVisuals.lua#L204) |
| `FluxRaidVisuals.SetPartyDebuffBorderType` | [L235](../../RaidFrame/FluxRaidVisuals.lua#L235) |
| `FluxRaidVisuals.CreatePartyDispelGlow` | [L251](../../RaidFrame/FluxRaidVisuals.lua#L251) |
| `FluxRaidVisuals.GetAuraDurationFont` | [L295](../../RaidFrame/FluxRaidVisuals.lua#L295) |
| `FluxRaidVisuals.GetAuraDurationFontSize` | [L306](../../RaidFrame/FluxRaidVisuals.lua#L306) |
| `FluxRaidVisuals.GetAuraDurationTextScale` | [L311](../../RaidFrame/FluxRaidVisuals.lua#L311) |
| `FluxRaidVisuals.GetAuraDurationFormatter` | [L369](../../RaidFrame/FluxRaidVisuals.lua#L369) |
| `FluxRaidVisuals.GetAuraDurationFontObject` | [L398](../../RaidFrame/FluxRaidVisuals.lua#L398) |
| `FluxRaidVisuals.StyleAuraDuration` | [L413](../../RaidFrame/FluxRaidVisuals.lua#L413) |
| `FluxRaidVisuals.ApplyRaidFrameTunables` | [L434](../../RaidFrame/FluxRaidVisuals.lua#L434) |
| `FluxRaidVisuals.ApplyRaidHighlightVertexColors` | [L503](../../RaidFrame/FluxRaidVisuals.lua#L503) |
| `FluxRaidVisuals.SafeSetUnitFrameSize` | [L519](../../RaidFrame/FluxRaidVisuals.lua#L519) |
| `FluxRaidVisuals.EnsureFluxOverlays` | [L544](../../RaidFrame/FluxRaidVisuals.lua#L544) |
| `FluxRaidVisuals.GetAuraFocusMode` | [L629](../../RaidFrame/FluxRaidVisuals.lua#L629) |
| `FluxRaidVisuals.GetAuraOrganizationType` | [L641](../../RaidFrame/FluxRaidVisuals.lua#L641) |
| `FluxRaidVisuals.UsesPrivateAuras` | [L672](../../RaidFrame/FluxRaidVisuals.lua#L672) |
| `FluxRaidVisuals.GetFluxRaidOptionTable` | [L681](../../RaidFrame/FluxRaidVisuals.lua#L681) |
| `FluxRaidVisuals.ShouldDisplayOnlyDispellableDebuffs` | [L696](../../RaidFrame/FluxRaidVisuals.lua#L696) |
| `FluxRaidVisuals.UseOwnRaidSettings` | [L709](../../RaidFrame/FluxRaidVisuals.lua#L709) |
| `FluxRaidVisuals.SyncAuraDisplayOptions` | [L714](../../RaidFrame/FluxRaidVisuals.lua#L714) |
| `FluxRaidVisuals.EnsureAuraMaxSlots` | [L754](../../RaidFrame/FluxRaidVisuals.lua#L754) |
| `FluxRaidVisuals.ConfigurePrivateAuras` | [L787](../../RaidFrame/FluxRaidVisuals.lua#L787) |
| `FluxRaidVisuals.UpdatePrivateAuraUnit` | [L843](../../RaidFrame/FluxRaidVisuals.lua#L843) |
| `FluxRaidVisuals.SyncPrivateAuraSettings` | [L869](../../RaidFrame/FluxRaidVisuals.lua#L869) |
| `FluxRaidVisuals.PushAuraDisplayToFrame` | [L897](../../RaidFrame/FluxRaidVisuals.lua#L897) |
| `FluxRaidVisuals.NeutralizeBlizzardSharedUpdateAllSetup` | [L907](../../RaidFrame/FluxRaidVisuals.lua#L907) |
| `FluxRaidVisuals.ResealCompactUnitFrameOnUpdate` | [L910](../../RaidFrame/FluxRaidVisuals.lua#L910) |
| `FluxRaidVisuals.SetUnitName` | [L1161](../../RaidFrame/FluxRaidVisuals.lua#L1161) |
| `FluxRaidVisuals.SetHealthStatus` | [L1173](../../RaidFrame/FluxRaidVisuals.lua#L1173) |
| `FluxRaidVisuals.SetUnitStatus` | [L1204](../../RaidFrame/FluxRaidVisuals.lua#L1204) |
| `FluxRaidVisuals.SetJoinedEdges` | [L1218](../../RaidFrame/FluxRaidVisuals.lua#L1218) |
| `FluxRaidVisuals.ApplyCellChrome` | [L1270](../../RaidFrame/FluxRaidVisuals.lua#L1270) |
| `FluxRaidVisuals.ApplyVisuals` | [L1449](../../RaidFrame/FluxRaidVisuals.lua#L1449) |
| `FluxRaidVisuals.SetupHealAbsorbLayers` | [L1454](../../RaidFrame/FluxRaidVisuals.lua#L1454) |
| `FluxRaidVisuals.SetupReadyCheckIcon` | [L1457](../../RaidFrame/FluxRaidVisuals.lua#L1457) |
| `FluxRaidVisuals.RefreshNeutralBarTracks` | [L1460](../../RaidFrame/FluxRaidVisuals.lua#L1460) |

### Respec/FluxRespec_ActionBars.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `ActionBars.CollectSlots` | [L59](../../Respec/FluxRespec_ActionBars.lua#L59) |
| `ActionBars.RewriteStanceSpellId` | [L255](../../Respec/FluxRespec_ActionBars.lua#L255) |
| `ActionBars.RewriteSavedStanceSpellId` | [L327](../../Respec/FluxRespec_ActionBars.lua#L327) |
| `ActionBars.CaptureStanceLayout` | [L357](../../Respec/FluxRespec_ActionBars.lua#L357) |
| `ActionBars.ApplyStanceLayout` | [L379](../../Respec/FluxRespec_ActionBars.lua#L379) |
| `ActionBars.Capture` | [L423](../../Respec/FluxRespec_ActionBars.lua#L423) |
| `ActionBars.CancelPendingApply` | [L566](../../Respec/FluxRespec_ActionBars.lua#L566) |
| `ActionBars.Apply` | [L597](../../Respec/FluxRespec_ActionBars.lua#L597) |
| `ActionBars.MatchesSnapshot` | [L637](../../Respec/FluxRespec_ActionBars.lua#L637) |
| `ActionBars.FilledCount` | [L663](../../Respec/FluxRespec_ActionBars.lua#L663) |

### Respec/FluxRespec_Apply.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Apply.IsRunning` | [L159](../../Respec/FluxRespec_Apply.lua#L159) |
| `Apply.IsWaitingForRuneEngrave` | [L163](../../Respec/FluxRespec_Apply.lua#L163) |
| `Apply.IsEngraveButtonMode` | [L169](../../Respec/FluxRespec_Apply.lua#L169) |
| `Apply.WillSwitchSpec` | [L179](../../Respec/FluxRespec_Apply.lua#L179) |
| `Apply.Cancel` | [L184](../../Respec/FluxRespec_Apply.lua#L184) |
| `Apply.IsProfileFullyApplied` | [L324](../../Respec/FluxRespec_Apply.lua#L324) |
| `Apply.NextStepLabel` | [L396](../../Respec/FluxRespec_Apply.lua#L396) |
| `Apply.Run` | [L947](../../Respec/FluxRespec_Apply.lua#L947) |

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
| `Consumables.IsDifferent` | [L75](../../Respec/FluxRespec_Consumables.lua#L75) |

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
| `Equipment.StartParallelBankWithdrawForLoad` | [L1350](../../Respec/FluxRespec_Equipment.lua#L1350) |
| `Equipment.BagSlotMatchesSavedWant` | [L1392](../../Respec/FluxRespec_Equipment.lua#L1392) |
| `Equipment.IsBagSlotInSavedGearSet` | [L1397](../../Respec/FluxRespec_Equipment.lua#L1397) |
| `Equipment.CancelPendingApply` | [L1644](../../Respec/FluxRespec_Equipment.lua#L1644) |
| `Equipment.ApplyWithCallback` | [L1833](../../Respec/FluxRespec_Equipment.lua#L1833) |
| `Equipment.Apply` | [L1838](../../Respec/FluxRespec_Equipment.lua#L1838) |
| `Equipment.SlotRelevantToProfileEquipment` | [L1843](../../Respec/FluxRespec_Equipment.lua#L1843) |
| `Equipment.DiffCount` | [L1864](../../Respec/FluxRespec_Equipment.lua#L1864) |
| `Equipment.AnyGearChangeNeeded` | [L1887](../../Respec/FluxRespec_Equipment.lua#L1887) |
| `Equipment.SlotMatchesEntry` | [L1913](../../Respec/FluxRespec_Equipment.lua#L1913) |
| `Equipment.FindBagSlotByItemLink` | [L1926](../../Respec/FluxRespec_Equipment.lua#L1926) |
| `Equipment.GetProfileGearAvailability` | [L1969](../../Respec/FluxRespec_Equipment.lua#L1969) |
| `Equipment.GetSlotGearStatus` | [L2068](../../Respec/FluxRespec_Equipment.lua#L2068) |
| `Equipment.ProfileHasMissingGear` | [L2082](../../Respec/FluxRespec_Equipment.lua#L2082) |
| `Equipment.ProfileHasGearIssue` | [L2092](../../Respec/FluxRespec_Equipment.lua#L2092) |
| `Equipment.GetProfileGearIssueKind` | [L2102](../../Respec/FluxRespec_Equipment.lua#L2102) |
| `Equipment.CanItemGoInInventorySlot` | [L2168](../../Respec/FluxRespec_Equipment.lua#L2168) |
| `Equipment.GetBagCandidatesForInventorySlot` | [L2187](../../Respec/FluxRespec_Equipment.lua#L2187) |
| `Equipment.EquipBagSlotToInventorySlot` | [L2228](../../Respec/FluxRespec_Equipment.lua#L2228) |
| `Equipment.NotifyActiveProfileMayNeedBankWithdraw` | [L2254](../../Respec/FluxRespec_Equipment.lua#L2254) |

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
| `P.CancelHideTimer` | [L73](../../Respec/FluxRespec_GearPicker.lua#L73) |
| `P.CancelShowTimer` | [L77](../../Respec/FluxRespec_GearPicker.lua#L77) |
| `P.IsOpenFor` | [L81](../../Respec/FluxRespec_GearPicker.lua#L81) |
| `P.HasAlternatives` | [L94](../../Respec/FluxRespec_GearPicker.lua#L94) |
| `P.Hide` | [L103](../../Respec/FluxRespec_GearPicker.lua#L103) |
| `P.NotifyStripEnter` | [L136](../../Respec/FluxRespec_GearPicker.lua#L136) |
| `P.NotifyStripLeave` | [L154](../../Respec/FluxRespec_GearPicker.lua#L154) |
| `P.ScheduleHideSoon` | [L159](../../Respec/FluxRespec_GearPicker.lua#L159) |
| `P.Show` | [L175](../../Respec/FluxRespec_GearPicker.lua#L175) |

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
| `GearSetLock.DecorateProtectedInventoryTooltip` | [L118](../../Respec/FluxRespec_GearSetTooltip.lua#L118) |
| `GearSetLock.DecorateProtectedTooltip` | [L148](../../Respec/FluxRespec_GearSetTooltip.lua#L148) |
| `GearSetLock.InstallTooltipHooks` | [L279](../../Respec/FluxRespec_GearSetTooltip.lua#L279) |

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
| `Bundle.CaptureTalentSnapshot` | [L116](../../Respec/FluxRespec_PresetBundle.lua#L116) |
| `Bundle.TalentTreeLabel` | [L123](../../Respec/FluxRespec_PresetBundle.lua#L123) |
| `Bundle.PresetHasAnyBars` | [L148](../../Respec/FluxRespec_PresetBundle.lua#L148) |
| `Bundle.PresetBarsTalentMatchesAnySpec` | [L160](../../Respec/FluxRespec_PresetBundle.lua#L160) |
| `Bundle.ResolveBarsBundleForPreset` | [L182](../../Respec/FluxRespec_PresetBundle.lua#L182) |
| `Bundle.GetPrimaryTalentSnapshotForPreset` | [L229](../../Respec/FluxRespec_PresetBundle.lua#L229) |
| `Bundle.ApplyBarsSnapshot` | [L248](../../Respec/FluxRespec_PresetBundle.lua#L248) |
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
| `P.CancelHideTimer` | [L82](../../Respec/FluxRespec_RunePicker.lua#L82) |
| `P.CancelShowTimer` | [L86](../../Respec/FluxRespec_RunePicker.lua#L86) |
| `P.IsOpenFor` | [L90](../../Respec/FluxRespec_RunePicker.lua#L90) |
| `P.HasAlternatives` | [L137](../../Respec/FluxRespec_RunePicker.lua#L137) |
| `P.Hide` | [L141](../../Respec/FluxRespec_RunePicker.lua#L141) |
| `P.NotifyStripEnter` | [L162](../../Respec/FluxRespec_RunePicker.lua#L162) |
| `P.NotifyStripLeave` | [L180](../../Respec/FluxRespec_RunePicker.lua#L180) |
| `P.ScheduleHideSoon` | [L185](../../Respec/FluxRespec_RunePicker.lua#L185) |
| `P.Show` | [L201](../../Respec/FluxRespec_RunePicker.lua#L201) |

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
| `Talents.SwitchToMatchingGroup` | [L804](../../Respec/FluxRespec_Talents.lua#L804) |
| `Talents.Apply` | [L865](../../Respec/FluxRespec_Talents.lua#L865) |
| `Talents.RememberUnlearnCost` | [L977](../../Respec/FluxRespec_Talents.lua#L977) |
| `Talents.SetTrainerPayPreauthorized` | [L988](../../Respec/FluxRespec_Talents.lua#L988) |
| `Talents.IsTrainerPayPreauthorized` | [L992](../../Respec/FluxRespec_Talents.lua#L992) |
| `Talents.ClearTrainerPayPreauth` | [L996](../../Respec/FluxRespec_Talents.lua#L996) |
| `Talents.GetTrainerUnlearnCostCopper` | [L1001](../../Respec/FluxRespec_Talents.lua#L1001) |
| `Talents.BuildNeedTrainerPopupText` | [L1028](../../Respec/FluxRespec_Talents.lua#L1028) |
| `Talents.SyncTrainerUnlearnQueueForActiveProfile` | [L1053](../../Respec/FluxRespec_Talents.lua#L1053) |

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
| `S.Defer` | [L95](../../Salvage/FluxSalvage_Overlay.lua#L95) |
| `S.DeferMethod` | [L103](../../Salvage/FluxSalvage_Overlay.lua#L103) |
| `S.AnchorOverlayToOwner` | [L151](../../Salvage/FluxSalvage_Overlay.lua#L151) |
| `S.ApplySpellToBagSlot` | [L327](../../Salvage/FluxSalvage_Overlay.lua#L327) |
| `S.ApplySpell` | [L344](../../Salvage/FluxSalvage_Overlay.lua#L344) |
| `S.ApplyItem` | [L378](../../Salvage/FluxSalvage_Overlay.lua#L378) |
| `S.UpdateAttributeDriver` | [L402](../../Salvage/FluxSalvage_Overlay.lua#L402) |
| `S.SetOverlayColor` | [L630](../../Salvage/FluxSalvage_Overlay.lua#L630) |
| `S.HideOverlay` | [L652](../../Salvage/FluxSalvage_Overlay.lua#L652) |
| `S.HandleTooltip` | [L723](../../Salvage/FluxSalvage_Overlay.lua#L723) |
| `S.OnModifierChanged` | [L819](../../Salvage/FluxSalvage_Overlay.lua#L819) |

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
| `InfoFrame._IsRetailStatClient` | [L251](../../StatusBars/FluxInfoFrame.lua#L251) |
| `InfoFrame._CamelotCombatStatValue` | [L262](../../StatusBars/FluxInfoFrame.lua#L262) |
| `InfoFrame._RetailCombatStatValue` | [L325](../../StatusBars/FluxInfoFrame.lua#L325) |
| `InfoFrame._CamelotLiveCombatText` | [L359](../../StatusBars/FluxInfoFrame.lua#L359) |
| `InfoFrame._RetailLiveCombatText` | [L437](../../StatusBars/FluxInfoFrame.lua#L437) |
| `InfoFrame._RenderCamelotLiveText` | [L453](../../StatusBars/FluxInfoFrame.lua#L453) |
| `InfoFrame._ClassicSpellPinKey` | [L660](../../StatusBars/FluxInfoFrame.lua#L660) |
| `InfoFrame._UseClassicSpellPowerLine` | [L683](../../StatusBars/FluxInfoFrame.lua#L683) |
| `InfoFrame._FoldClassicSpellPins` | [L690](../../StatusBars/FluxInfoFrame.lua#L690) |
| `InfoFrame._PlainStatNumber` | [L732](../../StatusBars/FluxInfoFrame.lua#L732) |
| `InfoFrame._EnsureCamelotSpellSnapshotHooks` | [L758](../../StatusBars/FluxInfoFrame.lua#L758) |
| `InfoFrame._CamelotSpellBonus` | [L765](../../StatusBars/FluxInfoFrame.lua#L765) |
| `InfoFrame._ClassicSpellDamageColorHex` | [L833](../../StatusBars/FluxInfoFrame.lua#L833) |
| `.get` | [L1297](../../StatusBars/FluxInfoFrame.lua#L1297) |
| `.get` | [L1306](../../StatusBars/FluxInfoFrame.lua#L1306) |
| `InfoFrame.GetStatRegistry` | [L1632](../../StatusBars/FluxInfoFrame.lua#L1632) |
| `InfoFrame._RefreshCamelotLiveText` | [L1641](../../StatusBars/FluxInfoFrame.lua#L1641) |
| `InfoFrame.RefreshIntegratedStripBackdrop` | [L1706](../../StatusBars/FluxInfoFrame.lua#L1706) |
| `InfoFrame.IsDockedToActionStrip` | [L1725](../../StatusBars/FluxInfoFrame.lua#L1725) |
| `InfoFrame.GetEffectivePlacement` | [L1729](../../StatusBars/FluxInfoFrame.lua#L1729) |
| `InfoFrame.SetAnchoredByStatusBarColumn` | [L1734](../../StatusBars/FluxInfoFrame.lua#L1734) |
| `_GetTooltipMeasureFS` | [L2996](../../StatusBars/FluxInfoFrame.lua#L2996) |
| `_MeasureTooltipTextWidth` | [L3008](../../StatusBars/FluxInfoFrame.lua#L3008) |
| `_SplitMergedSegments` | [L3019](../../StatusBars/FluxInfoFrame.lua#L3019) |
| `_BuildTooltipLabelKeyMap` | [L3039](../../StatusBars/FluxInfoFrame.lua#L3039) |
| `_StripTooltipCodes` | [L3067](../../StatusBars/FluxInfoFrame.lua#L3067) |
| `_InferKeyFromSegmentText` | [L3072](../../StatusBars/FluxInfoFrame.lua#L3072) |
| `_ResolveTooltipKeysForEntry` | [L3085](../../StatusBars/FluxInfoFrame.lua#L3085) |
| `_BuildSegmentSpansForEntry` | [L3111](../../StatusBars/FluxInfoFrame.lua#L3111) |
| `_GetHoveredKeyFromEntryFS` | [L3225](../../StatusBars/FluxInfoFrame.lua#L3225) |
| `_PositionFluxInfoTooltipAnchor` | [L3347](../../StatusBars/FluxInfoFrame.lua#L3347) |
| `gt.SetOwnergt.SetOwner` | [L3399](../../StatusBars/FluxInfoFrame.lua#L3399) |
| `_InvalidateTooltipStatFrameCache` | [L3443](../../StatusBars/FluxInfoFrame.lua#L3443) |
| `_G.FluxAutoRepairEnabled` | [L3447](../../StatusBars/FluxInfoFrame.lua#L3447) |
| `_G.FluxToggleAutoRepair` | [L3456](../../StatusBars/FluxInfoFrame.lua#L3456) |
| `_SetDurabilityRepairTooltip` | [L3472](../../StatusBars/FluxInfoFrame.lua#L3472) |
| `_SetCompactPairTooltip` | [L3540](../../StatusBars/FluxInfoFrame.lua#L3540) |
| `_SetEquipmentRatingTooltip` | [L3550](../../StatusBars/FluxInfoFrame.lua#L3550) |
| `_GetCompactInfoPairValues` | [L3568](../../StatusBars/FluxInfoFrame.lua#L3568) |
| `_GetTooltipSourceStatFrames` | [L3589](../../StatusBars/FluxInfoFrame.lua#L3589) |
| `_GetTooltipSourceStatFrame` | [L3617](../../StatusBars/FluxInfoFrame.lua#L3617) |
| `InfoFrame._CharacterPanelStatNumber` | [L3623](../../StatusBars/FluxInfoFrame.lua#L3623) |
| `InfoFrame._ShowCamelotSpellPinTooltip` | [L3644](../../StatusBars/FluxInfoFrame.lua#L3644) |
| `_ShowInfoTooltipForKey` | [L3734](../../StatusBars/FluxInfoFrame.lua#L3734) |
| `InfoFrame.StatLabel` | [L3954](../../StatusBars/FluxInfoFrame.lua#L3954) |
| `InfoFrame._CollectVisibleStatKeys` | [L3986](../../StatusBars/FluxInfoFrame.lua#L3986) |
| `InfoFrame._NormalizeStatOrder` | [L4041](../../StatusBars/FluxInfoFrame.lua#L4041) |
| `InfoFrame.HasVisibleLines` | [L4077](../../StatusBars/FluxInfoFrame.lua#L4077) |
| `InfoFrame.GetOrderedVisibleStats` | [L4093](../../StatusBars/FluxInfoFrame.lua#L4093) |
| `InfoFrame.SetStatOrder` | [L4118](../../StatusBars/FluxInfoFrame.lua#L4118) |
| `InfoFrame._FlushPlayerStatRefresh` | [L4361](../../StatusBars/FluxInfoFrame.lua#L4361) |
| `InfoFrame.RequestStatRefresh` | [L4368](../../StatusBars/FluxInfoFrame.lua#L4368) |
| `InfoFrame.PrepareIntegratedStripLayout` | [L4424](../../StatusBars/FluxInfoFrame.lua#L4424) |
| `InfoFrame.PositionActionStripSlotFrame` | [L4561](../../StatusBars/FluxInfoFrame.lua#L4561) |
| `InfoFrame._LayoutScreenTopLeft` | [L4630](../../StatusBars/FluxInfoFrame.lua#L4630) |
| `InfoFrame.GetFrame` | [L5222](../../StatusBars/FluxInfoFrame.lua#L5222) |
| `InfoFrame.GetStableIntegratedColumnWidth` | [L5227](../../StatusBars/FluxInfoFrame.lua#L5227) |
| `InfoFrame.ForceUpdatePosition` | [L5239](../../StatusBars/FluxInfoFrame.lua#L5239) |
| `InfoFrame.ForceRebuild` | [L5260](../../StatusBars/FluxInfoFrame.lua#L5260) |
| `InfoFrame.TogglePinnedStat` | [L5283](../../StatusBars/FluxInfoFrame.lua#L5283) |
| `InfoFrame.IsStatPinned` | [L5359](../../StatusBars/FluxInfoFrame.lua#L5359) |
| `_RebuildTooltipStatFrameCache` | [L6038](../../StatusBars/FluxInfoFrame.lua#L6038) |
| `InfoFrame.ResolveStatFramesForTooltip` | [L6106](../../StatusBars/FluxInfoFrame.lua#L6106) |
| `InfoFrame.RefreshAllPinIndicators` | [L6152](../../StatusBars/FluxInfoFrame.lua#L6152) |
| `InfoFrame.ApplyRespecProfileSnapshot` | [L6157](../../StatusBars/FluxInfoFrame.lua#L6157) |
| `InfoFrame.HookClassicCSCStatFrame` | [L6201](../../StatusBars/FluxInfoFrame.lua#L6201) |
| `InfoFrame.HookRetailPaperDollStatFrame` | [L6210](../../StatusBars/FluxInfoFrame.lua#L6210) |
| `InfoFrame.HookRetailPaperDollPoolStatFrame` | [L6221](../../StatusBars/FluxInfoFrame.lua#L6221) |
| `InfoFrame.ReadForeverDisplayText` | [L6234](../../StatusBars/FluxInfoFrame.lua#L6234) |
| `InfoFrame.RememberPinnedStatValue` | [L6285](../../StatusBars/FluxInfoFrame.lua#L6285) |
| `InfoFrame.HookForeverScrollBoxStatFrame` | [L6329](../../StatusBars/FluxInfoFrame.lua#L6329) |
| `InfoFrame.InstallRetailPaperDollHooks` | [L6357](../../StatusBars/FluxInfoFrame.lua#L6357) |
| `InfoFrame.AfterCharacterShown` | [L6363](../../StatusBars/FluxInfoFrame.lua#L6363) |
| `InfoFrame._StartCamelotCharacterWatch` | [L6371](../../StatusBars/FluxInfoFrame.lua#L6371) |
| `InfoFrame.InstallCharacterInfoPinHooks` | [L6403](../../StatusBars/FluxInfoFrame.lua#L6403) |

### StatusBars/FluxInfoFrameStats.lua

Owner: [16-status-bars.md](../16-status-bars.md).

| Declaration | Source |
|---|---|
| `providers.spellPower` | [L145](../../StatusBars/FluxInfoFrameStats.lua#L145) |
| `endproviders.spellPowerOnly` | [L146](../../StatusBars/FluxInfoFrameStats.lua#L146) |
| `endproviders.healPower` | [L147](../../StatusBars/FluxInfoFrameStats.lua#L147) |
| `endendproviders.versatility` | [L155](../../StatusBars/FluxInfoFrameStats.lua#L155) |
| `endproviders.attackPower` | [L184](../../StatusBars/FluxInfoFrameStats.lua#L184) |
| `endproviders.rangedAttackPower` | [L185](../../StatusBars/FluxInfoFrameStats.lua#L185) |
| `endproviders.armor` | [L186](../../StatusBars/FluxInfoFrameStats.lua#L186) |
| `endproviders.health` | [L190](../../StatusBars/FluxInfoFrameStats.lua#L190) |
| `endproviders.power` | [L191](../../StatusBars/FluxInfoFrameStats.lua#L191) |
| `endendproviders.weaponDamage` | [L198](../../StatusBars/FluxInfoFrameStats.lua#L198) |
| `endproviders.rangedWeaponDamage` | [L210](../../StatusBars/FluxInfoFrameStats.lua#L210) |
| `endproviders.weaponSpeed` | [L217](../../StatusBars/FluxInfoFrameStats.lua#L217) |
| `endproviders.rangedWeaponSpeed` | [L222](../../StatusBars/FluxInfoFrameStats.lua#L222) |
| `endproviders.mp5` | [L223](../../StatusBars/FluxInfoFrameStats.lua#L223) |
| `endproviders.speed` | [L230](../../StatusBars/FluxInfoFrameStats.lua#L230) |
| `providers.speedproviders.defense` | [L240](../../StatusBars/FluxInfoFrameStats.lua#L240) |
| `endproviders.resilience` | [L247](../../StatusBars/FluxInfoFrameStats.lua#L247) |
| `Info.GetLiveStatText` | [L262](../../StatusBars/FluxInfoFrameStats.lua#L262) |

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
| `UpdateExpBar` | [L1765](../../StatusBars/FluxStatusBar.lua#L1765) |
| `UpdateFluxDurabilityFramePosition` | [L2309](../../StatusBars/FluxStatusBar.lua#L2309) |
| `_G.FluxStatusBar_GetLocation2MinBottomOffset` | [L2405](../../StatusBars/FluxStatusBar.lua#L2405) |
| `_G.FluxStatusBar_GetBottomOverlayHeight` | [L2426](../../StatusBars/FluxStatusBar.lua#L2426) |
| `_G.FluxStatusBar_GetBottomOverlayHeightForAlignedChrome` | [L2445](../../StatusBars/FluxStatusBar.lua#L2445) |
| `UpdateLayout` | [L2636](../../StatusBars/FluxStatusBar.lua#L2636) |
| `endend_G.FluxStatusBarUpdateLayout` | [L3096](../../StatusBars/FluxStatusBar.lua#L3096) |

### UnitFrames/FluxCastBar.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `CB.StopCustomTimer` | [L1793](../../UnitFrames/FluxCastBar.lua#L1793) |
| `CB.StartCustomTimer` | [L1799](../../UnitFrames/FluxCastBar.lua#L1799) |
| `CB.ResetCastForUnit` | [L2212](../../UnitFrames/FluxCastBar.lua#L2212) |
| `CB.RefreshCastForUnit` | [L2226](../../UnitFrames/FluxCastBar.lua#L2226) |
| `CB.CreateCastBar` | [L2711](../../UnitFrames/FluxCastBar.lua#L2711) |
| `castBar.SetValue` | [L2735](../../UnitFrames/FluxCastBar.lua#L2735) |
| `endcastBar.GetValue` | [L2736](../../UnitFrames/FluxCastBar.lua#L2736) |
| `castBar.SetMinMaxValues` | [L2738](../../UnitFrames/FluxCastBar.lua#L2738) |
| `endcastBar.GetMinMaxValues` | [L2742](../../UnitFrames/FluxCastBar.lua#L2742) |
| `endcastBar.SetStatusBarColor` | [L2743](../../UnitFrames/FluxCastBar.lua#L2743) |
| `endcastBar.SetStatusBarTexture` | [L2744](../../UnitFrames/FluxCastBar.lua#L2744) |
| `endcastBar.GetStatusBarTexture` | [L2745](../../UnitFrames/FluxCastBar.lua#L2745) |
| `endiftimerBar.SetTimerDurationthencastBar.SetTimerDuration` | [L2756](../../UnitFrames/FluxCastBar.lua#L2756) |
| `endendiftimerBar.GetTimerDurationthencastBar.GetTimerDuration` | [L2762](../../UnitFrames/FluxCastBar.lua#L2762) |
| `RegisterUnitCastEventscastBar.DisablePetCastBar` | [L2930](../../UnitFrames/FluxCastBar.lua#L2930) |
| `endcastBar.UpdateLayout` | [L3148](../../UnitFrames/FluxCastBar.lua#L3148) |
| `CB.SyncBlizzardCastBars` | [L3470](../../UnitFrames/FluxCastBar.lua#L3470) |
| `FluxCastBar_ApplyAppearanceAccent` | [L3501](../../UnitFrames/FluxCastBar.lua#L3501) |

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
| `FX.ThemeForMask` | [L260](../../UnitFrames/FluxCastBarThemes.lua#L260) |
| `FX.ResolveTheme` | [L300](../../UnitFrames/FluxCastBarThemes.lua#L300) |
| `FX.Layout` | [L442](../../UnitFrames/FluxCastBarThemes.lua#L442) |
| `FX.Reset` | [L569](../../UnitFrames/FluxCastBarThemes.lua#L569) |
| `FX.Update` | [L704](../../UnitFrames/FluxCastBarThemes.lua#L704) |
| `FX.Apply` | [L779](../../UnitFrames/FluxCastBarThemes.lua#L779) |
| `FX.Begin` | [L816](../../UnitFrames/FluxCastBarThemes.lua#L816) |
| `FX.BeginMask` | [L829](../../UnitFrames/FluxCastBarThemes.lua#L829) |
| `FX.Finish` | [L839](../../UnitFrames/FluxCastBarThemes.lua#L839) |
| `FX.Attach` | [L863](../../UnitFrames/FluxCastBarThemes.lua#L863) |
| `FX.Refresh` | [L871](../../UnitFrames/FluxCastBarThemes.lua#L871) |
| `FX.ObserveCast` | [L882](../../UnitFrames/FluxCastBarThemes.lua#L882) |
| `FX.SyncEvents` | [L950](../../UnitFrames/FluxCastBarThemes.lua#L950) |

### UnitFrames/FluxCastBarTradeskills.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `Trades.Resolve` | [L23](../../UnitFrames/FluxCastBarTradeskills.lua#L23) |
| `Trades.Reset` | [L61](../../UnitFrames/FluxCastBarTradeskills.lua#L61) |
| `Trades.Layout` | [L71](../../UnitFrames/FluxCastBarTradeskills.lua#L71) |
| `Trades.Apply` | [L127](../../UnitFrames/FluxCastBarTradeskills.lua#L127) |
| `Trades.Finish` | [L169](../../UnitFrames/FluxCastBarTradeskills.lua#L169) |

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
| `trueframe.SetScale` | [L61](../../UnitFrames/FluxClassPower.lua#L61) |
| `ns.ClassPower.GetLayoutBounds` | [L168](../../UnitFrames/FluxClassPower.lua#L168) |
| `ns.ClassPower.ApplyVisibility` | [L502](../../UnitFrames/FluxClassPower.lua#L502) |
| `ns.ClassPower.UpdatePosition` | [L522](../../UnitFrames/FluxClassPower.lua#L522) |
| `ns.ClassPower.Initialize` | [L595](../../UnitFrames/FluxClassPower.lua#L595) |

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
| `HLO.DisableForHealthBar` | [L301](../../UnitFrames/FluxHealthLossOverlay.lua#L301) |
| `HLO.ResetIdentityForFrame` | [L332](../../UnitFrames/FluxHealthLossOverlay.lua#L332) |
| `HLO.OnBeforeHealthValueSet` | [L362](../../UnitFrames/FluxHealthLossOverlay.lua#L362) |
| `HLO.OnAfterHealthValueSet` | [L369](../../UnitFrames/FluxHealthLossOverlay.lua#L369) |
| `HLO.Initialize` | [L461](../../UnitFrames/FluxHealthLossOverlay.lua#L461) |

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
| `MP5.Shutdown` | [L319](../../UnitFrames/FluxMP5Overlay.lua#L319) |
| `MP5.Initialize` | [L339](../../UnitFrames/FluxMP5Overlay.lua#L339) |

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
| `PCO.CreateOverlay` | [L153](../../UnitFrames/FluxPowerCostOverlay.lua#L153) |
| `PCO.ApplySegmentArt` | [L173](../../UnitFrames/FluxPowerCostOverlay.lua#L173) |
| `PCO.UpdateOverlayColor` | [L193](../../UnitFrames/FluxPowerCostOverlay.lua#L193) |
| `PCO.ResetIdentityForFrame` | [L376](../../UnitFrames/FluxPowerCostOverlay.lua#L376) |
| `PCO.RefreshPrediction` | [L444](../../UnitFrames/FluxPowerCostOverlay.lua#L444) |
| `PCO.AfterPowerApplied` | [L805](../../UnitFrames/FluxPowerCostOverlay.lua#L805) |
| `PCO.DisableForFrame` | [L896](../../UnitFrames/FluxPowerCostOverlay.lua#L896) |
| `PCO.Initialize` | [L920](../../UnitFrames/FluxPowerCostOverlay.lua#L920) |

### UnitFrames/FluxSwingTimer.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `ST.HideForCastBarClaim` | [L1289](../../UnitFrames/FluxSwingTimer.lua#L1289) |
| `ST.OnCastBarSlotReleased` | [L1294](../../UnitFrames/FluxSwingTimer.lua#L1294) |
| `FluxSwingTimer_IsCleuRegistered` | [L1932](../../UnitFrames/FluxSwingTimer.lua#L1932) |
| `ST.AttachToCastBar` | [L2501](../../UnitFrames/FluxSwingTimer.lua#L2501) |
| `ST.SetPlayerSwingTimerEnabled` | [L2605](../../UnitFrames/FluxSwingTimer.lua#L2605) |

### UnitFrames/FluxUnitFrames_Auras.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.GetAuraPackingWidth` | [L221](../../UnitFrames/FluxUnitFrames_Auras.lua#L221) |
| `button.GetFilter` | [L883](../../UnitFrames/FluxUnitFrames_Auras.lua#L883) |
| `UF.GetAuraContentOffsets` | [L1480](../../UnitFrames/FluxUnitFrames_Auras.lua#L1480) |
| `UF.UpdateAuraPosition` | [L1562](../../UnitFrames/FluxUnitFrames_Auras.lua#L1562) |
| `_G.FluxUnitFrames_UpdateFocusAuraLayoutForRaidStack` | [L1608](../../UnitFrames/FluxUnitFrames_Auras.lua#L1608) |
| `UF.ApplyAuraOptionsToFrame` | [L2023](../../UnitFrames/FluxUnitFrames_Auras.lua#L2023) |
| `UF.EnableAuras` | [L2048](../../UnitFrames/FluxUnitFrames_Auras.lua#L2048) |
| `UF.DisableAuras` | [L2334](../../UnitFrames/FluxUnitFrames_Auras.lua#L2334) |
| `UF.UpdateAuras` | [L2339](../../UnitFrames/FluxUnitFrames_Auras.lua#L2339) |
| `UF.CleanupAuras` | [L2348](../../UnitFrames/FluxUnitFrames_Auras.lua#L2348) |

### UnitFrames/FluxUnitFrames_AurasEngine.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.UseEngineAuras` | [L36](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L36) |
| `UF.ContainerUsesEngine` | [L48](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L48) |
| `UF.FrameUsesEngineAuras` | [L52](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L52) |
| `UF.PokeEngineAuras` | [L398](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L398) |
| `UF.SyncEngineAuras` | [L412](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L412) |
| `UF.AttachEngineAuras` | [L472](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L472) |

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

### UnitFrames/FluxUnitFrames_DebuffTint.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.PreviewDebuffTint` | [L267](../../UnitFrames/FluxUnitFrames_DebuffTint.lua#L267) |
| `UF.SetupDebuffTint` | [L298](../../UnitFrames/FluxUnitFrames_DebuffTint.lua#L298) |
| `UF.RefreshDebuffTint` | [L312](../../UnitFrames/FluxUnitFrames_DebuffTint.lua#L312) |

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
| `FluxUnitFrames_ApplyRuntimeFocus` | [L248](../../UnitFrames/FluxUnitFrames_Focus.lua#L248) |

### UnitFrames/FluxUnitFrames_FocusTarget.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `frame.UpdatePartitionframe.UpdatePartition` | [L107](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L107) |
| `FluxUnitFrames_ApplyRuntimeFocusTarget` | [L244](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L244) |
| `FluxUnitFrames_MatchFocusTargetToFocus` | [L327](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L327) |

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
| `FluxUnitFrames_GetTargetClassHealthColor` | [L11](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L11) |
| `FluxUnitFrames_RefreshTargetHealthColors` | [L32](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L32) |
| `FluxUnitFrames_ShouldUseFlux` | [L38](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L38) |
| `FluxUnitFrames_IsFeatureEnabled` | [L84](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L84) |
| `FluxUnitFrames_ShouldShowPortrait` | [L112](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L112) |
| `FluxUnitFrames_DisplayEnabled` | [L141](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L141) |
| `FluxUnitFrames_GetHealthTextMode` | [L149](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L149) |
| `FluxUnitFrames_ShouldShowCastTime` | [L168](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L168) |
| `FluxUnitFrames_ShouldShowPowerText` | [L172](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L172) |
| `FluxUnitFrames_ShouldShowHealPrediction` | [L178](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L178) |
| `FluxUnitFrames_ShouldShowAbsorbs` | [L182](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L182) |
| `FluxUnitFrames_ShouldShowClassPower` | [L186](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L186) |
| `FluxUnitFrames_GetClassPowerScale` | [L190](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L190) |
| `FluxUnitFrames_GetWholeFrameScale` | [L199](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L199) |
| `FluxUnitFrames_ShouldShowLevel` | [L207](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L207) |
| `FluxUnitFrames_ShouldShowClassIcon` | [L211](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L211) |
| `FluxUnitFrames_ShouldShowPvp` | [L215](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L215) |
| `FluxUnitFrames_ShouldShowCombatIcon` | [L219](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L219) |
| `FluxUnitFrames_ShouldShowRaidIcon` | [L223](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L223) |
| `FluxUnitFrames_ShouldShowPortraitCombat` | [L227](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L227) |
| `FluxUnitFrames_ShouldShowMouseover` | [L231](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L231) |
| `FluxUnitFrames_ShouldShowCastBar` | [L236](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L236) |
| `FluxUnitFrames_ShouldShowPetTooltipAuras` | [L250](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L250) |
| `FluxUnitFrames_ShouldUse3DPortrait` | [L259](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L259) |
| `FluxUnitFrames_IsPortraitCombatTintEnabled` | [L268](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L268) |
| `FluxUnitFrames_RefreshPortraitCombatTint` | [L276](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L276) |
| `FluxUnitFrames_ShouldShowTargetNoTargetPlaceholder` | [L291](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L291) |
| `FluxUnitFrames_RefreshTargetPlaceholderFromDB` | [L299](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L299) |
| `FluxUnitFrames_GetPlayerTargetPlacement` | [L308](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L308) |
| `FluxUnitFrames_GetScreenAnchorCenterOffsetX` | [L318](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L318) |
| `_G.FluxUnitFrames_GetPlayerScreenBottomOffset` | [L367](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L367) |
| `_G.FluxUnitFrames_ApplyPlayerStatusBarLayout` | [L402](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L402) |
| `FluxUnitFrames_SyncTargetChromeForPlacement` | [L415](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L415) |
| `FluxUnitFrames_RefreshTargetOfTargetAnchor` | [L450](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L450) |
| `FluxUnitFrames_ReanchorUnitFrameScreenPosition` | [L462](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L462) |
| `FluxUnitFrames_ApplyThreatBarOptionsFromDB` | [L523](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L523) |
| `FluxUnitFrames_ApplyPortraitOptionsFromDB` | [L569](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L569) |
| `FluxUnitFrames_RefreshPortraitRenderModeFromDB` | [L639](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L639) |
| `FluxUnitFrames_GetAuraConfigTables` | [L690](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L690) |
| `FluxUnitFrames_ApplyAuraLayoutFromDB` | [L752](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L752) |
| `FluxUnitFrames_ApplyOptionsFromDB` | [L787](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L787) |
| `FluxUnitFrames_GetPlayerTargetPlacement2RelativeUIScale` | [L923](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L923) |
| `FluxUnitFrames_UnitFrameStorageToEffectiveDimension` | [L931](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L931) |
| `FluxUnitFrames_UnitFrameEffectiveToStorageDimension` | [L942](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L942) |
| `FluxUnitFrames_EnsureAndGetFrameSizesBucket` | [L978](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L978) |
| `FluxUnitFrames_GetPlacement1TargetLeftForMicroMenuCap` | [L1005](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1005) |
| `FluxUnitFrames_GetUnitFrameDefaultDimension` | [L1041](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1041) |
| `FluxUnitFrames_GetFocusPresentationSize` | [L1066](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1066) |
| `FluxUnitFrames_GetFocusPresentationScale` | [L1075](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1075) |
| `FluxUnitFrames_GetConfiguredFrameSize` | [L1080](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1080) |
| `FluxUnitFrames_GetConfiguredPetTargetBarWidth` | [L1129](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1129) |
| `FluxUnitFrames_FullUnitFrameLayoutRefresh` | [L1142](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1142) |
| `FluxUnitFrames_GetHealthPartitionPct` | [L1179](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1179) |
| `FluxUnitFrames_RefreshBarPartitionsFromDB` | [L1210](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1210) |
| `FluxUnitFrames_ApplyFrameSizesFromDB` | [L1231](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1231) |

### UnitFrames/FluxUnitFrames_Party.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `Party.GetSizing` | [L21](../../UnitFrames/FluxUnitFrames_Party.lua#L21) |
| `Party.GetScale` | [L27](../../UnitFrames/FluxUnitFrames_Party.lua#L27) |
| `Party.GetStatusText` | [L42](../../UnitFrames/FluxUnitFrames_Party.lua#L42) |
| `Party.StyleText` | [L57](../../UnitFrames/FluxUnitFrames_Party.lua#L57) |
| `Party.LayoutIndicators` | [L72](../../UnitFrames/FluxUnitFrames_Party.lua#L72) |
| `Party.UpdatePvpBadge` | [L123](../../UnitFrames/FluxUnitFrames_Party.lua#L123) |
| `Party.SyncCastCover` | [L127](../../UnitFrames/FluxUnitFrames_Party.lua#L127) |
| `Party.LayoutCastOverlay` | [L152](../../UnitFrames/FluxUnitFrames_Party.lua#L152) |
| `Party.SetThreatColor` | [L168](../../UnitFrames/FluxUnitFrames_Party.lua#L168) |
| `Party.PaintStatus` | [L172](../../UnitFrames/FluxUnitFrames_Party.lua#L172) |
| `Party.ApplyTextModes` | [L183](../../UnitFrames/FluxUnitFrames_Party.lua#L183) |
| `Party.UpdateIndicators` | [L209](../../UnitFrames/FluxUnitFrames_Party.lua#L209) |
| `Party.UpdateThreat` | [L224](../../UnitFrames/FluxUnitFrames_Party.lua#L224) |
| `Party.PaintChrome` | [L266](../../UnitFrames/FluxUnitFrames_Party.lua#L266) |
| `Party.RefreshChrome` | [L304](../../UnitFrames/FluxUnitFrames_Party.lua#L304) |
| `Party.LayoutFocusPresentation` | [L382](../../UnitFrames/FluxUnitFrames_Party.lua#L382) |
| `Party.SetupFocusPresentation` | [L405](../../UnitFrames/FluxUnitFrames_Party.lua#L405) |
| `Party.SetupCompactCastOverlay` | [L419](../../UnitFrames/FluxUnitFrames_Party.lua#L419) |
| `bar.UpdateLayoutbar.UpdateLayout` | [L424](../../UnitFrames/FluxUnitFrames_Party.lua#L424) |
| `Party.RefreshPreview` | [L744](../../UnitFrames/FluxUnitFrames_Party.lua#L744) |
| `Party.ApplyOptions` | [L820](../../UnitFrames/FluxUnitFrames_Party.lua#L820) |
| `Party.Diagnostics` | [L867](../../UnitFrames/FluxUnitFrames_Party.lua#L867) |

### UnitFrames/FluxUnitFrames_Pet.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_ApplyRuntimePet` | [L279](../../UnitFrames/FluxUnitFrames_Pet.lua#L279) |

### UnitFrames/FluxUnitFrames_PetAuraTooltip.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.ShowPetAuraTooltip` | [L560](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L560) |
| `UF.HidePetAuraTooltip` | [L594](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L594) |
| `UF.ShowUnitTooltip` | [L649](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L649) |
| `UF.HideUnitTooltip` | [L661](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L661) |

### UnitFrames/FluxUnitFrames_PetTarget.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_ApplyRuntimePetTarget` | [L228](../../UnitFrames/FluxUnitFrames_PetTarget.lua#L228) |

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
| `PTC.ToggleOutfitFlyout` | [L432](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L432) |
| `PTC.UpdateInteractionState` | [L752](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L752) |
| `TransmogWatcher_OnUpdatestate.ArmTransmogWatcher` | [L830](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L830) |
| `PTC.Initialize` | [L842](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L842) |
| `trueplayerFrame.UpdateOuterBorder` | [L878](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L878) |
| `trueplayerFrame.UpdatePartition` | [L887](../../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua#L887) |

### UnitFrames/FluxUnitFrames_Shared.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.ConfigureUnitMenu` | [L12](../../UnitFrames/FluxUnitFrames_Shared.lua#L12) |
| `UF.ConfigureTargetClickVisibility` | [L33](../../UnitFrames/FluxUnitFrames_Shared.lua#L33) |
| `UF.RegisterUnitFramePoll` | [L168](../../UnitFrames/FluxUnitFrames_Shared.lua#L168) |
| `UF.UnregisterUnitFramePoll` | [L181](../../UnitFrames/FluxUnitFrames_Shared.lua#L181) |
| `FluxUI_GetUnitFramePollStats` | [L188](../../UnitFrames/FluxUnitFrames_Shared.lua#L188) |
| `UF.SyncBigDebuffsFrameLevelForUnitFrame` | [L342](../../UnitFrames/FluxUnitFrames_Shared.lua#L342) |
| `UF.SetFocusUnitWatch` | [L397](../../UnitFrames/FluxUnitFrames_Shared.lua#L397) |
| `UF.UnitTokenIsResolved` | [L433](../../UnitFrames/FluxUnitFrames_Shared.lua#L433) |
| `UF.ShouldShowWatchedUnitFrame` | [L491](../../UnitFrames/FluxUnitFrames_Shared.lua#L491) |
| `UF.HideEmptyUnitPortrait` | [L633](../../UnitFrames/FluxUnitFrames_Shared.lua#L633) |
| `UF.SyncTargetPlaceholderVisibility` | [L655](../../UnitFrames/FluxUnitFrames_Shared.lua#L655) |
| `UF.SyncWatchedUnitFrameVisibility` | [L715](../../UnitFrames/FluxUnitFrames_Shared.lua#L715) |
| `UF.GetHudBarTexture` | [L897](../../UnitFrames/FluxUnitFrames_Shared.lua#L897) |
| `UF.UsesHudUnitBars` | [L905](../../UnitFrames/FluxUnitFrames_Shared.lua#L905) |
| `UF.RecordFrameDimensions` | [L940](../../UnitFrames/FluxUnitFrames_Shared.lua#L940) |
| `UF.GetFramePublicDimensions` | [L950](../../UnitFrames/FluxUnitFrames_Shared.lua#L950) |
| `UF.GetFramePublicLevel` | [L960](../../UnitFrames/FluxUnitFrames_Shared.lua#L960) |
| `UF.SetFramePublicLevel` | [L979](../../UnitFrames/FluxUnitFrames_Shared.lua#L979) |
| `UF.RecordRelativeFramePublicLevel` | [L994](../../UnitFrames/FluxUnitFrames_Shared.lua#L994) |
| `UF.SetRelativeFramePublicLevel` | [L1001](../../UnitFrames/FluxUnitFrames_Shared.lua#L1001) |
| `UF.SyncPublicHealthGeometry` | [L1026](../../UnitFrames/FluxUnitFrames_Shared.lua#L1026) |
| `UF.GetPowerPredictionColor` | [L1075](../../UnitFrames/FluxUnitFrames_Shared.lua#L1075) |
| `UF.GetPowerStatusAtlas` | [L1094](../../UnitFrames/FluxUnitFrames_Shared.lua#L1094) |
| `UF.UpdateResourceSpark` | [L1148](../../UnitFrames/FluxUnitFrames_Shared.lua#L1148) |
| `pulse:StartAnimIfFull` | [L1366](../../UnitFrames/FluxUnitFrames_Shared.lua#L1366) |
| `pulse:RemoveAnims` | [L1389](../../UnitFrames/FluxUnitFrames_Shared.lua#L1389) |
| `UF.SetFullResourcePulseActive` | [L1432](../../UnitFrames/FluxUnitFrames_Shared.lua#L1432) |
| `UF.UpdateFullResourcePulse` | [L1461](../../UnitFrames/FluxUnitFrames_Shared.lua#L1461) |
| `UF.PowerValueForDisplay` | [L1490](../../UnitFrames/FluxUnitFrames_Shared.lua#L1490) |
| `UF.ApplyResourceBarStyle` | [L1526](../../UnitFrames/FluxUnitFrames_Shared.lua#L1526) |
| `UF.RefreshResourceConnection` | [L1621](../../UnitFrames/FluxUnitFrames_Shared.lua#L1621) |
| `UF.ApplyStaggerBarStyle` | [L1644](../../UnitFrames/FluxUnitFrames_Shared.lua#L1644) |
| `UF.LayoutPetHappinessIcon` | [L1726](../../UnitFrames/FluxUnitFrames_Shared.lua#L1726) |
| `UF.ForeverNpcChrome` | [L2227](../../UnitFrames/FluxUnitFrames_Shared.lua#L2227) |
| `AnimatedHealthLossMixin:OnLoad` | [L2331](../../UnitFrames/FluxUnitFrames_Shared.lua#L2331) |
| `AnimatedHealthLossMixin:SetDuration` | [L2339](../../UnitFrames/FluxUnitFrames_Shared.lua#L2339) |
| `AnimatedHealthLossMixin:SetStartDelay` | [L2343](../../UnitFrames/FluxUnitFrames_Shared.lua#L2343) |
| `AnimatedHealthLossMixin:SetPauseDelay` | [L2347](../../UnitFrames/FluxUnitFrames_Shared.lua#L2347) |
| `AnimatedHealthLossMixin:SetPostponeDelay` | [L2351](../../UnitFrames/FluxUnitFrames_Shared.lua#L2351) |
| `AnimatedHealthLossMixin:SetUnitHealthBar` | [L2355](../../UnitFrames/FluxUnitFrames_Shared.lua#L2355) |
| `AnimatedHealthLossMixin:UpdateHealthMinMax` | [L2365](../../UnitFrames/FluxUnitFrames_Shared.lua#L2365) |
| `AnimatedHealthLossMixin:GetHealthLossAnimationData` | [L2370](../../UnitFrames/FluxUnitFrames_Shared.lua#L2370) |
| `AnimatedHealthLossMixin:CancelAnimation` | [L2387](../../UnitFrames/FluxUnitFrames_Shared.lua#L2387) |
| `AnimatedHealthLossMixin:SetDisplayedLoss` | [L2393](../../UnitFrames/FluxUnitFrames_Shared.lua#L2393) |
| `AnimatedHealthLossMixin:BeginAnimation` | [L2403](../../UnitFrames/FluxUnitFrames_Shared.lua#L2403) |
| `AnimatedHealthLossMixin:PostponeStartTime` | [L2412](../../UnitFrames/FluxUnitFrames_Shared.lua#L2412) |
| `AnimatedHealthLossMixin:UpdateHealth` | [L2416](../../UnitFrames/FluxUnitFrames_Shared.lua#L2416) |
| `AnimatedHealthLossMixin:ReadableAbsorbBlocks` | [L2434](../../UnitFrames/FluxUnitFrames_Shared.lua#L2434) |
| `AnimatedHealthLossMixin:UpdateLossAnimation` | [L2442](../../UnitFrames/FluxUnitFrames_Shared.lua#L2442) |
| `AnimatedHealthLossMixin:ShowPixelDriver` | [L2461](../../UnitFrames/FluxUnitFrames_Shared.lua#L2461) |
| `AnimatedHealthLossMixin:UpdateFromPixels` | [L2484](../../UnitFrames/FluxUnitFrames_Shared.lua#L2484) |
| `UF.ApplyHealAbsorbOptionVisibility` | [L2788](../../UnitFrames/FluxUnitFrames_Shared.lua#L2788) |
| `UF.UpdateHealPrediction` | [L2816](../../UnitFrames/FluxUnitFrames_Shared.lua#L2816) |
| `UF.UnitIsAFKDisplay` | [L3043](../../UnitFrames/FluxUnitFrames_Shared.lua#L3043) |
| `UF.ShouldShowAFKHealthOverlay` | [L3053](../../UnitFrames/FluxUnitFrames_Shared.lua#L3053) |
| `UF.GetHealthDeadGhostStatusText` | [L3060](../../UnitFrames/FluxUnitFrames_Shared.lua#L3060) |
| `UF.LayoutVerticalTargetHealth` | [L3084](../../UnitFrames/FluxUnitFrames_Shared.lua#L3084) |
| `UF.CreateVerticalTargetAbsorbs` | [L3113](../../UnitFrames/FluxUnitFrames_Shared.lua#L3113) |
| `UF.UpdateVerticalTargetAbsorbs` | [L3152](../../UnitFrames/FluxUnitFrames_Shared.lua#L3152) |
| `UF.UpdateVerticalTargetColor` | [L3196](../../UnitFrames/FluxUnitFrames_Shared.lua#L3196) |
| `UF.ResetVerticalTargetHealth` | [L3213](../../UnitFrames/FluxUnitFrames_Shared.lua#L3213) |
| `UF.ConfigureVerticalTargetHealth` | [L3217](../../UnitFrames/FluxUnitFrames_Shared.lua#L3217) |
| `UF.UpdateVerticalTargetHealth` | [L3256](../../UnitFrames/FluxUnitFrames_Shared.lua#L3256) |
| `UF.UpdateHealth` | [L3277](../../UnitFrames/FluxUnitFrames_Shared.lua#L3277) |
| `UF.CreateHealthBar` | [L3433](../../UnitFrames/FluxUnitFrames_Shared.lua#L3433) |
| `UF.UpdateHealthColor` | [L3706](../../UnitFrames/FluxUnitFrames_Shared.lua#L3706) |
| `UF.UpdatePower` | [L3767](../../UnitFrames/FluxUnitFrames_Shared.lua#L3767) |
| `UF.CreatePowerBar` | [L3945](../../UnitFrames/FluxUnitFrames_Shared.lua#L3945) |
| `UF.CreatePortrait` | [L4215](../../UnitFrames/FluxUnitFrames_Shared.lua#L4215) |
| `UF.FrameUsesPortraitLayout` | [L4431](../../UnitFrames/FluxUnitFrames_Shared.lua#L4431) |
| `UF.LayoutBigDebuffsCornerPlaceholder` | [L4448](../../UnitFrames/FluxUnitFrames_Shared.lua#L4448) |
| `UF.UpdatePortrait` | [L4574](../../UnitFrames/FluxUnitFrames_Shared.lua#L4574) |
| `UF.SyncPortraitModelGeometry` | [L4651](../../UnitFrames/FluxUnitFrames_Shared.lua#L4651) |
| `UF.RefreshPortraitAfterDisplayMetrics` | [L4679](../../UnitFrames/FluxUnitFrames_Shared.lua#L4679) |
| `UF.UpdatePlayerSpecIconOnly` | [L4838](../../UnitFrames/FluxUnitFrames_Shared.lua#L4838) |
| `_G.FluxUnitFrames_RefreshPlayerSpecIcon` | [L4897](../../UnitFrames/FluxUnitFrames_Shared.lua#L4897) |
| `_G.FluxUnitFrames_GetPlayerSpecIcon` | [L4968](../../UnitFrames/FluxUnitFrames_Shared.lua#L4968) |
| `UF.CreateAtlasBorder` | [L5006](../../UnitFrames/FluxUnitFrames_Shared.lua#L5006) |
| `UF.UpdateAtlasBorder` | [L5054](../../UnitFrames/FluxUnitFrames_Shared.lua#L5054) |
| `UF.GuardTooltipStatusBar` | [L5106](../../UnitFrames/FluxUnitFrames_Shared.lua#L5106) |
| `UF.GetUnitTooltip` | [L5113](../../UnitFrames/FluxUnitFrames_Shared.lua#L5113) |
| `UF.ShowUnitTooltip` | [L5130](../../UnitFrames/FluxUnitFrames_Shared.lua#L5130) |
| `endtooltip.UpdateTooltip` | [L5164](../../UnitFrames/FluxUnitFrames_Shared.lua#L5164) |
| `UF.HideUnitTooltip` | [L5178](../../UnitFrames/FluxUnitFrames_Shared.lua#L5178) |
| `UF.CreateMouseoverHighlight` | [L5223](../../UnitFrames/FluxUnitFrames_Shared.lua#L5223) |
| `UF.SetIndicatorArt` | [L5305](../../UnitFrames/FluxUnitFrames_Shared.lua#L5305) |
| `UF.CreatePvpBadge` | [L5323](../../UnitFrames/FluxUnitFrames_Shared.lua#L5323) |
| `UF.UpdatePvpBadge` | [L5341](../../UnitFrames/FluxUnitFrames_Shared.lua#L5341) |
| `UF.CreateOuterBorder` | [L5385](../../UnitFrames/FluxUnitFrames_Shared.lua#L5385) |
| `outerBorderFrame.SetRightClickMenu` | [L5635](../../UnitFrames/FluxUnitFrames_Shared.lua#L5635) |
| `UF.SetFrameLevelIfChanged` | [L5752](../../UnitFrames/FluxUnitFrames_Shared.lua#L5752) |
| `UF.UpdatePortraitCombatTint` | [L5859](../../UnitFrames/FluxUnitFrames_Shared.lua#L5859) |
| `UF.UpdateBorderColors` | [L5888](../../UnitFrames/FluxUnitFrames_Shared.lua#L5888) |
| `UF.UpdateRaidMarker` | [L6729](../../UnitFrames/FluxUnitFrames_Shared.lua#L6729) |
| `UF.LayoutRaidMarker` | [L6743](../../UnitFrames/FluxUnitFrames_Shared.lua#L6743) |
| `UF.UpdateOuterBorder` | [L6753](../../UnitFrames/FluxUnitFrames_Shared.lua#L6753) |
| `UF.UpdateAdditionalPower` | [L7403](../../UnitFrames/FluxUnitFrames_Shared.lua#L7403) |
| `UF.CreateAdditionalPowerBar` | [L7556](../../UnitFrames/FluxUnitFrames_Shared.lua#L7556) |
| `UF.GetThreatBarPosition` | [L7741](../../UnitFrames/FluxUnitFrames_Shared.lua#L7741) |
| `UF.CreateThreatBar` | [L8008](../../UnitFrames/FluxUnitFrames_Shared.lua#L8008) |
| `UF.LayoutThreatBar` | [L8076](../../UnitFrames/FluxUnitFrames_Shared.lua#L8076) |
| `UF.UpdateThreatBar` | [L8202](../../UnitFrames/FluxUnitFrames_Shared.lua#L8202) |
| `UF.UpdateFrameVisualElements` | [L8406](../../UnitFrames/FluxUnitFrames_Shared.lua#L8406) |
| `UF.UpdateFramePartitionSeparators` | [L8552](../../UnitFrames/FluxUnitFrames_Shared.lua#L8552) |
| `UF.GetFluxStylePartitionHealthHeight` | [L8585](../../UnitFrames/FluxUnitFrames_Shared.lua#L8585) |
| `UF.UpdateFramePartition` | [L8599](../../UnitFrames/FluxUnitFrames_Shared.lua#L8599) |
| `UF.ApplyEmulatedHorizontalSqueezeForFrame` | [L9212](../../UnitFrames/FluxUnitFrames_Shared.lua#L9212) |
| `UF.UpdateAllEmulatedHorizontalSqueeze` | [L9216](../../UnitFrames/FluxUnitFrames_Shared.lua#L9216) |
| `FluxUnitFrames_UpdateAllEmulatedHorizontalSqueeze` | [L9228](../../UnitFrames/FluxUnitFrames_Shared.lua#L9228) |
| `UF.RegisterEmulatedHorizontalSqueeze` | [L9232](../../UnitFrames/FluxUnitFrames_Shared.lua#L9232) |
| `UF.CreateBaseFrame` | [L9277](../../UnitFrames/FluxUnitFrames_Shared.lua#L9277) |
| `UF.RefreshSelfDisplayNames` | [L9535](../../UnitFrames/FluxUnitFrames_Shared.lua#L9535) |
| `FluxUnitFrames_RefreshAppearanceChrome` | [L9557](../../UnitFrames/FluxUnitFrames_Shared.lua#L9557) |

### UnitFrames/FluxUnitFrames_Target.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `frame:UpdateFluxTargetPlaceholderVisibility` | [L285](../../UnitFrames/FluxUnitFrames_Target.lua#L285) |
| `FluxUnitFrames_RefreshTargetAndTotTogether` | [L336](../../UnitFrames/FluxUnitFrames_Target.lua#L336) |
| `FluxUnitFrames_ApplyRuntimeTarget` | [L407](../../UnitFrames/FluxUnitFrames_Target.lua#L407) |

### UnitFrames/FluxUnitFrames_TargetOfTarget.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_RestoreBlizzardTotDefaultParent` | [L285](../../UnitFrames/FluxUnitFrames_TargetOfTarget.lua#L285) |
| `FluxUnitFrames_ApplyRuntimeToT` | [L297](../../UnitFrames/FluxUnitFrames_TargetOfTarget.lua#L297) |

### WindowMover/Catalog.lua

Owner: [28-window-mover.md](../28-window-mover.md).

| Declaration | Source |
|---|---|
| `WindowMover.IsBlacklisted` | [L263](../../WindowMover/Catalog.lua#L263) |
| `WindowMover.ShouldSkip` | [L285](../../WindowMover/Catalog.lua#L285) |
| `WindowMover.Catalog` | [L318](../../WindowMover/Catalog.lua#L318) |

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
