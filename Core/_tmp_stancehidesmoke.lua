-- lua Core/_tmp_stancehidesmoke.lua
-- Actual Core/bar modules and Blizzard's HANDLE:Hide implementation. This checks
-- dispatch/behavior, not the game engine's taint tracking.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function Load(path, env, ns)
    local chunk
    if setfenv then chunk = assert(loadfile(root .. path)); setfenv(chunk, env)
    else chunk = assert(loadfile(root .. path, "t", env)) end
    return chunk("_FluxUI", ns)
end
local function Compile(source, env)
    if setfenv then local fn = assert(loadstring(source)); setfenv(fn, env); return fn end
    return assert(load(source, "restricted fixture", "t", env))
end
local f = assert(io.open(root .. "../__AddonsForRef/wow-ui-source-live/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua", "r"))
local source = f:read("*a"); f:close()
local a = assert(source:find("function HANDLE:Hide(skipAttr)", 1, true))
local b = assert(source:find("function HANDLE:SetID", a, true))
local hideSource = source:sub(a, b - 1)

local function Boot(family, options)
    family, options = family or "live", options or {}
    local locked, restricted, frames, pending, output = false, false, {}, {}, {}
    local headers, wrapped, baseHides, originalShows, attributeWrites = 0, 0, 0, 0, 0
    local ui, ns, native = {}, {}, {}
    local function Forbidden() error("native override/geometry/mouse or state driver was touched", 2) end
    local HANDLE = {}
    Compile(hideSource, { HANDLE = HANDLE, GetHandleFrame = function(handle) return handle.frame end,
        LOCAL_CHECK_Frame = {
            Hide = function(frame)
                assert(restricted, "stock hide did not run through a restricted frame handle")
                baseHides = baseHides + 1
                frame._state.shown = false
            end,
            SetAttribute = function() attributeWrites = attributeWrites + 1 end,
        },
    })()
    local function Handle(frame) return setmetatable({ frame = frame }, { __index = HANDLE }) end
    local function RunSnippet(body, selfHandle, control)
        local env = setmetatable({ self = selfHandle, control = control }, { __index = _G })
        restricted = true
        local ok, allow, message = pcall(Compile(body, env))
        restricted = false
        assert(ok, allow)
        return allow, message
    end
    local env = setmetatable({
        UIParent = ui, SlashCmdList = {},
        issecurevariable = function() return true end, issecretvalue = function() return false end,
        GetTime = function() return 10 end,
        GetBuildInfo = function() return "12.1.5", "70391", "", 120105 end,
        IsLoggedIn = function() return false end,
        print = function(message) output[#output + 1] = message end,
        geterrorhandler = function() return function(err) error(err, 0) end end,
        RegisterStateDriver = Forbidden, UnregisterStateDriver = Forbidden, hooksecurefunc = Forbidden,
        C_Timer = { After = function(_, fn) pending[#pending + 1] = fn end },
        CreateFrame = function(kind, name, parent, template)
            assert(kind == "Frame")
            local frame = { events = {}, scripts = {}, refs = {}, name = name }
            function frame:RegisterEvent(event) self.events[event] = true end
            function frame:UnregisterEvent(event) self.events[event] = nil end
            function frame:SetScript(script, fn) self.scripts[script] = fn end
            function frame:Hide() self.hidden = true end
            function frame:SetSize() end
            function frame:SetPoint() end
            if template then
                assert(template == "SecureHandlerBaseTemplate" and not locked)
                headers = headers + 1
                local control = { GetFrameRef = function(_, key) return frame.refs[key] end }
                function frame:SetFrameRef(key, ref) assert(not locked); self.refs[key] = Handle(ref) end
                function frame:Execute(body) assert(not locked); return RunSnippet(body, control, control) end
                function frame:WrapScript(button, script, pre, post)
                    assert(not locked and script == "OnShow" and select(2, button:IsProtected()))
                    if options.failWrap then error("simulated wrap failure") end
                    assert(not button._wrapped, "duplicate wrapper")
                    wrapped = wrapped + 1
                    button._wrapped = function()
                        local allow, message = RunSnippet(pre, Handle(button), control)
                        if allow ~= false then button._originalShow() end
                        if post and message ~= nil then RunSnippet(post, Handle(button), control) end
                    end
                end
            end
            frames[#frames + 1] = frame
            return frame
        end,
    }, { __index = _G })
    env._G = env
    Load("Core/Flux.lua", env, ns)
    ns.Flux.Client = { isLiveMidnight = family == "live", isRetail = family ~= "classic", isPostDF = family ~= "classic",
        isCamelot = family == "forever", isForever = family == "forever", isAnyClassic = family == "classic" }
    ns.Flux.Bars = { NUM_NATIVE = 0 }
    ns.Flux.Combat = { InLockdown = function() return locked end, Defer = function(key, fn) pending[key] = fn end }
    ns.Flux.Restricted = { Works = function() return family ~= "forever" end,
        PagingWorks = function() return family ~= "forever" or options.paging == true end }
    local function AddButtons(bar)
        for _ = 1, 10 do
            bar.actionButtons[#bar.actionButtons + 1] = {
                IsProtected = function() return true, true end,
                IsForbidden = function() return false end,
                _originalShow = function() originalShows = originalShows + 1 end,
                Hide = Forbidden, SetAttribute = Forbidden, EnableMouse = Forbidden,
            }
        end
    end
    for _, name in ipairs({ "StanceBar", "StanceBarFrame" }) do
        local state = { parent = ui, shown = true, artHides = 0 }
        local bar = { _state = state, actionButtons = {},
            GetParent = function() return state.parent end,
            SetParent = function(_, parent) assert(family ~= "live"); state.parent = parent end,
            Hide = Forbidden, Show = Forbidden, SetScale = Forbidden, SetPoint = Forbidden, SetAlpha = Forbidden,
            BackgroundArtLeft = { SetAlpha = function() end, SetIgnoreParentAlpha = function() end,
                Hide = function() state.artHides = state.artHides + 1 end },
        }
        if not options.lateButtons then AddButtons(bar) end
        native[name] = { state = state, bar = bar, hide = bar.Hide }
        env[name] = bar
    end
    if options.alias then env.StanceBarFrame = env.StanceBar end
    Load("Bars/Blizzard.lua", env, ns)
    ns.Flux.AfterLoad(function()
        ns.Flux.Bars.Blizzard.Reassert()
    end)
    local function Emit(event, ...)
        for _, frame in ipairs(frames) do if frame.events[event] then frame.scripts.OnEvent(frame, event, ...) end end
    end
    Emit("ADDON_LOADED", "_FluxUI")
    return {
        env = env, ns = ns, native = native, Emit = Emit, output = output, AddButtons = AddButtons,
        Reassert = ns.Flux.Bars.Blizzard.Reassert,
        Lock = function(value) locked = value end,
        Counts = function() return headers, wrapped, baseHides, originalShows, attributeWrites end,
        Show = function(bar, index)
            bar._state.shown = true
            local button = bar.actionButtons[index]
            assert(button._wrapped, "a native stance button was not wrapped")
            button._wrapped()
            assert(not bar._state.shown, "stock stance parent remained visible/interactive")
        end,
    }
end

local live = Boot()
local h, w, hides = live.Counts()
assert(h == 2 and w == 20 and hides == 2)
live.Lock(true)
for _ = 1, 40 do for _, item in pairs(live.native) do for i = 1, 10 do live.Show(item.bar, i) end end end
local h2, w2, _, shows, attributes = live.Counts()
assert(h2 == h and w2 == w and shows == 800 and attributes == 0,
    "combat re-show replaced original scripts, installed handlers, or changed statehidden")
live.Reassert() -- installation must be deferred while the restricted callbacks stay usable
assert(select(1, live.Counts()) == h)
live.Lock(false)
live.Reassert()
assert(select(2, live.Counts()) == w, "reassert duplicated wrappers")
for _, item in pairs(live.native) do assert(item.bar.Hide == item.hide and item.state.parent == live.env.UIParent) end
local restored = Boot()
assert(select(2, restored.Counts()) == 20, "the following reload lost secure stance suppression")

local aliases = Boot("live", { alias = true })
assert(select(1, aliases.Counts()) == 1 and select(2, aliases.Counts()) == 10)
local late = Boot("live", { lateButtons = true })
assert(select(2, late.Counts()) == 0)
for _, item in pairs(late.native) do late.AddButtons(item.bar) end
late.Reassert()
assert(select(2, late.Counts()) == 20)
local wrapOptions = { failWrap = true }
local failed = Boot("live", wrapOptions)
assert(select(2, failed.Counts()) == 0)
wrapOptions.failWrap = false; failed.Reassert()
assert(select(2, failed.Counts()) == 20, "failed wrappers could not be retried")
for _, family in ipairs({ "classic", "forever" }) do
    local client = Boot(family)
    assert(select(1, client.Counts()) == 0 and select(2, client.Counts()) == 0)
    assert(client.native.StanceBar.state.parent ~= client.env.UIParent, "legacy stance parenting changed")
end
local repairedForever = Boot("forever", { paging = true })
assert(select(1, repairedForever.Counts()) == 2 and select(2, repairedForever.Counts()) == 20)
repairedForever.Lock(true)
for _, item in pairs(repairedForever.native) do
    assert(item.state.parent == repairedForever.env.UIParent, "repaired Forever must retain native stance parent")
    repairedForever.Show(item.bar, 1)
end
print("stance hide smoke OK (native HANDLE:Hide, 800 combat shows, original scripts, aliases, late buttons, retries, reload, Classic/Forever)")
