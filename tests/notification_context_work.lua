-- Production Init queue contexts; synthetic clock, metadata source and frames.
-- Args: Init.lua path, --measure to report baseline work without candidate budget.
local path=arg[1]or"Inventory/Init.lua"
local measure=arg[2]=="--measure"
local f=assert(io.open(path,"rb"));local code=f:read("*a");f:close()
local checks=0
local function eq(a,b,label)checks=checks+1;assert(a==b,label..": "..tostring(a).." != "..tostring(b))end
local function has(t,id) return t and t[id] or nil end
local function boot()
 local s={now=100,frames={},timers={},meta={},work=0,copies=0}
 local e=setmetatable({}, {__index=_G});e._G=e;e.SlashCmdList={}
 e.GetTime=function()return s.now end
 e.CreateFrame=function()
  local f={scripts={}}
  function f:SetScript(k,v)self.scripts[k]=v end
  function f:RegisterEvent()end
  function f:UnregisterEvent()end
  s.frames[#s.frames+1]=f;return f
 end
 local flux={Cap={},Client={},Module={Register=function()end},Safecall=function(fn,...)return fn(...)end}
 flux.Timer={After=function(dt,fn)s.timers[#s.timers+1]={at=s.now+dt,fn=fn}end};e.C_Timer=flux.Timer
 assert(load(code,"@notification-context-production","t",e))("_FluxUI",{Flux=flux})
 local inv=flux.Inventory;s.inv,s.env,s.flux=inv,e,flux
 inv.source="builtin";inv.IsBankOpen=function()return false end
 inv.Builtin.Bags={
  GetLastChangeKind=function()if s.meta.error then error(s.meta.error,0)end;return s.meta.kind or"countOnly"end,
  GetLastAddedItemIDs=function()return s.meta.add end,
  GetLastRemovedItemIDs=function()return s.meta.rem end,
  GetLastRefreshedDirtyBags=function()return s.meta.dirty end,
  TakeItemSets=function()return s.meta.touch,s.meta.changed end,
 }
 local line,copyLine=0
 for text in (code.."\n"):gmatch("(.-)\n")do line=line+1;if text:find("for id in pairs(src)",1,true)then copyLine=line end end
 e.pairs=function(t)
  local info=debug.getinfo(2,"Sl")
  local copy=info and info.source=="@notification-context-production"and info.currentline==copyLine
  if copy then s.copies=s.copies+1 end
  local iter,state,key=pairs(t)
  return function(st,last)local k,v=iter(st,last);if k~=nil and copy then s.work=s.work+1 end;return k,v end,state,key
 end
 function s:emit(meta,tokens)self.meta=meta or{};self.inv.Notify(tokens or{bags=true,tier="light"})end
 function s:step(dt)
  self.now=self.now+dt
  local due=self.timers;self.timers={}
  for _,t in ipairs(due)do if t.at<=self.now then t.fn()else self.timers[#self.timers+1]=t end end
  local frames={};for i,v in ipairs(self.frames)do frames[i]=v end
  for _,f in ipairs(frames)do local fn=f.scripts.OnUpdate;if fn then fn(f,dt)end end
 end
 function s:drain()for _=1,100 do self:step(.016)end end
 return s
end

do
 local s=boot();local inv=s.inv;local first,second
 inv.Register("one",function(ctx)first=ctx end,{tier="scan",regions={"bags","mail"}})
 inv.Register("two",function(ctx)second=ctx end,{tier="heavy",regions={"bags","mail"}})
 local add,touch,changed,dirty={[10]=true},{[10]=true},{[10]=true},{[0]=true}
 s:emit({kind="identityChanged",add=add,touch=touch,changed=changed,dirty=dirty})
 add[11],touch[11],dirty[1]=true,true,true
 s:drain()
 eq(first.tier,"scan","light promotion keeps scan")
 eq(second.tier,"heavy","light promotion keeps heavy")
 eq(first.changeKind,"identityChanged","initial identity survives")
 eq(has(first.addedItemIDs,10),true,"initial added preserved")
 eq(has(first.addedItemIDs,11),nil,"source added mutation isolated")
 eq(has(first.touchedItemIDs,11),nil,"source touched mutation isolated")
 eq(has(first.dirtyBags,1),nil,"source dirty mutation isolated")
 eq(first.touchedItemIDs==second.touchedItemIDs,false,"listener touched sets isolated")
 first.touchedItemIDs[55]=true
 eq(has(second.touchedItemIDs,55),nil,"retained callback cannot mutate other listener")
end

do
 local s=boot();local got;local inv=s.inv
 inv.Register("merge",function(ctx)got=ctx end,{tier="scan",regions={"bags","mail"}})
 s:emit({kind="identityChanged",add={[10]=true},dirty={[0]=true},touch={[10]=true},changed={[10]=true}})
 s:emit({kind="countOnly",dirty={[1]=true},touch={[20]=true},changed={}})
 inv.Notify({mail=true,tier="light"})
 s:drain()
 eq(got.changeKind,"identityChanged","later count cannot erase identity")
 eq(has(got.addedItemIDs,10),true,"later count keeps earlier addition")
 eq(has(got.dirtyBags,0),true,"first dirty bag survives")
 eq(has(got.dirtyBags,1),true,"second dirty bag survives")
 eq(has(got.touchedItemIDs,10),true,"first touched survives")
 eq(has(got.touchedItemIDs,20),true,"second touched survives")
 eq(has(got.changedItemIDs,10),true,"empty changed set does not erase change")
 eq(got.regions.bags,true,"mail retains queued bags")
 eq(got.regions.mail,true,"mail merges region")
end

for _,missing in ipairs({"touch","changed","dirty"})do
 local s=boot();local got
 s.inv.Register("missing",function(ctx)got=ctx end,{tier="scan",regions={"bags","mail"}})
 s:emit({dirty={[0]=true},touch={[10]=true},changed={[10]=true}})
 local second={dirty={},touch={},changed={}};second[missing]=nil;s:emit(second)
 s:drain()
 local field=missing=="touch"and"touchedItemIDs"or(missing=="changed"and"changedItemIDs"or"dirtyBags")
 eq(got[field],nil,"missing relevant "..field.." means unknown")
end

do
 local s=boot();local got,n
 s.inv.Register("force",function(ctx)got=ctx;n=(n or 0)+1 end,{tier="scan",regions={"bags","mail"}})
 s:emit({kind="identityChanged",rem={[8]=true},touch={[8]=true},changed={[8]=true},dirty={[0]=true}})
 s.inv.Notify({mail=true,force=true,tier="heavy",recovery=true})
 eq(n,1,"forced refresh delivers inline")
 eq(got.regions.bags,true,"forced mail preserves queued bags")
 eq(got.regions.mail,true,"forced mail merged")
 eq(has(got.removedItemIDs,8),true,"forced pass retains pending removal")
 eq(got.tier,"heavy","forced current tier retained")
 eq(got.force,true,"forced flag retained")
 eq(got.recovery,true,"recovery retained")
 s:drain();eq(n,1,"forced refresh retires old queue")
end

do
 local s=boot();local got
 s.inv.Register("sync",function(ctx)ctx.extension={marker=false};ctx.tags={a=true}end,{tier="light",sync=true})
 s.inv.Register("deferred",function(ctx)got=ctx end,{tier="scan",regions={"bags"}})
 -- Choose one permitted listener iteration order for this extension case;
 -- Lua does not guarantee that the sync registration naturally runs first.
 local previous=s.env.pairs
 s.env.pairs=function(t)
  if t.sync and t.sync.key=="sync" and t.deferred and t.deferred.key=="deferred" then
   local i=0;local keys={"sync","deferred"}
   return function()i=i+1;local key=keys[i];if key then return key,t[key]end end,t,nil
  end
  return previous(t)
 end
 s:emit({touch={[1]=true},changed={}})
 s:emit({touch={[2]=true},changed={}})
 s:drain()
 eq(has(got.extension,"marker"),true,"unknown extension field retains set-copy contract")
 eq(has(got.tags,"a"),true,"unknown field is not discarded during merge")
end

do
 local s=boot();local calls=0
 s.inv.Register("replace",function()calls=calls+1 end,{tier="scan"})
 s:emit({touch={},changed={}})
 s.inv.Register("replace",function()calls=calls+10 end,{tier="scan"})
 s:drain();eq(calls,0,"replacement cancels older queued callback")
 s:emit({touch={},changed={}});s.inv.Unregister("replace");s:drain()
 eq(calls,0,"unregister cancels queued callback")
end

do
 local s=boot();local n=0
 s.inv.Register("nested",function()
  n=n+1
  if n==1 then s:emit({kind="identityChanged",add={[99]=true},touch={[99]=true},changed={[99]=true}})end
 end,{tier="scan",regions={"bags"}})
 s:emit({touch={},changed={}});s:drain()
 eq(n,2,"callback reentry queues next notification")
end

do
 local s=boot();local err={raw=true};local called=0
 s.inv.Register("error",function()called=called+1 end,{tier="scan"})
 local ok,value=pcall(function()s:emit({error=err})end)
 eq(ok,false,"source metadata error remains observable")
 eq(value,err,"source raw error object preserved")
 s:emit({touch={},changed={}});s:drain();eq(called,1,"next notification retries after metadata error")
end

do
 local s=boot();local calls=0
 s.inv.Register("deadline",function()calls=calls+1 end,{tier="scan",regions={"bags"}})
 s:emit({touch={},changed={}})
 s:step(.049);eq(calls,0,"quiet callback waits for original deadline")
 s:step(.002);eq(calls,1,"quiet callback runs at original deadline")
end

-- Count the actual key-copy constructor/iterator path, not elapsed native FPS.
local metrics={}
for _,width in ipairs({1,8,32})do
 local s=boot()
 for i=1,width do s.inv.Register("work"..i,function()end,{tier="scan",regions={"bags"}})end
 local touch,changed={},{};for i=1,80 do touch[i],changed[i]=true,true end
 for _=1,20 do s:emit({touch=touch,changed=changed,dirty={[0]=true}})end
 metrics[#metrics+1]=width..":"..s.copies..":"..s.work
 if not measure then eq(s.copies,80*width,"only retained key copies remain "..width)end
 s:drain()
end
print("CONTEXT_WORK "..table.concat(metrics,","))
print("NOTIFICATION_CONTEXT_CHECKS "..checks.." PASS")
