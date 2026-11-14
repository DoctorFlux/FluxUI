-- Executes the production junk rules, item cache, display and complete Junk panel.
-- Native widgets, server metadata and secure input are modeled, not certified.
local panelSource = 'Inventory/Restock/Junk/FluxVendorJunkPanel.lua'
local junkSource = 'Inventory/Restock/Junk/FluxJunk.lua'
local compare = false
for i, value in ipairs(arg or {}) do
    if value == '--panel-source' then panelSource = assert(arg[i + 1]) end
    if value == '--junk-source' then junkSource = assert(arg[i + 1]) end
    if value == '--compare' then compare = true end
end
local function read(path)
    local f = assert(io.open(path, 'rb')); local s = f:read('*a'); f:close()
    return s:gsub('\r\n', '\n')
end
local smoke = read('Inventory/Restock/Junk/_tmp_junksmoke.lua')
local ending = assert(smoke:find('for _, family in ipairs({ "live", "forever", "era", "anniversary", "mists" }) do', 1, true))
local fixture = smoke:sub(1, ending - 1):gsub('Load%("Inventory/Restock/Junk/FluxJunk.lua", env, ns%)',
    function() return 'Load(' .. string.format('%q', junkSource) .. ', env, ns)' end)
fixture = fixture:gsub('loadfile%(root %.%. path', 'loadfile((path:sub(2, 2) == ":" and path or root .. path)')
local Boot = assert(load(fixture .. '\nreturn Boot', '@junk-fixture', 't',
    setmetatable({arg = {[0] = 'Inventory/Restock/Junk/_tmp_junksmoke.lua'}}, {__index = _G})))()
local checks, failures = 0, 0
local function check(value, label)
    checks = checks + 1
    if not value then failures = failures + 1; print('FAIL ' .. label) end
end
local function boot(family, count)
    local t = Boot(family)
    local e = t.env
    local h = {frames = {}, queue = {}, loaded = {}, names = {}, requests = {}, itemReads = 0,
        scans = 0, paints = 0, rowPaints = 0, sizeWrites = 0, now = 0, errors = {}, depth = 0, maxDepth = 0}
    e.WOW_PROJECT_MAINLINE, e.WOW_PROJECT_CLASSIC = 1, 2
    e.WOW_PROJECT_ID = (family == 'live' or family == 'forever') and 1 or 2
    e.LE_EXPANSION_LEVEL_CURRENT = 12
    e.FluxItemClass = nil
    e.FluxVendorAuto.EnsureSettings = function() return t.settings end
    for id = 1, count do t.settings.junkList[400000 + id] = true end
    local function queue(delay, fn)
        local timer = {at = h.now + delay, fn = fn}
        function timer:Cancel() self.cancelled = true end
        h.queue[#h.queue + 1] = timer
        return timer
    end
    e.C_Timer = {After = queue, NewTimer = queue}
    function h:advance(seconds)
        local target = self.now + seconds
        for _ = 1, 3000 do
            local index, earliest
            for i, timer in ipairs(self.queue) do
                if timer.at <= target and (not earliest or timer.at < earliest.at) then index, earliest = i, timer end
            end
            if not index then self.now = target; return end
            table.remove(self.queue, index); self.now = earliest.at
            if not earliest.cancelled then earliest.fn() end
        end
        error('timer refresh failed to settle')
    end
    function h:event(event, ...)
        self.depth = self.depth + 1; self.maxDepth = math.max(self.maxDepth, self.depth)
        if self.depth > 100 then error('recursive metadata redraw') end
        for _, f in ipairs(self.frames) do
            if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
        end
        self.depth = self.depth - 1
    end
    local function info(id)
        h.itemReads = h.itemReads + 1
        if h.loaded[id] then return h.names[id] or 'Item ' .. id, 'item:' .. id, 1, 1, 1, 'Misc', '', 1, '', 123, 1, 15, 0 end
    end
    e.C_Item = {GetItemInfo = info, GetItemIconByID = function() return 123 end,
        IsItemDataCachedByID = function(id) return h.loaded[id] == true end,
        RequestLoadItemDataByID = function(id)
            h.requests[#h.requests + 1] = id
            if h.synchronous and not h.loaded[id] then h.loaded[id] = true; h:event('ITEM_DATA_LOAD_RESULT', id, true) end
        end}
    e.GetItemInfo = info
    e.GetItemInfoInstant = function() return nil end
    e.GetItemQualityColor = function() return 1, 1, 1 end
    e.geterrorhandler = function() return function(err) h.errors[#h.errors + 1] = err end end
    local methods = {}
    local function noop() end
    for _, name in ipairs({'SetPoint','ClearAllPoints','SetAllPoints','SetFrameStrata','RegisterForClicks',
        'RegisterForDrag','SetJustifyH','SetWordWrap','SetNonSpaceWrap','SetColorTexture','SetTexture',
        'SetBlendMode','SetAlpha','LockHighlight','UnlockHighlight','EnableMouse','SetID'}) do methods[name] = noop end
    function methods:GetName() return self.name end
    function methods:GetFrameLevel() return self.level or 1 end
    function methods:SetFrameLevel(level) self.level = level end
    function methods:GetFrameStrata() return 'MEDIUM' end
    function methods:SetText(value) self.text = value end
    function methods:GetText() return self.text end
    function methods:IsShown() return self.shown end
    function methods:SetScript(event, fn) self.scripts[event] = fn end
    function methods:HookScript(event, fn)
        local old = self.scripts[event]
        self.scripts[event] = function(...) if old then old(...) end; fn(...) end
    end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:UnregisterEvent(event) self.events[event] = nil end
    function methods:Show()
        local changed = not self.shown; self.shown = true
        if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function methods:Hide()
        local changed = self.shown; self.shown = false
        if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function methods:SetShown(value) if value then self:Show() else self:Hide() end end
    function methods:GetWidth() return self.width or 300 end
    function methods:GetHeight() return self.height or 300 end
    local function rangeChanged(f, changed)
        local parent = f.scrollOwner
        if changed and parent and parent.scripts.OnScrollRangeChanged then parent.scripts.OnScrollRangeChanged(parent, 0, f:GetHeight()) end
    end
    function methods:SetWidth(value)
        h.sizeWrites = h.sizeWrites + 1
        local changed = self.width ~= value; self.width = value; rangeChanged(self, changed)
    end
    function methods:SetHeight(value)
        h.sizeWrites = h.sizeWrites + 1
        local changed = self.height ~= value; self.height = value; rangeChanged(self, changed)
    end
    function methods:SetSize(w, v) self:SetWidth(w); self:SetHeight(v) end
    function methods:SetScrollChild(child) self.child = child; child.scrollOwner = self; h.scroll = self end
    function methods:GetVerticalScroll() return self.offset or 0 end
    function methods:SetVerticalScroll(value) self.offset = value end
    local function frame(kind, name, parent)
        local f = setmetatable({name = name, parent = parent, scripts = {}, events = {}, shown = true}, {__index = methods})
        if name then e[name] = f end
        h.frames[#h.frames + 1] = f
        return f
    end
    methods.CreateTexture = frame
    methods.CreateFontString = frame
    e.CreateFrame = frame
    e.MerchantFrame = frame('Frame', 'MerchantFrame')
    e.GameTooltip_Hide = noop
    e.PanelTemplates_SetTab = function(f, id) f.selectedTab = id end
    e.PanelTemplates_TabResize = noop
    e.LibStub = function() return {Add = function() return {SetText = noop} end} end
    -- Actual item-cache events feed the actual junk visual listeners.
    assert(loadfile('Inventory/FluxItemClass.lua', 't', e))('_FluxUI', t.ns)
    assert(loadfile('Inventory/Restock/Vendor/FluxVendorItemDisplay.lua', 't', e))('_FluxUI', t.ns)
    local fields = e.FluxVendorItemDisplay.GetItemFields
    e.FluxVendorItemDisplay.GetItemFields = function(...) h.paints = h.paints + 1; return fields(...) end
    local applyName = e.FluxVendorItemDisplay.ApplyNameFontString
    e.FluxVendorItemDisplay.ApplyNameFontString = function(...) h.rowPaints = h.rowPaints + 1; return applyName(...) end
    local autoList = t.fj.GetAutoJunkList
    t.fj.GetAutoJunkList = function(...) h.scans = h.scans + 1; return autoList(...) end
    assert(loadfile(panelSource, 't', e))('_FluxUI', t.ns)
    e.FluxVendorJunkPanel:Init()
    h.panel, h.frame, h.t, h.env = e.FluxVendorJunkPanel, e.FluxVendorJunkPanelFrame, t, e
    return h
end

for _, family in ipairs({'live','forever','mists','era','anniversary'}) do
    local h = boot(family, 400)
    h.frame:Show()
    local coldRequests, coldScans, coldPaints, coldRows = #h.requests, h.scans, h.paints, h.rowPaints
    for id = 400001, 400400 do h.loaded[id] = true; h:event('ITEM_DATA_LOAD_RESULT', id, true) end
    h:advance(.21)
    local burstScans, burstPaints = h.scans - coldScans, h.paints - coldPaints
    print(('METRIC %s coldRequests=%d coldScans=%d coldRows=%d burstScans=%d burstFields=%d burstRows=%d'):format(family,coldRequests,coldScans,coldRows,burstScans,burstPaints,h.rowPaints-coldRows))
    check(coldRequests <= 1600, family .. ' cold list requests bounded to linear work')
    check(coldRows == 17, family .. ' opening paints once despite scroll range delivery')
    check(burstScans <= 2, family .. ' metadata burst coalesces full bag/list rebuilds')
    check(burstPaints <= 40, family .. ' metadata burst coalesces row paints')
    local before = h.sizeWrites
    for _ = 1, 100 do h.panel:RefreshList() end
    check(h.sizeWrites == before, family .. ' stable refresh does not rewrite scroll geometry')
    local list = h.t.fj.GetJunkTabList()
    check(#list == 400 and list[1] == 400001 and list[400] == 400400, family .. ' full sorted list retained')
    h.panel:FocusItem(400300, 2)
    check(h.scroll:GetVerticalScroll() > 0, family .. ' focus scroll retained')
    h.panel:SetSubTab(1)
    h.t.fj.MarkUseful(400300)
    check(h.frame.selectedTab == 1 and h.t.fj.IsExplicitUseful(400300), family .. ' Useful mutation retained')
    h.panel:SetSubTab(2)
    h.t.fj.AddJunk(400300)
    check(h.t.fj.IsExplicitJunk(400300), family .. ' Junk mutation retained')
    local scans = h.scans
    h.frame:Hide(); h:advance(1)
    check(h.scans == scans, family .. ' hidden panel stops delayed work')
    h.frame:Show(); h:advance(.21)
    check(#h.t.fj.GetJunkTabList() == 400, family .. ' reopen retains rows')
    -- A late auto-junk visual notification still updates membership at the same
    -- metadata boundary, without requiring a tab switch or manual list edit.
    h.t.add(1, 500001, {quality = 0, classID = 15})
    h.loaded[500001] = true
    h.t.fj.NotifyVisualRefresh(500001); h:advance(.21)
    local found = false
    for _, id in ipairs(h.t.fj.GetJunkTabList()) do if id == 500001 then found = true end end
    check(found, family .. ' late automatic junk remains visible')
    h.t.fj.MarkUseful(500001); h:advance(.21)
    check(not h.t.fj.IsAutoJunk(500001), family .. ' Useful still protects automatic junk')
    -- Cancelled callbacks cannot take over a reopened panel's pending refresh.
    h.t.fj.NotifyVisualRefresh()
    local stale = h.queue[#h.queue] and h.queue[#h.queue].fn
    h.frame:Hide(); h.frame:Show(); h.t.fj.NotifyVisualRefresh()
    local beforeStale = h.paints
    if stale then stale() end
    check(stale and h.paints == beforeStale, family .. ' old timer cannot repaint reopened panel')
    h:advance(.21)
    check(h.paints > beforeStale, family .. ' new timer retains refresh ownership')
    local names = boot(family, 3)
    for id = 400001, 400003 do names.loaded[id] = true end
    names.names[400001], names.names[400002], names.names[400003] = 'Zulu', 'Zulu', 'Alpha'
    names.frame:Show()
    local ordered = names.t.fj.GetJunkTabList()
    check(ordered[1] == 400003 and ordered[2] == 400001 and ordered[3] == 400002,
        family .. ' name ordering and numeric tie break retained')
    local sync = boot(family, 120); sync.synchronous = true
    local ok, err = pcall(function() sync.frame:Show() end)
    print(('METRIC %s synchronousDepth=%d synchronousScans=%d'):format(family,sync.maxDepth,sync.scans))
    check(ok and sync.maxDepth <= 2, family .. ' synchronous metadata cannot recursively rebuild: ' .. tostring(err))
end
print(('Vendor Junk tab: %d checks, %d failures'):format(checks, failures))
if not compare then assert(failures == 0) end
