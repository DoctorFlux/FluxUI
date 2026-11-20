-- Same-interval diagnostic provenance, without profiling or an idle monitor.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@idle-trace-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local j,new,piece,flush,objects,_,_,_,e=fixture()
local root=new(e.UIParent);piece(root,'Top',{0,-9,100,17});piece(root,'Left',{41,-40,16,80});flush()
local lines,timers={},{}
e.Flux.Print=function(line)lines[#lines+1]=line end
e.C_Timer={After=function(delay,fn)check(delay==10,'only the finite user capture timer');timers[#timers+1]=fn end}
local function has(pattern)for _,line in ipairs(lines)do if line:find(pattern,1,true)then return true end end end
e.SlashCmdList.FLUXBORDERS('idle')
local added=piece(root,'Right',{61,-40,16,80});flush()
j:Forget(added);flush();j:Invalidate(true);flush()
for _,o in ipairs(objects)do if o.OnEvent then o:OnEvent('PLAYER_REGEN_ENABLED')end end;flush()
for _,o in ipairs(objects)do if o.OnEvent then o:OnEvent('UI_SCALE_CHANGED')end end;flush()
timers[1]()
check(has('1x new pieces: '),'new registration has finite producer evidence')
check(has('1x removed pieces: '),'removed registration is distinct from appearance or unit opacity')
check(has('1x explicit style/settings'),'forced settings request identified')
check(not has('event: PLAYER_REGEN_ENABLED'),'a clean combat exit never manufactures a full-refresh producer')
check(has('1x event: UI_SCALE_CHANGED'),'a real lifecycle layout event is identified')
local reads=0;for _,line in ipairs(lines)do if line:find('Border interval ',1,true)==1 then reads=reads+1 end end
check(reads>0 and reads<=3,'the exact interval prints bounded current geometry reasons automatically')
check(has('fullRequests=2')and has('Border local refresh:'),'registration stays local; only settings and display changes request a full refresh')
lines={};e.SlashCmdList.FLUXBORDERS('idle');timers[2]()
check(#lines==2 and has('solves=0')and has('fullRequests=0'),'a fresh quiet capture cannot repeat stale previous geometry/request reasons')
check(#timers==2,'capture does not schedule a persistent diagnostic driver')
print('Border idle trace: '..checks..' checks PASS; finite same-interval producer/read evidence; registration/removal/settings/event causes; bounded records; no stale quiet-capture reasons or persistent timer')
