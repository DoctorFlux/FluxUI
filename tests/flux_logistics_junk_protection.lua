-- Exercise the actual FluxUI junk classifier, Baganator detector and merchant seller.
local base = "Inventory/Restock/Junk/_tmp_junksmoke.lua"
local file = assert(io.open(base, "rb"))
local fixture = file:read("*a")
file:close()
local stop = assert(fixture:find("for _, family in ipairs(", 1, true))
local env = setmetatable({arg = {[0] = base}}, {__index = _G})
local boot = assert(load(fixture:sub(1, stop - 1) .. "return Boot", "@queued-junk", "t", env))()
local checks = 0
local function check(value, label)
    checks = checks + 1
    assert(value, label)
end

for _, family in ipairs({"forever", "live", "era", "anniversary", "mists"}) do
    local t = boot(family)
    local e, fj = t.env, t.fj
    assert(loadfile("Inventory/Restock/Core/FluxRestockPolicy.lua", "t", e))("_FluxUI", t.ns)
    local policy = t.ns.Flux.RestockPolicy
    local marked, gray, priceless, missing, unrelated = 301001, 301002, 301003, 301004, 301005
    t.add(1, marked, {quality = 2})
    t.add(2, gray)
    t.add(3, priceless, {sellPrice = 0})
    t.add(4, unrelated)
    t.settings.junkList[marked], t.settings.junkList[tostring(priceless)] = true, true
    t.settings.junkFilters.destroy = true
    local detector, repaint = nil, 0
    e.Baganator = {API = {
        RegisterJunkPlugin = function(_, _, fn) detector = fn end,
        RequestItemButtonsRefresh = function() repaint = repaint + 1 end,
    }}
    assert(loadfile("BaganatorCompat/FluxBaganator_Junk.lua", "t", e))("_FluxUI", t.ns)
    e.FluxBaganatorCompat.InitJunk()
    check(fj.IsExplicitJunk(marked) and detector(0, 1, marked) and #fj.GetJunkTabList() == 4,
        "unprotected classification and cached list match the pre-queue settings")
    fj.BuildJunkSlotWorklist("all")
    local ids = {[marked] = true, [gray] = true, [priceless] = true, [missing] = true}
    check(policy.RegisterPlanner({
        GetCoverage = function() return {} end, Request = function() end,
        GetCraftMaterialIDs = function() return ids end,
    }), "the planner may publish optional craft material protection")
    check(not fj.IsJunk(marked) and not fj.IsExplicitJunk(marked) and not detector(0, 1, marked),
        "a previously manual mark cannot classify or paint an accepted material as junk")
    check(not fj.IsBlizzardVendorJunk(gray, t.inv.GetContainerItemInfo(0, 2))
        and not fj.IsJunk(gray) and not detector(0, 2, gray),
        "a queued gray also bypasses the native vendor-junk fallback")
    local list = fj.GetJunkTabList()
    check(#list == 1 and list[1] == unrelated and repaint == 1,
        "queue registration clears stale lists and refreshes bag classification once")
    check(fj.AddJunk(missing) == false and fj.ToggleJunk(gray) == false and not fj.MarkUpgradeInferior(gray)
        and t.settings.junkList[missing] == nil and t.settings.junkList[gray] == nil,
        "manual mutations are blocked even for a missing material")
    fj.GetItemIdFromCursor = function() return gray end
    check(fj.HandleItemDrop(false) and t.settings.junkList[gray] == nil,
        "merchant drop consumes the action without marking or clearing a protected item")

    policy.NotifyCoverageChanged()
    ids = {[gray] = true, [marked] = true, [priceless] = true, [missing] = true}
    policy.NotifyCoverageChanged()
    check(fj.GetJunkTabList() == list and repaint == 1,
        "mail or queue coverage notices with equal membership keep caches and visuals")

    -- Simulate a sale pass holding a candidate from its pre-queue worklist.
    local previousIterator, stale = fj.IterateJunkWorklist, true
    fj.IterateJunkWorklist = function(mode)
        local nextSlot = previousIterator(mode)
        return function()
            if stale then stale = false; return 0, 3, priceless end
            return nextSlot()
        end
    end
    t.sj.Start("all")
    t.advance(1)
    fj.IterateJunkWorklist = previousIterator
    check(not stale and #t.calls == 1 and t.calls[1].itemID == unrelated
        and t.bags[0][1] and t.bags[0][2] and t.bags[0][3] and #t.errors == 0,
        "live sale and delete checks protect accepted materials even from a stale candidate")

    local beforeRelease = repaint
    ids = {}
    policy.NotifyCoverageChanged()
    check(repaint == beforeRelease + 1 and fj.IsExplicitJunk(marked) and detector(0, 1, marked)
        and fj.IsBlizzardVendorJunk(gray, t.inv.GetContainerItemInfo(0, 2)),
        "release restores prior manual and gray classifications without a bag event")
    check(t.settings.junkList[marked] == true and t.settings.junkList[tostring(priceless)] == true
        and t.settings.junkList[gray] == nil and t.settings.junkList[missing] == nil,
        "temporary protection preserves earlier settings and writes no new mark")
end

print(("Queued craft material junk protection: %d checks across five client profiles."):format(checks))
