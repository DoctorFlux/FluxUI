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

### &lt;anonymous&gt; · Bar · L25

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:25](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L25). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### scopeHeader · Scope · L30

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:30](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L30). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### settingsScope · Action bar scope · L35

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:35](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L35). Type: `"select"`.

Same settings for all chars, or just this one.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L41) |
| get | `function() if FluxOptions and FluxOptions.IsActionbarsCharacterSpecific and FluxOptions:IsActionbarsCharacterSpecific() then return "character" end return "account" end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L46) |
| set | `function(_, val) if FluxOptions and FluxOptions.SetActionbarsCharacterSpecific then FluxOptions:SetActionbarsCharacterSpecific(val == "character") end AB.Notify() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L53) |

### layoutHeader · Layout · L61

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:61](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L61). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### minirowPosition · Minirow position · L66

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:66](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L66). Type: `"select"`.

Shift/ctrl rows above or below the main bar.

| Contract | Source expression / implementation |
|---|---|
| values | `{ top = "Top (default)", bottom = "Bottom", }` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L72) |
| get | `function() local t = AB.ActionbarsDB() if t then return t.minirowPosition or "top" end return "top" end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L77) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.minirowPosition = val end if Flux and Flux.Bars and Flux.Bars.RequestLayout then Flux.Bars.RequestLayout("minirow") end end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L84) |

### vfxHeader · Action Bar VFX · L95

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:95](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L95). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.IsPreDF() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L99) |

### vfxDesc · Cast and target effects on buttons. Older clients only. · L103

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:103](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L103). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.IsPreDF() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L108) |

### spellCastVFX · Enable action bar VFX · L112

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:112](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L112). Type: `"toggle"`.

Show cast and target effects on action buttons.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local t = AB.ActionbarsDB() if t and t.spellCastVFX == false then return false end return true end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L121) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.spellCastVFX = val and true or false end if Flux and Flux.ButtonFX and Flux.ButtonFX.Cast and Flux.ButtonFX.Cast.RefreshFromOptions then Flux.ButtonFX.Cast.RefreshFromOptions() end end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L128) |
| hidden | `function() return not AB.IsPreDF() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L118) |

### mouseoverCastHeader · Mouseover casting · L139

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:139](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L139). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### mouseoverCastDesc · Matches the spell book setting. · L144

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:144](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L144). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### mouseoverCast · Mouseover cast · L150

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:150](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L150). Type: `"toggle"`.

Cast on the unit under your cursor. On Forever this drives Blizzard's enableMouseoverCast CVar. On other clients, plain action slots use click-time targeting and Flux keybind macros get an [@mouseover] clause baked into their macro text.  A keybind that already picks its own target (Targets tab in the binding editor) keeps that target and ignores this.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local MC = AB.MouseoverCast() if MC and MC.IsEnabled then return MC.IsEnabled() end local t = AB.ActionbarsDB() return not t or t.mouseoverCast ~= false end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L156) |
| set | `function(_, val) local MC = AB.MouseoverCast() if MC and MC.SetEnabled then MC.SetEnabled(val and true or false) return end local t = AB.ActionbarsDB() if t then t.mouseoverCast = val and true or false end if MC and MC.Apply then MC.Apply() end end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L164) |

### mouseoverCastNative · Flux mouseover-cast uses click-time targeting. Blizzard's enableMouseoverCast CVar stays off so world namepla… · L179

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:179](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L179). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not NativeMouseoverCast() or UsesNativeCVar() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L185) |

### mouseoverCastNativeForever · This client uses Blizzard mouseover-cast. The Action Bars toggle drives enableMouseoverCast. · L189

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:189](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L189). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not UsesNativeCVar() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L195) |

### mouseoverCastCombat · \|cffffcc00Changing this in combat applies when you leave combat.\|r · L199

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:199](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L199). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not (InCombatLockdown and InCombatLockdown()) end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L205) |

### spellbookHeader · Auto Rank up · L210

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:210](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L210). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L214) |

### spellbookDesc · Forever, Classic Era, and Anniversary. Not on live Midnight. · L218

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:218](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L218). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L223) |

### autoRankUp · Auto rank up · L227

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:227](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L227). Type: `"toggle"`.

Upgrade spells when you learn a higher rank.

| Contract | Source expression / implementation |
|---|---|
| get | `function() if FluxSpellRankManagerModule and FluxSpellRankManagerModule.GetAutoRankUpEnabled then return FluxSpellRankManagerModule:GetAutoRankUpEnabled() end return false end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L236) |
| set | `function(_, val) if FluxSpellRankManagerModule and FluxSpellRankManagerModule.SetAutoRankUpEnabled then FluxSpellRankManagerModule:SetAutoRankUpEnabled(val) end end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L242) |
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L233) |

### rankUpAllSpells · Rank up all spells · L248

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:248](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L248). Type: `"execute"`.

Replace lower ranks with your highest rank now.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxSpellRankManagerModule and FluxSpellRankManagerModule.RankUpAllSpells then FluxSpellRankManagerModule:RankUpAllSpells() end end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L260) |
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L254) |
| disabled | `function() return InCombatLockdown() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L257) |

### blacklistHelp · Blacklisted spells: · L266

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:266](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L266). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L271) |

### blacklistPanel · blacklistPanel · L275

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:275](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L275). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not AB.RankSupported() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L280) |
| dialogControl | `"FluxSpellBlacklistPanel"` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L283) |

### perfHeader · Performance · L286

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:286](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L286). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### perfDesc · Lower = faster updates, more CPU. · L291

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:291](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L291). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### rangeCheckInterval · Range check interval · L297

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:297](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L297). Type: `"range"`.

How often action bar buttons check range.

| Contract | Source expression / implementation |
|---|---|
| min | `0.1` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L302) |
| max | `1.0` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L303) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L304) |
| get | `function() local t = AB.ActionbarsDB() if t and t.rangeCheckInterval then return t.rangeCheckInterval end return 0.25 end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L305) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.rangeCheckInterval = val end ApplyPerformance() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L312) |

### extraButtonRangeCheckInterval · Extra button range interval · L320

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:320](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L320). Type: `"range"`.

How often extra grid buttons check range.

| Contract | Source expression / implementation |
|---|---|
| min | `0.1` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L325) |
| max | `1.0` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L326) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L327) |
| get | `function() local t = AB.ActionbarsDB() if t and t.extraButtonRangeCheckInterval then return t.extraButtonRangeCheckInterval end return 0.18 end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L328) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.extraButtonRangeCheckInterval = val end ApplyPerformance() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L335) |

### mouseoverUpdateInterval · Mouseover update interval · L343

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:343](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L343). Type: `"range"`.

How often mouseover macros refresh their tint.

| Contract | Source expression / implementation |
|---|---|
| min | `0.04` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L348) |
| max | `0.2` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L349) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L350) |
| get | `function() local t = AB.ActionbarsDB() if t and t.mouseoverUpdateInterval then return t.mouseoverUpdateInterval end return 0.07 end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L351) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.mouseoverUpdateInterval = val end ApplyPerformance() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L358) |

### macroUsableMinInterval · Macro usable interval · L366

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:366](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L366). Type: `"range"`.

Delay between macro usability updates. 0 = off.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L371) |
| max | `0.5` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L372) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L373) |
| get | `function() local t = AB.ActionbarsDB() if t and t.macroUsableMinInterval ~= nil then return t.macroUsableMinInterval end return 0.05 end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L374) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.macroUsableMinInterval = val end ApplyPerformance() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L381) |

### actionUsableMinInterval · Action usable interval · L389

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:389](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L389). Type: `"range"`.

Delay between button usability updates. 0 = off.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L394) |
| max | `0.5` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L395) |
| step | `0.01` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L396) |
| get | `function() local t = AB.ActionbarsDB() if t and t.actionUsableMinInterval ~= nil then return t.actionUsableMinInterval end return 0 end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L397) |
| set | `function(_, val) local t = AB.ActionbarsDB() if t then t.actionUsableMinInterval = val end ApplyPerformance() end` [source](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L404) |

### macroSmartLayoutPerfDesc · Macro buttons won't move minirows unless needed. · L412

Source: [AddonOptions/FluxOptionsActionBars_Bar.lua:412](../../AddonOptions/FluxOptionsActionBars_Bar.lua#L412). Type: `"description"`.

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

### &lt;anonymous&gt; · MicroMenu · L85

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

### &lt;anonymous&gt; · Party / Raid · L48

Source: [AddonOptions/FluxOptionsRaidFrame.lua:48](../../AddonOptions/FluxOptionsRaidFrame.lua#L48). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### masterHeader · Names · L53

Source: [AddonOptions/FluxOptionsRaidFrame.lua:53](../../AddonOptions/FluxOptionsRaidFrame.lua#L53). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### nameUseClassColor · Class-colored names · L58

Source: [AddonOptions/FluxOptionsRaidFrame.lua:58](../../AddonOptions/FluxOptionsRaidFrame.lua#L58). Type: `"toggle"`.

Color player names by class on Flux compact frames. Off keeps names white. Health bar class colors use Class colors below.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().nameUseClassColor == true end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L63) |
| set | `function(_, val) GetRaidDB().nameUseClassColor = val and true or false AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L66) |

### previewGroup · World Preview · L74

Source: [AddonOptions/FluxOptionsRaidFrame.lua:74](../../AddonOptions/FluxOptionsRaidFrame.lua#L74). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### desc · Shows a full-size preview of Flux raid frames in the game world. In a party or raid the first slots mirror re… · L80

Source: [AddonOptions/FluxOptionsRaidFrame.lua:80](../../AddonOptions/FluxOptionsRaidFrame.lua#L80). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### toggle · Show / Hide Preview · L86

Source: [AddonOptions/FluxOptionsRaidFrame.lua:86](../../AddonOptions/FluxOptionsRaidFrame.lua#L86). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxRaidPreview and FluxRaidPreview.Toggle then FluxRaidPreview.Toggle() end end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L91) |

### rosterSize · Roster size · L97

Source: [AddonOptions/FluxOptionsRaidFrame.lua:97](../../AddonOptions/FluxOptionsRaidFrame.lua#L97). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `{ ["5"] = "5", ["10"] = "10", ["15"] = "15", ["20"] = "20", ["25"] = "25", ["30"] = "30", ["35"] = "35", ["40"] = "40", }` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L102) |
| get | `function() local n = tonumber(GetRaidDB().previewRosterSize) or 40 return tostring(max(5, min(40, floor(n / 5) * 5))) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L107) |
| set | `function(_, val) GetRaidDB().previewRosterSize = tonumber(val) or 40 AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L111) |

### showMT · Show MT column · L116

Source: [AddonOptions/FluxOptionsRaidFrame.lua:116](../../AddonOptions/FluxOptionsRaidFrame.lua#L116). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().previewShowMTColumn ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L121) |
| set | `function(_, val) GetRaidDB().previewShowMTColumn = val and true or false AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L124) |

### mtCount · MT slots · L129

Source: [AddonOptions/FluxOptionsRaidFrame.lua:129](../../AddonOptions/FluxOptionsRaidFrame.lua#L129). Type: `"range"`.

How many MT/MA-style frames appear in the MT column.

| Contract | Source expression / implementation |
|---|---|
| min | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L134) |
| max | `8` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L134) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L134) |
| get | `function() local n = tonumber(GetRaidDB().previewMainTankCount) if not n or n &lt; 1 then n = 2 end return max(1, min(8, floor(n))) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L136) |
| set | `function(_, val) GetRaidDB().previewMainTankCount = max(1, min(8, floor(val))) AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L141) |

### auraSpacer · Demo Auras · L146

Source: [AddonOptions/FluxOptionsRaidFrame.lua:146](../../AddonOptions/FluxOptionsRaidFrame.lua#L146). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### showBuffs · Buffs · L151

Source: [AddonOptions/FluxOptionsRaidFrame.lua:151](../../AddonOptions/FluxOptionsRaidFrame.lua#L151). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().previewDemoBuffsEnabled ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L156) |
| set | `function(_, val) GetRaidDB().previewDemoBuffsEnabled = val and true or false AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L159) |

### buffCount · Buff count · L164

Source: [AddonOptions/FluxOptionsRaidFrame.lua:164](../../AddonOptions/FluxOptionsRaidFrame.lua#L164). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L168) |
| max | `6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L168) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L168) |
| get | `function() return tonumber(GetRaidDB().previewBuffCount) or 3 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L170) |
| set | `function(_, val) GetRaidDB().previewBuffCount = val AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L173) |

### showDebuffs · Debuffs · L178

Source: [AddonOptions/FluxOptionsRaidFrame.lua:178](../../AddonOptions/FluxOptionsRaidFrame.lua#L178). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().previewDemoDebuffsEnabled ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L183) |
| set | `function(_, val) GetRaidDB().previewDemoDebuffsEnabled = val and true or false AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L186) |

### debuffCount · Debuff count · L191

Source: [AddonOptions/FluxOptionsRaidFrame.lua:191](../../AddonOptions/FluxOptionsRaidFrame.lua#L191). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L195) |
| max | `6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L195) |
| step | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L195) |
| get | `function() return tonumber(GetRaidDB().previewDebuffCount) or 5 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L197) |
| set | `function(_, val) GetRaidDB().previewDebuffCount = val AfterPreviewChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L200) |

### sizingHeader · Frame sizing (Flux) · L211

Source: [AddonOptions/FluxOptionsRaidFrame.lua:211](../../AddonOptions/FluxOptionsRaidFrame.lua#L211). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### memberWidthScale · Member frame width scale · L216

Source: [AddonOptions/FluxOptionsRaidFrame.lua:216](../../AddonOptions/FluxOptionsRaidFrame.lua#L216). Type: `"range"`.

1 = default width (~72px).

| Contract | Source expression / implementation |
|---|---|
| min | `0.6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L221) |
| max | `1.4` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L221) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L221) |
| get | `function() return GetRaidDB().memberWidthScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L223) |
| set | `function(_, val) GetRaidDB().memberWidthScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L226) |

### frameHeightScale · Member frame height scale · L231

Source: [AddonOptions/FluxOptionsRaidFrame.lua:231](../../AddonOptions/FluxOptionsRaidFrame.lua#L231). Type: `"range"`.

1.2 matches the built-in default row height.

| Contract | Source expression / implementation |
|---|---|
| min | `0.8` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L236) |
| max | `1.6` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L236) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L236) |
| get | `function() return GetRaidDB().frameHeightScale or 1.2 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L238) |
| set | `function(_, val) GetRaidDB().frameHeightScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L241) |

### powerBarHeightScale · Power bar height scale · L246

Source: [AddonOptions/FluxOptionsRaidFrame.lua:246](../../AddonOptions/FluxOptionsRaidFrame.lua#L246). Type: `"range"`.

Scales only the resource strip at the bottom (independent of member frame height). 1 = default strip size.

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L251) |
| max | `2.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L251) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L251) |
| get | `function() return GetRaidDB().powerBarHeightScale or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L253) |
| set | `function(_, val) GetRaidDB().powerBarHeightScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L256) |

### auraIconScale · Aura icon scale · L261

Source: [AddonOptions/FluxOptionsRaidFrame.lua:261](../../AddonOptions/FluxOptionsRaidFrame.lua#L261). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L265) |
| max | `2.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L265) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L265) |
| get | `function() return GetRaidDB().auraIconScale or 1.4 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L267) |
| set | `function(_, val) GetRaidDB().auraIconScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L270) |

### raidManagerScale · Raid manager strip scale · L275

Source: [AddonOptions/FluxOptionsRaidFrame.lua:275](../../AddonOptions/FluxOptionsRaidFrame.lua#L275). Type: `"range"`.

Left raid tools / markers strip (when present).

| Contract | Source expression / implementation |
|---|---|
| min | `0.5` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L280) |
| max | `1.2` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L280) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L280) |
| get | `function() return GetRaidDB().raidManagerScale or 0.9 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L282) |
| set | `function(_, val) GetRaidDB().raidManagerScale = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L285) |

### transparencyHeader · Transparency (Flux) · L294

Source: [AddonOptions/FluxOptionsRaidFrame.lua:294](../../AddonOptions/FluxOptionsRaidFrame.lua#L294). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### transparencyDesc · Frame opacity applies to each unit button. In-range and out-of-range multipliers apply when Fade out of range… · L299

Source: [AddonOptions/FluxOptionsRaidFrame.lua:299](../../AddonOptions/FluxOptionsRaidFrame.lua#L299). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### frameBaseAlpha · Frame base opacity · L305

Source: [AddonOptions/FluxOptionsRaidFrame.lua:305](../../AddonOptions/FluxOptionsRaidFrame.lua#L305). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0.2` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L309) |
| max | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L309) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L309) |
| get | `function() return tonumber(GetRaidDB().frameBaseAlpha) or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L311) |
| set | `function(_, val) GetRaidDB().frameBaseAlpha = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L314) |

### rangeAlphaInRange · Opacity when in range · L319

Source: [AddonOptions/FluxOptionsRaidFrame.lua:319](../../AddonOptions/FluxOptionsRaidFrame.lua#L319). Type: `"range"`.

Used when Fade out of range is on. Multiplied by frame base opacity.

| Contract | Source expression / implementation |
|---|---|
| min | `0.2` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L324) |
| max | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L324) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L324) |
| get | `function() return tonumber(GetRaidDB().rangeAlphaInRange) or 0.9 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L326) |
| set | `function(_, val) GetRaidDB().rangeAlphaInRange = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L329) |

### rangeAlphaOutOfRange · Opacity when out of range / offline · L334

Source: [AddonOptions/FluxOptionsRaidFrame.lua:334](../../AddonOptions/FluxOptionsRaidFrame.lua#L334). Type: `"range"`.

Used when Fade out of range is on. Multiplied by frame base opacity.

| Contract | Source expression / implementation |
|---|---|
| min | `0.1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L339) |
| max | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L339) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L339) |
| get | `function() return tonumber(GetRaidDB().rangeAlphaOutOfRange) or 0.44 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L341) |
| set | `function(_, val) GetRaidDB().rangeAlphaOutOfRange = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L344) |

### auraIconAlpha · Buff / debuff icon opacity · L349

Source: [AddonOptions/FluxOptionsRaidFrame.lua:349](../../AddonOptions/FluxOptionsRaidFrame.lua#L349). Type: `"range"`.

Multiplies aura button alpha (stacks with frame opacity).

| Contract | Source expression / implementation |
|---|---|
| min | `0.2` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L354) |
| max | `1` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L354) |
| step | `0.05` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L354) |
| get | `function() return tonumber(GetRaidDB().auraIconAlpha) or 1 end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L356) |
| set | `function(_, val) GetRaidDB().auraIconAlpha = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L359) |

### dispelHeader · Dispel Highlight · L368

Source: [AddonOptions/FluxOptionsRaidFrame.lua:368](../../AddonOptions/FluxOptionsRaidFrame.lua#L368). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### showDispelHighlight · Dispel highlight border · L373

Source: [AddonOptions/FluxOptionsRaidFrame.lua:373](../../AddonOptions/FluxOptionsRaidFrame.lua#L373). Type: `"toggle"`.

Shows a type-colored border when a party/raid member has a debuff your class can dispel (e.g. Curse only if you have Remove Curse). Matches Blizzard Dispellable By Me.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetRaidDB().showDispelHighlight ~= false end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L379) |
| set | `function(_, val) GetRaidDB().showDispelHighlight = val and true or false AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L382) |

### highlightHeader · Highlights · L388

Source: [AddonOptions/FluxOptionsRaidFrame.lua:388](../../AddonOptions/FluxOptionsRaidFrame.lua#L388). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### showAggroHighlight · Aggro highlight · L393

Source: [AddonOptions/FluxOptionsRaidFrame.lua:393](../../AddonOptions/FluxOptionsRaidFrame.lua#L393). Type: `"toggle"`.

Shows the aggro ring when a member has threat.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showAggroHighlight", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L398) |
| set | `function(_, val) SetRaidFlag("showAggroHighlight", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L399) |

### showTargetHighlight · Target highlight · L401

Source: [AddonOptions/FluxOptionsRaidFrame.lua:401](../../AddonOptions/FluxOptionsRaidFrame.lua#L401). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showTargetHighlight", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L405) |
| set | `function(_, val) SetRaidFlag("showTargetHighlight", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L406) |

### showMouseoverHighlight · Mouseover highlight · L408

Source: [AddonOptions/FluxOptionsRaidFrame.lua:408](../../AddonOptions/FluxOptionsRaidFrame.lua#L408). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showMouseoverHighlight", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L412) |
| set | `function(_, val) SetRaidFlag("showMouseoverHighlight", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L413) |

### showRoleIcon · Role icons · L415

Source: [AddonOptions/FluxOptionsRaidFrame.lua:415](../../AddonOptions/FluxOptionsRaidFrame.lua#L415). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showRoleIcon", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L419) |
| set | `function(_, val) SetRaidFlag("showRoleIcon", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L420) |

### showGroupLabels · Group labels · L422

Source: [AddonOptions/FluxOptionsRaidFrame.lua:422](../../AddonOptions/FluxOptionsRaidFrame.lua#L422). Type: `"toggle"`.

Party and group numbers above each column.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showGroupLabels", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L427) |
| set | `function(_, val) SetRaidFlag("showGroupLabels", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L428) |

### showRangeFade · Fade out of range · L430

Source: [AddonOptions/FluxOptionsRaidFrame.lua:430](../../AddonOptions/FluxOptionsRaidFrame.lua#L430). Type: `"toggle"`.

Uses the in-range and out-of-range opacity sliders.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showRangeFade", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L435) |
| set | `function(_, val) SetRaidFlag("showRangeFade", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L436) |

### displayHeader · Bars and auras · L439

Source: [AddonOptions/FluxOptionsRaidFrame.lua:439](../../AddonOptions/FluxOptionsRaidFrame.lua#L439). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### useClassColors · Class colors · L444

Source: [AddonOptions/FluxOptionsRaidFrame.lua:444](../../AddonOptions/FluxOptionsRaidFrame.lua#L444). Type: `"toggle"`.

Class-colored health bars. Names stay on the setting above.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("useClassColors", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L449) |
| set | `function(_, val) SetRaidFlag("useClassColors", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L450) |

### displayPowerBar · Power bars · L452

Source: [AddonOptions/FluxOptionsRaidFrame.lua:452](../../AddonOptions/FluxOptionsRaidFrame.lua#L452). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayPowerBar", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L456) |
| set | `function(_, val) SetRaidFlag("displayPowerBar", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L457) |

### showHealPrediction · Heal prediction · L459

Source: [AddonOptions/FluxOptionsRaidFrame.lua:459](../../AddonOptions/FluxOptionsRaidFrame.lua#L459). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("showHealPrediction", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L463) |
| set | `function(_, val) SetRaidFlag("showHealPrediction", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L464) |

### healthText · Health text · L466

Source: [AddonOptions/FluxOptionsRaidFrame.lua:466](../../AddonOptions/FluxOptionsRaidFrame.lua#L466). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `healthTextValues` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L470) |
| get | `function() local v = GetRaidDB().healthText if v ~= "none" and v ~= "health" and v ~= "perc" and v ~= "healthandpercent" then return "perc" end return v end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L472) |
| set | `function(_, val) if val ~= "none" and val ~= "health" and val ~= "perc" and val ~= "healthandpercent" then val = "perc" end GetRaidDB().healthText = val AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L479) |

### displayBuffs · Show buffs · L487

Source: [AddonOptions/FluxOptionsRaidFrame.lua:487](../../AddonOptions/FluxOptionsRaidFrame.lua#L487). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayBuffs", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L491) |
| set | `function(_, val) SetRaidFlag("displayBuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L492) |

### displayDebuffs · Show debuffs · L494

Source: [AddonOptions/FluxOptionsRaidFrame.lua:494](../../AddonOptions/FluxOptionsRaidFrame.lua#L494). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayDebuffs", true) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L498) |
| set | `function(_, val) SetRaidFlag("displayDebuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L499) |

### auraFocusMode · Aura focus · L501

Source: [AddonOptions/FluxOptionsRaidFrame.lua:501](../../AddonOptions/FluxOptionsRaidFrame.lua#L501). Type: `"select"`.

Debuff focused: more debuff slots. Buff focused: more buff slots along the top.

| Contract | Source expression / implementation |
|---|---|
| values | `{ debuff = "Debuff focused", buff = "Buff focused", }` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L506) |
| get | `function() local v = GetRaidDB().auraFocusMode if v == "buff" then return "buff" end return "debuff" end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L510) |
| set | `function(_, val) GetRaidDB().auraFocusMode = (val == "buff") and "buff" or "debuff" AfterRaidChange() end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L515) |

### displayOnlyDispellableDebuffs · Only dispellable debuffs · L520

Source: [AddonOptions/FluxOptionsRaidFrame.lua:520](../../AddonOptions/FluxOptionsRaidFrame.lua#L520). Type: `"toggle"`.

Limits debuff icons to auras your class can dispel.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return RaidFlag("displayOnlyDispellableDebuffs", false) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L525) |
| set | `function(_, val) SetRaidFlag("displayOnlyDispellableDebuffs", val) end` [source](../../AddonOptions/FluxOptionsRaidFrame.lua#L526) |

## FluxOptionsRender.lua

[AddonOptions/FluxOptionsRender.lua](../../AddonOptions/FluxOptionsRender.lua)

### headerOpt · title · L679

Source: [AddonOptions/FluxOptionsRender.lua:679](../../AddonOptions/FluxOptionsRender.lua#L679). Type: `"header"`.

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

### raidSettingsScope · Party / raid settings scope · L399

Source: [AddonOptions/FluxOptionsUnitFrames.lua:399](../../AddonOptions/FluxOptionsUnitFrames.lua#L399). Type: `"select"`.

Account-wide stores party and raid options in the active profile. Character-specific keeps them on this character only.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L405) |
| get | `function() return FluxOptions:IsRaidFramesCharacterSpecific() and "character" or "account" end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L410) |
| set | `function(_, val) FluxOptions:SetRaidFrameCharacterSpecific(val == "character") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L413) |

### useFluxRaidFrames · Party / raid · L418

Source: [AddonOptions/FluxOptionsUnitFrames.lua:418](../../AddonOptions/FluxOptionsUnitFrames.lua#L418). Type: `"toggle"`.

Use Flux compact party and raid frames. When off, Blizzard party and raid frames are restored.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {} return db.useFluxRaidFrames ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L423) |
| set | `function(_, v) local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() if db then db.useFluxRaidFrames = v and true or false end if FluxOptions and FluxOptions.RefreshRaidFrameScopedModules then FluxOptions:RefreshRaid…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L427) |

### resetRaidFrames · Reset party / raid options · L438

Source: [AddonOptions/FluxOptionsUnitFrames.lua:438](../../AddonOptions/FluxOptionsUnitFrames.lua#L438). Type: `"execute"`.

Restores Party / Raid tab settings for the current party / raid scope.

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxOptions and FluxOptions.ResetRaidFramesToDefaults then FluxOptions:ResetRaidFramesToDefaults() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L444) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L443) |

### playerExtrasHeader · Player extras · L461

Source: [AddonOptions/FluxOptionsUnitFrames.lua:461](../../AddonOptions/FluxOptionsUnitFrames.lua#L461). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusTargetHeader · Focus target · L569

Source: [AddonOptions/FluxOptionsUnitFrames.lua:569](../../AddonOptions/FluxOptionsUnitFrames.lua#L569). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusTargetDesc · The focus target bar matches the focus frame size. · L574

Source: [AddonOptions/FluxOptionsUnitFrames.lua:574](../../AddonOptions/FluxOptionsUnitFrames.lua#L574). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### description · School and spell visual themes for Flux cast bars. Hybrid spells combine every school’s colors and effects. I… · L639

Source: [AddonOptions/FluxOptionsUnitFrames.lua:639](../../AddonOptions/FluxOptionsUnitFrames.lua#L639). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### [key] · label · L645

Source: [AddonOptions/FluxOptionsUnitFrames.lua:645](../../AddonOptions/FluxOptionsUnitFrames.lua#L645). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return get(key) ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L647) |
| set | `function(_, value) set(key, value and true or false) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L648) |
| disabled | `function() return (key ~= "enabled" and get("enabled") == false) or (key == "gradient" and get("colors") == false) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L649) |

### bars · Cast bars · L656

Source: [AddonOptions/FluxOptionsUnitFrames.lua:656](../../AddonOptions/FluxOptionsUnitFrames.lua#L656). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### detection · Spell appearance · L662

Source: [AddonOptions/FluxOptionsUnitFrames.lua:662](../../AddonOptions/FluxOptionsUnitFrames.lua#L662). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### effects · Shared appearance · L667

Source: [AddonOptions/FluxOptionsUnitFrames.lua:667](../../AddonOptions/FluxOptionsUnitFrames.lua#L667). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### [key] · label · L675

Source: [AddonOptions/FluxOptionsUnitFrames.lua:675](../../AddonOptions/FluxOptionsUnitFrames.lua#L675). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L676) |
| max | `maximum` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L676) |
| step | `5` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L676) |
| get | `function() return get(key) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L677) |
| set | `function(_, value) set(key, value) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L678) |
| disabled | `function() return get("enabled") == false or (requires and get(requires) == false) or (key == "glowOpacity" and get("halo") == false and get("edge") == false) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L679) |

### reset · Reset school themes · L688

Source: [AddonOptions/FluxOptionsUnitFrames.lua:688](../../AddonOptions/FluxOptionsUnitFrames.lua#L688). Type: `"execute"`.

| Contract | Source expression / implementation |
|---|---|
| func | `function() local db = GetDB() db.castBarThemes = {} for key, value in pairs(defaults) do db.castBarThemes[key] = value end if ns.CastBarThemes then ns.CastBarThemes.Refresh() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L690) |

### &lt;anonymous&gt; · Cast bar school themes · L697

Source: [AddonOptions/FluxOptionsUnitFrames.lua:697](../../AddonOptions/FluxOptionsUnitFrames.lua#L697). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### options · Unit frames · L701

Source: [AddonOptions/FluxOptionsUnitFrames.lua:701](../../AddonOptions/FluxOptionsUnitFrames.lua#L701). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### general · General · L710

Source: [AddonOptions/FluxOptionsUnitFrames.lua:710](../../AddonOptions/FluxOptionsUnitFrames.lua#L710). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### scopeHeader · Settings · L715

Source: [AddonOptions/FluxOptionsUnitFrames.lua:715](../../AddonOptions/FluxOptionsUnitFrames.lua#L715). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### settingsScope · Unit frame settings scope · L720

Source: [AddonOptions/FluxOptionsUnitFrames.lua:720](../../AddonOptions/FluxOptionsUnitFrames.lua#L720). Type: `"select"`.

Account-wide stores these options in the active profile (follows the Profiles tab). Character-specific keeps them on this character only, independent of General &gt; Settings scope.

| Contract | Source expression / implementation |
|---|---|
| values | `{ account = "Account-wide", character = "Character-specific", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L726) |
| get | `function() return FluxOptions:IsUnitFramesCharacterSpecific() and "character" or "account" end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L731) |
| set | `function(_, val) FluxOptions:SetUnitFrameCharacterSpecific(val == "character") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L734) |

### scopeDesc · This scope applies to every sub-tab below. Character-specific unit frame data is not duplicated when you copy… · L738

Source: [AddonOptions/FluxOptionsUnitFrames.lua:738](../../AddonOptions/FluxOptionsUnitFrames.lua#L738). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### fluxVsBlizHeader · Flux vs Blizzard · L745

Source: [AddonOptions/FluxOptionsUnitFrames.lua:745](../../AddonOptions/FluxOptionsUnitFrames.lua#L745). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### fluxVsBlizDesc · When Flux is off for a unit, the default Blizzard frame is used. Pet and target-of-target require the Flux pl… · L750

Source: [AddonOptions/FluxOptionsUnitFrames.lua:750](../../AddonOptions/FluxOptionsUnitFrames.lua#L750). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### useFluxPlayer · Player · L757

Source: [AddonOptions/FluxOptionsUnitFrames.lua:757](../../AddonOptions/FluxOptionsUnitFrames.lua#L757). Type: `"toggle"`.

Use Flux player frame. When off, Blizzard PlayerFrame is used; Flux pet requires Flux player.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxPlayer ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L763) |
| set | `function(_, v) GetDB().useFluxPlayer = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L764) |

### useFluxTarget · Target · L769

Source: [AddonOptions/FluxOptionsUnitFrames.lua:769](../../AddonOptions/FluxOptionsUnitFrames.lua#L769). Type: `"toggle"`.

Use Flux target frame. When off, Blizzard TargetFrame is used. Target-of-target (Flux) requires Flux target.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L775) |
| set | `function(_, v) GetDB().useFluxTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L776) |

### useFluxTargetOfTarget · Target of target · L781

Source: [AddonOptions/FluxOptionsUnitFrames.lua:781](../../AddonOptions/FluxOptionsUnitFrames.lua#L781). Type: `"toggle"`.

Requires Flux target. When off, Blizzard ToT is used if available.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxTargetOfTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L788) |
| set | `function(_, v) GetDB().useFluxTargetOfTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L789) |
| disabled | `function() return GetDB().useFluxTarget == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L787) |

### useFluxFocus · Focus · L794

Source: [AddonOptions/FluxOptionsUnitFrames.lua:794](../../AddonOptions/FluxOptionsUnitFrames.lua#L794). Type: `"toggle"`.

Use Flux focus frame. When off, Blizzard FocusFrame is used. Focus target bar requires Flux focus.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxFocus ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L801) |
| set | `function(_, v) GetDB().useFluxFocus = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L802) |
| hidden | `function() return not HasFocusUnit() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L800) |

### useFluxFocusTarget · Focus target · L807

Source: [AddonOptions/FluxOptionsUnitFrames.lua:807](../../AddonOptions/FluxOptionsUnitFrames.lua#L807). Type: `"toggle"`.

Requires Flux focus. When off, Blizzard focus ToT is used.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxFocusTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L815) |
| set | `function(_, v) GetDB().useFluxFocusTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L816) |
| hidden | `function() return not HasFocusUnit() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L813) |
| disabled | `function() return GetDB().useFluxFocus == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L814) |

### useFluxPet · Pet · L821

Source: [AddonOptions/FluxOptionsUnitFrames.lua:821](../../AddonOptions/FluxOptionsUnitFrames.lua#L821). Type: `"toggle"`.

Requires Flux player frame. When off, Blizzard PetFrame is used.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxPet ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L828) |
| set | `function(_, v) GetDB().useFluxPet = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L829) |
| disabled | `function() return GetDB().useFluxPlayer == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L827) |

### useFluxPetTarget · Pet target · L834

Source: [AddonOptions/FluxOptionsUnitFrames.lua:834](../../AddonOptions/FluxOptionsUnitFrames.lua#L834). Type: `"toggle"`.

Requires Flux pet (and Flux player). When off, pet target strip is not created.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().useFluxPetTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L844) |
| set | `function(_, v) GetDB().useFluxPetTarget = v and true or false AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L845) |
| disabled | `function() local d = GetDB() return d.useFluxPlayer == false or d.useFluxPet == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L840) |

### resetUnitFrames · Reset unit frame options to defaults · L851

Source: [AddonOptions/FluxOptionsUnitFrames.lua:851](../../AddonOptions/FluxOptionsUnitFrames.lua#L851). Type: `"execute"`.

Restores Flux vs Blizzard toggles and feature toggles to FluxUI defaults for the current scope (all unit frame tabs).

| Contract | Source expression / implementation |
|---|---|
| func | `function() if FluxOptions and FluxOptions.ResetUnitFramesToDefaults then FluxOptions:ResetUnitFramesToDefaults() end AfterPerUnitChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L858) |
| confirm | `true` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L857) |

### featuresHeader · Features · L866

Source: [AddonOptions/FluxOptionsUnitFrames.lua:866](../../AddonOptions/FluxOptionsUnitFrames.lua#L866). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### featuresDesc · These options apply immediately to Flux unit frames. · L871

Source: [AddonOptions/FluxOptionsUnitFrames.lua:871](../../AddonOptions/FluxOptionsUnitFrames.lua#L871). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### use3DPortraits · 3D portraits · L877

Source: [AddonOptions/FluxOptionsUnitFrames.lua:877](../../AddonOptions/FluxOptionsUnitFrames.lua#L877). Type: `"toggle"`.

When enabled, the portrait strip uses animated 3D models. When disabled, classic flat (2D) portraits are used for player, target, focus, and pet.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().use3DPortraits ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L883) |
| set | `function(_, v) GetDB().use3DPortraits = v and true or false if FluxUnitFrames_RefreshPortraitRenderModeFromDB then FluxUnitFrames_RefreshPortraitRenderModeFromDB() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L886) |

### enablePortraitCombatTint · Combat portrait tint · L893

Source: [AddonOptions/FluxOptionsUnitFrames.lua:893](../../AddonOptions/FluxOptionsUnitFrames.lua#L893). Type: `"toggle"`.

When this unit is in combat, its portrait border and the background behind the portrait turn red. Each frame uses its own unit, so a target or focus in combat stays red even if you are not.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enablePortraitCombatTint ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L899) |
| set | `function(_, v) GetDB().enablePortraitCombatTint = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L902) |

### enableHealthLossOverlay · Health loss overlay · L907

Source: [AddonOptions/FluxOptionsUnitFrames.lua:907](../../AddonOptions/FluxOptionsUnitFrames.lua#L907). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableHealthLossOverlay ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L912) |
| set | `function(_, v) GetDB().enableHealthLossOverlay = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L913) |

### enablePowerCostOverlay · Power cost overlay · L918

Source: [AddonOptions/FluxOptionsUnitFrames.lua:918](../../AddonOptions/FluxOptionsUnitFrames.lua#L918). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enablePowerCostOverlay ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L923) |
| set | `function(_, v) GetDB().enablePowerCostOverlay = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L924) |

### enableMP5Overlay · MP5 / mana tick overlay (player) · L929

Source: [AddonOptions/FluxOptionsUnitFrames.lua:929](../../AddonOptions/FluxOptionsUnitFrames.lua#L929). Type: `"toggle"`.

Show five-second-rule and mana-tick markers on Era, Anniversary/TBC, and Forever clients.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableMP5Overlay ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L935) |
| set | `function(_, v) GetDB().enableMP5Overlay = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L936) |

### swingTimerUnsupportedNote · Weapon swing timer is unavailable on live post-Dragonflight retail and on Cataclysm / Mists Classic. Classic … · L941

Source: [AddonOptions/FluxOptionsUnitFrames.lua:941](../../AddonOptions/FluxOptionsUnitFrames.lua#L941). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return IsSwingTimerClientSupported() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L947) |

### enableSwingTimer · Weapon swing timer (player) · L949

Source: [AddonOptions/FluxOptionsUnitFrames.lua:949](../../AddonOptions/FluxOptionsUnitFrames.lua#L949). Type: `"toggle"`.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableSwingTimer ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L955) |
| set | `function(_, v) GetDB().enableSwingTimer = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L956) |
| hidden | `function() return not IsSwingTimerClientSupported() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L954) |

### enableFlightPathTimers · Flight path timers · L961

Source: [AddonOptions/FluxOptionsUnitFrames.lua:961](../../AddonOptions/FluxOptionsUnitFrames.lua#L961). Type: `"toggle"`.

Show flight duration on taxi map tooltips and a progress bar on the player cast bar while flying. Uses bundled flight-time data with optional overrides after landing.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableFlightPathTimers ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L967) |
| set | `function(_, v) GetDB().enableFlightPathTimers = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L968) |

### enableFlightPathCastBar · Flight path cast bar (player) · L973

Source: [AddonOptions/FluxOptionsUnitFrames.lua:973](../../AddonOptions/FluxOptionsUnitFrames.lua#L973). Type: `"toggle"`.

Show in-flight progress on the player unit frame cast bar slot.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableFlightPathCastBar ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L980) |
| set | `function(_, v) GetDB().enableFlightPathCastBar = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L981) |
| disabled | `function() return GetDB().enableFlightPathTimers == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L979) |

### enableFlightPathTooltips · Flight path taxi map tooltips · L986

Source: [AddonOptions/FluxOptionsUnitFrames.lua:986](../../AddonOptions/FluxOptionsUnitFrames.lua#L986). Type: `"toggle"`.

Append estimated flight duration when hovering reachable destinations on the taxi map.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().enableFlightPathTooltips ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L993) |
| set | `function(_, v) GetDB().enableFlightPathTooltips = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L994) |
| disabled | `function() return GetDB().enableFlightPathTimers == false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L992) |

### threatBarVisibility · Threat bar visibility · L999

Source: [AddonOptions/FluxOptionsUnitFrames.lua:999](../../AddonOptions/FluxOptionsUnitFrames.lua#L999). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `THREAT_BAR_VISIBILITY_VALUES` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1005) |
| get | `function() return GetThreatBarVisibility() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1007) |
| set | `function(_, v) SetThreatBarVisibility(v) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1010) |

### showNumericThreat · Show threat percentage · L1014

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1014](../../AddonOptions/FluxOptionsUnitFrames.lua#L1014). Type: `"toggle"`.

Shows tank-relative threat % (100% = you have aggro) on the target/focus threat bar and on nameplates, plus your placement in the group.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local ThreatAPI = ns.Flux and ns.Flux.Threat if ThreatAPI and ThreatAPI.ShowNumeric then return ThreatAPI.ShowNumeric() end return true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1020) |
| set | `function(_, v) local ThreatAPI = ns.Flux and ns.Flux.Threat if ThreatAPI and ThreatAPI.SetShowNumeric then ThreatAPI.SetShowNumeric(v) end if FluxUnitFrames_ApplyThreatBarOptionsFromDB then FluxUnitFrames_ApplyThreatBarOptionsFromDB() end if FluxNam…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1027) |

### nameplateOptionsPointer · Nameplate Progressive, Flash, Health Bar Color, and Threat warning are on the Nameplates page. · L1040

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1040](../../AddonOptions/FluxOptionsUnitFrames.lua#L1040). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|

### unitPlayer · Player · L1051

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1051](../../AddonOptions/FluxOptionsUnitFrames.lua#L1051). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### playerShowPortrait · Show portrait strip · L1056

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1056](../../AddonOptions/FluxOptionsUnitFrames.lua#L1056). Type: `"toggle"`.

When off, only the bar column is shown and it stays centered at the bottom of the screen. When on, the side portrait strip is shown (3D vs flat is set under General -&gt; Features). Applies immediately. Third-party addons that replace the portrait (e.g. BigDebuffs) get a layout refresh when this changes.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitPlayer ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1062) |
| set | `function(_, v) GetDB().showPortraitPlayer = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1065) |

### playerTargetScale · Player + target scale (%) · L1070

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1070](../../AddonOptions/FluxOptionsUnitFrames.lua#L1070). Type: `"range"`.

Scales the complete player and target frames and their attached cast bars, auras, indicators and target-of-target frame.

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1073) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1073) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1073) |
| get | `function() return (FluxUnitFrames_GetWholeFrameScale and FluxUnitFrames_GetWholeFrameScale("player") or 1) * 100 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1074) |
| set | `function(_, value) GetDB().frameScalePlayerTarget = math.max(50, math.min(200, tonumber(value) or 100)) / 100 AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1077) |

### playerWidth · Width · L1082

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1082](../../AddonOptions/FluxOptionsUnitFrames.lua#L1082). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `150` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1087) |
| max | `600` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1088) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1089) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("player", "width") end fs.player = fs.player or {} local raw = fs.player.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("player", "widt…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1090) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.player = fs.player or {} fs.player.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1102) |

### playerHeight · Height · L1112

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1112](../../AddonOptions/FluxOptionsUnitFrames.lua#L1112). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1117) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1118) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1119) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("player", "height") end fs.player = fs.player or {} local raw = fs.player.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("player", "he…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1120) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.player = fs.player or {} fs.player.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1132) |

### playerHealthSplit · Health / resource split % · L1142

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1142](../../AddonOptions/FluxOptionsUnitFrames.lua#L1142). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown. Alternate power (third bar) still uses a fixed three-way split.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1148) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1149) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1150) |
| get | `function() return HealthPartitionGetFor("player") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1151) |
| set | `function(_, val) HealthPartitionSetFor("player", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1154) |

### unitTarget · Target · L1161

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1161](../../AddonOptions/FluxOptionsUnitFrames.lua#L1161). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### targetShowPortrait · Show portrait strip · L1166

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1166](../../AddonOptions/FluxOptionsUnitFrames.lua#L1166). Type: `"toggle"`.

When off, only the bar column is shown and it stays centered at the top of the screen. When on, the side portrait strip is shown (3D vs flat is under General -&gt; Features). Applies immediately; BigDebuffs and similar mods receive a refresh hook.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitTarget ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1172) |
| set | `function(_, v) GetDB().showPortraitTarget = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1175) |

### targetNoTargetPlaceholder · Empty target placeholder · L1180

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1180](../../AddonOptions/FluxOptionsUnitFrames.lua#L1180). Type: `"toggle"`.

When enabled, a subtle gray outline marks the target frame area while you have nothing targeted. Turn off to hide that box.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showTargetNoTargetPlaceholder ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1186) |
| set | `function(_, v) GetDB().showTargetNoTargetPlaceholder = v and true or false AfterTargetPlaceholderChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1189) |

### targetSizeFollowsPlayerNote · Layout is set to side-by-side (Layout tab): target width and height match the Player tab - adjust size there. · L1194

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1194](../../AddonOptions/FluxOptionsUnitFrames.lua#L1194). Type: `"description"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not IsSideBySidePlayerTargetLayout() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1200) |

### targetWidth · Width · L1204

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1204](../../AddonOptions/FluxOptionsUnitFrames.lua#L1204). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1209) |
| max | `800` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1210) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1211) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("target", "width") end fs.target = fs.target or {} local raw = fs.target.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("target", "widt…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1215) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.target = fs.target or {} fs.target.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1227) |
| hidden | `function() return IsSideBySidePlayerTargetLayout() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1212) |

### targetHeight · Height · L1237

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1237](../../AddonOptions/FluxOptionsUnitFrames.lua#L1237). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1242) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1243) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1244) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("target", "height") end fs.target = fs.target or {} local raw = fs.target.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("target", "he…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1248) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.target = fs.target or {} fs.target.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1260) |
| hidden | `function() return IsSideBySidePlayerTargetLayout() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1245) |

### targetHealthSplit · Health / resource split % · L1270

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1270](../../AddonOptions/FluxOptionsUnitFrames.lua#L1270). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1276) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1277) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1278) |
| get | `function() return HealthPartitionGetFor("target") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1279) |
| set | `function(_, val) HealthPartitionSetFor("target", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1282) |

### targetAurasHeader · Auras · L1286

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1286](../../AddonOptions/FluxOptionsUnitFrames.lua#L1286). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### targetAuraBuffSize · Buff icon size · L1291

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1291](../../AddonOptions/FluxOptionsUnitFrames.lua#L1291). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1296) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1297) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1298) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.buffSize or 35 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1299) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.buffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1304) |

### targetAuraDebuffSize · Debuff icon size · L1311

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1311](../../AddonOptions/FluxOptionsUnitFrames.lua#L1311). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1316) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1317) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1318) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.debuffSize or 35 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1319) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.debuffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1324) |

### targetAuraLockOwnDebuffSize · Lock own debuff size · L1331

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1331](../../AddonOptions/FluxOptionsUnitFrames.lua#L1331). Type: `"toggle"`.

Keep your player/pet/vehicle debuffs at full boosted size (~1.38x). Other players' debuffs can shrink to fit the panel (Classic) or stay at the configured size (Midnight/Forever). When off, yours can shrink down to Own debuff min scale.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1337) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.lockOwnDebuffSize = v and true or false AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1342) |

### targetAuraOwnDebuffMinScale · Own debuff min scale · L1349

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1349](../../AddonOptions/FluxOptionsUnitFrames.lua#L1349). Type: `"range"`.

When lock is off, the smallest your own debuffs can get (100% = full boosted size, 50% = half of boosted). They stay larger than other players' icons while the panel is shrinking. Disabled while lock is on. On Midnight/Forever this sets own icon size directly (those frames do not fit-shrink).

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1355) |
| max | `100` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1356) |
| step | `5` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1357) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} local s = tonumber(d.auraTarget.ownDebuffMinScale) or 0.75 return math.floor(s * 100 + 0.5) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1365) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.ownDebuffMinScale = (tonumber(v) or 75) / 100 AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1371) |
| disabled | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1360) |

### targetAuraBuffSpacing · Buff spacing · L1378

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1378](../../AddonOptions/FluxOptionsUnitFrames.lua#L1378). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1383) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1384) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1385) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.buffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1386) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.buffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1391) |

### targetAuraDebuffSpacing · Debuff spacing · L1398

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1398](../../AddonOptions/FluxOptionsUnitFrames.lua#L1398). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1403) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1404) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1405) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.debuffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1406) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.debuffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1411) |

### targetAuraMaxBuffs · Max buff icons · L1418

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1418](../../AddonOptions/FluxOptionsUnitFrames.lua#L1418). Type: `"range"`.

Increasing above the previous cap rebuilds the buff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `8` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1424) |
| max | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1425) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1426) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.maxBuffs or 32 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1427) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.maxBuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1432) |

### targetAuraMaxDebuffs · Max debuff icons · L1439

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1439](../../AddonOptions/FluxOptionsUnitFrames.lua#L1439). Type: `"range"`.

Increasing above the previous cap rebuilds the debuff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `4` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1445) |
| max | `24` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1446) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1447) |
| get | `function() local d = GetDB() d.auraTarget = d.auraTarget or {} return d.auraTarget.maxDebuffs or 16 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1448) |
| set | `function(_, v) local d = GetDB() d.auraTarget = d.auraTarget or {} d.auraTarget.maxDebuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1453) |

### targetThreatHeader · Threat · L1460

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1460](../../AddonOptions/FluxOptionsUnitFrames.lua#L1460). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### targetThreatBarVisibility · Threat bar visibility · L1465

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1465](../../AddonOptions/FluxOptionsUnitFrames.lua#L1465). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `THREAT_BAR_VISIBILITY_VALUES` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1471) |
| get | `function() return GetThreatBarVisibility() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1473) |
| set | `function(_, v) SetThreatBarVisibility(v) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1476) |

### targetThreatBarPosition · Threat bar position · L1480

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1480](../../AddonOptions/FluxOptionsUnitFrames.lua#L1480). Type: `"select"`.

Portrait overlays the portrait when you have threat. Between reserves a strip between the frame chrome and auras. Left/Right are vertical strips for enemy NPCs only. In side-by-side Layout, Left is coerced to Right so the strip stays on the outer edge.

| Contract | Source expression / implementation |
|---|---|
| values | `{ portrait = "Portrait overlay", between = "Between chrome and auras", left = "Left (vertical)", right = "Right (vertical)", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1486) |
| get | `function() local v = GetDB().threatBarPositionTarget if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then return "portrait" end return v end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1492) |
| set | `function(_, v) if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then v = "portrait" end GetDB().threatBarPositionTarget = v if FluxUnitFrames_ApplyThreatBarOptionsFromDB then FluxUnitFrames_ApplyThreatBarOptionsFromDB() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1499) |

### unitTargetOfTarget · Target of target · L1512

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1512](../../AddonOptions/FluxOptionsUnitFrames.lua#L1512). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### totWidth · Width · L1517

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1517](../../AddonOptions/FluxOptionsUnitFrames.lua#L1517). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `80` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1522) |
| max | `300` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1523) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1524) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("targettarget", "width") end fs.targettarget = fs.targettarget or {} local raw = fs.targettarget.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return De…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1525) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.targettarget = fs.targettarget or {} fs.targettarget.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1537) |

### totHeight · Height · L1547

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1547](../../AddonOptions/FluxOptionsUnitFrames.lua#L1547). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `30` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1552) |
| max | `120` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1553) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1554) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("targettarget", "height") end fs.targettarget = fs.targettarget or {} local raw = fs.targettarget.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return …` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1555) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.targettarget = fs.targettarget or {} fs.targettarget.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1567) |

### totHealthSplit · Health / resource split % · L1577

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1577](../../AddonOptions/FluxOptionsUnitFrames.lua#L1577). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1583) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1584) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1585) |
| get | `function() return HealthPartitionGetFor("targettarget") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1586) |
| set | `function(_, val) HealthPartitionSetFor("targettarget", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1589) |

### unitFocus · Focus · L1596

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1596](../../AddonOptions/FluxOptionsUnitFrames.lua#L1596). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|
| hidden | `function() return not HasFocusUnit() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1600) |

### focusShowPortrait · Show portrait strip · L1602

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1602](../../AddonOptions/FluxOptionsUnitFrames.lua#L1602). Type: `"toggle"`.

When off, only the bar column is shown (focus frame repositions from chat; focus target bar matches width). When on, the side portrait strip is shown (3D vs flat is under General -&gt; Features). Applies immediately.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitFocus ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1608) |
| set | `function(_, v) GetDB().showPortraitFocus = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1611) |

### focusFrameScale · Focus scale (%) · L1616

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1616](../../AddonOptions/FluxOptionsUnitFrames.lua#L1616). Type: `"range"`.

Scales the complete focus frame, attached cast bar, auras, indicators and focus-target frame.

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1619) |
| max | `200` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1619) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1619) |
| get | `function() return (FluxUnitFrames_GetWholeFrameScale and FluxUnitFrames_GetWholeFrameScale("focus") or 1) * 100 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1620) |
| set | `function(_, value) GetDB().frameScaleFocus = math.max(50, math.min(200, tonumber(value) or 100)) / 100 AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1623) |

### focusWidth · Width · L1628

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1628](../../AddonOptions/FluxOptionsUnitFrames.lua#L1628). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `80` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1633) |
| max | `250` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1634) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1635) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("focus", "width") end fs.focus = fs.focus or {} local raw = fs.focus.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("focus", "width") e…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1636) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.focus = fs.focus or {} fs.focus.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1648) |

### focusHeight · Height · L1658

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1658](../../AddonOptions/FluxOptionsUnitFrames.lua#L1658). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `30` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1663) |
| max | `120` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1664) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1665) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("focus", "height") end fs.focus = fs.focus or {} local raw = fs.focus.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("focus", "height"…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1666) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.focus = fs.focus or {} fs.focus.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1678) |

### focusHealthSplit · Health / resource split % · L1688

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1688](../../AddonOptions/FluxOptionsUnitFrames.lua#L1688). Type: `"range"`.

Share of the inner bar stack for health; also used for the focus target-of-target strip height.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1694) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1695) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1696) |
| get | `function() return HealthPartitionGetFor("focus") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1697) |
| set | `function(_, val) HealthPartitionSetFor("focus", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1700) |

### focusAurasHeader · Auras · L1704

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1704](../../AddonOptions/FluxOptionsUnitFrames.lua#L1704). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusAuraBuffSize · Buff icon size · L1709

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1709](../../AddonOptions/FluxOptionsUnitFrames.lua#L1709). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1714) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1715) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1716) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.buffSize or 20 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1717) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.buffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1722) |

### focusAuraDebuffSize · Debuff icon size · L1729

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1729](../../AddonOptions/FluxOptionsUnitFrames.lua#L1729). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `14` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1734) |
| max | `56` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1735) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1736) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.debuffSize or 20 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1737) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.debuffSize = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1742) |

### focusAuraLockOwnDebuffSize · Lock own debuff size · L1749

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1749](../../AddonOptions/FluxOptionsUnitFrames.lua#L1749). Type: `"toggle"`.

Keep your player/pet/vehicle debuffs at full boosted size (~1.38x). Other players' debuffs can shrink to fit the panel (Classic) or stay at the configured size (Midnight/Forever). When off, yours can shrink down to Own debuff min scale.

| Contract | Source expression / implementation |
|---|---|
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1755) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.lockOwnDebuffSize = v and true or false AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1760) |

### focusAuraOwnDebuffMinScale · Own debuff min scale · L1767

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1767](../../AddonOptions/FluxOptionsUnitFrames.lua#L1767). Type: `"range"`.

When lock is off, the smallest your own debuffs can get (100% = full boosted size, 50% = half of boosted). They stay larger than other players' icons while the panel is shrinking. Disabled while lock is on. On Midnight/Forever this sets own icon size directly (those frames do not fit-shrink).

| Contract | Source expression / implementation |
|---|---|
| min | `50` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1773) |
| max | `100` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1774) |
| step | `5` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1775) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} local s = tonumber(d.auraFocus.ownDebuffMinScale) or 0.75 return math.floor(s * 100 + 0.5) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1783) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.ownDebuffMinScale = (tonumber(v) or 75) / 100 AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1789) |
| disabled | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.lockOwnDebuffSize ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1778) |

### focusAuraBuffSpacing · Buff spacing · L1796

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1796](../../AddonOptions/FluxOptionsUnitFrames.lua#L1796). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1801) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1802) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1803) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.buffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1804) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.buffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1809) |

### focusAuraDebuffSpacing · Debuff spacing · L1816

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1816](../../AddonOptions/FluxOptionsUnitFrames.lua#L1816). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `0` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1821) |
| max | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1822) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1823) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.debuffSpacing or 2 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1824) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.debuffSpacing = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1829) |

### focusAuraMaxBuffs · Max buff icons · L1836

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1836](../../AddonOptions/FluxOptionsUnitFrames.lua#L1836). Type: `"range"`.

Increasing above the previous cap rebuilds the buff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `8` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1842) |
| max | `40` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1843) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1844) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.maxBuffs or 32 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1845) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.maxBuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1850) |

### focusAuraMaxDebuffs · Max debuff icons · L1857

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1857](../../AddonOptions/FluxOptionsUnitFrames.lua#L1857). Type: `"range"`.

Increasing above the previous cap rebuilds the debuff panel once.

| Contract | Source expression / implementation |
|---|---|
| min | `4` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1863) |
| max | `24` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1864) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1865) |
| get | `function() local d = GetDB() d.auraFocus = d.auraFocus or {} return d.auraFocus.maxDebuffs or 16 end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1866) |
| set | `function(_, v) local d = GetDB() d.auraFocus = d.auraFocus or {} d.auraFocus.maxDebuffs = v AfterAuraOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1871) |

### focusThreatHeader · Threat · L1878

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1878](../../AddonOptions/FluxOptionsUnitFrames.lua#L1878). Type: `"header"`.

| Contract | Source expression / implementation |
|---|---|

### focusThreatBarVisibility · Threat bar visibility · L1883

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1883](../../AddonOptions/FluxOptionsUnitFrames.lua#L1883). Type: `"select"`.

| Contract | Source expression / implementation |
|---|---|
| values | `THREAT_BAR_VISIBILITY_VALUES` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1889) |
| get | `function() return GetThreatBarVisibility() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1891) |
| set | `function(_, v) SetThreatBarVisibility(v) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1894) |

### focusThreatBarPosition · Threat bar position · L1898

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1898](../../AddonOptions/FluxOptionsUnitFrames.lua#L1898). Type: `"select"`.

Portrait overlays the portrait when you have threat. Between reserves a strip between the frame chrome and auras. Left/Right are vertical strips for enemy NPCs only.

| Contract | Source expression / implementation |
|---|---|
| values | `{ portrait = "Portrait overlay", between = "Between chrome and auras", left = "Left (vertical)", right = "Right (vertical)", }` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1904) |
| get | `function() local v = GetDB().threatBarPositionFocus if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then return "portrait" end return v end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1910) |
| set | `function(_, v) if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then v = "portrait" end GetDB().threatBarPositionFocus = v if FluxUnitFrames_ApplyThreatBarOptionsFromDB then FluxUnitFrames_ApplyThreatBarOptionsFromDB() end end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1917) |

### unitPet · Pet · L1930

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1930](../../AddonOptions/FluxOptionsUnitFrames.lua#L1930). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### petShowPortrait · Show portrait strip · L1935

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1935](../../AddonOptions/FluxOptionsUnitFrames.lua#L1935). Type: `"toggle"`.

When off, only the pet bar column is shown (no portrait strip). When on, the side portrait strip is shown (3D vs flat is under General -&gt; Features). Applies immediately; the pet frame re-anchors to the player frame.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPortraitPet ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1941) |
| set | `function(_, v) GetDB().showPortraitPet = v and true or false AfterPortraitOptionsChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1944) |

### petShowCastBar · Show cast bar · L1949

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1949](../../AddonOptions/FluxOptionsUnitFrames.lua#L1949). Type: `"toggle"`.

Overlay a cast/channel bar on the pet resource bar. Off by default.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showCastBarPet == true end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1955) |
| set | `function(_, v) GetDB().showCastBarPet = v and true or false AfterFeatureChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1958) |

### petShowTooltipAuras · Show auras on mouseover · L1963

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1963](../../AddonOptions/FluxOptionsUnitFrames.lua#L1963). Type: `"toggle"`.

When hovering the pet frame, show buff and debuff icons with cooldown countdown next to the unit tooltip.

| Contract | Source expression / implementation |
|---|---|
| get | `function() return GetDB().showPetTooltipAuras ~= false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1969) |
| set | `function(_, v) GetDB().showPetTooltipAuras = v and true or false end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1972) |

### petWidth · Width · L1976

Source: [AddonOptions/FluxOptionsUnitFrames.lua:1976](../../AddonOptions/FluxOptionsUnitFrames.lua#L1976). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `60` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1981) |
| max | `220` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1982) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1983) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("pet", "width") end fs.pet = fs.pet or {} local raw = fs.pet.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("pet", "width") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1984) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.pet = fs.pet or {} fs.pet.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L1996) |

### petHeight · Height · L2006

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2006](../../AddonOptions/FluxOptionsUnitFrames.lua#L2006). Type: `"range"`.

| Contract | Source expression / implementation |
|---|---|
| min | `30` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2011) |
| max | `120` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2012) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2013) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("pet", "height") end fs.pet = fs.pet or {} local raw = fs.pet.height if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("pet", "height") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2014) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.pet = fs.pet or {} fs.pet.height = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2026) |

### petHealthSplit · Health / resource split % · L2036

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2036](../../AddonOptions/FluxOptionsUnitFrames.lua#L2036). Type: `"range"`.

Share of the inner bar stack for health when only health + main resource are shown.

| Contract | Source expression / implementation |
|---|---|
| min | `35` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2042) |
| max | `85` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2043) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2044) |
| get | `function() return HealthPartitionGetFor("pet") end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2045) |
| set | `function(_, val) HealthPartitionSetFor("pet", val) end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2048) |

### unitPetTarget · Pet target · L2055

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2055](../../AddonOptions/FluxOptionsUnitFrames.lua#L2055). Type: `"group"`.

| Contract | Source expression / implementation |
|---|---|

### petTargetWidth · Width · L2060

Source: [AddonOptions/FluxOptionsUnitFrames.lua:2060](../../AddonOptions/FluxOptionsUnitFrames.lua#L2060). Type: `"range"`.

Vertical health strip next to the pet frame; height always matches the pet frame.

| Contract | Source expression / implementation |
|---|---|
| min | `12` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2066) |
| max | `48` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2067) |
| step | `1` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2068) |
| get | `function() local fs = FrameSizesBucket() if not fs then return DefaultDim("pettarget", "width") end fs.pettarget = fs.pettarget or {} local raw = fs.pettarget.width if raw ~= nil then return FrameSizeStorageToEffective(raw) end return DefaultDim("pe…` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2069) |
| set | `function(_, v) local fs = FrameSizesBucket() if not fs then return end fs.pettarget = fs.pettarget or {} fs.pettarget.width = FrameSizeEffectiveToStorage(v) AfterLayoutSizingChange() end` [source](../../AddonOptions/FluxOptionsUnitFrames.lua#L2081) |

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
| [AddonOptions/FluxOptionsUnitFrames.lua:500](../../AddonOptions/FluxOptionsUnitFrames.lua#L500) | `AddTextAndBars(player, "player", 30, { castBar = true, castTime = true, health = "both", power = true, heal = true, absorb = true, classPower = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:509](../../AddonOptions/FluxOptionsUnitFrames.lua#L509) | `AddIcons(player, "player", 36, { level = true, classIcon = true, pvp = true, combat = true, raidIcon = true, portraitCombat = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:519](../../AddonOptions/FluxOptionsUnitFrames.lua#L519) | `AddTextAndBars(target, "target", 20, { castBar = true, castTime = true, health = "both", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:527](../../AddonOptions/FluxOptionsUnitFrames.lua#L527) | `AddIcons(target, "target", 26, { level = true, classIcon = true, pvp = true, raidIcon = true, portraitCombat = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:535](../../AddonOptions/FluxOptionsUnitFrames.lua#L535) | `AuraToggle("auraTarget", "showBuffs", "Show buffs", 3.6)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:536](../../AddonOptions/FluxOptionsUnitFrames.lua#L536) | `AuraToggle("auraTarget", "showDebuffs", "Show debuffs", 3.7)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:538](../../AddonOptions/FluxOptionsUnitFrames.lua#L538) | `AddTextAndBars(tot.args, "targettarget", 10, { header = "Text and bars", health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:545](../../AddonOptions/FluxOptionsUnitFrames.lua#L545) | `AddIcons(tot.args, "targettarget", 16, { raidIcon = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:551](../../AddonOptions/FluxOptionsUnitFrames.lua#L551) | `AddTextAndBars(focus, "focus", 20, { castBar = true, castTime = true, health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:559](../../AddonOptions/FluxOptionsUnitFrames.lua#L559) | `AddIcons(focus, "focus", 26, { level = true, classIcon = true, pvp = true, raidIcon = true, portraitCombat = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:567](../../AddonOptions/FluxOptionsUnitFrames.lua#L567) | `AuraToggle("auraFocus", "showBuffs", "Show buffs", 3.6)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:568](../../AddonOptions/FluxOptionsUnitFrames.lua#L568) | `AuraToggle("auraFocus", "showDebuffs", "Show debuffs", 3.7)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:580](../../AddonOptions/FluxOptionsUnitFrames.lua#L580) | `AddTextAndBars(focus, "focustarget", 70.1, { header = "Focus target text", health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:587](../../AddonOptions/FluxOptionsUnitFrames.lua#L587) | `FlagToggle("focustarget", "mouseover", "Mouseover highlight", nil, 71)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:588](../../AddonOptions/FluxOptionsUnitFrames.lua#L588) | `FlagToggle("focustarget", "raidIcon", "Raid marker", nil, 71.1)` |
| [AddonOptions/FluxOptionsUnitFrames.lua:590](../../AddonOptions/FluxOptionsUnitFrames.lua#L590) | `AddTextAndBars(pet, "pet", 20, { castTime = true, health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:597](../../AddonOptions/FluxOptionsUnitFrames.lua#L597) | `AddIcons(pet, "pet", 26, { raidIcon = true, mouseover = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:602](../../AddonOptions/FluxOptionsUnitFrames.lua#L602) | `AddTextAndBars(petTarget.args, "pettarget", 10, { header = "Text and bars", health = "percent", power = true, heal = true, absorb = true, })` |
| [AddonOptions/FluxOptionsUnitFrames.lua:609](../../AddonOptions/FluxOptionsUnitFrames.lua#L609) | `FlagToggle("pettarget", "mouseover", "Mouseover highlight", nil, 16)` |

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
| [AddonOptions/AceGUIWidget-FluxRestockPanel.lua:2559](../../AddonOptions/AceGUIWidget-FluxRestockPanel.lua#L2559) | `Type, Constructor, Version` |
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
