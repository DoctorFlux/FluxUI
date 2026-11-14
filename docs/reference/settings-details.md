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

### &lt;anonymous&gt; · FluxWindow · L105

Source: [AddonOptions/FluxOptionsBattlezone.lua:105](../../AddonOptions/FluxOptionsBattlezone.lua#L105). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### headerTabs · Tabs · L110

Source: [AddonOptions/FluxOptionsBattlezone.lua:110](../../AddonOptions/FluxOptionsBattlezone.lua#L110). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### tabsDesc · Drag chips to reorder. Click a chip to turn that tab on or off (at least one must stay on). · L115

Source: [AddonOptions/FluxOptionsBattlezone.lua:115](../../AddonOptions/FluxOptionsBattlezone.lua#L115). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### tabStrip · tabStrip · L121

Source: [AddonOptions/FluxOptionsBattlezone.lua:121](../../AddonOptions/FluxOptionsBattlezone.lua#L121). Type: `"input"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return "" end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L127) |
| set | `function() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L128) |
| dialogControl | `"FluxBattlezoneTabStrip"` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L124) |

### resetTabs · Reset tabs · L130

Source: [AddonOptions/FluxOptionsBattlezone.lua:130](../../AddonOptions/FluxOptionsBattlezone.lua#L130). Type: `"execute"`.

Restore Map → Meter → Respec → Buttons, all enabled.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxWindowFrame and FluxWindowFrame.ResetTabConfigDefaults then FluxWindowFrame:ResetTabConfigDefaults() end local reg = LibStub("AceConfigRegistry-3.0", true) if reg then reg:NotifyChange("FluxUI") end end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L138) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L136) |
| confirmText | `"Reset Flux window tabs to defaults?"` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L137) |

### spacer · spacer · L146

Source: [AddonOptions/FluxOptionsBattlezone.lua:146](../../AddonOptions/FluxOptionsBattlezone.lua#L146). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not HasMeterLayoutBackend() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L150) |

### headerMeter · Meter layout · L154

Source: [AddonOptions/FluxOptionsBattlezone.lua:154](../../AddonOptions/FluxOptionsBattlezone.lua#L154). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not HasMeterLayoutBackend() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L158) |

### meterDesc · function() return MeterLayoutDescription() end · L162

Source: [AddonOptions/FluxOptionsBattlezone.lua:162](../../AddonOptions/FluxOptionsBattlezone.lua#L162). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not HasMeterLayoutBackend() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L169) |

### meterEditor · meterEditor · L173

Source: [AddonOptions/FluxOptionsBattlezone.lua:173](../../AddonOptions/FluxOptionsBattlezone.lua#L173). Type: `"input"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return "" end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L179) |
| set | `function() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L180) |
| hidden | `function() return not HasMeterLayoutBackend() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L181) |
| dialogControl | `"FluxMeterLayoutEmbed"` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L176) |

### noDetails · \|cffAAAAAAMeter layout options appear when Details! is loaded, or when this client ships Blizzard’s damage me… · L185

Source: [AddonOptions/FluxOptionsBattlezone.lua:185](../../AddonOptions/FluxOptionsBattlezone.lua#L185). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return HasMeterLayoutBackend() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L190) |

### minimapButtonsHeader · L.MINIMAP_BUTTONS_HEADER · L194

Source: [AddonOptions/FluxOptionsBattlezone.lua:194](../../AddonOptions/FluxOptionsBattlezone.lua#L194). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### minimapButtonsHelp · L.MINIMAP_BUTTONS_HELP · L197

Source: [AddonOptions/FluxOptionsBattlezone.lua:197](../../AddonOptions/FluxOptionsBattlezone.lua#L197). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### minimapButtonCount · L.MINIMAP_BUTTON_COUNT · L201

Source: [AddonOptions/FluxOptionsBattlezone.lua:201](../../AddonOptions/FluxOptionsBattlezone.lua#L201). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `1` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L204) |
| max | `120` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L204) |
| step | `1` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L204) |
| get | `function() return GetMinimapSetting("count") end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L206) |
| set | `function(_, value) SetMinimapSetting("count", value) end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L207) |
| disabled | `MinimapSettingsUnavailable` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L205) |

### minimapSideHeader · L.MINIMAP_SIDE_HEADER · L209

Source: [AddonOptions/FluxOptionsBattlezone.lua:209](../../AddonOptions/FluxOptionsBattlezone.lua#L209). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### minimapButtonAutoGrow · L.MINIMAP_BUTTON_AUTO_GROW · L212

Source: [AddonOptions/FluxOptionsBattlezone.lua:212](../../AddonOptions/FluxOptionsBattlezone.lua#L212). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetMinimapSetting("autoGrow") end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L216) |
| set | `function(_, value) SetMinimapSetting("autoGrow", value) end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L217) |
| disabled | `MinimapSettingsUnavailable` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L215) |

### minimapSideEnabled · L.MINIMAP_SIDE_ENABLED · L219

Source: [AddonOptions/FluxOptionsBattlezone.lua:219](../../AddonOptions/FluxOptionsBattlezone.lua#L219). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetMinimapSetting("sideEnabled") end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L223) |
| set | `function(_, value) SetMinimapSetting("sideEnabled", value) end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L224) |
| disabled | `MinimapSettingsUnavailable` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L222) |

### minimapSideScale · L.MINIMAP_SIDE_SCALE · L226

Source: [AddonOptions/FluxOptionsBattlezone.lua:226](../../AddonOptions/FluxOptionsBattlezone.lua#L226). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `10` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L229) |
| max | `200` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L229) |
| step | `1` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L229) |
| get | `function() return GetMinimapSetting("sideScale") end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L231) |
| set | `function(_, value) SetMinimapSetting("sideScale", value) end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L232) |
| disabled | `SideSettingsDisabled` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L230) |

### minimapSideStart · L.MINIMAP_SIDE_START · L234

Source: [AddonOptions/FluxOptionsBattlezone.lua:234](../../AddonOptions/FluxOptionsBattlezone.lua#L234). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `{ below = L.MINIMAP_SIDE_BELOW, top = L.MINIMAP_SIDE_TOP }` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L237) |
| get | `function() return GetMinimapSetting("sideStart") end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L239) |
| set | `function(_, value) SetMinimapSetting("sideStart", value) end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L240) |
| disabled | `SideSettingsDisabled` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L238) |

### minimapHideInCombat · L.MINIMAP_HIDE_COMBAT · L242

Source: [AddonOptions/FluxOptionsBattlezone.lua:242](../../AddonOptions/FluxOptionsBattlezone.lua#L242). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetMinimapSetting("hideInCombat") end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L252) |
| set | `function(_, value) SetMinimapSetting("hideInCombat", value) end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L253) |
| disabled | `function() return MinimapSettingsUnavailable() or not CanHideMinimapButtonsInCombat() end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L249) |

### minimapSideHideEmpty · L.MINIMAP_SIDE_HIDE_EMPTY · L255

Source: [AddonOptions/FluxOptionsBattlezone.lua:255](../../AddonOptions/FluxOptionsBattlezone.lua#L255). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetMinimapSetting("sideHideEmpty") end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L259) |
| set | `function(_, value) SetMinimapSetting("sideHideEmpty", value) end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L260) |
| disabled | `SideSettingsDisabled` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L258) |

### minimapSideVisibility · L.MINIMAP_SIDE_VISIBILITY · L262

Source: [AddonOptions/FluxOptionsBattlezone.lua:262](../../AddonOptions/FluxOptionsBattlezone.lua#L262). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `{ always = L.MINIMAP_SIDE_ALWAYS, mouseover = L.MINIMAP_SIDE_MOUSEOVER }` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L265) |
| get | `function() return GetMinimapSetting("sideVisibility") end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L267) |
| set | `function(_, value) SetMinimapSetting("sideVisibility", value) end` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L268) |
| disabled | `SideSettingsDisabled` [source](../../AddonOptions/FluxOptionsBattlezone.lua#L266) |

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

### &lt;anonymous&gt; · name · L67

Source: [AddonOptions/FluxOptionsNameplates.lua:67](../../AddonOptions/FluxOptionsNameplates.lua#L67). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local api = ThreatAPI() if api and api.NameplateDisplayEnabled then return api.NameplateDisplayEnabled(key) end return true end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L73) |
| set | `function(_, v) local api = ThreatAPI() if api and api.SetNameplateDisplay then api.SetNameplateDisplay(key, v) end end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L80) |

### headerThreat · Threat · L91

Source: [AddonOptions/FluxOptionsNameplates.lua:91](../../AddonOptions/FluxOptionsNameplates.lua#L91). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### threatDesc · Flux draws a threat-colored border and your threat rank and percent (100% = you have aggro) on enemy NPC name… · L96

Source: [AddonOptions/FluxOptionsNameplates.lua:96](../../AddonOptions/FluxOptionsNameplates.lua#L96). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### npcThreatBorder · NPC threat border + rank/% · L103

Source: [AddonOptions/FluxOptionsNameplates.lua:103](../../AddonOptions/FluxOptionsNameplates.lua#L103). Type: `"toggle"`.

Color the nameplate border from your threat on enemy NPCs and show threat rank and percent under the health bar.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return EnsureNameplateThreatDB().npcThreatBorder ~= false end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L109) |
| set | `function(_, v) EnsureNameplateThreatDB().npcThreatBorder = v and true or false RefreshNameplatesFromDB() end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L112) |

### showNumericThreat · Show threat percentage · L117

Source: [AddonOptions/FluxOptionsNameplates.lua:117](../../AddonOptions/FluxOptionsNameplates.lua#L117). Type: `"toggle"`.

Shows tank-relative threat % (100% = you have aggro) on nameplates and on the Flux target/focus threat bar.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local api = ThreatAPI() if api and api.ShowNumeric then return api.ShowNumeric() end return true end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L123) |
| set | `function(_, v) local api = ThreatAPI() if api and api.SetShowNumeric then api.SetShowNumeric(v) end RefreshNameplatesFromDB() if FluxUnitFrames_ApplyThreatBarOptionsFromDB then FluxUnitFrames_ApplyThreatBarOptionsFromDB() end end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L130) |

### enemyPlayerTarget · Enemy player targeting you · L141

Source: [AddonOptions/FluxOptionsNameplates.lua:141](../../AddonOptions/FluxOptionsNameplates.lua#L141). Type: `"toggle"`.

Red nameplate border when an enemy player is targeting you.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return EnsureNameplateThreatDB().enemyPlayerTarget ~= false end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L147) |
| set | `function(_, v) EnsureNameplateThreatDB().enemyPlayerTarget = v and true or false RefreshNameplatesFromDB() end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L150) |

### headerBlizzardThreat · Blizzard nameplate threat · L155

Source: [AddonOptions/FluxOptionsNameplates.lua:155](../../AddonOptions/FluxOptionsNameplates.lua#L155). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### blizzardThreatDesc · The game's own Progressive / Flash / Health Bar Color threat display (nameplateThreatDisplay). Flux writes th… · L160

Source: [AddonOptions/FluxOptionsNameplates.lua:160](../../AddonOptions/FluxOptionsNameplates.lua#L160). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### headerLevel · Level · L175

Source: [AddonOptions/FluxOptionsNameplates.lua:175](../../AddonOptions/FluxOptionsNameplates.lua#L175). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### levelDesc · On Modern nameplate style, Flux shows a smaller "Lvl. N" under the right side of the health bar. · L180

Source: [AddonOptions/FluxOptionsNameplates.lua:180](../../AddonOptions/FluxOptionsNameplates.lua#L180). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### levelOverlayEnabled · Show level overlay (Modern style) · L186

Source: [AddonOptions/FluxOptionsNameplates.lua:186](../../AddonOptions/FluxOptionsNameplates.lua#L186). Type: `"toggle"`.

Flux level text/skull under the health text on Modern-style nameplates. Ignored while the Classic health-bar style is active.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return EnsureNameplateThreatDB().levelOverlayEnabled ~= false end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L192) |
| set | `function(_, v) EnsureNameplateThreatDB().levelOverlayEnabled = v and true or false RefreshNameplatesFromDB() end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L195) |

### headerQuestProgress · Quest progress · L202

Source: [AddonOptions/FluxOptionsNameplates.lua:202](../../AddonOptions/FluxOptionsNameplates.lua#L202). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### questOverlayEnabled · Show quest kill / loot progress · L205

Source: [AddonOptions/FluxOptionsNameplates.lua:205](../../AddonOptions/FluxOptionsNameplates.lua#L205). Type: `"toggle"`.

Show a kill or loot icon and your current / required count below the left edge of quest mob nameplates. Uses Questie when loaded, otherwise available Blizzard quest information. Disables Questie's own nameplate marker while enabled.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return EnsureNameplateThreatDB().questOverlayEnabled ~= false end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L210) |
| set | `function(_, value) EnsureNameplateThreatDB().questOverlayEnabled = value and true or false RefreshNameplatesFromDB() end` [source](../../AddonOptions/FluxOptionsNameplates.lua#L211) |

### countdownHeader · Buff / debuff countdown · L217

Source: [AddonOptions/FluxOptionsNameplates.lua:217](../../AddonOptions/FluxOptionsNameplates.lua#L217). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### aurasDesc · Countdown digits use the same Flux 12px overlay as Classic on every client. Size: edit FLUX_NAMEPLATE_AURA_CO… · L223

Source: [AddonOptions/FluxOptionsNameplates.lua:223](../../AddonOptions/FluxOptionsNameplates.lua#L223). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### &lt;anonymous&gt; · Nameplates · L230

Source: [AddonOptions/FluxOptionsNameplates.lua:230](../../AddonOptions/FluxOptionsNameplates.lua#L230). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### Factory expansions

Arguments select storage keys, unit names, labels, fallback values, ordering, and conditional availability. Follow the corresponding factory definition for the resulting getter/setter contract.

| Site | Factory and arguments |
|---|---|
| [AddonOptions/FluxOptionsNameplates.lua:166](../../AddonOptions/FluxOptionsNameplates.lua#L166) | `BlizzardThreatToggle("Progressive", "Progressive", "Blizzard progressive aggro highlight on enemy nameplates.", 6.2)` |
| [AddonOptions/FluxOptionsNameplates.lua:168](../../AddonOptions/FluxOptionsNameplates.lua#L168) | `BlizzardThreatToggle("Flash", "Flash", "Blizzard aggro flash on enemy nameplates.", 6.3)` |
| [AddonOptions/FluxOptionsNameplates.lua:170](../../AddonOptions/FluxOptionsNameplates.lua#L170) | `BlizzardThreatToggle("HealthBarColor", "Health Bar Color", "Blizzard threat coloring on the nameplate health bar. The Flux border is separate.", 6.4)` |

## FluxOptionsNavigation.lua

[AddonOptions/FluxOptionsNavigation.lua](../../AddonOptions/FluxOptionsNavigation.lua)

### view · tab.name · L56

Source: [AddonOptions/FluxOptionsNavigation.lua:56](../../AddonOptions/FluxOptionsNavigation.lua#L56). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### notice · tab.notice · L60

Source: [AddonOptions/FluxOptionsNavigation.lua:60](../../AddonOptions/FluxOptionsNavigation.lua#L60). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### open · action.label · L63

Source: [AddonOptions/FluxOptionsNavigation.lua:63](../../AddonOptions/FluxOptionsNavigation.lua#L63). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() FluxOptions:ShowConfig(action.page, action.sub) end` [source](../../AddonOptions/FluxOptionsNavigation.lua#L63) |

### ["external_" .. index] · target.label · L67

Source: [AddonOptions/FluxOptionsNavigation.lua:67](../../AddonOptions/FluxOptionsNavigation.lua#L67). Type: `"execute"`.

Open this feature's settings outside combat.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if InCombatLockdown and InCombatLockdown() then return end local owner = _G[target.owner]; if owner and owner[target.method] then owner[target.method]() end end` [source](../../AddonOptions/FluxOptionsNavigation.lua#L73) |
| disabled | `function() if InCombatLockdown and InCombatLockdown() then return true end local owner = _G[target.owner]; return not (owner and type(owner[target.method]) == "function") end` [source](../../AddonOptions/FluxOptionsNavigation.lua#L69) |

### &lt;anonymous&gt; · entry.name · L92

Source: [AddonOptions/FluxOptionsNavigation.lua:92](../../AddonOptions/FluxOptionsNavigation.lua#L92). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### text · entry.text · L92

Source: [AddonOptions/FluxOptionsNavigation.lua:92](../../AddonOptions/FluxOptionsNavigation.lua#L92). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### group · entry.name · L100

Source: [AddonOptions/FluxOptionsNavigation.lua:100](../../AddonOptions/FluxOptionsNavigation.lua#L100). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

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

Raid previews show 10 to 40 members. Use Party Frames for the five-member party preview.

| Contract | Source expression / implementation |
|---|---|
| values | `{ ["10"] = "10", ["15"] = "15", ["20"] = "20", ["25"] = "25", ["30"] = "30", ["35"] = "35", ["40"] = "40", }` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L288) |
| get | `function() local n = tonumber(GetRaidDB().previewRosterSize) or 40 return tostring(max(10, min(40, floor(n / 5) * 5))) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L293) |
| set | `function(_, val) GetRaidDB().previewRosterSize = max(10, min(40, floor((tonumber(val) or 40) / 5) * 5)) AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L297) |

### showMT · Show MT column · L302

Source: [AddonOptions/FluxOptionsRaidFrame.lua:302](../../AddonOptions/FluxOptionsRaidFrame.lua#L302). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().previewShowMTColumn ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L307) |
| set | `function(_, val) GetRaidDB().previewShowMTColumn = val and true or false AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L310) |

### mtCount · MT slots · L315

Source: [AddonOptions/FluxOptionsRaidFrame.lua:315](../../AddonOptions/FluxOptionsRaidFrame.lua#L315). Type: `"range"`.

How many MT/MA-style frames appear in the MT column.

| Contract | Source expression / implementation |
|---|---|
| min | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L320) |
| max | `8` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L320) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L320) |
| get | `function() local n = tonumber(GetRaidDB().previewMainTankCount) if not n or n &lt; 1 then n = 2 end return max(1, min(8, floor(n))) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L322) |
| set | `function(_, val) GetRaidDB().previewMainTankCount = max(1, min(8, floor(val))) AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L327) |

### auraSpacer · Demo Auras · L332

Source: [AddonOptions/FluxOptionsRaidFrame.lua:332](../../AddonOptions/FluxOptionsRaidFrame.lua#L332). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### showBuffs · Buffs · L337

Source: [AddonOptions/FluxOptionsRaidFrame.lua:337](../../AddonOptions/FluxOptionsRaidFrame.lua#L337). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().previewDemoBuffsEnabled ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L342) |
| set | `function(_, val) GetRaidDB().previewDemoBuffsEnabled = val and true or false AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L345) |

### buffCount · Buff count · L350

Source: [AddonOptions/FluxOptionsRaidFrame.lua:350](../../AddonOptions/FluxOptionsRaidFrame.lua#L350). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L354) |
| max | `6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L354) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L354) |
| get | `function() return tonumber(GetRaidDB().previewBuffCount) or 3 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L356) |
| set | `function(_, val) GetRaidDB().previewBuffCount = val AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L359) |

### showDebuffs · Debuffs · L364

Source: [AddonOptions/FluxOptionsRaidFrame.lua:364](../../AddonOptions/FluxOptionsRaidFrame.lua#L364). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().previewDemoDebuffsEnabled ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L369) |
| set | `function(_, val) GetRaidDB().previewDemoDebuffsEnabled = val and true or false AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L372) |

### debuffCount · Debuff count · L377

Source: [AddonOptions/FluxOptionsRaidFrame.lua:377](../../AddonOptions/FluxOptionsRaidFrame.lua#L377). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L381) |
| max | `6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L381) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L381) |
| get | `function() return tonumber(GetRaidDB().previewDebuffCount) or 5 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L383) |
| set | `function(_, val) GetRaidDB().previewDebuffCount = val AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L386) |

### sizingHeader · Frame sizing (Flux) · L397

Source: [AddonOptions/FluxOptionsRaidFrame.lua:397](../../AddonOptions/FluxOptionsRaidFrame.lua#L397). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### memberWidthScale · Member frame width scale · L402

Source: [AddonOptions/FluxOptionsRaidFrame.lua:402](../../AddonOptions/FluxOptionsRaidFrame.lua#L402). Type: `"range"`.

1.00 uses Blizzard's default unit-frame width.

| Contract | Source expression / implementation |
|---|---|
| min | `0.6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L407) |
| max | `1.4` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L407) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L407) |
| get | `function() return GetRaidDB().memberWidthScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L409) |
| set | `function(_, val) GetRaidDB().memberWidthScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L412) |

### frameHeightScale · Member frame height scale · L417

Source: [AddonOptions/FluxOptionsRaidFrame.lua:417](../../AddonOptions/FluxOptionsRaidFrame.lua#L417). Type: `"range"`.

1.00 uses Blizzard's default unit-frame height.

| Contract | Source expression / implementation |
|---|---|
| min | `0.8` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L422) |
| max | `1.6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L422) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L422) |
| get | `function() return GetRaidDB().frameHeightScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L424) |
| set | `function(_, val) GetRaidDB().frameHeightScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L427) |

### powerBarHeightScale · Power bar height scale · L432

Source: [AddonOptions/FluxOptionsRaidFrame.lua:432](../../AddonOptions/FluxOptionsRaidFrame.lua#L432). Type: `"range"`.

1.00 uses Blizzard's default resource-strip height. Scales independently of member frame height.

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L437) |
| max | `2.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L437) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L437) |
| get | `function() return GetRaidDB().powerBarHeightScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L439) |
| set | `function(_, val) GetRaidDB().powerBarHeightScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L442) |

### auraWidthScale · Aura width (X) · L448

Source: [AddonOptions/FluxOptionsRaidFrame.lua:448](../../AddonOptions/FluxOptionsRaidFrame.lua#L448). Type: `"range"`.

Changes aura width independently of height. 1.00 is Blizzard's width. Updates live icons out of combat when native configuration is allowed; otherwise the change waits until safe.

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L451) |
| max | `2.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L451) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L451) |
| get | `function() return GetRaidDB().auraWidthScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L452) |
| set | `function(_, value) GetRaidDB().auraWidthScale = max(0.5, min(2.5, tonumber(value) or 1)); AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L453) |

### auraDurationFontScale · Aura duration text size · L455

Source: [AddonOptions/FluxOptionsRaidFrame.lua:455](../../AddonOptions/FluxOptionsRaidFrame.lua#L455). Type: `"range"`.

Scales the fitted duration font independently of icon size. 1.00 keeps the default font size. Updates preview and live aura timers out of combat; combat changes apply when combat ends.

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L458) |
| max | `2.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L458) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L458) |
| get | `function() return GetRaidDB().auraDurationFontScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L459) |
| set | `function(_, value) GetRaidDB().auraDurationFontScale = max(0.5, min(2.5, tonumber(value) or 1)); AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L460) |

### auraTimersUnderMinute · Show aura timers only below 1 minute · L462

Source: [AddonOptions/FluxOptionsRaidFrame.lua:462](../../AddonOptions/FluxOptionsRaidFrame.lua#L462). Type: `"toggle"`.

Applies to raid and party shown as raid frames. Show numbers only below 60 seconds; icons, swipes and stacks remain. Normal party, target and focus use Unit Frames &gt; General.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("auraTimersUnderMinute", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L465) |
| set | `function(_, value) SetRaidFlag("auraTimersUnderMinute", value) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L466) |

### raidManagerScale · Raid manager strip scale · L468

Source: [AddonOptions/FluxOptionsRaidFrame.lua:468](../../AddonOptions/FluxOptionsRaidFrame.lua#L468). Type: `"range"`.

Left raid tools / markers strip. 1.00 uses a compact baseline that is 30% smaller than Blizzard's manager.

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L473) |
| max | `1.2` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L473) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L473) |
| get | `function() return GetRaidDB().raidManagerScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L475) |
| set | `function(_, val) GetRaidDB().raidManagerScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L478) |

### resetSizes · Reset sizes · L483

Source: [AddonOptions/FluxOptionsRaidFrame.lua:483](../../AddonOptions/FluxOptionsRaidFrame.lua#L483). Type: `"execute"`.

Restores the default sizing preset and under-one-minute aura timer display. Aura filters, counts and transparency stay configured.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local db = GetRaidDB() local defaults = FluxOptionsDefaults.profile.raidFrames for _, key in ipairs({ "memberWidthScale", "frameHeightScale", "powerBarHeightScale", "auraIconScale", "auraWidthScale", "auraDurationFontScale", "raidManagerS…` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L488) |

### transparencyHeader · Transparency (Flux) · L502

Source: [AddonOptions/FluxOptionsRaidFrame.lua:502](../../AddonOptions/FluxOptionsRaidFrame.lua#L502). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### transparencyDesc · Frame opacity applies to the visible cell content. In-range and out-of-range multipliers apply when Fade out … · L507

Source: [AddonOptions/FluxOptionsRaidFrame.lua:507](../../AddonOptions/FluxOptionsRaidFrame.lua#L507). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### frameBaseAlpha · Frame base opacity · L513

Source: [AddonOptions/FluxOptionsRaidFrame.lua:513](../../AddonOptions/FluxOptionsRaidFrame.lua#L513). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0.2` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L517) |
| max | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L517) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L517) |
| get | `function() return tonumber(GetRaidDB().frameBaseAlpha) or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L519) |
| set | `function(_, val) GetRaidDB().frameBaseAlpha = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L522) |

### rangeAlphaInRange · Opacity when in range · L527

Source: [AddonOptions/FluxOptionsRaidFrame.lua:527](../../AddonOptions/FluxOptionsRaidFrame.lua#L527). Type: `"range"`.

Used when Fade out of range is on. Multiplied by frame base opacity.

| Contract | Source expression / implementation |
|---|---|
| min | `0.2` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L532) |
| max | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L532) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L532) |
| get | `function() return tonumber(GetRaidDB().rangeAlphaInRange) or 0.9 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L534) |
| set | `function(_, val) GetRaidDB().rangeAlphaInRange = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L537) |

### rangeAlphaOutOfRange · Opacity when out of range / offline · L542

Source: [AddonOptions/FluxOptionsRaidFrame.lua:542](../../AddonOptions/FluxOptionsRaidFrame.lua#L542). Type: `"range"`.

Used when Fade out of range is on. Multiplied by frame base opacity.

| Contract | Source expression / implementation |
|---|---|
| min | `0.1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L547) |
| max | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L547) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L547) |
| get | `function() return tonumber(GetRaidDB().rangeAlphaOutOfRange) or 0.44 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L549) |
| set | `function(_, val) GetRaidDB().rangeAlphaOutOfRange = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L552) |

### auraIconAlpha · Aura transparency · L557

Source: [AddonOptions/FluxOptionsRaidFrame.lua:557](../../AddonOptions/FluxOptionsRaidFrame.lua#L557). Type: `"range"`.

Transparency of buff/debuff icons, duration text and cooldown overlays. 0% is fully visible; 100% is invisible. The starting value is 70%.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L562) |
| max | `100` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L562) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L562) |
| get | `function() local db=GetRaidDB() local value=tonumber(db.auraTransparency) if value==nil then value=100*(1-max(0.1,min(1,tonumber(db.auraIconAlpha) or 1))*0.3) end return max(0,min(100,value)) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L564) |
| set | `function(_, val) GetRaidDB().auraTransparency = max(0,min(100,tonumber(val) or 70)) AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L570) |

### dispelHeader · Dispel Highlight · L579

Source: [AddonOptions/FluxOptionsRaidFrame.lua:579](../../AddonOptions/FluxOptionsRaidFrame.lua#L579). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### showDispelHighlight · Dispel highlight border · L584

Source: [AddonOptions/FluxOptionsRaidFrame.lua:584](../../AddonOptions/FluxOptionsRaidFrame.lua#L584). Type: `"toggle"`.

Shows a type-colored border when a party/raid member has a debuff your class can dispel (e.g. Curse only if you have Remove Curse). Matches Blizzard Dispellable By Me.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().showDispelHighlight ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L590) |
| set | `function(_, val) GetRaidDB().showDispelHighlight = val and true or false AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L593) |

### highlightHeader · Highlights · L599

Source: [AddonOptions/FluxOptionsRaidFrame.lua:599](../../AddonOptions/FluxOptionsRaidFrame.lua#L599). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### showAggroHighlight · Aggro highlight · L604

Source: [AddonOptions/FluxOptionsRaidFrame.lua:604](../../AddonOptions/FluxOptionsRaidFrame.lua#L604). Type: `"toggle"`.

Shows the aggro ring when a member has threat.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showAggroHighlight", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L609) |
| set | `function(_, val) SetRaidFlag("showAggroHighlight", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L610) |

### showTargetHighlight · Target highlight · L612

Source: [AddonOptions/FluxOptionsRaidFrame.lua:612](../../AddonOptions/FluxOptionsRaidFrame.lua#L612). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showTargetHighlight", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L616) |
| set | `function(_, val) SetRaidFlag("showTargetHighlight", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L617) |

### showMouseoverHighlight · Mouseover highlight · L619

Source: [AddonOptions/FluxOptionsRaidFrame.lua:619](../../AddonOptions/FluxOptionsRaidFrame.lua#L619). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showMouseoverHighlight", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L623) |
| set | `function(_, val) SetRaidFlag("showMouseoverHighlight", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L624) |

### showRoleIcon · Role icons · L626

Source: [AddonOptions/FluxOptionsRaidFrame.lua:626](../../AddonOptions/FluxOptionsRaidFrame.lua#L626). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showRoleIcon", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L630) |
| set | `function(_, val) SetRaidFlag("showRoleIcon", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L631) |

### showGroupLabels · Group labels · L633

Source: [AddonOptions/FluxOptionsRaidFrame.lua:633](../../AddonOptions/FluxOptionsRaidFrame.lua#L633). Type: `"toggle"`.

Party and group numbers above each column.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showGroupLabels", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L638) |
| set | `function(_, val) SetRaidFlag("showGroupLabels", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L639) |

### showRangeFade · Fade out of range · L641

Source: [AddonOptions/FluxOptionsRaidFrame.lua:641](../../AddonOptions/FluxOptionsRaidFrame.lua#L641). Type: `"toggle"`.

Uses the in-range and out-of-range opacity sliders.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showRangeFade", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L646) |
| set | `function(_, val) SetRaidFlag("showRangeFade", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L647) |

### showClassBuffs · Class buffs out of combat · L649

Source: [AddonOptions/FluxOptionsRaidFrame.lua:649](../../AddonOptions/FluxOptionsRaidFrame.lua#L649). Type: `"toggle"`.

Shows buffs currently present on party/raid members while out of combat, including long-duration class buffs.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showClassBuffs", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L654) |
| set | `function(_, val) SetRaidFlag("showClassBuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L655) |

### showMissingClassBuffs · Missing class buffs · L657

Source: [AddonOptions/FluxOptionsRaidFrame.lua:657](../../AddonOptions/FluxOptionsRaidFrame.lua#L657). Type: `"toggle"`.

Out of combat, show up to three dim icons for learned class buffs missing from a member. Restricted or unavailable aura data shows no missing-buff claim.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showMissingClassBuffs", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L662) |
| set | `function(_, val) SetRaidFlag("showMissingClassBuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L663) |

### showPets · Party / raid pets · L665

Source: [AddonOptions/FluxOptionsRaidFrame.lua:665](../../AddonOptions/FluxOptionsRaidFrame.lua#L665). Type: `"toggle"`.

Adds half-height pet cells beside the existing grid. Requires working secure visibility support. Existing member positions and sizes stay the same.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showPets", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L670) |
| set | `function(_, val) SetRaidFlag("showPets", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L671) |

### showFriendlyTarget · Friendly target · L673

Source: [AddonOptions/FluxOptionsRaidFrame.lua:673](../../AddonOptions/FluxOptionsRaidFrame.lua#L673). Type: `"toggle"`.

Adds a friendly-target cell beside the party/raid grid, above optional pets. Hostile or missing targets hide securely. Existing member positions stay the same.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showFriendlyTarget", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L678) |
| set | `function(_, val) SetRaidFlag("showFriendlyTarget", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L679) |

### showEstimatedHoTs · Estimate my remaining HoT healing (Forever) · L681

Source: [AddonOptions/FluxOptionsRaidFrame.lua:681](../../AddonOptions/FluxOptionsRaidFrame.lua#L681). Type: `"toggle"`.

Optional estimate from your own successful casts and readable learned English spell descriptions. It cannot detect every dispel, refresh or modifier and does not replace native heal prediction. Unavailable or restricted data shows no estimate.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showEstimatedHoTs", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L691) |
| set | `function(_, val) SetRaidFlag("showEstimatedHoTs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L692) |
| disabled | `function() if FluxRaidHoTs and FluxRaidHoTs.IsSupported then return not FluxRaidHoTs.IsSupported() end local client = ns.Flux and ns.Flux.Client return not (client and (client.isForever or client.isCamelot)) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L686) |

### displayHeader · Bars and auras · L695

Source: [AddonOptions/FluxOptionsRaidFrame.lua:695](../../AddonOptions/FluxOptionsRaidFrame.lua#L695). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### useClassColors · Class colors · L700

Source: [AddonOptions/FluxOptionsRaidFrame.lua:700](../../AddonOptions/FluxOptionsRaidFrame.lua#L700). Type: `"toggle"`.

Class-colored health bars. Names stay on the setting above.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("useClassColors", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L705) |
| set | `function(_, val) SetRaidFlag("useClassColors", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L706) |

### displayPowerBar · Power bars · L708

Source: [AddonOptions/FluxOptionsRaidFrame.lua:708](../../AddonOptions/FluxOptionsRaidFrame.lua#L708). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayPowerBar", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L712) |
| set | `function(_, val) SetRaidFlag("displayPowerBar", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L713) |

### showHealPrediction · Heal prediction · L715

Source: [AddonOptions/FluxOptionsRaidFrame.lua:715](../../AddonOptions/FluxOptionsRaidFrame.lua#L715). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showHealPrediction", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L719) |
| set | `function(_, val) SetRaidFlag("showHealPrediction", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L720) |

### healthText · Health text · L722

Source: [AddonOptions/FluxOptionsRaidFrame.lua:722](../../AddonOptions/FluxOptionsRaidFrame.lua#L722). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `healthTextValues` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L726) |
| get | `function() local v = GetRaidDB().healthText if v ~= "none" and v ~= "health" and v ~= "perc" and v ~= "healthandpercent" then return "perc" end return v end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L728) |
| set | `function(_, val) if val ~= "none" and val ~= "health" and val ~= "perc" and val ~= "healthandpercent" then val = "perc" end GetRaidDB().healthText = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L735) |

### displayBuffs · Show buffs · L743

Source: [AddonOptions/FluxOptionsRaidFrame.lua:743](../../AddonOptions/FluxOptionsRaidFrame.lua#L743). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayBuffs", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L747) |
| set | `function(_, val) SetRaidFlag("displayBuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L748) |

### displayDebuffs · Show debuffs · L750

Source: [AddonOptions/FluxOptionsRaidFrame.lua:750](../../AddonOptions/FluxOptionsRaidFrame.lua#L750). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayDebuffs", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L754) |
| set | `function(_, val) SetRaidFlag("displayDebuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L755) |

### maxBuffs · Maximum buffs · L757

Source: [AddonOptions/FluxOptionsRaidFrame.lua:757](../../AddonOptions/FluxOptionsRaidFrame.lua#L757). Type: `"range"`.

Maximum buff icons per party or raid member.

| Contract | Source expression / implementation |
|---|---|
| min | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L762) |
| max | `6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L762) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L762) |
| get | `function() return max(1, min(6, floor(tonumber(GetRaidDB().maxBuffs) or 6))) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L763) |
| set | `function(_, val) GetRaidDB().maxBuffs = max(1, min(6, floor(tonumber(val) or 6))) AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L764) |

### maxDebuffs · Maximum debuffs · L769

Source: [AddonOptions/FluxOptionsRaidFrame.lua:769](../../AddonOptions/FluxOptionsRaidFrame.lua#L769). Type: `"range"`.

Maximum debuff icons per party or raid member.

| Contract | Source expression / implementation |
|---|---|
| min | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L774) |
| max | `6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L774) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L774) |
| get | `function() return max(1, min(6, floor(tonumber(GetRaidDB().maxDebuffs) or 6))) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L775) |
| set | `function(_, val) GetRaidDB().maxDebuffs = max(1, min(6, floor(tonumber(val) or 6))) AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L776) |

### auraFocusMode · Aura focus · L781

Source: [AddonOptions/FluxOptionsRaidFrame.lua:781](../../AddonOptions/FluxOptionsRaidFrame.lua#L781). Type: `"select"`.

Debuff focused: more debuff slots. Buff focused: more buff slots along the top.

| Contract | Source expression / implementation |
|---|---|
| values | `{ debuff = "Debuff focused", buff = "Buff focused", }` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L786) |
| get | `function() local v = GetRaidDB().auraFocusMode if v == "buff" then return "buff" end return "debuff" end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L790) |
| set | `function(_, val) GetRaidDB().auraFocusMode = (val == "buff") and "buff" or "debuff" AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L795) |

### displayOnlyDispellableDebuffs · Only dispellable debuffs · L800

Source: [AddonOptions/FluxOptionsRaidFrame.lua:800](../../AddonOptions/FluxOptionsRaidFrame.lua#L800). Type: `"toggle"`.

Limits debuff icons to auras your class can dispel.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayOnlyDispellableDebuffs", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L805) |
| set | `function(_, val) SetRaidFlag("displayOnlyDispellableDebuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L806) |

## FluxOptionsRender.lua

[AddonOptions/FluxOptionsRender.lua](../../AddonOptions/FluxOptionsRender.lua)

### headerOpt · title · L702

Source: [AddonOptions/FluxOptionsRender.lua:702](../../AddonOptions/FluxOptionsRender.lua#L702). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### opt · source.title · L758

Source: [AddonOptions/FluxOptionsRender.lua:758](../../AddonOptions/FluxOptionsRender.lua#L758). Type: `"header"`.

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

### &lt;anonymous&gt; · text.threatWarningVisibility · L171

Source: [AddonOptions/FluxOptionsUnitFrames.lua:171](../../AddonOptions/FluxOptionsUnitFrames.lua#L171). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `text.threatWarningVisibilityValues` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L173) |
| get | `function() local api = ns.Flux and ns.Flux.Threat return api and api.GetVisibilityMode and api.GetVisibilityMode() or "group" end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L175) |
| set | `function(_, value) local api = ns.Flux and ns.Flux.Threat if api and api.SetVisibilityMode then api.SetVisibilityMode(value) end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L179) |

### &lt;anonymous&gt; · name · L210

Source: [AddonOptions/FluxOptionsUnitFrames.lua:210](../../AddonOptions/FluxOptionsUnitFrames.lua#L210). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return DisplayGet(unit, key) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L215) |
| set | `function(_, v) DisplaySet(unit, key, v) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L218) |

### &lt;anonymous&gt; · Health text · L225

Source: [AddonOptions/FluxOptionsUnitFrames.lua:225](../../AddonOptions/FluxOptionsUnitFrames.lua#L225). Type: `"select"`.

Current and percent, percent only, values only, or hidden.

| Contract | Source expression / implementation |
|---|---|
| values | `HEALTH_TEXT_VALUES` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L230) |
| get | `function() local row = GetDB().display and GetDB().display[unit] local mode = row and row.healthText if mode == "both" or mode == "percent" or mode == "values" or mode == "none" then return mode end return fallback end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L232) |
| set | `function(_, v) if v ~= "both" and v ~= "percent" and v ~= "values" and v ~= "none" then v = fallback end DisplaySet(unit, "healthText", v) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L240) |

### &lt;anonymous&gt; · name · L259

Source: [AddonOptions/FluxOptionsUnitFrames.lua:259](../../AddonOptions/FluxOptionsUnitFrames.lua#L259). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local t = GetDB()[dbKey] if not t or t[flag] == nil then return true end return t[flag] and true or false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L263) |
| set | `function(_, v) local d = GetDB() d[dbKey] = d[dbKey] or {} d[dbKey][flag] = v and true or false AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L270) |

### [unit .. "TextHeader"] · flags.header or "Text and bars" · L280

Source: [AddonOptions/FluxOptionsUnitFrames.lua:280](../../AddonOptions/FluxOptionsUnitFrames.lua#L280). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### [unit .. "ClassPowerScale"] · Class power size (%) · L317

Source: [AddonOptions/FluxOptionsUnitFrames.lua:317](../../AddonOptions/FluxOptionsUnitFrames.lua#L317). Type: `"range"`.

Scale relative to the default size (100%). Includes combo points, arcane charges, holy power, runes, chi, shards, essence, and totems. Applies after combat; nameplates keep their own size.

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L320) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L320) |
| step | `5` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L320) |
| get | `function() return (FluxUnitFrames_GetClassPowerScale and FluxUnitFrames_GetClassPowerScale() or 1) * 100 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L321) |
| set | `function(_, value) GetDB().classPowerScale = math.max(50, math.min(200, tonumber(value) or 100)) / 100 if ns.ClassPower and ns.ClassPower.ApplyVisibility then ns.ClassPower.ApplyVisibility() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L324) |

### [unit .. "IconHeader"] · Icons · L333

Source: [AddonOptions/FluxOptionsUnitFrames.lua:333](../../AddonOptions/FluxOptionsUnitFrames.lua#L333). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### auraTimersUnderMinute · Show aura timers only below 1 minute · L391

Source: [AddonOptions/FluxOptionsUnitFrames.lua:391](../../AddonOptions/FluxOptionsUnitFrames.lua#L391). Type: `"toggle"`.

Applies to normal party frames, target and focus. Hide countdown text at 60 seconds or more; icons, stacks and swipes remain. Raid and compact party use the separate Party / Raid setting.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().auraTimersUnderMinute == true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L394) |
| set | `function(_, value) GetDB().auraTimersUnderMinute = value and true or false AfterAuraOptionsChange() if FluxPartyFrames and FluxPartyFrames.ApplyOptions then FluxPartyFrames.ApplyOptions() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L395) |

### raidSettingsScope · Party / raid settings scope · L402

Source: [AddonOptions/FluxOptionsUnitFrames.lua:402](../../AddonOptions/FluxOptionsUnitFrames.lua#L402). Type: `"select"`.

Account-wide stores party and raid options in the active profile. Character-specific keeps them on this character only.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L408) |
| get | `function() return FluxOptions:IsRaidFramesCharacterSpecific() and "character" or "account" end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L413) |
| set | `function(_, val) FluxOptions:SetRaidFrameCharacterSpecific(val == "character") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L416) |

### useFluxRaidFrames · Party / raid · L421

Source: [AddonOptions/FluxOptionsUnitFrames.lua:421](../../AddonOptions/FluxOptionsUnitFrames.lua#L421). Type: `"toggle"`.

Use Flux compact party and raid frames. When off, Blizzard party and raid frames are restored.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {} return db.useFluxRaidFrames ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L426) |
| set | `function(_, v) local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() if db then db.useFluxRaidFrames = v and true or false end if FluxOptions and FluxOptions.RefreshRaidFrameScopedModules then FluxOptions:RefreshRaid…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L430) |

### resetRaidFrames · Reset party / raid options · L441

Source: [AddonOptions/FluxOptionsUnitFrames.lua:441](../../AddonOptions/FluxOptionsUnitFrames.lua#L441). Type: `"execute"`.

Restores Party / Raid tab settings for the current party / raid scope.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxOptions and FluxOptions.ResetRaidFramesToDefaults then FluxOptions:ResetRaidFramesToDefaults() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L447) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L446) |

### playerExtrasHeader · Player extras · L464

Source: [AddonOptions/FluxOptionsUnitFrames.lua:464](../../AddonOptions/FluxOptionsUnitFrames.lua#L464). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusTargetHeader · Focus target · L572

Source: [AddonOptions/FluxOptionsUnitFrames.lua:572](../../AddonOptions/FluxOptionsUnitFrames.lua#L572). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusTargetDesc · The focus target bar matches the focus frame size. · L577

Source: [AddonOptions/FluxOptionsUnitFrames.lua:577](../../AddonOptions/FluxOptionsUnitFrames.lua#L577). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### focustargetClassHP · Class-colored focus target HP · L592

Source: [AddonOptions/FluxOptionsUnitFrames.lua:592](../../AddonOptions/FluxOptionsUnitFrames.lua#L592). Type: `"toggle"`.

Use class color when the focus target is a player. NPC targets keep their usual color.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().classColorFocusTargetHP == true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L595) |
| set | `function(_, value) GetDB().classColorFocusTargetHP = value and true or false if FluxUnitFrames_RefreshTargetHealthColors then FluxUnitFrames_RefreshTargetHealthColors() end AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L596) |

### pettargetClassHP · Class-colored pet target HP · L623

Source: [AddonOptions/FluxOptionsUnitFrames.lua:623](../../AddonOptions/FluxOptionsUnitFrames.lua#L623). Type: `"toggle"`.

Use class color when your pet's target is a player. NPC targets keep their usual color.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().classColorPetTargetHP == true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L626) |
| set | `function(_, value) GetDB().classColorPetTargetHP = value and true or false if FluxUnitFrames_RefreshTargetHealthColors then FluxUnitFrames_RefreshTargetHealthColors() end AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L627) |

### description · School and spell visual themes for Flux cast bars. Hybrid spells combine every school’s colors and effects. I… · L662

Source: [AddonOptions/FluxOptionsUnitFrames.lua:662](../../AddonOptions/FluxOptionsUnitFrames.lua#L662). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### [key] · label · L668

Source: [AddonOptions/FluxOptionsUnitFrames.lua:668](../../AddonOptions/FluxOptionsUnitFrames.lua#L668). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return get(key) ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L670) |
| set | `function(_, value) set(key, value and true or false) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L671) |
| disabled | `function() return (key ~= "enabled" and get("enabled") == false) or (key == "gradient" and get("colors") == false) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L672) |

### bars · Cast bars · L679

Source: [AddonOptions/FluxOptionsUnitFrames.lua:679](../../AddonOptions/FluxOptionsUnitFrames.lua#L679). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### detection · Spell appearance · L687

Source: [AddonOptions/FluxOptionsUnitFrames.lua:687](../../AddonOptions/FluxOptionsUnitFrames.lua#L687). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### effects · Shared appearance · L692

Source: [AddonOptions/FluxOptionsUnitFrames.lua:692](../../AddonOptions/FluxOptionsUnitFrames.lua#L692). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### [key] · label · L700

Source: [AddonOptions/FluxOptionsUnitFrames.lua:700](../../AddonOptions/FluxOptionsUnitFrames.lua#L700). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L701) |
| max | `maximum` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L701) |
| step | `5` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L701) |
| get | `function() return get(key) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L702) |
| set | `function(_, value) set(key, value) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L703) |
| disabled | `function() return get("enabled") == false or (requires and get(requires) == false) or (key == "glowOpacity" and get("halo") == false and get("edge") == false) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L704) |

### reset · Reset school themes · L713

Source: [AddonOptions/FluxOptionsUnitFrames.lua:713](../../AddonOptions/FluxOptionsUnitFrames.lua#L713). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local db = GetDB() db.castBarThemes = {} for key, value in pairs(defaults) do db.castBarThemes[key] = value end if ns.CastBarThemes then ns.CastBarThemes.Refresh() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L715) |

### &lt;anonymous&gt; · Cast bar school themes · L722

Source: [AddonOptions/FluxOptionsUnitFrames.lua:722](../../AddonOptions/FluxOptionsUnitFrames.lua#L722). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### options · Unit frames · L726

Source: [AddonOptions/FluxOptionsUnitFrames.lua:726](../../AddonOptions/FluxOptionsUnitFrames.lua#L726). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### general · General · L735

Source: [AddonOptions/FluxOptionsUnitFrames.lua:735](../../AddonOptions/FluxOptionsUnitFrames.lua#L735). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### scopeHeader · Settings · L740

Source: [AddonOptions/FluxOptionsUnitFrames.lua:740](../../AddonOptions/FluxOptionsUnitFrames.lua#L740). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### settingsScope · Unit frame settings scope · L745

Source: [AddonOptions/FluxOptionsUnitFrames.lua:745](../../AddonOptions/FluxOptionsUnitFrames.lua#L745). Type: `"select"`.

Account-wide stores these options in the active profile (follows the Profiles tab). Character-specific keeps them on this character only, independent of General &gt; Settings scope.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L751) |
| get | `function() return FluxOptions:IsUnitFramesCharacterSpecific() and "character" or "account" end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L756) |
| set | `function(_, val) FluxOptions:SetUnitFrameCharacterSpecific(val == "character") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L759) |

### scopeDesc · This scope applies to every sub-tab below. Character-specific unit frame data is not duplicated when you copy… · L763

Source: [AddonOptions/FluxOptionsUnitFrames.lua:763](../../AddonOptions/FluxOptionsUnitFrames.lua#L763). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### fluxVsBlizHeader · Flux vs Blizzard · L770

Source: [AddonOptions/FluxOptionsUnitFrames.lua:770](../../AddonOptions/FluxOptionsUnitFrames.lua#L770). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### fluxVsBlizDesc · When Flux is off for a unit, the default Blizzard frame is used. Pet and target-of-target require the Flux pl… · L775

Source: [AddonOptions/FluxOptionsUnitFrames.lua:775](../../AddonOptions/FluxOptionsUnitFrames.lua#L775). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### useFluxPlayer · Player · L782

Source: [AddonOptions/FluxOptionsUnitFrames.lua:782](../../AddonOptions/FluxOptionsUnitFrames.lua#L782). Type: `"toggle"`.

Use Flux player frame. When off, Blizzard PlayerFrame is used; Flux pet requires Flux player.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxPlayer ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L788) |
| set | `function(_, v) GetDB().useFluxPlayer = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L789) |

### useFluxTarget · Target · L794

Source: [AddonOptions/FluxOptionsUnitFrames.lua:794](../../AddonOptions/FluxOptionsUnitFrames.lua#L794). Type: `"toggle"`.

Use Flux target frame. When off, Blizzard TargetFrame is used. Target-of-target (Flux) requires Flux target.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L800) |
| set | `function(_, v) GetDB().useFluxTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L801) |

### useFluxTargetOfTarget · Target of target · L806

Source: [AddonOptions/FluxOptionsUnitFrames.lua:806](../../AddonOptions/FluxOptionsUnitFrames.lua#L806). Type: `"toggle"`.

Requires Flux target. When off, Blizzard ToT is used if available.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxTargetOfTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L813) |
| set | `function(_, v) GetDB().useFluxTargetOfTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L814) |
| disabled | `function() return GetDB().useFluxTarget == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L812) |

### useFluxFocus · Focus · L819

Source: [AddonOptions/FluxOptionsUnitFrames.lua:819](../../AddonOptions/FluxOptionsUnitFrames.lua#L819). Type: `"toggle"`.

Use Flux focus frame. When off, Blizzard FocusFrame is used. Focus target bar requires Flux focus.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxFocus ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L826) |
| set | `function(_, v) GetDB().useFluxFocus = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L827) |
| hidden | `function() return not HasFocusUnit() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L825) |

### useFluxFocusTarget · Focus target · L832

Source: [AddonOptions/FluxOptionsUnitFrames.lua:832](../../AddonOptions/FluxOptionsUnitFrames.lua#L832). Type: `"toggle"`.

Requires Flux focus. When off, Blizzard focus ToT is used.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxFocusTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L840) |
| set | `function(_, v) GetDB().useFluxFocusTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L841) |
| hidden | `function() return not HasFocusUnit() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L838) |
| disabled | `function() return GetDB().useFluxFocus == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L839) |

### useFluxPet · Pet · L846

Source: [AddonOptions/FluxOptionsUnitFrames.lua:846](../../AddonOptions/FluxOptionsUnitFrames.lua#L846). Type: `"toggle"`.

Requires Flux player frame. When off, Blizzard PetFrame is used.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxPet ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L853) |
| set | `function(_, v) GetDB().useFluxPet = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L854) |
| disabled | `function() return GetDB().useFluxPlayer == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L852) |

### useFluxPetTarget · Pet target · L859

Source: [AddonOptions/FluxOptionsUnitFrames.lua:859](../../AddonOptions/FluxOptionsUnitFrames.lua#L859). Type: `"toggle"`.

Requires Flux pet (and Flux player). When off, pet target strip is not created.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxPetTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L869) |
| set | `function(_, v) GetDB().useFluxPetTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L870) |
| disabled | `function() local d = GetDB() return d.useFluxPlayer == false or d.useFluxPet == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L865) |

### resetUnitFrames · Reset unit frame options to defaults · L876

Source: [AddonOptions/FluxOptionsUnitFrames.lua:876](../../AddonOptions/FluxOptionsUnitFrames.lua#L876). Type: `"execute"`.

Restores Flux vs Blizzard toggles and feature toggles to FluxUI defaults for the current scope (all unit frame tabs).

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxOptions and FluxOptions.ResetUnitFramesToDefaults then FluxOptions:ResetUnitFramesToDefaults() end AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L883) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L882) |

### featuresHeader · Features · L891

Source: [AddonOptions/FluxOptionsUnitFrames.lua:891](../../AddonOptions/FluxOptionsUnitFrames.lua#L891). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### featuresDesc · These options apply immediately to Flux unit frames. · L896

Source: [AddonOptions/FluxOptionsUnitFrames.lua:896](../../AddonOptions/FluxOptionsUnitFrames.lua#L896). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### use3DPortraits · 3D portraits · L902

Source: [AddonOptions/FluxOptionsUnitFrames.lua:902](../../AddonOptions/FluxOptionsUnitFrames.lua#L902). Type: `"toggle"`.

When enabled, the portrait strip uses animated 3D models. When disabled, classic flat (2D) portraits are used for player, target, focus, and pet.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().use3DPortraits ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L908) |
| set | `function(_, v) GetDB().use3DPortraits = v and true or false if FluxUnitFrames_RefreshPortraitRenderModeFromDB then FluxUnitFrames_RefreshPortraitRenderModeFromDB() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L911) |

### enablePortraitCombatTint · Combat portrait tint · L918

Source: [AddonOptions/FluxOptionsUnitFrames.lua:918](../../AddonOptions/FluxOptionsUnitFrames.lua#L918). Type: `"toggle"`.

When this unit is in combat, its portrait border and the background behind the portrait turn red. Each frame uses its own unit, so a target or focus in combat stays red even if you are not.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enablePortraitCombatTint ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L924) |
| set | `function(_, v) GetDB().enablePortraitCombatTint = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L927) |

### enableHealthLossOverlay · Health loss overlay · L932

Source: [AddonOptions/FluxOptionsUnitFrames.lua:932](../../AddonOptions/FluxOptionsUnitFrames.lua#L932). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableHealthLossOverlay ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L937) |
| set | `function(_, v) GetDB().enableHealthLossOverlay = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L938) |

### enablePowerCostOverlay · Power cost overlay · L943

Source: [AddonOptions/FluxOptionsUnitFrames.lua:943](../../AddonOptions/FluxOptionsUnitFrames.lua#L943). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enablePowerCostOverlay ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L948) |
| set | `function(_, v) GetDB().enablePowerCostOverlay = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L949) |

### enableMP5Overlay · MP5 / mana tick overlay (player) · L954

Source: [AddonOptions/FluxOptionsUnitFrames.lua:954](../../AddonOptions/FluxOptionsUnitFrames.lua#L954). Type: `"toggle"`.

Show five-second-rule and mana-tick markers on Era, Anniversary/TBC, and Forever clients.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableMP5Overlay ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L960) |
| set | `function(_, v) GetDB().enableMP5Overlay = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L961) |

### swingTimerUnsupportedNote · Weapon swing timer is unavailable on live post-Dragonflight retail and on Cataclysm / Mists Classic. Classic … · L966

Source: [AddonOptions/FluxOptionsUnitFrames.lua:966](../../AddonOptions/FluxOptionsUnitFrames.lua#L966). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return IsSwingTimerClientSupported() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L972) |

### enableSwingTimer · Weapon swing timer (player) · L974

Source: [AddonOptions/FluxOptionsUnitFrames.lua:974](../../AddonOptions/FluxOptionsUnitFrames.lua#L974). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableSwingTimer ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L980) |
| set | `function(_, v) GetDB().enableSwingTimer = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L981) |
| hidden | `function() return not IsSwingTimerClientSupported() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L979) |

### enableFlightPathTimers · Flight path timers · L986

Source: [AddonOptions/FluxOptionsUnitFrames.lua:986](../../AddonOptions/FluxOptionsUnitFrames.lua#L986). Type: `"toggle"`.

Show flight duration on taxi map tooltips and a progress bar on the player cast bar while flying. Uses bundled flight-time data with optional overrides after landing.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableFlightPathTimers ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L992) |
| set | `function(_, v) GetDB().enableFlightPathTimers = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L993) |

### enableFlightPathCastBar · Flight path cast bar (player) · L998

Source: [AddonOptions/FluxOptionsUnitFrames.lua:998](../../AddonOptions/FluxOptionsUnitFrames.lua#L998). Type: `"toggle"`.

Show in-flight progress on the player unit frame cast bar slot.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableFlightPathCastBar ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1005) |
| set | `function(_, v) GetDB().enableFlightPathCastBar = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1006) |
| disabled | `function() return GetDB().enableFlightPathTimers == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1004) |

### enableFlightPathTooltips · Flight path taxi map tooltips · L1011

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1011](../../AddonOptions/FluxOptionsUnitFrames.lua#L1011). Type: `"toggle"`.

Append estimated flight duration when hovering reachable destinations on the taxi map.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableFlightPathTooltips ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1018) |
| set | `function(_, v) GetDB().enableFlightPathTooltips = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1019) |
| disabled | `function() return GetDB().enableFlightPathTimers == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1017) |

### showNumericThreat · Show threat percentage · L1025

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1025](../../AddonOptions/FluxOptionsUnitFrames.lua#L1025). Type: `"toggle"`.

Shows tank-relative threat % (100% = you have aggro) on the target/focus threat bar and on nameplates, plus your placement in the group.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local ThreatAPI = ns.Flux and ns.Flux.Threat if ThreatAPI and ThreatAPI.ShowNumeric then return ThreatAPI.ShowNumeric() end return true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1031) |
| set | `function(_, v) local ThreatAPI = ns.Flux and ns.Flux.Threat if ThreatAPI and ThreatAPI.SetShowNumeric then ThreatAPI.SetShowNumeric(v) end if FluxUnitFrames_ApplyThreatBarOptionsFromDB then FluxUnitFrames_ApplyThreatBarOptionsFromDB() end if FluxNam…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1038) |

### nameplateOptionsPointer · Nameplate Progressive, Flash, Health Bar Color, and Threat warning are on the Nameplates page. · L1051

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1051](../../AddonOptions/FluxOptionsUnitFrames.lua#L1051). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### unitPlayer · Player · L1062

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1062](../../AddonOptions/FluxOptionsUnitFrames.lua#L1062). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### playerShowPortrait · Show portrait strip · L1067

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1067](../../AddonOptions/FluxOptionsUnitFrames.lua#L1067). Type: `"toggle"`.

When off, only the bar column is shown and it stays centered at the bottom of the screen. When on, the side portrait strip is shown (3D vs flat is set under General -&gt; Features). Applies immediately. Third-party addons that replace the portrait (e.g. BigDebuffs) get a layout refresh when this changes.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitPlayer ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1073) |
| set | `function(_, v) GetDB().showPortraitPlayer = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1076) |

### playerTargetScale · Player + target scale (%) · L1081

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1081](../../AddonOptions/FluxOptionsUnitFrames.lua#L1081). Type: `"range"`.

Scales the complete player and target frames and their attached cast bars, auras, indicators and target-of-target frame.

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1084) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1084) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1084) |
| get | `function() return (FluxUnitFrames_GetWholeFrameScale and FluxUnitFrames_GetWholeFrameScale("player") or 1) * 100 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1085) |
| set | `function(_, value) GetDB().frameScalePlayerTarget = math.max(50, math.min(200, tonumber(value) or 100)) / 100 AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1088) |

### playerWidth · Width · L1093

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1093](../../AddonOptions/FluxOptionsUnitFrames.lua#L1093). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `150` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1098) |
| max | `600` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1099) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1100) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("player", "width") end fs.player = fs.player or {} local raw = fs.player.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("player", "widt…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1101) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.player = fs.player or {} fs.player.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1113) |

### playerHeight · Height · L1123

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1123](../../AddonOptions/FluxOptionsUnitFrames.lua#L1123). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1128) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1129) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1130) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("player", "height") end fs.player = fs.player or {} local raw = fs.player.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("player", "he…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1131) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.player = fs.player or {} fs.player.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1143) |

### playerHealthSplit · Health / resource split % · L1153

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1153](../../AddonOptions/FluxOptionsUnitFrames.lua#L1153). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown. Alternate power (third bar) still uses a fixed three-way split.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1159) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1160) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1161) |
| get | `function() return HealthPartitionGetFor("player") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1162) |
| set | `function(_, val) HealthPartitionSetFor("player", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1165) |

### unitTarget · Target · L1172

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1172](../../AddonOptions/FluxOptionsUnitFrames.lua#L1172). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### targetShowPortrait · Show portrait strip · L1177

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1177](../../AddonOptions/FluxOptionsUnitFrames.lua#L1177). Type: `"toggle"`.

When off, only the bar column is shown and it stays centered at the top of the screen. When on, the side portrait strip is shown (3D vs flat is under General -&gt; Features). Applies immediately; BigDebuffs and similar mods receive a refresh hook.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1183) |
| set | `function(_, v) GetDB().showPortraitTarget = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1186) |

### targetNoTargetPlaceholder · Empty target placeholder · L1191

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1191](../../AddonOptions/FluxOptionsUnitFrames.lua#L1191). Type: `"toggle"`.

When enabled, a subtle gray outline marks the target frame area while you have nothing targeted. Turn off to hide that box.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showTargetNoTargetPlaceholder ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1197) |
| set | `function(_, v) GetDB().showTargetNoTargetPlaceholder = v and true or false AfterTargetPlaceholderChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1200) |

### targetSizeFollowsPlayerNote · Layout is set to side-by-side (Layout tab): target width and height match the Player tab - adjust size there. · L1205

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1205](../../AddonOptions/FluxOptionsUnitFrames.lua#L1205). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not IsSideBySidePlayerTargetLayout() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1211) |

### targetWidth · Width · L1215

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1215](../../AddonOptions/FluxOptionsUnitFrames.lua#L1215). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1220) |
| max | `800` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1221) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1222) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("target", "width") end fs.target = fs.target or {} local raw = fs.target.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("target", "widt…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1226) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.target = fs.target or {} fs.target.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1238) |
| hidden | `function() return IsSideBySidePlayerTargetLayout() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1223) |

### targetHeight · Height · L1248

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1248](../../AddonOptions/FluxOptionsUnitFrames.lua#L1248). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1253) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1254) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1255) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("target", "height") end fs.target = fs.target or {} local raw = fs.target.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("target", "he…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1259) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.target = fs.target or {} fs.target.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1271) |
| hidden | `function() return IsSideBySidePlayerTargetLayout() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1256) |

### targetHealthSplit · Health / resource split % · L1281

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1281](../../AddonOptions/FluxOptionsUnitFrames.lua#L1281). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1287) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1288) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1289) |
| get | `function() return HealthPartitionGetFor("target") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1290) |
| set | `function(_, val) HealthPartitionSetFor("target", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1293) |

### targetAurasHeader · Auras · L1297

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1297](../../AddonOptions/FluxOptionsUnitFrames.lua#L1297). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### targetAuraBuffSize · Buff icon size · L1302

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1302](../../AddonOptions/FluxOptionsUnitFrames.lua#L1302). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1307) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1308) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1309) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.buffSize or 35 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1310) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.buffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1315) |

### targetAuraDebuffSize · Debuff icon size · L1322

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1322](../../AddonOptions/FluxOptionsUnitFrames.lua#L1322). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1327) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1328) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1329) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.debuffSize or 35 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1330) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.debuffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1335) |

### targetAuraLockOwnDebuffSize · Lock own debuff size · L1342

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1342](../../AddonOptions/FluxOptionsUnitFrames.lua#L1342). Type: `"toggle"`.

Keep your player/pet/vehicle debuffs at full boosted size (~1.38x). Other players' debuffs can shrink to fit the panel (Classic) or stay at the configured size (Midnight/Forever). When off, yours can shrink down to Own debuff min scale.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1348) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.lockOwnDebuffSize = v and true or false AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1353) |

### targetAuraOwnDebuffMinScale · Own debuff min scale · L1360

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1360](../../AddonOptions/FluxOptionsUnitFrames.lua#L1360). Type: `"range"`.

When lock is off, the smallest your own debuffs can get (100% = full boosted size, 50% = half of boosted). They stay larger than other players' icons while the panel is shrinking. Disabled while lock is on. On Midnight/Forever this sets own icon size directly (those frames do not fit-shrink).

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1366) |
| max | `100` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1367) |
| step | `5` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1368) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} local s = tonumber(d.auraTarget.ownDebuffMinScale) or 0.75 return math.floor(s * 100 + 0.5) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1376) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.ownDebuffMinScale = (tonumber(v) or 75) / 100 AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1382) |
| disabled | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1371) |

### targetAuraBuffSpacing · Buff spacing · L1389

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1389](../../AddonOptions/FluxOptionsUnitFrames.lua#L1389). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1394) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1395) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1396) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.buffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1397) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.buffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1402) |

### targetAuraDebuffSpacing · Debuff spacing · L1409

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1409](../../AddonOptions/FluxOptionsUnitFrames.lua#L1409). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1414) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1415) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1416) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.debuffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1417) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.debuffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1422) |

### targetAuraMaxBuffs · Max buff icons · L1429

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1429](../../AddonOptions/FluxOptionsUnitFrames.lua#L1429). Type: `"range"`.

Increasing above the previous cap rebuilds the buff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `8` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1435) |
| max | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1436) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1437) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.maxBuffs or 32 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1438) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.maxBuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1443) |

### targetAuraMaxDebuffs · Max debuff icons · L1450

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1450](../../AddonOptions/FluxOptionsUnitFrames.lua#L1450). Type: `"range"`.

Increasing above the previous cap rebuilds the debuff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `4` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1456) |
| max | `24` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1457) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1458) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.maxDebuffs or 16 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1459) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.maxDebuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1464) |

### targetThreatHeader · Threat · L1471

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1471](../../AddonOptions/FluxOptionsUnitFrames.lua#L1471). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### targetThreatBarPosition · Threat bar position · L1477

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1477](../../AddonOptions/FluxOptionsUnitFrames.lua#L1477). Type: `"select"`.

Portrait overlays the portrait when you have threat. Between reserves a strip between the frame chrome and auras. Left/Right are vertical strips for enemy NPCs only. In side-by-side Layout, Left is coerced to Right so the strip stays on the outer edge.

| Contract | Source expression / implementation |
|---|---|
| values | `{ portrait = "Portrait overlay", between = "Between chrome and auras", left = "Left (vertical)", right = "Right (vertical)", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1483) |
| get | `function() local v = GetDB().threatBarPositionTarget if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then return "portrait" end return v end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1489) |
| set | `function(_, v) if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then v = "portrait" end GetDB().threatBarPositionTarget = v if FluxUnitFrames_ApplyThreatBarOptionsFromDB then FluxUnitFrames_ApplyThreatBarOptionsFromDB() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1496) |

### unitTargetOfTarget · Target of target · L1509

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1509](../../AddonOptions/FluxOptionsUnitFrames.lua#L1509). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### totWidth · Width · L1514

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1514](../../AddonOptions/FluxOptionsUnitFrames.lua#L1514). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `80` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1519) |
| max | `300` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1520) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1521) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("targettarget", "width") end fs.targettarget = fs.targettarget or {} local raw = fs.targettarget.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return De…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1522) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.targettarget = fs.targettarget or {} fs.targettarget.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1534) |

### totHeight · Height · L1544

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1544](../../AddonOptions/FluxOptionsUnitFrames.lua#L1544). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `30` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1549) |
| max | `120` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1550) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1551) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("targettarget", "height") end fs.targettarget = fs.targettarget or {} local raw = fs.targettarget.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return …` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1552) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.targettarget = fs.targettarget or {} fs.targettarget.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1564) |

### totHealthSplit · Health / resource split % · L1574

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1574](../../AddonOptions/FluxOptionsUnitFrames.lua#L1574). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1580) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1581) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1582) |
| get | `function() return HealthPartitionGetFor("targettarget") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1583) |
| set | `function(_, val) HealthPartitionSetFor("targettarget", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1586) |

### unitFocus · Focus · L1593

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1593](../../AddonOptions/FluxOptionsUnitFrames.lua#L1593). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not HasFocusUnit() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1597) |

### focusShowPortrait · Show portrait strip · L1599

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1599](../../AddonOptions/FluxOptionsUnitFrames.lua#L1599). Type: `"toggle"`.

When off, only the bar column is shown (focus frame repositions from chat; focus target bar matches width). When on, the side portrait strip is shown (3D vs flat is under General -&gt; Features). Applies immediately.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitFocus ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1605) |
| set | `function(_, v) GetDB().showPortraitFocus = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1608) |

### focusFrameScale · Focus scale (%) · L1613

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1613](../../AddonOptions/FluxOptionsUnitFrames.lua#L1613). Type: `"range"`.

Scales the complete focus frame, attached cast bar, auras, indicators and focus-target frame.

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1616) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1616) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1616) |
| get | `function() return (FluxUnitFrames_GetWholeFrameScale and FluxUnitFrames_GetWholeFrameScale("focus") or 1) * 100 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1617) |
| set | `function(_, value) GetDB().frameScaleFocus = math.max(50, math.min(200, tonumber(value) or 100)) / 100 AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1620) |

### focusWidth · Width · L1625

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1625](../../AddonOptions/FluxOptionsUnitFrames.lua#L1625). Type: `"range"`.

Focus layout units. The default proportions match a normal party member; whole-frame scale remains independent.

| Contract | Source expression / implementation |
|---|---|
| min | `80` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1631) |
| max | `250` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1632) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1633) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("focus", "width") end fs.focus = fs.focus or {} local raw = fs.focus.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("focus", "width") e…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1634) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.focus = fs.focus or {} fs.focus.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1646) |

### focusHeight · Height · L1656

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1656](../../AddonOptions/FluxOptionsUnitFrames.lua#L1656). Type: `"range"`.

Focus layout units. The default proportions match a normal party member; whole-frame scale remains independent.

| Contract | Source expression / implementation |
|---|---|
| min | `30` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1662) |
| max | `120` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1663) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1664) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("focus", "height") end fs.focus = fs.focus or {} local raw = fs.focus.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("focus", "height"…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1665) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.focus = fs.focus or {} fs.focus.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1677) |

### focusHealthSplit · Health / resource split % · L1687

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1687](../../AddonOptions/FluxOptionsUnitFrames.lua#L1687). Type: `"range"`.

Share of the inner bar stack for health; also used for the focus target-of-target strip height.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1693) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1694) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1695) |
| get | `function() return HealthPartitionGetFor("focus") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1696) |
| set | `function(_, val) HealthPartitionSetFor("focus", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1699) |

### focusAurasHeader · Auras · L1703

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1703](../../AddonOptions/FluxOptionsUnitFrames.lua#L1703). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusAuraBuffSize · Buff icon size · L1708

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1708](../../AddonOptions/FluxOptionsUnitFrames.lua#L1708). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1713) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1714) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1715) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.buffSize or 20 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1716) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.buffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1721) |

### focusAuraDebuffSize · Debuff icon size · L1728

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1728](../../AddonOptions/FluxOptionsUnitFrames.lua#L1728). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1733) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1734) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1735) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.debuffSize or 20 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1736) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.debuffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1741) |

### focusAuraLockOwnDebuffSize · Lock own debuff size · L1748

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1748](../../AddonOptions/FluxOptionsUnitFrames.lua#L1748). Type: `"toggle"`.

Keep your player/pet/vehicle debuffs at full boosted size (~1.38x). Other players' debuffs can shrink to fit the panel (Classic) or stay at the configured size (Midnight/Forever). When off, yours can shrink down to Own debuff min scale.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1754) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.lockOwnDebuffSize = v and true or false AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1759) |

### focusAuraOwnDebuffMinScale · Own debuff min scale · L1766

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1766](../../AddonOptions/FluxOptionsUnitFrames.lua#L1766). Type: `"range"`.

When lock is off, the smallest your own debuffs can get (100% = full boosted size, 50% = half of boosted). They stay larger than other players' icons while the panel is shrinking. Disabled while lock is on. On Midnight/Forever this sets own icon size directly (those frames do not fit-shrink).

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1772) |
| max | `100` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1773) |
| step | `5` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1774) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} local s = tonumber(d.auraFocus.ownDebuffMinScale) or 0.75 return math.floor(s * 100 + 0.5) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1782) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.ownDebuffMinScale = (tonumber(v) or 75) / 100 AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1788) |
| disabled | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1777) |

### focusAuraBuffSpacing · Buff spacing · L1795

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1795](../../AddonOptions/FluxOptionsUnitFrames.lua#L1795). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1800) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1801) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1802) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.buffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1803) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.buffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1808) |

### focusAuraDebuffSpacing · Debuff spacing · L1815

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1815](../../AddonOptions/FluxOptionsUnitFrames.lua#L1815). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1820) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1821) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1822) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.debuffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1823) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.debuffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1828) |

### focusAuraMaxBuffs · Max buff icons · L1835

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1835](../../AddonOptions/FluxOptionsUnitFrames.lua#L1835). Type: `"range"`.

Increasing above the previous cap rebuilds the buff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `8` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1841) |
| max | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1842) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1843) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.maxBuffs or 32 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1844) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.maxBuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1849) |

### focusAuraMaxDebuffs · Max debuff icons · L1856

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1856](../../AddonOptions/FluxOptionsUnitFrames.lua#L1856). Type: `"range"`.

Increasing above the previous cap rebuilds the debuff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `4` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1862) |
| max | `24` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1863) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1864) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.maxDebuffs or 16 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1865) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.maxDebuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1870) |

### focusThreatHeader · Threat · L1877

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1877](../../AddonOptions/FluxOptionsUnitFrames.lua#L1877). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusThreatBarPosition · Threat bar position · L1883

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1883](../../AddonOptions/FluxOptionsUnitFrames.lua#L1883). Type: `"select"`.

Portrait overlays the portrait when you have threat. Between reserves a strip between the frame chrome and auras. Left/Right are vertical strips for enemy NPCs only.

| Contract | Source expression / implementation |
|---|---|
| values | `{ portrait = "Portrait overlay", between = "Between chrome and auras", left = "Left (vertical)", right = "Right (vertical)", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1889) |
| get | `function() local v = GetDB().threatBarPositionFocus if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then return "portrait" end return v end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1895) |
| set | `function(_, v) if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then v = "portrait" end GetDB().threatBarPositionFocus = v if FluxUnitFrames_ApplyThreatBarOptionsFromDB then FluxUnitFrames_ApplyThreatBarOptionsFromDB() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1902) |

### unitPet · Pet · L1915

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1915](../../AddonOptions/FluxOptionsUnitFrames.lua#L1915). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### petShowPortrait · Show portrait strip · L1920

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1920](../../AddonOptions/FluxOptionsUnitFrames.lua#L1920). Type: `"toggle"`.

When off, only the pet bar column is shown (no portrait strip). When on, the side portrait strip is shown (3D vs flat is under General -&gt; Features). Applies immediately; the pet frame re-anchors to the player frame.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitPet ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1926) |
| set | `function(_, v) GetDB().showPortraitPet = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1929) |

### petShowCastBar · Show cast bar · L1934

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1934](../../AddonOptions/FluxOptionsUnitFrames.lua#L1934). Type: `"toggle"`.

Overlay a cast/channel bar on the pet resource bar. Off by default.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showCastBarPet == true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1940) |
| set | `function(_, v) GetDB().showCastBarPet = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1943) |

### petShowTooltipAuras · Show auras on mouseover · L1948

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1948](../../AddonOptions/FluxOptionsUnitFrames.lua#L1948). Type: `"toggle"`.

When hovering the pet frame, show buff and debuff icons with cooldown countdown next to the unit tooltip.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPetTooltipAuras ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1954) |
| set | `function(_, v) GetDB().showPetTooltipAuras = v and true or false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1957) |

### petWidth · Width · L1961

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1961](../../AddonOptions/FluxOptionsUnitFrames.lua#L1961). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `60` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1966) |
| max | `220` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1967) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1968) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("pet", "width") end fs.pet = fs.pet or {} local raw = fs.pet.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("pet", "width") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1969) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.pet = fs.pet or {} fs.pet.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1981) |

### petHeight · Height · L1991

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1991](../../AddonOptions/FluxOptionsUnitFrames.lua#L1991). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `30` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1996) |
| max | `120` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1997) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1998) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("pet", "height") end fs.pet = fs.pet or {} local raw = fs.pet.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("pet", "height") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1999) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.pet = fs.pet or {} fs.pet.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2011) |

### petHealthSplit · Health / resource split % · L2021

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2021](../../AddonOptions/FluxOptionsUnitFrames.lua#L2021). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2027) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2028) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2029) |
| get | `function() return HealthPartitionGetFor("pet") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2030) |
| set | `function(_, val) HealthPartitionSetFor("pet", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2033) |

### unitPetTarget · Pet target · L2040

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2040](../../AddonOptions/FluxOptionsUnitFrames.lua#L2040). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### petTargetWidth · Width · L2045

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2045](../../AddonOptions/FluxOptionsUnitFrames.lua#L2045). Type: `"range"`.

Vertical health strip next to the pet frame; height always matches the pet frame.

| Contract | Source expression / implementation |
|---|---|
| min | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2051) |
| max | `48` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2052) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2053) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("pettarget", "width") end fs.pettarget = fs.pettarget or {} local raw = fs.pettarget.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("pe…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2054) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.pettarget = fs.pettarget or {} fs.pettarget.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2066) |

### Factory expansions

Arguments select storage keys, unit names, labels, fallback values, ordering, and conditional availability. Follow the corresponding factory definition for the resulting getter/setter contract.

| Site | Factory and arguments |
|---|---|
| [AddonOptions/FluxOptionsUnitFrames.lua:291](../../AddonOptions/FluxOptionsUnitFrames.lua#L291) | `FlagToggle(unit, "castBar", "Cast bar", "Show the cast bar on this frame.", nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:294](../../AddonOptions/FluxOptionsUnitFrames.lua#L294) | `FlagToggle(unit, "castTime", "Cast time", "Show remaining time on the cast bar.", nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:297](../../AddonOptions/FluxOptionsUnitFrames.lua#L297) | `HealthTextOpt(unit, flags.health, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:307](../../AddonOptions/FluxOptionsUnitFrames.lua#L307) | `FlagToggle(unit, "powerText", "Power numbers", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:310](../../AddonOptions/FluxOptionsUnitFrames.lua#L310) | `FlagToggle(unit, "healPrediction", "Heal prediction", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:313](../../AddonOptions/FluxOptionsUnitFrames.lua#L313) | `FlagToggle(unit, "absorbs", "Absorbs", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:316](../../AddonOptions/FluxOptionsUnitFrames.lua#L316) | `FlagToggle(unit, "classPower", "Class power", "Combo points, runes, essence, and the other class resource bars.", nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:344](../../AddonOptions/FluxOptionsUnitFrames.lua#L344) | `FlagToggle(unit, "level", "Level", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:347](../../AddonOptions/FluxOptionsUnitFrames.lua#L347) | `FlagToggle(unit, "classIcon", "Class icon", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:350](../../AddonOptions/FluxOptionsUnitFrames.lua#L350) | `FlagToggle(unit, "pvp", "PvP flag", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:353](../../AddonOptions/FluxOptionsUnitFrames.lua#L353) | `FlagToggle(unit, "combat", "Combat icon", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:356](../../AddonOptions/FluxOptionsUnitFrames.lua#L356) | `FlagToggle(unit, "raidIcon", "Raid marker", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:359](../../AddonOptions/FluxOptionsUnitFrames.lua#L359) | `FlagToggle(unit, "portraitCombat", "Portrait combat text", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:362](../../AddonOptions/FluxOptionsUnitFrames.lua#L362) | `FlagToggle(unit, "mouseover", "Mouseover highlight", nil, nextOrder())` |
| [AddonOptions/FluxOptionsUnitFrames.lua:503](../../AddonOptions/FluxOptionsUnitFrames.lua#L503) | `AddTextAndBars(player, "player", 30, { castBar = true, castTime = true, health = "both", power = true, heal = true, absorb = true, classPower = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:512](../../AddonOptions/FluxOptionsUnitFrames.lua#L512) | `AddIcons(player, "player", 36, { level = true, classIcon = true, pvp = true, combat = true, raidIcon = true, portraitCombat = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:522](../../AddonOptions/FluxOptionsUnitFrames.lua#L522) | `AddTextAndBars(target, "target", 20, { castBar = true, castTime = true, health = "both", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:530](../../AddonOptions/FluxOptionsUnitFrames.lua#L530) | `AddIcons(target, "target", 26, { level = true, classIcon = true, pvp = true, raidIcon = true, portraitCombat = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:538](../../AddonOptions/FluxOptionsUnitFrames.lua#L538) | `AuraToggle("auraTarget", "showBuffs", "Show buffs", 3.6)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:539](../../AddonOptions/FluxOptionsUnitFrames.lua#L539) | `AuraToggle("auraTarget", "showDebuffs", "Show debuffs", 3.7)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:541](../../AddonOptions/FluxOptionsUnitFrames.lua#L541) | `AddTextAndBars(tot.args, "targettarget", 10, { header = "Text and bars", health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:548](../../AddonOptions/FluxOptionsUnitFrames.lua#L548) | `AddIcons(tot.args, "targettarget", 16, { raidIcon = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:554](../../AddonOptions/FluxOptionsUnitFrames.lua#L554) | `AddTextAndBars(focus, "focus", 20, { castBar = true, castTime = true, health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:562](../../AddonOptions/FluxOptionsUnitFrames.lua#L562) | `AddIcons(focus, "focus", 26, { level = true, classIcon = true, pvp = true, raidIcon = true, portraitCombat = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:570](../../AddonOptions/FluxOptionsUnitFrames.lua#L570) | `AuraToggle("auraFocus", "showBuffs", "Show buffs", 3.6)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:571](../../AddonOptions/FluxOptionsUnitFrames.lua#L571) | `AuraToggle("auraFocus", "showDebuffs", "Show debuffs", 3.7)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:583](../../AddonOptions/FluxOptionsUnitFrames.lua#L583) | `AddTextAndBars(focus, "focustarget", 70.1, { header = "Focus target text", health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:590](../../AddonOptions/FluxOptionsUnitFrames.lua#L590) | `FlagToggle("focustarget", "mouseover", "Mouseover highlight", nil, 71)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:591](../../AddonOptions/FluxOptionsUnitFrames.lua#L591) | `FlagToggle("focustarget", "raidIcon", "Raid marker", nil, 71.1)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:603](../../AddonOptions/FluxOptionsUnitFrames.lua#L603) | `AddTextAndBars(pet, "pet", 20, { castTime = true, health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:610](../../AddonOptions/FluxOptionsUnitFrames.lua#L610) | `AddIcons(pet, "pet", 26, { raidIcon = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:615](../../AddonOptions/FluxOptionsUnitFrames.lua#L615) | `AddTextAndBars(petTarget.args, "pettarget", 10, { header = "Text and bars", health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:622](../../AddonOptions/FluxOptionsUnitFrames.lua#L622) | `FlagToggle("pettarget", "mouseover", "Mouseover highlight", nil, 16)` |

## FluxOptionsVendor.lua

[AddonOptions/FluxOptionsVendor.lua](../../AddonOptions/FluxOptionsVendor.lua)

### &lt;anonymous&gt; · function() return L[label] end · L8

Source: [AddonOptions/FluxOptionsVendor.lua:8](../../AddonOptions/FluxOptionsVendor.lua#L8). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local auction = _G.FluxAuctionRestock if auction then return auction.IsUpgradeEnabled(kind) end return kind ~= "bandage" end` [source](../../AddonOptions/FluxOptionsVendor.lua#L12) |
| set | `function(_, value) local auction = _G.FluxAuctionRestock if auction then auction.SetUpgradeEnabled(kind, value) end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L17) |
| disabled | `function() local auction = _G.FluxAuctionRestock return auction and (auction.transaction ~= nil or auction.state == "quoting") or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L21) |

### [1] · function() return L.AH_FOLLOWUP_AUTO or "Automate auction restock follow-up" end · L47

Source: [AddonOptions/FluxOptionsVendor.lua:47](../../AddonOptions/FluxOptionsVendor.lua#L47). Type: `custom toggle descriptor`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local followup = _G.FluxAuctionRestock and FluxAuctionRestock.Followup return followup and followup.IsAutoEnabled and followup.IsAutoEnabled() == true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L51) |
| set | `function(value) local followup = _G.FluxAuctionRestock and FluxAuctionRestock.Followup if followup and followup.SetAutoEnabled then followup.SetAutoEnabled(value == true) end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L55) |

### [2] · function() return L.MAIL_RESTOCK_AUTO_OPTION or "Auto restock mail" end · L60

Source: [AddonOptions/FluxOptionsVendor.lua:60](../../AddonOptions/FluxOptionsVendor.lua#L60). Type: `custom toggle descriptor`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local mail = ns.Flux and ns.Flux.Mail return mail and mail.GetSetting and mail.GetSetting("Restock", "AutoCollect") == true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L64) |
| set | `function(value) local mail = ns.Flux and ns.Flux.Mail if mail and mail.SetSetting then mail.SetSetting("Restock", "AutoCollect", value == true) end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L68) |

### [3] · L.AUTO_OPEN_VENDOR · L73

Source: [AddonOptions/FluxOptionsVendor.lua:73](../../AddonOptions/FluxOptionsVendor.lua#L73). Type: `custom toggle descriptor`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local FV = _G.FluxVendorAuto local s = FV and FV.EnsureSettings and FV.EnsureSettings() return s and s.autoOpenVendorGossip == true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L81) |
| set | `function(val) local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return end FV.EnsureSettings().autoOpenVendorGossip = val and true or false if FV.RefreshVendorGossip then FV.RefreshVendorGossip() end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L86) |
| hidden | `function() local FV = _G.FluxVendorAuto return not (FV and FV.IsVendorGossipSupported and FV.IsVendorGossipSupported()) end` [source](../../AddonOptions/FluxOptionsVendor.lua#L77) |

### [4] · L.AUTO_OPEN_BANK · L93

Source: [AddonOptions/FluxOptionsVendor.lua:93](../../AddonOptions/FluxOptionsVendor.lua#L93). Type: `custom toggle descriptor`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local FV = _G.FluxVendorAuto local s = FV and FV.EnsureSettings and FV.EnsureSettings() return s and s.autoOpenBankGossip == true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L101) |
| set | `function(val) local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return end FV.EnsureSettings().autoOpenBankGossip = val and true or false if FV.RefreshVendorGossip then FV.RefreshVendorGossip() end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L106) |
| hidden | `function() local FV = _G.FluxVendorAuto return not (FV and FV.IsVendorGossipSupported and FV.IsVendorGossipSupported()) end` [source](../../AddonOptions/FluxOptionsVendor.lua#L97) |

### [5] · Auto repair · L113

Source: [AddonOptions/FluxOptionsVendor.lua:113](../../AddonOptions/FluxOptionsVendor.lua#L113). Type: `custom toggle descriptor`.

Repair gear at repair-capable merchants.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return false end local s = FV.EnsureSettings() return s and s.autoRepair and true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L117) |
| set | `function(val) local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return end local s = FV.EnsureSettings() s.autoRepair = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L125) |

### [6] · Bulk buy at vendor · L135

Source: [AddonOptions/FluxOptionsVendor.lua:135](../../AddonOptions/FluxOptionsVendor.lua#L135). Type: `custom toggle descriptor`.

Shift+click merchant items to open the bulk purchase window.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local BEA = _G.FluxBuyEmAll if BEA and BEA.IsEnabled then return BEA:IsEnabled() end _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {} return _FluxUI_CharSavedVars.buyEmAllEnabled ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L139) |
| set | `function(val) _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {} _FluxUI_CharSavedVars.buyEmAllEnabled = val and true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L147) |

### [7] · Confirm large bulk purchases · L152

Source: [AddonOptions/FluxOptionsVendor.lua:152](../../AddonOptions/FluxOptionsVendor.lua#L152). Type: `custom toggle descriptor`.

Show a confirmation dialog before very large vendor purchases. Same as /buyemall confirm.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local BEA = _G.FluxBuyEmAll if BEA and BEA.IsConfirmLargeEnabled then return BEA:IsConfirmLargeEnabled() end _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {} return _FluxUI_CharSavedVars.buyEmAllConfirmLarge ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L164) |
| set | `function(val) local BEA = _G.FluxBuyEmAll if BEA and BEA.SetConfirmLargeEnabled then BEA:SetConfirmLargeEnabled(val) return end _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {} _FluxUI_CharSavedVars.buyEmAllConfirmLarge = val and true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L172) |
| disabled | `function() local BEA = _G.FluxBuyEmAll if BEA and BEA.IsEnabled then return not BEA:IsEnabled() end _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {} return _FluxUI_CharSavedVars.buyEmAllEnabled == false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L156) |

### [8] · Guild bank first · L182

Source: [AddonOptions/FluxOptionsVendor.lua:182](../../AddonOptions/FluxOptionsVendor.lua#L182). Type: `custom toggle descriptor`.

Prefer guild bank over personal gold when auto repair runs.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return false end local s = FV.EnsureSettings() return s and (s.repairPriority or "personal") == "guild" end` [source](../../AddonOptions/FluxOptionsVendor.lua#L201) |
| set | `function(val) local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return end local s = FV.EnsureSettings() s.repairPriority = val and "guild" or "personal" NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L209) |
| hidden | `function() local FV = _G.FluxVendorAuto if not FV or not FV.ShouldShowGuildRepairPriorityOption then return true end return not FV.ShouldShowGuildRepairPriorityOption() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L186) |
| disabled | `function() local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return true end local s = FV.EnsureSettings() return not (s and s.autoRepair) end` [source](../../AddonOptions/FluxOptionsVendor.lua#L193) |

### [9] · Auto sell junk · L219

Source: [AddonOptions/FluxOptionsVendor.lua:219](../../AddonOptions/FluxOptionsVendor.lua#L219). Type: `custom toggle descriptor`.

Sell junk when a vendor opens.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return false end local s = FV.EnsureSettings() return s and s.autoSellGray and true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L223) |
| set | `function(val) local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return end local s = FV.EnsureSettings() s.autoSellGray = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L231) |

### [10] · Auto restock · L241

Source: [AddonOptions/FluxOptionsVendor.lua:241](../../AddonOptions/FluxOptionsVendor.lua#L241). Type: `custom toggle descriptor`.

Buy listed items up to their targets at vendors.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return false end local s = FV.EnsureSettings() return s and s.autoRestock and true or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L245) |
| set | `function(val) local FV = _G.FluxVendorAuto if not FV or not FV.EnsureSettings then return end local s = FV.EnsureSettings() s.autoRestock = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L253) |

### [11] · Auto bank restock · L263

Source: [AddonOptions/FluxOptionsVendor.lua:263](../../AddonOptions/FluxOptionsVendor.lua#L263). Type: `custom toggle descriptor`.

Refill bags from the bank toward restock targets when the bank opens.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local BR = _G.FluxBankRestock if BR and BR.IsAutoEnabled then return BR.IsAutoEnabled() and true or false end local FV = _G.FluxVendorAuto local s = FV and FV.EnsureSettings and FV.EnsureSettings() return s and s.autoBankRestock and true …` [source](../../AddonOptions/FluxOptionsVendor.lua#L267) |
| set | `function(val) local BR = _G.FluxBankRestock if BR and BR.SetAutoEnabled then BR.SetAutoEnabled(val and true or false) else local FV = _G.FluxVendorAuto local s = FV and FV.EnsureSettings and FV.EnsureSettings() if s then s.autoBankRestock = val and …` [source](../../AddonOptions/FluxOptionsVendor.lua#L276) |

### [1] · Low-level consumables · L295

Source: [AddonOptions/FluxOptionsVendor.lua:295](../../AddonOptions/FluxOptionsVendor.lua#L295). Type: `custom toggle descriptor`.

Mark low-level consumables as junk.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkFilters and s.junkFilters.consumable ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L299) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkFilters = s.junkFilters or {} s.junkFilters.consumable = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L303) |

### [2] · Unusable equipment · L310

Source: [AddonOptions/FluxOptionsVendor.lua:310](../../AddonOptions/FluxOptionsVendor.lua#L310). Type: `custom toggle descriptor`.

Mark gear your class cannot use as junk.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkFilters and s.junkFilters.unusable ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L314) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkFilters = s.junkFilters or {} s.junkFilters.unusable = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L318) |

### [3] · Sell non-conjured food & water · L325

Source: [AddonOptions/FluxOptionsVendor.lua:325](../../AddonOptions/FluxOptionsVendor.lua#L325). Type: `custom toggle descriptor`.

With Conjure Food, Water, or Refreshment learned: auto-junk non-conjured food/water (no Well Fed). Inferior tiers on the other axis still apply when conjure does not cover it.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkFilters and s.junkFilters.conjureInferiorFoodWater ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L329) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkFilters = s.junkFilters or {} s.junkFilters.conjureInferiorFoodWater = val and true or false local FJ = _G.FluxVendorJunk if FJ then if val and FJ.ScheduleConjureInferiorJunkSync then …` [source](../../AddonOptions/FluxOptionsVendor.lua#L333) |

### [4] · Destroy unsellable junk · L349

Source: [AddonOptions/FluxOptionsVendor.lua:349](../../AddonOptions/FluxOptionsVendor.lua#L349). Type: `custom toggle descriptor`.

Delete one unsellable junk item per vendor sell pass.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkFilters and s.junkFilters.destroy ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L353) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkFilters = s.junkFilters or {} s.junkFilters.destroy = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L357) |

### [5] · Safe batch sell · L364

Source: [AddonOptions/FluxOptionsVendor.lua:364](../../AddonOptions/FluxOptionsVendor.lua#L364). Type: `custom toggle descriptor`.

Sell junk in small batches.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkFilters and s.junkFilters.safe ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L368) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkFilters = s.junkFilters or {} s.junkFilters.safe = val and true or false NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L372) |

### [1] · Junk glow on bag slots · L381

Source: [AddonOptions/FluxOptionsVendor.lua:381](../../AddonOptions/FluxOptionsVendor.lua#L381). Type: `custom toggle descriptor`.

Show a glow on bag slots that contain junk.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkDisplay and s.junkDisplay.glow ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L385) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkDisplay = s.junkDisplay or {} s.junkDisplay.glow = val and true or false local FJ = _G.FluxVendorJunk if FJ and FJ.FireListChanged then FJ.FireListChanged() end NotifyVendorSettingsCha…` [source](../../AddonOptions/FluxOptionsVendor.lua#L389) |

### [2] · Junk coin icon on bag slots · L400

Source: [AddonOptions/FluxOptionsVendor.lua:400](../../AddonOptions/FluxOptionsVendor.lua#L400). Type: `custom toggle descriptor`.

Show a coin icon on bag slots that contain junk.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.junkDisplay and s.junkDisplay.icons ~= false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L404) |
| set | `function(val) local s = _G.FluxVendorAuto.EnsureSettings() s.junkDisplay = s.junkDisplay or {} s.junkDisplay.icons = val and true or false local FJ = _G.FluxVendorJunk if FJ and FJ.FireListChanged then FJ.FireListChanged() end NotifyVendorSettingsCh…` [source](../../AddonOptions/FluxOptionsVendor.lua#L408) |

### [toggle.key] · toggle.name or toggle.key · L430

Source: [AddonOptions/FluxOptionsVendor.lua:430](../../AddonOptions/FluxOptionsVendor.lua#L430). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return toggle.get and toggle.get() or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L437) |
| set | `function(_, val) if toggle.set then toggle.set(val) end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L440) |
| hidden | `toggle.hidden` [source](../../AddonOptions/FluxOptionsVendor.lua#L435) |
| disabled | `toggle.disabled` [source](../../AddonOptions/FluxOptionsVendor.lua#L436) |

### &lt;anonymous&gt; · Salvage · L451

Source: [AddonOptions/FluxOptionsVendor.lua:451](../../AddonOptions/FluxOptionsVendor.lua#L451). Type: `"group"`.

One-click mill, prospect, disenchant, and similar bag actions.

| Contract | Source expression / implementation |
|---|---|

### automationHeader · Automation · L460

Source: [AddonOptions/FluxOptionsVendor.lua:460](../../AddonOptions/FluxOptionsVendor.lua#L460). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### automationDesc · Repair, selling, and restock that run when a vendor or the bank opens. · L465

Source: [AddonOptions/FluxOptionsVendor.lua:465](../../AddonOptions/FluxOptionsVendor.lua#L465). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### junkHeader · Junk detection · L475

Source: [AddonOptions/FluxOptionsVendor.lua:475](../../AddonOptions/FluxOptionsVendor.lua#L475). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### junkListHelp · In the Restock tab junk grid: \|cffffcc66M\|r = manually added, \|cff888888A\|r = auto-marked. · L481

Source: [AddonOptions/FluxOptionsVendor.lua:481](../../AddonOptions/FluxOptionsVendor.lua#L481). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### bagHeader · Bag indicators · L489

Source: [AddonOptions/FluxOptionsVendor.lua:489](../../AddonOptions/FluxOptionsVendor.lua#L489). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### bagDesc · Marks on bag slots that hold junk. · L494

Source: [AddonOptions/FluxOptionsVendor.lua:494](../../AddonOptions/FluxOptionsVendor.lua#L494). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### alreadyKnownHeader · Already known items · L503

Source: [AddonOptions/FluxOptionsVendor.lua:503](../../AddonOptions/FluxOptionsVendor.lua#L503). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### alreadyKnownStandaloneNote · function() local AK = _G.FluxAlreadyKnown if AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded() then re… · L508

Source: [AddonOptions/FluxOptionsVendor.lua:508](../../AddonOptions/FluxOptionsVendor.lua#L508). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### alreadyKnownEnabled · Tint already-known items · L521

Source: [AddonOptions/FluxOptionsVendor.lua:521](../../AddonOptions/FluxOptionsVendor.lua#L521). Type: `"toggle"`.

Highlight vendor, auction, and guild-bank items you have already learned or collected.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local AK = _G.FluxAlreadyKnown if AK and AK.GetSettings then return AK.GetSettings().enabled ~= false end local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings() return s and s.alreadyKnown …` [source](../../AddonOptions/FluxOptionsVendor.lua#L530) |
| set | `function(_, val) local AK = _G.FluxAlreadyKnown if AK and AK.GetSettings then AK.GetSettings().enabled = val and true or false if AK.NotifySettingsChanged then AK.NotifySettingsChanged() end end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L538) |
| disabled | `function() local AK = _G.FluxAlreadyKnown return AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L526) |

### alreadyKnownMonochrome · Monochrome tint · L548

Source: [AddonOptions/FluxOptionsVendor.lua:548](../../AddonOptions/FluxOptionsVendor.lua#L548). Type: `"toggle"`.

Desaturate icons for already-known items.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local AK = _G.FluxAlreadyKnown return AK and AK.GetSettings and AK.GetSettings().monochrome or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L563) |
| set | `function(_, val) local AK = _G.FluxAlreadyKnown if AK and AK.GetSettings then AK.GetSettings().monochrome = val and true or false if AK.NotifySettingsChanged then AK.NotifySettingsChanged() end end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L567) |
| disabled | `function() local AK = _G.FluxAlreadyKnown if AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded() then return true end if AK and AK.GetSettings then return AK.GetSettings().enabled == false end return false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L553) |

### alreadyKnownColor · Tint color · L577

Source: [AddonOptions/FluxOptionsVendor.lua:577](../../AddonOptions/FluxOptionsVendor.lua#L577). Type: `"color"`.

Color used for already-known item highlights.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local AK = _G.FluxAlreadyKnown local db = AK and AK.GetSettings and AK.GetSettings() or { r = 0, g = 1, b = 0 } return db.r or 0, db.g or 1, db.b or 0 end` [source](../../AddonOptions/FluxOptionsVendor.lua#L593) |
| set | `function(_, r, g, b) local AK = _G.FluxAlreadyKnown if AK and AK.GetSettings then local db = AK.GetSettings() db.r, db.g, db.b = r, g, b if AK.NotifySettingsChanged then AK.NotifySettingsChanged() end end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L598) |
| disabled | `function() local AK = _G.FluxAlreadyKnown if AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded() then return true end if AK and AK.GetSettings then return AK.GetSettings().enabled == false end return false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L583) |

### keepWeakerHeader · function() return L.RESTOCK_KEEP_WEAKER_HEADER end · L610

Source: [AddonOptions/FluxOptionsVendor.lua:610](../../AddonOptions/FluxOptionsVendor.lua#L610). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### ["keepWeaker_" .. kind] · function() return L["RESTOCK_KEEP_WEAKER_" .. label] end · L614

Source: [AddonOptions/FluxOptionsVendor.lua:614](../../AddonOptions/FluxOptionsVendor.lua#L614). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local tiers = _G.FluxRestockTiers return not tiers or not tiers.IsCarriedUpgradeRequired or tiers.IsCarriedUpgradeRequired(kind) end` [source](../../AddonOptions/FluxOptionsVendor.lua#L618) |
| set | `function(_, enabled) local tiers = _G.FluxRestockTiers if tiers and tiers.SetCarriedUpgradeRequired then tiers.SetCarriedUpgradeRequired(kind, enabled) end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L622) |

### &lt;anonymous&gt; · Inventory · L628

Source: [AddonOptions/FluxOptionsVendor.lua:628](../../AddonOptions/FluxOptionsVendor.lua#L628). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### vendor · Vendor · L635

Source: [AddonOptions/FluxOptionsVendor.lua:635](../../AddonOptions/FluxOptionsVendor.lua#L635). Type: `"group"`.

Repair, selling, junk rules, bag markers, and already-known tint.

| Contract | Source expression / implementation |
|---|---|

### restock · Restock · L642

Source: [AddonOptions/FluxOptionsVendor.lua:642](../../AddonOptions/FluxOptionsVendor.lua#L642). Type: `"group"`.

Item targets to buy from vendors and pull from the bank.

| Contract | Source expression / implementation |
|---|---|

### restockHelp · Drag items into the grids. Preset restock lists spell reagents from your spell book. " .. "bags/target — stoc… · L648

Source: [AddonOptions/FluxOptionsVendor.lua:648](../../AddonOptions/FluxOptionsVendor.lua#L648). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### auctionRestock · function() return L.AH_OPEN or "Auction restock & prices" end · L657

Source: [AddonOptions/FluxOptionsVendor.lua:657](../../AddonOptions/FluxOptionsVendor.lua#L657). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local auction = _G.FluxAuctionRestock if auction and auction.Toggle then auction.Toggle() end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L663) |

### auctionCrafting · function() return L.AH_CRAFT_TOGGLE or "Prefer crafting materials" end · L668

Source: [AddonOptions/FluxOptionsVendor.lua:668](../../AddonOptions/FluxOptionsVendor.lua#L668). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local auction = _G.FluxAuctionRestock return auction and auction.PreferCrafting and auction.PreferCrafting() or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L674) |
| set | `function(_, value) local auction = _G.FluxAuctionRestock if auction and auction.SetPreferCrafting then auction.SetPreferCrafting(value) end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L678) |

### auctionExcludeDiscolored · function() return L.AH_EXCLUDE_DISCOLORED end · L683

Source: [AddonOptions/FluxOptionsVendor.lua:683](../../AddonOptions/FluxOptionsVendor.lua#L683). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local auction = _G.FluxAuctionRestock return not auction or auction.ExcludesDiscoloredHealing() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L687) |
| set | `function(_, enabled) local auction = _G.FluxAuctionRestock if auction then auction.SetExcludeDiscoloredHealing(enabled) end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L691) |

### auctionUpgradeBlacklistAdd · function() return L.AH_UPGRADE_BLACKLIST_ADD end · L699

Source: [AddonOptions/FluxOptionsVendor.lua:699](../../AddonOptions/FluxOptionsVendor.lua#L699). Type: `"input"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return "" end` [source](../../AddonOptions/FluxOptionsVendor.lua#L703) |
| set | `function(_, value) local auction = _G.FluxAuctionRestock if auction then auction.SetUpgradeBlacklisted(value, true) end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L708) |

### auctionUpgradeBlacklist · function() return L.AH_UPGRADE_BLACKLIST_LIST end · L713

Source: [AddonOptions/FluxOptionsVendor.lua:713](../../AddonOptions/FluxOptionsVendor.lua#L713). Type: `"multiselect"`.

| Contract | Source expression / implementation |
|---|---|
| values | `function() local auction = _G.FluxAuctionRestock return auction and auction.UpgradeBlacklistItems() or {} end` [source](../../AddonOptions/FluxOptionsVendor.lua#L717) |
| get | `function(_, id) local auction = _G.FluxAuctionRestock return auction and auction.IsUpgradeBlacklisted(id) or false end` [source](../../AddonOptions/FluxOptionsVendor.lua#L721) |
| set | `function(_, id, excluded) local auction = _G.FluxAuctionRestock if auction then auction.SetUpgradeBlacklisted(id, excluded) end end` [source](../../AddonOptions/FluxOptionsVendor.lua#L725) |

### restockPanel · restockPanel · L730

Source: [AddonOptions/FluxOptionsVendor.lua:730](../../AddonOptions/FluxOptionsVendor.lua#L730). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| dialogControl | `"FluxRestockPanel"` [source](../../AddonOptions/FluxOptionsVendor.lua#L732) |

### clearRestock · Clear all restock targets · L737

Source: [AddonOptions/FluxOptionsVendor.lua:737](../../AddonOptions/FluxOptionsVendor.lua#L737). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local FV = _G.FluxVendorAuto if FV and FV.EnsureSettings then local s = FV.EnsureSettings() if s then s.restockItems = {} end end NotifyVendorSettingsChanged() end` [source](../../AddonOptions/FluxOptionsVendor.lua#L744) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsVendor.lua#L742) |
| confirmText | `"Set every restock target to zero?"` [source](../../AddonOptions/FluxOptionsVendor.lua#L743) |

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
