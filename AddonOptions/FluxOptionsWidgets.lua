-- FluxOptionsWidgets.lua
-- Native rows for the FluxUI options window. AceGUI is not used here.
local _, ns = ...

local W = {}
ns.FluxOptionsWidgets = W

W.ROW_H = 40

local accentListeners = {}

-- This client rejects a 4th alpha on SetVertexColor/SetColorTexture. RGB, then SetAlpha.
local function Solid(tex, r, g, b, a)
    if not tex then
        return
    end
    a = a or 1
    r, g, b = r or 1, g or 1, b or 1
    tex:SetTexture("Interface\\Buttons\\WHITE8x8")
    tex:SetVertexColor(r, g, b)
    tex:SetAlpha(a)
end

function W.Solid(tex, r, g, b, a)
    Solid(tex, r, g, b, a)
end

function W.Accent()
    if FluxBorder and FluxBorder.GetAccentColor then
        local r, g, b = FluxBorder:GetAccentColor()
        return r or 1, g or 1, b or 1
    end
    return 0.9, 0.75, 0.3
end

function W.OnAccent(fn)
    if type(fn) == "function" then
        accentListeners[#accentListeners + 1] = fn
    end
end

function W.RefreshAccent()
    for i = 1, #accentListeners do
        pcall(accentListeners[i])
    end
end

function W.HasAtlas(name)
    if not name or name == "" then
        return false
    end
    if C_Texture and C_Texture.GetAtlasInfo then
        local ok, info = pcall(C_Texture.GetAtlasInfo, name)
        return ok and info ~= nil
    end
    if GetAtlasInfo then
        local ok, info = pcall(GetAtlasInfo, name)
        return ok and info ~= nil
    end
    return false
end

local function BackdropFrame(name, parent, template)
    local tmpl = template
    if BackdropTemplateMixin then
        if tmpl and tmpl ~= "" then
            tmpl = "BackdropTemplate," .. tmpl
        else
            tmpl = "BackdropTemplate"
        end
    end
    return CreateFrame("Frame", name, parent, tmpl)
end

function W.ApplyBackdrop(frame, r, g, b, a, br, bg, bb, ba)
    if not frame or not frame.SetBackdrop then
        return
    end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(r, g, b, a or 1)
    frame:SetBackdropBorderColor(br or 1, bg or 1, bb or 1, ba or 0.12)
end

function W.HideTooltip()
    if GameTooltip then
        GameTooltip:Hide()
    end
end

function W.ShowTooltip(owner, title, body)
    if not GameTooltip or not owner then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    if title and title ~= "" then
        GameTooltip:SetText(title, 1, 0.82, 0, 1, true)
    end
    if body and body ~= "" then
        GameTooltip:AddLine(body, 1, 1, 1, true)
    end
    GameTooltip:Show()
end

local function ClickSound()
    local id = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856
    if PlaySound then
        pcall(PlaySound, id)
    end
end

function W.CreateRow(parent, height)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(height or W.ROW_H)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    row.bg = bg
    row:EnableMouse(true)
    return row
end

function W.PaintStripe(row, index)
    if not row or not row.bg then
        return
    end
    if index % 2 == 0 then
        Solid(row.bg, 0.11, 0.13, 0.15, 0.9)
    else
        Solid(row.bg, 0.07, 0.08, 0.10, 0.9)
    end
end

function W.CreateHeader(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(28)
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", 4, 0)
    text:SetPoint("RIGHT", -4, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    local line = row:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 4, 2)
    line:SetPoint("BOTTOMRIGHT", -4, 2)
    Solid(line, 1, 1, 1, 0.12)
    row.text = text
    row.SetLabel = function(_, value)
        text:SetText(value or "")
    end
    return row
end

function W.CreateDescription(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(20)
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", 12, -4)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(true)
    row.text = text
    row.SetBody = function(self, value, fontSize)
        if fontSize == "medium" then
            text:SetFontObject(GameFontHighlight)
        elseif fontSize == "large" then
            text:SetFontObject(GameFontHighlightLarge)
        else
            text:SetFontObject(GameFontHighlightSmall)
        end
        text:SetText(value or "")
        self._body = value or ""
    end
    row.LayoutHeight = function(self, width)
        local w = math.max(40, (width or 200) - 24)
        text:SetWidth(w)
        local h = (text:GetStringHeight() or 0) + 10
        if h < 18 then
            h = 18
        end
        self:SetHeight(h)
        return h
    end
    return row
end

local function AttachTooltip(frame, getTitle, getBody)
    frame:SetScript("OnEnter", function(self)
        local title = getTitle and getTitle() or nil
        local body = getBody and getBody() or nil
        if (title and title ~= "") or (body and body ~= "") then
            W.ShowTooltip(self, title, body)
        end
    end)
    frame:SetScript("OnLeave", function()
        W.HideTooltip()
    end)
end

function W.CreateToggle(parent)
    local row = W.CreateRow(parent, W.ROW_H)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    label:SetPoint("LEFT", 12, 0)

    local btn = CreateFrame("Button", nil, row)
    btn:SetSize(40, 20)
    btn:SetPoint("RIGHT", -12, 0)
    local track = btn:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    local knob = btn:CreateTexture(nil, "ARTWORK")
    knob:SetSize(16, 16)
    Solid(knob, 0.92, 0.92, 0.92, 1)

    local value = false
    local disabled = false
    local onChange

    local function Paint()
        local r, g, b = W.Accent()
        if value then
            Solid(track, r, g, b, disabled and 0.35 or 0.85)
            knob:ClearAllPoints()
            knob:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
        else
            Solid(track, 0.27, 0.27, 0.27, disabled and 0.4 or 0.7)
            knob:ClearAllPoints()
            knob:SetPoint("LEFT", btn, "LEFT", 2, 0)
        end
        label:SetAlpha(disabled and 0.4 or 1)
    end

    btn:SetScript("OnClick", function()
        if disabled then
            return
        end
        value = not value
        Paint()
        ClickSound()
        if onChange then
            onChange(value)
        end
    end)

    label:SetPoint("RIGHT", btn, "LEFT", -10, 0)
    AttachTooltip(row, function() return row._title end, function() return row._desc end)
    AttachTooltip(btn, function() return row._title end, function() return row._desc end)

    row.SetLabel = function(_, text)
        row._title = text or ""
        label:SetText(row._title)
    end
    row.SetDescription = function(_, text)
        row._desc = text or ""
    end
    row.SetValue = function(_, v)
        value = v and true or false
        Paint()
    end
    row.GetValue = function()
        return value
    end
    row.SetDisabled = function(_, d)
        disabled = d and true or false
        btn:EnableMouse(not disabled)
        Paint()
    end
    row.SetOnChange = function(_, fn)
        onChange = fn
    end
    row.RefreshAccent = Paint
    W.OnAccent(Paint)
    Paint()
    return row
end

local function SetBlizzardDropdownText(dropdown, text)
    text = text or ""
    if dropdown.OverrideText then
        dropdown:OverrideText(text)
        return
    end
    if dropdown.SetDefaultText then
        dropdown:SetDefaultText(text)
        return
    end
    if dropdown.Text and dropdown.Text.SetText then
        dropdown.Text:SetText(text)
        return
    end
    if UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(dropdown, text)
    end
end

function W.CloseDropdown()
    if Menu and Menu.GetManager then
        local ok, manager = pcall(Menu.GetManager)
        if ok and manager and manager.CloseMenus then
            pcall(manager.CloseMenus, manager)
        end
    end
    if CloseDropDownMenus then
        CloseDropDownMenus()
    end
end

local function CreateModernDropdown(parent)
    local Flux = _G.Flux
    local cap = Flux and (Flux.Cap or Flux.Capabilities)
    if cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() then
        return nil
    end
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_Menu")
    elseif LoadAddOn then
        pcall(LoadAddOn, "Blizzard_Menu")
    end
    local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    if ok and dropdown and dropdown.SetupMenu then
        return dropdown
    end
end

function W.CreateDropdown(parent)
    local row = W.CreateRow(parent, W.ROW_H)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    label:SetPoint("LEFT", 12, 0)

    local dropdown = CreateModernDropdown(row)
    local modern = dropdown ~= nil
    if not dropdown then
        dropdown = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
        if UIDropDownMenu_SetWidth then
            UIDropDownMenu_SetWidth(dropdown, 160)
        end
    else
        dropdown:SetWidth(200)
    end
    dropdown:SetPoint("RIGHT", modern and -8 or 12, modern and 0 or -1)
    label:SetPoint("RIGHT", dropdown, "LEFT", modern and -8 or 18, 0)

    local disabled = false
    local value
    local getItems
    local onChange

    local function CurrentText()
        local text = ""
        if getItems then
            local items = getItems() or {}
            for i = 1, #items do
                if items[i].value == value then
                    text = items[i].text or ""
                    break
                end
            end
        end
        if text == "" and value ~= nil then
            text = tostring(value)
        end
        return text
    end

    local function Display()
        local text = CurrentText()
        SetBlizzardDropdownText(dropdown, text)
        local fs = dropdown.Text
        local textWidth = 0
        if fs then
            if fs.GetUnboundedStringWidth then
                textWidth = fs:GetUnboundedStringWidth() or 0
            else
                textWidth = fs:GetStringWidth() or 0
            end
        end
        if textWidth < 8 then
            textWidth = 8 * #text
        end
        if modern then
            local rowWidth = row:GetWidth() or 0
            local want = math.max(140, math.ceil(textWidth + 52))
            if rowWidth > 80 then
                want = math.min(want, math.max(140, rowWidth - 24))
            end
            dropdown:SetWidth(want)
        elseif UIDropDownMenu_SetWidth then
            UIDropDownMenu_SetWidth(dropdown, math.max(120, math.ceil(textWidth + 16)))
        end
        if modern and dropdown.SetEnabled then
            dropdown:SetEnabled(not disabled)
        elseif UIDropDownMenu_DisableDropDown and UIDropDownMenu_EnableDropDown then
            if disabled then
                UIDropDownMenu_DisableDropDown(dropdown)
            else
                UIDropDownMenu_EnableDropDown(dropdown)
            end
        end
        label:SetAlpha(disabled and 0.4 or 1)
    end

    if modern then
        local DD = _G.FluxBlizzardDropdown
        if DD and DD.InstallGamepadClick then
            DD.InstallGamepadClick(dropdown, function()
                local items = getItems and getItems() or {}
                local entries = {}
                for i = 1, #items do
                    local item = items[i]
                    local pick = item.value
                    local text = item.text or tostring(pick or "")
                    entries[#entries + 1] = {
                        text = text,
                        checked = function()
                            return value == pick
                        end,
                        disabled = function()
                            return disabled
                        end,
                        func = function()
                            value = pick
                            SetBlizzardDropdownText(dropdown, text)
                            if onChange then
                                onChange(pick)
                            end
                        end,
                    }
                end
                return entries
            end)
        end
        dropdown:SetupMenu(function(_, root)
            if root.SetScrollMode then
                root:SetScrollMode(240)
            end
            local items = getItems and getItems() or {}
            for i = 1, #items do
                local item = items[i]
                local pick = item.value
                local text = item.text or tostring(pick or "")
                root:CreateRadio(text, function()
                    return value == pick
                end, function()
                    value = pick
                    SetBlizzardDropdownText(dropdown, text)
                    if onChange then
                        onChange(pick)
                    end
                end)
            end
        end)
    elseif UIDropDownMenu_Initialize and UIDropDownMenu_CreateInfo and UIDropDownMenu_AddButton then
        UIDropDownMenu_Initialize(dropdown, function(_, level)
            local items = getItems and getItems() or {}
            for i = 1, #items do
                local item = items[i]
                local info = UIDropDownMenu_CreateInfo()
                info.text = item.text or tostring(item.value or "")
                info.checked = value == item.value
                info.func = function()
                    value = item.value
                    if UIDropDownMenu_SetText then
                        UIDropDownMenu_SetText(dropdown, info.text)
                    end
                    if onChange then
                        onChange(item.value)
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end

    row:HookScript("OnSizeChanged", Display)
    AttachTooltip(row, function() return row._title end, function() return row._desc end)
    AttachTooltip(dropdown, function() return row._title end, function() return row._desc end)

    row.SetLabel = function(_, text)
        row._title = text or ""
        label:SetText(row._title)
    end
    row.SetDescription = function(_, text)
        row._desc = text or ""
    end
    row.SetGetter = function(_, fn)
        getItems = fn
        Display()
    end
    row.SetValue = function(_, v)
        value = v
        Display()
    end
    row.SetDisabled = function(_, d)
        disabled = d and true or false
        Display()
    end
    row.SetOnChange = function(_, fn)
        onChange = fn
    end
    row.RefreshAccent = Display
    W.OnAccent(Display)
    Display()
    return row
end

local function FormatNumber(value, step, isPercent)
    value = tonumber(value) or 0
    if isPercent then
        return string.format("%d%%", math.floor(value * 100 + 0.5))
    end
    step = tonumber(step) or 1
    if step >= 1 then
        return tostring(math.floor(value + 0.5))
    end
    if step >= 0.1 then
        return string.format("%.2f", value)
    end
    return string.format("%.2f", value)
end

function W.CreateSlider(parent)
    local row = W.CreateRow(parent, W.ROW_H)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    label:SetPoint("LEFT", 12, 0)

    local slider = CreateFrame("Slider", nil, row)
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(150, 16)
    slider:SetPoint("RIGHT", -12, 0)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetHeight(4)
    track:SetPoint("LEFT", slider, "LEFT", 0, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    Solid(track, 1, 1, 1, 0.16)

    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(4)
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)
    slider.fill = fill

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(14, 14)
    Solid(thumb, 0.95, 0.95, 0.95, 1)
    slider:SetThumbTexture(thumb)

    local valueText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueText:SetPoint("RIGHT", slider, "LEFT", -8, 0)
    valueText:SetJustifyH("RIGHT")
    valueText:SetWidth(48)
    label:SetPoint("RIGHT", valueText, "LEFT", -8, 0)

    local minV, maxV, stepV = 0, 1, 1
    local isPercent = false
    local disabled = false
    local onChange
    local onCommit

    local function PaintFill()
        local v = slider:GetValue() or minV
        local span = (maxV - minV)
        local pct = span ~= 0 and (v - minV) / span or 0
        if pct < 0 then pct = 0 end
        if pct > 1 then pct = 1 end
        local r, g, b = W.Accent()
        Solid(fill, r, g, b, disabled and 0.35 or 0.9)
        fill:SetWidth(math.max(1, (track:GetWidth() or slider:GetWidth() or 1) * pct))
        valueText:SetText(FormatNumber(v, stepV, isPercent))
        label:SetAlpha(disabled and 0.4 or 1)
        valueText:SetAlpha(disabled and 0.4 or 0.85)
    end

    slider:SetScript("OnValueChanged", function(_, value)
        PaintFill()
        if row._setting or disabled or not onChange then
            return
        end
        onChange(value)
    end)
    slider:SetScript("OnMouseUp", function()
        if onCommit and not disabled then
            onCommit(slider:GetValue())
        end
    end)

    AttachTooltip(row, function() return row._title end, function() return row._desc end)

    row.SetLabel = function(_, text)
        row._title = text or ""
        label:SetText(row._title)
    end
    row.SetDescription = function(_, text)
        row._desc = text or ""
    end
    row.Configure = function(_, minValue, maxValue, step, percent)
        minV = tonumber(minValue) or 0
        maxV = tonumber(maxValue) or 100
        if maxV < minV then
            maxV = minV
        end
        stepV = tonumber(step) or 0
        isPercent = percent and true or false
        slider:SetMinMaxValues(minV, maxV)
        if stepV > 0 then
            slider:SetValueStep(stepV)
            if slider.SetObeyStepOnDrag then
                slider:SetObeyStepOnDrag(true)
            end
        elseif slider.SetObeyStepOnDrag then
            slider:SetObeyStepOnDrag(false)
        end
        PaintFill()
    end
    row.SetValue = function(_, value)
        value = tonumber(value) or minV
        if value < minV then value = minV end
        if value > maxV then value = maxV end
        row._setting = true
        slider:SetValue(value)
        row._setting = false
        PaintFill()
    end
    row.SetDisabled = function(_, d)
        disabled = d and true or false
        slider:EnableMouse(not disabled)
        PaintFill()
    end
    row.SetOnChange = function(_, fn)
        onChange = fn
    end
    row.SetOnCommit = function(_, fn)
        onCommit = fn
    end
    row.RefreshAccent = PaintFill
    W.OnAccent(PaintFill)
    row.Configure(0, 1, 0.1, false)
    return row
end

function W.CreateColor(parent)
    local row = W.CreateRow(parent, W.ROW_H)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    label:SetPoint("LEFT", 12, 0)

    local swatch = CreateFrame("Button", nil, row)
    swatch:SetSize(22, 22)
    swatch:SetPoint("RIGHT", -12, 0)
    local tex = swatch:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 1, -1)
    tex:SetPoint("BOTTOMRIGHT", -1, 1)
    local border = swatch:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    Solid(border, 1, 1, 1, 0.35)
    label:SetPoint("RIGHT", swatch, "LEFT", -10, 0)

    local r, g, b, a = 1, 1, 1, 1
    local hasAlpha = false
    local disabled = false
    local onChange

    local function Paint()
        Solid(tex, r, g, b, 1)
        label:SetAlpha(disabled and 0.4 or 1)
        swatch:SetAlpha(disabled and 0.4 or 1)
    end

    local function OpenPicker()
        if disabled then
            return
        end
        local prev = { r = r, g = g, b = b, opacity = a }
        local function Apply(nr, ng, nb, na)
            r, g, b = nr, ng, nb
            if hasAlpha and na then
                a = na
            end
            Paint()
            if onChange then
                onChange(r, g, b, a)
            end
        end
        local function Revert()
            Apply(prev.r, prev.g, prev.b, prev.opacity)
        end
        if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b,
                opacity = a,
                hasOpacity = hasAlpha,
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    local na = a
                    if hasAlpha and ColorPickerFrame.GetColorAlpha then
                        na = ColorPickerFrame:GetColorAlpha()
                    end
                    Apply(nr, ng, nb, na)
                end,
                cancelFunc = function()
                    Revert()
                end,
            })
            return
        end
        if not ColorPickerFrame then
            return
        end
        ColorPickerFrame.hasOpacity = hasAlpha and true or false
        ColorPickerFrame.func = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            Apply(nr, ng, nb, a)
        end
        ColorPickerFrame.cancelFunc = function(previous)
            if type(previous) == "table" then
                Apply(previous.r or prev.r, previous.g or prev.g, previous.b or prev.b, previous.opacity or prev.opacity)
            else
                Revert()
            end
        end
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end

    swatch:SetScript("OnClick", OpenPicker)
    AttachTooltip(row, function() return row._title end, function() return row._desc end)

    row.SetLabel = function(_, text)
        row._title = text or ""
        label:SetText(row._title)
    end
    row.SetDescription = function(_, text)
        row._desc = text or ""
    end
    row.SetHasAlpha = function(_, v)
        hasAlpha = v and true or false
    end
    row.SetValue = function(_, nr, ng, nb, na)
        r = tonumber(nr) or 1
        g = tonumber(ng) or 1
        b = tonumber(nb) or 1
        a = tonumber(na) or 1
        Paint()
    end
    row.SetDisabled = function(_, d)
        disabled = d and true or false
        swatch:EnableMouse(not disabled)
        Paint()
    end
    row.SetOnChange = function(_, fn)
        onChange = fn
    end
    Paint()
    return row
end

function W.CreateButton(parent)
    local row = W.CreateRow(parent, W.ROW_H)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    label:SetPoint("LEFT", 12, 0)

    local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btn:SetSize(180, 22)
    btn:SetPoint("RIGHT", -12, 0)
    label:SetPoint("RIGHT", btn, "LEFT", -10, 0)

    local disabled = false
    local onClick

    -- UIPanelButtonTemplate end caps cover the outer ~20px on each side.
    local function FitButton()
        local fs = btn.GetFontString and btn:GetFontString()
        local textWidth = 0
        if fs then
            if fs.GetUnboundedStringWidth then
                textWidth = fs:GetUnboundedStringWidth() or 0
            else
                textWidth = fs:GetStringWidth() or 0
            end
        end
        local want = math.max(96, math.ceil(textWidth + 48))
        local rowWidth = row:GetWidth() or 0
        if rowWidth > 48 then
            want = math.min(want, math.max(96, rowWidth - 24))
        end
        btn:SetWidth(want)
    end

    btn:SetScript("OnClick", function()
        if disabled then
            return
        end
        ClickSound()
        if onClick then
            onClick()
        end
    end)
    row:HookScript("OnSizeChanged", FitButton)
    AttachTooltip(row, function() return row._title end, function() return row._desc end)

    row.SetLabel = function(_, text)
        row._title = text or ""
        label:SetText(row._title)
    end
    row.SetButtonText = function(_, text)
        btn:SetText(text or "")
        FitButton()
    end
    row.SetDescription = function(_, text)
        row._desc = text or ""
    end
    row.SetDisabled = function(_, d)
        disabled = d and true or false
        btn:SetEnabled(not disabled)
        label:SetAlpha(disabled and 0.4 or 1)
    end
    row.SetOnClick = function(_, fn)
        onClick = fn
    end
    return row
end

function W.CreateInput(parent)
    local row = W.CreateRow(parent, W.ROW_H)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    label:SetPoint("LEFT", 12, 0)

    local box = CreateFrame("EditBox", nil, row, BackdropTemplateMixin and "BackdropTemplate" or nil)
    box:SetSize(180, 22)
    box:SetPoint("RIGHT", -12, 0)
    box:SetAutoFocus(false)
    box:SetFontObject(GameFontHighlightSmall)
    box:SetTextInsets(6, 6, 0, 0)
    if box.SetBackdrop then
        box:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        box:SetBackdropColor(0.02, 0.03, 0.04, 0.9)
        box:SetBackdropBorderColor(1, 1, 1, 0.16)
    end
    label:SetPoint("RIGHT", box, "LEFT", -10, 0)

    local disabled = false
    local onCommit

    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if not disabled and onCommit then
            onCommit(self:GetText() or "")
        end
    end)
    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    AttachTooltip(row, function() return row._title end, function() return row._desc end)

    row.SetLabel = function(_, text)
        row._title = text or ""
        label:SetText(row._title)
    end
    row.SetDescription = function(_, text)
        row._desc = text or ""
    end
    row.SetValue = function(_, text)
        box:SetText(text or "")
    end
    row.SetDisabled = function(_, d)
        disabled = d and true or false
        box:EnableMouse(not disabled)
        label:SetAlpha(disabled and 0.4 or 1)
        box:SetAlpha(disabled and 0.4 or 1)
    end
    row.SetOnCommit = function(_, fn)
        onCommit = fn
    end
    return row
end

function W.CreateMoreButton(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(28)
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", 0, 0)
    row.text = text
    local function Paint()
        local r, g, b = W.Accent()
        text:SetTextColor(r, g, b)
    end
    row.SetOpen = function(_, open)
        text:SetText(open and "Fewer options" or "More options")
        Paint()
    end
    row:SetScript("OnClick", function()
        ClickSound()
        if row._onClick then
            row._onClick()
        end
    end)
    row.SetOnClick = function(_, fn)
        row._onClick = fn
    end
    W.OnAccent(Paint)
    row.SetOpen(false)
    return row
end

function W.CreateScroll(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    if scroll.SetClipsChildren then
        scroll:SetClipsChildren(true)
    end
    local child = CreateFrame("Frame", nil, scroll)
    child:SetHeight(1)
    scroll:SetScrollChild(child)

    -- Ace embeds (binding browser, meter layout) walk parents for an Ace-style ScrollFrame.
    scroll.obj = {
        type = "ScrollFrame",
        frame = scroll,
        scrollframe = scroll,
        content = child,
    }

    local bar = CreateFrame("Slider", nil, scroll)
    bar:SetOrientation("VERTICAL")
    bar:SetWidth(8)
    bar:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", -2, -4)
    bar:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", -2, 4)
    bar:SetValueStep(1)
    bar:SetMinMaxValues(0, 0)
    bar:SetValue(0)
    if bar.SetObeyStepOnDrag then
        bar:SetObeyStepOnDrag(true)
    end
    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 28)
    Solid(thumb, 1, 1, 1, 0.27)
    bar:SetThumbTexture(thumb)
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    Solid(track, 1, 1, 1, 0.06)

    local function ApplyScroll(value)
        local maxScroll = select(2, bar:GetMinMaxValues())
        value = math.max(0, math.min(maxScroll or 0, value or 0))
        bar:SetValue(value)
        scroll:SetVerticalScroll(value)
    end

    bar:SetScript("OnValueChanged", function(_, value)
        scroll:SetVerticalScroll(value or 0)
    end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        ApplyScroll((bar:GetValue() or 0) - delta * 48)
    end)

    local api = {}
    function api:SetContentHeight(h)
        h = math.max(1, h or 1)
        child:SetHeight(h)
        local view = scroll:GetHeight() or 0
        local maxScroll = math.max(0, h - view)
        bar:SetMinMaxValues(0, maxScroll)
        if (bar:GetValue() or 0) > maxScroll then
            bar:SetValue(maxScroll)
            scroll:SetVerticalScroll(maxScroll)
        end
        bar:SetShown(maxScroll > 1)
    end
    function api:GetContentWidth()
        local w = scroll:GetWidth() or 0
        if w < 40 then
            w = 40
        end
        return w - 16
    end
    function api:GetViewHeight()
        return scroll:GetHeight() or 0
    end
    function api:ResetScroll()
        bar:SetValue(0)
        scroll:SetVerticalScroll(0)
    end

    api.scroll = scroll
    api.child = child
    return api
end
