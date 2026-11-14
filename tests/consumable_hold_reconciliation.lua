-- Exercise actual loading events, not only a manually toggled reliability bit.
local function read(path)
    local f = assert(io.open(path)); local s = f:read("*a"); f:close(); return s
end
local smoke = read("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua")
local stop = assert(smoke:find("-- PLAYER_LOGIN bag priming", 1, true))
local fixture = setmetatable({arg={[0]="ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua"}}, {__index=_G})
if arg[1] then
    fixture.io={open=function(path,...)
        for _, name in ipairs({"Inventory/Init.lua","Inventory/FluxConsumableBest/Init.lua","Inventory/FluxConsumableBest/FluxConsumableBest.lua","Core/API/Item.lua"}) do
            if path:gsub("\\","/"):sub(-#name)==name then path=arg[1].."/"..name;break end
        end
        return io.open(path,...)
    end}
end
local boot = assert(load(smoke:sub(1,stop-1).."return boot", "@hold-events", "t", fixture))()
local helper=read("tests/combat_grid_live_counts.lua")
local helperStop=assert(helper:find("for _, family in ipairs",1,true))
local _,provider,entries=assert(load(helper:sub(1,helperStop-1).."return boot, provider, entries", "@provider", "t", setmetatable({arg={}}, {__index=_G})))()
local checks,failures=0,0
local function check(ok,label)
    checks=checks+1;if not ok then failures=failures+1;print("FAIL "..label)end
end
local function setup(family, source, entry)
    local kind,id,key=entry[1],entry[2],entry[3]
    local s=boot(family,family=="era"or family=="anniversary")
    local create=s.env.CreateFrame
    local function complete(frame)
        function frame:UnregisterEvent(name)self.events[name]=nil end
        function frame:GetScript(name)return self.scripts[name]end
        function frame:IsEventRegistered(name)return self.events[name]and true or false end
        return frame
    end
    for _,frame in ipairs(s.frames)do complete(frame)end
    s.env.CreateFrame=function(...)return complete(create(...))end
    if source=="syndicator"then provider(s)end
    local charged=entry[4]or kind=="healthstone"and(family=="retail"or family=="mists")
    local n=(kind=="managem"or kind=="healthstone")and 1 or 13
    s:set(0,1,id,n);s:set(1,1,id==159 and 118 or 159,5);s.uses[id]=charged and 3 or 0
    if s.publish then s:publish()else s:bags()end
    s:advance(9)
    s.bridge.GetPreferredCreateSpell=function()return 1,"Create fixture"end
    s.bridge.GetNextManaGemConjureSpell=s.bridge.GetPreferredCreateSpell
    s.bridge.KnowsManaGemConjureSpell=function()return true end
    s.bridge.ShouldStickyManaGemItem=function()return true end
    s.env.FluxExtraButtonVisibility={QuickGate=function()return true end,Apply=function()return true end}
    local path=kind=="managem"and"ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua"or kind=="healthstone"and"ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua"or nil
    local btn,module=s:button(kind,false,path);s.env[key]=module;s:advance(0.4)
    return s,btn,module,id,n,charged
end
for _,family in ipairs({"forever","retail","mists","era","anniversary"})do
 for _,source in ipairs({"builtin","syndicator"})do
  for _,entry in ipairs(entries)do
   for _,mode in ipairs({"login","reload","missing-args"})do
    local s,btn,module,id,n,charged=setup(family,source,entry)
    s.inv.Start();s:advance(0.1)
    s:event("LOADING_SCREEN_ENABLED")
    s.inv.BeginLoginHold()
    check(s.best._loadHoldOpen==true,family..source..entry[1]..mode.." startup hold cannot release a real loading screen")
    s.inv.Notify({bags=true,recovery=true});s:advance(0.1)
    check(s.best.ShouldSoftHoldOwned(),family..source..entry[1]..mode.." genuine loading holds ownership")
    s:advance(9)
    check(s.best.ShouldSoftHoldOwned(),family..source..entry[1]..mode.." genuine long loading outlives inventory timeout")
    if mode=="login"then s:event("PLAYER_ENTERING_WORLD",true,false)
    elseif mode=="reload"then s:event("PLAYER_ENTERING_WORLD",false,true)
    else s:event("PLAYER_ENTERING_WORLD")end
    s:advance(9)
    local label=family.."/"..source.."/"..entry[1].."/"..mode
    check(s.inv.IsReliable(),label.." inventory recovers")
    check(not s.best.ShouldSoftHoldOwned()and not s.best._loadHoldOpen,label.." first world entry releases loading hold")
    s.combat=true;local writes=s.writes
    s:set(0,1,id,0);s.uses[id]=0
    s:event("BAG_UPDATE",0);s:event("BAG_UPDATE_DELAYED");s:event("BAG_UPDATE_COOLDOWN");s:advance(0.2)
    check(btn.WCount.value=="0"and btn.WIcon.color[1]==0.4,label.." no frozen13/1 after loading")
    check(s.writes==writes,label.." no protected combat writes")
   end
   -- The portal grace can outlast the inventory reliability hold. A count-only
   -- recovery must release the forced digit even when Best publishes no identity.
   do
    local s,btn,module,id,n,charged=setup(family,source,entry)
    local label=family.."/"..source.."/"..entry[1].."/portal-end"
    s.combat=true;local writes=s.writes
    s.best.ArmPortalSoftHold()
    s.inv.NoteRefreshSettling()
    s.inv.Notify({bags=true,recovery=true});s:advance(0.1)
    s:set(0,1,id,0);s.uses[id]=0
    -- Keep provider facts/Best identity unchanged, isolating count recovery.
    s.best.RequestRecompute=function()end
    s.inv.Notify({bags=true,recovery=true});s:advance(1)
    s.inv.IsReliable();s:advance(0.1)
    check(s.inv.IsReliable(),label.." inventory settles before portal grace")
    check(s.best.ShouldSoftHoldOwned(),label.." grace retains face before expiry")
    s:advance(1.45)
    check(not s.best.ShouldSoftHoldOwned(),label.." grace expires")
    check(btn.WCount.value=="0"and btn.WIcon.color[1]==0.4,label.." grace-end publication releases frozen count")
    check(s.writes==writes,label.." release remains visual in combat")
   end
  end
 end
end
-- Best can observe the first PEW before the deferred inventory owner starts.
for _,family in ipairs({"forever","retail","mists","era","anniversary"})do
 for _,source in ipairs({"builtin","syndicator"})do
    local s,btn,module,id=setup(family,source,entries[1])
    s.best.BeginLoadHold()
    s:event("PLAYER_ENTERING_WORLD",true,false);s:advance(9)
    check(not s.best.ShouldSoftHoldOwned(),family..source.." Best-only first-world owner releases hold")
    s.combat=true;s:set(0,1,id,0);s:event("BAG_UPDATE_COOLDOWN");s:advance(0.2)
    check(btn.WCount.value=="0",family..source.." deferred inventory startup cannot preserve old digit")
 end
end
-- The short manual command captures the bad state without forcing a recount,
-- changing actions, allocating a driver or exposing opaque FontString values.
do
    local s,btn,module,id=setup("forever","syndicator",entries[2])
    s.combat=true;s:set(0,1,id,0);s.uses[id]=0
    s.env.GetItemCount=function()return 13 end
    s:event("BAG_UPDATE_COOLDOWN");s:advance(0.2)
    local rows={}
    s.env.print=function(...)
        local values={};for i=1,select("#",...)do values[i]=tostring(select(i,...))end
        rows[#rows+1]=table.concat(values," ")
    end
    s.env.Flux.Print=s.env.print
    local writes,scans,frames,timers=s.writes,s.scans,#s.frames,#s.timers
    local text=btn.WCount.value
    s.env.SlashCmdList.FLUXINV("buttons")
    local output=table.concat(rows,"\n")
    check(output:find("COUNTS/1 source=syndicator",1,true),"diagnostic reports source/revision")
    check(output:find("water id=159",1,true)and output:find("slots=0 snapshot=13 modern=0 legacy=13 wrapped=0",1,true),"diagnostic separates physical/API/cache facts")
    check(s.writes==writes and s.scans==scans and #s.frames==frames and #s.timers==timers and btn.WCount.value==text,"diagnostic is read-only and has no background driver")
    local opaque=setmetatable({}, {__tostring=function()error("opaque text must not be inspected")end})
    s.env.Flux.Secrets={IsSecretValue=function(v)return v==opaque end}
    btn.WCount.GetText=function()return opaque end
    rows={};s.env.SlashCmdList.FLUXINV("buttons")
    check(table.concat(rows,"\n"):find("text=restricted",1,true),"diagnostic does not stringify opaque text")
end
print(("Consumable hold reconciliation: %d checks, %d failures"):format(checks,failures))
assert(failures==0,"consumable hold reconciliation regression")
