-- lua RaidFrame/_tmp_raidaurassmoke.lua
-- Uses each supplied client's original CUF private-aura methods and original
-- restricted-container registration handlers. Engine registration is mocked;
-- WoW's protected execution and taint propagation still require an in-game check.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local refs = root .. "../__AddonsForRef/"
local function Load(path, env, ns)
    local chunk
    if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, env)
    else chunk = assert(loadfile(path, "t", env)) end
    return chunk("_FluxUI", ns)
end
local function RunSource(source, name, env)
    local chunk
    if setfenv then chunk = assert(loadstring(source, name)); setfenv(chunk, env)
    else chunk = assert(load(source, name, "t", env)) end
    return chunk()
end
local function Mix(target, ...)
    for i = 1, select("#", ...) do
        for k, v in pairs(select(i, ...)) do target[k] = v end
    end
    return target
end
local function Read(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a"); file:close(); return text
end

local function Scenario(family, missingAPI)
    local sourceRoot = refs .. "wow-ui-source-" .. family .. "/Interface/AddOns/"
    local combat, queues, adds, removes, settingsUpdates = false, 0, 0, 0, 0
    local failNextAdd = false
    local violations = {}
    local anchors, registrations, widgets = {}, {}, {}
    local auraData, auraReads = { HELPFUL = {}, HARMFUL = {}, ["HARMFUL|RAID"] = {} }, {}
    local db = { auraFocusMode = "debuff" }
    local function Violation(message)
        violations[#violations + 1] = message
        error(message, 2)
    end
    local function Widget(parent)
        local w = { parent = parent, scripts = {}, attributes = {}, events = {}, shown = true, level = 1 }
        function w:GetParent() return self.parent end
        function w:SetParent(p) self.parent = p end
        function w:GetName() return self.widgetName end
        function w:SetScript(script, fn) self.scripts[script] = fn end
        function w:GetScript(script) return self.scripts[script] end
        function w:HookScript(script, fn)
            local previous = self.scripts[script]
            self.scripts[script] = function(...)
                if previous then previous(...) end
                return fn(...)
            end
        end
        function w:SetAttribute(name, value)
            if combat and self.SetPrivateAuraAnchorUnit then Violation("private-aura attribute write in combat") end
            self.attributes[name] = value
            if self.scripts.OnAttributeChanged then self.scripts.OnAttributeChanged(self, name, value) end
        end
        function w:GetAttribute(name) return self.attributes[name] end
        function w:RegisterForClicks() end
        function w:RegisterUnitEvent(event, unit) self.events[event] = unit end
        function w:RegisterEvent(event) self.events[event] = true end
        function w:UnregisterAllEvents() self.events = {} end
        function w:Show() self.shown = true end
        function w:Hide() self.shown = false end
        function w:IsShown() return self.shown end
        function w:SetShown(value) self.shown = value end
        function w:SetSize(width, height) self.width, self.height = width, height end
        function w:GetWidth() return self.width or 72 end
        function w:GetHeight() return self.height or 43 end
        function w:SetAllPoints(target) self.allPoints = target end
        function w:ClearAllPoints() self.point = nil end
        function w:SetPoint(...) self.point = { ... } end
        function w:SetAlpha(alpha) self.alpha = alpha end
        function w:SetFrameLevel(level) self.level = level end
        function w:GetFrameLevel() return self.level end
        function w:EnableMouse() end
        function w:SetIgnoreParentAlpha() end
        function w:SetAtlas() end
        function w:SetTexture(texture) self.texture = texture end
        function w:SetVertexColor() end
        function w:SetColorTexture() end
        function w:CreateTexture() return Widget(self) end
        widgets[#widgets + 1] = w
        return w
    end
    local env = setmetatable({
        CreateColor = function(...) return { ... } end,
        CreateFromMixins = function(...) return Mix({}, ...) end,
        Mixin = Mix,
        CompactAuraTooltipMixin = {},
        CompactRaidGroupTypeEnum = { Raid = 1, Party = 2, Arena = 3 },
        Enum = {
            RaidAuraOrganizationType = { Legacy = 0, BuffsTopDebuffsBottom = 1, BuffsRightDebuffsLeft = 2 },
            RaidDispelDisplayType = { Disabled = 0, DisplayAll = 1, DispellableByMe = 2 },
        },
        EnumUtil = { MakeEnum = function(...)
            local result = {}; for i, name in ipairs({ ... }) do result[name] = i end; return result
        end },
        InCombatLockdown = function() return combat end,
        UnitExists = function(unit) return type(unit) == "string" and unit ~= "" end,
        UnitIsConnected = function() return true end,
        issecretvalue = function() return false end,
        securecallfunction = function(fn, ...) return fn(...) end,
        securecall = function(fn, ...) return fn(...) end,
        assertsafe = function(condition, message)
            if not condition then Violation(message) end
            return true
        end,
        FluxOptions = { GetRaidFrameDB = function() return db end },
        FluxRaid_IsDispelHighlightEnabled = function() return false end,
        FluxRaid_QueueConfigureAndRefresh = function() queues = queues + 1 end,
        CreateFrame = function(_, name, parent)
            local w = Widget(parent); w.widgetName = name; return w
        end,
    }, { __index = _G })
    env._G = env
    local ns = { Flux = {}, API = {} }
    Load(sourceRoot .. "Blizzard_UnitFrame/Shared/CompactUnitFrame.lua", env, ns)
    -- Execute these methods verbatim from the supplied restricted addon. Loading
    -- the rest would require reproducing its entire renderer and unit-watcher engine.
    env.PrivateAuraAnchorContainerMixin = {}
    local privateSource = Read(sourceRoot .. "Blizzard_PrivateAurasUI/Blizzard_PrivateAurasUI.lua")
    for _, method in ipairs({ "RegisterSettingsChangeHandler", "UnregisterSettingsChangeHandler" }) do
        local source = assert(privateSource:match("function PrivateAuraAnchorContainerMixin:" .. method .. "%(%)\n.-\nend"), method)
        RunSource(source, "@" .. family .. "/" .. method, env)
    end
    local auraSource = Read(sourceRoot .. "Blizzard_FrameXMLUtil/AuraUtil.lua")
    env.AuraUtil = {
        IsRoleAura = function(aura) return aura.roleAura end,
        IsPriorityDebuff = function(spellID) return spellID == 30 end,
        ShouldDisplayDebuff = function() return true end,
        ShouldDisplayBuff = function() return true end,
    }
    RunSource(assert(auraSource:match("AuraUtil.DispellableDebuffTypes =%s*{.-\n};")), "@" .. family .. "/dispellableTypes", env)
    for _, enum in ipairs({ "AuraUpdateChangedType", "UnitFrameDebuffType" }) do
        RunSource(assert(auraSource:match("AuraUtil%." .. enum .. " = EnumUtil.MakeEnum%(%s*.-\n%);")), "@" .. family .. "/" .. enum, env)
    end
    RunSource(assert(auraSource:match("function AuraUtil.ProcessAura%(.-\nend")), "@" .. family .. "/ProcessAura", env)
    local nativeContainer, nativeIndividual = {}, {}
    for k, v in pairs(env.ContainerPrivateAuraBehaviorMixin) do nativeContainer[k] = v end
    for k, v in pairs(env.CompactUnitIndividualPrivateAuraAnchorMixin) do nativeIndividual[k] = v end
    env.C_UnitAuras = {
        GetAllPrivateAuras = function() Violation("Flux called restricted GetAllPrivateAuras") end,
        GetAuraDataByIndex = function(_, index, filter)
            auraReads[filter] = (auraReads[filter] or 0) + 1
            return assert(auraData[filter], "unexpected aura filter " .. tostring(filter))[index]
        end,
        AddPrivateAuraAnchor = function(args)
            if combat then Violation("private-aura anchor added in combat") end
            if failNextAdd then failNextAdd = false; error("transient registration failure") end
            assert(args.isContainer and args.parent and type(args.unitToken) == "string")
            adds = adds + 1
            local record = Mix({}, env.PrivateAuraAnchorContainerMixin)
            function record:GetContainer() return args.parent end
            function record:UpdateFromSettings() settingsUpdates = settingsUpdates + 1 end
            record:RegisterSettingsChangeHandler()
            anchors[adds], registrations[adds] = args, record
            return adds
        end,
        RemovePrivateAuraAnchor = function(id)
            if combat then Violation("private-aura anchor removed in combat") end
            assert(anchors[id], "removed missing private-aura anchor")
            registrations[id]:UnregisterSettingsChangeHandler()
            anchors[id], registrations[id] = nil, nil
            removes = removes + 1
        end,
    }
    if missingAPI == "add" then env.C_UnitAuras.AddPrivateAuraAnchor = nil end
    if missingAPI == "remove" then env.C_UnitAuras.RemovePrivateAuraAnchor = nil end
    Load(root .. "RaidFrame/FluxRaidCompat.lua", env, ns)
    Load(root .. "RaidFrame/FluxRaidVisuals.lua", env, ns)
    Load(root .. "RaidFrame/FluxRaidUnit.lua", env, ns)
    local button = Widget()
    button.auraHost = Widget(button)
    env.FluxRaidUnit_OnLoad(button)
    local buttonHandler = assert(button:GetScript("OnAttributeChanged"), "missing Flux unit attribute hook")
    if missingAPI then
        assert(not button._fluxPrivateAuraMixed, "mixed native private-aura methods without API support")
        auraData.HARMFUL = { { icon = 100, spellId = 1 }, { spellId = 2 }, { icon = 102, spellId = 3 } }
        env.FluxRaid_BindUnit(button, "raid1")
        assert(button._fluxAuraButtons and #button.buffFrames > 0, "missing classic aura fallback")
        assert(button.debuffFrames[1]:IsShown() and button.debuffFrames[1].icon.texture == 100)
        assert(button.debuffFrames[2]:IsShown() and button.debuffFrames[2].icon.texture == 102, "rejected aura consumed visible fallback slot")
        db.displayOnlyDispellableDebuffs = true
        -- Native HARMFUL|RAID membership is the capability check. These native
        -- aura payloads deliberately omit canActivePlayerDispel.
        auraData["HARMFUL|RAID"] = { { spellId = 3 }, { icon = 201, spellId = 4 }, { icon = 202, spellId = 5 } }
        env.FluxRaidVisuals.PushAuraDisplayToFrame(button)
        env.FluxRaid_UpdateAuras(button)
        assert(auraReads["HARMFUL|RAID"], "fallback did not query native player-dispellable filter")
        assert(button.debuffFrames[1]:IsShown() and button.debuffFrames[1].icon.texture == 201, "native dispellable aura was not displayed")
        assert(button.debuffFrames[2]:IsShown() and button.debuffFrames[2].icon.texture == 202)
        assert(not button.debuffFrames[3]:IsShown(), "stale non-dispellable fallback icon remained")
        db.displayOnlyDispellableDebuffs = false
        env.FluxRaidVisuals.PushAuraDisplayToFrame(button)
        env.FluxRaid_UpdateAuras(button)
        assert(button.debuffFrames[1].icon.texture == 100, "disabling filter did not restore ordinary fallback debuffs")
        assert(adds == 0 and #violations == 0)
        print(family .. " missing " .. missingAPI .. " private API: aura fallback and native dispellable filtering OK")
        return
    end
    local host = assert(button._fluxPrivateAuraHost or button.auraHost)
    assert(host ~= button and host:GetParent() == button, "private-aura container must be a dedicated child")
    assert(button.SetPrivateAuraAnchorUnit == nil and button.IsContainer == nil, "native methods were mixed onto unit button")
    assert(button:GetScript("OnAttributeChanged") == buttonHandler)
    button:SetAttribute("unit", "raid1")
    local firstID = assert(host.anchorID, "initial unit bind did not create anchor")
    assert(anchors[firstID].parent == host and anchors[firstID].unitToken == "raid1")
    assert(host:GetScript("OnAttributeChanged") and button:GetScript("OnAttributeChanged") == buttonHandler)
    assert(host.displayedUnit == "raid1" and host.optionTable == button.optionTable)
    assert(host:GetAttribute("max-buffs") == 3 and host:GetAttribute("max-debuffs") == 5)
    assert(host:GetAttribute("group-type") == env.CompactRaidGroupTypeEnum.Raid)
    assert(not button._fluxAuraButtons, "private-aura frames created duplicate Lua aura buttons")
    env.FluxRaid_UpdateAuras(button)
    assert(host.anchorID == firstID and adds == 1 and removes == 0, "repeated paint churned anchor")

    db.auraFocusMode, db.displayBuffs = "buff", false
    db.displayOnlyDispellableDebuffs = true
    env.FluxRaidVisuals.ApplyRaidFrameTunables({ auraIconScale = 2 })
    env.FluxRaidVisuals.PushAuraDisplayToFrame(button)
    assert(host.anchorID == firstID and adds == 1 and removes == 0, "settings update rebuilt anchor")
    assert(settingsUpdates > 0, "native settings handler did not receive update")
    assert(host:GetAttribute("max-buffs") == 6 and host:GetAttribute("max-debuffs") == 3)
    assert(host:GetAttribute("ignore-buffs") == true and host:GetAttribute("display-only-dispellable-debuffs") == true)
    assert(host:GetAttribute("aura-organization-type") == env.Enum.RaidAuraOrganizationType.BuffsTopDebuffsBottom)
    assert((host:GetAttribute("icon-size") or host:GetAttribute("buff-size")) == env.FluxRaidVisuals.AURA_ICON_HEIGHT)
    assert(not host.avoidPrivateAuraAnchorChange, "settings-only anchor suppression leaked into future unit binds")
    local function Classify(fields)
        local aura = Mix({ isHarmful = true, spellId = 1, dispelName = "Magic" }, fields)
        return env.AuraUtil.ProcessAura(aura, host:GetAttribute("display-only-dispellable-debuffs"), host:GetAttribute("ignore-buffs"), host:GetAttribute("ignore-debuffs"), host:GetAttribute("ignore-dispel-debuffs"))
    end
    local changedType = env.AuraUtil.AuraUpdateChangedType
    assert(host:GetAttribute("ignore-debuffs") == true and host:GetAttribute("ignore-dispel-debuffs") == false, "native container settings do not enforce dispellable-only debuffs")
    for _, fields in ipairs({ {}, { isBossAura = true }, { roleAura = true }, { spellId = 30 } }) do
        assert(Classify(fields) == changedType.None, "non-dispellable ordinary/boss/role/priority aura leaked through native painter")
    end
    for _, fields in ipairs({ { isRaid = true }, { isRaid = true, isBossAura = true }, { isRaid = true, roleAura = true }, { isRaid = true, spellId = 30 } }) do
        assert(Classify(fields) == changedType.Dispel, "native player-dispellable aura was hidden")
    end
    db.displayOnlyDispellableDebuffs = false
    env.FluxRaidVisuals.PushAuraDisplayToFrame(button)
    assert(host.anchorID == firstID and adds == 1 and removes == 0, "filter toggle rebuilt anchor")
    assert(host:GetAttribute("ignore-debuffs") == false and Classify({}) == changedType.Debuff and Classify({ isBossAura = true }) == changedType.Debuff, "filter toggle did not restore ordinary/boss native debuffs")
    button:SetAttribute("unit", "raid2")
    local secondID = assert(host.anchorID)
    assert(secondID ~= firstID and not anchors[firstID] and anchors[secondID].unitToken == "raid2", "rebind kept stale unit watcher")
    assert(host:GetScript("OnAttributeChanged") and button:GetScript("OnAttributeChanged") == buttonHandler)

    -- The header refresh paints before consuming its dirty flag. A settings-only
    -- combat change must be marshalled on that first paint, with the same unit
    -- and existing anchor, rather than losing the pending change.
    combat = true
    local settingsAdds, settingsRemoves = adds, removes
    db.auraFocusMode, db.displayOnlyDispellableDebuffs = "debuff", true
    env.FluxRaidVisuals.PushAuraDisplayToFrame(button)
    assert(host:GetAttribute("ignore-debuffs") == false and host:GetAttribute("max-debuffs") == 3, "combat wrote deferred native settings")
    assert(button._fluxNeedsPrivateAuraSync, "same-unit combat settings update was not queued")
    combat = false
    env.FluxRaid_UpdateAuras(button)
    assert(host:GetAttribute("ignore-debuffs") == true and host:GetAttribute("max-debuffs") == 5, "first post-combat paint lost deferred native settings")
    assert(host.anchorID == secondID and adds == settingsAdds and removes == settingsRemoves, "same-unit deferred settings rebuilt anchor")
    assert(not button._fluxNeedsPrivateAuraSync, "same-unit deferred settings retained dirty flag")

    combat = true
    local combatAdds, combatRemoves = adds, removes
    button:SetAttribute("unit", "raid3")
    env.FluxRaidVisuals.PushAuraDisplayToFrame(button)
    assert(adds == combatAdds and removes == combatRemoves and host.anchorID == secondID, "combat modified anchor")
    assert(button._fluxNeedsPrivateAuraSync and queues > 0, "combat aura change was not queued")
    combat = false
    env.FluxRaid_UpdateAuras(button)
    local thirdID = assert(host.anchorID)
    assert(thirdID ~= secondID and not anchors[secondID] and anchors[thirdID].unitToken == "raid3", "deferred combat rebind not applied")
    assert(not button._fluxNeedsPrivateAuraSync, "aura dirty flag not cleared after retry")
    button:SetAttribute("unit", nil)
    assert(not host.anchorID and not host.privateAuraUnit and not anchors[thirdID], "unbind left stale private-aura anchor")
    assert(not host:GetScript("OnAttributeChanged") and button:GetScript("OnAttributeChanged") == buttonHandler, "unbind removed Flux unit handler")
    button:SetAttribute("unit", "raid4")
    local fourthID = assert(host.anchorID)
    assert(anchors[fourthID].unitToken == "raid4", "rebind after unbind failed")
    combat = true
    button:SetAttribute("unit", nil)
    assert(host.anchorID == fourthID and button._fluxNeedsPrivateAuraSync, "combat unbind did not defer cleanup")
    combat = false
    env.FluxRaid_UpdateAuras(button)
    assert(not host.anchorID and not anchors[fourthID], "deferred unbind left stale anchor")

    -- Native binding writes privateAuraUnit before engine registration. Retrying
    -- the same unit must still create an anchor after a transient engine failure.
    failNextAdd = true
    button:SetAttribute("unit", "raid5")
    assert(not host.anchorID and host.privateAuraUnit == "raid5" and button._fluxNeedsPrivateAuraSync, "failed initial anchor did not remain retryable")
    env.FluxRaid_UpdateAuras(button)
    assert(host.anchorID and anchors[host.anchorID].unitToken == "raid5" and not button._fluxNeedsPrivateAuraSync, "same-unit retry did not recover failed anchor creation")

    local mini, previousAdds = Widget(), adds
    mini._fluxRaidMini = true
    assert(env.FluxRaidVisuals.ConfigurePrivateAuras(mini) == false)
    env.FluxRaid_UpdateAuras(mini)
    assert(not mini._fluxPrivateAuraMixed and not mini._fluxAuraButtons and adds == previousAdds, "mini acquired aura infrastructure")
    for k, fn in pairs(nativeContainer) do assert(env.ContainerPrivateAuraBehaviorMixin[k] == fn, "replaced native container method " .. k) end
    for k, fn in pairs(nativeIndividual) do assert(env.CompactUnitIndividualPrivateAuraAnchorMixin[k] == fn, "replaced native individual-anchor method " .. k) end
    assert(#violations == 0, table.concat(violations, "; "))
    print(family .. ": native private-aura ownership, dispellable filtering, settings, rebind/unbind, combat retry and minis OK")
end

for _, family in ipairs({ "forever", "live", "classic_era", "classic_anniversary" }) do
    Scenario(family, false)
    Scenario(family, "add")
    Scenario(family, "remove")
end
print("Raid aura smoke OK (4 supplied clients, native methods retained; engine taint requires in-game validation)")
