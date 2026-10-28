-- Opt-in input/taint snapshots. No native hooks, input writes or idle polling.
local _, ns = ...
local Debug = {}
ns.Flux.InputDebug = Debug
local function plain(value)
    if issecretvalue and issecretvalue(value) then return "secret" end
    local kind = type(value)
    if kind == "string" or kind == "boolean" then return value end
    if kind == "number" and value == value and value > -math.huge and value < math.huge then return value end
    return nil
end
local function call(frame, method, ...)
    if not frame or type(frame[method]) ~= "function" then return nil end
    local ok, value = pcall(frame[method], frame, ...)
    if ok then return plain(value) end
end
local function name(frame)
    return call(frame, "GetName") or call(frame, "GetDebugName") or "anonymous"
end
local function security(object,keys)
    local result={}
    if issecretvalue and issecretvalue(object) then return {restricted=true} end
    if not object or not issecurevariable then return result end
    for _,key in ipairs(keys) do
        local ok,secure,owner=pcall(issecurevariable,object,key)
        if ok then result[key]={secure=plain(secure),owner=plain(owner)} end
    end
    return result
end
local function state(frame)
    if not frame then return { missing = true } end
    local result = { name = name(frame), attributes = {}, security = {} }
    for key, method in pairs({ shown = "IsShown", shownBase = "IsShownBase", visible = "IsVisible", mouse = "IsMouseEnabled",
        clicks = "IsMouseClickEnabled", motion = "IsMouseMotionEnabled", alpha = "GetAlpha",
        width = "GetWidth", height = "GetHeight", level = "GetFrameLevel", strata = "GetFrameStrata",
        editActive = "IsEditModeActive", editLocked = "IsEditModeLocked" }) do
        result[key] = call(frame, method)
    end
    if frame.GetParent then
        local ok, parent = pcall(frame.GetParent, frame)
        if ok and parent then result.parent = name(parent) end
    end
    if frame.GetScript then
        local ok, handler = pcall(frame.GetScript, frame, "OnClick")
        if ok then
            result.unitClickHandler = handler == SecureUnitButton_OnClick
            result.clickHandlerPresent = handler ~= nil
        end
    end
    if frame.IsProtected then
        local ok, protected, explicit = pcall(frame.IsProtected, frame)
        if ok then result.protected, result.explicitProtected = plain(protected), plain(explicit) end
    end
    for _, key in ipairs({ "unit", "type", "type1", "*type1", "type2", "*type2", "useOnKeyDown", "unit1", "*unit1", "helpbutton1", "*helpbutton1", "downbutton1" }) do
        result.attributes[key] = call(frame, "GetAttribute", key)
    end
    if issecurevariable then
        for _, key in ipairs({ "OnEditModeEnter", "OnEditModeExit", "Show", "Hide", "SetPoint", "SetScale",
            "HighlightSystem", "ClearHighlight", "isSelected", "isHighlighted", "systemInfo", "editModeForceShow" }) do
            local ok, secure, owner = pcall(issecurevariable, frame, key)
            if ok then result.security[key] = { secure = plain(secure), owner = plain(owner) } end
        end
    end
    local clicks = frame.GetRegisteredClicks and { pcall(frame.GetRegisteredClicks, frame) }
    if clicks and clicks[1] then
        result.registeredClicks = {}
        for i = 2, #clicks do result.registeredClicks[#result.registeredClicks + 1] = plain(clicks[i]) end
    end
    return result
end
local names = { "FluxUnitFrame_player", "FluxUnitFrameOuter_player", "PlayerFrame", "TargetFrame", "FocusFrame",
    "FluxPlayerPortraitTransmogClick", "FluxPlayerPortraitHoverCatcher", "FluxPortraitOutfitCombatHider",
    "StanceBar", "PetActionBar", "PossessActionBar", "CompactPartyFrame", "PartyFrame", "GameMenuFrame", "EditModeManagerFrame" }
local gridNames={"MainActionBar","MultiBarBottomLeft","MultiBarBottomRight","MultiBarLeft","MultiBarRight","MultiBar5","MultiBar6","MultiBar7"}
local gridFields={"SetShown","SetShowGrid","GetShowGrid","HasAction","UpdateVisibility","UpdateShownButtons",
    "actionButtons","shownButtonContainers","numButtonsShowable","showAllButtons","noSpacers","index","showgrid","bar","container"}
local function captureGrids(snapshot)
    snapshot.nativeGrids={}
    for _,key in ipairs(gridNames) do
        local bar=_G[key]
        local record={frame=state(bar),security=security(bar,gridFields),buttons={}}
        snapshot.nativeGrids[key]=record
        local buttons=bar and bar.actionButtons
        if type(buttons)=="table" and not (issecretvalue and issecretvalue(buttons)) then
            for i=1,12 do
                local button=buttons[i]
                if button and not (issecretvalue and issecretvalue(button)) then
                    record.buttons[i]={name=name(button),security=security(button,gridFields),
                        entry=security(buttons,{i}),container=security(button.container,{"SetShown","Show","Hide"}),
                        statehidden=call(button,"GetAttribute","statehidden")}
                end
            end
        end
    end
    snapshot.gridGlobals=security(_G,{"MultiActionBar_ShowAllGrids","MultiActionBar_HideAllGrids","GetMultiActionBars","PlayerSpellsFrame"})
    snapshot.spellbookMixins={
        frame=security(_G.SpellBookFrameMixin,{"OnShow","UpdateSpells","ShouldDisplaySpellBookItem"}),
        item=security(_G.SpellBookItemMixin,{"UpdateVisuals","UpdateSubName","OnIconClick"})}
end
function Debug.Capture(includeGrids)
    local snapshot = { schema = 2, time = date and date("%Y-%m-%d %H:%M:%S"), frames = {}, foci = {},
        combat = InCombatLockdown and InCombatLockdown(), editBusy = FluxEditModeBusy and FluxEditModeBusy(),
        helpers = { api = type(FLUX_API), events = type(FluxSafeRegisterUnitEvent), atlas = type(FluxHasAtlas),
            microSize = type(FluxGetStandardMicroButtonSize) } }
    -- Retain partial evidence if a newly restricted native read fails later.
    FluxPerfCaptureDB = FluxPerfCaptureDB or {}
    FluxPerfCaptureDB.inputDebug = snapshot
    local getCVar = C_CVar and C_CVar.GetCVar or GetCVar
    if getCVar then
        local ok, value = pcall(getCVar, "taintLog")
        if ok then snapshot.taintLog = plain(value) end
    end
    if C_ClickBindings and C_ClickBindings.GetBindingType then
        snapshot.clickBindings = {}
        local mods = MakeModifiers and MakeModifiers() or 0
        for _, button in ipairs({ "LeftButton", "RightButton", "MiddleButton" }) do
            local ok, kind = pcall(C_ClickBindings.GetBindingType, button, mods)
            local row = { bindingType = ok and plain(kind) or "error" }
            if C_ClickBindings.GetEffectiveInteractionButton then
                local good, effective = pcall(C_ClickBindings.GetEffectiveInteractionButton, button, mods)
                if good then row.effective = plain(effective) end
            end
            snapshot.clickBindings[button] = row
        end
    end
    for _, key in ipairs(names) do
        local frame = _G[key]
        snapshot.frames[key] = state(frame)
        if frame and frame.Selection then snapshot.frames[key .. ".Selection"] = state(frame.Selection) end
    end
    local player = _G.PlayerFrame
    for _, key in ipairs({ "PlayerFrameContainer", "PlayerFrameContent" }) do
        snapshot.frames["PlayerFrame." .. key] = state(player and player[key])
    end
    local manager = _G.EditModeManagerFrame
    snapshot.frames.AccountSettings = state(manager and manager.AccountSettings)
    local account = manager and manager.AccountSettings
    local savedBars = account and account.oldActionBarSettings
    if savedBars and issecurevariable then
        snapshot.accountBarState = {}
        for _, key in ipairs({ "StanceBar", "PetActionBar", "PossessActionBar" }) do
            local bar = _G[key]
            local saved = bar and savedBars[bar]
            if saved then
                local ok, secure, owner = pcall(issecurevariable, saved, "isShown")
                if ok then snapshot.accountBarState[key] = { secure = plain(secure), owner = plain(owner), shown = plain(saved.isShown) } end
            end
        end
    end
    local foci = {}
    if GetMouseFoci then
        local ok, value = pcall(GetMouseFoci)
        if ok and type(value) == "table" then foci = value end
    elseif GetMouseFocus then
        local ok, value = pcall(GetMouseFocus)
        if ok and value then foci[1] = value end
    end
    for i = 1, math.min(#foci, 12) do
        local ancestry, frame = {}, foci[i]
        for _ = 1, 8 do
            if not frame then break end
            ancestry[#ancestry + 1] = state(frame)
            local ok, parent = false, nil
            if frame.GetParent then ok, parent = pcall(frame.GetParent, frame) end
            frame = ok and parent or nil
        end
        snapshot.foci[#snapshot.foci + 1] = ancestry
    end
    if includeGrids then captureGrids(snapshot) end
    snapshot.complete = true
    return snapshot
end
local pending = false
SLASH_FLUXINPUT1 = "/fluxinput"
SlashCmdList.FLUXINPUT = function(message)
    if pending then return end
    local grids=type(message)=="string" and message:lower():match("^%s*grid%s*$")~=nil
    local notice = grids and "Flux grid capture: reproduce the spellbook error now; /reload afterward to save."
        or "Flux input v2: hover the player frame for 3 seconds, then /reload to save the snapshot."
    if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(notice, 1, 1, 1) end
    local before=Debug.Capture(grids)
    if C_Timer and C_Timer.After then
        pending = true
        C_Timer.After(3, function()
            pending = false
            local snapshot = Debug.Capture(grids)
            if grids then snapshot.gridsBefore=before.nativeGrids end
            if UIErrorsFrame and UIErrorsFrame.AddMessage then
                UIErrorsFrame:AddMessage("Flux input captured " .. (snapshot.time or "now") .. ". /reload to save.", 1, 1, 1)
            end
        end)
    end
end
