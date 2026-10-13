-- FluxOptionsShell.lua
-- Sidebar options window. Pages are built one at a time from Ace option tables.
local _, ns = ...

local Shell = {}
ns.FluxOptionsShell = Shell
_G.FluxOptionsShell = Shell

local Catalog = ns.FluxOptionsCatalog
local Render = ns.FluxOptionsRender
local W = ns.FluxOptionsWidgets

local MIN_W, MIN_H = 860, 520
local DEFAULT_W, DEFAULT_H = 1000, 680
local SIDEBAR_W = 220
local TITLE_H = 40
local FOOTER_H = 40

local function PageEntry(pageId)
    return Catalog and Catalog.pages and Catalog.pages[pageId]
end

local function ShowCategoryTip(owner, title, body)
    if not owner or not body or body == "" then
        return
    end
    if W and W.ShowTooltip then
        W.ShowTooltip(owner, title or "", body)
    end
end

local function HideCategoryTip()
    if W and W.HideTooltip then
        W.HideTooltip()
    end
end

local function SubpageLabel(pageId, sub)
    local labels = Catalog and Catalog.subpageLabels and Catalog.subpageLabels[pageId]
    if labels and sub and labels[sub.key] then
        return labels[sub.key]
    end
    return sub and sub.name or ""
end

function Shell:IsShown()
    return self.frame and self.frame:IsShown() and true or false
end

function Shell:SetStatus(text)
    if self.status then
        self.status:SetText(text or "")
    end
end

function Shell:ApplyFluxBorder()
    local frame = self.frame
    if not frame or not FluxBorder or not FluxBorder.ApplyTo then
        return
    end
    if not frame.FluxBorderFrame then
        if frame.SetBackdrop then
            frame:SetBackdrop(nil)
        end
        FluxBorder:ApplyTo(frame, 0, 0, 0, 0)
        local bgFrame = frame.FluxBorderFrame and frame.FluxBorderFrame.BackgroundFrame
        if bgFrame then
            local level = frame:GetFrameLevel() or 1
            if level < 2 then
                frame:SetFrameLevel(2)
                level = 2
            end
            bgFrame:SetFrameStrata(frame:GetFrameStrata())
            bgFrame:SetFrameLevel(level - 1)
        end
    end
    if FluxBorder.SetClassColor then
        FluxBorder:SetClassColor(frame, 1, true)
    end
end

function Shell:ApplyAccent()
    self:ApplyFluxBorder()
    if W and W.RefreshAccent then
        W.RefreshAccent()
    end
    self:PaintSelection()
    self:PaintTabs()
end

function Shell:PaintSelection()
    if not self.navButtons then
        return
    end
    local r, g, b = W.Accent()
    for i = 1, #self.navButtons do
        local btn = self.navButtons[i]
        local selected = btn.pageId == self.pageId
        btn.selected = selected
        if selected then
            btn.bar:Show()
            W.Solid(btn.bar, r, g, b, 1)
            btn.label:SetTextColor(1, 1, 1)
            btn.icon:SetVertexColor(1, 1, 1)
            if btn.atlas and btn.atlas.SetAtlas and W.HasAtlas("Options_List_Active") then
                btn.atlas:SetAtlas("Options_List_Active")
                btn.atlas:Show()
            elseif btn.atlas then
                btn.atlas:Hide()
            end
        else
            btn.bar:Hide()
            btn.label:SetTextColor(0.78, 0.78, 0.78)
            btn.icon:SetVertexColor(0.75, 0.75, 0.75)
            if btn.atlas then
                btn.atlas:Hide()
            end
        end
    end
end

function Shell:PaintTabs()
    if not self.tabButtons then
        return
    end
    local r, g, b = W.Accent()
    for i = 1, #self.tabButtons do
        local btn = self.tabButtons[i]
        if btn:IsShown() and btn.SetBackdropColor then
            local selected = btn.subKey == self.subKey
            local hover = btn:IsMouseOver()
            if selected then
                btn:SetBackdropColor(r, g, b, 0.28)
                btn:SetBackdropBorderColor(r, g, b, 0.9)
                btn.label:SetTextColor(1, 1, 1)
                W.Solid(btn.underline, r, g, b, 1)
                btn.underline:Show()
            elseif hover then
                btn:SetBackdropColor(1, 1, 1, 0.10)
                btn:SetBackdropBorderColor(1, 1, 1, 0.22)
                btn.label:SetTextColor(0.95, 0.95, 0.95)
                btn.underline:Hide()
            else
                btn:SetBackdropColor(1, 1, 1, 0.045)
                btn:SetBackdropBorderColor(1, 1, 1, 0.10)
                btn.label:SetTextColor(0.72, 0.72, 0.72)
                btn.underline:Hide()
            end
        end
    end
end

function Shell:ContentWidth()
    if self.scrollApi then
        return self.scrollApi:GetContentWidth()
    end
    return 640
end

function Shell:ViewHeight()
    if self.scrollApi then
        return self.scrollApi:GetViewHeight()
    end
    return 400
end

function Shell:ReleaseCache()
    if not self.cache then
        return
    end
    for _, page in pairs(self.cache) do
        if page.Release then
            pcall(page.Release, page)
        end
    end
    wipe(self.cache)
    self.active = nil
end

local function CleanupHosts()
    if _G.FluxRestockPanel_OnOptionsClosed then
        pcall(_G.FluxRestockPanel_OnOptionsClosed)
    end
    if _G.FluxOptions_OnOptionsClosed then
        pcall(_G.FluxOptions_OnOptionsClosed)
    end
    if FluxMicroMenuConfigUI and FluxMicroMenuConfigUI.HideStandalone then
        FluxMicroMenuConfigUI:HideStandalone()
    end
    if FluxMinimapToMicro then
        FluxMinimapToMicro.isConfigShown = false
    end
    if W and W.CloseDropdown then
        W.CloseDropdown()
    end
end

function Shell:OnHidden()
    if self._hideGuard then
        return
    end
    self._hideGuard = true
    self:ReleaseCache()
    CleanupHosts()
    self._hideGuard = false
end

function Shell:Hide()
    if not self.frame or not self.frame:IsShown() then
        return
    end
    self.frame:Hide()
end

function Shell:Remember()
    self.lastPage = self.pageId
    self.lastSub = self.lastSub or {}
    if self.pageId then
        self.lastSub[self.pageId] = self.subKey
    end
end

function Shell:ResolveGroup(pageId)
    local entry = PageEntry(pageId)
    if not entry or not FluxOptions then
        return nil
    end
    if entry.profiles then
        if FluxOptions.GetProfilesOptions then
            return FluxOptions:GetProfilesOptions()
        end
        return nil
    end
    if FluxOptions.ResolveModuleOptions then
        return FluxOptions:ResolveModuleOptions(pageId)
    end
    return nil
end

function Shell:SubpagesFor(pageId, group)
    local subs = Render.ListSubpages(group)
    if not subs then
        return nil
    end
    for i = 1, #subs do
        subs[i].label = SubpageLabel(pageId, subs[i])
    end
    return subs
end

function Shell:Query()
    if not self.search then
        return ""
    end
    return string.lower(self.search:GetText() or "")
end

function Shell:PageMatches(pageId, query)
    if query == "" then
        return true
    end
    local entry = PageEntry(pageId)
    if not entry then
        return false
    end
    local blob = string.lower((entry.name or "") .. " " .. (entry.description or "") .. " " .. (entry.search or ""))
    if blob:find(query, 1, true) then
        return true
    end
    local group = self:ResolveGroup(pageId)
    local subs = self:SubpagesFor(pageId, group)
    if subs then
        for i = 1, #subs do
            local label = string.lower(subs[i].label or subs[i].name or "")
            if label:find(query, 1, true) then
                return true, subs[i].key
            end
        end
    end
    return false
end

function Shell:FilterSidebar()
    if not self.navButtons then
        return
    end
    local query = self:Query()
    local y = 0
    for i = 1, #self.navHeaders do
        self.navHeaders[i]:Hide()
    end
    local headerShown = {}
    for i = 1, #self.navButtons do
        local btn = self.navButtons[i]
        local match = self:PageMatches(btn.pageId, query)
        btn:SetShown(match)
        if match then
            headerShown[btn.groupId] = true
        end
    end
    for i = 1, #self.navFlow do
        local item = self.navFlow[i]
        if item.kind == "header" then
            if headerShown[item.groupId] then
                item.frame:Show()
                item.frame:ClearAllPoints()
                item.frame:SetPoint("TOPLEFT", self.navChild, "TOPLEFT", 0, y)
                item.frame:SetPoint("TOPRIGHT", self.navChild, "TOPRIGHT", 0, y)
                y = y - 22
            else
                item.frame:Hide()
            end
        elseif item.frame:IsShown() then
            item.frame:ClearAllPoints()
            item.frame:SetPoint("TOPLEFT", self.navChild, "TOPLEFT", 0, y)
            item.frame:SetPoint("TOPRIGHT", self.navChild, "TOPRIGHT", 0, y)
            y = y - 36
        end
    end
    self.navChild:SetHeight(math.max(1, -y))
    local view = self.navScroll:GetHeight() or 0
    local maxScroll = math.max(0, (-y) - view)
    self.navBar:SetMinMaxValues(0, maxScroll)
    if (self.navBar:GetValue() or 0) > maxScroll then
        self.navBar:SetValue(maxScroll)
    end
    self.navBar:SetShown(maxScroll > 1)
end

function Shell:LayoutTabs(subs)
    for i = 1, #self.tabButtons do
        self.tabButtons[i]:Hide()
    end
    if not subs or #subs == 0 then
        self.tabBar:Hide()
        self.tabBar:SetHeight(0.01)
        if self.tabRule then
            self.tabRule:Hide()
        end
        if self.scrollHost and self.content then
            self.scrollHost:ClearAllPoints()
            self.scrollHost:SetPoint("TOPLEFT", self.desc, "BOTTOMLEFT", 0, -8)
            self.scrollHost:SetPoint("BOTTOMRIGHT", self.content, "BOTTOMRIGHT", 0, 0)
        end
        return
    end
    self.tabBar:Show()
    self.tabBar:SetHeight(36)
    if self.tabRule then
        self.tabRule:Show()
    end
    if self.scrollHost and self.content then
        self.scrollHost:ClearAllPoints()
        self.scrollHost:SetPoint("TOPLEFT", self.tabBar, "BOTTOMLEFT", 0, -8)
        self.scrollHost:SetPoint("BOTTOMRIGHT", self.content, "BOTTOMRIGHT", 0, 0)
    end
    local x = 0
    local gap = 6
    for i = 1, #subs do
        local sub = subs[i]
        local btn = self.tabButtons[i]
        if not btn then
            local tmpl = BackdropTemplateMixin and "BackdropTemplate" or nil
            btn = CreateFrame("Button", nil, self.tabChild, tmpl)
            btn:SetHeight(28)
            W.ApplyBackdrop(btn, 1, 1, 1, 0.045, 1, 1, 1, 0.10)
            local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", 12, 0)
            label:SetPoint("RIGHT", -12, 0)
            label:SetJustifyH("CENTER")
            btn.label = label
            local line = btn:CreateTexture(nil, "OVERLAY")
            line:SetHeight(3)
            line:SetPoint("BOTTOMLEFT", 1, 1)
            line:SetPoint("BOTTOMRIGHT", -1, 1)
            line:Hide()
            btn.underline = line
            btn:SetScript("OnClick", function(selfBtn)
                Shell:Select(Shell.pageId, selfBtn.subKey, true)
            end)
            btn:SetScript("OnEnter", function(selfBtn)
                ShowCategoryTip(selfBtn, selfBtn.label:GetText(), selfBtn.tip)
                Shell:PaintTabs()
            end)
            btn:SetScript("OnLeave", function()
                HideCategoryTip()
                Shell:PaintTabs()
            end)
            self.tabButtons[i] = btn
        end
        btn.subKey = sub.key
        btn.tip = sub.desc
        btn.label:SetText(sub.label or sub.name)
        btn:Show()
        local textWidth = btn.label:GetStringWidth() or 40
        local w = math.max(72, textWidth + 28)
        btn:SetWidth(w)
        btn:ClearAllPoints()
        btn:SetPoint("LEFT", self.tabChild, "LEFT", x, -4)
        x = x + w + gap
    end
    self.tabChild:SetWidth(math.max(1, x))
    self:PaintTabs()
end

function Shell:ShowPage(pageId, subKey)
    local group = self:ResolveGroup(pageId)
    local entry = PageEntry(pageId)
    if not group then
        self.title:SetText(entry and entry.name or "FluxUI")
        self.desc:SetText("This page is not available yet.")
        self:LayoutTabs(nil)
        if self.active then
            self.active:Release()
            self.active = nil
        end
        return
    end

    local subs = self:SubpagesFor(pageId, group)
    if subs and #subs > 0 then
        local found = false
        if subKey then
            for i = 1, #subs do
                if subs[i].key == subKey then
                    found = true
                    break
                end
            end
        end
        if not found then
            local query = self:Query()
            subKey = nil
            if query ~= "" then
                for i = 1, #subs do
                    local label = string.lower(subs[i].label or subs[i].name or "")
                    if label:find(query, 1, true) then
                        subKey = subs[i].key
                        break
                    end
                end
            end
            if not subKey then
                local remembered = self.lastSub and self.lastSub[pageId]
                subKey = remembered or subs[1].key
            end
        end
    else
        subKey = nil
        subs = nil
    end

    self.pageId = pageId
    self.subKey = subKey
    self:Remember()
    self.title:SetText(entry and entry.name or group.name or pageId)
    self.desc:SetText(entry and entry.description or "")
    self:LayoutTabs(subs)
    self:PaintSelection()

    local renderGroup = group
    local path = {}
    if subKey and group.args and group.args[subKey] then
        renderGroup = group.args[subKey]
        path = { subKey }
    end

    local gen = 0
    if FluxOptions and FluxOptions.GetModuleGen and not (entry and entry.profiles) then
        gen = FluxOptions:GetModuleGen(pageId) or 0
    end
    local cacheKey = tostring(pageId) .. "\0" .. tostring(subKey or "") .. "\0" .. tostring(gen)

    self.cache = self.cache or {}
    for key, cached in pairs(self.cache) do
        if key ~= cacheKey and cached.SetActive then
            cached:SetActive(false)
        end
    end

    local page = self.cache[cacheKey]
    if not page or page.released then
        page = Render.Build(self.scrollApi.child, group, renderGroup, path, {
            pageId = pageId,
            advancedOpen = self.advancedOpen and self.advancedOpen[cacheKey],
            query = self:Query(),
            getWidth = function()
                return Shell:ContentWidth()
            end,
            getViewport = function()
                return Shell:ViewHeight()
            end,
        })
        page.onLayout = function(h)
            if Shell.scrollApi and Shell.active == page then
                Shell.scrollApi:SetContentHeight(h)
            end
        end
        self.cache[cacheKey] = page
    else
        page.query = self:Query()
    end
    self.active = page
    self.activeCacheKey = cacheKey
    if page.SetActive then
        page:SetActive(true)
    end
    page:Layout()
    self.advancedOpen = self.advancedOpen or {}
    self.advancedOpen[cacheKey] = page.advancedOpen
    if self.scrollApi.ResetScroll and self._resetScroll then
        self.scrollApi:ResetScroll()
        self._resetScroll = false
    end
end

function Shell:Select(pageId, subKey, keepScroll)
    if not PageEntry(pageId) then
        pageId = "general"
    end
    if not keepScroll then
        self._resetScroll = true
    end
    self:ShowPage(pageId, subKey)
    self:FilterSidebar()
end

function Shell:RefreshOpenPageNow()
    if not self:IsShown() or not self.pageId then
        return
    end
    local entry = PageEntry(self.pageId)
    local gen = 0
    if FluxOptions and FluxOptions.GetModuleGen and not (entry and entry.profiles) then
        gen = FluxOptions:GetModuleGen(self.pageId) or 0
    end
    local cacheKey = tostring(self.pageId) .. "\0" .. tostring(self.subKey or "") .. "\0" .. tostring(gen)
    if self.active and self.activeCacheKey ~= cacheKey then
        if self.cache[self.activeCacheKey] then
            self.cache[self.activeCacheKey]:Release()
            self.cache[self.activeCacheKey] = nil
        end
        self.active = nil
        self:ShowPage(self.pageId, self.subKey)
        return
    end
    if self.active then
        self.active.query = self:Query()
        self.active:Layout()
    end
    self:ApplyAccent()
end

function Shell:RefreshOpenPage()
    if self._refreshQueued then
        return
    end
    self._refreshQueued = true
    local function run()
        self._refreshQueued = false
        self:RefreshOpenPageNow()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

function Shell:Relayout()
    if self.navChild then
        self.navChild:SetWidth(math.max(40, (self.navScroll:GetWidth() or SIDEBAR_W) - 4))
    end
    self:FilterSidebar()
    if self.active then
        self.active:Layout()
    end
end

function Shell:BuildSidebar()
    self.navButtons = {}
    self.navHeaders = {}
    self.navFlow = {}
    local y = 0
    for g = 1, #Catalog.groups do
        local group = Catalog.groups[g]
        local header = CreateFrame("Frame", nil, self.navChild)
        header:SetHeight(22)
        local label = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        label:SetPoint("LEFT", 12, 0)
        label:SetText(string.upper(group.label or ""))
        label:SetTextColor(0.55, 0.55, 0.55)
        header:EnableMouse(true)
        header.tipTitle = group.label or ""
        header.tipBody = group.description or ""
        header:SetScript("OnEnter", function(selfHeader)
            ShowCategoryTip(selfHeader, selfHeader.tipTitle, selfHeader.tipBody)
        end)
        header:SetScript("OnLeave", HideCategoryTip)
        header:SetPoint("TOPLEFT", self.navChild, "TOPLEFT", 0, y)
        header:SetPoint("TOPRIGHT", self.navChild, "TOPRIGHT", 0, y)
        y = y - 22
        self.navHeaders[#self.navHeaders + 1] = header
        self.navFlow[#self.navFlow + 1] = { kind = "header", groupId = group.id, frame = header }

        for p = 1, #group.pages do
            local pageId = group.pages[p]
            local entry = PageEntry(pageId)
            if entry then
                local btn = CreateFrame("Button", nil, self.navChild)
                btn:SetHeight(36)
                btn.pageId = pageId
                btn.groupId = group.id

                local atlas = btn:CreateTexture(nil, "BACKGROUND")
                atlas:SetPoint("TOPLEFT", 0, 0)
                atlas:SetPoint("BOTTOMRIGHT", 0, 0)
                atlas:Hide()
                btn.atlas = atlas

                local hover = btn:CreateTexture(nil, "BACKGROUND")
                hover:SetAllPoints()
                W.Solid(hover, 1, 1, 1, 0.06)
                hover:Hide()
                btn.hover = hover

                local bar = btn:CreateTexture(nil, "ARTWORK")
                bar:SetWidth(3)
                bar:SetPoint("TOPLEFT", 0, -3)
                bar:SetPoint("BOTTOMLEFT", 0, 3)
                bar:Hide()
                btn.bar = bar

                local icon = btn:CreateTexture(nil, "ARTWORK")
                icon:SetSize(28, 28)
                icon:SetPoint("LEFT", 10, 0)
                icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                btn.icon = icon

                local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                text:SetPoint("LEFT", icon, "RIGHT", 8, 0)
                text:SetPoint("RIGHT", -8, 0)
                text:SetJustifyH("LEFT")
                text:SetWordWrap(false)
                text:SetText(entry.name or pageId)
                btn.label = text

                btn:SetPoint("TOPLEFT", self.navChild, "TOPLEFT", 0, y)
                btn:SetPoint("TOPRIGHT", self.navChild, "TOPRIGHT", 0, y)
                y = y - 36

                btn:SetScript("OnClick", function(selfBtn)
                    Shell._resetScroll = true
                    Shell:Select(selfBtn.pageId, nil, false)
                end)
                btn:SetScript("OnEnter", function(selfBtn)
                    selfBtn.hover:Show()
                    if selfBtn.atlas.SetAtlas and W.HasAtlas("Options_List_Hover") and selfBtn.pageId ~= Shell.pageId then
                        selfBtn.atlas:SetAtlas("Options_List_Hover")
                        selfBtn.atlas:Show()
                    end
                    local tipEntry = PageEntry(selfBtn.pageId)
                    ShowCategoryTip(selfBtn, tipEntry and tipEntry.name, tipEntry and tipEntry.description)
                end)
                btn:SetScript("OnLeave", function(selfBtn)
                    HideCategoryTip()
                    selfBtn.hover:Hide()
                    if selfBtn.pageId ~= Shell.pageId then
                        selfBtn.atlas:Hide()
                    end
                    Shell:PaintSelection()
                end)

                self.navButtons[#self.navButtons + 1] = btn
                self.navFlow[#self.navFlow + 1] = { kind = "page", groupId = group.id, frame = btn }
            end
        end
    end
    self.navChild:SetHeight(math.max(1, -y))
end

-- CloseWindows hides every UISpecialFrames entry when a center or fullscreen
-- panel opens (spellbook, talents, help, chat config). Stay off that list.
-- Escape still closes this window through the game-menu handler, or an
-- override binding on clients that do not have one.
local escapeInstalled = false
local escapeRegen

local function LeaveSpecialFrames()
    local list = UISpecialFrames
    if not list then
        return
    end
    for i = #list, 1, -1 do
        if list[i] == "FluxUIOptionsFrame" then
            table.remove(list, i)
        end
    end
end

--- After CloseAllWindows (AddOnPost). An earlier handler taints ToggleGameMenu
--- and the gamepad close then calls SetPreferredGamepadInteractTarget.
local function EscHandlerPriority()
    if not (RegisterGameMenuEscHandler and GameMenuEscPriority) then
        return nil
    end
    return GameMenuEscPriority.AddOnPost2 or GameMenuEscPriority.World
end

local function MenuOrDropdownTookEscape()
    if Menu and Menu.GetManager then
        local ok, manager = pcall(Menu.GetManager)
        if ok and manager and manager.HandleESC then
            local callOk, handled = pcall(manager.HandleESC, manager)
            if callOk and handled then
                return true
            end
        end
    end
    local list = _G.DropDownList1
    if list and list.IsShown and list:IsShown() then
        if CloseDropDownMenus then
            CloseDropDownMenus()
        elseif W and W.CloseDropdown then
            W.CloseDropdown()
        end
        return true
    end
    return false
end

local function BindEscapeClick(frame)
    if not frame or not SetOverrideBindingClick then
        return false
    end
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    local ok = pcall(SetOverrideBindingClick, frame, true, "ESCAPE", "FluxUIOptionsEscapeButton", "LeftButton")
    return ok
end

local function ClearEscapeClick(frame)
    if not frame or not ClearOverrideBindings then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    pcall(ClearOverrideBindings, frame)
end

local function ArmEscapeBinding(frame)
    if BindEscapeClick(frame) then
        return
    end
    if not (InCombatLockdown and InCombatLockdown()) then
        return
    end
    if not escapeRegen then
        escapeRegen = CreateFrame("Frame")
        escapeRegen:SetScript("OnEvent", function(self)
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            local shown = Shell.frame
            if shown and shown:IsShown() then
                BindEscapeClick(shown)
            end
        end)
    end
    escapeRegen:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local function DisarmEscapeBinding(frame)
    if escapeRegen then
        escapeRegen:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
    ClearEscapeClick(frame)
end

local function InstallEscapeClose(frame)
    LeaveSpecialFrames()
    if escapeInstalled then
        return
    end
    escapeInstalled = true
    local escPriority = EscHandlerPriority()
    if escPriority then
        RegisterGameMenuEscHandler(escPriority, function()
            if Shell.frame and Shell.frame:IsShown() then
                Shell.frame:Hide()
                return true
            end
            return false
        end)
        return
    end
    local button = CreateFrame("Button", "FluxUIOptionsEscapeButton", frame)
    button:SetSize(1, 1)
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    button:EnableMouse(false)
    button:SetScript("OnClick", function()
        if MenuOrDropdownTookEscape() then
            return
        end
        Shell:Hide()
    end)
    Shell._escapeBinding = true
end

function Shell:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", "FluxUIOptionsFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    frame:SetSize(DEFAULT_W, DEFAULT_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_W, MIN_H, 1600, 1100)
    else
        frame:SetMinResize(MIN_W, MIN_H)
        frame:SetMaxResize(1600, 1100)
    end
    self.frame = frame
    self:ApplyFluxBorder()
    if not frame.FluxBorderFrame then
        W.ApplyBackdrop(frame, 0.05, 0.06, 0.08, 0.98, 0.35, 0.35, 0.38, 1)
    end

    _G.FluxUIOptionsFrame = frame
    _G.FluxUIConfigFrame = frame
    InstallEscapeClose(frame)

    local sidebar = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
    sidebar:SetWidth(SIDEBAR_W)
    sidebar:SetPoint("TOPLEFT", 8, -TITLE_H)
    sidebar:SetPoint("BOTTOMLEFT", 8, FOOTER_H)
    W.ApplyBackdrop(sidebar, 0.03, 0.04, 0.05, 1, 1, 1, 1, 0.06)

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
    content:SetPoint("BOTTOMRIGHT", -8, FOOTER_H)

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -2)
    title:SetJustifyH("LEFT")
    title:SetText("FluxUI")
    self.title = title

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", content, "RIGHT", -4, 0)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(false)
    desc:SetTextColor(0.7, 0.7, 0.7)
    self.desc = desc

    local tabBar = CreateFrame("ScrollFrame", nil, content)
    tabBar:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -40)
    tabBar:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -40)
    tabBar:SetHeight(36)
    local tabRule = tabBar:CreateTexture(nil, "BORDER")
    tabRule:SetHeight(1)
    tabRule:SetPoint("BOTTOMLEFT", 0, 0)
    tabRule:SetPoint("BOTTOMRIGHT", 0, 0)
    W.Solid(tabRule, 1, 1, 1, 0.10)
    tabRule:Hide()
    self.tabRule = tabRule
    if tabBar.SetClipsChildren then
        tabBar:SetClipsChildren(true)
    end
    local tabChild = CreateFrame("Frame", nil, tabBar)
    tabChild:SetHeight(36)
    tabBar:SetScrollChild(tabChild)
    tabBar:EnableMouseWheel(true)
    tabBar:SetScript("OnMouseWheel", function(selfBar, delta)
        local childW = tabChild:GetWidth() or 0
        local view = selfBar:GetWidth() or 0
        local maxScroll = math.max(0, childW - view)
        local cur = selfBar:GetHorizontalScroll() or 0
        local nextScroll = math.max(0, math.min(maxScroll, cur - delta * 40))
        selfBar:SetHorizontalScroll(nextScroll)
    end)
    self.tabBar = tabBar
    self.tabChild = tabChild
    self.tabButtons = {}

    local scrollHost = CreateFrame("Frame", nil, content)
    scrollHost:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -4)
    scrollHost:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    self.scrollHost = scrollHost
    self.content = content
    self.scrollApi = W.CreateScroll(scrollHost)
    self.scrollApi.scroll:SetAllPoints(scrollHost)

    local search
    local searchOk
    searchOk, search = pcall(CreateFrame, "EditBox", "FluxUIOptionsSearch", frame, "SearchBoxTemplate")
    if not searchOk or not search then
        search = CreateFrame("EditBox", "FluxUIOptionsSearch", frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
        search:SetAutoFocus(false)
        search:SetFontObject(GameFontHighlightSmall)
        search:SetTextInsets(8, 8, 0, 0)
        if search.SetBackdrop then
            search:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            search:SetBackdropColor(0.02, 0.03, 0.04, 0.9)
            search:SetBackdropBorderColor(1, 1, 1, 0.16)
        end
    end
    search:SetSize(200, 22)
    search:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -10)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(selfBox)
        if searchOk and SearchBoxTemplate_OnTextChanged then
            pcall(SearchBoxTemplate_OnTextChanged, selfBox)
        end
        Shell:FilterSidebar()
        if Shell.active then
            Shell.active.query = Shell:Query()
            Shell.active:Layout()
        end
    end)
    search:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
        if selfBox:GetText() ~= "" then
            selfBox:SetText("")
        end
    end)
    self.search = search

    local drag = CreateFrame("Button", nil, frame)
    drag:SetPoint("TOPLEFT", 8, -4)
    drag:SetPoint("RIGHT", search, "LEFT", -8, 0)
    drag:SetHeight(28)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    drag:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)
    local windowTitle = drag:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    windowTitle:SetPoint("LEFT", 8, 0)
    windowTitle:SetText("FluxUI")

    local closeX = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeX:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeX:SetScript("OnClick", function()
        Shell:Hide()
    end)

    local status = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    status:SetPoint("BOTTOMLEFT", 16, 14)
    status:SetJustifyH("LEFT")
    status:SetTextColor(0.65, 0.65, 0.65)
    self.status = status

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(96, 22)
    closeBtn:SetPoint("BOTTOMRIGHT", -12, 10)
    closeBtn:SetText(CLOSE or "Close")
    closeBtn:SetScript("OnClick", function()
        Shell:Hide()
    end)
    status:SetPoint("RIGHT", closeBtn, "LEFT", -12, 0)

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        Shell:Relayout()
    end)

    local navScroll = CreateFrame("ScrollFrame", nil, sidebar)
    navScroll:SetPoint("TOPLEFT", 0, -4)
    navScroll:SetPoint("BOTTOMRIGHT", -12, 4)
    if navScroll.SetClipsChildren then
        navScroll:SetClipsChildren(true)
    end
    local navChild = CreateFrame("Frame", nil, navScroll)
    navChild:SetWidth(SIDEBAR_W - 16)
    navChild:SetHeight(1)
    navScroll:SetScrollChild(navChild)
    local navBar = CreateFrame("Slider", nil, sidebar)
    navBar:SetOrientation("VERTICAL")
    navBar:SetWidth(8)
    navBar:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -2, -8)
    navBar:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -2, 8)
    navBar:SetValueStep(1)
    navBar:SetMinMaxValues(0, 0)
    navBar:SetValue(0)
    local navThumb = navBar:CreateTexture(nil, "OVERLAY")
    navThumb:SetSize(8, 24)
    W.Solid(navThumb, 1, 1, 1, 0.27)
    navBar:SetThumbTexture(navThumb)
    navBar:SetScript("OnValueChanged", function(_, value)
        navScroll:SetVerticalScroll(value or 0)
    end)
    navScroll:EnableMouseWheel(true)
    navScroll:SetScript("OnMouseWheel", function(_, delta)
        local maxScroll = select(2, navBar:GetMinMaxValues())
        local nextValue = math.max(0, math.min(maxScroll or 0, (navBar:GetValue() or 0) - delta * 36))
        navBar:SetValue(nextValue)
    end)
    self.navScroll = navScroll
    self.navChild = navChild
    self.navBar = navBar

    self.frame = frame
    self.cache = {}
    self.lastSub = {}
    self.advancedOpen = {}
    self:BuildSidebar()

    frame:SetScript("OnHide", function()
        if Shell._escapeBinding then
            DisarmEscapeBinding(frame)
        end
        Shell:OnHidden()
    end)
    frame:SetScript("OnShow", function()
        if Shell._escapeBinding then
            ArmEscapeBinding(frame)
        end
        if FluxMinimapToMicro then
            FluxMinimapToMicro.isConfigShown = true
        end
        Shell:ApplyAccent()
        if FluxOptions and FluxOptions.GetConfigStatusText then
            Shell:SetStatus(FluxOptions:GetConfigStatusText())
        end
    end)
    frame:SetScript("OnSizeChanged", function()
        if Shell._sizeQueued then
            return
        end
        Shell._sizeQueued = true
        local function run()
            Shell._sizeQueued = false
            if Shell.frame and Shell.frame:IsShown() then
                Shell:Relayout()
            end
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, run)
        else
            run()
        end
    end)

    return frame
end

function Shell:Show(pageId, subKey)
    self:EnsureFrame()
    if pageId and pageId ~= "" then
        self.pageId = pageId
    end
    if not self.pageId then
        self.pageId = self.lastPage or "general"
    end
    if subKey and subKey ~= "" then
        self.subKey = subKey
    elseif pageId then
        self.subKey = nil
    end
    self.frame:Show()
    self._resetScroll = true
    self:Select(self.pageId, self.subKey, false)
    self:ApplyAccent()
    if FluxOptions and FluxOptions.GetConfigStatusText then
        self:SetStatus(FluxOptions:GetConfigStatusText())
    end
end

function Shell:Open(pageId, subKey)
    self:Show(pageId, subKey)
end
