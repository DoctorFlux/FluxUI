-- One original World Map surface, shared between Flux and the normal window.
-- Addons retain their frames, regions, closures, providers and map identity.
-- No addon discovery, provider cloning, canvas scans or extra rendering loop.
-- Native layout and panel moves wait for combat to end. Native panel state
-- and map methods stay owned by Blizzard (in particular the gamepad paths).
local _, addonTable = ...
local client = addonTable.Flux.Client
local guardQuestEvents = client and client.isForever
local restrictionType = Enum and Enum.AddOnRestrictionType
local restrictionState = Enum and Enum.AddOnRestrictionState
FluxBattlefieldWorldMap = {}
local Surface = FluxBattlefieldWorldMap
local state = {
    requested = false, embedded = false, full = false, changing = false,
    queued = false, pendingFull = false, hooks = {}, reason = "inactive",
    targetsHooked = setmetatable({}, { __mode = "k" }),
    parentsHooked = setmetatable({}, { __mode = "k" }),
    worldsHooked = setmetatable({}, { __mode = "k" }),
    blackoutsHooked = setmetatable({}, { __mode = "k" }),
    chromeHooked = setmetatable({}, { __mode = "k" }),
    togglesHooked = setmetatable({}, { __mode = "k" }),
    geometryRetries = 0, preparationFailed = false,
}
local Sync, OpenFull, CloseFull
local events
local QUEST_EVENTS = { "QUEST_WATCH_LIST_CHANGED", "QUEST_LOG_UPDATE", "QUEST_POI_UPDATE" }
local PANEL_AREAS = { "left", "center", "right", "doublewide", "fullscreen" }
local CHROME_KEYS = { "BorderFrame", "MiniBorderFrame", "MaximizeMinimizeFrame", "NavBar", "SidePanelToggle", "QuestLog",
    "ContinentDropdown", "ZoneDropdown", "MinimapDropdown", "CloseButton", "TitleButton" }
local CHROME_GLOBALS = { "WorldMapTitleButton", "WorldMapFrameCloseButton" }
local INPUT_POLICIES = {
    { "ShouldZoomInOnClick", "SetShouldZoomInOnClick" },
    { "ShouldNavigateOnClick", "SetShouldNavigateOnClick" },
    { "ShouldPanOnClick", "SetShouldPanOnClick" },
    { "ShouldZoomInstantly", "SetShouldZoomInstantly" },
}
local MAX_GEOMETRY_PROBES = 6
local function InLockdown()
    return InCombatLockdown and InCombatLockdown()
end
local function InCombat()
    return state.combatTransition or InLockdown()
end
local function QueueSync()
    if state.queued then return end
    state.queued = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            state.queued = false
            Sync()
        end)
    else
        state.queued = false
        Sync()
    end
end
local function Allowed(frame)
    return frame and not (frame.IsForbidden and frame:IsForbidden())
end
local function HoldQuestEvents(world)
    if not guardQuestEvents or state.hostedWorld ~= world or world ~= _G.WorldMapFrame or not Allowed(world)
        or not world.IsEventRegistered or not world.UnregisterEvent or not world.RegisterEvent then return end
    local hold = state.questHold
    for _, event in ipairs(QUEST_EVENTS) do
        if world:IsEventRegistered(event) then
            if not hold then
                hold = { world = world, events = {} }
                state.questHold = hold
            end
            if not hold.events[event] then
                hold.events[event] = true
                events:RegisterEvent(event)
            end
            world:UnregisterEvent(event)
        end
    end
end
local function RestoreQuestEvents()
    local hold = state.questHold
    if not hold then return end
    state.questHold = nil
    local world = hold.world
    local visible = Allowed(world) and world:IsVisible()
    for event in pairs(hold.events) do
        events:UnregisterEvent(event)
        -- Normal OnHide removes provider registrations. A later native OnShow
        -- will re-register them if the map was closed during combat.
        if visible and not world:IsEventRegistered(event) then world:RegisterEvent(event) end
    end
    if visible and hold.dirty and world == _G.WorldMapFrame then return world end
end
local function ResumeAfterCombat()
    if not state.resumeAfterCombat then return end
    if InLockdown() then
        -- The first post-regen frame can still report lockdown. Retry once
        -- and allow the next native restriction/regen notification to retry.
        if state.recheckCombatExit and C_Timer and C_Timer.After then
            state.recheckCombatExit = false
            C_Timer.After(0, ResumeAfterCombat)
        end
        return
    end
    state.resumeAfterCombat, state.combatTransition = false, false
    local world = RestoreQuestEvents()
    if world and world.RefreshAllDataProviders and not state.pendingFull and not state.pendingClose
        and (state.requested or not state.embedded) then
        world:RefreshAllDataProviders()
    end
    Sync()
end
local function HideViewport()
    local viewport = state.viewport
    -- An adopted addon may contain protected children. Ownership of the empty
    -- viewport does not make hiding that entire tree legal during combat.
    if viewport and not (InCombat() and viewport.IsProtected and viewport:IsProtected()) then
        viewport:Hide()
    end
end
local function ReadMapID(frame)
    return frame and frame.GetMapID and frame:GetMapID()
end
local function SetMapID(frame, id)
    if id and frame.SetMapID and ReadMapID(frame) ~= id then frame:SetMapID(id) end
end
local function OtherPanelOpen()
    if not GetUIPanel then return false end
    -- Native World Map OnShow may maximize/restore the panel in its area.
    -- It must never do that to an unrelated panel occupying a native slot.
    for _, area in ipairs(PANEL_AREAS) do
        local frame = GetUIPanel(area)
        if frame and frame ~= state.world then return true end
    end
    return false
end
local function ReleaseFallback()
    if FluxBattlefieldMapPinRouter then FluxBattlefieldMapPinRouter:Uninstall() end
    if FluxBattlefieldMapProviders then FluxBattlefieldMapProviders:Detach(state.target) end
end
local function SnapshotRenderer(world)
    return {
        framebuffer = world.IsFrameBuffer and world.SetIsFrameBuffer and world:IsFrameBuffer(),
        flatten = world.GetFlattensRenderLayers and world.SetFlattensRenderLayers and world:GetFlattensRenderLayers(),
    }
end
local function SetRenderer(world, saved, embedded)
    -- Rebuilding a visible framebuffer can expose an incomplete render scene.
    -- Change these flags only while the original map is hidden, never in combat.
    if not saved or InCombat() or world:IsShown() then return end
    if saved.framebuffer ~= nil then
        local value = saved.framebuffer
        if embedded then value = false end
        if world:IsFrameBuffer() ~= value then world:SetIsFrameBuffer(value) end
    end
    if saved.flatten ~= nil then
        local value = saved.flatten
        if embedded then value = false end
        if world:GetFlattensRenderLayers() ~= value then world:SetFlattensRenderLayers(value) end
    end
end
local function ResumeFallback()
    if not state.requested then return end
    if FluxBattlefieldMapProviders then FluxBattlefieldMapProviders:Attach(state.target) end
    if FluxBattlefieldMapPinRouter then
        FluxBattlefieldMapPinRouter:Install()
        FluxBattlefieldMapPinRouter:ScheduleKickstart()
    end
end
local function SuspendMovementFade(world, preparing)
    -- Native OnShow registers this exact frame for movement fading. Remove
    -- both active and deferred registrations; the normal full-map OnShow
    -- registers itself again. Do not change mapFade or the shared driver.
    local fader = _G.PlayerMovementFrameFader
    if fader and fader.RemoveFrame then fader.RemoveFrame(world) end
    local alpha = preparing and 0 or 1
    if world:GetAlpha() ~= alpha then world:SetAlpha(alpha) end
end
local function HideNativeBlackout(world)
    local blackout = world and world.BlackoutFrame
    if not blackout or InCombat() then return end
    -- The normal maximized map is above its LOW fullscreen blackout. Flux's
    -- battlefield surface is BACKGROUND, so the same blackout would cover its
    -- terrain and addon drawings. This stock window decoration is not map data.
    if not state.blackoutsHooked[blackout] and blackout.HookScript then
        state.blackoutsHooked[blackout] = true
        blackout:HookScript("OnShow", function()
            if state.world == world and state.embedded and state.requested
                and not state.changing and not InCombat() then
                blackout:Hide()
            end
        end)
    end
    if blackout:IsShown() then blackout:Hide() end
end
local function CopyPoints(frame)
    local points = {}
    local function Pack(...) return { n = select("#", ...), ... } end
    for i = 1, frame:GetNumPoints() do points[i] = Pack(frame:GetPoint(i)) end
    return points
end
local function SourceOwns(frame, world)
    for _ = 1, 32 do
        if frame == world then return true end
        if not frame or not frame.GetParent then break end
        frame = frame:GetParent()
    end
    return false
end
local function SnapshotChrome(world)
    local frames, seen = {}, {}
    local function Add(frame)
        if frame and not seen[frame] and SourceOwns(frame, world) then
            seen[frame] = true
            frames[#frames + 1] = { frame = frame, shown = frame:IsShown() }
        end
    end
    for i = 1, #CHROME_KEYS do Add(world[CHROME_KEYS[i]]) end
    for i = 1, #CHROME_GLOBALS do Add(_G[CHROME_GLOBALS[i]]) end
    return frames
end
local function RestorePoints(frame, points)
    frame:ClearAllPoints()
    for i = 1, #points do
        local point = points[i]
        frame:SetPoint(unpack(point, 1, point.n))
    end
end
local function Snapshot(frame)
    local saved = {
        parent = frame:GetParent(), scale = frame:GetScale(), points = CopyPoints(frame),
        width = frame:GetWidth(), height = frame:GetHeight(), scrollPoints = CopyPoints(frame.ScrollContainer),
        strata = frame:GetFrameStrata(), level = frame:GetFrameLevel(),
        ignoreScale = frame.IsIgnoringParentScale and frame:IsIgnoringParentScale(),
        blackout = frame.BlackoutFrame,
        blackoutShown = frame.BlackoutFrame and frame.BlackoutFrame:IsShown(),
        mapID = ReadMapID(frame),
        mouse = frame.IsMouseEnabled and frame:IsMouseEnabled(),
        mouseClick = frame.IsMouseClickEnabled and frame:IsMouseClickEnabled(),
        mouseMotion = frame.IsMouseMotionEnabled and frame:IsMouseMotionEnabled(),
        chrome = SnapshotChrome(frame), input = {},
    }
    for i = 1, #INPUT_POLICIES do
        local policy = INPUT_POLICIES[i]
        if frame[policy[1]] and frame[policy[2]] then saved.input[i] = frame[policy[1]](frame) end
    end
    return saved
end
local function ApplyBattlefieldPresentation(world)
    local saved = state.saved
    if not saved or InCombat() then return end
    local wasChanging = state.changing
    state.changing = true
    if saved.mouse ~= nil and world.EnableMouse and world:IsMouseEnabled() then world:EnableMouse(false) end
    for i = 1, #saved.chrome do
        local frame = saved.chrome[i].frame
        if not state.chromeHooked[frame] and frame.HookScript then
            state.chromeHooked[frame] = true
            frame:HookScript("OnShow", function()
                if state.world == world and state.embedded and state.requested and not state.changing and not InCombat() then frame:Hide() end
            end)
        end
        if frame:IsShown() then frame:Hide() end
    end
    for i = 1, #INPUT_POLICIES do
        local policy = INPUT_POLICIES[i]
        if saved.input[i] ~= nil and state.target[policy[1]] then
            local value = state.target[policy[1]](state.target)
            if world[policy[1]](world) ~= value then world[policy[2]](world, value) end
        end
    end
    state.changing = wasChanging
end
local function Restore(frame)
    local saved = state.saved
    if not saved then return end
    SetRenderer(frame, saved.renderer, false)
    frame:SetParent(saved.parent)
    if frame.SetIgnoreParentScale and saved.ignoreScale ~= nil then
        frame:SetIgnoreParentScale(saved.ignoreScale)
    end
    frame:SetScale(saved.scale)
    frame:SetFrameStrata(saved.strata)
    frame:SetFrameLevel(saved.level)
    RestorePoints(frame.ScrollContainer, saved.scrollPoints)
    frame:SetSize(saved.width, saved.height)
    RestorePoints(frame, saved.points)
    if saved.alpha ~= nil then frame:SetAlpha(saved.alpha) end
    if saved.mouse ~= nil and frame.EnableMouse then frame:EnableMouse(saved.mouse) end
    if saved.mouseClick ~= nil and frame.SetMouseClickEnabled then frame:SetMouseClickEnabled(saved.mouseClick) end
    if saved.mouseMotion ~= nil and frame.SetMouseMotionEnabled then frame:SetMouseMotionEnabled(saved.mouseMotion) end
    for i = 1, #saved.chrome do saved.chrome[i].frame:SetShown(saved.chrome[i].shown) end
    for i = 1, #INPUT_POLICIES do
        local policy = INPUT_POLICIES[i]
        if saved.input[i] ~= nil and frame[policy[1]](frame) ~= saved.input[i] then frame[policy[2]](frame, saved.input[i]) end
    end
    if saved.blackout and saved.blackout.SetShown then saved.blackout:SetShown(saved.blackoutShown) end
    state.saved = nil
    state.canvasLayoutPending = false
end
local function CancelPreparation(restoreMap)
    local preparation = state.preparation
    if not preparation then return end
    local world = preparation.world
    state.preparation = nil
    if not Allowed(world) then return end
    state.changing = true
    world:Hide()
    SetRenderer(world, preparation.renderer, false)
    world:SetAlpha(preparation.alpha)
    if preparation.seeded then RestorePoints(world, preparation.points) end
    if restoreMap then SetMapID(world, preparation.mapID) end
    state.changing = false
end
local function Release(restoreMap)
    CancelPreparation(restoreMap)
    local world = state.world
    if not state.embedded or not Allowed(world) then return end
    state.changing = true
    local savedID = state.saved and state.saved.mapID
    world:Hide()
    Restore(world)
    if restoreMap then SetMapID(world, savedID) end
    state.embedded = false
    state.changing = false
    HideViewport()
end
local function InstallGlobalHook(name, fn)
    if not state.hooks[name] and type(_G[name]) == "function" and hooksecurefunc then
        state.hooks[name] = true
        hooksecurefunc(name, fn)
    end
end
local function OnNativeToggle()
    if state.changing or not state.requested then return end
    if state.full then
        CloseFull()
    elseif state.embedded or state.preparation then
        OpenFull()
    end
end
local function InstallHooks(world)
    -- Native toggles see an embedded map as already open and close it. The
    -- posthook returns it to its normal window, then opens it through Blizzard.
    InstallGlobalHook("ToggleWorldMap", function()
        if not state.togglesHooked[state.world] then OnNativeToggle() end
    end)
    InstallGlobalHook("OpenWorldMap", function()
        if not state.changing and (state.embedded or state.preparation) then OpenFull() end
    end)
    InstallGlobalHook("ShowUIPanel", function(frame)
        if frame == state.world and not state.changing and (state.embedded or state.preparation) then
            -- Do not change ownership from inside the native toggle. Its
            -- posthook must still distinguish opening from closing a full map.
            state.pendingFull = true
            QueueSync()
        end
    end)
    if not state.togglesHooked[world] and hooksecurefunc and world.HandleUserActionToggleSelf then
        state.togglesHooked[world] = true
        hooksecurefunc(world, "HandleUserActionToggleSelf", function(self)
            if self == state.world then OnNativeToggle() end
        end)
    end
    InstallGlobalHook("HideUIPanel", function()
        if state.requested and not state.changing then QueueSync() end
    end)
    if not state.worldsHooked[world] and world.HookScript then
        state.worldsHooked[world] = true
        world:HookScript("OnShow", function()
            if InCombat() then
                HoldQuestEvents(world)
                return
            end
            if state.world == world and state.requested and (state.embedded or state.preparation) then
                SuspendMovementFade(world, state.preparation ~= nil)
            end
        end)
        world:HookScript("OnHide", function()
            if state.world == world and not state.changing and state.requested then QueueSync() end
        end)
        local function GeometryChanged()
            if state.world == world and state.requested and not state.changing and state.embedded then
                state.geometryDirty = true
                QueueSync()
            end
        end
        world:HookScript("OnSizeChanged", GeometryChanged)
        if world.ScrollContainer.HookScript then
            world.ScrollContainer:HookScript("OnSizeChanged", GeometryChanged)
        end
        if hooksecurefunc then
            local function PlacementChanged()
                if state.world == world and state.requested and state.embedded and not state.changing then
                    QueueSync()
                end
            end
            -- UIPanel positioning can rewrite these anchors without changing
            -- the root's size or parent. Repair after the native operation has
            -- finished; a pending full-map handoff takes priority in Sync.
            for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetAllPoints", "SetParent", "SetScale", "SetIgnoreParentScale" }) do
                if world[method] then hooksecurefunc(world, method, PlacementChanged) end
            end
            for _, method in ipairs({ "SetPoint", "ClearAllPoints", "SetAllPoints" }) do
                if world.ScrollContainer[method] then hooksecurefunc(world.ScrollContainer, method, PlacementChanged) end
            end
        end
    end
end
local function EnsureWorld()
    if not _G.WorldMapFrame and not InCombat() then
        local load = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
        if load then load("Blizzard_WorldMap") end
    end
    local world = _G.WorldMapFrame
    if state.world and state.world ~= world then
        -- Another map addon may replace the public root. Return the old root
        -- before adopting a different frame; never apply its saved geometry to
        -- the replacement or retain a second active rendering source.
        Release(true)
        state.world, state.full, state.hostedWorld = nil, false, nil
        state.preparationFailed = false
    end
    if not Allowed(world) or not Allowed(world.ScrollContainer) then
        state.reason = "World Map unavailable"
        return nil
    end
    if not world.GetMapID or not world.SetMapID or not world.GetCanvas then
        state.reason = "World Map canvas unavailable"
        return nil
    end
    state.world = world
    InstallHooks(world)
    return world
end
local function HasPoint(frame, index, point, relative, relativePoint, x, y)
    local p, r, rp, px, py = frame:GetPoint(index)
    return p == point and r == relative and rp == relativePoint
        and math.abs((px or 0) - x) < 0.01 and math.abs((py or 0) - y) < 0.01
end
local function FillsFrame(frame, relative)
    if frame:GetNumPoints() ~= 2 then return false end
    return (HasPoint(frame, 1, "TOPLEFT", relative, "TOPLEFT", 0, 0)
            and HasPoint(frame, 2, "BOTTOMRIGHT", relative, "BOTTOMRIGHT", 0, 0))
        or (HasPoint(frame, 2, "TOPLEFT", relative, "TOPLEFT", 0, 0)
            and HasPoint(frame, 1, "BOTTOMRIGHT", relative, "BOTTOMRIGHT", 0, 0))
end
local function Fit()
    if not state.requested or not state.embedded or InCombat() then return end
    local world, host = state.world, state.viewport
    local scene = state.scene
    if not scene or scene.width <= 1 or scene.height <= 1 then return end
    local width, height = scene.width, scene.height
    local scale = math.min(host:GetWidth() / width, host:GetHeight() / height)
    if scale <= 0 then return end
    local x = (host:GetWidth() / scale - width) / 2
    local y = -(host:GetHeight() / scale - height) / 2
    local sizeChanged = math.abs(world:GetWidth() - width) >= 0.01 or math.abs(world:GetHeight() - height) >= 0.01
    local parentChanged = world:GetParent() ~= host
    local scaleChanged = math.abs(world:GetScale() - scale) >= 0.0001
    local ignoreScale = world.IsIgnoringParentScale and world:IsIgnoringParentScale()
    local anchorChanged = world:GetNumPoints() ~= 1 or not HasPoint(world, 1, "TOPLEFT", host, "TOPLEFT", x, y)
    local scrollChanged = not FillsFrame(world.ScrollContainer, world)
    -- Check the actual native anchors, not our last requested coordinates.
    -- A stable sync performs no layout writes or native canvas resize.
    if not (sizeChanged or parentChanged or scaleChanged or ignoreScale or anchorChanged or scrollChanged) then return end
    state.changing = true
    -- Preserve the normal World Map's logical scene. Native pins and unit
    -- arrows counteract canvas zoom; one OUTER transform scales those widgets,
    -- direct addon frames, text and terrain together without per-addon sizing.
    if parentChanged then
        world:SetParent(host)
        world:SetFrameStrata(host:GetFrameStrata())
        world:SetFrameLevel(host:GetFrameLevel() + 1)
    end
    if ignoreScale and world.SetIgnoreParentScale then world:SetIgnoreParentScale(false) end
    if scaleChanged then world:SetScale(scale) end
    if sizeChanged then world:SetSize(width, height) end
    if anchorChanged then
        world:ClearAllPoints()
        world:SetPoint("TOPLEFT", host, "TOPLEFT", x, y)
    end
    if scrollChanged then
        world.ScrollContainer:ClearAllPoints()
        world.ScrollContainer:SetAllPoints(world)
        state.canvasLayoutPending = true
    end
    if sizeChanged then state.canvasLayoutPending = true end
    state.changing = false
    -- Reparenting out of a hidden owner may synchronously run native OnShow
    -- layout/chrome callbacks. Recheck once after those callbacks have settled.
    if parentChanged or state.canvasLayoutPending then QueueSync() end
end
local function RefreshCanvasSize()
    if not state.canvasLayoutPending or InCombat() then return end
    local world, scroll = state.world, state.world.ScrollContainer
    if math.abs(scroll:GetWidth() - world:GetWidth()) > 0.1 or math.abs(scroll:GetHeight() - world:GetHeight()) > 0.1 then
        state.resizeProbes = (state.resizeProbes or 0) + 1
        if state.resizeProbes < MAX_GEOMETRY_PROBES then QueueSync() end
        return
    end
    state.canvasLayoutPending, state.resizeProbes = false, 0
    state.changing = true
    if world.OnFrameSizeChanged then world:OnFrameSizeChanged()
    elseif scroll.OnCanvasSizeChanged then scroll:OnCanvasSizeChanged() end
    state.changing = false
end
local function Geometry(world)
    local scroll = world.ScrollContainer
    local worldScale, scrollScale = world:GetEffectiveScale(), scroll:GetEffectiveScale()
    local left, top, sl, st = world:GetLeft(), world:GetTop(), scroll:GetLeft(), scroll:GetTop()
    if not (worldScale and scrollScale and left and top and sl and st) or worldScale <= 0 then return nil end
    local ratio = scrollScale / worldScale
    local width, height = scroll:GetWidth() * ratio, scroll:GetHeight() * ratio
    if width <= 1 or height <= 1 then return nil end
    return { width = width, height = height,
        left = sl * ratio - left, top = st * ratio - top }
end
local function Viewport(target)
    local viewport = state.viewport
    if not viewport then
        -- Create parentless first: Forever's CreateFrame hook scans map buttons
        -- when a parent is supplied. The viewport never becomes a focus stop.
        viewport = CreateFrame("Frame")
        viewport:Hide()
        if not viewport.SetClipsChildren then
            state.reason = "Map clipping unavailable"
            return nil
        end
        viewport:SetClipsChildren(true)
        viewport:SetScript("OnSizeChanged", function() Fit() end)
        state.viewport = viewport
    end
    local anchor = target.ScrollContainer or target
    -- The native battlefield ScrollFrame draws its own designated scroll child.
    -- A second framebuffer tree underneath that ScrollFrame can be occluded by
    -- its terrain. Use a separate ordinary clipped surface, anchored to the same
    -- content rectangle, above BACKGROUND terrain and below the MEDIUM HUD.
    if viewport:GetParent() ~= UIParent or state.viewportAnchor ~= anchor then
        viewport:SetParent(UIParent)
        viewport:ClearAllPoints()
        viewport:SetAllPoints(anchor)
        state.viewportAnchor = anchor
    end
    local strata = target:GetFrameStrata()
    viewport:SetFrameStrata(strata == "BACKGROUND" and "LOW" or strata)
    viewport:SetFrameLevel(target:GetFrameLevel() + 1)
    return viewport
end
OpenFull = function()
    if not state.embedded and not state.preparation then return end
    state.pendingFull = false
    if InCombat() then
        state.pendingFull = true
        state.reason = "Full map waits for combat"
        return
    end
    local world, mapID = state.world, ReadMapID(state.world)
    Release(false)
    state.full = true
    state.changing = true
    if ShowUIPanel then ShowUIPanel(world) else world:Show() end
    SetMapID(world, mapID)
    state.changing = false
    state.reason = "World Map owns surface"
end
CloseFull = function()
    state.pendingFull = false
    if InCombat() then
        state.pendingClose = true
        state.reason = "Full map close waits for combat"
        return
    end
    state.pendingClose = false
    state.changing = true
    local world = state.world
    if world and world:IsShown() then
        if HideUIPanel then HideUIPanel(world) else world:Hide() end
    end
    state.full = false
    state.changing = false
    QueueSync()
end
Sync = function()
    if state.changing then return end
    if InCombat() then state.reason = "Waiting for combat"; return end
    if state.pendingClose then CloseFull() end
    if state.pendingFull then
        state.pendingFull = false
        if state.requested then OpenFull() end
    end
    if not state.requested then
        Release(true)
        state.hostedWorld = nil
        state.reason = "inactive"
        return
    end
    local world = EnsureWorld()
    if not world then return end
    if not state.embedded and not state.preparation and world:IsShown() then
        ReleaseFallback()
        state.full = true
        state.reason = "World Map owns surface"
        return
    end
    if state.embedded then
        if not state.viewport:IsShown() or not world:IsShown() then
            if OtherPanelOpen() then state.reason = "Waiting for other panels"; return end
            state.changing = true
            state.viewport:Show()
            world:Show()
            state.changing = false
            state.geometryDirty = true
        end
        ApplyBattlefieldPresentation(world)
        HideNativeBlackout(world)
        if state.geometryDirty then
            state.geometryDirty = false
            state.geometry = Geometry(world) or state.geometry
        end
        SetMapID(world, ReadMapID(state.target))
        Fit()
        RefreshCanvasSize()
        return
    end
    state.full = false
    if state.preparationFailed then state.reason = "World Map geometry unavailable"; return end
    if OtherPanelOpen() then
        CancelPreparation(true)
        state.reason = "Waiting for other panels"
        return
    end
    local parent = world:GetParent()
    if parent and parent.IsVisible and not parent:IsVisible() then
        CancelPreparation(true)
        if not state.parentsHooked[parent] and parent.HookScript then
            state.parentsHooked[parent] = true
            parent:HookScript("OnShow", function() if state.requested then QueueSync() end end)
        end
        state.reason = "Waiting for source owner"
        return
    end
    local preparation = state.preparation
    if not preparation then
        ReleaseFallback()
        preparation = {
            world = world, alpha = world:GetAlpha(), mapID = ReadMapID(world),
            points = CopyPoints(world), probes = 0,
            renderer = SnapshotRenderer(world),
        }
        state.preparation = preparation
        state.hostedWorld = world
        state.changing = true
        SetRenderer(world, preparation.renderer, true)
        -- A never-opened minimized map may have no native root anchor yet.
        -- Seed only that empty case; its original empty anchors are restored.
        if #preparation.points == 0 and parent then
            preparation.seeded = true
            world:SetPoint("CENTER", parent, "CENTER", 0, 0)
        end
        world:SetAlpha(0)
        world:Show()
        state.changing = false
        -- Even populated rectangles can still describe the old child layout.
        -- Let native OnShow/layout callbacks finish before measuring the crop.
        if C_Timer and C_Timer.After then
            state.reason = "Preparing World Map layout"
            QueueSync()
            return
        end
    end
    if not world:IsShown() then
        CancelPreparation(true)
        state.preparationFailed = true
        state.reason = "World Map source hidden"
        ResumeFallback()
        return
    end
    -- Native layout can settle only while the original root remains shown.
    -- Probe over bounded next frames; never hide/re-show between probes.
    local geometry = Geometry(world)
    if not geometry then
        preparation.probes = preparation.probes + 1
        state.geometryRetries = preparation.probes
        if preparation.probes < MAX_GEOMETRY_PROBES and C_Timer and C_Timer.After then
            state.reason = "Preparing World Map geometry"
            QueueSync()
        else
            CancelPreparation(true)
            state.preparationFailed = true
            state.reason = "World Map geometry unavailable"
            ResumeFallback()
        end
        return
    end
    local viewport = Viewport(state.target)
    if not viewport then CancelPreparation(true); ResumeFallback(); return end
    state.saved, state.geometry = Snapshot(world), geometry
    state.saved.alpha = preparation.alpha
    -- Capture once before map-only mounting. Never derive this reference from
    -- our own already-scaled viewport on later resizes or source notifications.
    state.scene = { width = geometry.width, height = geometry.height }
    state.saved.renderer = preparation.renderer
    state.saved.mapID = preparation.mapID
    if preparation.seeded then state.saved.points = preparation.points end
    state.changing = true
    world:SetAlpha(preparation.alpha)
    state.preparation = nil
    state.geometryRetries = 0
    viewport:Show()
    world:SetParent(viewport)
    if world.SetIgnoreParentScale and state.saved.ignoreScale ~= nil then world:SetIgnoreParentScale(false) end
    world:SetFrameStrata(viewport:GetFrameStrata())
    world:SetFrameLevel(viewport:GetFrameLevel() + 1)
    state.embedded = true
    state.changing = false
    SuspendMovementFade(world, false)
    ApplyBattlefieldPresentation(world)
    HideNativeBlackout(world)
    SetMapID(world, ReadMapID(state.target))
    Fit()
    state.reason = "embedded"
end
function Surface:Activate(target)
    if not Allowed(target) then return false end
    state.requested, state.target = true, target
    state.preparationFailed = false
    if not state.targetsHooked[target] and hooksecurefunc and target.SetMapID then
        state.targetsHooked[target] = true
        hooksecurefunc(target, "SetMapID", function()
            if state.requested then QueueSync() end
        end)
    end
    self:Sync()
    return state.embedded or state.full or state.preparation ~= nil
end
function Surface:Deactivate()
    state.requested, state.pendingFull = false, false
    -- Stop descendant work immediately when legal. A protected adopted tree
    -- and restoring the native root both wait for combat to end.
    HideViewport()
    self:Sync()
end
function Surface:Sync() Sync() end
function Surface:IsEmbedded() return state.embedded end
function Surface:OwnsLayout(frame)
    -- Ownership outlives requested=false when protected release waits for
    -- combat. Normal full-map use has already returned this layout to its owner.
    return frame == state.world and (state.embedded or (state.preparation ~= nil and state.preparation.world == frame))
end
function Surface:IsActive() return state.requested and (state.embedded or state.full or state.preparation ~= nil) end
function Surface:IsRequested() return state.requested end
function Surface:GetDiagnostics()
    local world = state.world
    local blackout = world and world.BlackoutFrame
    local function FrameOwner(frame)
        return frame == state.viewport and "surface" or frame == UIParent and "UIParent"
            or frame == world and "world" or frame and "native" or "none"
    end
    local function FrameDescription(frame)
        if not frame then return "unavailable" end
        local left, bottom, width, height = frame:GetRect()
        local point, relative, relativePoint, x, y
        local points = frame:GetNumPoints()
        if points > 0 then point, relative, relativePoint, x, y = frame:GetPoint(1) end
        return "parent=" .. FrameOwner(frame:GetParent()) .. " shown=" .. tostring(frame:IsShown()) .. " visible=" .. tostring(frame:IsVisible())
            .. " rect=" .. tostring(left) .. "," .. tostring(bottom) .. "," .. tostring(width) .. "," .. tostring(height)
            .. " effectiveScale=" .. tostring(frame:GetEffectiveScale()) .. " strata=" .. tostring(frame:GetFrameStrata())
            .. " anchors=" .. tostring(points) .. " anchor=" .. tostring(point) .. ":" .. FrameOwner(relative)
            .. ":" .. tostring(relativePoint) .. ":" .. tostring(x) .. "," .. tostring(y)
    end
    return { requested = state.requested, embedded = state.embedded, full = state.full, reason = state.reason,
        mapVisible = world and world:IsVisible(), mapStrata = world and world:GetFrameStrata(),
        blackoutShown = blackout and blackout:IsShown(), blackoutStrata = blackout and blackout:GetFrameStrata(),
        root = FrameDescription(world), viewport = FrameDescription(state.viewport),
        scroll = FrameDescription(world and world.ScrollContainer),
        canvas = FrameDescription(world and world.GetCanvas and world:GetCanvas()),
        sceneWidth = state.scene and state.scene.width, sceneHeight = state.scene and state.scene.height,
        canvasScale = world and world.GetCanvasScale and world:GetCanvasScale(),
        framebuffer = world and world.IsFrameBuffer and world:IsFrameBuffer(),
    }
end
events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ADDON_LOADED", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED" }) do
    events:RegisterEvent(event)
end
if guardQuestEvents then
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    if restrictionType and restrictionState then events:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED") end
end
events:SetScript("OnEvent", function(_, event, name, status)
    local combatRestriction = event == "ADDON_RESTRICTION_STATE_CHANGED" and name == restrictionType.Combat
    if event == "PLAYER_REGEN_ENABLED" or (combatRestriction and status == restrictionState.Inactive) then
        if state.combatTransition then
            state.resumeAfterCombat, state.recheckCombatExit = true, true
            if C_Timer and C_Timer.After then C_Timer.After(0, ResumeAfterCombat) else ResumeAfterCombat() end
        else
            Sync()
        end
    elseif event == "PLAYER_REGEN_DISABLED" or (combatRestriction and status == restrictionState.Activating) then
        -- The restriction event can arrive before InCombatLockdown changes.
        -- Hold only this previously hosted map's quest event subscriptions.
        -- The scene stays visible with the original pins and addon children.
        state.combatTransition, state.resumeAfterCombat = true, false
        HoldQuestEvents(state.hostedWorld)
    elseif event == "ADDON_RESTRICTION_STATE_CHANGED" then
        return
    elseif state.questHold and state.questHold.events[event] then
        state.questHold.dirty = true
    elseif state.requested and (event ~= "ADDON_LOADED" or name == "Blizzard_WorldMap") then
        if event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then state.geometryDirty = true end
        QueueSync()
    end
end)
