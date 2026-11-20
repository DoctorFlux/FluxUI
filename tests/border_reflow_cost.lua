-- Finite-watch-only phase clocks; retained geometry and normal idle work stay
-- independent of optional diagnostic availability.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@border-cost-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function upvalue(fn,wanted)
 for i=1,100 do local name,value=debug.getupvalue(fn,i);if not name then break end;if name==wanted then return value end end
 error('missing production helper '..wanted)
end
for _,style in ipairs{1,2}do
 local j,new,piece,flush,objects,locked,choose,_,e=fixture();choose(style,'class')
 local calls=0
 e.debugprofilestop=function()calls=calls+1;return 1000000000+calls end
 local root=new(e.UIParent);local h=piece(root,'Top',{0,-9,100,17});piece(root,'Left',{41,-40,16,80});flush()
 check(calls==0,'default renderer never asks the optional phase clock')
 local report
 e.Flux.PerfCapture={GetActiveWatchReport=function()return report end}
 report={};h.rect[3]=110;j:Invalidate(nil,h);flush()
 local peak=report.borderPeak
 check(peak and peak.kind=='build'and peak.total>0,'a watched real reflow records consumed build cost')
 check(peak.borderVersion==j.version,'saved native cost retains the exact loaded border revision')
 local sum=0
 for _,key in ipairs{'preflight','align','geometry','solve','plan','commit'}do
  check(type(peak.phases[key])=='number'and peak.phases[key]>=0,'bounded phase is recorded: '..key)
  sum=sum+peak.phases[key]
 end
 check(sum==peak.total,'phase costs partition this consumed pass without adding overlapping spans')
 check(peak.operations==j.stats.operations and peak.triangles==j.stats.triangles,'cost row records the actual committed mesh counts')
 check(peak.baseHits==j.stats.compileHits and peak.baseMisses==j.stats.compileMisses,
  'native peak retains its exact prepared-geometry reuse counters')
 check(peak.sourceReads==j.stats.sourceReads and peak.sourceHits==j.stats.sourceHits
  and peak.fallbackProbes==j.stats.fallbackProbes,'peak stores consumed source and fallback lookup counts')
 check(peak.fallbackPlanHits==j.stats.fallbackPlanHits and peak.fallbackPlanMisses==j.stats.fallbackPlanMisses,
  'peak stores exact full-op fallback plan reuse counts')
 check(peak.commitPhases and peak.commitPhases.fragments>=0 and peak.commitPhases.mesh>=0,
  'watched commit records its fragment and branch work separately')
 local mesh=peak.meshPhases
 check(peak.started>100000000 and mesh and mesh.prepare==1 and mesh.draw==1,
  'one midpoint at large uptime splits preparation/drawing without a coordinate-number cap')
 check(mesh.prepare+mesh.draw==peak.commitPhases.mesh,
  'nested mesh phases partition the original fallback-end/mesh-end aggregate')
 check(peak.commitPhases.prepare==nil and peak.commitPhases.draw==nil,
  'nested mesh detail adds no overlapping flat commit phases')
 check(peak.work and peak.work.fieldCalls==peak.work.fieldHits+peak.work.fieldWrites,
  'cached native setter hit and write counters partition actual helper calls')
 check(peak.planPhases and peak.planPhases.branches>=0 and peak.planPhases.fallbackMesh>=0,
  'watched planning separates compilation from fallback fields')
 j:Invalidate(nil,h);flush()
 check(report.borderLast.kind=='unchanged'and report.borderPeak==peak,'quiet preflights do not erase the captured expensive pass')
 check(report.borderLast.meshPhases==nil and report.borderPeak.meshPhases==mesh,
  'unchanged last has no mesh while the owned peak retains its original nested row')
 local lines={};e.Flux.Print=function(line)lines[#lines+1]=line end
 e.SlashCmdList.FLUXBORDERS('cost')
 check(#lines==5 and lines[1]:find('Border peak ',1,true)and lines[1]:find(' commit=',1,true)
  and lines[3]:find('Border commit ',1,true)and lines[4]:find('Border work ',1,true)
  and lines[5]:find('Border plan ',1,true),'short command reads cached phase/work rows and no layout')
 check(lines[2]:find('fallbackPlanHits=',1,true)and lines[2]:find('fallbackPlanMisses=',1,true),
  'existing five-row command includes full-op plan counters without another report')
 local reads,solves=j.stats.geometryReads,j.stats.solves
 local before=calls;report=nil;j:Invalidate(true);flush()
 check(calls==before and j.stats.solves==solves+1,'stopping the watch removes every phase clock while real layouts still work')
 local private=setmetatable({}, {__lt=function()error('private clock compared')end,__le=function()error('private clock compared')end,__sub=function()error('private clock used')end})
 e.issecretvalue=function(v)return rawequal(v,private)end
 for _,mode in ipairs{'secret','error','missing','nan','infinity','negative'}do
  report={}
  if mode=='missing'then e.debugprofilestop=false else e.debugprofilestop=function()
   if mode=='secret'then return private end
   if mode=='error'then error('optional clock unavailable')end
   if mode=='nan'then return 0/0 end
   if mode=='infinity'then return math.huge end
   return -1
  end end
  j:Invalidate(true);check(pcall(flush),'optional clock failure cannot interrupt rendering')
  check(report.borderPeak==nil,'unavailable clock publishes no fabricated cost')
  lines={};e.SlashCmdList.FLUXBORDERS('cost')
  check(#lines==1 and lines[1]:find('run /fluxperf watch',1,true),'new unavailable capture cannot print stale prior-session timing')
 end
 check(j.stats.geometryReads>reads and j.stats.fallback==nil,'optional diagnostics preserve actual render reflows')
 -- Exercise the actual loaded helpers. The caller must sanitize an opaque
 -- numeric clock before CommitCost orders it, and bad optional detail must
 -- never invalidate an otherwise healthy legacy span.
 local commit=upvalue(j.Flush,'CommitCost');local clock=upvalue(commit,'CostClock')
 local oldType=e.type
 e.type=function(v)if rawequal(v,private)then return'number'end;return type(v)end
 local base=1000000000
 for _,mode in ipairs{'nil','error','secret','nan','infinity','negative','early','late','missing'}do
  if mode=='missing'then e.debugprofilestop=false else e.debugprofilestop=function()
   if mode=='nil'then return nil end
   if mode=='error'then error(private,0)end
   if mode=='secret'then return private end
   if mode=='nan'then return 0/0 end
   if mode=='infinity'then return math.huge end
   if mode=='negative'then return -1 end
   return mode=='early'and base-1 or base+31
  end end
  local middle=clock()
  e.debugprofilestop=function()return base+30 end
  local cost={commitLast=base,commitPhases={}}
  check(pcall(commit,cost,'mesh',middle),'optional midpoint failure is contained: '..mode)
  check(not cost.invalid and cost.commitLast==base+30 and cost.commitPhases.mesh==30,
   'valid legacy mesh survives the faulty optional midpoint: '..mode)
  check(cost.meshPhases==nil,'faulty midpoint publishes no fabricated nested row: '..mode)
 end
 e.type=oldType
 -- A real draw setter failure happens after the midpoint but before the old
 -- mesh endpoint. Preserve its raw error and rollback, then recover normally.
 e.debugprofilestop=function()calls=calls+1;return base+calls end
 local methods=getmetatable(h).__index;local setUV=methods.SetTexCoord;local drawError={}
 methods.SetTexCoord=function(field,...)
  if field._junctionOwnerOp then error(drawError,0)end
  return setUV(field,...)
 end
 report={};h.rect[3]=h.rect[3]+1;j:Invalidate(nil,h)
 local ok,err=pcall(flush)
 methods.SetTexCoord=setUV
 check(not ok and rawequal(err,drawError),'a real draw setter preserves its exact opaque failure')
 check(report.borderLast and report.borderLast.kind=='error'and report.borderLast.meshPhases==nil,
  'failed draw publishes no completed nested mesh')
 j:Invalidate(true);flush()
 check(report.borderLast.kind=='build'and report.borderLast.meshPhases and j.stats.fallback==nil,
  'existing transactional recovery rebuilds healthy mesh detail')
end
print('Border reflow cost: '..checks..' checks PASS; existing finite-watch epochs; legacy aggregate/nested mesh algebra; retained peak; zero default clocks; opaque/faulty midpoint and draw recovery; native timings pending')
