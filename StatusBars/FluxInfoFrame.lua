--[[
    StatusBars/FluxInfoFrame.lua
    Info frame displaying durability, FPS, ping, and pinned character stats
    
    Features:
    - Dynamically positioned between CombatGrid and NonCombatGrid
    - FluxBorder styling (class-colored border and backdrop)
    - FPS, durability, and ping display with color coding (individually toggleable)
    - Click-to-pin character stats from PaperDollFrame (retail) or CSC panel (classic)
    - Per-character settings via _FluxUI_CharSavedVars.infoFrame
    - Dynamic line count: frame auto-sizes to fit active lines
    - Vertical text stack (HUD) or horizontal strip (integrated), centered horizontally where needed
]]

FluxInfoFrame = FluxInfoFrame or {}
local InfoFrame = FluxInfoFrame

-- Flux perf: hot-path global upvalues (hit on every layout / OnSizeChanged
-- cascade). Avoids repeated global table lookups inside debounced callbacks.
local _GetTime = GetTime
local _C_Timer = C_Timer
local _InCombatLockdown = InCombatLockdown
local _CreateFrame = CreateFrame

-- Local references
local frame = nil
local durabilityText = nil
local durabilityTooltipFrame = nil
local fpsText = nil
local pingText = nil
local UPDATE_INTERVAL = 1.0 -- Update every 1 second (handled by C_Timer ticker below)
local TEXT_SPACING = 18 -- Legacy fallback; prefer INFO_FRAME_GROUP_* for Info layout rhythm.
local FRAME_HEIGHT = 80 -- Default height for multi-line vertical layout
--- Horizontal merged-segment gap (action strip / minimap at full size).
local INFO_FRAME_GROUP_GAP = 8
local INFO_FRAME_GROUP_GAP_COMPACT = 6 -- minimap floating / smaller strip font
--- Vertical HUD: tighter row + wrapped-line spacing (FontString SetSpacing + row stride).
local INFO_FRAME_VERTICAL_LINE_GAP = 2
--- Left inset for vertical merged layout (scroll + non-scroll paths stay identical).
local INFO_FRAME_TEXT_PAD_X = 6
--- Vertical HUD: merge down to at most this many rows before scroll.
local VERTICAL_MAX_MERGED_ROWS = 6
local VERTICAL_MIN_LINE_GAP = 4
--- Minimum font when squeezing: ~80% of base (never truncate stat names — wrap/scroll instead).
local VERTICAL_FONT_BASE = 11
local VERTICAL_FONT_MIN = 7
local VERTICAL_FONT_SCALE_STEP = 0.02

local function GetDynamicVerticalHeight()
    local n = tonumber(activeLineCount) or 0
    if n <= 0 then return FRAME_HEIGHT end
    return math.max(FRAME_HEIGHT, n * INFO_FRAME_VERTICAL_LINE_GAP + 16)
end
local INFO_TOPLEFT_X = 2
local INFO_TOPLEFT_Y = 0
local STRIP_FONT_SIZE = 10 -- Matches compact status strip text vs GameFontNormalSmall on bars
--- Minimap-interior FPS strip when the map is docked normally (narrower rim band than embedded window).
local MINIMAP_TOP_FLOAT_FONT_SIZE = 9.5
--- Secondary strip row (item level + GearScore): keep same size as primary row (was 2 pt smaller).
local ILVL_GS_SECONDARY_FONT_SHRINK = 0
local stripVisualActive = false
local minimapTopVisualActive = false

--- Cached width for integrated strip (worst-case strings); never resized when live numbers change.
local cachedStableIntegratedClusterWidth = nil

-- Flux perf: re-entry guard. FluxStatusBar.UpdateLayout calls SetSize on
-- FluxStatusBarContainer while we are mid-layout, which re-fires
-- OnSizeChanged -> FluxInfoFrame.UpdatePosition and pointlessly re-runs
-- LayoutIntegrated. The guard is set inside LayoutIntegrated /
-- PrepareIntegratedStripLayout and cleared on the next frame via C_Timer.After(0).
local _inIntegratedLayout = false

-- Flux perf: hash-guard for LayoutIntegrated. Skip SetWidth/SetHeight/SetPoint
-- churn when placement parameters haven't changed since last pass. Invalidated
-- by ForceUpdatePosition and when placement leaves statusIntegrated.
local _lastIntegratedKey = nil
local _lastPrepareStripKey = nil

-- Flux perf: CalculateMinimalWidth worst-case cache. Text fonts only change on
-- placement toggles, so computing worst-case widths on every action-strip
-- layout pass was pure waste. Invalidated in ForceUpdatePosition and when
-- strip/minimap visuals toggle.
local _cachedActionStripMinimalWidth = nil

-- Forward decl: defined later near the positionWatcher. Called from
-- UpdatePositionImmediate / ForceUpdatePosition so placement-driven attach /
-- detach of the 2s poll can co-locate with layout placement resolution.
local _SyncPositionWatcher = function() end

-- Forward decl: defined later alongside the stats ticker. Invoked from
-- CreateInfoFrame (which runs lazily, after this file has finished loading)
-- to install OnShow/OnHide hooks that start/stop the 1s stats ticker.
local _InstallInfoFrameTickerHooks = function() end
local _BindInfoFrameEntryTooltip = function() end
local _ClearInfoFrameEntryTooltip = function() end

-- ============================================================================
-- PER-CHARACTER STORAGE (_FluxUI_CharSavedVars.infoFrame)
-- ============================================================================

local function GetInfoFrameCharDB()
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    if not _FluxUI_CharSavedVars.infoFrame then
        _FluxUI_CharSavedVars.infoFrame = {
            showFPS = true,
            showDurability = false,
            showPing = true,
            pinnedStats = {},
            spellDisplayMode = "off", -- off | sp | heal | both
        }
    end
    local db = _FluxUI_CharSavedVars.infoFrame
    if db.showFPS == nil then db.showFPS = true end
    if db.showPing == nil then db.showPing = true end
    if not db._fluxDurabilityDefaultOff then
        db._fluxDurabilityDefaultOff = true
        db.showDurability = false
    end
    if db.showDurability == nil then db.showDurability = false end
    if not db.pinnedStats then db.pinnedStats = {} end
    if db.spellDisplayMode == nil then
        local hasSp = db.pinnedStats["spellPower"] and true or false
        local hasHeal = db.pinnedStats["healPower"] and true or false
        if hasSp and hasHeal then
            db.spellDisplayMode = "both"
        elseif hasHeal then
            db.spellDisplayMode = "heal"
        elseif hasSp then
            db.spellDisplayMode = "sp"
        else
            db.spellDisplayMode = "off"
        end
    end
    if db.spellDisplayMode ~= "off" and db.spellDisplayMode ~= "sp" and db.spellDisplayMode ~= "heal" and db.spellDisplayMode ~= "both" then
        db.spellDisplayMode = "off"
    end
    InfoFrame._FoldCamelotCombatPins(db)
    return db
end

function InfoFrame.GetCharDB()
    return GetInfoFrameCharDB()
end

--- Plain table for FluxRespec profile snapshots (SavedVariables-safe).
function InfoFrame.SerializeRespecProfileSnapshot()
    local db = GetInfoFrameCharDB()
    local pins = {}
    for k, v in pairs(db.pinnedStats or {}) do
        if v then
            pins[k] = true
        end
    end
    local order = {}
    if type(db.statOrder) == "table" then
        for _, k in ipairs(db.statOrder) do
            if type(k) == "string" then
                order[#order + 1] = k
            end
        end
    end
    return {
        showFPS = not not db.showFPS,
        showDurability = not not db.showDurability,
        showPing = not not db.showPing,
        spellDisplayMode = db.spellDisplayMode or "off",
        pinnedStats = pins,
        statOrder = order,
    }
end

-- ============================================================================
-- STAT REGISTRY (retail + classic providers)
-- ============================================================================

local STAT_REGISTRY = {}

local function _SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, ...)
    if ok then return v end
    return nil
end

function InfoFrame._IsCamelotClient()
    local client = _G.Flux and _G.Flux.Client
    if client and client.isCamelot ~= nil then
        return client.isCamelot == true
    end
    if WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
        return true
    end
    local api = rawget(_G, "FLUX_API")
    return api and (api.isCamelot or api.isForever) and true or false
end

-- Forever shares these stats across melee, ranged, and spells. Keep the
-- existing registry keys so saved pins and Respec snapshots remain compatible.
do
    local aliases = {
        meleeCrit = "crit", rangedCrit = "crit", spellCrit = "crit",
        critical_strike = "crit", melee_crit = "crit", ranged_crit = "crit", spell_crit = "crit",
        meleeHit = "meleeHit", rangedHit = "meleeHit", spellHit = "meleeHit",
        hit = "meleeHit", hit_chance = "meleeHit",
        melee_hit = "meleeHit", ranged_hit = "meleeHit", spell_hit = "meleeHit",
        meleeHaste = "haste", rangedHaste = "haste", spellHaste = "haste",
        melee_haste = "haste", ranged_haste = "haste", spell_haste = "haste",
    }

    function InfoFrame._CamelotCombatStatKey(key)
        if InfoFrame._IsCamelotClient() then
            return aliases[key] or key
        end
        return key
    end

    function InfoFrame._FoldCamelotCombatPins(db)
        if not InfoFrame._IsCamelotClient() then return end
        local pins = db.pinnedStats
        for alias, key in pairs(aliases) do
            if alias ~= key and pins[alias] ~= nil then
                if pins[alias] then pins[key] = true end
                pins[alias] = nil
            end
        end
        local migrateOrder = false
        for _, key in ipairs(type(db.statOrder) == "table" and db.statOrder or {}) do
            if aliases[key] and aliases[key] ~= key then
                migrateOrder = true
                break
            end
        end
        if migrateOrder then
            local order, seen = {}, {}
            for _, key in ipairs(db.statOrder) do
                key = aliases[key] or key
                if not seen[key] then
                    seen[key] = true
                    order[#order + 1] = key
                end
            end
            db.statOrder = order
        end
    end
end

-- Match Camelot's PaperDollFrameStats.lua without calling native row setters
-- (those run in the protected character-window show path).
function InfoFrame._CamelotCombatStatValue(key)
    local restricted = false
    local function plain(value)
        if issecretvalue and issecretvalue(value) then
            restricted = true
            return nil
        end
        if type(value) == "number" then return value end
    end
    local function number(fn, ...)
        if type(fn) ~= "function" then return nil end
        local ok, value = pcall(fn, ...)
        if not ok then
            restricted = true
            return nil
        end
        local result = plain(value)
        if result == nil then restricted = true end
        return result
    end
    local best
    local function include(value)
        if value ~= nil then
            best = best and math.max(best, value) or value
        end
    end
    if key == "crit" then
        include(number(GetCritChance))
        include(number(GetRangedCritChance))
        include(number(GetSpellCritChance))
    elseif key == "haste" then
        include(number(GetMeleeHaste))
        include(number(UnitSpellHaste, "player"))
        if type(GetRangedHaste) == "function" then
            local ok, base, ammo = pcall(GetRangedHaste)
            if ok then
                base, ammo = plain(base), plain(ammo)
                if base ~= nil then include(base + (ammo or 0)) end
            else
                restricted = true
            end
        end
        if best == nil then include(number(GetHaste)) end
    elseif key == "meleeHit" then
        local function hit(ratingIndex, modifier)
            local rating = type(ratingIndex) == "number" and number(GetCombatRatingBonus, ratingIndex) or nil
            local mod = number(modifier)
            if rating ~= nil or mod ~= nil then include((rating or 0) + (mod or 0)) end
        end
        hit(_G.CR_HIT_MELEE, GetHitModifier)
        hit(_G.CR_HIT_MELEE, GetOffhandHitModifier)
        hit(_G.CR_HIT_RANGED, GetRangedHitModifier)
        hit(_G.CR_HIT_SPELL, GetSpellHitModifier)
    end
    -- A lower, readable channel is not the combined stat when another channel
    -- is restricted. Let the display show unavailable until all values recover.
    if restricted then return nil end
    return best
end

-- Secret stat values can be displayed by the native text renderer. Keep them
-- out of the strings that Lua measures, merges, or uses for tooltip hit testing.
function InfoFrame._CamelotLiveCombatText(key)
    local label = STAT_REGISTRY[key].label
    local function display(fmt, sample, ...)
        return { format = label .. ": |cffffffff" .. fmt .. "|r",
            sample = label .. ": |cffffffff" .. sample .. "|r", args = { ... } }
    end
    -- A visible native row already contains the combined total, including hit
    -- rating/modifiers and ranged ammo haste. Read it without changing the row.
    local root = _G.CharacterStatsPaneScrollBox
    if root and root.IsVisible and root:IsVisible() then
        local box = root.ScrollBox
        local view = box and box.GetView and box:GetView()
        local rows = view and view.GetFrames and view:GetFrames()
        if type(rows) == "table" then
            for _, row in ipairs(rows) do
                local data = row.GetElementData and row:GetElementData()
                local name = data and data.name
                local matches = (key == "crit" and name == "CRITCHANCE")
                    or (key == "haste" and name == "HASTE")
                    or (key == "meleeHit" and name == "HITCHANCE")
                if matches and data.unit == "player" and row.Value and row.Value.GetText then
                    local text = row.Value:GetText()
                    if (issecretvalue and issecretvalue(text)) or (type(text) == "string" and text ~= "") then
                        return display("%s", "999.99%", text)
                    end
                end
            end
        end
    end
    local function live(fn, ...)
        local value = _SafeCall(fn, ...)
        if (issecretvalue and issecretvalue(value)) or type(value) == "number" then return value end
    end
    if key == "crit" or key == "haste" then
        -- Forever shares these channels. Forward the current value directly;
        -- do not compare secret melee/ranged/spell values to choose a maximum.
        local value
        if key == "crit" then value = live(GetCritChance)
        else value = live(GetMeleeHaste) end
        if (issecretvalue and issecretvalue(value)) or type(value) == "number" then
            return display("%.2f%%", "999.99%", value)
        end
    elseif key == "meleeHit" then
        local rating = live(GetCombatRatingBonus, _G.CR_HIT_MELEE or 6)
        local modifier = live(GetHitModifier)
        if ((issecretvalue and issecretvalue(rating)) or type(rating) == "number")
            and ((issecretvalue and issecretvalue(modifier)) or type(modifier) == "number") then
            -- Lua cannot add two secret numbers. With no visible native total,
            -- show both live contributions rather than an old or partial total.
            return display("%.2f%% + %.2f%%", "999.99% + 999.99%", rating, modifier)
        end
    end
end

function InfoFrame._RenderCamelotLiveText(fs)
    local displays = InfoFrame._camelotLiveCombatText
    local entry = fs and fs._fluxEntryRef
    if not displays or not entry or not fs.SetFormattedText then return end
    local text = entry.text or ""
    local replacements = {}
    for _, key in ipairs(entry.keys or { entry.key }) do
        local live = displays[key]
        if live then
            local first, last = text:find(live.sample, 1, true)
            if first then replacements[#replacements + 1] = { first = first, last = last, live = live } end
        end
    end
    if #replacements == 0 then return end
    table.sort(replacements, function(a, b) return a.first < b.first end)
    local parts, args, cursor = {}, {}, 1
    local function literal(value) return (value:gsub("%%", "%%%%")) end
    for _, replacement in ipairs(replacements) do
        parts[#parts + 1] = literal(text:sub(cursor, replacement.first - 1))
        parts[#parts + 1] = replacement.live.format
        for _, value in ipairs(replacement.live.args) do args[#args + 1] = value end
        cursor = replacement.last + 1
    end
    parts[#parts + 1] = literal(text:sub(cursor))
    fs:SetFormattedText(table.concat(parts), (unpack or table.unpack)(args))
end

-- Accept hex colors in different formats and normalize to 6-char rgb.
local function _NormalizeHexColor(colorHex)
    if type(colorHex) ~= "string" then
        return nil
    end
    local hex = colorHex:match("|c[fF][fF](%x%x%x%x%x%x)") or colorHex:match("^ff(%x%x%x%x%x%x)$") or colorHex
    if type(hex) ~= "string" then
        return nil
    end
    hex = hex:lower()
    if #hex == 6 and hex:match("^%x%x%x%x%x%x$") then
        return hex
    end
    return nil
end

local _SCHOOL_COLOR_BY_ID = {
    [2] = "ffff99", -- Holy
    [3] = "ff8000", -- Fire
    [4] = "33ff33", -- Nature
    [5] = "66ccff", -- Frost
    [6] = "cc66ff", -- Shadow
    [7] = "99ccff", -- Arcane
}

local function _GetSpellPowerTopSchoolColorNoTie(maxD, bonus)
    local cscFn = _G.CSC_InfoFrame_BuildSpellPowerData
    if type(cscFn) == "function" then
        local ok, maxDmg, _, _, values, relevant = pcall(cscFn)
        if ok and type(maxDmg) == "number" and maxDmg > 0 and type(values) == "table" and type(relevant) == "table" then
            local topCount = 0
            local topSchool = nil
            for school = 2, 7 do
                if relevant[school] and type(values[school]) == "number" and values[school] == maxDmg then
                    topCount = topCount + 1
                    topSchool = school
                end
            end
            if topCount == 1 then
                return _SCHOOL_COLOR_BY_ID[topSchool]
            end
            return nil -- tie or no clear top -> white
        end
    end
    if InfoFrame._ClassicSpellDamageColorHex then
        return InfoFrame._ClassicSpellDamageColorHex(maxD, bonus)
    end
    return nil
end

--- Melee (physical) crit — InfoFrame label "M.Crit", full decimal %.
STAT_REGISTRY["meleeCrit"] = {
    label = "M.Crit",
    order = 11,
    get = function()
        local displayFn = _G.CSC_InfoFrame_GetDisplayMeleeCritPercent
        if type(displayFn) == "function" then
            local ok, v = pcall(displayFn, "player")
            if ok and v ~= nil then return v end
        end
        if type(GetCritChance) == "function" then
            local v = _SafeCall(GetCritChance)
            if v ~= nil then return v end
        end
        return nil
    end,
    fmt = "%.2f%%",
}

STAT_REGISTRY["crit"] = {
    label = "S.Crit",
    order = 10,
    get = function()
        -- CSC: class-relevant spell crit with talent bonuses, aura procs, and school coloring.
        local cscFn = _G.CSC_InfoFrame_BuildSpellCritData
        if type(cscFn) == "function" then
            local ok, maxCrit, topSchool, values, relevant = pcall(cscFn, "player")
            if ok and type(maxCrit) == "number" then
                local fallbackHex = _SCHOOL_COLOR_BY_ID[topSchool]
                local colorFn = _G.CSC_InfoFrame_GetDisplayColorForTop
                if type(colorFn) == "function" then
                    local colorHex = _NormalizeHexColor(colorFn(values, relevant, maxCrit, true)) or fallbackHex
                    return maxCrit, colorHex
                end
                return maxCrit, fallbackHex
            end
        end
        -- Retail / non-caster fallback (melee crit).
        local meleeFn = _G.CSC_InfoFrame_GetDisplayMeleeCritPercent
        if type(meleeFn) == "function" then
            local ok, v = pcall(meleeFn, "player")
            if ok and v ~= nil then return v end
        end
        if type(GetCritChance) == "function" then return GetCritChance() end
        if type(GetSpellCritChance) == "function" then
            local best = 0
            for i = 2, 7 do
                local v = _SafeCall(GetSpellCritChance, i)
                if v and v > best then best = v end
            end
            if best > 0 then return best end
        end
        return nil
    end,
    fmt = "%.2f%%",
}

STAT_REGISTRY["haste"] = {
    label = "S.Haste",
    order = 20,
    get = function()
        local displayFn = _G.CSC_InfoFrame_GetDisplayHastePercent
        if type(displayFn) == "function" then
            local ok, v = pcall(displayFn, "player")
            if ok and v ~= nil then return v end
        end
        -- Classic Era: gear+buff cast-speed scan.
        local cscFn = _G.CSC_InfoFrame_GetCastSpeedStats
        if type(cscFn) == "function" then
            local ok, totalIncrease = pcall(cscFn)
            if ok and totalIncrease then return totalIncrease end
        end
        if type(GetHaste) == "function" then
            local v = _SafeCall(GetHaste)
            if v ~= nil then return v end
        end
        -- Forever / WotLK-family: no GetHaste; paper doll uses melee/ranged/spell haste.
        local melee, ranged, spell = 0, 0, 0
        local usedForeverHaste = false
        if type(GetMeleeHaste) == "function" then
            usedForeverHaste = true
            melee = tonumber(_SafeCall(GetMeleeHaste)) or 0
        end
        if type(GetRangedHaste) == "function" then
            usedForeverHaste = true
            local okH, base, ammo = pcall(GetRangedHaste)
            if okH then
                ranged = (tonumber(base) or 0) + (tonumber(ammo) or 0)
            end
        end
        if type(UnitSpellHaste) == "function" then
            usedForeverHaste = true
            spell = tonumber(_SafeCall(UnitSpellHaste, "player")) or 0
        end
        if usedForeverHaste then
            return math.max(melee, ranged, spell)
        end
        return nil
    end,
    fmt = "%.2f%%",
}

STAT_REGISTRY["mastery"] = {
    label = "Mastery",
    order = 30,
    get = function()
        if type(GetMasteryEffect) == "function" then return _SafeCall(GetMasteryEffect) end
        return nil
    end,
    fmt = "%.2f%%",
}

STAT_REGISTRY["versatility"] = {
    label = "Vers",
    order = 40,
    get = function()
        if type(GetCombatRatingBonus) == "function" and CR_VERSATILITY_DAMAGE_DONE then
            return _SafeCall(GetCombatRatingBonus, CR_VERSATILITY_DAMAGE_DONE)
        end
        return nil
    end,
    fmt = "%.2f%%",
}

--- Forever cloth "Spell Damage" / "Spell Healing" are Classic Era spell power, not two extra stats.
function InfoFrame._ClassicSpellPinKey(key)
    if type(key) ~= "string" or key == "" then
        return nil
    end
    local k = key:lower():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    k = k:gsub("[:%s]+$", ""):gsub("%s+", "_"):gsub("[^%w_]", "")
    if k == "spellpower" or k == "spell_power" or k == "spellpoweronly" or k == "spell_damage" or k == "spelldamage" or k == "sp" then
        return "spellPower"
    end
    if k == "healpower" or k == "heal_power" or k == "spell_healing" or k == "spellhealing" or k == "healing" then
        return "healPower"
    end
    local damageName = _G.STAT_SPELLPOWER
    local healName = _G.STAT_SPELLHEALING
    if type(damageName) == "string" and k == damageName:lower():gsub("[:%s]+$", ""):gsub("%s+", "_"):gsub("[^%w_]", "") then
        return "spellPower"
    end
    if type(healName) == "string" and k == healName:lower():gsub("[:%s]+$", ""):gsub("%s+", "_"):gsub("[^%w_]", "") then
        return "healPower"
    end
    return nil
end

function InfoFrame._UseClassicSpellPowerLine()
    if InfoFrame._IsCamelotClient() then
        return true
    end
    return type(_G.PaperDollFrame_SetSpellPower) == "function" and type(_G.CSC_InfoFrame_BuildSpellPowerData) ~= "function"
end

function InfoFrame._FoldClassicSpellPins(db)
    local pins = db and db.pinnedStats
    if type(pins) ~= "table" then
        return
    end
    local addSp, addHeal = false, false
    local remove = {}
    for key, enabled in pairs(pins) do
        if enabled then
            local kind = InfoFrame._ClassicSpellPinKey(key)
            if kind == "spellPower" and key ~= "spellPower" then
                addSp = true
                remove[#remove + 1] = key
            elseif kind == "healPower" and key ~= "healPower" then
                addHeal = true
                remove[#remove + 1] = key
            end
        end
    end
    for i = 1, #remove do
        pins[remove[i]] = nil
    end
    if not addSp and not addHeal then
        return
    end
    local mode = db.spellDisplayMode or "off"
    local hasSp = addSp or mode == "sp" or mode == "both"
    local hasHeal = addHeal or mode == "heal" or mode == "both"
    if hasSp and hasHeal then
        mode = "both"
    elseif hasSp then
        mode = "sp"
    elseif hasHeal then
        mode = "heal"
    else
        mode = "off"
    end
    db.spellDisplayMode = mode
    pins.spellPower = (hasSp or hasHeal) and true or nil
    pins.healPower = hasHeal and true or nil
end

function InfoFrame._PlainStatNumber(v)
    if v == nil then
        return nil
    end
    if issecretvalue and issecretvalue(v) then
        return nil
    end
    if type(v) == "number" then
        return v
    end
    if type(v) ~= "string" then
        return nil
    end
    if issecretvalue and issecretvalue(v) then
        return nil
    end
    local text = v:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub(",", ""):gsub("%s+", "")
    local n = tonumber(text)
    if n == nil or (issecretvalue and issecretvalue(n)) then
        return nil
    end
    return n
end

--- Copy the numbers Blizzard already stored on the character rows. Addon calls to
--- GetSpellBonusDamage are restricted on Forever and were showing up as 1.
function InfoFrame._EnsureCamelotSpellSnapshotHooks()
    -- PaperDollFrame_OnShow calls these from ToggleCharacter, before
    -- CharacterFrame:OnShow compares secret health. A post-hook taints that
    -- compare. Spell numbers are read off the rows after the panel is open.
end

--- max damage, healing, min school damage, per-school bonus[2..7]
function InfoFrame._CamelotSpellBonus()
    InfoFrame._EnsureCamelotSpellSnapshotHooks()
    local bonus = {}
    local function takeSchool(school, value)
        local n = InfoFrame._PlainStatNumber(value)
        if n ~= nil then
            bonus[school] = n
        end
    end
    local snap = InfoFrame._camelotSpellSnapshot
    if snap and type(snap.bonus) == "table" then
        for school = 2, 7 do
            takeSchool(school, snap.bonus[school])
        end
    end
    if not next(bonus) and _GetTooltipSourceStatFrames then
        local frames = _GetTooltipSourceStatFrames("spellPower") or {}
        for i = 1, #frames do
            local stored = frames[i] and frames[i].bonusDamage
            if type(stored) == "table" then
                for school = 2, 7 do
                    takeSchool(school, stored[school])
                end
            end
        end
    end
    if not next(bonus) and type(GetSpellBonusDamage) == "function" then
        local maxSchools = _G.MAX_SPELL_SCHOOLS or 7
        for school = 2, maxSchools do
            takeSchool(school, _SafeCall(GetSpellBonusDamage, school))
        end
    end
    local minD, maxD
    for school = 2, 7 do
        local n = bonus[school]
        if n ~= nil then
            if minD == nil or n < minD then
                minD = n
            end
            if maxD == nil or n > maxD then
                maxD = n
            end
        end
    end
    if maxD == nil and snap then
        maxD = InfoFrame._PlainStatNumber(snap.shown)
    end
    local heal = snap and InfoFrame._PlainStatNumber(snap.heal) or nil
    if heal == nil and _GetTooltipSourceStatFrames then
        local frames = _GetTooltipSourceStatFrames("healPower") or {}
        for i = 1, #frames do
            local frame = frames[i]
            heal = InfoFrame._PlainStatNumber(frame and frame.numericValue)
            if heal == nil and frame and frame.Value and frame.Value.GetText then
                heal = InfoFrame._PlainStatNumber(frame.Value:GetText())
            end
            if heal ~= nil then
                break
            end
        end
    end
    if heal == nil and type(GetSpellBonusHealing) == "function" then
        heal = InfoFrame._PlainStatNumber(_SafeCall(GetSpellBonusHealing))
    end
    return maxD or 0, heal or 0, minD or maxD or 0, bonus
end

--- Same rule as classic GetDisplayColorForTop: one leading school, else the spec school if it ties, else white.
function InfoFrame._ClassicSpellDamageColorHex(maxD, bonus)
    if maxD == nil or type(bonus) ~= "table" then
        local currentMax, _, _, currentBonus = InfoFrame._CamelotSpellBonus()
        maxD, bonus = currentMax, currentBonus
    end
    local tops = {}
    for school = 2, 7 do
        if bonus[school] == maxD then
            tops[#tops + 1] = school
        end
    end
    if #tops == 1 then
        return _SCHOOL_COLOR_BY_ID[tops[1]] or "ffffff"
    end
    local _, _, classId = UnitClass("player")
    local tab
    if type(GetNumTalentTabs) == "function" and type(GetTalentTabInfo) == "function" then
        local best, bestPts = nil, -1
        for i = 1, GetNumTalentTabs() do
            local _, _, pts = GetTalentTabInfo(i)
            pts = tonumber(pts) or 0
            if pts > bestPts then
                bestPts = pts
                best = i
            end
        end
        if bestPts > 0 then
            tab = best
        end
    end
    local dominant
    if classId == 8 then
        if tab == 1 then dominant = 7 elseif tab == 2 then dominant = 3 elseif tab == 3 then dominant = 5 end
    elseif classId == 5 then
        if tab == 2 then dominant = 2 elseif tab == 3 then dominant = 6 end
    elseif classId == 9 then
        if tab == 1 then dominant = 6 elseif tab == 3 then dominant = 3 end
    elseif classId == 2 then
        if tab == 1 then dominant = 2 end
    elseif classId == 11 then
        if tab == 1 then dominant = 4 end
    elseif classId == 7 then
        if tab == 1 then dominant = 4 end
    end
    if dominant then
        for i = 1, #tops do
            if tops[i] == dominant then
                return _SCHOOL_COLOR_BY_ID[dominant] or "ffffff"
            end
        end
    end
    return "ffffff"
end

STAT_REGISTRY["spellPower"] = {
    label = "Spell",
    order = 50,
    -- getText returns (fullText, compactText) so the combined Dmg / Heal line
    -- can be formatted and colored before _GetKeyText sees it.
    getText = function()
        if InfoFrame._UseClassicSpellPowerLine() then
            -- Forever Spell Damage / Spell Healing are Classic Era spell power.
            -- Pin damage -> S.P.  Pin healing -> Heal.  Pin both -> Spell: dmg / heal.
            local mode = GetInfoFrameCharDB().spellDisplayMode or "off"
            local maxD, heal, _, bonus = InfoFrame._CamelotSpellBonus()
            local haveSchools = false
            for school = 2, 7 do
                if bonus[school] ~= nil then
                    haveSchools = true
                    break
                end
            end
            local snap = InfoFrame._camelotSpellSnapshot
            local dmgHex = _GetSpellPowerTopSchoolColorNoTie(maxD, bonus) or "ffffff"
            local dmgStr
            if haveSchools or not (snap and type(snap.shownText) == "string" and snap.shownText ~= "") then
                dmgStr = string.format("|cff%s%d|r", dmgHex, maxD or 0)
            else
                dmgStr = snap.shownText
            end
            local healStr
            if heal ~= 0 or not (snap and type(snap.healText) == "string" and snap.healText ~= "") then
                healStr = string.format("|cff20ff20%d|r", heal or 0)
            else
                healStr = "|cff20ff20" .. snap.healText .. "|r"
            end
            local showDmg = mode == "sp" or mode == "both"
            local showHeal = mode == "heal" or mode == "both"
            if showDmg and showHeal then
                local full = "Spell: " .. dmgStr .. " / " .. healStr
                local compact = "Spell: " .. dmgStr .. "/" .. healStr
                return full, compact
            end
            if showHeal then
                local one = "Heal: " .. healStr
                return one, one
            end
            local one = "S.P.: " .. dmgStr
            return one, one
        end
        local cscFn = _G.CSC_InfoFrame_BuildSpellPowerData
        if type(cscFn) == "function" then
            local ok, maxDmg, heal, _, values, relevant = pcall(cscFn)
            if ok and type(maxDmg) == "number" and maxDmg > 0 then
                local colorFn = _G.CSC_InfoFrame_GetDisplayColorForTop
                local colorHex = "ffffff"
                if type(colorFn) == "function" then
                    colorHex = _NormalizeHexColor(colorFn(values, relevant, maxDmg, false)) or "ffffff"
                end
                local dmgStr  = string.format("|cff%s%d|r", colorHex, maxDmg)
                if type(heal) == "number" and heal > 0 then
                    local healStr = string.format("|cff20ff20%d|r", heal)
                    local full    = "Spell: " .. dmgStr .. " / " .. healStr
                    local compact = "Spell: " .. dmgStr .. "/" .. healStr
                    return full, compact
                end
                local one = "Spell: " .. dmgStr
                return one, one
            end
        end
        -- Retail / fallback: best school damage only.
        if type(GetSpellBonusDamage) == "function" then
            local best = 0
            for i = 2, 7 do
                local v = _SafeCall(GetSpellBonusDamage, i)
                if v and v > best then best = v end
            end
            if best > 0 then
                local s = string.format("|cffffffff%d|r", best)
                local one = "Spell: " .. s
                return one, one
            end
        end
        local na = "|cff888888--|r"
        local one = "Spell: " .. na
        return one, one
    end,
    get = function() return nil end,
    fmt = "%d",
}

STAT_REGISTRY["spellPowerOnly"] = {
    label = "S.P.",
    order = 50,
    getText = function()
        local cscFn = _G.CSC_InfoFrame_BuildSpellPowerData
        if type(cscFn) == "function" then
            local ok, maxDmg, _, _, values, relevant = pcall(cscFn)
            if ok and type(maxDmg) == "number" and maxDmg > 0 then
                local colorFn = _G.CSC_InfoFrame_GetDisplayColorForTop
                local colorHex = "ffffff"
                if type(colorFn) == "function" then
                    colorHex = _NormalizeHexColor(colorFn(values, relevant, maxDmg, false)) or "ffffff"
                end
                local dmgStr = string.format("|cff%s%d|r", colorHex, maxDmg)
                local one = "S.P.: " .. dmgStr
                return one, one
            end
        end
        if type(GetSpellBonusDamage) == "function" then
            local best = 0
            for i = 2, 7 do
                local v = _SafeCall(GetSpellBonusDamage, i)
                if v and v > best then best = v end
            end
            if best > 0 then
                local s = string.format("|cffffffff%d|r", best)
                local one = "S.P.: " .. s
                return one, one
            end
        end
        local na = "|cff888888--|r"
        local one = "S.P.: " .. na
        return one, one
    end,
    get = function() return nil end,
    fmt = "%d",
}

STAT_REGISTRY["healPower"] = {
    label = "Heal",
    order = 55,
    get = function()
        -- CSC exposes heal as second return of BuildSpellPowerData.
        local cscFn = _G.CSC_InfoFrame_BuildSpellPowerData
        if type(cscFn) == "function" then
            local ok, _, heal = pcall(cscFn)
            if ok and heal and heal > 0 then return heal, "20ff20" end
        end
        if type(GetSpellBonusHealing) ~= "function" then return nil end
        local v = _SafeCall(GetSpellBonusHealing)
        if v and v > 0 then return v, "20ff20" end
        return nil
    end,
    fmt = "%d",
}

STAT_REGISTRY["spellHit"] = {
    label = "S.Hit",
    order = 60,
    get = function()
        -- CSC: class-specific hit with talent/rune bonuses and school coloring.
        local cscFn = _G.CSC_InfoFrame_BuildSpellHitData
        if type(cscFn) == "function" then
            local ok, maxVal, topSchool, values, relevant = pcall(cscFn, "player")
            if ok and type(maxVal) == "number" then
                local fallbackHex = _SCHOOL_COLOR_BY_ID[topSchool]
                local colorFn = _G.CSC_InfoFrame_GetDisplayColorForTop
                if type(colorFn) == "function" then
                    local colorHex = _NormalizeHexColor(colorFn(values, relevant, maxVal, true)) or fallbackHex
                    return maxVal, colorHex
                end
                return maxVal, fallbackHex
            end
        end
        if type(_G.CSC_GetTotalSpellHitPercent) == "function" then
            local ok, v = pcall(_G.CSC_GetTotalSpellHitPercent, "player")
            if ok and type(v) == "number" then return v end
        end
        -- Retail / non-caster fallback (melee hit).
        if type(GetHitModifier) == "function" then
            local v = _SafeCall(GetHitModifier)
            if v ~= nil then return v end
        end
        if type(GetCombatRatingBonus) == "function" and type(_G.CR_HIT_SPELL) == "number" then
            local rating = tonumber(_SafeCall(GetCombatRatingBonus, _G.CR_HIT_SPELL)) or 0
            local mod = 0
            if type(GetSpellHitModifier) == "function" then
                mod = tonumber(_SafeCall(GetSpellHitModifier)) or 0
            end
            return rating + mod
        end
        if type(GetSpellHitModifier) == "function" then
            local v = _SafeCall(GetSpellHitModifier)
            if v ~= nil then return v end
        end
        return nil
    end,
    fmt = "%.2f%%",
}

STAT_REGISTRY["spellPenetration"] = {
    label = "Sp.Pen",
    order = 57,
    get = function()
        if type(GetSpellPenetration) ~= "function" then return nil end
        local v = _SafeCall(GetSpellPenetration)
        if type(v) == "number" then return v end
        return nil
    end,
    fmt = "%.0f",
}

STAT_REGISTRY["meleeHit"] = {
    label = "M.Hit",
    order = 61,
    get = function()
        if type(_G.CSC_GetTotalMeleeHitPercent) == "function" then
            local ok, v = pcall(_G.CSC_GetTotalMeleeHitPercent, "player")
            if ok and type(v) == "number" then return v end
        end
        if type(GetCombatRatingBonus) == "function" and type(_G.CR_HIT_MELEE) == "number" then
            local rating = tonumber(_SafeCall(GetCombatRatingBonus, _G.CR_HIT_MELEE)) or 0
            local mod = tonumber(_SafeCall(GetHitModifier)) or 0
            return rating + mod
        end
        if type(GetHitModifier) == "function" then
            local v = _SafeCall(GetHitModifier)
            if v ~= nil then return v end
        end
        return nil
    end,
    fmt = "%.2f%%",
}

--- Weapon damage (melee main/off hand range), not attack power.
STAT_REGISTRY["weaponDamage"] = {
    label = "M.Dmg",
    order = 64,
    get = function()
        if type(UnitDamage) == "function" then
            local ok, a, b, c, d = pcall(UnitDamage, "player")
            if ok then
                local lowM, highM = tonumber(a) or 0, tonumber(b) or 0
                local lowO, highO = tonumber(c) or 0, tonumber(d) or 0
                if lowM > 0 or highM > 0 then
                    local s = string.format("%d-%d", math.floor(lowM), math.floor(highM))
                    if lowO > 0 or highO > 0 then
                        s = s .. string.format(" (%d-%d)", math.floor(lowO), math.floor(highO))
                    end
                    return s
                end
            end
        end
        return nil
    end,
    fmt = "%s",
}

--- Ranged weapon damage (when API exists).
STAT_REGISTRY["rangedWeaponDamage"] = {
    label = "R.Dmg",
    order = 63,
    get = function()
        if type(UnitRangedDamage) ~= "function" then return nil end
        local ok, _speed, low, high = pcall(UnitRangedDamage, "player")
        if not ok then return nil end
        low, high = tonumber(low), tonumber(high)
        if low and high and (low > 0 or high > 0) then
            return string.format("%d-%d", math.floor(low), math.floor(high))
        end
        return nil
    end,
    fmt = "%s",
}

STAT_REGISTRY["attackPower"] = {
    label = "M.AP",
    order = 65,
    get = function()
        if type(UnitAttackPower) ~= "function" then return nil end
        local ok, base, pos, neg = pcall(UnitAttackPower, "player")
        if ok and base ~= nil then return (tonumber(base) or 0) + (tonumber(pos) or 0) - (tonumber(neg) or 0) end
        return nil
    end,
    fmt = "%d",
}

STAT_REGISTRY["rangedAttackPower"] = {
    label = "R.AP",
    order = 65,
    get = function()
        if type(UnitRangedAttackPower) ~= "function" then return nil end
        local ok, base, pos, neg = pcall(UnitRangedAttackPower, "player")
        if ok and base ~= nil then return base + (pos or 0) - (neg or 0) end
        return nil
    end,
    fmt = "%d",
}

STAT_REGISTRY["armor"] = {
    label = "Armor",
    order = 70,
    get = function()
        if type(UnitArmor) ~= "function" then return nil end
        local ok, base, eff = pcall(UnitArmor, "player")
        if not ok then return nil end
        if eff then return eff end
        if base then return base end
        return nil
    end,
    fmt = "%d",
}

STAT_REGISTRY["dodge"] = {
    label = "Dodge",
    order = 75,
    get = function()
        if type(GetDodgeChance) == "function" then return _SafeCall(GetDodgeChance) end
        return nil
    end,
    fmt = "%.2f%%",
}

STAT_REGISTRY["parry"] = {
    label = "Parry",
    order = 76,
    get = function()
        if type(GetParryChance) == "function" then return _SafeCall(GetParryChance) end
        return nil
    end,
    fmt = "%.2f%%",
}

STAT_REGISTRY["block"] = {
    label = "Block",
    order = 77,
    get = function()
        if type(GetBlockChance) == "function" then return _SafeCall(GetBlockChance) end
        return nil
    end,
    fmt = "%.2f%%",
}

STAT_REGISTRY["mp5"] = {
    label = "MP5",
    order = 80,
    get = function()
        if type(GetManaRegen) ~= "function" then return nil end
        local ok, base, cast = pcall(GetManaRegen)
        if not ok then return nil end
        -- Show while-casting regen in InfoFrame (label remains MP5).
        local regen = cast or base
        if not regen then return nil end
        local mp5 = regen * 5
        if mp5 > 0 then return mp5 end
        return nil
    end,
    fmt = "%.0f",
}

STAT_REGISTRY["rangedCrit"] = {
    label = "R.Crit",
    order = 12,
    get = function()
        local displayFn = _G.CSC_InfoFrame_GetDisplayRangedCritPercent
        if type(displayFn) == "function" then
            local ok, v = pcall(displayFn, "player")
            if ok and v ~= nil then return v end
        end
        if type(GetRangedCritChance) == "function" then
            local v = _SafeCall(GetRangedCritChance)
            if v ~= nil then return v end
        end
        return nil
    end,
    fmt = "%.2f%%",
}

-- Mainline: unified secondary ratings; avoid M./S./R. prefixes in pinned / merged stat text.
do
    local pid = rawget(_G, "WOW_PROJECT_ID")
    local mainline = rawget(_G, "WOW_PROJECT_MAINLINE")
    if InfoFrame._IsCamelotClient() or (type(pid) == "number" and type(mainline) == "number" and pid == mainline) then
        local mc = STAT_REGISTRY["meleeCrit"]
        local rc = STAT_REGISTRY["rangedCrit"]
        local sc = STAT_REGISTRY["crit"]
        local ha = STAT_REGISTRY["haste"]
        if mc then mc.label = "Crit" end
        if rc then rc.label = "Crit" end
        if sc then sc.label = "Crit" end
        if ha then ha.label = "Haste" end
    end
end

STAT_REGISTRY["rangedHit"] = {
    label = "R.Hit",
    order = 62,
    get = function()
        if type(_G.CSC_GetTotalRangedHitPercent) == "function" then
            local ok, v = pcall(_G.CSC_GetTotalRangedHitPercent, "player")
            if ok and type(v) == "number" then return v end
        end
        if type(GetCombatRatingBonus) == "function" and type(_G.CR_HIT_RANGED) == "number" then
            local rating = tonumber(_SafeCall(GetCombatRatingBonus, _G.CR_HIT_RANGED)) or 0
            local mod = tonumber(_SafeCall(GetRangedHitModifier)) or 0
            return rating + mod
        end
        if type(GetRangedHitModifier) == "function" then
            local v = _SafeCall(GetRangedHitModifier)
            if v ~= nil then return v end
        end
        -- Classic Era / clients with no ranged-specific API: physical hit modifier.
        if type(GetHitModifier) == "function" then
            local v = _SafeCall(GetHitModifier)
            if v ~= nil then return v end
        end
        return nil
    end,
    fmt = "%.2f%%",
}

if InfoFrame._IsCamelotClient() then
    for _, key in ipairs({ "crit", "haste", "meleeHit" }) do
        STAT_REGISTRY[key].get = function() return InfoFrame._CamelotCombatStatValue(key) end
    end
    STAT_REGISTRY.meleeHit.label = "Hit"
    STAT_REGISTRY.meleeCrit = STAT_REGISTRY.crit
    STAT_REGISTRY.rangedCrit = STAT_REGISTRY.crit
    STAT_REGISTRY.spellHit = STAT_REGISTRY.meleeHit
    STAT_REGISTRY.rangedHit = STAT_REGISTRY.meleeHit
end

STAT_REGISTRY["meleeArmorPenetration"] = {
    label = "M.APen",
    order = 67,
    get = function()
        if type(GetArmorPenetration) ~= "function" then return nil end
        local v = _SafeCall(GetArmorPenetration)
        if type(v) == "number" then return v end
        return nil
    end,
    fmt = "%.2f%%",
}

STAT_REGISTRY["rangedArmorPenetration"] = {
    label = "R.APen",
    order = 68,
    get = function()
        if type(IsRangedWeapon) == "function" and not IsRangedWeapon() then return nil end
        if type(GetArmorPenetration) ~= "function" then return nil end
        local v = _SafeCall(GetArmorPenetration)
        if type(v) == "number" then return v end
        return nil
    end,
    fmt = "%.2f%%",
}

STAT_REGISTRY["expertise"] = {
    label = "Expertise",
    order = 66,
    get = function()
        if type(GetExpertise) == "function" then
            local ok, expertise = pcall(GetExpertise)
            if ok and type(expertise) == "number" then return expertise end
        end
        return nil
    end,
    fmt = "%d",
}

STAT_REGISTRY["defense"] = {
    label = "Defense",
    order = 71,
    get = function()
        if type(GetDefenseSkill) == "function" then
            local ok, v = pcall(GetDefenseSkill)
            if ok and v then return v end
        end
        if type(UnitDefenseSkill) == "function" then
            local ok, base, modifier = pcall(UnitDefenseSkill, "player")
            if ok and type(base) == "number" then
                return math.max(0, base + (tonumber(modifier) or 0))
            end
        end
        if type(UnitDefense) == "function" then
            local ok, v = pcall(UnitDefense, "player")
            if ok and v then return v end
        end
        local crDef = _G.CR_DEFENSE_SKILL
        if type(GetCombatRatingBonus) == "function" and type(crDef) == "number" then
            local v = _SafeCall(GetCombatRatingBonus, crDef)
            if v then return v end
        end
        return nil
    end,
    fmt = "%d",
}

STAT_REGISTRY["resilience"] = {
    label = "Resil",
    order = 78,
    get = function()
        if type(GetCombatRating) ~= "function" then return nil end
        local cr = _G.CR_RESILIENCE_CRIT_TAKEN
        if type(cr) == "number" then
            local v = _SafeCall(GetCombatRating, cr)
            if type(v) == "number" then return v end
        end
        cr = _G.COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN
        if type(cr) == "number" then
            local v = _SafeCall(GetCombatRating, cr)
            if type(v) == "number" then return v end
        end
        return nil
    end,
    fmt = "%d",
}

--- Run / flight / swim speed as a percent of base. Character Info "Speed" and "Movement Speed" are this one stat.
STAT_REGISTRY["speed"] = {
    label = "Speed",
    order = 45,
    get = function()
        local hasMoveRow = false
        local cats = _G.PAPERDOLL_STATCATEGORIES
        if type(cats) == "table" then
            for _, cat in pairs(cats) do
                local stats = cat and cat.stats
                if type(stats) == "table" then
                    for _, entry in pairs(stats) do
                        if type(entry) == "table" and entry.stat == "MOVESPEED" then
                            hasMoveRow = true
                        end
                    end
                end
            end
        end
        if hasMoveRow and type(GetUnitSpeed) == "function" then
            local ok, current, runSpeed, flightSpeed, swimSpeed = pcall(GetUnitSpeed, "player")
            if ok then
                local base = tonumber(_G.BASE_MOVEMENT_SPEED) or 7
                if base > 0 then
                    local yards = runSpeed or current
                    if type(IsSwimming) == "function" and IsSwimming("player") then
                        yards = swimSpeed or yards
                    elseif type(IsFlying) == "function" and IsFlying("player") then
                        yards = flightSpeed or yards
                    end
                    yards = tonumber(yards)
                    if yards and yards > 0 then
                        return (yards / base) * 100
                    end
                end
            end
        end
        if type(GetCombatRatingBonus) == "function" and CR_SPEED then
            return _SafeCall(GetCombatRatingBonus, CR_SPEED)
        end
        return nil
    end,
    fmt = "%.0f%%",
}

STAT_REGISTRY["health"] = {
    label = "HP",
    order = 48,
    get = function()
        if type(UnitHealthMax) ~= "function" then return nil end
        local ok, v = pcall(UnitHealthMax, "player")
        if not ok then return nil end
        v = tonumber(v)
        if type(v) == "number" then return v end
        return nil
    end,
    fmt = "%s",
}

STAT_REGISTRY["power"] = {
    label = "Power",
    order = 49,
    get = function()
        if type(UnitPowerMax) ~= "function" then return nil end
        local ok, v = pcall(UnitPowerMax, "player")
        if not ok then return nil end
        v = tonumber(v)
        if type(v) == "number" then return v end
        return nil
    end,
    fmt = "%s",
}

--- Alias. Pins and paper-doll rows use "speed".
STAT_REGISTRY["moveSpeed"] = STAT_REGISTRY["speed"]

--- Melee attack speed (matches PaperDoll: UnitAttackSpeed; dual-wield shows "mh / oh").
STAT_REGISTRY["weaponSpeed"] = {
    label = "M.Speed",
    order = 44,
    get = function()
        if type(UnitAttackSpeed) ~= "function" then return nil end
        local ok, mh, oh = pcall(UnitAttackSpeed, "player")
        if not ok or not mh then return nil end
        mh = tonumber(mh)
        if not mh or mh <= 0 then return nil end
        oh = tonumber(oh)
        if oh and oh > 0 then
            return string.format("%.2f / %.2f", mh, oh)
        end
        return string.format("%.2f", mh)
    end,
    fmt = "%s",
}

--- Ranged attack speed (seconds) from UnitRangedDamage.
STAT_REGISTRY["rangedWeaponSpeed"] = {
    label = "R.Speed",
    order = 43,
    get = function()
        if type(UnitRangedDamage) ~= "function" then return nil end
        local ok, spd = pcall(function() return select(1, UnitRangedDamage("player")) end)
        if not ok then return nil end
        spd = tonumber(spd)
        if spd and spd > 0 then return string.format("%.2f", spd) end
        return nil
    end,
    fmt = "%s",
}

STAT_REGISTRY["leech"] = {
    label = "Leech",
    order = 46,
    get = function()
        if type(GetCombatRatingBonus) == "function" and CR_LIFESTEAL then
            return _SafeCall(GetCombatRatingBonus, CR_LIFESTEAL)
        end
        return nil
    end,
    fmt = "%.2f%%",
}

STAT_REGISTRY["avoidance"] = {
    label = "Avoid",
    order = 47,
    get = function()
        if type(GetCombatRatingBonus) == "function" and CR_AVOIDANCE then
            return _SafeCall(GetCombatRatingBonus, CR_AVOIDANCE)
        end
        return nil
    end,
    fmt = "%.2f%%",
}

--- Equipped average item level (Flux CSC wrist row + optional pin).
local function _InfoFrameGetItemLevelValue()
    local fn = _G.FluxCSC_GetPlayerItemLevel
    if type(fn) == "function" then
        local v = fn()
        if type(v) == "number" then return v end
    end
    if type(GetAverageItemLevel) == "function" then
        local ok, overall, equipped = pcall(GetAverageItemLevel)
        if ok then
            if type(equipped) == "number" and equipped > 0 then return equipped end
            if type(overall) == "number" and overall > 0 then return overall end
        end
    end
    return nil
end

--- GearScore (TacoTip TT_GS when loaded; else FluxCSC_GetPlayerGearScore internal).
local function _InfoFrameGetGearScoreValue()
    local fn = _G.FluxCSC_GetPlayerGearScore
    if type(fn) == "function" then
        local v = fn()
        if type(v) == "number" then return v end
    end
    return nil
end

--- |cffRRGGBB for value text; TacoTip parity: tier from total GearScore for both ilvl and GS lines.
local function _InfoFrameGsTierColorHex()
    local qc = _G.FluxCSC_GetGearScoreQualityRGB
    local gs = tonumber(_InfoFrameGetGearScoreValue()) or 0
    local r, g, b = 1, 1, 1
    if type(qc) == "function" then
        r, g, b = qc(gs)
    end
    return string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

STAT_REGISTRY["itemLevel"] = {
    label = "Item LvL",
    order = 7,
    get = _InfoFrameGetItemLevelValue,
    getText = function()
        local val = _InfoFrameGetItemLevelValue()
        local coloredValue
        if val ~= nil then
            coloredValue = string.format("|cff%s%.1f|r", _InfoFrameGsTierColorHex(), val)
        else
            coloredValue = "|cff888888--|r"
        end
        return "iLvl: " .. coloredValue, "iLvl: " .. coloredValue
    end,
    fmt = "%.1f",
}

STAT_REGISTRY["gearScore"] = {
    label = "GearScore",
    order = 8,
    get = _InfoFrameGetGearScoreValue,
    getText = function()
        local val = _InfoFrameGetGearScoreValue()
        local coloredValue
        if val ~= nil then
            coloredValue = string.format("|cff%s%d|r", _InfoFrameGsTierColorHex(), math.floor(val + 0.5))
        else
            coloredValue = "|cff888888--|r"
        end
        return "GearScore: " .. coloredValue, "G.S.: " .. coloredValue
    end,
    fmt = "%d",
}

--- Normalize pinned / dynamic keys (e.g. sanitized "gearscore") to registry keys for merge + strip labels.
local function _CanonicalIlvlGsRegistryKey(k)
    if not k or type(k) ~= "string" then return nil end
    if k == "itemLevel" or k == "gearScore" then return k end
    local l = string.lower(k)
    if l == "gearscore" or l == "gear_score" then return "gearScore" end
    if l == "itemlevel" or l == "item_level" or l == "ilvl" then return "itemLevel" end
    if l == "gs" or l == "g.s" then return "gearScore" end
    return nil
end

-- Primary stats
local _primaryStatNames = { "Strength", "Agility", "Stamina", "Intellect", "Spirit" }
local _primaryStatKeys  = { "strength", "agility", "stamina", "intellect", "spirit" }
local _primaryStatLabels = { "Str", "Agi", "Sta", "Int", "Spi" }
for _i = 1, 5 do
    local idx, label = _i, _primaryStatLabels[_i]
    STAT_REGISTRY[_primaryStatKeys[_i]] = {
        label = label,
        order = 200 + _i,
        get = function()
            if type(UnitStat) ~= "function" then return nil end
            local ok, base, stat = pcall(UnitStat, "player", idx)
            if ok then return stat or base end
            return nil
        end,
        fmt = "%d",
    }
end

function InfoFrame.GetStatRegistry()
    return STAT_REGISTRY
end

-- Dynamic line pool
local linePool = {}
local activeLines = {}
local activeLineCount = 0

function InfoFrame._RefreshCamelotLiveText()
    if not InfoFrame._camelotLiveCombatText then return end
    for _, fs in ipairs(linePool) do
        if fs:IsShown() then InfoFrame._RenderCamelotLiveText(fs) end
    end
end
local _lastLayoutMode = nil
local _lastLayoutW = nil
local _lastLayoutH = nil

-- Forward decl for rebuild
local RebuildInfoLines

--- Match FluxBorder:SetClassColor backdrop (no border art) — used when FluxBorder is removed for status-integrated Info.
local function SetIntegratedStripBackdropColor(tex, r, g, b, a)
    if not tex then return end
    if tex.SetColorTexture then
        tex:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
    else
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        tex:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
    end
end

local function ApplyTintToIntegratedStripBackdrop(tex)
    if not tex or not FluxBorder then return end
    if FluxBorder.GetThemedBackdropFillRGB then
        local r, g, b = FluxBorder:GetThemedBackdropFillRGB()
        SetIntegratedStripBackdropColor(tex, r, g, b, 0.85)
        return
    end
    local r, g, b, mode = FluxBorder:GetAccentColor()
    if mode == "atlas" then
        SetIntegratedStripBackdropColor(tex, 0.15, 0.15, 0.15, 0.85)
    else
        SetIntegratedStripBackdropColor(tex, r * 0.4, g * 0.4, b * 0.4, 0.85)
    end
end

local function RefreshIntegratedStripBackdropVisual()
    if not stripVisualActive or not frame then
        return
    end
    local holder = frame.FluxInfoIntegratedBackdropHolder
    if not holder then
        holder = CreateFrame("Frame", nil, frame)
        holder:SetFrameStrata("BACKGROUND")
        holder:SetFrameLevel(0)
        holder:SetAllPoints(frame)
        local tex = holder:CreateTexture(nil, "BACKGROUND", nil, -8)
        tex:SetAllPoints(holder)
        holder._tex = tex
        frame.FluxInfoIntegratedBackdropHolder = holder
    end
    ApplyTintToIntegratedStripBackdrop(holder._tex)
    holder._tex:Show()
    holder:Show()
end

local function HideIntegratedStripBackdropVisual()
    if frame and frame.FluxInfoIntegratedBackdropHolder then
        frame.FluxInfoIntegratedBackdropHolder:Hide()
    end
end

function InfoFrame.RefreshIntegratedStripBackdrop()
    RefreshIntegratedStripBackdropVisual()
end

local function GetBorderInsetForStack()
    return FluxBorder and FluxBorder.CanUseAtlases and FluxBorder:CanUseAtlases() and 4 or 2
end

--- Vertical offset from horizontal micro bottom to integrated Info top (status bar loc 1). Positive = nudge Info up toward micro to trim stack height.
local MICRO_TO_INTEGRATED_INFO_OFFSET_Y = 1

local function GetPlacement()
    if FluxOptions and FluxOptions.GetInfoFramePlacement then
        return FluxOptions:GetInfoFramePlacement()
    end
    return "actionStrip"
end

--- Used by CombatGrid anchor logic and embeds.
function InfoFrame.IsDockedToActionStrip()
    return GetPlacement() == "actionStrip"
end

function InfoFrame.GetEffectivePlacement()
    return GetPlacement()
end

--- StatusBar column layout (location 2/3 + micro 2/3): FluxStatusBar pins the frame as the last column.
function InfoFrame.SetAnchoredByStatusBarColumn(on)
    if frame then
        frame.FluxAnchoredByStatusBarColumn = on and true or nil
        if on then
            frame.FluxIntegratedLoc1FullWidthCentered = nil
        end
    end
end

--- Same pixel height as gold / XP / rep strips (Status Bars tab).
local function GetIntegratedStripPixelHeight()
    local h = 18
    if FluxOptions and FluxOptions.GetStatusBarSettingsDB then
        local d = FluxOptions:GetStatusBarSettingsDB()
        if d and type(d.barHeight) == "number" and d.barHeight == d.barHeight then
            h = d.barHeight
        end
    end
    return math.max(10, math.min(40, h))
end

local function ApplyVerticalStripTextLayout()
    if activeLineCount == 0 then return end
    _TeardownVerticalScrollForStripLayout()
    local n = activeLineCount
    local spacing = INFO_FRAME_VERTICAL_LINE_GAP
    local totalHeight = (n - 1) * spacing
    local topY = totalHeight / 2
    for i = 1, n do
        local fs = activeLines[i].fs
        local key = activeLines[i].key
        fs:ClearAllPoints()
        fs:SetFont("Fonts\\FRIZQT__.TTF", (spacing <= 12) and 10 or 11, "OUTLINE")
        fs:SetPoint("CENTER", frame, "CENTER", 0, topY - (i - 1) * spacing)
        _BindInfoFrameEntryTooltip(fs, { key = key, keys = { key }, text = activeLines[i].fullText or "" }, "Fonts\\FRIZQT__.TTF", (spacing <= 12) and 10 or 11)
    end
    if durabilityTooltipFrame then
        durabilityTooltipFrame:Hide()
    end
end

--- Minimap-top placement: smaller typography when minimap is floating (non-embedded).
local function IsMinimapEmbeddedMode()
    local fm = _G.FluxMinimap
    return fm and fm.IsEmbedded and fm:IsEmbedded()
end

local function GetMinimapTopStripFontSize()
    if IsMinimapEmbeddedMode() then
        return STRIP_FONT_SIZE
    end
    return MINIMAP_TOP_FLOAT_FONT_SIZE
end

--- Embedded map tab keeps status-strip sizing; floating minimap uses one step smaller text and slightly shorter band.
local function GetMinimapTopStripPixelHeight()
    local base = GetIntegratedStripPixelHeight()
    if IsMinimapEmbeddedMode() then
        return base
    end
    return math.max(14, math.min(32, base - 2))
end

--- Dynamic horizontal strip layout helper (shared by minimap-top and integrated).
local function _GetLineFullText(line)
    return line.fullText or line.fs:GetText() or ""
end

local function _GetLineCompactText(line)
    if line.compactText and line.compactText ~= "" then
        return line.compactText
    end
    return line.fullText or line.fs:GetText() or ""
end

local HORIZ_MERGE_GROUPS_PRIMARY = {
    -- A: system + ilvl + GearScore (gearScore-only pin keeps key gearScore; must be listed to merge with Dur/FPS/ping).
    { "durability", "fps", "ping", "itemLevel", "gearScore" },
    -- B: crit family
    { "crit", "rangedCrit", "meleeCrit", "spellCrit", "critical_strike", "melee_crit", "spell_crit", "ranged_crit" },
    -- C: hit family
    { "spellHit", "meleeHit", "rangedHit", "hit", "hit_chance", "melee_hit", "spell_hit", "ranged_hit" },
    -- D: damage / AP / swing time
    { "weaponDamage", "rangedWeaponDamage", "attackPower", "rangedAttackPower", "weaponSpeed", "rangedWeaponSpeed" },
    -- E: combat spillover (keeps spellPower separate in primary phase)
    { "crit", "meleeCrit", "spellCrit", "rangedCrit", "haste", "spellHit", "meleeHit", "rangedHit", "hit", "hit_chance" },
}

-- Emergency-only: allowed after compact+shrink if still overflowing.
local HORIZ_MERGE_GROUPS_EMERGENCY = {
    { "crit", "haste", "mastery", "versatility", "spellHit", "meleeHit", "rangedCrit", "rangedHit", "expertise", "spellPower", "healPower" },
}

--- Vertical HUD only: after primary/emergency, merge system+ilvl/GS and hit/crit/haste families harder (same row budget).
local VERTICAL_MERGE_GROUPS_AGGRESSIVE = {
    { "durability", "fps", "ping", "itemLevel", "gearScore" },
    {
        "spellHit", "meleeHit", "rangedHit", "hit", "hit_chance", "melee_hit", "spell_hit", "ranged_hit",
        "meleeCrit", "rangedCrit", "crit", "spellCrit", "critical_strike", "melee_crit", "spell_crit", "ranged_crit",
        "haste",
    },
}

--- Build a render list: each entry is {text, fs, key, keys}.
--- `keys` tracks merged source keys so we can preserve merge structure when
--- switching from full text to compact text.
local function _BuildRenderList(texts)
    local rl = {}
    for i = 1, activeLineCount do
        local key = activeLines[i].key
        rl[i] = { text = texts[i] or "", fs = activeLines[i].fs, key = key, keys = { key } }
    end
    return rl
end

--- Measure total width of a render list at the given font size (also applies
--- text+font to each FontString so GetStringWidth is accurate).
local function _MeasureRL(rl, fontSize)
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local total = 0
    for i, entry in ipairs(rl) do
        entry.fs:SetFont(fontPath, fontSize, "OUTLINE")
        entry.fs:SetText(entry.text)
        total = total + (entry.fs:GetStringWidth() or 0)
        if i > 1 then total = total + INFO_FRAME_GROUP_GAP end
    end
    return total
end

--- Match merge tokens (itemLevel/gearScore) to lines pinned under alias keys (e.g. gearscore).
local function _EntryKeyMatchesGroupKey(entryKey, gk)
    if entryKey == gk then return true end
    local canonE = _CanonicalIlvlGsRegistryKey(entryKey)
    return canonE ~= nil and canonE == gk
end

--- Try to merge entries from groupKeys into a single slot (the first one found).
--- Returns the new render list and whether a merge actually happened.
local function _TryMergeGroup(rl, groupKeys)
    local groupIdx = {}
    for i, entry in ipairs(rl) do
        for _, k in ipairs(groupKeys) do
            if _EntryKeyMatchesGroupKey(entry.key, k) then groupIdx[#groupIdx + 1] = i; break end
        end
    end
    if #groupIdx < 2 then return rl, false end

    local firstIdx = groupIdx[1]
    local parts, removeSet = {}, {}
    local mergedKeys = {}
    for _, idx in ipairs(groupIdx) do
        parts[#parts + 1] = rl[idx].text
        local entryKeys = rl[idx].keys or { rl[idx].key }
        for _, k in ipairs(entryKeys) do
            mergedKeys[#mergedKeys + 1] = k
        end
        if idx ~= firstIdx then removeSet[idx] = true end
    end
    rl[firstIdx].text = table.concat(parts, " | ")
    rl[firstIdx].keys = mergedKeys

    local newRl = {}
    for i, entry in ipairs(rl) do
        if not removeSet[i] then newRl[#newRl + 1] = entry end
    end
    return newRl, true
end

--- Always combine Item LvL + GearScore on one InfoFrame line when both are pinned.
local function _MergeIlvlAndGearScoreRenderList(rl)
    local idxs = {}
    for i, e in ipairs(rl) do
        if _CanonicalIlvlGsRegistryKey(e.key) then
            idxs[#idxs + 1] = i
        end
    end
    if #idxs < 2 then
        return rl
    end
    local firstIdx, secondIdx = idxs[1], idxs[2]
    local parts = { rl[firstIdx].text, rl[secondIdx].text }
    local mergedKeys = {}
    for _, idx in ipairs({ firstIdx, secondIdx }) do
        local entryKeys = rl[idx].keys or { rl[idx].key }
        for _, kk in ipairs(entryKeys) do
            mergedKeys[#mergedKeys + 1] = kk
        end
    end
    rl[firstIdx].text = table.concat(parts, " | ")
    rl[firstIdx].keys = mergedKeys
    local newRl = {}
    for i, entry in ipairs(rl) do
        if i ~= secondIdx then
            newRl[#newRl + 1] = entry
        end
    end
    return newRl
end

local function _IsIlvlOrGsKey(k)
    return _CanonicalIlvlGsRegistryKey(k) ~= nil
end

--- True when this merged chunk includes Dur / FPS / ping (short iLvl / G.S. only in that case).
local function _RlEntryHasSystemStat(entry)
    for _, k in ipairs(entry.keys or { entry.key }) do
        if k == "durability" or k == "fps" or k == "ping" then
            return true
        end
    end
    return false
end

--- After merge: iLvl / G.S. short only when this chunk's keys include Dur/FPS/ping (same merged segment).
local function _ApplyHybridIlvlGsTextsToRenderList(rl, fullByKey, compactByKey)
    local out = {}
    for i, entry in ipairs(rl) do
        local srcKeys = entry.keys or { entry.key }
        local useShortIlvlGs = _RlEntryHasSystemStat(entry)
        local parts = {}
        for _, k in ipairs(srcKeys) do
            if _IsIlvlOrGsKey(k) then
                if useShortIlvlGs then
                    parts[#parts + 1] = compactByKey[k] or fullByKey[k] or ""
                else
                    parts[#parts + 1] = fullByKey[k] or ""
                end
            else
                parts[#parts + 1] = fullByKey[k] or compactByKey[k] or ""
            end
        end
        out[i] = {
            fs = entry.fs,
            key = entry.key,
            keys = srcKeys,
            text = table.concat(parts, " | "),
        }
    end
    return out
end

--- Rebuild current render list texts from compact sources while preserving the
--- existing merged key structure.
local function _ApplyCompactTextsToRenderList(rl, compactByKey)
    local out = {}
    for i, entry in ipairs(rl) do
        local srcKeys = entry.keys or { entry.key }
        local parts = {}
        for _, k in ipairs(srcKeys) do
            parts[#parts + 1] = compactByKey[k] or ""
        end
        out[i] = {
            fs = entry.fs,
            key = entry.key,
            keys = srcKeys,
            text = table.concat(parts, " | "),
        }
    end
    return out
end

local function _ApplyMergeCascadeUntilFit(rl, mergeGroups, fontSize, availableW, measuredW)
    local out = rl
    local width = measuredW or _MeasureRL(out, fontSize)
    if width <= availableW then
        return out, width
    end
    for _, groupKeys in ipairs(mergeGroups) do
        if width <= availableW then break end
        local newRl, merged = _TryMergeGroup(out, groupKeys)
        if merged then
            out = newRl
            width = _MeasureRL(out, fontSize)
        end
    end
    return out, width
end

local function _ApplyMergeCascadeUntilRowCount(rl, mergeGroups, maxRows)
    local out = rl
    if #out <= maxRows then
        return out
    end
    for _, groupKeys in ipairs(mergeGroups) do
        if #out <= maxRows then break end
        local newRl, merged = _TryMergeGroup(out, groupKeys)
        if merged then
            out = newRl
        end
    end
    return out
end

local function _EntryIsIlvlGsOnly(entry)
    local keys = entry.keys or { entry.key }
    if #keys == 0 then return false end
    for _, kk in ipairs(keys) do
        if not _IsIlvlOrGsKey(kk) then
            return false
        end
    end
    return true
end

local function _TeardownVerticalScrollForStripLayout()
    if not frame then return end
    local content = frame.FluxInfoVertScrollContent
    if content then
        for i = 1, #linePool do
            local fs = linePool[i]
            if fs:GetParent() == content then
                fs:SetParent(frame)
                fs:ClearAllPoints()
                if fs.SetWordWrap then fs:SetWordWrap(false) end
                if fs.SetSpacing then fs:SetSpacing(0) end
                --- Do not SetWidth(0): horizontal strip needs natural width or text won't paint.
            end
        end
    end
    local sc = frame.FluxInfoVertScroll
    if sc then
        sc:Hide()
        sc:SetVerticalScroll(0)
    end
end

local function _EnsureVerticalScrollHost(parentFrame)
    if parentFrame.FluxInfoVertScroll then
        return parentFrame.FluxInfoVertScroll, parentFrame.FluxInfoVertScrollContent
    end
    local sc = _CreateFrame("ScrollFrame", nil, parentFrame)
    sc:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 2, -3)
    sc:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -2, 3)
    if sc.SetFrameLevel and parentFrame.GetFrameLevel then
        sc:SetFrameLevel(parentFrame:GetFrameLevel() + 5)
    end
    sc:EnableMouse(true)
    sc:EnableMouseWheel(true)
    sc:SetScript("OnMouseWheel", function(self, delta)
        local lo, hi = 0, self:GetVerticalScrollRange()
        local y = self:GetVerticalScroll() - (delta * 24)
        if y < lo then y = lo elseif y > hi then y = hi end
        self:SetVerticalScroll(y)
    end)
    local content = _CreateFrame("Frame", nil, sc)
    content:SetSize(100, 100)
    sc:SetScrollChild(content)
    parentFrame.FluxInfoVertScroll = sc
    parentFrame.FluxInfoVertScrollContent = content
    sc:Hide()
    return sc, content
end

local function _VerticalTryFitRowBudget(rl, maxRows)
    if #rl <= maxRows then return rl end
    rl = _ApplyMergeCascadeUntilRowCount(rl, HORIZ_MERGE_GROUPS_PRIMARY, maxRows)
    if #rl <= maxRows then return rl end
    rl = _ApplyMergeCascadeUntilRowCount(rl, VERTICAL_MERGE_GROUPS_AGGRESSIVE, maxRows)
    if #rl <= maxRows then return rl end
    rl = _ApplyMergeCascadeUntilRowCount(rl, HORIZ_MERGE_GROUPS_EMERGENCY, maxRows)
    return rl
end

local function _ApplyVerticalDynamicMergeLayout()
    if activeLineCount == 0 or not frame then return end

    local frameH = (frame:GetHeight() or FRAME_HEIGHT)
    --- Keep less hidden safety margin so near-full-size text is preferred.
    local usable = math.max(12, frameH - 8)
    local frameW = (frame:GetWidth() or 200)
    -- Use real drawable width for wrapped text (old math left too much unused right-side space).
    local availableW = math.max(40, frameW - (INFO_FRAME_TEXT_PAD_X * 2) - 2)
    local textPadW = math.max(24, availableW)
    local baseFont = VERTICAL_FONT_BASE
    local minFont = math.max(VERTICAL_FONT_MIN, baseFont * 0.8)

    local fullTexts = {}
    local compactByKey, fullByKey = {}, {}
    for i = 1, activeLineCount do
        local key = activeLines[i].key
        local canon = _CanonicalIlvlGsRegistryKey(key)
        if canon then
            local reg = STAT_REGISTRY[canon]
            if reg and type(reg.getText) == "function" then
                local f, c = reg.getText()
                fullByKey[key] = f or ""
                compactByKey[key] = (c and c ~= "") and c or fullByKey[key]
            else
                fullByKey[key] = _GetLineFullText(activeLines[i])
                compactByKey[key] = _GetLineCompactText(activeLines[i])
            end
        else
            fullByKey[key] = _GetLineFullText(activeLines[i])
            compactByKey[key] = _GetLineCompactText(activeLines[i])
        end
        if _IsIlvlOrGsKey(key) then
            fullTexts[i] = compactByKey[key]
        else
            fullTexts[i] = fullByKey[key]
        end
    end

    local rl = _BuildRenderList(fullTexts)
    local useFont = baseFont

    local function _MeasureVerticalMaxWidthUnwrapped(list, fontSize)
        local maxW = 0
        for _, entry in ipairs(list) do
            local fs = entry.fs
            if fs.SetWordWrap then fs:SetWordWrap(false) end
            if fs.SetWidth then fs:SetWidth(0) end
            fs:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
            fs:SetText(entry.text)
            local w = fs:GetStringWidth()
            if not (issecretvalue and issecretvalue(w)) and (w or 0) > maxW then
                maxW = w
            end
        end
        return maxW
    end

    local function _WidthFitsUnwrapped(list, fontSize)
        return _MeasureVerticalMaxWidthUnwrapped(list, fontSize) <= availableW + 0.5
    end

    local n = #rl
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local lineHeights = {}
    --- Always use the same gap as horizontal merged segments; scroll instead of shrinking row spacing.
    local chosenGap = INFO_FRAME_VERTICAL_LINE_GAP
    local nbsp = string.char(194, 160)

    --- Keep "StatName: value" as one unbreakable pair so label/value never split across lines.
    local function _KeepLabelValueTogether(txt)
        if not txt or txt == "" then return txt end
        return (txt:gsub(":%s+", ":" .. nbsp))
    end

    local function applyRowFontsAndWrapHeights(gapForMeasure)
        local total = 0
        n = #rl
        for i = 1, n do
            local entry = rl[i]
            local fs = entry.fs
            local fSize = useFont
            if _EntryIsIlvlGsOnly(entry) then
                fSize = math.max(minFont, useFont - ILVL_GS_SECONDARY_FONT_SHRINK)
            end
            fs:SetFont(fontPath, fSize, "OUTLINE")
            fs:SetWidth(textPadW)
            if fs.SetWordWrap then fs:SetWordWrap(true) end
            if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
            if fs.SetSpacing then fs:SetSpacing(gapForMeasure) end
            fs:SetText(_KeepLabelValueTogether(entry.text))
            -- GetStringHeight is a secret number while this update is tainted (12.1).
            -- math.max cannot convert it. Fall back to the font size.
            local measuredH = fs:GetStringHeight()
            local plainH = (issecretvalue and issecretvalue(measuredH)) and (fSize + 2) or (measuredH or 0)
            local lh = math.max(fSize + 2, plainH)
            lineHeights[i] = lh
            total = total + lh + (i > 1 and gapForMeasure or 0)
        end
        return total
    end

    local function fitCurrentListBeforeScroll()
        useFont = baseFont
        rl = _ApplyHybridIlvlGsTextsToRenderList(rl, fullByKey, compactByKey)
        --- Keep base font whenever wrapped layout already fits.
        local h = applyRowFontsAndWrapHeights(chosenGap)
        local overflowTolerance = chosenGap + 2
        --- Prefer downscaling before introducing scroll.
        while useFont > minFont and h > usable + overflowTolerance do
            useFont = math.max(minFont, useFont - VERTICAL_FONT_SCALE_STEP)
            h = applyRowFontsAndWrapHeights(chosenGap)
        end
        return h, (h > usable + overflowTolerance)
    end

    if #rl > VERTICAL_MAX_MERGED_ROWS then
        --- Merge first once row count exceeds cap; only then consider downscale/scroll.
        local merged = _MergeIlvlAndGearScoreRenderList(_BuildRenderList(fullTexts))
        local rowBudgetStep = VERTICAL_MIN_LINE_GAP + baseFont + 2
        local targetMaxRows = math.min(VERTICAL_MAX_MERGED_ROWS, math.max(1, math.floor((usable - 8) / math.max(8, rowBudgetStep))))
        rl = _VerticalTryFitRowBudget(merged, targetMaxRows)
    end
    local contentHeight, needScroll = fitCurrentListBeforeScroll()

    local renderedFS = {}
    if needScroll then
        local sc, content = _EnsureVerticalScrollHost(frame)
        local oldScroll = sc:GetVerticalScroll() or 0
        sc:Show()
        content:SetWidth(textPadW + (INFO_FRAME_TEXT_PAD_X * 2))
        local y = -chosenGap
        for i = 1, n do
            local entry = rl[i]
            local fs = entry.fs
            renderedFS[fs] = true
            fs:SetParent(content)
            fs:Show()
            fs:ClearAllPoints()
            local fSize = useFont
            if _EntryIsIlvlGsOnly(entry) then
                fSize = math.max(minFont, useFont - ILVL_GS_SECONDARY_FONT_SHRINK)
            end
            fs:SetFont(fontPath, fSize, "OUTLINE")
            fs:SetWidth(textPadW)
            if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
            if fs.SetWordWrap then fs:SetWordWrap(true) end
            if fs.SetSpacing then fs:SetSpacing(chosenGap) end
            fs:SetText(_KeepLabelValueTogether(entry.text))
            local lh = lineHeights[i]
            fs:SetPoint("TOPLEFT", content, "TOPLEFT", INFO_FRAME_TEXT_PAD_X, y)
            _BindInfoFrameEntryTooltip(fs, entry, fontPath, fSize)
            y = y - lh - chosenGap
        end
        content:SetHeight(math.max(1, -y + chosenGap))
        local lo, hi = 0, sc:GetVerticalScrollRange()
        if oldScroll < lo then oldScroll = lo elseif oldScroll > hi then oldScroll = hi end
        sc:SetVerticalScroll(oldScroll)
    else
        local sc = frame.FluxInfoVertScroll
        if sc then
            sc:Hide()
        end
        for i = 1, #linePool do
            local fs = linePool[i]
            if fs:GetParent() ~= frame then
                fs:SetParent(frame)
            end
        end
        --- TOP + CENTER anchoring breaks wrapped FontStrings; stack from TOPLEFT so lines stay visible.
        --- Match top inset to inter-row gap so space above first group equals space between groups.
        local topPad = math.max(chosenGap, math.floor((usable - contentHeight) / 2))
        local y = -topPad
        for i = 1, n do
            local entry = rl[i]
            local fs = entry.fs
            renderedFS[fs] = true
            fs:Show()
            fs:ClearAllPoints()
            local fSize = useFont
            if _EntryIsIlvlGsOnly(entry) then
                fSize = math.max(minFont, useFont - ILVL_GS_SECONDARY_FONT_SHRINK)
            end
            fs:SetFont(fontPath, fSize, "OUTLINE")
            fs:SetWidth(textPadW)
            if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
            if fs.SetWordWrap then fs:SetWordWrap(true) end
            if fs.SetSpacing then fs:SetSpacing(chosenGap) end
            fs:SetText(_KeepLabelValueTogether(entry.text))
            fs:SetPoint("TOPLEFT", frame, "TOPLEFT", INFO_FRAME_TEXT_PAD_X, y)
            _BindInfoFrameEntryTooltip(fs, entry, fontPath, fSize)
            y = y - lineHeights[i] - chosenGap
        end
    end

    for i = 1, activeLineCount do
        local fs = activeLines[i].fs
        if not renderedFS[fs] then
            _ClearInfoFrameEntryTooltip(fs)
            fs:Hide()
        end
    end

    if durabilityTooltipFrame then
        durabilityTooltipFrame:Hide()
    end
end

local function ApplyHorizontalStripTextLayoutDynamic(fontSize, padLeft, gap)
    if activeLineCount == 0 or not frame then return end
    _TeardownVerticalScrollForStripLayout()
    local availableW = math.max(40, (frame:GetWidth() or 0) - (padLeft * 2))
    local fontPath = "Fonts\\FRIZQT__.TTF"

    local lineFull, lineCompact = {}, {}
    local compactByKey, fullByKey = {}, {}
    local textsShort = {}
    for i = 1, activeLineCount do
        local key = activeLines[i].key
        local canon = _CanonicalIlvlGsRegistryKey(key)
        if canon then
            local reg = STAT_REGISTRY[canon]
            if reg and type(reg.getText) == "function" then
                local f, c = reg.getText()
                lineFull[i] = f or ""
                lineCompact[i] = (c and c ~= "") and c or lineFull[i]
            else
                lineFull[i] = _GetLineFullText(activeLines[i])
                lineCompact[i] = _GetLineCompactText(activeLines[i])
            end
        else
            lineFull[i] = _GetLineFullText(activeLines[i])
            lineCompact[i] = _GetLineCompactText(activeLines[i])
        end
        compactByKey[key] = lineCompact[i]
        fullByKey[key] = lineFull[i]
        if _IsIlvlOrGsKey(key) then
            local c = lineCompact[i]
            textsShort[i] = (c and c ~= "") and c or lineFull[i]
        else
            textsShort[i] = lineFull[i]
        end
    end

    local renderedFS = {}

    local function _RunHorizontalMergePipeline(texts, useFontStart)
        local rl = _BuildRenderList(texts)
        rl = _MergeIlvlAndGearScoreRenderList(rl)
        local useFont = useFontStart
        -- Keep the current list/font measurement within this transaction.
        -- Merge, compact, hybrid and font changes each take a fresh sample.
        local width
        rl, width = _ApplyMergeCascadeUntilFit(rl, HORIZ_MERGE_GROUPS_PRIMARY, useFont, availableW)
        if width > availableW then
            rl = _ApplyCompactTextsToRenderList(rl, compactByKey)
            width = _MeasureRL(rl, useFont)
        end
        while useFont > 7 and width > availableW do
            useFont = useFont - 1
            width = _MeasureRL(rl, useFont)
        end
        if width > availableW then
            rl = _ApplyMergeCascadeUntilFit(rl, HORIZ_MERGE_GROUPS_EMERGENCY, useFont, availableW, width)
        end
        return rl, useFont
    end

    local rl, useFont = _RunHorizontalMergePipeline(textsShort, fontSize)
    rl = _ApplyHybridIlvlGsTextsToRenderList(rl, fullByKey, compactByKey)
    local width = _MeasureRL(rl, useFont)
    while useFont > 7 and width > availableW do
        useFont = useFont - 1
        width = _MeasureRL(rl, useFont)
    end
    if width > availableW then
        rl = _ApplyMergeCascadeUntilFit(rl, HORIZ_MERGE_GROUPS_EMERGENCY, useFont, availableW, width)
    end
    local prev = nil
    for _, entry in ipairs(rl) do
        renderedFS[entry.fs] = true
        entry.fs:Show()
        entry.fs:ClearAllPoints()
        if entry.fs.SetSpacing then entry.fs:SetSpacing(0) end
        if not prev then
            entry.fs:SetPoint("LEFT", frame, "LEFT", padLeft, 0)
        else
            entry.fs:SetPoint("LEFT", prev, "RIGHT", gap, 0)
        end
        entry.fs:SetPoint("TOP", frame, "TOP", 0, -2)
        entry.fs:SetPoint("BOTTOM", frame, "BOTTOM", 0, 2)
        entry.fs:SetFont(fontPath, useFont, "OUTLINE")
        entry.fs:SetText(entry.text)
        _BindInfoFrameEntryTooltip(entry.fs, entry, fontPath, useFont)
        prev = entry.fs
    end

    for i = 1, activeLineCount do
        local fs = activeLines[i].fs
        if not renderedFS[fs] then
            _ClearInfoFrameEntryTooltip(fs)
            fs:Hide()
        end
    end

    if durabilityTooltipFrame then
        durabilityTooltipFrame:Hide()
    end
end

local function ApplyMinimapTopStripTextLayout()
    if activeLineCount == 0 then return end
    local fs = GetMinimapTopStripFontSize()
    local pad = (fs < STRIP_FONT_SIZE) and 4 or 6
    local gap = (fs < STRIP_FONT_SIZE) and INFO_FRAME_GROUP_GAP_COMPACT or INFO_FRAME_GROUP_GAP
    ApplyHorizontalStripTextLayoutDynamic(fs, pad, gap)
end

local function ApplyHorizontalStripTextLayout()
    if activeLineCount == 0 then return end
    ApplyHorizontalStripTextLayoutDynamic(STRIP_FONT_SIZE, 6, INFO_FRAME_GROUP_GAP)
end

--- Worst-case horizontal cluster width (stable — does not change when FPS/ping tick).
--- Item level is always the short iLvl label. GearScore still uses its full string.
local function MeasureStableIntegratedClusterWidth()
    if activeLineCount == 0 then return 120 end
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local gap = INFO_FRAME_GROUP_GAP
    local saved = {}
    for i = 1, activeLineCount do
        local fs = activeLines[i].fs
        saved[i] = fs:GetText()
        fs:SetFont(fontPath, STRIP_FONT_SIZE, "OUTLINE")
    end
    local worstCaseTexts = {
        durability = "|cff33ff99100|r dur",
        fps = "|cff33ff99333|r fps",
        ping = "|cff33ff999999|r ms",
        itemLevel = "iLvl: 999.9",
        gearScore = "GearScore: 99999",
    }
    for i = 1, activeLineCount do
        local key = activeLines[i].key
        local wc = worstCaseTexts[key]
        local live = InfoFrame._camelotLiveCombatText and InfoFrame._camelotLiveCombatText[key]
        wc = wc or (live and live.sample)
        if wc then
            activeLines[i].fs:SetText(wc)
        else
            local reg = STAT_REGISTRY[key]
            if reg then
                activeLines[i].fs:SetText(string.format("|cffffffff9999|r %s", reg.label))
            end
        end
    end
    local total = 0
    for i = 1, activeLineCount do
        if i > 1 then total = total + gap end
        total = total + (activeLines[i].fs:GetStringWidth() or 0)
    end
    local w = math.max(math.ceil(total + 24), 120)
    for i = 1, activeLineCount do
        local text = saved[i]
        if issecretvalue and issecretvalue(text) then activeLines[i].fs:SetText(text)
        else activeLines[i].fs:SetText(text or "") end
    end
    return w
end

--- Integrated location 1: frame stays full micro/status width; cluster centered using stable total width (no jitter).
local function ApplyHorizontalStripTextLayoutCenteredStable()
    if activeLineCount == 0 or not frame then return end
    if not cachedStableIntegratedClusterWidth then
        cachedStableIntegratedClusterWidth = MeasureStableIntegratedClusterWidth()
    end
    local clusterW = cachedStableIntegratedClusterWidth
    local fw = frame:GetWidth()
    local pad = math.max(6, (fw - clusterW) / 2)
    ApplyHorizontalStripTextLayoutDynamic(STRIP_FONT_SIZE, pad, 8)
end

local function ApplyIntegratedStripTextLayoutRouter()
    if not frame then
        return
    end
    if frame.FluxAnchoredByStatusBarColumn then
        ApplyHorizontalStripTextLayout()
    elseif frame.FluxIntegratedLoc1FullWidthCentered then
        ApplyHorizontalStripTextLayoutCenteredStable()
    else
        ApplyHorizontalStripTextLayout()
    end
end

--- Integrated strip: no FluxBorder frame art on Info (shared status chrome); keep same class/atlas backdrop fill as pos1 / detached.
--- First column inside Location 2 strip: MEDIUM + high frame level so mouse hits Info before adjacent StatusBars.
local INFO_STATUSBAR_COLUMN_FRAME_LEVEL = 30

local function ApplyStatusIntegratedStripVisual(enable)
    if not frame then
        return
    end
    if enable then
        if not stripVisualActive then
            stripVisualActive = true
        end
        if FluxBorder then
            FluxBorder:RemoveFrom(frame)
        end
        RefreshIntegratedStripBackdropVisual()
        if frame.FluxAnchoredByStatusBarColumn then
            frame:SetFrameStrata("MEDIUM")
            frame:SetFrameLevel(INFO_STATUSBAR_COLUMN_FRAME_LEVEL)
            frame:EnableMouse(true)
        else
            frame:SetFrameStrata("MEDIUM")
            frame:SetFrameLevel(7)
            frame:EnableMouse(false)
        end
        if durabilityTooltipFrame then
            durabilityTooltipFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
        end
        ApplyIntegratedStripTextLayoutRouter()
    else
        if stripVisualActive then
            stripVisualActive = false
            HideIntegratedStripBackdropVisual()
            if FluxBorder then
                FluxBorder:ApplyTo(frame, 0, -4, -1, -4)
                FluxBorder:SetClassColor(frame, 1, true)
            end
            frame:SetFrameStrata("MEDIUM")
            frame:SetFrameLevel(7)
            frame:EnableMouse(false)
            ApplyVerticalStripTextLayout()
        end
    end
end

--- Interior top of Minimap: horizontal strip only — no FluxBorder / backdrop; stays below Flux minimap border art.
local function GetMinimapInteriorStripFrameLevel()
    local mini = _G.Minimap
    if not mini then
        return 7
    end
    local bf = mini.FluxBorderFrame
    local bz = bf and bf.GetFrameLevel and bf:GetFrameLevel()
    if type(bz) == "number" and bz > 1 then
        return math.max(1, bz - 1)
    end
    local ml = mini:GetFrameLevel()
    if type(ml) == "number" then
        return math.max(1, ml + 1)
    end
    return 2
end

local function ApplyMinimapTopStripVisual(enable)
    if not frame then
        return
    end
    if enable then
        minimapTopVisualActive = true
        if FluxBorder then
            FluxBorder:RemoveFrom(frame)
        end
        HideIntegratedStripBackdropVisual()
        frame:SetFrameStrata((_G.Minimap and _G.Minimap:GetFrameStrata()) or "MEDIUM")
        frame:SetFrameLevel(GetMinimapInteriorStripFrameLevel())
        frame:EnableMouse(true)
        if durabilityTooltipFrame then
            durabilityTooltipFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
        end
        ApplyMinimapTopStripTextLayout()
    else
        if minimapTopVisualActive then
            minimapTopVisualActive = false
            if FluxBorder then
                FluxBorder:ApplyTo(frame, 0, -4, -1, -4)
                FluxBorder:SetClassColor(frame, 1, true)
            end
            frame:SetFrameStrata("MEDIUM")
            frame:SetFrameLevel(7)
            frame:EnableMouse(false)
            ApplyVerticalStripTextLayout()
        end
    end
end

local function SyncStripVisualWithPlacement()
    local p = GetPlacement()
    if p == "minimapTop" then
        if stripVisualActive then
            ApplyStatusIntegratedStripVisual(false)
        end
        ApplyMinimapTopStripVisual(true)
    elseif p == "statusIntegrated" then
        if minimapTopVisualActive then
            ApplyMinimapTopStripVisual(false)
        end
        ApplyStatusIntegratedStripVisual(true)
    else
        if minimapTopVisualActive then
            ApplyMinimapTopStripVisual(false)
        end
        ApplyStatusIntegratedStripVisual(false)
    end
    --- Status-integrated: FluxStatusBar.NotifyUnifiedUIAndPVPThrottled already calls UpdateStatusBarBorder with UpdateBorder.
    if p ~= "statusIntegrated" then
        if FluxUnifiedBorder and FluxUnifiedBorder.UpdateStatusBarBorder then
            pcall(FluxUnifiedBorder.UpdateStatusBarBorder)
        end
    end
end

-- ============================================================================
-- COLOR FUNCTIONS (matching SimpleFPSPing)
-- ============================================================================

local function GetFPSColor(fps)
    if fps < 30 then return 1, 0.3, 0.3 end      -- Red
    if fps < 60 then return 1, 1, 0.3 end          -- Yellow
    return 0.3, 1, 0.3                            -- Green
end

local function GetPingColor(ping)
    if ping > 150 then return 1, 0.3, 0.3 end     -- Red
    if ping > 100 then return 1, 1, 0.3 end       -- Yellow
    return 0.3, 1, 0.3                            -- Green
end

local function GetDurabilityColor(durability)
    if durability < 25 then return 1, 0.3, 0.3 end  -- Red
    if durability < 50 then return 1, 1, 0.3 end   -- Yellow
    return 0.3, 1, 0.3                            -- Green
end

-- Get average durability percentage from all equipped items.
-- Flux idle FPS: cache for ~1s (matches Info stats ticker) and invalidate on equip/alerts.
local _durCachePct = nil
local _durCacheAt = 0
local DUR_CACHE_TTL = 1.0

local function InvalidateDurabilityCache()
    _durCachePct = nil
    _durCacheAt = 0
end

local function GetDurabilityPercentage()
    local now = (GetTime and GetTime()) or 0
    if _durCachePct ~= nil and (now - _durCacheAt) < DUR_CACHE_TTL then
        return _durCachePct
    end

    local totalDurability = 0
    local totalItems = 0
    
    -- Compatibility: Use constants if available, otherwise use slot numbers (0-18)
    local firstSlot = INVSLOT_FIRST_EQUIPPED or 0
    local lastSlot = INVSLOT_LAST_EQUIPPED or 18
    
    for i = firstSlot, lastSlot do
        local current, maximum = GetInventoryItemDurability(i)
        if current and maximum and maximum > 0 then
            local itemDurability = (current / maximum) * 100
            totalDurability = totalDurability + itemDurability
            totalItems = totalItems + 1
        end
    end
    
    local pct
    if totalItems == 0 then
        pct = 100 -- No durability items equipped
    else
        pct = math.floor(totalDurability / totalItems)
    end
    _durCachePct = pct
    _durCacheAt = now
    return pct
end

-- ============================================================================
-- MERGE GROUPS + PER-KEY TEXT HELPER
-- Defined here so all color/durability helpers above are already in scope.
-- ============================================================================

local function _KeyOrder(k)
    local sys = { durability = 1, fps = 2, ping = 3, itemLevel = 4, gearScore = 5 }
    if sys[k] then return sys[k] end
    local reg = STAT_REGISTRY[k]
    return reg and (reg.order + 100) or 200
end

--- Compute full and compact text strings for one stat key (no UI reads).
local function _GetKeyText(key)
    if key == "durability" then
        local db = GetInfoFrameCharDB and GetInfoFrameCharDB()
        if db and db.showDurability == false then
            return "", ""
        end
        local dur = GetDurabilityPercentage()
        local r, g, b = GetDurabilityColor(dur)
        local colored = string.format("|cff%02x%02x%02x%d%%|r", r*255, g*255, b*255, dur)
        local full = "Dur: " .. colored
        return full, full
    elseif key == "fps" then
        local fps = GetFramerate()
        local r, g, b = GetFPSColor(fps)
        local colored = string.format("|cff%02x%02x%02x%.0f|r", r*255, g*255, b*255, fps)
        local full = "FPS: " .. colored
        return full, full
    elseif key == "ping" then
        local _, _, latencyHome, latencyWorld = GetNetStats()
        local latency = latencyWorld or latencyHome or 0
        local r, g, b = GetPingColor(latency)
        local colored = string.format("|cff%02x%02x%02x%d ms|r", r*255, g*255, b*255, latency)
        local full = "Ping: " .. colored
        return full, full
    else
        local reg = STAT_REGISTRY[key]
        if reg then
            -- Registry entries with getText() return pre-formatted (full, compact)
            -- strings directly (e.g. spellPower with combined Dmg / Heal).
            if type(reg.getText) == "function" then
                return reg.getText()
            end
            -- get() may return (value) or (value, colorHex) where colorHex is
            -- a 6-char hex string like "ff8000" from the CSC school-color helpers.
            -- IMPORTANT: must call reg.get() in a plain assignment — `a and b()`
            -- collapses multi-returns to a single value, dropping colorHex.
            local val, colorHex
            if type(reg.get) == "function" then
                val, colorHex = reg.get()
            end
            local sharedCombatStat = InfoFrame._IsCamelotClient()
                and (key == "crit" or key == "haste" or key == "meleeHit")
            if sharedCombatStat then
                InfoFrame._camelotLiveCombatText = InfoFrame._camelotLiveCombatText or {}
                local live = val == nil and InfoFrame._CamelotLiveCombatText(key) or nil
                local previous = InfoFrame._camelotLiveCombatText[key]
                if (previous and previous.sample) ~= (live and live.sample) then
                    cachedStableIntegratedClusterWidth = nil
                    InfoFrame._screenTopLeftWidth = nil
                end
                InfoFrame._camelotLiveCombatText[key] = live
                if live then return live.sample, live.sample end
            end
            if val == nil and not sharedCombatStat and InfoFrame.ReadForeverDisplayText then
                val = InfoFrame.ReadForeverDisplayText(key)
            end
            if val == nil and not sharedCombatStat then
                local cache = InfoFrame._foreverStatCache
                if cache and cache[key] ~= nil then
                    val = cache[key]
                end
            end
            local coloredValue
            if val ~= nil then
                local hex = _NormalizeHexColor(colorHex) or "ffffff"
                local fmt = reg.fmt or "%s"
                if type(val) == "string" then
                    fmt = "%s"
                end
                local okFmt, formatted = pcall(string.format, "|cff%s" .. fmt .. "|r", hex, val)
                if okFmt then
                    coloredValue = formatted
                else
                    coloredValue = string.format("|cffffffff%s|r", tostring(val))
                end
            else
                coloredValue = "|cff888888--|r"
            end
            local full = string.format("%s: %s", reg.label or key, coloredValue)
            return full, full
        end
    end
    return "", ""
end

-- Get repair cost (returns cost in copper, isEstimate)
-- Calculates repair cost without needing to visit a vendor when possible.
local function GetRepairCost()
    -- First try GetRepairAllCost if at a merchant (most accurate)
    local success, cost, canRepair = pcall(GetRepairAllCost)
    if success and cost and cost > 0 then
        return cost, false
    end

    -- Try per-item repair API (works even outside vendor on most clients).
    local totalCost = 0
    local firstSlot = INVSLOT_FIRST_EQUIPPED or 0
    local lastSlot = INVSLOT_LAST_EQUIPPED or 18
    local sawRepairable = false
    for i = firstSlot, lastSlot do
        if type(GetInventoryItemRepairCost) == "function" then
            local ok, c = pcall(GetInventoryItemRepairCost, i)
            if ok and type(c) == "number" then
                if c > 0 then
                    totalCost = totalCost + c
                    sawRepairable = true
                end
            end
        end
    end
    if sawRepairable then
        return totalCost, false
    end

    -- Classic-compatible off-vendor scan via GameTooltip:SetInventoryItem return value.
    _repairScanTooltip = _repairScanTooltip or CreateFrame("GameTooltip", "FluxInfoRepairScanTooltip", UIParent, "GameTooltipTemplate")
    if _repairScanTooltip and _repairScanTooltip.SetOwner then
        _repairScanTooltip:SetOwner(WorldFrame or UIParent, "ANCHOR_NONE")
    end
    totalCost = 0
    for i = firstSlot, lastSlot do
        local current, maximum = GetInventoryItemDurability(i)
        if current and maximum and maximum > 0 and current < maximum and _repairScanTooltip and _repairScanTooltip.SetInventoryItem then
            local ok, _, _, repairCost = pcall(_repairScanTooltip.SetInventoryItem, _repairScanTooltip, "player", i)
            if ok and type(repairCost) == "number" and repairCost > 0 then
                totalCost = totalCost + repairCost
                sawRepairable = true
            end
        end
    end
    if sawRepairable and totalCost > 0 then
        return totalCost, false
    end

    -- Broker_DurabilityInfo-style fallback: read per-slot repairCost from tooltip data.
    totalCost = 0
    for i = firstSlot, lastSlot do
        local current, maximum = GetInventoryItemDurability(i)
        if current and maximum and maximum > 0 and current < maximum then
            if C_TooltipInfo and type(C_TooltipInfo.GetInventoryItem) == "function" then
                local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", i)
                if ok and type(data) == "table" and type(data.repairCost) == "number" and data.repairCost > 0 then
                    totalCost = totalCost + data.repairCost
                    sawRepairable = true
                end
            end
        end
    end
    if sawRepairable and totalCost > 0 then
        return totalCost, false
    end

    -- Fallback estimate from durability + item info when direct API is unavailable.
    totalCost = 0
    for i = firstSlot, lastSlot do
        local current, maximum = GetInventoryItemDurability(i)
        if current and maximum and maximum > 0 and current < maximum then
            -- Get item info to calculate repair cost
            local itemLink = GetInventoryItemLink("player", i)
            if itemLink then
                local itemName, itemLink2, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, 
                      itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink)
                local durabilityLost = 1.0 - (current / maximum)
                local qualityMultiplier = 1.0
                if itemQuality then
                    if itemQuality == 2 then qualityMultiplier = 1.1
                    elseif itemQuality == 3 then qualityMultiplier = 1.25
                    elseif itemQuality == 4 then qualityMultiplier = 1.5
                    elseif itemQuality == 5 then qualityMultiplier = 2.0
                    elseif itemQuality == 6 then qualityMultiplier = 2.5
                    end
                end

                local sellEstimate = nil
                local ilvlEstimate = nil
                -- Sell-price based estimate (conservative coefficient).
                if type(itemSellPrice) == "number" and itemSellPrice > 0 then
                    sellEstimate = math.floor(itemSellPrice * 0.09 * durabilityLost * qualityMultiplier)
                end
                -- Item-level based estimate.
                if itemLevel and itemLevel > 0 then
                    local baseCost = itemLevel * 0.5 * qualityMultiplier * durabilityLost * 100
                    ilvlEstimate = math.floor(baseCost)
                end
                -- Use the lower valid estimate to avoid overpricing vs vendor.
                local itemCost = nil
                if sellEstimate and sellEstimate > 0 and ilvlEstimate and ilvlEstimate > 0 then
                    itemCost = math.min(sellEstimate, ilvlEstimate)
                else
                    itemCost = (sellEstimate and sellEstimate > 0 and sellEstimate)
                        or (ilvlEstimate and ilvlEstimate > 0 and ilvlEstimate)
                end
                -- Last-resort baseline so damaged items never report unknown/free.
                if (not itemCost or itemCost <= 0) then
                    itemCost = math.floor((maximum - current) * 5)
                end

                if itemCost and itemCost > 0 then
                    totalCost = totalCost + math.max(1, itemCost)
                    sawRepairable = true
                end
            end
        end
    end

    if totalCost > 0 then
        return totalCost, true
    end
    -- If we reached here and durability is below 100, return a tiny non-zero estimate
    -- so the tooltip avoids "unavailable" when items are clearly damaged.
    local dur = GetDurabilityPercentage and GetDurabilityPercentage() or nil
    if dur and dur < 100 then
        return math.max(1, (100 - dur) * 25), true
    end
    return nil -- No repairs needed / full durability
end

-- Format money (copper to gold/silver/copper)
local function FormatMoney(copper)
    if not copper or copper == 0 then
        return "Free"
    end
    
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperRemainder = copper % 100
    
    local parts = {}
    if gold > 0 then
        -- Gold symbol texture
        table.insert(parts, string.format("%d|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t", gold))
    end
    if silver > 0 then
        -- Silver symbol texture
        table.insert(parts, string.format("%d|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t", silver))
    end
    if copperRemainder > 0 or #parts == 0 then
        -- Copper symbol texture
        table.insert(parts, string.format("%d|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t", copperRemainder))
    end
    
    return table.concat(parts, " ")
end

_TOOLTIP_DISABLED_KEYS = {
}

_tooltipMeasureFS = nil
_tooltipKeyToStatFrame = {}
_tooltipKeyToStatFrameList = {}
_tooltipKeyToStatFrameAt = 0
_lastInfoTooltipKey = nil
_hoveredInfoEntryFS = nil
local _fluxInfoTooltipAnchor = nil
_UpdateInfoFrameEntryTooltip = function() end
_lastPerfTooltipRefreshAt = 0
_lastStatTooltipRetryAt = 0
_lastTooltipCacheFlushPinsAt = 0
_infoTooltipHoverPollAt = 0
local _infoTooltipTicker = nil

local function _StopInfoTooltipHoverPoll()
	if _infoTooltipTicker then
		_infoTooltipTicker:Cancel()
		_infoTooltipTicker = nil
	end
	_infoTooltipHoverPollAt = 0
end

local function _StartInfoTooltipHoverPoll()
	_StopInfoTooltipHoverPoll()
	if not (C_Timer and C_Timer.NewTicker) then return end
	_infoTooltipTicker = C_Timer.NewTicker(0.05, function()
		local fs = _hoveredInfoEntryFS
		if not fs or not fs:IsShown() then
			_StopInfoTooltipHoverPoll()
			return
		end
		_UpdateInfoFrameEntryTooltip(fs)
	end)
end

function _GetTooltipMeasureFS()
    if _tooltipMeasureFS and _tooltipMeasureFS.GetStringWidth then
        return _tooltipMeasureFS
    end
    local host = frame or UIParent
    _tooltipMeasureFS = host:CreateFontString(nil, "OVERLAY")
    _tooltipMeasureFS:Hide()
    if _tooltipMeasureFS.SetWordWrap then _tooltipMeasureFS:SetWordWrap(false) end
    if _tooltipMeasureFS.SetNonSpaceWrap then _tooltipMeasureFS:SetNonSpaceWrap(false) end
    return _tooltipMeasureFS
end

function _MeasureTooltipTextWidth(text, fontPath, fontSize, fontFlags)
    local fs = _GetTooltipMeasureFS()
    fs:SetFont(fontPath or "Fonts\\FRIZQT__.TTF", fontSize or 11, fontFlags or "OUTLINE")
    fs:SetText(text or "")
    local w = fs:GetStringWidth()
    if w == nil or (issecretvalue and issecretvalue(w)) then
        return nil
    end
    return w
end

function _SplitMergedSegments(text)
    local segments = {}
    local src = tostring(text or "")
    local startPos = 1
    while true do
        local s, e = string.find(src, " | ", startPos, true)
        if not s then
            segments[#segments + 1] = string.sub(src, startPos)
            break
        end
        segments[#segments + 1] = string.sub(src, startPos, s - 1)
        startPos = e + 1
    end
    if #segments == 0 then
        segments[1] = src
    end
    return segments
end

_tooltipLabelKeyMap = nil
function _BuildTooltipLabelKeyMap()
    if _tooltipLabelKeyMap then return _tooltipLabelKeyMap end
    local map = {}
    for key, reg in pairs(STAT_REGISTRY) do
        if reg and type(reg.label) == "string" and reg.label ~= "" then
            map[reg.label:lower()] = key
        end
    end
    map["dur"] = "durability"
    map["fps"] = "fps"
    map["ping"] = "ping"
    map["item lvl"] = "itemLevel"
    map["ilvl"] = "itemLevel"
    map["g.s."] = "gearScore"
    map["gs"] = "gearScore"
    map["g.s"] = "gearScore"
    map["spell"] = "spellPower"
    map["s.p."] = "spellPower"
    map["heal"] = "healPower"
    map["haste"] = "haste"
    map["spell haste"] = "haste"
    map["mana regen"] = "mp5"
    map["mana regeneration"] = "mp5"
    map["mp5"] = "mp5"
    _tooltipLabelKeyMap = map
    return map
end

function _StripTooltipCodes(s)
    if type(s) ~= "string" then return "" end
    return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

function _InferKeyFromSegmentText(seg)
    local clean = _StripTooltipCodes(seg)
    clean = clean:gsub("\194\160", " ")
    local label = clean:match("^%s*([^:]+):") or clean:match("^%s*([%w%.]+)")
    if not label then return nil end
    label = label:gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if label == "gs" or label == "g.s" or label == "g.s." then
        return "gearScore"
    end
    local map = _BuildTooltipLabelKeyMap()
    return _CanonicalIlvlGsRegistryKey(map[label] or label) or map[label]
end

function _ResolveTooltipKeysForEntry(entry)
    local out = {}
    local src = entry and entry.keys
    if type(src) == "table" then
        for i = 1, #src do
            local k = _CanonicalIlvlGsRegistryKey(src[i]) or src[i]
            if k and k ~= "" then
                out[#out + 1] = k
            end
        end
    end
    if #out == 0 then
        local segs = _SplitMergedSegments(entry and entry.text or "")
        for i = 1, #segs do
            local k = _InferKeyFromSegmentText(segs[i])
            if k then
                out[#out + 1] = k
            end
        end
    end
    if #out == 0 and entry and entry.key then
        out[1] = _CanonicalIlvlGsRegistryKey(entry.key) or entry.key
    end
    return out
end

function _BuildSegmentSpansForEntry(entry, fontPath, fontSize, wrapWidth, fs)
    local keys = _ResolveTooltipKeysForEntry(entry)
    local spans = {}
    local spansByLine = {}
    if not keys or #keys == 0 then return spans end
    local fontFlags = "OUTLINE"
    if fs and fs.GetFont then
        local _, _, f = fs:GetFont()
        if type(f) == "string" and f ~= "" then
            fontFlags = f
        end
    end
    local segments = _SplitMergedSegments(entry.text or "")
    local delimW = _MeasureTooltipTextWidth(" | ", fontPath, fontSize, fontFlags)
    local maxW = nil
    if not (issecretvalue and issecretvalue(wrapWidth)) and type(wrapWidth) == "number" and wrapWidth > 0 then
        maxW = wrapWidth
    end
    if maxW and delimW and #segments > 1 then
        local unwrapped = 0
        local measured = true
        for si = 1, #segments do
            local sw = _MeasureTooltipTextWidth(segments[si], fontPath, fontSize, fontFlags)
            if not sw then
                measured = false
                break
            end
            unwrapped = unwrapped + sw
            if si < #segments then
                unwrapped = unwrapped + delimW
            end
        end
        if not measured or unwrapped <= maxW + 6 then
            maxW = nil
        end
    elseif maxW then
        maxW = nil
    end
    local numLines = fs and fs.GetNumLines and fs:GetNumLines() or 1
    if issecretvalue and issecretvalue(numLines) then
        numLines = 1
    end
    if maxW and fs and fs.GetNumLines and #segments > 1 and (numLines or 1) <= 1 then
        maxW = nil
    end

    local count = math.min(#keys, #segments)
    if maxW then
        local x = 0
        local line = 1
        for i = 1, count do
            local w = _MeasureTooltipTextWidth(segments[i], fontPath, fontSize, fontFlags)
            if not w or not delimW then
                maxW = nil
                break
            end
            local addDelim = (x > 0) and delimW or 0
            if x > 0 and (x + addDelim + w) > (maxW + 0.5) then
                line = line + 1
                x = 0
                addDelim = 0
            end
            local x1 = x + addDelim
            local x2 = x1 + w
            local seg = { key = keys[i], line = line, x1 = x1, x2 = x2 }
            spans[#spans + 1] = seg
            spansByLine[line] = spansByLine[line] or {}
            spansByLine[line][#spansByLine[line] + 1] = seg
            x = x2
        end
    else
        local prevX2 = 0
        for i = 1, count do
            local prefix = table.concat(segments, " | ", 1, i)
            local x2 = _MeasureTooltipTextWidth(prefix, fontPath, fontSize, fontFlags) or prevX2
            local x1 = (i == 1) and 0 or (prevX2 + (delimW or 0))
            prevX2 = x2
            local seg = { key = keys[i], line = 1, x1 = x1, x2 = x2 }
            spans[#spans + 1] = seg
            spansByLine[1] = spansByLine[1] or {}
            spansByLine[1][#spansByLine[1] + 1] = seg
        end
    end
    if #spans == 0 then
        local total = _MeasureTooltipTextWidth(entry.text or "", fontPath, fontSize, fontFlags)
        spans[1] = { key = keys[1], line = 1, x1 = 0, x2 = total }
        spansByLine[1] = { spans[1] }
    end
    if #keys > #spans then
        local last = spans[#spans]
        for i = #spans + 1, #keys do
            spans[i] = { key = keys[i], line = last.line or 1, x1 = last.x2, x2 = last.x2 }
            local ln = spans[i].line
            spansByLine[ln] = spansByLine[ln] or {}
            spansByLine[ln][#spansByLine[ln] + 1] = spans[i]
        end
    end
    if fs and fs.GetNumLines and fs.GetStringHeight then
        local realLines = fs:GetNumLines()
        if not (issecretvalue and issecretvalue(realLines)) and realLines and realLines > 1
            and #spansByLine < realLines and #spans > 0 then
            local last = spans[#spans]
            for ln = #spansByLine + 1, realLines do
                spansByLine[ln] = { { key = last.key, line = ln, x1 = last.x1, x2 = last.x2 } }
            end
        end
    end
    return spans, spansByLine
end

local function _IsSecret(v)
    return issecretvalue and issecretvalue(v) and true or false
end

function _GetHoveredKeyFromEntryFS(fs)
    if not fs then return nil end
    local spans = fs._fluxEntrySpans
    local spansByLine = fs._fluxEntrySpansByLine
    if type(spans) ~= "table" or #spans == 0 then
        local keys = fs._fluxEntryKeys
        return (type(keys) == "table" and keys[1]) or nil
    end
    --- Cursor and GetScaledRect() both use the same screen coordinate space; mixing
    --- GetCursorPosition() with region:GetLeft() breaks merged-segment hit boxes (e.g. G.S.).
    local relX, relY, regionH = nil, nil, nil
    if fs.GetScaledRect then
        local l, b, w, h = fs:GetScaledRect()
        if l and b and w and h and not (_IsSecret(l) or _IsSecret(b) or _IsSecret(w) or _IsSecret(h)) then
            local cx, cy = GetCursorPosition()
            if not (_IsSecret(cx) or _IsSecret(cy)) then
                relX = cx - l
                local top = b + h
                relY = top - cy
                regionH = h
            end
        end
    end
    if relX == nil then
        local cx, cy = GetCursorPosition()
        local scale = fs:GetEffectiveScale()
        local left = fs:GetLeft()
        local top = fs:GetTop()
        if _IsSecret(cx) or _IsSecret(cy) or _IsSecret(scale) or _IsSecret(left) or _IsSecret(top) then
            return spans[1].key
        end
        if not left or not scale or scale <= 0 then
            return spans[1].key
        end
        relX = (cx / scale) - left
        relY = top and (top - (cy / scale)) or 0
        local measuredH = fs:GetStringHeight()
        regionH = _IsSecret(measuredH) and 0 or (measuredH or 0)
    end
    if _IsSecret(relX) or _IsSecret(relY) or _IsSecret(regionH) then
        return spans[1].key
    end
    local lineSpans = spans
    if type(spansByLine) == "table" and next(spansByLine) ~= nil and relY ~= nil and not _IsSecret(relY) then
        local measuredH = fs:GetStringHeight()
        local totalH = regionH
        if _IsSecret(totalH) then
            totalH = _IsSecret(measuredH) and 0 or (measuredH or 0)
        end
        local lines = fs.GetNumLines and fs:GetNumLines() or 1
        if _IsSecret(lines) or _IsSecret(totalH) then
            lines = 1
            totalH = 0
        end
        lines = lines or 1
        local lineH = (lines > 0 and totalH > 0) and (totalH / lines) or 11
        if _IsSecret(lineH) then
            lineH = 11
        end
        local idx = math.floor((relY / math.max(1, lineH))) + 1
        if idx < 1 then idx = 1 elseif idx > lines then idx = lines end
        lineSpans = spansByLine[idx] or spansByLine[1] or spans
    end
    if _IsSecret(relX) then
        return lineSpans[1].key
    end
    if relX <= lineSpans[1].x2 then
        return lineSpans[1].key
    end
    for i = 2, #lineSpans do
        local seg = lineSpans[i]
        if relX <= seg.x2 then
            return seg.key
        end
    end
    return lineSpans[#lineSpans].key
end

local function _EnsureFluxInfoTooltipAnchor()
    if _fluxInfoTooltipAnchor then
        return _fluxInfoTooltipAnchor
    end
    local parent = (frame and frame.GetParent and frame:GetParent()) or UIParent
    _fluxInfoTooltipAnchor = _CreateFrame("Frame", nil, parent)
    _fluxInfoTooltipAnchor:SetSize(2, 2)
    _fluxInfoTooltipAnchor:Hide()
    if _fluxInfoTooltipAnchor.EnableMouse then
        _fluxInfoTooltipAnchor:EnableMouse(false)
    end
    return _fluxInfoTooltipAnchor
end

local function _FindSpanForStatKey(fs, statKey)
    if not fs or not statKey then
        return nil
    end
    local spans = fs._fluxEntrySpans
    if type(spans) ~= "table" or #spans == 0 then
        return nil
    end
    for i = 1, #spans do
        local s = spans[i]
        if s and s.key == statKey then
            return s
        end
    end
    return spans[1]
end

local function _GetFontStringLineMetrics(fs)
    local lines = fs.GetNumLines and fs:GetNumLines() or 1
    local totalH = fs.GetStringHeight and fs:GetStringHeight() or 12
    if _IsSecret(lines) or _IsSecret(totalH) then
        return 1, 12, 12
    end
    lines = lines or 1
    totalH = totalH or 12
    local lineH = (lines > 0 and totalH > 0) and (totalH / lines) or 12
    return lines, lineH, totalH
end

--- Place a zero-hit-test frame on the hovered Info segment so GameTooltip uses ANCHOR_RIGHT like PaperDoll rows.
function _PositionFluxInfoTooltipAnchor(fs, statKey)
    local anchor = _EnsureFluxInfoTooltipAnchor()
    if not fs then
        anchor:Hide()
        return anchor
    end
    local seg = _FindSpanForStatKey(fs, statKey)
    local lineIdx = (seg and seg.line) or 1
    local x1 = seg and seg.x1 or 0
    local x2 = seg and seg.x2 or nil
    if _IsSecret(x1) or _IsSecret(x2) then
        x1, x2 = 0, 100
    end
    if x2 == nil then
        local width = fs.GetWidth and fs:GetWidth() or nil
        x2 = _IsSecret(width) and 100 or (width or 100)
    end
    local w = math.max(2, x2 - x1)
    local lines, lineH = _GetFontStringLineMetrics(fs)
    if lineIdx < 1 then
        lineIdx = 1
    elseif lineIdx > lines then
        lineIdx = lines
    end
    local yOff = -(lineIdx - 1) * lineH
    local parent = fs:GetParent() or UIParent
    anchor:SetParent(parent)
    anchor:SetFrameStrata("TOOLTIP")
    local baseLvl = (fs.GetFrameLevel and fs:GetFrameLevel()) or 0
    if _IsSecret(baseLvl) then
        baseLvl = 0
    end
    anchor:SetFrameLevel(baseLvl + 25)
    anchor:ClearAllPoints()
    anchor:SetSize(w, math.max(1, lineH))
    anchor:SetPoint("TOPLEFT", fs, "TOPLEFT", x1, yOff)
    anchor:Show()
    return anchor
end

local function _HideFluxInfoTooltipAnchor()
    if _fluxInfoTooltipAnchor then
        _fluxInfoTooltipAnchor:Hide()
    end
end

local function _WithTooltipOwnerRedirect(redirTarget, statFrame, fn)
    if not redirTarget or not statFrame or type(fn) ~= "function" then
        return
    end
    local gt = GameTooltip
    local oldSetOwner = gt.SetOwner
    gt.SetOwner = function(self, owner, ...)
        if owner == statFrame then
            owner = redirTarget
        end
        return oldSetOwner(self, owner, ...)
    end
    local ok, err = pcall(fn)
    gt.SetOwner = oldSetOwner
    if not ok and geterrorhandler then
        geterrorhandler()(err)
    end
end

local function _ApplyPaperDollStatTooltipToAnchor(statFrame, anchor)
    if not statFrame or not statFrame.tooltip or not anchor then
        return false
    end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    if FLUX_API and FLUX_API.isRetail then
        GameTooltip:SetText(statFrame.tooltip)
    else
        GameTooltip:SetText(statFrame.tooltip, 1, 1, 1)
    end
    if statFrame.tooltip2 then
        local c = NORMAL_FONT_COLOR
        if c and c.r then
            GameTooltip:AddLine(statFrame.tooltip2, c.r, c.g, c.b, true)
        else
            GameTooltip:AddLine(statFrame.tooltip2, nil, nil, nil, true)
        end
    end
    if statFrame.tooltip3 then
        local c = NORMAL_FONT_COLOR
        if c and c.r then
            GameTooltip:AddLine(statFrame.tooltip3, c.r, c.g, c.b, true)
        else
            GameTooltip:AddLine(statFrame.tooltip3, nil, nil, nil, true)
        end
    end
    GameTooltip:Show()
    return GameTooltip:IsShown()
end

function _InvalidateTooltipStatFrameCache()
    _tooltipKeyToStatFrameAt = nil
end

function _G.FluxAutoRepairEnabled()
    local FV = _G.FluxVendorAuto
    if not FV or not FV.EnsureSettings then
        return false
    end
    local s = FV.EnsureSettings()
    return s and s.autoRepair and true or false
end

function _G.FluxToggleAutoRepair()
    local FV = _G.FluxVendorAuto
    if not FV or not FV.EnsureSettings then
        return false
    end
    local s = FV.EnsureSettings()
    if not s then
        return false
    end
    s.autoRepair = not (s.autoRepair and true or false)
    if FV.NotifyVendorSettingsChanged then
        pcall(FV.NotifyVendorSettingsChanged)
    end
    return true
end

function _SetDurabilityRepairTooltip(anchor, append, suppressToggleHint)
    local cost, isEstimate = GetRepairCost()
    local canRepair = nil
    local durabilityPct = GetDurabilityPercentage and GetDurabilityPercentage() or nil
    if GetRepairAllCost then
        local ok, _, can = pcall(GetRepairAllCost)
        if ok then
            canRepair = can
        end
    end
    if not append then
        GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
    end
    local pctNum = durabilityPct
    if issecretvalue and pctNum and issecretvalue(pctNum) then
        pctNum = nil
    end
    if type(pctNum) ~= "number" then
        pctNum = nil
    end
    local pctR, pctG, pctB = 1, 1, 1
    if pctNum then
        pctR, pctG, pctB = GetDurabilityColor(pctNum)
    end
    GameTooltip:AddDoubleLine("Durability", pctNum and string.format("%d%%", pctNum) or "--", 1, 0.82, 0, pctR, pctG, pctB)
    -- Midnight: SetTooltipMoney → MoneyFrame_Update does GetStringWidth arithmetic
    -- that fails under addon taint when widths are secret. Prefer plain FormatMoney.
    local api = (FluxAPICompat and FluxAPICompat.API) or (_G.FluxAPICompat and _G.FluxAPICompat.API)
    local safeCost = 0
    if cost then
        if api and api.SafeGetNumber then
            safeCost = api.SafeGetNumber(cost, 0)
        elseif issecretvalue and issecretvalue(cost) then
            safeCost = 0
        else
            safeCost = tonumber(cost) or 0
        end
    end
    local repairText, repairR, repairG, repairB = "--", 0.7, 0.7, 0.7
    if safeCost > 0 then
        repairText, repairR, repairG, repairB = FormatMoney(safeCost), 1, 1, 1
    elseif pctNum and pctNum >= 100 then
        repairText, repairR, repairG, repairB = "None", 0.7, 0.9, 0.7
    end
    GameTooltip:AddDoubleLine(isEstimate and safeCost > 0 and "Est. Repair" or "Repair", repairText, 1, 0.82, 0, repairR, repairG, repairB)
    if safeCost > 0 and canRepair == false and CanMerchantRepair and CanMerchantRepair() then
        local playerMoney = GetMoney and GetMoney() or 0
        if api and api.SafeGetNumber then
            playerMoney = api.SafeGetNumber(playerMoney, 0)
        else
            playerMoney = tonumber(playerMoney) or 0
        end
        if type(playerMoney) == "number" and playerMoney < safeCost then
            GameTooltip:AddLine(ERR_NOT_ENOUGH_MONEY or "Not enough money", 1.0, 0.1, 0.1)
        end
    end
    if _G.FluxAutoRepairEnabled() then
        GameTooltip:AddDoubleLine("Auto Repair", "On", 1, 0.82, 0, 0.2, 1, 0.2)
    else
        GameTooltip:AddDoubleLine("Auto Repair", "Off", 1, 0.82, 0, 1, 0.25, 0.25)
    end
    if not suppressToggleHint then
        GameTooltip:AddLine("<Right Click> Toggle", 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end

function _SetCompactPairTooltip(anchor, title, leftLabel, leftValue, rightLabel, rightValue)
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:SetText(title)
    GameTooltip:AddDoubleLine(leftLabel, leftValue or "--", 1, 0.82, 0.2, 1, 1, 1)
    GameTooltip:AddDoubleLine(rightLabel, rightValue or "--", 1, 0.82, 0.2, 1, 1, 1)
    GameTooltip:Show()
end

--- Same layout as FluxCSC item/GS rows (CharacterStatsItemLevel ShowCrossTooltip); title matches paper doll ("Equipment").
function _SetEquipmentRatingTooltip(anchor, primaryIsIlvl)
    if not anchor then return end
    local _, _, ilvlText, gsText = _GetCompactInfoPairValues()
    local ilvlLbl = _G.CSC_ILVL_LABEL or "Item LvL"
    local gsLbl = _G.CSC_GS_LABEL or "GearScore"
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:SetText("Equipment")
    if primaryIsIlvl then
        GameTooltip:AddDoubleLine(ilvlLbl, ilvlText or "--", 1, 0.82, 0.2, 1, 1, 1)
        GameTooltip:AddDoubleLine(gsLbl, gsText or "--", 1, 0.82, 0.2, 1, 1, 1)
    else
        GameTooltip:AddDoubleLine(gsLbl, gsText or "--", 1, 0.82, 0.2, 1, 1, 1)
        GameTooltip:AddDoubleLine(ilvlLbl, ilvlText or "--", 1, 0.82, 0.2, 1, 1, 1)
    end
    GameTooltip:Show()
end

function _GetCompactInfoPairValues()
    local fps = GetFramerate and GetFramerate() or nil
    local _, _, latencyHome, latencyWorld = GetNetStats()
    local ping = latencyWorld or latencyHome or nil

    local ilvl = nil
    if type(_G.FluxCSC_GetPlayerItemLevel) == "function" then
        ilvl = _G.FluxCSC_GetPlayerItemLevel()
    end
    local gs = nil
    if type(_G.FluxCSC_GetPlayerGearScore) == "function" then
        gs = _G.FluxCSC_GetPlayerGearScore()
    end

    local fpsText = fps and string.format("%.0f", fps) or "--"
    local pingText = ping and string.format("%d ms", ping) or "--"
    local ilvlText = ilvl and string.format("%.1f", ilvl) or "--"
    local gsText = gs and string.format("%d", math.floor(gs + 0.5)) or "--"
    return fpsText, pingText, ilvlText, gsText
end

function _GetTooltipSourceStatFrames(statKey)
    if InfoFrame.ResolveStatFramesForTooltip then
        return InfoFrame.ResolveStatFramesForTooltip(statKey)
    end
    return {}
end

local function _TryShowStatTooltipFromFrame(statFrame, anchor)
    if not statFrame or not anchor then return false end
    local onEnter = statFrame.GetScript and statFrame:GetScript("OnEnter") or nil
    if type(onEnter) == "function" then
        _WithTooltipOwnerRedirect(anchor, statFrame, function()
            onEnter(statFrame)
        end)
        if GameTooltip:IsShown() then return true end
    end
    if statFrame.tooltip or statFrame.tooltip2 or statFrame.tooltip3 then
        if _ApplyPaperDollStatTooltipToAnchor(statFrame, anchor) then return true end
    end
    if _G.PaperDollStatTooltip then
        _WithTooltipOwnerRedirect(anchor, statFrame, function()
            _G.PaperDollStatTooltip(statFrame)
        end)
        if GameTooltip:IsShown() then return true end
    end
    return false
end

function _GetTooltipSourceStatFrame(statKey)
    local L = _GetTooltipSourceStatFrames(statKey)
    return L[1]
end

--- Number shown on the Forever character row, when that row has been built.
function InfoFrame._CharacterPanelStatNumber(statKey)
    if type(statKey) ~= "string" then
        return nil
    end
    if _GetTooltipSourceStatFrames then
        local frames = _GetTooltipSourceStatFrames(statKey)
        for i = 1, #frames do
            local numeric = frames[i] and frames[i].numericValue
            if type(numeric) == "number" then
                return numeric
            end
        end
    end
    local cache = InfoFrame._foreverStatCache
    if cache and type(cache[statKey]) == "number" then
        return cache[statKey]
    end
    return nil
end

--- Info-panel spell tooltip: same layout as the TBC / Anniversary Power tooltip.
function InfoFrame._ShowCamelotSpellPinTooltip(anchor)
    local show = rawget(_G, "FluxAnniversarySpellPowerTooltip")
    if type(show) == "function" then
        show(anchor, false)
        return
    end
    if not anchor or not GameTooltip then
        return
    end
    local maxD, heal, minD, bonus = InfoFrame._CamelotSpellBonus()
    local hi = _G.HIGHLIGHT_FONT_COLOR
    local normal = _G.NORMAL_FONT_COLOR
    local hr, hg, hb = 1, 1, 1
    local nr, ng, nb = 1, 0.82, 0
    if hi then
        hr, hg, hb = hi.r or hr, hi.g or hg, hi.b or hb
    end
    if normal then
        nr, ng, nb = normal.r or nr, normal.g or ng, normal.b or nb
    end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:SetText(_G.STAT_SPELLPOWER or "Spell Power", hr, hg, hb)
    if type(_G.STAT_SPELLPOWER_TOOLTIP) == "string" then
        local ok, text = pcall(string.format, _G.STAT_SPELLPOWER_TOOLTIP, maxD or 0)
        GameTooltip:AddLine(ok and text or _G.STAT_SPELLPOWER_TOOLTIP, hr, hg, hb, true)
    end
    GameTooltip:AddLine(" ")
    local schoolRows = {
        { cap = "SPELL_SCHOOL1_CAP", school = 2, fallback = "Holy" },
        { cap = "SPELL_SCHOOL2_CAP", school = 3, fallback = "Fire" },
        { cap = "SPELL_SCHOOL4_CAP", school = 5, fallback = "Frost" },
        { cap = "SPELL_SCHOOL6_CAP", school = 7, fallback = "Arcane" },
        { cap = "SPELL_SCHOOL5_CAP", school = 6, fallback = "Shadow" },
        { cap = "SPELL_SCHOOL3_CAP", school = 4, fallback = "Nature" },
    }
    for i = 1, #schoolRows do
        local row = schoolRows[i]
        local value = bonus[row.school] or 0
        local hex = _SCHOOL_COLOR_BY_ID[row.school] or "ffffff"
        local cap = _G[row.cap]
        local damageWord = _G.DAMAGE or "Damage"
        if type(cap) ~= "string" or cap == "" then
            cap = row.fallback
        end
        local label = string.format("|cff%s%s %s:|r", hex, cap, damageWord)
        GameTooltip:AddDoubleLine(label, string.format("%.2f", value), nr, ng, nb, hr, hg, hb)
        if value ~= minD and GameTooltip.AddTexture then
            pcall(GameTooltip.AddTexture, GameTooltip, "Interface\\PaperDollInfoFrame\\SpellSchoolIcon" .. row.school)
        end
    end
    GameTooltip:AddLine(" ")
    local healLabel = (_G.STAT_SPELLHEALING or "Spell Healing") .. ":"
    GameTooltip:AddDoubleLine("|cff20ff20" .. healLabel .. "|r", string.format("|cff20ff20%d|r", heal or 0), 1, 1, 1, 1, 1, 1)
    if type(_G.STAT_SPELLHEALING_TOOLTIP) == "string" then
        local ok, text = pcall(string.format, _G.STAT_SPELLHEALING_TOOLTIP, heal or 0)
        GameTooltip:AddLine((ok and text) or _G.STAT_SPELLHEALING_TOOLTIP, 0.6, 1, 0.6, true)
    end
    if type(ComputePetBonus) == "function" then
        local petStr, damage
        local shadow = bonus[6] or 0
        local fire = bonus[3] or 0
        if shadow == minD and fire == minD then
            petStr = _G.PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG
            damage = minD
        elseif shadow > fire then
            petStr = _G.PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_SHADOW
            damage = shadow
        else
            petStr = _G.PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_FIRE
            damage = fire
        end
        if type(petStr) == "string" and type(damage) == "number" then
            local okAp, petAP = pcall(ComputePetBonus, "PET_BONUS_SPELLDMG_TO_AP", damage)
            local okDmg, petDmg = pcall(ComputePetBonus, "PET_BONUS_SPELLDMG_TO_SPELLDMG", damage)
            petAP = okAp and tonumber(petAP) or 0
            petDmg = okDmg and tonumber(petDmg) or 0
            petAP = math.floor(petAP or 0)
            petDmg = math.floor(petDmg or 0)
            if petAP > 0 or petDmg > 0 then
                local ok, line = pcall(string.format, petStr, petAP, petDmg)
                if ok and type(line) == "string" then
                    GameTooltip:AddLine(line, nil, nil, nil, true)
                end
            end
        end
    end
    GameTooltip:Show()
end

function _ShowInfoTooltipForKey(ownerFs, statKey)
    statKey = _CanonicalIlvlGsRegistryKey(statKey) or statKey
    statKey = InfoFrame._CamelotCombatStatKey(statKey)
    if not statKey or _TOOLTIP_DISABLED_KEYS[statKey] then
        GameTooltip:Hide()
        _HideFluxInfoTooltipAnchor()
        _lastInfoTooltipKey = nil
        return
    end
    local anchor = _PositionFluxInfoTooltipAnchor(ownerFs, statKey)
    if statKey == "durability" then
        _SetDurabilityRepairTooltip(anchor)
        _lastInfoTooltipKey = statKey
        return
    end
    if statKey == "fps" or statKey == "ping" then
        local fpsText, pingText = _GetCompactInfoPairValues()
        _SetCompactPairTooltip(anchor, "Performance", "FPS", fpsText, "Ping", pingText)
        _lastInfoTooltipKey = statKey
        return
    end
    if statKey == "itemLevel" or statKey == "gearScore" then
        _SetEquipmentRatingTooltip(anchor, statKey == "itemLevel")
        _lastInfoTooltipKey = statKey
        return
    end
    if InfoFrame._UseClassicSpellPowerLine() and (statKey == "spellPower" or statKey == "spellPowerOnly" or statKey == "healPower") then
        InfoFrame._ShowCamelotSpellPinTooltip(anchor)
        if GameTooltip:IsShown() then
            _lastInfoTooltipKey = statKey
            return
        end
    end
    local cscLookupKey = statKey
    if statKey == "spellPowerOnly" or statKey == "healPower" then
        cscLookupKey = "spellPower"
    end
    local frames = _GetTooltipSourceStatFrames(cscLookupKey)
    local showed = false
    for i = 1, #frames do
        GameTooltip:Hide()
        if _TryShowStatTooltipFromFrame(frames[i], anchor) then
            showed = true
            break
        end
    end
    if not showed and cscLookupKey == "spellPower" then
        local fn = _G.CSC_InfoFrame_ShowSpellPowerTooltip
        if type(fn) == "function" then
            GameTooltip:Hide()
            pcall(fn, anchor)
            showed = GameTooltip:IsShown()
        end
    end
    if showed then
        _lastInfoTooltipKey = statKey
        return
    end
    GameTooltip:Hide()
    _HideFluxInfoTooltipAnchor()
    _lastInfoTooltipKey = statKey
end

_UpdateInfoFrameEntryTooltip = function(fs)
    if not fs or not fs:IsShown() then return end
    local key = _GetHoveredKeyFromEntryFS(fs)
    if not key then
        if _lastInfoTooltipKey or GameTooltip:IsShown() then
            GameTooltip:Hide()
            _HideFluxInfoTooltipAnchor()
            _lastInfoTooltipKey = nil
        end
        return
    end
    local liveKey = (key == "fps" or key == "ping")
    local tipShown = GameTooltip:IsShown()
    local sameKey = (key == _lastInfoTooltipKey)
    if liveKey and sameKey then
        local now = GetTime() or 0
        if now - (_lastPerfTooltipRefreshAt or 0) < UPDATE_INTERVAL then
            return
        end
    elseif sameKey and tipShown and not liveKey then
        return
    elseif sameKey and not tipShown and not liveKey then
        local now = GetTime() or 0
        if now - (_lastStatTooltipRetryAt or 0) < 0.15 then
            return
        end
        _lastStatTooltipRetryAt = now
    end
    _ShowInfoTooltipForKey(fs, key)
    if liveKey then
        _lastPerfTooltipRefreshAt = GetTime() or 0
    end
end

_BindInfoFrameEntryTooltip = function(fs, entry, fontPath, fontSize)
    if not fs then return end
    fs._fluxEntryKeys = entry and _ResolveTooltipKeysForEntry(entry) or nil
    fs._fluxEntryRef = entry
    fs._fluxEntryFontPath = fontPath
    fs._fluxEntryFontSize = fontSize
    fs._fluxEntryWrapWidth = fs.GetWidth and fs:GetWidth() or nil
    local wrapW = fs.GetWidth and fs:GetWidth() or nil
    local spans, spansByLine = nil, nil
    if entry then
        spans, spansByLine = _BuildSegmentSpansForEntry(entry, fontPath, fontSize, wrapW, fs)
    end
    fs._fluxEntrySpans = spans
    fs._fluxEntrySpansByLine = spansByLine
    if fs.EnableMouse then fs:EnableMouse(true) end
    fs:SetScript("OnEnter", function(self)
        local curW = self.GetWidth and self:GetWidth() or nil
        local curSize = self._fluxEntryFontSize
        local fp, fsz = self:GetFont()
        if not (issecretvalue and issecretvalue(fsz)) and type(fsz) == "number" and fsz > 0 then
            curSize = fsz
        end
        local secretMeasure = issecretvalue and (
            issecretvalue(curW) or issecretvalue(self._fluxEntryWrapWidth)
            or issecretvalue(curSize) or issecretvalue(self._fluxEntryFontSize)
        )
        if self._fluxEntryRef and not secretMeasure
            and (curW ~= self._fluxEntryWrapWidth or curSize ~= self._fluxEntryFontSize) then
            local spans, byLine = _BuildSegmentSpansForEntry(
                self._fluxEntryRef,
                fp or self._fluxEntryFontPath or "Fonts\\FRIZQT__.TTF",
                curSize or self._fluxEntryFontSize or 11,
                curW,
                self
            )
            self._fluxEntrySpans = spans
            self._fluxEntrySpansByLine = byLine
            self._fluxEntryWrapWidth = curW
            self._fluxEntryFontPath = fp or self._fluxEntryFontPath
            self._fluxEntryFontSize = curSize or self._fluxEntryFontSize
        end
        _hoveredInfoEntryFS = self
        _UpdateInfoFrameEntryTooltip(self)
        _StartInfoTooltipHoverPoll()
    end)
    fs:SetScript("OnLeave", function(self)
        if _hoveredInfoEntryFS == self then
            _hoveredInfoEntryFS = nil
        end
        _StopInfoTooltipHoverPoll()
        _lastInfoTooltipKey = nil
        _HideFluxInfoTooltipAnchor()
        GameTooltip:Hide()
    end)
    fs:SetScript("OnMouseUp", function(self, button)
        if button ~= "RightButton" then
            return
        end
        if _GetHoveredKeyFromEntryFS(self) ~= "durability" then
            return
        end
        if _G.FluxToggleAutoRepair and _G.FluxToggleAutoRepair() then
            _ShowInfoTooltipForKey(self, "durability")
        end
    end)
    InfoFrame._RenderCamelotLiveText(fs)
end

_ClearInfoFrameEntryTooltip = function(fs)
    if not fs then return end
    if _hoveredInfoEntryFS == fs then
        _hoveredInfoEntryFS = nil
        _StopInfoTooltipHoverPoll()
    end
    fs._fluxEntryKeys = nil
    fs._fluxEntryRef = nil
    fs._fluxEntryFontPath = nil
    fs._fluxEntryFontSize = nil
    fs._fluxEntryWrapWidth = nil
    fs._fluxEntrySpans = nil
    fs._fluxEntrySpansByLine = nil
    fs:SetScript("OnEnter", nil)
    fs:SetScript("OnLeave", nil)
    fs:SetScript("OnMouseUp", nil)
    if fs.EnableMouse then fs:EnableMouse(false) end
end

-- ============================================================================
-- FRAME CREATION
-- ============================================================================

-- Store reference to global CreateFrame to avoid shadowing
local WoWCreateFrame = CreateFrame

local function GetOrCreatePooledFontString()
    for i = 1, #linePool do
        if not linePool[i]._inUse then
            linePool[i]._inUse = true
            if linePool[i].SetWordWrap then linePool[i]:SetWordWrap(false) end
            if linePool[i].SetNonSpaceWrap then linePool[i]:SetNonSpaceWrap(false) end
            linePool[i]:Show()
            return linePool[i]
        end
    end
    local fs = frame:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    fs:SetTextColor(1, 1, 1)
    if fs.SetWordWrap then fs:SetWordWrap(false) end
    if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
    fs._inUse = true
    linePool[#linePool + 1] = fs
    return fs
end

local function ReleaseAllPooledFontStrings()
    for i = 1, #linePool do
        linePool[i]._inUse = false
        _ClearInfoFrameEntryTooltip(linePool[i])
        linePool[i]:Hide()
        linePool[i]:SetText("")
    end
end

function InfoFrame.StatLabel(key)
    key = InfoFrame._CamelotCombatStatKey(key)
    if key == "spellPower" and InfoFrame._IsCamelotClient and InfoFrame._IsCamelotClient() then
        local mode = GetInfoFrameCharDB().spellDisplayMode or "off"
        if mode == "heal" then
            return "Heal"
        end
        if mode == "sp" then
            return "S.P."
        end
        return "Spell"
    end
    local systemLabels = InfoFrame._systemStatLabels
    if not systemLabels then
        systemLabels = {
            durability = "Durability",
            fps = "FPS",
            ping = "Ping",
        }
        InfoFrame._systemStatLabels = systemLabels
    end
    if systemLabels[key] then
        return systemLabels[key]
    end
    local reg = STAT_REGISTRY[key]
    if reg and type(reg.label) == "string" and reg.label ~= "" then
        return reg.label
    end
    return tostring(key or "")
end

--- Visible line keys in the legacy default sequence (not the player's saved order).
function InfoFrame._CollectVisibleStatKeys(db)
    local keys = {}
    if db.showDurability then
        keys[#keys + 1] = "durability"
    end
    if db.showFPS then
        keys[#keys + 1] = "fps"
    end
    if db.showPing then
        keys[#keys + 1] = "ping"
    end
    InfoFrame._FoldClassicSpellPins(db)
    local pins = db.pinnedStats
    if pins and (pins.moveSpeed or pins.movement_speed) then
        pins.speed = true
        pins.moveSpeed = nil
        pins.movement_speed = nil
    end
    if type(db.statOrder) == "table" then
        for i, orderedKey in ipairs(db.statOrder) do
            if orderedKey == "moveSpeed" or orderedKey == "movement_speed" then
                db.statOrder[i] = "speed"
            end
        end
    end
    local spellMode = db.spellDisplayMode or "off"
    local skipSpellKeys = { spellPower = true, healPower = true }
    local seenPin = {}
    for statKey in pairs(db.pinnedStats or {}) do
        local key = _CanonicalIlvlGsRegistryKey(statKey) or statKey
        if key == "moveSpeed" or key == "movement_speed" then
            key = "speed"
        end
        local spellKind = InfoFrame._ClassicSpellPinKey(key)
        if spellKind == "spellPower" or spellKind == "healPower" then
            key = nil
        end
        if key and not skipSpellKeys[key] and STAT_REGISTRY[key] and not seenPin[key] then
            seenPin[key] = true
            keys[#keys + 1] = key
        end
    end
    if spellMode ~= "off" and InfoFrame._UseClassicSpellPowerLine() then
        -- Damage, healing, or both stay on one info line.
        keys[#keys + 1] = "spellPower"
    elseif spellMode == "sp" then
        keys[#keys + 1] = "spellPowerOnly"
    elseif spellMode == "heal" then
        keys[#keys + 1] = "healPower"
    elseif spellMode == "both" then
        keys[#keys + 1] = "spellPower"
    end
    return keys
end

function InfoFrame._NormalizeStatOrder(db, visibleKeys)
    if type(db.statOrder) ~= "table" then
        db.statOrder = {}
    end
    local seen = {}
    local cleaned = {}
    for _, k in ipairs(db.statOrder) do
        if type(k) == "string" and not seen[k] then
            seen[k] = true
            cleaned[#cleaned + 1] = k
        end
    end
    db.statOrder = cleaned
    local missing = {}
    for _, k in ipairs(visibleKeys) do
        if not seen[k] then
            seen[k] = true
            missing[#missing + 1] = k
        end
    end
    if #cleaned == 0 then
        table.sort(missing, function(a, b)
            return _KeyOrder(a) < _KeyOrder(b)
        end)
        db.statOrder = missing
        return
    end
    table.sort(missing, function(a, b)
        return _KeyOrder(a) < _KeyOrder(b)
    end)
    for _, k in ipairs(missing) do
        db.statOrder[#db.statOrder + 1] = k
    end
end

--- True when at least one stat would be drawn. Does not require the frame.
function InfoFrame.HasVisibleLines()
    local db = GetInfoFrameCharDB()
    if db.showFPS or db.showDurability or db.showPing then
        return true
    end
    if db.spellDisplayMode and db.spellDisplayMode ~= "off" then
        return true
    end
    for _, enabled in pairs(db.pinnedStats or {}) do
        if enabled then
            return true
        end
    end
    return false
end

function InfoFrame.GetOrderedVisibleStats()
    local db = GetInfoFrameCharDB()
    local keys = InfoFrame._CollectVisibleStatKeys(db)
    InfoFrame._NormalizeStatOrder(db, keys)
    local index = {}
    for i, k in ipairs(db.statOrder) do
        if index[k] == nil then
            index[k] = i
        end
    end
    table.sort(keys, function(a, b)
        local ia = index[a] or 9999
        local ib = index[b] or 9999
        if ia ~= ib then
            return ia < ib
        end
        return _KeyOrder(a) < _KeyOrder(b)
    end)
    local out = {}
    for i, k in ipairs(keys) do
        out[i] = { key = k, label = InfoFrame.StatLabel(k) }
    end
    return out
end

function InfoFrame.SetStatOrder(keys)
    local db = GetInfoFrameCharDB()
    local nextOrder = {}
    local seen = {}
    if type(keys) == "table" then
        for _, k in ipairs(keys) do
            if type(k) == "string" and not seen[k] then
                seen[k] = true
                nextOrder[#nextOrder + 1] = k
            end
        end
    end
    for _, k in ipairs(db.statOrder or {}) do
        if type(k) == "string" and not seen[k] then
            seen[k] = true
            nextOrder[#nextOrder + 1] = k
        end
    end
    db.statOrder = nextOrder
    if frame then
        InfoFrame.ForceRebuild()
    end
end

--- Build the ordered list of visible lines from charDB settings.
--- One FontString per stat key; merging is handled at layout time when needed.
RebuildInfoLines = function()
    if not frame then return end
    local db = GetInfoFrameCharDB()
    if not db._fluxIlvlGsKeyMigrated then
        db._fluxIlvlGsKeyMigrated = true
        local pinKeys = {}
        for statKey in pairs(db.pinnedStats or {}) do
            pinKeys[#pinKeys + 1] = statKey
        end
        for _, statKey in ipairs(pinKeys) do
            local canon = _CanonicalIlvlGsRegistryKey(statKey)
            if canon and canon ~= statKey and db.pinnedStats[statKey] then
                db.pinnedStats[canon] = true
                db.pinnedStats[statKey] = nil
            end
        end
    end

    ReleaseAllPooledFontStrings()
    activeLineCount = 0
    durabilityText = nil
    fpsText = nil
    pingText = nil

    local visibleKeys = InfoFrame._CollectVisibleStatKeys(db)
    InfoFrame._NormalizeStatOrder(db, visibleKeys)
    local orderIndex = {}
    for i, k in ipairs(db.statOrder) do
        if orderIndex[k] == nil then
            orderIndex[k] = i
        end
    end
    local lines = {}
    for _, key in ipairs(visibleKeys) do
        lines[#lines + 1] = {
            key = key,
            order = orderIndex[key] or _KeyOrder(key),
        }
    end

    table.sort(lines, function(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end
        return _KeyOrder(a.key) < _KeyOrder(b.key)
    end)

    for i = 1, #lines do
        local fs = GetOrCreatePooledFontString()
        local k  = lines[i].key
        activeLines[i] = { key = k, fs = fs }
        if k == "durability" then durabilityText = fs end
        if k == "fps"        then fpsText        = fs end
        if k == "ping"       then pingText        = fs end
    end
    activeLineCount = #lines

    for i = activeLineCount + 1, #activeLines do activeLines[i] = nil end

    cachedStableIntegratedClusterWidth = nil
    InfoFrame._screenTopLeftWidth = nil
    _cachedActionStripMinimalWidth = nil
    _lastLayoutMode = nil
    _lastLayoutW = nil
    _lastLayoutH = nil
end

local function CreateInfoFrame()
    if frame then return frame end
    
    frame = WoWCreateFrame("Frame", "FluxInfoFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(7)
    frame:SetHeight(GetDynamicVerticalHeight())
    frame:SetWidth(200)
    
    if FluxBorder then
        FluxBorder:ApplyTo(frame, 0, -4, -1, -4)
        FluxBorder:SetClassColor(frame, 1, true)
    end
    
    -- Legacy durability hit-frame kept for compatibility; tooltip handling now lives on stat FontStrings.
    durabilityTooltipFrame = WoWCreateFrame("Frame", nil, frame)
    durabilityTooltipFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
    durabilityTooltipFrame:EnableMouse(false)
    durabilityTooltipFrame:SetAlpha(0)
    durabilityTooltipFrame:Hide()
    
    -- Build dynamic line pool from per-character settings
    RebuildInfoLines()
    
    frame:Hide()

    _InstallInfoFrameTickerHooks()

    return frame
end

-- ============================================================================
-- UPDATE LOGIC (moved before positioning to allow UpdateStats to be called)
-- ============================================================================

local function UpdateStats()
    if not frame or not frame:IsShown() then return end
    if activeLineCount == 0 then return end

    local textChanged = false
    for i = 1, activeLineCount do
        local line = activeLines[i]
        local key  = line.key
        local full, compact = _GetKeyText(key)
        local secret = (issecretvalue and (issecretvalue(full) or issecretvalue(compact))) and true or false
        if secret or full ~= line.fullText or compact ~= line.compactText then
            textChanged = true
            if not secret then
                line.fullText = full
                line.compactText = compact
            end
            line.fs:SetText(full)
        end
    end

    local mode = minimapTopVisualActive and "minimapTop" or (stripVisualActive and "integrated" or "vertical")
    local fw = frame:GetWidth() or 0
    local fh = frame:GetHeight() or 0
    local layoutChanged = (mode ~= _lastLayoutMode) or (fw ~= _lastLayoutW) or (fh ~= _lastLayoutH)
    if not textChanged and not layoutChanged then
        InfoFrame._RefreshCamelotLiveText()
        return
    end
    _lastLayoutMode = mode
    _lastLayoutW = fw
    _lastLayoutH = fh

    if textChanged then
        _cachedActionStripMinimalWidth = nil
    end

    -- Per-key SetText above resets any merged/truncated text the horizontal
    -- layout produced.  Re-run the active horizontal layout so the merge
    -- cascade (dur/fps/ping → crit-variants → hit-variants) is re-applied
    -- before any font shrink, every tick.  Vertical layout doesn't merge so
    -- it doesn't need a refresh here.
    if minimapTopVisualActive then
        ApplyMinimapTopStripTextLayout()
    elseif stripVisualActive then
        ApplyIntegratedStripTextLayoutRouter()
    else
        _ApplyVerticalDynamicMergeLayout()
    end
    InfoFrame._RefreshCamelotLiveText()
end

--- Pins that track combat ratings / auras (not FPS/dur/ping-only).
local DYNAMIC_PIN_KEYS = {
    crit = true,
    meleeCrit = true,
    spellCrit = true,
    rangedCrit = true,
    haste = true,
    mastery = true,
    versatility = true,
    hit = true,
    hit_chance = true,
    spellHit = true,
    meleeHit = true,
    rangedHit = true,
    spellPower = true,
    healPower = true,
    expertise = true,
    itemLevel = true,
    gearScore = true,
    attackPower = true,
    meleeAttackPower = true,
    rangedAttackPower = true,
    armor = true,
    dodge = true,
    parry = true,
    block = true,
    resilience = true,
    manaRegen = true,
    attackSpeed = true,
    meleeArmorPenetration = true,
    rangedArmorPenetration = true,
    spellPenetration = true,
    health = true,
    power = true,
    moveSpeed = true,
    speed = true,
    strength = true,
    agility = true,
    stamina = true,
    intellect = true,
    spirit = true,
    defense = true,
    weaponDamage = true,
    mp5 = true,
}

local function HasDynamicPinnedStat()
    local db = GetInfoFrameCharDB()
    for key, enabled in pairs(db.pinnedStats or {}) do
        if enabled and DYNAMIC_PIN_KEYS[key] then
            return true
        end
    end
    return false
end

local infoStatRefreshPending = false
local infoStatRefreshFallbackFrame = nil

function InfoFrame._FlushPlayerStatRefresh()
    if not frame or not frame:IsShown() then
        return
    end
    UpdateStats()
end

function InfoFrame.RequestStatRefresh()
    if type(_G.FluxCSC_QueuePlayerStatRefresh) == "function" then
        _G.FluxCSC_QueuePlayerStatRefresh()
        return
    end
    if infoStatRefreshPending then
        return
    end
    infoStatRefreshPending = true
    if _C_Timer and _C_Timer.After then
        _C_Timer.After(0, function()
            infoStatRefreshPending = false
            InfoFrame._FlushPlayerStatRefresh()
        end)
        return
    end
    if not infoStatRefreshFallbackFrame then
        infoStatRefreshFallbackFrame = _CreateFrame("Frame")
    end
    infoStatRefreshFallbackFrame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        infoStatRefreshPending = false
        InfoFrame._FlushPlayerStatRefresh()
    end)
end

-- ============================================================================
-- POSITIONING LOGIC
-- ============================================================================

-- Calculate minimal width needed for all text elements.
-- Flux perf: result only changes when the text font / placement-specific
-- layout changes — not on every action-strip pass. Cache the worst-case
-- width and invalidate it on ForceUpdatePosition / placement toggles.
local function CalculateMinimalWidth()
    if _cachedActionStripMinimalWidth then
        return _cachedActionStripMinimalWidth
    end

    local minWidth = 100
    local padding = 20

    for i = 1, activeLineCount do
        local tw = activeLines[i].fs:GetStringWidth() or 0
        if tw > 0 then
            minWidth = math.max(minWidth, tw + padding)
        end
    end

    if minWidth > 100 then
        _cachedActionStripMinimalWidth = minWidth
    end
    return minWidth
end

--- Status bar owns the integrated cell. Kept so older callers do not error.
function InfoFrame.PrepareIntegratedStripLayout()
    if GetPlacement() ~= "statusIntegrated" then
        return
    end
    CreateInfoFrame()
end

--- Pixels to grow the UnifiedBorder gap backdrop past the Info slot (covers border seams vs grids). Only when forRealInfoFrame is false.
local ACTION_STRIP_GAP_BACKDROP_BLEED = 4

--- Same rectangle as the FPS/durability strip on the action bar row. Used by LayoutActionStrip and UnifiedBorder gap fill when Info lives elsewhere.
--- @param forRealInfoFrame boolean true for FluxInfoFrame (stats height); false for backdrop-only sibling frame
--- @return boolean whether the slot exists and `f` was anchored
local function PositionFrameInActionStripSlot(f, forRealInfoFrame)
    local e = (not forRealInfoFrame and ACTION_STRIP_GAP_BACKDROP_BLEED) or 0
    if not f then
        return false
    end
    local combatGrid = FluxCombatManager and FluxCombatManager.Grid
    local nonCombatGrid = FluxNonCombatAPI and FluxNonCombatAPI.DefaultGrid
    local nonCombatFrame = nonCombatGrid and nonCombatGrid.Frame
    local ncShown = nonCombatFrame and nonCombatFrame:IsShown()
    local Cap = _G.Flux and _G.Flux.Cap
    local gamepadHud = Cap and Cap.IsGamepadUIEnabled and Cap.IsGamepadUIEnabled()
    if not gamepadHud and not ncShown then
        return false
    end

    local combatFrame = combatGrid and combatGrid.Frame
    local combatGridShown = combatFrame and combatFrame:IsShown()

    local actionBar = _G["FluxMainActionBar"]
    local actionBarActive = actionBar and actionBar:IsShown()
    local trinketMenu = FluxTrinketMenu and FluxTrinketMenu.Frame
    local trinketMenuShown = trinketMenu and trinketMenu:IsShown()
    local borderPadding = 8

    -- Grids are one row with no action bar between them. Info sits past the rightmost.
    if gamepadHud then
        if not forRealInfoFrame then
            return false
        end
        local rightmost
        if trinketMenuShown then
            rightmost = trinketMenu
        elseif combatGridShown then
            rightmost = combatFrame
        elseif ncShown then
            rightmost = nonCombatFrame
        end
        if not rightmost then
            return false
        end
        local heightRef = (ncShown and nonCombatFrame) or (combatGridShown and combatFrame) or rightmost
        UpdateStats()
        local rowH = heightRef.GetHeight and heightRef:GetHeight()
        if type(rowH) ~= "number" or rowH <= 0 then
            rowH = GetDynamicVerticalHeight()
        end
        f:SetHeight(rowH)
        f:SetWidth(CalculateMinimalWidth())
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", rightmost, "BOTTOMRIGHT", borderPadding - e, -e)
        f:SetPoint("TOP", heightRef, "TOP", 0, e)
        return true
    end

    local dynH = GetDynamicVerticalHeight()
    local combatHeight = (combatFrame and combatFrame:GetHeight()) or dynH
    local nonCombatHeight = nonCombatFrame:GetHeight() or dynH
    local targetHeight = math.max(combatHeight, nonCombatHeight)

    if forRealInfoFrame then
        f:SetHeight(targetHeight)
    end

    local infoLeftRef = nonCombatFrame
    local stripExtraWidth = 0

    if combatGridShown then
        if actionBarActive then
            local nonCombatRight = nonCombatFrame:GetRight()
            local combatLeft = combatFrame:GetLeft()
            if not nonCombatRight or not combatLeft then
                return false
            end
            local gapWidth = combatLeft - nonCombatRight
            if gapWidth - borderPadding - stripExtraWidth < 100 then
                return false
            end
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", infoLeftRef, "BOTTOMRIGHT", borderPadding / 2 - e, -e)
            f:SetPoint("BOTTOMRIGHT", combatFrame, "BOTTOMLEFT", -borderPadding / 2 + e, -e)
            f:SetPoint("TOP", nonCombatFrame, "TOP", 0, e)
            return true
        else
            if forRealInfoFrame then
                UpdateStats()
            end
            f:SetWidth(CalculateMinimalWidth())
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", infoLeftRef, "BOTTOMRIGHT", borderPadding / 2 - e, -e)
            f:SetPoint("TOP", nonCombatFrame, "TOP", 0, e)
            if forRealInfoFrame and FluxCombatManager and FluxCombatManager.UpdateAnchor then
                C_Timer.After(0.1, function()
                    if FluxCombatManager and FluxCombatManager.UpdateAnchor then FluxCombatManager:UpdateAnchor() end
                end)
            end
            return true
        end
    else
        if actionBarActive then
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", infoLeftRef, "BOTTOMRIGHT", borderPadding / 2 - e, -e)
            f:SetPoint("BOTTOMRIGHT", actionBar, "BOTTOMLEFT", 2, -e)
            f:SetPoint("TOP", nonCombatFrame, "TOP", 0, e)
            return true
        elseif trinketMenuShown then
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", infoLeftRef, "BOTTOMRIGHT", borderPadding / 2 - e, -e)
            f:SetPoint("BOTTOMRIGHT", trinketMenu, "BOTTOMLEFT", -borderPadding / 2 + e, -e)
            f:SetPoint("TOP", nonCombatFrame, "TOP", 0, e)
            return true
        else
            if forRealInfoFrame then
                UpdateStats()
            end
            f:SetWidth(CalculateMinimalWidth())
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", infoLeftRef, "BOTTOMRIGHT", borderPadding / 2 - e, -e)
            f:SetPoint("TOP", nonCombatFrame, "TOP", 0, e)
            return true
        end
    end
end

--- UnifiedBorder: fills the action-strip slot when Info is top-left / status-integrated (same geometry as LayoutActionStrip).
function InfoFrame.PositionActionStripSlotFrame(f)
    return PositionFrameInActionStripSlot(f, false)
end

local function LayoutActionStrip()
    InfoFrame.SetAnchoredByStatusBarColumn(false)
    if frame then
        frame.FluxIntegratedLoc1FullWidthCentered = nil
        if frame:GetParent() ~= UIParent then
            frame:SetParent(UIParent)
        end
    end
    if not frame then
        return
    end
    if not PositionFrameInActionStripSlot(frame, true) then
        frame:Hide()
        return
    end
    frame:Show()
    -- First paint should use the same dynamic merge/spacing logic as runtime
    -- updates to avoid a one-frame "wrong gap" on login/reload.
    UpdateStats()
end

--- FPS/dur/ping strip along the interior top edge of Minimap (inside mask/border stack, below Flux rim).
local function LayoutMinimapTop()
    InfoFrame.SetAnchoredByStatusBarColumn(false)
    if frame then
        frame.FluxIntegratedLoc1FullWidthCentered = nil
    end
    local mini = _G.Minimap
    if not mini or not mini:IsShown() then
        if frame then
            frame:Hide()
        end
        return
    end

    UpdateStats()

    local stripH = GetMinimapTopStripPixelHeight()
    local inset = GetBorderInsetForStack()
    local sidePad = inset + 1
    local topPad = inset + 2

    frame:SetParent(mini)
    frame:SetFrameStrata(mini:GetFrameStrata() or "MEDIUM")
    frame:SetFrameLevel(GetMinimapInteriorStripFrameLevel())
    if durabilityTooltipFrame then
        durabilityTooltipFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
    end

    frame:SetHeight(stripH)

    local mw = mini:GetWidth()
    if type(mw) ~= "number" or mw <= 0 then
        mw = 190
    end
    frame:SetWidth(math.max(10, mw - 2 * sidePad))

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", mini, "TOPLEFT", sidePad, -topPad)
    frame:SetPoint("TOPRIGHT", mini, "TOPRIGHT", -sidePad, -topPad)
    frame:Show()
    ApplyMinimapTopStripTextLayout()
end

--- Standalone panel at the screen top-left. Own border, vertical stat stack, not attached to status or the action strip.
function InfoFrame._LayoutScreenTopLeft()
    --- Widest single worst-case line. Stable across FPS / ping ticks.
    local function MeasureScreenTopLeftWidth()
        if InfoFrame._screenTopLeftWidth then
            return InfoFrame._screenTopLeftWidth
        end
        if activeLineCount == 0 then
            return 140
        end
        local fontPath = "Fonts\\FRIZQT__.TTF"
        local worstCaseTexts = {
            durability = "Dur: 100%",
            fps = "FPS: 333",
            ping = "Ping: 9999 ms",
            itemLevel = "iLvl: 999.9",
            gearScore = "GearScore: 99999",
        }
        local saved = {}
        local maxW = 80
        for i = 1, activeLineCount do
            local fs = activeLines[i].fs
            saved[i] = fs:GetText()
            fs:SetFont(fontPath, VERTICAL_FONT_BASE, "OUTLINE")
            if fs.SetWordWrap then fs:SetWordWrap(false) end
            if fs.SetWidth then fs:SetWidth(0) end
            local key = activeLines[i].key
            local wc = worstCaseTexts[key]
            local live = InfoFrame._camelotLiveCombatText and InfoFrame._camelotLiveCombatText[key]
            wc = wc or (live and live.sample)
            if not wc then
                local reg = STAT_REGISTRY[key]
                local label = (reg and reg.label) or key
                wc = label .. ": 9999"
            end
            fs:SetText(wc)
            local lineW = fs:GetStringWidth() or 0
            if lineW > maxW then
                maxW = lineW
            end
        end
        for i = 1, activeLineCount do
            local text = saved[i]
            if issecretvalue and issecretvalue(text) then activeLines[i].fs:SetText(text)
            else activeLines[i].fs:SetText(text or "") end
        end
        local width = math.min(320, math.max(120, math.ceil(maxW + INFO_FRAME_TEXT_PAD_X * 2 + 18)))
        InfoFrame._screenTopLeftWidth = width
        return width
    end

    InfoFrame.SetAnchoredByStatusBarColumn(false)
    if not frame then
        return
    end
    frame.FluxIntegratedLoc1FullWidthCentered = nil
    if frame:GetParent() ~= UIParent then
        frame:SetParent(UIParent)
    end
    if activeLineCount == 0 then
        frame:Hide()
        return
    end
    local n = activeLineCount
    local height = math.max(32, n * (VERTICAL_FONT_BASE + 6) + 12)
    frame:ClearAllPoints()
    frame:SetSize(MeasureScreenTopLeftWidth(), height)
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", INFO_TOPLEFT_X, INFO_TOPLEFT_Y)
    frame:Show()
end

--- Status bar places the cell. This pass only shows it once that anchor exists.
local function LayoutIntegrated()
    CreateInfoFrame()
    if not frame then
        return
    end
    frame.FluxIntegratedLoc1FullWidthCentered = nil
    if frame.FluxAnchoredByStatusBarColumn then
        frame:Show()
        return
    end
    frame:Hide()
end

local minimapHooksDone = false
local function EnsureMinimapHooks()
    if minimapHooksDone then
        return
    end
    local mini = _G.Minimap
    if not mini or not mini.HookScript then
        return
    end
    minimapHooksDone = true
    mini:HookScript("OnSizeChanged", function()
        if GetPlacement() == "minimapTop" and initialized then
            UpdatePosition()
        end
    end)
    mini:HookScript("OnShow", function()
        if GetPlacement() == "minimapTop" and initialized then
            UpdatePosition()
        end
    end)
    mini:HookScript("OnHide", function()
        if GetPlacement() == "minimapTop" and initialized then
            UpdatePosition()
        end
    end)
end

local statusBarContainerHooksDone = false
--- Strip width changes before a full FluxStatusBar UpdateLayout may need a refresh (fourth-column layout is owned by FluxStatusBar).
local function EnsureStatusBarContainerHooks()
    if statusBarContainerHooksDone then return end
    local sb = _G.FluxStatusBarContainer
    if not sb or not sb.HookScript then return end
    statusBarContainerHooksDone = true
    sb:HookScript("OnSizeChanged", function()
        -- Flux perf: FluxStatusBar.UpdateLayout already calls FluxInfoFrame
        -- UpdatePosition via NotifyStatusBarLayoutDependents. When that chain
        -- resizes the container as part of the same pass, OnSizeChanged
        -- fires mid-layout and would re-enter LayoutIntegrated pointlessly.
        -- Skip while we're still inside a layout tick; UpdatePosition is
        -- already throttled (INTEGRATED_LAYOUT_COOLDOWN) for real changes.
        if _inIntegratedLayout then return end
        if GetPlacement() == "statusIntegrated" and initialized then
            local fn = _G.FluxInfoFrame and _G.FluxInfoFrame.UpdatePosition
            if type(fn) == "function" then
                fn()
            end
        end
    end)
end

--- FluxBorder strip visuals + unified gap backdrop + PVP widget alignment. Heavy vs SetPoint on Info alone.
local function RefreshPlacementChromeAndDependents()
    SyncStripVisualWithPlacement()

    --- Gap backdrop is inside UnifiedBorder.UpdateBorder; PVP is batched — both run from FluxStatusBar notifier when integrated.
    if GetPlacement() == "statusIntegrated" then
        return
    end

    if FluxUnifiedBorder and FluxUnifiedBorder.UpdateActionStripInfoGapBackdrop then
        pcall(FluxUnifiedBorder.UpdateActionStripInfoGapBackdrop)
    end

    if _G.FluxPVPObjectiveMover and _G.FluxPVPObjectiveMover.UpdatePositions then
        pcall(_G.FluxPVPObjectiveMover.UpdatePositions)
    end
end

--- Full layout + chrome (options / non-integrated / forced refresh).
local function UpdatePositionImmediate()
    if InCombatLockdown() then return end
    EnsureStatusBarContainerHooks()
    EnsureMinimapHooks()
    CreateInfoFrame()
    if not frame then return end

    local placement = GetPlacement()
    -- Flux perf: toggle the 2s positionWatcher OnUpdate with placement so it
    -- only fires for actionStrip (the only mode that actually needs polling).
    _SyncPositionWatcher(placement)
    if placement == "statusIntegrated" then
        LayoutIntegrated()
    elseif placement == "minimapTop" then
        LayoutMinimapTop()
    elseif placement == "screenTopLeft" then
        InfoFrame._LayoutScreenTopLeft()
    else
        LayoutActionStrip()
    end

    RefreshPlacementChromeAndDependents()
    if placement == "screenTopLeft" and frame:IsShown() then
        UpdateStats()
    end
end

--- Status-integrated: only anchors (LayoutIntegrated) on the hot path; chrome/borders/PVP less often.
local INTEGRATED_HEAVY_COOLDOWN = 0.55
local lastIntegratedHeavyAt = -1e9

local function RunIntegratedLayoutPass(includeHeavyDependents)
    if InCombatLockdown() then return end
    EnsureStatusBarContainerHooks()
    EnsureMinimapHooks()
    CreateInfoFrame()
    if not frame then return end
    if GetPlacement() ~= "statusIntegrated" then return end

    LayoutIntegrated()

    if includeHeavyDependents then
        lastIntegratedHeavyAt = GetTime()
        RefreshPlacementChromeAndDependents()
        return
    end

    local now = GetTime()
    if now - lastIntegratedHeavyAt >= INTEGRATED_HEAVY_COOLDOWN then
        lastIntegratedHeavyAt = now
        RefreshPlacementChromeAndDependents()
    end
end

--- Status-integrated Info is anchored from FluxStatusBar + FluxMicroMenu; those layouts fire very often
--- (e.g. UpdateMicroButtons → micro UpdateLayout → FluxStatusBarUpdateLayout → NotifyStatusBarLayoutDependents).
--- Throttle coalesces bursts; heavy dependents are further rate-limited (see RunIntegratedLayoutPass).
local INTEGRATED_LAYOUT_COOLDOWN = 0.2
local integratedCooldownUntil = 0
local integratedCooldownTimer

local function CancelIntegratedCooldownTimer()
    if integratedCooldownTimer then
        if type(integratedCooldownTimer) == "table" and integratedCooldownTimer.Cancel then
            pcall(function()
                integratedCooldownTimer:Cancel()
            end)
        end
        integratedCooldownTimer = nil
    end
end

local function UpdatePosition()
    if InCombatLockdown() then return end
    if GetPlacement() ~= "statusIntegrated" then
        CancelIntegratedCooldownTimer()
        integratedCooldownUntil = 0
        lastIntegratedHeavyAt = -1e9
        -- Flux perf: leaving statusIntegrated — drop hash keys so the next
        -- entry re-lays out cleanly (previous key may match stale state set
        -- by LayoutActionStrip / LayoutMinimapTop).
        _lastIntegratedKey = nil
        _lastPrepareStripKey = nil
        return UpdatePositionImmediate()
    end

    local now = GetTime()
    if now >= integratedCooldownUntil then
        integratedCooldownUntil = now + INTEGRATED_LAYOUT_COOLDOWN
        return RunIntegratedLayoutPass(false)
    end

    if integratedCooldownTimer then
        return
    end

    local wait = math.max(0.001, integratedCooldownUntil - now)
    if C_Timer and C_Timer.After then
        integratedCooldownTimer = C_Timer.After(wait, function()
            integratedCooldownTimer = nil
            integratedCooldownUntil = GetTime() + INTEGRATED_LAYOUT_COOLDOWN
            if InCombatLockdown() then return end
            if GetPlacement() ~= "statusIntegrated" then return end
            RunIntegratedLayoutPass(false)
        end)
    else
        RunIntegratedLayoutPass(false)
    end
end

-- EVENT-BASED: Stats updates via events and less frequent timer
local updateFrame = CreateFrame("Frame", "FluxInfoStatsEventDriver")

-- Register events that might affect stats
updateFrame:RegisterEvent("ZONE_CHANGED")
updateFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
updateFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
updateFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
pcall(function() updateFrame:RegisterEvent("UPDATE_INVENTORY_ALERTS") end)
pcall(function() updateFrame:RegisterUnitEvent("UNIT_AURA", "player") end)
updateFrame:RegisterEvent("COMBAT_RATING_UPDATE")
updateFrame:RegisterEvent("MASTERY_UPDATE")
updateFrame:RegisterEvent("SPELL_POWER_CHANGED")
pcall(function() updateFrame:RegisterUnitEvent("UNIT_STATS", "player") end)
updateFrame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
if InfoFrame._IsCamelotClient() then
    updateFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    updateFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    updateFrame:RegisterUnitEvent("UNIT_SPELL_HASTE", "player")
end
-- Note: Durability % is cached ~1s; equip/inventory alerts invalidate the cache.

updateFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" and InfoFrame._rebuildAfterCombat then
        InfoFrame._rebuildAfterCombat = nil
        InfoFrame.ForceRebuild()
    end
    if event == "PLAYER_EQUIPMENT_CHANGED" or event == "UPDATE_INVENTORY_ALERTS" then
        InvalidateDurabilityCache()
    end
    if event == "UNIT_AURA" then
        local unit = ...
        if unit ~= "player" then
            return
        end
        -- Flux perf: first buff hitch — skip when strip hidden or no aura-sensitive pins.
        if not (frame and frame:IsShown()) then
            return
        end
        if not HasDynamicPinnedStat() then
            return
        end
    elseif event == "UNIT_STATS" then
        local unit = ...
        if unit ~= "player" then
            return
        end
    end
    InfoFrame.RequestStatRefresh()
end)

-- Flux perf T3.5: replace the permanent OnUpdate accumulator with a C_Timer
-- NewTicker created on Show and cancelled on Hide. The previous implementation
-- ran every frame for the sole purpose of checking a 1s threshold, even when
-- the frame was hidden. The ticker runs only while the frame is visible and
-- costs nothing when hidden.
local infoStatsTicker = nil

local function _StartInfoStatsTicker()
    if infoStatsTicker then return end
    if not (C_Timer and C_Timer.NewTicker) then return end
    infoStatsTicker = C_Timer.NewTicker(1.0, function()
        if frame and frame:IsShown() then
            UpdateStats()
        end
    end)
end

local function _StopInfoStatsTicker()
    if infoStatsTicker then
        if infoStatsTicker.Cancel then infoStatsTicker:Cancel() end
        infoStatsTicker = nil
    end
end

-- Flux perf: the previous implementation attached a permanent OnUpdate to a
-- watcher frame solely to detect when `frame` existed, then installed the
-- show/hide hooks. Replaced with a direct one-call bind function invoked from
-- CreateInfoFrame(). Zero per-frame cost, same lifecycle.
local _infoFrameTickerHooksInstalled = false
_InstallInfoFrameTickerHooks = function()
    if _infoFrameTickerHooksInstalled then return end
    if not frame then return end
    _infoFrameTickerHooksInstalled = true
    frame:HookScript("OnShow", _StartInfoStatsTicker)
    frame:HookScript("OnHide", _StopInfoStatsTicker)
    if frame:IsShown() then
        _StartInfoStatsTicker()
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local microMenuHooksDone = false
local function EnsureMicroMenuHooks()
    if microMenuHooksDone then return end
    local mm = _G.FluxMicroMenu
    if not mm or not mm.HookScript then return end
    microMenuHooksDone = true
    mm:HookScript("OnSizeChanged", function()
        if GetPlacement() == "statusIntegrated" and initialized then
            UpdatePosition()
        end
    end)
    mm:HookScript("OnShow", function()
        if GetPlacement() == "statusIntegrated" and initialized then
            UpdatePosition()
        end
    end)
    mm:HookScript("OnHide", function()
        if GetPlacement() == "statusIntegrated" and initialized then
            UpdatePosition()
        end
    end)
end

local function Initialize()
    if InCombatLockdown() then return false end
    
    -- Create frame if not exists
    if not frame then
        CreateInfoFrame()
    end
    
    EnsureMicroMenuHooks()
    EnsureStatusBarContainerHooks()

    -- Try to update position
    UpdatePosition()
    
    -- Initial stats update
    UpdateStats()
    
    return true
end

-- ============================================================================
-- WATCHER PATTERN (similar to GridManager.lua)
-- ============================================================================

local initialized = false
local watcherFrame = CreateFrame("Frame", "FluxInfoStartupDriver")
local checkCount = 0
local MAX_CHECKS = 30 -- Safety limit: ~0.5 seconds at 60fps

local function TryInitialize(force)
    if InCombatLockdown() then return false end
    if initialized then return true end
    
    -- Check if both grids are available
    local hasCombatGrid = FluxCombatManager and FluxCombatManager.Grid and FluxCombatManager.Grid.Frame
    local hasNonCombatGrid = FluxNonCombatAPI and FluxNonCombatAPI.DefaultGrid and FluxNonCombatAPI.DefaultGrid.Frame
    
    local placementEarly = GetPlacement()
    -- Allow status-integrated mode without waiting for both grids (Info anchors to micro/status).
    if force or (hasCombatGrid and hasNonCombatGrid) or placementEarly ~= "actionStrip" then
        if Initialize() then
            initialized = true
            watcherFrame:SetScript("OnUpdate", nil) -- Stop watching
            return true
        end
    end
    
    return false
end

-- EVENT-BASED: Grid position updates via hooks and frame scripts (no continuous OnUpdate)
-- Hook into grid relayout functions if available
local function HookGridRelayout()
    -- Try to hook grid relayout functions
    if FluxNonCombatGrid and FluxNonCombatGrid.Relayout and not FluxNonCombatGrid._fluxInfoRelayoutHooked then
        FluxNonCombatGrid._fluxInfoRelayoutHooked = true
        hooksecurefunc(FluxNonCombatGrid, "Relayout", function()
            if initialized and frame and frame:IsShown() then
                UpdatePosition()
            end
        end)
    end
    
    if FluxCombatGrid and FluxCombatGrid.Relayout and not FluxCombatGrid._fluxInfoRelayoutHooked then
        FluxCombatGrid._fluxInfoRelayoutHooked = true
        hooksecurefunc(FluxCombatGrid, "Relayout", function()
            if initialized and frame and frame:IsShown() then
                UpdatePosition()
            end
        end)
    end
    
    -- Hook grid frame OnSizeChanged (OnMove doesn't exist in WoW, so we use a timer for position changes)
    local combatGrid = FluxCombatManager and FluxCombatManager.Grid
    local nonCombatGrid = FluxNonCombatAPI and FluxNonCombatAPI.DefaultGrid
    
    if combatGrid and combatGrid.Frame and not combatGrid.Frame._fluxInfoSizeHooked then
        combatGrid.Frame._fluxInfoSizeHooked = true
        combatGrid.Frame:HookScript("OnSizeChanged", function()
            if initialized and frame and frame:IsShown() then
                UpdatePosition()
            end
        end)
    end
    
    if nonCombatGrid and nonCombatGrid.Frame and not nonCombatGrid.Frame._fluxInfoSizeHooked then
        nonCombatGrid.Frame._fluxInfoSizeHooked = true
        nonCombatGrid.Frame:HookScript("OnSizeChanged", function()
            if initialized and frame and frame:IsShown() then
                UpdatePosition()
            end
        end)
    end
end

-- Try to hook immediately, or after a delay if grids aren't ready
if (FluxCombatManager and FluxCombatManager.Grid) or (FluxNonCombatAPI and FluxNonCombatAPI.DefaultGrid) then
    HookGridRelayout()
else
    C_Timer.After(1.0, function()
        HookGridRelayout()
    end)
end

-- Less frequent timer for position updates (only when frame is shown, every 2 seconds)
-- This handles position changes since OnMove doesn't exist in WoW.
-- Flux perf: only actionStrip placement needs this 2s poll. statusIntegrated
-- is driven by FluxStatusBar + FluxMicroMenu hooks; minimapTop is driven by
-- Minimap OnSizeChanged/OnShow/OnHide hooks.
local positionWatcher = CreateFrame("Frame", "FluxInfoPositionDriver")
local positionElapsed = 0
local positionTicker

local function _PositionWatcherOnUpdate(self, elapsed)
    if not initialized or not frame or not frame:IsShown() then return end
    positionElapsed = positionElapsed + elapsed
    if positionElapsed >= 2.0 then
        positionElapsed = 0
        UpdatePosition()
    end
end

local function _PositionTickerTick()
    if not initialized or not frame or not frame:IsShown() then
        return
    end
    UpdatePosition()
end

local _positionWatcherAttached = false
_SyncPositionWatcher = function(placement)
    local shouldRun = (placement == "actionStrip")
    if shouldRun and not _positionWatcherAttached then
        positionElapsed = 0
        if C_Timer and C_Timer.NewTicker then
            positionTicker = C_Timer.NewTicker(2, _PositionTickerTick)
        else
            positionWatcher:SetScript("OnUpdate", _PositionWatcherOnUpdate)
        end
        _positionWatcherAttached = true
    elseif (not shouldRun) and _positionWatcherAttached then
        if positionTicker then
            positionTicker:Cancel()
            positionTicker = nil
        end
        positionWatcher:SetScript("OnUpdate", nil)
        _positionWatcherAttached = false
    end
end

-- Initial attach reflects current placement (default = actionStrip).
_SyncPositionWatcher(GetPlacement())

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Character Info pin hooks (retry-safe; CharacterInfo also calls this).
        if InfoFrame.InstallCharacterInfoPinHooks then
            InfoFrame.InstallCharacterInfoPinHooks()
        end
        -- Try to initialize immediately
        if TryInitialize(false) then
            return
        end
        
        -- If not initialized, watch every frame until grids are available
        checkCount = 0
        watcherFrame:SetScript("OnUpdate", function(self, elapsed)
            checkCount = checkCount + 1
            if TryInitialize(false) or checkCount >= MAX_CHECKS then
                -- If we hit the limit, force initialization
                if checkCount >= MAX_CHECKS and not initialized then
                    TryInitialize(true)
                end
                self:SetScript("OnUpdate", nil)
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Update position and stats after loading screen
        if initialized then
            UpdatePosition()
            UpdateStats()
            -- Setup grid hooks after entering world
            HookGridRelayout()
        else
            -- Try to initialize if not already done
            TryInitialize(false)
        end
    end
end)

-- Export
_G.FluxInfoFrame = InfoFrame

-- Export GetFrame function for external access
function InfoFrame.GetFrame()
    return frame
end

--- Narrow Info cell on status bar location 3 (worst-case string width; does not resize with live numbers).
function InfoFrame.GetStableIntegratedColumnWidth()
    CreateInfoFrame()
    if not cachedStableIntegratedClusterWidth then
        cachedStableIntegratedClusterWidth = MeasureStableIntegratedClusterWidth()
    end
    return cachedStableIntegratedClusterWidth
end

-- Export UpdatePosition for external refresh (e.g. when Combat Grid hides)
InfoFrame.UpdatePosition = UpdatePosition

--- Immediate full layout (options / user toggles placement). Bypasses status-integrated throttle.
function InfoFrame.ForceUpdatePosition()
    if InCombatLockdown() then return end
    CancelIntegratedCooldownTimer()
    integratedCooldownUntil = 0
    _lastIntegratedKey = nil
    _lastPrepareStripKey = nil
    _cachedActionStripMinimalWidth = nil
    local placement = GetPlacement()
    _SyncPositionWatcher(placement)
    if placement == "statusIntegrated" then
        lastIntegratedHeavyAt = GetTime()
        RunIntegratedLayoutPass(true)
    else
        UpdatePositionImmediate()
    end
    if frame and frame:IsShown() then
        UpdateStats()
    end
end

--- Rebuild dynamic lines from charDB and force a full layout refresh.
function InfoFrame.ForceRebuild()
    if InfoFrame._IsCamelotClient() and InCombatLockdown() then
        InfoFrame._rebuildAfterCombat = true
        return
    end
    if not frame then return end
    RebuildInfoLines()
    if GetPlacement() == "statusIntegrated" and _G.FluxStatusBarUpdateLayout then
        pcall(_G.FluxStatusBarUpdateLayout)
    end
    InfoFrame.ForceUpdatePosition()
    if frame:IsShown() then
        UpdateStats()
    end
end

local function _IsRetailMainlineProject()
    local pid = rawget(_G, "WOW_PROJECT_ID")
    local mainline = rawget(_G, "WOW_PROJECT_MAINLINE")
    return type(pid) == "number" and type(mainline) == "number" and pid == mainline
end

--- Toggle a pinned stat on/off. Called from character panel click hooks.
function InfoFrame.TogglePinnedStat(statKey)
    statKey = InfoFrame._ClassicSpellPinKey(statKey) or _CanonicalIlvlGsRegistryKey(statKey) or statKey
    statKey = InfoFrame._CamelotCombatStatKey(statKey)
    if statKey == "moveSpeed" or statKey == "movement_speed" then
        statKey = "speed"
    end
    local db = GetInfoFrameCharDB()

    -- Dragonflight+: one crit row on paper doll; merge legacy melee/ranged/spell pin keys.
    if _IsRetailMainlineProject() and statKey and (statKey == "meleeCrit" or statKey == "rangedCrit" or statKey == "crit") then
        if not STAT_REGISTRY["crit"] then return end
        local any = db.pinnedStats["meleeCrit"] or db.pinnedStats["rangedCrit"] or db.pinnedStats["crit"]
        db.pinnedStats["meleeCrit"] = nil
        db.pinnedStats["rangedCrit"] = nil
        db.pinnedStats["crit"] = nil
        if not any then
            db.pinnedStats["crit"] = true
        end
        InfoFrame.ForceRebuild()
        return
    end

    if not statKey or not STAT_REGISTRY[statKey] then return end
    if InfoFrame._UseClassicSpellPowerLine() and (statKey == "spellPower" or statKey == "healPower" or statKey == "spellPowerOnly") then
        if statKey == "spellPowerOnly" then
            statKey = "spellPower"
        end
        local mode = db.spellDisplayMode or "off"
        local hasSp = mode == "sp" or mode == "both"
        local hasHeal = mode == "heal" or mode == "both"
        if statKey == "healPower" then
            hasHeal = not hasHeal
        else
            hasSp = not hasSp
        end
        if hasSp and hasHeal then
            mode = "both"
        elseif hasSp then
            mode = "sp"
        elseif hasHeal then
            mode = "heal"
        else
            mode = "off"
        end
        db.spellDisplayMode = mode
        db.pinnedStats["spellPower"] = (hasSp or hasHeal) and true or nil
        db.pinnedStats["healPower"] = hasHeal and true or nil
        InfoFrame.ForceRebuild()
        return
    end
    if statKey == "spellPower" or statKey == "healPower" or statKey == "spellPowerOnly" then
        local mode = db.spellDisplayMode or "off"
        if mode == "off" then
            mode = "sp"
        elseif mode == "sp" then
            mode = "heal"
        elseif mode == "heal" then
            mode = "both"
        else
            mode = "off"
        end
        db.spellDisplayMode = mode
        db.pinnedStats["spellPower"] = (mode == "sp" or mode == "both") and true or nil
        db.pinnedStats["healPower"] = (mode == "heal" or mode == "both") and true or nil
        InfoFrame.ForceRebuild()
        return
    end
    if db.pinnedStats[statKey] then
        db.pinnedStats[statKey] = nil
    else
        db.pinnedStats[statKey] = true
    end
    InfoFrame.ForceRebuild()
end

--- Check if a stat is currently pinned.
function InfoFrame.IsStatPinned(statKey)
    local db = GetInfoFrameCharDB()
    statKey = InfoFrame._CamelotCombatStatKey(statKey)
    if statKey == "spellPower" or statKey == "spellPowerOnly" then
        local mode = db.spellDisplayMode or "off"
        if InfoFrame._UseClassicSpellPowerLine() then
            return mode == "sp" or mode == "both"
        end
        return mode ~= "off"
    end
    if statKey == "healPower" then
        local mode = db.spellDisplayMode or "off"
        return mode == "heal" or mode == "both"
    end
    statKey = _CanonicalIlvlGsRegistryKey(statKey) or statKey
    if statKey == "moveSpeed" or statKey == "movement_speed" then
        statKey = "speed"
    end
    if _IsRetailMainlineProject() and (statKey == "meleeCrit" or statKey == "rangedCrit" or statKey == "crit") then
        return db.pinnedStats["meleeCrit"] == true or db.pinnedStats["rangedCrit"] == true or db.pinnedStats["crit"] == true
    end
    return db.pinnedStats[statKey] == true
end

-- ============================================================================
-- CLICK-TO-PIN HOOKS (Retail PaperDollFrame + Classic CSC stat frames)
-- ============================================================================

local PIN_ICON_CHAR = "|TInterface\\Buttons\\UI-CheckBox-Check:14:14:1:0|t"
local PIN_HOOK_TAG = "_FluxInfoPinHooked"
local RefreshAllPinIndicators
--- PaperDoll item level row is not in CharacterStatsPane.statsFramePool (post–Dragonflight).
local _retailPaperDollItemLevelStatFrame = nil

--- Map Blizzard retail stat labels to our STAT_REGISTRY keys.
local retailStatLabelMap = {
    -- Crit: mainline paper doll has one rating; use "crit" so pins match STAT_REGISTRY + saved vars.
    ["Critical Strike"] = "crit",
    ["Crit"] = "crit",
    ["Melee Critical Strike"] = "crit",
    ["Damage"] = "weaponDamage",
    ["Attack Power"] = "attackPower",
    ["Hit"] = "meleeHit",
    ["Hit Chance"] = "meleeHit",
    ["Melee Hit"] = "meleeHit",
    ["Melee Hit Chance"] = "meleeHit",
    ["Expertise"] = "expertise",
    ["Attack Speed"] = "weaponSpeed",
    ["Weapon Speed"] = "weaponSpeed",
    ["Melee Speed"] = "weaponSpeed",
    -- Ranged
    ["Ranged Damage"] = "rangedWeaponDamage",
    ["Ranged Attack Power"] = "rangedAttackPower",
    ["Ranged Speed"] = "rangedWeaponSpeed",
    ["Ranged Attack Speed"] = "rangedWeaponSpeed",
    ["Ranged Critical Strike"] = "rangedCrit",
    ["Ranged Crit"] = "rangedCrit",
    ["Ranged Hit"] = "rangedHit",
    ["Ranged Hit Chance"] = "rangedHit",
    -- Spell
    ["Spell Critical Strike"] = "crit",
    ["Spell Crit"] = "crit",
    ["Spell Critical"] = "crit",
    ["Spell Hit"] = "spellHit",
    ["Spell Hit Chance"] = "spellHit",
    ["Haste"] = "haste",
    ["Spell Haste"] = "haste",
    ["Mastery"] = "mastery",
    ["Versatility"] = "versatility", ["Vers"] = "versatility",
    ["Armor"] = "armor",
    ["Bonus Armor"] = "armor",
    ["Dodge"] = "dodge",
    ["Parry"] = "parry",
    ["Block"] = "block",
    ["Spell Power"] = "spellPower",
    ["Intellect"] = "intellect",     ["Int"] = "intellect",
    ["Healing Power"] = "healPower",  ["Healing"] = "healPower",
    ["Spell Penetration"] = "spellPenetration",
    ["Armor Penetration"] = "meleeArmorPenetration",
    ["Speed"] = "speed",
    ["Movement Speed"] = "speed",
    ["Health"] = "health",
    ["HP"] = "health",
    ["Mana"] = "power",
    ["Rage"] = "power",
    ["Energy"] = "power",
    ["Focus"] = "power",
    ["Runic Power"] = "power",
    ["Main Hand"] = "weaponDamage",
    ["Off Hand"] = "weaponDamage",
    ["Ranged"] = "rangedWeaponDamage",
    ["Leech"] = "leech",
    ["Avoidance"] = "avoidance",
    ["Defense"] = "defense",
    ["Resilience"] = "resilience",
    ["Strength"] = "strength",       ["Str"] = "strength",
    ["Agility"] = "agility",         ["Agi"] = "agility",
    ["Stamina"] = "stamina",         ["Sta"] = "stamina",
    ["Spirit"] = "spirit",           ["Spi"] = "spirit",
    ["Mana Regen"] = "mp5",          ["Mana regeneration"] = "mp5",
    ["Mana Regeneration"] = "mp5",   ["Mana regen"] = "mp5",
    ["Item LvL"] = "itemLevel",
    ["Item LvL:"] = "itemLevel",
    ["Item Level"] = "itemLevel",
    ["Average Item Level"] = "itemLevel",
    ["Avg Item Level"] = "itemLevel",
    ["iLvl"] = "itemLevel",
    ["iLvl:"] = "itemLevel",
    ["GearScore"] = "gearScore",
    ["GearScore:"] = "gearScore",
    ["G.S."] = "gearScore",
    ["G.S.:"] = "gearScore",
}

--- Sanitize a display label into a stable registry key (lowercase, underscores).
local function _SanitizeStatKey(label)
    if not label or label == "" then return nil end
    local k = label:lower():gsub("[:%s]+$", ""):gsub("%s+", "_"):gsub("[^%w_]", "")
    return k ~= "" and k or nil
end

--- Create a minimal registry entry for an unknown stat so it can be pinned.
--- The get() returns nil (no independent provider); the label is preserved.
local function EnsureDynamicStatInRegistry(key, label)
    if not key or STAT_REGISTRY[key] then return end
    STAT_REGISTRY[key] = {
        label = label or key,
        order = 500,
        get = function()
            local cache = InfoFrame._foreverStatCache
            if cache and cache[key] ~= nil then
                return cache[key]
            end
            if InfoFrame.ReadForeverDisplayText then
                return InfoFrame.ReadForeverDisplayText(key)
            end
            return nil
        end,
        fmt = "%s",
        _dynamic = true,
    }
end

local function _GetStatLabelRegionAndText(statFrame)
    if not statFrame then return nil, nil end
    local candidates = {
        statFrame.Label, statFrame.label, statFrame.Title, statFrame.title,
        statFrame.Name, statFrame.name,
        statFrame.StatLabel, statFrame.statLabel,
    }
    for i = 1, #candidates do
        local reg = candidates[i]
        if reg and reg.GetText then
            local t = reg:GetText()
            if type(t) == "string" and t ~= "" then
                -- Strip color escapes for matching/sanitizing.
                t = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                return reg, t
            end
        end
    end
    return nil, nil
end

local function _StatFrameHasValueRegion(statFrame)
    if not statFrame then return false end
    local vals = {
        statFrame.Value, statFrame.value, statFrame.ValueText, statFrame.valueText,
        statFrame.RightText, statFrame.rightText,
    }
    for i = 1, #vals do
        local v = vals[i]
        if v and v.GetText then
            return true
        end
    end
    return false
end

local function GetRetailStatKey(statFrame)
    local _, labelText = _GetStatLabelRegionAndText(statFrame)
    if not labelText then return nil end
    local clean = labelText:gsub("[:%s]+$", "")
    -- Forever Character Info uses Blizzard globals ("Main Hand", HEALTH, STAT_MOVEMENT_SPEED)
    -- that are not the Live paper-doll labels. Match those before the English map so
    -- "Speed" on Camelot is movement speed, not CR_SPEED.
    local api = _G.FLUX_API
    if api and (api.isCamelot or api.isForever) then
        local foreverGlobals = {
            HEALTH = "health",
            MANA = "power",
            RAGE = "power",
            ENERGY = "power",
            FOCUS = "power",
            RUNIC_POWER = "power",
            STAT_MOVEMENT_SPEED = "speed",
            STAT_SPEED = "speed",
            INVTYPE_WEAPONMAINHAND = "weaponDamage",
            INVTYPE_WEAPONOFFHAND = "weaponDamage",
            INVTYPE_RANGED = "rangedWeaponDamage",
            INVTYPE_RANGEDRIGHT = "rangedWeaponDamage",
            INVTYPE_THROWN = "rangedWeaponDamage",
            DAMAGE = "weaponDamage",
            STAT_ATTACK_POWER = "attackPower",
            MELEE_ATTACK_POWER = "attackPower",
            RANGED_ATTACK_POWER = "rangedAttackPower",
            STAT_HIT_CHANCE = "meleeHit",
            STAT_CRITICAL_STRIKE = "crit",
            STAT_HASTE = "haste",
            STAT_EXPERTISE = "expertise",
            STAT_ARMOR_PENETRATION = "meleeArmorPenetration",
            STAT_SPELLPOWER = "spellPower",
            STAT_SPELLHEALING = "healPower",
            DEFENSE = "defense",
            STAT_DODGE = "dodge",
            STAT_PARRY = "parry",
            STAT_BLOCK = "block",
            STAT_ARMOR = "armor",
            SPELL_STAT1_NAME = "strength",
            SPELL_STAT2_NAME = "agility",
            SPELL_STAT3_NAME = "stamina",
            SPELL_STAT4_NAME = "intellect",
            SPELL_STAT5_NAME = "spirit",
        }
        for gname, key in pairs(foreverGlobals) do
            local g = _G[gname]
            if type(g) == "string" and clean == g then
                return key
            end
        end
    end
    -- Check known map (case-insensitive).
    if retailStatLabelMap[clean] then return retailStatLabelMap[clean] end
    local lower = clean:lower()
    for mapLabel, key in pairs(retailStatLabelMap) do
        if lower == mapLabel:lower() then return key end
    end
    local spellPin = InfoFrame._ClassicSpellPinKey(clean)
    if spellPin then
        return spellPin
    end
    -- Unknown stat → dynamic key so it can still be pinned.
    local dynKey = _SanitizeStatKey(clean)
    if dynKey then
        EnsureDynamicStatInRegistry(dynKey, clean)
        return dynKey
    end
    return nil
end

local function UpdatePinIndicator(statFrame, statKey)
    if not statFrame then return end
    if not statFrame._fluxPinIndicatorTex then
        local tex = statFrame:CreateTexture(nil, "OVERLAY")
        tex:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        tex:SetSize(14, 14)
        statFrame._fluxPinIndicatorTex = tex
    end
    local labelRegion = select(1, _GetStatLabelRegionAndText(statFrame))
    local tex = statFrame._fluxPinIndicatorTex
    tex:ClearAllPoints()
    -- Blizzard retail CharacterStatsPane.ItemLevelFrame: no Label, only a centered Value.
    -- Flux wrist row (pre-retail) has Label+Value; anchoring pin→Value while Value→pin causes a layout cycle.
    if statKey == "itemLevel" and statFrame.Value and statFrame.Value.GetStringWidth and not labelRegion then
        tex:SetPoint("RIGHT", statFrame.Value, "LEFT", -6, 0)
    elseif labelRegion then
        -- Anchor to the rendered text end (not the fontstring frame edge), so the
        -- check sits directly after ":" with no visual gap.
        local textW = labelRegion.GetStringWidth and (labelRegion:GetStringWidth() or 0) or 0
        tex:SetPoint("LEFT", labelRegion, "LEFT", textW, 0)
    else
        tex:SetPoint("RIGHT", statFrame, "RIGHT", -2, 0)
    end
    if statKey and InfoFrame.IsStatPinned(statKey) then
        local r, g, b = 1, 1, 1
        if statKey == "spellPower" or statKey == "healPower" or statKey == "spellPowerOnly" then
            local mode = GetInfoFrameCharDB().spellDisplayMode or "off"
            local camelot = InfoFrame._IsCamelotClient()
            local damagePin = statKey == "spellPower" or statKey == "spellPowerOnly"
            local healPin = statKey == "healPower"
            if healPin and (mode == "heal" or (camelot and mode == "both")) then
                r, g, b = 0.125, 1, 0.125
            elseif mode == "heal" and not camelot then
                r, g, b = 0.125, 1, 0.125
            elseif damagePin and (mode == "sp" or (camelot and mode == "both")) then
                local schoolHex = _GetSpellPowerTopSchoolColorNoTie() or "ffffff"
                local rr = tonumber(schoolHex:sub(1, 2), 16)
                local gg = tonumber(schoolHex:sub(3, 4), 16)
                local bb = tonumber(schoolHex:sub(5, 6), 16)
                if rr and gg and bb then
                    r, g, b = rr / 255, gg / 255, bb / 255
                end
            elseif mode == "sp" then
                local schoolHex = _GetSpellPowerTopSchoolColorNoTie() or "ffffff"
                local rr = tonumber(schoolHex:sub(1, 2), 16)
                local gg = tonumber(schoolHex:sub(3, 4), 16)
                local bb = tonumber(schoolHex:sub(5, 6), 16)
                if rr and gg and bb then
                    r, g, b = rr / 255, gg / 255, bb / 255
                end
            end
        end
        tex:SetVertexColor(r, g, b, 1)
        tex:Show()
    else
        tex:Hide()
    end
end

local function HookRetailStatFrame(statFrame)
    if not statFrame or statFrame[PIN_HOOK_TAG] then return end
    statFrame[PIN_HOOK_TAG] = true
    if statFrame.EnableMouse then
        statFrame:EnableMouse(true)
    end
    if statFrame.SetMouseClickEnabled then
        statFrame:SetMouseClickEnabled(true)
    end
    -- Forever ScrollBox rows are Frames with OnEnter only. HookScript("OnMouseUp")
    -- is a no-op on some clients until a handler exists — SetScript first.
    local function onPinMouse(self, button)
        if button ~= nil and button ~= "LeftButton" then
            return
        end
        local key = self._FluxInfoStatKey or GetRetailStatKey(self)
        if key then
            InfoFrame.TogglePinnedStat(key)
            RefreshAllPinIndicators()
        end
    end
    if statFrame.GetScript and statFrame:GetScript("OnMouseUp") then
        statFrame:HookScript("OnMouseUp", onPinMouse)
    elseif statFrame.SetScript then
        statFrame:SetScript("OnMouseUp", onPinMouse)
    elseif statFrame.HookScript then
        statFrame:HookScript("OnMouseUp", onPinMouse)
    end
end

local function RefreshRetailPinIndicators()
    if InfoFrame._IsCamelotClient() and InCombatLockdown() then return end
    if _retailPaperDollItemLevelStatFrame and _retailPaperDollItemLevelStatFrame.GetParent then
        local sf = _retailPaperDollItemLevelStatFrame
        if sf:GetParent() then
            local key = GetRetailStatKey(sf) or "itemLevel"
            if sf._FluxInfoStatKey ~= key then _InvalidateTooltipStatFrameCache() end
            sf._FluxInfoStatKey = key
            HookRetailStatFrame(sf)
            UpdatePinIndicator(sf, key)
        end
    end

    local function pinOne(statFrame, elementData)
        if not statFrame or statFrame.Title then return end
        if not (statFrame.Label or statFrame.Value) then return end
        local key = statFrame._FluxInfoStatKey
        local map = InfoFrame._foreverPaperDollStatToKey
        if (not elementData) and statFrame.GetElementData then
            local okData, data = pcall(statFrame.GetElementData, statFrame)
            if okData then
                elementData = data
            end
        end
        if map and elementData and type(elementData.name) == "string" then
            key = map[elementData.name] or key
        end
        key = InfoFrame._CamelotCombatStatKey(key or GetRetailStatKey(statFrame))
        if key then
            if statFrame._FluxInfoStatKey ~= key then _InvalidateTooltipStatFrameCache() end
            statFrame._FluxInfoStatKey = key
            HookRetailStatFrame(statFrame)
            UpdatePinIndicator(statFrame, key)
            if InfoFrame.RememberPinnedStatValue then
                InfoFrame.RememberPinnedStatValue(key, statFrame.numericValue, statFrame)
            end
        end
    end

    local pane = _G.CharacterStatsPane
    if pane and pane.statsFramePool and pane.statsFramePool.EnumerateActive then
        -- Live / Cata: visible rows are the pool. Forever uses the pool as scratch
        -- during ScrollBox rebuild, then releases it — still safe to scan.
        for statFrame in pane.statsFramePool:EnumerateActive() do
            pinOne(statFrame)
        end
    end

    -- Forever Camelot: visible rows are CharacterStatsPaneScrollBox list elements.
    -- Nested (not a main-chunk local): Lua 5.1 caps the file at 200 locals.
    local root = _G.CharacterStatsPaneScrollBox
    if root and root ~= _G.CharacterStatsPanePetScrollBox then
        local box = root.ScrollBox
        local view = box and box.GetView and box:GetView()
        local frames = view and view.GetFrames and view:GetFrames()
        if type(frames) == "table" then
            for i = 1, #frames do
                pinOne(frames[i])
            end
        elseif box and box.ForEachFrame then
            box:ForEachFrame(function(frame, elementData)
                pinOne(frame, elementData)
            end)
        end
    end
end

InfoFrame.RefreshRetailPinIndicators = RefreshRetailPinIndicators

--- Classic CSC stat label → registry key mapping.
local classicStatLabelMap = {
    ["Power:"] = "spellPower",   ["Spell:"] = "spellPower",
    ["Spell Power:"] = "spellPower", ["Spell Power"] = "spellPower",
    ["Crit:"] = "crit",
    ["Hit:"] = "spellHit",
    ["Haste:"] = "haste",
    ["Haste"] = "haste",
    ["Heal:"] = "healPower",     ["Healing:"] = "healPower",
    ["Damage:"] = "weaponDamage",
    ["AP:"] = "attackPower",
    ["Attack Power:"] = "attackPower",
    ["Ranged Damage:"] = "rangedWeaponDamage",
    ["Attack Speed:"] = "weaponSpeed",
    ["Armor:"] = "armor",
    ["Defense:"] = "defense",
    ["Dodge:"] = "dodge",
    ["Parry:"] = "parry",
    ["Block:"] = "block",
    ["Resilience:"] = "resilience",
    ["Spell Penetration:"] = "spellPenetration",
    ["MP5:"] = "mp5",
    ["MP5"] = "mp5",
    ["Mana Regen:"] = "mp5", ["Mana regeneration:"] = "mp5",
    ["Mana Regeneration:"] = "mp5",
    ["Expertise:"] = "expertise",
    ["Melee Crit:"] = "meleeCrit",
    ["Ranged Crit:"] = "rangedCrit",
    ["R.Crit:"] = "rangedCrit",
    ["Melee Hit:"] = "meleeHit",
    ["Ranged Hit:"] = "rangedHit",
    ["R.Hit:"] = "rangedHit",
    ["Strength:"] = "strength",  ["Str:"] = "strength",
    ["Agility:"] = "agility",    ["Agi:"] = "agility",
    ["Stamina:"] = "stamina",    ["Sta:"] = "stamina",
    ["Intellect:"] = "intellect",["Int:"] = "intellect",
    ["Spirit:"] = "spirit",      ["Spi:"] = "spirit",
    ["Item LvL"] = "itemLevel",
    ["Item LvL:"] = "itemLevel",
    ["iLvl"] = "itemLevel",
    ["iLvl:"] = "itemLevel",
    ["GearScore"] = "gearScore",
    ["GearScore:"] = "gearScore",
    ["G.S."] = "gearScore",
    ["G.S.:"] = "gearScore",
}

--- Strip label text the same way as Blizzard STAT_FORMAT rows (for CSC comparisons).
local function _StripStatLabelForMatch(s)
    if not s then return "" end
    return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("[:%s]+$", ""))
end

local function _LabelMatchesStatFormat(labelText, globalConst)
    if type(globalConst) ~= "string" or globalConst == "" then return false end
    local fmt = _G.STAT_FORMAT
    if type(fmt) ~= "string" then fmt = "%s" end
    local full = string.format(fmt, globalConst)
    return _StripStatLabelForMatch(labelText) == _StripStatLabelForMatch(full)
end

--- Resolve Flux Character Stats left/right pane dropdown category (melee/ranged/spell/…).
local function _GetClassicCscPaperCategory(statFrame)
    local anc = _G.FluxUI_CSC_StatsParents
    local settings = _G.UISettingsCharacter
    if not anc or not settings or not statFrame then return nil end
    local side = nil
    local p, depth = statFrame, 0
    while p and depth < 12 do
        if p == anc.left then side = "left" break end
        if p == anc.right then side = "right" break end
        p = p:GetParent()
        depth = depth + 1
    end
    if not side then return nil end
    local list = {
        _G.PLAYERSTAT_BASE_STATS,
        _G.PLAYERSTAT_MELEE_COMBAT,
        _G.PLAYERSTAT_RANGED_COMBAT,
        _G.PLAYERSTAT_SPELL_COMBAT,
        _G.PLAYERSTAT_DEFENSES,
    }
    local idx = side == "left" and settings.selectedLeftStatsCategory or settings.selectedRightStatsCategory
    if type(idx) ~= "number" or idx < 1 or idx > #list then return nil end
    return list[idx]
end

local function _KeyFromClassicHitRatingIndex(statFrame)
    local ri = statFrame and statFrame.ratingIndex
    if type(ri) ~= "number" then return nil end
    local m, r, s = _G.CR_HIT_MELEE, _G.CR_HIT_RANGED, _G.CR_HIT_SPELL
    if m and ri == m then return "meleeHit" end
    if r and ri == r then return "rangedHit" end
    if s and ri == s then return "spellHit" end
    return nil
end

--- Remap shorthand map keys (Hit:/Crit:/Damage:) using the active CSC paper category.
local function _RemapClassicKeyForCategory(key, category)
    if not key or not category then return key end
    local pm, pr, ps = _G.PLAYERSTAT_MELEE_COMBAT, _G.PLAYERSTAT_RANGED_COMBAT, _G.PLAYERSTAT_SPELL_COMBAT
    if category == pr then
        if key == "weaponDamage" then return "rangedWeaponDamage" end
        if key == "attackPower" then return "rangedAttackPower" end
        if key == "weaponSpeed" then return "rangedWeaponSpeed" end
        if key == "crit" then return "rangedCrit" end
        if key == "spellHit" then return "rangedHit" end
    elseif category == pm then
        if key == "crit" then return "meleeCrit" end
        if key == "spellHit" then return "meleeHit" end
    elseif category == ps then
        if key == "crit" then return "crit" end
    end
    return key
end

local function GetClassicStatKey(statFrame)
    local _, labelText = _GetStatLabelRegionAndText(statFrame)
    if not labelText then return nil end
    local stripped = labelText:gsub("[:%s]+$", "")
    local ilvlLbl = _G.CSC_ILVL_LABEL or "Item LvL"
    if _LabelMatchesStatFormat(labelText, ilvlLbl) or stripped == ilvlLbl then
        return "itemLevel"
    end
    local gsLbl = _G.CSC_GS_LABEL or "GearScore"
    if _LabelMatchesStatFormat(labelText, gsLbl) or stripped == gsLbl then
        return "gearScore"
    end
    if type(MANA_REGEN) == "string" and MANA_REGEN ~= "" then
        if _LabelMatchesStatFormat(labelText, MANA_REGEN) or stripped == _StripStatLabelForMatch(MANA_REGEN) then
            return "mp5"
        end
    end
    if type(STAT_SPELLHASTE) == "string" and STAT_SPELLHASTE ~= "" then
        if _LabelMatchesStatFormat(labelText, STAT_SPELLHASTE) then
            return "haste"
        end
    end
    local cat = _GetClassicCscPaperCategory(statFrame)

    local fromRi = _KeyFromClassicHitRatingIndex(statFrame)
    if fromRi then return fromRi end

    local pm, pr, ps = _G.PLAYERSTAT_MELEE_COMBAT, _G.PLAYERSTAT_RANGED_COMBAT, _G.PLAYERSTAT_SPELL_COMBAT
    if cat and pm and pr and ps then
        if _LabelMatchesStatFormat(labelText, _G.STAT_CRITICAL_STRIKE) then
            if cat == pm then return "meleeCrit" end
            if cat == pr then return "rangedCrit" end
            if cat == ps then return "crit" end
        end
        if _LabelMatchesStatFormat(labelText, _G.STAT_HIT_CHANCE) then
            if cat == pm then return "meleeHit" end
            if cat == pr then return "rangedHit" end
            if cat == ps then return "spellHit" end
        end
        if _LabelMatchesStatFormat(labelText, _G.DAMAGE) then
            if cat == pm then return "weaponDamage" end
            if cat == pr then return "rangedWeaponDamage" end
        end
        if _LabelMatchesStatFormat(labelText, _G.WEAPON_SPEED) then
            if cat == pm then return "weaponSpeed" end
            if cat == pr then return "rangedWeaponSpeed" end
        end
        local apMelee = _LabelMatchesStatFormat(labelText, _G.STAT_ATTACK_POWER)
            or _LabelMatchesStatFormat(labelText, _G.ATTACK_POWER)
        if apMelee then
            if cat == pm then return "attackPower" end
            if cat == pr then return "rangedAttackPower" end
        end
        local spellPenGlobal = _G.SPELL_PENETRATION
        if type(spellPenGlobal) == "string" and spellPenGlobal ~= "" then
            if _LabelMatchesStatFormat(labelText, spellPenGlobal)
                or stripped == _StripStatLabelForMatch(spellPenGlobal) then
                if cat == ps then return "spellPenetration" end
            end
        end
        if stripped:lower():find("armor penetration", 1, true) then
            local kind = statFrame._FluxArmorPenKind
            if kind == "ranged" then return "rangedArmorPenetration" end
            if kind == "melee" then return "meleeArmorPenetration" end
            if cat == pr then return "rangedArmorPenetration" end
            if cat == pm then return "meleeArmorPenetration" end
            return "meleeArmorPenetration"
        end
    end

    if _LabelMatchesStatFormat(labelText, _G.MELEE_CRIT_CHANCE) then return "meleeCrit" end
    if _LabelMatchesStatFormat(labelText, _G.RANGED_CRIT_CHANCE) then return "rangedCrit" end
    if _LabelMatchesStatFormat(labelText, _G.SPELL_CRIT_CHANCE) then return "crit" end

    local key = classicStatLabelMap[labelText]
    if not key then
        for mapLabel, k in pairs(classicStatLabelMap) do
            if stripped == mapLabel:gsub("[:%s]+$", "") then
                key = k
                break
            end
        end
    end
    if key then
        return _RemapClassicKeyForCategory(key, cat)
    end

    local spellPin = InfoFrame._ClassicSpellPinKey(stripped)
    if spellPin then
        return spellPin
    end

    local dynKey = _SanitizeStatKey(stripped)
    if dynKey then
        EnsureDynamicStatInRegistry(dynKey, stripped)
        return dynKey
    end
    return nil
end

local function HookClassicStatFrame(statFrame)
    if not statFrame or statFrame[PIN_HOOK_TAG] then return end
    statFrame[PIN_HOOK_TAG] = true
    statFrame:EnableMouse(true)

    statFrame:HookScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            local key = GetClassicStatKey(self)
            if key then
                InfoFrame.TogglePinnedStat(key)
                RefreshAllPinIndicators()
            end
        end
    end)
end

--- Generic classic scan: hook any visible frame that looks like a stat row.
--- This complements CSC's explicit hooks so Base/Melee/Ranged/Spell/Defenses
--- rows are all pinnable even if their setter function isn't explicitly hooked.
local function RefreshClassicPinIndicators()
    local root = _G.CharacterFrame or _G.CharacterStatsPane
    if not root or not root.GetChildren then
        return
    end
    local queue = { root }
    local qi = 1
    while qi <= #queue do
        local node = queue[qi]
        qi = qi + 1
        if node and node.GetChildren then
            local children = { node:GetChildren() }
            for i = 1, #children do
                local c = children[i]
                if c then
                    queue[#queue + 1] = c
                    local _, labelText = _GetStatLabelRegionAndText(c)
                    if labelText and _StatFrameHasValueRegion(c) then
                        local key = InfoFrame._CamelotCombatStatKey(GetClassicStatKey(c))
                        if key then
                            if c._FluxInfoStatKey ~= key then _InvalidateTooltipStatFrameCache() end
                            c._FluxInfoStatKey = key
                            HookClassicStatFrame(c)
                            UpdatePinIndicator(c, key)
                        end
                    end
                end
            end
        end
    end
end

-- Discover all keys in one pass. The old resolver traversed this same tree
-- again for every requested stat, including the damage/heal/color getters in
-- one refresh. Only frame identities are cached: numbers and visibility stay
-- live, and the existing 0.25s bound still discovers unannounced addon rows.
function _RebuildTooltipStatFrameCache()
    _tooltipKeyToStatFrame = {}
    _tooltipKeyToStatFrameList = {}
    _tooltipKeyToStatFrameAt = GetTime() or 0
    InfoFrame._tooltipSourceMembers = {}
    InfoFrame._tooltipSourceRoots = {
        character = _G.CharacterFrame, pane = _G.CharacterStatsPane,
        paperDoll = _G.PaperDollFrame, scroll = _G.CharacterStatsPaneScrollBox,
    }
    local seen = {}
    local queue = {}
    local function push(c)
        if not c or seen[c] then return end
        seen[c] = true
        queue[#queue + 1] = c
    end
    local function register(c)
        local k = c._FluxInfoStatKey
        if not k then
            local _, labelText = _GetStatLabelRegionAndText(c)
            if labelText and _StatFrameHasValueRegion(c) then
                if FLUX_API and FLUX_API.isRetail then
                    k = GetRetailStatKey(c)
                end
                if not k then k = GetClassicStatKey(c) end
            end
        end
        k = InfoFrame._CamelotCombatStatKey(_CanonicalIlvlGsRegistryKey(k) or k)
        if not k then return end
        InfoFrame._tooltipSourceMembers[c] = k
        local list = _tooltipKeyToStatFrameList[k]
        if not list then
            list = {}
            _tooltipKeyToStatFrameList[k] = list
            _tooltipKeyToStatFrame[k] = c
        end
        list[#list + 1] = c
    end
    push(_G.CharacterFrame)
    push(_G.CharacterStatsPane)
    push(_G.PaperDollFrame)
    push(_G.CharacterStatsPaneScrollBox)
    local pane = _G.CharacterStatsPane
    if pane and pane.statsFramePool then
        for statFrame in pane.statsFramePool:EnumerateActive() do push(statFrame) end
    end
    local foreverRoot = _G.CharacterStatsPaneScrollBox
    if foreverRoot and foreverRoot ~= _G.CharacterStatsPanePetScrollBox then
        local box = foreverRoot.ScrollBox
        local view = box and box.GetView and box:GetView()
        local frames = view and view.GetFrames and view:GetFrames()
        if type(frames) == "table" then
            for i = 1, #frames do push(frames[i]) end
        end
    end
    local qi = 1
    while qi <= #queue do
        local node = queue[qi]
        qi = qi + 1
        register(node)
        if node.GetChildren then
            local kids = { node:GetChildren() }
            for i = 1, #kids do push(kids[i]) end
        end
    end
end

--- All Character / PaperDoll / stats-pane frames matching this Flux registry key (for CSC tooltip parity).
function InfoFrame.ResolveStatFramesForTooltip(statKey, allowRetry)
    statKey = _CanonicalIlvlGsRegistryKey(statKey) or statKey
    statKey = InfoFrame._CamelotCombatStatKey(statKey)
    if not statKey then return {} end
    if allowRetry == nil then allowRetry = true end
    local now = GetTime() or 0
    local roots = InfoFrame._tooltipSourceRoots
    if not _tooltipKeyToStatFrameAt or (now - _tooltipKeyToStatFrameAt) > 0.25
        or not roots or roots.character ~= _G.CharacterFrame or roots.pane ~= _G.CharacterStatsPane
        or roots.paperDoll ~= _G.PaperDollFrame or roots.scroll ~= _G.CharacterStatsPaneScrollBox then
        _RebuildTooltipStatFrameCache()
    end
    local out = {}
    local list = _tooltipKeyToStatFrameList[statKey]
    if list then
        for i = 1, #list do out[i] = list[i] end
    end
    -- Visibility can change without rebuilding/reassigning pooled frames.
    table.sort(out, function(a, b)
        local sa = (a.IsShown and a:IsShown()) and 1 or 0
        local sb = (b.IsShown and b:IsShown()) and 1 or 0
        if sa ~= sb then
            return sa > sb
        end
        return tostring(a) < tostring(b)
    end)

    if #out == 0 and allowRetry and (now - (_lastTooltipCacheFlushPinsAt or 0)) > 0.2 then
        _lastTooltipCacheFlushPinsAt = now
        if type(RefreshAllPinIndicators) == "function" then
            RefreshAllPinIndicators()
        end
        _InvalidateTooltipStatFrameCache()
        _RebuildTooltipStatFrameCache()
        return InfoFrame.ResolveStatFramesForTooltip(statKey, false)
    end
    return out
end

RefreshAllPinIndicators = function()
    RefreshRetailPinIndicators()
    if not InfoFrame._IsCamelotClient() then
        RefreshClassicPinIndicators()
    end
end

function InfoFrame.RefreshAllPinIndicators()
    RefreshAllPinIndicators()
end

--- Restore InfoFrame char DB from a Respec profile snapshot. Pass nil/invalid to skip.
function InfoFrame.ApplyRespecProfileSnapshot(data)
    if type(data) ~= "table" then
        return
    end
    local db = GetInfoFrameCharDB()
    if data.showFPS ~= nil then
        db.showFPS = not not data.showFPS
    end
    if data.showDurability ~= nil then
        db.showDurability = not not data.showDurability
    end
    if data.showPing ~= nil then
        db.showPing = not not data.showPing
    end
    if data.spellDisplayMode ~= nil then
        db.spellDisplayMode = data.spellDisplayMode
    end
    wipe(db.pinnedStats)
    if type(data.pinnedStats) == "table" then
        for k, v in pairs(data.pinnedStats) do
            if v and type(k) == "string" then
                db.pinnedStats[k] = true
            end
        end
    end
    if type(data.statOrder) == "table" then
        local order = {}
        local seen = {}
        for _, k in ipairs(data.statOrder) do
            if type(k) == "string" and not seen[k] then
                seen[k] = true
                order[#order + 1] = k
            end
        end
        db.statOrder = order
    end
    if db.spellDisplayMode ~= "off" and db.spellDisplayMode ~= "sp" and db.spellDisplayMode ~= "heal" and db.spellDisplayMode ~= "both" then
        db.spellDisplayMode = "off"
    end
    InfoFrame.ForceRebuild()
    InfoFrame.RefreshAllPinIndicators()
end

--- Called from CharacterStatsCustomExtensions hooks and standalone scan.
function InfoFrame.HookClassicCSCStatFrame(statFrame)
    HookClassicStatFrame(statFrame)
    local key = GetClassicStatKey(statFrame)
    if statFrame._FluxInfoStatKey ~= key then _InvalidateTooltipStatFrameCache() end
    statFrame._FluxInfoStatKey = key
    UpdatePinIndicator(statFrame, key)
end

--- Retail: Blizzard average item level is updated via PaperDollFrame_SetItemLevel (not statsFramePool).
function InfoFrame.HookRetailPaperDollStatFrame(statFrame)
    if not statFrame then return end
    _retailPaperDollItemLevelStatFrame = statFrame
    local key = GetRetailStatKey(statFrame) or "itemLevel"
    if statFrame._FluxInfoStatKey ~= key then _InvalidateTooltipStatFrameCache() end
    statFrame._FluxInfoStatKey = key
    HookRetailStatFrame(statFrame)
    UpdatePinIndicator(statFrame, key)
end

--- Retail: pool stat rows from PaperDollFrame_SetCritChance / SetHaste (and similar) — refresh pin hook+glyph every update.
function InfoFrame.HookRetailPaperDollPoolStatFrame(statFrame, registryKey)
    if not statFrame or type(registryKey) ~= "string" or registryKey == "" then return end
    if not STAT_REGISTRY[registryKey] then return end
    if statFrame._FluxInfoStatKey ~= registryKey
        or (InfoFrame._tooltipSourceMembers and InfoFrame._tooltipSourceMembers[statFrame] ~= registryKey) then
        _InvalidateTooltipStatFrameCache()
    end
    statFrame._FluxInfoStatKey = registryKey
    HookRetailStatFrame(statFrame)
    UpdatePinIndicator(statFrame, registryKey)
end

--- Forever ScrollBox row: map PAPERDOLL_STATINFO name (or label) into STAT_REGISTRY and pin.
function InfoFrame.ReadForeverDisplayText(statKey)
    statKey = InfoFrame._CamelotCombatStatKey(statKey)
    if type(statKey) ~= "string" or statKey == "" then return nil end
    local function strip(text)
        if issecretvalue and issecretvalue(text) then return nil end
        if type(text) ~= "string" or text == "" then return nil end
        text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
        text = text:match("^%s*(.-)%s*$") or text
        return text ~= "" and text or nil
    end
    local function fromFrame(f)
        if not f or f._FluxInfoStatKey ~= statKey then return nil end
        if f.Value and f.Value.GetText then
            return strip(f.Value:GetText())
        end
        return nil
    end
    local root = _G.CharacterStatsPaneScrollBox
    if root and root ~= _G.CharacterStatsPanePetScrollBox then
        local box = root.ScrollBox
        local view = box and box.GetView and box:GetView()
        local frames = view and view.GetFrames and view:GetFrames()
        if type(frames) == "table" then
            for i = 1, #frames do
                local t = fromFrame(frames[i])
                if t then
                    InfoFrame._foreverStatText = InfoFrame._foreverStatText or {}
                    InfoFrame._foreverStatText[statKey] = t
                    return t
                end
            end
        end
    end
    local pane = _G.CharacterStatsPane
    if pane and pane.statsFramePool and pane.statsFramePool.EnumerateActive then
        for statFrame in pane.statsFramePool:EnumerateActive() do
            local t = fromFrame(statFrame)
            if t then
                InfoFrame._foreverStatText = InfoFrame._foreverStatText or {}
                InfoFrame._foreverStatText[statKey] = t
                return t
            end
        end
    end
    local texts = InfoFrame._foreverStatText
    if texts then
        return strip(texts[statKey])
    end
    return nil
end

function InfoFrame.RememberPinnedStatValue(statKey, numericValue, statFrame)
    statKey = InfoFrame._CamelotCombatStatKey(statKey)
    if type(statKey) ~= "string" or statKey == "" then return end
    InfoFrame._foreverStatCache = InfoFrame._foreverStatCache or {}
    InfoFrame._foreverStatText = InfoFrame._foreverStatText or {}
    if issecretvalue and issecretvalue(numericValue) then
        InfoFrame._foreverStatCache[statKey] = nil
        InfoFrame._foreverStatText[statKey] = nil
        return
    end
    if statFrame and statFrame.Value and statFrame.Value.GetText then
        local text = statFrame.Value:GetText()
        if issecretvalue and issecretvalue(text) then
            InfoFrame._foreverStatCache[statKey] = nil
            InfoFrame._foreverStatText[statKey] = nil
            return
        end
        if type(text) == "string" and text ~= "" then
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
            text = text:match("^%s*(.-)%s*$") or text
            if text ~= "" then
                InfoFrame._foreverStatText[statKey] = text
            end
        end
    end
    if type(numericValue) == "number" then
        InfoFrame._foreverStatCache[statKey] = numericValue
        return
    end
    if type(numericValue) == "string" then
        local n = tonumber((numericValue:gsub("%%", ""):gsub(",", "")))
        InfoFrame._foreverStatCache[statKey] = n or numericValue
        return
    end
    local stored = InfoFrame._foreverStatText[statKey]
    if issecretvalue and issecretvalue(stored) then return end
    if stored then
        local n = tonumber((stored:gsub("%%", ""):gsub(",", "")))
        if n then
            InfoFrame._foreverStatCache[statKey] = n
        end
    end
end

function InfoFrame.HookForeverScrollBoxStatFrame(statFrame, registryKey)
    if not statFrame then return end
    if InfoFrame._IsCamelotClient() and InCombatLockdown() then return end
    local _, labelText = _GetStatLabelRegionAndText(statFrame)
    registryKey = InfoFrame._ClassicSpellPinKey(registryKey) or InfoFrame._ClassicSpellPinKey(labelText) or registryKey
    if type(registryKey) ~= "string" or registryKey == "" then
        registryKey = GetRetailStatKey(statFrame)
    end
    registryKey = InfoFrame._CamelotCombatStatKey(registryKey)
    if not registryKey then return end
    if not STAT_REGISTRY[registryKey] then
        EnsureDynamicStatInRegistry(registryKey, labelText or registryKey)
    end
    if InfoFrame._IsCamelotClient() and (registryKey == "crit" or registryKey == "haste" or registryKey == "meleeHit")
        and statFrame.Label and statFrame.Label.SetText then
        statFrame.Label:SetText(InfoFrame.StatLabel(registryKey))
    end
    if statFrame._FluxInfoStatKey ~= registryKey
        or (InfoFrame._tooltipSourceMembers and InfoFrame._tooltipSourceMembers[statFrame] ~= registryKey) then
        _InvalidateTooltipStatFrameCache()
    end
    statFrame._FluxInfoStatKey = registryKey
    HookRetailStatFrame(statFrame)
    UpdatePinIndicator(statFrame, registryKey)
    InfoFrame.RememberPinnedStatValue(registryKey, statFrame.numericValue, statFrame)
end

--- Scan and hook retail PaperDollFrame stat rows. Safe to call repeatedly.
function InfoFrame.InstallRetailPaperDollHooks()
    RefreshAllPinIndicators()
end

InfoFrame._afterCharacterShown = InfoFrame._afterCharacterShown or {}

function InfoFrame.AfterCharacterShown(fn)
    if type(fn) ~= "function" then
        return
    end
    local list = InfoFrame._afterCharacterShown
    list[#list + 1] = fn
end

function InfoFrame._StartCamelotCharacterWatch()
    local client = _G.Flux and _G.Flux.Client
    if not (client and client.isCamelot) or InfoFrame._camelotCharacterWatch then
        return
    end
    InfoFrame._camelotCharacterWatch = true
    local watch = CreateFrame("Frame", "FluxInfoCharacterWatchDriver")
    local wasShown = false
    local pending = false
    watch:SetScript("OnUpdate", function()
        local frame = _G.CharacterFrame
        local shown = frame and frame.IsShown and frame:IsShown() and true or false
        local inCombat = InCombatLockdown()
        if shown and (not wasShown or inCombat) then
            pending = true
        elseif not shown then
            pending = false
        end
        if pending and not inCombat then
            pending = false
            local list = InfoFrame._afterCharacterShown
            for i = 1, #list do
                pcall(list[i])
            end
        end
        wasShown = shown
    end)
end
InfoFrame._StartCamelotCharacterWatch()

--- Install hooks after character panel is present. Retry-safe (CharacterInfo calls this).
--- Hook flags live on InfoFrame so this file stays under Lua 5.1's 200-local cap.
function InfoFrame.InstallCharacterInfoPinHooks()
    local client = _G.Flux and _G.Flux.Client
    if client and client.isCamelot then
        -- Stat hooks run inside PaperDollFrame_OnShow, which ToggleCharacter
        -- calls before ShowUIPanel. That taints the secret health compare.
        if not InfoFrame._camelotOpenRefresh then
            InfoFrame._camelotOpenRefresh = true
            InfoFrame.AfterCharacterShown(function()
                _InvalidateTooltipStatFrameCache()
                RefreshRetailPinIndicators()
            end)
        end
        return
    end
    InfoFrame._EnsureCamelotSpellSnapshotHooks()
    local hasSurface = (_G.CharacterStatsPane and _G.CharacterStatsPane.statsFramePool)
        or (_G.CharacterStatsPaneScrollBox ~= nil)
    if hasSurface then
        if not InfoFrame._pinPaperDollShowHooked and _G.PaperDollFrame and _G.PaperDollFrame.HookScript then
            InfoFrame._pinPaperDollShowHooked = true
            _G.PaperDollFrame:HookScript("OnShow", function()
                C_Timer.After(0.1, RefreshRetailPinIndicators)
            end)
        end
        if not InfoFrame._pinUpdateStatsHooked and type(_G.PaperDollFrame_UpdateStats) == "function" and type(hooksecurefunc) == "function" then
            InfoFrame._pinUpdateStatsHooked = true
            hooksecurefunc("PaperDollFrame_UpdateStats", function()
                _InvalidateTooltipStatFrameCache()
                C_Timer.After(0, RefreshRetailPinIndicators)
                C_Timer.After(0, RefreshClassicPinIndicators)
                if HasDynamicPinnedStat() then
                    InfoFrame.RequestStatRefresh()
                end
            end)
        end
        local box = _G.CharacterStatsPaneScrollBox
        if not InfoFrame._pinForeverScrollHooked and box and type(box.UpdateStats) == "function" and type(hooksecurefunc) == "function" then
            InfoFrame._pinForeverScrollHooked = true
            hooksecurefunc(box, "UpdateStats", function(self)
                if self == _G.CharacterStatsPanePetScrollBox then
                    return
                end
                C_Timer.After(0, RefreshRetailPinIndicators)
            end)
        end
        if not InfoFrame._pinForeverRowInitHooked and type(hooksecurefunc) == "function" then
            local mixin = rawget(_G, "CharacterStatFrameScrollBoxBaseElementMixin")
            if mixin and type(mixin.Init) == "function" then
                InfoFrame._pinForeverRowInitHooked = true
                hooksecurefunc(mixin, "Init", function(self, elementData)
                    if not self or not elementData or elementData.isHeader then
                        return
                    end
                    local petRoot = _G.CharacterStatsPanePetScrollBox
                    if petRoot then
                        local p = self.GetParent and self:GetParent()
                        local n = 0
                        while p and n < 16 do
                            if p == petRoot then
                                return
                            end
                            p = p.GetParent and p:GetParent()
                            n = n + 1
                        end
                    end
                    local map = InfoFrame._foreverPaperDollStatToKey
                    local key = map and elementData.name and map[elementData.name] or nil
                    InfoFrame.HookForeverScrollBoxStatFrame(self, key)
                end)
            end
        end
    end

    if not InfoFrame._pinCharacterFrameShowHooked and _G.CharacterFrame then
        local client = _G.Flux and _G.Flux.Client
        -- HookScript OnShow taints CharacterFrame:OnShow. Forever then errors
        -- comparing secret health in TextStatusBar. ToggleCharacter's post-hook
        -- runs after that compare and the gamepad binding setup.
        if client and client.isCamelot then
            if type(hooksecurefunc) == "function" and type(_G.ToggleCharacter) == "function" then
                InfoFrame._pinCharacterFrameShowHooked = true
                hooksecurefunc("ToggleCharacter", function()
                    _InvalidateTooltipStatFrameCache()
                    C_Timer.After(0.2, function()
                        RefreshRetailPinIndicators()
                        RefreshClassicPinIndicators()
                    end)
                end)
            end
        elseif _G.CharacterFrame.HookScript then
            InfoFrame._pinCharacterFrameShowHooked = true
            _G.CharacterFrame:HookScript("OnShow", function()
                _InvalidateTooltipStatFrameCache()
                C_Timer.After(0.2, function()
                    RefreshRetailPinIndicators()
                    RefreshClassicPinIndicators()
                end)
            end)
        end
    end

    RefreshRetailPinIndicators()
    RefreshClassicPinIndicators()
end

