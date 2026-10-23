-- Actual registration helper and supplied native unit-click handlers. Hardware
-- dispatch and the game's protected execution still require client testing.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local source = read("Binding/Input/FluxMouseoverKeybind.lua")
local a = assert(source:find("local function RegisterFrameClickEdges", 1, true))
local b = assert(source:find("-- ---------------------------------------------------------------------------", a, true))
local helper = source:sub(a, b - 1)
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function exercise(branch, body)
    local actions, casts, registrations = {}, 0, {}
    local env = setmetatable({}, { __index = _G }); env._G = env
    local frame = { attributes = { ["*type1"] = "target", ["*type2"] = "togglemenu", unit = "player" },
        RegisterForClicks = function(_, ...) registrations = {}; for _, edge in ipairs({ ... }) do registrations[edge] = true end end }
    local register = assert(load((body or helper) .. "\nreturn RegisterFrameClickEdges", "@click-edges", "t", env))()
    local native = read("../__AddonsForRef/wow-ui-source-" .. branch .. "/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua")
    local nativeStart = assert(native:find("function SecureUnitButton_OnClick", 1, true))
    native = native:sub(nativeStart)
    local kind = 3
    env.Enum = { ClickBindingType = { None = 0, Spell = 1, Macro = 2, Interaction = 3, PetAction = 4 } }
    env.MakeModifiers = function() return 0 end
    env.C_ClickBindings = { GetBindingType = function() return kind end,
        GetEffectiveInteractionButton = function(button) return button end,
        ExecuteBinding = function() casts = casts + 1 end }
    env.SecureButton_GetModifiedAttribute = function(_, _, button) return button == "LeftButton" and "target" or "togglemenu" end
    env.SecureButton_GetModifiedUnit = function() return "player" end
    env.SpellIsTargeting = function() return false end
    env.OnActionButtonClick = function(_, button, down) actions[#actions + 1] = { button = button, down = down } end
    assert(load(native, "@native-unit-click-" .. branch, "t", env))()
    local function click(button)
        for _, edge in ipairs({ { "Down", true }, { "Up", false } }) do
            if registrations[button .. edge[1]] or registrations["Any" .. edge[1]] then
                env.SecureUnitButton_OnClick(frame, button, edge[2])
            end
        end
    end
    register(frame); click("LeftButton")
    check(#actions == 1 and actions[1].button == "LeftButton" and actions[1].down == false,
        branch .. ": ordinary left click reaches the native handler once on release")
    click("RightButton")
    check(#actions == 2 and actions[2].button == "RightButton" and not actions[2].down,
        "right-click menu retains its native release edge")
    for _, button in ipairs({ "MiddleButton", "Button4", "Button5" }) do
        local before = #actions; click(button)
        check(#actions == before + 1 and actions[#actions].down, "extra mouse-button routing retains one press event")
    end
    -- A native user click-casting assignment remains authoritative.
    kind = 1; local before = #actions; click("LeftButton")
    check(casts == 1 and #actions == before, "native click-casting assignment is respected without duplicate casts")
    kind = 0; click("LeftButton")
    check(#actions == before, "an explicitly unbound native interaction is not overridden")
    register(frame); kind = 3; click("LeftButton")
    check(#actions == before + 1, "reapplying registration retains ordinary target input")
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do exercise(branch) end
local old = helper:gsub('"LeftButtonUp", "RightButtonUp", "MiddleButtonDown", "Button4Down", "Button5Down"', '"AnyDown", "RightButtonUp"')
check(not pcall(exercise, "live", old), "negative control rejects the dropped left-release event")
print("Unit click edges: " .. checks .. " checks; five native source handlers; negative control passed")
