local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local base=arg[1]
local function source(name,path)return read(base and (base..'/'..name) or path)end
local aura=source('FluxUnitFrames_Auras.lua','UnitFrames/FluxUnitFrames_Auras.lua')
local engine=source('FluxUnitFrames_AurasEngine.lua','UnitFrames/FluxUnitFrames_AurasEngine.lua')
local bridge=source('FluxUnitFrames_OptionsBridge.lua','UnitFrames/FluxUnitFrames_OptionsBridge.lua')
local options=source('FluxOptionsUnitFrames.lua','AddonOptions/FluxOptionsUnitFrames.lua')
local raidOptions=source('FluxOptionsRaidFrame.lua','AddonOptions/FluxOptionsRaidFrame.lua')
local function part(s,a,b)local x=assert(s:find(a,1,true));return s:sub(x,assert(s:find(b,x+#a,true))-1)end
local checks=0;local function check(v,m)assert(v,m);checks=checks+1 end
local state={combat=false,now=100}
local db={auraTarget={},auraFocus={}}
local env=setmetatable({GetDB=function()return db end,AfterAuraOptionsChange=function()state.refreshed=true end,
 InCombatLockdown=function()return state.combat end,GetTime=function()return state.now end,
 ns={API={SafeGetNumber=function(v,d)return type(v)=='number' and v or d end}}},{__index=_G})
env.general={}
env.FluxOptions={GetUnitFrameDB=function()return db end}
local general=part(options,'    general.auraTimersUnderMinute =','    general.raidSettingsScope =')
assert(load(general,'general-option','t',env))()
local target=env.general.auraTimersUnderMinute
check(not target.get(),'missing saved general key retains all timers')
target.set(nil,true);check(target.get() and state.refreshed,'the general callback saves and refreshes the shared setting')
local original=db;db={auraTarget={},auraFocus={}};check(not target.get(),'character scope independent');db=original
local toggle=assert(load(part(options,'local function AuraToggle','local function AddTextAndBars')..'\nreturn AuraToggle','option','t',env))()
check(toggle('auraTarget','showBuffs','buffs',1).get(),'existing aura toggle defaults preserved')
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
check(bridge:find('timersUnderMinute = db and db.auraTimersUnderMinute == true or false',1,true)
 and aura:find('frame.BuffContainer._fluxAuraTimersUnderMinute = buffConfig.timersUnderMinute == true',1,true)
 and aura:find('frame.DebuffContainer._fluxAuraTimersUnderMinute = debuffConfig.timersUnderMinute == true',1,true),
 'initial and refreshed target/focus panels share the same policy for helpful and harmful auras')
check(aura:find('button.Cooldown._fluxAuraContainer = parent',1,true),'legacy cooldown linked to owner')
check(engine:find('GetDurationFormatter(container)',engine:find('function UF.SyncEngineAuras',1,true),true),'existing sync updates policy')
check(not options:find('target.targetAuraTimersUnderMinute',1,true) and not options:find('focus.focusAuraTimersUnderMinute',1,true),'per-target/focus duplicate options removed')
check(not raidOptions:find('auraTimersUnderMinute',1,true),'raid no longer declares or resets a second timer setting')

-- Drive the General toggle through the actual options bridge and verify the
-- production aura owners all bind the same group formatter for their client.
local fixtureSource=read('tests/raid_healer_auras.lua')
local boundary=assert(fixtureSource:find('for _,client in ipairs({"retail","forever"})do',1,true))
local fixture=assert(load(fixtureSource:sub(1,boundary-1)..'\nreturn Fixture','actual-party-aura-fixture','t',_G))()
local apply=part(bridge,'function FluxUnitFrames_ApplyAuraLayoutFromDB','function FluxUnitFrames_ApplyOptionsFromDB')
for _,client in ipairs({'live','forever','classic','classic_era','classic_anniversary'}) do
    local native=client=='live' or client=='forever'
    local e,module,party,_,_,_,createUnit=fixture(native,nil,nil,client)
    local compact,raid=createUnit('party2'),createUnit('raid1')
    local unitDb={auraTimersUnderMinute=false}
    e.FluxOptions.GetUnitFrameDB=function()return unitDb end
    e.raidDB.auraTimersUnderMinute=true
    e.Enum.NumericRuleFormatRounding=env.Enum.NumericRuleFormatRounding
    e.C_StringUtil=env.C_StringUtil
    e.ns=e.addonNS
    local deferred
    e.ns.UnitFrames={DeferProtected=function(_,callback)deferred=callback end}
    e.general={}
    e.GetDB=function()return unitDb end
    assert(load(apply,'actual-aura-refresh','t',e))()
    e.AfterAuraOptionsChange=e.FluxUnitFrames_ApplyAuraLayoutFromDB
    assert(load(general,'actual-general-control','t',e))()
    local control=e.general.auraTimersUnderMinute

    party._fluxPartyMember=true
    for _,frame in ipairs({party,compact,raid}) do check(module.Setup(frame),client..' group owner prepares') end
    local function bound(frame)
        if native then return frame._fluxNativeAuraButtons[1].durationOptions.textFormatter end
        return frame._fluxAuraCorners.buffs[1].Cooldown.countdownFormatter
    end
    local shared=bound(party)
    check(shared and bound(compact)==shared and bound(raid)==shared,client..' all group owners bind the same formatter')
    check(not control.get() and shared:Format(60)=='1m',client..' former raid value does not override General')
    e.restricted=true
    control.set(nil,true)
    check(control.get() and shared:Format(59)=='59' and shared:Format(60)==''
        and shared:Format(61)=='' and shared:Format(3600)=='',client..' one toggle hides every long group countdown')
    check(bound(party)==shared and bound(compact)==shared and bound(raid)==shared,client..' existing timer bindings stay attached')
    e.combat=true;control.set(nil,false)
    check(deferred and shared:Format(90)=='',client..' combat defers the shared formatter update')
    e.combat=false;deferred()
    check(shared:Format(90)=='1m',client..' deferred update restores longer timers')
end
print('PASS '..checks..' unit aura minute-policy checks; native rendering pending')
