-- Live EBS ring/backplate owner versus a stale legacy WNormalTexture.
local checks=0
local function check(v,msg) checks=checks+1;assert(v,msg) end
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s end
local e=setmetatable({}, {__index=_G});e._G=e
local function object()
    local o={}
    function o:SetVertexColor(...)self.color={...}end
    function o:SetAlpha(v)self.alpha=v end
    function o:Show()self.shown=true end
    function o:Hide()self.shown=false end
    function o:RegisterEvent()end
    function o:SetScript()end
    return o
end
e.CreateFrame=object;e.UnitClass=function()return "Mage","MAGE"end
e.RAID_CLASS_COLORS={MAGE={r=.2,g=.5,b=.8}}
local rgb={.2,.5,.8}
e.FluxBorder={GetThemedVertexRGB=function()return table.unpack(rgb)end}
e.FluxButtonUtil={ApplyButtonStyle=function()error("must use the live EBS owner")end}
local empties=0
local flux={EBS={buttons={},badges={},Paint={UpdateEmpty=function()empties=empties+1 end}},Client={isForever=true}}
local ns={Flux=flux}
assert(load(read("ExtraButtonSystem/Engine/Style.lua"),"@EBS Style","t",e))("_FluxUI",ns)
-- Native sizing is covered by the existing chrome tests; run real resolver/tint.
local sizes=0
flux.EBS.Style.SizeRing=function()sizes=sizes+1 end
assert(load(read("ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua"),"@TrinketMenu","t",e))("_FluxUI",ns)
local tm=e.FluxTrinketMenu
local ring,plate,overlay,old,green=object(),object(),object(),object(),object()
local widget={NormalTexture=ring,BackgroundTexture=plate,_fluxQuickslotRing=overlay,Border=green}
local icon,cooldown,action={},{},"/use 13"
local button={Widget=widget,WNormalTexture=old,WIcon=icon,WCooldown=cooldown,ActionValue=action}
tm.Buttons={[0]=button};tm.MenuButtons={{NormalTexture=object()}}
for _,accent in ipairs({{.2,.5,.8},{.9,.3,.1},{1,1,1},{.502,.443,.278}})do
    rgb=accent
    e.FluxTrinketMenu_ApplyAppearanceAccent()
    for _,texture in ipairs({ring,plate,overlay,tm.MenuButtons[1].NormalTexture})do
        check(texture.color[1]==accent[1] and texture.color[3]==accent[3],"live ring/plate/fallback/menu follows accent")
    end
    check(not old.color and button.WNormalTexture==ring,"stale legacy normal reference replaced by live widget owner")
    check(not green.shown and button.WIcon==icon and button.WCooldown==cooldown and button.ActionValue==action,"equipped glow remains hidden; icon/cooldown/action ownership preserved")
    ring.color=nil;plate.color=nil
    tm.RestoreTrinketBorderColor(button)
    check(ring.color[1]==accent[1] and plate.color[1]==accent[1],"usability restore retains newest ring and plate accent")
    check(sizes==empties,"usability restoration adds no sizing/template work")
end
check(empties==4,"appearance applies the same EBS empty-slot painter as grids")
print(("Trinket appearance: %d checks PASS; live ring/backplate, four accents, usability restore; native rendering pending"):format(checks))
