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
| [AddonOptions/FluxOptionsGeneral.lua:105](../../AddonOptions/FluxOptionsGeneral.lua#L105) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsInfo.lua:173](../../AddonOptions/FluxOptionsInfo.lua#L173) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsLayout.lua:76](../../AddonOptions/FluxOptionsLayout.lua#L76) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsLoot.lua:66](../../AddonOptions/FluxOptionsLoot.lua#L66) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsMicroMenu.lua:312](../../AddonOptions/FluxOptionsMicroMenu.lua#L312) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsNameplates.lua:239](../../AddonOptions/FluxOptionsNameplates.lua#L239) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsShell.lua:867](../../AddonOptions/FluxOptionsShell.lua#L867) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [AddonOptions/FluxOptionsStatusBars.lua:536](../../AddonOptions/FluxOptionsStatusBars.lua#L536) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsUnitFrames.lua:2086](../../AddonOptions/FluxOptionsUnitFrames.lua#L2086) | `RegisterEvent` | `"ADDON_LOADED"` |
| [AddonOptions/FluxOptionsWindows.lua:274](../../AddonOptions/FluxOptionsWindows.lua#L274) | `RegisterEvent` | `"ADDON_LOADED"` |
| [BaganatorCompat/FluxBaganator_BankRestock.lua:295](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L295) | `RegisterEvent` | `"BANKFRAME_OPENED"` |
| [BaganatorCompat/FluxBaganator_BankRestock.lua:296](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L296) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [BaganatorCompat/FluxBaganator_BankRestock.lua:298](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L298) | `RegisterEvent` | `"PLAYER_INTERACTION_MANAGER_FRAME_SHOW"` |
| [BaganatorCompat/FluxBaganator_GearSets.lua:555](../../BaganatorCompat/FluxBaganator_GearSets.lua#L555) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [BaganatorCompat/FluxBaganator_GearSetShield.lua:222](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L222) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [BaganatorCompat/FluxBaganator_Protection.lua:327](../../BaganatorCompat/FluxBaganator_Protection.lua#L327) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [BaganatorCompat/FluxBaganator_Protection.lua:328](../../BaganatorCompat/FluxBaganator_Protection.lua#L328) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [BaganatorCompat/FluxBaganator_Protection.lua:329](../../BaganatorCompat/FluxBaganator_Protection.lua#L329) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [BaganatorCompat/Loader.lua:91](../../BaganatorCompat/Loader.lua#L91) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [BaganatorCompat/Loader.lua:125](../../BaganatorCompat/Loader.lua#L125) | `RegisterEvent` | `"ADDON_LOADED"` |
| [BaganatorCompat/Loader.lua:126](../../BaganatorCompat/Loader.lua#L126) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Bars/Blizzard.lua:712](../../Bars/Blizzard.lua#L712) | `RegisterEvent` | `STOCK_STANCE_LEFTOVER_EVENTS[i]` |
| [Bars/Blizzard.lua:714](../../Bars/Blizzard.lua#L714) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Bars/ProgramFace.lua:1612](../../Bars/ProgramFace.lua#L1612) | `Subscribe` | `ProgramFace.OnContext` |
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
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:849](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L849) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:850](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L850) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:851](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L851) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxBattlefieldMapPinRouter.lua:852](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L852) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:885](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L885) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:886](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L886) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:1224](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1224) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:1225](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1225) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxBattlefieldMapWorldFeatures.lua:1226](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1226) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxBattlefieldWorldMap.lua:72](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L72) | `RegisterEvent` | `event` |
| [Battlezonemap/FluxBattlefieldWorldMap.lua:88](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L88) | `RegisterEvent` | `event` |
| [Battlezonemap/FluxBattlefieldWorldMap.lua:783](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L783) | `RegisterEvent` | `event` |
| [Battlezonemap/FluxBattlefieldWorldMap.lua:786](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L786) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Battlezonemap/FluxBattlefieldWorldMap.lua:787](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L787) | `RegisterEvent` | `"ADDON_RESTRICTION_STATE_CHANGED"` |
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
| [Battlezonemap/FluxThreat.lua:209](../../Battlezonemap/FluxThreat.lua#L209) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [Battlezonemap/FluxThreat.lua:210](../../Battlezonemap/FluxThreat.lua#L210) | `RegisterUnitEvent` | `"UNIT_TARGET", "target"` |
| [Battlezonemap/FluxThreat.lua:211](../../Battlezonemap/FluxThreat.lua#L211) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Battlezonemap/FluxThreat.lua:212](../../Battlezonemap/FluxThreat.lua#L212) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxThreat.lua:930](../../Battlezonemap/FluxThreat.lua#L930) | `RegisterEvent` | `"UNIT_THREAT_LIST_UPDATE"` |
| [Battlezonemap/FluxThreat.lua:931](../../Battlezonemap/FluxThreat.lua#L931) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [Battlezonemap/FluxThreat.lua:1000](../../Battlezonemap/FluxThreat.lua#L1000) | `RegisterEvent` | `Threat, "COMBAT_PLAYER_ENTER"` |
| [Battlezonemap/FluxThreat.lua:1001](../../Battlezonemap/FluxThreat.lua#L1001) | `RegisterEvent` | `Threat, "COMBAT_PLAYER_LEAVE"` |
| [Battlezonemap/FluxThreat.lua:1002](../../Battlezonemap/FluxThreat.lua#L1002) | `RegisterEvent` | `Threat, "DETAILS_INSTANCE_ENDRESIZE"` |
| [Battlezonemap/FluxThreat.lua:1003](../../Battlezonemap/FluxThreat.lua#L1003) | `RegisterEvent` | `Threat, "DETAILS_INSTANCE_SIZECHANGED"` |
| [Battlezonemap/FluxThreat.lua:1004](../../Battlezonemap/FluxThreat.lua#L1004) | `RegisterEvent` | `Threat, "DETAILS_INSTANCE_STARTSTRETCH"` |
| [Battlezonemap/FluxThreat.lua:1005](../../Battlezonemap/FluxThreat.lua#L1005) | `RegisterEvent` | `Threat, "DETAILS_INSTANCE_ENDSTRETCH"` |
| [Battlezonemap/FluxThreat.lua:1006](../../Battlezonemap/FluxThreat.lua#L1006) | `RegisterEvent` | `Threat, "DETAILS_OPTIONS_MODIFIED"` |
| [Battlezonemap/FluxThreat.lua:1008](../../Battlezonemap/FluxThreat.lua#L1008) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [Battlezonemap/FluxThreat.lua:1009](../../Battlezonemap/FluxThreat.lua#L1009) | `RegisterUnitEvent` | `"UNIT_TARGET", "target"` |
| [Battlezonemap/FluxThreat.lua:1010](../../Battlezonemap/FluxThreat.lua#L1010) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Battlezonemap/FluxThreat.lua:1011](../../Battlezonemap/FluxThreat.lua#L1011) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Battlezonemap/FluxThreatMeter.lua:333](../../Battlezonemap/FluxThreatMeter.lua#L333) | `RegisterEvent` | `event` |
| [Battlezonemap/FluxThreatMeter.lua:334](../../Battlezonemap/FluxThreatMeter.lua#L334) | `RegisterUnitEvent` | `"UNIT_TARGET", "target"` |
| [Battlezonemap/FluxWindowFrame.lua:1668](../../Battlezonemap/FluxWindowFrame.lua#L1668) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Battlezonemap/FluxWindowFrame.lua:1669](../../Battlezonemap/FluxWindowFrame.lua#L1669) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Battlezonemap/FluxWindowFrame.lua:1670](../../Battlezonemap/FluxWindowFrame.lua#L1670) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Battlezonemap/FluxWindowFrame.lua:1671](../../Battlezonemap/FluxWindowFrame.lua#L1671) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Boot.lua:40](../../Binding/Boot.lua#L40) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Boot.lua:41](../../Binding/Boot.lua#L41) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Boot.lua:51](../../Binding/Boot.lua#L51) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Binding/Core/Apply.lua:2416](../../Binding/Core/Apply.lua#L2416) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Binding/Core/Apply.lua:2417](../../Binding/Core/Apply.lua#L2417) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Binding/Core/Apply.lua:2434](../../Binding/Core/Apply.lua#L2434) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Core/Apply.lua:2444](../../Binding/Core/Apply.lua#L2444) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/Apply.lua:2484](../../Binding/Core/Apply.lua#L2484) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [Binding/Core/ChordMap.lua:211](../../Binding/Core/ChordMap.lua#L211) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/Core/ChordMap.lua:212](../../Binding/Core/ChordMap.lua#L212) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/Conditions.lua:607](../../Binding/Core/Conditions.lua#L607) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [Binding/Core/Conditions.lua:608](../../Binding/Core/Conditions.lua#L608) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Binding/Core/Conditions.lua:626](../../Binding/Core/Conditions.lua#L626) | `RegisterEvent` | `"UNIT_PET"` |
| [Binding/Core/Engraving.lua:270](../../Binding/Core/Engraving.lua#L270) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Binding/Core/Engraving.lua:272](../../Binding/Core/Engraving.lua#L272) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [Binding/Core/Forms.lua:258](../../Binding/Core/Forms.lua#L258) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORMS"` |
| [Binding/Core/Forms.lua:259](../../Binding/Core/Forms.lua#L259) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/Placement.lua:2459](../../Binding/Core/Placement.lua#L2459) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/Core/Placement.lua:2460](../../Binding/Core/Placement.lua#L2460) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/PushPress.lua:436](../../Binding/Core/PushPress.lua#L436) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Binding/Core/PushPress.lua:775](../../Binding/Core/PushPress.lua#L775) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Binding/Core/PushPress.lua:872](../../Binding/Core/PushPress.lua#L872) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Core/PushPress.lua:873](../../Binding/Core/PushPress.lua#L873) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Input/FluxMouseoverKeybind.lua:2250](../../Binding/Input/FluxMouseoverKeybind.lua#L2250) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Binding/Input/FluxMouseoverKeybind.lua:2251](../../Binding/Input/FluxMouseoverKeybind.lua#L2251) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Binding/Input/FluxMouseoverKeybind.lua:2252](../../Binding/Input/FluxMouseoverKeybind.lua#L2252) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [Binding/Input/FluxMouseoverKeybind.lua:2253](../../Binding/Input/FluxMouseoverKeybind.lua#L2253) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Binding/Input/FluxMouseoverKeybind.lua:2254](../../Binding/Input/FluxMouseoverKeybind.lua#L2254) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
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
| [Blizzard/Hide.lua:247](../../Blizzard/Hide.lua#L247) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
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
| [Core/BorderJunctions.lua:6137](../../Core/BorderJunctions.lua#L6137) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/BorderJunctions.lua:6138](../../Core/BorderJunctions.lua#L6138) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Core/BorderJunctions.lua:6139](../../Core/BorderJunctions.lua#L6139) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [Core/BorderJunctions.lua:6140](../../Core/BorderJunctions.lua#L6140) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [Core/ButtonFX/Overlay.lua:1891](../../Core/ButtonFX/Overlay.lua#L1891) | `RegisterEvent` | `"GLOBAL_MOUSE_UP"` |
| [Core/ButtonFX/Overlay.lua:2133](../../Core/ButtonFX/Overlay.lua#L2133) | `RegisterEvent` | `"GLOBAL_MOUSE_UP"` |
| [Core/Capabilities.lua:158](../../Core/Capabilities.lua#L158) | `RegisterEvent` | `"COMBAT_LOG_EVENT_UNFILTERED"` |
| [Core/Capabilities.lua:195](../../Core/Capabilities.lua#L195) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_RETICLE_TARGET", "player"` |
| [Core/Capabilities.lua:198](../../Core/Capabilities.lua#L198) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_RETICLE_CLEAR", "player"` |
| [Core/Capabilities.lua:526](../../Core/Capabilities.lua#L526) | `RegisterUnitEvent` | `"UNIT_HEALTH", "focus"` |
| [Core/Client_Camelot.lua:171](../../Core/Client_Camelot.lua#L171) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Core/Engine/Combat.lua:213](../../Core/Engine/Combat.lua#L213) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/Engine/Context.lua:281](../../Core/Engine/Context.lua#L281) | `Subscribe` | `fn` |
| [Core/Engine/Context.lua:537](../../Core/Engine/Context.lua#L537) | `RegisterEvent` | `"UPDATE_MOUSEOVER_UNIT"` |
| [Core/Engine/Context.lua:538](../../Core/Engine/Context.lua#L538) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [Core/Engine/Context.lua:539](../../Core/Engine/Context.lua#L539) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/Engine/Context.lua:540](../../Core/Engine/Context.lua#L540) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Core/Engine/Modifier.lua:94](../../Core/Engine/Modifier.lua#L94) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Core/Engine/Restricted.lua:359](../../Core/Engine/Restricted.lua#L359) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [Core/Engine/Restricted.lua:360](../../Core/Engine/Restricted.lua#L360) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [Core/Engine/Restricted.lua:361](../../Core/Engine/Restricted.lua#L361) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Core/Engine/Restricted.lua:362](../../Core/Engine/Restricted.lua#L362) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Core/Engine/Restricted.lua:363](../../Core/Engine/Restricted.lua#L363) | `RegisterEvent` | `"UNIT_PET"` |
| [Core/Engine/Restricted.lua:364](../../Core/Engine/Restricted.lua#L364) | `RegisterEvent` | `"UNIT_TARGET"` |
| [Core/Engine/Restricted.lua:365](../../Core/Engine/Restricted.lua#L365) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [Core/Engine/Restricted.lua:366](../../Core/Engine/Restricted.lua#L366) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [Core/Engine/Restricted.lua:367](../../Core/Engine/Restricted.lua#L367) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [Core/Engine/Restricted.lua:368](../../Core/Engine/Restricted.lua#L368) | `RegisterEvent` | `"ACTIONBAR_PAGE_CHANGED"` |
| [Core/Engine/Restricted.lua:369](../../Core/Engine/Restricted.lua#L369) | `RegisterEvent` | `"UPDATE_BONUS_ACTIONBAR"` |
| [Core/Engine/Restricted.lua:370](../../Core/Engine/Restricted.lua#L370) | `RegisterEvent` | `"UPDATE_STEALTH"` |
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
| [Core/FluxAPI/UI.lua:1347](../../Core/FluxAPI/UI.lua#L1347) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Core/FluxAPI/UI.lua:1348](../../Core/FluxAPI/UI.lua#L1348) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Core/FluxAPI/UI.lua:1349](../../Core/FluxAPI/UI.lua#L1349) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Core/FluxAPI/UI.lua:1350](../../Core/FluxAPI/UI.lua#L1350) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [Core/FluxAPI/UI.lua:1351](../../Core/FluxAPI/UI.lua#L1351) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [Core/FluxAPI/UI.lua:1352](../../Core/FluxAPI/UI.lua#L1352) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Core/FluxAPI/UI.lua:1353](../../Core/FluxAPI/UI.lua#L1353) | `RegisterUnitEvent` | `"UNIT_MAXPOWER", "player"` |
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
| [ExtraButtonSystem/CombatGrid/GridManager.lua:342](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L342) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/CombatGrid/GridManager.lua:343](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L343) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/CombatGrid/GridManager.lua:344](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L344) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:1924](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1924) | `RegisterEvent` | `"TRADE_SKILL_SHOW"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:2697](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2697) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:2698](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2698) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:2699](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2699) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:2700](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2700) | `RegisterEvent` | `"BAG_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:3555](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3555) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:3556](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3556) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/Engine/ConsumableBind.lua:3557](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3557) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
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
| [ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua:547](../../ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua#L547) | `RegisterEvent` | `"SPELLS_CHANGED"` |
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
| [ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua:208](../../ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua#L208) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:390](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L390) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:797](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L797) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua:798](../../ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua#L798) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:967](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L967) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:984](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L984) | `RegisterEvent` | `"ADDON_LOADED"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:985](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L985) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua:986](../../ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua#L986) | `RegisterEvent` | `"NEW_MOUNT_ADDED"` |
| [ExtraButtonSystem/NonCombatGrid/GridInit.lua:142](../../ExtraButtonSystem/NonCombatGrid/GridInit.lua#L142) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/GridInit.lua:143](../../ExtraButtonSystem/NonCombatGrid/GridInit.lua#L143) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua:832](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua#L832) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1184](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1184) | `RegisterEvent` | `"CURSOR_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1185](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1185) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1186](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1186) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1187](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1187) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1189](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1189) | `RegisterEvent` | `"TRANSMOG_OUTFITS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1190](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1190) | `RegisterEvent` | `"TRANSMOG_DISPLAYED_OUTFIT_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1194](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1194) | `RegisterEvent` | `"SPELL_UPDATE_CHARGES"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1199](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1199) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1201](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1201) | `RegisterEvent` | `"BAG_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1202](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1202) | `RegisterEvent` | `"CURRENT_SPELL_CAST_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1203](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1203) | `RegisterEvent` | `"ACTIONBAR_UPDATE_STATE"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1204](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1204) | `RegisterEvent` | `"COMPANION_UPDATE"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1206](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1206) | `RegisterEvent` | `"PET_JOURNAL_LIST_UPDATE"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1208](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1208) | `RegisterEvent` | `"PLAYER_MOUNT_DISPLAY_CHANGED"` |
| [ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua:1210](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1210) | `RegisterUnitEvent` | `"UNIT_PET", "player"` |
| [ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua:626](../../ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua#L626) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/Shared/HotkeyUtil.lua:442](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L442) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/Shared/HotkeyUtil.lua:443](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L443) | `RegisterEvent` | `"MODIFIER_STATE_CHANGED"` |
| [ExtraButtonSystem/Shared/HotkeyUtil.lua:444](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L444) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua:867](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L867) | `RegisterEvent` | `"GLOBAL_MOUSE_UP"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua:868](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L868) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:153](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L153) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:154](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L154) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:155](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L155) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:156](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L156) | `RegisterEvent` | `"ACTIONBAR_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:157](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L157) | `RegisterEvent` | `"BAG_UPDATE_COOLDOWN"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:158](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L158) | `RegisterEvent` | `"SPELL_UPDATE_USABLE"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:159](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L159) | `RegisterEvent` | `"ACTIONBAR_UPDATE_STATE"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:160](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L160) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:161](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L161) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:162](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L162) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:163](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L163) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:164](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L164) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:168](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L168) | `RegisterEvent` | `"PET_BATTLE_OPENING_START"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:169](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L169) | `RegisterEvent` | `"PET_BATTLE_CLOSE"` |
| [ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua:378](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L378) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [FluxBorder.lua:33](../../FluxBorder.lua#L33) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [FluxDefaultSettings.lua:56](../../FluxDefaultSettings.lua#L56) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [FluxDefaultSettings.lua:57](../../FluxDefaultSettings.lua#L57) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [FluxDefaultSettings.lua:58](../../FluxDefaultSettings.lua#L58) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [FluxDefaultSettings.lua:59](../../FluxDefaultSettings.lua#L59) | `RegisterEvent` | `"UPDATE_BINDINGS"` |
| [FluxDefaultSettings.lua:79](../../FluxDefaultSettings.lua#L79) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [FluxDefaultSettings.lua:1306](../../FluxDefaultSettings.lua#L1306) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [FluxDefaultSettings.lua:3028](../../FluxDefaultSettings.lua#L3028) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [FluxDefaultSettings.lua:3029](../../FluxDefaultSettings.lua#L3029) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [FluxDefaultSettings.lua:3030](../../FluxDefaultSettings.lua#L3030) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [FluxDefaultSettings.lua:3032](../../FluxDefaultSettings.lua#L3032) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [FluxDefaultSettings.lua:3035](../../FluxDefaultSettings.lua#L3035) | `RegisterEvent` | `"COMPACT_UNIT_FRAME_PROFILES_LOADED"` |
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
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:589](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L589) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:590](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L590) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:591](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L591) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:592](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L592) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:593](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L593) | `RegisterEvent` | `"SKILL_LINES_CHANGED"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:594](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L594) | `RegisterEvent` | `"UNIT_MAXHEALTH"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:595](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L595) | `RegisterEvent` | `"UNIT_MAXPOWER"` |
| [Inventory/FluxConsumableBest/FluxConsumableBest.lua:688](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L688) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [Inventory/FluxItemClass.lua:743](../../Inventory/FluxItemClass.lua#L743) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [Inventory/FluxItemClass.lua:744](../../Inventory/FluxItemClass.lua#L744) | `RegisterEvent` | `"GET_ITEM_INFO_RECEIVED"` |
| [Inventory/Init.lua:316](../../Inventory/Init.lua#L316) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:516](../../Inventory/Restock/Bank/FluxBankRestock.lua#L516) | `RegisterEvent` | `"BAG_UPDATE"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:517](../../Inventory/Restock/Bank/FluxBankRestock.lua#L517) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:518](../../Inventory/Restock/Bank/FluxBankRestock.lua#L518) | `RegisterEvent` | `"ITEM_UNLOCKED"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:519](../../Inventory/Restock/Bank/FluxBankRestock.lua#L519) | `RegisterEvent` | `"PLAYERBANKBAGSLOTS_CHANGED"` |
| [Inventory/Restock/Bank/FluxBankRestock.lua:2334](../../Inventory/Restock/Bank/FluxBankRestock.lua#L2334) | `RegisterEvent` | `"UI_ERROR_MESSAGE"` |
| [Inventory/Restock/Core/FluxRestockList.lua:1676](../../Inventory/Restock/Core/FluxRestockList.lua#L1676) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Core/FluxRestockSettings.lua:232](../../Inventory/Restock/Core/FluxRestockSettings.lua#L232) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Junk/FluxJunk.lua:1725](../../Inventory/Restock/Junk/FluxJunk.lua#L1725) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Junk/FluxJunk.lua:1726](../../Inventory/Restock/Junk/FluxJunk.lua#L1726) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1881](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1881) | `RegisterEvent` | `ev` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1965](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1965) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1966](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1966) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1967](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1967) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [Inventory/Restock/Junk/FluxJunkOverlay.lua:1968](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1968) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [Inventory/Restock/Junk/FluxVendorJunkPanel.lua:714](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L714) | `RegisterEvent` | `"ITEM_DATA_LOAD_RESULT"` |
| [Inventory/Restock/Junk/FluxVendorJunkPanel.lua:760](../../Inventory/Restock/Junk/FluxVendorJunkPanel.lua#L760) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua:154](../../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua#L154) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnown.lua:496](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L496) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnown.lua:497](../../Inventory/Restock/Vendor/FluxAlreadyKnown.lua#L497) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua:574](../../Inventory/Restock/Vendor/FluxAlreadyKnownClassic.lua#L574) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua:94](../../Inventory/Restock/Vendor/FluxAlreadyKnownShared.lua#L94) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua:3462](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3462) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua:3463](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3463) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua:3464](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3464) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1717](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1717) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1718](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1718) | `RegisterEvent` | `"MERCHANT_UPDATE"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1719](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1719) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1720](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1720) | `RegisterEvent` | `"UI_ERROR_MESSAGE"` |
| [Inventory/Restock/Vendor/FluxVendorBuy.lua:1728](../../Inventory/Restock/Vendor/FluxVendorBuy.lua#L1728) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Vendor/FluxVendorRestockPanel.lua:1084](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1084) | `RegisterEvent` | `"BAG_UPDATE_DELAYED"` |
| [Inventory/Restock/Vendor/FluxVendorRestockPanel.lua:1271](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1271) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Layout/UnifiedBorder.lua:912](../../Layout/UnifiedBorder.lua#L912) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Layout/UnifiedBorder.lua:913](../../Layout/UnifiedBorder.lua#L913) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Layout/UnifiedBorder.lua:914](../../Layout/UnifiedBorder.lua#L914) | `RegisterEvent` | `"ACTIONBAR_SLOT_CHANGED"` |
| [Layout/UnifiedBorder.lua:915](../../Layout/UnifiedBorder.lua#L915) | `RegisterEvent` | `"CURSOR_CHANGED"` |
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
| [Mail/Restock.lua:217](../../Mail/Restock.lua#L217) | `RegisterEvent` | `event` |
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
| [MicroMenu/FluxLFGMicroButton.lua:465](../../MicroMenu/FluxLFGMicroButton.lua#L465) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [MicroMenu/FluxLFGMicroButton.lua:466](../../MicroMenu/FluxLFGMicroButton.lua#L466) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxMicroMenu.lua:435](../../MicroMenu/FluxMicroMenu.lua#L435) | `RegisterEvent` | `"UNIT_PORTRAIT_UPDATE"` |
| [MicroMenu/FluxMicroMenu.lua:436](../../MicroMenu/FluxMicroMenu.lua#L436) | `RegisterEvent` | `"PORTRAITS_UPDATED"` |
| [MicroMenu/FluxMicroMenu.lua:437](../../MicroMenu/FluxMicroMenu.lua#L437) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxMicroMenu.lua:3110](../../MicroMenu/FluxMicroMenu.lua#L3110) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [MicroMenu/FluxMicroMenu.lua:3111](../../MicroMenu/FluxMicroMenu.lua#L3111) | `RegisterEvent` | `"ADDON_LOADED"` |
| [MicroMenu/FluxMicroMenu.lua:3112](../../MicroMenu/FluxMicroMenu.lua#L3112) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [MicroMenu/FluxMicroMenu.lua:3113](../../MicroMenu/FluxMicroMenu.lua#L3113) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [MicroMenu/FluxMicroMenu.lua:3114](../../MicroMenu/FluxMicroMenu.lua#L3114) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [MicroMenu/FluxMicroMenu.lua:3115](../../MicroMenu/FluxMicroMenu.lua#L3115) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [MicroMenu/FluxMicroMenu.lua:3116](../../MicroMenu/FluxMicroMenu.lua#L3116) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
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
| [Minimap/FluxMinimap.lua:467](../../Minimap/FluxMinimap.lua#L467) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:468](../../Minimap/FluxMinimap.lua#L468) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [Minimap/FluxMinimap.lua:469](../../Minimap/FluxMinimap.lua#L469) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [Minimap/FluxMinimap.lua:471](../../Minimap/FluxMinimap.lua#L471) | `RegisterEvent` | `"EDIT_MODE_LAYOUTS_UPDATED"` |
| [Minimap/FluxMinimap.lua:900](../../Minimap/FluxMinimap.lua#L900) | `RegisterEvent` | `"UPDATE_PENDING_MAIL"` |
| [Minimap/FluxMinimap.lua:901](../../Minimap/FluxMinimap.lua#L901) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:1296](../../Minimap/FluxMinimap.lua#L1296) | `RegisterEvent` | `"UPDATE_BATTLEFIELD_STATUS"` |
| [Minimap/FluxMinimap.lua:1297](../../Minimap/FluxMinimap.lua#L1297) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:1298](../../Minimap/FluxMinimap.lua#L1298) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimap.lua:1299](../../Minimap/FluxMinimap.lua#L1299) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [Minimap/FluxMinimap.lua:1300](../../Minimap/FluxMinimap.lua#L1300) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [Minimap/FluxMinimap.lua:1301](../../Minimap/FluxMinimap.lua#L1301) | `RegisterEvent` | `"EDIT_MODE_LAYOUTS_UPDATED"` |
| [Minimap/FluxMinimap.lua:1302](../../Minimap/FluxMinimap.lua#L1302) | `RegisterEvent` | `"PVPQUEUE_ANYWHERE_SHOW"` |
| [Minimap/FluxMinimap.lua:1303](../../Minimap/FluxMinimap.lua#L1303) | `RegisterEvent` | `"PVPQUEUE_ANYWHERE_UPDATE_AVAILABLE"` |
| [Minimap/FluxMinimap.lua:2007](../../Minimap/FluxMinimap.lua#L2007) | `RegisterEvent` | `"ZONE_CHANGED"` |
| [Minimap/FluxMinimap.lua:2008](../../Minimap/FluxMinimap.lua#L2008) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [Minimap/FluxMinimap.lua:2009](../../Minimap/FluxMinimap.lua#L2009) | `RegisterEvent` | `"ZONE_CHANGED_INDOORS"` |
| [Minimap/FluxMinimap.lua:2010](../../Minimap/FluxMinimap.lua#L2010) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxMinimap.lua:2383](../../Minimap/FluxMinimap.lua#L2383) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimap.lua:2622](../../Minimap/FluxMinimap.lua#L2622) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimapButtons.lua:727](../../Minimap/FluxMinimapButtons.lua#L727) | `RegisterEvent` | `"CURSOR_CHANGED"` |
| [Minimap/FluxMinimapButtons.lua:769](../../Minimap/FluxMinimapButtons.lua#L769) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Minimap/FluxMinimapButtons.lua:770](../../Minimap/FluxMinimapButtons.lua#L770) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Minimap/FluxMinimapButtons.lua:771](../../Minimap/FluxMinimapButtons.lua#L771) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxMinimapButtons.lua:772](../../Minimap/FluxMinimapButtons.lua#L772) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [Minimap/FluxMinimapButtons.lua:773](../../Minimap/FluxMinimapButtons.lua#L773) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:248](../../Minimap/FluxObjectiveTrackerScroll.lua#L248) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:630](../../Minimap/FluxObjectiveTrackerScroll.lua#L630) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:1089](../../Minimap/FluxObjectiveTrackerScroll.lua#L1089) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:1307](../../Minimap/FluxObjectiveTrackerScroll.lua#L1307) | `RegisterEvent` | `"QUEST_LOG_UPDATE"` |
| [Minimap/FluxObjectiveTrackerScroll.lua:1541](../../Minimap/FluxObjectiveTrackerScroll.lua#L1541) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Minimap/FluxQuestie.lua:9](../../Minimap/FluxQuestie.lua#L9) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Minimap/FluxQuestie.lua:10](../../Minimap/FluxQuestie.lua#L10) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Minimap/FluxQuestie.lua:11](../../Minimap/FluxQuestie.lua#L11) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Minimap/FluxQuestie.lua:12](../../Minimap/FluxQuestie.lua#L12) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [NamePlates/ComboPoints.lua:138](../../NamePlates/ComboPoints.lua#L138) | `RegisterEvent` | `event` |
| [NamePlates/ComboPoints.lua:142](../../NamePlates/ComboPoints.lua#L142) | `RegisterUnitEvent` | `event, "player", "vehicle"` |
| [NamePlates/ComboPoints.lua:145](../../NamePlates/ComboPoints.lua#L145) | `RegisterUnitEvent` | `"UNIT_POWER_POINT_CHARGE", "player", "vehicle"` |
| [NamePlates/Core.lua:615](../../NamePlates/Core.lua#L615) | `RegisterEvent` | `"NAME_PLATE_UNIT_ADDED"` |
| [NamePlates/Core.lua:616](../../NamePlates/Core.lua#L616) | `RegisterEvent` | `"NAME_PLATE_UNIT_REMOVED"` |
| [NamePlates/Core.lua:617](../../NamePlates/Core.lua#L617) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [NamePlates/Core.lua:618](../../NamePlates/Core.lua#L618) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [NamePlates/Core.lua:619](../../NamePlates/Core.lua#L619) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [NamePlates/Core.lua:620](../../NamePlates/Core.lua#L620) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
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
| [Other/FluxChatFrame.lua:1457](../../Other/FluxChatFrame.lua#L1457) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxChatFrame.lua:1458](../../Other/FluxChatFrame.lua#L1458) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxChatFrame.lua:1459](../../Other/FluxChatFrame.lua#L1459) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [Other/FluxChatFrame.lua:1460](../../Other/FluxChatFrame.lua#L1460) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxDurationBars.lua:101](../../Other/FluxDurationBars.lua#L101) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxDurationBars.lua:102](../../Other/FluxDurationBars.lua#L102) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxDurationBars.lua:103](../../Other/FluxDurationBars.lua#L103) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Other/FluxExtraAbilityHUD.lua:209](../../Other/FluxExtraAbilityHUD.lua#L209) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxHUDTooltip.lua:161](../../Other/FluxHUDTooltip.lua#L161) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxLoot.lua:454](../../Other/FluxLoot.lua#L454) | `RegisterEvent` | `"LOOT_READY"` |
| [Other/FluxLoot.lua:457](../../Other/FluxLoot.lua#L457) | `RegisterEvent` | `event` |
| [Other/FluxLoot.lua:543](../../Other/FluxLoot.lua#L543) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Other/FluxLootRollPosition.lua:40](../../Other/FluxLootRollPosition.lua#L40) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Other/FluxLootRollPosition.lua:84](../../Other/FluxLootRollPosition.lua#L84) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Other/FluxLootRollPosition.lua:85](../../Other/FluxLootRollPosition.lua#L85) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Other/FluxPerfCapture.lua:786](../../Other/FluxPerfCapture.lua#L786) | `RegisterEvent` | `event` |
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
| [RaidFrame/FluxRaidUnit.lua:29](../../RaidFrame/FluxRaidUnit.lua#L29) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Respec/FluxRespec_ActionBars.lua:826](../../Respec/FluxRespec_ActionBars.lua#L826) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:403](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L403) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:404](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L404) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:405](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L405) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:406](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L406) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_START", "player"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:407](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L407) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_SUCCEEDED", "player"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:408](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L408) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_STOP", "player"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:409](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L409) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_INTERRUPTED", "player"` |
| [Respec/FluxRespec_AtieshDualSpecFix.lua:410](../../Respec/FluxRespec_AtieshDualSpecFix.lua#L410) | `RegisterUnitEvent` | `"UNIT_SPELLCAST_FAILED", "player"` |
| [Respec/FluxRespec_Core.lua:730](../../Respec/FluxRespec_Core.lua#L730) | `RegisterEvent` | `"ADDON_LOADED"` |
| [Respec/FluxRespec_Core.lua:731](../../Respec/FluxRespec_Core.lua#L731) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_Core.lua:855](../../Respec/FluxRespec_Core.lua#L855) | `RegisterEvent` | `"PLAYER_SPECIALIZATION_CHANGED"` |
| [Respec/FluxRespec_Core.lua:858](../../Respec/FluxRespec_Core.lua#L858) | `RegisterEvent` | `"PLAYER_TALENT_UPDATE"` |
| [Respec/FluxRespec_Core.lua:859](../../Respec/FluxRespec_Core.lua#L859) | `RegisterEvent` | `"ACTIVE_TALENT_GROUP_CHANGED"` |
| [Respec/FluxRespec_Core.lua:860](../../Respec/FluxRespec_Core.lua#L860) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [Respec/FluxRespec_Core.lua:861](../../Respec/FluxRespec_Core.lua#L861) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [Respec/FluxRespec_Core.lua:899](../../Respec/FluxRespec_Core.lua#L899) | `RegisterEvent` | `"PLAYER_LOGIN"` |
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
| [Respec/FluxRespec_GearSetLock.lua:730](../../Respec/FluxRespec_GearSetLock.lua#L730) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [Respec/FluxRespec_GearSetLock.lua:733](../../Respec/FluxRespec_GearSetLock.lua#L733) | `RegisterEvent` | `"MERCHANT_SHOW"` |
| [Respec/FluxRespec_GearSetLock.lua:734](../../Respec/FluxRespec_GearSetLock.lua#L734) | `RegisterEvent` | `"MERCHANT_CLOSED"` |
| [Respec/FluxRespec_GearSetLock.lua:735](../../Respec/FluxRespec_GearSetLock.lua#L735) | `RegisterEvent` | `"SPELL_UPDATE_USABLE"` |
| [Respec/FluxRespec_GearSetLock.lua:736](../../Respec/FluxRespec_GearSetLock.lua#L736) | `RegisterEvent` | `"CURRENT_SPELL_CAST_CHANGED"` |
| [Respec/FluxRespec_GearSetLock.lua:738](../../Respec/FluxRespec_GearSetLock.lua#L738) | `RegisterEvent` | `"UNIT_SPELLCAST_SENT"` |
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
| [Respec/FluxRespec_UI.lua:3145](../../Respec/FluxRespec_UI.lua#L3145) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
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
| [StatusBars/FluxInfoFrame.lua:4931](../../StatusBars/FluxInfoFrame.lua#L4931) | `RegisterEvent` | `"ZONE_CHANGED"` |
| [StatusBars/FluxInfoFrame.lua:4932](../../StatusBars/FluxInfoFrame.lua#L4932) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [StatusBars/FluxInfoFrame.lua:4933](../../StatusBars/FluxInfoFrame.lua#L4933) | `RegisterEvent` | `"PLAYER_UPDATE_RESTING"` |
| [StatusBars/FluxInfoFrame.lua:4934](../../StatusBars/FluxInfoFrame.lua#L4934) | `RegisterEvent` | `"PLAYER_EQUIPMENT_CHANGED"` |
| [StatusBars/FluxInfoFrame.lua:4935](../../StatusBars/FluxInfoFrame.lua#L4935) | `RegisterEvent` | `"UPDATE_INVENTORY_ALERTS"` |
| [StatusBars/FluxInfoFrame.lua:4936](../../StatusBars/FluxInfoFrame.lua#L4936) | `RegisterUnitEvent` | `"UNIT_AURA", "player"` |
| [StatusBars/FluxInfoFrame.lua:4937](../../StatusBars/FluxInfoFrame.lua#L4937) | `RegisterEvent` | `"COMBAT_RATING_UPDATE"` |
| [StatusBars/FluxInfoFrame.lua:4938](../../StatusBars/FluxInfoFrame.lua#L4938) | `RegisterEvent` | `"MASTERY_UPDATE"` |
| [StatusBars/FluxInfoFrame.lua:4939](../../StatusBars/FluxInfoFrame.lua#L4939) | `RegisterEvent` | `"SPELL_POWER_CHANGED"` |
| [StatusBars/FluxInfoFrame.lua:4940](../../StatusBars/FluxInfoFrame.lua#L4940) | `RegisterUnitEvent` | `"UNIT_STATS", "player"` |
| [StatusBars/FluxInfoFrame.lua:4941](../../StatusBars/FluxInfoFrame.lua#L4941) | `RegisterEvent` | `"PLAYER_DAMAGE_DONE_MODS"` |
| [StatusBars/FluxInfoFrame.lua:4943](../../StatusBars/FluxInfoFrame.lua#L4943) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [StatusBars/FluxInfoFrame.lua:4944](../../StatusBars/FluxInfoFrame.lua#L4944) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [StatusBars/FluxInfoFrame.lua:4945](../../StatusBars/FluxInfoFrame.lua#L4945) | `RegisterUnitEvent` | `"UNIT_SPELL_HASTE", "player"` |
| [StatusBars/FluxInfoFrame.lua:5202](../../StatusBars/FluxInfoFrame.lua#L5202) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [StatusBars/FluxInfoFrame.lua:5203](../../StatusBars/FluxInfoFrame.lua#L5203) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
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
| [StatusBars/FluxStatusBar.lua:2571](../../StatusBars/FluxStatusBar.lua#L2571) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [StatusBars/FluxStatusBar.lua:2935](../../StatusBars/FluxStatusBar.lua#L2935) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [StatusBars/FluxStatusBar.lua:2936](../../StatusBars/FluxStatusBar.lua#L2936) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [StatusBars/FluxStatusBar.lua:2937](../../StatusBars/FluxStatusBar.lua#L2937) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [StatusBars/FluxStatusBar.lua:2938](../../StatusBars/FluxStatusBar.lua#L2938) | `RegisterEvent` | `"ADDON_LOADED"` |
| [StatusBars/FluxStatusBar.lua:2939](../../StatusBars/FluxStatusBar.lua#L2939) | `RegisterEvent` | `"PLAYER_XP_UPDATE"` |
| [StatusBars/FluxStatusBar.lua:2940](../../StatusBars/FluxStatusBar.lua#L2940) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [StatusBars/FluxStatusBar.lua:2941](../../StatusBars/FluxStatusBar.lua#L2941) | `RegisterEvent` | `"UPDATE_EXHAUSTION"` |
| [StatusBars/FluxStatusBar.lua:2942](../../StatusBars/FluxStatusBar.lua#L2942) | `RegisterEvent` | `"PLAYER_UPDATE_RESTING"` |
| [StatusBars/FluxStatusBar.lua:2943](../../StatusBars/FluxStatusBar.lua#L2943) | `RegisterEvent` | `"UPDATE_FACTION"` |
| [StatusBars/FluxStatusBar.lua:2944](../../StatusBars/FluxStatusBar.lua#L2944) | `RegisterEvent` | `"QUEST_LOG_UPDATE"` |
| [StatusBars/FluxStatusBar.lua:2945](../../StatusBars/FluxStatusBar.lua#L2945) | `RegisterEvent` | `"PLAYER_MONEY"` |
| [StatusBars/FluxStatusBar.lua:2946](../../StatusBars/FluxStatusBar.lua#L2946) | `RegisterEvent` | `"CURRENCY_DISPLAY_UPDATE"` |
| [StatusBars/FluxStatusBar.lua:2947](../../StatusBars/FluxStatusBar.lua#L2947) | `RegisterEvent` | `"UPDATE_INVENTORY_ALERTS"` |
| [UnitFrames/FluxCastBar.lua:3014](../../UnitFrames/FluxCastBar.lua#L3014) | `RegisterUnitEvent` | `event, unit` |
| [UnitFrames/FluxCastBar.lua:3047](../../UnitFrames/FluxCastBar.lua#L3047) | `RegisterEvent` | `"UNIT_SPELLCAST_SENT"` |
| [UnitFrames/FluxCastBar.lua:3732](../../UnitFrames/FluxCastBar.lua#L3732) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [UnitFrames/FluxCastBar.lua:3733](../../UnitFrames/FluxCastBar.lua#L3733) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxCastBarThemes.lua:983](../../UnitFrames/FluxCastBarThemes.lua#L983) | `RegisterEvent` | `"SPELLS_CHANGED"` |
| [UnitFrames/FluxCastBarThemes.lua:984](../../UnitFrames/FluxCastBarThemes.lua#L984) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
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
| [UnitFrames/FluxSwingTimer.lua:1952](../../UnitFrames/FluxSwingTimer.lua#L1952) | `RegisterEvent` | `"COMBAT_LOG_EVENT_UNFILTERED"` |
| [UnitFrames/FluxSwingTimer.lua:2268](../../UnitFrames/FluxSwingTimer.lua#L2268) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxSwingTimer.lua:2269](../../UnitFrames/FluxSwingTimer.lua#L2269) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxSwingTimer.lua:2271](../../UnitFrames/FluxSwingTimer.lua#L2271) | `RegisterEvent` | `"PLAYER_ENTER_COMBAT"` |
| [UnitFrames/FluxSwingTimer.lua:2274](../../UnitFrames/FluxSwingTimer.lua#L2274) | `RegisterEvent` | `"PLAYER_LEAVE_COMBAT"` |
| [UnitFrames/FluxSwingTimer.lua:2276](../../UnitFrames/FluxSwingTimer.lua#L2276) | `RegisterEvent` | `"UNIT_INVENTORY_CHANGED"` |
| [UnitFrames/FluxSwingTimer.lua:2277](../../UnitFrames/FluxSwingTimer.lua#L2277) | `RegisterEvent` | `"GET_ITEM_INFO_RECEIVED"` |
| [UnitFrames/FluxSwingTimer.lua:2278](../../UnitFrames/FluxSwingTimer.lua#L2278) | `RegisterEvent` | `"START_AUTOREPEAT_SPELL"` |
| [UnitFrames/FluxSwingTimer.lua:2279](../../UnitFrames/FluxSwingTimer.lua#L2279) | `RegisterEvent` | `"STOP_AUTOREPEAT_SPELL"` |
| [UnitFrames/FluxSwingTimer.lua:2280](../../UnitFrames/FluxSwingTimer.lua#L2280) | `RegisterEvent` | `"UNIT_SPELLCAST_SUCCEEDED"` |
| [UnitFrames/FluxSwingTimer.lua:2281](../../UnitFrames/FluxSwingTimer.lua#L2281) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxSwingTimer.lua:2283](../../UnitFrames/FluxSwingTimer.lua#L2283) | `RegisterUnitEvent` | `"UNIT_ATTACK_SPEED", "player"` |
| [UnitFrames/FluxSwingTimer.lua:2286](../../UnitFrames/FluxSwingTimer.lua#L2286) | `RegisterUnitEvent` | `"UNIT_COMBAT", "target"` |
| [UnitFrames/FluxSwingTimer.lua:2290](../../UnitFrames/FluxSwingTimer.lua#L2290) | `RegisterEvent` | `"PLAYER_SWING"` |
| [UnitFrames/FluxSwingTimer.lua:2293](../../UnitFrames/FluxSwingTimer.lua#L2293) | `RegisterEvent` | `"PLAYER_SWING_RANGE_UPDATE"` |
| [UnitFrames/FluxSwingTimer.lua:2296](../../UnitFrames/FluxSwingTimer.lua#L2296) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxSwingTimer.lua:2299](../../UnitFrames/FluxSwingTimer.lua#L2299) | `RegisterEvent` | `"WEAPON_SLOT_CHANGED"` |
| [UnitFrames/FluxSwingTimer.lua:2302](../../UnitFrames/FluxSwingTimer.lua#L2302) | `RegisterEvent` | `"ADDON_LOADED"` |
| [UnitFrames/FluxSwingTimer.lua:2318](../../UnitFrames/FluxSwingTimer.lua#L2318) | `RegisterEvent` | `"ADDON_RESTRICTION_STATE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2373](../../UnitFrames/FluxUnitFrames_Auras.lua#L2373) | `RegisterUnitEvent` | `"UNIT_AURA", frame.unit` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2374](../../UnitFrames/FluxUnitFrames_Auras.lua#L2374) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2375](../../UnitFrames/FluxUnitFrames_Auras.lua#L2375) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2376](../../UnitFrames/FluxUnitFrames_Auras.lua#L2376) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2378](../../UnitFrames/FluxUnitFrames_Auras.lua#L2378) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2380](../../UnitFrames/FluxUnitFrames_Auras.lua#L2380) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2425](../../UnitFrames/FluxUnitFrames_Auras.lua#L2425) | `RegisterEvent` | `"PLAYER_LOGOUT"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2482](../../UnitFrames/FluxUnitFrames_Auras.lua#L2482) | `RegisterEvent` | `"PLAYER_LOGIN"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2483](../../UnitFrames/FluxUnitFrames_Auras.lua#L2483) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2484](../../UnitFrames/FluxUnitFrames_Auras.lua#L2484) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Auras.lua:2485](../../UnitFrames/FluxUnitFrames_Auras.lua#L2485) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_DebuffTint.lua:346](../../UnitFrames/FluxUnitFrames_DebuffTint.lua#L346) | `RegisterEvent` | `event` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:321](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L321) | `RegisterUnitEvent` | `event, unpack(registration, 2)` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:323](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L323) | `RegisterEvent` | `event` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:416](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L416) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:417](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L417) | `RegisterEvent` | `"UNIT_ENTERED_VEHICLE"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:418](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L418) | `RegisterEvent` | `"UNIT_EXITED_VEHICLE"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:674](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L674) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:675](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L675) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:676](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L676) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:677](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L677) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua:678](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L678) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_Focus.lua:237](../../UnitFrames/FluxUnitFrames_Focus.lua#L237) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Focus.lua:238](../../UnitFrames/FluxUnitFrames_Focus.lua#L238) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:174](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L174) | `RegisterUnitEvent` | `"UNIT_CONNECTION", "focustarget"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:175](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L175) | `RegisterUnitEvent` | `"UNIT_FLAGS", "focustarget"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:176](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L176) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:177](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L177) | `RegisterEvent` | `"UNIT_TARGET"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:178](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L178) | `RegisterEvent` | `"UNIT_NAME_UPDATE"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:190](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L190) | `RegisterUnitEvent` | `"UNIT_HEALTH", "focustarget"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:191](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L191) | `RegisterUnitEvent` | `"UNIT_MAXHEALTH", "focustarget"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:223](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L223) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_FocusTarget.lua:224](../../UnitFrames/FluxUnitFrames_FocusTarget.lua#L224) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Party.lua:556](../../UnitFrames/FluxUnitFrames_Party.lua#L556) | `RegisterUnitEvent` | `event, unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:559](../../UnitFrames/FluxUnitFrames_Party.lua#L559) | `RegisterUnitEvent` | `"UNIT_TARGET", owner.unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:698](../../UnitFrames/FluxUnitFrames_Party.lua#L698) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:699](../../UnitFrames/FluxUnitFrames_Party.lua#L699) | `RegisterUnitEvent` | `"UNIT_PORTRAIT_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:700](../../UnitFrames/FluxUnitFrames_Party.lua#L700) | `RegisterUnitEvent` | `"UNIT_MODEL_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:701](../../UnitFrames/FluxUnitFrames_Party.lua#L701) | `RegisterUnitEvent` | `"UNIT_CONNECTION", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:702](../../UnitFrames/FluxUnitFrames_Party.lua#L702) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_Party.lua:703](../../UnitFrames/FluxUnitFrames_Party.lua#L703) | `RegisterUnitEvent` | `"UNIT_FLAGS", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:704](../../UnitFrames/FluxUnitFrames_Party.lua#L704) | `RegisterUnitEvent` | `"PLAYER_FLAGS_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:705](../../UnitFrames/FluxUnitFrames_Party.lua#L705) | `RegisterUnitEvent` | `"UNIT_FACTION", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:706](../../UnitFrames/FluxUnitFrames_Party.lua#L706) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:707](../../UnitFrames/FluxUnitFrames_Party.lua#L707) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Party.lua:708](../../UnitFrames/FluxUnitFrames_Party.lua#L708) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Party.lua:714](../../UnitFrames/FluxUnitFrames_Party.lua#L714) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [UnitFrames/FluxUnitFrames_Party.lua:728](../../UnitFrames/FluxUnitFrames_Party.lua#L728) | `RegisterEvent` | `"CVAR_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Party.lua:731](../../UnitFrames/FluxUnitFrames_Party.lua#L731) | `RegisterUnitEvent` | `"UNIT_AURA", unit` |
| [UnitFrames/FluxUnitFrames_Pet.lua:201](../../UnitFrames/FluxUnitFrames_Pet.lua#L201) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_Pet.lua:202](../../UnitFrames/FluxUnitFrames_Pet.lua#L202) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:601](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L601) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:602](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L602) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:603](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L603) | `RegisterUnitEvent` | `"UNIT_AURA", "pet"` |
| [UnitFrames/FluxUnitFrames_PetAuraTooltip.lua:605](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L605) | `RegisterEvent` | `"UNIT_AURA"` |
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
| [UnitFrames/FluxUnitFrames_Shared.lua:1365](../../UnitFrames/FluxUnitFrames_Shared.lua#L1365) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:5108](../../UnitFrames/FluxUnitFrames_Shared.lua#L5108) | `RegisterUnitEvent` | `"UNIT_TARGET", "player"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:5110](../../UnitFrames/FluxUnitFrames_Shared.lua#L5110) | `RegisterEvent` | `"UNIT_TARGET"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:5939](../../UnitFrames/FluxUnitFrames_Shared.lua#L5939) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:5940](../../UnitFrames/FluxUnitFrames_Shared.lua#L5940) | `RegisterEvent` | `"PLAYER_FLAGS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:5978](../../UnitFrames/FluxUnitFrames_Shared.lua#L5978) | `RegisterEvent` | `"RAID_TARGET_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:7201](../../UnitFrames/FluxUnitFrames_Shared.lua#L7201) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:8995](../../UnitFrames/FluxUnitFrames_Shared.lua#L8995) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9674](../../UnitFrames/FluxUnitFrames_Shared.lua#L9674) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9675](../../UnitFrames/FluxUnitFrames_Shared.lua#L9675) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9676](../../UnitFrames/FluxUnitFrames_Shared.lua#L9676) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9677](../../UnitFrames/FluxUnitFrames_Shared.lua#L9677) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9760](../../UnitFrames/FluxUnitFrames_Shared.lua#L9760) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9761](../../UnitFrames/FluxUnitFrames_Shared.lua#L9761) | `RegisterEvent` | `"UI_SCALE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9762](../../UnitFrames/FluxUnitFrames_Shared.lua#L9762) | `RegisterEvent` | `"DISPLAY_SIZE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9763](../../UnitFrames/FluxUnitFrames_Shared.lua#L9763) | `RegisterEvent` | `"UPDATE_SHAPESHIFT_FORM"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9764](../../UnitFrames/FluxUnitFrames_Shared.lua#L9764) | `RegisterUnitEvent` | `"UNIT_HEALTH", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9765](../../UnitFrames/FluxUnitFrames_Shared.lua#L9765) | `RegisterUnitEvent` | `"UNIT_MAXHEALTH", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9766](../../UnitFrames/FluxUnitFrames_Shared.lua#L9766) | `RegisterUnitEvent` | `"UNIT_POWER_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9767](../../UnitFrames/FluxUnitFrames_Shared.lua#L9767) | `RegisterUnitEvent` | `"UNIT_MAXPOWER", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9768](../../UnitFrames/FluxUnitFrames_Shared.lua#L9768) | `RegisterUnitEvent` | `"UNIT_DISPLAYPOWER", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9776](../../UnitFrames/FluxUnitFrames_Shared.lua#L9776) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9777](../../UnitFrames/FluxUnitFrames_Shared.lua#L9777) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9781](../../UnitFrames/FluxUnitFrames_Shared.lua#L9781) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9783](../../UnitFrames/FluxUnitFrames_Shared.lua#L9783) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9784](../../UnitFrames/FluxUnitFrames_Shared.lua#L9784) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9785](../../UnitFrames/FluxUnitFrames_Shared.lua#L9785) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9786](../../UnitFrames/FluxUnitFrames_Shared.lua#L9786) | `RegisterEvent` | `"UNIT_THREAT_LIST_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9788](../../UnitFrames/FluxUnitFrames_Shared.lua#L9788) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9789](../../UnitFrames/FluxUnitFrames_Shared.lua#L9789) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9790](../../UnitFrames/FluxUnitFrames_Shared.lua#L9790) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9793](../../UnitFrames/FluxUnitFrames_Shared.lua#L9793) | `RegisterUnitEvent` | `"UNIT_TARGET", "target"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9798](../../UnitFrames/FluxUnitFrames_Shared.lua#L9798) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9799](../../UnitFrames/FluxUnitFrames_Shared.lua#L9799) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9804](../../UnitFrames/FluxUnitFrames_Shared.lua#L9804) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9806](../../UnitFrames/FluxUnitFrames_Shared.lua#L9806) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9808](../../UnitFrames/FluxUnitFrames_Shared.lua#L9808) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9809](../../UnitFrames/FluxUnitFrames_Shared.lua#L9809) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9810](../../UnitFrames/FluxUnitFrames_Shared.lua#L9810) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9811](../../UnitFrames/FluxUnitFrames_Shared.lua#L9811) | `RegisterEvent` | `"PLAYER_LEVEL_UP"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9812](../../UnitFrames/FluxUnitFrames_Shared.lua#L9812) | `RegisterEvent` | `"UNIT_THREAT_LIST_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9814](../../UnitFrames/FluxUnitFrames_Shared.lua#L9814) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9818](../../UnitFrames/FluxUnitFrames_Shared.lua#L9818) | `RegisterEvent` | `"PLAYER_FOCUS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9820](../../UnitFrames/FluxUnitFrames_Shared.lua#L9820) | `RegisterUnitEvent` | `"UNIT_TARGET", "focus"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9821](../../UnitFrames/FluxUnitFrames_Shared.lua#L9821) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9823](../../UnitFrames/FluxUnitFrames_Shared.lua#L9823) | `RegisterUnitEvent` | `"UNIT_CLASSIFICATION_CHANGED", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9824](../../UnitFrames/FluxUnitFrames_Shared.lua#L9824) | `RegisterUnitEvent` | `"UNIT_LEVEL", unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9827](../../UnitFrames/FluxUnitFrames_Shared.lua#L9827) | `RegisterEvent` | `"UNIT_PET"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9832](../../UnitFrames/FluxUnitFrames_Shared.lua#L9832) | `RegisterUnitEvent` | `"UNIT_NAME_UPDATE", "player", "pet"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9836](../../UnitFrames/FluxUnitFrames_Shared.lua#L9836) | `RegisterEvent` | `"PLAYER_REGEN_DISABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9837](../../UnitFrames/FluxUnitFrames_Shared.lua#L9837) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9838](../../UnitFrames/FluxUnitFrames_Shared.lua#L9838) | `RegisterEvent` | `"PLAYER_UPDATE_RESTING"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9839](../../UnitFrames/FluxUnitFrames_Shared.lua#L9839) | `RegisterEvent` | `"PLAYER_FLAGS_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9843](../../UnitFrames/FluxUnitFrames_Shared.lua#L9843) | `RegisterEvent` | `"GROUP_ROSTER_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9844](../../UnitFrames/FluxUnitFrames_Shared.lua#L9844) | `RegisterEvent` | `"RAID_ROSTER_UPDATE"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9845](../../UnitFrames/FluxUnitFrames_Shared.lua#L9845) | `RegisterEvent` | `"PARTY_LEADER_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9849](../../UnitFrames/FluxUnitFrames_Shared.lua#L9849) | `RegisterEvent` | `"PARTY_LOOT_METHOD_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9853](../../UnitFrames/FluxUnitFrames_Shared.lua#L9853) | `RegisterUnitEvent` | `"UNIT_FACTION", frame.unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9854](../../UnitFrames/FluxUnitFrames_Shared.lua#L9854) | `RegisterUnitEvent` | `"PLAYER_FLAGS_CHANGED", frame.unit` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9858](../../UnitFrames/FluxUnitFrames_Shared.lua#L9858) | `RegisterEvent` | `"ZONE_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9859](../../UnitFrames/FluxUnitFrames_Shared.lua#L9859) | `RegisterEvent` | `"ZONE_CHANGED_NEW_AREA"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9860](../../UnitFrames/FluxUnitFrames_Shared.lua#L9860) | `RegisterEvent` | `"ZONE_CHANGED_INDOORS"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9861](../../UnitFrames/FluxUnitFrames_Shared.lua#L9861) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Shared.lua:9995](../../UnitFrames/FluxUnitFrames_Shared.lua#L9995) | `RegisterEvent` | `"CVAR_UPDATE"` |
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
| [UnitFrames/FluxUnitFrames_Target.lua:318](../../UnitFrames/FluxUnitFrames_Target.lua#L318) | `RegisterEvent` | `"PLAYER_TARGET_CHANGED"` |
| [UnitFrames/FluxUnitFrames_Target.lua:319](../../UnitFrames/FluxUnitFrames_Target.lua#L319) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |
| [UnitFrames/FluxUnitFrames_Target.lua:320](../../UnitFrames/FluxUnitFrames_Target.lua#L320) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [UnitFrames/FluxUnitFrames_TargetOfTarget.lua:130](../../UnitFrames/FluxUnitFrames_TargetOfTarget.lua#L130) | `RegisterEvent` | `"PLAYER_REGEN_ENABLED"` |
| [WindowMover/Engine.lua:970](../../WindowMover/Engine.lua#L970) | `RegisterEvent` | `"ADDON_LOADED"` |
| [WindowMover/Engine.lua:971](../../WindowMover/Engine.lua#L971) | `RegisterEvent` | `"PLAYER_ENTERING_WORLD"` |

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
| `item.valueinfo.func` | [L512](../../AddonOptions/FluxOptionsWidgets.lua#L512) |
| `row.SetLabel` | [L530](../../AddonOptions/FluxOptionsWidgets.lua#L530) |
| `endrow.SetDescription` | [L534](../../AddonOptions/FluxOptionsWidgets.lua#L534) |
| `endrow.SetGetter` | [L537](../../AddonOptions/FluxOptionsWidgets.lua#L537) |
| `endrow.SetValue` | [L541](../../AddonOptions/FluxOptionsWidgets.lua#L541) |
| `endrow.SetDisabled` | [L545](../../AddonOptions/FluxOptionsWidgets.lua#L545) |
| `endrow.SetOnChange` | [L549](../../AddonOptions/FluxOptionsWidgets.lua#L549) |
| `W.CreateSlider` | [L573](../../AddonOptions/FluxOptionsWidgets.lua#L573) |
| `row.SetLabel` | [L654](../../AddonOptions/FluxOptionsWidgets.lua#L654) |
| `endrow.SetDescription` | [L658](../../AddonOptions/FluxOptionsWidgets.lua#L658) |
| `endrow.Configure` | [L661](../../AddonOptions/FluxOptionsWidgets.lua#L661) |
| `endrow.SetValue` | [L680](../../AddonOptions/FluxOptionsWidgets.lua#L680) |
| `endrow.SetDisabled` | [L689](../../AddonOptions/FluxOptionsWidgets.lua#L689) |
| `endrow.SetOnChange` | [L694](../../AddonOptions/FluxOptionsWidgets.lua#L694) |
| `fnendrow.SetOnCommit` | [L697](../../AddonOptions/FluxOptionsWidgets.lua#L697) |
| `W.CreateColor` | [L706](../../AddonOptions/FluxOptionsWidgets.lua#L706) |
| `hasAlphaandtrueorfalseColorPickerFrame.func` | [L777](../../AddonOptions/FluxOptionsWidgets.lua#L777) |
| `endColorPickerFrame.cancelFunc` | [L781](../../AddonOptions/FluxOptionsWidgets.lua#L781) |
| `row.SetLabel` | [L796](../../AddonOptions/FluxOptionsWidgets.lua#L796) |
| `endrow.SetDescription` | [L800](../../AddonOptions/FluxOptionsWidgets.lua#L800) |
| `endrow.SetHasAlpha` | [L803](../../AddonOptions/FluxOptionsWidgets.lua#L803) |
| `vandtrueorfalseendrow.SetValue` | [L806](../../AddonOptions/FluxOptionsWidgets.lua#L806) |
| `endrow.SetDisabled` | [L813](../../AddonOptions/FluxOptionsWidgets.lua#L813) |
| `endrow.SetOnChange` | [L818](../../AddonOptions/FluxOptionsWidgets.lua#L818) |
| `W.CreateButton` | [L825](../../AddonOptions/FluxOptionsWidgets.lua#L825) |
| `row.SetLabel` | [L872](../../AddonOptions/FluxOptionsWidgets.lua#L872) |
| `endrow.SetButtonText` | [L876](../../AddonOptions/FluxOptionsWidgets.lua#L876) |
| `endrow.SetDescription` | [L880](../../AddonOptions/FluxOptionsWidgets.lua#L880) |
| `endrow.SetDisabled` | [L883](../../AddonOptions/FluxOptionsWidgets.lua#L883) |
| `endrow.SetOnClick` | [L888](../../AddonOptions/FluxOptionsWidgets.lua#L888) |
| `W.CreateInput` | [L894](../../AddonOptions/FluxOptionsWidgets.lua#L894) |
| `row.SetLabel` | [L934](../../AddonOptions/FluxOptionsWidgets.lua#L934) |
| `endrow.SetDescription` | [L938](../../AddonOptions/FluxOptionsWidgets.lua#L938) |
| `endrow.SetValue` | [L941](../../AddonOptions/FluxOptionsWidgets.lua#L941) |
| `endrow.SetDisabled` | [L944](../../AddonOptions/FluxOptionsWidgets.lua#L944) |
| `endrow.SetOnCommit` | [L950](../../AddonOptions/FluxOptionsWidgets.lua#L950) |
| `W.CreateMoreButton` | [L956](../../AddonOptions/FluxOptionsWidgets.lua#L956) |
| `endrow.SetOpen` | [L966](../../AddonOptions/FluxOptionsWidgets.lua#L966) |
| `row.SetOnClick` | [L976](../../AddonOptions/FluxOptionsWidgets.lua#L976) |
| `W.CreateScroll` | [L984](../../AddonOptions/FluxOptionsWidgets.lua#L984) |
| `api:SetContentHeight` | [L1038](../../AddonOptions/FluxOptionsWidgets.lua#L1038) |
| `api:GetContentWidth` | [L1050](../../AddonOptions/FluxOptionsWidgets.lua#L1050) |
| `api:GetViewHeight` | [L1057](../../AddonOptions/FluxOptionsWidgets.lua#L1057) |
| `api:ResetScroll` | [L1060](../../AddonOptions/FluxOptionsWidgets.lua#L1060) |

### BaganatorCompat/FluxBaganator_BankRestock.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.ForEachBaganatorBankView` | [L77](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L77) |
| `Compat.GetActiveBaganatorBankView` | [L126](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L126) |
| `Compat.SyncBaganatorBankLive` | [L148](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L148) |
| `Compat.AttachBankRestockButton` | [L173](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L173) |
| `bankView.UpdateTransferButtonbankView.UpdateTransferButton` | [L193](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L193) |
| `bankView.OnTabFinishedbankView.OnTabFinished` | [L203](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L203) |
| `Compat.FinalizeBankRestock` | [L265](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L265) |
| `Compat.InitBankRestock` | [L271](../../BaganatorCompat/FluxBaganator_BankRestock.lua#L271) |

### BaganatorCompat/FluxBaganator_CategoryIcons.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `origfontString.GetUnboundedStringWidth` | [L65](../../BaganatorCompat/FluxBaganator_CategoryIcons.lua#L65) |
| `Compat.ApplyCategoryLabelIcon` | [L129](../../BaganatorCompat/FluxBaganator_CategoryIcons.lua#L129) |
| `label.SetWidthlabel.SetWidth` | [L174](../../BaganatorCompat/FluxBaganator_CategoryIcons.lua#L174) |
| `Compat.InitCategoryIcons` | [L222](../../BaganatorCompat/FluxBaganator_CategoryIcons.lua#L222) |

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
| `Compat.SyncConsumablesCategories` | [L231](../../BaganatorCompat/FluxBaganator_ConsumablesCategories.lua#L231) |
| `Compat.InitConsumablesCategories` | [L375](../../BaganatorCompat/FluxBaganator_ConsumablesCategories.lua#L375) |

### BaganatorCompat/FluxBaganator_EquipmentSetSection.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.EnsureEquipmentSetSection` | [L147](../../BaganatorCompat/FluxBaganator_EquipmentSetSection.lua#L147) |
| `Compat.InitEquipmentSetSection` | [L192](../../BaganatorCompat/FluxBaganator_EquipmentSetSection.lua#L192) |

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
| `Compat.InitGearSets` | [L506](../../BaganatorCompat/FluxBaganator_GearSets.lua#L506) |

### BaganatorCompat/FluxBaganator_GearSetShield.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.RefreshShieldOnBaganatorButton` | [L90](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L90) |
| `Compat.RefreshVisibleGearSetShields` | [L94](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L94) |
| `Compat.RequestGearSetShieldRefresh` | [L104](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L104) |
| `Compat.ConfigureBaganatorGearSetCorners` | [L158](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L158) |
| `Compat.InitGearSetShield` | [L200](../../BaganatorCompat/FluxBaganator_GearSetShield.lua#L200) |

### BaganatorCompat/FluxBaganator_ItemViews.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.TrackBaganatorView` | [L43](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L43) |
| `Compat.ForEachVisibleBaganatorView` | [L66](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L66) |
| `Compat.ResolveBaganatorItemButtonSlot` | [L95](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L95) |
| `Compat.ForEachRegisteredBaganatorItemButton` | [L164](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L164) |
| `Compat.ForEachBaganatorItemButton` | [L190](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L190) |
| `Compat.ForEachVisibleItemButton` | [L280](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L280) |
| `Compat.InitBaganatorViewTracking` | [L307](../../BaganatorCompat/FluxBaganator_ItemViews.lua#L307) |

### BaganatorCompat/FluxBaganator_Junk.lua

Owner: [24-baganator-compat.md](../24-baganator-compat.md).

| Declaration | Source |
|---|---|
| `Compat.RequestBaganatorRefresh` | [L25](../../BaganatorCompat/FluxBaganator_Junk.lua#L25) |
| `Compat.RequestBaganatorCategoryDataRefresh` | [L46](../../BaganatorCompat/FluxBaganator_Junk.lua#L46) |
| `Compat.ConfigureBaganatorJunkDetector` | [L81](../../BaganatorCompat/FluxBaganator_Junk.lua#L81) |
| `Compat.InitJunk` | [L112](../../BaganatorCompat/FluxBaganator_Junk.lua#L112) |

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
| `BadgeHost.PrepareSecureAuraForSlot` | [L653](../../Bars/BadgeHost.lua#L653) |
| `BadgeHost.SetSlotBadges` | [L840](../../Bars/BadgeHost.lua#L840) |
| `BadgeHost.ApplyMap` | [L859](../../Bars/BadgeHost.lua#L859) |
| `BadgeHost.ClearSlot` | [L873](../../Bars/BadgeHost.lua#L873) |
| `BadgeHost.GetSlotBadges` | [L877](../../Bars/BadgeHost.lua#L877) |
| `BadgeHost.HasAny` | [L881](../../Bars/BadgeHost.lua#L881) |
| `BadgeHost.EachIndexedBody` | [L885](../../Bars/BadgeHost.lua#L885) |
| `BadgeHost.NotifyDisplay` | [L906](../../Bars/BadgeHost.lua#L906) |
| `BadgeHost.RefreshFormVisibility` | [L949](../../Bars/BadgeHost.lua#L949) |
| `BadgeHost.OnIdentityChange` | [L1005](../../Bars/BadgeHost.lua#L1005) |
| `BadgeHost.SyncShownFaces` | [L1038](../../Bars/BadgeHost.lua#L1038) |
| `BadgeHost.RefreshOccupancyVisibility` | [L1068](../../Bars/BadgeHost.lua#L1068) |
| `BadgeHost.NotifyModifierPaging` | [L1085](../../Bars/BadgeHost.lua#L1085) |
| `BadgeHost.RefreshDisplays` | [L1157](../../Bars/BadgeHost.lua#L1157) |
| `BadgeHost.RefreshMouseoverDisplays` | [L1171](../../Bars/BadgeHost.lua#L1171) |
| `BadgeHost.GetVisibleBadgesForButton` | [L1200](../../Bars/BadgeHost.lua#L1200) |
| `BadgeHost.RefreshLayout` | [L1252](../../Bars/BadgeHost.lua#L1252) |
| `BadgeHost.FlushCombatQueue` | [L1281](../../Bars/BadgeHost.lua#L1281) |

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
| `BM:Activate` | [L458](../../Bars/BindingMode.lua#L458) |
| `BM:Deactivate` | [L485](../../Bars/BindingMode.lua#L485) |
| `BM:Toggle` | [L500](../../Bars/BindingMode.lua#L500) |

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
| `widget.UpdateButtonArtwidget.UpdateButtonArt` | [L1065](../../Bars/Blizzard.lua#L1065) |
| `Blizzard.SkinButton` | [L1077](../../Bars/Blizzard.lua#L1077) |
| `Blizzard.Prepare` | [L1092](../../Bars/Blizzard.lua#L1092) |
| `Blizzard.Reassert` | [L1098](../../Bars/Blizzard.lua#L1098) |
| `Blizzard.QuietGrid` | [L1104](../../Bars/Blizzard.lua#L1104) |

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
| `Clicks.UseKeyDown` | [L42](../../Bars/Clicks.lua#L42) |
| `Clicks.Prepare` | [L52](../../Bars/Clicks.lua#L52) |
| `Clicks.ApplyRegistration` | [L68](../../Bars/Clicks.lua#L68) |
| `Clicks.InheritKeyerActions` | [L126](../../Bars/Clicks.lua#L126) |
| `Clicks.ReassertEmpower` | [L190](../../Bars/Clicks.lua#L190) |
| `Clicks.InvalidateKeys` | [L236](../../Bars/Clicks.lua#L236) |
| `Clicks.RefreshKeys` | [L260](../../Bars/Clicks.lua#L260) |
| `Clicks.OnCVar` | [L356](../../Bars/Clicks.lua#L356) |
| `Clicks.Start` | [L378](../../Bars/Clicks.lua#L378) |

### Bars/Effects.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Effects.GlowDiagnostics` | [L17](../../Bars/Effects.lua#L17) |
| `Effects.SetGlow` | [L257](../../Bars/Effects.lua#L257) |
| `Effects.InvalidateSecureAuraCandidates` | [L374](../../Bars/Effects.lua#L374) |
| `Effects.SyncColumn` | [L430](../../Bars/Effects.lua#L430) |
| `Effects.Refresh` | [L636](../../Bars/Effects.lua#L636) |
| `Effects.RefreshAll` | [L656](../../Bars/Effects.lua#L656) |
| `Effects.Start` | [L663](../../Bars/Effects.lua#L663) |

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
| `Hosts.UpdateTooltip` | [L465](../../Bars/Hosts.lua#L465) |
| `Hosts.RefreshHoverTooltip` | [L505](../../Bars/Hosts.lua#L505) |
| `Hosts.CreateSurface` | [L516](../../Bars/Hosts.lua#L516) |
| `Hosts.Skin` | [L841](../../Bars/Hosts.lua#L841) |
| `Hosts.FinishSurface` | [L851](../../Bars/Hosts.lua#L851) |
| `Hosts.Build` | [L888](../../Bars/Hosts.lua#L888) |
| `Hosts.ApplyChrome` | [L945](../../Bars/Hosts.lua#L945) |
| `Hosts.InvalidateKeys` | [L951](../../Bars/Hosts.lua#L951) |
| `Hosts.RefreshKeys` | [L957](../../Bars/Hosts.lua#L957) |
| `Hosts.PrepareClicks` | [L963](../../Bars/Hosts.lua#L963) |

### Bars/Init.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Bars.GetHost` | [L37](../../Bars/Init.lua#L37) |
| `Bars.GetMain` | [L41](../../Bars/Init.lua#L41) |
| `Bars.ForEach` | [L46](../../Bars/Init.lua#L46) |
| `Bars.ForEachHost` | [L57](../../Bars/Init.lua#L57) |
| `Bars.ForEachStatic` | [L76](../../Bars/Init.lua#L76) |
| `Bars.RequestLayout` | [L119](../../Bars/Init.lua#L119) |
| `Bars.RequestStockSweep` | [L172](../../Bars/Init.lua#L172) |
| `Bars.RequestPaint` | [L193](../../Bars/Init.lua#L193) |
| `Bars.ApplyLayout` | [L241](../../Bars/Init.lua#L241) |
| `Bars.Start` | [L295](../../Bars/Init.lua#L295) |
| `Bars.ApplyPerformanceSettings` | [L390](../../Bars/Init.lua#L390) |
| `Bars.ApplyActionbarsOptions` | [L417](../../Bars/Init.lua#L417) |
| `Bars.TraceColumn` | [L553](../../Bars/Init.lua#L553) |
| `Bars.TraceNextKey` | [L596](../../Bars/Init.lua#L596) |
| `Bars.AuditMainRow` | [L638](../../Bars/Init.lua#L638) |
| `Bars.RestoreMainRow` | [L683](../../Bars/Init.lua#L683) |

### Bars/Layout.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Layout.HasContentInAnyState` | [L75](../../Bars/Layout.lua#L75) |
| `Layout.HasContentOnMain` | [L94](../../Bars/Layout.lua#L94) |
| `Layout.IsColumnEmpty` | [L110](../../Bars/Layout.lua#L110) |
| `Layout.GetPromotedMode` | [L130](../../Bars/Layout.lua#L130) |
| `Layout.IsExpanding` | [L152](../../Bars/Layout.lua#L152) |
| `Layout.SetBindingMode` | [L173](../../Bars/Layout.lua#L173) |
| `Layout.MiniAtBottom` | [L184](../../Bars/Layout.lua#L184) |
| `Layout.InvalidateMappings` | [L194](../../Bars/Layout.lua#L194) |
| `Layout.ApplyMappings` | [L237](../../Bars/Layout.lua#L237) |
| `Layout.RevealEmptyInCombat` | [L308](../../Bars/Layout.lua#L308) |
| `Layout.AnyMiniVisible` | [L432](../../Bars/Layout.lua#L432) |
| `Layout.VisibleCount` | [L442](../../Bars/Layout.lua#L442) |
| `Layout.ApplyVisual` | [L508](../../Bars/Layout.lua#L508) |
| `Layout.Invalidate` | [L637](../../Bars/Layout.lua#L637) |
| `Layout.Apply` | [L642](../../Bars/Layout.lua#L642) |
| `Layout.Request` | [L693](../../Bars/Layout.lua#L693) |
| `Layout.HasPendingDragPose` | [L719](../../Bars/Layout.lua#L719) |
| `Layout.OnDragHover` | [L731](../../Bars/Layout.lua#L731) |
| `Layout.OnCursor` | [L757](../../Bars/Layout.lua#L757) |
| `Layout.Start` | [L776](../../Bars/Layout.lua#L776) |

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
| `Paint.ShownSpellId` | [L203](../../Bars/Paint.lua#L203) |
| `Paint.UpdateName` | [L498](../../Bars/Paint.lua#L498) |
| `Paint.UpdateIcon` | [L538](../../Bars/Paint.lua#L538) |
| `Paint.UpdateCount` | [L865](../../Bars/Paint.lua#L865) |
| `Paint.UpdateCooldown` | [L1206](../../Bars/Paint.lua#L1206) |
| `Paint.UpdateUsable` | [L1302](../../Bars/Paint.lua#L1302) |
| `Paint.NotePlayerCast` | [L1401](../../Bars/Paint.lua#L1401) |
| `Paint.NeedsRange` | [L1470](../../Bars/Paint.lua#L1470) |
| `Paint.UpdateRange` | [L1550](../../Bars/Paint.lua#L1550) |
| `Paint.ApplySlotRange` | [L1574](../../Bars/Paint.lua#L1574) |
| `Paint.SweepLitChecked` | [L1707](../../Bars/Paint.lua#L1707) |
| `Paint.ArmCheckedPoll` | [L1731](../../Bars/Paint.lua#L1731) |
| `Paint.UpdateFlash` | [L1747](../../Bars/Paint.lua#L1747) |
| `Paint.UpdateChecked` | [L1773](../../Bars/Paint.lua#L1773) |
| `Paint.UpdateEquipped` | [L1850](../../Bars/Paint.lua#L1850) |
| `Paint.AbbreviateKey` | [L1961](../../Bars/Paint.lua#L1961) |
| `Paint.UpdateHotkey` | [L1975](../../Bars/Paint.lua#L1975) |
| `Paint.UpdateAssistedCombat` | [L2104](../../Bars/Paint.lua#L2104) |
| `rot.OnUpdate` | [L2137](../../Bars/Paint.lua#L2137) |
| `Paint.UpdateAssistedHighlight` | [L2212](../../Bars/Paint.lua#L2212) |
| `Paint.PaintAssistedHighlights` | [L2293](../../Bars/Paint.lua#L2293) |
| `Paint.PaintAssistedHosts` | [L2305](../../Bars/Paint.lua#L2305) |
| `Paint.UpdateDisplay` | [L2327](../../Bars/Paint.lua#L2327) |
| `Paint.UpdateAll` | [L2344](../../Bars/Paint.lua#L2344) |
| `Paint.HostIsLive` | [L2354](../../Bars/Paint.lua#L2354) |
| `Paint.MarkDirty` | [L2370](../../Bars/Paint.lua#L2370) |
| `Paint.Dirty` | [L2378](../../Bars/Paint.lua#L2378) |
| `Paint.EachDirty` | [L2383](../../Bars/Paint.lua#L2383) |
| `Paint.Flush` | [L2584](../../Bars/Paint.lua#L2584) |
| `Paint.ClearCache` | [L2592](../../Bars/Paint.lua#L2592) |

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
| `Pet.LayoutButtons` | [L159](../../Bars/Pet/Layout.lua#L159) |

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
| `ProgramFace.CastBodyForSlot` | [L355](../../Bars/ProgramFace.lua#L355) |
| `ProgramFace.InvalidateIndex` | [L368](../../Bars/ProgramFace.lua#L368) |
| `ProgramFace.RebuildIndex` | [L378](../../Bars/ProgramFace.lua#L378) |
| `ProgramFace.Needs` | [L496](../../Bars/ProgramFace.lua#L496) |
| `ProgramFace.KindWanted` | [L529](../../Bars/ProgramFace.lua#L529) |
| `ProgramFace.ProbeFlags` | [L533](../../Bars/ProgramFace.lua#L533) |
| `ProgramFace.EachExtraMatching` | [L546](../../Bars/ProgramFace.lua#L546) |
| `ProgramFace.TranslateAll` | [L605](../../Bars/ProgramFace.lua#L605) |
| `ProgramFace.EachBody` | [L624](../../Bars/ProgramFace.lua#L624) |
| `ProgramFace.RequestRosterRefresh` | [L867](../../Bars/ProgramFace.lua#L867) |
| `ProgramFace.RegisterRosterRefresh` | [L876](../../Bars/ProgramFace.lua#L876) |
| `ProgramFace.RequestTarget` | [L886](../../Bars/ProgramFace.lua#L886) |
| `ProgramFace.NoteMouseoverEvent` | [L905](../../Bars/ProgramFace.lua#L905) |
| `ProgramFace.ArmMouseoverPoll` | [L939](../../Bars/ProgramFace.lua#L939) |
| `ProgramFace.WakeMouseoverPoll` | [L991](../../Bars/ProgramFace.lua#L991) |
| `ProgramFace.SetMouseoverPollInterval` | [L1004](../../Bars/ProgramFace.lua#L1004) |
| `ProgramFace.SetMinFlushInterval` | [L1017](../../Bars/ProgramFace.lua#L1017) |
| `ProgramFace.FlushPending` | [L1031](../../Bars/ProgramFace.lua#L1031) |
| `ProgramFace.Request` | [L1100](../../Bars/ProgramFace.lua#L1100) |
| `ProgramFace.RequestConditionalRefresh` | [L1131](../../Bars/ProgramFace.lua#L1131) |
| `ProgramFace.HasAny` | [L1135](../../Bars/ProgramFace.lua#L1135) |
| `ProgramFace.SyncHost` | [L1152](../../Bars/ProgramFace.lua#L1152) |
| `ProgramFace.TranslateHost` | [L1216](../../Bars/ProgramFace.lua#L1216) |
| `ProgramFace.ShownForSlot` | [L1256](../../Bars/ProgramFace.lua#L1256) |
| `ProgramFace.Shown` | [L1280](../../Bars/ProgramFace.lua#L1280) |
| `ProgramFace.RequestHoverPeek` | [L1433](../../Bars/ProgramFace.lua#L1433) |
| `ProgramFace.OnContext` | [L1508](../../Bars/ProgramFace.lua#L1508) |
| `ProgramFace.ContextOwnsDisplay` | [L1600](../../Bars/ProgramFace.lua#L1600) |
| `ProgramFace.Start` | [L1605](../../Bars/ProgramFace.lua#L1605) |

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
| `ApplyRankDesaturation` | [L613](../../Bars/SpellRank.lua#L613) |
| `UpdateHostDesaturation` | [L654](../../Bars/SpellRank.lua#L654) |
| `UpdateFluxButtonDesaturation` | [L661](../../Bars/SpellRank.lua#L661) |
| `UpdateAllButtonDesaturation` | [L671](../../Bars/SpellRank.lua#L671) |
| `SpellRank:RankUpAllSpells` | [L1016](../../Bars/SpellRank.lua#L1016) |
| `SpellRank:IsRankFeaturesSupported` | [L1402](../../Bars/SpellRank.lua#L1402) |
| `SpellRank:IsLowerRankSpell` | [L1406](../../Bars/SpellRank.lua#L1406) |
| `SpellRank:ApplyRankDesaturation` | [L1413](../../Bars/SpellRank.lua#L1413) |
| `SpellRank:RefreshColumnSurfaces` | [L1434](../../Bars/SpellRank.lua#L1434) |
| `SpellRank:RefreshColumnSurfacesPaging` | [L1464](../../Bars/SpellRank.lua#L1464) |
| `SpellRank:RefreshColumnAllRows` | [L1468](../../Bars/SpellRank.lua#L1468) |
| `SpellRank:RefreshColumnUsable` | [L1496](../../Bars/SpellRank.lua#L1496) |
| `SpellRank:ClearHostRankState` | [L1530](../../Bars/SpellRank.lua#L1530) |
| `SpellRank:ReassertDesaturation` | [L1548](../../Bars/SpellRank.lua#L1548) |
| `SpellRank:GetAutoRankUpEnabled` | [L1590](../../Bars/SpellRank.lua#L1590) |
| `SpellRank:SetAutoRankUpEnabled` | [L1597](../../Bars/SpellRank.lua#L1597) |
| `SpellRank:GetBlacklistSpellIDs` | [L1619](../../Bars/SpellRank.lua#L1619) |
| `SpellRank:ToggleSpellBlacklist` | [L1654](../../Bars/SpellRank.lua#L1654) |
| `SpellRank:ClearSpellFromBlacklist` | [L1661](../../Bars/SpellRank.lua#L1661) |
| `SpellRank:SetSpellBlacklistPanelRefreshHandler` | [L1681](../../Bars/SpellRank.lua#L1681) |
| `SpellRank:NotifySpellBlacklistPanelRefresh` | [L1685](../../Bars/SpellRank.lua#L1685) |
| `SpellRank:RefreshSpellBookRankUI` | [L1689](../../Bars/SpellRank.lua#L1689) |
| `SpellRank:RefreshAfterActionbarsScopedStorageChange` | [L1701](../../Bars/SpellRank.lua#L1701) |
| `SpellRank.RefreshAll` | [L1711](../../Bars/SpellRank.lua#L1711) |

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
| `Stance.ToggleSlotHidden` | [L105](../../Bars/Stance/Init.lua#L105) |
| `Stance.GetSlotOrderDescriptors` | [L110](../../Bars/Stance/Init.lua#L110) |
| `Stance.GetSlotOrderEditorRows` | [L161](../../Bars/Stance/Init.lua#L161) |
| `Stance.GetCanonicalToShapeshiftButtonBindingIndexMap` | [L176](../../Bars/Stance/Init.lua#L176) |
| `Stance.ReassignBindings` | [L210](../../Bars/Stance/Init.lua#L210) |
| `f.GetFrame` | [L270](../../Bars/Stance/Init.lua#L270) |
| `endf.Flux_ReanchorToLayout` | [L273](../../Bars/Stance/Init.lua#L273) |
| `endendf.RequestLayout` | [L285](../../Bars/Stance/Init.lua#L285) |
| `endendf.RequestSizeOnly` | [L290](../../Bars/Stance/Init.lua#L290) |
| `endendf.ReassignBindings` | [L295](../../Bars/Stance/Init.lua#L295) |
| `endf.ApplySavedSlotOrderAndRefresh` | [L298](../../Bars/Stance/Init.lua#L298) |
| `endendf.UpdateLayout` | [L303](../../Bars/Stance/Init.lua#L303) |
| `endendf.GetSlotOrderDescriptors` | [L308](../../Bars/Stance/Init.lua#L308) |
| `endf.GetSlotOrderEditorRows` | [L311](../../Bars/Stance/Init.lua#L311) |
| `endf.GetCanonicalToShapeshiftButtonBindingIndexMap` | [L314](../../Bars/Stance/Init.lua#L314) |
| `endf.ToggleStanceSlotHidden` | [L317](../../Bars/Stance/Init.lua#L317) |
| `endf.RemoveCustomSlot` | [L320](../../Bars/Stance/Init.lua#L320) |
| `endf.AddCustomFromCursor` | [L323](../../Bars/Stance/Init.lua#L323) |
| `Stance.Start` | [L330](../../Bars/Stance/Init.lua#L330) |

### Bars/Stance/Layout.lua

Owner: [11-action-bars.md](../11-action-bars.md).

| Declaration | Source |
|---|---|
| `Stance.ComputeLayoutMetrics` | [L90](../../Bars/Stance/Layout.lua#L90) |
| `Stance.Anchor` | [L210](../../Bars/Stance/Layout.lua#L210) |
| `Stance.ApplyLayout` | [L308](../../Bars/Stance/Layout.lua#L308) |
| `Stance.RequestLayout` | [L474](../../Bars/Stance/Layout.lua#L474) |
| `Stance.RequestSizeOnly` | [L499](../../Bars/Stance/Layout.lua#L499) |
| `Stance.RequestStripLayout` | [L543](../../Bars/Stance/Layout.lua#L543) |
| `Stance.RequestFormsVisual` | [L555](../../Bars/Stance/Layout.lua#L555) |
| `Stance.RequestExtrasVisual` | [L575](../../Bars/Stance/Layout.lua#L575) |
| `Stance.RequestDiscover` | [L595](../../Bars/Stance/Layout.lua#L595) |

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
| `State.SyncMainKeyer` | [L663](../../Bars/State.lua#L663) |
| `State.Attach` | [L747](../../Bars/State.lua#L747) |
| `State.HeaderFor` | [L785](../../Bars/State.lua#L785) |
| `State.Create` | [L890](../../Bars/State.lua#L890) |
| `State.RegisterDrivers` | [L919](../../Bars/State.lua#L919) |
| `State.CurrentSwap` | [L1072](../../Bars/State.lua#L1072) |
| `State.ResolveCurrentSlot` | [L1085](../../Bars/State.lua#L1085) |
| `State.IndexLiveSlots` | [L1103](../../Bars/State.lua#L1103) |
| `State.ApplySlotsInsecure` | [L1151](../../Bars/State.lua#L1151) |
| `State.OnModFallback` | [L1198](../../Bars/State.lua#L1198) |
| `State.ForceApply` | [L1206](../../Bars/State.lua#L1206) |
| `State.GetClassStances` | [L1248](../../Bars/State.lua#L1248) |

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
| `Strip.Layout` | [L389](../../Bars/Strip.lua#L389) |

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
| `FluxBattlefieldMapPinRouter:IsLibrarySupported` | [L57](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L57) |
| `FluxBattlefieldMapPinRouter:ShouldRouteToBattlefield` | [L118](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L118) |
| `FluxBattlefieldMapPinRouter:IsHBDAvailable` | [L137](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L137) |
| `FluxBattlefieldMapPinRouter:IsHBDWorldProvider` | [L141](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L141) |
| `FluxBattlefieldMapPinRouter:GetRouteLabel` | [L160](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L160) |
| `canvaspool.createFunc` | [L225](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L225) |
| `frame.OnAcquiredframe.OnAcquired` | [L240](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L240) |
| `endendendreturnframeendpool.resetFunc` | [L251](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L251) |
| `canvaspool.createFunc` | [L319](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L319) |
| `route.battlefieldProvider.RefreshAllDataroute.battlefieldProvider.RefreshAllData` | [L567](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L567) |
| `endendworldProvider.HandlePin` | [L576](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L576) |
| `endworldProvider.RefreshAllData` | [L579](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L579) |
| `FluxBattlefieldMapPinRouter:RefreshAllThirdPartyPins` | [L702](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L702) |
| `FluxBattlefieldMapPinRouter:RequestRefresh` | [L733](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L733) |
| `FluxBattlefieldMapPinRouter:ScheduleKickstart` | [L745](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L745) |
| `FluxBattlefieldMapPinRouter:Install` | [L769](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L769) |
| `FluxBattlefieldMapPinRouter:Uninstall` | [L800](../../Battlezonemap/FluxBattlefieldMapPinRouter.lua#L800) |

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
| `cloneworldProvider.RefreshAllData` | [L174](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L174) |
| `FluxBattlefieldMapWorldFeatures:IsEnabled` | [L317](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L317) |
| `FluxBattlefieldMapWorldFeatures:SetEnabled` | [L342](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L342) |
| `FluxBattlefieldMapWorldFeatures:RefreshBattlefieldMapPublic` | [L530](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L530) |
| `FluxBattlefieldMapWorldFeatures:RefreshShadowClones` | [L534](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L534) |
| `FluxBattlefieldMapWorldFeatures:ClearShadowClonesOnBattlefield` | [L548](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L548) |
| `FluxBattlefieldMapWorldFeatures:StripCombatUnsafeProviders` | [L694](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L694) |
| `mapFrame.AddDataProvidermapFrame.AddDataProvider` | [L754](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L754) |
| `FluxBattlefieldMapWorldFeatures:RefreshToggleLayout` | [L916](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L916) |
| `FluxBattlefieldMapWorldFeatures:Activate` | [L1023](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1023) |
| `FluxBattlefieldMapWorldFeatures:Deactivate` | [L1051](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1051) |
| `FluxBattlefieldMapWorldFeatures:OnMapShown` | [L1079](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1079) |
| `FluxBattlefieldMapWorldFeatures:OnMapHidden` | [L1094](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1094) |
| `FluxBattlefieldMapWorldFeatures:SyncIfMapActive` | [L1104](../../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua#L1104) |

### Battlezonemap/FluxBattlefieldWorldMap.lua

Owner: [10-flux-window.md](../10-flux-window.md).

| Declaration | Source |
|---|---|
| `Surface:Activate` | [L722](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L722) |
| `Surface:Deactivate` | [L735](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L735) |
| `Surface:Sync` | [L742](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L742) |
| `Surface:IsEmbedded` | [L743](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L743) |
| `Surface:OwnsLayout` | [L744](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L744) |
| `Surface:IsActive` | [L749](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L749) |
| `Surface:IsRequested` | [L750](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L750) |
| `Surface:GetDiagnostics` | [L751](../../Battlezonemap/FluxBattlefieldWorldMap.lua#L751) |

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
| `Threat:OnDetailsEvent` | [L140](../../Battlezonemap/FluxThreat.lua#L140) |
| `Threat:UpdateContainers` | [L226](../../Battlezonemap/FluxThreat.lua#L226) |
| `Threat:UpdateRowWidths` | [L232](../../Battlezonemap/FluxThreat.lua#L232) |
| `Threat:HideBars` | [L238](../../Battlezonemap/FluxThreat.lua#L238) |
| `Threat:SizeChanged` | [L426](../../Battlezonemap/FluxThreat.lua#L426) |
| `Threat:RefreshRow` | [L454](../../Battlezonemap/FluxThreat.lua#L454) |
| `Threat:RefreshRows` | [L475](../../Battlezonemap/FluxThreat.lua#L475) |
| `Threat:NewRow` | [L481](../../Battlezonemap/FluxThreat.lua#L481) |
| `Threat:TargetChanged` | [L808](../../Battlezonemap/FluxThreat.lua#L808) |
| `Threat:Start` | [L815](../../Battlezonemap/FluxThreat.lua#L815) |
| `Threat:Stop` | [L822](../../Battlezonemap/FluxThreat.lua#L822) |
| `Threat:Cancel` | [L827](../../Battlezonemap/FluxThreat.lua#L827) |
| `Threat:OnThreatListOrRosterEvent` | [L846](../../Battlezonemap/FluxThreat.lua#L846) |
| `Threat:SyncThreatPollingScript` | [L918](../../Battlezonemap/FluxThreat.lua#L918) |
| `Threat:SetCombatListEvents` | [L925](../../Battlezonemap/FluxThreat.lua#L925) |
| `Threat:OnEvent` | [L941](../../Battlezonemap/FluxThreat.lua#L941) |

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
| `_G.FluxActionBarPeekSlotOccupancyChanged` | [L1073](../../Binding/Core/Apply.lua#L1073) |
| `_G.FluxActionBarPeekSlotOccupancyPrevious` | [L1093](../../Binding/Core/Apply.lua#L1093) |
| `_G.FluxActionBarConsumeOccupancyDirty` | [L1101](../../Binding/Core/Apply.lua#L1101) |
| `_G.FluxActionBarConsumeAllOccupancyDirty` | [L1110](../../Binding/Core/Apply.lua#L1110) |
| `_G.FluxActionBarSeedSlotOccupancyCache` | [L1118](../../Binding/Core/Apply.lua#L1118) |
| `_G.FluxActionBarPeekSlotOccupancy_ClearCache` | [L1129](../../Binding/Core/Apply.lua#L1129) |
| `FluxBinding.HasActiveWork` | [L2495](../../Binding/Core/Apply.lua#L2495) |
| `FluxBinding.GetActiveWorkInfo` | [L2508](../../Binding/Core/Apply.lua#L2508) |
| `FluxBinding.RequestApplyAll` | [L2526](../../Binding/Core/Apply.lua#L2526) |
| `FluxBinding.NotifyOccupancyChanged` | [L2547](../../Binding/Core/Apply.lua#L2547) |
| `FluxBinding.NotifyBarSlotChanged` | [L2596](../../Binding/Core/Apply.lua#L2596) |
| `FluxBinding.NotifyBarSlotsChanged` | [L2605](../../Binding/Core/Apply.lua#L2605) |
| `FluxBinding.NotifyBindingChanged` | [L2619](../../Binding/Core/Apply.lua#L2619) |
| `FluxBinding.NotifyBindingsAvailabilityChanged` | [L2636](../../Binding/Core/Apply.lua#L2636) |
| `FluxBinding.NormalizeChord` | [L2644](../../Binding/Core/Apply.lua#L2644) |
| `FluxBinding.GetWorldChordTarget` | [L2650](../../Binding/Core/Apply.lua#L2650) |
| `FluxBinding.FindColumnForChord` | [L2657](../../Binding/Core/Apply.lua#L2657) |
| `FluxBinding.RegisterApplied` | [L2661](../../Binding/Core/Apply.lua#L2661) |
| `FluxBinding.GetLastApplyStats` | [L2665](../../Binding/Core/Apply.lua#L2665) |
| `FluxBinding.CanUseMultiCastExtras` | [L2672](../../Binding/Core/Apply.lua#L2672) |
| `FluxBinding.GetPeersForChord` | [L2818](../../Binding/Core/Apply.lua#L2818) |
| `FluxBinding.GetEditorOverlap` | [L2868](../../Binding/Core/Apply.lua#L2868) |
| `FluxBinding.GetPreviewForBinding` | [L2939](../../Binding/Core/Apply.lua#L2939) |
| `FluxBinding.Debug` | [L3050](../../Binding/Core/Apply.lua#L3050) |

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
| `PushPress.EnsureBarButtonPushHooks` | [L590](../../Binding/Core/PushPress.lua#L590) |
| `PushPress.HookKeyer` | [L603](../../Binding/Core/PushPress.lua#L603) |
| `PushPress.WakeUfHoverFromUnitFrame` | [L788](../../Binding/Core/PushPress.lua#L788) |
| `PushPress.ParkUfHoverFromUnitFrame` | [L794](../../Binding/Core/PushPress.lua#L794) |
| `PushPress.WipeUfHover` | [L801](../../Binding/Core/PushPress.lua#L801) |
| `PushPress.RegisterUfHover` | [L807](../../Binding/Core/PushPress.lua#L807) |
| `PushPress.BindButton` | [L843](../../Binding/Core/PushPress.lua#L843) |
| `PushPress.OnApplyComplete` | [L862](../../Binding/Core/PushPress.lua#L862) |

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
| `FluxMouseoverKeybind:HasHoverRoutingActive` | [L2030](../../Binding/Input/FluxMouseoverKeybind.lua#L2030) |
| `FluxMouseoverKeybind:IsHovercastPeekMouseContext` | [L2034](../../Binding/Input/FluxMouseoverKeybind.lua#L2034) |
| `FluxMouseoverKeybind:RegisterFrame` | [L2048](../../Binding/Input/FluxMouseoverKeybind.lua#L2048) |
| `FluxMouseoverKeybind:IsFrameRegistered` | [L2052](../../Binding/Input/FluxMouseoverKeybind.lua#L2052) |
| `FluxMouseoverKeybind:SyncNativePlayerSuppression` | [L2056](../../Binding/Input/FluxMouseoverKeybind.lua#L2056) |
| `FluxMouseoverKeybind:UnregisterBlizzardCompactRaidFrames` | [L2062](../../Binding/Input/FluxMouseoverKeybind.lua#L2062) |
| `FluxMouseoverKeybind:RefreshKeybinds` | [L2094](../../Binding/Input/FluxMouseoverKeybind.lua#L2094) |
| `FluxMouseoverKeybind:ReapplyAllRegisteredFrames` | [L2101](../../Binding/Input/FluxMouseoverKeybind.lua#L2101) |
| `FluxMouseoverKeybind:SetUfHoverRouting` | [L2110](../../Binding/Input/FluxMouseoverKeybind.lua#L2110) |
| `FluxMouseoverKeybind:SetSpellHoverKeys` | [L2139](../../Binding/Input/FluxMouseoverKeybind.lua#L2139) |
| `FluxMouseoverKeybind:FlushPendingHoverRouting` | [L2173](../../Binding/Input/FluxMouseoverKeybind.lua#L2173) |
| `FluxMouseoverKeybind:HasPendingHoverRouting` | [L2188](../../Binding/Input/FluxMouseoverKeybind.lua#L2188) |
| `FluxMouseoverKeybind:DebugRouting` | [L2192](../../Binding/Input/FluxMouseoverKeybind.lua#L2192) |
| `end_G.FluxMouseoverKeybind_DebugRouting` | [L2232](../../Binding/Input/FluxMouseoverKeybind.lua#L2232) |
| `FluxMouseoverKeybind_G.FluxRaidRegisterAllMouseoverKeybindFrames` | [L2239](../../Binding/Input/FluxMouseoverKeybind.lua#L2239) |
| `headerClique.UpdateRegisteredClicks` | [L2270](../../Binding/Input/FluxMouseoverKeybind.lua#L2270) |

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
| `Blizz.SetMouseSuppressed` | [L228](../../Blizzard/Hide.lua#L228) |
| `Blizz.IsMouseSuppressed` | [L271](../../Blizzard/Hide.lua#L271) |
| `Blizz.Hide` | [L279](../../Blizzard/Hide.lua#L279) |
| `Blizz.Unhide` | [L312](../../Blizzard/Hide.lua#L312) |
| `Blizz.IsHidden` | [L321](../../Blizzard/Hide.lua#L321) |

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
| `Item.GetCount` | [L63](../../Core/API/Item.lua#L63) |
| `Item.IsUsable` | [L89](../../Core/API/Item.lua#L89) |
| `Item.IsEquipped` | [L133](../../Core/API/Item.lua#L133) |
| `Item.UsesConsumableCharges` | [L169](../../Core/API/Item.lua#L169) |
| `Item.IsConsumable` | [L200](../../Core/API/Item.lua#L200) |
| `Item.IsCurrent` | [L239](../../Core/API/Item.lua#L239) |
| `Item.CanCheckRange` | [L262](../../Core/API/Item.lua#L262) |
| `Item.IsInRange` | [L274](../../Core/API/Item.lua#L274) |
| `Item.GetSpell` | [L310](../../Core/API/Item.lua#L310) |
| `Item.GetQuality` | [L342](../../Core/API/Item.lua#L342) |
| `Item.DoesExist` | [L350](../../Core/API/Item.lua#L350) |
| `Item.GetCooldown` | [L361](../../Core/API/Item.lua#L361) |

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
| `Threat.GetPlayerRank` | [L1004](../../Core/API/Threat.lua#L1004) |
| `Threat.GetPlayerRankForNameplateBatch` | [L1009](../../Core/API/Threat.lua#L1009) |
| `Threat.GetMeterRow` | [L1046](../../Core/API/Threat.lua#L1046) |

### Core/BorderJunctions.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `J._FieldLists` | [L44](../../Core/BorderJunctions.lua#L44) |
| `J._ColorLists` | [L49](../../Core/BorderJunctions.lua#L49) |
| `FieldPaint.Texture` | [L151](../../Core/BorderJunctions.lua#L151) |
| `FieldPaint.Layer` | [L163](../../Core/BorderJunctions.lua#L163) |
| `FieldPaint.Color` | [L175](../../Core/BorderJunctions.lua#L175) |
| `J._FieldGeometry.Box` | [L198](../../Core/BorderJunctions.lua#L198) |
| `J._FieldGeometry.Follow` | [L236](../../Core/BorderJunctions.lua#L236) |
| `J._FieldGeometry.Vertices` | [L267](../../Core/BorderJunctions.lua#L267) |
| `J._FieldGeometry.Color` | [L339](../../Core/BorderJunctions.lua#L339) |
| `J:Solve` | [L372](../../Core/BorderJunctions.lua#L372) |
| `J:ReleaseAll` | [L717](../../Core/BorderJunctions.lua#L717) |
| `J:ReleaseFor` | [L748](../../Core/BorderJunctions.lua#L748) |
| `J._PublicAncestorGetters` | [L1091](../../Core/BorderJunctions.lua#L1091) |
| `J._RefreshObserverLinks` | [L1607](../../Core/BorderJunctions.lua#L1607) |
| `J:PaintChanged` | [L1618](../../Core/BorderJunctions.lua#L1618) |
| `J:Adopt` | [L1713](../../Core/BorderJunctions.lua#L1713) |
| `J:Forget` | [L1840](../../Core/BorderJunctions.lua#L1840) |
| `J:SetOverlay` | [L1852](../../Core/BorderJunctions.lua#L1852) |
| `J:Recolor` | [L1873](../../Core/BorderJunctions.lua#L1873) |
| `J:Subtract` | [L2113](../../Core/BorderJunctions.lua#L2113) |
| `J._ReadPreparedSource` | [L2253](../../Core/BorderJunctions.lua#L2253) |
| `J:AlignNearbyPanels` | [L2358](../../Core/BorderJunctions.lua#L2358) |
| `J:Triangles` | [L2672](../../Core/BorderJunctions.lua#L2672) |
| `J:_ClearBranchCompileCache` | [L2903](../../Core/BorderJunctions.lua#L2903) |
| `J:_PublishBranchCompileCache` | [L2906](../../Core/BorderJunctions.lua#L2906) |
| `J:BranchTriangles` | [L3003](../../Core/BorderJunctions.lua#L3003) |
| `prepared.inputsendreturnresultendBranches` | [L3283](../../Core/BorderJunctions.lua#L3283) |
| `J:_PrepareUnitBranchFallbacks` | [L3672](../../Core/BorderJunctions.lua#L3672) |
| `J:_UnitFallbackProfileMatches` | [L3774](../../Core/BorderJunctions.lua#L3774) |
| `J:_TrimUnitBranchFallbackRects` | [L3803](../../Core/BorderJunctions.lua#L3803) |
| `J:_BeginFallbackCompileGeneration` | [L3841](../../Core/BorderJunctions.lua#L3841) |
| `J:_ClearFallbackCompileCache` | [L3845](../../Core/BorderJunctions.lua#L3845) |
| `J:_PublishFallbackCompileCache` | [L3848](../../Core/BorderJunctions.lua#L3848) |
| `J._FallbackDisjoint` | [L3955](../../Core/BorderJunctions.lua#L3955) |
| `J:_ClearFallbackPlanCache` | [L4059](../../Core/BorderJunctions.lua#L4059) |
| `J:_ClearAlternatePlans` | [L4062](../../Core/BorderJunctions.lua#L4062) |
| `J:_PublishFallbackPlanCache` | [L4065](../../Core/BorderJunctions.lua#L4065) |
| `J:_CompileFallbackPlans` | [L4156](../../Core/BorderJunctions.lua#L4156) |
| `J:_PreparePlan` | [L4415](../../Core/BorderJunctions.lua#L4415) |
| `Spatial.Copy` | [L4621](../../Core/BorderJunctions.lua#L4621) |
| `Spatial.Eligible` | [L4673](../../Core/BorderJunctions.lua#L4673) |
| `Spatial.IsScoped` | [L4700](../../Core/BorderJunctions.lua#L4700) |
| `Spatial.MarkGroup` | [L4703](../../Core/BorderJunctions.lua#L4703) |
| `Spatial.ScopeBounds` | [L4716](../../Core/BorderJunctions.lua#L4716) |
| `Spatial.RectCells` | [L4742](../../Core/BorderJunctions.lua#L4742) |
| `Spatial.Owners` | [L4753](../../Core/BorderJunctions.lua#L4753) |
| `Spatial.Changed` | [L4758](../../Core/BorderJunctions.lua#L4758) |
| `Spatial.Intersection` | [L4788](../../Core/BorderJunctions.lua#L4788) |
| `Spatial.ClipTriangle` | [L4800](../../Core/BorderJunctions.lua#L4800) |
| `Spatial.TileSource` | [L4868](../../Core/BorderJunctions.lua#L4868) |
| `Spatial.CopyDrawOperation` | [L4878](../../Core/BorderJunctions.lua#L4878) |
| `Spatial.PrepareCell` | [L4891](../../Core/BorderJunctions.lua#L4891) |
| `Spatial.IndexRegions` | [L4949](../../Core/BorderJunctions.lua#L4949) |
| `Spatial.VisitTiles` | [L4971](../../Core/BorderJunctions.lua#L4971) |
| `Spatial.TouchesHalo` | [L5005](../../Core/BorderJunctions.lua#L5005) |
| `Spatial.Query` | [L5010](../../Core/BorderJunctions.lua#L5010) |
| `Spatial.TouchesRegion` | [L5047](../../Core/BorderJunctions.lua#L5047) |
| `Spatial.Affects` | [L5050](../../Core/BorderJunctions.lua#L5050) |
| `Spatial.AddToRegion` | [L5055](../../Core/BorderJunctions.lua#L5055) |
| `Spatial.RouteRegions` | [L5060](../../Core/BorderJunctions.lua#L5060) |
| `Spatial.Hide` | [L5077](../../Core/BorderJunctions.lua#L5077) |
| `Spatial.Pop` | [L5088](../../Core/BorderJunctions.lua#L5088) |
| `Spatial.Push` | [L5096](../../Core/BorderJunctions.lua#L5096) |
| `J._RemoveRegionalFragment` | [L5099](../../Core/BorderJunctions.lua#L5099) |
| `Spatial.DetachListener` | [L5102](../../Core/BorderJunctions.lua#L5102) |
| `Spatial.Detach` | [L5116](../../Core/BorderJunctions.lua#L5116) |
| `Spatial.PruneListenerIndices` | [L5135](../../Core/BorderJunctions.lua#L5135) |
| `Spatial.Attach` | [L5143](../../Core/BorderJunctions.lua#L5143) |
| `Spatial.Reset` | [L5192](../../Core/BorderJunctions.lua#L5192) |
| `J:_ForgetLocality` | [L5202](../../Core/BorderJunctions.lua#L5202) |
| `Spatial.Acquire` | [L5216](../../Core/BorderJunctions.lua#L5216) |
| `Spatial.Tick` | [L5231](../../Core/BorderJunctions.lua#L5231) |
| `Spatial.Levels` | [L5242](../../Core/BorderJunctions.lua#L5242) |
| `Spatial.ApplyLevels` | [L5290](../../Core/BorderJunctions.lua#L5290) |
| `Spatial.Budget` | [L5300](../../Core/BorderJunctions.lua#L5300) |
| `Spatial.Commit` | [L5330](../../Core/BorderJunctions.lua#L5330) |
| `Spatial.MatchLayoutPose` | [L5490](../../Core/BorderJunctions.lua#L5490) |
| `Spatial.CopyPoseOperations` | [L5519](../../Core/BorderJunctions.lua#L5519) |
| `Spatial.SaveLayoutPose` | [L5529](../../Core/BorderJunctions.lua#L5529) |
| `Spatial.PruneLayoutPoses` | [L5569](../../Core/BorderJunctions.lua#L5569) |
| `Spatial.FindLayoutPose` | [L5579](../../Core/BorderJunctions.lua#L5579) |
| `Spatial.RememberLayoutPose` | [L5587](../../Core/BorderJunctions.lua#L5587) |
| `Spatial.SaveLayoutPlan` | [L5632](../../Core/BorderJunctions.lua#L5632) |
| `Spatial.RestoreLayoutPlan` | [L5679](../../Core/BorderJunctions.lua#L5679) |
| `Spatial.Try` | [L5728](../../Core/BorderJunctions.lua#L5728) |
| `J:_LocalSegment` | [L5833](../../Core/BorderJunctions.lua#L5833) |
| `Spatial.ReadFilter` | [L5848](../../Core/BorderJunctions.lua#L5848) |
| `J:Flush` | [L5855](../../Core/BorderJunctions.lua#L5855) |
| `J:CommitLayout` | [L6086](../../Core/BorderJunctions.lua#L6086) |
| `J:Invalidate` | [L6090](../../Core/BorderJunctions.lua#L6090) |
| `endendSlashCmdList.FLUXBORDERS` | [L6307](../../Core/BorderJunctions.lua#L6307) |

### Core/ButtonFX/Cast.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Cast.IsSpellCastVFXEnabled` | [L34](../../Core/ButtonFX/Cast.lua#L34) |
| `ButtonFX.BeginSlotPass` | [L244](../../Core/ButtonFX/Cast.lua#L244) |
| `ButtonFX.EndSlotPass` | [L252](../../Core/ButtonFX/Cast.lua#L252) |
| `ButtonFX.WithSlotPassCleanup` | [L266](../../Core/ButtonFX/Cast.lua#L266) |
| `ButtonFX.SpellIdFromAction` | [L399](../../Core/ButtonFX/Cast.lua#L399) |
| `ButtonFX.SpellIdFromEBS` | [L419](../../Core/ButtonFX/Cast.lua#L419) |
| `ButtonFX.SpellIdsMatch` | [L723](../../Core/ButtonFX/Cast.lua#L723) |
| `Cast.PickAllMatching` | [L791](../../Core/ButtonFX/Cast.lua#L791) |
| `Cast.PickOwners` | [L809](../../Core/ButtonFX/Cast.lua#L809) |
| `Cast.PickOwner` | [L836](../../Core/ButtonFX/Cast.lua#L836) |
| `Cast.PickOwnerByName` | [L841](../../Core/ButtonFX/Cast.lua#L841) |
| `Cast.FollowColumn` | [L1673](../../Core/ButtonFX/Cast.lua#L1673) |
| `Cast.FollowExtra` | [L1765](../../Core/ButtonFX/Cast.lua#L1765) |
| `Cast.NoteChannelTimes` | [L1867](../../Core/ButtonFX/Cast.lua#L1867) |
| `StopReticleWatch` | [L2265](../../Core/ButtonFX/Cast.lua#L2265) |
| `Cast.Start` | [L2516](../../Core/ButtonFX/Cast.lua#L2516) |
| `Cast.RefreshFromOptions` | [L2520](../../Core/ButtonFX/Cast.lua#L2520) |
| `Cast.SpellBlockedAsCurrent` | [L2536](../../Core/ButtonFX/Cast.lua#L2536) |
| `Cast.NoteTargeting` | [L2543](../../Core/ButtonFX/Cast.lua#L2543) |
| `Cast.Debug` | [L2590](../../Core/ButtonFX/Cast.lua#L2590) |
| `Cast.Register` | [L2607](../../Core/ButtonFX/Cast.lua#L2607) |
| `Cast.AdoptFace` | [L2635](../../Core/ButtonFX/Cast.lua#L2635) |

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
| `StopAttachedReticlewidget.ClearInterruptDisplay` | [L852](../../Core/ButtonFX/Overlay.lua#L852) |
| `endendwidget.StopSpellCastAnim` | [L864](../../Core/ButtonFX/Overlay.lua#L864) |
| `endwidget.PlaySpellInterruptedAnim` | [L868](../../Core/ButtonFX/Overlay.lua#L868) |
| `endwidget.PlayTargettingReticleAnim` | [L872](../../Core/ButtonFX/Overlay.lua#L872) |
| `endendwidget.PlaySpellCastAnim` | [L897](../../Core/ButtonFX/Overlay.lua#L897) |
| `Overlay.StopClassicFill` | [L1175](../../Core/ButtonFX/Overlay.lua#L1175) |
| `Overlay._classicOnUpdate` | [L1204](../../Core/ButtonFX/Overlay.lua#L1204) |
| `Overlay.PlayClassicFill` | [L1363](../../Core/ButtonFX/Overlay.lua#L1363) |
| `Overlay.PlayClassicFinish` | [L1383](../../Core/ButtonFX/Overlay.lua#L1383) |
| `Overlay.PlayClassicInterrupt` | [L1408](../../Core/ButtonFX/Overlay.lua#L1408) |
| `Overlay.HideCastFill` | [L1487](../../Core/ButtonFX/Overlay.lua#L1487) |
| `Overlay.PlayBurst` | [L1507](../../Core/ButtonFX/Overlay.lua#L1507) |
| `Overlay.PlayCast` | [L1560](../../Core/ButtonFX/Overlay.lua#L1560) |
| `Overlay.StopCast` | [L1621](../../Core/ButtonFX/Overlay.lua#L1621) |
| `Overlay.PlayInterrupt` | [L1720](../../Core/ButtonFX/Overlay.lua#L1720) |
| `Overlay.PlayReticle` | [L1759](../../Core/ButtonFX/Overlay.lua#L1759) |
| `Overlay.ClearReticle` | [L1798](../../Core/ButtonFX/Overlay.lua#L1798) |
| `Overlay.ForEachPressed` | [L1875](../../Core/ButtonFX/Overlay.lua#L1875) |
| `Overlay.NotePressed` | [L1884](../../Core/ButtonFX/Overlay.lua#L1884) |
| `Overlay.ReleasePress` | [L1895](../../Core/ButtonFX/Overlay.lua#L1895) |
| `Overlay.IsCheckedSuppressed` | [L1970](../../Core/ButtonFX/Overlay.lua#L1970) |
| `Overlay.EnsureCheckedTexture` | [L2014](../../Core/ButtonFX/Overlay.lua#L2014) |
| `Overlay.CheckedVisualOn` | [L2040](../../Core/ButtonFX/Overlay.lua#L2040) |
| `Overlay.ApplyChecked` | [L2068](../../Core/ButtonFX/Overlay.lua#L2068) |
| `Overlay.IsPushed` | [L2104](../../Core/ButtonFX/Overlay.lua#L2104) |
| `Overlay.FollowChrome` | [L2122](../../Core/ButtonFX/Overlay.lua#L2122) |
| `Overlay.ResetTargetChrome` | [L2154](../../Core/ButtonFX/Overlay.lua#L2154) |
| `Overlay.IsLiveBurst` | [L2351](../../Core/ButtonFX/Overlay.lua#L2351) |
| `Overlay.IsLiveCast` | [L2364](../../Core/ButtonFX/Overlay.lua#L2364) |
| `Overlay.IsLiveReticle` | [L2387](../../Core/ButtonFX/Overlay.lua#L2387) |
| `Overlay.IsLiveInterrupt` | [L2413](../../Core/ButtonFX/Overlay.lua#L2413) |
| `Overlay.ShouldHideCooldown` | [L2425](../../Core/ButtonFX/Overlay.lua#L2425) |
| `Overlay.ForceClear` | [L2430](../../Core/ButtonFX/Overlay.lua#L2430) |
| `Overlay.SyncCast` | [L2474](../../Core/ButtonFX/Overlay.lua#L2474) |
| `Overlay.SyncInterrupt` | [L2495](../../Core/ButtonFX/Overlay.lua#L2495) |
| `Overlay.SyncBurst` | [L2508](../../Core/ButtonFX/Overlay.lua#L2508) |
| `Overlay.TickFill` | [L2520](../../Core/ButtonFX/Overlay.lua#L2520) |
| `Overlay.TransferCast` | [L2534](../../Core/ButtonFX/Overlay.lua#L2534) |
| `Overlay.TransferReticle` | [L2599](../../Core/ButtonFX/Overlay.lua#L2599) |
| `Overlay.TransferInterrupt` | [L2624](../../Core/ButtonFX/Overlay.lua#L2624) |
| `Overlay.Transfer` | [L2664](../../Core/ButtonFX/Overlay.lua#L2664) |
| `endwidget.MatchesActiveButtonSpellID` | [L2717](../../Core/ButtonFX/Overlay.lua#L2717) |
| `Overlay.Attach` | [L2727](../../Core/ButtonFX/Overlay.lua#L2727) |

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
| `Combat.ObserveTiming` | [L27](../../Core/Engine/Combat.lua#L27) |
| `Combat.InLockdown` | [L50](../../Core/Engine/Combat.lua#L50) |
| `Combat.ScheduleRegenQueues` | [L99](../../Core/Engine/Combat.lua#L99) |
| `Combat.RegenDefer` | [L112](../../Core/Engine/Combat.lua#L112) |
| `endend_G.FluxCombatRegenDeferQueue` | [L128](../../Core/Engine/Combat.lua#L128) |
| `end_G.FluxRegenDeferHeavyQueue` | [L132](../../Core/Engine/Combat.lua#L132) |
| `Combat.Defer` | [L137](../../Core/Engine/Combat.lua#L137) |
| `Combat.Flush` | [L152](../../Core/Engine/Combat.lua#L152) |
| `Combat.HasPending` | [L203](../../Core/Engine/Combat.lua#L203) |
| `Combat.PendingCount` | [L207](../../Core/Engine/Combat.lua#L207) |

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
| `Events.GetCallbackOrigin` | [L94](../../Core/Engine/Events.lua#L94) |
| `Events.IsPlayerUnitEvent` | [L102](../../Core/Engine/Events.lua#L102) |
| `Events.ObserveTiming` | [L125](../../Core/Engine/Events.lua#L125) |
| `Events.SetTrace` | [L197](../../Core/Engine/Events.lua#L197) |
| `Events.Register` | [L201](../../Core/Engine/Events.lua#L201) |
| `Events.Unregister` | [L224](../../Core/Engine/Events.lua#L224) |
| `Events.RegisterUnit` | [L250](../../Core/Engine/Events.lua#L250) |
| `Events.SafeRegister` | [L279](../../Core/Engine/Events.lua#L279) |
| `Events.SafeRegisterUnit` | [L293](../../Core/Engine/Events.lua#L293) |
| `Events.RegisterLearnedSpell` | [L307](../../Core/Engine/Events.lua#L307) |

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
| `MouseoverCast.RangeUnit` | [L525](../../Core/Engine/MouseoverCast.lua#L525) |
| `MouseoverCast.SyncDrivers` | [L743](../../Core/Engine/MouseoverCast.lua#L743) |
| `MouseoverCast.RegisterHeader` | [L769](../../Core/Engine/MouseoverCast.lua#L769) |
| `MouseoverCast.AttachHost` | [L796](../../Core/Engine/MouseoverCast.lua#L796) |
| `MouseoverCast.RegisterButton` | [L830](../../Core/Engine/MouseoverCast.lua#L830) |
| `MouseoverCast.SetButtonSpell` | [L858](../../Core/Engine/MouseoverCast.lua#L858) |
| `MouseoverCast.SetButtonItem` | [L882](../../Core/Engine/MouseoverCast.lua#L882) |
| `MouseoverCast.ConfigureUtility` | [L896](../../Core/Engine/MouseoverCast.lua#L896) |
| `MouseoverCast.AttachUtilityKeyer` | [L917](../../Core/Engine/MouseoverCast.lua#L917) |
| `MouseoverCast.UtilityRangeUnit` | [L924](../../Core/Engine/MouseoverCast.lua#L924) |
| `MouseoverCast.Apply` | [L957](../../Core/Engine/MouseoverCast.lua#L957) |
| `MouseoverCast.RefreshSetting` | [L1008](../../Core/Engine/MouseoverCast.lua#L1008) |
| `MouseoverCast.SetEnabled` | [L1043](../../Core/Engine/MouseoverCast.lua#L1043) |
| `MouseoverCast.GetStats` | [L1054](../../Core/Engine/MouseoverCast.lua#L1054) |
| `MouseoverCast.DebugDump` | [L1065](../../Core/Engine/MouseoverCast.lua#L1065) |
| `MouseoverCast.GetSpellBookCheckbox` | [L1153](../../Core/Engine/MouseoverCast.lua#L1153) |
| `MouseoverCast.RefreshSpellBookCheckbox` | [L1160](../../Core/Engine/MouseoverCast.lua#L1160) |
| `PositionSpellBookCheckbox` | [L1212](../../Core/Engine/MouseoverCast.lua#L1212) |
| `MouseoverCast.Start` | [L1342](../../Core/Engine/MouseoverCast.lua#L1342) |

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
| `Range.ResolveUnit` | [L164](../../Core/Engine/Range.lua#L164) |
| `Range.CheckSpell` | [L246](../../Core/Engine/Range.lua#L246) |
| `Range.CheckItem` | [L258](../../Core/Engine/Range.lua#L258) |
| `Range.CheckAction` | [L275](../../Core/Engine/Range.lua#L275) |
| `Range.RegisterSweep` | [L293](../../Core/Engine/Range.lua#L293) |
| `Range.Sync` | [L376](../../Core/Engine/Range.lua#L376) |
| `Range.IsArmed` | [L394](../../Core/Engine/Range.lua#L394) |
| `Range.IsHopBurst` | [L400](../../Core/Engine/Range.lua#L400) |
| `Range.Invalidate` | [L411](../../Core/Engine/Range.lua#L411) |
| `Range.InvalidateSweep` | [L418](../../Core/Engine/Range.lua#L418) |
| `Range.UnitReactionClass` | [L431](../../Core/Engine/Range.lua#L431) |
| `Range.TargetReactionClass` | [L454](../../Core/Engine/Range.lua#L454) |
| `Range.Start` | [L480](../../Core/Engine/Range.lua#L480) |

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
| `Restricted.RegisterAttributeDriver` | [L392](../../Core/Engine/Restricted.lua#L392) |
| `Restricted.UnregisterAttributeDriver` | [L415](../../Core/Engine/Restricted.lua#L415) |
| `Restricted.RegisterStateDriver` | [L440](../../Core/Engine/Restricted.lua#L440) |
| `Restricted.UnregisterStateDriver` | [L444](../../Core/Engine/Restricted.lua#L444) |
| `Restricted.RegisterUnitWatch` | [L451](../../Core/Engine/Restricted.lua#L451) |
| `Restricted.UnregisterUnitWatch` | [L466](../../Core/Engine/Restricted.lua#L466) |
| `Restricted.UnitWatchRegistered` | [L481](../../Core/Engine/Restricted.lua#L481) |

### Core/Engine/Scheduler.lua

Owner: [08-shared-services.md](../08-shared-services.md).

| Declaration | Source |
|---|---|
| `Scheduler.GetCallbackOrigin` | [L41](../../Core/Engine/Scheduler.lua#L41) |
| `Scheduler.ObserveTiming` | [L99](../../Core/Engine/Scheduler.lua#L99) |
| `Scheduler.Register` | [L156](../../Core/Engine/Scheduler.lua#L156) |
| `Scheduler.BeginPaging` | [L165](../../Core/Engine/Scheduler.lua#L165) |
| `Scheduler.EndPaging` | [L169](../../Core/Engine/Scheduler.lua#L169) |
| `Scheduler.IsPaging` | [L173](../../Core/Engine/Scheduler.lua#L173) |
| `Scheduler.Request` | [L178](../../Core/Engine/Scheduler.lua#L178) |
| `Scheduler.HasPending` | [L209](../../Core/Engine/Scheduler.lua#L209) |
| `Scheduler.Flush` | [L301](../../Core/Engine/Scheduler.lua#L301) |
| `Scheduler.Stats` | [L351](../../Core/Engine/Scheduler.lua#L351) |

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
| `ns.API.GetNumSpellTabs` | [L121](../../Core/FluxAPI/Actions.lua#L121) |
| `ns.API.GetSpellTabInfo` | [L126](../../Core/FluxAPI/Actions.lua#L126) |
| `ns.API.GetSpellBookItemName` | [L131](../../Core/FluxAPI/Actions.lua#L131) |
| `ns.API.GetSpellBookItemInfo` | [L136](../../Core/FluxAPI/Actions.lua#L136) |
| `ns.API.GetSpellBookItemTexture` | [L141](../../Core/FluxAPI/Actions.lua#L141) |
| `ns.API.IsSpellKnown` | [L146](../../Core/FluxAPI/Actions.lua#L146) |
| `ns.API.GetFlyoutInfo` | [L151](../../Core/FluxAPI/Actions.lua#L151) |
| `ns.API.GetFlyoutSlotInfo` | [L156](../../Core/FluxAPI/Actions.lua#L156) |
| `ns.API.GetSpellDisplayTexture` | [L173](../../Core/FluxAPI/Actions.lua#L173) |
| `ns.API.GetItemInfo` | [L204](../../Core/FluxAPI/Actions.lua#L204) |
| `ns.API.GetAtlasInfo` | [L209](../../Core/FluxAPI/Actions.lua#L209) |
| `ns.API.HasAtlas` | [L217](../../Core/FluxAPI/Actions.lua#L217) |
| `ns.API.GetCurrentTime` | [L221](../../Core/FluxAPI/Actions.lua#L221) |
| `FluxHasAtlas` | [L228](../../Core/FluxAPI/Actions.lua#L228) |
| `FluxGetCurrentTime` | [L232](../../Core/FluxAPI/Actions.lua#L232) |
| `ns.API.GetActionTexture` | [L236](../../Core/FluxAPI/Actions.lua#L236) |
| `ns.API.IsUsableAction` | [L241](../../Core/FluxAPI/Actions.lua#L241) |
| `ns.API.IsConsumableAction` | [L246](../../Core/FluxAPI/Actions.lua#L246) |
| `ns.API.IsStackableAction` | [L251](../../Core/FluxAPI/Actions.lua#L251) |
| `ns.API.IsItemAction` | [L256](../../Core/FluxAPI/Actions.lua#L256) |
| `ns.API.IsEquippedAction` | [L261](../../Core/FluxAPI/Actions.lua#L261) |
| `ns.API.GetActionCharges` | [L266](../../Core/FluxAPI/Actions.lua#L266) |
| `ns.API.GetActionCount` | [L271](../../Core/FluxAPI/Actions.lua#L271) |
| `ns.API.GetActionCooldown` | [L276](../../Core/FluxAPI/Actions.lua#L276) |
| `ns.API.GetActionLossOfControlCooldown` | [L281](../../Core/FluxAPI/Actions.lua#L281) |
| `ns.API.IsActionInRange` | [L286](../../Core/FluxAPI/Actions.lua#L286) |
| `ns.API.NormalizeRangeResult` | [L293](../../Core/FluxAPI/Actions.lua#L293) |
| `ns.API.IsSpellUsable` | [L299](../../Core/FluxAPI/Actions.lua#L299) |
| `FluxGetSpellUsable` | [L354](../../Core/FluxAPI/Actions.lua#L354) |
| `ns.API.IsSpellInRange` | [L378](../../Core/FluxAPI/Actions.lua#L378) |
| `ns.API.CanCheckItemInRange` | [L398](../../Core/FluxAPI/Actions.lua#L398) |
| `ns.API.IsItemInRange` | [L406](../../Core/FluxAPI/Actions.lua#L406) |
| `ns.API.UnitExistsSafe` | [L420](../../Core/FluxAPI/Actions.lua#L420) |
| `ns.API.UnitInRangeSafe` | [L426](../../Core/FluxAPI/Actions.lua#L426) |
| `ns.API.IsAttackAction` | [L446](../../Core/FluxAPI/Actions.lua#L446) |
| `ns.API.IsAutoRepeatAction` | [L451](../../Core/FluxAPI/Actions.lua#L451) |
| `ns.API.IsCurrentAction` | [L456](../../Core/FluxAPI/Actions.lua#L456) |
| `ns.API.HasAction` | [L461](../../Core/FluxAPI/Actions.lua#L461) |
| `ns.API.GetNumShapeshiftForms` | [L466](../../Core/FluxAPI/Actions.lua#L466) |
| `ns.API.GetShapeshiftFormInfo` | [L471](../../Core/FluxAPI/Actions.lua#L471) |
| `ns.API.GetShapeshiftFormCooldown` | [L476](../../Core/FluxAPI/Actions.lua#L476) |
| `ns.API.HasValidStanceTexture` | [L481](../../Core/FluxAPI/Actions.lua#L481) |
| `ns.API.HasValidStances` | [L491](../../Core/FluxAPI/Actions.lua#L491) |
| `ns.API.ShouldUseLegacyComboFrameUI` | [L500](../../Core/FluxAPI/Actions.lua#L500) |
| `ns.API.GetClassPowerInfo` | [L514](../../Core/FluxAPI/Actions.lua#L514) |
| `ns.API.IsUnitPvP` | [L538](../../Core/FluxAPI/Actions.lua#L538) |
| `ns.API.GetUnitFactionGroup` | [L543](../../Core/FluxAPI/Actions.lua#L543) |
| `ns.API.IsWarModeActive` | [L548](../../Core/FluxAPI/Actions.lua#L548) |
| `ns.API.GetWarModeAsset` | [L553](../../Core/FluxAPI/Actions.lua#L553) |
| `ns.API.IsUnitInWarMode` | [L558](../../Core/FluxAPI/Actions.lua#L558) |

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
| `FluxUI_UsesAlternativeBagUI` | [L908](../../Core/FluxAPI/UI.lua#L908) |
| `FluxRegisterSettingsCategory` | [L921](../../Core/FluxAPI/UI.lua#L921) |
| `thenifSettingsandSettings.RegisterCanvasLayoutCategoryandSettings.RegisterAddOnCategorythenInterfaceOptions_AddCategory` | [L945](../../Core/FluxAPI/UI.lua#L945) |
| `FluxAPICompat.GetPlayerHasMana` | [L969](../../Core/FluxAPI/UI.lua#L969) |
| `FluxAPICompat.ResetManaCache` | [L977](../../Core/FluxAPI/UI.lua#L977) |
| `FluxAPICompat.CancelBankOpenWork` | [L1010](../../Core/FluxAPI/UI.lua#L1010) |
| `FluxCancelBankOpenWork` | [L1015](../../Core/FluxAPI/UI.lua#L1015) |
| `FluxAPICompat.DeferBankOpenWork` | [L1017](../../Core/FluxAPI/UI.lua#L1017) |
| `FluxDeferBankOpenWork` | [L1032](../../Core/FluxAPI/UI.lua#L1032) |
| `FluxAPICompat.IsUnifiedBankPaintReady` | [L1034](../../Core/FluxAPI/UI.lua#L1034) |
| `FluxIsUnifiedBankPaintReady` | [L1038](../../Core/FluxAPI/UI.lua#L1038) |
| `FluxAPICompat.DeferBankTransferWork` | [L1047](../../Core/FluxAPI/UI.lua#L1047) |
| `FluxDeferBankTransferWork` | [L1057](../../Core/FluxAPI/UI.lua#L1057) |
| `ns.API.GetNumPlayerTalentGroups` | [L1064](../../Core/FluxAPI/UI.lua#L1064) |
| `ns.API.GetActivePlayerTalentGroup` | [L1076](../../Core/FluxAPI/UI.lua#L1076) |
| `ns.API.SetActivePlayerTalentGroup` | [L1088](../../Core/FluxAPI/UI.lua#L1088) |
| `ns.API.TogglePlayerDualTalentGroup` | [L1098](../../Core/FluxAPI/UI.lua#L1098) |
| `ns.API.GetPlayerSpecFlyoutEntries` | [L1107](../../Core/FluxAPI/UI.lua#L1107) |
| `ns.API.GetPlayerSpecFlyoutEntriesIncludingActive` | [L1129](../../Core/FluxAPI/UI.lua#L1129) |
| `ns.API.TrySetPlayerSpecialization` | [L1144](../../Core/FluxAPI/UI.lua#L1144) |
| `ns.API.CanPlayerUseTalentSpecUI` | [L1153](../../Core/FluxAPI/UI.lua#L1153) |
| `ns.API.GetPlayerSpecSwitchMode` | [L1161](../../Core/FluxAPI/UI.lua#L1161) |
| `ns.API.HasPlayerTransmogOutfitAPI` | [L1170](../../Core/FluxAPI/UI.lua#L1170) |
| `ns.API.GetPlayerTransmogOutfitEntries` | [L1181](../../Core/FluxAPI/UI.lua#L1181) |
| `ns.API.GetPlayerTransmogOutfitAction` | [L1232](../../Core/FluxAPI/UI.lua#L1232) |
| `ns.API.IsPlayerTransmogOutfitActive` | [L1257](../../Core/FluxAPI/UI.lua#L1257) |
| `ns.API.GetPlayerTransmogOutfitIDForSpell` | [L1268](../../Core/FluxAPI/UI.lua#L1268) |
| `ns.API.TryApplyPlayerTransmogOutfit` | [L1277](../../Core/FluxAPI/UI.lua#L1277) |
| `ns.API.TryPickupPlayerTransmogOutfit` | [L1285](../../Core/FluxAPI/UI.lua#L1285) |
| `FluxIsDetailsActorLocalPlayer` | [L1308](../../Core/FluxAPI/UI.lua#L1308) |
| `FluxIsDetailsMeterSourceLocalPlayer` | [L1330](../../Core/FluxAPI/UI.lua#L1330) |

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
| `Hotkey.Path` | [L39](../../Core/Hotkey.lua#L39) |
| `Hotkey.Markup` | [L46](../../Core/Hotkey.lua#L46) |
| `Hotkey.IsOutOfRange` | [L74](../../Core/Hotkey.lua#L74) |
| `Hotkey.SetText` | [L78](../../Core/Hotkey.lua#L78) |
| `Hotkey.SetRange` | [L92](../../Core/Hotkey.lua#L92) |
| `Hotkey.IconFor` | [L112](../../Core/Hotkey.lua#L112) |
| `Hotkey.LivePrefix` | [L117](../../Core/Hotkey.lua#L117) |
| `Hotkey.Format` | [L128](../../Core/Hotkey.lua#L128) |

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
| `Grid.New` | [L37](../../ExtraButtonSystem/CombatGrid/Grid.lua#L37) |
| `grid:CreateButton` | [L88](../../ExtraButtonSystem/CombatGrid/Grid.lua#L88) |
| `btn:SetPlaceholder` | [L154](../../ExtraButtonSystem/CombatGrid/Grid.lua#L154) |
| `btn:ClearPlaceholder` | [L180](../../ExtraButtonSystem/CombatGrid/Grid.lua#L180) |
| `btn:SetLocked` | [L195](../../ExtraButtonSystem/CombatGrid/Grid.lua#L195) |
| `btn:SetCount` | [L207](../../ExtraButtonSystem/CombatGrid/Grid.lua#L207) |
| `btn:ShowTooltip` | [L230](../../ExtraButtonSystem/CombatGrid/Grid.lua#L230) |
| `btn:OnEnter` | [L237](../../ExtraButtonSystem/CombatGrid/Grid.lua#L237) |
| `btn:OnLeave` | [L246](../../ExtraButtonSystem/CombatGrid/Grid.lua#L246) |
| `btn:FullRefresh` | [L254](../../ExtraButtonSystem/CombatGrid/Grid.lua#L254) |
| `btn:Show` | [L268](../../ExtraButtonSystem/CombatGrid/Grid.lua#L268) |
| `btn:Hide` | [L272](../../ExtraButtonSystem/CombatGrid/Grid.lua#L272) |
| `grid:ComputeDynamicPriorities` | [L340](../../ExtraButtonSystem/CombatGrid/Grid.lua#L340) |
| `grid:ConsolidateColumns` | [L424](../../ExtraButtonSystem/CombatGrid/Grid.lua#L424) |
| `grid:BeginLayout` | [L551](../../ExtraButtonSystem/CombatGrid/Grid.lua#L551) |
| `grid:EndLayout` | [L555](../../ExtraButtonSystem/CombatGrid/Grid.lua#L555) |
| `grid:ScheduleRelayout` | [L563](../../ExtraButtonSystem/CombatGrid/Grid.lua#L563) |
| `grid:Relayout` | [L625](../../ExtraButtonSystem/CombatGrid/Grid.lua#L625) |
| `grid:Relayout` | [L802](../../ExtraButtonSystem/CombatGrid/Grid.lua#L802) |
| `grid:RefreshAllModules` | [L811](../../ExtraButtonSystem/CombatGrid/Grid.lua#L811) |
| `grid:Show` | [L829](../../ExtraButtonSystem/CombatGrid/Grid.lua#L829) |
| `grid:Hide` | [L830](../../ExtraButtonSystem/CombatGrid/Grid.lua#L830) |
| `FluxCombatGrid_ApplyAppearanceAccent` | [L836](../../ExtraButtonSystem/CombatGrid/Grid.lua#L836) |
| `Grid.RefreshAfterVisibilityChange` | [L862](../../ExtraButtonSystem/CombatGrid/Grid.lua#L862) |

### ExtraButtonSystem/CombatGrid/GridManager.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Manager:UpdateAnchor` | [L70](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L70) |
| `Manager:FinalizeLayout` | [L97](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L97) |
| `Manager:InitializeButtons` | [L123](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L123) |
| `Manager:RegisterCombatRefresh` | [L175](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L175) |
| `Manager:UnregisterCombatRefresh` | [L185](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L185) |
| `Manager:_RunCombatRefreshers` | [L191](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L191) |
| `Manager:_StartCombatRefreshTicker` | [L199](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L199) |
| `Manager:_StopCombatRefreshTicker` | [L215](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L215) |
| `Manager:ScheduleAllUpdates` | [L226](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L226) |
| `Manager:GetDebugStats` | [L296](../../ExtraButtonSystem/CombatGrid/GridManager.lua#L296) |

### ExtraButtonSystem/Engine/Action.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Action.ResolveProfessionSpell` | [L393](../../ExtraButtonSystem/Engine/Action.lua#L393) |
| `Action.InvalidateProfessionSpells` | [L399](../../ExtraButtonSystem/Engine/Action.lua#L399) |
| `Action.IsProfessionSpellData` | [L403](../../ExtraButtonSystem/Engine/Action.lua#L403) |
| `Action.GetMountInfo` | [L529](../../ExtraButtonSystem/Engine/Action.lua#L529) |
| `Action.SupportsAssistant` | [L563](../../ExtraButtonSystem/Engine/Action.lua#L563) |
| `Action.GetAssistantActionSpell` | [L571](../../ExtraButtonSystem/Engine/Action.lua#L571) |
| `Action.GetAssistantNextSpell` | [L589](../../ExtraButtonSystem/Engine/Action.lua#L589) |
| `Action.IsAssistantSpell` | [L610](../../ExtraButtonSystem/Engine/Action.lua#L610) |
| `Action.GetAssistantButton` | [L640](../../ExtraButtonSystem/Engine/Action.lua#L640) |
| `Action.LayoutAssistant` | [L710](../../ExtraButtonSystem/Engine/Action.lua#L710) |
| `Action.UpdateAssistantChrome` | [L714](../../ExtraButtonSystem/Engine/Action.lua#L714) |
| `existing.OnUpdate` | [L747](../../ExtraButtonSystem/Engine/Action.lua#L747) |
| `frame.OnUpdate` | [L762](../../ExtraButtonSystem/Engine/Action.lua#L762) |
| `Action.AttachAssistant` | [L801](../../ExtraButtonSystem/Engine/Action.lua#L801) |
| `Action.ClearAssistant` | [L824](../../ExtraButtonSystem/Engine/Action.lua#L824) |
| `Action.SyncAssistant` | [L844](../../ExtraButtonSystem/Engine/Action.lua#L844) |
| `Action.RefreshAssistantIdentity` | [L868](../../ExtraButtonSystem/Engine/Action.lua#L868) |
| `Action.RefreshAssistantChrome` | [L886](../../ExtraButtonSystem/Engine/Action.lua#L886) |
| `Action.PaintAssistantButtons` | [L900](../../ExtraButtonSystem/Engine/Action.lua#L900) |
| `Action.RebindAssistant` | [L917](../../ExtraButtonSystem/Engine/Action.lua#L917) |
| `Action.ClearEnv` | [L954](../../ExtraButtonSystem/Engine/Action.lua#L954) |
| `Action.InvalidateMacroParseCache` | [L1574](../../ExtraButtonSystem/Engine/Action.lua#L1574) |
| `Action.ShownFromBody` | [L1750](../../ExtraButtonSystem/Engine/Action.lua#L1750) |
| `Action.CastFromBody` | [L1762](../../ExtraButtonSystem/Engine/Action.lua#L1762) |
| `Action.CastForRange` | [L1812](../../ExtraButtonSystem/Engine/Action.lua#L1812) |
| `Action.TranslateMacro` | [L1963](../../ExtraButtonSystem/Engine/Action.lua#L1963) |
| `Action.TranslateMatching` | [L2122](../../ExtraButtonSystem/Engine/Action.lua#L2122) |
| `Action.RefreshMacroDisplay` | [L2147](../../ExtraButtonSystem/Engine/Action.lua#L2147) |
| `Action.SyncMacroProbes` | [L2319](../../ExtraButtonSystem/Engine/Action.lua#L2319) |
| `Action.RequestMacroDisplay` | [L2354](../../ExtraButtonSystem/Engine/Action.lua#L2354) |
| `Action.RefreshMacroBindings` | [L2431](../../ExtraButtonSystem/Engine/Action.lua#L2431) |
| `Action.OnMacrosUpdated` | [L2493](../../ExtraButtonSystem/Engine/Action.lua#L2493) |
| `Action.EnableMacroPrune` | [L2502](../../ExtraButtonSystem/Engine/Action.lua#L2502) |
| `Action.ForceMacrosLoaded` | [L2509](../../ExtraButtonSystem/Engine/Action.lua#L2509) |
| `Action.RefreshOutfits` | [L2538](../../ExtraButtonSystem/Engine/Action.lua#L2538) |
| `Action.SetAction` | [L2555](../../ExtraButtonSystem/Engine/Action.lua#L2555) |
| `Action.MouseoverCastSpell` | [L2626](../../ExtraButtonSystem/Engine/Action.lua#L2626) |
| `Action.RefreshProfessions` | [L2637](../../ExtraButtonSystem/Engine/Action.lua#L2637) |
| `Action.RefreshMounts` | [L2677](../../ExtraButtonSystem/Engine/Action.lua#L2677) |
| `Action.Clear` | [L2710](../../ExtraButtonSystem/Engine/Action.lua#L2710) |
| `Action.Pickup` | [L2899](../../ExtraButtonSystem/Engine/Action.lua#L2899) |
| `Action.NoteFlyoutPopupSpell` | [L2962](../../ExtraButtonSystem/Engine/Action.lua#L2962) |
| `Action.NoteFlyoutPopupItem` | [L2971](../../ExtraButtonSystem/Engine/Action.lua#L2971) |
| `Action.OnReceiveDrag` | [L3174](../../ExtraButtonSystem/Engine/Action.lua#L3174) |
| `Action.OnDragStart` | [L3232](../../ExtraButtonSystem/Engine/Action.lua#L3232) |
| `Action.OnEnter` | [L3347](../../ExtraButtonSystem/Engine/Action.lua#L3347) |
| `Action.AppendTooltipExtras` | [L3379](../../ExtraButtonSystem/Engine/Action.lua#L3379) |
| `Action.OnLeave` | [L3405](../../ExtraButtonSystem/Engine/Action.lua#L3405) |
| `Action.UpdateTooltip` | [L3494](../../ExtraButtonSystem/Engine/Action.lua#L3494) |
| `FluxButton:SetAction` | [L3647](../../ExtraButtonSystem/Engine/Action.lua#L3647) |
| `FluxButton:OnEnter` | [L3651](../../ExtraButtonSystem/Engine/Action.lua#L3651) |
| `FluxButton:OnLeave` | [L3658](../../ExtraButtonSystem/Engine/Action.lua#L3658) |
| `FluxButton:FullRefresh` | [L3662](../../ExtraButtonSystem/Engine/Action.lua#L3662) |
| `FluxButton:TranslateFace` | [L3668](../../ExtraButtonSystem/Engine/Action.lua#L3668) |
| `FluxButton:TranslateMacro` | [L3672](../../ExtraButtonSystem/Engine/Action.lua#L3672) |
| `FluxButton:ClearAction` | [L3676](../../ExtraButtonSystem/Engine/Action.lua#L3676) |
| `FluxButton:Pickup` | [L3680](../../ExtraButtonSystem/Engine/Action.lua#L3680) |

### ExtraButtonSystem/Engine/Badge.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Badge.StackCount` | [L19](../../ExtraButtonSystem/Engine/Badge.lua#L19) |
| `Badge.SyncCountFont` | [L95](../../ExtraButtonSystem/Engine/Badge.lua#L95) |
| `Badge.SyncFrameLevel` | [L149](../../ExtraButtonSystem/Engine/Badge.lua#L149) |
| `Badge.Layout` | [L260](../../ExtraButtonSystem/Engine/Badge.lua#L260) |
| `Badge.ShowVisual` | [L356](../../ExtraButtonSystem/Engine/Badge.lua#L356) |
| `Badge.HideVisual` | [L382](../../ExtraButtonSystem/Engine/Badge.lua#L382) |
| `Badge.ApplyVisualSpellTexture` | [L403](../../ExtraButtonSystem/Engine/Badge.lua#L403) |
| `Badge.Clear` | [L426](../../ExtraButtonSystem/Engine/Badge.lua#L426) |
| `Badge.New` | [L440](../../ExtraButtonSystem/Engine/Badge.lua#L440) |
| `endbtn.Layout` | [L473](../../ExtraButtonSystem/Engine/Badge.lua#L473) |
| `endbtn.ShowVisual` | [L476](../../ExtraButtonSystem/Engine/Badge.lua#L476) |
| `endbtn.HideVisual` | [L479](../../ExtraButtonSystem/Engine/Badge.lua#L479) |
| `endbtn.ApplyVisualSpellTexture` | [L482](../../ExtraButtonSystem/Engine/Badge.lua#L482) |
| `endbtn.Clear` | [L485](../../ExtraButtonSystem/Engine/Badge.lua#L485) |

### ExtraButtonSystem/Engine/ConsumableBind.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Bridge.ShouldHoldItemIdentity` | [L89](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L89) |
| `Bridge.KeepConsumableSlot` | [L94](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L94) |
| `Bridge.BagCount` | [L229](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L229) |
| `Bridge.DisplayItemCount` | [L236](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L236) |
| `Bridge.IsManaGemChargeBased` | [L267](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L267) |
| `Bridge.ShouldUseChargeBasedManaGemOnly` | [L274](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L274) |
| `Bridge.KnowsManaGemConjureSpell` | [L377](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L377) |
| `Bridge.IsManaGemConjureFree` | [L401](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L401) |
| `Bridge.ShouldStickyManaGemItem` | [L411](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L411) |
| `Bridge.GetPreferredManaGemItemID` | [L416](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L416) |
| `Bridge.GetNextManaGemConjureSpell` | [L424](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L424) |
| `Bridge.GetBestOwned` | [L506](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L506) |
| `Bridge.GetOwnedLadder` | [L666](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L666) |
| `Bridge.PromoteIfBetter` | [L893](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L893) |
| `Bridge.CanCreate` | [L945](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L945) |
| `Bridge.GetPreferredCreateSpell` | [L954](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L954) |
| `Bridge.GetFoodConjureSpell` | [L965](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L965) |
| `Bridge.GetFoodSecondaryConjureSpell` | [L973](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L973) |
| `Bridge.GetWaterConjureSpell` | [L981](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L981) |
| `Bridge.GetWaterSecondaryConjureSpell` | [L989](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L989) |
| `Bridge.ApplyRightClickMacro` | [L1004](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1004) |
| `Bridge.ResolveSpellName` | [L1023](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1023) |
| `Bridge.ApplyRightClickSpell` | [L1050](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1050) |
| `Bridge.ApplyShiftRightClickSpell` | [L1107](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1107) |
| `Bridge.ApplyCtrlRightClickSpell` | [L1163](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1163) |
| `Bridge.ApplyUseAndConjureBindings` | [L1222](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1222) |
| `Bridge.BuildUseItemMacro` | [L1300](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1300) |
| `Bridge.BuildCastSequenceMacro` | [L1308](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1308) |
| `Bridge.After` | [L1329](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1329) |
| `Bridge.DeleteOneOwned` | [L1340](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1340) |
| `Bridge.IsConjured` | [L1376](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1376) |
| `Bridge.DeleteOneConjuredOwned` | [L1403](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1403) |
| `Bridge.ApplyBinding` | [L1411](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1411) |
| `Bridge.FormatSpellTooltipLine` | [L1444](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1444) |
| `Bridge.ResetFluxTooltipGap` | [L1561](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1561) |
| `Bridge._EnsureFluxTooltipGap` | [L1568](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1568) |
| `Bridge.AppendConjureSpellLines` | [L1576](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1576) |
| `Bridge.AppendTierStatusLines` | [L1726](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1726) |
| `Bridge.AppendDeleteStackHint` | [L1819](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1819) |
| `Bridge.WireRestockEdit` | [L1855](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1855) |
| `Bridge.GetRestockClickHint` | [L1897](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1897) |
| `Bridge.AppendRestockEditHint` | [L1901](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1901) |
| `Bridge.GetBestCraftable` | [L1993](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L1993) |
| `Bridge.CanCraft` | [L2002](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2002) |
| `Bridge.GetCraftMacro` | [L2011](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2011) |
| `Bridge.ApplyCraftOrRestockRightClick` | [L2049](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2049) |
| `Bridge.AppendCraftTooltipLines` | [L2103](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2103) |
| `Bridge.ApplyMiddleClickNoUse` | [L2140](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2140) |
| `Bridge.SuppressCheckedVisual` | [L2183](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2183) |
| `Bridge.SuppressCheckedVisualSettle` | [L2223](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2223) |
| `Bridge.GetConsumableCombatSwap` | [L2263](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2263) |
| `Bridge.SetConsumableCombatSwap` | [L2275](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2275) |
| `Bridge.CombatSwapTooltipKind` | [L2290](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2290) |
| `Bridge.SyncSwapEmptyFace` | [L2407](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2407) |
| `Bridge.ApplyCombatSwap` | [L2504](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2504) |
| `Bridge.RefreshConsumableCombatSwap` | [L2570](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2570) |
| `Bridge.QueueConsumableFaceRefresh` | [L2670](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2670) |
| `Refresh.Attach` | [L2868](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L2868) |
| `Module.Update` | [L3210](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3210) |
| `Module.RefreshCountOnly` | [L3417](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3417) |
| `Module.RefreshCraftState` | [L3481](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3481) |
| `Module.Update` | [L3713](../../ExtraButtonSystem/Engine/ConsumableBind.lua#L3713) |

### ExtraButtonSystem/Engine/Paint.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Paint.InvalidateSpellCaches` | [L52](../../ExtraButtonSystem/Engine/Paint.lua#L52) |
| `Paint.ClearCache` | [L66](../../ExtraButtonSystem/Engine/Paint.lua#L66) |
| `Paint.IsParked` | [L91](../../ExtraButtonSystem/Engine/Paint.lua#L91) |
| `Paint.RequestShown` | [L112](../../ExtraButtonSystem/Engine/Paint.lua#L112) |
| `Paint.HasPendingIcon` | [L133](../../ExtraButtonSystem/Engine/Paint.lua#L133) |
| `Paint.UpdateEmpty` | [L250](../../ExtraButtonSystem/Engine/Paint.lua#L250) |
| `Paint.EnsureAutocast` | [L362](../../ExtraButtonSystem/Engine/Paint.lua#L362) |
| `Paint.UpdateAutocast` | [L393](../../ExtraButtonSystem/Engine/Paint.lua#L393) |
| `Paint.UpdateIcon` | [L711](../../ExtraButtonSystem/Engine/Paint.lua#L711) |
| `Paint.UpdateCount` | [L1182](../../ExtraButtonSystem/Engine/Paint.lua#L1182) |
| `Paint.UpdateCooldown` | [L1876](../../ExtraButtonSystem/Engine/Paint.lua#L1876) |
| `Paint.UpdateAllCooldowns` | [L2033](../../ExtraButtonSystem/Engine/Paint.lua#L2033) |
| `Paint.UpdateUsable` | [L2385](../../ExtraButtonSystem/Engine/Paint.lua#L2385) |
| `Paint.NotePlayerCast` | [L2640](../../ExtraButtonSystem/Engine/Paint.lua#L2640) |
| `Paint.UpdateFlash` | [L3034](../../ExtraButtonSystem/Engine/Paint.lua#L3034) |
| `Paint.FlushFlash` | [L3072](../../ExtraButtonSystem/Engine/Paint.lua#L3072) |
| `Paint.UpdateChecked` | [L3087](../../ExtraButtonSystem/Engine/Paint.lua#L3087) |
| `Paint.FlushIcons` | [L3227](../../ExtraButtonSystem/Engine/Paint.lua#L3227) |
| `Paint.RequestIcon` | [L3251](../../ExtraButtonSystem/Engine/Paint.lua#L3251) |
| `Paint.FlushChecked` | [L3285](../../ExtraButtonSystem/Engine/Paint.lua#L3285) |
| `Paint.ArmCheckedPoll` | [L3360](../../ExtraButtonSystem/Engine/Paint.lua#L3360) |
| `Paint.RequestChecked` | [L3368](../../ExtraButtonSystem/Engine/Paint.lua#L3368) |
| `Paint.RequestCheckedSettle` | [L3384](../../ExtraButtonSystem/Engine/Paint.lua#L3384) |
| `Paint.UpdateGlow` | [L3397](../../ExtraButtonSystem/Engine/Paint.lua#L3397) |
| `Paint.UpdateEquipped` | [L3543](../../ExtraButtonSystem/Engine/Paint.lua#L3543) |
| `Paint.UpdateRange` | [L3690](../../ExtraButtonSystem/Engine/Paint.lua#L3690) |
| `Paint.Update` | [L3712](../../ExtraButtonSystem/Engine/Paint.lua#L3712) |
| `Paint.UpdateLiveFace` | [L3732](../../ExtraButtonSystem/Engine/Paint.lua#L3732) |
| `Paint.FlushEval` | [L3743](../../ExtraButtonSystem/Engine/Paint.lua#L3743) |
| `Paint.FlushCounts` | [L3849](../../ExtraButtonSystem/Engine/Paint.lua#L3849) |
| `FluxButton:UpdateEmptyBackground` | [L3898](../../ExtraButtonSystem/Engine/Paint.lua#L3898) |
| `FluxButton:UpdateUsable` | [L3902](../../ExtraButtonSystem/Engine/Paint.lua#L3902) |
| `FluxButton:UpdateCooldown` | [L3906](../../ExtraButtonSystem/Engine/Paint.lua#L3906) |
| `FluxButton:UpdateEquipped` | [L3910](../../ExtraButtonSystem/Engine/Paint.lua#L3910) |

### ExtraButtonSystem/Engine/Range.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Range.IsArmed` | [L97](../../ExtraButtonSystem/Engine/Range.lua#L97) |
| `Range.RefreshButton` | [L102](../../ExtraButtonSystem/Engine/Range.lua#L102) |
| `Range.RefreshFlags` | [L116](../../ExtraButtonSystem/Engine/Range.lua#L116) |
| `Range.RefreshItemFlags` | [L131](../../ExtraButtonSystem/Engine/Range.lua#L131) |
| `Range.Sync` | [L135](../../ExtraButtonSystem/Engine/Range.lua#L135) |
| `Range.SyncDemand` | [L151](../../ExtraButtonSystem/Engine/Range.lua#L151) |
| `Range.Start` | [L155](../../ExtraButtonSystem/Engine/Range.lua#L155) |

### ExtraButtonSystem/Engine/Style.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Style.UseQuickslotRing` | [L25](../../ExtraButtonSystem/Engine/Style.lua#L25) |
| `Style.StampFace` | [L109](../../ExtraButtonSystem/Engine/Style.lua#L109) |
| `Style.RefreshSqueezeChrome` | [L122](../../ExtraButtonSystem/Engine/Style.lua#L122) |
| `Style.SizeRing` | [L421](../../ExtraButtonSystem/Engine/Style.lua#L421) |
| `Style.RefreshAccent` | [L529](../../ExtraButtonSystem/Engine/Style.lua#L529) |
| `Style.Apply` | [L536](../../ExtraButtonSystem/Engine/Style.lua#L536) |
| `Style.ApplySlotRing` | [L565](../../ExtraButtonSystem/Engine/Style.lua#L565) |

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
| `Arrow.ConfigureLayer` | [L39](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L39) |
| `Arrow.Rotation` | [L87](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L87) |
| `Arrow.Anchor` | [L120](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L120) |
| `Arrow.SetTint` | [L153](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L153) |
| `Arrow.ApplyAccent` | [L192](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L192) |
| `Arrow.Ensure` | [L204](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L204) |
| `Arrow.Update` | [L248](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L248) |
| `Arrow.SetOpen` | [L262](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L262) |
| `Arrow.Show` | [L268](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L268) |
| `Arrow.Hide` | [L290](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L290) |
| `Arrow.RefreshAll` | [L305](../../ExtraButtonSystem/FlyoutEngine/Arrow.lua#L305) |

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
| `Def.NormalizeList` | [L80](../../ExtraButtonSystem/FlyoutEngine/Def.lua#L80) |
| `Def.ItemAttr` | [L100](../../ExtraButtonSystem/FlyoutEngine/Def.lua#L100) |

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
| `Grid.New` | [L36](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L36) |
| `grid:CreateButton` | [L87](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L87) |
| `btn:SetPlaceholder` | [L151](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L151) |
| `btn:ClearPlaceholder` | [L174](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L174) |
| `btn:SetLocked` | [L189](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L189) |
| `btn:SetCount` | [L201](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L201) |
| `btn:ShowTooltip` | [L248](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L248) |
| `btn:OnEnter` | [L255](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L255) |
| `btn:OnLeave` | [L264](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L264) |
| `btn:FullRefresh` | [L272](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L272) |
| `btn:Show` | [L286](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L286) |
| `btn:Hide` | [L290](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L290) |
| `returnnilendendgrid.SetButtonColumnPriority` | [L309](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L309) |
| `endendgrid.SetButtonOrder` | [L316](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L316) |
| `grid:ComputeDynamicPriorities` | [L378](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L378) |
| `grid:ConsolidateColumns` | [L493](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L493) |
| `grid:BeginLayout` | [L620](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L620) |
| `grid:EndLayout` | [L624](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L624) |
| `grid:ScheduleRelayout` | [L632](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L632) |
| `grid:Relayout` | [L678](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L678) |
| `grid:Relayout` | [L854](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L854) |
| `grid:RefreshAllModules` | [L863](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L863) |
| `grid:Show` | [L881](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L881) |
| `grid:Hide` | [L882](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L882) |
| `FluxNonCombatGrid_ApplyAppearanceAccent` | [L888](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L888) |
| `Grid.RefreshAfterVisibilityChange` | [L911](../../ExtraButtonSystem/NonCombatGrid/Grid.lua#L911) |

### ExtraButtonSystem/NonCombatGrid/GridInit.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `API.UpdateAnchor` | [L57](../../ExtraButtonSystem/NonCombatGrid/GridInit.lua#L57) |
| `API_G.FluxNonCombatGrid_ApplyScreenBottomAnchor` | [L175](../../ExtraButtonSystem/NonCombatGrid/GridInit.lua#L175) |

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
| `Manager.BuildMacroText` | [L192](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L192) |
| `Manager.UpdateHotkeys` | [L604](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L604) |
| `Manager.UpdateButton` | [L711](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L711) |
| `btn.UpdateChecked` | [L881](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L881) |
| `Manager.EnsureButtons` | [L887](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L887) |
| `Manager.ShouldShowEmptySlots` | [L974](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L974) |
| `Manager.UpdateVisibility` | [L985](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L985) |
| `Manager._DoUpdateAllSlots` | [L1018](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1018) |
| `Manager.UpdateAllSlots` | [L1072](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1072) |
| `Manager.RefreshProfessions` | [L1087](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1087) |
| `Manager.UpdateBindings` | [L1124](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1124) |
| `ManagerA.OnSlotsChanged` | [L1445](../../ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua#L1445) |

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
| `HotkeyUtil.SetText` | [L63](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L63) |
| `HotkeyUtil.SetRange` | [L69](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L69) |
| `HotkeyUtil.GetFormattedKeyFromKey` | [L168](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L168) |
| `HotkeyUtil.GetBindingKeyText` | [L238](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L238) |
| `HotkeyUtil.UpdateHotkeyText` | [L253](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L253) |
| `HotkeyUtil.UpdateHotkeyTextMultiple` | [L295](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L295) |
| `HotkeyUtil.AddTooltipBinding` | [L316](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L316) |
| `HotkeyUtil.AddTooltipBindings` | [L326](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L326) |
| `HotkeyUtil.RefreshAfterBindingChange` | [L359](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L359) |
| `HotkeyUtil.FlushAfterBulkBindings` | [L393](../../ExtraButtonSystem/Shared/HotkeyUtil.lua#L393) |

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
| `TM.RefreshArrowLayersOnBorder` | [L350](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L350) |
| `TM.ApplyHorizontalSqueeze` | [L369](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L369) |
| `TM.CreateGrid` | [L495](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L495) |
| `TM.WidgetForTrinketBind` | [L686](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L686) |
| `TM.SyncKeybindPushWatch` | [L834](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L834) |
| `TM.HookTrinketClickScripts` | [L945](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L945) |
| `TM.SyncEquippedFace` | [L979](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L979) |
| `TM.CreateTrinketButton` | [L1010](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1010) |
| `btn.UpdateUsable` | [L1098](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1098) |
| `endbtn.UpdateEquipped` | [L1102](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1102) |
| `btn.Widget.UpdateTooltip` | [L1111](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1111) |
| `button.UpdateUsable` | [L1202](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1202) |
| `endbutton.UpdateEquipped` | [L1205](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1205) |
| `TM.CreateFlyoutArrow` | [L1264](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1264) |
| `TM.UpdateArrowRotation` | [L1284](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1284) |
| `TM.UpdateArrowVisibility` | [L1298](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1298) |
| `TM.SetupButtonScripts` | [L1370](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1370) |
| `TM.OnTrinketClick` | [L1398](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1398) |
| `TM.ShowTrinketTooltip` | [L1420](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1420) |
| `TM.RestoreTrinketIconColor` | [L1453](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1453) |
| `TM.RestoreTrinketBorderColor` | [L1465](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1465) |
| `TM.HideEquippedGreenBorder` | [L1492](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1492) |
| `TM.EnsureUsabilityTextureRefs` | [L1513](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1513) |
| `TM.ApplyTrinketUsability` | [L1535](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1535) |
| `TM.ApplyMenuTrinketUsability` | [L1594](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1594) |
| `TM.UpdateTrinketButton` | [L1603](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1603) |
| `TM.UpdateTrinketCooldown` | [L1639](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1639) |
| `TM.UpdateAllTrinkets` | [L1673](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1673) |
| `TM.UpdateAllCooldowns` | [L1680](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1680) |
| `TM.UpdateAllUsability` | [L1688](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1688) |
| `TM.CreateMenuFrame` | [L1699](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1699) |
| `TM.ScanBagsForTrinkets` | [L1732](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1732) |
| `TM.SyncFlyoutEngine` | [L1860](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1860) |
| `TM.BuildMenu` | [L1928](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1928) |
| `TM.UpdateMenuButtonCooldown` | [L1953](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1953) |
| `TM.OnMenuTrinketClick` | [L1964](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1964) |
| `TM.ShowMenuTrinketTooltip` | [L1997](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L1997) |
| `TM.StartMenuMouseoverTimer` | [L2030](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2030) |
| `TM.QueueTrinketSwap` | [L2078](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2078) |
| `TM.ProcessCombatQueue` | [L2098](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2098) |
| `TM.EquipTrinket` | [L2114](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2114) |
| `TM.UpdateQueueVisuals` | [L2158](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2158) |
| `TM.UpdateKeybindings` | [L2167](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2167) |
| `TM.Show` | [L2294](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2294) |
| `TM.Hide` | [L2310](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2310) |
| `TM.Toggle` | [L2336](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2336) |
| `TM.HasEquippedTrinkets` | [L2353](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2353) |
| `TM.GetEquippedTrinketSlots` | [L2358](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2358) |
| `TM.GetTrinketVisibilityState` | [L2370](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2370) |
| `TM.UpdateTrinketVisibility` | [L2387](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2387) |
| `FluxTrinketMenu_ApplyAppearanceAccent` | [L2572](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua#L2572) |

### ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua

Owner: [12-extra-button-system.md](../12-extra-button-system.md).

| Declaration | Source |
|---|---|
| `Manager:UpdateAnchor` | [L73](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L73) |
| `Manager:UpdateStripAnchor` | [L134](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L134) |
| `Manager:GetFrame` | [L430](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L430) |
| `Manager:GetButtons` | [L434](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L434) |
| `Manager:Refresh` | [L438](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L438) |
| `Manager.UpdateKeybindings` | [L447](../../ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua#L447) |

### FluxBorder.lua

Owner: [04-visual-system.md](../04-visual-system.md).

| Declaration | Source |
|---|---|
| `Border:GetBorderType` | [L46](../../FluxBorder.lua#L46) |
| `Border:GetBorderThickness` | [L52](../../FluxBorder.lua#L52) |
| `Border:IsUntintedAtlasAccent` | [L83](../../FluxBorder.lua#L83) |
| `Border:GetForeverClientChromeRGB` | [L88](../../FluxBorder.lua#L88) |
| `Border:GetForeverClientBackdropRGB` | [L96](../../FluxBorder.lua#L96) |
| `Border:GetDefaultAccentRGB` | [L105](../../FluxBorder.lua#L105) |
| `Border:GetDefaultBackdropRGB` | [L111](../../FluxBorder.lua#L111) |
| `Border:GetAccentColor` | [L120](../../FluxBorder.lua#L120) |
| `Border:RefreshAllAccentedFrames` | [L143](../../FluxBorder.lua#L143) |
| `Border:GetAccentMode` | [L159](../../FluxBorder.lua#L159) |
| `Border:GetThemedVertexRGB` | [L165](../../FluxBorder.lua#L165) |
| `Border:GetThemedBackdropFillRGB` | [L174](../../FluxBorder.lua#L174) |
| `Border:RefreshAppearanceDependents` | [L186](../../FluxBorder.lua#L186) |
| `FluxUI_RefreshAppearance` | [L245](../../FluxBorder.lua#L245) |
| `Border:CanUseAtlases` | [L276](../../FluxBorder.lua#L276) |
| `Border:GetJoinTracks` | [L325](../../FluxBorder.lua#L325) |
| `Border:GetSideTrackOffset` | [L339](../../FluxBorder.lua#L339) |
| `Border:RefreshPaintOwners` | [L404](../../FluxBorder.lua#L404) |
| `Border:RegisterPiece` | [L470](../../FluxBorder.lua#L470) |
| `Border:SetUntinted` | [L503](../../FluxBorder.lua#L503) |
| `Border:SetUnitColor` | [L515](../../FluxBorder.lua#L515) |
| `Border:RefreshBorderType` | [L525](../../FluxBorder.lua#L525) |
| `Border:RefreshAllBorderTypes` | [L549](../../FluxBorder.lua#L549) |
| `Border:GetBorderPreview` | [L570](../../FluxBorder.lua#L570) |
| `Border:GetBorderTypeChoices` | [L583](../../FluxBorder.lua#L583) |
| `Border:CreateTypeOption` | [L591](../../FluxBorder.lua#L591) |
| `Border:ApplyTo` | [L635](../../FluxBorder.lua#L635) |
| `Border:SetPortraitAttachment` | [L798](../../FluxBorder.lua#L798) |
| `Border:RemoveFrom` | [L848](../../FluxBorder.lua#L848) |
| `Border:SetOverlayLayer` | [L876](../../FluxBorder.lua#L876) |
| `Border:PreparePortraitBackdrop` | [L885](../../FluxBorder.lua#L885) |
| `Border:SetBorderColor` | [L906](../../FluxBorder.lua#L906) |
| `Border:SetNativeUnitColor` | [L927](../../FluxBorder.lua#L927) |
| `Border:SetNativeUnitBackdrop` | [L938](../../FluxBorder.lua#L938) |
| `Border:SetBackdropColor` | [L954](../../FluxBorder.lua#L954) |
| `Border:SetBackdropAlpha` | [L968](../../FluxBorder.lua#L968) |
| `Border:SetClassColor` | [L986](../../FluxBorder.lua#L986) |
| `Border:HideBackground` | [L1012](../../FluxBorder.lua#L1012) |
| `Border:ShowBackground` | [L1022](../../FluxBorder.lua#L1022) |
| `Border:ApplyCircle` | [L1040](../../FluxBorder.lua#L1040) |
| `Border:RefreshClassColor` | [L1055](../../FluxBorder.lua#L1055) |

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
| `FluxUILayoutSqueeze.CanKeepGridAnchors` | [L923](../../FluxDefaultSettings.lua#L923) |
| `FluxUILayoutSqueeze.CanKeepGridPacking` | [L966](../../FluxDefaultSettings.lua#L966) |
| `FluxUILayoutSqueeze.NewGridPacking` | [L984](../../FluxDefaultSettings.lua#L984) |
| `FluxUILayoutSqueeze.NotifyLayoutDependents` | [L1019](../../FluxDefaultSettings.lua#L1019) |
| `FluxUILayoutSqueeze.EnsureDisplayRefreshHooks` | [L1133](../../FluxDefaultSettings.lua#L1133) |
| `FluxUILayoutSqueeze.RequestRefresh` | [L1149](../../FluxDefaultSettings.lua#L1149) |
| `FluxDefaultSettings.GetState` | [L1197](../../FluxDefaultSettings.lua#L1197) |
| `FluxDefaultSettings.ApplyNameplateScalarDefaults` | [L1375](../../FluxDefaultSettings.lua#L1375) |
| `FluxDefaultSettings.ApplyNameplateClassColorDefault` | [L1379](../../FluxDefaultSettings.lua#L1379) |
| `FluxDefaultSettings.ApplyNameplateNpcNameDefaults` | [L1383](../../FluxDefaultSettings.lua#L1383) |
| `FluxDefaultSettings.ApplyNameplateBitfieldDefaults` | [L1387](../../FluxDefaultSettings.lua#L1387) |
| `FluxDefaultSettings.ApplyNameplateDefaultsPack` | [L1391](../../FluxDefaultSettings.lua#L1391) |
| `FluxDefaultSettings.ScheduleNameplateDefaultsPack` | [L1395](../../FluxDefaultSettings.lua#L1395) |
| `FluxDefaultSettings.ApplySpecialCVarSettings` | [L1415](../../FluxDefaultSettings.lua#L1415) |
| `FluxDefaultSettings.ApplyRaidFrameSettings` | [L1452](../../FluxDefaultSettings.lua#L1452) |
| `FluxDefaultSettings.EnsureNameplateSizeMedium` | [L1457](../../FluxDefaultSettings.lua#L1457) |
| `FluxDefaultSettings.ScheduleRaidArenaFrameDefaultsPack` | [L1474](../../FluxDefaultSettings.lua#L1474) |
| `FluxDefaultSettings.ApplyRaidArenaFrameDefaultsPackNow` | [L1478](../../FluxDefaultSettings.lua#L1478) |
| `FluxDefaultSettings.ApplyRaidArenaFrameDefaultsPack` | [L1482](../../FluxDefaultSettings.lua#L1482) |
| `FluxDefaultSettings.ApplyInterfaceDefaultsPack` | [L1488](../../FluxDefaultSettings.lua#L1488) |
| `FluxDefaultSettings.ApplyStickyTargetingOff` | [L1496](../../FluxDefaultSettings.lua#L1496) |
| `FluxDefaultSettings.GetMaxCameraDistanceZoomFactor` | [L1527](../../FluxDefaultSettings.lua#L1527) |
| `FluxDefaultSettings.ApplyMaxCameraDistance` | [L1550](../../FluxDefaultSettings.lua#L1550) |
| `FluxDefaultSettings.ApplyControlsDefaultsPack` | [L1581](../../FluxDefaultSettings.lua#L1581) |
| `FluxDefaultSettings.ApplyChatSettings` | [L1661](../../FluxDefaultSettings.lua#L1661) |
| `FluxDefaultSettings.ApplySelfCastAndFocusCastDefaults` | [L1707](../../FluxDefaultSettings.lua#L1707) |
| `FluxDefaultSettings.ApplyCombatDefaultsPack` | [L1712](../../FluxDefaultSettings.lua#L1712) |
| `FluxDefaultSettings.ApplyActionBarDefaultsPack` | [L1840](../../FluxDefaultSettings.lua#L1840) |
| `FluxDefaultSettings.ShouldSuppressBindingRefresh` | [L1932](../../FluxDefaultSettings.lua#L1932) |
| `FluxDefaultSettings.FlushBindingRefreshAfterBulk` | [L1947](../../FluxDefaultSettings.lua#L1947) |
| `FluxDefaultSettings.SavePendingModifiedClicks` | [L2028](../../FluxDefaultSettings.lua#L2028) |
| `FluxDefaultSettings.ApplyKeybinds` | [L2079](../../FluxDefaultSettings.lua#L2079) |
| `FluxDefaultSettings.PrepareAccountBindingBootstrap` | [L2351](../../FluxDefaultSettings.lua#L2351) |
| `FluxDefaultSettings.EnsureDefaultFluxBindings` | [L2416](../../FluxDefaultSettings.lua#L2416) |
| `FluxDefaultSettings.ReassertSoftTargetEnemyFromDefaults` | [L2463](../../FluxDefaultSettings.lua#L2463) |
| `FluxDefaultSettings.ScheduleSoftTargetEnemyReassertFromDefaults` | [L2492](../../FluxDefaultSettings.lua#L2492) |
| `FluxDefaultSettings.SyncSettingsRegistryProxies` | [L2501](../../FluxDefaultSettings.lua#L2501) |
| `FluxDefaultSettings.ApplyCharacterFirstLogin` | [L2537](../../FluxDefaultSettings.lua#L2537) |
| `FluxDefaultSettings.VerifyInitialNonBindingDefaults` | [L2571](../../FluxDefaultSettings.lua#L2571) |
| `FluxDefaultSettings.VerifyPostLoginDefaults` | [L2657](../../FluxDefaultSettings.lua#L2657) |
| `FluxDefaultSettings.Apply` | [L2710](../../FluxDefaultSettings.lua#L2710) |
| `FluxDefaultSettings.ApplyCVarsOnly` | [L2991](../../FluxDefaultSettings.lua#L2991) |
| `FluxDefaultSettings.PrintDebug` | [L3434](../../FluxDefaultSettings.lua#L3434) |

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
| `C.ChangedFromDelta` | [L782](../../Inventory/Containers.lua#L782) |
| `C.NewItemSetLog` | [L804](../../Inventory/Containers.lua#L804) |
| `C.NoteItemSets` | [L809](../../Inventory/Containers.lua#L809) |
| `C.TakeItemSets` | [L824](../../Inventory/Containers.lua#L824) |

### Inventory/Craft.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Craft.GetCraftableCount` | [L190](../../Inventory/Craft.lua#L190) |
| `Craft.HasProfessionForKind` | [L342](../../Inventory/Craft.lua#L342) |
| `Craft.GetOutputPerCraft` | [L556](../../Inventory/Craft.lua#L556) |
| `Craft.ListRecipesForKind` | [L587](../../Inventory/Craft.lua#L587) |
| `Craft.InvalidateCanCraftCache` | [L661](../../Inventory/Craft.lua#L661) |
| `Craft.BagChangesAffectKind` | [L667](../../Inventory/Craft.lua#L667) |
| `Craft.GetBestCraftable` | [L680](../../Inventory/Craft.lua#L680) |
| `Craft.CanCraftKind` | [L729](../../Inventory/Craft.lua#L729) |
| `Craft.GetBandageProfessionSpellName` | [L772](../../Inventory/Craft.lua#L772) |
| `Craft.ClearPendingCraft` | [L862](../../Inventory/Craft.lua#L862) |
| `Craft.TryFlushPendingCraft` | [L956](../../Inventory/Craft.lua#L956) |
| `Craft.ExecuteCraft` | [L971](../../Inventory/Craft.lua#L971) |
| `Craft.ExecuteHealPotionCraft` | [L1020](../../Inventory/Craft.lua#L1020) |
| `Craft.ExecuteManaPotionCraft` | [L1024](../../Inventory/Craft.lua#L1024) |
| `Craft.ExecuteBandageCraft` | [L1028](../../Inventory/Craft.lua#L1028) |

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
| `Best._notifyListeners` | [L123](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L123) |
| `Best.RegisterListener` | [L131](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L131) |
| `Best.UnregisterListener` | [L138](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L138) |
| `Best.RequestRecompute` | [L142](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L142) |
| `Best.GetBest` | [L185](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L185) |
| `Best.GetBestRef` | [L208](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L208) |
| `Best.GetLadder` | [L312](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L312) |
| `Best.GetBestOwned` | [L331](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L331) |
| `Best.GetAllBest` | [L350](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L350) |
| `Best.FindStacks` | [L370](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L370) |
| `Best.Init` | [L551](../../Inventory/FluxConsumableBest/FluxConsumableBest.lua#L551) |

### Inventory/FluxConsumableBest/Init.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Best.HasEmptyRelevantKind` | [L83](../../Inventory/FluxConsumableBest/Init.lua#L83) |
| `Best.IsLoginScanActive` | [L100](../../Inventory/FluxConsumableBest/Init.lua#L100) |
| `Best.EndLoginScan` | [L112](../../Inventory/FluxConsumableBest/Init.lua#L112) |
| `Best.BeginLoginScan` | [L121](../../Inventory/FluxConsumableBest/Init.lua#L121) |
| `Best.IsSoftHoldKind` | [L168](../../Inventory/FluxConsumableBest/Init.lua#L168) |
| `Best.ShouldSoftHoldOwned` | [L181](../../Inventory/FluxConsumableBest/Init.lua#L181) |
| `Best.EndLoadHold` | [L219](../../Inventory/FluxConsumableBest/Init.lua#L219) |
| `Best.BeginLoadHold` | [L225](../../Inventory/FluxConsumableBest/Init.lua#L225) |
| `Best.ArmPortalSoftHold` | [L243](../../Inventory/FluxConsumableBest/Init.lua#L243) |
| `Best.MergePendingAdded` | [L279](../../Inventory/FluxConsumableBest/Init.lua#L279) |
| `Best.IsConjureArmActive` | [L292](../../Inventory/FluxConsumableBest/Init.lua#L292) |
| `Best.ArmConjureChase` | [L298](../../Inventory/FluxConsumableBest/Init.lua#L298) |
| `Best.IsManaKind` | [L333](../../Inventory/FluxConsumableBest/Init.lua#L333) |
| `Best.IsManaKindRelevant` | [L337](../../Inventory/FluxConsumableBest/Init.lua#L337) |
| `Best.IsValidKind` | [L348](../../Inventory/FluxConsumableBest/Init.lua#L348) |

### Inventory/FluxConsumableBest/Persist.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Persist.GetRoot` | [L26](../../Inventory/FluxConsumableBest/Persist.lua#L26) |
| `Persist.NormalizePotion` | [L30](../../Inventory/FluxConsumableBest/Persist.lua#L30) |
| `Persist.GetRef` | [L123](../../Inventory/FluxConsumableBest/Persist.lua#L123) |
| `Persist.GetAllRefs` | [L128](../../Inventory/FluxConsumableBest/Persist.lua#L128) |
| `Persist.MaybeUpdateRef` | [L194](../../Inventory/FluxConsumableBest/Persist.lua#L194) |
| `Persist.GetVendorSeen` | [L211](../../Inventory/FluxConsumableBest/Persist.lua#L211) |
| `Persist.RememberVendorItem` | [L220](../../Inventory/FluxConsumableBest/Persist.lua#L220) |
| `Persist.GetAllVendorSeen` | [L241](../../Inventory/FluxConsumableBest/Persist.lua#L241) |

### Inventory/FluxConsumableBest/Scan.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Scan.Recompute` | [L560](../../Inventory/FluxConsumableBest/Scan.lua#L560) |
| `Scan.OnItemDataLoaded` | [L1209](../../Inventory/FluxConsumableBest/Scan.lua#L1209) |
| `Best.IsSettled` | [L1269](../../Inventory/FluxConsumableBest/Scan.lua#L1269) |
| `Best.GetPendingLoadCount` | [L1279](../../Inventory/FluxConsumableBest/Scan.lua#L1279) |
| `Best.GetClassifyQueueCount` | [L1289](../../Inventory/FluxConsumableBest/Scan.lua#L1289) |

### Inventory/FluxConsumableBest/Score.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Score.HealthstoneRank` | [L48](../../Inventory/FluxConsumableBest/Score.lua#L48) |
| `Score.GetPools` | [L64](../../Inventory/FluxConsumableBest/Score.lua#L64) |
| `Score.EffectiveFromClassify` | [L86](../../Inventory/FluxConsumableBest/Score.lua#L86) |
| `Score.InvalidateUsableCache` | [L116](../../Inventory/FluxConsumableBest/Score.lua#L116) |
| `Score.IsBelowRequiredLevel` | [L291](../../Inventory/FluxConsumableBest/Score.lua#L291) |
| `Score.IsKnownUnusable` | [L307](../../Inventory/FluxConsumableBest/Score.lua#L307) |
| `Score.IsExcludedFromBest` | [L329](../../Inventory/FluxConsumableBest/Score.lua#L329) |
| `Score.IsBlockedForBest` | [L348](../../Inventory/FluxConsumableBest/Score.lua#L348) |
| `Score.IsUsableForVendor` | [L385](../../Inventory/FluxConsumableBest/Score.lua#L385) |
| `Score.IsUsable` | [L411](../../Inventory/FluxConsumableBest/Score.lua#L411) |
| `Score.GetMaxStack` | [L469](../../Inventory/FluxConsumableBest/Score.lua#L469) |
| `Score.FoodTier` | [L512](../../Inventory/FluxConsumableBest/Score.lua#L512) |
| `Score.WaterDrinkTier` | [L534](../../Inventory/FluxConsumableBest/Score.lua#L534) |
| `Score.IsBetter` | [L556](../../Inventory/FluxConsumableBest/Score.lua#L556) |

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
| `C.IsManaGemItem` | [L697](../../Inventory/FluxConsumableClassify.lua#L697) |
| `C.IsCombatUtilityPotion` | [L789](../../Inventory/FluxConsumableClassify.lua#L789) |
| `C.IsHealingPotionName` | [L793](../../Inventory/FluxConsumableClassify.lua#L793) |
| `C.IsManaPotionName` | [L797](../../Inventory/FluxConsumableClassify.lua#L797) |
| `C.ParseFoodWaterRestore` | [L825](../../Inventory/FluxConsumableClassify.lua#L825) |
| `C.GetInvalidationRevision` | [L960](../../Inventory/FluxConsumableClassify.lua#L960) |
| `C.ResetParseBudget` | [L964](../../Inventory/FluxConsumableClassify.lua#L964) |
| `C.InvalidateCache` | [L973](../../Inventory/FluxConsumableClassify.lua#L973) |
| `C.IsPending` | [L985](../../Inventory/FluxConsumableClassify.lua#L985) |
| `C.IsRejected` | [L992](../../Inventory/FluxConsumableClassify.lua#L992) |
| `C.ForceReject` | [L999](../../Inventory/FluxConsumableClassify.lua#L999) |
| `C.Classify` | [L1219](../../Inventory/FluxConsumableClassify.lua#L1219) |
| `C.ResolveCombatTierAxes` | [L1450](../../Inventory/FluxConsumableClassify.lua#L1450) |
| `FluxNCItemDetection.ParseFoodWaterRestore` | [L1468](../../Inventory/FluxConsumableClassify.lua#L1468) |
| `endFluxNCItemDetection.ItemGrantsWellFed` | [L1473](../../Inventory/FluxConsumableClassify.lua#L1473) |
| `FluxItemDetection.ResolveCombatTierAxes` | [L1501](../../Inventory/FluxConsumableClassify.lua#L1501) |

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
| `IC.GetStatic` | [L89](../../Inventory/FluxItemClass.lua#L89) |
| `IC.RequestLoad` | [L166](../../Inventory/FluxItemClass.lua#L166) |
| `IC.GetInfo` | [L180](../../Inventory/FluxItemClass.lua#L180) |
| `IC.IsLoaded` | [L196](../../Inventory/FluxItemClass.lua#L196) |
| `IC.GetName` | [L200](../../Inventory/FluxItemClass.lua#L200) |
| `IC.GetLink` | [L205](../../Inventory/FluxItemClass.lua#L205) |
| `IC.GetQuality` | [L225](../../Inventory/FluxItemClass.lua#L225) |
| `ns.ReadCachedItemQuality` | [L234](../../Inventory/FluxItemClass.lua#L234) |
| `IC.GetSellPrice` | [L245](../../Inventory/FluxItemClass.lua#L245) |
| `IC.GetStackSize` | [L260](../../Inventory/FluxItemClass.lua#L260) |
| `IC.GetIcon` | [L265](../../Inventory/FluxItemClass.lua#L265) |
| `IC.GetClassID` | [L274](../../Inventory/FluxItemClass.lua#L274) |
| `IC.GetSubClassID` | [L279](../../Inventory/FluxItemClass.lua#L279) |
| `IC.GetEquipLoc` | [L284](../../Inventory/FluxItemClass.lua#L284) |
| `IC.IsEquippable` | [L291](../../Inventory/FluxItemClass.lua#L291) |
| `IC.GetTooltipText` | [L396](../../Inventory/FluxItemClass.lua#L396) |
| `ns.WithAuctionRestockBagTooltips` | [L434](../../Inventory/FluxItemClass.lua#L434) |
| `IC.GetRestore` | [L460](../../Inventory/FluxItemClass.lua#L460) |
| `IC.InvalidateRestoreCache` | [L534](../../Inventory/FluxItemClass.lua#L534) |
| `IC.ClassifyConsumable` | [L564](../../Inventory/FluxItemClass.lua#L564) |
| `IC.InvalidateClassification` | [L647](../../Inventory/FluxItemClass.lua#L647) |
| `IC.OnItemDataLoaded` | [L661](../../Inventory/FluxItemClass.lua#L661) |
| `IC.OnItemDataEvent` | [L723](../../Inventory/FluxItemClass.lua#L723) |

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
| `Index.GetCount` | [L72](../../Inventory/Index.lua#L72) |
| `Index.Find` | [L219](../../Inventory/Index.lua#L219) |
| `Index.GetFirst` | [L287](../../Inventory/Index.lua#L287) |
| `Index.GetUniqueItems` | [L388](../../Inventory/Index.lua#L388) |
| `Index.GetUniqueItemIDs` | [L455](../../Inventory/Index.lua#L455) |
| `Index.UniqueCount` | [L572](../../Inventory/Index.lua#L572) |
| `Index.ForEachLocation` | [L640](../../Inventory/Index.lua#L640) |
| `Index.GetSnapshotGeneration` | [L687](../../Inventory/Index.lua#L687) |
| `Index.GetFirstFreeBagSlot` | [L694](../../Inventory/Index.lua#L694) |
| `Inv.GetCount` | [L717](../../Inventory/Index.lua#L717) |
| `Inv.Find` | [L759](../../Inventory/Index.lua#L759) |
| `Inv.GetFirst` | [L763](../../Inventory/Index.lua#L763) |
| `Inv.GetUniqueItems` | [L767](../../Inventory/Index.lua#L767) |
| `Inv.GetUniqueItemIDs` | [L773](../../Inventory/Index.lua#L773) |
| `rec.linkiflinkthenreturnlinkendendendendendns.InventoryUniqueItemIDQuery.carriedOrBankLink` | [L797](../../Inventory/Index.lua#L797) |
| `Inv.ForEachLocation` | [L845](../../Inventory/Index.lua#L845) |
| `Inv.GetSnapshotGeneration` | [L849](../../Inventory/Index.lua#L849) |
| `Inv.GetFirstFreeBagSlot` | [L853](../../Inventory/Index.lua#L853) |
| `Inv.GetBagGeneration` | [L857](../../Inventory/Index.lua#L857) |

### Inventory/Init.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Inv.LoadPersistedBankCounts` | [L62](../../Inventory/Init.lua#L62) |
| `Inv.PersistBankCounts` | [L85](../../Inventory/Init.lua#L85) |
| `Inv.SnapshotCountKeys` | [L120](../../Inventory/Init.lua#L120) |
| `Inv.ClassifyCountKeys` | [L133](../../Inventory/Init.lua#L133) |
| `Inv.MergeChangeKind` | [L181](../../Inventory/Init.lua#L181) |
| `Inv.IsScanPending` | [L212](../../Inventory/Init.lua#L212) |
| `Inv.RequestItemData` | [L324](../../Inventory/Init.lua#L324) |
| `Inv.PruneItemDataForBag` | [L356](../../Inventory/Init.lua#L356) |
| `Inv.NoteItemDataArrived` | [L395](../../Inventory/Init.lua#L395) |
| `Inv.IsBagStorm` | [L475](../../Inventory/Init.lua#L475) |
| `Inv.NotifyBagStorm` | [L503](../../Inventory/Init.lua#L503) |
| `Inv.EndBagStorm` | [L517](../../Inventory/Init.lua#L517) |
| `Inv.OnStormSettled` | [L525](../../Inventory/Init.lua#L525) |
| `Inv.RegisterStormSettled` | [L540](../../Inventory/Init.lua#L540) |
| `Inv.UnregisterStormSettled` | [L547](../../Inventory/Init.lua#L547) |
| `Inv.SetMerchantOpen` | [L551](../../Inventory/Init.lua#L551) |
| `Inv.IsMerchantOpen` | [L555](../../Inventory/Init.lua#L555) |
| `Inv.SetMailboxOpen` | [L560](../../Inventory/Init.lua#L560) |
| `Inv.IsMailboxOpen` | [L580](../../Inventory/Init.lua#L580) |
| `Inv.ShouldDeferHeavyWork` | [L594](../../Inventory/Init.lua#L594) |
| `Inv.GetLastAddedItemIDs` | [L863](../../Inventory/Init.lua#L863) |
| `Inv.Notify` | [L906](../../Inventory/Init.lua#L906) |
| `Inv.Register` | [L972](../../Inventory/Init.lua#L972) |
| `Inv.Unregister` | [L990](../../Inventory/Init.lua#L990) |
| `Inv.GetListenerInfo` | [L996](../../Inventory/Init.lua#L996) |
| `Inv.GetSource` | [L1013](../../Inventory/Init.lua#L1013) |
| `Inv.IsReady` | [L1017](../../Inventory/Init.lua#L1017) |
| `Inv.SnapshotLooksCollapsed` | [L1056](../../Inventory/Init.lua#L1056) |
| `Inv.MarkUnreliable` | [L1069](../../Inventory/Init.lua#L1069) |
| `Inv.BeginLoginHold` | [L1103](../../Inventory/Init.lua#L1103) |
| `Inv.IsLoginHold` | [L1130](../../Inventory/Init.lua#L1130) |
| `Inv.NoteLoginBagsDelayed` | [L1142](../../Inventory/Init.lua#L1142) |
| `Inv.IsReliable` | [L1197](../../Inventory/Init.lua#L1197) |
| `Inv.NoteRefreshSettling` | [L1209](../../Inventory/Init.lua#L1209) |
| `Inv.HasWarband` | [L1273](../../Inventory/Init.lua#L1273) |
| `Inv.IsBaganatorBankViewShown` | [L1364](../../Inventory/Init.lua#L1364) |
| `Inv.IsBaganatorBankLiveShown` | [L1385](../../Inventory/Init.lua#L1385) |
| `Inv.RegisterBankStateListener` | [L1404](../../Inventory/Init.lua#L1404) |
| `Inv.ShouldKeepBankOpen` | [L1440](../../Inventory/Init.lua#L1440) |
| `Inv.SetBankOpenLatch` | [L1444](../../Inventory/Init.lua#L1444) |
| `Inv.SetBaganatorBankLive` | [L1475](../../Inventory/Init.lua#L1475) |
| `Inv.IsBaganatorBankLive` | [L1507](../../Inventory/Init.lua#L1507) |
| `Inv.IsBankLive` | [L1513](../../Inventory/Init.lua#L1513) |
| `Inv.CanTakeFromBank` | [L1535](../../Inventory/Init.lua#L1535) |
| `Inv.IsBankOpen` | [L1554](../../Inventory/Init.lua#L1554) |
| `Inv.PrepareHUD` | [L1626](../../Inventory/Init.lua#L1626) |
| `Inv.Start` | [L1639](../../Inventory/Init.lua#L1639) |

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
| `Prof.GetCharacterKey` | [L265](../../Inventory/Professions.lua#L265) |
| `Prof.GetRecipeLive` | [L963](../../Inventory/Professions.lua#L963) |
| `Prof.GetCompleteness` | [L992](../../Inventory/Professions.lua#L992) |
| `Prof.GetRecipe` | [L1030](../../Inventory/Professions.lua#L1030) |
| `Prof.GetReagents` | [L1060](../../Inventory/Professions.lua#L1060) |
| `Prof.GetOutput` | [L1065](../../Inventory/Professions.lua#L1065) |
| `Prof.IsLearned` | [L1073](../../Inventory/Professions.lua#L1073) |
| `Prof.ListCachedRecipes` | [L1087](../../Inventory/Professions.lua#L1087) |
| `Prof.ListSkillKeys` | [L1099](../../Inventory/Professions.lua#L1099) |
| `Prof.GetSkillInfo` | [L1108](../../Inventory/Professions.lua#L1108) |
| `Prof.OnProfessionEvent` | [L1117](../../Inventory/Professions.lua#L1117) |
| `Prof.ListAllCachedRecipes` | [L1254](../../Inventory/Professions.lua#L1254) |
| `Prof.ListRecipesForOutput` | [L1282](../../Inventory/Professions.lua#L1282) |
| `ns.ListOwnedRecipesByOutput` | [L1333](../../Inventory/Professions.lua#L1333) |
| `Prof.OnProfessionClosed` | [L1362](../../Inventory/Professions.lua#L1362) |
| `Prof.OnEventPulse` | [L1367](../../Inventory/Professions.lua#L1367) |
| `Prof.InvalidateSkillCaches` | [L1455](../../Inventory/Professions.lua#L1455) |
| `Prof.GetProfessionKnowledge` | [L1638](../../Inventory/Professions.lua#L1638) |
| `Prof.GetRecipeKnowledge` | [L1686](../../Inventory/Professions.lua#L1686) |
| `Prof.HasProfessionName` | [L1724](../../Inventory/Professions.lua#L1724) |
| `Prof.GetProfessionRank` | [L1729](../../Inventory/Professions.lua#L1729) |
| `Prof.GetSkillLineRank` | [L1744](../../Inventory/Professions.lua#L1744) |
| `Prof.GetSkillRequirementFromText` | [L1799](../../Inventory/Professions.lua#L1799) |
| `Prof.GetSkillRequirementFromTooltip` | [L1812](../../Inventory/Professions.lua#L1812) |
| `Prof.GetSkillRequirementFromTooltipData` | [L1846](../../Inventory/Professions.lua#L1846) |
| `Prof.GetSkillRequirementFromBagSlot` | [L1874](../../Inventory/Professions.lua#L1874) |
| `Prof.GetItemSkillRequirement` | [L1952](../../Inventory/Professions.lua#L1952) |
| `Prof.ScheduleLoginScan` | [L2059](../../Inventory/Professions.lua#L2059) |
| `Prof.AbortLoginScan` | [L2094](../../Inventory/Professions.lua#L2094) |
| `Prof.ForceScanOpen` | [L2167](../../Inventory/Professions.lua#L2167) |
| `Prof.ResetLoginScanState` | [L2172](../../Inventory/Professions.lua#L2172) |

### Inventory/Restock/Auction/FluxAuctionRestock.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `A.PrintStatus` | [L32](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L32) |
| `A.Invalidate` | [L92](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L92) |
| `A.IsLegacy` | [L217](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L217) |
| `A.Select` | [L224](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L224) |
| `A.BeginPotionBrowse` | [L570](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L570) |
| `A.PrepareNext` | [L739](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L739) |
| `A.ScanQueue` | [L744](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L744) |
| `A.Primary` | [L911](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L911) |
| `A.ShowSession` | [L1047](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L1047) |
| `ns.AuctionRestockOnShow` | [L1052](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L1052) |
| `A.HideSession` | [L1061](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L1061) |
| `A.SettingsChanged` | [L1068](../../Inventory/Restock/Auction/FluxAuctionRestock.lua#L1068) |

### Inventory/Restock/Auction/FluxAuctionRestockCraft.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `A.CraftRecipes` | [L180](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L180) |
| `A.SavedRecipeKnowledge` | [L199](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L199) |
| `A.RefreshCraftRecipes` | [L291](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L291) |
| `A.BookCost` | [L302](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L302) |
| `A.CraftCountsBank` | [L360](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L360) |
| `A.CraftBankFlagsMatch` | [L370](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L370) |
| `A.GetCraftBankAvailable` | [L422](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L422) |
| `A.GetCraftBagAvailable` | [L425](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L425) |
| `A.CompareCraft` | [L446](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L446) |
| `A.ResetCraftPlans` | [L514](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L514) |
| `A.CancelCraftPricing` | [L523](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L523) |
| `A.IsCraftOutput` | [L524](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L524) |
| `A.HasCraftPlans` | [L525](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L525) |
| `A.ClearVendorCraftPlan` | [L527](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L527) |
| `A.GetVendorCraftTargets` | [L559](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L559) |
| `A.MaterialRows` | [L660](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L660) |
| `A.MaterialLimit` | [L726](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L726) |
| `A.CheckCraftSpend` | [L775](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L775) |
| `A.RecordCraftSpend` | [L779](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L779) |
| `A.ReleaseCraftSpend` | [L785](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L785) |
| `A.StartCraftPricing` | [L789](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L789) |
| `A.RouteText` | [L852](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L852) |
| `A.RepriceMaterial` | [L858](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L858) |
| `A.CraftStatus` | [L871](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L871) |
| `A.RecipeDetails` | [L900](../../Inventory/Restock/Auction/FluxAuctionRestockCraft.lua#L900) |

### Inventory/Restock/Auction/FluxAuctionRestockData.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `A.Number` | [L8](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L8) |
| `A.Settings` | [L29](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L29) |
| `A.IsUpgradeEnabled` | [L42](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L42) |
| `A.SetUpgradeEnabled` | [L48](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L48) |
| `A.UpgradeItemID` | [L56](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L56) |
| `A.IsUpgradeBlacklisted` | [L61](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L61) |
| `A.RefreshConsumableExclusions` | [L66](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L66) |
| `A.ExcludesDiscoloredHealing` | [L72](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L72) |
| `A.SetExcludeDiscoloredHealing` | [L73](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L73) |
| `A.SetUpgradeBlacklisted` | [L82](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L82) |
| `A.UpgradeBlacklistItems` | [L92](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L92) |
| `A.GetMaxPrice` | [L100](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L100) |
| `A.IsPriceUnlimited` | [L103](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L103) |
| `A.PriceLimit` | [L114](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L114) |
| `A.PricePolicyMatches` | [L117](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L117) |
| `A.PreferCrafting` | [L121](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L121) |
| `A.SetPreferCrafting` | [L122](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L122) |
| `A.PurchaseLimit` | [L127](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L127) |
| `A.SetMaxPrice` | [L133](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L133) |
| `A.SetPriceUnlimited` | [L146](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L146) |
| `A.ParsePrice` | [L151](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L151) |
| `A.PriceText` | [L169](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L169) |
| `A.VendorSource` | [L178](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L178) |
| `A.HasUnlimitedVendor` | [L199](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L199) |
| `A.IsVendorItem` | [L203](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L203) |
| `A.VendorPrice` | [L206](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L206) |
| `A.VendorTerms` | [L210](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L210) |
| `A.IsFoodWater` | [L227](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L227) |
| `A.SetItemUnits` | [L243](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L243) |
| `A.AllowExcessStacks` | [L287](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L287) |
| `A.IsInventoryReliable` | [L298](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L298) |
| `A.IsReliable` | [L304](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L304) |
| `A.NoteRestockMailbox` | [L312](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L312) |
| `A.RefreshMailFacts` | [L322](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L322) |
| `A.MailUnits` | [L333](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L333) |
| `A.PredictedMailUnits` | [L346](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L346) |
| `A.Pending` | [L380](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L380) |
| `A.Need` | [L420](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L420) |
| `A.Reserve` | [L460](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L460) |
| `A.AcceptReservation` | [L470](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L470) |
| `A.Release` | [L476](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L476) |
| `A.RowLess` | [L500](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L500) |
| `A.GetRows` | [L562](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L562) |
| `A.GetVendorScanRows` | [L617](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L617) |
| `A.FindRow` | [L619](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L619) |
| `A.SelectStack` | [L626](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L626) |
| `A.CommodityOffer` | [L653](../../Inventory/Restock/Auction/FluxAuctionRestockData.lua#L653) |

### Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `F.Capture` | [L135](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L135) |
| `F.Purchased` | [L185](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L185) |
| `F.HasWork` | [L200](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L200) |
| `F.IsAutoEnabled` | [L204](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L204) |
| `F.SetAutoEnabled` | [L205](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L205) |
| `F.IsContextOpen` | [L210](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L210) |
| `F.CanAct` | [L232](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L232) |
| `F.GetMailItems` | [L255](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L255) |
| `F.MailTakeStarted` | [L265](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L265) |
| `F.MailTakeFinished` | [L278](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L278) |
| `F.MailTakeCancelled` | [L286](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L286) |
| `F.OwnerRejected` | [L293](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L293) |
| `F.MailSnapshotComplete` | [L302](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L302) |
| `F.Planned` | [L333](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L333) |
| `F.Clear` | [L342](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L342) |
| `F.GetState` | [L576](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L576) |
| `F.GetBankTargets` | [L577](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L577) |
| `F.GetVendorTargets` | [L581](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L581) |
| `F.Refresh` | [L586](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L586) |
| `F.Click` | [L652](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L652) |
| `F.Resume` | [L681](../../Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua#L681) |

### Inventory/Restock/Auction/FluxAuctionRestockFollowupCraft.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `F.CraftIsBusy` | [L85](../../Inventory/Restock/Auction/FluxAuctionRestockFollowupCraft.lua#L85) |
| `F.CanCraft` | [L209](../../Inventory/Restock/Auction/FluxAuctionRestockFollowupCraft.lua#L209) |
| `F.CraftClick` | [L213](../../Inventory/Restock/Auction/FluxAuctionRestockFollowupCraft.lua#L213) |

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
| `A.PotionReplacement` | [L64](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L64) |
| `A.ApplyPotionReplacements` | [L73](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L73) |
| `A.CancelPotionDiscovery` | [L108](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L108) |
| `A.ResetPotionUpgradeChoices` | [L113](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L113) |
| `A.ResetPotionDiscovery` | [L114](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L114) |
| `A.HasPotionCatalog` | [L121](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L121) |
| `A.HasBlockedPotionTargets` | [L127](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L127) |
| `A.PotionRowBlocked` | [L128](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L128) |
| `A.DiscoverPotionUpgrades` | [L211](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L211) |
| `proposal.resolve` | [L306](../../Inventory/Restock/Auction/FluxAuctionRestockPotions.lua#L306) |

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
| `A.Toggle` | [L611](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L611) |
| `A.AttachButton` | [L625](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L625) |
| `SlashCmdList.FLUXAUCTIONRESTOCK` | [L672](../../Inventory/Restock/Auction/FluxAuctionRestockUI.lua#L672) |

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
| `Inventory.SnapshotContainers` | [L62](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L62) |
| `Inventory.SnapshotPlayerBags` | [L90](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L90) |
| `Inventory.SnapshotBank` | [L94](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L94) |
| `Inventory.MatchItemID` | [L99](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L99) |
| `Inventory.MatchTierKind` | [L107](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L107) |
| `Inventory.FindBestFit` | [L115](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L115) |
| `Inventory.HasEmptyBagSlot` | [L162](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L162) |
| `Inventory.SlotKey` | [L183](../../Inventory/Restock/Bank/FluxBankRestockInventory.lua#L183) |

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
| `FV.AddRestockItem` | [L32](../../Inventory/Restock/Core/FluxRestockList.lua#L32) |
| `FV.RemoveRestockItem` | [L56](../../Inventory/Restock/Core/FluxRestockList.lua#L56) |
| `FV.SetRestockTarget` | [L72](../../Inventory/Restock/Core/FluxRestockList.lua#L72) |
| `FV.GetRestockTargetForItem` | [L96](../../Inventory/Restock/Core/FluxRestockList.lua#L96) |
| `FV.GetRestockItemFlags` | [L102](../../Inventory/Restock/Core/FluxRestockList.lua#L102) |
| `FV.SetRestockItemFlag` | [L115](../../Inventory/Restock/Core/FluxRestockList.lua#L115) |
| `FV.DismissRestockReagent` | [L136](../../Inventory/Restock/Core/FluxRestockList.lua#L136) |
| `FV.GetRestockShowNotSold` | [L152](../../Inventory/Restock/Core/FluxRestockList.lua#L152) |
| `FV.SetRestockShowNotSold` | [L156](../../Inventory/Restock/Core/FluxRestockList.lua#L156) |
| `FV.SetRestockFoodWaterTarget` | [L190](../../Inventory/Restock/Core/FluxRestockList.lua#L190) |
| `FV.SetRestockCombatTarget` | [L197](../../Inventory/Restock/Core/FluxRestockList.lua#L197) |
| `FV.GetTierCountBankFlag` | [L204](../../Inventory/Restock/Core/FluxRestockList.lua#L204) |
| `FV.SetTierCountBankFlag` | [L209](../../Inventory/Restock/Core/FluxRestockList.lua#L209) |
| `FV.ResetTierReference` | [L216](../../Inventory/Restock/Core/FluxRestockList.lua#L216) |
| `List.CancelSpellReagentCacheWarm` | [L342](../../Inventory/Restock/Core/FluxRestockList.lua#L342) |
| `List.InvalidateSpellReagentCache` | [L345](../../Inventory/Restock/Core/FluxRestockList.lua#L345) |
| `List.OnActiveReagentsFinalized` | [L386](../../Inventory/Restock/Core/FluxRestockList.lua#L386) |
| `FV.IsStaticSpellReagentItem` | [L433](../../Inventory/Restock/Core/FluxRestockList.lua#L433) |
| `FV.IsKnownSpellReagentItem` | [L453](../../Inventory/Restock/Core/FluxRestockList.lua#L453) |
| `FV.IsSpellReagentItem` | [L457](../../Inventory/Restock/Core/FluxRestockList.lua#L457) |
| `List.RecordMerchantPrices` | [L516](../../Inventory/Restock/Core/FluxRestockList.lua#L516) |
| `List.GetItemUnitPrice` | [L549](../../Inventory/Restock/Core/FluxRestockList.lua#L549) |
| `List.GetItemUnitPriceFluxRestock.GetTargetQuantity` | [L573](../../Inventory/Restock/Core/FluxRestockList.lua#L573) |
| `endFluxRestock.SetTargetQuantity` | [L574](../../Inventory/Restock/Core/FluxRestockList.lua#L574) |
| `endFluxRestock.GetRestockCost` | [L575](../../Inventory/Restock/Core/FluxRestockList.lua#L575) |
| `endFluxRestock.IsKnownSpellReagentItem` | [L591](../../Inventory/Restock/Core/FluxRestockList.lua#L591) |
| `endFluxRestock.IsStaticSpellReagentItem` | [L592](../../Inventory/Restock/Core/FluxRestockList.lua#L592) |
| `endFluxRestock.IsSpellReagentItem` | [L593](../../Inventory/Restock/Core/FluxRestockList.lua#L593) |
| `endFluxRestock.InvalidateSpellReagentCache` | [L594](../../Inventory/Restock/Core/FluxRestockList.lua#L594) |
| `FV.InvalidateRestockOptionsPanelCache` | [L721](../../Inventory/Restock/Core/FluxRestockList.lua#L721) |
| `FV.GetRestockTargetItems` | [L726](../../Inventory/Restock/Core/FluxRestockList.lua#L726) |
| `FV.HasAnyRestockTargets` | [L914](../../Inventory/Restock/Core/FluxRestockList.lua#L914) |
| `FV.IsRestockEntrySoldAtVendor` | [L942](../../Inventory/Restock/Core/FluxRestockList.lua#L942) |
| `FV.FilterRestockListForVendor` | [L963](../../Inventory/Restock/Core/FluxRestockList.lua#L963) |
| `FV.SortRestockEntriesByVendorAvailability` | [L980](../../Inventory/Restock/Core/FluxRestockList.lua#L980) |
| `FV.GetRestockVendorItems` | [L999](../../Inventory/Restock/Core/FluxRestockList.lua#L999) |
| `FV.RefreshRestockCacheEntries` | [L1011](../../Inventory/Restock/Core/FluxRestockList.lua#L1011) |
| `FV.HasRestockNeeded` | [L1086](../../Inventory/Restock/Core/FluxRestockList.lua#L1086) |
| `FV.GetRestockTotalCost` | [L1096](../../Inventory/Restock/Core/FluxRestockList.lua#L1096) |
| `FV.RefreshMerchantOptionsCheckboxes` | [L1113](../../Inventory/Restock/Core/FluxRestockList.lua#L1113) |
| `Registry.InvalidateBankTargetsCache` | [L1164](../../Inventory/Restock/Core/FluxRestockList.lua#L1164) |
| `Registry.RegisterProvider` | [L1169](../../Inventory/Restock/Core/FluxRestockList.lua#L1169) |
| `Registry.UnregisterProvider` | [L1177](../../Inventory/Restock/Core/FluxRestockList.lua#L1177) |
| `Registry.GetBankTargets` | [L1228](../../Inventory/Restock/Core/FluxRestockList.lua#L1228) |
| `Registry.GetBankTargetList` | [L1246](../../Inventory/Restock/Core/FluxRestockList.lua#L1246) |
| `Registry.GetItemMaxStack` | [L1263](../../Inventory/Restock/Core/FluxRestockList.lua#L1263) |
| `Registry.CountItemInBank` | [L1274](../../Inventory/Restock/Core/FluxRestockList.lua#L1274) |
| `Registry.GetSlotCharges` | [L1404](../../Inventory/Restock/Core/FluxRestockList.lua#L1404) |
| `Registry.GetChargeInfo` | [L1485](../../Inventory/Restock/Core/FluxRestockList.lua#L1485) |
| `Registry.IsChargeItem` | [L1546](../../Inventory/Restock/Core/FluxRestockList.lua#L1546) |
| `Registry.GetItemMaxCharges` | [L1568](../../Inventory/Restock/Core/FluxRestockList.lua#L1568) |
| `Registry.GetChargeAwareCount` | [L1586](../../Inventory/Restock/Core/FluxRestockList.lua#L1586) |

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
| `S.Get` | [L209](../../Inventory/Restock/Core/FluxRestockSettings.lua#L209) |
| `FluxVendorAuto.EnsureSettings` | [L244](../../Inventory/Restock/Core/FluxRestockSettings.lua#L244) |
| `FluxVendorAuto.GetSettings` | [L248](../../Inventory/Restock/Core/FluxRestockSettings.lua#L248) |

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
| `P.ClassifyItem` | [L263](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L263) |
| `P.ClassificationForTierCount` | [L268](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L268) |
| `P.TierAxisValue` | [L300](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L300) |
| `Tiers.Classify` | [L304](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L304) |
| `P.MerchantItemLink` | [L309](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L309) |
| `P.ClassifyMerchantItem` | [L323](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L323) |
| `P.ScanVendorBestPurchasable` | [L405](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L405) |
| `Tiers.GetItemTierValue` | [L430](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L430) |
| `Tiers.GetBagOwnedTier` | [L436](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L436) |
| `Tiers.GetOwnedTier` | [L464](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L464) |
| `Tiers.GetJunkReferenceTier` | [L508](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L508) |
| `Tiers.GetEffectiveReferenceTier` | [L563](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L563) |
| `Tiers.GetReferenceTier` | [L606](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L606) |
| `Tiers.RememberOwnedTiers` | [L616](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L616) |
| `Tiers.ResetTierReference` | [L624](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L624) |
| `P.GetVendorBestTier` | [L645](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L645) |
| `Tiers.GetInferiorReferenceTier` | [L650](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L650) |
| `P.GetTierRestockThreshold` | [L678](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L678) |
| `P.IsTierItemUsable` | [L698](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L698) |
| `P.ItemMatchesTier` | [L713](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L713) |
| `P.ItemMatchesTierForBank` | [L734](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L734) |
| `P.ItemMatchesTierLooseForBank` | [L745](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L745) |
| `Tiers.ItemMatchesRestockKind` | [L786](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L786) |
| `Tiers.StackMatchesBankRestockKind` | [L824](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L824) |
| `Tiers.GetTierCount` | [L960](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L960) |
| `P.GetTierCountForRestockList` | [L965](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L965) |
| `Tiers.GetSnapshotTierCount` | [L972](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L972) |
| `Tiers.GetTierBagTotalForBankRestock` | [L1060](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L1060) |
| `P.GetBankTierBagTotal` | [L1075](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L1075) |
| `Tiers.GetBankCountForKind` | [L1175](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L1175) |
| `P.GetBankCountForRestockList` | [L1190](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L1190) |
| `Tiers.GetCachedTooltipReferenceTier` | [L1219](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L1219) |
| `Tiers.GetTooltipDisplay` | [L1223](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L1223) |
| `Tiers.KindsTouchedByItemID` | [L1231](../../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua#L1231) |

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
| `RI.API` | [L104](../../Inventory/Restock/FluxRestock_Inv.lua#L104) |
| `RI.IsReady` | [L108](../../Inventory/Restock/FluxRestock_Inv.lua#L108) |
| `RI.IsReliable` | [L113](../../Inventory/Restock/FluxRestock_Inv.lua#L113) |
| `RI.IsBankOpen` | [L121](../../Inventory/Restock/FluxRestock_Inv.lua#L121) |
| `RI.IsBankLive` | [L138](../../Inventory/Restock/FluxRestock_Inv.lua#L138) |
| `RI.HasWarband` | [L152](../../Inventory/Restock/FluxRestock_Inv.lua#L152) |
| `RI.GetCarriedBagIDs` | [L158](../../Inventory/Restock/FluxRestock_Inv.lua#L158) |
| `RI.GetBagContainerIDs` | [L166](../../Inventory/Restock/FluxRestock_Inv.lua#L166) |
| `RI.GetPlayerRestockBagIDs` | [L177](../../Inventory/Restock/FluxRestock_Inv.lua#L177) |
| `RI.GetCharacterBankIDs` | [L185](../../Inventory/Restock/FluxRestock_Inv.lua#L185) |
| `RI.GetWarbandBankIDs` | [L193](../../Inventory/Restock/FluxRestock_Inv.lua#L193) |
| `RI.GetCount` | [L216](../../Inventory/Restock/FluxRestock_Inv.lua#L216) |
| `RI.GetUniqueItems` | [L279](../../Inventory/Restock/FluxRestock_Inv.lua#L279) |
| `RI.Bags.GetUniqueItems` | [L289](../../Inventory/Restock/FluxRestock_Inv.lua#L289) |
| `RI.ForEachLocation` | [L312](../../Inventory/Restock/FluxRestock_Inv.lua#L312) |
| `RI.Find` | [L319](../../Inventory/Restock/FluxRestock_Inv.lua#L319) |
| `RI.GetFirst` | [L327](../../Inventory/Restock/FluxRestock_Inv.lua#L327) |
| `RI.GetBagSnapshotGeneration` | [L335](../../Inventory/Restock/FluxRestock_Inv.lua#L335) |
| `RI.GetFirstFreeBagSlot` | [L346](../../Inventory/Restock/FluxRestock_Inv.lua#L346) |
| `RI.FindFirstBagSlot` | [L363](../../Inventory/Restock/FluxRestock_Inv.lua#L363) |
| `RI.FindBagStacks` | [L371](../../Inventory/Restock/FluxRestock_Inv.lua#L371) |
| `RI.ForEachBagSlot` | [L400](../../Inventory/Restock/FluxRestock_Inv.lua#L400) |
| `RI.GetContainerNumSlots` | [L420](../../Inventory/Restock/FluxRestock_Inv.lua#L420) |
| `RI.GetContainerNumFreeSlots` | [L428](../../Inventory/Restock/FluxRestock_Inv.lua#L428) |
| `RI.CountFreeSlotsInBag` | [L436](../../Inventory/Restock/FluxRestock_Inv.lua#L436) |
| `RI.GetTotalFreeBagSlots` | [L462](../../Inventory/Restock/FluxRestock_Inv.lua#L462) |
| `RI.GetContainerItemInfo` | [L547](../../Inventory/Restock/FluxRestock_Inv.lua#L547) |
| `ns.GetRestockTierSlotReader` | [L583](../../Inventory/Restock/FluxRestock_Inv.lua#L583) |
| `RI.GetContainerItemID` | [L593](../../Inventory/Restock/FluxRestock_Inv.lua#L593) |
| `RI.GetContainerItemLink` | [L611](../../Inventory/Restock/FluxRestock_Inv.lua#L611) |
| `RI.GetContainerItemSnapshot` | [L627](../../Inventory/Restock/FluxRestock_Inv.lua#L627) |
| `RI.ItemExistsInInventory` | [L648](../../Inventory/Restock/FluxRestock_Inv.lua#L648) |
| `RI.IsBankContainer` | [L665](../../Inventory/Restock/FluxRestock_Inv.lua#L665) |
| `RI.PickupContainerItem` | [L674](../../Inventory/Restock/FluxRestock_Inv.lua#L674) |
| `RI.GetLastBankUse` | [L705](../../Inventory/Restock/FluxRestock_Inv.lua#L705) |
| `RI.NoteBankUseAfter` | [L709](../../Inventory/Restock/FluxRestock_Inv.lua#L709) |
| `RI.UseContainerItem` | [L718](../../Inventory/Restock/FluxRestock_Inv.lua#L718) |
| `RI.SplitContainerItemPending` | [L804](../../Inventory/Restock/FluxRestock_Inv.lua#L804) |
| `RI.SplitContainerItem` | [L832](../../Inventory/Restock/FluxRestock_Inv.lua#L832) |
| `RI.SetMerchantOpen` | [L868](../../Inventory/Restock/FluxRestock_Inv.lua#L868) |
| `RI.IsMerchantOpen` | [L872](../../Inventory/Restock/FluxRestock_Inv.lua#L872) |
| `RI.IsAutomationQuiet` | [L885](../../Inventory/Restock/FluxRestock_Inv.lua#L885) |
| `RI.NotifyAutomationPulse` | [L903](../../Inventory/Restock/FluxRestock_Inv.lua#L903) |
| `RI.OnQuietSettled` | [L914](../../Inventory/Restock/FluxRestock_Inv.lua#L914) |
| `RI.IsBagStorm` | [L929](../../Inventory/Restock/FluxRestock_Inv.lua#L929) |
| `RI.NotifyBagStorm` | [L950](../../Inventory/Restock/FluxRestock_Inv.lua#L950) |
| `RI.OnStormSettled` | [L961](../../Inventory/Restock/FluxRestock_Inv.lua#L961) |
| `RI.RegisterStormSettled` | [L976](../../Inventory/Restock/FluxRestock_Inv.lua#L976) |
| `RI.UnregisterStormSettled` | [L983](../../Inventory/Restock/FluxRestock_Inv.lua#L983) |
| `RI.ShouldDeferHeavyWork` | [L987](../../Inventory/Restock/FluxRestock_Inv.lua#L987) |
| `RI.NotifyItemsRemoved` | [L994](../../Inventory/Restock/FluxRestock_Inv.lua#L994) |
| `RI.ForceRefreshBagCounts` | [L997](../../Inventory/Restock/FluxRestock_Inv.lua#L997) |
| `RI.FlushExtraButtonIdentityRefresh` | [L1000](../../Inventory/Restock/FluxRestock_Inv.lua#L1000) |
| `Bank.IsOpen` | [L1048](../../Inventory/Restock/FluxRestock_Inv.lua#L1048) |
| `Bank.IsLive` | [L1062](../../Inventory/Restock/FluxRestock_Inv.lua#L1062) |
| `Bank.GetContainerIDs` | [L1079](../../Inventory/Restock/FluxRestock_Inv.lua#L1079) |
| `Bank.GetScanDebug` | [L1097](../../Inventory/Restock/FluxRestock_Inv.lua#L1097) |
| `Bank.IsModernBank` | [L1133](../../Inventory/Restock/FluxRestock_Inv.lua#L1133) |
| `Bank.HasLegacyBankBags` | [L1137](../../Inventory/Restock/FluxRestock_Inv.lua#L1137) |
| `Bank.HasReagentBag` | [L1152](../../Inventory/Restock/FluxRestock_Inv.lua#L1152) |
| `Bank.IsBankContainer` | [L1156](../../Inventory/Restock/FluxRestock_Inv.lua#L1156) |
| `Bank.GetBankTypeForContainer` | [L1160](../../Inventory/Restock/FluxRestock_Inv.lua#L1160) |
| `Bank.Persist` | [L1249](../../Inventory/Restock/FluxRestock_Inv.lua#L1249) |
| `Bank.ForEachLiveStack` | [L1449](../../Inventory/Restock/FluxRestock_Inv.lua#L1449) |
| `Bank.Refresh` | [L1473](../../Inventory/Restock/FluxRestock_Inv.lua#L1473) |
| `Bank.GetCount` | [L1532](../../Inventory/Restock/FluxRestock_Inv.lua#L1532) |
| `Bank.GetCharacterCounts` | [L1569](../../Inventory/Restock/FluxRestock_Inv.lua#L1569) |
| `Bank.GetWarbandCounts` | [L1585](../../Inventory/Restock/FluxRestock_Inv.lua#L1585) |
| `Bank.GetGeneration` | [L1604](../../Inventory/Restock/FluxRestock_Inv.lua#L1604) |
| `Bank.FindStacks` | [L1611](../../Inventory/Restock/FluxRestock_Inv.lua#L1611) |
| `Bank.ForEachOpenStack` | [L1660](../../Inventory/Restock/FluxRestock_Inv.lua#L1660) |
| `Bank.GetItemLink` | [L1692](../../Inventory/Restock/FluxRestock_Inv.lua#L1692) |
| `Bank.RegisterBankOpen` | [L1710](../../Inventory/Restock/FluxRestock_Inv.lua#L1710) |
| `Bank.RegisterBankClose` | [L1717](../../Inventory/Restock/FluxRestock_Inv.lua#L1717) |
| `Bank.RefreshIfOpen` | [L1724](../../Inventory/Restock/FluxRestock_Inv.lua#L1724) |
| `Bank.RequestLiveRefresh` | [L1734](../../Inventory/Restock/FluxRestock_Inv.lua#L1734) |
| `Bank.SchedulePersist` | [L1738](../../Inventory/Restock/FluxRestock_Inv.lua#L1738) |
| `RI.Notify` | [L1772](../../Inventory/Restock/FluxRestock_Inv.lua#L1772) |
| `RI.Register` | [L1915](../../Inventory/Restock/FluxRestock_Inv.lua#L1915) |
| `RI.Unregister` | [L1927](../../Inventory/Restock/FluxRestock_Inv.lua#L1927) |

### Inventory/Restock/Junk/FluxJunk.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `FJ.Init` | [L117](../../Inventory/Restock/Junk/FluxJunk.lua#L117) |
| `FJ.GetFilters` | [L121](../../Inventory/Restock/Junk/FluxJunk.lua#L121) |
| `FJ.GetDisplay` | [L125](../../Inventory/Restock/Junk/FluxJunk.lua#L125) |
| `FJ.IsExplicitUseful` | [L142](../../Inventory/Restock/Junk/FluxJunk.lua#L142) |
| `FJ.IsExplicitJunk` | [L148](../../Inventory/Restock/Junk/FluxJunk.lua#L148) |
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
| `FJ.IsConjuredConsumable` | [L510](../../Inventory/Restock/Junk/FluxJunk.lua#L510) |
| `FJ.IsLowConsumable` | [L528](../../Inventory/Restock/Junk/FluxJunk.lua#L528) |
| `FJ.IsFiltered` | [L672](../../Inventory/Restock/Junk/FluxJunk.lua#L672) |
| `FJ.IsJunk` | [L683](../../Inventory/Restock/Junk/FluxJunk.lua#L683) |
| `FJ.IsJunkForDisplay` | [L708](../../Inventory/Restock/Junk/FluxJunk.lua#L708) |
| `FJ.IsBlizzardVendorJunk` | [L779](../../Inventory/Restock/Junk/FluxJunk.lua#L779) |
| `FJ.NativeJunkCount` | [L824](../../Inventory/Restock/Junk/FluxJunk.lua#L824) |
| `FJ.HasItemInPlayerBags` | [L836](../../Inventory/Restock/Junk/FluxJunk.lua#L836) |
| `FJ.FindBagSlot` | [L841](../../Inventory/Restock/Junk/FluxJunk.lua#L841) |
| `FJ.IterateJunk` | [L926](../../Inventory/Restock/Junk/FluxJunk.lua#L926) |
| `FJ.IterateUpgradeInferiorFast` | [L936](../../Inventory/Restock/Junk/FluxJunk.lua#L936) |
| `FJ.SetUpgradeInferiorKindFilter` | [L952](../../Inventory/Restock/Junk/FluxJunk.lua#L952) |
| `FJ.ClearUpgradeInferiorKindFilter` | [L957](../../Inventory/Restock/Junk/FluxJunk.lua#L957) |
| `FJ.HasUpgradeInferiorForKinds` | [L962](../../Inventory/Restock/Junk/FluxJunk.lua#L962) |
| `FJ.InvalidateJunkWorklist` | [L1020](../../Inventory/Restock/Junk/FluxJunk.lua#L1020) |
| `FJ.IsSlotProtectedFromSell` | [L1024](../../Inventory/Restock/Junk/FluxJunk.lua#L1024) |
| `FJ.BuildJunkSlotWorklist` | [L1033](../../Inventory/Restock/Junk/FluxJunk.lua#L1033) |
| `FJ.EnsureJunkWorklist` | [L1056](../../Inventory/Restock/Junk/FluxJunk.lua#L1056) |
| `FJ.IterateJunkWorklist` | [L1065](../../Inventory/Restock/Junk/FluxJunk.lua#L1065) |
| `FJ.RemoveJunkSlotFromWorklist` | [L1082](../../Inventory/Restock/Junk/FluxJunk.lua#L1082) |
| `FJ.HasJunkWorklistRemaining` | [L1101](../../Inventory/Restock/Junk/FluxJunk.lua#L1101) |
| `FJ.GetUpgradeInferiorSlotCount` | [L1107](../../Inventory/Restock/Junk/FluxJunk.lua#L1107) |
| `FJ.InvalidateJunkSlotCount` | [L1127](../../Inventory/Restock/Junk/FluxJunk.lua#L1127) |
| `FJ.GetJunkSlotCount` | [L1133](../../Inventory/Restock/Junk/FluxJunk.lua#L1133) |
| `FJ.GetJunkSlotCountFast` | [L1137](../../Inventory/Restock/Junk/FluxJunk.lua#L1137) |
| `FJ.RefreshJunkSlotCountFast` | [L1145](../../Inventory/Restock/Junk/FluxJunk.lua#L1145) |
| `FJ.AdjustJunkSlotCount` | [L1149](../../Inventory/Restock/Junk/FluxJunk.lua#L1149) |
| `FJ.RegisterJunkCountListener` | [L1157](../../Inventory/Restock/Junk/FluxJunk.lua#L1157) |
| `FJ.OnBagSnapshotDiff` | [L1162](../../Inventory/Restock/Junk/FluxJunk.lua#L1162) |
| `FJ.AnyJunkInBags` | [L1173](../../Inventory/Restock/Junk/FluxJunk.lua#L1173) |
| `FJ.AnyExplicitJunkInBags` | [L1180](../../Inventory/Restock/Junk/FluxJunk.lua#L1180) |
| `FJ.AnyBlizzardVendorJunkInBags` | [L1197](../../Inventory/Restock/Junk/FluxJunk.lua#L1197) |
| `FJ.HasSellableJunkForButton` | [L1228](../../Inventory/Restock/Junk/FluxJunk.lua#L1228) |
| `FJ.RefreshSellableJunkButtonState` | [L1253](../../Inventory/Restock/Junk/FluxJunk.lua#L1253) |
| `FJ.GetSellButtonStats` | [L1262](../../Inventory/Restock/Junk/FluxJunk.lua#L1262) |
| `FJ.InvalidateSellButtonStats` | [L1298](../../Inventory/Restock/Junk/FluxJunk.lua#L1298) |
| `FJ.GetSellReport` | [L1303](../../Inventory/Restock/Junk/FluxJunk.lua#L1303) |
| `FJ.FireListChanged` | [L1322](../../Inventory/Restock/Junk/FluxJunk.lua#L1322) |
| `FJ.RegisterListChanged` | [L1336](../../Inventory/Restock/Junk/FluxJunk.lua#L1336) |
| `FJ.NotifyVisualRefresh` | [L1341](../../Inventory/Restock/Junk/FluxJunk.lua#L1341) |
| `FJ.RegisterVisualRefresh` | [L1347](../../Inventory/Restock/Junk/FluxJunk.lua#L1347) |
| `FJ.RefreshJunkVisuals` | [L1352](../../Inventory/Restock/Junk/FluxJunk.lua#L1352) |
| `FJ.ToggleJunk` | [L1362](../../Inventory/Restock/Junk/FluxJunk.lua#L1362) |
| `FJ.AddJunk` | [L1375](../../Inventory/Restock/Junk/FluxJunk.lua#L1375) |
| `FJ.MarkUseful` | [L1382](../../Inventory/Restock/Junk/FluxJunk.lua#L1382) |
| `FJ.ForgetJunk` | [L1390](../../Inventory/Restock/Junk/FluxJunk.lua#L1390) |
| `FJ.ClearAutoJunkMark` | [L1400](../../Inventory/Restock/Junk/FluxJunk.lua#L1400) |
| `FJ.InvalidateJunkTabListCache` | [L1421](../../Inventory/Restock/Junk/FluxJunk.lua#L1421) |
| `FJ.GetExplicitJunkList` | [L1446](../../Inventory/Restock/Junk/FluxJunk.lua#L1446) |
| `FJ.GetUsefulList` | [L1461](../../Inventory/Restock/Junk/FluxJunk.lua#L1461) |
| `FJ.GetAutoJunkList` | [L1480](../../Inventory/Restock/Junk/FluxJunk.lua#L1480) |
| `FJ.GetJunkTabList` | [L1501](../../Inventory/Restock/Junk/FluxJunk.lua#L1501) |
| `FJ.RebuildJunkTabListCache` | [L1526](../../Inventory/Restock/Junk/FluxJunk.lua#L1526) |
| `FJ.IsAutoJunk` | [L1531](../../Inventory/Restock/Junk/FluxJunk.lua#L1531) |
| `FJ.OnManualRestockChanged` | [L1548](../../Inventory/Restock/Junk/FluxJunk.lua#L1548) |
| `FJ.GetItemIdFromCursor` | [L1579](../../Inventory/Restock/Junk/FluxJunk.lua#L1579) |
| `FJ.HandleItemDrop` | [L1590](../../Inventory/Restock/Junk/FluxJunk.lua#L1590) |
| `FJ.WarmJunkDisplayCacheForBags` | [L1608](../../Inventory/Restock/Junk/FluxJunk.lua#L1608) |
| `FJ.WarmJunkDisplayCacheThoroughChunked` | [L1609](../../Inventory/Restock/Junk/FluxJunk.lua#L1609) |
| `FJ.IsJunkDisplayCacheWarm` | [L1612](../../Inventory/Restock/Junk/FluxJunk.lua#L1612) |
| `FJ.ResetJunkDisplayCacheWarm` | [L1613](../../Inventory/Restock/Junk/FluxJunk.lua#L1613) |
| `FJ.InvalidateJunkBag` | [L1614](../../Inventory/Restock/Junk/FluxJunk.lua#L1614) |
| `FJ.InvalidateAllJunkBags` | [L1615](../../Inventory/Restock/Junk/FluxJunk.lua#L1615) |
| `FJ.FlushDeferredJunkDisplayCaches` | [L1616](../../Inventory/Restock/Junk/FluxJunk.lua#L1616) |
| `FJ.RelocateBagJunkCache` | [L1617](../../Inventory/Restock/Junk/FluxJunk.lua#L1617) |
| `FJ.RefreshJunkDisplaySlot` | [L1618](../../Inventory/Restock/Junk/FluxJunk.lua#L1618) |
| `FJ.SetJunkDisplayCacheSlot` | [L1619](../../Inventory/Restock/Junk/FluxJunk.lua#L1619) |
| `FJ.BeginVisualPaint` | [L1620](../../Inventory/Restock/Junk/FluxJunk.lua#L1620) |
| `FJ.EndVisualPaint` | [L1621](../../Inventory/Restock/Junk/FluxJunk.lua#L1621) |
| `FJ.IsVisualPaintActive` | [L1622](../../Inventory/Restock/Junk/FluxJunk.lua#L1622) |
| `FJ.RescanAutoJunkRules` | [L1623](../../Inventory/Restock/Junk/FluxJunk.lua#L1623) |
| `FJ.SyncAutoJunkMarks` | [L1624](../../Inventory/Restock/Junk/FluxJunk.lua#L1624) |
| `FJ.ScheduleAutoJunkSync` | [L1625](../../Inventory/Restock/Junk/FluxJunk.lua#L1625) |
| `FJ.ScheduleJunkTabAuthoritativeRefresh` | [L1627](../../Inventory/Restock/Junk/FluxJunk.lua#L1627) |
| `FJ.PromoteMarkedInferiorToAutoJunk` | [L1657](../../Inventory/Restock/Junk/FluxJunk.lua#L1657) |
| `FJ.PromoteInferiorItemsToAutoJunk` | [L1658](../../Inventory/Restock/Junk/FluxJunk.lua#L1658) |
| `FJ.ReconcileUpgradeInferiorMarks` | [L1659](../../Inventory/Restock/Junk/FluxJunk.lua#L1659) |
| `FJ.EnsureInferiorConsumableMarked` | [L1660](../../Inventory/Restock/Junk/FluxJunk.lua#L1660) |
| `FJ.ScheduleConjureInferiorJunkSync` | [L1662](../../Inventory/Restock/Junk/FluxJunk.lua#L1662) |
| `FJ.AppendTierReferenceRestoreLines` | [L1669](../../Inventory/Restock/Junk/FluxJunk.lua#L1669) |
| `FJ.HasConjureJunkFilterAvailable` | [L1676](../../Inventory/Restock/Junk/FluxJunk.lua#L1676) |
| `FJ.ScanInferiorTierConsumables` | [L1700](../../Inventory/Restock/Junk/FluxJunk.lua#L1700) |
| `FJ.PrintInferiorTierScan` | [L1712](../../Inventory/Restock/Junk/FluxJunk.lua#L1712) |

### Inventory/Restock/Junk/FluxJunkOverlay.lua

Owner: [20-vendor-restock-junk.md](../20-vendor-restock-junk.md).

| Declaration | Source |
|---|---|
| `Overlay.ArePaintTargetsVisible` | [L629](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L629) |
| `Overlay.ScheduleCharacterBagTransferPaint` | [L798](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L798) |
| `Overlay.UpdateAll` | [L910](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L910) |
| `Overlay.UpdateDirtyBags` | [L947](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L947) |
| `Overlay.UpdateAllBank` | [L1276](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1276) |
| `Overlay.ScheduleMainBankGridRefresh` | [L1285](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1285) |
| `Overlay.ApplyBankInternalContext` | [L1311](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1311) |
| `Overlay.ApplyDispatchContext` | [L1334](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1334) |
| `Overlay.ScheduleBankTransferPaint` | [L1410](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1410) |
| `Overlay.ApplyBankOnlyContext` | [L1424](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1424) |
| `Overlay.MarkBankGridDirty` | [L1434](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1434) |
| `Overlay.RepaintInferiorVisuals` | [L1514](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1514) |
| `Overlay.ScheduleInferiorRepaintBurst` | [L1523](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1523) |
| `Overlay.CancelInferiorRepaintBurst` | [L1579](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1579) |
| `Overlay.OnLoginPulseEndSettled` | [L1584](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1584) |
| `Overlay.FlushDeferredPaint` | [L1632](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1632) |
| `Overlay.NotifyBankActivity` | [L1718](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1718) |
| `Overlay.EnsureHooks` | [L1737](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1737) |
| `Overlay.RegisterSlotDecorator` | [L1890](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1890) |
| `Overlay.InvalidateSlotDecorators` | [L1898](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1898) |
| `Overlay.RepaintSlotDecorators` | [L1911](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1911) |
| `Overlay.RefreshProtectionContext` | [L1926](../../Inventory/Restock/Junk/FluxJunkOverlay.lua#L1926) |

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
| `FluxVendorAutoMerchantUI.MarkRestockSettingsDirty` | [L1013](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1013) |
| `FluxVendorAutoMerchantUI.IsRestockDataDirty` | [L1017](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1017) |
| `FluxVendorAutoMerchantUI.MarkJunkStatsDirty` | [L1021](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1021) |
| `FluxVendorAutoMerchantUI.IsJunkStatsDirty` | [L1025](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1025) |
| `FluxVendorAutoMerchantUI.OnJunkListChanged` | [L1533](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1533) |
| `FluxVendorAutoMerchantUI.ScheduleJunkUIRefresh` | [L1558](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L1558) |
| `FluxVendorAutoMerchantUI.HookPanelCloseButton` | [L2258](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2258) |
| `FluxVendorAutoMerchantUI.OnBuyTabHidden` | [L2325](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2325) |
| `FluxVendorAutoMerchantUI.OnBuyTabShown` | [L2331](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2331) |
| `LayoutPostDFActionCluster` | [L2428](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2428) |
| `RefreshCheapJunkSlotCount` | [L2522](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2522) |
| `FluxVendorAutoMerchantUI.GetCachedSellJunkTotal` | [L2538](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2538) |
| `FluxVendorAutoMerchantUI.GetCachedJunkSlotCount` | [L2542](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2542) |
| `FluxVendorAutoMerchantUI.MarkVendorBagPulseDone` | [L2582](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2582) |
| `FluxVendorAutoMerchantUI.IsMerchantBuyTabActive` | [L2586](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2586) |
| `ApplyNativeSellJunkButtonState` | [L2590](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2590) |
| `FluxVendorAutoMerchantUI.GetCachedRestockItems` | [L2618](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2618) |
| `FluxVendorAutoMerchantUI.ApplyClassicSellJunkButtonState` | [L2622](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2622) |
| `FluxVendorAutoMerchantUI.RefreshVendorJunkDisplay` | [L2715](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2715) |
| `FluxVendorAutoMerchantUI.UpdateMerchantUI` | [L2807](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2807) |
| `FluxVendorAutoMerchantUI.NeedsMerchantUIDataRefresh` | [L2881](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L2881) |
| `FluxVendorAutoMerchantUI.IsMerchantUIInitialized` | [L3023](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3023) |
| `FluxVendorAutoMerchantUI.PrewarmForVendorOpen` | [L3027](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3027) |
| `FluxVendorAutoMerchantUI.WarmJunkDisplayCacheIfNeeded` | [L3035](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3035) |
| `FluxVendorAutoMerchantUI.RunPipelineLayoutLight` | [L3094](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3094) |
| `FluxVendorAutoMerchantUI.RunIdleOpenLayout` | [L3126](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3126) |
| `FluxVendorAutoMerchantUI.RunPipelineLayoutStep` | [L3173](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3173) |
| `FluxVendorAutoMerchantUI.OnVendorOpenStormSettled` | [L3243](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3243) |
| `FluxVendorAutoMerchantUI.RunPipelineLayout` | [L3262](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3262) |
| `FluxVendorAutoMerchantUI.ApplyRestockPortraitIcon` | [L3348](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3348) |
| `FluxVendorAutoMerchantUI.ApplyJunkPortraitIcon` | [L3358](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3358) |
| `FluxVendorAutoMerchantUI.CreateRestockStyleButton` | [L3411](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3411) |
| `FluxVendorAutoMerchantUI.SetRestockButtonEnabled` | [L3417](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3417) |
| `FluxVendorAutoMerchantUI.ApplyRestockAutoToggleChrome` | [L3421](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3421) |
| `FluxVendorAutoMerchantUI.CreateRestockAutoToggle` | [L3425](../../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua#L3425) |

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
| `FVID.GetQualityRGB` | [L79](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L79) |
| `FVID.GetDisplayText` | [L105](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L105) |
| `FVID.ApplyNameFontString` | [L131](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L131) |
| `FVID.ShowTooltip` | [L142](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L142) |
| `FVID.IsPreDragonflight` | [L168](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L168) |
| `FVID.ApplyPreDFMerchantSecureTabLayers` | [L172](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L172) |
| `FVID.GetJunkSubTabLayout` | [L206](../../Inventory/Restock/Vendor/FluxVendorItemDisplay.lua#L206) |

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
| `Panel.InvalidateListCache` | [L273](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L273) |
| `Panel.RefreshCountsOnly` | [L277](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L277) |
| `Panel:RefreshList` | [L881](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L881) |
| `Panel:OnTabSelected` | [L956](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L956) |
| `Panel:Init` | [L1233](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1233) |
| `panelFrameendmerchantTab.OnSelect` | [L1257](../../Inventory/Restock/Vendor/FluxVendorRestockPanel.lua#L1257) |

### Inventory/SpellReagents.lua

Owner: [21-inventory-foundation.md](../21-inventory-foundation.md).

| Declaration | Source |
|---|---|
| `Spells.IsBlacklistedReagent` | [L171](../../Inventory/SpellReagents.lua#L171) |
| `Spells.ScheduleReagentWarm` | [L798](../../Inventory/SpellReagents.lua#L798) |
| `Spells.ScheduleWarm` | [L819](../../Inventory/SpellReagents.lua#L819) |
| `Spells.Invalidate` | [L833](../../Inventory/SpellReagents.lua#L833) |
| `Spells.Refresh` | [L841](../../Inventory/SpellReagents.lua#L841) |
| `Spells.AreReagentsWarmed` | [L854](../../Inventory/SpellReagents.lua#L854) |
| `Spells.OnVisibleItemsChanged` | [L867](../../Inventory/SpellReagents.lua#L867) |
| `Spells.UsesReagents` | [L872](../../Inventory/SpellReagents.lua#L872) |
| `Spells.GetReagents` | [L882](../../Inventory/SpellReagents.lua#L882) |
| `Spells.GetReagentItemIDs` | [L888](../../Inventory/SpellReagents.lua#L888) |
| `Spells.GetReagentItemIDSet` | [L900](../../Inventory/SpellReagents.lua#L900) |
| `Spells.IsReagentItem` | [L912](../../Inventory/SpellReagents.lua#L912) |
| `Spells.GetSpellsUsingReagent` | [L989](../../Inventory/SpellReagents.lua#L989) |
| `Spells.GetSpellsUsingReagentLabeled` | [L1013](../../Inventory/SpellReagents.lua#L1013) |

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
| `Adapter.RebuildBags` | [L187](../../Inventory/Syndicator/Adapter.lua#L187) |
| `Adapter.RebuildBank` | [L236](../../Inventory/Syndicator/Adapter.lua#L236) |
| `Adapter.GetLastBagsChangeKind` | [L301](../../Inventory/Syndicator/Adapter.lua#L301) |
| `Adapter.GetLastBagsAddedItemIDs` | [L305](../../Inventory/Syndicator/Adapter.lua#L305) |
| `Adapter.GetLastBagsRemovedItemIDs` | [L309](../../Inventory/Syndicator/Adapter.lua#L309) |
| `Adapter.GetLastBagsDirtyBags` | [L313](../../Inventory/Syndicator/Adapter.lua#L313) |
| `Adapter.GetLastBankChangeKind` | [L317](../../Inventory/Syndicator/Adapter.lua#L317) |
| `Adapter.GetLastBankAddedItemIDs` | [L321](../../Inventory/Syndicator/Adapter.lua#L321) |
| `Adapter.GetLastBankRemovedItemIDs` | [L325](../../Inventory/Syndicator/Adapter.lua#L325) |
| `Adapter.GetLastBankDirtyBags` | [L329](../../Inventory/Syndicator/Adapter.lua#L329) |
| `Adapter.TakeBagsItemSets` | [L333](../../Inventory/Syndicator/Adapter.lua#L333) |
| `Adapter.TakeBankItemSets` | [L337](../../Inventory/Syndicator/Adapter.lua#L337) |
| `Adapter.RebuildWarband` | [L341](../../Inventory/Syndicator/Adapter.lua#L341) |
| `Adapter.RebuildEquip` | [L366](../../Inventory/Syndicator/Adapter.lua#L366) |
| `Adapter.RebuildMail` | [L450](../../Inventory/Syndicator/Adapter.lua#L450) |
| `Adapter.RebuildVoid` | [L460](../../Inventory/Syndicator/Adapter.lua#L460) |
| `Adapter.RebuildAuctions` | [L478](../../Inventory/Syndicator/Adapter.lua#L478) |
| `Adapter.RebuildGuild` | [L486](../../Inventory/Syndicator/Adapter.lua#L486) |
| `Adapter.RebuildCurrencies` | [L508](../../Inventory/Syndicator/Adapter.lua#L508) |
| `Adapter.RebuildWarbandCurrency` | [L533](../../Inventory/Syndicator/Adapter.lua#L533) |
| `Adapter.RebuildAll` | [L544](../../Inventory/Syndicator/Adapter.lua#L544) |
| `Adapter.Start` | [L755](../../Inventory/Syndicator/Adapter.lua#L755) |

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
| `Tooltip.Start` | [L447](../../Inventory/Tooltip.lua#L447) |

### Layout/UnifiedBorder.lua

Owner: [06-layout.md](../06-layout.md).

| Declaration | Source |
|---|---|
| `UnifiedBorder.GamepadStripFrames` | [L171](../../Layout/UnifiedBorder.lua#L171) |
| `UnifiedBorder.UpdateAfterGridLayout` | [L685](../../Layout/UnifiedBorder.lua#L685) |
| `UnifiedBorder.RequestGridLayoutUpdate` | [L715](../../Layout/UnifiedBorder.lua#L715) |
| `UnifiedBorder.GetActionGridBorderTop` | [L1027](../../Layout/UnifiedBorder.lua#L1027) |
| `UnifiedBorder.RefreshGapAppearance` | [L1044](../../Layout/UnifiedBorder.lua#L1044) |

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
| `Mail.TakeRestockItems` | [L164](../../Mail/Restock.lua#L164) |
| `Mail.IsRestockContextOpen` | [L170](../../Mail/Restock.lua#L170) |
| `Mail.CanTakeRestockItems` | [L173](../../Mail/Restock.lua#L173) |
| `Mail.OnJobStateChangedMail.OnJobStateChanged` | [L200](../../Mail/Restock.lua#L200) |

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
| `FluxMicroMenu:FitScreenBorder` | [L1295](../../MicroMenu/FluxMicroMenu.lua#L1295) |
| `_G.FluxMicroMenu_GetBesideChatColumnRightX` | [L1493](../../MicroMenu/FluxMicroMenu.lua#L1493) |
| `FluxMicroMenu:RefreshLayout` | [L2661](../../MicroMenu/FluxMicroMenu.lua#L2661) |
| `FluxMicroMenu:Rebuild` | [L3027](../../MicroMenu/FluxMicroMenu.lua#L3027) |

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
| `FluxMinimap:Initialize` | [L332](../../Minimap/FluxMinimap.lua#L332) |
| `FluxMinimap:RunEnforcerPass` | [L341](../../Minimap/FluxMinimap.lua#L341) |
| `FluxMinimap:RequestEnforcerBurst` | [L349](../../Minimap/FluxMinimap.lua#L349) |
| `FluxMinimap:CancelEnforcerTicker` | [L357](../../Minimap/FluxMinimap.lua#L357) |
| `FluxMinimap:EnsureEnforcerTicker` | [L366](../../Minimap/FluxMinimap.lua#L366) |
| `FluxMinimap.GetEnforcerBurstRemaining` | [L393](../../Minimap/FluxMinimap.lua#L393) |
| `FluxMinimap:Initialize` | [L402](../../Minimap/FluxMinimap.lua#L402) |
| `FluxMinimap_ApplyAppearanceAccent` | [L486](../../Minimap/FluxMinimap.lua#L486) |
| `FluxMinimap:UpdateStyle` | [L506](../../Minimap/FluxMinimap.lua#L506) |
| `FluxMinimap:CleanupBlizzardFrames` | [L568](../../Minimap/FluxMinimap.lua#L568) |
| `FluxMinimap:CleanupTimeManager` | [L654](../../Minimap/FluxMinimap.lua#L654) |
| `FluxMinimap:EnforcePosition` | [L669](../../Minimap/FluxMinimap.lua#L669) |
| `FluxMinimap:PositionIndicators` | [L710](../../Minimap/FluxMinimap.lua#L710) |
| `FluxMinimap:PositionInstanceDifficulty` | [L998](../../Minimap/FluxMinimap.lua#L998) |
| `FluxMinimap:PositionQueueStatusEye` | [L1183](../../Minimap/FluxMinimap.lua#L1183) |
| `FluxMinimap:EnsureQueueStatusEyeHooks` | [L1229](../../Minimap/FluxMinimap.lua#L1229) |
| `FluxMinimap:HookQuestWatchFramePositioning` | [L1311](../../Minimap/FluxMinimap.lua#L1311) |
| `QuestWatchFrame.SetPointQuestWatchFrame.SetPoint` | [L1346](../../Minimap/FluxMinimap.lua#L1346) |
| `WatchFrame.SetPointWatchFrame.SetPoint` | [L1368](../../Minimap/FluxMinimap.lua#L1368) |
| `FluxMinimap:UpdateQuestTrackerPosition` | [L1381](../../Minimap/FluxMinimap.lua#L1381) |
| `FluxMinimap:HandleEditMode` | [L1738](../../Minimap/FluxMinimap.lua#L1738) |
| `FluxMinimap:CreateInfoBar` | [L1882](../../Minimap/FluxMinimap.lua#L1882) |
| `FluxMinimap:ApplyInfoBarZoneTextFit` | [L2072](../../Minimap/FluxMinimap.lua#L2072) |
| `FluxMinimap:OnInfoBarZoneHitEnter` | [L2111](../../Minimap/FluxMinimap.lua#L2111) |
| `FluxMinimap:OnInfoBarZoneHitLeave` | [L2146](../../Minimap/FluxMinimap.lua#L2146) |
| `FluxMinimap:UpdateInfoBarZoneScroll` | [L2163](../../Minimap/FluxMinimap.lua#L2163) |
| `FluxMinimap:RefreshInfoBarZoneFit` | [L2213](../../Minimap/FluxMinimap.lua#L2213) |
| `FluxMinimap:UpdateInfoBarZone` | [L2217](../../Minimap/FluxMinimap.lua#L2217) |
| `FluxMinimap:UpdateInfoBarTime` | [L2254](../../Minimap/FluxMinimap.lua#L2254) |
| `FluxMinimap:EmbedInFrame` | [L2288](../../Minimap/FluxMinimap.lua#L2288) |
| `FluxMinimap:RefreshEmbeddedLayout` | [L2541](../../Minimap/FluxMinimap.lua#L2541) |
| `FluxMinimap:CalculateEmbeddedMapSize` | [L2575](../../Minimap/FluxMinimap.lua#L2575) |
| `FluxMinimap:RestoreToNormal` | [L2582](../../Minimap/FluxMinimap.lua#L2582) |
| `FluxMinimap:IsEmbedded` | [L2723](../../Minimap/FluxMinimap.lua#L2723) |
| `FluxMinimap:GetNormalWidth` | [L2728](../../Minimap/FluxMinimap.lua#L2728) |
| `FluxMinimap:HideEmbedded` | [L2740](../../Minimap/FluxMinimap.lua#L2740) |
| `FluxMinimap:ShowEmbedded` | [L2765](../../Minimap/FluxMinimap.lua#L2765) |
| `FluxMinimap.NotifyInfoFrameLayoutChanged` | [L2787](../../Minimap/FluxMinimap.lua#L2787) |
| `FluxMinimap:Refresh` | [L2800](../../Minimap/FluxMinimap.lua#L2800) |
| `Tracking.IsActive` | [L2902](../../Minimap/FluxMinimap.lua#L2902) |
| `Tracking.SetActive` | [L2908](../../Minimap/FluxMinimap.lua#L2908) |

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
| `M:GetSideWidth` | [L466](../../Minimap/FluxMinimapButtons.lua#L466) |
| `M:GetMinimapOffset` | [L473](../../Minimap/FluxMinimapButtons.lua#L473) |
| `M:GetTrackerOffset` | [L479](../../Minimap/FluxMinimapButtons.lua#L479) |
| `M:GetEmbeddedWidthReserve` | [L487](../../Minimap/FluxMinimapButtons.lua#L487) |
| `M:LayoutSlots` | [L491](../../Minimap/FluxMinimapButtons.lua#L491) |
| `M:UpdateSideBorder` | [L569](../../Minimap/FluxMinimapButtons.lua#L569) |
| `M:RefreshAppearanceAccent` | [L601](../../Minimap/FluxMinimapButtons.lua#L601) |
| `M:Show` | [L675](../../Minimap/FluxMinimapButtons.lua#L675) |
| `M:Hide` | [L682](../../Minimap/FluxMinimapButtons.lua#L682) |
| `M:IsShown` | [L695](../../Minimap/FluxMinimapButtons.lua#L695) |
| `M:PositionInWindow` | [L699](../../Minimap/FluxMinimapButtons.lua#L699) |
| `M:OnEmbedStateChanged` | [L706](../../Minimap/FluxMinimapButtons.lua#L706) |
| `M:RefreshLayout` | [L711](../../Minimap/FluxMinimapButtons.lua#L711) |
| `M:RequestRefresh` | [L738](../../Minimap/FluxMinimapButtons.lua#L738) |
| `M:Initialize` | [L761](../../Minimap/FluxMinimapButtons.lua#L761) |

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
| `Combo.Added` | [L127](../../NamePlates/ComboPoints.lua#L127) |
| `Combo.Removed` | [L128](../../NamePlates/ComboPoints.lua#L128) |
| `Combo.Refresh` | [L131](../../NamePlates/ComboPoints.lua#L131) |
| `Combo.RefreshAll` | [L134](../../NamePlates/ComboPoints.lua#L134) |

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
| `NP.ReleaseHost` | [L246](../../NamePlates/Core.lua#L246) |
| `NP.UsesClassicHealthBar` | [L255](../../NamePlates/Core.lua#L255) |
| `NP.CreateClientPlate` | [L286](../../NamePlates/Core.lua#L286) |
| `NP.FitPlate` | [L301](../../NamePlates/Core.lua#L301) |
| `NP.IsUnitTarget` | [L320](../../NamePlates/Core.lua#L320) |
| `NP.ShowPlate` | [L328](../../NamePlates/Core.lua#L328) |
| `NP.SetThreatTint` | [L352](../../NamePlates/Core.lua#L352) |
| `NP.ThreatTint` | [L365](../../NamePlates/Core.lua#L365) |
| `NP.TintPlateChrome` | [L425](../../NamePlates/Core.lua#L425) |
| `NP.ResetPlateChrome` | [L445](../../NamePlates/Core.lua#L445) |
| `NP.RegisterModule` | [L484](../../NamePlates/Core.lua#L484) |
| `NP.RefreshUnit` | [L564](../../NamePlates/Core.lua#L564) |
| `NP.RefreshAll` | [L572](../../NamePlates/Core.lua#L572) |
| `Quest.Added` | [L982](../../NamePlates/Core.lua#L982) |
| `Quest.Removed` | [L985](../../NamePlates/Core.lua#L985) |
| `Quest.Refresh` | [L989](../../NamePlates/Core.lua#L989) |
| `Quest.RefreshAll` | [L990](../../NamePlates/Core.lua#L990) |
| `Quest.Poll` | [L999](../../NamePlates/Core.lua#L999) |

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
| `Threat.Added` | [L299](../../NamePlates/Threat.lua#L299) |
| `Threat.Removed` | [L303](../../NamePlates/Threat.lua#L303) |
| `Threat.Refresh` | [L316](../../NamePlates/Threat.lua#L316) |
| `Threat.Poll` | [L320](../../NamePlates/Threat.lua#L320) |

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
| `_G.FluxChatFrame_ApplyPrimaryPosition` | [L901](../../Other/FluxChatFrame.lua#L901) |
| `_G.FluxChatFrame_UpdateAfterStripLayout` | [L908](../../Other/FluxChatFrame.lua#L908) |
| `_G.FluxChatFrame_SetDragHold` | [L915](../../Other/FluxChatFrame.lua#L915) |
| `_G.FluxChatFrame_RefreshSocialLayout` | [L1254](../../Other/FluxChatFrame.lua#L1254) |

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
| `SlashCmdList.FLUXCOOLDOWNS` | [L410](../../Other/FluxCooldownDefaults.lua#L410) |

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
| `ns.ApplyHUDTooltipPosition` | [L57](../../Other/FluxHUDTooltip.lua#L57) |
| `ns.SetHUDTooltipOwner` | [L88](../../Other/FluxHUDTooltip.lua#L88) |

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
| `Capture.StopWatch` | [L665](../../Other/FluxPerfCapture.lua#L665) |
| `Capture.WatchStatus` | [L692](../../Other/FluxPerfCapture.lua#L692) |
| `Capture.GetActiveWatchReport` | [L703](../../Other/FluxPerfCapture.lua#L703) |
| `Capture.StartWatch` | [L881](../../Other/FluxPerfCapture.lua#L881) |
| `Capture.PrintSpikes` | [L903](../../Other/FluxPerfCapture.lua#L903) |

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
| `A.OnHiddenGroupBuffsChanged` | [L100](../../RaidFrame/FluxRaidAuras.lua#L100) |
| `A.Setup` | [L530](../../RaidFrame/FluxRaidAuras.lua#L530) |
| `A.Update` | [L780](../../RaidFrame/FluxRaidAuras.lua#L780) |
| `A.UpdateDispel` | [L852](../../RaidFrame/FluxRaidAuras.lua#L852) |
| `A.Refresh` | [L880](../../RaidFrame/FluxRaidAuras.lua#L880) |
| `A.Clear` | [L890](../../RaidFrame/FluxRaidAuras.lua#L890) |
| `A.Diagnostics` | [L899](../../RaidFrame/FluxRaidAuras.lua#L899) |
| `A.DebugDuration` | [L935](../../RaidFrame/FluxRaidAuras.lua#L935) |

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
| `FluxRaidCompat.BuildVisibleGroupsReverse` | [L281](../../RaidFrame/FluxRaidCompat.lua#L281) |
| `FluxRaidCompat.ComputeReverseColumnLayout` | [L294](../../RaidFrame/FluxRaidCompat.lua#L294) |
| `FluxRaidCompat.IsSecret` | [L335](../../RaidFrame/FluxRaidCompat.lua#L335) |
| `FluxRaidCompat.PlainBool` | [L339](../../RaidFrame/FluxRaidCompat.lua#L339) |
| `FluxRaidCompat.HasHealthPercent` | [L343](../../RaidFrame/FluxRaidCompat.lua#L343) |
| `FluxRaidCompat.HasPowerPercent` | [L349](../../RaidFrame/FluxRaidCompat.lua#L349) |
| `FluxRaidCompat.HasPrivateAuraContainer` | [L355](../../RaidFrame/FluxRaidCompat.lua#L355) |
| `FluxRaidCompat.HasRangeAlphaBoolean` | [L363](../../RaidFrame/FluxRaidCompat.lua#L363) |
| `FluxRaidCompat.GetHealthPercent` | [L370](../../RaidFrame/FluxRaidCompat.lua#L370) |
| `FluxRaidCompat.GetPowerPercent` | [L407](../../RaidFrame/FluxRaidCompat.lua#L407) |

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
| `EventHandlers:PARTY_MEMBERS_CHANGED` | [L206](../../RaidFrame/FluxRaidFrame.lua#L206) |
| `EventHandlers:CVAR_UPDATE` | [L212](../../RaidFrame/FluxRaidFrame.lua#L212) |
| `EventHandlers:PLAYER_ENTERING_WORLD` | [L216](../../RaidFrame/FluxRaidFrame.lua#L216) |
| `EventHandlers:PLAYER_REGEN_ENABLED` | [L223](../../RaidFrame/FluxRaidFrame.lua#L223) |
| `EventHandlers:PLAYER_REGEN_DISABLED` | [L234](../../RaidFrame/FluxRaidFrame.lua#L234) |
| `EventHandlers:SPELLS_CHANGED` | [L242](../../RaidFrame/FluxRaidFrame.lua#L242) |
| `EventHandlers:HIDDEN_GROUP_BUFFS_CHANGED` | [L250](../../RaidFrame/FluxRaidFrame.lua#L250) |
| `EventHandlers:PET_BATTLE_CLOSE` | [L262](../../RaidFrame/FluxRaidFrame.lua#L262) |
| `EventHandlers:COMPACT_UNIT_FRAME_PROFILES_LOADED` | [L266](../../RaidFrame/FluxRaidFrame.lua#L266) |
| `EventHandlers:DISPLAY_SIZE_CHANGED` | [L272](../../RaidFrame/FluxRaidFrame.lua#L272) |
| `EventHandlers:UI_SCALE_CHANGED` | [L278](../../RaidFrame/FluxRaidFrame.lua#L278) |
| `EventHandlers:PLAYER_TARGET_CHANGED` | [L284](../../RaidFrame/FluxRaidFrame.lua#L284) |
| `EventHandlers:PLAYER_ROLES_ASSIGNED` | [L290](../../RaidFrame/FluxRaidFrame.lua#L290) |
| `EventHandlers:READY_CHECK` | [L296](../../RaidFrame/FluxRaidFrame.lua#L296) |
| `EventHandlers:READY_CHECK_CONFIRM` | [L302](../../RaidFrame/FluxRaidFrame.lua#L302) |
| `EventHandlers:READY_CHECK_FINISHED` | [L308](../../RaidFrame/FluxRaidFrame.lua#L308) |
| `EventHandlers:RAID_TARGET_UPDATE` | [L314](../../RaidFrame/FluxRaidFrame.lua#L314) |
| `FluxRaid_OnLoad` | [L323](../../RaidFrame/FluxRaidFrame.lua#L323) |
| `FluxRaid_OnEvent` | [L377](../../RaidFrame/FluxRaidFrame.lua#L377) |

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
| `E.RefreshLayout` | [L367](../../RaidFrame/FluxRaidHealerExtras.lua#L367) |
| `E.RefreshRoster` | [L383](../../RaidFrame/FluxRaidHealerExtras.lua#L383) |
| `E.OnEvent` | [L405](../../RaidFrame/FluxRaidHealerExtras.lua#L405) |
| `endendE.GetExtraCells` | [L428](../../RaidFrame/FluxRaidHealerExtras.lua#L428) |

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
| `FluxRaid_GetMTMARosterCount` | [L181](../../RaidFrame/FluxRaidLayout.lua#L181) |
| `FluxRaid_GetPreviewStackVerticalPosition` | [L325](../../RaidFrame/FluxRaidLayout.lua#L325) |
| `FluxRaidFrame_UpdatePosition` | [L330](../../RaidFrame/FluxRaidLayout.lua#L330) |
| `FluxRaid_ComputeSyntheticGroup2ColumnLeftX` | [L348](../../RaidFrame/FluxRaidLayout.lua#L348) |
| `FluxRaid_GetPlacement2FocusAnchorBottomRight` | [L376](../../RaidFrame/FluxRaidLayout.lua#L376) |
| `FluxRaid_GetFirstGroupNthMemberBottomFromScreen` | [L816](../../RaidFrame/FluxRaidLayout.lua#L816) |
| `FluxRaid_QueueReadinessRetry` | [L941](../../RaidFrame/FluxRaidLayout.lua#L941) |
| `FluxRaid_QueueConfigureAndRefresh` | [L946](../../RaidFrame/FluxRaidLayout.lua#L946) |
| `FluxRaid_InstallManagerHooks` | [L1168](../../RaidFrame/FluxRaidLayout.lua#L1168) |
| `FluxRaid_ScheduleBlizzardGridHideCheck` | [L1190](../../RaidFrame/FluxRaidLayout.lua#L1190) |
| `FluxRaid_ApplyBlizzardCompactGridHidden` | [L1203](../../RaidFrame/FluxRaidLayout.lua#L1203) |
| `FluxRaid_RestoreBlizzardRaidFrames` | [L1231](../../RaidFrame/FluxRaidLayout.lua#L1231) |
| `FluxRaid_RunPendingCombatWork` | [L1254](../../RaidFrame/FluxRaidLayout.lua#L1254) |
| `FluxRaid_OnRosterOrPartyChanged` | [L1295](../../RaidFrame/FluxRaidLayout.lua#L1295) |
| `FluxRaid_InitLayoutFrames` | [L1320](../../RaidFrame/FluxRaidLayout.lua#L1320) |
| `FluxRaid_InstallPetBattleDriver` | [L1354](../../RaidFrame/FluxRaidLayout.lua#L1354) |
| `FluxRaid_DisableBlizzardNow` | [L1402](../../RaidFrame/FluxRaidLayout.lua#L1402) |
| `FluxRaid_PositionContainer` | [L1406](../../RaidFrame/FluxRaidLayout.lua#L1406) |

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
| `Secure.ConfigurePartyFrames` | [L423](../../RaidFrame/FluxRaidSecure.lua#L423) |
| `Secure.DisablePartyFrames` | [L469](../../RaidFrame/FluxRaidSecure.lua#L469) |
| `Secure.GetPartyStates` | [L489](../../RaidFrame/FluxRaidSecure.lua#L489) |
| `Secure.AttachHeaderChild` | [L500](../../RaidFrame/FluxRaidSecure.lua#L500) |
| `Secure.RefreshRosterLayout` | [L529](../../RaidFrame/FluxRaidSecure.lua#L529) |

### RaidFrame/FluxRaidUnit.lua

Owner: [15-raid-frames.md](../15-raid-frames.md).

| Declaration | Source |
|---|---|
| `FluxRaid_RefreshJoinedBorders` | [L195](../../RaidFrame/FluxRaidUnit.lua#L195) |
| `FluxRaid_RequestJoinedBorderRefresh` | [L258](../../RaidFrame/FluxRaidUnit.lua#L258) |
| `FluxRaid_ShouldShowPowerBar` | [L272](../../RaidFrame/FluxRaidUnit.lua#L272) |
| `FluxRaid_UpdateHealth` | [L342](../../RaidFrame/FluxRaidUnit.lua#L342) |
| `FluxRaid_UpdatePower` | [L364](../../RaidFrame/FluxRaidUnit.lua#L364) |
| `FluxRaid_UpdateHealPrediction` | [L409](../../RaidFrame/FluxRaidUnit.lua#L409) |
| `FluxRaid_UpdateName` | [L421](../../RaidFrame/FluxRaidUnit.lua#L421) |
| `FluxRaid_UpdateStatusText` | [L459](../../RaidFrame/FluxRaidUnit.lua#L459) |
| `FluxRaid_UpdateSelectionHighlight` | [L516](../../RaidFrame/FluxRaidUnit.lua#L516) |
| `FluxRaid_UpdateAggroHighlight` | [L533](../../RaidFrame/FluxRaidUnit.lua#L533) |
| `FluxRaid_UpdateRoleIcon` | [L577](../../RaidFrame/FluxRaidUnit.lua#L577) |
| `FluxRaid_UpdateCenterStatus` | [L629](../../RaidFrame/FluxRaidUnit.lua#L629) |
| `FluxRaid_UpdateReadyCheck` | [L683](../../RaidFrame/FluxRaidUnit.lua#L683) |
| `FluxRaid_UpdateRange` | [L709](../../RaidFrame/FluxRaidUnit.lua#L709) |
| `FluxRaid_UpdateAuras` | [L716](../../RaidFrame/FluxRaidUnit.lua#L716) |
| `FluxRaid_UpdateDispelHighlight` | [L723](../../RaidFrame/FluxRaidUnit.lua#L723) |
| `FluxRaid_PaintUnit` | [L727](../../RaidFrame/FluxRaidUnit.lua#L727) |
| `ns.FluxRaidQueueMissingBuffRefresh` | [L903](../../RaidFrame/FluxRaidUnit.lua#L903) |
| `ns.FluxRaidQueueRosterPaint` | [L909](../../RaidFrame/FluxRaidUnit.lua#L909) |
| `FluxRaid_BindUnit` | [L958](../../RaidFrame/FluxRaidUnit.lua#L958) |
| `FluxRaid_OnUnitAttributeChanged` | [L997](../../RaidFrame/FluxRaidUnit.lua#L997) |
| `FluxRaidUnit_OnLoad` | [L1008](../../RaidFrame/FluxRaidUnit.lua#L1008) |
| `FluxRaidUnit_OnShow` | [L1054](../../RaidFrame/FluxRaidUnit.lua#L1054) |
| `FluxRaidUnit_OnHide` | [L1068](../../RaidFrame/FluxRaidUnit.lua#L1068) |
| `FluxRaidUnit_OnEnter` | [L1120](../../RaidFrame/FluxRaidUnit.lua#L1120) |
| `FluxRaidUnit_OnLeave` | [L1128](../../RaidFrame/FluxRaidUnit.lua#L1128) |
| `ns.FluxRaidRegisterAllMouseoverKeybindFrames` | [L1135](../../RaidFrame/FluxRaidUnit.lua#L1135) |
| `FluxRaid_ForEachHeaderChild` | [L1154](../../RaidFrame/FluxRaidUnit.lua#L1154) |
| `FluxRaid_SyncHeaderChildUnits` | [L1185](../../RaidFrame/FluxRaidUnit.lua#L1185) |
| `FluxRaid_ApplyChromeToChildren` | [L1198](../../RaidFrame/FluxRaidUnit.lua#L1198) |
| `FluxRaid_SyncAllFluxUnitAuraSettings` | [L1222](../../RaidFrame/FluxRaidUnit.lua#L1222) |
| `FluxRaid_RefreshVisibleUnits` | [L1230](../../RaidFrame/FluxRaidUnit.lua#L1230) |
| `FluxRaid_RefreshSelfDisplayNames` | [L1253](../../RaidFrame/FluxRaidUnit.lua#L1253) |
| `FluxRaid_EnsureRangePoll` | [L1311](../../RaidFrame/FluxRaidUnit.lua#L1311) |
| `FluxRaid_IsMTMAChild` | [L1320](../../RaidFrame/FluxRaidUnit.lua#L1320) |
| `FluxCompactMiniFrameSetup` | [L1357](../../RaidFrame/FluxRaidUnit.lua#L1357) |
| `FluxRaid_AttachOrUpdateMTMATarget` | [L1425](../../RaidFrame/FluxRaidUnit.lua#L1425) |
| `FluxRaid_RefreshMTMATargetAttachments` | [L1467](../../RaidFrame/FluxRaidUnit.lua#L1467) |
| `FluxCompactMiniFrameSetup_G.FluxCompactUnitFrameSetup` | [L1483](../../RaidFrame/FluxRaidUnit.lua#L1483) |

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
| `FluxRaidVisuals.ApplyCellChrome` | [L1281](../../RaidFrame/FluxRaidVisuals.lua#L1281) |
| `FluxRaidVisuals.ApplyVisuals` | [L1460](../../RaidFrame/FluxRaidVisuals.lua#L1460) |
| `FluxRaidVisuals.SetupHealAbsorbLayers` | [L1465](../../RaidFrame/FluxRaidVisuals.lua#L1465) |
| `FluxRaidVisuals.SetupReadyCheckIcon` | [L1468](../../RaidFrame/FluxRaidVisuals.lua#L1468) |
| `FluxRaidVisuals.RefreshNeutralBarTracks` | [L1471](../../RaidFrame/FluxRaidVisuals.lua#L1471) |

### Respec/FluxRespec_ActionBars.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `ActionBars.CollectSlots` | [L52](../../Respec/FluxRespec_ActionBars.lua#L52) |
| `ActionBars.RewriteStanceSpellId` | [L279](../../Respec/FluxRespec_ActionBars.lua#L279) |
| `ActionBars.RewriteSavedStanceSpellId` | [L351](../../Respec/FluxRespec_ActionBars.lua#L351) |
| `ActionBars.CaptureStanceLayout` | [L381](../../Respec/FluxRespec_ActionBars.lua#L381) |
| `ActionBars.ApplyStanceLayout` | [L403](../../Respec/FluxRespec_ActionBars.lua#L403) |
| `ActionBars.Capture` | [L448](../../Respec/FluxRespec_ActionBars.lua#L448) |
| `ActionBars.CancelPendingApply` | [L754](../../Respec/FluxRespec_ActionBars.lua#L754) |
| `ActionBars.Apply` | [L801](../../Respec/FluxRespec_ActionBars.lua#L801) |
| `ActionBars.MatchesSnapshot` | [L841](../../Respec/FluxRespec_ActionBars.lua#L841) |
| `ActionBars.FilledCount` | [L870](../../Respec/FluxRespec_ActionBars.lua#L870) |

### Respec/FluxRespec_Apply.lua

Owner: [23-respec.md](../23-respec.md).

| Declaration | Source |
|---|---|
| `Apply.IsRunning` | [L153](../../Respec/FluxRespec_Apply.lua#L153) |
| `Apply.IsWaitingForRuneEngrave` | [L157](../../Respec/FluxRespec_Apply.lua#L157) |
| `Apply.IsEngraveButtonMode` | [L163](../../Respec/FluxRespec_Apply.lua#L163) |
| `Apply.WillSwitchSpec` | [L173](../../Respec/FluxRespec_Apply.lua#L173) |
| `Apply.Cancel` | [L178](../../Respec/FluxRespec_Apply.lua#L178) |
| `Apply.IsProfileFullyApplied` | [L318](../../Respec/FluxRespec_Apply.lua#L318) |
| `Apply.NextStepLabel` | [L390](../../Respec/FluxRespec_Apply.lua#L390) |
| `Apply.Run` | [L941](../../Respec/FluxRespec_Apply.lua#L941) |

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
| `R.LoadProfile` | [L466](../../Respec/FluxRespec_Core.lua#L466) |
| `R.ApplyInfoFrameForProfile` | [L475](../../Respec/FluxRespec_Core.lua#L475) |
| `R.ClearUnitFrameRespecArmed` | [L492](../../Respec/FluxRespec_Core.lua#L492) |
| `R.SetUnitFrameRespecArmed` | [L496](../../Respec/FluxRespec_Core.lua#L496) |
| `R.IsUnitFrameRespecArmedForActiveProfile` | [L506](../../Respec/FluxRespec_Core.lua#L506) |
| `R.SelectActiveProfileOnly` | [L514](../../Respec/FluxRespec_Core.lua#L514) |
| `R.RunLoadProfileButtonAction` | [L540](../../Respec/FluxRespec_Core.lua#L540) |
| `R.ActiveProfileGearMatches` | [L566](../../Respec/FluxRespec_Core.lua#L566) |
| `R.ActiveProfileBuildMatches` | [L618](../../Respec/FluxRespec_Core.lua#L618) |
| `R.GetActiveProfileBuildIcon` | [L633](../../Respec/FluxRespec_Core.lua#L633) |
| `R.SetLoadCheckpoint` | [L652](../../Respec/FluxRespec_Core.lua#L652) |
| `R.ClearLoadCheckpoint` | [L658](../../Respec/FluxRespec_Core.lua#L658) |
| `R.GetLoadCheckpoint` | [L664](../../Respec/FluxRespec_Core.lua#L664) |
| `R.RefreshPlayerSpecIconDecor` | [L674](../../Respec/FluxRespec_Core.lua#L674) |
| `endend_G.FluxRespec_GetPlayerSpecIconOverride` | [L794](../../Respec/FluxRespec_Core.lua#L794) |

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
| `GearSetLock.NotifyBlocked` | [L102](../../Respec/FluxRespec_GearSetLock.lua#L102) |
| `GearSetLock.IsMerchantSellContext` | [L108](../../Respec/FluxRespec_GearSetLock.lua#L108) |
| `GearSetLock.IsSalvageDisenchantHoverContext` | [L189](../../Respec/FluxRespec_GearSetLock.lua#L189) |
| `GearSetLock.IsManualDisenchantTargeting` | [L205](../../Respec/FluxRespec_GearSetLock.lua#L205) |
| `GearSetLock.IsDisenchantContext` | [L224](../../Respec/FluxRespec_GearSetLock.lua#L224) |
| `GearSetLock.ShouldBlockContainerUse` | [L231](../../Respec/FluxRespec_GearSetLock.lua#L231) |
| `GearSetLock.ShouldBlockContainerPickup` | [L238](../../Respec/FluxRespec_GearSetLock.lua#L238) |
| `thenifguard.ShouldButtonPassThroughthenguard.ShouldButtonPassThrough` | [L324](../../Respec/FluxRespec_GearSetLock.lua#L324) |
| `GearSetLock.HideItemButtonClickGuard` | [L342](../../Respec/FluxRespec_GearSetLock.lua#L342) |
| `GearSetLock.UpdateItemButtonClickGuard` | [L349](../../Respec/FluxRespec_GearSetLock.lua#L349) |
| `GearSetLock.ResolveBagSlotFromOwner` | [L404](../../Respec/FluxRespec_GearSetLock.lua#L404) |
| `GearSetLock.ResolveBagSlotFromTooltip` | [L427](../../Respec/FluxRespec_GearSetLock.lua#L427) |
| `GearSetLock.Rebuild` | [L525](../../Respec/FluxRespec_GearSetLock.lua#L525) |
| `GearSetLock.WithContextSnapshot` | [L597](../../Respec/FluxRespec_GearSetLock.lua#L597) |
| `GearSetLock.ShouldShowManualInventoryClickGuard` | [L653](../../Respec/FluxRespec_GearSetLock.lua#L653) |
| `GearSetLock.GetManualInventoryClickGuardMode` | [L663](../../Respec/FluxRespec_GearSetLock.lua#L663) |
| `GearSetLock.ShouldShowManualClickGuard` | [L667](../../Respec/FluxRespec_GearSetLock.lua#L667) |
| `GearSetLock.IsShieldContextActive` | [L690](../../Respec/FluxRespec_GearSetLock.lua#L690) |
| `GearSetLock.ShouldShowShieldVisual` | [L697](../../Respec/FluxRespec_GearSetLock.lua#L697) |
| `GearSetLock.GetManualClickGuardModeForSlot` | [L701](../../Respec/FluxRespec_GearSetLock.lua#L701) |
| `GearSetLock.GetManualClickGuardMode` | [L725](../../Respec/FluxRespec_GearSetLock.lua#L725) |

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
| `Bundle.ApplyBarsForActiveGroup` | [L271](../../Respec/FluxRespec_PresetBundle.lua#L271) |
| `Bundle.HasBarsForActiveGroup` | [L279](../../Respec/FluxRespec_PresetBundle.lua#L279) |
| `Bundle.SaveSpellBookForActiveGroup` | [L286](../../Respec/FluxRespec_PresetBundle.lua#L286) |
| `Bundle.ApplySpellBookForActiveGroup` | [L298](../../Respec/FluxRespec_PresetBundle.lua#L298) |
| `Bundle.HasSpellBookForActiveGroup` | [L307](../../Respec/FluxRespec_PresetBundle.lua#L307) |
| `Bundle.SaveSuffixForActiveGroup` | [L315](../../Respec/FluxRespec_PresetBundle.lua#L315) |

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
| `_GetTooltipMeasureFS` | [L3009](../../StatusBars/FluxInfoFrame.lua#L3009) |
| `_MeasureTooltipTextWidth` | [L3021](../../StatusBars/FluxInfoFrame.lua#L3021) |
| `_SplitMergedSegments` | [L3032](../../StatusBars/FluxInfoFrame.lua#L3032) |
| `_BuildTooltipLabelKeyMap` | [L3052](../../StatusBars/FluxInfoFrame.lua#L3052) |
| `_StripTooltipCodes` | [L3080](../../StatusBars/FluxInfoFrame.lua#L3080) |
| `_InferKeyFromSegmentText` | [L3085](../../StatusBars/FluxInfoFrame.lua#L3085) |
| `_ResolveTooltipKeysForEntry` | [L3098](../../StatusBars/FluxInfoFrame.lua#L3098) |
| `_BuildSegmentSpansForEntry` | [L3124](../../StatusBars/FluxInfoFrame.lua#L3124) |
| `_GetHoveredKeyFromEntryFS` | [L3238](../../StatusBars/FluxInfoFrame.lua#L3238) |
| `_PositionFluxInfoTooltipAnchor` | [L3360](../../StatusBars/FluxInfoFrame.lua#L3360) |
| `gt.SetOwnergt.SetOwner` | [L3412](../../StatusBars/FluxInfoFrame.lua#L3412) |
| `_InvalidateTooltipStatFrameCache` | [L3456](../../StatusBars/FluxInfoFrame.lua#L3456) |
| `_G.FluxAutoRepairEnabled` | [L3460](../../StatusBars/FluxInfoFrame.lua#L3460) |
| `_G.FluxToggleAutoRepair` | [L3469](../../StatusBars/FluxInfoFrame.lua#L3469) |
| `_SetDurabilityRepairTooltip` | [L3485](../../StatusBars/FluxInfoFrame.lua#L3485) |
| `_SetCompactPairTooltip` | [L3553](../../StatusBars/FluxInfoFrame.lua#L3553) |
| `_SetEquipmentRatingTooltip` | [L3563](../../StatusBars/FluxInfoFrame.lua#L3563) |
| `_GetCompactInfoPairValues` | [L3581](../../StatusBars/FluxInfoFrame.lua#L3581) |
| `_GetTooltipSourceStatFrames` | [L3602](../../StatusBars/FluxInfoFrame.lua#L3602) |
| `_GetTooltipSourceStatFrame` | [L3630](../../StatusBars/FluxInfoFrame.lua#L3630) |
| `InfoFrame._CharacterPanelStatNumber` | [L3636](../../StatusBars/FluxInfoFrame.lua#L3636) |
| `InfoFrame._ShowCamelotSpellPinTooltip` | [L3657](../../StatusBars/FluxInfoFrame.lua#L3657) |
| `_ShowInfoTooltipForKey` | [L3747](../../StatusBars/FluxInfoFrame.lua#L3747) |
| `InfoFrame.StatLabel` | [L3967](../../StatusBars/FluxInfoFrame.lua#L3967) |
| `InfoFrame._CollectVisibleStatKeys` | [L3999](../../StatusBars/FluxInfoFrame.lua#L3999) |
| `InfoFrame._NormalizeStatOrder` | [L4054](../../StatusBars/FluxInfoFrame.lua#L4054) |
| `InfoFrame.HasVisibleLines` | [L4090](../../StatusBars/FluxInfoFrame.lua#L4090) |
| `InfoFrame.GetOrderedVisibleStats` | [L4106](../../StatusBars/FluxInfoFrame.lua#L4106) |
| `InfoFrame.SetStatOrder` | [L4131](../../StatusBars/FluxInfoFrame.lua#L4131) |
| `InfoFrame._FlushPlayerStatRefresh` | [L4374](../../StatusBars/FluxInfoFrame.lua#L4374) |
| `InfoFrame.RequestStatRefresh` | [L4381](../../StatusBars/FluxInfoFrame.lua#L4381) |
| `InfoFrame.PrepareIntegratedStripLayout` | [L4437](../../StatusBars/FluxInfoFrame.lua#L4437) |
| `InfoFrame._AnchorActionStripSlot` | [L4464](../../StatusBars/FluxInfoFrame.lua#L4464) |
| `InfoFrame.PositionActionStripSlotFrame` | [L4590](../../StatusBars/FluxInfoFrame.lua#L4590) |
| `InfoFrame._LayoutScreenTopLeft` | [L4659](../../StatusBars/FluxInfoFrame.lua#L4659) |
| `InfoFrame.GetFrame` | [L5246](../../StatusBars/FluxInfoFrame.lua#L5246) |
| `InfoFrame.GetStableIntegratedColumnWidth` | [L5251](../../StatusBars/FluxInfoFrame.lua#L5251) |
| `InfoFrame.UpdateAfterStripLayout` | [L5262](../../StatusBars/FluxInfoFrame.lua#L5262) |
| `InfoFrame.ForceUpdatePosition` | [L5276](../../StatusBars/FluxInfoFrame.lua#L5276) |
| `InfoFrame.ForceRebuild` | [L5297](../../StatusBars/FluxInfoFrame.lua#L5297) |
| `InfoFrame.TogglePinnedStat` | [L5320](../../StatusBars/FluxInfoFrame.lua#L5320) |
| `InfoFrame.IsStatPinned` | [L5396](../../StatusBars/FluxInfoFrame.lua#L5396) |
| `_RebuildTooltipStatFrameCache` | [L6075](../../StatusBars/FluxInfoFrame.lua#L6075) |
| `InfoFrame.ResolveStatFramesForTooltip` | [L6143](../../StatusBars/FluxInfoFrame.lua#L6143) |
| `InfoFrame.RefreshAllPinIndicators` | [L6189](../../StatusBars/FluxInfoFrame.lua#L6189) |
| `InfoFrame.ApplyRespecProfileSnapshot` | [L6194](../../StatusBars/FluxInfoFrame.lua#L6194) |
| `InfoFrame.HookClassicCSCStatFrame` | [L6238](../../StatusBars/FluxInfoFrame.lua#L6238) |
| `InfoFrame.HookRetailPaperDollStatFrame` | [L6247](../../StatusBars/FluxInfoFrame.lua#L6247) |
| `InfoFrame.HookRetailPaperDollPoolStatFrame` | [L6258](../../StatusBars/FluxInfoFrame.lua#L6258) |
| `InfoFrame.ReadForeverDisplayText` | [L6271](../../StatusBars/FluxInfoFrame.lua#L6271) |
| `InfoFrame.RememberPinnedStatValue` | [L6322](../../StatusBars/FluxInfoFrame.lua#L6322) |
| `InfoFrame.HookForeverScrollBoxStatFrame` | [L6366](../../StatusBars/FluxInfoFrame.lua#L6366) |
| `InfoFrame.InstallRetailPaperDollHooks` | [L6394](../../StatusBars/FluxInfoFrame.lua#L6394) |
| `InfoFrame.AfterCharacterShown` | [L6400](../../StatusBars/FluxInfoFrame.lua#L6400) |
| `InfoFrame._StartCamelotCharacterWatch` | [L6408](../../StatusBars/FluxInfoFrame.lua#L6408) |
| `InfoFrame.InstallCharacterInfoPinHooks` | [L6440](../../StatusBars/FluxInfoFrame.lua#L6440) |

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
| `UpdateExpBar` | [L1766](../../StatusBars/FluxStatusBar.lua#L1766) |
| `UpdateFluxDurabilityFramePosition` | [L2310](../../StatusBars/FluxStatusBar.lua#L2310) |
| `_G.FluxStatusBar_GetLocation2MinBottomOffset` | [L2406](../../StatusBars/FluxStatusBar.lua#L2406) |
| `_G.FluxStatusBar_GetBottomOverlayHeight` | [L2427](../../StatusBars/FluxStatusBar.lua#L2427) |
| `_G.FluxStatusBar_GetBottomOverlayHeightForAlignedChrome` | [L2446](../../StatusBars/FluxStatusBar.lua#L2446) |
| `UpdateLayout` | [L2637](../../StatusBars/FluxStatusBar.lua#L2637) |
| `endend_G.FluxStatusBarUpdateLayout` | [L3098](../../StatusBars/FluxStatusBar.lua#L3098) |

### UnitFrames/FluxCastBar.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `CB.StopCustomTimer` | [L1847](../../UnitFrames/FluxCastBar.lua#L1847) |
| `CB.StartCustomTimer` | [L1853](../../UnitFrames/FluxCastBar.lua#L1853) |
| `CB.ResetCastForUnit` | [L2280](../../UnitFrames/FluxCastBar.lua#L2280) |
| `CB.RefreshCastForUnit` | [L2294](../../UnitFrames/FluxCastBar.lua#L2294) |
| `CB.CreateCastBar` | [L2798](../../UnitFrames/FluxCastBar.lua#L2798) |
| `castBar.SetValue` | [L2833](../../UnitFrames/FluxCastBar.lua#L2833) |
| `endcastBar.GetValue` | [L2834](../../UnitFrames/FluxCastBar.lua#L2834) |
| `castBar.SetMinMaxValues` | [L2836](../../UnitFrames/FluxCastBar.lua#L2836) |
| `endcastBar.GetMinMaxValues` | [L2840](../../UnitFrames/FluxCastBar.lua#L2840) |
| `endcastBar.SetStatusBarColor` | [L2841](../../UnitFrames/FluxCastBar.lua#L2841) |
| `endcastBar.SetStatusBarTexture` | [L2842](../../UnitFrames/FluxCastBar.lua#L2842) |
| `endcastBar.GetStatusBarTexture` | [L2843](../../UnitFrames/FluxCastBar.lua#L2843) |
| `endiftimerBar.SetTimerDurationthencastBar.SetTimerDuration` | [L2869](../../UnitFrames/FluxCastBar.lua#L2869) |
| `endendiftimerBar.GetTimerDurationthencastBar.GetTimerDuration` | [L2875](../../UnitFrames/FluxCastBar.lua#L2875) |
| `RegisterUnitCastEventscastBar.DisablePetCastBar` | [L3052](../../UnitFrames/FluxCastBar.lua#L3052) |
| `endendcastBar.UpdateLayout` | [L3275](../../UnitFrames/FluxCastBar.lua#L3275) |
| `CB.SyncBlizzardCastBars` | [L3668](../../UnitFrames/FluxCastBar.lua#L3668) |
| `FluxCastBar_ApplyAppearanceAccent` | [L3699](../../UnitFrames/FluxCastBar.lua#L3699) |

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
| `FX.Reset` | [L570](../../UnitFrames/FluxCastBarThemes.lua#L570) |
| `FX.Update` | [L705](../../UnitFrames/FluxCastBarThemes.lua#L705) |
| `FX.Apply` | [L780](../../UnitFrames/FluxCastBarThemes.lua#L780) |
| `FX.Begin` | [L817](../../UnitFrames/FluxCastBarThemes.lua#L817) |
| `FX.BeginMask` | [L830](../../UnitFrames/FluxCastBarThemes.lua#L830) |
| `FX.Finish` | [L840](../../UnitFrames/FluxCastBarThemes.lua#L840) |
| `FX.Attach` | [L864](../../UnitFrames/FluxCastBarThemes.lua#L864) |
| `FX.Refresh` | [L872](../../UnitFrames/FluxCastBarThemes.lua#L872) |
| `FX.ObserveCast` | [L883](../../UnitFrames/FluxCastBarThemes.lua#L883) |
| `FX.SyncEvents` | [L951](../../UnitFrames/FluxCastBarThemes.lua#L951) |

### UnitFrames/FluxCastBarTradeskills.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `Trades.Resolve` | [L23](../../UnitFrames/FluxCastBarTradeskills.lua#L23) |
| `Trades.Reset` | [L61](../../UnitFrames/FluxCastBarTradeskills.lua#L61) |
| `Trades.Layout` | [L71](../../UnitFrames/FluxCastBarTradeskills.lua#L71) |
| `Trades.Apply` | [L132](../../UnitFrames/FluxCastBarTradeskills.lua#L132) |
| `Trades.Finish` | [L178](../../UnitFrames/FluxCastBarTradeskills.lua#L178) |

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
| `HLO.CanKeepVerticalRosterSample` | [L355](../../UnitFrames/FluxHealthLossOverlay.lua#L355) |
| `HLO.OnBeforeHealthValueSet` | [L384](../../UnitFrames/FluxHealthLossOverlay.lua#L384) |
| `HLO.OnAfterHealthValueSet` | [L391](../../UnitFrames/FluxHealthLossOverlay.lua#L391) |
| `HLO.Initialize` | [L483](../../UnitFrames/FluxHealthLossOverlay.lua#L483) |

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
| `ST._ResumeHeaderLayout` | [L159](../../UnitFrames/FluxSwingTimer.lua#L159) |
| `ST._DeferHeaderLayout` | [L163](../../UnitFrames/FluxSwingTimer.lua#L163) |
| `ST.HideForCastBarClaim` | [L1305](../../UnitFrames/FluxSwingTimer.lua#L1305) |
| `ST.OnCastBarSlotReleased` | [L1310](../../UnitFrames/FluxSwingTimer.lua#L1310) |
| `FluxSwingTimer_IsCleuRegistered` | [L1965](../../UnitFrames/FluxSwingTimer.lua#L1965) |
| `ST._ResumeHeaderAttach` | [L2547](../../UnitFrames/FluxSwingTimer.lua#L2547) |
| `ST.AttachToCastBar` | [L2552](../../UnitFrames/FluxSwingTimer.lua#L2552) |
| `ST.SetPlayerSwingTimerEnabled` | [L2690](../../UnitFrames/FluxSwingTimer.lua#L2690) |

### UnitFrames/FluxUnitFrames_Auras.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.GetAuraPackingWidth` | [L221](../../UnitFrames/FluxUnitFrames_Auras.lua#L221) |
| `button.GetFilter` | [L883](../../UnitFrames/FluxUnitFrames_Auras.lua#L883) |
| `UF.GetAuraContentOffsets` | [L1484](../../UnitFrames/FluxUnitFrames_Auras.lua#L1484) |
| `UF.UpdateAuraPosition` | [L1622](../../UnitFrames/FluxUnitFrames_Auras.lua#L1622) |
| `_G.FluxUnitFrames_UpdateFocusAuraLayoutForRaidStack` | [L1666](../../UnitFrames/FluxUnitFrames_Auras.lua#L1666) |
| `UF.ApplyAuraOptionsToFrame` | [L2090](../../UnitFrames/FluxUnitFrames_Auras.lua#L2090) |
| `UF.EnableAuras` | [L2115](../../UnitFrames/FluxUnitFrames_Auras.lua#L2115) |
| `UF.DisableAuras` | [L2401](../../UnitFrames/FluxUnitFrames_Auras.lua#L2401) |
| `UF.UpdateAuras` | [L2406](../../UnitFrames/FluxUnitFrames_Auras.lua#L2406) |
| `UF.CleanupAuras` | [L2415](../../UnitFrames/FluxUnitFrames_Auras.lua#L2415) |

### UnitFrames/FluxUnitFrames_AurasEngine.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.UseEngineAuras` | [L36](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L36) |
| `UF.ContainerUsesEngine` | [L48](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L48) |
| `UF.FrameUsesEngineAuras` | [L52](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L52) |
| `UF.PokeEngineAuras` | [L436](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L436) |
| `UF.SyncEngineAuras` | [L450](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L450) |
| `UF.AttachEngineAuras` | [L511](../../UnitFrames/FluxUnitFrames_AurasEngine.lua#L511) |

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
| `UF.PreviewDebuffTint` | [L287](../../UnitFrames/FluxUnitFrames_DebuffTint.lua#L287) |
| `UF.SetupDebuffTint` | [L321](../../UnitFrames/FluxUnitFrames_DebuffTint.lua#L321) |
| `UF.RefreshDebuffTint` | [L335](../../UnitFrames/FluxUnitFrames_DebuffTint.lua#L335) |

### UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_SetBlizzardPlayerPredictionMuted` | [L268](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L268) |
| `FluxUnitFrames_SuppressBlizzardUnitFrame` | [L435](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L435) |
| `FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled` | [L457](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L457) |
| `FluxUnitFrames_RefreshBothSidesAfterToggle` | [L528](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L528) |
| `FluxUnitFrames_ApplyFluxVsBlizzardRuntime` | [L623](../../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua#L623) |

### UnitFrames/FluxUnitFrames_Focus.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUIPositionFocusFrameDefault` | [L46](../../UnitFrames/FluxUnitFrames_Focus.lua#L46) |
| `FluxUnitFrames_ApplyRuntimeFocus` | [L289](../../UnitFrames/FluxUnitFrames_Focus.lua#L289) |

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
| `_G.FluxUnitFrames_ApplyPlayerStatusBarLayout` | [L423](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L423) |
| `FluxUnitFrames_SyncTargetChromeForPlacement` | [L436](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L436) |
| `FluxUnitFrames_RefreshTargetOfTargetAnchor` | [L471](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L471) |
| `FluxUnitFrames_ReanchorUnitFrameScreenPosition` | [L496](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L496) |
| `FluxUnitFrames_ApplyThreatBarOptionsFromDB` | [L571](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L571) |
| `FluxUnitFrames_ApplyPortraitOptionsFromDB` | [L617](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L617) |
| `FluxUnitFrames_RefreshPortraitRenderModeFromDB` | [L687](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L687) |
| `FluxUnitFrames_GetAuraConfigTables` | [L738](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L738) |
| `FluxUnitFrames_ApplyAuraLayoutFromDB` | [L800](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L800) |
| `FluxUnitFrames_ApplyOptionsFromDB` | [L835](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L835) |
| `FluxUnitFrames_GetPlayerTargetPlacement2RelativeUIScale` | [L971](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L971) |
| `FluxUnitFrames_UnitFrameStorageToEffectiveDimension` | [L979](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L979) |
| `FluxUnitFrames_UnitFrameEffectiveToStorageDimension` | [L990](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L990) |
| `FluxUnitFrames_EnsureAndGetFrameSizesBucket` | [L1026](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1026) |
| `FluxUnitFrames_GetPlacement1TargetLeftForMicroMenuCap` | [L1053](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1053) |
| `FluxUnitFrames_GetUnitFrameDefaultDimension` | [L1089](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1089) |
| `FluxUnitFrames_GetFocusPresentationSize` | [L1114](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1114) |
| `FluxUnitFrames_GetFocusPresentationScale` | [L1123](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1123) |
| `FluxUnitFrames_GetConfiguredFrameSize` | [L1128](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1128) |
| `FluxUnitFrames_GetConfiguredPetTargetBarWidth` | [L1177](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1177) |
| `FluxUnitFrames_FullUnitFrameLayoutRefresh` | [L1190](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1190) |
| `FluxUnitFrames_GetHealthPartitionPct` | [L1227](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1227) |
| `FluxUnitFrames_RefreshBarPartitionsFromDB` | [L1258](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1258) |
| `FluxUnitFrames_ApplyFrameSizesFromDB` | [L1279](../../UnitFrames/FluxUnitFrames_OptionsBridge.lua#L1279) |

### UnitFrames/FluxUnitFrames_Party.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `Party.GetSizing` | [L21](../../UnitFrames/FluxUnitFrames_Party.lua#L21) |
| `Party.GetScale` | [L27](../../UnitFrames/FluxUnitFrames_Party.lua#L27) |
| `Party.GetStatusText` | [L42](../../UnitFrames/FluxUnitFrames_Party.lua#L42) |
| `Party.StyleText` | [L57](../../UnitFrames/FluxUnitFrames_Party.lua#L57) |
| `Party.LayoutIndicators` | [L81](../../UnitFrames/FluxUnitFrames_Party.lua#L81) |
| `Party.UpdatePvpBadge` | [L131](../../UnitFrames/FluxUnitFrames_Party.lua#L131) |
| `Party.SyncCastCover` | [L135](../../UnitFrames/FluxUnitFrames_Party.lua#L135) |
| `bar._fluxPartyCastResume` | [L166](../../UnitFrames/FluxUnitFrames_Party.lua#L166) |
| `Party.LayoutCastOverlay` | [L216](../../UnitFrames/FluxUnitFrames_Party.lua#L216) |
| `Party.SetThreatColor` | [L248](../../UnitFrames/FluxUnitFrames_Party.lua#L248) |
| `Party.PaintStatus` | [L252](../../UnitFrames/FluxUnitFrames_Party.lua#L252) |
| `Party.ApplyTextModes` | [L263](../../UnitFrames/FluxUnitFrames_Party.lua#L263) |
| `Party.UpdateIndicators` | [L289](../../UnitFrames/FluxUnitFrames_Party.lua#L289) |
| `Party.UpdateThreat` | [L304](../../UnitFrames/FluxUnitFrames_Party.lua#L304) |
| `Party.PaintChrome` | [L346](../../UnitFrames/FluxUnitFrames_Party.lua#L346) |
| `Party.RefreshChrome` | [L392](../../UnitFrames/FluxUnitFrames_Party.lua#L392) |
| `Party.LayoutFocusPresentation` | [L472](../../UnitFrames/FluxUnitFrames_Party.lua#L472) |
| `Party.SetupFocusPresentation` | [L495](../../UnitFrames/FluxUnitFrames_Party.lua#L495) |
| `Party.SetupCompactCastOverlay` | [L509](../../UnitFrames/FluxUnitFrames_Party.lua#L509) |
| `bar.UpdateLayoutbar.UpdateLayout` | [L515](../../UnitFrames/FluxUnitFrames_Party.lua#L515) |
| `Party.QueueRosterUpdate` | [L666](../../UnitFrames/FluxUnitFrames_Party.lua#L666) |
| `Party.RefreshPreview` | [L904](../../UnitFrames/FluxUnitFrames_Party.lua#L904) |
| `Party.ApplyOptions` | [L981](../../UnitFrames/FluxUnitFrames_Party.lua#L981) |
| `Party.Diagnostics` | [L1030](../../UnitFrames/FluxUnitFrames_Party.lua#L1030) |

### UnitFrames/FluxUnitFrames_Pet.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_ApplyRuntimePet` | [L280](../../UnitFrames/FluxUnitFrames_Pet.lua#L280) |

### UnitFrames/FluxUnitFrames_PetAuraTooltip.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `UF.ShowPetAuraTooltip` | [L551](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L551) |
| `UF.HidePetAuraTooltip` | [L585](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L585) |
| `UF.ShowUnitTooltip` | [L640](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L640) |
| `UF.HideUnitTooltip` | [L652](../../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua#L652) |

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
| `trueplayerFrame.UpdateOuterBorder` | [L1202](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1202) |
| `trueplayerFrame.UpdatePartition` | [L1212](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1212) |
| `_G.FluxUnitFrames_PlayerSpecClick_Refresh` | [L1222](../../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua#L1222) |

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
| `UF.GetHudBarTexture` | [L901](../../UnitFrames/FluxUnitFrames_Shared.lua#L901) |
| `UF.UsesHudUnitBars` | [L909](../../UnitFrames/FluxUnitFrames_Shared.lua#L909) |
| `UF.RecordFrameDimensions` | [L944](../../UnitFrames/FluxUnitFrames_Shared.lua#L944) |
| `UF.GetFramePublicDimensions` | [L954](../../UnitFrames/FluxUnitFrames_Shared.lua#L954) |
| `UF.GetFramePublicLevel` | [L964](../../UnitFrames/FluxUnitFrames_Shared.lua#L964) |
| `UF.SetFramePublicLevel` | [L983](../../UnitFrames/FluxUnitFrames_Shared.lua#L983) |
| `UF.RecordRelativeFramePublicLevel` | [L998](../../UnitFrames/FluxUnitFrames_Shared.lua#L998) |
| `UF.SetRelativeFramePublicLevel` | [L1005](../../UnitFrames/FluxUnitFrames_Shared.lua#L1005) |
| `UF.SyncPublicHealthGeometry` | [L1032](../../UnitFrames/FluxUnitFrames_Shared.lua#L1032) |
| `UF.GetPowerPredictionColor` | [L1081](../../UnitFrames/FluxUnitFrames_Shared.lua#L1081) |
| `UF.GetPowerStatusAtlas` | [L1100](../../UnitFrames/FluxUnitFrames_Shared.lua#L1100) |
| `UF.UpdateResourceSpark` | [L1154](../../UnitFrames/FluxUnitFrames_Shared.lua#L1154) |
| `pulse:StartAnimIfFull` | [L1372](../../UnitFrames/FluxUnitFrames_Shared.lua#L1372) |
| `pulse:RemoveAnims` | [L1395](../../UnitFrames/FluxUnitFrames_Shared.lua#L1395) |
| `UF.SetFullResourcePulseActive` | [L1438](../../UnitFrames/FluxUnitFrames_Shared.lua#L1438) |
| `UF.UpdateFullResourcePulse` | [L1467](../../UnitFrames/FluxUnitFrames_Shared.lua#L1467) |
| `UF.PowerValueForDisplay` | [L1496](../../UnitFrames/FluxUnitFrames_Shared.lua#L1496) |
| `UF.ApplyResourceBarStyle` | [L1532](../../UnitFrames/FluxUnitFrames_Shared.lua#L1532) |
| `UF.RefreshResourceConnection` | [L1627](../../UnitFrames/FluxUnitFrames_Shared.lua#L1627) |
| `UF.ApplyStaggerBarStyle` | [L1650](../../UnitFrames/FluxUnitFrames_Shared.lua#L1650) |
| `UF.LayoutPetHappinessIcon` | [L1732](../../UnitFrames/FluxUnitFrames_Shared.lua#L1732) |
| `UF.GetNativeUnitClassRGB` | [L2201](../../UnitFrames/FluxUnitFrames_Shared.lua#L2201) |
| `UF.GetUnitNameRGB` | [L2219](../../UnitFrames/FluxUnitFrames_Shared.lua#L2219) |
| `UF.PaintUnitNameColor` | [L2236](../../UnitFrames/FluxUnitFrames_Shared.lua#L2236) |
| `UF.GetUnitNameColorHex` | [L2242](../../UnitFrames/FluxUnitFrames_Shared.lua#L2242) |
| `UF.PaintRestrictedUnitChrome` | [L2250](../../UnitFrames/FluxUnitFrames_Shared.lua#L2250) |
| `UF.GetMiniUnitChromeColor` | [L2275](../../UnitFrames/FluxUnitFrames_Shared.lua#L2275) |
| `UF.PaintMiniUnitChrome` | [L2294](../../UnitFrames/FluxUnitFrames_Shared.lua#L2294) |
| `UF.ForeverNpcChrome` | [L2306](../../UnitFrames/FluxUnitFrames_Shared.lua#L2306) |
| `UF.GetNormalUnitBackdrop` | [L2350](../../UnitFrames/FluxUnitFrames_Shared.lua#L2350) |
| `UF.GetUnitChromeColors` | [L2359](../../UnitFrames/FluxUnitFrames_Shared.lua#L2359) |
| `AnimatedHealthLossMixin:OnLoad` | [L2431](../../UnitFrames/FluxUnitFrames_Shared.lua#L2431) |
| `AnimatedHealthLossMixin:SetDuration` | [L2439](../../UnitFrames/FluxUnitFrames_Shared.lua#L2439) |
| `AnimatedHealthLossMixin:SetStartDelay` | [L2443](../../UnitFrames/FluxUnitFrames_Shared.lua#L2443) |
| `AnimatedHealthLossMixin:SetPauseDelay` | [L2447](../../UnitFrames/FluxUnitFrames_Shared.lua#L2447) |
| `AnimatedHealthLossMixin:SetPostponeDelay` | [L2451](../../UnitFrames/FluxUnitFrames_Shared.lua#L2451) |
| `AnimatedHealthLossMixin:SetUnitHealthBar` | [L2455](../../UnitFrames/FluxUnitFrames_Shared.lua#L2455) |
| `AnimatedHealthLossMixin:UpdateHealthMinMax` | [L2465](../../UnitFrames/FluxUnitFrames_Shared.lua#L2465) |
| `AnimatedHealthLossMixin:GetHealthLossAnimationData` | [L2470](../../UnitFrames/FluxUnitFrames_Shared.lua#L2470) |
| `AnimatedHealthLossMixin:CancelAnimation` | [L2487](../../UnitFrames/FluxUnitFrames_Shared.lua#L2487) |
| `AnimatedHealthLossMixin:SetDisplayedLoss` | [L2493](../../UnitFrames/FluxUnitFrames_Shared.lua#L2493) |
| `AnimatedHealthLossMixin:BeginAnimation` | [L2503](../../UnitFrames/FluxUnitFrames_Shared.lua#L2503) |
| `AnimatedHealthLossMixin:PostponeStartTime` | [L2512](../../UnitFrames/FluxUnitFrames_Shared.lua#L2512) |
| `AnimatedHealthLossMixin:UpdateHealth` | [L2516](../../UnitFrames/FluxUnitFrames_Shared.lua#L2516) |
| `AnimatedHealthLossMixin:ReadableAbsorbBlocks` | [L2534](../../UnitFrames/FluxUnitFrames_Shared.lua#L2534) |
| `AnimatedHealthLossMixin:UpdateLossAnimation` | [L2542](../../UnitFrames/FluxUnitFrames_Shared.lua#L2542) |
| `AnimatedHealthLossMixin:ShowPixelDriver` | [L2561](../../UnitFrames/FluxUnitFrames_Shared.lua#L2561) |
| `AnimatedHealthLossMixin:UpdateFromPixels` | [L2584](../../UnitFrames/FluxUnitFrames_Shared.lua#L2584) |
| `UF.ApplyHealAbsorbOptionVisibility` | [L2888](../../UnitFrames/FluxUnitFrames_Shared.lua#L2888) |
| `UF.UpdateHealPrediction` | [L2916](../../UnitFrames/FluxUnitFrames_Shared.lua#L2916) |
| `UF.UnitIsAFKDisplay` | [L3143](../../UnitFrames/FluxUnitFrames_Shared.lua#L3143) |
| `UF.ShouldShowAFKHealthOverlay` | [L3153](../../UnitFrames/FluxUnitFrames_Shared.lua#L3153) |
| `UF.GetHealthDeadGhostStatusText` | [L3160](../../UnitFrames/FluxUnitFrames_Shared.lua#L3160) |
| `UF.LayoutVerticalTargetHealth` | [L3184](../../UnitFrames/FluxUnitFrames_Shared.lua#L3184) |
| `UF.CreateVerticalTargetAbsorbs` | [L3213](../../UnitFrames/FluxUnitFrames_Shared.lua#L3213) |
| `UF.UpdateVerticalTargetAbsorbs` | [L3252](../../UnitFrames/FluxUnitFrames_Shared.lua#L3252) |
| `UF.UpdateVerticalTargetColor` | [L3296](../../UnitFrames/FluxUnitFrames_Shared.lua#L3296) |
| `UF.ResetVerticalTargetHealth` | [L3313](../../UnitFrames/FluxUnitFrames_Shared.lua#L3313) |
| `UF.ConfigureVerticalTargetHealth` | [L3317](../../UnitFrames/FluxUnitFrames_Shared.lua#L3317) |
| `UF.UpdateVerticalTargetHealth` | [L3356](../../UnitFrames/FluxUnitFrames_Shared.lua#L3356) |
| `UF.UpdateHealth` | [L3390](../../UnitFrames/FluxUnitFrames_Shared.lua#L3390) |
| `UF.CreateHealthBar` | [L3546](../../UnitFrames/FluxUnitFrames_Shared.lua#L3546) |
| `UF.UpdateHealthColor` | [L3819](../../UnitFrames/FluxUnitFrames_Shared.lua#L3819) |
| `UF.UpdatePower` | [L3880](../../UnitFrames/FluxUnitFrames_Shared.lua#L3880) |
| `UF.CreatePowerBar` | [L4064](../../UnitFrames/FluxUnitFrames_Shared.lua#L4064) |
| `UF.FitPortraitBorderBounds` | [L4343](../../UnitFrames/FluxUnitFrames_Shared.lua#L4343) |
| `UF.FitPortraitOverlay` | [L4371](../../UnitFrames/FluxUnitFrames_Shared.lua#L4371) |
| `UF.CreatePortrait` | [L4451](../../UnitFrames/FluxUnitFrames_Shared.lua#L4451) |
| `UF.FrameUsesPortraitLayout` | [L4670](../../UnitFrames/FluxUnitFrames_Shared.lua#L4670) |
| `UF.LayoutBigDebuffsCornerPlaceholder` | [L4687](../../UnitFrames/FluxUnitFrames_Shared.lua#L4687) |
| `UF.ForgetRosterPortrait` | [L4817](../../UnitFrames/FluxUnitFrames_Shared.lua#L4817) |
| `UF.UpdatePortrait` | [L4825](../../UnitFrames/FluxUnitFrames_Shared.lua#L4825) |
| `UF.SyncPortraitModelGeometry` | [L4945](../../UnitFrames/FluxUnitFrames_Shared.lua#L4945) |
| `UF.RefreshPortraitAfterDisplayMetrics` | [L4966](../../UnitFrames/FluxUnitFrames_Shared.lua#L4966) |
| `UF.UpdatePlayerSpecIconOnly` | [L5125](../../UnitFrames/FluxUnitFrames_Shared.lua#L5125) |
| `_G.FluxUnitFrames_RefreshPlayerSpecIcon` | [L5184](../../UnitFrames/FluxUnitFrames_Shared.lua#L5184) |
| `_G.FluxUnitFrames_GetPlayerSpecIcon` | [L5255](../../UnitFrames/FluxUnitFrames_Shared.lua#L5255) |
| `UF.CreateAtlasBorder` | [L5293](../../UnitFrames/FluxUnitFrames_Shared.lua#L5293) |
| `UF.UpdateAtlasBorder` | [L5345](../../UnitFrames/FluxUnitFrames_Shared.lua#L5345) |
| `UF.GetUnitTooltip` | [L5400](../../UnitFrames/FluxUnitFrames_Shared.lua#L5400) |
| `UF.IsUnitTooltipOwner` | [L5414](../../UnitFrames/FluxUnitFrames_Shared.lua#L5414) |
| `UF.BeginUnitTooltip` | [L5420](../../UnitFrames/FluxUnitFrames_Shared.lua#L5420) |
| `UF.SetUnitTooltipRefresh` | [L5430](../../UnitFrames/FluxUnitFrames_Shared.lua#L5430) |
| `UF.ShowUnitTooltip` | [L5436](../../UnitFrames/FluxUnitFrames_Shared.lua#L5436) |
| `UF.HideUnitTooltip` | [L5483](../../UnitFrames/FluxUnitFrames_Shared.lua#L5483) |
| `UF.CreateMouseoverHighlight` | [L5527](../../UnitFrames/FluxUnitFrames_Shared.lua#L5527) |
| `UF.SetIndicatorArt` | [L5609](../../UnitFrames/FluxUnitFrames_Shared.lua#L5609) |
| `UF.CreatePvpBadge` | [L5627](../../UnitFrames/FluxUnitFrames_Shared.lua#L5627) |
| `UF.UpdatePvpBadge` | [L5645](../../UnitFrames/FluxUnitFrames_Shared.lua#L5645) |
| `UF.PrepareClassIconBounds` | [L5691](../../UnitFrames/FluxUnitFrames_Shared.lua#L5691) |
| `UF.CreateOuterBorder` | [L5721](../../UnitFrames/FluxUnitFrames_Shared.lua#L5721) |
| `outerBorderFrame.SetRightClickMenu` | [L5981](../../UnitFrames/FluxUnitFrames_Shared.lua#L5981) |
| `UF.SetFrameLevelIfChanged` | [L6104](../../UnitFrames/FluxUnitFrames_Shared.lua#L6104) |
| `UF.UpdatePortraitCombatTint` | [L6207](../../UnitFrames/FluxUnitFrames_Shared.lua#L6207) |
| `UF.UpdateBorderColors` | [L6230](../../UnitFrames/FluxUnitFrames_Shared.lua#L6230) |
| `UF.SetNameStripIconSize` | [L6702](../../UnitFrames/FluxUnitFrames_Shared.lua#L6702) |
| `UF.SetNameStripIconDrawLayer` | [L6709](../../UnitFrames/FluxUnitFrames_Shared.lua#L6709) |
| `UF.SetNameStripIconShown` | [L6715](../../UnitFrames/FluxUnitFrames_Shared.lua#L6715) |
| `UF.NameStripIconPointMatches` | [L6722](../../UnitFrames/FluxUnitFrames_Shared.lua#L6722) |
| `UF.SetNameStripIconPoint` | [L6731](../../UnitFrames/FluxUnitFrames_Shared.lua#L6731) |
| `UF.SetNameStripIconHeight` | [L6739](../../UnitFrames/FluxUnitFrames_Shared.lua#L6739) |
| `UF.LayoutNameStripIcon` | [L6745](../../UnitFrames/FluxUnitFrames_Shared.lua#L6745) |
| `UF.SetNameStripIconFrameLevel` | [L6758](../../UnitFrames/FluxUnitFrames_Shared.lua#L6758) |
| `UF.UpdateRaidMarker` | [L7135](../../UnitFrames/FluxUnitFrames_Shared.lua#L7135) |
| `UF.LayoutRaidMarker` | [L7149](../../UnitFrames/FluxUnitFrames_Shared.lua#L7149) |
| `UF.UpdateOuterBorder` | [L7189](../../UnitFrames/FluxUnitFrames_Shared.lua#L7189) |
| `UF.UpdateAdditionalPower` | [L7780](../../UnitFrames/FluxUnitFrames_Shared.lua#L7780) |
| `UF.CreateAdditionalPowerBar` | [L7933](../../UnitFrames/FluxUnitFrames_Shared.lua#L7933) |
| `UF.GetThreatBarPosition` | [L8118](../../UnitFrames/FluxUnitFrames_Shared.lua#L8118) |
| `UF.CreateThreatBar` | [L8411](../../UnitFrames/FluxUnitFrames_Shared.lua#L8411) |
| `UF.LayoutThreatBar` | [L8479](../../UnitFrames/FluxUnitFrames_Shared.lua#L8479) |
| `UF.UpdateThreatBar` | [L8611](../../UnitFrames/FluxUnitFrames_Shared.lua#L8611) |
| `UF.UpdateFrameVisualElements` | [L8815](../../UnitFrames/FluxUnitFrames_Shared.lua#L8815) |
| `UF.UpdateFramePartitionSeparators` | [L8911](../../UnitFrames/FluxUnitFrames_Shared.lua#L8911) |
| `UF.GetFluxStylePartitionHealthHeight` | [L8958](../../UnitFrames/FluxUnitFrames_Shared.lua#L8958) |
| `UF.UpdateFramePartition` | [L8972](../../UnitFrames/FluxUnitFrames_Shared.lua#L8972) |
| `UF.QueueRosterChrome` | [L9267](../../UnitFrames/FluxUnitFrames_Shared.lua#L9267) |
| `UF.ApplyEmulatedHorizontalSqueezeForFrame` | [L9645](../../UnitFrames/FluxUnitFrames_Shared.lua#L9645) |
| `UF.UpdateAllEmulatedHorizontalSqueeze` | [L9649](../../UnitFrames/FluxUnitFrames_Shared.lua#L9649) |
| `FluxUnitFrames_UpdateAllEmulatedHorizontalSqueeze` | [L9661](../../UnitFrames/FluxUnitFrames_Shared.lua#L9661) |
| `UF.RegisterEmulatedHorizontalSqueeze` | [L9665](../../UnitFrames/FluxUnitFrames_Shared.lua#L9665) |
| `UF.CreateBaseFrame` | [L9715](../../UnitFrames/FluxUnitFrames_Shared.lua#L9715) |
| `UF.RefreshSelfDisplayNames` | [L9982](../../UnitFrames/FluxUnitFrames_Shared.lua#L9982) |
| `FluxUnitFrames_RefreshAppearanceChrome` | [L10004](../../UnitFrames/FluxUnitFrames_Shared.lua#L10004) |

### UnitFrames/FluxUnitFrames_Target.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `frame:UpdateFluxTargetPlaceholderVisibility` | [L291](../../UnitFrames/FluxUnitFrames_Target.lua#L291) |
| `FluxUnitFrames_RefreshTargetAndTotTogether` | [L342](../../UnitFrames/FluxUnitFrames_Target.lua#L342) |
| `FluxUnitFrames_ApplyRuntimeTarget` | [L413](../../UnitFrames/FluxUnitFrames_Target.lua#L413) |

### UnitFrames/FluxUnitFrames_TargetOfTarget.lua

Owner: [14-unit-frames.md](../14-unit-frames.md).

| Declaration | Source |
|---|---|
| `FluxUnitFrames_RestoreBlizzardTotDefaultParent` | [L287](../../UnitFrames/FluxUnitFrames_TargetOfTarget.lua#L287) |
| `FluxUnitFrames_ApplyRuntimeToT` | [L299](../../UnitFrames/FluxUnitFrames_TargetOfTarget.lua#L299) |

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
| `WindowMover.Apply` | [L300](../../WindowMover/Engine.lua#L300) |
| `WindowMover._OnProxyUpdate` | [L478](../../WindowMover/Engine.lua#L478) |
| `WindowMover.ResetFrame` | [L623](../../WindowMover/Engine.lua#L623) |
| `WindowMover.ResetAll` | [L640](../../WindowMover/Engine.lua#L640) |
| `WindowMover.SetLocked` | [L652](../../WindowMover/Engine.lua#L652) |
| `WindowMover.IsLocked` | [L659](../../WindowMover/Engine.lua#L659) |
| `WindowMover.Attach` | [L821](../../WindowMover/Engine.lua#L821) |
| `WindowMover.Scan` | [L915](../../WindowMover/Engine.lua#L915) |
| `WindowMover.Refresh` | [L943](../../WindowMover/Engine.lua#L943) |
| `WindowMover.Start` | [L960](../../WindowMover/Engine.lua#L960) |
| `WindowMover.AttachedCount` | [L989](../../WindowMover/Engine.lua#L989) |
| `WindowMover.Smoke` | [L999](../../WindowMover/Engine.lua#L999) |

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
