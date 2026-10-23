# Game defaults, keyboard template and scale

[FluxDefaultSettings.lua](../FluxDefaultSettings.lua) owns game-setting setup, the keyboard template, reset detection and shared horizontal squeeze. These differ from AceDB option defaults and conditional Binding documents. See [09-persistence.md](09-persistence.md), [13-binding-system.md](13-binding-system.md) and [31-commands-and-bindings.md](31-commands-and-bindings.md).

## Automatic application

Full settings **and keybindings** apply automatically on first account login when `FluxUI_DB.accountDefaultsApplied` is false. Encountered characters are recorded in `FluxUI_DB.characters[charKey]`. A later new character receives `ApplyCharacterFirstLogin`: raid setup and chat class colors, without full keyboard-template application.

There is no opt-in installer prompt in this flow. `Apply(force)` skips an already-applied account unless forced. Full application calls setting packs, keybind application, modified-click setup, raid/profile setup and chat setup, then marks the account flag. Some work is protected/deferred; the flag does not prove that every individual write succeeded.

The event frame also tracks display/UI scale changes and compact raid profile readiness. Regen handling is armed for pending key/scale/squeeze work. A five-second login grace period suppresses reset detection; `VerifyPostLoginDefaults` runs afterward, retrying during combat.

## Keyboard template

`DefaultKeyTemplate` contains exact `SetBinding` commands. Representative assignments follow; its source table is authoritative, including locale-sensitive key tokens.

| Keys | Default command |
|---|---|
| `W/S/A/D`, Space | Forward/back/strafe and jump. |
| `1–5`, `½`, `Q/E/R/T/F/G` | Action buttons 1–12. |
| Mouse 5/4/3, `<`, `Z/X/C` | Seven extra columns using existing multiaction commands. |
| `F1–F4`, Shift-F1–F4 | Stance/shapeshift buttons 1–8. |
| `F5` | Flux reload; customized assignments are preserved by automatic verification. |
| `Y/7/6` | Smart mount/hearth/vendor mount. |
| `U/I/F7/F8` | Utility slots 1–4. |
| Alt-D/Alt-A, `K` | Food, water/combined and consumables. |
| Alt-E/S/Z/Q/C | Heal potion, bandage, healthstone, mana potion and mana gem. |
| `8/9`, F10/F11/F12, Shift-F11 | Teleport, mage TP/portal toggle, conjures and refreshment. |
| Alt-wheel up/down | Trinket 1/2. |
| `B/0/H/P/Shift-P/N/L/J/M/O` | Bags, character, PVP, spellbook, pet book, talents, quest log, guild, map and social. |

`ApplyKeybinds` clears existing keys outside this template and changes differing template assignments, in batches of eight across frames. It saves the current set using `SaveBindings(GetCurrentBindingSet())`. Combat queues or pauses application; repeated calls use guards and can queue one reapply. Applying the template can therefore replace custom bindings; it does more than fill unbound Flux commands.

Bulk suppression prevents each `UPDATE_BINDINGS` from rebuilding every consumer. `FlushBindingRefreshAfterBulk` consolidates bar, mouseover, Extra Buttons, utility and trinket refresh, followed by guard release and a final late Extra Button refresh.

[Bindings.xml](../Bindings.xml) supplies Flux command names/click routes. Conjure labels update from preferred available spells. `Flux.Hotkey` formats abbreviations and bundled mouse/scroll/Space glyphs. Shift takes display-prefix priority over Control; Alt is not a paging prefix. Conditional spell/chord routing is a separate Binding subsystem.

## Settings packs and write routes

`FLUX_DEFAULTS` groups controls, mouse/camera, names/nameplates, interface, raid/PVP, action bars, combat, social/chat and UI scale. Examples include auto-loot, combined bags, key-down actions, numeric cooldowns, enemy nameplates/class colors, large nameplates with 120% auras, compact party/power/heal displays, camera zoom and classic inline whispers. A table entry is not proof of a write on every client: missing APIs/CVars and coupled settings have specific guards.

| Owner | Actual behavior |
|---|---|
| [BlizzardSettings/Write.lua](../BlizzardSettings/Write.lua) | `Run(key, fn)` queues keyed work in combat or while SettingsPanel is open; flushes on regen/after hide. Low-level `CVar`/`Bit` check combat, existence and equality. Settings-sensitive callers must use the queued route. |
| [Nameplates.lua](../BlizzardSettings/Nameplates.lua) | Scalars, NPC flags, class colors and enum bitfields. Full pack runs on setup/reset/request; only health amount/percent bits reassert on world entry. |
| [Raid.lua](../BlizzardSettings/Raid.lua) | Tutorials, raid/PVP CVars and available active raid-profile fields. Profile writes can wait for compact profiles. Flux raid enablement affects Blizzard layout defaults. |
| `Flux.CVar` / legacy `FluxSetCVar` | General guarded routes block selected coupled nameplate/raid/target-cast settings. They are distinct from curated packs. |
| `FluxDefaultSettings` methods | Controls, combat, bars, camera/interface/chat and modified-click packs, with client exclusions and guarded helpers. |

On modern Retail/Forever, `Write.MayUseSettingsAPI()` is false: it avoids `Settings.SetValue`/`NotifyUpdate` callback chains. Curated CVar packs still apply with Settings closed and outside combat. Classic paths may refresh corresponding Settings controls. `Write.IsSecretClient` is a client-policy predicate, not a guarantee that every value is secret.

Camera maximum zoom is resolved by `GetMaxCameraDistanceZoomFactor`; the table's 2.6 is not universal. Mouseover Cast also has an exception: wrap clients keep native mouseover off, while current Forever code leaves its native CVar to Blizzard's checkbox and updates Flux attributes. See [08-shared-services.md](08-shared-services.md).

## Reset detection and state semantics

Official Settings reset callbacks and legacy hooks/heuristics can reapply full/category packs. Modern Retail/Forever defer sensitive reset jobs until Settings closes; full resets can reapply keys. Resetting Blizzard settings can therefore cause Flux recommendations to return.

`GetState()` labels a small critical-CVar sample `FRESH`/`MODIFIED` by comparing to **Blizzard `GetCVarDefault`**, rather than the full Flux recommendation table. It is not an audit that Flux defaults are intact.

Automatic `VerifyPostLoginDefaults` and binding-change verification preserve customized keybindings. A different F5 assignment no longer reapplies keys or triggers a CVar reset. Explicit reset-to-Flux-defaults still applies the keyboard template. Existing first-account setup and explicit Blizzard reset handling are separate paths; see the [implementation report](43-startup-optimization.md).

## Commands and reset boundaries

| `/fluxdefaults` argument | Effect |
|---|---|
| none / unknown | State/debug output and usage. |
| `apply`, `force` | Both call `Apply(true)`: forced full settings/key application. |
| `keybinds` | Keyboard template only. |
| `cvars` | CVar-only flow. |
| `reset` | Clears the account-applied flag, not every setting or character flag. |
| `resetchar` | Clears this character's seen flag; when account setup is marked, next login runs character-only setup. |

There is no Defaults tab. Action Bars exposes keyboard reset/binding mode, feature tabs expose individual resets, and Ace profile/Layout resets have different storage boundaries.

## Scale and horizontal squeeze

`MIN_UI_SCALE` is 0.75. `GetOptimalUIScale` tries physical screen size, then `gxResolution`, then 1920×1080. It computes `0.75 - (1.90 - aspectRatio) * 0.442`, clamps to `[0.75, 1]`, and formats two decimals. This policy differs from a feature's local frame scale.

Global `FluxUILayoutSqueeze` supplies console geometry helpers. Squeeze is considered only with custom UI scaling at/below the floor. Solvers compare logical row width to the available right boundary, include margins/slack, and clamp horizontal factors to `[0.4, 1]`. Nil means geometry is unavailable or compression is unnecessary. Height stays native; dependent widths follow the action bar's X factor.

Dynamic targets consider shown Flux Window/map/trinket dimensions. Cached emulated full 19-column geometry stabilizes unit-frame-dependent width so transient minirow contents do not resize unit frames repeatedly. `RequestRefresh` coalesces resolution/UI scale/UIParent size changes onto the layout tier, including unchanged-uiScale resolution changes. Combat defers named work.

`NotifyLayoutDependents` refreshes grid/trinket anchors, utilities/flyout arrows, chat, badges, buffs/auras, pet/stance bars and related unit placement with a recursion guard. Independent unit-frame scale helpers and aura caches narrow which updates propagate. Placement and flow diagrams are in [06-layout.md](06-layout.md).
## Complete literal default tables

The tables below reproduce every literal entry from `DefaultKeyTemplate` and `FLUX_DEFAULTS` in [FluxDefaultSettings.lua](../FluxDefaultSettings.lua), in source order. They describe configured recommendations, not unconditional successful writes. Dynamic UI scale/camera overrides, modified-click setup, enum bitfields and client guards above still apply. Regenerate these rows if those source tables change.

### Keyboard assignments (83)

| Chord | SetBinding command |
|---|---|
| `W` | `MOVEFORWARD` |
| `S` | `MOVEBACKWARD` |
| `A` | `STRAFELEFT` |
| `D` | `STRAFERIGHT` |
| `SPACE` | `JUMP` |
| `-` | `SITORSTAND` |
| `'` | `TOGGLEAUTORUN` |
| `+` | `TOGGLERUN` |
| `ESCAPE` | `TOGGLEGAMEMENU` |
| `B` | `OPENALLBAGS` |
| `0` | `TOGGLECHARACTER0` |
| `H` | `TOGGLECHARACTER4` |
| `P` | `TOGGLESPELLBOOK` |
| `SHIFT-P` | `TOGGLEPETBOOK` |
| `N` | `TOGGLETALENTS` |
| `L` | `TOGGLEQUESTLOG` |
| `J` | `TOGGLEGUILDTAB` |
| `M` | `TOGGLEWORLDMAP` |
| `1` | `ACTIONBUTTON1` |
| `2` | `ACTIONBUTTON2` |
| `3` | `ACTIONBUTTON3` |
| `4` | `ACTIONBUTTON4` |
| `5` | `ACTIONBUTTON5` |
| `½` | `ACTIONBUTTON6` |
| `Q` | `ACTIONBUTTON7` |
| `E` | `ACTIONBUTTON8` |
| `R` | `ACTIONBUTTON9` |
| `T` | `ACTIONBUTTON10` |
| `F` | `ACTIONBUTTON11` |
| `G` | `ACTIONBUTTON12` |
| `BUTTON5` | `MULTIACTIONBAR2BUTTON8` |
| `BUTTON4` | `MULTIACTIONBAR2BUTTON9` |
| `BUTTON3` | `MULTIACTIONBAR2BUTTON10` |
| `<` | `MULTIACTIONBAR2BUTTON11` |
| `Z` | `MULTIACTIONBAR2BUTTON12` |
| `X` | `MULTIACTIONBAR4BUTTON8` |
| `C` | `MULTIACTIONBAR4BUTTON9` |
| `TAB` | `TARGETNEARESTENEMY` |
| `SHIFT-TAB` | `TARGETPREVIOUSENEMY` |
| `CTRL-TAB` | `TARGETNEARESTFRIEND` |
| `CTRL-SHIFT-TAB` | `TARGETPREVIOUSFRIEND` |
| `SHIFT-V` | `INTERACTTARGET` |
| `MOUSEWHEELUP` | `CAMERAZOOMIN` |
| `MOUSEWHEELDOWN` | `CAMERAZOOMOUT` |
| `ENTER` | `OPENCHAT` |
| `PRINTSCREEN` | `SCREENSHOT` |
| `V` | `TOGGLEPINGLISTENER` |
| `F6` | `NAMEPLATES` |
| `SHIFT-F6` | `FRIENDNAMEPLATES` |
| `CTRL-F6` | `ALLNAMEPLATES` |
| `F1` | `SHAPESHIFTBUTTON1` |
| `F2` | `SHAPESHIFTBUTTON2` |
| `F3` | `SHAPESHIFTBUTTON3` |
| `F4` | `SHAPESHIFTBUTTON4` |
| `SHIFT-F1` | `SHAPESHIFTBUTTON5` |
| `SHIFT-F2` | `SHAPESHIFTBUTTON6` |
| `SHIFT-F3` | `SHAPESHIFTBUTTON7` |
| `SHIFT-F4` | `SHAPESHIFTBUTTON8` |
| `F5` | `FLUXRELOADUI` |
| `Y` | `FLUXGRIDSMARTMOUNT` |
| `7` | `FLUXGRIDHEARTH` |
| `6` | `FLUXGRIDVENDORMOUNT` |
| `I` | `FLUXSPELLBOOKSLOT2` |
| `U` | `FLUXSPELLBOOKSLOT1` |
| `O` | `TOGGLESOCIAL` |
| `F7` | `FLUXSPELLBOOKSLOT3` |
| `F8` | `FLUXSPELLBOOKSLOT4` |
| `ALT-D` | `FLUXGRID_FOOD_OR_RECUP` |
| `ALT-A` | `FLUXGRID_WATER_OR_COMBINED` |
| `K` | `FLUXGRID_CONSUMABLES` |
| `ALT-E` | `FLUXCOMBAT_HEALPOT` |
| `ALT-S` | `FLUXCOMBAT_BANDAGE` |
| `ALT-Z` | `FLUXCOMBAT_HEALTHSTONE` |
| `ALT-Q` | `FLUXCOMBAT_MANAPOT` |
| `ALT-C` | `FLUXCOMBAT_MANAGEM` |
| `8` | `FLUXCLASS_TELEPORT` |
| `9` | `FLUXMAGE_TOGGLE_TPPT` |
| `F10` | `FLUXMAGE_CONJURE_MANAGEM` |
| `F11` | `FLUXMAGE_CONJURE_FOOD` |
| `F12` | `FLUXMAGE_CONJURE_WATER` |
| `SHIFT-F11` | `FLUXMAGE_RITUAL_OF_REFRESHMENT` |
| `ALT-MOUSEWHEELUP` | `FLUXTRINKET1` |
| `ALT-MOUSEWHEELDOWN` | `FLUXTRINKET2` |

### Scalar CVar recommendations (126)

| CVar | Literal recommendation |
|---|---|
| `autoClearAFK` | `1` |
| `interactOnLeftClick` | `0` |
| `lootUnderMouse` | `1` |
| `autoLootDefault` | `1` |
| `autoLootKey` | `3` |
| `softTargetInteract` | `3` |
| `softTargettingInteractKeySound` | `0` |
| `stickyTargeting` | `0` |
| `combinedBags` | `1` |
| `enableMouseoverCast` | `0` |
| `ClipCursor` | `0` |
| `mouseInvertPitch` | `0` |
| `mouseLookSpeed` | `5.5` |
| `enableMouseSpeed` | `0` |
| `autointeract` | `0` |
| `cameraWaterCollision` | `0` |
| `cameraFollowSpeed` | `5.5` |
| `cameraSmoothStyle` | `0` |
| `cameraDistanceMaxZoomFactor` | `2.6` |
| `cameraTerrainTilt` | `0` |
| `cameraBobbing` | `0` |
| `cameraPivot` | `1` |
| `unitNameOwn` | `0` |
| `UnitNameNPC` | `1` |
| `UnitNameFriendlySpecialNPCName` | `0` |
| `UnitNameHostleNPC` | `0` |
| `UnitNameInteractiveNPC` | `0` |
| `ShowQuestUnitCircles` | `1` |
| `UnitNameNonCombatCreatureName` | `1` |
| `UnitNameFriendlyPlayerName` | `1` |
| `UnitNameFriendlyMinionName` | `1` |
| `UnitNameEnemyPlayerName` | `1` |
| `UnitNameEnemyMinionName` | `1` |
| `nameplateShowAll` | `1` |
| `nameplateShowEnemies` | `1` |
| `nameplateShowEnemyMinions` | `1` |
| `nameplateShowEnemyMinus` | `1` |
| `nameplateShowOffscreen` | `1` |
| `nameplateShowFriendlyPlayers` | `0` |
| `nameplateShowSelf` | `0` |
| `nameplateSize` | `3` |
| `nameplateAuraScale` | `1.2` |
| `nameplateStyle` | `2` |
| `nameplateShowClassColor` | `1` |
| `nameplateShowFriendlyClassColor` | `0` |
| `showTutorials` | `0` |
| `statusTextDisplay` | `BOTH` |
| `chatBubblesParty` | `1` |
| `displayHelm` | `1` |
| `displayCloak` | `1` |
| `instantQuestText` | `1` |
| `autoQuestWatch` | `1` |
| `displayFreeBagSlots` | `1` |
| `consolidateBuffs` | `0` |
| `hideOutdoorWorldState` | `0` |
| `rotateMinimap` | `0` |
| `showMinimapClock` | `1` |
| `showDetailedTooltips` | `1` |
| `threatShowNumeric` | `1` |
| `threatWarning` | `3` |
| `showTargetCastbar` | `1` |
| `showEnemyCastbar` | `1` |
| `showSwingTimer` | `0` |
| `ShowDynamicBuffSize` | `1` |
| `alwaysShowRuneIcons` | `0` |
| `UseClassicGuildUI` | `0` |
| `UberTooltips` | `1` |
| `unitFramesDisplayIncomingHeals` | `1` |
| `useCompactPartyFrames` | `1` |
| `raidFramesDisplayPowerBars` | `1` |
| `raidFramesDisplayClassColor` | `1` |
| `raidFramesHealthText` | `perc` |
| `raidFramesDisplayIncomingHeals` | `1` |
| `raidFramesDisplayDebuffs` | `1` |
| `raidFramesDisplayBuffs` | `1` |
| `raidFramesDisplayOnlyDispellableDebuffs` | `1` |
| `raidFramesFadeOutOfRange` | `1` |
| `raidFramesDisplayInOtherPhase` | `1` |
| `raidOptionDisplayMainTankAndAssist` | `1` |
| `raidOptionDisplayPets` | `0` |
| `raidFramesDisplayOnlyHealerPowerBars` | `0` |
| `raidFramesDisplayAggroHighlight` | `1` |
| `raidFramesDisplayLargerRoleSpecificDebuffs` | `1` |
| `raidFramesCenterBigDefensive` | `1` |
| `pvpFramesDisplayPowerBars` | `1` |
| `pvpFramesDisplayClassColor` | `1` |
| `pvpFramesHealthText` | `perc` |
| `pvpFramesDisplayOnlyHealerPowerBars` | `0` |
| `pvpOptionDisplayPets` | `0` |
| `alwaysShowActionBars` | `1` |
| `lockActionBars` | `0` |
| `countdownForCooldowns` | `1` |
| `enableMultiActionBars` | `0` |
| `multiBarLeft` | `0` |
| `multiBarRight` | `0` |
| `multiBarBottomLeft` | `0` |
| `multiBarBottomRight` | `0` |
| `ActionButtonUseKeyDown` | `1` |
| `raidSelfHighlight` | `0` |
| `showTargetOfTarget` | `1` |
| `doNotFlashLowHealthWarning` | `0` |
| `autoSelfCast` | `1` |
| `occludedSilhouettePlayer` | `1` |
| `assistedCombatHighlight` | `0` |
| `cooldownViewerEnabled` | `0` |
| `empowerTapControls` | `1` |
| `softTargetEnemy` | `1` |
| `profanityFilter` | `0` |
| `guildMemberNotify` | `1` |
| `blockTrades` | `0` |
| `restrictCalendarInvites` | `0` |
| `blockChannelInvites` | `1` |
| `showToastOnline` | `1` |
| `showToastOffline` | `1` |
| `showToastBroadcast` | `0` |
| `showToastFriendRequest` | `1` |
| `showToastWindow` | `0` |
| `chatStyle` | `classic` |
| `whisperMode` | `inline` |
| `showTimestamps` | `none` |
| `useUIScale` | `1` |
| `enableFloatingCombatText` | `0` |
| `floatingCombatTextCombatDamage_v2` | `1` |
| `floatingCombatTextCombatLogPeriodicSpells_v2` | `1` |
| `floatingCombatTextPetMeleeDamage_v2` | `1` |
| `floatingCombatTextCombatHealing_v2` | `1` |

### Nameplate enum bitfields

[BlizzardSettings/Nameplates.lua](../BlizzardSettings/Nameplates.lua), `BITFIELDS`, enables the following enum keys and disables other positive numeric keys in each available enum group. Missing CVars/groups are skipped.

| CVar | Enabled keys |
|---|---|
| `nameplateInfoDisplay` | CurrentHealthPercent, CurrentHealthValue, RarityIcon. |
| `nameplateCastBarDisplay` | SpellName, SpellIcon, SpellTarget, HighlightImportantCasts, HighlightWhenCastTarget. |
| `nameplateThreatDisplay` | Progressive, Flash, HealthBarColor. |
| `nameplateEnemyNpcAuraDisplay` | Buffs, Debuffs, CrowdControl. |
| `nameplateEnemyPlayerAuraDisplay` | Buffs, Debuffs, LossOfControl. |
| `nameplateFriendlyPlayerAuraDisplay` | Buffs, Debuffs, LossOfControl. |
| `nameplateSimplifiedTypes` | Minion, MinusMob. |
| `nameplateStackingTypes` | Enemy, Friendly. |

The raid/PVP table also associates scalar values with typed Settings values and writes active profile options through [Raid.lua](../BlizzardSettings/Raid.lua), `CVARS`/`ApplyProfile`. Self/focus modified-click setup and dynamic camera limits remain defined by the named pack functions; they are not extra literal rows in FLUX_DEFAULTS.
