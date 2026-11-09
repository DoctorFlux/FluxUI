# Setting definitions and custom control sites

Generated from Lua table constructors and factory call sites. This is the exhaustive source-definition companion to the [options map](../26-options-map.md), not an evaluated screenshot of a particular character's options.

A definition can be a group, header, description, actionable setting, or custom embedded control. Factory templates and their calls are listed separately: one runtime control per skill/unit/row can originate at a single source site. Full expressions, getter/setter bodies, and line locations are retained in [inventory.json](inventory.json). Expressions are source evidence, not values evaluated by this tool.

Shared literal defaults are in [defaults](defaults.md); feature-owned fallbacks are in the getter excerpts and linked feature chapters. A default table is not proof of the effective value after migrations, CVars, character overrides, or user configuration.

## FluxOptions.lua

[AddonOptions/FluxOptions.lua](../../AddonOptions/FluxOptions.lua)

### options · FluxUI · L19

Source: [AddonOptions/FluxOptions.lua:19](../../AddonOptions/FluxOptions.lua#L19). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

## FluxOptionsActionBars.lua

[AddonOptions/FluxOptionsActionBars.lua](../../AddonOptions/FluxOptionsActionBars.lua)

### &lt;anonymous&gt; · Action Bars · L57

Source: [AddonOptions/FluxOptionsActionBars.lua:57](../../AddonOptions/FluxOptionsActionBars.lua#L57). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

## FluxOptionsActionBars_Bar.lua

[AddonOptions/FluxOptionsActionBars_Bar.lua](../../AddonOptions/FluxOptionsActionBars_Bar.lua)

### &lt;anonymous&gt; · Bar · L21

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:21](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L21). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### scopeHeader · Scope · L26

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:26](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L26). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### settingsScope · Action bar scope · L31

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:31](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L31). Type: `"select"`.

Same settings for all chars, or just this one.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L37) |
| get | `function() if FluxOptions and FluxOptions.IsActionbarsCharacterSpecific and FluxOptions:IsActionbarsCharacterSpecific() then return "character" end return "account" end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L42) |
| set | `function(_, val) if FluxOptions and FluxOptions.SetActionbarsCharacterSpecific then FluxOptions:SetActionbarsCharacterSpecific(val == "character") end AB.Notify() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L49) |

### layoutHeader · Layout · L57

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:57](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L57). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### minirowPosition · Minirow position · L62

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:62](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L62). Type: `"select"`.

Shift/ctrl rows above or below the main bar.

| Contract | Source expression / implementation |
|---|---|
| values | `{ top = "Top (default)", bottom = "Bottom", }` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L68) |
| get | `function() local t = AB.ActionbarsDB() if t then return t.minirowPosition or "top" end return "top" end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L73) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.minirowPosition = val end if Flux and Flux.Bars and Flux.Bars.RequestLayout then Flux.Bars.RequestLayout("minirow") end end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L80) |

### vfxHeader · Action Bar VFX · L91

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:91](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L91). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.IsPreDF() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L95) |

### vfxDesc · Cast and target effects on buttons. Older clients only. · L99

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:99](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L99). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.IsPreDF() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L104) |

### spellCastVFX · Enable action bar VFX · L108

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:108](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L108). Type: `"toggle"`.

Show cast and target effects on action buttons.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local t = AB.ActionbarsDB() if t and t.spellCastVFX == false then return false end return true end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L117) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.spellCastVFX = val and true or false end if Flux and Flux.ButtonFX and Flux.ButtonFX.Cast and Flux.ButtonFX.Cast.RefreshFromOptions then Flux.ButtonFX.Cast.RefreshFromOptions() end end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L124) |
| hidden | `function() return not AB.IsPreDF() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L114) |

### mouseoverCastHeader · Mouseover casting · L135

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:135](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L135). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### mouseoverCastDesc · Matches the spell book setting. · L140

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:140](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L140). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### mouseoverCast · Mouseover cast · L146

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:146](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L146). Type: `"toggle"`.

Cast on the unit under your cursor. Plain action slots use click-time targeting and Flux keybind macros get an [@mouseover] clause. A keybind that already picks its own target keeps that target.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local MC = AB.MouseoverCast() if MC and MC.IsEnabled then return MC.IsEnabled() end local t = AB.ActionbarsDB() return not t or t.mouseoverCast ~= false end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L153) |
| set | `function(_, val) local MC = AB.MouseoverCast() if MC and MC.SetEnabled then MC.SetEnabled(val and true or false) return end local t = AB.ActionbarsDB() if t then t.mouseoverCast = val and true or false end if MC and MC.Apply then MC.Apply() end end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L161) |
| hidden | `UsesNativeCVar` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L152) |

### mouseoverCastNative · function() local MC = AB.MouseoverCast() return "Mouseover cast: " .. ((MC and MC.IsEnabled()) and "On" or "O… · L176

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:176](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L176). Type: `"execute"`.

Open Blizzard's Click Casting panel to change mouseover casting and its modifier key.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local MC = AB.MouseoverCast() if MC and MC.OpenNativeOptions then MC.OpenNativeOptions() end end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L187) |
| hidden | `function() return not UsesNativeCVar() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L185) |
| disabled | `function() return InCombatLockdown and InCombatLockdown() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L186) |

### mouseoverCastNativeForever · This client uses Blizzard mouseover-cast. Change it in Click Casting from the spellbook, or use the button ab… · L192

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:192](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L192). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not UsesNativeCVar() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L198) |

### mouseoverCastCombat · \|cffffcc00Changing this in combat applies when you leave combat.\|r · L202

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:202](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L202). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not (InCombatLockdown and InCombatLockdown()) end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L208) |

### spellbookHeader · Auto Rank up · L213

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:213](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L213). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L217) |

### spellbookDesc · Forever, Classic Era, and Anniversary. Not on live Midnight. · L221

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:221](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L221). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L226) |

### autoRankUp · Auto rank up · L230

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:230](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L230). Type: `"toggle"`.

Upgrade spells when you learn a higher rank.

| Contract | Source expression / implementation |
|---|---|
| get | `function() if FluxSpellRankManagerModule and FluxSpellRankManagerModule.GetAutoRankUpEnabled then return FluxSpellRankManagerModule:GetAutoRankUpEnabled() end return false end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L239) |
| set | `function(_, val) if FluxSpellRankManagerModule and FluxSpellRankManagerModule.SetAutoRankUpEnabled then FluxSpellRankManagerModule:SetAutoRankUpEnabled(val) end end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L245) |
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L236) |

### rankUpAllSpells · Rank up all spells · L251

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:251](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L251). Type: `"execute"`.

Replace lower ranks with your highest rank now.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxSpellRankManagerModule and FluxSpellRankManagerModule.RankUpAllSpells then FluxSpellRankManagerModule:RankUpAllSpells() end end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L263) |
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L257) |
| disabled | `function() return InCombatLockdown() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L260) |

### blacklistHelp · Blacklisted spells: · L269

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:269](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L269). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L274) |

### blacklistPanel · blacklistPanel · L278

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:278](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L278). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L283) |
| dialogControl | `"FluxSpellBlacklistPanel"` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L286) |

### perfHeader · Performance · L289

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:289](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L289). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### perfDesc · Lower = faster updates, more CPU. · L294

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:294](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L294). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### rangeCheckInterval · Range check interval · L300

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:300](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L300). Type: `"range"`.

How often action bar buttons check range.

| Contract | Source expression / implementation |
|---|---|
| min | `0.1` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L305) |
| max | `1.0` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L306) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L307) |
| get | `function() local t = AB.ActionbarsDB() if t and t.rangeCheckInterval then return t.rangeCheckInterval end return 0.25 end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L308) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.rangeCheckInterval = val end ApplyPerformance() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L315) |

### extraButtonRangeCheckInterval · Extra button range interval · L323

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:323](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L323). Type: `"range"`.

How often extra grid buttons check range.

| Contract | Source expression / implementation |
|---|---|
| min | `0.1` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L328) |
| max | `1.0` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L329) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L330) |
| get | `function() local t = AB.ActionbarsDB() if t and t.extraButtonRangeCheckInterval then return t.extraButtonRangeCheckInterval end return 0.18 end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L331) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.extraButtonRangeCheckInterval = val end ApplyPerformance() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L338) |

### mouseoverUpdateInterval · Mouseover update interval · L346

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:346](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L346). Type: `"range"`.

How often mouseover macros refresh their tint.

| Contract | Source expression / implementation |
|---|---|
| min | `0.04` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L351) |
| max | `0.2` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L352) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L353) |
| get | `function() local t = AB.ActionbarsDB() if t and t.mouseoverUpdateInterval then return t.mouseoverUpdateInterval end return 0.07 end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L354) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.mouseoverUpdateInterval = val end ApplyPerformance() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L361) |

### macroUsableMinInterval · Macro usable interval · L369

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:369](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L369). Type: `"range"`.

Delay between macro usability updates. 0 = off.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L374) |
| max | `0.5` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L375) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L376) |
| get | `function() local t = AB.ActionbarsDB() if t and t.macroUsableMinInterval ~= nil then return t.macroUsableMinInterval end return 0.05 end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L377) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.macroUsableMinInterval = val end ApplyPerformance() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L384) |

### actionUsableMinInterval · Action usable interval · L392

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:392](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L392). Type: `"range"`.

Delay between button usability updates. 0 = off.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L397) |
| max | `0.5` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L398) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L399) |
| get | `function() local t = AB.ActionbarsDB() if t and t.actionUsableMinInterval ~= nil then return t.actionUsableMinInterval end return 0 end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L400) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.actionUsableMinInterval = val end ApplyPerformance() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L407) |

### macroSmartLayoutPerfDesc · Macro buttons won't move minirows unless needed. · L415

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:415](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L415). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

## FluxOptionsActionBars_Bindings.lua

[AddonOptions/FluxOptionsActionBars_Bindings.lua](../../AddonOptions/FluxOptionsActionBars_Bindings.lua)

### &lt;anonymous&gt; · Bindings · L6

Source: [AddonOptions/FluxOptionsActionBars_Bindings.lua:6](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L6). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### bindingHeader · Key Bindings · L11

Source: [AddonOptions/FluxOptionsActionBars_Bindings.lua:11](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L11). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### bindingDesc · Hover a button, press a key. ESC clears. · L16

Source: [AddonOptions/FluxOptionsActionBars_Bindings.lua:16](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L16). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### enterBindingMode · Enter Binding Mode · L22

Source: [AddonOptions/FluxOptionsActionBars_Bindings.lua:22](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L22). Type: `"execute"`.

Bind keys on your bars.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if not FluxBindingMode then return end if InCombatLockdown and InCombatLockdown() then return end -- Defer close: AceConfigDialog refreshes after execute and needs rootframe. C_Timer.After(0, function() if InCombatLockdown and InCombatLoc…` [source](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L31) |
| disabled | `function() return InCombatLockdown() end` [source](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L28) |

### bindingCombatNote · \|cffff6666Cannot enter binding mode during combat.\|r · L50

Source: [AddonOptions/FluxOptionsActionBars_Bindings.lua:50](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L50). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not InCombatLockdown() end` [source](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L55) |

### resetKeybindsHeader · Reset keybindings · L60

Source: [AddonOptions/FluxOptionsActionBars_Bindings.lua:60](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L60). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### resetKeybindsDesc · Reset all keys to Flux defaults. · L65

Source: [AddonOptions/FluxOptionsActionBars_Bindings.lua:65](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L65). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### resetKeybindsToFluxDefaults · Reset keybindings to Flux defaults · L71

Source: [AddonOptions/FluxOptionsActionBars_Bindings.lua:71](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L71). Type: `"execute"`.

Clear binds and use Flux defaults.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxDefaultSettings and FluxDefaultSettings.ApplyKeybinds then FluxDefaultSettings.ApplyKeybinds() end end` [source](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L82) |
| disabled | `function() return InCombatLockdown() end` [source](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L79) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L77) |
| confirmText | `"Replace all key bindings with Flux defaults?"` [source](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L78) |

### resetKeybindsCombatNote · \|cffff6666Cannot reset keybindings during combat.\|r · L88

Source: [AddonOptions/FluxOptionsActionBars_Bindings.lua:88](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L88). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not InCombatLockdown() end` [source](../../AddonOptions/FluxOptionsActionBars_Bindings.lua#L93) |

## FluxOptionsActionBars_Extra.lua

[AddonOptions/FluxOptionsActionBars_Extra.lua](../../AddonOptions/FluxOptionsActionBars_Extra.lua)

### &lt;anonymous&gt; · Extra · L6

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:6](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L6). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### extraButtonsHeader · Extra buttons (visibility) · L11

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:11](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L11). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### extraButtonsDesc · Click to change visibility. O=Off, A=Auto, +=Always, H=Hidden. · L16

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:16](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L16). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### extraButtonVisibilityReset · Reset extra button visibility to defaults · L22

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:22](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L22). Type: `"execute"`.

Reset all extra buttons for this scope.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxExtraButtonVisibility and FluxExtraButtonVisibility.ResetToDefaults then FluxExtraButtonVisibility.ResetToDefaults() end end` [source](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L30) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L28) |
| confirmText | `"Reset extra button visibility to defaults?"` [source](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L29) |

### extraButtonVisibilityPanel · extraButtonVisibilityPanel · L36

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:36](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L36). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| dialogControl | `"FluxExtraButtonVisibilityPanel"` [source](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L41) |

### consumableSwapHeader · Food, water, and potions · L44

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:44](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L44). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### consumableSwapDesc · Off for both is the starting setup, so food, water, and potions stay on their own buttons. Turn on one side, … · L49

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:49](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L49). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### consumableSwapFoodWater · Food and water become potions in combat · L55

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:55](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L55). Type: `"toggle"`.

Food uses your healing potion in combat. Water uses your mana potion in combat. Out of combat they stay food and water, or Recuperate if the food button is showing that. Both sides need to be available.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local Bridge = _G.FluxEBSConsumableBridge if Bridge and Bridge.GetConsumableCombatSwap then return Bridge.GetConsumableCombatSwap("foodWater") end local t = AB.ActionbarsDB() return t and t.consumableCombatSwap and t.consumableCombatSwap.…` [source](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L61) |
| set | `function(_, val) local Bridge = _G.FluxEBSConsumableBridge if Bridge and Bridge.SetConsumableCombatSwap then Bridge.SetConsumableCombatSwap("foodWater", val) return end local t = AB.ActionbarsDB() if not t then return end t.consumableCombatSwap = t.…` [source](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L69) |

### consumableSwapPotions · Potions become food and water out of combat · L83

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:83](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L83). Type: `"toggle"`.

The healing potion button uses food out of combat. The mana potion button uses water out of combat. In combat they stay potions. Both items need to be in your bags.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local Bridge = _G.FluxEBSConsumableBridge if Bridge and Bridge.GetConsumableCombatSwap then return Bridge.GetConsumableCombatSwap("potions") end local t = AB.ActionbarsDB() return t and t.consumableCombatSwap and t.consumableCombatSwap.po…` [source](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L89) |
| set | `function(_, val) local Bridge = _G.FluxEBSConsumableBridge if Bridge and Bridge.SetConsumableCombatSwap then Bridge.SetConsumableCombatSwap("potions", val) return end local t = AB.ActionbarsDB() if not t then return end t.consumableCombatSwap = t.co…` [source](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L97) |

### ncFlyoutPanel · Per character. Click hide, drag reorder, right-click favorite. · L112

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:112](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L112). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| dialogControl | `"FluxNCFlyoutPanel"` [source](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L118) |

### spellbookSlotsHeader · Utility slots · L121

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:121](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L121). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### spellbookSlotsDesc · Drag spell/item/macro/mount/toy. Hold Shift/Ctrl/Alt for that modifier. Drag off to clear, or clear in option… · L126

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:126](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L126). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### spellbookSlotsPanel · spellbookSlotsPanel · L132

Source: [AddonOptions/FluxOptionsActionBars_Extra.lua:132](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L132). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| dialogControl | `"FluxSpellBookSlotsPanel"` [source](../../AddonOptions/FluxOptionsActionBars_Extra.lua#L137) |

## FluxOptionsActionBars_Stance.lua

[AddonOptions/FluxOptionsActionBars_Stance.lua](../../AddonOptions/FluxOptionsActionBars_Stance.lua)

### &lt;anonymous&gt; · Stance · L6

Source: [AddonOptions/FluxOptionsActionBars_Stance.lua:6](../../AddonOptions/FluxOptionsActionBars_Stance.lua#L6). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### stanceBarOrderHeader · Stance bar slot order · L11

Source: [AddonOptions/FluxOptionsActionBars_Stance.lua:11](../../AddonOptions/FluxOptionsActionBars_Stance.lua#L11). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### stanceBarOrderDesc · Drag to reorder. Right-click hide/show built-in slots. Right-click remove added spells and items. Drag a spel… · L16

Source: [AddonOptions/FluxOptionsActionBars_Stance.lua:16](../../AddonOptions/FluxOptionsActionBars_Stance.lua#L16). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### stanceBarOrderReset · Reset stance bar order to default · L22

Source: [AddonOptions/FluxOptionsActionBars_Stance.lua:22](../../AddonOptions/FluxOptionsActionBars_Stance.lua#L22). Type: `"execute"`.

Back to default order and show all built-in slots. Added spells and items stay.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxOptions and FluxOptions.db and FluxOptions.db.char then local cab = FluxOptions.db.char.actionbars if cab then if cab.stanceBarSlotOrder then wipe(cab.stanceBarSlotOrder) else cab.stanceBarSlotOrder = {} end if cab.stanceBarHiddenS…` [source](../../AddonOptions/FluxOptionsActionBars_Stance.lua#L28) |

### stanceBarOrderPanel · stanceBarOrderPanel · L56

Source: [AddonOptions/FluxOptionsActionBars_Stance.lua:56](../../AddonOptions/FluxOptionsActionBars_Stance.lua#L56). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| dialogControl | `"FluxStanceBarOrderPanel"` [source](../../AddonOptions/FluxOptionsActionBars_Stance.lua#L61) |

## FluxOptionsAppearance.lua

[AddonOptions/FluxOptionsAppearance.lua](../../AddonOptions/FluxOptionsAppearance.lua)

### &lt;anonymous&gt; · Appearance · L10

Source: [AddonOptions/FluxOptionsAppearance.lua:10](../../AddonOptions/FluxOptionsAppearance.lua#L10). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### header · Borders and buttons · L15

Source: [AddonOptions/FluxOptionsAppearance.lua:15](../../AddonOptions/FluxOptionsAppearance.lua#L15). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### description · Minecraft style uses the original inventory bevel, slot and button pixels from your local Minecraft Java 1.20… · L16

Source: [AddonOptions/FluxOptionsAppearance.lua:16](../../AddonOptions/FluxOptionsAppearance.lua#L16). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### style · UI style · L22

Source: [AddonOptions/FluxOptionsAppearance.lua:22](../../AddonOptions/FluxOptionsAppearance.lua#L22). Type: `"select"`.

Changes FluxUI border art and supported button frames. The Minecraft textures are built locally from your installed game and are not included in the public addon.

| Contract | Source expression / implementation |
|---|---|
| values | `{ default = "FluxUI default", minecraft = "Minecraft", }` [source](../../AddonOptions/FluxOptionsAppearance.lua#L28) |
| get | `function() return FluxOptions.db.profile.appearance.style or "default" end` [source](../../AddonOptions/FluxOptionsAppearance.lua#L33) |
| set | `function(_, val) FluxOptions.db.profile.appearance.style = val RefreshAppearance() end` [source](../../AddonOptions/FluxOptionsAppearance.lua#L36) |

### accentHeader · Accent · L41

Source: [AddonOptions/FluxOptionsAppearance.lua:41](../../AddonOptions/FluxOptionsAppearance.lua#L41). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### accentDesc · The default style tints FluxUI chrome with this accent. Minecraft panel borders keep their original gray pixe… · L42

Source: [AddonOptions/FluxOptionsAppearance.lua:42](../../AddonOptions/FluxOptionsAppearance.lua#L42). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### borderAccent · Accent · L48

Source: [AddonOptions/FluxOptionsAppearance.lua:48](../../AddonOptions/FluxOptionsAppearance.lua#L48). Type: `"select"`.

Class color matches your class. Default atlas leaves atlas-based art untinted, except on WoW Forever where it uses Blizzard's status bar gold. Custom uses the color below.

| Contract | Source expression / implementation |
|---|---|
| values | `{ class = "Class color", atlas = "Default atlas (no tint)", custom = "Custom color", }` [source](../../AddonOptions/FluxOptionsAppearance.lua#L54) |
| get | `function() return FluxOptions.db.profile.appearance.borderAccent or "class" end` [source](../../AddonOptions/FluxOptionsAppearance.lua#L59) |
| set | `function(_, val) FluxOptions.db.profile.appearance.borderAccent = val RefreshAppearance() end` [source](../../AddonOptions/FluxOptionsAppearance.lua#L62) |

### customAccent · Custom accent color · L67

Source: [AddonOptions/FluxOptionsAppearance.lua:67](../../AddonOptions/FluxOptionsAppearance.lua#L67). Type: `"color"`.

Used when Accent is set to Custom.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local c = FluxOptions.db.profile.appearance.customAccent or { r = 1, g = 1, b = 1 } return c.r or 1, c.g or 1, c.b or 1 end` [source](../../AddonOptions/FluxOptionsAppearance.lua#L73) |
| set | `function(_, r, g, b) local c = FluxOptions.db.profile.appearance.customAccent if not c then c = {} FluxOptions.db.profile.appearance.customAccent = c end c.r, c.g, c.b = r, g, b RefreshAppearance() end` [source](../../AddonOptions/FluxOptionsAppearance.lua#L77) |
| hidden | `function() return (FluxOptions.db.profile.appearance.borderAccent or "class") ~= "custom" end` [source](../../AddonOptions/FluxOptionsAppearance.lua#L86) |

## FluxOptionsBattlezone.lua

[AddonOptions/FluxOptionsBattlezone.lua](../../AddonOptions/FluxOptionsBattlezone.lua)

### &lt;anonymous&gt; · FluxWindow · L37

Source: [AddonOptions/FluxOptionsBattlezone.lua:37](../../AddonOptions/FluxOptionsBattlezone.lua#L37). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### headerTabs · Tabs · L42

Source: [AddonOptions/FluxOptionsBattlezone.lua:42](../../AddonOptions/FluxOptionsBattlezone.lua#L42). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### tabsDesc · Drag chips to reorder. Click a chip to turn that tab on or off (at least one must stay on). · L47

Source: [AddonOptions/FluxOptionsBattlezone.lua:47](../../AddonOptions/FluxOptionsBattlezone.lua#L47). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### tabStrip · tabStrip · L53

Source: [AddonOptions/FluxOptionsBattlezone.lua:53](../../AddonOptions/FluxOptionsBattlezone.lua#L53). Type: `"input"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return "" end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L59) |
| set | `function() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L60) |
| dialogControl | `"FluxBattlezoneTabStrip"` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L56) |

### resetTabs · Reset tabs · L62

Source: [AddonOptions/FluxOptionsBattlezone.lua:62](../../AddonOptions/FluxOptionsBattlezone.lua#L62). Type: `"execute"`.

Restore Map → Meter → Respec → Buttons, all enabled.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxWindowFrame and FluxWindowFrame.ResetTabConfigDefaults then FluxWindowFrame:ResetTabConfigDefaults() end local reg = LibStub("AceConfigRegistry-3.0", true) if reg then reg:NotifyChange("FluxUI") end end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L70) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L68) |
| confirmText | `"Reset Flux window tabs to defaults?"` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L69) |

### spacer · spacer · L78

Source: [AddonOptions/FluxOptionsBattlezone.lua:78](../../AddonOptions/FluxOptionsBattlezone.lua#L78). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not HasMeterLayoutBackend() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L82) |

### headerMeter · Meter layout · L86

Source: [AddonOptions/FluxOptionsBattlezone.lua:86](../../AddonOptions/FluxOptionsBattlezone.lua#L86). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not HasMeterLayoutBackend() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L90) |

### meterDesc · function() return MeterLayoutDescription() end · L94

Source: [AddonOptions/FluxOptionsBattlezone.lua:94](../../AddonOptions/FluxOptionsBattlezone.lua#L94). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not HasMeterLayoutBackend() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L101) |

### meterEditor · meterEditor · L105

Source: [AddonOptions/FluxOptionsBattlezone.lua:105](../../AddonOptions/FluxOptionsBattlezone.lua#L105). Type: `"input"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return "" end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L111) |
| set | `function() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L112) |
| hidden | `function() return not HasMeterLayoutBackend() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L113) |
| dialogControl | `"FluxMeterLayoutEmbed"` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L108) |

### noDetails · \|cffAAAAAAMeter layout options appear when Details! is loaded, or when this client ships Blizzard’s damage me… · L117

Source: [AddonOptions/FluxOptionsBattlezone.lua:117](../../AddonOptions/FluxOptionsBattlezone.lua#L117). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return HasMeterLayoutBackend() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L122) |

## FluxOptionsBinding.lua

[AddonOptions/FluxOptionsBinding.lua](../../AddonOptions/FluxOptionsBinding.lua)

### &lt;anonymous&gt; · Binding · L8

Source: [AddonOptions/FluxOptionsBinding.lua:8](../../AddonOptions/FluxOptionsBinding.lua#L8). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### browser · browser · L15

Source: [AddonOptions/FluxOptionsBinding.lua:15](../../AddonOptions/FluxOptionsBinding.lua#L15). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| dialogControl | `"FluxBindingBrowserEmbed"` [source](../../AddonOptions/FluxOptionsBinding.lua#L18) |

## FluxOptionsChat.lua

[AddonOptions/FluxOptionsChat.lua](../../AddonOptions/FluxOptionsChat.lua)

### &lt;anonymous&gt; · name · L27

Source: [AddonOptions/FluxOptionsChat.lua:27](../../AddonOptions/FluxOptionsChat.lua#L27). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = GetCCPDB() return not db or db[key] ~= false end` [source](../../AddonOptions/FluxOptionsChat.lua#L36) |
| set | `function(_, val) local db = GetCCPDB() if not db then return end db[key] = val and true or false NotifyAndRefresh() end` [source](../../AddonOptions/FluxOptionsChat.lua#L40) |
| hidden | `function() return not exists() end` [source](../../AddonOptions/FluxOptionsChat.lua#L33) |

### &lt;anonymous&gt; · Chat · L52

Source: [AddonOptions/FluxOptionsChat.lua:52](../../AddonOptions/FluxOptionsChat.lua#L52). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### intro · Show or hide buttons on the chat column. Hiding FluxUI Options only removes the gear on chat. /fluxui still o… · L57

Source: [AddonOptions/FluxOptionsChat.lua:57](../../AddonOptions/FluxOptionsChat.lua#L57). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### Factory expansions

Arguments select storage keys, unit names, labels, fallback values, ordering, and conditional availability. Follow the corresponding factory definition for the resulting getter/setter contract.

| Site | Factory and arguments |
|---|---|
| [AddonOptions/FluxOptionsChat.lua:64](../../AddonOptions/FluxOptionsChat.lua#L64) | `ButtonToggle("chat_btn_social", "Social", "Friends / quick join button above the chat column.", 10, function() return _G.QuickJoinToastButton ~= nil or _G.FriendsMicroButton ~= nil end)` |
| [AddonOptions/FluxOptionsChat.lua:73](../../AddonOptions/FluxOptionsChat.lua#L73) | `ButtonToggle("chat_btn_channel", "Channels", "Chat channel button.", 20, function() return _G.ChatFrameChannelButton ~= nil end)` |
| [AddonOptions/FluxOptionsChat.lua:82](../../AddonOptions/FluxOptionsChat.lua#L82) | `ButtonToggle("chat_btn_guild", "Guild", "Opens the guild window. Online member count sits under the icon.", 30, function() return _G.FluxCCPChatGuildButton ~= nil end)` |
| [AddonOptions/FluxOptionsChat.lua:91](../../AddonOptions/FluxOptionsChat.lua#L91) | `ButtonToggle("chat_btn_durability", "Character Info", "Full-size Character micro button. Durability percent sits under it.", 40, function() return _G.FluxCCPChatDurabilityButton ~= nil end)` |
| [AddonOptions/FluxOptionsChat.lua:100](../../AddonOptions/FluxOptionsChat.lua#L100) | `ButtonToggle("chat_btn_bags", "Bags", "Full-size Bags micro button. Same tooltip and clicks as the micromenu bags button.", 45, function() return _G.FluxCCPChatBagButton ~= nil end)` |
| [AddonOptions/FluxOptionsChat.lua:109](../../AddonOptions/FluxOptionsChat.lua#L109) | `ButtonToggle("chat_copy", "Copy Chat", "Copy the selected chat window.", 50, function() return _G.FluxCCPChatCopyButton ~= nil end)` |
| [AddonOptions/FluxOptionsChat.lua:118](../../AddonOptions/FluxOptionsChat.lua#L118) | `ButtonToggle("chat_btn_options", "FluxUI Options", "Gear on the chat column. Left-click opens FluxUI options. Right-click opens Blizzard settings.", 60, function() return _G.FluxCCPChatSettingsButton ~= nil end)` |
| [AddonOptions/FluxOptionsChat.lua:127](../../AddonOptions/FluxOptionsChat.lua#L127) | `ButtonToggle("chat_btn_menu", "Chat Menu", "Blizzard chat menu button.", 70, function() return _G.ChatFrameMenuButton ~= nil end)` |

## FluxOptionsGeneral.lua

[AddonOptions/FluxOptionsGeneral.lua](../../AddonOptions/FluxOptionsGeneral.lua)

### &lt;anonymous&gt; · General · L12

Source: [AddonOptions/FluxOptionsGeneral.lua:12](../../AddonOptions/FluxOptionsGeneral.lua#L12). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### header · FluxUI · L17

Source: [AddonOptions/FluxOptionsGeneral.lua:17](../../AddonOptions/FluxOptionsGeneral.lua#L17). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### settingsScope · Settings scope · L22

Source: [AddonOptions/FluxOptionsGeneral.lua:22](../../AddonOptions/FluxOptionsGeneral.lua#L22). Type: `"select"`.

Account-wide shares these settings across all characters. Character-specific lets this character use its own independent settings.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsGeneral.lua#L28) |
| get | `function() return FluxOptions:IsCharacterSpecific() and "character" or "account" end` [source](../../AddonOptions/FluxOptionsGeneral.lua#L33) |
| set | `function(_, val) FluxOptions:SetCharacterSpecific(val == "character") end` [source](../../AddonOptions/FluxOptionsGeneral.lua#L36) |

### scopeDesc · Account-wide shares settings across all characters. Character-specific lets this character override with its … · L40

Source: [AddonOptions/FluxOptionsGeneral.lua:40](../../AddonOptions/FluxOptionsGeneral.lua#L40). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### appearanceHeader · Appearance · L46

Source: [AddonOptions/FluxOptionsGeneral.lua:46](../../AddonOptions/FluxOptionsGeneral.lua#L46). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### appearanceDesc · Accent for FluxUI chrome: unit frames, bars, and borders. This options window uses it for the selected page, … · L51

Source: [AddonOptions/FluxOptionsGeneral.lua:51](../../AddonOptions/FluxOptionsGeneral.lua#L51). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### borderAccent · Accent · L57

Source: [AddonOptions/FluxOptionsGeneral.lua:57](../../AddonOptions/FluxOptionsGeneral.lua#L57). Type: `"select"`.

Class color matches your class. Default atlas leaves atlas-based art untinted (neutral grays), except on WoW Forever where it uses Blizzard's status bar gold. Custom uses the color below. Applies to borders, backdrops, and the on-state of this options window.

| Contract | Source expression / implementation |
|---|---|
| values | `{ class = "Class color", atlas = "Default atlas (no tint)", custom = "Custom color", }` [source](../../AddonOptions/FluxOptionsGeneral.lua#L63) |
| get | `function() return FluxOptions.db.profile.appearance.borderAccent or "class" end` [source](../../AddonOptions/FluxOptionsGeneral.lua#L68) |
| set | `function(_, val) FluxOptions.db.profile.appearance.borderAccent = val RefreshAppearance() end` [source](../../AddonOptions/FluxOptionsGeneral.lua#L71) |

### customAccent · Custom accent color · L76

Source: [AddonOptions/FluxOptionsGeneral.lua:76](../../AddonOptions/FluxOptionsGeneral.lua#L76). Type: `"color"`.

Used when Border accent is set to Custom.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local c = FluxOptions.db.profile.appearance.customAccent or { r = 1, g = 1, b = 1 } return c.r or 1, c.g or 1, c.b or 1 end` [source](../../AddonOptions/FluxOptionsGeneral.lua#L82) |
| set | `function(_, r, g, b) local c = FluxOptions.db.profile.appearance.customAccent if not c then c = {} FluxOptions.db.profile.appearance.customAccent = c end c.r, c.g, c.b = r, g, b RefreshAppearance() end` [source](../../AddonOptions/FluxOptionsGeneral.lua#L86) |
| hidden | `function() return (FluxOptions.db.profile.appearance.borderAccent or "class") ~= "custom" end` [source](../../AddonOptions/FluxOptionsGeneral.lua#L95) |

## FluxOptionsInfo.lua

[AddonOptions/FluxOptionsInfo.lua](../../AddonOptions/FluxOptionsInfo.lua)

### &lt;anonymous&gt; · Info · L38

Source: [AddonOptions/FluxOptionsInfo.lua:38](../../AddonOptions/FluxOptionsInfo.lua#L38). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### intro · FPS, ping, durability, and stats pinned from the character panel. These toggles are always per character. Whe… · L43

Source: [AddonOptions/FluxOptionsInfo.lua:43](../../AddonOptions/FluxOptionsInfo.lua#L43). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### infoShowFPS · Show FPS · L50

Source: [AddonOptions/FluxOptionsInfo.lua:50](../../AddonOptions/FluxOptionsInfo.lua#L50). Type: `"toggle"`.

Display frames per second on the Info panel.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetInfoFrameCharDB().showFPS end` [source](../../AddonOptions/FluxOptionsInfo.lua#L56) |
| set | `function(_, val) GetInfoFrameCharDB().showFPS = val RefreshInfoFrame() end` [source](../../AddonOptions/FluxOptionsInfo.lua#L59) |

### infoShowPing · Show Ping · L64

Source: [AddonOptions/FluxOptionsInfo.lua:64](../../AddonOptions/FluxOptionsInfo.lua#L64). Type: `"toggle"`.

Display world latency on the Info panel.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetInfoFrameCharDB().showPing end` [source](../../AddonOptions/FluxOptionsInfo.lua#L70) |
| set | `function(_, val) GetInfoFrameCharDB().showPing = val RefreshInfoFrame() end` [source](../../AddonOptions/FluxOptionsInfo.lua#L73) |

### infoShowDurability · Show Durability · L78

Source: [AddonOptions/FluxOptionsInfo.lua:78](../../AddonOptions/FluxOptionsInfo.lua#L78). Type: `"toggle"`.

Display average gear durability on the Info panel.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetInfoFrameCharDB().showDurability end` [source](../../AddonOptions/FluxOptionsInfo.lua#L84) |
| set | `function(_, val) GetInfoFrameCharDB().showDurability = val RefreshInfoFrame() end` [source](../../AddonOptions/FluxOptionsInfo.lua#L87) |

### infoResetPinned · Clear pinned stats · L92

Source: [AddonOptions/FluxOptionsInfo.lua:92](../../AddonOptions/FluxOptionsInfo.lua#L92). Type: `"execute"`.

Remove all character stats pinned to the Info panel.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local db = GetInfoFrameCharDB() db.pinnedStats = {} RefreshInfoFrame() end` [source](../../AddonOptions/FluxOptionsInfo.lua#L100) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsInfo.lua#L98) |
| confirmText | `"Remove all pinned stats from the Info panel?"` [source](../../AddonOptions/FluxOptionsInfo.lua#L99) |

### orderHeader · Stat order · L106

Source: [AddonOptions/FluxOptionsInfo.lua:106](../../AddonOptions/FluxOptionsInfo.lua#L106). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### orderDesc · Drag a row to change the order inside the panel. Newly pinned stats are added at the end. · L111

Source: [AddonOptions/FluxOptionsInfo.lua:111](../../AddonOptions/FluxOptionsInfo.lua#L111). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### statOrder · statOrder · L118

Source: [AddonOptions/FluxOptionsInfo.lua:118](../../AddonOptions/FluxOptionsInfo.lua#L118). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| dialogControl | `"FluxInfoStatOrder"` [source](../../AddonOptions/FluxOptionsInfo.lua#L121) |

### slotHeader · Status bar cell · L124

Source: [AddonOptions/FluxOptionsInfo.lua:124](../../AddonOptions/FluxOptionsInfo.lua#L124). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### slotDesc · Used when Layout places the panel on the status bar. Left, between, and right are columns on the horizontal s… · L129

Source: [AddonOptions/FluxOptionsInfo.lua:129](../../AddonOptions/FluxOptionsInfo.lua#L129). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### infoStatusSlot · Cell position · L136

Source: [AddonOptions/FluxOptionsInfo.lua:136](../../AddonOptions/FluxOptionsInfo.lua#L136). Type: `"select"`.

Where the info cell sits among gold, experience, and reputation.

| Contract | Source expression / implementation |
|---|---|
| values | `{ start = "Left", middle = "Between", ["end"] = "Right", }` [source](../../AddonOptions/FluxOptionsInfo.lua#L142) |
| get | `function() if FluxOptions and FluxOptions.GetInfoStatusSlot then return FluxOptions:GetInfoStatusSlot() end return "start" end` [source](../../AddonOptions/FluxOptionsInfo.lua#L148) |
| set | `function(_, val) local d = FluxOptions and FluxOptions.GetLayoutDB and FluxOptions:GetLayoutDB() if d then if val ~= "middle" and val ~= "end" then val = "start" end d.infoStatusSlot = val end if FluxOptions and FluxOptions.RefreshLayoutDependents t…` [source](../../AddonOptions/FluxOptionsInfo.lua#L154) |

## FluxOptionsLayout.lua

[AddonOptions/FluxOptionsLayout.lua](../../AddonOptions/FluxOptionsLayout.lua)

### &lt;anonymous&gt; · Layout · L11

Source: [AddonOptions/FluxOptionsLayout.lua:11](../../AddonOptions/FluxOptionsLayout.lua#L11). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### intro · Click a colored box to move it. Faded tiles are other spots. Gray boxes are reference only. · L16

Source: [AddonOptions/FluxOptionsLayout.lua:16](../../AddonOptions/FluxOptionsLayout.lua#L16). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### layoutScopeHeader · Scope · L23

Source: [AddonOptions/FluxOptionsLayout.lua:23](../../AddonOptions/FluxOptionsLayout.lua#L23). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### layoutSettingsScope · Layout scope · L28

Source: [AddonOptions/FluxOptionsLayout.lua:28](../../AddonOptions/FluxOptionsLayout.lua#L28). Type: `"select"`.

Account-wide or per character. Layout tab only - not Micro Menu size or button order.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsLayout.lua#L34) |
| get | `function() return FluxOptions:IsLayoutCharacterSpecific() and "character" or "account" end` [source](../../AddonOptions/FluxOptionsLayout.lua#L39) |
| set | `function(_, val) FluxOptions:SetLayoutCharacterSpecific(val == "character") NotifyFluxUIConfig() if FluxLayoutPreviewUI and FluxLayoutPreviewUI.DrawPreview then FluxLayoutPreviewUI:DrawPreview() end end` [source](../../AddonOptions/FluxOptionsLayout.lua#L42) |

### resetLayout · Reset layout to defaults · L50

Source: [AddonOptions/FluxOptionsLayout.lua:50](../../AddonOptions/FluxOptionsLayout.lua#L50). Type: `"execute"`.

Reset all layout positions on this tab for the current scope.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxOptions and FluxOptions.ResetLayoutToDefaults then FluxOptions:ResetLayoutToDefaults() end end` [source](../../AddonOptions/FluxOptionsLayout.lua#L58) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsLayout.lua#L56) |
| confirmText | `"Reset layout to defaults?"` [source](../../AddonOptions/FluxOptionsLayout.lua#L57) |

### preview · preview · L64

Source: [AddonOptions/FluxOptionsLayout.lua:64](../../AddonOptions/FluxOptionsLayout.lua#L64). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| dialogControl | `"FluxLayoutPreview"` [source](../../AddonOptions/FluxOptionsLayout.lua#L67) |

## FluxOptionsLoot.lua

[AddonOptions/FluxOptionsLoot.lua](../../AddonOptions/FluxOptionsLoot.lua)

### &lt;anonymous&gt; · Loot · L14

Source: [AddonOptions/FluxOptionsLoot.lua:14](../../AddonOptions/FluxOptionsLoot.lua#L14). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### header · Loot · L17

Source: [AddonOptions/FluxOptionsLoot.lua:17](../../AddonOptions/FluxOptionsLoot.lua#L17). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### fast · Fast loot · L18

Source: [AddonOptions/FluxOptionsLoot.lua:18](../../AddonOptions/FluxOptionsLoot.lua#L18). Type: `"toggle"`.

Pick up loot as soon as it is ready, respecting your Auto Loot modifier. If the separate FasterLoot addon is enabled, it remains in charge; disable that addon to use this switch.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return LootDB().fast end` [source](../../AddonOptions/FluxOptionsLoot.lua#L21) |
| set | `function(_, value) LootDB().fast = value; Changed() end` [source](../../AddonOptions/FluxOptionsLoot.lua#L22) |

### alerts · Show loot at cursor · L24

Source: [AddonOptions/FluxOptionsLoot.lua:24](../../AddonOptions/FluxOptionsLoot.lua#L24). Type: `"toggle"`.

Show a short, non-clickable list next to the cursor when you receive loot.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return LootDB().alerts end` [source](../../AddonOptions/FluxOptionsLoot.lua#L27) |
| set | `function(_, value) LootDB().alerts = value; Changed() end` [source](../../AddonOptions/FluxOptionsLoot.lua#L28) |

### money · Money · L30

Source: [AddonOptions/FluxOptionsLoot.lua:30](../../AddonOptions/FluxOptionsLoot.lua#L30). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return LootDB().money end` [source](../../AddonOptions/FluxOptionsLoot.lua#L33) |
| set | `function(_, value) LootDB().money = value; Changed() end` [source](../../AddonOptions/FluxOptionsLoot.lua#L34) |
| disabled | `function() return not LootDB().alerts end` [source](../../AddonOptions/FluxOptionsLoot.lua#L32) |

### currency · Currency · L36

Source: [AddonOptions/FluxOptionsLoot.lua:36](../../AddonOptions/FluxOptionsLoot.lua#L36). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return LootDB().currency end` [source](../../AddonOptions/FluxOptionsLoot.lua#L39) |
| set | `function(_, value) LootDB().currency = value; Changed() end` [source](../../AddonOptions/FluxOptionsLoot.lua#L40) |
| disabled | `function() return not LootDB().alerts end` [source](../../AddonOptions/FluxOptionsLoot.lua#L38) |

### quality · Minimum item quality · L42

Source: [AddonOptions/FluxOptionsLoot.lua:42](../../AddonOptions/FluxOptionsLoot.lua#L42). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `{ [0] = "All", [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic" }` [source](../../AddonOptions/FluxOptionsLoot.lua#L44) |
| get | `function() return LootDB().quality end` [source](../../AddonOptions/FluxOptionsLoot.lua#L46) |
| set | `function(_, value) LootDB().quality = value; Changed() end` [source](../../AddonOptions/FluxOptionsLoot.lua#L47) |
| disabled | `function() return not LootDB().alerts end` [source](../../AddonOptions/FluxOptionsLoot.lua#L45) |

### duration · Disappear after (seconds) · L49

Source: [AddonOptions/FluxOptionsLoot.lua:49](../../AddonOptions/FluxOptionsLoot.lua#L49). Type: `"range"`.

How long each loot alert stays beside the cursor. Default: 3 seconds.

| Contract | Source expression / implementation |
|---|---|
| min | `2` [source](../../AddonOptions/FluxOptionsLoot.lua#L50) |
| max | `8` [source](../../AddonOptions/FluxOptionsLoot.lua#L50) |
| step | `1` [source](../../AddonOptions/FluxOptionsLoot.lua#L50) |
| get | `function() return LootDB().duration end` [source](../../AddonOptions/FluxOptionsLoot.lua#L53) |
| set | `function(_, value) LootDB().duration = value; Changed() end` [source](../../AddonOptions/FluxOptionsLoot.lua#L54) |
| disabled | `function() return not LootDB().alerts end` [source](../../AddonOptions/FluxOptionsLoot.lua#L52) |

### preview · Preview · L56

Source: [AddonOptions/FluxOptionsLoot.lua:56](../../AddonOptions/FluxOptionsLoot.lua#L56). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxLoot and FluxLoot.Preview then FluxLoot:Preview() end end` [source](../../AddonOptions/FluxOptionsLoot.lua#L59) |
| disabled | `function() return not LootDB().alerts end` [source](../../AddonOptions/FluxOptionsLoot.lua#L58) |

## FluxOptionsMicroMenu.lua

[AddonOptions/FluxOptionsMicroMenu.lua](../../AddonOptions/FluxOptionsMicroMenu.lua)

### [argKey] · skill.name or key · L40

Source: [AddonOptions/FluxOptionsMicroMenu.lua:40](../../AddonOptions/FluxOptionsMicroMenu.lua#L40). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `{ individual = "Individual button", flyout = "In flyout", off = "Off", }` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L45) |
| get | `function() local db = GetTradeSkillDB() if not db or not db.perSkill then return (skill.kind == "primary") and "individual" or "flyout" end local v = db.perSkill[key] if v == "individual" or v == "flyout" or v == "off" then return v end return (skil…` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L51) |
| set | `function(_, val) local db = GetTradeSkillDB() if not db then return end db.perSkill = db.perSkill or {} db.perSkill[key] = val RefreshTradeSkills() end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L62) |

### tsk_none · No learned professions detected yet. · L73

Source: [AddonOptions/FluxOptionsMicroMenu.lua:73](../../AddonOptions/FluxOptionsMicroMenu.lua#L73). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### options · MicroMenu · L85

Source: [AddonOptions/FluxOptionsMicroMenu.lua:85](../../AddonOptions/FluxOptionsMicroMenu.lua#L85). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### intro · Drag buttons in the preview to set order. Use the strip under each icon to cycle Off -&gt; Account -&gt; Character … · L90

Source: [AddonOptions/FluxOptionsMicroMenu.lua:90](../../AddonOptions/FluxOptionsMicroMenu.lua#L90). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### microMenuScopeHeader · Micro menu bar scope · L97

Source: [AddonOptions/FluxOptionsMicroMenu.lua:97](../../AddonOptions/FluxOptionsMicroMenu.lua#L97). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### microMenuSettingsScope · Micro menu bar scope · L102

Source: [AddonOptions/FluxOptionsMicroMenu.lua:102](../../AddonOptions/FluxOptionsMicroMenu.lua#L102). Type: `"select"`.

Account-wide: button size, spacing offset, and drag order (unified list) use the active profile. Character-specific: those three use this character only (account values are copied when you first switch). Does not change Layout tab placement (horizontal vs beside chat). Does not change per-row Off/Account/Character. Independent of General -&gt; Settings scope and independent of the Layout tab's layout scope. Trade skill settings are always character-only.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L108) |
| get | `function() return FluxOptions:IsMicroMenuSettingsCharacterSpecific() and "character" or "account" end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L113) |
| set | `function(_, val) FluxOptions:SetMicroMenuSettingsCharacterSpecific(val == "character") NotifyFluxUIConfig() end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L116) |

### microMenuScopeDesc · Layout tab -&gt; Layout settings scope only affects where the bar sits (and columns for position 2), not this li… · L121

Source: [AddonOptions/FluxOptionsMicroMenu.lua:121](../../AddonOptions/FluxOptionsMicroMenu.lua#L121). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### editor · editor · L128

Source: [AddonOptions/FluxOptionsMicroMenu.lua:128](../../AddonOptions/FluxOptionsMicroMenu.lua#L128). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| dialogControl | `"FluxMicroMenuConfigEmbed"` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L131) |

### tradeSkillsHeader · Trade skills · L135

Source: [AddonOptions/FluxOptionsMicroMenu.lua:135](../../AddonOptions/FluxOptionsMicroMenu.lua#L135). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### tradeSkillsDesc · Learned professions as micromenu buttons (open that trade skill). Default order is just before the Addons (+)… · L140

Source: [AddonOptions/FluxOptionsMicroMenu.lua:140](../../AddonOptions/FluxOptionsMicroMenu.lua#L140). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### tradeSkillsEnabled · Enable trade skill micro buttons · L147

Source: [AddonOptions/FluxOptionsMicroMenu.lua:147](../../AddonOptions/FluxOptionsMicroMenu.lua#L147). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = GetTradeSkillDB() return not db or db.enabled ~= false end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L152) |
| set | `function(_, val) local db = GetTradeSkillDB() if db then db.enabled = val and true or false end RefreshTradeSkills() end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L156) |

### tradeSkillsLayoutMode · Layout mode · L164

Source: [AddonOptions/FluxOptionsMicroMenu.lua:164](../../AddonOptions/FluxOptionsMicroMenu.lua#L164). Type: `"select"`.

Per-profession: choose Individual / In flyout / Off for each learned skill. Fixed split: primary professions as individual buttons; Cooking, Fishing, First Aid, Archaeology, etc. in one flyout. Global: one policy for every skill.

| Contract | Source expression / implementation |
|---|---|
| values | `{ perProfession = "Per-profession", fixedSplit = "Fixed split (primary buttons + secondary flyout)", global = "Global", }` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L170) |
| get | `function() local db = GetTradeSkillDB() return (db and db.layoutMode) or "fixedSplit" end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L176) |
| set | `function(_, val) local db = GetTradeSkillDB() if db then db.layoutMode = val end RefreshTradeSkills() end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L180) |

### tradeSkillsGlobalStyle · Global style · L188

Source: [AddonOptions/FluxOptionsMicroMenu.lua:188](../../AddonOptions/FluxOptionsMicroMenu.lua#L188). Type: `"select"`.

Used when Layout mode is Global. All individual: one button per skill. One flyout: all skills in a single flyout button. Both: every skill as its own button and also listed in the flyout.

| Contract | Source expression / implementation |
|---|---|
| values | `{ allIndividual = "All individual", oneFlyout = "One flyout", both = "Both (buttons + flyout)", }` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L194) |
| get | `function() local db = GetTradeSkillDB() return (db and db.globalStyle) or "allIndividual" end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L204) |
| set | `function(_, val) local db = GetTradeSkillDB() if db then db.globalStyle = val end RefreshTradeSkills() end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L208) |
| hidden | `function() local db = GetTradeSkillDB() return not db or db.layoutMode ~= "global" or db.enabled == false end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L200) |

### tradeSkillsFixedSplitDesc · Fixed split: primary professions appear as individual micro buttons; secondary skills open from the Trade Ski… · L216

Source: [AddonOptions/FluxOptionsMicroMenu.lua:216](../../AddonOptions/FluxOptionsMicroMenu.lua#L216). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() local db = GetTradeSkillDB() return not db or db.layoutMode ~= "fixedSplit" or db.enabled == false end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L222) |

### tradeSkillsPerSkillHeader · Per-profession placement · L227

Source: [AddonOptions/FluxOptionsMicroMenu.lua:227](../../AddonOptions/FluxOptionsMicroMenu.lua#L227). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() local db = GetTradeSkillDB() return not db or db.layoutMode ~= "perProfession" or db.enabled == false end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L231) |

### tradeSkillsPerSkill · tradeSkillsPerSkill · L236

Source: [AddonOptions/FluxOptionsMicroMenu.lua:236](../../AddonOptions/FluxOptionsMicroMenu.lua#L236). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() local db = GetTradeSkillDB() return not db or db.layoutMode ~= "perProfession" or db.enabled == false end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L241) |

### buttonSizeScale · Button size · L247

Source: [AddonOptions/FluxOptionsMicroMenu.lua:247](../../AddonOptions/FluxOptionsMicroMenu.lua#L247). Type: `"range"`.

Uniform scale for every micro menu button. Gold / experience / reputation bars under the menu use the same width as the micro bar, so they stretch or shrink with size and spacing.

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L252) |
| max | `1.5` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L253) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L254) |
| get | `function() local m = FluxOptions:GetMicroMenuDB() return (m and m.buttonSizeScale) or 0.9 end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L256) |
| set | `function(_, val) local m = FluxOptions:GetMicroMenuDB() if m then m.buttonSizeScale = val end FluxOptions:RefreshMicroMenuScopedModules() end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L260) |

### buttonSpacingOffset · Spacing offset · L268

Source: [AddonOptions/FluxOptionsMicroMenu.lua:268](../../AddonOptions/FluxOptionsMicroMenu.lua#L268). Type: `"range"`.

Added on top of the game's default micro button spacing. Lower (more negative) packs icons tighter; higher adds more space between them.

| Contract | Source expression / implementation |
|---|---|
| min | `-12` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L273) |
| max | `16` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L274) |
| step | `1` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L275) |
| get | `function() local m = FluxOptions:GetMicroMenuDB() return (m and m.buttonSpacingOffset) or -2 end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L277) |
| set | `function(_, val) local m = FluxOptions:GetMicroMenuDB() if m then m.buttonSpacingOffset = val end FluxOptions:RefreshMicroMenuScopedModules() end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L281) |

### resetMicroMenuLayout · Reset layout to defaults · L289

Source: [AddonOptions/FluxOptionsMicroMenu.lua:289](../../AddonOptions/FluxOptionsMicroMenu.lua#L289). Type: `"execute"`.

Sets button size to 90% and spacing offset to -2 for the current micro menu bar scope. Does not reset drag order or per-row Off/Account/Character.

| Contract | Source expression / implementation |
|---|---|
| func | `function() FluxOptions:ResetMicroMenuLayoutToDefaults() end` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L297) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L295) |
| confirmText | `"Reset micro menu layout (size and spacing) to defaults for this scope?"` [source](../../AddonOptions/FluxOptionsMicroMenu.lua#L296) |

## FluxOptionsNameplates.lua

[AddonOptions/FluxOptionsNameplates.lua](../../AddonOptions/FluxOptionsNameplates.lua)

### &lt;anonymous&gt; · name · L63

Source: [AddonOptions/FluxOptionsNameplates.lua:63](../../AddonOptions/FluxOptionsNameplates.lua#L63). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local api = ThreatAPI() if api and api.NameplateDisplayEnabled then return api.NameplateDisplayEnabled(key) end return true end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L69) |
| set | `function(_, v) local api = ThreatAPI() if api and api.SetNameplateDisplay then api.SetNameplateDisplay(key, v) end end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L76) |

### headerThreat · Threat · L87

Source: [AddonOptions/FluxOptionsNameplates.lua:87](../../AddonOptions/FluxOptionsNameplates.lua#L87). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### threatDesc · Flux draws a threat-colored border and your threat rank and percent (100% = you have aggro) on enemy NPC name… · L92

Source: [AddonOptions/FluxOptionsNameplates.lua:92](../../AddonOptions/FluxOptionsNameplates.lua#L92). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### visibilityMode · Threat visibility · L98

Source: [AddonOptions/FluxOptionsNameplates.lua:98](../../AddonOptions/FluxOptionsNameplates.lua#L98). Type: `"select"`.

When Flux nameplate threat visuals are shown. Group = party/raid only.

| Contract | Source expression / implementation |
|---|---|
| values | `{ group = "In group only", always = "Always", never = "Never", }` [source](../../AddonOptions/FluxOptionsNameplates.lua#L104) |
| get | `function() return EnsureNameplateThreatDB().visibilityMode or "group" end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L109) |
| set | `function(_, v) if v ~= "always" and v ~= "never" and v ~= "group" then v = "group" end EnsureNameplateThreatDB().visibilityMode = v RefreshNameplatesFromDB() end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L112) |

### npcThreatBorder · NPC threat border + rank/% · L120

Source: [AddonOptions/FluxOptionsNameplates.lua:120](../../AddonOptions/FluxOptionsNameplates.lua#L120). Type: `"toggle"`.

Color the nameplate border from your threat on enemy NPCs and show threat rank and percent under the health bar.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return EnsureNameplateThreatDB().npcThreatBorder ~= false end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L126) |
| set | `function(_, v) EnsureNameplateThreatDB().npcThreatBorder = v and true or false RefreshNameplatesFromDB() end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L129) |

### showNumericThreat · Show threat percentage · L134

Source: [AddonOptions/FluxOptionsNameplates.lua:134](../../AddonOptions/FluxOptionsNameplates.lua#L134). Type: `"toggle"`.

Shows tank-relative threat % (100% = you have aggro) on nameplates and on the Flux target/focus threat bar.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local api = ThreatAPI() if api and api.ShowNumeric then return api.ShowNumeric() end return true end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L140) |
| set | `function(_, v) local api = ThreatAPI() if api and api.SetShowNumeric then api.SetShowNumeric(v) end RefreshNameplatesFromDB() if FluxUnitFrames_ApplyThreatBarOptionsFromDB then FluxUnitFrames_ApplyThreatBarOptionsFromDB() end end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L147) |

### enemyPlayerTarget · Enemy player targeting you · L158

Source: [AddonOptions/FluxOptionsNameplates.lua:158](../../AddonOptions/FluxOptionsNameplates.lua#L158). Type: `"toggle"`.

Red nameplate border when an enemy player is targeting you.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return EnsureNameplateThreatDB().enemyPlayerTarget ~= false end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L164) |
| set | `function(_, v) EnsureNameplateThreatDB().enemyPlayerTarget = v and true or false RefreshNameplatesFromDB() end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L167) |

### headerBlizzardThreat · Blizzard nameplate threat · L172

Source: [AddonOptions/FluxOptionsNameplates.lua:172](../../AddonOptions/FluxOptionsNameplates.lua#L172). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### blizzardThreatDesc · The game's own Progressive / Flash / Health Bar Color threat display (nameplateThreatDisplay). Flux writes th… · L177

Source: [AddonOptions/FluxOptionsNameplates.lua:177](../../AddonOptions/FluxOptionsNameplates.lua#L177). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### threatWarning · Threat warning · L189

Source: [AddonOptions/FluxOptionsNameplates.lua:189](../../AddonOptions/FluxOptionsNameplates.lua#L189). Type: `"select"`.

Blizzard threatWarning CVar (tanking/losing aggro indicator). Off / party / raid / always.

| Contract | Source expression / implementation |
|---|---|
| values | `{ [0] = "Off", [1] = "In party", [2] = "In raid", [3] = "Always", }` [source](../../AddonOptions/FluxOptionsNameplates.lua#L195) |
| get | `function() local api = ThreatAPI() if api and api.GetWarningMode then return api.GetWarningMode() end return 3 end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L206) |
| set | `function(_, v) local api = ThreatAPI() if api and api.SetWarningMode then api.SetWarningMode(v) end end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L213) |
| hidden | `function() local api = ThreatAPI() return not (api and api.HasWarningCVar and api.HasWarningCVar()) end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L202) |

### headerLevel · Level · L223

Source: [AddonOptions/FluxOptionsNameplates.lua:223](../../AddonOptions/FluxOptionsNameplates.lua#L223). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### levelDesc · On Modern nameplate style, Flux shows a smaller "Lvl. N" under the right side of the health bar. · L228

Source: [AddonOptions/FluxOptionsNameplates.lua:228](../../AddonOptions/FluxOptionsNameplates.lua#L228). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### levelOverlayEnabled · Show level overlay (Modern style) · L234

Source: [AddonOptions/FluxOptionsNameplates.lua:234](../../AddonOptions/FluxOptionsNameplates.lua#L234). Type: `"toggle"`.

Flux level text/skull under the health text on Modern-style nameplates. Ignored while the Classic health-bar style is active.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return EnsureNameplateThreatDB().levelOverlayEnabled ~= false end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L240) |
| set | `function(_, v) EnsureNameplateThreatDB().levelOverlayEnabled = v and true or false RefreshNameplatesFromDB() end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L243) |

### countdownHeader · Buff / debuff countdown · L250

Source: [AddonOptions/FluxOptionsNameplates.lua:250](../../AddonOptions/FluxOptionsNameplates.lua#L250). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### aurasDesc · Countdown digits use the same Flux 12px overlay as Classic on every client. Size: edit FLUX_NAMEPLATE_AURA_CO… · L256

Source: [AddonOptions/FluxOptionsNameplates.lua:256](../../AddonOptions/FluxOptionsNameplates.lua#L256). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### &lt;anonymous&gt; · Nameplates · L263

Source: [AddonOptions/FluxOptionsNameplates.lua:263](../../AddonOptions/FluxOptionsNameplates.lua#L263). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### Factory expansions

Arguments select storage keys, unit names, labels, fallback values, ordering, and conditional availability. Follow the corresponding factory definition for the resulting getter/setter contract.

| Site | Factory and arguments |
|---|---|
| [AddonOptions/FluxOptionsNameplates.lua:183](../../AddonOptions/FluxOptionsNameplates.lua#L183) | `BlizzardThreatToggle("Progressive", "Progressive", "Blizzard progressive aggro highlight on enemy nameplates.", 6.2)` |
| [AddonOptions/FluxOptionsNameplates.lua:185](../../AddonOptions/FluxOptionsNameplates.lua#L185) | `BlizzardThreatToggle("Flash", "Flash", "Blizzard aggro flash on enemy nameplates.", 6.3)` |
| [AddonOptions/FluxOptionsNameplates.lua:187](../../AddonOptions/FluxOptionsNameplates.lua#L187) | `BlizzardThreatToggle("HealthBarColor", "Health Bar Color", "Blizzard threat coloring on the nameplate health bar. The Flux border is separate.", 6.4)` |

## FluxOptionsRaidFrame.lua

[AddonOptions/FluxOptionsRaidFrame.lua](../../AddonOptions/FluxOptionsRaidFrame.lua)

### option · Aura icon scale · L59

Source: [AddonOptions/FluxOptionsRaidFrame.lua:59](../../AddonOptions/FluxOptionsRaidFrame.lua#L59). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L64) |
| max | `2.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L64) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L64) |
| get | `function() local maximum = SyncLimit() return max(0.5, min(maximum, tonumber(GetRaidDB().auraIconScale) or 1)) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L66) |
| set | `function(_, val) local maximum = SyncLimit() GetRaidDB().auraIconScale = max(0.5, min(maximum, tonumber(val) or 1)) AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L70) |

### &lt;anonymous&gt; · Party / Raid · L94

Source: [AddonOptions/FluxOptionsRaidFrame.lua:94](../../AddonOptions/FluxOptionsRaidFrame.lua#L94). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### partyStyle · Party frames · L99

Source: [AddonOptions/FluxOptionsRaidFrame.lua:99](../../AddonOptions/FluxOptionsRaidFrame.lua#L99). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### partyAsRaid · Show party as raid frames · L102

Source: [AddonOptions/FluxOptionsRaidFrame.lua:102](../../AddonOptions/FluxOptionsRaidFrame.lua#L102). Type: `"toggle"`.

Use the compact raid layout for parties. Turn off for smaller Flux player-style frames. Raids always keep the raid layout. Both styles share the last member's bottom-right anchor.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L105) |
| set | `function(_, value) SetRaidFlag("partyAsRaid", value) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L106) |

### scale · Party member scale · L108

Source: [AddonOptions/FluxOptionsRaidFrame.lua:108](../../AddonOptions/FluxOptionsRaidFrame.lua#L108). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0.35` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L109) |
| max | `1.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L109) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L109) |
| get | `function() return tonumber(GetRaidDB().partyFrameScale) or 0.55 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L111) |
| set | `function(_, value) GetRaidDB().partyFrameScale = value; AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L112) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L110) |

### portraits · Party portraits · L114

Source: [AddonOptions/FluxOptionsRaidFrame.lua:114](../../AddonOptions/FluxOptionsRaidFrame.lua#L114). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("partyShowPortrait", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L117) |
| set | `function(_, value) SetRaidFlag("partyShowPortrait", value) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L118) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L116) |

### casts · Show party cast bars · L120

Source: [AddonOptions/FluxOptionsRaidFrame.lua:120](../../AddonOptions/FluxOptionsRaidFrame.lua#L120). Type: `"toggle"`.

Show player-style casts and spell icons over each party member's name and level. Disabling hides an active cast; enabling refreshes the current cast. Changes apply outside combat.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("partyShowCastBar", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L124) |
| set | `function(_, value) SetRaidFlag("partyShowCastBar", value) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L125) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L123) |

### pets · Party pets · L127

Source: [AddonOptions/FluxOptionsRaidFrame.lua:127](../../AddonOptions/FluxOptionsRaidFrame.lua#L127). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("partyShowPets", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L130) |
| set | `function(_, value) SetRaidFlag("partyShowPets", value) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L131) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L129) |

### petScale · Party pet scale · L133

Source: [AddonOptions/FluxOptionsRaidFrame.lua:133](../../AddonOptions/FluxOptionsRaidFrame.lua#L133). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0.35` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L134) |
| max | `1.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L134) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L134) |
| get | `function() return tonumber(GetRaidDB().partyPetScale) or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L136) |
| set | `function(_, value) GetRaidDB().partyPetScale = value; AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L137) |
| disabled | `function() return RaidFlag("partyAsRaid", true) or not RaidFlag("partyShowPets", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L135) |

### preview · function() return FluxRaidPreview and FluxRaidPreview.IsPartyShown and FluxRaidPreview.IsPartyShown() and "Hi… · L139

Source: [AddonOptions/FluxOptionsRaidFrame.lua:139](../../AddonOptions/FluxOptionsRaidFrame.lua#L139). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxRaidPreview and FluxRaidPreview.ToggleParty then FluxRaidPreview.ToggleParty() end end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L144) |

### classColor · Class-colored party borders and backdrop · L148

Source: [AddonOptions/FluxOptionsRaidFrame.lua:148](../../AddonOptions/FluxOptionsRaidFrame.lua#L148). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("partyClassColor", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L151) |
| set | `function(_, value) SetRaidFlag("partyClassColor", value) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L152) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L150) |

### targets · Party member targets · L154

Source: [AddonOptions/FluxOptionsRaidFrame.lua:154](../../AddonOptions/FluxOptionsRaidFrame.lua#L154). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("partyShowTargets", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L157) |
| set | `function(_, value) SetRaidFlag("partyShowTargets", value) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L158) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L156) |

### width · Party member width · L160

Source: [AddonOptions/FluxOptionsRaidFrame.lua:160](../../AddonOptions/FluxOptionsRaidFrame.lua#L160). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `.35` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L161) |
| max | `1.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L161) |
| step | `.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L161) |
| get | `function() return tonumber(GetRaidDB().partyWidthScale) or .8 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L163) |
| set | `function(_, value) GetRaidDB().partyWidthScale = value; AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L164) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L162) |

### height · Party member height · L166

Source: [AddonOptions/FluxOptionsRaidFrame.lua:166](../../AddonOptions/FluxOptionsRaidFrame.lua#L166). Type: `"range"`.

Four rows always fit within the current raid column. Member size stays constant as the roster changes.

| Contract | Source expression / implementation |
|---|---|
| min | `.35` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L167) |
| max | `1.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L167) |
| step | `.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L167) |
| get | `function() return tonumber(GetRaidDB().partyHeightScale) or .85 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L170) |
| set | `function(_, value) GetRaidDB().partyHeightScale = value; AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L171) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L169) |

### targetWidth · Party target width · L173

Source: [AddonOptions/FluxOptionsRaidFrame.lua:173](../../AddonOptions/FluxOptionsRaidFrame.lua#L173). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `12` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L174) |
| max | `60` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L174) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L174) |
| get | `function() return tonumber(GetRaidDB().partyTargetWidth) or 30 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L176) |
| set | `function(_, value) GetRaidDB().partyTargetWidth = value; AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L177) |
| disabled | `function() return RaidFlag("partyAsRaid", true) or not RaidFlag("partyShowTargets", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L175) |

### auraScale · Party aura size · L179

Source: [AddonOptions/FluxOptionsRaidFrame.lua:179](../../AddonOptions/FluxOptionsRaidFrame.lua#L179). Type: `"range"`.

Extra size for player-style party auras. The default 1.50 is fifty percent larger than the same raid aura settings.

| Contract | Source expression / implementation |
|---|---|
| min | `.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L180) |
| max | `2.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L180) |
| step | `.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L180) |
| get | `function() return tonumber(GetRaidDB().partyAuraScale) or 1.5 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L183) |
| set | `function(_, value) GetRaidDB().partyAuraScale = value; AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L184) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L182) |

### textScale · Party text size · L186

Source: [AddonOptions/FluxOptionsRaidFrame.lua:186](../../AddonOptions/FluxOptionsRaidFrame.lua#L186). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L187) |
| max | `1.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L187) |
| step | `.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L187) |
| get | `function() return tonumber(GetRaidDB().partyTextScale) or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L189) |
| set | `function(_, value) GetRaidDB().partyTextScale = value; AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L190) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L188) |

### threat · Party threat highlight · L192

Source: [AddonOptions/FluxOptionsRaidFrame.lua:192](../../AddonOptions/FluxOptionsRaidFrame.lua#L192). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("partyThreatHighlight", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L195) |
| set | `function(_, value) SetRaidFlag("partyThreatHighlight", value) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L196) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L194) |

### reset · Reset party sizes · L198

Source: [AddonOptions/FluxOptionsRaidFrame.lua:198](../../AddonOptions/FluxOptionsRaidFrame.lua#L198). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local defaults = FluxOptionsDefaults.profile.raidFrames for _, key in ipairs({"partyFrameScale", "partyWidthScale", "partyHeightScale", "partyPetScale", "partyTargetWidth", "partyAuraScale", "partyTextScale", "partyPowerHeightScale"}) do …` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L201) |

### powerHeight · Party resource height · L209

Source: [AddonOptions/FluxOptionsRaidFrame.lua:209](../../AddonOptions/FluxOptionsRaidFrame.lua#L209). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L210) |
| max | `1.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L210) |
| step | `.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L210) |
| get | `function() return tonumber(GetRaidDB().partyPowerHeightScale) or .8 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L212) |
| set | `function(_, value) GetRaidDB().partyPowerHeightScale = value; AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L213) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L211) |

### healthText · Party HP text · L215

Source: [AddonOptions/FluxOptionsRaidFrame.lua:215](../../AddonOptions/FluxOptionsRaidFrame.lua#L215). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `{values = "Values", percent = "Percent", both = "Values and percent", none = "Hidden"}` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L217) |
| get | `function() return GetRaidDB().partyHealthText or "values" end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L219) |
| set | `function(_, value) GetRaidDB().partyHealthText = value; AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L220) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L218) |

### powerText · Party resource text · L222

Source: [AddonOptions/FluxOptionsRaidFrame.lua:222](../../AddonOptions/FluxOptionsRaidFrame.lua#L222). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `{values = "Values", percent = "Percent", both = "Values and percent", none = "Hidden"}` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L224) |
| get | `function() return GetRaidDB().partyPowerText or "percent" end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L226) |
| set | `function(_, value) GetRaidDB().partyPowerText = value; AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L227) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L225) |

### targetClassColor · Class-colored party target HP · L229

Source: [AddonOptions/FluxOptionsRaidFrame.lua:229](../../AddonOptions/FluxOptionsRaidFrame.lua#L229). Type: `"toggle"`.

Use class color only when the party member's target is a player. NPC targets keep their usual color.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("partyTargetClassColor", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L233) |
| set | `function(_, value) SetRaidFlag("partyTargetClassColor", value) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L234) |
| disabled | `function() return RaidFlag("partyAsRaid", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L232) |

### masterHeader · Names · L238

Source: [AddonOptions/FluxOptionsRaidFrame.lua:238](../../AddonOptions/FluxOptionsRaidFrame.lua#L238). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### nameUseClassColor · Class-colored names · L243

Source: [AddonOptions/FluxOptionsRaidFrame.lua:243](../../AddonOptions/FluxOptionsRaidFrame.lua#L243). Type: `"toggle"`.

Color player names by class on Flux compact frames. Off keeps names white. Health bar class colors use Class colors below.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().nameUseClassColor == true end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L248) |
| set | `function(_, val) GetRaidDB().nameUseClassColor = val and true or false AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L251) |

### previewGroup · World Preview · L259

Source: [AddonOptions/FluxOptionsRaidFrame.lua:259](../../AddonOptions/FluxOptionsRaidFrame.lua#L259). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### desc · Shows a full-size preview of Flux raid frames in the game world. In a party or raid the first slots mirror re… · L265

Source: [AddonOptions/FluxOptionsRaidFrame.lua:265](../../AddonOptions/FluxOptionsRaidFrame.lua#L265). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### toggle · Show / Hide Preview · L271

Source: [AddonOptions/FluxOptionsRaidFrame.lua:271](../../AddonOptions/FluxOptionsRaidFrame.lua#L271). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxRaidPreview and FluxRaidPreview.Toggle then FluxRaidPreview.Toggle() end end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L276) |

### rosterSize · Roster size · L282

Source: [AddonOptions/FluxOptionsRaidFrame.lua:282](../../AddonOptions/FluxOptionsRaidFrame.lua#L282). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `{ ["5"] = "5", ["10"] = "10", ["15"] = "15", ["20"] = "20", ["25"] = "25", ["30"] = "30", ["35"] = "35", ["40"] = "40", }` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L287) |
| get | `function() local n = tonumber(GetRaidDB().previewRosterSize) or 40 return tostring(max(5, min(40, floor(n / 5) * 5))) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L292) |
| set | `function(_, val) GetRaidDB().previewRosterSize = tonumber(val) or 40 AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L296) |

### showMT · Show MT column · L301

Source: [AddonOptions/FluxOptionsRaidFrame.lua:301](../../AddonOptions/FluxOptionsRaidFrame.lua#L301). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().previewShowMTColumn ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L306) |
| set | `function(_, val) GetRaidDB().previewShowMTColumn = val and true or false AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L309) |

### mtCount · MT slots · L314

Source: [AddonOptions/FluxOptionsRaidFrame.lua:314](../../AddonOptions/FluxOptionsRaidFrame.lua#L314). Type: `"range"`.

How many MT/MA-style frames appear in the MT column.

| Contract | Source expression / implementation |
|---|---|
| min | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L319) |
| max | `8` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L319) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L319) |
| get | `function() local n = tonumber(GetRaidDB().previewMainTankCount) if not n or n &lt; 1 then n = 2 end return max(1, min(8, floor(n))) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L321) |
| set | `function(_, val) GetRaidDB().previewMainTankCount = max(1, min(8, floor(val))) AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L326) |

### auraSpacer · Demo Auras · L331

Source: [AddonOptions/FluxOptionsRaidFrame.lua:331](../../AddonOptions/FluxOptionsRaidFrame.lua#L331). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### showBuffs · Buffs · L336

Source: [AddonOptions/FluxOptionsRaidFrame.lua:336](../../AddonOptions/FluxOptionsRaidFrame.lua#L336). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().previewDemoBuffsEnabled ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L341) |
| set | `function(_, val) GetRaidDB().previewDemoBuffsEnabled = val and true or false AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L344) |

### buffCount · Buff count · L349

Source: [AddonOptions/FluxOptionsRaidFrame.lua:349](../../AddonOptions/FluxOptionsRaidFrame.lua#L349). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L353) |
| max | `6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L353) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L353) |
| get | `function() return tonumber(GetRaidDB().previewBuffCount) or 3 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L355) |
| set | `function(_, val) GetRaidDB().previewBuffCount = val AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L358) |

### showDebuffs · Debuffs · L363

Source: [AddonOptions/FluxOptionsRaidFrame.lua:363](../../AddonOptions/FluxOptionsRaidFrame.lua#L363). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().previewDemoDebuffsEnabled ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L368) |
| set | `function(_, val) GetRaidDB().previewDemoDebuffsEnabled = val and true or false AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L371) |

### debuffCount · Debuff count · L376

Source: [AddonOptions/FluxOptionsRaidFrame.lua:376](../../AddonOptions/FluxOptionsRaidFrame.lua#L376). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L380) |
| max | `6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L380) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L380) |
| get | `function() return tonumber(GetRaidDB().previewDebuffCount) or 5 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L382) |
| set | `function(_, val) GetRaidDB().previewDebuffCount = val AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L385) |

### sizingHeader · Frame sizing (Flux) · L396

Source: [AddonOptions/FluxOptionsRaidFrame.lua:396](../../AddonOptions/FluxOptionsRaidFrame.lua#L396). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### memberWidthScale · Member frame width scale · L401

Source: [AddonOptions/FluxOptionsRaidFrame.lua:401](../../AddonOptions/FluxOptionsRaidFrame.lua#L401). Type: `"range"`.

1.00 uses Blizzard's default unit-frame width.

| Contract | Source expression / implementation |
|---|---|
| min | `0.6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L406) |
| max | `1.4` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L406) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L406) |
| get | `function() return GetRaidDB().memberWidthScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L408) |
| set | `function(_, val) GetRaidDB().memberWidthScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L411) |

### frameHeightScale · Member frame height scale · L416

Source: [AddonOptions/FluxOptionsRaidFrame.lua:416](../../AddonOptions/FluxOptionsRaidFrame.lua#L416). Type: `"range"`.

1.00 uses Blizzard's default unit-frame height.

| Contract | Source expression / implementation |
|---|---|
| min | `0.8` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L421) |
| max | `1.6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L421) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L421) |
| get | `function() return GetRaidDB().frameHeightScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L423) |
| set | `function(_, val) GetRaidDB().frameHeightScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L426) |

### powerBarHeightScale · Power bar height scale · L431

Source: [AddonOptions/FluxOptionsRaidFrame.lua:431](../../AddonOptions/FluxOptionsRaidFrame.lua#L431). Type: `"range"`.

1.00 uses Blizzard's default resource-strip height. Scales independently of member frame height.

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L436) |
| max | `2.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L436) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L436) |
| get | `function() return GetRaidDB().powerBarHeightScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L438) |
| set | `function(_, val) GetRaidDB().powerBarHeightScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L441) |

### auraWidthScale · Aura width (X) · L447

Source: [AddonOptions/FluxOptionsRaidFrame.lua:447](../../AddonOptions/FluxOptionsRaidFrame.lua#L447). Type: `"range"`.

Changes aura width independently of height. 1.00 is Blizzard's width. Updates live icons out of combat when native configuration is allowed; otherwise the change waits until safe.

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L450) |
| max | `2.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L450) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L450) |
| get | `function() return GetRaidDB().auraWidthScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L451) |
| set | `function(_, value) GetRaidDB().auraWidthScale = max(0.5, min(2.5, tonumber(value) or 1)); AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L452) |

### auraDurationFontScale · Aura duration text size · L454

Source: [AddonOptions/FluxOptionsRaidFrame.lua:454](../../AddonOptions/FluxOptionsRaidFrame.lua#L454). Type: `"range"`.

Scales the fitted duration font independently of icon size. 1.00 keeps the default font size. Updates preview and live aura timers out of combat; combat changes apply when combat ends.

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L457) |
| max | `2.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L457) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L457) |
| get | `function() return GetRaidDB().auraDurationFontScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L458) |
| set | `function(_, value) GetRaidDB().auraDurationFontScale = max(0.5, min(2.5, tonumber(value) or 1)); AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L459) |

### auraTimersUnderMinute · Show aura timers only below 1 minute · L461

Source: [AddonOptions/FluxOptionsRaidFrame.lua:461](../../AddonOptions/FluxOptionsRaidFrame.lua#L461). Type: `"toggle"`.

Applies to raid and party shown as raid frames. Show numbers only below 60 seconds; icons, swipes and stacks remain. Normal party, target and focus use Unit Frames &gt; General.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("auraTimersUnderMinute", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L464) |
| set | `function(_, value) SetRaidFlag("auraTimersUnderMinute", value) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L465) |

### raidManagerScale · Raid manager strip scale · L467

Source: [AddonOptions/FluxOptionsRaidFrame.lua:467](../../AddonOptions/FluxOptionsRaidFrame.lua#L467). Type: `"range"`.

Left raid tools / markers strip. 1.00 uses a compact baseline that is 30% smaller than Blizzard's manager.

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L472) |
| max | `1.2` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L472) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L472) |
| get | `function() return GetRaidDB().raidManagerScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L474) |
| set | `function(_, val) GetRaidDB().raidManagerScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L477) |

### resetSizes · Reset sizes · L482

Source: [AddonOptions/FluxOptionsRaidFrame.lua:482](../../AddonOptions/FluxOptionsRaidFrame.lua#L482). Type: `"execute"`.

Restores the default sizing preset and under-one-minute aura timer display. Aura filters, counts and transparency stay configured.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local db = GetRaidDB() local defaults = FluxOptionsDefaults.profile.raidFrames for _, key in ipairs({ "memberWidthScale", "frameHeightScale", "powerBarHeightScale", "auraIconScale", "auraWidthScale", "auraDurationFontScale", "raidManagerS…` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L487) |

### transparencyHeader · Transparency (Flux) · L501

Source: [AddonOptions/FluxOptionsRaidFrame.lua:501](../../AddonOptions/FluxOptionsRaidFrame.lua#L501). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### transparencyDesc · Frame opacity applies to the visible cell content. In-range and out-of-range multipliers apply when Fade out … · L506

Source: [AddonOptions/FluxOptionsRaidFrame.lua:506](../../AddonOptions/FluxOptionsRaidFrame.lua#L506). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### frameBaseAlpha · Frame base opacity · L512

Source: [AddonOptions/FluxOptionsRaidFrame.lua:512](../../AddonOptions/FluxOptionsRaidFrame.lua#L512). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0.2` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L516) |
| max | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L516) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L516) |
| get | `function() return tonumber(GetRaidDB().frameBaseAlpha) or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L518) |
| set | `function(_, val) GetRaidDB().frameBaseAlpha = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L521) |

### rangeAlphaInRange · Opacity when in range · L526

Source: [AddonOptions/FluxOptionsRaidFrame.lua:526](../../AddonOptions/FluxOptionsRaidFrame.lua#L526). Type: `"range"`.

Used when Fade out of range is on. Multiplied by frame base opacity.

| Contract | Source expression / implementation |
|---|---|
| min | `0.2` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L531) |
| max | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L531) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L531) |
| get | `function() return tonumber(GetRaidDB().rangeAlphaInRange) or 0.9 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L533) |
| set | `function(_, val) GetRaidDB().rangeAlphaInRange = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L536) |

### rangeAlphaOutOfRange · Opacity when out of range / offline · L541

Source: [AddonOptions/FluxOptionsRaidFrame.lua:541](../../AddonOptions/FluxOptionsRaidFrame.lua#L541). Type: `"range"`.

Used when Fade out of range is on. Multiplied by frame base opacity.

| Contract | Source expression / implementation |
|---|---|
| min | `0.1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L546) |
| max | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L546) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L546) |
| get | `function() return tonumber(GetRaidDB().rangeAlphaOutOfRange) or 0.44 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L548) |
| set | `function(_, val) GetRaidDB().rangeAlphaOutOfRange = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L551) |

### auraIconAlpha · Aura transparency · L556

Source: [AddonOptions/FluxOptionsRaidFrame.lua:556](../../AddonOptions/FluxOptionsRaidFrame.lua#L556). Type: `"range"`.

Transparency of buff/debuff icons, duration text and cooldown overlays. 0% is fully visible; 100% is invisible. The starting value is 70%.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L561) |
| max | `100` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L561) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L561) |
| get | `function() local db=GetRaidDB() local value=tonumber(db.auraTransparency) if value==nil then value=100*(1-max(0.1,min(1,tonumber(db.auraIconAlpha) or 1))*0.3) end return max(0,min(100,value)) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L563) |
| set | `function(_, val) GetRaidDB().auraTransparency = max(0,min(100,tonumber(val) or 70)) AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L569) |

### dispelHeader · Dispel Highlight · L578

Source: [AddonOptions/FluxOptionsRaidFrame.lua:578](../../AddonOptions/FluxOptionsRaidFrame.lua#L578). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### showDispelHighlight · Dispel highlight border · L583

Source: [AddonOptions/FluxOptionsRaidFrame.lua:583](../../AddonOptions/FluxOptionsRaidFrame.lua#L583). Type: `"toggle"`.

Shows a type-colored border when a party/raid member has a debuff your class can dispel (e.g. Curse only if you have Remove Curse). Matches Blizzard Dispellable By Me.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().showDispelHighlight ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L589) |
| set | `function(_, val) GetRaidDB().showDispelHighlight = val and true or false AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L592) |

### highlightHeader · Highlights · L598

Source: [AddonOptions/FluxOptionsRaidFrame.lua:598](../../AddonOptions/FluxOptionsRaidFrame.lua#L598). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### showAggroHighlight · Aggro highlight · L603

Source: [AddonOptions/FluxOptionsRaidFrame.lua:603](../../AddonOptions/FluxOptionsRaidFrame.lua#L603). Type: `"toggle"`.

Shows the aggro ring when a member has threat.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showAggroHighlight", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L608) |
| set | `function(_, val) SetRaidFlag("showAggroHighlight", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L609) |

### showTargetHighlight · Target highlight · L611

Source: [AddonOptions/FluxOptionsRaidFrame.lua:611](../../AddonOptions/FluxOptionsRaidFrame.lua#L611). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showTargetHighlight", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L615) |
| set | `function(_, val) SetRaidFlag("showTargetHighlight", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L616) |

### showMouseoverHighlight · Mouseover highlight · L618

Source: [AddonOptions/FluxOptionsRaidFrame.lua:618](../../AddonOptions/FluxOptionsRaidFrame.lua#L618). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showMouseoverHighlight", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L622) |
| set | `function(_, val) SetRaidFlag("showMouseoverHighlight", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L623) |

### showRoleIcon · Role icons · L625

Source: [AddonOptions/FluxOptionsRaidFrame.lua:625](../../AddonOptions/FluxOptionsRaidFrame.lua#L625). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showRoleIcon", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L629) |
| set | `function(_, val) SetRaidFlag("showRoleIcon", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L630) |

### showGroupLabels · Group labels · L632

Source: [AddonOptions/FluxOptionsRaidFrame.lua:632](../../AddonOptions/FluxOptionsRaidFrame.lua#L632). Type: `"toggle"`.

Party and group numbers above each column.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showGroupLabels", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L637) |
| set | `function(_, val) SetRaidFlag("showGroupLabels", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L638) |

### showRangeFade · Fade out of range · L640

Source: [AddonOptions/FluxOptionsRaidFrame.lua:640](../../AddonOptions/FluxOptionsRaidFrame.lua#L640). Type: `"toggle"`.

Uses the in-range and out-of-range opacity sliders.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showRangeFade", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L645) |
| set | `function(_, val) SetRaidFlag("showRangeFade", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L646) |

### showClassBuffs · Class buffs out of combat · L648

Source: [AddonOptions/FluxOptionsRaidFrame.lua:648](../../AddonOptions/FluxOptionsRaidFrame.lua#L648). Type: `"toggle"`.

Shows buffs currently present on party/raid members while out of combat, including long-duration class buffs.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showClassBuffs", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L653) |
| set | `function(_, val) SetRaidFlag("showClassBuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L654) |

### showMissingClassBuffs · Missing class buffs · L656

Source: [AddonOptions/FluxOptionsRaidFrame.lua:656](../../AddonOptions/FluxOptionsRaidFrame.lua#L656). Type: `"toggle"`.

Out of combat, show up to three dim icons for learned class buffs missing from a member. Restricted or unavailable aura data shows no missing-buff claim.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showMissingClassBuffs", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L661) |
| set | `function(_, val) SetRaidFlag("showMissingClassBuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L662) |

### showPets · Party / raid pets · L664

Source: [AddonOptions/FluxOptionsRaidFrame.lua:664](../../AddonOptions/FluxOptionsRaidFrame.lua#L664). Type: `"toggle"`.

Adds half-height pet cells beside the existing grid. Requires working secure visibility support. Existing member positions and sizes stay the same.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showPets", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L669) |
| set | `function(_, val) SetRaidFlag("showPets", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L670) |

### showFriendlyTarget · Friendly target · L672

Source: [AddonOptions/FluxOptionsRaidFrame.lua:672](../../AddonOptions/FluxOptionsRaidFrame.lua#L672). Type: `"toggle"`.

Adds a friendly-target cell beside the party/raid grid, above optional pets. Hostile or missing targets hide securely. Existing member positions stay the same.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showFriendlyTarget", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L677) |
| set | `function(_, val) SetRaidFlag("showFriendlyTarget", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L678) |

### showEstimatedHoTs · Estimate my remaining HoT healing (Forever) · L680

Source: [AddonOptions/FluxOptionsRaidFrame.lua:680](../../AddonOptions/FluxOptionsRaidFrame.lua#L680). Type: `"toggle"`.

Optional estimate from your own successful casts and readable learned English spell descriptions. It cannot detect every dispel, refresh or modifier and does not replace native heal prediction. Unavailable or restricted data shows no estimate.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showEstimatedHoTs", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L690) |
| set | `function(_, val) SetRaidFlag("showEstimatedHoTs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L691) |
| disabled | `function() if FluxRaidHoTs and FluxRaidHoTs.IsSupported then return not FluxRaidHoTs.IsSupported() end local client = ns.Flux and ns.Flux.Client return not (client and (client.isForever or client.isCamelot)) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L685) |

### displayHeader · Bars and auras · L694

Source: [AddonOptions/FluxOptionsRaidFrame.lua:694](../../AddonOptions/FluxOptionsRaidFrame.lua#L694). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### useClassColors · Class colors · L699

Source: [AddonOptions/FluxOptionsRaidFrame.lua:699](../../AddonOptions/FluxOptionsRaidFrame.lua#L699). Type: `"toggle"`.

Class-colored health bars. Names stay on the setting above.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("useClassColors", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L704) |
| set | `function(_, val) SetRaidFlag("useClassColors", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L705) |

### displayPowerBar · Power bars · L707

Source: [AddonOptions/FluxOptionsRaidFrame.lua:707](../../AddonOptions/FluxOptionsRaidFrame.lua#L707). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayPowerBar", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L711) |
| set | `function(_, val) SetRaidFlag("displayPowerBar", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L712) |

### showHealPrediction · Heal prediction · L714

Source: [AddonOptions/FluxOptionsRaidFrame.lua:714](../../AddonOptions/FluxOptionsRaidFrame.lua#L714). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showHealPrediction", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L718) |
| set | `function(_, val) SetRaidFlag("showHealPrediction", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L719) |

### healthText · Health text · L721

Source: [AddonOptions/FluxOptionsRaidFrame.lua:721](../../AddonOptions/FluxOptionsRaidFrame.lua#L721). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `healthTextValues` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L725) |
| get | `function() local v = GetRaidDB().healthText if v ~= "none" and v ~= "health" and v ~= "perc" and v ~= "healthandpercent" then return "perc" end return v end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L727) |
| set | `function(_, val) if val ~= "none" and val ~= "health" and val ~= "perc" and val ~= "healthandpercent" then val = "perc" end GetRaidDB().healthText = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L734) |

### displayBuffs · Show buffs · L742

Source: [AddonOptions/FluxOptionsRaidFrame.lua:742](../../AddonOptions/FluxOptionsRaidFrame.lua#L742). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayBuffs", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L746) |
| set | `function(_, val) SetRaidFlag("displayBuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L747) |

### displayDebuffs · Show debuffs · L749

Source: [AddonOptions/FluxOptionsRaidFrame.lua:749](../../AddonOptions/FluxOptionsRaidFrame.lua#L749). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayDebuffs", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L753) |
| set | `function(_, val) SetRaidFlag("displayDebuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L754) |

### maxBuffs · Maximum buffs · L756

Source: [AddonOptions/FluxOptionsRaidFrame.lua:756](../../AddonOptions/FluxOptionsRaidFrame.lua#L756). Type: `"range"`.

Maximum buff icons per party or raid member.

| Contract | Source expression / implementation |
|---|---|
| min | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L761) |
| max | `6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L761) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L761) |
| get | `function() return max(1, min(6, floor(tonumber(GetRaidDB().maxBuffs) or 6))) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L762) |
| set | `function(_, val) GetRaidDB().maxBuffs = max(1, min(6, floor(tonumber(val) or 6))) AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L763) |

### maxDebuffs · Maximum debuffs · L768

Source: [AddonOptions/FluxOptionsRaidFrame.lua:768](../../AddonOptions/FluxOptionsRaidFrame.lua#L768). Type: `"range"`.

Maximum debuff icons per party or raid member.

| Contract | Source expression / implementation |
|---|---|
| min | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L773) |
| max | `6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L773) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L773) |
| get | `function() return max(1, min(6, floor(tonumber(GetRaidDB().maxDebuffs) or 6))) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L774) |
| set | `function(_, val) GetRaidDB().maxDebuffs = max(1, min(6, floor(tonumber(val) or 6))) AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L775) |

### auraFocusMode · Aura focus · L780

Source: [AddonOptions/FluxOptionsRaidFrame.lua:780](../../AddonOptions/FluxOptionsRaidFrame.lua#L780). Type: `"select"`.

Debuff focused: more debuff slots. Buff focused: more buff slots along the top.

| Contract | Source expression / implementation |
|---|---|
| values | `{ debuff = "Debuff focused", buff = "Buff focused", }` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L785) |
| get | `function() local v = GetRaidDB().auraFocusMode if v == "buff" then return "buff" end return "debuff" end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L789) |
| set | `function(_, val) GetRaidDB().auraFocusMode = (val == "buff") and "buff" or "debuff" AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L794) |

### displayOnlyDispellableDebuffs · Only dispellable debuffs · L799

Source: [AddonOptions/FluxOptionsRaidFrame.lua:799](../../AddonOptions/FluxOptionsRaidFrame.lua#L799). Type: `"toggle"`.

Limits debuff icons to auras your class can dispel.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayOnlyDispellableDebuffs", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L804) |
| set | `function(_, val) SetRaidFlag("displayOnlyDispellableDebuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L805) |

## FluxOptionsRender.lua

[AddonOptions/FluxOptionsRender.lua](../../AddonOptions/FluxOptionsRender.lua)

### headerOpt · title · L698

Source: [AddonOptions/FluxOptionsRender.lua:698](../../AddonOptions/FluxOptionsRender.lua#L698). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

## FluxOptionsSalvage.lua

[AddonOptions/FluxOptionsSalvage.lua](../../AddonOptions/FluxOptionsSalvage.lua)

### &lt;anonymous&gt; · Salvage · L22

Source: [AddonOptions/FluxOptionsSalvage.lua:22](../../AddonOptions/FluxOptionsSalvage.lua#L22). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### intro · One-click milling, prospecting, disenchanting, Comprehend Scroll, lockpicking, and more. " .. "Hold the modif… · L27

Source: [AddonOptions/FluxOptionsSalvage.lua:27](../../AddonOptions/FluxOptionsSalvage.lua#L27). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### enabled · Enable salvage overlay · L36

Source: [AddonOptions/FluxOptionsSalvage.lua:36](../../AddonOptions/FluxOptionsSalvage.lua#L36). Type: `"toggle"`.

Show the one-click salvage overlay when holding the modifier key over bag items.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local S = _G.FluxSalvage return S and S.IsEnabled() or false end` [source](../../AddonOptions/FluxOptionsSalvage.lua#L42) |
| set | `function(_, val) local S = _G.FluxSalvage if not S then return end S.SetEnabled(val) NotifySalvageSettingsChanged() end` [source](../../AddonOptions/FluxOptionsSalvage.lua#L46) |

### modifier · Modifier key · L55

Source: [AddonOptions/FluxOptionsSalvage.lua:55](../../AddonOptions/FluxOptionsSalvage.lua#L55). Type: `"select"`.

Hold this key combination while hovering a bag item to activate salvage.

| Contract | Source expression / implementation |
|---|---|
| values | `{ ALT = ALT_KEY or "Alt", CTRL = (ALT_KEY_TEXT or "Alt") .. " + " .. (CTRL_KEY or "Ctrl"), SHIFT = (ALT_KEY_TEXT or "Alt") .. " + " .. (SHIFT_KEY or "Shift"), }` [source](../../AddonOptions/FluxOptionsSalvage.lua#L61) |
| get | `function() local S = _G.FluxSalvage return S and S.GetModifier() or "ALT" end` [source](../../AddonOptions/FluxOptionsSalvage.lua#L66) |
| set | `function(_, val) local S = _G.FluxSalvage if not S then return end S.SetModifier(val) end` [source](../../AddonOptions/FluxOptionsSalvage.lua#L70) |

## FluxOptionsStatusBars.lua

[AddonOptions/FluxOptionsStatusBars.lua](../../AddonOptions/FluxOptionsStatusBars.lua)

### statusBarsOptions · Status Bars · L24

Source: [AddonOptions/FluxOptionsStatusBars.lua:24](../../AddonOptions/FluxOptionsStatusBars.lua#L24). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### intro · Gold, experience, and reputation strips share one height. Layout placement (under menu vs bottom strip) stays… · L29

Source: [AddonOptions/FluxOptionsStatusBars.lua:29](../../AddonOptions/FluxOptionsStatusBars.lua#L29). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### scopeHeader · Status bar scope · L36

Source: [AddonOptions/FluxOptionsStatusBars.lua:36](../../AddonOptions/FluxOptionsStatusBars.lua#L36). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### statusBarsSettingsScope · Status bar settings scope · L41

Source: [AddonOptions/FluxOptionsStatusBars.lua:41](../../AddonOptions/FluxOptionsStatusBars.lua#L41). Type: `"select"`.

Account-wide: currency strip on/off and bar height use the active profile. Character-specific: those use this character only (account values are copied when you first switch). Independent of General -&gt; Settings scope.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L47) |
| get | `function() return FluxOptions:IsStatusBarsCharacterSpecific() and "character" or "account" end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L52) |
| set | `function(_, val) FluxOptions:SetStatusBarsCharacterSpecific(val == "character") NotifyFluxUIConfig() end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L55) |

### showCurrencyBar · Show currency (gold) bar · L60

Source: [AddonOptions/FluxOptionsStatusBars.lua:60](../../AddonOptions/FluxOptionsStatusBars.lua#L60). Type: `"toggle"`.

When off, the gold strip is hidden. Experience and reputation strips still show when applicable.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = FluxOptions:GetStatusBarSettingsDB() if d and d.showCurrencyBar == false then return false end return true end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L66) |
| set | `function(_, val) local d = FluxOptions:GetStatusBarSettingsDB() if d then d.showCurrencyBar = val and true or false end FluxOptions:RefreshStatusBarScopedModules() end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L73) |

### hideExpBarAtMaxLevel · Hide experience bar when not gaining XP · L81

Source: [AddonOptions/FluxOptionsStatusBars.lua:81](../../AddonOptions/FluxOptionsStatusBars.lua#L81). Type: `"toggle"`.

When on, the experience strip is removed whenever the game would hide the default XP bar (for example at max level). When off, Flux can still show the gray Max Level strip if you are not watching a faction, so you can click it to open Reputation.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = FluxOptions:GetStatusBarSettingsDB() return d and d.hideExpBarAtMaxLevel and true or false end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L87) |
| set | `function(_, val) local d = FluxOptions:GetStatusBarSettingsDB() if d then d.hideExpBarAtMaxLevel = val and true or false end FluxOptions:RefreshStatusBarScopedModules() end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L91) |

### barHeight · Bar height · L99

Source: [AddonOptions/FluxOptionsStatusBars.lua:99](../../AddonOptions/FluxOptionsStatusBars.lua#L99). Type: `"range"`.

Pixel height for gold, experience, and reputation strips (shared).

| Contract | Source expression / implementation |
|---|---|
| min | `10` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L104) |
| max | `40` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L105) |
| step | `1` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L106) |
| get | `function() local d = FluxOptions:GetStatusBarSettingsDB() local h = d and d.barHeight if type(h) == "number" and h == h then return h end return 18 end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L108) |
| set | `function(_, val) local d = FluxOptions:GetStatusBarSettingsDB() if d then d.barHeight = val end FluxOptions:RefreshStatusBarScopedModules() end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L116) |

### resetStatusBars · Reset status bar options to defaults · L124

Source: [AddonOptions/FluxOptionsStatusBars.lua:124](../../AddonOptions/FluxOptionsStatusBars.lua#L124). Type: `"execute"`.

Restores currency strip on, default height, hide-XP-bar default, and item currency fields for the current status bar scope.

| Contract | Source expression / implementation |
|---|---|
| func | `function() FluxOptions:ResetStatusBarsToDefaults() end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L132) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L130) |
| confirmText | `"Reset status bar strip options to defaults for this scope?"` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L131) |

### pvpHeader · Honor & Arena on status bar · L136

Source: [AddonOptions/FluxOptionsStatusBars.lua:136](../../AddonOptions/FluxOptionsStatusBars.lua#L136). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not (FluxPVPTracking and FluxPVPTracking.ShouldEnable and FluxPVPTracking.ShouldEnable()) end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L140) |

### pvpIntro · On this client, Honor and Arena can be shown on the gold strip. These toggles are stored per character (same … · L144

Source: [AddonOptions/FluxOptionsStatusBars.lua:144](../../AddonOptions/FluxOptionsStatusBars.lua#L144). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not (FluxPVPTracking and FluxPVPTracking.ShouldEnable and FluxPVPTracking.ShouldEnable()) end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L150) |

### trackHonorInBar · Show Honor on status bar · L154

Source: [AddonOptions/FluxOptionsStatusBars.lua:154](../../AddonOptions/FluxOptionsStatusBars.lua#L154). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local p = EnsurePVPTrackingSavedVars() return p.trackHonor and true or false end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L162) |
| set | `function(_, val) local p = EnsurePVPTrackingSavedVars() p.trackHonor = val and true or false if FluxPVPTracking and FluxPVPTracking.SyncHonorArenaCheckboxesFromSavedVars then FluxPVPTracking.SyncHonorArenaCheckboxesFromSavedVars() end if _G.UpdateGo…` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L166) |
| hidden | `function() return not (FluxPVPTracking and FluxPVPTracking.ShouldEnable and FluxPVPTracking.ShouldEnable()) end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L159) |

### trackArenaInBar · Show Arena Points on status bar · L177

Source: [AddonOptions/FluxOptionsStatusBars.lua:177](../../AddonOptions/FluxOptionsStatusBars.lua#L177). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local p = EnsurePVPTrackingSavedVars() return p.trackArena and true or false end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L185) |
| set | `function(_, val) local p = EnsurePVPTrackingSavedVars() p.trackArena = val and true or false if FluxPVPTracking and FluxPVPTracking.SyncHonorArenaCheckboxesFromSavedVars then FluxPVPTracking.SyncHonorArenaCheckboxesFromSavedVars() end if _G.UpdateGo…` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L189) |
| hidden | `function() return not (FluxPVPTracking and FluxPVPTracking.ShouldEnable and FluxPVPTracking.ShouldEnable()) end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L182) |

### itemCurrencyHeader · Item currency (bag counts) · L226

Source: [AddonOptions/FluxOptionsStatusBars.lua:226](../../AddonOptions/FluxOptionsStatusBars.lua#L226). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### itemCurrencyIntro · Per character (not account-wide). Icons in a grid: drag to reorder, drag from bags to assign, cursor + click … · L231

Source: [AddonOptions/FluxOptionsStatusBars.lua:231](../../AddonOptions/FluxOptionsStatusBars.lua#L231). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### itemCurrencyEnabled · Show item currency on gold strip · L238

Source: [AddonOptions/FluxOptionsStatusBars.lua:238](../../AddonOptions/FluxOptionsStatusBars.lua#L238). Type: `"toggle"`.

When on, each slotted item with a non-zero bag count is shown on the bar after gold / game currencies and Honor & Arena (if any).

| Contract | Source expression / implementation |
|---|---|
| get | `function() local ic = GetItemCurrencyDB() return ic and ic.enabled and true or false end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L244) |
| set | `function(_, val) local ic = GetItemCurrencyDB() if ic then ic.enabled = val and true or false end RefAfterItemCurrency() end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L248) |

### itemCurrencySlotPanel · itemCurrencySlotPanel · L256

Source: [AddonOptions/FluxOptionsStatusBars.lua:256](../../AddonOptions/FluxOptionsStatusBars.lua#L256). Type: `"description"`.

Drag to reorder, drag an item from bags onto an icon, or use the cursor. Right-click clears a slot.

| Contract | Source expression / implementation |
|---|---|
| dialogControl | `"FluxItemCurrencySlots"` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L263) |

### goldLedgerHeader · Account gold (multi-character tooltip) · L294

Source: [AddonOptions/FluxOptionsStatusBars.lua:294](../../AddonOptions/FluxOptionsStatusBars.lua#L294). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### goldLedgerDesc · Gold per character is stored with Flux inventory awareness (or Syndicator, if that addon is loaded) and shown… · L299

Source: [AddonOptions/FluxOptionsStatusBars.lua:299](../../AddonOptions/FluxOptionsStatusBars.lua#L299). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### goldLedgerSelect · Stored character · L306

Source: [AddonOptions/FluxOptionsStatusBars.lua:306](../../AddonOptions/FluxOptionsStatusBars.lua#L306). Type: `"select"`.

Short lines: name / realm / gold. * = this character (re-adds to the list when you earn or spend gold). Pick a row, then delete if needed. Sorted by name, then realm.

| Contract | Source expression / implementation |
|---|---|
| values | `function() return SyncGoldLedgerSelect() end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L312) |
| get | `function() SyncGoldLedgerSelect() if ledgerPick.keys[1] == false then return 1 end local m = math.floor(tonumber(ledgerPick.lastIdx) or 1) m = math.max(1, math.min(m, #ledgerPick.keys)) ledgerPick.lastIdx = m return m end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L315) |
| set | `function(_, v) ledgerPick.lastIdx = v end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L325) |

### goldLedgerDelete · Delete selected character from ledger · L329

Source: [AddonOptions/FluxOptionsStatusBars.lua:329](../../AddonOptions/FluxOptionsStatusBars.lua#L329). Type: `"execute"`.

Hides that character from the account gold tooltip. Inventory item locations for that character are kept. The only way to show gold again is to log that character so the addon can re-save their gold.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if not _G.FluxGoldLedger or not _G.FluxGoldLedger.DeleteLedgerEntryByKey then return end SyncGoldLedgerSelect() local idx = math.floor(tonumber(ledgerPick.lastIdx) or 1) if ledgerPick.keys[1] == false or idx &lt; 1 or idx &gt; #ledgerPick.keys …` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L337) |
| disabled | `function() if not _G.FluxGoldLedger or not _G.FluxGoldLedger.GetConfigLedgerIndex then return true end local n = 0 pcall(function() n = #_G.FluxGoldLedger:GetConfigLedgerIndex() end) return n &lt; 1 end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L355) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L335) |
| confirmText | `"Remove this entry from the account gold saved data? The only way to get it back is to log that character again so the addon can re-save their gold."` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L336) |

### invTipHeader · Inventory awareness · L390

Source: [AddonOptions/FluxOptionsStatusBars.lua:390](../../AddonOptions/FluxOptionsStatusBars.lua#L390). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### invTipDesc · function() if SyndicatorOwnsTips() then return "Syndicator is loaded, so item and currency location lines on … · L395

Source: [AddonOptions/FluxOptionsStatusBars.lua:395](../../AddonOptions/FluxOptionsStatusBars.lua#L395). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### &lt;anonymous&gt; · name · L408

Source: [AddonOptions/FluxOptionsStatusBars.lua:408](../../AddonOptions/FluxOptionsStatusBars.lua#L408). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = InvTipDB() if not d then return true end if d[key] == false then return false end return d[key] ~= false end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L416) |
| set | `function(_, val) local d = InvTipDB() if d then d[key] = val and true or false end end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L426) |
| hidden | `hiddenFn` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L415) |
| disabled | `SyndicatorOwnsTips` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L414) |

### invTipShiftOnly · Only while Shift is held · L449

Source: [AddonOptions/FluxOptionsStatusBars.lua:449](../../AddonOptions/FluxOptionsStatusBars.lua#L449). Type: `"toggle"`.

Location lines appear only while you hold Shift.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = InvTipDB() return d and d.invTipShiftOnly and true or false end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L456) |
| set | `function(_, val) local d = InvTipDB() if d then d.invTipShiftOnly = val and true or false end end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L460) |
| disabled | `SyndicatorOwnsTips` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L455) |

### invTipConnectedRealms · Connected realms only · L467

Source: [AddonOptions/FluxOptionsStatusBars.lua:467](../../AddonOptions/FluxOptionsStatusBars.lua#L467). Type: `"toggle"`.

Hide characters on realms that are not connected to this one.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = InvTipDB() return d and d.invTipConnectedRealms and true or false end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L474) |
| set | `function(_, val) local d = InvTipDB() if d then d.invTipConnectedRealms = val and true or false end end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L478) |
| disabled | `SyndicatorOwnsTips` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L473) |

### invTipFactionOnly · Same faction only · L485

Source: [AddonOptions/FluxOptionsStatusBars.lua:485](../../AddonOptions/FluxOptionsStatusBars.lua#L485). Type: `"toggle"`.

Hide characters of the opposite faction.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = InvTipDB() return d and d.invTipFactionOnly and true or false end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L492) |
| set | `function(_, val) local d = InvTipDB() if d then d.invTipFactionOnly = val and true or false end end` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L496) |
| disabled | `SyndicatorOwnsTips` [source](../../AddonOptions/FluxOptionsStatusBars.lua#L491) |

## FluxOptionsUnitFrames.lua

[AddonOptions/FluxOptionsUnitFrames.lua](../../AddonOptions/FluxOptionsUnitFrames.lua)

### &lt;anonymous&gt; · name · L218

Source: [AddonOptions/FluxOptionsUnitFrames.lua:218](../../AddonOptions/FluxOptionsUnitFrames.lua#L218). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return DisplayGet(unit, key) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L223) |
| set | `function(_, v) DisplaySet(unit, key, v) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L226) |

### &lt;anonymous&gt; · Health text · L233

Source: [AddonOptions/FluxOptionsUnitFrames.lua:233](../../AddonOptions/FluxOptionsUnitFrames.lua#L233). Type: `"select"`.

Current and percent, percent only, values only, or hidden.

| Contract | Source expression / implementation |
|---|---|
| values | `HEALTH_TEXT_VALUES` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L238) |
| get | `function() local row = GetDB().display and GetDB().display[unit] local mode = row and row.healthText if mode == "both" or mode == "percent" or mode == "values" or mode == "none" then return mode end return fallback end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L240) |
| set | `function(_, v) if v ~= "both" and v ~= "percent" and v ~= "values" and v ~= "none" then v = fallback end DisplaySet(unit, "healthText", v) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L248) |

### &lt;anonymous&gt; · name · L267

Source: [AddonOptions/FluxOptionsUnitFrames.lua:267](../../AddonOptions/FluxOptionsUnitFrames.lua#L267). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local t = GetDB()[dbKey] if not t or t[flag] == nil then return true end return t[flag] and true or false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L271) |
| set | `function(_, v) local d = GetDB() d[dbKey] = d[dbKey] or {} d[dbKey][flag] = v and true or false AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L278) |

### [unit .. "TextHeader"] · flags.header or "Text and bars" · L288

Source: [AddonOptions/FluxOptionsUnitFrames.lua:288](../../AddonOptions/FluxOptionsUnitFrames.lua#L288). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### [unit .. "ClassPowerScale"] · Class power size (%) · L325

Source: [AddonOptions/FluxOptionsUnitFrames.lua:325](../../AddonOptions/FluxOptionsUnitFrames.lua#L325). Type: `"range"`.

Scale relative to the default size (100%). Includes combo points, arcane charges, holy power, runes, chi, shards, essence, and totems. Applies after combat; nameplates keep their own size.

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L328) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L328) |
| step | `5` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L328) |
| get | `function() return (FluxUnitFrames_GetClassPowerScale and FluxUnitFrames_GetClassPowerScale() or 1) * 100 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L329) |
| set | `function(_, value) GetDB().classPowerScale = math.max(50, math.min(200, tonumber(value) or 100)) / 100 if ns.ClassPower and ns.ClassPower.ApplyVisibility then ns.ClassPower.ApplyVisibility() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L332) |

### [unit .. "IconHeader"] · Icons · L341

Source: [AddonOptions/FluxOptionsUnitFrames.lua:341](../../AddonOptions/FluxOptionsUnitFrames.lua#L341). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### auraTimersUnderMinute · Show aura timers only below 1 minute · L399

Source: [AddonOptions/FluxOptionsUnitFrames.lua:399](../../AddonOptions/FluxOptionsUnitFrames.lua#L399). Type: `"toggle"`.

Applies to normal party frames, target and focus. Hide countdown text at 60 seconds or more; icons, stacks and swipes remain. Raid and compact party use the separate Party / Raid setting.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().auraTimersUnderMinute == true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L402) |
| set | `function(_, value) GetDB().auraTimersUnderMinute = value and true or false AfterAuraOptionsChange() if FluxPartyFrames and FluxPartyFrames.ApplyOptions then FluxPartyFrames.ApplyOptions() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L403) |

### raidSettingsScope · Party / raid settings scope · L410

Source: [AddonOptions/FluxOptionsUnitFrames.lua:410](../../AddonOptions/FluxOptionsUnitFrames.lua#L410). Type: `"select"`.

Account-wide stores party and raid options in the active profile. Character-specific keeps them on this character only.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L416) |
| get | `function() return FluxOptions:IsRaidFramesCharacterSpecific() and "character" or "account" end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L421) |
| set | `function(_, val) FluxOptions:SetRaidFrameCharacterSpecific(val == "character") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L424) |

### useFluxRaidFrames · Party / raid · L429

Source: [AddonOptions/FluxOptionsUnitFrames.lua:429](../../AddonOptions/FluxOptionsUnitFrames.lua#L429). Type: `"toggle"`.

Use Flux compact party and raid frames. When off, Blizzard party and raid frames are restored.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {} return db.useFluxRaidFrames ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L434) |
| set | `function(_, v) local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() if db then db.useFluxRaidFrames = v and true or false end if FluxOptions and FluxOptions.RefreshRaidFrameScopedModules then FluxOptions:RefreshRaid…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L438) |

### resetRaidFrames · Reset party / raid options · L449

Source: [AddonOptions/FluxOptionsUnitFrames.lua:449](../../AddonOptions/FluxOptionsUnitFrames.lua#L449). Type: `"execute"`.

Restores Party / Raid tab settings for the current party / raid scope.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxOptions and FluxOptions.ResetRaidFramesToDefaults then FluxOptions:ResetRaidFramesToDefaults() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L455) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L454) |

### playerExtrasHeader · Player extras · L472

Source: [AddonOptions/FluxOptionsUnitFrames.lua:472](../../AddonOptions/FluxOptionsUnitFrames.lua#L472). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusTargetHeader · Focus target · L580

Source: [AddonOptions/FluxOptionsUnitFrames.lua:580](../../AddonOptions/FluxOptionsUnitFrames.lua#L580). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusTargetDesc · The focus target bar matches the focus frame size. · L585

Source: [AddonOptions/FluxOptionsUnitFrames.lua:585](../../AddonOptions/FluxOptionsUnitFrames.lua#L585). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### focustargetClassHP · Class-colored focus target HP · L600

Source: [AddonOptions/FluxOptionsUnitFrames.lua:600](../../AddonOptions/FluxOptionsUnitFrames.lua#L600). Type: `"toggle"`.

Use class color when the focus target is a player. NPC targets keep their usual color.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().classColorFocusTargetHP == true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L603) |
| set | `function(_, value) GetDB().classColorFocusTargetHP = value and true or false if FluxUnitFrames_RefreshTargetHealthColors then FluxUnitFrames_RefreshTargetHealthColors() end AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L604) |

### pettargetClassHP · Class-colored pet target HP · L631

Source: [AddonOptions/FluxOptionsUnitFrames.lua:631](../../AddonOptions/FluxOptionsUnitFrames.lua#L631). Type: `"toggle"`.

Use class color when your pet's target is a player. NPC targets keep their usual color.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().classColorPetTargetHP == true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L634) |
| set | `function(_, value) GetDB().classColorPetTargetHP = value and true or false if FluxUnitFrames_RefreshTargetHealthColors then FluxUnitFrames_RefreshTargetHealthColors() end AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L635) |

### description · School and spell visual themes for Flux cast bars. Hybrid spells combine every school’s colors and effects. I… · L670

Source: [AddonOptions/FluxOptionsUnitFrames.lua:670](../../AddonOptions/FluxOptionsUnitFrames.lua#L670). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### [key] · label · L676

Source: [AddonOptions/FluxOptionsUnitFrames.lua:676](../../AddonOptions/FluxOptionsUnitFrames.lua#L676). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return get(key) ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L678) |
| set | `function(_, value) set(key, value and true or false) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L679) |
| disabled | `function() return (key ~= "enabled" and get("enabled") == false) or (key == "gradient" and get("colors") == false) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L680) |

### bars · Cast bars · L687

Source: [AddonOptions/FluxOptionsUnitFrames.lua:687](../../AddonOptions/FluxOptionsUnitFrames.lua#L687). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### detection · Spell appearance · L695

Source: [AddonOptions/FluxOptionsUnitFrames.lua:695](../../AddonOptions/FluxOptionsUnitFrames.lua#L695). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### effects · Shared appearance · L700

Source: [AddonOptions/FluxOptionsUnitFrames.lua:700](../../AddonOptions/FluxOptionsUnitFrames.lua#L700). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### [key] · label · L708

Source: [AddonOptions/FluxOptionsUnitFrames.lua:708](../../AddonOptions/FluxOptionsUnitFrames.lua#L708). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L709) |
| max | `maximum` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L709) |
| step | `5` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L709) |
| get | `function() return get(key) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L710) |
| set | `function(_, value) set(key, value) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L711) |
| disabled | `function() return get("enabled") == false or (requires and get(requires) == false) or (key == "glowOpacity" and get("halo") == false and get("edge") == false) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L712) |

### reset · Reset school themes · L721

Source: [AddonOptions/FluxOptionsUnitFrames.lua:721](../../AddonOptions/FluxOptionsUnitFrames.lua#L721). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local db = GetDB() db.castBarThemes = {} for key, value in pairs(defaults) do db.castBarThemes[key] = value end if ns.CastBarThemes then ns.CastBarThemes.Refresh() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L723) |

### &lt;anonymous&gt; · Cast bar school themes · L730

Source: [AddonOptions/FluxOptionsUnitFrames.lua:730](../../AddonOptions/FluxOptionsUnitFrames.lua#L730). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### options · Unit frames · L734

Source: [AddonOptions/FluxOptionsUnitFrames.lua:734](../../AddonOptions/FluxOptionsUnitFrames.lua#L734). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### general · General · L743

Source: [AddonOptions/FluxOptionsUnitFrames.lua:743](../../AddonOptions/FluxOptionsUnitFrames.lua#L743). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### scopeHeader · Settings · L748

Source: [AddonOptions/FluxOptionsUnitFrames.lua:748](../../AddonOptions/FluxOptionsUnitFrames.lua#L748). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### settingsScope · Unit frame settings scope · L753

Source: [AddonOptions/FluxOptionsUnitFrames.lua:753](../../AddonOptions/FluxOptionsUnitFrames.lua#L753). Type: `"select"`.

Account-wide stores these options in the active profile (follows the Profiles tab). Character-specific keeps them on this character only, independent of General &gt; Settings scope.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L759) |
| get | `function() return FluxOptions:IsUnitFramesCharacterSpecific() and "character" or "account" end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L764) |
| set | `function(_, val) FluxOptions:SetUnitFrameCharacterSpecific(val == "character") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L767) |

### scopeDesc · This scope applies to every sub-tab below. Character-specific unit frame data is not duplicated when you copy… · L771

Source: [AddonOptions/FluxOptionsUnitFrames.lua:771](../../AddonOptions/FluxOptionsUnitFrames.lua#L771). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### fluxVsBlizHeader · Flux vs Blizzard · L778

Source: [AddonOptions/FluxOptionsUnitFrames.lua:778](../../AddonOptions/FluxOptionsUnitFrames.lua#L778). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### fluxVsBlizDesc · When Flux is off for a unit, the default Blizzard frame is used. Pet and target-of-target require the Flux pl… · L783

Source: [AddonOptions/FluxOptionsUnitFrames.lua:783](../../AddonOptions/FluxOptionsUnitFrames.lua#L783). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### useFluxPlayer · Player · L790

Source: [AddonOptions/FluxOptionsUnitFrames.lua:790](../../AddonOptions/FluxOptionsUnitFrames.lua#L790). Type: `"toggle"`.

Use Flux player frame. When off, Blizzard PlayerFrame is used; Flux pet requires Flux player.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxPlayer ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L796) |
| set | `function(_, v) GetDB().useFluxPlayer = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L797) |

### useFluxTarget · Target · L802

Source: [AddonOptions/FluxOptionsUnitFrames.lua:802](../../AddonOptions/FluxOptionsUnitFrames.lua#L802). Type: `"toggle"`.

Use Flux target frame. When off, Blizzard TargetFrame is used. Target-of-target (Flux) requires Flux target.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L808) |
| set | `function(_, v) GetDB().useFluxTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L809) |

### useFluxTargetOfTarget · Target of target · L814

Source: [AddonOptions/FluxOptionsUnitFrames.lua:814](../../AddonOptions/FluxOptionsUnitFrames.lua#L814). Type: `"toggle"`.

Requires Flux target. When off, Blizzard ToT is used if available.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxTargetOfTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L821) |
| set | `function(_, v) GetDB().useFluxTargetOfTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L822) |
| disabled | `function() return GetDB().useFluxTarget == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L820) |

### useFluxFocus · Focus · L827

Source: [AddonOptions/FluxOptionsUnitFrames.lua:827](../../AddonOptions/FluxOptionsUnitFrames.lua#L827). Type: `"toggle"`.

Use Flux focus frame. When off, Blizzard FocusFrame is used. Focus target bar requires Flux focus.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxFocus ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L834) |
| set | `function(_, v) GetDB().useFluxFocus = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L835) |
| hidden | `function() return not HasFocusUnit() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L833) |

### useFluxFocusTarget · Focus target · L840

Source: [AddonOptions/FluxOptionsUnitFrames.lua:840](../../AddonOptions/FluxOptionsUnitFrames.lua#L840). Type: `"toggle"`.

Requires Flux focus. When off, Blizzard focus ToT is used.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxFocusTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L848) |
| set | `function(_, v) GetDB().useFluxFocusTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L849) |
| hidden | `function() return not HasFocusUnit() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L846) |
| disabled | `function() return GetDB().useFluxFocus == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L847) |

### useFluxPet · Pet · L854

Source: [AddonOptions/FluxOptionsUnitFrames.lua:854](../../AddonOptions/FluxOptionsUnitFrames.lua#L854). Type: `"toggle"`.

Requires Flux player frame. When off, Blizzard PetFrame is used.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxPet ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L861) |
| set | `function(_, v) GetDB().useFluxPet = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L862) |
| disabled | `function() return GetDB().useFluxPlayer == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L860) |

### useFluxPetTarget · Pet target · L867

Source: [AddonOptions/FluxOptionsUnitFrames.lua:867](../../AddonOptions/FluxOptionsUnitFrames.lua#L867). Type: `"toggle"`.

Requires Flux pet (and Flux player). When off, pet target strip is not created.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxPetTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L877) |
| set | `function(_, v) GetDB().useFluxPetTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L878) |
| disabled | `function() local d = GetDB() return d.useFluxPlayer == false or d.useFluxPet == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L873) |

### resetUnitFrames · Reset unit frame options to defaults · L884

Source: [AddonOptions/FluxOptionsUnitFrames.lua:884](../../AddonOptions/FluxOptionsUnitFrames.lua#L884). Type: `"execute"`.

Restores Flux vs Blizzard toggles and feature toggles to FluxUI defaults for the current scope (all unit frame tabs).

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxOptions and FluxOptions.ResetUnitFramesToDefaults then FluxOptions:ResetUnitFramesToDefaults() end AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L891) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L890) |

### featuresHeader · Features · L899

Source: [AddonOptions/FluxOptionsUnitFrames.lua:899](../../AddonOptions/FluxOptionsUnitFrames.lua#L899). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### featuresDesc · These options apply immediately to Flux unit frames. · L904

Source: [AddonOptions/FluxOptionsUnitFrames.lua:904](../../AddonOptions/FluxOptionsUnitFrames.lua#L904). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### use3DPortraits · 3D portraits · L910

Source: [AddonOptions/FluxOptionsUnitFrames.lua:910](../../AddonOptions/FluxOptionsUnitFrames.lua#L910). Type: `"toggle"`.

When enabled, the portrait strip uses animated 3D models. When disabled, classic flat (2D) portraits are used for player, target, focus, and pet.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().use3DPortraits ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L916) |
| set | `function(_, v) GetDB().use3DPortraits = v and true or false if FluxUnitFrames_RefreshPortraitRenderModeFromDB then FluxUnitFrames_RefreshPortraitRenderModeFromDB() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L919) |

### enablePortraitCombatTint · Combat portrait tint · L926

Source: [AddonOptions/FluxOptionsUnitFrames.lua:926](../../AddonOptions/FluxOptionsUnitFrames.lua#L926). Type: `"toggle"`.

When this unit is in combat, its portrait border and the background behind the portrait turn red. Each frame uses its own unit, so a target or focus in combat stays red even if you are not.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enablePortraitCombatTint ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L932) |
| set | `function(_, v) GetDB().enablePortraitCombatTint = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L935) |

### enableHealthLossOverlay · Health loss overlay · L940

Source: [AddonOptions/FluxOptionsUnitFrames.lua:940](../../AddonOptions/FluxOptionsUnitFrames.lua#L940). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableHealthLossOverlay ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L945) |
| set | `function(_, v) GetDB().enableHealthLossOverlay = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L946) |

### enablePowerCostOverlay · Power cost overlay · L951

Source: [AddonOptions/FluxOptionsUnitFrames.lua:951](../../AddonOptions/FluxOptionsUnitFrames.lua#L951). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enablePowerCostOverlay ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L956) |
| set | `function(_, v) GetDB().enablePowerCostOverlay = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L957) |

### enableMP5Overlay · MP5 / mana tick overlay (player) · L962

Source: [AddonOptions/FluxOptionsUnitFrames.lua:962](../../AddonOptions/FluxOptionsUnitFrames.lua#L962). Type: `"toggle"`.

Show five-second-rule and mana-tick markers on Era, Anniversary/TBC, and Forever clients.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableMP5Overlay ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L968) |
| set | `function(_, v) GetDB().enableMP5Overlay = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L969) |

### swingTimerUnsupportedNote · Weapon swing timer is unavailable on live post-Dragonflight retail and on Cataclysm / Mists Classic. Classic … · L974

Source: [AddonOptions/FluxOptionsUnitFrames.lua:974](../../AddonOptions/FluxOptionsUnitFrames.lua#L974). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return IsSwingTimerClientSupported() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L980) |

### enableSwingTimer · Weapon swing timer (player) · L982

Source: [AddonOptions/FluxOptionsUnitFrames.lua:982](../../AddonOptions/FluxOptionsUnitFrames.lua#L982). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableSwingTimer ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L988) |
| set | `function(_, v) GetDB().enableSwingTimer = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L989) |
| hidden | `function() return not IsSwingTimerClientSupported() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L987) |

### enableFlightPathTimers · Flight path timers · L994

Source: [AddonOptions/FluxOptionsUnitFrames.lua:994](../../AddonOptions/FluxOptionsUnitFrames.lua#L994). Type: `"toggle"`.

Show flight duration on taxi map tooltips and a progress bar on the player cast bar while flying. Uses bundled flight-time data with optional overrides after landing.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableFlightPathTimers ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1000) |
| set | `function(_, v) GetDB().enableFlightPathTimers = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1001) |

### enableFlightPathCastBar · Flight path cast bar (player) · L1006

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1006](../../AddonOptions/FluxOptionsUnitFrames.lua#L1006). Type: `"toggle"`.

Show in-flight progress on the player unit frame cast bar slot.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableFlightPathCastBar ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1013) |
| set | `function(_, v) GetDB().enableFlightPathCastBar = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1014) |
| disabled | `function() return GetDB().enableFlightPathTimers == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1012) |

### enableFlightPathTooltips · Flight path taxi map tooltips · L1019

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1019](../../AddonOptions/FluxOptionsUnitFrames.lua#L1019). Type: `"toggle"`.

Append estimated flight duration when hovering reachable destinations on the taxi map.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableFlightPathTooltips ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1026) |
| set | `function(_, v) GetDB().enableFlightPathTooltips = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1027) |
| disabled | `function() return GetDB().enableFlightPathTimers == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1025) |

### threatBarVisibility · Threat bar visibility · L1032

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1032](../../AddonOptions/FluxOptionsUnitFrames.lua#L1032). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `THREAT_BAR_VISIBILITY_VALUES` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1038) |
| get | `function() return GetThreatBarVisibility() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1040) |
| set | `function(_, v) SetThreatBarVisibility(v) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1043) |

### showNumericThreat · Show threat percentage · L1047

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1047](../../AddonOptions/FluxOptionsUnitFrames.lua#L1047). Type: `"toggle"`.

Shows tank-relative threat % (100% = you have aggro) on the target/focus threat bar and on nameplates, plus your placement in the group.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local ThreatAPI = ns.Flux and ns.Flux.Threat if ThreatAPI and ThreatAPI.ShowNumeric then return ThreatAPI.ShowNumeric() end return true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1053) |
| set | `function(_, v) local ThreatAPI = ns.Flux and ns.Flux.Threat if ThreatAPI and ThreatAPI.SetShowNumeric then ThreatAPI.SetShowNumeric(v) end if FluxUnitFrames_ApplyThreatBarOptionsFromDB then FluxUnitFrames_ApplyThreatBarOptionsFromDB() end if FluxNam…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1060) |

### nameplateOptionsPointer · Nameplate Progressive, Flash, Health Bar Color, and Threat warning are on the Nameplates page. · L1073

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1073](../../AddonOptions/FluxOptionsUnitFrames.lua#L1073). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### unitPlayer · Player · L1084

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1084](../../AddonOptions/FluxOptionsUnitFrames.lua#L1084). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### playerShowPortrait · Show portrait strip · L1089

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1089](../../AddonOptions/FluxOptionsUnitFrames.lua#L1089). Type: `"toggle"`.

When off, only the bar column is shown and it stays centered at the bottom of the screen. When on, the side portrait strip is shown (3D vs flat is set under General -&gt; Features). Applies immediately. Third-party addons that replace the portrait (e.g. BigDebuffs) get a layout refresh when this changes.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitPlayer ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1095) |
| set | `function(_, v) GetDB().showPortraitPlayer = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1098) |

### playerTargetScale · Player + target scale (%) · L1103

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1103](../../AddonOptions/FluxOptionsUnitFrames.lua#L1103). Type: `"range"`.

Scales the complete player and target frames and their attached cast bars, auras, indicators and target-of-target frame.

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1106) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1106) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1106) |
| get | `function() return (FluxUnitFrames_GetWholeFrameScale and FluxUnitFrames_GetWholeFrameScale("player") or 1) * 100 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1107) |
| set | `function(_, value) GetDB().frameScalePlayerTarget = math.max(50, math.min(200, tonumber(value) or 100)) / 100 AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1110) |

### playerWidth · Width · L1115

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1115](../../AddonOptions/FluxOptionsUnitFrames.lua#L1115). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `150` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1120) |
| max | `600` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1121) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1122) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("player", "width") end fs.player = fs.player or {} local raw = fs.player.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("player", "widt…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1123) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.player = fs.player or {} fs.player.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1135) |

### playerHeight · Height · L1145

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1145](../../AddonOptions/FluxOptionsUnitFrames.lua#L1145). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1150) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1151) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1152) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("player", "height") end fs.player = fs.player or {} local raw = fs.player.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("player", "he…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1153) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.player = fs.player or {} fs.player.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1165) |

### playerHealthSplit · Health / resource split % · L1175

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1175](../../AddonOptions/FluxOptionsUnitFrames.lua#L1175). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown. Alternate power (third bar) still uses a fixed three-way split.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1181) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1182) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1183) |
| get | `function() return HealthPartitionGetFor("player") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1184) |
| set | `function(_, val) HealthPartitionSetFor("player", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1187) |

### unitTarget · Target · L1194

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1194](../../AddonOptions/FluxOptionsUnitFrames.lua#L1194). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### targetShowPortrait · Show portrait strip · L1199

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1199](../../AddonOptions/FluxOptionsUnitFrames.lua#L1199). Type: `"toggle"`.

When off, only the bar column is shown and it stays centered at the top of the screen. When on, the side portrait strip is shown (3D vs flat is under General -&gt; Features). Applies immediately; BigDebuffs and similar mods receive a refresh hook.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1205) |
| set | `function(_, v) GetDB().showPortraitTarget = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1208) |

### targetNoTargetPlaceholder · Empty target placeholder · L1213

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1213](../../AddonOptions/FluxOptionsUnitFrames.lua#L1213). Type: `"toggle"`.

When enabled, a subtle gray outline marks the target frame area while you have nothing targeted. Turn off to hide that box.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showTargetNoTargetPlaceholder ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1219) |
| set | `function(_, v) GetDB().showTargetNoTargetPlaceholder = v and true or false AfterTargetPlaceholderChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1222) |

### targetSizeFollowsPlayerNote · Layout is set to side-by-side (Layout tab): target width and height match the Player tab - adjust size there. · L1227

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1227](../../AddonOptions/FluxOptionsUnitFrames.lua#L1227). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not IsSideBySidePlayerTargetLayout() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1233) |

### targetWidth · Width · L1237

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1237](../../AddonOptions/FluxOptionsUnitFrames.lua#L1237). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1242) |
| max | `800` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1243) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1244) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("target", "width") end fs.target = fs.target or {} local raw = fs.target.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("target", "widt…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1248) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.target = fs.target or {} fs.target.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1260) |
| hidden | `function() return IsSideBySidePlayerTargetLayout() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1245) |

### targetHeight · Height · L1270

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1270](../../AddonOptions/FluxOptionsUnitFrames.lua#L1270). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1275) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1276) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1277) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("target", "height") end fs.target = fs.target or {} local raw = fs.target.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("target", "he…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1281) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.target = fs.target or {} fs.target.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1293) |
| hidden | `function() return IsSideBySidePlayerTargetLayout() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1278) |

### targetHealthSplit · Health / resource split % · L1303

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1303](../../AddonOptions/FluxOptionsUnitFrames.lua#L1303). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1309) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1310) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1311) |
| get | `function() return HealthPartitionGetFor("target") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1312) |
| set | `function(_, val) HealthPartitionSetFor("target", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1315) |

### targetAurasHeader · Auras · L1319

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1319](../../AddonOptions/FluxOptionsUnitFrames.lua#L1319). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### targetAuraBuffSize · Buff icon size · L1324

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1324](../../AddonOptions/FluxOptionsUnitFrames.lua#L1324). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1329) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1330) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1331) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.buffSize or 35 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1332) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.buffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1337) |

### targetAuraDebuffSize · Debuff icon size · L1344

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1344](../../AddonOptions/FluxOptionsUnitFrames.lua#L1344). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1349) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1350) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1351) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.debuffSize or 35 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1352) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.debuffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1357) |

### targetAuraLockOwnDebuffSize · Lock own debuff size · L1364

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1364](../../AddonOptions/FluxOptionsUnitFrames.lua#L1364). Type: `"toggle"`.

Keep your player/pet/vehicle debuffs at full boosted size (~1.38x). Other players' debuffs can shrink to fit the panel (Classic) or stay at the configured size (Midnight/Forever). When off, yours can shrink down to Own debuff min scale.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1370) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.lockOwnDebuffSize = v and true or false AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1375) |

### targetAuraOwnDebuffMinScale · Own debuff min scale · L1382

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1382](../../AddonOptions/FluxOptionsUnitFrames.lua#L1382). Type: `"range"`.

When lock is off, the smallest your own debuffs can get (100% = full boosted size, 50% = half of boosted). They stay larger than other players' icons while the panel is shrinking. Disabled while lock is on. On Midnight/Forever this sets own icon size directly (those frames do not fit-shrink).

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1388) |
| max | `100` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1389) |
| step | `5` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1390) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} local s = tonumber(d.auraTarget.ownDebuffMinScale) or 0.75 return math.floor(s * 100 + 0.5) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1398) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.ownDebuffMinScale = (tonumber(v) or 75) / 100 AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1404) |
| disabled | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1393) |

### targetAuraBuffSpacing · Buff spacing · L1411

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1411](../../AddonOptions/FluxOptionsUnitFrames.lua#L1411). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1416) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1417) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1418) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.buffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1419) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.buffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1424) |

### targetAuraDebuffSpacing · Debuff spacing · L1431

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1431](../../AddonOptions/FluxOptionsUnitFrames.lua#L1431). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1436) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1437) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1438) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.debuffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1439) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.debuffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1444) |

### targetAuraMaxBuffs · Max buff icons · L1451

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1451](../../AddonOptions/FluxOptionsUnitFrames.lua#L1451). Type: `"range"`.

Increasing above the previous cap rebuilds the buff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `8` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1457) |
| max | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1458) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1459) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.maxBuffs or 32 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1460) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.maxBuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1465) |

### targetAuraMaxDebuffs · Max debuff icons · L1472

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1472](../../AddonOptions/FluxOptionsUnitFrames.lua#L1472). Type: `"range"`.

Increasing above the previous cap rebuilds the debuff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `4` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1478) |
| max | `24` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1479) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1480) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.maxDebuffs or 16 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1481) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.maxDebuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1486) |

### targetThreatHeader · Threat · L1493

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1493](../../AddonOptions/FluxOptionsUnitFrames.lua#L1493). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### targetThreatBarVisibility · Threat bar visibility · L1498

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1498](../../AddonOptions/FluxOptionsUnitFrames.lua#L1498). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `THREAT_BAR_VISIBILITY_VALUES` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1504) |
| get | `function() return GetThreatBarVisibility() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1506) |
| set | `function(_, v) SetThreatBarVisibility(v) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1509) |

### targetThreatBarPosition · Threat bar position · L1513

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1513](../../AddonOptions/FluxOptionsUnitFrames.lua#L1513). Type: `"select"`.

Portrait overlays the portrait when you have threat. Between reserves a strip between the frame chrome and auras. Left/Right are vertical strips for enemy NPCs only. In side-by-side Layout, Left is coerced to Right so the strip stays on the outer edge.

| Contract | Source expression / implementation |
|---|---|
| values | `{ portrait = "Portrait overlay", between = "Between chrome and auras", left = "Left (vertical)", right = "Right (vertical)", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1519) |
| get | `function() local v = GetDB().threatBarPositionTarget if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then return "portrait" end return v end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1525) |
| set | `function(_, v) if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then v = "portrait" end GetDB().threatBarPositionTarget = v if FluxUnitFrames_ApplyThreatBarOptionsFromDB then FluxUnitFrames_ApplyThreatBarOptionsFromDB() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1532) |

### unitTargetOfTarget · Target of target · L1545

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1545](../../AddonOptions/FluxOptionsUnitFrames.lua#L1545). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### totWidth · Width · L1550

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1550](../../AddonOptions/FluxOptionsUnitFrames.lua#L1550). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `80` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1555) |
| max | `300` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1556) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1557) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("targettarget", "width") end fs.targettarget = fs.targettarget or {} local raw = fs.targettarget.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return De…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1558) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.targettarget = fs.targettarget or {} fs.targettarget.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1570) |

### totHeight · Height · L1580

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1580](../../AddonOptions/FluxOptionsUnitFrames.lua#L1580). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `30` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1585) |
| max | `120` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1586) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1587) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("targettarget", "height") end fs.targettarget = fs.targettarget or {} local raw = fs.targettarget.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return …` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1588) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.targettarget = fs.targettarget or {} fs.targettarget.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1600) |

### totHealthSplit · Health / resource split % · L1610

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1610](../../AddonOptions/FluxOptionsUnitFrames.lua#L1610). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1616) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1617) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1618) |
| get | `function() return HealthPartitionGetFor("targettarget") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1619) |
| set | `function(_, val) HealthPartitionSetFor("targettarget", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1622) |

### unitFocus · Focus · L1629

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1629](../../AddonOptions/FluxOptionsUnitFrames.lua#L1629). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not HasFocusUnit() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1633) |

### focusShowPortrait · Show portrait strip · L1635

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1635](../../AddonOptions/FluxOptionsUnitFrames.lua#L1635). Type: `"toggle"`.

When off, only the bar column is shown (focus frame repositions from chat; focus target bar matches width). When on, the side portrait strip is shown (3D vs flat is under General -&gt; Features). Applies immediately.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitFocus ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1641) |
| set | `function(_, v) GetDB().showPortraitFocus = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1644) |

### focusFrameScale · Focus scale (%) · L1649

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1649](../../AddonOptions/FluxOptionsUnitFrames.lua#L1649). Type: `"range"`.

Scales the complete focus frame, attached cast bar, auras, indicators and focus-target frame.

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1652) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1652) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1652) |
| get | `function() return (FluxUnitFrames_GetWholeFrameScale and FluxUnitFrames_GetWholeFrameScale("focus") or 1) * 100 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1653) |
| set | `function(_, value) GetDB().frameScaleFocus = math.max(50, math.min(200, tonumber(value) or 100)) / 100 AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1656) |

### focusWidth · Width · L1661

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1661](../../AddonOptions/FluxOptionsUnitFrames.lua#L1661). Type: `"range"`.

Focus layout units. The default proportions match a normal party member; whole-frame scale remains independent.

| Contract | Source expression / implementation |
|---|---|
| min | `80` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1667) |
| max | `250` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1668) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1669) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("focus", "width") end fs.focus = fs.focus or {} local raw = fs.focus.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("focus", "width") e…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1670) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.focus = fs.focus or {} fs.focus.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1682) |

### focusHeight · Height · L1692

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1692](../../AddonOptions/FluxOptionsUnitFrames.lua#L1692). Type: `"range"`.

Focus layout units. The default proportions match a normal party member; whole-frame scale remains independent.

| Contract | Source expression / implementation |
|---|---|
| min | `30` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1698) |
| max | `120` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1699) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1700) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("focus", "height") end fs.focus = fs.focus or {} local raw = fs.focus.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("focus", "height"…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1701) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.focus = fs.focus or {} fs.focus.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1713) |

### focusHealthSplit · Health / resource split % · L1723

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1723](../../AddonOptions/FluxOptionsUnitFrames.lua#L1723). Type: `"range"`.

Share of the inner bar stack for health; also used for the focus target-of-target strip height.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1729) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1730) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1731) |
| get | `function() return HealthPartitionGetFor("focus") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1732) |
| set | `function(_, val) HealthPartitionSetFor("focus", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1735) |

### focusAurasHeader · Auras · L1739

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1739](../../AddonOptions/FluxOptionsUnitFrames.lua#L1739). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusAuraBuffSize · Buff icon size · L1744

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1744](../../AddonOptions/FluxOptionsUnitFrames.lua#L1744). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1749) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1750) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1751) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.buffSize or 20 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1752) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.buffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1757) |

### focusAuraDebuffSize · Debuff icon size · L1764

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1764](../../AddonOptions/FluxOptionsUnitFrames.lua#L1764). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1769) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1770) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1771) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.debuffSize or 20 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1772) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.debuffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1777) |

### focusAuraLockOwnDebuffSize · Lock own debuff size · L1784

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1784](../../AddonOptions/FluxOptionsUnitFrames.lua#L1784). Type: `"toggle"`.

Keep your player/pet/vehicle debuffs at full boosted size (~1.38x). Other players' debuffs can shrink to fit the panel (Classic) or stay at the configured size (Midnight/Forever). When off, yours can shrink down to Own debuff min scale.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1790) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.lockOwnDebuffSize = v and true or false AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1795) |

### focusAuraOwnDebuffMinScale · Own debuff min scale · L1802

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1802](../../AddonOptions/FluxOptionsUnitFrames.lua#L1802). Type: `"range"`.

When lock is off, the smallest your own debuffs can get (100% = full boosted size, 50% = half of boosted). They stay larger than other players' icons while the panel is shrinking. Disabled while lock is on. On Midnight/Forever this sets own icon size directly (those frames do not fit-shrink).

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1808) |
| max | `100` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1809) |
| step | `5` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1810) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} local s = tonumber(d.auraFocus.ownDebuffMinScale) or 0.75 return math.floor(s * 100 + 0.5) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1818) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.ownDebuffMinScale = (tonumber(v) or 75) / 100 AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1824) |
| disabled | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1813) |

### focusAuraBuffSpacing · Buff spacing · L1831

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1831](../../AddonOptions/FluxOptionsUnitFrames.lua#L1831). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1836) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1837) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1838) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.buffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1839) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.buffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1844) |

### focusAuraDebuffSpacing · Debuff spacing · L1851

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1851](../../AddonOptions/FluxOptionsUnitFrames.lua#L1851). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1856) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1857) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1858) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.debuffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1859) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.debuffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1864) |

### focusAuraMaxBuffs · Max buff icons · L1871

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1871](../../AddonOptions/FluxOptionsUnitFrames.lua#L1871). Type: `"range"`.

Increasing above the previous cap rebuilds the buff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `8` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1877) |
| max | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1878) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1879) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.maxBuffs or 32 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1880) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.maxBuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1885) |

### focusAuraMaxDebuffs · Max debuff icons · L1892

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1892](../../AddonOptions/FluxOptionsUnitFrames.lua#L1892). Type: `"range"`.

Increasing above the previous cap rebuilds the debuff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `4` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1898) |
| max | `24` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1899) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1900) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.maxDebuffs or 16 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1901) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.maxDebuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1906) |

### focusThreatHeader · Threat · L1913

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1913](../../AddonOptions/FluxOptionsUnitFrames.lua#L1913). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusThreatBarVisibility · Threat bar visibility · L1918

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1918](../../AddonOptions/FluxOptionsUnitFrames.lua#L1918). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `THREAT_BAR_VISIBILITY_VALUES` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1924) |
| get | `function() return GetThreatBarVisibility() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1926) |
| set | `function(_, v) SetThreatBarVisibility(v) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1929) |

### focusThreatBarPosition · Threat bar position · L1933

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1933](../../AddonOptions/FluxOptionsUnitFrames.lua#L1933). Type: `"select"`.

Portrait overlays the portrait when you have threat. Between reserves a strip between the frame chrome and auras. Left/Right are vertical strips for enemy NPCs only.

| Contract | Source expression / implementation |
|---|---|
| values | `{ portrait = "Portrait overlay", between = "Between chrome and auras", left = "Left (vertical)", right = "Right (vertical)", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1939) |
| get | `function() local v = GetDB().threatBarPositionFocus if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then return "portrait" end return v end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1945) |
| set | `function(_, v) if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then v = "portrait" end GetDB().threatBarPositionFocus = v if FluxUnitFrames_ApplyThreatBarOptionsFromDB then FluxUnitFrames_ApplyThreatBarOptionsFromDB() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1952) |

### unitPet · Pet · L1965

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1965](../../AddonOptions/FluxOptionsUnitFrames.lua#L1965). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### petShowPortrait · Show portrait strip · L1970

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1970](../../AddonOptions/FluxOptionsUnitFrames.lua#L1970). Type: `"toggle"`.

When off, only the pet bar column is shown (no portrait strip). When on, the side portrait strip is shown (3D vs flat is under General -&gt; Features). Applies immediately; the pet frame re-anchors to the player frame.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitPet ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1976) |
| set | `function(_, v) GetDB().showPortraitPet = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1979) |

### petShowCastBar · Show cast bar · L1984

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1984](../../AddonOptions/FluxOptionsUnitFrames.lua#L1984). Type: `"toggle"`.

Overlay a cast/channel bar on the pet resource bar. Off by default.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showCastBarPet == true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1990) |
| set | `function(_, v) GetDB().showCastBarPet = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1993) |

### petShowTooltipAuras · Show auras on mouseover · L1998

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1998](../../AddonOptions/FluxOptionsUnitFrames.lua#L1998). Type: `"toggle"`.

When hovering the pet frame, show buff and debuff icons with cooldown countdown next to the unit tooltip.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPetTooltipAuras ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2004) |
| set | `function(_, v) GetDB().showPetTooltipAuras = v and true or false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2007) |

### petWidth · Width · L2011

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2011](../../AddonOptions/FluxOptionsUnitFrames.lua#L2011). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `60` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2016) |
| max | `220` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2017) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2018) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("pet", "width") end fs.pet = fs.pet or {} local raw = fs.pet.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("pet", "width") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2019) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.pet = fs.pet or {} fs.pet.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2031) |

### petHeight · Height · L2041

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2041](../../AddonOptions/FluxOptionsUnitFrames.lua#L2041). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `30` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2046) |
| max | `120` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2047) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2048) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("pet", "height") end fs.pet = fs.pet or {} local raw = fs.pet.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("pet", "height") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2049) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.pet = fs.pet or {} fs.pet.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2061) |

### petHealthSplit · Health / resource split % · L2071

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2071](../../AddonOptions/FluxOptionsUnitFrames.lua#L2071). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2077) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2078) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2079) |
| get | `function() return HealthPartitionGetFor("pet") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2080) |
| set | `function(_, val) HealthPartitionSetFor("pet", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2083) |

### unitPetTarget · Pet target · L2090

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2090](../../AddonOptions/FluxOptionsUnitFrames.lua#L2090). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### petTargetWidth · Width · L2095

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2095](../../AddonOptions/FluxOptionsUnitFrames.lua#L2095). Type: `"range"`.

Vertical health strip next to the pet frame; height always matches the pet frame.

| Contract | Source expression / implementation |
|---|---|
| min | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2101) |
| max | `48` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2102) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2103) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("pettarget", "width") end fs.pettarget = fs.pettarget or {} local raw = fs.pettarget.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("pe…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2104) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.pettarget = fs.pettarget or {} fs.pettarget.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2116) |

### Factory expansions

Arguments select storage keys, unit names, labels, fallback values, ordering, and conditional availability. Follow the corresponding factory definition for the resulting getter/setter contract.

| Site | Factory and arguments |
|---|---|
| [AddonOptions/FluxOptionsUnitFrames.lua:299](../../AddonOptions/FluxOptionsUnitFrames.lua#L299) | `FlagToggle(unit, "castBar", "Cast bar", "Show the cast bar on this frame.", nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:302](../../AddonOptions/FluxOptionsUnitFrames.lua#L302) | `FlagToggle(unit, "castTime", "Cast time", "Show remaining time on the cast bar.", nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:305](../../AddonOptions/FluxOptionsUnitFrames.lua#L305) | `HealthTextOpt(unit, flags.health, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:315](../../AddonOptions/FluxOptionsUnitFrames.lua#L315) | `FlagToggle(unit, "powerText", "Power numbers", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:318](../../AddonOptions/FluxOptionsUnitFrames.lua#L318) | `FlagToggle(unit, "healPrediction", "Heal prediction", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:321](../../AddonOptions/FluxOptionsUnitFrames.lua#L321) | `FlagToggle(unit, "absorbs", "Absorbs", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:324](../../AddonOptions/FluxOptionsUnitFrames.lua#L324) | `FlagToggle(unit, "classPower", "Class power", "Combo points, runes, essence, and the other class resource bars.", nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:352](../../AddonOptions/FluxOptionsUnitFrames.lua#L352) | `FlagToggle(unit, "level", "Level", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:355](../../AddonOptions/FluxOptionsUnitFrames.lua#L355) | `FlagToggle(unit, "classIcon", "Class icon", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:358](../../AddonOptions/FluxOptionsUnitFrames.lua#L358) | `FlagToggle(unit, "pvp", "PvP flag", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:361](../../AddonOptions/FluxOptionsUnitFrames.lua#L361) | `FlagToggle(unit, "combat", "Combat icon", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:364](../../AddonOptions/FluxOptionsUnitFrames.lua#L364) | `FlagToggle(unit, "raidIcon", "Raid marker", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:367](../../AddonOptions/FluxOptionsUnitFrames.lua#L367) | `FlagToggle(unit, "portraitCombat", "Portrait combat text", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:370](../../AddonOptions/FluxOptionsUnitFrames.lua#L370) | `FlagToggle(unit, "mouseover", "Mouseover highlight", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:511](../../AddonOptions/FluxOptionsUnitFrames.lua#L511) | `AddTextAndBars(player, "player", 30, { castBar = true, castTime = true, health = "both", power = true, heal = true, absorb = true, classPower = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:520](../../AddonOptions/FluxOptionsUnitFrames.lua#L520) | `AddIcons(player, "player", 36, { level = true, classIcon = true, pvp = true, combat = true, raidIcon = true, portraitCombat = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:530](../../AddonOptions/FluxOptionsUnitFrames.lua#L530) | `AddTextAndBars(target, "target", 20, { castBar = true, castTime = true, health = "both", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:538](../../AddonOptions/FluxOptionsUnitFrames.lua#L538) | `AddIcons(target, "target", 26, { level = true, classIcon = true, pvp = true, raidIcon = true, portraitCombat = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:546](../../AddonOptions/FluxOptionsUnitFrames.lua#L546) | `AuraToggle("auraTarget", "showBuffs", "Show buffs", 3.6)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:547](../../AddonOptions/FluxOptionsUnitFrames.lua#L547) | `AuraToggle("auraTarget", "showDebuffs", "Show debuffs", 3.7)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:549](../../AddonOptions/FluxOptionsUnitFrames.lua#L549) | `AddTextAndBars(tot.args, "targettarget", 10, { header = "Text and bars", health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:556](../../AddonOptions/FluxOptionsUnitFrames.lua#L556) | `AddIcons(tot.args, "targettarget", 16, { raidIcon = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:562](../../AddonOptions/FluxOptionsUnitFrames.lua#L562) | `AddTextAndBars(focus, "focus", 20, { castBar = true, castTime = true, health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:570](../../AddonOptions/FluxOptionsUnitFrames.lua#L570) | `AddIcons(focus, "focus", 26, { level = true, classIcon = true, pvp = true, raidIcon = true, portraitCombat = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:578](../../AddonOptions/FluxOptionsUnitFrames.lua#L578) | `AuraToggle("auraFocus", "showBuffs", "Show buffs", 3.6)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:579](../../AddonOptions/FluxOptionsUnitFrames.lua#L579) | `AuraToggle("auraFocus", "showDebuffs", "Show debuffs", 3.7)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:591](../../AddonOptions/FluxOptionsUnitFrames.lua#L591) | `AddTextAndBars(focus, "focustarget", 70.1, { header = "Focus target text", health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:598](../../AddonOptions/FluxOptionsUnitFrames.lua#L598) | `FlagToggle("focustarget", "mouseover", "Mouseover highlight", nil, 71)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:599](../../AddonOptions/FluxOptionsUnitFrames.lua#L599) | `FlagToggle("focustarget", "raidIcon", "Raid marker", nil, 71.1)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:611](../../AddonOptions/FluxOptionsUnitFrames.lua#L611) | `AddTextAndBars(pet, "pet", 20, { castTime = true, health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:618](../../AddonOptions/FluxOptionsUnitFrames.lua#L618) | `AddIcons(pet, "pet", 26, { raidIcon = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:623](../../AddonOptions/FluxOptionsUnitFrames.lua#L623) | `AddTextAndBars(petTarget.args, "pettarget", 10, { header = "Text and bars", health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:630](../../AddonOptions/FluxOptionsUnitFrames.lua#L630) | `FlagToggle("pettarget", "mouseover", "Mouseover highlight", nil, 16)` |

## FluxOptionsVendor.lua

[AddonOptions/FluxOptionsVendor.lua](../../AddonOptions/FluxOptionsVendor.lua)

### [1] · Auto repair · L14

Source: [AddonOptions/FluxOptionsVendor.lua:14](../../AddonOptions/FluxOptionsVendor.lua#L14). Type: `custom toggle descriptor`.

Repair gear at repair-capable merchants.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return false end local s = FV.EnsureSettings() return s and s.autoRepair and true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L18) |
| set | `function(val) local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return end local s = FV.EnsureSettings() s.autoRepair = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L26) |

### [2] · Bulk buy at vendor · L36

Source: [AddonOptions/FluxOptionsVendor.lua:36](../../AddonOptions/FluxOptionsVendor.lua#L36). Type: `custom toggle descriptor`.

Shift+click merchant items to open the bulk purchase window.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local BEA = _G.FluxBuyEmAll if BEA and BEA.IsEnabled then return BEA:IsEnabled() end _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {} return _FluxUI_CharSavedVars.buyEmAllEnabled ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L40) |
| set | `function(val) _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {} _FluxUI_CharSavedVars.buyEmAllEnabled = val and true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L48) |

### [3] · Confirm large bulk purchases · L53

Source: [AddonOptions/FluxOptionsVendor.lua:53](../../AddonOptions/FluxOptionsVendor.lua#L53). Type: `custom toggle descriptor`.

Show a confirmation dialog before very large vendor purchases. Same as /buyemall confirm.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local BEA = _G.FluxBuyEmAll if BEA and BEA.IsConfirmLargeEnabled then return BEA:IsConfirmLargeEnabled() end _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {} return _FluxUI_CharSavedVars.buyEmAllConfirmLarge ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L65) |
| set | `function(val) local BEA = _G.FluxBuyEmAll if BEA and BEA.SetConfirmLargeEnabled then BEA:SetConfirmLargeEnabled(val) return end _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {} _FluxUI_CharSavedVars.buyEmAllConfirmLarge = val and true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L73) |
| disabled | `function() local BEA = _G.FluxBuyEmAll if BEA and BEA.IsEnabled then return not BEA:IsEnabled() end _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {} return _FluxUI_CharSavedVars.buyEmAllEnabled == false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L57) |

### [4] · Guild bank first · L83

Source: [AddonOptions/FluxOptionsVendor.lua:83](../../AddonOptions/FluxOptionsVendor.lua#L83). Type: `custom toggle descriptor`.

Prefer guild bank over personal gold when auto repair runs.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return false end local s = FV.EnsureSettings() return s and (s.repairPriority or "personal") == "guild" end` [source](../../AddonOptions/FluxOptionsVendor.lua#L102) |
| set | `function(val) local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return end local s = FV.EnsureSettings() s.repairPriority = val and "guild" or "personal" NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L110) |
| hidden | `function() local FV = _G.FluxVendorAuto if not FV or not FV.ShouldShowGuildRepairPriorityOption then return true end return not FV.ShouldShowGuildRepairPriorityOption() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L87) |
| disabled | `function() local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return true end local s = FV.EnsureSettings() return not (s and s.autoRepair) end` [source](../../AddonOptions/FluxOptionsVendor.lua#L94) |

### [5] · Auto sell junk · L120

Source: [AddonOptions/FluxOptionsVendor.lua:120](../../AddonOptions/FluxOptionsVendor.lua#L120). Type: `custom toggle descriptor`.

Sell junk when a vendor opens.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return false end local s = FV.EnsureSettings() return s and s.autoSellGray and true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L124) |
| set | `function(val) local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return end local s = FV.EnsureSettings() s.autoSellGray = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L132) |

### [6] · Auto restock · L142

Source: [AddonOptions/FluxOptionsVendor.lua:142](../../AddonOptions/FluxOptionsVendor.lua#L142). Type: `custom toggle descriptor`.

Buy listed items up to their targets at vendors.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return false end local s = FV.EnsureSettings() return s and s.autoRestock and true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L146) |
| set | `function(val) local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return end local s = FV.EnsureSettings() s.autoRestock = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L154) |

### [7] · Auto bank restock · L164

Source: [AddonOptions/FluxOptionsVendor.lua:164](../../AddonOptions/FluxOptionsVendor.lua#L164). Type: `custom toggle descriptor`.

Refill bags from the bank toward restock targets when the bank opens.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local BR = _G.FluxBankRestock if BR and BR.IsAutoEnabled then return BR.IsAutoEnabled() and true or false end local FV = _G.FluxVendorAuto local s = FV and FV.EnsureSettings and FV.EnsureSettings() return s and s.autoBankRestock and true …` [source](../../AddonOptions/FluxOptionsVendor.lua#L168) |
| set | `function(val) local BR = _G.FluxBankRestock if BR and BR.SetAutoEnabled then BR.SetAutoEnabled(val and true or false) else local FV = _G.FluxVendorAuto local s = FV and FV.EnsureSettings and FV.EnsureSettings() if s then s.autoBankRestock = val and …` [source](../../AddonOptions/FluxOptionsVendor.lua#L177) |

### [1] · Low-level consumables · L196

Source: [AddonOptions/FluxOptionsVendor.lua:196](../../AddonOptions/FluxOptionsVendor.lua#L196). Type: `custom toggle descriptor`.

Mark low-level consumables as junk.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkFilters and s.junkFilters.consumable ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L200) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkFilters = s.junkFilters or {} s.junkFilters.consumable = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L204) |

### [2] · Unusable equipment · L211

Source: [AddonOptions/FluxOptionsVendor.lua:211](../../AddonOptions/FluxOptionsVendor.lua#L211). Type: `custom toggle descriptor`.

Mark gear your class cannot use as junk.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkFilters and s.junkFilters.unusable ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L215) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkFilters = s.junkFilters or {} s.junkFilters.unusable = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L219) |

### [3] · Sell non-conjured food & water · L226

Source: [AddonOptions/FluxOptionsVendor.lua:226](../../AddonOptions/FluxOptionsVendor.lua#L226). Type: `custom toggle descriptor`.

With Conjure Food, Water, or Refreshment learned: auto-junk non-conjured food/water (no Well Fed). Inferior tiers on the other axis still apply when conjure does not cover it.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkFilters and s.junkFilters.conjureInferiorFoodWater ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L230) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkFilters = s.junkFilters or {} s.junkFilters.conjureInferiorFoodWater = val and true or false local FJ = _G.FluxVendorJunk if FJ then if val and FJ.ScheduleConjureInferiorJunkSync then …` [source](../../AddonOptions/FluxOptionsVendor.lua#L234) |

### [4] · Destroy unsellable junk · L250

Source: [AddonOptions/FluxOptionsVendor.lua:250](../../AddonOptions/FluxOptionsVendor.lua#L250). Type: `custom toggle descriptor`.

Delete one unsellable junk item per vendor sell pass.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkFilters and s.junkFilters.destroy ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L254) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkFilters = s.junkFilters or {} s.junkFilters.destroy = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L258) |

### [5] · Safe batch sell · L265

Source: [AddonOptions/FluxOptionsVendor.lua:265](../../AddonOptions/FluxOptionsVendor.lua#L265). Type: `custom toggle descriptor`.

Sell junk in small batches.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkFilters and s.junkFilters.safe ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L269) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkFilters = s.junkFilters or {} s.junkFilters.safe = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L273) |

### [1] · Junk glow on bag slots · L282

Source: [AddonOptions/FluxOptionsVendor.lua:282](../../AddonOptions/FluxOptionsVendor.lua#L282). Type: `custom toggle descriptor`.

Show a glow on bag slots that contain junk.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkDisplay and s.junkDisplay.glow ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L286) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkDisplay = s.junkDisplay or {} s.junkDisplay.glow = val and true or false local FJ = _G.FluxVendorJunk if FJ and FJ.FireListChanged then FJ.FireListChanged() end NotifyVendorSettingsCha…` [source](../../AddonOptions/FluxOptionsVendor.lua#L290) |

### [2] · Junk coin icon on bag slots · L301

Source: [AddonOptions/FluxOptionsVendor.lua:301](../../AddonOptions/FluxOptionsVendor.lua#L301). Type: `custom toggle descriptor`.

Show a coin icon on bag slots that contain junk.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkDisplay and s.junkDisplay.icons ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L305) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkDisplay = s.junkDisplay or {} s.junkDisplay.icons = val and true or false local FJ = _G.FluxVendorJunk if FJ and FJ.FireListChanged then FJ.FireListChanged() end NotifyVendorSettingsCh…` [source](../../AddonOptions/FluxOptionsVendor.lua#L309) |

### [toggle.key] · toggle.name or toggle.key · L331

Source: [AddonOptions/FluxOptionsVendor.lua:331](../../AddonOptions/FluxOptionsVendor.lua#L331). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return toggle.get and toggle.get() or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L338) |
| set | `function(_, val) if toggle.set then toggle.set(val) end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L341) |
| hidden | `toggle.hidden` [source](../../AddonOptions/FluxOptionsVendor.lua#L336) |
| disabled | `toggle.disabled` [source](../../AddonOptions/FluxOptionsVendor.lua#L337) |

### &lt;anonymous&gt; · Salvage · L352

Source: [AddonOptions/FluxOptionsVendor.lua:352](../../AddonOptions/FluxOptionsVendor.lua#L352). Type: `"group"`.

One-click mill, prospect, disenchant, and similar bag actions.

| Contract | Source expression / implementation |
|---|---|

### automationHeader · Automation · L361

Source: [AddonOptions/FluxOptionsVendor.lua:361](../../AddonOptions/FluxOptionsVendor.lua#L361). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### automationDesc · Repair, selling, and restock that run when a vendor or the bank opens. · L366

Source: [AddonOptions/FluxOptionsVendor.lua:366](../../AddonOptions/FluxOptionsVendor.lua#L366). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### junkHeader · Junk detection · L376

Source: [AddonOptions/FluxOptionsVendor.lua:376](../../AddonOptions/FluxOptionsVendor.lua#L376). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### junkListHelp · In the Restock tab junk grid: \|cffffcc66M\|r = manually added, \|cff888888A\|r = auto-marked. · L382

Source: [AddonOptions/FluxOptionsVendor.lua:382](../../AddonOptions/FluxOptionsVendor.lua#L382). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### bagHeader · Bag indicators · L390

Source: [AddonOptions/FluxOptionsVendor.lua:390](../../AddonOptions/FluxOptionsVendor.lua#L390). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### bagDesc · Marks on bag slots that hold junk. · L395

Source: [AddonOptions/FluxOptionsVendor.lua:395](../../AddonOptions/FluxOptionsVendor.lua#L395). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### alreadyKnownHeader · Already known items · L404

Source: [AddonOptions/FluxOptionsVendor.lua:404](../../AddonOptions/FluxOptionsVendor.lua#L404). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### alreadyKnownStandaloneNote · function() local AK = _G.FluxAlreadyKnown if AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded() then re… · L409

Source: [AddonOptions/FluxOptionsVendor.lua:409](../../AddonOptions/FluxOptionsVendor.lua#L409). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### alreadyKnownEnabled · Tint already-known items · L422

Source: [AddonOptions/FluxOptionsVendor.lua:422](../../AddonOptions/FluxOptionsVendor.lua#L422). Type: `"toggle"`.

Highlight vendor, auction, and guild-bank items you have already learned or collected.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local AK = _G.FluxAlreadyKnown if AK and AK.GetSettings then return AK.GetSettings().enabled ~= false end local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.alreadyKnown …` [source](../../AddonOptions/FluxOptionsVendor.lua#L431) |
| set | `function(_, val) local AK = _G.FluxAlreadyKnown if AK and AK.GetSettings then AK.GetSettings().enabled = val and true or false if AK.NotifySettingsChanged then AK.NotifySettingsChanged() end end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L439) |
| disabled | `function() local AK = _G.FluxAlreadyKnown return AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L427) |

### alreadyKnownMonochrome · Monochrome tint · L449

Source: [AddonOptions/FluxOptionsVendor.lua:449](../../AddonOptions/FluxOptionsVendor.lua#L449). Type: `"toggle"`.

Desaturate icons for already-known items.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local AK = _G.FluxAlreadyKnown return AK and AK.GetSettings and AK.GetSettings().monochrome or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L464) |
| set | `function(_, val) local AK = _G.FluxAlreadyKnown if AK and AK.GetSettings then AK.GetSettings().monochrome = val and true or false if AK.NotifySettingsChanged then AK.NotifySettingsChanged() end end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L468) |
| disabled | `function() local AK = _G.FluxAlreadyKnown if AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded() then return true end if AK and AK.GetSettings then return AK.GetSettings().enabled == false end return false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L454) |

### alreadyKnownColor · Tint color · L478

Source: [AddonOptions/FluxOptionsVendor.lua:478](../../AddonOptions/FluxOptionsVendor.lua#L478). Type: `"color"`.

Color used for already-known item highlights.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local AK = _G.FluxAlreadyKnown local db = AK and AK.GetSettings and AK.GetSettings() or { r = 0, g = 1, b = 0 } return db.r or 0, db.g or 1, db.b or 0 end` [source](../../AddonOptions/FluxOptionsVendor.lua#L494) |
| set | `function(_, r, g, b) local AK = _G.FluxAlreadyKnown if AK and AK.GetSettings then local db = AK.GetSettings() db.r, db.g, db.b = r, g, b if AK.NotifySettingsChanged then AK.NotifySettingsChanged() end end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L499) |
| disabled | `function() local AK = _G.FluxAlreadyKnown if AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded() then return true end if AK and AK.GetSettings then return AK.GetSettings().enabled == false end return false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L484) |

### &lt;anonymous&gt; · Inventory · L511

Source: [AddonOptions/FluxOptionsVendor.lua:511](../../AddonOptions/FluxOptionsVendor.lua#L511). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### vendor · Vendor · L518

Source: [AddonOptions/FluxOptionsVendor.lua:518](../../AddonOptions/FluxOptionsVendor.lua#L518). Type: `"group"`.

Repair, selling, junk rules, bag markers, and already-known tint.

| Contract | Source expression / implementation |
|---|---|

### restock · Restock · L525

Source: [AddonOptions/FluxOptionsVendor.lua:525](../../AddonOptions/FluxOptionsVendor.lua#L525). Type: `"group"`.

Item targets to buy from vendors and pull from the bank.

| Contract | Source expression / implementation |
|---|---|

### restockHelp · Drag items into the grids. Preset restock lists spell reagents from your spell book. " .. "bags/target — stoc… · L531

Source: [AddonOptions/FluxOptionsVendor.lua:531](../../AddonOptions/FluxOptionsVendor.lua#L531). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### restockPanel · restockPanel · L540

Source: [AddonOptions/FluxOptionsVendor.lua:540](../../AddonOptions/FluxOptionsVendor.lua#L540). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| dialogControl | `"FluxRestockPanel"` [source](../../AddonOptions/FluxOptionsVendor.lua#L542) |

### clearRestock · Clear all restock targets · L547

Source: [AddonOptions/FluxOptionsVendor.lua:547](../../AddonOptions/FluxOptionsVendor.lua#L547). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local FV = _G.FluxVendorAuto if FV and FV.EnsureSettings then local s = FV.EnsureSettings() if s then s.restockItems = {} end end NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L554) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsVendor.lua#L552) |
| confirmText | `"Set every restock target to zero?"` [source](../../AddonOptions/FluxOptionsVendor.lua#L553) |

## FluxOptionsWindows.lua

[AddonOptions/FluxOptionsWindows.lua](../../AddonOptions/FluxOptionsWindows.lua)

### &lt;anonymous&gt; · Windows · L29

Source: [AddonOptions/FluxOptionsWindows.lua:29](../../AddonOptions/FluxOptionsWindows.lua#L29). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### intro · Drag Blizzard windows (Character, bags, map, auction, popups). Left-drag moves, right-drag scales, middle-cli… · L34

Source: [AddonOptions/FluxOptionsWindows.lua:34](../../AddonOptions/FluxOptionsWindows.lua#L34). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### scopeHeader · Scope · L41

Source: [AddonOptions/FluxOptionsWindows.lua:41](../../AddonOptions/FluxOptionsWindows.lua#L41). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### settingsScope · Windows scope · L46

Source: [AddonOptions/FluxOptionsWindows.lua:46](../../AddonOptions/FluxOptionsWindows.lua#L46). Type: `"select"`.

Account-wide or per character. Windows tab only.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsWindows.lua#L52) |
| get | `function() return FluxOptions:IsWindowMoverCharacterSpecific() and "character" or "account" end` [source](../../AddonOptions/FluxOptionsWindows.lua#L57) |
| set | `function(_, val) FluxOptions:SetWindowMoverCharacterSpecific(val == "character") NotifyFluxUIConfig() end` [source](../../AddonOptions/FluxOptionsWindows.lua#L60) |

### behaviorHeader · Behavior · L65

Source: [AddonOptions/FluxOptionsWindows.lua:65](../../AddonOptions/FluxOptionsWindows.lua#L65). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### enabled · Enable window mover · L70

Source: [AddonOptions/FluxOptionsWindows.lua:70](../../AddonOptions/FluxOptionsWindows.lua#L70). Type: `"toggle"`.

Allow dragging and scaling Blizzard windows.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = GetDB() return not db or db.enabled ~= false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L76) |
| set | `function(_, val) local db = GetDB() if not db then return end db.enabled = val and true or false RefreshMover() end` [source](../../AddonOptions/FluxOptionsWindows.lua#L80) |

### lock · Lock windows · L89

Source: [AddonOptions/FluxOptionsWindows.lua:89](../../AddonOptions/FluxOptionsWindows.lua#L89). Type: `"toggle"`.

Keep saved positions but ignore drag, scale, and reset. /fluxwindows lock

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = GetDB() return db and db.lock and true or false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L95) |
| set | `function(_, val) local db = GetDB() if not db then return end db.lock = val and true or false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L99) |

### scaleEnabled · Allow scaling · L107

Source: [AddonOptions/FluxOptionsWindows.lua:107](../../AddonOptions/FluxOptionsWindows.lua#L107). Type: `"toggle"`.

Right-drag a window to scale it (50%–250%).

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = GetDB() return not db or db.scaleEnabled ~= false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L113) |
| set | `function(_, val) local db = GetDB() if not db then return end db.scaleEnabled = val and true or false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L117) |

### savePosition · Save positions · L125

Source: [AddonOptions/FluxOptionsWindows.lua:125](../../AddonOptions/FluxOptionsWindows.lua#L125). Type: `"toggle"`.

Remember window positions across reloads.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = GetDB() return not db or db.savePosition ~= false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L131) |
| set | `function(_, val) local db = GetDB() if not db then return end db.savePosition = val and true or false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L135) |

### saveScale · Save scale · L143

Source: [AddonOptions/FluxOptionsWindows.lua:143](../../AddonOptions/FluxOptionsWindows.lua#L143). Type: `"toggle"`.

Remember window scale across reloads.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = GetDB() return not db or db.saveScale ~= false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L149) |
| set | `function(_, val) local db = GetDB() if not db then return end db.saveScale = val and true or false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L153) |

### clampToScreen · Clamp to screen · L161

Source: [AddonOptions/FluxOptionsWindows.lua:161](../../AddonOptions/FluxOptionsWindows.lua#L161). Type: `"toggle"`.

Keep moved windows on screen.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = GetDB() return not db or db.clampToScreen ~= false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L167) |
| set | `function(_, val) local db = GetDB() if not db then return end db.clampToScreen = val and true or false RefreshMover() end` [source](../../AddonOptions/FluxOptionsWindows.lua#L171) |

### modifierHeader · Modifier · L180

Source: [AddonOptions/FluxOptionsWindows.lua:180](../../AddonOptions/FluxOptionsWindows.lua#L180). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### requireModifier · Require modifier to drag · L185

Source: [AddonOptions/FluxOptionsWindows.lua:185](../../AddonOptions/FluxOptionsWindows.lua#L185). Type: `"toggle"`.

Only move/scale/reset while holding the key below. Useful so Merchant and auction clicks are never stolen.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = GetDB() return db and db.requireModifier and true or false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L191) |
| set | `function(_, val) local db = GetDB() if not db then return end db.requireModifier = val and true or false end` [source](../../AddonOptions/FluxOptionsWindows.lua#L195) |

### modifier · Modifier key · L203

Source: [AddonOptions/FluxOptionsWindows.lua:203](../../AddonOptions/FluxOptionsWindows.lua#L203). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `{ SHIFT = SHIFT_KEY or "Shift", CTRL = CTRL_KEY or "Ctrl", ALT = ALT_KEY or "Alt", }` [source](../../AddonOptions/FluxOptionsWindows.lua#L208) |
| get | `function() local db = GetDB() return (db and db.modifier) or "SHIFT" end` [source](../../AddonOptions/FluxOptionsWindows.lua#L218) |
| set | `function(_, val) local db = GetDB() if not db then return end db.modifier = val end` [source](../../AddonOptions/FluxOptionsWindows.lua#L222) |
| disabled | `function() local db = GetDB() return not (db and db.requireModifier) end` [source](../../AddonOptions/FluxOptionsWindows.lua#L214) |

### snap · Snap size · L230

Source: [AddonOptions/FluxOptionsWindows.lua:230](../../AddonOptions/FluxOptionsWindows.lua#L230). Type: `"range"`.

0 = no snap. Pixel grid for window positions.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsWindows.lua#L236) |
| max | `64` [source](../../AddonOptions/FluxOptionsWindows.lua#L237) |
| step | `1` [source](../../AddonOptions/FluxOptionsWindows.lua#L238) |
| get | `function() local db = GetDB() return db and db.snap or 0 end` [source](../../AddonOptions/FluxOptionsWindows.lua#L239) |
| set | `function(_, val) local db = GetDB() if not db then return end db.snap = val end` [source](../../AddonOptions/FluxOptionsWindows.lua#L243) |

### reset · Reset all window positions · L251

Source: [AddonOptions/FluxOptionsWindows.lua:251](../../AddonOptions/FluxOptionsWindows.lua#L251). Type: `"execute"`.

Clear saved positions and scales. Reopen windows to restore Blizzard layout.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local mover = WM() if mover and mover.ResetAll then mover.ResetAll() elseif FluxOptions and FluxOptions.ResetWindowMoverToDefaults then FluxOptions:ResetWindowMoverToDefaults() end NotifyFluxUIConfig() end` [source](../../AddonOptions/FluxOptionsWindows.lua#L259) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsWindows.lua#L257) |
| confirmText | `"Reset all saved window positions?"` [source](../../AddonOptions/FluxOptionsWindows.lua#L258) |

## Registered custom widgets

Registration expressions can use local `Type` constants. Exact widget names, interaction behavior, and storage are explained in the options map; this table keeps every registration site discoverable.

| Source | Registration arguments |
|---|---|
| [AddonOptions/AceGUIWidget-FluxBattlezone.lua:301](../../AddonOptions/AceGUIWidget-FluxBattlezone.lua#L301) | `TabType, TabConstructor, TabVersion` |
| [AddonOptions/AceGUIWidget-FluxBattlezone.lua:465](../../AddonOptions/AceGUIWidget-FluxBattlezone.lua#L465) | `EmbedType, EmbedConstructor, EmbedVersion` |
| [AddonOptions/AceGUIWidget-FluxExtraButtonVisibility.lua:364](../../AddonOptions/AceGUIWidget-FluxExtraButtonVisibility.lua#L364) | `Type, Constructor, Version` |
| [AddonOptions/AceGUIWidget-FluxInfoStatOrder.lua:277](../../AddonOptions/AceGUIWidget-FluxInfoStatOrder.lua#L277) | `Type, Constructor, Version` |
| [AddonOptions/AceGUIWidget-FluxItemCurrencySlots.lua:561](../../AddonOptions/AceGUIWidget-FluxItemCurrencySlots.lua#L561) | `Type, Constructor, Version` |
| [AddonOptions/AceGUIWidget-FluxLayoutPreview.lua:50](../../AddonOptions/AceGUIWidget-FluxLayoutPreview.lua#L50) | `Type, Constructor, Version` |
| [AddonOptions/AceGUIWidget-FluxNCFlyoutPanel.lua:1059](../../AddonOptions/AceGUIWidget-FluxNCFlyoutPanel.lua#L1059) | `Type, Constructor, Version` |
| [AddonOptions/AceGUIWidget-FluxOptionsToggleGrid.lua:313](../../AddonOptions/AceGUIWidget-FluxOptionsToggleGrid.lua#L313) | `Type, Constructor, Version` |
| [AddonOptions/AceGUIWidget-FluxRestockPanel.lua:2583](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2583) | `Type, Constructor, Version` |
| [AddonOptions/AceGUIWidget-FluxSpellBlacklistPanel.lua:593](../../AddonOptions/AceGUIWidget-FluxSpellBlacklistPanel.lua#L593) | `Type, Constructor, Version` |
| [AddonOptions/AceGUIWidget-FluxSpellBookSlotsPanel.lua:476](../../AddonOptions/AceGUIWidget-FluxSpellBookSlotsPanel.lua#L476) | `Type, Constructor, Version` |
| [AddonOptions/AceGUIWidget-FluxStanceBarOrderPanel.lua:838](../../AddonOptions/AceGUIWidget-FluxStanceBarOrderPanel.lua#L838) | `Type, Constructor, Version` |
| [Binding/UI/Browser/AceGUIWidget-FluxBindingBrowserEmbed.lua:372](../../Binding/UI/Browser/AceGUIWidget-FluxBindingBrowserEmbed.lua#L372) | `Type, Constructor, Version` |
| [Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua:231](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua#L231) | `Type, Constructor, Version` |
| [Binding/UI/Editor/Widgets/AceGUIWidget-FluxMultiCastOrderPanel.lua:706](../../Binding/UI/Editor/Widgets/AceGUIWidget-FluxMultiCastOrderPanel.lua#L706) | `Type, Constructor, Version` |
| [Binding/UI/Editor/Widgets/FluxBindingFrame.lua:64](../../Binding/UI/Editor/Widgets/FluxBindingFrame.lua#L64) | `Type, Constructor, Version` |
| [Binding/UI/Editor/Widgets/FluxBindingTabGroup.lua:27](../../Binding/UI/Editor/Widgets/FluxBindingTabGroup.lua#L27) | `Type, Constructor, Version` |
| [Binding/UI/Editor/Widgets/FluxKeyCapture.lua:195](../../Binding/UI/Editor/Widgets/FluxKeyCapture.lua#L195) | `Type, Constructor, Version` |
| [Binding/UI/Editor/Widgets/FluxSectionHeading.lua:120](../../Binding/UI/Editor/Widgets/FluxSectionHeading.lua#L120) | `Type, Constructor, Version` |
| [Binding/UI/Editor/Widgets/FluxTargetRow.lua:85](../../Binding/UI/Editor/Widgets/FluxTargetRow.lua#L85) | `Type, Constructor, Version` |
| [Binding/UI/KeyVisualizer/AceGUIContainer-FluxKeyVisualizerTreeGroup.lua:42](../../Binding/UI/KeyVisualizer/AceGUIContainer-FluxKeyVisualizerTreeGroup.lua#L42) | `Type, Constructor, Version` |
| [Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua:397](../../Binding/UI/KeyVisualizer/AceGUIWidget-FluxKeyVisualizerButton.lua#L397) | `Type, Constructor, Version` |
| [MicroMenu/AceGUIWidget-FluxMicroMenuEmbed.lua:60](../../MicroMenu/AceGUIWidget-FluxMicroMenuEmbed.lua#L60) | `Type, Constructor, Version` |
