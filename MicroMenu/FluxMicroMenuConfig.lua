-- FluxMicroMenuConfig.lua
-- Façade for unified micro bar layout: native micro buttons + minimap-to-micro rows.
-- Native visibility (Account/Character/Off per button) lives in FluxUI_DB.MicroMenu.native and
-- _FluxUI_CharSavedVars.MicroMenu.native. Unified row order follows FluxOptions Micro Menu tab scope only
-- (account: FluxUI_DB.MicroMenu unified*; character: _FluxUI_CharSavedVars.MicroMenu unified*).
-- Layout tab placement scope does not affect unified order.
-- Minimap entries continue to use MinimapToMicro saved vars.

if not FluxMicroMenu then return end

FluxMicroMenuConfig = FluxMicroMenuConfig or {}
local C = FluxMicroMenuConfig

C.ROW_PREFIX_MINIMAP = "M2M:"
C.ROW_PREFIX_TRADESKILL = "TSK:"
C.TRADESKILL_FLYOUT_ROW_ID = "FluxTradeSkillFlyoutMicroButton"

-- Bump when canonical default order changes so saved unifiedOrderList can be rebuilt once.
local UNIFIED_ORDER_LAYOUT_VERSION = 9

local callbacks = {}

local function EnsureSavedVars()
    if not FluxUI_DB then
        FluxUI_DB = {}
    end
    if not FluxUI_DB.MicroMenu then
        FluxUI_DB.MicroMenu = {
            native = {},
            unifiedOrderList = {},
            unifiedInitialized = false,
        }
    end
    if not FluxUI_DB.MicroMenu.native then
        FluxUI_DB.MicroMenu.native = {}
    end
    if not FluxUI_DB.MicroMenu.unifiedOrderList then
        FluxUI_DB.MicroMenu.unifiedOrderList = {}
    end

    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end
    if not _FluxUI_CharSavedVars.MicroMenu then
        _FluxUI_CharSavedVars.MicroMenu = { native = {} }
    end
    if not _FluxUI_CharSavedVars.MicroMenu.native then
        _FluxUI_CharSavedVars.MicroMenu.native = {}
    end
end

function C:RegisterCallback(fn)
    if type(fn) == "function" then
        table.insert(callbacks, fn)
    end
end

local function FireCallbacks()
    for _, fn in ipairs(callbacks) do
        pcall(fn)
    end
end

-- ---------------------------------------------------------------------------
-- Row IDs: plain name for native (e.g. CharacterMicroButton); "M2M:MinimapName" for minimap sources
-- ---------------------------------------------------------------------------

function C:IsMinimapRowId(rowId)
    return type(rowId) == "string" and rowId:sub(1, 4) == C.ROW_PREFIX_MINIMAP
end

function C:GetMinimapSourceName(rowId)
    if not C:IsMinimapRowId(rowId) then return nil end
    return rowId:sub(5)
end

function C:MakeMinimapRowId(minimapButtonName)
    return C.ROW_PREFIX_MINIMAP .. minimapButtonName
end

function C:GetMinimapMicroGlobalName(minimapButtonName)
    local safe = minimapButtonName:gsub("[^%w]", "_")
    return "FluxMinimap2Micro_" .. safe .. "MicroButton"
end

function C:IsTradeSkillRowId(rowId)
    return type(rowId) == "string" and rowId:sub(1, 4) == C.ROW_PREFIX_TRADESKILL
end

function C:GetTradeSkillKey(rowId)
    if not self:IsTradeSkillRowId(rowId) then return nil end
    return rowId:sub(5)
end

function C:MakeTradeSkillRowId(key)
    return C.ROW_PREFIX_TRADESKILL .. tostring(key)
end

function C:GetTradeSkillMicroGlobalName(key)
    if FluxTradeSkillMicro and FluxTradeSkillMicro.GetIndividualGlobalName then
        return FluxTradeSkillMicro:GetIndividualGlobalName(key)
    end
    local safe = tostring(key):gsub("[^%w]", "_")
    return "FluxTradeSkill_" .. safe .. "MicroButton"
end

function C:IsTradeSkillFlyoutRowId(rowId)
    return rowId == C.TRADESKILL_FLYOUT_ROW_ID
end

function C:IsTradeSkillRelatedRowId(rowId)
    return self:IsTradeSkillRowId(rowId) or self:IsTradeSkillFlyoutRowId(rowId)
end

--- Trade skills are character-only: move any account native entries to character and clear account.
function C:MigrateTradeSkillNativeToCharacter()
    EnsureSavedVars()
    local changed = false
    local toMove = {}
    for rowId, data in pairs(FluxUI_DB.MicroMenu.native or {}) do
        if self:IsTradeSkillRelatedRowId(rowId) then
            toMove[rowId] = data
        end
    end
    for rowId, data in pairs(toMove) do
        if not _FluxUI_CharSavedVars.MicroMenu.native[rowId] then
            _FluxUI_CharSavedVars.MicroMenu.native[rowId] = {
                order = (data and data.order) or self:GetNextNativeOrder(),
            }
        end
        FluxUI_DB.MicroMenu.native[rowId] = nil
        changed = true
    end
    return changed
end

--- Default-on for a trade skill row: character visibility only (never account).
function C:EnsureTradeSkillCharacterEnabled(rowId)
    if not self:IsTradeSkillRelatedRowId(rowId) then return end
    EnsureSavedVars()
    -- Never keep account entries for trade skills.
    if FluxUI_DB.MicroMenu.native[rowId] then
        FluxUI_DB.MicroMenu.native[rowId] = nil
    end
    if not _FluxUI_CharSavedVars.MicroMenu.native[rowId] then
        _FluxUI_CharSavedVars.MicroMenu.native[rowId] = { order = self:GetNextNativeOrder() }
    end
end

--- Place a newly available canonical native after the nearest preceding default row already in the list.
--- Forever's LFDMicroButton was pruned from saved order (no LFDParentFrame); keep it in the group-finder slot.
function C:InsertDefaultRowAtCanonicalPosition(unified, seen, rowId, defaultIds)
    if not rowId or seen[rowId] then
        return
    end
    local insertAt = #unified + 1
    local prevId
    for i = 1, #defaultIds do
        local id = defaultIds[i]
        if id == rowId then
            break
        end
        if seen[id] then
            prevId = id
        end
    end
    if prevId then
        for i = 1, #unified do
            if unified[i] == prevId then
                insertAt = i + 1
                break
            end
        end
    else
        for i = 1, #defaultIds do
            local id = defaultIds[i]
            if seen[id] then
                for j = 1, #unified do
                    if unified[j] == id then
                        insertAt = j
                        break
                    end
                end
                break
            end
        end
    end
    table.insert(unified, insertAt, rowId)
    seen[rowId] = true
end

--- Insert rowId just before FluxAddonMicroButton or the first M2M: row (whichever comes first).
--- New trade-skill rows append at the end of any existing TSK/flyout cluster so secondaries
--- keep relative order with already-saved profession buttons.
function C:InsertRowBeforeAddonMicro(unified, rowId, seen)
    if seen[rowId] then return end
    local insertAt = #unified + 1
    local anchorAt = nil
    for i, id in ipairs(unified) do
        if id == "FluxAddonMicroButton" or self:IsMinimapRowId(id) then
            anchorAt = i
            break
        end
    end
    if anchorAt then
        insertAt = anchorAt
        -- If this is a trade-skill row, place after the last TSK/flyout already before the anchor.
        if self:IsTradeSkillRelatedRowId(rowId) then
            local lastTsk = nil
            for i = 1, anchorAt - 1 do
                if self:IsTradeSkillRelatedRowId(unified[i]) then
                    lastTsk = i
                end
            end
            if lastTsk then
                insertAt = lastTsk + 1
            end
        end
    end
    table.insert(unified, insertAt, rowId)
    seen[rowId] = true
end

--- Canonical unified rowId for a discovered *MicroButton global (M2M:source for minimap-derived; else global name).
function C:UnifiedRowIdFromGlobalMicroName(name)
    if type(name) ~= "string" or name == "" then return nil end
    if self:IsMinimapRowId(name) then
        return name
    end
    if self:IsTradeSkillRowId(name) then
        return name
    end
    local btn = _G[name]
    if not btn or not btn.IsObjectType or not btn:IsObjectType("Frame") then
        return nil
    end
    if btn.minimapButtonName then
        return self:MakeMinimapRowId(btn.minimapButtonName)
    end
    if btn.tradeSkillKey then
        return self:MakeTradeSkillRowId(btn.tradeSkillKey)
    end
    return name
end

--- Drop FluxMinimap2Micro_* rowIds when M2M:sourceName for the same minimap is already listed (single logical slot).
function C:ConsolidateMinimapMicroDuplicates()
    EnsureSavedVars()
    local list = self:GetUnifiedOrderList()
    if not list or #list == 0 then return false end
    local m2mSources = {}
    for _, id in ipairs(list) do
        if self:IsMinimapRowId(id) then
            local src = self:GetMinimapSourceName(id)
            if src then
                m2mSources[src] = true
            end
        end
    end
    local out = {}
    local changed = false
    for _, id in ipairs(list) do
        local skip = false
        if id:match("^FluxMinimap2Micro_") and id:match("MicroButton$") then
            local f = _G[id]
            local src = f and f.minimapButtonName
            if src and m2mSources[src] then
                skip = true
                changed = true
            end
        end
        if not skip then
            table.insert(out, id)
        end
    end
    if changed then
        self:SetUnifiedOrderList(out)
    end
    return changed
end

-- ---------------------------------------------------------------------------
-- Native mode (same semantics as MinimapToMicro)
-- ---------------------------------------------------------------------------

function C:IsNativeAccountEnabled(name)
    EnsureSavedVars()
    return FluxUI_DB.MicroMenu.native[name] ~= nil
end

function C:IsNativeCharacterEnabled(name)
    EnsureSavedVars()
    return _FluxUI_CharSavedVars.MicroMenu.native[name] ~= nil
end

function C:GetNativeMode(name)
    -- Trade skills: character-only (treat stray account entries as character after migrate).
    if self:IsTradeSkillRelatedRowId(name) then
        self:MigrateTradeSkillNativeToCharacter()
        if self:IsNativeCharacterEnabled(name) then
            return "character"
        end
        return "off"
    end
    if self:IsNativeCharacterEnabled(name) then
        return "character"
    elseif self:IsNativeAccountEnabled(name) then
        return "account"
    end
    return "off"
end

function C:GetNativeButtonOrder(name)
    EnsureSavedVars()
    if FluxUI_DB.MicroMenu.native[name] then
        return FluxUI_DB.MicroMenu.native[name].order or 999
    elseif _FluxUI_CharSavedVars.MicroMenu.native[name] then
        return _FluxUI_CharSavedVars.MicroMenu.native[name].order or 999
    end
    return 999
end

function C:SetNativeButtonOrder(name, newOrder)
    EnsureSavedVars()
    if FluxUI_DB.MicroMenu.native[name] then
        FluxUI_DB.MicroMenu.native[name].order = newOrder
    elseif _FluxUI_CharSavedVars.MicroMenu.native[name] then
        _FluxUI_CharSavedVars.MicroMenu.native[name].order = newOrder
    end
end

function C:EnableNativeForAccount(name)
    EnsureSavedVars()
    local order = self:GetNativeButtonOrder(name)
    if order >= 999 then
        order = self:GetNextNativeOrder()
    end
    FluxUI_DB.MicroMenu.native[name] = { order = order }
    self:UpdateUnifiedOrderAfterNativeChange()
end

function C:DisableNativeForAccount(name)
    EnsureSavedVars()
    FluxUI_DB.MicroMenu.native[name] = nil
end

function C:EnableNativeForCharacter(name)
    EnsureSavedVars()
    local order = self:GetNativeButtonOrder(name)
    if order >= 999 then
        order = self:GetNextNativeOrder()
    end
    _FluxUI_CharSavedVars.MicroMenu.native[name] = { order = order }
    self:UpdateUnifiedOrderAfterNativeChange()
end

function C:DisableNativeForCharacter(name)
    EnsureSavedVars()
    _FluxUI_CharSavedVars.MicroMenu.native[name] = nil
end

function C:GetNextNativeOrder()
    EnsureSavedVars()
    local maxOrder = 0
    for _, data in pairs(FluxUI_DB.MicroMenu.native) do
        if data.order and data.order > maxOrder then
            maxOrder = data.order
        end
    end
    for _, data in pairs(_FluxUI_CharSavedVars.MicroMenu.native) do
        if data.order and data.order > maxOrder then
            maxOrder = data.order
        end
    end
    return maxOrder + 1
end

function C:CycleNativeMode(name)
    -- Trade skills: Off <-> Character only (never Account).
    if self:IsTradeSkillRelatedRowId(name) then
        EnsureSavedVars()
        FluxUI_DB.MicroMenu.native[name] = nil
        if self:IsNativeCharacterEnabled(name) then
            self:DisableNativeForCharacter(name)
        else
            self:EnableNativeForCharacter(name)
        end
        self:NotifyChanged()
        return
    end
    local mode = self:GetNativeMode(name)
    if mode == "off" then
        self:EnableNativeForAccount(name)
    elseif mode == "account" then
        local ord = self:GetNativeButtonOrder(name)
        self:DisableNativeForAccount(name)
        EnsureSavedVars()
        _FluxUI_CharSavedVars.MicroMenu.native[name] = { order = ord }
    elseif mode == "character" then
        self:DisableNativeForCharacter(name)
    end
    self:NotifyChanged()
end

function C:NotifyListenersOnly()
    FireCallbacks()
end

-- ---------------------------------------------------------------------------
-- Unified order list (row order only; native Account/Character/Off stays in FluxUI_DB / _FluxUI_CharSavedVars .native)
-- ---------------------------------------------------------------------------

local function OrderScopeUsesCharacterStorage()
    if FluxOptions and FluxOptions.IsMicroMenuSettingsCharacterSpecific then
        local ok, v = pcall(function()
            return FluxOptions:IsMicroMenuSettingsCharacterSpecific()
        end)
        return ok and v == true
    end
    return false
end

--- Where unifiedOrderList / unifiedInitialized / unifiedOrderLayoutVersion live (Micro Menu tab scope only).
local function GetUnifiedOrderStorage()
    EnsureSavedVars()
    if OrderScopeUsesCharacterStorage() then
        local ch = _FluxUI_CharSavedVars.MicroMenu
        if not ch.unifiedOrderList then
            ch.unifiedOrderList = {}
        end
        return ch
    end
    return FluxUI_DB.MicroMenu
end

--- When toggling Micro Menu tab scope in FluxOptions: copy unified-order fields only (not .native visibility).
function C:CopyUnifiedOrderForScopeToggle(toCharacter)
    EnsureSavedVars()
    local acc = FluxUI_DB.MicroMenu
    local ch = _FluxUI_CharSavedVars.MicroMenu
    local function copyUnifiedFields(src, dst)
        if not dst then
            return
        end
        if src and type(src.unifiedOrderList) == "table" then
            dst.unifiedOrderList = {}
            for i, v in ipairs(src.unifiedOrderList) do
                dst.unifiedOrderList[i] = v
            end
        else
            dst.unifiedOrderList = {}
        end
        if src then
            dst.unifiedInitialized = src.unifiedInitialized
            dst.unifiedOrderLayoutVersion = src.unifiedOrderLayoutVersion
        else
            dst.unifiedInitialized = false
            dst.unifiedOrderLayoutVersion = nil
        end
        -- tradeSkills stay character-only; do not copy with micro menu bar scope.
    end
    if toCharacter then
        copyUnifiedFields(acc, ch)
    else
        copyUnifiedFields(ch, acc)
    end
end

function C:GetUnifiedOrderList()
    local st = GetUnifiedOrderStorage()
    if not st.unifiedOrderList then
        st.unifiedOrderList = {}
    end
    return st.unifiedOrderList
end

function C:SetUnifiedOrderList(list)
    local st = GetUnifiedOrderStorage()
    st.unifiedOrderList = list
end

--- Remove duplicate rowIds from unifiedOrderList (first occurrence wins). Persists when the list shrinks.
function C:NormalizeUnifiedOrderList()
    EnsureSavedVars()
    local list = self:GetUnifiedOrderList()
    if not list or #list == 0 then return false end
    local seen = {}
    local out = {}
    for _, id in ipairs(list) do
        if type(id) == "string" and id ~= "" and not seen[id] then
            seen[id] = true
            table.insert(out, id)
        end
    end
    if #out ~= #list then
        self:SetUnifiedOrderList(out)
        return true
    end
    return false
end

--- Queue eye is positioned outside the micro bar; remove legacy slot from saved unified order.
function C:PruneQueueStatusFromUnifiedOrder()
    EnsureSavedVars()
    local list = self:GetUnifiedOrderList()
    if not list or #list == 0 then
        return false
    end
    local out = {}
    local changed = false
    for _, id in ipairs(list) do
        if id == "QueueStatusButton" then
            changed = true
        else
            table.insert(out, id)
        end
    end
    if changed then
        self:SetUnifiedOrderList(out)
    end
    return changed
end

--- Convert legacy FluxMinimap2Micro_*MicroButton rowIds to M2M:sourceName when the frame exists.
function C:MigrateLegacyUnifiedRowIds()
    EnsureSavedVars()
    local list = self:GetUnifiedOrderList()
    if not list or #list == 0 then return false end
    local changed = false
    local out = {}
    local seen = {}
    for _, id in ipairs(list) do
        if type(id) ~= "string" or id == "" then
            changed = true
        else
            local nid = id
            if id:match("^FluxMinimap2Micro_") and id:match("MicroButton$") then
                local f = _G[id]
                if f and f.minimapButtonName then
                    local m = self:MakeMinimapRowId(f.minimapButtonName)
                    if m ~= id then
                        nid = m
                        changed = true
                    end
                end
            end
            if not seen[nid] then
                seen[nid] = true
                table.insert(out, nid)
            else
                changed = true
            end
        end
    end
    if changed then
        self:SetUnifiedOrderList(out)
    end
    return changed
end

--- Drop native rowIds that do not exist on this client (e.g. SpellbookMicroButton on retail-only builds).
--- Trade-skill rows are kept while the skill is still known (or enum is not ready) even if the
--- current layout parks them in the flyout — so drag order survives mode / secondary toggles.
function C:PruneUnavailableNativeRows()
    EnsureSavedVars()
    if not FluxMicroMenu or not FluxMicroMenu.IsNativeRowAvailableOnClient then return false end
    local list = self:GetUnifiedOrderList()
    if not list or #list == 0 then return false end
    local out = {}
    local changed = false
    for _, rowId in ipairs(list) do
        if type(rowId) ~= "string" or rowId == "" then
            changed = true
        elseif self:IsMinimapRowId(rowId) then
            table.insert(out, rowId)
        elseif self:IsTradeSkillRelatedRowId(rowId) then
            if FluxTradeSkillMicro and FluxTradeSkillMicro.ShouldKeepRowInOrder then
                if FluxTradeSkillMicro:ShouldKeepRowInOrder(rowId) then
                    table.insert(out, rowId)
                else
                    changed = true
                end
            else
                table.insert(out, rowId)
            end
        elseif FluxMicroMenu:IsNativeRowAvailableOnClient(rowId) then
            table.insert(out, rowId)
        else
            changed = true
        end
    end
    if changed then
        self:SetUnifiedOrderList(out)
    end
    return changed
end

--- One-time: replace unifiedOrderList with discovery order + scanned M2M rows (fixes stale saved order vs BUTTON_PRIORITIES).
local function MaybeRebuildUnifiedOrderForLayoutVersion()
    EnsureSavedVars()
    local st = GetUnifiedOrderStorage()
    local v = st.unifiedOrderLayoutVersion or 0
    if v >= UNIFIED_ORDER_LAYOUT_VERSION then return end
    if not FluxMicroMenu.GetDefaultUnifiedRowIds then
        st.unifiedOrderLayoutVersion = UNIFIED_ORDER_LAYOUT_VERSION
        return
    end
    local unified = {}
    local seen = {}
    for _, rowId in ipairs(FluxMicroMenu:GetDefaultUnifiedRowIds()) do
        table.insert(unified, rowId)
        seen[rowId] = true
    end
    if FluxMinimapToMicro and FluxMinimapToMicro.ScanButtons then
        FluxMinimapToMicro:ScanButtons()
        for _, data in ipairs(FluxMinimapToMicro.scannedButtons or {}) do
            if data.name then
                local id = C:MakeMinimapRowId(data.name)
                if not seen[id] then
                    seen[id] = true
                    table.insert(unified, id)
                end
            end
        end
    end
    C:SetUnifiedOrderList(unified)
    C:NormalizeUnifiedOrderList()
    st.unifiedOrderLayoutVersion = UNIFIED_ORDER_LAYOUT_VERSION
end

--- Chat column already covers these. Stay in the editor, but do not auto-enable.
local NATIVE_DEFAULT_OFF = {
    FluxConfigMicroButton = true,
    GuildMicroButton = true,
    GuildAndCommunitiesMicroButton = true,
    CharacterMicroButton = true,
}

local CHAT_DUPLICATE_DEFAULT_OFF_VERSION = 1

local function ApplyChatDuplicateDefaultOff()
    EnsureSavedVars()
    local rows = {
        "GuildMicroButton",
        "GuildAndCommunitiesMicroButton",
        "CharacterMicroButton",
    }
    local st = FluxUI_DB.MicroMenu
    if (st.chatDuplicateDefaultOffVersion or 0) < CHAT_DUPLICATE_DEFAULT_OFF_VERSION then
        for i = 1, #rows do
            C:DisableNativeForAccount(rows[i])
        end
        st.chatDuplicateDefaultOffVersion = CHAT_DUPLICATE_DEFAULT_OFF_VERSION
    end
    local ch = _FluxUI_CharSavedVars.MicroMenu
    if (ch.chatDuplicateDefaultOffVersion or 0) < CHAT_DUPLICATE_DEFAULT_OFF_VERSION then
        for i = 1, #rows do
            C:DisableNativeForCharacter(rows[i])
        end
        ch.chatDuplicateDefaultOffVersion = CHAT_DUPLICATE_DEFAULT_OFF_VERSION
    end
end

local function EnableNativeDefaultIfUnset(rowId, orderIndex)
    if C:IsMinimapRowId(rowId) then return end
    if NATIVE_DEFAULT_OFF[rowId] then return end
    if C:IsTradeSkillRelatedRowId(rowId) then
        -- Character-only default on for trade skills.
        FluxUI_DB.MicroMenu.native[rowId] = nil
        if not _FluxUI_CharSavedVars.MicroMenu.native[rowId] then
            _FluxUI_CharSavedVars.MicroMenu.native[rowId] = { order = orderIndex }
        end
        return
    end
    if not FluxUI_DB.MicroMenu.native[rowId] and not _FluxUI_CharSavedVars.MicroMenu.native[rowId] then
        FluxUI_DB.MicroMenu.native[rowId] = { order = orderIndex }
    end
end

function C:EnsureUnifiedDefaults()
    EnsureSavedVars()
    ApplyChatDuplicateDefaultOff()
    self:MigrateLegacyUnifiedRowIds()
    if FluxTradeSkillMicro then
        if FluxTradeSkillMicro.EnumerateSkills then
            FluxTradeSkillMicro:EnumerateSkills()
        end
        if FluxTradeSkillMicro.MigrateSavedRowKeys then
            FluxTradeSkillMicro:MigrateSavedRowKeys()
        end
    end
    self:PruneUnavailableNativeRows()
    local st = GetUnifiedOrderStorage()
    if not st.unifiedInitialized then
        local unified = {}
        if FluxMicroMenu.GetDefaultUnifiedRowIds then
            for _, rowId in ipairs(FluxMicroMenu:GetDefaultUnifiedRowIds()) do
                table.insert(unified, rowId)
                if not self:IsMinimapRowId(rowId) then
                    EnableNativeDefaultIfUnset(rowId, #unified)
                end
            end
        end
        st.unifiedOrderList = unified
        st.unifiedInitialized = true
        st.unifiedOrderLayoutVersion = UNIFIED_ORDER_LAYOUT_VERSION
    end
    MaybeRebuildUnifiedOrderForLayoutVersion()
    self:MigrateTradeSkillNativeToCharacter()
    self:MergeNewDiscoveriesIntoUnifiedOrder()
end

function C:MergeNewDiscoveriesIntoUnifiedOrder()
    if self._mergeDiscoveriesInProgress then
        return
    end
    self._mergeDiscoveriesInProgress = true
    local ok, err = pcall(self.MergeNewDiscoveriesIntoUnifiedOrderUnlocked, self)
    self._mergeDiscoveriesInProgress = false
    if not ok then
        local handler = geterrorhandler and geterrorhandler()
        if handler then
            pcall(handler, err)
        end
    end
end

function C:MergeNewDiscoveriesIntoUnifiedOrderUnlocked()
    EnsureSavedVars()
    self:MigrateLegacyUnifiedRowIds()
    if FluxTradeSkillMicro and FluxTradeSkillMicro.MigrateSavedRowKeys then
        FluxTradeSkillMicro:MigrateSavedRowKeys()
    end
    self:MigrateTradeSkillNativeToCharacter()
    self:PruneUnavailableNativeRows()
    local unified = self:GetUnifiedOrderList()
    local seen = {}
    for _, id in ipairs(unified) do
        seen[id] = true
    end

    local function addDiscovery(rowId, beforeAddon)
        if not rowId or seen[rowId] then return end
        if beforeAddon or self:IsTradeSkillRowId(rowId) or self:IsTradeSkillFlyoutRowId(rowId) then
            self:InsertRowBeforeAddonMicro(unified, rowId, seen)
        else
            table.insert(unified, rowId)
            seen[rowId] = true
        end
        EnableNativeDefaultIfUnset(rowId, #unified)
    end

    -- Active trade-skill bar rows first (before Addon / M2M).
    if FluxTradeSkillMicro and FluxTradeSkillMicro.GetActiveBarRowIds then
        for _, rowId in ipairs(FluxTradeSkillMicro:GetActiveBarRowIds()) do
            if FluxMicroMenu and FluxMicroMenu.IsNativeRowAvailableOnClient
                and FluxMicroMenu:IsNativeRowAvailableOnClient(rowId) then
                addDiscovery(rowId, true)
            end
        end
    end

    if FluxMicroMenu.GetDefaultUnifiedRowIds then
        local defaults = FluxMicroMenu:GetDefaultUnifiedRowIds()
        for _, rowId in ipairs(defaults) do
            if not seen[rowId] then
                if self:IsTradeSkillRowId(rowId) or self:IsTradeSkillFlyoutRowId(rowId) then
                    addDiscovery(rowId, true)
                else
                    self:InsertDefaultRowAtCanonicalPosition(unified, seen, rowId, defaults)
                    EnableNativeDefaultIfUnset(rowId, #unified)
                end
            end
        end
    end

    if FluxMinimapToMicro and FluxMinimapToMicro.ScanButtons then
        FluxMinimapToMicro:ScanButtons()
        for _, data in ipairs(FluxMinimapToMicro.scannedButtons or {}) do
            local id = self:MakeMinimapRowId(data.name)
            if not seen[id] then
                table.insert(unified, id)
                seen[id] = true
            end
        end
    end

    -- Every *MicroButton global the bar can discover — same canonical rowIds as BuildOrderedMicroButtons (no orphan-only slots).
    if FluxMicroMenu and FluxMicroMenu.GetDiscoveredMicroButtonNames and FluxMicroMenu.IsNativeRowAvailableOnClient then
        for _, gname in ipairs(FluxMicroMenu:GetDiscoveredMicroButtonNames()) do
            local rowId = self:UnifiedRowIdFromGlobalMicroName(gname)
            if rowId and not seen[rowId] and FluxMicroMenu:IsNativeRowAvailableOnClient(rowId) then
                local beforeAddon = self:IsTradeSkillRowId(rowId) or self:IsTradeSkillFlyoutRowId(rowId)
                addDiscovery(rowId, beforeAddon)
            end
        end
    end

    self:ConsolidateMinimapMicroDuplicates()
    self:PruneQueueStatusFromUnifiedOrder()
    self:NormalizeUnifiedOrderList()
end

function C:UpdateUnifiedOrderAfterNativeChange()
    -- Order values may need sync; unified list positions are authoritative for layout
end

-- ---------------------------------------------------------------------------
-- Resolve row to bar inclusion
-- ---------------------------------------------------------------------------

function C:ShouldShowNativeOnBar(name)
    return self:GetNativeMode(name) ~= "off"
end

function C:ResolveRowToButtonFrame(rowId, discoveredByName)
    if self:IsMinimapRowId(rowId) then
        local src = self:GetMinimapSourceName(rowId)
        if not src or not FluxMinimapToMicro or not FluxMinimapToMicro.IsEnabled then
            return nil
        end
        if not FluxMinimapToMicro:IsEnabled(src) then
            return nil
        end
        local gname = self:GetMinimapMicroGlobalName(src)
        return discoveredByName[gname]
    elseif self:IsTradeSkillRowId(rowId) then
        if FluxTradeSkillMicro and FluxTradeSkillMicro.IsRowActiveOnBar
            and not FluxTradeSkillMicro:IsRowActiveOnBar(rowId) then
            return nil
        end
        if not self:ShouldShowNativeOnBar(rowId) then
            return nil
        end
        local key = self:GetTradeSkillKey(rowId)
        local gname = key and self:GetTradeSkillMicroGlobalName(key)
        if gname then
            return discoveredByName[gname] or _G[gname]
        end
        return nil
    elseif self:IsTradeSkillFlyoutRowId(rowId) then
        if FluxTradeSkillMicro and FluxTradeSkillMicro.IsRowActiveOnBar
            and not FluxTradeSkillMicro:IsRowActiveOnBar(rowId) then
            return nil
        end
        if not self:ShouldShowNativeOnBar(rowId) then
            return nil
        end
        return discoveredByName[rowId] or _G[rowId]
    else
        if rowId == "QueueStatusButton" then
            return nil
        end
        if FluxMicroMenu and FluxMicroMenu.IsNativeRowAvailableOnClient
            and not FluxMicroMenu:IsNativeRowAvailableOnClient(rowId) then
            return nil
        end
        if not self:ShouldShowNativeOnBar(rowId) then
            return nil
        end
        local btn = discoveredByName[rowId]
        if btn then
            return btn
        end
        local f = _G[rowId]
        if f and f.IsObjectType and f:IsObjectType("Frame") then
            return f
        end
        return nil
    end
end

function C:BuildOrderedMicroButtons(discoveredList)
    self:EnsureUnifiedDefaults()

    local discoveredByName = {}
    for _, btn in ipairs(discoveredList) do
        local n = btn:GetName()
        if n then
            discoveredByName[n] = btn
        end
    end

    local ordered = {}
    local used = {}

    for _, rowId in ipairs(self:GetUnifiedOrderList()) do
        local btn = self:ResolveRowToButtonFrame(rowId, discoveredByName)
        -- One physical button per slot; duplicate rowIds must not insert the same frame twice (breaks SetPoint chain).
        if btn and not used[btn] then
            table.insert(ordered, btn)
            used[btn] = true
        end
    end

    for _, btn in ipairs(discoveredList) do
        if not used[btn] and self:ShouldIncludeDiscoveredButton(btn, discoveredByName) then
            table.insert(ordered, btn)
            used[btn] = true
        end
    end

    return ordered, discoveredByName
end

function C:ShouldIncludeDiscoveredButton(btn, discoveredByName)
    local name = btn:GetName()
    if not name then return false end
    if btn.tradeSkillKey then
        local rowId = self:MakeTradeSkillRowId(btn.tradeSkillKey)
        if FluxTradeSkillMicro and FluxTradeSkillMicro.IsRowActiveOnBar
            and not FluxTradeSkillMicro:IsRowActiveOnBar(rowId) then
            return false
        end
        return self:ShouldShowNativeOnBar(rowId)
    end
    if name == C.TRADESKILL_FLYOUT_ROW_ID or btn.fluxTradeSkillFlyout then
        if FluxTradeSkillMicro and FluxTradeSkillMicro.IsRowActiveOnBar
            and not FluxTradeSkillMicro:IsRowActiveOnBar(name) then
            return false
        end
        return self:ShouldShowNativeOnBar(name)
    end
    if FluxMicroMenu and FluxMicroMenu.IsNativeRowAvailableOnClient
        and not FluxMicroMenu:IsNativeRowAvailableOnClient(name) then
        return false
    end
    if name == "FluxLFGMicroButton" and FluxMicroMenu and FluxMicroMenu.HasBlizzardGroupFinderMicroButton and FluxMicroMenu:HasBlizzardGroupFinderMicroButton() then
        return false
    end
    if btn.minimapButtonName then
        return FluxMinimapToMicro and FluxMinimapToMicro.IsEnabled and FluxMinimapToMicro:IsEnabled(btn.minimapButtonName)
    end
    return self:ShouldShowNativeOnBar(name)
end

--- Classic/Anniversary: Blizzard UpdateMicroButtons still SetPoints QuestLog to Talent. Parking natives on
--- FluxHiddenParent while the visible bar lives on FluxMicroMenu can trigger "Cannot anchor to a region dependent on it".
local function GetParkParentForHiddenNative(hiddenParent)
    if WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        return hiddenParent
    end
    return FluxMicroMenu or hiddenParent
end

function C:ParkHiddenButtons(discoveredList, visibleOrdered, hiddenParent)
    local visible = {}
    for _, b in ipairs(visibleOrdered) do
        visible[b] = true
    end
    if InCombatLockdown() then return end
    local parkParent = GetParkParentForHiddenNative(hiddenParent)
    for _, btn in ipairs(discoveredList) do
        if btn and not visible[btn] then
            local name = btn:GetName()
            if name and not btn.minimapButtonName
                and not (FluxMicroMenu.ShouldLeaveBlizzardButtonShown
                    and FluxMicroMenu:ShouldLeaveBlizzardButtonShown(name)) then
                btn:SetParent(parkParent)
                btn:Hide()
            end
        end
    end
end

-- Coalesce multiple Notify* calls in the same frame into one rebuild (avoids repeated pairs(_G) + layout).
local notifyDeferredScheduled = false
local notifyDeferredIncludeMinimap = false

local function RunDeferredNotify()
    notifyDeferredScheduled = false
    local doMinimap = notifyDeferredIncludeMinimap
    notifyDeferredIncludeMinimap = false

    FireCallbacks()
    if FluxMicroMenu and FluxMicroMenu.Rebuild then
        FluxMicroMenu:Rebuild()
    end
    if doMinimap and FluxMinimapToMicro and FluxMinimapToMicro.RebuildMicroButtons then
        FluxMinimapToMicro:RebuildMicroButtons()
    end
end

local function ScheduleDeferredNotify(includeMinimap)
    if includeMinimap then
        notifyDeferredIncludeMinimap = true
    end
    if notifyDeferredScheduled then
        return
    end
    notifyDeferredScheduled = true
    C_Timer.After(0, RunDeferredNotify)
end

function C:NotifyChanged()
    ScheduleDeferredNotify(true)
end

function C:NotifyLayoutOnly()
    ScheduleDeferredNotify(false)
end

-- ---------------------------------------------------------------------------
-- Unified rows for editor: { rowId, kind, label, mode }
-- ---------------------------------------------------------------------------

function C:GetEffectiveRows()
    self:EnsureUnifiedDefaults()
    if FluxMinimapToMicro then
        if FluxMinimapToMicro.HarvestNamedMinimapButtons then
            FluxMinimapToMicro:HarvestNamedMinimapButtons()
        end
        if FluxMinimapToMicro.ScanButtons then
            FluxMinimapToMicro:ScanButtons(true)
        end
    end
    local rows = {}
    local seen = {}
    for i, rowId in ipairs(self:GetUnifiedOrderList()) do
        if seen[rowId] then
            -- Defensive: duplicate rowIds would duplicate UI slots and stacked handlers after reorder.
        else
            seen[rowId] = true
            if self:IsMinimapRowId(rowId) then
                local src = self:GetMinimapSourceName(rowId)
                if not src then
                    -- skip invalid id
                elseif FluxMinimapToMicro and FluxMinimapToMicro.IsMinimapButtonPresent
                    and not FluxMinimapToMicro:IsMinimapButtonPresent(src) then
                    -- Omit M2M slots when the addon is not loaded / minimap button does not exist (saved order unchanged).
                else
                    local mode = (FluxMinimapToMicro and FluxMinimapToMicro.GetMode) and FluxMinimapToMicro:GetMode(src) or "off"
                    table.insert(rows, {
                        rowId = rowId,
                        kind = "minimap",
                        name = src,
                        mode = mode,
                        unifiedListIndex = i,
                    })
                end
            else
                local show = true
                if self:IsTradeSkillRelatedRowId(rowId) then
                    -- Omit from editor when not currently on the bar; saved unified order is kept.
                    show = FluxTradeSkillMicro and FluxTradeSkillMicro.IsRowActiveOnBar
                        and FluxTradeSkillMicro:IsRowActiveOnBar(rowId)
                elseif FluxMicroMenu and FluxMicroMenu.IsNativeRowAvailableOnClient
                    and not FluxMicroMenu:IsNativeRowAvailableOnClient(rowId) then
                    -- Omit unavailable native slots (stub frames on classic); saved order unchanged.
                    show = false
                end
                if show then
                    local displayName = rowId
                    if self:IsTradeSkillRowId(rowId) then
                        local key = self:GetTradeSkillKey(rowId)
                        local skillName
                        if FluxTradeSkillMicro and FluxTradeSkillMicro.GetSkillDisplayName then
                            skillName = FluxTradeSkillMicro:GetSkillDisplayName(key)
                        elseif key and FluxTradeSkillMicro and FluxTradeSkillMicro.skillsByKey then
                            local s = FluxTradeSkillMicro.skillsByKey[key]
                            skillName = s and s.name
                        end
                        displayName = skillName or key or rowId
                    elseif self:IsTradeSkillFlyoutRowId(rowId) then
                        displayName = "Trade Skills"
                    end
                    table.insert(rows, {
                        rowId = rowId,
                        kind = "native",
                        name = displayName,
                        mode = self:GetNativeMode(rowId),
                        unifiedListIndex = i,
                    })
                end
            end
        end
    end
    return rows
end

function C:CycleRowMode(rowId)
    if self:IsMinimapRowId(rowId) then
        local src = self:GetMinimapSourceName(rowId)
        if FluxMinimapToMicro and FluxMinimapToMicro.CycleMode then
            FluxMinimapToMicro:CycleMode(src)
        end
        FireCallbacks()
        return
    end
    self:CycleNativeMode(rowId)
end

--- insertPos: 1..n+1 = insert before that index in the list *before* the move (n+1 = append). Prevents duplicate rows from bad insert math.
function C:ReorderUnifiedRows(fromIndex, insertPos)
    local list = self:GetUnifiedOrderList()
    local n = #list
    if not list[fromIndex] then return end
    if insertPos < 1 or insertPos > n + 1 then return end
    if insertPos == fromIndex then
        return
    end
    local entry = table.remove(list, fromIndex)
    local insertAt = insertPos
    if insertPos > fromIndex then
        insertAt = insertPos - 1
    end
    if insertAt < 1 then insertAt = 1 end
    if insertAt > #list + 1 then insertAt = #list + 1 end
    table.insert(list, insertAt, entry)
    self:SetUnifiedOrderList(list)
    self:NormalizeUnifiedOrderList()
    self:NotifyChanged()
end

local function FindRowIndex(list, rowId)
    if not list or not rowId then return nil end
    for i, id in ipairs(list) do
        if id == rowId then
            return i
        end
    end
    return nil
end

--- Move fromRowId so it sits immediately before beforeRowId (nil = append at end).
--- Prefer this over index math when the editor hides inactive trade-skill rows.
function C:ReorderUnifiedRowById(fromRowId, beforeRowId)
    if not fromRowId or fromRowId == beforeRowId then
        return
    end
    local list = self:GetUnifiedOrderList()
    local fromIndex = FindRowIndex(list, fromRowId)
    if not fromIndex then
        return
    end
    local insertPos
    if beforeRowId == nil then
        insertPos = #list + 1
    else
        insertPos = FindRowIndex(list, beforeRowId)
        if not insertPos then
            insertPos = #list + 1
        end
    end
    self:ReorderUnifiedRows(fromIndex, insertPos)
end

--- Move fromRowId so it sits immediately after afterRowId.
function C:ReorderUnifiedRowAfter(fromRowId, afterRowId)
    if not fromRowId or not afterRowId or fromRowId == afterRowId then
        return
    end
    local list = self:GetUnifiedOrderList()
    local fromIndex = FindRowIndex(list, fromRowId)
    local afterIndex = FindRowIndex(list, afterRowId)
    if not fromIndex or not afterIndex then
        return
    end
    -- Insert before the item that currently follows afterRowId (skipping fromRowId if it is next).
    local beforeRowId = nil
    for i = afterIndex + 1, #list do
        if list[i] ~= fromRowId then
            beforeRowId = list[i]
            break
        end
    end
    self:ReorderUnifiedRowById(fromRowId, beforeRowId)
end

function C:SwapUnifiedRows(i, j)
    local list = self:GetUnifiedOrderList()
    if not list[i] or not list[j] then return end
    list[i], list[j] = list[j], list[i]
    self:NotifyChanged()
end

-- ---------------------------------------------------------------------------
-- Reset: default row order + factory on/off (native = account, minimap = off)
-- ---------------------------------------------------------------------------

local function BuildFreshDefaultUnifiedOrderList()
    local unified = {}
    local seen = {}
    if FluxMicroMenu and FluxMicroMenu.GetDefaultUnifiedRowIds then
        for _, rowId in ipairs(FluxMicroMenu:GetDefaultUnifiedRowIds()) do
            if not seen[rowId] then
                seen[rowId] = true
                table.insert(unified, rowId)
            end
        end
    end
    if FluxMinimapToMicro and FluxMinimapToMicro.ScanButtons then
        FluxMinimapToMicro:ScanButtons()
        for _, data in ipairs(FluxMinimapToMicro.scannedButtons or {}) do
            if data and data.name then
                local id = C:MakeMinimapRowId(data.name)
                if not seen[id] then
                    seen[id] = true
                    table.insert(unified, id)
                end
            end
        end
    end
    if FluxMicroMenu and FluxMicroMenu.GetDiscoveredMicroButtonNames then
        for _, gname in ipairs(FluxMicroMenu:GetDiscoveredMicroButtonNames()) do
            local rowId = C:UnifiedRowIdFromGlobalMicroName(gname)
            if rowId and not seen[rowId]
                and (not FluxMicroMenu.IsNativeRowAvailableOnClient or FluxMicroMenu:IsNativeRowAvailableOnClient(rowId)) then
                seen[rowId] = true
                table.insert(unified, rowId)
            end
        end
    end
    return unified
end

--- Restore canonical row order (default natives + minimap scan + discovered extras). Does not change Account/Character/Off.
function C:ResetUnifiedOrderToDefault()
    self:EnsureUnifiedDefaults()
    local unified = BuildFreshDefaultUnifiedOrderList()
    self:SetUnifiedOrderList(unified)
    self:ConsolidateMinimapMicroDuplicates()
    self:NormalizeUnifiedOrderList()
    self:NotifyChanged()
end

--- Full factory reset: default order, every native row on Account, every minimap row Off.
function C:ResetMicroMenuToFactoryDefaults()
    self:EnsureUnifiedDefaults()
    local unified = BuildFreshDefaultUnifiedOrderList()
    self:SetUnifiedOrderList(unified)
    self:ConsolidateMinimapMicroDuplicates()
    self:NormalizeUnifiedOrderList()
    unified = self:GetUnifiedOrderList()

    EnsureSavedVars()
    wipe(FluxUI_DB.MicroMenu.native)
    FluxUI_DB.MicroMenu.native = {}
    wipe(_FluxUI_CharSavedVars.MicroMenu.native)
    _FluxUI_CharSavedVars.MicroMenu.native = {}

    if FluxMinimapToMicro and FluxMinimapToMicro.WipeAllButtonSavedState then
        FluxMinimapToMicro:WipeAllButtonSavedState()
    end

    local nativeOrder = 0
    for _, rowId in ipairs(unified) do
        if not self:IsMinimapRowId(rowId) then
            nativeOrder = nativeOrder + 1
            if self:IsTradeSkillRelatedRowId(rowId) then
                _FluxUI_CharSavedVars.MicroMenu.native[rowId] = { order = nativeOrder }
            else
                FluxUI_DB.MicroMenu.native[rowId] = { order = nativeOrder }
            end
        end
    end
    self:NotifyChanged()
end
