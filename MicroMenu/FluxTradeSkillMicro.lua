-- FluxTradeSkillMicro.lua
-- Learned trade skills as micromenu buttons + optional flyout popup.
-- Layout modes: perProfession | fixedSplit | global (allIndividual / oneFlyout / both).

if not FluxMicroMenu or not FluxMicroMenu.CreateMicroButton then return end

FluxTradeSkillMicro = FluxTradeSkillMicro or {}
local M = FluxTradeSkillMicro
_G.FluxTradeSkillMicro = M

local FLYOUT_GLOBAL = "FluxTradeSkillFlyoutMicroButton"
local FLYOUT_ICON = "Interface\\Icons\\Trade_BlackSmithing"
local BUTTON_SIZE = 32
local BUTTON_SPACING = 2
local PADDING = 6
local BUTTONS_PER_ROW = 4
local POPUP_STRATA = "DIALOG"
local POPUP_LEVEL = 100

--- Classic-era spellbook fallback names (only include if the player knows the spell).
local FALLBACK_PROFESSION_NAMES = {
    "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Leatherworking",
    "Mining", "Tailoring", "Jewelcrafting", "Inscription", "Herbalism", "Skinning",
    "Cooking", "First Aid", "Fishing", "Archaeology", "Smelting",
}

-- skill key -> skill info from last enum
M.skillsByKey = M.skillsByKey or {}
-- ordered list from last enum
M.skills = M.skills or {}
-- placement: key -> "individual" | "flyout" | "off" | "both" (both only for global both)
M.placement = M.placement or {}
M._flyoutMembers = M._flyoutMembers or {}
M._buttonsByKey = M._buttonsByKey or {}
M.isFlyoutShown = false
M._refreshQueued = false

-- ---------------------------------------------------------------------------
-- Saved settings (always character — professions are per-character)
-- ---------------------------------------------------------------------------

local function EnsureTradeSkillSaved()
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end
    if not _FluxUI_CharSavedVars.MicroMenu then
        _FluxUI_CharSavedVars.MicroMenu = { native = {} }
    end
    if not _FluxUI_CharSavedVars.MicroMenu.tradeSkills then
        _FluxUI_CharSavedVars.MicroMenu.tradeSkills = {
            enabled = true,
            layoutMode = "fixedSplit",
            globalStyle = "allIndividual",
            perSkill = {},
        }
    end
    local cts = _FluxUI_CharSavedVars.MicroMenu.tradeSkills
    if cts.enabled == nil then cts.enabled = true end
    if not cts.layoutMode then cts.layoutMode = "fixedSplit" end
    if not cts.globalStyle then cts.globalStyle = "allIndividual" end
    if type(cts.perSkill) ~= "table" then cts.perSkill = {} end

    -- One-time migrate from older account-scoped copy if character still at defaults
    -- and account had custom settings.
    if FluxUI_DB and FluxUI_DB.MicroMenu and type(FluxUI_DB.MicroMenu.tradeSkills) == "table" then
        local acc = FluxUI_DB.MicroMenu.tradeSkills
        local charIsDefault = cts.layoutMode == "fixedSplit"
            and cts.globalStyle == "allIndividual"
            and (not cts.perSkill or not next(cts.perSkill))
            and cts.enabled ~= false
        local accCustom = acc.layoutMode ~= "fixedSplit"
            or acc.globalStyle ~= "allIndividual"
            or (type(acc.perSkill) == "table" and next(acc.perSkill))
            or acc.enabled == false
        if charIsDefault and accCustom then
            cts.enabled = acc.enabled
            cts.layoutMode = acc.layoutMode or cts.layoutMode
            cts.globalStyle = acc.globalStyle or cts.globalStyle
            cts.perSkill = {}
            if type(acc.perSkill) == "table" then
                for k, v in pairs(acc.perSkill) do
                    cts.perSkill[k] = v
                end
            end
        end
        FluxUI_DB.MicroMenu.tradeSkills = nil
    end
end

function M:GetDB()
    EnsureTradeSkillSaved()
    return _FluxUI_CharSavedVars.MicroMenu.tradeSkills
end

function M:IsEnabled()
    local db = self:GetDB()
    return db and db.enabled ~= false
end

--- Ensure character visibility is on for an active bar row (first time only).
function M:EnsureRowVisible(rowId)
    if FluxMicroMenuConfig and FluxMicroMenuConfig.EnsureTradeSkillCharacterEnabled then
        FluxMicroMenuConfig:EnsureTradeSkillCharacterEnabled(rowId)
    end
end

--- Per-row bootstrap: enable Character visibility the first time each active row appears.
function M:BootstrapVisibilityIfNeeded()
    EnsureTradeSkillSaved()
    local mm = _FluxUI_CharSavedVars.MicroMenu
    if type(mm.tradeSkillVisibilityBootstrappedRows) ~= "table" then
        mm.tradeSkillVisibilityBootstrappedRows = {}
        -- Migrate legacy one-shot flag: do not re-bootstrap rows that already have a mode set.
        if mm.tradeSkillVisibilityBootstrapped then
            mm.tradeSkillVisibilityBootstrapped = nil
        end
    end
    local boot = mm.tradeSkillVisibilityBootstrappedRows
    for _, rowId in ipairs(self:GetActiveBarRowIds()) do
        if not boot[rowId] then
            self:EnsureRowVisible(rowId)
            boot[rowId] = true
        end
    end
end

-- ---------------------------------------------------------------------------
-- Row / global name helpers
-- ---------------------------------------------------------------------------

--- Normalize a profession name into a legacy name-key (used only for migration).
local function NameKey(name)
    if type(name) ~= "string" or name == "" then return nil end
    return name:gsub("%s+", "_")
end

function M:MakeKey(skillLine, name)
    if type(skillLine) == "number" then
        return tostring(skillLine)
    end
    if type(skillLine) == "string" and skillLine:match("^%d+$") then
        return skillLine
    end
    -- Prefer previously-seen skillLine for this name (stable across sessions).
    local nk = NameKey(name)
    if nk and self._nameToSkillLineKey and self._nameToSkillLineKey[nk] then
        return self._nameToSkillLineKey[nk]
    end
    if nk then
        return nk
    end
    return "unknown"
end

function M:SafeGlobalKey(key)
    return tostring(key):gsub("[^%w]", "_")
end

function M:GetIndividualGlobalName(key)
    return "FluxTradeSkill_" .. self:SafeGlobalKey(key) .. "MicroButton"
end

function M:GetFlyoutGlobalName()
    return FLYOUT_GLOBAL
end

function M:GetSkillDisplayName(key)
    if not key then return nil end
    local skill = self.skillsByKey and self.skillsByKey[key]
    if skill and skill.name then return skill.name end
    if self._keyDisplayNames and self._keyDisplayNames[key] then
        return self._keyDisplayNames[key]
    end
    -- Legacy name-key
    if type(key) == "string" and not key:match("^%d+$") then
        return key:gsub("_", " ")
    end
    return nil
end

function M:IsSkillKnown(key)
    if not key then return false end
    if self.skillsByKey and self.skillsByKey[key] then
        return true
    end
    return false
end

--- True if this row should remain in unifiedOrderList (order preserved across layout modes).
--- Only drops when enum succeeded and the profession is truly gone.
function M:ShouldKeepRowInOrder(rowId)
    if not self:IsEnabled() then
        -- Module off: still keep rows so turning it back on restores order.
        return true
    end
    if rowId == FLYOUT_GLOBAL then
        return true
    end
    if not FluxMicroMenuConfig or not FluxMicroMenuConfig.IsTradeSkillRowId
        or not FluxMicroMenuConfig:IsTradeSkillRowId(rowId) then
        return false
    end
    local key = FluxMicroMenuConfig:GetTradeSkillKey(rowId)
    if not key then return false end
    if self:IsSkillKnown(key) then
        return true
    end
    -- Legacy name-key (TSK:Cooking) while skills are keyed by skillLine — keep until migrated.
    if self._nameToSkillLineKey then
        local mapped = self._nameToSkillLineKey[key]
        if mapped and self:IsSkillKnown(mapped) then
            return true
        end
        -- The key may be a skillLine while the reverse map contains only a name key.
        for nameKey, skillLineKey in pairs(self._nameToSkillLineKey) do
            if skillLineKey == key and self:IsSkillKnown(skillLineKey) then
                return true
            end
            if nameKey == key then
                return true -- name key still pending migrate; keep
            end
        end
    end
    -- Display-name fallback: "Cooking" / "Cooking" with underscores
    local display = self:GetSkillDisplayName(key)
    if display and self.skills then
        for _, skill in ipairs(self.skills) do
            if skill.name == display or NameKey(skill.name) == key then
                return true
            end
        end
    end
    -- During empty / incomplete enum, never wipe saved order.
    if not self._enumReady then
        return true
    end
    -- If we had skills this session and list went empty, keep (transient).
    if self._hadSkillsThisSession and #(self.skills or {}) == 0 then
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Enumeration
-- ---------------------------------------------------------------------------

local function PlayerKnowsSpellByName(spellName)
    if not spellName or spellName == "" then return false end
    if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
        local ok, known = pcall(C_SpellBook.IsSpellInSpellBook, spellName)
        if ok and known then return true end
    end
    if IsPlayerSpell and C_Spell and C_Spell.GetSpellInfo then
        -- name-based IsSpellKnown is unreliable; try GetSpellInfo + IsPlayerSpell
    end
    if GetSpellInfo then
        local name = GetSpellInfo(spellName)
        if name then
            if IsSpellKnownOrOverridesKnown then
                -- need spell id; fall through to book scan
            elseif IsUsableSpell then
                local usable = IsUsableSpell(spellName)
                if usable ~= nil then
                    -- still not proof of known
                end
            end
        end
    end
    -- Spellbook scan by name
    local bookType = (BOOKTYPE_SPELL) or "spell"
    local numTabs = (GetNumSpellTabs and GetNumSpellTabs()) or 0
    for t = 1, numTabs do
        local _, _, offset, numSpells = GetSpellTabInfo(t)
        if offset and numSpells then
            for i = offset + 1, offset + numSpells do
                local sn = GetSpellBookItemName and GetSpellBookItemName(i, bookType)
                if sn == spellName then
                    return true, i, bookType
                end
            end
        end
    end
    return false
end

local function AddSkill(list, byKey, seen, info)
    if not info or not info.name then return end
    local key = M:MakeKey(info.skillLine, info.name)
    if seen[key] then return end
    seen[key] = true
    info.key = key
    list[#list + 1] = info
    byKey[key] = info
end

function M:EnumerateSkills()
    local list = {}
    local byKey = {}
    local seen = {}
    self._nameToSkillLineKey = self._nameToSkillLineKey or {}
    self._keyDisplayNames = self._keyDisplayNames or {}

    local function rememberName(skillLine, name)
        local nk = NameKey(name)
        if nk and type(skillLine) == "number" then
            self._nameToSkillLineKey[nk] = tostring(skillLine)
            self._keyDisplayNames[tostring(skillLine)] = name
        elseif nk then
            self._keyDisplayNames[nk] = name
        end
    end

    if GetProfessions and GetProfessionInfo then
        local p1, p2, arch, fish, cook, firstAid = GetProfessions()
        local function addIndex(idx, kind)
            if not idx then return end
            local name, texture, rank, maxRank, numSpells, spellOffset, skillLine = GetProfessionInfo(idx)
            if not name then return end
            rememberName(skillLine, name)
            AddSkill(list, byKey, seen, {
                name = name,
                texture = texture,
                rank = rank,
                maxRank = maxRank,
                numSpells = numSpells,
                spellOffset = spellOffset,
                skillLine = skillLine,
                kind = kind, -- "primary" | "secondary"
                professionIndex = idx,
            })
        end
        addIndex(p1, "primary")
        addIndex(p2, "primary")
        addIndex(arch, "secondary")
        addIndex(fish, "secondary")
        addIndex(cook, "secondary")
        addIndex(firstAid, "secondary")
    end

    if #list == 0 then
        for _, spellName in ipairs(FALLBACK_PROFESSION_NAMES) do
            local known, slot, bookType = PlayerKnowsSpellByName(spellName)
            if known then
                local texture
                if GetSpellTexture then
                    texture = GetSpellTexture(spellName)
                end
                local kind = "primary"
                if spellName == "Cooking" or spellName == "First Aid" or spellName == "Fishing"
                    or spellName == "Archaeology" then
                    kind = "secondary"
                end
                rememberName(nil, spellName)
                AddSkill(list, byKey, seen, {
                    name = spellName,
                    texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
                    skillLine = nil,
                    spellSlot = slot,
                    bookType = bookType,
                    kind = kind,
                })
            end
        end
    end

    self.skills = list
    self.skillsByKey = byKey
    if #list > 0 then
        self._hadSkillsThisSession = true
    end
    -- Enum is "ready" only after a non-empty profession read, or fallback found spells.
    -- Empty GetProfessions at login must NOT mark ready (would prune all TSK rows).
    if #list > 0 then
        self._enumReady = true
    elseif GetProfessions and self._hadSkillsThisSession then
        -- Had skills earlier; empty now may be unlearn-all — allow prune on next keep check.
        self._enumReady = true
    end
    return list
end

function M:GetLearnedSkills()
    if not self.skills or #self.skills == 0 then
        self:EnumerateSkills()
    end
    return self.skills
end

-- ---------------------------------------------------------------------------
-- Placement resolution
-- ---------------------------------------------------------------------------

function M:ResolvePlacement()
    local placement = {}
    local flyoutMembers = {}
    local db = self:GetDB()

    if not self:IsEnabled() then
        self.placement = placement
        self._flyoutMembers = flyoutMembers
        return placement, flyoutMembers
    end

    local skills = self:EnumerateSkills()
    local mode = db.layoutMode or "fixedSplit"

    for _, skill in ipairs(skills) do
        local key = skill.key
        local place = "off"

        if mode == "fixedSplit" then
            if skill.kind == "primary" then
                place = "individual"
            else
                place = "flyout"
            end
        elseif mode == "global" then
            local style = db.globalStyle or "allIndividual"
            if style == "allIndividual" then
                place = "individual"
            elseif style == "oneFlyout" then
                place = "flyout"
            else -- both
                place = "both"
            end
        else -- perProfession
            local per = db.perSkill and db.perSkill[key]
            if per == "individual" or per == "flyout" or per == "off" then
                place = per
            else
                -- defaults: primary individual, secondary flyout
                place = (skill.kind == "primary") and "individual" or "flyout"
            end
        end

        placement[key] = place
        if place == "flyout" or place == "both" then
            flyoutMembers[#flyoutMembers + 1] = skill
        end
    end

    self.placement = placement
    self._flyoutMembers = flyoutMembers
    return placement, flyoutMembers
end

function M:ShouldShowFlyoutButton()
    if not self:IsEnabled() then return false end
    self:ResolvePlacement()
    return #(self._flyoutMembers or {}) > 0
end

function M:IsIndividualOnBar(key)
    if not self:IsEnabled() then return false end
    local place = self.placement[key]
    if place == nil then
        self:ResolvePlacement()
        place = self.placement[key]
    end
    return place == "individual" or place == "both"
end

function M:IsRowActiveOnBar(rowId)
    if not FluxMicroMenuConfig or not FluxMicroMenuConfig.IsTradeSkillRowId then
        return false
    end
    if rowId == FLYOUT_GLOBAL then
        return self:ShouldShowFlyoutButton()
    end
    if not FluxMicroMenuConfig:IsTradeSkillRowId(rowId) then
        return false
    end
    local key = FluxMicroMenuConfig:GetTradeSkillKey(rowId)
    return key and self:IsIndividualOnBar(key)
end

--- Row ids that should appear in default/unified order (individuals + flyout when used).
--- Stable discovery order: primaries first, then secondaries, then flyout host.
function M:GetActiveBarRowIds()
    local out = {}
    if not self:IsEnabled() then return out end
    local placement = self:ResolvePlacement()
    local skills = self.skills or {}
    local function appendKind(wantKind)
        for _, skill in ipairs(skills) do
            if skill.kind == wantKind then
                local place = placement[skill.key]
                if place == "individual" or place == "both" then
                    if FluxMicroMenuConfig and FluxMicroMenuConfig.MakeTradeSkillRowId then
                        out[#out + 1] = FluxMicroMenuConfig:MakeTradeSkillRowId(skill.key)
                    else
                        out[#out + 1] = "TSK:" .. skill.key
                    end
                end
            end
        end
    end
    appendKind("primary")
    appendKind("secondary")
    -- Any skill missing kind (fallback enum) after secondaries
    for _, skill in ipairs(skills) do
        if skill.kind ~= "primary" and skill.kind ~= "secondary" then
            local place = placement[skill.key]
            if place == "individual" or place == "both" then
                if FluxMicroMenuConfig and FluxMicroMenuConfig.MakeTradeSkillRowId then
                    out[#out + 1] = FluxMicroMenuConfig:MakeTradeSkillRowId(skill.key)
                else
                    out[#out + 1] = "TSK:" .. skill.key
                end
            end
        end
    end
    if self:ShouldShowFlyoutButton() then
        out[#out + 1] = FLYOUT_GLOBAL
    end
    return out
end

local function RewriteRowIdInList(list, oldId, newId)
    if not list or oldId == newId then return false end
    local hasNew = false
    for _, id in ipairs(list) do
        if id == newId then
            hasNew = true
            break
        end
    end
    local out = {}
    local changed = false
    for _, id in ipairs(list) do
        if id == oldId then
            changed = true
            if not hasNew then
                out[#out + 1] = newId
                hasNew = true
            end
        else
            out[#out + 1] = id
        end
    end
    if not changed then return false end
    for i = #list, 1, -1 do
        list[i] = nil
    end
    for i, id in ipairs(out) do
        list[i] = id
    end
    return true
end

--- Migrate legacy TSK:Cooking-style keys to stable TSK:<skillLine> when skillLine is known.
function M:MigrateSavedRowKeys()
    if not FluxMicroMenuConfig or not self._nameToSkillLineKey then return end
    EnsureTradeSkillSaved()
    local cfg = FluxMicroMenuConfig
    local renames = {}
    for nameKey, skillLineKey in pairs(self._nameToSkillLineKey) do
        if nameKey and skillLineKey and nameKey ~= skillLineKey then
            renames[cfg:MakeTradeSkillRowId(nameKey)] = cfg:MakeTradeSkillRowId(skillLineKey)
        end
    end
    if not next(renames) then return end

    local function migrateStore(nativeTbl)
        if type(nativeTbl) ~= "table" then return end
        for oldId, newId in pairs(renames) do
            if nativeTbl[oldId] and not nativeTbl[newId] then
                nativeTbl[newId] = nativeTbl[oldId]
            end
            nativeTbl[oldId] = nil
        end
    end

    if FluxUI_DB and FluxUI_DB.MicroMenu then
        migrateStore(FluxUI_DB.MicroMenu.native)
    end
    if _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.MicroMenu then
        migrateStore(_FluxUI_CharSavedVars.MicroMenu.native)
        local boot = _FluxUI_CharSavedVars.MicroMenu.tradeSkillVisibilityBootstrappedRows
        if type(boot) == "table" then
            for oldId, newId in pairs(renames) do
                if boot[oldId] then
                    boot[newId] = true
                    boot[oldId] = nil
                end
            end
        end
        local db = _FluxUI_CharSavedVars.MicroMenu.tradeSkills
        if db and type(db.perSkill) == "table" then
            for nameKey, skillLineKey in pairs(self._nameToSkillLineKey) do
                if db.perSkill[nameKey] and not db.perSkill[skillLineKey] then
                    db.perSkill[skillLineKey] = db.perSkill[nameKey]
                end
                db.perSkill[nameKey] = nil
            end
        end
    end

    if cfg.GetUnifiedOrderList and cfg.SetUnifiedOrderList then
        local unified = cfg:GetUnifiedOrderList()
        local changed = false
        for oldId, newId in pairs(renames) do
            if RewriteRowIdInList(unified, oldId, newId) then
                changed = true
            end
        end
        if changed then
            cfg:SetUnifiedOrderList(unified)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Open profession
-- ---------------------------------------------------------------------------

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

function M:OpenSkill(skill)
    if not skill then return false end
    if InCombat() then return false end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return false end

    if skill.skillLine and C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then
        local ok = pcall(C_TradeSkillUI.OpenTradeSkill, skill.skillLine)
        if ok then return true end
    end

    if skill.spellOffset and skill.numSpells and skill.numSpells > 0 then
        local bookType = BOOKTYPE_PROFESSION or BOOKTYPE_SPELL or "spell"
        if CastSpell then
            local slot = skill.spellOffset + 1
            local ok = pcall(CastSpell, slot, bookType)
            if ok then return true end
            if BOOKTYPE_SPELL and bookType ~= BOOKTYPE_SPELL then
                ok = pcall(CastSpell, slot, BOOKTYPE_SPELL)
                if ok then return true end
            end
        end
    end

    if skill.spellSlot and CastSpell then
        local ok = pcall(CastSpell, skill.spellSlot, skill.bookType or BOOKTYPE_SPELL or "spell")
        if ok then return true end
    end

    if skill.name and CastSpellByName then
        local ok = pcall(CastSpellByName, skill.name)
        if ok then return true end
    end

    return false
end

function M:OpenSkillByKey(key)
    local skill = self.skillsByKey and self.skillsByKey[key]
    if not skill then
        self:EnumerateSkills()
        skill = self.skillsByKey and self.skillsByKey[key]
    end
    return self:OpenSkill(skill)
end

-- ---------------------------------------------------------------------------
-- Flyout popup
-- ---------------------------------------------------------------------------

local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
local container = CreateFrame("Frame", "FluxTradeSkillFlyoutContainer", UIParent)
container:SetFrameStrata(POPUP_STRATA)
container:SetFrameLevel(POPUP_LEVEL)
container:SetSize(100, 100)
container:Hide()
M.flyoutContainer = container

local backdropFrame = CreateFrame("Frame", "FluxTradeSkillFlyoutBackdrop", container, backdropTemplate)
backdropFrame:SetAllPoints(container)
backdropFrame:EnableMouse(false)
if not backdropFrame.SetBackdrop and Mixin and BackdropTemplateMixin then
    Mixin(backdropFrame, BackdropTemplateMixin)
    backdropFrame:OnBackdropLoaded()
end
if backdropFrame.SetBackdrop then
    backdropFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
end
M.flyoutBackdrop = backdropFrame

local buttonHost = CreateFrame("Frame", "FluxTradeSkillFlyoutHost", container)
buttonHost:SetAllPoints(container)
M.flyoutHost = buttonHost

container:RegisterEvent("PLAYER_STARTED_MOVING")
container:SetScript("OnEvent", function(self)
    self:Hide()
    M.isFlyoutShown = false
end)

local flyoutSlotPool = {}

local function ApplyPopupColors()
    if not backdropFrame.SetBackdropColor then return end
    local r, g, b = 1, 1, 1
    if FluxBorder and FluxBorder.GetThemedVertexRGB then
        r, g, b = FluxBorder:GetThemedVertexRGB()
    elseif FluxMicroMenu and FluxMicroMenu.GetClassColor then
        r, g, b = FluxMicroMenu:GetClassColor()
    end
    local br, bg, bb = r * 0.2, g * 0.2, b * 0.2
    if FluxBorder and FluxBorder.GetThemedBackdropFillRGB then
        br, bg, bb = FluxBorder:GetThemedBackdropFillRGB()
    end
    backdropFrame:SetBackdropColor(br, bg, bb, 0.95)
    backdropFrame:SetBackdropBorderColor(r, g, b, 1)
end

function M:UpdateFlyoutLayout()
    local members = self._flyoutMembers or {}
    local count = #members
    for _, slot in ipairs(flyoutSlotPool) do
        slot:Hide()
    end
    if count == 0 then
        container:SetSize(PADDING * 2 + BUTTON_SIZE, PADDING * 2 + BUTTON_SIZE)
        return
    end

    local cols = math.min(BUTTONS_PER_ROW, count)
    local rows = math.ceil(count / cols)
    local w = PADDING * 2 + cols * BUTTON_SIZE + (cols - 1) * BUTTON_SPACING
    local h = PADDING * 2 + rows * BUTTON_SIZE + (rows - 1) * BUTTON_SPACING
    container:SetSize(w, h)
    ApplyPopupColors()

    for i, skill in ipairs(members) do
        local slot = flyoutSlotPool[i]
        if not slot then
            slot = CreateFrame("Button", nil, buttonHost)
            slot:SetSize(BUTTON_SIZE, BUTTON_SIZE)
            local icon = slot:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints()
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            slot.icon = icon
            local hl = slot:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
            hl:SetBlendMode("ADD")
            slot:SetScript("OnEnter", function(self)
                if not self.skill then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.skill.name or "Profession")
                if self.skill.rank and self.skill.maxRank then
                    GameTooltip:AddLine(self.skill.rank .. " / " .. self.skill.maxRank, 0.8, 0.8, 0.8)
                end
                GameTooltip:AddLine("<Left Click> Open", 0.6, 0.6, 0.6)
                GameTooltip:Show()
            end)
            slot:SetScript("OnLeave", function()
                if GameTooltip then GameTooltip:Hide() end
            end)
            slot:SetScript("OnClick", function(self)
                if self.skill then
                    M:OpenSkill(self.skill)
                end
                container:Hide()
                M.isFlyoutShown = false
            end)
            flyoutSlotPool[i] = slot
        end
        slot.skill = skill
        if slot.icon then
            slot.icon:SetTexture(skill.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        local col = ((i - 1) % cols)
        local row = math.floor((i - 1) / cols)
        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", buttonHost, "TOPLEFT",
            PADDING + col * (BUTTON_SIZE + BUTTON_SPACING),
            -PADDING - row * (BUTTON_SIZE + BUTTON_SPACING))
        slot:Show()
    end
end

local POPUP_SCREEN_MARGIN = 8
local ANCHOR_BELOW_Y = -2
local ANCHOR_ABOVE_Y = 2

--- Keep flyout fully on-screen (and clear of the micro bar when the shared clamp exists).
function M:ClampFlyoutToScreen(anchor)
    if not container:IsShown() or not anchor then
        return
    end
    if FluxAddonSystem and FluxAddonSystem.ClampPopupToScreenAndMicroMenu then
        FluxAddonSystem.ClampPopupToScreenAndMicroMenu(container, anchor)
        return
    end

    -- Fallback: prefer below, else above; then nudge into UIParent.
    local pw = UIParent:GetWidth() or 0
    local ph = UIParent:GetHeight() or 0
    local m = POPUP_SCREEN_MARGIN

    local function place(below, dx, dy)
        container:ClearAllPoints()
        if below then
            container:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", dx, ANCHOR_BELOW_Y + dy)
        else
            container:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", dx, ANCHOR_ABOVE_Y + dy)
        end
    end

    local function try(below)
        local dx, dy = 0, 0
        for _ = 1, 40 do
            place(below, dx, dy)
            local l, b, w, h = container:GetRect()
            if not l then
                return true
            end
            local r, t = l + w, b + h
            local moved = false
            if l < m then
                dx = dx + (m - l)
                moved = true
            elseif r > pw - m then
                dx = dx + (pw - m - r)
                moved = true
            end
            if b < m then
                dy = dy + (m - b)
                moved = true
            elseif t > ph - m then
                dy = dy + (ph - m - t)
                moved = true
            end
            if not moved then
                return true
            end
        end
        return false
    end

    if not try(true) then
        try(false)
    end
end

function M:ToggleFlyout(anchor)
    if self.isFlyoutShown then
        container:Hide()
        self.isFlyoutShown = false
        return
    end
    self:ResolvePlacement()
    self:UpdateFlyoutLayout()
    if #(self._flyoutMembers or {}) == 0 then return end

    anchor = anchor or self.flyoutMicroButton or _G[FLYOUT_GLOBAL]
    container:ClearAllPoints()
    if anchor then
        container:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, ANCHOR_BELOW_Y)
    else
        container:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    container:Show()
    if container.Raise then container:Raise() end
    self.isFlyoutShown = true

    -- Layout + GetRect need a frame; clamp next tick like the Addon popup.
    if anchor and C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if not container:IsShown() then return end
            M:ClampFlyoutToScreen(anchor)
        end)
    elseif anchor then
        self:ClampFlyoutToScreen(anchor)
    end
end

function M:HideFlyout()
    container:Hide()
    self.isFlyoutShown = false
end

-- ---------------------------------------------------------------------------
-- Micro buttons
-- ---------------------------------------------------------------------------

local function SetButtonPriority(globalName, prio)
    if _G.BUTTON_PRIORITIES then
        _G.BUTTON_PRIORITIES[globalName] = prio
    end
end

function M:EnsureIndividualButton(skill)
    local key = skill.key
    local gname = self:GetIndividualGlobalName(key)
    local btn = _G[gname]
    if not btn then
        local clickHandler = {
            OnClick = function()
                M:OpenSkillByKey(key)
            end,
            OnTooltip = function(tooltip)
                local s = M.skillsByKey and M.skillsByKey[key]
                if s and s.rank and s.maxRank then
                    tooltip:AddLine(s.rank .. " / " .. s.maxRank, 0.8, 0.8, 0.8)
                end
                tooltip:AddLine("<Left Click> Open " .. (s and s.name or "profession"), 0.6, 0.6, 0.6)
            end,
        }
        FluxMicroMenu:CreateMicroButton(
            gname,
            skill.texture or "Interface\\Icons\\INV_Misc_QuestionMark",
            skill.name or "Profession",
            nil,
            clickHandler
        )
        btn = _G[gname]
    end
    if btn then
        btn.tradeSkillKey = key
        btn.fluxTradeSkillMicro = true
        if btn.icon and skill.texture then
            btn.icon:SetTexture(skill.texture)
        end
        btn.fluxTradeSkillName = skill.name
        SetButtonPriority(gname, 92.5)
        self._buttonsByKey[key] = btn
    end
    return btn
end

function M:EnsureFlyoutButton()
    local btn = _G[FLYOUT_GLOBAL]
    if not btn then
        local clickHandler = {
            OnClick = function(self)
                M:ToggleFlyout(self)
            end,
            OnTooltip = function(tooltip)
                tooltip:AddLine("Trade Skills", 1, 1, 1)
                local n = #(M._flyoutMembers or {})
                tooltip:AddLine("<Left Click> Show professions (" .. n .. ")", 0.6, 0.6, 0.6)
            end,
        }
        FluxMicroMenu:CreateMicroButton(
            FLYOUT_GLOBAL,
            FLYOUT_ICON,
            "Trade Skills",
            nil,
            clickHandler
        )
        btn = _G[FLYOUT_GLOBAL]
    end
    if btn then
        btn.fluxTradeSkillFlyout = true
        SetButtonPriority(FLYOUT_GLOBAL, 92.4)
        if btn.icon then
            btn.icon:SetTexture(FLYOUT_ICON)
        end
        M.flyoutMicroButton = btn
    end
    return btn
end

local function ParkButton(btn)
    if not btn or InCombat() then return end
    local parent = FluxHiddenParent or UIParent
    if FluxMicroMenu and WOW_PROJECT_ID and WOW_PROJECT_MAINLINE
        and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
        parent = FluxMicroMenu
    end
    btn:SetParent(parent)
    btn:Hide()
    btn:ClearAllPoints()
end

function M:SyncButtons()
    if InCombat() then
        self._needsCombatSync = true
        return
    end
    EnsureTradeSkillSaved()
    local placement = self:ResolvePlacement()
    local activeKeys = {}

    if self:IsEnabled() then
        for _, skill in ipairs(self.skills or {}) do
            local place = placement[skill.key]
            if place == "individual" or place == "both" then
                activeKeys[skill.key] = true
                self:EnsureIndividualButton(skill)
            end
        end
        if self:ShouldShowFlyoutButton() then
            self:EnsureFlyoutButton()
        else
            local fly = _G[FLYOUT_GLOBAL]
            if fly then ParkButton(fly) end
            self:HideFlyout()
        end
        self:BootstrapVisibilityIfNeeded()
    else
        local fly = _G[FLYOUT_GLOBAL]
        if fly then ParkButton(fly) end
        self:HideFlyout()
    end

    for key, btn in pairs(self._buttonsByKey) do
        if not activeKeys[key] then
            ParkButton(btn)
        end
    end

    -- Also park orphaned globals matching our prefix that are no longer active
    if FluxMicroMenu and FluxMicroMenu.GetDiscoveredMicroButtonNames then
        for _, gname in ipairs(FluxMicroMenu:GetDiscoveredMicroButtonNames()) do
            local btn = _G[gname]
            if btn and btn.tradeSkillKey and not activeKeys[btn.tradeSkillKey] then
                ParkButton(btn)
            end
        end
    end
end

function M:Refresh(notifyConfig)
    if self._refreshQueued then return end
    self._refreshQueued = true
    local function run()
        self._refreshQueued = false
        if InCombat() then
            self._needsCombatSync = true
            return
        end
        self:EnumerateSkills()
        self:MigrateSavedRowKeys()
        self:SyncButtons()
        if FluxMicroMenuConfig and FluxMicroMenuConfig.MergeNewDiscoveriesIntoUnifiedOrder then
            FluxMicroMenuConfig:MergeNewDiscoveriesIntoUnifiedOrder()
        end
        if FluxMicroMenuConfig and FluxMicroMenuConfig.PruneUnavailableNativeRows then
            FluxMicroMenuConfig:PruneUnavailableNativeRows()
        end
        if notifyConfig ~= false and FluxMicroMenuConfig and FluxMicroMenuConfig.NotifyChanged then
            FluxMicroMenuConfig:NotifyChanged()
        elseif FluxMicroMenu and FluxMicroMenu.Rebuild then
            FluxMicroMenu:Rebuild()
        end
        if FluxMicroMenuConfigUI and FluxMicroMenuConfigUI.RefreshRows then
            FluxMicroMenuConfigUI:RefreshRows()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("TRADE_SKILL_SHOW") then
    -- no need to open on show
end
pcall(function() eventFrame:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE") end)
pcall(function() eventFrame:RegisterEvent("SPELLS_CHANGED") end)

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if M._needsCombatSync then
            M._needsCombatSync = false
            M:Refresh()
        end
        return
    end
    M:Refresh()
end)

-- Initial sync after load (buttons need CreateMicroButton + config ready)
if C_Timer and C_Timer.After then
    C_Timer.After(0.5, function()
        M:Refresh()
    end)
end
if IsLoggedIn and IsLoggedIn() then
    M:Refresh(false)
end

