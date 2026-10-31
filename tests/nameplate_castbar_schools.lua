-- Nameplate lifecycle and native ownership model; no native taint/pixel claim.
local checks = 0
local function check(value, label) checks = checks + 1; assert(value, label) end

for _, branch in ipairs({"retail", "forever", "era", "anniversary"}) do
    local secret = {}
    local calls = {begin = {}, reset = 0, finish = 0, hooks = 0, frames = 0}
    local plate = {}
    local bar = {shown = false, casting = false, level = 100, fill = {}, nativeWrites = 0}
    function bar:IsShown() return self.shown end
    function bar:GetStatusBarTexture() return self.fill end
    function bar:GetFrameLevel() return self.level end
    local uf = {CastBarsContainer = {castBar = bar}}
    local module
    local fx = {
        Attach = function(proxy) proxy.attached = true end,
        Reset = function(proxy)
            calls.reset = calls.reset + 1
            proxy._fluxSchoolCast = nil
        end,
        Begin = function(proxy, unit, id, name, trade, eventID, nameplate)
            calls.begin[#calls.begin + 1] = {proxy, unit, id, name, trade, eventID, nameplate}
            proxy._fluxSchoolCast = {id = id}
        end,
        Finish = function() calls.finish = calls.finish + 1 end,
    }
    local mixin = {
        HandleCastStart = function(self) self.shown = true; self.casting = true end,
        FinishSpell = function(self) self.casting = false end,
        HandleInterruptOrSpellFailed = function(self) self.casting = false end,
    }
    for key, method in pairs(mixin) do bar[key] = method end
    local env = setmetatable({NamePlateCastingBarMixin = mixin}, {__index = _G})
    env.CreateFrame = function(_, _, parent)
        calls.frames = calls.frames + 1
        local frame = {parent = parent}
        function frame:SetAllPoints(target) self.target = target end
        function frame:ClearAllPoints() self.target = nil end
        function frame:SetFrameLevel(level) self.level = level end
        function frame:EnableMouse(value) self.mouse = value end
        function frame:SetParent(value) self.parent = value end
        function frame:Show() self.shown = true end
        function frame:Hide() self.shown = false end
        return frame
    end
    env.hooksecurefunc = function(object, method, callback)
        calls.hooks = calls.hooks + 1
        local original = object[method]
        object[method] = function(...)
            original(...)
            callback(...)
        end
    end
    local currentName, currentID, currentTrade = "Fireball", 133, false
    local channelName, channelID, channelEmpowered = "Frost Channel", 116, false
    env.UnitCastingInfo = function()
        return currentName, currentName, nil, 0, 1000, currentTrade, nil, false, currentID
    end
    env.UnitChannelInfo = function()
        return channelName, channelName, nil, 0, 1000, false, false, channelID, channelEmpowered
    end
    local ns = {
        Flux = {NamePlates = {
            RegisterModule = function(_, value) module = value; return value end,
            GetParts = function() return uf, plate end,
        }},
        CastBarThemes = fx,
        CastBarSchools = {Plain = function(value) if value == secret then return nil end; return value end},
    }
    local loader = assert(loadfile("NamePlates/CastBarSchools.lua", "t", env))
    loader("_FluxUI", ns)

    module.Added("nameplate1")
    check(calls.frames == 1 and calls.hooks == 3, branch .. " installs one Flux host and native post-hooks")
    local start = bar.HandleCastStart
    start(bar, "UNIT_SPELLCAST_START")
    local first = calls.begin[#calls.begin]
    check(first[2] == "nameplate1" and first[3] == 133 and first[4] == "Fireball" and first[7] == true,
        branch .. " normal cast routes accessible identity to shared themes")
    check(first[1].TimerBar == bar and first[1].target == bar and first[1].mouse == false,
        branch .. " Flux host follows Blizzard status bar without input ownership")
    check(bar.nativeWrites == 0 and bar.fill ~= nil, branch .. " Blizzard bar remains the progress owner")
    start(bar, "UNIT_SPELLCAST_CHANNEL_START")
    check(calls.begin[#calls.begin][3] == 116, branch .. " channel uses channel spell ID")
    bar:FinishSpell()
    check(calls.finish == 1 and first[1].casting == false, branch .. " completion stops Flux emission")
    bar:HandleInterruptOrSpellFailed()
    check(first[1]._fluxSchoolCast == nil, branch .. " interruption clears theme")

    currentName, currentID = secret, secret
    local prior = #calls.begin
    start(bar, "UNIT_SPELLCAST_START")
    check(#calls.begin == prior and first[1]._fluxSchoolCast == nil,
        branch .. " secret identity leaves native appearance")
    channelName, channelID = secret, secret
    start(bar, "UNIT_SPELLCAST_CHANNEL_START")
    check(#calls.begin == prior and first[1]._fluxSchoolCast == nil,
        branch .. " secret channel identity leaves native appearance")
    channelID, channelEmpowered = false, true
    start(bar, "UNIT_SPELLCAST_CHANNEL_START")
    check(#calls.begin == prior and first[1]._fluxSchoolCast == nil,
        branch .. " missing channel ID never borrows the empowered flag as a spell ID")
    channelName, channelID, channelEmpowered = "Frost Channel", 116, false
    currentName, currentID = "Frostbolt", 116
    start(bar, "UNIT_SPELLCAST_START")
    bar.shown = false
    module.Poll()
    check(first[1]._fluxSchoolCast == nil, branch .. " hidden bar clears theme")
    module.Removed("nameplate1")
    check(first[1].shown == false, branch .. " removal hides Flux host")
    module.Added("nameplate2")
    check(calls.frames == 1 and calls.hooks == 3, branch .. " recycled plate reuses host and hooks")
    check(first[1].shown == true, branch .. " recycled host becomes visible")
end
print("PASS nameplate cast-bar themes: " .. checks .. " checks; native taint/pixels pending")
