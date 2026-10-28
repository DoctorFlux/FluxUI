-- SpellBookChrome.lua — Mouseover Cast + rank-up placement on all four books.
-- Live / Forever: PlayerSpellsFrame.SpellBookFrame footer (PagedSpellsFrame).
-- Classic Era / Anniversary: SpellBookFrame title row, right of Blizzard ranks.
local addonName, ns = ...
local Flux = ns.Flux

local Chrome = {}
Flux.SpellBookChrome = Chrome

local FOOTER_X, FOOTER_Y = 20, 36
local CLASSIC_TITLE_X, CLASSIC_TITLE_Y = 74, -38
local ROW_GAP = 15

-- Modern book visibility/page changes can occur inside PlayerSpells OnShow,
-- before MultiActionBar_ShowAllGrids and protected spell casting. Observe from
-- one independent, throttled driver; never wrap the native book/filter methods.
local observers = {}
local observerFrame
function Chrome.Observe(owner, onShow, onHide, onUpdate)
	observers[owner] = { onShow=onShow, onHide=onHide, onUpdate=onUpdate }
	if observerFrame then return end
	observerFrame=CreateFrame("Frame")
	local elapsed=0
	observerFrame:SetScript("OnUpdate",function(_,dt)
		elapsed=elapsed+dt
		if elapsed<0.1 then return end
		elapsed=0
		local host=Chrome.GetHost()
		local shown=false
		if host then
			if host.IsVisible then shown=host:IsVisible()
			elseif host.IsShown then shown=host:IsShown() end
		end
		shown=shown and true or false
		local paged=shown and host.PagedSpellsFrame
		local provider=paged and paged.dataProvider
		local views=paged and paged.viewDataList
		local pages=paged and paged.PagingControls
		local page=pages and pages.currentPage
		if issecretvalue and issecretvalue(page) then page=nil end
		for _,observer in pairs(observers) do
			local changed=observer.shown~=shown or observer.host~=host
			local pageChanged=observer.provider~=provider or observer.views~=views or observer.page~=page
			observer.provider,observer.views,observer.page=provider,views,page
			observer.host=host
			if changed then
				local was=observer.shown
				observer.shown=shown
				if shown and observer.onShow then observer.onShow()
				elseif was and observer.onHide then observer.onHide() end
			elseif shown and pageChanged and observer.onUpdate then observer.onUpdate() end
		end
	end)
end

function Chrome.HasLowRankApi()
	return C_SpellBook and type(C_SpellBook.IsSpellBookItemLowRank) == "function"
end

function Chrome.HasBlizzardShowAllRanksDropdown()
	local mixin = _G.SpellBookFrameMixin
	return mixin and type(mixin.SetupAllRanksCheckbox) == "function"
end

function Chrome.GetBlizzardShowAllRanksCheckbox()
	local checkbox = _G.ShowAllSpellRanksCheckbox or _G.ShowAllSpellRanksCheckBox
	if checkbox and checkbox._fluxCreatedShowAllRanks then
		return nil
	end
	return checkbox
end

function Chrome.GetFluxShowAllRanksCheckbox()
	local checkbox = _G.ShowAllSpellRanksCheckbox or _G.ShowAllSpellRanksCheckBox or _G.FluxShowAllSpellRanksCheckbox
	if checkbox and checkbox._fluxCreatedShowAllRanks then
		return checkbox
	end
	return _G.FluxShowAllSpellRanksCheckbox
end

-- Forever PlayerSpells has Show All Ranks in SettingsDropdown, but the
-- localized string and CVar are not always present. Restore Blizzard's
-- own filter; do not hide SettingsDropdown.
function Chrome.EnsureBlizzardShowAllRanks()
	if not Chrome.RankChromeAllowed() then
		return
	end
	if SHOW_ALL_SPELL_RANKS == nil then
		SHOW_ALL_SPELL_RANKS = "Show All Spell Ranks"
	end
	if GetCVar and GetCVar("ShowAllSpellRanks") == nil and C_CVar and C_CVar.RegisterCVar then
		C_CVar.RegisterCVar("ShowAllSpellRanks", "1")
	end
	local host = Chrome.GetHost()
	if host and host.SettingsDropdown and Chrome.HasBlizzardShowAllRanksDropdown() then
		if host.SettingsDropdown.Show then
			host.SettingsDropdown:Show()
		end
	end
end

-- Forever PlayerSpells has no named XML checkbox (gear only). Classic already
-- has ShowAllSpellRanksCheckbox. Live must never get one.
function Chrome.ShouldCreateFluxShowAllRanks()
	if not Chrome.RankChromeAllowed() then
		return false
	end
	if Chrome.GetBlizzardShowAllRanksCheckbox() then
		return false
	end
	local _, kind = Chrome.GetHost()
	if kind == "playerSpells" then
		return true
	end
	return PlayerSpellsFrame ~= nil
end

-- Forever, Classic Era, Anniversary, Wrath. Live Midnight has no spell ranks
-- (wow-ui-source-live has no IsSpellBookItemLowRank). Do not trust a false
-- Camelot flag: live still lacks that API.
function Chrome.RankChromeAllowed()
	local C = Flux.Client
	if C then
		if C.isCata == true or C.isMists == true or C.isLiveMidnight == true then
			return false
		end
		if C.isEra == true or C.isAnniversary == true or C.isTBC == true or C.isWrath == true then
			return true
		end
	end
	return Chrome.HasLowRankApi() == true
end

function Chrome.GetHost()
	if PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame then
		return PlayerSpellsFrame.SpellBookFrame, "playerSpells"
	end
	if SpellBookFrame then
		return SpellBookFrame, "classic"
	end
	return nil, nil
end

local function Raise(frame, host)
	if not frame or not host then
		return
	end
	frame:SetParent(host)
	if frame.ClearAllPoints then
		frame:ClearAllPoints()
	end
	if frame.SetFrameStrata then
		frame:SetFrameStrata("DIALOG")
	end
	local level = host.GetFrameLevel and host:GetFrameLevel() or 0
	if frame.SetFrameLevel then
		frame:SetFrameLevel(level + 10)
	end
end

local function RightAnchor(widget)
	if not widget then
		return nil, nil
	end
	if widget.label then
		return widget.label, "RIGHT"
	end
	local name = widget.GetName and widget:GetName()
	if type(name) == "string" and name ~= "" then
		local text = _G[name .. "Text"]
		if text then
			return text, "RIGHT"
		end
	end
	return widget, "RIGHT"
end

function Chrome.HideRankChrome()
	local auto = _G.FluxAutoRankUpCheckbox
	local btn = _G.FluxRankUpAllButton
	local fluxRanks = Chrome.GetFluxShowAllRanksCheckbox()
	if auto and auto.Hide then
		auto:Hide()
	end
	if btn and btn.Hide then
		btn:Hide()
	end
	if fluxRanks and fluxRanks.Hide then
		fluxRanks:Hide()
	end
end

local function PlaceRow(host, firstPoint, firstRel, firstRelPoint, firstX, firstY, widgets)
	local shown = 0
	for i = 1, #widgets do
		local w = widgets[i]
		if w then
			Raise(w, host)
			if shown == 0 then
				w:SetPoint(firstPoint, firstRel, firstRelPoint, firstX, firstY)
			else
				local rel, point = RightAnchor(widgets[shown])
				w:SetPoint("LEFT", rel, point, ROW_GAP, 0)
			end
			if w.Show then
				w:Show()
			end
			shown = i
		end
	end
end

function Chrome.Layout(opts)
	opts = opts or {}
	local host, kind = Chrome.GetHost()
	local mouseover = opts.mouseover or _G.FluxMouseoverCastCheckbox
	local autoRank = opts.autoRank or _G.FluxAutoRankUpCheckbox
	local rankUp = opts.rankUp or _G.FluxRankUpAllButton
	local showAll = opts.showAll
	if showAll == nil then
		showAll = Chrome.GetFluxShowAllRanksCheckbox()
	end
	local showRank = opts.showRank
	if showRank == nil then
		showRank = Chrome.RankChromeAllowed()
	end

	if showRank then
		Chrome.EnsureBlizzardShowAllRanks()
	end

	if not host or not (host.IsShown and host:IsShown()) then
		if mouseover then
			mouseover:Hide()
		end
		Chrome.HideRankChrome()
		return
	end

	if not showRank then
		Chrome.HideRankChrome()
		autoRank = nil
		rankUp = nil
		showAll = nil
	end

	local row = {}
	if kind == "playerSpells" and showAll then
		row[#row + 1] = showAll
	end
	if mouseover then
		row[#row + 1] = mouseover
	end
	if autoRank then
		row[#row + 1] = autoRank
	end
	if rankUp then
		row[#row + 1] = rankUp
	end
	if #row == 0 then
		return
	end

	if kind == "playerSpells" then
		local paged = host.PagedSpellsFrame or host
		PlaceRow(host, "BOTTOMLEFT", paged, "BOTTOMLEFT", FOOTER_X, FOOTER_Y, row)
		return
	end

	local ranks = Chrome.GetBlizzardShowAllRanksCheckbox()
	local ranksVisible = ranks and ranks.IsVisible and ranks:IsVisible()
	if ranksVisible then
		local rel, point = RightAnchor(ranks)
		PlaceRow(host, "LEFT", rel, point, 12, 0, row)
	else
		PlaceRow(host, "TOPLEFT", host, "TOPLEFT", CLASSIC_TITLE_X, CLASSIC_TITLE_Y, row)
	end
end
