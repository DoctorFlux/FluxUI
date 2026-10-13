-- FluxChatFrame.lua
-- Automatic chat frame positioning, sizing, and configuration on first login per character.
-- Supports: Classic Era (no Edit Mode), Classic Anniversary (Edit Mode), Retail/Live (post-DF).

local addonName, ns = ...

-- ---------------------------------------------------------------------------
-- CROSS-VERSION HELPERS
-- ---------------------------------------------------------------------------

local function SafeAddMessageGroup(frame, group)
    if frame.AddMessageGroup then
        frame:AddMessageGroup(group)
    elseif ChatFrame_AddMessageGroup then
        ChatFrame_AddMessageGroup(frame, group)
    end
end

local function SafeRemoveMessageGroup(frame, group)
    if frame.RemoveMessageGroup then
        frame:RemoveMessageGroup(group)
    elseif ChatFrame_RemoveMessageGroup then
        ChatFrame_RemoveMessageGroup(frame, group)
    end
end

local function SafeAddChannel(frame, channel)
    if frame.AddChannel then
        frame:AddChannel(channel)
    elseif ChatFrame_AddChannel then
        ChatFrame_AddChannel(frame, channel)
    else
        local id = frame:GetID()
        if AddChatWindowChannel then
            AddChatWindowChannel(id, channel)
        end
    end
end

local function SafeRemoveChannel(frame, channel)
    if frame.RemoveChannel then
        frame:RemoveChannel(channel)
    elseif ChatFrame_RemoveChannel then
        ChatFrame_RemoveChannel(frame, channel)
    else
        local id = frame:GetID()
        if RemoveChatWindowChannel then
            RemoveChatWindowChannel(id, channel)
        end
    end
end

-- ---------------------------------------------------------------------------
-- CONFIGURATION CONSTANTS
-- ---------------------------------------------------------------------------

local FONT_SIZE = 14

local GLOBAL_CHANNELS = {
    "General",
    "Trade",
    "LocalDefense",
    "LookingForGroup",
    "WorldDefense",
    "GuildRecruitment",
    "Services",
    "NewcomerChat",
}

local CHAT_MESSAGE_GROUPS = {
    "SAY", "EMOTE", "YELL",
    "PARTY", "PARTY_LEADER",
    "RAID", "RAID_LEADER", "RAID_WARNING",
    "GUILD", "OFFICER",
    "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER",
}

local ALL_CLASS_COLOR_TYPES = {
    "SAY", "EMOTE", "YELL", "WHISPER",
    "PARTY", "PARTY_LEADER",
    "RAID", "RAID_LEADER",
    "GUILD", "OFFICER",
    "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER",
    "CHANNEL",
}

-- ---------------------------------------------------------------------------
-- GLOBAL CHAT CHANNELS (post-DF uses GetChannelList identifiers)
-- ---------------------------------------------------------------------------

local function EnableChannelOnFrame(frame, channelName)
    if not frame or not channelName then return end
    if frame.SetChannelEnabled then
        pcall(function()
            frame:SetChannelEnabled(channelName, true)
        end)
        return
    end
    SafeAddChannel(frame, channelName)
    local id = frame:GetID()
    if AddChatWindowChannel then
        pcall(AddChatWindowChannel, id, channelName)
    end
end

--- Remove/disable a channel from a chat frame. Pre-DF: uses RemoveChannel + RemoveChatWindowChannel.
local function SafeDisableChannelOnFrame(frame, channelName)
    if not frame or not channelName then return end
    if frame.SetChannelEnabled then
        pcall(function()
            frame:SetChannelEnabled(channelName, false)
        end)
        return
    end
    SafeRemoveChannel(frame, channelName)
    local id = frame:GetID()
    if RemoveChatWindowChannel then
        pcall(RemoveChatWindowChannel, id, channelName)
    end
end

local fluxGlobalChatFrame = nil

local function SecureCallBlizzard(func, ...)
    if not func then
        return
    end
    if securecall then
        return securecall(func, ...)
    end
    return func(...)
end

local function FindGlobalChatFrame()
    for i = 3, 10 do
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab and tab.GetText and tab:GetText() == "Global Chat" then
            return _G["ChatFrame" .. i]
        end
    end
    return nil
end

local function EnsureGlobalChatFrame()
    local f = FindGlobalChatFrame()
    if f then
        return f
    end
    if not FCF_OpenNewWindow then
        return nil
    end
    SecureCallBlizzard(FCF_OpenNewWindow, "Global Chat")
    return FindGlobalChatFrame()
end

--- Second docked tab is always ChatFrame2 (Combat Log when Blizzard_CombatLog is loaded).
local function GetCombatLogChatFrame()
    return _G["ChatFrame2"]
end

local function RefreshChatDockTabs()
    if FCF_DockUpdate then
        pcall(SecureCallBlizzard, FCF_DockUpdate)
    end
end

--- Tab order: General > Global Chat > Combat Log; extra Blizzard tabs (e.g. voice) after Combat Log.
--- FCF_DockFrame no-ops if already docked, so we undock non-primary frames then re-dock in order.
---
--- Retail FCFDock_UpdateTabs (FloatingChatFrame.lua) lays out isStaticDocked tabs first, then dynamic
--- tabs in the scroll row. ChatFrame1 and ChatFrame2 set isStaticDocked in XML/mixin; new windows
--- do not, so Global Chat was drawn after Combat Log even when DOCKED_CHAT_FRAMES order was correct.
local function ReorderDockGeneralGlobalCombat(globalFrame)
    if not globalFrame or not ChatFrame1 then
        return
    end

    if InCombatLockdown() then
        C_Timer.After(0.5, function()
            ReorderDockGeneralGlobalCombat(globalFrame)
        end)
        return
    end

    local combatLog = GetCombatLogChatFrame()
    if not combatLog then
        return
    end

    -- Keep Global in the same static tab strip as General and Combat Log (see comment above).
    globalFrame.isStaticDocked = true

    local dock = GENERAL_CHAT_DOCK
    if not dock or not dock.DOCKED_CHAT_FRAMES or not FCF_UnDockFrame or not FCF_DockFrame then
        RefreshChatDockTabs()
        return
    end

    local docked = dock.DOCKED_CHAT_FRAMES
    if docked[1] == ChatFrame1 and docked[2] == globalFrame and docked[3] == combatLog then
        RefreshChatDockTabs()
        return
    end

    local extras = {}
    for _, f in ipairs(docked) do
        if f ~= ChatFrame1 and f ~= globalFrame and f ~= combatLog then
            table.insert(extras, f)
        end
    end

    local toUndock = {}
    for _, f in ipairs(docked) do
        if f ~= dock.primary then
            table.insert(toUndock, f)
        end
    end
    for i = #toUndock, 1, -1 do
        pcall(SecureCallBlizzard, FCF_UnDockFrame, toUndock[i])
    end

    pcall(SecureCallBlizzard, FCF_DockFrame, globalFrame, 2, false)
    pcall(SecureCallBlizzard, FCF_DockFrame, combatLog, 3, false)

    for _, f in ipairs(extras) do
        local nextIndex = #(GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES or {}) + 1
        pcall(SecureCallBlizzard, FCF_DockFrame, f, nextIndex, false)
    end

    RefreshChatDockTabs()
end

local function ApplyGetChannelListToFrame(frame)
    if not frame or not GetChannelList then return 0 end
    local pack = { GetChannelList() }
    local n = 0
    for i = 1, #pack, 3 do
        local channelID = pack[i]
        local channelName = pack[i + 1]
        local disabled = pack[i + 2]
        if channelID and channelName and not disabled then
            EnableChannelOnFrame(frame, channelName)
            n = n + 1
        end
    end
    return n
end

local function ApplyNamedGlobalChannels(frame)
    if not frame then return end
    local id = frame:GetID()
    for _, ch in ipairs(GLOBAL_CHANNELS) do
        EnableChannelOnFrame(frame, ch)
        if not frame.SetChannelEnabled and AddChatWindowChannel then
            pcall(AddChatWindowChannel, id, ch)
        end
    end
end

local function ConfigureGlobalChannels(frame)
    if not frame then return end
    if FLUX_API and FLUX_API.isPostDF and GetChannelList then
        local count = ApplyGetChannelListToFrame(frame)
        if count == 0 then
            ApplyNamedGlobalChannels(frame)
        end
    else
        ApplyNamedGlobalChannels(frame)
    end
end

--- Zone/global channels often are not joinable on the first tick after login (all clients).
--- Post-DF also relies on GetChannelList(); pre-DF only had named-channel adds — retries matter there most.
local function ScheduleGlobalChannelRetries(frame)
    if not frame then return end
    local delays = { 1, 3, 5, 8, 12 }
    if FLUX_API and FLUX_API.isPreDF then
        delays = { 0.5, 1.5, 3, 6, 10, 15 }
    end
    for _, delay in ipairs(delays) do
        C_Timer.After(delay, function()
            if frame and frame.GetName and _G[frame:GetName()] then
                ConfigureGlobalChannels(frame)
            end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- POSITION / SIZE
-- ---------------------------------------------------------------------------

local function GetChatWidth()
    local base
    if FluxWindowFrame and FluxWindowFrame.WINDOW_WIDTH then
        base = FluxWindowFrame.WINDOW_WIDTH
    else
        base = 300 * 1.35
    end
    local xF = 1
    if FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames then
        xF = FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames() or 1
    end
    if type(xF) ~= "number" or xF ~= xF or xF <= 0 then
        xF = 1
    end
    return base * xF
end

local function GetChatHeight()
    local base
    if FluxWindowFrame and FluxWindowFrame.WINDOW_HEIGHT then
        base = FluxWindowFrame.WINDOW_HEIGHT
    else
        base = 200 * 1.35
    end
    return math.max(120, base - 100)
end

local function ShownFrameTop(frame)
    if not (frame and frame.GetTop) then
        return nil
    end
    if frame.IsShown and not frame:IsShown() then
        return nil
    end
    local top = frame:GetTop()
    if type(top) ~= "number" or top ~= top or top < 40 then
        return nil
    end
    return top
end

--- Computed action-strip chrome height (backup SmartLayout: 1.5 rows × 1.24 + margins).
local function GetComputedStripChromeHeight()
    local C = _G.Flux and _G.Flux.Bars and _G.Flux.Bars.CONFIG
    local buttonSize = (C and C.buttonSize) or 44
    local scale = (C and C.scale) or 1.24
    local margin = (C and C.margin) or 4
    local tweak = (C and C.heightTweak) or -2
    return buttonSize * 1.5 * scale + margin * 2 + tweak
end

--- Top of the action / NC envelope. Backup used FluxUnifiedBorderFrame:GetTop(); that
--- frame starts hidden so GetTop was 0 and chat sat on the strip. Prefer live tops,
--- never below the computed chrome so the log cannot park at Y=32.
local function GetStripClearanceTop()
    local best = 0
    local function consider(top)
        if type(top) == "number" and top > best then
            best = top
        end
    end
    consider(ShownFrameTop(_G.FluxUnifiedBorderFrame))
    consider(ShownFrameTop(_G.FluxStatusBarUnifiedBorderFrame))
    consider(ShownFrameTop(_G.FluxActionStrip) or ShownFrameTop(_G.FluxMainActionBar))
    local nc = _G.FluxNonCombatAPI and _G.FluxNonCombatAPI.DefaultGrid
    consider(ShownFrameTop(nc and nc.Frame))
    consider(ShownFrameTop(_G.FluxNonCombatGrid_Main))
    -- Combat extras sit in the action-bar row. Including their top lifts the log
    -- when potions appear / combat starts. Chat must keep the action/NC floor.
    local bot = 4
    if _G.FluxActionBar_GetBottomScreenOffset then
        local ok, y = pcall(_G.FluxActionBar_GetBottomScreenOffset)
        if ok and type(y) == "number" and y == y then
            bot = y
        end
    end
    consider(bot + GetComputedStripChromeHeight())
    return best
end

local function GetBorderTop()
    return GetStripClearanceTop()
end

local function GetEditBoxHeight()
    local editBox = _G["ChatFrame1EditBox"]
    if editBox and editBox.GetHeight then
        local h = editBox:GetHeight()
        if h and h > 0 then
            return h
        end
    end
    return 32
end

--- Same 3px gap micromenu pos2 uses above the action/grid unified border.
local ACTION_STRIP_CHAT_GAP = 3

local function ApplyStatusBarChatLifts(yBottom)
    local loc2Lift = _G.FluxStatusBar_GetLocation2MinBottomOffset and _G.FluxStatusBar_GetLocation2MinBottomOffset()
    if type(loc2Lift) == "number" and loc2Lift == loc2Lift then
        yBottom = math.max(yBottom, loc2Lift)
    end
    local pos3Lift = _G.FluxStatusBar_GetBottomOverlayHeight and _G.FluxStatusBar_GetBottomOverlayHeight()
    if type(pos3Lift) == "number" and pos3Lift == pos3Lift and pos3Lift > 0 then
        yBottom = math.max(yBottom, pos3Lift)
    end
    return yBottom
end

--- Live top of the action/NC envelope (not max-of-everything). Pos1/3 chat sits on this floor.
local function GetActionStripTopY()
    local y
    if _G.FluxUnifiedBorder and _G.FluxUnifiedBorder.GetActionGridBorderTop then
        local ok, t = pcall(_G.FluxUnifiedBorder.GetActionGridBorderTop)
        if ok and type(t) == "number" and t == t and t > 0 then
            y = t
        end
    end
    if not y then
        y = ShownFrameTop(_G.FluxActionStrip) or ShownFrameTop(_G.FluxMainActionBar) or GetStripClearanceTop()
    end
    local Cap = ns.Flux and ns.Flux.Cap
    local floor = Cap and Cap.GetGamepadActionBarFloor and Cap.GetGamepadActionBarFloor()
    if type(floor) == "number" and floor == floor and (type(y) ~= "number" or floor > y) then
        return floor
    end
    return y
end

--- Pos1 and pos3: log bottom matches pos2 — above the action strip, with the edit box under the log.
local function GetChatFloorAboveActionStrip()
    return ApplyStatusBarChatLifts(GetActionStripTopY() + ACTION_STRIP_CHAT_GAP + GetEditBoxHeight())
end

--- Exported for FluxMicroMenu vertical layout cap (must match GetChatHeight).
function _G.FluxChatFrame_GetPrimaryChatHeight()
    return GetChatHeight()
end

local DEFAULT_CHAT_TAB_H = 22

local function GetChatTabHeightUI()
    local tab = _G.ChatFrame1Tab
    if tab and tab.GetHeight and (not tab.IsShown or tab:IsShown()) then
        local h = tab:GetHeight()
        if type(h) == "number" and h > 4 and h < 80 then
            local fes = (tab.GetEffectiveScale and tab:GetEffectiveScale()) or 1
            local ues = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
            if type(fes) == "number" and fes > 0 and type(ues) == "number" and ues > 0 then
                h = h * fes / ues
            end
            if h > 4 and h < 80 then
                return h
            end
        end
    end
    return DEFAULT_CHAT_TAB_H
end

--- Bottom Y inset for anchoring frames to UIParent BOTTOMLEFT (matches ApplyPosition for ChatFrame1).
--- Includes status-strip lifts so micromenu pos2 and chat share one floor.
function _G.FluxChatFrame_GetPrimaryBottomInsetY()
    local yBottom = GetBorderTop() + GetEditBoxHeight()
    return ApplyStatusBarChatLifts(yBottom)
end

--- Visual chat-tab height in UIParent units (not live GetTop — that follows off-screen FCF restores).
function _G.FluxChatFrame_GetPrimaryTabHeight()
    return GetChatTabHeightUI()
end

--- Intended column top (UIParent BOTTOMLEFT Y): chat floor + log height + tab. Independent of ChatFrame1:GetTop().
function _G.FluxChatFrame_GetPrimaryColumnTopY()
    return _G.FluxChatFrame_GetPrimaryBottomInsetY() + GetChatHeight() + GetChatTabHeightUI()
end

--- Top edge Y (UIParent space) for micromenu alignment: preferred computed column top; live GetTop only if on-screen.
function _G.FluxChatFrame_GetPrimaryChatTop()
    local computed = _G.FluxChatFrame_GetPrimaryColumnTopY()
    if type(computed) == "number" and computed == computed and computed > 0 then
        return computed
    end
    local tab = _G.ChatFrame1Tab
    if tab and tab.GetTop and (not tab.IsShown or tab:IsShown()) then
        local ty = tab:GetTop()
        if ty and ty > 0 then
            return ty
        end
    end
    local f = ChatFrame1
    if f and f.GetTop then
        return f:GetTop()
    end
    return nil
end

--- Single clearance (micromenu column right → chat frame left). Chat X = column right + this gap.
--- Includes room for FluxBorder art past the frame rect and chat’s left scroll/menu controls (not inside the strip).
local MICROMENU_CHAT_GAP = 34

--- Horizontal bar (position 1): chat BOTTOMLEFT X so the log isn’t flush to the screen edge (matches typical UI inset).
local CHAT_LEFT_INSET_POS1 = 34

--- Must match MicroMenu BESIDE_CHAT_LEFT_INSET (pos2 column origin). Fallback if the column-right export is missing.
local BESIDE_CHAT_COLUMN_LEFT_INSET = 2

function _G.FluxChatFrame_GetBesideMicromenuGap()
    return MICROMENU_CHAT_GAP
end

--- Layout default is beside-chat (2). Treating "options not loaded" as position 1
--- parks the log on the left, overlapping the micromenu column and the NC/action strip.
local function GetMicroMenuLayoutPos()
    if FluxOptions and FluxOptions.GetMicroMenuLayoutPosition then
        return FluxOptions:GetMicroMenuLayoutPosition()
    end
    return 2
end

--- Pos2 column width from Flux micro options. Live GetWidth is 300 until the strip is
--- laid out, or 1px in empty-layout paths — both slam chat to the left.
local function EstimateBesideChatColumnWidth()
    local cols = 2
    if FluxOptions and FluxOptions.GetMicroMenuBesideChatColumns then
        cols = FluxOptions:GetMicroMenuBesideChatColumns() or 2
    end
    if type(cols) ~= "number" or cols < 1 then
        cols = 2
    end
    local sw = 32
    if FluxGetStandardMicroButtonSize then
        local ok, w = pcall(FluxGetStandardMicroButtonSize)
        if ok and type(w) == "number" and w > 8 then
            sw = w
        end
    end
    local scale = 0.9
    if _G.FluxMicroMenu and _G.FluxMicroMenu.GetButtonSizeScale then
        local ok, s = pcall(_G.FluxMicroMenu.GetButtonSizeScale, _G.FluxMicroMenu)
        if ok and type(s) == "number" and s > 0 then
            scale = s
        end
    end
    local spacing = 0
    if _G.FluxMicroMenu and _G.FluxMicroMenu.GetLayoutSpacing then
        local ok, g = pcall(_G.FluxMicroMenu.GetLayoutSpacing, _G.FluxMicroMenu)
        if ok and type(g) == "number" then
            spacing = g
        end
    end
    local btnW = sw * scale
    return cols * btnW + math.max(0, cols - 1) * spacing
end

local function PlausibleBesideChatWidth(w)
    return type(w) == "number" and w > 8 and w < 220
end

local function GetChatBottomLeftX()
    if GetMicroMenuLayoutPos() ~= 2 then
        return CHAT_LEFT_INSET_POS1
    end
    local width
    local mm = _G.FluxMicroMenu
    if mm then
        local reserve = mm._besideChatReserveWidth
        if PlausibleBesideChatWidth(reserve) then
            width = reserve
        elseif PlausibleBesideChatWidth(mm.GetWidth and mm:GetWidth()) then
            width = mm:GetWidth()
        end
    end
    if not width then
        width = EstimateBesideChatColumnWidth()
    end
    -- Column is pinned at BESIDE_CHAT_LEFT_INSET (2). Backup used width+gap as if x=0;
    -- with a pinned column the log is inset + width + gap so it sits right of the strip.
    return BESIDE_CHAT_COLUMN_LEFT_INSET + width + MICROMENU_CHAT_GAP
end

local function IsEraOrAnniversaryChat()
    local client = (ns.Flux and ns.Flux.Client) or (_G.Flux and _G.Flux.Client)
    if client and (client.isEra or client.isAnniversary) then
        return true
    end
    if WOW_PROJECT_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        return true
    end
    if WOW_PROJECT_BURNING_CRUSADE_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        return true
    end
    return false
end

--- Pos2: log fills the micromenu column except the tab row (top) and the chat edit box
--- (bottom, below ChatFrame1). Extra height still grows down; do not raise the top.
--- Era and Anniversary do not follow the live menu rect. That rect changes every
--- menu refresh and drags the log with it.
local function GetPos2ChatVertical()
    if GetMicroMenuLayoutPos() ~= 2 or IsEraOrAnniversaryChat() then
        return nil, nil
    end
    local mm = _G.FluxMicroMenu
    if not mm or not mm.GetHeight or not mm.GetBottom then
        return nil, nil
    end
    local mmH = mm:GetHeight()
    local mmBottom = mm:GetBottom()
    if type(mmH) ~= "number" or mmH ~= mmH or mmH < 48 then
        return nil, nil
    end
    if type(mmBottom) ~= "number" or mmBottom ~= mmBottom then
        return nil, nil
    end
    local tabH = GetChatTabHeightUI()
    local editH = GetEditBoxHeight()
    local h = mmH - tabH - editH
    if h < 120 then
        h = 120
    end
    return mmBottom + editH, h
end

-- Last Flux layout. Combat ExtraAction / UIParent_ManageFramePositions parks
-- DEFAULT_CHAT_FRAME; we re-pin this instead of recomputing from combat extras.
local lastChatPin = nil

--- Classic UIParentManageFramePositions moves ChatFrame1 while
--- systemInfo.isInDefaultPosition is true (stance, pet, status bars).
--- ApplySystemAnchor then clears ignoreFramePositionManager and does it
--- again. Store our point as the layout anchor and leave the default
--- position so those passes keep the same spot.
local function SyncChatEditModeAnchor(chatFrame, x, y)
    if not chatFrame then
        return
    end
    chatFrame.ignoreFramePositionManager = true
    local info = chatFrame.systemInfo
    if not info or type(x) ~= "number" or type(y) ~= "number" then
        return
    end
    info.isInDefaultPosition = false
    if not info.anchorInfo then
        info.anchorInfo = {}
    end
    local scale = 1
    if chatFrame.GetScale then
        local s = chatFrame:GetScale()
        if type(s) == "number" and s > 0 then
            scale = s
        end
    end
    info.anchorInfo.point = "BOTTOMLEFT"
    info.anchorInfo.relativeTo = "UIParent"
    info.anchorInfo.relativePoint = "BOTTOMLEFT"
    info.anchorInfo.offsetX = x * scale
    info.anchorInfo.offsetY = y * scale
    info.anchorInfo2 = nil
end

local function PinChatFrame(chatFrame, x, y, w, h)
    if not chatFrame or type(x) ~= "number" or type(y) ~= "number" or type(w) ~= "number" or type(h) ~= "number" then
        return
    end
    SyncChatEditModeAnchor(chatFrame, x, y)
    chatFrame.ignoreFramePositionManager = true
    if chatFrame.SetMovable then
        pcall(chatFrame.SetMovable, chatFrame, true)
    end
    -- Edit Mode overrides ClearAllPoints/SetPoint and dirties the system anchor.
    -- Base widget methods skip that tracking.
    if chatFrame.ClearAllPointsBase then
        pcall(chatFrame.ClearAllPointsBase, chatFrame)
    else
        pcall(chatFrame.ClearAllPoints, chatFrame)
    end
    pcall(chatFrame.SetSize, chatFrame, w, h)
    if chatFrame.SetPointBase then
        pcall(chatFrame.SetPointBase, chatFrame, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    else
        pcall(chatFrame.SetPoint, chatFrame, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    end
    if chatFrame.SetUserPlaced then
        pcall(chatFrame.SetUserPlaced, chatFrame, true)
    end
end

--- Ignore smaller refreshes. Menu layout and tab-height reads move the log
--- by a few pixels if every measurement is applied.
local CHAT_PIN_HOLD_PX = 24

local function ChatPinDrifted(chatFrame, x, y)
    if not chatFrame or not chatFrame.GetLeft or not chatFrame.GetBottom then
        return true
    end
    local left = chatFrame:GetLeft()
    local bottom = chatFrame:GetBottom()
    if type(left) ~= "number" or type(bottom) ~= "number" then
        return true
    end
    return math.abs(left - x) > 12 or math.abs(bottom - y) > 12
end

local function ChatMetricsClose(pin, x, y, w, h)
    if not pin then
        return false
    end
    return math.abs(pin.x - x) <= CHAT_PIN_HOLD_PX
        and math.abs(pin.y - y) <= CHAT_PIN_HOLD_PX
        and math.abs(pin.w - w) <= CHAT_PIN_HOLD_PX
        and math.abs(pin.h - h) <= CHAT_PIN_HOLD_PX
end

local chatPinApplying = false
local chatPinPending = false
local chatPinHold = false
local ApplyPosition

local function ScheduleChatPin(chatFrame)
    if chatPinHold or chatPinPending or chatPinApplying or not chatFrame then
        return
    end
    chatPinPending = true
    local function run()
        chatPinPending = false
        if chatPinHold then
            return
        end
        if FluxEditModeBusy and FluxEditModeBusy() then
            FluxAfterEditMode(run, "FluxChatPin")
            return
        end
        if chatFrame and chatFrame.GetName and _G[chatFrame:GetName()] then
            ApplyPosition(chatFrame)
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

ApplyPosition = function(chatFrame, force)
    if chatPinHold or not chatFrame or chatPinApplying then
        return
    end
    chatPinApplying = true

    -- Combat: keep the last OOC layout. Do not recompute from combat-grid tops
    -- or skip entirely (Blizzard then parks the log on the action strip).
    if InCombatLockdown() then
        if lastChatPin then
            PinChatFrame(chatFrame, lastChatPin.x, lastChatPin.y, lastChatPin.w, lastChatPin.h)
        end
        chatPinApplying = false
        return
    end

    -- Pos2 menu refresh runs often on Era and Anniversary. Keep the placed log.
    if not force and lastChatPin and IsEraOrAnniversaryChat() and GetMicroMenuLayoutPos() == 2 then
        SyncChatEditModeAnchor(chatFrame, lastChatPin.x, lastChatPin.y)
        chatPinApplying = false
        return
    end

    local w = GetChatWidth()
    local h = GetChatHeight()
    local yBottom = GetChatFloorAboveActionStrip()
    local pos2Bottom, pos2H = GetPos2ChatVertical()
    if pos2Bottom then
        yBottom = pos2Bottom
        h = pos2H
    elseif GetMicroMenuLayoutPos() == 2 and lastChatPin then
        -- Beside-chat layout, but the menu has no size yet. Do not drop the
        -- log onto the action strip for that one refresh.
        chatPinApplying = false
        return
    end
    local xLeft = GetChatBottomLeftX()
    if ChatMetricsClose(lastChatPin, xLeft, yBottom, w, h) then
        chatPinApplying = false
        return
    end
    lastChatPin = { x = xLeft, y = yBottom, w = w, h = h }
    PinChatFrame(chatFrame, xLeft, yBottom, w, h)

    local id = chatFrame:GetID()
    if SetChatWindowSavedDimensions then
        SetChatWindowSavedDimensions(id, w, h)
    end
    if SetChatWindowSavedPosition then
        local parentW = UIParent:GetWidth()
        local parentH = UIParent:GetHeight()
        if parentW and parentW > 0 and parentH and parentH > 0 then
            SetChatWindowSavedPosition(id, "BOTTOMLEFT", xLeft / parentW, yBottom / parentH)
        end
    end

    -- Do not call EditModeManagerFrame:UpdateSystemAnchorInfo: that writes
    -- Edit Mode anchors under addon execution and poisons a later
    -- UpdateBottomActionBarPositions → RightManagedFrameContainer:SetSize.

    if chatFrame == ChatFrame1 and FluxUIPositionFocusFrameDefault then
        FluxUIPositionFocusFrameDefault()
    end

    if chatFrame == ChatFrame1 and FluxRaidFrame_UpdatePosition then
        FluxRaidFrame_UpdatePosition()
    end
    chatPinApplying = false
end

local stripRetryScheduled = false

local function ApplyPositionWithRetries(chatFrame, force)
    ApplyPosition(chatFrame, force)
    local stripReady = ShownFrameTop(_G.FluxActionStrip) or ShownFrameTop(_G.FluxMainActionBar)
        or ShownFrameTop(_G.FluxUnifiedBorderFrame)
    if stripReady or stripRetryScheduled then
        return
    end
    stripRetryScheduled = true
    C_Timer.After(0.5, function()
        if chatFrame and chatFrame.IsShown and chatFrame:IsShown() then
            ApplyPosition(chatFrame, true)
        end
    end)
    C_Timer.After(1.5, function()
        if chatFrame and chatFrame.IsShown and chatFrame:IsShown() then
            ApplyPosition(chatFrame, true)
        end
        stripRetryScheduled = false
    end)
end

function _G.FluxChatFrame_ApplyPrimaryPosition(force)
    if not ChatFrame1 or chatPinHold then
        return
    end
    ApplyPositionWithRetries(ChatFrame1, force)
end

--- Classic bag drags resize BagsBar and UIParent then re-pins chat from a fresh
--- measurement. Hold the last pin for that drag and put the log back without
--- measuring the micro menu or the action strip again.
function _G.FluxChatFrame_SetDragHold(hold, quiet)
    if hold then
        chatPinHold = true
        return
    end
    chatPinHold = false
    if quiet then
        return
    end
    local pin = lastChatPin
    local frame = _G.ChatFrame1
    if not pin or not frame then
        return
    end
    local width = frame.GetWidth and frame:GetWidth()
    local height = frame.GetHeight and frame:GetHeight()
    local sizeDrifted = type(width) ~= "number" or type(height) ~= "number"
        or math.abs(width - pin.w) > 12 or math.abs(height - pin.h) > 12
    if sizeDrifted or ChatPinDrifted(frame, pin.x, pin.y) then
        PinChatFrame(frame, pin.x, pin.y, pin.w, pin.h)
    end
end

--- Classic UIParent_ManageFramePositions parks DEFAULT_CHAT_FRAME on the bottom-left
--- action/NC strip. Edit Mode calls that function inside its open and close passes
--- (before TargetUnit / ResetTargetAndFocus), so it is not hooked. A light ticker
--- puts chat back once Blizzard moved it.
local chatDriftTicker = nil

--- Put the log back on the last placed point. Measuring again here follows the
--- micromenu and the action strip, so the frame keeps sliding.
local chatPinRestoring = false

local function RestoreLastChatPin(chatFrame)
    if chatPinRestoring then
        return true
    end
    chatFrame = chatFrame or _G.ChatFrame1
    local pin = lastChatPin
    if chatPinHold or chatPinApplying or not chatFrame or not pin then
        return false
    end
    local width = chatFrame.GetWidth and chatFrame:GetWidth()
    local height = chatFrame.GetHeight and chatFrame:GetHeight()
    SyncChatEditModeAnchor(chatFrame, pin.x, pin.y)
    local sizeDrifted = type(width) ~= "number" or type(height) ~= "number"
        or math.abs(width - pin.w) > 12 or math.abs(height - pin.h) > 12
    if sizeDrifted or ChatPinDrifted(chatFrame, pin.x, pin.y) then
        chatPinRestoring = true
        PinChatFrame(chatFrame, pin.x, pin.y, pin.w, pin.h)
        chatPinRestoring = false
    end
    return true
end

local function RepinChatIfDrifted()
    if chatPinHold or chatPinApplying or chatPinPending or not ChatFrame1 then
        return
    end
    if not (_FluxUI_CharSavedVars and _FluxUI_CharSavedVars.fluxChatConfigured) then
        return
    end
    if FluxEditModeBusy and FluxEditModeBusy() then
        return
    end
    if RestoreLastChatPin(ChatFrame1) then
        return
    end
    local wantX = GetChatBottomLeftX()
    local wantY = _G.FluxChatFrame_GetPrimaryBottomInsetY()
    local left = ChatFrame1.GetLeft and ChatFrame1:GetLeft()
    local bottom = ChatFrame1.GetBottom and ChatFrame1:GetBottom()
    if type(left) == "number" and type(bottom) == "number"
        and math.abs(left - wantX) <= 12 and bottom >= (wantY - 12) then
        return
    end
    ScheduleChatPin(ChatFrame1)
end

local function WatchChatPinDrift()
    if chatDriftTicker or type(UIParent_ManageFramePositions) ~= "function" then
        return
    end
    if not (C_Timer and C_Timer.NewTicker) then
        return
    end
    chatDriftTicker = C_Timer.NewTicker(1, RepinChatIfDrifted)
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Exit", function()
            if FluxAfterEditMode then
                FluxAfterEditMode(RepinChatIfDrifted)
            end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- CLASS COLORS
-- ---------------------------------------------------------------------------

local function EnableAllClassColors()
    if not SetChatColorNameByClass then return end

    for _, msgType in ipairs(ALL_CLASS_COLOR_TYPES) do
        pcall(SetChatColorNameByClass, msgType, true)
        if ChatTypeInfo[msgType] then
            ChatTypeInfo[msgType].colorNameByClass = true
        end
    end
    for i = 1, 20 do
        local chType = "CHANNEL" .. i
        pcall(SetChatColorNameByClass, chType, true)
        if ChatTypeInfo[chType] then
            ChatTypeInfo[chType].colorNameByClass = true
        end
    end
end

-- ---------------------------------------------------------------------------
-- CHATFRAME1 (General) CONFIGURATION
-- ---------------------------------------------------------------------------

local function ConfigureGeneral(chatFrame)
    if FCF_SetLocked then
        FCF_SetLocked(chatFrame, 1)
    end

    if SetChatWindowUninteractable then
        SetChatWindowUninteractable(chatFrame:GetID(), false)
    end
    chatFrame.isUninteractable = false

    if FCF_SetChatWindowFontSize then
        FCF_SetChatWindowFontSize(nil, chatFrame, FONT_SIZE)
    end

    for _, ch in ipairs(GLOBAL_CHANNELS) do
        SafeDisableChannelOnFrame(chatFrame, ch)
    end
end

--- Remove global channels from General (ChatFrame1). Called on first run and on pre-DF
--- every login — zone/channel logic can re-add them, so we re-apply.
local function DisableGlobalChannelsOnGeneral()
    if not ChatFrame1 then return end
    for _, ch in ipairs(GLOBAL_CHANNELS) do
        SafeDisableChannelOnFrame(ChatFrame1, ch)
    end
end

-- ---------------------------------------------------------------------------
-- GLOBAL CHAT (new window) CONFIGURATION
-- Leaves ChatFrame1 (General) and ChatFrame2 (Combat Log) untouched.
-- ---------------------------------------------------------------------------

local function ConfigureGlobalChat()
    local globalFrame = EnsureGlobalChatFrame()
    if not globalFrame then
        return
    end

    ReorderDockGeneralGlobalCombat(globalFrame)

    if FCF_SetLocked then
        FCF_SetLocked(globalFrame, 1)
    end

    if SetChatWindowUninteractable then
        SetChatWindowUninteractable(globalFrame:GetID(), false)
    end
    globalFrame.isUninteractable = false

    if FCF_SetChatWindowFontSize then
        FCF_SetChatWindowFontSize(nil, globalFrame, FONT_SIZE)
    end

    for _, group in ipairs(CHAT_MESSAGE_GROUPS) do
        SafeRemoveMessageGroup(globalFrame, group)
    end

    SafeAddMessageGroup(globalFrame, "WHISPER")
    SafeAddMessageGroup(globalFrame, "BN_WHISPER")
    SafeAddMessageGroup(globalFrame, "SYSTEM")
    SafeAddMessageGroup(globalFrame, "CHANNEL")

    fluxGlobalChatFrame = globalFrame
    ConfigureGlobalChannels(globalFrame)
    ScheduleGlobalChannelRetries(globalFrame)

    return globalFrame
end

local function SelectGeneralTab()
    if not ChatFrame1 then return end
    if FCF_SelectDockFrame then
        pcall(SecureCallBlizzard, FCF_SelectDockFrame, ChatFrame1)
    end
end

-- ---------------------------------------------------------------------------
-- EDIT MODE WORKAROUND
-- ---------------------------------------------------------------------------

local editModeChatHooksDone = false

local function RepositionFluxPrimaryChat()
    if not (_FluxUI_CharSavedVars and _FluxUI_CharSavedVars.fluxChatConfigured) or not ChatFrame1 then
        return
    end
    ApplyPosition(ChatFrame1)
end

--- On Classic Anniversary (and any pre-DF client with Edit Mode), ChatFrame1 is an Edit Mode
--- system frame. Edit Mode stores its own anchor and reapplies it via ApplySystemAnchor()
--- whenever layout is refreshed (ExitEditMode → RevertAllChanges → UpdateLayoutInfo, login,
--- EDIT_MODE_LAYOUTS_UPDATED, etc.). Hooking ApplySystemAnchor directly is the only way to
--- catch every reposition at the source and override it without timer-based oscillation.
local function HookEditModeRestore()
    if not FLUX_API or not FLUX_API.hasEditMode then return end
    if editModeChatHooksDone then return end
    editModeChatHooksDone = true

    -- Primary defense: intercept every Edit Mode anchor apply on ChatFrame1.
    -- ApplySystemAnchor reads systemInfo.anchorInfo and calls SetPoint (override).
    -- Our post-hook immediately re-applies Flux position using base widget methods
    -- (via ApplyPosition), so the frame never visibly jumps.
    if ChatFrame1.ApplySystemAnchor then
        hooksecurefunc(ChatFrame1, "ApplySystemAnchor", function(self)
            if _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.fluxChatConfigured then
                -- Defer: synchronous ApplyPosition taints FCFDock_UpdateTabs → ChatFrame1:Show().
                -- Restore the placed point. Measuring again moves the frame.
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, function()
                        if not RestoreLastChatPin(self) then
                            ScheduleChatPin(self)
                        end
                    end)
                elseif not RestoreLastChatPin(self) then
                    ScheduleChatPin(self)
                end
            end
        end)
    end

    -- Backup: FCF_RestorePositionAndDimensions early-returns for DEFAULT_CHAT_FRAME on
    -- Classic Anniversary, but on retail the hook still serves as a fallback.
    if FCF_RestorePositionAndDimensions then
        hooksecurefunc("FCF_RestorePositionAndDimensions", function(chatFrame)
            if chatFrame == ChatFrame1 then
                if not RestoreLastChatPin(chatFrame) then
                    ScheduleChatPin(chatFrame)
                end
            end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Social button: above Chat Channel (Classic: layoutIndex; Retail: QuickJoin anchor)
-- CHAT_SOCIAL_CLUSTER_NUDGE_DOWN: pushes Channel + Social together toward the edit box (all clients).
-- ---------------------------------------------------------------------------

local CHAT_SOCIAL_CLUSTER_NUDGE_DOWN = 14

local socialButtonLayoutDone = false

--- Classic / Anniversary / Era: FriendsMicroButton used layoutIndex -2 so it sat above the
--- scroll cluster; reorder so Social sits just above ChatFrameChannelButton.
local function ChatColumnButtonEnabled(globalName)
    if FluxCCP and FluxCCP.IsChatButtonEnabled then
        return FluxCCP.IsChatButtonEnabled(globalName)
    end
    return true
end

local function PlaceClassicColumnButton(btn, globalName, nextIndex, padding)
    if not btn then
        return nextIndex
    end
    if not ChatColumnButtonEnabled(globalName) then
        btn.ignoreInLayout = true
        return nextIndex
    end
    btn.ignoreInLayout = nil
    btn.layoutIndex = nextIndex
    btn.align = "center"
    if padding ~= nil then
        btn.bottomPadding = padding
    end
    return nextIndex + 1
end

local function ApplySocialButtonLayoutNearChannel()
    if _G.QuickJoinToastButton then return end
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(ApplySocialButtonLayoutNearChannel)
        return
    end
    if not _G.FriendsMicroButton or not _G.ChatFrameChannelButton or not _G.ChatFrameMenuButton then
        return
    end
    local chat = ChatFrame1
    if not chat or not chat.buttonFrame then return end
    local bf = chat.buttonFrame
    local up, down, bottom = bf.upButton, bf.downButton, bf.bottomButton
    if not up or not down or not bottom then return end

    up.layoutIndex = 1
    down.layoutIndex = 2
    bottom.layoutIndex = 3
    local nextIndex = 4
    nextIndex = PlaceClassicColumnButton(FriendsMicroButton, "FriendsMicroButton", nextIndex, 0)
    nextIndex = PlaceClassicColumnButton(ChatFrameChannelButton, "ChatFrameChannelButton", nextIndex, 0)
    nextIndex = PlaceClassicColumnButton(_G.FluxCCPChatGuildButton, "FluxCCPChatGuildButton", nextIndex, 16)
    nextIndex = PlaceClassicColumnButton(_G.FluxCCPChatBagButton, "FluxCCPChatBagButton", nextIndex, 0)
    nextIndex = PlaceClassicColumnButton(_G.FluxCCPChatDurabilityButton, "FluxCCPChatDurabilityButton", nextIndex, 8)
    nextIndex = PlaceClassicColumnButton(_G.FluxCCPChatCopyButton, "FluxCCPChatCopyButton", nextIndex, 0)
    nextIndex = PlaceClassicColumnButton(ChatFrameMenuButton, "ChatFrameMenuButton", nextIndex, 0)
    nextIndex = PlaceClassicColumnButton(_G.FluxCCPChatSettingsButton, "FluxCCPChatSettingsButton", nextIndex, 0)
    if FluxCCP and FluxCCP.PinClassicButtonFrame then
        FluxCCP.PinClassicButtonFrame(chat)
    end
    if bf.MarkDirty then
        bf:MarkDirty()
    end
    if bf.Layout then
        pcall(function()
            bf:Layout()
        end)
    end
    socialButtonLayoutDone = true
end

function _G.FluxChatFrame_RefreshSocialLayout()
    ApplySocialButtonLayoutNearChannel()
end

local quickJoinAnchorHooksDone = false

--- Mainline: channel is TOP-anchored to the button strip; nudge it down, then pin QuickJoin above it.
local function ApplyChatFrameChannelButtonTopOffset()
    local bf = ChatFrame1 and ChatFrame1.buttonFrame
    local ch = _G.ChatFrameChannelButton
    if not bf or not ch or not ch.ClearAllPoints or not ch.SetPoint then
        return
    end
    -- buttonFrame is anchored to ChatFrame.Background, a texture. Once the
    -- durability button is protected, SetPoint through that strip errors.
    -- The chat column positions this button itself.
    local holder = _G.FluxCCPChatColumn
    if holder and ch.GetParent and ch:GetParent() == holder then
        return
    end
    local dur = _G.FluxCCPChatDurabilityButton
    if dur and dur.IsProtected and dur:IsProtected() then
        return
    end
    ch:ClearAllPoints()
    ch:SetPoint("TOP", bf, "TOP", 0, -CHAT_SOCIAL_CLUSTER_NUDGE_DOWN)
end

local function ApplyQuickJoinAnchorToChannel()
    local qj = _G.QuickJoinToastButton
    local ch = _G.ChatFrameChannelButton
    if not qj or not qj.ClearAllPoints then return end
    if FluxCCP and FluxCCP.IsChatButtonEnabled and not FluxCCP.IsChatButtonEnabled("QuickJoinToastButton") then
        return
    end
    local anchor = ch
    if not anchor or anchor._fluxChatOptHidden then
        anchor = _G.FluxCCPChatColumn
    end
    if not anchor then return end
    qj:ClearAllPoints()
    local gap = 0
    local side = "right"
    if ChatFrame1 and FCF_GetButtonSide then
        side = FCF_GetButtonSide(ChatFrame1) or side
    end
    local point = (side == "left") and "BOTTOMLEFT" or "BOTTOMRIGHT"
    local rel = (side == "left") and "TOPLEFT" or "TOPRIGHT"
    qj:SetPoint(point, anchor, rel, 0, gap)
end

local function ApplyRetailChatChannelAndQuickJoin()
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(ApplyRetailChatChannelAndQuickJoin)
        return
    end
    ApplyChatFrameChannelButtonTopOffset()
    ApplyQuickJoinAnchorToChannel()
    if FluxCCP and FluxCCP.PlaceColumnButtons then
        FluxCCP.PlaceColumnButtons()
    end
end

local function ScheduleRetailChatChannelApply()
    C_Timer.After(0, ApplyRetailChatChannelAndQuickJoin)
    C_Timer.After(0.1, ApplyRetailChatChannelAndQuickJoin)
    C_Timer.After(1, ApplyRetailChatChannelAndQuickJoin)
end

local function InitQuickJoinAnchorHooks()
    if quickJoinAnchorHooksDone then return end
    if not _G.QuickJoinToastButton or not _G.ChatFrameChannelButton then return end

    quickJoinAnchorHooksDone = true

    -- ChatAlertFrame is optional: if missing, we still nudge via FCF hooks + timers.
    if _G.ChatAlertFrame and ChatAlertFrame.UpdateAnchors then
        hooksecurefunc(ChatAlertFrame, "UpdateAnchors", function()
            ScheduleRetailChatChannelApply()
        end)
    end

    if FCF_SetButtonSide then
        hooksecurefunc("FCF_SetButtonSide", function(chatFrame)
            if chatFrame == ChatFrame1 then
                ScheduleRetailChatChannelApply()
            end
        end)
    end
    if FCF_UpdateButtonSide then
        hooksecurefunc("FCF_UpdateButtonSide", function(chatFrame)
            if chatFrame == ChatFrame1 then
                ScheduleRetailChatChannelApply()
            end
        end)
    end

    -- Do not replace ChatFrameChannelButton.ClearAllPoints: Blizzard's chat
    -- button layout (also in chat's Edit Mode enter) would run Flux code.
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Exit", function()
            if FluxAfterEditMode then
                FluxAfterEditMode(ApplyRetailChatChannelAndQuickJoin)
            end
        end)
    end

    ScheduleRetailChatChannelApply()
end

local function InitSocialButtonPositioning()
    InitQuickJoinAnchorHooks()
    ApplySocialButtonLayoutNearChannel()
    if not socialButtonLayoutDone and not _G.QuickJoinToastButton then
        C_Timer.After(0.5, ApplySocialButtonLayoutNearChannel)
    end
    if _G.QuickJoinToastButton and not quickJoinAnchorHooksDone then
        C_Timer.After(0.5, InitQuickJoinAnchorHooks)
    end
end

-- ---------------------------------------------------------------------------
-- MAIN INITIALIZATION
-- ---------------------------------------------------------------------------

local function RunConfiguration()
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end

    if _FluxUI_CharSavedVars.fluxChatConfigured then
        fluxGlobalChatFrame = FindGlobalChatFrame()
        if fluxGlobalChatFrame then
            ReorderDockGeneralGlobalCombat(fluxGlobalChatFrame)
            ConfigureGlobalChannels(fluxGlobalChatFrame)
            ScheduleGlobalChannelRetries(fluxGlobalChatFrame)
        end
        -- Pre-DF: zone/channel logic can re-add global channels to General; re-disable every login.
        if FLUX_API and FLUX_API.isPreDF then
            DisableGlobalChannelsOnGeneral()
        end
        ApplyPositionWithRetries(ChatFrame1)
        HookEditModeRestore()
        WatchChatPinDrift()
        InitSocialButtonPositioning()
        return
    end

    if InCombatLockdown() then
        C_Timer.After(2, RunConfiguration)
        return
    end

    local chatFrame1 = ChatFrame1
    if not chatFrame1 then return end

    ConfigureGeneral(chatFrame1)

    ConfigureGlobalChat()

    SelectGeneralTab()
    C_Timer.After(0.1, SelectGeneralTab)
    C_Timer.After(0.5, SelectGeneralTab)

    ApplyPositionWithRetries(chatFrame1)

    EnableAllClassColors()

    HookEditModeRestore()
    WatchChatPinDrift()

    InitSocialButtonPositioning()

    _FluxUI_CharSavedVars.fluxChatConfigured = true

    print("|cff00ffff[FluxChatFrame]|r Chat configured for this character.")
end

-- ---------------------------------------------------------------------------
-- EVENT HANDLING
-- ---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

local hasRun = false

-- Zone/global channels populate after login; refresh Global Chat when the client reports channel changes.
-- Pre-DF: also re-disable globals on General — the engine can re-add them when channels update.
local channelRefreshFrame = CreateFrame("Frame")
if FluxSafeRegisterEvent and FluxSafeRegisterEvent(channelRefreshFrame, "CHANNEL_COUNT_UPDATE") then
    channelRefreshFrame:SetScript("OnEvent", function()
        if not (_FluxUI_CharSavedVars and _FluxUI_CharSavedVars.fluxChatConfigured) then return end
        if FLUX_API and FLUX_API.isPreDF then
            DisableGlobalChannelsOnGeneral()
        end
        local f = fluxGlobalChatFrame or FindGlobalChatFrame()
        if f then
            ConfigureGlobalChannels(f)
        end
    end)
end

-- Zone changes can alter which channels are available; refresh Global Chat and
-- re-disable globals on General (pre-DF). Position is NOT re-applied here.
local fluxChatPewFrame = CreateFrame("Frame")
if FluxSafeRegisterEvent and FluxSafeRegisterEvent(fluxChatPewFrame, "PLAYER_ENTERING_WORLD") then
    fluxChatPewFrame:SetScript("OnEvent", function()
        -- Social/channel nudge must run even when Flux chat layout was never saved (fluxChatConfigured).
        InitSocialButtonPositioning()
        if not (_FluxUI_CharSavedVars and _FluxUI_CharSavedVars.fluxChatConfigured) then
            return
        end
        if FLUX_API and FLUX_API.isPreDF then
            C_Timer.After(0.5, DisableGlobalChannelsOnGeneral)
        end
        local gf = fluxGlobalChatFrame or FindGlobalChatFrame()
        if gf then
            C_Timer.After(1.5, function()
                ConfigureGlobalChannels(gf)
            end)
        end
    end)
end

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        -- ExtraAction / UIParent parks chat on combat enter. Put the last
        -- placement back. Measuring again slides the frame.
        if _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.fluxChatConfigured then
            if not RestoreLastChatPin(ChatFrame1) then
                ApplyPosition(ChatFrame1)
            end
        end
        return
    end

    if hasRun then return end

    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            if not hasRun then
                hasRun = true
                RunConfiguration()
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            if not hasRun then
                hasRun = true
                RunConfiguration()
            end
        end)
    end
end)

