-- Actual follow-up/recipe driver and inventory storm owner; native actions mocked.
local root = os.getenv("FLUX_AH_ROOT") or "."
local function Export(path, flag)
    local env = setmetatable({ [flag] = true }, { __index = _G })
    return assert(loadfile(root .. "/tests/" .. path .. ".lua", "t", env))()
end
local followFixture = Export("auction_restock_followup", "FLUX_FOLLOWUP_FIXTURE_EXPORT")
local function StormOwner(st, env)
    local file = assert(io.open(root .. "/Inventory/Init.lua", "rb")); local text = file:read("*a"); file:close()
    local first = assert(text:find("local STORM_HOLD = 0.25", 1, true))
    local last = assert(text:find("function Inv.SetMerchantOpen", first, true))
    env.C_Timer.After = function(delay, fn) return env.C_Timer.NewTimer(delay, fn) end
    st.flux.Safecall = function(fn, ...) return fn(...) end
    assert(load("local _, ns = ...; local Flux, Inv = ns.Flux, ns.Flux.Inventory\n" .. text:sub(first, last - 1),
        "@Inventory/Init.lua:storm-owner", "t", env))("_FluxUI", { Flux = st.flux })
end
local function Fixture(client, provider, yield)
    local legacy = client == "Era" or client == "Anniversary"
    local A, st, env, F = followFixture(legacy, provider)
    st.entries[1].target, st.recipes[1].quantityMin = yield == 1 and 3 or 6, yield
    st.books[100] = { commodity = not legacy, offers = legacy
        and { { itemID = 100, quantity = yield == 1 and 2 or 5, total = (yield == 1 and 2 or 5) * 100 } }
        or { { itemID = 100, quantity = yield == 1 and 2 or 5, unitPrice = 100 } } }
    A.SetMaxPrice(100, 100, false)
    env.GetTradeSkillNumMade = function() return yield end
    local schematic = env.C_TradeSkillUI.GetRecipeSchematic
    env.C_TradeSkillUI.GetRecipeSchematic = function(...)
        local value = schematic(...); if value then value.quantityMin = yield end; return value
    end
    if st.recipes[1].craftingData then st.recipes[1].craftingData.schematic.quantityMin = yield end
    StormOwner(st, env)
    st.openAH(); st.press(); st.ack(); A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
    st.bags[200], st.bags[201] = 2, 2; st.emit("BAG_UPDATE_DELAYED")
    st.professionName, st.professionID = "First Aid", 129; st.emit("TRADE_SKILL_SHOW")
    env.UnitCastingInfo = function()
        if st.casting then return st.castName or "Bandage", nil, nil, 0, 1, st.tradeSkillCast ~= false, st.castToken, false, st.castSpellID end
    end
    function st.castStart(token, spellID)
        st.casting, st.castToken, st.castSpellID = true, token, spellID
        st.emit("UNIT_SPELLCAST_START", "player", token, spellID)
    end
    st.work = { counts = 0, rows = 0, paints = 0, hidden = 0, ready = 0 }
    local live, rows = env.FluxRestock.Inv.GetLiveCount, A.GetRows
    env.FluxRestock.Inv.GetLiveCount = function(...) st.work.counts = st.work.counts + 1; return live(...) end
    A.GetRows = function(...) st.work.rows = st.work.rows + 1; return rows(...) end
    F.Paint = function(state)
        st.work.paints = st.work.paints + 1
        if not state or state.kind == "waiting" then st.work.hidden = st.work.hidden + 1 end
        if state and state.canAct then st.work.ready = st.work.ready + 1 end
        st.painted = state
    end
    return A, st, env, F
end
local function AttachUI(A, st, env, F)
    local m = getmetatable(env.UIParent).__index
    function m:GetSize() return self:GetWidth(), self:GetHeight() end
    function m:SetNormalTexture(value) self.normal = value end
    function m:SetPushedTexture(value) self.pushed = value end
    function m:SetHighlightTexture(value) self.highlight = value end
    function m:SetTextColor(...) self.textColor = { ... } end
    function m:SetShadowColor(...) self.shadowColor = { ... } end
    function m:SetShadowOffset(...) self.shadowOffset = { ... } end
    env.FluxExtraAbilityHost = {}; st.flux.Cap.HasAtlas = function() return true end
    st.ui = { starts = 0, stops = 0, shows = 0, hides = 0 }
    local effects = {}
    env.LibStub = function(name)
        if name == "LibCustomGlow-1.0" then return {
            ProcGlow_Start = function(button) effects[button] = true; st.ui.starts = st.ui.starts + 1 end,
            ProcGlow_Stop = function(button) effects[button] = nil; st.ui.stops = st.ui.stops + 1 end,
        } end
    end
    local ns = { Flux = st.flux }
    assert(loadfile(root .. "/Inventory/Restock/Auction/FluxAuctionRestockLocale.lua", "t", env))("_FluxUI", ns)
    assert(loadfile(root .. "/Inventory/Restock/Auction/FluxAuctionRestockFollowupUI.lua", "t", env))("_FluxUI", ns)
    F.Refresh()
    local frame, show, hide = F.frame, F.frame.Show, F.frame.Hide
    frame.Show = function(self) if not self:IsShown() then st.ui.shows = st.ui.shows + 1 end; return show(self) end
    frame.Hide = function(self) if self:IsShown() then st.ui.hides = st.ui.hides + 1 end; return hide(self) end
    st.ui.effects = effects
end
if FLUX_CRAFT_SETTLE_FIXTURE_EXPORT then return Fixture end
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, provider in ipairs({ "absent", "ready" }) do for _, yield in ipairs({ 1, 3 }) do
        profiles = profiles + 1
        local A, st, env, F = Fixture(client, provider, yield)
        AttachUI(A, st, env, F)
        check(F.GetState().kind == "craft" and F.GetState().canAct, "real saved recipe is ready before its player press")
        st.followPress()
        st.castStart("Craft-one", 901)
        local task = F.GetState().task
        check(F.GetState().kind == "crafting" and not F.GetState().canAct and #st.crafts == 1,
            "one physical press starts exactly one real-driver batch")
        st.inventory.NotifyBagStorm(.25)
        st.bags[100], st.bags[200], st.bags[201], st.repeatCount = 1 + yield, 1, 1, 1
        st.emit("UNIT_SPELLCAST_STOP", "player", "Craft-one", 901)
        check(F.GetState().kind == "crafting" and F.GetState().settling == true
            and F.GetState().items[100] == 2 * yield and F.GetState().task == task and not F.GetState().canAct,
            "temporary untrusted inventory retains the same real item/task disabled instead of a hidden waiting state")
        check(F.frame:IsShown() and F.icons[1]:IsShown() and F.icons[1].itemID == 100 and not F.icons[1]:IsEnabled()
            and not next(st.ui.effects) and st.ui.shows == 0 and st.ui.hides == 0,
            "actual service-to-HUD chain keeps the same real item visible with no hide/show or stale proc during settlement")
        st.followPress()
        check(#st.crafts == 1 and not F.CanAct(F.GetState()), "settling presentation cannot authorize a direct repeated craft click")
        st.advance(.31)
        check(F.GetState().kind == "crafting" and F.GetState().items[100] == yield
            and F.GetState().task == task and not F.GetState().settling,
            "trusted output publication updates quantity in place and clears only the settling marker")
        st.castStart("Craft-two", 901)
        st.casting, st.repeatCount = false, 0
        st.emit("UNIT_SPELLCAST_STOP", "player", "Craft-two", 901)
        if not legacy then st.emit("UPDATE_TRADESKILL_CAST_STOPPED", false) end
        check(F.GetState().kind == "crafting" and not F.GetState().canAct,
            "natural final stop before bag publication never re-advertises another craft")
        check(F.frame:IsShown() and not F.icons[1]:IsEnabled() and not next(st.ui.effects)
            and st.ui.shows == 0 and st.ui.hides == 0 and F.icons[1].count.text == tostring(yield),
            "pre-storm final stop cannot flash the real button's ready state or rebuild its badge")
        st.inventory.NotifyBagStorm(.25)
        st.bags[100], st.bags[200], st.bags[201] = 1 + 2 * yield, 0, 0
        st.emit("BAG_UPDATE_DELAYED")
        check(F.GetState().kind == "crafting" and F.GetState().items[100] == yield and not F.GetState().canAct,
            "final untrusted output keeps the same known item until the owner settles")
        st.advance(.31)
        check(not F.GetState() and not A.Settings().followup and #st.crafts == 1,
            "trusted final output retires the job once without an extra native craft")
        check(not F.frame:IsShown() and st.ui.hides == 1 and st.ui.shows == 0,
            "actual final goal completion hides the persistent HUD once")
    end end
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, provider in ipairs({ "absent", "ready" }) do
        for _, failure in ipairs({ "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED" }) do
            for _, stopFirst in ipairs({ false, true }) do
                local A, st, env, F = Fixture(client, provider, 1)
                st.followPress(); st.castStart("Cancelled-cast", 901)
                st.casting, st.repeatCount = false, 0
                if stopFirst then st.emit("UNIT_SPELLCAST_STOP", "player", "Cancelled-cast", 901) end
                st.emit(failure, "player", "Cancelled-cast", 901)
                if not stopFirst then st.emit("UNIT_SPELLCAST_STOP", "player", "Cancelled-cast", 901) end
                check(F.GetState().kind == "craft" and F.GetState().canAct and not F.GetState().settling and #st.crafts == 1,
                    "explicit failed/interrupted craft releases a no-output attempt in either stop order without a bag event")
            end
        end
        for _, mode in ipairs({ "unknown", "not-tradeskill", "another-recipe", "secret", "secret-spell" }) do
            local A, st, env, F = Fixture(client, provider, 1)
            st.followPress()
            local token, spellID = "Unowned-cast", 901
            if mode == "not-tradeskill" then st.tradeSkillCast = false
            elseif mode == "another-recipe" then st.castName = "Another recipe"
            elseif mode == "secret" then
                token = "Secret-cast"
                env.issecretvalue = function(value) return rawequal(value, token) end
            elseif mode == "secret-spell" then
                env.issecretvalue = function(value) return rawequal(value, spellID) end
            end
            if mode ~= "unknown" then st.castStart(token, spellID) end
            st.casting, st.repeatCount = false, 0
            st.emit("UNIT_SPELLCAST_STOP", "player", token, spellID)
            if not legacy then st.emit("UPDATE_TRADESKILL_CAST_STOPPED", false) end
            check(F.GetState().kind == "craft" and F.GetState().canAct and not F.GetState().settling and #st.crafts == 1,
                "unknown/unowned/restricted cast observations cannot manufacture an output hold or strand a stopped batch")
        end
        local A, st, env, F = Fixture(client, provider, 1)
        st.followPress(); st.castStart("Owned-cast", 901)
        st.casting, st.repeatCount = false, 1
        st.emit("UNIT_SPELLCAST_STOP", "player", "Unrelated-cast", 901)
        check(F.GetState().kind == "crafting" and not F.GetState().settling,
            "an unrelated stopped token cannot add a settlement expectation to the owned craft")
        st.emit("UNIT_SPELLCAST_STOP", "player", "Owned-cast", 901)
        st.emit("UNIT_SPELLCAST_STOP", "player", "Owned-cast", 901)
        st.bags[100], st.bags[200], st.bags[201], st.repeatCount = 2, 1, 1, 0
        st.emit("BAG_UPDATE_DELAYED")
        if legacy then st.emit("UNIT_SPELLCAST_STOP", "player", "Owned-cast", 901)
        else st.emit("UPDATE_TRADESKILL_CAST_STOPPED", false) end
        check(F.GetState().kind == "craft" and F.GetState().canAct and F.GetState().items[100] == 1 and #st.crafts == 1,
            "duplicate stopped tokens do not extend a lower bound and a partial stopped batch resumes after its output was published")
        A, st, env, F = Fixture(client, provider, 1)
        st.followPress(); st.casting, st.repeatCount = false, 0
        if legacy then st.emit("UNIT_SPELLCAST_INTERRUPTED", "player")
        else st.emit("UPDATE_TRADESKILL_CAST_STOPPED", false) end
        check(F.GetState().kind == "craft" and F.GetState().canAct and #st.crafts == 1,
            "an explicit no-output batch cancellation does not require a future bag update")
        A, st, env, F = Fixture(client, provider, 1)
        st.followPress()
        st.castStart("Queued-one", 901); st.casting, st.repeatCount = false, 1
        st.emit("UNIT_SPELLCAST_STOP", "player", "Queued-one", 901)
        st.castStart("Queued-two", 901); st.casting, st.repeatCount = false, 0
        st.emit("UNIT_SPELLCAST_STOP", "player", "Queued-two", 901)
        if not legacy then st.emit("UPDATE_TRADESKILL_CAST_STOPPED", false) end
        st.bags[100], st.bags[200], st.bags[201] = 2, 1, 1; st.emit("BAG_UPDATE_DELAYED")
        check(F.GetState().kind == "crafting" and not F.GetState().canAct and F.GetState().settling
            and F.GetState().items[100] == 1 and #st.crafts == 1,
            "multiple observed casts before any bags publish retain a cumulative lower bound after only the first output arrives")
        st.followPress(); check(#st.crafts == 1, "partially published stopped outputs cannot authorize another batch")
        st.bags[100], st.bags[200], st.bags[201] = 3, 0, 0; st.emit("BAG_UPDATE_DELAYED")
        check(not F.GetState() and not A.Settings().followup,
            "the cumulative lower bound never delays trusted complete output retirement")
        A, st, env, F = Fixture(client, provider, 1)
        st.inventory.NotifyBagStorm(.25); F.Refresh()
        local held = F.GetState()
        check(held.kind == "craft" and held.settling and not held.canAct,
            "an existing ready craft remains the same disabled item while inventory becomes untrusted")
        st.inventory.EndBagStorm()
        check(not F.CanAct(held), "a retained settling payload cannot grant permission before it is republished even if global reliability returns")
        F.Clear(); check(not F.GetState() and not A.Settings().followup,
            "explicit cancellation clears the retained job immediately without a future output publication")
        if not legacy then
            A, st, env, F = Fixture(client, provider, 1)
            st.followPress(); st.castName = "Alchemy"
            st.castStart("Generic-modern-cast", 77)
            st.casting, st.repeatCount = false, 0
            st.emit("UNIT_SPELLCAST_STOP", "player", "Generic-modern-cast", 77)
            st.emit("UPDATE_TRADESKILL_CAST_STOPPED", false)
            check(F.GetState().kind == "crafting" and F.GetState().settling and not F.GetState().canAct,
                "an actual public modern recipe-spell match binds a generic display name without assuming all casting spells match recipe IDs")
            st.emit("UNIT_SPELLCAST_INTERRUPTED", "player", "Generic-modern-cast", 77)
            check(F.GetState().kind == "craft" and F.GetState().canAct,
                "the generic-name observation still releases immediately on explicit no-output interruption")
        end
    end
end
print(("Auction craft settlement: %d checks PASS; %d client/provider/yield profiles; native event timing/art/input NOT RUN"):format(checks, profiles))
