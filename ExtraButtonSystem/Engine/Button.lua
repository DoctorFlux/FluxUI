--[[
    ExtraButtonSystem/Engine/Button.lua
    FluxButton class with full functionality
    Based on FluxButton.lua and ButtonForge patterns
    Uses FLUX_API for cross-version compatibility
]]

-- Create FluxButton namespace
if not FluxButton then
    FluxButton = {}
end

local FluxButton = FluxButton
FluxButton.__index = FluxButton

-- Button states
FluxButton.BUTTON_STATE_NORMAL = "NORMAL"
FluxButton.BUTTON_STATE_PUSHED = "PUSHED"
FluxButton.BUTTON_STATE_DISABLED = "DISABLED"

-- Empty slot visuals
local EMPTY_SLOT_TEXTURE = "Interface\\Buttons\\UI-EmptySlot-Disabled"
local EMPTY_SLOT_ALPHA = 0.85

-- Stealth spell IDs (like ButtonForge)
FluxButton.StealthSpellIds = {
    [1784] = 1,  -- Stealth
    [5215] = 1,  -- Prowl
}

-- Single-Button Assistant spell ID (rotation helper)
FluxButton.SINGLE_BUTTON_ASSISTANT_ID = 1229376

-- Match Blizzard ActionBarButtonAssistedCombatRotationFrameMixin:OnLoad (Blizzard_ActionBar/Shared/ActionButton.lua)
local SINGLE_BUTTON_ASSISTANT_OVERLAY_SCALE = 1.4
local SINGLE_BUTTON_ASSISTANT_OVERLAY_ANCHOR_X = -2
local SINGLE_BUTTON_ASSISTANT_OVERLAY_ANCHOR_Y = 1

-- API compatibility helpers
local function HasC_Spell()
    return FLUX_API and FLUX_API.hasC_Spell
end

local function HasC_Item()
    return FLUX_API and FLUX_API.hasC_Item
end

local function IsLegacyClient()
    return FLUX_API and FLUX_API.isLegacyClient
end

-- Safe pickup wrappers
local function SafePickupSpell(spellIdentifier)
    -- Modern Retail API (preferred)
    if C_Spell and type(C_Spell.PickupSpell) == "function" then
        local success = pcall(C_Spell.PickupSpell, spellIdentifier)
        return success
    end
    -- Fallback to global API for Classic compatibility
    if _G.PickupSpell and type(_G.PickupSpell) == "function" then
        local success = pcall(_G.PickupSpell, spellIdentifier)
        return success
    end
    return false
end

local function SafePickupItem(itemIdentifier)
    if _G.PickupItem and type(_G.PickupItem) == "function" then
        local success = pcall(_G.PickupItem, itemIdentifier)
        return success
    end
    return false
end

local function SafePickupMacro(macroIndex)
    if _G.PickupMacro and type(_G.PickupMacro) == "function" then
        local success = pcall(_G.PickupMacro, macroIndex)
        return success
    end
    return false
end

-- Flyout spell book lookup helper
-- Caches spell book data to find flyouts by ID (like old FluxButton)
function FluxButton:LookupFlyoutIndex(flyoutID)
    if not flyoutID or not C_SpellBook then return nil, nil end
    
    -- Cache spell book data on first call
    if not FluxButton.SpellBookCache then
        FluxButton.SpellBookCache = {}
        
        -- Safety check for required APIs
        if not (C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemInfo) then
            return nil, nil
        end
        
        -- Safety check for Enum
        if not (Enum and Enum.SpellBookSpellBank and Enum.SpellBookItemType) then
            return nil, nil
        end
        
        -- Iterate spell book to find all flyouts
        for skillLineIndex = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
            if skillLineInfo then
                for i = 1, (skillLineInfo.numSpellBookItems or 0) do
                    local slotIndex = (skillLineInfo.itemIndexOffset or 0) + i
                    local spellBookItemInfo = C_SpellBook.GetSpellBookItemInfo(slotIndex, Enum.SpellBookSpellBank.Player)
                    if spellBookItemInfo and spellBookItemInfo.itemType == Enum.SpellBookItemType.Flyout then
                        FluxButton.SpellBookCache[spellBookItemInfo.actionID] = {
                            index = slotIndex,
                            bank = Enum.SpellBookSpellBank.Player
                        }
                    end
                end
            end
        end
    end
    
    local cached = FluxButton.SpellBookCache[flyoutID]
    return cached and cached.index, cached and cached.bank
end

-- Create a new button instance
function FluxButton.New(parent, config)
    local self = setmetatable({}, FluxButton)
    
    -- Set default click behavior
    if config and not config.clickBehavior then
        config.clickBehavior = "AnyUp"
    end
    
    -- Create the core button widget
    local coreButton = FluxButtonCore.CreateButton(parent, config)
    if not coreButton then
        return nil
    end

    -- Pre-DF cast/reticle VFX: register immediately (also bootstrapped later via Core wrap).
    if coreButton.Widget and _G.FluxPreDFVFX_RegisterExtraButton then
        pcall(_G.FluxPreDFVFX_RegisterExtraButton, coreButton.Widget)
    end
    if coreButton.Widget and _G.FluxEffectGlow and _G.FluxEffectGlow.InstallSAO then
        pcall(_G.FluxEffectGlow.InstallSAO, coreButton.Widget)
    end
    
    -- Copy all core button widget properties
    self.Widget = coreButton.Widget
    self.WIcon = coreButton.WIcon
    self.WNormalTexture = coreButton.WNormalTexture
    self.WCooldown = coreButton.WCooldown
    self.WCount = coreButton.WCount
    self.WBorder = coreButton.WBorder
    self.WFlashTexture = coreButton.WFlashTexture
    self.WHotKey = coreButton.WHotKey
    self.WName = coreButton.WName
    
    -- Tighten visuals
    if self.Widget and self.Widget.SetHitRectInsets then
        self.Widget:SetHitRectInsets(0, 0, 0, 0)
    end
    if self.WIcon then
        self.WIcon:ClearAllPoints()
        self.WIcon:SetPoint("TOPLEFT", self.Widget, "TOPLEFT", 0, 0)
        self.WIcon:SetPoint("BOTTOMRIGHT", self.Widget, "BOTTOMRIGHT", 0, 0)
        self.WIcon:SetTexCoord(0, 1, 0, 1)
        -- Preserve lower-rank colorless + empty-slot placeholder gray:
        -- later SetDesaturated(false) from usable/rank passes must not wipe.
        if not self.WIcon._fluxRankDesatGuard then
            self.WIcon._fluxRankDesatGuard = true
            local owner = self
            hooksecurefunc(self.WIcon, "SetDesaturated", function(tex, desat)
                if tex ~= owner.WIcon then return end
                if desat then return end
                if owner._fluxRankDesaturated then
                    tex:SetDesaturated(true)
                elseif owner.PlaceholderTexture and not owner.IsWispLockPlaceholder then
                    tex:SetDesaturated(true)
                end
            end)
        end
    end
    
    -- Hide ring border initially (will be shown via FluxButtonUtil when needed)
    -- This matches old version behavior where border is hidden by default
    if self.WNormalTexture then
        self.WNormalTexture:SetAlpha(0)
    end
    
    -- Empty-slot background (hidden by default)
    local emptyBG = self.Widget:CreateTexture(nil, "BACKGROUND", nil, -8)
    emptyBG:SetTexture(EMPTY_SLOT_TEXTURE)
    emptyBG:SetPoint("CENTER", self.Widget, "CENTER")
    emptyBG:SetSize((self.Widget:GetWidth() or 32) * 1.5, (self.Widget:GetHeight() or 32) * 1.5)
    emptyBG:Hide()
    self.WEmptyBG = emptyBG
    
    -- Initialize button configuration
    self.ActionType = nil
    self.ActionValue = nil
    self.ButtonLocked = config and config.locked or false
    self.TooltipEnabled = not (config and config.tooltip == false)
    self.MacroTextEnabled = not (config and config.macroText == false)
    self.KeyBindTextEnabled = not (config and config.keyBindText == false)
    self.UseClassColor = config and config.useClassColor
    
    -- Placeholder support
    self.PlaceholderTexture = nil
    self.PlaceholderLabel = nil
    
    -- Set up event handlers
    self:SetupEvents()
    
    -- Create back-reference
    self.Widget.FluxButton = self
	
	return self
end

-- Set up event handlers
function FluxButton:SetupEvents()
    local widget = self.Widget
    
    -- Mouse interaction events
    widget:SetScript("OnEnter", function(w) self:OnEnter() end)
    widget:SetScript("OnLeave", function(w) self:OnLeave() end)
    widget:SetScript("OnShow", function(w) self:OnShow() end)
    widget:SetScript("OnHide", function(w) self:OnHide() end)
    widget:SetScript("OnMouseDown", function(w, button) self:OnMouseDown(button) end)
    widget:SetScript("OnMouseUp", function(w, button) self:OnMouseUp(button) end)
    
    -- Drag and drop events
    widget:SetScript("OnDragStart", function(w, button) self:OnDragStart(button) end)
    widget:SetScript("OnReceiveDrag", function(w) self:OnReceiveDrag() end)
    widget:SetScript("OnDragStop", function(w) self:OnDragStop() end)
    
    -- Click processing events
    -- Helper: Check if button should never be checked (empty or equipment set)
    local function shouldNeverBeChecked()
        return (not self.ActionType or not self.ActionValue) or (self.ActionType == "equipmentset") or self.IgnoreCheckedVisual
    end
    
    widget:SetScript("PostClick", function(w, button, down)
        -- Handle cursor item drop first (click-to-drop functionality)
        if not InCombatLockdown() and not down and w._hasCursorItem then
            -- Restore button type
            if w._backupType then
                w:SetAttribute("type", w._backupType)
                w:SetAttribute("typerelease", w._backupTypeRelease or w._backupType)
            end
            w._backupType = nil
            w._backupTypeRelease = nil
            w._hasCursorItem = nil
            
            -- Process the drop
        self:OnReceiveDrag()
        end
        
        if self.PostClick then self:PostClick(button, down) end
        -- Force unchecked for empty buttons and equipment sets after any click
        if shouldNeverBeChecked() then
            if w.SetChecked then
                w:SetChecked(false)
            end
            local checkedTexture = w:GetCheckedTexture()
            if checkedTexture then
                checkedTexture:Hide()
            end
        end
        
        -- FLYOUT INTEGRATION: Check for /flyout macro command on left click
        -- Based on old working FluxCustomFlyout.lua: always parse macro on-the-fly when clicked
        if not down and button == "LeftButton" then
            if FluxFlyout and self.ActionType == "macro" then
                -- Get macro body - either stored on button or fetch from macro index
                local macroBody = self.MacroBody
                if not macroBody and self.MacroIndex then
                    local _, _, body = GetMacroInfo(self.MacroIndex)
                    macroBody = body
                end
                
                if macroBody then
                    -- NOTE: Do NOT execute macro via ChatEdit_SendText - the SecureActionButton
                    -- already runs the macro on click. Re-executing via chat causes ADDON_ACTION_FORBIDDEN.
                    -- Always parse and show flyout directly (like old FluxCustomFlyout did)
                    if FluxFlyout.ShowForMacroBody then
                        FluxFlyout.ShowForMacroBody(w, macroBody)
                    end
                end
            end
        end

        -- ButtonForge parity for macro checked visuals:
        -- non spell/item macros should never stay checked after click.
        -- Force a checked-state recompute right after macro execution so
        -- macros without /cast or /use clear immediately.
        if not down and self.ActionType == "macro" and self.UpdateChecked then
            self:UpdateChecked()
            if C_Timer and C_Timer.After then
                C_Timer.After(0.02, function()
                    if self and self.Widget and self.UpdateChecked then
                        self:UpdateChecked()
                    end
                end)
            end
        end
    end)
    
    widget:SetScript("PreClick", function(w, button, down)
        if self.PreClick then self:PreClick(button, down) end

        -- ButtonForge guard: keybind clicks must never blank type.
        if button == "KeyBind" or button == "ConjureBind" then
            return
        end

        -- Forever has no wrap: click-to-drop is the secure handler with a cursor.
        local Click = Flux.ButtonFX and Flux.ButtonFX.Click
        if Click and Click.UsesWrap and not Click.UsesWrap() then
            return
        end

        -- Check if there's something on cursor - if so, disable button action temporarily
        if not InCombatLockdown() and not down then
            local cursorType = GetCursorInfo()
            if cursorType then
                -- Store original button type and disable action
                w._backupType = w:GetAttribute("type")
                w._backupTypeRelease = w:GetAttribute("typerelease")
                w:SetAttribute("type", "")
                w:SetAttribute("typerelease", "")
                w._hasCursorItem = true
            end
        end
    end)
    
    -- Hook OnClick to immediately force unchecked state for empty buttons and equipment sets
    widget:HookScript("OnClick", function(w)
        if shouldNeverBeChecked() then
            if w.SetChecked then
                w:SetChecked(false)
            end
            local checkedTexture = w:GetCheckedTexture()
            if checkedTexture then
                checkedTexture:Hide()
            end
        end
    end)
    
    -- Hook OnMouseUp as additional safeguard for empty buttons and equipment sets
    widget:HookScript("OnMouseUp", function(w)
        if shouldNeverBeChecked() then
            if w.SetChecked then
                w:SetChecked(false)
            end
            local checkedTexture = w:GetCheckedTexture()
            if checkedTexture then
                checkedTexture:Hide()
            end
            -- Also use a timer as backup
            C_Timer.After(0.01, function()
                if w and w.SetChecked then
                    w:SetChecked(false)
                end
                local tex = w and w:GetCheckedTexture()
                if tex then
                    tex:Hide()
        end
    end)
        end
    end)

    -- Override SetChecked to prevent checked state on empty buttons and equipment sets.
    -- Action-bar badges: Exclusive may SetChecked(true) while ActionType briefly lags —
    -- honor _fluxSuppressCheckedHook / live SpellId so the ring can land on the badge.
    local originalSetChecked = widget.SetChecked
    widget.SetChecked = function(w, checked)
        local suppress = w._fluxSuppressCheckedHook or self._fluxSuppressCheckedHook
        if checked and suppress then
            originalSetChecked(w, true)
            return
        end
        local ov = _G.Flux and _G.Flux.ButtonFX and _G.Flux.ButtonFX.Overlay
        if ov and ov.IsCheckedSuppressed and ov.IsCheckedSuppressed(w) then
            originalSetChecked(w, false)
            local checkedTexture = w.GetCheckedTexture and w:GetCheckedTexture()
            if checkedTexture then
                checkedTexture:Hide()
            end
            return
        end
        if shouldNeverBeChecked() then
            if self._fluxIsActionBarBadge and checked and type(self.SpellId) == "number" and self.SpellId > 0 then
                originalSetChecked(w, true)
                return
            end
            originalSetChecked(w, false)
            local checkedTexture = w:GetCheckedTexture()
            if checkedTexture then
                checkedTexture:Hide()
            end
        else
            originalSetChecked(w, checked)
        end
    end
    
    -- Create flyout arrow on the widget for the flyout system
    if FluxFlyoutFrame and FluxFlyoutFrame.CreateArrow then
        FluxFlyoutFrame.CreateArrow(widget)
    end
    
    -- Mark this button as being an ExtraButton for direction detection
    self._isExtraButton = true
end

-- Clear all action data from the button
function FluxButton:ClearAction()
    self.ActionType = nil
    self.ActionValue = nil
    self.SpellId = nil
    self.SpellName = nil
    self.SpellNameRank = nil
    self.ItemId = nil
    self.ItemName = nil
    self.ItemLink = nil
    self.MacroName = nil
    self.MacroBody = nil -- Also clear macro body
    self.MacroText = nil
    self.MacroShowTooltip = nil
    self.HideMacroName = nil
    self.EquipmentSetName = nil
    self.EquipmentSetId = nil
    self.FlyoutId = nil
    
    -- Clear forced count
    self._forcedCount = nil
    
    -- Clear visual elements
    if self.WIcon then self.WIcon:SetTexture(nil) end
    if self.WCount then
        self.WCount:Show()
        self.WCount:SetText("")
    end
    if self.WCooldown then self.WCooldown:Hide() end
    
    -- Reset attributes if safe
    if not InCombatLockdown() and self.Widget then
        self.Widget:SetAttribute("type", nil)
        self.Widget:SetAttribute("spell", nil)
        self.Widget:SetAttribute("spell2", nil)
        self.Widget:SetAttribute("item", nil)
        self.Widget:SetAttribute("macro", nil)
        self.Widget:SetAttribute("macrotext", nil)
        self.Widget:SetAttribute("type2", nil)
        self.Widget:SetAttribute("macrotext2", nil)
    end
    -- Craft RC memo must not survive a wipe of macrotext2 (placeholder / empty slot).
    self._fluxCraftBindKey = nil
end

-- Local helpers for macro directive parsing (mirrors ButtonForge SetEnvMacro)
local function MacroBodyHasShowTooltip(body)
    if type(body) ~= "string" then return false end
    -- Match #showtooltip at start of any line (case-insensitive).
    -- Lua patterns lack alternation, so match start-of-string and \n separately.
    if body:lower():find("^#showtooltip") then return true end
    if body:lower():find("\n#showtooltip") then return true end
    return false
end

local function MacroBodyHasNoName(body)
    if type(body) ~= "string" then return false end
    if body:lower():find("^#noname") then return true end
    if body:lower():find("\n#noname") then return true end
    return false
end

--- True when body has [mod:] / [nomod] so mod-edge TranslateMacro is required.
local function MacroBodyHasModConditional(body)
    if type(body) ~= "string" or body == "" then return false end
    local lower = body:lower()
    return lower:find("[mod", 1, true) ~= nil
        or lower:find("[nomod", 1, true) ~= nil
end

--- True when body has stance/form/bonusbar/actionbar/stealth/vehicle conditionals
--- that must retranslate on shapeshift (skip unrelated macros during form storms).
local function MacroBodyHasStanceConditional(body)
    if type(body) ~= "string" or body == "" then return false end
    local lower = body:lower()
    return lower:find("[form", 1, true) ~= nil
        or lower:find("[stance", 1, true) ~= nil
        or lower:find("[bonusbar", 1, true) ~= nil
        or lower:find("[actionbar", 1, true) ~= nil
        or lower:find("[stealth", 1, true) ~= nil
        or lower:find("[nostealth", 1, true) ~= nil
        or lower:find("[vehicleui", 1, true) ~= nil
        or lower:find("[possessbar", 1, true) ~= nil
end

local function UpdateHasModConditional(self, body)
    self._fluxHasModConditional = MacroBodyHasModConditional(body) and true or false
    if type(body) == "string" and body ~= "" then
        self._fluxHasMouseoverConditional = body:lower():find("@mouseover", 1, true) ~= nil
    else
        self._fluxHasMouseoverConditional = false
    end
end

local function UpdateHasStanceConditional(self, body)
    self._fluxHasStanceConditional = MacroBodyHasStanceConditional(body) and true or false
end

-- Strip every line whose first non-whitespace character is '#' from a macro body.
-- Used when forwarding inline macrotext to the secure attribute, to prevent
-- modern C_Macro.RunMacroText from speaking unrecognized header lines like
-- '#showtooltip' in /say.
local function StripMacroDirectives(body)
    if type(body) ~= "string" or body == "" then return body end
    local lines = {}
    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        local trimmed = line:gsub("^%s+", "")
        if trimmed:sub(1, 1) ~= "#" then
            lines[#lines + 1] = line
        end
    end
    -- Trim a trailing newline left over from the gmatch padding
    local result = table.concat(lines, "\n")
    return result
end

-- Resolve a macro identifier (number or name) to a numeric index.
-- Returns nil if it cannot be resolved or is out of range.
local function ResolveMacroIndex(value)
    if type(value) == "number" then
        if value >= 1 and GetMacroInfo and GetMacroInfo(value) then
            return value
        end
        return nil
    end
    if type(value) == "string" and value ~= "" then
        local idx = GetMacroIndexByName and GetMacroIndexByName(value)
        if idx and idx > 0 then return idx end
    end
    return nil
end

-- Set the button's action
function FluxButton:SetAction(actionType, actionValue)
    -- Clear placeholder state
    self.PlaceholderTexture = nil
    self.PlaceholderLabel = nil
    self.ActionType = actionType
    self.ActionValue = actionValue
    
    -- Handle special action types
    if actionType == "macro" and actionValue then
        -- Validate / resolve to a numeric macro index (drag-and-drop and
        -- saved buttons may pass either a number or a macro name).
        local index = ResolveMacroIndex(actionValue)
        if not index then
            -- Macro disappeared (deleted/renamed): clear the slot rather than
            -- leaving a stale secure binding.
            self:ClearAction()
            return
        end

        local macroName, _, macroBody = GetMacroInfo(index)
        self.MacroIndex = index
        self.MacroName = macroName
        self.MacroBody = macroBody
        -- NOTE: name is MacroShowTooltip (not ShowTooltip) because
        -- FluxButton:ShowTooltip is an existing instance method; setting a
        -- boolean field with the same name would shadow it on the instance.
        self.MacroShowTooltip = MacroBodyHasShowTooltip(macroBody)
        self.HideMacroName = MacroBodyHasNoName(macroBody)
        UpdateHasModConditional(self, macroBody)
        UpdateHasStanceConditional(self, macroBody)
        -- Forward the resolved numeric index to Core so the secure handler
        -- writes SetAttribute("macro", index) and the click runs RunMacro(index)
        -- (which strips '#' header lines correctly).
        actionType = "macro"
        actionValue = index
        self.ActionValue = index
        self:InvalidateTranslateMacroCache()
        self:TranslateMacro()
        if FluxButtonEvents and FluxButtonEvents.RefreshMouseoverMacroMembership then
            FluxButtonEvents.RefreshMouseoverMacroMembership(self)
        end
        
    elseif actionType == "macrotext" and actionValue then
        -- Inline macrotext (no stored macro index). Compute ShowTooltip from
        -- the ORIGINAL body so '#showtooltip' still drives the tooltip, then
        -- strip every '#' line before forwarding the body to the secure
        -- attribute. Without stripping, modern C_Macro.RunMacroText will
        -- speak unrecognized header lines as /say.
        local originalBody = actionValue
        local cleanedBody = StripMacroDirectives(originalBody)

        self.MacroName = self.MacroName or "Macro"
        self.MacroBody = cleanedBody
        self.MacroIndex = nil
        self.MacroShowTooltip = MacroBodyHasShowTooltip(originalBody)
        self.HideMacroName = MacroBodyHasNoName(originalBody)
        UpdateHasModConditional(self, originalBody)
        UpdateHasStanceConditional(self, originalBody)
        self.ActionType = "macro"
        actionValue = cleanedBody
        self:InvalidateTranslateMacroCache()
        self:TranslateMacro()
        if FluxButtonEvents and FluxButtonEvents.RefreshMouseoverMacroMembership then
            FluxButtonEvents.RefreshMouseoverMacroMembership(self)
        end
        
    elseif actionType == "flyout" and actionValue then
        self.FlyoutId = actionValue
        -- Get flyout texture from spell book
        local flyoutIndex, flyoutBank = self:LookupFlyoutIndex(actionValue)
        if flyoutIndex and flyoutBank and C_SpellBook and C_SpellBook.GetSpellBookItemTexture then
            self.Texture = C_SpellBook.GetSpellBookItemTexture(flyoutIndex, flyoutBank) or "Interface/Icons/INV_Misc_QuestionMark"
        else
            self.Texture = "Interface/Icons/INV_Misc_QuestionMark"
        end
        self:ClearMacroData()
        self:ClearSpellData()
        
    elseif actionType == "spell" and actionValue then
        -- Clear any previous Single-Button Assistant state
        self:ClearSingleButtonAssistant()
        
        -- Check if this is the Single-Button Assistant spell
        if actionValue == FluxButton.SINGLE_BUTTON_ASSISTANT_ID then
            self.IsSingleButtonAssistant = true
            -- Set up overlay and OnUpdate for dynamic spell tracking
            self:SetupSingleButtonAssistantOverlay()
            self:SetupSingleButtonAssistantOnUpdate()
        else
            self.IsSingleButtonAssistant = false
        end
        
        -- Spell identity: keep rank-specific SpellId; cast attribute set by Core.SetButtonAction
        -- as Name(Rank N) on classic (never bare name / FindBaseSpell rewrite).
        local castAttr = (FluxButtonCore and FluxButtonCore.FormatSpellCastAttribute
            and FluxButtonCore.FormatSpellCastAttribute(actionValue))
            or (_G.FluxFormatSpellCastAttribute and _G.FluxFormatSpellCastAttribute(actionValue))

        if HasC_Spell() and C_Spell.GetSpellInfo then
            local spellInfo = C_Spell.GetSpellInfo(actionValue)
            if spellInfo then
                self.SpellName = spellInfo.name
                self.SpellNameRank = (type(castAttr) == "string" and castAttr) or spellInfo.name
                self.SpellId = actionValue
                -- CRITICAL: Set spellID on widget for ActionButton_UpdateCooldown safety
                -- If ActionButton_UpdateCooldown gets called, having widget.spellID set makes it
                -- use the safe C_Spell path instead of crashing C_ActionBar path
                if self.Widget then
                    self.Widget.spellID = actionValue
                end
                if C_Spell.GetSpellTexture then
                    self.Texture = C_Spell.GetSpellTexture(actionValue) or "Interface/Icons/INV_Misc_QuestionMark"
                end
            end
        elseif GetSpellInfo then
            local name, _, icon = GetSpellInfo(actionValue)
            self.SpellName = name
            self.SpellNameRank = (type(castAttr) == "string" and castAttr) or name
            self.SpellId = actionValue
            -- CRITICAL: Set spellID on widget for ActionButton_UpdateCooldown safety
            if self.Widget then
                self.Widget.spellID = actionValue
            end
            self.Texture = icon or "Interface/Icons/INV_Misc_QuestionMark"
        end
        self:ClearMacroData()
        
    elseif actionType == "item" and actionValue then
        local itemName, itemLink = GetItemInfo(actionValue)
        self.ItemId = actionValue
        self.ItemName = itemName
        self.ItemLink = itemLink
        self.Texture = GetItemIcon(actionValue) or "Interface/Icons/INV_Misc_QuestionMark"
        self:ClearMacroData()
        -- CRITICAL: Set widget.spellID for ActionButton_UpdateCooldown safety
        -- Items may have associated spells - use that spell ID
        if self.Widget then
            local itemSpellID = nil
            if C_Item and C_Item.GetItemSpell then
                local _, spellID = C_Item.GetItemSpell(actionValue)
                itemSpellID = spellID
            elseif GetItemSpell then
                local _, _, spellID = GetItemSpell(actionValue)
                itemSpellID = spellID
            end
            self.Widget.spellID = itemSpellID
        end
        -- Don't call ClearSpellData() as it would clear widget.spellID we just set
        self.SpellName = nil
        self.SpellNameRank = nil
        self.SpellId = nil
        self.FlyoutId = nil
        
    elseif actionType == "mount" and actionValue then
        if C_MountJournal and C_MountJournal.GetMountInfoByID then
            local mountName, mountSpellID, mountIcon = C_MountJournal.GetMountInfoByID(actionValue)
            self.MountName = mountName
            self.MountSpellId = mountSpellID
            self.Texture = mountIcon or "Interface/Icons/INV_Misc_QuestionMark"
            -- CRITICAL: Set widget.spellID for ActionButton_UpdateCooldown safety
            -- Mount spells have spell IDs, so use that
            if self.Widget and mountSpellID then
                self.Widget.spellID = mountSpellID
            end
        end
        self:ClearMacroData()
        -- Don't call ClearSpellData() as it would clear widget.spellID we just set
        self.SpellName = nil
        self.SpellNameRank = nil
        self.SpellId = nil
        self.FlyoutId = nil
        
    elseif actionType == "battlepet" and actionValue then
        if C_PetJournal and C_PetJournal.GetPetInfoByPetID then
            local _, _, _, _, _, _, _, petName, petIcon = C_PetJournal.GetPetInfoByPetID(actionValue)
            self.PetName = petName
            self.Texture = petIcon or "Interface/Icons/INV_Misc_QuestionMark"
        end
        self:ClearMacroData()
        -- Battle pets don't have spell IDs, but clear for consistency
        self.SpellName = nil
        self.SpellNameRank = nil
        self.SpellId = nil
        self.FlyoutId = nil
        if self.Widget then
            self.Widget.spellID = nil
        end
        
    elseif actionType == "toy" and actionValue then
        -- Toys are items, get their spell ID
        local _, itemName, itemIcon = C_ToyBox and C_ToyBox.GetToyInfo(actionValue)
        self.ToyId = actionValue
        self.ItemId = actionValue
        self.ItemName = itemName
        self.Texture = itemIcon or "Interface/Icons/INV_Misc_QuestionMark"
        self:ClearMacroData()
        -- CRITICAL: Set widget.spellID for ActionButton_UpdateCooldown safety
        if self.Widget then
            local toySpellID = nil
            if C_Item and C_Item.GetItemSpell then
                local _, spellID = C_Item.GetItemSpell(actionValue)
                toySpellID = spellID
            elseif GetItemSpell then
                local _, _, spellID = GetItemSpell(actionValue)
                toySpellID = spellID
            end
            self.Widget.spellID = toySpellID
        end
        self.SpellName = nil
        self.SpellNameRank = nil
        self.SpellId = nil
        self.FlyoutId = nil
        
    elseif actionType == "equipmentset" and actionValue then
        -- Equipment set: actionValue is the set index
        local setName = nil
        local setTexture = nil
        if C_EquipmentSet and C_EquipmentSet.GetEquipmentSetInfo then
            local name, texture = C_EquipmentSet.GetEquipmentSetInfo(actionValue)
            setName = name
            setTexture = texture
        elseif C_EquipmentSet and C_EquipmentSet.GetNumEquipmentSets then
            -- Fallback: iterate through sets to find by index
            local setCount = C_EquipmentSet.GetNumEquipmentSets()
            for i = 0, setCount - 1 do
                local name, texture, setIndex = C_EquipmentSet.GetEquipmentSetInfo(i)
                if setIndex == actionValue then
                    setName = name
                    setTexture = texture
                    break
                end
            end
        end
        
        self.EquipmentSetId = actionValue
        self.EquipmentSetName = setName
        self.Texture = setTexture or "Interface/Icons/INV_Misc_QuestionMark"
        self:ClearMacroData()
        self:ClearSpellData()
        self.ItemId = nil
        self.ItemName = nil
        self.ItemLink = nil
        self.FlyoutId = nil
        
    else
        self:ClearMacroData()
        -- Clear spell data and widget.spellID
        self.SpellName = nil
        self.SpellNameRank = nil
        self.SpellId = nil
        self.FlyoutId = nil
        if self.Widget then
            self.Widget.spellID = nil
        end
        self.Texture = nil
    end
    
    -- Set secure attributes
    FluxButtonCore.SetButtonAction(self, actionType, actionValue)
    
    -- Register for updates
    if FluxButtonEvents and FluxButtonEvents.RegisterButton then
        FluxButtonEvents.RegisterButton(self)
    end
    
    -- Update flyout arrow if this is a macro with flyout
    -- Only update the arrow display - DON'T call HookFluxButton which adds another OnClick hook
    -- (the flyout click handling is already done in PostClick above)
    if FluxFlyout and FluxFlyout.UpdateFluxButtonArrow then
        FluxFlyout.UpdateFluxButtonArrow(self)
    end
    
    -- Full refresh (includes range checking via usability system)
    self:FullRefresh()
end

-- Clear macro data
function FluxButton:ClearMacroData()
    self.MacroMode = nil
    self.MacroAction = nil
    self.MacroTargetName = nil
    self.MacroTargetDead = nil
    self.MacroName = nil
    self.MacroBody = nil
    self.MacroIndex = nil
    self.MacroShowTooltip = nil
    self.HideMacroName = nil
    self._fluxHasModConditional = nil
    self._fluxHasMouseoverConditional = nil
    self._fluxHasStanceConditional = nil
    self.Target = nil
    self:InvalidateTranslateMacroCache()
    if FluxButtonEvents and FluxButtonEvents.RefreshMouseoverMacroMembership then
        FluxButtonEvents.RefreshMouseoverMacroMembership(self)
    end
end

-- Clear spell data
function FluxButton:ClearSpellData()
    self.SpellName = nil
    self.SpellNameRank = nil
    self.SpellId = nil
    self.FlyoutId = nil
    -- Also clear widget.spellID to keep them in sync
    if self.Widget then
        self.Widget.spellID = nil
    end
end

-- Clear equipment set data
function FluxButton:ClearEquipmentSetData()
    self.EquipmentSetId = nil
    self.EquipmentSetName = nil
end

-- Clear the button's action
function FluxButton:ClearAction()
    if FluxButtonEvents and FluxButtonEvents.UnregisterButton then
        FluxButtonEvents.UnregisterButton(self)
    end
    
    -- Clear Single-Button Assistant state first
    self:ClearSingleButtonAssistant()
    self.SingleButtonAssistantSpellId = nil  -- Clear VFX spell ID
    
    self.ActionType = nil
    self.ActionValue = nil
    self:ClearMacroData()
    self:ClearSpellData()
    self:ClearEquipmentSetData()
    self.ItemId = nil
    self.ItemName = nil
    self.ItemLink = nil
    self.Texture = nil
    
    -- Clear secure attributes
    if self.Widget and not InCombatLockdown() then
        self.Widget:SetAttribute("type", nil)
        self.Widget:SetAttribute("typerelease", nil)
        self.Widget:SetAttribute("spell", nil)
        self.Widget:SetAttribute("spell2", nil)
        self.Widget:SetAttribute("item", nil)
        self.Widget:SetAttribute("macro", nil)
        self.Widget:SetAttribute("macrotext", nil)
        self.Widget:SetAttribute("type2", nil)
        self.Widget:SetAttribute("macrotext2", nil)
        self.Widget:SetAttribute("action", nil)
        self.Widget:SetAttribute("equipmentset", nil)
    end
    -- Craft RC memo must not survive a wipe of macrotext2 (placeholder / empty slot).
    self._fluxCraftBindKey = nil

    -- Stay unregistered while empty (SetAction re-registers). Empty slots must not
    -- sit in ActiveButtons for every RefText/RefUsable batch sweep.
    
    -- Force unchecked state when clearing
    if self.Widget and self.Widget.SetChecked then
        self.Widget:SetChecked(false)
        local checkedTexture = self.Widget:GetCheckedTexture()
        if checkedTexture then
            checkedTexture:Hide()
        end
    end
    
    -- Clear flyout arrow
    if FluxFlyout and FluxFlyout.ClearFluxButtonArrow then
        FluxFlyout.ClearFluxButtonArrow(self)
    end
    
    self:FullRefresh()
end

-- ============================================================================
-- MACRO HELPER FUNCTIONS (ported from old FluxButton.lua)
-- ============================================================================

-- Helper to trim spaces from strings
local function TrimWhitespace(str)
    if type(str) ~= "string" then return str end
    return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Helper to extract spell from castsequence arguments
local function ExtractCastSequenceSpell(args)
    if not args then return nil, nil end
    -- Remove reset conditions (reset=X/combat/target etc)
    local cleaned = args:gsub("^reset=[^%s]*%s*", "")
    -- Extract first spell/item before comma
    local first = cleaned:match("([^,]+)")
    return first and TrimWhitespace(first), cleaned
end

-- Extract a primary cast name from macro body; prefers nomod clause
local function ExtractPrimaryCastName(macroBody)
    if type(macroBody) ~= "string" then return nil end
    local candidateFirst
    local candidateNomod
    for line in macroBody:gmatch("[^\r\n]+") do
        local lowered = line:lower()
        local isNomod = lowered:find("nomod") ~= nil
        
        -- Handle /castsequence
        if lowered:find("/castsequence", 1, true) then
            local args = line:gsub("^%s*/%s*castsequence%s*", "")
            -- Remove encoded conditionals to find the sequence string
            local sequence = args:gsub("^%s*%b[]%s*", "")
            local spell, rawSequence = ExtractCastSequenceSpell(sequence)
            
            if spell and spell ~= "" then
                if isNomod and not candidateNomod then
                    candidateNomod = spell
                end
                if not candidateFirst then
                    candidateFirst = spell
                end
            end
            
        elseif lowered:find("/cast", 1, true) or lowered:find("/use", 1, true) then
            -- Remove command and any bracketed conditionals
            local cleaned = line:gsub("^%s*/%s*cast%s*", ""):gsub("^%s*/%s*use%s*", "")
            cleaned = cleaned:gsub("%b[]", "")
            -- Take first clause before ';'
            local clause = cleaned:match("([^;]+)") or cleaned
            clause = TrimWhitespace(clause)
            if clause ~= "" then
                if isNomod and not candidateNomod then
                    candidateNomod = clause
                end
                if not candidateFirst then
                    candidateFirst = clause
                end
            end
        end
    end
    return candidateNomod or candidateFirst
end

-- Evaluate current environment against macro conditionals to pick the active cast/use token
-- Uses SecureCmdOptionParse to evaluate conditionals based on current game state
local function EvaluateMacroActiveCast(macroBody)
    if type(macroBody) ~= "string" then return nil, nil, nil end
    
    for line in macroBody:gmatch("[^\r\n]+") do
        -- Handle #showtooltip first if present on this line
        local stt = line:match("^%s*#%s*showtooltip%s*(.*)$")
        if stt and SecureCmdOptionParse then
            local chosen, target = SecureCmdOptionParse(stt)
            if chosen and chosen ~= "" then
                -- Check if it's a castsequence format
                if chosen:find(",") then
                    local spell, _ = ExtractCastSequenceSpell(chosen)
                    if spell then return spell, target, chosen end
                end
                return TrimWhitespace(chosen), target, nil
            end
        end
        
        -- Handle /castsequence
        local seqTail = line:match("^%s*/%s*castsequence%s*(.+)$")
        if seqTail and SecureCmdOptionParse then
            local chosen, target = SecureCmdOptionParse(seqTail)
            if chosen and chosen ~= "" then
                local spell, _ = ExtractCastSequenceSpell(chosen)
                if spell then return spell, target, chosen end
            end
        end

        -- Handle /cast or /use lines
        local tail = line:match("^%s*/%s*cast%s*(.+)$") or line:match("^%s*/%s*use%s*(.+)$")
        
        if tail and tail ~= "" and SecureCmdOptionParse then
            local chosen, target = SecureCmdOptionParse(tail)
            if chosen and chosen ~= "" then
                return TrimWhitespace(chosen), target, nil
            end
        end
    end
    return nil, nil, nil
end

-- ============================================================================
-- TRANSLATE MACRO (full conditional-aware implementation)
-- ============================================================================

local function BuildTranslateMacroModifierKey()
    local parts = {}
    if IsShiftKeyDown and IsShiftKeyDown() then
        parts[#parts + 1] = "S"
    end
    if IsControlKeyDown and IsControlKeyDown() then
        parts[#parts + 1] = "C"
    end
    if IsAltKeyDown and IsAltKeyDown() then
        parts[#parts + 1] = "A"
    end
    return table.concat(parts)
end

-- Stance / bonus-bar / page / stealth tokens so [form:]/[stance:]/[bonusbar:]/[actionbar:]
-- macros miss cache on shapeshift without a global InvalidateAllTranslateMacroCaches storm.
local function BuildTranslateMacroStanceKey()
    local form = 0
    if GetShapeshiftForm then
        local ok, v = pcall(GetShapeshiftForm)
        if ok and type(v) == "number" then
            form = v
        end
    end
    local page = 1
    if GetActionBarPage then
        local ok, v = pcall(GetActionBarPage)
        if ok and type(v) == "number" then
            page = v
        end
    end
    local bonus = 0
    if GetBonusBarOffset then
        local ok, v = pcall(GetBonusBarOffset)
        if ok and type(v) == "number" then
            bonus = v
        end
    end
    local stealth = (IsStealthed and IsStealthed()) and "1" or "0"
    return form .. ":" .. page .. ":" .. bonus .. ":" .. stealth
end

local function UnitCacheToken(unit)
    if not UnitExists or not UnitExists(unit) then
        return "-"
    end
    local api = (FluxAPICompat and FluxAPICompat.API) or {}
    local guid
    if api.AccessibleGUIDForUnit then
        guid = api.AccessibleGUIDForUnit(unit)
    elseif UnitGUID then
        guid = UnitGUID(unit)
        if api.IsSecretValue and api.IsSecretValue(guid) then
            guid = nil
        elseif api.CanAccessValue and not api.CanAccessValue(guid) then
            guid = nil
        elseif issecretvalue and issecretvalue(guid) then
            guid = nil
        end
    end
    if type(guid) ~= "string" or guid == "" then
        guid = "1"
    end
    -- help/harm flips (e.g. mind control) without a GUID change must bust cache
    local harm = "f"
    if UnitCanAttack then
        if api.SafeBooleanTest then
            harm = api.SafeBooleanTest(UnitCanAttack("player", unit), false) and "h" or "f"
        else
            local ok, can = pcall(UnitCanAttack, "player", unit)
            if ok and can then
                harm = "h"
            end
        end
    end
    return guid .. harm
end

local function BuildTranslateMacroCacheKey(self, macroBody)
    local macroKey
    if self.MacroIndex then
        macroKey = "i:" .. tostring(self.MacroIndex) .. ":" .. (macroBody and #macroBody or 0)
    else
        macroKey = "b:" .. (macroBody or "")
    end
    local combat = (InCombatLockdown and InCombatLockdown()) and "1" or "0"
    return table.concat({
        macroKey,
        UnitCacheToken("mouseover"),
        UnitCacheToken("target"),
        UnitCacheToken("focus"),
        combat,
        BuildTranslateMacroModifierKey(),
        BuildTranslateMacroStanceKey(),
    }, "|")
end

function FluxButton:InvalidateTranslateMacroCache()
    self._fluxTranslateMacroCacheKey = nil
end

-- Translate macro content (supports macro index and inline macrotext)
-- Evaluates conditionals to determine active spell/item based on current game state
function FluxButton:TranslateMacro()
    if self.ActionType ~= "macro" then
		return false
	end
	
    local macroBody, macroTexture
    if self.MacroIndex then
        local mName, mTex, mBody = GetMacroInfo(self.MacroIndex)
        macroTexture = mTex
        macroBody = mBody
        -- Keep cached name in sync (covers in-game macro renames while mounted)
        if mName then
            self.MacroName = mName
        end
    elseif self.MacroBody then
        macroBody = self.MacroBody
    end

    if not macroBody or macroBody == "" then
        return false
    end

    -- Lazily classify stance conditionals for macros assigned before this flag existed.
    if self._fluxHasStanceConditional == nil then
        UpdateHasStanceConditional(self, macroBody)
    end

    local cacheKey = BuildTranslateMacroCacheKey(self, macroBody)
    local cacheHit = false
    if self._fluxTranslateMacroCacheKey ~= nil then
        local api = (FluxAPICompat and FluxAPICompat.API) or {}
        if api.SafeEqualForCache then
            cacheHit = api.SafeEqualForCache(self._fluxTranslateMacroCacheKey, cacheKey) == true
        else
            local ok, same = pcall(function()
                return self._fluxTranslateMacroCacheKey == cacheKey
            end)
            cacheHit = ok and same or false
        end
    end
    local formStorm = FluxButtonEvents and FluxButtonEvents.IsFormStormActive
        and FluxButtonEvents.IsFormStormActive()
    if cacheHit then
        -- Still re-evaluate glow/checked/cast (ButtonForge FullRefresh pattern),
        -- except during shapeshift storms where stance key already gated a real miss.
        if not formStorm then
            local EffectRefresh = _G.FluxEffectRefresh
            if EffectRefresh and EffectRefresh.RefreshButton then
                EffectRefresh.RefreshButton(self)
            end
        end
        return false
    end

    -- Refresh #showtooltip / #noname flags from the freshly-read body so that
    -- in-game macro edits propagate to tooltip + label rendering.
    -- For inline macrotext, self.MacroBody is already the sanitized (no '#'
    -- lines) version, so it would report MacroShowTooltip = false; SetAction
    -- has already computed the flag from the original body in that path.
    if self.MacroIndex then
        self.MacroShowTooltip = MacroBodyHasShowTooltip(macroBody)
        self.HideMacroName = MacroBodyHasNoName(macroBody)
    end

    -- Check if state changed to avoid redundant refreshes
    local changed = false

    -- Determine active cast target from conditionals
    local activeToken, activeTarget, activeSequence = EvaluateMacroActiveCast(macroBody)

    -- If we have a cast sequence, use the GAME's logic to find the currently active item/spell
    if activeSequence and QueryCastSequence then
        local index, item, spell = QueryCastSequence(activeSequence)
        if item or spell then
            activeToken = item or spell
        end
    end

    -- Fallback: extract a basic candidate if conditionals fail or are empty
    if not activeToken then
        activeToken = ExtractPrimaryCastName(macroBody)
    end
    
    if self.CastSequence ~= activeSequence then
        self.CastSequence = activeSequence
        changed = true
    end

    -- Track chosen unit target if provided by parser
    local targetName = activeTarget and UnitName and UnitName(activeTarget)
    local targetDead = activeTarget and UnitIsDead and UnitIsDead(activeTarget)

    local API = FluxAPICompat and FluxAPICompat.API or {}
    local safeEqualForCache = API.SafeEqualForCache
    if not safeEqualForCache then
        safeEqualForCache = function(a, b)
            local c = API.SafeCompare and API.SafeCompare(a, b, "==")
            if c ~= nil then return c end
            local ok, res = pcall(function()
                return a == b
            end)
            return ok and res or false
        end
    end

    local targetChanged = false
    if self.Target ~= activeTarget
        or not safeEqualForCache(self.MacroTargetName, targetName)
        or not safeEqualForCache(self.MacroTargetDead, targetDead) then
        self.Target = activeTarget
        self.MacroTargetName = targetName
        self.MacroTargetDead = targetDead
        targetChanged = true
        changed = true
    end

    -- Determine texture/mode and cache tooltip-related info
    local newSpellName, newSpellId, newMacroMode, newItemId, newItemName, newTexture
    local setTexture = false
    
    if self.MacroIndex then
        -- Leverage game-provided resolution for true macros
        local SpellId = GetMacroSpell(self.MacroIndex)
        if SpellId and C_Spell and C_Spell.GetSpellInfo then
            local spellInfo = C_Spell.GetSpellInfo(SpellId)
            local Name = spellInfo and spellInfo.name
            local Subtext = nil
            if C_Spell and C_Spell.GetSpellSubtext then
                Subtext = C_Spell.GetSpellSubtext(SpellId)
            end
            if Subtext and Subtext ~= "" then
                newSpellName = Name .. "(" .. Subtext .. ")"
            else
                newSpellName = Name
            end
            newSpellId = SpellId
            newMacroMode = "spell"
            newTexture = C_Spell.GetSpellTexture(SpellId) or macroTexture
            setTexture = true
        else
            local ItemName, ItemLink = GetMacroItem(self.MacroIndex)
            if ItemName then
                if C_Item and C_Item.GetItemInfoInstant then
                    newItemId = C_Item.GetItemInfoInstant(ItemName) or 0
                else
                    newItemId = 0
                end
                newItemName = ItemName
                newMacroMode = "item"
                if newItemId then
                    newTexture = GetItemIcon(newItemId)
                end
                if not newTexture then newTexture = macroTexture end
                setTexture = true
            end
        end
    end

    -- If game APIs didn't resolve, try parsing the active token
    if not setTexture and activeToken then
        local primary = activeToken
        -- Remove @unit suffix for lookup
        primary = primary:gsub("@[%w_]+", "")
        primary = TrimWhitespace(primary)

        -- Try spell first
        local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(primary)
        if spellInfo and spellInfo.spellID then
            newSpellName = spellInfo.name
            local Subtext = nil
            if C_Spell and C_Spell.GetSpellSubtext then
                Subtext = C_Spell.GetSpellSubtext(spellInfo.spellID)
            end
            if Subtext and Subtext ~= "" then
                newSpellName = spellInfo.name .. "(" .. Subtext .. ")"
            else
                newSpellName = spellInfo.name
            end
            newSpellId = spellInfo.spellID
            newMacroMode = "spell"
            newTexture = C_Spell.GetSpellTexture(spellInfo.spellID) or self.Texture
            setTexture = true
        else
            -- Try item
            -- Support item:1234 syntax
            local itemIDFromStr = primary:match("^item:(%d+)$")
            if itemIDFromStr then
                primary = tonumber(itemIDFromStr)
            end
            
            local itemId = C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(primary)
            if itemId then
                newItemId = itemId
                newItemName = type(primary) == "string" and primary or GetItemInfo(itemId)
                newMacroMode = "item"
                newTexture = GetItemIcon(itemId) or self.Texture
                setTexture = true
            end
        end
    end

    -- Fallback to existing texture if nothing found
    if not newTexture and not setTexture then
        newTexture = self.Texture or macroTexture
    end

    -- Check for changes and update state
    if self.SpellName ~= newSpellName or self.SpellId ~= newSpellId or 
       self.MacroMode ~= newMacroMode or self.ItemId ~= newItemId or 
       self.ItemName ~= newItemName or self.Texture ~= newTexture then
           
        self.SpellName = newSpellName
        self.SpellId = newSpellId
        self.SpellNameRank = newSpellName
        self.MacroMode = newMacroMode
        -- CRITICAL: Keep widget.spellID in sync for ActionButton_UpdateCooldown safety
        if self.Widget then
            self.Widget.spellID = newSpellId
        end
        self.ItemId = newItemId
        self.ItemName = newItemName
        self.Texture = newTexture
        changed = true
    end

    -- If anything changed, trigger a visual update (ButtonForge: FullRefresh includes CD)
    if changed then
        if self.WIcon and self.Texture then
            self.WIcon:SetTexture(self.Texture)
        end
        -- Also update usability/range when macro target or spell changes
        self:UpdateUsable()
        -- Clear/repaint swipe for the newly resolved spell/item (e.g. nomod on CD → alt off CD)
        if self.UpdateCooldown then
            self:UpdateCooldown()
        end
        if self.UpdateTextCount then
            self:UpdateTextCount()
        end
        if self._fluxBadgeHiddenUnlessCd and self.ApplyDisplayPolicy then
            self:ApplyDisplayPolicy()
        end
    elseif targetChanged then
        -- Even if nothing else changed, if target changed we need to re-check range
        self:UpdateUsable()
    end

    self._fluxTranslateMacroCacheKey = cacheKey

    -- Notify EffectRouter / IdentityDrive when an action-bar badge (or any FluxButton
    -- with a column) changes displayed spell/item under macro conditions.
    if changed or targetChanged then
        if self._fluxIsActionBarBadge or (self.Widget and self.Widget._fluxIsActionBarBadge) then
            local Identity = _G.FluxIdentityDrive
            if Identity and Identity.OnBadgeTranslated then
                Identity.OnBadgeTranslated(self)
            end
        elseif self._fluxBarSlotIndex or (self.Widget and self.Widget._fluxBarSlotIndex) then
            local Identity = _G.FluxIdentityDrive
            if Identity and Identity.OnButtonIdentityChanged then
                Identity.OnButtonIdentityChanged(self.Widget or self)
            end
        end
    end

    -- Glow/checked/cast: always on identity change. During shapeshift storms, skip the
    -- no-op path — RefreshButton → Identity.RefreshColumn across every badge is the hitch.
    if changed or targetChanged or not formStorm then
        -- Keep SpellActivationOverlay's ActionButtons map in sync with live spell id
        -- BEFORE settle so membership + Enable/Disable see the new GetGlowID.
        local Glow = _G.FluxEffectGlow
        local widget = self.Widget or self
        if Glow and widget then
            if Glow.EnsureBadgeGlowAnchor and widget._fluxIsActionBarBadge then
                pcall(Glow.EnsureBadgeGlowAnchor, widget)
            end
            if Glow.InstallSAO then
                pcall(Glow.InstallSAO, widget)
            end
            if Glow.NotifySAO then
                pcall(Glow.NotifySAO, widget)
            end
        end

        local EffectRefresh = _G.FluxEffectRefresh
        if EffectRefresh and EffectRefresh.RefreshButton then
            EffectRefresh.RefreshButton(self)
        end

        local SRM = _G.FluxSpellRankManager
        if SRM and SRM.ApplyRankDesaturation and self.SpellId then
            SRM:ApplyRankDesaturation(self, self.SpellId)
        end
    end

    return (changed or targetChanged) and true or false
end

-- Full refresh function
function FluxButton:FullRefresh()
    if not self.Widget then return end
    
    self:UpdateTexture()
    self:UpdateChecked()
    self:UpdateEquipped()
    self:UpdateCooldown()
    self:UpdateUsable()
    self:UpdateButtonText()
    self:UpdateEmptyBackground()
    self:ForceRingBorderClassColor()

    local EffectRefresh = _G.FluxEffectRefresh
    if EffectRefresh and EffectRefresh.RefreshButton then
        EffectRefresh.RefreshButton(self)
    end
    
    -- If tooltip is currently shown, refresh next frame so synchronous tooltip/GameTooltip code cannot
    -- re-enter SetAction/FullRefresh (C stack overflow in GetCVarBool during shopping/compare tooltip setup).
    -- Coalesce to one pending refresh per button: layout can call FullRefresh dozens of times per frame.
    local Guard = _G.FluxTooltipGuard
    local tipOwned = Guard and Guard.IsOwnedByWidget and Guard.IsOwnedByWidget(self.Widget)
        or (GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self.Widget))
    if self.TooltipEnabled and self.Widget and tipOwned then
        if self._fluxTooltipRefreshScheduled then
            -- already queued this frame chain
        else
            self._fluxTooltipRefreshScheduled = true
            local btn = self
            local function doTooltipRefresh()
                btn._fluxTooltipRefreshScheduled = nil
                if not btn.Widget then
                    return
                end
                local stillOwned = Guard and Guard.IsOwnedByWidget and Guard.IsOwnedByWidget(btn.Widget)
                    or (GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(btn.Widget))
                if not stillOwned then
                    return
                end
                if btn.Widget.UpdateTooltip then
                    btn.Widget:UpdateTooltip()
                else
                    btn:ShowTooltip()
                end
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0, doTooltipRefresh)
            else
                doTooltipRefresh()
            end
        end
    end
    if self.IsSingleButtonAssistant and self.SingleButtonAssistantOverlayFrame then
        self:UpdateSingleButtonAssistantOverlayLayout()
    end
end

-- Update empty background visibility and color
function FluxButton:UpdateEmptyBackground()
    if not self.WEmptyBG then return end
    
    if not self.ActionType or not self.ActionValue then
        if not self.PlaceholderTexture then
            self.WEmptyBG:Show()

            if self._fluxSmartCollectionStyle then
                if self._fluxSmartCollectionCharacterTint and FluxButtonUtil and FluxButtonUtil.GetClassColor then
                    local c = FluxButtonUtil:GetClassColor()
                    self.WEmptyBG:SetVertexColor(c.r, c.g, c.b, EMPTY_SLOT_ALPHA)
                    return
                end
                if self._fluxSmartCollectionAccountNeutralTint then
                    self.WEmptyBG:SetVertexColor(1, 1, 1, EMPTY_SLOT_ALPHA)
                    return
                end
                -- Account-wide smart + appearance not in class-color mode: same empty-slot treatment as other grid buttons.
                local scope = self.categoryScope or "class"
                if scope == "character" or scope == "class" then
                    local r, g, b = 0.6, 0.6, 0.6
                    if self._fluxExtraButtonsUseRawClassEmpty and FluxButtonUtil and FluxButtonUtil.GetClassColor then
                        local c = FluxButtonUtil:GetClassColor()
                        r, g, b = c.r, c.g, c.b
                    elseif FluxButtonUtil and FluxButtonUtil.GetThemedScopeVertexRGB then
                        r, g, b = FluxButtonUtil:GetThemedScopeVertexRGB(scope)
                    else
                        local _, classFilename = UnitClass("player")
                        local classColor = RAID_CLASS_COLORS[classFilename] or { r = 0.6, g = 0.6, b = 0.6 }
                        r, g, b = classColor.r, classColor.g, classColor.b
                    end
                    self.WEmptyBG:SetVertexColor(r, g, b, EMPTY_SLOT_ALPHA)
                else
                    self.WEmptyBG:SetVertexColor(1, 1, 1, EMPTY_SLOT_ALPHA)
                end
                return
            end
            
            local scope = self.categoryScope or "class"
            if scope == "character" or scope == "class" then
                local r, g, b = 0.6, 0.6, 0.6
                if self._fluxExtraButtonsUseRawClassEmpty and FluxButtonUtil and FluxButtonUtil.GetClassColor then
                    local c = FluxButtonUtil:GetClassColor()
                    r, g, b = c.r, c.g, c.b
                elseif FluxButtonUtil and FluxButtonUtil.GetThemedScopeVertexRGB then
                    r, g, b = FluxButtonUtil:GetThemedScopeVertexRGB(scope)
                else
                    local _, classFilename = UnitClass("player")
                    local classColor = RAID_CLASS_COLORS[classFilename] or { r = 0.6, g = 0.6, b = 0.6 }
                    r, g, b = classColor.r, classColor.g, classColor.b
                end
                self.WEmptyBG:SetVertexColor(r, g, b, EMPTY_SLOT_ALPHA)
            else
                self.WEmptyBG:SetVertexColor(1, 1, 1, EMPTY_SLOT_ALPHA)
            end
        else
            self.WEmptyBG:Hide()
        end
    else
        self.WEmptyBG:Hide()
    end
end

-- Update texture for macros (dynamic based on conditionals)
function FluxButton:UpdateTextureMacro()
    -- Hard icon override (e.g. Flux Stance active pet/armor wisp)
    if self.IconOverrideTexture and type(self.IconOverrideTexture) == "string" and self.IconOverrideTexture ~= "" then
        if self.WIcon then
            self.WIcon:SetTexture(self.IconOverrideTexture)
            self.WIcon:SetDesaturated(false)
            self.WIcon:Show()
        end
        return
    end

    -- Track previous state to detect content changes
    local prevSpellId = self.SpellId
    local prevItemId = self.ItemId
    local prevMacroMode = self.MacroMode
    
    -- Re-resolve active token under current modifier and unit conditions
    local macroBody
    if self.MacroIndex then
        local _, _, body = GetMacroInfo(self.MacroIndex)
        macroBody = body
    else
        macroBody = self.MacroBody
    end

    local function resolveActive()
        if type(macroBody) ~= "string" or macroBody == "" then return nil end
        -- Prefer #showtooltip; else first /cast or /use
        for line in macroBody:gmatch("[^\r\n]+") do
            local stt = line:match("^%s*#%s*showtooltip%s*(.*)$")
            if stt and SecureCmdOptionParse then
                local chosen = SecureCmdOptionParse(stt)
                if chosen and chosen ~= "" then return chosen end
            end
            local tail = line:match("^%s*/%s*cast%s*(.+)$") or line:match("^%s*/%s*use%s*(.+)$")
            if tail and SecureCmdOptionParse then
                local chosen = SecureCmdOptionParse(tail)
                if chosen and chosen ~= "" then return chosen end
            end
        end
        return nil
    end

    local chosen = resolveActive()
    local tex
    if chosen then
        -- Keep Name(Rank N); stripping () made Classic resolve max rank.
        local token = chosen:gsub("@[%w_]+", "")
        token = token:match("^%s*(.-)%s*$")
        if token and token ~= "" then
            local function SetMacroSpellIdentity(spellId, bareName, rankedToken)
                self.MacroMode = "spell"
                self.SpellId = spellId
                self.SpellName = bareName
                local castAttr = (FluxButtonCore and FluxButtonCore.FormatSpellCastAttribute
                    and FluxButtonCore.FormatSpellCastAttribute(spellId))
                    or (_G.FluxFormatSpellCastAttribute and _G.FluxFormatSpellCastAttribute(spellId))
                if type(castAttr) == "string" and castAttr ~= "" then
                    self.SpellNameRank = castAttr
                elseif type(rankedToken) == "string" and rankedToken:find("%(", 1, true) then
                    self.SpellNameRank = rankedToken
                else
                    self.SpellNameRank = bareName
                end
                if self.Widget then
                    self.Widget.spellID = spellId
                end
            end
            -- Try spell first
            if C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(token) then
                local info = C_Spell.GetSpellInfo(token)
                tex = C_Spell.GetSpellTexture(info.spellID)
                SetMacroSpellIdentity(info.spellID, info.name, token)
            elseif GetSpellTexture then
                -- Fallback for legacy clients
                tex = GetSpellTexture(token)
                if tex then
                    local spellId = nil
                    if C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
                        spellId = C_Spell.GetSpellIDForSpellIdentifier(token)
                    end
                    local bare = token:match("^([^%(]+)") or token
                    SetMacroSpellIdentity(spellId, bare, token)
                end
            end
            
            -- Try item if spell lookup failed
            if not tex then
                -- Handle "item:ID" format
                local itemId = token:match("^item:(%d+)$")
                if itemId then
                    itemId = tonumber(itemId)
                    tex = GetItemIcon(itemId)
                    if tex then
                        self.MacroMode = "item"
                        self.ItemId = itemId
                        self.ItemName = GetItemInfo(itemId)
                        self.ItemLink = select(2, GetItemInfo(itemId))
                    end
                else
                    -- Try item name lookup
                    local resolvedItemId = C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(token)
                    if resolvedItemId then
                        tex = GetItemIcon(resolvedItemId)
                        if tex then
                            self.MacroMode = "item"
                            self.ItemId = resolvedItemId
                            self.ItemName = token
                            self.ItemLink = select(2, GetItemInfo(resolvedItemId))
                        end
                    end
                end
            end
        end
    end
    
    tex = tex or self.Texture or self:GetActionTexture()
    if tex then
        self.WIcon:SetTexture(tex)
        self.WIcon:Show()
    else
        self.WIcon:Hide()
    end
    
    -- Check if macro content changed (for clearing casting animations)
    local contentChanged = false
    if prevSpellId ~= self.SpellId then
        contentChanged = true
    elseif prevItemId ~= self.ItemId then
        contentChanged = true
    elseif prevMacroMode ~= self.MacroMode then
        contentChanged = true
    end
    
    -- If content changed, update usability too
    if contentChanged and self.UpdateUsable then
        self:UpdateUsable()
    end

    local SRM = _G.FluxSpellRankManager
    if SRM and SRM.ApplyRankDesaturation and self.SpellId then
        SRM:ApplyRankDesaturation(self, self.SpellId)
    end
end

-- Update texture
function FluxButton:UpdateTexture()
    if not self.Widget then return end
    
    if not self.ActionType or not self.ActionValue then
        if self.PlaceholderTexture then
            self.WIcon:SetTexture(self.PlaceholderTexture)
            self.WIcon:SetDesaturated(true)
            self.WIcon:SetVertexColor(0.25, 0.25, 0.25)
            self.WIcon:Show()
        else
            self.WIcon:Hide()
        end
        return 
    end

    -- Hard icon override (e.g. Flux Stance active pet/armor wisp)
    if self.IconOverrideTexture and type(self.IconOverrideTexture) == "string" and self.IconOverrideTexture ~= "" then
        if self.WIcon then
            self.WIcon:SetTexture(self.IconOverrideTexture)
            self.WIcon:SetDesaturated(false)
            self.WIcon:Show()
        end
        return
    end

    -- For macros, use specialized function that handles conditionals
    if self.ActionType == "macro" then
        self:UpdateTextureMacro()
        return
    end

    -- Check for Single-Button Assistant special handling
    if self.IsSingleButtonAssistant then
        self:UpdateTextureSpellSingleButtonAssistant()
        return
    end
    
    -- Update texture based on action type
    local texture = self.Texture
    
    if self.ActionType == "spell" then
        -- Always get fresh texture for spells - handles spell overrides (Smite -> Void Blast)
        if HasC_Spell() and C_Spell.GetSpellTexture then
            texture = C_Spell.GetSpellTexture(self.SpellId or self.ActionValue) or texture
        elseif GetSpellInfo then
            local _, _, icon = GetSpellInfo(self.SpellId or self.ActionValue)
            texture = icon or texture
        end
    elseif self.ActionType == "item" then
        texture = texture or GetItemIcon(self.ActionValue)
    elseif self.ActionType == "mount" then
        if C_MountJournal and C_MountJournal.GetMountInfoByID then
            local _, _, icon = C_MountJournal.GetMountInfoByID(self.ActionValue)
            texture = texture or icon
        end
    elseif self.ActionType == "battlepet" then
        if C_PetJournal and C_PetJournal.GetPetInfoByPetID then
            local _, _, _, _, _, _, _, _, petIcon = C_PetJournal.GetPetInfoByPetID(self.ActionValue)
            texture = texture or petIcon
        end
    elseif self.ActionType == "equipmentset" then
        -- Equipment set texture is already set in SetAction, just use it
        texture = texture or self.Texture
    end
    
    if texture then
        self.WIcon:SetTexture(texture)
        -- NOTE: Do NOT set vertex color here - it's managed by UpdateUsable()
        -- Setting it here causes flickering because UpdateTexture is called on all buttons
        -- but UpdateUsable only runs when RefUsable is true
        self.WIcon:Show()
        local SRM = _G.FluxSpellRankManager
        if SRM and SRM.ApplyRankDesaturation and self.SpellId
            and (self.ActionType == "spell" or self.ActionType == "macro" or self.ActionType == "macrotext"
                or self.MacroMode == "spell") then
            SRM:ApplyRankDesaturation(self, self.SpellId)
        end
    else
        self.WIcon:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
        self.WIcon:Show()
    end
end

-- Get texture for current action (used by UpdateTextureMacro and other systems)
function FluxButton:GetActionTexture()
    -- Allow a hard icon override regardless of the underlying action
    if self.IconOverrideTexture and type(self.IconOverrideTexture) == "string" and self.IconOverrideTexture ~= "" then
        return self.IconOverrideTexture
    end

    if not self.ActionType or not self.ActionValue then
        return nil
    end

    if self.ActionType == "spell" then
        -- Use modern API for spell textures
        if HasC_Spell() and C_Spell.GetSpellTexture then
            return C_Spell.GetSpellTexture(self.ActionValue)
        elseif GetSpellInfo then
            local _, _, icon = GetSpellInfo(self.ActionValue)
            return icon
        end
        return nil
    elseif self.ActionType == "item" then
        return GetItemIcon(self.ActionValue)
    elseif self.ActionType == "macro" then
        -- For macros, handle dynamic updates
        if self.MacroMode == "spell" and self.SpellId then
            -- Use spell texture for spell macros
            if HasC_Spell() and C_Spell.GetSpellTexture then
                return C_Spell.GetSpellTexture(self.SpellId)
            elseif GetSpellInfo then
                local _, _, icon = GetSpellInfo(self.SpellId)
                return icon
            end
            return nil
        elseif self.MacroMode == "item" and self.ItemId then
            -- Use item texture for item macros
            return GetItemIcon(self.ItemId)
        else
            -- Use cached texture from TranslateMacro or fallback
            if self.Texture then
                return self.Texture
            end
            return "Interface\\Icons\\INV_Misc_QuestionMark"
        end
    elseif self.ActionType == "action" then
        if FluxAPICompat.API.GetActionTexture then
            return FluxAPICompat.API.GetActionTexture(self.ActionValue)
        end
        return nil
    elseif self.ActionType == "mount" then
        -- For mounts, get spell texture from mount spell ID
        if C_MountJournal and C_MountJournal.GetMountInfoByID then
            local mountName, mountSpellID = C_MountJournal.GetMountInfoByID(self.ActionValue)
            if mountSpellID then
                if HasC_Spell() and C_Spell.GetSpellTexture then
                    return C_Spell.GetSpellTexture(mountSpellID)
                elseif GetSpellTexture then
                    return GetSpellTexture(mountSpellID)
                end
            end
            return "Interface\\Icons\\Ability_Mount_Charger"
        else
            return "Interface\\Icons\\Ability_Mount_Charger"
        end
    elseif self.ActionType == "equipmentset" then
        -- For equipment sets, use cached texture or default
        return self.Texture or "Interface\\Icons\\INV_Misc_QuestionMark"
    elseif self.ActionType == "bonusaction" then
        -- For bonus actions, try to get the action texture
        if FluxAPICompat.API.GetActionTexture then
            return FluxAPICompat.API.GetActionTexture(self.ActionValue)
        end
        return nil
    elseif self.ActionType == "flyout" then
        -- For flyouts, get the texture from the spell book
        local flyoutIndex, flyoutBank = self:LookupFlyoutIndex(self.FlyoutId or self.ActionValue)
        if flyoutIndex and flyoutBank and C_SpellBook and C_SpellBook.GetSpellBookItemTexture then
            local texture = C_SpellBook.GetSpellBookItemTexture(flyoutIndex, flyoutBank)
            if texture then
                return texture
            end
        end
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    elseif self.ActionType == "battlepet" then
        -- For battle pets, get the pet texture
        if C_PetJournal and C_PetJournal.GetPetInfoByPetID then
            local _, _, _, _, _, _, _, _, petTexture = C_PetJournal.GetPetInfoByPetID(self.ActionValue)
            return petTexture or "Interface\\Icons\\INV_Misc_QuestionMark"
        else
            return "Interface\\Icons\\INV_Misc_QuestionMark"
        end
    elseif self.ActionType == "toy" then
        -- For toys, treat as item
        return GetItemIcon(self.ActionValue) or "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    return nil
end

-- Refresh spell button - used for spell overrides (Smite -> Void Blast, etc.)
-- Called when SPELLS_CHANGED or LEARNED_SPELL_IN_TAB fires
function FluxButton:RefreshSpell()
    if self.ActionType ~= "spell" then return end
    
    -- Update cached texture to reflect current spell state (handles overrides)
    if HasC_Spell() and C_Spell.GetSpellTexture then
        self.Texture = C_Spell.GetSpellTexture(self.SpellId or self.ActionValue) or "Interface/Icons/INV_Misc_QuestionMark"
    elseif GetSpellInfo then
        local _, _, icon = GetSpellInfo(self.SpellId or self.ActionValue)
        self.Texture = icon or "Interface/Icons/INV_Misc_QuestionMark"
    end
    
    -- Update visual state
    self:UpdateTexture()
    self:UpdateCooldown()
    self:UpdateUsable()
end

-- Update checked state
function FluxButton:UpdateChecked()
    if not self.Widget then return end
    local ov = _G.Flux and _G.Flux.ButtonFX and _G.Flux.ButtonFX.Overlay
    if ov and ov.IsCheckedSuppressed and ov.IsCheckedSuppressed(self.Widget) then
        self.Widget:SetChecked(false)
        local checkedTexture = self.Widget.GetCheckedTexture and self.Widget:GetCheckedTexture()
        if checkedTexture then
            checkedTexture:Hide()
        end
        return
    end
    
    if self.IgnoreCheckedVisual or self.IsMountButton or self.IsUnifiedMountButton then
        self.Widget:SetChecked(false)
        local checkedTexture = self.Widget.GetCheckedTexture and self.Widget:GetCheckedTexture()
        if checkedTexture then
            checkedTexture:Hide()
        end
        return
    end
    
    local shouldBeChecked = false
    
    if self.ActionType and self.ActionValue then
        if self.ActionType == "spell" then
            -- Prefer numeric spell ID so classic ranks stay distinct; name only if no id.
            if type(self.SpellId) == "number" and self.SpellId > 0 then
                if HasC_Spell() and C_Spell.IsCurrentSpell then
                    shouldBeChecked = C_Spell.IsCurrentSpell(self.SpellId)
                elseif IsCurrentSpell then
                    shouldBeChecked = IsCurrentSpell(self.SpellId)
                end
            else
                local spellName = self.SpellNameRank or self.SpellName or self.ActionValue
                if HasC_Spell() and C_Spell.IsCurrentSpell then
                    shouldBeChecked = C_Spell.IsCurrentSpell(spellName)
                elseif IsCurrentSpell then
                    shouldBeChecked = IsCurrentSpell(spellName)
                end
            end
        elseif self.ActionType == "item" then
            if HasC_Item() and C_Item.IsCurrentItem then
                shouldBeChecked = C_Item.IsCurrentItem(self.ActionValue)
            elseif IsCurrentItem then
                shouldBeChecked = IsCurrentItem(self.ActionValue)
            end
        elseif self.ActionType == "mount" then
            if C_MountJournal and C_MountJournal.GetMountInfoByID then
                shouldBeChecked = select(4, C_MountJournal.GetMountInfoByID(self.ActionValue)) or false
            end
        elseif self.ActionType == "battlepet" then
            if C_PetJournal and C_PetJournal.GetSummonedPetGUID then
                shouldBeChecked = self.ActionValue == C_PetJournal.GetSummonedPetGUID()
            end
        elseif self.ActionType == "macro" then
            if self.MacroMode == "spell" then
                if type(self.SpellId) == "number" and self.SpellId > 0 then
                    if HasC_Spell() and C_Spell.IsCurrentSpell then
                        shouldBeChecked = C_Spell.IsCurrentSpell(self.SpellId)
                    elseif IsCurrentSpell then
                        shouldBeChecked = IsCurrentSpell(self.SpellId)
                    end
                    if not shouldBeChecked then
                        if HasC_Spell() and C_Spell.IsAutoRepeatSpell then
                            shouldBeChecked = C_Spell.IsAutoRepeatSpell(self.SpellId)
                        elseif IsAutoRepeatSpell then
                            shouldBeChecked = IsAutoRepeatSpell(self.SpellId)
                        end
                    end
                elseif self.SpellNameRank then
                    if HasC_Spell() and C_Spell.IsCurrentSpell then
                        shouldBeChecked = C_Spell.IsCurrentSpell(self.SpellNameRank)
                    elseif IsCurrentSpell then
                        shouldBeChecked = IsCurrentSpell(self.SpellNameRank)
                    end
                    if not shouldBeChecked then
                        if HasC_Spell() and C_Spell.IsAutoRepeatSpell then
                            shouldBeChecked = C_Spell.IsAutoRepeatSpell(self.SpellNameRank)
                        elseif IsAutoRepeatSpell then
                            shouldBeChecked = IsAutoRepeatSpell(self.SpellNameRank)
                        end
                    end
                end
            elseif self.MacroMode == "item" and self.ItemId then
                if HasC_Item() and C_Item.IsCurrentItem then
                    shouldBeChecked = C_Item.IsCurrentItem(self.ItemId)
                elseif IsCurrentItem then
                    shouldBeChecked = IsCurrentItem(self.ItemId)
                end
            end
        elseif self.ActionType == "equipmentset" then
            -- Equipment sets never show as checked (matches ButtonForge behavior)
            -- They are a one-time action, not an ongoing state like spells or mounts
            shouldBeChecked = false
        elseif self.ActionType == "flyout" then
            -- Flyout spells should only show checked when their flyout is actually open
            local flyoutId = self.FlyoutId or self.ActionValue
            if flyoutId then
                -- Check if our custom flyout is open for this button
                if FluxFlyoutFrame and FluxFlyoutFrame.IsFlyoutOpenFor then
                    shouldBeChecked = FluxFlyoutFrame.IsFlyoutOpenFor(self.Widget)
                end
                
                -- Also check if Blizzard's native SpellFlyout is open and attached to this button
                if not shouldBeChecked and SpellFlyout then
                    -- SpellFlyout:IsAttachedToButton(button) checks if flyout is attached
                    if SpellFlyout.IsAttachedToButton and SpellFlyout:IsAttachedToButton(self.Widget) then
                        shouldBeChecked = SpellFlyout:IsShown() or false
                    end
                end
            end
        end
    end
    
    -- Action-bar badges: ButtonForge-style checked on THIS surface's SpellId.
    -- Also treat host IsCurrentAction as "native current" when BindingWins swapped
    -- the native spell onto this badge (Summon stays slot-current while icon is Freeze).
    if self._fluxIsActionBarBadge then
        if not shouldBeChecked then
            local host = self._fluxBadgeHost
            local slot = host and (host._state_action or host.action)
            if type(slot) ~= "number" and host and host.GetAttribute then
                slot = host:GetAttribute("action")
            end
            -- Swapped (BindingWins): native Summon is on this badge; slot stays
            -- IsCurrentAction while LAB icon is Freeze — badge owns the ring.
            if self._fluxBindingWins == true
                and type(slot) == "number" and slot > 0
                and IsCurrentAction and IsCurrentAction(slot) then
                shouldBeChecked = true
            end
        end
        if self.SetCheckedVisual then
            self:SetCheckedVisual(shouldBeChecked)
        elseif FluxBadgeButton and FluxBadgeButton.SetCheckedVisual then
            FluxBadgeButton.SetCheckedVisual(self, shouldBeChecked)
        else
            self.Widget:SetChecked(shouldBeChecked)
        end
        return
    end

    self.Widget:SetChecked(shouldBeChecked)
end

-- Update equipped state
function FluxButton:UpdateEquipped()
    if not self.WBorder then return end
    
    -- Apply proper sizing for pre-Dragonflight clients
    if FluxButtonUtil and FluxButtonUtil.AdjustEquipBorderSizeForClient then
        FluxButtonUtil:AdjustEquipBorderSizeForClient(self)
    end
    
    self.WBorder:Hide()
    
    -- Check for equipped items (direct item buttons)
    if self.ActionType == "item" and self.ItemId then
        local isEquipped = false
        if HasC_Item() and C_Item.IsEquippedItem then
            isEquipped = C_Item.IsEquippedItem(self.ItemId)
        elseif IsEquippedItem then
            isEquipped = IsEquippedItem(self.ItemId)
        end
        
        if isEquipped then
            self.WBorder:SetVertexColor(0, 1.0, 0, 0.35)
            self.WBorder:Show()
        end
    -- Check for equipped items in macros
    elseif self.ActionType == "macro" and self.MacroMode == "item" and self.ItemId then
        local isEquipped = false
        if HasC_Item() and C_Item.IsEquippedItem then
            isEquipped = C_Item.IsEquippedItem(self.ItemId)
        elseif IsEquippedItem then
            isEquipped = IsEquippedItem(self.ItemId)
        end
        
        if isEquipped then
            self.WBorder:SetVertexColor(0, 1.0, 0, 0.35)
            self.WBorder:Show()
        end
    end
end

-- Cooldown helpers (ButtonForge + Midnight duration-object path)
local function HasSpellCooldownDurationAPI()
    return C_Spell and type(C_Spell.GetSpellCooldownDuration) == "function"
end

local function HasActionCooldownDurationAPI()
    return C_ActionBar and type(C_ActionBar.GetActionCooldownDuration) == "function"
end

--- Duration objects are for secret-value / Midnight clients. Classic Era & Anniversary
--- keep numeric SetCooldown (ButtonForge Classic/TBC pattern) even if duration APIs exist in dumps.
local function ShouldUseDurationCooldownObjects()
    if not HasSpellCooldownDurationAPI() then
        return false
    end
    local api = FLUX_API
    if not api then
        return false
    end
    if api.hasCanAccessValue or api.isMidnight then
        return true
    end
    if api.isRetail and (api.buildNumber or 0) >= 66562 then
        return true
    end
    return false
end

local function ResolveOverrideSpellId(spellId)
    if type(spellId) ~= "number" then
        return spellId
    end
    if C_Spell and C_Spell.GetOverrideSpell then
        local ok, override = pcall(C_Spell.GetOverrideSpell, spellId)
        if ok and type(override) == "number" and override > 0 then
            return override
        end
    end
    return spellId
end

--- Merge charge cooldown into start/duration when charges are not full (Classic/Anniversary).
local function MergeSpellChargeCooldown(spellIdentifier, start, duration, enable)
    local currentCharges, maxCharges
    if not (C_Spell and C_Spell.GetSpellCharges) and not GetSpellCharges then
        return start, duration, enable, currentCharges, maxCharges
    end
    local chargesInfo
    if C_Spell and C_Spell.GetSpellCharges then
        chargesInfo = C_Spell.GetSpellCharges(spellIdentifier)
    end
    if chargesInfo and type(chargesInfo) == "table" then
        local API = FluxAPICompat and FluxAPICompat.API or {}
        local safeCompare = API.SafeCompare
        local needsChargeDisplay
        if chargesInfo.isActive ~= nil then
            needsChargeDisplay = chargesInfo.isActive and true or false
        elseif safeCompare then
            needsChargeDisplay = safeCompare(chargesInfo.currentCharges, chargesInfo.maxCharges, "~=")
        else
            needsChargeDisplay = chargesInfo.currentCharges ~= chargesInfo.maxCharges
        end
        if needsChargeDisplay ~= false then
            start = chargesInfo.cooldownStartTime or start
            duration = chargesInfo.cooldownDuration or duration
            currentCharges = chargesInfo.currentCharges
            maxCharges = chargesInfo.maxCharges
        end
    elseif GetSpellCharges then
        local charges, maxC, chargeStart, chargeDuration = GetSpellCharges(spellIdentifier)
        if charges and maxC and charges ~= maxC then
            start = chargeStart or start
            duration = chargeDuration or duration
            currentCharges = charges
            maxCharges = maxC
        end
    end
    return start, duration, enable, currentCharges, maxCharges
end

--- Resolve numeric spell cooldown (pre-duration-object clients).
local function ResolveSpellCooldownNumeric(spellIdentifier)
    local start, duration, enable = 0, 0, 0
    if HasC_Spell() and C_Spell.GetSpellCooldown then
        local cooldownInfo = C_Spell.GetSpellCooldown(spellIdentifier)
        if cooldownInfo and type(cooldownInfo) == "table" then
            start = cooldownInfo.startTime or 0
            duration = cooldownInfo.duration or 0
            enable = cooldownInfo.isEnabled
            if cooldownInfo.isActive == false then
                start, duration, enable = 0, 0, 0
            end
        end
    elseif GetSpellCooldown then
        start, duration, enable = GetSpellCooldown(spellIdentifier)
    end
    return MergeSpellChargeCooldown(spellIdentifier, start, duration, enable)
end

--- Resolve item cooldown across C_Item / C_Container / GetItemCooldown.
local function ResolveItemCooldownNumeric(itemId)
    if type(itemId) == "string" then
        local numericId = tonumber(itemId) or tonumber(itemId:match("(%d+)"))
        if numericId then
            itemId = numericId
        end
    end
    if not itemId or (type(itemId) ~= "number" and type(itemId) ~= "string") then
        return nil
    end
    local start, duration, enable = 0, 0, 0
    local currentCharges, maxCharges
    if C_Item and C_Item.GetItemCooldown then
        local cooldownInfo = C_Item.GetItemCooldown(itemId)
        if cooldownInfo == nil then
            return 0, 0, 0
        elseif type(cooldownInfo) == "table" then
            start = cooldownInfo.startTime or 0
            duration = cooldownInfo.duration or 0
            enable = cooldownInfo.isEnabled
        else
            start, duration, enable = C_Item.GetItemCooldown(itemId)
            start = start or 0
            duration = duration or 0
        end
        if C_Item.GetItemSpell then
            local _, spellID = C_Item.GetItemSpell(itemId)
            if spellID then
                start, duration, enable, currentCharges, maxCharges =
                    MergeSpellChargeCooldown(spellID, start, duration, enable)
            end
        end
        return start, duration, enable, currentCharges, maxCharges, itemId
    elseif C_Container and C_Container.GetItemCooldown then
        local a, b, c = C_Container.GetItemCooldown(itemId)
        if type(a) == "table" then
            return a.startTime or 0, a.duration or 0, a.isEnabled, nil, nil, itemId
        end
        return a or 0, b or 0, c or 1, nil, nil, itemId
    elseif GetItemCooldown then
        start, duration, enable = GetItemCooldown(itemId)
        return start or 0, duration or 0, enable, nil, nil, itemId
    end
    return 0, 0, 0, nil, nil, itemId
end

-- Clear cooldown update cache (call when leaving combat to allow immediate updates)
function FluxButton.ClearCooldownUpdateCache()
    -- retained for callers; per-button skip throttle removed
end

--- Clear cooldown visuals (duration-object or numeric). Combat-legal.
function FluxButton:ClearCooldownVisual()
    local cd = self.WCooldown
    if not cd then return end
    if cd.Clear then
        pcall(cd.Clear, cd)
    elseif cd.SetCooldown then
        pcall(cd.SetCooldown, cd, 0, 0)
    end
    if cd:IsShown() then
        cd:Hide()
    end
    self._lastCooldownVisible = false
    self._lastCooldownStart = 0
    self._lastCooldownDuration = 0
    self._lastCooldownIsCharge = nil
end

--- Paint via Midnight duration object when available; otherwise numeric SetCooldown.
function FluxButton:CooldownFrame_SetFromDurationObject(durationObject, isCharge)
    if not self.WCooldown then return end
    local cd = self.WCooldown
    if not durationObject then
        self:ClearCooldownVisual()
        return
    end
    local alpha = (cd.GetEffectiveAlpha and cd:GetEffectiveAlpha()) or 1
    if cd.SetSwipeColor then pcall(cd.SetSwipeColor, cd, 0, 0, 0, alpha) end
    if alpha > 0.4 then
        if cd.SetDrawBling then pcall(cd.SetDrawBling, cd, true) end
        if cd.SetDrawEdge then pcall(cd.SetDrawEdge, cd, isCharge and true or false) end
    else
        if cd.SetDrawBling then pcall(cd.SetDrawBling, cd, false) end
        if cd.SetDrawEdge then pcall(cd.SetDrawEdge, cd, false) end
    end
    if cd.SetDrawSwipe then pcall(cd.SetDrawSwipe, cd, not isCharge) end
    if cd.SetCooldownFromDurationObject then
        local ok = pcall(cd.SetCooldownFromDurationObject, cd, durationObject)
        if ok then
            if not cd:IsShown() then
                cd:Show()
            end
            self._lastCooldownVisible = true
            self._lastCooldownIsCharge = isCharge and true or nil
            -- Duration may be secret; leave numeric cache unset or try GetDuration.
            local dur = 0
            if durationObject.GetDuration then
                local okD, d = pcall(durationObject.GetDuration, durationObject)
                if okD and d ~= nil then
                    local API = FluxAPICompat and FluxAPICompat.API
                    if not API or not API.CanAccessValue or API.CanAccessValue(d) then
                        dur = tonumber(d) or 0
                    else
                        dur = 2 -- mark non-GCD for hiddenUnlessCd when secret
                    end
                end
            end
            self._lastCooldownDuration = dur > 0 and dur or 2
            self._lastCooldownStart = GetTime()
            if self.Widget and FluxButtonUtil and FluxButtonUtil.ApplyCooldownCountdownHorizontalScale then
                if self._fluxIsActionBarBadge then
                    local BCM = _G.FluxActionBarBadgeCooldown
                    if BCM and BCM.ApplyBadgeTextScale then
                        BCM.ApplyBadgeTextScale(self)
                    end
                end
                if cd.SetCountdownAbbrevThreshold then
                    pcall(cd.SetCountdownAbbrevThreshold, cd, 60)
                end
                if FluxButtonUtil.EnsureCooldownAboveCount then
                    FluxButtonUtil:EnsureCooldownAboveCount(self)
                end
                FluxButtonUtil:ApplyCooldownCountdownHorizontalScale(cd, self.Widget)
            end
            return
        end
    end
    -- Fallback: hide rather than leave stale swipe
    if cd.Clear then pcall(cd.Clear, cd) end
    cd:Hide()
    self._lastCooldownVisible = false
    self._lastCooldownDuration = 0
    self._lastCooldownIsCharge = nil
end

--- Apply spell cooldown: duration object on Midnight, numeric elsewhere.
function FluxButton:ApplySpellCooldown(spellIdentifier)
    if not spellIdentifier then
        self:CooldownFrame_SetTimer(0, 0, 0)
        return
    end
    spellIdentifier = ResolveOverrideSpellId(spellIdentifier)
    if self.Widget then
        self.Widget.spellID = type(spellIdentifier) == "number" and spellIdentifier or self.Widget.spellID
        self.Widget.action = nil
    end

    if ShouldUseDurationCooldownObjects() and type(spellIdentifier) == "number" then
        local cooldownInfo = C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(spellIdentifier)
        local chargeInfo = C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(spellIdentifier)
        local showCharge = false
        if chargeInfo then
            if chargeInfo.isActive ~= nil then
                showCharge = chargeInfo.isActive and true or false
            else
                local API = FluxAPICompat and FluxAPICompat.API or {}
                if API.SafeCompare then
                    showCharge = API.SafeCompare(chargeInfo.currentCharges, chargeInfo.maxCharges, "~=") ~= false
                        and chargeInfo.maxCharges and chargeInfo.maxCharges > 1
                else
                    showCharge = chargeInfo.currentCharges ~= chargeInfo.maxCharges
                        and (chargeInfo.maxCharges or 0) > 1
                end
            end
        end
        local showNormal = true
        if cooldownInfo and cooldownInfo.isActive == false and not showCharge then
            showNormal = false
        end
        if showCharge and C_Spell.GetSpellChargeDuration then
            local durObj = C_Spell.GetSpellChargeDuration(spellIdentifier)
            self:CooldownFrame_SetFromDurationObject(durObj, true)
            return
        end
        if showNormal then
            local durObj = C_Spell.GetSpellCooldownDuration(spellIdentifier)
            if durObj then
                self:CooldownFrame_SetFromDurationObject(durObj, false)
                return
            end
        end
        self:CooldownFrame_SetFromDurationObject(nil)
        return
    end

    local start, duration, enable, currentCharges, maxCharges = ResolveSpellCooldownNumeric(spellIdentifier)
    self:CooldownFrame_SetTimer(start, duration, enable, currentCharges, maxCharges)
end

--- Apply item/toy cooldown (always numeric — items have no duration-object API in BF).
function FluxButton:ApplyItemCooldown(itemId)
    local start, duration, enable, currentCharges, maxCharges = ResolveItemCooldownNumeric(itemId)
    if start == nil then
        self:CooldownFrame_SetTimer(0, 0, 0)
        return
    end
    self:CooldownFrame_SetTimer(start, duration, enable, currentCharges, maxCharges)
end

--- Apply action-slot cooldown (bar-synced badges).
function FluxButton:ApplyActionSlotCooldown(slot)
    if not slot or slot < 1 then
        self:CooldownFrame_SetTimer(0, 0, 0)
        return
    end
    if self.Widget then
        self.Widget.action = slot
        self.Widget.spellID = nil
    end
    if ShouldUseDurationCooldownObjects() and HasActionCooldownDurationAPI() then
        local cooldownInfo = C_ActionBar.GetActionCooldown and C_ActionBar.GetActionCooldown(slot)
        local chargeInfo = C_ActionBar.GetActionCharges and C_ActionBar.GetActionCharges(slot)
        local showCharge = false
        if chargeInfo then
            if chargeInfo.isActive ~= nil then
                showCharge = chargeInfo.isActive and true or false
            elseif chargeInfo.maxCharges and chargeInfo.currentCharges then
                showCharge = chargeInfo.maxCharges > 1 and chargeInfo.currentCharges < chargeInfo.maxCharges
            end
        end
        if showCharge and C_ActionBar.GetActionChargeDuration then
            local durObj = C_ActionBar.GetActionChargeDuration(slot)
            self:CooldownFrame_SetFromDurationObject(durObj, true)
            return
        end
        local showNormal = true
        if cooldownInfo and cooldownInfo.isActive == false and not showCharge then
            showNormal = false
        end
        if showNormal then
            local durObj = C_ActionBar.GetActionCooldownDuration(slot)
            if durObj then
                self:CooldownFrame_SetFromDurationObject(durObj, false)
                return
            end
        end
        self:CooldownFrame_SetFromDurationObject(nil)
        return
    end
    local start, duration, enable = 0, 0, 0
    local currentCharges, maxCharges
    if C_ActionBar and C_ActionBar.GetActionCooldown then
        local info = C_ActionBar.GetActionCooldown(slot)
        if info and type(info) == "table" then
            start = info.startTime or 0
            duration = info.duration or 0
            enable = info.isEnabled
        else
            start, duration, enable = C_ActionBar.GetActionCooldown(slot)
        end
        if C_ActionBar.GetActionCharges then
            local ch = C_ActionBar.GetActionCharges(slot)
            if ch and type(ch) == "table" and ch.maxCharges and ch.maxCharges > 1
                and ch.currentCharges and ch.currentCharges < ch.maxCharges then
                start = ch.cooldownStartTime or start
                duration = ch.cooldownDuration or duration
                currentCharges = ch.currentCharges
                maxCharges = ch.maxCharges
            end
        end
    elseif GetActionCooldown then
        start, duration, enable = GetActionCooldown(slot)
        if GetActionCharges then
            local charges, maxC, cStart, cDur = GetActionCharges(slot)
            if charges and maxC and maxC > 1 and charges < maxC then
                start, duration = cStart or start, cDur or duration
                currentCharges, maxCharges = charges, maxC
            end
        end
    end
    self:CooldownFrame_SetTimer(start or 0, duration or 0, enable, currentCharges, maxCharges)
end

-- Update cooldown
function FluxButton:UpdateCooldown()
    if not self.WCooldown then return end

    -- Stance extras (mage armor buff swipe) and consumable aura timers own the cooldown.
    -- Food/water must keep item/spell CD even if an aura flag was left on them.
    if self.IsFoodButton or self.IsWaterButton then
        self.FluxConsumableAuraCooldown = nil
    end
    if self.FluxStanceManagedCooldown or self.FluxConsumableAuraCooldown then
        return
    end

    if not self.ActionType or not self.ActionValue then
        self:ClearCooldownVisual()
        return
    end

    -- Check for Single-Button Assistant special handling
    if self.IsSingleButtonAssistant then
        self:UpdateCooldownSpellSingleButtonAssistant()
        return
    end

    -- Bar-synced badges: prefer action-slot cooldown (covers macros on the host slot).
    if self._fluxBadgeCooldownLeg == "bar"
        and type(self._fluxSyncedActionSlot) == "number"
        and self._fluxSyncedActionSlot >= 1 then
        self:ApplyActionSlotCooldown(self._fluxSyncedActionSlot)
        return
    end

    -- 12.0.0+: Skip cooldown updates for trading skills during combat to prevent flickering
    local has12SecretValues = FluxAPICompat and FluxAPICompat.FLUX_API and FluxAPICompat.FLUX_API.hasCanAccessValue
    if has12SecretValues and InCombatLockdown() then
        if self.ActionType == "spell" then
            local spellId = self.SpellId or self.ActionValue
            local spellName = self.SpellNameRank or self.SpellName
            local spellIdentifier = spellId or spellName
            if FluxButtonUsability and FluxButtonUsability.IsTradingSkill and FluxButtonUsability:IsTradingSkill(spellIdentifier) then
                self:ClearCooldownVisual()
                return
            end
        elseif self.ActionType == "macro" and self.MacroMode == "spell" then
            local spellId = self.SpellId
            if spellId and FluxButtonUsability and FluxButtonUsability.IsTradingSkill and FluxButtonUsability:IsTradingSkill(spellId) then
                self:ClearCooldownVisual()
                return
            end
        end
    end

    if self.ActionType == "spell" then
        local spellIdentifier = self.SpellId or self.ActionValue or self.SpellNameRank or self.SpellName
        self:ApplySpellCooldown(spellIdentifier)

    elseif self.ActionType == "item" or self.ActionType == "toy" then
        self:ApplyItemCooldown(self.ItemId or self.ActionValue)

    elseif self.ActionType == "macro" then
        if self.MacroMode == "spell" and (self.SpellId or self.SpellNameRank) then
            self:ApplySpellCooldown(self.SpellId or self.SpellNameRank)
        elseif self.MacroMode == "item" and self.ItemId then
            self:ApplyItemCooldown(self.ItemId)
        else
            self:CooldownFrame_SetTimer(0, 0, 0)
        end

    elseif self.ActionType == "mount" then
        -- Midnight: hide (secret-safe, ButtonForge). Classic/Anniversary: spell path via MountSpellId.
        if ShouldUseDurationCooldownObjects() or has12SecretValues then
            self:ClearCooldownVisual()
        elseif self.MountSpellId then
            self:ApplySpellCooldown(self.MountSpellId)
        else
            self:ClearCooldownVisual()
        end

    elseif self.ActionType == "battlepet" then
        if ShouldUseDurationCooldownObjects() or has12SecretValues then
            self:ClearCooldownVisual()
        elseif C_PetJournal and C_PetJournal.GetPetCooldownByGUID and self.ActionValue then
            local start, duration, enable = C_PetJournal.GetPetCooldownByGUID(self.ActionValue)
            self:CooldownFrame_SetTimer(start or 0, duration or 0, enable)
        else
            self:ClearCooldownVisual()
        end

    else
        self:CooldownFrame_SetTimer(0, 0, 0)
    end
end

-- Enhanced cooldown timer with charge support (ButtonForge pattern)
-- Updated for 12.0.0+ secret value compatibility
function FluxButton:CooldownFrame_SetTimer(start, duration, isEnabled, charges, maxCharges, forceShowDrawEdge)
    if not self.WCooldown then return end
    local cd = self.WCooldown

    -- Get FluxAPICompat helpers (with fallbacks for safety)
    local API = FluxAPICompat and FluxAPICompat.API or {}
    local canAccessValue = API.CanAccessValue or function() return true end
    local safeGetNumber = API.SafeGetNumber or function(v, d) return tonumber(v) or (d or 0) end
    local safeCompare = API.SafeCompare or function(a, b, op)
        if op == "~=" then return a ~= b end
        if op == ">" then return a > b end
        if op == "==" then return a == b end
        return nil
    end
    local safeBooleanTest = API.SafeBooleanTest or function(v, d) if v then return true else return d end end

    local canAccessStart = canAccessValue(start)
    local canAccessDuration = canAccessValue(duration)
    local canAccessEnabled = canAccessValue(isEnabled)
    local canAccessAll = canAccessStart and canAccessDuration and canAccessEnabled

    if canAccessAll then
        local startNum = safeGetNumber(start, 0)
        local durationNum = safeGetNumber(duration, 0)

        local shouldShowCooldown = false
        local enabledTest = safeBooleanTest(isEnabled, true)
        if enabledTest then
            local enabledNotZero = safeCompare(isEnabled, 0, "~=")
            if enabledNotZero ~= false then
                local hasDuration = safeCompare(durationNum, 0, ">")
                if hasDuration then
                    shouldShowCooldown = true
                end
            end
        end

        local wasVisible = cd:IsShown()
        local isCharge = false

        if shouldShowCooldown then
            local drawEdge = false
            local durationCheck = safeCompare(durationNum, 2, ">")
            if durationCheck and charges and maxCharges then
                local chargeNotZero = safeCompare(charges, 0, "~=")
                if chargeNotZero then
                    drawEdge = true
                    isCharge = true
                end
            end

            local alpha = (cd.GetEffectiveAlpha and cd:GetEffectiveAlpha()) or 1
            if cd.SetSwipeColor then cd:SetSwipeColor(0, 0, 0, alpha) end

            if alpha > 0.4 then
                if cd.SetDrawEdge then cd:SetDrawEdge(drawEdge or forceShowDrawEdge) end
                if cd.SetDrawBling then cd:SetDrawBling(true) end
            else
                if cd.SetDrawEdge then cd:SetDrawEdge(false) end
                if cd.SetDrawBling then cd:SetDrawBling(false) end
            end
            if cd.SetDrawSwipe then cd:SetDrawSwipe(not drawEdge) end

            if cd.SetCooldown then
                cd:SetCooldown(startNum, durationNum)
                if not wasVisible then
                    cd:Show()
                end
            end
        else
            if cd.Clear then
                pcall(cd.Clear, cd)
            elseif cd.SetCooldown then
                cd:SetCooldown(0, 0)
            end
            if wasVisible then
                cd:Hide()
            end
        end

        self._lastCooldownVisible = shouldShowCooldown
        self._lastCooldownStart = startNum
        self._lastCooldownDuration = durationNum
        self._lastCooldownIsCharge = isCharge and true or nil
    else
        -- Values are secret (12.0.0+ in combat). Prefer duration-object path when caller
        -- can; here we still try SetCooldown with secrets and Clear when it fails.
        local wasVisible = cd:IsShown()

        if cd.SetCooldown then
            local success = pcall(function()
                cd:SetCooldown(start, duration)
            end)

            if success then
                if not wasVisible then
                    cd:Show()
                end
                self._lastCooldownVisible = true
                -- Secret duration: mark as non-GCD so hiddenUnlessCd can show
                self._lastCooldownDuration = 2
                self._lastCooldownIsCharge = (charges and maxCharges) and true or nil
            else
                self:ClearCooldownVisual()
            end
        end
    end

    if self.Widget and cd and cd:IsShown() and FluxButtonUtil and FluxButtonUtil.ApplyCooldownCountdownHorizontalScale then
        -- Badges: re-apply per-binding CD digit size (do not hardcode 2/3).
        if self._fluxIsActionBarBadge then
            local BCM = _G.FluxActionBarBadgeCooldown
            if BCM and BCM.ApplyBadgeTextScale then
                BCM.ApplyBadgeTextScale(self)
            end
        end
        if cd.SetCountdownAbbrevThreshold then
            pcall(cd.SetCountdownAbbrevThreshold, cd, 60)
        end
        if FluxButtonUtil.EnsureCooldownAboveCount then
            FluxButtonUtil:EnsureCooldownAboveCount(self)
        end
        FluxButtonUtil:ApplyCooldownCountdownHorizontalScale(cd, self.Widget)
    end
end

-- Re-assert empty-slot placeholder look (desat + dark). Rank desat sweeps
-- can clear SetDesaturated(false) on ActiveButtons that have no spell id.
local function ApplyPlaceholderIconStyle(button)
    if not button or not button.WIcon or not button.PlaceholderTexture then
        return
    end
    if button.IsWispLockPlaceholder then
        return
    end
    button.WIcon:SetTexture(button.PlaceholderTexture)
    button.WIcon:SetDesaturated(true)
    button.WIcon:SetVertexColor(0.25, 0.25, 0.25)
    button.WIcon:Show()
end

-- Update usability
function FluxButton:UpdateUsable()
    if not self.WIcon then return end
    
    -- Keep placeholder colorless at all times (count 0 / unset item).
    if self.PlaceholderTexture then
        ApplyPlaceholderIconStyle(self)
        return
    end

    -- Multi-cast extras: native spell/item identity. Clear host aspect only.
    do
        local key = self._fluxBadgeKey
            or (self.Widget and self.Widget._fluxBadgeKey)
        local keyIsExtra = type(key) == "string" and key:sub(1, 6) == "extra:"
        if not keyIsExtra then
            if self._fluxIsMultiCastExtra then
                self._fluxIsMultiCastExtra = nil
            end
            if self.Widget and self.Widget._fluxIsMultiCastExtra then
                self.Widget._fluxIsMultiCastExtra = nil
            end
        else
            self._fluxIsMultiCastExtra = true
            self._fluxAspectDisplaySpellId = nil
            self._fluxAppliedMacrotext = nil
            self.MacroBody = nil
            if self.Widget then
                self.Widget._fluxIsMultiCastExtra = true
                self.Widget._fluxAspectDisplaySpellId = nil
            end
            if self._fluxWantItemId then
                self.ItemId = self._fluxWantItemId
                self.ActionType = "item"
                self.ActionValue = self._fluxWantItemId
                self.MacroMode = "item"
                self.SpellId = nil
            elseif self._fluxWantSpellId then
                self.SpellId = self._fluxWantSpellId
                self.ActionType = "spell"
                self.ActionValue = self._fluxWantSpellId
                self.MacroMode = "spell"
                self.ItemId = nil
                if self.Widget then self.Widget.spellID = self._fluxWantSpellId end
            end
        end
    end

    -- Rank desat first so usable paint / _fluxRankDesaturated flag is current.
    do
        local SRM = _G.FluxSpellRankManager
        if SRM and SRM.ApplyRankDesaturation and self.SpellId
            and (self.ActionType == "spell" or self.ActionType == "macro" or self.ActionType == "macrotext"
                or self.MacroMode == "spell") then
            SRM:ApplyRankDesaturation(self, self.SpellId)
        end
    end

    -- Display-only item buttons: skip unusable/mana dimming; keep icon + ring at "usable" look
    if self.IgnoreUsabilityVisual and self.WIcon then
        self._isUsable = true
        self._notEnoughMana = false
        self._usabilityState = FluxButtonUsability and FluxButtonUsability.STATE_USABLE or 1
        if FluxButtonUsability and FluxButtonUsability.ApplyVisualFeedback then
            FluxButtonUsability:ApplyVisualFeedback(self, FluxButtonUsability.STATE_USABLE, false)
        else
            self.WIcon:SetVertexColor(1, 1, 1)
            self.WIcon:SetDesaturated(self._fluxRankDesaturated and true or false)
        end
        return
    end

    -- Handle Single Button Assistant specially - it has dynamic spell changes
    if self.IsSingleButtonAssistant then
        local isUsable, notEnoughMana = self:UpdateUsableSpellSingleButtonAssistant()
        self._isUsable = isUsable
        self._notEnoughMana = notEnoughMana
        if not isUsable then
            self.WIcon:SetVertexColor(0.4, 0.4, 0.4)
            self.WIcon:SetDesaturated(true)
        elseif notEnoughMana then
            self.WIcon:SetVertexColor(0.2, 0.2, 1.0)
            self.WIcon:SetDesaturated(self._fluxRankDesaturated and true or false)
        else
            self.WIcon:SetVertexColor(1, 1, 1)
            self.WIcon:SetDesaturated(self._fluxRankDesaturated and true or false)
        end
        return
    end
    
    -- For buttons without actions (empty), treat as bright (matches ButtonForge behavior)
    if not self.ActionType or not self.ActionValue then
        self.WIcon:SetVertexColor(1, 1, 1)
        self.WIcon:SetDesaturated(self._fluxRankDesaturated and true or false)
        self._isUsable = true
        self._notEnoughMana = false
        self._usabilityState = FluxButtonUsability and FluxButtonUsability.STATE_UNKNOWN or 4
        return
    end
    
    -- Use FluxButtonUsability if available
    -- Note: Debouncing is handled inside FluxButtonUsability:ApplyVisualFeedback for 12.0.0+ clients
    if FluxButtonUsability and FluxButtonUsability.UpdateButton then
        FluxButtonUsability:UpdateButton(self)
        local SRM = _G.FluxSpellRankManager
        if SRM and SRM.ApplyRankDesaturation and self.SpellId
            and (self.ActionType == "spell" or self.ActionType == "macro" or self.ActionType == "macrotext"
                or self.MacroMode == "spell") then
            SRM:ApplyRankDesaturation(self, self.SpellId)
        end
        return 
    end

    -- Fallback usability check
    local isUsable, notEnoughMana = false, false
    
    if self.ActionType == "spell" then
        local spellName = self.SpellNameRank or self.SpellName or self.ActionValue
        if HasC_Spell() and C_Spell.IsSpellUsable then
            isUsable, notEnoughMana = C_Spell.IsSpellUsable(spellName)
        elseif IsUsableSpell then
            isUsable, notEnoughMana = IsUsableSpell(spellName)
        end
    elseif self.ActionType == "item" then
        if HasC_Item() and C_Item.IsUsableItem then
            isUsable, notEnoughMana = C_Item.IsUsableItem(self.ActionValue)
        elseif IsUsableItem then
            isUsable, notEnoughMana = IsUsableItem(self.ActionValue)
        end
    elseif self.ActionType == "macro" then
        if self.MacroMode == "spell" and self.SpellNameRank then
            if HasC_Spell() and C_Spell.IsSpellUsable then
                isUsable, notEnoughMana = C_Spell.IsSpellUsable(self.SpellNameRank)
            elseif IsUsableSpell then
                isUsable, notEnoughMana = IsUsableSpell(self.SpellNameRank)
            end
        elseif self.MacroMode == "item" and self.ItemId then
            if HasC_Item() and C_Item.IsUsableItem then
                isUsable, notEnoughMana = C_Item.IsUsableItem(self.ItemId)
            elseif IsUsableItem then
                isUsable, notEnoughMana = IsUsableItem(self.ItemId)
            end
        else
            isUsable = true -- Default for macros
        end
    else
        isUsable = true
    end
    
    -- Apply visual feedback (fallback path - FluxButtonUsability handles debouncing)
    if isUsable then
        self.WIcon:SetVertexColor(1, 1, 1)
        self.WIcon:SetDesaturated(self._fluxRankDesaturated and true or false)
    elseif notEnoughMana then
        self.WIcon:SetVertexColor(0.5, 0.5, 1.0)
        self.WIcon:SetDesaturated(self._fluxRankDesaturated and true or false)
    else
        self.WIcon:SetVertexColor(0.4, 0.4, 0.4)
        self.WIcon:SetDesaturated(self._fluxRankDesaturated and true or false)
    end

    local SRM = _G.FluxSpellRankManager
    if SRM and SRM.ApplyRankDesaturation and self.SpellId
        and (self.ActionType == "spell" or self.ActionType == "macro" or self.ActionType == "macrotext"
            or self.MacroMode == "spell") then
        SRM:ApplyRankDesaturation(self, self.SpellId)
    end
end

-- =============================================================================
-- TEXT COUNT HELPER FUNCTIONS (cross-version compatible)
-- =============================================================================
-- TEXT COUNT DISPLAY FUNCTIONS
-- =============================================================================

-- Update button text
function FluxButton:UpdateButtonText()
    if self.WCount then
        self:UpdateTextCount()
    end
    if self.WHotKey then
        -- Supports persistent hotkey display through FullRefresh()
        if self.HotkeyBinding and FluxNCHotkeyUtil and FluxNCHotkeyUtil.UpdateHotkeyText then
            FluxNCHotkeyUtil.UpdateHotkeyText(self, self.HotkeyBinding, self.HotkeyAddDynamicModifiers, self.HotkeyHasModifierAssignments, self.HotkeyIconSize)
        else
            self.WHotKey:SetText("")
            self.WHotKey:Hide()
        end
    end
    -- Don't clear name for macros - it's handled by UpdateTextCount()
    if self.WName and self.ActionType ~= "macro" then
        self.WName:SetText("")
    end
end

-- Reagent / cast count for spells (teleport runes, ritual reagents, etc.)
local function GetSpellReagentDisplayCount(spellId)
    if not spellId then
        return nil
    end
    if C_Spell and C_Spell.GetSpellCastCount then
        local count = C_Spell.GetSpellCastCount(spellId)
        if count ~= nil then
            return count
        end
    end
    if GetSpellCount then
        local ok, count = pcall(GetSpellCount, spellId)
        if ok and count ~= nil then
            return count
        end
    end
    local LCSAC = LibStub and LibStub("LibClassicSpellActionCount-1.0", true)
    if LCSAC and LCSAC.GetSpellReagentCount then
        local count = LCSAC:GetSpellReagentCount(spellId)
        if count ~= nil then
            return count
        end
    end
    return nil
end

-- Extra window / minimap: charged copies show remaining uses (2×3 = 6).
-- Combat gem/HS pass preferCopies so two stones show 2.
local function ExtraDisplayItemCount(itemId, opts)
    if not itemId then
        return nil
    end
    opts = opts or {}
    local Paint = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint
    if Paint and Paint.DisplayItemCount then
        return Paint.DisplayItemCount(itemId, opts)
    end
    local inv = _G.FluxInv
    local copies = 0
    if inv and inv.GetCount then
        copies = inv.GetCount(itemId, { includeBank = false, charges = false }) or 0
    elseif _G.FluxGetItemCount then
        copies = _G.FluxGetItemCount(itemId, { includeBank = false, charges = false }) or 0
    elseif C_Item and C_Item.GetItemCount then
        copies = C_Item.GetItemCount(itemId, false, false) or 0
    elseif GetItemCount then
        copies = GetItemCount(itemId, false, false) or 0
    end
    copies = tonumber(copies) or 0
    local uses = copies
    if inv and inv.GetLiveCount then
        uses = inv.GetLiveCount(itemId, { includeBank = false, charges = true }) or copies
    elseif _G.FluxGetItemCount then
        uses = _G.FluxGetItemCount(itemId, { includeBank = false, charges = true }) or copies
    elseif C_Item and C_Item.GetItemCount then
        uses = C_Item.GetItemCount(itemId, false, true) or copies
    elseif GetItemCount then
        uses = GetItemCount(itemId, false, true) or copies
    end
    uses = tonumber(uses) or 0
    if copies > 1 then
        if opts.preferCopies then
            return copies
        end
        if uses > copies then
            return uses
        end
        return copies
    end
    local Flux = _G.Flux
    local isConsumable = Flux and Flux.Item and Flux.Item.IsConsumable and Flux.Item.IsConsumable(itemId)
    if not isConsumable then
        isConsumable = C_Item and C_Item.IsConsumableItem and C_Item.IsConsumableItem(itemId)
    end
    if not isConsumable then
        isConsumable = IsConsumableItem and IsConsumableItem(itemId)
    end
    if copies == 0 then
        if isConsumable then
            return 0
        end
        return nil
    end
    if uses <= 0 then
        return copies
    end
    if uses > copies or isConsumable then
        return uses
    end
    return nil
end

-- Update text count (spell charges, item counts, reagents)
-- Simplified to match ButtonForge pattern - direct API usage without excessive pcall
function FluxButton:UpdateTextCount()
    if not self.WCount then return end

    -- Set digits and Show when non-empty (mirrors _ApplyCount; BadgeHost may have Hide'd WCount).
    local function setCountText(value)
        self.WCount:Show()
        if value == nil then
            self.WCount:SetText("")
            return
        end
        local Flux = _G.Flux
        local S = Flux and Flux.Secrets
        if S and S.IsSecretValue then
            local ok, secret = pcall(S.IsSecretValue, value)
            if ok and secret then
                self.WCount:SetText(value)
                return
            end
        end
        if S and S.SafeLooksEmpty and S.SafeLooksEmpty(value) then
            self.WCount:SetText("")
            return
        end
        if value == "" then
            self.WCount:SetText("")
            return
        end
        self.WCount:SetText(value)
    end

    -- Combat-swap macro: the digit is the [combat] face, not the home latch.
    if self._fluxCombatSwapBody then
        if self.MacroMode == "item" and self.ItemId then
            local n = ExtraDisplayItemCount(self.ItemId, { preferCopies = true })
            self._forcedCountLive = true
            self._liveCountItemId = self.ItemId
            self._forcedCount = n or 0
            self:_ApplyCount()
            return
        end
        if self.MacroMode == "spell" or self.MacroMode == "" then
            self._forcedCount = nil
            self._forcedCountLive = nil
            self._liveCountItemId = nil
            setCountText(nil)
            return
        end
    end
    
    -- PRIORITY: If a strict count has been set via SetCount(), use it and ignore auto-updates
    if self._forcedCount ~= nil then
        if self._forcedCountLive and self._liveCountItemId then
            local n = ExtraDisplayItemCount(self._liveCountItemId)
            if n ~= nil then
                self._forcedCount = n
            end
        elseif self.ActionType == "item" then
            local isCombatConsumable = self.IsBandageButton or self.IsHealPotionButton
                or self.IsHealingPotionButton or self.IsManaPotionButton or self.IsHealthstoneButton
            if isCombatConsumable then
                local itemId = tonumber(self.ItemId) or tonumber(self.ActionValue)
                if itemId and itemId > 0 then
                    self._forcedCountLive = true
                    self._liveCountItemId = itemId
                    self._forcedCount = ExtraDisplayItemCount(itemId) or 0
                end
            end
        end
        self:_ApplyCount() -- Ensure it's applied (font, visibility, etc.)
        return
    end
    
    if not self.ActionType or not self.ActionValue then
        setCountText("")
        return
    end
    
    if self.ActionType == "spell" then
        local spellId = self.SpellNameRank or self.SpellId or self.ActionValue
        
        -- Get FluxAPICompat helpers for secret value handling (12.0.0+)
        local API = FluxAPICompat and FluxAPICompat.API or {}
        local safeCompare = API.SafeCompare
        local canAccessValue = API.CanAccessValue or function() return true end
        
        local count = GetSpellReagentDisplayCount(spellId)

        -- Show if count != 0 OR spell is consumable (like ButtonForge)
        -- Use safe comparison for potentially secret values
        local isConsumable = IsConsumableSpell and IsConsumableSpell(spellId)
        local countNotZero = nil
        if count ~= nil then
            if safeCompare then
                countNotZero = safeCompare(count, 0, "~=")
            elseif canAccessValue(count) then
                countNotZero = count ~= 0
            end
        end
        
        if countNotZero or isConsumable then
            -- Check if we can display the count value
            if canAccessValue(count) then
                setCountText(count or 0)
            else
                setCountText("")  -- Can't display secret value
            end
            return
        end
        
        -- Fall back to charges
        if C_Spell and C_Spell.GetSpellCharges then
            local chargesInfo = C_Spell.GetSpellCharges(spellId)
            if chargesInfo then
                local hasMultipleCharges = nil
                if safeCompare then
                    hasMultipleCharges = safeCompare(chargesInfo.maxCharges, 1, "~=")
                elseif canAccessValue(chargesInfo.maxCharges) then
                    hasMultipleCharges = chargesInfo.maxCharges ~= 1
                end
                
                if hasMultipleCharges ~= false then
                    -- Check if we can access the charge count to display it
                    if canAccessValue(chargesInfo.currentCharges) then
                        setCountText(chargesInfo.currentCharges)
                    else
                        setCountText("")  -- Can't display secret value
                    end
                    return
                end
            end
        end
        
        setCountText("")
        
    elseif self.ActionType == "item" then
        local itemId = self.ItemId or self.ActionValue
        
        -- Get FluxAPICompat helpers for secret value handling (12.0.0+)
        local API = FluxAPICompat and FluxAPICompat.API or {}
        local safeCompare = API.SafeCompare
        local canAccessValue = API.CanAccessValue or function() return true end
        
        -- Copies when copies > 1; remaining uses only for a single charged/consumable copy.
        local itemCount = ExtraDisplayItemCount(itemId)
        
        -- Combat grid buttons: Always show count (even 1 or 0)
        if self.IsHealingPotionButton or self.IsManaPotionButton or self.IsBandageButton or self.IsHealthstoneButton or self.IsManaGemButton then
            if canAccessValue(itemCount) then
                setCountText(tostring(itemCount or 0))
            else
                setCountText("")  -- Can't display secret value
            end
            return
        end
        
        -- Show if consumable, stackable (incl. count 1), or count > 1 (ButtonForge logic)
        local isConsumable = Flux and Flux.Item and Flux.Item.IsConsumable and Flux.Item.IsConsumable(itemId)
        if not isConsumable then
            isConsumable = C_Item and C_Item.IsConsumableItem and C_Item.IsConsumableItem(itemId)
        end
        if not isConsumable then
            isConsumable = IsConsumableItem and IsConsumableItem(itemId)
        end
        local maxStack = (C_Item and C_Item.GetItemMaxStackSizeByID and C_Item.GetItemMaxStackSizeByID(itemId))
            or (GetItemInfo and select(8, GetItemInfo(itemId)))
        local isStackable = (tonumber(maxStack) or 1) > 1
        
        -- Use safe comparison for potentially secret values
        local countGreaterThanOne = nil
        local countAtLeastOne = nil
        if itemCount ~= nil then
            if safeCompare then
                countGreaterThanOne = safeCompare(itemCount, 1, ">")
                countAtLeastOne = safeCompare(itemCount, 0, ">")
            elseif canAccessValue(itemCount) then
                countGreaterThanOne = itemCount > 1
                countAtLeastOne = itemCount > 0
            end
        end
        
        if isConsumable or countGreaterThanOne or (isStackable and countAtLeastOne) then
            if canAccessValue(itemCount) then
                setCountText(itemCount or 0)
            else
                setCountText("")  -- Can't display secret value
            end
        else
            setCountText("")
        end
        
    elseif self.ActionType == "macro" then
        -- Get FluxAPICompat helpers for secret value handling (12.0.0+)
        local API = FluxAPICompat and FluxAPICompat.API or {}
        local safeCompare = API.SafeCompare
        local canAccessValue = API.CanAccessValue or function() return true end
        
        -- Delegate to spell/item logic based on MacroMode
        -- Badges may only have SpellId (FillBadgeWantGaps) without SpellNameRank.
        local macroSpellId = self.SpellNameRank or self.SpellId or self.ActionValue
        if self.MacroMode == "spell" and macroSpellId then
            local spellId = macroSpellId
            
            local count = GetSpellReagentDisplayCount(spellId)

            local isConsumable = IsConsumableSpell and IsConsumableSpell(spellId)
            
            -- Use safe comparison for potentially secret values
            local countNotZero = nil
            if count ~= nil then
                if safeCompare then
                    countNotZero = safeCompare(count, 0, "~=")
                elseif canAccessValue(count) then
                    countNotZero = count ~= 0
                end
            end
            
            if countNotZero or isConsumable then
                if canAccessValue(count) then
                    setCountText(count or 0)
                else
                    setCountText("")  -- Can't display secret value
                end
            else
                -- Fall back to charges
                if C_Spell and C_Spell.GetSpellCharges then
                    local chargesInfo = C_Spell.GetSpellCharges(spellId)
                    if chargesInfo then
                        local hasMultipleCharges = nil
                        if safeCompare then
                            hasMultipleCharges = safeCompare(chargesInfo.maxCharges, 1, "~=")
                        elseif canAccessValue(chargesInfo.maxCharges) then
                            hasMultipleCharges = chargesInfo.maxCharges ~= 1
                        end
                        
                        if hasMultipleCharges ~= false then
                            -- Check if we can access the charge count to display it
                            if canAccessValue(chargesInfo.currentCharges) then
                                setCountText(chargesInfo.currentCharges)
                            else
                                setCountText("")  -- Can't display secret value
                            end
                        else
                            setCountText("")
                        end
                    else
                        setCountText("")
                    end
                else
                    setCountText("")
                end
            end
            
        elseif self.MacroMode == "item" and self.ItemId then
            local itemId = self.ItemId
            
            -- Copies when copies > 1; remaining uses only for a single charged/consumable copy.
            local itemCount = ExtraDisplayItemCount(itemId)
            
            -- Combat grid buttons: Always show count (even 1 or 0)
            if self.IsHealingPotionButton or self.IsManaPotionButton or self.IsBandageButton or self.IsHealthstoneButton or self.IsManaGemButton then
                if canAccessValue(itemCount) then
                    setCountText(tostring(itemCount or 0))
                else
                    setCountText("")  -- Can't display secret value
                end
                return
            end
            
            -- Show if consumable, stackable (incl. count 1), or count > 1
            local isConsumable = C_Item and C_Item.IsConsumableItem and C_Item.IsConsumableItem(itemId)
            if not isConsumable then
                isConsumable = IsConsumableItem and IsConsumableItem(itemId)
            end
            local maxStack = (C_Item and C_Item.GetItemMaxStackSizeByID and C_Item.GetItemMaxStackSizeByID(itemId))
                or (GetItemInfo and select(8, GetItemInfo(itemId)))
            local isStackable = (tonumber(maxStack) or 1) > 1
            
            -- Use safe comparison for potentially secret values
            local countGreaterThanOne = nil
            local countAtLeastOne = nil
            if itemCount ~= nil then
                if safeCompare then
                    countGreaterThanOne = safeCompare(itemCount, 1, ">")
                    countAtLeastOne = safeCompare(itemCount, 0, ">")
                elseif canAccessValue(itemCount) then
                    countGreaterThanOne = itemCount > 1
                    countAtLeastOne = itemCount > 0
                end
            end
            
            if isConsumable or countGreaterThanOne or (isStackable and countAtLeastOne) then
                if canAccessValue(itemCount) then
                    setCountText(itemCount or 0)
                else
                    setCountText("")  -- Can't display secret value
                end
            else
                setCountText("")
            end
        else
            setCountText("")
        end
        
        -- Handle macro name display (ButtonForge pattern)
        local countEmpty = true
        local Flux = _G.Flux
        local S = Flux and Flux.Secrets
        local countText = self.WCount:GetText()
        if S and S.SafeLooksEmpty then
            countEmpty = S.SafeLooksEmpty(countText)
        elseif countText ~= nil then
            local secret = false
            if S and S.IsSecretValue then
                local ok, v = pcall(S.IsSecretValue, countText)
                secret = ok and v and true or false
            end
            if not secret then
                countEmpty = countText == ""
            else
                countEmpty = false
            end
        end
        if countEmpty and self.MacroTextEnabled and self.WName and self.MacroName then
            self.WName:SetText(self.MacroName)
        elseif self.WName then
            self.WName:SetText("")
        end
    else
        setCountText("")
    end

    -- Action-bar badges: item/charge/reagent digits match minirow count size.
    local BadgeAPI = _G.FluxBadgeButton
    if (self.badgeMode or self._fluxIsActionBarBadge) and BadgeAPI and BadgeAPI.SyncCountFont then
        BadgeAPI.SyncCountFont(self)
    end
    if FluxButtonUtil and FluxButtonUtil.EnsureCooldownAboveCount then
        FluxButtonUtil:EnsureCooldownAboveCount(self)
    end
end

-- Force class color on ring border for legacy clients
function FluxButton:ForceRingBorderClassColor()
    if not self.WNormalTexture then return end
    
    local isLegacy = IsLegacyClient()
    if not isLegacy then return end
    
    if FluxButtonUtil and FluxButtonUtil.GetClassColor then
        local classColor = FluxButtonUtil:GetClassColor()
        if classColor then
            self.WNormalTexture:SetVertexColor(classColor.r, classColor.g, classColor.b, 1.0)
        end
    end
end

-- Mouse enter handler
function FluxButton:OnEnter()
    if not self.TooltipEnabled then return end
    
    local w = self.Widget
    -- Proactively hide any existing global tooltips from other sources
    if GameTooltip and GameTooltip.Hide then pcall(function() GameTooltip:Hide() end) end
    if ShoppingTooltip1 and ShoppingTooltip1.Hide then pcall(function() ShoppingTooltip1:Hide() end) end
    if ShoppingTooltip2 and ShoppingTooltip2.Hide then pcall(function() ShoppingTooltip2:Hide() end) end
    if ShoppingTooltip3 and ShoppingTooltip3.Hide then pcall(function() ShoppingTooltip3:Hide() end) end
    
    -- Set up UpdateTooltip callback for auto-refresh (re-entrancy guard: Blizzard tooltip + layout SetAction
    -- can otherwise recurse through FullRefresh -> UpdateTooltip -> ShowTooltip -> ... -> stack overflow)
    if w then
        if self._fluxGridRestockTooltipHooked then
            local Tiers = _G.FluxRestockTiers
            w.UpdateTooltip = function()
                if self._fluxTooltipUpdateBusy or self._fluxGridRestockTooltipBusy then
                    return
                end
                self._fluxTooltipUpdateBusy = true
                pcall(function()
                    if Tiers and Tiers.RefreshGridButtonTooltip then
                        Tiers.RefreshGridButtonTooltip(self)
                    else
                        self:ShowTooltip()
                    end
                end)
                self._fluxTooltipUpdateBusy = nil
            end
        else
            w.UpdateTooltip = function()
                if self._fluxTooltipUpdateBusy or self._fluxGridRestockTooltipBusy then
                    return
                end
                self._fluxTooltipUpdateBusy = true
                pcall(function()
                    self:ShowTooltip()
                end)
                self._fluxTooltipUpdateBusy = nil
            end
        end
    end
    
    -- Show initial tooltip
    self:ShowTooltip()
    
    -- Start a 1s ticker for live conjure cooldown updates while hovered.
    if self.TooltipTicker and self.TooltipTicker.Cancel then
        self.TooltipTicker:Cancel()
        self.TooltipTicker = nil
    end
    local deferConjureTicker = false
    local pl = _G.FluxEBS_PostLoginBagRefresh
    if pl then
        if pl.IsPostLoginPulseActive and pl.IsPostLoginPulseActive() then
            deferConjureTicker = true
        elseif pl.IsPulseEndSettling and pl.IsPulseEndSettling() then
            deferConjureTicker = true
        elseif pl.IsPostLoginInteractiveSettle and pl.IsPostLoginInteractiveSettle() then
            deferConjureTicker = true
        end
    end
    if self._fluxTooltipNeedsLiveRefresh ~= false and not deferConjureTicker then
        local useHookedRefresh = self._fluxGridRestockTooltipHooked and not self._fluxTooltipNeedsLiveRefresh
        if not useHookedRefresh then
        self.TooltipTicker = C_Timer.NewTicker(1, function()
            if not self.Widget then return end
            local Guard = _G.FluxTooltipGuard
            local owned = (Guard and Guard.IsOwnedByWidget and Guard.IsOwnedByWidget(self.Widget))
                or (GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self.Widget))
            if owned then
                if self.Widget.UpdateTooltip then
                    self.Widget:UpdateTooltip()
                else
                    self:ShowTooltip()
                end
            else
                if self.TooltipTicker and self.TooltipTicker.Cancel then
                    self.TooltipTicker:Cancel()
                    self.TooltipTicker = nil
                end
            end
        end)
        end
    end
end

-- Show tooltip with proper cooldown updates.
-- Consumable Extra Buttons (_fluxIsolatedTooltip): private tip + Blizzard C_TooltipInfo body
-- so other addons cannot inject TooltipDataProcessor / GameTooltip hooks.
function FluxButton:ShowTooltip()
    if not self.TooltipEnabled then return end
    
    local w = self.Widget
    local Guard = FluxTooltipGuard
    local tip = GameTooltip
    if self._fluxIsolatedTooltip and Guard and Guard.GetIsolatedTooltip then
        tip = Guard.GetIsolatedTooltip()
        if GameTooltip then
            GameTooltip:Hide()
        end
    elseif Guard then
        Guard.Unblock(GameTooltip)
    end
    self._fluxActiveTooltip = tip

    local hookedRestock = self._fluxGridRestockTooltipHooked
    tip:SetOwner(w, "ANCHOR_RIGHT")
    
    -- Enable auto-refresh for cooldown updates (hooked grid buttons finish with updateTooltip=0)
    if tip.SetOwner and not hookedRestock then
        tip.updateTooltip = 1
    end
    
    -- Handle Single Button Assistant specially - it has dynamic spell changes
    if self.IsSingleButtonAssistant then
        self:ShowTooltipSpellSingleButtonAssistant()
        if FluxSafeGameTooltipShow then
            FluxSafeGameTooltipShow(tip)
        else
            tip:Show()
        end
        return
    end

    -- Isolated consumable Extra Buttons: Blizzard item text only (no foreign PostCalls).
    -- Exception: Recuperate (or any spell) bound on a food/consumable ExtraButton.
    if self._fluxIsolatedTooltip and Guard and (self.ActionType == "spell" or self.IsRecuperateMode) then
        local spellId = tonumber(self.SpellId or self.ActionValue)
        if spellId and tip.SetSpellByID then
            if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Block(tip) end
            local success = pcall(tip.SetSpellByID, tip, spellId)
            if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Unblock(tip) end
            if not success then
                local spellName = self.SpellName or self.SpellNameRank or tostring(spellId)
                tip:SetText(spellName, 1, 1, 1)
            end
        else
            tip:SetText(self.SpellName or self.PlaceholderLabel or "Spell", 1, 1, 1)
        end
        if FluxSafeGameTooltipShow then
            FluxSafeGameTooltipShow(tip)
        else
            tip:Show()
        end
        return
    end

    if self._fluxIsolatedTooltip and Guard and Guard.FillBlizzardItem then
        local itemId = self.ItemId
        if self.ActionType == "item" then
            itemId = self.ItemId or self.ActionValue
        end
        if self.ActionType == "macro" and self.MacroMode == "item" and self.ItemId then
            itemId = self.ItemId
        end
        if type(itemId) == "string" then
            itemId = tonumber(itemId) or tonumber(tostring(itemId):match("(%d+)"))
        else
            itemId = tonumber(itemId)
        end
        if itemId then
            local usedCombatMinimal = false
            if FLUX_API and FLUX_API.isV12 and InCombatLockdown() and FluxSafeTooltipSetItemCombatMinimal then
                usedCombatMinimal = FluxSafeTooltipSetItemCombatMinimal(tip, itemId)
            end
            if not usedCombatMinimal then
                if not Guard.FillBlizzardItem(tip, itemId) then
                    tip:SetText("Item", 1, 1, 1)
                end
            end
            if tip.SetOwner and not hookedRestock then
                tip.updateTooltip = 1
            end
        elseif self.PlaceholderLabel then
            tip:SetText(self.PlaceholderLabel, 1, 1, 1)
        else
            tip:SetText("Empty Slot", 0.5, 0.5, 0.5)
        end
        if FluxSafeGameTooltipShow then
            FluxSafeGameTooltipShow(tip)
        else
            tip:Show()
        end
        return
    end
    
    if self.ActionType == "spell" then
        local spellId = self.SpellId or self.ActionValue
        if spellId and type(spellId) == "number" then
            local canAccess = true
            if FluxAPICompat and FluxAPICompat.API and FluxAPICompat.API.CanAccessValue then
                canAccess = FluxAPICompat.API.CanAccessValue(spellId)
            end
            
            if canAccess and tip.SetSpellByID then
                -- On post-DF, do NOT Block: TooltipDataProcessor uses AddLine; blocking would prevent Blizzard from filling the tooltip
                if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Block(tip) end
                local success = pcall(tip.SetSpellByID, tip, spellId)
                if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Unblock(tip) end
                if not success then
                    local spellName = self.SpellName or self.SpellNameRank or tostring(spellId)
                    tip:SetText(spellName, 1, 1, 1)
                    tip:AddLine("Spell", 0.7, 0.7, 0.7, true)
                end
            else
                local spellName = self.SpellName or self.SpellNameRank or tostring(spellId)
                tip:SetText(spellName, 1, 1, 1)
                tip:AddLine("Spell", 0.7, 0.7, 0.7, true)
            end
        else
            tip:SetText(self.ActionValue or "Spell", 1, 1, 1)
        end
        
    elseif self.ActionType == "item" then
        local itemId = self.ItemId or self.ActionValue
        
        -- Ensure itemId is numeric
        if type(itemId) == "string" then
            local numericId = tonumber(itemId) or tonumber(itemId:match("(%d+)"))
            if numericId then
                itemId = numericId
            end
        end
        
        if itemId and type(itemId) == "number" then
            -- +12 / Midnight: addon-owned item tooltips + sell price can error in MoneyFrame_Update during Show;
            -- in combat use name-only tooltip (full tooltip after combat).
            local usedCombatMinimal = false
            if FLUX_API and FLUX_API.isV12 and InCombatLockdown() and FluxSafeTooltipSetItemCombatMinimal then
                usedCombatMinimal = FluxSafeTooltipSetItemCombatMinimal(tip, itemId)
            end
            if usedCombatMinimal then
                if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Unblock(tip) end
                if tip.SetOwner and not hookedRestock then
                    tip.updateTooltip = 1
                end
            else
            -- On post-DF, do NOT Block: TooltipDataProcessor uses AddLine
            if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Block(tip) end
            local found = false

            if self._fluxPreferItemByIdTooltip and tip.SetItemByID then
                if PlayerHasToy and PlayerHasToy(itemId) and tip.SetToyByItemID then
                    found = pcall(tip.SetToyByItemID, tip, itemId)
                else
                    found = pcall(tip.SetItemByID, tip, itemId)
                end
            end
            
            if not found and GetInventoryItemID then
                for slot = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 23 do
                    local invId = GetInventoryItemID("player", slot)
                    if invId and invId == itemId then
                        if FluxSafeTooltipSetInventoryItem then
                            FluxSafeTooltipSetInventoryItem(tip, "player", slot, itemId)
                        else
                            tip:SetInventoryItem("player", slot)
                        end
                        found = true
                        break
                    end
                end
            end
            
            if not found and C_Container and C_Container.GetContainerNumSlots then
                for bag = 0, 5 do
                    local num = C_Container.GetContainerNumSlots(bag)
                    if num and num > 0 then
                        for slot = 1, num do
                            local bid = (FluxGetContainerItemID or C_Container.GetContainerItemID)(bag, slot)
                            if bid and bid == itemId then
                                if FluxSafeTooltipSetBagItem then
                                    FluxSafeTooltipSetBagItem(tip, bag, slot, itemId)
                                else
                                    tip:SetBagItem(bag, slot)
                                end
                                found = true
                                break
                            end
                        end
                        if found then break end
                    end
                end
            end
            
            if not found then
                local success = false
                if PlayerHasToy and PlayerHasToy(itemId) and tip.SetToyByItemID then
                    success = pcall(tip.SetToyByItemID, tip, itemId)
                elseif tip.SetItemByID then
                    success = pcall(tip.SetItemByID, tip, itemId)
                end
                
                if not success then
                    local _, link = GetItemInfo(itemId)
                    if link and tip.SetHyperlink then
                        pcall(tip.SetHyperlink, tip, link)
                    else
                        tip:SetText("Item", 1, 1, 1)
                    end
                end
            end
            if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Unblock(tip) end
            
            -- Enable auto-refresh for item tooltips (cooldown updates)
            if tip.SetOwner and not hookedRestock then
                tip.updateTooltip = 1
            end
            end
            
        else
            tip:SetText("Item", 1, 1, 1)
        end
        
    elseif self.ActionType == "macro" then
        -- Mirror ButtonForge UpdateTooltipMacro: only show the spell/item
        -- tooltip when the macro body explicitly contains #showtooltip.
        -- Otherwise fall back to plain macro name text.
        if not self.MacroShowTooltip then
            tip:SetText(self.MacroName or "Macro", 1, 1, 1)
        elseif self.MacroMode == "spell" and self.SpellId then
            -- Check if spell ID is accessible (not secret) before calling SetSpellByID
            local canAccess = true
            if FluxAPICompat and FluxAPICompat.API and FluxAPICompat.API.CanAccessValue then
                canAccess = FluxAPICompat.API.CanAccessValue(self.SpellId)
            end
            
            if canAccess and tip.SetSpellByID then
                if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Block(tip) end
                local success = pcall(tip.SetSpellByID, tip, self.SpellId)
                if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Unblock(tip) end
                if not success then
                    tip:SetText(self.SpellNameRank or self.SpellName or self.MacroName or "Spell", 1, 1, 1)
                end
            else
                tip:SetText(self.SpellNameRank or self.SpellName or self.MacroName or "Spell", 1, 1, 1)
            end
        elseif self.MacroMode == "item" and self.ItemId then
            if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Block(tip) end
            local success = false
            if tip.SetItemByID then
                success = pcall(tip.SetItemByID, tip, self.ItemId)
            end
            if not success then
                local _, link = GetItemInfo(self.ItemId)
                if link and tip.SetHyperlink then
                    pcall(tip.SetHyperlink, tip, link)
                else
                    tip:SetText(self.MacroName or "Item", 1, 1, 1)
                end
            end
            if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Unblock(tip) end
            -- Enable auto-refresh for item tooltips
            if tip.SetOwner and not hookedRestock then
                tip.updateTooltip = 1
            end
        else
            tip:SetText(self.MacroName or "Macro", 1, 1, 1)
        end
        
    elseif self.ActionType == "flyout" then
        -- Get flyout info from spell book
        local flyoutIndex, flyoutBank = self:LookupFlyoutIndex(self.FlyoutId or self.ActionValue)
        if flyoutIndex and flyoutBank and tip.SetSpellBookItem then
            -- Use pcall to safely handle any secret value access
            local success = pcall(tip.SetSpellBookItem, tip, flyoutIndex, flyoutBank)
            if not success then
                tip:SetText("Flyout", 1, 1, 1)
                tip:AddLine("Click to open flyout", 1, 1, 1, true)
            end
        else
            tip:SetText("Flyout", 1, 1, 1)
            tip:AddLine("Click to open flyout", 1, 1, 1, true)
        end
        
    elseif self.ActionType == "equipmentset" then
        -- Show equipment set tooltip
        local setName = self.EquipmentSetName
        if setName then
            tip:SetText(setName, 1, 1, 1)
            tip:AddLine("Equipment Set", 0.7, 0.7, 0.7, true)
            -- Try to show full equipment set tooltip if available
            if C_EquipmentSet and C_EquipmentSet.GetEquipmentSetInfo then
                local setIndex = self.EquipmentSetId or self.ActionValue
                if setIndex then
                    -- Equipment sets don't have a direct tooltip API, so just show name
                    tip:AddLine("Right-click to equip", 0.5, 0.5, 0.5, true)
                end
            end
        else
            tip:SetText("Equipment Set", 1, 1, 1)
        end
        
    elseif self.ActionType == "mount" then
        -- Use SetMountBySpellID for proper mount tooltip (like old version)
        if C_MountJournal and C_MountJournal.GetMountInfoByID then
            local mountName, mountSpellID = C_MountJournal.GetMountInfoByID(self.ActionValue)
            if mountSpellID and tip.SetMountBySpellID then
                tip:SetMountBySpellID(mountSpellID)
            else
                -- Fallback to text
                tip:SetText(mountName or "Mount", 1, 1, 1)
                tip:AddLine("Mount", 0.7, 0.7, 0.7, true)
            end
        else
            tip:SetText("Mount", 1, 1, 1)
        end
        
    elseif self.ActionType == "battlepet" then
        -- Get pet info and show proper battle pet tooltip (like old version)
        if C_PetJournal and C_PetJournal.GetPetInfoByPetID then
            local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name = C_PetJournal.GetPetInfoByPetID(self.ActionValue)
            if customName or name then
                tip:SetText(customName or name, 1, 1, 1)
                -- Add cast time
                if SPELL_CAST_TIME_INSTANT then
                    tip:AddLine(SPELL_CAST_TIME_INSTANT, 1, 1, 1, true)
                end
                -- Add summon description
                if BATTLE_PET_TOOLTIP_SUMMON and name then
                    tip:AddLine(string.format(BATTLE_PET_TOOLTIP_SUMMON, name), nil, nil, nil, true)
                end
            else
                tip:SetText("Battle Pet", 1, 1, 1)
                tip:AddLine("Click to summon pet", 1, 1, 1, true)
            end
        else
            tip:SetText("Battle Pet", 1, 1, 1)
        end
        
    elseif self.PlaceholderLabel then
        tip:SetText(self.PlaceholderLabel, 1, 1, 1)

    else
        tip:SetText("Empty Slot", 0.5, 0.5, 0.5)
    end

    -- Craft hints for heal/mana/bandage ExtraButtons are appended via
    -- FluxEBSConsumableBridge.AppendCraftTooltipLines in each button's showTooltipExtras.

    if FluxSafeGameTooltipShow then
        FluxSafeGameTooltipShow(tip)
    else
        tip:Show()
    end
    if Guard and tip == GameTooltip then Guard.BlockUntilHide(tip) end
end

-- Mouse leave handler
function FluxButton:OnLeave()
    local Guard = _G.FluxTooltipGuard
    if Guard and Guard.HideForButton then
        Guard.HideForButton(self)
    else
        GameTooltip:Hide()
    end
    if self.Widget then
        self.Widget.UpdateTooltip = nil
    end
    if self.TooltipTicker and self.TooltipTicker.Cancel then
        self.TooltipTicker:Cancel()
        self.TooltipTicker = nil
    end
end

-- OnShow handler
function FluxButton:OnShow()
    self:FullRefresh()
end

-- OnHide handler
function FluxButton:OnHide()
    GameTooltip:Hide()
end

-- Mouse down handler
function FluxButton:OnMouseDown(button)
    -- Visual feedback
end

-- Mouse up handler
function FluxButton:OnMouseUp(button)
    -- Visual feedback
end

-- Drag start handler
function FluxButton:OnDragStart(button)
    if self.ButtonLocked then return end
    if InCombatLockdown() then return end
    
    if self.ActionType == "spell" then
        local spellIdentifier = self.SpellId or self.SpellName or self.ActionValue
        SafePickupSpell(spellIdentifier)
        self:ClearAction()
        if self.OnDelete then self.OnDelete() end
    elseif self.ActionType == "flyout" then
        -- For flyouts, use PickupSpellBookItem with the flyout's spellbook index
        local flyoutID = self.FlyoutId or self.ActionValue
        local pickupSuccessful = false
        
        -- Method 1: Use PickupSpellBookItem with flyout's spellbook index (correct approach)
        local flyoutIndex, flyoutBank = self:LookupFlyoutIndex(flyoutID)
        if flyoutIndex and flyoutBank and C_SpellBook and C_SpellBook.PickupSpellBookItem then
            local ok = pcall(C_SpellBook.PickupSpellBookItem, flyoutIndex, flyoutBank)
            if ok then pickupSuccessful = true end
        end
        
        -- Method 2: Fallback for legacy clients
        if not pickupSuccessful and flyoutIndex and flyoutBank and _G.PickupSpellBookItem then
            local ok = pcall(_G.PickupSpellBookItem, flyoutIndex, flyoutBank)
            if ok then pickupSuccessful = true end
        end
        
        -- Method 3: Use custom cursor state as fallback
        if not pickupSuccessful then
            self.customCursorType = "flyout"
            self.customCursorData = flyoutID
            pickupSuccessful = true
        end
        
        if pickupSuccessful then
    self:ClearAction()
            if self.OnDelete then self.OnDelete() end
        end
    elseif self.ActionType == "item" then
        local itemId = self.ItemId or self.ActionValue
        SafePickupItem(itemId)
        self:ClearAction()
        if self.OnDelete then self.OnDelete() end
    elseif self.ActionType == "macro" then
        local macroId = self.MacroIndex or self.ActionValue
        if type(macroId) == "number" then
            SafePickupMacro(macroId)
        end
        self:ClearAction()
        if self.OnDelete then self.OnDelete() end
    elseif self.ActionType == "equipmentset" then
        -- Pickup equipment set
        local setIndex = self.EquipmentSetId or self.ActionValue
        if setIndex and C_EquipmentSet and C_EquipmentSet.PickupEquipmentSet then
            pcall(C_EquipmentSet.PickupEquipmentSet, setIndex)
            self:ClearAction()
            if self.OnDelete then self.OnDelete() end
        end
    elseif self.ActionType == "mount" then
        local mountID = self.MountId or self.ActionValue
        local pickupSuccessful = false
        
        if C_MountJournal then
            -- Try to find mount in displayed mounts
            if C_MountJournal.GetNumDisplayedMounts then
                local numMounts = C_MountJournal.GetNumDisplayedMounts()
                for i = 1, numMounts do
                    local displayedMountID = C_MountJournal.GetDisplayedMountID(i)
                    if displayedMountID == mountID then
                        C_MountJournal.Pickup(i)
                        pickupSuccessful = true
                        break
                    end
                end
            end
            
            -- Fallback: Try direct pickup
            if not pickupSuccessful and C_MountJournal.Pickup then
                local ok = pcall(C_MountJournal.Pickup, mountID)
                if ok then pickupSuccessful = true end
            end
        end
        
        -- Custom cursor fallback
        if not pickupSuccessful then
            self.customCursorType = "mount"
            self.customCursorData = mountID
            pickupSuccessful = true
        end
        
        if pickupSuccessful then
            self:ClearAction()
            if self.OnDelete then self.OnDelete() end
        end
    elseif self.ActionType == "battlepet" then
        if C_PetJournal and C_PetJournal.PickupPet then
            C_PetJournal.PickupPet(self.ActionValue)
        end
        self:ClearAction()
        if self.OnDelete then self.OnDelete() end
    elseif self.ActionType == "action" then
        if PickupAction then
            PickupAction(self.ActionValue)
        end
    self:ClearAction()
        if self.OnDelete then self.OnDelete() end
    end
end

-- Receive drag handler
function FluxButton:OnReceiveDrag()
    if self.ButtonLocked then return end
    if InCombatLockdown() then return end
    
    -- Check for custom cursor state first (for flyouts/mounts that can't be picked up normally)
    if self.customCursorType == "flyout" then
        self:SetAction("flyout", self.customCursorData)
        self.customCursorType = nil
        self.customCursorData = nil
        ClearCursor()
        if self.OnReceiveDragCallback then
            self.OnReceiveDragCallback("flyout", self.customCursorData)
        end
        return
    elseif self.customCursorType == "mount" then
        self:SetAction("mount", self.customCursorData)
        self.customCursorType = nil
        self.customCursorData = nil
        ClearCursor()
        if self.OnReceiveDragCallback then
            self.OnReceiveDragCallback("mount", self.customCursorData)
        end
        return
    end
    
    local cursorType, cursorData, cursorSubType, cursorSubData = GetCursorInfo()
    
    if not cursorType then return end
    
    -- Store previous button state for potential swap
    local previousActionType = self.ActionType
    local previousActionValue = self.ActionValue
    local previousSpellId = self.SpellId
    local previousItemId = self.ItemId
    local previousMacroIndex = self.MacroIndex
    local previousFlyoutId = self.FlyoutId
    local previousMountId = self.MountId
    local previousPetId = self.PetId
    local previousEquipmentSetId = self.EquipmentSetId
    
    local actionType, actionValue
    
    -- Handle companion type first (mount or pet)
    if cursorType == "companion" then
        if cursorSubType == "MOUNT" then
            -- Enhanced mount detection: Convert collection display index to actual mount ID
            local actualMountID = cursorData
            if C_MountJournal and C_MountJournal.GetDisplayedMountID then
                local displayedMountID = C_MountJournal.GetDisplayedMountID(cursorData)
                if displayedMountID then
                    actualMountID = displayedMountID
                end
            end
            actionType = "mount"
            actionValue = actualMountID
        elseif cursorSubType == "CRITTER" then
            actionType = "battlepet"
            actionValue = cursorData
        else
            -- Default to mount for unknown companion types
            actionType = "mount"
            actionValue = cursorData
        end
    elseif cursorType == "spell" then
        -- Check for flyout subtype
        if cursorSubType and cursorSubType == "flyout" then
            actionType = "flyout"
            actionValue = cursorData
        else
            actionType = "spell"
            actionValue = cursorSubData or cursorData -- spellID
        end
    elseif cursorType == "flyout" then
        -- Direct flyout cursor type
        actionType = "flyout"
        actionValue = cursorData
    elseif cursorType == "item" then
        actionType = "item"
        -- Use helper to resolve item ID from various formats
        actionValue = FluxButtonUtil and FluxButtonUtil.GetItemIDFromIdentifier 
            and FluxButtonUtil.GetItemIDFromIdentifier(cursorData) 
            or cursorData
    elseif cursorType == "macro" then
        actionType = "macro"
        actionValue = cursorData -- macro index
    elseif cursorType == "mount" then
        actionType = "mount"
        actionValue = cursorData -- mount ID
    elseif cursorType == "battlepet" then
        actionType = "battlepet"
        actionValue = cursorData -- pet GUID
    elseif cursorType == "equipmentset" then
        -- Equipment set: cursorData is the set name, need to find set index
        actionType = "equipmentset"
        actionValue = nil
        if C_EquipmentSet and C_EquipmentSet.GetNumEquipmentSets then
            local setCount = C_EquipmentSet.GetNumEquipmentSets()
            for i = 0, setCount - 1 do
                local name, _, setIndex = C_EquipmentSet.GetEquipmentSetInfo(i)
                if name == cursorData then
                    actionValue = setIndex
                    break
                end
            end
        end
        -- If we couldn't find the set index, use the name as fallback
        if not actionValue then
            actionValue = cursorData
        end
    elseif cursorType == "action" then
        actionType = "action"
        actionValue = cursorData
    end
    
    if actionType and actionValue then
        -- Clear flyout attributes before setting new content to prevent persistence issues
        if not InCombatLockdown() and self.Widget then
            self.Widget:SetAttribute("type", nil)
            self.Widget:SetAttribute("spell", nil)
        end
        
        self:SetAction(actionType, actionValue)
        ClearCursor()
        
        if self.OnReceiveDragCallback then
            self.OnReceiveDragCallback(actionType, actionValue)
        end
        
        -- Put previous item back on cursor (swap functionality)
        if previousActionType and previousActionValue then
            if previousActionType == "spell" then
                local spellId = previousSpellId or previousActionValue
                SafePickupSpell(spellId)
            elseif previousActionType == "flyout" and previousFlyoutId then
                SafePickupSpell(previousFlyoutId)
            elseif previousActionType == "item" and previousItemId then
                SafePickupItem(previousItemId)
            elseif previousActionType == "macro" and previousMacroIndex then
                SafePickupMacro(previousMacroIndex)
            elseif previousActionType == "mount" and previousMountId then
                -- For mounts, just clear cursor (mounts can't always be picked up)
        ClearCursor()
            elseif previousActionType == "battlepet" and previousPetId then
                -- For pets, just clear cursor
        ClearCursor()
            elseif previousActionType == "equipmentset" and previousEquipmentSetId then
                -- Pickup equipment set
                if C_EquipmentSet and C_EquipmentSet.PickupEquipmentSet then
                    pcall(C_EquipmentSet.PickupEquipmentSet, previousEquipmentSetId)
                else
        ClearCursor()
         end
            else
         ClearCursor()
            end
        end
    end
end

-- Drag stop handler
function FluxButton:OnDragStop()
    -- Nothing needed
end

-- ============================================================================
-- SINGLE-BUTTON ASSISTANT FUNCTIONS (Rotation Helper)
-- Based on ButtonForge's implementation
-- ============================================================================

-- Clear Single-Button Assistant state and hide overlay
function FluxButton:ClearSingleButtonAssistant()
    if self.SingleButtonAssistantOverlayFrame then
        self.SingleButtonAssistantOverlayFrame:Hide()
        self.SingleButtonAssistantOverlayFrame = nil
    end
    if self.SingleButtonAssistantOnUpdateFrame then
        self.SingleButtonAssistantOnUpdateFrame:SetScript("OnUpdate", nil)
        self.SingleButtonAssistantOnUpdateFrame = nil
    end
    self.IsSingleButtonAssistant = false
    self.SingleButtonAssistantSpellId = nil  -- Clear VFX spell ID
end

-- Size/anchor the inactive rotation ring to the button (same as Blizzard assisted rotation frame).
function FluxButton:UpdateSingleButtonAssistantOverlayLayout()
    local overlay = self.SingleButtonAssistantOverlayFrame
    local widget = self.Widget
    if not overlay or not widget then return end
    local w, h = widget:GetWidth(), widget:GetHeight()
    if not w or not h or w <= 0 or h <= 0 then return end
    overlay:SetScale(1)
    overlay:SetSize(w * SINGLE_BUTTON_ASSISTANT_OVERLAY_SCALE, h * SINGLE_BUTTON_ASSISTANT_OVERLAY_SCALE)
    overlay:ClearAllPoints()
    overlay:SetPoint("CENTER", widget, "CENTER", SINGLE_BUTTON_ASSISTANT_OVERLAY_ANCHOR_X, SINGLE_BUTTON_ASSISTANT_OVERLAY_ANCHOR_Y)
    local tex = overlay.Texture
    if tex then
        tex:SetAtlas("UI-HUD-RotationHelper-Inactive", false)
        tex:SetAllPoints(overlay)
    end
end

-- Set up the visual overlay frame for Single-Button Assistant
function FluxButton:SetupSingleButtonAssistantOverlay()
    if not self.Widget then return end
    
    -- Create overlay frame if it doesn't exist
    if not self.SingleButtonAssistantOverlayFrame then
        local overlay = CreateFrame("Frame", nil, self.Widget)
        overlay:SetFrameStrata(self.Widget:GetFrameStrata())
        overlay:SetFrameLevel(self.Widget:GetFrameLevel() + 10)
        
        -- Create texture with rotation helper atlas
        local tex = overlay:CreateTexture(nil, "OVERLAY")
        tex:SetAtlas("UI-HUD-RotationHelper-Inactive", false)
        tex:SetAllPoints(overlay)
        overlay.Texture = tex
        
        self.SingleButtonAssistantOverlayFrame = overlay

        local button = self
        if not self.Widget._fluxSingleButtonAssistantSizeHook then
            self.Widget._fluxSingleButtonAssistantSizeHook = true
            self.Widget:HookScript("OnSizeChanged", function()
                if button.IsSingleButtonAssistant and button.SingleButtonAssistantOverlayFrame then
                    button:UpdateSingleButtonAssistantOverlayLayout()
                end
            end)
        end
    end

    self:UpdateSingleButtonAssistantOverlayLayout()
    self.SingleButtonAssistantOverlayFrame:Show()
end

-- Set up OnUpdate handler for periodic next-spell refresh.
-- Prefer AssistedCombat highlight events; fall back to combat-gated 10Hz poll.
function FluxButton:SetupSingleButtonAssistantOnUpdate()
    if not self.Widget then return end
    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
        return
    end

    if not self.SingleButtonAssistantOnUpdateFrame then
        self.SingleButtonAssistantOnUpdateFrame = CreateFrame("Frame")
        _G.FluxEBSSingleButtonAssistantDriver = self.SingleButtonAssistantOnUpdateFrame
    end

    local button = self
    local updateInterval = 0.1
    local timeSinceLastUpdate = 0
    local lastSpellID = nil

    local function RefreshIfChanged()
        if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
            return
        end
        local spellID = C_AssistedCombat.GetNextCastSpell(true)
        if spellID ~= lastSpellID then
            lastSpellID = spellID
            if button.UpdateTexture then button:UpdateTexture() end
            if button.UpdateCooldown then button:UpdateCooldown() end
            if button.UpdateUsable then button:UpdateUsable() end
        end
    end

    local function ArmPoll()
        local f = button.SingleButtonAssistantOnUpdateFrame
        if not f then return end
        timeSinceLastUpdate = 0
        f:SetScript("OnUpdate", function(_, elapsed)
            -- OOC / hidden: disarm continuous poll (events re-arm in combat).
            if not (InCombatLockdown and InCombatLockdown()) then
                f:SetScript("OnUpdate", nil)
                return
            end
            local widget = button.Widget
            if widget and widget.IsShown and not widget:IsShown() then
                f:SetScript("OnUpdate", nil)
                return
            end
            timeSinceLastUpdate = timeSinceLastUpdate + (elapsed or 0)
            if timeSinceLastUpdate < updateInterval then return end
            timeSinceLastUpdate = 0
            RefreshIfChanged()
        end)
    end

    local f = self.SingleButtonAssistantOnUpdateFrame
    f:UnregisterAllEvents()
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    -- Retail AssistedCombat highlight changes (when available).
    if C_AssistedCombat then
        pcall(function()
            if EventRegistry and EventRegistry.RegisterCallback then
                -- no-op placeholder; prefer unit events below
            end
        end)
    end
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            f:SetScript("OnUpdate", nil)
            RefreshIfChanged()
            return
        end
        if event == "PLAYER_REGEN_DISABLED" then
            ArmPoll()
            RefreshIfChanged()
            return
        end
        RefreshIfChanged()
    end)

    if InCombatLockdown and InCombatLockdown() then
        ArmPoll()
    else
        f:SetScript("OnUpdate", nil)
    end
    RefreshIfChanged()
end

-- Update texture for Single-Button Assistant (dynamic next spell icon)
function FluxButton:UpdateTextureSpellSingleButtonAssistant()
    -- Check if C_AssistedCombat API is available
    if not C_AssistedCombat then
        -- Fallback to normal spell texture
        self:UpdateTextureSpell()
        return
    end
    
    -- Get the next recommended spell
    local checkForVisibleButton = true
    local spellID = C_AssistedCombat.GetNextCastSpell(checkForVisibleButton)
    
    if spellID == nil then
        -- No next spell, use the action spell as fallback
        if C_AssistedCombat.GetActionSpell then
            local actionSpellID = C_AssistedCombat.GetActionSpell()
            if actionSpellID and C_Spell and C_Spell.GetSpellTexture then
                local texture = C_Spell.GetSpellTexture(actionSpellID)
                self.WIcon:SetTexture(texture or "Interface/Icons/INV_Misc_QuestionMark")
                self.WIcon:Show()
                -- CRITICAL: Update widget.spellID for ActionButton_UpdateCooldown safety
                -- Also store on FluxButton for VFX matching
                if self.Widget then
                    self.Widget.spellID = actionSpellID
                end
                self.SingleButtonAssistantSpellId = actionSpellID  -- Store for VFX matching
                return
            end
        end
        -- Ultimate fallback
        self.WIcon:SetTexture(self.Texture or "Interface/Icons/INV_Misc_QuestionMark")
        self.WIcon:Show()
        return
    end
    
    -- CRITICAL: Update widget.spellID for ActionButton_UpdateCooldown safety
    -- Also store on FluxButton for VFX matching
    if self.Widget then
        self.Widget.spellID = spellID
    end
    self.SingleButtonAssistantSpellId = spellID  -- Store for VFX matching
    
    -- Get spell info for the next recommended spell
    if C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            self.WIcon:SetTexture(spellInfo.iconID or "Interface/Icons/INV_Misc_QuestionMark")
            self.WIcon:Show()
            return
        end
    end
    
    -- Fallback to GetSpellTexture
    if C_Spell and C_Spell.GetSpellTexture then
        local texture = C_Spell.GetSpellTexture(spellID)
        self.WIcon:SetTexture(texture or "Interface/Icons/INV_Misc_QuestionMark")
    else
        self.WIcon:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
    end
    self.WIcon:Show()
end

-- Update cooldown for Single-Button Assistant (dynamic next spell cooldown)
function FluxButton:UpdateCooldownSpellSingleButtonAssistant()
    -- Check if C_AssistedCombat API is available
    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
        self.WCooldown:Hide()
        self._lastCooldownVisible = false
        return
    end

    -- Get the next recommended spell
    local checkForVisibleButton = true
    local spellID = C_AssistedCombat.GetNextCastSpell(checkForVisibleButton)

    if spellID == nil then
        self.WCooldown:Hide()
        self.SingleButtonAssistantSpellId = nil
        self._lastCooldownVisible = false
        return
    end

    -- Store spell ID for VFX matching
    self.SingleButtonAssistantSpellId = spellID
    if self.Widget then
        self.Widget.spellID = spellID
    end

    self:ApplySpellCooldown(spellID)
end

-- Update usability for Single-Button Assistant (dynamic next spell usability)
function FluxButton:UpdateUsableSpellSingleButtonAssistant()
    -- Check if C_AssistedCombat API is available
    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
        return false, false
    end
    
    -- Get the next recommended spell
    local checkForVisibleButton = true
    local spellID = C_AssistedCombat.GetNextCastSpell(checkForVisibleButton)
    
    if spellID == nil then
        -- Clear stored spell ID if no spell available
        self.SingleButtonAssistantSpellId = nil
        return false, false
    end
    
    -- Store spell ID for VFX matching
    self.SingleButtonAssistantSpellId = spellID
    if self.Widget then
        self.Widget.spellID = spellID
    end
    
    -- Check usability for the next recommended spell
    if C_Spell and C_Spell.IsSpellUsable then
        local isUsable, notEnoughMana = C_Spell.IsSpellUsable(spellID)
        return isUsable, notEnoughMana
    end
    
    -- Fallback for legacy API
    if IsUsableSpell then
        local isUsable, notEnoughMana = IsUsableSpell(spellID)
        return isUsable, notEnoughMana
    end
    
    return false, false
end

-- Show tooltip for Single-Button Assistant (dynamic next spell tooltip)
function FluxButton:ShowTooltipSpellSingleButtonAssistant()
    -- Helper function to safely show spell tooltip
    local function SafeSetSpellByID(spellId)
        if not spellId or not GameTooltip.SetSpellByID then return false end
        
        -- Check if spell ID is accessible (not secret) before calling SetSpellByID
        local canAccess = true
        if FluxAPICompat and FluxAPICompat.API and FluxAPICompat.API.CanAccessValue then
            canAccess = FluxAPICompat.API.CanAccessValue(spellId)
        end
        
        if canAccess then
            local success = pcall(GameTooltip.SetSpellByID, GameTooltip, spellId, false, true)
            return success
        end
        return false
    end
    
    -- Check if C_AssistedCombat API is available
    if not C_AssistedCombat then
        -- Fallback to normal spell tooltip
        if not SafeSetSpellByID(self.SpellId) and self.SpellName then
            GameTooltip:SetText(self.SpellName, 1, 1, 1)
        end
        return
    end
    
    -- Get the next recommended spell
    local checkForVisibleButton = true
    local spellID = C_AssistedCombat.GetNextCastSpell(checkForVisibleButton)
    
    if spellID == nil then
        -- No next spell, use the action spell
        if C_AssistedCombat.GetActionSpell then
            spellID = C_AssistedCombat.GetActionSpell()
        end
    end
    
    -- Show tooltip for the determined spell
    if spellID then
        if not SafeSetSpellByID(spellID) then
            -- Fallback: try to get spell name
            local spellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
            if spellName then
                GameTooltip:SetText(spellName, 1, 1, 1)
            end
        end
    elseif self.SpellId then
        -- Ultimate fallback to stored spell ID
        if not SafeSetSpellByID(self.SpellId) and self.SpellName then
            GameTooltip:SetText(self.SpellName, 1, 1, 1)
        end
    end
end

-- Destroy button
function FluxButton:Destroy()
    -- Clear Single-Button Assistant state first
    self:ClearSingleButtonAssistant()

    if FluxButtonEvents and FluxButtonEvents.UnregisterButton then
        FluxButtonEvents.UnregisterButton(self)
    end

    if self.Widget then
        self.Widget:Hide()
        self.Widget:ClearAllPoints()
        self.Widget:SetParent(nil)
    end
end

-- Hook Blizzard's SpellFlyout to update checked state on all flyout buttons
-- This ensures flyout buttons only show checked when their flyout is actually open
local function UpdateAllFlyoutButtons()
    if FluxButtonEvents and FluxButtonEvents.ActiveButtons then
        for _, button in ipairs(FluxButtonEvents.ActiveButtons) do
            if button and button.ActionType == "flyout" and button.UpdateChecked then
                button:UpdateChecked()
            end
        end
    end
end

-- Hook SpellFlyout show/hide if it exists (use hooksecurefunc to avoid taint)
-- ============================================================================
-- DISABLED: SpellFlyout Global Hooks
-- ============================================================================
-- These hooks were causing taint propagation because:
-- 1. hooksecurefunc on SpellFlyout adds insecure addon code to the secure call chain
-- 2. When SpellFlyout Show/Hide is called by Blizzard's secure code, our hook runs
-- 3. This taints the execution path, causing ADDON_ACTION_BLOCKED on action buttons
-- ============================================================================
--[[
if SpellFlyout then
    -- Use hooksecurefunc for Show - runs after original without taint
    hooksecurefunc(SpellFlyout, "Show", function(self)
        C_Timer.After(0.01, UpdateAllFlyoutButtons)
    end)
    
    -- Use hooksecurefunc for Hide - runs after original without taint
    hooksecurefunc(SpellFlyout, "Hide", function(self)
        C_Timer.After(0.01, UpdateAllFlyoutButtons)
    end)
    
    -- Hook OnShow/OnHide using HookScript (safe, doesn't replace the original script)
    SpellFlyout:HookScript("OnShow", function(self)
        C_Timer.After(0.01, UpdateAllFlyoutButtons)
    end)
    
    SpellFlyout:HookScript("OnHide", function(self)
        C_Timer.After(0.01, UpdateAllFlyoutButtons)
    end)
    
    -- Helper function to detect if a button is an ExtraButton (not an ActionBar button)
    local function IsExtraButtonFlyout(flyoutButton)
        if not flyoutButton then return false end
        
        -- Check for FluxButton instance flag
        if flyoutButton.FluxButton and flyoutButton.FluxButton._isExtraButton then
            return true
        end
        
        -- Check for _isExtraButton flag on widget
        if flyoutButton._isExtraButton then
            return true
        end
        
        -- Check parent hierarchy for ExtraButtons frames
        local parentFrame = flyoutButton:GetParent()
        while parentFrame do
            local parentName = parentFrame:GetName() or ""
            if parentName:match("ExtraButtons") or
               parentName:match("ExtraButtonsMainFrame") or
               parentName:match("ExtraButtonsContent") or
               parentName:match("ExtraButtonsScroll") or
               parentName:match("FluxButtonGrid") or
               parentName:match("FluxUtility") or
               parentName:match("FluxMage") or
               parentName:match("FluxNonCombatGrid") or
               parentName:match("NonCombatGrid") then
                return true
            end
            parentFrame = parentFrame:GetParent()
        end
        
        return false
    end
    
    -- Use hooksecurefunc for Toggle - runs after original without taint
    -- Blizzard's SmallActionButtonTemplate is 30x30, we scale up for better visibility on ExtraButtons
    hooksecurefunc(SpellFlyout, "Toggle", function(self, flyoutButton, flyoutID, isActionBar, specID, showFullTooltip, reason)
        -- Check if attached to ExtraButton (not ActionBar)
        local isExtraButton = IsExtraButtonFlyout(flyoutButton)
        
        if isExtraButton and self:IsShown() then
            -- Scale factor to make 30x30 buttons appear larger to match our custom flyout visual size
            local SCALE_FACTOR = 1.15
            
            -- Apply scale to all visible buttons after a small delay (buttons need time to be created)
            C_Timer.After(0.01, function()
                if not self:IsShown() then return end
                
                local i = 1
                local button = _G["SpellFlyoutPopupButton" .. i]
                while button do
                    if button:IsShown() then
                        button:SetScale(SCALE_FACTOR)
                    end
                    i = i + 1
                    button = _G["SpellFlyoutPopupButton" .. i]
                end
                
                -- Call Layout() to reflow with new button scales
                if self.Layout then
                    self:Layout()
                end
            end)
        else
            -- Reset scale for ActionBar flyouts (ensure they're back to normal)
            C_Timer.After(0.01, function()
                local i = 1
                local button = _G["SpellFlyoutPopupButton" .. i]
                while button do
                    button:SetScale(1.0)
                    i = i + 1
                    button = _G["SpellFlyoutPopupButton" .. i]
                end
            end)
        end
    end)
end
]]

-- Export
_G.FluxButton = FluxButton


-- Manually set the count text on the button
-- This overrides default behavior and allows showing "0" or "1" explicitly
-- @param count Number or String to display. If nil, hides the count.
-- @param opts table|nil { live = true, itemId = number } re-fetch on each UpdateTextCount
function FluxButton:SetCount(count, opts)
    if not self.WCount then 
        -- Try to find it if missing (sometimes updated after creation)
        if self.Widget and self.Widget.Count then
            self.WCount = self.Widget.Count
        end
        if not self.WCount then return end
    end

    if type(opts) == "table" and opts.live then
        self._forcedCountLive = true
        self._liveCountItemId = opts.itemId or self.ItemId or self.ActionValue
    else
        self._forcedCountLive = nil
        self._liveCountItemId = nil
    end
    
    self._forcedCount = count -- Store for hook re-application
    self:_ApplyCount()
    
    -- Hook UpdateTextCount on the widget to persist our count
    -- This handles cases where WoW's ActionButton_UpdateCount clears our text
    if self.Widget and not self._countHooked then
        if self.Widget.UpdateTextCount then
            hooksecurefunc(self.Widget, "UpdateTextCount", function()
                self:_ApplyCount()
            end)
            self._countHooked = true
        end
    end
end

-- Internal helper to apply the stored count
function FluxButton:_ApplyCount()
    if not self.WCount then return end
    if self._forcedCountLive and self._liveCountItemId then
        local n = ExtraDisplayItemCount(self._liveCountItemId)
        if n ~= nil then
            self._forcedCount = n
        end
    end
    local count = self._forcedCount
    
    if count == nil then
        self.WCount:Show()
        self.WCount:SetText("")
        if self.Widget and self.Widget.Count and self.Widget.Count ~= self.WCount then
            self.Widget.Count:Show()
            self.Widget.Count:SetText("")
        end
        return
    end
    
    local text = tostring(count)
    
    -- Format large numbers
    local num = tonumber(count)
    if num then
        if num >= 1000 then
            text = string.format("%.1fk", num / 1000)
        elseif num == 0 then
            text = "0" -- Explicitly show 0
        end
    end
    
    -- Show before SetText. A hidden TextOverlayContainer count drops the write.
    self.WCount:Show()
    self.WCount:SetText(text)
    self.WCount:SetAlpha(1)
    
    -- Ensure font is set (prevent invisible text)
    if self.WCount.GetFont and not self.WCount:GetFont() then
        local font = _G.NumberFontNormal or _G.GameFontHighlightOutline
        self.WCount:SetFontObject(font)
    end

    -- Action-bar badges: item/charge/reagent digits match minirow count size.
    local BadgeAPI = _G.FluxBadgeButton
    if (self.badgeMode or self._fluxIsActionBarBadge) and BadgeAPI and BadgeAPI.SyncCountFont then
        BadgeAPI.SyncCountFont(self)
    end
    
    -- Count stays under cooldown swipe / countdown digits.
    if FluxButtonUtil and FluxButtonUtil.EnsureCooldownAboveCount then
        FluxButtonUtil:EnsureCooldownAboveCount(self)
    elseif self.WCount.SetFrameLevel and self.Widget then
        self.WCount:SetFrameLevel(self.Widget:GetFrameLevel() + 3)
    end
    
    -- If using modern ActionButton logic, ensure text is not cleared by other updates
    if self.Widget and self.Widget.Count and self.Widget.Count ~= self.WCount then
        self.Widget.Count:Show()
        self.Widget.Count:SetText(text)
    end
end
