-- Blizzard settings dropdown (WowStyle1). Classic UIDropDownMenu is the fallback.
local _, ns = ...

local DD = {}
_G.FluxBlizzardDropdown = DD
ns.FluxBlizzardDropdown = DD

local function LoadMenuAddon()
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_Menu")
    elseif LoadAddOn then
        pcall(LoadAddOn, "Blizzard_Menu")
    end
end

function DD.IsMouseOver()
    for i = 1, _G.UIDROPDOWNMENU_MAXLEVELS or 4 do
        local list = _G["DropDownList" .. i]
        if list and list:IsShown() and list:IsMouseOver() then
            return true
        end
    end
    if not (Menu and Menu.GetManager) then
        return false
    end
    local ok, manager = pcall(Menu.GetManager)
    if not ok or not manager or not manager.GetOpenMenu then
        return false
    end
    local openOk, openMenu = pcall(manager.GetOpenMenu, manager)
    if openOk and openMenu and openMenu.IsShown and openMenu:IsShown() and openMenu.IsMouseOver and openMenu:IsMouseOver() then
        return true
    end
    return false
end

local function ApplyDecor(desc, entry)
    if not desc or not entry then
        return
    end
    if entry.icon and desc.SetIcon then
        pcall(desc.SetIcon, desc, entry.icon)
    end
    if entry.disabled ~= nil and desc.SetEnabled then
        local dis = entry.disabled
        local enabled = not (type(dis) == "function" and dis() or dis)
        pcall(desc.SetEnabled, desc, enabled)
    end
end

local function FillModern(root, entries)
    if root.SetScrollMode then
        root:SetScrollMode(280)
    end
    for i = 1, #entries do
        local entry = entries[i]
        if entry.divider then
            if root.CreateDivider then
                root:CreateDivider()
            end
        elseif entry.submenu then
            local sub = root:CreateButton(entry.text or "")
            local kids = entry.submenu
            if type(kids) == "function" then
                kids = kids()
            end
            for j = 1, #(kids or {}) do
                local child = kids[j]
                local btn = sub:CreateButton(child.text or "", function()
                    if child.func then
                        child.func()
                    end
                end)
                ApplyDecor(btn, child)
            end
        elseif entry.checked ~= nil then
            local radio = root:CreateRadio(entry.text or "", function()
                local checked = entry.checked
                if type(checked) == "function" then
                    return checked() and true or false
                end
                return checked and true or false
            end, function()
                if entry.func then
                    entry.func()
                end
            end)
            ApplyDecor(radio, entry)
        else
            local btn = root:CreateButton(entry.text or "", function()
                if entry.func then
                    entry.func()
                end
            end)
            ApplyDecor(btn, entry)
        end
    end
end

-- Forever gamepad uses the classic dropdown for every Flux menu. A Flux
-- WowStyle1 menu fills the shared menu frame from addon code, and that frame
-- stays tainted, so later Blizzard dropdowns also call
-- SetPreferredGamepadInteractTarget as Flux. Blizzard's own menus are untouched.
function DD.UseClassicMenu()
    local Flux = ns.Flux or _G.Flux
    local cap = Flux and (Flux.Cap or Flux.Capabilities)
    return cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() == true
end

function DD.WantsGamepadMenu(name, opts)
    if DD.UseClassicMenu() then
        return false
    end
    if opts and opts.gamepadMenu then
        return true
    end
    return type(name) == "string" and name:find("FluxRespec", 1, true) ~= nil
end

function DD.InstallGamepadClick()
end

local function FillClassic(dropdown, level, entries)
    local menuValue = _G.UIDROPDOWNMENU_MENU_VALUE
    if level == 2 then
        for i = 1, #entries do
            local entry = entries[i]
            if entry.submenuId == menuValue then
                local kids = entry.submenu
                if type(kids) == "function" then
                    kids = kids()
                end
                for j = 1, #(kids or {}) do
                    local child = kids[j]
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = child.text
                    info.notCheckable = true
                    info.disabled = type(child.disabled) == "function" and child.disabled() or child.disabled
                    info.func = child.func
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end
        return
    end
    for i = 1, #entries do
        local entry = entries[i]
        if not entry.divider then
            local info = UIDropDownMenu_CreateInfo()
            info.text = entry.text
            if entry.checked ~= nil then
                info.checked = type(entry.checked) == "function" and entry.checked() or entry.checked
                info.notCheckable = false
            else
                info.notCheckable = true
            end
            info.disabled = type(entry.disabled) == "function" and entry.disabled() or entry.disabled
            info.func = entry.func
            if entry.icon then
                info.icon = entry.icon
                local coords = entry.iconCoords
                if coords then
                    info.tCoordLeft, info.tCoordRight = coords[1], coords[2]
                    info.tCoordTop, info.tCoordBottom = coords[3], coords[4]
                end
            end
            if entry.submenu then
                info.hasArrow = true
                info.value = entry.submenuId
                info.notCheckable = true
                info.func = function() end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

--- @param opts table|nil { stretch = true } keeps LEFT+RIGHT anchors from fighting SetWidth
function DD.Create(parent, name, width, opts)
    opts = opts or {}
    LoadMenuAddon()
    width = width or 180
    local dropdown
    local modern = false
    if DD.WantsGamepadMenu(name, opts) or not DD.UseClassicMenu() then
        local ok, created = pcall(CreateFrame, "DropdownButton", name, parent, "WowStyle1DropdownTemplate")
        if ok and created and created.SetupMenu then
            dropdown = created
            modern = true
            if not opts.stretch then
                dropdown:SetWidth(width)
            end
        end
    end
    if not dropdown then
        dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
        if UIDropDownMenu_SetWidth then
            UIDropDownMenu_SetWidth(dropdown, math.max(80, width - 50))
        end
        if UIDropDownMenu_JustifyText then
            UIDropDownMenu_JustifyText(dropdown, "LEFT")
        end
    end
    dropdown._fluxModern = modern
    dropdown._fluxStretch = opts.stretch and true or false
    dropdown._fluxMinWidth = width

    function dropdown:FluxSetText(text)
        text = text or ""
        if self.OverrideText then
            self:OverrideText(text)
        elseif self.SetDefaultText then
            self:SetDefaultText(text)
        elseif self.Text and self.Text.SetText then
            self.Text:SetText(text)
        elseif UIDropDownMenu_SetText then
            UIDropDownMenu_SetText(self, text)
        end
        if not self._fluxModern or self._fluxStretch or not self.Text then
            return
        end
        local textWidth = 0
        if self.Text.GetUnboundedStringWidth then
            textWidth = self.Text:GetUnboundedStringWidth() or 0
        elseif self.Text.GetStringWidth then
            textWidth = self.Text:GetStringWidth() or 0
        end
        local want = math.max(self._fluxMinWidth or 140, math.ceil(textWidth + 52))
        if want > 360 then
            want = 360
        end
        self:SetWidth(want)
    end

    function dropdown:FluxSetMenu(getEntries)
        DD.InstallGamepadClick(self, getEntries)
        if self._fluxModern then
            self:SetupMenu(function(owner, root)
                local menuRoot = root or owner
                if menuRoot and menuRoot.CreateRadio then
                    FillModern(menuRoot, getEntries() or {})
                end
            end)
        elseif UIDropDownMenu_Initialize then
            UIDropDownMenu_Initialize(self, function(_, level)
                FillClassic(self, level, getEntries() or {})
            end)
        end
    end

    return dropdown
end
