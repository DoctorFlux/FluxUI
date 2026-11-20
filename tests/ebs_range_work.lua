-- Exact whole painter + range/event/scheduler producer; native API sinks modeled.
-- Allocation is a desktop regression gate, not native FPS/GC/taint acceptance.
local paintSource=arg[1]
local support=arg[2]or'tests/support/ebs_range_work_model.txt'
local sourceRoot=arg[3]or'.'
local model=assert(loadfile(support))()
local cases,checks,failures=0,0,0
local function check(v,label)
 checks=checks+1
 if not v then failures=failures+1;print('FAIL '..label)end
end
local function eq(a,b,label)check(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local function tuple(a,b,label)
 eq(a.n,b.n,label..' arity')
 for i=1,b.n do eq(a[i],b[i],label..' result'..i)end
end
for _,client in ipairs({'midnight','forever','classic','era','anniversary'})do
 local function case(label,fn)
  cases=cases+1
  local s=model.new(sourceRoot,client,paintSource)
  local ok,err=pcall(fn,s,s.flux,s.paint,s.probe)
  check(ok,client..' '..label..' completed'..(ok and''or': '..tostring(err)))
  check(#s.errors==0,client..' '..label..' no producer error')
 end
 case('real producer',function(s,F,p)
  s.instrumentRange()
  F.EBS.RegisterButton(s.button('spell',101));F.EBS.RegisterButton(s.button('spell',101))
  F.EBS.RegisterButton(s.button('item',201));F.EBS.RegisterBadge(s.button('spell',103))
  local macroItem=s.button('macrotext',202);macroItem.MacroMode='item';macroItem.ItemId=202
  F.EBS.RegisterButton(macroItem)
  local toy=s.button('toy',203);toy.ItemId=203;s.itemSpellID=501;F.EBS.RegisterButton(toy)
  local parked=s.button('item',999);parked.Widget.visible=false;F.EBS.RegisterButton(parked)
  for i=1,3 do s.advance(.18)end
  eq(s.counts.rangePaint,18,'three ticker sweeps paint six active hosts and skip parked')
  eq(s.counts.spell,9,'shared same-ID plus toy effect and badge range probes')
  eq(s.counts.item,6,'item and macro-item range probes')
  eq(s.counts.itemSpell,5,'live toy effects plus initial item-usability reads')
  eq(F.Scheduler.stats.tierFlushes.eval,3,'original scheduler delivery cadence')
  s.dispatch('PLAYER_FOCUS_CHANGED');s.dispatch('PLAYER_FOCUS_CHANGED')
  eq(s.counts.rangePaint,18,'events do not inline paint')
  s.drain();eq(s.counts.rangePaint,24,'same-turn events coalesce original next-turn paint')
 end)
 case('dynamic spell getter and arity',function(s,F,p,probe)
  local b=s.button();local reads=0
  F.Range={ResolveUnit=function()return'target'end}
  setmetatable(F.Range,{__index=function(_,k)
   if k=='CheckSpell'then reads=reads+1;return function(id,u)return id,u,nil,'tail'end end
  end})
  tuple(model.pack(probe(b)),model.pack(101,'target',nil,'tail'),'all public spell results')
  eq(reads,2,'guard/call getter callbacks both execute')
 end)
 case('captured range owner',function(s,F,p,probe)
  local b=s.button();local old=F.Range
  old.ResolveUnit=function()F.Range={CheckSpell=function()error('foreign replacement')end};return'focus'end
  old.CheckSpell=function(id,u)return id,u end
  tuple(model.pack(probe(b)),model.pack(101,'focus'),'old local owner survives callback')
 end)
 case('item late revision and reentry',function(s,F,p,probe)
  local b=s.button('item',201);local R=F.Range;local depth=0
  R.GetUnitRevision=function()error('early revision access')end
  R.CheckItem=function()
   R.GetUnitRevision=function()return 7 end
   depth=depth+1
   if depth==1 then tuple(model.pack(probe(b)),model.pack(false,false),'nested first item')end
   depth=depth-1;return false,true,'discarded'
  end
  tuple(model.pack(probe(b)),model.pack(false,true),'outer reads nested state after callback')
  eq(b._fluxRangeItem,201,'owned item marker');eq(b._fluxRangeRevision,7,'late revision')
 end)
 case('toy fallback',function(s,F,p,probe)
  local b=s.button('toy',203);b.ItemId=203;s.itemSpellID=501;local itemCalls=0
  F.Range.CheckSpell=function()return nil,'discarded'end
  F.Range.CheckItem=function(id)eq(id,203,'toy item fallback ID');itemCalls=itemCalls+1;return false,true end
  tuple(model.pack(probe(b)),model.pack(false,false),'nil spell falls back to exact item')
  F.Range.CheckSpell=function()return false,'narrowed'end
  tuple(model.pack(probe(b)),model.pack(false),'toy returns only primary spell result')
  eq(itemCalls,1,'false spell does not item-fallback')
 end)
 case('raw opaque error and partial state',function(s,F,p,probe)
  local b=s.button();b._fluxRangeItem=99;local marker={}
  F.Range.CheckSpell=function()error(marker,0)end
  tuple(model.pack(pcall(probe,b)),model.pack(false,marker),'opaque callback error object')
  eq(b._fluxRangeItem,nil,'spell marker cleared before raw callback error')
 end)
 for _,kind in ipairs({'spell','item'})do
  case(kind..' range allocation',function(s,F,p)
   local b=s.button(kind,kind=='item'and 201 or 101)
   if kind=='item'then s.blocked=true end
   s.note=function()end;s.trace={}
   for i=1,300 do p.UpdateRange(b)end
   collectgarbage('collect');collectgarbage('stop')
   local before=collectgarbage('count');local units=s.counts.unit
   local native=s.counts.spell+s.counts.item
   for i=1,5000 do p.UpdateRange(b)end
   local growth=collectgarbage('count')-before
   collectgarbage('restart')
   check(growth<1,kind..' temporary query allocation grows across5000 calls: '..growth..'KiB')
   eq(s.counts.unit-units,5000,'all unit getter calls retained')
   eq(s.counts.spell+s.counts.item,native,'existing same-frame native range memo retained')
   eq(#s.trace,0,'fixture trace does not grow')
  end)
 end
end
print(('EBS_RANGE_WORK cases=%d checks=%d failures=%d native_FPS_GC_taint=NOT_RUN'):format(cases,checks,failures))
os.exit(failures==0 and 0 or 1)
