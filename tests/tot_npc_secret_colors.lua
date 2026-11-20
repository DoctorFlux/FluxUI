-- Real Shared name/color painters and real Border. Opaque metadata is never
-- indexed, formatted or used in arithmetic; approved native paint is recorded.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function span(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(i,assert(s:find(b,i+#a,true),b)-1)end
local shared=read(arg[1]or'UnitFrames/FluxUnitFrames_Shared.lua')
local prefix=assert(read('tests/border_types.lua'):match('^(.-)for _, forever in ipairs'))
if arg[2]then prefix=prefix:gsub('source%("FluxBorder.lua"%)','source('..string.format('%q',arg[2])..')',1)end
local model=assert(load(prefix..'\nreturn model','@tot-real-border','t',_G))()
local class=span(shared,'local function ClassColorForUnit(unit)','-- ---------------------------------------------------------------------------\n-- Health Bar')
local tint=span(shared,'local PORTRAIT_COMBAT_BORDER_R','-- Unit name on outer border:')
local names=span(shared,'local function PaintOpaqueUnitName(','local function PaintUnitFrameNameText(')
local rich=span(shared,'local function FluxTargetTotPetNameRichText()','-- Midnight (12+)')
local parentPaint=span(shared,'                    if not PaintOpaqueUnitName(self.petNameText, "targettarget", "ToT: ") then',
 '                    self.petNameText:ClearAllPoints()')
local checks,scenes=0,0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,forever in ipairs{false,true}do for _,style in ipairs{1,2}do for _,mode in ipairs{'atlas','class','custom'}do
 scenes=scenes+1
 local e,B,db,new=model(forever,'none');db.borderType=style;db.borderAccent=mode;db.customAccent={r=.8,g=.1,b=.2}
 local private={};local function secret()
  local o=setmetatable({},{__eq=function()error('secret compared')end,__lt=function()error('secret ordered')end,
   __le=function()error('secret ordered')end,__tostring=function()error('secret formatted')end,
   __mul=function()error('secret multiplied')end,__add=function()error('secret arithmetic')end,
   __concat=function()error('secret concatenated')end});private[o]=true;return o
 end
 local opaqueName,opaqueClass,opaqueKind=secret(),secret(),secret()
 local rgb={secret(),secret(),secret()};local dark={secret(),secret(),secret()};local reactionRGB={secret(),secret(),secret()}
 local state={players={player=true,target=true,targettarget=false,focus=false,focustarget=false},classes={player='MAGE',target='MAGE',targettarget='PRIEST'},names={targettarget='NPC'},reaction=5,level=30,nativeReads=0}
 local UF={};e.UF=UF;e.Border=B;e.ns={Border=B,UnitFrames=UF};e.FluxBorder=B
 e.IsSecretValue=function(v)return private[v]or false end;e.issecretvalue=e.IsSecretValue
 e.PublicGeometryNumber=function(v)if not e.IsSecretValue(v)and type(v)=='number'then return v end end
 e.SafeBooleanTest=function(v,default)if e.IsSecretValue(v)then return default end;return not not v end
 e.API={IsSecretValue=e.IsSecretValue,SafeAccessibleString=function(v)if not e.IsSecretValue(v)and type(v)=='string'then return v end end,
  SafeGetNumber=function(v,default)if not e.IsSecretValue(v)and type(v)=='number'then return v end;return default end}
 e.UnitClass=function(u)return 'Class',state.classes[u]end;e.UnitIsPlayer=function(u)return state.players[u]end
 e.UnitName=function(u)return state.names[u]end;e.UnitLevel=function()return state.level end;e.UnitReaction=function()return state.reaction end
 e.UnitDisplayName=function(u)return e.API.SafeAccessibleString(state.names[u])end
 e.UnitSelectionColor=function()return table.unpack(reactionRGB)end
 e.CreateColor=function(r,g,b,a)return{r=r,g=g,b=b,a=a}end
 e.C_ClassColor={GetClassColor=function(id,tintColor)
  check(rawequal(id,opaqueClass),'opaque class identifier reaches approved native lookup unchanged')
  state.nativeReads=state.nativeReads+1
  local channels=tintColor and dark or rgb
  if tintColor then check(tintColor.r==.4 and tintColor.g==.4 and tintColor.b==.4,'backdrop tint is authored public input')end
  return{GetRGB=function()return table.unpack(channels)end}
 end}
 e.RAID_CLASS_COLORS.PRIEST={r=1,g=1,b=1}
 setmetatable(e.RAID_CLASS_COLORS,{__index=function(_,key)check(not e.IsSecretValue(key),'opaque class never indexes RAID_CLASS_COLORS');return nil end})
 UF.UsesHudUnitBars=function()return false end;UF.GetFramePublicLevel=function()return 40 end;UF.SetFramePublicLevel=function()end
 UF.UnitTokenIsResolved=function()return true end
 assert(load(class..'\n'..tint..'\n'..names..'\n'..rich..'\nUF.TestOpaqueName=PaintOpaqueUnitName;UF.TestRich=FluxTargetTotPetNameRichText;UF.TestParentName=function(self)\n'..parentPaint..'\nend',
  '@tot-actual-painters','t',e))()
 local parent=new(e.UIParent);parent.unit='target';B:ApplyTo(parent,2,2,3,5,.75)
 local tot=new(parent);tot.unit='targettarget';B:ApplyTo(tot,2,2,3,5,.75)
 local surface=new(tot);surface._FluxBorderOwner=tot;B:ApplyTo(surface,2,2,3,5,.75);tot.outerBorderFrame=surface
 tot.HealthPowerSeparator=tot:CreateTexture()
 local function isRGB(t,wanted)
  local r,g,b=table.unpack(t.fill or {t:GetVertexColor()});return rawequal(r,wanted[1])and rawequal(g,wanted[2])and rawequal(b,wanted[3])
 end
 -- NPCs use the selected style's DEFAULT material and palette, not Appearance.
 UF.UpdateBorderColors(parent);UF.UpdateBorderColors(tot)
 local r,g,b=B:GetDefaultAccentRGB();local dr,dg,dd=B:GetDefaultBackdropRGB()
 check(isRGB(tot.FluxBorderFrame.Top,{r,g,b}),'NPC ToT always uses Default accent RGB')
 check(B._pieces[tot.FluxBorderFrame.Top].naturalArt==true,'NPC ToT always uses default artwork even beneath a player parent')
 check(isRGB(tot.outerBorderFrame.FluxBorderFrame.Background,{dr,dg,dd}),'NPC backdrop follows Default instead of custom/class')
 local fs={SetText=function(self,t)self.text=t end,SetTextColor=function(self,...)self.color={...}end,
  SetFormattedText=function(self,fmt,...)self.format=fmt;self.args={...}end}
 UF.PaintUnitNameColor(fs,'targettarget');check(fs.color[1]==0 and fs.color[2]==1 and fs.color[3]==0,'friendly NPC name remains reaction-green')
 check(UF.TestRich():find('|cff00ff00NPC|r',1,true),'public rich ToT name preserves reaction color and level')
 state.names.targettarget=opaqueName
 check(UF.TestOpaqueName(fs,'targettarget','ToT: '),'restricted ToT name uses native formatted sink')
 check(rawequal(fs.args[1],opaqueName)and fs.args[2]==30,'name is forwarded unchanged; public level preserved')
 check(fs.format:find('|cffffffffToT: |r',1,true),'prefix remains white independently of native name color')
 -- Secret class -> native class-color + RGB sinks, never a Lua class lookup.
 state.players.targettarget=true;state.classes.targettarget=opaqueClass
 UF.UpdateBorderColors(tot)
 check(isRGB(tot.FluxBorderFrame.Top,rgb),'restricted class reaches ToT border native sink')
 check(isRGB(tot.outerBorderFrame.FluxBorderFrame.Background,dark),'restricted class backdrop uses native tint rather than Lua arithmetic')
 check(isRGB(tot.HealthPowerSeparator,rgb),'restricted class colors the HP/resource split')
 check(tot._FluxBorderUnitColor and tot._FluxBorderUnitColor.r==1,'only public material classification enters the unit-color cache')
 local colorReads=state.nativeReads
 check(UF.GetUnitNameColorHex('targettarget')==nil,'private RGB cannot enter rich-text hex formatting')
 check(state.nativeReads==colorReads,'hex formatting never allocates/queries native private class colors')
 UF.TestParentName({petNameText=fs})
 check(state.nativeReads==colorReads+1,'opaque parent ToT name paints its native class color exactly once')
 check(rawequal(fs.color[1],rgb[1])and rawequal(fs.color[2],rgb[2])and rawequal(fs.color[3],rgb[3]),'secret name + secret class get independent native text color')
 -- A secret reaction is passed to the existing native unit selection painter.
 state.players.targettarget=false;state.reaction=secret();UF.PaintUnitNameColor(fs,'targettarget')
 check(rawequal(fs.color[1],reactionRGB[1]),'restricted NPC reaction uses native selection color')
 state.reaction=5;state.level=secret();UF.TestOpaqueName(fs,'targettarget','ToT: ')
 check(#fs.args==1,'private level is omitted, never compared or interpolated in Lua')
 state.players.targettarget=true;state.classes.targettarget='PRIEST';UF.UpdateBorderColors(tot)
 local before={tot.FluxBorderFrame.Top:GetVertexColor()}
 state.classes.targettarget=opaqueClass;e.C_ClassColor=nil;UF.UpdateBorderColors(tot)
 check(isRGB(tot.FluxBorderFrame.Top,before),'missing native class capability holds prepared public color')
 state.players.targettarget=opaqueKind;UF.UpdateBorderColors(tot)
 check(isRGB(tot.FluxBorderFrame.Top,before),'unknown private player kind is not guessed to be an NPC')
end end end
print('ToT NPC/restricted colors: '..checks..' checks PASS /'..scenes..' scenes; default NPC material/all accents, opaque name/class/reaction native sinks; no native taint/pixels/FPS claim')
