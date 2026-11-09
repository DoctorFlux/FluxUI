-- Actual name paint/fitting functions. Clipped metrics and opaque values model
-- the failure boundaries; native pixels/secret VM still require gameplay tests.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(os.getenv('FLUX_NAME_FIT_SOURCE') or 'UnitFrames/FluxUnitFrames_Shared.lua')
local checks=0
local function check(v,m)assert(v,m);checks=checks+1 end
local function section(a,b)local x=assert(source:find(a,1,true));return source:sub(x,assert(source:find(b,x+1,true))-1)end
local secret=setmetatable({},{__tostring=function()error('opaque string conversion')end,__concat=function()error('opaque concat')end,__lt=function()error('opaque compare')end})
local s={name='Long character name for fitting',width=90,resolved=true,regional=false,showSurname=true,measurements=0}
local function public(v)if not rawequal(v,secret) and type(v)=='string' then return v end end
local function number(v)if not rawequal(v,secret) and type(v)=='number' then return v end end
local E=setmetatable({},{__index=_G});E._G=E
E.API={IsSecretValue=function(v)return rawequal(v,secret)end,SafeAccessibleString=public,SafeGetNumber=function(v,d)return number(v) or d end}
E.PublicGeometryNumber=number;E.NAME_FONT_PATH='Fonts\\FRIZQT__.TTF'
E.UF={UnitTokenIsResolved=function()return s.resolved end};E.UnitName=function()return s.name,s.surname end
E.UnitDisplayName=function()return public(s.name)end
E.ns={Flux={PlayerName={UsesRegionalUniqueNames=function()return s.regional end,ShouldDisplaySurname=function()return s.showSurname end,GetSurnameSeparator=function()return ' ' end}}}
E.GetOuterBorderContentWidth=function()return s.width end;E.GetNameStripSideReserve=function()return 12 end;E.FitNameStripMetadata=function()end
E.UnitIsPlayer=function()return false end;E.UnitReaction=function()return 5 end;E.RAID_CLASS_COLORS={}
local paint,opaquePaint=assert(load(section('local function UnitFrameResolvedDisplayName','-- Aura system loads automatically')..'\nreturn PaintUnitFrameNameText,PaintOpaqueUnitName','@real-name-paint','t',E))()
-- The private helper definitions above must remain local to the same chunk as
-- the fit owners. Load their production blocks together, with geometry stubs.
local measurementStart=source:find('local function NameTextWidth',1,true) and 'local function NameTextWidth' or 'local function BinarySearchFontSize'
local fit,secondary=assert(load(section(measurementStart,'--- Place compact level/rarity/type')..'\n'..section('local function FitUnitFrameNameText','-- Both player and normal party use')..'\nreturn FitUnitFrameNameText,FitUnitFrameSecondaryNameText','@real-name-fit','t',E))()
local function label()
 local f={size=16,scale=1,shown=true}
 function f:SetText(v)self.text=v end
 function f:GetText()return self.text end
 function f:SetFormattedText(fmt,...)
  self.format=fmt;local a={...};for _,v in ipairs(a)do if rawequal(v,secret)then self.text=secret;return end end
  self.text=string.format(fmt,...)
 end
 function f:SetFont(_,size)self.size=size end
 function f:SetWidth(w)self.width=w end
 function f:SetWordWrap()end
 function f:SetJustifyH()end
 function f:IsShown()return self.shown end
 function f:GetUnboundedStringWidth()
  s.measurements=s.measurements+1
  if s.opaqueWidth or rawequal(self.text,secret)then return secret end
  local text=(self.text or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
  return #text*self.size*.5*self.scale
 end
 function f:GetStringWidth()local w=self:GetUnboundedStringWidth();if rawequal(w,secret)then return w end;return math.min(self.width or w,w)end
 return f
end
for _,client in ipairs({'live','forever','classic','classic_era','classic_anniversary'})do
 s.regional=client=='forever'
 for _,unit in ipairs({'player','target','focus','targettarget','party1','party4'})do
  s.name,s.width,s.resolved,s.opaqueWidth='Very long character name beyond the available space',90,true,false
  s.surname=nil
  local f={unit=unit,nameText=label()}
  if unit:find('party')then f._fluxPartyNameTextAnchor={GetWidth=function()return 55 end};f._fluxPartyNameTextScale=1.4;f.nameText.scale=1.4 end
  fit(f,paint(f,f.nameText),16,8)
  local text,size=f.nameText.text,f.nameText.size
  check(text~=s.name and #text>0,'long names are fitted using unclipped width')
  local measured=s.measurements
  for i=1,12 do
   fit(f,paint(f,f.nameText),16,8)
   check(f.nameText.text==text and f.nameText.size==size,'repaint restores fitted text and font without oscillation')
  end
  check(s.measurements==measured,'stable fit cache does not remeasure names')
  s.name='New';fit(f,paint(f,f.nameText),16,8)
  check(f.nameText.text=='New','target/member replacement clears old fitted text')
  s.name,s.surname=secret,secret
  local before=s.measurements;fit(f,paint(f,f.nameText),16,8)
  check(rawequal(f.nameText.text,secret) and f._fluxLastRealName==nil and s.measurements==before,'restricted current name reaches sink and never reuses previous unit name')
  check(f.nameText.format==(s.regional and '%s %s' or '%s'),'regional surname native format retained')
  if s.regional then
   s.name='Public first name';paint(f,f.nameText)
   check(rawequal(f.nameText.text,secret) and f.nameText.format=='%s %s' and not f._fluxLastRealName,'restricted surname alone stays in native formatter')
   s.name=secret
  end
  s.showSurname=false;paint(f,f.nameText);check(f.nameText.format=='%s','surname-off policy retained');s.showSurname=true
  s.resolved=false;paint(f,f.nameText)
  check(f.nameText.text=='' and not f._fluxLastRealName,'unresolved identity clears stale name')
  s.resolved=true;s.name='Opaque geometry but public name';s.opaqueWidth=true
  before=f.nameText.size;fit(f,paint(f,f.nameText),16,8)
  check(f.nameText.size==before and not f.nameText._fluxNameFitKey,'restricted metrics keep stable font without caching fake zero width')
  s.opaqueWidth=false
 end
 local f={unit='target',petNameText=label()};s.width=100
 local full='ToT: A very long enemy target name [72]'
 f.petNameText:SetText(full);secondary(f)
 local text,size=f.petNameText.text,f.petNameText.size
 for i=1,12 do f.petNameText:SetText(full);secondary(f);check(f.petNameText.text==text and f.petNameText.size==size,'ToT cache restores fitted public text')end
 s.name,s.surname=secret,secret
 check(opaquePaint(f.petNameText,'targettarget','ToT: '),'restricted ToT uses native formatter')
 local before=s.measurements;secondary(f)
 check(rawequal(f.petNameText.text,secret) and s.measurements==before,'restricted ToT text never becomes a fit/cache key')
 check(f.petNameText.format==(s.regional and 'ToT: %s %s' or 'ToT: %s'),'ToT prefix and surname formatting retained')
end
print('Name/ToT fit lifecycle: '..checks..' checks; five client models; native text/taint pending')
