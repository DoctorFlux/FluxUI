-- Binding/Core/Placement.lua
-- Where a spell/item sits: Flux action-bar main/mini rows (with live keys) and
-- ExtraButtonSystem buttons (Trinket / Utility / Combat / NC / Flyout favorites).

local addonName, ns = ...

local Action = ns.FluxBindingAction

local Placement = {}
ns.FluxBindingPlacement = Placement

-- ChordMap is resolved lazily: Placement used to load before ChordMap in the TOC,
-- which left a nil upvalue and dropped every column keybind from bar labels.
local function ChordMap()
    return ns.FluxBindingChordMap
end

local ROW_SHORT = {
    main = "main",
    secondary = "Shift",
    tertiary = "Ctrl",
}

-- Same Texture\\MouseButton*.tga icons as Flux action bars / FluxNCHotkeyUtil.
-- Binding list uses full Shift-/Ctrl-/Alt- (not S-/C-/A-).
local function FormatBaseKeyDisplay(baseKey)
    if not baseKey or baseKey == "" then return nil end
    local HotkeyUtil = _G.FluxNCHotkeyUtil
    if HotkeyUtil and HotkeyUtil.GetFormattedKeyFromKey then
        -- Pass base only so HotkeyUtil does not prepend S-/C-/A-.
        local text = HotkeyUtil.GetFormattedKeyFromKey(baseKey, false, false)
        if text and text ~= "" then
            -- Defensive: expand any leftover abbreviations.
            text = text:gsub("SHIFT%-", "Shift-"):gsub("CTRL%-", "Ctrl-"):gsub("ALT%-", "Alt-")
            text = text:gsub("STRG%-", "Ctrl-")
            text = text:gsub("S%-", "Shift-"):gsub("C%-", "Ctrl-"):gsub("A%-", "Alt-")
            return text
        end
    end
    return baseKey
end

local function ModifierPrefixFromMods(mods)
    if type(mods) ~= "table" then return "" end
    local prefix = ""
    -- Match Blizzard chord order used in Normalize: Alt, Ctrl, Shift.
    if mods.alt then prefix = prefix .. "Alt-" end
    if mods.ctrl then prefix = prefix .. "Ctrl-" end
    if mods.shift then prefix = prefix .. "Shift-" end
    if mods.meta then prefix = prefix .. "Meta-" end
    return prefix
end

--- Base key only (row label already says main / Shift / Ctrl).
local function FormatChordDisplay(chord)
    if not chord or chord == "" then return nil end
    local CM = ChordMap()
    local base = chord
    if CM and CM.Parse then
        base = select(1, CM.Parse(chord)) or chord
    end
    return FormatBaseKeyDisplay(base)
end

local function FormatChordsDisplay(chords)
    if type(chords) ~= "table" or #chords == 0 then return nil end
    local parts, seen = {}, {}
    for i = 1, #chords do
        local text = FormatChordDisplay(chords[i]) or chords[i]
        if text and not seen[text] then
            seen[text] = true
            parts[#parts + 1] = text
        end
    end
    if #parts == 0 then return nil end
    return table.concat(parts, "/")
end

--- Full chord display with Shift-/Ctrl-/Alt- kept (Extra / Stance have no separate row tags).
local function FormatChordDisplayFull(chord)
    if not chord or chord == "" then return nil end
    local CM = ChordMap()
    local base, mods
    if CM and CM.Parse then
        base, mods = CM.Parse(chord)
    else
        base = chord
    end
    local prefix = ModifierPrefixFromMods(mods)
    local baseText = FormatBaseKeyDisplay(base) or base or ""
    if baseText == "" then return nil end
    return prefix .. baseText
end

local function FormatChordsDisplayFull(chords)
    if type(chords) ~= "table" or #chords == 0 then return nil end
    local parts, seen = {}, {}
    for i = 1, #chords do
        local text = FormatChordDisplayFull(chords[i]) or chords[i]
        if text and not seen[text] then
            seen[text] = true
            parts[#parts + 1] = text
        end
    end
    if #parts == 0 then return nil end
    return table.concat(parts, "/")
end

local function BindingKeys(bindingName)
    local out = {}
    if type(bindingName) ~= "string" or bindingName == "" or not GetBindingKey then
        return out
    end
    local CM = ChordMap()
    for i = 1, select("#", GetBindingKey(bindingName)) do
        local key = select(i, GetBindingKey(bindingName))
        if key and key ~= "" then
            out[#out + 1] = (CM and CM.Normalize and CM.Normalize(key)) or key
        end
    end
    return out
end

local function FirstBindingKey(bindingName)
    local keys = BindingKeys(bindingName)
    return keys[1]
end

--- All keys for a binding (raw chords for logic).
local function FormatKeys(bindingName)
    local keys = BindingKeys(bindingName)
    if #keys == 0 then return nil end
    return table.concat(keys, " / ")
end

local function FirstRawKey(bindingName)
    local keys = BindingKeys(bindingName)
    return keys[1]
end

--- Combine Extra button binding key with a flyout/utility modifier (shift/ctrl/alt/…).
local function ChordWithMod(bindingName, modKey)
    local base = FirstRawKey(bindingName)
    if not base or base == "" then
        return nil
    end
    local mk = tostring(modKey or "")
    if mk == "" or mk == "nomod" or mk == "base" then
        return base
    end
    local prefix = {}
    local seen = {}
    for token in mk:gmatch("[^+%-]+") do
        local u = string.upper(token)
        if (u == "SHIFT" or u == "CTRL" or u == "ALT" or u == "META") and not seen[u] then
            seen[u] = true
            prefix[#prefix + 1] = u
        end
    end
    if #prefix == 0 then
        return base
    end
    -- Strip mods already on the base key so we don't double them.
    local bare = base
        :gsub("^ALT%-", "")
        :gsub("^CTRL%-", "")
        :gsub("^SHIFT%-", "")
        :gsub("^META%-", "")
        :gsub("^ALT%-", "")
        :gsub("^CTRL%-", "")
        :gsub("^SHIFT%-", "")
        :gsub("^META%-", "")
    local combined = table.concat(prefix, "-") .. "-" .. bare
    local CM = ChordMap()
    if CM and CM.Normalize then
        return CM.Normalize(combined) or combined
    end
    return combined
end

local function DisplayChordWithMod(bindingName, modKey)
    local chord = ChordWithMod(bindingName, modKey)
    if not chord then
        return nil
    end
    return FormatChordsDisplayFull({ chord }) or FormatChordsDisplay({ chord }) or chord
end

--- Binding keys with mouse/space icons for UI labels (base key only).
local function FormatKeysDisplay(bindingName)
    local keys = BindingKeys(bindingName)
    if #keys == 0 then return nil end
    return FormatChordsDisplay(keys)
end

--- Extra-button keys: keep Shift/Ctrl/Alt prefixes on the bound chords.
local function FormatKeysDisplayFull(bindingName)
    local keys = BindingKeys(bindingName)
    if #keys == 0 then return nil end
    return FormatChordsDisplayFull(keys)
end

local function ActionKeyFromTypeId(actionType, id, macroName)
    if not Action then return nil end
    if actionType == "spell" or actionType == "companion" then
        local desc = Action.Spell(tonumber(id))
        return (Action.FamilyKey and Action.FamilyKey(desc)) or Action.Key(desc)
    elseif actionType == "item" then
        return Action.Key(Action.Item(tonumber(id)))
    elseif actionType == "macro" then
        local name = macroName
        if (not name or name == "") and id and GetMacroInfo then
            name = GetMacroInfo(id)
        end
        if name and name ~= "" then
            return Action.Key(Action.Macro(name))
        end
    elseif actionType == "mount" and id then
        return "mount:" .. tostring(id)
    end
    return nil
end

local function PushPlace(map, actionKey, place)
    if not actionKey or type(place) ~= "table" then return end
    local list = map[actionKey]
    if not list then
        list = {}
        map[actionKey] = list
    end
    place.placeId = Placement.PlaceId(place)
    list[#list + 1] = place
end

--- Stable placement identity for list rows / DB placeId linking.
--- Examples: ab:45, stance:2, extra:FLUXGRIDHEARTH, util:3:base
function Placement.PlaceId(place)
    if type(place) ~= "table" then
        return nil
    end
    if type(place.placeId) == "string" and place.placeId ~= "" then
        return place.placeId
    end
    local src = place.source
    if src == "actionbar" and place.slot then
        return "ab:" .. tostring(place.slot)
    end
    if src == "stance" then
        if place.bindIndex then
            return "stance:" .. tostring(place.bindIndex)
        end
        if place.slotIndex then
            return "stance:slot:" .. tostring(place.slotIndex)
        end
    end
    if src == "utility" then
        -- Main Utility button (flyout parent): util:1 .. util:4
        if place.role == "utility" and place.slotIndex then
            return "util:" .. tostring(place.slotIndex)
        end
        local slot = place.slotIndex or place.slot
        local mode = place.modKey or place.modTag or "base"
        if mode == "" then mode = "base" end
        if slot then
            return "util:" .. tostring(slot) .. ":" .. tostring(mode)
        end
    end
    if src == "extra" then
        -- Flyout favorites: unique per button + mod + spell/item.
        local role = place.role
        if role == "mount_flyout" or role == "hearth_flyout" or role == "class_teleport_spell" then
            local mod = place.modKey or place.modTag or "nomod"
            local fav = place.favKey or place.spellID or place.itemId or place.itemID or ""
            return string.format("extra:%s:%s:%s",
                tostring(place.binding or role), tostring(mod), tostring(fav))
        end
        if place.binding and place.binding ~= "" then
            return "extra:" .. tostring(place.binding)
        end
        if place.role and place.role ~= "" then
            return "extra:role:" .. tostring(place.role)
        end
    end
    if src == "multicast" then
        return string.format("mcast:%s:%s:%d",
            tostring(place.hostUid or "?"),
            tostring(place.formToken or "noform"),
            tonumber(place.extraIndex) or 0)
    end
    if place.binding and place.binding ~= "" then
        return "bind:" .. tostring(place.binding)
    end
    if place.label and place.label ~= "" then
        return "lbl:" .. tostring(place.label)
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Action bar geometry: slot → column / storage row + effective chords
-- ---------------------------------------------------------------------------

local slotLocateCache = nil

local function InvalidateSlotLocate()
    slotLocateCache = nil
end

local function EnsureSlotLocate()
    if slotLocateCache then return slotLocateCache end
    local State = ns.FluxActionBarState or _G.FluxActionBarState
    local CM = ChordMap()
    local cache = {}
    if State and State.GetSecondarySlot and State.GetTertiarySlot and State.GetMainSlot then
        local cols = (CM and CM.TOTAL_COLUMNS) or 19
        -- Register cols 13–19 first. GetMainSlot(1,2)=13 collides with GetMainSlot(13);
        -- first-writer-wins must prefer the dedicated page-2 columns.
        local order = {}
        for col = 13, cols do order[#order + 1] = col end
        for col = 1, math.min(12, cols) do order[#order + 1] = col end
        for oi = 1, #order do
            local col = order[oi]
            cache[State.GetSecondarySlot(col)] = { col = col, row = "secondary" }
            cache[State.GetTertiarySlot(col)] = { col = col, row = "tertiary" }
            -- Label every stance/page main for DescribeBarSlot, but CatalogBarSlotSet
            -- (below) decides which of those count as Binding-list places.
            for state = 0, 18 do
                local main = State.GetMainSlot(col, state)
                if main and not cache[main] then
                    cache[main] = { col = col, row = "main" }
                end
            end
        end
    end
    slotLocateCache = cache
    return cache
end

local function ColumnBaseKey(col)
    local CM = ChordMap()
    if not CM or not CM.COLUMN_BINDING_NAME then return nil end
    local bindingName = CM.COLUMN_BINDING_NAME[col]
    local key = FirstBindingKey(bindingName)
    if not key or key == "" then return nil end
    if CM.Parse then
        return select(1, CM.Parse(key))
    end
    return key
end

--- Action slots the Binding catalog may treat as places.
--- Always: Flux mini rows + default main page. Also: slots currently reached by
--- each column's bare/Shift/Ctrl chord (active stance/page). Skips other
--- stance/paging mains so leftover spells there do not claim btn N · R.
function Placement.CatalogBarSlotSet()
    local set = {}
    local State = ns.FluxActionBarState or _G.FluxActionBarState
    local CM = ChordMap()
    if not (State and State.GetSecondarySlot and State.GetTertiarySlot and State.GetMainSlot) then
        for slot = 1, 120 do
            set[slot] = true
        end
        return set
    end
    local cols = (CM and CM.TOTAL_COLUMNS) or 19
    for col = 1, cols do
        local sec = State.GetSecondarySlot(col)
        local tert = State.GetTertiarySlot(col)
        local main0 = State.GetMainSlot(col, 0)
        if sec then set[sec] = true end
        if tert then set[tert] = true end
        if main0 then set[main0] = true end
        local base = ColumnBaseKey(col)
        if base and base ~= "" and CM and CM.SlotsForChord and CM.Normalize then
            local variants = {
                CM.Normalize(base),
                CM.Normalize("SHIFT-" .. base),
                CM.Normalize("CTRL-" .. base),
            }
            for v = 1, #variants do
                local chord = variants[v]
                local bySlot = chord and CM.SlotsForChord(chord)
                if type(bySlot) == "table" then
                    for slot in pairs(bySlot) do
                        slot = tonumber(slot) or slot
                        if slot then set[slot] = true end
                    end
                end
            end
        end
    end
    return set
end

--- Effective chords that currently reach `slot` (honors SmartLayout promotion).
local function EffectiveChordsForSlot(slot)
    local out, seen = {}, {}
    local CM = ChordMap()
    if not CM or not CM.SlotsForChord or not CM.COLUMN_BINDING_NAME then
        return out
    end
    local loc = EnsureSlotLocate()[slot]
    local cols = {}
    if loc and loc.col then
        cols[1] = loc.col
    else
        for c = 1, (CM.TOTAL_COLUMNS or 19) do
            cols[#cols + 1] = c
        end
    end
    for _, col in ipairs(cols) do
        local base = ColumnBaseKey(col)
        if base and base ~= "" then
            local variants = {
                CM.Normalize(base),
                CM.Normalize("SHIFT-" .. base),
                CM.Normalize("CTRL-" .. base),
            }
            for v = 1, #variants do
                local chord = variants[v]
                if chord and chord ~= "" and not seen[chord] then
                    local bySlot = CM.SlotsForChord(chord)
                    if bySlot and bySlot[slot] then
                        seen[chord] = true
                        out[#out + 1] = chord
                    end
                end
            end
        end
    end
    return out
end

local function RowShort(row)
    return ROW_SHORT[row or ""] or "btn"
end

--- Row tag from which chords actually reach this slot (promotion-aware).
--- Solo column (only one spell/item): always "main" — never Shift/Ctrl.
local function RowLabelFromChords(chords, storageRow, soloColumn)
    if soloColumn then
        return "main"
    end
    local hasBare, hasShift, hasCtrl = false, false, false
    local CM = ChordMap()
    if type(chords) == "table" then
        for i = 1, #chords do
            local chord = chords[i]
            if chord and chord ~= "" and CM and CM.Parse then
                local _, mods = CM.Parse(chord)
                if mods and mods.shift then
                    hasShift = true
                elseif mods and mods.ctrl then
                    hasCtrl = true
                else
                    hasBare = true
                end
            end
        end
    end
    if hasBare and hasShift and hasCtrl then
        return "Shift/Ctrl"
    end
    if hasShift and hasCtrl and not hasBare then
        return "Shift/Ctrl"
    end
    if hasBare and hasShift and not hasCtrl then
        return "main/Shift"
    end
    if hasBare and hasCtrl and not hasShift then
        return "main/Ctrl"
    end
    if hasShift and not hasBare and not hasCtrl then
        return "Shift"
    end
    if hasCtrl and not hasBare and not hasShift then
        return "Ctrl"
    end
    if hasBare and not hasShift and not hasCtrl then
        return "main"
    end
    return RowShort(storageRow)
end

--- When SmartLayout promotes a solo mini, invent all three column chords for that slot.
local function PromotedModeForColumn(col)
    col = tonumber(col)
    if not col then return nil end
    local State = ns.FluxActionBarState or _G.FluxActionBarState
    if not State then return nil end

    local function hasAction(slot)
        if not slot or not HasAction then return false end
        return HasAction(slot) and true or false
    end

    local function hasMainContent()
        for state = 0, 18 do
            if hasAction(State.GetMainSlot(col, state)) then
                return true
            end
        end
        return false
    end
    if hasMainContent() then return nil end
    local hasSec = hasAction(State.GetSecondarySlot(col))
    local hasTert = hasAction(State.GetTertiarySlot(col))
    if hasSec and hasTert then return "both"
    elseif hasSec then return "sec"
    elseif hasTert then return "tert"
    end
    return nil
end

--- How many of main / Shift / Ctrl rows in this column have an action.
local function ColumnActionCount(col)
    col = tonumber(col)
    local State = ns.FluxActionBarState or _G.FluxActionBarState
    if not col or not State then return 0 end
    local function hasAction(slot)
        if not slot or not HasAction then return false end
        return HasAction(slot) and true or false
    end
    local n = 0
    for state = 0, 18 do
        if hasAction(State.GetMainSlot(col, state)) then
            n = n + 1
            break
        end
    end
    if hasAction(State.GetSecondarySlot(col)) then n = n + 1 end
    if hasAction(State.GetTertiarySlot(col)) then n = n + 1 end
    return n
end

--- Column mini occupancy (for Shift/Ctrl fallback when only one mini is filled).
local function ColumnMiniOccupancy(col)
    col = tonumber(col)
    local State = ns.FluxActionBarState or _G.FluxActionBarState
    if not col or not State then return false, false end
    local function hasAction(slot)
        if not slot or not HasAction then return false end
        return HasAction(slot) and true or false
    end
    return hasAction(State.GetSecondarySlot(col)), hasAction(State.GetTertiarySlot(col))
end

local function EnsureChordList(chords, list)
    local seen = {}
    for i = 1, #chords do
        seen[chords[i]] = true
    end
    for i = 1, #list do
        local c = list[i]
        if c and c ~= "" and not seen[c] then
            seen[c] = true
            chords[#chords + 1] = c
        end
    end
    return chords
end

--- Describe a Flux action-bar slot: main|Shift|Ctrl · btn 1-19 · keybind (mouse icons).
--- Uses ChordMap (promotion-aware). Falls back to storage-row chord when scan is empty.
function Placement.DescribeBarSlot(slot)
    slot = tonumber(slot)
    if not slot then return nil end
    local CM = ChordMap()
    local loc = EnsureSlotLocate()[slot]
    local col = loc and loc.col or nil
    local storageRow = loc and loc.row or nil
    local chords = EffectiveChordsForSlot(slot)
    local primary = chords[1]
    local promoted = false
    local promotedMode = col and PromotedModeForColumn(col) or nil
    local hasSec, hasTert = ColumnMiniOccupancy(col)
    local soloColumn = col and ColumnActionCount(col) == 1

    -- Solo mini promotion: bare / Shift / Ctrl all fire this storage slot.
    if promotedMode == "sec" and storageRow == "secondary" and CM and CM.Normalize then
        local base = ColumnBaseKey(col)
        if base and base ~= "" then
            if soloColumn then
                -- Only spell in the column → treat as main (bare key).
                chords = EnsureChordList({}, { CM.Normalize(base) })
            else
                chords = EnsureChordList({}, {
                    CM.Normalize(base),
                    CM.Normalize("SHIFT-" .. base),
                    CM.Normalize("CTRL-" .. base),
                })
            end
            primary = chords[1]
            promoted = true
        end
    elseif promotedMode == "tert" and storageRow == "tertiary" and CM and CM.Normalize then
        local base = ColumnBaseKey(col)
        if base and base ~= "" then
            if soloColumn then
                chords = EnsureChordList({}, { CM.Normalize(base) })
            else
                chords = EnsureChordList({}, {
                    CM.Normalize(base),
                    CM.Normalize("SHIFT-" .. base),
                    CM.Normalize("CTRL-" .. base),
                })
            end
            primary = chords[1]
            promoted = true
        end
    elseif promotedMode == "both" and CM and CM.Normalize then
        -- both: bare → sec storage; Shift/Ctrl → tert storage (main remapped to sec).
        local base = ColumnBaseKey(col)
        if base and base ~= "" then
            if storageRow == "secondary" then
                chords = EnsureChordList({}, { CM.Normalize(base) })
                promoted = true
            elseif storageRow == "tertiary" then
                chords = EnsureChordList({}, {
                    CM.Normalize("SHIFT-" .. base),
                    CM.Normalize("CTRL-" .. base),
                })
                promoted = true
            end
            primary = chords[1]
        end
    elseif col and CM and CM.Normalize and not promotedMode then
        -- Normal column with only one mini filled: SmartLayout sends both Shift and Ctrl there.
        local base = ColumnBaseKey(col)
        if base and base ~= "" then
            if storageRow == "secondary" and hasSec and not hasTert then
                if soloColumn then
                    chords = EnsureChordList({}, { CM.Normalize(base) })
                else
                    chords = EnsureChordList(chords, {
                        CM.Normalize("SHIFT-" .. base),
                        CM.Normalize("CTRL-" .. base),
                    })
                end
            elseif storageRow == "tertiary" and hasTert and not hasSec then
                if soloColumn then
                    chords = EnsureChordList({}, { CM.Normalize(base) })
                else
                    chords = EnsureChordList(chords, {
                        CM.Normalize("SHIFT-" .. base),
                        CM.Normalize("CTRL-" .. base),
                    })
                end
            end
            primary = chords[1] or primary
        end
    end

    -- Do not invent chords when ChordMap finds none — that falsely claims keys
    -- like R for stance/page storage the live binding does not reach.

    -- Promoted: storage is mini, but bare column key also reaches this slot.
    if not promoted and storageRow and storageRow ~= "main" and col then
        local base = ColumnBaseKey(col)
        if base then
            local bare = CM and CM.Normalize and CM.Normalize(base)
            if bare then
                for i = 1, #chords do
                    if chords[i] == bare then
                        promoted = true
                        break
                    end
                end
            end
        end
    end

    local parts = {}
    parts[#parts + 1] = RowLabelFromChords(chords, storageRow, soloColumn)
    if col then
        parts[#parts + 1] = "btn " .. tostring(col)
    else
        parts[#parts + 1] = "btn ?"
    end
    local keyLabel = FormatChordsDisplay(chords)
    if keyLabel then
        parts[#parts + 1] = keyLabel
    end
    -- Solo column is just main — no "promoted" / Shift/Ctrl wording.
    if promoted and not soloColumn then
        parts[#parts + 1] = "promoted"
    end
    local label = table.concat(parts, " · ")

    local place = {
        source = "actionbar",
        slot = slot,
        col = col,
        row = soloColumn and "main" or storageRow,
        chord = primary or chords[1],
        chords = chords,
        promoted = promoted and not soloColumn,
        promotedMode = promotedMode,
        soloColumn = soloColumn and true or nil,
        label = label,
    }
    place.placeId = Placement.PlaceId(place)
    return place
end

function Placement.FormatBarSlots(slots)
    if type(slots) ~= "table" or #slots == 0 then return nil end
    local parts, seen = {}, {}
    local maxShow = 4
    for i = 1, #slots do
        local d = Placement.DescribeBarSlot(slots[i])
        local lab = d and d.label
        if lab and not seen[lab] then
            seen[lab] = true
            parts[#parts + 1] = lab
            if #parts >= maxShow then break end
        end
    end
    if #slots > maxShow then
        parts[#parts + 1] = "+" .. (#slots - maxShow)
    end
    if #parts == 0 then return nil end
    return table.concat(parts, " | ")
end

-- ---------------------------------------------------------------------------
-- ExtraButtonSystem placements
-- ---------------------------------------------------------------------------

local function NormalizeUtilityEntry(entry)
    if type(entry) ~= "table" then return nil end
    if entry.type and entry.id then
        return entry.type, entry.id, entry.name
    end
    if entry.spellID then
        return "spell", entry.spellID, entry.name
    end
    return nil
end

local function IndexUtilitySlots(map, utilitySnap)
    local slots
    if type(utilitySnap) == "table" and type(utilitySnap.slots) == "table" then
        slots = utilitySnap.slots
    elseif _G.FluxNCUtilitySlots and _G.FluxNCUtilitySlots.GetSlots then
        slots = _G.FluxNCUtilitySlots.GetSlots()
    end
    if type(slots) ~= "table" then return end
    local max = 4
    if _G.FluxNCUtilitySlots and _G.FluxNCUtilitySlots.GetMaxSlots then
        max = _G.FluxNCUtilitySlots.GetMaxSlots() or 4
    end

    local function EntryIcon(aType, id, name)
        if aType == "spell" and Action and Action.Spell and Action.GetIcon then
            return Action.GetIcon(Action.Spell(id))
        end
        if aType == "item" and Action and Action.Item and Action.GetIcon then
            return Action.GetIcon(Action.Item(id))
        end
        if aType == "macro" and Action and Action.Macro and Action.GetIcon then
            return Action.GetIcon(Action.Macro(name or id))
        end
        return nil
    end

    local function EntryDisplayName(aType, id, name)
        if name and name ~= "" then return name end
        if aType == "spell" and Action and Action.Spell and Action.GetName then
            return Action.GetName(Action.Spell(id))
        end
        if aType == "item" and Action and Action.Item and Action.GetName then
            return Action.GetName(Action.Item(id))
        end
        if aType == "macro" then
            return tostring(name or id)
        end
        return nil
    end

    for slotIndex = 1, max do
        local tierMap = slots[slotIndex]
        if type(tierMap) == "table" then
            local bindingName = "FLUXSPELLBOOKSLOT" .. slotIndex
            local keyRaw = FormatKeys(bindingName)
            local any = false
            local parentIcon, parentName

            -- Prefer nomod / mirror order for the main Utility button icon (live Extra look).
            local preferred
            if _G.FluxNCUtilitySlots and _G.FluxNCUtilitySlots.ResolveNomodEntry then
                preferred = select(1, _G.FluxNCUtilitySlots.ResolveNomodEntry(tierMap))
            end
            if type(preferred) == "table" then
                local pa, pid, pname = NormalizeUtilityEntry(preferred)
                if pa and pid then
                    parentIcon = EntryIcon(pa, pid, pname)
                    parentName = EntryDisplayName(pa, pid, pname)
                end
            end

            for modKey, entry in pairs(tierMap) do
                local aType, id, name = NormalizeUtilityEntry(entry)
                if aType and id then
                    any = true
                    local ak = ActionKeyFromTypeId(aType, id, name)
                    local mod = (modKey == nil or modKey == "") and "base" or tostring(modKey)
                    local chord = ChordWithMod(bindingName, modKey)
                    local keyLabel = DisplayChordWithMod(bindingName, modKey) or keyRaw
                    local modLab = (mod == "base" or mod == "") and "main" or mod
                    local label
                    if keyLabel then
                        label = string.format("Util %d %s · %s", slotIndex, modLab, keyLabel)
                    else
                        label = string.format("Util %d %s", slotIndex, modLab)
                    end
                    local dispName = EntryDisplayName(aType, id, name)
                    local icon = EntryIcon(aType, id, name)
                    if not parentIcon then
                        parentIcon = icon
                        parentName = dispName
                    end
                    PushPlace(map, ak, {
                        source = "utility",
                        slotIndex = slotIndex,
                        modKey = modKey,
                        binding = bindingName,
                        chord = chord or keyRaw,
                        label = label,
                        role = "utility_flyout",
                        favKey = tostring(aType) .. ":" .. tostring(id),
                        name = dispName,
                        icon = icon,
                    })
                end
            end

            -- Only list Utility buttons that actually have an assignment.
            if any then
                local nice = ("Utility %d"):format(slotIndex)
                local chord = FormatKeys(bindingName)
                local keyLabel = FormatKeysDisplayFull(bindingName) or FormatKeysDisplay(bindingName)
                local label = keyLabel and (nice .. " · " .. keyLabel) or nice
                PushPlace(map, "extra:utility" .. tostring(slotIndex), {
                    source = "utility",
                    slotIndex = slotIndex,
                    binding = bindingName,
                    chord = chord,
                    label = label,
                    role = "utility",
                    name = nice,
                    icon = parentIcon or 133622,
                    always = true,
                })
            end
        end
    end
end

local MOD_LABEL = {
    nomod = "main",
    shift = "Shift",
    ctrl = "Ctrl",
    alt = "Alt",
    ["ctrl+shift"] = "Ctrl+Shift",
    ["ctrl+alt"] = "Ctrl+Alt",
    ["shift+alt"] = "Shift+Alt",
    ["ctrl+shift+alt"] = "Ctrl+Shift+Alt",
}

local FLYOUT_MODS = {
    "nomod", "shift", "ctrl", "alt",
    "ctrl+shift", "ctrl+alt", "shift+alt", "ctrl+shift+alt",
}

local function ItemName(itemId)
    itemId = tonumber(itemId)
    if not itemId then return nil end
    if Action and Action.Item and Action.GetName then
        local n = Action.GetName(Action.Item(itemId))
        if n and n ~= "" and not n:find("^item:") then return n end
    end
    if GetItemInfo then
        local n = GetItemInfo(itemId)
        if n and n ~= "" then return n end
    end
    if C_Item and C_Item.GetItemNameByID then
        local n = C_Item.GetItemNameByID(itemId)
        if n and n ~= "" then return n end
    end
    return nil
end

local function ItemIcon(itemId)
    itemId = tonumber(itemId)
    if not itemId then return nil end
    if Action and Action.Item and Action.GetIcon then
        return Action.GetIcon(Action.Item(itemId))
    end
    if GetItemIcon then return GetItemIcon(itemId) end
    return nil
end

local function SpellName(spellIdOrName)
    if type(spellIdOrName) == "number" then
        if Action and Action.Spell and Action.GetName then
            local n = Action.GetName(Action.Spell(spellIdOrName))
            if n and n ~= "" and not n:find("^spell:") then return n end
        end
        if GetSpellInfo then
            local n = GetSpellInfo(spellIdOrName)
            if n and n ~= "" then return n end
        end
        return nil
    end
    if type(spellIdOrName) == "string" and spellIdOrName ~= "" then
        return spellIdOrName
    end
    return nil
end

local function ShortName(name, maxLen)
    if not name or name == "" then return nil end
    maxLen = maxLen or 22
    if #name <= maxLen then return name end
    return name:sub(1, maxLen - 1) .. "…"
end

--- Extra label: title · mod details · KEY (keys keep Shift/Ctrl/Alt prefixes).
local function ExtraRoleLabel(niceName, bindingName, modTag)
    local display = FormatKeysDisplayFull(bindingName)
    local parts = { niceName }
    if modTag and modTag ~= "" then
        parts[#parts + 1] = modTag
    end
    if display and display ~= "" then
        parts[#parts + 1] = display
    end
    return table.concat(parts, " · ")
end

local function PushExtraRole(map, role, bindingName, niceName, icon, opts)
    opts = type(opts) == "table" and opts or {}
    local ak = "extra:" .. tostring(role)
    local chord = FormatKeys(bindingName)
    local label = ExtraRoleLabel(niceName, bindingName, opts.modTag)
    PushPlace(map, ak, {
        source = "extra",
        binding = bindingName,
        chord = chord,
        label = label,
        role = opts.role or role,
        name = niceName,
        icon = icon,
        always = true,
        modTag = opts.modTag,
        placeholder = opts.placeholder and true or nil,
    })
    return ak
end

local function IsClassicEraClient()
    local api = _G.FLUX_API
    if api and api.isClassicEra then return true end
    if WOW_PROJECT_ID and WOW_PROJECT_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        return true
    end
    return false
end

local function IsFlyableNow()
    local Flux = _G.Flux
    local F = Flux and Flux.Inventory and Flux.Inventory.Flyable
    if not F then
        F = _G.FluxInv and _G.FluxInv.Spells
    end
    if F and F.PreferFlying then
        return F.PreferFlying()
    end
    if F and F.IsFlyableHere then
        return F.IsFlyableHere()
    end
    if IsFlyableArea and IsFlyableArea() then
        return true
    end
    return false
end

local function LooksLikeMountItem(itemId)
    itemId = tonumber(itemId)
    if not itemId then return false end
    local Spells = _G.FluxInv and _G.FluxInv.Spells
    if Spells and Spells.IsItemAMount then
        return Spells.IsItemAMount(itemId) and true or false
    end
    if _G.FluxItemDetection and _G.FluxItemDetection.IsItemAMount then
        return _G.FluxItemDetection.IsItemAMount(itemId) and true or false
    end
    if C_MountJournal and C_MountJournal.GetMountFromItem then
        return C_MountJournal.GetMountFromItem(itemId) ~= nil
    end
    return false
end

local function MountNameFromAnyFixed(v)
    if v == nil then return nil end
    if type(v) == "string" then return ShortName(v) end
    if type(v) == "number" then
        if LooksLikeMountItem(v) then return ShortName(ItemName(v)) end
        return ShortName(SpellName(v) or ItemName(v))
    end
    if type(v) == "table" then
        if v.name then return ShortName(v.name) end
        local iid = v.itemId or v.itemID
        if iid then return ShortName(ItemName(iid) or v.name) end
        if v.spellID then return ShortName(SpellName(v.spellID)) end
    end
    return nil
end

local function KnowsSwitchFlightStyle()
    local spellId = 404464
    if IsPlayerSpell and IsPlayerSpell(spellId) then return true end
    if IsSpellKnown and IsSpellKnown(spellId) then return true end
    if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
        return C_SpellBook.IsSpellInSpellBook(spellId) and true or false
    end
    return false
end

--- Mount mod tag with resolved names + flyable awareness.
--- Example: main(flyable:Swift Windsteed)/Shift(Brown Horse)/Ctrl(Yak)/Alt(Swift Windsteed)
local function MountDetailTag()
    local flyable = IsFlyableNow()
    local ground, flying, multi
    local Mount = _G.FluxNCMount
    if Mount and Mount.GetMountConfig then
        ground, flying, multi = Mount.GetMountConfig()
    end
    local CFG = _G.FluxSmartMountConfig
    if not ground and CFG and CFG.GetGroundMount then ground = CFG.GetGroundMount() end
    if not flying and CFG and CFG.GetFlyingMount then flying = CFG.GetFlyingMount() end
    if not multi and CFG and CFG.GetMultiMount then multi = CFG.GetMultiMount() end

    local gName = MountNameFromAnyFixed(ground)
    local fName = MountNameFromAnyFixed(flying)
    local mName = MountNameFromAnyFixed(multi)

    -- Bag-mount favorites (Classic / item mounts) fill gaps.
    local Items = _G.FluxNCMountItems
    if Items and Items.GetBestAvailableMount then
        if not gName then gName = MountNameFromAnyFixed(Items.GetBestAvailableMount("shift") or Items.GetBestAvailableMount("nomod")) end
        if not fName then fName = MountNameFromAnyFixed(Items.GetBestAvailableMount("alt")) end
        if not mName then mName = MountNameFromAnyFixed(Items.GetBestAvailableMount("ctrl")) end
        if not gName then gName = MountNameFromAnyFixed(Items.GetBestAvailableMount("nomod")) end
    end

    local mainName = flyable and (fName or gName) or (gName or fName)
    local main = flyable and "main(flyable" or "main(ground"
    if mainName then
        main = main .. ":" .. mainName .. ")"
    else
        main = main .. ")"
    end

    local parts = { main }
    parts[#parts + 1] = gName and ("Shift(" .. gName .. ")") or "Shift"
    parts[#parts + 1] = mName and ("Ctrl(" .. mName .. ")") or "Ctrl"
    if not IsClassicEraClient() then
        local altName = fName
        if KnowsSwitchFlightStyle() then
            altName = "Flight Style"
        end
        parts[#parts + 1] = altName and ("Alt(" .. altName .. ")") or "Alt"
    end
    return table.concat(parts, "/")
end

local function HearthDetailTag()
    local H = _G.FluxNCHearthstone
    if not H then return nil, "Hearthstone", 134414 end

    local hasTP = H.HasTeleportItems and H.HasTeleportItems()
    if not hasTP then
        local hid = H.GetHearthItemId and H.GetHearthItemId()
        local name = ItemName(hid) or "Hearthstone"
        local icon = ItemIcon(hid) or 134414
        return nil, name, icon
    end

    -- Teleport mode: list mod → item when known.
    local parts = {}
    local icon = 134414
    local mods = { "nomod", "shift", "ctrl", "alt" }
    for i = 1, #mods do
        local mk = mods[i]
        local it = H.GetBestTeleportItem and H.GetBestTeleportItem(mk)
        local lab = MOD_LABEL[mk] or mk
        if type(it) == "table" then
            local n = it.name or ItemName(it.itemId or it.itemID)
            if it.icon then icon = it.icon end
            if (it.itemId or it.itemID) and not icon then icon = ItemIcon(it.itemId or it.itemID) or icon end
            parts[#parts + 1] = n and (lab .. "(" .. ShortName(n) .. ")") or lab
        else
            parts[#parts + 1] = lab
        end
    end
    return table.concat(parts, "/"), "Best hearth / teleport", icon
end

local function ClassTeleportDetailTag()
    local TP = _G.FluxNCTeleportPortal
    if not TP or not TP.HasAnyTeleportOrPortalSpell or not TP.HasAnyTeleportOrPortalSpell() then
        return nil
    end
    local Fav = _G.FluxFlyoutFavorites
    local parts = {}
    local icon = 135826
    local mods = { "nomod", "shift", "ctrl", "alt" }
    local mode = "Teleport"
    if TP.GetMode then
        mode = TP.GetMode() or mode
    end
    -- Prefer favorites in active mode; fall back to Teleport then Portal.
    local function resolve(mk)
        if Fav and Fav.GetFavorite then
            local id = Fav.GetFavorite(mode, mk) or Fav.GetFavorite("Teleport", mk) or Fav.GetFavorite("Portal", mk)
            if id then return SpellName(id), id end
        end
        if mk == "nomod" then
            if TP.GetFirstKnownSpell then
                local sp = TP.GetFirstKnownSpell(mode) or TP.GetFirstKnownSpell("Teleport") or TP.GetFirstKnownSpell("Portal")
                if type(sp) == "table" then
                    return sp.name or SpellName(sp.spellID), sp.spellID
                elseif type(sp) == "number" or type(sp) == "string" then
                    return SpellName(sp), sp
                end
            end
        end
        return nil, nil
    end
    for i = 1, #mods do
        local mk = mods[i]
        local lab = MOD_LABEL[mk] or mk
        local n, id = resolve(mk)
        if id and Action and Action.Spell and Action.GetIcon then
            icon = Action.GetIcon(Action.Spell(tonumber(id) or id)) or icon
        end
        parts[#parts + 1] = n and (lab .. "(" .. ShortName(n) .. ")") or lab
    end
    return table.concat(parts, "/"), "Class teleport", icon
end

local function ResolveSpellId(spellIDOrName)
    if type(spellIDOrName) == "number" then
        return spellIDOrName > 0 and spellIDOrName or nil
    end
    if type(spellIDOrName) ~= "string" or spellIDOrName == "" then
        return nil
    end
    local asNum = tonumber(spellIDOrName)
    if asNum then return asNum end
    if C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
        local id = C_Spell.GetSpellIDForSpellIdentifier(spellIDOrName)
        if id and id > 0 then return id end
    end
    if GetSpellInfo then
        local _, _, _, _, _, _, spellID = GetSpellInfo(spellIDOrName)
        if spellID and spellID > 0 then return spellID end
    end
    if C_SpellBook and C_SpellBook.GetNumSpellBookItems and C_SpellBook.GetSpellBookItemInfo then
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
        local n = C_SpellBook.GetNumSpellBookItems(bank) or 0
        local want = spellIDOrName:lower()
        for i = 1, n do
            local info = C_SpellBook.GetSpellBookItemInfo(i, bank)
            if info and info.name and info.spellID and info.name:lower() == want then
                return info.spellID
            end
        end
    elseif GetNumSpellTabs and GetSpellBookItemName then
        local want = spellIDOrName:lower()
        local tabs = GetNumSpellTabs() or 0
        for t = 1, tabs do
            local _, _, offset, count = GetSpellTabInfo(t)
            for i = (offset or 0) + 1, (offset or 0) + (count or 0) do
                local name, _, id = GetSpellBookItemName(i, BOOKTYPE_SPELL or "spell")
                if name and name:lower() == want and id then
                    return id
                end
            end
        end
    end
    return nil
end

local function IndexSpellBinding(map, spellIDOrName, bindingName, source, niceName, role)
    local spellID = ResolveSpellId(spellIDOrName)
    if not spellID then return end
    local ak = ActionKeyFromTypeId("spell", spellID)
    local chord = FormatKeys(bindingName)
    local display = FormatKeysDisplayFull(bindingName) or FormatKeysDisplay(bindingName) or chord
    local label = display and (niceName .. " · " .. display) or niceName
    PushPlace(map, ak, {
        source = source,
        binding = bindingName,
        chord = chord,
        label = label,
        role = role or "conjure",
        spellID = spellID,
    })
end

--- Always-on Extra consumable buttons.
--- Empty → "Best food" role with the same placeholder icon as the Extra button (gray in list).
--- Owned → place on the real item so the list knows that button.
local function IndexConsumableButtons(map)
    local Bridge = _G.FluxEBSConsumableBridge

    -- Icons match ExtraButtonSystem placeholder textures (Food/Water/Bandage/… modules).
    local rows = {
        { "food",         "FLUXGRID_FOOD_OR_RECUP",     "Best food",           "Interface\\Icons\\INV_Misc_Fork&Knife",       "food",         "Food" },
        { "water",        "FLUXGRID_WATER_OR_COMBINED", "Best water",          "Interface\\Icons\\INV_Drink_07",              "water",        "Water" },
        { "bandage",      "FLUXCOMBAT_BANDAGE",         "Best bandage",        "Interface\\Icons\\INV_Misc_Bandage_01",       "bandage",      "Bandage" },
        { "healPotion",   "FLUXCOMBAT_HEALPOT",         "Best healing potion", "Interface\\Icons\\INV_Potion_54",             "healPotion",   "Healing potion" },
        { "manaPotion",   "FLUXCOMBAT_MANAPOT",         "Best mana potion",    "Interface\\Icons\\INV_Potion_76",             "manaPotion",   "Mana potion" },
        { "healthstone",  "FLUXCOMBAT_HEALTHSTONE",     "Best healthstone",    "Interface\\Icons\\INV_Stone_04",              "healthstone",  "Healthstone" },
        { "manaGem",      "FLUXCOMBAT_MANAGEM",         "Best mana gem",       "Interface\\Icons\\INV_Misc_Gem_Sapphire_02",  "managem",      "Mana gem" },
    }
    for i = 1, #rows do
        local role, binding, fallback, icon, kind, short =
            rows[i][1], rows[i][2], rows[i][3], rows[i][4], rows[i][5], rows[i][6]
        local owned = Bridge and Bridge.GetBestOwned and Bridge.GetBestOwned(kind)
        if type(owned) == "table" and owned.itemID then
            local ak = ActionKeyFromTypeId("item", owned.itemID)
            local chord = FormatKeys(binding)
            local display = FormatKeysDisplayFull(binding) or FormatKeysDisplay(binding)
            local label = display and (short .. " button · " .. display) or (short .. " button")
            PushPlace(map, ak, {
                source = "extra",
                binding = binding,
                chord = chord,
                label = label,
                role = "use",
                name = owned.name or ItemName(owned.itemID) or short,
                icon = owned.icon or ItemIcon(owned.itemID) or icon,
            })
        else
            PushExtraRole(map, role, binding, fallback, icon, {
                role = "use",
                placeholder = true,
            })
        end
    end

    if not Bridge then return end

    local foodConjure = Bridge.GetFoodConjureSpell and Bridge.GetFoodConjureSpell()
    if foodConjure then
        IndexSpellBinding(map, foodConjure, "FLUXMAGE_CONJURE_FOOD", "extra", "Food conjure", "conjure")
    end
    local foodSecondary = Bridge.GetFoodSecondaryConjureSpell and Bridge.GetFoodSecondaryConjureSpell()
    if foodSecondary then
        local isRitual = type(foodSecondary) == "string" and foodSecondary:lower():find("ritual", 1, true)
        if isRitual then
            IndexSpellBinding(map, foodSecondary, "FLUXMAGE_RITUAL_OF_REFRESHMENT", "extra", "Ritual", "ritual")
            local conjureKeys = FormatKeys("FLUXMAGE_CONJURE_FOOD")
            local conjureDisp = FormatKeysDisplayFull("FLUXMAGE_CONJURE_FOOD") or FormatKeysDisplay("FLUXMAGE_CONJURE_FOOD") or conjureKeys
            if conjureKeys then
                local sid = ResolveSpellId(foodSecondary)
                if sid then
                    PushPlace(map, ActionKeyFromTypeId("spell", sid), {
                        source = "extra",
                        binding = "FLUXMAGE_CONJURE_FOOD",
                        chord = "Shift+" .. conjureKeys,
                        label = "Ritual (Shift+RMB) · Shift+" .. conjureDisp,
                        role = "ritual_modifier",
                        spellID = sid,
                    })
                end
            end
        else
            IndexSpellBinding(map, foodSecondary, "FLUXMAGE_CONJURE_FOOD", "extra", "Food conjure (Shift)", "conjure")
        end
    end

    local waterConjure = Bridge.GetWaterConjureSpell and Bridge.GetWaterConjureSpell()
    if waterConjure then
        IndexSpellBinding(map, waterConjure, "FLUXMAGE_CONJURE_WATER", "extra", "Water conjure", "conjure")
    end
    local waterSecondary = Bridge.GetWaterSecondaryConjureSpell and Bridge.GetWaterSecondaryConjureSpell()
    if waterSecondary then
        local isRitual = type(waterSecondary) == "string" and waterSecondary:lower():find("ritual", 1, true)
        if isRitual then
            IndexSpellBinding(map, waterSecondary, "FLUXMAGE_RITUAL_OF_REFRESHMENT", "extra", "Ritual", "ritual")
            local conjureKeys = FormatKeys("FLUXMAGE_CONJURE_WATER")
            local conjureDisp = FormatKeysDisplayFull("FLUXMAGE_CONJURE_WATER") or FormatKeysDisplay("FLUXMAGE_CONJURE_WATER") or conjureKeys
            if conjureKeys then
                local sid = ResolveSpellId(waterSecondary)
                if sid then
                    PushPlace(map, ActionKeyFromTypeId("spell", sid), {
                        source = "extra",
                        binding = "FLUXMAGE_CONJURE_WATER",
                        chord = "Shift+" .. conjureKeys,
                        label = "Ritual (Shift+RMB) · Shift+" .. conjureDisp,
                        role = "ritual_modifier",
                        spellID = sid,
                    })
                end
            end
        else
            IndexSpellBinding(map, waterSecondary, "FLUXMAGE_CONJURE_WATER", "extra", "Water conjure (Shift)", "conjure")
        end
    end

    local mg = _G.FluxCombatManaGem
    local hs = _G.FluxCombatHealthstone
    local mageOwnsShared = mg and mg.KnowsAnyConjureSpell and mg.KnowsAnyConjureSpell()
    if mageOwnsShared then
        local spellID, spellName = nil, nil
        if Bridge.GetNextManaGemConjureSpell then
            spellID, spellName = Bridge.GetNextManaGemConjureSpell()
        end
        if not spellID and Bridge.GetPreferredCreateSpell then
            spellID, spellName = Bridge.GetPreferredCreateSpell("managem")
        end
        IndexSpellBinding(map, spellID or spellName, "FLUXMAGE_CONJURE_MANAGEM", "extra", "Mana gem conjure", "conjure")
    elseif hs and hs.CanCreateHealthstone and hs.CanCreateHealthstone() then
        local spellID, spellName = nil, nil
        if Bridge.GetPreferredCreateSpell then
            spellID, spellName = Bridge.GetPreferredCreateSpell("healthstone")
        end
        IndexSpellBinding(map, spellID or spellName, "FLUXMAGE_CONJURE_MANAGEM", "extra", "Healthstone create", "conjure")
    end
end

--- One place per mount (flyout favorite / config), with its mod + button keybind + flyable note.
--- modKeyOverride: optional display tag instead of main/Shift/Ctrl
---   ("bound when flying" / "bound when ground" → no live key, grayed like unbound).
local function PushMountPlace(map, ak, modKey, name, icon, flyNote, modKeyOverride)
    if not ak then return end
    local binding = "FLUXGRIDSMARTMOUNT"
    local zoneInactive = (modKeyOverride == "bound when flying")
        or (modKeyOverride == "bound when ground")
    local chord = zoneInactive and nil or ChordWithMod(binding, modKey)
    local keyDisp = zoneInactive and nil or DisplayChordWithMod(binding, modKey)
    local modLab = modKeyOverride
    if not modLab or modLab == "" then
        modLab = MOD_LABEL[modKey or "nomod"] or tostring(modKey or "main")
        if flyNote and flyNote ~= "" then
            modLab = modLab .. "(" .. flyNote .. ")"
        end
    end
    local parts = { "Mount", modLab }
    if keyDisp and not zoneInactive then
        parts[#parts + 1] = keyDisp
    end
    PushPlace(map, ak, {
        source = "extra",
        binding = binding,
        chord = chord,
        label = table.concat(parts, " · "),
        role = "mount_flyout",
        modKey = modKey or "nomod",
        favKey = ak,
        name = name,
        icon = icon or 132261,
        inactiveUntilFlying = zoneInactive and true or nil,
    })
end

local function MountActionKeyFromValue(v)
    if v == nil then return nil, nil, nil end
    if type(v) == "table" then
        local iid = tonumber(v.itemId or v.itemID)
        if iid then
            return ActionKeyFromTypeId("item", iid), v.name or ItemName(iid), v.icon or ItemIcon(iid)
        end
        local sid = tonumber(v.spellID or v.id)
        if sid then
            return ActionKeyFromTypeId("spell", sid), v.name or SpellName(sid), v.icon
        end
        if type(v.name) == "string" then
            local Coll = _G.FluxNCMountCollection
            if Coll and Coll.GetCollectedMountByName then
                local info = Coll.GetCollectedMountByName(v.name)
                if info and info.spellID then
                    return ActionKeyFromTypeId("spell", info.spellID), info.name or v.name, info.icon or v.icon
                end
            end
            local sid2 = ResolveSpellId(v.name)
            if sid2 then
                return ActionKeyFromTypeId("spell", sid2), v.name, v.icon
            end
        end
        return nil, v.name, v.icon
    end
    if type(v) == "number" then
        if LooksLikeMountItem(v) then
            return ActionKeyFromTypeId("item", v), ItemName(v), ItemIcon(v)
        end
        -- Prefer spell (journal mount spell id)
        local sn = SpellName(v)
        if sn then
            return ActionKeyFromTypeId("spell", v), sn, nil
        end
        return ActionKeyFromTypeId("item", v), ItemName(v), ItemIcon(v)
    end
    if type(v) == "string" then
        local Coll = _G.FluxNCMountCollection
        if Coll and Coll.GetCollectedMountByName then
            local info = Coll.GetCollectedMountByName(v)
            if info and info.spellID then
                return ActionKeyFromTypeId("spell", info.spellID), info.name or v, info.icon
            end
        end
        local sid = ResolveSpellId(v)
        if sid then
            return ActionKeyFromTypeId("spell", sid), v, nil
        end
    end
    return nil, nil, nil
end

local function IndexMount(map)
    local Items = _G.FluxNCMountItems
    local flyable = (Items and Items.IsFlyableHere and Items.IsFlyableHere())
        or IsFlyableNow()
    local any = false
    local pushed = {} -- dedupe key → true

    local function add(modKey, value, flyNote, modKeyOverride)
        local ak, name, icon = MountActionKeyFromValue(value)
        if not ak then return end
        local dedupe = ak .. "|" .. tostring(modKey) .. "|" .. tostring(flyNote or "") .. "|" .. tostring(modKeyOverride or "")
        if pushed[dedupe] then return end
        pushed[dedupe] = true
        PushMountPlace(map, ak, modKey, name, icon, flyNote, modKeyOverride)
        any = true
    end

    -- Bag favorites: same zone rules as Extra mount button (MountItems).
    if Items and Items.GetBindingFavoriteMounts then
        local rows, effective = Items.GetBindingFavoriteMounts()
        if type(rows) == "table" and #rows > 0 then
            local effAk = effective and select(1, MountActionKeyFromValue(effective))
            local effDisabled = effective and Items.IsTemporarilyDisabledMount
                and Items.IsTemporarilyDisabledMount(effective.itemId)

            -- Live nomod = Extra button cast only when that mount is a favorite.
            if effective and not effDisabled and effAk then
                local effIsFav = false
                for i = 1, #rows do
                    local rowAk = select(1, MountActionKeyFromValue(rows[i]))
                    if rowAk and rowAk == effAk then
                        effIsFav = true
                        break
                    end
                end
                if effIsFav then
                    add("nomod", effective, nil, "main")
                end
            end

            for i = 1, #rows do
                local row = rows[i]
                local rowAk = select(1, MountActionKeyFromValue(row))
                local isGround = not row.isFlying and not row.isAirOnly

                if row.temporarilyDisabled then
                    -- Air-only fav outside flyable zone: still listed, grayed like unbound.
                    add(row.modKey, row, nil, "bound when flying")
                elseif isGround then
                    -- Ground always works; label follows Mount.lua (main on ground, Shift in air).
                    if rowAk and effAk and rowAk == effAk and not effDisabled then
                        -- Already added as main · KEY.
                    elseif flyable then
                        -- Flyable zone: nomod is flying; ground is Shift (same as Mount.lua).
                        if row.modKey == "nomod" then
                            add("shift", row, "ground")
                        elseif row.modKey == "shift" then
                            add("shift", row, "ground")
                        else
                            local note = (row.modKey == "ctrl") and "multi" or nil
                            add(row.modKey, row, note)
                        end
                    else
                        -- Non-flyable: ground is the live main when assigned nomod / effective.
                        if row.modKey == "nomod" then
                            add("nomod", row, nil, "main")
                        elseif row.modKey == "shift" then
                            add("shift", row, "ground")
                        else
                            local note = (row.modKey == "ctrl") and "multi" or nil
                            add(row.modKey, row, note)
                        end
                    end
                else
                    -- Usable flying fav (in a flyable zone).
                    if row.modKey == "nomod" then
                        if not effAk or effAk ~= rowAk then
                            add("nomod", row, nil, "main")
                        end
                    else
                        local note
                        if row.modKey == "shift" then
                            note = "ground"
                        elseif row.modKey == "ctrl" then
                            note = "multi"
                        elseif row.modKey == "alt" then
                            note = KnowsSwitchFlightStyle() and "flight-style" or "fly"
                        end
                        add(row.modKey, row, note)
                    end
                end
            end
        end
    end

    -- Journal / smart-mount config only when there are no Mount flyout favorites.
    -- Configured Extra mounts stay under Extra; everything else stays unbound in Items/spellbook.
    if not any then
        local ground, flying, multi
        local Mount = _G.FluxNCMount
        if Mount and Mount.GetMountConfig then
            ground, flying, multi = Mount.GetMountConfig()
        end
        local CFG = _G.FluxSmartMountConfig
        if not ground and CFG and CFG.GetGroundMount then ground = CFG.GetGroundMount() end
        if not flying and CFG and CFG.GetFlyingMount then flying = CFG.GetFlyingMount() end
        if not multi and CFG and CFG.GetMultiMount then multi = CFG.GetMultiMount() end

        if multi then add("ctrl", multi, "multi") end

        -- Ground: main · KEY on ground zones; Shift(ground) · KEY in flyable zones (Mount.lua).
        if ground then
            if flyable then
                add("shift", ground, "ground")
            else
                add("nomod", ground, nil, "main")
                add("shift", ground, "ground")
            end
        end

        -- Flying: main · KEY when flyable; gray "bound when flying" otherwise.
        if flying then
            if flyable then
                add("nomod", flying, nil, "main")
                add("alt", flying, KnowsSwitchFlightStyle() and "flight-style" or "fly")
            else
                add("alt", flying, nil, "bound when flying")
                if not ground then
                    add("nomod", flying, nil, "bound when flying")
                end
            end
        elseif ground and flyable then
            -- No flying config: ground stays main even in flyable zones.
            add("nomod", ground, nil, "main")
        end
    end

    -- Main Extra mount button (flyout options nest under this in the Binding list).
    PushExtraRole(map, "mount", "FLUXGRIDSMARTMOUNT", "Mount", 132261, {
        role = "mount",
        modTag = MountDetailTag(),
    })

    local MountBtn = _G.FluxNCMount
    if MountBtn and MountBtn.HasAnyVendorMount and MountBtn.HasAnyVendorMount() then
        PushExtraRole(map, "vendorMount", "FLUXGRIDVENDORMOUNT", "Vendor mount", 132144, {
            role = "vendor_mount",
        })
    end
end

--- Each teleport / hearth item with FLUXGRIDHEARTH key.
--- Mod tags only when TeleportItem favorites are set (not hearthstone-only / no favs).
local function IndexHearth(map)
    local H = _G.FluxNCHearthstone
    local binding = "FLUXGRIDHEARTH"
    local keyDisp = FormatKeysDisplayFull(binding) or FormatKeysDisplay(binding)
    local chord = FormatKeys(binding)

    if not H or not H.HasTeleportItems or not H.HasTeleportItems() then
        local hid = H and H.GetHearthItemId and H.GetHearthItemId()
        if hid then
            local ak = ActionKeyFromTypeId("item", hid)
            local label = keyDisp and ("Hearthstone · " .. keyDisp) or "Hearthstone"
            PushPlace(map, ak, {
                source = "extra",
                binding = binding,
                chord = chord,
                label = label,
                role = "hearth",
                name = ItemName(hid) or "Hearthstone",
                icon = ItemIcon(hid) or 134414,
            })
        else
            PushExtraRole(map, "hearth", binding, "Hearthstone", 134414, { role = "hearth" })
        end
        return
    end

    local Fav = _G.FluxFlyoutFavorites
    -- itemId -> { name, icon, modKeys = { "nomod", "shift", ... } }
    local placed = {}

    local function remember(itemId, modKey, name, icon)
        itemId = tonumber(itemId)
        if not itemId then return end
        local e = placed[itemId]
        if not e then
            e = { modKeys = {}, name = name, icon = icon }
            placed[itemId] = e
        end
        if modKey and modKey ~= "" then
            local seen = false
            for i = 1, #e.modKeys do
                if e.modKeys[i] == modKey then seen = true break end
            end
            if not seen then
                e.modKeys[#e.modKeys + 1] = modKey
            end
        end
        if name and not e.name then e.name = name end
        if icon and not e.icon then e.icon = icon end
    end

    -- Favorites only — non-favorite teleports stay in Items as unbound.
    if Fav and Fav.GetFavorite then
        for i = 1, #FLYOUT_MODS do
            local mk = FLYOUT_MODS[i]
            local id = Fav.GetFavorite("TeleportItem", mk)
            if id then
                local it = H.GetBestTeleportItem and H.GetBestTeleportItem(mk)
                if type(it) == "table" and tonumber(it.itemId) == tonumber(id) then
                    remember(id, mk, it.name, it.icon)
                else
                    remember(id, mk, ItemName(id), ItemIcon(id))
                end
            end
        end
    end

    local any = false
    for itemId, e in pairs(placed) do
        local mods = e.modKeys
        if #mods > 0 then
            local ak = ActionKeyFromTypeId("item", itemId)
            for mi = 1, #mods do
                local mk = mods[mi]
                local c = ChordWithMod(binding, mk)
                local kd = DisplayChordWithMod(binding, mk)
                local parts = { "Hearth / teleport", MOD_LABEL[mk] or mk }
                if kd then parts[#parts + 1] = kd end
                PushPlace(map, ak, {
                    source = "extra",
                    binding = binding,
                    chord = c,
                    label = table.concat(parts, " · "),
                    role = "hearth_flyout",
                    modKey = mk,
                    favKey = "item:" .. tostring(itemId),
                    itemId = itemId,
                    name = e.name or ItemName(itemId),
                    icon = e.icon or ItemIcon(itemId) or 134414,
                })
            end
        end
    end

    -- Main Extra hearth button (teleport flyout options nest under this in Binding).
    PushExtraRole(map, "hearth", binding, "Best hearth / teleport", 134414, { role = "hearth" })
end

--- Toggle (only if both Teleport + Portal exist) + known spells on the Extra button.
--- No separate "Class teleport" Extra role row.
local function IndexClassTeleport(map)
    local TP = _G.FluxNCTeleportPortal
    if not TP or not TP.HasAnyTeleportOrPortalSpell or not TP.HasAnyTeleportOrPortalSpell() then
        return
    end

    local binding = "FLUXCLASS_TELEPORT"
    local toggleBind = "FLUXMAGE_TOGGLE_TPPT"
    local keyDisp = FormatKeysDisplayFull(binding) or FormatKeysDisplay(binding)
    local chord = FormatKeys(binding)

    -- Prefer the live Extra button icon (current nomod spell), else Stormwind teleport.
    local mainIcon = "Interface\\Icons\\Spell_Arcane_TeleportStormwind"
    if TP.GetSpellForModifier then
        local sp = TP.GetSpellForModifier("nomod")
        if type(sp) == "table" then
            mainIcon = sp.icon
                or (sp.spellID and (GetSpellTexture and GetSpellTexture(sp.spellID)))
                or mainIcon
        end
    end
    if (not mainIcon or mainIcon == "Interface\\Icons\\Spell_Arcane_TeleportStormwind")
        and TP.GetFirstKnownSpell then
        local mode = (TP.GetMode and TP.GetMode()) or "Teleport"
        local tip = TP.GetFirstKnownSpell(mode)
        if type(tip) == "table" and tip.icon then
            mainIcon = tip.icon
        elseif type(tip) == "number" and GetSpellTexture then
            mainIcon = GetSpellTexture(tip) or mainIcon
        end
    end

    -- Main Extra class-teleport button (spell flyout options nest under this in Binding).
    PushExtraRole(map, "classTeleport", binding, "Class teleport", mainIcon, {
        role = "class_teleport",
    })

    local hasTP = TP.HasAnyTeleportSpell and TP.HasAnyTeleportSpell()
    local hasPortal = TP.HasAnyPortalSpell and TP.HasAnyPortalSpell()
    if hasTP and hasPortal then
        local mode = (TP.GetMode and TP.GetMode()) or "Teleport"
        -- Icon/title = mode you switch TO (portal icon while in teleport mode, and vice versa).
        local targetMode = (mode == "Portal") and "Teleport" or "Portal"
        local tip = TP.GetFirstKnownSpell and TP.GetFirstKnownSpell(targetMode)
        local icon = mainIcon
        local title = (targetMode == "Portal") and "Switch to Portal" or "Switch to Teleport"
        if type(tip) == "table" then
            icon = tip.icon or icon
        elseif type(tip) == "number" and Action and Action.Spell and Action.GetIcon then
            icon = Action.GetIcon(Action.Spell(tip)) or icon
        end
        PushExtraRole(map, "classTeleportToggle", toggleBind, title, icon, {
            role = "class_teleport_toggle",
        })
    end

    local Fav = _G.FluxFlyoutFavorites
    local mode = (TP.GetMode and TP.GetMode()) or "Teleport"

    local function modsForSpell(spellID)
        local mods = {}
        if not Fav or not Fav.GetFavorite then return mods end
        for _, cat in ipairs({ mode, "Teleport", "Portal" }) do
            for i = 1, #FLYOUT_MODS do
                local mk = FLYOUT_MODS[i]
                local id = Fav.GetFavorite(cat, mk)
                if tonumber(id) == tonumber(spellID) then
                    local seen = false
                    for j = 1, #mods do
                        if mods[j] == mk then seen = true break end
                    end
                    if not seen then
                        mods[#mods + 1] = mk
                    end
                end
            end
        end
        return mods
    end

    local function pushSpell(sp, kind)
        if type(sp) ~= "table" then return end
        local sid = tonumber(sp.spellID or sp.id)
        if not sid then return end
        -- Favorites only — other teleports/portals stay in the spellbook as unbound.
        local mods = modsForSpell(sid)
        if #mods == 0 then return end
        local ak = ActionKeyFromTypeId("spell", sid)
        for mi = 1, #mods do
            local mk = mods[mi]
            local c = ChordWithMod(binding, mk)
            local kd = DisplayChordWithMod(binding, mk)
            local parts = { kind or "Teleport", MOD_LABEL[mk] or mk }
            if kd then parts[#parts + 1] = kd end
            PushPlace(map, ak, {
                source = "extra",
                binding = binding,
                chord = c,
                label = table.concat(parts, " · "),
                role = "class_teleport_spell",
                modKey = mk,
                favKey = "spell:" .. tostring(sid),
                spellID = sid,
                name = sp.name or SpellName(sid),
                icon = sp.icon,
            })
        end
    end

    if TP.GetKnownTeleportSpells then
        local list = TP.GetKnownTeleportSpells()
        if type(list) == "table" then
            for i = 1, #list do pushSpell(list[i], "Teleport") end
        end
    end
    if TP.GetKnownPortalSpells then
        local list = TP.GetKnownPortalSpells()
        if type(list) == "table" then
            for i = 1, #list do pushSpell(list[i], "Portal") end
        end
    end
end

--- Build actionKey → { placement, ... } for Extra buttons (+ optional utility snap).
--- @param opts { utilitySlots = profile.utilitySlots|nil }
function Placement.IndexExtra(opts)
    opts = type(opts) == "table" and opts or {}
    local map = {}
    IndexUtilitySlots(map, opts.utilitySlots)
    IndexConsumableButtons(map)
    IndexMount(map)
    IndexHearth(map)
    IndexClassTeleport(map)
    return map
end

--- Flux stance bar (Actionbars/Stance): visible slots → SHAPESHIFTBUTTON N keys.
--- Uses canonical→bind map so reorder/dedup matches live keybinds.
function Placement.IndexStance()
    local map = {}
    local bar = _G.FluxStanceBar
    if not bar or not bar.GetSlotOrderDescriptors then
        return map
    end
    local desc = bar:GetSlotOrderDescriptors()
    if type(desc) ~= "table" then
        return map
    end
    local bindMap = {}
    if bar.GetCanonicalToShapeshiftButtonBindingIndexMap then
        bindMap = bar:GetCanonicalToShapeshiftButtonBindingIndexMap() or {}
    end
    local Eng = ns.FluxBindingEngraving or _G.FluxBindingEngraving
    for i = 1, #desc do
        local row = desc[i]
        local canon = row and row.slotIndex
        local bindN = canon and bindMap[canon]
        local spellID = row and tonumber(row.spellID)
        if bindN and spellID and spellID > 0 then
            local bindingName = "SHAPESHIFTBUTTON" .. tostring(bindN)
            local chord = FormatKeys(bindingName)
            local keyDisp = FormatKeysDisplayFull(bindingName) or FormatKeysDisplay(bindingName)
            local parts = { "Stance", "btn " .. tostring(bindN) }
            if keyDisp then
                parts[#parts + 1] = keyDisp
            end
            -- SoD: store remapped learned spell id + display name (not rune-slot placeholder).
            local displayName = row.label
            local icon = row.texture
            if Eng and Eng.ResolveCastIdAndName then
                local castId, name = Eng.ResolveCastIdAndName(spellID, spellID, icon)
                if castId then
                    spellID = tonumber(castId) or spellID
                end
                if name and name ~= "" then
                    displayName = name
                end
            end
            local ak = ActionKeyFromTypeId("spell", spellID)
            if ak then
                PushPlace(map, ak, {
                    source = "stance",
                    binding = bindingName,
                    bindIndex = bindN,
                    slotIndex = canon,
                    button = "FluxStanceButton" .. tostring(canon),
                    spellID = spellID,
                    chord = chord,
                    label = table.concat(parts, " · "),
                    name = displayName,
                    icon = icon,
                })
            end
        end
    end
    return map
end

--- Spells/items/equip slots used as multi-cast extras on other bindings.
--- Effective key that fires a host binding (Flux key, placeId chord, or bar slot).
--- Must NOT call ChordForPlaceId / IndexMultiCast — hosts can themselves be mcast
--- instances, and that re-enters IndexMultiCast → stack overflow.
local function ResolveBindingDisplayChord(b)
    if type(b) ~= "table" then return nil end
    if b.key and b.key ~= "" then
        return b.key
    end
    local pid = b.placeId
    if type(pid) == "string" and pid ~= "" then
        local slot = tonumber(pid:match("^ab:(%d+)$"))
        if slot then
            local d = Placement.DescribeBarSlot(slot)
            if d and d.chord and d.chord ~= "" then
                return d.chord
            end
        end
        local stanceN = pid:match("^stance:(%d+)$")
        if stanceN then
            return FormatKeys("SHAPESHIFTBUTTON" .. stanceN)
        end
        local utilMain = pid:match("^util:(%d+)$")
        if utilMain then
            return FormatKeys("FLUXSPELLBOOKSLOT" .. utilMain)
        end
        local utilSlot, utilMod = pid:match("^util:(%d+):(.+)$")
        if utilSlot then
            local binding = "FLUXSPELLBOOKSLOT" .. utilSlot
            if utilMod == "base" or utilMod == "" then
                return FormatKeys(binding)
            end
            return ChordWithMod(binding, utilMod)
        end
        -- mcast:/inst:/extra: — do not recurse; fall through to bar scan.
    end
    local ak = b.action and Action
        and ((Action.FamilyKey and Action.FamilyKey(b.action)) or Action.Key(b.action))
    if not ak then return nil end
    local SlotHost = ns.FluxSlotHost
    if not (SlotHost and SlotHost.GetAllBarSlots and HasAction and GetActionInfo) then
        return nil
    end
    local preferSlot = type(pid) == "string" and tonumber(pid:match("^ab:(%d+)$"))
    local best
    for slot in pairs(SlotHost.GetAllBarSlots()) do
        slot = tonumber(slot) or slot
        if slot and HasAction(slot) then
            local actionType, id = GetActionInfo(slot)
            local desc
            if (actionType == "spell" or actionType == "companion") and id and Action.Spell then
                desc = Action.Spell(id)
            elseif actionType == "item" and id and Action.Item then
                desc = Action.Item(id)
            elseif actionType == "macro" and id and Action.Macro and GetMacroInfo then
                local name = GetMacroInfo(id)
                if name and name ~= "" then
                    desc = Action.Macro(name)
                end
            end
            local sak = desc and ((Action.FamilyKey and Action.FamilyKey(desc)) or Action.Key(desc))
            if sak == ak then
                local d = Placement.DescribeBarSlot(slot)
                local chord = d and d.chord
                if chord and chord ~= "" then
                    if preferSlot and tonumber(slot) == preferSlot then
                        return chord
                    end
                    if not best then
                        best = chord
                    end
                end
            end
        end
    end
    return best
end

--- actionKey → { placement, ... } with source "multicast".
--- Each place carries the host's effective chord so the list shows the keybind.
local indexingMultiCast = false
function Placement.IndexMultiCast()
    local map = {}
    if indexingMultiCast then
        return map
    end
    local DB = ns.FluxBindingDB3
    if not DB or not DB.All or not DB.GetMacroExtras then
        return map
    end
    indexingMultiCast = true
    local ok, err = pcall(function()
        local L = _G.FluxSpellBindingLocale
        local fmt = (L and L["multicast_place_fmt"]) or "Multi-cast · %s"
        local hostChordCache = {} -- uid -> chord|false
        for uid, b in pairs(DB.All()) do
            if type(b) == "table" and type(b.forms) == "table" and type(b.action) == "table" then
                local hostName = (Action and Action.GetName and Action.GetName(b.action)) or "?"
                local hostIcon = Action and Action.GetIcon and Action.GetIcon(b.action)
                local hostChord = hostChordCache[uid]
                if hostChord == nil then
                    hostChord = ResolveBindingDisplayChord(b) or false
                    hostChordCache[uid] = hostChord
                end
                if hostChord == false then
                    hostChord = nil
                end
                local keyDisp = hostChord and FormatChordDisplayFull(hostChord) or nil
                for formToken, sub in pairs(b.forms) do
                    local list = DB.GetMacroExtras(sub)
                    for i = 1, #list do
                        local e = list[i]
                        local action = DB.MacroExtraToAction and DB.MacroExtraToAction(e)
                        if type(action) == "table" and Action and Action.Key then
                            local ak = (Action.FamilyKey and Action.FamilyKey(action)) or Action.Key(action)
                            if ak then
                                local extraIcon = (DB.GetMacroExtraIcon and DB.GetMacroExtraIcon(e))
                                    or (Action.GetIcon and Action.GetIcon(action))
                                local extraName = (DB.GetMacroExtraLabel and DB.GetMacroExtraLabel(e))
                                    or (Action.GetName and Action.GetName(action))
                                local label = fmt:format(hostName)
                                if keyDisp then
                                    label = label .. " · " .. keyDisp
                                end
                                PushPlace(map, ak, {
                                    source = "multicast",
                                    role = "multicast_extra",
                                    hostUid = uid,
                                    hostAction = b.action,
                                    formToken = formToken or "noform",
                                    extraIndex = i,
                                    extraType = e.type,
                                    slotId = e.type == "slot" and e.id or nil,
                                    chord = hostChord,
                                    label = label,
                                    name = hostName,
                                    icon = hostIcon,
                                    extraName = extraName,
                                    extraIcon = extraIcon,
                                })
                            end
                        end
                    end
                end
            end
        end
    end)
    indexingMultiCast = false
    if not ok then
        geterrorhandler()(err)
    end
    return map
end

local function AppendPlacesFromIndex(places, ak, index)
    if not ak or type(index) ~= "table" or type(index[ak]) ~= "table" then
        return
    end
    for i = 1, #index[ak] do
        places[#places + 1] = index[ak][i]
    end
end

--- Merge bar slot descriptions + extra + stance + multi-cast placements for one catalog entry.
function Placement.CollectForEntry(entry, barSlots, extraIndex, stanceIndex, multiCastIndex)
    local places = {}
    if type(barSlots) == "table" then
        for i = 1, #barSlots do
            local d = Placement.DescribeBarSlot(barSlots[i])
            if d then places[#places + 1] = d end
        end
    end
    local ak = entry and entry.action and Action
        and ((Action.FamilyKey and Action.FamilyKey(entry.action)) or Action.Key(entry.action))
    AppendPlacesFromIndex(places, ak, extraIndex)
    AppendPlacesFromIndex(places, ak, stanceIndex)
    AppendPlacesFromIndex(places, ak, multiCastIndex)
    return places
end

function Placement.FormatPlaces(places)
    if type(places) ~= "table" or #places == 0 then return nil end
    local parts, seen = {}, {}
    local maxShow = 8
    for i = 1, #places do
        local lab = places[i].label or places[i].chord
        if lab and not seen[lab] then
            seen[lab] = true
            parts[#parts + 1] = lab
            if #parts >= maxShow then break end
        end
    end
    if #places > maxShow then
        parts[#parts + 1] = "+" .. (#places - maxShow)
    end
    return table.concat(parts, " | ")
end

function Placement.PrimaryChord(places)
    if type(places) ~= "table" then return nil end
    for i = 1, #places do
        local src = places[i].source
        if (src == "actionbar" or src == "stance") and places[i].chord and places[i].chord ~= "" then
            return places[i].chord
        end
    end
    for i = 1, #places do
        if places[i].chord and places[i].chord ~= "" then
            return places[i].chord
        end
    end
    return nil
end

--- Human-readable label for a placeId (dropdown / list hints).
function Placement.LabelForPlaceId(placeId, preferChord)
    if type(placeId) ~= "string" or placeId == "" then
        return nil
    end
    local slot = placeId:match("^ab:(%d+)$")
    if slot then
        local d = Placement.DescribeBarSlot(tonumber(slot))
        if d and d.label then
            return d.label
        end
        return "On action bar"
    end
    local stanceN = placeId:match("^stance:(%d+)$")
    if stanceN then
        local parts = { "Stance", "btn " .. stanceN }
        if preferChord and preferChord ~= "" then
            parts[#parts + 1] = tostring(preferChord)
        end
        return table.concat(parts, " · ")
    end
    if placeId:match("^stance:") then
        return "Stance"
    end
    if placeId:match("^util:") then
        return placeId:gsub("^util:", "Util ")
    end
    if placeId:match("^extra:") then
        return "Extra"
    end
    if placeId:match("^mcast:") then
        local map = Placement.IndexMultiCast and Placement.IndexMultiCast() or {}
        for _, places in pairs(map) do
            if type(places) == "table" then
                for i = 1, #places do
                    local p = places[i]
                    local pid = p.placeId or Placement.PlaceId(p)
                    if pid == placeId then
                        if preferChord and preferChord ~= "" then
                            return (p.label or "Multi-cast") .. " · " .. tostring(preferChord)
                        end
                        return p.label or "Multi-cast"
                    end
                end
            end
        end
        return "Multi-cast"
    end
    if placeId:match("^inst:") then
        return nil -- caller uses UNBOUND
    end
    return nil
end

--- Live chord for a placeId (updates when bars/bindings change).
function Placement.ChordForPlaceId(placeId)
    if type(placeId) ~= "string" or placeId == "" then
        return nil
    end
    local slot = placeId:match("^ab:(%d+)$")
    if slot then
        local d = Placement.DescribeBarSlot(tonumber(slot))
        return d and d.chord or nil
    end
    local stanceN = placeId:match("^stance:(%d+)$")
    if stanceN then
        return FormatKeys("SHAPESHIFTBUTTON" .. stanceN)
    end
    -- Main Utility button (no mod tier): util:1 .. util:4
    local utilMain = placeId:match("^util:(%d+)$")
    if utilMain then
        return FormatKeys("FLUXSPELLBOOKSLOT" .. utilMain)
    end
    local utilSlot, utilMod = placeId:match("^util:(%d+):(.+)$")
    if utilSlot then
        local binding = "FLUXSPELLBOOKSLOT" .. utilSlot
        if utilMod == "base" or utilMod == "" then
            return FormatKeys(binding)
        end
        return ChordWithMod(binding, utilMod)
    end
    if placeId:match("^util:") or placeId:match("^extra:") or placeId:match("^bind:") then
        local map = Placement.IndexExtra and Placement.IndexExtra() or {}
        for _, places in pairs(map) do
            if type(places) == "table" then
                for i = 1, #places do
                    local p = places[i]
                    local pid = p.placeId or Placement.PlaceId(p)
                    if pid == placeId and p.chord and p.chord ~= "" then
                        return p.chord
                    end
                end
            end
        end
    end
    if placeId:match("^mcast:") then
        local map = Placement.IndexMultiCast and Placement.IndexMultiCast() or {}
        for _, places in pairs(map) do
            if type(places) == "table" then
                for i = 1, #places do
                    local p = places[i]
                    local pid = p.placeId or Placement.PlaceId(p)
                    if pid == placeId and p.chord and p.chord ~= "" then
                        return p.chord
                    end
                end
            end
        end
    end
    return nil
end

local function PickupSpellCompat(id)
    if _G.ClearCursor then pcall(_G.ClearCursor) end
    if _G.C_Spell and _G.C_Spell.PickupSpell then
        pcall(_G.C_Spell.PickupSpell, id)
        if GetCursorInfo then
            local ct = GetCursorInfo()
            if ct == "spell" or ct == "petaction" or ct == "companion" then return true end
        else
            return true
        end
    end
    if _G.PickupSpell then
        pcall(_G.PickupSpell, id)
        if GetCursorInfo then
            local ct = GetCursorInfo()
            if ct == "spell" or ct == "petaction" or ct == "companion" then return true end
        else
            return true
        end
    end
    return false
end

local function PickupItemCompat(id)
    if _G.ClearCursor then pcall(_G.ClearCursor) end
    if _G.C_Item and _G.C_Item.PickupItem then
        pcall(_G.C_Item.PickupItem, id)
        if GetCursorInfo then
            local ct = GetCursorInfo()
            if ct == "item" then return true end
        else
            return true
        end
    end
    if _G.PickupItem then
        pcall(_G.PickupItem, id)
        if GetCursorInfo then
            local ct = GetCursorInfo()
            if ct == "item" then return true end
        else
            return true
        end
    end
    return false
end

--- Place a spell/item/macro onto an action-bar slot (combat-safe no-op).
--- Returns true only when the slot ends up occupied.
function Placement.PlaceActionOnSlot(slot, actionDesc)
    if not slot or type(actionDesc) ~= "table" then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    if HasAction and HasAction(slot) then return false end
    local t, id = actionDesc.type, actionDesc.id
    if t == "spell" and id then
        if not PickupSpellCompat(id) then return false end
    elseif t == "item" and id then
        if not PickupItemCompat(id) then return false end
    elseif t == "macro" and actionDesc.name and _G.PickupMacro then
        if not pcall(_G.PickupMacro, actionDesc.name) then return false end
    else
        return false
    end
    if _G.PlaceAction then
        pcall(_G.PlaceAction, slot)
    end
    if _G.ClearCursor then
        pcall(_G.ClearCursor)
    end
    if HasAction then
        return HasAction(slot) and true or false
    end
    return true
end

local function UtilModKeyFromChordMods(mods)
    if type(mods) ~= "table" then return "" end
    local parts = {}
    if mods.shift then parts[#parts + 1] = "SHIFT" end
    if mods.ctrl then parts[#parts + 1] = "CTRL" end
    if mods.alt then parts[#parts + 1] = "ALT" end
    if mods.meta then parts[#parts + 1] = "META" end
    local Assign = _G.FluxNCUtilitySlots
    local joined = table.concat(parts, "-")
    if Assign and Assign.NormalizeModKey then
        return Assign.NormalizeModKey(joined)
    end
    return joined
end

local function BareBaseKey(chord, CM)
    if not chord or chord == "" then return nil end
    if CM and CM.Parse then
        local base = CM.Parse(chord)
        if base and base ~= "" then return base end
    end
    local bare = tostring(chord)
        :gsub("^ALT%-", "")
        :gsub("^CTRL%-", "")
        :gsub("^SHIFT%-", "")
        :gsub("^META%-", "")
        :gsub("^ALT%-", "")
        :gsub("^CTRL%-", "")
        :gsub("^SHIFT%-", "")
        :gsub("^META%-", "")
    return bare
end

--- If `chord` routes to an empty Flux bar slot or empty Utility Extra mod tier,
--- place the action there.
--- @return table|nil { placeId, chord, kind = "actionbar"|"utility", ... }
function Placement.TryPlaceActionOnChord(actionDesc, chord)
    if type(actionDesc) ~= "table" or not chord or chord == "" then
        return nil
    end
    if InCombatLockdown and InCombatLockdown() then return nil end
    local CM = ChordMap()
    if not CM then return nil end
    local nk = CM.Normalize and CM.Normalize(chord) or chord
    local baseKey, mods = nil, {}
    if CM.Parse then
        baseKey, mods = CM.Parse(nk)
    end
    baseKey = baseKey or BareBaseKey(nk, CM)
    mods = type(mods) == "table" and mods or {}

    -- 1) Flux action bar (bare / Shift / Ctrl column keys).
    local bySlot, route = CM.SlotsForChord and CM.SlotsForChord(nk)
    local function tryBarSlot(slot, meta)
        if not slot or (HasAction and HasAction(slot)) then
            return nil
        end
        if Placement.PlaceActionOnSlot(slot, actionDesc) then
            return {
                kind = "actionbar",
                slot = slot,
                placeId = "ab:" .. tostring(slot),
                chord = nk,
                col = meta and meta.col,
                row = meta and meta.row,
            }
        end
        return nil
    end

    if route and route.kind == "slot" then
        local Forms = ns.FluxBindingForms
        local token = Forms and Forms.GetCurrentToken and Forms.GetCurrentToken() or "noform"
        local slot = route.slotsByForm and route.slotsByForm[token]
        if not slot and route.slotsByForm then
            for _, s in pairs(route.slotsByForm) do
                if s and (not HasAction or not HasAction(s)) then
                    slot = s
                    break
                end
                if not slot then slot = s end
            end
        end
        local placed = tryBarSlot(slot, route)
        if placed then return placed end
    end

    -- Fallback: any empty bar slot whose live chord list includes this key
    -- (covers promotion / form-page edge cases ChordMap missed).
    do
        local State = ns.FluxActionBarState or _G.FluxActionBarState
        local Forms = ns.FluxBindingForms
        local cols = (CM.TOTAL_COLUMNS) or 19
        local token = Forms and Forms.GetCurrentToken and Forms.GetCurrentToken() or "noform"
        local page = Forms and Forms.PageForToken and Forms.PageForToken(token) or 1
        if State and State.GetMainSlot and State.GetSecondarySlot and State.GetTertiarySlot then
            for col = 1, cols do
                local mainState = col > 12 and 0 or page
                local candidates = {
                    { State.GetMainSlot(col, mainState), "main" },
                    { State.GetSecondarySlot(col), "secondary" },
                    { State.GetTertiarySlot(col), "tertiary" },
                }
                for ci = 1, #candidates do
                    local slot, row = candidates[ci][1], candidates[ci][2]
                    if slot and (not HasAction or not HasAction(slot)) then
                        local d = Placement.DescribeBarSlot(slot)
                        local hit = false
                        if d then
                            if d.chord and (CM.Normalize and CM.Normalize(d.chord) or d.chord) == nk then
                                hit = true
                            elseif type(d.chords) == "table" then
                                for _, c in ipairs(d.chords) do
                                    if c and (CM.Normalize and CM.Normalize(c) or c) == nk then
                                        hit = true
                                        break
                                    end
                                end
                            end
                        end
                        if hit then
                            local placed = tryBarSlot(slot, { col = col, row = row })
                            if placed then return placed end
                        end
                    end
                end
            end
        end
    end

    -- 2) Utility Extra: base key matches FLUXSPELLBOOKSLOTn; place into that mod tier.
    local Assign = _G.FluxNCUtilitySlots
    if Assign and Assign.Assign and Assign.GetSlots and baseKey and baseKey ~= "" then
        local slots = Assign.GetSlots()
        local maxSlots = (Assign.GetMaxSlots and Assign.GetMaxSlots()) or 4
        local utilMod = UtilModKeyFromChordMods(mods) -- "" = nomod
        local baseNorm = CM.Normalize and CM.Normalize(baseKey) or baseKey
        for i = 1, maxSlots do
            local bindingName = "FLUXSPELLBOOKSLOT" .. tostring(i)
            local k1, k2 = GetBindingKey(bindingName)
            local matched = false
            for _, k in ipairs({ k1, k2 }) do
                if k and k ~= "" then
                    local kn = CM.Normalize and CM.Normalize(k) or k
                    local kb = BareBaseKey(kn, CM)
                    local kbNorm = kb and (CM.Normalize and CM.Normalize(kb) or kb)
                    if kn == baseNorm or kbNorm == baseNorm or kn == nk then
                        matched = true
                        break
                    end
                end
            end
            if matched then
                local slotData = slots and slots[i]
                local ent = type(slotData) == "table" and slotData[utilMod] or nil
                local empty = not (type(ent) == "table" and ent.type and ent.id ~= nil)
                if empty then
                    local entry = {
                        type = actionDesc.type,
                        id = actionDesc.id,
                        name = actionDesc.name,
                    }
                    if Assign.Assign(i, entry, utilMod) then
                        local mode = (utilMod == nil or utilMod == "") and "base" or tostring(utilMod)
                        return {
                            kind = "utility",
                            slotIndex = i,
                            modKey = utilMod,
                            placeId = "util:" .. tostring(i) .. ":" .. mode,
                            chord = nk,
                            binding = bindingName,
                        }
                    end
                end
            end
        end
    end

    return nil
end

-- Invalidate geometry when bindings change.
local w = CreateFrame("Frame")
w:RegisterEvent("UPDATE_BINDINGS")
w:RegisterEvent("PLAYER_ENTERING_WORLD")
w:SetScript("OnEvent", InvalidateSlotLocate)

_G.FluxBindingPlacement = Placement
