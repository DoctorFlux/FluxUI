--[[
    ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua
    TrinketMenu port for FluxUI - Two trinket slot buttons with class-colored styling
    Based on TrinketMenu addon with FluxUI visual integration
    
    Compatible with all WoW versions via Flux.Container / Flux.Item.
    Bag/equip awareness via Flux.Inventory (Syndicator or builtin snapshots).
]]

local addonName, ns = ...

-- Create namespace
FluxTrinketMenu = FluxTrinketMenu or {}
local TM = FluxTrinketMenu

local wipe = table.wipe or wipe

local function ItemInfo(item)
    if item == nil then
        return nil
    end
    local Flux = ns and ns.Flux
    if Flux and Flux.Item and Flux.Item.GetInfo then
        local a, b, c, d, e, f, g, h, i, j = Flux.Item.GetInfo(item)
        if type(a) == "table" then
            local t = a
            return t.itemName or t.name, t.itemLink or t.hyperlink, t.itemQuality or t.quality,
                t.itemLevel, t.itemMinLevel or t.minLevel, t.itemType, t.itemSubType,
                t.itemStackCount or t.stackCount, t.itemEquipLoc or t.invType,
                t.itemTexture or t.iconFileID
        end
        if a ~= nil or b ~= nil then
            return a, b, c, d, e, f, g, h, i, j
        end
    end
    if C_Item and C_Item.GetItemInfo then
        local ok, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10 = pcall(C_Item.GetItemInfo, item)
        if ok then
            if type(r1) == "table" then
                local t = r1
                return t.itemName or t.name, t.itemLink or t.hyperlink, t.itemQuality or t.quality,
                    t.itemLevel, t.itemMinLevel or t.minLevel, t.itemType, t.itemSubType,
                    t.itemStackCount or t.stackCount, t.itemEquipLoc or t.invType,
                    t.itemTexture or t.iconFileID
            end
            return r1, r2, r3, r4, r5, r6, r7, r8, r9, r10
        end
    end
    if GetItemInfo then
        return GetItemInfo(item)
    end
    return nil
end

-- Constants (matching NonCombatGrid/CombatGrid exactly)
TM.DEFAULT_BUTTON_SIZE = 45
TM.DEFAULT_SPACING = 0  -- Match NonCombatGrid GRID_SPACING
TM.DEFAULT_SCALE = 1 / 1.265
TM.BUTTON_SLOT_SIZE_MULTIPLIER = 1.2

-- Flyout arrow constants (engine TGA glyph)
TM.ARROW_TEX_COORDS = { 0.62500000, 0.98437500, 0.74218750, 0.82812500 }
TM.ARROW_SIZE_W = 23
TM.ARROW_SIZE_H = 11

-- Combat queue for trinket swaps
TM.CombatQueue = {}

-- Menu system
TM.BaggedTrinkets = {}
TM.NumberOfTrinkets = 0
TM.MaxTrinketMenuButtons = 30
TM.MenuFrame = nil
TM.MenuButtons = {}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get player class color
local function GetClassColor()
    local _, classFilename = UnitClass("player")
    return RAID_CLASS_COLORS[classFilename] or { r = 0.6, g = 0.6, b = 0.6 }
end

-- Retail/Midnight dropped the MouseIsOver global; Classic still has it.
local function FrameMouseOver(frame)
    if not frame then
        return false
    end
    if frame.IsForbidden and frame:IsForbidden() then
        return false
    end
    if frame.IsMouseOver then
        local ok, over = pcall(frame.IsMouseOver, frame)
        if ok then
            return over and true or false
        end
    end
    if MouseIsOver then
        local ok, over = pcall(MouseIsOver, frame)
        if ok and over then
            return true
        end
    end
    return false
end

local function GetThemedTrinketVertexRGB()
    if FluxBorder and FluxBorder.GetThemedVertexRGB then
        return FluxBorder:GetThemedVertexRGB()
    end
    local c = GetClassColor()
    return c.r, c.g, c.b
end

-- Get trinket info for a slot (13 = top trinket, 14 = bottom trinket)
function TM.GetTrinketInfo(slot)
    local link = GetInventoryItemLink("player", slot)
    local texture = GetInventoryItemTexture("player", slot)
    
    if not texture then
        -- Fallback to slot texture if no trinket equipped
        local _, slotTexture = GetInventorySlotInfo("Trinket" .. (slot - 13) .. "Slot")
        texture = slotTexture
    end
    
    local name = nil
    if link then
        name = ItemInfo(link)
    end
    
    return texture, name, link
end

-- Prefer Flux.Inventory carried bag IDs; fall back to FluxInv / Classic default.
local function _TM_GetCarriedBagIDs()
    local Flux = ns and ns.Flux
    local C = Flux and Flux.Inventory and Flux.Inventory.Containers
    if C and C.GetCarriedBagIDs then
        local ids = C.GetCarriedBagIDs()
        if type(ids) == "table" and #ids > 0 then
            return ids
        end
    end
    local inv = _G.FluxInv
    if inv and inv.GetCarriedBagIDs then
        local ids = inv.GetCarriedBagIDs()
        if type(ids) == "table" and #ids > 0 then
            return ids
        end
    end
    local maxBag = 4
    if ns and ns.API and ns.API.GetMaxBagIndex then
        maxBag = ns.API.GetMaxBagIndex()
    end
    local ids = {}
    for bag = 0, maxBag do
        ids[#ids + 1] = bag
    end
    return ids
end

-- Flux perf T2.13: cache trinket bag locations by itemID keyed on the last
-- successful scan. Rebuilt on every ScanBagsForTrinkets (fired on bag/equip
-- via FluxInv listener in the Manager). FindTrinketInBags can then resolve a
-- name->location lookup in O(1) instead of re-scanning every bag slot.
TM._trinketBagCacheByItemID = TM._trinketBagCacheByItemID or {}
TM._trinketBagCacheByName = TM._trinketBagCacheByName or {}

-- Find trinket in bags by name (or by itemID if a number is passed)
function TM.FindTrinketInBags(name)
    if not name then return nil, nil end

    -- Fast path: cached from the last bag scan.
    if type(name) == "number" then
        local byId = TM._trinketBagCacheByItemID[name]
        if byId then
            return byId.bag, byId.slot
        end
        local Flux = ns and ns.Flux
        local Inv = Flux and Flux.Inventory
        if Inv and Inv.Find then
            local locs = Inv.Find(name, { bags = true, bank = false, warband = false, equipped = false })
            local loc = locs and locs[1]
            if loc then
                return loc.bag, loc.slot
            end
        end
        local inv = _G.FluxInv
        if inv and inv.FindItem then
            local locs = inv.FindItem(name, { bags = true, bank = false, warband = false, equipped = false })
            local loc = locs and locs[1]
            if loc then
                return loc.bag, loc.slot
            end
        end
        return nil, nil
    end

    local cached = TM._trinketBagCacheByName[name]
    if cached then
        return cached.bag, cached.slot
    end

    local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local GetContainerItemLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink

    for _, bag in ipairs(_TM_GetCarriedBagIDs()) do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink and string.find(itemLink, name, 1, true) then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

-- Check if player is really dead (not feign death when that API exists)
function TM.IsPlayerReallyDead()
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
        if UnitIsFeignDeath and UnitIsFeignDeath("player") then
            return false
        end
        return true
    end
    return false
end

-- Post-DF: defensive tooltip cleanup before hide (clears comparison tooltips)
function TM.HideTrinketTooltip()
    if ShoppingTooltip1 then ShoppingTooltip1:Hide() end
    if ShoppingTooltip2 then ShoppingTooltip2:Hide() end
    if GameTooltip then GameTooltip:Hide() end
end

-- Get slot frame from button (handles both FluxButton and fallback)
local function GetSlotFrame(button)
    return button and (button.SlotFrame or button.slotFrame)
end

local function TMFlyout()
    local EBS = ns and ns.Flux and ns.Flux.EBS
    return EBS and EBS.Flyout
end

function TM.SlotWidget(index)
    local btn = TM.Buttons and TM.Buttons[index]
    return btn and (btn.Widget or btn) or nil
end

function TM.GetVisibleSlotWidget()
    local slot0 = GetSlotFrame(TM.Buttons and TM.Buttons[0])
    if slot0 and slot0:IsShown() then
        return TM.SlotWidget(0)
    end
    local slot1 = GetSlotFrame(TM.Buttons and TM.Buttons[1])
    if slot1 and slot1:IsShown() then
        return TM.SlotWidget(1)
    end
    return TM.SlotWidget(0)
end

local function TrinketFlyoutOpts(cols)
    return {
        direction = "UP",
        columns = cols or 1,
        cellSize = 42,
        spacing = 2,
        padding = 6,
        arrowTint = { 0.2, 1.0, 0.2 },
        desaturate = true,
        adoptHostCast = false,
        -- Whole column (both slots), same as the old MenuFrame.
        anchorFrame = TM.Frame,
        placePoint = "BOTTOMRIGHT",
        placeRelPoint = "TOPRIGHT",
        placeX = -4,
        placeY = 6,
        matchAnchorScale = true,
    }
end

local function BindTrinketFlyout(widget)
    local Flyout = TMFlyout()
    if not Flyout or not widget or not Flyout.BindHost then
        return
    end
    Flyout.BindHost(widget, TrinketFlyoutOpts(1))
end

local function EngineArrow(widget)
    if not widget then
        return nil
    end
    return widget.FluxFlyoutArrow or widget.FluxTrinketMenuArrow
end

-- ============================================================================
-- TRINKET GRID CREATION
-- ============================================================================

--- Reposition trinket flyout arrows after squeeze or when unified border reparents.
function TM.RefreshArrowLayersOnBorder()
    local Flyout = TMFlyout()
    if Flyout and Flyout.RefreshArrowLayers then
        Flyout.RefreshArrowLayers()
    end
    for i = 0, 1 do
        local w = TM.SlotWidget(i)
        local arrow = EngineArrow(w)
        if arrow and w then
            if Flyout and Flyout.Arrow and Flyout.Arrow.ConfigureLayer then
                Flyout.Arrow.ConfigureLayer(arrow, w)
            end
            arrow:ClearAllPoints()
            arrow:SetPoint("TOP", w, "TOP", 0, 6)
        end
    end
end

--- Resize trinket column width (X-only) to match FluxUILayoutSqueeze when at min UI scale + overlap.
function TM.ApplyHorizontalSqueeze()
    if not TM.Frame then return end
    if InCombatLockdown and InCombatLockdown() then
        if Flux and Flux.Combat and Flux.Combat.Defer then
            Flux.Combat.Defer("trinket.squeeze", TM.ApplyHorizontalSqueeze)
        end
        return
    end
    local baseSlot = TM._baseSlotWidth or TM.SlotSize
    if not baseSlot or baseSlot <= 0 then return end
    -- Same X squeeze as FluxMainActionBar: column width and widget face width. Vertical spacing stays Y.
    local xF = (FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor and FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor()) or 1
    local slotW = baseSlot * xF
    local height = TM._baseFrameHeight
    if not height and TM.Frame.GetHeight then
        height = TM.Frame:GetHeight()
    end
    TM.Frame:SetWidth(slotW)
    if height then
        TM.Frame:SetHeight(height)
    end
    local mult = TM.BUTTON_SLOT_SIZE_MULTIPLIER or 1.2
    local sp = TM.Spacing or 0
    local centerOffset = (baseSlot + sp) / 2
    -- Must match UpdateTrinketVisibility: single-slot states use vertical center in the 2-row frame.
    local vis = TM.VisibilityState
    if not vis or vis == "none" then
        vis = "both_equipped"
    end
    local btnSize = TM.ButtonSize or TM.DEFAULT_BUTTON_SIZE
    for i = 0, 1 do
        local btn = TM.Buttons and TM.Buttons[i]
        local sf = btn and (btn.SlotFrame or btn.slotFrame)
        if sf then
            sf:SetSize(slotW, baseSlot)
            if sf.SetClipsChildren then
                -- Pre-DF Quickslot2 ring overhangs the slot; clipping hides it.
                local clip = xF < 1
                if (FLUX_API and (FLUX_API.isAnyClassic or FLUX_API.isPostDF == false))
                    or (Flux.Client and (Flux.Client.isAnyClassic or Flux.Client.isPostDF == false)) then
                    clip = false
                end
                sf:SetClipsChildren(clip)
            end
            local yOff
            if vis == "both_equipped" then
                yOff = (1 - i) * (baseSlot + sp)
            elseif vis == "bag_only" then
                yOff = (i == 0) and centerOffset or 0
            elseif vis == "one_equipped" then
                local equipped = TM.GetEquippedTrinketSlots()
                local eq = equipped[1]
                if eq == 13 then
                    yOff = (i == 0) and centerOffset or 0
                elseif eq == 14 then
                    yOff = (i == 1) and centerOffset or 0
                else
                    yOff = (1 - i) * (baseSlot + sp)
                end
            else
                yOff = (1 - i) * (baseSlot + sp)
            end
            sf:ClearAllPoints()
            sf:SetPoint("BOTTOMLEFT", TM.Frame, "BOTTOMLEFT", 0, yOff)
        end
        if btn and btn.Widget then
            local faceW = btnSize * xF
            if btn.Widget.SetSize then
                btn.Widget:SetSize(faceW, btnSize)
            end
            if btn.Widget.SetScale then
                btn.Widget:SetScale(mult)
            end
            local Style = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Style
            if Style and Style.RefreshSqueezeChrome then
                Style.RefreshSqueezeChrome(btn, faceW, btnSize)
            elseif FluxButtonUtil and FluxButtonUtil.SyncFluxButtonLayerSizesToWidget then
                FluxButtonUtil:SyncFluxButtonLayerSizesToWidget(btn)
            end
        elseif btn and btn.SetScale then
            btn:SetSize(btnSize * xF, btnSize)
            btn:SetScale(mult)
            btn._fluxScaleApplied = nil
            if FluxActionBarAnisoHelpers and FluxActionBarAnisoHelpers.ScaleButtonTextures then
                FluxActionBarAnisoHelpers.ScaleButtonTextures(btn, btnSize * xF, btnSize)
            else
                local nt = btn.NormalTexture or (btn.GetName and _G[btn:GetName() .. "NormalTexture"])
                if nt and nt.SetSize then
                    local lw, lh = btnSize * xF, btnSize
                    if lw > 0 and lh > 0 then
                        -- Post-DF (Forever + Midnight): IconFrame scale — not legacy 1.65.
                        -- Forever is 1.x; never use majorVersion >= 10 here.
                        local isDF = FLUX_API and FLUX_API.isPostDF
                        if isDF then
                            nt:SetSize(lw * (46 / 44), lh * (45 / 44))
                        else
                            nt:SetSize(lw * 1.65, lh * 1.65)
                        end
                        nt:ClearAllPoints()
                        nt:SetPoint("CENTER", btn, "CENTER", 0, 0)
                    end
                end
                local br = btn.Border or (btn.GetName and _G[btn:GetName() .. "Border"])
                if br and br.SetSize then
                    local w, h = btn:GetWidth(), btn:GetHeight()
                    if w and h then
                        br:SetSize(w, h)
                        br:ClearAllPoints()
                        br:SetPoint("CENTER", btn, "CENTER", 0, 0)
                    end
                end
                local cd = btn.Cooldown or btn.cooldown
                if cd and FluxButtonUtil and FluxButtonUtil.ApplyCooldownCountdownHorizontalScale then
                    FluxButtonUtil:ApplyCooldownCountdownHorizontalScale(cd, btn, btnSize * xF, btnSize)
                end
            end
        end
    end
    if TM.ScaleHost and TM.ScaleHost:IsObjectType("Frame") and TM.Frame then
        TM.ScaleHost:SetSize(math.max(1, TM.Frame:GetWidth()), math.max(1, TM.Frame:GetHeight()))
    end
    if FluxBorder and TM.Frame then
        FluxBorder:ApplyTo(TM.Frame, 0, -4, 0, -4)
        FluxBorder:SetClassColor(TM.Frame, 1, true)
    end
    
    TM.RefreshArrowLayersOnBorder()
end

function TM.CreateGrid(parent)
    parent = parent or UIParent
    
    local size = TM.DEFAULT_BUTTON_SIZE
    local spacing = TM.DEFAULT_SPACING
    local scale = TM.DEFAULT_SCALE
    local slotSize = size * TM.BUTTON_SLOT_SIZE_MULTIPLIER

    local scaleHost = CreateFrame("Frame", "FluxTrinketMenuScaleHost", parent)
    scaleHost:SetFrameStrata("MEDIUM")
    TM.ScaleHost = scaleHost
    
    -- Create container frame (child of scaleHost so Manager can anchor the host)
    local gridFrame = CreateFrame("Frame", "FluxTrinketMenuFrame", scaleHost, BackdropTemplateMixin and "BackdropTemplate" or nil)
    gridFrame:SetClampedToScreen(true)
    gridFrame:SetScale(scale)
    
    -- Size for 1 column, 2 rows (vertical layout)
    local width = slotSize
    local height = (slotSize * 2) + spacing
    gridFrame:SetSize(width, height)
    TM._baseSlotWidth = slotSize
    TM._baseFrameWidth = width
    TM._baseFrameHeight = height

    gridFrame:SetPoint("BOTTOMLEFT", scaleHost, "BOTTOMLEFT", 0, 0)
    scaleHost:SetSize(width, height)
    
    -- Apply FluxBorder (match NonCombatGrid/CombatGrid exactly)
    if FluxBorder then
        FluxBorder:ApplyTo(gridFrame, 0, -4, 0, -4)
        FluxBorder:SetClassColor(gridFrame, 1, true)
    end
    
    -- Store reference
    TM.Frame = gridFrame
    TM.Buttons = {}
    TM.ButtonSize = size
    TM.SlotSize = slotSize
    TM.Spacing = spacing

    gridFrame:SetScript("OnShow", function()
        if TM.SyncKeybindPushWatch then
            TM.SyncKeybindPushWatch()
        end
    end)
    gridFrame:SetScript("OnHide", function()
        if TM.SyncKeybindPushWatch then
            TM.SyncKeybindPushWatch()
        end
    end)
    
    -- Create trinket buttons
    -- Slot 13 (index 0) at TOP, Slot 14 (index 1) at BOTTOM
    TM.CreateTrinketButton(0, 13) -- Top trinket (slot 13)
    TM.CreateTrinketButton(1, 14) -- Bottom trinket (slot 14)

    TM.ApplyHorizontalSqueeze()
    if TM.SyncKeybindPushWatch then
        TM.SyncKeybindPushWatch()
    end
    
    return gridFrame
end

-- ============================================================================
-- TRINKET BUTTON CREATION (rewrite Extra Button widgets)
-- ============================================================================

local function FluxEBS()
    return ns and ns.Flux and ns.Flux.EBS
end

-- Keybinds do not fire PreClick/OnMouseDown. HUD click wrap swallows mouse-up
-- so the use fires on press. Flyout still opens from OnMouseDown. Push visuals must not lock
-- PUSHED: IsKeyDown can miss a release (wheel binds, focus loss) and a
-- locked state sticks. Hold while the bind/mouse is down, cap at 1.5s,
-- and always clear when the input is gone.
local keyPushWatch = CreateFrame("Frame")
keyPushWatch:Hide()
local presses = {}
local HOLD_SAFETY_CAP = 1.5
local TAP_FLASH = 0.2
local MOUSE_BIND = {
    BUTTON1 = "LeftButton",
    BUTTON2 = "RightButton",
    BUTTON3 = "MiddleButton",
    BUTTON4 = "Button4",
    BUTTON5 = "Button5",
}

local function TrinketBareKey(chord)
    if type(chord) ~= "string" or chord == "" then
        return nil
    end
    return chord:match("([^-]+)$") or chord
end

local function ChordIsPhysicallyDown(chord)
    if type(chord) ~= "string" or chord == "" then
        return false
    end
    local bare = TrinketBareKey(chord)
    if not bare then
        return false
    end
    local up = string.upper(bare)
    if up == "MOUSEWHEELUP" or up == "MOUSEWHEELDOWN" then
        return false
    end
    local mouseBtn = MOUSE_BIND[up]
    if mouseBtn and IsMouseButtonDown then
        local ok, down = pcall(IsMouseButtonDown, mouseBtn)
        if not ok or not down then
            return false
        end
    else
        if not IsKeyDown then
            return false
        end
        local ok, down = pcall(IsKeyDown, bare)
        if not ok or not down then
            return false
        end
    end
    local nk = string.upper(chord)
    local shift = IsShiftKeyDown and IsShiftKeyDown()
    local ctrl = IsControlKeyDown and IsControlKeyDown()
    local alt = IsAltKeyDown and IsAltKeyDown()
    if nk:find("SHIFT%-CTRL%-", 1, false) or nk:find("CTRL%-SHIFT%-", 1, false) then
        return shift and ctrl
    end
    if nk:match("^SHIFT%-") then
        return shift and not ctrl
    end
    if nk:match("^CTRL%-") then
        return ctrl and not shift
    end
    if nk:match("^ALT%-") then
        return alt and true or false
    end
    return not shift and not ctrl and not alt
end

local function BindingIsDown(bindIndex)
    if not GetBindingKey then
        return false
    end
    local keys = { GetBindingKey("FLUXTRINKET" .. bindIndex) }
    for i = 1, #keys do
        if ChordIsPhysicallyDown(keys[i]) then
            return true
        end
    end
    return false
end

function TM.WidgetForTrinketBind(bindIndex)
    local state = TM.VisibilityState or (TM.GetTrinketVisibilityState and TM.GetTrinketVisibilityState())
    local w0 = TM.SlotWidget and TM.SlotWidget(0)
    local w1 = TM.SlotWidget and TM.SlotWidget(1)
    if state == "none" or state == "bag_only" then
        return nil
    end
    if state == "one_equipped" then
        local equipped = TM.GetEquippedTrinketSlots and TM.GetEquippedTrinketSlots()
        if equipped and equipped[1] == 13 then
            return w0
        end
        return w1
    end
    if bindIndex == 1 then
        return w0
    end
    return w1
end

local function WidgetBindHeld(widget)
    for i = 1, 2 do
        if BindingIsDown(i) and TM.WidgetForTrinketBind(i) == widget then
            return true
        end
    end
    return false
end

local function MouseLeftHeld()
    if not IsMouseButtonDown then
        return false
    end
    local ok, down = pcall(IsMouseButtonDown, "LeftButton")
    return ok and down and true or false
end

local function EnsurePushShade(widget)
    local shade = widget._fluxTrinketPushShade
    if shade then
        return shade
    end
    shade = widget:CreateTexture(nil, "OVERLAY", nil, 7)
    shade:SetAllPoints(widget)
    shade:SetColorTexture(0, 0, 0, 0.45)
    shade:Hide()
    widget._fluxTrinketPushShade = shade
    return shade
end

local function RestoreTrinketPushIcon(widget)
    local btn = widget.FluxButton
    local icon = (btn and btn.WIcon) or widget.icon or widget.Icon
    if widget._fluxTrinketPushDimmed and icon and icon.SetVertexColor and widget._fluxTrinketPushIconColor then
        local c = widget._fluxTrinketPushIconColor
        icon:SetVertexColor(c[1], c[2], c[3])
        widget._fluxTrinketPushDimmed = nil
        widget._fluxTrinketPushIconColor = nil
    end
end

local function ClearTrinketPush(widget)
    if not widget then
        return
    end
    presses[widget] = nil
    widget._fluxTrinketMouseDown = nil
    if widget.SetButtonState then
        pcall(widget.SetButtonState, widget, "NORMAL", false)
    end
    if widget.UnlockHighlight then
        pcall(widget.UnlockHighlight, widget)
    end
    local pt = widget.PushedTexture or (widget.GetPushedTexture and widget:GetPushedTexture())
    if pt and pt.Hide then
        pcall(pt.Hide, pt)
    end
    RestoreTrinketPushIcon(widget)
    local shade = widget._fluxTrinketPushShade
    if shade then
        shade:Hide()
    end
end

local function ApplyTrinketPushVisual(widget)
    if not widget then
        return
    end
    -- Do not lock PUSHED: a missed key-up would stick the atlas forever.
    if widget.SetButtonState then
        pcall(widget.SetButtonState, widget, "PUSHED", false)
    end
    local pt = widget.PushedTexture or (widget.GetPushedTexture and widget:GetPushedTexture())
    if pt and pt.Show then
        pcall(pt.Show, pt)
    end
    local btn = widget.FluxButton
    local icon = (btn and btn.WIcon) or widget.icon or widget.Icon
    if icon and icon.SetVertexColor and not widget._fluxTrinketPushDimmed then
        local r, g, b = icon:GetVertexColor()
        widget._fluxTrinketPushIconColor = { r, g, b }
        widget._fluxTrinketPushDimmed = true
        icon:SetVertexColor(r * 0.62, g * 0.62, b * 0.62)
    end
    EnsurePushShade(widget):Show()
end

local function NoteTrinketPushed(widget, reason)
    if not widget then
        return
    end
    local rec = presses[widget]
    if rec and rec.capped then
        return
    end
    if not rec then
        rec = { t0 = (GetTime and GetTime()) or 0 }
        presses[widget] = rec
    end
    if reason == "mouse" then
        rec.mouse = true
        widget._fluxTrinketMouseDown = true
    else
        -- KeyBind / wheel ticks have no OnMouseDown. Keep the same shade as a
        -- click for at least TAP_FLASH so a missed IsKeyDown does not wipe it.
        rec.untilClear = math.max(rec.untilClear or 0, ((GetTime and GetTime()) or 0) + TAP_FLASH)
    end
    ApplyTrinketPushVisual(widget)
end

local function EnsureHandler(widget, handler)
    if widget.GetScript and not widget:GetScript(handler) then
        widget:SetScript(handler, function() end)
    end
end

local function FlushTrinketPushes()
    local leftover = {}
    for widget in pairs(presses) do
        leftover[#leftover + 1] = widget
    end
    for i = 1, #leftover do
        ClearTrinketPush(leftover[i])
    end
    wipe(presses)
end

function TM.SyncKeybindPushWatch()
    if TM.Frame and TM.Frame.IsShown and TM.Frame:IsShown() then
        keyPushWatch:Show()
        return
    end
    keyPushWatch:Hide()
    FlushTrinketPushes()
end

local function ReleaseMousePresses()
    local now = (GetTime and GetTime()) or 0
    local toClear = {}
    for widget, rec in pairs(presses) do
        rec.mouse = nil
        if widget then
            widget._fluxTrinketMouseDown = nil
        end
        if rec and not WidgetBindHeld(widget) then
            rec.t0 = math.min(rec.t0 or now, now - TAP_FLASH)
            toClear[#toClear + 1] = widget
        end
    end
    for i = 1, #toClear do
        ClearTrinketPush(toClear[i])
    end
end

keyPushWatch:RegisterEvent("GLOBAL_MOUSE_UP")
keyPushWatch:RegisterEvent("MODIFIER_STATE_CHANGED")
keyPushWatch:SetScript("OnEvent", function(_, event)
    if event == "GLOBAL_MOUSE_UP" then
        if C_Timer and C_Timer.After then
            C_Timer.After(0, ReleaseMousePresses)
        else
            ReleaseMousePresses()
        end
        return
    end
    -- Modifier flip: OnUpdate re-evaluates chords next frame.
end)

keyPushWatch:SetScript("OnUpdate", function()
    local now = (GetTime and GetTime()) or 0
    local keyHeld = {}
    for i = 1, 2 do
        if BindingIsDown(i) then
            local widget = TM.WidgetForTrinketBind(i)
            if widget then
                keyHeld[widget] = true
                NoteTrinketPushed(widget, "key")
            end
        end
    end
    local toClear = {}
    for widget, rec in pairs(presses) do
        local age = now - (rec.t0 or now)
        if rec.capped then
            if not keyHeld[widget] then
                rec.capped = nil
                toClear[#toClear + 1] = widget
            end
        elseif age >= HOLD_SAFETY_CAP then
            rec.capped = true
            toClear[#toClear + 1] = widget
        elseif keyHeld[widget] then
            ApplyTrinketPushVisual(widget)
        elseif rec.mouse and MouseLeftHeld() then
            ApplyTrinketPushVisual(widget)
        elseif rec.mouse then
            -- Mouse-up lands before OnClick. Clearing PUSHED in this
            -- handler would cancel /use; wait a tick.
            rec.mouse = nil
            rec.untilClear = now + TAP_FLASH
            if widget then
                widget._fluxTrinketMouseDown = nil
            end
        elseif rec.untilClear and now < rec.untilClear then
            ApplyTrinketPushVisual(widget)
        elseif age < TAP_FLASH then
            ApplyTrinketPushVisual(widget)
        else
            toClear[#toClear + 1] = widget
        end
    end
    for i = 1, #toClear do
        local widget = toClear[i]
        local rec = presses[widget]
        local capped = rec and rec.capped
        ClearTrinketPush(widget)
        if capped then
            presses[widget] = { t0 = now, capped = true }
        end
    end
end)

function TM.HookTrinketClickScripts(widget)
    if not widget or widget._fluxTrinketClicksHooked then
        return
    end
    widget._fluxTrinketClicksHooked = true

    EnsureHandler(widget, "OnMouseDown")
    widget:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            TM.BuildMenu(self)
            return
        end
        NoteTrinketPushed(self, "mouse")
    end)

    -- Keybinds (including ALT-MOUSEWHEEL) never fire OnMouseDown. Paint the
    -- same push shade on the click the override actually delivers.
    EnsureHandler(widget, "OnClick")
    widget:HookScript("OnClick", function(self, button, down)
        if button == "RightButton" or not down then
            return
        end
        NoteTrinketPushed(self, "click")
    end)

    widget:HookScript("PostClick", function(self)
        if self.SetChecked then
            self:SetChecked(false)
        end
    end)
end

-- /use 13 parses as remainder "13" (a spell id). Pin the paperdoll item so
-- Extra paint does not show that spell after SetAction/TranslateMacro.
function TM.SyncEquippedFace(button)
    if not button then
        return
    end
    local slot = button.inventorySlot
    local itemID = slot and GetInventoryItemID and GetInventoryItemID("player", slot)
    button.SpellId = nil
    button.MacroTexture = nil
    if itemID then
        button.MacroMode = "item"
        button.ItemId = itemID
        button._fluxManagedFaceItemId = itemID
        button._fluxManagedFaceSpellId = nil
    else
        button.MacroMode = ""
        button.ItemId = nil
        button._fluxManagedFaceItemId = nil
        button._fluxManagedFaceSpellId = nil
    end
end

function TM.CreateTrinketButton(index, inventorySlot)
    local slotSize = TM.SlotSize
    local spacing = TM.DEFAULT_SPACING
    local scaleMultiplier = TM.BUTTON_SLOT_SIZE_MULTIPLIER
    local btnSize = TM.ButtonSize
    
    -- Slot frame (wrapper)
    local slotFrame = CreateFrame("Frame", nil, TM.Frame)
    slotFrame:SetSize(slotSize, slotSize)
    
    -- Position: Slot 13 (index 0) at TOP, Slot 14 (index 1) at BOTTOM
    local yOffset = (1 - index) * (slotSize + spacing)
    slotFrame:SetPoint("BOTTOMLEFT", TM.Frame, "BOTTOMLEFT", 0, yOffset)
    
    -- Create button — rewrite Extra Button widget, skip Extra-window scripts.
    local btn = nil
    local EBS = FluxEBS()
    local createFn = (EBS and EBS.Widget and EBS.Widget.Create)
        or (FluxBtn and FluxBtn.Create)
        or (FluxButton and FluxButton.New)
    local useFluxButton = createFn ~= nil
    
    if useFluxButton then
        local fluxConfig = {
            name = "FluxTrinketMenu_Trinket" .. index,
            size = btnSize,
            kind = "extra",
            skipScripts = true,
            skipMouseover = true,
            locked = true,
            clickBehavior = "AnyDown",
            showBorder = true,
            tooltip = false,
            macroText = false,
        }
        btn = createFn(slotFrame, fluxConfig)
        
        if btn and btn.Widget then
            -- Scale/Position to match CombatGrid look
            btn.Widget:SetScale(scaleMultiplier)
            btn.Widget:ClearAllPoints()
            btn.Widget:SetPoint("CENTER", slotFrame, "CENTER", 0, 0)
            if slotFrame.SetClipsChildren then
                pcall(slotFrame.SetClipsChildren, slotFrame, false)
            end
            
            btn.SlotFrame = slotFrame
            
            if EBS and EBS.Style and EBS.Style.Apply then
                EBS.Style.Apply(btn, "class")
            elseif FluxButtonUtil and FluxButtonUtil.ApplyButtonStyle then
                FluxButtonUtil:ApplyButtonStyle(btn, "class")
            end
            
            -- Secure use of the paperdoll slot. Empty-slot safe (not type=item).
            if EBS and EBS.Action and EBS.Action.SetAction then
                EBS.Action.SetAction(btn, "macrotext", "/use " .. inventorySlot)
            else
                btn.Widget:SetAttribute("type", "macro")
                btn.Widget:SetAttribute("macrotext", "/use " .. inventorySlot)
            end
            -- Block right-click from using trinket (use for menu instead)
            btn.Widget:SetAttribute("type2", "macro")
            btn.Widget:SetAttribute("macrotext2", "/")
            btn.Widget:SetAttribute("typerelease", "macro")
            -- skipScripts skips Extra drag scripts AND Click.Apply. Without the
            -- wrap, AnyDown+AnyUp fires PreClick twice and Toggle opens then closes.
            local Click = ns and ns.Flux and ns.Flux.ButtonFX and ns.Flux.ButtonFX.Click
            if Click and Click.Apply then
                Click.Apply(btn.Widget, { onDown = true })
            else
                btn.Widget:RegisterForClicks("AnyUp", "AnyDown")
            end
            local G = ns and ns.Flux and ns.Flux.ButtonFX and ns.Flux.ButtonFX.Glow
            if G and G.NotifySAO then
                G.NotifySAO(btn.Widget)
            end
            
            -- Store references
            btn.inventorySlot = inventorySlot
            btn.index = index
            btn.categoryScope = btn.categoryScope or "class"
            btn.locked = true
            TM.SyncEquippedFace(btn)

            btn.UpdateUsable = function(self)
                TM.ApplyTrinketUsability(self)
            end
            -- Slots are always equipped items; never show the green equip glow.
            btn.UpdateEquipped = function(self)
                TM.HideEquippedGreenBorder(self)
            end
            TM.HideEquippedGreenBorder(btn)
            
            -- Setup scripts for tooltip and right-click menu
            -- Override any existing OnEnter/OnLeave handlers
            btn.Widget:SetScript("OnEnter", function(self)
                -- Set UpdateTooltip callback for live updates
                btn.Widget.UpdateTooltip = function()
                    TM.ShowTrinketTooltip(btn)
                end
                
                -- Show initial tooltip
                TM.ShowTrinketTooltip(btn)
                
                -- Start ticker for live updates (1 second interval)
                if btn.TooltipTicker and btn.TooltipTicker.Cancel then
                    btn.TooltipTicker:Cancel()
                end
                btn.TooltipTicker = C_Timer.NewTicker(1, function()
                    if not btn.Widget then return end
                    local owned = (GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(btn.Widget))
                    if owned then
                        if btn.Widget.UpdateTooltip then
                            btn.Widget:UpdateTooltip()
                        else
                            TM.ShowTrinketTooltip(btn)
                        end
                    else
                        if btn.TooltipTicker and btn.TooltipTicker.Cancel then
                            btn.TooltipTicker:Cancel()
                            btn.TooltipTicker = nil
                        end
                    end
                end)
            end)
            
            btn.Widget:SetScript("OnLeave", function(self)
                -- Stop ticker
                if btn.TooltipTicker and btn.TooltipTicker.Cancel then
                    btn.TooltipTicker:Cancel()
                    btn.TooltipTicker = nil
                end
                TM.HideTrinketTooltip()
            end)
            
            -- Also disable FluxButton's tooltip update if it has one
            if btn.DisableTooltip then
                btn:DisableTooltip()
            end
            
            TM.HookTrinketClickScripts(btn.Widget)
            
            -- Store in buttons table
            TM.Buttons[index] = btn
            
            -- Add flyout arrow to both trinkets (needed when only slot 2 is visible in one_equipped)
            TM.CreateFlyoutArrow(btn)
            
            -- Initial update
            TM.UpdateTrinketButton(btn)
            
            return btn
        end
    end
    
    -- Fallback: Use ActionButtonTemplate if FluxButton unavailable
    local buttonName = "FluxTrinketMenu_Trinket" .. index
    local button = CreateFrame("CheckButton", buttonName, slotFrame, "ActionButtonTemplate,SecureActionButtonTemplate")
    local Action = ns and ns.Flux and ns.Flux.Action
    if Action and Action.DetachFromCollectors then
        Action.DetachFromCollectors(button)
    end
    button:SetSize(btnSize, btnSize)
    button:SetScale(scaleMultiplier)
    button:SetPoint("CENTER", slotFrame, "CENTER", 0, 0)
    
    -- Set secure attributes for trinket use
    -- Use macro instead of item type to avoid errors with empty slots
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", "/use " .. inventorySlot)
    -- Block right-click from using trinket (use for menu instead)
    button:SetAttribute("type2", "macro")
    button:SetAttribute("macrotext2", "/")
    button:SetAttribute("typerelease", "macro")
    local Click = ns and ns.Flux and ns.Flux.ButtonFX and ns.Flux.ButtonFX.Click
    if Click and Click.Apply then
        Click.Apply(button, { onDown = true })
    else
        button:RegisterForClicks("AnyUp", "AnyDown")
    end
    
    -- Store references
    button.inventorySlot = inventorySlot
    button.slotFrame = slotFrame
    button.SlotFrame = slotFrame -- For compatibility with UpdateTrinketVisibility
    button.index = index
    button.Widget = button -- For compatibility
    button.categoryScope = "class"
    button.UpdateUsable = function(self)
        TM.ApplyTrinketUsability(self)
    end
    button.UpdateEquipped = function(self)
        TM.HideEquippedGreenBorder(self)
    end
    
    -- Get button elements
    local icon = _G[buttonName .. "Icon"] or button.icon
    local cooldown = _G[buttonName .. "Cooldown"] or button.cooldown
    local normalTexture = _G[buttonName .. "NormalTexture"] or button.NormalTexture
    local hotKey = _G[buttonName .. "HotKey"] or button.HotKey
    local count = _G[buttonName .. "Count"] or button.Count
    local equipBorder = _G[buttonName .. "Border"] or button.Border
    
    -- Store element references
    button.Icon = icon
    button.Cooldown = cooldown
    button.NormalTexture = normalTexture
    button.HotKey = hotKey
    button.Count = count
    button.WBorder = equipBorder
    button.Border = equipBorder
    
    -- Hide elements we don't need
    if count then count:Hide() end
    if hotKey then hotKey:SetText("") end
    TM.HideEquippedGreenBorder(button)
    
    -- Apply class color tint to normal texture (border) - match size properly
    if normalTexture then
        local r, g, b = GetThemedTrinketVertexRGB()
        normalTexture:SetVertexColor(r, g, b, 1)
        -- Ensure proper sizing for border
        normalTexture:ClearAllPoints()
        normalTexture:SetPoint("TOPLEFT", button, "TOPLEFT", -15, 15)
        normalTexture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 15, -15)
    end
    
    -- Set cooldown swipe color
    if cooldown then
        if cooldown.SetSwipeColor then
            cooldown:SetSwipeColor(0, 0, 0, 0.8)
        end
    end
    
    -- Setup scripts
    TM.SetupButtonScripts(button)
    
    -- Store in buttons table
    TM.Buttons[index] = button
    
    -- Initial update
    TM.UpdateTrinketButton(button)
    
    return button
end

-- ============================================================================
-- FLYOUT ARROW CREATION
-- ============================================================================

function TM.CreateFlyoutArrow(button)
    if not button then return nil end

    local widget = button.Widget or button
    if not widget then return nil end

    BindTrinketFlyout(widget)
    local Flyout = TMFlyout()
    local arrow = EngineArrow(widget)
    if not arrow and Flyout and Flyout.Arrow and Flyout.Arrow.Ensure then
        arrow = Flyout.Arrow.Ensure(widget, Flyout.HostOf and Flyout.HostOf(widget) and Flyout.HostOf(widget).opts)
    end
    if arrow then
        widget.FluxTrinketMenuArrow = arrow
        button.FluxTrinketMenuArrow = arrow
        arrow:Hide()
    end
    return arrow
end

function TM.UpdateArrowRotation(isOpen)
    local widget = TM.GetVisibleSlotWidget()
    local Flyout = TMFlyout()
    if Flyout and Flyout.Arrow and Flyout.Arrow.SetOpen and widget then
        Flyout.Arrow.SetOpen(widget, isOpen and true or false)
        return
    end
    local arrow = EngineArrow(widget)
    if not arrow or not arrow.texture then return end
    if SetClampedTextureRotation then
        SetClampedTextureRotation(arrow.texture, isOpen and 180 or 0)
    end
end

function TM.UpdateArrowVisibility()
    if not TM.Buttons then return end

    local Flyout = TMFlyout()
    -- FluxFlyoutArrow is a SecureActionButton. Show/Hide/SetSize taint in combat.
    if Flyout and Flyout.InLockdown and Flyout.InLockdown() then
        if Flyout.Defer then
            Flyout.Defer("trinket.arrow.vis", TM.UpdateArrowVisibility)
        end
        return
    end
    local fbm = _G.FluxBindingMode
    if fbm and fbm.ShouldForceShowAllExtraSlots and fbm:ShouldForceShowAllExtraSlots() then
        for i = 0, 1 do
            local w = TM.SlotWidget(i)
            if Flyout and Flyout.Arrow and Flyout.Arrow.Hide then
                Flyout.Arrow.Hide(w)
            else
                local arrow = EngineArrow(w)
                if arrow then arrow:Hide() end
            end
        end
        return
    end

    local slot0Frame = GetSlotFrame(TM.Buttons[0])
    local slot1Frame = GetSlotFrame(TM.Buttons[1])
    local arrow0 = EngineArrow(TM.SlotWidget(0))
    local arrow1 = EngineArrow(TM.SlotWidget(1))

    if TM.NumberOfTrinkets <= 0 then
        if Flyout and Flyout.Arrow then
            Flyout.Arrow.Hide(TM.SlotWidget(0))
            Flyout.Arrow.Hide(TM.SlotWidget(1))
        else
            if arrow0 then arrow0:Hide() end
            if arrow1 then arrow1:Hide() end
        end
        return
    end

    if slot0Frame and slot0Frame:IsShown() then
        if Flyout and Flyout.Arrow then
            Flyout.Arrow.Show(TM.SlotWidget(0))
            Flyout.Arrow.Hide(TM.SlotWidget(1))
        else
            if arrow0 then arrow0:Show() end
            if arrow1 then arrow1:Hide() end
        end
    elseif slot1Frame and slot1Frame:IsShown() then
        if Flyout and Flyout.Arrow then
            Flyout.Arrow.Show(TM.SlotWidget(1))
            Flyout.Arrow.Hide(TM.SlotWidget(0))
        else
            if arrow1 then arrow1:Show() end
            if arrow0 then arrow0:Hide() end
        end
    else
        if Flyout and Flyout.Arrow then
            Flyout.Arrow.Hide(TM.SlotWidget(0))
            Flyout.Arrow.Hide(TM.SlotWidget(1))
        else
            if arrow0 then arrow0:Hide() end
            if arrow1 then arrow1:Hide() end
        end
    end
end

-- ============================================================================
-- BUTTON SCRIPTS (for fallback ActionButtonTemplate)
-- ============================================================================

function TM.SetupButtonScripts(button)
    -- On click - clear checked state (no highlight after use)
    button:SetScript("PostClick", function(self, buttonClicked)
        self:SetChecked(false)
        -- Only process left-click for trinket use
        if buttonClicked == "LeftButton" then
            TM.OnTrinketClick(self)
        end
    end)
    
    -- On enter - show tooltip only
    button:SetScript("OnEnter", function(self)
        TM.ShowTrinketTooltip(self)
    end)
    
    -- On leave - hide tooltip
    button:SetScript("OnLeave", function(self)
        TM.HideTrinketTooltip()
    end)
    
    -- Right-click opens the flyout; KeyBind uses the slot. Same as HUD path.
    TM.HookTrinketClickScripts(button)
    
    -- Add flyout arrow to both trinkets (needed when only slot 2 is visible in one_equipped)
    TM.CreateFlyoutArrow(button)
end

-- Handle trinket click
function TM.OnTrinketClick(button)
    if button.SetChecked then
        button:SetChecked(false)
    end
    
    -- Track trinket usage for cooldown monitoring
    local slot = button.inventorySlot
    local link = GetInventoryItemLink("player", slot)
    if link then
        local _, _, itemID = string.find(link, "item:(%d+)")
        if itemID then
            TM.LastUsedTrinket = itemID
        end
    end
    
    -- Schedule cooldown update
    C_Timer.After(0.1, function()
        TM.UpdateTrinketCooldown(button)
    end)
end

-- Show trinket tooltip (live updating)
function TM.ShowTrinketTooltip(button)
    local slot = button.inventorySlot
    local widget = button.Widget or button
    
    if GameTooltip then GameTooltip:Hide() end
    if ShoppingTooltip1 then ShoppingTooltip1:Hide() end
    if ShoppingTooltip2 then ShoppingTooltip2:Hide() end
    if ShoppingTooltip3 then ShoppingTooltip3:Hide() end
    
    local left = widget.GetLeft and widget:GetLeft()
    local anchor = (left and left < 400) and "ANCHOR_RIGHT" or "ANCHOR_LEFT"
    GameTooltip:SetOwner(widget, anchor)
    
    -- Post-Dragonflight: suppress automatic comparison (other equipped trinket)
    if FLUX_API and FLUX_API.isPostDF and GameTooltip_SuppressAutomaticCompareItem then
        GameTooltip_SuppressAutomaticCompareItem(GameTooltip)
    end
    
    local hasItem = GameTooltip:SetInventoryItem("player", slot)
    
    local queuedName = TM.CombatQueue[slot - 13]
    if queuedName then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Queued: " .. queuedName, 1, 0.82, 0)
    end
    
    GameTooltip:Show()
end

-- ============================================================================
-- BUTTON UPDATES
-- ============================================================================

function TM.RestoreTrinketIconColor(icon)
    if not icon then
        return
    end
    if icon.SetDesaturated then
        icon:SetDesaturated(false)
    end
    if icon.SetVertexColor then
        icon:SetVertexColor(1, 1, 1, 1)
    end
end

function TM.RestoreTrinketBorderColor(button)
    if not button then
        return
    end
    local r, g, b = GetThemedTrinketVertexRGB()
    if button.WNormalTexture and FluxButtonUtil and FluxButtonUtil.ApplyButtonStyle then
        FluxButtonUtil:ApplyButtonStyle(button, button.categoryScope or "class")
        TM.HideEquippedGreenBorder(button)
        return
    end
    local nt = button.WNormalTexture or button.NormalTexture
        or (button.GetName and _G[button:GetName() .. "NormalTexture"])
    if nt and nt.SetVertexColor then
        nt:SetVertexColor(r, g, b, 1)
    end
    TM.HideEquippedGreenBorder(button)
end

--- Trinket slots are always the equipped items — skip FluxButton's green WBorder glow.
function TM.HideEquippedGreenBorder(button)
    if not button then
        return
    end
    local border = button.WBorder
        or button.Border
        or (button.GetName and _G[button:GetName() .. "Border"])
    if border and border.Hide then
        border:Hide()
    end
    local widget = button.Widget
    if widget and widget ~= button then
        local wBorder = widget.Border
            or (widget.GetName and _G[widget:GetName() .. "Border"])
        if wBorder and wBorder.Hide then
            wBorder:Hide()
        end
    end
end

--- Ensure FluxButtonUsability can paint (needs WIcon / WNormalTexture).
function TM.EnsureUsabilityTextureRefs(button)
    if not button then
        return nil
    end
    local icon = button.WIcon or button.Icon
    if not icon and button.Widget then
        icon = button.Widget.WIcon or button.Widget.icon or button.Widget.Icon
    end
    if icon and not button.WIcon then
        button.WIcon = icon
    end
    local nt = button.WNormalTexture or button.NormalTexture
        or (button.GetName and _G[button:GetName() .. "NormalTexture"])
    if nt and not button.WNormalTexture then
        button.WNormalTexture = nt
    end
    button.categoryScope = button.categoryScope or "class"
    return icon
end

--- Equipped slots: Extra Paint usable tint. Do not flip ActionType to item
--- (clicks stay /use 13|14). Empty slots desaturate.
function TM.ApplyTrinketUsability(button)
    if not button then
        return
    end
    local icon = TM.EnsureUsabilityTextureRefs(button)
    TM.SyncEquippedFace(button)
    local EBS = FluxEBS()
    local Paint = EBS and EBS.Paint
    if Paint and button.ItemId then
        if Paint.UpdateLiveFace then
            Paint.UpdateLiveFace(button)
        elseif Paint.UpdateUsable then
            Paint.UpdateUsable(button)
        end
        TM.HideEquippedGreenBorder(button)
        return
    end

    if not button.ItemId then
        button._isUsable = false
        button._notEnoughMana = false
        if icon then
            if icon.SetDesaturated then
                icon:SetDesaturated(true)
            end
            if icon.SetVertexColor then
                icon:SetVertexColor(0.4, 0.4, 0.4, 1)
            end
        end
        TM.RestoreTrinketBorderColor(button)
        return
    end

    local Flux = ns and ns.Flux
    local usable, noMana
    if Flux and Flux.Item and Flux.Item.IsUsable then
        usable, noMana = Flux.Item.IsUsable(button.ItemId)
    end
    if usable == false then
        if icon then
            if icon.SetDesaturated then
                icon:SetDesaturated(false)
            end
            if icon.SetVertexColor then
                if noMana then
                    icon:SetVertexColor(0.5, 0.5, 1, 1)
                else
                    icon:SetVertexColor(0.4, 0.4, 0.4, 1)
                end
            end
        end
    else
        TM.RestoreTrinketIconColor(icon)
    end
    TM.RestoreTrinketBorderColor(button)
    TM.HideEquippedGreenBorder(button)
end

--- Bag flyout: no usability darken — full-color icons + themed borders only.
function TM.ApplyMenuTrinketUsability(button, itemID)
    if not button then
        return
    end
    TM.EnsureUsabilityTextureRefs(button)
    TM.RestoreTrinketIconColor(button.WIcon or button.Icon or button.icon)
    TM.RestoreTrinketBorderColor(button)
end

function TM.UpdateTrinketButton(button)
    if not button then return end

    local slot = button.inventorySlot
    local texture, name, link = TM.GetTrinketInfo(slot)
    TM.SyncEquippedFace(button)

    local EBS = FluxEBS()
    local Paint = EBS and EBS.Paint
    if Paint and Paint.UpdateIcon then
        Paint.UpdateIcon(button)
    end

    local icon = button.WIcon or button.Icon
    if not icon and button.Widget then
        icon = button.Widget.WIcon or button.Widget.icon or (button.Widget.Icon and button.Widget.Icon)
    end
    if icon and (not button.ItemId or not Paint) then
        icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        icon:Show()
    end
    
    -- Clear checked state
    local widget = button.Widget or button
    if widget.SetChecked then
        widget:SetChecked(false)
    end
    
    if Paint and Paint.UpdateCooldown then
        Paint.UpdateCooldown(button)
    else
        TM.UpdateTrinketCooldown(button)
    end
    TM.ApplyTrinketUsability(button)
end

function TM.UpdateTrinketCooldown(button)
    if not button then return end
    
    local slot = button.inventorySlot
    local start, duration, enable = GetInventoryItemCooldown("player", slot)
    
    -- Get cooldown frame
    local cooldown = button.Cooldown
    if not cooldown and button.Widget then
        cooldown = button.Widget.cooldown or button.Widget.Cooldown
    end
    
    if not cooldown then return end
    
    if CooldownFrame_Set then
        CooldownFrame_Set(cooldown, start, duration, enable)
    elseif cooldown.SetCooldown then
        if start and duration and start > 0 and duration > 0 then
            cooldown:SetCooldown(start, duration)
        elseif cooldown.Clear then
            cooldown:Clear()
        end
    end
end

function TM.UpdateAllTrinkets()
    if not TM.Buttons then return end
    for _, button in pairs(TM.Buttons) do
        TM.UpdateTrinketButton(button)
    end
end

function TM.UpdateAllCooldowns()
    if not TM.Buttons then return end
    for _, button in pairs(TM.Buttons) do
        TM.UpdateTrinketCooldown(button)
        TM.ApplyTrinketUsability(button)
    end
end

function TM.UpdateAllUsability()
    if not TM.Buttons then return end
    for _, button in pairs(TM.Buttons) do
        TM.ApplyTrinketUsability(button)
    end
end

-- ============================================================================
-- MENU FRAME CREATION
-- ============================================================================

function TM.CreateMenuFrame()
    local Flyout = TMFlyout()
    local widget = TM.GetVisibleSlotWidget()
    if Flyout and widget then
        TM.MenuFrame = Flyout.GetPopup(widget)
    end
    return TM.MenuFrame
end

-- ============================================================================
-- MENU BUILDING (scan bags for trinkets)
-- ============================================================================

-- Scan bags for trinkets (shared function)
local function GetTrinketEquipSlot(itemID)
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, equipLoc = C_Item.GetItemInfoInstant(itemID)
        if equipLoc == "INVTYPE_TRINKET" then
            return equipLoc
        end
        if equipLoc then
            return equipLoc
        end
    elseif GetItemInfoInstant then
        local _, _, _, equipLoc = GetItemInfoInstant(itemID)
        if equipLoc then
            return equipLoc
        end
    end
    local _, _, _, _, _, _, _, _, equipSlot = ItemInfo(itemID)
    return equipSlot
end

function TM.ScanBagsForTrinkets()
    TM.BaggedTrinkets = {}
    -- Reset caches at the start of every scan; FindTrinketInBags repopulates them.
    wipe(TM._trinketBagCacheByItemID)
    wipe(TM._trinketBagCacheByName)

    local idx = 1

    -- Prefer Flux.Inventory bag snapshots (Syndicator or builtin).
    local uniqueItems = nil
    local Flux = ns and ns.Flux
    local byBag = Flux and Flux.Inventory and Flux.Inventory.snapshots
        and Flux.Inventory.snapshots.bags and Flux.Inventory.snapshots.bags.byBag
    if type(byBag) == "table" then
        local hasBags = false
        for _ in pairs(byBag) do
            hasBags = true
            break
        end
        if hasBags then
            uniqueItems = {}
            for bag, slots in pairs(byBag) do
                if type(slots) == "table" then
                    for slot, rec in pairs(slots) do
                        local itemID = rec and rec.itemID
                        if itemID then
                            uniqueItems[itemID] = { bag = bag, slot = slot, count = rec.count, link = rec.link }
                        end
                    end
                end
            end
        end
    end
    if not uniqueItems then
        local inv = _G.FluxInv
        if inv and inv.Bags and inv.Bags.GetUniqueItems then
            uniqueItems = inv.Bags.GetUniqueItems()
        elseif inv and inv.GetSnapshot then
            local snap = inv.GetSnapshot("bags")
            uniqueItems = snap and snap.uniqueItems or nil
        end
    end
    if uniqueItems then
        local trinkets = {}
        for itemID, rec in pairs(uniqueItems) do
            local equipSlot = GetTrinketEquipSlot(itemID)
            if equipSlot == "INVTYPE_TRINKET" then
                trinkets[#trinkets + 1] = { id = itemID, bag = rec.bag, slot = rec.slot }
            end
        end
        table.sort(trinkets, function(a, b)
            if a.bag ~= b.bag then return a.bag < b.bag end
            return a.slot < b.slot
        end)
        for i = 1, #trinkets do
            if idx > TM.MaxTrinketMenuButtons then break end
            local t = trinkets[i]
            local itemName, _, _, _, _, _, _, _, _, itemTexture = ItemInfo(t.id)
            TM.BaggedTrinkets[idx] = {
                id = t.id,
                bag = t.bag,
                slot = t.slot,
                name = itemName,
                texture = itemTexture
            }
            TM._trinketBagCacheByItemID[t.id] = { bag = t.bag, slot = t.slot }
            if itemName then
                TM._trinketBagCacheByName[itemName] = { bag = t.bag, slot = t.slot }
            end
            idx = idx + 1
        end
        TM.NumberOfTrinkets = math.min(idx - 1, TM.MaxTrinketMenuButtons)
        return
    end

    local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local GetContainerItemLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink

    for _, bag in ipairs(_TM_GetCarriedBagIDs()) do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink then
                    local _, _, itemID = string.find(itemLink, "item:(%d+)")
                    if itemID then
                        itemID = tonumber(itemID)
                        local itemName, _, _, _, _, _, _, _, equipSlot, itemTexture = ItemInfo(itemID)
                        equipSlot = GetTrinketEquipSlot(itemID) or equipSlot
                        if equipSlot == "INVTYPE_TRINKET" then
                            TM.BaggedTrinkets[idx] = {
                                id = itemID,
                                bag = bag,
                                slot = slot,
                                name = itemName,
                                texture = itemTexture
                            }
                            TM._trinketBagCacheByItemID[itemID] = { bag = bag, slot = slot }
                            if itemName then
                                TM._trinketBagCacheByName[itemName] = { bag = bag, slot = slot }
                            end
                            idx = idx + 1
                            if idx > TM.MaxTrinketMenuButtons then break end
                        end
                    end
                end
            end
        end
        if idx > TM.MaxTrinketMenuButtons then break end
    end

    TM.NumberOfTrinkets = math.min(idx - 1, TM.MaxTrinketMenuButtons)
    if TM.SyncFlyoutEngine then
        TM.SyncFlyoutEngine()
    end
end

function TM.SyncFlyoutEngine()
    local Flyout = TMFlyout()
    if not Flyout or not Flyout.SetButtons then
        return
    end
    local list = {}
    for i = 1, TM.NumberOfTrinkets or 0 do
        local trinket = TM.BaggedTrinkets[i]
        if trinket then
            local itemID = trinket.id or trinket.itemID
            local name = trinket.name
            local bag = trinket.bag
            local slot = trinket.slot
            local idx = i
            list[#list + 1] = {
                icon = trinket.texture,
                name = name,
                item = itemID,
                bag = bag,
                slot = slot,
                tooltip = "Left-Click: Equip to Slot 1 (Top). Right-Click: Equip to Slot 2 (Bottom).",
                onClick = function(_, mouse)
                    local targetSlot = (mouse == "RightButton") and 14 or 13
                    TM.EquipTrinket(name, targetSlot)
                    C_Timer.After(0.25, function()
                        TM.UpdateTrinketVisibility()
                        if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
                            FluxUnifiedBorder.UpdateBorder()
                        end
                    end)
                end,
                onEnter = function(kid)
                    kid:SetID(idx)
                    TM.ShowMenuTrinketTooltip(kid)
                end,
            }
        end
    end
    local n = #list
    -- Same fill order as original TrinketMenu (left-to-right, wrap, build up).
    -- Width forms: 1 col through 4, 2 through 12, 3 through 18, 4 after that.
    local cols = 1
    if n > 18 then
        cols = 4
    elseif n > 12 then
        cols = 3
    elseif n > 4 then
        cols = 2
    end
    local opts = TrinketFlyoutOpts(cols)
    for i = 0, 1 do
        local w = TM.SlotWidget(i)
        if w then
            BindTrinketFlyout(w)
            Flyout.SetButtons(w, list, opts)
            local arrow = EngineArrow(w)
            if arrow then
                w.FluxTrinketMenuArrow = arrow
                local btn = TM.Buttons and TM.Buttons[i]
                if btn then
                    btn.FluxTrinketMenuArrow = arrow
                end
            end
        end
    end
    TM.UpdateArrowVisibility()
end

function TM.BuildMenu(host)
    -- OnMouseDown plus a leftover up-click should not Toggle twice.
    local now = (GetTime and GetTime()) or 0
    if TM._buildMenuAt and (now - TM._buildMenuAt) < 0.08 then
        return
    end
    TM._buildMenuAt = now
    TM.ScanBagsForTrinkets()
    TM.SyncFlyoutEngine()
    local Flyout = TMFlyout()
    local widget = host or TM.GetVisibleSlotWidget()
    if not Flyout or not widget then
        return
    end
    if TM.NumberOfTrinkets < 1 then
        Flyout.Close(widget)
        TM.UpdateArrowRotation(false)
        return
    end
    Flyout.Toggle(widget)
    TM.MenuFrame = Flyout.GetPopup(widget)
    TM.UpdateArrowRotation(Flyout.IsOpen(widget))
    TM.StartMenuMouseoverTimer()
end

function TM.UpdateMenuButtonCooldown(btn, bag, slot)
    if not btn or not btn.Cooldown then return end
    
    local GetContainerItemCooldown = C_Container and C_Container.GetContainerItemCooldown or GetContainerItemCooldown
    local start, duration, enable = GetContainerItemCooldown(bag, slot)
    
    if CooldownFrame_Set then
        CooldownFrame_Set(btn.Cooldown, start, duration, enable)
    end
end

function TM.OnMenuTrinketClick(button)
    local id = button:GetID()
    if not id or not TM.BaggedTrinkets[id] then return end
    
    local trinket = TM.BaggedTrinkets[id]
    local mouseButton = GetMouseButtonClicked()
    
    -- Determine target slot: Left = slot 13 (top), Right = slot 14 (bottom)
    local targetSlot = (mouseButton == "LeftButton") and 13 or 14
    
    -- Equip trinket
    TM.EquipTrinket(trinket.name, targetSlot)
    
    -- Hide menu after short delay and rotate arrow back
    C_Timer.After(0.1, function()
        local Flyout = TMFlyout()
        if Flyout then
            Flyout.CloseAll()
        elseif TM.MenuFrame then
            TM.MenuFrame:Hide()
        end
        TM.UpdateArrowRotation(false)
    end)

    -- Refresh visibility/layout after equip (events may fire async)
    C_Timer.After(0.25, function()
        TM.UpdateTrinketVisibility()
        if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
            FluxUnifiedBorder.UpdateBorder()
        end
    end)
end

function TM.ShowMenuTrinketTooltip(button)
    local id = button:GetID()
    if not id or not TM.BaggedTrinkets[id] then return end
    
    local trinket = TM.BaggedTrinkets[id]
    
    if GameTooltip then GameTooltip:Hide() end
    if ShoppingTooltip1 then ShoppingTooltip1:Hide() end
    if ShoppingTooltip2 then ShoppingTooltip2:Hide() end
    if ShoppingTooltip3 then ShoppingTooltip3:Hide() end
    
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    
    GameTooltip:ClearLines()
    
    -- Post-Dragonflight: suppress automatic comparison (equipped trinkets)
    if FLUX_API and FLUX_API.isPostDF and GameTooltip_SuppressAutomaticCompareItem then
        GameTooltip_SuppressAutomaticCompareItem(GameTooltip)
    end
    
    local tid = trinket.id and tonumber(trinket.id) or nil
    if FluxSafeTooltipSetBagItem then
        FluxSafeTooltipSetBagItem(GameTooltip, trinket.bag, trinket.slot, tid)
    else
        GameTooltip:SetBagItem(trinket.bag, trinket.slot)
    end
    
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-Click: Equip to Slot 1 (Top)", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Right-Click: Equip to Slot 2 (Bottom)", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function TM.StartMenuMouseoverTimer()
    if TM.MenuMouseoverTimer then
        TM.MenuMouseoverTimer:Cancel()
    end

    TM.MenuMouseoverTimer = C_Timer.NewTicker(0.25, function()
        local Flyout = TMFlyout()
        local widget = TM.GetVisibleSlotWidget()
        local popup = TM.MenuFrame
        if Flyout and widget then
            popup = Flyout.GetPopup(widget) or popup
            TM.MenuFrame = popup
        end
        if popup and popup:IsShown() then
            local overMain = TM.Frame and FrameMouseOver(TM.Frame)
            local overMenu = FrameMouseOver(popup)
            local overArrow = false
            local arrow = EngineArrow(widget)
            if arrow and arrow.IsShown and arrow:IsShown() and FrameMouseOver(arrow) then
                overArrow = true
            end
            if not overMain and not overMenu and not overArrow then
                if Flyout then
                    Flyout.CloseAll()
                else
                    popup:Hide()
                end
                TM.UpdateArrowRotation(false)
                if TM.MenuMouseoverTimer then
                    TM.MenuMouseoverTimer:Cancel()
                    TM.MenuMouseoverTimer = nil
                end
            end
        else
            TM.UpdateArrowRotation(false)
            if TM.MenuMouseoverTimer then
                TM.MenuMouseoverTimer:Cancel()
                TM.MenuMouseoverTimer = nil
            end
        end
    end)
end

-- ============================================================================
-- COMBAT QUEUE SYSTEM
-- ============================================================================

-- Queue a trinket swap for after combat
function TM.QueueTrinketSwap(trinketName, targetSlot)
    if not trinketName then return end
    
    local which = targetSlot - 13 -- 0 or 1
    
    -- If same trinket already queued, remove it (toggle)
    if TM.CombatQueue[which] == trinketName then
        TM.CombatQueue[which] = nil
    else
        -- Check if queued in other slot, move it
        if TM.CombatQueue[1 - which] == trinketName then
            TM.CombatQueue[1 - which] = nil
        end
        TM.CombatQueue[which] = trinketName
    end
    
    TM.UpdateQueueVisuals()
end

-- Execute queued swaps after combat
function TM.ProcessCombatQueue()
    if InCombatLockdown() or TM.IsPlayerReallyDead() then return end
    
    for which = 0, 1 do
        local trinketName = TM.CombatQueue[which]
        if trinketName then
            local targetSlot = which + 13
            TM.EquipTrinket(trinketName, targetSlot)
            TM.CombatQueue[which] = nil
        end
    end
    
    TM.UpdateQueueVisuals()
end

-- Equip a trinket from bags to a slot
function TM.EquipTrinket(trinketName, targetSlot)
    if not trinketName then return end
    if InCombatLockdown() or TM.IsPlayerReallyDead() then
        TM.QueueTrinketSwap(trinketName, targetSlot)
        return
    end
    
    if CursorHasItem() or SpellIsTargeting() then return end
    
    local bag, slot = TM.FindTrinketInBags(trinketName)
    if bag then
        local GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo or GetContainerItemInfo
        local PickupContainerItem = C_Container and C_Container.PickupContainerItem or PickupContainerItem
        
        local info = GetContainerItemInfo(bag, slot)
        local isLocked = info and info.isLocked
        
        if not isLocked and not IsInventoryItemLocked(targetSlot) then
            PickupContainerItem(bag, slot)
            PickupInventoryItem(targetSlot)
            
            -- Visual feedback
            if TM.Buttons then
                local button = TM.Buttons[targetSlot - 13]
                if button then
                    local icon = button.Icon
                    if not icon and button.Widget then
                        icon = button.Widget.icon
                    end
                    if icon then
                        icon:SetDesaturated(true)
                    end
                end
            end
            
            -- Schedule visibility and layout update
            C_Timer.After(0.5, function()
                TM.UpdateTrinketVisibility()
            end)
        end
    end
end

-- Update visual indicators for queued swaps
function TM.UpdateQueueVisuals()
    -- Could add queue overlay icons here if desired
    -- For now, just rely on tooltip showing queue info
end

-- ============================================================================
-- KEYBINDING SUPPORT
-- ============================================================================

function TM.UpdateKeybindings()
    if InCombatLockdown() then
        TM._pendingKeybindUpdate = true
        return
    end

    if not TM.Buttons then return end

    -- Mouse/space glyphs: 17px = 14 * 1.2 (20% larger than shared ExtraButton hotkey icons)
    local TRINKET_HOTKEY_ICON_SIZE = 17

    local function ApplyHotkeyText(button, bindingName)
        if not button then return end
        if FluxNCHotkeyUtil and FluxNCHotkeyUtil.UpdateHotkeyText then
            FluxNCHotkeyUtil.UpdateHotkeyText(button, bindingName, nil, nil, TRINKET_HOTKEY_ICON_SIZE)
            return
        end
        local widget = button.Widget or button
        local widgetName = widget and widget.GetName and widget:GetName()
        local hotKey = button.HotKey or (widget and (widget.HotKey or (widgetName and _G[widgetName .. "HotKey"])))
        if not hotKey then return end
        local key = bindingName and GetBindingKey(bindingName)
        local text = ""
        if key and key ~= "" then
            if GetBindingText then
                text = GetBindingText(key, "KEY_") or key
            else
                text = key
            end
        end
        if text ~= "" then
            hotKey:SetText(text)
            hotKey:Show()
        else
            hotKey:SetText("")
            hotKey:Hide()
        end
    end

    TM.ScanBagsForTrinkets()
    local state = TM.VisibilityState or TM.GetTrinketVisibilityState()
    local btn0 = TM.Buttons[0]
    local btn1 = TM.Buttons[1]
    local widget0 = btn0 and (btn0.Widget or btn0) or nil
    local widget1 = btn1 and (btn1.Widget or btn1) or nil

    -- Clear all override bindings first
    if widget0 then ClearOverrideBindings(widget0) end
    if widget1 then ClearOverrideBindings(widget1) end

    if state == "none" or state == "bag_only" then
        ApplyHotkeyText(btn0, "FLUXTRINKET1")
        ApplyHotkeyText(btn1, "FLUXTRINKET2")
        if TM.SyncKeybindPushWatch then
            TM.SyncKeybindPushWatch()
        end
        return
    end

    -- one_equipped: both keybinds target the single visible button
    if state == "one_equipped" then
        local equipped = TM.GetEquippedTrinketSlots()
        local targetWidget = (equipped[1] == 13) and widget0 or widget1
        local targetBtn = (equipped[1] == 13) and btn0 or btn1
        if targetWidget and targetWidget:GetName() then
            for i = 1, 2 do
                local bindingName = "FLUXTRINKET" .. i
                local keys = { GetBindingKey(bindingName) }
                for ki = 1, #keys do
                    local key = keys[ki]
                    if key and key ~= "" then
                        SetOverrideBindingClick(targetWidget, false, key, targetWidget:GetName(), "KeyBind")
                    end
                end
            end
        end
        -- Show both binding labels on the visible slot when possible
        if FluxNCHotkeyUtil and FluxNCHotkeyUtil.UpdateHotkeyTextMultiple then
            FluxNCHotkeyUtil.UpdateHotkeyTextMultiple(targetBtn, { "FLUXTRINKET1", "FLUXTRINKET2" }, TRINKET_HOTKEY_ICON_SIZE)
        else
            ApplyHotkeyText(btn0, "FLUXTRINKET1")
            ApplyHotkeyText(btn1, "FLUXTRINKET2")
        end
        if TM.SyncKeybindPushWatch then
            TM.SyncKeybindPushWatch()
        end
        return
    end

    -- both_equipped: normal 1->slot 13, 2->slot 14
    for index, button in pairs(TM.Buttons) do
        local bindingName = "FLUXTRINKET" .. (index + 1)
        local keys = { GetBindingKey(bindingName) }
        local widget = button.Widget or button
        local widgetName = widget:GetName()

        if widgetName then
            for ki = 1, #keys do
                local key = keys[ki]
                if key and key ~= "" then
                    SetOverrideBindingClick(widget, false, key, widgetName, "KeyBind")
                end
            end
        end

        ApplyHotkeyText(button, bindingName)
    end
    if TM.SyncKeybindPushWatch then
        TM.SyncKeybindPushWatch()
    end
end

-- ============================================================================
-- VISIBILITY
-- ============================================================================

function TM.Show()
    -- Prevent showing frame in combat (defer until combat ends)
    if InCombatLockdown() then
        TM._pendingShow = true
        return
    end
    
    if TM.Frame then
        TM.Frame:Show()
    end
    TM._pendingShow = false
    if TM.SyncKeybindPushWatch then
        TM.SyncKeybindPushWatch()
    end
end

function TM.Hide()
    if TM.Frame then
        TM.Frame:Hide()
    end
    local Flyout = TMFlyout()
    if Flyout and Flyout.CloseAll then
        Flyout.CloseAll()
    elseif TM.MenuFrame then
        TM.MenuFrame:Hide()
    end
    if TM.Buttons then
        for i = 0, 1 do
            local w = TM.SlotWidget(i)
            local arrow = EngineArrow(w)
            if Flyout and Flyout.Arrow and Flyout.Arrow.Hide then
                Flyout.Arrow.Hide(w)
            elseif arrow then
                arrow:Hide()
            end
        end
    end
    if TM.SyncKeybindPushWatch then
        TM.SyncKeybindPushWatch()
    end
end

function TM.Toggle()
    if TM.Frame then
        if TM.Frame:IsShown() then
            TM.Frame:Hide()
            local Flyout = TMFlyout()
            if Flyout and Flyout.CloseAll then
                Flyout.CloseAll()
            elseif TM.MenuFrame then
                TM.MenuFrame:Hide()
            end
        else
            TM.Frame:Show()
        end
    end
end

-- Check if player has any trinkets equipped
function TM.HasEquippedTrinkets()
    return GetInventoryItemLink("player", 13) or GetInventoryItemLink("player", 14)
end

-- Returns which slots (13, 14) have trinkets equipped: {13}, {14}, or {13, 14}
function TM.GetEquippedTrinketSlots()
    local equipped = {}
    if GetInventoryItemLink("player", 13) then
        table.insert(equipped, 13)
    end
    if GetInventoryItemLink("player", 14) then
        table.insert(equipped, 14)
    end
    return equipped
end

-- Returns "none", "bag_only", "one_equipped", or "both_equipped". Call ScanBagsForTrinkets first.
function TM.GetTrinketVisibilityState()
    local equipped = TM.GetEquippedTrinketSlots()
    local numEquipped = #equipped
    local numInBag = TM.NumberOfTrinkets or 0

    if numEquipped == 0 and numInBag == 0 then
        return "none"
    elseif numEquipped == 0 and numInBag > 0 then
        return "bag_only"
    elseif numEquipped == 1 then
        return "one_equipped"
    else
        return "both_equipped"
    end
end

-- Central updater: visibility, slot layout, frame size based on trinket state
function TM.UpdateTrinketVisibility()
    if InCombatLockdown() then
        TM._pendingVisibilityUpdate = true
        return
    end

    TM.ScanBagsForTrinkets()
    local state = TM.GetTrinketVisibilityState()
    TM.VisibilityState = state

    if not TM.Frame or not TM.Buttons then return end

    local slotSize = TM.SlotSize or (TM.DEFAULT_BUTTON_SIZE * TM.BUTTON_SLOT_SIZE_MULTIPLIER)
    local spacing = TM.Spacing or TM.DEFAULT_SPACING

    local fbm = _G.FluxBindingMode
    if fbm and fbm.ShouldForceShowAllExtraSlots and fbm:ShouldForceShowAllExtraSlots() then
        TM.Show()
        local frameHeight = (slotSize * 2) + spacing
        TM.Frame:SetSize(slotSize, frameHeight)
        local slot0Frame = GetSlotFrame(TM.Buttons[0])
        local slot1Frame = GetSlotFrame(TM.Buttons[1])
        local btn0 = TM.Buttons[0]
        local btn1 = TM.Buttons[1]
        local widget0 = btn0 and (btn0.Widget or btn0)
        local widget1 = btn1 and (btn1.Widget or btn1)
        if slot0Frame and slot1Frame then
            slot0Frame:Show()
            slot1Frame:Show()
            slot0Frame:ClearAllPoints()
            slot0Frame:SetPoint("BOTTOMLEFT", TM.Frame, "BOTTOMLEFT", 0, slotSize + spacing)
            slot1Frame:ClearAllPoints()
            slot1Frame:SetPoint("BOTTOMLEFT", TM.Frame, "BOTTOMLEFT", 0, 0)
        end
        if widget0 then
            widget0:SetAttribute("macrotext", "/use 13")
            local tex0 = GetInventoryItemTexture("player", 13)
            if not tex0 then
                local _, slotTex = GetInventorySlotInfo("Trinket0Slot")
                tex0 = slotTex
            end
            if widget0.icon then widget0.icon:SetTexture(tex0) end
            if btn0 and btn0.WIcon then btn0.WIcon:SetTexture(tex0); btn0.WIcon:Show() end
        end
        if widget1 then
            widget1:SetAttribute("macrotext", "/use 14")
            local tex1 = GetInventoryItemTexture("player", 14)
            if not tex1 then
                local _, slotTex = GetInventorySlotInfo("Trinket1Slot")
                tex1 = slotTex
            end
            if widget1.icon then widget1.icon:SetTexture(tex1) end
            if btn1 and btn1.WIcon then btn1.WIcon:SetTexture(tex1); btn1.WIcon:Show() end
        end
        if TM.ApplyHorizontalSqueeze then
            TM.ApplyHorizontalSqueeze()
        end
        TM.UpdateArrowVisibility()
        TM.UpdateKeybindings()
        if FluxTrinketMenu_ApplyAppearanceAccent then
            FluxTrinketMenu_ApplyAppearanceAccent()
        end
        return
    end

    local smartTM = (state ~= "none")
    if FluxExtraButtonVisibility and not FluxExtraButtonVisibility.Apply("trinket_menu", smartTM) then
        TM.Hide()
        TM.UpdateKeybindings()
        return
    end

    if state == "none" then
        TM.Show()
        local frameHeight = (slotSize * 2) + spacing
        TM.Frame:SetSize(slotSize, frameHeight)
        local slot0Frame = GetSlotFrame(TM.Buttons[0])
        local slot1Frame = GetSlotFrame(TM.Buttons[1])
        local btn0 = TM.Buttons[0]
        local btn1 = TM.Buttons[1]
        local widget0 = btn0 and (btn0.Widget or btn0)
        local widget1 = btn1 and (btn1.Widget or btn1)
        if slot0Frame and slot1Frame then
            slot0Frame:Show()
            slot1Frame:Show()
            slot0Frame:ClearAllPoints()
            slot0Frame:SetPoint("BOTTOMLEFT", TM.Frame, "BOTTOMLEFT", 0, slotSize + spacing)
            slot1Frame:ClearAllPoints()
            slot1Frame:SetPoint("BOTTOMLEFT", TM.Frame, "BOTTOMLEFT", 0, 0)
        end
        if widget0 then
            widget0:SetAttribute("macrotext", "/use 13")
            local tex0 = GetInventoryItemTexture("player", 13)
            if not tex0 then
                local _, slotTex = GetInventorySlotInfo("Trinket0Slot")
                tex0 = slotTex
            end
            if widget0.icon then widget0.icon:SetTexture(tex0) end
            if btn0 and btn0.WIcon then btn0.WIcon:SetTexture(tex0); btn0.WIcon:Show() end
        end
        if widget1 then
            widget1:SetAttribute("macrotext", "/use 14")
            local tex1 = GetInventoryItemTexture("player", 14)
            if not tex1 then
                local _, slotTex = GetInventorySlotInfo("Trinket1Slot")
                tex1 = slotTex
            end
            if widget1.icon then widget1.icon:SetTexture(tex1) end
            if btn1 and btn1.WIcon then btn1.WIcon:SetTexture(tex1); btn1.WIcon:Show() end
        end
        if TM.ApplyHorizontalSqueeze then
            TM.ApplyHorizontalSqueeze()
        end
        TM.UpdateArrowVisibility()
        TM.UpdateKeybindings()
        if FluxTrinketMenu_ApplyAppearanceAccent then
            FluxTrinketMenu_ApplyAppearanceAccent()
        end
        return
    end

    TM.Show()

    -- Frame always 2-button height (border never changes, like CombatGrid/NonCombatGrid)
    local frameHeight = (slotSize * 2) + spacing
    TM.Frame:SetSize(slotSize, frameHeight)

    local slot0Frame = GetSlotFrame(TM.Buttons[0])
    local slot1Frame = GetSlotFrame(TM.Buttons[1])
    if not slot0Frame or not slot1Frame then return end

    local btn0 = TM.Buttons[0]
    local btn1 = TM.Buttons[1]
    local widget0 = btn0.Widget or btn0
    local widget1 = btn1.Widget or btn1

    -- Center offset for single button (matches CombatGrid/NonCombatGrid)
    local centerOffset = (slotSize + spacing) / 2

    if state == "bag_only" then
        slot0Frame:Show()
        slot1Frame:Hide()
        slot0Frame:ClearAllPoints()
        slot0Frame:SetPoint("BOTTOMLEFT", TM.Frame, "BOTTOMLEFT", 0, centerOffset)
        widget0:SetAttribute("macrotext", "/")
        TM.UpdateTrinketButton(btn0)
        TM.UpdateArrowVisibility()
    elseif state == "one_equipped" then
        local equipped = TM.GetEquippedTrinketSlots()
        local equippedSlot = equipped[1]
        if equippedSlot == 13 then
            slot0Frame:Show()
            slot1Frame:Hide()
            slot0Frame:ClearAllPoints()
            slot0Frame:SetPoint("BOTTOMLEFT", TM.Frame, "BOTTOMLEFT", 0, centerOffset)
            widget0:SetAttribute("macrotext", "/use 13")
        else
            slot0Frame:Hide()
            slot1Frame:Show()
            slot1Frame:ClearAllPoints()
            slot1Frame:SetPoint("BOTTOMLEFT", TM.Frame, "BOTTOMLEFT", 0, centerOffset)
            widget1:SetAttribute("macrotext", "/use 14")
        end
        TM.UpdateAllTrinkets()
        TM.UpdateArrowVisibility()
    else
        -- Both slots: original positions (slot 0 top, slot 1 bottom)
        slot0Frame:Show()
        slot1Frame:Show()
        slot0Frame:ClearAllPoints()
        slot0Frame:SetPoint("BOTTOMLEFT", TM.Frame, "BOTTOMLEFT", 0, slotSize + spacing)
        slot1Frame:ClearAllPoints()
        slot1Frame:SetPoint("BOTTOMLEFT", TM.Frame, "BOTTOMLEFT", 0, 0)
        widget0:SetAttribute("macrotext", "/use 13")
        widget1:SetAttribute("macrotext", "/use 14")
        TM.UpdateAllTrinkets()
        TM.UpdateArrowVisibility()
    end

    if TM.ApplyHorizontalSqueeze then
        TM.ApplyHorizontalSqueeze()
    end
    TM.UpdateKeybindings()
end

function FluxTrinketMenu_ApplyAppearanceAccent()
    local r, g, b
    if FluxBorder and FluxBorder.GetThemedVertexRGB then
        r, g, b = FluxBorder:GetThemedVertexRGB()
    else
        local c = GetClassColor()
        r, g, b = c.r, c.g, c.b
    end
    -- Slot 13/14: FluxButton uses WNormalTexture + ApplyButtonStyle; legacy ActionButton uses NormalTexture.
    if TM.Buttons then
        for _, button in pairs(TM.Buttons) do
            if button and button.WNormalTexture and FluxButtonUtil and FluxButtonUtil.ApplyButtonStyle then
                FluxButtonUtil:ApplyButtonStyle(button, "class")
            elseif button and button.NormalTexture then
                button.NormalTexture:SetVertexColor(r, g, b, 1)
            end
        end
    end
    if TM.MenuButtons then
        for _, btn in ipairs(TM.MenuButtons) do
            if btn and btn.NormalTexture then
                btn.NormalTexture:SetVertexColor(r, g, b, 1)
            end
        end
    end
    local Flyout = TMFlyout()
    if Flyout and Flyout.ApplyAppearanceAccent then
        Flyout.ApplyAppearanceAccent()
    end
    -- Container frame borders (registered with FluxBorder)
    if FluxBorder and FluxBorder.RefreshClassColor then
        if TM.Frame then
            FluxBorder:RefreshClassColor(TM.Frame)
        end
        if TM.MenuFrame then
            FluxBorder:RefreshClassColor(TM.MenuFrame)
        end
    end
end

-- ============================================================================
-- GLOBAL EXPORT
-- ============================================================================

_G.FluxTrinketMenu = TM
