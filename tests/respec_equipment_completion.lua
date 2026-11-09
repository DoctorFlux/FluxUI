-- COMPLETE current Compat/Inv/Includes/EquipmentSets/Equipment/Apply modules. Only native
-- inventory, public Flux.Inventory facts, event delivery and clocks are modeled.
local root = arg[1] or "."
if not root:match("[/\\]$") then root = root .. "/" end
local selected=arg[2]
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local clients={"classic_era","classic_anniversary","classic","live","forever"}
local function boot(client,mode)
    local s={combat=mode=="cancel-pending",equipped={[1]=1001,[3]=1003},bags={},events={},warnings={},frames={},timers={},store={},pickups=0,equips=0,checkpointClears=0,allowEquip=mode~="cancel-active"}
    local profile={equipment={[1]={itemID=2001}}}
    if mode=="missing"then s.bags={} elseif mode=="partial"then profile.equipment[3]={itemID=2003};s.bags[1]=2001
    elseif mode=="matched"then s.equipped[1]=2001
    elseif mode=="disabled"then profile.includes={equipment=false}
    elseif mode=="uncaptured"then profile.equipment=nil
    else s.bags[1]=2001 end
    local e=setmetatable({},{__index=_G});e._G=e
    local R={GetProfile=function()return profile end,GetStore=function()return s.store end,
        On=function()end,ApplyInfoFrameForProfile=function()end,LinkProfilePresets=function()end,
        Warn=function(message)s.warnings[#s.warnings+1]=message end,Print=function()end,
        SetLoadCheckpoint=function(name,step)s.checkpoint={name=name,step=step}end,
        ClearLoadCheckpoint=function()s.checkpoint=nil;s.checkpointClears=s.checkpointClears+1 end,
        Fire=function(...)s.events[#s.events+1]={...}end}
    e.FluxRespec=R;e.FLUX_API={isRetail=client=="live"or client=="forever",isV12=client=="live",isClassicEra=client=="classic_era"}
    e.time=function()return 100 end;e.GetTime=function()return 100 end
    e.InCombatLockdown=function()return s.combat end
    e.GetInventoryItemLink=function(_,slot)local id=s.equipped[slot];return id and("item:"..id..":")end
    e.GetInventoryItemID=function(_,slot)return s.equipped[slot]end
    e.GetItemInfo=function(id)return"Item"..tostring(id),nil,nil,nil,nil,nil,nil,nil,"INVTYPE_HEAD"end
    e.IsInventoryItemLocked=function()return false end
    e.ClearCursor=function()s.cursor=nil end
    e.GetCursorInfo=function()return s.cursor and"item"end
    e.EquipCursorItem=function(slot)
        check(not s.combat,"no gear mutation while modeled combat lock remains")
        s.equips=s.equips+1
        if s.allowEquip and s.cursor then local old=s.equipped[slot];s.equipped[slot]=s.cursor.id;s.bags[s.cursor.slot]=old end
    end
    e.C_Container={GetContainerNumSlots=function(bag)return bag==0 and 4 or 0 end,
        GetContainerItemID=function(bag,slot)return bag==0 and s.bags[slot]or nil end,
        GetContainerItemLink=function(bag,slot)local id=bag==0 and s.bags[slot];return id and("item:"..id..":")end,
        GetContainerItemInfo=function()return {isLocked=false}end,
        PickupContainerItem=function(bag,slot)
            check(not s.combat,"no bag pickup during modeled combat")
            s.pickups=s.pickups+1
            if bag==0 and s.bags[slot]then s.cursor={id=s.bags[slot],slot=slot}end
        end}
    e.CreateFrame=function()
        local f={events={},scripts={}}
        function f:RegisterEvent(event)self.events[event]=true end
        function f:UnregisterAllEvents()self.events={}end
        function f:SetScript(key,fn)self.scripts[key]=fn end
        s.frames[#s.frames+1]=f;return f
    end
    e.C_Timer={After=function(delay,fn)s.timers[#s.timers+1]={delay=delay,fn=fn}end}
    if client=="live"or client=="forever"or client=="classic"then
        e.C_EquipmentSet={CanUseEquipmentSets=function()return true end,GetEquipmentSetIDs=function()return {}end,
            GetEquipmentSetID=function()return nil end,UseEquipmentSet=function()error("unlinked native set must not be used")end}
    end
    local flux={Inventory={Containers={GetCarriedBagIDs=function()return {0}end},IsReady=function()return true end,
        IsBankOpen=function()return false end,CanTakeFromBank=function()return false end,
        Find=function(id,opts)
            local list={};if opts.bags then for slot,item in pairs(s.bags)do if item==id then list[#list+1]={bag=0,slot=slot,itemID=id,region="bags"}end end end;return list
        end}}
    local ns={Flux=flux};e.Flux=flux
    for _,path in ipairs({"Respec/FluxRespec_Compat.lua","Respec/FluxRespec_Inv.lua","Respec/FluxRespec_Includes.lua","Respec/FluxRespec_EquipmentSets.lua","Respec/FluxRespec_Equipment.lua","Respec/FluxRespec_Apply.lua"})do
        assert(loadfile(root .. path,"t",e))("_FluxUI",ns)
    end
    check(type(R.EquipmentSets.TryApply)=="function","complete production equipment-set bridge is present")
    function s.done()local out={};for _,event in ipairs(s.events)do if event[1]=="APPLY_DONE"then out[#out+1]=event end end;return out end
    function s.regen()
        for _,f in ipairs(s.frames)do local fn=f.scripts.OnEvent;if f.events.PLAYER_REGEN_ENABLED and fn then fn(f,"PLAYER_REGEN_ENABLED")end end
    end
    function s.flush()
        local work=s.timers;s.timers={};for _,t in ipairs(work)do t.fn()end
    end
    return s,R,profile,e
end

for _,client in ipairs(clients)do
    if not selected or selected=="missing" then
    for _,mode in ipairs({"missing","partial"})do
        local s,R,p=boot(client,mode)
        R.Apply.Run("RequestedGear")
        local done=s.done()
        check(#done==1 and done[1][2]==false and done[1][3]=="EQUIPMENT_INCOMPLETE","missing requested gear must never report full success")
        check(R.Equipment.AnyGearChangeNeeded(p.equipment),"missing requested gear remains a truthful mismatch")
        check(s.checkpoint~=nil and s.checkpointClears==0,"incomplete gear retains recovery checkpoint")
        if mode=="partial"then check(s.equipped[1]==2001 and s.equipped[3]==1003,"available gear still applies before incomplete result")end
        s.bags[2]=2001;s.bags[3]=2003;R.Apply.Run("RequestedGear")
        check(s.done()[2][2]==true and s.checkpoint==nil,"retry completes after missing gear becomes available")
    end
    end
    if not selected or selected=="cancel" then
    for _,mode in ipairs({"cancel-pending","cancel-active"})do
        local s,R,p=boot(client,mode)
        R.Apply.Run("CancelledGear")
        check(R.Apply.IsRunning(),"real pipeline starts asynchronous gear owner")
        local before=s.equips
        R.Apply.Cancel()
        check(R.Equipment._pending==nil and not R.Equipment._active,"pipeline cancellation clears its gear request")
        s.combat=false;s.allowEquip=true;s.regen();s.flush()
        check(s.equips==before and s.equipped[1]==1001,"cancelled combat/lock continuation cannot equip")
        check(#s.done()==1 and s.done()[1][3]=="CANCELLED","cancelled pipeline emits exactly one final result")
    end
    end
    for _,mode in ipairs({"ordinary","matched","disabled","uncaptured"})do
        local s,R=boot(client,mode);R.Apply.Run("Control")
        check(#s.done()==1 and s.done()[1][2] and not R.Apply.IsRunning(),"ordinary/matched/disabled/uncaptured controls succeed")
        check(s.pickups==(mode=="ordinary"and 1 or 0),"unchanged gear work budget")
    end
    do
        local s,R=boot(client,"ordinary")
        check(R.Equipment.Apply(nil)==false,"direct invalid equipment snapshot remains failure")
        check(s.pickups==0,"invalid snapshot cannot mutate gear")
        local events=#s.events
        check(not R.Equipment.CancelPendingApply() and #s.events==events,"no-op cancellation emits no completion or inventory work")
    end
    for _,fromEvent in ipairs({false,true})do
        local s,R,p=boot(client,"cancel-pending");s.bags[2]=3001
        local a,b,c={}, {}, {};local nested=false
        local function newer()
            if nested then return end;nested=true;s.combat=false
            R.Equipment.ApplyWithCallback({[1]={itemID=3001}},function(ok,why)c[#c+1]={ok,why}end)
        end
        if fromEvent then
            local fire=R.Fire
            R.Fire=function(name,ok,why,...)
                fire(name,ok,why,...)
                if name=="EQUIPMENT_APPLIED"and why=="SUPERSEDED"then newer()end
            end
        end
        R.Equipment.ApplyWithCallback(p.equipment,function(ok,why)
            a[#a+1]={ok,why};if not fromEvent and why=="SUPERSEDED"then newer()end
        end)
        local accepted=R.Equipment.ApplyWithCallback(p.equipment,function(ok,why)b[#b+1]={ok,why}end)
        check(accepted==false and #a==1 and #b==1 and b[1][2]=="SUPERSEDED","outer request superseded during callback/events completes exactly once")
        check(#c==1 and c[1][1] and s.equipped[1]==3001 and s.equips==1,"nested synchronous completion stays newest; outer gear cannot overwrite it")
        local before=#s.events
        check(not R.Equipment.CancelPendingApply() and #s.events==before,"no-op cancel after nested completion is inert")
    end
    do
        local s,R,p=boot(client,"cancel-pending");local completions={};local cancelled=false
        local callback=function(ok,why)completions[#completions+1]={ok,why}end
        R.Equipment.ApplyWithCallback(p.equipment,function(_,why)
            if why=="SUPERSEDED"then cancelled=R.Equipment.CancelPendingApply(callback)end
        end)
        local accepted=R.Equipment.ApplyWithCallback(p.equipment,callback)
        s.combat=false;s.regen();s.flush()
        check(cancelled and not accepted and #completions==1 and completions[1][2]=="CANCELLED","new owner can cancel during superseded completion before request install")
        check(s.equips==0 and R.Equipment._pending==nil and not R.Equipment._active,"begin-window cancellation cannot leak deferred gear work")
    end
    do
        local s,R,p=boot(client,"cancel-pending");local a,b={},{ }
        local function doneA(ok,why)a[#a+1]={ok,why}end
        local function doneB(ok,why)b[#b+1]={ok,why}end
        R.Equipment.ApplyWithCallback(p.equipment,doneA)
        local stale=s.frames[#s.frames].scripts.OnEvent
        R.Equipment.ApplyWithCallback(p.equipment,doneB)
        check(#a==1 and not a[1][1] and a[1][2]=="SUPERSEDED","replacement completes previous owner once")
        check(not R.Equipment.CancelPendingApply(doneA),"old callback cannot cancel newer equipment owner")
        p.equipment[1].itemID=9999
        s.combat=false;stale(s.frames[1],"PLAYER_REGEN_ENABLED");s.regen();s.flush()
        check(s.equipped[1]==2001 and #b==1 and b[1][1],"queued snapshot frozen; stale watcher cannot consume replacement")
        check(#a==1 and s.equips==1,"replacement has one accepted gear write")
    end
    do
        local s,R,p=boot(client,"cancel-active");local old,new={},{}
        local a=function(ok,why)old[#old+1]={ok,why}end
        local b=function(ok,why)new[#new+1]={ok,why}end
        R.Equipment.ApplyWithCallback(p.equipment,a)
        R.Equipment.CancelPendingApply(a)
        R.Equipment.ApplyWithCallback(p.equipment,b)
        local before=s.equips;s.allowEquip=true;s.flush()
        check(s.equips==before+1 and #new==1 and new[1][1],"stale active callback cannot advance new swap twice")
        check(#old==1 and old[1][2]=="CANCELLED","explicit equipment cancellation completes owner once")
    end
    -- Complete production bank sequence with public live-bank facts and a
    -- cursor/slot transaction model. Cancellation does not undo its first move.
    local function bankBoot()
        local s,R,p,e=boot(client,"missing");s.bank={[1]=2001,[2]=2003};p.equipment[3]={itemID=2003}
        local api=e.Flux.Inventory
        api.IsBankOpen=function()return true end;api.CanTakeFromBank=function()return true end
        api.GetFirstFreeBagSlot=function()for slot=1,4 do if not s.bags[slot]then return 0,slot end end end
        api.Find=function(id,opts)
            local out={}
            if opts.bags then for slot,item in pairs(s.bags)do if id==item then out[#out+1]={bag=0,slot=slot,itemID=id,region="bags"}end end end
            if opts.bank then for slot,item in pairs(s.bank)do if id==item then out[#out+1]={bag=-1,slot=slot,itemID=id,region="bank"}end end end
            return out
        end
        e.C_Container.PickupContainerItem=function(bag,slot)
            check(not s.combat,"bank/gear pickup respects combat")
            s.pickups=s.pickups+1
            local slots=bag==0 and s.bags or s.bank;local previous=slots[slot]
            slots[slot]=s.cursor and s.cursor.id or nil
            s.cursor=previous and {id=previous,slot=slot,bag=bag}or nil
        end
        return s,R,p
    end
    do
        local s,R,p=bankBoot();local results={};local done=function(ok,why)results[#results+1]={ok,why}end
        R.Equipment.ApplyWithCallback(p.equipment,done)
        check(s.bags[1]==2001 and s.bank[2]==2003 and #s.timers==1,"bank sequence keeps 80ms step cadence")
        local before=s.pickups;R.Equipment.CancelPendingApply(done);s.flush()
        check(s.pickups==before and s.bank[2]==2003 and s.equips==0,"cancelled bank timer cannot withdraw second item or start gear")
        check(#results==1 and results[1][2]=="CANCELLED" and not R.Equipment._bankWithdrawInProgress,"bank request ownership retires cleanly")
    end
    do
        local s,R,p=bankBoot();local results={}
        R.Equipment.ApplyWithCallback(p.equipment,function(ok)results[#results+1]=ok end)
        s.flush();s.flush();s.flush()
        check(#results==1 and results[1] and s.equipped[1]==2001 and s.equipped[3]==2003,"ordinary bank withdrawal still completes full equipment request")
    end
end
print(("Respec equipment completion: %d checks; five clients; missing/partial/retry/combat/locks/bank/replacement ownership PASS"):format(checks))
