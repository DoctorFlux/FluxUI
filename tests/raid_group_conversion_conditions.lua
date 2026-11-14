-- Reproduce the native Forever observation: raid API/tokens updated, group macro
-- flag still party. Exercise the real drivers and each client's native resolver.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local src=read("tests/raid_healer_secure.lua")
local prefix=src:sub(1,assert(src:find("local function exercise(client)",1,true))-1)
prefix=prefix:gsub('local ns = { Flux = {} }','local ns = { Flux = {} }; e.ns=ns',1)
if os.getenv("FLUX_CONVERSION_SOURCE")then
 prefix=prefix:gsub('root %.%. "RaidFrame/FluxRaidSecure.lua"',string.format("%q",os.getenv("FLUX_CONVERSION_SOURCE")),1)
end
local fixture=assert(load(prefix.."\nreturn fixture","@native-conversion-fixture","t",_G))()
local parse=assert(loadfile("tests/support/group_condition_parser.lua"))()
local checks,transitions=0,0
local function check(v,why)checks=checks+1;assert(v,why)end
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
 for _,normal in ipairs({false,true})do
  local e,secure=fixture(client)
  local S=e.FluxRaidSecure
  local methods=getmetatable(e.CreateFrame("Frame","Probe")).__index
  function methods:GetParent()return self.parent end
  local container=e.CreateFrame("Frame","Dock");container:Show()
  local headers={}
  e.ns.PartyFrames=normal and{ready=true}or nil
  for i=1,8 do headers[i]=e.CreateFrame("Frame","Group"..i,container);check(S.ConfigureHeader(headers[i],i,false),"prepare all native group controllers OOC")end
  local mt=e.CreateFrame("Frame","MT",container);check(S.ConfigureHeader(mt,nil,true),"prepare native MT visibility")
  local members,pets,targets={},{},{}
  if normal then
   for i=1,4 do
    members[i]=e.CreateFrame("Button","Party"..i,container)
    pets[i]=e.CreateFrame("Button","Pet"..i,members[i])
    targets[i]=e.CreateFrame("Button","Target"..i,members[i])
   end
   check(S.ConfigurePartyFrames(members,pets,.5,1,true,true,targets,{showTargets=true}),"prepare all party unit drivers OOC")
  end
  local present,mode,flag={},"solo","party"
  e.SecureCmdOptionParse=parse({exists=function(u)return present[u]end,petbattle=function()return e.petbattle end,group=function()return flag end})
  local capacity=e.created
  e.combat=true
  local function transition(nextMode,raidIndex,staleFlag,battle)
   mode,flag,e.petbattle=nextMode,staleFlag,battle
   present={pet=true}
   -- Party aliases remain valid in raid, as in the observed native session.
   if mode~="solo"then present.party1=true;present.partypet1=true;present.party1target=true end
   if mode=="raid"then present["raid"..raidIndex]=true;present["raidpet"..raidIndex]=true end
   secure(function()for owner,d in pairs(e.drivers)do e.resolveDriver(owner,"state-"..d.state,d.condition)end end)
   local raid=mode=="raid"and not battle
   local party=mode=="party"and not battle
   check(headers[1]:IsShown()==(raid or party and not normal),client..": bidirectional conversion selects correct first header with stale group flags")
   for i=2,8 do check(headers[i]:IsShown()==raid,"all prepared groups follow actual raid tokens")end
   check(mt:IsShown()==raid,"MT header follows actual roster mode")
   if S.GetCompanionVisibilityCondition then
    local raidPet=S.GetCompanionVisibilityCondition("raid","raidpet"..(raidIndex or 1))
    check((e.SecureCmdOptionParse(raidPet)=="show")==raid,"raid pets follow conversions without group flags")
    for _,unit in ipairs({"pet","partypet1"})do
     local condition=S.GetCompanionVisibilityCondition("party",unit)
     check((e.SecureCmdOptionParse(condition)=="show")==party,"party pets never leak into raid or solo")
    end
   end
   if normal then
    for i=1,4 do
     local visible=party and i==1
     check(members[i]:IsVisible()==visible,"party membership never leaks into raid")
     check(pets[i]:IsVisible()==visible,"party pets follow both conversion directions")
     check(targets[i]:IsVisible()==visible,"party targets follow both conversion directions")
    end
   end
   check(e.created==capacity,"conversion never allocates protected frames in combat")
   transitions=transitions+1
  end
  for index=1,40 do
   transition("party",nil,"party")
   transition("raid",index,"party")
   transition("party",nil,"raid")
   transition("solo",nil,"raid")
   transition("raid",index,"party",true)
   transition("raid",index,"party")
   transition("solo",nil,"raid")
  end
  check(type(S.GetCompanionVisibilityCondition)=="function","companion units share the universal group policy")
  for _,d in pairs(e.drivers)do
   check(#d.condition<1024,"bounded native condition string")
   check(not d.condition:find("group:",1,true),"all client drivers avoid the observed stale macro group flag")
  end
 end
end
print("Universal group conversion conditions: "..checks.." checks / "..transitions.." combat transitions PASS; native client acceptance separate")
