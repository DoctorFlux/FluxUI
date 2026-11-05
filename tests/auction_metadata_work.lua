-- Production item classifier, spell reagent resolver and native-event router.
-- Native APIs are mocked. Optional source root permits matched baseline replay.
local root = arg[1] or "."
local checks, failures, totals = 0, 0, {names=0, info=0, junk=0, invalidations=0, walks=0, cacheEntries=0}
local function check(ok, label)
    checks=checks+1
    if not ok then failures=failures+1; print("FAIL "..label) end
end
local function up(fn, key, replacement)
    for i=1,100 do
        local name,value=debug.getupvalue(fn,i)
        if not name then break end
        if name==key then
            if replacement~=nil then debug.setupvalue(fn,i,replacement) end
            return value
        end
    end
    error("missing fixture upvalue "..key)
end
for _, family in ipairs({"retail","forever","era","anniversary","mists"}) do
 for _, provider in ipairs({"builtin","syndicator"}) do
    local s={frames={},timers={},names=0,info=0,junk=0,invalidations=0,walks=0,ready={}}
    local env=setmetatable({}, {__index=_G}); env._G=env
    env.wipe=function(t) for k in pairs(t) do t[k]=nil end end
    env.GetTime=function() return 10 end
    env.UIParent={}
    env.CreateFrame=function(_,name)
        local f={scripts={},events={}}
        function f:SetScript(key,fn) self.scripts[key]=fn end
        function f:RegisterEvent(event) self.events[event]=true end
        function f:RegisterUnitEvent(event) self.events[event]=true end
        s.frames[#s.frames+1]=f; if name then env[name]=f end
        return f
    end
    local compat={SafeRegisterEvent=function(f,event) f:RegisterEvent(event) end,
        After=function(_,fn) s.timers[#s.timers+1]=fn end,
        GetSpellName=function(id) return "Reagent Spell (Rank "..id..")" end}
    local bag,bank={},{}
    for i=1,80 do bag[i]=true end
    for i=81,280 do bank[i]=true end
    env.FluxInv={Compat=compat, Bags={GetUniqueItems=function() s.walks=s.walks+1; return bag end},
        Bank={GetCharacterCounts=function() s.walks=s.walks+1; return bank end}}
    -- The event router/resolver is identical under both inventory providers.
    env.Flux={Inventory={source=provider}}
    local function name(id) return id==9000 and "Test Powder" or "Item "..id end
    env.C_Item={GetItemInfoInstant=function() return 1,nil,nil,"",1,0,0 end,
        GetItemNameByID=function(id) s.names=s.names+1; return s.ready[id] and name(id) or (id<8000 and name(id)) end,
        GetItemInfo=function(id)
            s.info=s.info+1
            if not s.ready[id] and id>=8000 then return end
            return {itemName=name(id),itemLink="item:"..id,classID=0,subclassID=0,stackCount=20}
        end,
        RequestLoadItemDataByID=function() end}
    env.GetItemInfo=function(id)
        if type(id)=="string" then
            if id=="Test Powder" and s.ready[9000] then return name(9000),"item:9000" end
            return
        end
        s.names=s.names+1
        return (s.ready[id] or id<8000) and name(id) or nil
    end
    if family=="era" or family=="anniversary" then env.C_Item.GetItemNameByID=nil end
    env.FluxVendorJunk={OnItemDataLoaded=function() s.junk=s.junk+1 end}
    env.FluxItemDetection={InvalidateCombatCache=function() s.invalidations=s.invalidations+1 end}
    env.FluxNCItemDetection={InvalidateFoodWaterCache=function() s.invalidations=s.invalidations+1 end}
    local function loadFile(path) return assert(loadfile(root.."/"..path,"t",env))() end
    local IC=loadFile("Inventory/FluxItemClass.lua")
    loadFile("Inventory/FluxInv/FluxInv_Spells.lua")
    loadFile("Inventory/FluxInv/FluxInv_Events.lua")
    local Spells=env.FluxInv.Spells
    env.FluxInv.Events.Init()
    local function event(key,id,success)
        for _,f in ipairs(s.frames) do
            if f.events[key] and f.scripts.OnEvent then f.scripts.OnEvent(f,key,id,success) end
        end
    end
    -- Successful global metadata loads unrelated to any FluxUI request.
    for id=10000,10049 do
        s.ready[id]=true
        event("GET_ITEM_INFO_RECEIVED",id,true)
        event("ITEM_DATA_LOAD_RESULT",id,true)
    end
    check(s.walks==0, family.."/"..provider.." unrelated metadata does not scan containers")
    check(s.names==0, "no unrelated name reads after reagent warm")
    check(s.info==0, "no unsolicited full-info cache population")
    check(s.junk==0, "unrelated auction metadata does not invalidate junk UI")
    check(s.invalidations==0, "unrelated consumables do not invalidate selector caches")
    s.cacheEntries=0
    for _ in pairs(up(IC.GetInfo,"infoCache")) do s.cacheEntries=s.cacheEntries+1 end
    check(s.cacheEntries==0, "unrelated metadata does not grow the session cache")
    for k in pairs(totals) do totals[k]=totals[k]+s[k] end

    -- A cold request made by the classifier still resolves through either event.
    check(IC.GetInfo(8000)==nil, "cold requested item unresolved")
    s.ready[8000]=true
    event("ITEM_DATA_LOAD_RESULT",8000,true)
    check(IC.GetInfo(8000).name==name(8000), "requested metadata resolves")
    check(s.junk>0 and s.invalidations>0, "owned consumable/junk notifications retained")
    check(IC.GetInfo(8001)==nil, "second cold request unresolved")
    event("ITEM_DATA_LOAD_RESULT",8001,false)
    s.ready[8001]=true
    event("GET_ITEM_INFO_RECEIVED",8001,true)
    check(IC.GetInfo(8001).name==name(8001), "failed request can resolve on later legacy event")
    IC.GetStatic(8002)
    s.ready[8002]=true
    local owned=s.junk
    event("ITEM_DATA_LOAD_RESULT",8002,true)
    check(s.junk>owned, "static-only consumers retain metadata invalidation")
    local before=s.junk
    event("GET_ITEM_INFO_RECEIVED",8000,false)
    check(s.junk==before, "failed global event does not invalidate ready item")
    -- Explicit callers retain the original reconciliation API, even untracked.
    IC.OnItemDataLoaded(10000)
    check(s.junk>before, "explicit item completion API retained")

    -- Seed the real resolver's name-only Classic tooltip state, without a fake
    -- spellbook rebuild; tables/functions under test remain production ones.
    local resolve=up(Spells.OnVisibleItemsChanged,"ResolvePendingReagentNames")
    local pending=up(resolve,"GetItemIDFromName")
    local pendingNames=up(pending,"pendingReagentNames")
    local bySpell=up(resolve,"reagentBySpell")
    bySpell[9]={{itemID=8002,name=name(8002)}}
    bySpell[10]={{name="Test Powder"}}; pendingNames["test powder"]=true
    local migrations
    env.FluxRestockList={OnActiveReagentsFinalized=function(rows) migrations=rows end}
    up(Spells.OnVisibleItemsChanged,"reagentsWarmDone",true)
    local startWalks=s.walks
    for id=10050,10059 do s.ready[id]=true; event("ITEM_DATA_LOAD_RESULT",id,true) end
    check(s.walks==startWalks, "pending reagent does not justify unrelated full scans")
    s.ready[9000]=true
    event("GET_ITEM_INFO_RECEIVED",9000,false)
    check(bySpell[10][1].itemID==nil, "failed reagent completion remains pending")
    event("ITEM_DATA_LOAD_RESULT",9000,true)
    check(bySpell[10][1].itemID==9000, "name-only reagent resolves immediately")
    check(s.walks==startWalks, "matching metadata also avoids container walks")
    check(up(resolve,"allReagentItemIDs")[9000], "reagent ownership recorded")
    local finalized=up(up(Spells.OnVisibleItemsChanged,"FinalizeActiveReagents"),"activeReagentItemIDs")
    check(finalized[9000], "warm active restock set finalized")
    check(not finalized[8002], "obsolete lower-rank reagent stays out of active set")
    check(migrations and migrations[1] and migrations[1].obsoleteIDs[8002]
        and migrations[1].activeIDs[1]==9000, "max-rank restock migration retained")
    -- Real visible-container changes still harvest names for all existing users.
    Spells.OnVisibleItemsChanged()
    check(s.walks>startWalks, "bag/bank change harvesting retained")
 end
end
print(string.format("auction metadata: %d checks, %d failures; burst names=%d info=%d walks=%d junk=%d invalidations=%d cacheEntries=%d",
    checks,failures,totals.names,totals.info,totals.walks,totals.junk,totals.invalidations,totals.cacheEntries))
if failures>0 then os.exit(1) end
