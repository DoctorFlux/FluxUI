local addonName, ns = ...

FluxLayoutPreviewUI = FluxLayoutPreviewUI or {}
local UI = FluxLayoutPreviewUI

-- ── Preview canvas: normalized rects (0-1); pixel scale uses UI.previewW/H (set per DrawPreview).
local DEFAULT_PREVIEW_W, DEFAULT_PREVIEW_H = 380, 300
local PAD = 10

UI.previewW = DEFAULT_PREVIEW_W
UI.previewH = DEFAULT_PREVIEW_H

local function SyncPreviewDimensionsFromCanvas()
    local canvas = UI.canvas
    if not canvas then
        UI.previewW = DEFAULT_PREVIEW_W
        UI.previewH = DEFAULT_PREVIEW_H
        return UI.previewW, UI.previewH
    end
    local w, h = canvas:GetWidth(), canvas:GetHeight()
    if not w or w < 2 then
        w = DEFAULT_PREVIEW_W
    end
    if not h or h < 2 then
        h = DEFAULT_PREVIEW_H
    end
    UI.previewW = w
    UI.previewH = h
    return w, h
end
local BG_COLOR = { 0.08, 0.08, 0.10, 1 }

--- Ace sometimes stores select values as strings; layout math uses numeric compares (micro 2 = chat column, etc.).
local function LayoutPosToNumber(v, default)
    if v == nil then
        return default
    end
    local n = tonumber(v)
    if n and n == n then
        return math.floor(n)
    end
    return default
end

-- ── Element colors (r, g, b) ────────────────────────────────────────────────
local COLORS = {
    microMenu    = { 0.30, 0.70, 1.00 },
    statusBar    = { 1.00, 0.75, 0.25 },
    player       = { 0.30, 0.90, 0.40 },
    target       = { 0.90, 0.30, 0.30 },
    stanceBar    = { 0.80, 0.50, 1.00 },
    petBar       = { 0.55, 0.85, 0.95 },
    actionBar    = { 0.45, 0.45, 0.50 },
    chat         = { 0.40, 0.40, 0.45 },
    minimap      = { 0.40, 0.40, 0.45 },
    fluxWindow   = { 0.55, 0.55, 0.70 },
    raidStack    = { 0.50, 0.65, 0.90 },
    actionStrip  = { 0.25, 0.28, 0.32 },
    focus        = { 0.95, 0.45, 0.20 },
    pvpObjective = { 0.35, 0.82, 0.45 },
    talkingHead  = { 0.92, 0.68, 0.28 },
    infoFrame    = { 0.70, 0.85, 1.00 },
}

local ACTIVE_ALPHA    = 0.85
local GHOST_ALPHA     = 0.22
local SELECTED_ALPHA  = 1.0
local REFERENCE_ALPHA = 0.35
-- While a layout control is selected, other movable tiles fade so alternate (ghost) zones are easier to see.
local PLACEMENT_MODE_OTHER_ALPHA = 0.28

-- ── Approximate proportional rectangles (fraction of canvas) ────────────────
-- These are schematic positions, not pixel-accurate replicas.
-- { xFrac, yFrac, wFrac, hFrac } where (0,0) = top-left of canvas.

-- Fallback fractions when game frames are not available (e.g. options open before login).
-- Chat / micro-beside-chat / raid are derived from action strip in GetChatAreaSchematics (flush left, no gap to strip).
local REF_RECTS = {
    minimap    = { 0.84, 0.02, 0.14, 0.22 },
}

-- Flux window (schematic). Action strip width is derived: left screen edge to just before window (UnifiedBorder.lua).
local FALLBACK_STRIP = {
    fluxWindow   = { 0.74, 0.48, 0.24, 0.42 },
}
do
    local fw = FALLBACK_STRIP.fluxWindow
    local stripLeft, gap = 0, 0.01
    FALLBACK_STRIP.unifiedStrip = {
        stripLeft,
        0.74,
        math.max(0.05, fw[1] - stripLeft - gap),
        0.16,
    }
end

-- ── Live frame -> canvas fractions (matches in-game layout when frames exist) ──

local function FrameToCanvasFrac(frame)
    if not frame or not frame.IsShown or not frame:IsShown() then
        return nil
    end
    if not frame.GetScaledRect or not UIParent or not UIParent.GetScaledRect then
        return nil
    end
    local ok, l, b, w, h = pcall(frame.GetScaledRect, frame)
    if not ok or not l or not b or not w or not h or w < 2 or h < 2 then
        return nil
    end
    local okp, ul, ub, uw, uh = pcall(UIParent.GetScaledRect, UIParent)
    if not okp or not uw or not uh or uw < 1 or uh < 1 then
        return nil
    end
    local leftFrac = (l - ul) / uw
    local widthFrac = w / uw
    local heightFrac = h / uh
    local yFromTopFrac = 1 - (b - ub) / uh - heightFrac
    leftFrac = math.max(0, math.min(1, leftFrac))
    yFromTopFrac = math.max(0, math.min(1, yFromTopFrac))
    widthFrac = math.max(0.008, math.min(1, widthFrac))
    heightFrac = math.max(0.008, math.min(1, heightFrac))
    return { leftFrac, yFromTopFrac, widthFrac, heightFrac }
end

local function Rect4(rect)
    if not rect then return nil end
    return { rect[1], rect[2], rect[3], rect[4] }
end

local function ResolveRect(fallback, frame)
    local live = FrameToCanvasFrac(frame)
    if live then
        return live
    end
    return Rect4(fallback)
end

--- Collect ExtraButtonSystem / ActionBar / Raid frames (same sources as UnifiedBorder.lua GetComponents).
local function GetLiveFrameBundle()
    local nc = FluxNonCombatAPI and FluxNonCombatAPI.DefaultGrid and FluxNonCombatAPI.DefaultGrid.Frame
    local cg = FluxCombatManager and FluxCombatManager.Grid and FluxCombatManager.Grid.Frame
    local ab = _G.FluxMainActionBar
    local info = FluxInfoFrame and FluxInfoFrame.GetFrame and FluxInfoFrame:GetFrame()
    local tm = FluxTrinketMenu and FluxTrinketMenu.Frame
    local win = FluxWindowFrame and FluxWindowFrame.GetFrame and FluxWindowFrame:GetFrame()
    local ub = _G.FluxUnifiedBorderFrame
    local raid = _G.FluxRaidContainer
    local party = _G.CompactPartyFrame
    local stance = _G.FluxStanceBar
    local pet = _G.FluxPetBar
    local mm = _G.FluxMicroMenu
    local sb = _G.FluxStatusBarContainer
    local map = _G.Minimap
    local chat = _G.ChatFrame1
    local focusF = _G.FluxFocusFrame
    local pvpObj = _G.UIWidgetTopCenterContainerFrame
    return {
        ncGrid = nc,
        combatGrid = cg,
        actionBar = ab,
        infoFrame = info,
        trinketMenu = tm,
        fluxWindow = win,
        unifiedStrip = ub,
        raidStack = raid,
        partyFrame = party,
        stanceBar = stance,
        petBar = pet,
        microMenu = mm,
        statusBar = sb,
        minimap = map,
        chat = chat,
        fluxFocus = focusF,
        pvpObjective = pvpObj,
    }
end

--- Axis-aligned union of strip widgets, extended to Flux window left when possible (matches UnifiedBorder: NC left -> window left).
local STRIP_COMPONENT_KEYS = { "ncGrid", "combatGrid", "actionBar", "infoFrame", "trinketMenu" }

local function ExtendStripRectToFluxWindowLeft(rect, bundle)
    if not rect or not bundle then
        return rect
    end
    local wf = bundle.fluxWindow
    if not wf or not wf.IsShown or not wf:IsShown() then
        return rect
    end
    local wr = FrameToCanvasFrac(wf)
    if not wr then
        return rect
    end
    local winLeft = wr[1]
    local gap = 0.002
    local targetRight = math.max(0, winLeft - gap)
    local left = rect[1]
    local right = left + rect[3]
    if targetRight > right then
        return { left, rect[2], math.max(0.008, targetRight - left), rect[4] }
    end
    return rect
end

local function ComputeActionStripUnionRect(bundle)
    -- Prefer FluxUnifiedBorderFrame: in-game it spans NonCombatGrid left -> FluxWindowFrame left (not just NC...trinket union).
    local ub = bundle.unifiedStrip
    if ub and ub.IsShown and ub:IsShown() then
        local r = FrameToCanvasFrac(ub)
        if r then
            return r, true
        end
    end

    local parts = {}
    for _, key in ipairs(STRIP_COMPONENT_KEYS) do
        local f = bundle[key]
        local r = FrameToCanvasFrac(f)
        if r then
            parts[#parts + 1] = r
        end
    end

    if #parts >= 1 then
        local minL, minT = 1, 1
        local maxR, maxB = 0, 0
        for _, r in ipairs(parts) do
            local l, t, w, h = r[1], r[2], r[3], r[4]
            minL = math.min(minL, l)
            minT = math.min(minT, t)
            maxR = math.max(maxR, l + w)
            maxB = math.max(maxB, t + h)
        end
        minL = math.max(0, minL)
        minT = math.max(0, minT)
        maxR = math.min(1, maxR)
        maxB = math.min(1, maxB)
        local wf = math.max(0.008, maxR - minL)
        local hf = math.max(0.008, maxB - minT)
        local merged = ExtendStripRectToFluxWindowLeft({ minL, minT, wf, hf }, bundle)
        return merged, true
    end

    return Rect4(FALLBACK_STRIP.unifiedStrip), false
end

local ELEMENT_POSITIONS = {
    microMenu = {
        [1] = { 0.01, 0.02, 0.35, 0.06, "Top bar" },
        -- [2] rect computed from chat column (same height, flush left of chat, 0 gap); keep label for tooltips
        [2] = { 0, 0, 0, 0, "Beside chat" },
        -- [3] rect from minimap (dock TOPRIGHT = Minimap TOPRIGHT; strip extends left along map edge)
        [3] = { 0, 0, 0, 0, "Beside minimap" },
    },
    statusBar = {
        [1] = { 0.01, 0.08, 0.35, 0.04, "Top-left / under micro" },
        -- [2] rect from action strip (full width, flush on strip top); keep label
        [2] = { 0, 0, 0, 0, "Above action bar" },
        [3] = { 0.00, 0.96, 1.00, 0.04, "Screen bottom" },
    },
    playerTarget = {
        [1] = { nil },
        [2] = { nil },
    },
    stanceBar = {
        [1] = { nil },
        [2] = { nil },
    },
}

-- Chat column: bottom meets action strip top (0 vertical gap). When micro is pos 2, narrow micro strip [0,microW) then chat; otherwise chat uses full width (microW+chatW) flush left.
local PREVIEW_CHAT_H = 0.32
local PREVIEW_RAID_H = 0.16
local MICRO_BESIDE_CHAT_W = 0.04
local CHAT_COLUMN_W = 0.20

local function GetChatAreaSchematics(stripRect, microMenuPosition)
    local stripTop = (stripRect and stripRect[2]) or FALLBACK_STRIP.unifiedStrip[2]
    local ch = PREVIEW_CHAT_H
    local cy = stripTop - ch
    cy = math.max(0.02, cy)
    local microW = MICRO_BESIDE_CHAT_W
    local chatW = CHAT_COLUMN_W
    local totalW = microW + chatW
    local rh = PREVIEW_RAID_H
    local microBeside = { 0, cy, microW, ch, ELEMENT_POSITIONS.microMenu[2][5] }
    local chat
    if microMenuPosition == 2 then
        chat = { microW, cy, chatW, ch }
    else
        chat = { 0, cy, totalW, ch }
    end
    local raid = { 0, cy - rh, totalW, rh }
    return chat, microBeside, raid
end

-- Schematic focus (fractions of canvas). Live rect preferred when Flux focus exists and is shown.
local PREVIEW_FOCUS_W_FRAC = 0.10
local PREVIEW_FOCUS_H_FRAC = 0.09
local FOCUS_SCHEM_GAP = 0.008

local function GetUnitFramePreviewDB()
    if FluxOptions and FluxOptions.GetUnitFrameDB then
        return FluxOptions:GetUnitFrameDB()
    end
    return nil
end

local function FluxFocusShownInPreview()
    local uf = GetUnitFramePreviewDB()
    if uf and uf.useFluxFocus == false then
        return false
    end
    if FLUX_API and FLUX_API.hasFocusUnit == false then
        return false
    end
    return true
end

local function GetFocusSchematicRect(chatSch, raidSch, playerTargetMode)
    local fw, fh = PREVIEW_FOCUS_W_FRAC, PREVIEW_FOCUS_H_FRAC
    local fx, fy
    if playerTargetMode == 2 and raidSch then
        local rx, ry, rw = raidSch[1], raidSch[2], raidSch[3]
        fy = ry - fh - FOCUS_SCHEM_GAP
        fx = rx + rw - fw - 0.01
    else
        local cx, cy, cw = chatSch[1], chatSch[2], chatSch[3]
        fx = cx + cw + 0.008
        fy = cy
    end
    fx = math.max(0.02, math.min(1 - fw - 0.01, fx))
    fy = math.max(0.02, math.min(0.88, fy))
    return { fx, fy, fw, fh }
end

-- Minimap layout 3: dock TOPRIGHT = Minimap TOPRIGHT (FluxMicroMenu.lua). Height = minimap height.
-- Preview always shows collapsed dock (chevron only, micro hidden) - matches in-game strip when not expanded.
local MINIMAP_STRIP_TOGGLE_W_PX = 22

local function GetMicroMenuMinimapStripSchematicRect(minimapRect)
    local m = minimapRect or REF_RECTS.minimap
    local pw = UI.previewW or DEFAULT_PREVIEW_W
    local w = MINIMAP_STRIP_TOGGLE_W_PX / pw
    if not m then
        return { 0.87, 0.02, w, 0.22, ELEMENT_POSITIONS.microMenu[3][5] }
    end
    local mx, my, mw, mh = m[1], m[2], m[3], m[4]
    local right = mx + mw
    local sx = right - w
    if sx < 0.01 then
        sx = 0.01
    end
    return { sx, my, w, mh, ELEMENT_POSITIONS.microMenu[3][5] }
end

local function GetMicroMenuSchematicRect(pos, microBesideSch, minimapRect)
    if pos == 2 then
        return microBesideSch
    end
    if pos == 3 then
        return GetMicroMenuMinimapStripSchematicRect(minimapRect)
    end
    return ELEMENT_POSITIONS.microMenu[pos]
end

--- Location 1: under horizontal micro or top-left. Location 2: same width/x as action strip, flush on strip (0 gap). Location 3: full width bottom.
local PREVIEW_STATUSBAR_H = 0.04
--- Nominal height used when the info tile is not filling a status-bar cell.
local PREVIEW_INFO_FRAME_H_FRAC = 0.065

local function NormalizeInfoFramePlacement(v)
    if v == "topLeft" then
        return "actionStrip"
    end
    if v == "statusIntegrated" or v == "minimapTop" or v == "screenTopLeft" then
        return v
    end
    return "actionStrip"
end

local function PreviewInfoStatusSlot()
    if FluxOptions and FluxOptions.GetInfoStatusSlot then
        return FluxOptions:GetInfoStatusSlot()
    end
    return "start"
end

local function GetStatusBarSchematicRect(statusPos, microMenuPosition, stripRect, infoFramePlacement)
    if statusPos == 2 then
        if stripRect then
            local sh = PREVIEW_STATUSBAR_H
            local sy = stripRect[2] - sh
            return { stripRect[1], sy, stripRect[3], sh, ELEMENT_POSITIONS.statusBar[2][5] }
        end
        return { 0.20, 0.84, 0.60, PREVIEW_STATUSBAR_H, ELEMENT_POSITIONS.statusBar[2][5] }
    end
    if statusPos == 3 then
        return ELEMENT_POSITIONS.statusBar[3]
    end
    local s = ELEMENT_POSITIONS.statusBar[1]
    if microMenuPosition == 1 then
        return s
    end
    return { s[1], 0.02, s[3], s[4], s[5] }
end

-- PVP / scenario top objective (UIWidgetTopCenterContainerFrame). FluxPVPObjectiveMover: under micro (status 2/3 + horizontal micro),
-- top-centered + offset (status 2/3 + vertical/minimap micro), or under status bar (location 1) - always use schematic position from layout (not live frame rect: live is tiny and lags layout).
local PREVIEW_PVP_OBJ_W_FRAC = 0.24
local PREVIEW_PVP_OBJ_H_FRAC = 0.082
local PVP_OBJ_BELOW_GAP = 0.012
-- Status 2/3 + micro 2/3: mover uses GetVirtualHorizontalMenuCenterOffsetX() - aligns with the *virtual horizontal menu column* (left of screen center), not UIParent top-center (which stacks on the classic target).
local PREVIEW_PVP_VIRTUAL_MENU_CENTER_X_FRAC = 0.13

local function GetPVPObjectiveSchematicRect(pos, stripRect, microMenuSch, statusBarSch)
    local nw, nh = PREVIEW_PVP_OBJ_W_FRAC, PREVIEW_PVP_OBJ_H_FRAC
    local gap = PVP_OBJ_BELOW_GAP
    if pos.playerTarget == 2 then
        return { (1 - nw) / 2, 0.01, nw, nh }
    end
    local st, mm = pos.statusBar, pos.microMenu
    local mr = microMenuSch and Rect4(microMenuSch)
    local sbr = statusBarSch and Rect4(statusBarSch)

    -- Status 2 or 3: under horizontal micro when micro is top bar; else virtual menu column (FluxPVPObjectiveMover), not screen middle.
    if st == 2 or st == 3 then
        if mm == 1 then
            local mrect = mr or Rect4(ELEMENT_POSITIONS.microMenu[1])
            if mrect then
                local cx = mrect[1] + mrect[3] / 2 - nw / 2
                local oy = mrect[2] + mrect[4] + gap
                return { math.max(0.02, cx), math.min(0.90, oy), nw, nh }
            end
        end
        local cx = PREVIEW_PVP_VIRTUAL_MENU_CENTER_X_FRAC - nw / 2
        return { math.max(0.02, cx), 0.01, nw, nh }
    end

    -- Status location 1: under Flux status bar (in-game TOP of objective to status BOTTOM - center on status width, not micro column).
    if sbr then
        local sy = sbr[2] + sbr[4] + gap
        local cx = sbr[1] + sbr[3] / 2 - nw / 2
        return { math.max(0.02, cx), math.min(0.92, sy), nw, nh }
    end
    local sr = GetStatusBarSchematicRect(st, mm, stripRect, pos.infoFramePlacement)
    local sr4 = Rect4(sr)
    if sr4 then
        local sy = sr4[2] + sr4[4] + gap
        local cx = sr4[1] + sr4[3] / 2 - nw / 2
        return { math.max(0.02, cx), math.min(0.92, sy), nw, nh }
    end
    return { 0.5 - nw / 2, 0.12, nw, nh }
end

-- Native TalkingHeadFrame is 570x155; FluxTalkingHead uses SetScale(0.75). Retail-only reference tile.
local PREVIEW_TALKING_HEAD_W_FRAC = 0.22
local PREVIEW_TALKING_HEAD_H_FRAC = 0.11
local TALKING_HEAD_BELOW_GAP = 0.008

local function PreviewHasTalkingHead()
    local Flux = ns and ns.Flux
    local Cap = Flux and Flux.Cap
    if Cap and Cap.hasTalkingHead ~= nil then
        return Cap.hasTalkingHead == true
    end
    local Client = Flux and Flux.Client
    if Client and Client.isRetail then
        return true
    end
    return FLUX_API and FLUX_API.isRetail == true
end

--- Same stacking as FluxTalkingHead: top-left, or left-aligned under pos-1 micro and/or status.
local function GetTalkingHeadSchematicRect(pos, microMenuSch, statusBarSch)
    local nw, nh = PREVIEW_TALKING_HEAD_W_FRAC, PREVIEW_TALKING_HEAD_H_FRAC
    local gap = TALKING_HEAD_BELOW_GAP
    local st, mm = pos.statusBar, pos.microMenu
    if st == 1 then
        local sbr = statusBarSch and Rect4(statusBarSch)
        if sbr then
            return { sbr[1], math.min(0.88, sbr[2] + sbr[4] + gap), nw, nh }
        end
    end
    if mm == 1 then
        local mr = microMenuSch and Rect4(microMenuSch) or Rect4(ELEMENT_POSITIONS.microMenu[1])
        if mr then
            return { mr[1], math.min(0.88, mr[2] + mr[4] + gap), nw, nh }
        end
    end
    return { 0.01, 0.02, nw, nh }
end

--- Fractional rect for Info frame on the canvas for a given placement mode (preview + interactive ghosts).
local function GetInfoFramePlacementPreviewRect(placement, pos, stripRect, microMenuSch, minimapSch)
    local h = PREVIEW_INFO_FRAME_H_FRAC
    local ip = NormalizeInfoFramePlacement(placement)
    if ip == "actionStrip" then
        local sr = stripRect and Rect4(stripRect)
        if sr then
            local iw = math.min(0.20, math.max(sr[3] * 0.18, 0.08))
            local ih = math.max(sr[4] * 0.82, 0.045)
            local ix = sr[1] + sr[3] * 0.36
            return { ix, sr[2], iw, ih }
        end
        return { 0.36, 0.68, 0.16, 0.09 }
    end
    if ip == "minimapTop" then
        local m = Rect4(minimapSch) or Rect4(REF_RECTS.minimap)
        if not m then
            return { 0.848, 0.028, 0.124, h }
        end
        local pad = 0.01
        local innerW = math.max(0.06, m[3] - 2 * pad)
        local top = m[2] + pad
        return { m[1] + pad, top, innerW, h }
    end
    if ip == "screenTopLeft" then
        return { 0.012, 0.012, 0.11, 0.09 }
    end
    -- statusIntegrated: one cell inside the status row. Horizontal bars use left/center/right;
    -- the stacked top-left status bar uses the same slot as top / middle / bottom.
    local slot = PreviewInfoStatusSlot()
    local st, mm = pos.statusBar, pos.microMenu
    local sbr = GetStatusBarSchematicRect(st, mm, stripRect, pos.infoFramePlacement)
    if sbr then
        local x, y, w, sh = sbr[1], sbr[2], sbr[3], sbr[4]
        if st == 2 or st == 3 then
            local colFrac = 0.24
            local iw = math.max(0.04, w * colFrac)
            local ix = x
            if slot == "middle" then
                ix = x + (w - iw) / 2
            elseif slot == "end" then
                ix = x + w - iw
            end
            return { ix, y, iw, sh }
        end
        local bandH = math.min(sh, math.max(0.018, h * 0.45))
        local iy = y
        if slot == "middle" then
            iy = y + math.max(0, (sh - bandH) / 2)
        elseif slot == "end" then
            iy = y + math.max(0, sh - bandH)
        end
        return { x, iy, w, bandH }
    end
    return { 0.02, 0.02, 0.18, h }
end

-- Schematic sizes (fractions of canvas). Classic player: screen-centered horizontally, just above the action strip.
local PREVIEW_PLAYER_W, PREVIEW_PLAYER_H = 0.17, 0.12
local PREVIEW_TARGET_W, PREVIEW_TARGET_H = 0.17, 0.12
-- Stance / pet: narrow vertical strips (tall, small width) like in-game columns beside player or window.
local PREVIEW_VERT_STRIP_W = 0.030
local PREVIEW_STANCE_H = 0.095 -- schematic fallback height when player rect missing
local PREVIEW_ABOVE_STRIP_GAP = 0.012

-- Player/target: when status is location 2, stack is strip -> status (0 gap) -> player (0 gap). Otherwise small gap above strip only.
-- Mode 1 (classic): player horizontally centered on the full screen, not on the action strip.
local function GetPlayerTargetRects(mode, stripRect, statusBarPosition)
    local st = stripRect and stripRect[2] or 0.74
    local pw, ph = PREVIEW_PLAYER_W, PREVIEW_PLAYER_H
    local py
    if statusBarPosition == 2 then
        local statusTop = st - PREVIEW_STATUSBAR_H
        py = statusTop - ph
    else
        py = st - PREVIEW_ABOVE_STRIP_GAP - ph
    end
    if py < 0.02 then
        py = 0.02
    end

    if mode == 2 then
        local seam = 0.02
        return {
            player = { 0.5 - pw - seam * 0.5, py, pw, ph },
            target = { 0.5 + seam * 0.5, py, pw, ph },
        }
    end
    local px = 0.5 - pw * 0.5
    px = math.max(0.02, math.min(1 - pw - 0.02, px))
    return {
        player = { px, py, pw, ph },
        target = { 0.5 - PREVIEW_TARGET_W * 0.5, 0.06, PREVIEW_TARGET_W, PREVIEW_TARGET_H },
    }
end

--- Height from Flux window top down to the HUD anchor above the action strip (top of status row when status is location 2, else strip top).
local function GetFluxWindowStackStripSpan(fluxWindowRect, stripRect, statusBarPosition)
    local fw = fluxWindowRect or FALLBACK_STRIP.fluxWindow
    local stripTop = (stripRect and stripRect[2]) or FALLBACK_STRIP.unifiedStrip[2]
    local anchorY = stripTop
    if statusBarPosition == 2 then
        anchorY = stripTop - PREVIEW_STATUSBAR_H
    end
    local winTop = fw[2]
    local h = anchorY - winTop
    if h < 0.03 then
        h = math.max(0.06, (FALLBACK_STRIP.unifiedStrip[2] - FALLBACK_STRIP.fluxWindow[2]))
    end
    return winTop, h
end

--- Stance 1: flush left of player, same height as player (vertical strip). Stance 2: strip from window top to stack above strip (same span as pet).
local function GetStanceBarSchematicRect(stancePos, playerRect, fluxWindowRect, stripRect, statusBarPosition)
    local fw = fluxWindowRect or FALLBACK_STRIP.fluxWindow
    local gapWin = 0.006
    local sw = PREVIEW_VERT_STRIP_W
    if stancePos == 2 then
        local sy, sh = GetFluxWindowStackStripSpan(fluxWindowRect, stripRect, statusBarPosition)
        local sx = fw[1] - gapWin - sw
        return { math.max(0.02, sx), sy, sw, sh }
    end
    if not playerRect then
        return { 0.28, 0.62, PREVIEW_VERT_STRIP_W, PREVIEW_STANCE_H }
    end
    local sh = playerRect[4]
    local sx = playerRect[1] - sw
    local sy = playerRect[2]
    return { math.max(0.02, sx), sy, sw, sh }
end

--- Pet: same strip width as stance. Height always matches stance-at-window (window top -> stack above strip), regardless of stance placement.
local function GetPetBarSchematicRect(fluxWindowRect, stancePlacement, stanceSchematicRect, stripRect, statusBarPosition)
    local fw = fluxWindowRect or FALLBACK_STRIP.fluxWindow
    local gapWin = 0
    local pw = PREVIEW_VERT_STRIP_W
    local sy, ph = GetFluxWindowStackStripSpan(fluxWindowRect, stripRect, statusBarPosition)
    local rightEdge = fw[1] - gapWin
    if stancePlacement == 2 and stanceSchematicRect then
        rightEdge = stanceSchematicRect[1] - gapWin
    end
    local sx = rightEdge - pw
    return { math.max(0.02, sx), math.max(0.02, sy), pw, ph }
end

-- Ghost rects for player/target modes (same strip-relative rules).
local function GetPlayerTargetGhostRects(mode, stripRect, statusBarPosition)
    local alt = (mode == 1) and 2 or 1
    local rects = GetPlayerTargetRects(alt, stripRect, statusBarPosition)
    return {
        [alt] = {
            player = rects.player,
            target = rects.target,
            label = (alt == 2) and "Side by side" or "Classic",
        },
    }
end

-- Ghost rects for stance bar (alternate placement).
local function GetStanceBarGhostRects(currentStance, playerRect, fluxWindowRect, stripRect, statusBarPosition)
    local ghosts = {}
    local fw = fluxWindowRect or FALLBACK_STRIP.fluxWindow
    if currentStance ~= 1 then
        local r = GetStanceBarSchematicRect(1, playerRect, fw, stripRect, statusBarPosition)
        ghosts[1] = { r[1], r[2], r[3], r[4], "Beside player" }
    end
    if currentStance ~= 2 then
        local r = GetStanceBarSchematicRect(2, playerRect, fw, stripRect, statusBarPosition)
        ghosts[2] = { r[1], r[2], r[3], r[4], "Left of window" }
    end
    return ghosts
end

-- ── DB helpers ───────────────────────────────────────────────────────────────

local function GetDB()
    if FluxOptions and FluxOptions.GetLayoutDB then
        return FluxOptions:GetLayoutDB()
    end
    return nil
end

local function ReadPositions()
    local db = GetDB()
    local ip = NormalizeInfoFramePlacement(db and db.infoFramePlacement or "actionStrip")
    return {
        microMenu          = LayoutPosToNumber(db and db.microMenuPosition, 2),
        statusBar          = LayoutPosToNumber(db and db.statusBarPosition, 3),
        playerTarget       = LayoutPosToNumber(db and db.playerTargetPlacement, 2),
        stanceBar          = LayoutPosToNumber(db and db.stanceBarPlacement, 1),
        microColumns       = LayoutPosToNumber(db and db.microMenuBesideChatColumns, 2),
        infoFramePlacement = ip,
    }
end

local function ApplyPosition(key, value)
    local db = GetDB()
    if not db then return end

    if key == "microMenu" then
        db.microMenuPosition = value
    elseif key == "statusBar" then
        db.statusBarPosition = value
    elseif key == "playerTarget" then
        db.playerTargetPlacement = value
    elseif key == "stanceBar" then
        db.stanceBarPlacement = value
    elseif key == "infoFrame" then
        db.infoFramePlacement = NormalizeInfoFramePlacement(value)
    end

    if FluxOptions and FluxOptions.RefreshLayoutDependents then
        FluxOptions:RefreshLayoutDependents()
    end

    local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if ACR then
        ACR:NotifyChange("FluxUI")
    end
end

-- ── Frame pool / recycling ──────────────────────────────────────────────────

local allBoxes = {}
local allGhosts = {}

local LEVEL_REFERENCE = 2
-- Interactive hit layers: ghosts (alternate placements) must sit above other controls or clicks feel random.
local LEVEL_INTERACTIVE_BACK = 6   -- another control is selected - sinks below ghosts
local LEVEL_INTERACTIVE = 11       -- normal, nothing selected
local LEVEL_INTERACTIVE_SELECTED = 14
--- Info FPS left cell overlaps the full-width Status Bar schematic - must stack above it for clicks (below ghosts at 26).
local LEVEL_INFO_OVER_STATUS_BAR_SCHEMATIC = 23
local LEVEL_GHOST_TOP = 26         -- alternate zones always receive clicks first
local LEVEL_ACTIVE = 8           -- initial PlaceBox; overridden for interactives/ghosts below

local function HideAll(pool)
    for _, f in ipairs(pool) do
        f:Hide()
        f:ClearAllPoints()
    end
end

local function GetOrCreateBox(parent, idx)
    if allBoxes[idx] then
        allBoxes[idx]:SetParent(parent)
        return allBoxes[idx]
    end
    local f = CreateFrame("Button", nil, parent)
    f:SetFrameLevel(parent:GetFrameLevel() + LEVEL_ACTIVE)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.border = f:CreateTexture(nil, "BORDER")
    f.border:SetPoint("TOPLEFT", -1, 1)
    f.border:SetPoint("BOTTOMRIGHT", 1, -1)
    f.border:SetColorTexture(1, 1, 1, 0.5)
    f.label = f:CreateFontString(nil, "OVERLAY")
    f.label:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    f.label:SetPoint("CENTER")
    f.label:SetJustifyH("CENTER")
    f.label:SetJustifyV("MIDDLE")
    allBoxes[idx] = f
    return f
end

local function GetOrCreateGhost(parent, idx)
    if allGhosts[idx] then
        allGhosts[idx]:SetParent(parent)
        return allGhosts[idx]
    end
    local f = CreateFrame("Button", nil, parent)
    f:SetFrameLevel(parent:GetFrameLevel() + LEVEL_ACTIVE)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.border = f:CreateTexture(nil, "BORDER")
    f.border:SetPoint("TOPLEFT", -1, 1)
    f.border:SetPoint("BOTTOMRIGHT", 1, -1)
    f.label = f:CreateFontString(nil, "OVERLAY")
    f.label:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    f.label:SetPoint("CENTER")
    f.label:SetJustifyH("CENTER")
    f.label:SetJustifyV("MIDDLE")
    allGhosts[idx] = f
    return f
end

-- ── Tooltip helpers ─────────────────────────────────────────────────────────

local ELEMENT_TOOLTIPS = {
    microMenu = {
        title = "Micro Menu",
        [1] = "Top-left row.",
        [2] = "Vertical strip left of chat.",
        [3] = "Docked on minimap.",
    },
    statusBar = {
        title = "Status Bar",
        [1] = "Top-left, under micro when possible.",
        [2] = "Full width above action bar.",
        [3] = "Full width at screen bottom.",
    },
    playerTarget = {
        title = "Player / Target",
        [1] = "Classic: target top center, player above strip.",
        [2] = "Side by side above strip.",
    },
    stanceBar = {
        title = "Stance Bar",
        [1] = "Left of player frame.",
        [2] = "Vertical strip left of Flux window.",
    },
    infoFrame = {
        title = "Info (FPS / ping)",
        actionStrip = "In the bottom button strip.",
        statusIntegrated = "In the status bar row.",
        minimapTop = "Inside minimap top edge.",
        screenTopLeft = "Own panel at the top-left of the screen.",
    },
}

local function ShowBoxTooltip(box, elementKey, posValue)
    local info = ELEMENT_TOOLTIPS[elementKey]
    if not info then return end
    GameTooltip:SetOwner(box, "ANCHOR_RIGHT")
    GameTooltip:AddLine(info.title, 1, 1, 1)
    if posValue ~= nil and info[posValue] then
        GameTooltip:AddLine(info[posValue], 0.7, 0.7, 0.7, true)
    end
    GameTooltip:AddLine("Click to move.", 0.5, 0.8, 1.0)
    GameTooltip:Show()
end

local function ShowGhostTooltip(ghost, elementKey, posValue)
    local info = ELEMENT_TOOLTIPS[elementKey]
    if not info then return end
    GameTooltip:SetOwner(ghost, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Move here", 1, 1, 1)
    if posValue ~= nil and info[posValue] then
        GameTooltip:AddLine(info[posValue], 0.7, 0.7, 0.7, true)
    end
    GameTooltip:Show()
end

local REF_TOOLTIPS = {
    actionStrip = {
        "Action strip",
        "Utility buttons, bar, info, trinkets.",
    },
    fluxWindow  = { "Flux window", "Map / Details window." },
    raidStack   = { "Raid / party", "Above chat." },
    petBar      = { "Pet bar", "Beside Flux window." },
    minimap     = { "Minimap", "Game minimap." },
    chat        = { "Chat", "Chat frame." },
    focusFrame  = {
        "Focus",
        "Beside chat, or above raid in side-by-side mode.",
    },
    pvpObjective = {
        "PVP objective",
        "Scenario / M+ tracker.",
    },
    talkingHead = {
        "Talking Head",
        "Quest / cinematic speaker at 75% scale. Top-left, or under micromenu and/or status when either is at position 1.",
    },
}

local function ShowRefTooltip(box, key)
    local t = REF_TOOLTIPS[key]
    if not t then return end
    GameTooltip:SetOwner(box, "ANCHOR_RIGHT")
    GameTooltip:AddLine(t[1], 1, 1, 1)
    GameTooltip:AddLine(t[2], 0.75, 0.75, 0.75, true)
    local live = box._fluxLiveRect
    if live then
        GameTooltip:AddLine("|cff888888Live position|r", 0.5, 0.9, 0.5)
    elseif key == "pvpObjective" or key == "talkingHead" then
        GameTooltip:AddLine("|cff888888Preview only|r", 0.55, 0.75, 0.6)
    else
        GameTooltip:AddLine("|cff888888Preview only|r", 0.7, 0.7, 0.5)
    end
    GameTooltip:Show()
end

-- ── Selection state ─────────────────────────────────────────────────────────

UI.selectedElement = nil

local function Deselect()
    UI.selectedElement = nil
    if UI.canvas then
        UI:DrawPreview()
    end
end

-- ── Micro columns slider ────────────────────────────────────────────────────

local function EnsureColumnsSlider(parent)
    if UI.columnsSlider then
        UI.columnsSlider:SetParent(parent)
        return UI.columnsSlider
    end

    local slider = CreateFrame("Slider", "FluxLayoutPreviewColumnsSlider", parent, "OptionsSliderTemplate")
    slider:SetSize(180, 16)
    slider:SetMinMaxValues(1, 8)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)

    slider.Low = slider.Low or _G[slider:GetName() .. "Low"]
    slider.High = slider.High or _G[slider:GetName() .. "High"]
    slider.Text = slider.Text or _G[slider:GetName() .. "Text"]
    if slider.Low then slider.Low:SetText("1") end
    if slider.High then slider.High:SetText("8") end
    if slider.Text then slider.Text:SetText("Buttons per row") end

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val + 0.5)
        local db = GetDB()
        if db then
            db.microMenuBesideChatColumns = val
        end
        if FluxOptions and FluxOptions.RefreshLayoutDependents then
            FluxOptions:RefreshLayoutDependents()
        end
        if slider.Text then
            slider.Text:SetText("Buttons per row: " .. val)
        end
        if UI.DrawPreview then
            UI:DrawPreview()
        end
    end)

    UI.columnsSlider = slider
    return slider
end

-- ── Canvas creation ─────────────────────────────────────────────────────────

local function EnsureCanvas(parent)
    if UI.canvas then
        UI.canvas:SetParent(parent)
        return UI.canvas
    end

    local canvas = CreateFrame("Frame", "FluxLayoutPreviewCanvas", parent)
    canvas:SetSize(DEFAULT_PREVIEW_W, DEFAULT_PREVIEW_H)

    canvas.bg = canvas:CreateTexture(nil, "BACKGROUND", nil, -8)
    canvas.bg:SetAllPoints()
    canvas.bg:SetColorTexture(unpack(BG_COLOR))

    canvas.borderTop = canvas:CreateTexture(nil, "BORDER")
    canvas.borderTop:SetColorTexture(0.25, 0.25, 0.30, 1)
    canvas.borderTop:SetPoint("TOPLEFT"); canvas.borderTop:SetPoint("TOPRIGHT")
    canvas.borderTop:SetHeight(1)

    canvas.borderBot = canvas:CreateTexture(nil, "BORDER")
    canvas.borderBot:SetColorTexture(0.25, 0.25, 0.30, 1)
    canvas.borderBot:SetPoint("BOTTOMLEFT"); canvas.borderBot:SetPoint("BOTTOMRIGHT")
    canvas.borderBot:SetHeight(1)

    canvas.borderL = canvas:CreateTexture(nil, "BORDER")
    canvas.borderL:SetColorTexture(0.25, 0.25, 0.30, 1)
    canvas.borderL:SetPoint("TOPLEFT"); canvas.borderL:SetPoint("BOTTOMLEFT")
    canvas.borderL:SetWidth(1)

    canvas.borderR = canvas:CreateTexture(nil, "BORDER")
    canvas.borderR:SetColorTexture(0.25, 0.25, 0.30, 1)
    canvas.borderR:SetPoint("TOPRIGHT"); canvas.borderR:SetPoint("BOTTOMRIGHT")
    canvas.borderR:SetWidth(1)

    canvas:EnableMouse(true)
    canvas:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" or btn == "RightButton" then
            Deselect()
        end
    end)

    UI.canvas = canvas
    return canvas
end

-- ── Selection highlight animation ───────────────────────────────────────────
-- Hide() does not stop OnUpdate in WoW — only clear the script when idle.

local pulsePhase = 0
local pulseFrame = CreateFrame("Frame")
pulseFrame:Hide()

local function PulseOnUpdate(_, elapsed)
    pulsePhase = pulsePhase + elapsed * 3
    if pulsePhase > 6.283 then pulsePhase = pulsePhase - 6.283 end
    local alpha = 0.6 + 0.4 * math.sin(pulsePhase)
    if UI._selectedBorder then
        UI._selectedBorder:SetAlpha(alpha)
    end
end

local function StartPulse()
    pulseFrame:SetScript("OnUpdate", PulseOnUpdate)
end

local function StopPulse()
    pulseFrame:SetScript("OnUpdate", nil)
    pulseFrame:Hide()
end

-- ── Main draw routine ───────────────────────────────────────────────────────

local boxIdx = 0
local ghostIdx = 0

local function PlaceBox(canvas, rect, color, alpha, labelText, isSelected)
    boxIdx = boxIdx + 1
    local box = GetOrCreateBox(canvas, boxIdx)
    local pw, ph = UI.previewW or DEFAULT_PREVIEW_W, UI.previewH or DEFAULT_PREVIEW_H
    local x = rect[1] * pw
    local y = rect[2] * ph
    local w = math.max(rect[3] * pw, 4)
    local h = math.max(rect[4] * ph, 4)

    box:ClearAllPoints()
    box:SetPoint("TOPLEFT", canvas, "TOPLEFT", x, -y)
    box:SetSize(w, h)

    local r, g, b = color[1], color[2], color[3]
    box.bg:SetColorTexture(r, g, b, alpha * 0.6)

    if isSelected then
        box.border:SetColorTexture(r, g, b, 1)
        box.border:Show()
        UI._selectedBorder = box.border
        StartPulse()
    else
        box.border:SetColorTexture(r, g, b, alpha * 0.4)
        box.border:Show()
    end

    box.label:SetText(labelText or "")
    -- Fixed size: live rects or selection used to swing w/h and toggle font, which looked like layout jumping.
    box.label:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    box.label:SetTextColor(1, 1, 1, alpha)
    box:Show()
    return box
end

local function PlaceGhost(canvas, rect, color, labelText, strengthMul)
    strengthMul = strengthMul or 1
    ghostIdx = ghostIdx + 1
    local ghost = GetOrCreateGhost(canvas, ghostIdx)
    local pw, ph = UI.previewW or DEFAULT_PREVIEW_W, UI.previewH or DEFAULT_PREVIEW_H
    local x = rect[1] * pw
    local y = rect[2] * ph
    local w = math.max(rect[3] * pw, 4)
    local h = math.max(rect[4] * ph, 4)

    ghost:ClearAllPoints()
    ghost:SetPoint("TOPLEFT", canvas, "TOPLEFT", x, -y)
    ghost:SetSize(w, h)

    local r, g, b = color[1], color[2], color[3]
    ghost.bg:SetColorTexture(r, g, b, GHOST_ALPHA * 0.5 * strengthMul)
    ghost.border:SetColorTexture(r, g, b, GHOST_ALPHA * 0.8 * strengthMul)
    ghost.border:Show()
    ghost.label:SetText(labelText or "")
    ghost.label:SetFont("Fonts\\FRIZQT__.TTF", (strengthMul > 1.15) and 10 or 8, "OUTLINE")
    ghost.label:SetTextColor(r, g, b, (strengthMul > 1.15) and 0.95 or 0.7)
    ghost:SetHitRectInsets(-8, -8, -8, -8)
    ghost:SetFrameLevel(canvas:GetFrameLevel() + LEVEL_GHOST_TOP)
    ghost:Show()
    return ghost
end

--- Alpha for Micro / Status / Player+Target / Stance tiles: selected is bright, others dim while picking placement.
local function InteractiveControlAlpha(isSelected, elementKey, selected)
    if isSelected then
        return SELECTED_ALPHA
    end
    if selected and selected ~= elementKey then
        return PLACEMENT_MODE_OTHER_ALPHA
    end
    return ACTIVE_ALPHA
end

--- Z-order for Micro Menu / Status / Player+Target / Stance so alternate-placement ghosts are never buried.
local function SetInteractiveBoxLayer(box, elementKey, selected)
    local parent = box:GetParent()
    if not parent then
        return
    end
    local base = parent:GetFrameLevel()
    if not selected then
        box:SetFrameLevel(base + LEVEL_INTERACTIVE)
    elseif selected == elementKey then
        box:SetFrameLevel(base + LEVEL_INTERACTIVE_SELECTED)
    else
        box:SetFrameLevel(base + LEVEL_INTERACTIVE_BACK)
    end
end

local function PlaceRefBox(canvas, rect, color, alpha, label, refKey, sourceFrame, liveOverride)
    if not rect then return nil end
    local isLive
    if liveOverride ~= nil then
        isLive = liveOverride
    else
        isLive = sourceFrame and FrameToCanvasFrac(sourceFrame) ~= nil
    end
    local box = PlaceBox(canvas, rect, color, alpha, label, false)
    box:SetFrameLevel(canvas:GetFrameLevel() + LEVEL_REFERENCE)
    box:EnableMouse(true)
    box._fluxLiveRect = isLive and true or nil
    box:SetScript("OnEnter", function(b)
        ShowRefTooltip(b, refKey)
    end)
    box:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    box:SetScript("OnClick", function()
        Deselect()
    end)
    return box
end

function UI:DrawPreview()
    local canvas = self.canvas
    if not canvas then return end

    SyncPreviewDimensionsFromCanvas()

    local selected = self.selectedElement
    local placementPicking = selected ~= nil
    if canvas.bg then
        if placementPicking then
            canvas.bg:SetColorTexture(0.055, 0.058, 0.075, 1)
        else
            canvas.bg:SetColorTexture(unpack(BG_COLOR))
        end
    end

    -- Reset pools
    HideAll(allBoxes)
    HideAll(allGhosts)
    boxIdx = 0
    ghostIdx = 0
    StopPulse()
    UI._selectedBorder = nil

    local pos = ReadPositions()
    local bundle = GetLiveFrameBundle()
    local ghostStrength = placementPicking and 1.72 or 1

    -- ── Core screen landmarks (hidden while picking a placement - reduces overlap with ghost zones) ──
    local minimapSch = ResolveRect(REF_RECTS.minimap, bundle.minimap)
    local stripRect, stripLive = ComputeActionStripUnionRect(bundle)

    local chatSch, microBesideSch, raidSch = GetChatAreaSchematics(stripRect, pos.microMenu)
    local microMenuPr = GetMicroMenuSchematicRect(pos.microMenu, microBesideSch, minimapSch)
    local statusBarPr = GetStatusBarSchematicRect(pos.statusBar, pos.microMenu, stripRect, pos.infoFramePlacement)
    local pvpSch = GetPVPObjectiveSchematicRect(pos, stripRect, microMenuPr, statusBarPr)
    local talkingHeadSch = PreviewHasTalkingHead() and GetTalkingHeadSchematicRect(pos, microMenuPr, statusBarPr) or nil
    local fluxResolved = ResolveRect(FALLBACK_STRIP.fluxWindow, bundle.fluxWindow)
    local ptRects = GetPlayerTargetRects(pos.playerTarget, stripRect, pos.statusBar)
    local stanceSch = GetStanceBarSchematicRect(pos.stanceBar, ptRects.player, fluxResolved, stripRect, pos.statusBar)
    local petSchematic = GetPetBarSchematicRect(fluxResolved, pos.stanceBar, stanceSch, stripRect, pos.statusBar)

    if not placementPicking then
        PlaceRefBox(canvas, minimapSch, COLORS.minimap, REFERENCE_ALPHA, "Minimap", "minimap", bundle.minimap)
        PlaceRefBox(canvas, Rect4(pvpSch), COLORS.pvpObjective, REFERENCE_ALPHA, "PVP\nobj", "pvpObjective", bundle.pvpObjective, false)
        if talkingHeadSch then
            PlaceRefBox(canvas, Rect4(talkingHeadSch), COLORS.talkingHead, REFERENCE_ALPHA, "Talking\nHead", "talkingHead", nil, false)
        end

        local stripBox = PlaceRefBox(
            canvas,
            stripRect,
            COLORS.actionStrip,
            REFERENCE_ALPHA,
            "Action\nstrip",
            "actionStrip",
            nil,
            stripLive
        )
        if stripBox then
            stripBox:SetFrameLevel(canvas:GetFrameLevel() + 1)
        end

        PlaceRefBox(canvas, fluxResolved, COLORS.fluxWindow, REFERENCE_ALPHA, "Flux\nwindow", "fluxWindow", bundle.fluxWindow)
        PlaceRefBox(canvas, Rect4(chatSch), COLORS.chat, REFERENCE_ALPHA, "Chat", "chat", bundle.chat)

        local raidFrame = bundle.raidStack
        if not (raidFrame and raidFrame.IsShown and raidFrame:IsShown()) then
            raidFrame = bundle.partyFrame
        end
        PlaceRefBox(canvas, Rect4(raidSch), COLORS.raidStack, REFERENCE_ALPHA, "Raid /\nParty", "raidStack", raidFrame)

        if FluxFocusShownInPreview() then
            local schF = GetFocusSchematicRect(chatSch, raidSch, pos.playerTarget)
            local focusResolved = ResolveRect(schF, bundle.fluxFocus)
            PlaceRefBox(
                canvas,
                Rect4(focusResolved),
                COLORS.focus,
                REFERENCE_ALPHA,
                "Focus",
                "focusFrame",
                bundle.fluxFocus
            )
        end

        PlaceRefBox(canvas, Rect4(petSchematic), COLORS.petBar, REFERENCE_ALPHA, "Pet\nbar", "petBar", bundle.petBar)
    end

    -- ── Interactive controls (frame level decides overlaps; same layer = ambiguous).
    -- ── Interactive: Status Bar ────────────────────────────────────────────
    do
        local key = "statusBar"
        local cur = pos.statusBar
        local isSel = (selected == key)
        local sr = GetStatusBarSchematicRect(cur, pos.microMenu, stripRect, pos.infoFramePlacement)
        local rect = Rect4(sr)
        local alpha = InteractiveControlAlpha(isSel, key, selected)
        local box = PlaceBox(canvas, rect, COLORS[key], alpha, "Status Bar", isSel)
        box:SetHitRectInsets(-6, -6, -6, -6)
        SetInteractiveBoxLayer(box, key, selected)
        box:SetScript("OnClick", function()
            if self.selectedElement == key then
                Deselect()
            else
                self.selectedElement = key
                self:DrawPreview()
            end
        end)
        box:SetScript("OnEnter", function(b) ShowBoxTooltip(b, key, cur) end)
        box:SetScript("OnLeave", function() GameTooltip:Hide() end)

        if isSel then
            for posVal = 1, 3 do
                if posVal ~= cur then
                    local gr = GetStatusBarSchematicRect(posVal, pos.microMenu, stripRect, pos.infoFramePlacement)
                    local ghost = PlaceGhost(canvas, Rect4(gr), COLORS[key], gr[5] or "", ghostStrength)
                    ghost:SetScript("OnClick", function()
                        ApplyPosition(key, posVal)
                        self.selectedElement = nil
                        self:DrawPreview()
                    end)
                    ghost:SetScript("OnEnter", function(g) ShowGhostTooltip(g, key, posVal) end)
                    ghost:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            end
        end
    end

    -- ── Interactive: Player / Target ───────────────────────────────────────
    do
        local key = "playerTarget"
        local cur = pos.playerTarget
        local isSel = (selected == key)
        local rects = GetPlayerTargetRects(cur, stripRect, pos.statusBar)
        local alpha = InteractiveControlAlpha(isSel, key, selected)

        local pBox = PlaceBox(canvas, rects.player, COLORS.player, alpha, "Player", isSel)
        local tBox = PlaceBox(canvas, rects.target, COLORS.target, alpha, "Target", isSel)
        pBox:SetHitRectInsets(-6, -6, -6, -6)
        tBox:SetHitRectInsets(-6, -6, -6, -6)
        SetInteractiveBoxLayer(pBox, key, selected)
        SetInteractiveBoxLayer(tBox, key, selected)

        local function onClick()
            if self.selectedElement == key then
                Deselect()
            else
                self.selectedElement = key
                self:DrawPreview()
            end
        end

        pBox:SetScript("OnClick", onClick)
        tBox:SetScript("OnClick", onClick)
        pBox:SetScript("OnEnter", function(b) ShowBoxTooltip(b, key, cur) end)
        pBox:SetScript("OnLeave", function() GameTooltip:Hide() end)
        tBox:SetScript("OnEnter", function(b) ShowBoxTooltip(b, key, cur) end)
        tBox:SetScript("OnLeave", function() GameTooltip:Hide() end)

        if isSel then
            local ghostSets = GetPlayerTargetGhostRects(cur, stripRect, pos.statusBar)
            for posVal, ghostData in pairs(ghostSets) do
                local pg = PlaceGhost(canvas, ghostData.player, COLORS.player, ghostData.label or "", ghostStrength)
                local tg = PlaceGhost(canvas, ghostData.target, COLORS.target, "", ghostStrength)

                local function onGhostClick()
                    ApplyPosition(key, posVal)
                    self.selectedElement = nil
                    self:DrawPreview()
                end

                pg:SetScript("OnClick", onGhostClick)
                tg:SetScript("OnClick", onGhostClick)
                pg:SetScript("OnEnter", function(g) ShowGhostTooltip(g, key, posVal) end)
                pg:SetScript("OnLeave", function() GameTooltip:Hide() end)
                tg:SetScript("OnEnter", function(g) ShowGhostTooltip(g, key, posVal) end)
                tg:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
        end
    end

    -- ── Interactive: Stance Bar ────────────────────────────────────────────
    do
        local key = "stanceBar"
        local cur = pos.stanceBar
        local isSel = (selected == key)
        local rect = Rect4(stanceSch)
        local alpha = InteractiveControlAlpha(isSel, key, selected)
        local box = PlaceBox(canvas, rect, COLORS[key], alpha, "Stance", isSel)
        box:SetHitRectInsets(-6, -6, -6, -6)
        SetInteractiveBoxLayer(box, key, selected)
        box:SetScript("OnClick", function()
            if self.selectedElement == key then
                Deselect()
            else
                self.selectedElement = key
                self:DrawPreview()
            end
        end)
        box:SetScript("OnEnter", function(b) ShowBoxTooltip(b, key, cur) end)
        box:SetScript("OnLeave", function() GameTooltip:Hide() end)

        if isSel then
            local ghosts = GetStanceBarGhostRects(cur, ptRects.player, fluxResolved, stripRect, pos.statusBar)
            for posVal, ghostRect in pairs(ghosts) do
                local ghost = PlaceGhost(canvas, ghostRect, COLORS[key], ghostRect[5], ghostStrength)
                ghost:SetScript("OnClick", function()
                    ApplyPosition(key, posVal)
                    self.selectedElement = nil
                    self:DrawPreview()
                end)
                ghost:SetScript("OnEnter", function(g) ShowGhostTooltip(g, key, posVal) end)
                ghost:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
        end
    end

    -- ── Interactive: Micro Menu (drawn last - top priority where UI overlaps) ─
    do
        local key = "microMenu"
        local cur = pos.microMenu
        local isSel = (selected == key)
        local pr = GetMicroMenuSchematicRect(cur, microBesideSch, minimapSch)
        local rect = Rect4(pr)
        local alpha = InteractiveControlAlpha(isSel, key, selected)
        local box = PlaceBox(canvas, rect, COLORS[key], alpha, "Micro\nMenu", isSel)
        box:SetHitRectInsets(-6, -6, -6, -6)
        SetInteractiveBoxLayer(box, key, selected)
        box:SetScript("OnClick", function()
            if self.selectedElement == key then
                Deselect()
            else
                self.selectedElement = key
                self:DrawPreview()
            end
        end)
        box:SetScript("OnEnter", function(b) ShowBoxTooltip(b, key, cur) end)
        box:SetScript("OnLeave", function() GameTooltip:Hide() end)

        if isSel then
            for posVal = 1, 3 do
                if posVal ~= cur then
                    local gRect = GetMicroMenuSchematicRect(posVal, microBesideSch, minimapSch)
                    local ghost = PlaceGhost(canvas, Rect4(gRect), COLORS[key], gRect[5] or "", ghostStrength)
                    ghost:SetScript("OnClick", function()
                        ApplyPosition(key, posVal)
                        self.selectedElement = nil
                        self:DrawPreview()
                    end)
                    ghost:SetScript("OnEnter", function(g) ShowGhostTooltip(g, key, posVal) end)
                    ghost:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            end
        end
    end

    -- ── Interactive: Info frame (after Micro Menu - wins overlaps in top band; over status row see LEVEL_INFO_OVER_STATUS_BAR_SCHEMATIC) ─
    do
        local key = "infoFrame"
        local cur = pos.infoFramePlacement or "actionStrip"
        local isSel = (selected == key)
        local rect = Rect4(GetInfoFramePlacementPreviewRect(cur, pos, stripRect, microMenuPr, minimapSch))
        local alpha = InteractiveControlAlpha(isSel, key, selected)
        local box = PlaceBox(canvas, rect, COLORS.infoFrame, alpha, "Info\nFPS", isSel)
        box:SetHitRectInsets(-6, -6, -6, -6)
        SetInteractiveBoxLayer(box, key, selected)
        -- Left Info cell shares the status strip rect with the Status Bar control; raise layer so this box receives hover/click first (matches in-game column priority).
        local infoPlace = NormalizeInfoFramePlacement(cur)
        if infoPlace == "statusIntegrated" or infoPlace == "screenTopLeft" then
            box:SetFrameLevel(canvas:GetFrameLevel() + LEVEL_INFO_OVER_STATUS_BAR_SCHEMATIC)
        end
        box:SetScript("OnClick", function()
            if self.selectedElement == key then
                Deselect()
            else
                self.selectedElement = key
                self:DrawPreview()
            end
        end)
        box:SetScript("OnEnter", function(b) ShowBoxTooltip(b, key, cur) end)
        box:SetScript("OnLeave", function() GameTooltip:Hide() end)

        if isSel then
            for _, mode in ipairs({ "actionStrip", "statusIntegrated", "minimapTop", "screenTopLeft" }) do
                if mode ~= cur then
                    local gRect = Rect4(GetInfoFramePlacementPreviewRect(mode, pos, stripRect, microMenuPr, minimapSch))
                    local ghostLabel = (mode == "actionStrip" and "Strip")
                        or (mode == "statusIntegrated" and "Status")
                        or (mode == "screenTopLeft" and "Top left")
                        or "Minimap"
                    local ghost = PlaceGhost(canvas, gRect, COLORS.infoFrame, ghostLabel, ghostStrength)
                    ghost:SetScript("OnClick", function()
                        ApplyPosition(key, mode)
                        self.selectedElement = nil
                        self:DrawPreview()
                    end)
                    ghost:SetScript("OnEnter", function(g) ShowGhostTooltip(g, key, mode) end)
                    ghost:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            end
        end
    end

    -- ── Columns slider visibility ──────────────────────────────────────────
    if self.columnsSlider then
        local microPos = pos.microMenu
        if microPos == 2 or microPos == 3 then
            self.columnsSlider:SetValue(pos.microColumns)
            if self.columnsSlider.Text then
                self.columnsSlider.Text:SetText("Buttons per row: " .. pos.microColumns)
            end
            self.columnsSlider:Show()
        else
            self.columnsSlider:Hide()
        end
    end

    -- ── Instructions label ─────────────────────────────────────────────────
    if self.instructionLabel then
        if selected then
            local info = ELEMENT_TOOLTIPS[selected]
            local title = info and info.title or selected
            self.instructionLabel:SetText("|cff80c0ff" .. title .. "|r - click a faded tile to move. Click empty canvas to cancel.")
        else
            self.instructionLabel:SetText("|cffaaaaaaClick a box to move it. Faded tiles show other spots.|r")
        end
    end
end

-- ── Ace widget lifecycle ────────────────────────────────────────────────────

--- Resize preview when the Ace widget frame changes (options window / scroll layout).
function UI:OnPreviewFrameResize()
    if not self.canvas or not self.aceWidget then
        return
    end
    self:DrawPreview()
end

function UI:AttachToAceWidget(widget)
    self.aceWidget = widget
    local parent = widget.frame
    parent:Show()

    local canvas = EnsureCanvas(parent)
    canvas:Show()

    if not self.instructionLabel then
        self.instructionLabel = parent:CreateFontString(nil, "OVERLAY")
        self.instructionLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        self.instructionLabel:SetJustifyH("LEFT")
        self.instructionLabel:SetWordWrap(true)
    end
    self.instructionLabel:SetParent(parent)

    local slider = EnsureColumnsSlider(parent)

    -- Bottom: columns slider; above it: instruction label; top: canvas fills remaining height
    slider:ClearAllPoints()
    slider:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", PAD, 10)
    slider:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -PAD, 10)

    self.instructionLabel:ClearAllPoints()
    self.instructionLabel:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 12)
    self.instructionLabel:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 12)
    self.instructionLabel:Show()

    canvas:ClearAllPoints()
    canvas:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, -8)
    canvas:SetPoint("BOTTOMLEFT", self.instructionLabel, "TOPLEFT", 0, 0)
    canvas:SetPoint("BOTTOMRIGHT", self.instructionLabel, "TOPRIGHT", 0, 0)

    slider:Show()

    parent:SetScript("OnSizeChanged", function()
        if UI.aceWidget ~= widget then
            return
        end
        UI:OnPreviewFrameResize()
    end)

    self.selectedElement = nil
    self:DrawPreview()

    if self._liveTicker then
        self._liveTicker:Cancel()
        self._liveTicker = nil
    end
    self._liveTicker = C_Timer.NewTicker(1.0, function()
        if UI.aceWidget ~= widget then return end
        if widget.frame and widget.frame:IsVisible() and UI.canvas and UI.canvas:IsVisible() then
            UI:DrawPreview()
        end
    end)

    C_Timer.After(0, function()
        if UI.aceWidget ~= widget then return end
        if widget.frame and widget.frame:IsVisible() then
            UI:OnPreviewFrameResize()
        end
    end)
    C_Timer.After(0.05, function()
        if UI.aceWidget ~= widget then return end
        if widget.frame and widget.frame:IsVisible() then
            UI:OnPreviewFrameResize()
        end
    end)
end

function UI:DetachFromAceWidget(widget)
    if self.aceWidget ~= widget then return end
    self.aceWidget = nil
    self.selectedElement = nil
    StopPulse()
    UI._selectedBorder = nil

    if widget.frame then
        widget.frame:SetScript("OnSizeChanged", nil)
    end

    if self._liveTicker then
        self._liveTicker:Cancel()
        self._liveTicker = nil
    end

    if self.canvas then
        self.canvas:Hide()
        self.canvas:SetParent(UIParent)
        self.canvas:ClearAllPoints()
    end
    if self.instructionLabel then
        self.instructionLabel:Hide()
    end
    if self.columnsSlider then
        self.columnsSlider:Hide()
    end

    HideAll(allBoxes)
    HideAll(allGhosts)
end

--- Defensive cleanup when FluxUI options close (Detach should already have run).
function _G.FluxLayoutPreviewUI_OnOptionsClosed()
    StopPulse()
    UI._selectedBorder = nil
    if UI._liveTicker then
        UI._liveTicker:Cancel()
        UI._liveTicker = nil
    end
    UI.aceWidget = nil
end
