local addonName, ns = ...

-- Independently authored optional healer adjuncts. Settings belong to Flux's
-- existing raid scope. No reference-addon code, assets or settings are loaded.
FluxRaidHealerExtras = {}
local E = FluxRaidHealerExtras
local Compat = FluxRaidCompat
local State = FluxRaidState
local Flux = ns.Flux
local frames = setmetatable({}, { __mode = "k" })
local pets, target = {}, nil
local candidates, pendingLayout, events = nil, false, nil
local rosterUpdateQueued = false
local classBuffIDs, classBuffNames
local max, min, floor = math.max, math.min, math.floor

-- Alternative ranks share localized names. Group versions and mutually
-- exclusive alternatives count as present; only actually learned spells mark.
local BUFFS = {
    DRUID = { { ids={1126,21849} }, { ids={467}, tank=true } },
    MAGE = { { ids={1459,23028} }, { ids={6117,7302,168,30482}, selfOnly=true } },
    PRIEST = { { ids={1243,21562} }, { ids={14752,27681}, mana=true },
        { ids={976,27683} }, { ids={588}, selfOnly=true } },
    PALADIN = { { ids={19740,25782,19742,25894,20217,25898,20911,25899,19977,25890} } },
    SHAMAN = { { ids={462854} }, { ids={52127,324}, selfOnly=true } },
    WARLOCK = { { ids={687,706,28176}, selfOnly=true } },
    WARRIOR = { { ids={6673,469} } },
    HUNTER = { { ids={19506}, selfOnly=true } },
    DEATHKNIGHT = { { ids={57330} } },
    MONK = { { ids={115921} }, { ids={116781} } },
    EVOKER = { { ids={364342} } },
}

-- Factual rank families, including group versions. Vanilla/TBC/Forever
-- prerequisite chains were checked against the installed trainer data; this
-- is spell identity data, independently expressed here rather than addon code.
local CLASS_BUFF_RANKS = {
    PRIEST={976,1243,1244,1245,2791,10937,10938,10957,10958,14752,14818,14819,
        21562,21564,25312,25389,25433,27681,27683,27841,32999},
    MAGE={1459,1460,1461,10156,10157,23028,27126},
    DRUID={1126,5232,5234,6756,8907,9884,9885,21849,21850,26990},
    PALADIN={19740,19742,19834,19835,19836,19837,19838,19850,19852,19853,19854,
        19977,19978,19979,20217,20911,20912,20913,20914,25290,25291,25782,25890,
        25894,25898,25899,25916,25918,27140,27141,27142,27143,27144,27145,27168,27169},
    WARRIOR={469,2048,5242,6192,6673,11549,11550,11551,25289},
}

local function DB()
    return FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {}
end

local function Secret(value)
    return Compat and Compat.IsSecret and Compat.IsSecret(value)
end

local function Accessible(value)
    if Secret(value) then return false end
    local secrets = Flux and Flux.Secrets
    if type(value) == "table" and secrets and secrets.CanAccessTable then
        return secrets.CanAccessTable(value)
    end
    return not (type(value) == "table" and canaccesstable and not canaccesstable(value))
end

local function Combat()
    return InCombatLockdown and InCombatLockdown()
end

local function Enabled()
    return not FluxRaid_IsFluxRaidEnabled or FluxRaid_IsFluxRaidEnabled()
end

local function Unit(frame)
    return frame.displayedUnit or frame.unit
end

local function PlainCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and Accessible(value) then return value end
end

local function Known(id)
    local inv = _G.FluxInv
    if inv and inv.IsSpellKnown and PlainCall(inv.IsSpellKnown, id) == true then return true end
    return PlainCall(IsPlayerSpell, id) == true or PlainCall(IsSpellKnown, id) == true
        or (C_SpellBook and PlainCall(C_SpellBook.IsSpellKnown, id) == true)
end

function E.GetClassBuffFilter()
    if classBuffIDs then return classBuffIDs, classBuffNames end
    if Combat() then return {}, {} end
    classBuffIDs, classBuffNames = {}, {}
    local _, class = UnitClass("player")
    if not Accessible(class) then return classBuffIDs, classBuffNames end
    local spell = Flux and Flux.Spell
    local function add(id)
        classBuffIDs[id] = true
        if not spell or not spell.GetInfo then return end
        local ok, name = pcall(spell.GetInfo, id)
        if ok and Accessible(name) and type(name)=="string" and name~="" then classBuffNames[name]=true end
    end
    for _, id in ipairs(CLASS_BUFF_RANKS[class] or {}) do add(id) end
    for _, family in ipairs(BUFFS[class] or {}) do for _, id in ipairs(family.ids) do add(id) end end
    return classBuffIDs, classBuffNames
end

function E.InvalidateClassBuffFilter()
    classBuffIDs, classBuffNames = nil, nil
end

local function Candidates()
    if candidates then return candidates end
    candidates = {}
    local _, class = UnitClass("player")
    if not Accessible(class) then return candidates end
    local spell = Flux and Flux.Spell
    if not spell or not spell.GetInfo then return candidates end
    for _, entry in ipairs(BUFFS[class] or {}) do
        local names, icon, learned = {}, nil, false
        for _, id in ipairs(entry.ids) do
            local ok, name, _, texture = pcall(spell.GetInfo, id)
            if ok and Accessible(name) and type(name) == "string" and name ~= "" then
                names[name] = true
                if Known(id) then
                    learned = true
                    if not icon and Accessible(texture) then icon = texture end
                end
            end
        end
        if learned and icon then
            candidates[#candidates+1] = { names=names, icon=icon, selfOnly=entry.selfOnly, mana=entry.mana, tank=entry.tank }
        end
    end
    return candidates
end

function E.Clear(frame)
    for _, icon in ipairs(frame and frame._fluxMissingBuffIcons or {}) do icon:Hide() end
end

function E.Setup(frame)
    if not frame or frame._fluxRaidMini then return end
    frames[frame] = true
    if frame._fluxMissingBuffIcons or Combat() or DB().showMissingClassBuffs~=true then return end
    local parent = frame._fluxContent or frame.auraHost or frame
    local icons = {}
    for i=1,3 do
        local icon = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        icon:SetSize(9, 9)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetAlpha(0.4)
        icon:SetPoint("BOTTOMRIGHT", frame.healthBar or parent, "BOTTOMRIGHT", -2-(i-1)*10, 2)
        icon:Hide()
        icons[i] = icon
    end
    frame._fluxMissingBuffIcons = icons
end

local function PresentBuffs(unit)
    local names = {}
    local modern = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if not modern and not UnitAura then return nil end
    for i=1,80 do
        local name
        if modern then
            local ok, aura = pcall(modern, unit, i, "HELPFUL")
            if not ok or not Accessible(aura) then return nil end
            if aura == nil then return names end
            name = aura.name
        else
            local ok, value = pcall(UnitAura, unit, i, "HELPFUL")
            if not ok then return nil end
            name = value
        end
        if not Accessible(name) then return nil end
        if name == nil then return names end
        if type(name) ~= "string" or name == "" then return nil end
        names[name] = true
    end
    -- A capped scan is incomplete, so absence cannot establish a missing buff.
    return nil
end

function E.Update(frame)
    if not frame then return end
    E.Clear(frame)
    if frame._fluxRaidMini or Combat() or not Enabled() or DB().showMissingClassBuffs ~= true then return end
    local secrets = Flux and Flux.Secrets
    if secrets and secrets.AurasRestricted and secrets.AurasRestricted() then return end
    local unit = Unit(frame)
    if type(unit) ~= "string" or unit == "" then return end
    if frame.IsShown and not frame:IsShown() then return end
    if PlainCall(UnitExists, unit) ~= true or PlainCall(UnitIsConnected, unit) ~= true
        or PlainCall(UnitIsDeadOrGhost, unit) ~= false or PlainCall(UnitIsPlayer, unit) ~= true then return end
    local list = Candidates()
    if #list == 0 then return end
    local present = PresentBuffs(unit)
    if not present then return end
    E.Setup(frame)
    local icons = frame._fluxMissingBuffIcons
    if not icons then return end
    local count = 0
    for _, candidate in ipairs(list) do
        local applicable = not candidate.selfOnly or PlainCall(UnitIsUnit, unit, "player") == true
        if applicable and candidate.mana then applicable = PlainCall(UnitPowerType, unit) == 0 end
        if applicable and candidate.tank then applicable = PlainCall(UnitGroupRolesAssigned, unit) == "TANK" end
        if applicable then
            local found = false
            for name in pairs(candidate.names) do if present[name] then found = true; break end end
            if not found then
                count = count+1
                icons[count]:SetTexture(candidate.icon)
                icons[count]:Show()
                if count == 3 then break end
            end
        end
    end
end

local function UpdateAll()
    for frame in pairs(frames) do E.Update(frame) end
end

local function DriverAPI()
    local restricted = Flux and Flux.Restricted
    if not restricted or not restricted.PagingWorks or not restricted.PagingWorks()
        or not restricted.SetPagingSnippet or not restricted.RegisterPagingDriver
        or not restricted.UnregisterPagingDriver then return nil end
    return restricted
end

local function DisableCell(cell)
    local restricted = cell._fluxExtraDriverOwner or DriverAPI()
    if cell._fluxExtraDriver and restricted then restricted.UnregisterPagingDriver(cell, "raidextra") end
    cell._fluxExtraDriver = nil
    cell._fluxExtraDriverOwner = nil
    cell:Hide()
    cell:SetAttribute("unit", nil)
    if FluxRaid_BindUnit then FluxRaid_BindUnit(cell, nil) end
    E.Clear(cell)
end

local function ConfigureCell(cell, unit, condition, pet, column, row, offsetY, restricted)
    cell._fluxExtraPet = pet and true or false
    cell._fluxRaidMini = pet and true or false
    local width = FluxRaidVisuals.FRAME_WIDTH
    local height = pet and max(12, floor(FluxRaidVisuals.FRAME_HEIGHT/2+0.5)) or FluxRaidVisuals.FRAME_HEIGHT
    cell:SetSize(width, height)
    cell:ClearAllPoints()
    cell:SetPoint("TOPLEFT", State.containerFrame, "TOPRIGHT", 8+column*width, -offsetY-row*max(1,height-4))
    if FluxRaidVisuals.ApplyCellChrome then FluxRaidVisuals.ApplyCellChrome(cell, { height=height, showPower=not pet and DB().displayPowerBar~=false }) end
    cell:SetAttribute("unit", unit)
    if FluxRaid_BindUnit then FluxRaid_BindUnit(cell, unit) end
    if not restricted.SetPagingSnippet(cell, "_onstate-raidextra", [[ if newstate == "show" then self:Show() else self:Hide() end ]])
        or not restricted.RegisterPagingDriver(cell, "raidextra", condition) then
        DisableCell(cell)
        E.extraStatus = "Secure visibility driver unavailable"
        return
    end
    cell._fluxExtraDriver = true
    cell._fluxExtraDriverOwner = restricted
end

local function NewCell(name, pet)
    local template = pet and "FluxRaidPetUnitTemplate,SecureHandlerStateTemplate" or "FluxRaidUnitTemplate,SecureHandlerStateTemplate"
    local cell = CreateFrame("Button", name, State.containerFrame, template)
    cell._fluxHealerExtra = true
    return cell
end

local function SyncEvents()
    if not events then events = CreateFrame("Frame"); events:SetScript("OnEvent", function(_, event, ...) E.OnEvent(event, ...) end) end
    events:UnregisterAllEvents()
    local db = DB()
    if not pendingLayout and (not Enabled() or (db.showClassBuffs==false and db.showMissingClassBuffs~=true and not db.showPets and not db.showFriendlyTarget)) then return end
    for _, event in ipairs({ "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE" }) do
        pcall(events.RegisterEvent, events, event)
    end
    if db.showClassBuffs~=false or db.showMissingClassBuffs==true then
        for _, event in ipairs({"PLAYER_REGEN_DISABLED", "SPELLS_CHANGED", "SPELL_DATA_LOAD_RESULT"}) do
            pcall(events.RegisterEvent, events, event)
        end
    end
    if db.showPets then pcall(events.RegisterEvent, events, "UNIT_PET") end
    if db.showFriendlyTarget then
        pcall(events.RegisterEvent, events, "PLAYER_TARGET_CHANGED")
        pcall(events.RegisterEvent, events, "UNIT_FACTION")
    end
end

function E.RefreshLayout()
    if Combat() then pendingLayout = true; SyncEvents(); return end
    pendingLayout = false
    local db = DB()
    local wantPets, wantTarget = Enabled() and db.showPets==true, Enabled() and db.showFriendlyTarget==true
    local restricted = (wantPets or wantTarget) and DriverAPI() or nil
    if (wantPets or wantTarget) and not restricted then E.extraStatus = "Secure visibility driver unavailable"
    else E.extraStatus = nil end
    if State.containerFrame and restricted then
        if wantTarget then
            target = target or NewCell("FluxRaidFriendlyTarget")
            ConfigureCell(target, "target", "[group,@target,help,exists] show; hide", false, 0, 0, 0, restricted)
        elseif target then DisableCell(target) end
        local offsetY = wantTarget and (FluxRaidVisuals.FRAME_HEIGHT+8) or 0
        if wantPets then
            -- Preallocate both modes OOC; secure conditions handle summoning,
            -- dismissing and party/raid transitions without Lua layout writes.
            for i=1,45 do
                pets[i] = pets[i] or NewCell("FluxRaidPet"..i, true)
                local raid = i<=40
                local index = raid and i or i-40
                local unit = raid and ("raidpet"..i) or (index==1 and "pet" or "partypet"..(index-1))
                local mode = raid and "raid" or "party"
                ConfigureCell(pets[i], unit, "[group:"..mode..",@"..unit..",exists] show; hide", true,
                    floor((index-1)/5), (index-1)%5, offsetY, restricted)
            end
        else for _, pet in ipairs(pets) do DisableCell(pet) end end
    else
        for _, pet in ipairs(pets) do DisableCell(pet) end
        if target then DisableCell(target) end
    end
    SyncEvents()
    UpdateAll()
end

local function PaintExtraUnits()
    for _, pet in ipairs(pets) do
        if pet._fluxExtraDriver and pet:IsShown() and FluxRaid_PaintUnit then FluxRaid_PaintUnit(pet) end
    end
    if target and target._fluxExtraDriver and target:IsShown() and FluxRaid_PaintUnit then FluxRaid_PaintUnit(target) end
end

function E.OnEvent(event, unit)
    if event == "PLAYER_REGEN_DISABLED" then
        for frame in pairs(frames) do E.Clear(frame) end
        return
    end
    if event == "SPELLS_CHANGED" or event == "SPELL_DATA_LOAD_RESULT" or event == "PLAYER_ENTERING_WORLD" then
        candidates = nil
        E.InvalidateClassBuffFilter()
    end
    if event == "UNIT_FACTION" and unit ~= "target" then return end
    if event == "GROUP_ROSTER_UPDATE" then
        -- Both party and raid pet slots were prepared by RefreshLayout. Keep
        -- their native visibility drivers instead of rebinding all 45 slots.
        if rosterUpdateQueued then return end
        rosterUpdateQueued = true
        local function refresh()
            rosterUpdateQueued = false
            if pendingLayout or E.extraStatus then E.RefreshLayout()
            else UpdateAll(); PaintExtraUnits() end
        end
        if C_Timer and C_Timer.After then C_Timer.After(0, refresh) else refresh() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingLayout then E.RefreshLayout() else UpdateAll(); PaintExtraUnits() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        E.RefreshLayout()
    elseif event == "UNIT_PET" or event == "PLAYER_TARGET_CHANGED" or event == "UNIT_FACTION" then
        -- Visibility and reassignment belong to the already installed secure
        -- conditions; painting does not rebuild the protected layout in combat.
        PaintExtraUnits()
    else UpdateAll() end
end

E.GetExtraCells = function() return pets, target end
