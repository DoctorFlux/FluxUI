-- Actual module with each pinned client's color helpers. This is a desktop
-- ownership/lifecycle fixture, not a protected VM or native rendering test.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local checks = 0
local function check(value, message) assert(value, message); checks = checks + 1 end
local source = read(os.getenv("FLUX_DEBUFF_TINT_SOURCE") or "UnitFrames/FluxUnitFrames_DebuffTint.lua")
local combatTextOnly = os.getenv("FLUX_DEBUFF_TINT_CASE") == "combat-text"
for _, client in ipairs({"live", "forever", "classic", "classic_era", "classic_anniversary"}) do
 for _, provider in ipairs({"current", "legacy"}) do
    local E = setmetatable({}, {__index = _G}); E._G = E
    local secret = setmetatable({}, {__index = function() error("secret field inspected") end})
    local inaccessible = setmetatable({}, {__index = function() error("inaccessible aura inspected") end})
    E.issecretvalue = function(v) return rawequal(v, secret) end
    E.canaccesstable = function(v) return not rawequal(v, inaccessible) end
    local combat, restricted, friendly, opaqueFriend = false, false, true, false
    local pending, deferred, objects, boxes, reads = {}, {}, {}, {}, 0
    local dispel, ordinary = "Magic", "Poison"
    local unitAuras, aliases, readUnits, unitFriendly = {}, {}, {}, {}
    local function auraKind(unit, filter, index)
        index = index or 1
        local entry = unitAuras[aliases[unit] or unit]
        if entry == false then return nil end
        local d, o = dispel, ordinary
        if entry then
            local list = entry[filter == "HARMFUL|RAID" and "raid" or "all"]
            if list then return list[index] end
            d, o = entry.dispel, entry.ordinary
        end
        if filter == "HARMFUL|RAID" then return index == 1 and d or nil end
        if d then return index == 1 and d or index == 2 and o or nil end
        return index == 1 and o or nil
    end
    local invalid, failed = false, false
    local cvars = {}
    E.C_CVar = {GetCVarBool = function(name) return cvars[name] == true end}
    local colors = {Magic = {.2,.6,1,1}, Curse = {.6,0,1,1}, Disease = {.6,.4,0,1},
        Poison = {0,.6,0,1}, Bleed = {1,.2,.2,1}, None = {.8,0,0,1}}
    for kind, rgba in pairs(colors) do
        local color = {GetRGBA = function() return table.unpack(rgba) end}
        E["DEBUFF_TYPE_" .. kind:upper() .. "_COLOR"] = color
    end
    -- Replay the exact selected client's display table and public helper bodies.
    local base = "../__AddonsForRef/wow-ui-source-" .. client .. "/Interface/AddOns/"
    local auraSource = read(base .. "Blizzard_FrameXMLUtil/AuraUtil.lua")
    local partySource = read(base .. "Blizzard_UnitFrame/Shared/PartyMemberFrame.lua")
    check(partySource:find('GetCVarValueBool("showDispelDebuffs")',1,true), "client friendly aura policy reads Blizzard dispel-only preference")
    local display = assert(auraSource:match("local DEBUFF_DISPLAY_INFO = %b{};"))
    local helpers = {"GetDebuffDisplayInfoTable", "SetAuraBorderColor", "GetAuraBorderColor"}
    local code = display .. "\nAuraUtil = {}\n"
    for _, key in ipairs(helpers) do
        local body = auraSource:match("function AuraUtil%." .. key .. "%b()%s.-\nend")
        if body then code = code .. body .. "\n" end
    end
    assert(load(code, "@pinned-client-aura-colors-" .. client, "t", E))()
    check(E.AuraUtil.GetDebuffDisplayInfoTable ~= nil, "client display table exists")
    local native = client == "live" or client == "forever"
    local nativeColorCapabilities = native and provider == "current"
    -- Native 13:45:15 report: the registered Texture is forbidden too.
    -- Color-return annotations never grant object access through its ancestry.
    local values = setmetatable({}, {__mode="k"})
    local function opaque(value)
        local token = setmetatable({}, {__index=function() error("secret display field inspected") end,
            __eq=function() error("secret display compared") end, __tostring=function() error("secret display formatted") end})
        values[token] = value; return token
    end
    local function unwrap(value) if values[value] ~= nil then return values[value] end; return value end
    if nativeColorCapabilities then
        E.CreateColor = function(r,g,b,a)
            return {r=r,g=g,b=b,a=a, SetRGBA=function(self,r,g,b,a) self.r,self.g,self.b,self.a=r,g,b,a end,
                GetRGBA=function(self) return self.r,self.g,self.b,self.a end}
        end
        E.C_CurveUtil = {EvaluateColorFromBoolean=function(value,yes,no)
            local c = unwrap(value) and yes or no
            return E.CreateColor(opaque(unwrap(c.r)),opaque(unwrap(c.g)),opaque(unwrap(c.b)),opaque(unwrap(c.a)))
        end}
    end
    local nativeSetUnit, nativeSetFilter
    if native then
        local containerSource = read(base .. "Blizzard_AuraContainer/Blizzard_AuraContainer.lua")
        local setUnit = assert(containerSource:match("function AuraContainerSharedMixin:SetUnit%b()%s.-\nend"))
        E.AuraContainerSharedMixin = {}
        assert(load(setUnit, "@native-setunit-unchanged-token", "t", E))()
        nativeSetUnit = E.AuraContainerSharedMixin.SetUnit
        local custom = read(base .. "Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua")
        local setter = assert(custom:match("function CustomAuraContainerSharedMixin:SetAuraSlotFilterString%b()%s.-\nend"))
        E.CustomAuraContainerSharedMixin = {}
        E.GetRequiredAuraSlot = function(owner, key) check(key == "friendlyTint", "owned slot key"); return owner.slot end
        E.AuraUtil.IsValidFilterString = function(filter) return filter == "HARMFUL" or filter == "HARMFUL|RAID" end
        assert(load(setter, "@native-public-slot-filter-setter", "t", E))()
        nativeSetFilter = E.CustomAuraContainerSharedMixin.SetAuraSlotFilterString
        local buttonSource = read(base .. "Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua")
        check(buttonSource:find('RequireObjectType("Texture")', 1, true), "native requires Texture sinks")
        check(buttonSource:find("AuraUtil.SetAuraBorderColor(texture, auraData.dispelName)", 1, true), "PreserveAsset uses client colors")
        local first = assert(buttonSource:find("local function ShouldShowDispelTypeForAura",1,true))
        local last = assert(buttonSource:find("local function GetDispelTypeMapKey",first,true))
        local shouldShow = assert(load(buttonSource:sub(first,last-1) .. "\nreturn ShouldShowDispelTypeForAura", "@native-type-visibility", "t", E))()
        local options = {showWhenHarmful=true,showWhenHelpful=false,showWithoutDispelType=false}
        check(not shouldShow(options,{isHarmful=true}), "exact native predicate rejects missing type")
        check(shouldShow(options,{isHarmful=true,dispelName="Magic"}), "exact native predicate accepts known type")
        check(not shouldShow(options,{isHelpful=true,dispelName="Magic"}), "exact native predicate rejects helpful auras")
        E.AuraContainerSortMethod = {Default = 1}
        E.Enum = {CustomAuraButtonDispelTypeTextureStyle = {PreserveAsset = 3}}
    end
    local M = {}
    local function readable(f)
        local owner = f
        while owner do
            if native and restricted and owner.privateButton then
                error("Attempt to access forbidden object from code tainted by an AddOn")
            end
            owner = owner.parent
        end
    end
    local function object(kind, parent)
        local f = setmetatable({kind = kind, parent = parent, shown = true, alpha = 1, level = (parent and parent.level or 0) + 1,
            textures = {}, hooks = {}, rgba = {.9,.8,.7,.6}}, {__index = M})
        objects[#objects + 1] = f; return f
    end
    function M:CreateTexture() local t = object("Texture", self); self.textures[#self.textures+1] = t; return t end
    function M:GetParent() readable(self); return self.parent end
    function M:SetAllPoints(target) self.points = target end
    function M:EnableMouse() end
    function M:SetFrameLevel(level)
        local delta = level - self.level; self.level = level
        for _, child in ipairs(objects) do if child.parent == self and child.kind ~= "Texture" and child.kind ~= "FontString" then
            child:SetFrameLevel(child.level + delta)
        end end
    end
    function M:GetFrameLevel() readable(self); return self.level end
    function M:SetEditModePreviewEnabled(value) check(value == false, "native demo disabled") end
    function M:GetAtlas() return self.atlas end
    function M:SetAtlas(atlas) self.atlas = atlas end
    function M:GetTexture() return self.texture end
    function M:SetTexture(texture) self.texture = texture end
    function M:GetTexCoord() return 0,.2,.3,.4 end
    function M:SetTexCoord(...) self.uv = {...} end
    function M:GetTextColor() return table.unpack(self.rgba) end
    function M:GetVertexColor()
        readable(self)
        check(self.nativeDispel == true, "only registered addon Texture read; never private button state")
        return opaque(self.rgba[1]),opaque(self.rgba[2]),opaque(self.rgba[3]),opaque(self.rgba[4])
    end
    function M:SetTextColor(...) self.rgba = {...} end
    function M:SetVertexColor(...) self.rgba = {...} end
    local function visible(f) return f.shown and (not f.parent or visible(f.parent)) end
    function M:IsVisible()
        readable(self)
        local shown = visible(self)
        if self.nativeDispel and nativeColorCapabilities then return opaque(shown) end
        return shown
    end
    function M:IsShown() readable(self); return self.shown end
    function M:Show() self.shown = true end
    function M:Hide() self.shown = false end
    function M:GetAlpha() return self.alpha end
    function M:SetAlpha(value) self.alpha = value end
    function M:HookScript(event, fn) self.hooks[event] = fn end
    function M:RegisterEvent(event) self[event] = true end
    function M:SetScript(event, fn) self[event] = fn end
    function M:UpdateEventRegistrations() end
    function M:UpdateAllAuras()
        self.refreshes = (self.refreshes or 0) + 1
        self.bound = self.unitToken
        self.nativeKind = nil
        if self.bound ~= "none" then
            for index=1,40 do
                local kind = auraKind(self.bound,self.filter,index)
                if kind == nil then break end
                if self.candidateFilters.includeDispelTypes[kind] then self.nativeKind = kind; break end
            end
        end
        self.button.shown = self.nativeKind ~= nil
        for _, texture in ipairs(self.button.textures) do
            if self.nativeKind then texture.rgba = colors[self.nativeKind]; texture.shown = true
            else texture.shown = false end
        end
    end
    function M:SetUnit(unit)
        check(self.kind == "AuraContainer", "only public native owner rebound")
        return nativeSetUnit(self, unit)
    end
    function M:RebuildAuraParseFilters() end
    function M:SetAuraSlotFilterString(key, filter) return nativeSetFilter(self,key,filter) end
    function M:AddAuraSlot(key, filter, options)
        check(not combat, "native descendants created OOC")
        check(options.templateNames[1] == "FluxRaidDispelBorderTemplate", "bare owned native slot template")
        self.candidateFilters = options.candidateFilters
        check(self.candidateFilters.includeDispelTypes.Magic and self.candidateFilters.includeDispelTypes.Bleed
            and not self.candidateFilters.includeDispelTypes.None,"native requires known candidate type")
        self.filter = filter; self.button = object("Frame", self); self.button.privateButton = true
        self.slot = {GetFilterString=function() return self.filter end,SetFilterString=function(_,value) self.filter=value end}
        options.initializeFrame(self.button)
    end
    function M:AddDispelTypeTexture(texture, options)
        texture.nativeDispel = true
        check(texture.kind == "Texture" and texture.parent == self, "native sink is descendant Texture")
        check(options.style == 3 and options.showWhenHarmful and not options.showWithoutDispelType and not options.showWhenHelpful, "harmful PreserveAsset; missing type never colored")
    end
    E.CreateFrame = function(kind, _, parent)
        check(not combat or kind == "Frame", "no native allocation in combat")
        if failed and kind == "AuraContainer" then error("unsupported native owner") end
        local f = object(kind, parent); if kind == "AuraContainer" then boxes[#boxes+1] = f end; return f
    end
    E.C_Timer = {After = function(_, fn) pending[#pending+1] = fn end}
    E.InCombatLockdown = function() return combat end
    E.UnitCanAssist = function(_, unit)
        if opaqueFriend then return secret end
        if unitFriendly[unit] ~= nil then return unitFriendly[unit] end
        return friendly
    end
    E.UnitIsFriend = E.UnitCanAssist
    E.UnitCanAttack = function() return false end
    E.UnitIsUnit = function(a,b) return (aliases[a] or a) == (aliases[b] or b) end
    E.C_Secrets = {ShouldAurasBeSecret = function() return restricted end}
    local function aura(unit, index, filter)
        reads = reads + 1
        readUnits[#readUnits + 1] = unit
        check(not restricted, "no addon aura reads during restrictions")
        check(index >= 1 and index <= 40, "bounded candidate scan")
        if invalid == "secret" then return secret elseif invalid then return inaccessible end
        local kind = auraKind(unit, filter, index)
        if kind == "untyped" then return {} end
        if kind then return {dispelName = kind} end
    end
    if provider == "current" then E.C_UnitAuras = {GetAuraDataByIndex = aura}
    else
        E.UnitAura = function(...) local d = aura(...); if d then return "debuff", nil, nil, d.dispelName end end
        E.C_CVar = nil; E.GetCVar = function(name) return cvars[name] and "1" or "0" end
    end
    local UF = {GetFramePublicLevel = function(f) return f and f.level end,
        DeferProtected = function(key, fn) deferred[key] = fn end}
    local ns = {UnitFrames = UF}
    local raidDB = {}
    E.FluxOptions = {GetRaidFrameDB=function() return raidDB end,
        GetUnitFrameDB = function() return {auraTarget = {showDebuffs = true}, auraFocus = {showDebuffs = true}} end}
    assert(load(source, "@actual-friendly-debuff-tint", "t", E))("_FluxUI", ns)
    local events = objects[1]
    check(events.UNIT_AURA and events.PLAYER_TARGET_CHANGED and not events.OnUpdate, "single event driver; no addon polling")
    local function flush() while #pending > 0 do local batch = pending; pending = {}; for _, fn in ipairs(batch) do fn() end end end
    local function refresh() UF.RefreshDebuffTint(); flush() end
    local function border(parent)
        local b = object("Frame", parent); parent.FluxBorderFrame = b
        for _, key in ipairs({"TL","TR","BL","BR","Top","Bottom","Left","Right"}) do
            local t = b:CreateTexture(); t.texture = "asset-" .. key; if key == "TL" then t.atlas = "atlas-corner" end; b[key] = t
        end
        b.Background = b:CreateTexture(); b.Background.texture = "DO-NOT-TINT-BACKDROP"
    end
    local function unitFrame(unit)
        local f = object("Frame"); f.unit = unit; border(f)
        if unit:match("^party[1-4]$") then f._fluxPartyMember = true; f.optionTable = {} end
        f.PortraitFrame = object("Frame", f); border(f.PortraitFrame)
        f.Health, f.Power = {}, {}
        for _, bar in ipairs({f.Health,f.Power}) do bar.Value = object("FontString", f); bar.Percent = object("FontString", f) end
        f.HealthPowerSeparator = f:CreateTexture(); f.HealthPowerSeparator.texture = "separator"
        return f
    end
    local function paintMatches(f, kind)
        local expected = colors[kind]
        for _, bar in ipairs({f.Health,f.Power}) do for _, label in ipairs({bar.Value,bar.Percent}) do
            check(unwrap(label.rgba[1]) == expected[1] and unwrap(label.rgba[2]) == expected[2] and unwrap(label.rgba[3]) == expected[3], "HP/resource values and percent match client type")
        end end
    end
    local function restored(f) check(unwrap(f.Health.Value.rgba[1]) == .9 and unwrap(f.Power.Percent.rgba[4]) == .6, "exact normal text restored") end
    local frame = unitFrame("party1"); frame._fluxPartyMember = true; frame.optionTable = {}
    local indicator = object("Frame", frame); indicator.level = 100
    frame._fluxPartyDivider = indicator:CreateTexture(); frame._fluxPartyDivider.texture = "party-divider"
    UF.SetupDebuffTint(frame); flush(); paintMatches(frame,"Magic")
    local portraitBorder = frame.PortraitFrame.FluxBorderFrame
    local portraitHost
    for _, obj in ipairs(objects) do
        if obj.kind ~= "Texture" and obj.parent == portraitBorder then portraitHost = obj end
    end
    if not combatTextOnly then
        check(portraitHost ~= nil, "portrait tint inherits the border combat level")
        local normalLevel, offset = portraitBorder.level, portraitHost.level - portraitBorder.level
        combat = true; portraitBorder:SetFrameLevel(200)
        check(portraitHost.level > portraitBorder.level and portraitHost.level - portraitBorder.level == offset,
            "combat border raise cannot cover debuff tint")
        portraitBorder:SetFrameLevel(normalLevel); combat = false
    end
    if native then
        check(#boxes == 3, "one native dispellable slot per chrome part")
        check(boxes[3].level > indicator.level, "divider tint above real party divider")
        for _, box in ipairs(boxes) do
            check(box.bound == "party1", "native correct friendly unit")
            check(box.filter == "HARMFUL", "off uses all known harmful candidates")
        end
    end
    for _, f in ipairs(objects) do for _, t in ipairs(f.textures) do
        if t.points then check(t.points.texture ~= "DO-NOT-TINT-BACKDROP", "background never cloned") end
    end end
    local start = reads; UF.RefreshDebuffTint(); UF.RefreshDebuffTint(); UF.RefreshDebuffTint(); flush()
    if combatTextOnly then check(reads - start <= 1, "bursts coalesced to at most one aura lookup")
    else check(reads - start == 1, "bursts coalesced to one readable aura lookup") end
    dispel = nil; refresh(); paintMatches(frame,"Poison")
    for _, name in ipairs({"showDispelDebuffs", "raidFramesDisplayOnlyDispellableDebuffs"}) do
        cvars[name] = true; events.OnEvent(events,"CVAR_UPDATE",name); flush()
        if name == "raidFramesDisplayOnlyDispellableDebuffs" then
            restored(frame); if native then check(boxes[1].nativeKind == nil,"party Blizzard strict excludes ordinary") end
        else paintMatches(frame,"Poison") end
        cvars[name] = false; events.OnEvent(events,"CVAR_UPDATE",name); flush(); paintMatches(frame,"Poison")
    end
    raidDB.displayOnlyDispellableDebuffs = false
    cvars.showDispelDebuffs, cvars.raidFramesDisplayOnlyDispellableDebuffs = true, true
    refresh(); paintMatches(frame,"Poison")
    raidDB.displayOnlyDispellableDebuffs = true; refresh(); restored(frame)
    frame.optionTable.displayOnlyDispellableDebuffs = false; refresh(); paintMatches(frame,"Poison")
    frame.optionTable.displayOnlyDispellableDebuffs = nil
    raidDB.displayOnlyDispellableDebuffs = nil
    cvars.showDispelDebuffs, cvars.raidFramesDisplayOnlyDispellableDebuffs = false, false
    start = reads; events.OnEvent(events,"CVAR_UPDATE","unrelatedPreference"); flush(); check(reads == start,"unrelated CVar does not queue work")
    frame.optionTable.displayOnlyDispellableDebuffs = true; refresh(); restored(frame)
    if native then check(boxes[1].nativeKind == nil, "strict filter never admits ordinary debuff") end
    frame.optionTable.displayOnlyDispellableDebuffs = false
    for _, unknown in ipairs({"untyped", "None", "UnexpectedFutureType"}) do
        dispel, ordinary = unknown, unknown; refresh(); restored(frame)
    end
    dispel = "Curse"; refresh(); paintMatches(frame,"Curse")
    restricted = true; start = reads; refresh()
    restored(frame)
    check(reads == start, "restricted data not queried")
    if native then check(boxes[1].bound == "party1", "native tint remains independently bound during restrictions") end
    restricted = false
    if provider == "current" then for _, mode in ipairs({"secret",true}) do invalid = mode; refresh()
        restored(frame)
    end end
    invalid = false; refresh(); paintMatches(frame,"Curse")
    frame.optionTable.displayDebuffs = false; refresh(); restored(frame)
    if native then check(boxes[1].bound == "none", "disabled debuffs clear native tint") end
    frame.optionTable.displayDebuffs = true; refresh()
    opaqueFriend = true; refresh(); restored(frame); opaqueFriend = false
    frame.shown = false; frame.hooks.OnHide(); flush(); restored(frame)
    frame.shown = true; frame.hooks.OnShow(); flush(); paintMatches(frame,"Curse")
    if native then
        frame._fluxPartyDivider.alpha = secret; refresh(); check(rawequal(boxes[3].alpha, secret), "opaque alpha forwarded without comparison")
        frame._fluxPartyDivider.alpha = 1; frame._fluxPartyDivider:Hide(); refresh(); check(boxes[3].alpha == 0,"hidden separator stays hidden")
    end
    for _, unit in ipairs({"player","party2","party3","party4","target","focus"}) do
        local f = unitFrame(unit); UF.SetupDebuffTint(f); flush(); paintMatches(f,"Curse")
        cvars.showDispelDebuffs = true; dispel = nil; refresh(); restored(f)
        dispel = "Curse"; refresh(); paintMatches(f,"Curse"); cvars.showDispelDebuffs = false
        if unit == "target" or unit == "focus" then friendly = false; refresh(); restored(f); friendly = true; refresh() end
    end
    for _, unit in ipairs({"pet","partypet1","raid1","targettarget","pettarget","focustarget","party1target"}) do
        local f = unitFrame(unit); local count = #objects; UF.SetupDebuffTint(f); check(count == #objects,"unrequested unit excluded")
    end
    combat = true; local late = unitFrame("party2"); local count = #objects; UF.SetupDebuffTint(late)
    check(count == #objects and next(deferred), "setup deferred in combat")
    refresh(); combat = false; for _, fn in pairs(deferred) do fn() end; flush(); paintMatches(late,"Curse")
    local preview = unitFrame("party1"); preview._fluxPartyPreview = true
    UF.SetupDebuffTint(preview); UF.PreviewDebuffTint(preview,"Disease"); paintMatches(preview,"Disease")
    UF.PreviewDebuffTint(preview,nil); restored(preview)
    -- Earlier tests used one shared fixture aura for every unit, hiding stale
    -- target/focus ownership. Give every unit different data simultaneously.
    local separate = {}
    for unit, kind in pairs({player="Magic",target="Curse",focus="Poison",party3="Disease"}) do
        unitAuras[unit] = {dispel=kind,ordinary="Bleed"}
        separate[unit] = unitFrame(unit); UF.SetupDebuffTint(separate[unit])
    end
    flush()
    local function nativeMatches(f, kind)
        if not native then return end
        local count = 0
        for _, box in ipairs(boxes) do
            if box.parent == f or box.parent == f.PortraitFrame.FluxBorderFrame then
                check(box.nativeKind == kind,"each native overlay uses only its current unit")
                count = count + 1
                for _, texture in ipairs(box.button.textures) do
                    local owner = texture.points:GetParent()
                    while owner and owner ~= f do owner = owner:GetParent() end
                    check(owner == f,"overlay sources never belong to another unit frame")
                end
            end
        end
        check(count == 3,"all three native chrome parts tested")
    end
    for unit, kind in pairs({player="Magic",target="Curse",focus="Poison",party3="Disease"}) do
        paintMatches(separate[unit],kind); nativeMatches(separate[unit],kind)
    end
    check(separate.player.Health.Value ~= separate.target.Health.Value,"numeric objects are not shared")
    local function emit(event, unit)
        -- UNIT_AURA is also received by Blizzard's native owners. Identity
        -- events are deliberately not: native source registers no such event.
        if native and event == "UNIT_AURA" then
            for _, box in ipairs(boxes) do if E.UnitIsUnit(box.bound,unit) then box:UpdateAllAuras() end end
        end
        events.OnEvent(events,event,unit); flush()
    end
    local allocated = #objects
    unitAuras.player.dispel = "Bleed"; start = #readUnits
    emit("UNIT_AURA","player")
    for i=start+1,#readUnits do check(readUnits[i] == "player","unrelated target/focus not read on player-only aura event") end
    paintMatches(separate.player,"Bleed"); paintMatches(separate.target,"Curse"); nativeMatches(separate.target,"Curse")
    combat = true
    unitAuras.target = {ordinary="Magic"}; emit("PLAYER_TARGET_CHANGED")
    paintMatches(separate.target,"Magic"); nativeMatches(separate.target,"Magic")
    -- Switching the actual Flux option changes the same owner, in combat.
    raidDB.displayOnlyDispellableDebuffs = true; refresh()
    restored(separate.target); nativeMatches(separate.target,nil)
    paintMatches(separate.player,"Bleed"); paintMatches(separate.focus,"Poison")
    unitAuras.target = {dispel="Disease"}; emit("PLAYER_TARGET_CHANGED")
    paintMatches(separate.target,"Disease"); nativeMatches(separate.target,"Disease"); nativeMatches(separate.player,"Bleed")
    unitAuras.focus = {dispel="Curse"}; emit("PLAYER_FOCUS_CHANGED")
    paintMatches(separate.focus,"Curse"); nativeMatches(separate.focus,"Curse"); nativeMatches(separate.target,"Disease")
    unitAuras.party3 = {ordinary="Poison"}; emit("GROUP_ROSTER_UPDATE")
    restored(separate.party3); nativeMatches(separate.party3,nil); nativeMatches(separate.target,"Disease")
    unitFriendly.target = false; emit("UNIT_FACTION","target")
    restored(separate.target); nativeMatches(separate.target,nil); paintMatches(separate.player,"Bleed"); paintMatches(separate.focus,"Curse")
    unitFriendly.target = true; aliases.target = "player"; emit("PLAYER_TARGET_CHANGED")
    paintMatches(separate.target,"Bleed"); nativeMatches(separate.target,"Bleed")
    -- Reaction changes are revoked in this event, before the After(0) batch.
    -- Assist may still succeed (duel/charm), so friend/attack have precedence.
    for _,unit in ipairs({"target","focus"}) do
        local f=separate[unit]
        local assist,friend,attack=E.UnitCanAssist,E.UnitIsFriend,E.UnitCanAttack
        E.UnitCanAssist=function()return true end
        E.UnitIsFriend=function(_,token)if token==unit then return false end;return friend("player",token)end
        events.OnEvent(events,"UNIT_FACTION",unit)
        restored(f)
        for _,box in ipairs(boxes)do if box.bound==unit then check(not box.shown,"hostile owner hidden before deferred flush")end end
        flush();nativeMatches(f,nil)
        E.UnitIsFriend=friend;refresh()
        E.UnitCanAttack=function(_,token)return token==unit end
        events.OnEvent(events,unit=="target"and"PLAYER_TARGET_CHANGED"or"PLAYER_FOCUS_CHANGED")
        restored(f);flush();nativeMatches(f,nil)
        E.UnitCanAssist,E.UnitIsFriend,E.UnitCanAttack=assist,friend,attack
        refresh()
    end
    unitAuras.player.dispel = "Poison"; emit("UNIT_AURA","player")
    paintMatches(separate.player,"Poison"); paintMatches(separate.target,"Poison"); nativeMatches(separate.target,"Poison")
    aliases.target = nil; unitAuras.target = false; emit("PLAYER_TARGET_CHANGED")
    restored(separate.target); nativeMatches(separate.target,nil); paintMatches(separate.player,"Poison")
    raidDB.displayOnlyDispellableDebuffs = false; refresh()
    paintMatches(separate.party3,"Poison"); nativeMatches(separate.party3,"Poison")
    unitAuras.focus = {all={"untyped","UnexpectedFutureType","None","Disease"}}
    emit("PLAYER_FOCUS_CHANGED"); paintMatches(separate.focus,"Disease"); nativeMatches(separate.focus,"Disease")
    raidDB.displayOnlyDispellableDebuffs = true; refresh(); restored(separate.focus); nativeMatches(separate.focus,nil)
    raidDB.displayOnlyDispellableDebuffs = false; refresh(); paintMatches(separate.focus,"Disease"); nativeMatches(separate.focus,"Disease")
    if native then
        restricted = true; local beforeReads = reads
        for _, kind in ipairs({"Magic","Curse","Disease","Poison","Bleed"}) do
            for unit, f in pairs(separate) do
                unitAuras[unit] = {dispel=kind}; emit("UNIT_AURA",unit); restored(f); nativeMatches(f,kind)
                unitAuras[unit] = false; emit("UNIT_AURA",unit); restored(f); nativeMatches(f,nil)
            end
        end
        unitAuras.player = {dispel="Magic"}; emit("UNIT_AURA","player")
        unitAuras.target = {dispel="Curse"}; emit("PLAYER_TARGET_CHANGED")
        unitAuras.focus = {dispel="Poison"}; emit("PLAYER_FOCUS_CHANGED")
        restored(separate.player); restored(separate.target); restored(separate.focus)
        unitAuras.target = {dispel="Disease"}; emit("PLAYER_TARGET_CHANGED")
        restored(separate.target); restored(separate.player); restored(separate.focus)
        unitFriendly.target = false; emit("UNIT_FACTION","target"); restored(separate.target)
        unitFriendly.target = true; emit("UNIT_FACTION","target"); restored(separate.target)
        separate.player.shown = false; separate.player.hooks.OnHide(); flush(); restored(separate.player)
        separate.player.shown = true; separate.player.hooks.OnShow(); flush(); restored(separate.player)
        check(reads == beforeReads, "all combat type/removal/identity/hide transitions avoid aura reads")
        -- Presence of the native color selector must not authorize any getter
        -- on a forbidden descendant, even when it is nominally addon-created.
        local forbidden = boxes[1].button.textures[1]
        for _, method in ipairs({"GetVertexColor","IsVisible","IsShown","GetParent","GetFrameLevel"}) do
            local ok, message = pcall(forbidden[method], forbidden)
            check(not ok and message:find("forbidden object",1,true), "fixture enforces native forbidden descendant " .. method)
        end
        restricted = false; refresh()
        paintMatches(separate.player,"Magic"); paintMatches(separate.target,"Disease"); paintMatches(separate.focus,"Poison")
    end
    check(allocated == #objects,"combat identity/aura transitions allocate no frames or textures")
    combat = false; unitAuras = {}; unitFriendly = {}; raidDB = {}; refresh()
    ordinary, dispel = nil, nil; refresh(); restored(frame)
    if native then failed = true; local fallback = unitFrame("focus"); dispel = "Bleed"; UF.SetupDebuffTint(fallback); flush()
        paintMatches(fallback,"Bleed"); check(fallback._fluxDebuffTintError ~= nil,"unsupported owner recorded; readable fallback works") end
 end
end
print("Friendly debuff tint: " .. checks .. " checks PASS across five clients/current and legacy aura providers; native game checks pending")
