-- Catalog.lua — Blizzard (and Baganator) window names. Probe existence; do not assume.
-- HUD frames are not listed. Blacklist is a safety net.
local addonName, ns = ...
local Flux = ns.Flux

local WindowMover = Flux.WindowMover or {}
Flux.WindowMover = WindowMover

local ALL = { era = true, anniversary = true, classic = true, midnight = true }
local CLASSIC = { era = true, anniversary = true, classic = true }
local MIDNIGHT = { midnight = true }
local ERA_MIDNIGHT = { era = true, midnight = true }
local ERA_ANNIVERSARY = { era = true, anniversary = true }

local function E(name, extra)
	local t = {
		name = name,
		clients = ALL,
		drag = extra and extra.drag or "title",
	}
	if extra then
		for k, v in pairs(extra) do
			t[k] = v
		end
	end
	return t
end

local entries = {
	-- Shared windows
	E("CharacterFrame"),
	E("InspectFrame"),
	E("FriendsFrame"),
	E("TradeFrame"),
	E("GossipFrame"),
	E("MerchantFrame"),
	E("QuestFrame"),
	E("DressUpFrame"),
	E("MailFrame"),
	E("OpenMailFrame"),
	E("MacroFrame"),
	E("AddonList"),
	E("ChatConfigFrame"),
	-- GameMenuFrame and StaticPopup1-4 are deliberately absent; see BLACKLIST.
	E("ReadyCheckFrame", { drag = "frame" }),
	E("RolePollPopup", { drag = "frame" }),
	E("PVPReadyDialog", { drag = "frame" }),
	E("LFDRoleCheckPopup", { drag = "frame" }),
	E("LFGListInviteDialog", { drag = "frame", clients = MIDNIGHT }),
	E("InstanceAbandonPopup", { drag = "frame" }),
	E("ItemTextFrame"),
	E("TabardFrame"),
	E("ItemSocketingFrame"),
	E("CalendarFrame"),
	E("GuildBankFrame"),
	E("ChannelFrame"),
	E("HelpFrame"),
	E("LootFrame"),
	E("ItemRefTooltip", { drag = "frame" }),
	E("ModelPreviewFrame", { drag = "frame" }),
	E("SplashFrame", { drag = "frame" }),
	E("PVPParentFrame"),
	E("TradeSkillFrame"),
	E("QuestLogPopupDetailFrame"),
	E("QuestLogDetailFrame"),
	E("AchievementFrame"),
	E("PVEFrame"),
	E("EncounterJournal"),
	E("CollectionsJournal"),
	E("TimeManagerFrame"),
	E("BlackMarketFrame"),
	E("WorldMapFrame", { skipIfAddon = { "Leatrix_Maps" } }),

	-- Bags / bank (skipped when Baganator is loaded)
	E("BankFrame", {
		bag = true,
		dynamicSize = function()
			local Cap = Flux.Cap
			return Cap and Cap.UsesPlayerBagsInBank and Cap.UsesPlayerBagsInBank() or false
		end,
	}),
	E("ContainerFrameCombinedBags", { bag = true, clients = MIDNIGHT }),
	E("FluxCombinedBags", { bag = true, clients = ERA_ANNIVERSARY }),

	-- Classic-family replacements
	E("SpellBookFrame", { clients = CLASSIC }),
	E("PlayerTalentFrame", { clients = CLASSIC }),
	E("TalentFrame", { clients = CLASSIC }),
	E("AuctionFrame", { clients = CLASSIC }),
	E("TaxiFrame", { clients = CLASSIC }),
	E("QuestLogFrame", { clients = CLASSIC }),
	E("CraftFrame", { clients = CLASSIC }),
	E("ClassTrainerFrame", { clients = CLASSIC }),
	E("BattlefieldFrame", { clients = CLASSIC }),
	E("InterfaceOptionsFrame", { clients = CLASSIC }),
	E("VideoOptionsFrame", { clients = CLASSIC }),
	E("KeyBindingFrame", { clients = CLASSIC }),
	E("LFGParentFrame", { clients = CLASSIC }),
	E("PetStableFrame", { clients = CLASSIC }),
	E("WorldStateScoreFrame", { clients = CLASSIC }),
	E("WatchFrameAutoQuestPopUp1", { drag = "frame", clients = CLASSIC }),
	E("GuildControlUI", { clients = CLASSIC }),
	E("ReforgingFrame", { clients = CLASSIC }),
	E("ArchaeologyFrame", { clients = CLASSIC }),
	E("PVPFrame", { clients = ERA_MIDNIGHT }),

	-- Midnight / modern retail
	E("PlayerSpellsFrame", { clients = MIDNIGHT }),
	E("QuickKeybindFrame", { clients = MIDNIGHT }),
	E("AuctionHouseFrame", { clients = MIDNIGHT }),
	E("ProfessionsFrame", { clients = MIDNIGHT }),
	E("ProfessionsBookFrame", { clients = MIDNIGHT }),
	E("ProfessionsCustomerOrdersFrame", { clients = MIDNIGHT }),
	E("FlightMapFrame", { clients = MIDNIGHT }),
	E("CommunitiesFrame", { clients = MIDNIGHT }),
	E("ClassTalentFrame", { clients = MIDNIGHT }),
	E("WardrobeFrame", { clients = MIDNIGHT }),
	E("ClickBindingFrame", { clients = MIDNIGHT }),
	E("TransmogFrame", { clients = MIDNIGHT }),
	E("StableFrame", { clients = MIDNIGHT }),
	E("HeroTalentsSelectionDialog", { clients = MIDNIGHT }),
	E("CurrencyTransferMenu", { clients = MIDNIGHT }),
	E("CurrencyTransferLog", { clients = MIDNIGHT }),
	E("CooldownViewerSettings", { clients = MIDNIGHT }),
	E("WeeklyRewardsFrame", { clients = MIDNIGHT }),
	E("GroupLootHistoryFrame", { clients = MIDNIGHT }),
	E("ScrappingMachineFrame", { clients = MIDNIGHT }),
	E("InspectRecipeFrame", { clients = MIDNIGHT }),
	E("ChallengesKeystoneFrame", { clients = MIDNIGHT }),
	E("CovenantMissionFrame", { clients = MIDNIGHT }),
	E("OrderHallMissionFrame", { clients = MIDNIGHT }),
	E("PVPMatchScoreboard", { clients = MIDNIGHT }),
	E("AnimaDiversionFrame", { clients = MIDNIGHT }),
	E("CovenantSanctumFrame", { clients = MIDNIGHT }),
	E("SoulbindViewer", { clients = MIDNIGHT }),
	E("GarrisonLandingPage", { clients = MIDNIGHT }),
	E("PlayerChoiceFrame", { drag = "frame", clients = MIDNIGHT }),
	E("ExpansionLandingPage", { clients = MIDNIGHT }),
	E("MajorFactionRenownFrame", { clients = MIDNIGHT }),
	E("GenericTraitFrame", { clients = MIDNIGHT }),
	E("ItemUpgradeFrame", { clients = MIDNIGHT }),
	E("CovenantRenownFrame", { clients = MIDNIGHT }),
	E("ItemInteractionFrame", { clients = MIDNIGHT }),
	E("GarrisonCapacitiveDisplayFrame", { clients = MIDNIGHT }),
	E("DelvesCompanionConfigurationFrame", { clients = MIDNIGHT }),
	E("DelvesDifficultyPickerFrame", { clients = MIDNIGHT }),
	E("RemixArtifactFrame", { clients = MIDNIGHT }),
	E("HousingDashboardFrame", { clients = MIDNIGHT }),
	E("HouseFinderFrame", { clients = MIDNIGHT }),
	E("HouseListFrame", { clients = MIDNIGHT }),
	E("HousingHouseSettingsFrame", { clients = MIDNIGHT }),
	E("HousingModelPreviewFrame", { clients = MIDNIGHT }),
	E("HousingInviteResidentFrame", { clients = MIDNIGHT }),
	E("HousingCornerstoneHouseInfoFrame", { clients = MIDNIGHT }),
	E("HousingCornerstonePurchaseFrame", { clients = MIDNIGHT }),
	E("HousingCornerstoneVisitorFrame", { clients = MIDNIGHT }),
	E("HousingBulletinBoardFrame", { clients = MIDNIGHT }),
	E("HouseEditorFrame.StoragePanel", {
		clients = MIDNIGHT,
		setup = function(frame)
			if frame.InputBlocker and frame.InputBlocker.Hide then
				pcall(frame.InputBlocker.Hide, frame.InputBlocker)
			end
		end,
	}),

	-- Baganator (only when that addon is loaded; Blizzard bag rows are skipped)
	E("Baganator_SingleViewBackpackViewFrame", { requireAddon = "Baganator" }),
	E("Baganator_CategoryViewBackpackViewFrame", { requireAddon = "Baganator" }),
	E("Baganator_SingleViewBankViewFrame", { requireAddon = "Baganator" }),
	E("Baganator_CategoryViewBankViewFrame", { requireAddon = "Baganator" }),
}

for i = 1, 13 do
	entries[#entries + 1] = E("ContainerFrame" .. i, { bag = true })
end

local BLACKLIST = {
	FluxMainActionBar = true,
	FluxWindowFrame = true,
	FluxMicroMenu = true,
	FluxMicroMenuFrame = true,
	FluxStatusBar = true,
	FluxInfoFrame = true,
	FluxVendorRestockPanelFrame = true,
	FluxUnifiedBorder = true,
	FluxNonCombatGrid = true,
	-- ESC path. Attaching replaces GameMenuFrame.SetPoint with an addon closure, so
	-- any secure caller stays tainted for the rest of GameMenuFrameMixin:OnShow --
	-- which on Forever reaches the protected SetPreferredGamepadInteractTarget().
	GameMenuFrame = true,
	-- Trigger bars call button:SetScale during the secure click. Never attach.
	GamepadMainActionBarFrame = true,
	-- Nameplate options preview lays out auras inside this panel; addon anchors or
	-- scripts here leave that layout tainted.
	SettingsPanel = true,
	StaticPopup1 = true,
	StaticPopup2 = true,
	StaticPopup3 = true,
	StaticPopup4 = true,
	PlayerFrame = true,
	TargetFrame = true,
	FocusFrame = true,
	PetFrame = true,
	Minimap = true,
	MinimapCluster = true,
	ExtraAbilityContainer = true,
	ZoneAbilityFrame = true,
	MainActionBar = true,
	MainMenuBar = true,
	MultiBarBottomLeft = true,
	MultiBarBottomRight = true,
	MultiBarLeft = true,
	MultiBarRight = true,
	MultiBar5 = true,
	MultiBar6 = true,
	MultiBar7 = true,
	StanceBar = true,
	PetActionBar = true,
	PossessActionBar = true,
	OverrideActionBar = true,
	-- Moving these taints them; combat UNIT_AURA then blocks DebuffFrame:SetSize.
	BuffFrame = true,
	DebuffFrame = true,
	ObjectiveTrackerFrame = true,
	CompactRaidFrameContainer = true,
	CompactRaidFrameManager = true,
	PartyFrame = true,
	PlayerCastingBarFrame = true,
	CastingBarFrame = true,
	GameTooltip = true,
	UIWidgetTopCenterContainerFrame = true,
	UIWidgetBelowMinimapContainerFrame = true,
	EncounterBar = true,
	StatusTrackingBarManager = true,
	DurabilityFrame = true,
	MicroMenuContainer = true,
	BagsBar = true,
	MicroButtonAndBagsBar = true,
	GroupLootContainer = true,
	PersonalResourceDisplayFrame = true,
	WeakAurasOptions = true,
	DragonflightUIProfessionFrame = true,
}

for i = 1, 10 do
	BLACKLIST["ChatFrame" .. i] = true
	BLACKLIST["GroupLootFrame" .. i] = true
end

local function AddonLoaded(name)
	if Flux.AddOn and Flux.AddOn.IsLoaded then
		return Flux.AddOn.IsLoaded(name)
	end
	local fn = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
	if not fn then
		return false
	end
	local ok, loaded = pcall(fn, name)
	return ok and loaded and true or false
end

function WindowMover.IsBlacklisted(name)
	if not name then
		return true
	end
	-- The Flux prefix skips HUD frames. This bag window is a real panel.
	if name == "FluxCombinedBags" then
		return false
	end
	if BLACKLIST[name] then
		return true
	end
	if type(name) == "string" and name:find("^Flux", 1, true) then
		return true
	end
	return false
end

function WindowMover.ShouldSkip(entry)
	if not entry or not entry.name then
		return true
	end
	if WindowMover.IsBlacklisted(entry.name) then
		return true
	end
	local clients = entry.clients
	if clients and Flux.Client and Flux.Client.Matches and not Flux.Client.Matches(clients) then
		return true
	end
	if entry.skipIfAddon then
		for i = 1, #entry.skipIfAddon do
			if AddonLoaded(entry.skipIfAddon[i]) then
				return true
			end
		end
	end
	if entry.requireAddon and not AddonLoaded(entry.requireAddon) then
		return true
	end
	if entry.bag and AddonLoaded("Baganator") then
		return true
	end
	-- Forever gamepad close calls SetPoint from the secure HideUIPanel path.
	-- A layout hook on these frames is that execution. Keyboard mode still attaches.
	local cap = Flux.Cap
	if cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() then
		return true
	end
	return false
end

function WindowMover.Catalog()
	return entries
end
