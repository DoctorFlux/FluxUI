-- Verbatim Clicked enUS strings used by the Flux per-spell binding editor.
-- Keys mirror Clicked\Locales\enUS.lua so labels and tooltips match exactly.
-- English-only; Clicked itself ships English fallback for non-enUS clients
-- and we follow the same approach to keep the editor's wording stable.

local function FluxSpellBindingModulesSupported()
    local W = WOW_VERSION
    if not W then return true end
    if W.isRetail or not W.isLegacyClient then return true end
    if W.isClassic or W.isTBC or W.isWrath or W.isWOTLK or W.isCata then return true end
    if W.isModernClient and (W.majorVersion or 0) == 1 then return true end
    return false
end
if not FluxSpellBindingModulesSupported() then
    return
end

--- @type table<string, string>
local L = {}

-- Tabs and high-level
L["Action"]                          = "Action"
L["Targets"]                         = "Targets"
L["Macro conditions"]                = "Macro conditions"
L["Modifier conditions"]             = "Modifier conditions (shared action-bar key)"
L["Alt modifier"]                    = "Alt"
L["Shift+Ctrl modifier"]             = "SHIFT+CTRL"
L["modifier_conditions_hint"]        =
    "Only offered when this spell shares an action-bar key. SHIFT+CTRL requires the SHIFT mini, a Shift/Ctrl shared mini, or Main when that column has no minirows. Selecting both Alt and SHIFT+CTRL bakes SHIFT+CTRL+ALT."
L["Conditions"]                      = "Conditions"
L["Status"]                            = "Status"
L["editor_tab_cast"]                 = "Cast"
L["editor_tab_multicast"]            = "Multi-cast"
L["editor_tab_conditions"]           = "Conditions"
L["editor_tab_targets"]              = "Targets"
L["editor_tab_forms"]                = "Forms"
L["editor_tab_status"]               = "Status"
L["editor_tab_bar_badges"]           = "Bar & Badges"
L["editor_tab_badges"]               = "Bar & Badges"
L["editor_form_bar_slot_fmt"]        = "Bar: Button %s"
L["editor_form_bar_none"]            = "Bar: —"
L["editor_shared_bindings_heading"]  = "Shared bindings"
L["editor_shared_section_bar"]       = "Action bar (buttons 1–12)"
L["editor_shared_section_bindings"]  = "Same key (Flux bindings)"
L["editor_shared_section_badges"]    = "Corner badges"
L["editor_shared_section_other"]     = "Other"
L["editor_shared_none"]              = "No other spells share this binding slot's keys."
L["editor_form_bar_map_heading"]     = "Per-form action bar"
L["editor_form_bar_map_line"]        = "%s — %s"
L["editor_form_bar_slot_line"]       = "Button %s: %s"
L["editor_form_bar_slot_empty"]      = "—"
L["editor_form_bar_shared_none"]     = "No Flux action bar button shares this binding key."
L["editor_form_row_active"]          = "Active"
L["editor_form_icon_select_hint"]    = "Select this form to edit. Use the checkbox to enable the custom binding."
L["editor_bar_status_heading"]       = "Action bar link"
L["editor_bar_status_none"]          = "Not on the Flux bar and no key set yet."
L["editor_bar_status_on_bar_no_keys_tip"] =
    "This spell is on FluxActionButton%d (%s). Bar keys come from the WoW binding for |cffffcc00%s|r (Key Bindings \226\134\146 Action Bars). After you bind that command, bar keys and routed SHIFT/CTRL chords appear here."
L["editor_banner_bar_keys_line"]     = "Bar keys: |cffffcc00%s|r"
L["editor_banner_routed_inline"]     = " (also routed: %s)"
L["editor_bar_bind_cmd_inline"]      = "bind %s in WoW keybindings"
L["editor_bar_status_explicit_clear"] = "Key bound \194\151 no action bar conflict."
L["editor_bar_slot_main"]              = "main row"
L["editor_bar_slot_secondary"]         = "minirow top-left (SHIFT)"
L["editor_bar_slot_tertiary"]          = "minirow top-right (CTRL)"
L["editor_column_layout_main_only"]    = "Main row only (Shift/Ctrl also fire main)"
L["editor_column_layout_main_secondary"] = "Main + Shift mini (Ctrl uses same mini)"
L["editor_column_layout_main_tertiary"]  = "Main + Ctrl mini (Shift uses same mini)"
L["editor_column_layout_main_both"]    = "Main + both minis"
L["editor_column_layout_promoted_sec"] = "Promoted: secondary on main"
L["editor_column_layout_promoted_tert"] = "Promoted: tertiary on main"
L["editor_column_layout_promoted_both"] = "Promoted: both minis"
L["editor_column_layout_hint_fmt"]     = "Button %s — %s"
L["editor_form_badge_layout_tip"]      = "Column layout: %s"
L["editor_banner_same_spell_bar_slot_short"] =
    "Keys: overlaps bar (%s) — same spell on %s."
L["editor_banner_same_spell_bar_slot_line"]  = "Flux bar: Button %s (%s)."
L["editor_bar_status_compatible_short"] =
    "Keys: |cffffcc00%s|r — shares bar key with |cffffcc00%s|r (compatible targeting)."
L["editor_bar_status_compatible_tip"] =
    "This key also drives |cffffcc00%s|r on the Flux bar. Flux treats help/harm as compatible — no key-split duel."
L["editor_banner_mirror_chords_line"] =
    "While this column layout is unchanged, these keys also fire your bind: |cffffcc00%s|r"
L["editor_banner_shares_key_label"]     = "Shares key:"
L["editor_banner_routed_keys_line"]     = "Also routed: |cffffcc00%s|r"
L["editor_banner_bar_implicit_line"]    = "Bar keys: |cffffcc00%s|r"
L["editor_banner_shared_keys_tip"] =
    "Other spells sharing this key (|cffffcc00%s|r): "
L["editor_banner_shared_keys_more"] = " (+%d more)"
L["editor_banner_multicast_count"] = "Multi-cast: %d"
L["editor_banner_multicast_host_count"] = "Used as multi-cast on: %d"
L["multicast_share_extra_tip"]     = "Multi-cast"
L["multicast_share_host_tip"]      = "Multi-cast host"
L["multicast_share_extra_on_fmt"]  = "on %s"
L["multicast_place_fmt"]           = "Multi-cast · %s"
L["multicast_badge_settings_hint"] =
    "These Bar & Badges settings apply when this action appears as a multi-cast corner badge on its host spell."
L["multicast_host_badge_settings_hint"] =
    "Settings below are for this spell only. Corner badges (trinkets, Combustion, …) use Bar & Badges on each extra’s own binding in the list."
L["browser_tab_equipment_slots"]    = "Equipment slots"
L["editor_badge_display_heading"]    = "Badge display"
L["editor_badge_display_form_fmt"]   = "Settings for: %s"
L["editor_status_show_form_matrix"]  = "Show per-form macro matrix"
L["editor_status_advanced_preview"]  = "Advanced preview (merged context)"
L["binding_instance_add_compact"]    = "+"
L["binding_instance_remove_compact"] = "Remove"
L["Generated macro"]                 = "Generated macro"
L["status_macro_default_profile"]    = "All settings match defaults for this spell. The game uses the spellbook/action button as-is; there is no generated Flux macro to show."
L["status_implicit_default_on_bar"]   =
    "Bar keys |cffffcc00%s|r use the native action button until you customize Cast, Conditions, or Targets."
L["implicit_default_customize_hint"]   =
    "Default profile — customize Cast, Conditions, or Targets to activate a Flux macro on your bar keys."
L["status_macro_unavailable"]        = "Could not build a preview (spell data still loading or invalid profile)."
L["status_macro_explicit_hint"]      = "Preview matches your |cffffd200explicit|r Flux key binding."
L["status_macro_implicit_hint"]      = "Preview matches |cffffd200implicit|r chord layer (Flux action bar and/or spellbook strip binding with a non-default profile and no Flux key)."
L["status_macro_no_bind_hint"]         = "No active key or bar chord yet; below is the macro your profile would generate once bound or on-bar."
L["Generated macro (%d/%d)"]         = "Generated macro (%d / %d)"
L["Generated hovercast macro (%d/%d)"] = "Generated hovercast macro (%d / %d)"
L["Generated full macro (%d/%d)"]    = "Full macro — combined (%d / %d)"
L["binding_instance_bind_label_short"] = "Binding slot"
L["binding_instance_add"] = "Add binding"
L["binding_instance_remove"] = "Remove"
L["binding_instance_dropdown_default_named"] = "Default — %s"
L["binding_instance_dropdown_default_only"] = "Default (no key)"
L["binding_instance_dropdown_named"] = "%s — %s"
L["binding_instance_dropdown_id_only"] = "%s"
L["binding_instance_dropdown_also_more"] = " +%d"
L["binding_instance_dropdown_also_suffix"] = "%s  |cffaaaaaa%s %s|r"
L["binding_instance_dropdown_none_profile_only"] = "Profile only (set keys below)"
L["status_binding_instance_heading_short"] = "Binding — %s"
L["Key"]                             = "Key"
L["Reset to defaults"]                 = "Reset to defaults"
L["reset_profile_popup_text"]          = "Reset all Flux binding options for this spell to defaults? This does not clear your key bind."
L["Editor status hint"]                = "Drag title to move — edges to resize — Esc closes"
L["Flux binding editor subtitle"]      = "Flux binding profile — macro behavior & targets"
L["editor_key_tooltip_title"]           = "Key"
L["editor_keybind_line_short"]          =
    "Click then press to bind — right-click clears. One key per binding slot."
L["editor_banner_info_tooltip_title"]  = "Shared keys / overlap"
L["editor_banner_explicit_short"]      = "Keys: |cffffcc00%s|r — overlaps bar or strip (details: hover ?)."
L["editor_banner_strip_chords_short"]  = "Strip slot %d (%s) + keys |cffffcc00%s|r — see ? for strip setup."
L["editor_banner_strip_need_bind_short"] = "Strip slot %d (%s) — bind FLUXSPELLBOOKSLOT%d (see ?)."
L["editor_banner_tooltip_split_suffix"] = "\n\nKey-split: the macro may use [harm] / [help] vs the bar/spellbook spell. Under Targets, adjust \"Same key — cast last\" if needed."
L["related_bindings_compact_prefix"]   = "Also:"
L["related_bindings_list_intro"]       = "Shared keys: |cffffcc00%s|r"
L["related_bindings_click_tip"]        = "Click an icon to open that spell's profile."
L["related_bindings_drag_stack_hint"] =
    "Drag explicit-binding icons onto each other to set tiebreaker order within the same target tier (unit frame, mouseover, target, default)."
L["chord_stack_order_heading"]        = "Chord stack order (merged macro)"
L["chord_stack_order_desc"]           =
    "Merged macros auto-order by target tier: unit frame, then global mouseover, target, default, then bar. Drag a spell row onto another to swap priority within the same tier. Top spell owns the physical key."
L["badge_corner_order_heading"]       = "Badge corner order"
L["badge_corner_order_desc"]          =
    "Drag icons to reorder action-bar corner badges. Top icon is corner 1. Includes the spell you are editing. Does not change merged macro order."
L["badge_corner_order_drag_hint"]     =
    "Drag onto another icon to swap badge corner priority."
L["badge_corner_order_current_spell"] = "(this spell)"
L["badge_corner_order_excluded_fmt"]   =
    "%d more spell(s) share this key — only the first 3 icons above appear as corner badges on the action bar."
L["badge_slot_compact_prefix"]        = "Badges:"
L["badge_slot_shared_intro"]          = "Shared key |cffffcc00%s|r — spells on this bind:"
L["badge_slot_drag_hint"]             =
    "Drag onto another icon to reorder corner badges. Does not change merged macro order."
L["chord_stack_bindings_targets_hint"] =
    "Shown here on Bindings and Targets tabs whenever this spell shares a merged chord stack with others."
L["editor_banner_same_spell_bar_short"] =
    "Keys: overlaps bar (%s same spell — no peek split)."
L["editor_banner_same_spell_bar_tip"] =
    "Your explicit key overlaps the Flux bar spell |cffffcc00%s|r (same spell family)."
        .. "\nFlux does not build a duplicate key-split / peek duel for identical spells."

L["status_macro_explicit_hint_short"]  = "Preview: explicit Flux key binding."
L["status_macro_multi_explicit_intro"] =
    "This spell has multiple Flux key binds. Each key has its own generated macro below — including the matching action-bar spell for key-split [harm]/[mouseover,harm] clauses."
L["status_generated_macro_for_binding"] = "Generated macro — |cffffcc00%s|r"
L["status_per_form_macros"]             = "Per-form macros"
L["status_per_form_macros_for_binding"] = "Per-form macros — |cffffcc00%s|r"
L["status_macro_implicit_hint_short"]   = "Preview: implicit Flux bar / strip keys."
L["status_macro_no_bind_hint_short"]   = "Preview: profile only (bind or place on bar to drive keys)."
L["status_shared_binding_intro"] =
    "This spell shares |cffffcc00%s|r with other bindings. All peers use the same merged macro on the anchor spell"
    .. " (|cffffcc00%s|r). Action bar button, corner badges, and unit-frame hover all route through these macros."
L["status_shared_keyboard_macro"]      = "Keyboard / action bar button"
L["status_keyboard_not_installed"]     = "Keypress macro is not on this bar button, so the corner badge was not installed either."
L["status_shared_uf_hover_macro"]        = "Unit frame hover"
L["status_shared_bar_fallback_fmt"]    = "When no conditional clause matches, the key falls back to the action bar spell: |cffffcc00%s|r."
L["status_shared_no_macro"]            = "Could not build a shared macro preview for this key."
L["Optional cast prefix"]            = "Optional cast prefix"
L["Optional cast prefix help"]       = "Optional text before the spell name in /cast (e.g. ! to force cast)."

-- Action options (verbatim Clicked enUS keys)
L["Interrupt current cast"]          = "Interrupt current cast"
L["Allow this binding to cancel any spells that are currently being cast."] =
    "Allow this binding to cancel any spells that are currently being cast."
L["Start auto attacks"]              = "Start auto attacks"
L["Allow this binding to start auto attacks, useful for any damaging abilities."] =
    "Allow this binding to start auto attacks, useful for any damaging abilities."
L["Start pet attacks"]               = "Start pet attacks"
L["Allow this binding to start pet attacks."] =
    "Allow this binding to start pet attacks."
L["Override queued spell"]           = "Override queued spell"
L["Allow this binding to override a spell that is queued by the lag-tolerance system, should be reserved for high-priority spells."] =
    "Allow this binding to override a spell that is queued by the lag-tolerance system, should be reserved for high-priority spells."
L["Exit shapeshift form"]            = "Exit shapeshift form"
L["Allow this binding to automatically exit your shapeshift form."] =
    "Allow this binding to automatically exit your shapeshift form."
L["Cancel an aura"]                  = "Cancel an aura before cast"
L["Allow this binding to cancel a buff or debuff on you before casting."] =
    "Allow this binding to cancel a buff or debuff on you before casting (/cancelaura)."
L["Target aura"]                     = "Aura name or spell ID"
L["Enter the aura name or spell ID."] =
    "Emits /cancelaura before the cast. Enter the aura name, or a spell ID (resolved to its name)."
L["Include spell subtext"]           = "Include spell subtext"
L["Append the spell subtext to the cast command, e.g. Whirling Surge(Skyriding). Enable this if the spell does not cast without it."] =
    "Append rank or trainer subtext after the spell name in the cast line and tooltip preview, e.g. Frostbolt(Rank 1) on Classic or Whirling Surge(Skyriding) on retail. Enable when the client needs that exact name variant to cast."
L["Use spell:id in macro"]           = "Use spell:id in macro"
L["Use spell:id in macro help"] =
    "When enabled and \"Include spell subtext\" does not apply, generated /cast clauses use spell:<id> instead of the spell name to save macro space. On Classic or when rank subtext is required, Flux keeps using the spelled-out name."
L["rank_sync_by_name"]               = "Sync all ranks (same spell name)"
L["rank_sync_by_name_desc"]          = "Classic: one shared binding profile for every rank of this spell (targets, conditions, badges, key). Each bar slot still casts its own Rank N. Turn off to copy settings onto each rank so they can differ again."
L["(all ranks)"]                     = "(all ranks)"
L["remove_rank"]                     = "Remove this rank"
L["remove_rank_desc"]                = "Deletes the binding row for this spell rank. If ranks were synced, they are unsynced first so other ranks keep their settings."
L["sticky_respec"]                   = "Sticky across Respec"
L["UNBOUND"]                         = "UNBOUND"
L["browser_source"]                  = "Bindings source"
L["browser_live"]                    = "Live (current)"
L["browser_filter_all"]              = "All"
L["browser_filter_unbound"]          = "Unbound"
L["browser_filter_default"]          = "Default"
L["browser_filter_customized"]       = "Customized"
L["browser_search"]                  = "Search"
L["browser_preview_note"]            = "Preview — edits save to this Respec profile only (not applied live)."
L["browser_sticky_hint"]             = "* Sticky across Respec survives Load/Apply"
L["browser_filter_onbar"]            = "On bar / Stance / Extra / Multi-cast"
L["browser_filter_barkey"]           = "Bar / EBS key only"
L["browser_bars_live"]               = "Bars + EBS: live"
L["browser_bars_profile"]            = "Bars: Respec"
L["browser_bars_live_fallback"]      = "Bars: live (no profile bars)"
L["browser_util_profile"]            = "Util: Respec"
L["browser_util_live"]               = "Util/EBS: live"
L["browser_actionbar_prefix"]        = "Action bar"
L["browser_sort_key"]                = "Key"
L["browser_sort_abc"]                = "ABC"
L["browser_show_on_keyboard"]        = "Show on keyboard"
L["browser_search"]                  = "Search..."
L["browser_unbound_hint"]            = "No binding row yet. Set a key or enable Sticky to create one."
L["Target on cast"]                  = "Target on cast"
L["Targets the unit you are casting on."] =
    "Targets the unit you are casting on."
L["Cast at cursor (ground-target AOE)"] = "Cast at cursor (ground-target AOE)"
L["Adds a [@cursor] fallback to the cast clause; useful for ground-target AOE spells like Blizzard or Flamestrike. Has no effect on non-ground-target spells."] =
    "Same as Targets: Key press → Target 1 → Unit = Cursor ([@cursor] in the macro). This toggle and that dropdown stay in sync. Useful for ground-target AOE. Key press must be enabled for the cast line to apply."
L["Prevent toggle"]                  = "Prevent toggle"
L["Prevent the ability from being toggled off by repeatetly pressing the keybind."] =
    "Prevent the ability from being toggled off by repeatetly pressing the keybind."
L["Clear blue cursor"]               = "Clear blue cursor"
L["Clears the \"blue casting cursor\"."] =
    "Clears the \"blue casting cursor\"."
L["It's recommended to always leave this option enabled unless you need the extra space in a macro."] =
    "It's recommended to always leave this option enabled unless you need the extra space in a macro."
L["Without it you may be left with a dangling cast if the macro cannot determine the target automatically, in other words if your targets don't end in either 'player' or 'cursor' (or 'default' if self-cast is enabled)"] =
    "Without it you may be left with a dangling cast if the macro cannot determine the target automatically, in other words if your targets don't end in either 'player' or 'cursor' (or 'default' if self-cast is enabled)"

-- Targets tab
L["Activate on"]                     = "Activate on"
L["Key press"]                       = "Key press"
L["Unit frame"]                      = "Unit frame"
L["Both"]                            = "Both"
L["Hostility"]                       = "Hostility"
L["Vitals"]                          = "Vitals"
L["Unit"]                            = "Unit"
L["Any"]                             = "Any"
L["Friendly"]                        = "Friendly"
L["Hostile"]                         = "Hostile"
L["Alive"]                           = "Alive"
L["Dead"]                            = "Dead"

-- Unit list (Clicked TargetUnit values)
L["Default"]                         = "Default"
L["Player (you)"]                    = "Player (you)"
L["Target"]                          = "Target"
L["Target of target"]                = "Target of target"
L["Mouseover"]                       = "Mouseover"
L["Target of mouseover"]             = "Target of mouseover"
L["Focus"]                           = "Focus"
L["Cursor"]                          = "Cursor"
L["Pet"]                             = "Pet"
L["Pet target"]                      = "Pet target"
L["browser_tab_pet"]                  = "Pet"
L["Party %s"]                        = "Party %s"
L["Arena %s"]                        = "Arena %s"
L["Add"]                             = "Add"
L["<Remove this target>"]            = "<Remove this target>"

-- Load conditions
L["Never load"]                      = "Never load"
L["Class"]                           = "Class"
L["Race"]                            = "Race"
L["Player Name-Realm"]               = "Player Name-Realm"
L["Combat"]                          = "Combat"
L["In combat"]                       = "In combat"
L["Not in combat"]                   = "Not in combat"
L["Spell known"]                     = "Spell known"
L["Enter the spell name or spell ID."] =
    "Enter the spell name or spell ID."
L["In group"]                        = "In group"
L["Not in a group"]                  = "Not in a group"
L["In a party"]                      = "In a party"
L["In a raid group"]                 = "In a raid group"
L["In a party or raid group"]        = "In a party or raid group"
L["Player in group"]                 = "Player in group"
L["None"]                            = "None"
L["Form / Stance"]                   = "Form / Stance"
L["Stance %s"]                       = "Stance %s"
L["Humanoid Form"]                   = "Humanoid Form"
L["Pet"]                             = "Pet"
L["Pet exists"]                      = "Pet exists"
L["No pet"]                          = "No pet"
L["Stealth"]                         = "Stealth"
L["Stealthed"]                       = "Stealthed"
L["Not stealthed"]                   = "Not stealthed"
L["Mounted"]                         = "Mounted"
L["Not mounted"]                     = "Not mounted"
L["Outdoors"]                        = "Outdoors"
L["Indoors"]                         = "Indoors"
L["Swimming"]                        = "Swimming"
L["Not swimming"]                    = "Not swimming"
L["Instance type"]                   = "Instance type"
L["No Instance"]                     = "No Instance"
L["Scenario"]                        = "Scenario"
L["Dungeon"]                         = "Dungeon"
L["Raid"]                            = "Raid"
L["Arena"]                           = "Arena"
L["Battleground"]                    = "Battleground"
L["Zone name(s)"]                    = "Zone name(s)"
L["Semicolon separated, use an exclamation mark (%s) to negate a zone condition, for example:"] =
    "Semicolon separated, use an exclamation mark (%s) to negate a zone condition, for example:"
L["%s will be active if you're not in Oribos"] =
    "%s will be active if you're not in Oribos"
L["%s will be active if you're in Durotar or Orgrimmar"] =
    "%s will be active if you're in Durotar or Orgrimmar"
L["Item equipped"]                   = "Item equipped"
L["This will not update when in combat, so swapping weapons or shields during combat does not work."] =
    "This will not update when in combat, so swapping weapons or shields during combat does not work."
L["Enter an item name, item ID, or equipment slot number."] =
    "Enter an item name, item ID, or equipment slot number."
L["You can also shift-click an item from your bags to auto-fill."] =
    "You can also shift-click an item from your bags to auto-fill."
L["Bonus bar"]                       = "Bonus bar"
L["Not bonus bar"]                   = "Not bonus bar"
L["Enter the bonus bar page number."] = "Enter the bonus bar page number."
L["Action bar page"]                 = "Action bar page"
L["Enter the action bar page number."] = "Enter the action bar page number."
L["Channeling"]                      = "Channeling"
L["Not channeling"]                  = "Not channeling"
L["Flying"]                          = "Flying"
L["Not flying"]                      = "Not flying"
L["Skyriding"]                       = "Skyriding"
L["Not skyriding"]                   = "Not skyriding"
L["Flyable"]                         = "Flyable"
L["Not flyable"]                     = "Not flyable"
L["Advanced flyable"]                = "Advanced flyable"
L["Not advanced flyable"]            = "Not advanced flyable"
L["Talent specialization"]           = "Talent specialization"
L["Specialization %s"]               = "Specialization %s"
L["Specialization role"]             = "Specialization role"
L["DPS"]                             = "DPS"
L["Tank"]                            = "Tank"
L["Healer"]                          = "Healer"
L["Talent"]                          = "Talent"
L["PvP talent"]                      = "PvP talent"
L["Talent %s/%s"]                    = "Talent %s/%s"
L["PvP Talent %s"]                   = "PvP Talent %s"
L["War Mode"]                        = "War Mode"
L["War Mode enabled"]                = "War Mode enabled"
L["War Mode disabled"]               = "War Mode disabled"

-- Misc
L["Not"]                             = "Not"
L["Add condition"]                   = "Add condition"
L["Remove compound"]                 = "Remove compound"
L["Add compound"]                    = "Add compound"
L["Click and press a key to bind, or right click to unbind."] =
    "Click and press a key to bind, or right click to unbind."

-- Flux additions (not from Clicked)
L["Spell not learned"]               = "Spell not learned"
L["Spell not learned \194\151 binding disabled"] = "Spell not learned \194\151 binding disabled"
L["Macro"]                           = "Macro"
L["Bindings"]                        = "Bindings"
L["action_bar_implicit_banner"]      =
    "This spell is on your action bar. Your settings will apply automatically to: %s"
L["implicit_layer_banner"]           =
    "With no Flux key bind, your non-default profile applies to these Flux bar keys: %s."
L["implicit_profile_applies_to_keys"] =
    "Non-default profile applies to these keys: %s."
L["implicit_strip_placement_line"]   =
    "Spellbook strip: slot %d — %s row (binding FLUXSPELLBOOKSLOT%d + held modifiers)."
L["spellbook_strip_assigned_need_bind"] =
    "Spellbook strip: slot %d — %s row. Bind FLUXSPELLBOOKSLOT%d in Controls so implicit chords apply."
L["status_implicit_spellbook_tier"]   =
    "Spellbook strip: slot %d — %s row. Preview uses [mod:…] on /cast lines to match that strip tier."
L["key_split_implicit_hint"] =
    "This binding's key also drives |cffffcc00%s|r on the Flux bar, spellbook strip, or default action bar. The generated macro uses [harm]/[help] so the bar spell and this spell split by target type. Under Targets, \"Same key — cast last\" chooses which spell fires when nothing else matches."
L["key_split_fallback_heading"] = "Same key as action bar / strip"
L["key_split_fallback_label"] = "Cast last if nothing matches"
L["key_split_fallback_action_bar"] = "Action bar spell"
L["key_split_fallback_binding"] = "This spell (binding)"
L["key_split_fallback_desc"] =
    "When there is no valid mouseover row, no matching [harm]/[help] / target row, or you have no target, the macro runs clauses left to right and uses the last one as the final fallback. Pick which spell that should be: usually your damaging bar ability, or this binding (e.g. Preservation) if you prefer it as the default press."
L["related_bindings_heading"] = "Spells on the same key"
L["related_bindings_keys_fmt"] = "Key(s): |cffffcc00%s|r — click a spell icon to open its profile:"
L["related_source_flux_bar"] = "Flux bar / strip"
L["related_source_flux_bar_form"] = "Flux bar — %s"
L["related_source_explicit"] = "Flux binding"
L["related_source_blizzard"] = "Default action bar"
L["keybinding_multi_hint"] =
    "Each binding slot has one Flux key chord. Macro behavior (splits, collisions) follows the key bound on the slot you are editing.|n|nWant another chord for this spell on a different slot? Press |cffffd200Add binding|r, pick or create a slot from the Binding slot menu, then bind a key there."
L["editor_icon_tooltip_title"] = "Spell"

-- Per-form binding profile tabs
L["form_tab_noform"]      = "No Form"
L["form_tab_cat"]         = "Cat Form"
L["form_tab_prowl"]       = "Cat (Prowl)"
L["form_tab_bear"]        = "Bear Form"
L["form_tab_moonkin"]     = "Moonkin"
L["form_tab_treeoflife"]  = "Tree of Life"
L["form_tab_stealth"]     = "Stealth"
L["form_tab_shadowdance"] = "Shadow Dance"
L["form_tab_shadowform"]  = "Shadowform"
L["form_tab_soar"]        = "Soar"
L["form_tab_skyriding"]   = "Skyriding"
L["form_tab_battle"]      = "Battle Stance"
L["form_tab_def"]         = "Defensive Stance"
L["form_tab_berserker"]   = "Berserker Stance"
L["form_tab_tiger"]       = "Fierce Tiger"
L["form_tab_ox"]          = "Sturdy Ox"
L["form_tab_serpent"]     = "Wise Serpent"
L["form_tabs_help"]       = "Form icons choose which sub-profile is active. Cast, Conditions, and Targets edit the selected form. Status shows the generated macro."
L["Active in this form"]  = "Active in this form"
L["status_form_matrix_heading"] = "Forms / stances"
L["status_form_matrix_help"] = "Toggle which forms use a custom binding profile. Inactive forms on your action bar use bar passthrough (click + default @mouseover cast) unless Action settings require a macro."
L["status_form_custom_binding"] = "Custom binding"
L["status_form_bar_passthrough"] = "Bar passthrough"
L["status_form_action_bar_macro"] = "Action bar macro"
L["status_form_inactive_not_on_bar"] = "Inactive (not on bar)"
L["status_form_editing_label"] = "Editing form: %s"
L["status_form_kb_passthrough_fmt"] = "%s — keyboard: uses %s"
L["status_form_uf_passthrough_fmt"] = "%s — unit-frame hover: bar spell @mouseover"
L["status_form_kb_macro_label"] = "Keyboard macro"
L["status_form_uf_macro_label"] = "Unit-frame hover macro"
L["status_form_select_hint"] = "Click the form name to edit Action / Targets for that form."
L["status_form_summary_help"] = "Read-only preview of the macro generated for each form. Use the Form panel at the top to switch forms or toggle which forms have a custom binding."
L["active_in_form_desc"]  = "When checked, this spell's binding profile generates a macro for this form/stance and the peek icon shows on the action bar."
L["badge_transparency_label"] = "Badge transparency"
L["badge_transparency_desc"] = "Corner badge opacity for this form (25% = slightly transparent). Does not affect the large action bar icon when a binding wins the swap."
L["badge_visibility_heading"] = "Badge visibility"
L["badge_visibility_desc"] = "Combine any rules below. Hidden badges keep dual-split / icon swap active."
L["badge_hidden_swap"] = "Hide badge (swap active)"
L["badge_hidden_always"] = "Always hidden"
L["badge_hidden_unless_cd"] = "Hidden unless on cooldown (not GCD only)"
L["badge_hidden_minirow"] = "Hidden on mini row (not main row)"
L["badge_cd_number_heading"] = "Cooldown numbers"
L["badge_cd_number_help"] =
    "Cooldown countdown digits on this binding’s corner badge(s). Default size is 100% (max). Applies to peer badges and multi-cast extras."
L["badge_cd_number_show"] = "Show cooldown numbers"
L["badge_cd_number_scale"] = "Cooldown number size"
L["badge_cd_number_scale_hint"] = "0% = smallest · 100% = maximum (0.7 digit scale)"
L["badge_cd_number_mainrow"] = "Show on main row"
L["badge_cd_number_minirow"] = "Show on mini rows (Shift / Ctrl)"
L["Copy from"]            = "Copy from..."
L["copy_from_desc"]       = "Copy all settings (Action, Conditions, Targets) from another form's sub-profile into this form. The Active flag is preserved."
L["per_state_toggle"]     = "Enable binding profiles for this bar page"
L["per_state_toggle_desc"]= "Master ON/OFF for all per-spell binding profiles on this stance or form page. Turning off wipes generated macros and hides peek icons for this page."
L["disabled_by_global_toggle"]  = "Disabled by the global page toggle in addon options."
L["Generated macro (%s)"] = "Generated macro (%s)"
L["status_form_inactive"] = "Inactive for this form — not on your action bar for this page."
L["status_form_disabled_global"] = "This form's page is disabled in addon options \194\151 no macro is generated."

-- Form / Stance / Skyriding selector panel (always-visible spine of the editor)
L["form_panel_heading"]      = "Form / Stance / Skyriding"
L["form_panel_help"]         =
    "Pick which form or stance uses a custom binding. Active applies to |cffffd200keypress and unit-frame hover|r together. Inactive forms fall back to the action bar (passthrough). Use Cast / Targets / Conditions to edit the form selected in the strip above."
L["form_panel_active_label"] = "Active in %s"
L["form_panel_active_both"]  =
    "Active applies to keypress and unit-frame hover together. Use the Targets tab for per-form keypress / hovercast clause options."
L["form_panel_page_enable"]  = "Page on"
L["form_panel_no_macro_cond"] = "no macro condition"
L["form_panel_noforms"]      = "No forms or stances for this character \194\151 this binding always applies."
L["form_panel_scroll_hint"]  = "Scroll for more forms."
L["status_form_disabled_short"] = "Disabled"
L["status_form_inactive_short"] = "Inactive"
L["editor_editing_form_caption"] = "Editing: %s"

-- Action tab section headings
L["action_section_cast_behavior"] = "Cast behavior"
L["action_section_macro_options"] = "Macro options"

-- Multi-cast extras (native-alone bar action)
L["multicast_extras_heading"]      = "Multi-cast"
L["multicast_extras_help"]         =
    "Drop spells or items onto the cast order. Drag icons to reorder — including the main bar action so extras cast before or after it. Right-click an extra to remove. Corner badges show the first 3 available (empty items/slots skipped)."
L["multicast_extras_unavailable"]  =
    "Multi-cast extras only apply to a native action-bar spell that does not share its key with another binding. Existing extras below are kept until you remove them."
L["multicast_extras_empty"]        = "Drop spell or item here"
L["multicast_extras_drop"]         = "Drop spell or item here"
L["multicast_extras_drop_hint"]    =
    "\n  Drag a spell from the spellbook or an item from your bags onto the cast order.\n"
L["multicast_extras_full"]         = "Maximum of %d extras reached."
L["multicast_extras_list_heading"] = "Cast order"
L["multicast_extras_list_empty"]   = "No extras yet — drop a spell or item onto the order."
L["multicast_extras_badge_note"]   =
    "Corner badges use the first 3 available extras. Missing items and unequipped slots stay in cast order but are skipped in the macro until available. Drag rows to reorder (including the main action)."
L["multicast_extras_skipped"]      = "skipped"
L["multicast_extras_unequipped"]   = "unequipped"
L["multicast_extras_missing"]      = "missing"
L["multicast_skipped_tip"]         = "Shown in order but skipped in the cast macro until available."
L["multicast_extras_reorder_hint"] = "Drag to reorder"
L["multicast_extras_icon_tip"]     = "Drag to reorder · Right-click to remove"
L["multicast_main_mark"]           = "(main)"
L["multicast_main_bar_mark"]       = "(action bar)"
L["multicast_main_tip"]            = "Native bar action — drag to cast extras before or after it."
L["multicast_order_tip"]           = "Drag to set cast order (including the action-bar main). The bar always keeps that main spell. Right-click an extra to remove."
L["multicast_order_empty"]         = "Drop spells or items here to build cast order."
L["multicast_add_equip_slot"]      = "Add equipment slot"
L["multicast_add_equip_choose"]    = "Choose a slot…"
L["multicast_add_equip_slot_help"] =
    "Pick a paperdoll slot (Trinket 1/2, Finger 1/2, …). Adds a /use N line; unequipped slots stay in order but are skipped until equipped."
L["multicast_slot_1"]              = "Head"
L["multicast_slot_2"]              = "Neck"
L["multicast_slot_3"]              = "Shoulder"
L["multicast_slot_4"]              = "Shirt"
L["multicast_slot_5"]              = "Chest"
L["multicast_slot_6"]              = "Waist"
L["multicast_slot_7"]              = "Legs"
L["multicast_slot_8"]              = "Feet"
L["multicast_slot_9"]              = "Wrist"
L["multicast_slot_10"]             = "Hands"
L["multicast_slot_11"]             = "Finger 1"
L["multicast_slot_12"]             = "Finger 2"
L["multicast_slot_13"]             = "Trinket 1"
L["multicast_slot_14"]             = "Trinket 2"
L["multicast_slot_15"]             = "Back"
L["multicast_slot_16"]             = "Main Hand"
L["multicast_slot_17"]             = "Off Hand"
L["multicast_slot_18"]             = "Ranged"
L["multicast_slot_19"]             = "Tabard"
L["multicast_slot_trinket1"]       = "Trinket 1"
L["multicast_slot_trinket2"]       = "Trinket 2"
L["multicast_slot_mainhand"]       = "Main Hand"
L["multicast_slot_offhand"]        = "Off Hand"
L["multicast_slot_fmt"]            = "Equip slot %d"
L["multicast_badge_order_heading"] = "Badge corner order (multi-cast extras)"
L["multicast_badge_order_help"]    =
    "Corner badges follow the Multi-cast cast order (first 3 available). Reorder there by dragging."
L["Remove"]                        = "Remove"

-- Targets tab section headings
L["targets_section_hovercast"]  = "Unit-frame hover (hovercast)"
L["targets_section_keypress"]   = "Key press targets"
L["targets_hovercast_help"]     = "Cast on the unit frame your cursor is over, without changing your target."
L["targets_keypress_help"]      = "When you press the key, try each target in order until one matches."

-- Conditions tab
L["conditions_help"] = "Only fire this binding when the conditions below are met. These become [conditional] clauses in the generated macro."
L["condition_form_heading"]          = "Form / Stance"
L["condition_form_help"]             =
    "Per-form icons above still choose which sub-profile macro is active. Rows here add extra form/stance checks inside this form's generated macro. Multiple enabled conditions are combined with AND in each bracket."

-- Editor header
L["editor_intro_hint"] = "Set a key, pick a form below, then configure Cast, Conditions, and Targets."
L["editor_pending_title"] = "Flux binding editor"
L["editor_drop_hint"] = "Drag spell, item, & etc. here."
L["spellbook_binding_editor_btn"] = "Binding editor…"
L["spellbook_binding_editor_tip"] = "Open the Flux binding editor. Drag spells, items, mounts, pets, or macros into the window."
L["spellbook_right_click_binding_tip"] = "Right-click to open in Flux Binding."

-- Clicked Targets parity
L["Global"]                          = "Global"
L["<No one>"]                        = "<No one>"

-- Action tab — short labels (tooltips use existing long strings)
L["action_lbl_interrupt"]            = "Interrupt"
L["action_lbl_auto_attack"]          = "Auto attack"
L["action_lbl_pet_attack"]           = "Pet attack"
L["action_lbl_override_queue"]       = "Override queue"
L["action_lbl_cancel_form"]          = "Cancel form"
L["action_lbl_cancel_aura"]          = "Cancel aura"
L["action_lbl_target_on_cast"]       = "Target on cast"
L["action_lbl_cast_at_cursor"]       = "Cast @cursor"
L["action_lbl_prevent_toggle"]       = "Prevent toggle"
L["action_lbl_subtext"]              = "Spell subtext"
L["action_lbl_spell_id"]             = "spell:id macro"
L["action_lbl_clear_cursor"]         = "Clear blue cursor"
L["action_lbl_rank_sync"]            = "Spell ranks"

-- Status tab
L["status_selected_form_heading"]    = "Selected form: %s"
--- Looks up a string by Clicked locale key. Falls back to the key itself
--- (Clicked uses the same fall-through; new keys are auto-readable).
local function Lookup(key)
    return L[key] or key
end

_G.FluxSpellBindingLocale = setmetatable({}, {
    __index = function(_, k) return Lookup(k) end,
    __newindex = function() end,
})
