-- Friendly debuff chrome. Native aura slots own restricted border colors;
-- readable types also color the existing numeric labels. Never tint backdrops.
local _, ns = ...
local UF = ns.UnitFrames
local states, dirty = {}, {}
local scheduled = false
local keys = {"TL", "TR", "BL", "BR", "Top", "Bottom", "Left", "Right"}
local knownTypes = {Magic = true, Curse = true, Disease = true, Poison = true, Bleed = true}

local function Secret(v)
    if ns.API and ns.API.IsSecretValue then return ns.API.IsSecretValue(v) end
    return issecretvalue and issecretvalue(v) or false
end
local function Accessible(v)
    if Secret(v) then return false end
    if type(v) == "table" and canaccesstable and not canaccesstable(v) then return false end
    return true
end
local function Eligible(frame)
    local unit = frame.unit
    return unit == "player" or unit == "target" or unit == "focus" or type(unit) == "string" and unit:match("^party[1-4]$") ~= nil
end
local function Friendly(unit)
    if unit == "player" then return true end
    local query = UnitCanAssist or UnitIsFriend
    if not query then return false end
    local ok, value = pcall(query, "player", unit, true, true)
    return ok and not Secret(value) and value == true
end
local function Enabled(frame)
    if not frame:IsVisible() or not Friendly(frame.unit) then return false end
    if frame._fluxPartyMember then return not frame.optionTable or frame.optionTable.displayDebuffs ~= false end
    if frame.unit == "target" or frame.unit == "focus" then
        local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
        local config = db and db[frame.unit == "focus" and "auraFocus" or "auraTarget"]
        return not config or config.showDebuffs ~= false
    end
    return true
end
local function Restricted()
    local secrets = ns.Flux and ns.Flux.Secrets
    local query = secrets and secrets.AurasRestricted or C_Secrets and C_Secrets.ShouldAurasBeSecret
    if not query then return false end
    local ok, value = pcall(query)
    return not ok or Secret(value) or value == true
end
local function OnlyDispellable(frame)
    -- Explicit false is a choice, not an invitation to OR another setting on.
    local opt = frame.optionTable
    if opt and opt.displayOnlyDispellableDebuffs ~= nil then return opt.displayOnlyDispellableDebuffs == true end
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
    if db and db.displayOnlyDispellableDebuffs ~= nil then return db.displayOnlyDispellableDebuffs == true end
    local name = frame._fluxPartyMember and "raidFramesDisplayOnlyDispellableDebuffs" or "showDispelDebuffs"
    local cv = ns.Flux and ns.Flux.CVar
    local query = cv and cv.GetBool or C_CVar and C_CVar.GetCVarBool or GetCVarBool or GetCVar
    if not query then return false end
    local ok, value = pcall(query, name)
    return ok and not Secret(value) and (value == true or value == "1" or value == 1)
end
local function Color(kind)
    if AuraUtil and AuraUtil.GetAuraBorderColor then
        local color = AuraUtil.GetAuraBorderColor(kind)
        if color and color.GetRGBA then return color:GetRGBA() end
    end
    -- Classic exposes the client display table rather than GetAuraBorderColor.
    if AuraUtil and AuraUtil.GetDebuffDisplayInfoTable then
        local info = AuraUtil.GetDebuffDisplayInfoTable()
        local entry = info[kind] or info.None
        if entry and entry.color then return entry.color:GetRGBA() end
    end
    local color = DebuffTypeColor and (DebuffTypeColor[kind or "none"] or DebuffTypeColor.none)
    if color then return color.r, color.g, color.b, 1 end
end
local function Clone(source, parent)
    local texture = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    local atlas = source.GetAtlas and source:GetAtlas()
    if type(atlas) == "string" and atlas ~= "" then texture:SetAtlas(atlas, false)
    else
        texture:SetTexture(source:GetTexture())
        if source.GetTexCoord then texture:SetTexCoord(source:GetTexCoord()) end
    end
    texture:SetAllPoints(source)
    return texture
end
local function BorderSources(surface)
    local sources, border = {}, surface and surface.FluxBorderFrame
    if border then for _, key in ipairs(keys) do if border[key] then sources[#sources + 1] = border[key] end end end
    return sources
end
local function Parts(frame)
    local root = BorderSources(frame)
    for _, texture in ipairs(BorderSources(frame.atlasBorderFrame)) do root[#root + 1] = texture end
    local parts = {{parent = frame, sources = root}}
    if frame.PortraitFrame then parts[#parts + 1] = {parent = frame.PortraitFrame, sources = BorderSources(frame.PortraitFrame)} end
    local separator = frame._fluxPartyDivider or frame.HealthPowerSeparator
    if separator then parts[#parts + 1] = {parent = frame, sources = {separator}, alphaSource = separator} end
    for _, part in ipairs(parts) do
        local level = UF.GetFramePublicLevel(frame) or 0
        for _, source in ipairs(part.sources) do
            local owner = source:GetParent()
            level = math.max(level, UF.GetFramePublicLevel(owner) or 0)
        end
        part.level = math.min(level + 1, 65530)
    end
    return parts
end
local function CaptureLabels(frame)
    local labels = {}
    for _, bar in ipairs({frame.Health, frame.Power}) do
        for _, key in ipairs({"Value", "Percent"}) do
            local label = bar and bar[key]
            if label then
                local r, g, b, a = 1, 1, 1, 1
                if label.GetTextColor then r, g, b, a = label:GetTextColor() end
                if Secret(r) or Secret(g) or Secret(b) or Secret(a) then r, g, b, a = 1, 1, 1, 1 end
                labels[#labels + 1] = {label = label, r = r, g = g, b = b, a = a}
            end
        end
    end
    return labels
end
local function PaintText(state, kind)
    if state.textKind == kind then return end
    local r, g, b, a
    if kind then r, g, b, a = Color(kind) end
    for _, item in ipairs(state.labels) do
        if r then item.label:SetTextColor(r, g, b, a)
        else item.label:SetTextColor(item.r, item.g, item.b, item.a) end
    end
    state.textKind = kind
end
local function BuildNative(state)
    if not (AuraContainerSortMethod and Enum and Enum.CustomAuraButtonDispelTypeTextureStyle) then return false end
    local created, initError = {}, nil
    local ok, message = pcall(function()
        for _, part in ipairs(state.parts) do
            if #part.sources > 0 then
                part.boxes = {}
                -- One owner switches its public filter with the effective UI
                -- policy. Native candidate filtering skips unknown types.
                for index, filter in ipairs({"HARMFUL|RAID"}) do
                    local box = CreateFrame("AuraContainer", nil, part.parent, "CustomAuraContainerTemplate")
                    created[#created + 1] = box; part.boxes[index] = box
                    box:SetAllPoints(part.parent); box:EnableMouse(false)
                    box:SetFrameLevel(part.level + index)
                    if box.SetEditModePreviewEnabled then box:SetEditModePreviewEnabled(false) end
                    if not box.SetAuraSlotFilterString then error("Aura slot filter setter unavailable") end
                    box:AddAuraSlot("friendlyTint", filter, {templateNames = {"FluxRaidDispelBorderTemplate"},
                        candidateFilters = {includeDispelTypes = knownTypes},
                        sortMethod = AuraContainerSortMethod.Default,
                        initializeFrame = function(button)
                            local success, message = pcall(function()
                                button:SetAllPoints(part.parent); button:EnableMouse(false)
                                button:SetFrameLevel(part.level + index + 1)
                                for _, source in ipairs(part.sources) do
                                    local texture = Clone(source, button)
                                    button:AddDispelTypeTexture(texture, {style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
                                        showWhenHarmful = true, showWhenHelpful = false, showWithoutDispelType = false})
                                end
                            end)
                            if not success then initError = message end
                        end})
                    box:SetUnit("none")
                    if initError then error(initError) end
                end
            end
        end
    end)
    if ok then return true end
    state.frame._fluxDebuffTintError = tostring(message)
    for _, box in ipairs(created) do if box.SetUnit then box:SetUnit("none") end; box:Hide() end
    for _, part in ipairs(state.parts) do part.boxes = nil end
    return false
end
local function BuildReadable(state)
    for _, part in ipairs(state.parts) do
        local host = CreateFrame("Frame", nil, part.parent)
        host:SetAllPoints(part.parent); host:EnableMouse(false)
        host:SetFrameLevel(part.level + 1)
        part.host, part.textures = host, {}
        for _, source in ipairs(part.sources) do part.textures[#part.textures + 1] = Clone(source, host) end
        host:Hide()
    end
end
local function Scan(unit, filter)
    -- Match the native includeDispelTypes candidate filter in default order.
    for index = 1, 40 do
        local kind
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
            if not ok or not Accessible(data) then return nil, false end
            if data == nil then return nil, true end
            if type(data) ~= "table" or not Accessible(data.dispelName) then return nil, false end
            kind = data.dispelName
        elseif UnitAura then
            local ok, name, _, _, dispel = pcall(UnitAura, unit, index, filter)
            if not ok or not Accessible(name) or not Accessible(dispel) then return nil, false end
            if name == nil then return nil, true end
            kind = dispel
        else return nil, false end
        if knownTypes[kind] then return kind, true end
    end
    return nil, true
end
local function Update(state, refreshNative)
    local frame = state.frame
    local unit = Enabled(frame) and frame.unit or "none"
    local filter = OnlyDispellable(frame) and "HARMFUL|RAID" or "HARMFUL"
    if state.native then
        for _, part in ipairs(state.parts) do
            for _, box in ipairs(part.boxes or {}) do
                if state.filter ~= filter then box:SetAuraSlotFilterString("friendlyTint", filter) end
                if state.unit ~= unit then box:SetUnit(unit)
                elseif state.filter == filter and refreshNative and unit ~= "none" then box:UpdateAllAuras() end
            end
        end
        state.unit, state.filter = unit, filter
    end
    for _, part in ipairs(state.parts) do
        if part.alphaSource and part.alphaSource.GetAlpha then
            local alpha = part.alphaSource:GetAlpha() -- Owned source; forward to a native sink without testing it.
            local shown = part.alphaSource:IsShown()
            if not Secret(shown) and not shown then alpha = 0 end
            if state.native then for _, box in ipairs(part.boxes or {}) do box:SetAlpha(alpha) end
            elseif part.host then part.host:SetAlpha(alpha) end
        end
    end
    local kind
    if unit ~= "none" and not Restricted() then
        local available
        kind, available = Scan(unit, filter)
        if not available then kind = nil end
    end
    PaintText(state, kind)
    if not state.native then
        local r, g, b, a
        if kind then r, g, b, a = Color(kind) end
        for _, part in ipairs(state.parts) do
            if r then for _, texture in ipairs(part.textures) do texture:SetVertexColor(r, g, b, a) end; part.host:Show()
            else part.host:Hide() end
        end
    end
end
function UF.PreviewDebuffTint(frame, kind)
    if not frame._fluxPartyPreview or not Eligible(frame) or InCombatLockdown() then return end
    if not knownTypes[kind] then kind = nil end
    local state = frame._fluxDebuffTintPreview
    if not state then
        state = {frame = frame, parts = Parts(frame), labels = CaptureLabels(frame), textKind = false}
        BuildReadable(state); frame._fluxDebuffTintPreview = state
    end
    PaintText(state, kind)
    local r, g, b, a
    if kind then r, g, b, a = Color(kind) end
    for _, part in ipairs(state.parts) do
        if r then for _, texture in ipairs(part.textures) do texture:SetVertexColor(r, g, b, a) end; part.host:Show()
        else part.host:Hide() end
    end
end
local function Flush()
    scheduled = false
    local batch = dirty; dirty = {}
    for frame, refreshNative in pairs(batch) do if states[frame] then Update(states[frame], refreshNative) end end
end
local function Queue(frame, refreshNative)
    dirty[frame] = dirty[frame] == true or refreshNative == true
    if scheduled then return end
    scheduled = true
    if C_Timer and C_Timer.After then C_Timer.After(0, Flush) else Flush() end
end
function UF.SetupDebuffTint(frame)
    if not frame or frame._fluxPartyPreview or not Eligible(frame) or states[frame] then return end
    if InCombatLockdown() then
        UF.DeferProtected("debuffTint." .. tostring(frame), function() UF.SetupDebuffTint(frame) end)
        return
    end
    local state = {frame = frame, parts = Parts(frame), labels = CaptureLabels(frame), textKind = false}
    states[frame] = state
    state.native = BuildNative(state)
    if not state.native then BuildReadable(state) end
    frame:HookScript("OnShow", function() Queue(frame, true) end)
    frame:HookScript("OnHide", function() Queue(frame) end)
    Queue(frame)
end
function UF.RefreshDebuffTint()
    for frame in pairs(states) do Queue(frame, true) end
end
local function MatchesUnit(frame, unit)
    if frame.unit == unit then return true end
    if not UnitIsUnit then return false end
    local ok, same = pcall(UnitIsUnit, frame.unit, unit)
    return ok and not Secret(same) and same == true
end
local events = CreateFrame("Frame")
for _, event in ipairs({"UNIT_AURA", "UNIT_FACTION", "UNIT_FLAGS", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "GROUP_ROSTER_UPDATE", "CVAR_UPDATE",
    "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, unit)
    if Secret(unit) then return end
    if event == "CVAR_UPDATE" and unit ~= "showDispelDebuffs" and unit ~= "raidFramesDisplayOnlyDispellableDebuffs" then return end
    for frame in pairs(states) do
        if event == "PLAYER_TARGET_CHANGED" then
            if frame.unit == "target" then Queue(frame, true) end
        elseif event == "PLAYER_FOCUS_CHANGED" then
            if frame.unit == "focus" then Queue(frame, true) end
        elseif event == "GROUP_ROSTER_UPDATE" then
            if frame._fluxPartyMember then Queue(frame, true)
            elseif frame.unit == "target" or frame.unit == "focus" then Queue(frame) end
        elseif event:sub(1, 5) == "UNIT_" then
            if MatchesUnit(frame, unit) then Queue(frame) end
        else
            -- Native SetUnit deliberately skips an unchanged token. Roster and
            -- world changes can replace its unit, so refresh the public owner.
            Queue(frame, true)
        end
    end
end)
