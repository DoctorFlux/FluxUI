-- Binding/UI/Editor/Chrome.lua
-- Toolbar (subject, binding instances, key capture, SHARED-KEY row) and the
-- per-form strip. The shared-key row is the fix for the old editor never
-- showing which spells / bar action share the chord.

local addonName, ns = ...

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI then return end

local Editor = ns.FluxBindingEditor
if not Editor then return end

local DB = ns.FluxBindingDB3
local Action = ns.FluxBindingAction
local Forms = ns.FluxBindingForms
local Conditions = ns.FluxBindingConditions
local S = Editor.S
local L = Editor.L

local function OnBarSelfLabel(kind, longForm)
    if kind == "item" then
        return longForm
            and (L["this item is on the bar"] or "this item is on the bar")
            or (L["this item"] or "this item")
    end
    if kind == "spell" then
        return longForm
            and (L["this spell is on the bar"] or "this spell is on the bar")
            or (L["this spell"] or "this spell")
    end
    return longForm
        and (L["this action is on the bar"] or "this action is on the bar")
        or (L["this action"] or "this action")
end

-- ---------------------------------------------------------------------------
-- Toolbar
-- ---------------------------------------------------------------------------

local function InstanceLabel(uid)
    local Placement = ns.FluxBindingPlacement
    if uid == 0 or uid == nil then
        -- Virtual: on bar/Extra with no Flux binding row yet.
        if S.placeId and Placement and Placement.LabelForPlaceId then
            local lab = Placement.LabelForPlaceId(S.placeId, S.preferChord)
            if lab then
                return lab
            end
        end
        if S.preferChord and S.preferChord ~= "" then
            return tostring(S.preferChord)
        end
        return L["UNBOUND"] or "UNBOUND"
    end
    local b = DB.Get(uid)
    if not b then return tostring(uid) end
    if b.key and b.key ~= "" then
        return b.key
    end
    if b.placeId and Placement and Placement.LabelForPlaceId then
        local lab = Placement.LabelForPlaceId(b.placeId, b.key or S.preferChord)
        if lab then
            return lab
        end
    end
    if b.placeId and tostring(b.placeId):match("^inst:") then
        return L["UNBOUND"] or "UNBOUND"
    end
    return L["UNBOUND"] or "UNBOUND"
end

function Editor.BuildToolbar(root)
    local binding = Editor.GetBinding()
    local showInstances = Editor.SupportsBindingInstances and Editor.SupportsBindingInstances()
    local showKey = not Editor.SupportsKeyEditor or Editor.SupportsKeyEditor()
    local showTabs = not Editor.SupportsBindingTabs or Editor.SupportsBindingTabs()

    local bar = AceGUI:Create("SimpleGroup")
    bar:SetLayout("Flow")
    bar:SetFullWidth(true)
    root:AddChild(bar)

    -- subject
    local icon = AceGUI:Create("Icon")
    icon:SetImage(Action.GetIcon(S.subject))
    icon:SetImageSize(28, 28)
    icon:SetWidth(36)
    icon:SetHeight(34)
    bar:AddChild(icon)

    local name = AceGUI:Create("Label")
    name:SetFontObject(GameFontNormalLarge)
    local subjectName = (Action.GetNameWithRank and Action.GetNameWithRank(S.subject))
        or Action.GetName(S.subject)
    if binding and Conditions.IsParked(binding) then
        subjectName = subjectName .. " |cffff4040(" .. (L["Spell not learned — binding disabled"] or "not available") .. ")|r"
    end
    name:SetText(subjectName)
    name:SetWidth(showInstances and 240 or 420)
    bar:AddChild(name)

    if showInstances then
        -- binding instance dropdown
        local dd = AceGUI:Create("FluxBlizzardDropdown") or AceGUI:Create("Dropdown")
        dd:SetLabel(L["Binding"] or "Binding")
        dd:SetWidth(200)
        local list, order = {}, {}
        local placeUid = S.placeId and DB.FindUidForPlace
            and DB.FindUidForPlace(S.subjectKey, S.placeId, S.preferChord)
        -- Virtual "on bar" entry when this place has no Flux row yet.
        if S.placeId and not placeUid and not tostring(S.placeId):match("^inst:") then
            list[0] = InstanceLabel(0)
            order[#order + 1] = 0
        end
        for _, uid in ipairs(S.uids or {}) do
            list[uid] = InstanceLabel(uid)
            order[#order + 1] = uid
        end
        if #order == 0 then
            list[0] = InstanceLabel(0)
            order[1] = 0
        end
        dd:SetList(list, order)
        dd:SetValue(S.currentUid or 0)
        dd:SetCallback("OnValueChanged", function(_, _, val)
            if val == 0 then
                S.currentUid = nil
                Editor.Redraw()
                return
            end
            S.currentUid = val
            local b = DB.Get(val)
            S.placeId = b and b.placeId or nil
            Editor.Redraw()
            -- Jump list selection to this instance when it has a placeId.
            local Browser = ns.FluxBindingBrowser
            if Browser and Browser.S and S.subjectKey and S.placeId then
                Browser.S.selectedKey = S.subjectKey .. "|" .. S.placeId
                if Browser.RefreshList then
                    Browser.RefreshList()
                end
            end
        end)
        bar:AddChild(dd)

        local addBtn = AceGUI:Create("Button")
        addBtn:SetText(L["Add binding"] or "Add binding")
        addBtn:SetWidth(110)
        addBtn:SetCallback("OnClick", function()
            Editor.AddInstance()
        end)
        bar:AddChild(addBtn)

        local delBtn = AceGUI:Create("Button")
        delBtn:SetText(L["Remove"] or "Remove")
        delBtn:SetWidth(90)
        delBtn:SetDisabled(not S.currentUid)
        delBtn:SetCallback("OnClick", function()
            Editor.RemoveInstance()
        end)
        bar:AddChild(delBtn)
    end

    if showTabs then
        -- Sticky across Respec profiles (survives Load/Apply).
        local sticky = AceGUI:Create("CheckBox")
        sticky:SetLabel(L["sticky_respec"] or "Sticky across Respec")
        sticky:SetValue(binding and binding.stickyRespec and true or false)
        sticky:SetWidth(180)
        sticky:SetCallback("OnValueChanged", function(_, _, val)
            local b = Editor.GetBinding() or (Editor.EnsureBindingRow and Editor.EnsureBindingRow())
            if not b then return end
            b.stickyRespec = val and true or false
            Editor.Commit()
        end)
        bar:AddChild(sticky)
    end

    if not showKey then
        -- Extra / stance: no Key row (Bindings.xml). Placement note is in Rebuild.
        return
    end

    -- key capture
    local keyRow = AceGUI:Create("SimpleGroup")
    keyRow:SetLayout("Flow")
    keyRow:SetFullWidth(true)
    root:AddChild(keyRow)

    local manualKey = binding and binding.key and binding.key ~= "" and binding.key or nil
    local inheritedKey = nil
    if not manualKey and Editor.GetInheritedChord then
        inheritedKey = Editor.GetInheritedChord()
    elseif not manualKey and S.preferChord and S.preferChord ~= "" then
        inheritedKey = S.preferChord
    end
    local displayKey = manualKey or inheritedKey or ""
    local isInherited = (not manualKey) and inheritedKey and inheritedKey ~= ""
    local keyLocked = Editor.IsExtraSystemKeyLocked and Editor.IsExtraSystemKeyLocked()

    local cap = AceGUI:Create("FluxKeyCapture") or AceGUI:Create("Keybinding")
    cap:SetLabel(L["Key"] or "Key")
    cap:SetWidth(260)
    cap:SetKey(displayKey)
    if cap.SetInherited then
        cap:SetInherited(isInherited or keyLocked)
    end
    if cap.SetLocked then
        cap:SetLocked(keyLocked)
    elseif keyLocked and cap.SetDisabled then
        cap:SetDisabled(true)
    end
    cap:SetCallback("OnKeyChanged", function(_, _, key)
        if Editor.IsExtraSystemKeyLocked and Editor.IsExtraSystemKeyLocked() then
            Editor.Redraw()
            return
        end
        local b = Editor.GetBinding()
        local hadManual = b and b.key and b.key ~= ""
        local inherited = (Editor.GetInheritedChord and Editor.GetInheritedChord())
            or S.preferChord
        local viewingInherited = (not hadManual) and inherited and inherited ~= ""

        if key == nil or key == "" then
            if hadManual and b then
                b.key = nil
                -- Commit prunes default unbound orphans and resets editor to not-bound
                -- (or place-inherited if still on bar / Extra / stance).
                Editor.Commit()
            end
            return
        end

        local nk = _G.FluxBinding and _G.FluxBinding.NormalizeChord and _G.FluxBinding.NormalizeChord(key)
            or key
        local ink = inherited and (_G.FluxBinding and _G.FluxBinding.NormalizeChord
            and _G.FluxBinding.NormalizeChord(inherited) or inherited)

        -- 1) Empty action-bar / Utility mod for this chord → place the spell/item
        --    there first and inherit that key (no Flux keybind row).
        local Placement = ns.FluxBindingPlacement
        if Placement and Placement.TryPlaceActionOnChord and S.subject then
            local placed = Placement.TryPlaceActionOnChord(S.subject, nk)
            if placed then
                S.placeId = placed.placeId
                S.preferChord = placed.chord or nk
                -- Drop unbound draft instance if we were editing one.
                if b and b.placeId and tostring(b.placeId):match("^inst:")
                    and (not b.key or b.key == "") then
                    local FB = _G.FluxBinding
                    if not (FB and FB.IsBindingRespecRelevant and FB.IsBindingRespecRelevant(b)) then
                        DB.Remove(b.uid)
                    end
                end
                local Browser = ns.FluxBindingBrowser
                if Browser and Browser.S and S.subjectKey and S.placeId then
                    Browser.S.selectedKey = S.subjectKey .. "|" .. S.placeId
                end
                -- Re-open as place-inherited (no Flux key) after the slot is filled.
                if Editor.OpenInHost and S.subject then
                    Editor.OpenInHost(S.subject, {
                        create = false,
                        placeId = placed.placeId,
                        preferChord = placed.chord or nk,
                        placeRole = S.placeRole,
                        placeSource = S.placeSource,
                    })
                end
                if Browser and Browser.RefreshList then
                    Browser.RefreshList()
                elseif Editor.Commit then
                    Editor.Commit()
                end
                return
            end
        end

        -- 2) No empty slot to claim → normal Flux keybind behavior.
        if viewingInherited then
            if ink and nk == ink then
                Editor.Redraw()
                return
            end
            Editor.AddInstance()
            b = Editor.GetBinding()
            if not b then return end
            b.key = nk
            Editor.Commit()
            return
        end

        b = b or (Editor.EnsureBindingRow and Editor.EnsureBindingRow())
        if not b then return end
        b.key = nk
        Editor.Commit()
    end)
    keyRow:AddChild(cap)

    local hint = AceGUI:Create("Label")
    if keyLocked then
        hint:SetText(L["extra_key_locked_hint"]
            or "Key comes from Flux Extra Bindings.xml — change it in Key Bindings, not here.")
    else
        hint:SetText(L["Click then press to bind — right-click clears. One key per binding slot."]
            or "Click then press to bind — right-click clears. One key per binding slot.")
    end
    hint:SetWidth(380)
    hint:SetFontObject(GameFontDisableSmall)
    keyRow:AddChild(hint)

    Editor.BuildSharedKeyRow(root, binding)
end

-- ---------------------------------------------------------------------------
-- Shared-key row
-- ---------------------------------------------------------------------------

function Editor.BuildSharedKeyRow(root, binding)
    if not binding then return end
    local FluxBinding = _G.FluxBinding
    if not FluxBinding or not FluxBinding.GetEditorOverlap then return end
    local info = FluxBinding.GetEditorOverlap(binding.action, binding.uid)
    if not info then return end

    local extras = info.multiCastExtras or {}
    local hosts = info.multiCastHosts or {}
    local hasPeers = info.native or (info.peers and #info.peers > 0)
    local hasMulti = #extras > 0 or #hosts > 0
    if not hasPeers and not hasMulti and not (info.route or info.chord) then
        return
    end

    local row = AceGUI:Create("SimpleGroup")
    row:SetLayout("List")
    row:SetFullWidth(true)
    root:AddChild(row)

    local parts = {}
    if info.source == "bar" and (not binding.key or binding.key == "") then
        parts[#parts + 1] = ("|cff9ecfffOn action bar under key |cffffffff%s|r (no Flux key)|r"):format(
            info.chord or "?")
    end
    if info.route and info.route.kind == "slot" then
        local rowName
        if info.route.row == "secondary" then
            rowName = L["minirow top-left (SHIFT)"] or "SHIFT mini"
        elseif info.route.row == "tertiary" then
            rowName = L["minirow top-right (CTRL)"] or "CTRL mini"
        else
            rowName = L["main row"] or "main row"
        end
        parts[#parts + 1] = ("|cff9ecfffColumn %d — %s%s|r"):format(
            info.route.col, rowName, info.slot and (" (slot " .. info.slot .. ")") or "")
        if info.native then
            if info.native.kind == "macro" then
                parts[#parts + 1] = "|cffff8000bar slot holds a game macro — not merged|r"
            elseif info.native.name then
                local onBar = info.subjectIsNative
                    and (" |cff40ff40(" .. OnBarSelfLabel(info.native.kind, true) .. ")|r")
                    or ""
                parts[#parts + 1] = ("bar: |cffffffff%s|r%s"):format(info.native.name, onBar)
            end
        else
            parts[#parts + 1] = "|cff808080" .. (L["empty bar slot"] or "empty bar slot") .. "|r"
        end
    elseif binding.key and binding.key ~= "" then
        parts[#parts + 1] = "|cff9ecfff" .. (L["Key bound — no action bar conflict."] or "No action bar conflict") .. "|r"
    end
    if #extras > 0 then
        parts[#parts + 1] = ("|cff9ecfff" .. (L["editor_banner_multicast_count"] or "Multi-cast: %d") .. "|r")
            :format(#extras)
    end
    if #hosts > 0 then
        parts[#parts + 1] = ("|cff9ecfff" .. (L["editor_banner_multicast_host_count"] or "Used as multi-cast on: %d") .. "|r")
            :format(#hosts)
    end

    if #parts > 0 then
        local routeLbl = AceGUI:Create("Label")
        routeLbl:SetFullWidth(true)
        routeLbl:SetText(table.concat(parts, "   •   "))
        routeLbl:SetFontObject(GameFontHighlightSmall)
        row:AddChild(routeLbl)
    end

    -- Shares key: icon strip (bar native + binding peers + multi-cast)
    local shareIcons = AceGUI:Create("SimpleGroup")
    shareIcons:SetLayout("Flow")
    shareIcons:SetFullWidth(true)
    row:AddChild(shareIcons)

    local shareLbl = AceGUI:Create("Label")
    shareLbl:SetText(L["editor_banner_shares_key_label"] or "Shares key:")
    shareLbl:SetWidth(90)
    shareLbl:SetFontObject(GameFontNormalSmall)
    shareIcons:AddChild(shareLbl)

    local function AddShareIcon(tex, tip, highlight, dim, openTarget)
        local ic = AceGUI:Create("Icon")
        ic:SetImage(tex or 134400)
        ic:SetImageSize(22, 22)
        ic:SetWidth(28)
        ic:SetHeight(26)
        if ic.image then
            if dim then
                ic.image:SetVertexColor(0.5, 0.5, 0.5, 0.7)
            elseif highlight then
                ic.image:SetVertexColor(1, 1, 0.7, 1)
            else
                ic.image:SetVertexColor(1, 1, 1, 1)
            end
        end
        local clickHint = (Editor.IsEmbedded and Editor.IsEmbedded())
            and (L["Click to select in list"] or "Click to select in list")
            or (L["Click to open binding editor"] or "Click to open binding editor")
        local clickTip = openTarget
            and ((tip or "?") .. "\n|cff808080" .. clickHint .. "|r")
            or tip
        ic:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            GameTooltip:SetText(clickTip or "?", nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        ic:SetCallback("OnLeave", function()
            GameTooltip:Hide()
        end)
        if openTarget then
            ic:SetCallback("OnClick", function()
                if Editor.OpenSharedPeer then
                    Editor.OpenSharedPeer(openTarget)
                elseif _G.FluxSpellBindingEditor_Open then
                    local act = type(openTarget) == "table" and (openTarget.action or openTarget) or openTarget
                    _G.FluxSpellBindingEditor_Open(act)
                end
            end)
        end
        shareIcons:AddChild(ic)
    end

    if info.native and info.native.kind ~= "macro" then
        local nativeAction
        if info.native.kind == "spell" and info.native.id then
            nativeAction = { type = "spell", id = info.native.id, name = info.native.name }
        elseif info.native.kind == "item" and info.native.id then
            nativeAction = { type = "item", id = info.native.id, name = info.native.name }
        end
        local nativeTarget
        if (not info.subjectIsNative) and nativeAction then
            nativeTarget = {
                action = nativeAction,
                placeId = info.slot and ("ab:" .. tostring(info.slot)) or nil,
                preferChord = info.chord,
            }
        end
        AddShareIcon(
            info.native.icon,
            (L["Action bar"] or "Action bar") .. ": " .. (info.native.name or "?")
                .. (info.subjectIsNative
                    and ("\n|cff40ff40(" .. OnBarSelfLabel(info.native.kind, true) .. ")|r")
                    or ""),
            info.subjectIsNative,
            false,
            nativeTarget)
    elseif info.native and info.native.kind == "macro" then
        AddShareIcon(134400, "Action bar: game macro (not merged)", false, true, nil)
    end

    local peerShown = 0
    for _, peer in ipairs(info.peers or {}) do
        local peerTarget
        if not peer.isSubject and peer.action then
            peerTarget = {
                action = peer.action,
                placeId = peer.placeId,
                uid = peer.uid,
                key = peer.key,
                preferChord = peer.key,
            }
        end
        AddShareIcon(
            peer.icon,
            (peer.isSubject and "|cffffd100(this binding)|r\n" or "")
                .. (peer.name or "?")
                .. (peer.available and "" or "\n|cff808080unavailable|r"),
            peer.isSubject,
            not peer.available,
            peerTarget)
        peerShown = peerShown + 1
    end

    for _, ex in ipairs(extras) do
        local tip = (L["multicast_share_extra_tip"] or "Multi-cast") .. ": " .. (ex.name or "?")
        if ex.hostName and ex.hostUid and binding and ex.hostUid ~= binding.uid then
            tip = tip .. "\n|cff9ecfff" .. (L["multicast_share_extra_on_fmt"] or "on %s"):format(ex.hostName) .. "|r"
        end
        if not ex.available then
            tip = tip .. "\n|cff808080" .. (L["multicast_extras_skipped"] or "skipped") .. "|r"
        end
        local exTarget
        if ex.action then
            local eb = DB and DB.FindBindingForMacroExtra and DB.FindBindingForMacroExtra({
                type = ex.type, id = ex.id, name = ex.name,
            }, ex.hostUid or (binding and binding.uid))
            exTarget = {
                action = ex.action,
                placeId = eb and eb.placeId,
                uid = eb and eb.uid,
                key = eb and eb.key,
            }
        end
        AddShareIcon(ex.icon, tip, false, not ex.available, exTarget)
        peerShown = peerShown + 1
    end

    for _, host in ipairs(hosts) do
        local tip = (L["multicast_share_host_tip"] or "Multi-cast host") .. ": " .. (host.name or "?")
        local hostTarget
        if host.action then
            hostTarget = {
                action = host.action,
                placeId = host.placeId,
                uid = host.uid,
                key = host.key,
            }
        end
        AddShareIcon(host.icon, tip, false, false, hostTarget)
        peerShown = peerShown + 1
    end

    if not info.native and peerShown <= 1 and #extras == 0 and #hosts == 0 then
        local alone = AceGUI:Create("Label")
        alone:SetText("|cff808080" .. (L["No other spells share this key."] or "No other spells share this key.") .. "|r")
        alone:SetFontObject(GameFontDisableSmall)
        alone:SetWidth(220)
        shareIcons:AddChild(alone)
    end
end

-- ---------------------------------------------------------------------------
-- Form strip
-- ---------------------------------------------------------------------------

function Editor.BuildFormStrip(root)
    if not Forms.HasMultipleForms() then return end
    local binding = Editor.GetBinding()
    if not binding then return end

    local strip = AceGUI:Create("SimpleGroup")
    strip:SetLayout("Flow")
    strip:SetFullWidth(true)
    root:AddChild(strip)

    local heading = AceGUI:Create("Label")
    heading:SetText(L["Form / Stance"] or "Form / Stance")
    heading:SetFontObject(GameFontNormal)
    heading:SetWidth(110)
    strip:AddChild(heading)

    for _, token in ipairs(Forms.GetTokens()) do
        local info = Forms.GetTokenInfo(token)
        local btn = AceGUI:Create("Icon")
        btn:SetImage(Forms.GetTokenIcon(token))
        btn:SetImageSize(22, 22)
        btn:SetWidth(30)
        btn:SetHeight(28)
        local isSelected = (S.formToken == token)
        local customActive = DB.IsCustomActiveForForm and DB.IsCustomActiveForForm(binding, token)
        local hasDedicated = DB.HasDedicatedFormSub(binding, token)
        local tip = (info and info.name or token)
        if customActive then
            tip = tip .. "\n|cff40ff40" .. (L["status_form_custom_binding"] or "Custom binding") .. "|r"
        elseif hasDedicated then
            tip = tip .. "\n|cff808080" .. (L["status_form_inactive_short"] or "Inactive") .. "|r"
        else
            tip = tip .. "\n|cff808080" .. (L["inherits No Form"] or "inherits No Form (inactive)") .. "|r"
        end
        tip = tip .. "\n|cff808080" .. (L["Click to edit this form"] or "Click to edit this form") .. "|r"
        btn:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            GameTooltip:SetText(tip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        btn:SetCallback("OnLeave", function()
            GameTooltip:Hide()
        end)
        btn:SetCallback("OnClick", function()
            S.formToken = token
            Editor.Redraw()
        end)
        if btn.image then
            btn.image:SetVertexColor(1, 1, 1, isSelected and 1 or (customActive and 0.85 or 0.4))
        end
        strip:AddChild(btn)
    end

    local cur = Forms.GetTokenInfo(S.formToken)
    local caption = AceGUI:Create("Label")
    caption:SetText((L["editor_editing_form_caption"] or "Editing: %s"):format(
        (cur and cur.name) or S.formToken or "No Form"))
    caption:SetFontObject(GameFontHighlightSmall)
    caption:SetWidth(200)
    strip:AddChild(caption)
end
