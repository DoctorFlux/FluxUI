--[[
    Restock/Junk/FluxJunkOverlay.lua

    Junk glow + coin overlays on Blizzard bag slots (Scrap spotlight model).

    Hooks ContainerFrame:Update / ContainerFrame_Update for carried bags on
    every client. Bank painting has two independent paths that both only
    run while the bank frame is open:
      * Classic Era / TBC Anniversary / Wrath / Cata Classic (and any
        pre-Warband retail): BankFrame / BankSlotsFrame / bank ContainerFrame
        bag windows, addressed by the classic named-global model.
      * Modern retail with the unified Bank+Warband panel: Character and
        Warband tabs share ONE pooled item-button template
        (BankPanelItemButtonMixin) - hooking its Refresh once covers both,
        since there is no per-bag ContainerFrame to hook there at all.
    LIST_CHANGED triggers one UpdateAll pass (both bank paths included).
]]

if _G.FluxUI_UsesAlternativeBagUI and _G.FluxUI_UsesAlternativeBagUI() then
    return
end

FluxJunkOverlay = FluxJunkOverlay or {}
local Overlay = FluxJunkOverlay
_G.FluxVendorJunkSpotlight = Overlay

local Glows = {}
local Icons = {}
local lastPainted = {}
local slotDecorators = {}
local hooksInstalled = false
local hookedFrames = {}
local containerPainting = false
local containerPaintCooldown = {}
local CONTAINER_PAINT_COOLDOWN = 0.05
local bankGridPainting = false
local bankGridDirty = false
local bankRefreshScheduled = false
local listChangedScheduled = false
local deferredPaintPending = false
local bankOpenPaintGen = 0
local bankOpenInferiorGen = -1
local unifiedTransferPaintGen = 0
local unifiedTransferDirtyBags = {}
local unifiedTransferWantsFull = false
local unifiedCharTransferPaintGen = 0
local unifiedCharTransferDirtyBags = {}
local unifiedCharTransferWantsAll = false
local UNIFIED_BANK_TRANSFER_PAINT_DELAY = 0.06
local UNIFIED_CHAR_TRANSFER_PAINT_DELAY = 0.06
local UNIFIED_BAG_OPEN_PAINT_DELAY = 0.05
local UNIFIED_BAG_PAINT_CHUNK = 48
local bagPaintChunkGen = 0
local ScheduleUnifiedCharacterBagTransferPaint
local UpdateMainBankGrid
local PaintContainerFrameDirect
local PaintAllModernBankButtons
local inferiorRepaintBurstGen = 0
local inferiorRepaintBurstPending = false
local overlayLoginSettlePending = false
local lastBankSlotActivityAt = 0
local BANK_GRID_REFRESH_DELAY = 0.15
local BANK_PAINT_QUIET_SEC = 0.35
local LIST_CHANGED_DEBOUNCE = 0.1
local BANK_MAIN = _G.BANK_CONTAINER or -1

local R, G, B = (function()
    if C_Item and C_Item.GetItemQualityColor then
        return C_Item.GetItemQualityColor(0)
    end
    return 0.62, 0.62, 0.62
end)()

local function FJ()
    return _G.FluxVendorJunk
end

local function GetDisplayFlags()
    local fj = FJ()
    local display = fj and fj.GetDisplay and fj.GetDisplay() or nil
    local showIcons = not display or display.icons ~= false
    local showGlow = not display or display.glow ~= false
    return showIcons, showGlow
end

local function Inv()
    return _G.FluxRestock and _G.FluxRestock.Inv
end

local function Bank()
    local inv = Inv()
    return inv and inv.Bank
end

local function BankIsOpen()
    local bank = Bank()
    return bank and bank.IsOpen() or false
end

local function IsMerchantOpen()
    return MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown()
end

local function HasUnifiedBankUI()
    local api = _G.FLUX_API
    return api and api.HasUnifiedBankUI and api.HasUnifiedBankUI()
end

local function IsUnifiedBankPaintReady()
    local api = _G.FLUX_API
    if not api or not api.IsUnifiedBankPaintReady then
        return true
    end
    return api.IsUnifiedBankPaintReady()
end

local function IsBankBag(bagID)
    local bank = Bank()
    return bank and bank.IsBankContainer(bagID) or false
end

-- Forever's gamepad bag is Blizzard's alone: its Update refreshes gamepad
-- binding groups, and Flux code there taints SetPreferredGamepadInteractTarget().
local function ForeverGamepadUI()
    return _G.FluxUI_IsForeverGamepadUI and _G.FluxUI_IsForeverGamepadUI() or false
end

local function ShouldPaintContainer(frame)
    if not frame or ForeverGamepadUI() then
        return false
    end
    local bagID = frame.GetID and frame:GetID()
    if bagID and IsBankBag(bagID) then
        return BankIsOpen()
    end
    return true
end

local function GetContainerItemID(bag, slot)
    local inv = Inv()
    if inv then
        return inv.GetContainerItemID(bag, slot)
    end
    if C_Container and C_Container.GetContainerItemID then
        return C_Container.GetContainerItemID(bag, slot)
    elseif _G.GetContainerItemID then
        return _G.GetContainerItemID(bag, slot)
    end
    return nil
end

local function GetContainerItemInfo(bag, slot)
    local inv = Inv()
    if inv and inv.GetContainerItemInfo then
        return inv.GetContainerItemInfo(bag, slot)
    end
    if C_Container and C_Container.GetContainerItemInfo then
        return C_Container.GetContainerItemInfo(bag, slot)
    end
    return nil
end

local JUNK_COIN_ATLAS = "bags-junkcoin"

local function SlotIsJunkForDisplay(bag, slot, itemID)
    local fj = FJ()
    if not itemID or not fj then
        return false
    end
    local info = GetContainerItemInfo(bag, slot)
    if fj.IsJunkForDisplay then
        return fj.IsJunkForDisplay(itemID, info) and true or false
    end
    if fj.IsJunk and fj.IsJunk(itemID) then
        return true
    end
    return fj.IsBlizzardVendorJunk and fj.IsBlizzardVendorJunk(itemID, info) and true or false
end

local function ApplyNativeJunkIcon(button, shown)
    local junkIcon = button and button.JunkIcon
    if not junkIcon then
        return false
    end
    if shown then
        if junkIcon.SetAtlas then
            junkIcon:SetAtlas(JUNK_COIN_ATLAS, true)
        end
        junkIcon:Show()
    else
        junkIcon:Hide()
    end
    return true
end

local function NewGlow(button)
    local glow = button:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface/Buttons/UI-ActionButton-Border")
    glow:SetVertexColor(R, G, B, 0.7)
    glow:SetBlendMode("ADD")
    glow:SetPoint("CENTER")
    glow:SetSize(67, 67)
    Glows[button] = glow
    return glow
end

local function NewIcon(button)
    local fj = FJ()
    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetTexture((fj and fj.COIN_ICON) or "Interface/Buttons/UI-GroupLoot-Coin-Up")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetSize(15, 15)
    Icons[button] = icon
    return icon
end

local function ApplyCoinAndGlow(button, isJunk, showIcons, showGlow)
    local showCoin = isJunk and showIcons
    local native = ApplyNativeJunkIcon(button, showCoin)
    local fluxIcon = Icons[button]
    if native then
        if fluxIcon then
            fluxIcon:Hide()
        end
    else
        fluxIcon = fluxIcon or NewIcon(button)
        fluxIcon:SetShown(showCoin)
    end
    local glow = Glows[button] or NewGlow(button)
    glow:SetShown(isJunk and showGlow)
end

local function HasActiveSlotDecorators()
    return next(slotDecorators) ~= nil
end

local function ShouldSkipGearSetPaint()
    local gear = _G.FluxRespecGearSetOverlay
    if not gear or not gear.IsEnabled or not gear.IsEnabled() then
        return true
    end
    return false
end

local function ShouldSkipJunkPaint()
    local fj = FJ()
    if not fj then
        return true
    end
    local display = fj.GetDisplay and fj.GetDisplay()
    if display and display.icons == false and display.glow == false then
        local hasInferior = fj.HasUpgradeInferiorEntries and fj.HasUpgradeInferiorEntries()
        if not hasInferior then
            return true
        end
    end
    return false
end

local function ShouldSkipAllPaint()
    if not ShouldSkipJunkPaint() then
        return false
    end
    if HasActiveSlotDecorators() and not ShouldSkipGearSetPaint() then
        return false
    end
    return true
end

local function IsBankActivityActive()
    if not BankIsOpen() then
        return false
    end
    if lastBankSlotActivityAt <= 0 then
        return false
    end
    return (GetTime() - lastBankSlotActivityAt) < BANK_PAINT_QUIET_SEC
end

local function ShouldDeferPaint()
    if ShouldSkipAllPaint() then
        return true
    end
    if BankIsOpen() and not IsUnifiedBankPaintReady() then
        return true
    end
    if IsBankActivityActive() then
        return true
    end
    local inv = Inv()
    if inv and inv.IsAutomationQuiet and inv.IsAutomationQuiet() then
        return true
    end
    local vs = _G.FluxVendorSession
    if vs and vs.ShouldDeferBagVisuals and vs.ShouldDeferBagVisuals() then
        return true
    end
    local fv = _G.FluxVendorAuto
    if fv and fv.IsVendorBurstActive and fv.IsVendorBurstActive() then
        return true
    end
    local pl = _G.FluxEBS_PostLoginBagRefresh
    if pl and pl.IsPulseEndSettling and pl.IsPulseEndSettling() then
        return true
    end
    return false
end

local function PruneSlotDecorators(button)
    for _, decorator in pairs(slotDecorators) do
        if decorator and decorator.Prune then
            pcall(decorator.Prune, button)
        end
    end
end

local function PaintSlotDecorators(button, bag, slot)
    for _, decorator in pairs(slotDecorators) do
        if decorator and decorator.Paint then
            pcall(decorator.Paint, button, bag, slot)
        end
    end
end

local function PruneButtonDecor(button)
    if not button then return end
    local glow = Glows[button]
    local icon = Icons[button]
    if glow then glow:Hide() end
    if icon then icon:Hide() end
    if button.JunkIcon then
        button.JunkIcon:Hide()
    end
    lastPainted[button] = nil
    PruneSlotDecorators(button)
end

-- bagID 0 is the backpack. `button.bagID or frame:GetID()` treats 0 as missing.
-- Slot is a luaIndex (>= 1). Slot 0 is truthy and C_Container.GetContainerItemID rejects it.
local function ResolveButtonBagSlot(button, frame)
    if not button then
        return nil, nil
    end
    local bag
    if button.bagID ~= nil then
        bag = button.bagID
    elseif button.GetBagID then
        bag = button:GetBagID()
    elseif button.GetBankTabID then
        bag = button:GetBankTabID()
    elseif frame and frame.GetID then
        bag = frame:GetID()
    end
    local slot
    if button.GetContainerSlotID then
        slot = button:GetContainerSlotID()
    elseif button.GetID then
        slot = button:GetID()
    end
    return bag, slot
end

local function SlotKeyOk(bag, slot)
    local ok, good = pcall(function()
        local b = tonumber(bag)
        local s = tonumber(slot)
        if b == nil or s == nil then
            return false
        end
        if b ~= b or s ~= s then
            return false
        end
        if b ~= math.floor(b) or s ~= math.floor(s) or s < 1 then
            return false
        end
        return true
    end)
    return ok and good or false
end

-- Core paint: shared by the classic ContainerFrame/BankSlotsFrame path and
-- the modern pooled Bank+Warband item-button path below - both know how to
-- resolve their own (bag, slot) for a button, everything after that is
-- identical (junk lookup, glow/icon show-hide, paint-once caching).
local function PaintButtonForSlot(button, bag, slot, showIcons, showGlow)
    if not button or not button.IsShown or not button:IsShown() then
        if button then
            PruneButtonDecor(button)
        end
        return
    end
    if not SlotKeyOk(bag, slot) then
        PruneButtonDecor(button)
        return
    end
    local id = GetContainerItemID(bag, slot)
    local isJunk = SlotIsJunkForDisplay(bag, slot, id)

    local prev = lastPainted[button]
    if prev and prev.itemID == id and prev.isJunk == isJunk
        and prev.showIcons == showIcons and prev.showGlow == showGlow then
        -- Blizzard UpdateJunkItem may have just hidden JunkIcon; keep Flux marks.
        ApplyCoinAndGlow(button, isJunk, showIcons, showGlow)
        PaintSlotDecorators(button, bag, slot)
        return
    end

    ApplyCoinAndGlow(button, isJunk, showIcons, showGlow)
    lastPainted[button] = {
        itemID = id,
        isJunk = isJunk,
        showIcons = showIcons,
        showGlow = showGlow,
    }
    PaintSlotDecorators(button, bag, slot)
end

local function UpdateButton(frame, button, showIcons, showGlow)
    local bag, slot = ResolveButtonBagSlot(button, frame)
    if not SlotKeyOk(bag, slot) then
        PruneButtonDecor(button)
        return
    end
    PaintButtonForSlot(button, bag, slot, showIcons, showGlow)
end

local function IterateNamedItemButtons(frame, call)
    local name = frame.GetName and frame:GetName()
    if not name then return end
    local i = 1
    local button = _G[name .. "Item" .. i]
    while button do
        call(button)
        i = i + 1
        button = _G[name .. "Item" .. i]
    end
end

-- Combined bags pool extra buttons past GetBagSize(). EnumerateValidItems is 1..size.
local function ForEachItemButton(frame, call)
    if not frame or not call then
        return
    end
    if frame.EnumerateValidItems then
        local ok = pcall(function()
            for _, button in frame:EnumerateValidItems() do
                if button then
                    call(button)
                end
            end
        end)
        if ok then
            return
        end
    end
    if frame.Items then
        for i = 1, #frame.Items do
            local button = frame.Items[i]
            if button then
                call(button)
            end
        end
        return
    end
    IterateNamedItemButtons(frame, call)
end

-- ---------------------------------------------------------------------------
-- MODERN RETAIL: pooled Bank+Warband item buttons (Blizzard_UIPanels_Game).
--
-- Both the Character and Warband tabs share ONE item-button pool through
-- BankPanelItemButtonMixin, so hooking that mixin's Refresh once covers both
-- automatically - there is no per-bag ContainerFrame to hook here at all.
-- ---------------------------------------------------------------------------

local function IsBankBagSlotButton(button)
    -- Camelot equipped bank-bag slots live on BankFrame.itemButtonBagPool, not
    -- the item grid. Never paint junk on those.
    if not button then
        return false
    end
    if button.bagSlotID ~= nil then
        return true
    end
    if button.GetExactBankTabSlot then
        return true
    end
    return false
end

local function UpdateModernBankButton(button, showIcons, showGlow)
    if IsBankBagSlotButton(button) then
        PruneButtonDecor(button)
        return
    end
    local bag = button.GetBankTabID and button:GetBankTabID()
    local slot = button.GetContainerSlotID and button:GetContainerSlotID()
    if not SlotKeyOk(bag, slot) then
        PruneButtonDecor(button)
        return
    end
    PaintButtonForSlot(button, bag, slot, showIcons, showGlow)
end

local function GetModernBankItemButtonPool()
    local bankFrame = _G.BankFrame
    local panel = bankFrame and bankFrame.BankPanel
    return panel and panel.itemButtonPool
end

local function PaintModernBankButtonsForDirtyBags(dirtyBags, force)
    if ShouldSkipAllPaint() or not IsUnifiedBankPaintReady() then
        return
    end
    if not dirtyBags or not next(dirtyBags) then
        return
    end
    local pool = GetModernBankItemButtonPool()
    if not pool or not pool.EnumerateActive then
        return
    end
    if not force and ShouldDeferPaint() then
        deferredPaintPending = true
        return
    end
    local showIcons, showGlow = GetDisplayFlags()
    pcall(function()
        for button in pool:EnumerateActive() do
            local bag = button.GetBankTabID and button:GetBankTabID()
            if bag and dirtyBags[bag] then
                UpdateModernBankButton(button, showIcons, showGlow)
            end
        end
    end)
end

local function CollectBankDirtyBags(dirtyBags, out)
    out = out or {}
    if not dirtyBags then
        return out
    end
    for bag in pairs(dirtyBags) do
        if IsBankBag(bag) then
            out[bag] = true
        end
    end
    return out
end

local function CollectCharacterDirtyBags(dirtyBags, out)
    out = out or {}
    if not dirtyBags then
        return out
    end
    for bag in pairs(dirtyBags) do
        if not IsBankBag(bag) then
            out[bag] = true
        end
    end
    return out
end

local function CharacterBagsVisible()
    if _G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags.IsShown
        and _G.ContainerFrameCombinedBags:IsShown() then
        return true
    end
    local i = 1
    local frame = _G["ContainerFrame" .. i]
    while frame do
        if frame.IsShown and frame:IsShown() and ShouldPaintContainer(frame) then
            return true
        end
        i = i + 1
        frame = _G["ContainerFrame" .. i]
    end
    return false
end

local function JunkPaintTargetsVisible()
    if CharacterBagsVisible() then
        return true
    end
    -- Merchant open alone is NOT a paint target (avoids inferior bursts with bags closed).
    if BankIsOpen() then
        return true
    end
    if _G.FluxRestockPanel_IsActive and _G.FluxRestockPanel_IsActive() then
        return true
    end
    local panel = _G.FluxVendorRestockPanel
    if panel and panel.IsShown and panel:IsShown() then
        return true
    end
    return false
end

function Overlay.ArePaintTargetsVisible()
    return JunkPaintTargetsVisible()
end

local function MaybeFlushLoginSettlePaint()
    if overlayLoginSettlePending and JunkPaintTargetsVisible() then
        overlayLoginSettlePending = false
        Overlay.ScheduleInferiorRepaintBurst({ loginSettle = true, force = true })
    end
end

PaintContainerFrameDirect = function(frame, dirtyBags)
    if not frame or not ShouldPaintContainer(frame) then
        return
    end
    if frame.IsShown and not frame:IsShown() then
        return
    end
    local paintAll = not dirtyBags or not next(dirtyBags)
    local showIcons, showGlow = GetDisplayFlags()
    ForEachItemButton(frame, function(button)
        local bag, slot = ResolveButtonBagSlot(button, frame)
        if SlotKeyOk(bag, slot) and (paintAll or dirtyBags[bag]) then
            PaintButtonForSlot(button, bag, slot, showIcons, showGlow)
        end
    end)
end

local function BuildUnifiedCharacterBagWorkList(dirtyBags, wantsAll)
    local work = {}
    local paintAll = wantsAll or not dirtyBags or not next(dirtyBags)
    local function addFrame(frame)
        if not frame or not ShouldPaintContainer(frame) then
            return
        end
        if frame.IsShown and not frame:IsShown() then
            return
        end
        ForEachItemButton(frame, function(button)
            local bag, slot = ResolveButtonBagSlot(button, frame)
            if SlotKeyOk(bag, slot) and (paintAll or dirtyBags[bag]) then
                work[#work + 1] = { button = button, bag = bag, slot = slot }
            end
        end)
    end
    addFrame(_G.ContainerFrameCombinedBags)
    local i = 1
    local frame = _G["ContainerFrame" .. i]
    while frame do
        addFrame(frame)
        i = i + 1
        frame = _G["ContainerFrame" .. i]
    end
    return work
end

local function RunChunkedUnifiedCharacterBagPaint(dirtyBags, wantsAll)
    local work = BuildUnifiedCharacterBagWorkList(dirtyBags, wantsAll)
    if #work == 0 then
        return
    end
    bagPaintChunkGen = bagPaintChunkGen + 1
    local gen = bagPaintChunkGen
    local idx = 1
    local showIcons, showGlow = GetDisplayFlags()
    local function step()
        if gen ~= bagPaintChunkGen or ShouldSkipAllPaint() then
            return
        end
        local last = math.min(idx + UNIFIED_BAG_PAINT_CHUNK - 1, #work)
        for i = idx, last do
            local entry = work[i]
            PaintButtonForSlot(entry.button, entry.bag, entry.slot, showIcons, showGlow)
        end
        idx = last + 1
        if idx <= #work then
            if C_Timer and C_Timer.After then
                C_Timer.After(0, step)
            else
                step()
            end
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, step)
    else
        step()
    end
end

local function PaintCharacterBagsForDirtyBags(dirtyBags, force)
    if ShouldSkipAllPaint() or not dirtyBags or not next(dirtyBags) then
        return
    end
    if HasUnifiedBankUI() then
        RunChunkedUnifiedCharacterBagPaint(dirtyBags, false)
        return
    end
    if not force and ShouldDeferPaint() then
        deferredPaintPending = true
        return
    end
    if _G.ContainerFrameCombinedBags and ShouldPaintContainer(_G.ContainerFrameCombinedBags) then
        PaintContainerFrameDirect(_G.ContainerFrameCombinedBags, dirtyBags)
    end
    local i = 1
    local frame = _G["ContainerFrame" .. i]
    while frame do
        local bagID = frame.GetID and frame:GetID()
        if bagID and dirtyBags[bagID] and ShouldPaintContainer(frame) then
            PaintContainerFrameDirect(frame, dirtyBags)
        end
        i = i + 1
        frame = _G["ContainerFrame" .. i]
    end
end

local function PaintAllVisibleCharacterBagSlots(force)
    if HasUnifiedBankUI() then
        RunChunkedUnifiedCharacterBagPaint(nil, true)
        return
    end
    local dirty = {}
    local inv = Inv()
    if inv and inv.GetBagContainerIDs then
        for _, bag in ipairs(inv.GetBagContainerIDs()) do
            dirty[bag] = true
        end
    end
    if next(dirty) then
        PaintCharacterBagsForDirtyBags(dirty, force)
    end
end

local function RunUnifiedCharacterBagTransferPaint()
    if ShouldSkipAllPaint() then
        unifiedCharTransferDirtyBags = {}
        unifiedCharTransferWantsAll = false
        return
    end
    local bags = unifiedCharTransferDirtyBags
    local wantsAll = unifiedCharTransferWantsAll
    unifiedCharTransferDirtyBags = {}
    unifiedCharTransferWantsAll = false
    if wantsAll then
        PaintAllVisibleCharacterBagSlots(true)
    elseif next(bags) then
        PaintCharacterBagsForDirtyBags(bags, true)
    end
end

ScheduleUnifiedCharacterBagTransferPaint = function(dirtyBags, wantsAll)
    if not HasUnifiedBankUI() then
        return false
    end
    if wantsAll then
        unifiedCharTransferWantsAll = true
    end
    CollectCharacterDirtyBags(dirtyBags, unifiedCharTransferDirtyBags)
    unifiedCharTransferPaintGen = unifiedCharTransferPaintGen + 1
    local gen = unifiedCharTransferPaintGen
    local function run()
        if gen ~= unifiedCharTransferPaintGen then
            return
        end
        RunUnifiedCharacterBagTransferPaint()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(UNIFIED_CHAR_TRANSFER_PAINT_DELAY, run)
    else
        run()
    end
    return true
end

function Overlay.ScheduleCharacterBagTransferPaint(dirtyBags, wantsAll)
    return ScheduleUnifiedCharacterBagTransferPaint(dirtyBags, wantsAll)
end

local function RunUnifiedBankTransferPaint()
    if not BankIsOpen() or ShouldSkipAllPaint() or not IsUnifiedBankPaintReady() then
        unifiedTransferDirtyBags = {}
        unifiedTransferWantsFull = false
        return
    end
    local bags = unifiedTransferDirtyBags
    local wantsFull = unifiedTransferWantsFull
    unifiedTransferDirtyBags = {}
    unifiedTransferWantsFull = false
    if wantsFull then
        PaintAllModernBankButtons(true)
        bankGridDirty = false
    elseif next(bags) then
        PaintModernBankButtonsForDirtyBags(bags, true)
    end
end

local function ScheduleUnifiedBankTransferPaint(dirtyBags, wantsFull)
    if not HasUnifiedBankUI() or not BankIsOpen() then
        return false
    end
    if wantsFull then
        unifiedTransferWantsFull = true
    end
    CollectBankDirtyBags(dirtyBags, unifiedTransferDirtyBags)
    unifiedTransferPaintGen = unifiedTransferPaintGen + 1
    local gen = unifiedTransferPaintGen
    local function run()
        if gen ~= unifiedTransferPaintGen or not BankIsOpen() then
            return
        end
        RunUnifiedBankTransferPaint()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(UNIFIED_BANK_TRANSFER_PAINT_DELAY, run)
    else
        run()
    end
    return true
end

PaintAllModernBankButtons = function(force)
    if ShouldSkipAllPaint() or not IsUnifiedBankPaintReady() then
        return
    end
    local pool = GetModernBankItemButtonPool()
    if not pool or not pool.EnumerateActive then
        return
    end
    if not force and ShouldDeferPaint() then
        deferredPaintPending = true
        return
    end
    local showIcons, showGlow = GetDisplayFlags()
    pcall(function()
        for button in pool:EnumerateActive() do
            UpdateModernBankButton(button, showIcons, showGlow)
        end
    end)
end

local function ScheduleUnifiedContainerPaint(frame)
    if frame == _G.ContainerFrameCombinedBags then
        ScheduleUnifiedCharacterBagTransferPaint(nil, true)
        return
    end
    local bagID = frame and frame.GetID and frame:GetID()
    if bagID and not IsBankBag(bagID) then
        ScheduleUnifiedCharacterBagTransferPaint({ [bagID] = true }, false)
    else
        ScheduleUnifiedCharacterBagTransferPaint(nil, true)
    end
end

local function UpdateContainer(frame, force)
    MaybeFlushLoginSettlePaint()
    if containerPainting or not ShouldPaintContainer(frame) then
        return
    end
    if HasUnifiedBankUI() then
        local bagID = frame.GetID and frame:GetID()
        if not bagID or not IsBankBag(bagID) then
            deferredPaintPending = true
            ScheduleUnifiedContainerPaint(frame)
            return
        end
    end
    if not force and ShouldDeferPaint() then
        deferredPaintPending = true
        return
    end
    local now = GetTime()
    local lastPaint = containerPaintCooldown[frame]
    if not force and lastPaint and (now - lastPaint) < CONTAINER_PAINT_COOLDOWN then
        deferredPaintPending = true
        return
    end
    containerPaintCooldown[frame] = now
    local prof = _G.FluxBagLagProf
    if prof and prof.Inc then
        prof.Inc("overlay:containerPaint")
    end
    containerPainting = true
    PaintContainerFrameDirect(frame, nil)
    containerPainting = false
end

Overlay.UpdateContainer = UpdateContainer

--- Scrap-style full container pass (LIST_CHANGED and inferior-set refresh).
function Overlay.UpdateAll(force)
    if ShouldSkipAllPaint() then
        return
    end
    if HasUnifiedBankUI() then
        ScheduleUnifiedCharacterBagTransferPaint(nil, true)
        if BankIsOpen() and bankGridDirty then
            Overlay.ScheduleMainBankGridRefresh()
        end
        return
    end
    if not force and ShouldDeferPaint() then
        deferredPaintPending = true
        return
    end
    local prof = _G.FluxBagLagProf
    if prof and prof.Inc then
        prof.Inc("overlay:updateAll")
    end
    if _G.ContainerFrameCombinedBags then
        UpdateContainer(_G.ContainerFrameCombinedBags, force)
    end
    local i = 1
    local frame = _G["ContainerFrame" .. i]
    while frame do
        UpdateContainer(frame, force)
        i = i + 1
        frame = _G["ContainerFrame" .. i]
    end
    if BankIsOpen() and bankGridDirty then
        Overlay.ScheduleMainBankGridRefresh()
    end
end

Overlay.UpdateBags = Overlay.UpdateAll

--- Repaint only bag containers that changed (sell / deposit path).
function Overlay.UpdateDirtyBags(dirtyBags, force)
    if not dirtyBags or not next(dirtyBags) then
        return
    end
    if ShouldSkipAllPaint() then
        return
    end
    if HasUnifiedBankUI() then
        ScheduleUnifiedCharacterBagTransferPaint(dirtyBags, false)
        return
    end
    local totalBags = 0
    local inv = Inv()
    if inv and inv.GetBagContainerIDs then
        totalBags = #inv.GetBagContainerIDs()
    end
    local dirtyCount = 0
    for _ in pairs(dirtyBags) do
        dirtyCount = dirtyCount + 1
    end
    if not force and totalBags > 0 and dirtyCount >= math.ceil(totalBags * 0.5) then
        Overlay.UpdateAll(force)
        return
    end
    if _G.ContainerFrameCombinedBags then
        UpdateContainer(_G.ContainerFrameCombinedBags, force)
    end
    local i = 1
    local frame = _G["ContainerFrame" .. i]
    while frame do
        local bagID = frame.GetID and frame:GetID()
        if bagID == nil or dirtyBags[bagID] then
            UpdateContainer(frame, force)
        end
        i = i + 1
        frame = _G["ContainerFrame" .. i]
    end
end

local function GetMainBankContainerIDs()
    local ids = {}
    local mainBank = (Enum and Enum.BagIndex and Enum.BagIndex.Bank) or BANK_MAIN
    ids[mainBank] = true
    if BANK_MAIN ~= mainBank then
        ids[BANK_MAIN] = true
    end
    return ids
end

local function ModernBankPanelVisible()
    local bankFrame = _G.BankFrame
    local panel = bankFrame and bankFrame.BankPanel
    return panel and panel.IsShown and panel:IsShown()
end

local function PaintContainerByBagID(bagID, force)
    bagID = tonumber(bagID)
    if not bagID then
        return
    end
    if _G.ContainerFrameCombinedBags and ShouldPaintContainer(_G.ContainerFrameCombinedBags) then
        local combinedID = _G.ContainerFrameCombinedBags.GetID and _G.ContainerFrameCombinedBags:GetID()
        if combinedID == bagID then
            UpdateContainer(_G.ContainerFrameCombinedBags, force)
            return
        end
    end
    local i = 1
    local frame = _G["ContainerFrame" .. i]
    while frame do
        if frame.GetID and frame:GetID() == bagID and ShouldPaintContainer(frame) then
            UpdateContainer(frame, force)
            return
        end
        i = i + 1
        frame = _G["ContainerFrame" .. i]
    end
end

local function PaintDirtyBankContainers(dirtyBags, force)
    if not dirtyBags or not next(dirtyBags) then
        return false
    end
    local mainIds = GetMainBankContainerIDs()
    local needsMainGrid = false
    for bag in pairs(dirtyBags) do
        if mainIds[bag] then
            needsMainGrid = true
        elseif IsBankBag(bag) then
            PaintContainerByBagID(bag, force)
        end
    end
    if needsMainGrid then
        bankGridDirty = true
        Overlay.ScheduleMainBankGridRefresh()
    end
    if HasUnifiedBankUI() then
        local bankDirty = CollectBankDirtyBags(dirtyBags, {})
        if next(bankDirty) then
            ScheduleUnifiedBankTransferPaint(bankDirty, false)
        end
        return needsMainGrid
    end
    if ModernBankPanelVisible() then
        PaintAllModernBankButtons(force)
    end
    return needsMainGrid
end

-- Repaints EVERY bank slot visual regardless of client: the classic main
-- grid below, AND (via PaintAllModernBankButtons) the modern pooled
-- Character/Warband item buttons. Every call site that wants "the bank
-- visuals are current" funnels through here so neither path is forgotten.
UpdateMainBankGrid = function()
    if not BankIsOpen() then
        return
    end
    if HasUnifiedBankUI() then
        ScheduleUnifiedBankTransferPaint(nil, true)
        return
    end
    PaintAllModernBankButtons(true)

    if bankGridPainting then
        return
    end
    local bankSlots = _G.BankSlotsFrame
    if not bankSlots or not bankSlots.IsShown or not bankSlots:IsShown() then
        bankGridDirty = true
        return
    end
    bankGridPainting = true
    local showIcons, showGlow = GetDisplayFlags()
    if bankSlots.Items then
        for idx = 1, #bankSlots.Items do
            UpdateButton(bankSlots, bankSlots.Items[idx], showIcons, showGlow)
        end
    else
        local numSlots = _G.NUM_BANKGENERIC_SLOTS or 28
        for i = 1, numSlots do
            local button = bankSlots["Item" .. i] or _G["BankFrameItem" .. i]
            if button then
                UpdateButton(bankSlots, button, showIcons, showGlow)
            end
        end
    end
    bankGridDirty = false
    bankGridPainting = false
end

local function PaintVisibleBankBagContainers(force)
    if not BankIsOpen() then
        return
    end
    if _G.ContainerFrameCombinedBags and ShouldPaintContainer(_G.ContainerFrameCombinedBags) then
        UpdateContainer(_G.ContainerFrameCombinedBags, force)
    end
    local i = 1
    local frame = _G["ContainerFrame" .. i]
    while frame do
        if ShouldPaintContainer(frame) then
            UpdateContainer(frame, force)
        end
        i = i + 1
        frame = _G["ContainerFrame" .. i]
    end
end

local function PaintAllBankVisuals(force)
    if not BankIsOpen() or ShouldSkipAllPaint() or not IsUnifiedBankPaintReady() then
        return
    end
    bankGridDirty = true
    UpdateMainBankGrid()
    PaintVisibleBankBagContainers(force)
end

local function EnsureBankInferiorMarks()
    local bank = Bank()
    if bank then
        bank.RefreshIfOpen()
    end
    local tiers = _G.FluxRestockTiers
    if not tiers then
        return
    end
    if tiers._loginSettleDeferred and tiers.TryRunDeferredLoginSettle then
        pcall(tiers.TryRunDeferredLoginSettle)
        return
    end
    -- One RecomputeInferior per bank-open paint generation; later paints reuse marks.
    if bankOpenInferiorGen == bankOpenPaintGen then
        return
    end
    if bank and bank.IsOpen and bank.IsOpen() and tiers.RecomputeInferior then
        bankOpenInferiorGen = bankOpenPaintGen
        pcall(tiers.RecomputeInferior)
    end
end

local function RunBankOpenRefreshPass()
    if not BankIsOpen() or ShouldSkipAllPaint() then
        return
    end
    if not HasUnifiedBankUI() then
        EnsureBankInferiorMarks()
        PaintAllBankVisuals(true)
        return
    end
    bankGridDirty = true
    PaintAllModernBankButtons(true)
    local bankSlots = _G.BankSlotsFrame
    if bankSlots and bankSlots.IsShown and bankSlots:IsShown() then
        UpdateMainBankGrid()
    end
    PaintVisibleBankBagContainers(true)
end

local function ScheduleBankOpenPaintBurst()
    if ShouldSkipAllPaint() or not BankIsOpen() then
        return
    end
    if HasUnifiedBankUI() then
        bankOpenPaintGen = bankOpenPaintGen + 1
        EnsureBankInferiorMarks()
        RunBankOpenRefreshPass()
        return
    end
    bankOpenPaintGen = bankOpenPaintGen + 1
    local gen = bankOpenPaintGen
    -- Inferior once up front; delayed paints only tint from existing marks.
    EnsureBankInferiorMarks()
    local delays = { 0, 0.08, 0.25 }
    for _, delay in ipairs(delays) do
        if C_Timer and C_Timer.After then
            C_Timer.After(delay, function()
                if gen ~= bankOpenPaintGen or not BankIsOpen() then
                    return
                end
                -- Reuse marks; EnsureBankInferiorMarks is a no-op after first call.
                RunBankOpenRefreshPass()
            end)
        elseif delay == 0 then
            RunBankOpenRefreshPass()
        end
    end
end

Overlay.PaintAllBankVisuals = PaintAllBankVisuals

local function PaintBankOpenVisuals(force)
    PaintAllBankVisuals(force)
end

local function OnBankOpenedForOverlay()
    bankGridDirty = true
    lastBankSlotActivityAt = 0
    local pl = _G.FluxEBS_PostLoginBagRefresh
    if pl and pl.IsPostLoginPulseActive and pl.IsPostLoginPulseActive() then
        return
    end
    if HasUnifiedBankUI() then
        ScheduleBankOpenPaintBurst()
        return
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, ScheduleBankOpenPaintBurst)
    else
        ScheduleBankOpenPaintBurst()
    end
end

local function RegisterBagOpenPaint()
    if Overlay._bagOpenRegistered or ForeverGamepadUI() then
        return
    end
    Overlay._bagOpenRegistered = true
    local combined = _G.ContainerFrameCombinedBags
    if not combined or not combined.HookScript then
        return
    end
    combined:HookScript("OnShow", function()
        if not HasUnifiedBankUI() or ForeverGamepadUI() then
            return
        end
        Overlay.EnsureHooks()
        unifiedCharTransferPaintGen = unifiedCharTransferPaintGen + 1
        local gen = unifiedCharTransferPaintGen
        local function run()
            if gen ~= unifiedCharTransferPaintGen then
                return
            end
            ScheduleUnifiedCharacterBagTransferPaint(nil, true)
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(UNIFIED_BAG_OPEN_PAINT_DELAY, run)
        else
            run()
        end
    end)
    combined:HookScript("OnHide", function()
        unifiedCharTransferPaintGen = unifiedCharTransferPaintGen + 1
        bagPaintChunkGen = bagPaintChunkGen + 1
        unifiedCharTransferDirtyBags = {}
        unifiedCharTransferWantsAll = false
    end)
end

local function RegisterBankOpenPaint()
    if Overlay._bankOpenRegistered then
        return
    end
    Overlay._bankOpenRegistered = true
    local bank = Bank()
    if bank then
        bank.RegisterBankOpen("FluxJunkOverlay", OnBankOpenedForOverlay)
    end
    local pl = _G.FluxEBS_PostLoginBagRefresh
    if pl and pl.RegisterPulseEndCallback then
        pl.RegisterPulseEndCallback("FluxJunkOverlay", function()
            if not BankIsOpen() then
                return
            end
            ScheduleBankOpenPaintBurst()
        end)
    end
end

function Overlay.UpdateAllBank()
    if not BankIsOpen() then
        return
    end
    bankGridDirty = true
    Overlay.UpdateAll()
    UpdateMainBankGrid()
end

function Overlay.ScheduleMainBankGridRefresh(delay)
    if ShouldSkipAllPaint() then
        return
    end
    if not BankIsOpen() or not bankGridDirty then
        return
    end
    if bankRefreshScheduled then
        return
    end
    bankRefreshScheduled = true
    delay = math.max(tonumber(delay) or BANK_GRID_REFRESH_DELAY, BANK_GRID_REFRESH_DELAY)
    local function run()
        bankRefreshScheduled = false
        if BankIsOpen() and bankGridDirty then
            UpdateMainBankGrid()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, run)
    else
        run()
    end
end

--- Lightweight junk overlay refresh for in-bank reorganize (slot moves only).
function Overlay.ApplyBankInternalContext(ctx)
    if ShouldSkipAllPaint() or not ctx or not BankIsOpen() then
        return
    end
    lastBankSlotActivityAt = GetTime()
    local dirtyBags = ctx.dirtyBags
    if HasUnifiedBankUI() then
        if dirtyBags and next(dirtyBags) then
            PaintDirtyBankContainers(dirtyBags, true)
        else
            ScheduleUnifiedBankTransferPaint(nil, true)
        end
        return
    end
    if dirtyBags and next(dirtyBags) then
        PaintDirtyBankContainers(dirtyBags, true)
        return
    end
    bankGridDirty = true
    Overlay.ScheduleMainBankGridRefresh()
end

--- Targeted junk overlay refresh after inventory dispatch (bank transfers, etc.).
function Overlay.ApplyDispatchContext(ctx)
    if ShouldSkipAllPaint() or not ctx then
        return
    end
    -- Bags closed and no bank: nothing visible to paint (loot/craft with bags shut).
    local bagsVisible = (_G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags:IsShown())
        or (_G.ContainerFrame1 and _G.ContainerFrame1:IsShown())
    if not bagsVisible and not BankIsOpen() then
        return
    end
    local regions = ctx.regions or {}
    local bagsChanged = regions.bags == true
    local bankChanged = regions.bank == true or regions.warband == true
    -- Prefer generation hints so coalesced pulses without real bag dirty skip full paints.
    if ctx.bagsGenChanged == false then
        bagsChanged = false
    end
    if ctx.bankGenChanged == false then
        bankChanged = false
    end
    -- Legacy FluxInventory ctx shape still supported.
    if ctx.bankChanged ~= nil then
        bankChanged = ctx.bankChanged and true or false
    end
    -- No live bank work when closed (paints already gated; skip early).
    if bankChanged and not BankIsOpen() then
        bankChanged = false
        if not bagsChanged and not (ctx.dirtyBags and next(ctx.dirtyBags)) then
            return
        end
    end
    if bankChanged and ctx.changeKind == "none"
        and not (ctx.addedItemIDs and next(ctx.addedItemIDs))
        and not (ctx.removedItemIDs and next(ctx.removedItemIDs))
        and not bagsChanged then
        Overlay.ApplyBankInternalContext(ctx)
        return
    end
    local dirtyBags = ctx.dirtyBags
    if not bagsChanged and not bankChanged and not (dirtyBags and next(dirtyBags)) then
        return
    end
    if HasUnifiedBankUI() then
        if dirtyBags and next(dirtyBags) then
            local charDirty = CollectCharacterDirtyBags(dirtyBags, {})
            if next(charDirty) then
                ScheduleUnifiedCharacterBagTransferPaint(charDirty, false)
            end
        elseif bagsChanged then
            Overlay.UpdateAll(true)
        end
        if bankChanged and BankIsOpen() then
            lastBankSlotActivityAt = GetTime()
            if dirtyBags and next(dirtyBags) then
                PaintDirtyBankContainers(dirtyBags, true)
            else
                ScheduleUnifiedBankTransferPaint(nil, true)
            end
        end
        return
    end
    if dirtyBags and next(dirtyBags) then
        Overlay.UpdateDirtyBags(dirtyBags, true)
    elseif bagsChanged then
        Overlay.UpdateAll(true)
    end
    if bankChanged and BankIsOpen() then
        bankGridDirty = true
        UpdateMainBankGrid()
        if dirtyBags and next(dirtyBags) then
            PaintVisibleBankBagContainers(true)
        end
    end
end

--- Fast overlay refresh during bank transfers (legacy; coalesced by ScheduleBankActivityRefresh).
function Overlay.ScheduleBankTransferPaint(dirtyBags, bankChanged)
    if ShouldSkipAllPaint() or not BankIsOpen() then
        return
    end
    if bankChanged then
        bankGridDirty = true
    end
    lastBankSlotActivityAt = GetTime()
    if HasUnifiedBankUI() then
        ScheduleUnifiedBankTransferPaint(dirtyBags, false)
    end
end

--- Bank-only inventory pulse: repaint bank slots without touching character bags.
function Overlay.ApplyBankOnlyContext()
    if ShouldSkipAllPaint() or not BankIsOpen() then
        return
    end
    bankGridDirty = true
    Overlay.ScheduleMainBankGridRefresh()
end

Overlay.ScheduleBankRefresh = Overlay.ScheduleMainBankGridRefresh

function Overlay.MarkBankGridDirty()
    if not BankIsOpen() then
        return
    end
    bankGridDirty = true
    Overlay.ScheduleMainBankGridRefresh()
end

Overlay.RefreshAll = Overlay.UpdateAll
Overlay.UpdateAllCheap = Overlay.UpdateAll
Overlay.RefreshVisibleBagsCheap = Overlay.UpdateAll

local function InvalidateItemVisual(itemID)
    if not itemID then
        wipe(lastPainted)
        return
    end
    for btn, prev in pairs(lastPainted) do
        if prev and prev.itemID == itemID then
            lastPainted[btn] = nil
        end
    end
end

local function RefreshBagContainersForPaint()
    if ForeverGamepadUI() then
        return
    end
    Overlay.EnsureHooks()
    if _G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags.Update then
        pcall(_G.ContainerFrameCombinedBags.Update, _G.ContainerFrameCombinedBags)
    end
    local i = 1
    local frame = _G["ContainerFrame" .. i]
    while frame do
        if frame.Update then
            pcall(frame.Update, frame)
        end
        i = i + 1
        frame = _G["ContainerFrame" .. i]
    end
end

local function RepaintVisibleContainers(force, bankGridOnly)
    if HasUnifiedBankUI() and not bankGridOnly then
        ScheduleUnifiedCharacterBagTransferPaint(nil, true)
        if BankIsOpen() then
            PaintAllBankVisuals(force)
        end
        return
    end
    if not bankGridOnly then
        RefreshBagContainersForPaint()
    end
    if bankGridOnly then
        if BankIsOpen() then
            PaintAllBankVisuals(force)
        end
        return
    end
    if _G.ContainerFrameCombinedBags then
        -- Merchant open alone must not paint hidden bag frames.
        if _G.ContainerFrameCombinedBags:IsShown() then
            UpdateContainer(_G.ContainerFrameCombinedBags, force)
        end
    end
    local i = 1
    local frame = _G["ContainerFrame" .. i]
    while frame do
        if frame:IsShown() then
            UpdateContainer(frame, force)
        end
        i = i + 1
        frame = _G["ContainerFrame" .. i]
    end
end

--- Lightweight repaint after inferior marks change (bypasses vendor burst defer).
function Overlay.RepaintInferiorVisuals()
    wipe(lastPainted)
    RepaintVisibleContainers(true, IsBankActivityActive())
    if BankIsOpen() then
        PaintAllBankVisuals(true)
    end
end

--- Retry inferior paint while bag frames finish opening/updating at vendors.
function Overlay.ScheduleInferiorRepaintBurst(opts)
    opts = type(opts) == "table" and opts or {}
    if inferiorRepaintBurstPending and not opts.force then
        return
    end
    if ShouldDeferPaint() then
        deferredPaintPending = true
        return
    end
    local fv = _G.FluxVendorAuto
    if fv and fv.IsVendorBurstActive and fv.IsVendorBurstActive() then
        deferredPaintPending = true
        return
    end
    if opts.loginSettle and not JunkPaintTargetsVisible() then
        overlayLoginSettlePending = true
        return
    end
    local pl = _G.FluxEBS_PostLoginBagRefresh
    if pl and pl.IsPulseEndSettling and pl.IsPulseEndSettling() then
        deferredPaintPending = true
        if opts.loginSettle then
            overlayLoginSettlePending = true
        end
        return
    end
    inferiorRepaintBurstPending = true
    inferiorRepaintBurstGen = inferiorRepaintBurstGen + 1
    local gen = inferiorRepaintBurstGen
    local delays = opts.loginSettle and { 0, 0.1 } or { 0.03, 0.08, 0.15, 0.3 }
    local function run()
        if gen ~= inferiorRepaintBurstGen then
            return
        end
        Overlay.RepaintInferiorVisuals()
    end
    local pendingCount = #delays
    local function onPassDone()
        pendingCount = pendingCount - 1
        if pendingCount <= 0 then
            inferiorRepaintBurstPending = false
        end
    end
    for _, delay in ipairs(delays) do
        if C_Timer and C_Timer.After then
            C_Timer.After(delay, function()
                run()
                onPassDone()
            end)
        elseif delay == 0 then
            run()
            onPassDone()
        end
    end
end

function Overlay.CancelInferiorRepaintBurst()
    inferiorRepaintBurstGen = inferiorRepaintBurstGen + 1
    inferiorRepaintBurstPending = false
end

function Overlay.OnLoginPulseEndSettled()
    if not JunkPaintTargetsVisible() then
        if overlayLoginSettlePending or deferredPaintPending then
            overlayLoginSettlePending = overlayLoginSettlePending or deferredPaintPending
            return
        end
    end
    if overlayLoginSettlePending then
        overlayLoginSettlePending = false
        Overlay.ScheduleInferiorRepaintBurst({ loginSettle = true, force = true })
        return
    end
    if deferredPaintPending then
        Overlay.FlushDeferredPaint(true)
    end
end

local function ScheduleListChangedRefresh(itemID)
    if listChangedScheduled then
        return
    end
    listChangedScheduled = true
    local function run()
        listChangedScheduled = false
        if ShouldDeferPaint() then
            deferredPaintPending = true
            return
        end
        if itemID then
            InvalidateItemVisual(itemID)
            RepaintVisibleContainers(true)
            if BankIsOpen() then
                PaintAllBankVisuals(true)
            end
            return
        end
        Overlay.UpdateAll(true)
        if BankIsOpen() then
            PaintAllBankVisuals(true)
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(LIST_CHANGED_DEBOUNCE, run)
    else
        run()
    end
end

function Overlay.FlushDeferredPaint(force)
    if not force and not deferredPaintPending then
        return
    end
    deferredPaintPending = false
    if HasUnifiedBankUI() then
        ScheduleUnifiedCharacterBagTransferPaint(nil, true)
        if BankIsOpen() then
            PaintAllBankVisuals(force == true)
        end
        return
    end
    RepaintVisibleContainers(force == true)
    if BankIsOpen() then
        PaintAllBankVisuals(force == true)
    end
end

local function EnsureQuietSettleHook()
    if Overlay._quietSettleHooked then return end
    Overlay._quietSettleHooked = true
    local inv = Inv()
    if inv and inv.OnQuietSettled then
        inv.OnQuietSettled(function()
            if deferredPaintPending or bankGridDirty then
                Overlay.FlushDeferredPaint(true)
            end
            if BankIsOpen() and bankGridDirty and not ShouldDeferPaint() then
                PaintAllBankVisuals(true)
            end
        end)
    end
end

local function HookFrame(frame)
    if not frame or hookedFrames[frame] or not frame.Update or ForeverGamepadUI() then
        return
    end
    hookedFrames[frame] = true
    hooksecurefunc(frame, "Update", function(self)
        if not ShouldPaintContainer(self) then
            return
        end
        UpdateContainer(self)
    end)
end

local function HookUpdateJunkItem()
    if Overlay._updateJunkItemHooked or not hooksecurefunc or ForeverGamepadUI() then
        return
    end
    local mixin = _G.ContainerFrameItemButtonMixin
    if not mixin or not mixin.UpdateJunkItem then
        return
    end
    Overlay._updateJunkItemHooked = true
    hooksecurefunc(mixin, "UpdateJunkItem", function(self)
        if ShouldSkipJunkPaint() or ForeverGamepadUI() then
            return
        end
        local bag, slot = ResolveButtonBagSlot(self)
        if not SlotKeyOk(bag, slot) then
            return
        end
        local showIcons, showGlow = GetDisplayFlags()
        local id = GetContainerItemID(bag, slot)
        local isJunk = SlotIsJunkForDisplay(bag, slot, id)
        ApplyCoinAndGlow(self, isJunk, showIcons, showGlow)
    end)
end

local function OnBankOpened()
    bankGridDirty = true
    lastBankSlotActivityAt = 0
    OnBankOpenedForOverlay()
end

function Overlay.NotifyBankActivity()
    if ShouldSkipAllPaint() then
        return
    end
    lastBankSlotActivityAt = GetTime()
    bankGridDirty = true
    if BankIsOpen() then
        Overlay.ScheduleMainBankGridRefresh()
    end
end

local function OnBankSlotChanged()
    if not BankIsOpen() then
        return
    end
    lastBankSlotActivityAt = GetTime()
    bankGridDirty = true
end

function Overlay.EnsureHooks()
    if hooksInstalled then
        RegisterBankOpenPaint()
        RegisterBagOpenPaint()
        HookUpdateJunkItem()
        return
    end
    hooksInstalled = true
    RegisterBankOpenPaint()
    RegisterBagOpenPaint()
    HookUpdateJunkItem()

    if _G.ContainerFrameCombinedBags then
        HookFrame(_G.ContainerFrameCombinedBags)
    end

    local hookedAnyFrame = false
    local i = 1
    local frame = _G["ContainerFrame" .. i]
    while frame do
        if frame.Update then
            HookFrame(frame)
            hookedAnyFrame = true
        end
        i = i + 1
        frame = _G["ContainerFrame" .. i]
    end

    if not hookedAnyFrame and type(_G.ContainerFrame_Update) == "function" then
        hooksecurefunc("ContainerFrame_Update", function(f)
            if not ShouldPaintContainer(f) then
                return
            end
            UpdateContainer(f)
        end)
    end

    -- Modern retail: pooled bank buttons — never hook Refresh on unified UI
    -- (Blizzard refreshes the whole pool per deposit; hooking paints every slot).
    -- Do not hook CamelotBankPanelItemButtonMixin.Refresh: it swaps empty/filled atlases.
    local modernBankMixin = _G.BankPanelItemButtonMixin
    if modernBankMixin and modernBankMixin.Refresh then
        hooksecurefunc(modernBankMixin, "Refresh", function(self)
            if HasUnifiedBankUI() then
                return
            end
            if not BankIsOpen() or ShouldSkipAllPaint() then
                return
            end
            if ShouldDeferPaint() then
                deferredPaintPending = true
                return
            end
            local showIcons, showGlow = GetDisplayFlags()
            UpdateModernBankButton(self, showIcons, showGlow)
        end)
    end

    -- Camelot bags-in-bank pages rebuild the item pool; paint on the next frame
    -- because PageInfoChanged fires before GenerateAndPlaceOnePageOfItemButtons.
    if EventRegistry and EventRegistry.RegisterCallback then
        local pagePaintGen = 0
        local function ScheduleCamelotPagePaint()
            if not BankIsOpen() then
                return
            end
            pagePaintGen = pagePaintGen + 1
            local gen = pagePaintGen
            local After = C_Timer and C_Timer.After
            local function run()
                if gen ~= pagePaintGen or not BankIsOpen() then
                    return
                end
                PaintAllModernBankButtons(true)
            end
            if After then
                After(0, run)
            else
                run()
            end
        end
        pcall(function()
            EventRegistry:RegisterCallback("BankPanelMixin.PageSelected", ScheduleCamelotPagePaint)
        end)
        pcall(function()
            EventRegistry:RegisterCallback("BankPanelMixin.PageInfoChanged", ScheduleCamelotPagePaint)
        end)
    end

    EnsureQuietSettleHook()

    local fj = FJ()
    if fj and fj.RegisterListChanged then
        fj.RegisterListChanged(function(itemID)
            ScheduleListChangedRefresh(itemID)
        end)
    end
    if fj and fj.RegisterVisualRefresh then
        fj.RegisterVisualRefresh(function(itemID)
            if itemID then
                InvalidateItemVisual(itemID)
            else
                wipe(lastPainted)
            end
            if ShouldDeferPaint() then
                deferredPaintPending = true
                return
            end
            if itemID then
                RepaintVisibleContainers(false)
            else
                Overlay.RepaintInferiorVisuals()
            end
        end)
    end

    local bankFrame = _G.BankFrame
    if bankFrame and bankFrame.HookScript then
        if not HasUnifiedBankUI() then
            bankFrame:HookScript("OnShow", OnBankOpened)
        end
        bankFrame:HookScript("OnHide", function()
            bankGridDirty = false
            bankRefreshScheduled = false
            unifiedTransferPaintGen = unifiedTransferPaintGen + 1
            unifiedTransferDirtyBags = {}
            unifiedTransferWantsFull = false
            unifiedCharTransferPaintGen = unifiedCharTransferPaintGen + 1
            unifiedCharTransferDirtyBags = {}
            unifiedCharTransferWantsAll = false
        end)
    end

    local bankSlots = _G.BankSlotsFrame
    if bankSlots and bankSlots.HookScript and not HasUnifiedBankUI() then
        bankSlots:HookScript("OnShow", function()
            if BankIsOpen() then
                RunBankOpenRefreshPass()
            end
        end)
    end

    local slotFrame = CreateFrame("Frame")
    local function regEvent(ev)
        pcall(function() slotFrame:RegisterEvent(ev) end)
    end
    regEvent("PLAYERBANKSLOTS_CHANGED")
    regEvent("PLAYERBANKBAGSLOTS_CHANGED")
    slotFrame:SetScript("OnEvent", OnBankSlotChanged)
end

Overlay.InstallHooks = Overlay.EnsureHooks

function Overlay.RegisterSlotDecorator(id, decorator)
    if type(id) ~= "string" or type(decorator) ~= "table" then
        return false
    end
    slotDecorators[id] = decorator
    return true
end

function Overlay.InvalidateSlotDecorators()
    for _, decorator in pairs(slotDecorators) do
        if decorator and decorator.Invalidate then
            pcall(decorator.Invalidate)
        end
    end
    wipe(lastPainted)
    RepaintVisibleContainers(true)
    if BankIsOpen() then
        PaintAllBankVisuals(true)
    end
end

function Overlay.RepaintSlotDecorators()
    for _, decorator in pairs(slotDecorators) do
        if decorator and decorator.Invalidate then
            pcall(decorator.Invalidate)
        end
    end
    RepaintVisibleContainers(true)
    if BankIsOpen() then
        PaintAllBankVisuals(true)
    end
end

--- Light refresh for merchant/DE protection context flips.
--- Does NOT invalidate caches or call Blizzard ContainerFrame:Update.
--- Only re-paints the GearSet decorator on currently shown bag buttons.
function Overlay.RefreshProtectionContext()
    local gearDecorator = slotDecorators["FluxRespecGearSet"]
    if not gearDecorator or not gearDecorator.Paint then
        return
    end

    local function paintProtection(button, bag, slot)
        if not button or not button.IsShown or not button:IsShown() then
            return
        end
        if not SlotKeyOk(bag, slot) then
            return
        end
        pcall(gearDecorator.Paint, button, bag, slot)
    end

    local function paintFrame(frame)
        if not frame or not frame.IsShown or not frame:IsShown() or ForeverGamepadUI() then
            return
        end
        ForEachItemButton(frame, function(button)
            local bag, slot = ResolveButtonBagSlot(button, frame)
            paintProtection(button, bag, slot)
        end)
    end

    if _G.ContainerFrameCombinedBags then
        paintFrame(_G.ContainerFrameCombinedBags)
    end
    local i = 1
    local frame = _G["ContainerFrame" .. i]
    while frame do
        paintFrame(frame)
        i = i + 1
        frame = _G["ContainerFrame" .. i]
    end
end

local deferHookFrame = CreateFrame("Frame")
deferHookFrame:RegisterEvent("PLAYER_LOGIN")
deferHookFrame:RegisterEvent("BAG_UPDATE_DELAYED")
deferHookFrame:RegisterEvent("MERCHANT_SHOW")
deferHookFrame:RegisterEvent("MERCHANT_CLOSED")
deferHookFrame:SetScript("OnEvent", function(self, event)
    if event == "MERCHANT_CLOSED" then
        if Overlay.CancelInferiorRepaintBurst then
            Overlay.CancelInferiorRepaintBurst()
        end
        return
    end
    if event == "MERCHANT_SHOW" then
        if hooksInstalled then
            local schedule = (C_Timer and C_Timer.After) or (_G.FluxAPICompat and _G.FluxAPICompat.After)
            if schedule then
                schedule(0.5, function()
                    -- Only burst-paint when character bag frames are actually visible.
                    if CharacterBagsVisible and CharacterBagsVisible() then
                        Overlay.ScheduleInferiorRepaintBurst()
                    end
                end)
            end
        end
        return
    end
    Overlay.EnsureHooks()
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        local inv = Inv()
        if inv and inv.RegisterListener then
            inv.RegisterListener("FluxJunkOverlay", function(ctx)
                Overlay.ApplyDispatchContext(ctx)
            end, { tier = "light", regions = { "bags", "bank", "warband" }, sync = true })
        end
    else
        self:UnregisterEvent("BAG_UPDATE_DELAYED")
    end
end)

RegisterBankOpenPaint()
RegisterBagOpenPaint()

_G.FluxJunkOverlay = Overlay
return Overlay
