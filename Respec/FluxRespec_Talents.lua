-- FluxRespec_Talents.lua
-- Classic / Wrath / Cata talent capture & apply. Uses dual-spec swap when the
-- inactive group already matches the target template. Falls back to learning
-- individual talent points one at a time (like Talented/apply.lua).

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.Talents = R.Talents or {}
local Talents = R.Talents
local Compat = R.Compat

-- -----------------------------------------------------------------------------
-- Retail (post-Dragonflight) router: delegate all public Talents.* calls to
-- FluxRespec_TalentsRetail.lua on clients that have the saved-loadout system.
-- Classic / Wrath / Cata bodies below are unchanged and continue to run as-is.
-- -----------------------------------------------------------------------------

local function UseRetail()
    return Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts() == true
        and R.TalentsRetail ~= nil
end

-- -----------------------------------------------------------------------------
-- Low-level reads
-- -----------------------------------------------------------------------------

local function GetNumTabs()
    if _G.GetNumTalentTabs then
        local ok, n = pcall(_G.GetNumTalentTabs, false, false)
        if ok and type(n) == "number" then return n end
    end
    return 0
end

local function GetTalentInfoSafe(tab, index, inspect, pet, group)
    -- Classic Era only supports (tab, index). TBC+ supports (tab, index, inspect, pet, group).
    if _G.GetTalentInfo then
        local ok, name, iconTexture, tier, col, rank, maxRank =
            pcall(_G.GetTalentInfo, tab, index, inspect or false, pet or false, group)
        if ok then
            return name, iconTexture, tier, col, rank, maxRank
        end
    end
    return nil
end

local function GetNumTalentsInTab(tab)
    if _G.GetNumTalents then
        local ok, n = pcall(_G.GetNumTalents, tab, false, false)
        if ok and type(n) == "number" then return n end
    end
    return 0
end

--- Return the rank table {[tab]={[index]=rank}} for a given talent group.
function Talents.ReadGroup(groupIndex)
    local groups = Compat.GetNumGroups()
    groupIndex = groupIndex or Compat.GetActiveGroup()
    if groupIndex < 1 then groupIndex = 1 end
    if groupIndex > groups then groupIndex = groups end

    local out = {}
    local numTabs = GetNumTabs()
    for tab = 1, numTabs do
        local tree = {}
        local numTalents = GetNumTalentsInTab(tab)
        for i = 1, numTalents do
            local _, _, _, _, rank = GetTalentInfoSafe(tab, i, false, false, groupIndex)
            tree[i] = tonumber(rank) or 0
        end
        out[tab] = tree
    end
    return out
end

--- Icon path/fileID representing the saved build: dominant talent tab (Classic-style trees),
--- or specialization icon on Retail when there are no classic tabs. Matches UnitFrames "spec from tabs" logic.
function Talents.SpecIconFromSnapshot(snapshot)
    if UseRetail() then
        return R.TalentsRetail.SpecIconFromSnapshot(snapshot)
    end
    if type(snapshot) ~= "table" or type(snapshot.points) ~= "table" then
        return nil
    end
    local points = snapshot.points

    local function specIconFromSpecialization()
        if not _G.GetSpecialization or not _G.GetSpecializationInfo then return nil end
        local ok, specIdx = pcall(_G.GetSpecialization, false, false)
        if not ok or not specIdx or specIdx < 1 then
            ok, specIdx = pcall(_G.GetSpecialization)
            if not ok or not specIdx or specIdx < 1 then return nil end
        end
        local _, _, classID = UnitClass("player")
        local sex = UnitSex and UnitSex("player") or 2
        local tries = {
            { specIdx },
            { specIdx, false },
            { specIdx, false, false },
            { specIdx, false, false, sex, classID },
        }
        for _, args in ipairs(tries) do
            local r = { pcall(_G.GetSpecializationInfo, unpack(args)) }
            if r[1] then
                -- After pcall: r[2..] = API returns. Icon is select(4, ...) = r[5] (same as UnitFrames).
                for _, k in ipairs({ 5, 4, 6 }) do
                    local icon = r[k]
                    if type(icon) == "number" and icon > 0 then return icon end
                    if type(icon) == "string" and icon ~= "" and icon:find("\\") then return icon end
                end
            end
        end
        return nil
    end

    local numTabs = GetNumTabs()

    -- Retail / modern: prefer specialization icon (same as player frame spec texture).
    if numTabs == 0 then
        return specIconFromSpecialization()
    end

    if not _G.GetTalentTabInfo then
        return specIconFromSpecialization()
    end

    local tabPoints = {}
    local maxN = math.max(3, numTabs)
    for tab = 1, maxN do
        local s = 0
        local tree = points[tab]
        if type(tree) == "table" then
            for _, rank in pairs(tree) do
                s = s + (tonumber(rank) or 0)
            end
        end
        tabPoints[tab] = s
    end

    local total = 0
    local maxPoints = 0
    local bestTab = nil
    for tab = 1, math.min(3, maxN) do
        local p = tabPoints[tab] or 0
        total = total + p
        if p > maxPoints then
            maxPoints = p
            bestTab = tab
        end
    end
    if total <= 0 or not bestTab then
        return specIconFromSpecialization()
    end

    local low = math.min(tabPoints[1] or 0, tabPoints[2] or 0, tabPoints[3] or 0)
    local high = maxPoints
    local sorted = { tabPoints[1] or 0, tabPoints[2] or 0, tabPoints[3] or 0 }
    table.sort(sorted)
    local midPoints = sorted[2]

    local function tabIcon(tab)
        if not tab then return nil end
        local savedGroup = snapshot.group
        local calls = {
            function() return pcall(_G.GetTalentTabInfo, tab) end,
        }
        if Compat.GetActiveGroup then
            local g = (type(savedGroup) == "number" and savedGroup >= 1) and savedGroup or Compat.GetActiveGroup()
            calls[#calls + 1] = function()
                return pcall(_G.GetTalentTabInfo, tab, false, false, g)
            end
        end
        local function looksLikeTexturePath(s)
            return type(s) == "string" and s ~= "" and (s:find("\\") or s:find("^Interface"))
        end
        for _, call in ipairs(calls) do
            local r = { call() }
            if r[1] then
                -- Match FluxUnitFrames_GetSpecIconFromTalentTabs: primary texture is select(4, GetTalentTabInfo(...))
                -- With pcall: r[5] = 4th API return; r[3] is often the Classic tab icon (2nd return).
                for _, k in ipairs({ 5, 3, 4, 6 }) do
                    local icon = r[k]
                    if looksLikeTexturePath(icon) then return icon end
                    if type(icon) == "number" and icon > 0 then
                        -- Small values are usually points spent in the wrong slot, not file IDs.
                        if icon > 256 then return icon end
                    end
                end
            end
        end
        return nil
    end

    -- Same inequality as UnitFrames GetSpecIconFromTalentTabs: dominant tree when spread is "clear".
    if (3 * (midPoints - low)) < (2 * (high - low)) then
        local icon = tabIcon(bestTab)
        if icon then return icon end
    end
    return tabIcon(1) or tabIcon(bestTab) or specIconFromSpecialization()
end

-- -----------------------------------------------------------------------------
-- Capture
-- -----------------------------------------------------------------------------

--- Live build summary for "No profile" Respec row: same t1/t2/t3 format as saved profiles.
function Talents.LiveSummaryForUI()
    if UseRetail() then
        return R.TalentsRetail.LiveSummaryForUI()
    end
    local ag = (Compat.GetActiveGroup and Compat.GetActiveGroup()) or 1
    local pts = Talents.ReadGroup(ag)
    local totals = {}
    for tab, tree in pairs(pts or {}) do
        local s = 0
        for _, rank in pairs(tree) do s = s + (tonumber(rank) or 0) end
        totals[tab] = s
    end
    local t1, t2, t3 = totals[1] or 0, totals[2] or 0, totals[3] or 0
    local text = string.format("%d/%d/%d", t1, t2, t3)
    local n = (Compat.GetNumGroups and Compat.GetNumGroups()) or 1
    local tag = (n > 1) and ("[Spec " .. tostring(ag) .. "]") or "[live]"
    local specIcon = Talents.SpecIconFromSnapshot({ points = pts, class = select(2, UnitClass("player")) })
    if (not specIcon or specIcon == "" or specIcon == 0) and _G.FluxUnitFrames_GetPlayerSpecIcon then
        specIcon = _G.FluxUnitFrames_GetPlayerSpecIcon()
    end
    return text, tag, specIcon
end

--- Switch to the other talent group when dual spec is available (secure click path).
function Talents.ToggleDualSpecGroup()
    if UseRetail() then
        return R.TalentsRetail.ToggleDualSpecGroup()
    end
    local n = Compat.GetNumGroups and Compat.GetNumGroups() or 1
    if n < 2 then return false end
    local ag = (Compat.GetActiveGroup and Compat.GetActiveGroup()) or 1
    local other = (ag == 1) and 2 or 1
    return Compat.SetActiveGroup(other) and true or false
end

function Talents.Capture()
    if UseRetail() then
        return R.TalentsRetail.Capture()
    end
    local _, class = UnitClass("player")
    local group = Compat.GetActiveGroup()
    local snap = {
        class = class,
        group = group,
        points = Talents.ReadGroup(group),
    }
    -- Persist spec icon for Respec UI (must match saved points, not live player frame spec after dual-spec swap).
    snap.specIcon = Talents.SpecIconFromSnapshot(snap)
    if (not snap.specIcon or snap.specIcon == "" or snap.specIcon == 0) and _G.FluxUnitFrames_GetPlayerSpecIcon then
        snap.specIcon = _G.FluxUnitFrames_GetPlayerSpecIcon()
    end
    return snap
end

-- -----------------------------------------------------------------------------
-- Compare
-- -----------------------------------------------------------------------------

--- Are the ranks equal?
local function RanksEqual(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for tab, tree in pairs(a) do
        local other = b[tab]
        if type(other) ~= "table" then return false end
        for idx, rank in pairs(tree) do
            if (other[idx] or 0) ~= (rank or 0) then return false end
        end
        for idx, rank in pairs(other) do
            if (tree[idx] or 0) ~= (rank or 0) then return false end
        end
    end
    for tab in pairs(b) do
        if not a[tab] then return false end
    end
    return true
end

--- Does the snapshot match the given group?
function Talents.Matches(snapshot, groupIndex)
    if UseRetail() then
        return R.TalentsRetail.Matches(snapshot)
    end
    if type(snapshot) ~= "table" or type(snapshot.points) ~= "table" then
        return false
    end
    local _, class = UnitClass("player")
    if snapshot.class and class and snapshot.class ~= class then
        return false
    end
    local current = Talents.ReadGroup(groupIndex or Compat.GetActiveGroup())
    return RanksEqual(snapshot.points, current)
end

--- True when applying the snapshot would initiate a dual-spec switch (SetActiveGroup to a different
--- group that already matches the profile). Used by UI to skip auto-engrave while a spec dialog is pending.
function Talents.WouldSwitchSpec(snapshot)
    if UseRetail() then
        return R.TalentsRetail.WouldSwitchSpec(snapshot)
    end
    if type(snapshot) ~= "table" or type(snapshot.points) ~= "table" then
        return false
    end
    local active = (Compat and Compat.GetActiveGroup and Compat.GetActiveGroup()) or 1
    if Talents.Matches(snapshot, active) then
        return false
    end
    local match = Talents.FindMatchingGroupIndex(snapshot)
    return match ~= nil and match ~= active
end

--- First talent group index (1..n) whose build equals the snapshot, or nil if none.
--- Used for dual spec: detect when the inactive spec already matches the profile.
function Talents.FindMatchingGroupIndex(snapshot)
    if UseRetail() then
        return R.TalentsRetail.FindMatchingGroupIndex(snapshot)
    end
    if type(snapshot) ~= "table" or type(snapshot.points) ~= "table" then
        return nil
    end
    local _, class = UnitClass("player")
    if snapshot.class and class and snapshot.class ~= class then
        return nil
    end
    local n = Compat.GetNumGroups()
    if type(n) ~= "number" or n < 1 then
        return nil
    end
    for g = 1, n do
        if Talents.Matches(snapshot, g) then
            return g
        end
    end
    return nil
end

-- -----------------------------------------------------------------------------
-- Points needed
-- -----------------------------------------------------------------------------

local function CountDelta(currentPts, wantPts)
    local added, removed = 0, 0
    for tab, tree in pairs(wantPts) do
        local cur = (currentPts or {})[tab] or {}
        for idx, want in pairs(tree) do
            local cr = cur[idx] or 0
            if want > cr then
                added = added + (want - cr)
            elseif cr > want then
                removed = removed + (cr - want)
            end
        end
    end
    return added, removed
end

--- Returns (added, removed) where `added` is points that need to be spent and
--- `removed` is points that must be un-learned somehow (requires trainer on
--- Classic Era, impossible without reset).
function Talents.ComputeDelta(snapshot)
    if type(snapshot) ~= "table" or type(snapshot.points) ~= "table" then
        return 0, 0
    end
    local current = Talents.ReadGroup(Compat.GetActiveGroup())
    return CountDelta(current, snapshot.points)
end

--- Same as ComputeDelta but for a specific saved talent group (no need to switch specs).
function Talents.ComputeDeltaForGroup(snapshot, groupIndex)
    if type(snapshot) ~= "table" or type(snapshot.points) ~= "table" then
        return 0, 0
    end
    local current = Talents.ReadGroup(groupIndex)
    return CountDelta(current, snapshot.points)
end

--- On Classic Era, true if the profile can be applied without a trainer reset
--- (exact match on some group, or a spend-only path: removed == 0 and points to add).
function Talents.CanApplyWithoutTrainerReset(snapshot)
    if UseRetail() then
        return true
    end
    if not Compat.NeedsTrainerReset() then
        return true
    end
    if type(snapshot) ~= "table" or type(snapshot.points) ~= "table" then
        return true
    end
    if Talents.FindMatchingGroupIndex(snapshot) then
        return true
    end
    local n = Compat.GetNumGroups()
    if type(n) ~= "number" or n < 1 then
        return false
    end
    for g = 1, n do
        local added, removed = Talents.ComputeDeltaForGroup(snapshot, g)
        if removed == 0 and added > 0 then
            return true
        end
    end
    return false
end

-- -----------------------------------------------------------------------------
-- Apply
-- -----------------------------------------------------------------------------

Talents._state = nil
Talents._watcher = nil
local learnDeferFrame -- reused for ScheduleLearnContinue when C_Timer is absent
local specSwitchDeferFrame -- reused for one-tick settle after SetActiveGroup
-- Invalidate in-flight Apply callbacks (parallel gear failure, Apply.Cancel, etc.)
local applyCancelGen = 0
local specSwitchAwaitFrame = nil
local specSwitchAwaitTimer = nil

local function CancelLearnWatchdog(state)
    if not state or not state._learnTimer then return end
    local t = state._learnTimer
    state._learnTimer = nil
    if type(t) == "table" and t.Cancel then
        pcall(function() t:Cancel() end)
    elseif learnDeferFrame and t == learnDeferFrame then
        t:Hide()
        t:SetScript("OnUpdate", nil)
    elseif type(t) == "table" and t.Hide then
        t:Hide()
        t:SetScript("OnUpdate", nil)
    end
end

local function ClearLearnLoopState()
    if Talents._state then
        CancelLearnWatchdog(Talents._state)
    end
    if Talents._watcher then
        Talents._watcher:UnregisterAllEvents()
        Talents._watcher:SetScript("OnEvent", nil)
        Talents._watcher = nil
    end
    Talents._state = nil
    Talents._onDone = nil
end

local function ClearSpecSwitchAwait()
    if specSwitchAwaitTimer then
        pcall(function() specSwitchAwaitTimer:Cancel() end)
        specSwitchAwaitTimer = nil
    end
    if specSwitchAwaitFrame then
        specSwitchAwaitFrame:UnregisterAllEvents()
        specSwitchAwaitFrame:SetScript("OnEvent", nil)
        specSwitchAwaitFrame = nil
    end
end

local function ClearSpecSwitchSettleDefer()
    if specSwitchDeferFrame then
        specSwitchDeferFrame:Hide()
        specSwitchDeferFrame:SetScript("OnUpdate", nil)
    end
end

--- Stop an in-progress talent apply without firing TALENTS_APPLIED (used when gear fails during parallel load).
function Talents.AbortApply()
    if UseRetail() and R.TalentsRetail.AbortApply then
        R.TalentsRetail.AbortApply()
        return
    end
    applyCancelGen = applyCancelGen + 1
    ClearLearnLoopState()
    ClearSpecSwitchAwait()
    ClearSpecSwitchSettleDefer()
end

local function Finish(ok, reason)
    local fn = Talents._onDone
    ClearLearnLoopState()
    -- _onDone is Apply's `done` (fires TALENTS_APPLIED + user callback); do not duplicate R.Fire here.
    if fn then
        pcall(fn, ok, reason)
    end
end

--- Deficits sorted by tier then tab/index so prerequisites are learned first (pairs() order is random).
local function CollectSortedDeficits(want, cur, groupIndex)
    local list = {}
    for tab, tree in pairs(want) do
        for index, targetRank in pairs(tree) do
            local have = (cur[tab] or {})[index] or 0
            local wantn = tonumber(targetRank) or 0
            if have < wantn then
                local _, _, tier = GetTalentInfoSafe(tab, index, false, false, groupIndex)
                tier = tonumber(tier) or 0
                list[#list + 1] = { tab = tab, index = index, tier = tier }
            end
        end
    end
    table.sort(list, function(a, b)
        if a.tier ~= b.tier then return a.tier < b.tier end
        if a.tab ~= b.tab then return a.tab < b.tab end
        return a.index < b.index
    end)
    return list
end

-- Talented (classic apply.lua) learns one point per CHARACTER_POINTS_CHANGED — never many in one frame.
-- Bursting hundreds of LearnTalent() in a single frame reliably triggers realm disconnects / action throttles.
local MAX_LEARN_OPS_PER_TICK = 1
-- Extra spacing when we defer via timer (event-driven retries already follow server round-trips).
local LEARN_DEFER_SECONDS = 0.06

-- Forward-declared so ScheduleLearnContinue’s timer/OnUpdate closures capture the local (not a nil global).
local TryLearnNextPoint

local function ScheduleLearnContinue(state)
    CancelLearnWatchdog(state)
    if _G.C_Timer and _G.C_Timer.After then
        state._learnTimer = _G.C_Timer.After(LEARN_DEFER_SECONDS, function()
            if not Talents._state or Talents._state ~= state then return end
            state._learnTimer = nil
            TryLearnNextPoint()
        end)
        return
    end
    if not learnDeferFrame then
        learnDeferFrame = CreateFrame("Frame")
    end
    learnDeferFrame:Hide()
    state._learnTimer = learnDeferFrame
    local deferUntil = (GetTime and GetTime() or 0) + LEARN_DEFER_SECONDS
    learnDeferFrame:SetScript("OnUpdate", function(self)
        if (GetTime and GetTime() or 0) < deferUntil then
            return
        end
        self:SetScript("OnUpdate", nil)
        self:Hide()
        if Talents._state ~= state then
            state._learnTimer = nil
            return
        end
        state._learnTimer = nil
        TryLearnNextPoint()
    end)
    learnDeferFrame:Show()
end

--- Sync optimistic state with the game API after talent/spell events.
-- Do not infer "failed learn" from rank stalls here: PLAYER_TALENT_UPDATE and CHARACTER_POINTS_CHANGED
-- often fire many times (e.g. each spell rank for Pyroblast) before GetTalentInfo catches up, which used to
-- trip a per-event fail counter and abort with LEARN_ERROR despite successful learns.
local function ResyncFromAPI(state)
    if not state then return end
    local group = Compat.GetActiveGroup()
    state.localRanks = Talents.ReadGroup(group)
    state.localPoints = UnitCharacterPoints and UnitCharacterPoints("player") or 0
end

TryLearnNextPoint = function()
    local state = Talents._state
    if not state then return end
    if not _G.LearnTalent then
        Finish(false, "NO_API")
        return
    end

    local group = Compat.GetActiveGroup()
    local want = state.snapshot.points

    local ops = 0
    while ops < MAX_LEARN_OPS_PER_TICK do
        local deficits = CollectSortedDeficits(want, state.localRanks, group)
        if #deficits == 0 then
            -- Optimistic state says done; verify with a real API read. If still deficits, keep bursting.
            local realRanks = Talents.ReadGroup(group)
            local realDeficits = CollectSortedDeficits(want, realRanks, group)
            if #realDeficits == 0 then
                Finish(true, "DONE")
                return
            end
            -- Optimistic was too optimistic; sync and continue.
            state.localRanks = realRanks
            state.localPoints = UnitCharacterPoints and UnitCharacterPoints("player") or 0
        else
            local d = deficits[1]
            local targetRank = tonumber((want[d.tab] or {})[d.index]) or 0
            local have = (state.localRanks[d.tab] or {})[d.index] or 0

            if state.localPoints <= 0 then
                -- No points optimistically; confirm with API before giving up.
                local realPoints = UnitCharacterPoints and UnitCharacterPoints("player") or 0
                if realPoints <= 0 then
                    Finish(false, "NO_POINTS")
                    return
                end
                state.localPoints = realPoints
            end

            -- Burst: fire LearnTalent for every remaining rank optimistically; do not read back each step.
            while have < targetRank and state.localPoints > 0 and ops < MAX_LEARN_OPS_PER_TICK do
                local ok = pcall(_G.LearnTalent, d.tab, d.index)
                if not ok then
                    Finish(false, "LEARN_ERROR")
                    return
                end
                state.localRanks[d.tab] = state.localRanks[d.tab] or {}
                state.localRanks[d.tab][d.index] = have + 1
                have = have + 1
                state.localPoints = state.localPoints - 1
                ops = ops + 1
            end

            if have < targetRank then
                -- Hit op cap or out of optimistic points mid-node: continue next frame.
                ScheduleLearnContinue(state)
                return
            end
            -- Node filled optimistically; loop for next deficit in the same tick.
            ops = ops + 1
        end
    end

    -- Per-tick cap hit; continue next frame.
    ScheduleLearnContinue(state)
end

local function StartLearnLoop(snapshot, onDone)
    local group = Compat.GetActiveGroup()
    Talents._state = {
        snapshot = snapshot,
        _learnTimer = nil,
        localRanks = Talents.ReadGroup(group),
        localPoints = UnitCharacterPoints and UnitCharacterPoints("player") or 0,
    }
    Talents._onDone = onDone
    if not Talents._watcher then
        local f = CreateFrame("Frame")
        f:RegisterEvent("CHARACTER_POINTS_CHANGED")
        f:RegisterEvent("PLAYER_TALENT_UPDATE")
        -- Do not CancelLearnWatchdog here — avoids cancel/reschedule churn with ScheduleLearnContinue.
        f:SetScript("OnEvent", function()
            local state = Talents._state
            if not state then return end
            ResyncFromAPI(state)
            TryLearnNextPoint()
        end)
        Talents._watcher = f
    end
    TryLearnNextPoint()
end

--- One tick after dual-spec switch so GetActiveGroup/ReadGroup match the new spec, then match or learn.
local function RunAfterSpecSwitchSettles(fn)
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, fn)
        return
    end
    if not specSwitchDeferFrame then
        specSwitchDeferFrame = CreateFrame("Frame")
    end
    specSwitchDeferFrame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        self:Hide()
        fn()
    end)
    specSwitchDeferFrame:Show()
end

--- Resume Apply after spec switch: finish if already matched, else StartLearnLoop ASAP (same checks as path 3).
local function ContinueTalentApplyAfterSpecSwitch(snapshot, done)
    local active = Compat.GetActiveGroup()
    if Talents.Matches(snapshot, active) then
        done(true, "SPEC_SWITCHED")
        return
    end
    local added, removed = Talents.ComputeDelta(snapshot)
    if removed > 0 and Compat.NeedsTrainerReset() then
        done(false, "NEEDS_TRAINER")
        return
    end
    if added == 0 and removed == 0 then
        -- No delta but tree not matching snapshot yet (rare); learn loop re-reads API and completes or errors.
        StartLearnLoop(snapshot, done)
        return
    end
    local available = UnitCharacterPoints and UnitCharacterPoints("player") or 0
    if added > available then
        if Compat.NeedsTrainerReset() then
            done(false, "NEEDS_TRAINER")
        else
            done(false, "NO_POINTS")
        end
        return
    end
    StartLearnLoop(snapshot, done)
end

--- After SetActiveGroup + switch event: continue as soon as the client reports the right active group.
--- No extra frame wait when GetActiveGroup already matches (faster SPEC_SWITCHED or StartLearnLoop → runes).
--- If the group is not updated yet, defer one tick and retry (same as before).
local function ResumeAfterSpecSwitch(wantG, myGen, snapshot, done)
    local function proceed()
        if myGen ~= applyCancelGen then return end
        if tonumber(Compat.GetActiveGroup()) ~= tonumber(wantG) then
            done(false, "SPEC_SWITCH_CANCELLED")
            return
        end
        ContinueTalentApplyAfterSpecSwitch(snapshot, done)
    end

    local ag = tonumber(Compat.GetActiveGroup())
    local wg = tonumber(wantG)
    if ag == wg then
        proceed()
    else
        RunAfterSpecSwitchSettles(proceed)
    end
end

--- Profile load / menu click may call SetActiveGroup before the client is ready; retry next tick if still wrong spec.
local function NudgeDualSpecSwitchIfNeeded(wantG, myGen)
    if not wantG or not myGen then return end
    local wg = tonumber(wantG)
    local function tryNudge()
        if myGen ~= applyCancelGen then return end
        if tonumber(Compat.GetActiveGroup()) == wg then
            return
        end
        Compat.SetActiveGroup(wantG)
    end
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, tryNudge)
        _G.C_Timer.After(0.12, tryNudge)
    else
        RunAfterSpecSwitchSettles(tryNudge)
    end
end

local function AwaitSpecSwitch(onDone)
    ClearSpecSwitchAwait()
    local f = CreateFrame("Frame")
    specSwitchAwaitFrame = f
    f:RegisterEvent("PLAYER_TALENT_UPDATE")
    f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    local settled = false
    local function resolve(ok, reason)
        if settled then return end
        settled = true
        if specSwitchAwaitTimer then
            pcall(function() specSwitchAwaitTimer:Cancel() end)
            specSwitchAwaitTimer = nil
        end
        if specSwitchAwaitFrame then
            specSwitchAwaitFrame:UnregisterAllEvents()
            specSwitchAwaitFrame:SetScript("OnEvent", nil)
            specSwitchAwaitFrame = nil
        end
        if onDone then pcall(onDone, ok, reason) end
    end
    f:SetScript("OnEvent", function()
        resolve(true, "SPEC_SWITCHED")
    end)
    if C_Timer and C_Timer.After then
        specSwitchAwaitTimer = C_Timer.After(5, function()
            resolve(false, "SPEC_SWITCH_TIMEOUT")
        end)
    end
end

--- Inactive talent group that can reach the snapshot by spending only (e.g. blank off-spec). Prefer non-active.
local function FindSpendOnlyInactiveGroup(snapshot, active, numGroups)
    for g = 1, numGroups do
        if g ~= active and not Talents.Matches(snapshot, g) then
            local added, removed = Talents.ComputeDeltaForGroup(snapshot, g)
            if removed == 0 and added > 0 then
                return g
            end
        end
    end
    return nil
end

--- Switch to the inactive dual-spec group when it already matches `snapshot` (no point spend).
--- onDone(ok, reason): "NOOP" | "SPEC_SWITCHED" | "NO_SKIP" | "IN_COMBAT" | "SPEC_SWITCH_*" | "WRONG_CLASS"
function Talents.SwitchToMatchingGroup(snapshot, onDone)
    if UseRetail() then
        if onDone then onDone(true, "NOOP") end
        return
    end
    local function finish(ok, reason)
        if onDone then pcall(onDone, ok, reason) end
    end
    if type(snapshot) ~= "table" or type(snapshot.points) ~= "table" then
        finish(true, "NOOP")
        return
    end
    local _, class = UnitClass("player")
    if snapshot.class and snapshot.class ~= class then
        finish(false, "WRONG_CLASS")
        return
    end
    if InCombatLockdown() then
        finish(false, "IN_COMBAT")
        return
    end
    local active = Compat.GetActiveGroup()
    if Talents.Matches(snapshot, active) then
        finish(true, "NOOP")
        return
    end
    local numGroups = Compat.GetNumGroups()
    if type(numGroups) ~= "number" or numGroups < 2 then
        finish(true, "NO_SKIP")
        return
    end
    local matchG = Talents.FindMatchingGroupIndex(snapshot)
    if not matchG or matchG == active or matchG < 1 or matchG > numGroups then
        finish(true, "NO_SKIP")
        return
    end
    if not Compat.SetActiveGroup(matchG) then
        finish(false, "SPEC_SWITCH_FAILED")
        return
    end
    local wantG = matchG
    AwaitSpecSwitch(function(ok)
        if not ok then
            finish(false, "SPEC_SWITCH_TIMEOUT")
            return
        end
        RunAfterSpecSwitchSettles(function()
            if tonumber(Compat.GetActiveGroup()) == tonumber(wantG) then
                finish(true, "SPEC_SWITCHED")
            else
                finish(false, "SPEC_SWITCH_CANCELLED")
            end
        end)
    end)
end

--- Apply a talent snapshot. Order when dual spec is involved: any required `SetActiveGroup` + wait for
--- `ACTIVE_TALENT_GROUP_CHANGED` / `PLAYER_TALENT_UPDATE` happens before `StartLearnLoop` (point spend).
--- onDone(ok, reason) is called when done. reason is one of:
---   "NOOP" | "SPEC_SWITCHED" | "DONE" | "NEEDS_TRAINER" | "NO_POINTS" |
---   "WRONG_CLASS" | "IN_COMBAT" | "LEARN_ERROR" | "SPEC_SWITCH_TIMEOUT" | "SPEC_SWITCH_CANCELLED"
function Talents.Apply(snapshot, onDone)
    if UseRetail() then
        return R.TalentsRetail.Apply(snapshot, onDone)
    end
    applyCancelGen = applyCancelGen + 1
    local myGen = applyCancelGen

    local function done(ok, reason)
        if myGen ~= applyCancelGen then return end
        -- Invoke Apply pipeline callback first so listeners to TALENTS_APPLIED see updated Apply._state.
        if onDone then pcall(onDone, ok, reason) end
        R.Fire("TALENTS_APPLIED", ok, reason)
    end

    if type(snapshot) ~= "table" or type(snapshot.points) ~= "table" then
        done(true, "NOOP")
        return
    end

    local _, class = UnitClass("player")
    if snapshot.class and snapshot.class ~= class then
        R.Warn(("Talent template is for %s, not your class (%s)."):format(snapshot.class, class))
        done(false, "WRONG_CLASS")
        return
    end

    if InCombatLockdown() then
        R.Warn("Can't change talents in combat.")
        done(false, "IN_COMBAT")
        return
    end

    -- 1) Active spec already matches?
    local active = Compat.GetActiveGroup()
    if Talents.Matches(snapshot, active) then
        done(true, "NOOP")
        return
    end

    -- 2) Dual spec: profile matches the other saved build — switch groups (no trainer / no point spend).
    local numGroups = Compat.GetNumGroups()
    if type(numGroups) == "number" and numGroups >= 2 then
        local matchG = Talents.FindMatchingGroupIndex(snapshot)
        if matchG and matchG ~= active and matchG >= 1 and matchG <= numGroups then
            if Compat.SetActiveGroup(matchG) then
                local wantG = matchG
                AwaitSpecSwitch(function(ok)
                    if not ok then
                        done(false, "SPEC_SWITCH_TIMEOUT")
                        return
                    end
                    ResumeAfterSpecSwitch(wantG, myGen, snapshot, done)
                end)
                return
            end
        end
    end

    -- 2b) Dual spec: switch to an inactive group that only needs points spent (no unlearns), then learn.
    if type(numGroups) == "number" and numGroups >= 2 then
        local spendG = FindSpendOnlyInactiveGroup(snapshot, active, numGroups)
        if spendG and Compat.SetActiveGroup(spendG) then
            local wantG = spendG
            NudgeDualSpecSwitchIfNeeded(wantG, myGen)
            AwaitSpecSwitch(function(ok)
                if not ok then
                    done(false, "SPEC_SWITCH_TIMEOUT")
                    return
                end
                ResumeAfterSpecSwitch(wantG, myGen, snapshot, done)
            end)
            return
        end
    end

    -- 3) Learn points one-by-one.
    local added, removed = Talents.ComputeDelta(snapshot)
    if removed > 0 and Compat.NeedsTrainerReset() then
        -- Classic Era / SoD: can't un-spend points without trainer reset.
        done(false, "NEEDS_TRAINER")
        return
    end
    if added == 0 and removed == 0 then
        done(true, "NOOP")
        return
    end
    local available = UnitCharacterPoints and UnitCharacterPoints("player") or 0
    if added > available then
        if Compat.NeedsTrainerReset() then
            done(false, "NEEDS_TRAINER")
        else
            done(false, "NO_POINTS")
        end
        return
    end

    StartLearnLoop(snapshot, done)
end

-- -----------------------------------------------------------------------------
-- Trainer: auto-select "Unlearn Talents" gossip when the active profile needs a reset
-- (Classic Era / SoD). Optional: player pre-authorizes payment in the NEED_TRAINER popup;
-- Pre-authorized: gossip uses SelectOption*(..., true) to skip gold GOSSIP_CONFIRM when the client allows;
-- StaticPopup hook still auto-accepts GOSSIP_CONFIRM + CONFIRM_TALENT_WIPE as a fallback.
-- -----------------------------------------------------------------------------

Talents._trainerUnlearnArmed = false
local _lastTrainerUnlearnGossipAt = 0
Talents._cachedUnlearnCostCopper = nil
Talents._preauthorizedTrainerPay = false
Talents._lastTalentGossipMoneyAcceptAt = 0

function Talents.RememberUnlearnCost(copper)
    if UseRetail() then return end
    if type(copper) ~= "number" or copper <= 0 then
        return
    end
    Talents._cachedUnlearnCostCopper = copper
    if R.RememberTrainerUnlearnCostCopper then
        R.RememberTrainerUnlearnCostCopper(copper)
    end
end

function Talents.SetTrainerPayPreauthorized(yes)
    Talents._preauthorizedTrainerPay = yes and true or false
end

function Talents.IsTrainerPayPreauthorized()
    return Talents._preauthorizedTrainerPay == true
end

function Talents.ClearTrainerPayPreauth()
    Talents._preauthorizedTrainerPay = false
end

--- Best-effort copper cost for \"Unlearn Talents\": session cache, saved vars, API globals, gossip scan.
function Talents.GetTrainerUnlearnCostCopper()
    if UseRetail() then return nil end
    local cached = Talents._cachedUnlearnCostCopper
    if type(cached) == "number" and cached > 0 then
        return cached
    end
    if R.GetPersistedTrainerUnlearnCostCopper then
        local p = R.GetPersistedTrainerUnlearnCostCopper()
        if type(p) == "number" and p > 0 then
            Talents._cachedUnlearnCostCopper = p
            return p
        end
    end
    for _, gname in ipairs({ "GetTalentResetCost", "GetTalentPruningCost" }) do
        local fn = _G[gname]
        if type(fn) == "function" then
            local ok, v = pcall(fn)
            if ok and type(v) == "number" and v > 0 then
                Talents.RememberUnlearnCost(v)
                return v
            end
        end
    end
    return nil
end

--- Message body for GENERIC_CONFIRMATION (FluxRespec_Apply ShowNeedTrainerDialog) — plain text, no stray % for format.
function Talents.BuildNeedTrainerPopupText()
    if UseRetail() then return "" end
    local cost = Talents.GetTrainerUnlearnCostCopper()
    local fee
    if cost and cost > 0 and _G.GetMoneyString then
        fee = "\nFee: " .. GetMoneyString(cost) .. "."
    elseif cost and cost > 0 then
        fee = string.format("\nFee: %dc.", cost)
    else
        fee = "\nFee: unknown until the trainer shows it once — then FluxRespec remembers it."
    end
    local armed = ""
    if Talents.IsTrainerPayPreauthorized() then
        armed = "\n\n|cffffcc00Auto-confirm armed.|r"
    end
    local sod = (Compat.IsSoD and Compat.IsSoD()) and "\nSoD: engrave queue kept — use Load for runes until you reset talents." or ""
    return "Talents need a class trainer reset (Classic / SoD). Open a trainer: FluxRespec picks Unlearn Talents gossip."
        .. fee
        .. "\n\n|cff88ff88Auto-confirm:|r accept gold + wipe dialogs at the trainer.\n|cffaaaaaaManual:|r you click those prompts."
        .. "\nThen Load again."
        .. sod
        .. armed
end

--- Update automatic Unlearn Talents selection for the next trainer interaction.
function Talents.SyncTrainerUnlearnQueueForActiveProfile()
    Talents._trainerUnlearnArmed = false
    if UseRetail() then
        Talents.ClearTrainerPayPreauth()
        return
    end
    if not Compat.NeedsTrainerReset() then
        Talents.ClearTrainerPayPreauth()
        return
    end
    local name = R.GetActiveName and R.GetActiveName()
    if not name or name == "" then
        return
    end
    local profile = R.GetProfile and R.GetProfile(name)
    if not profile or type(profile.talents) ~= "table" then
        return
    end
    if Talents.CanApplyWithoutTrainerReset(profile.talents) then
        Talents.ClearTrainerPayPreauth()
        return
    end
    Talents._trainerUnlearnArmed = true
end

local function GossipOptionLooksLikeUnlearnTalents(label)
    if type(label) ~= "string" or label == "" then
        return false
    end
    local lower = string.lower(label)
    if not string.find(lower, "talent", 1, true) then
        return false
    end
    if string.find(lower, "unlearn", 1, true) then
        return true
    end
    if string.find(lower, "forget", 1, true) then
        return true
    end
    if string.find(lower, "wipe", 1, true) then
        return true
    end
    return false
end

--- Second gossip page after \"I wish to unlearn…\" often omits the word \"talent\" (e.g. \"Yes, I do.\").
local function GossipOptionLooksLikeUnlearnFollowUp(label)
    if type(label) ~= "string" or label == "" then
        return false
    end
    if GossipOptionLooksLikeUnlearnTalents(label) then
        return true
    end
    local lower = string.lower(label)
    if string.find(lower, "goodbye", 1, true) then
        return false
    end
    if string.find(lower, "nevermind", 1, true) or string.find(lower, "never mind", 1, true) then
        return false
    end
    if string.find(lower, "train", 1, true) and not string.find(lower, "unlearn", 1, true) then
        return false
    end
    -- Affirmations seen on follow-up gossip before the gold popup
    if string.find(lower, "yes", 1, true) then
        return true
    end
    if string.find(lower, "i do", 1, true) then
        return true
    end
    if string.find(lower, "understand", 1, true) then
        return true
    end
    if string.find(lower, "wish to", 1, true) and string.find(lower, "unlearn", 1, true) then
        return true
    end
    if string.find(lower, "pay", 1, true) and string.find(lower, "cost", 1, true) then
        return true
    end
    return false
end

--- After the first unlearn gossip pick, a second GOSSIP_SHOW can fire within ~1s; the old 1.5s debounce blocked it.
Talents._unlearnGossipChainUntil = nil

local function FindTrainerUnlearnGossipOption(opts, allowFollowUp)
    for _, o in ipairs(opts) do
        local label = o.name
        if type(label) == "string" and GossipOptionLooksLikeUnlearnTalents(label) then
            return o.orderIndex, label, "primary", o.gossipOptionID
        end
    end
    if allowFollowUp then
        for _, o in ipairs(opts) do
            local label = o.name
            if type(label) == "string" and GossipOptionLooksLikeUnlearnFollowUp(label) then
                return o.orderIndex, label, "followup", o.gossipOptionID
            end
        end
    end
    return nil, nil, nil, nil
end

--- While gossip is open, try to learn unlearn fee from option payload or \"12g\"-style text (best-effort).
local function TryCacheUnlearnCostFromGossipOptions()
    local CG = _G.C_GossipInfo
    if not CG or not CG.GetOptions then
        return
    end
    local ok, opts = pcall(CG.GetOptions)
    if not ok or type(opts) ~= "table" then
        return
    end
    for _, o in ipairs(opts) do
        local label = o.name
        if type(label) == "string" and GossipOptionLooksLikeUnlearnTalents(label) then
            for k, v in pairs(o) do
                if type(k) == "string" and k ~= "name" and type(v) == "number" and v >= 10000 and v <= 500000000 then
                    Talents.RememberUnlearnCost(v)
                    return
                end
            end
            local gold = string.match(label, "(%d+)%s*[gG]")
            if gold then
                local ng = tonumber(gold)
                if ng and ng > 0 and ng <= 50000 then
                    Talents.RememberUnlearnCost(ng * 10000)
                    return
                end
            end
        end
    end
end

local function TryAutoSelectTrainerUnlearnTalents()
    if not Talents._trainerUnlearnArmed then
        return
    end
    if not Compat.NeedsTrainerReset() then
        return
    end
    if InCombatLockdown() then
        return
    end
    Talents.SyncTrainerUnlearnQueueForActiveProfile()
    if not Talents._trainerUnlearnArmed then
        return
    end
    local now = (GetTime and GetTime()) or 0
    local inChain = type(Talents._unlearnGossipChainUntil) == "number" and now <= Talents._unlearnGossipChainUntil
    local gap = now - _lastTrainerUnlearnGossipAt
    -- Same-frame / accidental double-fire guard (scheduled retries use 0.25s+)
    if gap < 0.15 then
        return
    end
    -- Cooldown between unrelated gossip opens; allow quick second pick in unlearn chain only
    if gap < 1.5 and not inChain then
        return
    end
    local CG = _G.C_GossipInfo
    if not CG or not CG.GetOptions or not CG.SelectOptionByIndex then
        return
    end
    local ok, opts = pcall(CG.GetOptions)
    if not ok or type(opts) ~= "table" then
        return
    end
    local orderIndex, label, kind, gossipOptionID = FindTrainerUnlearnGossipOption(opts, inChain)
    if type(orderIndex) ~= "number" or type(label) ~= "string" then
        return
    end
    if Talents.IsTrainerPayPreauthorized() then
        if type(gossipOptionID) == "number" and gossipOptionID > 0 and CG.SelectOption then
            pcall(CG.SelectOption, gossipOptionID, nil, true)
        else
            pcall(CG.SelectOptionByIndex, orderIndex, nil, true)
        end
    else
        pcall(CG.SelectOptionByIndex, orderIndex)
    end
    _lastTrainerUnlearnGossipAt = now
    if kind == "primary" then
        Talents._unlearnGossipChainUntil = now + 12
        -- Second menu sometimes appears a tick later; GOSSIP_SHOW already runs @0, these catch stragglers.
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0.25, TryAutoSelectTrainerUnlearnTalents)
            _G.C_Timer.After(0.55, TryAutoSelectTrainerUnlearnTalents)
        end
    else
        Talents._unlearnGossipChainUntil = nil
    end
    if R.Print then
        if Talents.IsTrainerPayPreauthorized() then
            R.Print(
                ('FluxRespec: chose "%s" (confirmed gossip — gold popup may be skipped).'):format(label)
            )
        else
            R.Print(
                ('FluxRespec: chose trainer option "%s" — confirm the gold dialog at the trainer, or use the Load popup "Auto-confirm payment".'):format(
                    label
                )
            )
        end
    end
end

--- While CAMP/QUIT is up, Blizzard's StaticPopup_Show can cancel those dialogs via OnCancel → CancelLogout(),
--- which must not run from addon-initiated paths (ADDON_ACTION_BLOCKED).
local function FluxRespecStaticPopupLogoutFlowVisible()
    local vis = _G.StaticPopup_Visible
    if type(vis) ~= "function" then
        return false
    end
    if vis("CAMP") or vis("QUIT") or vis("PLUNDERSTORM_LEAVE") then
        return true
    end
    return false
end

local function StaticPopupDialogBodyText(dialog)
    if not dialog then
        return ""
    end
    local fs = dialog.GetTextFontString and dialog:GetTextFontString()
    if fs and fs.GetText then
        return fs:GetText() or ""
    end
    return ""
end

local function TextLooksLikeTalentMoneyConfirmation(s)
    if type(s) ~= "string" or s == "" then
        return false
    end
    local lower = string.lower(s)
    if string.find(lower, "talent", 1, true) then
        return true
    end
    if string.find(lower, "unlearn", 1, true) then
        return true
    end
    if string.find(lower, "forget", 1, true) then
        return true
    end
    return false
end

local function CaptureTrainerCostFromStaticPopup(which)
    if Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    if FluxRespecStaticPopupLogoutFlowVisible() then
        return
    end
    if which ~= "GOSSIP_CONFIRM" and which ~= "CONFIRM_TALENT_WIPE" then
        return
    end
    local find = _G.StaticPopup_FindVisible
    if type(find) ~= "function" then
        return
    end
    local dialog = find(which)
    if not dialog then
        return
    end
    local mf = dialog.MoneyFrame
    if mf and type(mf.staticMoney) == "number" and mf.staticMoney > 0 then
        Talents.RememberUnlearnCost(mf.staticMoney)
    end
end

local function TryAutoAcceptTrainerStaticPopups(which)
    if Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    if FluxRespecStaticPopupLogoutFlowVisible() then
        return
    end
    if which ~= "GOSSIP_CONFIRM" and which ~= "CONFIRM_TALENT_WIPE" then
        return
    end
    if not Talents.IsTrainerPayPreauthorized() then
        return
    end
    if not Talents._trainerUnlearnArmed then
        return
    end
    if not Compat.NeedsTrainerReset() then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local now = (GetTime and GetTime()) or 0
    if which == "CONFIRM_TALENT_WIPE" then
        local tMoney = Talents._lastTalentGossipMoneyAcceptAt or 0
        local recent = (now - tMoney <= 60) or (now - _lastTrainerUnlearnGossipAt <= 60)
        if not recent then
            return
        end
    end
    local find = _G.StaticPopup_FindVisible
    if type(find) ~= "function" then
        return
    end
    local dialog = find(which)
    if not dialog or not dialog.IsShown or not dialog:IsShown() then
        return
    end
    if which == "GOSSIP_CONFIRM" then
        if not TextLooksLikeTalentMoneyConfirmation(StaticPopupDialogBodyText(dialog)) then
            return
        end
    end
    local info = _G.StaticPopupDialogs and _G.StaticPopupDialogs[which]
    if not info or type(info.OnAccept) ~= "function" then
        return
    end
    -- securecall avoids spreading addon taint from this post-hook into StaticPopup / panel flows.
    if _G.securecall then
        securecall(function()
            info.OnAccept(dialog, dialog.data)
        end)
    else
        info.OnAccept(dialog, dialog.data)
    end
    if which == "GOSSIP_CONFIRM" then
        Talents._lastTalentGossipMoneyAcceptAt = now
    end
end

if hooksecurefunc and _G.StaticPopup_Show then
    hooksecurefunc("StaticPopup_Show", function(which, _, _, _, _)
        if Compat.SecureUIPanelsBlockRespecWork() then
            return
        end
        if FluxRespecStaticPopupLogoutFlowVisible() then
            return
        end
        if which ~= "GOSSIP_CONFIRM" and which ~= "CONFIRM_TALENT_WIPE" then
            return
        end
        -- Post-hook: dialog is created; accept immediately so the gold / wipe frames barely appear when pre-authorized.
        TryAutoAcceptTrainerStaticPopups(which)
        local after = _G.C_Timer and _G.C_Timer.After
        if after then
            after(0, function()
                if FluxRespecStaticPopupLogoutFlowVisible() then
                    return
                end
                CaptureTrainerCostFromStaticPopup(which)
                TryAutoAcceptTrainerStaticPopups(which)
            end)
        else
            if not FluxRespecStaticPopupLogoutFlowVisible() then
                CaptureTrainerCostFromStaticPopup(which)
                TryAutoAcceptTrainerStaticPopups(which)
            end
        end
    end)
end

do
    local f = CreateFrame("Frame")
    f:RegisterEvent("GOSSIP_SHOW")
    f:RegisterEvent("GOSSIP_CLOSED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_TALENT_UPDATE")
    f:RegisterEvent("GOSSIP_CONFIRM")
    f:RegisterEvent("CONFIRM_TALENT_WIPE")
    f:SetScript("OnEvent", function(_, event, ...)
        if event == "GOSSIP_SHOW" then
            if _G.C_Timer and _G.C_Timer.After then
                _G.C_Timer.After(0, function()
                    if Compat.SecureUIPanelsBlockRespecWork() then
                        return
                    end
                    if FluxRespecStaticPopupLogoutFlowVisible() then
                        return
                    end
                    TryCacheUnlearnCostFromGossipOptions()
                    TryAutoSelectTrainerUnlearnTalents()
                end)
            else
                if not Compat.SecureUIPanelsBlockRespecWork() and not FluxRespecStaticPopupLogoutFlowVisible() then
                    TryCacheUnlearnCostFromGossipOptions()
                    TryAutoSelectTrainerUnlearnTalents()
                end
            end
        elseif event == "GOSSIP_CLOSED" then
            Talents._unlearnGossipChainUntil = nil
        elseif event == "GOSSIP_CONFIRM" then
            local _, _, a3 = ...
            if type(a3) == "number" and a3 > 0 then
                Talents.RememberUnlearnCost(a3)
            end
        elseif event == "CONFIRM_TALENT_WIPE" then
            local a1 = ...
            if type(a1) == "number" and a1 > 0 then
                Talents.RememberUnlearnCost(a1)
            end
        elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TALENT_UPDATE" then
            if event == "PLAYER_ENTERING_WORLD" and R.GetPersistedTrainerUnlearnCostCopper then
                local p = R.GetPersistedTrainerUnlearnCostCopper()
                if type(p) == "number" and p > 0 then
                    Talents._cachedUnlearnCostCopper = p
                end
            end
            Talents.SyncTrainerUnlearnQueueForActiveProfile()
        end
    end)
end

if R.On then
    R.On("ACTIVE_CHANGED", function()
        Talents.SyncTrainerUnlearnQueueForActiveProfile()
    end)
end

Talents.SyncTrainerUnlearnQueueForActiveProfile()

if R.GetPersistedTrainerUnlearnCostCopper then
    local p = R.GetPersistedTrainerUnlearnCostCopper()
    if type(p) == "number" and p > 0 then
        Talents._cachedUnlearnCostCopper = p
    end
end

R.Talents = Talents
