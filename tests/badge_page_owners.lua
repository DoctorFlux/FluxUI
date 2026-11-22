-- Actual SlotMath and BadgeHost; frames/combat transport are desktop models.
-- Every column that can display an action slot needs its own prepared stack.
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local function fixture()
    local e = setmetatable({}, { __index = _G }); e._G = e
    local f = { created = 0, actionWrites = 0, layouts = 0, prepared = 0, lookups = {}, effects = {}, deferred = {} }
    e.HasAction = function() return true end
    local bars = { NUM_COLUMNS = 19, hosts = {} }
    local flux = { Bars = bars, Combat = { InLockdown = function() return f.combat end },
        Timer = { Defer = function(fn) f.deferred[#f.deferred + 1] = fn end } }
    local ns = { Flux = flux }
    assert(loadfile("Bars/SlotMath.lua", "t", e))("_FluxUI", ns)
    local math = bars.SlotMath
    bars.State = { GetSecondarySlot = math.SecondarySlot, GetTertiarySlot = math.TertiarySlot, GetMainSlot = math.MainSlot }
    bars.GetHost = function(col) f.lookups[#f.lookups + 1] = col; return bars.hosts[col] end
    bars.Hosts = { LiveSlot = function(host) return host.slot end }
    bars.ForEachHost = function(fn)
        for column = 1, 19 do
            local rec = bars.hosts[column]
            for _, row in ipairs({ "main", "sec", "tert" }) do fn(rec[row]) end
        end
    end
    bars.Effects = { Refresh = function(host) f.effects[#f.effects + 1] = host.column end }
    for column = 1, 19 do
        local rec = {}; bars.hosts[column] = rec
        for _, row in ipairs({ "main", "sec", "tert" }) do
            local host = { column = column, row = row, widget = {} }
            host.widget._fluxHost = host
            rec[row] = host
        end
    end
    function f.remap(page, swap)
        bars.ForEachHost(function(host)
            host.slot = math.Resolve(host.column, host.row, page, swap, { hasSec = true, hasTert = true })
        end)
    end
    f.remap(1, 0)
    local badgeAPI = {}
    function badgeAPI.New()
        check(not f.combat, "badge creation stays outside combat")
        f.created = f.created + 1
        local badge = { Widget = {} }
        function badge.Widget:SetAlpha(value) self.alpha = value end
        function badge.Widget:GetAlpha() return self.alpha or 0 end
        function badge:SetAction(kind, id)
            check(not f.combat, "badge action writes stay outside combat")
            f.actionWrites = f.actionWrites + 1
            self.ActionType, self.ActionValue = kind, id
            self.SpellId, self.ItemId = kind == "spell" and id or nil, kind == "item" and id or nil
        end
        return badge
    end
    function badgeAPI.Layout(badge, host)
        check(not f.combat, "badge layout stays outside combat")
        f.layouts = f.layouts + 1
        badge.Widget.parentHost = host
    end
    function badgeAPI.ShowVisual(badge) badge.Widget._fluxBadgeCombatVisHidden = nil; badge.Widget:SetAlpha(.75) end
    function badgeAPI.HideVisual(badge) badge.Widget._fluxBadgeCombatVisHidden = true; badge.Widget:SetAlpha(0) end
    function badgeAPI.ApplyVisualSpellTexture(badge, id) badge.Widget.icon = id end
    flux.EBS = { Badge = badgeAPI, Paint = { ClearCache = function() end, UpdateIcon = function() end,
        UpdateCount = function() end, UpdateCooldown = function() end } }
    flux.ButtonFX = { Glow = {
        CanPrepareSecureAura = function() return true end,
        IsSecureAuraSpell = function() return false end,
        MayShowSecureAuraText = function() return false end,
        EnsureSecureAura = function(widget)
            check(not f.combat, "secure aura setup stays outside combat")
            if not widget.prepared then widget.prepared = true; f.prepared = f.prepared + 1 end
        end,
    } }
    local source = arg and arg[1] ~= "" and arg[1] or "Bars/BadgeHost.lua"
    assert(loadfile(source, "t", e))("_FluxUI", ns)
    f.badges, f.bars, f.env, f.flux = bars.BadgeHost, bars, e, flux
    function f.shown(host)
        local list = f.badges.GetVisibleBadgesForButton(host.widget)
        return list and list[1]
    end
    return f
end

local cases = {
    { slot = 13, page = 2, static = 13, staticRow = "main", excluded = 1 },
    { slot = 19, page = 2, static = 19, staticRow = "main", excluded = 7 },
    { slot = 20, page = 2, dynamic = 8 },
    { slot = 37, page = 4, dynamic = 1, static = 13, staticRow = "tert" },
    { slot = 43, page = 4, dynamic = 7, static = 19, staticRow = "tert" },
    { slot = 49, page = 5, dynamic = 1, static = 13, staticRow = "sec" },
    { slot = 55, page = 5, dynamic = 7, static = 19, staticRow = "sec" },
    { slot = 1, page = 1, dynamic = 1 },
    { slot = 66, page = 6, dynamic = 6 },
}
for _, case in ipairs(cases) do
    local f = fixture()
    local list = { { key = "peer", spellId = 1000 + case.slot } }
    f.badges.SetSlotBadges(case.slot, list)
    local firstOwner = case.dynamic or case.static
    local owners = case.dynamic and case.static and 2 or 1
    local initial = f.created
    local initialOwnerCount = #f.lookups
    f.badges.PrepareSecureAuraForSlot(case.slot)
    check(f.prepared == initial and f.created == initial, "aura preparation reaches every existing row without another stack")
    local lookups = #f.lookups
    local writes, layouts = f.actionWrites, f.layouts
    for _ = 1, 100 do f.badges.SetSlotBadges(case.slot, { { key = "peer", spellId = 1000 + case.slot } }) end
    check(f.created == initial and #f.lookups == lookups and f.actionWrites == writes and f.layouts == layouts,
        "identical badge apply performs no owner lookup, creation, action write or layout")

    f.combat = true
    f.remap(case.page, 0)
    f.bars.ForEachHost(f.badges.NotifyDisplay)
    local firstHost = f.bars.hosts[firstOwner].main
    check(firstHost.slot == case.slot and f.shown(firstHost)
        and f.shown(firstHost).Widget.icon == 1000 + case.slot,
        "slot" .. case.slot .. ": first combat page entry paints the prewarmed owner")
    check(initial == owners * 3 * 3, "slot" .. case.slot .. ": exactly three faces per row of every potential column")
    check(initialOwnerCount == owners and f.lookups[1] == firstOwner
        and (owners == 1 or f.lookups[2] == case.static), "potential owners are unique and deterministic")
    if case.excluded then
        local baseHost = f.bars.hosts[case.excluded].main
        check(baseHost.slot == case.excluded and not f.shown(baseHost), "page 2 keeps the base face separate from the fixed badge")
    end
    if owners == 2 then
        local staticHost = f.bars.hosts[case.static][case.staticRow]
        check(staticHost.slot == case.slot and f.shown(staticHost)
            and f.shown(staticHost).Widget.icon == 1000 + case.slot,
            "shared static owner paints the same action slot independently")
    end
    check(f.created == initial and f.actionWrites == writes and f.layouts == layouts,
        "combat page entry needs no frame, protected action or layout writes")
    check(#f.deferred == 0, "prewarmed page entry never queues a missing stack for regen")
    f.badges.PrepareSecureAuraForSlot(case.slot)
    check(f.prepared == initial, "combat aura request preserves the prepared set")
    f.badges.SyncShownFaces()
    check(#f.effects == owners and f.effects[1] == firstOwner
        and (owners == 1 or f.effects[2] == case.static), "shown-face effects refresh every owner column")
    check(#f.deferred <= 1, "shown-face settling keeps one existing deferred pass")

    f.remap(1, 0)
    f.bars.ForEachHost(f.badges.NotifyDisplay)
    check(f.created == initial and f.actionWrites == writes and f.layouts == layouts,
        "combat return to ordinary page preserves prepared widgets")
    f.combat = false
    f.badges.ClearSlot(case.slot)
    check(not f.shown(firstHost), "clearing badges retires the first display")
    if owners == 2 then check(not f.shown(f.bars.hosts[case.static][case.staticRow]), "clearing retires the static display") end
    check(f.created == initial, "clearing a shared slot creates no replacement badges")
end
print(("Badge page ownership: %d checks PASS; shared slot <=2 columns/6 stacks/18 faces; no new polling"):format(checks))

-- A prepared follow-along layout uses the actual badge writer and squeeze owner.
-- Optional paired run: lua tests/badge_page_owners.lua "" --strip-placement <checkpoint>
local function StripBadgeFixture(checkpoint, client)
    local f = fixture()
    local e, flux = f.env, f.flux
    e.Flux, flux.Client = flux, client
    e.InCombatLockdown = flux.Combat.InLockdown
    e.NumberFontNormal = { GetFont = function() return "test-font", 14, "OUTLINE" end }
    local secret = setmetatable({}, {__eq = function() error("secret geometry compared") end})
    e.issecretvalue = function(value) return rawequal(value, secret) end
    local ops, faces = {}, {}
    local function count(key) ops[key] = (ops[key] or 0) + 1 end
    local function Widget(w, parent)
        w.width, w.height, w.scale, w.level, w.shown, w.parent, w.points = 44, 44, 1, 1, true, parent, {}
        local function round(value)
            return (string.unpack("f", string.pack("f", value)))
        end
        function w:SetSize(x, y)
            check(not f.combat, "badge sizing stays outside combat")
            count("size"); self.width, self.height = round(x), round(y)
        end
        function w:SetScale(scale) count("scale"); self.scale = round(scale) end
        function w:SetFrameLevel(level) count("level"); self.level = level end
        function w:SetParent(p) count("parent"); self.parent = p end
        function w:ClearAllPoints() count("point"); self.points = {} end
        function w:SetPoint(p, r, rp, x, y) count("point"); self.points[#self.points + 1] = {p, r, rp, x, round(y)} end
        function w:Show() count("show"); self.shown = true end
        function w:SetClipsChildren(clip) count("clip"); self.clip = clip end
        function w:GetWidth() return self.width end
        function w:GetHeight() return self.height end
        function w:GetScale() return self.scale end
        function w:GetFrameLevel() return self.level end
        function w:GetParent() return self.parent end
        function w:GetNumPoints() return #self.points end
        function w:GetPoint(i) return table.unpack(self.points[i]) end
        function w:IsShown() return self.shown end
        function w:DoesClipChildren() return self.clip end
        return w
    end
    function e.CreateFrame(_, _, parent) return Widget({}, parent) end
    f.bars.ForEachHost(function(host) Widget(host.widget) end)
    local stub = flux.EBS.Badge
    local function source(path)
        if checkpoint then return checkpoint .. "/" .. path:gsub("/", "-") end
        return path
    end
    if checkpoint then
        assert(loadfile(source("Bars/BadgeHost.lua"), "t", e))("_FluxUI", { Flux = flux })
        f.badges = f.bars.BadgeHost
    end
    assert(loadfile(source("ExtraButtonSystem/Engine/Badge.lua"), "t", e))("_FluxUI", { Flux = flux })
    local Badge = flux.EBS.Badge
    Badge.New = function(host)
        local badge = stub.New()
        Widget(badge.Widget, host)
        badge.WCount = { SetFont = function(self, _, size) self.size = size end }
        faces[#faces + 1] = badge
        return badge
    end
    local file = assert(io.open(source("FluxDefaultSettings.lua"), "rb"))
    local settings = file:read("*a")
    file:close()
    local start = assert(settings:find("function FluxUILayoutSqueeze.NotifyLayoutDependents", 1, true))
    local last = assert(settings:find("local squeezeRefreshScheduled", start, true))
    e.FluxUILayoutSqueeze = {}
    assert(load(settings:sub(start, last - 1), "@badge-strip-notification", "t", e))()
    for slot = 13, 20 do
        f.badges.SetSlotBadges(slot, { {key = "peer", spellId = 1000 + slot} })
    end
    f.faces, f.secret = faces, secret
    function f.refresh(crossing)
        ops = {}
        -- A cursor crossing moves the whole strip through its relative anchor.
        -- The badge point remains relative to the same owned button.
        e.FluxUILayoutSqueeze.NotifyLayoutDependents(true, crossing)
        return ops
    end
    function f.signature()
        local out = {}
        for i, badge in ipairs(faces) do
            local widget, slot, host = badge.Widget, badge.SlotFrame, badge._fluxBadgeHost
            local p, relative, rp, x, y = slot:GetPoint(1)
            local b, anchor, rb, bx, by = widget:GetPoint(1)
            assert(slot.parent == host and widget.parent == slot and relative == host and anchor == slot)
            out[i] = table.concat({widget.width,widget.height,widget.scale,widget.level,
                slot.width,slot.height,slot.level,p,rp,x,y,b,rb,bx,by,tostring(slot.clip),tostring(slot.shown),
                badge.WCount.size}, "|")
        end
        return table.concat(out, "\n")
    end
    return f
end

if not arg or not arg[1] or arg[1] == "" then
    local baseline = arg and arg[2] == "--strip-placement" and assert(arg[3]) or nil
    local function total(ops)
        local result = 0
        for _, count in pairs(ops) do result = result + count end
        return result
    end
    for _, client in ipairs({
        {"retail", {isPostDF = true}}, {"forever", {isForever = true}}, {"classic", {isAnyClassic = true}},
        {"era", {isEra = true, isAnyClassic = true}}, {"anniversary", {isAnniversary = true, isAnyClassic = true}},
    }) do
        local a, b = StripBadgeFixture(baseline, client[2]), StripBadgeFixture(nil, client[2])
        local writesBefore, writesAfter = 0, 0
        for _ = 1, 8 do
            writesBefore = writesBefore + total(a.refresh(baseline ~= nil))
            writesAfter = writesAfter + total(b.refresh(true))
            check(a.signature() == b.signature(), "stable badge layout and draw levels agree")
        end
        check(#b.faces == 8 * 3 * 3 and writesAfter == 0 and writesBefore > 0,
            "warm crossings skip all matching protected placement writes across eight owned columns")
        local firstA, firstB = a.faces[1], b.faces[1]
        firstA._fluxBadgeHost.width, firstB._fluxBadgeHost.width = 37, 37
        a.refresh(baseline ~= nil)
        local changed = b.refresh(true)
        check(changed.size > 0 and changed.size < #b.faces and a.signature() == b.signature(),
            "a squeezed host repairs only its own prepared badges")
        firstB.SlotFrame.points[1][5] = -7
        firstB.Widget.level = 250
        firstB.SlotFrame.clip = false
        check(total(b.refresh(true)) > 0 and a.signature() == b.signature(), "drifted anchor, clipping and layer are repaired")
        firstB.Widget.level = 250
        local levelOnly = b.refresh(true)
        check(total(levelOnly) == 1 and levelOnly.level == 1 and a.signature() == b.signature(),
            "a changed VFX level needs only one setter")
        firstA._fluxBadgeHost.scale, firstB._fluxBadgeHost.scale = .5, .5
        a.refresh(baseline ~= nil)
        check(total(b.refresh(true)) == 0 and a.signature() == b.signature(), "font follows host scale without replacing anchors")
        firstA.Widget._fluxSecureMissileGlow, firstB.Widget._fluxSecureMissileGlow = true, true
        a.refresh(baseline ~= nil)
        check(total(b.refresh(true)) > 0 and a.signature() == b.signature(), "a glow requiring unclipped art repairs clipping")

        local slot = firstB.SlotFrame
        local getter = slot.GetWidth
        slot.GetWidth = function() return b.secret end
        check(total(b.refresh(true)) > 0, "private geometry takes the full placement path")
        slot.GetWidth = function() error("getter unavailable") end
        check(total(b.refresh(true)) > 0, "unavailable geometry takes the full placement path")
        slot.GetWidth = getter
        check(total(b.refresh(false)) == writesBefore / 8, "explicit refresh keeps the ordinary layout writer")
        b.combat = true
        check(total(b.refresh(true)) == 0, "combat deferral issues no protected placement writes")
        print(("STRIP_BADGE_PLACEMENT|%s|%d|%d|%d"):format(client[1],#b.faces,writesBefore,writesAfter))
    end
end
