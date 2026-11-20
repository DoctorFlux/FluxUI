-- Actual full visual refresh, name paint/fitting, icon placement and regen branch.
-- Native endpoints are modeled; this does not certify native rendering or taint.
local sourcePath='UnitFrames/FluxUnitFrames_Shared.lua'
if arg and arg[1]=='--source'then sourcePath=assert(arg[2])end
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(sourcePath)
local function section(a,b)local x=assert(source:find(a,1,true),a);return source:sub(x,assert(source:find(b,x+#a,true),b)-1)end
local function loadenv(b,p,e)
 if _VERSION=='Lua 5.1'then local f,err=loadstring(b,p);if f then setfenv(f,e)end;return f,err end
 return load(b,p,'t',e)
end
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local function fixture()
 local s={combat=false,locked=false,rest=false,class='MAGE',spec='Interface\\Icons\\SpecMage',name='A long public character name for combat reserve fitting',
  queries={class=0,spec=0,level=0,name=0,player=0},health=0,tint=0,sync=0,trace={},getters=0,marker={}}
 local private=setmetatable({}, {__eq=function()error('private native value compared')end,__concat=function()error('private concatenation')end,__tostring=function()error('private conversion')end})
 local inaccessible=setmetatable({}, {__eq=function()error('inaccessible native value compared')end})
 local function public(v)return not rawequal(v,private)and not rawequal(v,inaccessible)end
 local function number(v)if public(v)and type(v)=='number'then return v end end
 local e=setmetatable({}, {__index=_G});e._G=e
 e.API={IsSecretValue=function(v)return rawequal(v,private)end,CanAccessValue=public,
  SafeAccessibleString=function(v)if public(v)and type(v)=='string'then return v end end,
  SafeGetNumber=function(v,d)return number(v)or d end}
 e.PublicGeometryNumber=number
 e.UF={UnitTokenIsResolved=function()return true end,FrameUsesPortraitLayout=function()return false end,
  UpdateHealthColor=function()s.health=s.health+1 end,UpdatePortraitCombatTint=function()s.tint=s.tint+1 end}
 e.ns={Flux={}};e.IsFluxUnitFrame=function()return true end
 e.UnitAffectingCombat=function()return s.combat end;e.InCombatLockdown=function()return s.locked end;e.IsResting=function()return s.rest end
 e.UnitIsPlayer=function()s.queries.player=s.queries.player+1;return s.isPlayer~=false end
 e.UnitClass=function()s.queries.class=s.queries.class+1;return 'localized',s.class end
 e.GetSpecIcon=function()s.queries.spec=s.queries.spec+1;return s.spec end
 e.UnitLevel=function()s.queries.level=s.queries.level+1;return s.level or 72 end
 e.UnitName=function()s.queries.name=s.queries.name+1;return s.name end
 e.UnitDisplayName=function()return e.API.SafeAccessibleString(e.UnitName())end
 e.UnknownObjectName=function()return 'Unknown'end
 e.UnitIsUnit=function(a,b)return a==b end;e.UnitReaction=function()return 5 end
 e.GetDifficultyColor=function()return{r=1,g=.8,b=.2}end
 e.FluxUnitFrames_ShouldShowClassIcon=function()return s.classEnabled~=false end
 e.FluxUnitFrames_ShouldShowCombatIcon=function()return s.combatEnabled~=false end
 e.FluxUnitFrames_ShouldShowLevel=function()return s.levelEnabled~=false end
 e.SyncRelatedWatchedFrames=function()s.sync=s.sync+1 end
 e.UnitClassification=function()return 'rare'end;e.UnitCreatureType=function()return 'Humanoid'end
 local function region(label)
  local f={label=label,shown=true,width=36,height=36,points={},level=5,fontSize=16,writes={},modes={}}
  local function get(method,...)
   s.getters=s.getters+1
   if f.modes[method]=='error'then error(s.marker,0)end
   if f.modes[method]=='private'then return private end
   if f.modes[method]=='inaccessible'then return inaccessible end
   return ...
  end
  local function write(method)
   f.writes[method]=(f.writes[method]or 0)+1;s.trace[#s.trace+1]=label..'.'..method
   if f.fail==method then error(s.marker,0)end
  end
  function f:SetSize(w,h)write('SetSize');self.width,self.height=w,h end
  function f:GetSize()return get('GetSize',self.width,self.height)end
  function f:GetWidth()return get('GetWidth',self.width)end;function f:GetHeight()return get('GetHeight',self.height)end
  function f:ClearAllPoints()write('ClearAllPoints');self.points={};if self.afterClear then self.afterClear()end end
  function f:SetPoint(...)write('SetPoint');self.points[#self.points+1]={...}end
  function f:GetNumPoints()return get('GetNumPoints',#self.points)end
  function f:GetPoint(i)
   local point=self.points[i]or{}
   if self.modes.GetPoint=='private'then return point[1],private,point[3],point[4],point[5]end
   if self.modes.GetPoint=='inaccessible'then return point[1],inaccessible,point[3],point[4],point[5]end
   return get('GetPoint',(table.unpack or unpack)(point))
  end
  function f:SetFrameLevel(v)write('SetFrameLevel');self.level=v end
  function f:GetFrameLevel()return get('GetFrameLevel',self.level)end
  function f:SetTexture(v)write('SetTexture');self.texture=v;if self.textureDrift then self.width=1;self.points={}end end
  function f:GetTexture()if self.preferredMissing and self.texture and self.texture:find('ClassIcon_',1,true)then return nil end;return self.texture end
  function f:SetTexCoord(...)write('SetTexCoord');self.coords={...}end
  function f:SetDrawLayer(...)write('SetDrawLayer');self.layer={...}end
  function f:Show()write('Show');self.shown=true;if self.afterShow then self.afterShow()end end
  function f:Hide()write('Hide');self.shown=false end;function f:IsShown()return self.shown end
  function f:SetAlpha(v)write('SetAlpha');self.alpha=v end
  function f:SetFont(path,size,flags)write('SetFont');self.fontPath,self.fontSize,self.flags=path,size,flags end
  function f:SetText(v)write('SetText');self.text=v end;function f:GetText()return self.text end
  function f:SetFormattedText(fmt,...)write('SetFormattedText');local values={...};for _,v in ipairs(values)do if not public(v)then self.text=private;return end end;self.text=string.format(fmt,...)end
  function f:SetWidth(v)write('SetWidth');self.width=v end
  function f:SetWordWrap(v)write('SetWordWrap');self.wordWrap=v end
  function f:SetJustifyH(v)write('SetJustifyH');self.justify=v end
  function f:SetTextColor(...)write('SetTextColor');self.color={...}end
  function f:GetUnboundedStringWidth()return public(self.text)and #(self.text or'')*self.fontSize*.5 or private end
  function f:GetStringWidth()
   self.stringWidthReads=(self.stringWidthReads or 0)+1
   return self:GetUnboundedStringWidth()
  end
  return f
 end
 local frame=region('frame');frame.unit='player';frame.width=400;frame.height=80
 for _,key in ipairs{'classIcon','specIcon','combatIcon','restIcon','combatIconFrame','levelText','nameText','outerBorderFrame'}do frame[key]=region(key)end
 frame.outerBorderFrame.width=400;frame.outerBorderPadding=36;frame.outerBorderAlignment='BOTTOM';frame.portraitPosition='LEFT'
 frame.nameText.shown=true;frame.combatIcon.shown=false;frame.restIcon.shown=false
 frame.restAnimation={playing=false,Play=function(a)a.playing=true end,Stop=function(a)a.playing=false end,IsPlaying=function(a)return a.playing end}
 local body=section('local function UnitFrameResolvedDisplayName','-- Aura system loads automatically')
  ..section('local NAME_FONT_PATH','local function UnitIsMasterLooterOfGroup')
  ..section('local function FitUnitFrameNameText','-- Both player and normal party use')
  ..section('function UF.UpdateFrameVisualElements(self)','-- HP / power / mana splitter textures')
  ..'\nreturn LayoutNameStripCombatIcon,GetNameStripSideReserve,FitNameStripMetadata'
 local layout,reserve,fitMetadata=assert(loadenv(body,'@actual-full-visual-name-refresh',e))()
 frame.UpdateFrameVisualElements=e.UF.UpdateFrameVisualElements
 local regen=section('    -- Combat icon (player) and threat bar (target)','    if event == "UNIT_FLAGS" then')
 s.event=assert(loadenv('return function(self,event)\n'..regen..'\nend','@actual-regen-visual-branch',e))()
 s.frame,s.env,s.layout,s.reserve,s.private,s.inaccessible=frame,e,layout,reserve,private,inaccessible
 s.fitMetadata=fitMetadata
 function s:refresh()return self.frame:UpdateFrameVisualElements()end
 function s:geometryWrites()
  local total=0;for _,k in ipairs{'classIcon','specIcon','combatIcon','restIcon','combatIconFrame'}do
   for _,method in ipairs{'SetSize','ClearAllPoints','SetPoint','SetFrameLevel'}do total=total+(self.frame[k].writes[method]or 0)end
  end;return total
 end
 return s
end
for _,combat in ipairs{true,false}do
 local s=fixture();s.combat,s.locked,s.rest=combat,combat,not combat;s:refresh()
 local before=s:geometryWrites();local health=s.health;local queries={};for k,v in pairs(s.queries)do queries[k]=v end
 for _=1,30 do s.event(s.frame,combat and'PLAYER_REGEN_DISABLED'or'PLAYER_REGEN_ENABLED')end
 check(s:geometryWrites()==before,'30 repeated combat/rest visual events skip only identical native icon geometry')
 check(s.health==health+30 and s.tint==30 and s.sync==(combat and 0 or 30),'every original visual/health/tint/watched event remains')
 check(s.queries.class==queries.class+30 and s.queries.spec==queries.spec+(combat and 0 or 30)
  and s.queries.level==queries.level+30 and s.queries.name==queries.name+30,'class/spec/level/name facts retain original freshness/cadence')
 check(s.frame.nameText.width==(combat and 255 or 287)and(not combat or s.frame.combatIcon.width==28),'combat icon width is established before actual name fitting reserve')
end
do
 local s=fixture();s:refresh();local f=s.frame
 f.classIcon.width=1;f.classIcon.points={{'TOPLEFT',f.outerBorderFrame,'TOPLEFT',0,-4},{'LEFT',f,'LEFT',0,0}}
 f.specIcon.height=1;f.specIcon.points={};f.combatIconFrame.level=1
 s:refresh();check(f.classIcon.width==36 and #f.classIcon.points==1 and f.classIcon.points[1][1]=='TOPLEFT','class current size and multiple-anchor drift repaired')
 check(f.specIcon.height==36 and #f.specIcon.points==1 and f.specIcon.points[1][2]==f.classIcon and f.combatIconFrame.level==27,'spec and combat-level drift repaired')
 s.combat=true;s.locked=true;f.combatIcon.width=1;f.combatIcon.points={};s:refresh()
 check(f.combatIcon.width==28 and f.combatIcon.points[1][2]==f.levelText,'combat icon native drift repaired before fitting')
 s.combat=false;s.locked=false;s.rest=true;f.restIcon.width=1;f.restIcon.points={};s:refresh()
 check(f.restIcon.width==32 and f.restIcon.points[1][2]==f.levelText,'rest icon current drift repaired')
 f.restIcon=nil;s:refresh();check(f.combatIcon.width==32 and f.combatIcon.shown,'classic no-rest-region fallback preserved')
 s.rest=false;s.class='WARRIOR';s.spec='Interface\\Icons\\WarriorSpec';f.classIcon.preferredMissing=true;s:refresh()
 check(f.classIcon.texture=='Interface\\Icons\\Class_WARRIOR'and f.specIcon.texture==s.spec,'class/spec query and legacy texture fallback preserved')
 s.class=s.private;s:refresh();check(not f.classIcon.shown,'private class still hides stale class icon')
 s.class='MAGE';s.name=s.private;s:refresh();check(rawequal(f.nameText.text,s.private),'private unit name still reaches native formatter unchanged')
 s.name='Short';s:refresh();check(f.nameText.text=='Short','public replacement identity restores name')
 s.classEnabled=false;s:refresh();check(not f.classIcon.shown and not f.specIcon.shown,'class/spec option remains live')
end
for _,mode in ipairs{'private','inaccessible','error','missing'}do
 local s=fixture();s.combat=true;s.locked=true;s:refresh();local f=s.frame
 for _,spec in ipairs{{f.classIcon,'GetSize'},{f.classIcon,'GetPoint'},{f.combatIcon,'GetSize'},{f.combatIcon,'GetNumPoints'},{f.combatIconFrame,'GetFrameLevel'}}do
  if mode=='missing'then spec[1][spec[2]]=false else spec[1].modes[spec[2]]=mode end
 end
 local size,point,level=f.classIcon.writes.SetSize or 0,f.classIcon.writes.SetPoint or 0,f.combatIconFrame.writes.SetFrameLevel or 0
 s:refresh();check(f.classIcon.writes.SetSize==size+1 and f.classIcon.writes.SetPoint==point+1
  and f.combatIconFrame.writes.SetFrameLevel==level+1,mode..': original geometry setter path remains for unavailable current state')
end
for _,method in ipairs{'SetSize','ClearAllPoints','SetPoint','SetFrameLevel'}do
 local s=fixture();s:refresh();local f=s.frame;local icon=method=='SetFrameLevel'and f.combatIconFrame or f.classIcon
 icon.width=1;icon.points={};icon.level=1;icon.fail=method
 local ok,err=pcall(function()s:refresh()end)
 check(not ok and err==s.marker,method..': direct native setter preserves exact opaque error')
 icon.fail=nil;s:refresh();check(icon.writes[method]>=2,method..': later full refresh retries failed native write')
end
do
 local s=fixture();s:refresh();local f=s.frame;local replacement={GetFrameLevel=function()return 5 end,GetWidth=function()return 400 end}
 f.classIcon.points={};f.classIcon.afterClear=function()f.outerBorderFrame=replacement end
 s:refresh();check(f.classIcon.points[1][2]==replacement,'mismatch keeps Clear callback before reading actual anchor owner')
end
do
 local s=fixture();s:refresh();local f=s.frame
 f.classIcon.afterShow=function()f.classIcon.points={}end
 s:refresh();check(#f.classIcon.points==1,'Show callback geometry drift still repaired before anchor placement')
 f.classIcon.afterShow=nil;f.classIcon.textureDrift=true;s:refresh()
 check(f.classIcon.width==36 and #f.classIcon.points==1,'texture callback geometry drift remains observable before size/point repair')
 local before=s.health;f.classIcon.points={};f.classIcon.afterClear=function()s.combat=true;s.locked=true end
 s:refresh();check(s.health==before+1 and s.locked,'mid-call combat reentry keeps full visual/health pass and current spec lockdown guard')
end
do
 local s=fixture()
 local f=s.frame
 f.unit='party1'
 local level=f.levelText
 f._fluxLevelMetaVariants={'72'}
 f._fluxLevelMetaIsPlayer=true
 f._fluxLevelMetaLevel=72
 s.fitMetadata(f)
 check(level.text=='72' and level.fontSize==13 and level.color[2]==.8
  and level.writes.SetText==1 and not level.stringWidthReads,
  'a single level label uses its font and difficulty color without a width measurement')
 f._fluxLevelMetaVariants={'72 Rare Humanoid with a long label','72 Rare','72'}
 f._fluxLevelMetaIsPlayer=false
 f.outerBorderFrame.width=100
 s.fitMetadata(f)
 check(level.text=='72' and level.stringWidthReads==3,
   'multiple NPC labels still measure and choose the shortest fitting variant')

 f._fluxLevelMetaVariants={'72'}
 local getWidth=f.outerBorderFrame.GetWidth
 local rejected=false
 f.outerBorderFrame.GetWidth=function(self)
  rejected=true
  return getWidth(self)
 end
 f._fluxPartyNameTextAnchor={GetWidth=function()return 88 end}
 s.env.UF.FitNameText(f,'A long party name that must still fit',16,8)
 check(not rejected and f.nameText.width==88 and #f.nameText.text>0,
  'the public party name anchor bypasses the unused shared name budget')
 f._fluxPartyNameTextAnchor.GetWidth=function()return s.private end
 s.env.UF.FitNameText(f,'A different name',16,8)
 check(rejected and f.nameText.width~=88,'private anchor width falls back to the original budget')
end
print('unit visual geometry work: '..checks..' checks PASS; native latency/rendering/taint pending')
