-- Actual shared cast-bar lifecycle; opaque values are desktop sentinels only.
local function read(p)
    local f = assert(io.open(p, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local source = read("tests/castbar_school_themes.lua")
source = source:sub(1, assert(source:find("local function checkParticleGeometry", 1, true)) - 1)
source = source:gsub('pet="PetFrame"', 'pet="PetFrame",party1="PartyFrame"')
if arg[1] then
    local n
    source, n = source:gsub('loadAddon%("UnitFrames/FluxCastBar.lua",%s*env,%s*ns%)', function()
        return "loadAddon("..string.format("%q", arg[1])..", env, ns)"
    end)
    check(n == 1, "test loads selected production source")
end
local fixture = assert(load(source.."\nreturn fixture", "@rejected-cast-fixture", "t", _G))()
local terminal = {
    "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_CHANNEL_STOP", "UNIT_SPELLCAST_EMPOWER_STOP",
}
for _, client in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    for _, unit in ipairs({ "player", "target", "focus", "pet", "party1" }) do
        for _, phase in ipairs({ "idle", "reset", "finished", "interrupted", "hidden", "custom" }) do
            local s, e, ns = fixture(client)
            local bar = s.NewBar(unit)
            if phase ~= "idle" then
                s.casts[unit] = { id = 133, name = "Fireball" }
                bar:CastStart(unit, false, "cast-1")
                if phase == "reset" then ns.CastBar.ResetCastForUnit(bar)
                elseif phase == "finished" then s.Event(bar, "UNIT_SPELLCAST_STOP", unit, "cast-1", 133)
                elseif phase == "interrupted" then s.Event(bar, "UNIT_SPELLCAST_INTERRUPTED", unit, "cast-1", 133)
                elseif phase == "hidden" then bar:Hide()
                elseif phase == "custom" then ns.CastBar.StartCustomTimer(bar, { duration = 20, kind = "flight" }) end
            end
            s.casts[unit] = nil
            local shown, label, hold, fade, casting, custom = bar:IsShown(), bar.Text.text, bar.holdTime, bar.fadeOut, bar.casting, bar.customTimer
            local frames, textures, writes, released = #s.frames, #s.textures, bar.manualWrites, s.released
            for repeatIndex = 1, 3 do
                for _, event in ipairs(terminal) do
                    for _, identity in ipairs({ "missing", "public", "secret" }) do
                        local guid = identity == "secret" and s.secret or identity == "public" and "rejected-1" or nil
                        local id = identity == "secret" and s.secret or 133
                        s.Event(bar, event, unit, guid, id, false)
                        check(bar:IsShown() == shown, client.." "..unit.." "..phase..": terminal event cannot show an inactive/hidden cast: "..event)
                        check(bar.Text.text == label and bar.holdTime == hold and bar.fadeOut == fade, "terminal event cannot replace or extend post-cast feedback")
                        check(bar.casting == casting and bar.customTimer == custom, "hidden cast and flight timer ownership preserved")
                    end
                end
            end
            check(#s.frames == frames and #s.textures == textures and bar.manualWrites == writes and s.released == released,
                "rejected terminal events allocate and paint nothing; swing slot unchanged")
        end
        -- Active cast failure/interruption still produces normal feedback, even
        -- after UnitCastingInfo has cleared and routed IDs are unavailable.
        for _, event in ipairs({ "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED" }) do
            for _, identity in ipairs({ "public", "missing", "secret" }) do
                local s, e, ns = fixture(client); local bar = s.NewBar(unit)
                s.casts[unit] = { id = 133, name = "Fireball" }; bar:CastStart(unit, false, "cast-1")
                s.casts[unit] = nil
                local guid = "cast-1"
                if identity == "missing" then bar.castGUID = nil; guid = nil end
                if identity == "secret" then bar.castGUID = s.secret; guid = s.secret end
                s.Event(bar, event, unit, guid, 133)
                check(bar:IsShown() and bar.interrupted and not bar.casting and bar.holdTime == 1,
                    "an actual cast keeps interruption/failure feedback")
            end
        end
        local s, e, ns = fixture(client); local bar = s.NewBar(unit)
        s.Event(bar, "UNIT_SPELLCAST_START", unit, "rejected-1", 133)
        check(not bar:IsShown() and not bar.casting, "START without live cast data cannot create a bar")
        s.casts[unit] = { id = 133, name = "Fireball" }; bar:CastStart(unit, false, "new-cast")
        s.Event(bar, "UNIT_SPELLCAST_FAILED", unit, "old-cast", 133)
        check(bar.casting and not bar.interrupted, "old attempt cannot fail replacement cast")
        s.Event(bar, "UNIT_SPELLCAST_FAILED", unit, nil, 116)
        check(bar.casting, "different public spell with omitted GUID stays rejected")
        s.Event(bar, "UNIT_SPELLCAST_FAILED", "other-unit", nil, 133)
        check(bar.casting, "unit event routing retained")
        ns.CastBar.ResetCastForUnit(bar)
        s.casts[unit] = { id = 5143, name = "Channel", channel = true }; bar:CastStart(unit, true, "channel-1")
        s.Event(bar, "UNIT_SPELLCAST_FAILED", unit, "rejected-1", 133)
        check(bar.channeling and not bar.interrupted, "failed attempt does not interrupt channel")
        s.Event(bar, "UNIT_SPELLCAST_CHANNEL_STOP", unit, "channel-1", 5143)
        check(not bar.channeling and bar.holdTime, "real channel completion retained")
        ns.CastBar.ResetCastForUnit(bar)
        s.casts[unit] = { id = 357208, name = "Empower", channel = true, stages = 3 }; bar:CastStart(unit, true, "empower-1")
        s.Event(bar, "UNIT_SPELLCAST_EMPOWER_STOP", unit, "empower-1", 357208, false)
        check(bar.interrupted and bar.holdTime, "real empowered interruption retained")
    end
end
print("Rejected cast lifecycle: "..checks.." checks PASS; five client models; native input/taint/pixels pending")
