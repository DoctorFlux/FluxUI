-- Real unit/pet/raid owners sharing Blizzard's tooltip. Ordinary Lua mocks
-- cannot certify native secret-value VM behavior, taint or rendered pixels.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local shared = read(os.getenv("FLUX_UNIT_TOOLTIP_SHARED_SOURCE") or "UnitFrames/FluxUnitFrames_Shared.lua")
local a = assert(shared:find("-- Unit tooltip (", 1, true))
local b = assert(shared:find("-- Mouseover highlight:", a, true))
local unitSource = "local UF, ns = ...\n" .. shared:sub(a, b - 1)
local happinessStart = assert(shared:find("local function PetHappinessIcon_OnEnter(icon)", 1, true))
local happinessEnd = assert(shared:find("local function ApplyPetHappinessArt", happinessStart, true))
local happinessSource = "local UF = ...\n" .. shared:sub(happinessStart, happinessEnd - 1)
    .. "\nreturn PetHappinessIcon_OnEnter, PetHappinessIcon_OnLeave\n"
local raid = read("RaidFrame/FluxRaidUnit.lua")
local raidStart = assert(raid:find("function FluxRaidUnit_OnHide(self)", 1, true))
local raidEnd = assert(raid:find("function ns.FluxRaidRegisterAllMouseoverKeybindFrames", raidStart, true))
local raidSource = "local ns, IsSecret, ShowRegion, pendingPaint, EnsureRangePoll = ...\n" .. raid:sub(raidStart, raidEnd - 1)
local preview = read("RaidFrame/FluxRaidPreview.lua")
local previewStart = assert(preview:find("function FluxRaidPreviewUnit_OnEnter(self)", 1, true))
local previewEnd = assert(preview:find("local previewCvarListener", previewStart, true))
local previewSource = "local ns, PreviewUnitExists = ...\n" .. preview:sub(previewStart, previewEnd - 1)

for _, client in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    local env = setmetatable({}, { __index = _G }); env._G = env
    local made, queued, tickers = {}, {}, {}
    local exists, guid, locked, hover, ownerShown, ancestorShown = true, "same-guid", false, true, true, true
    local nativeTip, ownerHooks, unitResult, forbidden = nil, {}, true, false
    local secret = setmetatable({}, { __index = function() error("opaque value indexed") end })
    env.issecretvalue = function(value) return rawequal(value, secret) end
    env.UnitExists = function() return exists end
    env.UnitGUID = function() return guid end
    env.InCombatLockdown = function() return locked end
    env.GetTime = function() return 100 end
    env.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    env.FLUX_API = { majorVersion = client:find("classic", 1, true) and 5 or 12, isForever = client == "forever" }
    local methods = {}
    local function widget(name, parent)
        local f = setmetatable({ name = name, parent = parent, scripts = {}, shown = false, width = 180, height = 30, lines = {} }, { __index = methods })
        if name then made[name] = f; env[name] = f end
        return f
    end
    function methods:GetName() return self.name end
    function methods:SetScript(kind, fn)
        check(self ~= nativeTip, client .. ": native tooltip script never replaced")
        self.scripts[kind] = fn
    end
    function methods:GetScript(kind) return self.scripts[kind] end
    function methods:HookScript(kind, fn)
        local before = self.scripts[kind]
        self.scripts[kind] = function(...) if before then before(...) end; fn(...) end
    end
    function methods:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
    function methods:Hide()
        local wasShown = self.shown; self.shown = false
        if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function methods:IsShown() return self.shown end
    function methods:IsForbidden() return forbidden end
    function methods:ClearLines()
        self.lines = {}
        if self.scripts.OnTooltipCleared then self.scripts.OnTooltipCleared(self) end
    end
    function methods:SetOwner(owner, anchor)
        self:Hide(); self:ClearLines(); self.owner, self.anchor = owner, anchor
        for _, fn in ipairs(ownerHooks) do fn(self, owner, anchor) end
    end
    function methods:GetOwner() return self.owner end
    function methods:SetUnit(unit, hideStatus)
        self:Hide(); self:ClearLines(); self.unit, self.hideStatus = unit, hideStatus
        self.unitCalls = (self.unitCalls or 0) + 1
        return unitResult
    end
    function methods:GetUnit() return "Pet", self.unit end
    function methods:AddLine(text) self.lines[#self.lines + 1] = text end
    function methods:SetText(text) self.lines = { text } end
    function methods:SetPoint(...) self.point = { ... } end
    function methods:SetSize(w, h) self.width, self.height = w, h end
    function methods:GetWidth() return self.width end
    function methods:GetFrameLevel() return self.level or 1 end
    function methods:SetFrameLevel(level) self.level = level end
    function methods:SetMinimumWidth(width) self.minimumWidth = width end
    function methods:CreateTexture() return widget(nil, self) end
    function methods:CreateFontString() return widget(nil, self) end
    function methods:SetTexture(texture) self.texture = texture end
    function methods:SetStatusBarColor(...) self.color = { ... } end
    function methods:FadeOut() self.faded = true; self:Hide() end
    for _, method in ipairs({ "EnableMouse", "SetAllPoints", "SetTexCoord", "SetDrawEdge", "SetDrawBling", "SetReverse",
        "SetHideCountdownNumbers", "SetFont", "SetTextColor", "SetShadowColor", "SetShadowOffset", "SetBackdrop",
        "SetBackdropBorderColor", "ClearAllPoints", "SetDrawLayer", "SetAlpha", "RegisterEvent", "RegisterUnitEvent" }) do
        methods[method] = function() end
    end
    env.CreateFrame = function(kind, name, parent, template)
        local f = widget(name, parent)
        check(kind ~= "GameTooltip", client .. ": no duplicate display tooltip allocated")
        return f
    end
    env.UIParent = widget("UIParent")
    local nativeReset, nativeHealth = function() end, function() end
    nativeTip = widget("GameTooltip", env.UIParent)
    setmetatable(nativeTip, { __index = methods, __newindex = function(t, key, value)
        assert(not tostring(key):match("^_flux") and key ~= "UpdateTooltip", "native tooltip field written: " .. key)
        rawset(t, key, value)
    end })
    env.GameTooltip = nativeTip
    env.GameTooltipStatusBar = { SetScript = function() error("native health script replaced") end }
    nativeTip.StatusBar = env.GameTooltipStatusBar
    env.hooksecurefunc = function(tip, method, fn)
        if type(tip) == "string" then
            local original, hook = env[tip], method
            env[tip] = function(...) original(...); hook(...) end
            return
        end
        check(tip == nativeTip and method == "SetOwner", client .. ": narrow native ownership hook")
        ownerHooks[#ownerHooks + 1] = fn
    end
    env.GameTooltipUnitHealthBarMixin = { ResetUnitHealth = nativeReset, UpdateUnitHealth = nativeHealth }
    env.GameTooltip_OnShow = function(self) self.nativeShows = (self.nativeShows or 0) + 1 end
    env.GameTooltip_OnUpdate = function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < .2 then return end
        self.elapsed = 0
        local owner = self:GetOwner()
        if owner and owner.UpdateTooltip then owner:UpdateTooltip()
        elseif self.UpdateTooltip then self:UpdateTooltip() end
    end
    local nativeSourceRoot = os.getenv("FLUX_NATIVE_TOOLTIP_SOURCE_ROOT")
    if nativeSourceRoot then
        local source = read(nativeSourceRoot .. "/" .. client .. "/GameTooltip.lua")
        local function loadNative(name)
            local first = assert(source:find("function " .. name .. "(", 1, true))
            local last = source:find("\nfunction ", first + 1, true) or (#source + 1)
            assert(load(source:sub(first, last - 1), "@pinned-" .. client .. "-" .. name, "t", env))()
        end
        env.TOOLTIP_UPDATE_TIME = .2
        nativeTip.updateTooltipTimer = .2
        nativeTip.shoppingTooltips = { widget(), widget() }
        if source:find("function GameTooltip_IsUpdateNeeded(", 1, true) then loadNative("GameTooltip_IsUpdateNeeded") end
        loadNative("GameTooltip_OnUpdate")
    end
    nativeTip.scripts.OnUpdate = env.GameTooltip_OnUpdate
    env.GameTooltip_SetDefaultAnchor = function(tip, owner) tip:SetOwner(owner, "ANCHOR_NONE") end
    env.GameTooltip_AddBlankLineToTooltip = function(tip) tip:AddLine(" ") end
    env.GameTooltip_AddInstructionLine = function(tip, text) tip:AddLine(text) end
    env.UNIT_POPUP_RIGHT_CLICK = "Right click for options"
    env.C_Timer = { After = function(_, fn) queued[#queued + 1] = fn end,
        NewTicker = function(_, fn) local t = { callback = fn, Cancel = function(self) self.cancelled = true end }; tickers[#tickers + 1] = t; return t end }
    local UF = {}
    local ns = { UnitFrames = UF, API = { SafeGetAuraDataByIndex = function(_, index, filter)
        if index == 1 and filter == "HELPFUL" then return { auraInstanceID = 1, icon = 123, duration = 0, applications = 2 } end
    end } }
    local hudAnchor = widget("FluxHUDTestAnchor", env.UIParent)
    env.FluxWindowFrame = { GetFrame = function() return hudAnchor end }
    assert(load(read("Other/FluxHUDTooltip.lua"), "@hud-tooltip", "t", env))("_FluxUI", ns)
    assert(load(unitSource, "@unit-tooltip-owner", "t", env))(UF, ns)
    UF.HideUnitTooltip()
    check(UF.GetUnitTooltip(false) == nativeTip and UF.UnitTooltipState.owner == nil, client .. ": lookup uses existing Blizzard tooltip")
    local owner = { IsMouseOver = function() return hover end, IsShown = function() return ownerShown end, IsVisible = function() return ancestorShown and ownerShown end }
    for _, unit in ipairs({ false, "", 42, secret }) do UF.ShowUnitTooltip(owner, unit) end
    check(UF.GetUnitTooltip(false) == nativeTip and UF.UnitTooltipState.owner == nil, client .. ": invalid/opaque tokens do not claim native tooltip")
    exists = secret; UF.ShowUnitTooltip(owner, "party1")
    check(UF.GetUnitTooltip(false) == nativeTip and UF.UnitTooltipState.owner == nil, client .. ": opaque existence is not tested in Lua")
    exists = true; UF.ShowUnitTooltip(owner, "party1")
    local tip = UF.GetUnitTooltip(false)
    check(tip and tip == nativeTip and tip:IsShown() and tip.unit == "party1", client .. ": native live unit content")
    check(tip.point[1] == "BOTTOMLEFT" and tip.point[2] == hudAnchor and tip.point[3] == "TOPLEFT"
        and tip.point[4] == 0 and tip.point[5] == 30, client .. ": exact existing HUD position retained")
    check(UF.UnitTooltipState.owner == owner and tip:GetOwner() == owner, client .. ": native owner is actual hovered frame")
    check(tip:GetScript("OnUpdate") == env.GameTooltip_OnUpdate, client .. ": native refresh cadence retained")
    UF.ShowUnitTooltip(owner, "party1"); check(tip.unitCalls == 1, client .. ": duplicate enter reuses visible GUID")
    tip:GetScript("OnUpdate")(tip, .1); check(tip.unitCalls == 1, client .. ": no faster polling introduced")
    tip:GetScript("OnUpdate")(tip, .1); check(tip.unitCalls == 2, client .. ": native tick refreshes unit")
    guid = secret; UF.ShowUnitTooltip(owner, "party1"); UF.ShowUnitTooltip(owner, "party1")
    check(tip.unitCalls == 4 and UF.UnitTooltipState.guid == nil, client .. ": opaque GUID never cached or compared")
    guid = nil; UF.ShowUnitTooltip(owner, "party1"); check(tip.unitCalls == 5, client .. ": absent GUID refreshes normally")
    guid = "same-guid"
    local other = { IsMouseOver = function() return true end, IsShown = function() return true end }
    UF.ShowUnitTooltip(other, "party2"); UF.HideUnitTooltip(owner)
    check(tip:IsShown() and UF.UnitTooltipState.owner == other, client .. ": old owner cannot dismiss another unit tooltip")
    ownerShown = false; UF.ShowUnitTooltip(owner, "party1"); tip:GetScript("OnUpdate")(tip, .2)
    check(not tip:IsShown() and owner.UpdateTooltip == nil, client .. ": hidden owner dismisses and stops refresh")
    ownerShown, hover = true, true; UF.ShowUnitTooltip(owner, "party1"); hover = false; tip:GetScript("OnUpdate")(tip, .2)
    check(not tip:IsShown() and owner.UpdateTooltip == nil, client .. ": leaving hover dismisses and stops refresh")
    hover = true

    UF.ShowUnitTooltip(owner, "party1")
    ancestorShown = false; tip:GetScript("OnUpdate")(tip, .2)
    check(not tip:IsShown() and owner.UpdateTooltip == nil, client .. ": hidden ancestor retires native unit tip")
    ancestorShown = true
    UF.ShowUnitTooltip(owner, "party1")
    local staleRefresh = owner.UpdateTooltip
    tip:SetOwner(other, "ANCHOR_RIGHT"); tip:SetText("Native item"); tip:Show()
    staleRefresh(); UF.HideUnitTooltip(owner); UF.HideUnitTooltip()
    check(tip:IsShown() and tip:GetOwner() == other and tip.lines[1] == "Native item"
        and owner.UpdateTooltip == nil and UF.UnitTooltipState.owner == nil,
        client .. ": item takeover retires old refresh; stale leave/callback cannot hide or steal it")
    UF.ShowUnitTooltip(owner, "party1"); tip:ClearLines()
    check(owner.UpdateTooltip == nil and UF.UnitTooltipState.owner == nil, client .. ": native clear retires Flux state")
    unitResult = false; UF.ShowUnitTooltip(owner, "party1")
    check(not tip:IsShown() and owner.UpdateTooltip == nil, client .. ": failed SetUnit dismisses old content")
    unitResult = true
    forbidden = true; UF.ShowUnitTooltip(owner, "party1"); UF.HideUnitTooltip(owner)
    check(UF.GetUnitTooltip(true) == nil, client .. ": forbidden native tooltip not accessed")
    forbidden = false

    -- Load the full pet module; icons, spacers and cleanup must use this same tip.
    assert(load(read("UnitFrames/FluxUnitFrames_PetAuraTooltip.lua"), "@pet-tooltip", "t", env))("_FluxUI", ns)
    UF.ShowUnitTooltip(owner, secret)
    UF.ShowUnitTooltip(owner, "pet")
    local host = assert(made.FluxPetAuraTooltipHost)
    check(host.parent == tip and host:IsShown(), client .. ": pet aura host follows native tooltip")
    check(made.FluxPetAuraTooltipHostBuff1.Icon.texture == 123 and made.FluxPetAuraTooltipHostBuff1:IsShown(), client .. ": existing pet buff icon painted")
    check(#tip.lines > 0 and host.point[2] == tip, client .. ": pet aura spacers and anchors stay inside own tip")
    UF.HideUnitTooltip(other); check(host:IsShown(), client .. ": stale owner does not dismiss pet auras")
    UF.HideUnitTooltip(owner)
    check(not host:IsShown() and not tip:IsShown() and owner.UpdateTooltip == nil, client .. ": pet hide clears icons and refresh together")
    UF.ShowUnitTooltip(owner, "pet")
    local oldPetRefresh = owner.UpdateTooltip
    tip:SetOwner(other, "ANCHOR_NONE"); tip:SetText("World unit"); tip:Show()
    check(not host:IsShown() and owner.UpdateTooltip == nil, client .. ": world takeover clears pet icons and refresh")
    oldPetRefresh(); UF.HideUnitTooltip(owner)
    check(tip:IsShown() and tip.lines[1] == "World unit", client .. ": old pet callback cannot replace world content")
    local happinessEnter, happinessLeave = assert(load(happinessSource, "@pet-happiness-tooltip", "t", env))(UF)
    UF.ShowUnitTooltip(owner, "pet")
    local icon = { tooltip = "Happy", tooltipDamage = "125% damage", tooltipLoyalty = "Loyal", tooltipDiet = "Meat" }
    happinessEnter(icon)
    check(tip:IsShown() and UF.UnitTooltipState.owner == icon and tip:GetOwner() == icon
        and owner.UpdateTooltip == nil and #tip.lines == 4, client .. ": pet happiness text survives owner-reset hide and stops previous unit refresh")
    check(not host:IsShown(), client .. ": pet aura icons clear before happiness text reuses tooltip")
    happinessLeave(icon); check(not tip:IsShown(), client .. ": pet happiness leave dismisses its own tip")

    env.FluxRaid_RequestJoinedBorderRefresh = function() end
    local function region(frame, shown) if frame then if shown then frame:Show() else frame:Hide() end end end
    assert(load(raidSource, "@raid-tooltip-owner", "t", env))(ns, env.issecretvalue, region, {}, function() end)
    local raidOwner = { unit = "raid1", hideStatusOnTooltip = true, IsMouseOver = function() return true end,
        IsShown = function() return true end, mouseOverHighlight = widget() }
    env.FluxRaidUnit_OnEnter(raidOwner)
    check(tip.unit == "raid1" and tip.hideStatus and UF.UnitTooltipState.owner == raidOwner, client .. ": raid unit uses Blizzard tooltip")
    check(tip.lines[#tip.lines] == env.UNIT_POPUP_RIGHT_CLICK, client .. ": raid context-menu instruction preserved")
    local calls = tip.unitCalls; tip:GetScript("OnUpdate")(tip, .2)
    check(tip.unitCalls == calls + 1 and raidOwner.UpdateTooltip, client .. ": raid hover keeps native refresh cadence")
    env.FluxRaidUnit_OnHide(raidOwner)
    check(not tip:IsShown() and raidOwner.UpdateTooltip == nil, client .. ": raid owner hide clears its tooltip")
    env.FluxRaidUnit_OnEnter(raidOwner); UF.ShowUnitTooltip(other, "party2"); env.FluxRaidUnit_OnHide(raidOwner)
    check(tip:IsShown() and UF.UnitTooltipState.owner == other, client .. ": hidden raid owner preserves newer owner")
    env.FluxRaidUnit_OnEnter(raidOwner); env.FluxRaidUnit_OnLeave(raidOwner)
    check(tip.faded and not tip:IsShown(), client .. ": raid native fade-out retained")
    env.FluxRaidUnit_OnEnter(raidOwner); raidOwner.unit = nil; tip:GetScript("OnUpdate")(tip, .2)
    check(not tip:IsShown() and raidOwner.UpdateTooltip == nil, client .. ": recycled empty raid unit stops both refresh callbacks and stale content")

    env.FluxRaidPreview_ApplyIdleHighlights = function() end
    assert(load(previewSource, "@preview-tooltip-owner", "t", env))(ns, function() return true end)
    local previewOwner = { _previewUnit = "player", IsMouseOver = function() return true end, IsShown = function() return true end }
    env.FluxRaidPreviewUnit_OnEnter(previewOwner)
    check(tip.unit == "player" and UF.UnitTooltipState.owner == previewOwner, client .. ": real preview unit uses owned tooltip")
    env.FluxRaidPreviewUnit_OnLeave(previewOwner)
    check(not tip:IsShown(), client .. ": preview leave dismisses tooltip")
    env.FluxRaidPreviewUnit_OnEnter(previewOwner); UF.ShowUnitTooltip(other, "party2"); env.FluxRaidPreviewUnit_OnLeave(previewOwner)
    check(tip:IsShown() and UF.UnitTooltipState.owner == other, client .. ": stale preview leave preserves newer unit owner")
    local mixinKeys = 0
    for _ in pairs(env.GameTooltipUnitHealthBarMixin) do mixinKeys = mixinKeys + 1 end
    check(env.GameTooltip == nativeTip and env.GameTooltipUnitHealthBarMixin.ResetUnitHealth == nativeReset
        and env.GameTooltipUnitHealthBarMixin.UpdateUnitHealth == nativeHealth and mixinKeys == 2,
        client .. ": native tooltip and secure health mixin identity never changed")
    check(UF.GetUnitTooltip(true) == tip and not made.FluxUnitTooltip, client .. ": one Blizzard tooltip across all unit owners")
    check(tip:GetScript("OnUpdate") == env.GameTooltip_OnUpdate and #ownerHooks == 1,
        client .. ": native updater and single lifetime hook retained")
end
print("unit_tooltip_ownership: " .. checks .. " checks passed (desktop ownership/lifecycle only)")
