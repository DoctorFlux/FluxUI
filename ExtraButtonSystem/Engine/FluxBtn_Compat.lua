--[[
    ExtraButtonSystem/Engine/FluxBtn_Compat.lua

    Cross-client probes for the button engine (Classic Era / Anniversary / post-DF).
]]

FluxBtn = FluxBtn or {}
local Compat = {}
FluxBtn.Compat = Compat

local major = 12
if GetBuildInfo then
    local version = GetBuildInfo()
    major = tonumber(version and version:match("^(%d+)")) or 12
end

Compat.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
Compat.isClassicEra = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
Compat.isAnniversary = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
    or (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
    or (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
Compat.isPostDF = major >= 10
Compat.isMidnight = major >= 12
Compat.hasC_Spell = (C_Spell ~= nil and type(C_Spell.GetSpellInfo) == "function")
Compat.hasC_Item = (C_Item ~= nil and type(C_Item.GetItemCount) == "function")
Compat.hasC_SpellBook = (C_SpellBook ~= nil)
Compat.useItemLinkAttribute = Compat.isPostDF or Compat.isAnniversary or Compat.isRetail
Compat.useNativeFlyout = Compat.isClassicEra and not Compat.isPostDF
Compat.useCustomFlyout = not Compat.useNativeFlyout
Compat.usePressAndHold = Compat.isPostDF or Compat.isRetail

--- Secure item attribute value: link on modern clients, name on Classic Era.
function Compat.GetItemAttributeValue(itemID, itemLink, itemName)
    if Compat.useItemLinkAttribute then
        if itemLink and itemLink ~= "" then
            return itemLink
        end
        if itemID and GetItemInfo then
            local _, link = GetItemInfo(itemID)
            if link then
                return link
            end
        end
    end
    if itemName and itemName ~= "" then
        return itemName
    end
    if itemID and GetItemInfo then
        local name = GetItemInfo(itemID)
        return name
    end
    return itemLink or itemName or itemID
end

function Compat.After(delay, fn)
    if FluxAPICompat and FluxAPICompat.After then
        FluxAPICompat.After(delay, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

_G.FluxBtn = FluxBtn
