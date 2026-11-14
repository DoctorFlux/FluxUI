-- Resolve the production divider against the actual shared bar partition code.
-- Party health fills stop above the resource seam; desktop geometry only.
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local fixture=read("tests/unit_power_visibility.lua")
local stop=assert(fixture:find('UF.UpdatePower(frame, "focus")',1,true))
local prefix=fixture:sub(1,stop-1)
local sharedPath=os.getenv("FLUX_PARTY_HEALTH_SOURCE")or"UnitFrames/FluxUnitFrames_Shared.lua"
prefix=prefix:gsub('local shared = [^\n]+',function()return 'local shared = read('..string.format("%q",sharedPath)..')'end,1)
local UF,env,region,mode,base=assert(load(prefix.."\nreturn UF,env,region,function(hud)modern=hud;combat=false end,frame","@partition-fixture","t",_G))()
local party=read(os.getenv("FLUX_PARTY_DIVIDER_SOURCE")or"UnitFrames/FluxUnitFrames_Party.lua")
local first=assert(party:find('    local divider = UF.CreateBarSeparator(layer)',1,true)
    or party:find('    local divider = layer:CreateTexture(nil, "OVERLAY")',1,true))
local last=assert(party:find('    frame._fluxPartyDivider = divider',first,true))+#'    frame._fluxPartyDivider = divider'
local body=party:sub(first,last)
local shared=read(sharedPath)
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
    frame.Health._fluxTextAnchor=widget()
    UF.UpdateFramePartition(frame)
    local hp,power=frame.Health.height,frame.Power.height
    local healthBottom=frame.Health.points[1][5]-hp
    local powerTop=frame.Power.points[1][5]
    check(math.abs(healthBottom-powerTop-2)<.000001,"party health fill ends above resource with the existing two-unit gap")
    UF.SyncPublicHealthGeometry(frame)
    check(math.abs(frame.Health._fluxPublicHeight-hp)<.000001,"planned health prediction geometry matches the fitted party fill")
    local E=setmetatable({frame=frame,layer={CreateTexture=widget}},{__index=env})
    assert(load(body,"@production-party-divider","t",E))()
    local divider=frame._fluxPartyDivider
    local point=divider.points[1]
    local relative=point[2]
    local y=relative.points[1][5]+point[5]
    if point[3]:find("BOTTOM",1,true)then y=y-relative.height end
    local expected=frame.HealthPowerSeparator.points[1][5]
    check(math.abs(y-expected)<.000001,"party divider must meet the real shared HP/resource seam")
    check(frame.Health.height==hp and frame.Power.height==power,"divider never changes bar dimensions")
    local target=UF.CreateBarSeparator(E.layer)
    check(divider.height==target.height and divider.color[4]==1 and divider.atlas==target.atlas and divider.texture==target.texture
        and table.concat(divider.uv or{},",")==table.concat(target.uv or{},","),"party uses target separator artwork, crop and height")
    UF.UpdateFramePartition(frame)
    check(not frame.HealthPowerSeparator.shown,"one textured divider replaces the underlying shared separator without doubling")
    frame._fluxHasMainPower=nil
    UF.UpdateFramePartition(frame)
    check(frame.Power.shown and frame.Health.height==hp,"unknown or restricted capacity keeps the prepared party split")
    frame._fluxHasMainPower=false
    UF.UpdateFramePartition(frame)
    check(not frame.Power.shown and frame.Health.height==math.max(height-8,10),"known no-resource party uses full-height health")
    frame._fluxHasMainPower=true
    UF.UpdateFramePartition(frame)
    check(frame.Power.shown and frame.Health.height==hp and frame.Health._fluxTextAnchor.height==hp,"resource return restores fill and text split")
    for _,focus in ipairs({false,true})do
        frame._fluxPartyMember=nil;frame._fluxCompactFocus=focus;frame.unit=focus and "focus"or"target"
        UF.UpdateFramePartition(frame)
        local expectedHeight=hud and math.max(height-8,10)or(focus and hp or(math.max(height-8,10)*.6-1))
        check(math.abs(frame.Health.height-expectedHeight)<.000001,"main target and compact focus keep their existing layout")
    end
end end end end
print("Party divider boundary: "..checks.." checks; fitted party HP, prediction geometry, resource transitions and unchanged target/focus; native pixels/combat pending")
