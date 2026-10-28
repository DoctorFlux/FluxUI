-- The opt-in capture must remain read-only, bounded and safe for false/secrets.
local env = setmetatable({}, { __index = _G }); env._G = env
local timers, writes = {}, 0
local secret = {}
env.issecretvalue = function(v) return v == secret end
env.SlashCmdList = {}
env.CreateFrame = function() error("input diagnostics must not install a permanent driver") end
env.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
env.InCombatLockdown = function() return false end
env.FluxEditModeBusy = function() return false end
local frame = { GetName = function() return "FluxUnitFrameOuter_player" end, IsShown = function() return true end,
    IsMouseClickEnabled = function() return false end, GetWidth = function() return secret end,
    GetHeight = function() return 80 end, GetAttribute = function(_, key) if key == "unit" then return "player" end end,
    GetParent = function() end, GetScript = function() return env.SecureUnitButton_OnClick end,
    EnableMouse = function() writes = writes + 1 end }
env.SecureUnitButton_OnClick = function() end
env.FluxUnitFrameOuter_player = frame
env.StanceBar = { IsShown = function() return true end, IsShownBase = function() return false end }
env.PlayerFrame = { PlayerFrameContainer = { IsShown = function() return false end },
    PlayerFrameContent = { IsShown = function() return false end } }
env.GetMouseFoci = function() return { frame } end
env.issecurevariable = function() return false, "_FluxUI" end
env.C_ClickBindings = { GetBindingType = function() return 0 end, GetEffectiveInteractionButton = function() return "LeftButton" end }
env.C_CVar = { GetCVar = function(key) assert(key == "taintLog"); return "0" end }
frame.IsProtected = function() return true, false end
local ns = { Flux = {} }
assert(loadfile("Other/FluxInputDebug.lua", "t", env))("_FluxUI", ns)
assert(env.FluxPerfCaptureDB == nil and #timers == 0, "diagnostics are inactive until explicitly requested")
local s = ns.Flux.InputDebug.Capture()
assert(s.frames.FluxUnitFrameOuter_player.clicks == false, "false input states are not discarded")
assert(s.frames.FluxUnitFrameOuter_player.width == "secret", "secret dimensions are not compared or serialized")
assert(s.frames.FluxUnitFrameOuter_player.unitClickHandler, "native click handler identity captured")
assert(s.frames.FluxUnitFrameOuter_player.security.Show.owner == "_FluxUI", "taint owner captured read-only")
assert(s.clickBindings.LeftButton.bindingType == 0, "native click binding type captured")
assert(s.taintLog == "0" and s.complete and s.schema == 2, "logging mode and capture completion recorded")
assert(s.frames.FluxUnitFrameOuter_player.protected and s.frames.FluxUnitFrameOuter_player.explicitProtected == false,
    "inherited and explicit protection distinguished")
assert(s.frames.StanceBar.shown and s.frames.StanceBar.shownBase == false,
    "native logical shown state is distinct from physical widget state")
assert(s.frames["PlayerFrame.PlayerFrameContainer"].shown == false and s.frames["PlayerFrame.PlayerFrameContent"].shown == false,
    "nested player artwork containers are recorded without changing their state")
frame.GetScript = function() error("OnClick not supported on this native frame") end
frame.GetParent = function() error("forbidden native parent read") end
s = ns.Flux.InputDebug.Capture()
assert(s.complete and s.frames.FluxUnitFrameOuter_player.height == 80, "restricted script/parent reads do not abort capture")
assert(s.nativeGrids==nil,"expanded grid diagnostics remain opt-in")
env.MultiBarBottomLeft={actionButtons={{GetName=function()return "MultiBarBottomLeftButton1"end,
    container={SetShown=function()error("diagnostics must not change a native container")end},
    GetAttribute=function(_,key)assert(key=="statehidden");return false end,
    SetShown=function()error("diagnostics must not show a native button")end},secret}}
env.GetMultiActionBars=function()error("diagnostics must not initialize Blizzard's lazy bar cache")end
env.SpellBookFrameMixin={ShouldDisplaySpellBookItem=function()error("diagnostics must not invoke native filter")end}
s=ns.Flux.InputDebug.Capture(true)
local grid=s.nativeGrids.MultiBarBottomLeft
assert(grid.security.numButtonsShowable.owner=="_FluxUI" and grid.buttons[1].security.GetShowGrid.owner=="_FluxUI",
    "grid and button field taint owners captured")
assert(grid.buttons[1].entry[1].owner=="_FluxUI" and grid.buttons[1].statehidden==false,
    "native list-entry ownership and false visibility attribute retained")
assert(grid.buttons[2]==nil and s.spellbookMixins.frame.ShouldDisplaySpellBookItem.owner=="_FluxUI",
    "secret list entries skipped and native filter ownership recorded")
env.SlashCmdList.FLUXINPUT(); env.SlashCmdList.FLUXINPUT()
assert(#timers == 1, "repeated requests cannot accumulate delayed snapshots")
timers[1]()
assert(writes == 0 and env.FluxPerfCaptureDB.inputDebug.foci[1][1].name == frame:GetName(), "capture does not change input or native state")
env.SlashCmdList.FLUXINPUT("grid")
assert(env.FluxPerfCaptureDB.inputDebug.nativeGrids and #timers==2,"grid slash command enables bounded expanded evidence")
timers[2]()
assert(env.FluxPerfCaptureDB.inputDebug.gridsBefore.MultiBarBottomLeft and writes==0,"before/after grid evidence stays read-only")
print("Input diagnostics: read-only capture, secrets, false/protected states, restricted reads, click routing, logging mode, bounded callback passed")
