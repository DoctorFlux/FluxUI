-- Average item level row under the wrist slot (+ optional GearScore row). Respects Flux CSC settings toggle.
local _, ns = ...
local module = ns.CharacterStats
if not (module and module.useClassicPaperDollChrome) then return end

local InfoFrame = rawget(_G, "FluxInfoFrame")

local ilvlLabelText = _G.CSC_ILVL_LABEL or "Item LvL"
local gsLabelText = _G.CSC_GS_LABEL or "GearScore"

local function IsPaperDollItemLevelEnabled()
    local g = rawget(_G, "UISettingsGlobal")
    if type(g) == "table" and g.showPaperDollItemLevel == false then
        return false
    end
    return true
end

local function GetGearScoreAndItemLevel()
    local gsFn = _G.FluxCSC_GetPlayerGearScore
    local gs = type(gsFn) == "function" and gsFn() or nil
    local ilvl = _G.FluxCSC_GetPlayerItemLevel and _G.FluxCSC_GetPlayerItemLevel() or nil
    return gs, ilvl
end

local function ShowCrossTooltip(owner, primaryLabel, primaryValueText, secondaryLabel, secondaryValueText)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:SetText("Equipment")
    GameTooltip:AddDoubleLine(primaryLabel, primaryValueText or "--", 1, 0.82, 0.2, 1, 1, 1)
    GameTooltip:AddDoubleLine(secondaryLabel, secondaryValueText or "--", 1, 0.82, 0.2, 1, 1, 1)
    GameTooltip:Show()
end

--- @return number|nil equipped average item level
function _G.FluxCSC_GetPlayerItemLevel()
    if type(GetAverageItemLevel) == "function" then
        local ok, a, equipped = pcall(GetAverageItemLevel)
        if ok then
            if type(equipped) == "number" and equipped > 0 then
                return equipped
            end
            if type(a) == "number" and a > 0 then
                return a
            end
        end
    end

    local first = INVSLOT_FIRST_EQUIPPED or 1
    local last = INVSLOT_LAST_EQUIPPED or 19
    local total, count = 0, 0

    for slot = first, last do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local ilvl
            if C_Item and C_Item.GetDetailedItemLevelInfo then
                local ok, v = pcall(C_Item.GetDetailedItemLevelInfo, link)
                if ok and type(v) == "number" and v > 0 then ilvl = v end
            end
            if not ilvl and type(GetDetailedItemLevelInfo) == "function" then
                local ok, v = pcall(GetDetailedItemLevelInfo, link)
                if ok and type(v) == "number" and v > 0 then ilvl = v end
            end
            if not ilvl then
                local ok, itemLevel = pcall(function()
                    return select(4, GetItemInfo(link))
                end)
                if ok and type(itemLevel) == "number" and itemLevel > 0 then
                    ilvl = itemLevel
                end
            end
            if ilvl and ilvl > 0 then
                total = total + ilvl
                count = count + 1
            end
        end
    end

    if count > 0 then
        return total / count
    end
    return nil
end

local function ApplyItemLevelLabel(row)
    if not row or not row.Label then return end
    local fmt = _G.STAT_FORMAT
    if type(fmt) ~= "string" then fmt = "%s" end
    local labelStr = string.format(fmt, ilvlLabelText)
    if not labelStr:find(":$") then
        labelStr = labelStr .. ":"
    end
    row.Label:SetText(labelStr)
end

local function UpdateItemLevelRow(row)
    if not row or not row.Value then return end
    ApplyItemLevelLabel(row)
    -- Value sits to the right of the pin check (same as other CSC stat rows).
    row.Value:ClearAllPoints()
    if row._fluxPinIndicatorTex then
        row.Value:SetPoint("LEFT", row._fluxPinIndicatorTex, "RIGHT", 3, 0)
    else
        row.Value:SetPoint("LEFT", row.Label, "RIGHT", 2, 0)
    end
    row.Value:SetJustifyH("LEFT")
    local ilvl = _G.FluxCSC_GetPlayerItemLevel()
    local gsFn = _G.FluxCSC_GetPlayerGearScore
    local gsTotal = type(gsFn) == "function" and gsFn() or nil
    local qc = _G.FluxCSC_GetGearScoreQualityRGB
    if ilvl then
        row.Value:SetFormattedText("%.1f", ilvl)
        if type(qc) == "function" then
            local r, g, b = qc(gsTotal or 0)
            row.Value:SetTextColor(r, g, b, 1)
        else
            row.Value:SetTextColor(1, 1, 1, 1)
        end
    else
        row.Value:SetText("--")
        row.Value:SetTextColor(0.53, 0.53, 0.53, 1)
    end
end

local function ApplyGearScoreLabel(row)
    if not row or not row.Label then return end
    local fmt = _G.STAT_FORMAT
    if type(fmt) ~= "string" then fmt = "%s" end
    local labelStr = string.format(fmt, gsLabelText)
    if not labelStr:find(":$") then
        labelStr = labelStr .. ":"
    end
    row.Label:SetText(labelStr)
end

local function UpdateGearScoreRow(row)
    if not row or not row.Value then return end
    ApplyGearScoreLabel(row)
    row.Value:ClearAllPoints()
    if row._fluxPinIndicatorTex then
        row.Value:SetPoint("LEFT", row._fluxPinIndicatorTex, "RIGHT", 3, 0)
    else
        row.Value:SetPoint("LEFT", row.Label, "RIGHT", 2, 0)
    end
    row.Value:SetJustifyH("LEFT")
    local gs = _G.FluxCSC_GetPlayerGearScore
    local v = type(gs) == "function" and gs() or nil
    local qc = _G.FluxCSC_GetGearScoreQualityRGB
    if v then
        row.Value:SetFormattedText("%d", math.floor(v + 0.5))
        if type(qc) == "function" then
            local r, g, b = qc(v)
            row.Value:SetTextColor(r, g, b, 1)
        else
            row.Value:SetTextColor(1, 1, 1, 1)
        end
    else
        row.Value:SetText("--")
        row.Value:SetTextColor(0.53, 0.53, 0.53, 1)
    end
end

local function AttachItemLevelTooltip(row)
    if not row then return end
    row:SetScript("OnEnter", function(self)
        local gs, ilvl = GetGearScoreAndItemLevel()
        local ilvlText = ilvl and string.format("%.1f", ilvl) or "--"
        local gsText = gs and string.format("%d", math.floor(gs + 0.5)) or "--"
        ShowCrossTooltip(self, ilvlLabelText, ilvlText, gsLabelText, gsText)
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function AttachGearScoreTooltip(row)
    if not row then return end
    row:SetScript("OnEnter", function(self)
        local gs, ilvl = GetGearScoreAndItemLevel()
        local gsText = gs and string.format("%d", math.floor(gs + 0.5)) or "--"
        local ilvlText = ilvl and string.format("%.1f", ilvl) or "--"
        ShowCrossTooltip(self, gsLabelText, gsText, ilvlLabelText, ilvlText)
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function EnsureGearScoreRow()
    local wrist = _G.CharacterWristSlot
    if not wrist then return end
    local parent = wrist:GetParent()
    if not parent then return end

    local ilvlRow = _G.FluxCSC_ItemLevelStatRow
    local anchorFrame = wrist
    local ox, oy = 0, -2
    if IsPaperDollItemLevelEnabled() and ilvlRow and ilvlRow:IsShown() then
        anchorFrame = ilvlRow
        ox, oy = 0, 0
    end

    local f = _G.FluxCSC_GearScoreStatRow
    local w = wrist:GetWidth()
    if not w or w < 80 then w = 100 end
    if not f then
        f = CreateFrame("Frame", "FluxCSC_GearScoreStatRow", parent)
        f:SetSize(w, 16)
        f.Label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f.Value = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.Label:SetPoint("LEFT", f, "LEFT", 0, 0)
        f.Label:SetJustifyH("LEFT")
        f.Value:SetJustifyH("LEFT")
        ApplyGearScoreLabel(f)
        f:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", ox, oy)
        f:EnableMouse(true)
        AttachGearScoreTooltip(f)
        _G.FluxCSC_GearScoreStatRow = f
    else
        f:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", ox, oy)
        AttachGearScoreTooltip(f)
    end

    if InfoFrame and InfoFrame.HookClassicCSCStatFrame then
        InfoFrame.HookClassicCSCStatFrame(f)
    end
    UpdateGearScoreRow(f)
end

local function EnsureItemLevelRow()
    local wrist = _G.CharacterWristSlot
    if not wrist or not wrist.GetParent then return end
    local parent = wrist:GetParent()
    if not parent then return end

    if not IsPaperDollItemLevelEnabled() then
        if _G.FluxCSC_ItemLevelStatRow then
            _G.FluxCSC_ItemLevelStatRow:Hide()
        end
        EnsureGearScoreRow()
        return
    end

    local f = _G.FluxCSC_ItemLevelStatRow
    if not f then
        f = CreateFrame("Frame", "FluxCSC_ItemLevelStatRow", parent)
        local w = wrist:GetWidth()
        if not w or w < 80 then w = 100 end
        f:SetSize(w, 16)
        f.Label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f.Value = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.Label:SetPoint("LEFT", f, "LEFT", 0, 0)
        f.Label:SetJustifyH("LEFT")
        f.Value:SetJustifyH("LEFT")
        ApplyItemLevelLabel(f)
        f:SetPoint("TOPLEFT", wrist, "BOTTOMLEFT", 0, -2)
        f:EnableMouse(true)
        AttachItemLevelTooltip(f)
        _G.FluxCSC_ItemLevelStatRow = f
    end
    f:SetPoint("TOPLEFT", wrist, "BOTTOMLEFT", 0, -2)
    f:Show()
    AttachItemLevelTooltip(f)

    -- Pin texture must exist before Value is anchored to its RIGHT.
    if InfoFrame and InfoFrame.HookClassicCSCStatFrame then
        InfoFrame.HookClassicCSCStatFrame(f)
    end
    UpdateItemLevelRow(f)
    EnsureGearScoreRow()
end

function _G.FluxCSC_ApplyPaperDollItemLevelSetting()
    EnsureItemLevelRow()
end

local hooksInstalled = false

local function InstallPaperDollHooks()
    if hooksInstalled then return end
    hooksInstalled = true
    if _G.PaperDollFrame and _G.PaperDollFrame.HookScript then
        _G.PaperDollFrame:HookScript("OnShow", function()
            C_Timer.After(0, EnsureItemLevelRow)
        end)
    end
    if _G.CharacterFrame and _G.CharacterFrame.HookScript then
        _G.CharacterFrame:HookScript("OnShow", function()
            C_Timer.After(0.05, EnsureItemLevelRow)
        end)
    end
    C_Timer.After(0.1, EnsureItemLevelRow)
end

function module.InstallItemLevel()
    if not module.useClassicPaperDollChrome then
        return false
    end
    InstallPaperDollHooks()
    return hooksInstalled
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
ev:RegisterEvent("GET_ITEM_INFO_RECEIVED")
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and module.IsCharacterUiAddon and module.IsCharacterUiAddon(arg1) then
        InstallPaperDollHooks()
        return
    end
    if event == "PLAYER_LOGIN" then
        InstallPaperDollHooks()
        return
    end
    if event == "PLAYER_EQUIPMENT_CHANGED" then
        if _G.FluxCSC_ItemLevelStatRow then
            UpdateItemLevelRow(_G.FluxCSC_ItemLevelStatRow)
        end
        if _G.FluxCSC_GearScoreStatRow then
            UpdateGearScoreRow(_G.FluxCSC_GearScoreStatRow)
        end
        return
    end
    if event == "GET_ITEM_INFO_RECEIVED" then
        if _G.FluxCSC_ItemLevelStatRow then
            UpdateItemLevelRow(_G.FluxCSC_ItemLevelStatRow)
        end
        if _G.FluxCSC_GearScoreStatRow then
            UpdateGearScoreRow(_G.FluxCSC_GearScoreStatRow)
        end
    end
end)


