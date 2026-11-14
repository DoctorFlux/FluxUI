-- Reuse the existing full real-geometry/native-policy fixture; load actual painters.
local function read(p) local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local fixture=read('tests/raid_healer_auras.lua')
local stop=assert(fixture:find('for _,client in ipairs({"retail","forever"})do',1,true))
local Fixture=assert(load(fixture:sub(1,stop-1)..'\nreturn Fixture','@existing-raid-aura-fixture'))()
local current=read(arg[1] or 'RaidFrame/FluxRaidAuras.lua')
local before
if arg[2] then before=read(arg[2]) else
 local a=assert(current:find('function A.Update(frame)',1,true));local b=assert(current:find('function A.UpdateDispel(frame)',a,true))
 before=current:sub(1,a-1)..read('tests/fixtures/passive_raid_auras_before.txt')..current:sub(b)
end
local checks=0
local function check(v,m) checks=checks+1;assert(v,m) end
local function aura(id,helpful,raid)
 return {name='aura'..id,spellId=id,auraInstanceID=id,icon=id+1000,duration=30,expirationTime=100,applications=2,
  sourceUnit='player',canApplyAura=true,isPriorityAura=false,isRaid=raid,isBossAura=false,isHelpful=helpful,isHarmful=not helpful,
  isTankRoleAura=false,isHealerRoleAura=false,isDPSRoleAura=false,isNameplateOnly=false,canActivePlayerDispel=true,dispelName=not helpful and 'Magic' or nil}
end
local function run(body,client,showBuff,showDebuff,strict,combat)
 local e,module,frame,_,_,data=Fixture(false,nil,body,client)
 data.HELPFUL={aura(1243,true,false),aura(10,true,false)};data.HARMFUL={aura(301,false,true)};data['HARMFUL|RAID']={aura(301,false,true)}
 frame.optionTable.displayBuffs=showBuff;frame.optionTable.displayDebuffs=showDebuff;frame.optionTable.displayOnlyDispellableDebuffs=strict
 e.combat=false;module.Setup(frame);e.combat=combat
 local count=0;local get=e.C_UnitAuras.GetAuraDataByIndex
 e.C_UnitAuras.GetAuraDataByIndex=function(...) count=count+1;return get(...) end
 module.Update(frame)
 local trace={}
 for _,key in ipairs({'buffs','debuffs'}) do
  trace[#trace+1]=tostring(frame._fluxAuraRows[key=='buffs' and 'top' or 'bottom'].shown)
  for _,icon in ipairs(frame._fluxAuraCorners[key]) do
   trace[#trace+1]=table.concat({tostring(icon.shown),tostring(icon.shown and icon.Icon.texture),tostring(icon.shown and icon.Count.text),tostring(icon.shown and icon.Cooldown.duration)},':')
  end
 end
 trace[#trace+1]=tostring(frame._fluxDispelType)
 return table.concat(trace,'|'),count
end
local samples={}
for _,client in ipairs({'classic','classic_era','classic_anniversary'}) do
 for _,buff in ipairs({false,true}) do for _,debuff in ipairs({false,true}) do for _,strict in ipairs({false,true}) do for _,combat in ipairs({false,true}) do
  local bt,bc=run(before,client,buff,debuff,strict,combat);local at,ac=run(current,client,buff,debuff,strict,combat)
  check(bt==at,'exact icon/filter/sort/count/duration/dispel trace parity')
  check(ac<=bc,'snapshot queries never increase')
  if not buff and not debuff then check(ac==0,'disabled displays perform no readable scan') end
  samples[#samples+1]=client..' buffs='..tostring(buff)..' debuffs='..tostring(debuff)..' strict='..tostring(strict)..' combat='..tostring(combat)..' before='..bc..' after='..ac
 end end end end
end
if arg[3] then local f=assert(io.open(arg[3],'wb'));f:write(table.concat(samples,'\n'),'\n');f:close() end
print('PASS raid fallback snapshots: '..checks..' actual-painter checks; native owners untouched')
