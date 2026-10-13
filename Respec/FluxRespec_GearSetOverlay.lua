-- FluxRespec_GearSetOverlay.lua
-- Shield overlay on default Blizzard bag/bank buttons for Flux Respec saved gear.

if _G.FluxUI_UsesAlternativeBagUI and _G.FluxUI_UsesAlternativeBagUI() then
    return
end

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.GearSetOverlay = R.GearSetOverlay or {}
local GearOverlay = R.GearSetOverlay

local SHIELD_TEXTURE = "Interface/AddOns/_FluxUI/Assets/equipment-set-shield"
local SHIELD_FALLBACK = "Interface/PaperDollInfoFrame/UI-GearManager-ItemLevel"
local SHIELD_SIZE = 15
local SHIELD_OFFSET_X = 2
local SHIELD_OFFSET_Y = 2

local Shields = {}
local lastPainted = {}
local showGearSetShield = true
local registered = false

local function Overlay()
    return _G.FluxJunkOverlay
end

local function GetContainerItemID(bag, slot)
    local inv = R.Inv
    if inv and inv.GetItemID then
        return inv.GetItemID(bag, slot)
    end
    local compat = R.Compat
    if compat and compat.GetContainerItemID then
        return compat.GetContainerItemID(bag, slot)
    end
    if _G.C_Container and _G.C_Container.GetContainerItemID then
        return _G.C_Container.GetContainerItemID(bag, slot)
    end
    if _G.GetContainerItemID then
        return _G.GetContainerItemID(bag, slot)
    end
end

local function ResolveShieldTexture()
    local tex = SHIELD_TEXTURE
    if tex and tex ~= "" then
        return tex
    end
    return SHIELD_FALLBACK
end

local function ApplyShieldLayout(shield, button)
    shield:SetSize(SHIELD_SIZE, SHIELD_SIZE)
    shield:ClearAllPoints()
    shield:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", SHIELD_OFFSET_X, SHIELD_OFFSET_Y)
end

local function NewShield(button)
    local shield = button:CreateTexture(nil, "ARTWORK", nil, 1)
    shield:SetTexture(ResolveShieldTexture())
    ApplyShieldLayout(shield, button)
    Shields[button] = shield
    return shield
end

local function PruneShield(button)
    local shield = Shields[button]
    if shield then
        shield:Hide()
    end
    local lock = GetGearSetLock()
    if lock and lock.HideItemButtonClickGuard then
        lock.HideItemButtonClickGuard(button)
    end
    lastPainted[button] = nil
end

local function GetGearSetLock()
    return R.GearSetLock
end

local function ForwardBagButtonTooltip(button)
    if not button then
        return
    end
    if button.UpdateTooltip then
        button:UpdateTooltip()
        return
    end
    if _G.ContainerFrameItemButton_OnEnter then
        _G.ContainerFrameItemButton_OnEnter(button)
        return
    end
    local onEnter = button:GetScript("OnEnter")
    if onEnter then
        onEnter(button)
    end
end

local function ForwardBagButtonTooltipHide(button)
    if button and button.UpdateTooltip then
        button:UpdateTooltip()
    elseif _G.ContainerFrameItemButton_OnLeave then
        _G.ContainerFrameItemButton_OnLeave(button)
    elseif GameTooltip_Hide then
        GameTooltip_Hide()
    end
end

local function UpdateClickGuard(button, bag, slot)
    local lock = GetGearSetLock()
    if not lock or not lock.UpdateItemButtonClickGuard then
        return
    end
    lock.UpdateItemButtonClickGuard(button, bag, slot, {
        onEnter = ForwardBagButtonTooltip,
        onLeave = ForwardBagButtonTooltipHide,
    })
end

local function PaintShield(button, bag, slot)
    if not button or not button:IsShown() then
        PruneShield(button)
        return
    end
    if not showGearSetShield then
        local shield = Shields[button]
        if shield then
            shield:Hide()
        end
        UpdateClickGuard(button, bag, slot)
        return
    end

    local itemID = GetContainerItemID(bag, slot)
    local lock = GetGearSetLock()
    local inSet = false
    local showShield = false
    if itemID and itemID ~= 0 and lock and lock.IsSlotProtected then
        inSet = lock.IsSlotProtected(bag, slot) and true or false
        if inSet and lock.ShouldShowShieldVisual then
            showShield = lock.ShouldShowShieldVisual(bag, slot) and true or false
        end
    end

    local prev = lastPainted[button]
    if prev and prev.itemID == itemID and prev.inSet == inSet
        and prev.showShield == showShield and prev.enabled == showGearSetShield then
        -- Skip click-guard tree walk when paint state unchanged.
        return
    end

    local shield = Shields[button] or NewShield(button)
    if showShield then
        shield:Show()
    else
        shield:Hide()
    end
    lastPainted[button] = {
        itemID = itemID,
        inSet = inSet,
        showShield = showShield,
        enabled = showGearSetShield,
    }
    UpdateClickGuard(button, bag, slot)
end

local function InvalidateAll()
    wipe(lastPainted)
end

local function RegisterDecorator()
    if registered then
        return
    end
    local overlay = Overlay()
    if not overlay or not overlay.RegisterSlotDecorator then
        return
    end
    overlay.RegisterSlotDecorator("FluxRespecGearSet", {
        Paint = PaintShield,
        Prune = PruneShield,
        Invalidate = InvalidateAll,
    })
    registered = true
end

local function OnIndexChanged()
    local overlay = Overlay()
    if overlay and overlay.InvalidateSlotDecorators then
        pcall(overlay.InvalidateSlotDecorators)
    elseif overlay and overlay.RepaintSlotDecorators then
        pcall(overlay.RepaintSlotDecorators)
    end
end

function GearOverlay.SetEnabled(enabled)
    showGearSetShield = enabled ~= false
    OnIndexChanged()
end

function GearOverlay.IsEnabled()
    return showGearSetShield ~= false
end

-- Shields paint via FluxJunkOverlay slot decorators during the normal junk overlay refresh.
function GearOverlay.ApplyDispatchContext(_ctx)
end

function GearOverlay.ApplyBankInternalContext(_ctx)
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    RegisterDecorator()
    R.On("GEAR_SET_INDEX_CHANGED", OnIndexChanged)
    R.On("GEAR_SET_LOCK_CHANGED", OnIndexChanged)
    local inv = R.Inv
    if inv and inv.Register then
        inv.Register("FluxRespecGearSet", function(ctx)
            if not (ctx and ctx.force) then
                return
            end
            local defer = _G.FluxDeferBankOpenWork or (_G.FLUX_API and _G.FLUX_API.DeferBankOpenWork)
            if defer then
                defer(OnIndexChanged)
            else
                OnIndexChanged()
            end
        end)
    end
end)

_G.FluxRespecGearSetOverlay = GearOverlay
R.GearSetOverlay = GearOverlay
return GearOverlay

