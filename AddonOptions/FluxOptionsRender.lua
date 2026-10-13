-- FluxOptionsRender.lua
-- Walks one AceConfig group into native rows. dialogControl widgets stay AceGUI.
local _, ns = ...

local R = {}
ns.FluxOptionsRender = R

local W = ns.FluxOptionsWidgets
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

local isInherited = {
    set = true,
    get = true,
    func = true,
    confirm = true,
    validate = true,
    disabled = true,
    hidden = true,
}

local stringIsLiteral = {
    name = true,
    desc = true,
    icon = true,
    usage = true,
    width = true,
    image = true,
    fontSize = true,
}

local allIsLiteral = {
    type = true,
    descStyle = true,
    imageWidth = true,
    imageHeight = true,
}

local FILL_EMBEDS = {
    FluxBindingBrowserEmbed = true,
}

local function GetSubOption(group, key)
    if group and group.plugins then
        for _, t in pairs(group.plugins) do
            if t[key] then
                return t[key]
            end
        end
    end
    if group and group.args then
        return group.args[key]
    end
end

local function MakeInfo(root, option, path)
    local info = {}
    local group = root
    local handler = group and group.handler
    for i = 1, #path do
        local nextGroup = GetSubOption(group, path[i])
        if nextGroup then
            group = nextGroup
        end
        info[i] = path[i]
        if group and group.handler then
            handler = group.handler
        end
    end
    info.options = root
    info.appName = "FluxUI"
    info[0] = "FluxUI"
    info.arg = option and option.arg
    info.handler = handler
    info.option = option
    info.type = option and option.type
    info.uiType = "dialog"
    info.uiName = "FluxOptions"
    return info, handler
end

local function GetMember(membername, option, root, path, ...)
    local member
    if isInherited[membername] then
        local group = root
        if group and group[membername] ~= nil then
            member = group[membername]
        end
        for i = 1, #path do
            group = GetSubOption(group, path[i])
            if group and group[membername] ~= nil then
                member = group[membername]
            end
        end
    else
        member = option and option[membername]
    end

    if (not allIsLiteral[membername]) and (type(member) == "function" or ((not stringIsLiteral[membername]) and type(member) == "string")) then
        local info, handler = MakeInfo(root, option, path)
        if type(member) == "function" then
            return member(info, ...)
        end
        if handler and handler[member] then
            return handler[member](handler, info, ...)
        end
        return nil
    end
    return member
end

local function SafeMember(membername, option, root, path, ...)
    local results = { pcall(GetMember, membername, option, root, path, ...) }
    if not results[1] then
        return nil
    end
    return unpack(results, 2, 5)
end

local function TextOf(option, root, path, field)
    local value = SafeMember(field, option, root, path)
    if type(value) == "string" then
        return value
    end
    if type(value) == "number" then
        return tostring(value)
    end
    return ""
end

local function IsHidden(option, root, path)
    if option.dialogHidden ~= nil then
        return option.dialogHidden and true or false
    end
    if option.guiHidden ~= nil then
        return option.guiHidden and true or false
    end
    return SafeMember("hidden", option, root, path) and true or false
end

local function IsDisabled(option, root, path)
    if option.dialogDisabled ~= nil then
        return option.dialogDisabled and true or false
    end
    if option.guiDisabled ~= nil then
        return option.guiDisabled and true or false
    end
    return SafeMember("disabled", option, root, path) and true or false
end

local function IsInline(option)
    if option.dialogInline ~= nil then
        return option.dialogInline and true or false
    end
    if option.guiInline ~= nil then
        return option.guiInline and true or false
    end
    return option.inline and true or false
end

local function Trim(text)
    if type(text) ~= "string" then
        return ""
    end
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function CopyPath(path, key)
    local out = {}
    for i = 1, #path do
        out[i] = path[i]
    end
    if key ~= nil then
        out[#out + 1] = key
    end
    return out
end

local function CollectArgs(group)
    local list = {}
    local seen = {}
    local function add(key, opt)
        if seen[key] or type(opt) ~= "table" or type(opt.type) ~= "string" then
            return
        end
        seen[key] = true
        list[#list + 1] = { key = key, opt = opt }
    end
    if group.plugins then
        for _, t in pairs(group.plugins) do
            for key, opt in pairs(t) do
                add(key, opt)
            end
        end
    end
    if group.args then
        for key, opt in pairs(group.args) do
            add(key, opt)
        end
    end
    return list
end

local function SortEntries(entries, root, pathPrefix)
    local orders = {}
    local names = {}
    for i = 1, #entries do
        local entry = entries[i]
        local path = CopyPath(pathPrefix, entry.key)
        local order = SafeMember("order", entry.opt, root, path)
        orders[entry] = tonumber(order) or 100
        local name = TextOf(entry.opt, root, path, "name")
        names[entry] = string.upper(name or "")
        entry.path = path
        entry.order = orders[entry]
        entry.sortName = names[entry]
    end
    table.sort(entries, function(a, b)
        local oa, ob = a.order, b.order
        if oa == ob then
            return a.sortName < b.sortName
        end
        if oa < 0 then
            if ob >= 0 then
                return false
            end
        elseif ob < 0 then
            return true
        end
        return oa < ob
    end)
end

local function ApplySectionOrder(entries, sectionOrder)
    if type(sectionOrder) ~= "table" or #sectionOrder == 0 then
        return entries
    end
    local indexOf = {}
    for i = 1, #sectionOrder do
        indexOf[sectionOrder[i]] = i
    end

    local preamble = {}
    local sections = {}
    local current
    for i = 1, #entries do
        local entry = entries[i]
        if entry.opt.type == "header" then
            current = { name = TextOf(entry.opt, entry.root or nil, entry.path, "name"), items = { entry }, first = i }
            -- name resolved below after we have root; stash entry and resolve after
            sections[#sections + 1] = current
        elseif not current then
            preamble[#preamble + 1] = entry
        else
            current.items[#current.items + 1] = entry
        end
    end
    if #sections == 0 then
        return entries
    end

    table.sort(sections, function(a, b)
        local function headerName(section)
            local header = section.items[1]
            return TextOf(header.opt, header._root, header.path, "name")
        end
        local na, nb = headerName(a), headerName(b)
        local ia, ib = indexOf[na], indexOf[nb]
        if ia and ib then
            return ia < ib
        end
        if ia then
            return true
        end
        if ib then
            return false
        end
        return a.first < b.first
    end)

    local out = {}
    for i = 1, #preamble do
        out[#out + 1] = preamble[i]
    end
    for s = 1, #sections do
        local items = sections[s].items
        for i = 1, #items do
            out[#out + 1] = items[i]
        end
    end
    return out
end

local function SearchBlob(...)
    local parts = {}
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if type(value) == "string" and value ~= "" then
            parts[#parts + 1] = value
        end
    end
    return string.lower(table.concat(parts, " "))
end

local function Pairable(entry)
    local opt = entry.opt
    if opt.dialogControl or opt.control then
        return false
    end
    local t = opt.type
    if t ~= "toggle" and t ~= "select" and t ~= "range" and t ~= "color" and t ~= "execute" and t ~= "input" then
        return false
    end
    local width = opt.width
    if width == "full" or width == "double" then
        return false
    end
    return true
end

local confirmDialog
local function EnsureConfirm()
    if confirmDialog or not StaticPopupDialogs then
        return
    end
    StaticPopupDialogs["FLUXUI_OPTIONS_CONFIRM"] = {
        text = "%s",
        button1 = YES or "Yes",
        button2 = NO or "No",
        OnAccept = function(self)
            local data = self.data
            if data and data.run then
                data.run()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    confirmDialog = true
end

local function AskConfirm(text, run)
    EnsureConfirm()
    if not StaticPopup_Show then
        run()
        return
    end
    StaticPopup_Show("FLUXUI_OPTIONS_CONFIRM", text or "Continue?", nil, { run = run })
end

local function InvokeSetter(option, root, path, ...)
    local funcname = option.type == "execute" and "func" or "set"
    local info, handler = MakeInfo(root, option, path)
    local func = root and root[funcname]
    local confirm = root and root.confirm
    local validate = root and root.validate
    if root and root.handler then
        handler = root.handler
    end
    local group = root
    for i = 1, #path do
        group = GetSubOption(group, path[i])
        if group then
            if group[funcname] ~= nil then
                func = group[funcname]
            end
            if group.handler then
                handler = group.handler
            end
            if group.confirm ~= nil then
                confirm = group.confirm
            end
            if group.validate ~= nil then
                validate = group.validate
            end
        end
    end
    info.handler = handler

    local args = { ... }
    local function callFunc()
        if type(func) == "string" then
            if handler and handler[func] then
                pcall(handler[func], handler, info, unpack(args))
            end
        elseif type(func) == "function" then
            pcall(func, info, unpack(args))
        end
        if not option._fluxSkipRefresh and FluxOptions and FluxOptions.RefreshOpenPage then
            FluxOptions:RefreshOpenPage()
        end
    end

    if option.type ~= "execute" and validate ~= nil then
        local ok, valid
        if type(validate) == "string" and handler and handler[validate] then
            ok, valid = pcall(handler[validate], handler, info, unpack(args))
        elseif type(validate) == "function" then
            ok, valid = pcall(validate, info, unpack(args))
        else
            ok, valid = true, true
        end
        if not ok or valid == false or type(valid) == "string" then
            local message = type(valid) == "string" and valid or "Invalid value"
            if FluxOptionsShell and FluxOptionsShell.SetStatus then
                FluxOptionsShell:SetStatus(message)
            end
            return
        end
    end

    local confirmText = option.confirmText
    if type(confirmText) == "function" then
        local ok, text = pcall(confirmText, info, unpack(args))
        confirmText = ok and text or nil
    end
    if type(confirm) == "string" and handler and handler[confirm] then
        local ok, result = pcall(handler[confirm], handler, info, unpack(args))
        if ok and type(result) == "string" then
            confirmText = result
            confirm = true
        elseif ok then
            confirm = result
        else
            confirm = false
        end
    elseif type(confirm) == "function" then
        local ok, result = pcall(confirm, info, unpack(args))
        if ok and type(result) == "string" then
            confirmText = result
            confirm = true
        elseif ok then
            confirm = result
        else
            confirm = false
        end
    end

    if confirm == true then
        if type(confirmText) ~= "string" or confirmText == "" then
            confirmText = TextOf(option, root, path, "name")
            local desc = TextOf(option, root, path, "desc")
            if desc ~= "" then
                confirmText = confirmText .. " - " .. desc
            end
        end
        AskConfirm(confirmText, callFunc)
        return
    end
    callFunc()
end

local function ReadGet(option, root, path)
    if option.get == false then
        return nil
    end
    return SafeMember("get", option, root, path)
end

local function NoteEmbed(page, widget)
    page.embeds[#page.embeds + 1] = widget
end

local function HostEmbed(page, parent, option)
    if not AceGUI or not option.dialogControl then
        return nil
    end
    local widget = AceGUI:Create(option.dialogControl)
    if not widget or not widget.frame then
        return nil
    end
    widget.frame:SetParent(parent)
    widget.frame:ClearAllPoints()
    widget.frame:Show()
    local width = page:ContentWidth()
    widget.frame:SetWidth(width)
    if widget.OnWidthSet then
        pcall(widget.OnWidthSet, widget, width)
    end
    if widget.SetText and type(option.name) == "string" and option.name ~= "" and option.name ~= " " then
        pcall(widget.SetText, widget, option.name)
    end
    local height = widget.frame:GetHeight() or 0
    if height < 8 then
        height = tonumber(widget.height) or 80
        widget.frame:SetHeight(height)
    end
    NoteEmbed(page, widget)
    return widget
end

local function AddControlRow(page, entry, parent)
    local option = entry.opt
    local root = page.root
    local path = entry.path
    local name = TextOf(option, root, path, "name")
    local desc = TextOf(option, root, path, "desc")
    local control = option.dialogControl or option.control

    if control and (option.type == "description" or option.type == "group" or name == "" or name == " ") then
        local row = W.CreateRow(parent, 80)
        row.kind = "embed"
        row.pairable = false
        row.fillViewport = FILL_EMBEDS[control] and true or false
        row.searchText = SearchBlob(name, desc, control)
        local widget = HostEmbed(page, row, option)
        row.widget = widget
        if widget and widget.frame then
            widget.frame:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            widget.frame:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
            row:SetHeight(widget.frame:GetHeight() or 80)
            widget.frame:HookScript("OnSizeChanged", function(frame)
                if not page._active or page._layingOut or row._syncing then
                    return
                end
                local h = frame:GetHeight() or 0
                if h > 8 and math.abs((row:GetHeight() or 0) - h) > 1 then
                    row._syncing = true
                    row:SetHeight(h)
                    row._syncing = false
                    page:Layout()
                end
            end)
        end
        row.Refresh = function(self)
            self._disabled = IsDisabled(option, root, path)
            self._hidden = IsHidden(option, root, path)
        end
        return row
    end

    local row
    if option.type == "toggle" then
        row = W.CreateToggle(parent)
        row.SetOnChange = row.SetOnChange
        row:SetOnChange(function(value)
            InvokeSetter(option, root, path, value)
        end)
    elseif option.type == "select" and option.style ~= "radio" then
        row = W.CreateDropdown(parent)
        row:SetGetter(function()
            local values = SafeMember("values", option, root, path)
            local sorting = SafeMember("sorting", option, root, path)
            local items = {}
            if type(values) ~= "table" then
                return items
            end
            if type(sorting) ~= "table" then
                sorting = {}
                for key in pairs(values) do
                    sorting[#sorting + 1] = key
                end
                table.sort(sorting, function(a, b)
                    return tostring(a) < tostring(b)
                end)
            end
            for i = 1, #sorting do
                local key = sorting[i]
                local text = values[key]
                items[#items + 1] = { value = key, text = type(text) == "string" and text or tostring(text or key) }
            end
            return items
        end)
        row:SetOnChange(function(value)
            InvokeSetter(option, root, path, value)
        end)
    elseif option.type == "range" then
        row = W.CreateSlider(parent)
        local minV = option.softMin or option.min or 0
        local maxV = option.softMax or option.max or 100
        local step = option.bigStep or option.step or 0
        row:Configure(minV, maxV, step, option.isPercent)
        row:SetOnChange(function(value)
            option._fluxSkipRefresh = true
            InvokeSetter(option, root, path, value)
            option._fluxSkipRefresh = nil
        end)
        row:SetOnCommit(function(value)
            InvokeSetter(option, root, path, value)
        end)
    elseif option.type == "color" then
        row = W.CreateColor(parent)
        local hasAlpha = SafeMember("hasAlpha", option, root, path)
        row:SetHasAlpha(hasAlpha)
        row:SetOnChange(function(r, g, b, a)
            InvokeSetter(option, root, path, r, g, b, a)
        end)
    elseif option.type == "execute" then
        row = W.CreateButton(parent)
        row:SetButtonText(name ~= "" and name or "Run")
        row:SetOnClick(function()
            InvokeSetter(option, root, path)
        end)
    elseif option.type == "input" then
        row = W.CreateInput(parent)
        row:SetOnCommit(function(text)
            InvokeSetter(option, root, path, text)
        end)
    elseif option.type == "header" then
        row = W.CreateHeader(parent)
        row:SetLabel(name)
        row.kind = "header"
    elseif option.type == "description" then
        local body = name
        if Trim(body) == "" and not control then
            return nil
        end
        row = W.CreateDescription(parent)
        row:SetBody(body, SafeMember("fontSize", option, root, path))
        row.kind = "description"
    else
        return nil
    end

    if not row then
        return nil
    end
    row.kind = row.kind or option.type
    row.pairable = Pairable(entry)
    row.searchText = SearchBlob(name, desc)
    if row.SetLabel and option.type ~= "header" and option.type ~= "description" then
        row:SetLabel(name)
    end
    if row.SetDescription then
        row:SetDescription(desc)
    end

    row.Refresh = function(self)
        self._hidden = IsHidden(option, root, path)
        self._disabled = IsDisabled(option, root, path)
        if self.SetDisabled then
            self:SetDisabled(self._disabled)
        end
        if option.type == "toggle" then
            self:SetValue(ReadGet(option, root, path))
        elseif option.type == "select" then
            self:SetValue(ReadGet(option, root, path))
        elseif option.type == "range" then
            self:SetValue(ReadGet(option, root, path) or option.min or 0)
        elseif option.type == "color" then
            local r, g, b, a = ReadGet(option, root, path)
            self:SetValue(r, g, b, a)
        elseif option.type == "input" then
            local text = ReadGet(option, root, path)
            self:SetValue(type(text) == "string" and text or "")
        elseif option.type == "description" then
            local body = TextOf(option, root, path, "name")
            self:SetBody(body, SafeMember("fontSize", option, root, path))
            self.searchText = SearchBlob(body)
        elseif option.type == "header" then
            local title = TextOf(option, root, path, "name")
            self:SetLabel(title)
            self.searchText = SearchBlob(title)
        end
    end
    return row
end

local function Walk(page, group, pathPrefix, parent, advancedNames)
    local entries = CollectArgs(group)
    for i = 1, #entries do
        entries[i]._root = page.root
    end
    SortEntries(entries, page.root, pathPrefix)
    local catalog = ns.FluxOptionsCatalog
    local sectionOrder = catalog and catalog.sectionOrder and catalog.sectionOrder[page.pageId]
    entries = ApplySectionOrder(entries, sectionOrder)

    local inAdvanced = false
    local sawMore = false
    for i = 1, #entries do
        local entry = entries[i]
        local option = entry.opt
        if option.type == "group" then
            if IsInline(option) and not IsHidden(option, page.root, entry.path) then
                local title = Trim(TextOf(option, page.root, entry.path, "name"))
                if title ~= "" then
                    local headerOpt = { type = "header", name = title, order = entry.order }
                    local headerEntry = { key = entry.key .. "#header", opt = headerOpt, path = entry.path, order = entry.order }
                    local headerRow = AddControlRow(page, headerEntry, parent)
                    if headerRow then
                        headerRow.advanced = inAdvanced
                        headerRow.sectionHeader = true
                        page.rows[#page.rows + 1] = headerRow
                    end
                end
                Walk(page, option, entry.path, parent, advancedNames)
            end
        else
            if option.type == "header" then
                local title = TextOf(option, page.root, entry.path, "name")
                local advanced = advancedNames and advancedNames[title] and true or false
                if advanced and not inAdvanced and not sawMore then
                    local more = W.CreateMoreButton(parent)
                    more.kind = "more"
                    more.pairable = false
                    more.searchText = "more options performance"
                    more.advanced = false
                    more:SetOpen(page.advancedOpen)
                    more:SetOnClick(function()
                        page.advancedOpen = not page.advancedOpen
                        more:SetOpen(page.advancedOpen)
                        page:Layout()
                    end)
                    more.Refresh = function(self)
                        self:SetOpen(page.advancedOpen)
                        self._hidden = false
                    end
                    page.moreRow = more
                    page.rows[#page.rows + 1] = more
                    sawMore = true
                end
                if not advanced then
                    inAdvanced = false
                else
                    inAdvanced = true
                end
            end
            local row = AddControlRow(page, entry, parent)
            if row then
                row.advanced = inAdvanced
                if option.type == "header" then
                    row.sectionHeader = true
                end
                page.rows[#page.rows + 1] = row
            end
        end
    end
end

local function SectionVisible(rows, startIndex, query)
    local header = rows[startIndex]
    local headerMatch = query == "" or (header.searchText and header.searchText:find(query, 1, true))
    local childMatch = false
    local last = startIndex
    for i = startIndex + 1, #rows do
        local row = rows[i]
        if row.sectionHeader then
            break
        end
        last = i
        if query ~= "" and row.kind ~= "more" and row.searchText and row.searchText:find(query, 1, true) then
            childMatch = true
        end
    end
    return headerMatch, childMatch, last
end

function R.ListSubpages(group)
    if not group or group.childGroups ~= "tab" or type(group.args) ~= "table" then
        return nil
    end
    local pages = {}
    for key, opt in pairs(group.args) do
        if type(opt) == "table" and opt.type == "group" and not IsInline(opt) then
            local hidden = false
            if type(opt.hidden) == "function" then
                local ok, result = pcall(opt.hidden)
                hidden = ok and result and true or false
            elseif opt.hidden then
                hidden = true
            end
            if not hidden then
                local name = opt.name
                if type(name) == "function" then
                    local ok, result = pcall(name)
                    name = ok and result or key
                end
                local desc = opt.desc
                if type(desc) == "function" then
                    local okDesc, result = pcall(desc)
                    desc = okDesc and result or nil
                end
                pages[#pages + 1] = {
                    key = key,
                    name = type(name) == "string" and name or tostring(key),
                    desc = type(desc) == "string" and desc or nil,
                    order = tonumber(opt.order) or 100,
                }
            end
        end
    end
    table.sort(pages, function(a, b)
        if a.order == b.order then
            return string.upper(a.name) < string.upper(b.name)
        end
        return a.order < b.order
    end)
    if #pages == 0 then
        return nil
    end
    return pages
end

function R.Build(parent, root, group, pathPrefix, opts)
    opts = opts or {}
    local page = {
        root = root,
        group = group,
        pathPrefix = pathPrefix or {},
        parent = parent,
        rows = {},
        embeds = {},
        pageId = opts.pageId,
        advancedOpen = opts.advancedOpen and true or false,
        query = opts.query or "",
        getWidth = opts.getWidth,
        getViewport = opts.getViewport,
        _active = true,
    }

    function page:ContentWidth()
        if self.getWidth then
            local w = self.getWidth()
            if w and w > 40 then
                return w
            end
        end
        return 640
    end

    function page:Layout()
        if not self._active or self._layingOut then
            return
        end
        self._layingOut = true
        local width = self:ContentWidth()
        local query = string.lower(self.query or "")
        for n = 1, #self.rows do
            if self.rows[n].Refresh then
                self.rows[n]:Refresh()
            end
        end
        local showAdvanced = self.advancedOpen
        if query ~= "" then
            for n = 1, #self.rows do
                local candidate = self.rows[n]
                if candidate.advanced and not candidate._hidden and candidate.searchText and candidate.searchText:find(query, 1, true) then
                    showAdvanced = true
                    break
                end
            end
        end
        local stripe = 0
        local y = 0

        local show = {}
        local i = 1
        while i <= #self.rows do
            local row = self.rows[i]
            if row.sectionHeader then
                local headerMatch, childMatch, last = SectionVisible(self.rows, i, query)
                local sectionOn = (query == "") or headerMatch or childMatch
                for n = i, last do
                    local candidate = self.rows[n]
                    local visible = sectionOn and not candidate._hidden
                    if candidate.advanced and not showAdvanced then
                        visible = false
                    end
                    if query ~= "" and sectionOn and not headerMatch and candidate.kind ~= "header" and candidate.kind ~= "more" then
                        local matches = candidate.searchText and candidate.searchText:find(query, 1, true)
                        if not matches then
                            visible = false
                        end
                    end
                    if candidate.kind == "more" then
                        if query ~= "" and not showAdvanced then
                            visible = false
                        end
                        if visible and candidate.SetOpen then
                            candidate:SetOpen(showAdvanced)
                        end
                    end
                    show[n] = visible
                end
                i = last + 1
            else
                local visible = not row._hidden
                if row.advanced and not showAdvanced then
                    visible = false
                end
                if row.kind == "more" then
                    local anyAdvanced = false
                    for n = 1, #self.rows do
                        if self.rows[n].advanced and not self.rows[n]._hidden then
                            anyAdvanced = true
                            break
                        end
                    end
                    visible = anyAdvanced
                    if query ~= "" and not showAdvanced then
                        visible = false
                    end
                    if visible and row.SetOpen then
                        row:SetOpen(showAdvanced)
                    end
                elseif query ~= "" then
                    local matches = row.searchText and row.searchText:find(query, 1, true)
                    if not matches then
                        visible = false
                    end
                end
                show[i] = visible
                i = i + 1
            end
        end

        local index = 1
        while index <= #self.rows do
            local row = self.rows[index]
            if not show[index] then
                row:Hide()
                index = index + 1
            else
                local nxt = self.rows[index + 1]
                local pair = row.pairable and nxt and show[index + 1] and nxt.pairable and not row.fillViewport and not nxt.fillViewport
                row:Show()
                if row.kind == "description" and row.LayoutHeight then
                    row:LayoutHeight(pair and (width / 2) or width)
                end
                if row.kind == "embed" and row.widget and row.widget.frame then
                    row.widget.frame:SetWidth(width)
                    if row.widget.OnWidthSet then
                        pcall(row.widget.OnWidthSet, row.widget, width)
                    end
                    local h = row.widget.frame:GetHeight() or row:GetHeight() or 80
                    if row.fillViewport and self.getViewport then
                        local view = self.getViewport() or 0
                        if view > h then
                            h = view
                        end
                        if row.widget.OnHeightSet then
                            pcall(row.widget.OnHeightSet, row.widget, h)
                        end
                        row.widget.frame:SetHeight(h)
                        h = row.widget.frame:GetHeight() or h
                    end
                    row:SetHeight(math.max(8, h))
                end
                local h = row:GetHeight() or W.ROW_H
                if pair then
                    local h2 = nxt:GetHeight() or W.ROW_H
                    if h2 > h then
                        h = h2
                    end
                    stripe = stripe + 1
                    local half = math.floor(width / 2)
                    row:ClearAllPoints()
                    row:SetWidth(half)
                    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
                    nxt:Show()
                    nxt:ClearAllPoints()
                    nxt:SetWidth(width - half)
                    nxt:SetPoint("TOPLEFT", parent, "TOPLEFT", half, y)
                    if row.bg then
                        W.PaintStripe(row, stripe)
                    end
                    if nxt.bg then
                        W.PaintStripe(nxt, stripe)
                    end
                    y = y - h
                    index = index + 2
                else
                    stripe = stripe + 1
                    row:ClearAllPoints()
                    row:SetWidth(width)
                    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
                    if row.bg and row.kind ~= "header" and row.kind ~= "description" and row.kind ~= "more" then
                        W.PaintStripe(row, stripe)
                    end
                    y = y - h
                    index = index + 1
                end
            end
        end

        parent:SetWidth(width)
        parent:SetHeight(math.max(1, -y))
        self.contentHeight = -y
        self._layingOut = false
        if self.onLayout then
            self.onLayout(self.contentHeight)
        end
    end

    function page:Refresh()
        self:Layout()
    end

    function page:SetQuery(query)
        self.query = query or ""
        self:Layout()
    end

    function page:SetActive(active)
        active = active and true or false
        if self._active == active then
            return
        end
        self._active = active
        if not active then
            for i = 1, #self.rows do
                self.rows[i]:Hide()
            end
            for i = 1, #self.embeds do
                local widget = self.embeds[i]
                if widget and widget.type == "FluxBindingBrowserEmbed" and _G.FluxBindingBrowser_Detach then
                    pcall(_G.FluxBindingBrowser_Detach, widget)
                    self._bindingDetached = true
                end
                if widget and widget.frame then
                    widget.frame:Hide()
                end
            end
            return
        end
        for i = 1, #self.embeds do
            local widget = self.embeds[i]
            if widget and widget.frame then
                widget.frame:Show()
            end
            if widget and widget.type == "FluxBindingBrowserEmbed" and self._bindingDetached and _G.FluxBindingBrowser_Attach then
                pcall(_G.FluxBindingBrowser_Attach, widget)
                self._bindingDetached = false
            end
        end
    end

    function page:Release()
        if AceGUI then
            for i = 1, #self.embeds do
                local widget = self.embeds[i]
                if widget and not widget.isQueuedForRelease then
                    pcall(AceGUI.Release, AceGUI, widget)
                end
            end
        end
        for i = 1, #self.rows do
            local row = self.rows[i]
            row:Hide()
            row:SetParent(nil)
        end
        self.rows = {}
        self.embeds = {}
        self.released = true
    end

    local advancedNames = ns.FluxOptionsCatalog and ns.FluxOptionsCatalog.advancedHeaders
    Walk(page, group, pathPrefix or {}, parent, advancedNames)
    for i = 1, #page.rows do
        if page.rows[i].Refresh then
            page.rows[i]:Refresh()
        end
    end
    page:Layout()
    return page
end
