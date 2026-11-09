-- Production docking lifecycle with native/widget mocks, not WoW's secure VM.
-- Optional args: alternate backend source; pinned EditModeSystemTemplates.lua.
local source = arg[1] or "Battlezonemap/FluxBlizzardMeter.lua"
local nativePath = arg[2]
local arguments = arg; arg = { source, "--harness" }
local harness = assert(loadfile("tests/native_meter_ownership.lua"))(); arg = arguments
local checks, failures = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local function near(a, b) return type(a) == "number" and math.abs(a - b) < .00001 end
local nativeText
if nativePath then
    local f = assert(io.open(nativePath, "r")); nativeText = f:read("*a"); f:close()
end
local function nativeMethod(name)
    local start = assert(nativeText:find("function EditModeSystemMixin:" .. name .. "(", 1, true))
    local finish = nativeText:find("\nfunction ", start + 1, true) or (#nativeText + 1)
    return nativeText:sub(start, finish - 1)
end
local function boot(gamepad)
    local e, s = harness(gamepad)
    s.nativePhase, s.addonMetadata, s.nativeMetadata = false, 0, 0
    local dm = s.dm
    local function metadata()
        if s.nativePhase then s.nativeMetadata = s.nativeMetadata + 1
        else s.addonMetadata = s.addonMetadata + 1 end
    end
    local function after(object, method, ...)
        for _, fn in ipairs(s.hooks[object] and s.hooks[object][method] or {}) do fn(object, ...) end
    end
    local point, clear, scale = dm.SetPoint, dm.ClearAllPoints, dm.SetScale
    function dm:SetPointBase(...) point(self, ...); after(self, "SetPointBase", ...) end
    function dm:ClearAllPointsBase(...) clear(self, ...) end
    function dm:SetScaleBase(value) scale(self, value); after(self, "SetScaleBase", value) end
    function dm:GetScale() return self.scale end
    function dm:GetNumPoints() return #self.points end
    function dm:GetPoint(index) return table.unpack(self.points[index] or {}) end
    function dm:GetManagedFrameContainer() return nil end
    function dm:IsInDefaultPosition() return false end
    dm.ClearFrameSnap, dm.SetSnappedToFrame = metadata, metadata
    e.EditModeManagerFrame = { OnEditModeSystemAnchorChanged = metadata, UpdateActionBarLayout = metadata }
    e.EditModeUtil = { IsRightAnchoredActionBar = function() return false end,
        IsBottomAnchoredActionBar = function() return false end }
    e.EditModeSystemMixin = {}
    local mixin = e.EditModeSystemMixin
    if nativeText then
        local chunk = ""
        for _, name in ipairs({"SetPointOverride", "ClearAllPointsOverride", "SetScaleOverride", "ApplySystemAnchor"}) do
            chunk = chunk .. nativeMethod(name) .. "\n"
        end
        assert(load(chunk, "@pinned native EditMode geometry", "t", e))()
    else
        function mixin:SetPointOverride(...)
            self:SetPointBase(...); self:SetSnappedToFrame(); e.EditModeManagerFrame:OnEditModeSystemAnchorChanged()
        end
        function mixin:ClearAllPointsOverride() self:ClearAllPointsBase(); self:ClearFrameSnap() end
        function mixin:SetScaleOverride(value) self:SetScaleBase(value) end
        function mixin:ApplySystemAnchor()
            self:ClearAllPoints()
            local a = self.systemInfo.anchorInfo; local value = self:GetScale()
            self:SetPoint(a.point, a.relativeTo, a.relativePoint, a.offsetX / value, a.offsetY / value)
            e.EditModeManagerFrame:UpdateActionBarLayout(self)
        end
    end
    dm.SetPoint, dm.ClearAllPoints, dm.SetScale = mixin.SetPointOverride, mixin.ClearAllPointsOverride, mixin.SetScaleOverride
    local originals = { dm.SetPoint, dm.ClearAllPoints, dm.SetScale, dm.SetPointBase, dm.ClearAllPointsBase, dm.SetScaleBase }
    dm.systemInfo = { anchorInfo = { point = "TOPLEFT", relativeTo = e.UIParent,
        relativePoint = "TOPLEFT", offsetX = 800, offsetY = -500 } }
    function s.nativeRestore()
        s.nativePhase = true
        mixin.ApplySystemAnchor(dm)
        dm:SetSize(500, 360); dm:SetScale(1.2)
        if not gamepad then dm:SetParent(e.UIParent) end
        s.windows[2]:ClearAllPoints(); s.windows[2]:SetPoint("TOPLEFT", e.UIParent, "TOPLEFT", 900, -600)
        s.windows[2]:SetScale(.9)
        s.nativePhase = false
    end
    function s.rawEngineRestore()
        -- A modeled engine restoration deliberately bypasses Lua setter fields.
        dm.parent, dm.width, dm.height, dm.scale = e.UIParent, 600, 400, 1
        dm.points = {{"TOPLEFT", e.UIParent, "TOPLEFT", 500, -300}}
        s.windows[2].points = {{"TOPLEFT", e.UIParent, "TOPLEFT", 900, -600}}
    end
    function s.docked()
        local p = dm.points[1] or {}; local w = s.windows[2].points[1] or {}
        return dm:GetParent() == (gamepad and e.UIParent or s.host) and p[1] == "CENTER" and p[2] == s.host
            and near(dm.width, s.host.width / .8) and near(dm.height, s.host.height / .8)
            and near(dm.scale, gamepad and s.host.scale * .8 or .8)
            and #s.windows[2].points == 2 and w[1] == "TOPLEFT" and w[2] == dm and near(s.windows[2].scale, 1)
    end
    function s.methodsIntact()
        return originals[1] == dm.SetPoint and originals[2] == dm.ClearAllPoints and originals[3] == dm.SetScale
            and originals[4] == dm.SetPointBase and originals[5] == dm.ClearAllPointsBase and originals[6] == dm.SetScaleBase
    end
    local layout = { topSlots = {{ kind = "blizzard", damageMeterType = 0 }},
        bottomSlots = {{ kind = "blizzard", damageMeterType = 2 }},
        topColFracs = {1}, bottomColFracs = {1}, topRowFrac = .6 }
    return e, s, layout
end
local totals = { burstTimers = 0, frames = 0, addonMetadata = 0, nativeMetadata = 0 }
for _, gamepad in ipairs({ false, true }) do
    local e, s, layout = boot(gamepad); local meter = e.FluxBlizzardMeter
    if gamepad then s.host.scale = 1.25 end
    check(meter:Embed(s.host, layout) and s.docked(), "initial docking " .. tostring(gamepad))
    check(s.addonMetadata == 0, "addon geometry uses widget aliases without native snap metadata writes")
    local typeCalls, sessionCalls, walks, frames = s.typeCalls, s.sessionCalls, s.entryWalks, #s.frames
    local created = s.timerCreates
    s.nativeRestore()
    check(not s.docked(), "native restoration completes before addon repair")
    check(s.timerCreates == created + 1 and #s.timers == 1, "native setters request one next-frame repair")
    s.drain()
    check(s.docked(), "late native restoration repairs root and secondary pane")
    check(s.typeCalls == typeCalls and s.sessionCalls == sessionCalls and s.entryWalks == walks,
        "repair changes only geometry without content setters or entry walks")
    check(s.addonMetadata == 0 and s.nativeMetadata > 0, "native override work stays native while addon uses aliases")
    check(s.methodsIntact(), "native geometry methods and widget aliases retain their identities")
    created = s.timerCreates
    for _ = 1, 500 do s.nativeRestore() end
    local burst = s.timerCreates - created; totals.burstTimers = totals.burstTimers + burst
    check(burst == 1 and #s.timers == 1, "500 native restoration bursts coalesce to one wake")
    s.drain()
    check(s.docked() and #s.timers == 0, "burst repairs once without a self-generated repair loop")
    check(#s.frames == frames and s.typeCalls == typeCalls and s.sessionCalls == sessionCalls and s.entryWalks == walks,
        "burst repair retains frames content setter counts and entry walk counts")
    local pointHooks = #(s.hooks[s.dm] and s.hooks[s.dm].SetPoint or {})
    meter:Embed(s.host, layout)
    check(#(s.hooks[s.dm] and s.hooks[s.dm].SetPoint or {}) == pointHooks,
        "re-embed does not multiply geometry hooks")
    s.rawEngineRestore(); created = s.timerCreates; s.event("EDIT_MODE_LAYOUTS_UPDATED")
    check(s.timerCreates == created + 1, "native layout event covers modeled engine updates without Lua setters")
    s.drain(); check(s.docked(), "layout event restores modeled engine geometry")
    s.activeTab = "Map"; meter:Hide(); s.rawEngineRestore()
    e._FluxUI_CharSavedVars = { fluxWindowActiveTab = 1 }
    created = s.timerCreates; local shows = s.rootShows
    s.event("PLAYER_ENTERING_WORLD")
    check(s.timerCreates == created + 1, "world entry schedules one settle after native position work")
    s.drain()
    check(s.docked() and not s.dm:IsShown() and s.rootShows == shows, "hidden-tab world repair never shows or paints the meter")
    s.activeTab = "Meter"; meter:Show(); s.combat = true
    s.nativeRestore(); created = s.timerCreates; s.event("EDIT_MODE_LAYOUTS_UPDATED")
    check(s.timerCreates == created and not s.docked(), "combat drift defers without mutation or polling")
    s.combat = false; s.event("PLAYER_REGEN_ENABLED")
    check(s.timerCreates == created + 1, "existing combat-exit service requests one deferred repair")
    s.drain(); check(s.docked(), "deferred geometry repairs after combat")
    s.nativeRestore(); shows = s.rootShows; meter:Hide(); s.drain()
    check(not s.docked() and not s.dm:IsShown() and s.rootShows == shows, "Hide invalidates a queued repair without resurrection")
    meter:Show(); check(s.docked(), "ordinary Show can reconcile the cached layout again")
    s.nativeRestore(); meter:Cleanup(); s.drain()
    check(not meter:IsEmbedded() and s.dm:GetParent() == e.UIParent and #s.timers == 0,
        "cleanup invalidates old work and releases the native root")
    meter:Embed(s.host, layout); s.combat = true
    local parentBefore, scaleBefore, pointsBefore = s.dm:GetParent(), s.dm.scale, s.dm.points
    created = s.timerCreates; meter:Cleanup()
    check(meter:IsEmbedded() and s.dm:GetParent() == parentBefore and s.dm.scale == scaleBefore and s.dm.points == pointsBefore,
        "combat cleanup keeps native geometry intact until an allowed transition")
    s.event("PLAYER_REGEN_ENABLED")
    check(meter:IsEmbedded() and s.timerCreates == created, "a premature regen event cannot run combat cleanup")
    s.combat = false; s.event("PLAYER_REGEN_ENABLED"); s.drain()
    check(not meter:IsEmbedded() and s.dm:GetParent() == e.UIParent and near(s.dm.scale, 1),
        "existing combat-exit service completes deferred cleanup")
    meter:Embed(s.host, layout); s.combat = true; meter:Cleanup()
    check(not meter:Embed(s.host, layout), "new combat embed remains deferred")
    s.combat = false; s.event("PLAYER_REGEN_ENABLED"); s.drain()
    check(meter:IsEmbedded() and s.docked(), "newer embed cancels stale deferred cleanup")
    check(s.addonMetadata == 0, "cleanup also uses native widget aliases without snap metadata writes")
    meter:Embed(s.host, layout); s.nativeRestore(); s.details = true; meter:Hide(); s.drain()
    created = s.timerCreates; s.nativeRestore(); s.drain()
    check(s.timerCreates == created and not s.dm:IsShown(), "Details ownership stops future native geometry work")
    check(s.methodsIntact(), "cleanup and handoff never replace native geometry methods")
    totals.frames = totals.frames + #s.frames; totals.addonMetadata = totals.addonMetadata + s.addonMetadata
    totals.nativeMetadata = totals.nativeMetadata + s.nativeMetadata
end
print(string.format("native docking: %d checks, %d failures; 500burstTimers=%d frames=%d addonSnapWrites=%d nativeSnapWrites=%d pinnedNative=%s",
    checks, failures, totals.burstTimers, totals.frames, totals.addonMetadata, totals.nativeMetadata, tostring(nativeText ~= nil)))
assert(failures == 0, "native docking regressions")
