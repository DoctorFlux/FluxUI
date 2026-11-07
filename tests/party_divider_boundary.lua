-- Resolve the production divider against the actual shared bar partition code.
-- HUD health fills extend below the resource seam; desktop geometry only.
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local fixture=read("tests/unit_power_visibility.lua")
local stop=assert(fixture:find('UF.UpdatePower(frame, "focus")',1,true))
local prefix=fixture:sub(1,stop-1)
local UF,env,region,mode,base=assert(load(prefix.."\nreturn UF,env,region,function(hud)modern=hud;combat=false end,frame","@partition-fixture","t",_G))()
local party=read(os.getenv("FLUX_PARTY_DIVIDER_SOURCE")or"UnitFrames/FluxUnitFrames_Party.lua")
local first=assert(party:find('    local divider = UF.CreateBarSeparator(layer)',1,true)
    or party:find('    local divider = layer:CreateTexture(nil, "OVERLAY")',1,true))
local last=assert(party:find('    frame._fluxPartyDivider = divider',first,true))+#'    frame._fluxPartyDivider = divider'
local body=party:sub(first,last)
local shared=read("UnitFrames/FluxUnitFrames_Shared.lua")
local sepFirst=assert(shared:find("local function CreateSeparator(parent)",1,true))
local sepLast=assert(shared:find("local AnimatedHealthLossMixin",sepFirst,true))
assert(load(shared:sub(sepFirst,sepLast-1),"@shared-target-divider","t",env))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,atlas in ipairs({true,false})do
env.FluxBorder={CanUseAtlases=function()return atlas end}
for _,hud in ipairs({true,false})do for _,height in ipairs({35,85,150})do for _,powerScale in ipairs({.5,.8,1.5})do
    mode(hud)
    local function widget()
        local w=region();w.points={}
        w.ClearAllPoints=function(s)s.points={}end
        w.SetPoint=function(s,...)s.points[#s.points+1]={...}end
        w.SetColorTexture=function(s,...)s.color={...}end
        w.SetVertexColor=function(s,...)s.color={...}end
        w.SetAtlas=function(s,a)s.atlas=a end
        w.SetTexture=function(s,t)s.texture=t end
        w.SetTexCoord=function(s,...)s.uv={...}end
        return w
    end
    local frame={unit="party1",_fluxPartyMember=true,_fluxPartyPowerHeightScale=powerScale,_fluxHasMainPower=true,
        Health=widget(),Power=widget(),HealthPowerSeparator=widget(),PowerAdditionalSeparator=widget()}
    for k,v in pairs(base)do if type(v)=="function"then frame[k]=v end end
    frame.GetHeight=function()return height end
    UF.UpdateFramePartition(frame)
    local hp,power=frame.Health.height,frame.Power.height
    local E=setmetatable({frame=frame,layer={CreateTexture=widget}},{__index=env})
    assert(load(body,"@production-party-divider","t",E))()
    local divider=frame._fluxPartyDivider
    local point=divider.points[1]
    local relative=point[2]
    local y=relative.points[1][5]+point[5]
    if point[3]:find("BOTTOM",1,true)then y=y-relative.height end
    local expected=frame.HealthPowerSeparator.points[1][5]
    check(math.abs(y-expected)<.000001,"party divider must meet the real shared HP/resource seam, including extended HUD fill")
    check(frame.Health.height==hp and frame.Power.height==power,"divider never changes bar dimensions")
    local target=UF.CreateBarSeparator(E.layer)
    check(divider.height==target.height and divider.color[4]==1 and divider.atlas==target.atlas and divider.texture==target.texture
        and table.concat(divider.uv or{},",")==table.concat(target.uv or{},","),"party uses target separator artwork, crop and height")
    UF.UpdateFramePartition(frame)
    check(not frame.HealthPowerSeparator.shown,"one textured divider replaces the underlying shared separator without doubling")
end end end end
print("Party divider boundary: "..checks.." checks; actual shared HUD/legacy partitions; native pixels/combat pending")
