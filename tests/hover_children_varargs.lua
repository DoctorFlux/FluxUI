-- Execute production fallback scan with native vararg GetChildren shape.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close()
    return s:gsub("\r\n", "\n")
end
local source = read("Binding/Input/FluxMouseoverKeybind.lua")
local first = assert(source:find("local function FrameUnderMouse(f)", 1, true))
local last = assert(source:find("function FluxMouseoverKeybind:HasHoverRoutingActive()", first, true))
local scanBody = source:sub(first, last - 1)
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
for _, branch in ipairs({ "live", "forever", "classic_era", "classic_anniversary", "classic" }) do
    local e = setmetatable({}, { __index = _G }); e._G = e
    local state = { parent = false, child1 = false, child2 = true, forbidden = false, hidden = false }
    local parent = { name = "parent" }
    local child1, child2 = { name = "child1" }, { name = "child2" }
    for _, frame in ipairs({ parent, child1, child2 }) do
        function frame:IsForbidden() return state.forbidden end
        function frame:IsShown() return not state.hidden end
        function frame:IsMouseOver() return state[self.name] end
        function frame:IsDescendantOf(owner) return self ~= owner and owner == parent end
    end
    function parent:GetChildren() return child1, child2 end
    local scan = assert(load("local registeredFrames = ...\n" .. scanBody .. "\nreturn _PerformHoverContextScan",
        "@production-hover-context-scan", "t", e))({ parent })
    e.GetMouseFoci = function() return { child2 } end
    check(scan() == true, branch .. " modern GetMouseFoci control finds hovered descendant")
    e.GetMouseFoci = nil
    check(scan() == true, branch .. " vararg fallback finds hovered second child")
    state.child1, state.child2 = true, false
    check(scan() == true, branch .. " vararg fallback finds hovered first child")
    state.parent, state.child1 = true, false
    check(scan() == true, branch .. " parent hover fallback control works")
    state.parent = false
    check(scan() == false, branch .. " no hovered frame control works")
    e.GetMouseFoci = function() error("modeled unavailable focus API") end
    state.child2 = true
    check(scan() == true, branch .. " focus API failure still finds hovered child")
    state.forbidden = true
    check(scan() == false, branch .. " forbidden hover is excluded")
    state.forbidden, state.hidden = false, true
    check(scan() == false, branch .. " hidden hover is excluded")
    state.hidden = false
    function parent:GetChildren() return end
    check(scan() == false, branch .. " zero child returns are safe")
    function parent:GetChildren() return child2 end
    check(scan() == true, branch .. " one child return is consumed")
    function parent:GetChildren() error("modeled denied child enumeration") end
    check(scan() == false, branch .. " child enumeration denial is contained")
    print(("METRIC hover branch=%s cases=11 assertions_recorded=true"):format(branch))
end
print(("SUMMARY checks=%d failures=%d"):format(checks, failures))
os.exit(failures > 0 and 1 or 0)
