--[[
	ExtraButtonSystem/Engine/Core.lua
    Core button widget creation and management
    Based on FluxButtonCore.lua and ButtonForge patterns
    Uses FLUX_API for cross-version compatibility
]]

-- Create namespace
FluxButtonCore = FluxButtonCore or {}
local Core = FluxButtonCore

-- Constants
Core.BUTTON_SIZE = 32
Core.BUTTON_NAMING = "FluxButton"
Core.ButtonSeq = 1

-- Active button tracking
Core.ActiveButtons = {}
Core.ButtonWidgetMap = {}

-- Secure frame for handling click events
local SecureClickWrapperFrame = CreateFrame("Frame", nil, nil, "SecureHandlerBaseTemplate")

-- Version detection using FLUX_API
local function IsPostDF()
    return FLUX_API and FLUX_API.isPostDF
end

local function HasC_Spell()
    return FLUX_API and FLUX_API.hasC_Spell
end

--- Secure cast attribute for a spell placement.
--- Live post-DF retail: numeric spell ID.
--- Forever is a retail client that still has classic ranks, so it uses
--- "Name(Rank N)" like Era / Anniversary (ButtonForge-style).
function Core.FormatSpellCastAttribute(spellId)
    local spellIdNum = tonumber(spellId)
    if not spellIdNum or spellIdNum <= 0 then
        return spellId
    end

    local rankClient = FLUX_API and (FLUX_API.isCamelot or FLUX_API.isForever
        or FLUX_API.supportsPerRankSpellBarFeatures)
    local useSpellId = FLUX_API and FLUX_API.isRetail and FLUX_API.isPostDF and not rankClient
    if useSpellId then
        return spellIdNum
    end

    local name
    if HasC_Spell() and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellIdNum)
        name = info and info.name
    elseif GetSpellInfo then
        name = GetSpellInfo(spellIdNum)
    end
    if not name or name == "" then
        return spellIdNum
    end

    local subtext
    if HasC_Spell() and C_Spell.GetSpellSubtext then
        subtext = C_Spell.GetSpellSubtext(spellIdNum)
    elseif GetSpellSubtext then
        subtext = GetSpellSubtext(spellIdNum)
    end
    if type(subtext) == "string" and subtext ~= "" then
        return name .. "(" .. subtext .. ")"
    end
    return name
end

_G.FluxFormatSpellCastAttribute = Core.FormatSpellCastAttribute

-- NOTE: We do NOT hook ActionButton_UpdateCooldown globally.
-- Global hooks cause taint that propagates to Blizzard's action buttons, causing:
-- 1. ADDON_ACTION_BLOCKED errors when Blizzard tries to call SetAttribute()
-- 2. "Secret value" comparison errors in Blizzard's own code
-- Instead, we handle ActionButton_UpdateCooldown locally by:
-- 1. Overriding widget:UpdateCooldown() to do nothing for FluxButtons
-- 2. Overriding SpellCastAnimFrame:OnHide to not call ActionButton_UpdateCooldown

local function IsLegacyClient()
    return FLUX_API and FLUX_API.isLegacyClient
end

-- Initialize CVars for button behavior
local function UpdateCVarInfo()
	if InCombatLockdown() then
		return
	end
	
	if SecureClickWrapperFrame and SecureClickWrapperFrame.SetAttribute then
        local empowerTapControls = GetCVarBool and GetCVarBool("empowerTapControls") or false
        local actionButtonUseKeyDown = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown") or false
        
        SecureClickWrapperFrame:SetAttribute("CVar_empowerTapControls", empowerTapControls)
        SecureClickWrapperFrame:SetAttribute("CVar_ActionButtonUseKeyDown", actionButtonUseKeyDown)
        
		if SecureClickWrapperFrame.Execute then
			local FluxNS = _G.Flux
			local Restricted = FluxNS and FluxNS.Restricted
			if Restricted and Restricted.Execute then
				Restricted.Execute(SecureClickWrapperFrame, [[ 
				empowerTapControls = owner:GetAttribute("CVar_empowerTapControls");
                ActionButtonUseKeyDown = owner:GetAttribute("CVar_ActionButtonUseKeyDown");
			]])
			elseif not (FLUX_API and FLUX_API.hasRestrictedClosures == false) then
				SecureClickWrapperFrame:Execute([[ 
				empowerTapControls = owner:GetAttribute("CVar_empowerTapControls");
                ActionButtonUseKeyDown = owner:GetAttribute("CVar_ActionButtonUseKeyDown");
			]])
			end
		end
	end
end

-- Create a new button widget
function Core.CreateButtonWidget(parent, name, clickBehavior)
	if InCombatLockdown() then
		return nil
	end
	
    local buttonName = name or (Core.BUTTON_NAMING .. Core.ButtonSeq)
    Core.ButtonSeq = Core.ButtonSeq + 1
	
    -- Template selection based on client version
    -- NOTE: We do NOT include ActionButtonSpellFXTemplate because its mixin scripts
    -- call ActionButton_UpdateCooldown which crashes on custom buttons without action slots.
    -- Instead, we create the overlay frames manually in SetupOverlayFrames with safe scripts.
    local templateList = "ActionButtonTemplate, SecureActionButtonTemplate"
    local useSpellFX = IsPostDF() and HasC_Spell()
    
    local widget = CreateFrame("CheckButton", buttonName, parent, templateList)
	local FluxNS = _G.Flux
	if FluxNS and FluxNS.Action and FluxNS.Action.DetachFromCollectors then
		FluxNS.Action.DetachFromCollectors(widget)
	end
    
    -- CRITICAL: ALWAYS add stub implementations for methods that Blizzard's templates expect
    -- These are called from OnHide/OnFinished callbacks in ActionButtonCastingAnimFrameTemplate/ActionButtonSpellFXTemplate
    -- Must be added BEFORE SetupOverlayFrames and BEFORE any templates set their scripts
    
    -- Store original OnHide if it exists (from ActionButtonTemplate)
    local originalWidgetOnHide = widget:GetScript("OnHide")
    
    widget.ClearReticle = function(self)
        if self.TargetReticleAnimFrame then
            pcall(function() self.TargetReticleAnimFrame:Hide() end)
        end
    end
    
    widget.StopSpellCastAnim = function(self, interrupted, castType)
        local cf = self.SpellCastAnimFrame
        if not cf then
            self.actionButtonCastType = nil
            self.vfxCastData = nil
            return
        end
        -- interrupted / force-stop: hide immediately.
        if interrupted then
            pcall(function() cf:Hide() end)
            self.actionButtonCastType = nil
            self.vfxCastData = nil
            return
        end
        -- Already in finish burst, or OnFinished already hid the frame — do not restart.
        if cf.EndBurst and cf.EndBurst:IsShown() then
            self.actionButtonCastType = nil
            self.vfxCastData = nil
            return
        end
        if not cf:IsShown() and not self.vfxCastData and not self.actionButtonCastType then
            return
        end
        local fill = cf.Fill
        if fill and fill.CastingAnim and fill.CastingAnim.Stop then
            pcall(fill.CastingAnim.Stop, fill.CastingAnim)
        end
        if fill and fill.Hide then
            pcall(fill.Hide, fill)
        end
        cf:Show()
        if cf.EndBurst then
            cf.EndBurst:Show()
            local anim = cf.EndBurst.FinishCastAnim
            if anim and anim.Play and not (anim.IsPlaying and anim:IsPlaying()) then
                pcall(anim.Play, anim)
            end
        elseif cf.FinishAnimAndPlayBurst then
            pcall(cf.FinishAnimAndPlayBurst, cf)
        else
            pcall(function() cf:Hide() end)
        end
        self.actionButtonCastType = nil
        self.vfxCastData = nil
    end
    
    widget.ClearInterruptDisplay = function(self)
        if self.InterruptDisplay then
            pcall(function() self.InterruptDisplay:Hide() end)
        end
    end
    
    widget.StopTargettingReticleAnim = function(self)
        if self.TargetReticleAnimFrame then
            pcall(function() self.TargetReticleAnimFrame:Hide() end)
        end
    end
    
    -- CRITICAL: Override widget's OnHide to prevent ActionButton_UpdateCooldown from being called
    -- Blizzard's ActionButtonTemplate OnHide calls ActionButton_UpdateCooldown which crashes on custom buttons
    widget:SetScript("OnHide", function(self)
        -- Only call original OnHide if it exists and doesn't call ActionButton_UpdateCooldown
        -- For our custom buttons, we don't need any OnHide behavior from Blizzard's templates
        -- The global hook will prevent ActionButton_UpdateCooldown from being called anyway
    end)
    
    -- Mix in ActionBarActionButtonMixin for spell FX methods (Dragonflight+)
    -- IMPORTANT: Do NOT copy methods that call ActionButton_UpdateCooldown:
    -- - ClearReticle, StopSpellCastAnim, ClearInterruptDisplay, StopTargettingReticleAnim
    -- Those are handled by our safe stub implementations above
    if useSpellFX and ActionBarActionButtonMixin then
        local safeMethodsToCopy = {
            "SpellFXEnabled",
            "PlaySpellCastAnim",
            "PlayTargettingReticleAnim",
            "PlaySpellInterruptedAnim",
            -- NOT copying: ClearReticle, StopSpellCastAnim, ClearInterruptDisplay, StopTargettingReticleAnim
            -- Those methods call ActionButton_UpdateCooldown which crashes on custom buttons
		}
        for _, methodName in ipairs(safeMethodsToCopy) do
            if ActionBarActionButtonMixin[methodName] then
				widget[methodName] = ActionBarActionButtonMixin[methodName]
			end
		end
	end
	
    -- Set up widget properties
	if widget.TextOverlayContainer and widget.GetFrameLevel then
		-- Below cooldown swipe/countdown (EnsureCooldownAboveCount raises CD further).
		widget.TextOverlayContainer:SetFrameLevel(widget:GetFrameLevel() + 3)
	end
    
	widget:SetAttribute("checkselfcast", true)
	widget:SetAttribute("checkfocuscast", true)
	widget:SetAttribute("checkmouseovercast", false)
	widget:SetAttribute("useparent-actionpage", true)
	local Click = Flux.ButtonFX and Flux.ButtonFX.Click
	if not Click or not Click.UsesWrap or Click.UsesWrap() then
		widget:SetAttribute("pressAndHoldAction", true)
	end
	
    -- Set click behavior based on parameter
    clickBehavior = clickBehavior or "AnyUp"
	widget:RegisterForClicks(clickBehavior)
	widget:RegisterForDrag("LeftButton", "RightButton")
	
    -- Set up button size
    widget:SetSize(Core.BUTTON_SIZE, Core.BUTTON_SIZE)
	
    -- Store widget reference
    Core.ButtonWidgetMap[widget] = true
	
    -- Set up overlay frames for modern clients
    if useSpellFX then
        Core.SetupOverlayFrames(widget)
        
        if ActionBarActionEventsFrame and ActionBarActionEventsFrame.RegisterFrame then
            local ActionButtonCastType = { Cast = 1, Channel = 2, Empowered = 3 }
            
            -- Override PlayTargettingReticleAnim to avoid errors
            function widget:PlayTargettingReticleAnim()
                if self.TargetReticleAnimFrame then
                    self.TargetReticleAnimFrame:Setup()
                    self.TargetReticleAnimFrame:Show()
                end
            end
            
            -- Override UpdateCooldown for custom buttons
            -- CRITICAL: Prevent ActionButton_UpdateCooldown from being called on custom buttons
            -- Custom buttons don't have action slots, so ActionButton_UpdateCooldown will crash
            function widget:UpdateCooldown()
                -- Do nothing - FluxButton handles its own cooldown updates
                -- Do NOT call ActionBarActionButtonMixin.UpdateCooldown or ActionButton_UpdateCooldown
                -- as they expect action slots which custom buttons don't have
            end
            
            -- Helper to check if two spell IDs match, considering overrides (Smite <-> Void Blast)
            local function SpellIDsMatch(spellA, spellB)
                if not spellA or not spellB then return false end
                if spellA == spellB then return true end
                
                -- Check spell overrides using FindBaseSpellByID
                if FindBaseSpellByID then
                    local baseA = FindBaseSpellByID(spellA)
                    local baseB = FindBaseSpellByID(spellB)
                    if baseA and baseA == spellB then return true end
                    if baseB and baseB == spellA then return true end
                    if baseA and baseB and baseA == baseB then return true end
                end
                
                return false
            end

            -- Implement MatchesActiveButtonSpellID (with spell override support and Single Button Assistant)
            function widget:MatchesActiveButtonSpellID(spellID)
                if not spellID then return false end
                
                local fluxBtn = self.FluxButton or self.ParentButton
                
                if fluxBtn then
                    -- Check Single Button Assistant current spell (highest priority - dynamic spell changes)
                    if fluxBtn.IsSingleButtonAssistant and fluxBtn.SingleButtonAssistantSpellId then
                        if SpellIDsMatch(fluxBtn.SingleButtonAssistantSpellId, spellID) then return true end
                    end
                    
                    if fluxBtn.SpellId and SpellIDsMatch(fluxBtn.SpellId, spellID) then return true end
                    if fluxBtn.MacroMode == "spell" and fluxBtn.SpellId and SpellIDsMatch(fluxBtn.SpellId, spellID) then return true end
                    
                    if fluxBtn.ItemId and C_Item and C_Item.GetItemSpell then
                        local _, itemSpellID = C_Item.GetItemSpell(fluxBtn.ItemId)
                        if itemSpellID and SpellIDsMatch(itemSpellID, spellID) then return true end
                    end
                end
                
                local attrSpell = self:GetAttribute("spell")
                if attrSpell then
                    if type(attrSpell) == "number" and SpellIDsMatch(attrSpell, spellID) then return true end
                    if type(attrSpell) == "string" and C_Spell and C_Spell.GetSpellInfo then
                        local spellInfo = C_Spell.GetSpellInfo(attrSpell)
                        if spellInfo and SpellIDsMatch(spellInfo.spellID, spellID) then return true end
                    end
                end
                
                local action = self.action or self:GetAttribute("action")
                if action and action > 0 and GetActionInfo then
                    local actionType, actionID, actionSubType = GetActionInfo(action)
                    if actionType == "spell" and SpellIDsMatch(actionID, spellID) then return true end
                end
                
                return false
            end
            
            -- Implement OnEvent for dispatched events
            function widget:OnEvent(event, ...)
                local ActionButtonCastType = { Cast = 1, Channel = 2, Empowered = 3 }
                
                if event == "UNIT_SPELLCAST_INTERRUPTED" then
                    local intd = self.InterruptDisplay
                    if intd and intd.IsShown and intd:IsShown() then
                        return
                    end
                    if self.PlaySpellInterruptedAnim then self:PlaySpellInterruptedAnim() end
                elseif event == "UNIT_SPELLCAST_START" then
                    if self.PlaySpellCastAnim then self:PlaySpellCastAnim(ActionButtonCastType.Cast) end
                elseif event == "UNIT_SPELLCAST_STOP" then
                    if self.StopSpellCastAnim then self:StopSpellCastAnim(true, ActionButtonCastType.Cast) end
                    if self.StopTargettingReticleAnim then self:StopTargettingReticleAnim() end
                elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
                    if self.StopSpellCastAnim then self:StopSpellCastAnim(false, ActionButtonCastType.Cast) end
                    if self.StopTargettingReticleAnim then self:StopTargettingReticleAnim() end
                elseif event == "UNIT_SPELLCAST_SENT" or event == "UNIT_SPELLCAST_FAILED" then
                    if self.StopTargettingReticleAnim then self:StopTargettingReticleAnim() end
                elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
                    if self.PlaySpellCastAnim then self:PlaySpellCastAnim(ActionButtonCastType.Channel) end
                elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
                    if self.StopSpellCastAnim then self:StopSpellCastAnim(false, ActionButtonCastType.Channel) end
                elseif event == "UNIT_SPELLCAST_RETICLE_TARGET" then
                    local spellID = select(3, ...)
                    if spellID and self:MatchesActiveButtonSpellID(spellID) then
                        if self.PlayTargettingReticleAnim then
                            local saved = self.enableSpellFX
                            self.enableSpellFX = true
                            self:PlayTargettingReticleAnim()
                            self.enableSpellFX = saved
                        end
                    end
                elseif event == "UNIT_SPELLCAST_RETICLE_CLEAR" then
                    if self.StopTargettingReticleAnim then self:StopTargettingReticleAnim() end
                end
            end
            
            if not widget:GetScript("OnEvent") then
                widget:SetScript("OnEvent", widget.OnEvent)
            end
            
            -- ============================================================================
            -- DISABLED: ActionBarActionEventsFrame Registration
            -- ============================================================================
            -- This was causing TAINT propagation - see FluxButtonCore.lua for full explanation.
            -- FluxButton VFX is handled via standalone VFX.InitCastingSystem() and VFX.InitProcGlowSystem().
            -- ============================================================================
            -- ActionBarActionEventsFrame:RegisterFrame(widget)
        end
	end
	
	return widget
end

-- Set up overlay frames on a button widget
function Core.SetupOverlayFrames(widget)
	if not widget then return end
	
    -- Helper to safely override scripts on SpellCastAnimFrame
    local function OverrideSpellCastAnimScripts(frame, parentWidget)
        if not frame then return end
        
        -- CRITICAL FIX: Override OnHide to prevent crashes
        -- The default ActionButtonCastingAnimFrameMixin:OnHide calls ClearReticle and ActionButton_UpdateCooldown
        -- which crashes for FluxButtons because they don't have action slots
        -- 
        -- Blizzard's template uses a MIXIN, so we need to:
        -- 1. Clear any existing script
        -- 2. Override the frame's OnHide method (mixin method)
        -- 3. Set our own script handler
        
        -- Create our safe OnHide handler
        local safeOnHideHandler = function(self)
            local parent = self:GetParent()
            -- Safely call ClearReticle if it exists
            if parent and parent.ClearReticle then
                pcall(parent.ClearReticle, parent)
            end
            -- Safely reset cooldown swipe color
            if parent and parent.cooldown and parent.cooldown.SetSwipeColor then
                pcall(parent.cooldown.SetSwipeColor, parent.cooldown, 0, 0, 0, 1)
            end
            -- SKIPPED: ActionButton_UpdateCooldown(parent) - crashes on custom buttons
        end
        
        -- Step 1: Clear any existing OnHide script
        pcall(function() frame:SetScript("OnHide", nil) end)
        
        -- Step 2: Override the mixin method directly on the frame instance
        -- This prevents the mixin's OnHide from being called via frame:OnHide()
        rawset(frame, "OnHide", safeOnHideHandler)
        
        -- Step 3: Set our script handler
        pcall(function() frame:SetScript("OnHide", safeOnHideHandler) end)
        
        -- CRITICAL FIX: Override animation OnFinished callbacks
        -- Blizzard's animations call parentButton:StopSpellCastAnim() which triggers Hide() and OnHide
        -- We need to override ALL animation callbacks that might trigger this
        
        -- Helper to safely override an animation group's OnFinished
        local function SafeOverrideAnimGroupFinished(animGroup, handler)
            if not animGroup then return end
            animGroup.OnFinished = handler
            pcall(function() animGroup:SetScript("OnFinished", handler) end)
        end
        
        -- Override EndBurst.FinishCastAnim - CRITICAL FIX
        -- This is the animation that triggers the crash chain:
        -- FinishCastAnim:OnFinished() → SpellCastAnimFrame:Hide() → mixin OnHide → ActionButton_UpdateCooldown
        pcall(function()
            if frame.EndBurst and frame.EndBurst.FinishCastAnim then
                SafeOverrideAnimGroupFinished(frame.EndBurst.FinishCastAnim, function(self)
                    pcall(function()
                        local spellCastFrame = self:GetParent():GetParent()
                        local parentButton = spellCastFrame and spellCastFrame:GetParent()
                        
                        if spellCastFrame then
                            -- CRITICAL: Temporarily nil out BOTH the script handler AND the mixin method
                            -- WoW calls both when Hide() is called:
                            -- 1. Script handler (SetScript("OnHide", fn))
                            -- 2. Mixin method (frame:OnHide())
                            
                            -- Save both
                            local savedScriptHandler = spellCastFrame:GetScript("OnHide")
                            local savedMixinOnHide = rawget(spellCastFrame, "OnHide")
                            
                            -- Nil out both to prevent ActionButton_UpdateCooldown from being called
                            spellCastFrame:SetScript("OnHide", nil)
                            rawset(spellCastFrame, "OnHide", nil)
                            
                            -- Now safe to hide
                            spellCastFrame:Hide()
                            
                            -- Restore both
                            if savedScriptHandler then
                                spellCastFrame:SetScript("OnHide", savedScriptHandler)
                            end
                            if savedMixinOnHide then
                                rawset(spellCastFrame, "OnHide", savedMixinOnHide)
                            end
                        end
                        
                        -- Call StopSpellCastAnim safely (matches Blizzard's behavior at line 1842)
                        if parentButton and parentButton.StopSpellCastAnim then
                            pcall(parentButton.StopSpellCastAnim, parentButton, false, parentButton.actionButtonCastType)
                        end
                    end)
                end)
            end
        end)
        
        -- Override Fill.CastingAnim
        pcall(function()
            if frame.Fill and frame.Fill.CastingAnim then
                SafeOverrideAnimGroupFinished(frame.Fill.CastingAnim, function(self)
                    -- Just hide the Fill, no need to call parent methods
                    pcall(function()
                        local fillFrame = self:GetParent()
                        if fillFrame and fillFrame.Hide then
                            fillFrame:Hide()
                        end
                    end)
                end)
            end
        end)
        
        -- Override any other animation groups that might exist
        pcall(function()
            -- CastingAnim on the main frame
            if frame.CastingAnim then
                SafeOverrideAnimGroupFinished(frame.CastingAnim, function(self) end)
            end
            
            -- StartCastAnim if it exists
            if frame.StartCastAnim then
                SafeOverrideAnimGroupFinished(frame.StartCastAnim, function(self) end)
            end
        end)
    end
    
    -- InterruptDisplay
	if not widget.InterruptDisplay then
		local ok, frame = pcall(CreateFrame, "Frame", nil, widget, "ActionButtonInterruptTemplate")
		if ok and frame then
			widget.InterruptDisplay = frame
			frame:SetAllPoints(widget)
			frame:SetFrameLevel(widget:GetFrameLevel() + 10)
			frame:Hide()
		end
	end
	
    -- SpellCastAnimFrame - created manually (NOT from ActionButtonSpellFXTemplate to avoid crashes)
	if not widget.SpellCastAnimFrame then
		local ok, frame = pcall(CreateFrame, "Frame", nil, widget, "ActionButtonCastingAnimFrameTemplate")
		if ok and frame then
			widget.SpellCastAnimFrame = frame
            
            -- CRITICAL: Override scripts IMMEDIATELY after creation, before any Hide() can be triggered
            OverrideSpellCastAnimScripts(frame, widget)
            
            -- CRITICAL: Also override the EndBurst's OnHide which calls parent methods
            -- The EndBurst frame has its own OnHide that calls parentButton:StopSpellCastAnim()
            if frame.EndBurst then
                frame.EndBurst:SetScript("OnHide", function(self)
                    local parent = self:GetParent()
                    if parent then
                        -- Just reset state, don't call any parent button methods
                        pcall(function()
                            if parent.Fill then parent.Fill:Hide() end
                        end)
                    end
                end)
                -- Also nil out the mixin method
                rawset(frame.EndBurst, "OnHide", function() end)
            end
            
            -- Now safe to set properties and hide
			frame:SetPoint("CENTER", widget, "CENTER", 0, 0)
			frame:SetFrameLevel(widget:GetFrameLevel() + 10)
			frame:Hide()
		end
    else
        -- Frame already exists (shouldn't happen now that we removed ActionButtonSpellFXTemplate)
        -- but override scripts just in case
        OverrideSpellCastAnimScripts(widget.SpellCastAnimFrame, widget)
        if widget.SpellCastAnimFrame.EndBurst then
            widget.SpellCastAnimFrame.EndBurst:SetScript("OnHide", function() end)
            rawset(widget.SpellCastAnimFrame.EndBurst, "OnHide", function() end)
        end
    end
    
    -- TargetReticleAnimFrame
	if not widget.TargetReticleAnimFrame then
		local ok, frame = pcall(CreateFrame, "Frame", nil, widget, "ActionButtonTargetReticleFrameTemplate")
		if ok and frame then
			widget.TargetReticleAnimFrame = frame
			frame:SetPoint("CENTER", widget, "CENTER", 0, 0)
			frame:SetFrameLevel(widget:GetFrameLevel() + 10)
			frame:Hide()
		end
	end
	
    -- SpellActivationAlert
	if not widget.SpellActivationAlert then
		local ok, frame = pcall(CreateFrame, "Frame", nil, widget, "ActionButtonSpellAlertTemplate")
		if ok and frame then
			widget.SpellActivationAlert = frame
			local w, h = widget:GetSize()
			frame:SetSize(w * 1.4, h * 1.4)
			frame:SetPoint("CENTER", widget, "CENTER", 0, 0)
			frame:SetFrameLevel(widget:GetFrameLevel() + 5)
			frame:Hide()
		end
	end
	
    -- CooldownFlash
	if not widget.CooldownFlash then
		local ok, frame = pcall(CreateFrame, "Frame", nil, widget, "ActionButtonCooldownFlashTemplate")
		if ok and frame then
			widget.CooldownFlash = frame
			frame:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 1)
			frame:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", 0, 1)
			frame:Hide()
		end
	end
end

-- Create a new button with full functionality
function Core.CreateButton(parent, buttonConfig)
    if InCombatLockdown() then
        return nil
    end
    
    local button = {}
    button.Widget = Core.CreateButtonWidget(parent, buttonConfig and buttonConfig.name, buttonConfig and buttonConfig.clickBehavior)
    
    if not button.Widget then
	return nil
end
	
	local name = button.Widget:GetName()
	button.WIcon = _G[name .. "Icon"]
	button.WNormalTexture = _G[name .. "NormalTexture"] 
	button.WCooldown = _G[name .. "Cooldown"]
	button.WCount = _G[name .. "Count"] or button.Widget.Count
	button.WBorder = _G[name .. "Border"]
	button.WFlashTexture = _G[name .. "Flash"]
	button.WHotKey = _G[name .. "HotKey"]
	button.WName = _G[name .. "Name"]
    button.WFloatingBG = _G[name .. "FloatingBG"]

    -- Snapshot template equip-border size vs create-time slot (32) before any rescale.
    if button.WBorder and FluxButtonUtil and FluxButtonUtil.CaptureEquipBorderNative then
        FluxButtonUtil:CaptureEquipBorderNative(button)
    end
    -- Set up cooldown appearance
    if button.WCooldown then
        if button.WCooldown.SetEdgeTexture then
		button.WCooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
	end
        if button.WCooldown.SetSwipeColor then
		button.WCooldown:SetSwipeColor(0, 0, 0)
	end
        if button.WCooldown.SetHideCountdownNumbers then
		button.WCooldown:SetHideCountdownNumbers(false)
	end
        if COOLDOWN_TYPE_NORMAL then
		button.WCooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL
        end
        if FluxButtonUtil and FluxButtonUtil.EnsureCooldownAboveCount then
            FluxButtonUtil:EnsureCooldownAboveCount(button)
        end
	end

    -- Enable spell FX
	button.Widget.enableSpellFX = true
    button.Widget.config = button.Widget.config or {}
    if button.Widget.config.spellCastVFX == nil then
        button.Widget.config.spellCastVFX = true
    end
    if _G.FluxPostDFVFX_RegisterSurface then
        pcall(_G.FluxPostDFVFX_RegisterSurface, button.Widget)
    end

    -- Register reticle events for DF+
    if IsPostDF() and HasC_Spell() then
		pcall(function() button.Widget:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_TARGET", "player") end)
		pcall(function() button.Widget:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_CLEAR", "player") end)
	end
	
    -- Link button to widget
	button.Widget.ParentButton = button
	button.Widget.FluxButton = button
	
    -- Apply initial ring border (skip for badge overlays)
	if FluxButtonUtil and button.WNormalTexture and not (buttonConfig and buttonConfig.badgeMode) then
		FluxButtonUtil:ShowRingBorder(button)
	end
	
    -- Configure button if config provided
	if buttonConfig then
        Core.ConfigureButton(button, buttonConfig)
	end
	
    -- Flux perf: keep Core.ActiveButtons aligned with Events — empty shells must not
    -- inflate glow/cast/flyout sweeps (was Core=21 vs Events=10).
    local shouldRegister = button.ActionType and button.ActionValue
    if shouldRegister then
        Core.AddActiveButton(button)
        if FluxButtonEvents and FluxButtonEvents.RegisterButton then
            FluxButtonEvents.RegisterButton(button)
        end
    end
	
	return button
end

-- Configure a button with specific settings
function Core.ConfigureButton(button, config)
    if not button or not button.Widget then
        return
    end
    
	local widget = button.Widget
	
	if config.point and config.relativeTo then
		widget:ClearAllPoints()
		widget:SetPoint(config.point, config.relativeTo, config.relativePoint or config.point, config.xOffset or 0, config.yOffset or 0)
	end
    
	if config.size then
		widget:SetSize(config.size, config.size)
	end
    
	if config.actionType and config.actionValue then
        Core.SetButtonAction(button, config.actionType, config.actionValue)
	end
    
	if config.visible ~= nil then
        if config.visible then
            widget:Show()
        else
            widget:Hide()
	end
	end
end

local RIGHT_CLICK_SECURE_ATTRS = {
    "type2", "spell2", "macrotext2", "macro2",
    "shift-type2", "shift-spell2", "shift-macrotext2", "shift-macro2",
    "ctrl-type2", "ctrl-spell2", "ctrl-macrotext2", "ctrl-macro2",
    "alt-type2", "alt-spell2", "alt-macrotext2", "alt-macro2",
    "type3", "macrotext3", "macro3",
}

local function SaveRightClickSecureAttrs(widget)
    local saved = {}
    for i = 1, #RIGHT_CLICK_SECURE_ATTRS do
        local key = RIGHT_CLICK_SECURE_ATTRS[i]
        local val = widget:GetAttribute(key)
        if val ~= nil then
            saved[key] = val
        end
    end
    return saved
end

local function RestoreRightClickSecureAttrs(widget, saved)
    if not saved then
        return
    end
    for key, val in pairs(saved) do
        widget:SetAttribute(key, val)
    end
end

-- Set a button's action
function Core.SetButtonAction(button, actionType, actionValue)
    if not button or not button.Widget then
        return
    end
    
    if InCombatLockdown() then
        return
    end
    
	local widget = button.Widget
    -- Preserve right/middle-click flyout proxies on preset grid buttons (Teleport, Mount, etc.)
    local preserveRightClick = (actionType == "item" or actionType == "spell")
        or widget.FluxGridFlyoutOwner
        or button.FluxGridFlyoutOwner
    local savedRightClick = preserveRightClick and SaveRightClickSecureAttrs(widget) or nil
	
    -- Clear previous attributes
	widget:SetAttribute("type", nil)
	widget:SetAttribute("typerelease", nil)
	widget:SetAttribute("spell", nil)
	if not preserveRightClick then
		widget:SetAttribute("spell2", nil)
	end
	widget:SetAttribute("item", nil)
	widget:SetAttribute("macro", nil)
	widget:SetAttribute("macrotext", nil)
	widget:SetAttribute("action", nil)
	widget:SetAttribute("flyout", nil)
    if not preserveRightClick then
        widget:SetAttribute("type2", nil)
        widget:SetAttribute("macrotext2", nil)
        widget:SetAttribute("macro2", nil)
        widget:SetAttribute("type3", nil)
        widget:SetAttribute("macrotext3", nil)
        widget:SetAttribute("macro3", nil)
    else
        -- Keep existing type2/macrotext2/spell2; restore after item/spell rebind.
        -- Do not nil macrotext2 here — a partial restore can leave conjure unbound
        -- on cold login (food button especially).
    end
    
	if actionType == "spell" then
        --- Retail 10+: numeric spell ID. Classic ranks: "Name(Rank N)" so lower ranks cast correctly.
        local spellAttr = Core.FormatSpellCastAttribute(actionValue)
		
        widget:SetAttribute("type", "spell")
        widget:SetAttribute("typerelease", "spell")
        widget:SetAttribute("spell", spellAttr)
        
        if HasC_Spell() and C_Spell.IsPressHoldReleaseSpell then
            widget:SetAttribute("IsEmpowerSpell", C_Spell.IsPressHoldReleaseSpell(actionValue))
        end
        
	elseif actionType == "item" then
        local itemName = GetItemInfo and GetItemInfo(actionValue)
        local itemAttr = itemName or ("item:" .. tostring(actionValue))
        widget:SetAttribute("type", "item")
        widget:SetAttribute("typerelease", "item")
        widget:SetAttribute("item", itemAttr)
        
	elseif actionType == "macro" then
		widget:SetAttribute("type", "macro")
        widget:SetAttribute("typerelease", "macro")
		widget:SetAttribute("macro", actionValue)
        
	elseif actionType == "macrotext" then
		widget:SetAttribute("type", "macro")
        widget:SetAttribute("typerelease", "macro")
		widget:SetAttribute("macrotext", actionValue)
        
	elseif actionType == "action" then
		widget:SetAttribute("type", "action")
        widget:SetAttribute("typerelease", "action")
		widget:SetAttribute("action", actionValue)
        
	elseif actionType == "mount" then
        local mountName, mountSpellID
        if C_MountJournal and C_MountJournal.GetMountInfoByID then
            mountName, mountSpellID = C_MountJournal.GetMountInfoByID(actionValue)
        end
        
             if mountName then
                 widget:SetAttribute("type", "macro")
            widget:SetAttribute("typerelease", "macro")
                 widget:SetAttribute("macrotext", "/cast " .. mountName)
             end
        
	elseif actionType == "flyout" then
		widget:SetAttribute("type", "flyout")
        widget:SetAttribute("typerelease", "flyout")
        local flyoutId = actionValue
        if type(flyoutId) == "string" then
            local parsed = tonumber(flyoutId:match("FLYOUT(%d+)") or flyoutId)
            flyoutId = parsed or flyoutId
        end
        widget:SetAttribute("spell", flyoutId)
		if widget:GetAttribute("flyoutDirection") == nil then
			widget:SetAttribute("flyoutDirection", "DOWN")
		end
        
	elseif actionType == "battlepet" then
		widget:SetAttribute("type", "macro")
        widget:SetAttribute("typerelease", "macro")
		widget:SetAttribute("macrotext", "/summonpet " .. actionValue)
        
    elseif actionType == "equipmentset" then
        -- Get equipment set name from index (actionValue is the set index)
        local setName = actionValue
        if C_EquipmentSet and C_EquipmentSet.GetEquipmentSetInfo then
            local name = C_EquipmentSet.GetEquipmentSetInfo(actionValue)
            if name then
                setName = name
            end
        end
        widget:SetAttribute("type", "macro")
        widget:SetAttribute("typerelease", "macro")
        widget:SetAttribute("macrotext", "/equipset " .. setName)
	end

    if savedRightClick then
        RestoreRightClickSecureAttrs(widget, savedRightClick)
    end
	
    Core.UpdateButtonState(button)
end

-- Update button visual state
function Core.UpdateButtonState(button)
    if not button or not button.Widget then
        return
    end
	button.Widget:Show()
end

-- Clean up a button
function Core.DestroyButton(button)
    if not button or not button.Widget then
        return
    end
	
	if FluxButtonEvents and FluxButtonEvents.UnregisterButton then
		FluxButtonEvents.UnregisterButton(button)
	end
	
    Core.RemoveActiveButton(button)
	
    Core.ButtonWidgetMap[button.Widget] = nil
    
	button.Widget:Hide()
	button.Widget:ClearAllPoints()
	button.Widget = nil
end

-- Get button by widget
function Core.GetButtonByWidget(widget)
	return widget and widget.ParentButton
end

-- Get all active buttons
function Core.GetActiveButtons()
    return Core.ActiveButtons
end

function Core.AddActiveButton(button)
    if not button then return end
    for i = 1, #Core.ActiveButtons do
        if Core.ActiveButtons[i] == button then
            return
        end
    end
    table.insert(Core.ActiveButtons, button)
end

function Core.RemoveActiveButton(button)
    if not button then return end
    for i = #Core.ActiveButtons, 1, -1 do
        if Core.ActiveButtons[i] == button then
            table.remove(Core.ActiveButtons, i)
            break
        end
    end
end

-- Initialize the button system
function Core.Initialize()
    UpdateCVarInfo()
    
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("CVAR_UPDATE")
    eventFrame:SetScript("OnEvent", function(self, event, cvarName)
        if cvarName == "empowerTapControls" or cvarName == "ActionButtonUseKeyDown" then
            UpdateCVarInfo()
        end
    end)
end

-- Initialize when loaded
Core.Initialize()

-- Export
_G.FluxButtonCore = Core
