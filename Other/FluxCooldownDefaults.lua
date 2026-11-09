-- Native layout data only. Cooldown/aura pools and refresh handlers stay Blizzard-owned.
local addonName, ns = ...
local Defaults = {}
ns.CooldownDefaults = Defaults
local Flux = ns.Flux
local names = {"BuffBarCooldownViewer", "BuffIconCooldownViewer", "UtilityCooldownViewer", "EssentialCooldownViewer"}
local boundaryAttempted, boundaryVerified = false, false
local pending, applying, loggedIn = false, false, false
local Run

local function Accessible(v)
    return not (issecretvalue and issecretvalue(v)) and not (canaccessvalue and not canaccessvalue(v))
end

local function Number(v)
    return Accessible(v) and type(v) == "number" and v == v and math.abs(v) < math.huge
end

local function Copy(value, depth)
    if not Accessible(value) then return nil, "restricted layout value" end
    if type(value) ~= "table" then return value end
    if depth > 12 then return nil, "invalid layout depth" end
    local result = {}
    for k, v in pairs(value) do
        if not Accessible(k) or (type(k) ~= "string" and type(k) ~= "number") then return nil, "invalid layout key" end
        local item, err = Copy(v, depth + 1)
        if err then return nil, err end
        result[k] = item
    end
    return result
end

function Defaults.IsAvailable()
    local e = Enum
    local available = e and e.EditModeCooldownViewerSetting and e.EditModeCooldownViewerSystemIndices
        and e.EditModeSystem and e.EditModeLayoutType and e.EditModePresetLayouts and C_EditMode
        and type(C_EditMode.SaveLayouts) == "function" and type(C_EditMode.SetActiveLayout) == "function"
        and type(C_EditMode.IsValidLayoutName) == "function"
        and EditModeManagerFrame and EditModeManagerFrame.layoutInfo and _G[names[1]] ~= nil
    if not available then return false end
    for _, key in ipairs({"IconSize", "IconPadding", "Opacity", "VisibleSetting", "ShowTimer", "ShowTooltips",
        "BarWidthScale", "BarContent", "HideWhenInactive", "Orientation", "IconDirection", "IconLimit"}) do
        if not Number(e.EditModeCooldownViewerSetting[key]) then return false end
    end
    if not e.CooldownViewerOrientation or not e.CooldownViewerIconDirection or not e.CooldownViewerVisibleSetting
        or not e.CooldownViewerBarContent then return false end
    local values = {e.EditModeCooldownViewerSystemIndices.BuffBar, e.EditModeCooldownViewerSystemIndices.BuffIcon,
        e.EditModeCooldownViewerSystemIndices.Utility, e.EditModeCooldownViewerSystemIndices.Essential,
        e.CooldownViewerOrientation.Vertical, e.CooldownViewerIconDirection.Right, e.CooldownViewerVisibleSetting.Always,
        e.CooldownViewerBarContent.IconAndName, e.EditModeSystem.CooldownViewer, e.EditModeLayoutType.Preset,
        e.EditModeLayoutType.Character}
    for i = 1, 11 do if not Number(values[i]) then return false end end
    return Number(e.EditModePresetLayouts.Modern) and Number(e.EditModePresetLayouts.Classic)
end

-- Pure conversion. Never mutate a native preset, a custom layout, or its settings.
function Defaults.BuildPlan(source, geometry, layoutName)
    if not Defaults.IsAvailable() then return nil, "native cooldown viewers unavailable" end
    local active = source and source.layouts and source.layouts[source.activeLayout]
    if not active or active.layoutType ~= Enum.EditModeLayoutType.Preset then return nil, "custom layout preserved" end
    if not geometry or not Number(geometry.left) or not Number(geometry.top) then return nil, "player geometry unavailable" end
    local result, err = Copy(source, 0)
    if not result then return nil, err end
    local layout = Copy(active, 0)
    local presets = Enum.EditModePresetLayouts
    if not presets or (active.layoutIndex ~= presets.Modern and active.layoutIndex ~= presets.Classic) then
        return nil, "native Modern/Classic preset unavailable"
    end
    layoutName = layoutName or "FluxUI"
    local character = Enum.EditModeLayoutType.Character
    local maxLayouts = Constants and Constants.EditModeConsts and Constants.EditModeConsts.EditModeMaxLayoutsPerType
    if not Number(maxLayouts) then return nil, "native layout limit unavailable" end
    local count = 0
    for _, entry in ipairs(source.layouts) do
        if entry.layoutType == character then count = count + 1 end
        if entry.layoutName == layoutName then return nil, "existing " .. layoutName .. " layout preserved" end
    end
    if count >= maxLayouts then return nil, "character layout limit reached" end
    if not C_EditMode.IsValidLayoutName(layoutName) then return nil, "layout name unavailable" end
    layout.layoutName, layout.layoutType = layoutName, character
    layout.layoutIndex = nil -- Preset-only metadata is not part of a saved character layout.
    local s, ix = Enum.EditModeCooldownViewerSetting, Enum.EditModeCooldownViewerSystemIndices
    local indexes = {ix.BuffBar, ix.BuffIcon, ix.Utility, ix.Essential}
    local found = {}
    -- XML base widths: buff icons40, utility30, essential50. Four UI units between columns.
    local offsets = {0, -44, -78, -132}
    for _, system in ipairs(layout.systems) do
        if system.system == Enum.EditModeSystem.CooldownViewer then
            local slot
            for i = 1, 4 do if system.systemIndex == indexes[i] then slot = i end end
            if slot then
                if found[slot] then return nil, "duplicate cooldown system" end
                found[slot] = true
                local settings = {
                    [s.IconSize] = slot == 1 and 4 or 5, -- (percent - 50) / 10
                    [s.IconPadding] = slot <= 2 and 0 or 2,
                    [s.Opacity] = 50, -- (100 - 50) / 1
                    [s.VisibleSetting] = Enum.CooldownViewerVisibleSetting.Always,
                    [s.ShowTimer] = 1, [s.ShowTooltips] = 1,
                }
                if slot == 1 then
                    settings[s.BarWidthScale] = 107 -- (157 - 50) / 1
                    settings[s.BarContent] = Enum.CooldownViewerBarContent.IconAndName
                    settings[s.HideWhenInactive] = 1
                else
                    settings[s.Orientation] = Enum.CooldownViewerOrientation.Vertical
                    settings[s.IconDirection] = Enum.CooldownViewerIconDirection.Right -- Native vertical label: Up.
                    if slot == 2 then settings[s.HideWhenInactive] = 1 else settings[s.IconLimit] = 20 end
                end
                local remaining = {}
                for key, value in pairs(settings) do remaining[key] = value end
                for _, setting in ipairs(system.settings) do
                    if remaining[setting.setting] ~= nil then
                        setting.value = remaining[setting.setting]
                        setting.displayValue = nil
                        remaining[setting.setting] = nil
                    end
                end
                for key, value in pairs(remaining) do system.settings[#system.settings + 1] = {setting = key, value = value} end
                system.anchorInfo = {point = "BOTTOMLEFT", relativeTo = "UIParent", relativePoint = "BOTTOMLEFT",
                    offsetX = geometry.left + offsets[slot], offsetY = geometry.top + 4}
                system.anchorInfo2, system.isInDefaultPosition = nil, false
            end
        end
    end
    for i = 1, 4 do if not found[i] then return nil, "native cooldown system not ready" end end
    result.layouts[#result.layouts + 1] = layout
    return result, #result.layouts
end

local function Preset(source, id)
    for i, entry in ipairs(source.layouts) do
        if entry.layoutType == Enum.EditModeLayoutType.Preset and entry.layoutIndex == id then return i, entry end
    end
end

local function OriginalCopy(source, entry, name)
    if not C_EditMode.ConvertLayoutInfoToString then return false end
    local geometry
    for _, system in ipairs(entry.systems) do
        if system.system == Enum.EditModeSystem.CooldownViewer and system.systemIndex == Enum.EditModeCooldownViewerSystemIndices.BuffBar then
            local a = system.anchorInfo
            if a and a.point == "BOTTOMLEFT" and a.relativeTo == "UIParent" and a.relativePoint == "BOTTOMLEFT"
                and Number(a.offsetX) and Number(a.offsetY) then geometry = {left = a.offsetX, top = a.offsetY - 4} end
        end
    end
    if not geometry then return false end
    local encoded = C_EditMode.ConvertLayoutInfoToString(entry)
    if not Accessible(encoded) or type(encoded) ~= "string" then return false end
    for _, id in ipairs({Enum.EditModePresetLayouts.Modern, Enum.EditModePresetLayouts.Classic}) do
        local _, preset = Preset(source, id)
        if preset then
            local plan, index = Defaults.BuildPlan({activeLayout = 1, layouts = {preset}}, geometry, name)
            if plan then
                local expected = C_EditMode.ConvertLayoutInfoToString(plan.layouts[index])
                if Accessible(expected) and type(expected) == "string" and encoded == expected then return true end
            end
        end
    end
    return false
end

-- Consolidate only recognized, unchanged generated copies. Edited profiles are
-- retained; removed copies have bounded recovery data in the existing char root.
function Defaults.BuildDefaults(source, geometry, state)
    if not Defaults.IsAvailable() then return nil, "native cooldown viewers unavailable" end
    local result, err = Copy(source, 0)
    if not result then return nil, err end
    for _, entry in ipairs(source.layouts) do
        if entry.layoutName == "FluxUI" then return nil, "existing FluxUI layout preserved" end
    end
    local active = source.layouts[source.activeLayout]
    local presetID = Enum.EditModePresetLayouts.Modern
    if active and (active.layoutIndex == Enum.EditModePresetLayouts.Classic or active.layoutName == "Flux Classic") then
        presetID = Enum.EditModePresetLayouts.Classic
    end
    local retired, retiredNames, kept, activeIndex, wasGenerated = {}, {}, {}, nil, false
    for i, entry in ipairs(result.layouts) do
        local name = entry.layoutName
        local recognized = (name == "Flux Modern" or name == "Flux Classic")
            and state and state.previousLayouts and state.previousLayouts[name] == true
        if name == "Flux Cooldowns" and state and state.legacyLayoutName == name and state.legacyStage == "applied" then recognized = true end
        if recognized and not retiredNames[name] and OriginalCopy(source, entry, name) then
            retired[#retired + 1] = entry
            retiredNames[name] = true
            if i == source.activeLayout then wasGenerated = true end
        else
            kept[#kept + 1] = entry
            if i == source.activeLayout then activeIndex = #kept end
        end
    end
    result.layouts = kept
    local index = Preset(result, presetID)
    if not index then return nil, "native Modern/Classic preset unavailable" end
    result.activeLayout = index
    local plan, added = Defaults.BuildPlan(result, geometry)
    if not plan then return nil, added end
    local activate = wasGenerated or (active and active.layoutType == Enum.EditModeLayoutType.Preset
        and (active.layoutIndex == Enum.EditModePresetLayouts.Modern or active.layoutIndex == Enum.EditModePresetLayouts.Classic))
    plan.activeLayout = activeIndex or index
    return plan, added, activate, retired
end

function Defaults.GetGeometry()
    local classPower = ns.ClassPower
    local player = ns.PlayerFrame
    if FluxUnitFrames_ShouldUseFlux and not FluxUnitFrames_ShouldUseFlux("player") then player = _G.PlayerFrame end
    if classPower and classPower.GetLayoutBounds then return classPower.GetLayoutBounds(player) end
end

local function MetadataSafe()
    if type(issecurevariable) ~= "function" then return false end
    local manager = EditModeManagerFrame
    if not manager or not issecurevariable(manager, "layoutInfo") then return false end
    for i = 1, #names do
        local f = _G[names[i]]
        if not f then return false end
        for _, key in ipairs({"systemInfo", "settingMap", "auraInstanceIDToItemFramesMap", "itemFramePool"}) do
            if not issecurevariable(f, key) then return false end
        end
    end
    return true
end

local function CanWrite()
    if InCombatLockdown and InCombatLockdown() then return false, "leave combat first" end
    if FluxEditModeBusy and FluxEditModeBusy() then return false, "close Edit Mode first" end
    if not Defaults.IsAvailable() then return false, "native cooldown viewers unavailable" end
    if not MetadataSafe() then return false, "native layout metadata is already tainted; reload first" end
    return true
end

local function State()
    local root = Flux.DB.GetChar()
    if root.cooldownDefaults == nil then root.cooldownDefaults = {version = 3} end
    local state = root.cooldownDefaults
    if type(state) ~= "table" then return end
    if state.version == 1 then
        state.legacyLayoutName, state.legacyStage = state.layoutName, state.stage
        if state.stage ~= "failed" and state.stage ~= "saving" and state.stage ~= "activating" then state.stage = nil end
        state.layoutName, state.managed, state.version = nil, nil, 2
    end
    if state.version == 2 then
        state.previousLayouts, state.layouts = state.layouts, nil
        if state.stage ~= "failed" and state.stage ~= "saving" and state.stage ~= "activating" then state.stage = nil end
        state.version = 3
    end
    if state.version == 3 then return state end
end

local function ActiveLayout()
    local root = EditModeManagerFrame and EditModeManagerFrame.layoutInfo
    return root and root.layouts and root.layouts[root.activeLayout]
end

local function FluxLayoutExists(source)
    for _, layout in ipairs(source.layouts) do
        if layout.layoutName == "FluxUI" then return true end
    end
    return false
end

local function StopOnNativeSave()
    if applying then return end
    local state, active = State(), ActiveLayout()
    if state and state.layouts and active and state.layouts[active.layoutName] then
        state.layouts[active.layoutName] = false
        state.lastCustomized = active.layoutName
    end
    Defaults.Request()
end

local function FollowPlayer(state, active)
    if not state.layouts or not active or not state.layouts[active.layoutName] then return end
    local geometry = Defaults.GetGeometry()
    if not geometry then return end
    local offsets = {0, -44, -78, -132}
    for i = 1, #names do
        local frame = _G[names[i]]
        -- Saved widget methods avoid native snapping/dirty-state overrides. Never
        -- call viewer layout, setting, refresh, visibility or aura methods here.
        if not frame or not frame.ClearAllPointsBase or not frame.SetPointBase then return end
    end
    for i = 1, #names do
        local frame = _G[names[i]]
        local x, y = geometry.left + offsets[i], geometry.top + 4
        local point, relative, relativePoint, oldX, oldY = frame:GetPoint(1)
        if not Accessible(point) or not Accessible(relative) or not Accessible(relativePoint)
            or not Accessible(oldX) or not Accessible(oldY) then return end
        if point ~= "BOTTOMLEFT" or relative ~= UIParent or relativePoint ~= "BOTTOMLEFT" or oldX ~= x or oldY ~= y then
            frame:ClearAllPointsBase()
            frame:SetPointBase("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
        end
    end
end

Run = function()
    pending = false
    if applying or not loggedIn or not Defaults.IsAvailable() then return end
    if InCombatLockdown and InCombatLockdown() then
        Flux.Combat.Defer("cooldown.defaults", Defaults.Request)
        return
    end
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(Defaults.Request, "cooldown.defaults")
        return
    end
    local ready = CanWrite()
    if not ready then return end
    local state = State()
    if not state or state.stage == "saving" or state.stage == "activating" or state.stage == "failed" then return end
    local active = ActiveLayout()
    local source = EditModeManagerFrame.layoutInfo
    if FluxLayoutExists(source) then
        state.stage = state.stage or "existing"
        FollowPlayer(state, active)
        return
    end
    -- Recreate a missing profile even after a previous creation or native save.
    -- Legacy-copy consolidation is a first-creation migration, not repeated cleanup.
    local migration
    if not state.stage then migration = state end
    local plan, index, activate, retired = Defaults.BuildDefaults(source, Defaults.GetGeometry(), migration)
    if not plan then return end
    -- Engine round-trip verified on Forever70862. Do not invoke the manager's
    -- Lua setters or OnLayoutAdded callback to route around execution taint.
    state.stage = "saving"
    state.layouts = {FluxUI = true}
    if #retired > 0 or state.retiredLayouts == nil then state.retiredLayouts = retired end
    applying = true
    C_EditMode.SaveLayouts(plan)
    if not MetadataSafe() then
        state.stage, applying = "failed", false
        print("[FluxUI] Cooldown defaults stopped: native metadata changed; reload before continuing.")
        return
    end
    if activate then
        state.stage = "activating"
        C_EditMode.SetActiveLayout(index)
    end
    applying = false
    if not MetadataSafe() then state.stage = "failed"; return end
    active = ActiveLayout()
    if activate and (not active or active.layoutName ~= "FluxUI") then state.stage = "failed"; return end
    state.stage = "applied"
    FollowPlayer(state, active)
end

function Defaults.Request()
    if pending or applying or not loggedIn then return end
    pending = true
    Flux.Timer.Defer(Run)
end

-- Explicit one-call probe only. No internal setter, secure callback routing, or retries.
-- Round-trip an unchanged copy through the documented engine API before enabling defaults.
function Defaults.TestBoundary()
    local ready, reason = CanWrite()
    if not ready then return false, reason end
    if boundaryAttempted then return boundaryVerified, "one boundary test per reload" end
    local copy, err = Copy(EditModeManagerFrame.layoutInfo, 0)
    if not copy then return false, err end
    boundaryAttempted = true
    local root = Flux.DB.GetChar()
    root.cooldownDefaultsProbe = {stage = "saving", build = select(2, GetBuildInfo())}
    C_EditMode.SaveLayouts(copy)
    boundaryVerified = MetadataSafe()
    root.cooldownDefaultsProbe.stage = boundaryVerified and "metadata-pass" or "metadata-fail"
    return boundaryVerified, boundaryVerified and "unchanged native save: metadata PASS; native interactions still required" or "native metadata FAIL; reload before continuing"
end

function Defaults.Status()
    if not Defaults.IsAvailable() then return "native cooldown viewers unavailable" end
    local state = State()
    if state and state.stage ~= "failed" and not FluxLayoutExists(EditModeManagerFrame.layoutInfo) then
        return "FluxUI layout missing; waiting for safe creation"
    end
    if state and state.stage then
        local active = ActiveLayout()
        local follows = state.layouts and active and state.layouts[active.layoutName]
        return state.stage .. (follows and "; following player/class power until saved in Edit Mode" or "; custom layouts are preserved")
    end
    local plan, reason = Defaults.BuildDefaults(EditModeManagerFrame.layoutInfo, Defaults.GetGeometry(), state)
    if plan then return "FluxUI layout ready; native presets remain unchanged" end
    return reason
end

-- One coalesced readiness/layout job, with no ticker, aura scan, or frame polling.
local client = Flux.Client or {}
if client.isRetail or client.isForever or client.isCamelot then
    Flux.Events.Register("PLAYER_LOGIN", function() loggedIn = true; Defaults.Request() end)
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_SPECIALIZATION_CHANGED", "UPDATE_SHAPESHIFT_FORM",
        "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "EDIT_MODE_LAYOUTS_UPDATED"}) do
        Flux.Events.Register(event, Defaults.Request)
    end
    Flux.Events.Register("ADDON_LOADED", function(_, name)
        if name == "Blizzard_CooldownViewer" then Defaults.Request() end
    end)
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.SavedLayouts", StopOnNativeSave, Defaults)
        EventRegistry:RegisterCallback("EditMode.Exit", Defaults.Request, Defaults)
    end
end

SLASH_FLUXCOOLDOWNS1 = "/fluxcooldowns"
SlashCmdList.FLUXCOOLDOWNS = function(message)
    if (message or ""):lower():match("^%s*test%s*$") then
        local _, reason = Defaults.TestBoundary()
        print("[FluxUI] Cooldown defaults: " .. reason)
    else
        print("[FluxUI] Cooldown defaults: " .. Defaults.Status())
    end
end
