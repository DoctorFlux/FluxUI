-- Production class-icon blocks with opaque sentinels. No native secret VM claim.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local source = read(arg[1] or "UnitFrames/FluxUnitFrames_Shared.lua")
local helper = read("Core/FluxAPI/Secrets.lua")
local first = assert(helper:find("function ns.API.SafeAccessibleString(value)", 1, true))
local last = assert(helper:find("function ns.API.CanAccessSecrets()", first, true))
helper = helper:sub(first, last - 1)
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local function forbidden() error("restricted class token inspected or concatenated") end
local secret = setmetatable({}, { __concat = forbidden, __tostring = forbidden, __index = forbidden })
local inaccessible = setmetatable({}, { __concat = forbidden, __tostring = forbidden, __index = forbidden })

for _, client in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    for _, alignment in ipairs({ "BOTTOM", "TOP" }) do
        for _, portrait in ipairs({ "LEFT", "RIGHT" }) do
            local class, player, enabled = "MAGE", true, true
            local ns = { API = {
                IsSecretValue = function(value) return rawequal(value, secret) end,
                CanAccessValue = function(value) return not rawequal(value, inaccessible) end,
            } }
            local env = setmetatable({ ns = ns, API = ns.API,
                UnitClass = function() return "localized", class end,
                UnitIsPlayer = function() return player end,
                FluxUnitFrames_ShouldShowClassIcon = function() return enabled end,
            }, { __index = _G })
            assert(load(helper, "@actual-safe-string", "t", env))()
            local search = 1
            for route = 1, 2 do
                local a = assert(source:find("-- Update class icon for players", search, true))
                local b = assert(source:find("-- Update spec icon", a, true))
                search = b
                -- The partition route nests spec/border handling inside this if.
                local close = route == 1 and "\nend" or ""
                local update = assert(load("return function(self, outerBorderPadding, outerBorderAlignment, portraitPosition, totPos2Minimal)\n"
                    .. source:sub(a, b - 1) .. close .. "\nend", "@actual-class-icon", "t", env))()
                local icon = { textures = {}, shown = false, failPreferred = false }
                function icon:SetTexture(value)
                    check(type(value) == "string", "texture receives a public filename")
                    self.textures[#self.textures + 1] = value; self.texture = value
                end
                function icon:GetTexture()
                    if self.failPreferred and self.texture:find("ClassIcon_", 1, true) then return nil end
                    return self.texture
                end
                function icon:Show() self.shown = true end
                function icon:Hide() self.shown = false end
                function icon:SetSize(w, h) self.width, self.height = w, h end
                function icon:ClearAllPoints() self.point = nil end
                function icon:SetPoint(...) self.point = { ... } end
                local frame = { unit = "target", classIcon = icon, outerBorderFrame = {} }
                local function paint() update(frame, 36, alignment, portrait, false) end
                player, enabled, class = true, true, "MAGE"; paint()
                check(icon.shown and icon.texture == "Interface\\Icons\\ClassIcon_MAGE", client .. ": public class art preserved")
                check(icon.width == 36 and icon.height == 36, "icon dimensions preserved")
                local point = (alignment == "BOTTOM" and "TOP" or "BOTTOM") .. portrait
                check(icon.point[1] == point and icon.point[2] == frame.outerBorderFrame
                    and icon.point[5] == (alignment == "BOTTOM" and -4 or 4), "existing corner and inset preserved")
                local calls = #icon.textures
                for _, value in ipairs({ secret, inaccessible, false }) do
                    class = value or nil; paint()
                    check(not icon.shown and #icon.textures == calls, "restricted or unavailable class hides stale art without a texture call")
                end
                class = "WARRIOR"; paint()
                check(icon.shown and icon.texture == "Interface\\Icons\\ClassIcon_WARRIOR", "next public identity restores current art")
                icon.failPreferred = true; paint()
                check(icon.texture == "Interface\\Icons\\Class_WARRIOR" and icon.shown, "legacy texture fallback retained")
                player = false; calls = #icon.textures; paint()
                check(not icon.shown and #icon.textures == calls, "NPC does not use a player class icon")
                player, enabled = true, false; paint()
                check(not icon.shown and #icon.textures == calls, "existing class-icon setting retained")
            end
        end
    end
end
print("unit_class_icon_secrets: " .. checks .. " checks PASS; native secrets/pixels NOT RUN")
