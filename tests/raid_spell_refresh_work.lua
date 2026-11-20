-- Execute actual spell event, existing dirty-part queue and raid paint driver.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function part(s,a,b)local x=assert(s:find(a,1,true));return s:sub(x,assert(s:find(b,x+#a,true))-1)end
local frames=read(arg[1]or'RaidFrame/FluxRaidFrame.lua');local unit=read('RaidFrame/FluxRaidUnit.lua')
local queue=part(unit,'local pendingPaint, paintDriver, paintArmed','local function OnUnitEvent')
local visible=part(unit,'function FluxRaid_RefreshVisibleUnits(which)','function FluxRaid_RefreshSelfDisplayNames')
local event=part(frames,'function EventHandlers:SPELLS_CHANGED()','function EventHandlers:HIDDEN_GROUP_BUFFS_CHANGED()')
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
for _,combat in ipairs{false,true}do
 local count={configure=0,queued=0,armed=0,aura=0,dispel=0,big=0,full=0};local cells={};local driver
 local e=setmetatable({ns={},State={isInitialized=true},EventHandlers={},enabled=true},{__index=_G})
 e.CreateFrame=function()driver={SetScript=function(self,k,f)self[k]=f;if f then count.armed=count.armed+1 end end};return driver end
 e.InCombatLockdown=function()return combat end;e.FluxRaid_IsFluxRaidEnabled=function()return e.enabled end
 e.FluxRaid_ApplyOptionsFromDB=function()count.configure=count.configure+1 end
 e.FluxRaid_QueueWork=function()count.queued=count.queued+1 end
 e.FluxRaid_ForEachHeaderChild=function(fn)for _,f in ipairs(cells)do fn(f)end end
 e.FluxRaid_PaintUnit=function()count.full=count.full+1 end
 e.FluxRaid_UpdateAuras=function(f)count.aura=count.aura+1;f.auraPaint=(f.auraPaint or 0)+1 end
 e.FluxRaid_UpdateDispelHighlight=function()count.dispel=count.dispel+1 end
 e.FluxRaidFrame_BigDebuffs_TryUpdate=function()count.big=count.big+1 end
 assert(load(queue..visible..event,'@raid-spell-refresh-production','t',e))()
 local expected=0
 for i=1,80 do
  local shown=i<=40;local mini=i%5==0
  cells[i]={unit='raid'..i,_fluxRaidMini=mini,IsVisible=function()return shown end}
  if shown and not mini then expected=expected+1 end
 end
 for _=1,30 do e.EventHandlers:SPELLS_CHANGED()end
 check(count.configure==0 and count.queued==0,'spell bursts do not reinstall options/header layout or defer full configuration')
 check(count.armed==1,'spell bursts share the existing single paint wake')
 driver:OnUpdate()
 check(count.aura==expected and count.dispel==expected and count.big==expected,'every shown full unit refreshes aura/dispel/BigDebuffs exactly once')
 check(count.full==0,'no whole-cell paint or chrome reconstruction')
 for _,f in ipairs(cells)do check(f.auraPaint==(f:IsVisible()and not f._fluxRaidMini and 1 or nil),'hidden/minis keep existing paint behavior')end
 e.enabled=false;e.EventHandlers:SPELLS_CHANGED();check(not driver.OnUpdate,'disabled module schedules no work')
 e.enabled=true;e.State.isInitialized=false;e.EventHandlers:SPELLS_CHANGED();check(not driver.OnUpdate,'uninitialized module schedules no work')
end
print('Raid spell refresh: '..checks..' checks PASS;30-event bursts/80prepared units/OOC+combat;one existing queue wake;32shown full units retain aura/dispel/BigDebuffs paint;zero header/options rebuilds. Native pending.')
