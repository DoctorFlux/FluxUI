-- Binding/UI/KeyVisualizer/Core.lua
-- Flux KeyVisualizer: show bindings on a keyboard (ported from Clicked, Flux-wired).

local addonName, ns = ...

local AceGUI = LibStub("AceGUI-3.0")

local DEFAULT_KEYBOARD_LAYOUT = (ns.FluxKeyboardLayouts and ns.FluxKeyboardLayouts.QWERTY) or "QWERTY"
local DEFAULT_KEYBOARD_SIZE = (ns.FluxKeyboardSizes and ns.FluxKeyboardSizes.SIZE_100) or 100
local MIN_FRAME_WIDTH = 1020

local SOURCE_ALL = "all"
local SOURCE_BINDING = "binding"
local SOURCE_BAR = "bar"
local SOURCE_EXTRA = "extra"

local MOUSE_TIP_LABELS = {
    BUTTON1 = "Left Mouse",
    BUTTON2 = "Right Mouse",
    BUTTON3 = "Middle Mouse",
    BUTTON4 = "Mouse 4",
    BUTTON5 = "Mouse 5",
    MOUSEWHEELUP = "Wheel Up",
    MOUSEWHEELDOWN = "Wheel Down",
}

local KeyVisualizer = {}
ns.FluxKeyVisualizer = KeyVisualizer
_G.FluxKeyVisualizer = KeyVisualizer

local frame
local tree
local filterBar
local buttonCache

local showCtrl = false
local showCtrlWidget
local showAlt = false
local showAltWidget
local showMeta = false
local showMetaWidget
local showShift = false
local showShiftWidget
local showSource = SOURCE_ALL

local hooksRegistered = false
-- When syncing mod checkboxes from physical keys, suppress OnValueChanged → redraw.
local suppressFilterCallbacks = false
local populateQueued = false
local scaleQueued = false
local userResized = false
local initialFitDone = false
local suppressResizeHook = false
local layoutUnitsW = 0
local layoutUnitsH = 0
local lastBuiltShowMouse = nil
local lastMouseKeySig = nil

local MOUSE_KEY_IDS = {
    "BUTTON1", "BUTTON2", "BUTTON3", "BUTTON4", "BUTTON5",
    "MOUSEWHEELUP", "MOUSEWHEELDOWN",
}

local MOUSE_ACTION_PREFIXES = {
    "",
    "SHIFT-", "CTRL-", "ALT-", "META-",
    "ALT-CTRL-", "ALT-SHIFT-", "CTRL-SHIFT-", "ALT-META-", "CTRL-META-", "SHIFT-META-",
    "ALT-CTRL-SHIFT-", "ALT-CTRL-META-", "ALT-SHIFT-META-", "CTRL-SHIFT-META-",
    "ALT-CTRL-SHIFT-META-",
}

--- True when this mouse base key is used by Blizzard binds or a Flux binding.
local function IsMouseKeyUsed(baseKey)
    if type(baseKey) ~= "string" or baseKey == "" then return false end
    if GetBindingAction then
        for i = 1, #MOUSE_ACTION_PREFIXES do
            local chord = MOUSE_ACTION_PREFIXES[i] .. baseKey
            local action
            -- Retail: checkOverrideBindings; older clients only take one arg.
            local ok, res = pcall(GetBindingAction, chord, true)
            if ok then
                action = res
            else
                action = GetBindingAction(chord)
            end
            if type(action) == "string" and action ~= "" then
                return true
            end
        end
    end
    local ChordMap = ns.FluxBindingChordMap
    local DB = ns.FluxBindingDB3
    if DB and DB.All and ChordMap and ChordMap.Parse then
        for _, b in pairs(DB.All()) do
            if b and type(b.key) == "string" and b.key ~= "" then
                local bk = ChordMap.Parse(b.key)
                if bk == baseKey then
                    return true
                end
            end
        end
    end
    return false
end

local function GetActiveMouseKeySet()
    local active = {}
    local any = false
    for i = 1, #MOUSE_KEY_IDS do
        local id = MOUSE_KEY_IDS[i]
        if IsMouseKeyUsed(id) then
            active[id] = true
            any = true
        end
    end
    return active, any
end

local function MouseKeySignature(active)
    if type(active) ~= "table" then return "" end
    local parts = {}
    for i = 1, #MOUSE_KEY_IDS do
        local id = MOUSE_KEY_IDS[i]
        if active[id] then
            parts[#parts + 1] = id
        end
    end
    return table.concat(parts, ",")
end

--- AceGUI Frame chrome: title + status + borders (see AceGUIContainer-Frame OnHeightSet).
local FRAME_CHROME = 57
local FRAME_WIDTH_PAD = 54
local TREE_SIDE_WIDTH = 100

local function TableContains(tbl, value)
    if type(tbl) ~= "table" then return false end
    for i = 1, #tbl do
        if tbl[i] == value then return true end
    end
    return false
end

local function GetDb()
    local opts = _G.FluxOptions
    if opts and opts.db and opts.db.global then
        local g = opts.db.global
        if type(g.keyVisualizer) ~= "table" then
            g.keyVisualizer = {
                lastKeyboardLayout = DEFAULT_KEYBOARD_LAYOUT,
                lastKeyboardSize = DEFAULT_KEYBOARD_SIZE,
                showOnlyLoadedBindings = true,
                highlightEmptyKeys = false,
                showExtraButtons = true,
                showMouse = true,
            }
        end
        return g.keyVisualizer
    end
    if type(_G.FluxKeyVisualizerDB) ~= "table" then
        _G.FluxKeyVisualizerDB = {
            lastKeyboardLayout = DEFAULT_KEYBOARD_LAYOUT,
            lastKeyboardSize = DEFAULT_KEYBOARD_SIZE,
            showOnlyLoadedBindings = true,
            highlightEmptyKeys = false,
            showExtraButtons = true,
            showMouse = true,
        }
    end
    return _G.FluxKeyVisualizerDB
end

local function SanitizeKeybind(key)
    if type(key) ~= "string" then return "" end
    if IsMacClient and IsMacClient() then
        key = key:gsub("META%-", "CMD-"):gsub("^META$", "CMD")
    end
    -- Friendlier mouse labels on the visualizer.
    key = key
        :gsub("MOUSEWHEELUP", "Mouse Wheel Up")
        :gsub("MOUSEWHEELDOWN", "Mouse Wheel Down")
        :gsub("BUTTON1", "Left Button")
        :gsub("BUTTON2", "Right Button")
        :gsub("BUTTON3", "Middle Button")
        :gsub("BUTTON4", "Mouse Button 4")
        :gsub("BUTTON5", "Mouse Button 5")
    return key
end

local function ShowTooltip(anchor, title, body)
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    if title and title ~= "" then
        GameTooltip:AddLine(title, 1, 1, 1)
    end
    if body and body ~= "" then
        for line in string.gmatch(body, "[^\n]+") do
            GameTooltip:AddLine(line, 0.9, 0.9, 0.9, true)
        end
    end
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

local function GetTreeLayout()
    local KeyLayouts = ns.FluxKeyLayouts
    local result = {}
    if not KeyLayouts then return result end
    for _, layout in ipairs(KeyLayouts:GetKeyboardLayouts()) do
        local item = {
            value = layout,
            text = layout,
            children = {},
        }
        for _, size in ipairs(KeyLayouts:GetKeyboardSizes(layout)) do
            item.children[#item.children + 1] = {
                value = size,
                text = size .. "%",
            }
        end
        result[#result + 1] = item
    end
    return result
end

local function SelectLayout(layout, size)
    local db = GetDb()
    layout = layout or db.lastKeyboardLayout or DEFAULT_KEYBOARD_LAYOUT
    size = size or db.lastKeyboardSize or DEFAULT_KEYBOARD_SIZE
    if tree then
        tree:SelectByPath(layout, size)
    end
end

--- Build filter chord from all active mod checkboxes (Alt/Ctrl/Shift/Meta).
local function GetModifiedKey(baseKey)
    local raw = ""
    if showAlt then raw = raw .. "ALT-" end
    if showCtrl then raw = raw .. "CTRL-" end
    if showShift then raw = raw .. "SHIFT-" end
    if showMeta then raw = raw .. "META-" end
    raw = raw .. tostring(baseKey or "")
    local ChordMap = ns.FluxBindingChordMap
    if ChordMap and ChordMap.Normalize then
        return ChordMap.Normalize(raw)
    end
    return string.upper(raw)
end

--- Tooltip title for a physical key under the current mod filters.
local function ChordTipTitle(baseKey)
    return SanitizeKeybind(GetModifiedKey(baseKey))
end

--- Bar main↔mini only understands Shift / Ctrl (not Alt/Meta, not Shift+Ctrl).
--- Alt / Meta / extra combos fall back to the Shift-or-Ctrl-or-bare row.
local function GetBarModifiedKey(baseKey)
    local raw = ""
    if showShift then
        raw = "SHIFT-"
    elseif showCtrl then
        raw = "CTRL-"
    end
    raw = raw .. tostring(baseKey or "")
    local ChordMap = ns.FluxBindingChordMap
    if ChordMap and ChordMap.Normalize then
        return ChordMap.Normalize(raw)
    end
    return string.upper(raw)
end

local function ActionSlotDisplay(slot)
    if not slot or not GetActionInfo then return nil, nil, nil end
    local Action = ns.FluxBindingAction
    local actionType, id, subType = GetActionInfo(slot)
    local actionIcon = GetActionTexture and GetActionTexture(slot)
    local name
    local spellId
    if actionType == "spell" or (actionType == "macro" and subType == "spell") then
        spellId = tonumber(id)
        if not spellId and type(id) == "string" and id ~= "" then
            -- Some clients hand back a spell name for macro/spell slots.
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(id)
                spellId = info and tonumber(info.spellID)
            end
        end
        if Action and Action.Spell and Action.GetNameWithRank and spellId then
            name = Action.GetNameWithRank(Action.Spell(spellId))
        else
            name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) or (GetSpellInfo and GetSpellInfo(id))
        end
    elseif actionType == "item" or (actionType == "macro" and subType == "item") then
        name = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(id) or (GetItemInfo and GetItemInfo(id))
    elseif actionType == "flyout" and GetFlyoutInfo then
        name = GetFlyoutInfo(id)
    elseif actionType == "summonpet" and C_PetJournal then
        local speciesId, customName = C_PetJournal.GetPetInfoByPetID(id)
        name = customName or (speciesId and C_PetJournal.GetPetInfoBySpeciesID(speciesId))
    elseif actionType == "summonmount" and C_MountJournal then
        name = C_MountJournal.GetMountInfoByID(id)
    elseif actionType == "macro" then
        name = GetMacroInfo and GetMacroInfo(id)
        if GetMacroSpell then
            -- Parentheses force nil when GetMacroSpell returns no values
            -- (tonumber() with zero args errors: "value expected").
            local ms = GetMacroSpell(id)
            if ms ~= nil then
                spellId = tonumber(ms)
            end
        end
    end
    if name and actionIcon then
        return name, actionIcon, spellId
    end
    return nil, actionIcon, spellId
end

local function IsSpellLowerRank(spellId)
    spellId = tonumber(spellId)
    if not spellId then return false end
    local SRM = _G.FluxSpellRankManager
    return SRM and SRM.IsLowerRankSpell and SRM:IsLowerRankSpell(spellId) and true or false
end

local function BindingSpellId(b)
    if not b or type(b.action) ~= "table" then return nil end
    if b.action.type == "spell" then
        return tonumber(b.action.id)
    end
    return nil
end

local function BindingDisplayName(b)
    local Action = ns.FluxBindingAction
    if not b or not Action then return "?" end
    if Action.GetNameWithRank then
        return Action.GetNameWithRank(b.action) or Action.GetName(b.action) or "?"
    end
    return Action.GetName(b.action) or "?"
end

--- What the physical key casts for the current mod filters.
--- Keys always click FluxActionButton{col}; SmartLayout remaps that button's
--- Shift (101+) / Ctrl (121+) / resting states (promote + HasAction fallback).
--- Alt / Meta never select a minirow — fall back to Shift/Ctrl/bare via GetBarModifiedKey.
--- Never read SlotHost on the mini while a mod is held — the mini shows the
--- swap partner, not what the key fires.
local function ResolveBarSlot(baseKey)
    local ChordMap = ns.FluxBindingChordMap
    if not ChordMap or not ChordMap.Route then return nil, nil end
    local barChord = GetBarModifiedKey(baseKey)
    local route = ChordMap.Route(barChord)
    if not route or route.kind ~= "slot" then
        return nil, route
    end

    local Forms = ns.FluxBindingForms
    local token = Forms and Forms.GetCurrentToken and Forms.GetCurrentToken() or "noform"
    local slot = route.slotsByForm and route.slotsByForm[token]
    if slot then
        return slot, route
    end
    local State = ns.FluxActionBarState
    local col = route.col
    local page = Forms and Forms.PageForToken and Forms.PageForToken(token) or 1
    if type(page) ~= "number" or page < 1 then page = 1 end
    if State and col then
        local secSlot = State.GetSecondarySlot and State.GetSecondarySlot(col)
        local tertSlot = State.GetTertiarySlot and State.GetTertiarySlot(col)
        local mainSlot = State.GetMainSlot and State.GetMainSlot(col, (col > 12) and 0 or page)
        local hasSec = secSlot and HasAction and HasAction(secSlot)
        local hasTert = tertSlot and HasAction and HasAction(tertSlot)

        if showShift then
            if hasSec then
                slot = secSlot
            elseif hasTert then
                slot = tertSlot
            else
                slot = mainSlot
            end
        elseif showCtrl then
            if hasTert then
                slot = tertSlot
            elseif hasSec then
                slot = secSlot
            else
                slot = mainSlot
            end
        else
            local function hasMainContent()
                if not State.GetMainSlot or not HasAction then return false end
                for s = 0, 18 do
                    local ms = State.GetMainSlot(col, s)
                    if ms and HasAction(ms) then return true end
                end
                return false
            end
            if not hasMainContent() then
                if hasSec and hasTert then
                    slot = secSlot
                elseif hasSec then
                    slot = secSlot
                elseif hasTert then
                    slot = tertSlot
                else
                    slot = mainSlot
                end
            else
                slot = mainSlot
            end
        end
    end

    if not slot and route.slotsByForm then
        slot = route.slotsByForm[token] or route.slotsByForm.noform
    end

    return slot, route, barChord
end

local function SummarizeBindingSub(sub)
    local Conditions = ns.FluxBindingConditions
    if Conditions and Conditions.SummarizeSub then
        return Conditions.SummarizeSub(sub) or ""
    end
    return ""
end

--- Resolve a BadgeHost slot entry for KV paint: peer binding uid OR multi-cast
--- `extra:<ownerUid>:<index>` (icon/spellId/itemId on the entry, or look up owner extras).
local function ResolveSlotBadgeVisual(bd, formToken)
    if type(bd) ~= "table" then return nil end
    local DB = ns.FluxBindingDB3
    local Action = ns.FluxBindingAction
    local key = bd.key
    local isExtra = type(key) == "string" and key:match("^extra:") ~= nil

    if not isExtra and key and DB and DB.Get then
        local b = DB.Get(key)
        if b and Action then
            local sub = DB.GetFormSub and DB.GetFormSub(b, formToken)
            return {
                uid = key,
                icon = Action.GetIcon(b.action),
                name = BindingDisplayName(b),
                alpha = bd.alpha or 0.75,
                desaturated = IsSpellLowerRank(BindingSpellId(b)),
                cond = SummarizeBindingSub(sub),
                tipTag = nil,
            }
        end
    end

    local icon = bd.icon
    local name
    local spellId = tonumber(bd.spellId)
    local itemId = tonumber(bd.itemId)

    if isExtra and DB then
        local ownerUid, idx = tostring(key):match("^extra:([^:]+):(%d+)$")
        local owner = ownerUid and DB.Get(tonumber(ownerUid) or ownerUid)
        if owner then
            local sub = DB.GetFormSub and DB.GetFormSub(owner, formToken)
            local list = DB.GetMacroExtras and DB.GetMacroExtras(sub) or {}
            local e = list[tonumber(idx)]
            if e then
                icon = icon or (DB.GetMacroExtraIcon and DB.GetMacroExtraIcon(e))
                name = (DB.GetMacroExtraLabel and DB.GetMacroExtraLabel(e)) or name
                if e.type == "spell" then
                    spellId = spellId or tonumber(e.id)
                elseif e.type == "item" then
                    itemId = itemId or tonumber(e.id)
                elseif e.type == "slot" and not itemId then
                    itemId = GetInventoryItemID and GetInventoryItemID("player", e.id)
                end
            end
        end
    end

    if Action then
        if spellId and not name then
            local desc = Action.Spell and Action.Spell(spellId)
            name = (Action.GetNameWithRank and Action.GetNameWithRank(desc))
                or (Action.GetName and Action.GetName(desc))
            icon = icon or (Action.GetIcon and Action.GetIcon(desc))
        elseif itemId and not name then
            local desc = Action.Item and Action.Item(itemId)
            name = Action.GetName and Action.GetName(desc)
            icon = icon or (Action.GetIcon and Action.GetIcon(desc))
        end
    end

    if not icon and not name then return nil end
    return {
        uid = key,
        icon = icon or 134400,
        name = name or "Multi-cast",
        alpha = bd.alpha or 0.75,
        desaturated = IsSpellLowerRank(spellId),
        cond = "",
        tipTag = "multi-cast",
    }
end

--- When BadgeHost has not published yet, still surface multi-cast extras from the
--- place-scoped (or action-matched) native binding for this slot.
local function AppendMultiCastExtrasFromDB(slot, nativeAk, meta, tipParts, coveredUid, formToken, TextureTag)
    local DB = ns.FluxBindingDB3
    local Action = ns.FluxBindingAction
    if not slot or not nativeAk or not DB or not DB.All or not Action then return end
    if meta and meta.badges and #meta.badges > 0 then return end

    local wantPid = "ab:" .. tostring(slot)
    local bestSub, bestUid
    for uid, b in pairs(DB.All()) do
        if b and b.action and not (coveredUid and coveredUid[uid]) then
            local match = false
            if Action.KeysMatch then
                match = Action.KeysMatch(b.action, nativeAk)
            elseif Action.Key then
                match = Action.Key(b.action) == nativeAk
            end
            if match then
                local sub = DB.GetFormSub and DB.GetFormSub(b, formToken)
                local extras = DB.GetMacroExtras and DB.GetMacroExtras(sub) or {}
                if #extras > 0 then
                    if b.placeId == wantPid then
                        bestSub, bestUid = sub, uid
                        break
                    elseif not bestSub then
                        bestSub, bestUid = sub, uid
                    end
                end
            end
        end
    end
    if not bestSub then return end
    if coveredUid and bestUid then coveredUid[bestUid] = true end

    local maxB = (_G.FluxBadgeHost and _G.FluxBadgeHost.MAX_BADGES) or 3
    local list = (DB.FilterMacroExtras and DB.FilterMacroExtras(DB.GetMacroExtras(bestSub), maxB))
        or DB.GetMacroExtras(bestSub)
    for i = 1, math.min(#list, maxB) do
        local e = list[i]
        local icon = DB.GetMacroExtraIcon and DB.GetMacroExtraIcon(e) or 134400
        local name = (DB.GetMacroExtraLabel and DB.GetMacroExtraLabel(e)) or "Multi-cast"
        if meta and meta.badges then
            meta.badges[#meta.badges + 1] = {
                icon = icon,
                alpha = 0.75,
                desaturated = false,
            }
        end
        if tipParts and TextureTag then
            tipParts[#tipParts + 1] = TextureTag(icon) .. name .. " [multi-cast]"
        end
    end
end

local function NativeActionKeyForSlot(slot)
    local Action = ns.FluxBindingAction
    if not slot or not GetActionInfo or not Action then return nil end
    local actionType, id, subType = GetActionInfo(slot)
    if actionType == "spell" or (actionType == "macro" and subType == "spell") then
        if Action.SlotActionKey then
            return Action.SlotActionKey(id)
        end
        return Action.Key and Action.Key(Action.Spell and Action.Spell(id))
    elseif actionType == "item" or (actionType == "macro" and subType == "item") then
        return Action.Key and Action.Key(Action.Item and Action.Item(id))
    elseif actionType == "macro" then
        local name = GetMacroInfo and GetMacroInfo(id)
        if name and Action.Macro then
            return Action.Key and Action.Key(Action.Macro(name))
        end
    end
    return nil
end

local function RefitAllKeyIcons()
    if type(buttonCache) ~= "table" then return end
    for _, widget in pairs(buttonCache) do
        if widget and widget.FitActionIcon then
            widget:FitActionIcon()
        end
        if widget and widget.SetBadges and widget._lastBadges then
            widget:SetBadges(widget._lastBadges)
        end
    end
end

local function FilterBarHeight()
    if filterBar and filterBar.frame and filterBar.frame.GetHeight then
        local h = filterBar.frame:GetHeight()
        if h and h > 10 then return h + 4 end
    end
    return 32
end

--- Title bar + status bar + padding outside the content children.
local function FrameChromeHeight()
    return FRAME_CHROME or 57
end

--- Available keyboard pane size from the window itself (reliable while resizing).
--- AceGUI List ignores SetFullHeight, so tree.content height stays keyboard-tall and
--- cannot be used to grow the grid — derive space from the frame instead.
local function GetAvailPaneSize()
    if not frame or not frame.frame or not tree then
        return 0, 0
    end
    local treeW = (tree.GetTreeWidth and tree:GetTreeWidth()) or TREE_SIDE_WIDTH or 100
    local fw = frame.frame:GetWidth() or 0
    local fh = frame.frame:GetHeight() or 0
    local availW = fw - FRAME_WIDTH_PAD - treeW - 12
    local availH = fh - FrameChromeHeight() - FilterBarHeight() - 16
    if availW < 0 then availW = 0 end
    if availH < 0 then availH = 0 end
    return availW, availH
end

--- Scale key grid to the window pane. Grows and shrinks with resize.
local function ApplyDynamicGrid()
    if not tree or not KeyVisualizer:IsOpen() then return end
    if layoutUnitsW <= 0 or layoutUnitsH <= 0 then return end

    local availW, availH = GetAvailPaneSize()
    -- Fallback to content widget if frame math is not ready yet.
    if (availW < 80 or availH < 60) and tree.content and tree.content.GetWidth then
        availW = tree.content:GetWidth() or availW
        availH = tree.content:GetHeight() or availH
    end
    if availW < 80 or availH < 60 then return end

    local pad = 10
    local gs = math.floor(math.min(
        (availW - pad) / layoutUnitsW,
        (availH - pad) / layoutUnitsH
    ) + 0.0001)
    if gs < 16 then gs = 16 end
    if gs > 64 then gs = 64 end

    local cur = tonumber(ns.FluxKeyVisualizerGridSize) or 34
    if math.abs(gs - cur) < 0.5 then
        return
    end
    ns.FluxKeyVisualizerGridSize = gs
    if tree.DoLayout then
        tree:DoLayout()
    elseif AceGUI and AceGUI.DoLayout and tree.parent then
        AceGUI:DoLayout(tree.parent)
    end
    RefitAllKeyIcons()
end

local function QueueDynamicGrid()
    if scaleQueued or not KeyVisualizer:IsOpen() then return end
    scaleQueued = true
    local function run()
        scaleQueued = false
        if KeyVisualizer:IsOpen() then
            ApplyDynamicGrid()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

local function RebuildKeyboardLayout()
    if not KeyVisualizer:IsOpen() then return end
    local db = GetDb()
    local layout = db.lastKeyboardLayout or DEFAULT_KEYBOARD_LAYOUT
    local size = db.lastKeyboardSize or DEFAULT_KEYBOARD_SIZE
    if tree and tree.ReleaseChildren then
        tree:ReleaseChildren()
    end
    buttonCache = nil
    KeyVisualizer:SetKeyboardLayout(layout, size)
end

local function BuildLayout(layout, size)
    local KeyLayouts = ns.FluxKeyLayouts
    if not KeyLayouts or not tree then return end
    if not KeyVisualizer:IsOpen() then return end

    -- Always clear first — mouse toggle used to stack a second keyboard.
    if tree.ReleaseChildren then
        tree:ReleaseChildren()
    end

    local keys, visible = KeyLayouts:GetKeyboardLayout(layout, size)
    local db = GetDb()
    local showMouse = db.showMouse ~= false
    lastBuiltShowMouse = showMouse
    local mouseKeys
    if showMouse and KeyLayouts.GetMouseLayout then
        local active = select(1, GetActiveMouseKeySet())
        lastMouseKeySig = MouseKeySignature(active)
        mouseKeys = KeyLayouts:GetMouseLayout(active)
    else
        lastMouseKeySig = ""
    end

    if not ns.FluxKeyVisualizerGridSize then
        ns.FluxKeyVisualizerGridSize = 34
    end

    local function GetOverride(key)
        if key.overrides == nil then
            return key
        end
        if key.overrides[size] then
            return Mixin({}, key, key.overrides[size])
        end
        local bestOverride = nil
        local bestOverrideDiff = math.huge
        for overrideSize, override in pairs(key.overrides) do
            if overrideSize >= size then
                local diff = math.abs(size - overrideSize)
                if diff < bestOverrideDiff then
                    bestOverride = override
                    bestOverrideDiff = diff
                end
            end
        end
        if bestOverride ~= nil then
            return Mixin({}, key, bestOverride)
        end
        return key
    end

    buttonCache = {}
    for _, key in ipairs(keys) do
        local widget = AceGUI:Create("FluxKeyVisualizerButton")
        widget:SetKey(GetOverride(key))
        widget:SetVisible(TableContains(visible, key:GetId()))
        tree:AddChild(widget)
        buttonCache[key:GetId()] = widget
    end

    if type(mouseKeys) == "table" then
        for _, key in ipairs(mouseKeys) do
            local widget = AceGUI:Create("FluxKeyVisualizerButton")
            widget:SetKey(key)
            widget:SetVisible(true)
            tree:AddChild(widget)
            buttonCache[key:GetId()] = widget
        end
    end

    local gs = tonumber(ns.FluxKeyVisualizerGridSize) or 34
    local cw = (tree.GetContentWidth and tree:GetContentWidth()) or 0
    local ch = (tree.GetContentHeight and tree:GetContentHeight()) or 0
    if cw > 0 and ch > 0 and gs > 0 then
        layoutUnitsW = cw / gs
        layoutUnitsH = ch / gs
    end

    -- One-shot open fit only — never fights user resize afterward.
    if not initialFitDone and not userResized and frame and frame.frame then
        local oldWidth = frame.frame:GetWidth()
        local treeWidth = (tree.GetTreeWidth and tree:GetTreeWidth()) or TREE_SIDE_WIDTH
        local width = math.max(treeWidth + cw + FRAME_WIDTH_PAD, MIN_FRAME_WIDTH)
        local height = math.max((ch or 0) + FilterBarHeight() + FrameChromeHeight() + 8, 420)
        suppressResizeHook = true
        frame:SetWidth(width)
        frame:SetHeight(height)
        suppressResizeHook = false
        initialFitDone = true

        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        if point == "CENTER" or point == "TOP" or point == "BOTTOM" then
            local xOffset = (frame.frame:GetWidth() - oldWidth) / 2
            frame:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + xOffset, yOfs)
        elseif point == "RIGHT" or point == "TOPRIGHT" or point == "BOTTOMRIGHT" then
            local xOffset = (frame.frame:GetWidth() - oldWidth)
            frame:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + xOffset, yOfs)
        end
    end

    QueueDynamicGrid()
end

--- Stance placements only (Extra buttons use live EBS resolvers below).
local function IndexStanceByChord(indexMap, ChordMap, out)
    if type(indexMap) ~= "table" or not ChordMap then return out end
    for _, places in pairs(indexMap) do
        if type(places) == "table" then
            for i = 1, #places do
                local p = places[i]
                local pChord = p and p.chord
                if pChord and pChord ~= "" and not pChord:find(" / ", 1, true) then
                    local nk = ChordMap.Normalize(pChord)
                    if nk ~= "" then
                        local list = out[nk]
                        if not list then
                            list = {}
                            out[nk] = list
                        end
                        list[#list + 1] = {
                            name = p.name or p.label,
                            icon = p.icon,
                            isStance = true,
                        }
                    end
                end
            end
        end
    end
    return out
end

local function BindingTitle(binding)
    local t = _G["BINDING_NAME_" .. tostring(binding)]
    if type(t) == "string" and t ~= "" then return t end
    return tostring(binding)
end

local function PushExtraChord(out, ChordMap, chord, entry)
    if not chord or chord == "" or not ChordMap then return end
    if chord:find(" / ", 1, true) then return end
    local nk = ChordMap.Normalize(chord)
    if nk == "" then return end
    local list = out[nk]
    if not list then
        list = {}
        out[nk] = list
    end
    list[#list + 1] = entry
end

local function EachBindingKey(bindingName, fn)
    if not GetBindingKey or type(fn) ~= "function" then return end
    local a, b = GetBindingKey(bindingName)
    if a and a ~= "" then fn(a) end
    if b and b ~= "" then fn(b) end
end

local function ItemNameIcon(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil, nil end
    local name = GetItemInfo and GetItemInfo(itemID)
    local icon = GetItemIcon and GetItemIcon(itemID)
    if C_Item then
        if not name and C_Item.GetItemNameByID then name = C_Item.GetItemNameByID(itemID) end
        if not icon and C_Item.GetItemIconByID then icon = C_Item.GetItemIconByID(itemID) end
    end
    return name, icon
end

local function SpellNameIcon(spell)
    if spell == nil then return nil, nil end
    if type(spell) == "number" then
        local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spell)
        local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spell)
        if not name and GetSpellInfo then name = GetSpellInfo(spell) end
        if not icon and GetSpellTexture then icon = GetSpellTexture(spell) end
        return name, icon
    end
    if type(spell) == "string" and spell ~= "" then
        local icon = GetSpellTexture and GetSpellTexture(spell)
        if C_Spell and C_Spell.GetSpellTexture then
            icon = C_Spell.GetSpellTexture(spell) or icon
        end
        return spell, icon
    end
    return nil, nil
end

--- Flyout favorite mod key from KeyVisualizer filters (ctrl+shift+alt).
local function CurrentFlyoutMod()
    local parts = {}
    if showCtrl then parts[#parts + 1] = "ctrl" end
    if showShift then parts[#parts + 1] = "shift" end
    if showAlt then parts[#parts + 1] = "alt" end
    if #parts == 0 then return "nomod" end
    return table.concat(parts, "+")
end

--- Utility-slot mod key ("" / SHIFT / CTRL-ALT / …).
local function CurrentUtilMod()
    local parts = {}
    if showShift then parts[#parts + 1] = "SHIFT" end
    if showCtrl then parts[#parts + 1] = "CTRL" end
    if showAlt then parts[#parts + 1] = "ALT" end
    if #parts == 0 then return "" end
    local raw = table.concat(parts, "-")
    local U = _G.FluxNCUtilitySlots
    if U and U.NormalizeModKey then
        return U.NormalizeModKey(raw) or raw
    end
    return raw
end

local function TextureTag(icon, size)
    if not icon then return "" end
    size = size or 14
    return "|T" .. tostring(icon) .. ":" .. size .. ":" .. size .. ":0:0|t "
end

--- Consumables key: one tooltip line per configured item that is currently in bags.
--- Key icon = first in-bag consumable (same idea as the live button when not empty).
local function BuildConsumablesTooltipLines(flyoutMod)
    local Cons = _G.FluxNCConsumables
    local lines = {}
    local primaryIcon
    local items = Cons and Cons.GetItems and Cons.GetItems()
    if type(items) ~= "table" then
        return lines, nil
    end

    local function bagCount(itemID)
        if Cons and Cons.GetItemCount then
            return tonumber(Cons.GetItemCount(itemID)) or 0
        end
        if GetItemCount then
            return tonumber(GetItemCount(itemID)) or 0
        end
        return 0
    end

    local ordered = {}
    for i = 1, #items do
        ordered[#ordered + 1] = items[i]
    end

    -- Modifier click can prefer Chronoboon — surface it first when applicable.
    if flyoutMod and flyoutMod ~= "nomod" and Cons and Cons.GetChronoboonModifierOverrideChronoID then
        local primary = Cons.GetFirstEligibleItem and select(1, Cons.GetFirstEligibleItem())
        local chrono = Cons.GetChronoboonModifierOverrideChronoID(primary)
        if chrono and bagCount(chrono) > 0 then
            local rest = {}
            for i = 1, #ordered do
                if ordered[i] ~= chrono then
                    rest[#rest + 1] = ordered[i]
                end
            end
            ordered = { chrono }
            for i = 1, #rest do
                ordered[#ordered + 1] = rest[i]
            end
        end
    end

    local seen = {}
    for i = 1, #ordered do
        local itemID = ordered[i]
        if itemID and not seen[itemID] and bagCount(itemID) > 0 then
            seen[itemID] = true
            local name, icon = ItemNameIcon(itemID)
            if not name or name == "" then
                name = "item:" .. tostring(itemID)
            end
            lines[#lines + 1] = {
                name = TextureTag(icon) .. name,
                icon = icon,
            }
            if not primaryIcon then
                primaryIcon = icon
            end
        end
    end

    return lines, primaryIcon
end

local function FormatButtonCastLine(buttonName, castNames)
    if type(buttonName) ~= "string" or buttonName == "" then
        buttonName = "?"
    end
    if type(castNames) ~= "table" or #castNames == 0 then
        return buttonName
    end
    local seen, parts = {}, {}
    for i = 1, #castNames do
        local n = castNames[i]
        if type(n) == "string" and n ~= "" and not seen[n] then
            seen[n] = true
            parts[#parts + 1] = n
        end
    end
    if #parts == 0 then return buttonName end
    return buttonName .. ": " .. table.concat(parts, " & ")
end

local function KnowsRitualOfRefreshment()
    local det = _G.FluxNCItemDetection
    if det and det.HasRitualOfRefreshment then
        return det.HasRitualOfRefreshment() and true or false
    end
    local Fly = _G.FluxFlyoutData
    if Fly and Fly.IsSpellKnown then
        return Fly.IsSpellKnown("Ritual of Refreshment") and true or false
    end
    if IsSpellKnown or IsPlayerSpell then
        local sid
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo("Ritual of Refreshment")
            sid = info and info.spellID
        end
        if sid then
            if IsPlayerSpell and IsPlayerSpell(sid) then return true end
            if IsSpellKnown and IsSpellKnown(sid) then return true end
        end
    end
    return false
end

local PH = {
    food = "Interface\\Icons\\INV_Misc_Fork&Knife",
    water = "Interface\\Icons\\INV_Drink_07",
    bandage = "Interface\\Icons\\INV_Misc_Bandage_01",
    healPotion = "Interface\\Icons\\INV_Potion_54",
    manaPotion = "Interface\\Icons\\INV_Potion_76",
    healthstone = "Interface\\Icons\\INV_Stone_04",
    managem = "Interface\\Icons\\INV_Misc_Gem_Sapphire_02",
    mount = 132261,
    hearth = 134414,
    consumables = "Interface\\Icons\\inv_potion_41",
    trinket = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01",
    util = 133622,
    assisted = 236364,
    teleport = "Interface\\Icons\\Spell_Arcane_TeleportStormWind",
}

--- Live resolve one Extra binding under current filters. Returns line, icon.
local function ResolveExtraLive(entry, flyoutMod, utilMod)
    if type(entry) ~= "table" or not entry.kind then
        return entry and entry.name, entry and entry.icon
    end
    local kind = entry.kind
    local buttonName = entry.buttonName or BindingTitle(entry.binding)
    local Bridge = _G.FluxEBSConsumableBridge
    flyoutMod = flyoutMod or "nomod"
    utilMod = utilMod or ""

    local function ownedLine(bridgeKind, ph)
        local owned = Bridge and Bridge.GetBestOwned and Bridge.GetBestOwned(bridgeKind)
        local cast, icon
        if type(owned) == "table" then
            cast = owned.name
            icon = owned.icon
            if (not cast or not icon) and owned.itemID then
                local n, ic = ItemNameIcon(owned.itemID)
                cast = cast or n
                icon = icon or ic
            end
        end
        return FormatButtonCastLine(buttonName, cast and { cast } or nil), icon or ph
    end

    if kind == "combat" or kind == "nc_use" then
        return ownedLine(entry.bridgeKind, entry.placeholder)
    end

    if kind == "consumables" then
        -- Multi-line handled in RegisterExtraList (one line per in-bag item + icon).
        return nil, entry.placeholder or PH.consumables
    end

    if kind == "trinket" then
        local TM = _G.FluxTrinketMenu
        local tex, name
        if TM and TM.GetTrinketInfo then
            tex, name = TM.GetTrinketInfo(entry.slot)
        else
            tex = GetInventoryItemTexture and GetInventoryItemTexture("player", entry.slot)
            local link = GetInventoryItemLink and GetInventoryItemLink("player", entry.slot)
            if link then name = link:match("%[(.-)%]") end
        end
        return FormatButtonCastLine(buttonName, name and { name } or nil), tex or entry.placeholder
    end

    if kind == "hearth" then
        local H = _G.FluxNCHearthstone
        local it = H and H.GetBestTeleportItem and H.GetBestTeleportItem(flyoutMod)
        local cast, icon
        if type(it) == "table" then
            cast = it.name
            icon = it.icon
            if not cast and it.itemId then
                cast, icon = ItemNameIcon(it.itemId)
            end
        else
            local hid = H and H.GetHearthItemId and H.GetHearthItemId()
            cast, icon = ItemNameIcon(hid)
        end
        return FormatButtonCastLine(buttonName, cast and { cast } or nil), icon or entry.placeholder
    end

    if kind == "mount" then
        local M = _G.FluxNCMount
        local cast, icon
        local bag = M and M.GetBestAvailableMount and M.GetBestAvailableMount(flyoutMod)
        if type(bag) == "table" then
            cast = bag.name
            icon = bag.icon
            if not cast and bag.itemId then cast, icon = ItemNameIcon(bag.itemId) end
        elseif M and M.GetMountForCurrentModifiers then
            local name, ic, spellID = M.GetMountForCurrentModifiers(flyoutMod)
            cast = name
            icon = ic
            if not cast and spellID then cast, icon = SpellNameIcon(spellID) end
        end
        return FormatButtonCastLine(buttonName, cast and { cast } or nil), icon or entry.placeholder
    end

    if kind == "vendor_mount" then
        local M = _G.FluxNCMount
        local icon = entry.placeholder
        if M and M.GetOppositeMountModeIconForBindingGhost then
            icon = M.GetOppositeMountModeIconForBindingGhost() or icon
        end
        local mode = M and M.GetMode and M.GetMode()
        local cast = (mode == "VendorMount") and "Smart mount" or "Vendor mount"
        return FormatButtonCastLine(buttonName, { cast }), icon
    end

    if kind == "teleport" then
        local TP = _G.FluxNCTeleportPortal
        local casts = {}
        local icon
        if TP and TP.GetSpellForModifier then
            local sp = TP.GetSpellForModifier(flyoutMod)
            if sp and sp.name then
                casts[#casts + 1] = sp.name
                icon = sp.icon
            end
            if TP.GetOppositeModeDisplaySpell then
                local opp = TP.GetOppositeModeDisplaySpell(flyoutMod)
                if opp and opp.name then
                    casts[#casts + 1] = opp.name
                    icon = icon or opp.icon
                end
            end
        end
        return FormatButtonCastLine(buttonName, casts), icon or entry.placeholder
    end

    if kind == "teleport_toggle" then
        local TP = _G.FluxNCTeleportPortal
        local opp = TP and TP.GetOppositeModeDisplaySpell and TP.GetOppositeModeDisplaySpell(flyoutMod)
        -- Toggle shows the opposite mode (portal while in teleport, and vice versa).
        if opp and opp.name then
            return opp.name, opp.icon or entry.placeholder
        end
        local mode = TP and TP.GetMode and TP.GetMode()
        local switchLabel = "Portal"
        if mode == "Portal" or (TP and TP.MODE_PORTAL and mode == TP.MODE_PORTAL) then
            switchLabel = "Teleport"
        end
        return switchLabel, entry.placeholder
    end

    if kind == "conjure" then
        local spell
        if Bridge then
            if entry.binding == "FLUXMAGE_CONJURE_FOOD" then
                if flyoutMod ~= "nomod" and Bridge.GetFoodSecondaryConjureSpell then
                    spell = Bridge.GetFoodSecondaryConjureSpell()
                end
                spell = spell or (Bridge.GetFoodConjureSpell and Bridge.GetFoodConjureSpell())
            elseif entry.binding == "FLUXMAGE_CONJURE_WATER" then
                if flyoutMod ~= "nomod" and Bridge.GetWaterSecondaryConjureSpell then
                    spell = Bridge.GetWaterSecondaryConjureSpell()
                end
                spell = spell or (Bridge.GetWaterConjureSpell and Bridge.GetWaterConjureSpell())
            elseif entry.binding == "FLUXMAGE_CONJURE_MANAGEM" then
                local mg = _G.FluxCombatManaGem
                if mg and mg.KnowsAnyConjureSpell and mg.KnowsAnyConjureSpell() then
                    if Bridge.GetNextManaGemConjureSpell then
                        spell = Bridge.GetNextManaGemConjureSpell()
                    end
                    if not spell and Bridge.GetPreferredCreateSpell then
                        spell = Bridge.GetPreferredCreateSpell("managem")
                    end
                elseif Bridge.GetPreferredCreateSpell then
                    spell = Bridge.GetPreferredCreateSpell("healthstone")
                end
            elseif entry.binding == "FLUXMAGE_RITUAL_OF_REFRESHMENT" then
                local Spells = _G.FluxInv and _G.FluxInv.Spells
                if Spells and Spells.HasRitualOfRefreshment and not Spells.HasRitualOfRefreshment() then
                    return nil, nil
                end
                spell = Bridge.GetFoodSecondaryConjureSpell and Bridge.GetFoodSecondaryConjureSpell()
                if type(spell) == "string" and not spell:lower():find("ritual", 1, true) then
                    -- Secondary is another conjure, not Ritual — don't mislabel.
                    spell = nil
                end
                if not spell and Spells and Spells.HasRitualOfRefreshment and Spells.HasRitualOfRefreshment() then
                    spell = "Ritual of Refreshment"
                end
            end
        end
        local cast, icon = SpellNameIcon(spell)
        if not cast then
            return nil, nil
        end
        return FormatButtonCastLine(buttonName, { cast }), icon or entry.placeholder
    end

    if kind == "utility" then
        local U = _G.FluxNCUtilitySlots
        local slots = U and U.GetSlots and U.GetSlots()
        local tierMap = type(slots) == "table" and slots[entry.slot]
        local preferred
        if type(tierMap) == "table" then
            if utilMod ~= "" and tierMap[utilMod] then
                preferred = tierMap[utilMod]
            elseif U.ResolveNomodEntry then
                preferred = select(1, U.ResolveNomodEntry(tierMap))
            else
                preferred = tierMap[""] or tierMap.base or tierMap.nomod
            end
        end
        local cast, icon
        if type(preferred) == "table" then
            cast = preferred.name
            icon = preferred.icon
            local aType = preferred.type or preferred.actionType
            local id = preferred.id or preferred.spellID or preferred.itemID or preferred.itemId
            if (not cast or not icon) and aType == "spell" and id then
                local n, ic = SpellNameIcon(id)
                cast = cast or n
                icon = icon or ic
            elseif (not cast or not icon) and aType == "item" and id then
                local n, ic = ItemNameIcon(id)
                cast = cast or n
                icon = icon or ic
            end
        end
        return FormatButtonCastLine(buttonName, cast and { cast } or nil), icon or entry.placeholder
    end

    if kind == "assisted" then
        local spellID
        if C_AssistedCombat then
            if C_AssistedCombat.GetNextCastSpell then
                spellID = C_AssistedCombat.GetNextCastSpell(true)
            end
            if not spellID and C_AssistedCombat.GetActionSpell then
                spellID = C_AssistedCombat.GetActionSpell()
            end
        end
        local cast, icon = SpellNameIcon(spellID)
        return FormatButtonCastLine(buttonName, cast and { cast } or nil), icon or entry.placeholder
    end

    return buttonName, entry.placeholder
end

--- Catalog Extra bindings by their real GetBindingKey chords (resolvers run at paint).
local function BuildExtraByChord(ChordMap)
    local out = {}
    if not ChordMap then return out end

    local function add(binding, kind, buttonName, extra)
        extra = extra or {}
        EachBindingKey(binding, function(key)
            PushExtraChord(out, ChordMap, key, {
                isButton = true,
                binding = binding,
                kind = kind,
                buttonName = buttonName or BindingTitle(binding),
                bridgeKind = extra.bridgeKind,
                placeholder = extra.placeholder,
                slot = extra.slot,
            })
        end)
    end

    -- CombatGrid
    add("FLUXCOMBAT_BANDAGE", "combat", "Bandage", { bridgeKind = "bandage", placeholder = PH.bandage })
    add("FLUXCOMBAT_HEALPOT", "combat", "Healing potion", { bridgeKind = "healPotion", placeholder = PH.healPotion })
    add("FLUXCOMBAT_MANAPOT", "combat", "Mana potion", { bridgeKind = "manaPotion", placeholder = PH.manaPotion })
    add("FLUXCOMBAT_HEALTHSTONE", "combat", "Healthstone", { bridgeKind = "healthstone", placeholder = PH.healthstone })
    add("FLUXCOMBAT_MANAGEM", "combat", "Mana gem", { bridgeKind = "managem", placeholder = PH.managem })
    add("FLUX_ASSISTED_COMBAT", "assisted", "Single-Button Assistant", { placeholder = PH.assisted })

    -- NonCombatGrid
    add("FLUXGRID_FOOD_OR_RECUP", "nc_use", "Food", { bridgeKind = "food", placeholder = PH.food })
    add("FLUXGRID_WATER_OR_COMBINED", "nc_use", "Water", { bridgeKind = "water", placeholder = PH.water })
    add("FLUXGRID_CONSUMABLES", "consumables", "Consumables", { placeholder = PH.consumables })
    add("FLUXGRIDSMARTMOUNT", "mount", "Mount", { placeholder = PH.mount })
    add("FLUXGRIDVENDORMOUNT", "vendor_mount", "Vendor mount", { placeholder = 132144 })
    add("FLUXGRIDHEARTH", "hearth", "Hearthstone", { placeholder = PH.hearth })
    add("FLUXCLASS_TELEPORT", "teleport", "Class teleport", { placeholder = PH.teleport })
    add("FLUXMAGE_TOGGLE_TPPT", "teleport_toggle", "Toggle Teleport / Portal", { placeholder = PH.teleport })

    -- Conjure
    add("FLUXMAGE_CONJURE_FOOD", "conjure", BindingTitle("FLUXMAGE_CONJURE_FOOD"), { placeholder = PH.food })
    add("FLUXMAGE_CONJURE_WATER", "conjure", BindingTitle("FLUXMAGE_CONJURE_WATER"), { placeholder = PH.water })
    add("FLUXMAGE_CONJURE_MANAGEM", "conjure", BindingTitle("FLUXMAGE_CONJURE_MANAGEM"), { placeholder = PH.managem })
    do
        local Spells = _G.FluxInv and _G.FluxInv.Spells
        if Spells and Spells.HasRitualOfRefreshment and Spells.HasRitualOfRefreshment() then
            add("FLUXMAGE_RITUAL_OF_REFRESHMENT", "conjure", BindingTitle("FLUXMAGE_RITUAL_OF_REFRESHMENT"), { placeholder = PH.food })
        end
    end

    -- TrinketMenu
    add("FLUXTRINKET1", "trinket", "Trinket (top)", { slot = 13, placeholder = PH.trinket })
    add("FLUXTRINKET2", "trinket", "Trinket (bottom)", { slot = 14, placeholder = PH.trinket })

    -- Utility slots
    for slot = 1, 4 do
        local binding = "FLUXSPELLBOOKSLOT" .. slot
        add(binding, "utility", BindingTitle(binding), { slot = slot, placeholder = PH.util })
    end

    return out
end

local function PopulateKeys()
    if not KeyVisualizer:IsOpen() or buttonCache == nil then
        return
    end

    local db = GetDb()
    local ChordMap = ns.FluxBindingChordMap
    local Action = ns.FluxBindingAction
    local Conditions = ns.FluxBindingConditions
    local Forms = ns.FluxBindingForms
    local DB = ns.FluxBindingDB3
    local Placement = ns.FluxBindingPlacement
    local BadgeHost = ns.FluxBadgeHost or _G.FluxBadgeHost
    local formToken = Forms and Forms.GetCurrentToken and Forms.GetCurrentToken() or "noform"
    local wantExtra = db.showExtraButtons ~= false
    local wantBinding = showSource == SOURCE_ALL or showSource == SOURCE_BINDING
    local wantBar = showSource == SOURCE_ALL or showSource == SOURCE_BAR
    local wantExtraSrc = wantExtra and (showSource == SOURCE_ALL or showSource == SOURCE_EXTRA)

    -- Chord indexes built ONCE per paint (never per-key IndexExtra / DB.All).
    local bindsByChord = {}
    if wantBinding and DB and DB.All and ChordMap and Action then
        for uid, b in pairs(DB.All()) do
            if b and b.key and b.key ~= "" then
                local nk = ChordMap.Normalize(b.key)
                if nk ~= "" then
                    local active = true
                    if Conditions and Conditions.IsActive then
                        active = Conditions.IsActive(b, formToken) and true or false
                    end
                    if not (db.showOnlyLoadedBindings and not active) then
                        local list = bindsByChord[nk]
                        if not list then
                            list = {}
                            bindsByChord[nk] = list
                        end
                        list[#list + 1] = {
                            uid = uid,
                            name = (Action.GetNameWithRank and Action.GetNameWithRank(b.action))
                                or Action.GetName(b.action)
                                or tostring(uid),
                            icon = Action.GetIcon(b.action),
                            active = active,
                            spellId = (b.action and b.action.type == "spell") and tonumber(b.action.id) or nil,
                        }
                    end
                end
            end
        end
    end

    local extraByChord = {}
    local stanceByChord = {}
    if wantExtraSrc and ChordMap then
        extraByChord = BuildExtraByChord(ChordMap)
    end
    if wantBar and Placement and Placement.IndexStance and ChordMap then
        IndexStanceByChord(Placement.IndexStance(), ChordMap, stanceByChord)
    end

    local miscByChord = {}
    if wantBar and ChordMap then
        if GetNumShapeshiftForms and GetShapeshiftFormInfo then
            local n = GetNumShapeshiftForms() or 0
            for form = 1, n do
                local targetKey = GetBindingKey("SHAPESHIFTBUTTON" .. form)
                if targetKey then
                    local nk = ChordMap.Normalize(targetKey)
                    if nk ~= "" then
                        local formIcon, _, _, spellId = GetShapeshiftFormInfo(form)
                        local spellName = spellId and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellId)
                        local list = miscByChord[nk]
                        if not list then
                            list = {}
                            miscByChord[nk] = list
                        end
                        list[#list + 1] = { name = spellName, icon = formIcon }
                    end
                end
            end
        end
        if NUM_PET_ACTION_SLOTS and GetPetActionInfo then
            for petAction = 1, NUM_PET_ACTION_SLOTS do
                local targetKey = GetBindingKey("BONUSACTIONBUTTON" .. petAction)
                if targetKey then
                    local nk = ChordMap.Normalize(targetKey)
                    if nk ~= "" then
                        local petName, petIcon = GetPetActionInfo(petAction)
                        local list = miscByChord[nk]
                        if not list then
                            list = {}
                            miscByChord[nk] = list
                        end
                        list[#list + 1] = { name = petName, icon = petIcon }
                    end
                end
            end
        end
    end

    -- Native bar actionKey → non-default profile lines (built once per paint).
    local nativeProfilesByAk = {}
    if (wantBar or wantBinding) and DB and DB.All and Action and _G.FluxBinding and _G.FluxBinding.IsSubNonDefault then
        local function indexProfile(ak, entry)
            if not ak or ak == "" then return end
            local list = nativeProfilesByAk[ak]
            if not list then
                list = {}
                nativeProfilesByAk[ak] = list
            end
            list[#list + 1] = entry
        end
        for uid, b in pairs(DB.All()) do
            if b and b.action then
                local sub = DB.GetFormSub and DB.GetFormSub(b, formToken)
                if sub and _G.FluxBinding.IsSubNonDefault(sub) then
                    local entry = {
                        uid = uid,
                        name = (Action.GetNameWithRank and Action.GetNameWithRank(b.action))
                            or Action.GetName(b.action)
                            or tostring(uid),
                        icon = Action.GetIcon(b.action),
                        cond = SummarizeBindingSub(sub),
                        action = b.action,
                    }
                    local bak = Action.Key and Action.Key(b.action)
                    indexProfile(bak, entry)
                    if Action.FamilyKey then
                        local fam = Action.FamilyKey(b.action)
                        if fam and fam ~= bak then
                            indexProfile(fam, entry)
                        end
                    end
                    if b.action.type == "spell" and b.action.id and Action.SlotActionKey then
                        local sak = Action.SlotActionKey(b.action.id)
                        if sak and sak ~= bak then
                            indexProfile(sak, entry)
                        end
                    end
                end
            end
        end
    end

    local flyoutMod = CurrentFlyoutMod()
    local utilMod = CurrentUtilMod()

    local function GetBinds(keyId)
        local spellNames = {}
        local nameOrder = {}
        local icon = nil
        local chord = GetModifiedKey(keyId)
        local barChord = GetBarModifiedKey(keyId)

        local function Register(spellName, spellIcon, forceIcon)
            if type(spellName) == "string" and spellName ~= "" and not spellNames[spellName] then
                spellNames[spellName] = true
                nameOrder[#nameOrder + 1] = spellName
                icon = icon or spellIcon
            end
            if forceIcon and spellIcon then
                icon = spellIcon
            end
        end

        local function RegisterList(list, forceFirst)
            if type(list) ~= "table" then return end
            for i = 1, #list do
                local e = list[i]
                if e then
                    Register(e.name, e.icon, forceFirst and i == 1)
                end
            end
        end

        local function RegisterExtraList(list)
            if type(list) ~= "table" then return end
            local seenBinding = {}
            for i = 1, #list do
                local e = list[i]
                if e and e.kind == "consumables" then
                    local bkey = e.binding or "consumables"
                    if not seenBinding[bkey] then
                        seenBinding[bkey] = true
                        local lines, primaryIcon = BuildConsumablesTooltipLines(flyoutMod)
                        if #lines == 0 then
                            Register(e.buttonName or "Consumables", e.placeholder or PH.consumables, icon == nil)
                        else
                            for j = 1, #lines do
                                local row = lines[j]
                                -- First in-bag item owns the key icon; each item is its own tooltip line.
                                Register(row.name, row.icon, icon == nil and j == 1)
                            end
                        end
                    end
                elseif e and e.kind then
                    local bkey = e.binding or (e.kind .. ":" .. tostring(e.slot or i))
                    if not seenBinding[bkey] then
                        seenBinding[bkey] = true
                        local line, tex = ResolveExtraLive(e, flyoutMod, utilMod)
                        if line then
                            Register(line, tex, icon == nil)
                        end
                    end
                elseif e and e.isStance then
                    Register(e.name, e.icon, icon == nil)
                end
            end
        end

        -- Flux binds: exact chord only (nomod "Remove Curse" on R must not leak
        -- onto Shift-R / Ctrl-R). Extra / Stance are usually bound nomod but their
        -- *content* changes with CurrentFlyoutMod / util mods — keep showing the
        -- nomod Extra/Stance under a modifier when nothing else owns that exact
        -- chord; prefer an exact Extra/Stance when one exists.
        local ChordMap = ns.FluxBindingChordMap
        local bareChord = (ChordMap and ChordMap.Normalize and ChordMap.Normalize(tostring(keyId)))
            or string.upper(tostring(keyId or ""))
        local exactExtra = wantExtraSrc and extraByChord[chord] or nil
        local exactBind = wantBinding and bindsByChord[chord] or nil
        local hasExactExtra = type(exactExtra) == "table" and #exactExtra > 0
        local hasExactBind = type(exactBind) == "table" and #exactBind > 0
        -- Alt/Meta never change bar routing — Exact Extra/bind on Alt-C swaps
        -- over the bare/Shift/Ctrl bar that would otherwise keep showing.
        local modsOverrideBar = (showAlt or showMeta) and chord ~= barChord
        local swapToOverlay = modsOverrideBar and (hasExactExtra or hasExactBind)

        local function PickExtraOrStanceList(exactList, byChord)
            if type(exactList) == "table" and #exactList > 0 then
                return exactList
            end
            -- Modifier active, nothing on this exact chord: fall back to nomod.
            if chord ~= bareChord and not hasExactBind and type(byChord) == "table" then
                local bare = byChord[bareChord]
                if type(bare) == "table" and #bare > 0 then
                    return bare
                end
            end
            return nil
        end

        if wantExtraSrc then
            local extraList = PickExtraOrStanceList(exactExtra, extraByChord)
            if extraList then
                RegisterExtraList(extraList)
            end
        end

        if wantBar and not swapToOverlay then
            local stanceExact = stanceByChord[chord]
            local stanceList = PickExtraOrStanceList(stanceExact, stanceByChord)
            if stanceList then
                RegisterList(stanceList)
            end
        end

        -- Live cast target on this key (main LAB effective state = what the key fires).
        -- Use bar-effective chord so Alt / Shift+Ctrl still resolve the bar —
        -- unless an Extra / Flux bind on Alt/Meta owns this key (swap above).
        local slot = ResolveBarSlot(keyId)
        local castName
        local barHandled = false
        local coveredUid = {}
        local meta = { desaturated = false, badges = {} }
        if wantBar and slot and not swapToOverlay then
            barHandled = true
            local name, tex, spellId = ActionSlotDisplay(slot)
            castName = name
            meta.desaturated = IsSpellLowerRank(spellId)

            local tipParts = {}
            local nativeAk = NativeActionKeyForSlot(slot)
            local nativeCond = ""

            -- Non-default native profile conditions attach to the cast segment.
            if nativeAk then
                local candidates = nativeProfilesByAk[nativeAk]
                if type(candidates) == "table" then
                    for i = 1, #candidates do
                        local e = candidates[i]
                        if e and e.uid and not coveredUid[e.uid] then
                            coveredUid[e.uid] = true
                            if e.cond and e.cond ~= "" then
                                if nativeCond == "" then
                                    nativeCond = e.cond
                                else
                                    nativeCond = nativeCond .. "; " .. e.cond
                                end
                            elseif nativeCond == "" then
                                nativeCond = "custom"
                            end
                        end
                    end
                end
            end

            if name or tex then
                local label = name or ("Action " .. tostring(slot))
                castName = label
                local seg = TextureTag(tex) .. label
                if nativeCond ~= "" then
                    seg = seg .. " [" .. nativeCond .. "]"
                end
                tipParts[#tipParts + 1] = seg
                if tex then
                    icon = tex
                end
            end

            -- Corner badges: peer bindings OR multi-cast extras (extra:<uid>:<n>).
            if BadgeHost and BadgeHost.GetSlotBadges then
                local badges = BadgeHost.GetSlotBadges(slot)
                if type(badges) == "table" then
                    for i = 1, #badges do
                        local vis = ResolveSlotBadgeVisual(badges[i], formToken)
                        if vis then
                            if vis.uid then coveredUid[vis.uid] = true end
                            meta.badges[#meta.badges + 1] = {
                                icon = vis.icon,
                                alpha = vis.alpha,
                                desaturated = vis.desaturated,
                            }
                            local seg = TextureTag(vis.icon) .. (vis.name or "?")
                            if vis.cond and vis.cond ~= "" then
                                seg = seg .. " [" .. vis.cond .. "]"
                            elseif vis.tipTag then
                                seg = seg .. " [" .. vis.tipTag .. "]"
                            end
                            tipParts[#tipParts + 1] = seg
                        end
                    end
                end
            end
            -- Fallback: DB multi-cast extras when BadgeHost has not published yet.
            AppendMultiCastExtrasFromDB(slot, nativeAk, meta, tipParts, coveredUid, formToken, TextureTag)

            if #tipParts > 0 then
                -- One tooltip line per spell/item, with that entry's profile on the same line.
                for i = 1, #tipParts do
                    local line = tipParts[i]
                    if line and not spellNames[line] then
                        spellNames[line] = true
                        nameOrder[#nameOrder + 1] = line
                    end
                end
                -- Badges are drawn on the key; don't inflate +N for them.
                meta.badgeCount = #meta.badges
            end

            RegisterList(miscByChord[chord] or miscByChord[barChord])
        end

        -- Flux Binding: exact filter chord only (no bare fallback under Shift/Ctrl/Alt).
        if wantBinding then
            local list = exactBind

            if not barHandled then
                local nativeName, nativeTex, nativeAk
                if slot and Action and not swapToOverlay then
                    nativeName, nativeTex = ActionSlotDisplay(slot)
                    nativeAk = NativeActionKeyForSlot(slot)
                end
                local matchedNative = false

                if type(list) == "table" then
                    for i = 1, #list do
                        local e = list[i]
                        if e then
                            local b = e.uid and DB and DB.Get and DB.Get(e.uid)
                            local sub = b and DB.GetFormSub and DB.GetFormSub(b, formToken)
                            local cond = SummarizeBindingSub(sub)
                            local disp = b and BindingDisplayName(b) or e.name
                            local isNative = false
                            if nativeAk and b and b.action then
                                if Action.KeysMatch then
                                    isNative = Action.KeysMatch(b.action, nativeAk)
                                elseif Action.Key then
                                    isNative = Action.Key(b.action) == nativeAk
                                end
                            end
                            if isNative then matchedNative = true end

                            local line
                            if cond ~= "" then
                                line = TextureTag(e.icon) .. disp .. " [" .. cond .. "]"
                            else
                                line = TextureTag(e.icon) .. disp
                            end
                            if isNative then
                                line = line .. " [action bar]"
                            end
                            Register(line, e.icon, icon == nil and i == 1)
                        end
                    end
                end

                -- Binding-only filter: surface shared native bar spell / badges.
                if not wantBar and slot then
                    if nativeName and not matchedNative then
                        Register(TextureTag(nativeTex) .. "Action bar: " .. nativeName, nativeTex)
                    end
                    if BadgeHost and BadgeHost.GetSlotBadges then
                        local badges = BadgeHost.GetSlotBadges(slot)
                        if type(badges) == "table" then
                            for i = 1, #badges do
                                local vis = ResolveSlotBadgeVisual(badges[i], formToken)
                                if vis then
                                    meta.badges[#meta.badges + 1] = {
                                        icon = vis.icon,
                                        alpha = vis.alpha,
                                        desaturated = vis.desaturated,
                                    }
                                    local seg = TextureTag(vis.icon) .. (vis.name or "?")
                                    if vis.cond and vis.cond ~= "" then
                                        seg = seg .. " [" .. vis.cond .. "]"
                                    elseif vis.tipTag then
                                        seg = seg .. " [" .. vis.tipTag .. "]"
                                    else
                                        seg = seg .. " [badge]"
                                    end
                                    Register(seg, vis.icon)
                                end
                            end
                            meta.badgeCount = #meta.badges
                        end
                    end
                    if #meta.badges == 0 then
                        local tipParts = {}
                        AppendMultiCastExtrasFromDB(slot, nativeAk, meta, tipParts, coveredUid, formToken, TextureTag)
                        for i = 1, #tipParts do
                            Register(tipParts[i])
                        end
                        meta.badgeCount = #meta.badges
                    end
                    if not icon and nativeTex then
                        icon = nativeTex
                        local _, _, nSid = ActionSlotDisplay(slot)
                        meta.desaturated = IsSpellLowerRank(nSid)
                    end
                end
            else
                if type(list) == "table" then
                    for i = 1, #list do
                        local e = list[i]
                        if e and e.name and e.name ~= castName and not (e.uid and coveredUid[e.uid]) then
                            local already = false
                            for j = 1, #nameOrder do
                                if nameOrder[j]:find(e.name, 1, true) then
                                    already = true
                                    break
                                end
                            end
                            if not already then
                                local b = e.uid and DB and DB.Get and DB.Get(e.uid)
                                local sub = b and DB.GetFormSub and DB.GetFormSub(b, formToken)
                                local cond = SummarizeBindingSub(sub)
                                local disp = b and BindingDisplayName(b) or e.name
                                local line
                                if cond ~= "" then
                                    line = TextureTag(e.icon) .. disp .. " [" .. cond .. "]"
                                else
                                    line = disp
                                end
                                Register(line, e.icon)
                            end
                        end
                    end
                end
            end
        end

        -- Free (non-bar) binding: apply lower-rank desat from the primary spell.
        if not barHandled and icon then
            if type(exactBind) == "table" and exactBind[1] and exactBind[1].spellId then
                meta.desaturated = IsSpellLowerRank(exactBind[1].spellId)
            end
        end

        return nameOrder, icon, meta
    end

    for keyId, widget in pairs(buttonCache) do
        local data = widget:GetKey()
        if data ~= nil then
            local binds, icon, meta = GetBinds(keyId)
            widget:SetIcon(icon)
            if widget.SetDesaturated then
                widget:SetDesaturated(meta and meta.desaturated)
            end
            if widget.SetBadges then
                widget:SetBadges(meta and meta.badges)
            end
            widget:SetHighlight(db.highlightEmptyKeys and #binds == 0 and not data.disabled)
            local actionCount = #binds
            if meta and meta.badgeCount and meta.badgeCount > 0 then
                actionCount = math.max(1, actionCount - meta.badgeCount)
            end
            widget:SetActionCount(actionCount)

            local tipBinds = binds
            widget:SetCallback("OnEnter", function()
                if not data.disabled then
                    ShowTooltip(widget.frame, ChordTipTitle(keyId), table.concat(tipBinds, "\n"))
                end
            end)
            widget:SetCallback("OnLeave", function()
                HideTooltip()
            end)

            -- Live tooltip refresh while hovering during modifier changes.
            if GameTooltip and GameTooltip:GetOwner() == widget.frame and GameTooltip:IsShown() then
                if not data.disabled then
                    ShowTooltip(widget.frame, ChordTipTitle(keyId), table.concat(tipBinds, "\n"))
                end
            end
        end
    end
end

local function RefreshKeys()
    if not KeyVisualizer:IsOpen() or buttonCache == nil then
        return
    end
    -- Mouse panel membership can change with binds — rebuild when the set changes.
    if GetDb().showMouse ~= false then
        local active = select(1, GetActiveMouseKeySet())
        local sig = MouseKeySignature(active)
        if sig ~= lastMouseKeySig then
            lastMouseKeySig = sig
            RebuildKeyboardLayout()
            return
        end
    end
    PopulateKeys()
end

--- Coalesce bursty events (mod edges, ACTIONBAR_SLOT_CHANGED) into one paint.
local function QueueRefreshKeys()
    if populateQueued or not KeyVisualizer:IsOpen() then
        return
    end
    populateQueued = true
    local function run()
        populateQueued = false
        if KeyVisualizer:IsOpen() then
            RefreshKeys()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

function KeyVisualizer:SetKeyboardLayout(layout, size)
    if not self:IsOpen() then
        return
    end
    BuildLayout(layout, size)
    PopulateKeys()
end

-- Runtime listeners exist ONLY while the visualizer window is open.
local modifierFrame = CreateFrame("Frame")
local eventFrame = CreateFrame("Frame")

local function OnModifierEvent(_, event, key, state)
    if not KeyVisualizer:IsOpen() or event ~= "MODIFIER_STATE_CHANGED" then
        return
    end

    local down = state == 1
    local changed = false
    if key == "LSHIFT" or key == "RSHIFT" then
        if showShift ~= down then
            showShift = down
            changed = true
        end
        if down and showCtrl then
            showCtrl = false
            changed = true
        end
    elseif key == "LCTRL" or key == "RCTRL" then
        local wantCtrl = down and not showShift
        if showCtrl ~= wantCtrl then
            showCtrl = wantCtrl
            changed = true
        end
    elseif key == "LALT" or key == "RALT" then
        if showAlt ~= down then
            showAlt = down
            changed = true
        end
    elseif key == "LMETA" or key == "RMETA" then
        if showMeta ~= down then
            showMeta = down
            changed = true
        end
    end

    if not changed then
        return
    end

    suppressFilterCallbacks = true
    if showShiftWidget then showShiftWidget:SetValue(showShift) end
    if showCtrlWidget then showCtrlWidget:SetValue(showCtrl) end
    if showAltWidget then showAltWidget:SetValue(showAlt) end
    if showMetaWidget then showMetaWidget:SetValue(showMeta) end
    suppressFilterCallbacks = false

    QueueRefreshKeys()
end

local function OnBindingEvent()
    if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
        and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
        return
    end
    if KeyVisualizer:IsOpen() then
        QueueRefreshKeys()
    end
end

modifierFrame:SetScript("OnEvent", OnModifierEvent)
eventFrame:SetScript("OnEvent", OnBindingEvent)

local function ActivateRuntime()
    if hooksRegistered then return end
    hooksRegistered = true

    modifierFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    eventFrame:RegisterEvent("UPDATE_BINDINGS")
    eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

    if _G.FluxBinding and _G.FluxBinding.RegisterApplied then
        _G.FluxBinding.RegisterApplied("keyVisualizer", function()
            KeyVisualizer:Redraw()
        end)
    end
end

local function DeactivateRuntime()
    if not hooksRegistered then return end
    hooksRegistered = false

    modifierFrame:UnregisterAllEvents()
    eventFrame:UnregisterAllEvents()

    if _G.FluxBinding and _G.FluxBinding.RegisterApplied then
        _G.FluxBinding.RegisterApplied("keyVisualizer", nil)
    end

    populateQueued = false
    scaleQueued = false
end

function KeyVisualizer:Open()
    if self:IsOpen() then
        return
    end

    ActivateRuntime()

    do
        local function OnClose(container)
            DeactivateRuntime()
            AceGUI:Release(container)
            showCtrl = false
            showAlt = false
            showShift = false
            showMeta = false
            showSource = SOURCE_ALL
            buttonCache = nil
            frame = nil
            tree = nil
            filterBar = nil
            showCtrlWidget = nil
            showAltWidget = nil
            showShiftWidget = nil
            showMetaWidget = nil
            populateQueued = false
            scaleQueued = false
            userResized = false
            initialFitDone = false
            layoutUnitsW, layoutUnitsH = 0, 0
            lastBuiltShowMouse = nil
            lastMouseKeySig = nil
            ns.FluxKeyVisualizerGridSize = nil
        end

        frame = AceGUI:Create("Frame")
        frame:SetCallback("OnClose", OnClose)
        frame:SetTitle("Flux Key Visualizer")
        frame:SetLayout("List")
        frame:SetWidth(MIN_FRAME_WIDTH)
        frame:SetHeight(380)
        if frame.SetStatusText then
            frame:SetStatusText("/fluxbind viz")
        end

        local f = frame.frame
        if f then
            userResized = false
            initialFitDone = false
            ns.FluxKeyVisualizerGridSize = 32
            layoutUnitsW, layoutUnitsH = 0, 0
            f:SetResizable(true)
            if f.SetResizeBounds then
                f:SetResizeBounds(640, 300, 1800, 1000)
            else
                if f.SetMinResize then f:SetMinResize(640, 300) end
                if f.SetMaxResize then f:SetMaxResize(1800, 1000) end
            end
            f:HookScript("OnSizeChanged", function()
                if suppressResizeHook or not KeyVisualizer:IsOpen() then return end
                userResized = true
                QueueDynamicGrid()
            end)
        end
    end

    do
        -- Compact filter strip (no InlineGroup chrome).
        filterBar = AceGUI:Create("SimpleGroup")
        filterBar:SetFullWidth(true)
        filterBar:SetLayout("Flow")

        local function AddCheck(label, width, getValue, onChange)
            local widget = AceGUI:Create("CheckBox")
            widget:SetLabel(label)
            widget:SetWidth(width)
            widget:SetValue(getValue())
            widget:SetCallback("OnValueChanged", function(_, _, value)
                if suppressFilterCallbacks then return end
                onChange(value and true or false)
            end)
            filterBar:AddChild(widget)
            return widget
        end

        AddCheck("Loaded", 78, function()
            return GetDb().showOnlyLoadedBindings
        end, function(v)
            GetDb().showOnlyLoadedBindings = v
            QueueRefreshKeys()
        end)

        AddCheck("Empty", 70, function()
            return GetDb().highlightEmptyKeys
        end, function(v)
            GetDb().highlightEmptyKeys = v
            QueueRefreshKeys()
        end)

        AddCheck("Extra", 64, function()
            return GetDb().showExtraButtons ~= false
        end, function(v)
            GetDb().showExtraButtons = v
            QueueRefreshKeys()
        end)

        AddCheck("Mouse", 68, function()
            return GetDb().showMouse ~= false
        end, function(v)
            GetDb().showMouse = v
            RebuildKeyboardLayout()
        end)

        do
            local items = {
                [SOURCE_ALL] = "All",
                [SOURCE_BINDING] = "Binding",
                [SOURCE_BAR] = "Bars",
                [SOURCE_EXTRA] = "Extra",
            }
            local order = { SOURCE_ALL, SOURCE_BINDING, SOURCE_BAR, SOURCE_EXTRA }
            local widget = AceGUI:Create("FluxBlizzardDropdown") or AceGUI:Create("Dropdown")
            widget:SetLabel("")
            widget:SetList(items, order)
            widget:SetValue(SOURCE_ALL)
            widget:SetWidth(100)
            widget:SetCallback("OnValueChanged", function(_, _, value)
                if suppressFilterCallbacks then return end
                showSource = value
                QueueRefreshKeys()
            end)
            filterBar:AddChild(widget)
        end

        showCtrlWidget = AddCheck(SanitizeKeybind("CTRL"), 58, function()
            return showCtrl
        end, function(v)
            showCtrl = v
            QueueRefreshKeys()
        end)

        showAltWidget = AddCheck(SanitizeKeybind("ALT"), 54, function()
            return showAlt
        end, function(v)
            showAlt = v
            QueueRefreshKeys()
        end)

        showShiftWidget = AddCheck(SanitizeKeybind("SHIFT"), 64, function()
            return showShift
        end, function(v)
            showShift = v
            QueueRefreshKeys()
        end)

        showMetaWidget = AddCheck(SanitizeKeybind("META"), 62, function()
            return showMeta
        end, function(v)
            showMeta = v
            QueueRefreshKeys()
        end)

        frame:AddChild(filterBar)
    end

    do
        local function DrawTreeContainer(container, _, value)
            local group = { strsplit("\001", value) }
            local layout = group[1] or DEFAULT_KEYBOARD_LAYOUT
            local size = tonumber(group[2]) or DEFAULT_KEYBOARD_SIZE
            local db = GetDb()

            local showMouse = db.showMouse ~= false
            if layout ~= db.lastKeyboardLayout
                or size ~= db.lastKeyboardSize
                or buttonCache == nil
                or showMouse ~= lastBuiltShowMouse
            then
                db.lastKeyboardLayout = layout
                db.lastKeyboardSize = size
                container:ReleaseChildren()
                buttonCache = nil
                self:SetKeyboardLayout(layout, size)
            else
                PopulateKeys()
            end
        end

        tree = AceGUI:Create("FluxKeyVisualizerTreeGroup")
        tree:SetLayout("FluxKeys")
        tree:SetFullWidth(true)
        tree:SetFullHeight(true)
        tree:SetCallback("OnGroupSelected", DrawTreeContainer)
        tree:SetTreeWidth(TREE_SIDE_WIDTH, false)
        tree:SetTree(GetTreeLayout())
        SelectLayout()

        frame:AddChild(tree)
    end
end

function KeyVisualizer:Close()
    if not self:IsOpen() then
        return
    end
    DeactivateRuntime()
    frame:Hide()
end

function KeyVisualizer:Redraw()
    if not self:IsOpen() then
        return
    end
    QueueRefreshKeys()
end

function KeyVisualizer:IsOpen()
    return frame ~= nil and frame:IsVisible()
end
