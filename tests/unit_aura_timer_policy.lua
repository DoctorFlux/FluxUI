local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local base=arg[1]
local function source(name,path)return read(base and (base..'/'..name) or path)end
local aura=source('FluxUnitFrames_Auras.lua','UnitFrames/FluxUnitFrames_Auras.lua')
local engine=source('FluxUnitFrames_AurasEngine.lua','UnitFrames/FluxUnitFrames_AurasEngine.lua')
local bridge=source('FluxUnitFrames_OptionsBridge.lua','UnitFrames/FluxUnitFrames_OptionsBridge.lua')
local options=source('FluxOptionsUnitFrames.lua','AddonOptions/FluxOptionsUnitFrames.lua')
local function part(s,a,b)local x=assert(s:find(a,1,true));return s:sub(x,assert(s:find(b,x+#a,true))-1)end
local checks=0;local function check(v,m)assert(v,m);checks=checks+1 end
local state={combat=false,now=100}
local db={auraTarget={},auraFocus={}}
local env=setmetatable({GetDB=function()return db end,AfterAuraOptionsChange=function()state.refreshed=true end,
 InCombatLockdown=function()return state.combat end,GetTime=function()return state.now end,
 ns={API={SafeGetNumber=function(v,d)return type(v)=='number' and v or d end}}},{__index=_G})
env.general={}
env.FluxPartyFrames={ApplyOptions=function()state.partyRefreshed=true end}
local general=part(options,'    general.auraTimersUnderMinute =','    general.raidSettingsScope =')
assert(load(general,'general-option','t',env))()
local target=env.general.auraTimersUnderMinute
check(not target.get(),'missing saved general key retains all timers')
target.set(nil,true);check(target.get() and state.refreshed and state.partyRefreshed,'general option refreshes target/focus and normal party')
local original=db;db={auraTarget={},auraFocus={}};check(not target.get(),'character scope independent');db=original
local toggle=assert(load(part(options,'local function AuraToggle','local function AddTextAndBars')..'\nreturn AuraToggle','option','t',env))()
check(toggle('auraTarget','showBuffs','buffs',1).get(),'existing aura toggle defaults preserved')
local getConfig=part(bridge,'function FluxUnitFrames_GetAuraConfigTables','function FluxUnitFrames_ApplyAuraLayoutFromDB')
env.DEFAULT_AURA_TARGET={buffSize=35,debuffSize=35,buffSpacing=2,debuffSpacing=2,maxBuffs=32,maxDebuffs=16,minAuraPx=10,lockOwnDebuffSize=true,ownDebuffMinScale=.75}
env.DEFAULT_AURA_FOCUS=env.DEFAULT_AURA_TARGET
env.FluxOptions={GetUnitFrameDB=function()return db end};env.FluxUnitFrames_GetPlayerTargetPlacement2RelativeUIScale=function()return 1 end
assert(load(getConfig,'configuration','t',env))()
local b,d=env.FluxUnitFrames_GetAuraConfigTables('target');check(b.timersUnderMinute and d.timersUnderMinute,'both buff and debuff configs carry option')
b,d=env.FluxUnitFrames_GetAuraConfigTables('focus');check(b.timersUnderMinute and d.timersUnderMinute,'focus shares general policy')
local legacy=assert(load(part(aura,'local function UpdateCooldownDurationText','-- Function to apply duration text styling')..'\nreturn UpdateCooldownDurationText','legacy','t',env))()
local text={shown=true,SetText=function(s,v)s.text=v end,Show=function(s)s.shown=true end,Hide=function(s)s.shown=false end}
local c={_fluxAuraTimersUnderMinute=true}
local cd={durationText=text,_fluxAuraContainer=c,IsShown=function()return true end,GetCooldownTimes=function()return 1000,1000000 end}
for _,remaining in ipairs({86400,3600,90,61,60})do
 cd.GetCooldownTimes=function()return 1000,(state.now+remaining-1)*1000 end
 legacy(cd);check(not text.shown,'legacy hides long timer '..remaining)
end
cd.GetCooldownTimes=function()return 1000,(state.now+59-1)*1000 end
legacy(cd);check(text.shown and text.text=='59','legacy returns below threshold using milliseconds')
c._fluxAuraTimersUnderMinute=false
cd.GetCooldownTimes=function()return 1000,(state.now+90-1)*1000 end
legacy(cd);check(text.shown and text.text=='2m','toggle off preserves legacy formatting')
cd.GetCooldownTimes=function()return 1000,500 end;legacy(cd);check(not text.shown,'expired timer hidden')
local creations=0
env.Enum={NumericRuleFormatRounding={Up=1,Down=2}}
env.C_StringUtil={CreateNumericRuleFormatter=function()
 creations=creations+1
 return {SetBreakpoints=function(s,r)s.rules=r end,Format=function(s,t)
  local rule=s.rules[1];for _,r in ipairs(s.rules)do if t>=r.threshold then rule=r end end
  if rule.format==''then return ''end
  local v=t/(rule.components and rule.components[1].div or 1)
  v=rule.rounding==1 and math.ceil(v) or math.floor(v)
  return string.format(rule.format,v)
 end}
end}
local formatter=assert(load(part(engine,'local function GetDurationFormatter','local function XSqueeze')..'\nreturn GetDurationFormatter','engine','t',env))()
local a={_fluxAuraTimersUnderMinute=true};local z={}
local f=formatter(a);local normal=formatter(z)
for _,t in ipairs({60,61,90,3600,86400})do check(f:Format(t)=='','engine blanks long duration '..t)end
check(f:Format(59)=='59' and f:Format(9.2)=='10','engine short labels unchanged')
check(normal:Format(90)=='1m','independent engine container keeps long timer')
a._fluxAuraTimersUnderMinute=false;check(formatter(a)==f and f:Format(90)=='1m','live option changes existing bound formatter')
check(creations==2,'formatter owners reused')
state.combat=true;a._fluxAuraTimersUnderMinute=true;formatter(a);check(f:Format(90)=='1m','combat defers formatter mutation')
state.combat=false;formatter(a);check(f:Format(90)=='','out of combat applies pending policy')
check(aura:find('container._fluxAuraTimersUnderMinute = extra.timersUnderMinute == true',1,true),'initial container receives policy')
check(aura:find('button.Cooldown._fluxAuraContainer = parent',1,true),'legacy cooldown linked to owner')
check(engine:find('GetDurationFormatter(container)',engine:find('function UF.SyncEngineAuras',1,true),true),'existing sync updates policy')
check(not options:find('target.targetAuraTimersUnderMinute',1,true) and not options:find('focus.focusAuraTimersUnderMinute',1,true),'per-target/focus duplicate options removed')
local raidDb={auraTimersUnderMinute=true}
env.ScopedSizingOptions=function(opt)return opt or raidDb end
env.FluxRaidVisuals={}
env.FluxOptions.GetUnitFrameDB=function()return db end
local visuals=source('FluxRaidVisuals.lua','RaidFrame/FluxRaidVisuals.lua')
assert(load(part(visuals,'local auraDurationFormatter, auraDurationUnderMinute','function FluxRaidVisuals.GetAuraDurationFontObject'),'party-raid-split','t',env))()
local get=env.FluxRaidVisuals.GetAuraDurationFormatter
local raid=get();local party=get(nil,{_fluxPartyMember=true})
check(raid~=party and raid:Format(90)=='' and party:Format(90)=='','distinct family formatter identities')
db.auraTimersUnderMinute=false
check(get(nil,{_fluxPartyMember=true})==party and party:Format(90)=='1m' and raid:Format(90)=='','normal party toggle does not alter raid/compact party')
raidDb.auraTimersUnderMinute=false;get()
check(raid:Format(90)=='1m' and party:Format(90)=='1m','raid toggle remains independent')
db.auraTimersUnderMinute=true;get(nil,{_fluxPartyMember=true})
check(party:Format(60)=='' and raid:Format(60)=='1m','normal party blanks exactly60 independently')
-- Native normal-party sinks must bind the party formatter, not just expose it.
local fixtureSource=read('tests/raid_healer_auras.lua')
local boundary=assert(fixtureSource:find('for _,client in ipairs({"retail","forever"})do',1,true))
local fixture=assert(load(fixtureSource:sub(1,boundary-1)..'\nreturn Fixture','actual-party-aura-fixture','t',_G))()
local e,module,frame=fixture(true,nil,nil,'forever')
e.Enum.NumericRuleFormatRounding=env.Enum.NumericRuleFormatRounding
e.C_StringUtil=env.C_StringUtil
e.FluxOptions.GetUnitFrameDB=function()return db end
frame._fluxPartyMember=true
db.auraTimersUnderMinute=true;e.raidDB.auraTimersUnderMinute=false
check(module.Setup(frame),'actual normal party native setup')
local bound=frame._fluxNativeAuraButtons[1].durationOptions.textFormatter
local raidFormatter=e.FluxRaidVisuals.GetAuraDurationFormatter()
check(bound and bound~=raidFormatter and bound:Format(90)=='' and raidFormatter:Format(90)=='1m','native party sinks use the shared unit-frame policy')
db.auraTimersUnderMinute=false;module.Refresh(frame)
check(frame._fluxNativeAuraButtons[1].durationOptions.textFormatter==bound and bound:Format(90)=='1m','actual party refresh updates current bound formatter')
print('PASS '..checks..' unit aura minute-policy checks; native rendering pending')
