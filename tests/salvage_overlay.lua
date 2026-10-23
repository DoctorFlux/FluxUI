-- lua tests/salvage_overlay.lua; exercises the real overlay with strict UI mocks.
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end
local function near(a, b) return type(a) == "number" and math.abs(a - b) < 0.00001 end
local noop = function() end
local path = "Salvage/FluxSalvage_Overlay.lua"
local file = assert(io.open(path, "r"))
local source = file:read("*a")
file:close()

local function fixture(branch, options, code)
    options = options or {}
    local env = setmetatable({}, { __index = _G })
    env._G, env.frames, env.atlasCalls = env, {}, 0
    env.combat, env.drivers, env.shines = false, {}, {}
    env.unpack = table.unpack
    env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_ID = 1, (branch == "live" or branch == "forever") and 1 or 2
    env.InCombatLockdown = function() return env.combat end
    env.CreateColor = function(r, g, b)
        return { GetRGB = function() return r, g, b end }
    end
    env.Flux = {
        Client = { isCamelot = branch == "forever", isForever = branch == "forever" },
        Restricted = { Works = function() return branch ~= "forever" end },
    }
    local function atlasInfo()
        if options.queryError then error("atlas metadata unavailable") end
        return options.atlas and { width = 256, height = 256 } or nil
    end
    if options.probe == "cap" then
        env.Flux.Cap = { HasAtlas = function() return options.atlas end }
    elseif options.probe == "legacy" then
        env.GetAtlasInfo = atlasInfo
    elseif options.probe ~= "none" then
        env.C_Texture = { GetAtlasInfo = atlasInfo }
    end
    local function texture()
        local t = { shown = true }
        function t:SetAllPoints(owner) self.allPoints = owner end
        function t:SetPoint(...) self.point = { ... } end
        function t:SetColorTexture(...) self.colorTexture = { ... } end
        function t:SetVertexColor(...) self.vertexColor = { ... } end
        function t:SetSize(w, h) self.width, self.height = w, h end
        function t:SetHeight(h) self.height = h end
        function t:SetWidth(w) self.width = w end
        function t:GetHeight() return self.height or 4 end
        function t:GetWidth() return self.width or 4 end
        function t:SetDesaturated(value) self.desaturated = value end
        function t:SetAtlas(atlas)
            env.atlasCalls = env.atlasCalls + 1
            if options.setAtlasError then error("atlas unavailable to texture") end
            self.atlas, self.painted = atlas, options.atlas
        end
        return t
    end
    env.CreateFrame = function(_, name, parent, template)
        local protected = template and template:find("Secure", 1, true)
        assert(not protected or not env.combat, "protected frame creation during combat")
        local f = { parent = parent, scripts = {}, hooks = {}, events = {}, attrs = {},
            textures = {}, animations = {}, shown = true, protected = protected, width = 32, height = 32 }
        local function mutate()
            assert(not protected or not env.combat, "protected frame mutation during combat")
        end
        function f:SetScript(event, callback) self.scripts[event] = callback end
        function f:HookScript(event, callback)
            self.hooks[event] = self.hooks[event] or {}
            self.hooks[event][#self.hooks[event] + 1] = callback
        end
        function f:RunScript(event, ...)
            if self.scripts[event] then self.scripts[event](self, ...) end
            for _, callback in ipairs(self.hooks[event] or {}) do callback(self, ...) end
        end
        function f:RegisterEvent(event) self.events[event] = true end
        function f:SetAttribute(key, value)
            mutate()
            if self.attrs[key] ~= value then
                self.attrs[key] = value
                self:RunScript("OnAttributeChanged", key, value)
            end
        end
        function f:GetAttribute(key) return self.attrs[key] end
        function f:Show()
            mutate()
            if not self.shown then self.shown = true; self:RunScript("OnShow") end
        end
        function f:Hide()
            mutate()
            if self.shown then self.shown = false; self:RunScript("OnHide") end
        end
        function f:IsShown() return self.shown end
        function f:ClearAllPoints() mutate(); self.point = nil end
        function f:SetPoint(...) mutate(); self.point = { ... } end
        function f:SetSize(w, h) mutate(); self.width, self.height = w, h end
        function f:GetSize() return self.width, self.height end
        function f:GetScale() return 0.5 end
        function f:GetScaledRect() return 100, 50, 32, 32 end
        function f:GetFrameLevel() return 3 end
        function f:SetFrameLevel(level) mutate(); self.level = level end
        function f:EnableMouse(value) mutate(); self.mouse = value end
        function f:CreateTexture()
            local t = texture()
            self.textures[#self.textures + 1] = t
            return t
        end
        function f:CreateAnimationGroup()
            local group = { plays = 0, stops = 0, animations = {} }
            function group:SetLooping(value) self.looping = value end
            function group:Play() self.plays = self.plays + 1; self.playing = true end
            function group:Stop() self.stops = self.stops + 1; self.playing = false end
            function group:CreateAnimation(kind)
                local a = { kind = kind }
                function a:SetTarget(value) self.target = value end
                function a:SetDuration(value) self.duration = value end
                function a:SetFlipBookColumns(value) self.columns = value end
                function a:SetFlipBookRows(value) self.rows = value end
                function a:SetFlipBookFrames(value) self.frames = value end
                self.animations[#self.animations + 1] = a
                return a
            end
            self.animations[#self.animations + 1] = group
            return group
        end
        f.SetFrameStrata, f.SetToplevel, f.RegisterForClicks = noop, noop, noop
        if template and template:find("AutoCastShineTemplate", 1, true) then
            f.sparkles = { texture(), texture() }
        end
        env.frames[#env.frames + 1] = f
        if name then env[name] = f end
        return f
    end
    env.UIParent = env.CreateFrame("Frame")
    env.owner = env.CreateFrame("Button")
    env.GameTooltip = { GetOwner = function() return env.owner end }
    env.C_Spell = { GetSpellName = function(id) return "Spell " .. id end }
    env.RegisterAttributeDriver = function(frame, key, driver)
        assert(not env.combat, "attribute driver changed during combat")
        env.drivers[#env.drivers + 1] = { frame, key, driver }
    end
    if options.shine then
        env.AutoCastShine_AutoCastStart = function(frame, ...)
            env.shines[#env.shines + 1] = { ... }
            frame.shining = true
        end
        env.AutoCastShine_AutoCastStop = function(frame) frame.shining = false end
    end
    env.FluxSalvage = {
        GetModifier = function() return env.modifier or "ALT" end,
        ModifierActive = function() return true end,
        ModifierReleased = function() return false end,
        RegisterModifierCallback = function(callback) env.modifierCallback = callback end,
    }
    env.fire = function(event)
        for _, f in ipairs(env.frames) do
            if f.events[event] then f:RunScript("OnEvent", event) end
        end
    end
    assert(load(code or source, "@" .. path, "t", env))()
    return env, env.FluxSalvage, env.FluxSalvage.Overlay
end

local function exercise(branch, options, code)
    local env, S, overlay = fixture(branch, options, code)
    local label = branch .. ": "
    local nativeShine = options.shine
    local atlas = not nativeShine and options.atlas and not options.setAtlasError
        and not options.queryError and options.probe ~= "none"
    check(not overlay:IsShown(), label .. "overlay starts hidden")
    check(#overlay.textures == (nativeShine and 0 or 1), label .. "one persistent custom texture")
    check(#overlay.animations == (atlas and 1 or 0), label .. "animate only a usable flipbook")
    if not nativeShine then
        local t = overlay.textures[1]
        if atlas then
            check(t.atlas == "UI-HUD-ActionBar-Proc-Loop-Flipbook" and t.painted and t.desaturated,
                label .. "preserve the available native proc atlas")
            local group, anim = overlay.animations[1], overlay.animations[1].animations[1]
            check(group.looping == "REPEAT" and anim.kind == "FlipBook" and anim.target == t
                and anim.duration == 1 and anim.columns == 5 and anim.rows == 6 and anim.frames == 30,
                label .. "preserve native animation timing")
        else
            check(t.allPoints == overlay and t.colorTexture and t.colorTexture[1] == 1
                and t.colorTexture[2] == 1 and t.colorTexture[3] == 1
                and t.colorTexture[4] > 0 and t.colorTexture[4] < 1,
                label .. "missing/unusable atlas has a visible, tintable translucent fill")
        end
        if not options.atlas or options.queryError or options.probe == "none" then
            check(env.atlasCalls == 0, label .. "do not assign an unverified atlas")
        end
    else
        check(overlay.sparkles[1]:GetWidth() == 12 and overlay.sparkles[1]:GetHeight() == 12,
            label .. "preserve native shine size")
    end
    for _, rgb in ipairs({ { 1, 0, 0 }, { 0, 1, 0 }, { 0.6, 0, 0.8 }, { 0, 0.5, 1 }, { 1, 1, 1 } }) do
        local color = env.CreateColor(table.unpack(rgb))
        S.ApplySpellToBagSlot(0, 2, 1804, color, env.owner)
        check(overlay:IsShown() and overlay:GetAttribute("target-bag") == 0
            and overlay:GetAttribute("target-slot") == 2, label .. "bag-slot overlay remains interactive")
        check(overlay:GetAttribute("type1") == "spell" and overlay:GetAttribute("typerelease") == "spell"
            and overlay:GetAttribute("spell") == (branch == "forever" and "Spell 1804" or 1804),
            label .. "retain client-specific secure spell action")
        local paintedColor = nativeShine and env.shines[#env.shines] or overlay.textures[1].vertexColor
        check(paintedColor and near(paintedColor[1], rgb[1]) and near(paintedColor[2], rgb[2])
            and near(paintedColor[3], rgb[3]), label .. "retain salvage family color")
        check(overlay.point[1] == "BOTTOMLEFT" and overlay.point[4] == 200 and overlay.point[5] == 100
            and overlay.width == 64 and overlay.height == 64, label .. "preserve scaled item anchoring")
        if atlas then
            local t = overlay.textures[1]
            check(near(t.width, 64 * 1.4) and near(t.height, 64 * 1.4)
                and overlay.animations[1].playing, label .. "preserve glow extent/play state")
        elseif not nativeShine then
            check(overlay.textures[1].allPoints == overlay and not overlay.textures[1].width,
                label .. "fallback fill follows item bounds without oversizing")
        end
        S.SetOverlayColor(nil)
        S.HideOverlay()
        check(not overlay:IsShown() and overlay.scripts.OnUpdate == nil
            and overlay:GetAttribute("spell") == nil, label .. "hide clears active action/update")
        if atlas then check(not overlay.animations[1].playing, label .. "hidden flipbook stops") end
        if nativeShine then check(not overlay.shining, label .. "hidden native shine stops") end
    end
    check(#overlay.textures == (nativeShine and 0 or 1)
        and #overlay.animations == (atlas and 1 or 0), label .. "reuse artwork across repeated hovers")

    -- Appearance updates are legal in combat; secure setup and tooltip arming are not.
    env.combat = true
    S.SetOverlayColor(env.CreateColor(0.2, 0.4, 0.6))
    S.HandleTooltip({ IsForbidden = function() return false end })
    S.OnModifierChanged()
    check(not overlay:IsShown() and overlay:GetAttribute("spell") == nil, label .. "combat cannot arm salvage")
    local ran, drivers = 0, #env.drivers
    S.Defer(function() ran = ran + 1 end)
    env.modifier = "CTRL"
    env.modifierCallback()
    env.fire("PLAYER_REGEN_ENABLED")
    check(ran == 0 and #env.drivers == drivers, label .. "protected work waits through lockdown")
    env.combat = false
    env.fire("PLAYER_REGEN_ENABLED")
    env.fire("PLAYER_REGEN_ENABLED")
    check(ran == 1 and #env.drivers == drivers + (branch == "forever" and 0 or 1),
        label .. "deferred work flushes once; Forever retains its non-snippet route")
end

for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    exercise(branch, { atlas = true })
    exercise(branch, { atlas = false })
    exercise(branch, { atlas = true, setAtlasError = true })
    exercise(branch, { atlas = true, probe = "cap" })
    exercise(branch, { atlas = false, probe = "cap" })
    exercise(branch, { atlas = true, probe = "legacy" })
    exercise(branch, { atlas = false, probe = "legacy" })
    exercise(branch, { atlas = true, queryError = true })
    exercise(branch, { probe = "none" })
    exercise(branch, { shine = true })
end

-- Verify the behavioral checks catch regressions, including blank and miscolored fills.
local function rejectsMutation(label, old, replacement, expectedFailure)
    local first, last = source:find(old, 1, true)
    check(first ~= nil, "mutation target exists: " .. label)
    local mutated = source:sub(1, first - 1) .. replacement .. source:sub(last + 1)
    local ok, err = pcall(exercise, "forever", { atlas = false }, mutated)
    check(not ok and tostring(err):find(expectedFailure, 1, true),
        "coverage rejects mutation at the intended assertion: " .. label .. ": " .. tostring(err))
end
rejectsMutation("invisible fill", "OverlayFill:SetColorTexture(1, 1, 1, 0.2)", "OverlayFill:SetColorTexture(1, 1, 1, 0)",
    "missing/unusable atlas has a visible, tintable translucent fill")
rejectsMutation("lost family tint", "OverlayFill:SetVertexColor(color:GetRGB())", "OverlayFill:SetVertexColor(1, 1, 1)",
    "retain salvage family color")
rejectsMutation("unverified atlas", "HasProcAtlas(atlas) and Glow.SetAtlas", "Glow.SetAtlas",
    "animate only a usable flipbook")
print("salvage overlay: " .. checks .. " checks passed (five client fixtures, missing-atlas and mutation coverage)")
