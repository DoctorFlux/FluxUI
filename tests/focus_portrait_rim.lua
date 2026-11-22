-- Check Core's drawn fields against the existing RGBA sheets. The authored
-- source rectangles mirror the FluxBorder factory at the compact portrait seam.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a")
    file:close()
    return source
end

local raster = read("tests/castbar_border_junctions.lua")
local art = raster:sub(1, assert(raster:find("-- Pinned local Forever source", 1, true)) - 1)
local sampler = assert(raster:find("local function alphaAt(", 1, true))
local endSampler = assert(raster:find("for _,profile in ipairs", sampler, true)) - 1
local fixture, coords, profiles, sheets, alphaAt = assert(load(art .. raster:sub(sampler, endSampler)
    .. "\nreturn fixture,coords,profiles,sheets,alphaAt", "@focus-rim-raster", "t", _G))()

local pieces = {"TL", "TR", "BL", "BR", "Top", "Bottom", "Left", "Right"}
local checks = 0
local function check(ok, message)
    checks = checks + 1
    assert(ok, message)
end

local function build(style, scale, height, compact, party, isolate)
    local junctions, new, piece, flush, objects, _, choose, _, env, border = fixture()
    choose(style, "class")
    local profile = profiles[style]
    border.GetJoinTracks = function() return profile end
    border.GetBorderThickness = function() return profile.thickness end
    local root = new(env.UIParent)
    root.unit = party and "party1" or "focus"
    root.scale = scale
    root._FluxBorderStatic = true
    root._FluxBorderIndependent = isolate
    root._fluxCompactFocus = compact
    local authored = {root}

    local function box(name, x, y, w, h, level, owner, aura)
        local host = new(owner or root, {x, y, w, h})
        host.scale, host.level = scale, level
        host.name = name
        host._FluxBorderAuraPanel = aura
        host._FluxBorderRoundCorners = name == "outer"
        if aura then host.strata = "BACKGROUND" end
        authored[#authored + 1] = host
        local rects = {
            TL = {x - 9, y + h - 13, 16, 17}, TR = {x + w - 11, y + h - 13, 16, 17},
            BL = {x - 9, y - 5, 16, 16}, BR = {x + w - 11, y - 5, 16, 16},
            Top = {x + 7, y + h - 13, w - 18, 17}, Bottom = {x + 7, y - 5, w - 18, 16},
            Left = {x - 9, y + 11, 16, h - 24}, Right = {x + w - 11, y + 11, 16, h - 24},
        }
        for _, key in ipairs(pieces) do
            local texture, record = piece(host, key, rects[key])
            record.art = "Interface\\AddOns\\_FluxUI\\Texture\\borders\\" .. profile.file
            texture:SetTexture(record.art)
            texture:SetTexCoord(table.unpack(coords[key]))
            texture:SetVertexColor(.2, .6, .8, aura and .4 or 1)
            host[key] = texture
            authored[#authored + 1] = texture
        end
        return host
    end

    local bodyWidth = height == 35 and 83 or 260
    local width = height + bodyWidth
    root.FluxBorderFrame = box("base", height - 2, 0, bodyWidth, height, 50)
    root.PortraitFrame = {FluxBorderFrame = box("portrait", 0, 0, height, height, 57)}
    local atlas = box("atlas", 0, 0, width, height, 52, env.UIParent)
    atlas._FluxBorderOwner = root
    root.outerBorderFrame = {FluxBorderFrame = box("outer", 0, 0, width, height + 36, 55)}
    if not party then
        local container = new(root)
        container.unit = root.unit
        local nest = 7 + profile.Top - profile.Bottom
        local panelHeight = math.max(44, math.floor(height * scale * .65 + 34)) / scale
        box("buff", 0, height + 36 - nest, width / 2, panelHeight, 0, container, true)
        box("debuff", width / 2, height + 36 - nest, width / 2, panelHeight, 0, container, true)
    end

    local function commit()
        flush()
        check(junctions.stats.fallback == nil and junctions.stats.triangles > 0, "real source fields commit")
    end
    commit()

    local function opacity(x, y)
        local alpha = 0
        for _, texture in ipairs(objects) do
            local path = texture:GetTexture()
            if texture:GetObjectType() == "Texture" and type(path) == "string" and path:find("Texture\\borders\\", 1, true) then
                local field = alphaAt(texture, x * scale, y * scale, sheets[style])
                alpha = 1 - (1 - alpha) * (1 - field)
            end
        end
        return alpha
    end

    local function move(x, y)
        for _, region in ipairs(authored) do
            region.rect[1], region.rect[2] = region.rect[1] + x, region.rect[2] + y
        end
        junctions:CommitLayout()
        commit()
    end
    return opacity, move, width
end

local function outerOpacity(style, width, x, y)
    local u1, u2, v1, v2 = table.unpack(coords.Bottom)
    return sheets[style](u1 + (x - 7) / (width - 18) * (u2 - u1), v1 + (11 - y) / 16 * (v2 - v1))
end

local baselineDifferent = false
for _, style in ipairs({1, 2}) do
    local crest = 11 - profiles[style].Bottom
    for _, scale in ipairs({.55, .65, .82, 1}) do
        for _, height in ipairs({35, 58, 85}) do
            local isolate = height == 58
            local focus, move, width = build(style, scale, height, true, false, isolate)
            local ordinary = build(style, scale, height, false, false, isolate)
            local party = build(style, scale, height, false, true, true)
            local function checkBand(dx, dy)
                for _, y in ipairs({-1.37, -.37, .13, .63, 1.13, crest - .31, crest + .19, crest + .81}) do
                    for i = -20, 20 do
                        local x = height - 2 + i * .5 + .07
                        local expected = outerOpacity(style, width, x, y)
                        check(math.abs(focus(x + dx, y + dy) - expected) < 1e-6,
                            "one original outer field supplies the exposed lower Focus rim")
                        local regular = ordinary(x, y)
                        check(math.abs(regular - party(x, y)) < 1e-6, "noncompact and Party contacts retain their normal paint")
                        if math.abs(regular - expected) > .02 then baselineDifferent = true end
                    end
                end
            end
            checkBand(0, 0)
            for _, x in ipairs({.37, 1.83, height - 1.59, width / 2 + .17, width - 1.73}) do
                for _, y in ipairs({.17, crest + 3.37, height + 34.27, height + 38.61}) do
                    if y > crest + 1 or math.abs(x - height + 2) > 20 then
                        check(math.abs(focus(x, y) - ordinary(x, y)) < 1e-6,
                            ("the upper contour, portrait stem and outside corners keep their previous sources at %.2f, %.2f"):format(x, y))
                    end
                end
            end
            if scale == .65 then
                move(.37, .29)
                checkBand(.37, .29)
            end
        end
    end
end
check(baselineDifferent, "the portrait contact baseline differs in the outer shadow")
print("Compact Focus portrait rim: " .. checks .. " checks PASS; original bevel/shadow field, detached scope variants, aura and cap preservation, fractional moves. Native pixels pending")
