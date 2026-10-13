-- FluxBaganator_ItemViews.lua
-- Shared traversal for visible Baganator item buttons (no frozen mixin hooks).

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat

local trackedViews = {}

local KNOWN_VIEW_FRAME_PREFIXES = {
    "Baganator_SingleViewBackpackViewFrame",
    "Baganator_CategoryViewBackpackViewFrame",
    "Baganator_SingleViewBankView",
    "Baganator_CategoryViewBankView",
}

function Compat.TrackBaganatorView(view)
    if view then
        trackedViews[view] = true
    end
end

function Compat.ForEachVisibleBaganatorView(callback)
    if type(callback) ~= "function" then
        return
    end

    local seen = {}
    local function visit(view)
        if not view or seen[view] or not view.IsVisible or not view:IsVisible() then
            return
        end
        seen[view] = true
        Compat.TrackBaganatorView(view)
        callback(view)
    end

    for view in pairs(trackedViews) do
        visit(view)
    end

    for i = 1, 2 do
        for p = 1, #KNOWN_VIEW_FRAME_PREFIXES do
            visit(_G[KNOWN_VIEW_FRAME_PREFIXES[p] .. i])
        end
    end
end

function Compat.ResolveBaganatorItemButtonSlot(button)
    if not button then
        return
    end

    local bgr = button.BGR
    if bgr and bgr.itemLocation then
        local location = bgr.itemLocation
        if location.GetBagAndSlot then
            local ok, bagID, slotID = pcall(location.GetBagAndSlot, location)
            if ok and bagID and slotID then
                return bagID, slotID
            end
        end
        if location.bagID and location.slotIndex then
            return location.bagID, location.slotIndex
        end
        if location.bagID and location.slotID then
            return location.bagID, location.slotID
        end
    end

    if button.GetParent and button.GetID then
        local parent = button:GetParent()
        local slotID = button:GetID()
        if parent and parent.GetID and slotID and slotID > 0 then
            local bagID = parent:GetID()
            if bagID then
                return bagID, slotID
            end
        end
    end

    if button.GetBagID and button.GetID then
        local bagID = button:GetBagID()
        local slotID = button:GetID()
        if bagID and slotID and slotID > 0 then
            return bagID, slotID
        end
    end

    local lock = _G.FluxRespec and _G.FluxRespec.GearSetLock
    if lock and lock.ResolveBagSlotFromOwner then
        return lock.ResolveBagSlotFromOwner(button)
    end
end

function Compat.ForEachRegisteredBaganatorItemButton(callback)
    if type(callback) ~= "function" then
        return
    end
    local api = _G.Baganator and _G.Baganator.API
    local skins = api and api.Skins
    if not skins or not skins.GetAllFrames then
        return false
    end
    local frames = skins.GetAllFrames()
    if type(frames) ~= "table" then
        return false
    end
    local seen = {}
    for i = 1, #frames do
        local details = frames[i]
        local button = details and details.region
        if button and details.regionType == "ItemButton" and not seen[button] then
            seen[button] = true
            callback(button)
        end
    end
    return true
end

function Compat.ForEachBaganatorItemButton(callback)
    if type(callback) ~= "function" then
        return
    end
    local seen = {}
    local function visit(button)
        if button and not seen[button] then
            seen[button] = true
            callback(button)
        end
    end
    if Compat.ForEachRegisteredBaganatorItemButton(visit) then
        return
    end
    Compat.ForEachVisibleItemButton(visit)
end

local function ForEachCategoryLayoutButtons(layout, callback)
    if not layout or type(layout.buttons) ~= "table" then
        return
    end
    for b = 1, #layout.buttons do
        local button = layout.buttons[b]
        if button and not button.isDummy then
            callback(button)
        end
    end
end

local function ForEachButtonInActiveCategoryLayouts(view, callback)
    local activeLayouts = view and view.activeLayouts
    if type(activeLayouts) ~= "table" then
        return
    end
    for i = 1, #activeLayouts do
        ForEachCategoryLayoutButtons(activeLayouts[i], callback)
    end
end

local function ForEachButtonInVisibleCategoryLayouts(view, callback)
    local layouts = view and view.LiveLayouts
    if type(layouts) ~= "table" then
        return
    end
    for i = 1, #layouts do
        local layout = layouts[i]
        if layout and (not layout.IsVisible or layout:IsVisible()) then
            ForEachCategoryLayoutButtons(layout, callback)
        end
    end
end

local function ForEachButtonInBagLayout(layout, callback)
    if not layout or type(layout.buttonsByBag) ~= "table" then
        return
    end
    for _, bagButtons in pairs(layout.buttonsByBag) do
        if type(bagButtons) == "table" then
            for i = 1, #bagButtons do
                callback(bagButtons[i])
            end
        end
    end
end

local function ForEachButtonInSingleView(view, callback)
    local container = view and view.Container
    if not container then
        return
    end
    if container.BagLive then
        ForEachButtonInBagLayout(container.BagLive, callback)
    end
    if container.BagCached then
        ForEachButtonInBagLayout(container.BagCached, callback)
    end
    local collapsing = view.CollapsingBags
    if type(collapsing) == "table" then
        for i = 1, #collapsing do
            local group = collapsing[i]
            if group and group.live then
                ForEachButtonInBagLayout(group.live, callback)
            end
            if group and group.cached then
                ForEachButtonInBagLayout(group.cached, callback)
            end
        end
    end
end

function Compat.ForEachVisibleItemButton(callback)
    if type(callback) ~= "function" then
        return
    end
    local seenButtons = {}
    local function visit(button)
        if button and not seenButtons[button] then
            -- Registered skins include bank/warband pools that are not on screen.
            if button.IsShown and not button:IsShown() then
                return
            end
            seenButtons[button] = true
            callback(button)
        end
    end
    Compat.ForEachVisibleBaganatorView(function(view)
        ForEachButtonInActiveCategoryLayouts(view, visit)
        ForEachButtonInVisibleCategoryLayouts(view, visit)
        ForEachButtonInSingleView(view, visit)
    end)
    Compat.ForEachRegisteredBaganatorItemButton(visit)
end

function Compat.InitBaganatorViewTracking()
    if Compat._baganatorViewTrackingInitialized then
        return
    end
    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if not registry or not registry.RegisterCallback then
        return
    end
    Compat._baganatorViewTrackingInitialized = true

    local function ScanVisibleViews()
        Compat.ForEachVisibleBaganatorView(function()
        end)
    end

    registry:RegisterCallback("BagShow", ScanVisibleViews)
    registry:RegisterCallback("BackpackFrameChanged", ScanVisibleViews)
    -- Skip ViewComplete: bag transfers fire it constantly; BagShow/BackpackFrameChanged
    -- are enough to discover views.
end
