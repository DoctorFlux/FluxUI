-- Real quest-data/painter lifecycle under five client contracts. No game access.
local checks = 0
local function check(value, message)
    checks = checks + 1
    assert(value, message)
end

local function scenario(branch)
    local calls = { objectives = 0, tooltip = 0, frames = 0, text = 0, writes = 0 }
    local secret = setmetatable({}, { __tostring = function() error("secret string conversion") end })
    local secretTable = {}
    local handlers, modules, hosts, fonts = {}, {}, {}, {}
    local db = {}
    local active = { nameplate1 = true, nameplate2 = true }
    local objects = {
        [101] = {
            { type = "monster", text = "Wolves slain: 2/8", numFulfilled = 2, numRequired = 8, finished = false },
            { type = "item", text = "Wolf pelts: 1/5", numFulfilled = 1, numRequired = 5, finished = false },
            { type = "event", text = "Speak to the hunter", numFulfilled = 0, numRequired = 1, finished = false },
        },
        [102] = { { type = "monster", text = "Wolves slain: 2/8", numFulfilled = 2, numRequired = 8, finished = false } },
    }
    local function widget(parent)
        local w = { parent = parent, shown = true, width = 54 }
        function w:SetParent(v) self.parent = v end
        function w:GetParent() return self.parent end
        function w:Hide() self.shown = false end
        function w:Show() self.shown = true end
        function w:IsShown() return self.shown end
        function w:ClearAllPoints() self.point = nil end
        function w:SetPoint(...) self.point = { ... } end
        function w:SetSize(x, y) self.width, self.height = x, y end
        function w:GetWidth() return self.width end
        function w:SetFont(...) self.font = { ... } end
        function w:GetStringWidth() return #self.text * self.font[2] / 2 end
        function w:SetShadowColor() end
        function w:SetShadowOffset() end
        function w:SetJustifyH() end
        function w:SetWordWrap() end
        function w:SetTextColor() end
        function w:SetTexture(v) self.texture = v end
        function w:SetText(v) self.text = v; calls.text = calls.text + 1 end
        function w:SetFormattedText(format, ...) self:SetText(string.format(format, ...)) end
        function w:CreateTexture() return widget(self) end
        function w:CreateFontString() return widget(self) end
        return w
    end
    local ui = widget()
    local plates = { nameplate1 = { frame = widget(), container = widget(), bar = widget() },
        nameplate2 = { frame = widget(), container = widget(), bar = widget() } }
    local guids = { player = "Player-1-A", nameplate1 = "Creature-0-1-2-3-42-0001", nameplate2 = "Creature-0-1-2-3-42-0002" }
    local entries = { first = { questId = 101, objective = { Index = 1 } },
        second = { questId = 101, objective = { Index = 2 } } }
    for _, entry in pairs(entries) do
        entry.objective.Update = function(self)
            calls.updates = (calls.updates or 0) + 1
            local row = objects[entry.questId] and objects[entry.questId][self.Index]
            if row then self.Type, self.Collected, self.Needed, self.Completed = row.type, row.numFulfilled, row.numRequired, row.finished end
        end
    end
    local questieModule = { lookupByKey = { m_42 = entries } }
    local questiePlates = { hides = 0, shown = true }
    function questiePlates:HideCurrentFrames() self.hides = self.hides + 1; self.shown = false end
    local questie = { db = { profile = { nameplateEnabled = true, nameplateTargetFrameEnabled = true } }, API = {} }
    local function import(_, name)
        if name == "QuestieNameplate" then return questiePlates end
        assert(name == "QuestieTooltips"); return questieModule
    end
    local callback, readyCallback, registrations, readyRegistrations = nil, nil, 0, 0
    function questie.API.RegisterForQuestUpdates(fn) callback = fn; registrations = registrations + 1 end
    function questie.API.RegisterOnReady(fn) readyCallback = fn; readyRegistrations = readyRegistrations + 1 end
    local NP = {
        activeUnits = active, PREVIEW_UNIT = "preview", FONT = "Fonts\\FRIZQT__.TTF",
        IsSecret = function(value) return value == secret end,
        BoolTest = function(value, default) if value == secret then return default end; return value and true or false end,
        GetDB = function() return db end,
        RegisterModule = function(name, module) modules[name] = module; return module end,
        GetParts = function(unit)
            local p = plates[unit]
            if p then return p.frame, p, p.container, p.bar end
        end,
        IsLiveClient = function() return branch == "live" end,
		IsSecretClient = function() return branch == "live" or branch == "forever" end,
        PlateTextOffsetY = function() return 1 end,
        CreateClientPlate = function(role)
            local host = widget(ui); host.role = role
            calls.frames = calls.frames + 1; hosts[#hosts + 1] = host
            return host
        end,
        FitPlate = function(host, text) host:SetSize(text:GetStringWidth() + 10, 14) end,
        ShowPlate = function() end,
        AttachHost = function(host, plate) host:SetParent(plate); return true end,
        ReleaseHost = function(host) host:Hide(); host:ClearAllPoints(); host:SetParent(ui) end,
    }
    local env = setmetatable({ UIParent = ui, Questie = questie,
        QuestieLoader = { ImportModule = import },
        issecrettable = function(value) return value == secretTable end,
        UnitGUID = function(unit) return guids[unit] end,
        Enum = { TooltipDataLineType = { QuestTitle = 17, QuestPlayer = 18, QuestObjective = 8 } },
    }, { __index = _G })
    env._G = env
	local inInstance = false
	env.IsInInstance = function() return inInstance end
	env.wipe = function(t) for key in pairs(t) do t[key] = nil end end
    local qlog = {
        GetQuestObjectives = function(id) calls.objectives = calls.objectives + 1; return objects[id] end,
        IsOnQuest = function(id) return objects[id] ~= nil end,
    }
    if branch == "live" or branch == "forever" then
        qlog.GetNumQuestLogEntries = function() return 1 end
        qlog.GetInfo = function() return { questID = 101, title = "The hunt", isHeader = false } end
    else
        env.GetNumQuestLogEntries = function() return 1 end
        env.GetQuestLogTitle = function() return "The hunt", 10, nil, false, false, nil, nil, 101 end
    end
    env.C_QuestLog = qlog
    local tooltipLines = {
        { type = 17, id = 101, leftText = "The hunt" },
        { type = 8, leftText = "Wolves slain: 2/8" },
        { type = 8, leftText = "Wolf pelts: 1/5" },
    }
    local nativeTooltip = branch == "live" or branch == "forever"
    if nativeTooltip then
        env.C_TooltipInfo = { GetUnit = function() calls.tooltip = calls.tooltip + 1; return { lines = tooltipLines } end }
    end
    local legacyLines, scannerObject
    env.CreateFrame = function(kind, name, parent, template)
        assert(kind == "GameTooltip" and name == "FluxNamePlateQuestScanner" and template == "GameTooltipTemplate")
        local scan = widget(parent); scannerObject = scan
        function scan:SetOwner(_, anchor) assert(anchor == "ANCHOR_NONE") end
        function scan:ClearLines() fonts = {} end
        function scan:SetUnit()
            calls.tooltip = calls.tooltip + 1
            for i, text in ipairs(legacyLines or { "Wolf", "The hunt", objects[101][1].text, objects[101][2].text }) do
                fonts[i] = { GetText = function() return text end, IsObjectType = function(_, kind) return kind == "FontString" end }
                env[name .. "TextLeft" .. i] = fonts[i]
            end
        end
        function scan:GetRegions() return table.unpack(fonts) end
        return scan
    end
    local events = {
        Register = function(event, fn) handlers[event] = fn end,
        Unregister = function(event) handlers[event] = nil end,
    }
    local ns = { Flux = { NamePlates = NP, Events = events } }
    local f = assert(io.open(os.getenv("FLUX_QUEST_CORE") or "NamePlates/Core.lua")); local core = f:read("*a"); f:close()
    local first = assert(core:find("-- Small quest progress tags:", 1, true))
    local last = assert(core:find("-- Forever world plates:", first, true))
    local code = "local _, ns = ...; local Flux = ns.Flux; local NP = Flux.NamePlates; local activeUnits = NP.activeUnits\n" .. core:sub(first, last - 1)
    assert(load(code, "@Core-quest-block", "t", env))("_FluxUI", ns)
    local module = modules.quest
    module.Added("nameplate1")
    module.Added("nameplate2")
    local function visible()
        local list = {}
        for _, host in ipairs(hosts) do if host.shown then list[#list + 1] = host end end
        return list
    end
    check(#visible() == 4, branch .. " Flux rows survive disabling Questie own nameplates")
    check(calls.objectives == 0, branch .. " Questie path performs no native log scan")
    check(questie.db.profile.nameplateEnabled == false and not questiePlates.shown and questiePlates.hides == 1, "Questie native setting disabled and existing markers cleared once")
    check(questie.db.profile.nameplateTargetFrameEnabled == true, "Questie target-frame marker remains independent")
    check(registrations == 1, branch .. " one optional public Questie callback")
    check(readyRegistrations == 1, "one optional Questie ready callback")
    for _, host in ipairs(visible()) do
        check(host.parent == plates.nameplate1 or host.parent == plates.nameplate2, "host parent is plate")
        check(host.role == "quest" and host.point[1] == "TOPLEFT" and host.point[3] == "BOTTOMLEFT", "top-left at bottom-left; opposite level")
		check(host.point[4] == 0 and (host.point[5] == 3 or host.point[5] == -13), "left edge; compact first row center aligns with threat/level at -3; later rows stack down")
		check(host.height == 12 and host.text.font[2] == 10, "smaller quest badge and count text")
		check(host.icon.width == 10 and host.icon.height == 10 and host.icon.point[4] == 2 and host.icon.point[5] == 0,
			"icon has two-unit left inset and one-unit vertical inset")
		check(host.text.point[4] == 2 and host.width == host.text:GetStringWidth() + 16,
			"tight icon-to-count gap and two-unit right inset without excess shared padding")
        check(host.text.text == "2/8" or host.text.text == "1/5", "actual count")
        check(host.icon.texture:find(host.text.text == "2/8" and "QuestSlay.blp" or "QuestLoot.blp"), "distinct kill/loot icon")
    end
    -- Drain bounded readiness refresh; a settled plate does no data/painter work.
    for _ = 1, 4 do module.Poll() end
    local queries, tooltips, writes, frames = calls.objectives, calls.tooltip, calls.text, calls.frames
    for _ = 1, 1000 do module.Poll() end
    check(calls.objectives == queries and calls.tooltip == tooltips and calls.text == writes and calls.frames == frames, "idle polls do no work")
	plates.nameplate1.bar.shown = false
	module.Poll()
	check(#visible() == 2, "native name-only transition hides attached quest rows without a quest event")
	plates.nameplate1.bar.shown = true
	module.Poll()
	check(#visible() == 4 and calls.frames == frames, "native health bar return recovers pooled rows")
	-- A late-ready Questie must not leave the badge waiting for another quest event.
	questie.API.isReady = false
	module.Refresh("nameplate1")
	check(#visible() == 4 and calls.tooltip > tooltips, "Questie initialization uses available native data")
	questie.API.isReady = true
	readyCallback()
	module.Poll()
	check(#visible() == 4 and readyRegistrations == 1, "Questie ready notification refreshes without duplicate subscription")
	if NP.IsSecretClient() then
		local beforeQueries, beforeTooltips, beforeUpdates = calls.objectives, calls.tooltip, calls.updates
		inInstance = true
		module.RefreshAll(); module.Refresh("nameplate1"); module.Refresh("nameplate2"); module.Poll()
		check(#visible() == 0, "restricted instance clears old world counts")
		check(calls.objectives == beforeQueries and calls.tooltip == beforeTooltips and calls.updates == beforeUpdates,
			"restricted instance invokes neither native tooltip rebuild nor Questie objective lookup")
		inInstance = false
		module.RefreshAll(); module.Poll()
		check(#visible() == 4, "leaving instance restores public world objectives")
	end
	for _ = 1, 4 do module.Poll() end
	queries, tooltips, writes = calls.objectives, calls.tooltip, calls.text
    local hides = questiePlates.hides
    questie.db.profile.nameplateEnabled = true; questiePlates.shown = true
    module.Poll()
    check(#visible() == 4 and questie.db.profile.nameplateEnabled == false and not questiePlates.shown, "Questie marker cannot stay enabled alongside Flux")
    check(questiePlates.hides == hides + 1 and calls.text == writes, "quiet enforcement only clears the foreign marker once without repainting Flux")
    for _ = 1, 100 do module.Poll() end
    check(questiePlates.hides == hides + 1, "stable disabled Questie setting adds no repeated hide calls")
    local priorProfile = questie.db.profile
    questie.db.profile = { nameplateEnabled = true, nameplateTargetFrameEnabled = true, trackerEnabled = true }
    module.Poll()
    check(questie.db.profile.nameplateEnabled == false and priorProfile.nameplateEnabled == false, "new Questie profile receives the same marker policy")
    check(questie.db.profile.trackerEnabled == true and questie.db.profile.nameplateTargetFrameEnabled == true, "other Questie profile settings remain intact")
    local invalidator = handlers.QUEST_LOG_UPDATE
    objects[101][1].numFulfilled = 3; objects[101][1].text = "Wolves slain: 3/8"
    tooltipLines[2].leftText = objects[101][1].text
    for _ = 1, 100 do invalidator("QUEST_LOG_UPDATE") end
    check(calls.objectives == queries, "event storm does not synchronously scan")
    local updates = calls.updates
    module.Poll()
    check(calls.updates == updates + 2, "one Questie refresh per objective shared across same-NPC plates")
    check(calls.objectives == queries, "Questie storm does not scan the native log")
    local advanced = 0
    for _, host in ipairs(visible()) do if host.text.text == "3/8" then advanced = advanced + 1 end end
    check(advanced == 2, "kill progress advances on both same-NPC plates")
    objects[101][1].finished = true
    objects[101][2].numFulfilled = 5
    invalidator("QUEST_LOG_UPDATE"); module.Poll()
    check(#visible() == 0, "completed kill and loot rows disappear")
    objects[101][1].finished = false; objects[101][2].numFulfilled = 2
    invalidator("QUEST_LOG_UPDATE"); module.Poll()
    check(#visible() == 4 and calls.frames == frames, "pool reuses rows after reacquisition")
    -- No stale quest state may follow a token recycled to a player/nonquest NPC.
    module.Removed("nameplate1"); active.nameplate1 = nil
    check(#visible() == 2, "remove releases all rows")
    guids.nameplate1 = "Player-1-B"; active.nameplate1 = true; module.Added("nameplate1")
    check(#visible() == 2, "player unit never receives a quest badge")
    guids.nameplate1 = secret; module.Added("nameplate1")
    check(#visible() == 2, "secret GUID never parsed or displayed")
    guids.nameplate1 = "Creature-0-1-2-3-42-0003"; module.Added("nameplate1")
    check(#visible() == 4, "safe token reuse recovers")
    -- The independent native route works with all Questie globals absent.
    env.Questie, env.QuestieLoader = nil, nil
    module.Refresh("nameplate1")
    check(#visible() == 4, "native tooltip/legacy scan independent of Questie")
    if nativeTooltip then
        objects[101][1].numFulfilled = 4; objects[101][1].text = "Loups tuÃ©s : 4/8"
        tooltipLines[2].leftText = "|cffffffff" .. objects[101][1].text .. "|r"
        module.Refresh("nameplate1")
        local found
        for _, host in ipairs(visible()) do if host.parent == plates.nameplate1 and host.text.text == "4/8" then found = true end end
        check(found, "Blizzard-only localized kill progress updates from native log counters")
        objects[101][2].numFulfilled = 3; objects[101][2].text = "Peaux de loup : 3/5"
        tooltipLines[3].leftText = objects[101][2].text; module.Refresh("nameplate1")
        found = false
        for _, host in ipairs(visible()) do if host.parent == plates.nameplate1 and host.text.text == "3/5" then found = true end end
        check(found, "Blizzard-only localized loot progress updates")
        local membership = qlog.IsOnQuest
        qlog.IsOnQuest = function() return false end; module.Refresh("nameplate1")
        for _, host in ipairs(visible()) do check(host.parent ~= plates.nameplate1, "native abandoned quest ignores stale tooltip block") end
        qlog.IsOnQuest = membership
        local api = env.C_TooltipInfo
        env.C_TooltipInfo = nil; module.Refresh("nameplate1")
        for _, host in ipairs(visible()) do check(host.parent ~= plates.nameplate1, "missing native tooltip capability clears stale badge") end
        env.C_TooltipInfo = api
        tooltipLines = { { type = 17, id = 101 }, { type = 18, guid = "Player-1-Other" },
            { type = 8, leftText = objects[101][1].text }, { type = 8, leftText = objects[101][2].text } }
        module.Refresh("nameplate1")
        check(#visible() == 2, "other party member progress ignored")
        tooltipLines[2].guid = "Player-1-A"; module.Refresh("nameplate1")
        check(#visible() == 4, "player-specific tooltip block supported")
        tooltipLines[1].id = secret; module.Refresh("nameplate1")
        check(#visible() == 2, "secret quest title cannot select public objective")
        tooltipLines = { secretTable }; module.Refresh("nameplate2")
        check(#visible() == 0, "secret tables never inspected")
        -- A quest hidden under a collapsed log header resolves by membership.
        tooltipLines = { { type = 17, id = 102 }, { type = 8, leftText = objects[102][1].text } }
        module.Refresh("nameplate1")
        check(#visible() == 1 and visible()[1].text.text == "2/8", "collapsed quest and duplicate objective text scoped by title id")
    end
    if not nativeTooltip then
        check(scannerObject and scannerObject.shown == false, "private legacy scanner never remains visible")
        legacyLines = { "Wolf", "Level 10 Beast" }; module.Refresh("nameplate1")
        for _, host in ipairs(visible()) do check(host.parent ~= plates.nameplate1, "legacy no native quest block hides instead of inventing drop association") end
        legacyLines = nil
        env.GetNumQuestLogEntries = function() return 2 end
        env.GetQuestLogTitle = function(index) return "The hunt", 10, nil, false, false, nil, nil, index == 1 and 101 or 102 end
        module.Refresh("nameplate1")
        for _, host in ipairs(visible()) do check(host.parent ~= plates.nameplate1, "ambiguous legacy quest title never selects another quest") end
        env.GetNumQuestLogEntries = function() return 1 end
        env.GetQuestLogTitle = function() return "The hunt", 10, nil, false, false, nil, nil, 101 end
        module.Refresh("nameplate1")
        check(#visible() == 4, "legacy fallback recovers after readable objective rows return")
    end
    env.Questie, env.QuestieLoader = questie, { ImportModule = import }
    tooltipLines = { { type = 17, id = 101 }, { type = 8, leftText = objects[101][1].text }, { type = 8, leftText = objects[101][2].text } }
    tooltipLines = { { type = 17, id = 101 }, { type = 8, leftText = objects[101][1].text },
        { type = 8, leftText = objects[101][2].text } }
    db.questOverlayEnabled = false
    module.RefreshAll()
    for _ = 1, 4 do module.Poll() end
    check(#visible() == 0 and next(handlers) == nil, "disable releases frames and all owned event subscriptions")
    questie.db.profile.nameplateEnabled = true
    module.Poll()
    check(questie.db.profile.nameplateEnabled == true, "disabled Flux overlay stops enforcing the Questie marker policy")
    queries, tooltips = calls.objectives, calls.tooltip
    callback(101, 1, "update"); module.Poll()
    check(calls.objectives == queries and calls.tooltip == tooltips, "unregister-less Questie callback inert while disabled")
    db.questOverlayEnabled = true; module.RefreshAll(); module.Refresh("nameplate1")
    check(registrations == 1 and handlers.QUEST_LOG_UPDATE ~= nil, "reenable registers native events without duplicate Questie callback")
    check(questie.db.profile.nameplateEnabled == false, "reenabling Flux disables Questie marker again")
    -- All unsupported/secret/malformed objectives clear rather than retain old counts.
    for _, value in ipairs({ secret, -1, math.huge, 0/0, 1.5 }) do
        objects[101][1].numFulfilled = value; objects[101][2].numRequired = 0
        module.Refresh("nameplate1")
        for _, host in ipairs(visible()) do check(host.parent ~= plates.nameplate1, "bad counter clears badge") end
    end
    objects[101] = nil
    module.Refresh("nameplate1")
    for _, host in ipairs(visible()) do check(host.parent ~= plates.nameplate1, "removed quest never resurrected by stale Questie map") end
    print(string.format("QUEST_PROGRESS client=%s frames=%d checks=%d idle_polls=1000 idle_queries=0", branch, calls.frames, checks))
end

for _, branch in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do scenario(branch) end
local function source(path) local f = assert(io.open(path)); local s = f:read("*a"); f:close(); return s end
local toc = source("_FluxUI.toc")
check(not toc:find("NamePlates\\QuestData.lua", 1, true) and not toc:find("NamePlates\\Quest.lua", 1, true), "no new runtime files or database")
check(source("AddonOptions/FluxOptionsDefaults.lua"):find("questOverlayEnabled = true", 1, true), "default enabled")
check(source("AddonOptions/FluxOptionsNameplates.lua"):find("Show quest kill / loot progress", 1, true), "own option exposed")
local function bytes(path) local f=assert(io.open(path,"rb"));local b=f:read("*a");f:close();return b end
check(#bytes("Texture/QuestSlay.blp") == 2564 and #bytes("Texture/QuestLoot.blp") == 2564, "two small standalone icons")
check(bytes("Texture/QuestSlay.blp") ~= bytes("Texture/QuestLoot.blp"), "kill and loot artwork are distinct")
print(string.format("QUEST_PROGRESS checks=%d failures=0 native_pixels_taint_performance=NOT_RUN", checks))
