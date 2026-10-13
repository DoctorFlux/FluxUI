-- Binding/UI/SpellbookBindingHooks.lua
-- Spellbook entry points for FluxUI Options → Binding:
--   * Right-click a spell row → open Binding tab and select that spell
--   * "Flux bindings…" button at the top of the spellbook window

local ADDON_NAME = ...

local editorBtn

local function SpellbookEntryIsPassive(spellInfo)
    if not spellInfo then
        return false
    end
    local sid = spellInfo.spellID or spellInfo.actionID
    if type(sid) ~= "number" or sid <= 0 then
        return false
    end
    if C_Spell and C_Spell.IsSpellPassive then
        local ok, v = pcall(C_Spell.IsSpellPassive, sid)
        if ok and v then
            return true
        end
    end
    if IsPassiveSpell then
        local ok, v = pcall(IsPassiveSpell, sid)
        if ok and v then
            return true
        end
    end
    return false
end

local function BuildClassicSpellbookSpellInfo(spellButton)
    if not (SpellBookFrame and SpellBook_GetSpellBookSlot and spellButton and GetSpellBookItemName) then
        return nil
    end
    local slot, slotType, slotID = SpellBook_GetSpellBookSlot(spellButton)
    if not slot or not slotType then
        return nil
    end
    if slotType == "FUTURESPELL" or slotType == "FLYOUT" then
        return nil
    end
    if slotType ~= "SPELL" and slotType ~= "PETACTION" then
        return nil
    end

    local bookType = SpellBookFrame.bookType
    local nameSpellID
    local ok, _, _, sid = pcall(GetSpellBookItemName, slot, bookType)
    if ok then
        nameSpellID = sid
    end
    local spellID = nameSpellID or slotID
    if not spellID then
        return nil
    end
    if SpellbookEntryIsPassive({ spellID = spellID, actionID = slotID or spellID }) then
        return nil
    end

    local isPetBook = bookType == (BOOKTYPE_PET or "pet") or slotType == "PETACTION"
    local itemType
    if Enum and Enum.SpellBookItemType then
        itemType = isPetBook and Enum.SpellBookItemType.PetAction or Enum.SpellBookItemType.Spell
    end

    return {
        spellID = spellID,
        actionID = slotID or spellID,
        itemType = itemType,
        _fluxPetSpellbook = not not isPetBook,
        _fluxClassicSlotType = slotType,
    }
end

local function BuildSpellbookRowInfo(control)
    if not control then
        return nil
    end
    local parent = control:GetParent()
    if parent and parent.spellBookItemInfo and Enum and Enum.SpellBookItemType then
        local info = parent.spellBookItemInfo
        local it = info.itemType
        if it ~= Enum.SpellBookItemType.Spell and it ~= Enum.SpellBookItemType.PetAction then
            return nil
        end
        if not info.spellID then
            return nil
        end
        if SpellbookEntryIsPassive(info) then
            return nil
        end
        return {
            spellID = info.spellID,
            actionID = info.actionID or info.spellID,
            itemType = info.itemType,
            iconID = info.iconID,
            _fluxPetSpellbook = (it == Enum.SpellBookItemType.PetAction),
        }
    end
    return BuildClassicSpellbookSpellInfo(control)
end

local function OpenBindingEditorForSpell(spellInfo)
    if not spellInfo or SpellbookEntryIsPassive(spellInfo) then
        return
    end
    local open = _G.FluxSpellBindingEditor_Open or _G.FluxBindingEditor_Open
    if open then
        open(spellInfo)
    end
end

local function OpenBindingEditorPending()
    local open = _G.FluxSpellBindingEditor_Open or _G.FluxBindingEditor_Open
    if open then
        open(nil)
    end
end

--- Right-click: open FluxUI Options → Binding on that spell.
local function OpenSpellbookRowContextMenu(owner, spellInfo)
    if not owner or not spellInfo then
        return
    end
    if SpellbookEntryIsPassive(spellInfo) then
        return
    end
    OpenBindingEditorForSpell(spellInfo)
end

local function LocaleTip(key, fallback)
    local L = _G.FluxSpellBindingLocale
    if L and L[key] then
        return L[key]
    end
    return fallback
end

--- Append "Right-click to open in Flux Binding." after Blizzard fills the tip.
local function AppendSpellbookBindingTip(owner, spellInfo)
    if not owner or not spellInfo or SpellbookEntryIsPassive(spellInfo) then
        return
    end
    if not GameTooltip or not GameTooltip:IsShown() then
        return
    end
    -- Avoid stacking the line if both Button and row OnEnter fire.
    if GameTooltip.__FluxBindingRightClickTip then
        return
    end
    local tipOwner = GameTooltip:GetOwner()
    if tipOwner then
        local parent = owner.GetParent and owner:GetParent()
        local ok = tipOwner == owner
            or tipOwner == parent
            or (owner.Button and tipOwner == owner.Button)
            or (parent and parent.Button and tipOwner == parent.Button)
        if not ok then
            return
        end
    end
    local text = LocaleTip("spellbook_right_click_binding_tip", "Right-click to open in Flux Binding.")
    GameTooltip:AddLine(text, 0.9, 0.9, 0.9, true)
    GameTooltip.__FluxBindingRightClickTip = true
    GameTooltip:Show()
end

local function HookSpellbookBindingTip(frame, buildInfo)
    if not frame or frame.__FluxBindingTipHooked or not buildInfo then
        return
    end
    frame.__FluxBindingTipHooked = true
    frame:HookScript("OnEnter", function(self)
        local info = buildInfo(self)
        if not info or SpellbookEntryIsPassive(info) then
            return
        end
        local function apply()
            AppendSpellbookBindingTip(self, info)
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, apply)
        else
            apply()
        end
    end)
    frame:HookScript("OnLeave", function()
        if GameTooltip then
            GameTooltip.__FluxBindingRightClickTip = nil
        end
    end)
end

-- Left-click on PlayerSpells items runs Blizzard OnClick → OnIconClick →
-- CastSpellBookItem. Calling RegisterForClicks (or HookScript OnMouseUp/OnClick)
-- on that Blizzard button taints the hardware click, so the protected cast is
-- blamed on _FluxUI. Right-click binding is an addon overlay: LeftButton
-- passes through, RightButtonUp stays on the overlay.
local HookSpellbookButtons
local catcherCombatRetry

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function QueueCatcherRefresh()
    if catcherCombatRetry then
        return
    end
    catcherCombatRetry = true
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        catcherCombatRetry = nil
        HookSpellbookButtons()
    end)
end

local function EnsureRightClickCatcher(hitTarget, wantCatch, buildInfo)
    if not hitTarget or not buildInfo then
        return
    end

    local catcher = hitTarget.__FluxBindingCatcher
    if not catcher then
        catcher = CreateFrame("Button", nil, hitTarget)
        catcher:SetAllPoints(hitTarget)
        local level = hitTarget.GetFrameLevel and hitTarget:GetFrameLevel() or 0
        catcher:SetFrameLevel(level + 1)
        pcall(catcher.RegisterForClicks, catcher, "RightButtonUp")
        catcher:EnableMouse(false)
        local function ForwardScript(frame, script)
            if not frame or not frame.GetScript then
                return
            end
            local fn = frame:GetScript(script)
            if fn then
                fn(frame)
            end
        end
        catcher:SetScript("OnEnter", function(self)
            ForwardScript(self:GetParent(), "OnEnter")
        end)
        catcher:SetScript("OnLeave", function(self)
            ForwardScript(self:GetParent(), "OnLeave")
        end)
        catcher:SetScript("OnClick", function(self, mouseButton)
            if mouseButton ~= "RightButton" then
                return
            end
            local target = self:GetParent()
            if not target then
                return
            end
            local info = buildInfo(target)
            if not info then
                return
            end
            OpenSpellbookRowContextMenu(target, info)
        end)
        hitTarget.__FluxBindingCatcher = catcher
    end

    local function disable()
        catcher:EnableMouse(false)
    end

    if not wantCatch then
        disable()
        return
    end

    local info = buildInfo(hitTarget)
    if not info or SpellbookEntryIsPassive(info) then
        disable()
        return
    end

    -- SetPassThroughButtons / propagate are protected in combat. A catcher
    -- without passthrough would eat left clicks and block CastSpellBookItem.
    if InCombat() then
        disable()
        QueueCatcherRefresh()
        return
    end

    if not catcher.__FluxBindingCatcherConfigured then
        if catcher.SetPropagateMouseMotion then
            pcall(catcher.SetPropagateMouseMotion, catcher, true)
        end
        if catcher.SetPropagateMouseClicks then
            pcall(catcher.SetPropagateMouseClicks, catcher, false)
        end
        if not catcher.SetPassThroughButtons then
            disable()
            return
        end
        local ok = pcall(catcher.SetPassThroughButtons, catcher, "LeftButton", "MiddleButton", "Button4", "Button5")
        if not ok then
            disable()
            QueueCatcherRefresh()
            return
        end
        catcher.__FluxBindingCatcherConfigured = true
    end

    catcher:EnableMouse(true)
end

HookSpellbookButtons = function()
    local spellBookFrame = (PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame) or SpellBookFrame
    if not spellBookFrame then
        return
    end

    local function HookClassicSpellButton(spellBtn)
        if not spellBtn then
            return
        end
        local bt = SpellBookFrame and SpellBookFrame.bookType
        local playerBt = BOOKTYPE_SPELL or "spell"
        local petBt = BOOKTYPE_PET or "pet"
        local wantClicks = (bt == playerBt or bt == petBt)

        EnsureRightClickCatcher(spellBtn, wantClicks, BuildClassicSpellbookSpellInfo)
        if spellBtn.__FluxBindingEditorHooked then
            return
        end
        spellBtn.__FluxBindingEditorHooked = true
        HookSpellbookBindingTip(spellBtn, BuildClassicSpellbookSpellInfo)
    end

    local function HookModernSpellRow(spellBookItemFrame)
        if not spellBookItemFrame or not spellBookItemFrame.Button then
            return
        end
        local button = spellBookItemFrame.Button
        local wantClicks = Enum and Enum.SpellBookSpellBank
            and (spellBookItemFrame.spellBank == Enum.SpellBookSpellBank.Player
                or spellBookItemFrame.spellBank == Enum.SpellBookSpellBank.Pet)

        EnsureRightClickCatcher(button, wantClicks, BuildSpellbookRowInfo)
        if spellBookItemFrame.__FluxBindingEditorHooked then
            return
        end
        spellBookItemFrame.__FluxBindingEditorHooked = true
        -- Tip may be owned by the row frame or the Button; hook both with a shared builder.
        local function BuildModernTipInfo(frame)
            if frame and frame.Button then
                return BuildSpellbookRowInfo(frame.Button)
            end
            return BuildSpellbookRowInfo(frame)
        end
        HookSpellbookBindingTip(button, BuildSpellbookRowInfo)
        HookSpellbookBindingTip(spellBookItemFrame, BuildModernTipInfo)
    end

    local function HookOne(spellBookItemFrame)
        if not spellBookItemFrame then
            return
        end
        if spellBookItemFrame.Button then
            HookModernSpellRow(spellBookItemFrame)
            return
        end
        if SpellBook_GetSpellBookSlot then
            local nm = spellBookItemFrame.GetName and spellBookItemFrame:GetName()
            if nm and string.match(nm, "^SpellButton%d+$") then
                HookClassicSpellButton(spellBookItemFrame)
            end
        end
    end

    if spellBookFrame.ForEachDisplayedSpell then
        spellBookFrame:ForEachDisplayedSpell(HookOne)
    else
        for i = 1, 12 do
            local spellButton = _G["SpellButton" .. i]
            if spellButton then
                HookOne(spellButton)
            end
        end
    end
end

local function GetSpellBookFrame()
    if PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame then
        return PlayerSpellsFrame.SpellBookFrame, true
    end
    if SpellBookFrame then
        return SpellBookFrame, false
    end
    return nil, false
end

local function EnsureEditorButton()
    if editorBtn then
        return editorBtn
    end
    editorBtn = CreateFrame("Button", "FluxSpellBookBindingEditorBtn", UIParent, "UIPanelButtonTemplate")
    editorBtn:SetSize(120, 22)
    editorBtn:SetText("Flux bindings…")
    editorBtn:SetScript("OnClick", function()
        OpenBindingEditorPending()
    end)
    editorBtn:SetScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Flux bindings", 1, 1, 1)
        GameTooltip:AddLine("Open FluxUI Options → Binding.", 1, 0.82, 0, true)
        GameTooltip:AddLine("Right-click a spell to jump to that spell in the list.", 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    editorBtn:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    editorBtn:Hide()
    return editorBtn
end

local function PositionEditorButton()
    local btn = EnsureEditorButton()
    local book, isModern = GetSpellBookFrame()
    if not book or not book:IsShown() then
        btn:Hide()
        return
    end

    btn:SetParent(book)
    btn:ClearAllPoints()
    if isModern then
        -- Top of the modern Player Spells spellbook page.
        btn:SetPoint("TOPRIGHT", book, "TOPRIGHT", -28, -36)
    else
        -- Classic-style spellbook: sit on the top edge of the window.
        btn:SetPoint("BOTTOM", book, "TOP", 0, -26)
    end
    btn:SetFrameStrata("HIGH")
    btn:SetFrameLevel(book:GetFrameLevel() + 20)
    btn:Show()
end

local function OnSpellbookShow()
    HookSpellbookButtons()
    PositionEditorButton()
end

local function OnSpellbookHide()
    if editorBtn then
        editorBtn:Hide()
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

initFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_PlayerSpells" then
            C_Timer.After(0, function()
                local spellBookFrame = GetSpellBookFrame()
                local isShown = spellBookFrame
                    and ((PlayerSpellsFrame and PlayerSpellsFrame:IsShown())
                        or (SpellBookFrame and SpellBookFrame:IsShown()))
                if isShown then
                    OnSpellbookShow()
                end
            end)
        end
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if initFrame.__fluxBindingSpellbookHooks then
            return
        end
        initFrame.__fluxBindingSpellbookHooks = true

        local client = _G.Flux and _G.Flux.Client
        local forever = client and (client.isCamelot or client.isForever)
        if not forever then
            local api = _G.FLUX_API
            forever = api and (api.isCamelot or api.isForever)
        end
        if forever then
            local was = false
            local spellBookFrame = GetSpellBookFrame()
            if spellBookFrame and ((PlayerSpellsFrame and PlayerSpellsFrame:IsShown()) or (SpellBookFrame and SpellBookFrame:IsShown())) then
                was = true
                OnSpellbookShow()
            end
            local watch = CreateFrame("Frame")
            watch:SetScript("OnUpdate", function()
                local frame = GetSpellBookFrame()
                local shown = frame and ((PlayerSpellsFrame and PlayerSpellsFrame:IsShown()) or (SpellBookFrame and SpellBookFrame:IsShown()))
                shown = shown and true or false
                if shown == was then
                    return
                end
                was = shown
                if shown then
                    OnSpellbookShow()
                else
                    OnSpellbookHide()
                end
            end)
            return
        end

        if EventRegistry and EventRegistry.RegisterCallback then
            EventRegistry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.Show", OnSpellbookShow)
            EventRegistry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.Hide", OnSpellbookHide)
            EventRegistry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged", function()
                HookSpellbookButtons()
            end)
        end
        if SpellBookFrame then
            SpellBookFrame:HookScript("OnShow", OnSpellbookShow)
            SpellBookFrame:HookScript("OnHide", OnSpellbookHide)
        end

        local spellBookFrame = GetSpellBookFrame()
        local isShown = spellBookFrame
            and ((PlayerSpellsFrame and PlayerSpellsFrame:IsShown())
                or (SpellBookFrame and SpellBookFrame:IsShown()))
        if isShown then
            OnSpellbookShow()
        end
    end
end)

_G.FluxSpellbookBindingHooks_OpenForSpell = OpenBindingEditorForSpell
_G.FluxSpellbookBindingHooks_BuildRowInfo = BuildSpellbookRowInfo
