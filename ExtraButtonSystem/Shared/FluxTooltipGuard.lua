--[[
    ExtraButtonSystem/Shared/FluxTooltipGuard.lua

    Keeps Extra Button consumable tooltips to Blizzard item text + FluxUI lines only.

    Retail: fill via C_TooltipInfo (no SetItemByID → other addons' TooltipDataProcessor
    PostCalls never run). Classic: Block AddLine while Blizzard fills, then Unblock for FluxUI.

    Usage:
        btn._fluxIsolatedTooltip = true
        local tip = FluxTooltipGuard.GetTipForButton(btn)
        FluxTooltipGuard.FillBlizzardItem(tip, itemId)
        -- FluxUI AddLine...
        tip:Show()
]]

FluxTooltipGuard = {}
local Guard = FluxTooltipGuard

local isolatedTip
local LINE_BLANK = (Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.Blank) or 1
local LINE_SELL = (Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.SellPrice) or 11

local function GuardDisabledOnClient()
	-- Retail/Midnight fill via TooltipDataProcessor AddLine; blocking would empty the tip.
	local Flux = _G.Flux
	local Client = Flux and Flux.Client
	if Client then
		return Client.isRetail or Client.isMidnight or (Client.majorVersion or 0) >= 10
	end
	return FLUX_API and FLUX_API.isPostDF
end

local state = {}
local noop = function() end

function Guard.Block(tip)
    if GuardDisabledOnClient() or not tip then
        return
    end
    if state[tip] then
        return
    end
    state[tip] = {
        AddLine = tip.AddLine,
        AddDoubleLine = tip.AddDoubleLine,
    }
    tip.AddLine = noop
    tip.AddDoubleLine = noop
end

function Guard.Unblock(tip)
    if not tip or not state[tip] then
        return
    end
    local s = state[tip]
    tip.AddLine = s.AddLine
    tip.AddDoubleLine = s.AddDoubleLine
    state[tip] = nil
end

Guard.Reset = Guard.Unblock

function Guard.BlockUntilHide(tip)
    if GuardDisabledOnClient() or not tip then
        return
    end
    Guard.Block(tip)
    if not tip._fluxGuardHooked then
        tip:HookScript("OnHide", function(self)
            Guard.Unblock(self)
        end)
        tip._fluxGuardHooked = true
    end
end

function Guard.GetIsolatedTooltip()
    if not isolatedTip then
        isolatedTip = CreateFrame("GameTooltip", "FluxExtraButtonConsumableTooltip", UIParent, "GameTooltipTemplate")
        isolatedTip:SetFrameStrata("TOOLTIP")
        isolatedTip:Hide()
    end
    return isolatedTip
end

function Guard.GetIsolatedTooltipIfExists()
    return isolatedTip
end

--- Tooltip frame for this button (isolated when flagged).
function Guard.GetTipForButton(btn)
    if btn and btn._fluxIsolatedTooltip then
        return Guard.GetIsolatedTooltip()
    end
    return GameTooltip
end

function Guard.HideForButton(btn)
    if isolatedTip then
        isolatedTip:Hide()
    end
    if GameTooltip then
        GameTooltip:Hide()
    end
    if btn then
        btn._fluxActiveTooltip = nil
    end
end

function Guard.IsOwnedByWidget(widget)
    if not widget then
        return false
    end
    if isolatedTip and isolatedTip.IsOwned and isolatedTip:IsOwned(widget) then
        return true
    end
    return GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(widget)
end

local function ColorRGB(c)
	if not c then
		return nil, nil, nil
	end
	return c.r, c.g, c.b
end

local function FillFromTooltipInfo(tip, data)
	if not tip or type(data) ~= "table" or type(data.lines) ~= "table" then
		return false
	end
	if TooltipUtil and TooltipUtil.SurfaceArgs then
		pcall(TooltipUtil.SurfaceArgs, data)
	end
	if tip.ClearLines then
		tip:ClearLines()
	end
	for i = 1, #data.lines do
		local line = data.lines[i]
		if line then
			if TooltipUtil and TooltipUtil.SurfaceArgs then
				pcall(TooltipUtil.SurfaceArgs, line)
			end
			local lineType = line.type
			local left = line.leftText
			local right = line.rightText
			if lineType == LINE_SELL and line.price and SetTooltipMoney then
				pcall(SetTooltipMoney, tip, line.price)
			elseif lineType == LINE_BLANK or ((not left or left == "") and (not right or right == "")) then
				tip:AddLine(" ")
			elseif right and right ~= "" then
				local lr, lg, lb = ColorRGB(line.leftColor)
				local rr, rg, rb = ColorRGB(line.rightColor)
				tip:AddDoubleLine(left or "", right, lr, lg, lb, rr, rg, rb)
			else
				local lr, lg, lb = ColorRGB(line.leftColor)
				tip:AddLine(left or "", lr, lg, lb, line.wrapText)
			end
		end
	end
	return true
end

--- Fill tip with Blizzard item lines only (no other-addon PostCall injection on retail).
function Guard.FillBlizzardItem(tip, itemId)
	itemId = tonumber(itemId)
	if not tip or not itemId then
		return false
	end

	if C_TooltipInfo and C_TooltipInfo.GetItemByID then
		local ok, data = pcall(C_TooltipInfo.GetItemByID, itemId)
		if ok and FillFromTooltipInfo(tip, data) then
			return true
		end
		-- Do not SetItemByID here: TooltipDataProcessor would let other addons inject.
		local name = GetItemInfo and GetItemInfo(itemId)
		if type(name) == "string" and name ~= "" then
			tip:SetText(name, 1, 1, 1)
			return true
		end
		return false
	end

	-- Classic: SetItemByID (Block silences AddLine hooks).
	if tip.SetItemByID then
		Guard.Block(tip)
		local ok = pcall(tip.SetItemByID, tip, itemId)
		Guard.Unblock(tip)
		if ok then
			return true
		end
	end

	local _, link = GetItemInfo(itemId)
	if link and tip.SetHyperlink then
		Guard.Block(tip)
		local ok = pcall(tip.SetHyperlink, tip, link)
		Guard.Unblock(tip)
		if ok then
			return true
		end
	end
	return false
end

--- Recuperate / conjure spell on an isolated consumable button.
function Guard.FillBlizzardSpell(tip, spellId)
	spellId = tonumber(spellId)
	if not tip or not spellId then
		return false
	end
	local getter = C_TooltipInfo and (C_TooltipInfo.GetSpellByID or C_TooltipInfo.GetSpellBySpellID)
	if getter then
		local ok, data = pcall(getter, spellId)
		if ok and FillFromTooltipInfo(tip, data) then
			return true
		end
		local name = GetSpellInfo and GetSpellInfo(spellId)
		if type(name) == "string" and name ~= "" then
			tip:SetText(name, 1, 1, 1)
			return true
		end
		return false
	end
	if tip.SetSpellByID then
		Guard.Block(tip)
		local ok = pcall(tip.SetSpellByID, tip, spellId)
		Guard.Unblock(tip)
		if ok then
			return true
		end
	end
	return false
end

if GuardDisabledOnClient() and GameTooltip then
    Guard.Unblock(GameTooltip)
end

_G.FluxTooltipGuard = Guard
return Guard
