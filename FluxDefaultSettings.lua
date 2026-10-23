FluxDefaultSettings = FluxDefaultSettings or {}

-- Keybindings UI category title (Bindings.xml uses category="BINDING_HEADER_AAA_FLUXUI")
BINDING_HEADER_AAA_FLUXUI = "FluxUI"

-- Keybindings UI row labels (_G["BINDING_NAME_" .. bindingName] — see Bindings.xml)
BINDING_NAME_FLUXRELOADUI = "Reload UI"
BINDING_NAME_FLUXGRIDSMARTMOUNT = "Smart mount"
BINDING_NAME_FLUXGRIDHEARTH = "Use hearthstone"
BINDING_NAME_FLUXGRIDVENDORMOUNT = "Vendor mount"
BINDING_NAME_FLUXGRID_FOOD_OR_RECUP = "Food or Recuperate"
BINDING_NAME_FLUXGRID_WATER_OR_COMBINED = "Water or combined drink"
BINDING_NAME_FLUXCOMBAT_HEALPOT = "Healing potion"
BINDING_NAME_FLUXCOMBAT_BANDAGE = "Bandage"
BINDING_NAME_FLUXCOMBAT_HEALTHSTONE = "Healthstone"
BINDING_NAME_FLUXCOMBAT_MANAPOT = "Mana potion"
BINDING_NAME_FLUXCOMBAT_MANAGEM = "Mana gem"
BINDING_NAME_FLUX_ASSISTED_COMBAT = "Single-Button Assistant"
BINDING_NAME_FLUXCLASS_TELEPORT = "Class teleport"
BINDING_NAME_FLUXMAGE_TOGGLE_TPPT = "Toggle Teleport / Portal"
BINDING_NAME_FLUXMAGE_CONJURE_FOOD = "Conjure food"
BINDING_NAME_FLUXMAGE_CONJURE_WATER = "Conjure water"
BINDING_NAME_FLUXMAGE_RITUAL_OF_REFRESHMENT = "Ritual of Refreshment"
BINDING_NAME_FLUXMAGE_CONJURE_MANAGEM = "Conjure mana gem"
BINDING_NAME_FLUXGRID_CONSUMABLES = "Consumables"

-- FLUXMAGE_CONJURE_MANAGEM is shared: Mage conjure mana gem (right-click) OR Warlock Create Healthstone (right-click).
-- FLUXMAGE_CONJURE_FOOD / WATER labels follow the preferred conjure spell (Food/Water vs Refreshment).
function FluxDefaultSettings.RefreshConjureSharedBindingName()
    local mg = _G.FluxCombatManaGem
    local hs = _G.FluxCombatHealthstone
    if mg and mg.KnowsAnyConjureSpell and mg.KnowsAnyConjureSpell() then
        _G["BINDING_NAME_FLUXMAGE_CONJURE_MANAGEM"] = "Conjure mana gem"
    elseif hs and hs.CanCreateHealthstone and hs.CanCreateHealthstone() then
        _G["BINDING_NAME_FLUXMAGE_CONJURE_MANAGEM"] = "Create Healthstone"
    else
        _G["BINDING_NAME_FLUXMAGE_CONJURE_MANAGEM"] = "Conjure mana gem / Create Healthstone"
    end

    local Bridge = _G.FluxEBSConsumableBridge
    local foodSpell = Bridge and Bridge.GetFoodConjureSpell and Bridge.GetFoodConjureSpell()
    local waterSpell = Bridge and Bridge.GetWaterConjureSpell and Bridge.GetWaterConjureSpell()
    if foodSpell and foodSpell ~= "" then
        _G["BINDING_NAME_FLUXMAGE_CONJURE_FOOD"] = foodSpell
    else
        _G["BINDING_NAME_FLUXMAGE_CONJURE_FOOD"] = "Conjure food"
    end
    if waterSpell and waterSpell ~= "" then
        _G["BINDING_NAME_FLUXMAGE_CONJURE_WATER"] = waterSpell
    else
        _G["BINDING_NAME_FLUXMAGE_CONJURE_WATER"] = "Conjure water"
    end
end

local _conjureNameSync = CreateFrame("Frame")
_conjureNameSync:RegisterEvent("PLAYER_LOGIN")
_conjureNameSync:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
_conjureNameSync:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
_conjureNameSync:RegisterEvent("UPDATE_BINDINGS")
_conjureNameSync:SetScript("OnEvent", function(_, event)
    if event == "UPDATE_BINDINGS"
        and FluxDefaultSettings.ShouldSuppressBindingRefresh
        and FluxDefaultSettings.ShouldSuppressBindingRefresh() then
        return
    end
    if FluxDefaultSettings.RefreshConjureSharedBindingName then
        FluxDefaultSettings.RefreshConjureSharedBindingName()
    end
end)
do
    local SpellBook = _G.Flux and _G.Flux.SpellBook
    if SpellBook and SpellBook.OnChanged then
        SpellBook.OnChanged("defaultsettings.conjurebind", function()
            if FluxDefaultSettings.RefreshConjureSharedBindingName then
                FluxDefaultSettings.RefreshConjureSharedBindingName()
            end
        end)
    else
        _conjureNameSync:RegisterEvent("SPELLS_CHANGED")
    end
end
BINDING_NAME_FLUXSPELLBOOKSLOT1 = "Utility slot 1"
BINDING_NAME_FLUXSPELLBOOKSLOT2 = "Utility slot 2"
BINDING_NAME_FLUXSPELLBOOKSLOT3 = "Utility slot 3"
BINDING_NAME_FLUXSPELLBOOKSLOT4 = "Utility slot 4"
BINDING_NAME_FLUXTRINKET1 = "Trinket (top)"
BINDING_NAME_FLUXTRINKET2 = "Trinket (bottom)"

-- Minimum UI scale used by GetOptimalUIScale and horizontal squeeze (single source of truth)
FluxDefaultSettings.MIN_UI_SCALE = 0.75

-- State Enum
FluxDefaultSettings.State = {
    FRESH = "FRESH",       -- All tracked CVars match default values
    MODIFIED = "MODIFIED"  -- At least one CVar differs from default
}

-- ---------------------------------------------------------------------------
-- COMBAT LOCKING SYSTEM
-- ---------------------------------------------------------------------------
-- This file only changes game settings automatically.
-- All functions that call protected APIs check combat status first.

-- ---------------------------------------------------------------------------
-- 1)  KEY‑TEMPLATE TABLE  (key  =>  command as understood by SetBinding)
-- ---------------------------------------------------------------------------
local DefaultKeyTemplate = {
    -- Movement --------------------------------------------------------------
    ["W"]             = "MOVEFORWARD",
    ["S"]             = "MOVEBACKWARD",
    ["A"]             = "STRAFELEFT",
    ["D"]             = "STRAFERIGHT",
    ["SPACE"]         = "JUMP",
    ["-"]             = "SITORSTAND",
    ["'"]             = "TOGGLEAUTORUN",
    ["+"]             = "TOGGLERUN",
    -- Interface / panels ----------------------------------------------------
    ["ESCAPE"]        = "TOGGLEGAMEMENU",
    ["B"]             = "OPENALLBAGS",
    ["0"]             = "TOGGLECHARACTER0",   -- character pane
    ["H"]             = "TOGGLECHARACTER4",   -- PvP
    ["P"]             = "TOGGLESPELLBOOK",
    ["SHIFT-P"]       = "TOGGLEPETBOOK",
    ["N"]             = "TOGGLETALENTS",   -- talents
    ["L"]             = "TOGGLEQUESTLOG",
    ["J"]             = "TOGGLEGUILDTAB",
    ["M"]             = "TOGGLEWORLDMAP",
    -- Action bar ------------------------------------------------------------
    ["1"]             = "ACTIONBUTTON1",
    ["2"]             = "ACTIONBUTTON2",
    ["3"]             = "ACTIONBUTTON3",
    ["4"]             = "ACTIONBUTTON4",
    ["5"]             = "ACTIONBUTTON5",
    ["½"]             = "ACTIONBUTTON6",
    ["Q"]             = "ACTIONBUTTON7",
    ["E"]             = "ACTIONBUTTON8",
    ["R"]             = "ACTIONBUTTON9",
    ["T"]             = "ACTIONBUTTON10",
    ["F"]             = "ACTIONBUTTON11",
    ["G"]             = "ACTIONBUTTON12",
    -- Multi Action Bars -----------------------------------------------------
    ["BUTTON5"]       = "MULTIACTIONBAR2BUTTON8",
    ["BUTTON4"]       = "MULTIACTIONBAR2BUTTON9",
    ["BUTTON3"]       = "MULTIACTIONBAR2BUTTON10",
    ["<"]             = "MULTIACTIONBAR2BUTTON11",
    ["Z"]             = "MULTIACTIONBAR2BUTTON12",
    ["X"]             = "MULTIACTIONBAR4BUTTON8",
    ["C"]             = "MULTIACTIONBAR4BUTTON9",
    -- Targeting & nameplates -----------------------------------------------
    ["TAB"]           = "TARGETNEARESTENEMY",
    ["SHIFT-TAB"]     = "TARGETPREVIOUSENEMY",
    ["CTRL-TAB"]      = "TARGETNEARESTFRIEND",
    ["CTRL-SHIFT-TAB"]= "TARGETPREVIOUSFRIEND",
    ["SHIFT-V"]       = "INTERACTTARGET",
    -- Camera ----------------------------------------------------------------
    ["MOUSEWHEELUP"]   = "CAMERAZOOMIN",
    ["MOUSEWHEELDOWN"] = "CAMERAZOOMOUT",
    -- Chat / misc -----------------------------------------------------------
    ["ENTER"]         = "OPENCHAT",
    ["PRINTSCREEN"]   = "SCREENSHOT",
    -- Ping System -----------------------------------------------------------
    ["V"]             = "TOGGLEPINGLISTENER",
    -- Nameplate Toggles -----------------------------------------------------
    ["F6"]            = "NAMEPLATES",
    ["SHIFT-F6"]      = "FRIENDNAMEPLATES",
    ["CTRL-F6"]       = "ALLNAMEPLATES",
    -- Stance Bar (Special Action Bar) ---------------------------------------
    ["F1"]            = "SHAPESHIFTBUTTON1",
    ["F2"]            = "SHAPESHIFTBUTTON2",
    ["F3"]            = "SHAPESHIFTBUTTON3",
    ["F4"]            = "SHAPESHIFTBUTTON4",
    ["SHIFT-F1"]      = "SHAPESHIFTBUTTON5",
    ["SHIFT-F2"]      = "SHAPESHIFTBUTTON6",
    ["SHIFT-F3"]      = "SHAPESHIFTBUTTON7",
    ["SHIFT-F4"]      = "SHAPESHIFTBUTTON8",
    -- FluxUI Custom Bindings ------------------------------------------------
    ["F5"]            = "FLUXRELOADUI",
    ["Y"]            = "FLUXGRIDSMARTMOUNT",
    ["7"]            = "FLUXGRIDHEARTH",
    ["6"]            = "FLUXGRIDVENDORMOUNT",
    ["I"]            = "FLUXSPELLBOOKSLOT2",
    ["U"]            = "FLUXSPELLBOOKSLOT1",
    ["O"]            = "TOGGLESOCIAL",
    ["F7"]            = "FLUXSPELLBOOKSLOT3",
    ["F8"]            = "FLUXSPELLBOOKSLOT4",
    ["ALT-D"]        = "FLUXGRID_FOOD_OR_RECUP",
    ["ALT-A"]            = "FLUXGRID_WATER_OR_COMBINED",
    ["K"]            = "FLUXGRID_CONSUMABLES",
    ["ALT-E"]            = "FLUXCOMBAT_HEALPOT",
    ["ALT-S"]            = "FLUXCOMBAT_BANDAGE",
    ["ALT-Z"]            = "FLUXCOMBAT_HEALTHSTONE",
    ["ALT-Q"]            = "FLUXCOMBAT_MANAPOT",
    ["ALT-C"]            = "FLUXCOMBAT_MANAGEM",
    ["8"]            = "FLUXCLASS_TELEPORT",
    ["9"]            = "FLUXMAGE_TOGGLE_TPPT",
    ["F10"]           = "FLUXMAGE_CONJURE_MANAGEM",
    ["F11"]           = "FLUXMAGE_CONJURE_FOOD",
    ["F12"]           = "FLUXMAGE_CONJURE_WATER",
    ["SHIFT-F11"]     = "FLUXMAGE_RITUAL_OF_REFRESHMENT",
    ["ALT-MOUSEWHEELUP"]   = "FLUXTRINKET1",
    ["ALT-MOUSEWHEELDOWN"] = "FLUXTRINKET2",
}

-- Comprehensive Default Values for FluxUI (Imported from Legacy)
local FLUX_DEFAULTS = {
    -- Controls
    ["autoClearAFK"] = "1",
    ["interactOnLeftClick"] = "0",
    ["lootUnderMouse"] = "1",
    ["autoLootDefault"] = "1",
    ["autoLootKey"] = "3",
    -- Retail Settings: PROXY_ENABLE_INTERACT mirrors softTargetInteract (Enum.SoftTargetEnableFlags.Any = 3)
    ["softTargetInteract"] = "3",
    ["softTargettingInteractKeySound"] = "0",
    ["stickyTargeting"] = "0",
    ["combinedBags"] = "1",
    -- Blizzard mouseover cast stays off. Flux's own mouseover does not turn this CVar on.
    ["enableMouseoverCast"] = "0",
    
    -- Mouse
    ["ClipCursor"] = "0",
    ["mouseInvertPitch"] = "0",
    ["mouseLookSpeed"] = "5.5",
    ["enableMouseSpeed"] = "0",
    ["autointeract"] = "0",
    
    -- Camera
    ["cameraWaterCollision"] = "0",
    ["cameraFollowSpeed"] = "5.5",
    ["cameraSmoothStyle"] = "0",
    -- cameraDistanceMaxZoomFactor resolved per-client at apply time (GetMaxCameraDistanceZoomFactor).
    ["cameraDistanceMaxZoomFactor"] = "2.6",
    ["cameraTerrainTilt"] = "0",
    ["cameraBobbing"] = "0",
    ["cameraPivot"] = "1",
    
    -- Interface / Names (PROXY_NPC_NAMES = All → UnitNameNPC=1 + clear special flags)
    ["unitNameOwn"] = "0",
    ["UnitNameNPC"] = "1", -- All NPCs
    ["UnitNameFriendlySpecialNPCName"] = "0",
    ["UnitNameHostleNPC"] = "0", -- Blizzard typo: Hostle
    ["UnitNameInteractiveNPC"] = "0",
    ["ShowQuestUnitCircles"] = "1",
    ["UnitNameNonCombatCreatureName"] = "1", -- Critters and Companions
    ["UnitNameFriendlyPlayerName"] = "1",
    ["UnitNameFriendlyMinionName"] = "1",
    ["UnitNameEnemyPlayerName"] = "1",
    ["UnitNameEnemyMinionName"] = "1",

    -- Nameplates (ApplyNameplateDefaultsPack on every client — scalars here are
    -- mirrored; pack is the write path. Forever / Live use raw C_CVar and skip
    -- Settings.NotifyUpdate so the preview does not re-enter RefreshAuras.)
    ["nameplateShowAll"] = "1",
    ["nameplateShowEnemies"] = "1",
    ["nameplateShowEnemyMinions"] = "1",
    ["nameplateShowEnemyMinus"] = "1",
    ["nameplateShowOffscreen"] = "1",
    ["nameplateShowFriendlyPlayers"] = "0",
    ["nameplateShowSelf"] = "0", -- Personal resource display off
    ["nameplateSize"] = "3", -- Enum.NamePlateSize.Large
    ["nameplateAuraScale"] = "1.2", -- 120%
    ["nameplateStyle"] = "2", -- Enum.NamePlateStyle.Block (Blocky bars / Forever Block)
    ["nameplateShowClassColor"] = "1", -- enemy players
    ["nameplateShowFriendlyClassColor"] = "0",

    -- Display
    ["showTutorials"] = "0",
    ["statusTextDisplay"] = "BOTH",
    ["chatBubblesParty"] = "1",
    ["displayHelm"] = "1",
    ["displayCloak"] = "1",
    ["instantQuestText"] = "1",
    ["autoQuestWatch"] = "1",
    ["displayFreeBagSlots"] = "1",
    ["consolidateBuffs"] = "0",
    ["hideOutdoorWorldState"] = "0",
    ["rotateMinimap"] = "0",
    ["showMinimapClock"] = "1",
    ["showDetailedTooltips"] = "1",
    ["threatShowNumeric"] = "1",
    ["threatWarning"] = "3",
    -- Unit-frame enemy cast bar on Era, Anniversary, Forever, and Live.
    -- showEnemyCastbar is written only when that CVar exists.
    ["showTargetCastbar"] = "1",
    ["showEnemyCastbar"] = "1",
    -- Forever Edit Mode "Show Swing Timer". Missing on live/Era/Anniversary is a no-op.
    -- Keep Blizzard's SwingTimer* HUD off so only the Flux cast-bar overlay shows.
    ["showSwingTimer"] = "0",
    ["ShowDynamicBuffSize"] = "1",
    ["alwaysShowRuneIcons"] = "0",
    ["UseClassicGuildUI"] = "0",
    ["UberTooltips"] = "1",
    
    -- Default unit frames (player / target / focus): show incoming heals on health bars
    -- Classic Anniversary: InterfaceOverrides + UnitFrame.lua (CVarCallbackRegistry unitFramesDisplayIncomingHeals)
    -- Other clients: no-op if CVar missing (e.g. some Classic Era builds)
    ["unitFramesDisplayIncomingHeals"] = "1",
    
    -- Raid Frames
    ["useCompactPartyFrames"] = "1",
    ["raidFramesDisplayPowerBars"] = "1",
    ["raidFramesDisplayClassColor"] = "1",
    ["raidFramesHealthText"] = "perc",
    ["raidFramesDisplayIncomingHeals"] = "1",
    ["raidFramesDisplayDebuffs"] = "1",
    ["raidFramesDisplayBuffs"] = "1",
    ["raidFramesDisplayOnlyDispellableDebuffs"] = "1",
    ["raidFramesFadeOutOfRange"] = "1",
    ["raidFramesDisplayInOtherPhase"] = "1",
    ["raidOptionDisplayMainTankAndAssist"] = "1",
    ["raidOptionDisplayPets"] = "0",
    ["raidFramesDisplayOnlyHealerPowerBars"] = "0",
    ["raidFramesDisplayAggroHighlight"] = "1",
    ["raidFramesDisplayLargerRoleSpecificDebuffs"] = "1",
    ["raidFramesCenterBigDefensive"] = "1",
    ["pvpFramesDisplayPowerBars"] = "1",
    ["pvpFramesDisplayClassColor"] = "1",
    ["pvpFramesHealthText"] = "perc",
    ["pvpFramesDisplayOnlyHealerPowerBars"] = "0",
    ["pvpOptionDisplayPets"] = "0",
    
    -- Action Bars
    ["alwaysShowActionBars"] = "1", -- empty slots still show keybind numbers
    ["lockActionBars"] = "0", -- User requested disabled
    ["countdownForCooldowns"] = "1", -- Show Numbers for Cooldowns
    ["enableMultiActionBars"] = "0",
    ["multiBarLeft"] = "0",
    ["multiBarRight"] = "0",
    ["multiBarBottomLeft"] = "0",
    ["multiBarBottomRight"] = "0",
    ["ActionButtonUseKeyDown"] = "1", -- Cast on key press (STANDARD)
    
    -- Combat
    ["raidSelfHighlight"] = "0",
    ["showTargetOfTarget"] = "1",
    ["doNotFlashLowHealthWarning"] = "0",
    ["autoSelfCast"] = "1", -- Self Cast = Auto (no modifier key)
    ["occludedSilhouettePlayer"] = "1", -- Show silhouette when obscured
    ["assistedCombatHighlight"] = "0",
    ["cooldownViewerEnabled"] = "0",
    ["empowerTapControls"] = "1", -- Empowered spell input: Press and Tap (0=hold, 1=tap)
    -- Enable Action Targeting (Combat): PROXY_ACTION_TARGETING; off = Gamepad (1), on = Any (3) — Blizzard Combat.lua
    ["softTargetEnemy"] = "1",
    
    -- Social
    ["profanityFilter"] = "0",
    ["guildMemberNotify"] = "1",
    ["blockTrades"] = "0",
    ["restrictCalendarInvites"] = "0",
    ["blockChannelInvites"] = "1",
    ["showToastOnline"] = "1",
    ["showToastOffline"] = "1",
    ["showToastBroadcast"] = "0",
    ["showToastFriendRequest"] = "1",
    ["showToastWindow"] = "0",
    ["chatStyle"] = "classic",
    ["whisperMode"] = "inline",
    ["showTimestamps"] = "none",
    
    -- Graphics / Scale
    ["useUIScale"] = "1",
    -- uiscale is calculated dynamically
    
    -- Floating Combat Text (retail uses *_v2 CVars since Jan 2026)
    ["enableFloatingCombatText"] = "0",
    ["floatingCombatTextCombatDamage_v2"] = "1",
    ["floatingCombatTextCombatLogPeriodicSpells_v2"] = "1",
    ["floatingCombatTextPetMeleeDamage_v2"] = "1",
    ["floatingCombatTextCombatHealing_v2"] = "1", -- Show Healing (world floating heal numbers)
}


-- Critical CVars to track for determining if the game is "fresh"
-- A subset of the defaults
local CRITICAL_CVARS = {
    "uiScale",
    "useUiScale",
    "Sound_EnableAllSound",
    "autoLootDefault",
    "alwaysShowActionBars",
    "statusTextDisplay",
    "showTutorials"
}

-- Calculate optimal UI scale
-- Legacy Method (Aspect Ratio Based from NewDefaultUISettings.lua)
-- Keeps visual proportions consistent across different monitor shapes (Ultrawide vs 16:9)
local function GetOptimalUIScale()
    local width, height = 0, 0
    
    -- Try GetPhysicalScreenSize first (Modern APIs)
    if GetPhysicalScreenSize then
        width, height = GetPhysicalScreenSize()
    end
    
    -- Fallback: Parse gxResolution CVar
    if not width or width == 0 then
        local resolution = GetCVar("gxResolution")
        if resolution then
            width, height = resolution:match("(%d+)x(%d+)")
            width = tonumber(width)
            height = tonumber(height)
        end
    end
    
    -- Fallback: Default to 1920x1080
    if not width or width == 0 then
        width = 1920
        height = 1080
    end
    
    -- Calculate Aspect Ratio
    local aspectRatio = width / height
    
    -- Base logic from NewDefaultUISettings.lua
    -- Base scale for 1.90 ratio is 0.8
    -- For 1.78 ratio (16:9), strictly adjusting to match visual appearance
    local baseRatio = 1.90
    local baseScale = 0.75
    
    -- Adjust scale based on ratio difference
    -- Multiplier 0.442 gives us 0.80 -> 0.747 for 1.90 -> 1.78 ratio change
    local scaleAdjustment = (baseRatio - aspectRatio) * 0.442
    local optimalScale = baseScale - scaleAdjustment
    
    -- Clamp the scale between reasonable bounds
    optimalScale = math.max(FluxDefaultSettings.MIN_UI_SCALE, math.min(1.0, optimalScale))

    return string.format("%.2f", optimalScale)
end

function FluxDefaultSettings.GetMinUIScale()
    return FluxDefaultSettings.MIN_UI_SCALE
end

--- True when custom UI scaling is enabled and uiScale is at or below the configured minimum (e.g. 0.7).
function FluxDefaultSettings.IsUIScaleAtOrBelowMin()
    if not GetCVar then return false end
    local use = GetCVar("useUIScale")
    if use == "0" then return false end
    local s = tonumber(GetCVar("uiScale"))
    if not s or s ~= s then return false end
    return s <= FluxDefaultSettings.MIN_UI_SCALE + 0.001
end

-- Shared horizontal squeeze for action bar + trinket + grids when at min UI scale and window overlap.
FluxUILayoutSqueeze = FluxUILayoutSqueeze or {}

local SLACK_PIXELS = 2
local MIN_HORIZONTAL_X_FACTOR = 0.4

--- Last factor applied by FluxActionBar (1 = no squeeze). Read by grids/trinket for matching width.
FluxUILayoutSqueeze._lastXFactor = 1

function FluxUILayoutSqueeze.SetLastHorizontalSqueezeFactor(f)
    if type(f) ~= "number" or f ~= f or f <= 0 then
        FluxUILayoutSqueeze._lastXFactor = 1
    elseif f >= 0.999 then
        FluxUILayoutSqueeze._lastXFactor = 1
    else
        FluxUILayoutSqueeze._lastXFactor = math.max(MIN_HORIZONTAL_X_FACTOR, math.min(1, f))
    end
end

function FluxUILayoutSqueeze.GetHorizontalSqueezeFactor()
    if not FluxDefaultSettings.IsUIScaleAtOrBelowMin() then return 1 end
    local f = FluxUILayoutSqueeze._lastXFactor
    if type(f) ~= "number" or f ~= f or f <= 0 then return 1 end
    return math.max(MIN_HORIZONTAL_X_FACTOR, math.min(1, f))
end

--- Same X multiplier as FluxMainActionBar action buttons (after bar layout). Grids/trinket should use this so they stay in sync at MIN_UI_SCALE + overlap squeeze.
function FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor()
    return FluxUILayoutSqueeze.GetHorizontalSqueezeFactor()
end

--- Kept at 1 so grids / trinket / flyout arrows match FluxMainActionBar width (no extra 0.94 tightening).
FluxUILayoutSqueeze.DEPENDENTS_EXTRA_X_FACTOR = 1

function FluxUILayoutSqueeze.GetDependentsHorizontalSqueezeFactor()
    return FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor()
end

--- Width/height of a laid-out widget (or its SlotFrame) as an X factor. Hotkeys and flyout kids use this.
function FluxUILayoutSqueeze.GetWidgetHorizontalSqueezeFactor(widget, native)
    if not widget then
        return 1
    end
    local frame = widget
    local parent = widget.GetParent and widget:GetParent()
    if parent and parent.GetWidth and parent.GetHeight then
        local pw, ph = parent:GetWidth(), parent:GetHeight()
        if type(pw) == "number" and type(ph) == "number" and ph > 0 and pw == pw and ph == ph then
            local pAspect = pw / ph
            local ww = widget.GetWidth and widget:GetWidth()
            local wh = widget.GetHeight and widget:GetHeight()
            local wAspect = (type(ww) == "number" and type(wh) == "number" and wh > 0) and (ww / wh) or 1
            if math.abs(pAspect - 1) > 0.01 and math.abs((wAspect or 1) - 1) < 0.01 then
                frame = parent
            end
        end
    end
    native = native or (frame.GetHeight and frame:GetHeight()) or 44
    if type(native) ~= "number" or native <= 0 or native ~= native then
        native = 44
    end
    local w = frame.GetWidth and frame:GetWidth()
    if type(w) ~= "number" or w ~= w or w <= 0 then
        return 1
    end
    local f = w / native
    if f ~= f or f <= 0 then
        return 1
    end
    return math.max(MIN_HORIZONTAL_X_FACTOR, math.min(1, f))
end

--- Returns targetRightX (optional alignment axis), barRightMax (max allowed right edge of FluxMainActionBar) or nil.
function FluxUILayoutSqueeze.GetDynamicScaleTargets()
    local windowFrame = FluxWindowFrame and FluxWindowFrame.GetFrame and FluxWindowFrame:GetFrame()
    local trinketFrame = FluxTrinketMenu and FluxTrinketMenu.Frame

    local targetRightX = nil
    local barRightMax = nil

    if windowFrame and windowFrame:IsShown() then
        local left = windowFrame:GetLeft()
        if left then
            targetRightX = left - 6
        end
    end
    if not targetRightX and trinketFrame and trinketFrame:IsShown() then
        local right = trinketFrame:GetRight()
        if right then
            targetRightX = right
        end
    end

    local MAP_TRINKET_CLEARANCE = -6
    local BAR_WINDOW_CLEARANCE = -6
    if windowFrame and windowFrame:IsShown() then
        local windowLeft = windowFrame:GetLeft()
        if windowLeft then
            local boundaryLeft = windowLeft
            if FluxBattlefieldMap and FluxBattlefieldMap.IsActive and FluxBattlefieldMap:IsActive()
                and FluxBattlefieldMap.GetMapFrame then
                local mapFrame = FluxBattlefieldMap:GetMapFrame()
                if mapFrame and mapFrame:IsShown() then
                    local mapLeft = mapFrame:GetLeft()
                    if type(mapLeft) == "number" and mapLeft == mapLeft then
                        boundaryLeft = math.max(windowLeft, mapLeft)
                    end
                end
            end
            if trinketFrame and trinketFrame:IsShown() then
                local trinketWidth
                local trL, trR = trinketFrame:GetLeft(), trinketFrame:GetRight()
                local trW
                if type(trL) == "number" and type(trR) == "number" and trL == trL and trR == trR then
                    trW = trR - trL
                end
                if not (type(trW) == "number" and trW > 0 and trW == trW) and trinketFrame.GetWidth then
                    local tw = trinketFrame:GetWidth()
                    if type(tw) == "number" and tw > 0 and tw == tw then
                        trW = tw
                    end
                end
                if type(trW) == "number" and trW > 0 and trW == trW then
                    trinketWidth = trW
                else
                    local slotSize = (FluxTrinketMenu.DEFAULT_BUTTON_SIZE or 45) * (FluxTrinketMenu.BUTTON_SLOT_SIZE_MULTIPLIER or 1.2)
                    trinketWidth = slotSize * (FluxTrinketMenu.DEFAULT_SCALE or (1 / 1.265))
                end
                barRightMax = boundaryLeft + 2 - trinketWidth - MAP_TRINKET_CLEARANCE
            else
                barRightMax = boundaryLeft - BAR_WINDOW_CLEARANCE
            end
        end
    end

    return targetRightX, barRightMax
end

--- Like GetDynamicScaleTargets but always reserves trinket column width for barRightMax when FluxWindowFrame is shown,
--- so squeeze math matches "full row + trinket" even if the trinket frame is hidden or not yet laid out.
function FluxUILayoutSqueeze.GetDynamicScaleTargetsEmulated()
    local windowFrame = FluxWindowFrame and FluxWindowFrame.GetFrame and FluxWindowFrame:GetFrame()
    local trinketFrame = FluxTrinketMenu and FluxTrinketMenu.Frame

    local targetRightX = nil
    local barRightMax = nil

    if windowFrame and windowFrame:IsShown() then
        local left = windowFrame:GetLeft()
        if left then
            targetRightX = left - 6
        end
    end
    if not targetRightX and trinketFrame and trinketFrame:IsShown() then
        local right = trinketFrame:GetRight()
        if right then
            targetRightX = right
        end
    end

    local MAP_TRINKET_CLEARANCE = -6
    if windowFrame and windowFrame:IsShown() then
        local windowLeft = windowFrame:GetLeft()
        if windowLeft then
            local boundaryLeft = windowLeft
            if FluxBattlefieldMap and FluxBattlefieldMap.IsActive and FluxBattlefieldMap:IsActive()
                and FluxBattlefieldMap.GetMapFrame then
                local mapFrame = FluxBattlefieldMap:GetMapFrame()
                if mapFrame and mapFrame:IsShown() then
                    local mapLeft = mapFrame:GetLeft()
                    if type(mapLeft) == "number" and mapLeft == mapLeft then
                        boundaryLeft = math.max(windowLeft, mapLeft)
                    end
                end
            end
            local trinketWidth
            if trinketFrame then
                local trL, trR = trinketFrame:GetLeft(), trinketFrame:GetRight()
                local trW
                if type(trL) == "number" and type(trR) == "number" and trL == trL and trR == trR then
                    trW = trR - trL
                end
                if not (type(trW) == "number" and trW > 0 and trW == trW) and trinketFrame.GetWidth then
                    local tw = trinketFrame:GetWidth()
                    if type(tw) == "number" and tw > 0 and tw == tw then
                        trW = tw
                    end
                end
                if type(trW) == "number" and trW > 0 and trW == trW then
                    trinketWidth = trW
                end
            end
            if not trinketWidth then
                local slotSize = (FluxTrinketMenu and FluxTrinketMenu.DEFAULT_BUTTON_SIZE or 45)
                    * (FluxTrinketMenu and FluxTrinketMenu.BUTTON_SLOT_SIZE_MULTIPLIER or 1.2)
                trinketWidth = slotSize * (FluxTrinketMenu and FluxTrinketMenu.DEFAULT_SCALE or (1 / 1.265))
            end
            barRightMax = boundaryLeft + 2 - trinketWidth - MAP_TRINKET_CLEARANCE
        end
    end

    return targetRightX, barRightMax
end

--- Trinket-style dependent X factor from an explicit bar squeeze factor (does not read _lastXFactor).
function FluxUILayoutSqueeze.GetDependentsHorizontalSqueezeFactorFromBarX(barXFactor)
    if not FluxDefaultSettings.IsUIScaleAtOrBelowMin() then return 1 end
    local f = barXFactor
    if type(f) ~= "number" or f ~= f or f <= 0 then return 1 end
    f = math.max(MIN_HORIZONTAL_X_FACTOR, math.min(1, f))
    if f >= 0.999 then return 1 end
    return f
end

--- Boundaries for unit-frame X squeeze only: Flux window / battlefield map + **constant** emulated trinket width.
--- Does not read FluxMainActionBar, live TrinketMenu frame size/position, or action-bar button visibility.
function FluxUILayoutSqueeze.GetUnitFrameIndependentScaleTargets()
    local windowFrame = FluxWindowFrame and FluxWindowFrame.GetFrame and FluxWindowFrame:GetFrame()

    local targetRightX = nil
    local barRightMax = nil

    local slotSize = (FluxTrinketMenu and FluxTrinketMenu.DEFAULT_BUTTON_SIZE or 45)
        * (FluxTrinketMenu and FluxTrinketMenu.BUTTON_SLOT_SIZE_MULTIPLIER or 1.2)
    local trinketWidth = slotSize * (FluxTrinketMenu and FluxTrinketMenu.DEFAULT_SCALE or (1 / 1.265))

    if windowFrame and windowFrame:IsShown() then
        local left = windowFrame:GetLeft()
        if left then
            targetRightX = left - 6
        end
        local windowLeft = windowFrame:GetLeft()
        if windowLeft then
            local boundaryLeft = windowLeft
            if FluxBattlefieldMap and FluxBattlefieldMap.IsActive and FluxBattlefieldMap:IsActive()
                and FluxBattlefieldMap.GetMapFrame then
                local mapFrame = FluxBattlefieldMap:GetMapFrame()
                if mapFrame and mapFrame:IsShown() then
                    local mapLeft = mapFrame:GetLeft()
                    if type(mapLeft) == "number" and mapLeft == mapLeft then
                        boundaryLeft = math.max(windowLeft, mapLeft)
                    end
                end
            end
            local MAP_TRINKET_CLEARANCE = -6
            barRightMax = boundaryLeft + 2 - trinketWidth - MAP_TRINKET_CLEARANCE
        end
    end

    if not barRightMax and UIParent and UIParent.GetRight then
        local ur = UIParent:GetRight()
        if type(ur) == "number" and ur == ur then
            barRightMax = ur - 16
        end
    end

    return targetRightX, barRightMax
end

--- Raw emulated bar X factor for unit-frame dependents (no DEPENDENTS_EXTRA_X_FACTOR / trinket tightening).
function FluxUILayoutSqueeze.ClampUnitFrameIndependentXSqueeze(barXFactor)
    if not FluxDefaultSettings.IsUIScaleAtOrBelowMin() then
        return 1
    end
    local f = barXFactor
    if type(f) ~= "number" or f ~= f or f <= 0 then
        return 1
    end
    f = math.max(MIN_HORIZONTAL_X_FACTOR, math.min(1, f))
    if f >= 0.999 then
        return 1
    end
    return f
end

-- Keep in sync with ActionBars/FluxActionBar.lua: BUTTON_SIZE, padding, FRAME_MARGIN, CONFIG.scale, 19 main buttons.
local EMULATED_MAIN_BAR_BUTTON_SIZE = 44
local EMULATED_MAIN_BAR_PADDING = 0
local EMULATED_MAIN_BAR_FRAME_MARGIN = 4
local EMULATED_MAIN_BAR_SCALE = 1.24
local EMULATED_MAIN_VISIBLE_COLUMNS = 19

--- Emulated 19-button horizontal squeeze for unit frames / pet bar / unit auras / minimap buff squeeze only.
--- Fully separate from live action bar layout, _lastXFactor, and NotifyLayoutDependents.
function FluxUILayoutSqueeze.ComputeEmulatedFullMainBarSqueezeFactors()
    if not FluxDefaultSettings.IsUIScaleAtOrBelowMin() then
        return 1
    end

    local visibleContentWidth = (EMULATED_MAIN_BAR_BUTTON_SIZE + EMULATED_MAIN_BAR_PADDING) * EMULATED_MAIN_VISIBLE_COLUMNS
        - EMULATED_MAIN_BAR_PADDING

    -- Horizontal origin: UIParent center only (never FluxMainActionBar).
    local centerX = nil
    if UIParent and UIParent.GetWidth then
        local uw = UIParent:GetWidth()
        if type(uw) == "number" and uw > 0 then
            local ul = UIParent:GetLeft()
            centerX = (type(ul) == "number" and ul or 0) + uw / 2
        end
    end
    if not centerX then
        return 1
    end

    local targetRightX, barRightMax = FluxUILayoutSqueeze.GetUnitFrameIndependentScaleTargets()

    local dynamicFactor = 1.0
    if centerX and targetRightX then
        local desiredWidth = 2 * (targetRightX - centerX)
        if barRightMax then
            local maxWidth = 2 * (barRightMax - centerX)
            desiredWidth = math.min(desiredWidth, maxWidth)
        end
        local baseWidth = visibleContentWidth * EMULATED_MAIN_BAR_SCALE + (EMULATED_MAIN_BAR_FRAME_MARGIN * 2)
        if baseWidth > 0 and desiredWidth > 0 then
            dynamicFactor = math.max(1.0, math.min(1.5, desiredWidth / baseWidth))
        end
    end

    local effectiveScale = EMULATED_MAIN_BAR_SCALE * dynamicFactor

    local barXFactor = FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactor(
        centerX,
        EMULATED_MAIN_VISIBLE_COLUMNS,
        EMULATED_MAIN_BAR_BUTTON_SIZE,
        EMULATED_MAIN_BAR_PADDING,
        effectiveScale,
        barRightMax,
        EMULATED_MAIN_BAR_FRAME_MARGIN
    )
    if not barXFactor then
        barXFactor = 1
    end

    return FluxUILayoutSqueeze.ClampUnitFrameIndependentXSqueeze(barXFactor)
end

--- Cache key for UI scale + resolution (invalidate on UI_SCALE_CHANGED / DISPLAY_SIZE_CHANGED / InvalidateEmulatedDependentCache).
function FluxUILayoutSqueeze.GetEmulatedDependentCacheKey()
    local ui = tostring(GetCVar("uiScale") or "")
    local sw = tonumber(GetScreenWidth()) or 0
    local sh = tonumber(GetScreenHeight()) or 0
    return ui .. "\0" .. tostring(sw) .. "\0" .. tostring(sh)
end

function FluxUILayoutSqueeze.InvalidateEmulatedDependentCache()
    FluxUILayoutSqueeze._emulatedDependentCacheKey = nil
    FluxUILayoutSqueeze._emulatedDependentCache = nil
end

--- Cached horizontal factor for unit-frame dependents (see ComputeEmulatedFullMainBarSqueezeFactors).
function FluxUILayoutSqueeze.GetCachedEmulatedDependentXFactorForUnitFrames()
    local key = FluxUILayoutSqueeze.GetEmulatedDependentCacheKey()
    local c = FluxUILayoutSqueeze._emulatedDependentCache
    if FluxUILayoutSqueeze._emulatedDependentCacheKey == key and type(c) == "number" and c == c and c > 0 then
        return c
    end
    local dep = FluxUILayoutSqueeze.ComputeEmulatedFullMainBarSqueezeFactors()
    if type(dep) ~= "number" or dep ~= dep or dep <= 0 then
        dep = 1
    end
    FluxUILayoutSqueeze._emulatedDependentCacheKey = key
    FluxUILayoutSqueeze._emulatedDependentCache = dep
    return dep
end

--- Same value as GetCachedEmulatedDependentXFactorForUnitFrames (emulated 19 columns; independent of action bars).
function FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames()
    local m = FluxUILayoutSqueeze.GetCachedEmulatedDependentXFactorForUnitFrames()
    if type(m) ~= "number" or m ~= m or m <= 0 then
        m = 1
    end
    return m
end

--- Solve for xFactor so (buttonSize*xFactor + padding)*visibleColumns - padding fits in maxInnerLogical space.
function FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactor(centerX, visibleColumns, buttonSize, padding, effectiveScale, barRightMax, frameMargin)
    if not FluxDefaultSettings.IsUIScaleAtOrBelowMin() then return nil end
    if not centerX or not barRightMax or not visibleColumns or visibleColumns < 1 then return nil end
    if not buttonSize or not effectiveScale or effectiveScale <= 0 then return nil end
    frameMargin = frameMargin or 4
    padding = padding or 0

    local maxTotalWidth = 2 * (barRightMax - centerX) - SLACK_PIXELS
    local maxInnerScaled = maxTotalWidth - 2 * frameMargin
    if maxInnerScaled <= 0 then return nil end
    local maxInnerLogical = maxInnerScaled / effectiveScale

    local visibleContentWidth = (buttonSize + padding) * visibleColumns - padding
    if visibleContentWidth <= maxInnerLogical + 0.5 then return nil end

    local denom = buttonSize * visibleColumns
    if denom <= 0 then return nil end
    local xFactor = (maxInnerLogical + padding - padding * visibleColumns) / denom
    xFactor = math.max(MIN_HORIZONTAL_X_FACTOR, math.min(1, xFactor))
    if xFactor >= 0.999 then return nil end
    return xFactor
end

function FluxUILayoutSqueeze.ComputeVisibleContentWidth(buttonSize, padding, visibleColumns, xFactor)
    xFactor = xFactor or 1
    return (buttonSize * xFactor + padding) * visibleColumns - padding
end

--- Same geometric cap as ComputeHorizontalSqueezeFactor but for an arbitrary row (grid/trinket):
--- content width = (slotWidth*x + spacing)*columnCount - spacing
function FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactorForRow(centerX, barRightMax, frameMargin, effectiveScale, columnCount, slotWidth, spacing)
    if not FluxDefaultSettings.IsUIScaleAtOrBelowMin() then return nil end
    if not centerX or not barRightMax or not columnCount or columnCount < 1 then return nil end
    if not slotWidth or not effectiveScale or effectiveScale <= 0 then return nil end
    frameMargin = frameMargin or 4
    spacing = spacing or 0

    local maxTotalWidth = 2 * (barRightMax - centerX) - SLACK_PIXELS
    local maxInnerScaled = maxTotalWidth - 2 * frameMargin
    if maxInnerScaled <= 0 then return nil end
    local maxInnerLogical = maxInnerScaled / effectiveScale

    local visibleContentWidth = (slotWidth + spacing) * columnCount - spacing
    if visibleContentWidth <= maxInnerLogical + 0.5 then return nil end

    local denom = slotWidth * columnCount
    if denom <= 0 then return nil end
    local xFactor = (maxInnerLogical + spacing - spacing * columnCount) / denom
    xFactor = math.max(MIN_HORIZONTAL_X_FACTOR, math.min(1, xFactor))
    if xFactor >= 0.999 then return nil end
    return xFactor
end

--- Use a frame's horizontal center and effective scale with GetDynamicScaleTargets() barRightMax.
function FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactorForFrame(frame, columnCount, slotWidth, spacing, frameMargin)
    if not frame or not frame.GetLeft or not frame.GetRight then return nil end
    local left, right = frame:GetLeft(), frame:GetRight()
    if not left or not right then return nil end
    local centerX = (left + right) / 2
    local _, barRightMax = FluxUILayoutSqueeze.GetDynamicScaleTargets()
    if not barRightMax then return nil end
    local effectiveScale = 1
    if frame.GetEffectiveScale then
        effectiveScale = frame:GetEffectiveScale() or 1
    elseif frame.GetScale then
        effectiveScale = frame:GetScale() or 1
    end
    return FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactorForRow(centerX, barRightMax, frameMargin, effectiveScale, columnCount, slotWidth, spacing)
end

function FluxUILayoutSqueeze.NotifyLayoutDependents()
    if InCombatLockdown and InCombatLockdown() then
        if _G.Flux and _G.Flux.Combat and _G.Flux.Combat.Defer then
            _G.Flux.Combat.Defer("layout.squeeze.dependents", FluxUILayoutSqueeze.NotifyLayoutDependents)
        end
        return
    end
    if FluxUILayoutSqueeze._notifyingDependents then
        return
    end
    FluxUILayoutSqueeze._notifyingDependents = true
    if FluxUILayoutSqueeze.InvalidateEmulatedDependentCache then
        FluxUILayoutSqueeze.InvalidateEmulatedDependentCache()
    end
    local Flux = _G.Flux
    if FluxTrinketMenu and FluxTrinketMenu.ApplyHorizontalSqueeze then
        pcall(FluxTrinketMenu.ApplyHorizontalSqueeze)
    end
    if FluxCombatManager and FluxCombatManager.Grid and FluxCombatManager.Grid.Relayout then
        pcall(function() FluxCombatManager.Grid:Relayout() end)
    end
    if _G.FluxNonCombatGrid_ApplyScreenBottomAnchor then
        pcall(_G.FluxNonCombatGrid_ApplyScreenBottomAnchor)
    end
    if _G.FluxNonCombatAPI and FluxNonCombatAPI.DefaultGrid and FluxNonCombatAPI.DefaultGrid.Relayout then
        pcall(function() FluxNonCombatAPI.DefaultGrid:Relayout() end)
    end
    if FluxCombatManager and FluxCombatManager.UpdateAnchor then
        pcall(FluxCombatManager.UpdateAnchor, FluxCombatManager)
    end
    if FluxTrinketMenuManager and FluxTrinketMenuManager.UpdateAnchor then
        pcall(FluxTrinketMenuManager.UpdateAnchor, FluxTrinketMenuManager)
    end
    if _G.FluxButtonAPI and FluxButtonAPI.DefaultGrid and FluxButtonAPI.DefaultGrid.Relayout then
        pcall(function() FluxButtonAPI.DefaultGrid:Relayout() end)
    end
    if _G.FluxSpellBookSlots_ApplyHorizontalSqueeze then
        pcall(_G.FluxSpellBookSlots_ApplyHorizontalSqueeze)
    end
    local Flyout = Flux and Flux.EBS and Flux.EBS.Flyout
    if Flyout and Flyout.OnDependentsLayoutChanged then
        pcall(Flyout.OnDependentsLayoutChanged)
    elseif _G.FluxFlyoutFrame and FluxFlyoutFrame.OnDependentsLayoutChanged then
        pcall(function() FluxFlyoutFrame.OnDependentsLayoutChanged() end)
    end
    if _G.FluxChatFrame_ApplyPrimaryPosition then
        pcall(_G.FluxChatFrame_ApplyPrimaryPosition, true)
    end
    if Flux and Flux.Bars and Flux.Bars.BadgeHost and Flux.Bars.BadgeHost.RefreshLayout then
        pcall(Flux.Bars.BadgeHost.RefreshLayout)
    end
    if _G.FluxMinimap and FluxMinimap.RefreshBlizzardBuffDebuffSqueeze then
        pcall(function() FluxMinimap:RefreshBlizzardBuffDebuffSqueeze() end)
    end
    if Flux and Flux.Bars and Flux.Bars.Pet and Flux.Bars.Pet.LayoutButtons then
        pcall(Flux.Bars.Pet.LayoutButtons)
    end
    if Flux and Flux.Bars and Flux.Bars.Stance and Flux.Bars.Stance.RequestSizeOnly then
        pcall(Flux.Bars.Stance.RequestSizeOnly)
    end
    if _G.FluxUnitFrames_ApplyPlayerStatusBarLayout then
        pcall(_G.FluxUnitFrames_ApplyPlayerStatusBarLayout)
    end
    local auraX = FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames
        and FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames()
    if type(auraX) ~= "number" or auraX ~= auraX or auraX <= 0 then
        auraX = 1
    end
    if FluxUILayoutSqueeze._lastPushedAuraX ~= auraX and _G.FluxUnitFrames_RefreshAuraLayoutsAfterSqueeze then
        local ok = pcall(_G.FluxUnitFrames_RefreshAuraLayoutsAfterSqueeze)
        if ok then
            local applied = FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames()
            if type(applied) ~= "number" or applied ~= applied or applied <= 0 then
                applied = auraX
            end
            FluxUILayoutSqueeze._lastPushedAuraX = applied
        end
    end
    FluxUILayoutSqueeze._notifyingDependents = nil
    -- Unit frame width squeeze stays on UI scale / resolution. Extra buttons (above) and auras follow this pass.
end

local squeezeRefreshScheduled = false
local lastDisplayRefreshKey = nil
local squeezeHooksInstalled = false

local function SqueezeRefreshAfter0(fn)
    if _G.Flux and _G.Flux.Timer and _G.Flux.Timer.After then
        _G.Flux.Timer.After(0, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(0, fn)
    else
        fn()
    end
end

function FluxUILayoutSqueeze.EnsureDisplayRefreshHooks()
    if squeezeHooksInstalled then
        return
    end
    squeezeHooksInstalled = true
    if UIParent and UIParent.HookScript then
        UIParent:HookScript("OnSizeChanged", function()
            if FluxUILayoutSqueeze.RequestRefresh then
                FluxUILayoutSqueeze.RequestRefresh("uiparent_size")
            end
        end)
    end
end

--- One coalesced X-squeeze refresh after resolution / UI scale / UIParent size.
--- 16:9 and 16:10 both clamp to min uiScale, so this must run even when the CVar does not change.
function FluxUILayoutSqueeze.RequestRefresh(reason)
    FluxUILayoutSqueeze.EnsureDisplayRefreshHooks()
    if InCombatLockdown and InCombatLockdown() then
        if _G.Flux and _G.Flux.Combat and _G.Flux.Combat.Defer then
            _G.Flux.Combat.Defer("layout.squeeze", function()
                FluxUILayoutSqueeze.RequestRefresh(reason or "post_combat")
            end)
        else
            local f = FluxDefaultSettings._eventFrame
            if f then
                f.pendingSqueezeRefresh = true
            end
        end
        return
    end
    if squeezeRefreshScheduled then
        return
    end
    squeezeRefreshScheduled = true
    local function flush()
        squeezeRefreshScheduled = false
        if InCombatLockdown and InCombatLockdown() then
            FluxUILayoutSqueeze.RequestRefresh(reason or "post_combat")
            return
        end
        local key = FluxUILayoutSqueeze.GetEmulatedDependentCacheKey()
        if lastDisplayRefreshKey == key then
            return
        end
        lastDisplayRefreshKey = key
        FluxUILayoutSqueeze.InvalidateEmulatedDependentCache()
        local Bars = _G.Flux and _G.Flux.Bars
        if Bars and Bars.ApplyLayout then
            pcall(Bars.ApplyLayout)
        elseif Bars and Bars.RequestLayout then
            pcall(Bars.RequestLayout, "display")
        end
        pcall(FluxUILayoutSqueeze.NotifyLayoutDependents)
    end
    local Scheduler = _G.Flux and _G.Flux.Scheduler
    if Scheduler and Scheduler.Request then
        Scheduler.Request("layout", "squeeze.refresh", flush, reason or "display")
    else
        SqueezeRefreshAfter0(flush)
    end
end

-- Get the current state of the game settings
function FluxDefaultSettings.GetState()
    if not FLUX_API then return FluxDefaultSettings.State.MODIFIED, {} end

    local isModified = false
    local debugInfo = {}

    for _, cvar in ipairs(CRITICAL_CVARS) do
        local currentVal = FluxGetCVar(cvar)
        local defaultVal = FluxGetCVarDefault(cvar)

        local normCurrent = tonumber(currentVal) or currentVal
        local normDefault = tonumber(defaultVal) or defaultVal
        
        if type(normCurrent) == "number" and type(normDefault) == "number" then
            if math.abs(normCurrent - normDefault) > 0.001 then
                isModified = true
                table.insert(debugInfo, cvar .. ": " .. tostring(currentVal) .. " != " .. tostring(defaultVal))
            end
        else
            if tostring(normCurrent) ~= tostring(normDefault) then
                isModified = true
                table.insert(debugInfo, cvar .. ": " .. tostring(currentVal) .. " != " .. tostring(defaultVal))
            end
        end
    end

    if isModified then
        return FluxDefaultSettings.State.MODIFIED, debugInfo
    else
        return FluxDefaultSettings.State.FRESH, {}
    end
end

local BlizzardSettings = select(2, ...).Flux.BlizzardSettings

--- Post-DF retail: the bulk FluxSetCVar loop does not write nameplate, raid, or
--- cast-bar CVars. Those go through BlizzardSettings.Write after Settings closes.
--- Settings.SetValue stays off Forever and Live (preview taint).
local function FluxAvoidBlizzardSettingsCoupling()
    local api = FLUX_API
    return api and api.isRetail and api.isPostDF and true or false
end

local function FluxIsNameplateDefaultCVar(cvar)
    return type(cvar) == "string" and string.sub(string.lower(cvar), 1, 9) == "nameplate"
end

local function FluxIsSoftTargetEnemyDefaultCVar(cvar)
    return type(cvar) == "string" and string.lower(cvar) == "softtargetenemy"
end

local function FluxIsCastBarPreviewCoupledCVar(cvar)
    if type(cvar) ~= "string" then
        return false
    end
    local lower = string.lower(cvar)
    return lower == "showenemycastbar" or lower == "showtargetcastbar"
end

local function FluxIsRaidArenaFrameDefaultCVar(cvar)
    if type(cvar) ~= "string" then
        return false
    end
    local lower = string.lower(cvar)
    return string.sub(lower, 1, 10) == "raidframes"
        or string.sub(lower, 1, 9) == "pvpframes"
        or lower == "usecompactpartyframes"
        or lower == "raidoptiondisplaymaintankandassist"
        or lower == "raidoptiondisplaypets"
        or lower == "pvpoptiondisplaypets"
end

local function FluxSkipCoupledDefaultCVar(cvar)
    if FluxIsNameplateDefaultCVar(cvar) then
        return true
    end
    -- Raid/arena CUF CVars: skip bulk FLUX_DEFAULTS only on post-DF retail
    -- (SetCVar → ApplyCurrentSettings under _FluxUI secrets). Classic / pre-DF
    -- must still receive power bars, class color, dispellable, % health from FLUX_DEFAULTS.
    if FluxAvoidBlizzardSettingsCoupling() and FluxIsRaidArenaFrameDefaultCVar(cvar) then
        return true
    end
    -- softTargetEnemy only (action targeting); softTargetInteract is written by Controls pack.
    if FluxAvoidBlizzardSettingsCoupling() and FluxIsSoftTargetEnemyDefaultCVar(cvar) then
        return true
    end
    if FluxAvoidBlizzardSettingsCoupling() and FluxIsCastBarPreviewCoupledCVar(cvar) then
        return true
    end
    return false
end

local function FluxSettingsPanelOpen()
    return SettingsPanel and SettingsPanel.IsShown and SettingsPanel:IsShown()
end

--- Arm PLAYER_REGEN_ENABLED only while deferred work is queued (no idle listener).
--- Nameplate and raid packs queue themselves in BlizzardSettings/Write.lua.
local function FluxArmPendingCombatFlush()
    local f = FluxDefaultSettings._eventFrame
    if not f or not f.RegisterEvent then
        return
    end
    if FluxDefaultSettings._pendingSoftTargetReassert
        or FluxDefaultSettings._pendingStickyTargeting
        or (FluxDefaultSettings._resetDetection and FluxDefaultSettings._resetDetection._pendingKeybindReapply)
        or f.pendingScaleUpdate
        or f.pendingSqueezeRefresh then
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
end

local function FluxDisarmPendingCombatFlushIfIdle()
    local f = FluxDefaultSettings._eventFrame
    if not f or not f.UnregisterEvent then
        return
    end
    if FluxDefaultSettings._pendingSoftTargetReassert
        or FluxDefaultSettings._pendingStickyTargeting
        or (FluxDefaultSettings._resetDetection and FluxDefaultSettings._resetDetection._pendingKeybindReapply)
        or f.pendingScaleUpdate
        or f.pendingSqueezeRefresh then
        return
    end
    f:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

local function FluxEnsureSettingsPanelNameplateFlushHook()
    if FluxDefaultSettings._softTargetSettingsFlushHooked then
        return
    end
    if not SettingsPanel then
        return
    end
    FluxDefaultSettings._softTargetSettingsFlushHooked = true
    local function FlushPending()
        if FluxDefaultSettings._pendingSoftTargetReassert then
            C_Timer.After(0, function()
                FluxDefaultSettings.ReassertSoftTargetEnemyFromDefaults()
            end)
        end
    end
    local client = _G.Flux and _G.Flux.Client
    local forever = client and (client.isCamelot or client.isForever)
    if not forever then
        local api = _G.FLUX_API
        forever = api and (api.isCamelot or api.isForever)
    end
    if forever then
        local was = SettingsPanel:IsShown() and true or false
        local watch = CreateFrame("Frame")
        watch:SetScript("OnUpdate", function()
            if not SettingsPanel or not SettingsPanel.IsShown then
                return
            end
            local shown = SettingsPanel:IsShown() and true or false
            if shown == was then
                return
            end
            was = shown
            if not shown then
                FlushPending()
            end
        end)
        return
    end
    if not SettingsPanel.HookScript then
        FluxDefaultSettings._softTargetSettingsFlushHooked = nil
        return
    end
    SettingsPanel:HookScript("OnHide", FlushPending)
end

-- Nameplate CVar pack lives in BlizzardSettings/Nameplates.lua (all clients).
-- Each writer returns true if a CVar was written; Apply/Schedule queue while
-- in combat or while Settings is open.
function FluxDefaultSettings.ApplyNameplateScalarDefaults(force)
    return BlizzardSettings.Nameplates.ApplyScalars(force)
end

function FluxDefaultSettings.ApplyNameplateClassColorDefault(force)
    return BlizzardSettings.Nameplates.ApplyClassColor(force)
end

function FluxDefaultSettings.ApplyNameplateNpcNameDefaults(force)
    return BlizzardSettings.Nameplates.ApplyNpcNames(force)
end

function FluxDefaultSettings.ApplyNameplateBitfieldDefaults(force)
    return BlizzardSettings.Nameplates.ApplyBitfields(force)
end

function FluxDefaultSettings.ApplyNameplateDefaultsPack(force)
    return BlizzardSettings.Nameplates.Apply(force)
end

function FluxDefaultSettings.ScheduleNameplateDefaultsPack(force)
    BlizzardSettings.Nameplates.Apply(force)
end

-- Apply special CVar settings that require multiple methods (sticky targeting, etc.)
-- This is called by both Apply() and ApplyCVarsOnly()

-- Never :Click() Blizzard nameplate Options widgets from addon code — that runs
-- option callbacks → RefreshAuras → Layout under _FluxUI (GetScaledRect taint).
local function FluxClickLegacyOptionsCheckbox(widget)
    if not widget or not widget.Click then
        return
    end
    local name = widget.GetName and widget:GetName()
    if type(name) == "string" and name:find("NamePlates", 1, true) then
        return
    end
    widget:Click()
end

function FluxDefaultSettings.ApplySpecialCVarSettings()
    local st = FluxDefaultSettings._specialCVarApply
    if not st then
        st = { pending = false, lastStart = 0 }
        FluxDefaultSettings._specialCVarApply = st
    end
    local now = (GetTime and GetTime()) or 0
    if st.pending and (now - (st.lastStart or 0)) < 8 then
        return -- already scheduled; do not stack bitfield / UI timers
    end
    st.pending = true
    st.lastStart = now

    -- Nameplates pack + Combat / Action Bars packs (Reset These Settings targets these too).
    pcall(FluxDefaultSettings.ApplyNameplateDefaultsPack, true)
    pcall(FluxDefaultSettings.ApplyCombatDefaultsPack, true)
    pcall(FluxDefaultSettings.ApplyActionBarDefaultsPack, true)
    pcall(FluxDefaultSettings.ApplyControlsDefaultsPack, true)
    -- Post-DF: raid pack skips CUF CVars (preview taint). Still runs tutorials + profile opts when closed.
    pcall(FluxDefaultSettings.ApplyInterfaceDefaultsPack, true)
    C_Timer.After(3, function()
        st.pending = false
    end)

    -- Sticky Targeting OFF (NegateBoolean stores off as deselectOnClick 1).
    C_Timer.After(0.5, function()
        if InCombatLockdown and InCombatLockdown() then
            FluxDefaultSettings._pendingStickyTargeting = true
            FluxArmPendingCombatFlush()
            return
        end
        pcall(FluxDefaultSettings.ApplyStickyTargetingOff)
    end)
end

-- Raid / arena frame defaults and tutorials live in BlizzardSettings/Raid.lua.
-- Never call CompactUnitFrameProfiles:ApplyCurrentSettings from addon code.
function FluxDefaultSettings.ApplyRaidFrameSettings()
    return BlizzardSettings.Raid.Apply(true)
end

function FluxDefaultSettings.ScheduleRaidArenaFrameDefaultsPack(force)
    return BlizzardSettings.Raid.Apply(force)
end

function FluxDefaultSettings.ApplyRaidArenaFrameDefaultsPackNow(force)
    return BlizzardSettings.Raid.Apply(force)
end

function FluxDefaultSettings.ApplyRaidArenaFrameDefaultsPack(force)
    BlizzardSettings.Raid.Apply(force)
    return false
end

--- Interface category: tutorials off + raid/arena pack.
function FluxDefaultSettings.ApplyInterfaceDefaultsPack(force)
    return BlizzardSettings.Raid.Apply(force)
end

--- Sticky Targeting OFF (Controls checkbox unchecked).
--- NegateBoolean: the checkbox value false is stored as deselectOnClick 1.
--- Raw SetCVar("1") is read back by OnCVarChanged as true and flipped to 0,
--- so the open Options page must be set with the checkbox value, not the CVar.
function FluxDefaultSettings.ApplyStickyTargetingOff()
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    local Write = BlizzardSettings.Write
    Write.CVar("stickyTargeting", "0", true)
    if not Write.SetShownValue("deselectOnClick", false) then
        Write.CVar("deselectOnClick", "1", true)
    end
    pcall(function()
        if InterfaceOptionsDisplayPanelStickyTargeting and InterfaceOptionsDisplayPanelStickyTargeting.GetChecked
            and InterfaceOptionsDisplayPanelStickyTargeting:GetChecked() then
            InterfaceOptionsDisplayPanelStickyTargeting:Click()
        end
        if InterfaceOptionsControlsPanelStickyTargeting and InterfaceOptionsControlsPanelStickyTargeting.GetChecked
            and InterfaceOptionsControlsPanelStickyTargeting:GetChecked() then
            InterfaceOptionsControlsPanelStickyTargeting:Click()
        end
    end)
    -- Sync the Settings control where the Settings API is allowed (Era / Anniversary).
    -- NegateBoolean: false = Sticky OFF → CVar 1.
    BlizzardSettings.Write.SetSetting("PROXY_DESELECT_ON_CLICK", false)
    BlizzardSettings.Write.SetSetting("deselectOnClick", false)
    BlizzardSettings.Write.RefreshShown("deselectOnClick")
    return true
end

--- Furthest allowed cameraDistanceMaxZoomFactor for this client.
--- Prefer engine GetCVarMax; Classic accepts up to 4; retail Midnight+ also 4; older retail ~2.6.
function FluxDefaultSettings.GetMaxCameraDistanceZoomFactor()
    if C_CVar and C_CVar.GetCVarMax then
        local ok, maxV = pcall(C_CVar.GetCVarMax, "cameraDistanceMaxZoomFactor")
        local n = ok and tonumber(maxV)
        if n and n > 0 then
            return n
        end
    end
    if GetCVarMax then
        local ok, maxV = pcall(GetCVarMax, "cameraDistanceMaxZoomFactor")
        local n = ok and tonumber(maxV)
        if n and n > 0 then
            return n
        end
    end
    local api = FLUX_API
    if api and api.isAnyClassic then
        return 4
    end
    if api and api.isRetail and api.majorVersion and api.majorVersion >= 12 then
        return 4
    end
    return 2.6
end

--- Set camera zoom to the client maximum (Controls / Apply / Classic PEW reset).
function FluxDefaultSettings.ApplyMaxCameraDistance(force)
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    local maxFactor = FluxDefaultSettings.GetMaxCameraDistanceZoomFactor()
    local desired = tostring(maxFactor)
    FLUX_DEFAULTS["cameraDistanceMaxZoomFactor"] = desired
    local cur = (FluxGetCVar and FluxGetCVar("cameraDistanceMaxZoomFactor"))
        or (GetCVar and GetCVar("cameraDistanceMaxZoomFactor"))
    if cur == nil then
        return false
    end
    if not force then
        local a, b = tonumber(cur), tonumber(desired)
        if a and b and math.abs(a - b) < 0.001 then
            return false
        end
        if tostring(cur) == desired then
            return false
        end
    end
    local ok = false
    if FluxSetCVar then
        ok = FluxSetCVar("cameraDistanceMaxZoomFactor", desired) and true or false
    else
        ok = pcall(SetCVar, "cameraDistanceMaxZoomFactor", desired)
    end
    return ok and true or false
end

--- Controls: sticky off, auto loot on, combined bags, interact key, camera never adjust + max zoom.
function FluxDefaultSettings.ApplyControlsDefaultsPack(force)
    if InCombatLockdown and InCombatLockdown() then
        C_Timer.After(2, function()
            FluxDefaultSettings.ApplyControlsDefaultsPack(force)
        end)
        return false
    end

    local wrote = false
    local function cvarMatches(cvar, desired)
        local cur = (FluxGetCVar and FluxGetCVar(cvar)) or (GetCVar and GetCVar(cvar))
        if cur == nil then
            return true
        end
        local a, b = tonumber(cur), tonumber(desired)
        if a and b then
            return math.abs(a - b) < 0.001
        end
        return tostring(cur) == tostring(desired)
    end
    local function setCVar(cvar, value)
        if not force and cvarMatches(cvar, value) then
            return
        end
        local cur = (FluxGetCVar and FluxGetCVar(cvar)) or (GetCVar and GetCVar(cvar))
        if cur == nil then
            return
        end
        local ok = false
        if FluxSetCVar then
            ok = FluxSetCVar(cvar, value)
        else
            ok = pcall(SetCVar, cvar, value)
        end
        if ok then
            wrote = true
        end
    end

    if FluxDefaultSettings.ApplyStickyTargetingOff() then
        wrote = true
    end
    setCVar("autoClearAFK", "1")
    setCVar("interactOnLeftClick", "0")
    setCVar("lootUnderMouse", "1")
    setCVar("autoLootDefault", "1")
    setCVar("autoLootKey", "3")
    setCVar("combinedBags", "1")
    setCVar("softTargetInteract", "3") -- Enable Interact Key = Any
    setCVar("softTargettingInteractKeySound", "0")
    setCVar("cameraSmoothStyle", "0") -- Never adjust
    if FluxDefaultSettings.ApplyMaxCameraDistance(force) then
        wrote = true
    end

    local Write = BlizzardSettings.Write
    Write.SetShownValue("autoClearAFK", true)
    Write.SetShownValue("interactOnLeftClick", false)
    Write.SetShownValue("lootUnderMouse", true)
    Write.SetShownValue("autoLootDefault", true)
    Write.SetShownValue("combinedBags", true)
    Write.SetShownValue("PROXY_ENABLE_INTERACT", true)
    Write.SetShownValue("cameraSmoothStyle", 0)
    Write.RefreshShown({
        "autoClearAFK",
        "interactOnLeftClick",
        "lootUnderMouse",
        "autoLootDefault",
        "combinedBags",
        "PROXY_ENABLE_INTERACT",
        "softTargettingInteractKeySound",
        "cameraSmoothStyle",
        "cameraDistanceMaxZoomFactor",
        "deselectOnClick",
    })

    return wrote
end

-- Enable Class Colors in Chat Channels (Global & Standard)
function FluxDefaultSettings.ApplyChatSettings()
    -- Chat settings are safe in combat (no protected function calls)
    -- Helpers
    local function EnableClassColor(type)
        -- Try Global API first (handles persistence/C-side)
        if SetChatColorNameByClass then
             pcall(SetChatColorNameByClass, type, true)
        end
        
        -- Fallback: Table modification (immediate visual update if frame exists)
        if ChatTypeInfo[type] then
            ChatTypeInfo[type].colorNameByClass = true
        end
    end

    -- 1. Standard Chat Types
    local CHAT_TYPES = {
        "SAY", "EMOTE", "YELL", "WHISPER",
        "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER",
        "GUILD", "OFFICER", 
        "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER",
        "CHANNEL", -- The category "Channel"
    }
    for _, type in ipairs(CHAT_TYPES) do
        EnableClassColor(type)
    end
    
    -- 2. Global Channels (1-20)
    -- These keys (CHANNEL1, CHANNEL2) might not exist yet, but API should handle persistence
    for i = 1, 20 do
        EnableClassColor("CHANNEL"..i)
    end
    
    -- 3. Force refresh of chat frames to reflect changes immediately
    -- CRITICAL: Check combat before UI updates
    if not InCombatLockdown() and FCF_UpdateChatWindow then
        for _, frame in ipairs(CHAT_FRAMES) do
            pcall(FCF_UpdateChatWindow, frame)
        end
    end
    
    print("|cFF00FFFF[FluxDefaultSettings]|r Chat Class Colors enabled globally.")
end

--- Self Cast = Auto, Focus Cast = None, Mouseover Cast = Off + None,
--- Empowered = Press and Tap, Target of Target = On.
--- Writes CVars + SetModifiedClick; refreshes Options via Settings.NotifyUpdate (not SetValue).
function FluxDefaultSettings.ApplySelfCastAndFocusCastDefaults()
    FluxDefaultSettings.ApplyCombatDefaultsPack(true)
end

--- Combat category pack (also used by Apply / Reset These Settings → Combat).
function FluxDefaultSettings.ApplyCombatDefaultsPack(force)
    if InCombatLockdown and InCombatLockdown() then
        C_Timer.After(2, function()
            FluxDefaultSettings.ApplyCombatDefaultsPack(force)
        end)
        return false
    end

    local wrote = false
    local function cvarMatches(cvar, desired)
        local cur = (FluxGetCVar and FluxGetCVar(cvar)) or (GetCVar and GetCVar(cvar))
        if cur == nil then
            return true -- missing: skip
        end
        local a, b = tonumber(cur), tonumber(desired)
        if a and b then
            return math.abs(a - b) < 0.001
        end
        return tostring(cur) == tostring(desired)
    end
    local function setCVar(cvar, value)
        if not force and cvarMatches(cvar, value) then
            return
        end
        local cur = (FluxGetCVar and FluxGetCVar(cvar)) or (GetCVar and GetCVar(cvar))
        if cur == nil then
            return
        end
        local ok = false
        if FluxSetCVar then
            ok = FluxSetCVar(cvar, value)
        else
            ok = pcall(SetCVar, cvar, value)
        end
        if ok then
            wrote = true
        end
    end

    setCVar("showTargetOfTarget", "1")
    -- Blizzard mouseover cast stays off on every client. Modifier stays None.
    setCVar("enableMouseoverCast", "0")
    setCVar("autoSelfCast", "1")
    setCVar("empowerTapControls", "1") -- Press and Tap
    setCVar("doNotFlashLowHealthWarning", "0")
    setCVar("raidSelfHighlight", "0")
    setCVar("occludedSilhouettePlayer", "1")
    setCVar("floatingCombatTextCombatDamage_v2", "1")
    setCVar("floatingCombatTextCombatLogPeriodicSpells_v2", "1")
    setCVar("floatingCombatTextPetMeleeDamage_v2", "1")
    setCVar("floatingCombatTextCombatHealing_v2", "1")
    setCVar("assistedCombatHighlight", "0")
    setCVar("cooldownViewerEnabled", "0")

    -- These CVars are blocked on the bulk FluxSetCVar path. Write them now so
    -- Reset These Settings updates the open page instead of waiting for it to close.
    local function writeCoupledCombat()
        local Write = BlizzardSettings.Write
        if Write.CVar("softTargetEnemy", FLUX_DEFAULTS["softTargetEnemy"] or "1", force) then
            wrote = true
        end
        if Write.CVar("showTargetCastbar", FLUX_DEFAULTS["showTargetCastbar"] or "1", force) then
            wrote = true
        end
        if Write.CVar("showEnemyCastbar", FLUX_DEFAULTS["showEnemyCastbar"] or "1", force) then
            wrote = true
        end
        if Write.CVar("nameplateShowSelf", "0", force) then
            wrote = true
        end
    end
    writeCoupledCombat()

    pcall(function()
        if not SetModifiedClick then
            return
        end
        SetModifiedClick("SELFCAST", "NONE")
        SetModifiedClick("FOCUSCAST", "NONE")
        SetModifiedClick("MOUSEOVERCAST", "NONE")
        if SaveBindings and GetCurrentBindingSet then
            SaveBindings(GetCurrentBindingSet())
        end
        wrote = true
    end)

    local Write = BlizzardSettings.Write
    local auto = (SELF_CAST_SETTING_VALUES and SELF_CAST_SETTING_VALUES.AUTO) or 2
    Write.SetShownValue("enableMouseoverCast", false)
    Write.SetShownValue("PROXY_SELF_CAST", auto)
    Write.SetShownValue("SELFCAST", "NONE")
    Write.SetShownValue("FOCUSCAST", "NONE")
    Write.SetShownValue("MOUSEOVERCAST", "NONE")
    Write.SetShownValue("showTargetOfTarget", true)
    Write.SetShownValue("occludedSilhouettePlayer", true)
    Write.SetShownValue("assistedCombatHighlight", false)
    Write.SetShownValue("cooldownViewerEnabled", false)
    Write.SetShownValue("nameplateShowSelf", false)

    -- Refresh Combat Options UI from live values (avoid Settings.SetValue softTarget path).
    local combatShown = {
        "showTargetOfTarget",
        "enableMouseoverCast",
        "MOUSEOVERCAST",
        "PROXY_SELF_CAST",
        "SELFCAST",
        "FOCUSCAST",
        "empowerTapControls",
        "doNotFlashLowHealthWarning",
        "raidSelfHighlight",
        "occludedSilhouettePlayer",
        "floatingCombatTextCombatDamage_v2",
        "floatingCombatTextCombatLogPeriodicSpells_v2",
        "floatingCombatTextPetMeleeDamage_v2",
        "floatingCombatTextCombatHealing_v2",
        "assistedCombatHighlight",
        "cooldownViewerEnabled",
        "nameplateShowSelf",
        "softTargetEnemy",
        "PROXY_ACTION_TARGETING",
        "showTargetCastbar",
        "showEnemyCastbar",
    }
    Write.Notify(combatShown)
    Write.RefreshShown(combatShown)

    return wrote
end

--- Action Bars: bars 2–8 off, Always Show Action Bars on, cooldown numbers on, unlocked.
function FluxDefaultSettings.ApplyActionBarDefaultsPack(force)
    if InCombatLockdown and InCombatLockdown() then
        C_Timer.After(2, function()
            FluxDefaultSettings.ApplyActionBarDefaultsPack(force)
        end)
        return false
    end

    local wrote = false
    local function cvarMatches(cvar, desired)
        local cur = (FluxGetCVar and FluxGetCVar(cvar)) or (GetCVar and GetCVar(cvar))
        if cur == nil then
            return true
        end
        local a, b = tonumber(cur), tonumber(desired)
        if a and b then
            return math.abs(a - b) < 0.001
        end
        return tostring(cur) == tostring(desired)
    end
    local function setCVar(cvar, value)
        if not force and cvarMatches(cvar, value) then
            return
        end
        local cur = (FluxGetCVar and FluxGetCVar(cvar)) or (GetCVar and GetCVar(cvar))
        if cur == nil then
            return
        end
        local ok = false
        if FluxSetCVar then
            ok = FluxSetCVar(cvar, value)
        else
            ok = pcall(SetCVar, cvar, value)
        end
        if ok then
            wrote = true
        end
    end

    setCVar("alwaysShowActionBars", "1")
    setCVar("lockActionBars", "0")
    setCVar("countdownForCooldowns", "1")
    setCVar("enableMultiActionBars", "0")
    setCVar("multiBarLeft", "0")
    setCVar("multiBarRight", "0")
    setCVar("multiBarBottomLeft", "0")
    setCVar("multiBarBottomRight", "0")
    setCVar("ActionButtonUseKeyDown", "1")

    -- Toggles only. MultiActionBar_Update and the PROXY_SHOW_ACTIONBAR_* setting
    -- callbacks SetShown every multi-bar as Flux; Edit Mode's SetupActionBar then
    -- reads that bar state before TargetUnit. Blizzard applies the toggles itself.
    pcall(function()
        if type(GetActionBarToggles) ~= "function" or type(SetActionBarToggles) ~= "function" then
            return
        end
        local t = { GetActionBarToggles() }
        local changed = false
        for i = 1, #t do
            if t[i] then
                changed = true
            end
            t[i] = false
        end
        if (force or changed) and #t > 0 then
            SetActionBarToggles(unpack(t))
            wrote = true
        end
    end)

    local Write = BlizzardSettings.Write
    Write.SetShownValue("lockActionBars", false)
    Write.SetShownValue("countdownForCooldowns", true)
    local barsShown = {
        "alwaysShowActionBars",
        "lockActionBars",
        "countdownForCooldowns",
        "PICKUPACTION",
    }
    Write.Notify(barsShown)
    Write.RefreshShown(barsShown)

    return wrote
end

-- Apply Keybindings.
-- Each SetBinding fires UPDATE_BINDINGS; Flux listeners + LAB skip while suppress is on.
-- Clear + template are batched across frames (skip no-ops), then one FlushBindingRefreshAfterBulk.
local KEYBIND_BATCH_SIZE = 8

--- True while bulk keybind apply / Blizzard Defaults is in progress — skip expensive UPDATE_BINDINGS work.
function FluxDefaultSettings.ShouldSuppressBindingRefresh()
    local d = FluxDefaultSettings._resetDetection
    if d and d._flushingBindingRefresh then
        return false
    end
    if d and (d._applyingKeybinds or d.justAppliedKeybinds) then
        return true
    end
    if SettingsPanel and SettingsPanel.CheckIsSettingDefaults and SettingsPanel:CheckIsSettingDefaults() then
        return true
    end
    return false
end

--- One-shot refresh after bulk SetBinding (action bar overrides, FluxBinding apply, mouseover, hotkeys).
function FluxDefaultSettings.FlushBindingRefreshAfterBulk()
    local detection = FluxDefaultSettings._resetDetection
    detection._flushingBindingRefresh = true
    pcall(function()
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        if _G.FluxActionBarCreate and _G.FluxActionBarCreate.SetupKeybindings then
            pcall(_G.FluxActionBarCreate.SetupKeybindings)
        end
        if _G.FluxBinding and _G.FluxBinding.NotifyBindingsChanged then
            pcall(_G.FluxBinding.NotifyBindingsChanged, "bulkKeybinds")
        elseif _G.FluxBinding and _G.FluxBinding.RequestApplyAll then
            pcall(_G.FluxBinding.RequestApplyAll, "bulkKeybinds")
        end
        local mok = _G.FluxMouseoverKeybindModule or _G.FluxMouseoverKeybind
        if mok and mok.RefreshKeybinds then
            pcall(function() mok:RefreshKeybinds() end)
        end
        if _G.FluxActionBarPresentation and _G.FluxActionBarPresentation.UpdateAllHotkeys then
            pcall(_G.FluxActionBarPresentation.UpdateAllHotkeys, true)
        end
        if LibStub then
            local lab = LibStub("LibActionButton-1.0", true)
            if lab and lab.FluxFlushHotkeys then
                pcall(lab.FluxFlushHotkeys)
            end
        end
        if _G.FluxStanceBar and _G.FluxStanceBar.ReassignBindings then
            pcall(function() _G.FluxStanceBar:ReassignBindings() end)
        end
        if _G.FluxPetBar and _G.FluxPetBar.SetupKeybindings then
            pcall(_G.FluxPetBar.SetupKeybindings)
        end
        if _G.FluxNCUtilitySlotsManager and _G.FluxNCUtilitySlotsManager.UpdateBindings then
            pcall(_G.FluxNCUtilitySlotsManager.UpdateBindings)
        end
        if _G.FluxTrinketMenuManager and _G.FluxTrinketMenuManager.UpdateKeybindings then
            pcall(_G.FluxTrinketMenuManager.UpdateKeybindings)
        elseif _G.FluxTrinketMenu and _G.FluxTrinketMenu.UpdateKeybindings then
            pcall(_G.FluxTrinketMenu.UpdateKeybindings)
        end
        -- Extra Button override binds + hotkey text (skipped during suppress)
        if _G.FluxNCHotkeyUtil and _G.FluxNCHotkeyUtil.FlushAfterBulkBindings then
            pcall(_G.FluxNCHotkeyUtil.FlushAfterBulkBindings)
        end
    end)
    detection._flushingBindingRefresh = false
    -- Second pass after Settings UI settles (override binds can miss the first flush).
    C_Timer.After(0.25, function()
        if InCombatLockdown and InCombatLockdown() then
            if _G.FluxNCHotkeyUtil then
                _G.FluxNCHotkeyUtil._deferredFlush = true
            end
            return
        end
        detection._flushingBindingRefresh = true
        pcall(function()
            if _G.FluxNCHotkeyUtil and _G.FluxNCHotkeyUtil.FlushAfterBulkBindings then
                _G.FluxNCHotkeyUtil.FlushAfterBulkBindings()
            end
            if _G.FluxNCUtilitySlotsManager and _G.FluxNCUtilitySlotsManager.UpdateBindings then
                pcall(_G.FluxNCUtilitySlotsManager.UpdateBindings)
            end
            if _G.FluxTrinketMenuManager and _G.FluxTrinketMenuManager.UpdateKeybindings then
                pcall(_G.FluxTrinketMenuManager.UpdateKeybindings)
            elseif _G.FluxTrinketMenu and _G.FluxTrinketMenu.UpdateKeybindings then
                pcall(_G.FluxTrinketMenu.UpdateKeybindings)
            end
        end)
        detection._flushingBindingRefresh = false
    end)
end

function FluxDefaultSettings.ApplyKeybinds()
    local detection = FluxDefaultSettings._resetDetection

    if InCombatLockdown() then
        print("|cFF00FFFF[FluxDefaultSettings]|r Combat detected — keybinds queued until combat ends.")
        detection._pendingKeybindReapply = true
        FluxArmPendingCombatFlush()
        return
    end

    if detection._applyingKeybinds and detection._keybindBatchActive then
        detection._reapplyKeybindsQueued = true
        return
    end

    detection._applyingKeybinds = true
    detection._keybindBatchActive = true
    detection._reapplyKeybindsQueued = false
    detection.justAppliedKeybinds = true
    detection.isResetting = true
    detection._pendingKeybindReapply = false

    print("|cFF00FFFF[FluxDefaultSettings]|r Applying keybindings...")

    local function releaseGuards()
        C_Timer.After(2, function()
            detection.justAppliedKeybinds = false
            detection.isResetting = false
            detection._applyingKeybinds = false
            detection._keybindBatchActive = false
            -- Final Extra Button rebind after suppress ends (catches deferred + late Settings settle).
            if not InCombatLockdown or not InCombatLockdown() then
                if _G.FluxNCHotkeyUtil and _G.FluxNCHotkeyUtil.FlushAfterBulkBindings then
                    pcall(_G.FluxNCHotkeyUtil.FlushAfterBulkBindings)
                end
            elseif _G.FluxNCHotkeyUtil then
                _G.FluxNCHotkeyUtil._deferredFlush = true
            end
            if detection._reapplyKeybindsQueued then
                detection._reapplyKeybindsQueued = false
                FluxDefaultSettings.ApplyKeybinds()
            end
        end)
    end

    local keepKeys = {}
    for key in pairs(DefaultKeyTemplate) do
        keepKeys[key] = true
    end

    -- Dedupe clear keys (same key can appear as key1 and key2 on different rows).
    local clearSeen = {}
    local clearList = {}
    for i = 1, GetNumBindings() do
        local _, key1, key2 = GetBinding(i)
        if key1 and not keepKeys[key1] and not clearSeen[key1] then
            clearSeen[key1] = true
            clearList[#clearList + 1] = key1
        end
        if key2 and not keepKeys[key2] and not clearSeen[key2] then
            clearSeen[key2] = true
            clearList[#clearList + 1] = key2
        end
    end

    -- Only rewrite template keys that differ from current (avoids redundant SetBinding storms).
    local templateList = {}
    for key, command in pairs(DefaultKeyTemplate) do
        if GetBindingAction(key) ~= command then
            templateList[#templateList + 1] = { key, command }
        end
    end

    local function runBatch(list, startIndex, applyFn, onDone)
        if InCombatLockdown() then
            C_Timer.After(2, function()
                runBatch(list, startIndex, applyFn, onDone)
            end)
            return
        end
        local last = math.min(startIndex + KEYBIND_BATCH_SIZE - 1, #list)
        for i = startIndex, last do
            applyFn(list[i])
        end
        if last < #list then
            C_Timer.After(0, function()
                runBatch(list, last + 1, applyFn, onDone)
            end)
        else
            onDone()
        end
    end

    local function finishApply()
        if InCombatLockdown() then
            C_Timer.After(2, finishApply)
            return
        end
        SaveBindings(GetCurrentBindingSet())
        FluxDefaultSettings.FlushBindingRefreshAfterBulk()
        print("|cFF00FFFF[FluxDefaultSettings]|r Keybindings applied!")
        releaseGuards()
    end

    local function applyTemplateBatches()
        if #templateList == 0 then
            finishApply()
            return
        end
        runBatch(templateList, 1, function(entry)
            SetBinding(entry[1], entry[2])
        end, finishApply)
    end

    if #clearList > 0 then
        runBatch(clearList, 1, function(key)
            SetBinding(key, nil)
        end, applyTemplateBatches)
    else
        applyTemplateBatches()
    end
end

--- Re-apply softTargetEnemy and the unit-frame cast bar from FLUX_DEFAULTS.
--- On first login, Blizzard Settings may load after our bulk Apply and reset them.
--- Writes go through BlizzardSettings.Write (missing CVars skip). Settings.SetValue
--- stays on Era / Anniversary only.
function FluxDefaultSettings.ReassertSoftTargetEnemyFromDefaults()
    if InCombatLockdown() then
        FluxDefaultSettings._pendingSoftTargetReassert = true
        FluxArmPendingCombatFlush()
        return
    end
    -- Avoid SoftTarget ↔ nameplate icon updates while Settings preview is live.
    if SettingsPanel and SettingsPanel.IsShown and SettingsPanel:IsShown() then
        FluxDefaultSettings._pendingSoftTargetReassert = true
        FluxEnsureSettingsPanelNameplateFlushHook()
        return
    end
    local Write = BlizzardSettings.Write
    local enemy = FLUX_DEFAULTS["softTargetEnemy"]
    if enemy ~= nil then
        Write.CVar("softTargetEnemy", enemy, false)
    end
    if FLUX_DEFAULTS["showTargetCastbar"] ~= nil then
        Write.CVar("showTargetCastbar", FLUX_DEFAULTS["showTargetCastbar"], false)
    end
    if FLUX_DEFAULTS["showEnemyCastbar"] ~= nil then
        Write.CVar("showEnemyCastbar", FLUX_DEFAULTS["showEnemyCastbar"], false)
    end
    pcall(FluxDefaultSettings.SyncSettingsRegistryProxies)
    FluxDefaultSettings._pendingSoftTargetReassert = false
    FluxDisarmPendingCombatFlushIfIdle()
end

--- One delayed reassert after Apply / ApplyCVarsOnly (Settings race); not every login.
function FluxDefaultSettings.ScheduleSoftTargetEnemyReassertFromDefaults()
    C_Timer.After(3, function()
        FluxDefaultSettings.ReassertSoftTargetEnemyFromDefaults()
    end)
end

--- Keep retail **Esc > Options** Settings registry in sync with CVars (PROXY_* rows).
--- Sticky Targeting always syncs (including post-DF). SoftTarget / self-cast SetValue
--- stay skipped on post-DF to avoid nameplate preview taint.
function FluxDefaultSettings.SyncSettingsRegistryProxies()
    if InCombatLockdown() then
        return
    end
    -- Sticky Targeting OFF on all clients (NegateBoolean Settings path).
    pcall(FluxDefaultSettings.ApplyStickyTargetingOff)

    local Write = BlizzardSettings.Write
    if not Write.MayUseSettingsAPI() or not Write.CanWriteNow() then
        return
    end
    local any = (Enum.SoftTargetEnableFlags and Enum.SoftTargetEnableFlags.Any) or 3
    local interact = tonumber(Write.Get("softTargetInteract")) or 0
    Write.SetSetting("PROXY_ENABLE_INTERACT", interact == any)
    local enemy = tonumber(Write.Get("softTargetEnemy")) or 0
    Write.SetSetting("PROXY_ACTION_TARGETING", enemy == any)
    Write.SetSetting("PROXY_SELF_CAST", (SELF_CAST_SETTING_VALUES and SELF_CAST_SETTING_VALUES.AUTO) or 2)
    Write.SetSetting("FOCUSCAST", "NONE")
end

--- First login on a **new character** when account-wide defaults already ran: raid frame APIs + chat class colors only (no keybind wipe).
function FluxDefaultSettings.ApplyCharacterFirstLogin()
    print("|cFF00FFFF[FluxDefaultSettings]|r First login for this character (account already configured). Raid frames + chat colors...")
    FluxDefaultSettings.ApplyRaidFrameSettings()
    FluxDefaultSettings.ApplyChatSettings()
end

-- Check client CVar reverts once the login grace window ends. A binding which
-- differs from the Flux template is a player preference, never a reset signal.
function FluxDefaultSettings.VerifyPostLoginDefaults()
    if not FluxUI_DB or not FluxUI_DB.accountDefaultsApplied then
        return
    end
    local detection = FluxDefaultSettings._resetDetection
    if detection.postLoginVerified then
        return -- once per login session
    end
    if InCombatLockdown() then
        C_Timer.After(2, FluxDefaultSettings.VerifyPostLoginDefaults)
        return
    end
    detection.postLoginVerified = true

    -- Only treat as a client CVar revert when several Flux-owned sentinels were reset to Blizzard.
    -- Avoid stomping on /reload noise or a couple of user-tweaked options.
    local sentinelCVars = {
        "showTutorials",
        "autoLootDefault",
        "deselectOnClick",
    }
    local mismatchCount = 0
    for _, cvar in ipairs(sentinelCVars) do
        local fluxVal = FLUX_DEFAULTS[cvar]
        if fluxVal ~= nil then
            local blizzDef = FluxGetCVarDefault(cvar)
            if blizzDef ~= nil then
                local fv, bd = tostring(fluxVal), tostring(blizzDef)
                if fv ~= bd then
                    local cur = FluxGetCVar(cvar)
                    if cur ~= nil and tostring(cur) == bd then
                        mismatchCount = mismatchCount + 1
                    end
                end
            end
        end
    end

    -- Binding changes must never authorize resetting bindings or CVars.
    local needsCvars = mismatchCount >= 4

    if needsCvars then
        print("|cFF00FFFF[FluxDefaultSettings]|r Post-login verify: client reverted Flux CVars (" .. mismatchCount .. " sentinels); re-applying CVars...")
        FluxDefaultSettings.ApplyCVarsOnly()
        detection.justAppliedCVars = true
        C_Timer.After(2, function()
            detection.justAppliedCVars = false
        end)
    end
end

-- Apply the defaults
-- @param force boolean: If true, applies even if already applied before
function FluxDefaultSettings.Apply(force)
    -- Initialize DB if needed (SavedVariables)
    if not FluxUI_DB then FluxUI_DB = {} end
    
    if FluxUI_DB.accountDefaultsApplied and not force then
        print("|cFF00FFFF[FluxDefaultSettings]|r Defaults already applied to this account. Use /fluxdefaults force to re-apply.")
        return
    end

    print("|cFF00FFFF[FluxDefaultSettings]|r Applying default settings (Account-Wide)...")
    local count = 0
    
    -- Handlers for Special Cases
    local optimalScale = GetOptimalUIScale()
    FLUX_DEFAULTS["uiscale"] = optimalScale
    FLUX_DEFAULTS["cameraDistanceMaxZoomFactor"] = tostring(FluxDefaultSettings.GetMaxCameraDistanceZoomFactor())
    
    -- CVar changes are safe in combat (nameplates go through ApplyNameplateDefaultsPack only).
    for cvar, value in pairs(FLUX_DEFAULTS) do
        if not FluxSkipCoupledDefaultCVar(cvar) then
            local success = FluxSetCVar(cvar, value)
            if success then
                count = count + 1
            end
        end
    end

    pcall(FluxDefaultSettings.SyncSettingsRegistryProxies)
    FluxDefaultSettings.ScheduleSoftTargetEnemyReassertFromDefaults()
    
    -- Handle deselectOnClick specifically (legacy had multiple methods)
    -- Try multiple methods to set deselectOnClick and stickyTargeting with delay
    C_Timer.After(1, function()
        -- Re-check combat before UI interactions
        if InCombatLockdown() then
            -- CVars can still be set
            pcall(function()
                FluxSetCVar("stickyTargeting", "0")
            end)
            -- Queue UI interactions for after combat
            C_Timer.After(2, function()
                if not InCombatLockdown() then
                    -- Retry the full UI interaction block
                    pcall(function()
                        FluxSetCVar("stickyTargeting", "0")
                        
                        if InterfaceOptionsDisplayPanelStickyTargeting and InterfaceOptionsDisplayPanelStickyTargeting.GetChecked and InterfaceOptionsDisplayPanelStickyTargeting:GetChecked() then
                            InterfaceOptionsDisplayPanelStickyTargeting:Click()
                        end
                        if InterfaceOptionsControlsPanelStickyTargeting and InterfaceOptionsControlsPanelStickyTargeting.GetChecked and InterfaceOptionsControlsPanelStickyTargeting:GetChecked() then
                            InterfaceOptionsControlsPanelStickyTargeting:Click()
                        end

                        -- NPC Names (Check if unchecked)
                        if InterfaceOptionsNamesPanelNPCNames and InterfaceOptionsNamesPanelNPCNames.GetChecked and not InterfaceOptionsNamesPanelNPCNames:GetChecked() then
                            InterfaceOptionsNamesPanelNPCNames:Click()
                        end

                        -- Smooth Stacking Nameplates (Check if unchecked)
                        if InterfaceOptionsNamePlatesPanelUseSmoothStacking and InterfaceOptionsNamePlatesPanelUseSmoothStacking.GetChecked and not InterfaceOptionsNamePlatesPanelUseSmoothStacking:GetChecked() then
                            FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelUseSmoothStacking)
                        end
                        
                        -- Stack Friendly Nameplates (Check if unchecked)
                        if InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking and InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking.GetChecked and not InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking:GetChecked() then
                            FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking)
                        end

                        -- Camera Max Distance Slider (Set to Max)
                        if InterfaceOptionsCameraPanelMaxDistanceSlider and InterfaceOptionsCameraPanelMaxDistanceSlider.GetValue and InterfaceOptionsCameraPanelMaxDistanceSlider.GetMinMaxValues then
                            local _, maxVal = InterfaceOptionsCameraPanelMaxDistanceSlider:GetMinMaxValues()
                            if maxVal and InterfaceOptionsCameraPanelMaxDistanceSlider:GetValue() ~= maxVal then
                                InterfaceOptionsCameraPanelMaxDistanceSlider:SetValue(maxVal)
                            end
                        end

                        -- Always Show Nameplates (Check if unchecked)
                        if InterfaceOptionsNamePlatesPanelAlwaysShowNameplates and InterfaceOptionsNamePlatesPanelAlwaysShowNameplates.GetChecked and not InterfaceOptionsNamePlatesPanelAlwaysShowNameplates:GetChecked() then
                            FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelAlwaysShowNameplates)
                        end

                        -- Combat Only Nameplates (Uncheck if checked, to ensure ALWAYS show)
                        if InterfaceOptionsNamePlatesPanelCombatOnly and InterfaceOptionsNamePlatesPanelCombatOnly.GetChecked and InterfaceOptionsNamePlatesPanelCombatOnly:GetChecked() then
                            FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelCombatOnly)
                        end
                        -- Singular variant (legacy typo handling)
                        if InterfaceOptionNamePlatesPanelCombatOnly and InterfaceOptionNamePlatesPanelCombatOnly.GetChecked and InterfaceOptionNamePlatesPanelCombatOnly:GetChecked() then
                            FluxClickLegacyOptionsCheckbox(InterfaceOptionNamePlatesPanelCombatOnly)
                        end
                        
                        -- NPC Names Dropdown -> All NPCs (ID 4)
                        if InterfaceOptionsNamesPanelNPCNamesDropDown and UIDropDownMenu_SetSelectedID then
                             UIDropDownMenu_SetSelectedID(InterfaceOptionsNamesPanelNPCNamesDropDown, 4)
                        end
                    end)
                end
            end)
            return
        end
        
        pcall(function()
            -- Sticky Targeting is applied below via the checkbox value.
            FluxSetCVar("stickyTargeting", "0") -- Legacy 3.3.5 fix
            
            -- Method 1b: Legacy Checkbox UI (controls the CVar and internal state)
            -- Check both potential frame names for various legacy versions
            if InterfaceOptionsDisplayPanelStickyTargeting and InterfaceOptionsDisplayPanelStickyTargeting.GetChecked and InterfaceOptionsDisplayPanelStickyTargeting:GetChecked() then
                InterfaceOptionsDisplayPanelStickyTargeting:Click()
            end
            if InterfaceOptionsControlsPanelStickyTargeting and InterfaceOptionsControlsPanelStickyTargeting.GetChecked and InterfaceOptionsControlsPanelStickyTargeting:GetChecked() then
                InterfaceOptionsControlsPanelStickyTargeting:Click()
            end

            -- NPC Names (Check if unchecked)
            if InterfaceOptionsNamesPanelNPCNames and InterfaceOptionsNamesPanelNPCNames.GetChecked and not InterfaceOptionsNamesPanelNPCNames:GetChecked() then
                InterfaceOptionsNamesPanelNPCNames:Click()
            end

            -- Smooth Stacking Nameplates (Check if unchecked)
            if InterfaceOptionsNamePlatesPanelUseSmoothStacking and InterfaceOptionsNamePlatesPanelUseSmoothStacking.GetChecked and not InterfaceOptionsNamePlatesPanelUseSmoothStacking:GetChecked() then
                FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelUseSmoothStacking)
            end
            
            -- Stack Friendly Nameplates (Check if unchecked)
            if InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking and InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking.GetChecked and not InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking:GetChecked() then
                FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking)
            end

            -- Camera Max Distance Slider (Set to Max)
            if InterfaceOptionsCameraPanelMaxDistanceSlider and InterfaceOptionsCameraPanelMaxDistanceSlider.GetValue and InterfaceOptionsCameraPanelMaxDistanceSlider.GetMinMaxValues then
                local _, maxVal = InterfaceOptionsCameraPanelMaxDistanceSlider:GetMinMaxValues()
                if maxVal and InterfaceOptionsCameraPanelMaxDistanceSlider:GetValue() ~= maxVal then
                    InterfaceOptionsCameraPanelMaxDistanceSlider:SetValue(maxVal)
                end
            end

            -- Always Show Nameplates (Check if unchecked)
            if InterfaceOptionsNamePlatesPanelAlwaysShowNameplates and InterfaceOptionsNamePlatesPanelAlwaysShowNameplates.GetChecked and not InterfaceOptionsNamePlatesPanelAlwaysShowNameplates:GetChecked() then
                FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelAlwaysShowNameplates)
            end

            -- Combat Only Nameplates (Uncheck if checked, to ensure ALWAYS show)
            if InterfaceOptionsNamePlatesPanelCombatOnly and InterfaceOptionsNamePlatesPanelCombatOnly.GetChecked and InterfaceOptionsNamePlatesPanelCombatOnly:GetChecked() then
                FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelCombatOnly)
            end
            -- Singular variant (legacy typo handling)
            if InterfaceOptionNamePlatesPanelCombatOnly and InterfaceOptionNamePlatesPanelCombatOnly.GetChecked and InterfaceOptionNamePlatesPanelCombatOnly:GetChecked() then
                FluxClickLegacyOptionsCheckbox(InterfaceOptionNamePlatesPanelCombatOnly)
            end
            
            -- NPC Names Dropdown -> All NPCs (ID 4)
            if InterfaceOptionsNamesPanelNPCNamesDropDown and UIDropDownMenu_SetSelectedID then
                 UIDropDownMenu_SetSelectedID(InterfaceOptionsNamesPanelNPCNamesDropDown, 4)
            end
        end)
        
        pcall(function()
            -- Sticky Targeting OFF via Settings NegateBoolean (required on retail)
            FluxDefaultSettings.ApplyStickyTargetingOff()
        end)
        
        pcall(function()
            -- Sticky Targeting OFF via the checkbox value (NegateBoolean).
            FluxDefaultSettings.ApplyStickyTargetingOff()
        end)
        
        pcall(function()
            FluxDefaultSettings.ApplyStickyTargetingOff()
        end)
        
        -- Method 5: Try again after a longer delay
        C_Timer.After(2, function()
            if InCombatLockdown() then return end
            
            pcall(function()
                FluxSetCVar("stickyTargeting", "0") -- Legacy 3.3.5 fix
                
                if InterfaceOptionsDisplayPanelStickyTargeting and InterfaceOptionsDisplayPanelStickyTargeting.GetChecked and InterfaceOptionsDisplayPanelStickyTargeting:GetChecked() then
                    InterfaceOptionsDisplayPanelStickyTargeting:Click()
                end
                if InterfaceOptionsControlsPanelStickyTargeting and InterfaceOptionsControlsPanelStickyTargeting.GetChecked and InterfaceOptionsControlsPanelStickyTargeting:GetChecked() then
                    InterfaceOptionsControlsPanelStickyTargeting:Click()
                end

                 -- NPC Names (Check if unchecked)
                if InterfaceOptionsNamesPanelNPCNames and InterfaceOptionsNamesPanelNPCNames.GetChecked and not InterfaceOptionsNamesPanelNPCNames:GetChecked() then
                    InterfaceOptionsNamesPanelNPCNames:Click()
                end

                 -- Smooth Stacking Nameplates (Check if unchecked)
                if InterfaceOptionsNamePlatesPanelUseSmoothStacking and InterfaceOptionsNamePlatesPanelUseSmoothStacking.GetChecked and not InterfaceOptionsNamePlatesPanelUseSmoothStacking:GetChecked() then
                    FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelUseSmoothStacking)
                end
                
                 -- Stack Friendly Nameplates (Check if unchecked)
                if InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking and InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking.GetChecked and not InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking:GetChecked() then
                    FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelUseFriendlySmoothStacking)
                end

                -- Camera Max Distance Slider (Set to Max)
                if InterfaceOptionsCameraPanelMaxDistanceSlider and InterfaceOptionsCameraPanelMaxDistanceSlider.GetValue and InterfaceOptionsCameraPanelMaxDistanceSlider.GetMinMaxValues then
                    local _, maxVal = InterfaceOptionsCameraPanelMaxDistanceSlider:GetMinMaxValues()
                    if maxVal and InterfaceOptionsCameraPanelMaxDistanceSlider:GetValue() ~= maxVal then
                        InterfaceOptionsCameraPanelMaxDistanceSlider:SetValue(maxVal)
                    end
                end

                -- Always Show Nameplates (Check if unchecked)
                if InterfaceOptionsNamePlatesPanelAlwaysShowNameplates and InterfaceOptionsNamePlatesPanelAlwaysShowNameplates.GetChecked and not InterfaceOptionsNamePlatesPanelAlwaysShowNameplates:GetChecked() then
                    FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelAlwaysShowNameplates)
                end

                -- Combat Only Nameplates (Uncheck if checked)
                if InterfaceOptionsNamePlatesPanelCombatOnly and InterfaceOptionsNamePlatesPanelCombatOnly.GetChecked and InterfaceOptionsNamePlatesPanelCombatOnly:GetChecked() then
                    FluxClickLegacyOptionsCheckbox(InterfaceOptionsNamePlatesPanelCombatOnly)
                end
                -- Singular variant
                if InterfaceOptionNamePlatesPanelCombatOnly and InterfaceOptionNamePlatesPanelCombatOnly.GetChecked and InterfaceOptionNamePlatesPanelCombatOnly:GetChecked() then
                    FluxClickLegacyOptionsCheckbox(InterfaceOptionNamePlatesPanelCombatOnly)
                end
                
                -- NPC Names Dropdown -> All NPCs (ID 4)
                if InterfaceOptionsNamesPanelNPCNamesDropDown and UIDropDownMenu_SetSelectedID then
                     UIDropDownMenu_SetSelectedID(InterfaceOptionsNamesPanelNPCNamesDropDown, 4)
                end
            end)
            pcall(function()
                FluxDefaultSettings.ApplyStickyTargetingOff()
            end)
        end)
    end)
    
    -- Apply Keybinds (has its own combat check)
    FluxDefaultSettings.ApplyKeybinds()

    -- Self cast Auto + focus cast key None (after keybind SaveBindings so modified clicks persist)
    FluxDefaultSettings.ApplySelfCastAndFocusCastDefaults()
    
    -- Apply special CVar settings (sticky targeting, etc.)
    FluxDefaultSettings.ApplySpecialCVarSettings()
    
    -- Apply Raid Frame settings (force profile refresh) - has combat check
    FluxDefaultSettings.ApplyRaidFrameSettings()

    -- Apply Chat Settings (Class Colors)
    FluxDefaultSettings.ApplyChatSettings()
    
    print("|cFF00FFFF[FluxDefaultSettings]|r Defaults applied ("..count.." settings).")
    
    FluxUI_DB.accountDefaultsApplied = true
    
    -- Mark that we just applied CVars (to avoid re-triggering from CVAR_UPDATE)
    FluxDefaultSettings._resetDetection.justAppliedCVars = true
    C_Timer.After(2, function()
        FluxDefaultSettings._resetDetection.justAppliedCVars = false
    end)
end

-- Track last known display size to prevent loops
local lastDisplaySize = nil

-- ---------------------------------------------------------------------------
-- RESET DETECTION STATE (Simplified - keybind detection only)
-- ---------------------------------------------------------------------------
FluxDefaultSettings._resetDetection = {
    justAppliedKeybinds = false,
    justAppliedCVars = false,
    loginGracePeriod = true,  -- Don't trigger during initial login
    isResetting = false,      -- Ignore events while we are applying our own defaults
    postLoginVerified = false, -- VerifyPostLoginDefaults once per login
    settingsCallbacksRegistered = false,
    _applyingKeybinds = false,     -- Re-entrancy guard for ApplyKeybinds batching
    _keybindBatchActive = false,   -- True while clear/template batches are running
    _flushingBindingRefresh = false, -- Allow one-shot flush during suppress window
    _reapplyKeybindsQueued = false,
    _pendingKeybindReapply = false, -- Debounce UPDATE_BINDINGS → ApplyKeybinds
}

-- Apply only CVars without keybindings (for partial reset scenarios)
function FluxDefaultSettings.ApplyCVarsOnly()
    if not FluxUI_DB then FluxUI_DB = {} end
    
    print("|cFF00FFFF[FluxDefaultSettings]|r Re-applying CVar settings (keybindings unchanged)...")
    local count = 0
    
    -- Handlers for Special Cases
    local optimalScale = GetOptimalUIScale()
    FLUX_DEFAULTS["uiscale"] = optimalScale
    FLUX_DEFAULTS["cameraDistanceMaxZoomFactor"] = tostring(FluxDefaultSettings.GetMaxCameraDistanceZoomFactor())
    
    -- CVar changes are safe in combat (nameplates go through ApplyNameplateDefaultsPack only).
    for cvar, value in pairs(FLUX_DEFAULTS) do
        if not FluxSkipCoupledDefaultCVar(cvar) then
            local success = FluxSetCVar(cvar, value)
            if success then
                count = count + 1
            end
        end
    end

    pcall(FluxDefaultSettings.SyncSettingsRegistryProxies)
    FluxDefaultSettings.ScheduleSoftTargetEnemyReassertFromDefaults()
    FluxDefaultSettings.ApplySelfCastAndFocusCastDefaults()
    
    print("|cFF00FFFF[FluxDefaultSettings]|r CVars re-applied ("..count.." settings).")
    
    -- Apply special CVar settings (sticky targeting, etc.)
    FluxDefaultSettings.ApplySpecialCVarSettings()
    
    -- Apply Raid Frame settings (has combat check)
    FluxDefaultSettings.ApplyRaidFrameSettings()
end

-- Initialize / Event Handler — idle after login except Settings reset callbacks + display scale.
local frame = CreateFrame("Frame")
FluxDefaultSettings._eventFrame = frame
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("DISPLAY_SIZE_CHANGED")
frame:RegisterEvent("UI_SCALE_CHANGED")
-- Classic resets cameraDistanceMaxZoomFactor on zone; light PEW reassert only.
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- PLAYER_REGEN_ENABLED armed only via FluxArmPendingCombatFlush when work is queued.
pcall(function()
    frame:RegisterEvent("COMPACT_UNIT_FRAME_PROFILES_LOADED")
end)
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if not FluxUI_DB then FluxUI_DB = {} end
        if not FluxUI_DB.characters then FluxUI_DB.characters = {} end

        local charKey
        if Flux and Flux.PlayerName and Flux.PlayerName.GetCharKey then
            charKey = Flux.PlayerName.GetCharKey("hyphen")
        end
        if not charKey then
            charKey = UnitName("player") .. "-" .. GetRealmName()
        end

        -- Once per **account**: full CVars + proxies + keybinds + raid/chat.
        -- Once per **new character** (account already done): raid frames + chat colors only (no keybind wipe).
        if not FluxUI_DB.accountDefaultsApplied then
            print("|cFF00FFFF[FluxDefaultSettings]|r First login on this account. Applying full defaults (Controls, Interface, Action Bars, Combat, Social, keybindings)...")

            FluxDefaultSettings._resetDetection.loginGracePeriod = true
            FluxDefaultSettings._resetDetection.isResetting = true

            pcall(function() FluxDefaultSettings.Apply() end)

            FluxUI_DB.characters[charKey] = true
            FluxDefaultSettings._resetDetection.isResetting = false
        elseif not FluxUI_DB.characters[charKey] then
            print("|cFF00FFFF[FluxDefaultSettings]|r First login for this character. Applying character-specific defaults...")

            FluxDefaultSettings._resetDetection.loginGracePeriod = true
            FluxDefaultSettings._resetDetection.isResetting = true

            pcall(function() FluxDefaultSettings.ApplyCharacterFirstLogin() end)

            FluxUI_DB.characters[charKey] = true
            FluxDefaultSettings._resetDetection.isResetting = false
        end
        
        if FluxUILayoutSqueeze and FluxUILayoutSqueeze.EnsureDisplayRefreshHooks then
            pcall(FluxUILayoutSqueeze.EnsureDisplayRefreshHooks)
        end

        -- Set grace period to avoid triggering on later login events
        FluxDefaultSettings._resetDetection.loginGracePeriod = true
        FluxDefaultSettings._resetDetection.postLoginVerified = false
        C_Timer.After(5, function()
            FluxDefaultSettings._resetDetection.loginGracePeriod = false
            -- Bindings/CVars may have loaded during grace; UPDATE_BINDINGS was skipped — verify once.
            pcall(FluxDefaultSettings.VerifyPostLoginDefaults)
        end)

        -- Raid/nameplate defaults: first-login Apply / COMPACT_UNIT_FRAME_PROFILES_LOADED /
        -- Settings.CategoryDefaulted only — no per-login After(2)/After(6) timers.

        -- Register EventRegistry callbacks for official Settings reset events (once per session).
        -- Forever / Live queue CVar packs until Settings closes. Settings.SetValue stays off those clients.
        -- Nameplate and raid packs use BlizzardSettings.Write.
        if EventRegistry and not FluxDefaultSettings._resetDetection.settingsCallbacksRegistered then
            FluxDefaultSettings._resetDetection.settingsCallbacksRegistered = true
            FluxEnsureSettingsPanelNameplateFlushHook()

            -- Hook for "Reset All Settings"
            EventRegistry:RegisterCallback("Settings.Defaulted", function()
                local detection = FluxDefaultSettings._resetDetection
                if detection.isResetting or detection.justAppliedCVars then
                    return
                end
                -- Forever / Live: do not write from this callback (Settings previews run as Flux).
                -- Queue the CVar packs and keybinds until the panel closes and combat ends.
                if FluxAvoidBlizzardSettingsCoupling() then
                    print("|cFF00FFFF[FluxDefaultSettings]|r Detected 'Reset All Settings' - Re-applying FluxUI defaults...")
                    detection.isResetting = true
                    BlizzardSettings.Write.Run("resetAll", function()
                        FluxDefaultSettings.ApplyCVarsOnly()
                        FluxDefaultSettings.ApplyKeybinds()
                        FluxDefaultSettings.ApplyChatSettings()
                    end)
                    C_Timer.After(1, function()
                        detection.isResetting = false
                    end)
                    return
                end
                print("|cFF00FFFF[FluxDefaultSettings]|r Detected 'Reset All Settings' - Re-applying FluxUI defaults...")
                detection.isResetting = true
                C_Timer.After(0.1, function()
                    if not InCombatLockdown() then
                        FluxDefaultSettings.Apply(true)
                    else
                        C_Timer.After(2, function()
                            if not InCombatLockdown() then
                                FluxDefaultSettings.Apply(true)
                            end
                        end)
                    end
                    C_Timer.After(1, function()
                        detection.isResetting = false
                    end)
                end)
            end, "FluxDefaultSettings")
            
            -- Hook for "Reset These Settings" (category-specific)
            EventRegistry:RegisterCallback("Settings.CategoryDefaulted", function(_, category)
                local detection = FluxDefaultSettings._resetDetection
                local categoryName = category and category:GetName() or "Unknown"
                print("|cFF00FFFF[FluxDefaultSettings]|r Detected 'Reset These Settings' for: " .. categoryName)
                detection.isResetting = true
                
                -- Check if this is the Keybindings category
                local isKeybindings = false
                if categoryName == "Keybindings" or categoryName == "Key Bindings" then
                    isKeybindings = true
                elseif BINDING_HEADER and categoryName == BINDING_HEADER then
                    isKeybindings = true
                elseif Settings and Settings.KEYBINDINGS_CATEGORY_ID and category and category.GetID and category:GetID() == Settings.KEYBINDINGS_CATEGORY_ID then
                    isKeybindings = true
                end

                local function ReapplyCategory(key, fn)
                    print("|cFF00FFFF[FluxDefaultSettings]|r Re-applying FluxUI " .. key .. "...")
                    local function run()
                        if InCombatLockdown and InCombatLockdown() then
                            BlizzardSettings.Write.Run("resetCategory:" .. key, run)
                            return
                        end
                        pcall(fn)
                        print("|cFF00FFFF[FluxDefaultSettings]|r Applied FluxUI " .. key .. ".")
                    end
                    -- Next frame, while Options is still open, on every client.
                    C_Timer.After(0, run)
                    -- Again after Options closes. Each category keeps its own key.
                    BlizzardSettings.Write.Run("resetCategory:" .. key, run)
                    C_Timer.After(1, function()
                        detection.isResetting = false
                    end)
                end

                -- Nameplates category: Blizzard resets to game defaults; re-apply Flux pack only.
                local isNameplates = false
                if Settings and Settings.NAMEPLATE_OPTIONS_CATEGORY_ID and category and category.GetID
                    and category:GetID() == Settings.NAMEPLATE_OPTIONS_CATEGORY_ID then
                    isNameplates = true
                elseif categoryName == "Nameplates" or categoryName == "Name Plates"
                    or (NAMEPLATE_OPTIONS_LABEL and categoryName == NAMEPLATE_OPTIONS_LABEL)
                    or (NAMEPLATES_LABEL and categoryName == NAMEPLATES_LABEL)
                    or (type(categoryName) == "string" and categoryName:lower():find("nameplate", 1, true)) then
                    isNameplates = true
                end

                local isCombat = false
                if (COMBAT_LABEL and categoryName == COMBAT_LABEL) or categoryName == "Combat" then
                    isCombat = true
                end

                local isActionBars = false
                if Settings and Settings.ACTION_BAR_CATEGORY_ID and category and category.GetID
                    and category:GetID() == Settings.ACTION_BAR_CATEGORY_ID then
                    isActionBars = true
                elseif (ACTIONBARS_LABEL and categoryName == ACTIONBARS_LABEL)
                    or categoryName == "Action Bars" or categoryName == "ActionBars" then
                    isActionBars = true
                end

                local isControls = false
                if (CONTROLS_LABEL and categoryName == CONTROLS_LABEL) or categoryName == "Controls" then
                    isControls = true
                end

                local isInterface = false
                if Settings and Settings.INTERFACE_CATEGORY_ID and category and category.GetID
                    and category:GetID() == Settings.INTERFACE_CATEGORY_ID then
                    isInterface = true
                elseif (INTERFACE_LABEL and categoryName == INTERFACE_LABEL) or categoryName == "Interface" then
                    isInterface = true
                end
                
                if isKeybindings then
                    -- Do NOT wipe bindings here — Blizzard already reset the category.
                    -- Suppress refresh immediately (gap before delayed ApplyKeybinds);
                    -- ApplyKeybinds owns guard lifetime (no early isResetting clear).
                    -- Debounce: ignore duplicate CategoryDefaulted while already applying.
                    if detection._applyingKeybinds or detection._keybindBatchActive or detection.justAppliedKeybinds then
                        return
                    end
                    detection.justAppliedKeybinds = true
                    detection.isResetting = true
                    print("|cFF00FFFF[FluxDefaultSettings]|r Re-applying FluxUI keybindings...")
                    C_Timer.After(0.1, function()
                        if InCombatLockdown() then
                            C_Timer.After(2, function()
                                if not InCombatLockdown() then
                                    FluxDefaultSettings.ApplyKeybinds()
                                end
                            end)
                        else
                            FluxDefaultSettings.ApplyKeybinds()
                        end
                    end)
                elseif isNameplates then
                    ReapplyCategory("nameplate defaults", function()
                        BlizzardSettings.Nameplates.ApplyNow(true)
                    end)
                elseif isCombat then
                    ReapplyCategory("combat defaults", function()
                        FluxDefaultSettings.ApplyCombatDefaultsPack(true)
                    end)
                elseif isActionBars then
                    ReapplyCategory("action bar defaults", function()
                        FluxDefaultSettings.ApplyActionBarDefaultsPack(true)
                    end)
                elseif isControls then
                    ReapplyCategory("controls defaults", function()
                        FluxDefaultSettings.ApplyControlsDefaultsPack(true)
                    end)
                elseif isInterface then
                    ReapplyCategory("interface defaults", function()
                        BlizzardSettings.Raid.ApplyNow(true)
                    end)
                else
                    ReapplyCategory("defaults", function()
                        FluxDefaultSettings.ApplyCVarsOnly()
                    end)
                end
            end, "FluxDefaultSettings")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Classic (and some retail loads) clamp camera zoom on zone; re-assert max only if needed.
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                pcall(FluxDefaultSettings.ApplyMaxCameraDistance, false)
            end)
        else
            pcall(FluxDefaultSettings.ApplyMaxCameraDistance, false)
        end
    elseif event == "COMPACT_UNIT_FRAME_PROFILES_LOADED" then
        -- Finish a raid profile write that ran before Blizzard's profiles existed.
        C_Timer.After(0.5, function()
            BlizzardSettings.Raid.OnProfilesLoaded()
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        if FluxDefaultSettings._pendingStickyTargeting then
            FluxDefaultSettings._pendingStickyTargeting = false
            pcall(FluxDefaultSettings.ApplyStickyTargetingOff)
        end
        local detection = FluxDefaultSettings._resetDetection
        if detection and detection._pendingKeybindReapply then
            detection._pendingKeybindReapply = false
            pcall(FluxDefaultSettings.ApplyKeybinds)
        end
        if FluxDefaultSettings._pendingSoftTargetReassert then
            FluxDefaultSettings.ReassertSoftTargetEnemyFromDefaults()
        end
        if self.pendingScaleUpdate then
            self.pendingScaleUpdate = false
            local optimalScale = GetOptimalUIScale()
            local currentScale = GetCVar("uiScale")
            local currentUse = GetCVar("useUIScale")
            local numOpt = tonumber(optimalScale)
            local numCur = tonumber(currentScale)
            if (currentUse ~= "1") or (numOpt and numCur and math.abs(numOpt - numCur) > 0.005) then
                pcall(function()
                    FluxSetCVar("useUIScale", "1")
                    FluxSetCVar("uiscale", optimalScale)
                end)
                print("|cFF00FFFF[FluxDefaultSettings]|r Display changed - UI scale adjusted to " .. optimalScale)
            end
        end
        if self.pendingSqueezeRefresh then
            self.pendingSqueezeRefresh = false
            if FluxUILayoutSqueeze and FluxUILayoutSqueeze.RequestRefresh then
                pcall(FluxUILayoutSqueeze.RequestRefresh, "post_combat")
            end
        end
        FluxDisarmPendingCombatFlushIfIdle()
    elseif event == "UI_SCALE_CHANGED" then
        if FluxUILayoutSqueeze and FluxUILayoutSqueeze.RequestRefresh then
            FluxUILayoutSqueeze.RequestRefresh("ui_scale")
        end
    elseif event == "DISPLAY_SIZE_CHANGED" then
        if FluxUILayoutSqueeze and FluxUILayoutSqueeze.RequestRefresh then
            FluxUILayoutSqueeze.RequestRefresh("display_size")
        end
        local width, height = GetPhysicalScreenSize()
        local currentSize = width .. "x" .. height
        if lastDisplaySize == currentSize then
            return
        end
        lastDisplaySize = currentSize
        C_Timer.After(0.5, function()
            if InCombatLockdown() then
                self.pendingScaleUpdate = true
                self.pendingSqueezeRefresh = true
                FluxArmPendingCombatFlush()
                print("|cFF00FFFF[FluxDefaultSettings]|r Combat detected - UI scale update queued.")
                return
            end
            local optimalScale = GetOptimalUIScale()
            local currentScale = GetCVar("uiScale")
            local currentUse = GetCVar("useUIScale")
            local numOpt = tonumber(optimalScale)
            local numCur = tonumber(currentScale)
            if (currentUse ~= "1") or (numOpt and numCur and math.abs(numOpt - numCur) > 0.005) then
                local success = pcall(function()
                    FluxSetCVar("useUIScale", "1")
                    FluxSetCVar("uiscale", optimalScale)
                end)
                if success then
                    print("|cFF00FFFF[FluxDefaultSettings]|r Display changed - UI scale adjusted to " .. optimalScale)
                end
            end
            if FluxUILayoutSqueeze and FluxUILayoutSqueeze.RequestRefresh then
                FluxUILayoutSqueeze.RequestRefresh("display_size_settled")
            end
        end)
    -- UPDATE_BINDINGS: do NOT auto-reapply Flux keybinds here.
    -- Changing a single key in Settings fires this event; the old F5-sentinel
    -- treated that as a full reset and wiped user binds (and looped after Defaults).
    -- Keybind re-apply is only: explicit Defaults actions / slash / first account setup.
    end
end)

-- Print debug info
function FluxDefaultSettings.PrintDebug()
    local state, info = FluxDefaultSettings.GetState()
    local charKey
    if Flux and Flux.PlayerName and Flux.PlayerName.GetCharKey then
        charKey = Flux.PlayerName.GetCharKey("hyphen")
    end
    if not charKey then
        charKey = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
    end
    local charSeen = FluxUI_DB and FluxUI_DB.characters and FluxUI_DB.characters[charKey]
    print("|cFF00FFFF[FluxDefaultSettings]|r State: " .. state)
    print("  Account defaults applied: " .. tostring(FluxUI_DB and FluxUI_DB.accountDefaultsApplied or false))
    print("  This character in saved first-login list: " .. tostring(charSeen or false) .. " (" .. charKey .. ")")
    if #info > 0 then
        print("  Differences found:")
        for _, diff in ipairs(info) do
            print("    - " .. diff)
        end
    end
end

-- Register Slash Command extensions
SLASH_FLUXDEFAULTS1 = "/fluxdefaults"
SlashCmdList["FLUXDEFAULTS"] = function(msg)
    msg = type(msg) == "string" and msg:match("^%s*(.-)%s*$") or ""
    if msg == "apply" or msg == "force" then
        FluxDefaultSettings.Apply(true)
    elseif msg == "keybinds" then
        FluxDefaultSettings.ApplyKeybinds()
    elseif msg == "cvars" then
        FluxDefaultSettings.ApplyCVarsOnly()
    elseif msg == "reset" then
        if FluxUI_DB then FluxUI_DB.accountDefaultsApplied = false end
        print("|cFF00FFFF[FluxDefaultSettings]|r Account defaults flag cleared. Use |cFFFFFFFF/fluxdefaults apply|r to apply full defaults now, or relog on a character that has never received account defaults.")
        print("|cFF00FFFF[FluxDefaultSettings]|r Characters already marked as seen are unchanged; use |cFFFFFFFF/fluxdefaults resetchar|r so this character can run character-only defaults on next login.")
    elseif msg == "resetchar" then
        if not FluxUI_DB then FluxUI_DB = {} end
        if not FluxUI_DB.characters then FluxUI_DB.characters = {} end
        local charKey
        if Flux and Flux.PlayerName and Flux.PlayerName.GetCharKey then
            charKey = Flux.PlayerName.GetCharKey("hyphen")
        end
        if not charKey then
            charKey = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
        end
        FluxUI_DB.characters[charKey] = nil
        print("|cFF00FFFF[FluxDefaultSettings]|r Cleared first-login flag for |cFFFFFFFF" .. charKey .. "|r. Next login runs character-only defaults (raid frames + chat colors).")
    else
        FluxDefaultSettings.PrintDebug()
        print("Usage: |cFFFFFFFF/fluxdefaults [apply|force|keybinds|cvars|reset|resetchar]|r")
    end
end
