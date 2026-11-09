local LBG = LibStub("LibButtonGlow-1.0", true)
if not LBG then return end

local addonName, ns = ...

_G.FluxButtonGlowExt = _G.FluxButtonGlowExt or {}
local Ext = _G.FluxButtonGlowExt

Ext.columnGlowOwner = Ext.columnGlowOwner or {}

function Ext.TransferGlow(fromButton, toButton)
    if not fromButton or not toButton then return end
    if fromButton.__LBGoverlay then
        LBG.HideOverlayGlow(fromButton, true)
    end
    LBG.ShowOverlayGlow(toButton)
end

function Ext.SetColumnGlowOwner(col, button)
    local prev = Ext.columnGlowOwner[col]
    if prev and prev ~= button and prev.__LBGoverlay then
        LBG.HideOverlayGlow(prev, true)
    end
    Ext.columnGlowOwner[col] = button
end

function Ext.GetColumnGlowOwner(col)
    return Ext.columnGlowOwner[col]
end

function Ext.ClearColumnGlow(col)
    local owner = Ext.columnGlowOwner[col]
    if owner and owner.__LBGoverlay then
        LBG.HideOverlayGlow(owner, true)
    end
    Ext.columnGlowOwner[col] = nil
end

function Ext.ShowOnBadge(badgeFrame, skipAnim)
    if not badgeFrame then return end
    LBG.ShowOverlayGlow(badgeFrame, skipAnim)
end

function Ext.HideOnBadge(badgeFrame, instant)
    if not badgeFrame then return end
    LBG.HideOverlayGlow(badgeFrame, instant)
end
