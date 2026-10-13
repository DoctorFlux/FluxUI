-- FluxThreat.lua
-- Details! RAID plugin - Standalone threat meter
-- Uses UnitDetailedThreatSituation to gather threat data for group members
-- Registers with Details as a RAID plugin selectable from the plugin menu

local addonName = ...

local detailsFramework = _G.DetailsFramework
if not detailsFramework then return end

local Details = _G.Details
if not Details then return end

local _GetNumSubgroupMembers = GetNumSubgroupMembers
local _GetNumGroupMembers = GetNumGroupMembers
local _UnitIsFriend = UnitIsFriend
local _IsInRaid = IsInRaid
local _IsInGroup = IsInGroup
local _UnitGroupRolesAssigned = detailsFramework.UnitGroupRolesAssigned
local _GetUnitName = GetUnitName
local _UnitDetailedThreatSituation = UnitDetailedThreatSituation
local _UnitExists = UnitExists
local _UnitAffectingCombat = UnitAffectingCombat
local _UnitIsUnit = UnitIsUnit
local _UnitCanAssist = UnitCanAssist
local _UnitReaction = UnitReaction
local _UnitIsPlayer = UnitIsPlayer

local ipairs = ipairs
local table_sort = table.sort
local string_format = string.format
local math_floor = math.floor
local unpack = unpack
local wipe = table.wipe
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local Threat = Details:NewPluginObject("Details_FluxThreat")
Threat.pluginGloballyEnabled = true -- PLUGIN_DISABLED clears; avoids OnUpdate when plugin off
local ThreatFrame = Threat.Frame
-- Also react to host addon load so InstallPlugin can run before PLAYER_LOGIN when Details is ready
ThreatFrame:RegisterEvent("ADDON_LOADED")

Threat:SetPluginDescription(
    "Threat meter showing threat for all group members against your current target. "
    .. "Saved keys: updatespeed (min 0.1s; lower values cost more CPU in large raids), "
    .. "event_led_threat_updates (boolean; rely on UNIT_THREAT_LIST_UPDATE instead of combat polling on primary target)."
)

local function ThreatUnitName(unit, showRealm)
    local PN = _G.Flux and _G.Flux.PlayerName
    if PN and PN.GetDisplayName then
        return PN.GetDisplayName(unit, showRealm)
    end
    return _GetUnitName(unit, showRealm)
end

local function NumFormat(v)
    if v > 1e10 then
        return math_floor(v / 1e9) .. "b"
    elseif v > 1e9 then
        return (math_floor(v / 1e9 * 10) / 10) .. "b"
    elseif v > 1e7 then
        return math_floor(v / 1e6) .. "m"
    elseif v > 1e6 then
        return (math_floor(v / 1e6 * 10) / 10) .. "m"
    elseif v > 1e4 then
        return math_floor(v / 1e3) .. "k"
    elseif v > 1e3 then
        return (math_floor(v / 1e3 * 10) / 10) .. "k"
    else
        return tostring(math_floor(v))
    end
end

-- Match FluxUI Details embed: compact right text, pipe-separated (use "||" = one visible "|" in FontStrings).
-- Whole-number percent (same style as 4-panel Details instances).
local function FormatThreatRightText(threatVal, threatPct)
    local p = math_floor(threatPct + 0.5)
    if p < 0 then p = 0 elseif p > 100 then p = 100 end
    return NumFormat(threatVal) .. "||" .. tostring(p) .. "%"
end

-- ---------------------------------------------------------------------------
-- Threat host unit token (mirrors ThreatClassic2 UpdatePlayerTarget)
-- ---------------------------------------------------------------------------
local function GetThreatTarget()
    if _UnitExists("target") and (not _UnitIsFriend("player", "target")
        or ((_UnitReaction("player", "target") or 0) <= 4 and not _UnitCanAssist("player", "target"))) then
        return "target"
    elseif _UnitExists("targettarget") and (not _UnitIsFriend("player", "targettarget")
        or ((_UnitReaction("player", "targettarget") or 0) <= 4 and not _UnitCanAssist("player", "targettarget"))) then
        return "targettarget"
    end
    return "target"
end

-- ---------------------------------------------------------------------------
-- Plugin frames and state (created inside CreatePluginFrames closure)
-- ---------------------------------------------------------------------------
local function CreatePluginFrames()
    local _detalhes = _G.Details
    local DetailsFrameWork = _detalhes.gump

    Threat.RowWidth = 294
    -- Default until attached; FluxDetails embed sets host instance row height to 21 (1.5x) for threat panel.
    Threat.RowHeight = 14
    Threat.CanShow = 0
    Threat.Rows = {}
    Threat.ShownRows = {}
    Threat.Active = false
    Threat.threatData = {}
    Threat.playerName = ""

    Threat.player_list_indexes = {}
    Threat.player_list_hash = {}

    local instance
    local playerName

    local lastThreatPollTime = 0
    local threatPollDeferred = false

    -- -------------------------------------------------------------------
    -- OnDetailsEvent
    -- -------------------------------------------------------------------
    local function SyncThreatToInstanceFrame(inst)
        inst = inst or Threat:GetPluginInstance()
        if not inst or not inst.baseframe then return end
        local bw = inst.baseframe:GetWidth()
        if bw and bw > 1 then
            Threat.RowWidth = bw - 6
        end
        Threat:UpdateContainers()
        Threat:UpdateRowWidths()
        Threat:SizeChanged()
        Threat:RefreshRows()
    end

    function Threat:OnDetailsEvent(event, ...)
        if event == "HIDE" then
            Threat.Active = false
            Threat:Cancel()

        elseif event == "SHOW" then
            instance = Threat:GetInstance(Threat.instance_id)
            SyncThreatToInstanceFrame(instance)

            -- Embed layout resizes baseframe after SHOW; Details may not emit INSTANCE_SIZECHANGED for that.
            if instance and instance.baseframe and not instance.baseframe.__FluxThreatEmbedSizeHook then
                instance.baseframe.__FluxThreatEmbedSizeHook = true
                instance.baseframe:HookScript("OnSizeChanged", function()
                    SyncThreatToInstanceFrame()
                end)
            end

            playerName = ThreatUnitName("player", true)
            Threat.playerName = playerName

            Threat.Active = false
            if Threat:IsInCombat() or _UnitAffectingCombat("player") then
                if Threat.initialized then
                    Threat.Active = true
                    Threat:Start()
                end
            end
            if Threat.SyncThreatPollingScript then Threat:SyncThreatPollingScript() end

        elseif event == "COMBAT_PLAYER_ENTER" then
            if not Threat.Active then
                Threat.Active = true
                Threat:Start()
            end
            if Threat.SyncThreatPollingScript then Threat:SyncThreatPollingScript() end

        elseif event == "DETAILS_INSTANCE_ENDRESIZE" or event == "DETAILS_INSTANCE_SIZECHANGED" then
            local what_window = select(1, ...)
            if what_window == instance then
                Threat:SizeChanged()
                Threat:RefreshRows()
            end

        elseif event == "DETAILS_OPTIONS_MODIFIED" then
            local what_window = select(1, ...)
            if what_window == instance then
                Threat:RefreshRows()
                if Threat.SyncThreatPollingScript then Threat:SyncThreatPollingScript() end
            end

        elseif event == "DETAILS_INSTANCE_STARTSTRETCH" then
            ThreatFrame:SetFrameStrata("TOOLTIP")
            ThreatFrame:SetFrameLevel(instance.baseframe:GetFrameLevel() + 1)

        elseif event == "DETAILS_INSTANCE_ENDSTRETCH" then
            ThreatFrame:SetFrameStrata("MEDIUM")

        elseif event == "PLUGIN_DISABLED" then
            Threat.pluginGloballyEnabled = false
            ThreatFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
            ThreatFrame:UnregisterEvent("PLAYER_REGEN_DISABLED")
            ThreatFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
            ThreatFrame:UnregisterEvent("UNIT_THREAT_LIST_UPDATE")
            ThreatFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")
            ThreatFrame:UnregisterEvent("UNIT_TARGET")
            if Threat.SyncThreatPollingScript then Threat:SyncThreatPollingScript() end

        elseif event == "PLUGIN_ENABLED" then
            Threat.pluginGloballyEnabled = true
            ThreatFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
            ThreatFrame:RegisterUnitEvent("UNIT_TARGET", "target")
            ThreatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
            ThreatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            if Threat.Active then
                Threat:SetCombatListEvents(true)
            end
            if Threat.SyncThreatPollingScript then Threat:SyncThreatPollingScript() end
        end
    end

    ThreatFrame:SetWidth(300)
    ThreatFrame:SetHeight(100)

    -- -------------------------------------------------------------------
    -- Row helpers
    -- -------------------------------------------------------------------
    function Threat:UpdateContainers()
        for _, row in ipairs(Threat.Rows) do
            row:SetContainer(instance.baseframe)
        end
    end

    function Threat:UpdateRowWidths()
        for _, row in ipairs(Threat.Rows) do
            row.width = Threat.RowWidth
        end
    end

    function Threat:HideBars()
        for _, row in ipairs(Threat.Rows) do
            row:Hide()
        end
    end

    local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")

    local function resolveForegroundTextureFile(ri)
        local f = ri.texture_file
        if type(f) == "string" and f ~= "" then
            return f
        end
        local t = ri.texture
        if type(t) == "string" and t ~= "" then
            return SharedMedia:Fetch("statusbar", t)
        end
        return nil
    end

    local function resolveBackgroundTextureFile(ri)
        local f = ri.texture_background_file
        if type(f) == "string" and f ~= "" then
            return f
        end
        local t = ri.texture_background
        if type(t) == "string" and t ~= "" then
            return SharedMedia:Fetch("statusbar", t)
        end
        return nil
    end

    local function applyTexturesFromRowInfo(row, inst)
        local ri = inst.row_info
        local fg = resolveForegroundTextureFile(ri)
        if fg and type(fg) == "string" and fg ~= "" then
            row._texture:SetTexture(fg)
            if row.timer_texture then
                row.timer_texture:SetTexture(fg)
            end
            if row.timer_textureR then
                row.timer_textureR:SetTexture(fg)
            end
        end

        local bg = resolveBackgroundTextureFile(ri)
        if bg and type(bg) == "string" and bg ~= "" then
            row.background:SetTexture(bg)
            row.background:Show()
            local c = ri.fixed_texture_background_color
            if c and not ri.texture_background_class_color then
                row.background:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
            end
        else
            row.background:Hide()
        end
    end

    local function classBarRgb(data)
        local class = data.class
        if class and _detalhes.class_colors and _detalhes.class_colors[class] then
            local c = _detalhes.class_colors[class]
            return c[1], c[2], c[3]
        end
        local rc = class and RAID_CLASS_COLORS[class]
        if rc then
            return rc.r, rc.g, rc.b
        end
        return 0.5, 0.5, 0.5
    end

    local function isPetUnitId(unitId)
        if type(unitId) ~= "string" then return false end
        if unitId == "pet" then return true end
        return unitId:match("^partypet%d+$") ~= nil or unitId:match("^raidpet%d+$") ~= nil
    end

    local function SetThreatUnitIcon(tex, inst, unitId, classToken)
        if not tex or not inst or not unitId or not _UnitExists(unitId) then return end
        local ri = inst.row_info
        local iconH = ri.flux_threat_icon_base_height or ri.height or 14
        local iconSize = iconH + (ri.icon_size_offset or 0)
        tex:SetSize(iconSize, iconSize)
        tex:SetVertexColor(1, 1, 1)

        if isPetUnitId(unitId) then
            tex:SetTexture(ri.icon_file or [[Interface\AddOns\Details\images\classes_small]])
            local petCoords = _detalhes.class_coords and _detalhes.class_coords["PET"]
            if petCoords then
                tex:SetTexCoord(unpack(petCoords))
            end
            return
        end

        local class = classToken
        if not class or class == "" then
            _, class = UnitClass(unitId)
        end
        class = class or "UNKNOW"

        if ri.use_spec_icons and _UnitIsPlayer(unitId) and _UnitIsUnit(unitId, "player") and GetSpecialization then
            local ok, specIndex = pcall(GetSpecialization)
            if ok and specIndex and specIndex > 0 and GetSpecializationInfo then
                local ok2, specID = pcall(function()
                    return select(1, GetSpecializationInfo(specIndex))
                end)
                if ok2 and specID and _detalhes.class_specs_coords and _detalhes.class_specs_coords[specID] then
                    tex:SetTexture(ri.spec_file or [[Interface\AddOns\Details\images\spec_icons_normal]])
                    tex:SetTexCoord(unpack(_detalhes.class_specs_coords[specID]))
                    return
                end
            end
        end

        local coords = (_detalhes.class_coords and _detalhes.class_coords[class])
            or (_detalhes.class_coords and _detalhes.class_coords["UNKNOW"])
        tex:SetTexture(ri.icon_file or [[Interface\AddOns\Details\images\classes_small]])
        if coords then
            tex:SetTexCoord(unpack(coords))
        end
    end

    local function threatRankForUnit(threatList, unitId)
        for idx, d in ipairs(threatList) do
            if _UnitIsUnit(d.unit, unitId) then
                return idx
            end
        end
        return nil
    end

    local function applyRowColorsAndText(row, inst, data, barAlpha, textAlpha)
        barAlpha = barAlpha or 1
        textAlpha = textAlpha or 1
        local ri = inst.row_info

        local r, g, b, a
        if ri.texture_class_colors then
            r, g, b = classBarRgb(data)
            a = barAlpha
        else
            local fc = ri.fixed_texture_color
            r, g, b = fc[1], fc[2], fc[3]
            a = (fc[4] or 1) * barAlpha
        end
        row:SetColor(r, g, b, a)

        if row.background:IsShown() then
            if ri.texture_background_class_color then
                row.background:SetVertexColor(r, g, b, a)
            else
                local bc = ri.fixed_texture_background_color
                if bc then
                    row.background:SetVertexColor(bc[1], bc[2], bc[3], (bc[4] or 1) * barAlpha)
                end
            end
        end

        local ftc = ri.fixed_text_color
        local flR, flG, flB, flA
        if ri.textL_class_colors and data.class and _detalhes.class_colors and _detalhes.class_colors[data.class] then
            flR, flG, flB = unpack(_detalhes.class_colors[data.class])
            flA = textAlpha
        else
            flR, flG, flB, flA = ftc[1], ftc[2], ftc[3], ftc[4] or 1
            flA = flA * textAlpha
        end
        row.textleft:SetTextColor(flR, flG, flB, flA)

        local frR, frG, frB, frA
        if ri.textR_class_colors and data.class and _detalhes.class_colors and _detalhes.class_colors[data.class] then
            frR, frG, frB = unpack(_detalhes.class_colors[data.class])
            frA = textAlpha
        else
            frR, frG, frB, frA = ftc[1], ftc[2], ftc[3], ftc[4] or 1
            frA = frA * textAlpha
        end
        row.textright:SetTextColor(frR, frG, frB, frA)
    end

    local function MaybeGreenPlayerLeftName(row, data, textAlpha)
        textAlpha = textAlpha or 1
        if not row or not row.textleft or not data or not data.unit then return end
        if not _UnitIsUnit(data.unit, "player") then return end
        local c = GREEN_FONT_COLOR
        row.textleft:SetTextColor(c.r, c.g, c.b, textAlpha)
    end

    function Threat:SizeChanged()
        local inst = Threat:GetPluginInstance()
        if not inst then return end

        local w, h = inst:GetSize()
        ThreatFrame:SetWidth(w)
        ThreatFrame:SetHeight(h)
        Threat.RowHeight = inst.row_info.height
        Threat.CanShow = math_floor(h / (inst.row_info.height + 1))

        for i = #Threat.Rows + 1, Threat.CanShow do
            Threat:NewRow(i)
        end

        Threat.ShownRows = {}
        for i = 1, Threat.CanShow do
            Threat.ShownRows[i] = Threat.Rows[i]
            if _detalhes.in_combat then
                Threat.Rows[i]:Show()
            end
            Threat.Rows[i].width = w - 5
        end

        for i = #Threat.ShownRows + 1, #Threat.Rows do
            Threat.Rows[i]:Hide()
        end
    end

    function Threat:RefreshRow(row)
        local inst = Threat:GetPluginInstance()
        if not inst then return end

        local font = SharedMedia:Fetch("font", inst.row_info.font_face, true) or inst.row_info.font_face
        row.textsize = inst.row_info.font_size
        row.textfont = font

        applyTexturesFromRowInfo(row, inst)

        row.shadow = inst.row_info.textL_outline

        row.width = inst.baseframe:GetWidth() - 5
        row.height = inst.row_info.height

        local rowHeight = -((row.rowId - 1) * (inst.row_info.height + 1))
        row:ClearAllPoints()
        row:SetPoint("topleft", ThreatFrame, "topleft", 1, rowHeight)
        row:SetPoint("topright", ThreatFrame, "topright", -1, rowHeight)
    end

    function Threat:RefreshRows()
        for i = 1, #Threat.Rows do
            Threat:RefreshRow(Threat.Rows[i])
        end
    end

    function Threat:NewRow(i)
        local newrow = DetailsFrameWork:NewBar(ThreatFrame, nil, "FluxThreatRow" .. i, nil, 300, Threat.RowHeight)
        newrow:SetPoint(3, -((i - 1) * (Threat.RowHeight + 1)))
        newrow.lefttext = ""
        newrow.rowId = i
        Threat.Rows[#Threat.Rows + 1] = newrow

        Threat:RefreshRow(newrow)
        newrow:Hide()
        return newrow
    end

    -- -------------------------------------------------------------------
    -- Threat data gathering
    -- -------------------------------------------------------------------
    local function GatherUnitThreat(unitId, targetUnit)
        if not _UnitExists(unitId) then return end

        local FluxThreat = _G.Flux and _G.Flux.Threat
        if FluxThreat and FluxThreat.GetMeterRow then
            local row = FluxThreat.GetMeterRow(unitId, targetUnit)
            if not row then return end
            local name = ThreatUnitName(unitId, true) or UNKNOWN
            local _, class = UnitClass(unitId)
            local role = _UnitGroupRolesAssigned(unitId) or "NONE"
            Threat.threatData[#Threat.threatData + 1] = {
                name       = name,
                unit       = unitId,
                class      = class,
                role       = role,
                threatPct  = row.threatPct or 0,
                rawPct     = row.rawPct or 0,
                threatVal  = row.threatVal or 0,
                isTanking  = row.isTanking or false,
            }
            return
        end

        local isTanking, _, threatPct, rawThreatPct, threatValue = _UnitDetailedThreatSituation(unitId, targetUnit)
        if not threatValue then return end
        if issecretvalue and (issecretvalue(threatValue) or issecretvalue(threatPct)) then
            return
        end

        -- Blizzard API uses ~100 threat per 1 damage; ThreatClassic2 divides by default ("Scale threat values").
        -- Midnight / Forever do not downscale.
        local downscale = Threat.saveddata.downscale_threat
        if FluxThreat and FluxThreat.ShouldDownscaleValues then
            downscale = downscale and FluxThreat.ShouldDownscaleValues()
        end
        if threatValue and downscale then
            threatValue = math_floor(threatValue / 100)
        end

        if isTanking then
            rawThreatPct = 100
            threatPct = 100
        end

        local name = ThreatUnitName(unitId, true) or UNKNOWN
        local _, class = UnitClass(unitId)
        local role = _UnitGroupRolesAssigned(unitId) or "NONE"

        Threat.threatData[#Threat.threatData + 1] = {
            name       = name,
            unit       = unitId,
            class      = class,
            role       = role,
            threatPct  = threatPct or 0,
            rawPct     = rawThreatPct or 0,
            threatVal  = threatValue or 0,
            isTanking  = isTanking or false,
        }
    end

    local function GatherAllThreat(targetUnit)
        wipe(Threat.threatData)

        if _IsInRaid() then
            for i = 1, _GetNumGroupMembers() do
                GatherUnitThreat("raid" .. i, targetUnit)
            end
        elseif _IsInGroup() then
            for i = 1, _GetNumSubgroupMembers() do
                GatherUnitThreat("party" .. i, targetUnit)
            end
            GatherUnitThreat("player", targetUnit)
            if _UnitExists("pet") then
                GatherUnitThreat("pet", targetUnit)
            end
        else
            GatherUnitThreat("player", targetUnit)
            if _UnitExists("pet") then
                GatherUnitThreat("pet", targetUnit)
            end
        end

        local client = _G.Flux and _G.Flux.Client
        local forever = client and (client.isCamelot or client.isForever)
        if not forever then
            table_sort(Threat.threatData, function(a, b)
                return a.threatPct > b.threatPct
            end)
            return
        end

        for i = 1, #Threat.threatData do
            Threat.threatData[i]._order = i
        end
        local FT = _G.Flux and _G.Flux.Threat
        local function sortKey(row)
            if not FT or not FT.AccessibleNumber then
                return nil
            end
            return FT.AccessibleNumber(row.threatPct) or FT.AccessibleNumber(row.threatVal)
        end
        table_sort(Threat.threatData, function(a, b)
            local function plainTank(row)
                local flag = row and row.isTanking
                if issecretvalue and issecretvalue(flag) then
                    return false
                end
                return flag and true or false
            end
            local aTank, bTank = plainTank(a), plainTank(b)
            if aTank ~= bTank then
                return aTank and not bTank
            end
            local ak, bk = sortKey(a), sortKey(b)
            if ak ~= nil and bk ~= nil and ak ~= bk then
                return ak > bk
            end
            if ak ~= nil and bk == nil then
                return true
            end
            if ak == nil and bk ~= nil then
                return false
            end
            return (a._order or 0) < (b._order or 0)
        end)
    end

    local function IsForeverThreatClient()
        local client = _G.Flux and _G.Flux.Client
        return client and (client.isCamelot or client.isForever) and true or false
    end

    local function RowHasThreat(data)
        if not data then
            return false
        end
        if data.isTanking or data.secret then
            local FT = _G.Flux and _G.Flux.Threat
            if FT and FT.ShouldShowThreat then
                return FT.ShouldShowThreat(data.threatPct, data.isTanking)
            end
            return true
        end
        local FT = _G.Flux and _G.Flux.Threat
        if FT and FT.HasNonZeroDisplay then
            return (FT.HasNonZeroDisplay(data.threatPct) or FT.HasNonZeroDisplay(data.threatVal)) and true or false
        end
        return (data.threatVal or 0) > 0
    end

    local function AnyRowHasThreat()
        if IsForeverThreatClient() then
            for i = 1, #Threat.threatData do
                if RowHasThreat(Threat.threatData[i]) then
                    return true
                end
            end
            return false
        end
        local top = Threat.threatData[1]
        if not top then
            return false
        end
        if top.threatPct < 0.1 and top.threatVal == 0 then
            return false
        end
        return true
    end

    -- Forever rows may hold secret numbers. Paint those with SetFormattedText / SetBarValue.
    -- Plain Forever numbers keep lead % above 100 in the text; the bar stays 0–100.
    local function PaintThreatRow(row, data)
        local FT = _G.Flux and _G.Flux.Threat
        local forever = IsForeverThreatClient()
        local secret = data.secret
        if not secret and forever and FT and FT.AccessibleNumber and data.threatPct ~= nil then
            secret = FT.AccessibleNumber(data.threatPct) == nil
        end
        if secret then
            local bar = row.statusbar or row
            if FT and FT.SetBarValue then
                FT.SetBarValue(bar, data.threatPct, data.isTanking)
            else
                pcall(bar.SetValue, bar, data.threatPct or 0)
            end
            local fs = row.textright
            if fs and fs.SetFormattedText then
                local ok = pcall(fs.SetFormattedText, fs, "%.0f||%.0f%%", data.threatVal or 0, data.threatPct or 0)
                if not ok then
                    ok = pcall(fs.SetFormattedText, fs, "%s||%s%%", data.threatVal or "", data.threatPct or "")
                end
                if not ok and FT and FT.SetPercentText then
                    FT.SetPercentText(fs, data.threatPct)
                end
            elseif fs and FT and FT.SetPercentText then
                FT.SetPercentText(fs, data.threatPct)
            end
            return
        end
        if forever then
            local pct = data.threatPct or 0
            local p = math_floor(pct + 0.5)
            if p < 0 then
                p = 0
            end
            row:SetRightText(NumFormat(data.threatVal or 0) .. "||" .. tostring(p) .. "%")
            local fill = pct
            if data.isTanking or fill > 100 then
                fill = 100
            elseif fill < 0 then
                fill = 0
            end
            row:SetValue(fill)
            return
        end
        row:SetRightText(FormatThreatRightText(data.threatVal, data.threatPct))
        row:SetValue(data.threatPct)
    end

    -- -------------------------------------------------------------------
    -- Display update
    -- -------------------------------------------------------------------
    local function UpdateDisplay()
        if not Threat.Active then return end

        local inst = Threat:GetPluginInstance()
        if not inst then return end

        local targetUnit = GetThreatTarget()
        if not _UnitExists(targetUnit) then
            Threat:HideBars()
            return
        end
        if IsForeverThreatClient() then
            local FT = _G.Flux and _G.Flux.Threat
            if FT and FT.IsExcludedThreatUnit and FT.IsExcludedThreatUnit(targetUnit) then
                Threat:HideBars()
                return
            end
        end

        GatherAllThreat(targetUnit)

        if #Threat.threatData == 0 or not AnyRowHasThreat() then
            Threat:HideBars()
            return
        end

        local lastIndex = #Threat.ShownRows
        local shownMe = false
        local showClassSpecIcons = Threat.saveddata.show_class_spec_icons ~= false

        for i = 1, lastIndex do
            local row = Threat.ShownRows[i]
            local data = Threat.threatData[i]

            if data and (IsForeverThreatClient() and RowHasThreat(data) or (not IsForeverThreatClient() and data.threatVal > 0)) then
                if showClassSpecIcons then
                    row._icon:Show()
                    SetThreatUnitIcon(row._icon, inst, data.unit, data.class)
                else
                    row._icon:Hide()
                end

                row:SetLeftText(string_format("%d. %s", i, Threat:GetOnlyName(data.name)))
                PaintThreatRow(row, data)

                applyRowColorsAndText(row, inst, data, 1, 1)
                MaybeGreenPlayerLeftName(row, data, 1)

                if not row.statusbar:IsShown() then
                    row:Show()
                end

                if _UnitIsUnit(data.unit, "player") then
                    shownMe = true
                end
            else
                row:Hide()
            end
        end

        if not shownMe then
            for _, data in ipairs(Threat.threatData) do
                if _UnitIsUnit(data.unit, "player") and (IsForeverThreatClient() and RowHasThreat(data) or (not IsForeverThreatClient() and data.threatVal > 0)) then
                    local row = Threat.ShownRows[lastIndex]
                    if row then
                        local prank = threatRankForUnit(Threat.threatData, "player") or 0
                        if showClassSpecIcons then
                            row._icon:Show()
                            SetThreatUnitIcon(row._icon, inst, data.unit, data.class)
                        else
                            row._icon:Hide()
                        end

                        row:SetLeftText(string_format("%d. %s", prank, playerName or Threat.playerName))
                        PaintThreatRow(row, data)

                        applyRowColorsAndText(row, inst, data, 0.5, 0.5)
                        MaybeGreenPlayerLeftName(row, data, 0.5)

                        row:Show()
                    end
                    break
                end
            end
        end
    end

    -- -------------------------------------------------------------------
    -- Timer / lifecycle
    -- -------------------------------------------------------------------
    function Threat:TargetChanged()
        if not Threat.Active then return end
        threatPollDeferred = true
        lastThreatPollTime = 0
        UpdateDisplay()
    end

    function Threat:Start()
        Threat:HideBars()
        threatPollDeferred = true
        lastThreatPollTime = 0
    end

    function Threat:Stop()
        Threat:HideBars()
    end

    function Threat:Cancel()
        Threat:HideBars()
        Threat.Active = false
        if Threat.SyncThreatPollingScript then
            Threat:SyncThreatPollingScript()
        end
    end

    function Threat:OnThreatListOrRosterEvent(event, unitTarget)
        if not Threat.Active then return end
        if event == "UNIT_THREAT_LIST_UPDATE" then
            if unitTarget == GetThreatTarget() then
                threatPollDeferred = false
                lastThreatPollTime = GetTime()
                UpdateDisplay()
            end
        elseif event == "GROUP_ROSTER_UPDATE" then
            threatPollDeferred = false
            lastThreatPollTime = GetTime()
            UpdateDisplay()
        end
    end

    -- TC2-style: UNIT_THREAT_LIST_UPDATE sets deferred for instant path; OnUpdate polls at updatespeed
    -- while in combat (or always for targettarget) so the list stays current between API events.
    -- Minimum interval 0.1s: sub-100ms full raid scans are very expensive.
    local function ThreatFrame_OnUpdate()
        if not Threat.Active then return end
        if not ThreatFrame:IsVisible() then return end
        if not Threat:GetPluginInstance() then return end

        local now = GetTime()
        local freq = Threat.options.updatespeed or 0.2
        if freq < 0.1 then freq = 0.1 end
        if freq > 2 then freq = 2 end

        local targetUnit = GetThreatTarget()
        local needTargetTargetPoll = targetUnit == "targettarget" and _UnitAffectingCombat("player")
        local inCombat = _UnitAffectingCombat("player")
        local eventLed = Threat.saveddata.event_led_threat_updates == true

        if now < lastThreatPollTime + freq then
            return
        end

        local needPollReason = threatPollDeferred or needTargetTargetPoll
        if eventLed then
            if not needPollReason then
                return
            end
        else
            if not needPollReason and not inCombat then
                return
            end
        end

        lastThreatPollTime = now
        threatPollDeferred = false
        UpdateDisplay()
    end

    local function syncThreatPollingScript()
        if not Threat.pluginGloballyEnabled then
            ThreatFrame:SetScript("OnUpdate", nil)
            return
        end
        if Threat.Active then
            ThreatFrame:SetScript("OnUpdate", ThreatFrame_OnUpdate)
        else
            ThreatFrame:SetScript("OnUpdate", nil)
        end
    end

    function Threat:SyncThreatPollingScript()
        syncThreatPollingScript()
    end

    syncThreatPollingScript()
end

function Threat:SetCombatListEvents(enabled)
    if not ThreatFrame then
        return
    end
    if enabled then
        ThreatFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
        ThreatFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    else
        ThreatFrame:UnregisterEvent("UNIT_THREAT_LIST_UPDATE")
        ThreatFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")
    end
end

-- ---------------------------------------------------------------------------
-- WoW Event Handler
-- ---------------------------------------------------------------------------
function Threat:OnEvent(_, event, ...)
    if event == "PLAYER_TARGET_CHANGED" or event == "UNIT_TARGET" then
        Threat:TargetChanged()

    elseif event == "PLAYER_REGEN_DISABLED" then
        Threat.Active = true
        Threat:SetCombatListEvents(true)
        Threat:Start()
        Threat:TargetChanged()
        if Threat.SyncThreatPollingScript then Threat:SyncThreatPollingScript() end

    elseif event == "PLAYER_REGEN_ENABLED" then
        Threat:Stop()
        Threat.Active = false
        Threat:SetCombatListEvents(false)
        if Threat.SyncThreatPollingScript then Threat:SyncThreatPollingScript() end

    elseif event == "UNIT_THREAT_LIST_UPDATE" then
        local unitTarget = ...
        if Threat.OnThreatListOrRosterEvent then
            Threat:OnThreatListOrRosterEvent(event, unitTarget)
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        if Threat.OnThreatListOrRosterEvent then
            Threat:OnThreatListOrRosterEvent(event)
        end

    elseif event == "ADDON_LOADED" then
        local loadedAddon = select(1, ...)
        -- Synthetic name from Details at PLAYER_LOGIN, or real load of this file's addon (_FluxUI)
        if loadedAddon ~= "Details_FluxThreat" and loadedAddon ~= addonName then
            return
        end
        if Threat.initialized then
            return
        end
        if not _G.Details then
            return
        end

        CreatePluginFrames()

        local MINIMAL_DETAILS_VERSION_REQUIRED = 1
        local install, saveddata = _G.Details:InstallPlugin(
            "RAID",
            "Threat",
            "Interface\\Icons\\Ability_Druid_Cower",
            Threat,
            "DETAILS_PLUGIN_FLUX_THREAT",
            MINIMAL_DETAILS_VERSION_REQUIRED,
            "FluxUI",
            "v1.0"
        )

        if type(install) == "table" and install.error then
            print(install.error)
        end

        _G.Details:RegisterEvent(Threat, "COMBAT_PLAYER_ENTER")
        _G.Details:RegisterEvent(Threat, "COMBAT_PLAYER_LEAVE")
        _G.Details:RegisterEvent(Threat, "DETAILS_INSTANCE_ENDRESIZE")
        _G.Details:RegisterEvent(Threat, "DETAILS_INSTANCE_SIZECHANGED")
        _G.Details:RegisterEvent(Threat, "DETAILS_INSTANCE_STARTSTRETCH")
        _G.Details:RegisterEvent(Threat, "DETAILS_INSTANCE_ENDSTRETCH")
        _G.Details:RegisterEvent(Threat, "DETAILS_OPTIONS_MODIFIED")

        ThreatFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        ThreatFrame:RegisterUnitEvent("UNIT_TARGET", "target")
        ThreatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        ThreatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        if Threat.Active then
            Threat:SetCombatListEvents(true)
        end

        Threat.saveddata = saveddata or {}
        Threat.saveddata.updatespeed = Threat.saveddata.updatespeed or 0.2
        -- Flux perf T2.11: clamp updatespeed to >= 0.2s. The per-tick pass walks
        -- the raid/party plus UnitDetailedThreatSituation for every unit and
        -- feeds the InstanceRefreshRows sort; faster than 5Hz offers no visible
        -- benefit in normal gameplay and noticeably loads the CPU in 20-man+
        -- content.
        if Threat.saveddata.updatespeed < 0.2 then
            Threat.saveddata.updatespeed = 0.2
        end
        Threat.saveddata.useclasscolors = (Threat.saveddata.useclasscolors ~= false)
        Threat.saveddata.show_class_spec_icons = Threat.saveddata.show_class_spec_icons ~= false
        -- Match TC2 default: show "human" threat (1 damage ≈ 1 threat before modifiers).
        Threat.saveddata.downscale_threat = (Threat.saveddata.downscale_threat ~= false)
        -- Flux perf T2.11: default event-led threat updates ON. Blizzard fires
        -- UNIT_THREAT_LIST_UPDATE whenever the primary target's threat table
        -- changes; the old constant OnUpdate poll was redundant for the
        -- primary target and produced sustained combat CPU. Target-of-target
        -- still polls for its gap-fill window inside SyncThreatPollingScript.
        if Threat.saveddata.event_led_threat_updates == nil then
            Threat.saveddata.event_led_threat_updates = true
        else
            Threat.saveddata.event_led_threat_updates = Threat.saveddata.event_led_threat_updates == true
        end
        Threat.options = Threat.saveddata

        Threat.initialized = true
        if Threat.SyncThreatPollingScript then Threat:SyncThreatPollingScript() end
    end
end

