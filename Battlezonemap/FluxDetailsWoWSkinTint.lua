-- FluxDetailsWoWSkinTint.lua
-- Vertex-tints Details! "WoW Interface" skin chrome (cabecalho, side/bottom rails, rodape corners + bottom rail) with player class color.
-- Does not add borders, does not touch row/panel fills, and does not replace SuppressDetailsInstanceChrome.

local addonName = ...

FluxDetailsWoWSkinTint = FluxDetailsWoWSkinTint or {}

local instanceColorHooked = false
local statusBarColorHooked = false
local eventFrame

local function GetAlpha(inst)
    if inst and inst.color and type(inst.color[4]) == "number" then
        return inst.color[4]
    end
    return 1
end

function FluxDetailsWoWSkinTint.GetPlayerClassRGB()
    if FluxBorder and FluxBorder.GetThemedVertexRGB then
        return FluxBorder:GetThemedVertexRGB()
    end
    local _, classFilename = UnitClass("player")
    local c = classFilename and RAID_CLASS_COLORS[classFilename]
    if c then
        return c.r, c.g, c.b
    end
    return 0.6, 0.6, 0.6
end

local function TintTexture(tex, r, g, b, a)
    if not tex or not tex.SetVertexColor then return end
    pcall(function()
        tex:SetVertexColor(r, g, b)
        tex:SetAlpha(a)
    end)
end

local function CollectWoWInterfaceSkinTextures(inst)
    local bf = inst and inst.baseframe
    if not bf then return end
    local cab = bf.cabecalho
    if not cab then return end

    -- Top corners + header rail + side/bottom rails (Details InstanceColor set).
    -- Bottom corners + bottom rail: rodape pins + top_bg (same skin atlas; not row panel).
    local list = {
        cab.ball_r,
        cab.ball,
        cab.emenda,
        cab.top_bg,
        bf.barra_esquerda,
        bf.barra_direita,
        bf.barra_fundo,
    }

    local rod = bf.rodape
    if rod then
        list[#list + 1] = rod.esquerdo
        list[#list + 1] = rod.direita
        list[#list + 1] = rod.top_bg
        list[#list + 1] = rod.esquerdo_nostatusbar
        list[#list + 1] = rod.direita_nostatusbar
    end

    return list
end

function FluxDetailsWoWSkinTint.ApplyToInstance(inst)
    if not inst or not inst.baseframe then return end

    local r, g, b = FluxDetailsWoWSkinTint.GetPlayerClassRGB()
    local a = GetAlpha(inst)

    local textures = CollectWoWInterfaceSkinTextures(inst)
    if textures then
        for _, tex in ipairs(textures) do
            TintTexture(tex, r, g, b, a)
        end
    end

    local bf = inst.baseframe
    if bf.UPFrame and bf.UPFrame.SetAlpha then
        pcall(function() bf.UPFrame:SetAlpha(a) end)
    end

    local D = _G.Details
    local skin = D and inst.skin and D.skins and D.skins[inst.skin]
    local cab = bf.cabecalho
    if cab and cab.atributo_icon and cab.atributo_icon.SetAlpha then
        if not (skin and skin.icon_ignore_alpha) then
            pcall(function() cab.atributo_icon:SetAlpha(a) end)
        end
    end
end

function FluxDetailsWoWSkinTint.RefreshAllEmbeddedInstances()
    if not _G.FluxDetails or not FluxDetails.IsEmbedded or not FluxDetails:IsEmbedded() then
        return
    end
    local D = _G.Details
    if not D or not D.tabela_instancias then return end
    for _, inst in ipairs(D.tabela_instancias) do
        FluxDetailsWoWSkinTint.ApplyToInstance(inst)
    end
end

function FluxDetailsWoWSkinTint.EnsureInstanceColorHook()
    local D = _G.Details
    if not D then return end

    if not instanceColorHooked and type(D.InstanceColor) == "function" then
        instanceColorHooked = true
        hooksecurefunc(D, "InstanceColor", function(inst)
            if not _G.FluxDetails or not FluxDetails.IsEmbedded or not FluxDetails:IsEmbedded() then
                return
            end
            if not inst or not inst.baseframe then return end
            FluxDetailsWoWSkinTint.ApplyToInstance(inst)
        end)
    end

    -- Rodape corners/rail use the same textures StatusBarColor paints; re-tint after Details updates them.
    if not statusBarColorHooked and type(D.StatusBarColor) == "function" then
        statusBarColorHooked = true
        hooksecurefunc(D, "StatusBarColor", function(inst)
            if not _G.FluxDetails or not FluxDetails.IsEmbedded or not FluxDetails:IsEmbedded() then
                return
            end
            if not inst or not inst.baseframe then return end
            FluxDetailsWoWSkinTint.ApplyToInstance(inst)
        end)
    end

    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:SetScript("OnEvent", function()
            FluxDetailsWoWSkinTint.RefreshAllEmbeddedInstances()
        end)
    end
end
