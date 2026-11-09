--[[
    FluxVendorRepairUI.lua
    Native repair-button sizing/toggles for FluxVendorAutoMerchantUI.
    Split out to stay under Lua's per-chunk local limit.
]]

FluxVendorRepairUI = FluxVendorRepairUI or {}
local R = FluxVendorRepairUI

local deps

local MIN_NATIVE_REPAIR_BUTTON_SIZE = 32
local CLASSIC_GUILD_BUTTON_SIZE = 36
local MERCHANT_BUTTON_SIZE = 36
local CLASSIC_ICON_MIN_SIZE = 24
local CLASSIC_ICON_EDGE_INSET = 1

function R.Register(dependencies)
    deps = dependencies
end

local function D()
    return deps or {}
end

local function RefreshAutoTogglePosition(hostButton)
    local toggle = hostButton and hostButton.fluxAutoToggle
    if not toggle or not hostButton:IsShown() then
        return
    end
    toggle:ClearAllPoints()
    toggle:SetPoint("TOPLEFT", hostButton, "TOPLEFT", -3, 3)
    if toggle:GetParent() == hostButton then
        toggle:SetFrameLevel(hostButton:GetFrameLevel() + 2)
    end
end

local function GetNativeRepairButtonIcon(btn)
    if not btn then
        return nil
    end
    if btn.Icon then
        return btn.Icon
    end
    if btn == _G.MerchantRepairAllButton then
        return _G.MerchantRepairAllIcon
    end
    if btn == _G.MerchantGuildBankRepairButton then
        return _G.MerchantGuildBankRepairButtonIcon
    end
    return nil
end

function R.NormalizeButton(btn)
    local d = D()
    if not btn or not btn.IsShown or not btn:IsShown() then
        return false
    end

    local useClassic = d.useClassicMerchantButtonStyle and d.useClassicMerchantButtonStyle()
    local expectedSize = useClassic and CLASSIC_GUILD_BUTTON_SIZE or MERCHANT_BUTTON_SIZE
    local w, h = btn:GetSize()
    if not w or not h or w < MIN_NATIVE_REPAIR_BUTTON_SIZE or h < MIN_NATIVE_REPAIR_BUTTON_SIZE then
        btn:SetSize(expectedSize, expectedSize)
        w, h = expectedSize, expectedSize
    end

    local icon = GetNativeRepairButtonIcon(btn)
    if not icon then
        return true
    end

    icon:ClearAllPoints()
    if useClassic then
        local iconSize = math.max(CLASSIC_ICON_MIN_SIZE, (w or expectedSize) - (CLASSIC_ICON_EDGE_INSET * 2))
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    else
        icon:SetAllPoints(btn)
    end
    icon:Show()
    return true
end

function R.NeedsLayout()
    local repairAll = _G.MerchantRepairAllButton
    if repairAll and repairAll:IsShown() then
        local w = repairAll:GetSize()
        if not w or w < MIN_NATIVE_REPAIR_BUTTON_SIZE then
            return true
        end
    end
    local guildRepair = _G.MerchantGuildBankRepairButton
    if guildRepair and guildRepair:IsShown() then
        local w = guildRepair:GetSize()
        if not w or w < MIN_NATIVE_REPAIR_BUTTON_SIZE then
            return true
        end
        if not guildRepair.fluxAutoToggle then
            return true
        end
    end
    return false
end

function R.EnsureTogglesReady()
    local d = D()
    local toggles = d.toggles
    local attachAutoToggle = d.attachAutoToggle
    local getSettings = d.getSettings
    local fv = d.fv
    if not attachAutoToggle or not getSettings or not toggles then
        return
    end

    local repairAll = _G.MerchantRepairAllButton
    if repairAll and not repairAll.fluxAutoToggle then
        attachAutoToggle(repairAll, {
            get = function()
                local s = getSettings()
                return s and s.autoRepair
            end,
            set = function(val)
                local s = getSettings()
                if s then
                    s.autoRepair = val and true or false
                end
                if val and fv and fv.TriggerAutoRepair and MerchantFrame and MerchantFrame:IsShown() then
                    fv.TriggerAutoRepair()
                end
            end,
            tooltipTitle = "Auto Repair",
            tooltipBody = "Automatically repair all gear when you visit a repair-capable merchant.",
        })
        toggles.repairAll = repairAll
    end

    local guildRepair = _G.MerchantGuildBankRepairButton
    if guildRepair and not guildRepair.fluxAutoToggle then
        attachAutoToggle(guildRepair, {
            get = function()
                local s = getSettings()
                return s and (s.repairPriority or "personal") ~= "personal"
            end,
            set = function(val)
                local s = getSettings()
                if s then
                    s.repairPriority = val and "guild" or "personal"
                end
            end,
            tooltipTitle = "Guild bank first",
            tooltipBody = "When auto repair runs, prefer guild bank over personal gold. Falls back if needed.",
        })
        toggles.guildRepair = guildRepair
    end
end

function R.UpdateToggles(repairClusterVisible)
    local d = D()
    local toggles = d.toggles or {}
    local refreshAutoToggle = d.refreshAutoToggle

    R.EnsureTogglesReady()

    local repairAll = toggles.repairAll or _G.MerchantRepairAllButton
    if repairAll and repairAll.fluxAutoToggle then
        if repairClusterVisible and repairAll:IsShown() then
            RefreshAutoTogglePosition(repairAll)
            repairAll.fluxAutoToggle:Show()
            if refreshAutoToggle then
                refreshAutoToggle(repairAll)
            end
        else
            repairAll.fluxAutoToggle:Hide()
        end
    end

    local guildRepair = toggles.guildRepair or _G.MerchantGuildBankRepairButton
    if guildRepair and guildRepair.fluxAutoToggle then
        if guildRepair:IsShown() then
            RefreshAutoTogglePosition(guildRepair)
            guildRepair.fluxAutoToggle:Show()
            if refreshAutoToggle then
                refreshAutoToggle(guildRepair)
            end
        else
            guildRepair.fluxAutoToggle:Hide()
        end
    end
end

function R.EnsureClusterReady(repairClusterVisible)
    local d = D()
    if not repairClusterVisible then
        return
    end

    R.NormalizeButton(_G.MerchantRepairAllButton)
    if _G.MerchantGuildBankRepairButton and _G.MerchantGuildBankRepairButton:IsShown() then
        R.NormalizeButton(_G.MerchantGuildBankRepairButton)
    end

    if d.usesClassicGuildRepairClusterLayout
        and d.usesClassicGuildRepairClusterLayout(repairClusterVisible)
        and d.applyClassicGuildRepairClusterLayout then
        d.applyClassicGuildRepairClusterLayout(repairClusterVisible)
    end

    local toggles = d.toggles or {}
    for _, host in ipairs({
        toggles.repairAll or _G.MerchantRepairAllButton,
        toggles.guildRepair or _G.MerchantGuildBankRepairButton,
    }) do
        if host and host:IsShown() and host.fluxAutoToggle then
            RefreshAutoTogglePosition(host)
            host.fluxAutoToggle:Show()
            if d.refreshAutoToggle then
                d.refreshAutoToggle(host)
            end
        end
    end
end

function R.CancelRetry()
    local uiState = D().uiState
    if not uiState then
        return
    end
    uiState.nativeRepairLayoutRetryGen = (uiState.nativeRepairLayoutRetryGen or 0) + 1
    if uiState.nativeRepairLayoutTimer then
        pcall(function()
            uiState.nativeRepairLayoutTimer:Cancel()
        end)
        uiState.nativeRepairLayoutTimer = nil
    end
end

function R.ScheduleRetry()
    local d = D()
    local isBuyTabActive = d.isMerchantBuyTabActive
    local getRepairClusterVisible = d.getRepairClusterVisible
    local isGuildRepairShown = d.isGuildRepairButtonShown

    if not MerchantFrame or not MerchantFrame:IsShown() or not (isBuyTabActive and isBuyTabActive()) then
        return
    end
    if not (getRepairClusterVisible and getRepairClusterVisible())
        and not (isGuildRepairShown and isGuildRepairShown()) then
        return
    end

    R.CancelRetry()
    local uiState = d.uiState
    if not uiState then
        return
    end

    local gen = uiState.nativeRepairLayoutRetryGen
    local delays = { 0, 0.05, 0.15 }

    local function runAttempt(index)
        if gen ~= uiState.nativeRepairLayoutRetryGen then
            return
        end
        if not MerchantFrame or not MerchantFrame:IsShown() then
            return
        end
        local repairClusterVisible = getRepairClusterVisible and getRepairClusterVisible() or false
        R.EnsureTogglesReady()
        R.EnsureClusterReady(repairClusterVisible)
        R.UpdateToggles(repairClusterVisible)
        if index < #delays and R.NeedsLayout() then
            local After = (C_Timer and C_Timer.After) or function(_, fn) fn() end
            uiState.nativeRepairLayoutTimer = nil
            After(delays[index + 1], function()
                runAttempt(index + 1)
            end)
        end
    end

    local After = (C_Timer and C_Timer.After) or function(_, fn) fn() end
    After(delays[1], function()
        runAttempt(1)
    end)
end

_G.FluxVendorRepairUI = R
