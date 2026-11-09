-- Real cast start/event/update/reset with the existing five-client fixture.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local checks=0
local function check(v,m)assert(v,m);checks=checks+1 end
local src=read('tests/castbar_school_themes.lua')
src=src:sub(1,assert(src:find('local function checkParticleGeometry',1,true))-1)
src=src:gsub('pet="PetFrame"','pet="PetFrame",party1="PartyFrame"')
if os.getenv('FLUX_PARTY_CAST_SOURCE')then
 local count
 src,count=src:gsub('loadAddon%("UnitFrames/FluxCastBar.lua",%s*env,%s*ns%)',function()return 'loadAddon('..string.format('%q',os.getenv('FLUX_PARTY_CAST_SOURCE'))..', env, ns)'end)
 assert(count==1,'candidate source must replace the actual module load')
end
local make=assert(load(src..'\nreturn fixture','@party-cast-fixture','t',_G))()
for _,client in ipairs({'live','forever','classic','classic_era','classic_anniversary'})do
 for _,event in ipairs({'UNIT_SPELLCAST_STOP','UNIT_SPELLCAST_FAILED','UNIT_SPELLCAST_INTERRUPTED'})do
  for _,missing in ipairs({'event','start','both','opaque'})do
   local s,e,ns=make(client);local bar=s.NewBar('party1')
   s.casts.party1={id=19434,name='Aimed Shot'}
   bar:CastStart('party1',false,'cast-1')
   if missing=='start' or missing=='both'then bar.castGUID=nil;bar.castID=nil end
   if missing=='opaque'then bar.castGUID=s.secret end
   local id=missing=='event' or missing=='both'
   if id then s.Event(bar,event,'party1',nil,19434)else s.Event(bar,event,'party1','cast-1',19434)end
   check(not bar.casting and (bar.holdTime or bar.fadeOut),'routed terminal event clears Aimed Shot with unavailable GUID')
   ns.CastBar.ResetCastForUnit(bar)
   check(not bar:IsShown() and not bar.casting and not bar.channeling and not bar.holdTime and not bar.fadeOut,'owner hide/rebind cancels active/hold/fade state')
   check(bar.Text.text=='' and bar.Time.text=='' and not bar.IconFrame:IsShown(),'reset clears cast text/time/icon')
  end
 end
 local s,e,ns=make(client);local bar=s.NewBar('party1')
 s.casts.party1={id=19434,name='Aimed Shot'};bar:CastStart('party1',false,'new-cast')
 s.Event(bar,'UNIT_SPELLCAST_STOP','party1','older-cast',19434)
 check(bar.casting,'different readable GUID cannot stop replacement cast')
 s.Event(bar,'UNIT_SPELLCAST_STOP','party1',nil,133)
 check(bar.casting,'missing GUID with different readable spell cannot stop replacement cast')
 s.Event(bar,'UNIT_SPELLCAST_STOP','party2',nil,19434)
 check(bar.casting,'another unit cannot stop scoped cast')
 ns.CastBar.ResetCastForUnit(bar);s.casts.party1=nil
 check(not ns.CastBar.RefreshCastForUnit(bar,'party1') and not bar:IsShown(),'empty new roster slot cannot revive old spell')
 s.casts.party1={id=133,name='New member cast'}
 check(ns.CastBar.RefreshCastForUnit(bar,'party1') and bar.Text.text=='New member cast','shown/rebound slot reads actual new cast')
 ns.CastBar.ResetCastForUnit(bar);s.casts.party1={id=5143,channel=true,name='Channel'}
 ns.CastBar.RefreshCastForUnit(bar,'party1');check(bar.channeling,'refresh retains channels')
 s.Event(bar,'UNIT_SPELLCAST_CHANNEL_STOP','party1',nil,5143)
 check(not bar.channeling and bar.holdTime,'channel terminal event still completes normally')
end
print('Party cast lifecycle: '..checks..' checks; five client models; native events/taint pending')
