local addonName, ns = ...

-- Raid frame orchestrator. Layout lives in FluxRaidLayout; paint lives in FluxRaidUnit.

local State = FluxRaidState

function FluxRaid_GetCVarBool(name, defaultIfMissing)
    if not C_CVar or not C_CVar.GetCVar then
        return defaultIfMissing and true or false
    end
    local v = C_CVar.GetCVar(name)
    if v == nil or v == "" then
        return defaultIfMissing and true or false
    end
    return v == "1" or v == 1 or v == true
end

function FluxRaid_ShouldClassColorNames()
    if not FluxOptions or not FluxOptions.GetRaidFrameDB then
        return false
    end
    local db = FluxOptions:GetRaidFrameDB()
    return db and db.nameUseClassColor and true or false
end

function FluxRaid_DisplayMainTankAndAssistCVarEnabled()
    return FluxRaid_GetCVarBool("raidOptionDisplayMainTankAndAssist", true)
end

function FluxRaid_IsDispelHighlightEnabled()
    if not FluxOptions or not FluxOptions.GetRaidFrameDB then
        return true
    end
    local db = FluxOptions:GetRaidFrameDB()
    if not db or db.showDispelHighlight == nil then
        return true
    end
    return db.showDispelHighlight and true or false
end

function FluxRaid_IsFluxRaidEnabled()
    if not FluxOptions or not FluxOptions.GetRaidFrameDB then
        return true
    end
    local db = FluxOptions:GetRaidFrameDB()
    if db and db.useFluxRaidFrames == false then
        return false
    end
    return true
end

function FluxRaid_ApplyRangePollInterval(_seconds)
end

function FluxRaid_GetRangePollStats()
    return 0, 0
end

function FluxRaid_GetMTMAPollStats()
    return 0, 0
end

local CVAR_REFRESH = {
    raidFramesDisplayPowerBars = true,
    raidFramesDisplayClassColor = true,
    raidFramesHealthText = true,
    raidFramesDisplayIncomingHeals = true,
    raidFramesFadeOutOfRange = true,
    raidFramesDisplayInOtherPhase = true,
    raidFramesDisplayDebuffs = true,
    raidFramesDisplayBuffs = true,
    raidFramesDisplayOnlyDispellableDebuffs = true,
}

function FluxRaid_ApplyOptionsFromDB()
    if InCombatLockdown() then
        if FluxRaid_QueueWork then FluxRaid_QueueWork(FluxRaid_ApplyOptionsFromDB) end
        return
    end
    if not State.isInitialized then return end
    local db = {}
    if FluxOptions and FluxOptions.GetRaidFrameDB then
        local d = FluxOptions:GetRaidFrameDB()
        if type(d) == "table" then db = d end
    end
    FluxRaidVisuals.ApplyRaidFrameTunables(db)
    if FluxRaid_EnsureRangePoll then
        FluxRaid_EnsureRangePoll()
    end
    if not FluxRaid_IsFluxRaidEnabled() then
        if State.containerFrame then State.containerFrame:Hide() end
        if FluxRaid_RestoreBlizzardRaidFrames then
            FluxRaid_RestoreBlizzardRaidFrames()
        end
        if FluxRaidPreview and FluxRaidPreview.RefreshFromOptions then
            FluxRaidPreview.RefreshFromOptions()
        end
        return
    end
    if FluxRaid_InstallManagerHooks then
        FluxRaid_InstallManagerHooks()
    end
    if State.isInitialized and FluxRaid_ApplyChromeToChildren then
        FluxRaid_ApplyChromeToChildren(true)
        if FluxRaid_SyncAllFluxUnitAuraSettings then
            FluxRaid_SyncAllFluxUnitAuraSettings()
        end
        if not InCombatLockdown() then
            for i = 1, (FluxRaidCompat.GROUP_COUNT or 8) do
                local h = State.raidHeaders[i]
                if h then
                    pcall(function() h:SetAttribute("minWidth", FluxRaidVisuals.FRAME_WIDTH) end)
                end
            end
            if State.mtmaHeader then
                pcall(function() State.mtmaHeader:SetAttribute("minWidth", FluxRaidVisuals.FRAME_WIDTH) end)
            end
        end
    end
    if FluxRaid_QueueConfigureAndRefresh then
        FluxRaid_QueueConfigureAndRefresh()
    end
    -- The first configuration creates the secure child buttons. Only then
    -- may the native party/raid controls be handed over to Flux.
    if State.secureConfigured then
        if FluxRaid_DisableBlizzardNow then FluxRaid_DisableBlizzardNow() end
        if FluxRaid_ScheduleBlizzardGridHideCheck then FluxRaid_ScheduleBlizzardGridHideCheck() end
    end
    if FluxRaidPreview and FluxRaidPreview.RefreshFromOptions then
        FluxRaidPreview.RefreshFromOptions()
    end
end

local function RefreshFromCVar(cvarName)
    if type(cvarName) == "string" and string.lower(cvarName) == "unitsurnameown" then
        if FluxRaid_RefreshSelfDisplayNames then
            FluxRaid_RefreshSelfDisplayNames()
        end
        return
    end
    if cvarName == "raidOptionDisplayMainTankAndAssist" then
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if not InCombatLockdown or not InCombatLockdown() then
                    if FluxRaid_QueueConfigureAndRefresh then
                        FluxRaid_QueueConfigureAndRefresh()
                    end
                end
            end)
        elseif FluxRaid_QueueConfigureAndRefresh then
            FluxRaid_QueueConfigureAndRefresh()
        end
        return
    end
    if not CVAR_REFRESH[cvarName] or not State.isInitialized or not FluxRaid_IsFluxRaidEnabled() then
        return
    end
    local function apply()
        if not State.isInitialized or not FluxRaid_IsFluxRaidEnabled() then return end
        if InCombatLockdown and InCombatLockdown() then return end
        if FluxRaid_ApplyChromeToChildren then
            FluxRaid_ApplyChromeToChildren(true)
        end
        if FluxRaid_SyncAllFluxUnitAuraSettings then
            FluxRaid_SyncAllFluxUnitAuraSettings()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, apply)
    else
        apply()
    end
end

local EventHandlers = {}

function EventHandlers:GROUP_ROSTER_UPDATE()
    if FluxRaid_OnRosterOrPartyChanged then
        FluxRaid_OnRosterOrPartyChanged()
    end
end

function EventHandlers:PARTY_MEMBERS_CHANGED()
    if FluxRaid_OnRosterOrPartyChanged then
        FluxRaid_OnRosterOrPartyChanged()
    end
end

function EventHandlers:CVAR_UPDATE(cvarName)
    RefreshFromCVar(cvarName)
end

function EventHandlers:PLAYER_ENTERING_WORLD()
    if not State.isInitialized and ns.Flux and ns.Flux.Module then
        ns.Flux.Module.Enable("RaidFrames")
    end
    FluxRaid_ApplyOptionsFromDB()
end

function EventHandlers:PLAYER_REGEN_ENABLED()
    if FluxRaid_RunPendingCombatWork then
        FluxRaid_RunPendingCombatWork()
    end
end

function EventHandlers:COMPACT_UNIT_FRAME_PROFILES_LOADED()
    if FluxRaid_DisableBlizzardNow then
        FluxRaid_DisableBlizzardNow()
    end
end

function EventHandlers:DISPLAY_SIZE_CHANGED()
    if FluxRaid_PositionContainer then
        FluxRaid_PositionContainer()
    end
end

function EventHandlers:UI_SCALE_CHANGED()
    if FluxRaid_PositionContainer then
        FluxRaid_PositionContainer()
    end
end

function EventHandlers:PLAYER_TARGET_CHANGED()
    if FluxRaid_RefreshVisibleUnits then
        FluxRaid_RefreshVisibleUnits("target")
    end
end

function EventHandlers:PLAYER_ROLES_ASSIGNED()
    if FluxRaid_RefreshVisibleUnits then
        FluxRaid_RefreshVisibleUnits("role")
    end
end

function EventHandlers:READY_CHECK()
    if FluxRaid_RefreshVisibleUnits then
        FluxRaid_RefreshVisibleUnits("ready")
    end
end

function EventHandlers:READY_CHECK_CONFIRM()
    if FluxRaid_RefreshVisibleUnits then
        FluxRaid_RefreshVisibleUnits("ready")
    end
end

function EventHandlers:READY_CHECK_FINISHED()
    if FluxRaid_RefreshVisibleUnits then
        FluxRaid_RefreshVisibleUnits("ready")
    end
end

function EventHandlers:RAID_TARGET_UPDATE()
    if FluxRaid_RefreshVisibleUnits then
        FluxRaid_RefreshVisibleUnits("raidtarget")
    end
end

function FluxRaid_OnLoad(self)
    State.eventFrame = self
    local events = {
        "PLAYER_ENTERING_WORLD",
        "GROUP_ROSTER_UPDATE",
        "PARTY_MEMBERS_CHANGED",
        "CVAR_UPDATE",
        "PLAYER_REGEN_ENABLED",
        "COMPACT_UNIT_FRAME_PROFILES_LOADED",
        "DISPLAY_SIZE_CHANGED",
        "UI_SCALE_CHANGED",
        "PLAYER_TARGET_CHANGED",
        "PLAYER_ROLES_ASSIGNED",
        "READY_CHECK",
        "READY_CHECK_CONFIRM",
        "READY_CHECK_FINISHED",
        "RAID_TARGET_UPDATE",
    }
    for _, event in ipairs(events) do
        pcall(self.RegisterEvent, self, event)
    end
    local function Initialize()
        if State.isInitialized then return true end
        if InCombatLockdown() then return false end
        if FluxRaid_InitLayoutFrames then FluxRaid_InitLayoutFrames() end
        if FluxRaid_InstallPetBattleDriver and FluxRaid_InstallPetBattleDriver() == false then return false end
        State.isInitialized = true
        local ok, err = pcall(FluxRaid_ApplyOptionsFromDB)
        if not ok then
            State.isInitialized = false
            error(err)
        end
        if ns.Flux and ns.Flux.Startup then ns.Flux.Startup.Mark("raid_secure_infrastructure_ready") end
        return true
    end
    if ns.Flux and ns.Flux.Module then
        ns.Flux.Module.Register("RaidFrames", {
            phase = "secure", priority = 70, protected = true, OnEnable = Initialize,
        })
    else
        Initialize()
    end
end

function FluxRaid_OnEvent(self, event, unit, ...)
    local handler = EventHandlers[event]
    if handler then
        handler(self, unit, ...)
    end
end

_G.FluxRaid_IsFluxRaidEnabled = FluxRaid_IsFluxRaidEnabled
_G.FluxRaid_ApplyOptionsFromDB = FluxRaid_ApplyOptionsFromDB
_G.FluxRaid_GetCVarBool = FluxRaid_GetCVarBool
_G.FluxRaid_ShouldClassColorNames = FluxRaid_ShouldClassColorNames
_G.FluxRaid_GetRangePollStats = FluxRaid_GetRangePollStats
_G.FluxRaid_GetMTMAPollStats = FluxRaid_GetMTMAPollStats
_G.FluxRaid_UpdateAll = FluxRaid_PaintUnit or _G.FluxRaid_UpdateAll
