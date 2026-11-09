-- FluxBaganator_CategoryVendorBlock.lua
-- Blocks Baganator category bulk vendor/transfer on Flux respec profile / gear preset categories.

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat

local EQUIPMENT_SETS_SOURCE = "default_auto_equipment_sets"

local VIEW_FRAME_PREFIXES = {
    "Baganator_SingleViewBackpackViewFrame",
    "Baganator_CategoryViewBackpackViewFrame",
    "Baganator_SingleViewBankViewFrame",
    "Baganator_CategoryViewBankViewFrame",
}

function Compat.FilterProtectedVendorMatches(matches)
    if type(matches) ~= "table" then
        return matches
    end
    local lock = _G.FluxRespec and _G.FluxRespec.GearSetLock
    if not lock or not lock.IsSlotProtected then
        return matches
    end
    local filtered = {}
    for i = 1, #matches do
        local item = matches[i]
        if item and item.bagID and item.slotID and lock.IsSlotProtected(item.bagID, item.slotID) then
            -- skip protected gear-set slots
        else
            filtered[#filtered + 1] = item
        end
    end
    return filtered
end

local function StripCategoryLabel(text)
    if not text or text == "" then
        return nil
    end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("%s*%(%d+%)%s*$", "")
    return text:match("^%s*(.-)%s*$")
end

local function IsFluxRespecCategoryButton(self)
    if not self then
        return false
    end
    if self.sourceKey and Compat.IsFluxRespecCategorySourceKey and Compat.IsFluxRespecCategorySourceKey(self.sourceKey) then
        return true
    end
    if self.source ~= EQUIPMENT_SETS_SOURCE then
        return false
    end
    local setName = StripCategoryLabel(self.GetText and self:GetText())
    return Compat.IsFluxManagedSetName and Compat.IsFluxManagedSetName(setName)
end

local function IsMerchantTransferContext()
    if C_PlayerInteractionManager and C_PlayerInteractionManager.IsInteractingWithNpcOfType
        and Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Merchant then
        local ok, interacting = pcall(
            C_PlayerInteractionManager.IsInteractingWithNpcOfType,
            Enum.PlayerInteractionType.Merchant
        )
        if ok and interacting then
            return true
        end
    end
    return MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown()
end

local function ShowFluxCategoryTooltip(self)
    if not self or not GameTooltip then
        return
    end
    if self.GetFontString and self:GetFontString():IsTruncated() then
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(self:GetText())
        GameTooltip:Show()
    else
        GameTooltip:Hide()
    end
end

local function WrapViewTransfer(view)
    if not view or view._fluxViewTransferWrapped then
        return
    end
    view._fluxViewTransferWrapped = true

    if view.RunAction then
        local origRunAction = view.RunAction
        view.RunAction = function(self, action, getItems)
            local function filteredAction(matches, ...)
                if IsMerchantTransferContext() then
                    matches = Compat.FilterProtectedVendorMatches(matches or {})
                end
                return action(matches, ...)
            end
            return origRunAction(self, filteredAction, getItems)
        end
    end

    if view.Transfer then
        local origTransfer = view.Transfer
        view.Transfer = function(self, force, getItems)
            if force and type(getItems) == "function" then
                local wrappedGetItems = function()
                    return Compat.FilterProtectedVendorMatches(getItems() or {})
                end
                return origTransfer(self, force, wrappedGetItems)
            end
            return origTransfer(self, force, getItems)
        end
    end

    if view.TransferCategory then
        local origTransferCategory = view.TransferCategory
        view.TransferCategory = function(self, sourceKey)
            if Compat.IsFluxRespecCategorySourceKey and Compat.IsFluxRespecCategorySourceKey(sourceKey) then
                return
            end
            return origTransferCategory(self, sourceKey)
        end
    end
end

local function InstallCategoryMixinHooks()
    local mixin = _G.BaganatorCategoryViewsCategoryButtonMixin
    if not mixin or Compat._categoryMixinHooksInstalled then
        return mixin ~= nil
    end
    Compat._categoryMixinHooksInstalled = true

    local origOnClick = mixin.OnClick
    mixin.OnClick = function(self, mouseButton)
        if mouseButton == "RightButton" and IsFluxRespecCategoryButton(self) then
            return
        end
        if origOnClick then
            return origOnClick(self, mouseButton)
        end
    end

    local origOnEnter = mixin.OnEnter
    mixin.OnEnter = function(self)
        if IsFluxRespecCategoryButton(self) then
            if SetCursor then
                SetCursor(nil)
            end
            ShowFluxCategoryTooltip(self)
            return
        end
        if origOnEnter then
            return origOnEnter(self)
        end
    end

    local origOnLeave = mixin.OnLeave
    mixin.OnLeave = function(self)
        if IsFluxRespecCategoryButton(self) then
            if SetCursor then
                SetCursor(nil)
            end
            if GameTooltip and GameTooltip.Hide then
                GameTooltip:Hide()
            end
            return
        end
        if origOnLeave then
            return origOnLeave(self)
        end
    end

    return true
end

local function ForEachBaganatorViewFrame(callback)
    if type(callback) ~= "function" then
        return
    end

    local seen = {}
    local function visit(view)
        if not view or seen[view] then
            return
        end
        seen[view] = true
        callback(view)
        if view.Character then
            visit(view.Character)
        end
        if view.Warband then
            visit(view.Warband)
        end
    end

    for i = 1, 2 do
        for p = 1, #VIEW_FRAME_PREFIXES do
            visit(_G[VIEW_FRAME_PREFIXES[p] .. i])
        end
    end

    if Compat.ForEachVisibleBaganatorView then
        Compat.ForEachVisibleBaganatorView(visit)
    end
end

local function WrapExistingViews()
    ForEachBaganatorViewFrame(WrapViewTransfer)
end

function Compat.WrapExistingBaganatorViews()
    WrapExistingViews()
end

function Compat.RefreshFluxCategoryLabels()
    -- Category labels use the shared mixin hooks; nothing extra to refresh.
end

function Compat.InitCategoryVendorBlock()
    if Compat._categoryVendorBlockInitialized then
        return
    end

    local hookedCategoryButton = InstallCategoryMixinHooks()

    if not hookedCategoryButton and not _G.BaganatorCategoryViewsCategoryButtonMixin then
        if Compat._categoryVendorBlockRetryScheduled or not C_Timer or not C_Timer.After then
            return
        end
        Compat._categoryVendorBlockRetryScheduled = true
        C_Timer.After(0, function()
            Compat._categoryVendorBlockRetryScheduled = false
            Compat.InitCategoryVendorBlock()
        end)
        return
    end

    Compat._categoryVendorBlockInitialized = true
    WrapExistingViews()

    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if registry and registry.RegisterCallback then
        registry:RegisterCallback("BagShow", WrapExistingViews)
        registry:RegisterCallback("BackpackFrameChanged", WrapExistingViews)
        registry:RegisterCallback("BankViewChanged", WrapExistingViews)
        -- Skip ViewComplete: wraps are idempotent and BagShow/BankViewChanged cover new views.
    end
end
