-- Actual renderer registration, with the prior R53 RegisterFallback helper as a
-- local negative/work baseline. No backup paths or native profiling required.
-- Prior full Core LF SHA256: e45902817207a50b408c4290ae594f07c15f5c4dfc7c4118f2b366b17dfbb85c.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local extra=[[
local observerTrace,listenerBacking
return {register=RegisterFallback,paint=PaintFallbackField,
 phase=function(on,traced)fallbackChains=on and{}or nil;fallbackAvailability=on and{}or nil;visibilityListeners={};availabilityCache={}
  if traced then observerTrace={};listenerBacking={};visibilityListeners=setmetatable({},
   {__index=function(_,object)observerTrace[#observerTrace+1]=object;return listenerBacking[object]end,
    __newindex=function(_,object,list)listenerBacking[object]=list end})end end,
 trace=function()local out=observerTrace;observerTrace={};return out end,
 listeners=function()return listenerBacking or visibilityListeners end,
 memos=function()return fallbackChains,fallbackAvailability,visibilityListeners,availabilityCache end,
 regional=function()renderLayers={}end,
 links=function()return fallbackChains.listenerNext end,
 publish=function()
  local tile={visibilityNext=fallbackChains.listenerNext}
  local lists=listenerBacking or visibilityListeners
  visibilityListeners={}
  for object,list in pairs(lists)do visibilityListeners[object]={[tile]=list}end
  fallbackChains,fallbackAvailability,renderLayers=nil,nil,nil
  J.stats.localMode=true
 end,
 visibility=PaintFallbacks,
 entry=function(t,a)clipped[t]={active=true,alpha=a,color={1,1,1,1},pool={}}end}
]]
local priorRegisterFallback=[=[
local function RegisterFallback(field,source,blockers,keepPaint)
    field._fallbackSource=source;field._fallbackBlockers=blockers
    local seen={}
    local function Observe(texture)
        local chain=AvailabilityChain(texture)
        if chain then
            for _,object in ipairs(chain) do if not seen[object] then
                seen[object]=true
                local list=visibilityListeners[object]
                if not list then list={};visibilityListeners[object]=list end
                list[#list+1]=field;availabilityCache[object]=PaintAvailable(object)
            end end
            return
        elseif fallbackChains then return end
        local unit=StaticUnitOwner(texture)
        local object=texture
        for _=1,32 do
            if not object or object==UIParent or object==unit then break end
            if not seen[object] then
                seen[object]=true
                local list=visibilityListeners[object]
                if not list then list={};visibilityListeners[object]=list end
                list[#list+1]=field
                availabilityCache[object]=PaintAvailable(object)
            end
            if object._FluxBorderOwner==unit and unit then break end
            object=object.GetParent and object:GetParent()
        end
    end
    Observe(source)
    for _,owner in ipairs(blockers) do Observe(owner) end
    if not keepPaint then PaintFallbackField(field) end
end
]=]
local currentCore=read('Core/BorderJunctions.lua'):gsub('\r\n','\n')
local function factory(path)
 local source=currentCore
 if path=='archive'then source=read(assert(arg[1])):gsub('\r\n','\n') end
 if path=='baseline'then
  local first=assert(source:find('local function RegisterFallback(',1,true))
  local last=assert(source:find('\ndo\n    local function PaintFallbackList',first,true))
  source=source:sub(1,first-1)..priorRegisterFallback..source:sub(last)
 end
 source=source..extra
 local text,n=prefix:gsub('assert%(load%(read%("Core/BorderJunctions.lua"%),"@Core/BorderJunctions.lua","t",e%)%)%("_FluxUI",{Border=B}%)',
  function()return'e.exports=assert(load('..string.format('%q',source)..',"@register-pair-controls-core","t",e))("_FluxUI",{Border=B})'end)
 assert(n==1);return assert(load(text..'\nreturn fixture','@register-pair-controls-fixture','t',_G))()
end
local checks=0;local function check(ok,m)checks=checks+1;assert(ok,m)end
local function mutateScenario(path,kind)
 local j,new,_,_,_,_,_,_,e=factory(path)();local x=e.exports
 local names={[e.UIParent]='UI'}
 local function object(name,parent,texture)local o=new(parent,nil,texture and'Texture'or'Frame');names[o]=name;return o end
 local root=object('root',e.UIParent);local source=object('source',root,true)
 local a=object('ownerA',object('parentA',root),true)
 local b=object('ownerB',object('parentB',root),true)
 local c=object('ownerC',object('parentC',root),true)
 local blockers={a,b};x.entry(source,.8)
 local secret=setmetatable({}, {__index=function()error('opaque indexed')end,__eq=function()error('opaque compared')end,
  __lt=function()error('opaque ordered')end,__tostring=function()error('opaque formatted')end})
 local privateOwner=false;e.issecretvalue=function(v)return rawequal(v,secret)or(privateOwner and rawequal(v,a))end
 names[secret]='opaque';x.phase(true,true)
 local first=object('first',root,true);x.register(first,source,blockers,false)
 local initial=x.trace();check(#initial>0,'first registration creates listener ordering witness')
 if kind=='same-owner-private'then privateOwner=true
 elseif kind=='replace-private'then blockers[1]=secret
 elseif kind=='replace-public'then blockers[1]=c
 elseif kind=='reorder'then blockers[1],blockers[2]=b,a
 elseif kind=='remove'then blockers[2]=nil
 elseif kind=='append'then blockers[3]=c
 elseif kind=='truncate'then blockers[1]=nil
 elseif kind=='replace-previous-private'then privateOwner=true;blockers[1]=c
 end
 local second=object('second',root,true);x.register(second,source,blockers,false)
 local trace=x.trace();local ordered={};for _,o in ipairs(trace)do ordered[#ordered+1]=names[o]end
 local _,_,_,available=x.memos();local rows={}
 for o,list in pairs(x.listeners())do local row={names[o],available[o]and'T'or'F'}
  for _,f in ipairs(list)do row[#row+1]=names[f]end;rows[#rows+1]=table.concat(row,':')end
 table.sort(rows)
 check(second._fallbackSource==source and second._fallbackBlockers==blockers,'mutation retains exact current bindings')
 if path=='candidate'then
  local chains=x.memos();local record=chains._observerPairs and chains._observerPairs[source]and chains._observerPairs[source][blockers]
  if kind=='unchanged'then check(record and #record.blockers==2,'public ordered blocker snapshot retained')end
  check((chains._observerCost or 0)<=j.limits.fragments,'mutated-pair clones remain inside phase budget')
 end
 return table.concat(ordered,','),table.concat(rows,';'),second:GetAlpha()
end
local function scenario(path,kind)
 local j,new,_,_,_,_,_,_,e=factory(path)();local x=e.exports
 local names={[e.UIParent]='UI'}
 local function object(name,parent,texture)local o=new(parent,nil,texture and'Texture'or'Frame');names[o]=name;return o end
 local root=object('root',e.UIParent)
 local a=object('sourceParent',root);local source=object('source',a,true)
 local b=object('blockerParent',root);local owner=object('owner',b,true)
 local blockers={owner};x.entry(source,.8)
 local secret=setmetatable({}, {__index=function()error('opaque indexed')end,__eq=function()error('opaque compared')end,
  __lt=function()error('opaque ordered')end,__tostring=function()error('opaque formatted')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end;names[secret]='opaque'
 if kind=='private-source'then source=secret
 elseif kind=='private-blocker'then blockers={secret}
 elseif kind=='private-parent'then source.parent=secret
 elseif kind=='missing-blocker-chain'then owner.parent=secret
 elseif kind=='overdepth'then
  local p=root;for i=1,40 do p=object('depth'..i,p)end;owner.parent=p
 elseif kind=='observer-cap'then
  blockers={};for k=1,3 do local p=root;for i=1,25 do p=object('branch'..k..'-'..i,p)end;blockers[k]=object('longOwner'..k,p,true)end
 elseif kind=='budget'then j.limits.fragments=1
 end
 x.phase(true)
 local function field(label)local f=object(label,root,true);x.register(f,source,blockers,false);return f end
 local f1,f2=field('f1'),field('f2')
 local chains,_,listeners,available=x.memos()
 local function signature()
  local rows={}
  for o,list in pairs(listeners)do local values={names[o],available[o]and'T'or'F'}
   for _,f in ipairs(list)do values[#values+1]=names[f]end;rows[#rows+1]=table.concat(values,':')
  end
  table.sort(rows);return table.concat(rows,';')
 end
 local shape=signature()
 local cached=chains and chains._observerPairs and chains._observerPairs[source]and chains._observerPairs[source][blockers]
 if path=='candidate'then
  local eligible=kind=='public'
  check((cached~=nil)==eligible,'only complete known-public within-budget pairs publish: '..kind)
  check((chains._observerCost or 0)<=j.limits.fragments,'phase clone budget never exceeds existing fragment limit')
 end
 check(f1._fallbackSource==source and f1._fallbackBlockers==blockers and f2._fallbackBlockers==blockers,'each field retains exact current source/blocker binding')
 if kind=='public'then
  if path=='candidate'then
   local charge=3+#cached*2+#cached.blockers
   check(chains._observerCost==charge,'ordered blocker snapshot is included in phase clone charge')
   j.limits.fragments=charge-1;x.phase(true);local limited=object('limited',root,true);x.register(limited,source,blockers,false)
   local bounded=x.memos();check(not bounded._observerPairs and not bounded._observerCost,'one-below exact clone budget declines publication')
  end
  x.phase(false);owner.shown=false;x.paint(f1);check(f1:GetAlpha()==.8,'outside-phase live hide recomputes current gate')
  owner.shown=true;x.paint(f1);check(f1:GetAlpha()==0,'outside-phase live show restores disabled alias')
  x.entry(source,secret);owner.shown=false;x.paint(f1);check(rawequal(f1:GetAlpha(),secret),'opaque live alpha goes directly to native sink')
 end
 -- A later phase must not retain partial/private/overdeep failure markers.
 source=object('recoveredSource',a,true);owner.parent=b;blockers={owner};x.entry(source,.7)
 x.phase(true);local recovered=object('recovered',root,true);x.register(recovered,source,blockers,false)
 local c=x.memos();check(c~=chains,'next commit receives a fresh phase container')
 x.phase(false);local c1,c2=x.memos();check(c1==nil and c2==nil,'phase teardown drops observer clones and availability values')
 -- Preserve partial registration before an exception; ReleaseAll clears phase.
 owner.GetParent=function()error('pair-chain getter failure',0)end
 x.phase(true);local bad=object('bad',root,true);local ok,err=pcall(x.register,bad,source,{owner},false)
 check(not ok and tostring(err):find('pair-chain getter failure',1,true),'native getter error propagates without cached partial publication')
 j:ReleaseAll();local c3,c4,ls=x.memos();check(c3==nil and c4==nil and next(ls)==nil,'existing rollback clears phase cache and listeners')
 return shape
end
for _,kind in ipairs{'public','private-source','private-blocker','private-parent','missing-blocker-chain','overdepth','observer-cap','budget'}do
 local baseline=scenario('baseline',kind);local candidate=scenario('candidate',kind)
 check(baseline==candidate,'exact observer field ordering and public availability match baseline: '..kind)
end
for _,kind in ipairs{'unchanged','same-owner-private','replace-private','replace-public','reorder','remove','append','truncate','replace-previous-private'}do
 local orderA,listenersA,alphaA=mutateScenario('baseline',kind)
 local orderB,listenersB,alphaB=mutateScenario('candidate',kind)
 check(orderA==orderB,'same-phase current blocker observer order matches baseline: '..kind)
 check(listenersA==listenersB,'same-phase current blocker listener membership matches baseline: '..kind)
 check(alphaA==alphaB,'same-phase current blocker final alpha matches baseline: '..kind)
end
local function regionalScenario(path)
 local j,new,_,_,_,_,_,_,e=factory(path)();local x=e.exports
 local source=new(e.UIParent,nil,'Texture')
 local holder=new(e.UIParent,nil,'Frame')
 local ownerA,ownerB=new(holder,nil,'Texture'),new(holder,nil,'Texture')
 local a,b={ownerA},{ownerB}
 x.entry(source,.8)
 x.phase(true,true);x.regional()
 local draw,writes={},{}
 for index,blockers in ipairs{a,a,a,b,b,a,a,a}do
  local field=new(e.UIParent,nil,'Texture')
  local alpha=field.SetAlpha
  function field:SetAlpha(value)
   alpha(self,value)
   writes[#writes+1]=index
  end
  draw[index]=field
  x.register(field,source,blockers,false)
  check(field:GetAlpha()==0,'each shown keeper initially hides its fallback')
 end
 local list=x.listeners()[holder]
 local slots,fields,links=#list,{},x.links()
 for _,listener in ipairs(list)do
  if listener._fallbackListenerRun then
   for _,field in ipairs(listener)do fields[#fields+1]=field end
  else
   local field=listener
   while field do
    assert(#fields<#draw,'observer run terminates before revisiting a field')
    fields[#fields+1]=field
    field=links and links[field]
   end
  end
 end
 for i,field in ipairs(draw)do check(fields[i]==field,'observer keeps the exact interleaved paint order')end
 check(#fields==#draw,'shared runs include each field once')
 local visits=#x.trace()
 x.publish()
 writes={}
 holder.shown=false
 x.visibility(holder)
 local order=table.concat(writes,',')
 check(order=='1,2,3,4,5,6,7,8','visibility update paints runs and singles in attachment order')
 for _,field in ipairs(draw)do check(field:GetAlpha()==.8,'keeper hide reveals every fallback in the run')end
 writes={}
 holder.shown=true
 x.visibility(holder)
 check(table.concat(writes,',')==order,'keeper show repeats exact draw order')
 for _,field in ipairs(draw)do check(field:GetAlpha()==0,'keeper show retires the entire visible backup')end
 x.entry(source,.55)
 holder.shown=false
 x.visibility(holder)
 for _,field in ipairs(draw)do check(field:GetAlpha()==.55,'every linked fallback uses fresh source opacity')end
 j:ReleaseAll()
 return slots,visits
end
local slots,visits=regionalScenario('candidate')
check(slots==3,'consecutive pairs share observer entries without merging separated runs')
if arg[1] then
 local oldSlots,oldVisits=regionalScenario('archive')
 check((oldSlots==3 or oldSlots==8) and visits<oldVisits,'share consecutive fallback fields with fewer observer visits')
 print(('REGIONAL_OBSERVERS|synthetic|%d|%d|%d|%d'):format(oldSlots,slots,oldVisits,visits))
end
print('Register pair controls: '..checks..' checks PASS; exact observer order/availability; private/partial/overdepth; clone budgets; outside-phase live opaque paint; next-phase recovery; errors/rollback')
