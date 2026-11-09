-- Run the loaded EBS paint path with owned combat gem/stone faces.
local checks = 0
local function check(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end

local state = { dead = false, ghost = false, usable = true, count = 1, reliable = true }
local env = setmetatable({}, { __index = _G })
env._G = env
env.FluxButton = {}
env.UnitIsDeadOrGhost = function() return state.dead or state.ghost end
env.UnitIsDead = function() return state.dead end
local flux = {
    EBS = { buttons = {}, badges = {} },
    Inventory = {
        IsReliable = function() return state.reliable end,
        GetCount = function(id) return id == state.itemID and state.count or 0 end,
        GetLiveCount = function(id) return id == state.itemID and state.count or 0 end,
    },
    Item = {
        IsUsable = function() return state.usable, false end,
        IsConsumable = function() return true end,
        UsesConsumableCharges = function() return false end,
    },
}
local source = "ExtraButtonSystem/Engine/Paint.lua"
if arg and arg[1] == "--source" then source = assert(arg[2]) end
local chunk = assert(loadfile(source, "t", env))
chunk("_FluxUI", { Flux = flux })

local function button(kind, itemID, actionType)
    state.itemID = itemID
    local icon = {}
    function icon:SetVertexColor(r, g, b) self.color = r end
    function icon:SetDesaturated(v) self.desaturated = v end
    local ring = { SetVertexColor = function() end }
    return {
        WIcon = icon, WNormalTexture = ring, Widget = {}, categoryScope = "account",
        ActionType = actionType or "item", ActionValue = itemID, ItemId = itemID,
        IsManaGemButton = kind == "gem", IsHealthstoneButton = kind == "stone",
    }
end

local function paint(btn, expected, label)
    flux.EBS.Paint.UpdateUsable(btn)
    check(btn.WIcon.color, expected, label)
end

local gem = button("gem", 8008)
paint(gem, 1, "owned usable gem")
state.dead = true
paint(gem, 0.4, "dead gem")
state.dead, state.ghost = false, true
paint(gem, 0.4, "ghost gem")
state.ghost = false
paint(gem, 1, "revived gem")
state.usable = false
paint(gem, 0.4, "situationally unusable gem")
state.usable = true
paint(gem, 1, "gem usable again")
state.count = 0
paint(gem, 0.4, "empty gem")
state.count = 1
local sequence = button("gem", 8008, "macrotext")
state.usable = false
paint(sequence, 0.4, "Vanilla gem castsequence")

state.usable = true
local stone = button("stone", 5512)
paint(stone, 1, "owned usable stone")
state.dead = true
paint(stone, 0.4, "dead stone")
state.dead = false
state.usable = false
paint(stone, 0.4, "situationally unusable stone")
state.usable = true
paint(stone, 1, "stone usable again")
state.count = 0
paint(stone, 0.4, "empty stone")
state.count, state.usable, state.reliable = 1, false, false
paint(stone, 1, "loading-screen unreliable bag state")

print("combat grid conjured usability: " .. checks .. " checks")
