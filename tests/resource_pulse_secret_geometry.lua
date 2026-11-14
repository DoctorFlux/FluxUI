-- Native Forever taint-log regression: caught arithmetic still emits taint work.
-- Execute the actual pulse updater with throwing opaque geometry; no native pass.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local path=os.getenv("FLUX_PULSE_SOURCE")or"UnitFrames/FluxUnitFrames_Shared.lua"
local s=read(path)
local a=assert(s:find("local function ValueIsSecret(value)",1,true))
local b=assert(s:find("-- The addon owns these dimensions.",a,true))
local c=assert(s:find("function UF.UpdateFullResourcePulse(",b,true))
local d=assert(s:find("-- Shorten the displayed fill",c,true))
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
 local unsafe=0
 local function denied()unsafe=unsafe+1;error("native secret-value arithmetic/comparison")end
 local secret=setmetatable({},{__add=denied,__sub=denied,__lt=denied,__le=denied})
 local inaccessible=setmetatable({},{__add=denied,__sub=denied,__lt=denied,__le=denied})
 local e=setmetatable({UF={},API={IsSecretValue=function(v)return rawequal(v,secret)end,
  CanAccessValue=function(v)return not rawequal(v,inaccessible)end,
  SafeGetNumber=function(v,default)return type(v)=="number"and v or default end}},{__index=_G})
 assert(load(s:sub(a,b-1)..s:sub(c,d-1),"@production-resource-pulse","t",e))()
 local width,barWidth,shown=100,100
 local calls=0
 local pulse={active=true,StartAnimIfFull=function(_,full)calls=calls+1;shown=full end}
 local bar={FullPowerFrame=pulse,GetWidth=function()return barWidth end,
  GetStatusBarTexture=function()return {GetWidth=function()return width end}end}
 for _,case in ipairs({{100,100,true},{30,100,false},{0,100,false},{99,100,false}})do
  e.UF.UpdateFullResourcePulse(bar,case[1],case[2]);check(shown==case[3],"readable power retains full/spend result")
 end
 width=100;e.UF.UpdateFullResourcePulse(bar,secret,secret);check(shown==true,"public full geometry retains pulse when values are opaque")
 width=30;e.UF.UpdateFullResourcePulse(bar,secret,secret);check(shown==false,"public partial geometry remains quiet")
 for _,value in ipairs({secret,inaccessible,0/0,math.huge,-math.huge,"100",false})do
  width=value;barWidth=100
  for i=1,100 do e.UF.UpdateFullResourcePulse(bar,secret,secret)end
  check(shown==false,"unreadable/nonfinite fill omits unverifiable pulse")
  check(unsafe==0,"secret fill is never used in arithmetic, even inside pcall")
  width=100;barWidth=value
  for i=1,100 do e.UF.UpdateFullResourcePulse(bar,secret,secret)end
  check(shown==false,"unreadable/nonfinite bar width omits unverifiable pulse")
  check(unsafe==0,"secret bar width is never used in arithmetic/comparison")
 end
 width,barWidth=100,100;e.UF.UpdateFullResourcePulse(bar,secret,secret);check(shown==true,"readable geometry resumes pulse after restriction")
 pulse.active=false;local before=calls;e.UF.UpdateFullResourcePulse(bar,secret,secret);check(calls==before,"disabled pulse does no work")
 bar.FullPowerFrame=nil;e.UF.UpdateFullResourcePulse(bar,secret,secret);check(calls==before,"missing pulse does no work")
end
print("Resource pulse secret geometry: "..checks.." checks PASS; native taint acceptance pending")
