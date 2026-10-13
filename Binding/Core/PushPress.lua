-- Binding/Core/PushPress.lua
-- Simulate the action-bar pushed texture for Binding cast paths.
--
-- LAB virtual "Keybind" clicks and hidden pool / _HC UF buttons do not
-- depress FluxActionButtonN on their own. This module mirrors V10
-- DirectBindPushPress: push the main-row host for the column, hold while
-- the key is down, clear on release (1.5s safety cap).

local addonName, ns = ...

local PushPress = {}
ns.FluxBindingPushPress = PushPress
_G.FluxBindingPushPress = PushPress

local ChordMap = ns.FluxBindingChordMap

local UF_HC_SUFFIX = "_HC"
local pushColByChord = {}
local ufHoverPushByFrame = {}
local ufHoverWatchChords = {}
local _barButtonPushHooked = {}

local HOLD_SAFETY_CAP_SECONDS = 1.5
local HOLD_RELEASE_GRACE_SECONDS = 0.08

local holdPoller = CreateFrame("Frame")
holdPoller:Hide()

local ufHoverPushPoller = CreateFrame("Frame")
ufHoverPushPoller:Hide()
ufHoverPushPoller._acc = 0
ufHoverPushPoller._active = false
ufHoverPushPoller._safetyAcc = 0

-- ---------------------------------------------------------------------------
-- Chord / column helpers
-- ---------------------------------------------------------------------------

local function Normalize(chord)
    if ChordMap and ChordMap.Normalize then
        return ChordMap.Normalize(chord)
    end
    return type(chord) == "string" and chord or ""
end

local function StripModifiers(chord)
    if ChordMap and ChordMap.Parse then
        local base = ChordMap.Parse(chord)
        return base ~= "" and base or nil
    end
    if type(chord) ~= "string" then return nil end
    return chord:match("([^-]+)$")
end

local function ParentFrameNameForUfHc(name)
    if type(name) ~= "string" or not name:match(UF_HC_SUFFIX .. "$") then return nil end
    return name:sub(1, #name - #UF_HC_SUFFIX)
end

local function ColForChord(chord)
    if not chord or chord == "" then return nil end
    if ChordMap then
        local route = ChordMap.Route and ChordMap.Route(chord)
        if route and route.kind == "slot" and route.col then
            return route.col
        end
        if ChordMap.FindColumnForChord then
            return ChordMap.FindColumnForChord(chord)
        end
    end
    return nil
end

local function RegisterPushColForChord(chord)
    if type(chord) ~= "string" or chord == "" then return end
    local nk = Normalize(chord)
    if nk == "" then return end
    local col = ColForChord(chord)
    if col then
        pushColByChord[nk] = col
    end
end

local function MainRowFrameForCol(col)
    if type(col) ~= "number" or col < 1 or col > 19 then return nil end
    local Flux = ns.Flux
    local host = Flux and Flux.Bars and Flux.Bars.GetMain and Flux.Bars.GetMain(col)
    local widget = host and host.widget
    if widget and widget.GetName then
        return widget:GetName()
    end
    return "FluxActionStripButton" .. col
end

local function ResolvePushCol(chord, opts)
    opts = opts or {}
    if type(opts.col) == "number" and opts.col >= 1 then
        return opts.col
    end
    if chord and chord ~= "" then
        local nk = Normalize(chord)
        if pushColByChord[nk] then
            return pushColByChord[nk]
        end
        return ColForChord(chord)
    end
    return nil
end

--- Press visual always targets the main-row FluxActionButton for the column.
local function ResolvePushFramesForPress(chord, opts)
    opts = opts or {}
    local col = ResolvePushCol(chord, opts)
    local mainFrame = MainRowFrameForCol(col)
    if mainFrame then
        return { mainFrame }
    end
    if type(opts.fallbackFrames) == "table" then
        for i = 1, #opts.fallbackFrames do
            local nm = opts.fallbackFrames[i]
            if type(nm) == "string" and (nm:match("^FluxActionButton%d+$") or nm:match("^FluxActionStripButton%d+$")) then
                return { nm }
            end
        end
    end
    return nil
end

local function InferActiveChordFromBoundKeys(boundKeys)
    if type(boundKeys) ~= "table" or #boundKeys == 0 then return nil end
    if #boundKeys == 1 then return boundKeys[1] end
    local shift = IsShiftKeyDown and IsShiftKeyDown()
    local ctrl = IsControlKeyDown and IsControlKeyDown()
    local alt = IsAltKeyDown and IsAltKeyDown()
    for i = 1, #boundKeys do
        local k = boundKeys[i]
        local nk = Normalize(k)
        if nk:match("^SHIFT%-") and shift and not ctrl then return k end
        if nk:match("^CTRL%-") and ctrl and not shift then return k end
        if nk:match("^ALT%-") and alt then return k end
        if not nk:match("^SHIFT%-") and not nk:match("^CTRL%-") and not nk:match("^ALT%-")
            and not shift and not ctrl and not alt then
            return k
        end
    end
    return boundKeys[1]
end

local function InferChordFromModifiersAndBareKey(bareKey)
    if not bareKey or bareKey == "" then return nil end
    local shift = IsShiftKeyDown and IsShiftKeyDown()
    local ctrl = IsControlKeyDown and IsControlKeyDown()
    local alt = IsAltKeyDown and IsAltKeyDown()
    if shift and not ctrl then return "SHIFT-" .. bareKey end
    if ctrl and not shift then return "CTRL-" .. bareKey end
    if alt then return "ALT-" .. bareKey end
    return bareKey
end

local function ChordIsPhysicallyDown(chord)
    if not chord or chord == "" or not IsKeyDown then return false end
    local bare = StripModifiers(chord)
    if not bare or bare == "" then return false end
    local ok, down = pcall(IsKeyDown, bare)
    if not ok or not down then return false end
    local nk = Normalize(chord)
    local shift = IsShiftKeyDown and IsShiftKeyDown()
    local ctrl = IsControlKeyDown and IsControlKeyDown()
    local alt = IsAltKeyDown and IsAltKeyDown()
    if nk:match("^SHIFT%-CTRL%-") or nk:match("^CTRL%-SHIFT%-") then
        return shift and ctrl
    end
    if nk:match("^SHIFT%-") then return shift and not ctrl end
    if nk:match("^CTRL%-") then return ctrl and not shift end
    if nk:match("^ALT%-") then return alt end
    return not shift and not ctrl and not alt
end

-- ---------------------------------------------------------------------------
-- Visuals
-- ---------------------------------------------------------------------------

local function ApplyPushVisual(fr)
    if not fr then return end
    if type(fr.IsForbidden) == "function" then
        local ok, bad = pcall(fr.IsForbidden, fr)
        if ok and bad then return end
    end
    if fr.SetButtonState then
        pcall(fr.SetButtonState, fr, "PUSHED")
    end
    if fr.LockHighlight then
        pcall(fr.LockHighlight, fr)
    end
    local pt = fr.PushedTexture or (fr.GetPushedTexture and fr:GetPushedTexture())
    if pt and pt.Show then
        pcall(pt.Show, pt)
    end
    local ht = fr.GetHighlightTexture and fr:GetHighlightTexture()
    if ht and ht.Show then
        pcall(ht.Show, ht)
    end
    local icon = fr.icon or fr.Icon
    if icon and icon.SetVertexColor and not fr._fluxKeybindPushDimmed then
        local r, g, b = icon:GetVertexColor()
        fr._fluxKeybindPushIconColor = { r, g, b }
        fr._fluxKeybindPushDimmed = true
        icon:SetVertexColor(r * 0.62, g * 0.62, b * 0.62)
    end
end

local function ClearPushVisual(fr)
    if not fr then return end
    if type(fr.IsForbidden) == "function" then
        local ok, bad = pcall(fr.IsForbidden, fr)
        if ok and bad then return end
    end
    if fr.SetButtonState then
        pcall(fr.SetButtonState, fr, "NORMAL", false)
    end
    if fr.UnlockHighlight then
        pcall(fr.UnlockHighlight, fr)
    end
    local pt = fr.PushedTexture or (fr.GetPushedTexture and fr:GetPushedTexture())
    if pt and pt.Hide then
        pcall(pt.Hide, pt)
    end
    -- Highlight can linger after LockHighlight if mouse is not over the button.
    local ht = fr.GetHighlightTexture and fr:GetHighlightTexture()
    if ht and ht.Hide and not (fr.IsMouseOver and fr:IsMouseOver()) then
        pcall(ht.Hide, ht)
    end
    local icon = fr.icon or fr.Icon
    if fr._fluxKeybindPushDimmed and icon and icon.SetVertexColor and fr._fluxKeybindPushIconColor then
        local c = fr._fluxKeybindPushIconColor
        icon:SetVertexColor(c[1], c[2], c[3])
        fr._fluxKeybindPushDimmed = nil
        fr._fluxKeybindPushIconColor = nil
    end
end

local function ClearAllBarPushVisuals()
    for col = 1, 19 do
        ClearPushVisual(_G["FluxActionButton" .. col])
        ClearPushVisual(_G["FluxActionStripButton" .. col])
        ClearPushVisual(_G["FluxSecondaryButton" .. col])
        ClearPushVisual(_G["FluxTertiaryButton" .. col])
        ClearPushVisual(_G["FluxActionStripSec" .. col])
        ClearPushVisual(_G["FluxActionStripTert" .. col])
    end
end

local function PressFluxBarPushFrames(pushFrames)
    if type(pushFrames) ~= "table" then return end
    for i = 1, #pushFrames do
        ApplyPushVisual(_G[pushFrames[i]])
    end
end

local function UnpressFluxBarPushFrames(pushFrames)
    if type(pushFrames) ~= "table" then return end
    for i = 1, #pushFrames do
        ClearPushVisual(_G[pushFrames[i]])
    end
end

local function ReleaseActionButtonsForKey(key)
    if not key or key == "" then return end
    local col = ColForChord(key) or pushColByChord[Normalize(key)]
    local nm = MainRowFrameForCol(col)
    local frame = nm and _G[nm]
    if frame and not (frame.IsForbidden and frame:IsForbidden()) then
        ClearPushVisual(frame)
    end
end

-- ---------------------------------------------------------------------------
-- Hold poller
-- ---------------------------------------------------------------------------

local function StopHoldPoll()
    holdPoller:SetScript("OnUpdate", nil)
    holdPoller:Hide()
    holdPoller._frames = nil
    holdPoller._bareKey = nil
    holdPoller._chord = nil
    holdPoller._elapsed = 0
end

local function FinishHoldPoll()
    local frames = holdPoller._frames
    local chord = holdPoller._chord
    StopHoldPoll()
    if chord then
        ReleaseActionButtonsForKey(chord)
    end
    UnpressFluxBarPushFrames(frames)
end

local function ChordOrKeyStillDown(chord, bareKey)
    if chord and chord ~= "" and ChordIsPhysicallyDown(chord) then
        return true
    end
    if bareKey and bareKey ~= "" and IsKeyDown then
        local ok, down = pcall(IsKeyDown, bareKey)
        if ok and down then return true end
    end
    return false
end

local function HoldPollOnUpdate(self, dt)
    self._elapsed = (self._elapsed or 0) + dt
    if self._elapsed >= HOLD_SAFETY_CAP_SECONDS then
        FinishHoldPoll()
        return
    end
    if self._elapsed < HOLD_RELEASE_GRACE_SECONDS then
        return
    end
    if not ChordOrKeyStillDown(self._chord, self._bareKey) then
        FinishHoldPoll()
    end
end

local function StartHoldPoll(bareKey, chord, frames)
    holdPoller._frames = frames
    holdPoller._bareKey = bareKey
    holdPoller._chord = chord
    holdPoller._elapsed = 0
    holdPoller:Show()
    holdPoller:SetScript("OnUpdate", HoldPollOnUpdate)
end

local function commitMainRowPush(chord, opts, bareKey)
    local frames = ResolvePushFramesForPress(chord, opts)
    if not frames or #frames == 0 then return end
    -- GetBindingKey / callers may pass a full chord; poller needs a bare key name.
    if bareKey and bareKey ~= "" then
        bareKey = StripModifiers(bareKey) or bareKey
    elseif chord and chord ~= "" then
        bareKey = StripModifiers(chord)
    end

    -- Same chord already held: refresh paint only — do NOT reset safety timer.
    -- (frames is a new table every call; identity compare was resetting the poll forever.)
    if holdPoller:IsShown() and holdPoller._chord and chord
        and Normalize(holdPoller._chord) == Normalize(chord) then
        holdPoller._frames = frames
        if bareKey and bareKey ~= "" then
            holdPoller._bareKey = bareKey
        end
        PressFluxBarPushFrames(frames)
        return
    end

    StopHoldPoll()
    PressFluxBarPushFrames(frames)
    StartHoldPoll(bareKey, chord, frames)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if holdPoller:IsShown() and holdPoller._frames == frames
                and ChordOrKeyStillDown(holdPoller._chord, holdPoller._bareKey) then
                PressFluxBarPushFrames(frames)
            end
        end)
    end
end

--- If the active hold chord is no longer physically down, clear push visuals.
function PushPress.ReleaseIfUp()
    if not holdPoller:IsShown() then return end
    if holdPoller._elapsed and holdPoller._elapsed < HOLD_RELEASE_GRACE_SECONDS then
        return
    end
    if not ChordOrKeyStillDown(holdPoller._chord, holdPoller._bareKey) then
        FinishHoldPoll()
        ClearAllBarPushVisuals()
    end
end

--- Force-clear all keybind push visuals (paging / escape hatch).
function PushPress.ClearAll()
    FinishHoldPoll()
    ClearAllBarPushVisuals()
end

-- Modifier/page flips often leave PUSHED if the bare key poll never saw an up edge.
holdPoller:RegisterEvent("MODIFIER_STATE_CHANGED")
holdPoller:SetScript("OnEvent", function()
    if not holdPoller:IsShown() then return end
    if holdPoller._elapsed and holdPoller._elapsed < HOLD_RELEASE_GRACE_SECONDS then
        return
    end
    if not ChordOrKeyStillDown(holdPoller._chord, holdPoller._bareKey) then
        FinishHoldPoll()
    end
end)

-- ---------------------------------------------------------------------------
-- Resolve press context from pool / _HC buttons
-- ---------------------------------------------------------------------------

local function ResolvePressSourceButton(self)
    if not self then return self end
    if self.__fluxBoundKey or self.__fluxPushCol
        or (type(self.__fluxBoundKeys) == "table" and #self.__fluxBoundKeys > 0) then
        return self
    end
    local name = self.GetName and self:GetName()
    if not name then return self end
    local entry = ufHoverPushByFrame[name]
    local parentName = (entry and entry.parentName) or ParentFrameNameForUfHc(name)
    if parentName then
        local parent = _G[parentName]
        if parent then return parent end
    end
    return self
end

local function ResolveChordForPressButton(self)
    if not self then return nil end
    local chord = self.__fluxBoundKey
    if (not chord or chord == "") and type(self.__fluxBoundKeys) == "table" then
        chord = InferActiveChordFromBoundKeys(self.__fluxBoundKeys) or self.__fluxBoundKeys[1]
    end
    if (not chord or chord == "") then
        local name = self.GetName and self:GetName()
        if name then
            local entry = ufHoverPushByFrame[name]
            if entry and type(entry.chordList) == "table" and #entry.chordList > 0 then
                chord = InferActiveChordFromBoundKeys(entry.chordList) or entry.chordList[1]
            end
        end
    end
    if (not chord or chord == "") then
        local source = ResolvePressSourceButton(self)
        if source and source ~= self then
            chord = ResolveChordForPressButton(source)
        end
    end
    return chord
end

local function ResolvePressOptsForButton(self, chord)
    local source = ResolvePressSourceButton(self)
    local opts = {
        col = source.__fluxPushCol,
        fallbackFrames = source.__fluxBarPushFrames,
    }
    if (not opts.col or opts.col < 1) and chord and chord ~= "" then
        local nk = Normalize(chord)
        opts.col = pushColByChord[nk] or ColForChord(chord)
    end
    if (not opts.col or opts.col < 1) then
        local name = self.GetName and self:GetName()
        local entry = name and ufHoverPushByFrame[name]
        if entry and entry.col then
            opts.col = entry.col
        end
    end
    return opts
end

local function resolvePressFramesForButton(self, chord)
    local source = ResolvePressSourceButton(self)
    if not chord or chord == "" then
        chord = ResolveChordForPressButton(self)
    end
    local frames = ResolvePushFramesForPress(chord, {
        col = source.__fluxPushCol,
        fallbackFrames = source.__fluxBarPushFrames,
    })
    if frames and #frames > 0 then
        return frames
    end
    if type(source.__fluxBarPushFrames) == "table" and #source.__fluxBarPushFrames > 0 then
        return source.__fluxBarPushFrames
    end
    local col = ResolvePushCol(chord, { col = source.__fluxPushCol })
    local mf = MainRowFrameForCol(col)
    return mf and { mf } or nil
end

-- ---------------------------------------------------------------------------
-- Hooks
-- ---------------------------------------------------------------------------

function PushPress.HookButton(btn)
    if not btn or btn.__fluxPressFxHooked then return end
    if type(btn.HookScript) ~= "function" then return end
    btn.__fluxPressFxHooked = true
    btn:HookScript("PreClick", function(self)
        local chord = ResolveChordForPressButton(self)
        local bare = chord and StripModifiers(chord) or nil
        commitMainRowPush(chord, ResolvePressOptsForButton(self, chord), bare)
    end)
    btn:HookScript("PostClick", function(self)
        local source = ResolvePressSourceButton(self)
        local chord = ResolveChordForPressButton(self)
        local bare = chord and StripModifiers(chord) or nil
        -- Mouse / click-up: clear immediately when the chord is no longer held.
        if not ChordOrKeyStillDown(chord, bare) then
            local frames = resolvePressFramesForButton(source, chord)
            if holdPoller:IsShown() and holdPoller._chord and chord
                and Normalize(holdPoller._chord) == Normalize(chord) then
                FinishHoldPoll()
            else
                UnpressFluxBarPushFrames(frames)
                if chord then
                    ReleaseActionButtonsForKey(chord)
                end
            end
            return
        end
        local list = source.__fluxBoundKeys
        if (not list or #list == 0) and source.__fluxBoundKey then
            list = { source.__fluxBoundKey }
        end
        if (not list or #list == 0) then
            local name = self.GetName and self:GetName()
            local entry = name and ufHoverPushByFrame[name]
            if entry and type(entry.chordList) == "table" then
                list = entry.chordList
            end
        end
        if type(list) == "table" and (not IsKeyDown) then
            local frames = resolvePressFramesForButton(source, chord)
            for i = 1, #list do
                ReleaseActionButtonsForKey(list[i])
            end
            UnpressFluxBarPushFrames(frames)
        end
    end)
end

local function HookFluxBarButtonKeybindPressFX(col)
    local name = "FluxActionStripButton" .. col
    if _barButtonPushHooked[name] then return end
    local btn = _G[name]
    if not btn or type(btn.HookScript) ~= "function" then return end
    _barButtonPushHooked[name] = true
    btn:HookScript("PreClick", function(_self, button, down)
        if button ~= "KeyBind" and button ~= "Keybind" then return end
        if down == false then return end
        local bindKey
        local bindName = ChordMap and ChordMap.COLUMN_BINDING_NAME and ChordMap.COLUMN_BINDING_NAME[col]
        if GetBindingKey and bindName then
            bindKey = GetBindingKey(bindName)
        end
        local bareKey = bindKey and (StripModifiers(bindKey) or bindKey) or nil
        local chord = InferChordFromModifiersAndBareKey(bareKey) or bindKey or bareKey
        commitMainRowPush(chord, { col = col }, bareKey)
    end)
end

function PushPress.EnsureBarButtonPushHooks()
    local hooked = 0
    local maxCol = (ChordMap and ChordMap.TOTAL_COLUMNS) or 19
    for col = 1, maxCol do
        HookFluxBarButtonKeybindPressFX(col)
        if _barButtonPushHooked["FluxActionStripButton" .. col] then
            hooked = hooked + 1
        end
    end
    return hooked == maxCol
end

-- Forever keys click hidden FluxActionStripKeyN as LeftButton. Paint the parent host.
function PushPress.HookKeyer(keyer, column)
    if not keyer or type(keyer.HookScript) ~= "function" then
        return
    end
    column = tonumber(column)
    if not column then
        return
    end
    if keyer._fluxPushHooked then
        return
    end
    keyer._fluxPushHooked = true
    keyer:HookScript("PreClick", function(_self, _button, down)
        if down == false then
            return
        end
        local bindKey
        local bindName = ChordMap and ChordMap.COLUMN_BINDING_NAME and ChordMap.COLUMN_BINDING_NAME[column]
        if GetBindingKey and bindName then
            bindKey = GetBindingKey(bindName)
        end
        local bareKey = bindKey and (StripModifiers(bindKey) or bindKey) or nil
        local chord = InferChordFromModifiersAndBareKey(bareKey) or bindKey or bareKey
        commitMainRowPush(chord, { col = column }, bareKey)
    end)
end

-- ---------------------------------------------------------------------------
-- UF hover push registry + poller
-- ---------------------------------------------------------------------------

local TryUfHoverKeyPress -- forward (used by OnUpdate before assignment)

local function DisarmUfHoverPushPoller()
    ufHoverPushPoller:Hide()
    ufHoverPushPoller._active = false
    ufHoverPushPoller._safetyAcc = 0
    ufHoverPushPoller:SetScript("OnUpdate", nil)
end

local function UfHoverPushOnUpdate(self, dt)
    if self._active then
        self._acc = self._acc + dt
        if self._acc < 0.02 then return end
        self._acc = 0
        local anyDown = false
        if IsKeyDown then
            for _, chord in pairs(ufHoverWatchChords) do
                if ChordIsPhysicallyDown(chord) then
                    anyDown = true
                    break
                end
            end
        end
        if not anyDown then
            self._active = false
            -- Stay armed briefly while still peeking (key-up / re-press); else park.
            local km = _G.FluxMouseoverKeybindModule
            if not (km and km.IsHovercastPeekMouseContext and km:IsHovercastPeekMouseContext()) then
                DisarmUfHoverPushPoller()
            end
            return
        end
        TryUfHoverKeyPress()
    else
        self._safetyAcc = (self._safetyAcc or 0) + dt
        if self._safetyAcc < 0.25 then return end
        self._safetyAcc = 0
        local hit = TryUfHoverKeyPress()
        if hit then
            self._active = true
            self._acc = 0
        else
            local km = _G.FluxMouseoverKeybindModule
            if not (km and km.IsHovercastPeekMouseContext and km:IsHovercastPeekMouseContext()) then
                DisarmUfHoverPushPoller()
            end
        end
    end
end

local function ArmUfHoverPushPoller()
    if not next(ufHoverWatchChords) then
        DisarmUfHoverPushPoller()
        return
    end
    ufHoverPushPoller:Show()
    if not ufHoverPushPoller:GetScript("OnUpdate") then
        ufHoverPushPoller:SetScript("OnUpdate", UfHoverPushOnUpdate)
    end
end

local function SyncUfHoverPushPoller()
    -- Chords registered: keep event wakeups; do not leave OnUpdate running idle.
    if not next(ufHoverWatchChords) then
        DisarmUfHoverPushPoller()
    end
end

local function AnyUfHoverChordDown()
    if not IsKeyDown or not next(ufHoverWatchChords) then return false end
    for _, chord in pairs(ufHoverWatchChords) do
        if ChordIsPhysicallyDown(chord) then
            return true
        end
    end
    return false
end

TryUfHoverKeyPress = function()
    -- Cheap gate: no watched chord down → never peek-scan.
    if not IsKeyDown then return false end
    if not AnyUfHoverChordDown() then return false end
    local km = _G.FluxMouseoverKeybindModule
    if not km or not km.IsHovercastPeekMouseContext then
        return false
    end
    if not km:IsHovercastPeekMouseContext() then
        return false
    end
    for _, chord in pairs(ufHoverWatchChords) do
        if ChordIsPhysicallyDown(chord) then
            local bare = StripModifiers(chord)
            commitMainRowPush(chord, ResolvePressOptsForButton({}, chord), bare)
            return true
        end
    end
    return false
end

--- Immediate wake (modifier / UF OnEnter / key already down).
local function WakeUfHoverPushPoller(self, opts)
    opts = opts or {}
    if not next(ufHoverWatchChords) then
        DisarmUfHoverPushPoller()
        return
    end

    local hit = TryUfHoverKeyPress()
    if hit then
        self._active = true
        self._acc = 0
        ArmUfHoverPushPoller()
        return
    end

    -- UF enter / modifier: arm safety poll only when peek is active so a
    -- soon-pressed key is picked up. Do not peek on raw UMU world sweeps.
    if opts.allowPeekArm then
        local km = _G.FluxMouseoverKeybindModule
        if km and km.IsHovercastPeekMouseContext and km:IsHovercastPeekMouseContext() then
            self._safetyAcc = 0.25
            ArmUfHoverPushPoller()
        end
    end
end

--- UPDATE_MOUSEOVER_UNIT: skip unless a watched chord is already down.
--- World nameplate sweeps must not schedule timers or peek.
local function WakeUfHoverFromMouseover(self)
    if not next(ufHoverWatchChords) then
        DisarmUfHoverPushPoller()
        return
    end
    if not (AnyUfHoverChordDown() or self._active) then
        return
    end
    WakeUfHoverPushPoller(self, { allowPeekArm = false })
end

ufHoverPushPoller:RegisterEvent("MODIFIER_STATE_CHANGED")
pcall(ufHoverPushPoller.RegisterEvent, ufHoverPushPoller, "UPDATE_MOUSEOVER_UNIT")
ufHoverPushPoller:SetScript("OnEvent", function(self, event)
    if event == "UPDATE_MOUSEOVER_UNIT" then
        WakeUfHoverFromMouseover(self)
    else
        -- Modifier edges: immediate (may be holding chord over UF).
        WakeUfHoverPushPoller(self, { allowPeekArm = true })
    end
end)
-- OnUpdate attached only while armed (ArmUfHoverPushPoller).

--- Called from FluxMouseoverKeybind insecure UF OnEnter (not world UMU).
function PushPress.WakeUfHoverFromUnitFrame()
    if not next(ufHoverWatchChords) then return end
    WakeUfHoverPushPoller(ufHoverPushPoller, { allowPeekArm = true })
end

--- UF OnLeave: park the hover push poller so world sweeps do not inherit it.
function PushPress.ParkUfHoverFromUnitFrame()
    if ufHoverPushPoller._active then
        return
    end
    DisarmUfHoverPushPoller()
end

function PushPress.WipeUfHover()
    wipe(ufHoverPushByFrame)
    wipe(ufHoverWatchChords)
    SyncUfHoverPushPoller()
end

function PushPress.RegisterUfHover(frameName, chord)
    if type(frameName) ~= "string" or frameName == "" then return end
    if type(chord) ~= "string" or chord == "" then return end
    RegisterPushColForChord(chord)
    local nk = Normalize(chord)
    if nk == "" then return end
    ufHoverWatchChords[nk] = chord
    local col = pushColByChord[nk] or ColForChord(chord)
    local entry = ufHoverPushByFrame[frameName]
    if not entry then
        entry = {
            col = col,
            parentName = ParentFrameNameForUfHc(frameName),
            chordList = {},
            chordSet = {},
        }
        ufHoverPushByFrame[frameName] = entry
    end
    if col and not entry.col then
        entry.col = col
    end
    if not entry.chordSet[nk] then
        entry.chordSet[nk] = true
        entry.chordList[#entry.chordList + 1] = chord
    end
    local fr = _G[frameName]
    if fr then
        PushPress.HookButton(fr)
    end
    if col then
        HookFluxBarButtonKeybindPressFX(col)
    end
    SyncUfHoverPushPoller()
end

--- Attach chord metadata used by PreClick resolution, then hook press FX.
function PushPress.BindButton(btn, chord)
    if not btn or type(chord) ~= "string" or chord == "" then return end
    local nk = Normalize(chord)
    RegisterPushColForChord(chord)
    local col = pushColByChord[nk] or ColForChord(chord)
    btn.__fluxBoundKey = chord
    btn.__fluxBoundKeys = { chord }
    btn.__fluxPushCol = col
    if col then
        btn.__fluxBarPushFrames = { MainRowFrameForCol(col) }
    end
    PushPress.HookButton(btn)
    if col then
        HookFluxBarButtonKeybindPressFX(col)
    end
end

local pushHooksWanted = false

function PushPress.OnApplyComplete(hasPushWork)
    if hasPushWork then
        pushHooksWanted = true
    end
    pushHooksWanted = true
    PushPress.EnsureBarButtonPushHooks()
end

-- Boot / regen: re-hook strip PreClick so default ACTIONBUTTON* keys depress.
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:RegisterEvent("PLAYER_REGEN_ENABLED")
boot:SetScript("OnEvent", function()
    pushHooksWanted = true
    PushPress.EnsureBarButtonPushHooks()
end)
