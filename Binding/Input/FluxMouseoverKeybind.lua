-- FluxMouseoverKeybind.lua
-- Fixes mouse button keybinds (BUTTON3/4/5, scroll wheel) not firing when hovering
-- over unit frames.
--
-- Root cause: unit frames (SecureUnitButtonTemplate) capture mouse clicks via
-- RegisterForClicks, preventing the binding system from reaching action bar buttons.
-- On Edit Mode clients, the engine remaps BUTTON3/4/5 at the input level via
-- C_ClickBindings interaction bindings, making frame-based attribute approaches
-- impossible for unmodified and most modified clicks.
--
-- Solution (client-dependent):
--   Edit Mode clients (DF+, Anniversary, beta):
--     BUTTON3/4/5 + SCROLL: SetPassThroughButtons on unit frames lets these buttons
--       bypass the frame click system entirely.  SetBindingClick override bindings
--       (set in secure OnEnter/OnLeave snippets) then route the input directly to
--       the FluxActionStripButtons via the binding system.
--
--   Non-Edit Mode clients (classic_era):
--     BUTTON3/4/5:       Set typeN/macrotextN attributes on each unit frame from Lua.
--     MOUSEWHEELUP/DOWN: Use SetBindingClick in secure OnEnter/OnLeave snippets.
--     RegisterForClicks with specific per-button directions to add BUTTON3/4/5 support.
--
-- The existing FluxMouseoverCast system sets unit="mouseover" on action bar buttons,
-- so the redirected /click automatically targets the hovered unit.

local addonName, ns = ...

if not FLUX_API then
    return
end

local Flux = ns.Flux

-- ---------------------------------------------------------------------------
-- CONSTANTS
-- ---------------------------------------------------------------------------

-- Binding names that map to rewrite strip hosts (Bars/Hosts.lua).
local ACTION_BINDINGS = {}
for i = 1, 12 do
    ACTION_BINDINGS[i] = { binding = "ACTIONBUTTON" .. i, button = "FluxActionStripButton" .. i }
end
local Hosts = ns.Flux and ns.Flux.Bars and ns.Flux.Bars.Hosts
local SPECIAL_BINDINGS = (Hosts and Hosts.BorrowedBindingOrder) or {}
for i, bindName in ipairs(SPECIAL_BINDINGS) do
    ACTION_BINDINGS[12 + i] = { binding = bindName, button = "FluxActionStripButton" .. (12 + i) }
end

local function StripMainButtonName(col)
    col = tonumber(col)
    if not col then
        return nil
    end
    return "FluxActionStripButton" .. col
end

-- ---------------------------------------------------------------------------
-- MODULE STATE
-- ---------------------------------------------------------------------------

local FluxMouseoverKeybind = {}
ns.FluxMouseoverKeybind = FluxMouseoverKeybind

local header = nil
local registeredFrames = {}
local registeredLookup = {}
local pendingFrames = {}
local pendingRosterRegistration = false
local unitExistsDriverRegistered = false
local pendingHoverRoutingFlush = false
local ufHoverCount = 0
local pendingDriverPark = false
local SyncHoverRoutingLifecycle
local WrapHovercastMouseChildren -- forward (used by ReapplyAllRegisteredFrames)
local NoteUfHoverEnter -- forward

local function SnippetsWork()
    local R = Flux and Flux.Restricted
    if R and R.Works then
        return R.Works()
    end
    local Cap = Flux and Flux.Cap
    if Cap and Cap.hasRestrictedClosures == false then
        return false
    end
    if FLUX_API.hasRestrictedClosures == false then
        return false
    end
    return true
end

--- Camelot: Restricted.Execute no-ops (hasRestrictedClosures is false) and
--- would leave this hover header empty. State drivers stay on that gate.
--- Click-cast OnEnter still has to run here, the same way Clicked's header does.
local function HeaderExecute(body)
    if not header or type(body) ~= "string" then
        return false
    end
    if type(header.Execute) ~= "function" then
        return false
    end
    if SnippetsWork() then
        local R = Flux and Flux.Restricted
        if R and R.Execute then
            return R.Execute(header, body) and true or false
        end
    end
    return pcall(header.Execute, header, body)
end

local function HeaderSetSnippet(name, body)
    if not header or type(name) ~= "string" then
        return false
    end
    if SnippetsWork() then
        local R = Flux and Flux.Restricted
        if R and R.SetSnippet then
            return R.SetSnippet(header, name, body) and true or false
        end
    end
    if type(header.SetAttribute) ~= "function" then
        return false
    end
    return pcall(header.SetAttribute, header, name, body)
end
local NoteUfHoverLeave -- forward

--- Spell-direct UF hover: keyboard/mouse chords from FluxSpellDirectBind → `_HC` sibling frames.
local spellHoverRawKeys = {}
local spellHoverRawBtns = {}
local spellHoverRawAnchors = {}
--- Expanded (mirror chords) payload used at runtime and by the secure header.
local spellHoverKeys = {}
local spellHoverBtns = {}
local spellHoverMouseButtons = {}
--- Parallel to spellHoverKeys: true when the chord is a real mouse BUTTON (3/4/5), not wheel/keyboard.
--- Classic clients cast mouse buttons via frame typeN attrs, so they must skip the header SetBindingClick.
local spellHoverIsButton = {}
--- Parallel hovercast macro bodies (Clicked-style: inline `macrotext` on UF, not `/click` indirection).
local spellHoverMacroTexts = {}
--- Normalized chords in expanded `spellHoverKeys`; bar scan / UF attrs skip these (spell bind wins on UF).
local spellHoverChordSet = {}
--- Bar columns (1–19) claimed by a spell UF hover bind; blocks synthesized bar modifier combos.
local spellHoverCols = {}
--- When true, `spellHoverKeys`/`spellHoverBtns` are already expanded by DirectBind (no re-expand).
local spellHoverPrebuiltFromDirectBind = false

--- Mouse-enabled descendants wrapped for hovercast OnEnter (auras / catchers steal outer enter).
local MAX_HOVERCAST_WRAP_DEPTH = 4
local MAX_HOVERCAST_WRAP_CHILDREN = 80

local MODIFIER_COMBOS = {
    "", "shift-", "ctrl-", "alt-",
    "shift-ctrl-", "shift-alt-", "ctrl-alt-", "shift-ctrl-alt-",
}

-- Edit Mode clients remap BUTTON3/4/5 at the engine level via C_ClickBindings.
-- Addon-owned frames use SetPassThroughButtons + SetBindingClick.
-- Blizzard SecureUnitButtons on Edit Mode / secret-value clients are WrapScript
-- only. RegisterForClicks, SetAttribute, SetPassThroughButtons, and HookScript
-- taint those buttons, so Edit Mode ClearTarget and compact health colors fail.
local isEditModeClient = FLUX_API and FLUX_API.hasEditMode

-- ---------------------------------------------------------------------------
-- KEYBIND PARSING
-- ---------------------------------------------------------------------------

local function ParseKeybind(keybind)
    local parts = {}
    local current = ""
    for i = 1, #keybind do
        local char = keybind:sub(i, i)
        if char == "-" and #current > 0 then
            table.insert(parts, current)
            current = ""
        else
            current = current .. char
        end
    end
    local baseKey = current

    -- Normalize modifier order to match WoW's SecureButton_GetModifierPrefix:
    -- shift- then ctrl- then alt-   (always this order regardless of keybind string)
    local hasShift, hasCtrl, hasAlt = false, false, false
    for _, p in ipairs(parts) do
        local low = string.lower(p)
        if low == "shift" then hasShift = true
        elseif low == "ctrl" then hasCtrl = true
        elseif low == "alt" then hasAlt = true end
    end
    local modPrefix = ""
    if hasShift then modPrefix = modPrefix .. "shift-" end
    if hasCtrl  then modPrefix = modPrefix .. "ctrl-" end
    if hasAlt   then modPrefix = modPrefix .. "alt-" end

    return modPrefix, baseKey
end

local function ClassifyMouseKeybind(keybind)
    local modPrefix, baseKey = ParseKeybind(keybind)
    local buttonIndex = baseKey:match("^BUTTON(%d+)$")
    local idx = buttonIndex and tonumber(buttonIndex)
    if idx and idx >= 3 then
        return "button", modPrefix, idx
    end
    if baseKey == "MOUSEWHEELUP" or baseKey == "MOUSEWHEELDOWN" then
        return "wheel", modPrefix, nil
    end
    return nil
end

--- _HC has no ButtonFX KeyBind remap. LeftButton hits type / type1 + macrotext1.
local function SpellHoverVirtualMouseButton(_chord)
    return "LeftButton"
end

local function NormalizeChord(key)
    if type(key) ~= "string" or key == "" then return "" end
    if _G.FluxBinding and _G.FluxBinding.NormalizeChord then
        local nk = _G.FluxBinding.NormalizeChord(key)
        if type(nk) == "string" and nk ~= "" then return nk end
    end
    -- canonical ALT-CTRL-SHIFT-META-KEY order, uppercase
    local modPrefix, baseKey = ParseKeybind(string.upper(key))
    local hasAlt = modPrefix:find("alt%-") ~= nil
    local hasCtrl = modPrefix:find("ctrl%-") ~= nil
    local hasShift = modPrefix:find("shift%-") ~= nil
    local out = ""
    if hasAlt then out = out .. "ALT-" end
    if hasCtrl then out = out .. "CTRL-" end
    if hasShift then out = out .. "SHIFT-" end
    return out .. baseKey
end

local function FindChordColumn(normChord)
    if _G.FluxBinding and _G.FluxBinding.FindColumnForChord and normChord and normChord ~= "" then
        return _G.FluxBinding.FindColumnForChord(normChord)
    end
    return nil
end

local function IndexSpellHoverRow(chord, btn)
    local nk = NormalizeChord(chord)
    if nk == "" then return end
    spellHoverKeys[#spellHoverKeys + 1] = chord
    spellHoverBtns[#spellHoverBtns + 1] = btn
    spellHoverMouseButtons[#spellHoverMouseButtons + 1] = SpellHoverVirtualMouseButton(chord)
    local kind = ClassifyMouseKeybind(chord)
    spellHoverIsButton[#spellHoverKeys] = (kind == "button")
    spellHoverChordSet[nk] = true
    local col = FindChordColumn(nk)
    if col then
        spellHoverCols[col] = true
    end
end

local function RebuildSpellHoverChordSet()
    wipe(spellHoverChordSet)
    wipe(spellHoverCols)
    wipe(spellHoverKeys)
    wipe(spellHoverBtns)
    wipe(spellHoverMouseButtons)
    wipe(spellHoverIsButton)
    wipe(spellHoverMacroTexts)

    if spellHoverPrebuiltFromDirectBind then
        for i = 1, #spellHoverRawKeys do
            local k = spellHoverRawKeys[i]
            local b = spellHoverRawBtns[i]
            if type(k) == "string" and k ~= "" and type(b) == "string" and b ~= "" then
                IndexSpellHoverRow(k, b)
            end
        end
        return
    end

    local expandFn = _G.FluxSpellBindingActionBarMap_ExpandExplicitMirrorChords
    local seenChord = {}

    for i = 1, #spellHoverRawKeys do
        local k = spellHoverRawKeys[i]
        local b = spellHoverRawBtns[i]
        local anchor = spellHoverRawAnchors[i]
        if type(k) == "string" and k ~= "" and type(b) == "string" and b ~= "" then
            local expanded = { k }
            if expandFn then
                local opts
                if anchor then
                    opts = { anchorSpellID = anchor }
                end
                local out = expandFn({ k }, {}, nil, opts)
                if type(out) == "table" and #out > 0 then
                    expanded = out
                end
            end
            for ei = 1, #expanded do
                local ek = expanded[ei]
                local nk = NormalizeChord(ek)
                if nk ~= "" and not seenChord[nk] then
                    seenChord[nk] = true
                    IndexSpellHoverRow(ek, b)
                end
            end
        end
    end
end

local function SpellHoverHcFrameReady(hcBtnName)
    if type(hcBtnName) ~= "string" or hcBtnName == "" then return false end
    return _G[hcBtnName] ~= nil
end

--- True when DirectBind owns this chord for UF hover and the `_HC` sibling frame exists.
local function IsSpellHoverChord(key)
    local nk = NormalizeChord(key)
    if nk == "" or not spellHoverChordSet[nk] then return false end
    for i = 1, #spellHoverKeys do
        if NormalizeChord(spellHoverKeys[i]) == nk then
            return SpellHoverHcFrameReady(spellHoverBtns[i])
        end
    end
    return false
end

--- True when this exact chord is UF spell-hover (committed `_HC` row), not a mirror-only block entry.
local function IsBareSpellHoverChord(key)
    if not IsSpellHoverChord(key) then return false end
    local modPrefix = ParseKeybind(key)
    return modPrefix == ""
end

--- True only when the unmodified BUTTONn chord is spell-owned (bare key, not SHIFT/CTRL variants).
local function IsBareMouseButtonClaimedBySpellHover(buttonIndex)
    buttonIndex = tonumber(buttonIndex)
    if not buttonIndex then return false end
    return IsSpellHoverChord("BUTTON" .. buttonIndex)
end

--- UF hover: route SHIFT/CTRL on bare spell-hover columns to FluxActionStripButton{col} (shared-slot [mod]).
local function AppendBarModifierBindsForSpellHoverColumns(bindKeys, bindBtnNames)
    local seen = {}
    for i = 1, #bindKeys do
        seen[NormalizeChord(bindKeys[i])] = true
    end
    for i = 1, #spellHoverKeys do
        local key = spellHoverKeys[i]
        if not IsBareSpellHoverChord(key) then
            -- skip
        else
            local nk = NormalizeChord(key)
            local col = FindChordColumn(nk)
            if col then
                local kind, modPrefix, buttonIndex = ClassifyMouseKeybind(key)
                local bareSuffix
                if kind == "button" and buttonIndex then
                    bareSuffix = "BUTTON" .. buttonIndex
                else
                    bareSuffix = select(2, ParseKeybind(key))
                end
                if bareSuffix and bareSuffix ~= "" then
                    local btnName = StripMainButtonName(col)
                    for _, combo in ipairs(MODIFIER_COMBOS) do
                        if combo ~= "" then
                            local chord = combo:upper() .. bareSuffix
                            local cn = NormalizeChord(chord)
                            if cn ~= "" and not IsSpellHoverChord(chord) and not seen[cn] then
                                seen[cn] = true
                                bindKeys[#bindKeys + 1] = chord
                                bindBtnNames[#bindBtnNames + 1] = btnName
                            end
                        end
                    end
                end
            end
        end
    end
end

--- When bare spell-hover owns a chord, keep column in buttonMap for modifier synthesis (mouse + keyboard cols).
local function EnsureBarMapForSpellHoverBareChords(buttonMap, buttonDefaults, boundIndices)
    for i = 1, #spellHoverKeys do
        local key = spellHoverKeys[i]
        if not IsBareSpellHoverChord(key) then
            -- skip
        else
            local nk = NormalizeChord(key)
            local col = FindChordColumn(nk)
            if not col then
                -- skip
            else
                local kind, modPrefix, buttonIndex = ClassifyMouseKeybind(key)
                if kind == "button" and modPrefix == "" and buttonIndex then
                    local idx = tonumber(buttonIndex)
                    boundIndices[idx] = true
                    local btnName = StripMainButtonName(col)
                    if not buttonDefaults[idx] then
                        buttonDefaults[idx] = btnName
                    end
                    if not buttonMap[idx] then
                        buttonMap[idx] = {}
                    end
                end
            end
        end
    end
end

--- Classic UF: per-modifier bar attrs when bare BUTTONn is spell-hover (no `*typeN` wildcard).
local function ApplyBarModifierPassthroughAttrs(frame, tracked, buttonMap, buttonDefaults)
    for index, modMap in pairs(buttonMap) do
        if IsBareMouseButtonClaimedBySpellHover(index) then
            local default = buttonDefaults[index]
            if not default then
                for _, v in pairs(modMap) do default = v; break end
            end
            for _, combo in ipairs(MODIFIER_COMBOS) do
                if combo == "" then
                    -- skip bare; spell-hover owns typeN
                else
                    local chord = combo:upper() .. "BUTTON" .. index
                    if not IsSpellHoverChord(chord) then
                        local target = modMap[combo] or default
                        if target then
                            local typeKey  = combo .. "type" .. index
                            local macroKey = combo .. "macrotext" .. index
                            frame:SetAttribute(typeKey, "macro")
                            frame:SetAttribute(macroKey, "/click " .. target)
                            tracked[#tracked + 1] = typeKey
                            tracked[#tracked + 1] = macroKey
                        end
                    end
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- KEYBIND SCANNING
-- ---------------------------------------------------------------------------

local function ScanMouseKeybindsInternal(forDetection)
    local btnPrefixes = {}
    local btnIndices = {}
    local btnCommands = {}
    local wheelKeys = {}
    local wheelBtnNames = {}

    for _, entry in ipairs(ACTION_BINDINGS) do
        if forDetection or _G[entry.button] then
            for k = 1, select('#', GetBindingKey(entry.binding)) do
                local key = select(k, GetBindingKey(entry.binding))
                if key and key ~= "" and (forDetection or not IsSpellHoverChord(key)) then
                    local kind, modPrefix, buttonIndex = ClassifyMouseKeybind(key)
                    if kind == "button" then
                        table.insert(btnPrefixes, modPrefix)
                        table.insert(btnIndices, buttonIndex)
                        table.insert(btnCommands, "/click " .. entry.button)
                    elseif kind == "wheel" then
                        table.insert(wheelKeys, key)
                        table.insert(wheelBtnNames, entry.button)
                    end
                end
            end
        end
    end

    return btnPrefixes, btnIndices, btnCommands, wheelKeys, wheelBtnNames
end

local function ScanMouseKeybinds()
    return ScanMouseKeybindsInternal(false)
end

--- Unfiltered scan for routing detection / passthrough (no spell-hover suppression).
local function ScanMouseKeybindsForDetection()
    return ScanMouseKeybindsInternal(true)
end

--- buttonIndex -> modPrefix -> FluxActionStripButton name; used for Edit Mode SetBindingClick + classic attrs.
local function BuildButtonMapFromBindings()
    RebuildSpellHoverChordSet()
    local btnPrefixes, btnIndices, btnCommands = ScanMouseKeybinds()
    local buttonMap = {}
    local buttonDefaults = {}
    local boundIndices = {}

    for i = 1, #btnPrefixes do
        local prefix = btnPrefixes[i]
        local index = tonumber(btnIndices[i])
        local btnName = btnCommands[i]:match("/click (%S+)")
        if btnName and index then
            if not buttonMap[index] then buttonMap[index] = {} end
            buttonMap[index][prefix] = btnName
            if prefix == "" then buttonDefaults[index] = btnName end
            boundIndices[index] = true
        end
    end

    EnsureBarMapForSpellHoverBareChords(buttonMap, buttonDefaults, boundIndices)
    return buttonMap, buttonDefaults, boundIndices
end

-- Forward declaration (defined in the Edit Mode section below)
local BuildButtonBindData

-- Keep ordinary unit interactions on the native release edge. Only the extra
-- mouse buttons need key-down delivery for action-bar/hovercast routing.
-- AnyDown drops the ordinary left-button release event on these frames.
local function RegisterFrameClickEdges(frame)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonDown", "Button4Down", "Button5Down")
end

-- ---------------------------------------------------------------------------
-- PERMANENT ATTRIBUTE MANAGEMENT (typeN/macrotextN on unit frames)
-- ---------------------------------------------------------------------------

--- Remove stale `*typeN` attrs from older builds that treated bare spell-hover as all modifiers.
local function ClearLegacyWildcardSpellHoverAttrs(frame)
    if not frame then return end
    for idx = 3, 5 do
        frame:SetAttribute("*type" .. idx, nil)
        frame:SetAttribute("*macrotext" .. idx, nil)
    end
end

--- Read UF-hover macro body from a DirectBind `_HC` anchor (set by ProvisionUfSiblingForButton).
local function ResolveSpellHoverMacrotextFromFrame(hcBtnName)
    if type(hcBtnName) ~= "string" or hcBtnName == "" then return nil end
    local f = _G[hcBtnName]
    if not f or not f.GetAttribute then return nil end
    local body = f:GetAttribute("flux-macrotext-hovercast")
    if type(body) ~= "string" or body == "" then
        body = f:GetAttribute("macrotext")
    end
    if type(body) ~= "string" or body == "" then return nil end
    if body:match("^%s*/click%s") then return nil end
    return body
end

local function SyncSpellHoverMacroTexts(passedBodies)
    wipe(spellHoverMacroTexts)
    for i = 1, #spellHoverKeys do
        local body
        if type(passedBodies) == "table" then
            body = passedBodies[i]
        end
        if type(body) ~= "string" or body == "" or body:match("^%s*/click%s") then
            body = ResolveSpellHoverMacrotextFromFrame(spellHoverBtns[i])
        end
        spellHoverMacroTexts[i] = (type(body) == "string" and body ~= "") and body or nil
    end
end

--- Clicked-style UF attrs: spell-hover mouse chords fire hovercast macro on the UF frame.
--- Classic: inline `macrotext` with [@mouseover] clauses (not `/click` _HC — unreliable on legacy clients).
--- Bare `BUTTONn` uses `typeN` only (not `*typeN`) so SHIFT/CTRL mini-row chords stay on the bar.
local function ApplySpellHoverKeybindAttributes(frame, tracked)
    for i = 1, #spellHoverKeys do
        local key = spellHoverKeys[i]
        local hcBtn = spellHoverBtns[i]
        if type(key) == "string" and key ~= "" and type(hcBtn) == "string" and hcBtn ~= "" then
            local kind, modPrefix, buttonIndex = ClassifyMouseKeybind(key)
            if kind == "button" and buttonIndex then
                local prefix = modPrefix
                local typeKey  = prefix .. "type" .. buttonIndex
                local macroKey = prefix .. "macrotext" .. buttonIndex
                local macroBody = spellHoverMacroTexts[i]
                if type(macroBody) ~= "string" or macroBody == "" then
                    macroBody = ResolveSpellHoverMacrotextFromFrame(hcBtn)
                end
                if type(macroBody) ~= "string" or macroBody == "" then
                    macroBody = "/click " .. hcBtn
                end
                frame:SetAttribute(typeKey, "macro")
                frame:SetAttribute(macroKey, macroBody)
                tracked[#tracked + 1] = typeKey
                tracked[#tracked + 1] = macroKey
            end
        end
    end
end

-- Apply mouse-button keybind attributes to a single frame (classic_era only).
-- On Edit Mode clients, SetPassThroughButtons + SetBindingClick is used instead.
local function ApplyKeybindAttributes(frame)
    if not frame then return end
    if InCombatLockdown() then return end

    RebuildSpellHoverChordSet()
    SyncSpellHoverMacroTexts(nil)

    local prev = frame.__fluxKeybindAttrs
    if prev then
        for i = 1, #prev do
            frame:SetAttribute(prev[i], nil)
        end
    end
    ClearLegacyWildcardSpellHoverAttrs(frame)

    local buttonMap, buttonDefaults = BuildButtonMapFromBindings()
    local tracked = {}

    for index, modMap in pairs(buttonMap) do
        if not IsBareMouseButtonClaimedBySpellHover(index) then
            for prefix, btnName in pairs(modMap) do
                local attrPrefix = prefix
                if attrPrefix == "" then attrPrefix = "*" end
                local typeKey  = attrPrefix .. "type" .. index
                local macroKey = attrPrefix .. "macrotext" .. index
                frame:SetAttribute(typeKey, "macro")
                frame:SetAttribute(macroKey, "/click " .. btnName)
                tracked[#tracked + 1] = typeKey
                tracked[#tracked + 1] = macroKey
            end
        end
    end

    ApplySpellHoverKeybindAttributes(frame, tracked)
    ApplyBarModifierPassthroughAttrs(frame, tracked, buttonMap, buttonDefaults)
    frame.__fluxKeybindAttrs = tracked
end

-- ---------------------------------------------------------------------------
-- EDIT MODE: SetPassThroughButtons + SetBindingClick
-- ---------------------------------------------------------------------------

local BUTTON_INDEX_TO_PASSTHROUGH = {
    ["3"] = "MiddleButton",
    ["4"] = "Button4",
    ["5"] = "Button5",
}

local function GetSpellHoverClaimedButtonIndices()
    local claimed = {}
    for nk in pairs(spellHoverChordSet) do
        local kind, _, idx = ClassifyMouseKeybind(nk)
        if kind == "button" and idx then
            claimed[idx] = true
        end
    end
    return claimed
end

--- Passthrough when this index has a bar route and/or bare spell-hover needs SetBindingClick (Edit Mode).
local function BoundIndicesHasIndex(boundIndices, index)
    index = tonumber(index)
    if not index or type(boundIndices) ~= "table" then return false end
    return boundIndices[index] == true
end

local function ShouldPassthroughMouseIndex(index, boundIndices)
    index = tonumber(index)
    if not index or index < 3 then return false end
    if IsBareMouseButtonClaimedBySpellHover(index) then return true end
    if isEditModeClient then
        return BoundIndicesHasIndex(boundIndices, index)
    end
    return true
end

local function BuildPassthroughButtonNames(bindKeys, boundIndices)
    local seen = {}
    local out = {}
    local function addIndex(index)
        if not ShouldPassthroughMouseIndex(index, boundIndices) then return end
        local name = BUTTON_INDEX_TO_PASSTHROUGH[tostring(index)]
        if name and not seen[name] then
            seen[name] = true
            out[#out + 1] = name
        end
    end
    if type(boundIndices) == "table" then
        for index in pairs(boundIndices) do addIndex(index) end
    end
    local _, detIndices = ScanMouseKeybindsForDetection()
    for i = 1, #detIndices do
        addIndex(detIndices[i])
    end
    if type(bindKeys) == "table" then
        for i = 1, #bindKeys do
            local kind, _, idx = ClassifyMouseKeybind(bindKeys[i])
            if kind == "button" then addIndex(idx) end
        end
    end
    for i = 1, #spellHoverKeys do
        local kind, _, idx = ClassifyMouseKeybind(spellHoverKeys[i])
        if kind == "button" then addIndex(idx) end
    end
    return out
end

--- Edit Mode: SetPassThroughButtons + secure SetBindingClick only (no typeN attrs — they block passthrough).
local function ApplyEditModeSpellHoverFrameSetup(frame)
    if not frame or frame:IsForbidden() or InCombatLockdown() then return end

    local prev = frame.__fluxKeybindAttrs
    if prev then
        for i = 1, #prev do
            frame:SetAttribute(prev[i], nil)
        end
    end
    ClearLegacyWildcardSpellHoverAttrs(frame)
    for idx = 3, 5 do
        frame:SetAttribute("type" .. idx, nil)
        frame:SetAttribute("macrotext" .. idx, nil)
        frame:SetAttribute("shift-type" .. idx, nil)
        frame:SetAttribute("shift-macrotext" .. idx, nil)
        frame:SetAttribute("ctrl-type" .. idx, nil)
        frame:SetAttribute("ctrl-macrotext" .. idx, nil)
    end
    frame.__fluxKeybindAttrs = nil

    if frame.RegisterForClicks then
        RegisterFrameClickEdges(frame)
    end

    if frame.SetPassThroughButtons then
        local bindKeys, _, passthrough = BuildButtonBindData()
        if #passthrough > 0 then
            frame:SetPassThroughButtons(unpack(passthrough))
        else
            frame:SetPassThroughButtons()
        end
    end
end

-- Build the full list of override binding keys and target frame names for
-- Edit Mode clients.  Also returns the list of passthrough button names.
BuildButtonBindData = function()
    local buttonMap, buttonDefaults, boundIndices = BuildButtonMapFromBindings()

    local bindKeys = {}
    local bindBtnNames = {}

    for index, modMap in pairs(buttonMap) do
        local baseButton = "BUTTON" .. index
        local default = buttonDefaults[index]
        if not default then
            for _, v in pairs(modMap) do default = v; break end
        end
        for _, combo in ipairs(MODIFIER_COMBOS) do
            local chord = combo:upper() .. baseButton
            -- Bare spell-hover uses spellHoverKeys; modifiers stay on the bar (shared-key parity).
            if not IsSpellHoverChord(chord) then
                local target = modMap[combo] or default
                if target then
                    bindKeys[#bindKeys + 1] = chord
                    bindBtnNames[#bindBtnNames + 1] = target
                end
            end
        end
    end

    AppendBarModifierBindsForSpellHoverColumns(bindKeys, bindBtnNames)

    local passthrough = BuildPassthroughButtonNames(bindKeys, boundIndices)
    return bindKeys, bindBtnNames, passthrough, boundIndices
end

local function RefreshAllFrameAttributes()
    if InCombatLockdown() then return end
    RebuildSpellHoverChordSet()
    if isEditModeClient then
        for _, frame in ipairs(registeredFrames) do
            if not frame._fluxBlizzardSecureWrapOnly then
                ApplyEditModeSpellHoverFrameSetup(frame)
            end
        end
    else
        for _, frame in ipairs(registeredFrames) do
            if not frame._fluxBlizzardSecureWrapOnly then
                ApplyKeybindAttributes(frame)
            end
        end
    end
end

local function ReapplyAllRegisteredFrames()
    if InCombatLockdown() then return end
    RebuildSpellHoverChordSet()
    for _, frame in ipairs(registeredFrames) do
        if frame._fluxBlizzardSecureWrapOnly then
            WrapHovercastEnterLeave(frame)
        else
            if isEditModeClient then
                ApplyEditModeSpellHoverFrameSetup(frame)
            else
                ApplyKeybindAttributes(frame)
            end
            -- Auras / catchers may appear after first register; wrap any new mouse children.
            WrapHovercastMouseChildren(frame)
        end
    end
end

-- ---------------------------------------------------------------------------
-- SECURE BINDING DATA (scroll wheel + mouse buttons on Edit Mode)
-- ---------------------------------------------------------------------------

local function FormatNewtable(list)
    if #list == 0 then
        return "newtable()"
    end
    local escaped = {}
    for i, v in ipairs(list) do
        escaped[i] = '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
    end
    return "newtable(" .. table.concat(escaped, ", ") .. ")"
end

--- Boolean variant: secure snippets read these as true/false to gate per-row behavior.
--- Length is matched to `count` so indices line up with the string lists (nil holes become false).
local function FormatNewtableBool(list, count)
    if count <= 0 then
        return "newtable()"
    end
    local parts = {}
    for i = 1, count do
        parts[i] = list[i] and "true" or "false"
    end
    return "newtable(" .. table.concat(parts, ", ") .. ")"
end

local function UpdateSecureBindingData()
    if InCombatLockdown() then
        pendingHoverRoutingFlush = true
        return false
    end

    SyncHoverRoutingLifecycle()
    if not header then return false end

    RebuildSpellHoverChordSet()
    local _, _, _, wheelKeys, wheelBtnNames = ScanMouseKeybinds()

    local buttonBindKeys, buttonBtnNames, buttonVirtualBtns = {}, {}, {}
    if isEditModeClient then
        buttonBindKeys, buttonBtnNames, _, _ = BuildButtonBindData()
        buttonVirtualBtns = {}
        for i = 1, #buttonBindKeys do
            -- Backup parity: bar UF hover routes use "Keybind", not LeftButton.
            buttonVirtualBtns[i] = "Keybind"
        end
    end

    local command = string.format([[
        wheelKeys                   = %s
        wheelBtnNames               = %s
        buttonBindKeys              = %s
        buttonBtnNames              = %s
        buttonVirtualBtns           = %s
        spellHoverKeys              = %s
        spellHoverBtnNames          = %s
        spellHoverMouseButtons      = %s
        spellHoverIsButton          = %s
        allowMouseButtonBindingClick = %s
    ]],
        FormatNewtable(wheelKeys),
        FormatNewtable(wheelBtnNames),
        FormatNewtable(buttonBindKeys),
        FormatNewtable(buttonBtnNames),
        FormatNewtable(buttonVirtualBtns),
        FormatNewtable(spellHoverKeys),
        FormatNewtable(spellHoverBtns),
        FormatNewtable(spellHoverMouseButtons),
        FormatNewtableBool(spellHoverIsButton, #spellHoverKeys),
        isEditModeClient and "true" or "false"
    )
    if not HeaderExecute(command) then
        pendingHoverRoutingFlush = true
        return false
    end

    HeaderExecute([[
        local btn = currentButton
        if btn ~= nil then
            self:RunFor(btn, self:GetAttribute("clear-bindings"))
            self:RunFor(btn, self:GetAttribute("setup-bindings"))
        end
    ]])
    pendingHoverRoutingFlush = false
    return true
end

-- ---------------------------------------------------------------------------
-- HEADER CREATION
-- ---------------------------------------------------------------------------

local function CreateHeader()
    if header then return end

    header = CreateFrame("Frame", "FluxClickCastHeader", UIParent,
        "SecureHandlerBaseTemplate,SecureHandlerAttributeTemplate")

    HeaderExecute([[
        wheelKeys                   = newtable()
        wheelBtnNames               = newtable()
        buttonBindKeys              = newtable()
        buttonBtnNames              = newtable()
        buttonVirtualBtns           = newtable()
        spellHoverKeys              = newtable()
        spellHoverBtnNames          = newtable()
        spellHoverMouseButtons      = newtable()
        spellHoverIsButton          = newtable()
        allowMouseButtonBindingClick = false
        currentButton               = nil
    ]])

    -- Secure snippet: OnEnter - set up override bindings (wheel + mouse buttons)
    HeaderSetSnippet("setup-bindings", [[
        if currentButton ~= nil and currentButton ~= self then
            control:RunFor(currentButton, control:GetAttribute("clear-bindings"))
        end
        currentButton = self

        for i = 1, table.maxn(wheelKeys) do
            local key     = wheelKeys[i]
            local btnName = wheelBtnNames[i]
            if key and btnName then
                self:SetBindingClick(true, key, btnName, "Keybind")
            end
        end
        for i = 1, table.maxn(buttonBindKeys) do
            local key     = buttonBindKeys[i]
            local btnName = buttonBtnNames[i]
            if key and btnName then
                local vbtn = buttonVirtualBtns[i] or "Keybind"
                self:SetBindingClick(true, key, btnName, vbtn)
            end
        end
        for i = 1, table.maxn(spellHoverKeys) do
            local key     = spellHoverKeys[i]
            local btnName = spellHoverBtnNames[i]
            local mbtn    = spellHoverMouseButtons[i]
            local isBtn   = spellHoverIsButton[i]
            if key and btnName then
                -- Classic (no Edit Mode): mouse buttons fire via the frame's own typeN
                -- attrs. An override binding would capture the button globally and block
                -- the frame click, so skip SetBindingClick for real mouse buttons here.
                if not (isBtn and not allowMouseButtonBindingClick) then
                    self:SetBindingClick(true, key, btnName, mbtn or "LeftButton")
                end
            end
        end
    ]])

    -- Secure snippet: OnLeave - clear all override bindings
    -- Guard: only clear if this frame still owns currentButton (sibling/child
    -- OnEnter may have already re-armed before our OnLeave).
    HeaderSetSnippet("clear-bindings", [[
        for i = 1, table.maxn(wheelKeys) do
            local key = wheelKeys[i]
            if key then self:ClearBinding(key) end
        end
        for i = 1, table.maxn(buttonBindKeys) do
            local key = buttonBindKeys[i]
            if key then self:ClearBinding(key) end
        end
        for i = 1, table.maxn(spellHoverKeys) do
            local key   = spellHoverKeys[i]
            local isBtn = spellHoverIsButton[i]
            -- Mirror setup-bindings: only clear what we actually bound.
            if key and not (isBtn and not allowMouseButtonBindingClick) then
                self:ClearBinding(key)
            end
        end
        if currentButton == self then
            currentButton = nil
        end
    ]])

    -- Clear bindings if mouseover unit disappears. Keep armed while the frame
    -- that ran setup-bindings (outer or wrapped child) is still under the mouse
    -- — peek can stay true over auras while unit-exists flickers.
    HeaderSetSnippet("_onattributechanged", [[
        if name == "unit-exists" and value == "false" and currentButton ~= nil then
            local btn = currentButton
            if btn:IsUnderMouse() and btn:IsVisible() then
                -- Stay armed; mouse still over the arming surface (incl. auras).
            else
                self:RunFor(btn, self:GetAttribute("clear-bindings"))
                if currentButton == btn then
                    currentButton = nil
                end
            end
        end
    ]])

end

local function UnregisterUnitExistsDriver()
    if not header or not unitExistsDriverRegistered then return end
    if InCombatLockdown() then
        pendingDriverPark = true
        return
    end
    UnregisterAttributeDriver(header, "unit-exists")
    unitExistsDriverRegistered = false
end

local function HasActiveRoutingData()
    RebuildSpellHoverChordSet()
    if #spellHoverKeys > 0 then
        return true
    end
    local btnPrefixes, _, _, wheelKeys = ScanMouseKeybindsForDetection()
    return #btnPrefixes > 0 or #wheelKeys > 0
end

--- World nameplate sweeps must not keep [@mouseover,exists] live. Arm only
--- while a registered unit frame (or wrapped child) is actually hovered.
local function RegisterUnitExistsDriver()
    if InCombatLockdown() then return end
    if not SnippetsWork() then return end
    if not header or unitExistsDriverRegistered or #spellHoverKeys == 0 then
        return
    end
    if ufHoverCount <= 0 then
        return
    end
    RegisterAttributeDriver(header, "unit-exists", "[@mouseover,exists] true; false")
    unitExistsDriverRegistered = true
end

NoteUfHoverEnter = function()
    ufHoverCount = ufHoverCount + 1
    if InCombatLockdown() then
        pendingDriverPark = false
        return
    end
    RegisterUnitExistsDriver()
end

NoteUfHoverLeave = function()
    ufHoverCount = ufHoverCount - 1
    if ufHoverCount < 0 then
        ufHoverCount = 0
    end
    if ufHoverCount > 0 then
        return
    end
    if InCombatLockdown() then
        pendingDriverPark = true
        return
    end
    UnregisterUnitExistsDriver()
end

local function HookUfHoverDriver(frame)
    if not frame or frame._fluxUfHoverDriverHooked or not frame.HookScript then
        return
    end
    frame._fluxUfHoverDriverHooked = true
    pcall(frame.HookScript, frame, "OnEnter", NoteUfHoverEnter)
    pcall(frame.HookScript, frame, "OnLeave", NoteUfHoverLeave)
end

-- ---------------------------------------------------------------------------
-- UNIT FRAME REGISTRATION
-- ---------------------------------------------------------------------------

local ENTER_SNIPPET = [[
    local hdr = control
    hdr:RunFor(self, hdr:GetAttribute("setup-bindings"))
]]

local LEAVE_SNIPPET = [[
    local hdr = control
    -- Sibling/child may have already re-armed; only clear if we still own it.
    if currentButton == self then
        hdr:RunFor(self, hdr:GetAttribute("clear-bindings"))
    end
]]

local function WrapHovercastEnterLeave(frame)
    if not header or not frame then return false end
    if frame.__fluxHovercastWrapped then return false end
    if frame.IsForbidden and frame:IsForbidden() then return false end
    local wrapped = false
    if SnippetsWork() then
        local R = Flux and Flux.Restricted
        if R and R.WrapScript then
            local enterOk = R.WrapScript(header, frame, "OnEnter", ENTER_SNIPPET)
            local leaveOk = R.WrapScript(header, frame, "OnLeave", LEAVE_SNIPPET)
            wrapped = enterOk and leaveOk and true or false
        end
    elseif header.WrapScript then
        -- Camelot Restricted.WrapScript no-ops. Call the header directly so UF
        -- OnEnter can SetBindingClick. Other Restricted callers stay gated.
        local enterOk = pcall(header.WrapScript, header, frame, "OnEnter", ENTER_SNIPPET)
        local leaveOk = pcall(header.WrapScript, header, frame, "OnLeave", LEAVE_SNIPPET)
        wrapped = enterOk and leaveOk and true or false
    end
    if not wrapped then
        return false
    end
    frame.__fluxHovercastWrapped = true
    return true
end

local function UnwrapHovercastEnterLeave(frame)
    if not header or not frame then return end
    if not frame.__fluxHovercastWrapped then return end
    if frame.IsForbidden and frame:IsForbidden() then
        frame.__fluxHovercastWrapped = nil
        return
    end
    if SnippetsWork() then
        local R = Flux and Flux.Restricted
        if R and R.UnwrapScript then
            R.UnwrapScript(header, frame, "OnEnter")
            R.UnwrapScript(header, frame, "OnLeave")
        end
    elseif header.UnwrapScript then
        pcall(header.UnwrapScript, header, frame, "OnEnter")
        pcall(header.UnwrapScript, header, frame, "OnLeave")
    end
    frame.__fluxHovercastWrapped = nil
    frame.__fluxHovercastOwner = nil
end

local function ShouldWrapHovercastChild(child, owner)
    if not child or child == owner then return false end
    if child.IsForbidden and child:IsForbidden() then return false end
    if child.__fluxHovercastWrapped then return false end
    if registeredLookup[child] then return false end
    if child.IsMouseEnabled and not child:IsMouseEnabled() then return false end
    -- Need a scriptable frame (Button/Frame), not a Texture/FontString.
    if not child.SetScript and not child.HookScript then return false end
    -- WrapScript on Blizzard StatusBars taints UnitFrameHealthBar_Update / mana updates.
    if child.IsObjectType and child:IsObjectType("StatusBar") then return false end
    if child == owner.healthbar or child == owner.manabar then return false end
    if child == owner.HealthBar or child == owner.PowerBar then return false end
    return true
end

--- Aura buttons / spec / transmog catchers steal OnEnter from FluxUnitFrameOuter.
--- Peek already treats descendants as hover; secure SetBindingClick must match.
WrapHovercastMouseChildren = function(owner)
    if not header or not owner then return end
    local list = owner.__fluxHovercastChildWraps
    if not list then
        list = {}
        owner.__fluxHovercastChildWraps = list
    end

    local count = #list
    local function walk(parent, depth)
        if depth > MAX_HOVERCAST_WRAP_DEPTH then return end
        if count >= MAX_HOVERCAST_WRAP_CHILDREN then return end
        if not parent or not parent.GetChildren then return end
        local ok, children = pcall(function()
            return { parent:GetChildren() }
        end)
        if not ok or type(children) ~= "table" then return end
        for i = 1, #children do
            if count >= MAX_HOVERCAST_WRAP_CHILDREN then return end
            local child = children[i]
            if ShouldWrapHovercastChild(child, owner) then
                if WrapHovercastEnterLeave(child) then
                    child.__fluxHovercastOwner = owner
                    HookUfHoverDriver(child)
                    count = count + 1
                    list[count] = child
                end
            end
            -- Descend even when child itself was not wrapped (mouse-disabled parent of auras).
            if child and child.GetChildren and depth < MAX_HOVERCAST_WRAP_DEPTH then
                walk(child, depth + 1)
            end
        end
    end
    walk(owner, 1)
end

local function UnwrapHovercastMouseChildren(owner)
    local list = owner and owner.__fluxHovercastChildWraps
    if not list then return end
    for i = 1, #list do
        UnwrapHovercastEnterLeave(list[i])
    end
    wipe(list)
end

--- Live, Forever, and anniversary: insecure clicks on Blizzard unit buttons
--- taint Edit Mode. classic_era has neither Edit Mode nor secret values.
local function BlizzardButtonsMustStaySecure()
    if isEditModeClient then
        return true
    end
    local cap = Flux and Flux.Cap
    if cap and cap.hasSecretValueAPI then
        return true
    end
    if FLUX_API and FLUX_API.hasSecretValueAPI then
        return true
    end
    return false
end

local BLIZZARD_UNIT_EXACT = {
    PlayerFrame = true,
    TargetFrame = true,
    FocusFrame = true,
    PetFrame = true,
    TargetFrameToT = true,
    FocusFrameToT = true,
}

local function BlizzardUnitButtonName(frame)
    if not frame or not frame.GetName then
        return nil
    end
    local name = frame:GetName()
    if type(name) ~= "string" or name == "" then
        return nil
    end
    return name
end

local function IsBlizzardCompactOrPartyButton(frame)
    local name = BlizzardUnitButtonName(frame)
    if name then
        if name:sub(1, 4) == "Flux" then
            return false
        end
        if name:match("^PartyMemberFrame%d")
            or name:match("^CompactPartyFrame")
            or name:match("^CompactRaidFrame%d")
            or name:match("^CompactRaidGroup%d+Member%d+") then
            return true
        end
    end
    local parent = frame and frame.GetParent and frame:GetParent()
    local pname = parent and parent.GetName and parent:GetName()
    if pname == "CompactPartyFrame" or pname == "PartyFrame" or pname == "CompactRaidFrameContainer" then
        return true
    end
    local gparent = parent and parent.GetParent and parent:GetParent()
    local gname = gparent and gparent.GetName and gparent:GetName()
    if gname == "CompactPartyFrame" or gname == "PartyFrame" or gname == "CompactRaidFrameContainer" then
        return true
    end
    return false
end

local function IsBlizzardSecureUnitButton(frame)
    if IsBlizzardCompactOrPartyButton(frame) then
        return true
    end
    local name = BlizzardUnitButtonName(frame)
    if not name or name:sub(1, 4) == "Flux" then
        return false
    end
    if BLIZZARD_UNIT_EXACT[name] then
        return true
    end
    if name:match("^Boss%d+TargetFrame$") or name:match("^ArenaEnemyFrame%d+$") then
        return true
    end
    return false
end

local function FluxRaidOwnsCompactFrames()
    local fn = _G.FluxRaid_IsFluxRaidEnabled
    if type(fn) ~= "function" then
        return false
    end
    local ok, on = pcall(fn)
    return ok and on and true or false
end

local function RequestHoverPeek()
    local PF = (ns.Flux and ns.Flux.Bars and ns.Flux.Bars.ProgramFace) or _G.FluxProgramFace
    if PF and PF.RequestHoverPeek then
        pcall(PF.RequestHoverPeek)
    end
end

--- Edit Mode / secret clients: secure OnEnter/OnLeave only. No click or
--- HookScript changes — those taint ClearTarget and compact health colors.
--- Camelot still wraps: hover SetBindingClick lives on this header, not on
--- Restricted (that gate stays for state drivers).
local function RegisterBlizzardSecureFrame(frame)
    if not frame then return end
    if not BlizzardButtonsMustStaySecure() then
        return nil
    end
    if FluxRaidOwnsCompactFrames() and IsBlizzardCompactOrPartyButton(frame) then
        return false
    end
    if registeredLookup[frame] then
        return true
    end
    if frame.IsForbidden and frame:IsForbidden() then
        return false
    end
    if not header or InCombatLockdown() then
        table.insert(pendingFrames, frame)
        return false
    end
    if not WrapHovercastEnterLeave(frame) then
        return false
    end
    frame._fluxBlizzardSecureWrapOnly = true
    table.insert(registeredFrames, frame)
    registeredLookup[frame] = true
    return true
end

local function RegisterFrame(frame)
    if not frame then return end
    if BlizzardButtonsMustStaySecure() and IsBlizzardSecureUnitButton(frame) then
        RegisterBlizzardSecureFrame(frame)
        return
    end
    if not frame.RegisterForClicks then return end
    if registeredLookup[frame] then return end
    if not header then
        table.insert(pendingFrames, frame)
        return
    end

    if InCombatLockdown() then
        table.insert(pendingFrames, frame)
        return
    end

    if isEditModeClient then
        ApplyEditModeSpellHoverFrameSetup(frame)
    else
        RegisterFrameClickEdges(frame)
        ApplyKeybindAttributes(frame)
    end

    if frame.EnableMouseWheel then
        frame:EnableMouseWheel(true)
    end

    -- Wrap OnEnter/OnLeave for override bindings (wheel + mouse buttons + spell hover).
    WrapHovercastEnterLeave(frame)
    WrapHovercastMouseChildren(frame)
    HookUfHoverDriver(frame)

    -- Insecure peek hooks: bar/badge icons follow UF hovercast only while over
    -- a registered unit frame (UPDATE_MOUSEOVER_UNIT alone is unreliable).
    if not frame._fluxMacrotextPeekHooked and frame.HookScript then
        frame._fluxMacrotextPeekHooked = true
        pcall(frame.HookScript, frame, "OnEnter", function()
            local PP = _G.FluxBindingPushPress
            if PP and PP.WakeUfHoverFromUnitFrame then
                pcall(PP.WakeUfHoverFromUnitFrame)
            end
            RequestHoverPeek()
        end)
        pcall(frame.HookScript, frame, "OnLeave", function()
            local PP = _G.FluxBindingPushPress
            if PP and PP.ParkUfHoverFromUnitFrame then
                pcall(PP.ParkUfHoverFromUnitFrame)
            end
            RequestHoverPeek()
        end)
    end

    table.insert(registeredFrames, frame)
    registeredLookup[frame] = true
end

local function UnregisterFrame(frame)
    if not header then return end
    if not frame then return end
    if not registeredLookup[frame] then return end
    if InCombatLockdown() then return end

    if frame._fluxBlizzardSecureWrapOnly then
        -- UnwrapScript only. SetPassThroughButtons / SetAttribute would taint.
    elseif isEditModeClient then
        if frame.SetPassThroughButtons and not frame:IsForbidden() then
            frame:SetPassThroughButtons()
        end
    else
        local prev = frame.__fluxKeybindAttrs
        if prev then
            for i = 1, #prev do
                frame:SetAttribute(prev[i], nil)
            end
            frame.__fluxKeybindAttrs = nil
        end
    end

    UnwrapHovercastMouseChildren(frame)
    UnwrapHovercastEnterLeave(frame)
    frame._fluxBlizzardSecureWrapOnly = nil

    for i, f in ipairs(registeredFrames) do
        if f == frame then
            table.remove(registeredFrames, i)
            break
        end
    end
    registeredLookup[frame] = nil
end

local function ProcessPendingFrames()
    if InCombatLockdown() then return end
    local queue = pendingFrames
    pendingFrames = {}
    for _, frame in ipairs(queue) do
        RegisterFrame(frame)
    end
end

-- Re-apply RegisterForClicks, EnableMouseWheel, and SetPassThroughButtons on an
-- already-registered frame (called after Blizzard code resets frame clicks).
local function ReapplyFrameClicks(frame)
    if not frame then return end
    if not registeredLookup[frame] then return end
    if InCombatLockdown() then return end
    if not frame.RegisterForClicks then return end

    if frame._fluxBlizzardSecureWrapOnly then
        WrapHovercastEnterLeave(frame)
        return
    end

    if isEditModeClient then
        ApplyEditModeSpellHoverFrameSetup(frame)
    else
        RegisterFrameClickEdges(frame)
        ApplyKeybindAttributes(frame)
    end

    if frame.EnableMouseWheel then
        frame:EnableMouseWheel(true)
    end
end

-- ---------------------------------------------------------------------------
-- FRAME DISCOVERY
-- ---------------------------------------------------------------------------

local function IsClickedLoaded()
    return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Clicked")
end

local function RegisterFluxUnitFrames()
    -- Flux uses FluxUnitFrameOuter_<unit> (CreateOuterBorder) for most units; focustarget has no outer
    -- (health-only bar) and uses the base SecureUnitButton FluxUnitFrame_focustarget for clicks.
    local unitNames = {
        "player", "target", "pet", "pettarget", "targettarget",
        "focus", "focustarget",
    }
    for _, unit in ipairs(unitNames) do
        local outer = _G["FluxUnitFrameOuter_" .. unit]
        if outer and outer.RegisterForClicks then
            RegisterFrame(outer)
        else
            local base = _G["FluxUnitFrame_" .. unit]
            if base and base.RegisterForClicks then
                RegisterFrame(base)
            end
        end
    end
end

local function RegisterBlizzardButton(frame)
    if not frame or not frame.RegisterForClicks then
        return
    end
    if FluxRaidOwnsCompactFrames() and IsBlizzardCompactOrPartyButton(frame) then
        return
    end
    RegisterFrame(frame)
end

local function RegisterBlizzardFrames()
    local names = {
        "PlayerFrame", "TargetFrame", "FocusFrame",
        "PetFrame", "TargetFrameToT", "FocusFrameToT",
    }
    for _, name in ipairs(names) do
        local frame = _G[name]
        RegisterBlizzardButton(frame)
    end

    for i = 1, 4 do
        RegisterBlizzardButton(_G["PartyMemberFrame" .. i])
    end

    if PartyFrame and PartyFrame.PartyMemberFramePool then
        for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            RegisterBlizzardButton(frame)
            if frame and frame.PetFrame then
                RegisterBlizzardButton(frame.PetFrame)
            end
        end
    end

    for i = 1, 5 do
        RegisterBlizzardButton(_G["CompactPartyFrameMember" .. i])
        RegisterBlizzardButton(_G["CompactPartyFramePet" .. i])
    end
    for i = 1, 40 do
        RegisterBlizzardButton(_G["CompactRaidFrame" .. i])
    end

    for group = 1, 8 do
        for member = 1, 5 do
            RegisterBlizzardButton(_G["CompactRaidGroup" .. group .. "Member" .. member])
        end
    end

    for i = 1, 5 do
        RegisterBlizzardButton(_G["Boss" .. i .. "TargetFrame"])
    end

    for i = 1, 3 do
        RegisterBlizzardButton(_G["ArenaEnemyFrame" .. i])
    end
end

local function RegisterFluxRaidMouseoverFramesIfPresent()
    if ns and ns.FluxRaidRegisterAllMouseoverKeybindFrames then
        ns.FluxRaidRegisterAllMouseoverKeybindFrames()
    end
end

local function RegisterAllMouseoverFrames()
    if InCombatLockdown() then return end
    if not header then
        CreateHeader()
        if Clique then
            Clique.header = header
        end
    end
    RegisterFluxUnitFrames()
    RegisterFluxRaidMouseoverFramesIfPresent()
    if not IsClickedLoaded() then
        RegisterBlizzardFrames()
    end
end

local function RegisterAllHoverFrames()
    RegisterAllMouseoverFrames()
end

SyncHoverRoutingLifecycle = function()
    if InCombatLockdown() then return end
    if not header then
        CreateHeader()
        if Clique then
            Clique.header = header
        end
    end
    if HasActiveRoutingData() and ufHoverCount > 0 then
        RegisterUnitExistsDriver()
    else
        UnregisterUnitExistsDriver()
    end
    RegisterAllHoverFrames()
    ProcessPendingFrames()
    if FluxMouseoverRefresh and FluxMouseoverRefresh.RefreshContextNeed then
        FluxMouseoverRefresh.RefreshContextNeed()
    end
end

local function TryFlushRosterRegistration()
    if InCombatLockdown() then return end
    SyncHoverRoutingLifecycle()
    if not header then return end
    RegisterAllMouseoverFrames()
    UpdateSecureBindingData()
    pendingRosterRegistration = false
end

local function IsNamePlateUnitFrame(frame)
    if not frame then
        return false
    end
    local name = frame.GetName and frame:GetName()
    if name and name:match("^NamePlate") then
        return true
    end
    local unit = frame.unit
    if unit and tostring(unit):find("^nameplate") then
        return true
    end
    -- Nameplate UnitFrame is parented under NamePlateN base frame.
    local parent = frame.GetParent and frame:GetParent()
    local pname = parent and parent.GetName and parent:GetName()
    if pname and pname:match("^NamePlate") then
        return true
    end
    return false
end

-- NEVER hooksecurefunc CompactUnitFrame_SetUpFrame / SetUpClicks.
-- NamePlateBaseMixin:SetUnit → ApplyFrameOptions → CompactUnitFrame_SetUpFrame,
-- then OnUnitSet → AurasFrame:SetUnit → RefreshList → Layout → GetScaledRect.
-- Even an early-return hook leaves the rest of SetUnit under Lua Taint:_FluxUI
-- (Shared CC / aura Layout spam). Register frames via RegisterBlizzardFrames,
-- ClickCastFrames, and FluxMouseoverKeybind:RegisterFrame instead.
local function HookCompactFrameCreation()
end

local function HookClickCastFrames()
    if IsClickedLoaded() then
        return
    end

    local function onClickCastFrame(frame, options)
        if IsClickedLoaded() then return end
        if not frame or IsNamePlateUnitFrame(frame) then return end
        if options ~= nil and options ~= false then
            RegisterFrame(frame)
        else
            UnregisterFrame(frame)
        end
    end

    local existing = ClickCastFrames

    if not existing then
        ClickCastFrames = setmetatable({}, {
            __newindex = function(_, frame, options)
                onClickCastFrame(frame, options)
            end,
        })
    else
        for frame, options in pairs(existing) do
            if options then
                onClickCastFrame(frame, options)
            end
        end
        ClickCastFrames = setmetatable({}, {
            __newindex = function(_, frame, options)
                onClickCastFrame(frame, options)
            end,
        })
    end
end

-- ---------------------------------------------------------------------------
-- HOVERCAST PEEK CONTEXT (mirror eval / key-split UF route)
-- ---------------------------------------------------------------------------

--- True when the cursor is over a Flux-registered unit frame — not 3D-world / nameplate
--- mouseover. Used by key-split peek so hover_profile does not swap icons over world
--- targets when the bind is UF-only.
local _hoverScanResult = false
local _hoverScanUntil = 0

local function FrameUnderMouse(f)
    if not f or f:IsForbidden() then return false end
    if f.IsShown and not f:IsShown() then return false end
    if f.IsMouseOver then
        local ok, v = pcall(f.IsMouseOver, f)
        if ok and v then return true end
    end
    if MouseIsOver then
        local ok, v = pcall(MouseIsOver, f)
        if ok and v then return true end
    end
    return false
end

local function RegisteredFrameContainsRegion(frame, region)
    if not frame or not region then return false end
    if region == frame then return true end
    if region.IsDescendantOf then
        local ok, desc = pcall(region.IsDescendantOf, region, frame)
        if ok and desc then return true end
    end
    return false
end

local function _PerformHoverContextScan()
    if GetMouseFoci then
        local ok, foci = pcall(GetMouseFoci)
        if ok and type(foci) == "table" then
            for fi = 1, #foci do
                local region = foci[fi]
                for i = 1, #registeredFrames do
                    if RegisteredFrameContainsRegion(registeredFrames[i], region) then
                        return true
                    end
                end
            end
        end
    end
    for i = 1, #registeredFrames do
        local f = registeredFrames[i]
        if FrameUnderMouse(f) then
            return true
        end
        if f and f.GetChildren then
            local ok, children = pcall(f.GetChildren, f)
            if ok and type(children) == "table" then
                for ci = 1, #children do
                    if FrameUnderMouse(children[ci]) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function FluxMouseoverKeybind:HasHoverRoutingActive()
    return HasActiveRoutingData()
end

function FluxMouseoverKeybind:IsHovercastPeekMouseContext()
    local now = GetTime()
    if now < _hoverScanUntil then
        return _hoverScanResult
    end
    _hoverScanResult = _PerformHoverContextScan()
    _hoverScanUntil = now + 0.05
    return _hoverScanResult
end

-- ---------------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------------

function FluxMouseoverKeybind:RegisterFrame(frame)
    RegisterFrame(frame)
end

--- Drop hovercast on Blizzard compact/party/raid buttons only. Flux unit
--- frames stay registered. Called when Flux raid frames own the group UI.
function FluxMouseoverKeybind:UnregisterBlizzardCompactRaidFrames()
    if InCombatLockdown() then
        return
    end
    local function drop(frame)
        if frame and IsBlizzardCompactOrPartyButton(frame) then
            UnregisterFrame(frame)
        end
    end
    for i = 1, 5 do
        drop(_G["CompactPartyFrameMember" .. i])
        drop(_G["CompactPartyFramePet" .. i])
        drop(_G["PartyMemberFrame" .. i])
    end
    for i = 1, 40 do
        drop(_G["CompactRaidFrame" .. i])
    end
    for group = 1, 8 do
        for member = 1, 5 do
            drop(_G["CompactRaidGroup" .. group .. "Member" .. member])
        end
    end
    if PartyFrame and PartyFrame.PartyMemberFramePool and PartyFrame.PartyMemberFramePool.EnumerateActive then
        for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            drop(frame)
            if frame and frame.PetFrame then
                drop(frame.PetFrame)
            end
        end
    end
end

function FluxMouseoverKeybind:RefreshKeybinds()
    if InCombatLockdown() then return end
    RegisterAllMouseoverFrames()
    RefreshAllFrameAttributes()
    UpdateSecureBindingData()
end

function FluxMouseoverKeybind:ReapplyAllRegisteredFrames()
    ReapplyAllRegisteredFrames()
end

--- @param keys string[] physical chords registered for UF-hover routing
--- @param btns string[] secure frame names (`_HC` siblings from FluxSpellDirectBind)
--- @param normChordSet table|nil normalized chord set for bar scan
--- @param macroBodies string[]|nil parallel UF-hover macro bodies (classic inline macrotext)
--- Pre-expanded UF-hover routing from DirectBind (single source of truth).
function FluxMouseoverKeybind:SetUfHoverRouting(keys, btns, normChordSet, macroBodies)
    spellHoverPrebuiltFromDirectBind = true
    wipe(spellHoverRawKeys)
    wipe(spellHoverRawBtns)
    wipe(spellHoverRawAnchors)
    if type(keys) == "table" and type(btns) == "table" then
        local n = math.min(#keys, #btns)
        for i = 1, n do
            local k = keys[i]
            local b = btns[i]
            if type(k) == "string" and k ~= "" and type(b) == "string" and b ~= "" then
                spellHoverRawKeys[#spellHoverRawKeys + 1] = k
                spellHoverRawBtns[#spellHoverRawBtns + 1] = b
            end
        end
    end
    RebuildSpellHoverChordSet()
    SyncSpellHoverMacroTexts(macroBodies)
    if InCombatLockdown() then
        pendingHoverRoutingFlush = true
        return false
    end
    if not header then CreateHeader() end
    RegisterAllMouseoverFrames()
    local ok = UpdateSecureBindingData()
    ReapplyAllRegisteredFrames()
    return ok ~= false
end

function FluxMouseoverKeybind:SetSpellHoverKeys(keys, btns, anchors)
    spellHoverPrebuiltFromDirectBind = false
    wipe(spellHoverRawKeys)
    wipe(spellHoverRawBtns)
    wipe(spellHoverRawAnchors)
    if type(keys) == "table" and type(btns) == "table" then
        local n = math.min(#keys, #btns)
        for i = 1, n do
            local k = keys[i]
            local b = btns[i]
            if type(k) == "string" and k ~= "" and type(b) == "string" and b ~= "" then
                spellHoverRawKeys[#spellHoverRawKeys + 1] = k
                spellHoverRawBtns[#spellHoverRawBtns + 1] = b
                local anchor
                if type(anchors) == "table" then
                    anchor = anchors[i]
                end
                spellHoverRawAnchors[#spellHoverRawAnchors + 1] = anchor
            end
        end
    end
    RebuildSpellHoverChordSet()
    SyncSpellHoverMacroTexts(nil)
    if InCombatLockdown() then
        pendingHoverRoutingFlush = true
        return false
    end
    if not header then CreateHeader() end
    local ok = UpdateSecureBindingData()
    ReapplyAllRegisteredFrames()
    return ok ~= false
end

--- True after a successful OOC secure push of hover routing tables into the header.
function FluxMouseoverKeybind:FlushPendingHoverRouting()
    if InCombatLockdown() then
        pendingHoverRoutingFlush = true
        return false
    end
    if not pendingHoverRoutingFlush and #spellHoverKeys == 0 then
        return true
    end
    if not header then CreateHeader() end
    RegisterAllMouseoverFrames()
    local ok = UpdateSecureBindingData()
    ReapplyAllRegisteredFrames()
    return ok ~= false
end

function FluxMouseoverKeybind:HasPendingHoverRouting()
    return pendingHoverRoutingFlush and true or false
end

function FluxMouseoverKeybind:DebugRouting()
    RebuildSpellHoverChordSet()
    local nRaw, nExp = #spellHoverRawKeys, #spellHoverKeys
    local api = _G.FLUX_API
    local hasEM = api and api.hasEditMode
    local childWraps = 0
    for i = 1, #registeredFrames do
        local list = registeredFrames[i] and registeredFrames[i].__fluxHovercastChildWraps
        if list then
            childWraps = childWraps + #list
        end
    end
    print(string.format(
        "[FluxMouseoverKeybind] prebuilt=%s raw=%d expanded=%d claimedMouse=%s hasEditMode=%s allowMouseBindingClick=%s registeredFrames=%d childWraps=%d pendingFlush=%s",
        tostring(spellHoverPrebuiltFromDirectBind),
        nRaw,
        nExp,
        tostring(GetSpellHoverClaimedButtonIndices()[5] == true),
        tostring(hasEM),
        tostring(isEditModeClient),
        #registeredFrames,
        childWraps,
        tostring(pendingHoverRoutingFlush)
    ))
    for i = 1, math.min(nExp, 8) do
        local isBtn = spellHoverIsButton[i] and "btn" or "kb/wheel"
        local body = spellHoverMacroTexts[i]
        local mode = "click"
        if type(body) == "string" and body ~= "" then
            mode = body:match("^%s*/click%s") and "click" or "inline"
        end
        local blen = (type(body) == "string") and #body or 0
        print("  ", tostring(spellHoverKeys[i]), "->", tostring(spellHoverBtns[i]),
            "(" .. isBtn .. " " .. mode .. " len=" .. tostring(blen) .. ")")
    end
    print("[FluxMouseoverKeybind] After binding changes run: /run FluxBinding.RequestApplyAll()")
    print("[FluxMouseoverKeybind] Hover UF (incl. aura) then check key resolves to *_HC, not FluxActionStripButton*")
end

_G.FluxMouseoverKeybind_DebugRouting = function()
    local m = _G.FluxMouseoverKeybindModule
    if m and m.DebugRouting then m:DebugRouting() end
end

FluxMouseoverKeybindModule = FluxMouseoverKeybind

_G.FluxRaidRegisterAllMouseoverKeybindFrames = function()
    if ns and ns.FluxRaidRegisterAllMouseoverKeybindFrames then
        ns.FluxRaidRegisterAllMouseoverKeybindFrames()
    end
end

-- ---------------------------------------------------------------------------
-- EVENT HANDLING
-- ---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
if FluxSafeRegisterEvent then
    FluxSafeRegisterEvent(eventFrame, "EDIT_MODE_LAYOUTS_UPDATED")
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        CreateHeader()
        HookClickCastFrames()
        HookCompactFrameCreation()

        -- Do not hooksecurefunc SecureUnitButton_OnLoad — same CUF/nameplate taint risk.

        if not Clique then
            Clique = {}
            Clique.header = header
            Clique.UpdateRegisteredClicks = function(_, frame)
                if frame and frame.RegisterForClicks and not IsNamePlateUnitFrame(frame) then
                    RegisterFrame(frame)
                end
            end
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not header then CreateHeader() end

        local function DoInitialRegistration()
            if InCombatLockdown() then return end
            RegisterAllMouseoverFrames()
            UpdateSecureBindingData()
        end

        C_Timer.After(0.5, DoInitialRegistration)
        -- Focus / focustarget outer frames may be created after the first pass (load order).
        C_Timer.After(1.2, function()
            if InCombatLockdown() then return end
            RegisterFluxUnitFrames()
            RegisterFluxRaidMouseoverFramesIfPresent()
            UpdateSecureBindingData()
        end)

        if FLUX_API and FLUX_API.hasEditMode then
            C_Timer.After(1.5, function()
                if InCombatLockdown() then return end
                RegisterAllMouseoverFrames()
                UpdateSecureBindingData()
            end)
            C_Timer.After(3.0, function()
                if InCombatLockdown() then return end
                RegisterAllMouseoverFrames()
                UpdateSecureBindingData()
            end)
        end

    elseif event == "UPDATE_BINDINGS" then
        if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
            and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
            return
        end
        if not header then return end
        if InCombatLockdown() then
            eventFrame.__pendingRefresh = true
            return
        end
        -- Coalesce single-key Settings edits (full mouseover rebind is expensive).
        if eventFrame.__bindingsRefreshPending then
            return
        end
        eventFrame.__bindingsRefreshPending = true
        C_Timer.After(0.12, function()
            eventFrame.__bindingsRefreshPending = false
            if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
                and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
                return
            end
            if InCombatLockdown() then
                eventFrame.__pendingRefresh = true
                return
            end
            RegisterAllMouseoverFrames()
            RefreshAllFrameAttributes()
            UpdateSecureBindingData()
        end)

    elseif event == "PLAYER_REGEN_ENABLED" then
        ProcessPendingFrames()
        if eventFrame.__pendingRefresh then
            eventFrame.__pendingRefresh = nil
            RegisterAllMouseoverFrames()
            RefreshAllFrameAttributes()
            UpdateSecureBindingData()
        elseif pendingHoverRoutingFlush then
            -- Hover routing tables filled in combat; push into secure header now.
            RegisterAllMouseoverFrames()
            UpdateSecureBindingData()
            ReapplyAllRegisteredFrames()
        end
        if pendingRosterRegistration then
            TryFlushRosterRegistration()
        end
        if pendingDriverPark or ufHoverCount <= 0 then
            pendingDriverPark = false
            if ufHoverCount <= 0 then
                UnregisterUnitExistsDriver()
            end
        end
        if ufHoverCount > 0 then
            RegisterUnitExistsDriver()
        end

    elseif event == "EDIT_MODE_LAYOUTS_UPDATED" or event == "GROUP_ROSTER_UPDATE" then
        pendingRosterRegistration = true
        C_Timer.After(0.3, function()
            TryFlushRosterRegistration()
        end)
    end
end)

