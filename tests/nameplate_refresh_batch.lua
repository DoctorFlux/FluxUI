-- Replay the actual refresh dispatcher with the existing five-client quest fixture.
-- Counts prove lookup scope only; native timing/rendering/security are unmeasured.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local source = read("tests/nameplate_quest_progress.lua")
local marker = '    check(questie.db.profile.nameplateTargetFrameEnabled == true, "Questie target-frame marker remains independent")'
local at = assert(source:find(marker, 1, true)) + #marker
local probe = [=[
    do
        local errors = {}
        local first = assert(core:find("local function EachModule(method, ...)", 1, true))
        local last = assert(core:find('local driver = CreateFrame("Frame")', first, true))
        local refreshFirst = assert(core:find("function NP.RefreshUnit(unit)", last, true))
        local refreshLast = assert(core:find('driver:SetScript("OnUpdate"', refreshFirst, true))
        local eventsFirst = assert(core:find('local events = CreateFrame("Frame")', refreshLast, true))
        local eventsLast = assert(core:find('-- Options call these', eventsFirst, true))
        local frame = { RegisterEvent = function() end, SetScript = function(self, _, handler) self.OnEvent = handler end }
        env.geterrorhandler = function() return function(err) errors[#errors + 1] = err end end
        assert(load("local NP, modules, activeUnits, activePlates, CreateFrame = ...\n"
            .. core:sub(first, last - 1) .. core:sub(refreshFirst, refreshLast - 1) .. core:sub(eventsFirst,eventsLast-1),
            "@nameplate-refresh-dispatch", "t", env))(NP, { module }, active, {}, function() return frame end)
        local function unitRows(unit)
            local count = 0
            for _, host in ipairs(visible()) do
                if host.parent == plates[unit] then count = count + 1 end
            end
            return count
        end
        local function nextFull()
            local before = calls.updates
            NP.RefreshAll()
            check(calls.updates == before + 2, "one synchronous full pass shares successful same-NPC rows")
            check(unitRows("nameplate1") == 2 and unitRows("nameplate2") == 2,
                "shared data paints each distinct native plate immediately")
        end
        for _ = 1, 4 do module.Poll() end
        local tasks, previousTimer = {}, env.C_Timer
        env.C_Timer = { After = function(_, callback) tasks[#tasks+1] = callback end }
        local beforeRoster = calls.updates
        local beforeAnchors = calls.anchors
        for _ = 1,20 do frame:OnEvent("GROUP_ROSTER_UPDATE") end
        check(calls.updates == beforeRoster and #tasks == 1,"roster events coalesce before re-reading visible nameplates")
        tasks[1]()
        check(calls.updates == beforeRoster + 2,"one merged roster pass visits both distinct visible nameplates")
        check(calls.anchors == beforeAnchors,"the roster refresh keeps verified native badge anchors")
        module.Poll()
        check(calls.updates == beforeRoster + 4 and calls.anchors == beforeAnchors,
            "the follow-up poll still reads fresh quest progress without rewriting settled badge anchors")
        tasks = {}
        frame:OnEvent("GROUP_ROSTER_UPDATE")
        nextFull()
        frame:OnEvent("GROUP_ROSTER_UPDATE")
        beforeRoster = calls.updates
        tasks[1]()
        check(calls.updates == beforeRoster,"explicit refresh cancels only the old queued roster work")
        tasks[2]()
        check(calls.updates == beforeRoster + 2,"a newer roster callback still observes the current plates")
        env.C_Timer = nil
        frame:OnEvent("GROUP_ROSTER_UPDATE")
        check(calls.updates == beforeRoster + 4,"timerless adapter retains immediate refresh behavior")
        env.C_Timer = previousTimer
        nextFull(); nextFull()
        local row = visible()[1]
        local point, getPoint, getPointCount = {table.unpack(row.point)}, row.GetPoint, row.GetNumPoints
        for _, breakAnchor in ipairs({
            function() row:Hide() end,
            function() row.point[4] = point[4] + 1 end,
            function() row.GetNumPoints = function() return 2 end end,
            function() row.GetPoint = function() error("anchor unavailable") end end,
            function() row.point[4] = secret end,
        }) do
            breakAnchor()
            beforeAnchors = calls.anchors
            NP.RefreshAll()
            check(calls.anchors == beforeAnchors + 1 and row.shown and row.point[4] == point[4],
                "a changed, hidden or unreadable badge uses the ordinary anchor writer")
            row.GetPoint, row.GetNumPoints = getPoint, getPointCount
        end
        local before = calls.updates
        NP.RefreshUnit("nameplate1"); NP.RefreshUnit("nameplate2")
        check(calls.updates == before + 4, "standalone unit refreshes never retain full-pass lookup data")
        objects[101][1].numFulfilled = 3
        nextFull()
        local found = 0
        for _, host in ipairs(visible()) do if host.text.text == "3/8" then found = found + 1 end end
        check(found == 2, "next full pass observes changed progress for both same-NPC plates")
        objects[101][1].numFulfilled = 2
        before = calls.updates
        module.Poll()
        check(calls.updates == before + 2, "full refresh retains its original dirty poll")
        module.Poll()
        check(calls.updates == before + 2, "completed dirty poll settles at the original deadline")
        module.Added("nameplate1")
        nextFull()
        before = calls.updates
        for _ = 1, 3 do module.Poll() end
        check(calls.updates == before + 6, "full refresh preserves all three already-armed retries")
        module.Poll()
        check(calls.updates == before + 6, "retry budget still expires after three polls")

        -- A failed provider update must not publish partial NPC results to a
        -- later unit. The ordinary dispatcher reports each unit's exact error.
        local objective = entries.first.objective
        local update = objective.Update
        local attempts, failure = 0, {}
        objective.Update = function(self)
            attempts = attempts + 1
            if attempts == 1 then error(failure) end
            return update(self)
        end
        NP.RefreshAll()
        check(attempts == 2 and #errors == 1 and errors[1] == failure,
            "provider failure retains exact-error dispatch and independent later-unit retry")
        objective.Update = update
        nextFull()
        check(unitRows("nameplate1") == 2 and unitRows("nameplate2") == 2,
            "new batch recovers both plates after a provider error")

        env.Questie, env.QuestieLoader = nil, nil
        local queries, tooltips = calls.objectives, calls.tooltip
        NP.RefreshAll()
        check(calls.objectives == queries + 1 and calls.tooltip == tooltips + 2,
            "native fallback shares quest objectives but retains both unit tooltip queries")
        queries, tooltips = calls.objectives, calls.tooltip
        NP.RefreshAll()
        check(calls.objectives == queries + 1 and calls.tooltip == tooltips + 2,
            "next native full pass starts with fresh objectives and unit tooltips")
        queries, tooltips = calls.objectives, calls.tooltip
        NP.RefreshUnit("nameplate1"); NP.RefreshUnit("nameplate2")
        check(calls.objectives == queries + 2 and calls.tooltip == tooltips + 2,
            "native standalone refreshes keep independent lookup lifetimes")
        local oldGUID = guids.nameplate1
        guids.nameplate1 = secret
        queries, tooltips = calls.objectives, calls.tooltip
        NP.RefreshAll()
        check(calls.objectives == queries + 1 and calls.tooltip == tooltips + 1
            and unitRows("nameplate1") == 0 and unitRows("nameplate2") == 2,
            "secret unit identity is rechecked before consuming any public batch result")
        guids.nameplate1 = oldGUID
        NP.RefreshAll()
        if nativeTooltip then
            local get = env.C_TooltipInfo.GetUnit
            env.C_TooltipInfo.GetUnit = function(unit)
                if unit == "nameplate1" then error("tooltip unavailable") end
                return get(unit)
            end
            NP.RefreshAll()
            check(unitRows("nameplate1") == 0 and unitRows("nameplate2") == 2,
                "unit-local tooltip failure cannot poison another unit's association")
            env.C_TooltipInfo.GetUnit = get
            NP.RefreshAll()
            check(unitRows("nameplate1") == 2 and unitRows("nameplate2") == 2,
                "fresh full pass recovers a failed native tooltip")
        end
        local getter = qlog.GetQuestObjectives
        qlog.GetQuestObjectives = function() error("quest objectives unavailable") end
        NP.RefreshAll()
        check(unitRows("nameplate1") == 0 and unitRows("nameplate2") == 0,
            "failed native objective query clears unverified rows")
        qlog.GetQuestObjectives = getter
        NP.RefreshAll()
        check(unitRows("nameplate1") == 2 and unitRows("nameplate2") == 2,
            "failed native objective lookup is retried by the next full pass")

        -- Questie may be present before its tooltip module exists. That is
        -- still native fallback, whose associations can differ for one NPC.
        local providerReady = false
        env.Questie = questie
        env.QuestieLoader = { ImportModule = function(loader, name)
            if name == "QuestieTooltips" then return providerReady and questieModule or nil end
            return import(loader, name)
        end }
        local restoreTooltip
        if nativeTooltip then
            local get = env.C_TooltipInfo.GetUnit
            env.C_TooltipInfo.GetUnit = function(unit)
                local result = get(unit)
                if unit == "nameplate2" then return { lines = {} } end
                return result
            end
            restoreTooltip = function() env.C_TooltipInfo.GetUnit = get end
        else
            local get = scannerObject.SetUnit
            scannerObject.SetUnit = function(self, unit)
                local prior = legacyLines
                legacyLines = unit == "nameplate2" and { "Wolf", "Level 10 Beast" } or nil
                get(self, unit)
                legacyLines = prior
            end
            restoreTooltip = function() scannerObject.SetUnit = get end
        end
        for _ = 1, 2 do
            queries, tooltips = calls.objectives, calls.tooltip
            NP.RefreshAll()
            check(calls.objectives == queries + 1 and calls.tooltip == tooltips + 2,
                "present Questie with no tooltip module retains both native unit queries")
            check(unitRows("nameplate1") == 2 and unitRows("nameplate2") == 0,
                "same-NPC native fallback never copies another unit's quest association")
        end
        providerReady = true
        before, tooltips = calls.updates, calls.tooltip
        NP.RefreshAll()
        check(calls.updates == before + 2 and calls.tooltip == tooltips
            and unitRows("nameplate1") == 2 and unitRows("nameplate2") == 2,
            "actual Questie tooltip module restores one shared NPC lookup without native queries")
        providerReady = false
        tooltips = calls.tooltip
        NP.RefreshAll()
        check(calls.tooltip == tooltips + 2 and unitRows("nameplate2") == 0,
            "later provider loss immediately returns to per-unit native associations")
        restoreTooltip()
        env.Questie, env.QuestieLoader = questie, { ImportModule = import }
        if NP.IsSecretClient() then
            queries, tooltips, before = calls.objectives, calls.tooltip, calls.updates
            inInstance = true
            NP.RefreshAll()
            check(#visible() == 0 and calls.objectives == queries and calls.tooltip == tooltips
                and calls.updates == before, "restricted instance bypass remains ahead of every batch lookup")
            inInstance = false
            nextFull()
        end
        for _ = 1, 4 do module.Poll() end
    end
]=]
source = source:sub(1, at) .. "\n" .. probe .. source:sub(at + 1)
assert(load(source, "@nameplate-refresh-batch-fixture", "t", _G))()
