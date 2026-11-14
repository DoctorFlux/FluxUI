-- FluxOptionsShell.lua
-- Sidebar options window. Pages are built one at a time from Ace option tables.
local _, ns = ...

local Shell = {}
ns.FluxOptionsShell = Shell
_G.FluxOptionsShell = Shell

local Catalog = ns.FluxOptionsCatalog
local Render = ns.FluxOptionsRender
local W = ns.FluxOptionsWidgets
local Skin = ns.FluxOptionsSkin
local Navigation = ns.FluxOptionsNavigation

local MIN_W, MIN_H = 860, 520
local DEFAULT_W, DEFAULT_H = 1240, 780
local SIDEBAR_W = 220
local NAV_ROW_H, NAV_HEADER_H = 24, 18
local SYSTEM_ROW_H, SYSTEM_STEP = 22, 26
local TITLE_H = 76
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
    -- Retained entry point for appearance refresh callers. The options window
    -- now keeps the client's own border instead of the HUD's class tint.
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
    for i = 1, #self.navButtons do
        local btn = self.navButtons[i]
        local selected = btn.pageId == self.pageId and (not btn.subKey or btn.subKey == self.subKey)
        btn.selected = selected
        Skin.PaintNav(btn, selected, btn:IsMouseOver())
    end
end

function Shell:PaintTabs()
    if not self.tabButtons then
        return
    end
    for i = 1, #self.tabButtons do
        local btn = self.tabButtons[i]
        if btn:IsShown() then
            Skin.PaintTab(btn, btn.subKey == self.subKey)
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
    if Navigation then return Navigation.Resolve(pageId) end
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
    return string.lower((self.search:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function Shell:PageMatches(pageId, query)
    local entry = PageEntry(pageId)
    if not entry then
        return false
    end
    local group
    if entry.checkAvailability then
        group = self:ResolveGroup(pageId)
        if not group or (group.hidden and group.hidden()) then return false end
    end
    if query == "" then return true end
    group = group or self:ResolveGroup(pageId)
    if group and Render.Search then
        local count, subKey = Render.Search(group, query)
        if count > 0 then return true, subKey, count end
    end
    for _, tab in ipairs(entry.tabs or {}) do
        if tab.search and string.lower(tab.search):find(query, 1, true) then return true, tab.key end
    end
    local blob = string.lower((entry.name or "") .. " " .. (not entry.sidebarSubpages and entry.description or "") .. " " .. (entry.search or ""))
    if blob:find(query, 1, true) then
        return true
    end
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

function Shell:ContentQuery()
    local query = self:Query()
    if query == "" then return query end
    local entry = PageEntry(self.pageId)
    if entry and entry.wholePane and self:PageMatches(self.pageId, query) then return "" end
    if entry and string.lower(entry.name or ""):find(query, 1, true) then return "" end
    local group = self:ResolveGroup(self.pageId)
    local subs = self:SubpagesFor(self.pageId, group)
    for i = 1, #(subs or {}) do
        local sub = subs[i]
        if sub.key == self.subKey and string.lower(sub.label or sub.name or ""):find(query, 1, true) then
            return ""
        end
    end
    return query
end

function Shell:NavMatches(btn, query, pages)
    if not btn.subKey then return self:PageMatches(btn.pageId, query) end
    local data = pages[btn.pageId]
    if not data then
        local group = self:ResolveGroup(btn.pageId)
        data = { group = group, subs = {}, entry = PageEntry(btn.pageId) }
        for _, sub in ipairs(self:SubpagesFor(btn.pageId, group) or {}) do data.subs[sub.key] = sub end
        pages[btn.pageId] = data
    end
    local sub = data.subs[btn.subKey]
    if not sub then return false end
    if query == "" then return true, btn.subKey end
    local count = Render.Search(data.group.args[btn.subKey], query)
    local label = string.lower(sub.label or sub.name or "")
    local parent = string.lower(data.entry.name or "")
    return count > 0 or label:find(query, 1, true) ~= nil or parent:find(query, 1, true) ~= nil,
        btn.subKey, count > 0 and count or nil
end

function Shell:ToggleCategory(groupId)
    self.navCollapsed = self.navCollapsed or {}
    self.navCollapsed[groupId] = not self.navCollapsed[groupId]
    self:FilterSidebar(true)
end

function Shell:FilterSidebar(keepNavScroll)
    if not self.navButtons then
        return
    end
    local query = self:Query()
    local y = 0
    for i = 1, #self.navHeaders do
        self.navHeaders[i]:Hide()
    end
    local headerShown = {}
    local selectedTop
    local pages = {}
    for i = 1, #self.navButtons do
        local btn = self.navButtons[i]
        local match, subKey, count = self:NavMatches(btn, query, pages)
        btn.matchSub = subKey
        if btn.count then btn.count:SetText(query ~= "" and count and tostring(count) or "") end
        local collapsed = self.navCollapsed and self.navCollapsed[btn.groupId] and query == ""
        btn:SetShown(match and not collapsed)
        if match then
            headerShown[btn.groupId] = true
        end
    end
    for i = 1, #self.navFlow do
        local item = self.navFlow[i]
        if item.kind == "header" then
            if headerShown[item.groupId] then
                if y < 0 then y = y - 6 end
                item.frame:Show()
                if item.frame.indicator then
                    item.frame.indicator:SetText(self.navCollapsed and self.navCollapsed[item.groupId] and query == "" and "+" or "-")
                end
                item.frame:ClearAllPoints()
                item.frame:SetPoint("TOPLEFT", self.navChild, "TOPLEFT", 0, y)
                item.frame:SetPoint("TOPRIGHT", self.navChild, "TOPRIGHT", 0, y)
                y = y - NAV_HEADER_H - 4
            else
                item.frame:Hide()
            end
        elseif item.frame:IsShown() then
            item.frame:ClearAllPoints()
            item.frame:SetPoint("TOPLEFT", self.navChild, "TOPLEFT", 0, y)
            item.frame:SetPoint("TOPRIGHT", self.navChild, "TOPRIGHT", 0, y)
            if item.frame.selected then selectedTop = -y end
            y = y - NAV_ROW_H
        end
    end
    self.navChild:SetHeight(math.max(1, -y))
    local view = self.navScroll:GetHeight() or 0
    local maxScroll = math.max(0, (-y) - view)
    self.navBar:SetMinMaxValues(0, maxScroll)
    local offset = self.navBar:GetValue() or 0
    local desired = offset
    if selectedTop and view > 0 and not keepNavScroll then
        if selectedTop < desired then desired = selectedTop end
        if selectedTop + NAV_ROW_H > desired + view then desired = selectedTop + NAV_ROW_H - view end
    end
    desired = math.max(0, math.min(maxScroll, desired))
    if desired ~= offset then
        self.navBar:SetValue(desired)
    end
    self.navBar:SetShown(maxScroll > 1)
    local matches = 0
    for i = 1, #self.navButtons do
        if self.navButtons[i]:IsShown() then matches = matches + 1 end
    end
    if self.noResults then self.noResults:SetShown(matches == 0) end
end

function Shell:SearchChanged()
    self:FilterSidebar()
    local query = self:Query()
    if query ~= "" then
        local match, subKey = self:PageMatches(self.pageId, query)
        if not match then
            for i = 1, #self.navButtons do
                local btn = self.navButtons[i]
                if btn:IsShown() then
                    self:Select(btn.pageId, btn.matchSub, false)
                    return
                end
            end
        elseif subKey and subKey ~= self.subKey then
            self:Select(self.pageId, subKey, false)
            return
        end
    end
    if self.active then
        self.active.query = self:ContentQuery()
        self.active:Layout()
        self.scrollApi:ResetScroll()
    end
end

function Shell:LayoutTabs(subs)
    local entry = PageEntry(self.pageId)
    if entry and entry.sidebarSubpages then subs = nil end
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
            btn = Skin.CreateTab("FluxUIOptionsTab" .. i, self.tabChild)
            btn:SetID(i)
            btn:SetScript("OnClick", function(selfBtn)
                Shell:Select(Shell.pageId, selfBtn.subKey, true)
            end)
            btn:HookScript("OnEnter", function(selfBtn)
                ShowCategoryTip(selfBtn, selfBtn.label:GetText(), selfBtn.tip)
                Shell:PaintTabs()
            end)
            btn:HookScript("OnLeave", function()
                HideCategoryTip()
                Shell:PaintTabs()
            end)
            self.tabButtons[i] = btn
        end
        btn.subKey = sub.key
        btn.tip = sub.desc
        Skin.SetTabText(btn, sub.label or sub.name)
        btn:Show()
        local textWidth = btn.label:GetStringWidth() or 40
        local w = math.max(88, textWidth + 36)
        w = Skin.SizeTab(btn, w)
        btn:ClearAllPoints()
        btn:SetPoint("BOTTOMLEFT", self.tabChild, "BOTTOMLEFT", x, 0)
        x = x + w + gap
    end
    self.tabChild:SetWidth(math.max(1, x))
    local maxScroll = math.max(0, x - (self.tabBar:GetWidth() or 0))
    local offset = math.min(maxScroll, self.tabBar:GetHorizontalScroll() or 0)
    for i = 1, #subs do
        local btn = self.tabButtons[i]
        if btn.subKey == self.subKey then
            local left = 0
            for n = 1, i - 1 do left = left + self.tabButtons[n]:GetWidth() + gap end
            if left < offset then offset = left end
            if left + btn:GetWidth() > offset + self.tabBar:GetWidth() then
                offset = math.min(maxScroll, left + btn:GetWidth() - self.tabBar:GetWidth())
            end
        end
    end
    self.tabBar:SetHorizontalScroll(math.max(0, offset))
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
                local _, matchingSub = Render.Search(group, query)
                subKey = matchingSub
                for i = 1, #subs do
                    local label = string.lower(subs[i].label or subs[i].name or "")
                    if not subKey and label:find(query, 1, true) then
                        subKey = subs[i].key
                        break
                    end
                end
            end
            if not subKey then
                local remembered = self.lastSub and self.lastSub[pageId]
                for i = 1, #subs do
                    if subs[i].key == remembered then subKey = remembered end
                end
                subKey = subKey or subs[1].key
            end
        end
    else
        subKey = nil
        subs = nil
    end

    self.pageId = pageId
    self.subKey = subKey
    self:Remember()
    local title = entry and entry.name or group.name or pageId
    local breadcrumb = "FluxUI  /  " .. title
    if entry and entry.category then breadcrumb = "FluxUI  /  " .. entry.category .. "  /  " .. title end
    if entry and entry.sidebarSubpages then
        for _, sub in ipairs(subs or {}) do
            if sub.key == subKey then title = sub.label or sub.name; breadcrumb = breadcrumb .. "  /  " .. title; break end
        end
    end
    self.title:SetText(title)
    self.desc:SetText(entry and entry.description or "")
    if self.breadcrumb then self.breadcrumb:SetText(breadcrumb) end
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
        gen = Navigation and Navigation.Generation(pageId) or FluxOptions:GetModuleGen(pageId) or 0
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
        self.sectionFolds = self.sectionFolds or {}
        local foldKey = tostring(pageId) .. "\0" .. tostring(subKey or "")
        self.sectionFolds[foldKey] = self.sectionFolds[foldKey] or {}
        page = Render.Build(self.scrollApi.child, group, renderGroup, path, {
            pageId = pageId,
            advancedOpen = self.advancedOpen and self.advancedOpen[cacheKey],
            query = self:ContentQuery(),
            collapsed = self.sectionFolds[foldKey],
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
        page.query = self:ContentQuery()
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

function Shell:Select(pageId, subKey, keepScroll, keepCollapsed)
    if Navigation then pageId, subKey = Navigation.Route(pageId, subKey) end
    if not PageEntry(pageId) then
        pageId, subKey = "layout", nil
    end
    if not keepCollapsed and self.navCollapsed and self:Query() == "" then
        for _, group in ipairs(Catalog.groups) do
            for _, id in ipairs(group.pages) do if id == pageId then self.navCollapsed[group.id] = nil end end
        end
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
        gen = Navigation and Navigation.Generation(self.pageId) or FluxOptions:GetModuleGen(self.pageId) or 0
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
        self.active.query = self:ContentQuery()
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
    if self.pageId then
        local group = self:ResolveGroup(self.pageId)
        self:LayoutTabs(self:SubpagesFor(self.pageId, group))
    end
    if self.active then
        self.active:Layout()
    end
end

function Shell:BuildSidebar()
    self.navButtons = {}
    self.navHeaders = {}
    self.navFlow = {}
    local y = 0
    local systemY = 0
    for g = 1, #Catalog.groups do
        local group = Catalog.groups[g]
        if not group.system and (group.label or "") ~= "" then
        local header = CreateFrame("Button", nil, self.navChild, BackdropTemplateMixin and "BackdropTemplate" or nil)
        header:SetHeight(NAV_HEADER_H)
        local label = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        header.label, header.groupId = label, group.id
        label:SetPoint("LEFT", 6, 0)
        label:SetPoint("RIGHT", -22, 0)
        label:SetJustifyH("LEFT")
        label:SetText(string.upper(group.label or ""))
        label:SetTextColor(0.95, 0.90, 0.76)
        Skin.StyleCategory(header)
        header:EnableMouse(true)
        header.tipTitle = group.label or ""
        header.tipBody = group.description or "Click to collapse or expand this category. Search reveals matching entries."
        local indicator = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        indicator:SetPoint("RIGHT", -6, 0)
        indicator:SetText("-")
        header.indicator = indicator
        header:SetScript("OnClick", function(selfHeader) Shell:ToggleCategory(selfHeader.groupId) end)
        header:SetScript("OnEnter", function(selfHeader)
            ShowCategoryTip(selfHeader, selfHeader.tipTitle, selfHeader.tipBody)
        end)
        header:SetScript("OnLeave", HideCategoryTip)
        header:SetPoint("TOPLEFT", self.navChild, "TOPLEFT", 0, y)
        header:SetPoint("TOPRIGHT", self.navChild, "TOPRIGHT", 0, y)
        y = y - NAV_HEADER_H - 4
        self.navHeaders[#self.navHeaders + 1] = header
        self.navFlow[#self.navFlow + 1] = { kind = "header", groupId = group.id, frame = header }
        end

        for p = 1, #group.pages do
            local pageId = group.pages[p]
            local entry = PageEntry(pageId)
            if entry then
                local rows = entry.sidebarSubpages and entry.tabs or { entry }
                for _, row in ipairs(rows) do
                    local owner = group.system and self.systemNav or self.navChild
                    local btn = CreateFrame("Button", nil, owner, BackdropTemplateMixin and "BackdropTemplate" or nil)
                    btn:SetHeight(group.system and SYSTEM_ROW_H or NAV_ROW_H)
                    Skin.StyleSystemButton(btn, group.system)
                    btn.pageId = pageId
                    btn.groupId = group.id
                    btn.subKey = entry.sidebarSubpages and row.key or nil
                    btn.tipTitle, btn.tipBody = row.name or entry.name, row.desc or entry.description

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
                    icon:SetSize(16, 16)
                    icon:SetPoint("LEFT", 8, 0)
                    icon:SetTexture(row.icon or entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    btn.icon = icon

                    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                    text:SetPoint("RIGHT", -8, 0)
                    text:SetJustifyH("LEFT")
                    text:SetWordWrap(false)
                    text:SetText(row.name or entry.name or pageId)
                    btn.label = text
                    text:ClearAllPoints()
                    text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                    text:SetPoint("RIGHT", -24, 0)
                    local count = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                    count:SetPoint("RIGHT", -8, 0)
                    btn.count = count

                    local top = group.system and systemY or y
                    btn:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, top)
                    btn:SetPoint("TOPRIGHT", owner, "TOPRIGHT", 0, top)
                    if group.system then systemY = systemY - SYSTEM_STEP else y = y - NAV_ROW_H end

                    btn:SetScript("OnClick", function(selfBtn)
                        Shell._resetScroll = true
                        Shell:Select(selfBtn.pageId, selfBtn.subKey or selfBtn.matchSub, false)
                    end)
                    btn:SetScript("OnEnter", function(selfBtn)
                        selfBtn.hover:Show()
                        if selfBtn.atlas.SetAtlas and W.HasAtlas("Options_List_Hover") and not selfBtn.selected then
                            selfBtn.atlas:SetAtlas("Options_List_Hover")
                            selfBtn.atlas:Show()
                        end
                        ShowCategoryTip(selfBtn, selfBtn.tipTitle, selfBtn.tipBody)
                    end)
                    btn:SetScript("OnLeave", function(selfBtn)
                        HideCategoryTip()
                        selfBtn.hover:Hide()
                        if not selfBtn.selected then
                            selfBtn.atlas:Hide()
                        end
                        Shell:PaintSelection()
                    end)

                    self.navButtons[#self.navButtons + 1] = btn
                    if not group.system then self.navFlow[#self.navFlow + 1] = { kind = "page", groupId = group.id, frame = btn } end
                end
            end
        end
    end
    self.navChild:SetHeight(math.max(1, -y))
end

-- CloseWindows hides every UISpecialFrames entry when a center or fullscreen
-- panel opens (spellbook, talents, help, chat config). Stay off that list.
-- Escape closes this window through an override binding while it is shown.
-- Do not register a game-menu handler: registration sorts Blizzard's shared
-- handler table in addon context, tainting even its earlier Casting entry.
-- That can forbid SpellStopCasting/SpellStopTargeting after options close.
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
            elseif shown then
                ClearEscapeClick(shown)
            end
        end)
    end
    escapeRegen:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local function DisarmEscapeBinding(frame)
    if InCombatLockdown and InCombatLockdown() then
        -- Closing during combat must still clear the override once permitted.
        ArmEscapeBinding(frame)
        return
    end
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

    local frame = Skin.CreateWindow("FluxUIOptionsFrame", UIParent)
    frame:SetSize(DEFAULT_W, DEFAULT_H)
    frame:SetScale(math.min(1, math.max(0.5, ((UIParent:GetWidth() or DEFAULT_W) - 40) / DEFAULT_W),
        math.max(0.5, ((UIParent:GetHeight() or DEFAULT_H) - 40) / DEFAULT_H)))
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

    _G.FluxUIOptionsFrame = frame
    _G.FluxUIConfigFrame = frame
    InstallEscapeClose(frame)

    local sidebar = Skin.CreateInset(frame)
    sidebar:SetWidth(SIDEBAR_W)
    sidebar:SetPoint("TOPLEFT", 8, -TITLE_H)
    sidebar:SetPoint("BOTTOMLEFT", 8, FOOTER_H)
    self.sidebar = sidebar
    local systemNav = CreateFrame("Frame", nil, sidebar)
    systemNav:SetHeight(104)
    systemNav:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 8, 8)
    systemNav:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -12, 8)
    self.systemNav = systemNav

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 18, 0)
    content:SetPoint("BOTTOMRIGHT", -18, FOOTER_H + 4)

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -2)
    title:SetJustifyH("LEFT")
    title:SetText("FluxUI")
    self.title = title
    local breadcrumb = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    breadcrumb:SetPoint("TOPLEFT", 76, -39)
    breadcrumb:SetText("FluxUI")
    self.breadcrumb = breadcrumb

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
    tabChild.tabPadding = 20
    tabChild.minTabWidth = 88
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

    local scrollHost = Skin.CreateInset(content)
    scrollHost:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -4)
    scrollHost:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    self.scrollHost = scrollHost
    self.content = content
    self.scrollApi = W.CreateScroll(scrollHost)
    self.scrollApi.scroll:SetPoint("TOPLEFT", scrollHost, "TOPLEFT", 8, -8)
    self.scrollApi.scroll:SetPoint("BOTTOMRIGHT", scrollHost, "BOTTOMRIGHT", -6, 8)

    local search
    local searchOk
    searchOk, search = pcall(CreateFrame, "EditBox", "FluxUIOptionsSearch", sidebar, "SearchBoxTemplate")
    if not searchOk or not search then
        search = CreateFrame("EditBox", "FluxUIOptionsSearch", sidebar, BackdropTemplateMixin and "BackdropTemplate" or nil)
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
    search:SetHeight(20)
    search:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, -8)
    search:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -10, -8)
    search:SetAutoFocus(false)
    search:HookScript("OnTextChanged", function()
        Shell:SearchChanged()
    end)
    search:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
        if selfBox:GetText() ~= "" then
            selfBox:SetText("")
        end
    end)
    self.search = search
    if search.Instructions then search.Instructions:SetText("Search settings") end

    local drag = CreateFrame("Button", nil, frame)
    drag:SetPoint("TOPLEFT", 62, -2)
    drag:SetPoint("TOPRIGHT", -36, -2)
    drag:SetHeight(28)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    drag:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)
    local closeX = frame.CloseButton or CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    if not frame.CloseButton then closeX:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2) end
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

    local reload = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    reload:SetSize(108, 24)
    reload:SetPoint("TOPRIGHT", -18, -36)
    reload:SetText(RELOADUI or "Reload UI")
    reload:SetScript("OnClick", function()
        if not (InCombatLockdown and InCombatLockdown()) and ReloadUI then ReloadUI() end
    end)
    reload:HookScript("OnEnter", function(selfBtn)
        W.ShowTooltip(selfBtn, "Reload UI", "Reload the interface after changing addon settings. Available outside combat.")
    end)
    reload:HookScript("OnLeave", HideCategoryTip)
    local layout = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    layout:SetSize(108, 24)
    layout:SetPoint("RIGHT", reload, "LEFT", -8, 0)
    layout:SetText("HUD Editor")
    layout:SetScript("OnClick", function() Shell:Select("layout", nil, false) end)
    breadcrumb:SetPoint("RIGHT", layout, "LEFT", -16, 0)

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
    navScroll:SetPoint("TOPLEFT", 4, -34)
    navScroll:SetPoint("BOTTOMRIGHT", -12, 120)
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
    navBar:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -2, -36)
    navBar:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -2, 120)
    navBar:SetValueStep(1)
    navBar:SetMinMaxValues(0, 0)
    navBar:SetValue(0)
    local navThumb = navBar:CreateTexture(nil, "OVERLAY")
    navThumb:SetSize(8, 24)
    W.Solid(navThumb, 1, 1, 1, 0.27)
    navBar:SetThumbTexture(navThumb)
    Skin.StyleScrollBar(navBar, navThumb)
    navBar:SetScript("OnValueChanged", function(_, value)
        navScroll:SetVerticalScroll(value or 0)
    end)
    navScroll:EnableMouseWheel(true)
    navScroll:SetScript("OnMouseWheel", function(_, delta)
        local maxScroll = select(2, navBar:GetMinMaxValues())
        local nextValue = math.max(0, math.min(maxScroll or 0, (navBar:GetValue() or 0) - delta * NAV_ROW_H))
        navBar:SetValue(nextValue)
    end)
    self.navScroll = navScroll
    self.navChild = navChild
    self.navBar = navBar
    local noResults = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    noResults:SetPoint("TOPLEFT", 16, -54)
    noResults:SetPoint("RIGHT", -16, 0)
    noResults:SetJustifyH("LEFT")
    noResults:SetText("No matching settings.")
    noResults:Hide()
    self.noResults = noResults

    self.frame = frame
    self.cache = {}
    self.lastSub = {}
    self.advancedOpen = {}
    self:BuildSidebar()

    frame:HookScript("OnHide", function()
        if Shell._escapeBinding then
            DisarmEscapeBinding(frame)
        end
        Shell:OnHidden()
    end)
    frame:HookScript("OnShow", function()
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
    frame:HookScript("OnSizeChanged", function()
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
        self.pageId = self.lastPage or "layout"
    end
    if subKey and subKey ~= "" then
        self.subKey = subKey
    elseif pageId then
        self.subKey = nil
    end
    self.frame:Show()
    self._resetScroll = true
    self:Select(self.pageId, self.subKey, false, not pageId)
    self:ApplyAccent()
    if FluxOptions and FluxOptions.GetConfigStatusText then
        self:SetStatus(FluxOptions:GetConfigStatusText())
    end
end

function Shell:Open(pageId, subKey)
    self:Show(pageId, subKey)
end
