-- FluxDetails.lua
-- Dedicated module for Details! damage meter integration within FluxUI
-- Safer, cleaner implementation to prevent crashes and race conditions
-- Post-login embed/hide via ApplyPostLoginState after Details UI ready (InstallOkey / StartMeUp)
-- Aggressive layout enforcement via Method Hooking (No Ticker)
-- Fixed SetUserPlaced/SetMovable error

local addonName, addonTable = ...
local Flux = addonTable and addonTable.Flux or _G.Flux

-- Create the public API
FluxDetails = {}

local PROFILE_NAME = "FluxUI"

-- Vertical layout for embedded meters (mode 1 + mode 2 top/bottom rows must match)
local EMBED_DAMAGE_TOP_OFF = 20
local EMBED_DAMAGE_BOT_OFF = 100 -- legacy fallback when topRowFrac missing
local EMBED_HEAL_TOP_OFF = 186 -- legacy fallback
-- Details title/chrome needs real separation; 4px looked like overlapping rows.
local EMBED_ROW_GAP = 16
local EMBED_TOP_ROW_FRAC_DEFAULT = 0.60
local EMBED_TOP_ROW_FRAC_MIN = 0.25
local EMBED_TOP_ROW_FRAC_MAX = 0.75

-- Default left column fraction when row has 2 slots (overridable via layout config)
local METER_GRID_LEFT_COL_FRAC = 0.45

-- Bar height: standard meters vs FluxThreat panel (threat uses 1.5x row height in embed; font stays x1)
local FLUX_DETAILS_BAR_HEIGHT = 14
local FLUX_THREAT_BAR_HEIGHT = 21 -- 14 * 1.5

-- Layout presets (read-only templates). Slots use structured descriptors:
--   { kind="attr", attribute=N, subAttribute=M } or { kind="plugin", plugin="DETAILS_PLUGIN_..." }
-- Legacy { type="damage"|... } still accepted via NormalizeSlot.
local function S(attr, sub) return { kind = "attr", attribute = attr, subAttribute = sub } end
local function P(name) return { kind = "plugin", plugin = name } end
local THREAT = "DETAILS_PLUGIN_FLUX_THREAT"

FluxDetails.LAYOUT_PRESETS = {
    [1] = {
        topSlots = { S(1, 1) },
        bottomSlots = { S(2, 1) },
        topColFracs = { 1 }, bottomColFracs = { 1 }, topRowFrac = 0.60,
    },
    [2] = {
        topSlots = { P(THREAT), S(1, 1) },
        bottomSlots = { S(4, 4), S(2, 1) },
        topColFracs = { 0.45, 0.55 }, bottomColFracs = { 0.45, 0.55 }, topRowFrac = 0.60,
    },
    [3] = {
        topSlots = { S(4, 3), S(1, 1) },
        bottomSlots = { S(4, 4), S(2, 1) },
        topColFracs = { 0.45, 0.55 }, bottomColFracs = { 0.45, 0.55 }, topRowFrac = 0.60,
    },
    [4] = {
        topSlots = { S(1, 1) },
        bottomSlots = { S(4, 3), S(2, 1) },
        topColFracs = { 1 }, bottomColFracs = { 0.45, 0.55 }, topRowFrac = 0.60,
    },
    [5] = {
        topSlots = { S(1, 1) },
        bottomSlots = { S(4, 4), S(2, 1) },
        topColFracs = { 1 }, bottomColFracs = { 0.45, 0.55 }, topRowFrac = 0.60,
    },
    [6] = {
        topSlots = { S(1, 1) },
        bottomSlots = { P(THREAT), S(2, 1) },
        topColFracs = { 1 }, bottomColFracs = { 0.45, 0.55 }, topRowFrac = 0.60,
    },
    [7] = {
        topSlots = { P(THREAT), S(1, 1) },
        bottomSlots = { S(2, 1) },
        topColFracs = { 0.45, 0.55 }, bottomColFracs = { 1 }, topRowFrac = 0.60,
    },
    [8] = {
        topSlots = { S(4, 3), S(1, 1) },
        bottomSlots = { S(2, 1) },
        topColFracs = { 0.45, 0.55 }, bottomColFracs = { 1 }, topRowFrac = 0.60,
    },
    [9] = {
        topSlots = { S(1, 1) },
        bottomSlots = {},
        topColFracs = { 1 }, bottomColFracs = { 1 }, topRowFrac = 0.60,
    },
    [10] = {
        topSlots = { P(THREAT), S(1, 1) },
        bottomSlots = {},
        topColFracs = { 0.45, 0.55 }, bottomColFracs = { 1 }, topRowFrac = 0.60,
    },
    [11] = {
        topSlots = { S(4, 3), S(1, 1) },
        bottomSlots = {},
        topColFracs = { 0.45, 0.55 }, bottomColFracs = { 1 }, topRowFrac = 0.60,
    },
}
local LAYOUT_PRESET_COUNT = 11

-- When FLUX_API.skipFluxThreatMeterLayouts, map threat-only presets to non-threat equivalents
local THREAT_LAYOUT_PRESET_MAP = { [2] = 3, [6] = 5, [7] = 8, [10] = 11 }

--- Resolve saved/UI preset id to the layout actually embedded on retail post-DF.
function FluxDetails:GetEffectiveLayoutPresetId(presetId)
    if type(presetId) ~= "number" then return 1 end
    if FLUX_API and FLUX_API.skipFluxThreatMeterLayouts then
        return THREAT_LAYOUT_PRESET_MAP[presetId] or presetId
    end
    return presetId
end

-- State tracking
local embeddedParentFrame = nil
local isEmbedded = false
local currentLayoutConfig = nil
-- Invalidate staggered Embed timers when a new Embed/layout starts (avoids old passes overwriting new layout).
local embedOperationGeneration = 0

-- No-op for disabling movement (used only for SetScript/Hooks locally)
local nop = function() end

-- Helper: Check for Details
local function IsDetailsAvailable()
    return _G.Details ~= nil
end

-- Details is UI-ready only after StartMeUp (PLAYER_LOGIN). Global exists earlier at ADDON_LOADED.
local function IsDetailsUIReady()
    local D = _G.Details
    if not D then return false end
    if D.IsLoaded and not D:IsLoaded() then return false end
    if D.InstallOkey then
        return D:InstallOkey() == true
    end
    return D.AndIWillNeverStop == true
end

function FluxDetails:IsDetailsUIReady()
    return IsDetailsUIReady()
end

-- Re-apply embed layout when Details opens instances or applies a profile while we are embedded.
local detailsEventListener = nil
local detailsEventRefreshPending = false
local detailsSkinHooksInstalled = false
local detailsSkinHookRefreshPending = false

-- Details RefreshAfterStartup (+1s) and ChangeSkin/ChangeIcon restore chrome/icons after our Configure.
-- IMPORTANT: never call full LayoutMeterGrid from ChangeSkin — Details options / bar creation fire
-- ChangeSkin constantly and that feedback loop freezes the client.
local embedHeavyRefreshSuspended = false

-- Forward-declare: ApplyLightEmbedChrome runs before these are assigned (Lua local scoping).
local SuppressDetailsInstanceChrome
local SuppressDetailsStretchButton
local ApplyLightEmbedChrome
local ScheduleLightChromeRefresh
local EnsureDetailsSkinHooks
local EnsureDetailsEventListener
local EnsureDetailsMaxWindows

-- Details HideMainIcon indexes self.baseframe; inactive/unbuilt instances crash without it.
local function SafeHideMainIcon(inst)
    if not inst or not inst.HideMainIcon then return end
    if not (inst.baseframe or inst.widget or inst.__frame) then return end
    pcall(inst.HideMainIcon, inst, true)
end

function ApplyLightEmbedChrome(inst)
    if not isEmbedded or not inst then return end
    if not (inst.baseframe or inst.widget or inst.__frame) then return end
    inst.hide_icon = true
    SafeHideMainIcon(inst)
    if SuppressDetailsInstanceChrome then
        SuppressDetailsInstanceChrome(inst)
    end
    if SuppressDetailsStretchButton then
        SuppressDetailsStretchButton(inst)
    end
    if _G.FluxDetailsWoWSkinTint then
        FluxDetailsWoWSkinTint.ApplyToInstance(inst)
    end
end

function ScheduleLightChromeRefresh()
    if not isEmbedded or embedHeavyRefreshSuspended then return end
    if detailsSkinHookRefreshPending then return end
    detailsSkinHookRefreshPending = true
    C_Timer.After(0.15, function()
        detailsSkinHookRefreshPending = false
        if not isEmbedded or embedHeavyRefreshSuspended then return end
        local D = _G.Details
        if not D or not D.tabela_instancias then return end
        for _, inst in ipairs(D.tabela_instancias) do
            -- Skip inactive/unbuilt windows (no baseframe → HideMainIcon crashes).
            if inst and isEmbedded and inst.baseframe and (not inst.IsEnabled or inst:IsEnabled()) then
                ApplyLightEmbedChrome(inst)
            end
        end
    end)
end

function EnsureDetailsSkinHooks()
    local D = _G.Details
    if not D or detailsSkinHooksInstalled then return end
    detailsSkinHooksInstalled = true

    if type(D.ChangeSkin) == "function" then
        hooksecurefunc(D, "ChangeSkin", function(inst)
            if not isEmbedded or not inst or embedHeavyRefreshSuspended then return end
            ScheduleLightChromeRefresh()
        end)
    end

    if type(D.ChangeIcon) == "function" then
        hooksecurefunc(D, "ChangeIcon", function(inst)
            if not isEmbedded or not inst then return end
            inst.hide_icon = true
            SafeHideMainIcon(inst)
        end)
    end

    if D.ToolBar and type(D.ToolBar.ReorganizeIcons) == "function" then
        hooksecurefunc(D.ToolBar, "ReorganizeIcons", function()
            if not isEmbedded or embedHeavyRefreshSuspended then return end
            ScheduleLightChromeRefresh()
        end)
    end
end

function EnsureDetailsEventListener()
    local D = _G.Details
    if not D or type(D.CreateEventListener) ~= "function" then return end
    EnsureDetailsSkinHooks()
    if detailsEventListener then return end
    detailsEventListener = D:CreateEventListener()
    local function lightRefreshIfEmbedded()
        if not isEmbedded or embedHeavyRefreshSuspended then return end
        ScheduleLightChromeRefresh()
    end
    -- OPEN / PROFILE may need geometry; still use light refresh (guards keep anchors).
    -- Do NOT listen to CHANGEATTRIBUTE — it fires constantly and caused option/bar lag.
    detailsEventListener:RegisterEvent("DETAILS_INSTANCE_OPEN", lightRefreshIfEmbedded)
    detailsEventListener:RegisterEvent("DETAILS_PROFILE_APPLYED", function()
        -- Profiles reset instances_amount (default 5); Flux needs up to 6 panes.
        EnsureDetailsMaxWindows()
        lightRefreshIfEmbedded()
    end)
end

-- ---------------------------------------------------------------------------
-- Window Management Helpers
-- ---------------------------------------------------------------------------

-- Details default Window Amount is 5; Flux meter layouts use up to 6 (3 top + 3 bottom).
local FLUX_DETAILS_MIN_INSTANCES = 6

--- Raise Details' max window limit so CreateInstance does not show STRING_INSTANCE_LIMIT.
function EnsureDetailsMaxWindows(minAmount)
    local D = _G.Details
    if not D then return end
    minAmount = minAmount or FLUX_DETAILS_MIN_INSTANCES
    local current = tonumber(D.instances_amount) or 0
    if current >= minAmount then return end
    if type(D.SetMaxInstancesAmount) == "function" then
        D:SetMaxInstancesAmount(minAmount)
    else
        D.instances_amount = minAmount
    end
end

local function EnsureNWindows(n)
    if not IsDetailsAvailable() then return nil end
    local D = _G.Details
    if not (D and D.tabela_instancias) then return nil end
    n = math.max(1, math.min(6, n or 1))
    EnsureDetailsMaxWindows(math.max(FLUX_DETAILS_MIN_INSTANCES, n))
    local guard = 0
    while #D.tabela_instancias < n and guard < 8 do
        guard = guard + 1
        if D.NewWindow then
            D:NewWindow()
        elseif D.CreateInstance then
            D:CreateInstance()
        else
            break
        end
    end
    if #D.tabela_instancias < n then return nil end
    local out = {}
    for i = 1, n do
        out[i] = D.tabela_instancias[i]
    end
    return out
end

local function EnsureTwoWindows()
    local list = EnsureNWindows(2)
    if not list then return end
    return list[1], list[2]
end

local function EnsureFourWindows()
    local list = EnsureNWindows(4)
    if not list then return end
    return list[1], list[2], list[3], list[4]
end

local function ApplyWoWSkin(inst)
    if not inst then return end
    if inst.skin ~= "WoW Interface" and inst.ChangeSkin then
        inst:ChangeSkin("WoW Interface")
        inst.skin = "WoW Interface"
    end
    -- WoW Interface skin defaults hide_icon=false; Flux embed always hides the attribute icon.
    inst.hide_icon = true
    SafeHideMainIcon(inst)
end

-- After Details RefreshLine: strip trailing decimal from percent (45.2% -> 45%) for narrow 4-panel cells.
-- Flux perf T2.16: fast-reject before the expensive gsub/closure pair. Details
-- calls this for every visible row, every RefreshLine, several times per second
-- during combat. The vast majority of frames have identical text to the
-- previous call (same %), and most strings never contain a "." in the first
-- place (e.g. non-percent columns). Skip them without allocating.
local function MaybeIntegerizeTrailingPercent(inst, line)
    if not inst or not inst.row_info or not inst.row_info.flux_integer_percent then return end
    if not line or not line.lineText4 then return end
    local text = line.lineText4:GetText()
    if not text or text == "" then return end
    -- Cheap rejection: if the text doesn't end with "%", it's not a percent cell.
    if text:sub(-1) ~= "%" then return end
    -- Must contain at least one "." to be a decimal percent worth rewriting.
    if not text:find(".", 1, true) then return end
    -- Short-circuit: if the previous normalization already produced this exact
    -- text, nothing to do. This covers the common case where the underlying
    -- percentage is stable but Details is repainting the same row.
    if line._fluxLastNormalized == text then return end
    local newText, reps = text:gsub("(%d+)%.(%d+)%%$", function(a, b)
        local v = tonumber(a .. "." .. b)
        if v then
            return math.floor(v + 0.5) .. "%"
        end
        return a .. "%"
    end)
    if reps > 0 and newText ~= text then
        line.lineText4:SetText(newText)
        line._fluxLastNormalized = newText
    else
        line._fluxLastNormalized = text
    end
end

local fluxPercentRefreshHooksInstalled = false
local function EnsureFluxRefreshLinePercentHooks()
    if fluxPercentRefreshHooksInstalled then return end
    local D = _G.Details
    if not D or not D.atributo_damage or type(D.atributo_damage.RefreshLine) ~= "function" then return end

    local function wrapRefreshLine(tbl)
        local orig = tbl.RefreshLine
        tbl.RefreshLine = function(self, inst, container, whichRowLine, ...)
            local ret = orig(self, inst, container, whichRowLine, ...)
            local line = container and whichRowLine and container[whichRowLine]
            MaybeIntegerizeTrailingPercent(inst, line)
            return ret
        end
    end

    wrapRefreshLine(D.atributo_damage)
    if D.atributo_heal and type(D.atributo_heal.RefreshLine) == "function" then
        wrapRefreshLine(D.atributo_heal)
    end
    if D.atributo_misc and type(D.atributo_misc.RefreshLine) == "function" then
        wrapRefreshLine(D.atributo_misc)
    end
    fluxPercentRefreshHooksInstalled = true
end

-- Details! optional window chrome: CreateFullBorder on baseframe + fullWindowFrame (white quads + vertex color).
-- Profiles/skins can show class-tinted outlines; Flux embed keeps them off (hide frames + clear flags).
function SuppressDetailsInstanceChrome(inst)
    if not inst or not inst.baseframe then return end
    inst.fullborder_shown = false
    inst.rowareaborder_shown = false
    if inst.UpdateFullBorder then
        pcall(function() inst:UpdateFullBorder(false) end)
    end
    if inst.UpdateRowAreaBorder then
        pcall(function() inst:UpdateRowAreaBorder(false) end)
    end
    local bf = inst.baseframe
    if bf.border and bf.border.Hide then
        bf.border:Hide()
    end
    if bf.fullWindowFrame and bf.fullWindowFrame.border and bf.fullWindowFrame.border.Hide then
        bf.fullWindowFrame.border:Hide()
    end
end

-- Details core creates a per-window stretch drag button ("DetailsButtonStretch<id>").
-- Flux embed must keep this fully disabled so it cannot resize/move embedded instances.
function SuppressDetailsStretchButton(inst)
    if not inst then return end

    local stretchButton = inst.button_stretch
    if not stretchButton and inst.meu_id then
        stretchButton = _G["DetailsButtonStretch" .. tostring(inst.meu_id)]
    end
    if not stretchButton then return end

    inst.button_stretch = stretchButton
    if stretchButton.Hide then
        stretchButton:Hide()
    end
    if stretchButton.EnableMouse then
        stretchButton:EnableMouse(false)
    end
    if stretchButton.SetAlpha then
        stretchButton:SetAlpha(0)
    end
    if stretchButton.SetScale then
        stretchButton:SetScale(0.0001)
    end
    if stretchButton.SetScript then
        stretchButton:SetScript("OnMouseDown", nop)
        stretchButton:SetScript("OnMouseUp", nop)
        stretchButton:SetScript("OnClick", nop)
        stretchButton:SetScript("OnShow", function(self)
            self:Hide()
        end)
    end
end

local function ConfigureInstance(inst, embedOpts)
    if not inst then return end
    embedOpts = embedOpts or {}

    EnsureFluxRefreshLinePercentHooks()

    local barHeight = embedOpts.threatTallRows and FLUX_THREAT_BAR_HEIGHT or FLUX_DETAILS_BAR_HEIGHT

    -- Visual settings
    if inst.SetBarSettings then inst:SetBarSettings(barHeight, 0) end
    if inst.SetBarTexture then inst:SetBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar") end
    
    -- Match FluxThreat bar text (Accidental Presidency + readable shadow).
    -- Modern Details uses outline_mode + shadow_offset; the old textL_outline boolean
    -- only feeds FluxThreat's DF bar.shadow — InstanceRefreshRows ignores it for damage bars.
    inst.use_multi_fontstrings = false
    if inst.row_info then
        inst.row_info.font_face = "Accidental Presidency"
        inst.row_info.font_size = 14
        inst.row_info.textL_outline = true
        inst.row_info.textR_outline = true
        inst.row_info.textL_outline_mode = "OUTLINE"
        inst.row_info.textR_outline_mode = "OUTLINE"
        inst.row_info.textL_outline_small = true
        inst.row_info.textR_outline_small = true
        inst.row_info.textL_outline_small_color = {0, 0, 0, 1}
        inst.row_info.textR_outline_small_color = {0, 0, 0, 1}
        inst.row_info.textL_shadow_color = {0, 0, 0, 1}
        inst.row_info.textR_shadow_color = {0, 0, 0, 1}
        inst.row_info.textL_shadow_offset = {1, -1}
        inst.row_info.textR_shadow_offset = {1, -1}
        inst.row_info.fixed_text_color = {1, 1, 1, 1}
        inst.row_info.textL_class_colors = false
        inst.row_info.textR_class_colors = false
        inst.row_info.textL_offsetY = 1
        inst.row_info.textR_offsetY = 1
        -- Tall threat bar: keep class/spec icons sized like a 14px row (see FluxThreat SetThreatUnitIcon).
        if embedOpts.threatTallRows then
            inst.row_info.flux_threat_icon_base_height = FLUX_DETAILS_BAR_HEIGHT
        else
            inst.row_info.flux_threat_icon_base_height = nil
        end
        inst.row_info.textR_enable_custom_text = true
        inst.row_info.textR_custom_text = "{data1}||{data2}||{data3}"
        -- In-combat fast PS uses :gsub(oldDps, newDps) on the whole right string; patterns are NOT plain,
        -- so abbreviated DPS like "1.2k" makes "." match any char and corrupts text (missing "|" between segments).
        inst.row_info.fast_ps_update = false
        -- 4-window mode: show 45% not 45.2% (Details hardcodes %.1f inside RefreshLine).
        inst.row_info.flux_integer_percent = embedOpts.integerPercent and true or false
    end
    if inst.SetBarTextSettings then
        pcall(function()
            -- size, font, fixedcolor, leftClass, rightClass, leftOutline, rightOutline
            inst:SetBarTextSettings(14, "Accidental Presidency", {1, 1, 1, 1}, false, false, true, true)
        end)
    end
    if inst.SetBarOutlineSettings then
        pcall(function()
            inst:SetBarOutlineSettings("left", "OUTLINE", {0, 0, 0, 1}, 1, -1)
            inst:SetBarOutlineSettings("right", "OUTLINE", {0, 0, 0, 1}, 1, -1)
        end)
    end
    -- fontstrings_text_limit_offset only affects AutoAlignInLineFontStrings (multi fontstrings); not used here.

    -- Title Bar & Menu
    if inst.SetUseCustomTitleBar then inst:SetUseCustomTitleBar(false) end
    if inst.SetTitleBarShown then inst:SetTitleBarShown(true) end
    if inst.SetAutoHideMenu then inst:SetAutoHideMenu(true) end
    
    -- Hide icons with the Details HideMainIcon API — HideIcon does not exist.
    inst.hide_icon = true
    inst.toolbar_side = 1
    inst.menu_icons_size = 1
    SafeHideMainIcon(inst)
    if inst.SetToolbarSide then inst:SetToolbarSide(1) end
    if inst.SetMenuIconsSize then inst:SetMenuIconsSize(1) end

    -- Font Settings (Gold/Yellow Friz Quadrata)
    -- Title combat timer ([mm:ss] before attribute name): off by default for Flux embed — repeated
    -- ConfigureInstance/AttributeMenu passes (layout stabilizers) could make it look oversized or duplicated.
    local color = NORMAL_FONT_COLOR
    local showTitleTimer = embedOpts.titleCombatTimer == true
    if inst.AttributeMenu then
        if showTitleTimer then
            inst:AttributeMenu(true, -16, 1, "Friz Quadrata TT", 12, {color.r, color.g, color.b, 1}, 1, true, true, true, true)
        else
            inst:AttributeMenu(true, -16, 1, "Friz Quadrata TT", 12, {color.r, color.g, color.b, 1}, 1, true, false, false, false)
            if inst.attribute_text then
                inst.attribute_text.show_timer_always = false
            end
            if inst.RefreshTitleBarText then
                pcall(function() inst:RefreshTitleBarText() end)
            end
        end
    end

    -- Buttons
    if inst.SetShowInstanceButton then inst:SetShowInstanceButton(true) end
    if inst.SetShowConfigButton then inst:SetShowConfigButton(true) end
    if inst.SetShowSegmentButton then inst:SetShowSegmentButton(true) end
    if inst.SetShowModeButton then inst:SetShowModeButton(true) end
    if inst.SetShowMenuButton then inst:SetShowMenuButton(true) end
    if inst.SetShowMenuButton then inst:SetShowMenuButton(true) end
    if inst.SetShowCloseButton then inst:SetShowCloseButton(false) end
    
    -- Stop fast PS ticker if it was running (matches fast_ps_update = false above)
    if inst.FastPSUpdate then
        pcall(function() inst:FastPSUpdate(false) end)
    end

    -- Create bars if EnableInstance ran under the embed ReajustaGump wrapper before
    -- anchors/size were settled (InstanceRefreshRows no-ops when barras is empty).
    if inst.baseframe and (not inst.barras or not inst.barras[1] or (inst.rows_created or 0) < 1) then
        local orig = inst.__OriginalReajustaGump
        if orig then
            pcall(orig, inst)
        elseif inst.ReajustaGump then
            pcall(function() inst:ReajustaGump() end)
        end
    end

    -- Refresh rows
    if _G.Details.InstanceRefreshRows then
        _G.Details:InstanceRefreshRows(inst)
    end

    SuppressDetailsInstanceChrome(inst)
    SuppressDetailsStretchButton(inst)

    if _G.FluxDetailsWoWSkinTint then
        FluxDetailsWoWSkinTint.EnsureInstanceColorHook()
        FluxDetailsWoWSkinTint.ApplyToInstance(inst)
    end
end

-- ---------------------------------------------------------------------------
-- Layout / Embedding with Method Hooking
-- ---------------------------------------------------------------------------

-- Ensure profile / frames allow pointer hits on rows (breakdown opens on MouseUp).
local function ApplyEmbedClickFix(inst)
    if not inst or not isEmbedded then return end

    inst.clickthrough_rows = false
    inst.clickthrough_window = false
    if inst.UpdateClickThrough then
        inst:UpdateClickThrough()
    end

    if inst.barras then
        for _, bar in ipairs(inst.barras) do
            if bar then
                if bar.EnableMouse then bar:EnableMouse(true) end
                if bar.icon_frame and bar.icon_frame.EnableMouse then
                    bar.icon_frame:EnableMouse(true)
                end
                -- Full-bar overlays that default to mouse on can block the row Button underneath.
                if bar.modelbox_low and bar.modelbox_low.EnableMouse then
                    bar.modelbox_low:EnableMouse(false)
                end
                if bar.modelbox_high and bar.modelbox_high.EnableMouse then
                    bar.modelbox_high:EnableMouse(false)
                end
                if bar.statusbar and bar.statusbar.EnableMouse then
                    bar.statusbar:EnableMouse(false)
                end
                if bar.extraStatusbar and bar.extraStatusbar.EnableMouse then
                    bar.extraStatusbar:EnableMouse(false)
                end
            end
        end
    end
end

-- Embedded-only tweaks. Do not recurse and reshuffle every child: that breaks Details' own
-- background vs row vs toolbar stacking. Clicks through FluxBorder use EnableMouse(false) there.
local function SetDetailsFrameLevels(inst)
    if not inst then return end
    
    local w = inst.baseframe or inst.widget or inst.__frame
    if not w then return end

    local parent = w.GetParent and w:GetParent()
    if isEmbedded and parent and parent.FluxBorderFrame and parent.FluxBorderFrame.EnableMouse then
        parent.FluxBorderFrame:EnableMouse(false)
    end
    
    if w.SetFrameStrata then
        w:SetFrameStrata("MEDIUM")
    end
    -- Match Details default from CriaJanelaPrincipal; avoid high values (they skew entire subtree vs host UI).
    if w.SetFrameLevel then
        w:SetFrameLevel(2)
    end

    -- Row layer above fullscreen switch button so bar MouseUp/breakdown works (see chat_embed pattern).
    if inst.windowSwitchButton then
        if inst.windowSwitchButton.SetFrameStrata then
            inst.windowSwitchButton:SetFrameStrata("MEDIUM")
        end
        if inst.windowSwitchButton.SetFrameLevel then
            inst.windowSwitchButton:SetFrameLevel(2)
        end
    end

    if inst.rowframe then
        if inst.rowframe.SetFrameStrata then
            inst.rowframe:SetFrameStrata("MEDIUM")
        end
        if inst.rowframe.SetFrameLevel then
            inst.rowframe:SetFrameLevel(10)
        end
    end

    if isEmbedded then
        SuppressDetailsInstanceChrome(inst)
        SuppressDetailsStretchButton(inst)
        if _G.FluxDetailsWoWSkinTint then
            FluxDetailsWoWSkinTint.EnsureInstanceColorHook()
            FluxDetailsWoWSkinTint.ApplyToInstance(inst)
        end
        ApplyEmbedClickFix(inst)
    end
end

-- Per-instance embed geometry. Details Restore* anchors to UIParent CENTER — we block that
-- at SetPoint/ClearAllPoints/SetParent so the jump never paints (not "fix after").
local embedLayoutByInstId = {}
local containmentWatchdog = nil
local positionRestoreHooksInstalled = false

local function InstallFrameAnchorGuards(inst)
    if not inst then return end
    local w = inst.baseframe or inst.widget or inst.__frame
    if not w or w.__fluxAnchorGuards then return end
    w.__fluxAnchorGuards = true

    w.__fluxOrigClearAllPoints = w.ClearAllPoints
    w.__fluxOrigSetPoint = w.SetPoint
    w.__fluxOrigSetParent = w.SetParent

    w.ClearAllPoints = function(self)
        if self.__fluxAllowEmbedRepos then
            return self.__fluxOrigClearAllPoints(self)
        end
        -- While embedded, ignore Details clears that precede UIParent / welcome teleports.
        if isEmbedded and embeddedParentFrame then
            return
        end
        return self.__fluxOrigClearAllPoints(self)
    end

    w.SetPoint = function(self, ...)
        if self.__fluxAllowEmbedRepos then
            return self.__fluxOrigSetPoint(self, ...)
        end
        -- While embedded, only Flux may change anchors. Blocking ClearAllPoints but
        -- allowing SetPoint (e.g. Details welcome → DetailsWelcomeWindow) causes
        -- "anchor family connection" because old Flux points are still active.
        if isEmbedded and embeddedParentFrame then
            return
        end
        return self.__fluxOrigSetPoint(self, ...)
    end

    w.SetParent = function(self, parent)
        if self.__fluxAllowEmbedRepos then
            return self.__fluxOrigSetParent(self, parent)
        end
        if isEmbedded and embeddedParentFrame then
            if parent == UIParent or parent == _G.UIParent then
                return -- stay parented to the Meter host
            end
        end
        return self.__fluxOrigSetParent(self, parent)
    end
end

local function WithEmbedAnchorWrite(frame, fn)
    if not frame then return end
    frame.__fluxAllowEmbedRepos = true
    local ok, err = pcall(fn)
    frame.__fluxAllowEmbedRepos = false
    if not ok and geterrorhandler then
        geterrorhandler()(err)
    end
end

local function EnsureEmbeddedParentage(inst, parentFrame)
    if not inst or not parentFrame then return end
    local w = inst.baseframe or inst.widget or inst.__frame
    if not w then return end

    InstallFrameAnchorGuards(inst)

    -- Ungroup/snap clear once per embed generation — not on every reassert (very expensive).
    if inst.__fluxSnapClearedGen ~= embedOperationGeneration then
        inst.__fluxSnapClearedGen = embedOperationGeneration
        if inst.UngroupInstance then
            pcall(function() inst:UngroupInstance() end)
        end
        if type(inst.snap) == "table" and _G.Details and _G.Details.Destroy then
            pcall(function() _G.Details:Destroy(inst.snap) end)
        elseif type(inst.snap) == "table" then
            wipe(inst.snap)
        end
        inst.horizontalSnap = nil
        inst.verticalSnap = nil
    end

    WithEmbedAnchorWrite(w, function()
        if w.GetParent and w:GetParent() ~= parentFrame then
            w:SetParent(parentFrame)
        elseif not w.GetParent then
            w:SetParent(parentFrame)
        end
    end)

    if inst.rowframe then
        if inst.rowframe.GetParent and inst.rowframe:GetParent() ~= w then
            inst.rowframe:SetParent(w)
            inst.rowframe:ClearAllPoints()
            inst.rowframe:SetAllPoints()
        end
    end
    if inst.windowSwitchButton then
        if inst.windowSwitchButton.GetParent and inst.windowSwitchButton:GetParent() ~= w then
            inst.windowSwitchButton:SetParent(w)
            inst.windowSwitchButton:ClearAllPoints()
            inst.windowSwitchButton:SetAllPoints()
        end
    end
    if inst.floatingframe and inst.floatingframe.SetParent then
        if not inst.floatingframe.GetParent or inst.floatingframe:GetParent() ~= w then
            inst.floatingframe:SetParent(w)
        end
    end
    if inst.bgframe and inst.bgframe.SetParent then
        if not inst.bgframe.GetParent or inst.bgframe:GetParent() ~= w then
            inst.bgframe:SetParent(w)
        end
    end
end

local function ForceCorrectPosition(inst, parentFrame, topOff, botOff)
    if not inst or not inst.baseframe or not parentFrame then return end
    EnsureEmbeddedParentage(inst, parentFrame)
    local w = inst.baseframe
    WithEmbedAnchorWrite(w, function()
        w:ClearAllPoints()
        w:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", -1, -topOff)
        w:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 1, botOff)
        if w.SetScale then w:SetScale(1) end
    end)
    if inst.rowframe and inst.rowframe.SetScale then inst.rowframe:SetScale(1) end
end

local function ForceGridPosition(inst, parentFrame, leftOff, rightOff, topOff, botOff)
    if not inst or not inst.baseframe or not parentFrame then return end
    EnsureEmbeddedParentage(inst, parentFrame)
    local w = inst.baseframe
    WithEmbedAnchorWrite(w, function()
        w:ClearAllPoints()
        w:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", leftOff, -topOff)
        w:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", rightOff, botOff)
        if w.SetScale then w:SetScale(1) end
    end)
    if inst.rowframe and inst.rowframe.SetScale then inst.rowframe:SetScale(1) end
end

local function ReassertEmbeddedInstance(inst)
    if not isEmbedded or not embeddedParentFrame or not inst then return end
    local id = inst.meu_id
    local layout = id and embedLayoutByInstId[id]
    if not layout then return end
    if layout.mode == "grid" then
        ForceGridPosition(inst, embeddedParentFrame, layout.left, layout.right, layout.top, layout.bot)
    else
        ForceCorrectPosition(inst, embeddedParentFrame, layout.top, layout.bot)
    end
    if inst.LockInstance then inst:LockInstance(true) end
    SetDetailsFrameLevels(inst)
end

local function ReassertAllEmbeddedInstances()
    if not isEmbedded or not embeddedParentFrame then return end
    local D = _G.Details
    if not D or not D.tabela_instancias then return end
    for _, inst in ipairs(D.tabela_instancias) do
        if inst and inst.meu_id and embedLayoutByInstId[inst.meu_id] then
            ReassertEmbeddedInstance(inst)
        end
    end
end

-- Details EnableInstance resets barras/rows_created then relies on ReajustaGump to
-- CreateNewLine. Stubbing the original left rows_created=0 and crashed PerformAnimations.
-- Keep original bar create/size; only reassert embed anchors around it (do not add
-- InstanceRefreshRows here — that path froze the client when ChangeSkin spam-fired).
local function InstallEmbedPositionHooks(inst)
    if not inst then return end
    InstallFrameAnchorGuards(inst)

    if not inst.__OriginalReajustaGump then
        inst.__OriginalReajustaGump = inst.ReajustaGump
    end
    inst.ReajustaGump = function(self, ...)
        if isEmbedded and embeddedParentFrame then
            ReassertEmbeddedInstance(self)
            if self.__OriginalReajustaGump then
                return self.__OriginalReajustaGump(self, ...)
            end
            return
        end
        if self.__OriginalReajustaGump then
            return self.__OriginalReajustaGump(self, ...)
        end
    end

    if not inst.__OriginalRestore then
        inst.__OriginalRestore = inst.RestoreMainWindowPosition
    end
    inst.RestoreMainWindowPosition = function(self, ...)
        if isEmbedded and embeddedParentFrame then
            ReassertEmbeddedInstance(self)
            return
        end
        if self.__OriginalRestore then
            return self.__OriginalRestore(self, ...)
        end
    end

    if not inst.__OriginalRestoreNoResize then
        inst.__OriginalRestoreNoResize = inst.RestoreMainWindowPositionNoResize
    end
    inst.RestoreMainWindowPositionNoResize = function(self, ...)
        if isEmbedded and embeddedParentFrame then
            ReassertEmbeddedInstance(self)
            return
        end
        if self.__OriginalRestoreNoResize then
            return self.__OriginalRestoreNoResize(self, ...)
        end
    end
end

local function EnsureClassPositionRestoreHooks()
    local D = _G.Details
    if not D or positionRestoreHooksInstalled then return end
    positionRestoreHooksInstalled = true

    -- Replace (not hooksecurefunc-after): prevent UIParent SetPoint from ever running while embedded.
    if type(D.RestoreMainWindowPosition) == "function" and not D.__fluxOrigRestoreMainWindowPosition then
        D.__fluxOrigRestoreMainWindowPosition = D.RestoreMainWindowPosition
        D.RestoreMainWindowPosition = function(self, ...)
            if isEmbedded and embeddedParentFrame and self then
                if self.meu_id and embedLayoutByInstId[self.meu_id] then
                    ReassertEmbeddedInstance(self)
                    return
                end
                -- Embedded but layout not recorded yet: keep current anchors, do not teleport.
                InstallFrameAnchorGuards(self)
                return
            end
            return D.__fluxOrigRestoreMainWindowPosition(self, ...)
        end
    end

    if type(D.RestoreMainWindowPositionNoResize) == "function" and not D.__fluxOrigRestoreMainWindowPositionNoResize then
        D.__fluxOrigRestoreMainWindowPositionNoResize = D.RestoreMainWindowPositionNoResize
        D.RestoreMainWindowPositionNoResize = function(self, ...)
            if isEmbedded and embeddedParentFrame and self then
                if self.meu_id and embedLayoutByInstId[self.meu_id] then
                    ReassertEmbeddedInstance(self)
                    return
                end
                InstallFrameAnchorGuards(self)
                return
            end
            return D.__fluxOrigRestoreMainWindowPositionNoResize(self, ...)
        end
    end

    if type(D.AtivarInstancia) == "function" and not D.__fluxOrigAtivarInstancia then
        D.__fluxOrigAtivarInstancia = D.AtivarInstancia
        D.AtivarInstancia = function(self, ...)
            if isEmbedded and self then
                InstallEmbedPositionHooks(self)
            end
            local a, b, c = D.__fluxOrigAtivarInstancia(self, ...)
            if isEmbedded and self then
                -- Mixin inside AtivarInstancia restores original methods; reinstall immediately.
                InstallEmbedPositionHooks(self)
                ReassertEmbeddedInstance(self)
            end
            return a, b, c
        end
    end
end

local function StartContainmentWatchdog(embedGen)
    if containmentWatchdog then
        containmentWatchdog:Cancel()
        containmentWatchdog = nil
    end
    local ticks = 0
    -- Light backup only: anchor guards block the jump; this reinstalls hooks after late Mixins.
    containmentWatchdog = C_Timer.NewTicker(0.5, function(self)
        ticks = ticks + 1
        if embedGen ~= embedOperationGeneration or not isEmbedded then
            self:Cancel()
            containmentWatchdog = nil
            return
        end
        EnsureClassPositionRestoreHooks()
        local D = _G.Details
        if D and D.tabela_instancias then
            for _, inst in ipairs(D.tabela_instancias) do
                if inst and inst.meu_id and embedLayoutByInstId[inst.meu_id] then
                    InstallEmbedPositionHooks(inst)
                    -- Only reassert if somehow parented away (guards should prevent this).
                    local w = inst.baseframe
                    if w and w.GetParent and embeddedParentFrame and w:GetParent() ~= embeddedParentFrame then
                        ReassertEmbeddedInstance(inst)
                    end
                end
            end
        end
        if ticks >= 12 then -- ~6s
            self:Cancel()
            containmentWatchdog = nil
        end
    end)
end

local function PositionWindow(inst, parentFrame, topOff, botOff)
    if not inst or not parentFrame then return end

    EnsureClassPositionRestoreHooks()

    if inst.meu_id then
        embedLayoutByInstId[inst.meu_id] = {
            mode = "stack",
            top = topOff,
            bot = botOff,
        }
    end

    local w = inst.baseframe or inst.widget or inst.__frame
    if w then
        ForceCorrectPosition(inst, parentFrame, topOff, botOff)
        w:Show()

        if w.SetMovable then w:SetMovable(true) end
        if w.SetResizable then w:SetResizable(true) end
        if w.EnableMouse then w:EnableMouse(true) end
        if w.SetScript then
            w:SetScript("OnDragStart", nil)
            w:SetScript("OnDragStop", nil)
            w:SetScript("OnSizeChanged", nil)
        end

        InstallEmbedPositionHooks(inst)
    end

    if inst.rowframe then inst.rowframe:Show() end
    if inst.barras then
        for _, bar in ipairs(inst.barras) do
            if bar then bar:Show() end
        end
    end

    if inst.LockInstance then inst:LockInstance(true) end
    SetDetailsFrameLevels(inst)
end

local function PositionWindowGrid(inst, parentFrame, leftOff, rightOff, topOff, botOff)
    if not inst or not parentFrame then return end

    EnsureClassPositionRestoreHooks()

    if inst.meu_id then
        embedLayoutByInstId[inst.meu_id] = {
            mode = "grid",
            left = leftOff,
            right = rightOff,
            top = topOff,
            bot = botOff,
        }
    end

    local w = inst.baseframe or inst.widget or inst.__frame
    if w then
        ForceGridPosition(inst, parentFrame, leftOff, rightOff, topOff, botOff)
        w:Show()

        if w.SetMovable then w:SetMovable(true) end
        if w.SetResizable then w:SetResizable(true) end
        if w.EnableMouse then w:EnableMouse(true) end
        if w.SetScript then
            w:SetScript("OnDragStart", nil)
            w:SetScript("OnDragStop", nil)
            w:SetScript("OnSizeChanged", nil)
        end

        InstallEmbedPositionHooks(inst)
    end

    if inst.rowframe then inst.rowframe:Show() end
    if inst.barras then
        for _, bar in ipairs(inst.barras) do
            if bar then bar:Show() end
        end
    end

    if inst.LockInstance then inst:LockInstance(true) end
    SetDetailsFrameLevels(inst)
end

-- Parent width can be 0 on first embed pass before layout; fall back to Flux window size.
local function GetEmbedContainerWidth(parentFrame)
    if not parentFrame or not parentFrame.GetWidth then return 400 end
    local w = parentFrame:GetWidth()
    if w and w >= 80 then
        return w
    end
    local FWF = _G.FluxWindowFrame
    if FWF and FWF.WINDOW_WIDTH then
        return FWF.WINDOW_WIDTH
    end
    return 400
end

-- Global key Details sets in InstallPlugin (see FluxThreat.lua pluginAbsoluteName)
local FLUX_THREAT_PLUGIN_KEY = "DETAILS_PLUGIN_FLUX_THREAT"

local function FindThreatPlugin()
    local p = _G.DETAILS_PLUGIN_FLUX_THREAT
    if p and p.Frame then return p end
    p = _G[FLUX_THREAT_PLUGIN_KEY]
    if p and p.Frame then return p end
    local D = _G.Details
    if not D then return nil end
    if D.RaidTables and D.RaidTables.NameTable then
        local r = D.RaidTables.NameTable[FLUX_THREAT_PLUGIN_KEY]
        if r and r.Frame then return r end
    end
    if D.RaidTables and D.RaidTables.Plugins then
        for _, plugin in ipairs(D.RaidTables.Plugins) do
            if plugin and plugin.real_name == FLUX_THREAT_PLUGIN_KEY then
                return plugin
            end
        end
    end
    return nil
end

local function AssignPluginToInstance(inst, pluginObject)
    if not inst or not pluginObject then return false end
    local D = _G.Details
    local absName = pluginObject.real_name or FLUX_THREAT_PLUGIN_KEY
    if D and D.RaidTables then
        if D.RaidTables.EnableRaidMode then
            pcall(function() D.RaidTables:EnableRaidMode(inst, absName) end)
        elseif D.RaidTables.switch then
            pcall(function() D.RaidTables:switch(nil, absName, inst) end)
        end
    end
    pluginObject.instance_id = (inst.GetId and inst:GetId()) or inst.meu_id
    if pluginObject.OnDetailsEvent then
        pcall(function() pluginObject:OnDetailsEvent("SHOW") end)
    end
    return true
end

local function TryAssignFluxThreatToInstance(inst, attempt)
    if not inst or not isEmbedded then return end
    attempt = attempt or 1
    local maxAttempts = 25
    local threatPlugin = FindThreatPlugin()
    if threatPlugin then
        AssignPluginToInstance(inst, threatPlugin)
        if inst.ReajustaGump then pcall(function() inst:ReajustaGump() end) end
        SetDetailsFrameLevels(inst)
        return
    end
    if attempt < maxAttempts then
        C_Timer.After(0.05, function() TryAssignFluxThreatToInstance(inst, attempt + 1) end)
    end
end

local function NormalizeEmbedSlot(slot)
    if FluxMeterLayout and FluxMeterLayout.NormalizeSlot then
        return FluxMeterLayout.NormalizeSlot(slot)
    end
    -- Fallback if FluxMeterLayout not loaded yet
    if type(slot) == "table" and slot.kind then return slot end
    if type(slot) == "table" and slot.type == "threat" then
        return { kind = "plugin", plugin = FLUX_THREAT_PLUGIN_KEY }
    end
    if type(slot) == "table" and slot.type == "healing" then
        return { kind = "attr", attribute = 2, subAttribute = 1 }
    end
    if type(slot) == "table" and slot.type == "dispels" then
        return { kind = "attr", attribute = 4, subAttribute = 4 }
    end
    if type(slot) == "table" and slot.type == "interrupts" then
        return { kind = "attr", attribute = 4, subAttribute = 3 }
    end
    return { kind = "attr", attribute = 1, subAttribute = 1 }
end

local function NormalizeColFracsEmbed(fracs, n)
    if FluxMeterLayout and FluxMeterLayout.NormalizeColFracs then
        return FluxMeterLayout.NormalizeColFracs(fracs, n)
    end
    n = math.max(1, n or 1)
    if type(fracs) == "table" and #fracs == n then return fracs end
    local out, each = {}, 1 / n
    for i = 1, n do out[i] = each end
    return out
end

-- Assign structured slot to a Details instance. usedPlugins tracks unique RAID plugins.
local function AssignSlot(inst, slot, usedPlugins)
    if not inst then return usedPlugins end
    usedPlugins = usedPlugins or {}
    slot = NormalizeEmbedSlot(slot)

    if slot.kind == "plugin" then
        local absName = slot.plugin or FLUX_THREAT_PLUGIN_KEY
        if usedPlugins[absName] then
            if inst.SetDisplay then inst:SetDisplay(0, 1, 1, 2) end
            return usedPlugins
        end
        usedPlugins[absName] = true
        if absName == FLUX_THREAT_PLUGIN_KEY then
            local threatPlugin = FindThreatPlugin()
            if threatPlugin then
                AssignPluginToInstance(inst, threatPlugin)
            else
                if inst.SetDisplay then inst:SetDisplay(0, 1, 1, 2) end
                TryAssignFluxThreatToInstance(inst, 1)
            end
        else
            local D = _G.Details
            if D and D.RaidTables and D.RaidTables.EnableRaidMode then
                pcall(function() D.RaidTables:EnableRaidMode(inst, absName) end)
            end
        end
        return usedPlugins
    end

    local attr = tonumber(slot.attribute) or 1
    local sub = tonumber(slot.subAttribute) or 1
    if inst.SetDisplay then
        inst:SetDisplay(0, attr, sub, 2)
    end
    return usedPlugins
end

-- Back-compat wrapper
local function AssignSlotType(inst, typeStr, threatAssigned)
    local used = {}
    if threatAssigned then used[FLUX_THREAT_PLUGIN_KEY] = true end
    local slot = type(typeStr) == "table" and typeStr or { type = typeStr }
    AssignSlot(inst, slot, used)
    return used[FLUX_THREAT_PLUGIN_KEY] == true
end

-- 1-based index among embedded instances for the first FluxThreat plugin slot.
local function GetFirstThreatSlotInstanceIndex(layoutConfig)
    if not layoutConfig then return nil end
    local topSlots = layoutConfig.topSlots or {}
    local bottomSlots = layoutConfig.bottomSlots or {}
    local idx = 1
    for _, slot in ipairs(topSlots) do
        local s = NormalizeEmbedSlot(slot)
        if s.kind == "plugin" and s.plugin == FLUX_THREAT_PLUGIN_KEY then
            return idx
        end
        idx = idx + 1
    end
    for _, slot in ipairs(bottomSlots) do
        local s = NormalizeEmbedSlot(slot)
        if s.kind == "plugin" and s.plugin == FLUX_THREAT_PLUGIN_KEY then
            return idx
        end
        idx = idx + 1
    end
    return nil
end

local function LayoutNeedsExtraPass(layoutConfig)
    local function check(list)
        for _, slot in ipairs(list or {}) do
            local s = NormalizeEmbedSlot(slot)
            if s.kind == "plugin" then return true end
            if s.kind == "attr" and (s.attribute == 4 or s.attribute == 5) then return true end
        end
        return false
    end
    return check(layoutConfig.topSlots) or check(layoutConfig.bottomSlots)
end

-- Reposition meter windows according to layout config. Supports up to 3x2 (6) windows.
local function LayoutMeterGrid(parentFrame, layoutConfig)
    if not parentFrame or not isEmbedded or not layoutConfig then return end

    local topSlots = layoutConfig.topSlots or {}
    local bottomSlots = layoutConfig.bottomSlots or {}
    if #topSlots > 3 then topSlots = { topSlots[1], topSlots[2], topSlots[3] } end
    if #bottomSlots > 3 then bottomSlots = { bottomSlots[1], bottomSlots[2], bottomSlots[3] } end

    local topRowFrac = layoutConfig.topRowFrac or EMBED_TOP_ROW_FRAC_DEFAULT
    if topRowFrac < EMBED_TOP_ROW_FRAC_MIN then topRowFrac = EMBED_TOP_ROW_FRAC_MIN end
    if topRowFrac > EMBED_TOP_ROW_FRAC_MAX then topRowFrac = EMBED_TOP_ROW_FRAC_MAX end

    local totalSlots = #topSlots + #bottomSlots
    if totalSlots < 1 or totalSlots > 6 then return end

    local hasBottomRow = #bottomSlots > 0
    local frameH = parentFrame.GetHeight and parentFrame:GetHeight() or 270
    if not frameH or frameH < 80 then
        frameH = (_G.FluxWindowFrame and _G.FluxWindowFrame.WINDOW_HEIGHT) or 270
    end

    local topPad = EMBED_DAMAGE_TOP_OFF
    local topRowBotOff = 0
    local botRowTopOff = EMBED_HEAL_TOP_OFF
    if hasBottomRow then
        local usable = math.max(40, frameH - topPad - EMBED_ROW_GAP)
        local topH = usable * topRowFrac
        topRowBotOff = frameH - (topPad + topH)
        botRowTopOff = topPad + topH + EMBED_ROW_GAP
    end

    local instances = EnsureNWindows(math.max(totalSlots, 2))
    if not instances or #instances < totalSlots then return end

    local D = _G.Details
    if D and D.RaidTables and D.RaidTables.DisableRaidMode then
        for _, inst in ipairs(instances) do
            if inst then pcall(D.RaidTables.DisableRaidMode, D.RaidTables, inst) end
        end
    end

    local frameW = GetEmbedContainerWidth(parentFrame)
    local outerLeft = -1
    local outerRight = 1

    local function PositionRow(slots, colFracs, topOff, botOff, startIdx, usedPlugins)
        local n = #slots
        if n == 0 then return startIdx, usedPlugins end
        if n == 1 then
            usedPlugins = AssignSlot(instances[startIdx], slots[1], usedPlugins)
            PositionWindow(instances[startIdx], parentFrame, topOff, botOff)
            return startIdx + 1, usedPlugins
        end
        -- Legacy leftColFrac support when colFracs missing and n==2
        if (not colFracs or #colFracs ~= n) and n == 2 then
            local left = layoutConfig.leftColFracTop or layoutConfig.leftColFracBottom or METER_GRID_LEFT_COL_FRAC
            if slots == bottomSlots then
                left = layoutConfig.leftColFracBottom or left
            else
                left = layoutConfig.leftColFracTop or left
            end
            colFracs = { left, 1 - left }
        end
        colFracs = NormalizeColFracsEmbed(colFracs, n)
        local cum = 0
        for i = 1, n do
            local leftOff = outerLeft + (frameW * cum)
            cum = cum + colFracs[i]
            local rightOff
            if i == n then
                rightOff = outerRight
            else
                local splitX = outerLeft + (frameW * cum)
                rightOff = -(frameW - splitX)
            end
            usedPlugins = AssignSlot(instances[startIdx], slots[i], usedPlugins)
            PositionWindowGrid(instances[startIdx], parentFrame, leftOff, rightOff, topOff, botOff)
            startIdx = startIdx + 1
        end
        return startIdx, usedPlugins
    end

    local idx = 1
    local usedPlugins = {}
    idx, usedPlugins = PositionRow(topSlots, layoutConfig.topColFracs, topPad, topRowBotOff, idx, usedPlugins)
    idx, usedPlugins = PositionRow(bottomSlots, layoutConfig.bottomColFracs, botRowTopOff, 0, idx, usedPlugins)

    if D and D.tabela_instancias then
        for i = idx, #D.tabela_instancias do
            local inst = D.tabela_instancias[i]
            if inst then
                local w = inst.baseframe or inst.widget or inst.__frame
                if w and w.Hide then w:Hide() end
            end
        end
    end

    for i = 1, idx - 1 do
        local inst = instances[i]
        if inst then
            SetDetailsFrameLevels(inst)
            if inst.ReajustaGump then
                pcall(function() inst:ReajustaGump() end)
            end
        end
    end

    local tp = _G.DETAILS_PLUGIN_FLUX_THREAT
    if tp and tp.SizeChanged and tp.RefreshRows then
        pcall(function()
            tp:SizeChanged()
            tp:RefreshRows()
        end)
    end
end

-- Apply row/title/icon/menu settings AFTER AssignSlotType/SetDisplay (misc, threat, dispels, interrupts).
-- If ConfigureInstance runs before LayoutMeterGrid, Details can restore spec/window icons from profile on mode change.
local function ReapplyConfigureEmbeddedInstances(layoutConfig)
    if not layoutConfig or not IsDetailsAvailable() then return end
    local D = _G.Details
    local topSlots = layoutConfig.topSlots or {}
    local bottomSlots = layoutConfig.bottomSlots or {}
    local totalSlots = #topSlots + #bottomSlots
    if totalSlots < 1 or totalSlots > 6 then return end
    local maxInst = math.min(totalSlots, 6)
    local useIntegerPercent = totalSlots > 2
    local threatSlotIndex = GetFirstThreatSlotInstanceIndex(layoutConfig)
    for i = 1, maxInst do
        local inst = D.tabela_instancias and D.tabela_instancias[i]
        if inst then
            ConfigureInstance(inst, {
                integerPercent = useIntegerPercent,
                threatTallRows = threatSlotIndex ~= nil and i == threatSlotIndex,
                titleCombatTimer = false,
            })
        end
    end
end

-- Parent OnSizeChanged can fire many times in one resize/animation; full LayoutMeterGrid is heavy
-- (reposition all instances, ReajustaGump, threat plugin). Coalesce to one pass after resize settles.
local GRID_LAYOUT_ON_SIZE_DEBOUNCE = 0.05

local function EnsureMeterGridSizeHook(parentFrame, layoutConfig)
    if not parentFrame or parentFrame.__FluxDetailsGridSizeHooked then return end
    parentFrame.__FluxDetailsGridSizeHooked = true
    parentFrame:HookScript("OnSizeChanged", function(self)
        if not isEmbedded or embeddedParentFrame ~= self then return end
        if not currentLayoutConfig then return end
        if self.__fluxDetailsSizeLayoutTimer then
            self.__fluxDetailsSizeLayoutTimer:Cancel()
            self.__fluxDetailsSizeLayoutTimer = nil
        end
        self.__fluxDetailsSizeLayoutTimer = C_Timer.After(GRID_LAYOUT_ON_SIZE_DEBOUNCE, function()
            self.__fluxDetailsSizeLayoutTimer = nil
            if not isEmbedded or embeddedParentFrame ~= self or not currentLayoutConfig then return end
            LayoutMeterGrid(self, currentLayoutConfig)
            ReapplyConfigureEmbeddedInstances(currentLayoutConfig)
        end)
    end)
end

function FluxDetails:Embed(parentFrame, layoutConfigOrMode)
    if InCombatLockdown() then
        if Flux and Flux.Combat then
            local generation = embedOperationGeneration
            Flux.Combat.Defer("details.embed", function()
                if generation == embedOperationGeneration then self:Embed(parentFrame, layoutConfigOrMode) end
            end)
        end
        return
    end
    if not IsDetailsUIReady() or not parentFrame then return end
    EnsureDetailsMaxWindows()
    EnsureDetailsEventListener()
    EnsureDetailsSkinHooks()
    EnsureClassPositionRestoreHooks()

    embedOperationGeneration = embedOperationGeneration + 1
    local embedGen = embedOperationGeneration

    embeddedParentFrame = parentFrame
    isEmbedded = true

    local D = _G.Details
    -- Arm SetPoint/SetParent guards before EnableInstance/ChangeSkin can teleport to UIParent.
    if D and D.tabela_instancias then
        for _, inst in ipairs(D.tabela_instancias) do
            if inst then
                InstallEmbedPositionHooks(inst)
            end
        end
    end
    if _G.FluxDetailsWoWSkinTint then
        FluxDetailsWoWSkinTint.EnsureInstanceColorHook()
    end

    -- Build layout config: prefer explicit table, else active working layout, else preset number.
    local layoutConfig
    if type(layoutConfigOrMode) == "table" and layoutConfigOrMode.topSlots then
        layoutConfig = layoutConfigOrMode
    elseif FluxWindowFrame and FluxWindowFrame.GetMeterLayoutConfig then
        layoutConfig = FluxWindowFrame:GetMeterLayoutConfig()
    elseif type(layoutConfigOrMode) == "number" then
        local presetId = layoutConfigOrMode
        if presetId < 1 or presetId > LAYOUT_PRESET_COUNT then presetId = 1 end
        layoutConfig = self:CopyLayoutPreset(presetId)
    else
        layoutConfig = self:CopyLayoutPreset(1)
    end

    if not layoutConfig then
        C_Timer.After(0.2, function()
            if embedGen == embedOperationGeneration and isEmbedded then self:Embed(parentFrame, 1) end
        end)
        return
    end

    currentLayoutConfig = layoutConfig
    local topSlots = layoutConfig.topSlots or {}
    local bottomSlots = layoutConfig.bottomSlots or {}
    local totalSlots = #topSlots + #bottomSlots
    if totalSlots < 1 then totalSlots = 1 end
    if totalSlots > 6 then totalSlots = 6 end

    local ensured = EnsureNWindows(math.max(totalSlots, 2))
    if not ensured or #ensured < math.min(totalSlots, 2) then
        C_Timer.After(0.2, function()
            if embedGen == embedOperationGeneration and isEmbedded then self:Embed(parentFrame, layoutConfig) end
        end)
        return
    end

    -- Hide unused extra windows
    for i = totalSlots + 1, #D.tabela_instancias do
        local extra = D.tabela_instancias[i]
        if extra then
            local w = extra.baseframe or extra.widget or extra.__frame
            if w and w.Hide then w:Hide() end
            if extra.ShutDown and extra:IsEnabled() then extra:ShutDown() end
        end
    end

    if D.RaidTables and D.RaidTables.DisableRaidMode then
        for i = 1, math.min(totalSlots, #D.tabela_instancias) do
            local inst = D.tabela_instancias[i]
            if inst then pcall(function() D.RaidTables:DisableRaidMode(inst) end) end
        end
    end

    EnsureMeterGridSizeHook(parentFrame, layoutConfig)

    local maxInst = math.min(totalSlots, 6)
    embedHeavyRefreshSuspended = true
    for i = 1, maxInst do
        local inst = D.tabela_instancias and D.tabela_instancias[i]
        if inst and not inst:IsEnabled() then inst:EnableInstance() end
    end

    for i = 1, maxInst do
        local inst = D.tabela_instancias and D.tabela_instancias[i]
        if inst then
            ApplyWoWSkin(inst)
        end
    end

    LayoutMeterGrid(parentFrame, layoutConfig)
    ReapplyConfigureEmbeddedInstances(layoutConfig)
    embedHeavyRefreshSuspended = false

    local function staggeredLayoutAndConfigure()
        if embedGen ~= embedOperationGeneration then return end
        if not isEmbedded or not currentLayoutConfig then return end
        if InCombatLockdown() then
            if Flux and Flux.Combat then Flux.Combat.Defer("details.layout", staggeredLayoutAndConfigure) end
            return
        end
        embedHeavyRefreshSuspended = true
        LayoutMeterGrid(parentFrame, currentLayoutConfig)
        ReapplyConfigureEmbeddedInstances(currentLayoutConfig)
        embedHeavyRefreshSuspended = false
    end

    C_Timer.After(0, function()
        if embedGen ~= embedOperationGeneration then return end
        staggeredLayoutAndConfigure()
    end)

    if LayoutNeedsExtraPass(layoutConfig) then
        C_Timer.After(0.2, function()
            if embedGen ~= embedOperationGeneration then return end
            staggeredLayoutAndConfigure()
        end)
    end

    C_Timer.After(0.25, function()
        if embedGen ~= embedOperationGeneration then return end
        if not isEmbedded then return end
        for i = 1, maxInst do
            local inst = D.tabela_instancias and D.tabela_instancias[i]
            if inst then ApplyEmbedClickFix(inst) end
        end
    end)

    -- After Details RefreshAfterStartup, only light chrome (not another full grid rebuild).
    local function waitForRefreshAfterStartup(attempt)
        attempt = attempt or 1
        if D.RefreshAfterStartup ~= nil and attempt < 40 then
            C_Timer.After(0.15, function()
                if embedGen ~= embedOperationGeneration then return end
                waitForRefreshAfterStartup(attempt + 1)
            end)
            return
        end
        if embedGen ~= embedOperationGeneration or not isEmbedded then return end
        ScheduleLightChromeRefresh()
    end
    C_Timer.After(0.2, function()
        if embedGen ~= embedOperationGeneration then return end
        waitForRefreshAfterStartup(1)
    end)

    -- Keep reasserting parent/anchors while Details' login Restore*/ChangeSkin storm settles.
    StartContainmentWatchdog(embedGen)
    if FluxBlizzardMeter and FluxBlizzardMeter.Hide then FluxBlizzardMeter:Hide() end
    if Flux and Flux.Startup then Flux.Startup.Mark("optional.Details.embedded") end
    return true
end

--- Deep-copy a preset for modification. Returns table with topSlots, bottomSlots, col fracs.
function FluxDetails:CopyLayoutPreset(presetId)
    presetId = self:GetEffectiveLayoutPresetId(presetId)
    local preset = self.LAYOUT_PRESETS and self.LAYOUT_PRESETS[presetId]
    if not preset then return nil end
    if FluxMeterLayout and FluxMeterLayout.CopyLayout then
        local copy = FluxMeterLayout.CopyLayout(preset)
        copy.id = nil
        copy.name = nil
        return copy
    end
    local copy = { topSlots = {}, bottomSlots = {}, topColFracs = {}, bottomColFracs = {}, topRowFrac = preset.topRowFrac or 0.60 }
    for _, s in ipairs(preset.topSlots or {}) do
        table.insert(copy.topSlots, NormalizeEmbedSlot(s))
    end
    for _, s in ipairs(preset.bottomSlots or {}) do
        table.insert(copy.bottomSlots, NormalizeEmbedSlot(s))
    end
    for i, v in ipairs(preset.topColFracs or {}) do copy.topColFracs[i] = v end
    for i, v in ipairs(preset.bottomColFracs or {}) do copy.bottomColFracs[i] = v end
    return copy
end

function FluxDetails:Hide()
    embedOperationGeneration = embedOperationGeneration + 1
    if not IsDetailsAvailable() then return end
    isEmbedded = false

    if containmentWatchdog then
        containmentWatchdog:Cancel()
        containmentWatchdog = nil
    end
    wipe(embedLayoutByInstId)

    if embeddedParentFrame and embeddedParentFrame.__fluxDetailsSizeLayoutTimer then
        embeddedParentFrame.__fluxDetailsSizeLayoutTimer:Cancel()
        embeddedParentFrame.__fluxDetailsSizeLayoutTimer = nil
    end
    embeddedParentFrame = nil
    
    local D = _G.Details
    if D.tabela_instancias then
        for _, inst in ipairs(D.tabela_instancias) do
            if inst then
                -- Instantly hide baseframe (removes from view immediately)
                local w = inst.baseframe or inst.widget or inst.__frame
                if w and w.Hide then w:Hide() end
                -- Fully shut down (not just hidden - proper cleanup)
                if inst.ShutDown and inst:IsEnabled() then
                    inst:ShutDown()
                end
            end
        end
    end
end

function FluxDetails:IsEmbedded()
    return isEmbedded
end

--- Single post-login coordinator: embed Details into the Flux window when the Meter tab is active,
--- or fully hide/shut down when another tab is active. Waits for Details StartMeUp readiness.
--- @return boolean true if Embed or Hide ran (preconditions met)
function FluxDetails:ApplyPostLoginState()
    if not IsDetailsUIReady() then
        return false
    end
    if not FluxWindowFrame or not FluxWindowFrame.GetFrame or not FluxWindowFrame.GetTabContent then
        return false
    end
    if not FluxWindowFrame:GetTabContent("Meter") then
        return false
    end
    local mainFrame = FluxWindowFrame:GetFrame()
    if not mainFrame then
        return false
    end

    EnsureDetailsMaxWindows()
    EnsureDetailsEventListener()

    local active = FluxWindowFrame.GetActiveTab and FluxWindowFrame:GetActiveTab()
    local layoutConfig = FluxWindowFrame.GetMeterLayoutConfig and FluxWindowFrame:GetMeterLayoutConfig()
    if active == "Meter" then
        self:Embed(mainFrame, layoutConfig or 1)
    else
        self:Hide()
    end
    return true
end

--- Re-run grid positioning + per-instance chrome after SetDisplay (used after resize debounce and layout stabilizers).
function FluxDetails:RefreshEmbeddedLayout()
    if not isEmbedded or not embeddedParentFrame or not currentLayoutConfig then
        return
    end
    if embedHeavyRefreshSuspended then
        return
    end
    embedHeavyRefreshSuspended = true
    local lc = currentLayoutConfig
    local ok, err = pcall(function()
        LayoutMeterGrid(embeddedParentFrame, lc)
        ReapplyConfigureEmbeddedInstances(lc)
    end)
    embedHeavyRefreshSuspended = false
    if not ok and geterrorhandler then
        geterrorhandler()(err)
    end
end

--- Copy column/row fractions from a layout table into the active embed and reflow (no CreateInstance).
function FluxDetails:SyncGeometryFromLayout(layout)
    if not isEmbedded or not embeddedParentFrame or not layout then
        return
    end
    if not currentLayoutConfig then
        return
    end
    local lc = currentLayoutConfig
    lc.topColFracs = {}
    for i, v in ipairs(layout.topColFracs or {}) do
        lc.topColFracs[i] = v
    end
    lc.bottomColFracs = {}
    for i, v in ipairs(layout.bottomColFracs or {}) do
        lc.bottomColFracs[i] = v
    end
    if layout.topRowFrac then
        lc.topRowFrac = layout.topRowFrac
    end
    if embedHeavyRefreshSuspended then
        return
    end
    embedHeavyRefreshSuspended = true
    local ok, err = pcall(function()
        LayoutMeterGrid(embeddedParentFrame, lc)
    end)
    embedHeavyRefreshSuspended = false
    if not ok and geterrorhandler then
        geterrorhandler()(err)
    end
end

--- After user changes meter preset/columns; one delayed light pass is enough (was 5 full layouts).
function FluxDetails:StabilizeAfterLayoutChange()
    if not IsDetailsAvailable() then
        return
    end
    EnsureDetailsSkinHooks()
    local myGen = embedOperationGeneration
    C_Timer.After(0.2, function()
        if myGen ~= embedOperationGeneration or not isEmbedded then return end
        ScheduleLightChromeRefresh()
    end)
end

--- Clear all Details! segment data (all windows). Same as Details:ResetSegmentData().
--- No-op when the player or Details considers combat active (avoids EndCombat side effects mid-fight).
--- @return boolean true if Details ran ResetSegmentData successfully
function FluxDetails:ResetAllDataIfOutOfCombat()
    if InCombatLockdown() then
        return false
    end
    if UnitAffectingCombat and UnitAffectingCombat("player") then
        return false
    end
    local D = _G.Details
    if not D or type(D.ResetSegmentData) ~= "function" then
        return false
    end
    if type(D.IsInCombat) == "function" and D:IsInCombat() then
        return false
    end
    local ok = pcall(function()
        D:ResetSegmentData()
    end)
    return ok == true
end

-- ---------------------------------------------------------------------------
-- Initialization & Profile Management
-- ---------------------------------------------------------------------------

-- Defer post-login embed/hide until Meter tab exists and Details StartMeUp has finished.
-- PLAYER_ENTERING_WORLD fires on login, reload, and every zone change — only run once per session on login/reload.
local postLoginCoordinatorScheduled = false
local COORDINATOR_WAIT_ATTEMPTS = 50 -- ~5s
local COORDINATOR_WAIT_STEP = 0.1
local WIDTH_STABILIZE_ATTEMPTS = 40 -- ~4s
local WIDTH_STABILIZE_STEP = 0.1

local function ScheduleWidthStabilize(attempt)
    attempt = attempt or 1
    if not isEmbedded or not embeddedParentFrame or not currentLayoutConfig then
        return
    end
    local w = embeddedParentFrame.GetWidth and embeddedParentFrame:GetWidth()
    if (w and w >= 80) or attempt >= WIDTH_STABILIZE_ATTEMPTS then
        FluxDetails:RefreshEmbeddedLayout()
        if _G.FluxDetailsWoWSkinTint and FluxDetailsWoWSkinTint.RefreshAllEmbeddedInstances then
            FluxDetailsWoWSkinTint.RefreshAllEmbeddedInstances()
        end
        return
    end
    C_Timer.After(WIDTH_STABILIZE_STEP, function()
        ScheduleWidthStabilize(attempt + 1)
    end)
end

local function SchedulePostLoginCoordinator()
    local function tryReady(attempt)
        attempt = attempt or 1
        local meterTab = FluxWindowFrame and FluxWindowFrame.GetTabContent and FluxWindowFrame:GetTabContent("Meter")
        if meterTab and IsDetailsUIReady() then
            EnsureDetailsEventListener()
            FluxDetails:ApplyPostLoginState()
            if isEmbedded then
                ScheduleWidthStabilize(1)
            end
            return
        end
        if attempt < COORDINATOR_WAIT_ATTEMPTS then
            C_Timer.After(COORDINATOR_WAIT_STEP, function()
                tryReady(attempt + 1)
            end)
        else
            -- Timed out waiting; Meter onShow retries can still Embed once Details is ready.
            if meterTab and IsDetailsAvailable() then
                EnsureDetailsEventListener()
                FluxDetails:ApplyPostLoginState()
                if isEmbedded then
                    ScheduleWidthStabilize(1)
                end
            end
        end
    end
    tryReady(1)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
local initializedProfileFor

local function InitializeDetailsProfile()
    if not IsDetailsAvailable() then return end
    local D = _G.Details
    if initializedProfileFor ~= D then
        if D.CreateProfile then D:CreateProfile(PROFILE_NAME) end
        D.always_use_profile = true
        D.always_use_profile_name = PROFILE_NAME
        D.always_use_profile_exception = {}
        initializedProfileFor = D
        if Flux and Flux.Startup then Flux.Startup.Mark("optional.Details.loaded") end
    end
    if not postLoginCoordinatorScheduled and IsLoggedIn and IsLoggedIn() then
        postLoginCoordinatorScheduled = true
        SchedulePostLoginCoordinator()
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and (arg1 == addonName or arg1 == "Details") then
        -- Let the provider finish its own ADDON_LOADED profile restoration.
        C_Timer.After(0, InitializeDetailsProfile)

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not IsDetailsAvailable() then return end
        local isInitialLogin, isReloadingUI = ...
        local loginOrReload = (isInitialLogin == true) or (isReloadingUI == true)
        if isInitialLogin == nil and isReloadingUI == nil then
            loginOrReload = true
        end
        if not loginOrReload then
            return
        end
        if postLoginCoordinatorScheduled then
            return
        end
        postLoginCoordinatorScheduled = true
        SchedulePostLoginCoordinator()
    end
end)

