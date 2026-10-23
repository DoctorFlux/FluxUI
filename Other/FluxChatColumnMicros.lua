-- Chat-column copies of the Bags and Character micro buttons.
-- Names do not end in MicroButton, so the micro menu discovery scan leaves them alone.
-- The character button is a secure /click of CharacterMicroButton. Calling
-- ToggleCharacter from addon code taints CharacterFrame:OnShow on Forever.

local _, ns = ...
local issecretvalue = issecretvalue

FluxChatColumnMicros = FluxChatColumnMicros or {}

local function AtlasOK(name)
    if not name or name == "" then
        return false
    end
    if C_Texture and C_Texture.GetAtlasInfo then
        return C_Texture.GetAtlasInfo(name) ~= nil
    end
    if GetAtlasInfo then
        return GetAtlasInfo(name) ~= nil
    end
    return false
end

local function MicroSize()
    local w, h = 29, 37
    if FluxGetStandardMicroButtonSize then
        w, h = FluxGetStandardMicroButtonSize()
    end
    local scale = 1
    if FluxMicroMenu and FluxMicroMenu.GetButtonSizeScale then
        scale = FluxMicroMenu:GetButtonSizeScale() or 1
    end
    if type(w) ~= "number" or (issecretvalue and issecretvalue(w)) then
        w = 29
    end
    if type(h) ~= "number" or (issecretvalue and issecretvalue(h)) then
        h = 37
    end
    if type(scale) ~= "number" or (issecretvalue and issecretvalue(scale)) or scale <= 0 then
        scale = 1
    end
    return w * scale, h * scale
end

local function UseDfShell()
    -- Anniversary/classic ship the HUD atlas but their micromenu is the 29x37 shell.
    if FluxShouldApplyMicroButtonTopGapLayout then
        return FluxShouldApplyMicroButtonTopGapLayout() == true
    end
    return false
end

--- Era, anniversary, and the other classic projects. Checked before any camelot
--- flag: a leaked TOC flag must not turn these clients into the Forever path.
local function IsClassicProject()
    if WOW_PROJECT_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        return true
    end
    if WOW_PROJECT_BURNING_CRUSADE_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        return true
    end
    if WOW_PROJECT_WRATH_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
        return true
    end
    if WOW_PROJECT_CATACLYSM_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC then
        return true
    end
    if WOW_PROJECT_MISTS_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC then
        return true
    end
    return false
end

--- Forever is WOW_PROJECT_CAMELOT, not mainline. It still has secret unit values.
local function IsCamelotClient()
    if IsClassicProject() then
        return false
    end
    if ns._isCamelotGameType == true then
        return true
    end
    if WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
        return true
    end
    local client = (ns.Flux and ns.Flux.Client) or (Flux and Flux.Client)
    if client and (client.isCamelot or client.isForever) then
        return true
    end
    return false
end

--- Era and anniversary CharacterMicroButton has OnMouseDown/OnMouseUp and no OnClick.
--- Click() and a secure clickbutton never run ToggleCharacter there.
local function IsClassicFamilyClient()
    if IsClassicProject() then
        return true
    end
    if IsCamelotClient() then
        return false
    end
    local client = (ns.Flux and ns.Flux.Client) or (Flux and Flux.Client)
    if client and (client.isAnyClassic or client.isEra or client.isAnniversary or client.isClassic or client.isTBC or client.isWrath or client.isCata or client.isMists) then
        return true
    end
    if WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
        return true
    end
    return false
end

local function DurabilityTextColor(pct)
    if pct >= 75 then
        local u = (pct - 75) / 25
        return 0.15 + (1 - u) * 0.85, 0.85, 0.15
    elseif pct >= 50 then
        local u = (pct - 50) / 25
        return 1, 0.55 + u * 0.3, 0.05
    elseif pct >= 25 then
        local u = (pct - 25) / 25
        return 1, 0.25 + u * 0.3, 0.05
    end
    local u = pct / 25
    return 1, 0.08 + u * 0.17, 0.08
end

--- Full-size micromenu shell. withPress is false for the secure character button:
--- OnMouseDown from addon code taints that click, so Character Info never opens.
local function DressMicroShell(btn, withPress)
    local w, h = MicroSize()
    btn:SetSize(w, h)
    if UseDfShell() then
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAtlas("UI-HUD-MicroMenu-ButtonBG-Up", true)
        btn:SetNormalTexture(bg)
        local pushedBg = btn:CreateTexture(nil, "BACKGROUND")
        pushedBg:SetAtlas("UI-HUD-MicroMenu-ButtonBG-Down", true)
        btn:SetPushedTexture(pushedBg)
        -- OVERLAY sits above the normal/pushed shell. ARTWORK was hidden by SetNormalTexture.
        local icon = btn:CreateTexture(nil, "OVERLAY", nil, 1)
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -7)
        icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -7, 7)
        btn.icon = icon
        if icon.AddMaskTexture and btn.CreateMaskTexture and AtlasOK("UI-HUD-MicroMenu-Portrait-Mask") then
            local mask = btn:CreateMaskTexture()
            mask:SetAtlas("UI-HUD-MicroMenu-Portrait-Mask", false)
            mask:SetPoint("CENTER", btn, "CENTER", 0, 0)
            mask:SetSize(35 * (w / 32), 65 * (h / 40))
            icon:AddMaskTexture(mask)
            btn._fluxPortraitMask = mask
        end
        if AtlasOK("UI-HUD-MicroMenu-Portrait-Down") then
            local shadow = btn:CreateTexture(nil, "OVERLAY", nil, 2)
            shadow:SetAtlas("UI-HUD-MicroMenu-Portrait-Down", true)
            shadow:SetPoint("CENTER", btn, "CENTER", 1, -4)
            shadow:Hide()
            btn._fluxPushedShadow = shadow
        end
        if FluxApplyCustomMicroMouseover then
            FluxApplyCustomMicroMouseover(btn, "df")
        end
        btn._fluxBg = bg
        btn._fluxPushedBg = pushedBg
        -- Not a button-state texture. The state machine hides the pushed
        -- texture whenever this button is not the one under the cursor.
        local latch = btn:CreateTexture(nil, "BACKGROUND", nil, 2)
        latch:SetAtlas("UI-HUD-MicroMenu-ButtonBG-Down", false)
        latch:SetAllPoints(btn)
        latch:SetAlpha(0)
        btn._fluxDownLatch = latch
        if withPress ~= false then
            btn:SetScript("OnMouseDown", function()
                icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 8, -8)
                icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6, 6)
            end)
            btn:SetScript("OnMouseUp", function()
                icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -7)
                icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -7, 7)
            end)
        end
        return
    end
    local texCoords = { 0, 1, 0.359375, 1 }
    btn:SetNormalTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Up")
    btn:SetPushedTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Down")
    if FluxApplyCustomMicroMouseover then
        FluxApplyCustomMicroMouseover(btn, "classic")
    else
        btn:SetHighlightTexture("Interface\\Buttons\\UI-MicroButton-Hilight", "ADD")
        local highlight = btn:GetHighlightTexture()
        if highlight then
            highlight:SetBlendMode("ADD")
            highlight:SetTexCoord(unpack(texCoords))
        end
    end
    local normal = btn:GetNormalTexture()
    if normal then
        normal:SetTexCoord(unpack(texCoords))
    end
    local pushed = btn:GetPushedTexture()
    if pushed then
        pushed:SetTexCoord(unpack(texCoords))
    end
    local icon = btn:CreateTexture(nil, "OVERLAY")
    icon:SetSize(18 * (w / 29), 25 * (h / 37))
    icon:SetPoint("CENTER", btn, "CENTER", 0, -1)
    btn.icon = icon
    if withPress ~= false then
        btn:SetScript("OnMouseDown", function()
            icon:SetPoint("CENTER", btn, "CENTER", 0, -2)
        end)
        btn:SetScript("OnMouseUp", function()
            icon:SetPoint("CENTER", btn, "CENTER", 0, -1)
        end)
    end
end

local function AddUnderLabel(btn)
    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject("NumberFontNormal")
    local font, size, flags = fs:GetFont()
    if font and size and size > 2 then
        local sr, sg, sb, sa = fs:GetShadowColor()
        local sx, sy = fs:GetShadowOffset()
        fs:SetFont(font, size - 2, flags)
        fs:SetShadowColor(sr or 0, sg or 0, sb or 0, sa or 1)
        fs:SetShadowOffset(sx or 0, sy or 0)
    end
    fs:SetPoint("TOP", btn, "BOTTOM", 5, 2)
    fs:SetTextColor(1, 1, 1, 1)
    btn._fluxCount = fs
    return fs
end

local function ClientFlags()
    return (ns.Flux and ns.Flux.Client) or (Flux and Flux.Client)
end

--- GearScore exists on Era, TBC/Anniversary, and Wrath. Later clients use item level only.
local function UsesGearScore()
    local client = ClientFlags()
    if not client then
        return false
    end
    return client.isEra or client.isAnniversary or client.isTBC or client.isWrath
end

local function SafeNumber(value)
    if type(value) ~= "number" or (issecretvalue and issecretvalue(value)) then
        return nil
    end
    return value
end

local function PlayerItemLevel()
    if type(_G.FluxCSC_GetPlayerItemLevel) == "function" then
        local value = SafeNumber(_G.FluxCSC_GetPlayerItemLevel())
        if value and value > 0 then
            return value
        end
    end
    if type(GetAverageItemLevel) == "function" then
        local ok, overall, equipped = pcall(GetAverageItemLevel)
        if ok then
            equipped = SafeNumber(equipped)
            overall = SafeNumber(overall)
            if equipped and equipped > 0 then
                return equipped
            end
            if overall and overall > 0 then
                return overall
            end
        end
    end
    return nil
end

local function PlayerGearScore()
    if not UsesGearScore() or type(_G.FluxCSC_GetPlayerGearScore) ~= "function" then
        return nil
    end
    local value = SafeNumber(_G.FluxCSC_GetPlayerGearScore())
    if value and value > 0 then
        return value
    end
    return nil
end

local function AddEquipmentTooltipLines()
    local ilvl = PlayerItemLevel()
    local gs = PlayerGearScore()
    if not ilvl and not gs then
        return
    end
    local r, g, b = 1, 1, 1
    if gs and type(_G.FluxCSC_GetGearScoreQualityRGB) == "function" then
        local qr, qg, qb = _G.FluxCSC_GetGearScoreQualityRGB(gs)
        if SafeNumber(qr) and SafeNumber(qg) and SafeNumber(qb) then
            r, g, b = qr, qg, qb
        end
    end
    GameTooltip:AddLine(" ")
    if ilvl then
        GameTooltip:AddDoubleLine(_G.CSC_ILVL_LABEL or "Item LvL", string.format("%.1f", ilvl), 1, 0.82, 0, r, g, b)
    end
    if gs then
        GameTooltip:AddDoubleLine(_G.CSC_GS_LABEL or "GearScore", tostring(math.floor(gs)), 1, 0.82, 0, r, g, b)
    end
end

local function IsForeverClient()
    return IsCamelotClient()
end

local function LoadCharacterUI()
    local loadAddOn = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
    if loadAddOn then
        pcall(loadAddOn, "Blizzard_CharacterFrame")
    end
end

--- CharacterFrame:OnShow turns on player/pet status text and compares secret
--- health there, which throws when addon code opened the panel. The XML script
--- keeps the original function, so replacing only CharacterFrameMixin.OnShow
--- never runs. Wrap the script Show() actually calls, and swallow only the
--- secret compare so the panel still finishes opening. Not on Forever: see
--- InstallCharacterShowGuard.
local characterShowWrapper

local function IsSecretErr(err)
    return type(err) == "string" and string.find(err, "secret", 1, true) ~= nil
end

local function AddStatusBar(list, seen, bar)
    if bar and not seen[bar] then
        seen[bar] = true
        list[#list + 1] = bar
    end
end

local function CollectCharacterStatusBars(list, seen)
    if type(PlayerFrame_GetHealthBar) == "function" then
        AddStatusBar(list, seen, PlayerFrame_GetHealthBar())
    end
    if type(PlayerFrame_GetManaBar) == "function" then
        AddStatusBar(list, seen, PlayerFrame_GetManaBar())
    end
    if type(PlayerFrame_GetAlternatePowerBar) == "function" then
        AddStatusBar(list, seen, PlayerFrame_GetAlternatePowerBar())
    end
    AddStatusBar(list, seen, _G.PlayerFrameHealthBar)
    AddStatusBar(list, seen, _G.PlayerFrameManaBar)
    AddStatusBar(list, seen, _G.PlayerFrameAlternateManaBar)
    AddStatusBar(list, seen, _G.PetFrameHealthBar)
    AddStatusBar(list, seen, _G.PetFrameManaBar)
    AddStatusBar(list, seen, _G.MonkStaggerBar)
end

local function CallSecretSafe(fn, selfBar, ...)
    local ok, err = pcall(fn, selfBar, ...)
    if not ok and not IsSecretErr(err) then
        error(err, 0)
    end
end

local function SecretNumber(...)
    if not issecretvalue then
        return false
    end
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil and issecretvalue(value) then
            return true
        end
    end
    return false
end

local function BarValuesAreSecret(bar)
    if not bar then
        return false
    end
    if bar.GetValue and SecretNumber(bar:GetValue()) then
        return true
    end
    if bar.GetMinMaxValues then
        local minValue, maxValue = bar:GetMinMaxValues()
        if SecretNumber(minValue, maxValue) then
            return true
        end
    end
    return false
end

local secretGuardSaved
local secretGuardRestoreQueued = false

local function RestoreSecretStatusGuard()
    local saved = secretGuardSaved
    if not saved then
        return
    end
    secretGuardSaved = nil
    for i = #saved, 1, -1 do
        local entry = saved[i]
        if entry[1][entry[2]] == entry[4] then
            entry[1][entry[2]] = entry[3]
        end
    end
end

local function QueueSecretGuardRestore()
    if not (C_Timer and C_Timer.After) then
        RestoreSecretStatusGuard()
        return
    end
    if secretGuardRestoreQueued then
        return
    end
    secretGuardRestoreQueued = true
    C_Timer.After(0, function()
        secretGuardRestoreQueued = false
        RestoreSecretStatusGuard()
    end)
end

local function GuardSecretMethod(saved, obj, key, makeWrapper)
    if not obj or type(obj[key]) ~= "function" then
        return
    end
    local orig = obj[key]
    local wrapped = makeWrapper(orig)
    saved[#saved + 1] = { obj, key, orig, wrapped }
    obj[key] = wrapped
end

local function BeginSecretStatusGuard()
    if secretGuardSaved or not issecretvalue then
        return secretGuardSaved ~= nil
    end
    local saved = {}
    secretGuardSaved = saved
    local function guardValues(orig)
        return function(self, textString, value, valueMin, valueMax, ...)
            if SecretNumber(value, valueMin, valueMax) or BarValuesAreSecret(self) then
                return
            end
            return orig(self, textString, value, valueMin, valueMax, ...)
        end
    end
    local function guardBarCall(orig)
        return function(self, ...)
            CallSecretSafe(orig, self, ...)
        end
    end
    local function guardHealthValue(orig)
        return function(self, value, ...)
            if SecretNumber(value) or BarValuesAreSecret(self) then
                return
            end
            return orig(self, value, ...)
        end
    end
    -- Live and forever both compare UnitGetTotalHealAbsorbs inside
    -- UnitFrameHealPredictionBars_Update (health < myCurrentHealAbsorb).
    -- That API is SecretReturns. The compare is legal only on an untainted
    -- stack. This guard is tainted, and health GetValue can be a plain number
    -- while the absorb return is still secret, so forwarding to orig throws.
    -- Skip for this window. RestoreSecretStatusGuard puts the real function
    -- back and Blizzard's own OnUpdate/events run it cleanly.
    local function guardHealPredict(_orig)
        return function()
        end
    end
    local mixin = _G.TextStatusBarMixin
    GuardSecretMethod(saved, mixin, "UpdateTextStringWithValues", guardValues)
    GuardSecretMethod(saved, mixin, "ShowStatusBarText", guardBarCall)
    GuardSecretMethod(saved, mixin, "HideStatusBarText", guardBarCall)
    GuardSecretMethod(saved, mixin, "UpdateTextString", guardBarCall)
    local list, seen = {}, {}
    CollectCharacterStatusBars(list, seen)
    local function walk(frame, depth)
        if not frame or depth > 5 or seen[frame] then
            return
        end
        seen[frame] = true
        if type(frame.ShowStatusBarText) == "function" or type(frame.UpdateTextStringWithValues) == "function" then
            list[#list + 1] = frame
        end
        if not frame.GetChildren then
            return
        end
        local ok, children = pcall(function()
            return { frame:GetChildren() }
        end)
        if not ok then
            return
        end
        for i = 1, #children do
            walk(children[i], depth + 1)
        end
    end
    walk(_G.PlayerFrame, 0)
    walk(_G.PetFrame, 0)
    for i = 1, #list do
        local bar = list[i]
        GuardSecretMethod(saved, bar, "UpdateTextStringWithValues", guardValues)
        GuardSecretMethod(saved, bar, "ShowStatusBarText", guardBarCall)
        GuardSecretMethod(saved, bar, "HideStatusBarText", guardBarCall)
        GuardSecretMethod(saved, bar, "UpdateTextString", guardBarCall)
    end
    GuardSecretMethod(saved, _G, "HealthBar_OnValueChanged", guardHealthValue)
    GuardSecretMethod(saved, _G, "UnitFrameHealthBar_OnValueChanged", guardHealthValue)
    GuardSecretMethod(saved, _G, "UnitFrameHealPredictionBars_Update", guardHealPredict)
    return true
end

local function RunShowGuarded(body, self, ...)
    local guarding = BeginSecretStatusGuard()
    local ok, err = pcall(body, self, ...)
    if guarding then
        QueueSecretGuardRestore()
    end
    if not ok and not IsSecretErr(err) then
        error(err, 0)
    end
end

local function BindCharacterHandler(frame, scriptName, bodyField, wrapper)
    if not frame or not frame.GetScript or not frame.SetScript then
        return wrapper
    end
    if wrapper and frame:GetScript(scriptName) == wrapper then
        return wrapper
    end
    local body = frame[bodyField]
    if type(body) ~= "function" then
        body = frame:GetScript(scriptName)
        if type(body) ~= "function" then
            body = frame[scriptName]
        end
        if type(body) ~= "function" and _G.CharacterFrameMixin then
            body = _G.CharacterFrameMixin[scriptName]
        end
        if type(body) == "function" and body ~= wrapper then
            frame[bodyField] = body
        end
    end
    body = frame[bodyField]
    if type(body) ~= "function" then
        return wrapper
    end
    if not wrapper then
        wrapper = function(self, ...)
            RunShowGuarded(self[bodyField] or body, self, ...)
        end
    end
    pcall(frame.SetScript, frame, scriptName, wrapper)
    if frame[scriptName] == body then
        frame[scriptName] = wrapper
    end
    local mixin = _G.CharacterFrameMixin
    if mixin and mixin[scriptName] == body then
        mixin[scriptName] = wrapper
    end
    return wrapper
end

local characterHideWrapper

local function InstallCharacterShowGuard()
    -- Forever's gamepad CharacterFrame activates binding groups in OnShow and
    -- hides the gamepad bag in OnHide. A Flux script or ToggleCharacter there
    -- taints the protected SetPreferredGamepadInteractTarget(). FluxUI opens it
    -- only through secure clicks on Forever, so the secret compare runs clean.
    if IsCamelotClient() then
        return
    end
    local frame = _G.CharacterFrame
    characterShowWrapper = BindCharacterHandler(frame, "OnShow", "_fluxShowBody", characterShowWrapper)
    characterHideWrapper = BindCharacterHandler(frame, "OnHide", "_fluxHideBody", characterHideWrapper)
    if type(ToggleCharacter) == "function" and ToggleCharacter ~= _G.FluxToggleCharacterHook then
        local openCharacter = ToggleCharacter
        local hook
        hook = function(...)
            InstallCharacterShowGuard()
            return openCharacter(...)
        end
        _G.FluxToggleCharacterHook = hook
        ToggleCharacter = hook
    end
    local globalShow = _G.CharacterFrame_OnShow
    if type(globalShow) == "function" and not _G.FluxCharacterFrame_OnShowGuarded then
        _G.FluxCharacterFrame_OnShowGuarded = true
        _G.CharacterFrame_OnShow = function(self, ...)
            RunShowGuarded(globalShow, self, ...)
        end
    end
    local globalHide = _G.CharacterFrame_OnHide
    if type(globalHide) == "function" and not _G.FluxCharacterFrame_OnHideGuarded then
        _G.FluxCharacterFrame_OnHideGuarded = true
        _G.CharacterFrame_OnHide = function(self, ...)
            RunShowGuarded(globalHide, self, ...)
        end
    end
end

local characterStatusTextGuard = CreateFrame("Frame")
characterStatusTextGuard:RegisterEvent("ADDON_LOADED")
characterStatusTextGuard:RegisterEvent("PLAYER_LOGIN")
characterStatusTextGuard:RegisterEvent("PLAYER_ENTERING_WORLD")
characterStatusTextGuard:SetScript("OnEvent", function()
    InstallCharacterShowGuard()
end)
InstallCharacterShowGuard()

--- Do not run CharacterMicroButton's mouse scripts. OnMouseDown calls
--- CharacterMicroButton_SetPushed, which touches the global MicroButtonPortrait
--- and can error before ToggleCharacter. Call the toggle directly.
local function OpenCharacterPanel()
    LoadCharacterUI()
    InstallCharacterShowGuard()
    local frame = _G.CharacterFrame
    if frame and frame.IsShown and frame:IsShown() then
        if HideUIPanel then
            HideUIPanel(frame)
        elseif frame.Hide then
            frame:Hide()
        end
        return
    end
    if ToggleCharacter then
        ToggleCharacter("PaperDollFrame")
        return
    end
    frame = _G.CharacterFrame
    if not frame then
        return
    end
    if ShowUIPanel then
        ShowUIPanel(frame)
    elseif frame.Show then
        frame:Show()
    end
end

local function CombatBlocked()
    if not InCombatLockdown() then
        return false
    end
    if UIErrorsFrame and ERR_NOT_IN_COMBAT then
        UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1, 0.3, 0.3, 1)
    end
    return true
end

local function ShowBagTooltip(self)
    if not GameTooltip then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Backpack")
    if GetBindingKey then
        local key = GetBindingKey("OPENALLBAGS")
        if key then
            GameTooltip:AddLine("Key: " .. key, 1, 1, 1)
        end
    end
    local src = _G.FluxBagMicroButton
    if src and src.FluxFillTooltip then
        src.FluxFillTooltip(GameTooltip)
    end
    GameTooltip:Show()
end

local function HasTransmogOutfits()
    local api = ns.API
    if not api or not api.HasPlayerTransmogOutfitAPI or api.HasPlayerTransmogOutfitAPI() ~= true then
        return false
    end
    local entries = api.GetPlayerTransmogOutfitEntries and api.GetPlayerTransmogOutfitEntries()
    if type(entries) ~= "table" then
        return false
    end
    for _, entry in ipairs(entries) do
        if entry and not entry.isDisabled and type(entry.index) == "number" then
            return true
        end
    end
    return false
end

local function ShowCharacterTooltip(self)
    if not GameTooltip then
        return
    end
    local src = _G.CharacterMicroButton
    local title
    if src and src.tooltipText then
        title = src.tooltipText
    elseif MicroButtonTooltipText and CHARACTER_BUTTON then
        title = MicroButtonTooltipText(CHARACTER_BUTTON, "TOGGLECHARACTER0")
    else
        title = CHARACTER_BUTTON or "Character Info"
    end
    -- GameTooltip_AddNewbieTip uses the default anchor when newbie tips are on,
    -- so the tip leaves the button. Always anchor to this button.
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    if GameTooltip_SetTitle then
        GameTooltip_SetTitle(GameTooltip, title)
    else
        GameTooltip:SetText(title, 1, 1, 1)
    end
    local newbie = (src and src.newbieText) or NEWBIE_TOOLTIP_CHARACTER
    if newbie and GetCVar and GetCVar("showNewbieTips") == "1" then
        if GameTooltip_AddNormalLine then
            GameTooltip_AddNormalLine(GameTooltip, newbie, true)
        else
            GameTooltip:AddLine(newbie, 1, 0.82, 0, true)
        end
    end
    if src and src.IsEnabled and not src:IsEnabled() then
        if src.factionGroup == "Neutral" and FEATURE_NOT_AVAILBLE_PANDAREN and RED_FONT_COLOR then
            GameTooltip:AddLine(FEATURE_NOT_AVAILBLE_PANDAREN, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
        elseif src.minLevel and FEATURE_BECOMES_AVAILABLE_AT_LEVEL and RED_FONT_COLOR then
            GameTooltip:AddLine(format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, src.minLevel), RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
        elseif src.disabledTooltip then
            local text = src.disabledTooltip
            if type(text) == "function" then
                text = text(src)
            end
            if text and RED_FONT_COLOR then
                GameTooltip:AddLine(text, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
            end
        end
    end
    AddEquipmentTooltipLines()
    if _SetDurabilityRepairTooltip then
        _SetDurabilityRepairTooltip(self, true, true)
    else
        GameTooltip:Show()
    end
    if HasTransmogOutfits() and GameTooltip then
        GameTooltip:AddLine("Right-click: Transmog outfits", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end
end

local function ForeverGamepadUI()
    return _G.FluxUI_IsForeverGamepadUI and _G.FluxUI_IsForeverGamepadUI() or false
end

local function HideTooltip()
    if GameTooltip then
        GameTooltip:Hide()
    end
end

local function ToggleChatCharacterOutfitFlyout(btn)
    local ptc = ns.PlayerTransmogClick
    if ptc and ptc.ToggleOutfitFlyout then
        ptc.ToggleOutfitFlyout(btn, "RIGHT")
    end
    HideTooltip()
end

local function CreateBagButton(parent)
    local btn = CreateFrame("Button", "FluxCCPChatBagButton", parent)
    DressMicroShell(btn)
    btn:RegisterForClicks("AnyUp")
    if btn.icon then
        btn.icon:SetTexture("Interface\\ICONS\\INV_Misc_Bag_08")
        btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    local count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    count:SetJustifyH("RIGHT")
    btn:SetScript("OnClick", function(self, button)
        -- Forever's gamepad bag opens only through the secure click proxy.
        if ForeverGamepadUI() then
            return
        end
        local src = _G.FluxBagMicroButton
        if button == "RightButton" and src and src.FluxToggleBagSlots then
            src.FluxToggleBagSlots(self, true)
            return
        end
        if src and src.Click then
            src:Click(button)
            return
        end
        if button == "RightButton" then
            return
        end
        if ToggleAllBags then
            ToggleAllBags()
        elseif OpenAllBags then
            OpenAllBags()
        elseif ToggleBackpack then
            ToggleBackpack()
        end
    end)
    btn:HookScript("OnEnter", ShowBagTooltip)
    btn:HookScript("OnLeave", HideTooltip)
    local proxy = ns.Flux and ns.Flux.SecureClickProxy
    if proxy and IsCamelotClient() then
        proxy.Attach(btn, {
            target = function()
                return _G.MainMenuBarBackpackButton
            end,
            enabled = ForeverGamepadUI,
            onEnter = ShowBagTooltip,
            onLeave = HideTooltip,
        })
    end
    local function SyncCount()
        local src = _G.FluxBagMicroButton
        local text = src and src.count and src.count.GetText and src.count:GetText()
        if issecretvalue and text and issecretvalue(text) then
            return
        end
        count:SetText(text or "")
        if src and src.count and src.count.GetTextColor then
            local r, g, b = src.count:GetTextColor()
            if r and not (issecretvalue and issecretvalue(r)) then
                count:SetTextColor(r, g, b)
            end
        end
    end
    -- C_Timer.After has no cancellation handle. Keep one pending callback,
    -- refresh at most 0.2s apart during a burst, then reconcile 0.2s after its
    -- last event so the source counter's own delayed update is included.
    local bagCountDue
    local bagCountPending = false
    local function FlushBagCount()
        bagCountPending = false
        SyncCount()
        local remaining = bagCountDue - GetTime()
        if remaining > 0 then
            bagCountPending = true
            C_Timer.After(math.min(0.2, remaining), FlushBagCount)
        end
    end
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("BAG_UPDATE")
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:SetScript("OnEvent", function()
        if C_Timer and C_Timer.After and GetTime then
            bagCountDue = GetTime() + 0.2
            if not bagCountPending then
                bagCountPending = true
                C_Timer.After(0.2, FlushBagCount)
            end
        else
            SyncCount()
        end
    end)
    SyncCount()
    return btn
end

local function ApplyPortrait(btn)
    -- A portrait refresh can restore resting crop/layout while the panel is open.
    btn._fluxPlatePushed = nil
    if btn.icon and SetPortraitTexture then
        SetPortraitTexture(btn.icon, "player")
        btn.icon:SetTexCoord(0.2, 0.8, 0.0666, 0.9)
    end
    if FluxApplyCharacterPortraitMouseover then
        FluxApplyCharacterPortraitMouseover(btn, btn.icon)
    end
end

local function CharacterPanelShown()
    local frame = _G.CharacterFrame
    if frame and frame.IsShown and frame:IsShown() then
        return true
    end
    local hack = _G.WoWHackCharacterUI
    return hack and hack.IsShown and hack:IsShown() or false
end

local function LayoutCharacterFace(btn, pushed)
    local icon = btn.icon
    if icon then
        icon:ClearAllPoints()
        if pushed then
            icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -7)
            icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6, 5)
        else
            icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -7)
            icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -7, 7)
        end
    end
    local mask = btn._fluxPortraitMask
    if mask then
        mask:ClearAllPoints()
        mask:SetPoint("CENTER", btn, "CENTER", pushed and 2 or 0, pushed and -2 or 0)
    end
    if btn._fluxPushedShadow then
        btn._fluxPushedShadow:SetShown(pushed)
    end
    local glow = btn._fluxPortraitGlow
    if glow and icon and glow.ClearAllPoints and glow.SetAllPoints then
        glow:ClearAllPoints()
        glow:SetAllPoints(icon)
    end
end

--- Dragonflight shell uses separate up/down plates. Locking SetButtonState
--- blocks clicks, and the Forever opener owns the left click, so the plate
--- alphas are what keep the button looking down.
local function ApplyCharacterPlate(btn, pushed)
    if not btn then
        return
    end
    if InCombatLockdown() and btn.IsProtected and btn:IsProtected() then
        return
    end
    local up = btn._fluxBg
    local down = btn._fluxDownLatch or btn._fluxPushedBg
    if up and up.SetAlpha then
        up:SetAlpha(pushed and 0 or 1)
    end
    if down and down.SetAlpha then
        down:SetAlpha(pushed and 1 or 0)
        if down.SetDrawLayer then
            down:SetDrawLayer("BACKGROUND", 2)
        end
    end
    if btn._fluxPushedShadow or btn._fluxPortraitMask then
        LayoutCharacterFace(btn, pushed)
    elseif btn.icon then
        if pushed then
            btn.icon:SetTexCoord(0.2666, 0.8666, 0, 0.8333)
            btn.icon:SetAlpha(0.5)
        else
            btn.icon:SetTexCoord(0.2, 0.8, 0.0666, 0.9)
            btn.icon:SetAlpha(1)
        end
    end
    btn._fluxPlatePushed = pushed and true or false
end

local function SyncCharacterButton(btn)
    if not btn then
        return
    end
    ApplyCharacterPlate(btn, CharacterPanelShown())
end

--- The secure child receives the left click, so this button never enters the
--- pushed state on its own. Mirror the real micro button while the mouse is
--- down and while the character window is open.
local function TrackCharacterPress(btn)
    if not btn or btn._fluxPressTrack then
        return
    end
    btn._fluxPressTrack = true
    local watch = CreateFrame("Frame", "FluxChatCharacterPressDriver")
    watch:SetScript("OnUpdate", function()
        if not btn:IsShown() then
            return
        end
        local holding = IsMouseButtonDown and IsMouseButtonDown("LeftButton") and btn:IsMouseOver()
        local pushed = holding or CharacterPanelShown()
        if btn._fluxPlatePushed ~= pushed then
            ApplyCharacterPlate(btn, pushed and true or false)
        end
    end)
end

local function WatchCharacterFrame(btn)
    -- Forever HideUIPanel runs OnHide inside the secure close that reaches
    -- SetPreferredGamepadInteractTarget. TrackCharacterPress already mirrors
    -- the open panel, so this frame is not hooked there.
    if IsCamelotClient() then
        return
    end
    local function Hook()
        local frame = _G.CharacterFrame
        if not frame or frame._fluxChatCharHook or not frame.HookScript then
            return false
        end
        frame._fluxChatCharHook = true
        frame:HookScript("OnShow", function()
            SyncCharacterButton(btn)
        end)
        frame:HookScript("OnHide", function()
            SyncCharacterButton(btn)
        end)
        SyncCharacterButton(btn)
        return true
    end
    if Hook() then
        return
    end
    local waiter = CreateFrame("Frame")
    waiter:RegisterEvent("ADDON_LOADED")
    waiter:SetScript("OnEvent", function(self)
        if Hook() then
            self:UnregisterAllEvents()
        end
    end)
end

--- Forever: a child secure button clicks CharacterMicroButton. The visible button
--- keeps tooltip and right-click scripts. Putting those scripts on the secure
--- button taints the click, so Character Info never opens.
local function AttachCamelotCharacterOpener(btn)
    local function ArmOpener()
        if InCombatLockdown() then
            return false
        end
        local target = _G.CharacterMicroButton
        if not target then
            return false
        end
        local opener = btn._fluxCharOpener
        if not opener then
            local ok, created = pcall(CreateFrame, "Button", "FluxCCPChatCharacterOpener", btn, "SecureActionButtonTemplate")
            if not ok or not created then
                return false
            end
            opener = created
            btn._fluxCharOpener = opener
            opener:SetAllPoints(btn)
            opener:RegisterForClicks("LeftButtonUp")
            if opener.SetPropagateMouseMotion then
                opener:SetPropagateMouseMotion(true)
            end
            if opener.SetPassThroughButtons then
                opener:SetPassThroughButtons("RightButton")
            end
        end
        opener:SetAttribute("type", "click")
        opener:SetAttribute("clickbutton", target)
        opener:SetAttribute("useOnKeyDown", false)
        opener:SetFrameLevel((btn:GetFrameLevel() or 0) + 5)
        opener:Show()
        TrackCharacterPress(btn)
        return true
    end
    if not ArmOpener() then
        local waiter = CreateFrame("Frame")
        waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        waiter:RegisterEvent("PLAYER_ENTERING_WORLD")
        waiter:SetScript("OnEvent", function(self)
            if ArmOpener() then
                self:UnregisterAllEvents()
            end
        end)
    end
    if not btn._fluxAutoRepairClick then
        btn._fluxAutoRepairClick = true
        btn:RegisterForClicks("RightButtonUp")
        btn:HookScript("OnClick", function(self, button)
            if button ~= "RightButton" then
                return
            end
            ToggleChatCharacterOutfitFlyout(self)
        end)
    end
end

local function BindDirectCharacterClick(btn)
    if btn._fluxDurFallbackClick then
        return
    end
    btn._fluxDurFallbackClick = true
    -- One up-click. AnyDown plus AnyUp runs OnClick twice and the panel opens then closes.
    btn:RegisterForClicks("AnyUp")
    btn:EnableMouse(true)
    if btn.SetMouseClickEnabled then
        btn:SetMouseClickEnabled(true)
    end
    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ToggleChatCharacterOutfitFlyout(self)
            return
        end
        if CombatBlocked() then
            return
        end
        OpenCharacterPanel()
        SyncCharacterButton(self)
    end)
end

local function CreateCharacterButton(parent)
    -- Classic/anniversary CharacterMicroButton opens from OnMouseDown, not OnClick.
    -- A secure Click() never reaches that, so those clients call ToggleCharacter.
    -- Forever uses a child secure button, so Character OnShow runs untainted.
    local classicFamily = IsClassicFamilyClient()
    local secretClient = (not classicFamily) and (IsCamelotClient() or issecretvalue)
    local secure = (not secretClient) and UseDfShell() and not classicFamily
    local btn
    if secure then
        local ok, created = pcall(CreateFrame, "Button", "FluxCCPChatDurabilityButton", parent, "SecureActionButtonTemplate")
        btn = (ok and created) or CreateFrame("Button", "FluxCCPChatDurabilityButton", parent)
        secure = ok and created and true or false
    else
        btn = CreateFrame("Button", "FluxCCPChatDurabilityButton", parent)
    end
    DressMicroShell(btn, false)
    ApplyPortrait(btn)
    local pct = AddUnderLabel(btn)
    pct:Hide()

    local function Arm()
        if classicFamily then
            BindDirectCharacterClick(btn)
            return true
        end
        if secure then
            if InCombatLockdown() then
                return false
            end
            -- SecureActionButton treats addon clicks like keybinds. With
            -- ActionButtonUseKeyDown on, an AnyUp-only button never runs.
            btn:RegisterForClicks("AnyDown", "AnyUp")
            local target = _G.CharacterMicroButton
            if not target then
                return false
            end
            -- type1 only: right click opens the outfit flyout and must not open Character Info.
            btn:SetAttribute("type", nil)
            btn:SetAttribute("clickbutton", nil)
            btn:SetAttribute("type1", "click")
            btn:SetAttribute("clickbutton1", target)
            btn:SetAttribute("useOnKeyDown", true)
            btn:SetAttribute("pressAndHoldAction", false)
            if not btn._fluxDurPostClick then
                btn._fluxDurPostClick = true
                btn:SetScript("PostClick", function(self, button)
                    if button == "RightButton" then
                        if IsMouseButtonDown and IsMouseButtonDown("RightButton") then
                            return
                        end
                        ToggleChatCharacterOutfitFlyout(self)
                        return
                    end
                    if button and button ~= "LeftButton" then
                        return
                    end
                    if InCombatLockdown() then
                        CombatBlocked()
                        return
                    end
                    SyncCharacterButton(self)
                end)
            end
            return true
        end
        if IsForeverClient() and not IsClassicFamilyClient() then
            if not btn._fluxAutoRepairClick then
                btn._fluxAutoRepairClick = true
                btn:HookScript("OnMouseUp", function(self, button)
                    if button ~= "RightButton" then
                        return
                    end
                    ToggleChatCharacterOutfitFlyout(self)
                end)
            end
            return true
        end
        BindDirectCharacterClick(btn)
        return true
    end
    if not Arm() then
        local waiter = CreateFrame("Frame")
        waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        waiter:RegisterEvent("PLAYER_ENTERING_WORLD")
        waiter:SetScript("OnEvent", function(self)
            if Arm() then
                self:UnregisterAllEvents()
            end
        end)
    end

    btn:SetScript("OnEnter", function(self)
        ShowCharacterTooltip(self)
        if FluxShowCharacterPortraitGlow then
            FluxShowCharacterPortraitGlow(self)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if GameTooltip then
            GameTooltip:Hide()
        end
        if FluxHideCharacterPortraitGlow then
            FluxHideCharacterPortraitGlow(self)
        end
    end)
    WatchCharacterFrame(btn)

    local function UpdateDurability()
        local lowest = 100
        if GetInventoryItemDurability then
            for slot = 1, 18 do
                local cur, mx = GetInventoryItemDurability(slot)
                if issecretvalue and (issecretvalue(cur) or issecretvalue(mx)) then
                    cur, mx = nil, nil
                end
                if cur and mx and mx > 0 then
                    local pctValue = (cur / mx) * 100
                    if pctValue < lowest then
                        lowest = pctValue
                    end
                end
            end
        end
        btn._fluxDurabilityPct = lowest
        if btn.icon then
            btn.icon:SetVertexColor(1, 1, 1, 1)
        end
        if lowest >= 100 then
            pct:Hide()
            return
        end
        pct:SetText(math.floor(lowest) .. "%")
        pct:SetTextColor(DurabilityTextColor(lowest))
        pct:Show()
    end
    local events = CreateFrame("Frame")
    events:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    events:RegisterEvent("UPDATE_INVENTORY_ALERTS")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    events:RegisterEvent("PORTRAITS_UPDATED")
    events:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_PORTRAIT_UPDATE" then
            if unit ~= "player" then
                return
            end
            ApplyPortrait(btn)
            return
        end
        if event == "PORTRAITS_UPDATED" then
            ApplyPortrait(btn)
            return
        end
        UpdateDurability()
    end)
    UpdateDurability()
    if IsCamelotClient() and not classicFamily then
        TrackCharacterPress(btn)
        AttachCamelotCharacterOpener(btn)
    elseif btn._fluxCharOpener then
        btn._fluxCharOpener:EnableMouse(false)
        btn._fluxCharOpener:Hide()
    end
    return btn
end

function FluxChatColumnMicros.Create(parent)
    if not parent or _G.FluxCCPChatBagButton then
        return _G.FluxCCPChatBagButton, _G.FluxCCPChatDurabilityButton
    end
    local bag = CreateBagButton(parent)
    local character = CreateCharacterButton(parent)
    return bag, character
end
