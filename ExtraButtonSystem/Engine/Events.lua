--[[
    ExtraButtonSystem/Engine/Events.lua
    Event management system for FluxButton instances
    Based on FluxButtonEvents.lua and ButtonForge patterns
    Uses FluxSafeRegisterEvent from FluxAPICompat for safe event registration
]]

-- Create the events namespace
if not FluxButtonEvents then
    FluxButtonEvents = {}
end

local FluxButtonEvents = FluxButtonEvents

-- Legacy detection function using FLUX_API
local function IsLegacy()
    if FLUX_API and FLUX_API.isLegacyClient ~= nil then
        return FLUX_API.isLegacyClient
    end
    -- Fallback detection
    local maj, min, rev, bn = GetBuildInfo()
    local majNum = tonumber(maj) or 0
    local bnNum = tonumber(bn) or 0
    return (majNum > 0 and majNum <= 3) or (bnNum > 0 and bnNum < 15000)
end

-- Track active buttons
FluxButtonEvents.ActiveButtons = {}
FluxButtonEvents.rangeButtons = {}
FluxButtonEvents.mouseoverMacroButtons = {}
-- Shared form-storm state (legacy + modern Conditional paths).
FluxButtonEvents._lastShapeshiftForm = nil
FluxButtonEvents._formStormIgnoreAscUntil = 0
FluxButtonEvents._lastTranslateMacroCacheInvalidate = 0
FluxButtonEvents._deferredUsableAfterStorm = false
FluxButtonEvents._deferredUsablePowerSettle = false
FluxButtonEvents._lastDisplayPowerType = nil
FluxButtonEvents._formStormFlushToken = 0

--- True while ExtraButtonSystem is coalescing a shapeshift / bonus-bar / display-power settle.
function FluxButtonEvents.IsFormStormActive()
    return (GetTime() or 0) < (FluxButtonEvents._formStormIgnoreAscUntil or 0)
end

local function FlushDeferredUsableAfterStorm()
    if not FluxButtonEvents._deferredUsableAfterStorm then
        return
    end
    if FluxButtonEvents.IsFormStormActive() then
        return
    end
    FluxButtonEvents._deferredUsableAfterStorm = false
    FluxButtonEvents._deferredUsablePowerSettle = true
    local Full = FluxButtonEvents.EventFrames and FluxButtonEvents.EventFrames.Full
    if not Full then
        return
    end
    Full.RefUsable = true
    Full.RefSkipTexture = true
    Full.RefreshButtons = true
    if not Full:GetScript("OnUpdate") then
        Full:SetScript("OnUpdate", Full.OnUpdate)
    end
end

FluxButtonEvents._formStormSettledHandlers = FluxButtonEvents._formStormSettledHandlers or {}

--- Register a one-shot-per-settle callback (LAB usable, Binding ASC fan-out, etc.).
function FluxButtonEvents.RegisterFormStormSettled(key, fn)
    if type(key) ~= "string" or type(fn) ~= "function" then
        return
    end
    FluxButtonEvents._formStormSettledHandlers[key] = fn
end

local function RunFormStormSettled()
    if FluxButtonEvents.IsFormStormActive() then
        return
    end
    FlushDeferredUsableAfterStorm()
    local handlers = FluxButtonEvents._formStormSettledHandlers
    if handlers then
        for _, fn in pairs(handlers) do
            pcall(fn)
        end
    end
end

--- Open/extend the form/power-storm suppress window.
--- Covers Druid mana↔energy/rage (UNIT_DISPLAYPOWER) and bonus-bar form swaps.
--- SPELL_UPDATE_USABLE during the window only sets a deferred flag; one RefUsable
--- (skipping item consumables) runs when the window ends.
function FluxButtonEvents.BeginFormStorm(duration)
    local dur = tonumber(duration) or 0.55
    local now = GetTime() or 0
    local untilT = now + dur
    if untilT > (FluxButtonEvents._formStormIgnoreAscUntil or 0) then
        FluxButtonEvents._formStormIgnoreAscUntil = untilT
    end
    FluxButtonEvents._formStormFlushToken = (FluxButtonEvents._formStormFlushToken or 0) + 1
    local tok = FluxButtonEvents._formStormFlushToken
    local delay = (FluxButtonEvents._formStormIgnoreAscUntil - now) + 0.02
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, function()
            if tok ~= FluxButtonEvents._formStormFlushToken then
                return
            end
            RunFormStormSettled()
        end)
    end
end

--- Mark that SPELL/ACTIONBAR_UPDATE_USABLE fired during a storm (settle once after).
function FluxButtonEvents.RequestDeferredUsableAfterStorm()
    FluxButtonEvents._deferredUsableAfterStorm = true
end

local function MacroBodyUsesMouseover(body)
    if not body or body == "" then
        return false
    end
    return body:lower():find("@mouseover", 1, true) ~= nil
end

function FluxButtonEvents.GetMacroBodyForButton(button)
    if not button then
        return nil
    end
    if button.MacroBody and button.MacroBody ~= "" then
        return button.MacroBody
    end
    if button.MacroIndex and GetMacroInfo then
        local _, _, body = GetMacroInfo(button.MacroIndex)
        return body
    end
    return nil
end

function FluxButtonEvents.RefreshMouseoverMacroMembership(button)
    if not FluxButtonEvents.mouseoverMacroButtons then
        FluxButtonEvents.mouseoverMacroButtons = {}
    end
    if not button then
        return
    end
    local was = FluxButtonEvents.mouseoverMacroButtons[button] ~= nil
    local is = false
    if button.ActionType == "macro" then
        local body = FluxButtonEvents.GetMacroBodyForButton(button)
        if MacroBodyUsesMouseover(body)
            or MacroBodyUsesMouseover(button._fluxHoverMacroBody)
            or MacroBodyUsesMouseover(button._fluxKbMacroBody) then
            is = true
            FluxButtonEvents.mouseoverMacroButtons[button] = true
        else
            FluxButtonEvents.mouseoverMacroButtons[button] = nil
        end
    else
        FluxButtonEvents.mouseoverMacroButtons[button] = nil
    end
    if was ~= is and FluxMouseoverRefresh and FluxMouseoverRefresh.RefreshGlobalPresence then
        FluxMouseoverRefresh.RefreshGlobalPresence()
    end
end

function FluxButtonEvents.FlushMouseoverUsable()
    local mouseoverSet = FluxButtonEvents.mouseoverMacroButtons

    if not mouseoverSet or not next(mouseoverSet) then
        return false
    end

    for button in next, mouseoverSet do
        if button then
            if button.TranslateMacro then
                button:TranslateMacro()
            end
            if button.UpdateUsable then
                button:UpdateUsable()
            end
        end
    end

    return true
end

-- Safe event registration wrapper
local function SafeRegisterEvent(frame, eventName)
    if FluxSafeRegisterEvent then
        return FluxSafeRegisterEvent(frame, eventName)
    else
        local ok, err = pcall(function() frame:RegisterEvent(eventName) end)
        return ok
    end
end

local function SafeRegisterUnitEvent(frame, eventName, unit)
    if FluxSafeRegisterUnitEvent then
        return FluxSafeRegisterUnitEvent(frame, eventName, unit)
    end
    local ok = pcall(function() frame:RegisterUnitEvent(eventName, unit) end)
    return ok
end

-- Minimal built-in legacy event system
if IsLegacy() and not _G.FluxButtonLegacySystem then
    local Legacy = {}
    Legacy.ActiveButtons = {}

    local updateFlags = {
        RefFull = false,
        RefChecked = false,
        RefEquipped = false,
        RefUsable = false,
        RefCooldown = false,
        RefText = false,
        RefConditional = false,
        RefConditionalFromMod = false,
        RefSpells = false,  -- For spell override/replacement updates
    }

    local updater = CreateFrame("Frame")
    updater:SetFrameStrata("LOW")
    updater:Show()

    local function Process()
        if not updateFlags.RefFull then return end
        local fromMod = updateFlags.RefConditionalFromMod == true
        for i = 1, #Legacy.ActiveButtons do
            local b = Legacy.ActiveButtons[i]
            if b and b.UpdateTexture then b:UpdateTexture() end
            if updateFlags.RefChecked and b.UpdateChecked then b:UpdateChecked() end
            if updateFlags.RefEquipped and b.UpdateEquipped then b:UpdateEquipped() end
            if updateFlags.RefUsable and b.UpdateUsable then b:UpdateUsable() end
            if updateFlags.RefCooldown and b.UpdateCooldown then b:UpdateCooldown() end
            if updateFlags.RefText and b.UpdateTextCount then b:UpdateTextCount() end
            if updateFlags.RefConditional and b.TranslateMacro then
                if not (fromMod and (b.IsHearthButton or b.IsMountButton or b.IsTeleportPortalButton)) then
                    b:TranslateMacro()
                end
            end
            if updateFlags.RefSpells and b.RefreshSpell then b:RefreshSpell() end
        end
        for k in pairs(updateFlags) do updateFlags[k] = false end
        updater:SetScript("OnUpdate", nil)
    end

    local function Request(flagName)
        updateFlags.RefFull = true
        if flagName and updateFlags[flagName] ~= nil then updateFlags[flagName] = true end
        if not updater:GetScript("OnUpdate") then
            updater:SetScript("OnUpdate", function() Process() end)
        end
    end

    local stormUsableRefreshPending = false

    local ef = CreateFrame("Frame")
    ef:SetScript("OnEvent", function(_, evt, arg1, arg2)
        if _G.FluxExtraButtonDisableActionbarUsableEvents
            and (evt == "SPELL_UPDATE_USABLE" or evt == "ACTIONBAR_UPDATE_USABLE") then
            return
        end
        if evt == "BAG_UPDATE" or evt == "BAG_UPDATE_DELAYED" then
            local VS = FluxVendorSession
            if VS and VS.IsBurstActive and VS.IsBurstActive() then
                Request("RefText")
            elseif VS and VS.IsPurchaseStormActive and VS.IsPurchaseStormActive() then
                -- Purchase storm: counts only per pulse, one usable pass at settle.
                Request("RefText")
                if not stormUsableRefreshPending and VS.OnPurchaseStormSettled then
                    stormUsableRefreshPending = true
                    VS.OnPurchaseStormSettled(function()
                        stormUsableRefreshPending = false
                        Request("RefUsable")
                        Request("RefText")
                    end)
                end
            else
                Request("RefUsable")
                Request("RefText")
            end
            return
        end
        
        if evt == "ACTIONBAR_UPDATE_STATE" or evt == "CURRENT_SPELL_CAST_CHANGED"
            or evt == "PLAYER_ENTER_COMBAT" or evt == "PLAYER_LEAVE_COMBAT"
            or evt == "START_AUTOREPEAT_SPELL" or evt == "STOP_AUTOREPEAT_SPELL"
            or evt == "COMPANION_UPDATE" then
            if (evt == "ACTIONBAR_UPDATE_STATE" or evt == "CURRENT_SPELL_CAST_CHANGED")
                and _G.FluxSpellBindingProfile_ShouldSuppressCastEdgeRefresh
                and _G.FluxSpellBindingProfile_ShouldSuppressCastEdgeRefresh() then
                return
            end
            Request("RefChecked")
        elseif evt == "PLAYER_EQUIPMENT_CHANGED" then
            Request("RefEquipped")
        elseif evt == "SPELL_UPDATE_USABLE" or evt == "ACTIONBAR_UPDATE_USABLE"
            or evt == "PLAYER_CONTROL_LOST" or evt == "PLAYER_CONTROL_GAINED"
            or evt == "VEHICLE_UPDATE" or evt == "MINIMAP_UPDATE_ZOOM"
            or evt == "ZONE_CHANGED" or evt == "ZONE_CHANGED_INDOORS"
            or evt == "ZONE_CHANGED_NEW_AREA" or evt == "TOYS_UPDATED"
            or evt == "PLAYER_REGEN_ENABLED" or evt == "PLAYER_REGEN_DISABLED" then
            Request("RefUsable")
        elseif evt == "SPELL_UPDATE_COOLDOWN" or evt == "ACTIONBAR_UPDATE_COOLDOWN"
            or evt == "UPDATE_SHAPESHIFT_COOLDOWN" then
            Request("RefCooldown")
        elseif evt == "SPELL_UPDATE_CHARGES" or evt == "BAG_UPDATE_COOLDOWN" then
            -- Charge changes affect both cooldown and text count
            Request("RefCooldown")
            Request("RefText")
        elseif evt == "UNIT_AURA" then
            -- Flux perf: count text does not depend on auras. Skipping RefText here
            -- avoids walking all ExtraButtons on every player buff tick / cast edge.
            -- Aura-driven ExtraButton state (e.g. Consumables) uses its own listeners.
            return
        elseif evt == "TRADE_SKILL_SHOW" then
            Request("RefText")
        elseif evt == "TRADE_SKILL_CLOSE" then
            Request("RefText")
            Request("RefChecked")
        elseif evt == "GET_ITEM_INFO_RECEIVED" then
            local now = GetTime()
            if not FluxButtonEvents._lastItemInfoUpdate or (now - FluxButtonEvents._lastItemInfoUpdate > 0.5) then
                FluxButtonEvents._lastItemInfoUpdate = now
                Request("RefUsable")
                Request("RefText")
            end
        elseif evt == "MODIFIER_STATE_CHANGED" or evt == "PLAYER_TARGET_CHANGED"
            or evt == "PLAYER_FOCUS_CHANGED" or evt == "ACTIONBAR_PAGE_CHANGED"
            or evt == "UPDATE_BONUS_ACTIONBAR" or evt == "UPDATE_SHAPESHIFT_FORM"
            or evt == "UNIT_DISPLAYPOWER"
            or evt == "UPDATE_STEALTH" or evt == "UNIT_ENTERED_VEHICLE"
            or evt == "UNIT_EXITED_VEHICLE" or evt == "ACTIONBAR_SLOT_CHANGED" then
            -- ButtonForge Conditional path: RefConditional only. Usable comes from
            -- SPELL/ACTIONBAR_UPDATE_USABLE (and targeted UpdateUsable after TranslateMacro).
            -- Form/bonus/page/displaypower open a suppress window (see modern Conditional).
            if evt == "UPDATE_SHAPESHIFT_FORM" then
                local form = GetShapeshiftForm and GetShapeshiftForm() or 0
                local last = FluxButtonEvents._lastShapeshiftForm
                if last ~= nil and form == last then
                    return
                end
                FluxButtonEvents._lastShapeshiftForm = form
            end
            if evt == "UPDATE_SHAPESHIFT_FORM" or evt == "UPDATE_BONUS_ACTIONBAR"
                or evt == "ACTIONBAR_PAGE_CHANGED" or evt == "UNIT_DISPLAYPOWER" then
                -- Nuclear: ExtraButton grids/badges do zero Conditional work on shapeshift /
                -- display-power (mana↔energy/rage) swaps.
                if evt == "UNIT_DISPLAYPOWER" then
                    -- Legacy OnEvent is (_, evt, arg1, arg2) — arg1 is the unit.
                    local unit = arg1
                    if unit and unit ~= "player" then
                        return
                    end
                end
                FluxButtonEvents.BeginFormStorm(0.55)
                return
            elseif evt == "ACTIONBAR_SLOT_CHANGED" then
                if FluxButtonEvents.IsFormStormActive() then
                    return
                end
            end
            if evt == "PLAYER_TARGET_CHANGED" then
                -- Coalesce only — immediate ActiveButtons megawalk was a target-spam hitch.
                -- Full.OnUpdate RefConditional/RefUsable handles TranslateMacro + UpdateUsable.
                Request("RefConditional")
                Request("RefUsable")
            elseif evt == "MODIFIER_STATE_CHANGED" then
                -- Module-managed flyout buttons skip TranslateMacro; only
                -- request conditional refresh for other macros (no RefUsable).
                updateFlags.RefConditionalFromMod = true
                Request("RefConditional")
            else
                -- Form / bonus / page / stealth / vehicle / ASC: macros only (ButtonForge).
                Request("RefConditional")
            end
        elseif evt == "SPELLS_CHANGED" or evt == "LEARNED_SPELL_IN_TAB" or evt == "LEARNED_SPELL_IN_SKILL_LINE" then
            if evt == "SPELLS_CHANGED"
                and _G.FluxSpellBindingProfile_ShouldSuppressCastEdgeRefresh
                and _G.FluxSpellBindingProfile_ShouldSuppressCastEdgeRefresh() then
                return
            end
            -- Handle spell overrides (Smite -> Void Blast, etc.)
            Request("RefSpells")
        else
            Request()
        end
    end)
    
    local legacyEvents = {
        "CURRENT_SPELL_CAST_CHANGED","ACTIONBAR_UPDATE_STATE","PLAYER_ENTER_COMBAT","PLAYER_LEAVE_COMBAT",
        "START_AUTOREPEAT_SPELL","STOP_AUTOREPEAT_SPELL","COMPANION_UPDATE","PLAYER_EQUIPMENT_CHANGED",
        "SPELL_UPDATE_USABLE","ACTIONBAR_UPDATE_USABLE","SPELL_UPDATE_COOLDOWN","ACTIONBAR_UPDATE_COOLDOWN",
        "SPELL_UPDATE_CHARGES","BAG_UPDATE_COOLDOWN","BAG_UPDATE_DELAYED",
        -- UNIT_AURA omitted: RefText does not need aura ticks (see handler no-op + modern Text).
        "MODIFIER_STATE_CHANGED","PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","ACTIONBAR_PAGE_CHANGED",
        "UPDATE_BONUS_ACTIONBAR","UPDATE_SHAPESHIFT_FORM","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED",
        "UPDATE_SHAPESHIFT_COOLDOWN","UNIT_DISPLAYPOWER",
        "UPDATE_STEALTH","UNIT_ENTERED_VEHICLE","UNIT_EXITED_VEHICLE","ACTIONBAR_SLOT_CHANGED",
        "GET_ITEM_INFO_RECEIVED","ZONE_CHANGED","ZONE_CHANGED_INDOORS","ZONE_CHANGED_NEW_AREA",
        "PLAYER_CONTROL_LOST","PLAYER_CONTROL_GAINED","MINIMAP_UPDATE_ZOOM","VEHICLE_UPDATE",
        "TRADE_SKILL_SHOW","TRADE_SKILL_CLOSE","TOYS_UPDATED",
        "SPELLS_CHANGED","LEARNED_SPELL_IN_TAB","LEARNED_SPELL_IN_SKILL_LINE",  -- Spell override events
    }
    for i = 1, #legacyEvents do SafeRegisterEvent(ef, legacyEvents[i]) end

    if FluxMouseoverRefresh and FluxMouseoverRefresh.Register then
        FluxMouseoverRefresh.Register("ExtraButtonsLegacy", function()
            for i = 1, #Legacy.ActiveButtons do
                local button = Legacy.ActiveButtons[i]
                if button and button.ActionType == "macro" then
                    local body = FluxButtonEvents.GetMacroBodyForButton(button)
                    if body and body:lower():find("@mouseover", 1, true) then
                        if button.TranslateMacro then
                            button:TranslateMacro()
                        end
                        if button.UpdateUsable then
                            button:UpdateUsable()
                        end
                    end
                end
            end
        end)
    end
    
    -- Flash subsystem for auto-attack flashing.
    -- Demand-armed: permanent OnUpdate while idle was a passive lag hotspot.
    local Flash = CreateFrame("Frame")
    Flash:Hide()
    Flash.FlashTime = 0
    Flash.On = false
    Flash._armed = false

    local function Flash_Disarm()
        if not Flash._armed then return end
        Flash._armed = false
        Flash:SetScript("OnUpdate", nil)
        Flash:Hide()
        Flash.On = false
        Flash.FlashTime = 0
        _G.FluxPerfEBSFlashArmed = false
        for i = 1, #Legacy.ActiveButtons do
            local b = Legacy.ActiveButtons[i]
            if b and b.FlashHide then
                pcall(b.FlashHide, b)
            end
        end
    end

    local function Flash_OnUpdate(self, elapsed)
        local t = (self.FlashTime or 0) - (elapsed or 0)
        if t <= 0 then
            local step = (ATTACK_BUTTON_FLASH_TIME or 0.4)
            if -t >= step then t = step else t = step + t end
            self.On = not self.On
            local any = false
            for i = 1, #Legacy.ActiveButtons do
                local b = Legacy.ActiveButtons[i]
                if b and b.FlashShow and b.FlashHide then
                    any = true
                    if self.On then b:FlashHide() else b:FlashShow() end
                end
            end
            if not any then
                Flash_Disarm()
                return
            end
        end
        self.FlashTime = t
    end

    local function Flash_Arm()
        if Flash._armed then return end
        Flash._armed = true
        Flash.FlashTime = 0
        Flash:SetScript("OnUpdate", Flash_OnUpdate)
        Flash:Show()
        _G.FluxPerfEBSFlashArmed = true
    end

    Flash:SetScript("OnEvent", function(_, event)
        for i = 1, #Legacy.ActiveButtons do
            local b = Legacy.ActiveButtons[i]
            if b and b.UpdateFlash then b:UpdateFlash() end
        end
        if event == "PLAYER_LEAVE_COMBAT" or event == "STOP_AUTOREPEAT_SPELL" then
            local needsFlash = false
            if IsCurrentSpell then
                needsFlash = IsCurrentSpell(6603) or IsCurrentSpell(75)
            end
            if not needsFlash then
                for i = 1, #Legacy.ActiveButtons do
                    local b = Legacy.ActiveButtons[i]
                    if b and (b.flashing or b.flashing == 1 or b._fluxFlashing) then
                        needsFlash = true
                        break
                    end
                end
            end
            if not needsFlash then
                Flash_Disarm()
            end
            return
        end
        Flash_Arm()
    end)
    SafeRegisterEvent(Flash, "PLAYER_ENTER_COMBAT")
    SafeRegisterEvent(Flash, "PLAYER_LEAVE_COMBAT")
    SafeRegisterEvent(Flash, "START_AUTOREPEAT_SPELL")
    SafeRegisterEvent(Flash, "STOP_AUTOREPEAT_SPELL")
    Legacy.Flash_Arm = Flash_Arm
    Legacy.Flash_Disarm = Flash_Disarm
    
    -- Range checking is now integrated into Usability system
    -- Add PLAYER_TARGET_CHANGED to Usable events for range checking
    SafeRegisterEvent(Usable, "PLAYER_TARGET_CHANGED")
    SafeRegisterEvent(Usable, "UNIT_FACTION")

    function Legacy.Initialize()
        -- Force initial refresh
        local after = C_Timer and C_Timer.After
        if after then
            after(0.05, function() Request("RefFull") end)
            after(0.5, function() 
                Request("RefUsable")
                Request("RefText") 
            end)
            after(1.0, function() 
                Request("RefUsable")
                Request("RefText") 
            end)
        else
            Request("RefFull")
        end
    end

    function Legacy.RegisterButton(button)
        if not button then return end
        for i = 1, #Legacy.ActiveButtons do
            if Legacy.ActiveButtons[i] == button then
                return
            end
        end
        table.insert(Legacy.ActiveButtons, button)
        Request("RefFull")
    end

    function Legacy.UnregisterButton(button)
        if not button then return end
        for i = #Legacy.ActiveButtons, 1, -1 do
            if Legacy.ActiveButtons[i] == button then 
                table.remove(Legacy.ActiveButtons, i) 
                break 
            end
        end
    end
    
    _G.FluxButtonLegacySystem = Legacy
end

-- Modern event system
local EventFrames = {}
local Full, Checked, Equipped, Usable, Cooldown, Text, Conditional, Spells

if not IsLegacy() then
    EventFrames["Full"] = CreateFrame("FRAME")
    EventFrames["Checked"] = CreateFrame("FRAME")
    EventFrames["Equipped"] = CreateFrame("FRAME")
    EventFrames["Usable"] = CreateFrame("FRAME")
    EventFrames["Cooldown"] = CreateFrame("FRAME")
    EventFrames["Text"] = CreateFrame("FRAME")
    EventFrames["Conditional"] = CreateFrame("FRAME")
    EventFrames["Spells"] = CreateFrame("FRAME")
    
    Full = EventFrames["Full"]
    Checked = EventFrames["Checked"]
    Equipped = EventFrames["Equipped"]
    Usable = EventFrames["Usable"]
    Cooldown = EventFrames["Cooldown"]
    Text = EventFrames["Text"]
    Conditional = EventFrames["Conditional"]
    Spells = EventFrames["Spells"]

    Full:SetFrameStrata("LOW")
    Full:Show()

    -- Initialize refresh flags
    Full.RefreshButtons = false
    Full.RefFull = false
    Full.RefChecked = false
    Full.RefEquipped = false
    Full.RefUsable = false
    Full.RefCooldown = false
    Full.RefText = false
    Full.RefConditional = false
    Full.RefConditionalFromMod = false
    Full.RefConditionalLight = false -- form/bonus/page: skip EffectRefresh.RefreshAll
    Full.RefSpells = false  -- For spell override/replacement updates
    Full.RefSkipTexture = false

    -- ButtonForge Classic: debounce duplicate UPDATE_SHAPESHIFT_FORM.
    FluxButtonEvents._lastShapeshiftForm = GetShapeshiftForm and GetShapeshiftForm() or 0
    -- While form/bonus/page settle, ASC storms are redundant for ExtraButton macros.
    FluxButtonEvents._formStormIgnoreAscUntil = 0
    
    -- Range checking timer (for continuous range updates when units move)
    Full.rangeTimer = 0
    local function GetRangeCheckInterval()
        if UnitExists("mouseover") and FluxMouseoverRefresh and FluxMouseoverRefresh.GetInterval then
            return FluxMouseoverRefresh.GetInterval()
        end
        return tonumber(_G.FluxExtraButtonRangeCheckInterval) or 0.18
    end

    local function ButtonNeedsRangeCheck(button)
        if not button or not button.UpdateUsable then
            return false
        end
        -- Bar-leg badges range via synced action slot.
        if button._fluxBadgeIconLeg == "bar"
            and type(button._fluxSyncedActionSlot) == "number"
            and button._fluxSyncedActionSlot >= 1 then
            return true
        end
        -- Multi-cast extras: no OOR poll (peeks; usable owns tint via spell/item id).
        local key = button._fluxBadgeKey
            or (button.Widget and button.Widget._fluxBadgeKey)
        if type(key) == "string" and key:sub(1, 6) == "extra:" then
            return false
        end
        -- Prefer identity/display spell (bindingWins swap) for dual-split peers only.
        if type(button._fluxAspectDisplaySpellId) == "number" and button._fluxAspectDisplaySpellId > 0 then
            return true
        end
        if type(button.SpellId) == "number" and button.SpellId > 0 then
            return true
        end
        if type(button.ItemId) == "number" and button.ItemId > 0 then
            return true
        end
        if not button.ActionType or not button.ActionValue then
            return false
        end
        local at = button.ActionType
        return (at == "spell") or (at == "item")
            or (at == "macro" and (button.MacroMode == "spell" or button.MacroMode == "item"))
    end

    -- Flux perf: empty / hidden buttons skip Full batch sweeps (still registered badges with content run).
    local function ButtonHasBatchContent(button)
        if not button then
            return false
        end
        if button.ActionType and button.ActionValue then
            return true
        end
        if button._fluxBadgeIconLeg
            and type(button._fluxSyncedActionSlot) == "number"
            and button._fluxSyncedActionSlot >= 1 then
            return true
        end
        if button.SingleButtonAssistantSpellId then
            return true
        end
        return false
    end

    local function ButtonBatchEligible(button)
        if not ButtonHasBatchContent(button) then
            return false
        end
        -- Action-bar badges are owned by BadgeHost/ActionBar. Keep them on badgeButtons
        -- for range/ForceRangeRefresh only — never sweep via Full ActiveButtons batches
        -- (RefUsable/Checked/Conditional). ActiveButtons is dominated by badges.
        if button._fluxIsActionBarBadge
            or (button.Widget and button.Widget._fluxIsActionBarBadge) then
            return false
        end
        local frame = button.Widget or button
        if frame and frame.IsShown and not frame:IsShown() then
            return false
        end
        return true
    end

    function FluxButtonEvents.RefreshRangeButtonMembership(button)
        if not FluxButtonEvents.rangeButtons then
            FluxButtonEvents.rangeButtons = {}
        end
        -- Hidden action-bar peers stay out of the poll set until shown again.
        local frame = button and (button.Widget or button)
        if frame and frame.IsShown and not frame:IsShown() then
            FluxButtonEvents.rangeButtons[button] = nil
        elseif ButtonNeedsRangeCheck(button) then
            FluxButtonEvents.rangeButtons[button] = true
        else
            FluxButtonEvents.rangeButtons[button] = nil
        end
        FluxButtonEvents.RefreshMouseoverMacroMembership(button)
    end

    local function ShouldRunExtraButtonRangeChecks()
        if FluxMouseoverRefresh and FluxMouseoverRefresh.ShouldSkipBackgroundRangePoll
            and FluxMouseoverRefresh.ShouldSkipBackgroundRangePoll() then
            return false
        end
        if InCombatLockdown() then
            return true
        end
        if UnitExists("mouseover") then
            return true
        end
        -- Friendly targets (heals) must poll OOC too — not only attackable.
        if UnitExists("target") then
            return true
        end
        return false
    end

    -- Demand range ticker (not Full OnUpdate). Keeps OOR tint while targeting
    -- without a permanent per-frame script when batch flags are idle.
    local ebsRangeTicker = nil

    local function RunExtraButtonRangePoll()
        local rangeButtons = FluxButtonEvents.rangeButtons
        if not rangeButtons then
            return
        end
        for button in next, rangeButtons do
            local frame = button and (button.Widget or button)
            if not frame or (frame.IsForbidden and frame:IsForbidden()) then
                rangeButtons[button] = nil
            elseif frame.IsShown and not frame:IsShown() then
                rangeButtons[button] = nil
            elseif button._fluxParkedOffscreen then
                rangeButtons[button] = nil
            elseif button and button.UpdateUsable then
                pcall(button.UpdateUsable, button)
            end
        end
    end

    local function ClearStaleExtraButtonOOR()
        local rangeButtons = FluxButtonEvents.rangeButtons
        if not rangeButtons then
            return
        end
        local FR = _G.FluxRange
        for button in next, rangeButtons do
            if button and (button._outOfRange or button.outOfRange) then
                if FR and FR.ClearFlag then
                    FR.ClearFlag(button)
                else
                    button._outOfRange = false
                    button.outOfRange = false
                end
                if button.UpdateUsable then
                    pcall(button.UpdateUsable, button)
                end
            end
        end
    end

    local function CancelExtraButtonRangeTicker()
        if ebsRangeTicker then
            ebsRangeTicker:Cancel()
            ebsRangeTicker = nil
        end
        _G.FluxEBSRangeTicker = nil
    end

    local function EnsureExtraButtonRangeTicker()
        if not ShouldRunExtraButtonRangeChecks() then
            CancelExtraButtonRangeTicker()
            ClearStaleExtraButtonOOR()
            return
        end
        if ebsRangeTicker or not C_Timer or not C_Timer.NewTicker then
            return
        end
        local interval = GetRangeCheckInterval()
        ebsRangeTicker = C_Timer.NewTicker(interval, function()
            if not ShouldRunExtraButtonRangeChecks() then
                CancelExtraButtonRangeTicker()
                ClearStaleExtraButtonOOR()
                return
            end
            RunExtraButtonRangePoll()
        end)
        _G.FluxEBSRangeTicker = ebsRangeTicker
    end

    function FluxButtonEvents.EnsureRangeTicker()
        EnsureExtraButtonRangeTicker()
    end

    function FluxButtonEvents.ForceRangeRefresh()
        -- One-shot poll; do NOT arm Full OnUpdate for range alone.
        RunExtraButtonRangePoll()
        EnsureExtraButtonRangeTicker()
        if FluxButtonEvents.IsFormStormActive and FluxButtonEvents.IsFormStormActive() then
            return
        end
        local badges = FluxButtonEvents.badgeButtons
        if badges then
            for i = 1, #badges do
                local badge = badges[i]
                if badge and badge.UpdateUsable and (not badge.IsShown or badge:IsShown()) then
                    FluxButtonEvents.RefreshRangeButtonMembership(badge)
                    pcall(badge.UpdateUsable, badge)
                end
            end
        end
    end

    FluxButtonEvents.EventFrames = EventFrames

    -- Flux perf T1.8: do NOT start OnUpdate at init. Range checks are only
    -- meaningful while the player has a target or mouseover. The batch refresh
    -- paths each call `Full:SetScript("OnUpdate", Full.OnUpdate)` when flags
    -- are set, and PLAYER_TARGET_CHANGED / UPDATE_MOUSEOVER_UNIT also arm it
    -- below (Usable:OnEvent / Conditional:OnEvent). When neither a target nor
    -- mouseover exists and no refresh flags are pending, OnUpdate clears
    -- itself on its next tick.
    
    -- OnUpdate function
    -- Budgeted batch flushes: large ActiveButtons storms hitch less by spreading
    -- work across frames (~32 eligible buttons per flag per tick).
    local FULL_BATCH_BUDGET = 32
    Full._batchCursor = Full._batchCursor or {}

    local function ForEachEligibleBudgeted(self, key, fn)
        local list = FluxButtonEvents.ActiveButtons
        local start = self._batchCursor[key] or 1
        local done = 0
        local i = start
        local n = #list
        while i <= n do
            local button = list[i]
            i = i + 1
            if ButtonBatchEligible(button) then
                fn(button)
                done = done + 1
                if done >= FULL_BATCH_BUDGET then
                    self._batchCursor[key] = i
                    return false
                end
            end
        end
        self._batchCursor[key] = nil
        return true
    end

    function Full:OnUpdate(elapsed)
        if self.RefreshButtons then
            local function safeCall(btn, method)
                if btn and btn[method] then
                    pcall(btn[method], btn)
                end
            end

            local incomplete = false

            if not self.RefSkipTexture then
                if not ForEachEligibleBudgeted(self, "tex", function(button)
                    safeCall(button, "UpdateTexture")
                end) then
                    incomplete = true
                else
                    -- Prevent re-walking textures on subsequent budgeted ticks of same flush.
                    self.RefSkipTexture = true
                end
            end
            
            if self.RefChecked then
                if not ForEachEligibleBudgeted(self, "chk", function(button)
                    safeCall(button, "UpdateChecked")
                end) then
                    incomplete = true
                else
                    -- Action-bar badges are excluded from ButtonBatchEligible — still need
                    -- ButtonForge UpdateChecked so Summon-on-badge gets the ring.
                    local badges = FluxButtonEvents.badgeButtons
                    if badges then
                        for i = 1, #badges do
                            local badge = badges[i]
                            if badge then
                                local frame = badge.Widget or badge
                                local alpha = tonumber(badge._fluxBadgeEffectiveAlpha) or 1
                                if alpha > 0.01 and not (frame and frame.IsShown and not frame:IsShown()) then
                                    safeCall(badge, "UpdateChecked")
                                end
                            end
                        end
                    end
                    self.RefChecked = false
                end
            end
            
            if self.RefEquipped then
                if not ForEachEligibleBudgeted(self, "eq", function(button)
                    safeCall(button, "UpdateEquipped")
                end) then
                    incomplete = true
                else
                    self.RefEquipped = false
                end
            end
            
            if self.RefUsable then
                local powerSettle = FluxButtonEvents._deferredUsablePowerSettle == true
                local skipBadges = self.RefUsableSkipBadges == true
                if not ForEachEligibleBudgeted(self, "use", function(button)
                    if powerSettle and button.ActionType == "item" then
                        return
                    end
                    safeCall(button, "UpdateUsable")
                end) then
                    incomplete = true
                else
                    -- Action-bar badges are excluded from ButtonBatchEligible; still need
                    -- ACTIONBAR/BAG usable paints. Skip on SPELL_UPDATE_USABLE-only (LAB
                    -- already painted bar buttons; badges follow ACTIONBAR_UPDATE_USABLE).
                    if not skipBadges then
                        local badges = FluxButtonEvents.badgeButtons
                        if badges then
                            for i = 1, #badges do
                                local badge = badges[i]
                                if badge then
                                    local frame = badge.Widget or badge
                                    if not (frame and frame.IsShown and not frame:IsShown()) then
                                        if not (powerSettle and badge.ActionType == "item") then
                                            safeCall(badge, "UpdateUsable")
                                        end
                                    end
                                end
                            end
                        end
                    end
                    self.RefUsable = false
                    self.RefUsableSkipBadges = nil
                    self._deferredUsablePowerSettle = nil
                    FluxButtonEvents._deferredUsablePowerSettle = nil
                end
            end
            
            if self.RefCooldown then
                if not ForEachEligibleBudgeted(self, "cd", function(button)
                    safeCall(button, "UpdateCooldown")
                end) then
                    incomplete = true
                else
                    -- Action-bar badges are excluded from ButtonBatchEligible (usable/checked
                    -- sweeps stay cheap) but still need SPELL/BAG/ACTIONBAR cooldown paints.
                    local badges = FluxButtonEvents.badgeButtons
                    if badges then
                        for i = 1, #badges do
                            local badge = badges[i]
                            if badge then
                                local frame = badge.Widget or badge
                                if not (frame and frame.IsShown and not frame:IsShown()) then
                                    safeCall(badge, "UpdateCooldown")
                                    if badge._fluxBadgeHiddenUnlessCd and badge.ApplyDisplayPolicy then
                                        safeCall(badge, "ApplyDisplayPolicy")
                                    end
                                end
                            end
                        end
                    end
                    self.RefCooldown = false
                end
            end
            
            if self.RefText then
                if not ForEachEligibleBudgeted(self, "txt", function(button)
                    safeCall(button, "UpdateTextCount")
                end) then
                    incomplete = true
                else
                    self.RefText = false
                end
            end
            
            if self.RefConditional then
                local fromMod = self.RefConditionalFromMod == true
                local light = self.RefConditionalLight == true
                local paging = _G._fluxPagingInProgress ~= nil
                -- Rapid SHIFT/CTRL: PagingCoordinator owns bar/badge settle; defer EBS
                -- TranslateMacro walk until latch clears (CatchUp flushes).
                if fromMod and paging then
                    self._fluxDeferredModConditional = true
                elseif not ForEachEligibleBudgeted(self, "cond", function(button)
                    if button.TranslateMacro and (button.ActionType == "macro" or button._fluxCombatSwapBody) then
                        if fromMod and (button.IsHearthButton or button.IsMountButton
                            or button.IsTeleportPortalButton) then
                            -- no-op
                        elseif fromMod and button._fluxHasModConditional == false then
                            -- Mod edge: skip macros with no [mod:]/[nomod]
                        elseif light and button._fluxHasStanceConditional == false then
                            -- Form/bonus storm: skip macros with no stance/form/bonusbar/etc.
                        else
                            local ok, changed = pcall(button.TranslateMacro, button)
                            if ok and changed and not self.RefUsable and not paging then
                                safeCall(button, "UpdateUsable")
                            end
                            if ok and changed and not self.RefText then
                                safeCall(button, "UpdateTextCount")
                            end
                            if ok and changed and not self.RefCooldown then
                                safeCall(button, "UpdateCooldown")
                            end
                        end
                    end
                end) then
                    incomplete = true
                else
                    -- Action-bar badges are excluded from ButtonBatchEligible; still need
                    -- [mod:]/[@target] TranslateMacro + cooldown clear/repaint.
                    -- Skip badge walk under paging latch (coordinator RefreshDisplaysForColumns).
                    local badges = FluxButtonEvents.badgeButtons
                    if badges and not paging then
                        for i = 1, #badges do
                            local badge = badges[i]
                            if badge and badge.ActionType == "macro" and badge.TranslateMacro then
                                local frame = badge.Widget or badge
                                if not (frame and frame.IsShown and not frame:IsShown()) then
                                    if fromMod and badge._fluxHasModConditional == false then
                                        -- no-op
                                    elseif light and badge._fluxHasStanceConditional == false then
                                        -- no-op
                                    else
                                        if badge.InvalidateTranslateMacroCache then
                                            pcall(badge.InvalidateTranslateMacroCache, badge)
                                        end
                                        local ok, changed = pcall(badge.TranslateMacro, badge)
                                        if ok then
                                            if changed then
                                                if not self.RefCooldown then
                                                    safeCall(badge, "UpdateCooldown")
                                                end
                                                if badge._fluxBadgeHiddenUnlessCd and badge.ApplyDisplayPolicy then
                                                    safeCall(badge, "ApplyDisplayPolicy")
                                                end
                                            end
                                            -- ButtonForge: TranslateMacro → UpdateChecked on this surface.
                                            safeCall(badge, "UpdateChecked")
                                            local col = badge._fluxBadgeColumn
                                                or (badge.Widget and badge.Widget._fluxBadgeColumn)
                                            if type(col) == "number" then
                                                local Ck = _G.FluxEffectChecked or _G.FluxBadgeCheckedDrive
                                                if Ck and Ck.SettleColumn then
                                                    pcall(Ck.SettleColumn, col, { discover = true })
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if not paging and not fromMod and not light then
                        local EffectRefresh = _G.FluxEffectRefresh
                        if EffectRefresh and EffectRefresh.RefreshAll then
                            EffectRefresh.RefreshAll({ glow = true, checked = true, cast = false })
                        end
                    end
                    self._fluxDeferredModConditional = nil
                    self.RefConditional = false
                    self.RefConditionalFromMod = false
                    self.RefConditionalLight = false
                end
            end
            
            -- Handle spell refresh (for spell overrides like Smite -> Void Blast)
            if self.RefSpells then
                if not ForEachEligibleBudgeted(self, "spl", function(button)
                    safeCall(button, "RefreshSpell")
                end) then
                    incomplete = true
                else
                    self.RefSpells = false
                end
            end
            
            if not incomplete then
                -- Always clear residual flags when all budgeted walks finished.
                self.RefreshButtons = false
                self.RefFull = false
                self.RefChecked = false
                self.RefEquipped = false
                self.RefUsable = false
                self.RefCooldown = false
                self.RefText = false
                -- Keep mod-conditional armed across paging latch; CatchUp flushes it.
                if not self._fluxDeferredModConditional then
                    self.RefConditional = false
                    self.RefConditionalFromMod = false
                    self.RefConditionalLight = false
                end
                self.RefSpells = false
                self.RefSkipTexture = false
                wipe(self._batchCursor)
            else
                -- Keep RefreshButtons armed so the next tick continues the budget.
                self.RefreshButtons = true
                _G.FluxPerfEBSBatchBudgetHits = (_G.FluxPerfEBSBatchBudgetHits or 0) + 1
            end
        end

        -- Range is owned by EnsureExtraButtonRangeTicker — never keep Full OnUpdate
        -- armed solely because a target exists (was the idle FPS cliff).
        if not self.RefreshButtons then
            self:SetScript("OnUpdate", nil)
        end
    end
   
    -- Event handlers
    function Checked:OnEvent(event, unitID)
        -- Flux perf: skip per-slot bag churn during a vendor sell burst; buttons
        -- are refreshed once when the burst ends (mirrors Usable:OnEvent).
        if event == "BAG_UPDATE_DELAYED"
            and FluxVendorSession and FluxVendorSession.IsBurstActive and FluxVendorSession.IsBurstActive() then
            return
        end
        if (event == "ACTIONBAR_UPDATE_STATE" or event == "CURRENT_SPELL_CAST_CHANGED")
            and _G.FluxSpellBindingProfile_ShouldSuppressCastEdgeRefresh
            and _G.FluxSpellBindingProfile_ShouldSuppressCastEdgeRefresh() then
            return
        end
        -- Condition-flip / paging latch: CatchUp + coordinator own checked settle.
        if _G._fluxPagingInProgress and event == "ACTIONBAR_UPDATE_STATE" then
            return
        end
        -- Shapeshift: ACTIONBAR_UPDATE_STATE storms — suppress during form settle.
        if event == "ACTIONBAR_UPDATE_STATE" and FluxButtonEvents.IsFormStormActive
            and FluxButtonEvents.IsFormStormActive() then
            return
        end
        -- Flux perf: checked state uses player-only APIs (IsCurrentSpell, etc.).
        if unitID and unitID ~= "player" then
            return
        end
        Full.RefChecked = true
        Full.RefreshButtons = true
        if not Full:GetScript("OnUpdate") then Full:SetScript("OnUpdate", Full.OnUpdate) end
    end
    
    local equipDebounceTimer = nil
    local function ArmEquippedRefresh()
        Full.RefEquipped = true
        Full.RefUsable = true
        Full.RefSkipTexture = true
        Full.RefreshButtons = true
        if not Full:GetScript("OnUpdate") then Full:SetScript("OnUpdate", Full.OnUpdate) end
    end

    function Equipped:OnEvent()
        if equipDebounceTimer and equipDebounceTimer.Cancel then
            equipDebounceTimer:Cancel()
        end
        if C_Timer and C_Timer.NewTimer then
            equipDebounceTimer = C_Timer.NewTimer(0.15, function()
                equipDebounceTimer = nil
                ArmEquippedRefresh()
            end)
        else
            ArmEquippedRefresh()
        end
    end
    
    -- Throttling for 12.0.0+ clients to prevent spell flickering
    local lastUsableEventTime = {}
    local USABLE_COMBAT_THROTTLE = 0.2  -- 200ms throttle during combat (increased)
    local USABLE_NORMAL_THROTTLE = 0.15  -- 150ms throttle outside combat
    
    function Usable:OnEvent(event)
        if event == "BAG_UPDATE_DELAYED"
            and FluxVendorSession and FluxVendorSession.IsBurstActive and FluxVendorSession.IsBurstActive() then
            return
        end
        -- Profiling: set _G.FluxExtraButtonDisableActionbarUsableEvents = true to isolate LAB vs ExtraButton
        -- double full-bar usable work on ACTIONBAR_UPDATE_USABLE / SPELL_UPDATE_USABLE (reload after change).
        if _G.FluxExtraButtonDisableActionbarUsableEvents
            and (event == "SPELL_UPDATE_USABLE" or event == "ACTIONBAR_UPDATE_USABLE") then
            return
        end
        -- Shapeshift / UNIT_DISPLAYPOWER usable storms: coalesce into one post-storm pass.
        if (event == "SPELL_UPDATE_USABLE" or event == "ACTIONBAR_UPDATE_USABLE")
            and FluxButtonEvents.IsFormStormActive and FluxButtonEvents.IsFormStormActive() then
            FluxButtonEvents.RequestDeferredUsableAfterStorm()
            return
        end
        local now = GetTime()
        local inCombat = InCombatLockdown()
        
        -- Throttle UpdateUsable storms (aura edges fire SPELL_+ACTIONBAR_UPDATE_USABLE bursts).
        do
            local throttleInterval = inCombat and USABLE_COMBAT_THROTTLE or USABLE_NORMAL_THROTTLE
            local lastUpdate = lastUsableEventTime[event] or 0
            
            if (now - lastUpdate) < throttleInterval then
                -- Too soon, defer to OnUpdate batch processing
                if event == "ACTIONBAR_UPDATE_USABLE" or event == "BAG_UPDATE_DELAYED" then
                    Full.RefUsableSkipBadges = false
                elseif event == "SPELL_UPDATE_USABLE" and Full.RefUsableSkipBadges == nil then
                    -- Spell-only: LAB owns action-bar buttons; badges wait for ACTIONBAR_* or bag.
                    Full.RefUsableSkipBadges = true
                end
                Full.RefUsable = true
                Full.RefreshButtons = true
                if not Full:GetScript("OnUpdate") then Full:SetScript("OnUpdate", Full.OnUpdate) end
                return
            end
            lastUsableEventTime[event] = now
        end

        -- Flux perf: SPELL_UPDATE_USABLE alone does not need action-bar badge usable
        -- (LAB already paints bar buttons; badges refresh on ACTIONBAR_UPDATE_USABLE).
        if event == "SPELL_UPDATE_USABLE" then
            if Full.RefUsableSkipBadges == nil then
                Full.RefUsableSkipBadges = true
            end
        elseif event == "ACTIONBAR_UPDATE_USABLE" or event == "BAG_UPDATE_DELAYED" then
            Full.RefUsableSkipBadges = false
        end
        
        -- Clear visual feedback cache when leaving combat (12.0.0+), deferred one frame
        if event == "PLAYER_REGEN_ENABLED" and FluxAPICompat and FluxAPICompat.FLUX_API and FluxAPICompat.FLUX_API.hasCanAccessValue then
            local function clearRegenCaches()
                if FluxButtonUsability and FluxButtonUsability.ClearVisualFeedbackCache then
                    FluxButtonUsability:ClearVisualFeedbackCache()
                end
                if FluxButton and FluxButton.ClearCooldownUpdateCache then
                    FluxButton.ClearCooldownUpdateCache()
                end
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0, clearRegenCaches)
            else
                clearRegenCaches()
            end
        end

        if event == "UPDATE_MOUSEOVER_UNIT" then
            return
        end

        if event == "PLAYER_TARGET_CHANGED" or event == "UNIT_FACTION" then
            if FluxButtonEvents.ForceRangeRefresh then
                FluxButtonEvents.ForceRangeRefresh()
            end
            -- TARGET: range ticker handles continuous OOR; only batch usable if
            -- other usable events need it (handled below for non-range events).
            if event == "UNIT_FACTION" then
                Full.RefUsable = true
                Full.RefreshButtons = true
                if not Full:GetScript("OnUpdate") then Full:SetScript("OnUpdate", Full.OnUpdate) end
            end
            return
        end

        -- Also set flag for batched updates (runs for ALL events including BAG_UPDATE)
        Full.RefUsable = true
        Full.RefreshButtons = true
        if not Full:GetScript("OnUpdate") then Full:SetScript("OnUpdate", Full.OnUpdate) end
    end
    
    function Cooldown:OnEvent()
        -- Dirty-flag coalesce is enough (one OnUpdate batch). Do not drop events —
        -- combat throttling here skipped the cast that started the CD.
        Full.RefCooldown = true
        Full.RefreshButtons = true
        if not Full:GetScript("OnUpdate") then Full:SetScript("OnUpdate", Full.OnUpdate) end
    end
    
    function Text:OnEvent(event, unitId)
        -- Flux perf: skip per-slot bag churn during a vendor sell burst; counts
        -- are refreshed once when the burst ends (mirrors Usable:OnEvent).
        if event == "BAG_UPDATE_DELAYED"
            and FluxVendorSession and FluxVendorSession.IsBurstActive and FluxVendorSession.IsBurstActive() then
            return
        end
        if event == "BAG_UPDATE_DELAYED" then
            Full.RefText = true
            Full.RefUsable = true
            Full.RefreshButtons = true
            if not Full:GetScript("OnUpdate") then Full:SetScript("OnUpdate", Full.OnUpdate) end
            return
        end
        -- Flux perf: do not RefText on player UNIT_AURA — counts come from bag/charge
        -- events. Buff ticks were walking every ExtraButton via UpdateTextCount.
        if event == "UNIT_AURA" then
            return
        end
        Full.RefText = true
        Full.RefreshButtons = true
        if not Full:GetScript("OnUpdate") then Full:SetScript("OnUpdate", Full.OnUpdate) end
    end
    
    function Conditional:OnEvent(event, ...)
        if event == "UPDATE_MOUSEOVER_UNIT" then
            return
        end

        -- ButtonForge Classic: ignore duplicate UPDATE_SHAPESHIFT_FORM (same form index).
        if event == "UPDATE_SHAPESHIFT_FORM" then
            local form = GetShapeshiftForm and GetShapeshiftForm() or 0
            local last = FluxButtonEvents._lastShapeshiftForm
            if last ~= nil and form == last then
                return
            end
            FluxButtonEvents._lastShapeshiftForm = form
        end

        -- Druid/hybrid: primary resource swap (mana ↔ energy/rage) fires UNIT_DISPLAYPOWER
        -- and a long SPELL_UPDATE_USABLE storm. Treat like form settle.
        if event == "UNIT_DISPLAYPOWER" then
            local unit = ...
            if unit and unit ~= "player" then
                return
            end
            local ptype = UnitPowerType and UnitPowerType("player") or nil
            if ptype ~= nil and ptype == FluxButtonEvents._lastDisplayPowerType
                and FluxButtonEvents.IsFormStormActive() then
                return
            end
            FluxButtonEvents._lastDisplayPowerType = ptype
            FluxButtonEvents.BeginFormStorm(0.55)
            return
        end

        -- Form / bonus / page: open suppress window only (no RefConditional arming).
        local isFormStormDriver = (event == "UPDATE_SHAPESHIFT_FORM"
            or event == "UPDATE_BONUS_ACTIONBAR"
            or event == "ACTIONBAR_PAGE_CHANGED")
        if isFormStormDriver then
            local now = GetTime() or 0
            local untilT = FluxButtonEvents._formStormIgnoreAscUntil or 0
            -- Coalesce bonus/page repeats inside the settle window.
            if now < untilT and event ~= "UPDATE_SHAPESHIFT_FORM" then
                return
            end
            -- Nuclear: suppress window only — no TranslateMacro / EffectRefresh over ActiveButtons.
            FluxButtonEvents.BeginFormStorm(0.55)
            return
        elseif event == "ACTIONBAR_SLOT_CHANGED" then
            if FluxButtonEvents.IsFormStormActive() then
                return
            end
            -- Outside form storms: only re-arm when slot occupancy actually changed.
            local slotNum = tonumber((...))
            if slotNum and slotNum > 0 then
                local peek = _G.FluxActionBarPeekSlotOccupancyChanged
                if peek and not peek(slotNum) then
                    return
                end
            end
            -- Debounce global cache wipe — ASC can still fire in bursts without a form storm.
            local now = GetTime() or 0
            local lastInv = FluxButtonEvents._lastTranslateMacroCacheInvalidate or 0
            if (now - lastInv) >= 0.05 then
                FluxButtonEvents._lastTranslateMacroCacheInvalidate = now
                FluxButtonEvents.InvalidateAllTranslateMacroCaches()
            end
            local Coord = _G.FluxPagingCoordinator
            if Coord and Coord.BeginConditionFlipSettle then
                pcall(Coord.BeginConditionFlipSettle, slotNum)
            end
        elseif event == "UPDATE_SHAPESHIFT_COOLDOWN" then
            if FluxButtonEvents.IsFormStormActive() then
                return
            end
        end

        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
            -- Usable:OnEvent already ForceRangeRefresh on TARGET; FOCUS is Conditional-only.
            -- Defer TranslateMacro/UpdateUsable to one OnUpdate batch (no double full walk).
            Full.rangeTimer = 0
            if event == "PLAYER_FOCUS_CHANGED" and FluxButtonEvents.ForceRangeRefresh then
                FluxButtonEvents.ForceRangeRefresh()
            end
            local Coord = _G.FluxPagingCoordinator
            if Coord and Coord.BeginConditionFlipSettle then
                pcall(Coord.BeginConditionFlipSettle)
            end
        end

        -- [pet]/[nopet] Binding macros: re-resolve bar↔badge identity + Exclusive checked.
        if event == "UNIT_PET" or event == "PET_BAR_UPDATE" then
            if event == "UNIT_PET" then
                local unit = ...
                if unit and unit ~= "player" then
                    return
                end
            end
            local Coord = _G.FluxPagingCoordinator
            if Coord and Coord.BeginConditionFlipSettle then
                pcall(Coord.BeginConditionFlipSettle)
            end
            -- After TranslateMacro batch, Exclusive must discover Summon-on-badge etc.
            -- Debounce: summon fires UNIT_PET + PET_BAR_UPDATE together.
            -- Two-frame delay so OnUpdate RefConditional TranslateMacro runs first.
            if not FluxButtonEvents._petCheckedSettlePending then
                FluxButtonEvents._petCheckedSettlePending = true
                local function settlePetChecked()
                    FluxButtonEvents._petCheckedSettlePending = nil
                    local Ck = _G.FluxEffectChecked or _G.FluxBadgeCheckedDrive
                    if Ck and Ck.ApplyAllRouted then
                        pcall(Ck.ApplyAllRouted)
                    end
                end
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, function()
                        C_Timer.After(0, settlePetChecked)
                    end)
                else
                    settlePetChecked()
                end
            end
        end
        
        -- Set flags for batched OnUpdate processing (ButtonForge pattern).
        -- ButtonForge Conditional only sets RefConditional — never RefUsable. Usable is
        -- driven by SPELL/ACTIONBAR_UPDATE_USABLE; macros still get targeted UpdateUsable
        -- after TranslateMacro when RefUsable is unset (see OnUpdate RefConditional block).
        Full.RefConditional = true
        Full.RefreshButtons = true
        if event == "MODIFIER_STATE_CHANGED" then
            Full.RefConditionalFromMod = true
            Full.RefConditionalLight = false
        elseif event == "ACTIONBAR_SLOT_CHANGED" then
            -- Non-form ASC: macros only, skip texture/usable megawalk.
            Full.RefConditionalFromMod = false
            Full.RefConditionalLight = true
            Full.RefSkipTexture = true
        else
            Full.RefConditionalFromMod = false
            if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED"
                or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE"
                or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED"
                or event == "UNIT_PET" or event == "PET_BAR_UPDATE" then
                Full.RefUsable = true
            end
        end
        if not Full:GetScript("OnUpdate") then Full:SetScript("OnUpdate", Full.OnUpdate) end
    end
    
    -- Spells event handler - handles spell overrides (Smite -> Void Blast, etc.)
    function Spells:OnEvent(event)
        if event == "SPELLS_CHANGED"
            and _G.FluxSpellBindingProfile_ShouldSuppressCastEdgeRefresh
            and _G.FluxSpellBindingProfile_ShouldSuppressCastEdgeRefresh() then
            return
        end
        -- Shapeshift often emits SPELLS_CHANGED; full ActiveButtons RefreshSpell is a hitch.
        if FluxButtonEvents.IsFormStormActive and FluxButtonEvents.IsFormStormActive() then
            return
        end
        -- Defer processing to OnUpdate (ButtonForge pattern - avoids spam during spec swaps)
        Full.RefSpells = true
        Full.RefreshButtons = true
        if not Full:GetScript("OnUpdate") then Full:SetScript("OnUpdate", Full.OnUpdate) end
    end
    
    -- Register events
    SafeRegisterEvent(Checked, "CURRENT_SPELL_CAST_CHANGED")
    SafeRegisterEvent(Checked, "ACTIONBAR_UPDATE_STATE")
    SafeRegisterEvent(Checked, "PLAYER_ENTER_COMBAT")
    SafeRegisterEvent(Checked, "PLAYER_LEAVE_COMBAT")
    SafeRegisterEvent(Checked, "START_AUTOREPEAT_SPELL")
    SafeRegisterEvent(Checked, "STOP_AUTOREPEAT_SPELL")
    SafeRegisterEvent(Checked, "COMPANION_UPDATE")
    SafeRegisterEvent(Checked, "PET_BATTLE_PET_CHANGED")
    SafeRegisterUnitEvent(Checked, "UNIT_SPELLCAST_START", "player")
    SafeRegisterUnitEvent(Checked, "UNIT_SPELLCAST_STOP", "player")
    SafeRegisterUnitEvent(Checked, "UNIT_SPELLCAST_SUCCEEDED", "player")
    SafeRegisterUnitEvent(Checked, "UNIT_SPELLCAST_FAILED", "player")
    SafeRegisterUnitEvent(Checked, "UNIT_SPELLCAST_INTERRUPTED", "player")
    SafeRegisterEvent(Checked, "TRADE_SKILL_SHOW")
    SafeRegisterEvent(Checked, "TRADE_SKILL_CLOSE")
    -- Bag refresh is handled by FluxInv (EngineBagRefresh).
    
    SafeRegisterEvent(Equipped, "PLAYER_EQUIPMENT_CHANGED")
    
    SafeRegisterEvent(Usable, "SPELL_UPDATE_USABLE")
    SafeRegisterEvent(Usable, "ACTIONBAR_UPDATE_USABLE")
    SafeRegisterEvent(Usable, "PLAYER_REGEN_ENABLED")
    SafeRegisterEvent(Usable, "PLAYER_REGEN_DISABLED")
    SafeRegisterEvent(Usable, "ZONE_CHANGED")
    SafeRegisterEvent(Usable, "ZONE_CHANGED_INDOORS")
    SafeRegisterEvent(Usable, "ZONE_CHANGED_NEW_AREA")
    -- No BAG_UPDATE_DELAYED: EngineBagRefresh already sets RefUsable, and it
    -- gates on changeKind so a stack change does not force a button rebuild.
    SafeRegisterEvent(Usable, "TOYS_UPDATED")
    
    SafeRegisterEvent(Cooldown, "SPELL_UPDATE_COOLDOWN")
    SafeRegisterEvent(Cooldown, "ACTIONBAR_UPDATE_COOLDOWN")
    SafeRegisterEvent(Cooldown, "SPELL_UPDATE_CHARGES")
    SafeRegisterEvent(Cooldown, "BAG_UPDATE_COOLDOWN")
    SafeRegisterEvent(Cooldown, "UPDATE_SHAPESHIFT_COOLDOWN")
    
    -- Bag count refresh is handled by FluxInv (EngineBagRefresh), so no
    -- BAG_UPDATE_DELAYED here — it ran the same megawalk a second time.
    -- UNIT_AURA intentionally not registered: count text is bag/charge driven.
    SafeRegisterEvent(Text, "SPELL_UPDATE_CHARGES")
    SafeRegisterEvent(Text, "BAG_UPDATE_COOLDOWN")
    SafeRegisterUnitEvent(Text, "UNIT_SPELLCAST_SUCCEEDED", "player")
    SafeRegisterEvent(Text, "TRADE_SKILL_SHOW")
    SafeRegisterEvent(Text, "TRADE_SKILL_CLOSE")
    
    SafeRegisterEvent(Conditional, "MODIFIER_STATE_CHANGED")
    SafeRegisterEvent(Conditional, "PLAYER_TARGET_CHANGED")
    SafeRegisterEvent(Conditional, "PLAYER_FOCUS_CHANGED")
    SafeRegisterEvent(Conditional, "ACTIONBAR_PAGE_CHANGED")
    SafeRegisterEvent(Conditional, "UPDATE_BONUS_ACTIONBAR")
    SafeRegisterEvent(Conditional, "PLAYER_REGEN_ENABLED")
    SafeRegisterEvent(Conditional, "PLAYER_REGEN_DISABLED")
    SafeRegisterUnitEvent(Conditional, "UNIT_SPELLCAST_CHANNEL_START", "player")
    SafeRegisterUnitEvent(Conditional, "UNIT_SPELLCAST_CHANNEL_STOP", "player")
    SafeRegisterEvent(Conditional, "ACTIVE_TALENT_GROUP_CHANGED")
    SafeRegisterEvent(Conditional, "UPDATE_SHAPESHIFT_COOLDOWN")
    -- ButtonForge: stance/form: — Classic also debounces duplicate form index.
    SafeRegisterEvent(Conditional, "UPDATE_SHAPESHIFT_FORM")
    SafeRegisterEvent(Conditional, "UPDATE_STEALTH")
    SafeRegisterEvent(Conditional, "UNIT_ENTERED_VEHICLE")
    SafeRegisterEvent(Conditional, "UNIT_EXITED_VEHICLE")
    SafeRegisterEvent(Conditional, "MINIMAP_UPDATE_ZOOM")
    SafeRegisterEvent(Conditional, "ACTIONBAR_SLOT_CHANGED")
    -- Binding [pet]/[nopet] macros: bar↔badge TranslateMacro + Exclusive checked re-home.
    SafeRegisterUnitEvent(Conditional, "UNIT_PET", "player")
    SafeRegisterEvent(Conditional, "PET_BAR_UPDATE")
    -- Druid/hybrid mana↔energy/rage: coalesce ExtraButton usable megawalks.
    SafeRegisterUnitEvent(Conditional, "UNIT_DISPLAYPOWER", "player")

    if FluxMouseoverRefresh and FluxMouseoverRefresh.Register then
        FluxMouseoverRefresh.Register("ExtraButtons", function()
            FluxButtonEvents.FlushMouseoverUsable()
        end)
    end
    
    -- Spell override events (Smite -> Void Blast, talent changes, etc.)
    SafeRegisterEvent(Spells, "SPELLS_CHANGED")
    SafeRegisterEvent(Spells, "LEARNED_SPELL_IN_TAB")
    SafeRegisterEvent(Spells, "LEARNED_SPELL_IN_SKILL_LINE")

    local function OnDispatcherBagRefresh(ctx)
        if not ctx then
            return
        end
        if ctx.equipmentOnly then
            return
        end
        if ctx.sessionClose and ctx.changeKind == "countOnly" then
            Full.RefText = true
            Full.RefUsable = true
            if not Full:GetScript("OnUpdate") then
                Full:SetScript("OnUpdate", Full.OnUpdate)
            end
            return
        end
        -- Stack size / same unique IDs: count + usable only (loot/craft storms).
        if ctx.changeKind == "countOnly" and not ctx.force
            and not ctx.fromItemData and not ctx.itemDataItemID then
            Full.RefText = true
            Full.RefUsable = true
            if not Full:GetScript("OnUpdate") then
                Full:SetScript("OnUpdate", Full.OnUpdate)
            end
            return
        end
        local inv = _G.FluxInv
        if inv and inv.IsVendorSettling and inv.IsVendorSettling() then
            if ctx.changeKind ~= "countOnly" then
                return
            end
        end
        local VS = FluxVendorSession
        local vendorHeavy = (VS and VS.IsBurstActive and VS.IsBurstActive())
            or (VS and VS.IsOpen and VS.IsOpen())
            or _G.FRAME_THAT_OPENED_BAGS == "MerchantFrame"
        if vendorHeavy and not ctx.coordinated and not ctx.force then
            Full.RefText = true
            Full.RefUsable = true
            if not Full:GetScript("OnUpdate") then
                Full:SetScript("OnUpdate", Full.OnUpdate)
            end
            if ctx.changeKind ~= "countOnly" then
                return
            end
        end
        if ctx.vendorActive and not ctx.coordinated and not ctx.force
            and ctx.changeKind ~= "countOnly" then
            return
        end
        if FluxVendorSession and FluxVendorSession.IsBurstActive and FluxVendorSession.IsBurstActive() then
            if ctx.changeKind ~= "countOnly" then
                return
            end
        end
        Full.RefreshButtons = true
        Full.RefText = true
        Full.RefUsable = true
        if ctx.changeKind == "identityChanged" or ctx.changeKind == "unknown" or ctx.force
            or ctx.fromItemData or ctx.itemDataItemID then
            Full.RefChecked = true
        end
        if not Full:GetScript("OnUpdate") then
            Full:SetScript("OnUpdate", Full.OnUpdate)
        end
    end

    -- Prefer FluxInv unified inventory listeners (never walk bags here).
    if _G.FluxInv and _G.FluxInv.RegisterListener then
        _G.FluxInv.RegisterListener("EngineBagRefresh", OnDispatcherBagRefresh, {
            tier = "instant",
            regions = { "bags", "equip" },
            sync = true,
        })
    elseif FluxBagChangeDispatcher and FluxBagChangeDispatcher.RegisterCountListener then
        FluxBagChangeDispatcher.RegisterCountListener("EngineBagRefresh", OnDispatcherBagRefresh)
    elseif FluxBagChangeDispatcher and FluxBagChangeDispatcher.Register then
        FluxBagChangeDispatcher.Register("EngineBagRefresh", OnDispatcherBagRefresh, {
            tier = "instant",
        })
    end
    
    -- Set up event handlers
    Checked:SetScript("OnEvent", Checked.OnEvent)
    Equipped:SetScript("OnEvent", Equipped.OnEvent)
    Usable:SetScript("OnEvent", Usable.OnEvent)
    Cooldown:SetScript("OnEvent", Cooldown.OnEvent)
    Text:SetScript("OnEvent", Text.OnEvent)
    Conditional:SetScript("OnEvent", Conditional.OnEvent)
    Spells:SetScript("OnEvent", Spells.OnEvent)
    
    -- Range checking is now integrated into Usability system
    -- PLAYER_TARGET_CHANGED triggers usability update which includes range check
    SafeRegisterEvent(Usable, "PLAYER_TARGET_CHANGED")
    SafeRegisterEvent(Usable, "UNIT_FACTION")
end

-- Button registration functions
function FluxButtonEvents.InvalidateAllTranslateMacroCaches()
    for i = 1, #FluxButtonEvents.ActiveButtons do
        local button = FluxButtonEvents.ActiveButtons[i]
        if button and button.InvalidateTranslateMacroCache then
            button:InvalidateTranslateMacroCache()
        end
    end
end

function FluxButtonEvents.RegisterButton(button)
    if IsLegacy() then
        if _G.FluxButtonLegacySystem then
            _G.FluxButtonLegacySystem.RegisterButton(button)
        end
    else
        if button then
            for i = 1, #FluxButtonEvents.ActiveButtons do
                if FluxButtonEvents.ActiveButtons[i] == button then
                    if FluxButtonCore and FluxButtonCore.AddActiveButton then
                        FluxButtonCore.AddActiveButton(button)
                    end
                    FluxButtonEvents.RefreshRangeButtonMembership(button)
                    return
                end
            end
            table.insert(FluxButtonEvents.ActiveButtons, button)
            if FluxButtonCore and FluxButtonCore.AddActiveButton then
                FluxButtonCore.AddActiveButton(button)
            end
            FluxButtonEvents.RefreshRangeButtonMembership(button)
        end
    end
end

-- Badge button registration (includes range membership for Binding / hovercast OOR)
FluxButtonEvents.badgeButtons = FluxButtonEvents.badgeButtons or {}

function FluxButtonEvents.RegisterBadgeButton(badge, column)
    if not badge then return end
    for i = 1, #FluxButtonEvents.badgeButtons do
        if FluxButtonEvents.badgeButtons[i] == badge then
            if FluxButtonEvents.RefreshRangeButtonMembership then
                FluxButtonEvents.RefreshRangeButtonMembership(badge)
            end
            return
        end
    end
    FluxButtonEvents.badgeButtons[#FluxButtonEvents.badgeButtons + 1] = badge
    if FluxButtonEvents.RefreshRangeButtonMembership then
        FluxButtonEvents.RefreshRangeButtonMembership(badge)
    end
end

function FluxButtonEvents.UnregisterBadgeButton(badge)
    if not badge then return end
    for i = #FluxButtonEvents.badgeButtons, 1, -1 do
        if FluxButtonEvents.badgeButtons[i] == badge then
            table.remove(FluxButtonEvents.badgeButtons, i)
            break
        end
    end
    if FluxButtonEvents.rangeButtons then
        FluxButtonEvents.rangeButtons[badge] = nil
    end
    if FluxButtonEvents.mouseoverMacroButtons then
        FluxButtonEvents.mouseoverMacroButtons[badge] = nil
    end
end

function FluxButtonEvents.UnregisterButton(button)
    if IsLegacy() then
        if _G.FluxButtonLegacySystem then
            _G.FluxButtonLegacySystem.UnregisterButton(button)
        end
    else
        if button then
            for i = #FluxButtonEvents.ActiveButtons, 1, -1 do
                if FluxButtonEvents.ActiveButtons[i] == button then
                    table.remove(FluxButtonEvents.ActiveButtons, i)
                    if FluxButtonEvents.rangeButtons then
                        FluxButtonEvents.rangeButtons[button] = nil
                    end
                    if FluxButtonEvents.mouseoverMacroButtons then
                        FluxButtonEvents.mouseoverMacroButtons[button] = nil
                    end
                    break
                end
            end
            if FluxButtonCore and FluxButtonCore.RemoveActiveButton then
                FluxButtonCore.RemoveActiveButton(button)
            end
        end
    end
end

-- Trigger checked state update for all buttons
function FluxButtonEvents.RequestCheckedUpdate()
    if IsLegacy() then
        if _G.FluxButtonLegacySystem and _G.FluxButtonLegacySystem.Request then
            _G.FluxButtonLegacySystem.Request("RefChecked")
        end
    else
        if Full then
            Full.RefChecked = true
            Full.RefreshButtons = true
            if not Full:GetScript("OnUpdate") then
                Full:SetScript("OnUpdate", Full.OnUpdate)
            end
        end
    end
end

-- Refresh all spell buttons (for spell overrides like Smite -> Void Blast)
function FluxButtonEvents.RefreshSpells()
    if IsLegacy() then
        if _G.FluxButtonLegacySystem and _G.FluxButtonLegacySystem.Request then
            _G.FluxButtonLegacySystem.Request("RefSpells")
        end
    else
        for i = 1, #FluxButtonEvents.ActiveButtons do
            local button = FluxButtonEvents.ActiveButtons[i]
            if button and button.RefreshSpell then
                button:RefreshSpell()
            end
        end
    end
end

-- Initialize the event system
function FluxButtonEvents.Initialize()
    if IsLegacy() then
        if _G.FluxButtonLegacySystem then
            _G.FluxButtonLegacySystem.Initialize()
        end
    end
end

-- Force a full refresh for all buttons
function FluxButtonEvents.ForceRefresh()
    if IsLegacy() then
        if _G.FluxButtonLegacySystem and _G.FluxButtonLegacySystem.Request then
            _G.FluxButtonLegacySystem.Request("RefFull")
        end
    else
        if Full then
            Full.RefreshButtons = true
            Full.RefChecked = true
            Full.RefEquipped = true
            Full.RefUsable = true
            Full.RefCooldown = true
            Full.RefText = true
            Full.RefConditional = true
            if not Full:GetScript("OnUpdate") then
                Full:SetScript("OnUpdate", Full.OnUpdate)
            end
        end
    end
end

--- Re-arm mod-conditional TranslateMacro after paging latch clears.
function FluxButtonEvents.FlushDeferredModConditional()
    if IsLegacy() then return end
    if not Full then return end
    if not Full._fluxDeferredModConditional and not Full.RefConditional then
        return
    end
    Full._fluxDeferredModConditional = nil
    Full.RefConditional = true
    Full.RefConditionalFromMod = true
    Full.RefreshButtons = true
    if not Full:GetScript("OnUpdate") then
        Full:SetScript("OnUpdate", Full.OnUpdate)
    end
end

-- ============================================================================
-- UPDATE_MACROS handling
-- ----------------------------------------------------------------------------
-- When the user edits a macro in /macro the secure attribute already points
-- at the right index, but the cached body, icon, ShowTooltip flag, and even
-- the index itself (after a reorder/rename) can be stale. Mirror ButtonForge's
-- RefreshMacro pattern: walk all active macro buttons, re-resolve by name,
-- and re-run TranslateMacro so icon and tooltip follow the new body.
-- Defer the SetAction part until combat ends, since SetAction touches secure
-- attributes.
-- ============================================================================

local MacroEvents = CreateFrame("Frame")
local pendingMacroRefresh = false

local function ResolveMacroIndexByName(name)
    if not name or name == "" or not GetMacroIndexByName then return nil end
    local idx = GetMacroIndexByName(name)
    if idx and idx > 0 then return idx end
    return nil
end

local function GetActiveButtonList()
    if IsLegacy() then
        if _G.FluxButtonLegacySystem then
            return _G.FluxButtonLegacySystem.ActiveButtons
        end
        return nil
    end
    return FluxButtonEvents.ActiveButtons
end

local function RefreshAllMacroButtons()
    local buttons = GetActiveButtonList()
    if not buttons then return end

    local inCombat = InCombatLockdown()
    local stillPending = false

    for i = 1, #buttons do
        local button = buttons[i]
        if button and button.ActionType == "macro" then
            local newIndex
            if button.MacroName then
                newIndex = ResolveMacroIndexByName(button.MacroName)
            end

            -- If the macro was renamed/deleted/reordered, rewire the secure
            -- binding via SetAction. SetAction touches secure attributes, so
            -- defer it past combat.
            if newIndex and newIndex ~= button.MacroIndex then
                if inCombat then
                    stillPending = true
                else
                    if button.SetAction then
                        button:SetAction("macro", newIndex)
                    end
                end
            else
                -- Same index (or no name/inline macrotext): just refresh the
                -- cached body, icon, ShowTooltip, and HideMacroName.
                if button.TranslateMacro then
                    button:TranslateMacro()
                end
            end
        end
    end

    pendingMacroRefresh = stillPending
end

MacroEvents:SetScript("OnEvent", function(self, event)
    if event == "UPDATE_MACROS" or event == "PLAYER_LOGIN" then
        RefreshAllMacroButtons()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingMacroRefresh then
            RefreshAllMacroButtons()
        end
    end
end)

SafeRegisterEvent(MacroEvents, "UPDATE_MACROS")
SafeRegisterEvent(MacroEvents, "PLAYER_LOGIN")
SafeRegisterEvent(MacroEvents, "PLAYER_REGEN_ENABLED")

FluxButtonEvents.RefreshAllMacroButtons = RefreshAllMacroButtons

-- Export the module
_G.FluxButtonEvents = FluxButtonEvents
