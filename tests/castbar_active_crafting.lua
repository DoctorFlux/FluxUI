-- Production cast lifecycle/renderer with modeled native primitives. These
-- assertions do not certify native pixels, filtering, combat taint or FPS.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local src=read('tests/castbar_school_themes.lua')
src=src:sub(1,assert(src:find('local function checkParticleGeometry',1,true))-1)
src=src:gsub('pet="PetFrame"','pet="PetFrame",party1="PartyFrame"')
for i,path in ipairs{'UnitFrames/FluxCastBar.lua','UnitFrames/FluxCastBarTradeskills.lua'}do if arg[i]then
 local n;src,n=src:gsub('loadAddon%("'..path..'",env,ns%)',function()return'loadAddon('..string.format('%q',arg[i])..',env,ns)'end);assert(n==1)
end end
local fixture=assert(load(src..'\nreturn fixture','@active-crafting-producer-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function rgb(surface,r,g,b)local c=surface.borderColor;return c and c[1]==r and c[2]==g and c[3]==b end
local function views(trades)
 for i=1,20 do local name,value=debug.getupvalue(trades.Apply,i);if name=='views'then return value end end
 error('profession view registry not found')
end
for _,client in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
 for _,unit in ipairs{'player','target','focus','pet','party1'}do
  local s,e,ns=fixture(client)
  s.SetDB({castBarThemes={enabled=false}})
  ns.UnitFrames.GetUnitChromeColors=function()return .3,.5,.7,.12,.2,.28 end
  e.FluxBorder={GetThemedVertexRGB=function()return .3,.5,.7 end,GetThemedBackdropFillRGB=function()return .12,.2,.28 end}
  ns.Border.SetBorderColor=function(_,surface,...)surface.borderColor={...}end
  local bar=s.NewBar(unit)
  if unit=='party1'then local frame=bar:GetParent();frame._fluxPartyMember=true;frame._fluxPartyClassChrome=true;ns.PartyFrames={members={frame}}end
  local methods=getmetatable(bar.Icon).__index
  methods.SetSnapToPixelGrid=function(self,v)self.snap=v end
  methods.SetTexelSnappingBias=function(self,v)self.snapBias=v end
  local castInfo=e.UnitCastingInfo;local hint=12345;local iconQueries,atlasQueries,professionQueries=0,0,0
  local atlasInfo=e.C_Texture and e.C_Texture.GetAtlasInfo
  if atlasInfo then e.C_Texture.GetAtlasInfo=function(name,...)if rawequal(name,s.secret)then atlasQueries=atlasQueries+1 end;return atlasInfo(name,...)end end
  local professions=e.GetProfessions
  if professions then e.GetProfessions=function(...)professionQueries=professionQueries+1;return professions(...)end end
  e.UnitCastingInfo=function(u)
   local name,text,_,start,finish,trade,id,locked,spell=castInfo(u)
   return name,text,hint,start,finish,trade,id,locked,spell
  end
  e.C_Spell.GetSpellInfo=function(id)iconQueries=iconQueries+1;return{spellID=id,castTime=5000,iconID=54321}end
  local function start(trade,locked,texture,id)
   hint=texture;iconQueries,atlasQueries,professionQueries=0,0,0;s.casts[unit]={id=id or 7836,trade=trade,locked=locked}
   bar:CastStart(unit,false,'cast-1')
  end
  start(true,true,12345)
  check(bar.casting and bar.notInterruptible,'known crafting preserves the native active cast flags')
  check(rgb(bar.IconBorder,.3,.5,.7)and rgb(bar.BorderFrame,.3,.5,.7)and not bar.ShieldOverlay:IsShown(),client..' '..unit..' crafting uses normal chrome without a combat-only shield')
  if client=='live'or client=='forever'then check(bar.TimerBar._fluxFillAtlas=='ui-castingbar-filling-standard','known craft selects standard filling art before timer ownership')end
  e.FluxCastBar_ApplyAppearanceAccent()
  check(rgb(bar.IconBorder,.3,.5,.7)and rgb(bar.BorderFrame,.3,.5,.7),'appearance refresh cannot restore a stale crafting warning')
  check(bar.TimerBar:GetStatusBarTexture().snap==false and bar.TimerBar:GetStatusBarTexture().snapBias==0,'native fill uses the same sampling policy as its fitted border')
  for _,case in ipairs{{value=false},{value=s.secret},{value='unknown'}, {}}do
   start(case.value,true,12345)
   check(rgb(bar.IconBorder,1,0,0)and rgb(bar.BorderFrame,1,0,0)and (unit=='pet'or bar.ShieldOverlay:IsShown()),'combat or unreadable trade classification preserves the real uninterruptible warning')
   e.FluxCastBar_ApplyAppearanceAccent();check(rgb(bar.BorderFrame,1,0,0),'refresh preserves the real warning')
  end
  start(false,false,12345)
  check(rgb(bar.BorderFrame,.3,.5,.7)and not bar.ShieldOverlay:IsShown(),'next ordinary interruptible cast clears prior red/shield state')
  for _,missing in ipairs{{},{value=0},{value=false},{value=''},{value=136235},{value='Interface\\Icons\\temp'}}do
   start(true,true,missing.value)
   check(bar.Icon.path==54321 and iconQueries==1,'missing or placeholder recipe icon uses one public spell-icon lookup rather than a blank reserved slot')
   check(unit=='pet'or bar.IconFrame:IsShown(),'resolved icon remains visible in the fitted icon column')
  end
  local nativeTexture=bar.Icon.SetTexture
  bar.Icon.SetTexture=function(self,value)if rawequal(value,'bad-icon')then return false end;return nativeTexture(self,value)end
  start(true,true,'bad-icon');check(bar.Icon.path==54321,'native texture rejection triggers the same public fallback')
  bar.Icon.SetTexture=nativeTexture
  start(false,true,s.secret)
  check(rawequal(bar.Icon.path,s.secret)and iconQueries==0 and atlasQueries==0 and professionQueries==0,'restricted icon passes directly to the native sink without metadata lookup')
  start(true,true,nil,s.secret)
  check(iconQueries==0 and bar.Icon.path=='Interface\\Icons\\INV_Misc_QuestionMark','restricted spell identity is never queried for a missing icon')
  local modernInfo=e.C_Spell.GetSpellInfo
  e.C_Spell.GetSpellInfo=nil
  e.GetSpellInfo=function()return'Spell',nil,87654 end
  start(true,true,nil)
  check(bar.Icon.path==87654,'a client without C_Spell.GetSpellInfo uses the existing legacy spell-icon return')
  e.C_Spell.GetSpellInfo=function()iconQueries=iconQueries+1;return s.secret end
  start(true,true,nil)
  check(iconQueries==1 and bar.Icon.path=='Interface\\Icons\\INV_Misc_QuestionMark','restricted spell-info tables are never indexed for an icon')
  e.C_Spell.GetSpellInfo=modernInfo
  if client=='live'or client=='forever'then
   local atlasInfo=e.C_Texture.GetAtlasInfo
   e.C_Texture.GetAtlasInfo=function(name)if name=='Profession-Alchemy-Icon'then return{width=32,height=32}end;return atlasInfo(name)end
   start(true,true,'Profession-Alchemy-Icon')
   check(bar.Icon.atlas=='Profession-Alchemy-Icon'and iconQueries==0,'public atlas icon uses the atlas setter without resizing the column')
   start(false,false,12345)
   check(bar.Icon.path==12345 and bar.Icon.uv[1]==.1 and bar.Icon.uv[2]==.9,'following file icon restores its ordinary crop after atlas artwork')
  end
 end
 if client=='live'or client=='forever'then
  local s,e,ns=fixture(client,{tradeThemes=true,nativeParticles=true})
  local bar=s.NewBar('player');local methods=getmetatable(bar.Icon).__index
  methods.SetSnapToPixelGrid=function(self,v)self.snap=v end
  methods.SetTexelSnappingBias=function(self,v)self.snapBias=v end
  local maskCreates,maskBinds,attached=0,0,{}
  local createMask,addMask=methods.CreateMaskTexture,methods.AddMaskTexture
  methods.CreateMaskTexture=function(self,...)maskCreates=maskCreates+1;return createMask(self,...)end
  methods.AddMaskTexture=function(self,mask)maskBinds=maskBinds+1;attached[self]=(attached[self]or 0)+1;return addMask(self,mask)end
  bar.TimerBar:SetHeight(32)
  s.professions[7836]={profession=e.Enum.Profession.Alchemy}
  s.Cast('player',7836,false,true)
  local view=assert(views(ns.CastBarTradeskills)[bar])
  check(view.fill:IsShown()and view.animation.playing,'active crafting retains the native animated profession artwork')
  check(view.fill.snap==false and view.fill.snapBias==0 and view.mask.snap==false and view.mask.snapBias==0,'animated fill and existing progress mask share the native fill sampling policy')
  local source=bar.TimerBar:GetStatusBarTexture()
  check(view.fill.mask==view.mask and view.flare.mask==view.mask,'profession flare and animated fill share the exact existing native progress mask')
  check(maskCreates==1 and maskBinds==2 and attached[view.fill]==1 and attached[view.flare]==1,'one prebuilt mask binds once to each texture without consuming repeated mask slots')
  check(view.mask.allPoints==source,'both profession layers follow the actual native fill source')
  local saved={}
  local function forbid(object,key)
   saved[#saved+1]={object,key,object[key]};object[key]=function()error('profession art queried restricted progress '..key)end
  end
  for _,key in ipairs{'GetWidth','GetSize','GetRect'}do forbid(source,key)end
  for _,key in ipairs{'GetValue','GetMinMaxValues'}do forbid(bar.TimerBar,key)end
  source.width=1;source.height=32 -- Modeled early native progress, not a Lua production query.
  ns.CastBarTradeskills.Apply(bar,bar._fluxSchoolCast,{})
  check(view.flare:GetWidth()>source.width and view.flare.mask==view.mask,'the wide early-progress flare remains constrained by the shared native mask')
  local frames,textures,positions,recipes=#s.frames,#s.textures,s.work.positions,s.work.recipes
  for _,width in ipairs{1,130,259}do
   source.width=width
   for _=1,40 do ns.CastBarTradeskills.Apply(bar,bar._fluxSchoolCast,{})end
   check(view.flare.mask==view.mask and view.mask.allPoints==source,'early/middle/late progress retain native mask bindings without reading progress geometry')
  end
  check(#s.frames==frames and #s.textures==textures and s.work.positions==positions and s.work.recipes==recipes,'stable crafting appearance allocates, re-queries and repositions nothing')
  check(maskCreates==1 and maskBinds==2,'progress updates allocate or attach no additional masks')
  for _,entry in ipairs(saved)do entry[1][entry[2]]=entry[3]end
  ns.CastBarTradeskills.Apply(bar,bar._fluxSchoolCast,{edge=false})
  check(not view.flare:IsShown()and bar.Spark:GetAlpha()==1,'disabled profession edge restores the normal native Spark fallback')
  ns.CastBarTradeskills.Apply(bar,bar._fluxSchoolCast,{})
  check(view.flare:IsShown()and bar.Spark:GetAlpha()==0,'re-enabled profession edge preserves its normal Spark suppression')
  local replacement=bar.TimerBar:CreateTexture();replacement.width=1;replacement.height=32
  replacement.GetWidth=function()error('replacement restricted width read')end
  bar.TimerBar.texture=replacement
  ns.CastBarTradeskills.Apply(bar,bar._fluxSchoolCast,{})
  check(source:GetAlpha()==1 and replacement:GetAlpha()==0,'actual source replacement restores old alpha and retains profession fill ownership')
  check(view.mask.allPoints==replacement and view.fill.mask==view.mask and view.flare.mask==view.mask,'source replacement reanchors the same shared mask rather than allocating new masks')
  check(maskCreates==1 and maskBinds==2,'source replacement consumes no additional mask slots')
  replacement.GetWidth=methods.GetWidth
  s.Event(bar,'UNIT_SPELLCAST_STOP','player','cast-1',7836)
  local color=bar.TimerBar.color
  check(color[1]==.12 and color[2]==.86 and color[3]==.15,'profession mask containment preserves the accepted green completion')
  check(not view.fill:IsShown()and not view.flare:IsShown()and not view.animation.playing and replacement:GetAlpha()==1,'actual completion resets profession layers and restores native alpha')
  s.professions[18560]={profession=e.Enum.Profession.Tailoring}
  s.Cast('player',18560,false,true)
  check(view.fill.atlas=='Skillbar_Fill_Flipbook_Tailoring'and view.animation.playing,'Mooncloth-shaped recipe change retains Tailoring art and native animation')
  check(view.flare.mask==view.mask and view.fill.mask==view.mask and maskCreates==1 and maskBinds==2,'recast and profession changes reuse the original shared mask')
  s.missingAtlas.Skillbar_Flare_Tailoring=true
  s.Cast('player',18560,false,true)
  check(view.fill:IsShown()and not view.flare:IsShown()and bar.Spark:GetAlpha()==1,'a missing profession flare preserves animated fill and native Spark fallback')
  bar:Hide()
  check(not view.fill:IsShown()and not view.flare:IsShown()and not view.animation.playing and replacement:GetAlpha()==1,'native hide resets the prepared profession art without new geometry')
  check(maskCreates==1 and maskBinds==2,'all craft lifecycle transitions retain one mask and two one-time attachments')
 end
end
print('active crafting cast bar: '..checks..' checks PASS; actual producers/known-private states/icon fallback/sampling; native fit pending')
