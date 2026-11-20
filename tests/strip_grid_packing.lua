-- Real grid packers and strip-dependent notification with modeled widgets.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a")
    file:close()
    return (text:gsub("\r\n", "\n"))
end
local function section(source, first, last)
    local start = assert(source:find(first, 1, true))
    return source:sub(start, assert(source:find(last, start + #first, true)) - 1)
end

local function fixture(before, classic, forever)
    local state = {factor = 1, writes = 0, style = 0, passes = 0, sorts = 0, info = 0, envelope = 0, moves = 0, timers = {}}
    local env = setmetatable({}, {__index = _G})
    env._G = env
    env.table = setmetatable({sort = function(...)
        state.sorts = state.sorts + 1
        return table.sort(...)
    end}, {__index = table})
    env.InCombatLockdown = function() return state.locked end
    env.C_Timer = {After = function(_, task) state.timers[#state.timers + 1] = task end}
    env.Flux = {
        Startup = {Count = function() state.passes = state.passes + 1 end},
        Client = {isAnyClassic = classic, isPostDF = not classic, isForever = forever},
        EBS = {Style = {
            StampFace = function() end,
            RefreshSqueezeChrome = function() state.style = state.style + 1 end,
        }},
    }
    env.FluxBindingMode = {ShouldForceShowAllExtraSlots = function() return state.binding end}
    local function frame(name)
        local object = {name = name, w = 1, h = 1, scale = 1, shown = true, level = 8, points = {}}
        local function write()
            assert(not state.locked, "protected layout attempted during lockdown")
            state.writes = state.writes + 1
        end
        function object:SetSize(w, h) write(); self.w, self.h = w, h end
        function object:GetSize() return self.w, self.h end
        function object:SetScale(value) write(); self.scale = value end
        function object:GetScale() return self.scale end
        function object:ClearAllPoints() write(); self.points = {} end
        function object:SetPoint(...) write(); self.points[#self.points + 1] = {...} end
        function object:GetPoint(i) return table.unpack(self.points[i]) end
        function object:GetNumPoints() return #self.points end
        function object:SetFrameLevel(level) write(); self.level = level end
        function object:GetFrameLevel() return self.level end
        function object:SetClipsChildren(clipped) write(); self.clip = clipped end
        function object:SetClampedToScreen() end
        function object:Show() write(); self.shown = true end
        function object:Hide() write(); self.shown = false end
        function object:IsShown() return self.shown end
        return object
    end
    env.CreateFrame = function(_, name) return frame(name) end
    env.UIParent = frame("UIParent")
    local function source(path)
        return read(before and before .. "/" .. path:gsub("/", "-") or path)
    end
    for _, root in ipairs({"CombatGrid","NonCombatGrid"}) do
        local path = "ExtraButtonSystem/" .. root .. "/Grid.lua"
        assert(load(source(path), "@" .. path, "t", env))()
    end
    local combat = env.FluxCombatGrid.New(nil, {name = "combat", size = 45})
    local noncombat = env.FluxNonCombatGrid.New(nil, {name = "noncombat", size = 44})
    local function add(grid, i, group)
        local button = {SlotFrame = frame("slot" .. i), Widget = frame("face" .. i)}
        grid.Buttons[#grid.Buttons + 1] = button
        grid.ButtonOrder[button], grid.ColumnGroups[button] = i, group
        return button
    end
    for i, group in ipairs({"healing", "healing", "mana", "mana", "ammo"}) do add(combat, i, group) end
    for i, group in ipairs({"hearthteleport", "hearthteleport", "mount", "foodwater", "foodwater", "consumables",
        "utility", "utility", "utility", "utility", "utility"}) do add(noncombat, i, group) end
    env.FluxCombatManager = {Grid = combat, UpdateAnchor = function()
        state.moves = state.moves + 1
        combat.Frame.x = state.edge - combat.Frame.w
    end}
    env.FluxNonCombatAPI = {DefaultGrid = noncombat}
    env.FluxNonCombatGrid_ApplyScreenBottomAnchor = function()
        state.moves = state.moves + 1
        noncombat.Frame.x = 4
    end
    env.FluxTrinketMenuManager = {UpdateAnchor = function()
        state.moves = state.moves + 1
        state.trinket = state.edge * 2
    end}
    env.FluxInfoFrame = {UpdatePosition = function()
        state.info = state.info + 1
        state.infoX = combat.Frame.x
        state.infoRight = state.trinket
    end}
    local actualEnvelope = section(read("Layout/UnifiedBorder.lua"),
        "local gridLayoutPending", "--- Unified micro+status chrome")
    env.FluxUnifiedBorder = assert(load("local UnifiedBorder = {}\n" .. actualEnvelope
        .. "\nreturn UnifiedBorder", "@actual-grid-finish", "t", env))()
    env.FluxUnifiedBorder.UpdateBorder = function()
        assert(state.infoX == combat.Frame.x and state.infoRight == state.trinket, "Info reads final neighbor locations")
        state.envelope = state.envelope + 1
    end
    env.FluxUILayoutSqueeze = {GetActionBarHorizontalSqueezeFactor = function() return state.factor end}
    local settings = section(source("FluxDefaultSettings.lua"),
        "-- Squeeze callback bodies are shared across notifications.", "local squeezeRefreshScheduled")
    assert(load(settings, "@actual-strip-dependent-layout", "t", env))()
    env.Flux.Perf = {Regen = {Time = function(_, callback, ...) return callback(...) end}}

    function state:cross(edge)
        self.edge = edge
        local writes, style, passes, sorts, info, envelope, moves =
            self.writes, self.style, self.passes, self.sorts, self.info, self.envelope, self.moves
        env.FluxUILayoutSqueeze.NotifyLayoutDependents(true, true)
        env.FluxUnifiedBorder.UpdateAfterGridLayout()
        local timers = self.timers
        self.timers = {}
        for _, task in ipairs(timers) do task() end
        assert(self.info - info == 1 and self.envelope - envelope == 1 and self.moves - moves == 3)
        return self.writes - writes, self.style - style, self.passes - passes, self.sorts - sorts
    end
    function state:signature()
        local result = {self.infoX, self.infoRight}
        for _, grid in ipairs({combat, noncombat}) do
            local root = grid.Frame
            result[#result + 1] = ("%s:%s:%s:%s"):format(root.w, root.h, root.x, tostring(root.shown))
            for _, btn in ipairs(grid.Buttons) do
                local slot, face = btn.SlotFrame, btn.Widget
                local p = slot.points[1] or {}
                result[#result + 1] = table.concat({tostring(slot.shown), slot.w, slot.h, slot.level,
                    tostring(slot.clip), p[1] or "", p[2] and p[2].name or "",
                    p[3] or "", p[4] or "", p[5] or "", face.w, face.h, face.scale}, ":")
            end
        end
        return table.concat(result, "|")
    end
    state.env, state.combat, state.noncombat, state.frame = env, combat, noncombat, frame
    state.add = add
    return state
end

local function RootAnchorFixture(archive, classic)
    local state = fixture(nil, classic)
    local env = state.env
    local function code(path)
        return read(archive and archive .. "/" .. path:gsub("/", "-") or path)
    end
    local settings = section(code("FluxDefaultSettings.lua"),
        "-- Squeeze callback bodies are shared across notifications.", "local squeezeRefreshScheduled")
    env.FluxUILayoutSqueeze.CanKeepGridAnchors = nil
    assert(load(settings, "@actual-grid-anchor-check", "t", env))()
    env.CreateFrame = function(_, name)
        local frame = state.frame(name)
        frame.RegisterEvent, frame.SetScript = function() end, function() end
        return frame
    end
    for _, path in ipairs({"ExtraButtonSystem/CombatGrid/GridManager.lua", "ExtraButtonSystem/NonCombatGrid/GridInit.lua"}) do
        assert(load(code(path), "@" .. path, "t", env))()
    end
    local combat, noncombat = state.combat.Frame, state.noncombat.Frame
    local strip = state.frame("action strip")
    env.FluxActionStrip, env.FluxMainActionBar = strip, strip
    env.Flux.Cap = {GamepadHudActive = function() return state.gamepad end}
    env.FluxExtraButtonSystem_GetActionStripBottomOffset = function()
        state.floorReads = state.floorReads + 1
        return 24
    end
    env.UIParent.GetEffectiveScale = function() return .75 end
    noncombat.GetEffectiveScale = function() return .6 end
    state.rootWrites, state.floorReads = 0, 0
    for _, frame in ipairs({combat, noncombat}) do
        for _, name in ipairs({"SetPoint", "ClearAllPoints"}) do
            local method = frame[name]
            frame[name] = function(self, ...)
                state.rootWrites = state.rootWrites + 1
                return method(self, ...)
            end
        end
    end
    function state:place()
        env.FluxNonCombatGrid_ApplyScreenBottomAnchor()
        env.FluxCombatManager:UpdateAnchor()
    end
    function state:anchors()
        local parts = {}
        for _, frame in ipairs({combat, noncombat}) do
            for _, point in ipairs(frame.points) do
                parts[#parts + 1] = table.concat({point[1], point[2].name, point[3], point[4], point[5]}, ":")
            end
        end
        return table.concat(parts, "|")
    end
    function state:crossRoots(edge)
        self.edge = edge
        strip.w = edge * 2
        local writes, reads, envelopes = self.rootWrites, self.floorReads, self.envelope
        env.FluxUILayoutSqueeze.NotifyLayoutDependents(true, true)
        env.FluxUnifiedBorder.UpdateAfterGridLayout(true)
        assert(self.envelope == envelopes + 1, "both grids settle in the same envelope transaction")
        local timers = self.timers
        self.timers = {}
        for _, task in ipairs(timers) do task() end
        assert(self.envelope == envelopes + 1, "no separate grid envelope republish")
        return self.rootWrites - writes, self.floorReads - reads
    end
    state.strip = strip
    return state
end

do
    local archive = arg[1] == "--root-anchors" and arg[2]
    for _, classic in ipairs({false, true}) do
        local current = RootAnchorFixture(nil, classic)
        local prior = archive and RootAnchorFixture(archive, classic)
        current:crossRoots(50)
        if prior then prior:crossRoots(50) end
        local oldWrites, oldReads = 0, 0
        for i = 1, 10 do
            local edge = i % 2 == 0 and 50 or 170
            local writes, reads = current:crossRoots(edge)
            assert(writes == 0 and reads == 0, "existing grid anchors follow the strip without new writes or floor reads")
            if prior then
                local a, b = prior:crossRoots(edge)
                oldWrites, oldReads = oldWrites + a, oldReads + b
                assert(current:anchors() == prior:anchors(), "final anchor offsets and relative owners match")
            end
        end
        if prior then
            assert(oldWrites == 50 and oldReads == 10, "the archive resets both root anchors on every crossing")
            print(("STRIP_ROOT_ANCHORS|%s|%d|0|%d|0"):format(tostring(classic), oldWrites, oldReads))
        end
        local env, combat, noncombat = current.env, current.combat.Frame, current.noncombat.Frame
        combat.points[1][4] = 3
        noncombat.points[3] = {"CENTER", env.UIParent, "CENTER", 0, 0}
        current:place()
        assert(combat.points[1][4] == 0 and #noncombat.points == 2, "external point drift restores exact placement")
        local oldPoint = noncombat.GetPoint
        local opaque = setmetatable({}, {__eq=function() error("private anchor compared") end})
        env.issecretvalue = function(value) return rawequal(value, opaque) end
        for _, getter in ipairs({function() return opaque, opaque, opaque end, function() error("denied getter") end, false}) do
            noncombat.GetPoint = getter
            local before = current.rootWrites
            current:place()
            assert(current.rootWrites - before == 3, "unknown anchor getter uses the full writer")
        end
        noncombat.GetPoint = oldPoint
        local replacement = current.frame("new strip")
        env.FluxActionStrip, env.FluxMainActionBar = replacement, replacement
        current:place()
        assert(combat.points[1][2] == replacement and noncombat.points[2][2] == replacement,
            "same-position replacement still changes the anchor owner")
        local keep = env.FluxUILayoutSqueeze.CanKeepGridAnchors
        env.FluxUILayoutSqueeze.CanKeepGridAnchors = nil
        local earlyWrites = current.rootWrites
        current:place()
        assert(current.rootWrites - earlyWrites == 5, "startup before the squeeze helper can still place both grids")
        env.FluxUILayoutSqueeze.CanKeepGridAnchors = keep
        current.gamepad = true
        current:place()
        assert(combat.points[1][2] == noncombat and noncombat.points[1][2] == env.UIParent
            and noncombat.points[1][5] == 30, "gamepad retains the alternate relative grid and scaled floor")
        noncombat:Hide()
        current:place()
        assert(combat.points[1][2] == env.UIParent and combat.points[1][5] == 24, "hidden noncombat grid uses the screen fallback")
        current.locked = true
        local before = current.rootWrites
        current:place()
        assert(current.rootWrites == before and current.combat._pendingRegenRelayout and current.noncombat._pendingRegenRelayout,
            "lockdown retains both pending layouts without anchor writes")
    end
    print("Action-strip root anchors pass relative ownership, repair, gamepad and lockdown.")
    if arg[1] == "--root-anchors" then return end
end

local widthCheckpoint = arg[1] == "--width" and arg[2]
local checkpoint = arg[1] ~= "--width" and arg[1] ~= "--ring" and arg[1]
for _, classic in ipairs({false, true}) do
    local after = fixture(nil, classic)
    local before = checkpoint and fixture(checkpoint, classic)
    after:cross(50)
    if before then before:cross(50) end
    for i = 1, 10 do
        local edge = i % 2 == 0 and 50 or 170
        local writes, style, passes = after:cross(edge)
        assert(writes == 0 and style == 0 and passes == 0, "stable translation keeps the existing slots and faces")
        if before then
            local oldWrites, oldStyle, oldPasses = before:cross(edge)
            assert(oldWrites > 0 and oldStyle == 16 and oldPasses == 2)
            assert(before:signature() == after:signature(), "final packing, visibility, scale, levels and Info agree")
            print(("STRIP_PACKING classic=%s crossing=%d writes=%d/%d faceRefresh=%d/%d packing=%d/%d")
                :format(tostring(classic), i, oldWrites, writes, oldStyle, style, oldPasses, passes))
        end
    end

    after.factor = .78
    local _, style, passes, sorts = after:cross(50)
    assert(style == 16 and passes == 2 and sorts == 0, "width changes refresh every changed face on the existing column order")
    assert(after:cross(170) == 0, "new squeeze is reusable")
    local grid, button = after.noncombat, after.noncombat.Buttons[2]
    button.SlotFrame:Hide()
    local _, _, hidePass = after:cross(50)
    assert(hidePass == 1, "one changed grid repacks")
    button.SlotFrame:Show()
    local _, _, revealPass = after:cross(170)
    assert(revealPass == 1, "revealed slot repacks")
    local utility = after.add(grid, 12, "utility")
    local _, _, newPass = after:cross(50)
    assert(newPass == 1 and utility.SlotFrame:GetNumPoints() == 1, "added slot repacks")

    local function repair(change)
        change()
        local _, _, rebuilt = after:cross(170)
        assert(rebuilt == 1, "changes to the non-combat owner repair locally")
    end
    repair(function() grid.Spacing = 3 end)
    repair(function() grid.ButtonOrder[button] = 99 end)
    repair(function() grid.ColumnGroups[button] = "utility" end)
    repair(function() button.Widget = after.frame("new face") end)
    repair(function() button.SlotFrame.points[1][4] = -1 end)
    repair(function() button.Widget.w = 99 end)
    repair(function() grid.Frame.w = 999 end)
    repair(function() button.SlotFrame.level = 900 end)
    local point = button.SlotFrame.GetPoint
    repair(function() button.SlotFrame.GetPoint = function() error("unavailable native geometry") end end)
    local private = setmetatable({}, {__eq = function() error("secret comparison") end})
    after.env.issecretvalue = function(value) return rawequal(value, private) end
    repair(function() button.SlotFrame.GetPoint = function() return private, private, private end end)
    button.SlotFrame.GetPoint = point
    local setSize = grid.Frame.SetSize
    grid.Frame.SetSize = function(self, ...)
        grid.Frame.SetSize = setSize
        grid.ButtonOrder[button] = -10
        setSize(self, ...)
    end
    grid:Relayout()
    local _, _, reentrant = after:cross(170)
    assert(reentrant == 1, "a change during the prior write requires a new packing pass")
    local prior = after.passes
    grid:Relayout()
    assert(after.passes == prior + 1, "an explicit layout still refreshes")
    after.binding = true
    local _, _, forced = after:cross(50)
    assert(forced == 2, "binding mode keeps its full layout")
    after.binding = false
    after:cross(170)
    grid:BeginLayout()
    prior = after.passes
    grid:Relayout(true)
    assert(after.passes == prior and grid._layoutBatchPending, "batch guard wins")
    grid:EndLayout()
    assert(after.passes == prior + 1, "batch settles through the original writer")
    after.locked = true
    local writes = after.writes
    grid:Relayout(true)
    assert(after.writes == writes and grid._pendingRegenRelayout, "combat guard wins")
    after.locked = false
    local _, _, regen = after:cross(50)
    assert(regen == 1 and not grid._pendingRegenRelayout, "pending combat layout is applied")
end

if widthCheckpoint then
    for _, profile in ipairs({"retail", "forever", "classic"}) do
        local classic, forever = profile == "classic", profile == "forever"
        local before, after = fixture(widthCheckpoint, classic, forever), fixture(nil, classic, forever)
        before:cross(50); after:cross(50)
        local totals = {{0, 0, 0}, {0, 0, 0}}
        for i = 1, 60 do
            local factor = ({1, .78, .64, .91})[(i - 1) % 4 + 1]
            for index, model in ipairs({before, after}) do
                model.factor = factor
                local writes, style, passes, sorts = model:cross(i % 2 == 1 and 170 or 50)
                assert(passes == (i == 1 and 0 or 2), "both grids retain the actual layout count")
                local total = totals[index]
                total[1], total[2], total[3] = total[1] + writes, total[2] + style, total[3] + sorts
            end
            assert(before:signature() == after:signature(), "both packers agree at every width and anchor")
        end
        assert(totals[1][1] > totals[2][1] and totals[1][2] == totals[2][2] and totals[1][3] > 0 and totals[2][3] == 0)
        print(("STRIP_GRID_WIDTH profile=%s steps=60 writes=%d/%d chrome=%d/%d sorts=%d/%d")
            :format(profile, totals[1][1], totals[2][1], totals[1][2], totals[2][2], totals[1][3], totals[2][3]))

        -- A width change still falls through if the layout is no longer the
        -- one that was measured by the owner, including replacement policy.
        local grid, slot = after.noncombat, after.noncombat.Buttons[2].SlotFrame
        local opaque = setmetatable({}, {__eq=function() error("secret coordinate compared") end})
        after.env.issecretvalue = function(value) return rawequal(value, opaque) end
        local getSize = slot.GetSize
        local savedPacking = grid._fluxStripPacking
        slot.w = 999
        slot.GetSize = function() return opaque, opaque end
        after.factor = .84
        after:cross(170)
        assert(grid._fluxStripPacking == savedPacking and slot.w == grid._fluxStripPacking.slotWidth,
            "replayed width replaces a changed size directly without reading it")
        slot.GetSize = getSize
        local getPoint = slot.GetPoint
        slot.GetPoint = function() return opaque end
        local combatPacking, priorPacking = after.combat._fluxStripPacking, grid._fluxStripPacking
        after.factor = .81
        after:cross(50)
        assert(after.combat._fluxStripPacking == combatPacking and grid._fluxStripPacking ~= priorPacking,
            "opaque points trigger the normal writer only for the affected grid")
        slot.GetPoint = getPoint

        local compute, calls = grid.ComputeDynamicPriorities, 0
        grid.ComputeDynamicPriorities = function(...)
            calls = calls + 1
            return compute(...)
        end
        after.factor = .72
        local _, _, replaced = after:cross(170)
        assert(replaced == 2 and calls == 1, "a replacement packing owner runs its own policy")
        after.factor = .83
        after:cross(50)
        assert(calls == 2 and not grid._fluxStripPacking.columns, "replacement policies keep resolving at each width")
        after.factor = .62
        after.locked = true
        local writes = after.writes
        grid:Relayout(true)
        assert(after.writes == writes and grid._pendingRegenRelayout, "width reuse cannot write protected frames during lockdown")
        after.locked = false
        local _, _, released = after:cross(50)
        assert(released == 2 and calls == 3 and not grid._pendingRegenRelayout, "the protected grid settles on release")
    end
end

local function AttachChrome(state, archive)
    local env = state.env
    local function source(path)
        return read(archive and archive .. "/" .. path:gsub("/", "-") or path)
    end
    assert(load(source("ExtraButtonSystem/Engine/Style.lua"), "@actual-grid-style", "t", env))("_FluxUI", {Flux=env.Flux})
    assert(load(source("ExtraButtonSystem/Engine/Util.lua"), "@actual-grid-chrome-util", "t", env))()
    local function cosmetic(name, parent)
        local o = state.frame(name)
        local function nativeWrite()
            assert(not state.locked, "cosmetic writer entered protected layout")
            state.chromeWrites = state.chromeWrites + 1
        end
        for _,key in ipairs({"SetSize", "ClearAllPoints", "SetPoint", "Show", "Hide", "SetFrameLevel"}) do
            local writer = o[key]
            o[key] = function(self, ...) nativeWrite();return writer(self, ...) end
        end
        function o:GetParent() return parent end
        function o:SetParent(value) nativeWrite();parent=value end
        function o:GetPoint(index) return table.unpack(self.points[index] or {}) end
        function o:GetWidth() return self.w end
        function o:GetHeight() return self.h end
        function o:GetTexture() return self.art end
        function o:SetTexture(art) nativeWrite();self.art=art end
        function o:SetAtlas(art, nativeSize)
            nativeWrite();self.art=art
            if nativeSize then self.w,self.h=58,60 end
        end
        function o:SetDrawLayer(...) nativeWrite();self.draw={...} end
        function o:SetTexCoord(...) nativeWrite();self.uv={...} end
        function o:SetVertexColor(...) nativeWrite();self.color={...} end
        function o:SetBlendMode(blend) nativeWrite();self.blend=blend end
        function o:SetAlpha(alpha) nativeWrite();self.alpha=alpha end
        function o:GetAlpha() return self.alpha or 1 end
        function o:SetAllPoints(target) nativeWrite();self.target=target end
        function o:EnableMouse() end
        function o:SetUsingParentLevel(value) nativeWrite();self.useParentLevel=value end
        function o:SetHideCountdownNumbers(value) nativeWrite();self.hideNumbers=value end
        function o:SetCountdownFont(value) nativeWrite();self.fontObject=value end
        function o:SetCountdownAbbrevThreshold(value) nativeWrite();self.abbreviation=value end
        function o:SetFont(path, size, flags) nativeWrite();self.font={path,size,flags} end
        function o:GetFont() return "font", 12, "OUTLINE" end
        return o
    end
    env.CreateFrame=function(_, _, parent)
        local o=cosmetic("generated",parent)
        local scripts={}
        function o:SetScript(key, fn) scripts[key]=fn end
        function o:GetScript(key) return scripts[key] end
        return o
    end
    state.chromeWrites,state.ringFits=0,0
    for _,grid in ipairs({state.combat,state.noncombat}) do
        for _,button in ipairs(grid.Buttons) do
            local widget=button.Widget
            button.kind="extra"
            function widget:GetWidth() return self.w end
            function widget:GetHeight() return self.h end
            function widget:CreateTexture() return cosmetic("texture",self) end
            for _,key in ipairs({"NormalTexture","PushedTexture","CheckedTexture","HighlightTexture","Border","SlotArt","SlotBackground"}) do
                widget[key]=cosmetic(key,widget)
            end
            function widget:SetNormalAtlas(...) self.NormalTexture:SetAtlas(...) end
            function widget:SetPushedAtlas(...) self.PushedTexture:SetAtlas(...) end
            function widget:SetNormalTexture(...) self.NormalTexture:SetTexture(...) end
            function widget:SetPushedTexture(...) self.PushedTexture:SetTexture(...) end
            function widget:SetCheckedTexture(...) self.CheckedTexture:SetTexture(...) end
            local normal=widget.NormalTexture
            local setSize=normal.SetSize
            function normal:SetSize(...)
                state.ringFits=state.ringFits+1
                return setSize(self,...)
            end
            button.WCooldown=cosmetic("cooldown",widget)
            button.WCount=cosmetic("count",widget)
            widget.FluxButton=button
            local digit=cosmetic("digit",button.WCooldown)
            function button.WCooldown:GetCountdownFontString() return digit end
            button.UpdateEmptyBackground=function(self)
                if self.WEmptyBG then self.WEmptyBG:Show() end
            end
        end
    end
    function state:chromeSignature()
        local fields={}
        local function emit(o)
            if not o then return end
            local p,relative,edge,x,y=o:GetPoint(1)
            local parent=o:GetParent()
            fields[#fields+1]=table.concat({o.name,o.art or "",o.w,o.h,o.scale,tostring(o.shown),o.alpha or 1,
                o.blend or "",o.level,p or "",relative and relative.name or "",edge or "",x or "",y or "",
                parent and parent.name or "",table.concat(o.uv or {},","),table.concat(o.draw or {},","),
                table.concat(o.color or {},","),table.concat(o.font or {},","),o.fontObject or "",o.abbreviation or ""},":")
        end
        for _,grid in ipairs({self.combat,self.noncombat}) do
            for _,button in ipairs(grid.Buttons) do
                local w=button.Widget
                for _,key in ipairs({"NormalTexture","PushedTexture","CheckedTexture","HighlightTexture","Border",
                    "SlotArt","SlotBackground","BackgroundTexture","_fluxQuickslotRing","_fluxCountHolder"}) do
                    emit(w[key])
                end
                emit(button.WEmptyBG);emit(button.WCount);emit(button.WCooldown);emit(button.WCooldown:GetCountdownFontString())
                assert(button.WCooldown.level>button.WCount:GetParent().level,"cooldown stays above the count")
            end
        end
        return table.concat(fields,"|")
    end
    return state
end

if arg[1]=="--ring" or not arg[1] then
    local archive=arg[1]=="--ring" and arg[2]
    for _,profile in ipairs({"retail","forever","classic"}) do
        local classic,forever=profile=="classic",profile=="forever"
        local old=archive and AttachChrome(fixture(nil,classic,forever),archive)
        local new=AttachChrome(fixture(nil,classic,forever))
        new:cross(50)
        if old then old:cross(50) end
        local newFits,newWrites=new.ringFits,new.chromeWrites
        local oldFits,oldWrites=old and old.ringFits,old and old.chromeWrites
        local function replay(model,i)
            model.factor=i%2==1 and .76 or 1
            model:cross(i%2==1 and 170 or 50)
        end
        for i=1,60 do
            local prior=new.ringFits
            replay(new,i)
            assert(new.ringFits-prior==16,"each resized grid face receives a single native ring fit")
            if old then
                local previous=old.ringFits
                replay(old,i)
                assert(old.ringFits-previous==32,"archived width edits fit each ring twice")
                assert(new:signature()==old:signature() and new:chromeSignature()==old:chromeSignature(),
                    "same grid, ring, art, equipped glow, checked/pushed and cooldown layout")
            end
        end
        if old then
            print(("STRIP_RING %s steps=60 fits=%d/%d cosmeticWrites=%d/%d")
                :format(profile,old.ringFits-oldFits,new.ringFits-newFits,old.chromeWrites-oldWrites,new.chromeWrites-newWrites))
        end
        local util=new.env.FluxButtonUtil
        local style=new.env.Flux.EBS.Style
        local button=new.combat.Buttons[1]
        local prior=new.ringFits
        util:SyncFluxButtonLayerSizesToWidget(button)
        assert(new.ringFits==prior+1,"direct utility sync still sizes the ring")
        local adjust=util.AdjustRingBorderSizeForClient
        local customCalls=0
        function util:AdjustRingBorderSizeForClient(...)
            customCalls=customCalls+1
            return adjust(self,...)
        end
        prior=new.ringFits
        style.RefreshSqueezeChrome(button,36,45)
        assert(customCalls==1 and new.ringFits==prior+2,"replacement adjusters still own their full path")
        util.AdjustRingBorderSizeForClient=adjust
        local sizeRing=style.SizeRing
        local styled=0
        function style.SizeRing(...)
            styled=styled+1
            return sizeRing(...)
        end
        style.RefreshSqueezeChrome(button,34,45)
        assert(styled==2,"replacement style keeps the previous call cadence")
        style.SizeRing=sizeRing
        new.locked=true
        local writes=new.chromeWrites
        new.combat:Relayout(true);new.noncombat:Relayout(true)
        assert(new.chromeWrites==writes,"combat leaves the same pending layout without native chrome writes")
    end
end
print("Strip grid packing passes both client shapes, changed squeeze and occupancy, repair, binding, batch and lockdown.")
