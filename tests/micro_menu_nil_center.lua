-- Native MicroButton_OnShow invokes Blizzard MicroMenu:Layout synchronously.
local source = assert(io.open("MicroMenu/FluxMicroMenu.lua", "r")):read("*a")
local start = assert(source:find("local function GetParkParentForLeftoverMicroMenuChild()", 1, true))
local finish = assert(source:find("-- Edit Mode re-lays out MicroMenu", start, true))
local parking = source:sub(start, finish - 1)

local menu = { children = {} }
local flux = { children = {}, buttons = {} }
local hidden = { children = {} }
local env = setmetatable({
    FluxMicroMenu = flux, FluxHiddenParent = hidden, MicroMenu = menu,
    InCombatLockdown = function() return false end, isRetail = false,
}, { __index = _G })
env._G = env
function menu:GetChildren() return table.unpack(self.children) end
function flux:ShouldLeaveBlizzardButtonShown() return false end
function menu:Layout()
    local first, last
    for _, child in ipairs(self.children) do
        if child.layoutIndex then
            if not first or child.layoutIndex < first.layoutIndex then first = child end
            if not last or child.layoutIndex > last.layoutIndex then last = child end
        end
    end
    if first then
        local firstX = first:GetCenter()
        local lastX = last:GetCenter()
        return firstX < lastX and first or last
    end
end
local function Button(name, index)
    local btn = { name = name, layoutIndex = index, parent = menu, shown = false }
    function btn:GetName() return self.name end
    function btn:GetCenter() if self.shown then return self.x, 100 end end
    function btn:SetParent(parent)
        for i, child in ipairs(self.parent.children) do
            if child == self then table.remove(self.parent.children, i); break end
        end
        self.parent = parent
        parent.children[#parent.children + 1] = self
    end
    function btn:Show()
        if not self.shown then
            self.shown = true
            menu:Layout() -- Classic MicroButton_OnShow does this even after reparenting.
        end
    end
    function btn:Hide()
        self.shown = false
        self.hides = (self.hides or 0) + 1
        menu:Layout() -- Classic MicroButton_OnHide has the same callback.
    end
    function btn:EnableMouse(value) self.mouse = value end
    menu.children[#menu.children + 1] = btn
    return btn
end
local socials = Button("SocialsMicroButton", 5)
local kept = Button("CharacterMicroButton", 1)
flux.buttons = { kept }
assert(not pcall(function() kept:Show() end), "old ordering reaches nil-center comparison")
kept.shown = false

local make = assert(load(parking .. "\nreturn ParkLeftoverMicroMenuLayoutChildren", "parking", "t", env))
local park = make()
kept:SetParent(flux)
park(true)
assert(socials.parent == flux and socials.hides == nil, "stage leftover without visibility callback")
assert(kept.parent == flux, "selected button leaves native container before parking")
kept.x = 20
assert(pcall(function() kept:Show() end), "Show after removing layout children is safe")
park()
assert(socials.parent == flux and socials.hides == 1 and socials.mouse == false,
    "finish parking staged leftover after kept buttons move")

local hijack = assert(source:find("local function HijackButtons()", 1, true))
local moveSelected = assert(source:find("btn:SetParent(FluxMicroMenu)", hijack, true))
local stage = assert(source:find("ParkLeftoverMicroMenuLayoutChildren(true)", hijack, true))
local hideUnused = assert(source:find("FluxMicroMenuConfig:ParkHiddenButtons", stage, true))
local layout = assert(source:find("    UpdateLayout()", stage, true))
assert(moveSelected < stage and stage < hideUnused and hideUnused < layout,
    "remove native layout children before any hidden-button callback or UpdateLayout")
local update = assert(source:find("local function UpdateLayout()", 1, true))
local move = assert(source:find("btn:SetParent(FluxMicroMenu)", update, true))
local show = assert(source:find("entry.btn:Show()", update, true))
assert(move < show, "reparent all kept buttons before any Show callback")
print("micro menu: nil-center Show ordering and staged native children pass")
