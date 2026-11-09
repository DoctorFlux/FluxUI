-- FluxSalvage_Colors.lua
-- Glow colors per salvage action. Same on live, Forever, Era, and Anniversary.

FluxSalvage = FluxSalvage or {}
local S = FluxSalvage

S.Colors = S.Colors or {}

local mage = RAID_CLASS_COLORS and RAID_CLASS_COLORS.MAGE
local mageR = mage and mage.r or 0.41
local mageG = mage and mage.g or 0.80
local mageB = mage and mage.b or 0.94

S.Colors.prospectable = CreateColor(1, 1 / 3, 1 / 3) -- red
S.Colors.millable = CreateColor(1 / 2, 1, 1 / 2) -- green
S.Colors.comprehensible = CreateColor(mageR, mageG, mageB) -- mage blue
S.Colors.openable = CreateColor(1, 1, 1)
S.Colors.scrappable = CreateColor(0, 1, 1)
S.Colors.crushable = CreateColor(1, 1 / 3, 1 / 3)
S.Colors.disenchantable = CreateColor(1 / 2, 1 / 2, 1) -- purple
S.Colors.transmutable = CreateColor(1 / 5, 1 / 2, 1)
