-- Ordinary item buttons share one whole-stage action; the caption is inert.
-- Native extra-action controls, secure hosts and bindings retain their owners.
local _, ns = ...
local F, L, Flux = FluxAuctionRestock.Followup, ns.FluxOptionsLocale, ns.Flux
local frame, displayed, WatchBounds, UpdateButtons
local professionSurfaceReader
local professionHooks = setmetatable({}, { __mode = "k" })
local icons = {}
local entries, entryByID = {}, {}
local layoutCount, layoutWidth, layoutHeight
local layoutDirty = true
local hooked = setmetatable({}, { __mode = "k" })
local GAP, PADDING, CAPTION_HEIGHT, MAX_GRID_WIDTH = 1, 4, 40, 200
local SCREEN_MARGIN, SCROLLBAR_WIDTH, GLOW_KEY = 16, 24, "FluxRestockFollowup"
local HORIZONTAL_SHIFT, VERTICAL_DROP, GLOW_SCALE = 24, 48, 1.4
local HUD_STRATA, HUD_LEVEL, SURFACE_CLEARANCE = "HIGH", 100, 8
local DOCK_WIDTH, DOCK_HEIGHT, DOCK_ICON_SIZE = 196, 42, 30
local strataRank = { HIGH = 1, DIALOG = 2, FULLSCREEN = 3, FULLSCREEN_DIALOG = 4, TOOLTIP = 5 }
local function InCombat() return InCombatLockdown and InCombatLockdown() end
local function Positive(value)
    return not (issecretvalue and issecretvalue(value)) and type(value) == "number"
        and value > 0 and value < math.huge and value % 1 == 0
end
local function NativeCraftPrepared(state)
    return state.kind == "craft" and state.nativeCraft == true and Positive(state.nativeCraftPrepared)
end
local function Actionable(state)
    return state and not NativeCraftPrepared(state) and (state.kind == "mail" or state.kind == "bank"
        or state.kind == "vendor" or state.kind == "craft" or state.kind == "profession" or state.kind == "auction")
end
local function ItemName(id)
    local ic = _G.FluxItemClass
    return ic and ic.GetName and ic.GetName(id) or tostring(id)
end
local function CaptionKind(state)
    if state.kind == "craft" and state.logistics and state.logistics.resume then
        return state.logistics.remainingOutput > 0 and "RESUME" or "RESUME_COMPLETE"
    end
    if state.kind == "craft" and state.nativeCraft == true then
        if NativeCraftPrepared(state) then return "NATIVE_CRAFT_PREPARED" end
        return "NATIVE_CRAFT"
    end
    return state.kind:upper()
end
local function Text(state)
    local kind = CaptionKind(state)
    local format = L["AH_FOLLOWUP_" .. kind] or L.AH_TITLE
    if kind == "VENDOR" and #entries == 1 and L.AH_FOLLOWUP_VENDOR_ITEM then
        local item = entries[1]
        return L.AH_FOLLOWUP_VENDOR_ITEM:format(item.quantity, ItemName(item.itemID))
    elseif kind == "VENDOR" and #entries == 2 and L.AH_FOLLOWUP_VENDOR_PAIR then
        local first, second = entries[1], entries[2]
        return L.AH_FOLLOWUP_VENDOR_PAIR:format(first.quantity, ItemName(first.itemID), second.quantity, ItemName(second.itemID))
    end
    if kind == "NATIVE_CRAFT_PREPARED" then return format:format(state.nativeCraftPrepared) end
    if kind == "PROFESSION" or kind == "NATIVE_CRAFT" then return format:format(state.name or "") end
    if kind == "RESUME" then return format:format(state.logistics.remainingOutput, state.name or "") end
    if kind == "RESUME_COMPLETE" then return format:format(state.logistics.carriedOutput, state.name or "") end
    return format:format(state.quantity or 0, state.name or "")
end
local function ResumeHelp(state)
    if not (state.logistics and state.logistics.resume) then return end
    local carried, remaining = state.logistics.carriedOutput, state.logistics.remainingOutput
    if remaining == 0 then return L.AH_FOLLOWUP_RESUME_COMPLETE_HELP:format(carried) end
    return L.AH_FOLLOWUP_RESUME_HELP:format(carried, remaining)
end
local function Entries(state)
    local count, changed = 0, false
    for id, quantity in pairs(state.items or {}) do
        if Positive(id) and Positive(quantity) then
            count = count + 1
            if entryByID[id] then entryByID[id].quantity = quantity else changed = true end
        end
    end
    if count == 0 then
        local task = state.task
        local id = state.itemID or (task and task.parentID)
        local quantity = state.quantity
        if task and Positive(task.operations) and Positive(task.yield) then quantity = task.operations * task.yield end
        if Positive(id) and Positive(quantity) then
            if #entries == 1 and entries[1].itemID == id then entries[1].quantity = quantity
            else entries = { { itemID = id, quantity = quantity } }; entryByID = { [id] = entries[1] } end
        else entries, entryByID = {}, {} end
    elseif changed or count ~= #entries then
        entries, entryByID = {}, {}
        for id, quantity in pairs(state.items) do
            if Positive(id) and Positive(quantity) then
                local entry = { itemID = id, quantity = quantity }
                entries[#entries + 1], entryByID[id] = entry, entry
            end
        end
        table.sort(entries, function(a, b) return a.itemID < b.itemID end)
    end
    return entries
end
local function Renderer()
    local lib = LibStub and LibStub("LibCustomGlow-1.0", true)
    local cap = Flux.Capabilities or Flux.Cap
    if cap and cap.HasAtlas and cap.HasAtlas("UI-HUD-ActionBar-Proc-Start-Flipbook")
        and cap.HasAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
        and lib and lib.ProcGlow_Start and lib.ProcGlow_Stop then return lib, "proc" end
    local classic = LibStub and LibStub("LibButtonGlow-1.0", true)
    if classic and classic.ShowOverlayGlow and classic.HideOverlayGlow then return classic, "classic" end
    if lib and lib.ButtonGlow_Start and lib.ButtonGlow_Stop then return lib, "button" end
end
local function GlowOverlay(slot, kind)
    if kind == "proc" then return slot["_ProcGlow" .. GLOW_KEY] end
    if kind == "classic" then return slot.__LBGoverlay end
    return slot._ButtonGlow
end
local function StopGlow(slot)
    local lib = slot.glowLib
    if not lib then return end
    local kind = slot.glowKind
    if kind == "proc" then lib.ProcGlow_Stop(slot, GLOW_KEY)
    elseif kind == "classic" then lib.HideOverlayGlow(slot)
    else lib.ButtonGlow_Stop(slot) end
    -- The fallback renderers fade while the button remains visible. Hiding
    -- the returned frame completes that library's release before slot reuse.
    if kind ~= "proc" then
        local overlay = GlowOverlay(slot, kind)
        if overlay then overlay:Hide() end
    end
    slot.glowLib, slot.glowKind, slot.glowSize = nil, nil, nil
end
local function Glow(slot, enabled, lib, kind)
    if not enabled or not lib then StopGlow(slot); return end
    if slot.glowLib == lib and slot.glowKind == kind and slot.glowSize == slot.size then return end
    StopGlow(slot)
    -- Art only: no native spell-alert manager or spell-membership registration.
    if kind == "proc" then lib.ProcGlow_Start(slot, { startAnim = false, key = GLOW_KEY })
    elseif kind == "classic" then lib.ShowOverlayGlow(slot)
    else lib.ButtonGlow_Start(slot) end
    slot.glowLib, slot.glowKind, slot.glowSize = lib, kind, slot.size
    local overlay = GlowOverlay(slot, kind)
    if not overlay then return end
    if kind == "proc" then
        local size = slot.size * GLOW_SCALE
        overlay:ClearAllPoints()
        overlay:SetSize(size, size)
        overlay:SetPoint("CENTER", slot, "CENTER", 0, 0)
    end
    overlay:EnableMouse(false)
end
local function Visible(slot)
    if not frame or not frame:IsVisible() or not slot.active or not slot:IsVisible() then return false end
    local offset = not frame.docked and frame.scroll and (frame.scroll:GetVerticalScroll() or 0) or 0
    return slot.y + slot.size > offset and slot.y < offset + frame.viewportHeight
end
local function ProfessionSpell()
    local profession = displayed and displayed.kind == "profession" and displayed.profession
    local spellID = profession and profession.spellID
    if Positive(spellID) then return spellID end
end
local function RefreshProfessionClick(slot)
    if not slot then return end
    local proxy = slot.professionClickProxy
    if not proxy then
        if not Visible(slot) or not ProfessionSpell() then return end
        proxy = Flux.SecureClickProxy
        if not proxy or not proxy.Refresh or not proxy.Attach then return end
        proxy.Attach(slot, {
            spell = ProfessionSpell,
            enabled = function()
                return not InCombat() and Visible(slot) and ProfessionSpell() ~= nil and displayed.canAct == true
            end,
            clicks = "LeftButtonUp",
        })
        slot.professionClickProxy = proxy
    end
    proxy.Refresh(slot)
end
local function EndTip(self)
    if not self.hovered then return end
    self.hovered = nil
    if GameTooltip and (not GameTooltip.IsOwned or GameTooltip:IsOwned(self)) then GameTooltip:Hide() end
end
local function Tooltip(self, force)
    if not displayed or not GameTooltip or InCombat() or not Visible(self) then return end
    local item, text = (L.AH_FOLLOWUP_ITEM or "%d %s"):format(self.quantity, ItemName(self.itemID)), Text(displayed)
    local kind = CaptionKind(displayed)
    local help = ResumeHelp(displayed) or L["AH_FOLLOWUP_" .. kind .. "_HELP"]
    if displayed.vendorProvider then help = L.AH_FOLLOWUP_COMPANION_VENDOR_HELP or help end
    if kind == "NATIVE_CRAFT_PREPARED" and help then
        help = help:format(displayed.nativeCraftPrepared)
    elseif kind == "NATIVE_CRAFT" and L.AH_FOLLOWUP_NATIVE_CRAFT_BATCH_HELP and Positive(displayed.nativeCraftOperations) then
        help = L.AH_FOLLOWUP_NATIVE_CRAFT_BATCH_HELP:format(displayed.nativeCraftOperations)
    end
    local price = displayed.offer and displayed.offer.total
    if price then price = GetMoneyString and GetMoneyString(price) or FluxAuctionRestock.PriceText(price) end
    if not help and displayed.kind == "crafting" then help = L.AH_FOLLOWUP_CRAFT_HELP end
    if not force and self.hovered and self.tipItem == item and self.tipText == text
        and self.tipPrice == price and self.tipHelp == help and self.tipCommon == L.AH_FOLLOWUP_HELP
        and GameTooltip.IsOwned and GameTooltip:IsOwned(self) then return end
    self.hovered = true
    self.tipItem, self.tipText, self.tipPrice, self.tipHelp, self.tipCommon = item, text, price, help, L.AH_FOLLOWUP_HELP
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:ClearLines()
    GameTooltip:AddLine(item, 1, 0.82, 0.2, true)
    GameTooltip:AddLine(text, 1, 1, 1, true)
    if price then GameTooltip:AddLine(price, 1, 1, 1, true) end
    if L.AH_FOLLOWUP_HELP then GameTooltip:AddLine(L.AH_FOLLOWUP_HELP, 1, 1, 1, true) end
    if help then GameTooltip:AddLine(help, 0.8, 0.8, 0.8, true) end
    GameTooltip:Show()
end
local function ScrollBar()
    local scroll = frame and frame.scroll
    return scroll and (scroll.ScrollBar or _G[scroll:GetName() .. "ScrollBar"])
end
local function RetireVisuals()
    if not frame or frame.retired then return end
    frame.retired = true
    layoutDirty = true -- restore native scrollbar state after a real hide
    if WatchBounds then WatchBounds(false) end
    if frame.scroll then frame.scroll:EnableMouseWheel(false); local bar = ScrollBar(); if bar then bar:Hide() end end
    for _, slot in ipairs(icons) do
        StopGlow(slot)
        if slot.followupEnabled ~= false then slot:SetEnabled(false); slot.followupEnabled = false end
        EndTip(slot)
    end
    RefreshProfessionClick(icons[1])
end
local function Hide()
    if frame then
        if frame:IsShown() then frame:Hide() else RetireVisuals() end
    end
end
local function AboveProfession(surface, strata, level)
    local isVisible = surface and (surface.IsVisible or surface.IsShown)
    if not isVisible or not isVisible(surface) or not surface.GetFrameStrata or not surface.GetFrameLevel then
        return strata, level
    end
    local surfaceStrata = surface:GetFrameStrata()
    local rank = strataRank[surfaceStrata]
    if not rank or rank < strataRank[strata] then return strata, level end
    -- Clear the stock controls and the workbench's nested Flowchart cards.
    local above = math.min(surface:GetFrameLevel() + SURFACE_CLEARANCE, 10000)
    if rank > strataRank[strata] then return surfaceStrata, math.max(HUD_LEVEL, above) end
    return strata, math.max(level, above)
end
local function FrameVisible(surface)
    local visible = surface and (surface.IsVisible or surface.IsShown)
    return visible and visible(surface)
end

local function OnProfessionVisibilityChanged()
    if displayed then F.Paint(displayed) end
end
local function ObserveProfessionSurface(surface)
    if not surface or not surface.HookScript or professionHooks[surface] then return end
    professionHooks[surface] = true
    surface:HookScript("OnShow", OnProfessionVisibilityChanged)
    surface:HookScript("OnHide", OnProfessionVisibilityChanged)
end

local function ProfessionTarget()
    local modern, legacy = _G.ProfessionsFrame, _G.TradeSkillFrame
    ObserveProfessionSurface(modern)
    ObserveProfessionSurface(legacy)
    local page = modern and modern.CraftingPage
    local book = modern and modern.BookPage
    local modernCreate = page and page.CreateButton
    local legacyCreate = _G.TradeSkillCreateButton
    ObserveProfessionSurface(page)
    ObserveProfessionSurface(book)
    ObserveProfessionSurface(modernCreate)
    ObserveProfessionSurface(legacyCreate)
    for _, tab in ipairs(modern and modern.Pages or {}) do ObserveProfessionSurface(tab) end
    local surface, hasWorkbenchAction, anchor, alignment
    if professionSurfaceReader then surface, hasWorkbenchAction, anchor, alignment = professionSurfaceReader() end
    ObserveProfessionSurface(surface)
    if FrameVisible(surface) then
        if FrameVisible(anchor) then return surface, anchor, alignment or "center" end
        if hasWorkbenchAction == true then return end -- An older Flowcraft supplies its own action.
        return surface, surface, "inside"
    end
    if FrameVisible(modern) then
        if FrameVisible(page) and FrameVisible(modernCreate) then return modern, modernCreate, "above" end
        return modern, modern, "inside"
    end
    if FrameVisible(legacy) then
        if FrameVisible(legacyCreate) then return legacy, legacyCreate, "above" end
        return legacy, legacy, "inside"
    end
end

local function ApplyProfessionLayer(surface, anchor)
    local professions = _G.ProfessionsFrame
    local strata, level
    if surface then
        strata, level = surface:GetFrameStrata(), surface:GetFrameLevel()
        if anchor.GetFrameLevel then level = math.max(level, anchor:GetFrameLevel()) end
        if surface == professions then
            local page, book = surface.CraftingPage, surface.BookPage
            if FrameVisible(page) then level = math.max(level, page:GetFrameLevel()) end
            if FrameVisible(book) then level = math.max(level, book:GetFrameLevel()) end
            for _, tab in ipairs(surface.Pages or {}) do
                if FrameVisible(tab) then level = math.max(level, tab:GetFrameLevel()) end
            end
        end
        level = math.min(level + 3, 10000)
    else
        strata, level = AboveProfession(professions, HUD_STRATA, HUD_LEVEL)
        strata, level = AboveProfession(professions and professions.CraftingPage, strata, level)
        strata, level = AboveProfession(professions and professions.BookPage, strata, level)
        strata, level = AboveProfession(_G.TradeSkillFrame, strata, level)
        if professionSurfaceReader then
            strata, level = AboveProfession(professionSurfaceReader(), strata, level)
        end
    end
    if frame.hudStrata ~= strata then frame:SetFrameStrata(strata); frame.hudStrata = strata end
    if frame.hudLevel ~= level then frame:SetFrameLevel(level); frame.hudLevel = level end
end
function F.RefreshProfessionLayer()
    OnProfessionVisibilityChanged()
end
F.HasProfessionReminderDock = true
function F.SetProfessionSurfaceReader(reader)
    if type(reader) ~= "function" then return false end
    professionSurfaceReader = reader
    F.RefreshProfessionLayer()
    return true
end
local function Place(surface, target, alignment)
    local parent = surface or UIParent
    if not surface then
        local host = _G.FluxExtraAbilityHost
        local window = _G.FluxWindowFrame
        target = host or (window and window.GetFrame and window:GetFrame())
        if not target then return false end
        alignment = host and "host" or "hud"
    end
    if frame.anchor ~= target or frame.anchorAlignment ~= alignment or frame.anchorSurface ~= surface then
        for _, slot in ipairs(icons) do EndTip(slot) end
        if frame:GetParent() ~= parent then frame:SetParent(parent) end
        frame:ClearAllPoints()
        local y = -CAPTION_HEIGHT / 2 - VERTICAL_DROP
        if alignment == "host" then frame:SetPoint("RIGHT", target, "LEFT", -8 + HORIZONTAL_SHIFT, y)
        elseif alignment == "hud" then frame:SetPoint("CENTER", target, "TOPLEFT", -90 + HORIZONTAL_SHIFT, 94 + y)
        elseif alignment == "center" then frame:SetPoint("CENTER", target, "CENTER")
        elseif alignment == "above" then frame:SetPoint("BOTTOMRIGHT", target, "TOPRIGHT", 0, 4)
        else frame:SetPoint("TOPRIGHT", target, "TOPRIGHT", -42, -30) end
        frame.anchor, frame.anchorAlignment, frame.anchorSurface = target, alignment, surface
    end
    return true
end
local function PlacementChanged()
    if frame and displayed then F.Paint(displayed) end
end
local function InstallPlacementHooks()
    local window = _G.FluxWindowFrame
    if not window or hooked[window] or not hooksecurefunc then return end
    hooked[window] = true
    for _, name in ipairs({ "SetOffset", "ApplyBottomLiftFromStatusBar" }) do
        if type(window[name]) == "function" then hooksecurefunc(window, name, PlacementChanged) end
    end
end
local function Font(region, size)
    local font = region:GetFont()
    if font then region:SetFont(font, size, "OUTLINE") end
    region:SetShadowColor(0, 0, 0, 1); region:SetShadowOffset(1, -1)
end
local function EnsureFrame()
    if frame then return frame end
    if InCombat() then return end
    frame = CreateFrame("Frame", "FluxAuctionRestockFollowupFrame", UIParent)
    frame:Hide(); frame:SetClampedToScreen(true); frame:EnableMouse(false)
    frame:SetFrameStrata(HUD_STRATA); frame:SetFrameLevel(HUD_LEVEL)
    frame.hudStrata, frame.hudLevel = HUD_STRATA, HUD_LEVEL
    frame.content = CreateFrame("Frame", nil, frame); frame.content:EnableMouse(false)
    frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.label:SetJustifyH("CENTER"); frame.label:SetWordWrap(true)
    frame.label:SetTextColor(1, 0.94, 0.7, 1); Font(frame.label, 14)
    frame.caption = frame:CreateTexture(nil, "BACKGROUND")
    frame.caption:SetColorTexture(0.015, 0.015, 0.025, 0.94)
    frame:SetScript("OnHide", RetireVisuals)
    frame.retired = true
    frame.icons, F.frame, F.icons, F.buttons = icons, frame, icons, icons
    return frame
end
local function EnsureIcon(index)
    if icons[index] then return icons[index] end
    local slot = CreateFrame("Button", index == 1 and "FluxAuctionRestockFollowupButton" or nil, frame.content)
    slot:RegisterForClicks("LeftButtonUp")
    if slot.SetMotionScriptsWhileDisabled then slot:SetMotionScriptsWhileDisabled(true) end
    slot:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    slot:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    slot.border, slot.icon = slot:CreateTexture(nil, "BACKGROUND"), slot:CreateTexture(nil, "ARTWORK")
    slot.border:SetTexture("Interface\\Buttons\\UI-Quickslot2"); slot:SetNormalTexture(slot.border)
    slot.count = slot:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    slot.count:SetTextColor(1, 1, 1, 1); slot.count:SetJustifyH("RIGHT"); slot.count:SetWordWrap(false)
    slot:SetScript("OnEnter", function(self) Tooltip(self, true) end); slot:SetScript("OnLeave", EndTip)
    slot:SetScript("OnHide", function(self)
        StopGlow(self); EndTip(self)
        if self.professionClickProxy then self.professionClickProxy.Refresh(self) end
    end)
    slot:SetScript("OnClick", function(self)
        if InCombat() or not Visible(self) or not Actionable(displayed) or displayed.canAct ~= true then return end
        if frame.docked and frame.dockAction and F.ClickProfessionWindowAction then
            F.ClickProfessionWindowAction(frame.dockAction)
        elseif displayed.kind == "profession" then F.ClickProfession(displayed)
        else F.Click() end -- every item requests all available targets in the current step
    end)
    icons[index] = slot
    if index == 1 then F.button = slot end
    return slot
end
local function EnsureScroll()
    if frame.scroll then return frame.scroll end
    local scroll = CreateFrame("ScrollFrame", "FluxAuctionRestockFollowupScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.scroll = scroll
    scroll:EnableMouse(false); scroll:EnableMouseWheel(true)
    frame.content:SetParent(scroll); scroll:SetScrollChild(frame.content)
    -- The template retains its native scrollbar, range and vertical-scroll owners.
    scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.min(frame.maxScroll or 0, math.max(0, (self:GetVerticalScroll() or 0) - delta * 46)))
    end)
    scroll:HookScript("OnVerticalScroll", function() if UpdateButtons then UpdateButtons() end end)
    return scroll
end
local function IconSize(count)
    if count == 1 then return 44 elseif count <= 2 then return 40 elseif count <= 5 then return 36
    elseif count <= 20 then return 34 else return 32 end
end
local function ScreenBounds()
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    return math.max(1, width - SCREEN_MARGIN * 2), math.max(1, height - SCREEN_MARGIN * 2)
end
local function LayoutIcon(slot, size, x, y)
    if slot.glowSize and slot.glowSize ~= size then StopGlow(slot) end
    slot.x, slot.y, slot.size = x, y, size
    slot:ClearAllPoints(); slot:SetPoint("TOPLEFT", frame.content, "TOPLEFT", x, -y); slot:SetSize(size, size)
    slot.border:ClearAllPoints(); slot.border:SetPoint("TOPLEFT", slot, "TOPLEFT", 0, 0); slot.border:SetSize(size, size)
    slot.icon:ClearAllPoints(); slot.icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 3, -3); slot.icon:SetSize(size - 6, size - 6)
    slot.count:ClearAllPoints(); slot.count:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1)
    slot.count:SetSize(size, math.max(10, math.floor(size * 0.45))); Font(slot.count, math.max(8, math.min(12, math.floor(size * 0.4))))
end

local function LayoutDock()
    frame:SetSize(DOCK_WIDTH, DOCK_HEIGHT)
    frame.iconSize, frame.columns, frame.rows, frame.itemCount = DOCK_ICON_SIZE, 1, 1, 1
    frame.overflow, frame.viewportHeight, frame.contentHeight = false, DOCK_HEIGHT, DOCK_HEIGHT
    frame.maxScroll = 0
    if frame.content:GetParent() ~= frame then frame.content:SetParent(frame) end
    if frame.scroll then
        frame.scroll:EnableMouseWheel(false)
        if frame.scroll:GetVerticalScroll() ~= 0 then frame.scroll:SetVerticalScroll(0) end
        local bar = ScrollBar(); if bar then bar:Hide() end
        frame.scroll:Hide()
    end
    frame.content:ClearAllPoints()
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.content:SetSize(DOCK_WIDTH, DOCK_HEIGHT)
    local inset = DOCK_ICON_SIZE + 14
    LayoutIcon(EnsureIcon(1), DOCK_ICON_SIZE, 7, (DOCK_HEIGHT - DOCK_ICON_SIZE) / 2)
    frame.label:ClearAllPoints()
    frame.label:SetPoint("LEFT", frame, "LEFT", inset, 0)
    frame.label:SetSize(DOCK_WIDTH - inset - 6, DOCK_HEIGHT - 2)
    frame.label:SetJustifyH("LEFT"); Font(frame.label, 12)
    frame.caption:ClearAllPoints()
    frame.caption:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.caption:SetSize(DOCK_WIDTH, DOCK_HEIGHT)
end

local function Layout(count)
    local maxWidth, maxHeight = ScreenBounds()
    if not layoutDirty and layoutCount == count and layoutWidth == maxWidth and layoutHeight == maxHeight then return end
    layoutDirty, layoutCount, layoutWidth, layoutHeight = false, count, maxWidth, maxHeight
    frame.layouting = true
    if frame.docked then
        LayoutDock()
        frame.layouting = nil
        return
    end
    local size = IconSize(count)
    local cols = math.min(count, math.max(1, math.floor((math.min(MAX_GRID_WIDTH, maxWidth - PADDING * 2) + GAP) / (size + GAP))))
    local maxRows = math.max(1, math.floor((maxHeight - CAPTION_HEIGHT - PADDING * 2 + GAP) / (size + GAP)))
    if math.ceil(count / cols) > maxRows then
        local maxCols = math.max(1, math.floor((maxWidth - PADDING * 2 + GAP) / (size + GAP)))
        cols = math.min(maxCols, math.max(cols, math.ceil(count / maxRows)))
    end
    local rows = math.ceil(count / cols)
    local overflow = rows > maxRows
    if overflow then
        cols = math.max(1, math.floor((maxWidth - PADDING * 2 - SCROLLBAR_WIDTH + GAP) / (size + GAP)))
        rows = math.ceil(count / cols)
    end
    local gridWidth, gridHeight = cols * (size + GAP) - GAP, rows * (size + GAP) - GAP
    local areaWidth = math.min(maxWidth - (overflow and SCROLLBAR_WIDTH or 0), math.max(188, gridWidth) + PADDING * 2)
    local width = areaWidth + (overflow and SCROLLBAR_WIDTH or 0)
    local contentHeight = gridHeight + PADDING * 2
    local height = math.min(maxHeight, contentHeight + CAPTION_HEIGHT)
    local viewportHeight = height - CAPTION_HEIGHT
    frame:SetSize(width, height)
    frame.iconSize, frame.columns, frame.rows, frame.itemCount = size, cols, rows, count
    frame.overflow, frame.viewportHeight, frame.contentHeight = overflow, viewportHeight, contentHeight
    frame.maxScroll = math.max(0, contentHeight - viewportHeight)
    local scroll = overflow and EnsureScroll() or frame.scroll
    frame.content:ClearAllPoints()
    frame.content:SetSize(areaWidth, contentHeight)
    if scroll then
        if frame.content:GetParent() ~= scroll then frame.content:SetParent(scroll) end
        scroll:ClearAllPoints(); scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0); scroll:SetSize(areaWidth, viewportHeight)
        frame.content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
        scroll:EnableMouseWheel(overflow); scroll:Show()
        local bar = ScrollBar(); if bar then if overflow then bar:Show() else bar:Hide() end end
        local offset = scroll:GetVerticalScroll() or 0
        if not overflow or offset > frame.maxScroll then scroll:SetVerticalScroll(overflow and frame.maxScroll or 0) end
    else frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0) end
    local inset = (areaWidth - gridWidth) / 2
    for index = 1, count do
        LayoutIcon(EnsureIcon(index), size, inset + (index - 1) % cols * (size + GAP),
            PADDING + math.floor((index - 1) / cols) * (size + GAP))
    end
    frame.label:ClearAllPoints(); frame.label:SetPoint("TOP", frame, "TOP", 0, -viewportHeight)
    frame.label:SetSize(width - PADDING * 2, CAPTION_HEIGHT - 4)
    if frame.labelDocked then frame.label:SetJustifyH("CENTER"); Font(frame.label, 14) end
    frame.caption:ClearAllPoints(); frame.caption:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -viewportHeight)
    frame.caption:SetSize(width, CAPTION_HEIGHT)
    frame.layouting = nil
end
local function Content(list)
    local ic = _G.FluxItemClass
    for index, entry in ipairs(list) do
        local slot = icons[index]
        if slot.itemID ~= entry.itemID then StopGlow(slot); EndTip(slot); slot.itemID = entry.itemID end
        if slot.quantity ~= entry.quantity then slot.quantity = entry.quantity; slot.count:SetText(tostring(entry.quantity)) end
        local texture = ic and ic.GetIcon and ic.GetIcon(entry.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark"
        if slot.texture ~= texture then slot.texture = texture; slot.icon:SetTexture(texture) end
        slot.active = true
        if not slot:IsShown() then slot:Show() end
    end
    for index = #list + 1, #icons do
        local slot = icons[index]
        if slot.active then
            slot.itemID, slot.quantity, slot.active = nil, nil, false
            StopGlow(slot); EndTip(slot); slot.count:SetText("")
            if slot:IsShown() then slot:Hide() end
        end
    end
end
UpdateButtons = function()
    if not frame or frame.layouting then return end
    local canAct = not InCombat() and Actionable(displayed) == true and displayed.canAct == true
    local lib, kind, resolved
    frame.retired = false
    for _, slot in ipairs(icons) do
        local visible = not InCombat() and Visible(slot)
        local enabled = visible and canAct
        if slot.followupEnabled ~= enabled then slot:SetEnabled(enabled); slot.followupEnabled = enabled end
        if not enabled then StopGlow(slot)
        elseif not slot.glowLib or slot.glowSize ~= slot.size or slot.glowKind ~= "proc" then
            if not resolved then lib, kind = Renderer(); resolved = true end
            Glow(slot, true, lib, kind)
        end
        if not visible and slot.hovered then EndTip(slot) end
    end
    RefreshProfessionClick(icons[1])
end
function F.Paint(state)
    -- Waiting is bookkeeping; inventory/profession events prepare the next action.
    if state and state.kind == "waiting" then state = nil end
    displayed = state
    if not state or InCombat() then Hide(); return end
    local list = Entries(state)
    if #list == 0 then Hide(); return end
    local widget = EnsureFrame()
    InstallPlacementHooks()
    if not widget then return end
    local surface, anchor, alignment
    if #list == 1 and (state.kind == "craft" or state.kind == "crafting" or state.kind == "profession") then
        surface, anchor, alignment = ProfessionTarget()
    end
    local docked = surface ~= nil
    if widget.docked ~= docked then layoutDirty = true end
    widget.docked = docked
    widget.dockAction = docked and F.GetProfessionWindowAction and F.GetProfessionWindowAction() or nil
    widget.retired = false
    Layout(#list); Content(list)
    widget.labelDocked = docked
    if not Place(surface, anchor, alignment) then Hide(); return end
    ApplyProfessionLayer(surface, anchor)
    local text = Text(state)
    if widget.text ~= text then widget.text = text; widget.label:SetText(text) end
    if not widget:IsShown() then widget:Show() end
    UpdateButtons(); WatchBounds(true)
    for _, slot in ipairs(icons) do if slot.hovered then Tooltip(slot) end end
end
local boundsListening = false
local function BoundsChanged()
    if frame and displayed then
        layoutDirty = true
        if InCombat() then Hide() else F.Paint(displayed) end
    end
end
WatchBounds = function(enabled)
    if boundsListening == enabled then return end
    boundsListening = enabled
    for _, event in ipairs({ "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED" }) do
        if enabled then Flux.Events.Register(event, BoundsChanged)
        elseif Flux.Events.Unregister then Flux.Events.Unregister(event, BoundsChanged) end
    end
end
Flux.Events.Register("PLAYER_REGEN_DISABLED", Hide)
Flux.Events.Register("PLAYER_REGEN_ENABLED", function() InstallPlacementHooks(); F.Refresh() end)
Flux.Events.Register("PLAYER_LOGIN", function() InstallPlacementHooks(); F.Refresh() end)
Flux.Events.Register("ADDON_LOADED", function(_, name)
    if name == "Blizzard_Professions" or name == "Blizzard_TradeSkillUI" then OnProfessionVisibilityChanged() end
end)
