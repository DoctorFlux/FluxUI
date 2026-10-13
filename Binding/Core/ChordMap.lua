-- Binding/Core/ChordMap.lua
-- Chord normalization + chord -> Flux bar routing.
--
-- A chord is a Blizzard binding string ("1", "SHIFT-1", "ALT-Q", "BUTTON4").
-- Chords whose BASE key is bound to a Flux column command route to that
-- column's MAIN button (the physical key always clicks the main button):
--   bare        -> the column's current main page slot (form-dependent)
--   SHIFT-      -> the column's secondary (SHIFT mini) slot
--   CTRL-       -> the column's tertiary (CTRL mini) slot
--   ALT- / SHIFT+CTRL / unbound base key -> FREE chord (secure pool override)
--
-- Slot resolution reads the LIVE LAB state tables via the buttons themselves
-- (ns.FluxActionBarState math as fallback) so promoted-mode remaps are honored.

local addonName, ns = ...

local ChordMap = {}
ns.FluxBindingChordMap = ChordMap
_G.FluxBindingChordMap3 = ChordMap

local Flux = ns.Flux or _G.Flux
local Hosts = Flux and Flux.Bars and Flux.Bars.Hosts
local COLUMN_BINDING_NAME = {}
for i = 1, 12 do
    COLUMN_BINDING_NAME[i] = "ACTIONBUTTON" .. i
end
if Hosts and Hosts.BindingCommand then
    for i = 13, 19 do
        COLUMN_BINDING_NAME[i] = Hosts.BindingCommand(i)
    end
end

ChordMap.TOTAL_COLUMNS = 19
ChordMap.COLUMN_BINDING_NAME = COLUMN_BINDING_NAME

-- ---------------------------------------------------------------------------
-- Chord parsing / normalization
-- ---------------------------------------------------------------------------

function ChordMap.Parse(chord)
    local mods = { shift = false, ctrl = false, alt = false, meta = false }
    if type(chord) ~= "string" or chord == "" then
        return "", mods
    end
    local parts = {}
    for piece in string.gmatch(chord, "[^%-]+") do
        parts[#parts + 1] = piece
    end
    if #parts == 0 then return "", mods end
    local baseKey = string.upper(parts[#parts])
    for i = 1, #parts - 1 do
        local m = string.upper(parts[i])
        if m == "SHIFT" then mods.shift = true
        elseif m == "CTRL" then mods.ctrl = true
        elseif m == "ALT" then mods.alt = true
        elseif m == "META" or m == "CMD" then mods.meta = true
        end
    end
    return baseKey, mods
end

--- Canonical "ALT-CTRL-SHIFT-META-KEY" (Blizzard modifier order), uppercase.
function ChordMap.Normalize(chord)
    local baseKey, mods = ChordMap.Parse(chord)
    if baseKey == "" then return "" end
    local out = ""
    if mods.alt then out = out .. "ALT-" end
    if mods.ctrl then out = out .. "CTRL-" end
    if mods.shift then out = out .. "SHIFT-" end
    if mods.meta then out = out .. "META-" end
    return out .. baseKey
end

function ChordMap.IsMouseChord(chord)
    local baseKey = ChordMap.Parse(chord)
    return baseKey:match("^BUTTON%d+$") ~= nil
        or baseKey == "MOUSEWHEELUP" or baseKey == "MOUSEWHEELDOWN"
end

-- ---------------------------------------------------------------------------
-- Base-key -> column cache (rebuilt on UPDATE_BINDINGS)
-- ---------------------------------------------------------------------------

local baseKeyToColumn = nil

local function BuildCache()
    baseKeyToColumn = {}
    for col = 1, ChordMap.TOTAL_COLUMNS do
        local bindingName = COLUMN_BINDING_NAME[col]
        for k = 1, select("#", GetBindingKey(bindingName)) do
            local key = select(k, GetBindingKey(bindingName))
            if key and key ~= "" then
                local baseKey = ChordMap.Parse(key)
                if baseKey ~= "" and not baseKeyToColumn[baseKey] then
                    baseKeyToColumn[baseKey] = col
                end
            end
        end
    end
end

local function EnsureCache()
    if not baseKeyToColumn then BuildCache() end
end

function ChordMap.Invalidate()
    baseKeyToColumn = nil
end

function ChordMap.FindColumnForChord(chord)
    EnsureCache()
    local baseKey = ChordMap.Parse(chord)
    if baseKey == "" then return nil end
    return baseKeyToColumn[baseKey]
end

-- ---------------------------------------------------------------------------
-- Routing
-- ---------------------------------------------------------------------------

--- How a chord routes:
---   { kind = "free" }                                        -- pool override
---   { kind = "slot", col, row, slotsByForm = {token->slot} } -- Flux bar
--- Bar routing carries per-form slots because the main row pages with forms.
function ChordMap.Route(chord)
    EnsureCache()
    local baseKey, mods = ChordMap.Parse(chord)
    if baseKey == "" then return nil end
    if mods.alt or mods.meta or (mods.shift and mods.ctrl) then
        return { kind = "free" }
    end
    local col = baseKeyToColumn[baseKey]
    if not col then
        return { kind = "free" }
    end

    local Flux = ns.Flux
    local Forms = ns.FluxBindingForms
    local State = ns.FluxActionBarState or (Flux and Flux.Bars and Flux.Bars.State)
    local SlotMath = Flux and Flux.Bars and Flux.Bars.SlotMath
    local rec = Flux and Flux.Bars and Flux.Bars.GetHost and Flux.Bars.GetHost(col)
    local mainWidget = rec and rec.main and rec.main.widget
    local opts = {}
    if mainWidget and mainWidget.GetAttribute then
        opts.promoted = tonumber(mainWidget:GetAttribute("flux-promoted")) or 0
        opts.hasSec = (tonumber(mainWidget:GetAttribute("flux-has-sec")) or 0) == 1
        opts.hasTert = (tonumber(mainWidget:GetAttribute("flux-has-tert")) or 0) == 1
    end

    local swap = 0
    local row
    if mods.shift then
        swap = 1
        row = "secondary"
    elseif mods.ctrl then
        swap = 2
        row = "tertiary"
    else
        row = "main"
    end

    local slotsByForm = {}
    local tokens = Forms and Forms.GetTokens() or { "noform" }
    for _, token in ipairs(tokens) do
        local page = Forms and Forms.PageForToken(token) or 1
        local slot
        if SlotMath and SlotMath.Resolve then
            slot = SlotMath.Resolve(col, "main", page, swap, opts)
        elseif State then
            if swap == 1 then
                slot = State.GetSecondarySlot(col)
            elseif swap == 2 then
                slot = State.GetTertiarySlot(col)
            else
                slot = State.GetMainSlot(col, col > 12 and 0 or page)
            end
        end
        if slot then
            slotsByForm[token] = slot
        end
    end

    return { kind = "slot", col = col, row = row, slotsByForm = slotsByForm }
end

--- All slots a chord can reach across forms (set slot -> { formToken, ... }).
--- Token lists follow Forms.GetTokens() order (deterministic macro output).
function ChordMap.SlotsForChord(chord)
    local route = ChordMap.Route(chord)
    if not route or route.kind ~= "slot" then return nil, route end
    local Forms = ns.FluxBindingForms
    local bySlot = {}
    local tokens = Forms and Forms.GetTokens() or { "noform" }
    for _, token in ipairs(tokens) do
        local slot = route.slotsByForm[token]
        if slot then
            local list = bySlot[slot]
            if not list then
                list = {}
                bySlot[slot] = list
            end
            list[#list + 1] = token
        end
    end
    return bySlot, route
end

-- ---------------------------------------------------------------------------
-- Cache invalidation
-- ---------------------------------------------------------------------------

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("UPDATE_BINDINGS")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:SetScript("OnEvent", function()
    baseKeyToColumn = nil
end)
