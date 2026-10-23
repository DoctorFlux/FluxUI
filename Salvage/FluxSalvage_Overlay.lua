-- FluxSalvage_Overlay.lua
-- Secure overlay button for one-click salvage actions (ported from Molinari addon.lua)

FluxSalvage = FluxSalvage or {}
local S = FluxSalvage

local ERR_COLOR = CreateColor(1, 32 / 255, 32 / 255)
local MACRO_SALVAGE = "/run C_TradeSkillUI.CraftSalvage(%d, 1, ItemLocation:CreateFromBagAndSlot(%d, %d))"
local MACRO_TRADE = "/cast %s\n/run ClickTargetTradeButton(7)"
local LOCKPICK_SPELLS = {
    [1804] = true,
    [312890] = true,
    [323427] = true,
}
local CLASSIC_STYLE_SPELLS = {
    [1804] = true,
    [312890] = true,
    [323427] = true,
    [51005] = true, -- Milling
    [31252] = true, -- Prospecting
}

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local function IsCamelotClient()
    local Flux = _G.Flux
    local C = Flux and Flux.Client
    if C and (C.isCamelot or C.isForever) then
        return true
    end
    local api = _G.FLUX_API
    return api and (api.isCamelot or api.isForever) and true or false
end

local function SnippetsWork()
    local Flux = _G.Flux
    local R = Flux and Flux.Restricted
    if R and R.Works then
        return R.Works()
    end
    local Cap = Flux and Flux.Cap
    if Cap and Cap.hasRestrictedClosures == false then
        return false
    end
    return true
end

local function IsPlayerSpell(spellID)
    if S.KnowsSpell then
        return S.KnowsSpell(spellID)
    end
    if C_SpellBook and C_SpellBook.IsSpellKnownOrInSpellBook then
        return C_SpellBook.IsSpellKnownOrInSpellBook(spellID)
    end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(spellID)
    end
    if _G.IsPlayerSpell then
        return _G.IsPlayerSpell(spellID)
    end
    return false
end

local deferFrame = CreateFrame("Frame")
local deferQueue = {}
deferFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

local function FlushDeferQueue()
    if InCombatLockdown() then
        return
    end
    while #deferQueue > 0 do
        local entry = table.remove(deferQueue, 1)
        if entry.kind == "call" then
            entry.fn()
        elseif entry.kind == "method" then
            entry.obj[entry.method](entry.obj, unpack(entry.args))
        end
    end
end

deferFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        FlushDeferQueue()
    end
end)

function S.Defer(fn)
    if InCombatLockdown() then
        deferQueue[#deferQueue + 1] = { kind = "call", fn = fn }
        return
    end
    fn()
end

function S.DeferMethod(obj, method, ...)
    if InCombatLockdown() then
        deferQueue[#deferQueue + 1] = {
            kind = "method",
            obj = obj,
            method = method,
            args = { ... },
        }
        return
    end
    obj[method](obj, ...)
end

local TEMPLATES = {
    "SecureActionButtonTemplate",
    "SecureHandlerAttributeTemplate",
    "SecureHandlerEnterLeaveTemplate",
}

local useAutoCastShine = AutoCastShine_AutoCastStart ~= nil
if useAutoCastShine then
    table.insert(TEMPLATES, "AutoCastShineTemplate")
end

local Overlay = CreateFrame("Button", "FluxSalvageOverlay", UIParent, table.concat(TEMPLATES, ","))
Overlay:SetFrameStrata("TOOLTIP")
Overlay:SetToplevel(true)
Overlay:EnableMouse(true)
Overlay:RegisterForClicks("AnyUp", "AnyDown")
Overlay:Hide()
S.Overlay = Overlay

local anchorElapsed = 0
local ANCHOR_REFRESH_SEC = 0.03

local function CanAnchorToOwner(owner)
    if not owner or not owner.IsShown or not owner:IsShown() then
        return false
    end
    if owner.IsAnchoringRestricted and owner:IsAnchoringRestricted() then
        return false
    end
    if owner.IsAnchoringSecret and owner:IsAnchoringSecret() then
        return false
    end
    return true
end

function S.AnchorOverlayToOwner(self)
    self = self or Overlay
    local owner = self.anchorOwner or GameTooltip:GetOwner()
    if not owner then
        return false
    end

    local anchored = false

    local function CoerceRectValue(v)
        local ok, n = pcall(tonumber, v)
        if ok and type(n) == "number" and n == n then
            return n
        end
    end

    local left, bottom, width, height
    if owner.GetScaledRect then
        local ok, l, b, w, h = pcall(owner.GetScaledRect, owner)
        if ok then
            left, bottom, width, height = CoerceRectValue(l), CoerceRectValue(b), CoerceRectValue(w), CoerceRectValue(h)
        end
    end
    if not (left and bottom and width and height and width > 0 and height > 0) then
        local okL, rawLeft = pcall(owner.GetLeft, owner)
        local okB, rawBottom = pcall(owner.GetBottom, owner)
        local okW, rawWidth = pcall(owner.GetWidth, owner)
        local okH, rawHeight = pcall(owner.GetHeight, owner)
        local scale = 1
        if owner.GetEffectiveScale then
            local okS, rawScale = pcall(owner.GetEffectiveScale, owner)
            if okS then
                scale = CoerceRectValue(rawScale) or 1
            end
        end
        if okL and okB and okW and okH then
            left = CoerceRectValue(rawLeft)
            bottom = CoerceRectValue(rawBottom)
            width = CoerceRectValue(rawWidth)
            height = CoerceRectValue(rawHeight)
            if left and bottom and width and height then
                left, bottom, width, height = left * scale, bottom * scale, width * scale, height * scale
            end
        end
    end
    if left and bottom and width and height and width > 0 and height > 0 then
        local parentScale = UIParent:GetScale() or 1
        if parentScale == 0 then
            parentScale = 1
        end
        local scaleMultiplier = 1 / parentScale
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left * scaleMultiplier, bottom * scaleMultiplier)
        self:SetSize(width * scaleMultiplier, height * scaleMultiplier)
        if owner.GetFrameLevel then
            local okLevel, level = pcall(owner.GetFrameLevel, owner)
            if okLevel and type(level) == "number" then
                self:SetFrameLevel(level + 30)
            end
        end
        self:EnableMouse(true)
        anchored = true
    end

    if not anchored and CanAnchorToOwner(owner) then
        local ok = pcall(function()
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
            self:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 0, 0)
        end)
        if ok then
            if owner.GetFrameLevel then
                self:SetFrameLevel(owner:GetFrameLevel() + 30)
            end
            self:EnableMouse(true)
            anchored = true
        end
    end

    if anchored and self.glowColor then
        S.SetOverlayColor(self.glowColor)
    end

    return anchored
end

local function ClearOverlayAction()
    Overlay:SetAttribute("type", nil)
    Overlay:SetAttribute("type1", nil)
    Overlay:SetAttribute("typerelease", nil)
    Overlay:SetAttribute("alt-type1", nil)
    Overlay:SetAttribute("alt-ctrl-type1", nil)
    Overlay:SetAttribute("alt-shift-type1", nil)
    Overlay:SetAttribute("spell", nil)
    Overlay:SetAttribute("macrotext", nil)
    Overlay:SetAttribute("item", nil)
end

local function SpellAttributeValue(spellID)
    if IsCamelotClient() then
        if C_Spell and C_Spell.GetSpellName then
            local ok, name = pcall(C_Spell.GetSpellName, spellID)
            if ok and type(name) == "string" and name ~= "" then
                return name
            end
        end
        if GetSpellInfo then
            local name = GetSpellInfo(spellID)
            if type(name) == "string" and name ~= "" then
                return name
            end
        end
    end
    return spellID
end

local function BindOverlayClickType(attrType)
    Overlay:SetAttribute("type", attrType)
    Overlay:SetAttribute("type1", attrType)
    Overlay:SetAttribute("typerelease", attrType)
    local modifier = S.GetModifier()
    if modifier == "CTRL" then
        Overlay:SetAttribute("alt-ctrl-type1", attrType)
    elseif modifier == "SHIFT" then
        Overlay:SetAttribute("alt-shift-type1", attrType)
    else
        Overlay:SetAttribute("alt-type1", attrType)
    end
end

local function ShouldUseCraftSalvage(spellID)
    if not isRetail then
        return false
    end
    if IsCamelotClient() then
        return false
    end
    if not (C_TradeSkillUI and C_TradeSkillUI.CraftSalvage) then
        return false
    end
    if LOCKPICK_SPELLS[spellID] or CLASSIC_STYLE_SPELLS[spellID] then
        return false
    end
    if S.IsComprehendSpell and S.IsComprehendSpell(spellID) then
        return false
    end
    -- Retail salvage (mill, prospect, disenchant, etc.) must target the bag slot via CraftSalvage.
    -- The spell attribute only casts without applying to the hovered item.
    return true
end

local function SetOverlaySpellAction(spell, bagID, slotID)
    ClearOverlayAction()
    if type(spell) == "number" and ShouldUseCraftSalvage(spell) then
        Overlay:SetAttribute("macrotext", MACRO_SALVAGE:format(spell, bagID, slotID))
        BindOverlayClickType("macro")
        return
    end
    local value = spell
    if type(spell) == "number" then
        value = SpellAttributeValue(spell)
    end
    Overlay:SetAttribute("spell", value)
    BindOverlayClickType("spell")
end

local function TooltipHelp(msg, color)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(msg, color and color:GetRGB())
    GameTooltip:Show()
end

function S.ApplySpellToBagSlot(bagID, slotID, spellID, color, owner)
    bagID = tonumber(bagID)
    slotID = tonumber(slotID)
    if not bagID or not slotID or spellID == nil or spellID == false then
        return
    end
    Overlay:SetAttribute("target-bag", bagID)
    Overlay:SetAttribute("target-slot", slotID)
    SetOverlaySpellAction(spellID, bagID, slotID)
    Overlay.spellID = spellID
    Overlay.spellName = type(spellID) == "string" and spellID or SpellAttributeValue(spellID)
    Overlay.anchorOwner = owner or GameTooltip:GetOwner()
    Overlay:Show()
    S.AnchorOverlayToOwner(Overlay)
    S.SetOverlayColor(color)
end

function S.ApplySpell(item, spellID, color, bagID, slotID, owner)
    owner = owner or GameTooltip:GetOwner()
    if (not bagID or not slotID) and item and item.GetItemLocation then
        local ok, location = pcall(item.GetItemLocation, item)
        if ok and location and location.IsBagAndSlot and location:IsBagAndSlot() then
            bagID, slotID = location:GetBagAndSlot()
        end
    end
    if bagID and slotID then
        return S.ApplySpellToBagSlot(bagID, slotID, spellID, color, owner)
    end
    if item and item.GetItemLink and GetTradeTargetItemLink and color == S.Colors.openable then
        local link = item:GetItemLink()
        if link and link == GetTradeTargetItemLink(7) then
            ClearOverlayAction()
            local spellName = spellID
            if C_Spell and C_Spell.GetSpellName then
                local ok, name = pcall(C_Spell.GetSpellName, spellID)
                if ok and name then
                    spellName = name
                end
            end
            Overlay:SetAttribute("macrotext", MACRO_TRADE:format(spellName))
            BindOverlayClickType("macro")
            Overlay.itemLink = link
            Overlay.spellID = spellID
            Overlay.anchorOwner = owner
            Overlay:Show()
            S.AnchorOverlayToOwner(Overlay)
            S.SetOverlayColor(color)
        end
    end
end

function S.ApplyItem(item, key, color, bagID, slotID, owner)
    owner = owner or GameTooltip:GetOwner()
    if (not bagID or not slotID) and item and item.GetItemLocation then
        local ok, location = pcall(item.GetItemLocation, item)
        if ok and location and location.IsBagAndSlot and location:IsBagAndSlot() then
            bagID, slotID = location:GetBagAndSlot()
        end
    end
    if not bagID or not slotID then
        return
    end
    Overlay:SetAttribute("target-bag", bagID)
    Overlay:SetAttribute("target-slot", slotID)
    ClearOverlayAction()
    Overlay:SetAttribute("item", "item:" .. key)
    BindOverlayClickType("item")

    Overlay.itemID = key
    Overlay.anchorOwner = owner
    Overlay:Show()
    S.AnchorOverlayToOwner(Overlay)
    S.SetOverlayColor(color)
end

function S.UpdateAttributeDriver()
    if not SnippetsWork() then
        return
    end
    local modifier = S.GetModifier()
    if modifier == "CTRL" then
        S.Defer(function() RegisterAttributeDriver(Overlay, "visibility", "[mod:alt,mod:ctrl] show; hide") end)
    elseif modifier == "SHIFT" then
        S.Defer(function() RegisterAttributeDriver(Overlay, "visibility", "[mod:alt,mod:shift] show; hide") end)
    else
        S.Defer(function() RegisterAttributeDriver(Overlay, "visibility", "[mod:alt] show; hide") end)
    end
end

Overlay:HookScript("OnAttributeChanged", function(self, name)
    if name ~= "spell" and name ~= "item" and name ~= "macrotext" then
        return
    end

    local attrType = name:gsub("macrotext", "macro")
    BindOverlayClickType(attrType)
end)

Overlay:HookScript("OnShow", function(self)
    S.AnchorOverlayToOwner(self)
    if self.glowColor then
        S.SetOverlayColor(self.glowColor)
    end
    self:SetAttribute("_entered", true)
    -- Arm OnUpdate only while shown (avoid permanent HookScript tick when hidden).
    self:SetScript("OnUpdate", function(frame, elapsed)
        if not frame:IsShown() then
            frame:SetScript("OnUpdate", nil)
            anchorElapsed = 0
            return
        end
        if not SnippetsWork() and S.ModifierActive and not S.ModifierActive() then
            S.HideOverlay()
            anchorElapsed = 0
            return
        end
        if frame.spellID == 13262 then
            local bagID = frame:GetAttribute("target-bag")
            local slotID = frame:GetAttribute("target-slot")
            if bagID and slotID and S.IsBagSlotProtected(bagID, slotID) then
                S.HideOverlay()
                local lock = _G.FluxRespec and _G.FluxRespec.GearSetLock
                if lock and lock.NotifyBlocked then
                    lock.NotifyBlocked()
                end
                anchorElapsed = 0
                return
            end
        end
        anchorElapsed = anchorElapsed + elapsed
        if anchorElapsed >= ANCHOR_REFRESH_SEC then
            anchorElapsed = 0
            S.AnchorOverlayToOwner(frame)
        end
    end)
end)

if SnippetsWork() then
    Overlay:SetAttribute("_onleave", "self:ClearAllPoints();self:Hide()")

    Overlay:SetAttribute("_onattributechanged", [[
        if name == 'visibility' and value == 'hide' and self:IsShown() then
            self:ClearAllPoints()
            self:Hide()
        end
    ]])
end

Overlay:HookScript("OnHide", function(self)
    self:SetScript("OnUpdate", nil)
    self.itemLink = nil
    self.spellID = nil
    self.spellName = nil
    self.itemID = nil
    self.anchorOwner = nil
    self.glowColor = nil
    anchorElapsed = 0
    S.DeferMethod(self, "SetAttribute", "target-bag")
    S.DeferMethod(self, "SetAttribute", "target-slot")
    S.DeferMethod(self, "SetAttribute", "_entered", false)
    S.Defer(function()
        ClearOverlayAction()
    end)
end)

local function OverlayTooltipShow(self)
    if self:GetRight() >= GetScreenWidth() / 2 then
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    else
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    end

    if self.itemLink then
        GameTooltip:SetHyperlink(self.itemLink)
    else
        GameTooltip:SetBagItem(self:GetAttribute("target-bag"), self:GetAttribute("target-slot"))
    end

    if self.spellID and NPEV2_CASTER_ABILITYINITIAL then
        local hint = (("\n"):split(NPEV2_CASTER_ABILITYINITIAL:gsub(" %%s ", "%s")))
        local spellName = self.spellName
        if not spellName and type(self.spellID) == "number" and C_Spell and C_Spell.GetSpellName then
            local ok, name = pcall(C_Spell.GetSpellName, self.spellID)
            if ok then
                spellName = name
            end
        end
        if not spellName then
            spellName = tostring(self.spellID)
        end
        TooltipHelp(hint:format("|A:NPE_LeftClick:18:18|a", "|cff0090ff" .. spellName .. "|r"))
    elseif self.itemID and NPEV2_ABILITYINITIAL then
        TooltipHelp(NPEV2_ABILITYINITIAL:format("|A:NPE_LeftClick:18:18|a", "|cff0090ff" .. C_Item.GetItemNameByID(self.itemID) .. "|r"))
    end

    GameTooltip:Show()
end

Overlay:HookScript("OnLeave", function()
    GameTooltip_Hide()
end)
Overlay:HookScript("OnEnter", OverlayTooltipShow)

Overlay:HookScript("PreClick", function(self, button, down)
    if not down or self.spellID ~= 13262 then
        return
    end
    local bagID = self:GetAttribute("target-bag")
    local slotID = self:GetAttribute("target-slot")
    if not bagID or not slotID or not S.IsBagSlotProtected(bagID, slotID) then
        return
    end
    ClearOverlayAction()
    local lock = _G.FluxRespec and _G.FluxRespec.GearSetLock
    if lock and lock.NotifyBlocked then
        lock.NotifyBlocked()
    end
    self:Hide()
end)

local Glow, Animation, OverlayFill

local function HasProcAtlas(atlas)
    local Cap = _G.Flux and _G.Flux.Cap
    if Cap and Cap.HasAtlas then
        return Cap.HasAtlas(atlas)
    end
    local getAtlasInfo = C_Texture and C_Texture.GetAtlasInfo or GetAtlasInfo
    if getAtlasInfo then
        local ok, info = pcall(getAtlasInfo, atlas)
        return ok and info ~= nil
    end
    return false
end

if not useAutoCastShine then
    Glow = Overlay:CreateTexture(nil, "ARTWORK")
    local atlas = "UI-HUD-ActionBar-Proc-Loop-Flipbook"
    if HasProcAtlas(atlas) and Glow.SetAtlas and pcall(Glow.SetAtlas, Glow, atlas) then
        Glow:SetPoint("CENTER")
        Glow:SetDesaturated(true)

        Animation = Overlay:CreateAnimationGroup()
        Animation:SetLooping("REPEAT")

        local FlipBook = Animation:CreateAnimation("FlipBook")
        FlipBook:SetTarget(Glow)
        FlipBook:SetDuration(1)
        FlipBook:SetFlipBookColumns(5)
        FlipBook:SetFlipBookRows(6)
        FlipBook:SetFlipBookFrames(30)

        Overlay:HookScript("OnShow", function()
            Animation:Play()
        end)

        Overlay:HookScript("OnHide", function()
            Animation:Stop()
        end)
    else
        -- Atlas availability varies independently of client identity. Reuse the
        -- same texture for a visible, family-colored affordance if it cannot paint.
        OverlayFill = Glow
        OverlayFill:SetAllPoints(Overlay)
        OverlayFill:SetColorTexture(1, 1, 1, 0.2)
    end
else
    for _, sparkle in next, Overlay.sparkles do
        sparkle:SetHeight(sparkle:GetHeight() * 3)
        sparkle:SetWidth(sparkle:GetWidth() * 3)
    end

    Overlay:HookScript("OnHide", AutoCastShine_AutoCastStop)
end

function S.SetOverlayColor(color)
    if not color then
        return
    end
    Overlay.glowColor = color
    if useAutoCastShine then
        AutoCastShine_AutoCastStart(Overlay, color:GetRGB())
        return
    end
    if OverlayFill then
        OverlayFill:SetVertexColor(color:GetRGB())
        return
    end
    if Glow then
        Glow:SetVertexColor(color:GetRGB())
        local width, height = Overlay:GetSize()
        if width and height and width > 0 and height > 0 then
            Glow:SetSize(width * 1.4, height * 1.4)
        end
    end
end

function S.HideOverlay()
    if Overlay:IsShown() and not InCombatLockdown() then
        Overlay:Hide()
    end
end

local function TooltipTextBlob(tooltip)
    if not tooltip then
        return ""
    end
    local parts = {}
    local n = 0
    if tooltip.NumLines then
        n = tooltip:NumLines() or 0
    end
    local prefix = tooltip.GetName and tooltip:GetName()
    for i = 1, math.min(n, 40) do
        local left = (prefix and _G[prefix .. "TextLeft" .. i]) or tooltip["TextLeft" .. i]
        local right = (prefix and _G[prefix .. "TextRight" .. i]) or tooltip["TextRight" .. i]
        local lt = left and left.GetText and left:GetText()
        local rt = right and right.GetText and right:GetText()
        if type(lt) == "string" and lt ~= "" then
            parts[#parts + 1] = lt
        end
        if type(rt) == "string" and rt ~= "" then
            parts[#parts + 1] = rt
        end
    end
    if #parts == 0 and tooltip.GetRegions then
        local regions = { tooltip:GetRegions() }
        for i = 1, #regions do
            local r = regions[i]
            if r and r.GetText then
                local t = r:GetText()
                if type(t) == "string" and t ~= "" then
                    parts[#parts + 1] = t
                end
            end
        end
    end
    return table.concat(parts, "\n")
end

local function GetLiveSkillHint(tooltip, bagID, slotID)
    local Flux = _G.Flux
    local P = Flux and Flux.Inventory and Flux.Inventory.Professions
    local hint
    if P then
        if tooltip and P.GetSkillRequirementFromTooltip then
            hint = P.GetSkillRequirementFromTooltip(tooltip)
        end
        if not hint and tooltip and P.GetSkillRequirementFromTooltipData then
            local data = tooltip.GetTooltipData and tooltip:GetTooltipData()
            if data then
                hint = P.GetSkillRequirementFromTooltipData(data)
            end
        end
        if not hint and bagID and slotID and P.GetSkillRequirementFromBagSlot then
            hint = P.GetSkillRequirementFromBagSlot(bagID, slotID)
        end
    end
    if (not hint or not hint.skillName) and S.HintFromTooltipText then
        hint = S.HintFromTooltipText(TooltipTextBlob(tooltip)) or hint
    end
    return hint
end

function S.HandleTooltip(tooltip, item, bagID, slotID, owner)
    tooltip = tooltip or GameTooltip
    if not tooltip or tooltip:IsForbidden() then
        return
    end
    if tooltip.GetOwner and tooltip:GetOwner() == Overlay then
        return
    end

    if InCombatLockdown() then
        return
    end

    if UnitHasVehicleUI and UnitHasVehicleUI("player") then
        return
    end

    if (PaperDollFrameItemFlyoutButtons or EquipmentFlyoutFrame)
        and (PaperDollFrameItemFlyoutButtons or EquipmentFlyoutFrame):IsVisible() then
        return
    end

    if (AuctionFrame or AuctionHouseFrame) and (AuctionFrame or AuctionHouseFrame):IsVisible() then
        return
    end

    if not S.ModifierActive() then
        return
    end

    owner = owner or (tooltip.GetOwner and tooltip:GetOwner())

    local location
    if item and item.GetItemLocation then
        local ok, loc = pcall(item.GetItemLocation, item)
        if ok then
            location = loc
        end
    end
    if (not bagID or not slotID) and location and location.IsBagAndSlot and location:IsBagAndSlot() then
        bagID, slotID = location:GetBagAndSlot()
    end

    local itemID = S.ResolveItemID(item, bagID, slotID)
    local hint = GetLiveSkillHint(tooltip, bagID, slotID)
    if not itemID and not hint then
        return
    end

    local spellID, color, numItemsRequired = S.IsSalvageable(itemID, hint)
    if spellID then
        if spellID == 13262 then
            if S.NonDisenchantable(itemID) or (C_Item.IsCosmeticItem and C_Item.IsCosmeticItem(itemID)) then
                return
            end
            if bagID and slotID and S.IsBagSlotProtected(bagID, slotID) then
                return
            end
        end

        if type(spellID) == "number" and not IsPlayerSpell(spellID) and not (S.IsComprehendSpell and S.IsComprehendSpell(spellID)) then
            return
        end

        if numItemsRequired then
            local stackCount
            if location and C_Item and C_Item.GetStackCount then
                local ok, count = pcall(C_Item.GetStackCount, location)
                if ok then
                    stackCount = count
                end
            end
            if not stackCount and bagID and slotID then
                stackCount = S.GetContainerItemStackCount and S.GetContainerItemStackCount(bagID, slotID)
            end
            if stackCount and stackCount < numItemsRequired then
                TooltipHelp(SPELL_FAILED_NEED_MORE_ITEMS:format(numItemsRequired, C_Item.GetItemNameByID(itemID)), ERR_COLOR)
                return
            end
        end

        return S.ApplySpell(item, spellID, color, bagID, slotID, owner)
    end

    spellID, color = S.IsOpenable(itemID)
    if spellID then
        return S.ApplySpell(item, spellID, color, bagID, slotID, owner)
    end

    local key
    key, color = S.IsOpenableProfession(itemID)
    if key then
        return S.ApplyItem(item, key, color, bagID, slotID, owner)
    end
end

function S.OnModifierChanged()
    if InCombatLockdown() then
        return
    end

    if Overlay:IsShown() then
        OverlayTooltipShow(Overlay)
        S.AnchorOverlayToOwner(Overlay)

        if S.ModifierReleased() then
            S.DeferMethod(Overlay, "Hide")
        end
    elseif GameTooltip:IsShown() then
        if GameTooltip:IsForbidden() or GameTooltip:IsProtected() then
            return
        end

        local owner = GameTooltip:GetOwner()
        if not owner then
            return
        end

        local mouseOver = true
        if owner.IsMouseOver then
            local ok, hovered = pcall(owner.IsMouseOver, owner)
            if ok then
                mouseOver = hovered and true or false
            end
        end
        if not mouseOver then
            return
        end

        local bag, slotIndex = S.ResolveBagSlotFromOwner(owner)
        if bag and slotIndex then
            local bagItem = S.ResolveBagItem(bag, slotIndex)
            S.HandleTooltip(GameTooltip, bagItem, bag, slotIndex, owner)
            return
        end

        local _, itemLink = GameTooltip:GetItem()
        if itemLink then
            S.HandleTooltip(GameTooltip, Item:CreateFromItemLink(itemLink), nil, nil, owner)
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
if FluxSafeRegisterEvent then
    FluxSafeRegisterEvent(eventFrame, "EDIT_MODE_LAYOUTS_UPDATED")
else
    pcall(eventFrame.RegisterEvent, eventFrame, "EDIT_MODE_LAYOUTS_UPDATED")
end
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "BAG_UPDATE_DELAYED" then
        S.HideOverlay()
    elseif event == "MODIFIER_STATE_CHANGED" or event == "EDIT_MODE_LAYOUTS_UPDATED" then
        if Overlay:IsShown() then
            S.AnchorOverlayToOwner(Overlay)
        end
        if event == "MODIFIER_STATE_CHANGED" then
            S.OnModifierChanged()
        end
    end
end)

S.RegisterModifierCallback(function()
    S.UpdateAttributeDriver()
end)

S.UpdateAttributeDriver()
