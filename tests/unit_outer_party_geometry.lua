-- Actual Party Build/wrapper/Paint/QueueRosterPaint; only the outer shell stage
-- is replaced with the corresponding actual Shared source block. Other Shared
-- visual helpers remain the existing fixture's modeled sinks.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local h=read('tests/unit_outer_geometry.lua');h=h:sub(1,assert(h:find('local rows={}',1,true))-1)..'return before,after'
local before,after=assert(load(h,'@outer-geometry-builders','t',_G))()
local source=read('tests/raid_party_frames.lua');local start=assert(source:find('for _,client in ipairs({"live"',1,true));local finish=assert(source:find('    local opaque=setmetatable',start,true))
source=source:sub(1,finish-1):gsub('for _,client in ipairs%({"live","forever","classic","classic_era","classic_anniversary"}%)do','local function partyFixture(client)',1)
local savedArg0=arg[0];arg[0]='tests/raid_party_frames.lua'
local fixture=assert(load(source..'\nreturn e,ns,db,calls,flushTimers,refresh\nend\nreturn partyFixture','@actual-party-fixture','t',_G))()
arg[0]=savedArg0
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local function world(client,stage)
 local e,ns,db,calls,drain,refresh=fixture(client);local P=ns.PartyFrames
 db.partyAsRaid=false;e.mode='party';e.partyCount=4;for i=1,4 do e.pets[i]=true;e.targets[i]=true end
 check(P.ApplyOptions(),'actual Party initialization');refresh();drain()
 local all={};for _,list in ipairs{P.members,P.pets}do for _,f in ipairs(list)do all[#all+1]=f;local p=f;while p do p:Show();p=p:GetParent()end end end;drain()
 for _,f in ipairs(all)do
  f.calls={writes=0,sizeReads=0,countReads=0,pointReads=0,aura=0,placeholder=0,mouse=0,chrome=0};local o=f.outerBorderFrame
  local clear,size,point=o.ClearAllPoints,o.SetSize,o.SetPoint
  o.ClearAllPoints=function(s,...)f.calls.writes=f.calls.writes+1;return clear(s,...)end
  o.SetSize=function(s,...)f.calls.writes=f.calls.writes+1;return size(s,...)end
  o.SetPoint=function(s,...)f.calls.writes=f.calls.writes+1;return point(s,...)end
  o.GetSize=function(s)f.calls.sizeReads=f.calls.sizeReads+1;return s.width or 0,s.height or 0 end
  o.GetNumPoints=function(s)f.calls.countReads=f.calls.countReads+1;return #(s.points or {})end
  o.GetPoint=function(s,i)f.calls.pointReads=f.calls.pointReads+1;return table.unpack(s.points[i])end
  local prior=f.UpdateOuterBorder
  f.UpdateOuterBorder=function(s,...)
   prior(s,...);f.calls.chrome=f.calls.chrome+1
   stage(s,e.combat,s:GetWidth(),s:GetHeight(),s.PortraitFrame~=nil,s.portraitPosition or 'LEFT',s:GetHeight(),s.outerBorderAlignment or 'BOTTOM',s.outerBorderPadding or 35,false)
  end
  f:UpdateOuterBorder()
 end
 local function reset()for _,f in ipairs(all)do for k in pairs(f.calls)do f.calls[k]=0 end end end
 local function count()local r={};for _,f in ipairs(all)do for k,v in pairs(f.calls)do r[k]=(r[k]or 0)+v end end;return r end
 local function fire(f,event,unit)f:GetScript('OnEvent')(f,event,unit)end
 local function event(kind)
  reset()
  if kind=='tenCleanExits'then for _=1,10 do for _,f in ipairs(all)do fire(f,'PLAYER_REGEN_ENABLED')end end
  elseif kind=='coalescedRosterBurst'then
   for _=1,20 do
    if P.QueueRosterUpdate then P.QueueRosterUpdate()
    else for _,f in ipairs(all)do fire(f,'GROUP_ROSTER_UPDATE')end end
   end
   drain()
  elseif kind=='matchingPetChange'then for _,f in ipairs(all)do fire(f,'UNIT_PET','party1')end;drain()
  elseif kind=='unrelatedPetChange'then for _,f in ipairs(all)do fire(f,'UNIT_PET','party9')end;drain()
  elseif kind=='realPetWidthChange'then P.pets[1].width=P.pets[1].width+1;fire(P.pets[1],'PLAYER_REGEN_ENABLED')
  else error(kind)end
  return count()
 end
 return event
end
for _,client in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
 local a,b=world(client,before),world(client,after)
 for _,kind in ipairs{'tenCleanExits','coalescedRosterBurst','matchingPetChange','unrelatedPetChange','realPetWidthChange'}do
  local x,y=a(kind),b(kind)
  check(x.chrome==y.chrome and x.aura==y.aura and x.placeholder==y.placeholder,'actual Party painter/callback counts unchanged')
  if kind=='realPetWidthChange'then check(x.writes==3 and y.writes==3,'real size change keeps shell repair')
  elseif kind=='tenCleanExits'then check(x.chrome==40 and x.writes==120 and y.writes==0,'actual four pet wrappers call settled outer once per exit')
  elseif kind=='coalescedRosterBurst'then check(x.chrome==8 and x.writes==24 and y.writes==0,'actual roster timer still coalesces20 events into one eight-cell batch')
  elseif kind=='matchingPetChange'then check(x.chrome==2 and x.writes==6 and y.writes==0,'native owner filter retains only matching owner and pet')
  elseif kind=='unrelatedPetChange'then check(x.chrome==0 and y.chrome==0,'unrelated owner keeps zero paints')end
  print(table.concat({'PARTY_OUTER',client,kind,'chrome='..x.chrome,'writes='..x.writes..'->'..y.writes,'reads='..(y.sizeReads+y.countReads+y.pointReads)},'|'))
 end
end
print('PASS actual Party dispatcher/queue -> Shared geometry-stage '..checks..' checks; other Shared painter bodies modeled; no native performance claim')
