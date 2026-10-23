--[[
    ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua

    Creates 4 NonCombat Utility Slot FluxButtons, multi-mod secure macros,
    key bindings, drag-drop assign, and empty-slot visibility while dragging near.
]]

FluxNCUtilitySlotsManager = FluxNCUtilitySlotsManager or {}
local Manager = FluxNCUtilitySlotsManager

local MAX_SLOTS = 4
local UPDATE_DEBOUNCE = 0.075
local NEAR_PAD = 48
local BINDING_PREFIX = "FLUXSPELLBOOKSLOT"

Manager.buttons = {}
Manager.grid = nil

local function Assign()
    return _G.FluxNCUtilitySlots
end

local function After(delay, fn)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

function Manager.GetGrid()
    if Manager.grid then
        return Manager.grid
    end
    local API = _G.FluxNonCombatAPI
    if API and API.DefaultGrid then
        Manager.grid = API.DefaultGrid
        return Manager.grid
    end
    return nil
end

function Manager.OnNonCombatGridReady(grid)
    if grid then
        Manager.grid = grid
    end
    Manager.EnsureButtons()
    Manager.UpdateAllSlots()
end

local function RequestRelayout()
    local grid = Manager.GetGrid()
    if grid and grid.ScheduleRelayout then
        grid:ScheduleRelayout()
    elseif grid and grid.Relayout and not InCombatLockdown() then
        grid:Relayout()
    end
    local EBV = _G.FluxExtraButtonVisibility
    if EBV and EBV.RequestLayoutNow then
        EBV.RequestLayoutNow()
    end
end

local function ClearModMacroAttrs(w)
    if not w then
        return
    end
    local prefixes = { "shift-", "ctrl-", "alt-", "alt-ctrl-", "alt-shift-", "ctrl-shift-", "alt-ctrl-shift-", "" }
    for i = 1, #prefixes do
        local p = prefixes[i]
        w:SetAttribute(p .. "type1", nil)
        w:SetAttribute(p .. "typerelease1", nil)
        w:SetAttribute(p .. "macro1", nil)
        w:SetAttribute(p .. "macrotext1", nil)
    end
end

local function AttrPrefixForMod(modKey)
    if not modKey or modKey == "" then
        return ""
    end
    return string.lower(modKey):gsub("-", "-") .. "-"
end

local function FormatSpellCast(spellId)
    spellId = tonumber(spellId)
    if not spellId then
        return nil
    end
    local Flux = _G.Flux
    if Flux and Flux.Spell and Flux.Spell.FormatCastAttribute then
        local attr = Flux.Spell.FormatCastAttribute(spellId)
        if type(attr) == "string" and attr ~= "" then
            return attr
        end
    end
    if _G.FluxFormatSpellCastAttribute then
        local attr = _G.FluxFormatSpellCastAttribute(spellId)
        if type(attr) == "string" and attr ~= "" then
            return attr
        end
    end
    return nil
end

--- Slash action fragment for non-macro entries (no leading /cast|/use).
local function ActionToken(entry)
    if not entry or not entry.type then
        return nil, nil
    end
    local t = entry.type
    if t == "outfit" then
        local A = Assign()
        local info = A and A.GetOutfitInfo and A.GetOutfitInfo(entry.id)
        if info and not info.isDisabled then return "outfit", info.isClear and "" or ("!" .. tostring(info.index)) end
        return nil, nil
    end
    if t == "spell" then
        local name = entry.name
        local spellId = tonumber(entry.id)
        -- Prefer Name(Rank N) from id so lower ranks cast correctly even if entry.name is bare.
        local attr = spellId and FormatSpellCast(spellId)
        if type(attr) == "string" and attr ~= "" then
            name = attr
        elseif (not name or name == "") and spellId then
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(spellId)
                name = info and info.name
            elseif GetSpellInfo then
                name = GetSpellInfo(spellId)
            end
        end
        return "cast", name or ("spell:" .. tostring(entry.id))
    end
    if t == "item" or t == "toy" then
        return "use", "item:" .. tostring(entry.id)
    end
    if t == "mount" then
        local name = entry.name
        if (not name or name == "") and C_MountJournal and C_MountJournal.GetMountInfoByID then
            name = C_MountJournal.GetMountInfoByID(tonumber(entry.id))
        end
        return "cast", name or tostring(entry.id)
    end
    if t == "battlepet" then
        return "summonpet", tostring(entry.id)
    end
    return nil, nil
end

local function CondPrefix(modKey)
    if not modKey or modKey == "" then
        return "[@mouseover,exists,nodead][]"
    end
    local condMod = string.lower(modKey):gsub("-", ",")
    return "[mod:" .. condMod .. ",@mouseover,exists,nodead][mod:" .. condMod .. "]"
end

function Manager.BuildMacroText(slotData)
    if type(slotData) ~= "table" then
        return nil
    end
    local castParts, useParts, petParts, outfitParts = {}, {}, {}, {}

    local modKeys = {}
    for k, v in pairs(slotData) do
        if k ~= "" and type(v) == "table" and v.type and v.type ~= "macro" then
            modKeys[#modKeys + 1] = k
        end
    end
    table.sort(modKeys, function(a, b)
        return #a > #b
    end)

    local function addEntry(modKey, entry)
        local slash, token = ActionToken(entry)
        if not slash or not token then
            return
        end
        local prefix = CondPrefix(modKey)
        local frag = prefix .. " " .. token
        if slash == "cast" then
            castParts[#castParts + 1] = frag
        elseif slash == "use" then
            useParts[#useParts + 1] = frag
        elseif slash == "summonpet" then
            petParts[#petParts + 1] = frag
        elseif slash == "outfit" then
            outfitParts[#outfitParts + 1] = frag
        end
    end

    for i = 1, #modKeys do
        addEntry(modKeys[i], slotData[modKeys[i]])
    end

    local base = slotData[""]
    if type(base) == "table" and base.type and base.type ~= "macro" then
        addEntry("", base)
    else
        -- Nomod empty: mirror SHIFT > CTRL > ALT > combos (same order as Assign).
        local A = Assign()
        local order = A and A.GetMirrorPrefOrder and A.GetMirrorPrefOrder()
            or { "SHIFT", "CTRL", "ALT", "SHIFT-CTRL", "SHIFT-ALT", "CTRL-ALT", "SHIFT-CTRL-ALT" }
        for i = 1, #order do
            local v = slotData[order[i]]
            if type(v) == "table" and v.type and v.type ~= "macro" and v.id ~= nil then
                addEntry("", v)
                break
            end
        end
    end

    local lines = { "#showtooltip" }
    if #castParts > 0 then
        lines[#lines + 1] = "/cast " .. table.concat(castParts, "; ")
    end
    if #useParts > 0 then
        lines[#lines + 1] = "/use " .. table.concat(useParts, "; ")
    end
    if #petParts > 0 then
        lines[#lines + 1] = "/summonpet " .. table.concat(petParts, "; ")
    end
    if #outfitParts > 0 then lines[#lines + 1] = "/outfit " .. table.concat(outfitParts, "; ") end
    if #lines == 1 then
        return nil
    end
    return table.concat(lines, "\n")
end

local function ApplyMacroAttributes(btn, slotData)
    local w = btn and btn.Widget
    if not w then
        return
    end
    ClearModMacroAttrs(w)
    if type(slotData) ~= "table" then
        return
    end
    -- Outfit clear has an empty /outfit argument. Bind each exact chord to its
    -- chosen action so a different modifier cannot fall through and clear gear.
    local hasOutfit = false
    for _, entry in pairs(slotData) do
        if type(entry) == "table" and entry.type == "outfit" then hasOutfit = true; break end
    end
    if hasOutfit then
        local A = Assign()
        local base = A and A.ResolveNomodEntry and select(1, A.ResolveNomodEntry(slotData)) or slotData[""]
        local chords = {
            { "", "" }, { "SHIFT", "shift-" }, { "CTRL", "ctrl-" }, { "ALT", "alt-" },
            { "SHIFT-CTRL", "ctrl-shift-" }, { "SHIFT-ALT", "alt-shift-" },
            { "CTRL-ALT", "alt-ctrl-" }, { "SHIFT-CTRL-ALT", "alt-ctrl-shift-" },
        }
        for _, chord in ipairs(chords) do
            local entry, prefix = slotData[chord[1]] or base, chord[2]
            w:SetAttribute(prefix .. "type1", "macro")
            w:SetAttribute(prefix .. "typerelease1", "macro")
            if entry and entry.type == "macro" then
                w:SetAttribute(prefix .. "macro1", entry.name or entry.id)
            else
                w:SetAttribute(prefix .. "macrotext1", entry and Manager.BuildMacroText({ [""] = entry }) or "")
            end
        end
        local Click = _G.Flux and _G.Flux.ButtonFX and _G.Flux.ButtonFX.Click
        if Click and Click.MirrorTypeRelease then Click.MirrorTypeRelease(w) end
        return
    end
    for modKey, entry in pairs(slotData) do
        if type(entry) == "table" and entry.type == "macro" then
            local prefix = AttrPrefixForMod(modKey)
            local macroId = entry.name or entry.id
            w:SetAttribute(prefix .. "type1", "macro")
            w:SetAttribute(prefix .. "typerelease1", "macro")
            w:SetAttribute(prefix .. "macro1", macroId)
        end
    end
    -- Nomod empty: mirror first preferred mod macro onto base attributes.
    local nomod = slotData[""]
    if not (type(nomod) == "table" and nomod.type == "macro") then
        local A = Assign()
        local mirrored = A and A.ResolveNomodEntry and select(1, A.ResolveNomodEntry(slotData))
        if type(mirrored) == "table" and mirrored.type == "macro" then
            local macroId = mirrored.name or mirrored.id
            w:SetAttribute("type1", "macro")
            w:SetAttribute("typerelease1", "macro")
            w:SetAttribute("macro1", macroId)
        end
    end
    local Click = _G.Flux and _G.Flux.ButtonFX and _G.Flux.ButtonFX.Click
    if Click and Click.MirrorTypeRelease then
        Click.MirrorTypeRelease(w)
    end
end

--- Midnight cast/charge numbers are secret while this addon is tainted.
--- issecretvalue before any ~= / > compare; secrets go to SetText as-is.
local function ValueIsSecret(value)
    if value == nil then
        return false
    end
    local S = _G.Flux and _G.Flux.Secrets
    if S and S.IsSecretValue then
        local ok, secret = pcall(S.IsSecretValue, value)
        if ok then
            return secret and true or false
        end
    end
    if issecretvalue then
        local ok, secret = pcall(issecretvalue, value)
        return ok and secret and true or false
    end
    return false
end

local function SafeNotEqual(a, b)
    if a == nil or ValueIsSecret(a) or ValueIsSecret(b) then
        return nil
    end
    local S = _G.Flux and _G.Flux.Secrets
    if S and S.SafeCompare then
        return S.SafeCompare(a, b, "~=")
    end
    local ok, cmp = pcall(function()
        return a ~= b
    end)
    if ok then
        return cmp
    end
    return nil
end

--- Spell reagent / cast count (teleports, rituals) then multi-charges — same rules as FluxButton.
local function GetSpellDisplayCount(spellId)
    spellId = tonumber(spellId) or spellId
    if not spellId then
        return nil
    end

    local Flux = _G.Flux
    if Flux and Flux.Spell and Flux.Spell.GetDisplayCount then
        local display = Flux.Spell.GetDisplayCount(spellId)
        if not (display == nil) then
            if ValueIsSecret(display) then
                return display
            end
            if display ~= "" then
                return display
            end
        end
    elseif C_Spell and C_Spell.GetSpellDisplayCount then
        local ok, display = pcall(C_Spell.GetSpellDisplayCount, spellId)
        if ok and not (display == nil) then
            if ValueIsSecret(display) then
                return display
            end
            if display ~= "" then
                return display
            end
        end
    end

    local count
    if C_Spell and C_Spell.GetSpellCastCount then
        local ok, c = pcall(C_Spell.GetSpellCastCount, spellId)
        if ok then
            count = c
        end
    end
    if count == nil and GetSpellCount then
        local ok, c = pcall(GetSpellCount, spellId)
        if ok then
            count = c
        end
    end
    if count == nil then
        local LCSAC = LibStub and LibStub("LibClassicSpellActionCount-1.0", true)
        if LCSAC and LCSAC.GetSpellReagentCount then
            count = LCSAC:GetSpellReagentCount(spellId)
        end
    end

    if not (count == nil) and ValueIsSecret(count) then
        return count
    end

    local isConsumable = false
    if C_Spell and C_Spell.IsConsumableSpell then
        local ok, v = pcall(C_Spell.IsConsumableSpell, spellId)
        if ok and not (v == nil) and not ValueIsSecret(v) then
            isConsumable = v and true or false
        end
    elseif IsConsumableSpell then
        local ok, v = pcall(IsConsumableSpell, spellId)
        if ok and not (v == nil) and not ValueIsSecret(v) then
            isConsumable = v and true or false
        end
    end
    if SafeNotEqual(count, 0) or isConsumable then
        return count or 0
    end

    if C_Spell and C_Spell.GetSpellCharges then
        local ok, chargesInfo = pcall(C_Spell.GetSpellCharges, spellId)
        if ok and chargesInfo then
            local maxCharges = chargesInfo.maxCharges
            if not (maxCharges == nil) and (ValueIsSecret(maxCharges) or ValueIsSecret(chargesInfo.currentCharges) or SafeNotEqual(maxCharges, 1)) then
                return chargesInfo.currentCharges
            end
        end
    elseif GetSpellCharges then
        local ok, cur, maxCharges = pcall(GetSpellCharges, spellId)
        if ok and not (maxCharges == nil) and (ValueIsSecret(maxCharges) or ValueIsSecret(cur) or SafeNotEqual(maxCharges, 1)) then
            return cur
        end
    end
    return nil
end

local function ClearForcedCount(btn)
    if btn.SetCount then
        btn:SetCount(nil)
    elseif btn.WCount then
        btn.WCount:Show()
        btn.WCount:SetText("")
    end
    btn._forcedCount = nil
    btn._forcedCountLive = nil
    btn._liveCountItemId = nil
end

--- Currently displayed entry for count / checked / preview.
--- Exact held chord wins; if that chord is empty, fall back to nomod (or nomod-mirror).
local function ResolveDisplayEntry(A, slotIndex, map)
    if type(map) ~= "table" and A and A.GetSlots then
        local slots = A.GetSlots()
        map = slots and slots[slotIndex]
    end
    if type(map) ~= "table" then
        return nil, nil
    end
    local mod = A and A.GetCurrentModKey and A.GetCurrentModKey() or ""
    if mod ~= "" then
        local e = map[mod]
        if type(e) == "table" and e.type and e.id ~= nil then
            return e, mod
        end
        -- Unassigned modifier chord → same as no-mod display (real "" or SHIFT-first mirror).
    end
    if A and A.ResolveNomodEntry then
        return A.ResolveNomodEntry(map)
    end
    local e = map[""]
    if type(e) == "table" and e.type and e.id ~= nil then
        return e, ""
    end
    return nil, nil
end

local function EntryIsChecked(entry)
    if type(entry) ~= "table" or not entry.type or entry.id == nil then
        return false
    end
    local t = entry.type
    local id = entry.id
    if t == "outfit" then
        local A = Assign()
        return A and A.IsOutfitActive and A.IsOutfitActive(id) or false
    end

    if t == "spell" then
        if C_Spell and C_Spell.IsCurrentSpell then
            if C_Spell.IsCurrentSpell(id) then
                return true
            end
            local ranked = entry.name
            if (not ranked or not ranked:find("%(", 1, true)) then
                local attr = FormatSpellCast(id)
                if type(attr) == "string" and attr ~= "" then
                    ranked = attr
                end
            end
            if ranked and C_Spell.IsCurrentSpell(ranked) then
                return true
            end
        elseif IsCurrentSpell then
            if IsCurrentSpell(id) then
                return true
            end
            local ranked = entry.name
            if (not ranked or not ranked:find("%(", 1, true)) then
                local attr = FormatSpellCast(id)
                if type(attr) == "string" and attr ~= "" then
                    ranked = attr
                end
            end
            if ranked and IsCurrentSpell(ranked) then
                return true
            end
        end
        return false
    end

    if t == "item" or t == "toy" then
        if C_Item and C_Item.IsCurrentItem then
            return C_Item.IsCurrentItem(id) and true or false
        end
        if IsCurrentItem then
            return IsCurrentItem(id) and true or false
        end
        return false
    end

    if t == "mount" then
        if C_MountJournal and C_MountJournal.GetMountInfoByID then
            -- 4th return is isActive
            return select(4, C_MountJournal.GetMountInfoByID(tonumber(id) or id)) and true or false
        end
        return false
    end

    if t == "battlepet" then
        if C_PetJournal and C_PetJournal.GetSummonedPetGUID then
            return id == C_PetJournal.GetSummonedPetGUID()
        end
        return false
    end

    if t == "macro" then
        -- Best-effort: treat macro name/body target as spell if currently casting that spell.
        local name = entry.name
        if name and C_Spell and C_Spell.IsCurrentSpell then
            return C_Spell.IsCurrentSpell(name) and true or false
        end
        if name and IsCurrentSpell then
            return IsCurrentSpell(name) and true or false
        end
        return false
    end

    return false
end

local function RefreshChecked(btn, slotData)
    local w = btn and btn.Widget
    if not w then
        return
    end
    local A = Assign()
    local entry = select(1, ResolveDisplayEntry(A, btn.slotIndex, slotData or btn.SlotData))
    local shouldBeChecked = EntryIsChecked(entry)
    -- Extra Paint golds StanceActiveVisual before macrotext faces. Mount / pet
    -- assignments stay type=macrotext, so stamp that visual here.
    if entry and (entry.type == "mount" or entry.type == "battlepet" or entry.type == "outfit") then
        btn.StanceActiveVisual = shouldBeChecked and true or nil
    else
        btn.StanceActiveVisual = nil
    end
    local Flux = _G.Flux
    local Paint = Flux and Flux.EBS and Flux.EBS.Paint
    if Paint and Paint.UpdateChecked and btn.ActionType then
        Paint.UpdateChecked(btn)
        return
    end
    local ov = Flux and Flux.ButtonFX and Flux.ButtonFX.Overlay
    if ov and ov.ApplyChecked then
        ov.ApplyChecked(w, shouldBeChecked)
        return
    end
    if w.SetChecked then
        w:SetChecked(shouldBeChecked and true or false)
    end
    local checkedTexture = w.GetCheckedTexture and w:GetCheckedTexture()
    if checkedTexture then
        if shouldBeChecked then
            checkedTexture:Show()
        else
            checkedTexture:Hide()
        end
    end
end

local function RefreshAllChecked()
    for i = 1, MAX_SLOTS do
        local btn = Manager.buttons[i]
        if btn then
            RefreshChecked(btn, btn.SlotData)
        end
    end
end

local function RefreshItemCount(btn, slotData)
    local A = Assign()
    local entry = select(1, ResolveDisplayEntry(A, btn.slotIndex, slotData))
    local wasOutfit = btn._fluxUtilityOutfitID ~= nil
    if entry and entry.type == "outfit" then
        btn._fluxUtilityOutfitID = entry.id
        btn._fluxUtilityOutfitInfo = A and A.GetOutfitInfo and A.GetOutfitInfo(entry.id)
        btn.IconOverrideTexture = btn._fluxUtilityOutfitInfo and btn._fluxUtilityOutfitInfo.icon or 134400
    elseif wasOutfit then
        btn._fluxUtilityOutfitID, btn._fluxUtilityOutfitInfo, btn.IconOverrideTexture = nil, nil, nil
    end
    if wasOutfit or btn._fluxUtilityOutfitID ~= nil then
        local Paint = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint
        if Paint then
            if Paint.UpdateIcon then Paint.UpdateIcon(btn) end
            if Paint.UpdateCooldown then Paint.UpdateCooldown(btn) end
            if Paint.UpdateUsable then Paint.UpdateUsable(btn) end
        end
    end

    if type(entry) ~= "table" or entry.id == nil then
        ClearForcedCount(btn)
        return
    end

    -- Spells: reagent/cast count or multi-charges (utility slots use macrotext, so FluxButton auto-count won't see them).
    if entry.type == "spell" then
        local spellCount = GetSpellDisplayCount(entry.id)
        if spellCount == nil then
            ClearForcedCount(btn)
            return
        end
        if btn.SetCount then
            btn:SetCount(spellCount)
        elseif btn.WCount then
            btn.WCount:SetText(tostring(spellCount))
            btn.WCount:Show()
        end
        return
    end

    -- Stackable items only.
    if entry.type ~= "item" then
        ClearForcedCount(btn)
        return
    end

    local itemID = tonumber(entry.id)
    if not itemID then
        ClearForcedCount(btn)
        return
    end

    local maxStack = 1
    local Best = _G.FluxConsumableBest
    if Best and Best.Score and Best.Score.GetMaxStack then
        maxStack = Best.Score.GetMaxStack(itemID) or 1
    elseif C_Item and C_Item.GetItemMaxStackSizeByID then
        local ok, n = pcall(C_Item.GetItemMaxStackSizeByID, itemID)
        if ok and type(n) == "number" then
            maxStack = n
        end
    end
    if maxStack <= 1 then
        ClearForcedCount(btn)
        return
    end

    local count = 0
    local inv = _G.FluxInv
    if inv and inv.Bags and inv.Bags.GetCount then
        count = inv.Bags.GetCount(itemID) or 0
    elseif inv and inv.GetCount then
        count = inv.GetCount(itemID, {
            bags = true,
            bank = false,
            warband = false,
            equipped = false,
            includeBank = false,
        }) or 0
    end
    if btn.SetCount then
        btn:SetCount(count, { live = true, itemId = itemID })
    elseif btn.WCount then
        if count > 1 then
            btn.WCount:Show()
            btn.WCount:SetText(tostring(count))
        else
            btn.WCount:Show()
            btn.WCount:SetText("")
        end
    end
end

local function RefreshAllItemCounts()
    for i = 1, MAX_SLOTS do
        local btn = Manager.buttons[i]
        if btn then
            RefreshItemCount(btn, btn.SlotData)
        end
    end
end

local function ShowEmptySlot(btn)
    if not btn then
        return
    end
    if btn.ClearAction then
        btn:ClearAction()
    end
    if btn.ClearPlaceholder then
        btn:ClearPlaceholder()
    end
    btn.PlaceholderTexture = nil
    btn.PlaceholderLabel = nil
    local Paint = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint
    if Paint and Paint.UpdateEmpty then
        Paint.UpdateEmpty(btn)
    elseif btn.UpdateEmptyBackground then
        btn:UpdateEmptyBackground()
    elseif btn.WEmptyBG then
        btn.WEmptyBG:Show()
    end
    if btn.WIcon then
        btn.WIcon:SetTexture(nil)
        btn.WIcon:Hide()
    end
end

function Manager.UpdateHotkeys(btn)
    if not btn or not btn.slotIndex then
        return
    end
    local hasMod = false
    if btn.SlotData then
        for modKey, entry in pairs(btn.SlotData) do
            if modKey ~= "" and type(entry) == "table" then
                hasMod = true
                break
            end
        end
    end
    local bindingName = BINDING_PREFIX .. btn.slotIndex
    if FluxNCHotkeyUtil and FluxNCHotkeyUtil.UpdateHotkeyText then
        FluxNCHotkeyUtil.UpdateHotkeyText(btn, bindingName, false, hasMod)
    else
        local key = GetBindingKey and GetBindingKey(bindingName)
        local text = key or ""
        if btn.WHotKey then
            btn.WHotKey:SetText(text)
            if text ~= "" then
                btn.WHotKey:Show()
            else
                btn.WHotKey:Hide()
            end
        end
    end
end

function Manager.UpdateButton(btn, slotData)
    if not btn then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        Manager._pendingUpdate = true
        return
    end
    btn.SlotData = slotData
    local macroText = Manager.BuildMacroText(slotData)
    local anyNonMacro, anyMacro = false, false
    if type(slotData) == "table" then
        for _, e in pairs(slotData) do
            if type(e) == "table" then
                if e.type == "macro" then
                    anyMacro = true
                else
                    anyNonMacro = true
                end
            end
        end
    end
    local hasMacroOnly = anyMacro and not anyNonMacro

    if macroText and btn.SetAction then
        btn:SetAction("macrotext", macroText)
    elseif hasMacroOnly then
        local base = slotData[""]
        if not (type(base) == "table" and base.type == "macro") then
            local A = Assign()
            base = A and A.ResolveNomodEntry and select(1, A.ResolveNomodEntry(slotData))
        end
        if type(base) == "table" and base.type == "macro" and btn.SetAction then
            btn:SetAction("macro", base.name or base.id)
        elseif btn.ClearAction then
            btn:ClearAction()
        end
    elseif btn.ClearAction then
        btn:ClearAction()
    end

    ApplyMacroAttributes(btn, slotData)
    RefreshItemCount(btn, slotData)
    RefreshChecked(btn, slotData)

    -- Rank desat on first paint (UtilitySlots are macrotext; don't wait for SRM +1s scan).
    do
        local A = Assign()
        local entry = select(1, ResolveDisplayEntry(A, btn.slotIndex, slotData))
        local SRM = _G.FluxSpellRankManager or _G.FluxSpellRankManagerModule
        if entry and entry.type == "spell" and entry.id and SRM and SRM.ApplyRankDesaturation then
            SRM:ApplyRankDesaturation(btn, entry.id)
        elseif btn.SpellId and SRM and SRM.ApplyRankDesaturation then
            SRM:ApplyRankDesaturation(btn, btn.SpellId)
        end
        if btn.UpdateUsable then
            btn:UpdateUsable()
        elseif _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint and _G.Flux.EBS.Paint.UpdateUsable then
            _G.Flux.EBS.Paint.UpdateUsable(btn)
        end
    end

    local ebs = _G.Flux and _G.Flux.EBS
    if ebs and ebs.Style and ebs.Style.Apply then
        ebs.Style.Apply(btn, btn.categoryScope or "class")
    elseif FluxNonCombatGrid and FluxNonCombatGrid.ApplyButtonStyle then
        FluxNonCombatGrid.ApplyButtonStyle(btn, "class")
    end
    Manager.UpdateHotkeys(btn)
end

local function PickupEntry(entry)
    if type(entry) ~= "table" or not entry.type or entry.id == nil then
        return false
    end
    local t = entry.type
    if t == "outfit" then
        local A = Assign()
        return A and A.PickupOutfit and A.PickupOutfit(entry.id) or false
    elseif t == "spell" then
        local A = Assign()
        local outfitID
        if A and A.GetOutfitIDForSpell then outfitID = A.GetOutfitIDForSpell(entry.id) end
        if outfitID ~= nil then
            return A.PickupOutfit and A.PickupOutfit(outfitID) or false
        end
        if C_Spell and C_Spell.PickupSpell then
            return pcall(C_Spell.PickupSpell, entry.id)
        end
        if PickupSpell then
            return pcall(PickupSpell, entry.id)
        end
    elseif t == "item" or t == "toy" then
        if PickupItem then
            return pcall(PickupItem, entry.id)
        end
    elseif t == "macro" then
        if PickupMacro then
            return pcall(PickupMacro, entry.name or entry.id)
        end
    elseif t == "mount" then
        if C_MountJournal and C_MountJournal.Pickup then
            return pcall(C_MountJournal.Pickup, tonumber(entry.id))
        end
    elseif t == "battlepet" then
        if C_PetJournal and C_PetJournal.PickupPet then
            return pcall(C_PetJournal.PickupPet, entry.id)
        end
    end
    return false
end

--- Entry + real mod key for drag-off clear (same fallback as display).
local function ResolveInteractionEntry(A, slotIndex)
    if not A or not A.GetSlots then
        return nil, nil
    end
    return ResolveDisplayEntry(A, slotIndex, A.GetSlots()[slotIndex])
end

local function WireSlotInteractions(btn)
    local w = btn.Widget
    if not w then
        return
    end
    btn.ButtonLocked = false
    -- Extra-window click wrap (fire on mouse-up) so drag-off does not also cast.
    -- Grid.CreateButton uses HUD onDown; utility slots must pick up instead.
    local Click = _G.Flux and _G.Flux.ButtonFX and _G.Flux.ButtonFX.Click
    if Click and Click.Apply then
        Click.Apply(w)
    end
    if w.RegisterForDrag then
        w:RegisterForDrag("LeftButton")
    end
    w:SetScript("OnReceiveDrag", function()
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        local A = Assign()
        if A and A.AssignFromCursor then
            A.AssignFromCursor(btn.slotIndex, A.GetCurrentModKey and A.GetCurrentModKey())
        end
    end)
    w:SetScript("OnDragStart", function()
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        local A = Assign()
        if not A then
            return
        end
        local entry, clearKey = ResolveInteractionEntry(A, btn.slotIndex)
        if type(entry) ~= "table" then
            return
        end
        if not PickupEntry(entry) then
            return
        end
        if A.ClearModifier and clearKey ~= nil then
            A.ClearModifier(btn.slotIndex, clearKey)
        end
    end)
    -- macrotext ActionType can't drive checked; use display entry instead.
    btn.UpdateChecked = function(self)
        RefreshChecked(self, self.SlotData)
    end
    w:EnableMouse(true)
end

function Manager.EnsureButtons()
    local grid = Manager.GetGrid()
    if not grid or not grid.CreateButton then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        Manager._pendingUpdate = true
        return
    end
    for slotIndex = 1, MAX_SLOTS do
        if not Manager.buttons[slotIndex] then
            local priority = (slotIndex <= 2) and 14 or 15
            local btn = grid:CreateButton({
                columnPriority = priority,
                columnGroup = "utility",
                order = slotIndex,
                size = grid.ButtonSize,
            })
            if btn then
                btn.slotIndex = slotIndex
                btn.IsUtilitySlotButton = true
                btn.categoryScope = btn.categoryScope or "class"
                Manager.buttons[slotIndex] = btn
                WireSlotInteractions(btn)
                local BM = _G.FluxBindingMode
                if BM and BM.RegisterButton and btn.Widget then
                    pcall(BM.RegisterButton, BM, btn.Widget, BINDING_PREFIX .. slotIndex)
                end
                ShowEmptySlot(btn)
                if btn.SlotFrame then
                    btn.SlotFrame:Hide()
                end
            end
        end
    end
end

local function ShouldForceShow()
    local fbm = _G.FluxBindingMode
    return fbm and fbm.ShouldForceShowAllExtraSlots and fbm:ShouldForceShowAllExtraSlots()
end

local function CursorNearUtilityZone()
    local grid = Manager.GetGrid()
    if not grid or not grid.Frame or not grid.Frame:IsVisible() then
        return false
    end
    if not GetCursorPosition or not UIParent or not UIParent.GetEffectiveScale then
        return false
    end
    local mx, my = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    if not scale or scale == 0 then
        return false
    end
    mx, my = mx / scale, my / scale

    -- Prefer union of utility slot frames; fall back to whole NC grid.
    local left, right, bottom, top
    for i = 1, MAX_SLOTS do
        local btn = Manager.buttons[i]
        local sf = btn and btn.SlotFrame
        if sf then
            local l, b, w, h = sf:GetLeft(), sf:GetBottom(), sf:GetWidth(), sf:GetHeight()
            if l and b and w and h then
                local r, t = l + w, b + h
                left = left and math.min(left, l) or l
                bottom = bottom and math.min(bottom, b) or b
                right = right and math.max(right, r) or r
                top = top and math.max(top, t) or t
            end
        end
    end
    if not left then
        local f = grid.Frame
        left, bottom = f:GetLeft(), f:GetBottom()
        local w, h = f:GetWidth(), f:GetHeight()
        if not left or not bottom or not w or not h then
            return false
        end
        right, top = left + w, bottom + h
    end
    left, bottom = left - NEAR_PAD, bottom - NEAR_PAD
    right, top = right + NEAR_PAD, top + NEAR_PAD
    return mx >= left and mx <= right and my >= bottom and my <= top
end

function Manager.ShouldShowEmptySlots()
    if ShouldForceShow() then
        return true
    end
    local A = Assign()
    if not (A and A.HasAssignableCursor and A.HasAssignableCursor()) then
        return false
    end
    return CursorNearUtilityZone()
end

function Manager.UpdateVisibility()
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local showEmpty = Manager.ShouldShowEmptySlots()
    local A = Assign()
    local changed = false
    for slotIndex = 1, MAX_SLOTS do
        local btn = Manager.buttons[slotIndex]
        if btn and btn.SlotFrame then
            local has = A and A.SlotHasAssignment and A.SlotHasAssignment(slotIndex)
            local want = has or showEmpty or ShouldForceShow()
            local shown = btn.SlotFrame:IsShown()
            if want and not shown then
                btn.SlotFrame:Show()
                if btn.Widget then
                    btn.Widget:Show()
                end
                changed = true
            elseif not want and shown then
                btn.SlotFrame:Hide()
                changed = true
            end
        end
    end
    if changed then
        RequestRelayout()
        if _G.FluxModifierTracker and _G.FluxModifierTracker.NotifyActiveChanged then
            _G.FluxModifierTracker.NotifyActiveChanged()
        end
    end
end

function Manager._DoUpdateAllSlots()
    if InCombatLockdown and InCombatLockdown() then
        Manager._pendingUpdate = true
        return
    end
    Manager.EnsureButtons()
    Manager.UpdateBindings()

    local A = Assign()
    local slots = A and A.GetSlots and A.GetSlots() or {}
    local showEmpty = Manager.ShouldShowEmptySlots()

    for slotIndex = 1, MAX_SLOTS do
        local btn = Manager.buttons[slotIndex]
        if btn then
            local slotData = slots[slotIndex]
            local has = A and A.SlotHasAssignment and A.SlotHasAssignment(slotIndex)
            if has then
                Manager.UpdateButton(btn, slotData)
                if btn.ClearPlaceholder then
                    btn:ClearPlaceholder()
                end
                if btn.WIcon then
                    btn.WIcon:Show()
                end
                if btn.WEmptyBG then
                    btn.WEmptyBG:Hide()
                end
                if btn.SlotFrame then
                    btn.SlotFrame:Show()
                end
                if btn.Widget then
                    btn.Widget:Show()
                end
            else
                btn.SlotData = nil
                ShowEmptySlot(btn)
                ApplyMacroAttributes(btn, nil)
                RefreshItemCount(btn, nil)
                RefreshChecked(btn, nil)
                Manager.UpdateHotkeys(btn)
                if showEmpty or ShouldForceShow() then
                    if btn.SlotFrame then
                        btn.SlotFrame:Show()
                    end
                elseif btn.SlotFrame then
                    btn.SlotFrame:Hide()
                end
            end
        end
    end
    RequestRelayout()
end

function Manager.UpdateAllSlots()
    if InCombatLockdown and InCombatLockdown() then
        Manager._pendingUpdate = true
        return
    end
    if Manager._updatePending then
        return
    end
    Manager._updatePending = true
    After(UPDATE_DEBOUNCE, function()
        Manager._updatePending = false
        Manager._DoUpdateAllSlots()
    end)
end

function Manager.UpdateBindings()
    if InCombatLockdown and InCombatLockdown() then
        Manager._pendingBindings = true
        return
    end
    Manager._pendingBindings = nil
    for slotIndex = 1, MAX_SLOTS do
        local btn = Manager.buttons[slotIndex]
        local secureBtn = btn and btn.Widget
        if secureBtn and secureBtn.GetName and secureBtn:GetName() then
            ClearOverrideBindings(secureBtn)
            local bindingName = BINDING_PREFIX .. slotIndex
            local key1, key2 = GetBindingKey(bindingName)
            if key1 then
                SetOverrideBindingClick(secureBtn, true, key1, secureBtn:GetName(), "KeyBind")
            end
            if key2 then
                SetOverrideBindingClick(secureBtn, true, key2, secureBtn:GetName(), "KeyBind")
            end
            Manager.UpdateHotkeys(btn)
        end
    end
end

-- Drag proximity watcher + spell/item count refresh events
local watch = CreateFrame("Frame")
watch:RegisterEvent("CURSOR_CHANGED")
watch:RegisterEvent("PLAYER_REGEN_ENABLED")
watch:RegisterEvent("UPDATE_BINDINGS")
watch:RegisterEvent("PLAYER_ENTERING_WORLD")
if C_TransmogOutfitInfo and C_TransmogOutfitInfo.GetOutfitsInfo then
    watch:RegisterEvent("TRANSMOG_OUTFITS_CHANGED")
    watch:RegisterEvent("TRANSMOG_DISPLAYED_OUTFIT_CHANGED")
end
-- No BAG_UPDATE_DELAYED: the FluxNCUtilitySlots inventory listener already
-- refreshes item counts, and registering both refreshed every slot twice.
watch:RegisterEvent("SPELL_UPDATE_CHARGES")
-- SPELLS_CHANGED rides the debounced, signature-gated Core bus (subscribed
-- below, after ScheduleCountRefresh exists); direct frame registration stays
-- only as fallback when the bus is missing.
if not (_G.Flux and _G.Flux.SpellBook and _G.Flux.SpellBook.OnChanged) then
    watch:RegisterEvent("SPELLS_CHANGED")
end
watch:RegisterEvent("BAG_UPDATE_COOLDOWN")
watch:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
watch:RegisterEvent("ACTIONBAR_UPDATE_STATE")
watch:RegisterEvent("COMPANION_UPDATE")
watch:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
if watch.RegisterUnitEvent then
    watch:RegisterUnitEvent("UNIT_PET", "player")
end
if FluxSafeRegisterEvent then
    FluxSafeRegisterEvent(watch, "PET_BAR_UPDATE")
end

local bindingPending = false
local countRefreshPending = false
local function ScheduleCountRefresh()
    if countRefreshPending then
        return
    end
    countRefreshPending = true
    After(0.05, function()
        countRefreshPending = false
        RefreshAllItemCounts()
    end)
end

if _G.Flux and _G.Flux.SpellBook and _G.Flux.SpellBook.OnChanged then
    _G.Flux.SpellBook.OnChanged("ncgrid.utilityslots", ScheduleCountRefresh)
end

local checkedRefreshPending = false
local function ScheduleCheckedRefresh()
    if checkedRefreshPending then
        return
    end
    checkedRefreshPending = true
    After(0.05, function()
        checkedRefreshPending = false
        RefreshAllChecked()
    end)
end

watch:SetScript("OnEvent", function(_, event)
    if event == "TRANSMOG_OUTFITS_CHANGED" or event == "TRANSMOG_DISPLAYED_OUTFIT_CHANGED" then
        Manager.UpdateAllSlots()
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if Manager._pendingUpdate then
            Manager._pendingUpdate = nil
            Manager.UpdateAllSlots()
        elseif Manager._pendingBindings then
            Manager.UpdateBindings()
        end
        return
    end
    if event == "UPDATE_BINDINGS" then
        if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
            and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
            return
        end
        if not bindingPending then
            bindingPending = true
            After(0.5, function()
                bindingPending = false
                if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
                    and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
                    return
                end
                Manager.UpdateBindings()
            end)
        end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        Manager.UpdateAllSlots()
        local SRM = _G.FluxSpellRankManager or _G.FluxSpellRankManagerModule
        if SRM and SRM.ApplyRankDesaturation then
            for i = 1, MAX_SLOTS do
                local btn = Manager.buttons[i]
                if btn then
                    local entry = select(1, ResolveDisplayEntry(Assign(), btn.slotIndex, btn.SlotData))
                    if entry and entry.type == "spell" and entry.id then
                        SRM:ApplyRankDesaturation(btn, entry.id)
                    elseif btn.SpellId then
                        SRM:ApplyRankDesaturation(btn, btn.SpellId)
                    end
                    if btn.UpdateUsable then
                        btn:UpdateUsable()
                    end
                end
            end
        end
        return
    end
    if event == "SPELL_UPDATE_CHARGES"
        or event == "SPELLS_CHANGED"
        or event == "BAG_UPDATE_COOLDOWN"
    then
        ScheduleCountRefresh()
        return
    end
    if event == "CURRENT_SPELL_CAST_CHANGED"
        or event == "ACTIONBAR_UPDATE_STATE"
        or event == "COMPANION_UPDATE"
        or event == "PLAYER_MOUNT_DISPLAY_CHANGED"
        or event == "PET_BAR_UPDATE"
        or event == "UNIT_PET"
    then
        -- Shapeshift / form / vehicle settle: skip checked refreshes from bar/pet/companion churn.
        if FluxButtonEvents and FluxButtonEvents.IsAnyBarStormActive
            and FluxButtonEvents.IsAnyBarStormActive()
            and (event == "ACTIONBAR_UPDATE_STATE"
                or event == "COMPANION_UPDATE"
                or event == "PET_BAR_UPDATE"
                or event == "UNIT_PET") then
            return
        end
        ScheduleCheckedRefresh()
        return
    end
    if event == "CURSOR_CHANGED" then
        Manager.UpdateVisibility()
        -- While dragging, poll mouse near-zone cheaply.
        local A = Assign()
        if A and A.HasAssignableCursor and A.HasAssignableCursor() then
            if not watch._polling then
                watch._polling = true
                watch:SetScript("OnUpdate", function(self, elapsed)
                    self._acc = (self._acc or 0) + elapsed
                    if self._acc < 0.1 then
                        return
                    end
                    self._acc = 0
                    if not (A.HasAssignableCursor and A.HasAssignableCursor()) then
                        self._polling = false
                        self:SetScript("OnUpdate", nil)
                        Manager.UpdateVisibility()
                        return
                    end
                    Manager.UpdateVisibility()
                end)
            end
        else
            watch._polling = false
            watch:SetScript("OnUpdate", nil)
            Manager.UpdateVisibility()
        end
    end
end)

-- FluxInv bag listener for item counts
local function RegisterInvListener()
    local inv = _G.FluxInv
    if not inv or not inv.RegisterListener or Manager._invHooked then
        return
    end
    Manager._invHooked = true
    inv.RegisterListener("FluxNCUtilitySlots", function()
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        for i = 1, MAX_SLOTS do
            local btn = Manager.buttons[i]
            if btn and btn.SlotData then
                RefreshItemCount(btn, btn.SlotData)
            end
        end
    end, { tier = "scan", regions = { "bags" }, sync = true })
end

After(0, RegisterInvListener)
After(1, RegisterInvListener)

-- Modifier chord → refresh stack count + checked + usable/desat for displayed entry.
local function RegisterModifierListener()
    local MT = _G.FluxModifierTracker
    if not MT or not MT.Register or Manager._modHooked then
        return
    end
    Manager._modHooked = true
    MT.Register("FluxNCUtilitySlots", function()
        for i = 1, MAX_SLOTS do
            local btn = Manager.buttons[i]
            if btn and btn.SlotData then
                if btn.TranslateMacro then
                    btn:TranslateMacro()
                elseif _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Action and _G.Flux.EBS.Action.TranslateMacro then
                    _G.Flux.EBS.Action.TranslateMacro(btn)
                end
            end
        end
        RefreshAllItemCounts()
        RefreshAllChecked()
        for i = 1, MAX_SLOTS do
            local btn = Manager.buttons[i]
            if btn and btn.SlotData then
                local entry = select(1, ResolveDisplayEntry(Assign(), btn.slotIndex, btn.SlotData))
                local SRM = _G.FluxSpellRankManager or _G.FluxSpellRankManagerModule
                if entry and entry.type == "spell" and entry.id and SRM and SRM.ApplyRankDesaturation then
                    SRM:ApplyRankDesaturation(btn, entry.id)
                elseif btn.SpellId and SRM and SRM.ApplyRankDesaturation then
                    SRM:ApplyRankDesaturation(btn, btn.SpellId)
                end
                if btn.UpdateUsable then
                    btn:UpdateUsable()
                elseif _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint and _G.Flux.EBS.Paint.UpdateUsable then
                    _G.Flux.EBS.Paint.UpdateUsable(btn)
                end
            end
        end
    end, {
        isActive = function()
            for i = 1, MAX_SLOTS do
                local btn = Manager.buttons[i]
                if btn and btn.SlotFrame and btn.SlotFrame:IsShown() then
                    return true
                end
            end
            return false
        end,
    })
end

After(0, RegisterModifierListener)
After(1, RegisterModifierListener)

-- Link Assign → Manager
local A = Assign()
if A then
    A.Manager = Manager
    A.OnSlotsChanged = function()
        Manager.UpdateAllSlots()
        local stance = _G.FluxStanceBar
        if stance and not InCombatLockdown() then
            pcall(function()
                if stance.RequestDedupRefresh then
                    stance:RequestDedupRefresh()
                elseif stance.UpdateLayout then
                    stance:UpdateLayout()
                end
            end)
        end
        if _G.FluxStanceBarOrderPanel_RequestRefresh then
            pcall(_G.FluxStanceBarOrderPanel_RequestRefresh)
        end
    end
end

_G.FluxNCUtilitySlotsManager = Manager
return Manager
