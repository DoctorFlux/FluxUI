local _, ns = ...
local Flux = ns.Flux

-- A header may reassign an MT/MA button during combat. Its mini must follow
-- inside the same secure attribute callback, before ordinary Lua paints it.
local Secure = {}
FluxRaidSecure = Secure
local hub, nextID = nil, 0
local attached = {}
local nativeWrap
local targetStatesReady = false
local targetStatesSuppressed = false
local partyFrames = {}

-- SecureHandlers.lua Wrapped_Attribute supplies self,name,value and preserves
-- the original handler unless this snippet explicitly returns false. It never
-- does. Only protected frame handles are read/written in this environment.
local TARGET_CHANGED = [=[
if (name == "unit" or name == "flux-raid-target-sync") and control:GetAttribute("armed-%d") then
    local target = control:GetFrameRef("target-%d")
    if target then
        local unit = self:GetAttribute("unit")
        if type(unit) == "string" and unit ~= "" then
            target:SetAttribute("unit", unit .. "target")
            local index = unit:match("^raid(%%d+)$")
            if index and control:GetAttribute("state-mt-target" .. index) == "show" and self:IsVisible() then
                target:Show()
            else target:Hide() end
        else
            target:SetAttribute("unit", nil)
            target:Hide()
        end
        if name == "flux-raid-target-sync" then
            target:SetAttribute("flux-raid-target-synced", value)
        end
    end
end
]=]

local TARGET_SHOWN = [=[
if control:GetAttribute("armed-%d") then
    local target = control:GetFrameRef("target-%d")
    local unit = self:GetAttribute("unit")
    if target and type(unit) == "string" and unit ~= "" then
        target:SetAttribute("unit", unit .. "target")
        local index = unit:match("^raid(%%d+)$")
        if index and control:GetAttribute("state-mt-target" .. index) == "show" then target:Show()
        else target:Hide() end
    end
end
]=]
local TARGET_HIDDEN = [=[
if control:GetAttribute("armed-%d") then
    local target = control:GetFrameRef("target-%d")
    if target then target:Hide() end
end
]=]

-- Forty shared native macro conditions cover the only source tokens the
-- MT/MA raid header assigns. Native dispatch owns target existence; no ordinary
-- Lua UnitExists result controls protected visibility or mouse hit regions.
local TARGET_EXISTENCE = [=[
local unit = "raid%dtarget"
for id = 1, self:GetAttribute("target-count") or 0 do
    if self:GetAttribute("armed-" .. id) then
        local target = self:GetFrameRef("target-" .. id)
        local source = self:GetFrameRef("source-" .. id)
        if target and source and target:GetAttribute("unit") == unit then
            if newstate == "show" and source:IsVisible() then target:Show()
            else target:Hide() end
        end
    end
end
]=]

local function InCombat()
    return InCombatLockdown and InCombatLockdown() or false
end

local function DisableTarget(target)
    target._fluxSecureTargetAttached = nil
    target._fluxSecureTargetUnsupported = true
    -- Failed setup happens before exposure, out of combat. A caller must never
    -- create or expose a previously unprepared target during lockdown.
    if InCombat() then return false end
    target:SetAttribute("unit", nil)
    target:Hide()
    if target.EnableMouse then target:EnableMouse(false) end
    return false
end

local function EnsureHub()
    local restricted = Flux and Flux.Restricted
    if not restricted or not restricted.PagingWorks or not restricted.PagingWorks() then return nil end
    if not hub then
        local ok, frame = pcall(CreateFrame, "Frame", "FluxRaidTargetSecureHub", nil, "SecureHandlerStateTemplate")
        if not ok or not frame or not frame.SetFrameRef or not frame.WrapScript then return nil end
        hub, nativeWrap = frame, frame.WrapScript
    end
    return hub, restricted
end

local function EnsureTargetStates(header, restricted)
    if targetStatesSuppressed then return true end
    if targetStatesReady then return true end
    if not restricted.SetPagingSnippet or not restricted.RegisterPagingDriver
        or not restricted.UnregisterPagingDriver then return false end
    header:SetAttribute("target-count", header:GetAttribute("target-count") or 0)
    -- Prove this owned frame's native state handler executes before installing
    -- subscriptions. Successful snippet execution alone is a different probe.
    if not restricted.SetPagingSnippet(header, "_onstate-flux-target-check",
        [[ self:SetAttribute("flux-target-check", newstate) ]]) then return false end
    header:SetAttribute("state-flux-target-check", "ready")
    if header:GetAttribute("flux-target-check") ~= "ready" then return false end
    local registered = 0
    for index = 1, 40 do
        local state = "mt-target" .. index
        local ready = restricted.SetPagingSnippet(header, "_onstate-" .. state,
            string.format(TARGET_EXISTENCE, index))
        if ready then header:SetAttribute("state-" .. state, nil) end
        if ready then ready = restricted.RegisterPagingDriver(header, state,
            "[@raid" .. index .. "target,exists] show; hide") end
        if not ready then
            restricted.UnregisterPagingDriver(header, state)
            for prior = 1, registered do restricted.UnregisterPagingDriver(header, "mt-target" .. prior) end
            return false
        end
        registered = index
    end
    targetStatesReady = true
    return true
end

function Secure.SuspendTargetWatches()
    if InCombat() then return false end
    targetStatesSuppressed = true
    local restricted = Flux and Flux.Restricted
    if hub then
        for index = 1, 40 do
            if targetStatesReady and restricted and restricted.UnregisterPagingDriver then
                restricted.UnregisterPagingDriver(hub, "mt-target" .. index)
            end
            -- Native state dispatch hides every matching target, including its
            -- input rectangle. Clearing also guarantees a fresh state edge when
            -- the existing shared drivers are enabled again.
            hub:SetAttribute("state-mt-target" .. index, nil)
        end
    end
    targetStatesReady = false
    return true
end

-- Call during target construction, before any ordinary target/unit writes.
-- On success, future unit assignments belong exclusively to the secure wrapper.
-- The target's ordinary OnAttributeChanged may bind its paint/events, but must
-- not replace its protected unit attribute during combat.
function Secure.AttachTarget(parent, target)
    if not parent or not target then return false end
    local previous = attached[parent]
    if previous and previous.target == target and previous.ready then return true end
    if InCombat() then return false end
    if previous and previous.target ~= target then
        previous.header:SetAttribute("armed-" .. previous.id, false)
        DisableTarget(previous.target)
    end
    local header, restricted = EnsureHub()
    if not header then return DisableTarget(target) end
    nextID = nextID + 1
    local id = nextID
    local record = { target = target, header = header, id = id }
    attached[parent] = record
    header:SetAttribute("armed-" .. id, false)
    local ok = pcall(header.SetFrameRef, header, "target-" .. id, target)
    if not ok then return DisableTarget(target) end
    ok = pcall(header.SetFrameRef, header, "source-" .. id, parent)
    if not ok then return DisableTarget(target) end
    local body = string.format(TARGET_CHANGED, id, id)
    local wrapped = restricted.WrapScript and restricted.WrapScript(header, parent, "OnAttributeChanged", body)
    if not wrapped then
        -- The legacy helper deliberately refuses Forever. PagingWorks has
        -- separately executed its repaired restricted engine, so use the native
        -- method captured from this owned secure header after that probe.
        wrapped = pcall(nativeWrap, header, parent, "OnAttributeChanged", body)
    end
    if not wrapped then return DisableTarget(target) end
    for _, entry in ipairs({ { "OnShow", TARGET_SHOWN }, { "OnHide", TARGET_HIDDEN } }) do
        local snippet = string.format(entry[2], id, id)
        local installed = restricted.WrapScript and restricted.WrapScript(header, parent, entry[1], snippet)
        if not installed then installed = pcall(nativeWrap, header, parent, entry[1], snippet) end
        if not installed then return DisableTarget(target) end
    end
    header:SetAttribute("armed-" .. id, true)
    header:SetAttribute("target-count", id)
    -- Exercise this exact wrapper, not merely function presence or Execute.
    -- The original parent callback also receives this addon-owned non-unit key.
    parent:SetAttribute("flux-raid-target-sync", id)
    if target:GetAttribute("flux-raid-target-synced") ~= id then
        header:SetAttribute("armed-" .. id, false)
        return DisableTarget(target)
    end
    -- Do not install shared native work until this actual source/target wrapper
    -- has passed its operational check. Keep this target hidden while the
    -- native initial condition values are populated, then reapply its source.
    header:SetAttribute("armed-" .. id, false)
    if not EnsureTargetStates(header, restricted) then return DisableTarget(target) end
    header:SetAttribute("armed-" .. id, true)
    parent:SetAttribute("flux-raid-target-sync", -id)
    if target:GetAttribute("flux-raid-target-synced") ~= -id then
        header:SetAttribute("armed-" .. id, false)
        return DisableTarget(target)
    end
    record.ready = true
    target._fluxSecureTargetAttached = true
    target._fluxSecureTargetUnsupported = nil
    if target.EnableMouse then target:EnableMouse(true) end
    return true
end

local headerControllers = {}
local childWrappers = {}
local HEADER_VISIBILITY = [=[
local header = self:GetFrameRef("header")
local owner = self:GetFrameRef("layout-owner")
local state = newstate or self:GetAttribute("state-raidgroup")
if header then
    if state == "show" then
        local container = owner and owner:GetFrameRef("roster-container")
        if container then container:Show() end
        header:Show()
    else header:Hide() end
end
if owner and owner:GetAttribute("roster-layout-ready") then owner:RunAttribute("_flux-roster-layout") end
]=]

-- Scalar roster modes are prepared once for every possible transition. A
-- separate state controller leaves the native group's attribute handler intact.
function Secure.ConfigureHeader(header, index, isMTMA)
    if not header or InCombat() then return false end
    local layoutOwner, restricted = EnsureHub()
    if not restricted or not restricted.SetPagingSnippet or not restricted.RegisterPagingDriver then
        header._fluxSecureRosterDriver = nil
        header:Hide()
        return false
    end
    if not isMTMA and (type(index) ~= "number" or index < 1 or index > 8) then return false end
    header:SetAttribute("showRaid", true)
    local normalParty = ns.PartyFrames and ns.PartyFrames.ready
    header:SetAttribute("showParty", not isMTMA and index == 1 and not normalParty)
    header:SetAttribute("showPlayer", true)
    header:SetAttribute("showSolo", false)
    header:SetAttribute("groupFilter", isMTMA and "MAINTANK,MAINASSIST" or tostring(index))
    local record = headerControllers[header]
    if not record then
        local ok, controller = pcall(CreateFrame, "Frame", nil, nil, "SecureHandlerStateTemplate")
        if not ok or not controller or not controller.SetFrameRef then header:Hide() return false end
        record = { controller = controller, restricted = restricted }
        headerControllers[header] = record
        controller:SetFrameRef("header", header)
        controller:SetFrameRef("layout-owner", layoutOwner)
    end
    record.isMTMA = isMTMA and true or false
    local condition = "[petbattle] hide; [group:raid] show; "
        .. (not isMTMA and index == 1 and not normalParty and "[group:party] show; " or "") .. "hide"
    if not restricted.SetPagingSnippet(record.controller, "_onstate-raidgroup", HEADER_VISIBILITY)
        or not restricted.RegisterPagingDriver(record.controller, "raidgroup", condition) then
        if restricted.UnregisterPagingDriver then restricted.UnregisterPagingDriver(record.controller, "raidgroup") end
        header._fluxSecureRosterDriver = nil
        header:Hide()
        return false
    end
    -- A repeated registration may retain the same native state after layout
    -- temporarily hid this header; explicitly reapply that retained state OOC.
    local applied = restricted.ExecutePaging and restricted.ExecutePaging(record.controller, HEADER_VISIBILITY)
    if not applied then applied = pcall(record.controller.Execute, record.controller, HEADER_VISIBILITY) end
    if not applied then header:Hide() return false end
    if isMTMA then
        targetStatesSuppressed = false
        if nextID > 0 and not EnsureTargetStates(layoutOwner, restricted) then
            restricted.UnregisterPagingDriver(record.controller, "raidgroup")
            record.enabled = false
            header._fluxSecureRosterDriver = nil
            header:Hide()
            return false
        end
    end
    record.enabled = true
    header._fluxSecureRosterDriver = true
    return true
end

function Secure.DisableHeader(header)
    if not header or InCombat() then return false end
    local record = headerControllers[header]
    if (record and record.isMTMA) or (FluxRaidState and header == FluxRaidState.mtmaHeader) then
        Secure.SuspendTargetWatches()
    end
    if record and record.enabled then
        local restricted = record.restricted
        if restricted.UnregisterPagingDriver then restricted.UnregisterPagingDriver(record.controller, "raidgroup") end
        record.enabled = false
    end
    header._fluxSecureRosterDriver = nil
    header:Hide()
    return true
end

-- Exact horizontal reverse-column math from the existing Flux layout, executed
-- against native unit attributes. Empty headers remain visible at alpha zero so
-- their native roster event handler can discover members during combat.
local ROSTER_LAYOUT = [=[
local container = self:GetFrameRef("roster-container")
local step = self:GetAttribute("roster-step")
if not container or not step then return end
local occupied = newtable()
local count = 0
for group = 1, 8 do
    local header = self:GetFrameRef("roster-group" .. group)
    if header and header:IsShown() then
        local child = header:GetFrameRef("child1")
        local unit = child and child:GetAttribute("unit")
        if type(unit) == "string" and unit ~= "" then occupied[group] = true count = count + 1 end
    end
end
local mt = self:GetFrameRef("roster-mt")
local mtCount = 0
if mt and mt:IsShown() then
    for i = 1, 40 do
        local child = mt:GetFrameRef("child" .. i)
        local unit = child and child:GetAttribute("unit")
        if type(unit) == "string" and unit ~= "" then mtCount = mtCount + 1 end
    end
end
local mtSlots = mtCount > 0 and math.ceil(mtCount / 4) or 0
local slots = math.max(9, count + mtSlots)
local rank = 0
for group = 1, 8 do
    local header = self:GetFrameRef("roster-group" .. group)
    if header then
        local x = (slots - group) * step
        if occupied[group] then x = (slots - 1 - rank) * step rank = rank + 1 end
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", "$parent", "TOPLEFT", x, 0)
        header:SetAlpha(occupied[group] and 1 or 0)
    end
end
if mt then
    local mtStep = self:GetAttribute("roster-mt-step") or 1
    local height = self:GetAttribute("roster-column-height") or 0
    local y = 0
    if mtCount >= 4 then y = math.max(0, height - math.min(4, mtCount) * mtStep) + (self:GetAttribute("roster-mt-extra-y") or 60) end
    mt:ClearAllPoints()
    mt:SetPoint("TOPLEFT", "$parent", "TOPLEFT", math.max(0, slots - count - mtSlots) * step, y)
    mt:SetAlpha(mtCount > 0 and count > 0 and 1 or 0)
end
container:SetWidth(slots * step)
]=]

-- Native state-visibility is handled directly by SecureStateDriver.resolveDriver.
-- It needs no addon layout snippet to reveal/hide a prepared unit button.
local PARTY_TEXT = [=[
local left = newstate == "show" and (self:GetAttribute("pet-offset") or 0) or 0
self:ClearAllPoints()
if self:GetAttribute("name-host") then
    self:SetPoint("TOPLEFT", "$parent", "TOPLEFT", self:GetAttribute("portrait-width") or 0, -2)
    self:SetPoint("BOTTOMRIGHT", "$parent", "TOPRIGHT", -44, -34)
elseif self:GetAttribute("health-host") and newstate == "show" then
    self:SetPoint("TOPLEFT", "$parent", "TOPLEFT", left, -2)
    self:SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", -left, -2)
    self:SetHeight(self:GetAttribute("text-band-height") or 30)
else
    self:SetPoint("TOPLEFT", "$parent", "TOPLEFT", left, 0)
    self:SetPoint("BOTTOMRIGHT", "$parent", "BOTTOMRIGHT", -left, 0)
end
self:SetAttribute("party-text-ready", true)
]=]

function Secure.ConfigurePartyFrames(members, pets, scale, petScale, showPets, portrait, targets, options)
    if InCombat() then return false end
    local restricted = Flux and Flux.Restricted
    if not restricted or not restricted.RegisterPagingDriver or not restricted.SetPagingSnippet then return false end
    local owner = EnsureHub()
    local container = members[1] and members[1]:GetParent()
    if not owner or not container then return false end
    owner:SetFrameRef("party-container", container)
    local ready = restricted.SetPagingSnippet(owner, "_onstate-partygroup", [[
        if newstate == "show" then
            local container = self:GetFrameRef("party-container")
            if container then container:Show() end
        end
    ]]) and restricted.RegisterPagingDriver(owner, "partygroup", "[petbattle] hide; [group:raid] hide; [group:party] show; hide")
    for i = 1, 4 do
        local member, pet, target = members[i], pets[i], targets and targets[i]
        partyFrames[i], partyFrames[i + 4], partyFrames[i + 8] = member, pet, target
        for kind = 1, 3 do
            local frame = kind == 1 and member or kind == 2 and pet or target
            local unit = kind == 1 and ("party" .. i) or kind == 2 and ("partypet" .. i) or ("party" .. i .. "target")
            local enabled = kind == 1 or kind == 2 and showPets or kind == 3 and options and options.showTargets
            if frame then
                local condition = enabled and ("[petbattle] hide; [group:raid] hide; [group:party,@" .. unit .. ",exists] show; hide") or "hide"
                ready = restricted.RegisterPagingDriver(frame, "visibility", condition) and ready
            end
        end
        for _, key in ipairs({"Health", "Power", "Name"}) do
            local text = member["_fluxParty" .. key .. "TextAnchor"]
            if text then
                text:SetAttribute("name-host", key == "Name")
                text:SetAttribute("health-host", key == "Health")
                text:SetAttribute("text-band-height", member._fluxPartyTextBandHeight or 30)
                text:SetAttribute("portrait-width", math.max(80, portrait and (options and options.height or 85) or 0))
                text:SetAttribute("pet-offset", 60 * petScale + 4)
                ready = restricted.SetPagingSnippet(text, "_onstate-petlayout", PARTY_TEXT) and ready
                local condition = showPets and ("[@partypet" .. i .. ",exists] show; hide") or "hide"
                text:SetAttribute("state-petlayout", nil)
                ready = restricted.RegisterPagingDriver(text, "petlayout", condition) and ready
            end
        end
    end
    if not ready then Secure.DisablePartyFrames() end
    return ready
end

function Secure.DisablePartyFrames()
    if InCombat() then return false end
    local restricted = Flux and Flux.Restricted
    if hub and restricted and restricted.UnregisterPagingDriver then
        restricted.UnregisterPagingDriver(hub, "partygroup")
        hub:SetAttribute("frameref-party-container", nil)
    end
    for _, frame in pairs(partyFrames) do
        if restricted and restricted.UnregisterPagingDriver then restricted.UnregisterPagingDriver(frame, "visibility") end
        frame:Hide()
        if frame._fluxPartyMember then
            for _, key in ipairs({"Health", "Power", "Name"}) do
                local text = frame["_fluxParty" .. key .. "TextAnchor"]
                if text and restricted and restricted.UnregisterPagingDriver then restricted.UnregisterPagingDriver(text, "petlayout") end
            end
        end
    end
    return true
end

function Secure.GetPartyStates()
    local parts = {}
    for i = 1, 4 do
        local frame = partyFrames[i]
        local value = frame and frame:GetAttribute("statehidden")
        if issecretvalue and issecretvalue(value) then value = "opaque" end
        parts[i] = tostring(value)
    end
    return "native-visibility:" .. table.concat(parts, ",")
end

function Secure.AttachHeaderChild(child)
    if not child then return false end
    if childWrappers[child] then return true end
    if InCombat() then return false end
    local header, restricted = EnsureHub()
    if not header then return false end
    local body = [[ if name == "unit" and control:GetAttribute("roster-layout-ready") then control:RunAttribute("_flux-roster-layout") end ]]
    local ok = restricted.WrapScript and restricted.WrapScript(header, child, "OnAttributeChanged", body)
    if not ok then ok = pcall(nativeWrap, header, child, "OnAttributeChanged", body) end
    childWrappers[child] = ok and true or nil
    return ok and true or false
end

-- Call OOC after precreating/wrapping all 40 group and 40 MT/MA children.
-- The container must inherit SecureFrameTemplate to accept a secure frame ref.
function Secure.RefreshRosterLayout(container, groups, mt, options)
    if InCombat() or not container or type(groups) ~= "table" then return false end
    local header, restricted = EnsureHub()
    if not header then return false end
    options = options or {}
    header:SetFrameRef("roster-container", container)
    for i = 1, 8 do
        if groups[i] then header:SetFrameRef("roster-group" .. i, groups[i])
        else header:SetAttribute("frameref-roster-group" .. i, nil) end
    end
    if mt then header:SetFrameRef("roster-mt", mt) else header:SetAttribute("frameref-roster-mt", nil) end
    header:SetAttribute("roster-step", tonumber(options.colStep) or (FluxRaidVisuals and FluxRaidVisuals.FRAME_WIDTH or 72))
    header:SetAttribute("roster-column-height", tonumber(options.columnHeight) or (FluxRaid_GetColumnHeight and FluxRaid_GetColumnHeight() or 215))
    header:SetAttribute("roster-cell-height", FluxRaidVisuals and FluxRaidVisuals.FRAME_HEIGHT or 44)
    header:SetAttribute("roster-cell-gap", -(FluxRaidVisuals and FluxRaidVisuals.CELL_JOIN_OVERLAP or 4))
    header:SetAttribute("roster-mt-step", tonumber(options.mtChildStep) or (FluxRaid_GetMTMAChildStep and FluxRaid_GetMTMAChildStep() or 66))
    header:SetAttribute("roster-mt-extra-y", tonumber(options.mtExtraY) or 60)
    header:SetAttribute("_flux-roster-layout", ROSTER_LAYOUT)
    header:SetAttribute("roster-layout-ready", true)
    local body = [[ self:RunAttribute("_flux-roster-layout") ]]
    if restricted.ExecutePaging then return restricted.ExecutePaging(header, body) end
    return pcall(header.Execute, header, body)
end

_G.FluxRaidSecure = Secure
