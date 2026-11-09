-- Execute actual geometry and text styling; native rendering remains pending.
local root=(arg[0]:match("^(.*)[/\\]")or".").."/../"
local f=assert(io.open(os.getenv("FLUX_RAID_VISUALS_SOURCE")or root.."RaidFrame/FluxRaidVisuals.lua","rb"))
local source=f:read("*a");f:close()
local checks=0
local function check(value,label)checks=checks+1;assert(value,label)end
local function near(a,b)return math.abs(a-b)<1e-9 end
local function fixture(code,db)
 local e=setmetatable({},{__index=_G});e._G=e
 e.FluxOptions={GetRaidFrameDB=function()return db or{}end}
 e.issecretvalue=function(v)return type(v)=="table"and v.opaque==true end
 e.GameFontNormalSmall={GetFont=function()return"NativeDuration",10,""end}
 e.CreateFrame=function()error("pure geometry allocated a widget")end
 assert(load(code,"@actual-raid-geometry","t",e))("_FluxUI",{})
 return e.FluxRaidVisuals,e
end
local v=fixture(source)
local layout=assert(v.GetAuraLayout,"shared geometry missing")
local function fits(d)return d.buffs.blockWidth+d.debuffs.blockWidth+d.centerGutter<=d.availableWidth+1e-9
 and math.max(d.buffs.blockHeight,d.debuffs.blockHeight)<=d.availableHeight+1e-9 end
local function stock(visual)
 local d=visual.GetAuraLayout(nil,nil,{})
 assert(d.base.width==11 and d.base.height==11 and d.base.largeIconSize==16.5,"canonical stock dimensions changed")
 assert(d.scale==1 and d.width==11 and d.height==11 and d.gap==0,"1.00 retains stock glyphs with zero spacing")
 assert(d.buffs.blockWidth==33 and d.buffs.blockHeight==22 and d.debuffs.blockWidth==33 and d.debuffs.blockHeight==22 and fits(d),"zero-gap blocks do not fit")
end
check(v.FRAME_WIDTH==98 and v.FRAME_HEIGHT==44 and v.POWER_BAR_HEIGHT==8,"stock Modern defaults are the startup baseline")
for _,scale in ipairs({.5,1,1.2,1.4,2})do
 local options={frameHeightScale=scale,memberWidthScale=scale,powerBarHeightScale=scale}
 v.ApplyRaidFrameTunables(options)
 check(v.FRAME_WIDTH==math.floor(98*scale+.5)and v.FRAME_HEIGHT==math.floor(44*scale+.5)
  and v.POWER_BAR_HEIGHT==math.floor(8*scale+.5)and options.frameHeightScale==scale,"all scales multiply stock dimensions without hidden modifiers or writes")
end
v.ApplyRaidFrameTunables({})
stock(v);check(true,"1.00 preserves actual normal and large native slots")
local half=layout(nil,nil,{auraIconScale=.5})
for _,x in ipairs({.5,1,1.5,2.5})do
 local wide=layout(nil,nil,{auraWidthScale=x})
 check(wide.width==11*x and wide.height==11 and wide.debuffs.slotWidth==11*x,
  "X scale changes normal and large widths independently of height")
 check(v.GetAuraDurationFontScale({auraDurationFontScale=x})==x,"font scale is independent of icon geometry")
end
check(half.width==5.5 and half.height==5.5 and half.largeIconSize==8.25,"half-size squares preserve the native large-icon ratio")
local capped=layout(nil,nil,{auraIconScale=2.5})
check(not capped.capped and capped.scale==2.5 and capped.overlap,"six-plus-six enlarges past the old hidden fit cap")
local few=layout(nil,nil,{auraIconScale=2.5,maxBuffs=1,maxDebuffs=1})
check(few.scale==2.5 and few.height==27.5,"fewer icons retain the same requested size")
local bigger=layout(nil,nil,{memberWidthScale=1.4,frameHeightScale=1.5,auraIconScale=2.5})
check(bigger.scale==2.5 and bigger.width==bigger.height,"frame geometry never changes requested icon size")
check(v.GetAuraScaleLimit(nil,nil,{})==2.5 and v.GetAuraScaleLimit(nil,nil,{maxBuffs=1,maxDebuffs=1})==2.5,"slider permits growth independently of counts")
local clamped=layout(nil,nil,{maxBuffs=0,maxDebuffs=99})
check(clamped.buffs.count==1 and clamped.debuffs.count==6,"limits clamp independently")
check(layout(nil,nil,{maxBuffs=4.9,maxDebuffs=2.2}).buffs.count==4,"fractional counts normalize consistently")
for _,startup in ipairs({.5,1,1.4,2.5})do
 local visual=fixture(source);visual.ApplyRaidFrameTunables({auraIconScale=startup})
 check(visual.AURA_ICON_WIDTH==11*startup and visual.AURA_ICON_HEIGHT==11*startup,"requested globals remain stock-relative squares")
 for _,requested in ipairs({.5,1,1.4,2.5,1})do
  local a=visual.GetAuraLayout(96,34,{auraIconScale=requested,maxBuffs=2,maxDebuffs=4})
  local b=layout(96,34,{auraIconScale=requested,maxBuffs=2,maxDebuffs=4})
  check(near(a.scale,b.scale)and near(a.width,b.width),"startup history cannot change explicit geometry")
 end
 stock(visual)
end
for buffs=1,6 do for debuffs=1,6 do
 for _,bounds in ipairs({{96,34},{65,31},{101,53},{29,17}})do
  local previous=0
  for _,requested in ipairs({.5,1,1.4,1.8,2.5})do
   local d=layout(bounds[1],bounds[2],{auraIconScale=requested,maxBuffs=buffs,maxDebuffs=debuffs})
   check(d.scale>0 and d.scale<=requested and (fits(d)or d.overlap),"geometry either fits or explicitly reports the stock-baseline overlap constraint")
   check(d.width==d.height and near(d.largeIconSize/d.normalIconSize,1.5)and d.scale>=previous,"squares grow uniformly until capped")
   check(d.buffs.count==buffs and d.debuffs.count==debuffs and d.buffs.columns==math.ceil(buffs/2)
    and d.debuffs.rows==math.min(2,debuffs),"fitting preserves counts and three-by-two layout")
   check(near(d.buffs.slotWidth/d.scale,11)and near(d.debuffs.slotWidth/d.scale,11)
    and d.base.width==11 and d.base.largeIconSize==16.5,"native constructor dimensions stay immutable")
   previous=d.scale
  end
 end
end end
local db={auraIconScale=1,maxBuffs=1,maxDebuffs=2}
local scoped=fixture(source,db)
check(scoped.GetAuraLayout().buffs.count==1 and scoped.GetAuraLayout().debuffs.count==2,"omitted options use scoped settings")
db.maxBuffs=5
check(scoped.GetAuraLayout().buffs.count==5,"count changes do not reuse stale geometry")
v.ApplyRaidFrameTunables({memberWidthScale=.6,frameHeightScale=.8})
local pending={memberWidthScale=1.4,frameHeightScale=1.5,powerBarHeightScale=1.5}
local future=layout(nil,nil,pending)
check(future.availableWidth==135 and future.availableHeight==52,"pending bounds use stock-relative frame and power dimensions")
check(near(v.GetAuraScaleLimit(nil,nil,pending),v.GetAuraScaleLimit(135,52,pending)),"slider bounds share pending geometry")
check(layout(nil,nil,{displayPowerBar=false}).availableHeight>layout(nil,nil,{}).availableHeight,"power hiding releases health height without changing the slider")
v.ApplyRaidFrameTunables({})
local opaque=setmetatable({opaque=true},{__tostring=function()error("opaque value formatted")end})
check(fits(layout(opaque,opaque,{auraIconScale=opaque,maxBuffs=opaque,maxDebuffs=opaque})),"secret guards precede numeric conversion")
local tiny=layout(1,1,{auraIconScale=2.5})
check(tiny.width==27.5 and tiny.height==27.5 and tiny.overlap and tiny.physicalFitScale<1,"tiny frames retain selected size and report overlap")
check(fits(layout(math.huge,0/0,{auraIconScale=math.huge,maxBuffs=0/0})),"nonfinite settings cannot reach widget dimensions")
do
 local visual,e=fixture(source)
 local m={}
 function m:SetFont(_,size)self.fontSize=size end
 function m:SetTextScale(value)self.textScale=value end
 function m:SetText(value)self.text=value end
 function m:SetWidth(value)self.width=value end
 function m:SetWordWrap()end
 function m:SetTextColor()end
 function m:SetShadowColor()end
 function m:SetShadowOffset()end
 function m:SetParent(parent)self.parent=parent end
 function m:ClearAllPoints()end
 function m:SetPoint()end
 function m:Hide()end
 function m:Show()end
 function m:CreateFontString()return setmetatable({},{__index=m})end
 function m:GetUnboundedStringWidth()return (#self.text==2 and 15.2 or 20)*(self.fontSize/7)*self.textScale end
 function m:GetStringHeight()return self.fontSize*self.textScale end
 e.CreateFrame=function()return setmetatable({},{__index=m})end
 e.GetTime=function()return 100 end
 local function read(path)local file=assert(io.open(root..path,"rb"));local s=file:read("*a"):gsub("\r\n","\n");file:close();return s end
 local function contract(text,name)
  local fn=assert(load(text.."\nreturn "..name,"@actual-text-style","t",e))()
  local label=setmetatable({},{__index=m})
  local button={GetWidth=function()return 11 end,GetHeight=function()return 11 end,textLayer={},count=setmetatable({},{__index=m})}
  button.clock={SetCooldown=function()end,SetHideCountdownNumbers=function()end,Show=function()end,GetCountdownFontString=function()return label end}
  if name=="StyleDurationText"then fn(label,button,11)else fn(button,1,1)end
  assert(label.width==13,"centering width changed")
  assert(label.fontSize==10 and 20*(10/7)*label.textScale<=11,"native labels exceed the actual clip")
 end
 local live=assert(read("RaidFrame/FluxRaidAuras.lua"):match("local function StyleDurationText%b().-\nend"))
 local preview=assert(read("RaidFrame/FluxRaidPreview.lua"):match("local function DemoAuraDuration%b().-\nend"))
 contract(live,"StyleDurationText");check(true,"live native duration font fits the stock icon")
 contract(preview,"DemoAuraDuration");check(true,"preview duration uses the same real clipping budget")
end
local mutants={
 {"stock constructor",'local AURA_ICON_BASE_HEIGHT = 11','local AURA_ICON_BASE_HEIGHT = 19.5',stock},
 {"hidden cap",'local scale = requested','local scale = min(requested, fitScale)',function(visual)assert(visual.GetAuraLayout(96,34,{auraIconScale=2.5}).scale==2.5)end},
 {"independent limits",'side%(options.maxDebuffs,','side(options.maxBuffs,',function(visual)local d=visual.GetAuraLayout(nil,nil,{maxBuffs=1,maxDebuffs=6});assert(d.debuffs.count==6)end},
 {"stock-relative slider",'return 2.5','return 1',function(visual)assert(visual.GetAuraScaleLimit(nil,nil,{maxBuffs=1,maxDebuffs=1})==2.5)end},
}
for _,mutant in ipairs(mutants)do
 local changed,n=source:gsub(mutant[2],mutant[3]);check(n>0,"negative control targets "..mutant[1])
 check(not pcall(function()mutant[4](fixture(changed))end),"negative control rejects "..mutant[1])
end
print("Raid aura layout: "..checks.." checks; stock-relative squares, independent aura resizing and actual text crop; four rejected mutants; native rendering pending")

