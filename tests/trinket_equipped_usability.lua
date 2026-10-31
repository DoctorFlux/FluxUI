-- Exercise the loaded EBS paint path for equipped /use 13|14 trinket faces.
local checks = 0
local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end

local state = { itemUsable = false, spellUsable = true, dead = false }
local env = setmetatable({}, { __index = _G })
env._G = env
env.FluxButton = {}
env.UnitIsDeadOrGhost = function() return state.dead end
env.UnitIsDead = function() return state.dead end
local flux = {
    EBS = { buttons = {}, badges = {} },
    Inventory = {
        IsReliable = function() return true end,
        GetCount = function() return 0 end, -- Equipped gear is outside bags.
        GetLiveCount = function() return 0 end,
    },
    Item = {
        IsUsable = function() return state.itemUsable, false end,
        GetSpell = function()
            if state.hasSpell == false then return nil, nil end
            return "Use Effect", 123
        end,
        IsConsumable = function() return false end,
        UsesConsumableCharges = function() return false end,
    },
    Spell = { IsUsable = function() return state.spellUsable, false end },
}
local source = "ExtraButtonSystem/Engine/Paint.lua"
if arg and arg[1] == "--source" then source = assert(arg[2]) end
assert(loadfile(source, "t", env))("_FluxUI", { Flux = flux })

local function face(slot)
    local icon = {}
    function icon:SetVertexColor(r) self.color = r end
    function icon:SetDesaturated(value) self.desaturated = value end
    local id = 900001
    return {
        WIcon = icon, WNormalTexture = { SetVertexColor = function() end },
        Widget = {}, categoryScope = "account", ActionType = "macrotext",
        ActionValue = "/use " .. (slot or 13), MacroMode = "item", ItemId = id,
        _fluxManagedFaceItemId = id, inventorySlot = slot,
    }
end

local equipped = face(13)
flux.EBS.Paint.UpdateUsable(equipped)
check(equipped.WIcon.color, 1, "ready equipped trinket stays bright")
state.spellUsable = false
flux.EBS.Paint.UpdateUsable(equipped)
check(equipped.WIcon.color, 0.4, "genuinely unusable spell remains dark")
state.spellUsable = true
flux.EBS.Paint.UpdateUsable(equipped)
check(equipped.WIcon.color, 1, "equipped trinket recovers")
local second = face(14)
flux.EBS.Paint.UpdateUsable(second)
check(second.WIcon.color, 1, "second equipped slot stays bright")
state.hasSpell = false
flux.EBS.Paint.UpdateUsable(second)
check(second.WIcon.color, 1, "passive equipped trinket stays bright")
state.hasSpell = true

local ordinary = face(nil)
flux.EBS.Paint.UpdateUsable(ordinary)
check(ordinary.WIcon.color, 0.4, "ordinary unowned macro stays dark")

local gem = face(nil)
gem.ActionType, gem.ActionValue, gem.IsManaGemButton = "item", gem.ItemId, true
flux.Inventory.GetCount = function() return 1 end
flux.Inventory.GetLiveCount = function() return 1 end
flux.EBS.Paint.UpdateUsable(gem)
check(gem.WIcon.color, 0.4, "combat gem still honors unusable item")
state.dead = true
state.itemUsable = true
flux.EBS.Paint.UpdateUsable(gem)
check(gem.WIcon.color, 0.4, "dead combat gem remains dark")

print("trinket equipped usability: " .. checks .. " checks")
