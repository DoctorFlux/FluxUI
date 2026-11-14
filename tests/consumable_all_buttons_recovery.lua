-- All seven real Create paths sharing one inventory, watcher and loading phase.
local function read(path)
    local f = assert(io.open(path)); local text = f:read("*a"); f:close(); return text
end
local smoke = read("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua")
local stop = assert(smoke:find("-- PLAYER_LOGIN bag priming", 1, true))
local fixture = setmetatable({arg={ [0]="ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua" }}, {__index=_G})
if arg[1] then
    fixture.io = {open=function(path, ...)
        for _, name in ipairs({"Inventory/Init.lua", "ExtraButtonSystem/Engine/ConsumableBind.lua",
            "ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua", "ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua"}) do
            if path:gsub("\\", "/"):sub(-#name) == name then path = arg[1] .. "/" .. name; break end
        end
        return io.open(path, ...)
    end}
end
local boot = assert(load(smoke:sub(1, stop-1).."return boot", "@all-buttons-fixture", "t", fixture))()
local helper = read("tests/combat_grid_live_counts.lua")
local helperStop = assert(helper:find("for _, family in ipairs", 1, true))
local _, provider = assert(load(helper:sub(1, helperStop-1).."return boot, provider", "@provider-fixture", "t",
    setmetatable({arg={}}, {__index=_G})))()
local ncGrid = read("ExtraButtonSystem/NonCombatGrid/Grid.lua")
local ncCountFirst = assert(ncGrid:find("function btn:SetCount(count, opts)", 1, true))
local ncCountLast = assert(ncGrid:find("function btn:ShowTooltip()", ncCountFirst, true))
local specs = {
    {"food", 117, "ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua"},
    {"water", 159, "ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua"},
    {"healPotion", 118, "ExtraButtonSystem/CombatGrid/Buttons/HealPotion.lua"},
    {"manaPotion", 2455, "ExtraButtonSystem/CombatGrid/Buttons/ManaPotion.lua"},
    {"bandage", 1251, "ExtraButtonSystem/CombatGrid/Buttons/Bandage.lua"},
    {"managem", 5514, "ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua"},
    {"healthstone", 5512, "ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua"},
}
local checks, failures, profiles = 0, 0, 0
local samples = {}
local function check(ok, label)
    checks = checks+1
    if not ok then failures=failures+1; print("FAIL "..label) end
end
local function publish(s)
    if s.publish then s:publish() else s:bags() end
end
for _, family in ipairs({"forever", "retail", "mists", "era", "anniversary"}) do
 for _, source in ipairs({"builtin", "syndicator"}) do
  for _, gemPolicy in ipairs({"single", "charged"}) do
    profiles=profiles+1
    local s = boot(family, family=="era" or family=="anniversary")
    local create=s.env.CreateFrame
    local function complete(f)
        function f:UnregisterEvent(event) self.events[event]=nil end
        function f:GetScript(event) return self.scripts[event] end
        function f:IsEventRegistered(event) return self.events[event] and true or false end
        return f
    end
    for _, f in ipairs(s.frames) do complete(f) end
    s.env.CreateFrame=function(...) return complete(create(...)) end
    if source=="syndicator" then provider(s) end
    s.env._FluxUI_CharSavedVars={food={preferRecuperate=false}}
    s.env.FluxExtraButtonVisibility={QuickGate=function() return true end, Apply=function() return true end}
    s.bridge.GetPreferredCreateSpell=function() return 1, "Create fixture" end
    s.bridge.GetNextManaGemConjureSpell=s.bridge.GetPreferredCreateSpell
    s.bridge.KnowsManaGemConjureSpell=function() return true end
    s.bridge.ShouldStickyManaGemItem=function() return true end
    -- Food/water use their actual noncombat count method before Attach writes
    -- anything. Other faces keep the production combat-grid method in boot.
    local attach=s.env.FluxEBSButtonRefresh.Attach
    s.env.FluxEBSButtonRefresh.Attach=function(opts)
        if opts.kind=="food" or opts.kind=="water" then
            assert(load("local btn=...\n"..ncGrid:sub(ncCountFirst,ncCountLast-1),
                "@noncombat-count", "t", s.env))(opts.btn)
        end
        return attach(opts)
    end
    local faces={}
    for i, spec in ipairs(specs) do
        local id=spec[1]=="managem" and gemPolicy=="charged" and 22044 or spec[2]
        local charged=spec[1]=="managem" and gemPolicy=="charged"
            or spec[1]=="healthstone" and (family=="retail" or family=="mists")
        faces[i]={kind=spec[1], id=id, charged=charged, path=spec[3], initial=charged and 3 or 1}
        s:set(0,i,id,1); s.uses[id]=charged and 3 or 0
    end
    publish(s); s:advance(9)
    for _, face in ipairs(faces) do face.btn, face.module=s:button(face.kind,false,face.path) end
    s.inv.Start(); s:event("PLAYER_ENTERING_WORLD",true,false); s:advance(9)
    local label=family.."/"..source.."/"..gemPolicy
    for _, face in ipairs(faces) do
        check(face.btn.ItemId==face.id and face.btn.WCount.value==tostring(face.initial),label.." real "..face.kind.." initial face")
    end
    local watchers=0
    for _, f in ipairs(s.frames) do
        if f.events.BAG_UPDATE_COOLDOWN then watchers=watchers+1 end
    end
    check(watchers==1,label.." all seven buttons share one use-event watcher")
    -- A complete use burst is shared by all seven buttons, with one settle pass.
    s.combat=true
    local writes=s.writes
    local recounts=0
    for _, face in ipairs(faces) do
        local refresh=face.module.RefreshCountOnly
        face.module.RefreshCountOnly=function(...) recounts=recounts+1; return refresh(...) end
    end
    local timers=#s.timers
    for n=1,100 do s:event("BAG_UPDATE_COOLDOWN") end
    local burstTimers=#s.timers-timers
    check(burstTimers==2,label.." 100 signals share immediate and settle callbacks")
    s:advance(0)
    check(recounts==7,label.." one immediate pass for seven faces")
    check(#s.timers==timers+1,label.." only the shared settle callback remains")
    s:advance(0.12)
    check(recounts==14,label.." seven faces get one immediate and one settle recount")
    local beforeUnrelated, unrelatedTimers=recounts,#s.timers
    for n=1,100 do s:event("ITEM_COUNT_CHANGED",999998) end
    s:advance(0.2)
    check(recounts==beforeUnrelated and #s.timers==unrelatedTimers,label.." unrelated item-count bursts add no work")
    for cycle=1,3 do
        s:event("LOADING_SCREEN_ENABLED")
        for i, face in ipairs(faces) do
            s:set(0,i,face.id,cycle==2 and face.charged and 1 or 0); s.uses[face.id]=0
        end
        publish(s); s:advance(9)
        check(s.inv.IsReliable() and s.best._loadHoldOpen,label.." cycle"..cycle.." reliable/open captured failure precondition")
        s:event("LOADING_SCREEN_DISABLED"); s:advance(3.2)
        check(not s.best.ShouldSoftHoldOwned(),label.." cycle"..cycle.." all consumers leave hold")
        for _, face in ipairs(faces) do
            check(face.btn.ItemId==face.id and face.btn.WCount.value=="0" and face.btn.WIcon.color[1]==0.4,
                label.." cycle"..cycle.." "..face.kind.." combat dark zero")
        end
        check(s.writes==writes,label.." cycle"..cycle.." no combat action writes")
        -- A refill after recovery must immediately replace the previous zero.
        for i, face in ipairs(faces) do s:set(0,i,face.id,1); s.uses[face.id]=face.charged and 2 or 0 end
        s:event("BAG_UPDATE_COOLDOWN"); s:advance(0.12)
        for _, face in ipairs(faces) do
            check(face.btn.WCount.value==tostring(face.charged and 2 or 1) and face.btn.WIcon.color[1]==1,
                label.." cycle"..cycle.." "..face.kind.." refill recovers without provider publication")
        end
    end
    -- Exhaust one face at a time, matching the native food-only failure while
    -- the other six consumables are still owned. No provider publication.
    for i, spent in ipairs(faces) do
        s:set(0,i,spent.id,0); s.uses[spent.id]=0
        s:event("BAG_UPDATE_COOLDOWN"); s:advance(0.12)
        for j, face in ipairs(faces) do
            local expected=i==j and 0 or (face.charged and 2 or 1)
            check(face.btn.WCount.value==tostring(expected) and face.btn.WIcon.color[1]==(expected>0 and 1 or 0.4),
                label.." spending "..spent.kind.." leaves "..face.kind.." correct")
        end
        s:set(0,i,spent.id,1); s.uses[spent.id]=spent.charged and 2 or 0
        s:event("BAG_UPDATE_COOLDOWN"); s:advance(0.12)
        check(spent.btn.WCount.value==tostring(spent.charged and 2 or 1),label.." isolated "..spent.kind.." refill")
    end
    check(s.writes==writes,label.." all isolated uses and refills preserve combat actions")
    -- Leaving combat selects an owned fallback or clears an exhausted identity.
    for i, face in ipairs(faces) do s:set(0,i,face.id,0); s.uses[face.id]=0 end
    s:event("BAG_UPDATE_COOLDOWN"); s:advance(0.12)
    s.combat=false; s:event("PLAYER_REGEN_ENABLED"); s:advance(0.5)
    for _, face in ipairs(faces) do
        check(not face.btn.ItemId and face.btn.PlaceholderTexture and not face.module._trackedItemID,
            label.." "..face.kind.." empty OOC placeholder")
    end
    publish(s); s:advance(12)
    local scans, frames, pending=s.scans,#s.frames,#s.timers
    s:event("LOADING_SCREEN_DISABLED"); s:event("LOADING_SCREEN_DISABLED"); s:advance(12)
    check(s.scans==scans and #s.frames==frames and #s.timers==pending,label.." settled empty grid stays idle")
    samples[#samples+1]={label=label, burstTimers=burstTimers, recounts=recounts, idleScans=s.scans-scans, idleTimers=#s.timers-pending}
  end
 end
end
print(("All consumable button recovery: %d checks, %d failures; profiles=%d"):format(checks,failures,profiles))
for _, sample in ipairs(samples) do
    print(("SAMPLE %s burstTimers=%d totalRecounts=%d idleScans=%d idleTimers=%d"):format(
        sample.label,sample.burstTimers,sample.recounts,sample.idleScans,sample.idleTimers))
end
assert(failures==0,"all-button recovery regression")
