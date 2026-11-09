-- Real classifier + Baganator junk bridge; native metadata/timers mocked.
local source=arg[1] or "Inventory/FluxItemClass.lua"
local checks,failed=0,0
local totals={junk=0,selectors=0,timers=0,cancels=0}
local function check(ok,label)checks=checks+1;if not ok then failed=failed+1;print("FAIL "..label)end end
for _,client in ipairs({"forever","retail","era","anniversary","mists"}) do
 for _,withBaganator in ipairs({false,true}) do
    local s={junk=0,selectors=0,timers=0,cancels=0,frames={},scheduled={},listeners={}}
    local e=setmetatable({}, {__index=_G});e._G=e
    e.wipe=function(t)for k in pairs(t)do t[k]=nil end end
    e.GetTime=function()return 10 end
    e.CreateFrame=function()
        local f={scripts={}};function f:RegisterEvent()end;function f:SetScript(k,fn)self.scripts[k]=fn end
        s.frames[#s.frames+1]=f;return f
    end
    e.C_Item={GetItemInfo=function(id)return {itemName="Item "..id,itemLink="item:"..id,classID=0,stackCount=20}end,
        RequestLoadItemDataByID=function()end}
    e.FluxItemDetection={InvalidateCombatCache=function()s.selectors=s.selectors+1 end}
    e.FluxNCItemDetection={InvalidateFoodWaterCache=function()s.selectors=s.selectors+1 end}
    e.FluxJunk={RegisterVisualRefresh=function(fn)s.listeners[#s.listeners+1]=fn end,
        RegisterListChanged=function()end,OnItemDataLoaded=function()
            s.junk=s.junk+1;for _,fn in ipairs(s.listeners)do fn()end
        end}
    e.FluxVendorJunk=e.FluxJunk
    e.C_Timer={NewTimer=function(_,fn)
        s.timers=s.timers+1;local t={fn=fn};function t:Cancel()self.cancelled=true;s.cancels=s.cancels+1 end
        s.scheduled[#s.scheduled+1]=t;return t
    end}
    if withBaganator then e.Baganator={API={RegisterJunkPlugin=function()end,RequestItemButtonsRefresh=function()end}} end
    assert(loadfile("BaganatorCompat/FluxBaganator_Junk.lua","t",e))()
    e.FluxBaganatorCompat.InitJunk()
    local IC=assert(loadfile(source,"t",e))()
    IC.GetInfo(100)
    local function deliver(event,id,ok)
        s.frames[1].scripts.OnEvent(nil,event,id,ok)
        IC.OnItemDataEvent(id,ok) -- the FluxInv route also delivers this result
    end
    deliver("ITEM_DATA_LOAD_RESULT",100,true)
    check(s.junk==1,client.." first completion notifies once across both routes")
    local before={junk=s.junk,selectors=s.selectors,timers=s.timers,cancels=s.cancels}
    for i=1,100 do deliver("GET_ITEM_INFO_RECEIVED",100,true);deliver("ITEM_DATA_LOAD_RESULT",100,true) end
    for k in pairs(totals)do totals[k]=totals[k]+s[k]-before[k]end
    check(s.junk==before.junk and s.selectors==before.selectors,"resolved metadata does not invalidate consumers")
    check(s.timers==before.timers and s.cancels==before.cancels,"resolved metadata does not churn Baganator timers")
    before=s.junk;IC.RequestLoad(100);deliver("ITEM_DATA_LOAD_RESULT",100,true)
    check(s.junk==before+1,"explicit re-request rearms exactly one completion")
    before=s.junk;IC.OnItemDataLoaded(100)
    check(s.junk==before+1,"explicit completion API still forces refresh")
    before=s.junk;deliver("GET_ITEM_INFO_RECEIVED",100,false)
    check(s.junk==before,"failed metadata stays inert")
    deliver("ITEM_DATA_LOAD_RESULT",999,true)
    check(s.junk==before,"unowned metadata stays inert")
    local heal=0
    e.FluxConsumableClassify={ParseFoodWaterRestore=function()return {isBandage=true,effectiveH=heal}end}
    IC.GetTooltipText=function()return "bandage text" end
    IC.GetInfo(200);deliver("ITEM_DATA_LOAD_RESULT",200,true)
    check(not IC.GetRestore(200).ready,"incomplete bandage remains pending")
    before=s.junk;deliver("ITEM_DATA_LOAD_RESULT",200,true)
    check(s.junk==before+1,"pending restore data can reconcile again")
    heal=100
    check(IC.GetRestore(200).ready,"completed restore data becomes ready")
    before=s.junk;deliver("ITEM_DATA_LOAD_RESULT",200,true)
    check(s.junk==before,"ready restore data stops redundant refreshes")
    IC.InvalidateRestoreCache()
    e.FluxConsumableClassify.ParseFoodWaterRestore=function()error("metadata not ready")end
    check(IC.GetRestore(200)==nil,"parser failure stays unresolved")
    before=s.junk;deliver("ITEM_DATA_LOAD_RESULT",200,true)
    check(s.junk==before+1,"parser retry without a new load still receives completion")
    e.FluxConsumableClassify.ParseFoodWaterRestore=function()return {isBandage=true,effectiveH=100}end
    check(IC.GetRestore(200).ready,"parser retry recovers without losing the item")
 end
end
print(string.format("item metadata idempotence: %d checks, %d failures; stable burst junk=%d selectors=%d timers=%d cancels=%d",
    checks,failed,totals.junk,totals.selectors,totals.timers,totals.cancels))
if failed>0 then os.exit(1)end
