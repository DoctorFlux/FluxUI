-- Native artwork is resolved by the running client's SharedXML templates.
-- Forever supplies its Camelot NineSlice overrides; Classic uses its own family.
local _, ns = ...
local Skin = {}
ns.FluxOptionsSkin = Skin

function Skin.IsForever()
    local flux = ns.Flux or _G.Flux
    local client = flux and flux.Client
    return client and (client.isForever or client.isCamelot) and true or false
end

local function Cover(texture, atlas, width, height)
    local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
    if not info or not info.width or not info.height or width <= 0 or height <= 0 then return end
    texture:SetAtlas(atlas)
    -- The portrait template's rock texture tiles; a cropped atlas must not.
    texture:SetHorizTile(false)
    texture:SetVertTile(false)
    local scale = math.max(width / info.width, height / info.height)
    local left, right = info.leftTexCoord or 0, info.rightTexCoord or 1
    local top, bottom = info.topTexCoord or 0, info.bottomTexCoord or 1
    local u = (right - left) * width / (scale * info.width)
    local v = (bottom - top) * height / (scale * info.height)
    local x = left + (right - left - u) / 2
    local y = top + (bottom - top - v) / 2
    texture:SetTexCoord(x, x + u, y, y + v)
end

local function FitArt(frame)
    if frame.Bg then
        Cover(frame.Bg, "ui-journeys-bg", frame:GetWidth() - 4, frame:GetHeight() - 23)
        frame.Bg:Show()
        frame.Bg:SetAlpha(1)
    end
end

function Skin.CreateWindow(name, parent)
    local frame = CreateFrame("Frame", name, parent, "PortraitFrameTemplate")
    -- The native template initializes its border. Classic has no NineSlice
    -- layout named PortraitFrameTemplate; its border uses separate textures.
    if frame.SetTitle then
        frame:SetTitle("FluxUI")
    elseif frame.TitleText then
        frame.TitleText:SetText("FluxUI")
    end
    local portrait = frame.PortraitContainer and frame.PortraitContainer.portrait or frame.portrait
    if portrait then
        portrait:SetTexture("Interface\\Icons\\INV_Misc_Gear_02")
    end
    if Skin.IsForever() then
        FitArt(frame)
        frame:HookScript("OnSizeChanged", FitArt)
    end
    return frame
end

function Skin.CreateInset(parent)
    return CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
end

function Skin.PaintTab(button, selected)
    if button._fluxMinimal then
        button:SetSelected(selected)
        return
    end
    -- Classic's top tabs and Mainline's panel tabs have different mixins.
    -- Their common PanelTemplates helpers retain the native art/state contract.
    if selected and PanelTemplates_SelectTab then
        PanelTemplates_SelectTab(button)
    elseif not selected and PanelTemplates_DeselectTab then
        PanelTemplates_DeselectTab(button)
    end
end

function Skin.CreateTab(name, parent)
    local minimal = Skin.IsForever()
    local button = CreateFrame("Button", name, parent, minimal and "MinimalTabTemplate" or "PanelTopTabButtonTemplate")
    button._fluxMinimal = minimal
    button.label = minimal and button.Text or button:GetFontString()
    return button
end

function Skin.SetTabText(button, text)
    if button._fluxMinimal then button.Text:SetText(text) else button:SetText(text) end
end

function Skin.SizeTab(button, width)
    if button._fluxMinimal then
        button:SetSize(width, 36)
    elseif PanelTemplates_TabResize then
        PanelTemplates_TabResize(button, 20, width)
    else
        button:SetWidth(width)
    end
    return button:GetWidth()
end

function Skin.StyleHeader(row, shade, sign)
    local W = ns.FluxOptionsWidgets
    if not Skin.IsForever() or not W.HasAtlas("common-button-list-collapseExpand") then return end
    shade:SetAtlas("common-button-list-collapseExpand")
    shade:SetVertexColor(1, 1, 1)
    shade:SetAlpha(1)
    if W.HasAtlas("common-button-list-plus") and W.HasAtlas("common-button-list-minus") then
        local icon = row:CreateTexture(nil, "OVERLAY")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", row, "LEFT", 10, 0)
        sign:Hide()
        row.SetExpanded = function(_, expanded) icon:SetAtlas(expanded and "common-button-list-minus" or "common-button-list-plus") end
        row:SetExpanded(true)
    end
end

function Skin.StyleScrollBar(bar, thumb)
    local W = ns.FluxOptionsWidgets
    if not Skin.IsForever() then return false end
    local names = { "minimal-scrollbar-track-top", "!minimal-scrollbar-track-middle", "minimal-scrollbar-track-bottom",
        "minimal-scrollbar-small-thumb-top", "minimal-scrollbar-small-thumb-middle", "minimal-scrollbar-small-thumb-bottom" }
    for _, name in ipairs(names) do if not W.HasAtlas(name) then return false end end
    local top, middle, bottom = bar:CreateTexture(nil, "BACKGROUND"), bar:CreateTexture(nil, "BACKGROUND"), bar:CreateTexture(nil, "BACKGROUND")
    top:SetAtlas(names[1]); top:SetSize(8, 8); top:SetPoint("TOPLEFT", bar, "TOPLEFT")
    bottom:SetAtlas(names[3]); bottom:SetSize(8, 8); bottom:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT")
    middle:SetAtlas(names[2]); middle:SetPoint("TOPLEFT", top, "BOTTOMLEFT"); middle:SetPoint("BOTTOMRIGHT", bottom, "TOPRIGHT")
    thumb:SetAtlas(names[5]); thumb:SetAlpha(1); thumb:SetVertexColor(1, 1, 1)
    local capTop, capBottom = bar:CreateTexture(nil, "OVERLAY"), bar:CreateTexture(nil, "OVERLAY")
    capTop:SetAtlas(names[4]); capTop:SetSize(8, 8); capTop:SetPoint("TOPLEFT", thumb, "TOPLEFT")
    capBottom:SetAtlas(names[6]); capBottom:SetSize(8, 8); capBottom:SetPoint("BOTTOMLEFT", thumb, "BOTTOMLEFT")
    return true
end

function Skin.StyleCategory(frame)
    local W = ns.FluxOptionsWidgets
    if Skin.IsForever() then
        W.ApplyBackdrop(frame, 0.055, 0.035, 0.015, 0.98, 0.48, 0.34, 0.16, 0.95)
    else
        W.ApplyBackdrop(frame, 0.04, 0.04, 0.04, 0.8, 0.34, 0.34, 0.34, 0.7)
    end
end

function Skin.StyleSystemButton(frame, isSystem)
    if not isSystem then return end
    Skin.StyleCategory(frame)
end

function Skin.PaintNav(button, selected, hover)
    local atlas = selected and "Options_List_Active" or hover and "Options_List_Hover"
    local W = ns.FluxOptionsWidgets
    if atlas and W.HasAtlas(atlas) then
        button.atlas:SetAtlas(atlas)
        button.atlas:Show()
    else
        button.atlas:Hide()
    end
    button.bar:SetShown(selected)
    W.Solid(button.bar, 1, 0.82, 0, 1)
    if selected then
        button.label:SetTextColor(1, 1, 1)
    else
        button.label:SetTextColor(1, 0.82, 0)
    end
    button.icon:SetVertexColor(1, 1, 1)
    -- The supplied sidebar reference requests an icon beside every fitting name,
    -- including Forever and the fixed system buttons.
    button.icon:Show()
end
