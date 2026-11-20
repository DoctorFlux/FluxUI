-- Exercise the real squeeze notifier and pet layout with public widget mocks.
local function Read(path, checkpoint)
    local file = assert(io.open(checkpoint and checkpoint .. "/" .. path:gsub("/", "-") or path, "rb"))
    local source = file:read("*a")
    file:close()
    return (source:gsub("\r\n", "\n"))
end

local function Fixture(checkpoint, classic)
    local s = { factor = .8, offset = 0, counts = {}, queued = {} }
    local function Hit(key) s.counts[key] = (s.counts[key] or 0) + 1 end
    local env = setmetatable({}, { __index = _G })
    env._G = env
    local function Widget(parent)
        local f = { points = {}, width = 1, height = 1, scale = 1, parent = parent, shown = false }
        function f:SetSize(w, h) self.width, self.height = w, h; Hit("size") end
        function f:GetSize() return self.width, self.height end
        function f:SetScale(scale) self.scale = scale; Hit("scale") end
        function f:GetScale() return self.scale end
        function f:SetParent(p) self.parent = p; Hit("parent") end
        function f:GetParent() return self.parent end
        function f:SetPoint(...) self.points[#self.points + 1] = {...}; Hit("point") end
        function f:ClearAllPoints() self.points = {}; Hit("clear") end
        function f:GetNumPoints() return #self.points end
        function f:GetPoint(i) return table.unpack(self.points[i]) end
        function f:SetClipsChildren(clip) self.clip = clip; Hit("clip") end
        function f:DoesClipChildren() return self.clip end
        function f:Show() self.shown = true; Hit("show") end
        function f:IsShown() return self.shown end
        return f
    end
    env.CreateFrame = function(_, _, parent) return Widget(parent) end
    env.InCombatLockdown = function() return s.locked end
    env.FluxUILayoutSqueeze = { GetEffectiveEmulatedDependentXFactorForUnitFrames = function() return s.factor end }
    local root, buttons = Widget(), {}
    for i = 1, 10 do buttons[i] = { Widget = Widget(root), PetAutoCastAllowed = true } end
    local pet = {
        CONFIG = { buttonSize = 38, buttonPadding = 1, totalButtons = 10, columns = 5, rows = 2 },
        GetFrame = function() return root end,
        GetAllButtons = function() return buttons end,
        UpdatePosition = function() root.offset = s.offset; Hit("position") end,
    }
    local function RefreshChrome(btn, w, h)
        btn.Widget._fluxLayoutW, btn.Widget._fluxLayoutH = w, h
        Hit("chrome")
    end
    local flux = {
        Client = { isAnyClassic = classic, isPostDF = not classic },
        Bars = { Pet = pet, Stance = { RequestSizeOnly = function() Hit("stance") end } },
        Combat = { InLockdown = env.InCombatLockdown, Defer = function(key, fn) s.queued[key] = fn end },
        EBS = {
            Style = { RefreshSqueezeChrome = RefreshChrome },
            Paint = { UpdateAutocast = function(btn, allowed, enabled)
                btn.PetAutoCastAllowed, btn.PetAutoCastEnabled = not not allowed, not not enabled
                Hit("autocast")
            end },
        },
    }
    env.Flux = flux
    env.FluxBorder = {
        ApplyTo = function(frame) frame.FluxBorderFrame = frame.FluxBorderFrame or {}; Hit("borderAttach") end,
        Junctions = { CommitLayout = function() Hit("commit") end },
    }
    local source = Read("FluxDefaultSettings.lua", checkpoint)
    local begin = assert(source:find("-- Squeeze callback bodies are shared across notifications.", 1, true))
    local finish = assert(source:find("local squeezeRefreshScheduled", begin, true))
    assert(load(source:sub(begin, finish - 1), "@actual-squeeze-notifier", "t", env))()
    assert(load(Read("Bars/Pet/Layout.lua", checkpoint), "@actual-pet-layout", "t", env))("_FluxUI", { Flux = flux })
    s.env, s.pet, s.flux, s.buttons, s.Widget = env, pet, flux, buttons, Widget
    s.cross = function() env.FluxUILayoutSqueeze.NotifyLayoutDependents(true, true) end
    s.signature = function()
        local parts = {root.width, root.height, root.offset}
        for _, btn in ipairs(buttons) do
            local slot, face = btn.SlotFrame, btn.Widget
            local sp, p, rp, x, y = slot:GetPoint(1)
            local wp, owner, wrp, wx, wy = face:GetPoint(1)
            assert(p == root and slot:GetParent() == root and face:GetParent() == slot and owner == slot)
            for _, value in ipairs({slot.width, slot.height, sp, rp, x, y, tostring(slot.clip), tostring(slot.shown),
                face.width, face.height, face.scale, wp, wrp, wx, wy, tostring(face.shown),
                face._fluxLayoutW, face._fluxLayoutH}) do parts[#parts + 1] = value end
        end
        return table.concat(parts, "|")
    end
    pet.LayoutButtons()
    s.counts = {}
    return s
end

for _, classic in ipairs({false, true}) do
    local a, b = Fixture(arg[1], classic), Fixture(nil, classic)
    local metrics = {"size", "point", "parent", "clip", "chrome", "autocast"}
    for step = 1, 8 do
        a.offset, b.offset = step % 2 == 1 and 20 or 0, step % 2 == 1 and 20 or 0
        a.cross(); b.cross()
        assert(a.signature() == b.signature(), "pet slots and root movement match")
    end
    assert(b.counts.position == 8 and b.counts.borderAttach == 8 and not b.counts.commit,
        "pet position and border adoption finish before the caller's commit")
    local counts = {}
    for _, key in ipairs(metrics) do
        assert(not b.counts[key], "settled slots skip " .. key)
        if arg[1] then assert((a.counts[key] or 0) > 0, "baseline exercised " .. key) end
        counts[#counts + 1] = ("%s=%d/%d"):format(key, a.counts[key] or 0, b.counts[key] or 0)
    end
    print(("PET_STRIP_PACKING|%s|%s"):format(classic and "classic" or "post-DF", table.concat(counts, "|")))

    local function Repairs(corrupt, check)
        b.counts = {}
        corrupt()
        b.cross()
        assert(b.counts.chrome == 10, "uncertain or changed packing takes the native writer")
        assert(not check or check(), "ordinary packing restores current native geometry")
        assert(not b.counts.commit, "repaired slots also use the parent border commit")
    end
    local btn = b.buttons[5]
    Repairs(function() btn.Widget.width = 1 end, function() return btn.Widget.width == 44 * b.factor end)
    Repairs(function() btn.SlotFrame:SetPoint("TOPRIGHT") end, function() return btn.SlotFrame:GetNumPoints() == 1 end)
    Repairs(function() btn.SlotFrame.clip = not btn.SlotFrame.clip end, function() return btn.SlotFrame.clip == not classic end)
    Repairs(function() btn.Widget = b.Widget() end, function() return btn.Widget:GetParent() == btn.SlotFrame end)
    Repairs(function() b.factor = .7 end, function() return btn.Widget.width == 44 * b.factor end)
    Repairs(function() btn.PetAutoCastEnabled = true end)
    local clip = btn.SlotFrame.DoesClipChildren
    Repairs(function() btn.SlotFrame.DoesClipChildren = false end)
    local secret = setmetatable({}, {__eq = function() error("compared private scale") end})
    b.env.issecretvalue = function(value) return rawequal(value, secret) end
    local scale = btn.Widget.GetScale
    Repairs(function()
        btn.SlotFrame.DoesClipChildren = clip
        btn.Widget.GetScale = function() return secret end
    end)
    btn.Widget.GetScale = scale
    b.counts = {}; b.locked = true; b.cross()
    assert(not next(b.counts) and b.queued["layout.squeeze.dependents"], "combat leaves protected layout untouched")
    b.locked = false; b.queued["layout.squeeze.dependents"]()
    assert(b.counts.chrome == 10 and b.counts.commit == 1, "ordinary change deferral still applies full layout")
end
print("Pet packing remains aligned through fast strip crossings, native drift, real squeeze and combat deferral.")
