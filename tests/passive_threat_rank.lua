-- Real rank implementations; tie ordering and inaccessible-data fallbacks retained.
local source=arg[1] or 'Core/API/Threat.lua'
local baseline=arg[2]
local output=arg[3]
local function read(p) local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local current=read(source)
local old
if baseline then old=read(baseline) else
 local a=assert(current:find('function Threat.GetPlayerRank(',1,true));local b=assert(current:find('\nlocal function ForeverMeterRow',a,true))
 old=current:sub(1,a-1)..read('tests/fixtures/passive_threat_rank_before.txt')..current:sub(b)
end
local checks=0
local function check(v,why) checks=checks+1;assert(v,why) end
local opaque=setmetatable({}, {__lt=function() error('secret compare') end,__tostring=function() error('secret tostring') end})
local function boot(body,group,pets,mode,sample)
 local counts={identity=0,guid=0,detailed=0}
 local function id(unit)
  if unit=='player' then return 'member1' end
  if unit=='pet' then return pets and 'pet1' or nil end
  local n=tonumber(unit:match('^raid(%d+)$'));if n and n<=group then return 'member'..n end
  n=tonumber(unit:match('^raidpet(%d+)$'));if pets and n and n<=group then return 'pet'..n end
  n=tonumber(unit:match('^party(%d+)$'));if n and n<group then return 'member'..(n+1) end
  n=tonumber(unit:match('^partypet(%d+)$'));if pets and n and n<group then return 'pet'..(n+1) end
  if unit=='target' then return 'target' end
 end
 local env=setmetatable({UnitExists=function(u) return id(u)~=nil end,IsInRaid=function() return group>5 end,
  IsInGroup=function() return group>1 end,GetNumGroupMembers=function() return group end,
  UnitIsUnit=function(a,b) counts.identity=counts.identity+1;return id(a)==id(b) end,
  UnitDetailedThreatSituation=function(u)
   counts.detailed=counts.detailed+1;local identity=id(u);local n=assert(tonumber(identity:match('%d+$')))
   if sample%13==0 and n%3==0 then return nil end
   if sample%17==0 and n%4==0 then error('query failed') end
   local value=(sample*n)%7 -- many exact ties, including cross-pet aliases
   local tank=sample%9==0 and n==1 or sample%5==0 and n==2
   if sample%11==0 and n%2==0 then value=opaque end
   return tank,1,50,50,value
  end}, {__index=_G});env._G=env
 if mode~='missing' then env.UnitGUID=function(u)
  counts.guid=counts.guid+1
  if mode=='failed' then error('GUID unavailable') end
  if mode=='secret' then return opaque end
  if mode=='mixed' and u:find('pet',1,true) then return opaque end
  return id(u)
 end end
 local ns={Flux={Client={isForever=true},Secrets={IsSecretValue=function(v) return rawequal(v,opaque) end,CanAccessValue=function(v) return not rawequal(v,opaque) end}}}
 assert(load(body,'@rank-production','t',env))('_FluxUI',ns)
 return ns.Flux.Threat,counts,env
end
for _,group in ipairs({1,5,40}) do for _,pets in ipairs({false,true}) do
 for _,mode in ipairs({'public','missing','failed','secret','mixed'}) do for sample=1,55 do
  local before=boot(old,group,pets,mode,sample);local after=boot(current,group,pets,mode,sample)
  check(before.GetPlayerRank('target')==after.GetPlayerRank('target'),'rank parity group/pets/GUID/ties/query errors/secret threat')
 end end
end end
local rows={}
for _,pets in ipairs({false,true}) do
 local before,bc=boot(old,40,pets,'public',2);local after,ac=boot(current,40,pets,'public',2)
 for i=1,100 do check(before.GetPlayerRank('target')==after.GetPlayerRank('target'),'steady rank') end
 check(ac.identity<bc.identity/10,'public GUID identity work must drop by >90%')
 check(ac.detailed==bc.detailed,'all detailed threat samples retained')
 rows[#rows+1]={pets=pets,before=bc,after=ac}
 print(('RANK pets=%s before_identity=%d after_identity=%d before_detailed=%d after_detailed=%d GUID=%d'):format(tostring(pets),bc.identity,ac.identity,bc.detailed,ac.detailed,ac.guid))
end
do
 local threat=boot(current,5,true,'public',2)
 local failed=true
 local fs={SetFormattedText=function() if failed then error('temporary text sink failure') end end,
  SetText=function() if failed then error('temporary text sink failure') end end}
 check(threat.SetRankPercentText(fs,2,50)==false,'failed text sinks report failure to invalidate output cache')
 failed=false
 check(threat.SetRankPercentText(fs,2,50)==true,'recovered text sink reports successful retry')
end
for _,mode in ipairs({'public','failed','secret','mixed'}) do
 local direct, directReads=boot(current,40,true,mode,2)
 local batched, batchedReads=boot(current,40,true,mode,2)
 local batch={}
 for _=1,12 do
  check(direct.GetPlayerRank('target')==batched.GetPlayerRankForNameplateBatch('target',batch),
   'rank stays per target when group identity reads are shared')
 end
 check(directReads.detailed==batchedReads.detailed,'a non-tank batch retains every target-specific detail sample')
 if mode=='public' then
  check(batchedReads.guid*12==directReads.guid,'only the first public group identity read remains')
 elseif mode=='mixed' then
  check(batchedReads.guid<directReads.guid and batchedReads.guid>directReads.guid/12,'private pet identities remain fresh')
 else
  check(batchedReads.guid==directReads.guid,'unusable identities use fresh guarded reads')
 end
end
do
 local threat,reads,env=boot(current,40,true,'public',9)
 check(threat.GetPlayerRank('target')==1 and reads.detailed==1,
  'a sampled tanking player already has rank one')
 local batch={}
 threat.GetPlayerRankForNameplateBatch('target',batch)
 local old=env.UnitGUID
 env.UnitGUID=function(unit) return unit=='player' and 'replacement-player' or old(unit) end
 threat.GetPlayerRankForNameplateBatch('target',batch)
 check(batch.threatRankGUIDs.player=='replacement-player','a changed GUID provider starts a fresh batch sample')
 local external=0
 threat.GetPlayerRank=function(unit,...)
  check(unit=='target' and select('#',...)==0,'replaced rank provider keeps the original call signature')
  external=external+1
  return 3
 end
 check(threat.GetPlayerRankForNameplateBatch('target',batch)==3 and external==1,'batch uses an externally replaced rank method')
end
if output then local f=assert(io.open(output,'wb'));f:write('checks=',checks,'\n');for _,r in ipairs(rows) do for _,phase in ipairs({'before','after'}) do for k,v in pairs(r[phase]) do f:write(tostring(r.pets),' ',phase,' ',k,'=',v,'\n') end end end;f:close() end
print('PASS threat rank: '..checks..' actual-code checks; native secret permissions/FPS not measured')
