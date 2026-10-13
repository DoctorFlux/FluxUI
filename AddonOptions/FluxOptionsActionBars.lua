-- FluxOptionsActionBars.lua — Action Bars tab shell (Bar / Bindings / Extra / Stance).
-- FluxOptions:OpenToActionBarsTab() has always pointed at the "actionbars" group.
local addonName, ns = ...
local Flux = ns.Flux

ns.FluxOptionsActionBars = ns.FluxOptionsActionBars or {}
local AB = ns.FluxOptionsActionBars

function AB.ActionbarsDB()
	if FluxOptions and FluxOptions.GetActionbarsDB then
		return FluxOptions:GetActionbarsDB()
	end
	return nil
end

function AB.Notify()
	local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
	if ACR then
		ACR:NotifyChange("FluxUI")
	end
end

function AB.RankSupported()
	return FluxSpellRankManagerModule
		and FluxSpellRankManagerModule.IsRankFeaturesSupported
		and FluxSpellRankManagerModule:IsRankFeaturesSupported()
end

function AB.IsPreDF()
	if Flux and Flux.Client and Flux.Client.isPreDF then
		return true
	end
	if _G.FLUX_API and _G.FLUX_API.isPreDF then
		return true
	end
	return false
end

function AB.MouseoverCast()
	return (Flux and Flux.MouseoverCast) or _G.FluxMouseoverCast
end

local function BuildActionBarsOptions()
	local args = {}
	if AB.GetBarGroup then
		args.bar = AB.GetBarGroup()
	end
	if AB.GetBindingsGroup then
		args.bindings = AB.GetBindingsGroup()
	end
	if AB.GetExtraGroup then
		args.extra = AB.GetExtraGroup()
	end
	if AB.GetStanceGroup then
		args.stance = AB.GetStanceGroup()
	end
	return {
		name = "Action Bars",
		type = "group",
		order = 20,
		childGroups = "tab",
		args = args,
	}
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
	if loadedAddon ~= addonName then
		return
	end
	self:UnregisterEvent("ADDON_LOADED")
	if FluxOptions and FluxOptions.RegisterModuleOptions then
		FluxOptions:RegisterModuleOptions("actionbars", BuildActionBarsOptions)
	end
end)

