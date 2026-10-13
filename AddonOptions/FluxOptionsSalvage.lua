local addonName, ns = ...

local function NotifySalvageSettingsChanged()
    local S = _G.FluxSalvage
    if not S then
        return
    end
    if S.IsEnabled() then
        S.HookTooltip()
        if S.HookBagButtons then
            S.HookBagButtons()
        end
    else
        S.HideOverlay()
    end
    if S.UpdateAttributeDriver then
        S.UpdateAttributeDriver()
    end
end

local function BuildSalvageOptions()
    return {
    name = "Salvage",
    type = "group",
    order = 22,
    args = {
        intro = {
            type = "description",
            name = "One-click milling, prospecting, disenchanting, Comprehend Scroll, lockpicking, and more.\n"
                .. "Hold the modifier key over a bag item to show the salvage overlay, then click.\n"
                .. "Forever: Comprehend Scroll is a learned mage spell (not a profession). If you know the spell, Alt-hover scrolls that say Requires Comprehension; the Comprehension secondary skill rank must meet the item. Mill/prospect/DE still use classic profession spells and rank. Combined bags use the bag-slot overlay.\n",
            order = 0,
            fontSize = "medium",
            width = "full",
        },
        enabled = {
            type = "toggle",
            name = "Enable salvage overlay",
            desc = "Show the one-click salvage overlay when holding the modifier key over bag items.",
            order = 1,
            width = "full",
            get = function()
                local S = _G.FluxSalvage
                return S and S.IsEnabled() or false
            end,
            set = function(_, val)
                local S = _G.FluxSalvage
                if not S then
                    return
                end
                S.SetEnabled(val)
                NotifySalvageSettingsChanged()
            end,
        },
        modifier = {
            type = "select",
            name = "Modifier key",
            desc = "Hold this key combination while hovering a bag item to activate salvage.",
            order = 2,
            width = "full",
            values = {
                ALT = ALT_KEY or "Alt",
                CTRL = (ALT_KEY_TEXT or "Alt") .. " + " .. (CTRL_KEY or "Ctrl"),
                SHIFT = (ALT_KEY_TEXT or "Alt") .. " + " .. (SHIFT_KEY or "Shift"),
            },
            get = function()
                local S = _G.FluxSalvage
                return S and S.GetModifier() or "ALT"
            end,
            set = function(_, val)
                local S = _G.FluxSalvage
                if not S then
                    return
                end
                S.SetModifier(val)
            end,
        },
    },
}
end

function _G.FluxOptionsSalvageGroup()
    local group = BuildSalvageOptions()
    group.name = "Salvage"
    group.desc = "One-click mill, prospect, disenchant, and similar bag actions."
    group.order = 3
    return group
end
