-- On-demand diagnostics must identify shared native scripts without waking UI.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local file = assert(io.open(root .. "Other/FluxPerfCapture.lua", "rb"))
local source = file:read("*a"); file:close()
local checks = 0
local function check(value, message)
    assert(value, "perf capture: " .. message)
    checks = checks + 1
end

local function run(branch, profile, change, restrictedMetrics)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local now, timers, output, inspections, sourceReads, forbiddenSources = 0, {}, {}, 0, 0, 0
    local metricReads = 0
    local frames = {}
    local function frame(name, visible, update, forbidden)
        local value = { name = name, shown = visible, visible = visible, update = update }
        function value:IsForbidden() return forbidden end
        function value:GetName() assert(not forbidden); return self.name end
        function value:GetObjectType() assert(not forbidden); return self.kind or "Frame" end
        function value:GetNumRegions() assert(not forbidden); return self.regions or 0 end
        function value:GetEffectiveAlpha() assert(not forbidden); return self.alpha end
        function value:GetScript(key) assert(not forbidden); return key == "OnUpdate" and self.update or nil end
        function value:IsVisible() assert(not forbidden); return self.visible end
        function value:IsShown() assert(not forbidden); return self.shown end
        function value:GetParent() assert(not forbidden) end
        function value:GetSourceLocation()
            if forbidden then forbiddenSources = forbiddenSources + 1 end
            assert(not forbidden, "inspected forbidden creation source")
            sourceReads = sourceReads + 1
            if self.badSource then error("unsupported source read") end
            return self.creationSource
        end
        function value:SetScript() error("diagnostic changed a frame") end
        function value:Show() error("diagnostic showed a frame") end
        frames[#frames + 1] = value
        return value
    end
    local shared, owned = function() end, function() end
    env.WorldMapFrame = frame("WorldMapFrame", false, shared)
    env.WorldMapFrame.creationSource = "Interface/AddOns/Blizzard_WorldMap/WorldMap.xml:20"
    env.BattlefieldMapFrame = frame("BattlefieldMapFrame", true, shared)
    env.BattlefieldMapFrame.creationSource = "Interface/AddOns/Blizzard_BattlefieldMap/BattlefieldMap.xml:10"
    local own = frame(nil, true, owned)
    own.creationSource = "Interface/AddOns/_FluxUI/Other/Test.lua:42"
    local secretSource = frame("SecretSource", true, function() end)
    secretSource.creationSource = "SECRET_CREATION_SOURCE"
    local unsupportedSource = frame("UnsupportedSource", true)
    unsupportedSource.GetSourceLocation = nil
    local failingSource = frame("FailingSource", true)
    failingSource.badSource = true
    local model = frame("FluxVisibleModel", true)
    model.kind, model.alpha, model.regions = "PlayerModel", 0, 3
    local secretModel = frame("SecretModel", true)
    secretModel.kind, secretModel.alpha, secretModel.regions = "ModelScene", { secret = true }, { secret = true }
    local hiddenModel = frame("HiddenModel", false)
    hiddenModel.kind = "PlayerModel"
    frame("Forbidden", true, shared, true)
    env.CharacterFrame = frame("CharacterFrame", false)
    env.FluxWindowFrame = { GetActiveTab = function() return "Map" end,
        GetFrame = function() error("diagnostic constructed Flux Window") end }
    local flux = { Client = { expansion = branch, gameType = branch == "forever" and "camelot" or branch },
        Inspectable = { driver = own }, Ticker = { GetSubscribers = function() return {} end } }
    flux.RestrictedNativeData = setmetatable({ inaccessible = true }, {
        __index = function() error("inspected inaccessible namespace table") end,
        __pairs = function() error("enumerated inaccessible namespace table") end,
    })
    flux.SecretNativeData = setmetatable({ secretTable = true }, {
        __index = function() error("inspected secret namespace table") end,
        __pairs = function() error("enumerated secret namespace table") end,
    })
    env.canaccesstable = function(value) return not rawget(value, "inaccessible") end
    env.issecrettable = function(value) return rawget(value, "secretTable") == true end
    env.print = function(...)
        local parts = {}; for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        output[#output + 1] = table.concat(parts, " ")
    end
    env.GetTime = function() return now end
    env.GetBuildInfo = function() return "test", 70532 end
    env.GetFramerate = function() return 200 end
    env.issecretvalue = function(value)
        return value == "SECRET_CREATION_SOURCE" or (type(value) == "table" and value.secret)
    end
    env.GetCVar = function(name) return name == "scriptProfile" and profile or "0" end
    if branch == "forever" or branch == "live" then
        env.Enum = { AddOnProfilerMetric = { RecentAverageTime = 1 } }
        env.C_AddOnProfiler = {
            GetApplicationMetric = function(metric)
                metricReads = metricReads + 1
                assert(metric == 1)
                if restrictedMetrics == "secret" then
                    return setmetatable({ secret = true }, { __add = function() error("used secret profiler metric") end })
                end
                if restrictedMetrics == "error" then error("metric unavailable") end
                return 5
            end,
            GetOverallMetric = function(metric) assert(metric == 1); return .2 end,
            GetAddOnMetric = function(name, metric) assert(name == "_FluxUI" and metric == 1); return .05 end,
        }
        if restrictedMetrics == "missing" then env.C_AddOnProfiler.GetOverallMetric = nil end
    end
    env.EnumerateFrames = function(previous)
        inspections = inspections + 1
        if not previous then return frames[1] end
        for i, value in ipairs(frames) do if previous == value then return frames[i + 1] end end
    end
    local function cpu() return profile == "1" and now * 2 or 0, math.floor(now * 100) end
    env.GetAddOnCPUUsage, env.GetFrameCPUUsage, env.GetFunctionCPUUsage = cpu, cpu, cpu
    env.UpdateAddOnCPUUsage = function() end
    local function timer(delay, callback)
        local t = { at = now + delay, callback = callback }
        function t:Cancel() self.cancelled = true end
        timers[#timers + 1] = t
        return t
    end
    env.C_Timer = { NewTimer = timer, NewTicker = timer }
    local text = change and change(source) or source
    assert(load(text, "@Other/FluxPerfCapture.lua", "t", env))("_FluxUI", { Flux = flux })
    check(inspections == 0 and #timers == 0 and sourceReads == 0 and metricReads == 0,
        "loading diagnostics performs no scans or recurring work")
    flux.PerfCapture.Start(5)
    check(#timers == 2, "only requested capture arms sampler and completion")
    now = 5
    timers[1].callback(); timers[2].callback()
    check(timers[1].cancelled, "completion cancels capture sampler")
    local result = env.FluxPerfCaptureDB
    check(forbiddenSources == 0, "forbidden owners never have creation sources inspected")
    check(result and result.uiBefore.worldMap == "shown=false/visible=false"
        and result.uiAfter.battlefieldMap == "shown=true/visible=true" and result.uiAfter.fluxTab == "Map",
        "closed world map and visible embedded map are recorded independently")
    local p = result.presentationAfter
    check(p and p.visibleRegions == 3 and #p.models == 2,
        "presentation records visible models and excludes hidden models and secret region counts")
    local models = {}; for _, row in ipairs(p.models) do models[row.label] = row end
    check(models.FluxVisibleModel.alpha == 0 and models.SecretModel.alpha == nil,
        "visible transparent models stay distinct from unknown secret alpha")
    if restrictedMetrics then
        check(result.recentProfiler == nil, "unavailable or secret modern metrics remain omitted")
    elseif branch == "forever" or branch == "live" then
        check(result.recentProfiler and result.recentProfiler.applicationMs == 5
            and result.recentProfiler.overallMs == .2 and result.recentProfiler.addonMs == .05,
            "modern application and addon metrics are sampled without scriptProfile")
    else
        check(result.recentProfiler == nil, "older clients need no modern profiler API")
    end
    if profile == "1" then
        local row
        for _, value in ipairs(result.functions) do if value.ownerCount == 2 then row = value end end
        check(row and row.visibleOwners == 1 and #row.owners == 2,
            "shared callback reports both owners and just one visible owner")
        local ownerSources = {}
        for _, owner in ipairs(row.ownerSources or {}) do ownerSources[owner.label] = owner.creationSource end
        check(ownerSources.WorldMapFrame == env.WorldMapFrame.creationSource
            and ownerSources.BattlefieldMapFrame == env.BattlefieldMapFrame.creationSource,
            "registered owner creation sources persist separately for a shared callback")
        local alias
        for _, value in ipairs(result.frames) do if value.label == "Flux.Inspectable.driver" then alias = value end end
        check(alias ~= nil, "anonymous owned frame uses its namespace path")
        check(alias.creationSource == own.creationSource, "frame creation source persists in ranked frame rows")
        local callback
        for _, value in ipairs(result.functions) do if value.label == "Flux.Inspectable.driver:OnUpdate" then callback = value end end
        check(callback and callback.ownerSources[1].creationSource == own.creationSource,
            "anonymous callback retains its owner's creation source")
        for _, value in ipairs(result.frames) do
            if value.label == "SecretSource" or value.label == "UnsupportedSource" or value.label == "FailingSource" then
                check(value.creationSource == nil, "unavailable or restricted frame source never persists")
            end
        end
        for _, value in ipairs(result.functions) do
            if value.label == "SecretSource:OnUpdate" then
                check(value.ownerSources[1].creationSource == nil, "restricted registered owner source never persists")
            end
        end
        check(table.concat(output, "\n"):find("script owners: 2 frames, 1 visible", 1, true),
            "printed ranking warns that callback CPU is shared")
        check(table.concat(output, "\n"):find("direct method calls", 1, true),
            "report distinguishes registered script ownership from direct calls")
        check(table.concat(output, "\n"):find("owner created at: " .. own.creationSource, 1, true),
            "printed anonymous callback includes owner creation source")
        check(table.concat(output, "\n"):find("not callback definitions", 1, true),
            "report distinguishes owner creation source from callback definition")
    else
        check(#result.frames == 0 and #result.functions == 0, "disabled profiler does not invent CPU attribution")
    end
    check(result.client == branch and result.scriptProfile == profile, "client and profiler context preserved")
    local reads, sources, metricsRead = inspections, sourceReads, metricReads
    flux.PerfCapture.Print()
    check(inspections == reads and sources == sourceReads and metricsRead == metricReads,
        "printing saved report does not enumerate frames")
    flux.PerfCapture.Start(5)
    flux.PerfCapture.Cancel()
    check(timers[3].cancelled and timers[4].cancelled, "cancellation stops both requested timers")
    -- Old saved reports remain printable after the additive schema change.
    result.uiBefore, result.uiAfter = nil, nil
    result.presentationBefore, result.presentationAfter = nil, nil
    result.recentProfiler = nil
    for _, rows in ipairs({ result.frames, result.functions }) do
        for _, row in ipairs(rows) do row.creationSource, row.ownerSources = nil, nil end
    end
    flux.PerfCapture.Print()
end

for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    run(branch, "0"); run(branch, "1")
end
for _, mode in ipairs({ "secret", "error", "missing" }) do run("forever", "0", nil, mode) end
local mutations = {
    { "visibility evidence", 'worldMap = FrameState(_G.WorldMapFrame)', 'worldMap = FrameState(_G.BattlefieldMapFrame)',
        "closed world map and visible embedded map are recorded independently" },
    { "shared owner count", 'row.ownerCount = (row.ownerCount or 0) + 1', 'row.ownerCount = 1',
        "shared callback reports both owners and just one visible owner" },
    { "namespace frame alias", 'aliases[tbl] = path; return', 'return', "anonymous owned frame uses its namespace path" },
    { "inaccessible table guard", 'if canaccesstable and not canaccesstable(value) then return false end', '',
        "inspected inaccessible namespace table" },
    { "secret table guard", 'if issecrettable and issecrettable(value) then return false end', '',
        "inspected secret namespace table" },
    { "owner creation source", 'local creationSource = Method(frame, "GetSourceLocation")', 'local creationSource = nil',
        "registered owner creation sources persist separately for a shared callback" },
    { "secret source value", 'if ok and not (issecretvalue and issecretvalue(value)) then return value end', 'if ok then return value end',
        "unavailable or restricted frame source never persists" },
    { "forbidden source inspection", ' and not Method(frame, "IsForbidden") then', ' then',
        "forbidden owners never have creation sources inspected" },
    { "visible model collection", 'and kind:find("Model", 1, true)', 'and false',
        "presentation records visible models" },
    { "transparent model alpha", 'alpha = PlainNumber(alpha) and alpha or nil', 'alpha = nil',
        "visible transparent models stay distinct" },
    { "secret modern metric", 'if ok and PlainNumber(value) then return value end', 'if ok then return value end',
        "used secret profiler metric", "secret" },
}
for _, mutation in ipairs(mutations) do
    local ok, message = pcall(run, "forever", "1", function(text)
        local at = assert(text:find(mutation[2], 1, true), "missing mutation anchor")
        return text:sub(1, at - 1) .. mutation[3] .. text:sub(at + #mutation[2])
    end, mutation[5])
    check(not ok and tostring(message):find(mutation[4], 1, true), mutation[1] .. " fails for its intended reason")
end
print("perf capture: " .. checks .. " checks across five clients; " .. #mutations .. " mutations rejected")
