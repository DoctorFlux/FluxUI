-- FluxChatCopyPaste.lua
-- Port of ChatCopyPaste (Novaspark/Venomisto) integrated into _FluxUI.
-- Settings: FluxOptions.db.global.chatCopyPaste (defaults in FluxOptionsDefaults).

local addonName, ns = ...
local GetCVar = GetCVar or C_CVar and C_CVar.GetCVar
local strmatch = string.match
local gmatch = string.gmatch
local gsub = string.gsub
local strsub = string.sub
local issecretvalue = issecretvalue

local function GetCCPDB()
    if FluxOptions and FluxOptions.db and FluxOptions.db.global then
        return FluxOptions.db.global.chatCopyPaste
    end
    return nil
end

FluxCCP = FluxCCP or {}

local function addBackdrop(template)
    if BackdropTemplateMixin then
        if template then
            return "BackdropTemplate," .. template
        end
        return "BackdropTemplate"
    end
    return template
end

local fluxCCPCopyFrame = CreateFrame("ScrollFrame", "FluxCCPCopyFrame", nil, addBackdrop("FluxCCP_InputScrollFrameTemplate"))
fluxCCPCopyFrame:Hide()
fluxCCPCopyFrame:SetToplevel(true)
fluxCCPCopyFrame:SetMovable(true)
fluxCCPCopyFrame:EnableMouse(true)
tinsert(UISpecialFrames, "FluxCCPCopyFrame")
fluxCCPCopyFrame:SetPoint("CENTER", UIParent, -100, 100)
fluxCCPCopyFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", insets = { top = 0, left = 0, bottom = 0, right = 0 } })
fluxCCPCopyFrame:SetBackdropColor(0, 0, 0, 0.5)
fluxCCPCopyFrame.CharCount:Hide()
fluxCCPCopyFrame:SetFrameLevel(129)
fluxCCPCopyFrame:SetFrameStrata("TOOLTIP")

local fluxCCPCopyFrameTopBar = CreateFrame("Frame", "FluxCCPCopyFrameTopBar", fluxCCPCopyFrame, "ThinGoldEdgeTemplate")
fluxCCPCopyFrameTopBar:SetPoint("TOP", -8, 22)
fluxCCPCopyFrameTopBar:SetWidth(100)
fluxCCPCopyFrameTopBar:SetHeight(18)
fluxCCPCopyFrameTopBar.fs = fluxCCPCopyFrameTopBar:CreateFontString("FluxCCPCopyFrameTopBarFS", "OVERLAY", "NumberFont_Shadow_Tiny")
fluxCCPCopyFrameTopBar.fs:SetText("Chat Copy Paste")
fluxCCPCopyFrameTopBar.fs:SetPoint("CENTER", 0, 0)
fluxCCPCopyFrameTopBar:SetMovable(true)
fluxCCPCopyFrameTopBar:EnableMouse(true)
fluxCCPCopyFrameTopBar:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self:GetParent().isMoving then
        self:GetParent():StartMoving()
        self:GetParent().isMoving = true
    end
end)
fluxCCPCopyFrameTopBar:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self:GetParent().isMoving then
        self:GetParent():StopMovingOrSizing()
        self:GetParent().isMoving = false
    end
end)
fluxCCPCopyFrameTopBar:SetScript("OnHide", function(self)
    if self:GetParent().isMoving then
        self:GetParent():StopMovingOrSizing()
        self:GetParent().isMoving = false
    end
end)

local fluxCCPCopyFrameCloseButton = CreateFrame("Button", "FluxCCPCopyFrameCloseButton", fluxCCPCopyFrame, "UIPanelCloseButton")
fluxCCPCopyFrameCloseButton:SetPoint("TOPRIGHT", 12, 27)
fluxCCPCopyFrameCloseButton:SetWidth(29)
fluxCCPCopyFrameCloseButton:SetHeight(29)
fluxCCPCopyFrameCloseButton:SetScript("OnClick", function()
    fluxCCPCopyFrame:Hide()
end)

local fluxCCPCopyFrameBottomButton = CreateFrame("Button", "FluxCCPCopyFrameBottomButton", fluxCCPCopyFrame, "UIPanelButtonTemplate")
fluxCCPCopyFrameBottomButton:SetPoint("BOTTOM", 0, -23)
fluxCCPCopyFrameBottomButton:SetWidth(80)
fluxCCPCopyFrameBottomButton:SetHeight(22)
fluxCCPCopyFrameBottomButton:SetText("Close")
fluxCCPCopyFrameBottomButton:SetNormalFontObject("GameFontNormalSmall")
fluxCCPCopyFrameBottomButton:SetScript("OnClick", function()
    fluxCCPCopyFrame:Hide()
end)
fluxCCPCopyFrameBottomButton:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self:GetParent().isMoving then
        self:GetParent():StartMoving()
        self:GetParent().isMoving = true
    end
end)
fluxCCPCopyFrameBottomButton:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self:GetParent().isMoving then
        self:GetParent():StopMovingOrSizing()
        self:GetParent().isMoving = false
    end
end)
fluxCCPCopyFrameBottomButton:SetScript("OnHide", function(self)
    if self:GetParent().isMoving then
        self:GetParent():StopMovingOrSizing()
        self:GetParent().isMoving = false
    end
end)

function FluxCCP.openFluxCCPCopyFrame(window, url)
    if not window then
        window = 1
    end
    local db = GetCCPDB()
    local maxLinesShown = (db and db.maxLinesShown) or 500

    fluxCCPCopyFrame:SetHeight(245)
    fluxCCPCopyFrame:SetWidth(400)
    fluxCCPCopyFrame.EditBox:SetFont("Fonts\\ARIALN.ttf", 10, "")
    fluxCCPCopyFrame.EditBox:SetFont("Fonts\\ARIALN.ttf", 11, "")
    fluxCCPCopyFrame.EditBox:SetText("")
    local hasSecretMsg
    if url then
        fluxCCPCopyFrame.EditBox:Insert(url)
        fluxCCPCopyFrame:SetHeight(45)
        fluxCCPCopyFrame.EditBox:HighlightText()
        fluxCCPCopyFrame.EditBox:SetFocus()
    else
        local chat = _G["ChatFrame" .. window]
        if not chat or not chat.GetNumMessages then
            return
        end
        local maxLines = chat:GetNumMessages() or 0
        local startLine = maxLines - maxLinesShown
        if startLine < 1 then
            startLine = 1
        end
        for i = startLine, maxLines do
            local isSecret
            local currentMsg, r, g, b, chatTypeID = chat:GetMessageInfo(i)
            if issecretvalue and issecretvalue(currentMsg) then
                isSecret = true
                hasSecretMsg = true
            end
            if not isSecret then
                local colorCode = false
                currentMsg = FluxCCP.removeChatJunk(currentMsg)
                if strmatch(currentMsg, "k:(%d+):(%d+):BN_WHISPER:") then
                    local presenceID = strmatch(currentMsg, "k:(%d+):%d+:BN_WHISPER:")
                    currentMsg = FluxCCP.createBnetString(presenceID, currentMsg)
                end
                if r and g and b and chatTypeID then
                    colorCode = RGBToColorCode(r, g, b)
                    currentMsg = gsub(currentMsg, "|r", "|r" .. colorCode)
                    currentMsg = colorCode .. currentMsg
                end
                if strmatch(currentMsg, "Guild Message of the Day: ") then
                    currentMsg = RGBTableToColorCode(ChatTypeInfo.GUILD) .. currentMsg
                end
                if i == 1 then
                    fluxCCPCopyFrame.EditBox:Insert(currentMsg .. "|r")
                else
                    fluxCCPCopyFrame.EditBox:Insert("\n" .. currentMsg .. "|r")
                end
            end
        end
    end
    fluxCCPCopyFrame.EditBox:SetWidth(fluxCCPCopyFrame:GetWidth() - 30)
    fluxCCPCopyFrameTopBar:SetWidth(fluxCCPCopyFrame:GetWidth() - 6)
    fluxCCPCopyFrame:Show()
    if url then
        fluxCCPCopyFrame.EditBox:SetFocus()
    end
    if hasSecretMsg then
        print("|cFFFFFFFFFluxUI Chat Copy:|r Some lines contained a Blizzard secret value and could not be copied.")
    end
end

function FluxCCP.createBnetString(id, msg)
    id = tonumber(id)
    local totalBNFriends = BNGetNumFriends()
    for friendIndex = 1, totalBNFriends do
        local presenceID, name, tag
        if C_BattleNet and C_BattleNet.GetFriendAccountInfo then
            local data = C_BattleNet.GetFriendAccountInfo(friendIndex)
            if data then
                presenceID = data.bnetAccountID
                name = data.accountName
                tag = data.battleTag
            end
        else
            presenceID, name, tag = BNGetFriendInfo(friendIndex)
        end
        if tag and id == presenceID then
            tag = strsplit("#", tag)
            return gsub(msg, "|HBNplayer:.*:.*:.*:BN_WHISPER:.*:", "[" .. tag .. "]:")
        end
    end
    return msg
end

function FluxCCP.removeChatJunk(currentMsg)
    if not currentMsg then
        return ""
    end
    local chatNumber = strmatch(currentMsg, "(%d+) |4year:years;")
    if chatNumber then
        if tonumber(number) == 0 then
            currentMsg = gsub(currentMsg, "(%d+) |4year:years;", chatNumber .. " year")
        elseif tonumber(chatNumber) > 1 then
            currentMsg = gsub(currentMsg, "(%d+) |4year:years;", chatNumber .. " years")
        end
    end
    chatNumber = strmatch(currentMsg, "(%d+) |4day:days;")
    if chatNumber then
        if tonumber(number) == 0 then
            currentMsg = gsub(currentMsg, "(%d+) |4day:days;", chatNumber .. " day")
        elseif tonumber(chatNumber) > 1 then
            currentMsg = gsub(currentMsg, "(%d+) |4day:days;", chatNumber .. " days")
        end
    end
    chatNumber = strmatch(currentMsg, "(%d+) |4hour:hours;")
    if chatNumber then
        if tonumber(number) == 0 then
            currentMsg = gsub(currentMsg, "(%d+) |4hour:hours;", chatNumber .. " hour")
        elseif tonumber(chatNumber) > 1 then
            currentMsg = gsub(currentMsg, "(%d+) |4hour:hours;", chatNumber .. " hours")
        end
    end
    chatNumber = strmatch(currentMsg, "(%d+) |4minute:minutes;")
    if chatNumber then
        if tonumber(number) == 0 then
            currentMsg = gsub(currentMsg, "(%d+) |4minute:minutes;", chatNumber .. " minute")
        elseif tonumber(chatNumber) > 1 then
            currentMsg = gsub(currentMsg, "(%d+) |4minute:minutes;", chatNumber .. " minutes")
        end
    end
    chatNumber = strmatch(currentMsg, "(%d+) |4second:seconds;")
    if chatNumber then
        if tonumber(number) == 0 then
            currentMsg = gsub(currentMsg, "(%d+) |4second:seconds;", chatNumber .. " second")
        elseif tonumber(chatNumber) > 1 then
            currentMsg = gsub(currentMsg, "(%d+) |4second:seconds;", chatNumber .. " seconds")
        end
    end
    currentMsg = gsub(currentMsg, "|T.-|t", "")
    return currentMsg
end

local MEDIA = "Interface\\AddOns\\_FluxUI\\Other\\Media\\"
local COPY_GLYPH = MEDIA .. "chat_copy.png"
local GUILD_GLYPH = MEDIA .. "chat_guild.png"
local GOLD_R, GOLD_G, GOLD_B = 1, 0.82, 0
local GEAR_ATLAS = {
    idle = "common-dropdown-a-button-settings-shadowless",
    over = "common-dropdown-a-button-settings-hover-shadowless",
    down = "common-dropdown-a-button-settings-pressed-shadowless",
    both = "common-dropdown-a-button-settings-pressedhover-shadowless",
}

local function AtlasOK(name)
    return name and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) and true or false
end

local function UseLayoutColumn(bf)
    return bf and bf.Layout and bf.upButton and bf.downButton and bf.bottomButton
end

local function SelectedChatWindowId()
    local selected = _G.GENERAL_CHAT_DOCK and _G.FCFDock_GetSelectedWindow and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
    local cf = selected or _G.ChatFrame1
    if cf and cf.GetID then
        local id = cf:GetID()
        if type(id) == "number" and id > 0 then
            return id
        end
    end
    return 1
end

local function SetStateArt(btn, which, atlas, file, desat, blend)
    if which == "Highlight" then
        if atlas and btn.SetHighlightAtlas then
            if blend then
                btn:SetHighlightAtlas(atlas, blend)
            else
                btn:SetHighlightAtlas(atlas)
            end
        elseif file then
            btn:SetHighlightTexture(file, blend)
        end
        return
    end
    local setAtlas = btn["Set" .. which .. "Atlas"]
    if atlas and setAtlas then
        setAtlas(btn, atlas)
        return
    end
    if file then
        btn["Set" .. which .. "Texture"](btn, file)
        local tex = btn["Get" .. which .. "Texture"](btn)
        if tex and desat and tex.SetDesaturated then
            tex:SetDesaturated(true)
        end
    end
end

local function DressPlate(btn)
    if AtlasOK("chatframe-button-up") and btn.SetNormalAtlas then
        btn:SetSize(27, 26)
        SetStateArt(btn, "Normal", "chatframe-button-up")
        SetStateArt(btn, "Pushed", "chatframe-button-down")
        SetStateArt(btn, "Highlight", "chatframe-button-highlight", nil, nil, "ADD")
        return true
    end
    btn:SetSize(32, 32)
    SetStateArt(btn, "Normal", nil, "Interface\\Buttons\\UI-SquareButton-Up", true)
    SetStateArt(btn, "Pushed", nil, "Interface\\Buttons\\UI-SquareButton-Down", true)
    SetStateArt(btn, "Highlight", nil, "Interface\\Buttons\\UI-Common-MouseHilight", nil, "ADD")
    if not btn._fluxInset then
        local inset = btn:CreateTexture(nil, "BACKGROUND")
        inset:SetColorTexture(0, 0, 0, 0.4)
        inset:SetAllPoints()
        btn._fluxInset = inset
    end
    return false
end

local function AttachGlyph(btn, file, w, h, tc, gold)
    local icon = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    icon:SetDrawLayer("OVERLAY", 7)
    icon:SetSize(w, h)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    if file and file:sub(1, 6) == "atlas:" then
        icon:SetAtlas(file:sub(7))
    else
        icon:SetTexture(file)
        if tc then
            icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
        end
    end
    if gold ~= false then
        icon:SetVertexColor(GOLD_R, GOLD_G, GOLD_B, 1)
    end
    btn._fluxGlyph = icon
    btn:HookScript("OnMouseDown", function(self, button)
        if button and button ~= "LeftButton" then
            return
        end
        self._fluxPushed = true
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", self, "CENTER", -1, -2)
        icon:SetAlpha(0.75)
    end)
    btn:HookScript("OnMouseUp", function(self)
        if not self._fluxPushed then
            return
        end
        self._fluxPushed = nil
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", self, "CENTER", 0, 0)
        icon:SetAlpha(1)
    end)
    btn:HookScript("OnHide", function(self)
        if not self._fluxPushed then
            return
        end
        self._fluxPushed = nil
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", self, "CENTER", 0, 0)
        icon:SetAlpha(1)
    end)
end

local function PaintGear(btn)
    local icon = btn._fluxGlyph
    if not icon then
        return
    end
    local atlas = (btn._fluxDown and btn._fluxOver and GEAR_ATLAS.both)
        or (btn._fluxOver and GEAR_ATLAS.over)
        or (btn._fluxDown and GEAR_ATLAS.down)
        or GEAR_ATLAS.idle
    if btn._fluxGearArt ~= atlas then
        btn._fluxGearArt = atlas
        icon:SetAtlas(atlas)
    end
end

local function HookTooltip(btn, title, lines)
    btn:HookScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if lines then
            for i = 1, #lines do
                GameTooltip:AddLine(lines[i], 0.8, 0.8, 0.8)
            end
        end
        GameTooltip:Show()
    end)
    btn:HookScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
end

local COLUMN_BUTTON_NAMES = {
    "FluxCCPChatGuildButton",
    "FluxCCPChatBagButton",
    "FluxCCPChatDurabilityButton",
    "FluxCCPChatCopyButton",
    "FluxCCPChatSettingsButton",
    "ChatFrameMenuButton",
    "ChatFrameChannelButton",
    "FriendsMicroButton",
}

--- Account-wide chat column toggles. Missing or true means shown.
local CHAT_BUTTON_DB_KEYS = {
    QuickJoinToastButton = "chat_btn_social",
    FriendsMicroButton = "chat_btn_social",
    ChatFrameChannelButton = "chat_btn_channel",
    FluxCCPChatGuildButton = "chat_btn_guild",
    FluxCCPChatBagButton = "chat_btn_bags",
    FluxCCPChatDurabilityButton = "chat_btn_durability",
    FluxCCPChatCopyButton = "chat_copy",
    FluxCCPChatSettingsButton = "chat_btn_options",
    ChatFrameMenuButton = "chat_btn_menu",
}

function FluxCCP.SocialChatButtonName()
    if _G.QuickJoinToastButton then
        return "QuickJoinToastButton"
    end
    if _G.FriendsMicroButton then
        return "FriendsMicroButton"
    end
    return nil
end

function FluxCCP.IsChatButtonEnabled(globalName)
    if globalName == "FriendsMicroButton" and FluxCCP.SocialChatButtonName() ~= "FriendsMicroButton" then
        return true
    end
    if globalName == "QuickJoinToastButton" and FluxCCP.SocialChatButtonName() ~= "QuickJoinToastButton" then
        return true
    end
    local key = CHAT_BUTTON_DB_KEYS[globalName]
    if not key then
        return true
    end
    local db = GetCCPDB()
    if not db then
        return true
    end
    return db[key] ~= false
end

local function ApplyChatButtonVisibility(btn, show)
    if not btn then
        return
    end
    if not btn._fluxChatOptHooked then
        btn._fluxChatOptHooked = true
        btn:HookScript("OnShow", function(self)
            if self._fluxChatOptHidden then
                if InCombatLockdown() and self.IsProtected and self:IsProtected() then
                    return
                end
                self:Hide()
            end
        end)
    end
    if InCombatLockdown() and btn.IsProtected and btn:IsProtected() then
        return
    end
    if show then
        btn._fluxChatOptHidden = nil
        btn.ignoreInLayout = nil
        btn:SetAlpha(1)
        btn:Show()
    else
        btn._fluxChatOptHidden = true
        btn.ignoreInLayout = true
        btn:Hide()
        btn:SetAlpha(0)
    end
end

local function DockChat()
    local dock = _G.GENERAL_CHAT_DOCK
    if dock and _G.FCFDock_GetSelectedWindow then
        local selected = FCFDock_GetSelectedWindow(dock)
        if selected and selected.buttonFrame then
            return selected
        end
    end
    return _G.ChatFrame1
end

local function HideOne(btn)
    if not btn then
        return
    end
    if not btn._fluxScrollHidden then
        btn._fluxScrollHidden = true
        btn:HookScript("OnShow", function(self)
            self:Hide()
        end)
    end
    btn:Hide()
    btn:SetAlpha(0)
end

local function HideScrollButtons(bf)
    if not bf then
        return
    end
    HideOne(bf.upButton)
    HideOne(bf.downButton)
    HideOne(bf.bottomButton)
end

local columnHolder

local function ColumnHolder()
    if not columnHolder then
        columnHolder = CreateFrame("Frame", "FluxCCPChatColumn", UIParent)
        columnHolder:SetSize(32, 32)
        columnHolder:SetFrameStrata("MEDIUM")
    end
    return columnHolder
end

--- Era is WOW_PROJECT_CLASSIC. Anniversary is WOW_PROJECT_BURNING_CRUSADE_CLASSIC
--- (Core/Client.lua). Both bottom-anchor the chat button strip. Reparenting those
--- buttons onto a holder loses to that strip's layout, so the raise never shows.
local function IsEraOrAnniversaryColumn()
    local client = (ns.Flux and ns.Flux.Client) or (_G.Flux and _G.Flux.Client)
    if client and (client.isEra or client.isAnniversary) then
        return true
    end
    if WOW_PROJECT_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        return true
    end
    if WOW_PROJECT_BURNING_CRUSADE_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        return true
    end
    return false
end

function FluxCCP.AttachColumnToDock()
    local holder = ColumnHolder()
    -- Era/Anniversary buttons stay on ChatFrame.buttonFrame. Moving that frame
    -- moves the column. Reparenting them leaves the visible strip where it was.
    if not IsEraOrAnniversaryColumn() then
        for i = 1, #COLUMN_BUTTON_NAMES do
            local btn = _G[COLUMN_BUTTON_NAMES[i]]
            if btn and btn.SetParent and btn:GetParent() ~= holder then
                btn:SetParent(holder)
            end
        end
    end
    local n = _G.NUM_CHAT_WINDOWS or 10
    for i = 1, n do
        local cf = _G["ChatFrame" .. i]
        if cf then
            if cf.buttonFrame then
                HideScrollButtons(cf.buttonFrame)
            end
            HideOne(cf.ScrollToBottomButton)
        end
    end
end

local columnLayoutQueued = false

local function QueueColumnLayout()
    if columnLayoutQueued then
        return
    end
    columnLayoutQueued = true
    local waiter = CreateFrame("Frame")
    waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
    waiter:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        columnLayoutQueued = false
        FluxCCP.PlaceColumnButtons()
    end)
end

local columnPlacing = false

local function ColumnScreenNum(v)
    if type(v) ~= "number" or (issecretvalue and issecretvalue(v)) then
        return nil
    end
    return v
end

--- Era and Anniversary: FCF_SetButtonSide anchors buttonFrame to Background
--- BOTTOM, so the column grows up from the edit box. The tab top sits about
--- 35px above the chat frame. Pin the strip a little above that so the social
--- button sits on the tab. Forever/live stay on Background TOP (y = -3).
local CLASSIC_BUTTON_FRAME_TOP = 55

function FluxCCP.PinClassicButtonFrame(chat)
    if not IsEraOrAnniversaryColumn() then
        return
    end
    chat = _G.ChatFrame1
    local bf = chat and chat.buttonFrame
    if not bf or not bf.ClearAllPoints or not bf.SetPoint then
        return
    end
    local side = "left"
    if _G.FCF_GetButtonSide then
        side = FCF_GetButtonSide(chat) or side
    end
    -- One point only. A leftover bottom anchor stretches this strip and drags
    -- the chat frame with it.
    bf:ClearAllPoints()
    if side == "right" then
        bf:SetPoint("TOPLEFT", chat, "TOPRIGHT", 3, CLASSIC_BUTTON_FRAME_TOP)
    else
        bf:SetPoint("TOPRIGHT", chat, "TOPLEFT", -3, CLASSIC_BUTTON_FRAME_TOP)
    end
end

if type(FCF_SetButtonSide) == "function" and not FluxCCP._classicButtonSideHook then
    FluxCCP._classicButtonSideHook = true
    hooksecurefunc("FCF_SetButtonSide", function(chatFrame)
        if chatFrame == _G.ChatFrame1 then
            FluxCCP.PinClassicButtonFrame(chatFrame)
        end
    end)
end

local function ClassicColumnUsesTabTop()
    local forever = (WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT)
        or ns._isCamelotGameType == true
    return WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE and not forever
end

local function HookColumnLayout(bf)
    if not bf or bf._fluxColumnLayoutHook or not bf.Layout or not hooksecurefunc then
        return
    end
    bf._fluxColumnLayoutHook = true
    hooksecurefunc(bf, "Layout", function()
        if columnPlacing then
            return
        end
        FluxCCP.PlaceColumnButtons()
    end)
end

function FluxCCP.PlaceColumnButtons()
    if columnPlacing then
        return
    end
    if IsEraOrAnniversaryColumn() then
        columnPlacing = true
        local chat = _G.ChatFrame1
        pcall(function()
            FluxCCP.AttachColumnToDock()
            local bf = chat and chat.buttonFrame
            -- Scroll buttons sit at layoutIndex 1-3. If they stay in the
            -- layout they push Social down the strip.
            if bf then
                if bf.upButton then
                    bf.upButton.ignoreInLayout = true
                end
                if bf.downButton then
                    bf.downButton.ignoreInLayout = true
                end
                if bf.bottomButton then
                    bf.bottomButton.ignoreInLayout = true
                end
            end
            -- Bag and character are created on the column holder. Leaving them
            -- there takes them off the strip this client actually shows.
            if bf then
                for i = 1, #COLUMN_BUTTON_NAMES do
                    local btn = _G[COLUMN_BUTTON_NAMES[i]]
                    if btn and btn.SetParent and btn:GetParent() ~= bf then
                        if not (InCombatLockdown() and btn.IsProtected and btn:IsProtected()) then
                            btn:SetParent(bf)
                            if btn.Show and not btn._fluxChatOptHidden then
                                btn:Show()
                            end
                        end
                    end
                end
            end
            FluxCCP.PinClassicButtonFrame(chat)
            if bf and bf.Layout then
                bf:Layout()
            end
            if bf then
                HookColumnLayout(bf)
            end
        end)
        columnPlacing = false
        return
    end
    local durBtn = _G.FluxCCPChatDurabilityButton
    if InCombatLockdown() and durBtn and durBtn.IsProtected and durBtn:IsProtected() then
        QueueColumnLayout()
        return
    end
    columnPlacing = true
    FluxCCP.AttachColumnToDock()
    local chat = DockChat()
    local holder = ColumnHolder()
    local guildBtn = _G.FluxCCPChatGuildButton
    local durBtn = _G.FluxCCPChatDurabilityButton
    local copyBtn = _G.FluxCCPChatCopyButton
    local gear = _G.FluxCCPChatSettingsButton
    if not chat or (not guildBtn and not durBtn and not copyBtn and not gear) then
        columnPlacing = false
        return
    end
    local side = "left"
    if _G.FCF_GetButtonSide then
        side = FCF_GetButtonSide(chat) or side
    end
    local bg = chat.Background or chat
    -- ChatFrame.Background is a Texture. A protected child (the durability
    -- secure button) cannot be positioned through a parent anchored to a region.
    local bgKind = bg.GetObjectType and bg:GetObjectType()
    local bgIsRegion = bgKind == "Texture" or bgKind == "FontString" or bgKind == "MaskTexture" or bgKind == "Line"
    local anchor = bgIsRegion and chat or bg
    local x, y = 0, -4
    local chatTop = chat.GetTop and ColumnScreenNum(chat:GetTop())
    if bgIsRegion and bg.GetTop and chatTop then
        local bgTop = ColumnScreenNum(bg:GetTop())
        local chatLeft = ColumnScreenNum(chat:GetLeft())
        local edge = ColumnScreenNum((side == "right") and bg:GetRight() or bg:GetLeft())
        if bgTop and chatLeft and edge then
            x = edge - chatLeft
            if ClassicColumnUsesTabTop() then
                local tab = _G.ChatFrame1Tab
                local tabTop = tab and tab.GetTop and ColumnScreenNum(tab:GetTop())
                -- Holder top is chatTop + y. Match the tab top.
                y = tabTop and (tabTop - chatTop) or 32
            else
                y = (bgTop - chatTop) - 4
            end
        end
    elseif ClassicColumnUsesTabTop() then
        y = 32
    end
    holder:ClearAllPoints()
    if side == "right" then
        holder:SetPoint("TOPLEFT", anchor, bgIsRegion and "TOPLEFT" or "TOPRIGHT", x, y)
    else
        holder:SetPoint("TOPRIGHT", anchor, "TOPLEFT", x, y)
    end
    holder:Show()
    local stackFrom = holder
    local function Stack(btn, gap)
        if not btn or btn._fluxChatOptHidden then
            return
        end
        btn:ClearAllPoints()
        btn:SetPoint("TOP", stackFrom, stackFrom == holder and "TOP" or "BOTTOM", 0, stackFrom == holder and 0 or gap)
        stackFrom = btn
    end
    Stack(_G.FriendsMicroButton, 0)
    if _G.ChatFrameChannelButton and ChatFrameChannelButton:GetParent() == holder then
        Stack(ChatFrameChannelButton, 0)
    end
    Stack(guildBtn, 0)
    Stack(_G.FluxCCPChatBagButton, -4)
    Stack(durBtn, 0)
    Stack(copyBtn, -8)
    Stack(_G.ChatFrameMenuButton, 0)
    Stack(gear, 0)
    if chat.buttonFrame then
        HookColumnLayout(chat.buttonFrame)
    end
    columnPlacing = false
end

function FluxCCP:UpdateColumnButtons()
    if not _G.FluxCCPChatCopyButton then
        return
    end
    local socialName = FluxCCP.SocialChatButtonName()
    ApplyChatButtonVisibility(socialName and _G[socialName], FluxCCP.IsChatButtonEnabled(socialName or ""))
    ApplyChatButtonVisibility(_G.ChatFrameChannelButton, FluxCCP.IsChatButtonEnabled("ChatFrameChannelButton"))
    ApplyChatButtonVisibility(_G.FluxCCPChatGuildButton, FluxCCP.IsChatButtonEnabled("FluxCCPChatGuildButton"))
    ApplyChatButtonVisibility(_G.FluxCCPChatBagButton, FluxCCP.IsChatButtonEnabled("FluxCCPChatBagButton"))
    ApplyChatButtonVisibility(_G.FluxCCPChatDurabilityButton, FluxCCP.IsChatButtonEnabled("FluxCCPChatDurabilityButton"))
    ApplyChatButtonVisibility(_G.FluxCCPChatCopyButton, FluxCCP.IsChatButtonEnabled("FluxCCPChatCopyButton"))
    ApplyChatButtonVisibility(_G.FluxCCPChatSettingsButton, FluxCCP.IsChatButtonEnabled("FluxCCPChatSettingsButton"))
    ApplyChatButtonVisibility(_G.ChatFrameMenuButton, FluxCCP.IsChatButtonEnabled("ChatFrameMenuButton"))
    if _G.FluxChatFrame_RefreshSocialLayout then
        FluxChatFrame_RefreshSocialLayout()
    end
    FluxCCP.PlaceColumnButtons()
end

local function OpenSettings(_, button)
    if not FluxOptions then
        return
    end
    if button == "RightButton" then
        FluxOptions:OpenBlizzardOptions()
    else
        FluxOptions:ToggleConfig()
    end
end

function FluxCCP:InstallColumnButtons()
    local chat = _G.ChatFrame1
    local bf = chat and chat.buttonFrame
    if not bf or _G.FluxCCPChatCopyButton then
        if bf and _G.FluxCCPChatCopyButton then
            FluxCCP.PlaceColumnButtons()
            FluxCCP:UpdateColumnButtons()
        end
        return
    end

    local function AddCount(btn)
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOP", btn, "BOTTOM", 0, 2)
        fs:SetTextColor(1, 1, 1, 1)
        return fs
    end

    local function CombatBlocked()
        if not InCombatLockdown() then
            return false
        end
        if UIErrorsFrame and ERR_NOT_IN_COMBAT then
            UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1, 0.3, 0.3, 1)
        end
        return true
    end

    local guildBtn = CreateFrame("Button", "FluxCCPChatGuildButton", bf)
    DressPlate(guildBtn)
    if AtlasOK("friends-icon-tab-guildmates") then
        AttachGlyph(guildBtn, "atlas:friends-icon-tab-guildmates", 17, 17, nil, false)
    else
        AttachGlyph(guildBtn, GUILD_GLYPH, 18, 18)
    end
    guildBtn:RegisterForClicks("LeftButtonUp")
    local guildCount = AddCount(guildBtn)
    guildCount:SetText("0")
    guildBtn:SetScript("OnClick", function()
        if CombatBlocked() then
            return
        end
        if ToggleGuildFrame then
            ToggleGuildFrame()
        end
    end)
    HookTooltip(guildBtn, "Guild")

    local function RequestGuildRoster()
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        if C_GuildInfo and C_GuildInfo.GuildRoster then
            C_GuildInfo.GuildRoster()
        elseif GuildRoster then
            GuildRoster()
        end
    end
    local function UpdateGuildCount()
        if not IsInGuild or not IsInGuild() then
            guildCount:SetText("0")
            return
        end
        local _, online = GetNumGuildMembers()
        if issecretvalue and issecretvalue(online) then
            return
        end
        guildCount:SetText(online or 0)
    end
    local guildEvents = CreateFrame("Frame")
    guildEvents:RegisterEvent("GUILD_ROSTER_UPDATE")
    guildEvents:RegisterEvent("PLAYER_GUILD_UPDATE")
    guildEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    guildEvents:SetScript("OnEvent", function(_, eventName)
        UpdateGuildCount()
        if eventName == "PLAYER_ENTERING_WORLD" then
            RequestGuildRoster()
        end
    end)
    guildBtn:HookScript("OnShow", function()
        RequestGuildRoster()
        UpdateGuildCount()
    end)
    guildBtn:HookScript("OnEnter", function()
        RequestGuildRoster()
        UpdateGuildCount()
    end)
    if guildBtn:IsShown() then
        RequestGuildRoster()
    end

    if FluxChatColumnMicros and FluxChatColumnMicros.Create then
        FluxChatColumnMicros.Create(ColumnHolder())
    end


    local copyBtn = CreateFrame("Button", "FluxCCPChatCopyButton", bf)
    DressPlate(copyBtn)
    AttachGlyph(copyBtn, COPY_GLYPH, 18, 18)
    copyBtn:RegisterForClicks("LeftButtonUp")
    copyBtn:SetScript("OnClick", function()
        local id = SelectedChatWindowId()
        if fluxCCPCopyFrame:IsVisible() then
            fluxCCPCopyFrame:Hide()
        else
            FluxCCP.openFluxCCPCopyFrame(id)
        end
    end)
    HookTooltip(copyBtn, "Copy Chat")

    local gear = CreateFrame("Button", "FluxCCPChatSettingsButton", bf)
    gear:RegisterForClicks("AnyUp")
    if AtlasOK(GEAR_ATLAS.idle) and gear.CreateTexture then
        gear:SetSize(27, 27)
        local icon = gear:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(gear)
        gear._fluxGlyph = icon
        PaintGear(gear)
        gear:HookScript("OnEnter", function(self)
            self._fluxOver = true
            PaintGear(self)
        end)
        gear:HookScript("OnLeave", function(self)
            self._fluxOver = nil
            PaintGear(self)
        end)
        gear:HookScript("OnMouseDown", function(self, button)
            if button and button ~= "LeftButton" and button ~= "RightButton" then
                return
            end
            self._fluxDown = true
            PaintGear(self)
        end)
        gear:HookScript("OnMouseUp", function(self)
            self._fluxDown = nil
            PaintGear(self)
        end)
        gear:HookScript("OnHide", function(self)
            self._fluxDown = nil
            PaintGear(self)
        end)
    else
        DressPlate(gear)
        AttachGlyph(gear, "Interface\\Icons\\INV_Misc_Gear_01", 18, 18)
    end
    gear:SetScript("OnClick", OpenSettings)
    HookTooltip(gear, "FluxUI Options", {
        " ",
        "|cffffffffLeft-Click|r Open FluxUI Options",
        "|cffffffffRight-Click|r Open Blizzard Settings",
    })

    local columnRestackPending = false
    local function Restack()
        if columnRestackPending then
            return
        end
        columnRestackPending = true
        local function run()
            columnRestackPending = false
            -- Chat's Edit Mode enter calls FCF_SelectDockFrame inside its pass.
            if FluxEditModeBusy and FluxEditModeBusy() then
                FluxAfterEditMode(run, "FluxCCPRestack")
                return
            end
            FluxCCP.PlaceColumnButtons()
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, run)
        else
            run()
        end
    end
    if _G.ChatFrameToggleVoiceDeafenButton and not ChatFrameToggleVoiceDeafenButton._fluxColumnHooked then
        ChatFrameToggleVoiceDeafenButton._fluxColumnHooked = true
        ChatFrameToggleVoiceDeafenButton:HookScript("OnShow", Restack)
        ChatFrameToggleVoiceDeafenButton:HookScript("OnHide", Restack)
    end
    if _G.ChatFrameToggleVoiceMuteButton and not ChatFrameToggleVoiceMuteButton._fluxColumnHooked then
        ChatFrameToggleVoiceMuteButton._fluxColumnHooked = true
        ChatFrameToggleVoiceMuteButton:HookScript("OnShow", Restack)
        ChatFrameToggleVoiceMuteButton:HookScript("OnHide", Restack)
    end
    if type(FCF_SetButtonSide) == "function" then
        hooksecurefunc("FCF_SetButtonSide", function(chatFrame)
            local dock = _G.GENERAL_CHAT_DOCK
            if chatFrame == ChatFrame1 or (dock and chatFrame and chatFrame.isDocked) then
                Restack()
            end
        end)
    end
    if type(FCF_SelectDockFrame) == "function" then
        hooksecurefunc("FCF_SelectDockFrame", Restack)
    end
    if type(FCFDock_SelectWindow) == "function" then
        hooksecurefunc("FCFDock_SelectWindow", function(dock)
            if dock == _G.GENERAL_CHAT_DOCK then
                Restack()
            end
        end)
    end
    if type(FCF_UpdateButtonSide) == "function" then
        hooksecurefunc("FCF_UpdateButtonSide", function(chatFrame)
            if chatFrame == ChatFrame1 then
                Restack()
            end
        end)
    end

    FluxCCP.PlaceColumnButtons()
    FluxCCP:UpdateColumnButtons()
end

local pewFrame = CreateFrame("Frame")
pewFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
pewFrame:SetScript("OnEvent", function()
    FluxCCP:InstallColumnButtons()
end)

local function hasEscapes(msg)
    if msg then
        local escapes = {
            ["|T.-|t"] = "",
            ["|H.-|h(.-)|h"] = "%1",
        }
        for k in pairs(escapes) do
            if strmatch(msg, k) then
                return true
            end
        end
    end
end

local urlColorCode = ""

function FluxCCP:loadUrlColor()
    local db = GetCCPDB()
    if not db then
        return
    end
    urlColorCode = "|cff" .. self:RGBToHex(db.chat_url_color_r, db.chat_url_color_g, db.chat_url_color_b)
end

local urlPattern = "[%w_.~!*:@&+$/?%%#-]-%w[-.%w]*%w%.%a%a+:?%d*/?"
local function parseMsg(msg)
    local ignored = {}
    for word in string.gmatch(msg, "%S+") do
        local match = string.match(word, urlPattern)
        if match and not hasEscapes(word) and not ignored[word] then
            local escaped = string.gsub(word, "([%(%)%%%+%-%*%?%[%^%$])", "%%%1")
            msg = string.gsub(msg, escaped, urlColorCode .. "(|HfluxccpCustomLink:url|h" .. word .. "|h)|r")
            ignored[word] = true
        end
    end
    return msg
end

function FluxCCP.fluxccpChatWebLinks(self, event, msg, author, ...)
    local db = GetCCPDB()
    if not db or not db.chat_url then
        return
    end
    if issecretvalue and issecretvalue(msg) then
        return
    end
    if not msg or msg == "" then
        return
    end
    -- Flux perf T3.4: chat filters run on every incoming line. The vast majority
    -- of messages contain neither a URL nor an MDT/WeakAuras payload, so the
    -- expensive urlPattern strmatch and parseMsg gsum loop are pure waste. Do
    -- cheap plain-find rejects first.
    if string.find(msg, "[MDT_v2:", 1, true) or string.find(msg, "[WeakAuras:", 1, true) then
        return
    end
    -- Cheap URL-presence heuristic: if none of these substrings appear, the
    -- urlPattern match cannot succeed either (URLs need a protocol/TLD).
    if not (string.find(msg, "http", 1, true)
            or string.find(msg, "www.", 1, true)
            or string.find(msg, ".com", 1, true)
            or string.find(msg, ".net", 1, true)
            or string.find(msg, ".org", 1, true)
            or string.find(msg, ".io",  1, true)
            or string.find(msg, ".tv",  1, true)
            or string.find(msg, ".gg",  1, true)) then
        return
    end
    -- Final authoritative check, identical to before.
    if not strmatch(msg, urlPattern) then
        return
    end
    msg = parseMsg(msg)
    return false, msg, author, ...
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", FluxCCP.fluxccpChatWebLinks)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", FluxCCP.fluxccpChatWebLinks)

local function openUrlFromLink(chatFrame, link, text, button)
    if link == "fluxccpCustomLink:url" then
        FluxCCP.createUrlLinkFrame(chatFrame, link, text, button)
    end
end

if type(ChatFrame_OnHyperlinkShow) == "function" then
    hooksecurefunc("ChatFrame_OnHyperlinkShow", function(chatFrame, link, text, button, ...)
        openUrlFromLink(chatFrame, link, text, button)
    end)
elseif type(SetItemRef) == "function" then
    hooksecurefunc("SetItemRef", function(link, text, button, chatFrame, ...)
        openUrlFromLink(chatFrame, link, text, button)
    end)
end

-- Prefix is 17 chars ("fluxccpCustomLink"); do not use 18 or ":" breaks the guard and Blizzard errors.
local FLUXCCP_CUSTOM_LINK_PREFIX = "fluxccpCustomLink"
local OriginalSetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(link, ...)
    if link and strsub(link, 1, #FLUXCCP_CUSTOM_LINK_PREFIX) == FLUXCCP_CUSTOM_LINK_PREFIX then
        return
    end
    return OriginalSetHyperlink(self, link, ...)
end

function FluxCCP.createUrlLinkFrame(chatFrame, link, text, button)
    FluxCCP.openFluxCCPCopyFrame(1, text)
end

function FluxCCP:updateChatOptions(value)
    local db = GetCCPDB()
    if not db then
        return
    end
    FluxCCP:UpdateColumnButtons()
    if db.chat_disable_fade then
        for j = 1, NUM_CHAT_WINDOWS do
            local f = _G["ChatFrame" .. j]
            if f and f.SetFading then
                f:SetFading(false)
            end
        end
    elseif value == "disablefade" then
        for j = 1, NUM_CHAT_WINDOWS do
            local f = _G["ChatFrame" .. j]
            if f and f.SetFading then
                f:SetFading(true)
            end
        end
    end
end

function FluxCCP:RGBToHex(r, g, b)
    r = tonumber(r)
    g = tonumber(g)
    b = tonumber(b)
    if r == math.floor(r) and g == math.floor(g) and b == math.floor(b) then
        r = r <= 255 and r >= 0 and r or 0
        g = g <= 255 and g >= 0 and g or 0
        b = b <= 255 and b >= 0 and b or 0
        return string.format("%02x%02x%02x", r, g, b)
    end
    return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, name)
    if event ~= "ADDON_LOADED" or name ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    FluxCCP:loadUrlColor()
    FluxCCP:updateChatOptions()
end)

