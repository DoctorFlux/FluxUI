-- Real unit/pet/raid tooltip owners with isolated widgets. Ordinary Lua mocks
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
    local exists, guid, locked, hover, ownerShown = true, "same-guid", false, true, true
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
    function methods:SetScript(kind, fn) self.scripts[kind] = fn end
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
    function methods:IsForbidden() return false end
    function methods:SetOwner(owner, anchor) self:Hide(); self.owner, self.anchor = owner, anchor end
    function methods:GetOwner() return self.owner end
    function methods:SetUnit(unit, hideStatus)
        self:Hide(); self.unit, self.hideStatus, self.lines = unit, hideStatus, {}
        self.unitCalls = (self.unitCalls or 0) + 1
        return true
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
        if kind == "GameTooltip" then
            check(name == "FluxUnitTooltip" and template == "GameTooltipTemplate", client .. ": same native tooltip template")
            f.StatusBar = widget(name .. "StatusBar", f)
        end
        return f
    end
    env.UIParent = widget("UIParent")
    local nativeReset, nativeHealth = function() end, function() end
    local nativeTip = setmetatable({}, { __newindex = function() error("native tooltip field written") end,
        __index = function() error("native tooltip consumed by addon unit owner") end })
    env.GameTooltip, env.GameTooltipStatusBar = nativeTip, { SetScript = function() error("native health script replaced") end }
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
    env.GameTooltip_SetDefaultAnchor = function(tip, owner) tip:SetOwner(owner, "ANCHOR_NONE") end
    env.GameTooltip_AddBlankLineToTooltip = function(tip) tip:AddLine(" ") end
    env.GameTooltip_AddInstructionLine = function(tip, text) tip:AddLine(text) end
    env.UNIT_POPUP_RIGHT_CLICK = "Right click for options"
    env.C_Timer = { After = function(_, fn) queued[#queued + 1] = fn end,
        NewTicker = function(_, fn) local t = { callback = fn, Cancel = function(self) self.cancelled = true end }; tickers[#tickers + 1] = t; return t end }
    local UF = {}
    local ns = { UnitFrames = UF, API = { SafeGetAuraDataByIndex = function(_, index, filter)
        if index == 1 and filter == "HELPFUL" then return { auraInstanceID = 1, icon = 123, duration = 0, applications = 2 } end
    end }, ApplyHUDTooltipPosition = function(tip) check(tip ~= nativeTip, client .. ": explicit owned HUD position"); tip.hud = true end }
    assert(load(unitSource, "@unit-tooltip-owner", "t", env))(UF, ns)
    UF.HideUnitTooltip()
    check(UF.GetUnitTooltip(false) == nil, client .. ": hidden tooltip remains unallocated")
    local owner = { IsMouseOver = function() return hover end, IsShown = function() return ownerShown end }
    for _, unit in ipairs({ false, "", 42, secret }) do UF.ShowUnitTooltip(owner, unit) end
    check(UF.GetUnitTooltip(false) == nil, client .. ": invalid/opaque tokens allocate no tooltip")
    exists = secret; UF.ShowUnitTooltip(owner, "party1")
    check(UF.GetUnitTooltip(false) == nil, client .. ": opaque existence is not tested in Lua")
    exists = true; UF.ShowUnitTooltip(owner, "party1")
    local tip = UF.GetUnitTooltip(false)
    check(tip and tip ~= nativeTip and tip:IsShown() and tip.unit == "party1" and tip.hud, client .. ": isolated live unit content and HUD placement")
    check(tip._fluxUnitTipOwner == owner and tip:GetOwner() == env.UIParent, client .. ": logical owner retained independently of anchor")
    check(tip:GetScript("OnUpdate") == env.GameTooltip_OnUpdate, client .. ": native refresh cadence retained")
    local guard = assert(tip.StatusBar:GetScript("OnValueChanged"))
    guard(tip.StatusBar, secret); check(tip.StatusBar.color == nil, client .. ": opaque health never compared or recolored")
    guard(tip.StatusBar, .5); check(tip.StatusBar.color[2] == 1, client .. ": existing public health tint retained")
    UF.ShowUnitTooltip(owner, "party1"); check(tip.unitCalls == 1, client .. ": duplicate enter reuses visible GUID")
    tip:GetScript("OnUpdate")(tip, .1); check(tip.unitCalls == 1, client .. ": no faster polling introduced")
    tip:GetScript("OnUpdate")(tip, .1); check(tip.unitCalls == 2, client .. ": native tick refreshes unit")
    guid = secret; UF.ShowUnitTooltip(owner, "party1"); UF.ShowUnitTooltip(owner, "party1")
    check(tip.unitCalls == 4 and tip._fluxUnitTipGuid == nil, client .. ": opaque GUID never cached or compared")
    guid = nil; UF.ShowUnitTooltip(owner, "party1"); check(tip.unitCalls == 5, client .. ": absent GUID refreshes normally")
    guid = "same-guid"
    local other = { IsMouseOver = function() return true end, IsShown = function() return true end }
    UF.ShowUnitTooltip(other, "party2"); UF.HideUnitTooltip(owner)
    check(tip:IsShown() and tip._fluxUnitTipOwner == other, client .. ": old owner cannot dismiss another unit tooltip")
    ownerShown = false; UF.ShowUnitTooltip(owner, "party1"); tip:GetScript("OnUpdate")(tip, .2)
    check(not tip:IsShown() and tip.UpdateTooltip == nil, client .. ": hidden owner dismisses and stops refresh")
    ownerShown, hover = true, true; UF.ShowUnitTooltip(owner, "party1"); hover = false; tip:GetScript("OnUpdate")(tip, .2)
    check(not tip:IsShown() and tip.UpdateTooltip == nil, client .. ": leaving hover dismisses and stops refresh")
    hover = true

    -- Load the full pet module; icons, spacers and cleanup must use this same tip.
    assert(load(read("UnitFrames/FluxUnitFrames_PetAuraTooltip.lua"), "@pet-tooltip", "t", env))("_FluxUI", ns)
    UF.ShowUnitTooltip(owner, secret)
    UF.ShowUnitTooltip(owner, "pet")
    local host = assert(made.FluxPetAuraTooltipHost)
    check(host.parent == tip and host:IsShown(), client .. ": pet aura host follows isolated tooltip")
    check(made.FluxPetAuraTooltipHostBuff1.Icon.texture == 123 and made.FluxPetAuraTooltipHostBuff1:IsShown(), client .. ": existing pet buff icon painted")
    check(#tip.lines > 0 and host.point[2] == tip, client .. ": pet aura spacers and anchors stay inside own tip")
    UF.HideUnitTooltip(other); check(host:IsShown(), client .. ": stale owner does not dismiss pet auras")
    UF.HideUnitTooltip(owner)
    check(not host:IsShown() and not tip:IsShown() and tip.UpdateTooltip == nil, client .. ": pet hide clears icons and refresh together")
    local happinessEnter, happinessLeave = assert(load(happinessSource, "@pet-happiness-tooltip", "t", env))(UF)
    UF.ShowUnitTooltip(owner, "pet")
    local icon = { tooltip = "Happy", tooltipDamage = "125% damage", tooltipLoyalty = "Loyal", tooltipDiet = "Meat" }
    happinessEnter(icon)
    check(tip:IsShown() and tip._fluxUnitTipOwner == icon and tip:GetOwner() == icon
        and tip.UpdateTooltip == nil and #tip.lines == 4, client .. ": pet happiness text survives owner-reset hide and stops previous unit refresh")
    check(not host:IsShown(), client .. ": pet aura icons clear before happiness text reuses tooltip")
    happinessLeave(icon); check(not tip:IsShown(), client .. ": pet happiness leave dismisses its own tip")

    env.FluxRaid_RequestJoinedBorderRefresh = function() end
    local function region(frame, shown) if frame then if shown then frame:Show() else frame:Hide() end end end
    assert(load(raidSource, "@raid-tooltip-owner", "t", env))(ns, env.issecretvalue, region, {}, function() end)
    local raidOwner = { unit = "raid1", hideStatusOnTooltip = true, IsMouseOver = function() return true end,
        IsShown = function() return true end, mouseOverHighlight = widget() }
    env.FluxRaidUnit_OnEnter(raidOwner)
    check(tip.unit == "raid1" and tip.hideStatus and tip._fluxUnitTipOwner == raidOwner, client .. ": raid unit uses dedicated tooltip")
    check(tip.lines[#tip.lines] == env.UNIT_POPUP_RIGHT_CLICK, client .. ": raid context-menu instruction preserved")
    local calls = tip.unitCalls; tip:GetScript("OnUpdate")(tip, .2)
    check(tip.unitCalls == calls + 1 and raidOwner.UpdateTooltip, client .. ": raid hover keeps native refresh cadence")
    env.FluxRaidUnit_OnHide(raidOwner)
    check(not tip:IsShown() and tip.UpdateTooltip == nil and raidOwner.UpdateTooltip == nil, client .. ": raid owner hide clears its tooltip")
    env.FluxRaidUnit_OnEnter(raidOwner); UF.ShowUnitTooltip(other, "party2"); env.FluxRaidUnit_OnHide(raidOwner)
    check(tip:IsShown() and tip._fluxUnitTipOwner == other, client .. ": hidden raid owner preserves newer owner")
    env.FluxRaidUnit_OnEnter(raidOwner); env.FluxRaidUnit_OnLeave(raidOwner)
    check(tip.faded and not tip:IsShown(), client .. ": raid native fade-out retained")
    env.FluxRaidUnit_OnEnter(raidOwner); raidOwner.unit = nil; tip:GetScript("OnUpdate")(tip, .2)
    check(not tip:IsShown() and tip.UpdateTooltip == nil and raidOwner.UpdateTooltip == nil, client .. ": recycled empty raid unit stops both refresh callbacks and stale content")

    env.FluxRaidPreview_ApplyIdleHighlights = function() end
    assert(load(previewSource, "@preview-tooltip-owner", "t", env))(ns, function() return true end)
    local previewOwner = { _previewUnit = "player", IsMouseOver = function() return true end, IsShown = function() return true end }
    env.FluxRaidPreviewUnit_OnEnter(previewOwner)
    check(tip.unit == "player" and tip._fluxUnitTipOwner == previewOwner, client .. ": real preview unit uses owned tooltip")
    env.FluxRaidPreviewUnit_OnLeave(previewOwner)
    check(not tip:IsShown(), client .. ": preview leave dismisses tooltip")
    env.FluxRaidPreviewUnit_OnEnter(previewOwner); UF.ShowUnitTooltip(other, "party2"); env.FluxRaidPreviewUnit_OnLeave(previewOwner)
    check(tip:IsShown() and tip._fluxUnitTipOwner == other, client .. ": stale preview leave preserves newer unit owner")
    local mixinKeys = 0
    for _ in pairs(env.GameTooltipUnitHealthBarMixin) do mixinKeys = mixinKeys + 1 end
    check(env.GameTooltip == nativeTip and env.GameTooltipUnitHealthBarMixin.ResetUnitHealth == nativeReset
        and env.GameTooltipUnitHealthBarMixin.UpdateUnitHealth == nativeHealth and mixinKeys == 2,
        client .. ": native tooltip and secure health mixin identity never changed")
    check(UF.GetUnitTooltip(true) == tip, client .. ": one tooltip is reused across all unit owners")
end
print("unit_tooltip_ownership: " .. checks .. " checks passed (desktop ownership/lifecycle only)")
