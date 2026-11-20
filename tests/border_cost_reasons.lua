-- Actual renderer/preflight with modeled native primitives. Diagnostic fields
-- reuse existing read reasons; these assertions make no native CPU/FPS claim.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
if arg[1]then local n;prefix,n=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return'read('..string.format('%q',arg[1])..')'end);assert(n==1)end
local fixture=assert(load(prefix..'\nreturn fixture','@border-cost-reasons-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function upvalue(fn,wanted)
 for i=1,100 do local name,value=debug.getupvalue(fn,i);if not name then break end;if name==wanted then return value end end
 error('missing production preflight state '..wanted)
end
local function count(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
local getterNames={'GetRect','GetLeft','GetBottom','GetParent','GetEffectiveScale','GetFrameStrata','GetFrameLevel','IsShown','IsVisible','GetAlpha','GetEffectiveAlpha','GetTexture','GetTexCoord','GetVertexColor','GetObjectType','GetDrawLayer','GetNumMaskTextures','GetNumPoints','GetPoint'}
local function scene(style,watched)
 local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,'class')
 local root=new(e.UIParent)
 local h=piece(root,'Top',{0,-9,100,17});local v=piece(root,'Left',{41,-40,16,80})
 local h2=piece(root,'Top',{200,-9,100,17});local v2=piece(root,'Left',{241,-40,16,80})
 flush()
 local report,enabled={},watched
 e.Flux.PerfCapture={GetActiveWatchReport=function()if enabled then return report end end}
 local clocks=0;e.debugprofilestop=function()clocks=clocks+1;return 1000000000+clocks end
 local native={};local methods=getmetatable(h).__index
 for _,key in ipairs(getterNames)do local original=assert(methods[key],key);methods[key]=function(self,...)native[key]=(native[key]or 0)+1;return original(self,...)end end
 local secret=setmetatable({},{__tostring=function()error('private reason formatting')end,__lt=function()error('private ordering')end,__le=function()error('private ordering')end,__add=function()error('private arithmetic')end,__sub=function()error('private arithmetic')end})
 e.issecretvalue=function(value)return rawequal(value,secret)end
 local function expected()
  local pending=upvalue(j.Flush,'pendingObjects');local clipped=upvalue(j.Flush,'clipped')
  local state={fullInvalidation=upvalue(j.Flush,'fullDirty')==true,pendingObjects=count(pending),paintObjects=count(upvalue(j.Flush,'paintDirty')),waitingRetire=0,waitingAlpha=0,waitingColor=0}
  for object in pairs(pending)do local entry=clipped[object];if entry then
   for _,key in ipairs{'waitingRetire','waitingAlpha','waitingColor'}do if entry[key]then state[key]=state[key]+1 end end
  end end
  return state
 end
 local function last(expectedState,label)
  local cost=report.borderLast
  check(type(cost)=='table'and type(cost.readReasons)=='table'and type(cost.dirtyState)=='table',label..': active watch owns reason/state fields')
  check(#cost.readReasons<=3,label..': existing reason limit retained')
  for _,reason in ipairs(cost.readReasons)do check(type(reason)=='string',label..': only guarded existing strings are retained')end
  for key,value in pairs(expectedState)do check(cost.dirtyState[key]==value,label..': entry state captured before clearing '..key)end
  for _,key in ipairs{'snapshotChanges','materialChanges','uvChanges'}do check(type(cost.dirtyState[key])=='number'and cost.dirtyState[key]>=0,label..': public bounded change count '..key)end
  return cost
 end
 return {j=j,h=h,v=v,h2=h2,v2=v2,flush=flush,e=e,report=report,native=native,expected=expected,last=last,secret=secret,
  setWatch=function(value)enabled=value end,clockCount=function()return clocks end}
end
for _,style in ipairs{1,2}do
 local off,on=scene(style,false),scene(style,true)
 for _,s in ipairs{off,on}do s.h.rect[3]=110;s.j:Invalidate(nil,s.h);s.entry=s.expected();s.flush()end
 check(off.clockCount()==0 and off.report.borderLast==nil and off.report.borderPeak==nil,'watch-off renderer adds no cost/report fields or clock calls')
 check(off.j.stats.readReasons==nil and off.j.stats.dirtyState==nil,'diagnostic state is not promoted to persistent default renderer stats')
 for _,key in ipairs(getterNames)do check((off.native[key]or 0)==(on.native[key]or 0),'watch fields add no native getter reads: '..key)end
 local c=on.last(on.entry,'actual width change')
 check(c.kind=='build'and c.dirtyState.snapshotChanges==1 and #c.readReasons==1,'one changed public width produces one current snapshot reason')
 check(c.readReasons[1]:find('width',1,true)or c.readReasons[1]:find(':w ',1,true),'reason identifies the actual changed geometry property')
 local lines={};on.e.Flux.Print=function(line)lines[#lines+1]=line end;on.e.SlashCmdList.FLUXBORDERS('why')
 local found=false;for _,line in ipairs(lines)do if line:find(c.readReasons[1],1,true)then found=true end end
 check(found,'cost row reuses the existing read-reason text printed by why')
 on.j:Invalidate(nil,on.h);local expected=on.expected();on.flush();c=on.last(expected,'unchanged request')
 check(c.kind=='unchanged'and #c.readReasons==0 and c.dirtyState.snapshotChanges==0 and c.dirtyState.materialChanges==0 and c.dirtyState.uvChanges==0,'unchanged request publishes zero changes without stale reasons')
 on.h:SetTexture(on.h.path);expected=on.expected();on.flush();c=on.last(expected,'unchanged material setter')
 check(c.kind=='unchanged'and c.dirtyState.paintObjects>0 and c.dirtyState.materialChanges==0 and c.dirtyState.uvChanges==0,'paint requests are counted while identical material remains unchanged')
 on.h:SetTexture('cost-reason-material.tga');expected=on.expected();on.flush();c=on.last(expected,'material update')
 check(c.dirtyState.materialChanges==1 and c.dirtyState.uvChanges==0,'material counter reflects the actual existing source comparison')
 check(table.concat(c.readReasons,'; '):find('source material/availability changed',1,true),'material row reuses existing material reason')
 local uv={on.h:GetTexCoord()};uv[1]=uv[1]+.001;on.h:SetTexCoord(table.unpack(uv));expected=on.expected();on.flush();c=on.last(expected,'UV update')
 check(c.dirtyState.uvChanges==1 and c.dirtyState.materialChanges==0,'UV counter records one changed source rather than every UV component')
 check(table.concat(c.readReasons,'; '):find(':UV1 ',1,true),'UV row reuses the existing numeric UV reason')
 on.h:SetVertexColor(on.secret,.5,.8,1);expected=on.expected()
 check(expected.waitingColor>0 and expected.waitingRetire>0,'actual restricted-color hook queues the existing retirement state')
 on.flush();c=on.last(expected,'restricted color retirement')
 check(table.concat(c.readReasons,'; '):find('restricted RGB retirement',1,true),'restricted color stores a public retirement reason without formatting opaque values')
 on.h:SetVertexColor(.2,.5,.8,1);expected=on.expected();on.flush();c=on.last(expected,'public color recovery')
 check(table.concat(c.readReasons,'; '):find('public RGB recovery',1,true),'public recovery retains its existing reason before flags clear')
 on.h:SetAlpha(on.secret);expected=on.expected();check(expected.waitingAlpha>0,'actual restricted-alpha hook queues existing alpha recovery state')
 on.flush();on.last(expected,'restricted alpha')
 on.h:SetAlpha(1);expected=on.expected();on.flush();on.last(expected,'public alpha recovery')
 -- Four actual dirty objects plus full invalidation exceed the report cap.
 for _,object in ipairs{on.h,on.v,on.h2,on.v2}do object.rect[1]=object.rect[1]+1;on.j:Invalidate(nil,object)end
 on.h2.rect[1]=on.secret;on.j:Invalidate(true);expected=on.expected();on.flush();c=on.last(expected,'bounded mixed public/private snapshots')
 check(c.dirtyState.fullInvalidation and c.dirtyState.snapshotChanges>=4 and #c.readReasons==3,'change counters remain complete while reason strings stay capped at three')
 check(c.readReasons[1]=='load/settings/global invalidation','full invalidation keeps the original first reason')
 on.h2.rect[1]=201;on.j:Invalidate(nil,on.h2);expected=on.expected();on.flush();on.last(expected,'private geometry recovery')
 local previous=on.report.borderLast;local clocks=on.clockCount();on.setWatch(false)
 on.h.rect[3]=120;on.j:Invalidate(nil,on.h);on.flush()
 check(on.clockCount()==clocks and on.report.borderLast==previous,'stopping the watch leaves the retained report unchanged and performs no diagnostic clocks')
 -- An inaccessible report is not treated as a writable capture table.
 on.e.Flux.PerfCapture.GetActiveWatchReport=function()return on.secret end
 on.h.rect[3]=130;on.j:Invalidate(nil,on.h);check(pcall(on.flush),'private report availability cannot disrupt the real renderer')
 check(on.clockCount()==clocks and on.report.borderLast==previous,'private report creates no new diagnostic cost')
end
print('Border cost reasons: '..checks..' checks PASS; actual watched preflight reasons/counts, unchanged rows, native getter parity, private retirement/recovery and bounded output; native timings unmeasured')
