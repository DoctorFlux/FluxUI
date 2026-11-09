--[[ ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua — Inventory-backed ]]

FluxNCFood = FluxNCFood or {}
local Module = FluxNCFood

local PLACEHOLDER = "Interface\\Icons\\INV_Misc_Fork&Knife"
local USE_BINDING = "FLUXGRID_FOOD_OR_RECUP"
local CONJURE_BINDING = "FLUXMAGE_CONJURE_FOOD"

Module._preferRecuperate = false
Module._recuperateSpellIdCache = nil

local function EnsureCharFoodDB()
    -- True per-character SV (## SavedVariablesPerCharacter).
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end
    if type(_FluxUI_CharSavedVars.food) ~= "table" then
        _FluxUI_CharSavedVars.food = {}
    end
    return _FluxUI_CharSavedVars.food
end

local function MigratePreferFromAccountDB()
    local food = EnsureCharFoodDB()
    if food.preferRecuperate ~= nil then
        return
    end
    -- One-time migrate from older account-wide FluxNonCombatGridDB[charKey].food.
    if not FluxNonCombatGridDB then
        return
    end
    local charKey
    if _G.Flux and _G.Flux.PlayerName and _G.Flux.PlayerName.GetCharKey then
        charKey = _G.Flux.PlayerName.GetCharKey("hyphen")
    else
        local name = UnitName("player")
        local realm = GetRealmName()
        if name and realm then
            charKey = name .. "-" .. realm
        end
    end
    if not charKey then
        return
    end
    local charData = FluxNonCombatGridDB[charKey]
    local old = charData and charData.food and charData.food.preferRecuperate
    if old == nil and charData and charData.foodWater then
        old = charData.foodWater.preferRecuperate
    end
    if old ~= nil then
        food.preferRecuperate = old and true or false
    end
end

local function GetSpells()
    local inv = _G.FluxInv
    return inv and inv.Spells
end

local function ScanSpellbookForRecuperate()
    local matchID
    local function consider(spellID, name)
        spellID = tonumber(spellID)
        if not spellID or type(name) ~= "string" then
            return
        end
        if string.lower(name):find("recuper", 1, true) then
            matchID = spellID
        end
    end
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo then
        local num = C_SpellBook.GetNumSpellBookSkillLines()
        for i = 1, num or 0 do
            local line = C_SpellBook.GetSpellBookSkillLineInfo(i)
            if line and line.itemIndexOffset and line.numSpellBookItems then
                local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
                for slot = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
                    local info = C_SpellBook.GetSpellBookItemInfo and C_SpellBook.GetSpellBookItemInfo(slot, bank)
                    if info and info.spellID then
                        consider(info.spellID, info.name)
                        if matchID then
                            return matchID
                        end
                    end
                end
            end
        end
    end
    if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
        local tabs = GetNumSpellTabs() or 0
        for t = 1, tabs do
            local _, _, offset, numSpells = GetSpellTabInfo(t)
            offset = offset or 0
            numSpells = numSpells or 0
            for i = offset + 1, offset + numSpells do
                local name, _, spellID = GetSpellBookItemName(i, BOOKTYPE_SPELL or "spell")
                consider(spellID, name)
                if matchID then
                    return matchID
                end
            end
        end
    end
    return matchID
end

function Module.GetRecuperateSpellId()
    if Module._recuperateSpellIdCache then
        local id = Module._recuperateSpellIdCache
        if IsPlayerSpell and IsPlayerSpell(id) then
            return id
        end
        if IsSpellKnown and IsSpellKnown(id) then
            return id
        end
        Module._recuperateSpellIdCache = nil
    end
    local Spells = GetSpells()
    if Spells and Spells.IsKnownByName then
        local known, spellID = Spells.IsKnownByName("Recuperate")
        if known and spellID then
            Module._recuperateSpellIdCache = spellID
            return spellID
        end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, "Recuperate")
        if ok and type(info) == "table" and info.spellID then
            if (IsPlayerSpell and IsPlayerSpell(info.spellID)) or (IsSpellKnown and IsSpellKnown(info.spellID)) then
                Module._recuperateSpellIdCache = info.spellID
                return info.spellID
            end
        end
    end
    local scanned = ScanSpellbookForRecuperate()
    if scanned then
        Module._recuperateSpellIdCache = scanned
        return scanned
    end
    return nil
end

function Module.HasRecuperate()
    return Module.GetRecuperateSpellId() ~= nil
end

--- Default false = food button (not Recuperate). Per-character SV.
function Module.GetPreferRecuperate()
    MigratePreferFromAccountDB()
    local food = _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.food
    if food and food.preferRecuperate == true then
        return true
    end
    return false
end

function Module.SetPreferRecuperate(prefer)
    prefer = prefer and true or false
    Module._preferRecuperate = prefer
    local food = EnsureCharFoodDB()
    food.preferRecuperate = prefer
end

local function RefreshFoodAndWater()
    if Module.Update then
        Module.Update(true)
    end
    local Water = _G.FluxNCWater
    if Water and Water.Update then
        Water.Update(true)
    end
end

function Module.ToggleRecuperate()
    if not Module.HasRecuperate() then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    -- Secure toggle runs on mouse-down; OnMouseUp delete must not fire after food rebinds.
    local btn = Module._foodButton
    if btn then
        btn._fluxSkipNextMiddleDelete = true
    end
    Module.SetPreferRecuperate(not Module.GetPreferRecuperate())
    local Bridge = FluxEBSConsumableBridge
    local after = Bridge and Bridge.After or function(_, fn) fn() end
    after(0, RefreshFoodAndWater)
end

local function IsConjuredFoodOnButton(btn)
    local Bridge = FluxEBSConsumableBridge
    if not Bridge or not Bridge.IsConjured then
        return false
    end
    local itemID = Module._trackedItemID or (btn and btn.ItemId)
    if not itemID or (btn and btn.IsRecuperateMode) then
        return false
    end
    return Bridge.IsConjured(itemID) and true or false
end

local function ClearRightClickSpell(btn)
    local w = btn and btn.Widget
    if not w or (InCombatLockdown and InCombatLockdown()) then
        return
    end
    w:SetAttribute("type2", nil)
    w:SetAttribute("typerelease2", nil)
    w:SetAttribute("macrotext2", nil)
    w:SetAttribute("spell2", nil)
    w:SetAttribute("shift-type2", nil)
    w:SetAttribute("shift-typerelease2", nil)
    w:SetAttribute("shift-macrotext2", nil)
    w:SetAttribute("shift-spell2", nil)
end

local function WireRecuperateMiddleClick(btn)
    local Bridge = FluxEBSConsumableBridge
    local w = btn and btn.Widget
    if not w or (InCombatLockdown and InCombatLockdown()) then
        return
    end
    local P = _G.FluxMacroClickProxies
    local toggleMacro = (P and P.MACRO_FOOD_TOGGLE_RECUPERATE) or "/click FluxMacroProxy_FoodToggleRecuperate"
    local conjured = IsConjuredFoodOnButton(btn)

    -- Clear prior recuperate / middle secure attrs before rebinding.
    w:SetAttribute("type3", nil)
    w:SetAttribute("typerelease3", nil)
    w:SetAttribute("macrotext3", nil)
    w:SetAttribute("shift-type3", nil)
    w:SetAttribute("shift-typerelease3", nil)
    w:SetAttribute("shift-macrotext3", nil)

    if conjured then
        -- Middle = delete conjured; Shift+Middle = Recuperate toggle.
        btn._fluxRecuperateClickMode = "shift-middle"
        btn._fluxSkipMiddleNoUse = nil
        w:SetAttribute("shift-type3", "macro")
        w:SetAttribute("shift-typerelease3", "macro")
        w:SetAttribute("shift-macrotext3", toggleMacro)
        if Bridge and Bridge.ApplyMiddleClickNoUse then
            Bridge.ApplyMiddleClickNoUse(btn)
        end
    else
        -- Middle = Recuperate toggle.
        btn._fluxRecuperateClickMode = "middle"
        btn._fluxSkipMiddleNoUse = true
        w:SetAttribute("type3", "macro")
        w:SetAttribute("typerelease3", "macro")
        w:SetAttribute("macrotext3", toggleMacro)
    end
end

local function ClearRecuperateMiddleClick(btn)
    if not btn then
        return
    end
    btn._fluxRecuperateClickMode = nil
    local w = btn.Widget
    if not w or (InCombatLockdown and InCombatLockdown()) then
        return
    end
    -- Drop recuperate toggle attrs; restock / delete path rebinds below.
    w:SetAttribute("type3", nil)
    w:SetAttribute("typerelease3", nil)
    w:SetAttribute("macrotext3", nil)
    w:SetAttribute("shift-type3", nil)
    w:SetAttribute("shift-typerelease3", nil)
    w:SetAttribute("shift-macrotext3", nil)
end

local function AppendTooltip(btn, tip)
    local Bridge = FluxEBSConsumableBridge
    if not Bridge or not tip or not tip.AddLine then
        return
    end
    local face = Bridge.CombatSwapTooltipKind and Bridge.CombatSwapTooltipKind(btn, "food") or "food"
    if face == "healPotion" then
        Bridge.AppendTierStatusLines(tip, "healPotion", btn and btn.ItemId, btn)
        local ooc = "Food"
        if Module.HasRecuperate() and Module.GetPreferRecuperate() then
            ooc = "Recuperate"
        end
        tip:AddLine("Out of combat: " .. ooc, 0.65, 0.65, 0.65)
        return
    end
    if Module.HasRecuperate() then
        if Bridge._EnsureFluxTooltipGap then
            Bridge._EnsureFluxTooltipGap(tip)
        end
        if Module.GetPreferRecuperate() or (btn and btn.IsRecuperateMode) then
            tip:AddLine("Currently showing: Recuperate", 0.5, 1, 0.5)
        else
            tip:AddLine("Currently showing: Food", 0.5, 1, 0.5)
        end
        if IsConjuredFoodOnButton(btn) then
            tip:AddLine("Shift + Middle-click to toggle Recuperate", 1, 0.35, 0.35)
        else
            tip:AddLine("Middle-click to toggle Recuperate", 1, 0.35, 0.35)
        end
        -- Restock hint: only here when Recuperate mode skips AppendTierStatusLines below.
        if (btn and btn.IsRecuperateMode) and Bridge.AppendRestockEditHint then
            local mode = (btn and btn._fluxRestockEditClickMode) or "right"
            Bridge.AppendRestockEditHint(tip, "food", mode)
        end
    end
    -- Always show conjure lines when a conjure spell is known (including with Recuperate).
    do
        local primary, primaryID = Bridge.GetFoodConjureSpell()
        local secondary, secondaryID = Bridge.GetFoodSecondaryConjureSpell()
        if primaryID or primary then
            Bridge.AppendConjureSpellLines(tip, primaryID or primary, secondaryID or secondary, {
                bindingName = "FLUXMAGE_CONJURE_FOOD",
                ritualBindingName = "FLUXMAGE_RITUAL_OF_REFRESHMENT",
                -- Shift+Right edits the target; Ritual uses Ctrl+Right.
                secondaryModifier = "ctrl",
            })
        end
    end
    local itemID = Module._trackedItemID or btn.ItemId
    if not (btn and btn.IsRecuperateMode) then
        Bridge.AppendTierStatusLines(tip, "food", itemID, btn)
    end
    if btn and btn._fluxCombatSwapBody then
        tip:AddLine("In combat: Healing potion", 0.65, 0.65, 0.65)
    end
end

local function ApplyRC(btn)
    local Bridge = FluxEBSConsumableBridge
    local w = btn and btn.Widget
    if not w or (InCombatLockdown and InCombatLockdown()) then
        return
    end

    local primary, primaryID = Bridge.GetFoodConjureSpell()
    local secondary, secondaryID = Bridge.GetFoodSecondaryConjureSpell()
    local hasPrimary = (primaryID or primary) and true or false

    if Module.HasRecuperate() then
        -- Recuperate + conjure coexist:
        --   Right = conjure, Shift+Right = restock set, Ctrl+Right = secondary/Ritual,
        --   Middle = Recuperate toggle (Shift+Middle when conjured food is shown).
        if hasPrimary then
            Bridge.ApplyRightClickSpell(btn, primaryID or primary)
            Bridge.ApplyShiftRightClickSpell(btn, nil)
            if secondaryID or secondary then
                Bridge.ApplyCtrlRightClickSpell(btn, secondaryID or secondary)
            else
                Bridge.ApplyCtrlRightClickSpell(btn, nil)
            end
            Bridge.WireRestockEdit(btn, "food", { mode = "shift-right" })
        else
            ClearRightClickSpell(btn)
            Bridge.ApplyShiftRightClickSpell(btn, nil)
            Bridge.ApplyCtrlRightClickSpell(btn, nil)
            Bridge.WireRestockEdit(btn, "food", { mode = "right" })
        end
        WireRecuperateMiddleClick(btn)
        return
    end

    ClearRecuperateMiddleClick(btn)
    Bridge.ApplyCtrlRightClickSpell(btn, nil)
    if hasPrimary then
        Bridge.ApplyRightClickSpell(btn, primaryID or primary)
        Bridge.ApplyShiftRightClickSpell(btn, nil)
        if secondaryID or secondary then
            Bridge.ApplyCtrlRightClickSpell(btn, secondaryID or secondary)
        else
            Bridge.ApplyCtrlRightClickSpell(btn, nil)
        end
        Bridge.WireRestockEdit(btn, "food", { mode = "shift-right" })
    else
        Bridge.ApplyRightClickSpell(btn, nil)
        Bridge.ApplyShiftRightClickSpell(btn, nil)
        Bridge.WireRestockEdit(btn, "food", { mode = "right" })
    end
end

local function ApplyKeybinds(btn)
    local Bridge = FluxEBSConsumableBridge
    if not Bridge or not Bridge.ApplyUseAndConjureBindings then
        return
    end
    Bridge.ApplyUseAndConjureBindings(btn, USE_BINDING, {
        conjureBindingName = CONJURE_BINDING,
        canConjure = function()
            local name, id = Bridge.GetFoodConjureSpell()
            return (id or name) and true or false
        end,
    })
end

local function ShouldShow()
    local smart = true
    local EBV = _G.FluxExtraButtonVisibility
    if EBV and EBV.Apply then
        return EBV.Apply("nc_food", smart)
    end
    return smart
end

local function BindRecuperate(btn)
    local recuperateId = Module.GetRecuperateSpellId()
    if not recuperateId or not btn or not btn.SetAction then
        return false
    end
    if InCombatLockdown and InCombatLockdown() then
        Module._pendingUpdate = true
        return true
    end
    Module._trackedItemID = nil
    Module._latchItemID = nil
    Module._latchCount = nil
    btn.ItemId = nil
    btn.IsRecuperateMode = true
    btn._lastCountText = nil
    btn._lastUsable = nil
    btn._lastNoMana = nil
    btn._lastIconR, btn._lastIconG, btn._lastIconB = nil, nil, nil
    if btn.ClearPlaceholder then
        btn:ClearPlaceholder()
    end
    btn.PlaceholderTexture = nil
    btn.PlaceholderLabel = nil
    btn:SetAction("spell", recuperateId)
    if btn.WCount then
        btn.WCount:SetText("")
    end
    if btn.SetCount then
        btn:SetCount(nil)
    end
    if btn.FullRefresh then
        btn:FullRefresh()
    end
    ApplyRC(btn)
    ApplyKeybinds(btn)
    local Swap = FluxEBSConsumableBridge
    if Swap and Swap.ApplyCombatSwap then
        local result = Swap.ApplyCombatSwap(btn, "food", Module)
        if result == "restore" then
            ApplyRC(btn)
            ApplyKeybinds(btn)
        end
    end
    return true
end

function Module.Create(grid)
    local btn = grid:CreateButton({
        columnPriority = 4,
        columnGroup = "foodwater",
        order = 2,
        size = grid.ButtonSize,
    })
    if not btn then
        return
    end
    btn.IsFoodButton = true
    Module._foodButton = btn
    Module._preferRecuperate = Module.GetPreferRecuperate()

    FluxEBSButtonRefresh.Attach({
        module = Module,
        btn = btn,
        kind = "food",
        kindFlag = "IsFoodButton",
        placeholderIcon = PLACEHOLDER,
        placeholderLabel = "Food",
        listenerKey = "FluxNCFood",
        bindingName = USE_BINDING,
        middleClickDeleteConjured = true,
        shouldShow = ShouldShow,
        showTooltipExtras = AppendTooltip,
        applyRightClick = ApplyRC,
    })

    local baseUpdate = Module.Update
    function Module.Update(force)
        local prefer = Module.HasRecuperate() and Module.GetPreferRecuperate()
        local wasPrefer = Module._lastPreferRecuperate
        Module._lastPreferRecuperate = prefer and true or false
        if prefer then
            BindRecuperate(btn)
            -- Water combo bind only when Recuperate preference toggles on, not every food refresh.
            if force or wasPrefer ~= true then
                local Water = _G.FluxNCWater
                if Water and Water.Update then
                    Water.Update(force)
                end
            end
            return
        end
        local wasRecup = btn.IsRecuperateMode
        if btn.IsRecuperateMode then
            btn.IsRecuperateMode = false
        end
        if baseUpdate then
            baseUpdate(force)
        end
        -- Leaving Recuperate mode: water must drop combo and rebind pure water.
        if wasRecup then
            local Water = _G.FluxNCWater
            if Water and Water.Update then
                Water.Update(true)
            end
        end
    end

    function Module.UpdateKeybinding()
        ApplyKeybinds(btn)
    end

    ApplyRC(btn)
    ApplyKeybinds(btn)

    local function OnSpellBookChanged()
        Module._recuperateSpellIdCache = nil
        if InCombatLockdown and InCombatLockdown() then
            btn._pendingKeybindUpdate = true
            return
        end
        ApplyRC(btn)
        ApplyKeybinds(btn)
        if Module.Update then
            Module.Update(false)
        end
    end

    local bindEvents = CreateFrame("Frame")
    bindEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    bindEvents:RegisterEvent("UPDATE_BINDINGS")
    bindEvents:RegisterEvent("GROUP_ROSTER_UPDATE")
    -- SPELLS_CHANGED rides the debounced, signature-gated Core bus; the direct
    -- frame registration stays only as fallback when the bus is missing.
    do
        local SpellBook = _G.Flux and _G.Flux.SpellBook
        if SpellBook and SpellBook.OnChanged then
            SpellBook.OnChanged("ncgrid.food", OnSpellBookChanged)
        else
            bindEvents:RegisterEvent("SPELLS_CHANGED")
        end
    end
    bindEvents:SetScript("OnEvent", function(_, event)
        if event == "SPELLS_CHANGED" then
            -- Fallback path only (no Core SpellBook bus).
            OnSpellBookChanged()
            return
        end
        if event == "UPDATE_BINDINGS"
            and _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
            and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
            return
        end
        if event == "UPDATE_BINDINGS" then
            if bindEvents._bindRefreshPending then
                return
            end
            bindEvents._bindRefreshPending = true
            C_Timer.After(0.15, function()
                bindEvents._bindRefreshPending = false
                if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
                    and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
                    return
                end
                if InCombatLockdown and InCombatLockdown() then
                    btn._pendingKeybindUpdate = true
                    return
                end
                ApplyRC(btn)
                ApplyKeybinds(btn)
                if Module.Update then
                    Module.Update(false)
                end
            end)
            return
        end
        if InCombatLockdown and InCombatLockdown() then
            btn._pendingKeybindUpdate = true
            return
        end
        ApplyRC(btn)
        ApplyKeybinds(btn)
        -- PEW is owned by ConsumableBind (portal hold). Updating here on empty
        -- bags would SetPlaceholder / unload food for the load screen.
        if event ~= "PLAYER_ENTERING_WORLD" and Module.Update then
            Module.Update(false)
        end
    end)

    -- Cold login: spellbook often warms after first ApplyRC; PEW may not re-fire SPELLS_CHANGED.
    local function RetryConjureBind()
        if InCombatLockdown and InCombatLockdown() then
            btn._pendingKeybindUpdate = true
            return
        end
        ApplyRC(btn)
        ApplyKeybinds(btn)
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, RetryConjureBind)
        C_Timer.After(2.0, RetryConjureBind)
    end
    local inv = _G.FluxInv
    if inv and inv.RegisterListener then
        inv.RegisterListener("FluxNCFoodConjure", function(ctx)
            local regions = ctx and ctx.regions
            if regions and regions.spells then
                RetryConjureBind()
            end
        end, {
            tier = "light",
            regions = { "spells" },
            deferHeavy = true,
        })
    end
end

_G.FluxNCFood = Module
return Module
