-- Actual Shared/Party tint producers, FluxBorder and prepared junction hooks.
-- Actual producers and prepared renderer; desktop ownership/work parity only.
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function part(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(i,assert(s:find(b,i+#a,true),b)-1)end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local original=part(prefix,'    local style,accent=1,"class"','    if not waitForWorld then')
local replacement=[[
    function m:EnableMouse()end
    e.UnitClass=function()return 'Mage','MAGE'end
    e.RAID_CLASS_COLORS={MAGE={r=.2,g=.5,b=.8}}
    e.Flux.Client={isForever=true}
    local appearance={borderType=1,borderAccent='class'}
    e.FluxOptions={db={profile={appearance=appearance}}}
    local ns={}
    assert(load(read('FluxBorder.lua'),'@actual-border','t',e))('_FluxUI',ns)
    local B=e.FluxBorder
    e.junctionExports=assert(load(read('Core/BorderJunctions.lua')..'\nreturn {active=function()return active end,clipped=clipped,groups=groups,paintDirty=paintDirty,pending=function()return pendingObjects end}','@actual-junction-hooks','t',e))('_FluxUI',ns)
    e.borderNamespace=ns
    local style,accent=1,'class'
]]
prefix=prefix:gsub(original:gsub('([^%w])','%%%1'),function()return replacement end,1)
prefix=prefix:gsub('function%(a,b%)style=a;accent=b end','function(a,b)style=a;accent=b;appearance.borderType=a;appearance.borderAccent=b end',1)
local fixture=assert(load(prefix..'\nreturn fixture','@actual-paint-mesh-fixture','t',_G))()
local shared=read('UnitFrames/FluxUnitFrames_Shared.lua');local party=read('UnitFrames/FluxUnitFrames_Party.lua')
local tint=part(shared,'local PORTRAIT_COMBAT_BORDER_R','-- Unit name on outer border:')
local partyPaint=part(party,'function Party.PaintChrome','function Party.RefreshChrome')
local keys={'TL','TR','BL','BR','Top','Bottom','Left','Right'}
local function Scene(style,enabled,reference)
 local results={}
 local j,new,piece,flush,objects,lock,choose,queued,e=fixture();choose(style,'class')
 local b=e.FluxBorder;local ns=e.borderNamespace;local UF,Party={},{};ns.UnitFrames=UF;ns.PartyFrames=Party;ns.Flux=e.Flux;ns.API={IsSecretValue=function()return false end}
 e.UF=UF;e.Party=Party;e.ns=ns;e.Border=b;e.API={SafeAccessibleString=function(v)return type(v)=='string'and v or nil end}
 e.UnitExists=function()return true end;e.UnitIsPlayer=e.UnitExists;e.UnitCanAttack=function()return false end;e.UnitIsFriend=e.UnitExists
 e.SafeBooleanTest=function(v,fallback)return type(v)=='boolean'and v or fallback end
 e.IsSecretValue=function(v)return e.issecretvalue and e.issecretvalue(v)or false end;e.Secret=e.IsSecretValue
 e.GetUnitClassColor=function()return e.RAID_CLASS_COLORS.MAGE end;e.ClassColorForUnit=e.GetUnitClassColor
 e.PublicGeometryNumber=function(v)return type(v)=='number'and v or nil end
 e.FluxUnitFrames_IsPortraitCombatTintEnabled=function()return enabled end
 local classes,players={},{};e.RAID_CLASS_COLORS.WARRIOR={r=.8,g=.3,b=.1};e.UnitClass=function(u)local c=classes[u]or'MAGE';return c,c end;e.UnitIsPlayer=function(u)return players[u]~=false end;e.GetUnitClassColor=function(u)return e.RAID_CLASS_COLORS[classes[u]or'MAGE']end;e.ClassColorForUnit=e.GetUnitClassColor
 local combat={};e.UnitAffectingCombat=function(unit)return combat[unit]or false end
 local policies=part(shared,'function UF.ForeverNpcChrome','-- Separator / chrome tint:')
 UF.GetFramePublicLevel=function(f)return f:GetFrameLevel()end;UF.UsesHudUnitBars=function()return false end
 local m=getmetatable(e.UIParent).__index
 function m:GetAtlas()return self.atlas end
 function m:SetColorTexture(r,g,bb,a)self.fill={r,g,bb,a}end
 function m:CreateTexture()local t=new(self,nil,'Texture');t.decorative=true;return t end
 function m:GetRegions()local r={};for _,o in ipairs(objects)do if o.parent==self then r[#r+1]=o end end;return table.unpack(r)end
 e.C_Timer={After=function(_,fn)e._later=e._later or{};e._later[#e._later+1]=fn end}
 e.DebuffTypeColor={Magic={r=.2,g=.6,b=1},Poison={r=0,g=.6,b=0}}
 local debuff
 e.C_UnitAuras={GetAuraDataByIndex=function(_,i)if debuff and i==1 then return {dispelName=debuff}end end}
 function e.FluxOptions:GetUnitFrameDB()return {}end
 local count={};local measuring=false
 local function bump(key)if measuring then count[key]=(count[key]or 0)+1 end end
 for _,name in ipairs{'SetVertexColor','SetAlpha','SetTexture','SetTexCoord','SetPoint','ClearAllPoints','SetSize','SetFrameLevel','Show','Hide','GetAlpha','GetRect','GetParent'}do
  local prior=m[name];m[name]=function(self,...)
   local kind=b._pieces[self]and'source'or self.decorative and'field'or'other'
   bump(kind..'.'..name);return prior(self,...)
  end
 end
 local oldInvalidate=j.Invalidate;j.Invalidate=function(self,...)bump('Invalidate');return oldInvalidate(self,...)end
 local oldPaint=j.PaintChanged;j.PaintChanged=function(self,...)bump('PaintChanged');return oldPaint(self,...)end
 local oldRecolor=j.Recolor;j.Recolor=function(self,...)bump('Recolor');return oldRecolor(self,...)end
 local function surface(parent,name,x,y,w,h)
  local f=new(parent,{x,y,w,h});f.label=name;f.level=parent:GetFrameLevel()+2
  local bf=new(f,{x,y,w,h});bf.label=name..'.border';bf.level=f.level+10;f.FluxBorderFrame=bf
  local t=b:GetJoinTracks();local top=y+h+t.Top-17;local bottom=y+t.Bottom-16
  local rs={TL={x-t.Left,top,16,17},TR={x+w-t.Right,top,16,17},BL={x-t.Left,bottom,16,16},BR={x+w-t.Right,bottom,16,16},Top={x,top,w,17},Bottom={x,bottom,w,16},Left={x-t.Left,y,16,h},Right={x+w-t.Right,y,16,h}}
  for _,key in ipairs(keys)do local p=new(bf,rs[key],'Texture');p.label=name..'.'..key;bf[key]=p;b:RegisterPiece(p,key)end
  bf.Background=new(bf,{x,y,w,h},'Texture');bf.BackgroundFrame=new(bf,{x,y,w,h});return f
 end
 local frames={}
 for i,unit in ipairs{'player','target','focus','party1','party2','party3','party4'}do
  local x,y=i*310,100
  local root=new(e.UIParent,{x,y,180,88});root.unit=unit;root._FluxBorderStatic=true;root.level=30;e['FluxUnitFrame_'..unit]=root
  local base=surface(root,unit..'.base',x,y,180,88);root.FluxBorderFrame=base.FluxBorderFrame;base.FluxBorderFrame.parent=root
  root.PortraitFrame=surface(root,unit..'.portrait',x-40,y,40,88);root.PortraitFrame.bg=new(root.PortraitFrame,{x-38,y+2,36,84},'Texture')
  root.atlasBorderFrame=surface(root,unit..'.atlas',x-40,y,220,88)
  root.outerBorderFrame=surface(root,unit..'.outer',x-40,y,220,124)
  root.CastBar={IconBorder=surface(root,unit..'.castIcon',x-40,y+88,40,36),BorderFrame=surface(root,unit..'.castBody',x,y+88,180,36)}
  root.ThreatBar=surface(root,unit..'.threat',x+180,y,12,88)
  root._fluxPartyMember=unit:match('^party')~=nil;root._fluxPartyClassChrome=true
  root.UpdateBorderColors=function(self)UF.UpdateBorderColors(self)end
  frames[#frames+1]=root
 end
 assert(load(policies..partyPaint..tint,'@actual-shared-party-paint','t',e))()
 assert(load(read('UnitFrames/FluxUnitFrames_DebuffTint.lua'),'@actual-friendly-dispel-paint','t',e))('_FluxUI',ns)
 if reference then
  local update=UF.UpdateBorderColors
  UF.UpdateBorderColors=function(f)
   -- A deliberate compatibility reference applies ordinary portrait chrome
   -- first, then the actual final producer. The final output must be identical.
   local state=combat[f.unit];combat[f.unit]=false;UF.UpdatePortraitCombatTint(f);combat[f.unit]=state
   update(f)
  end
 end
 for _,f in ipairs(frames)do b:SetClassColor(f.PortraitFrame,1,true);UF.SetupDebuffTint(f);UF.UpdateBorderColors(f)end
 local function later()local list=e._later or{};e._later={};for _,fn in ipairs(list)do fn()end end
 later();flush();later();flush();assert(not j.stats.fallback,j.stats.fallback)
 local function digest()
  local rows={}
  for _,o in ipairs(objects)do if o.objectType=='Texture'and o:IsVisible()then
   local row={o.label or'field',o.path or'',o:GetAlpha()};for _,n in ipairs(o.color or{})do row[#row+1]=n end;for _,n in ipairs(o.uv or{})do row[#row+1]=n end;for _,n in ipairs(o.fill or{})do row[#row+1]=n end
   for i=1,4 do for _,n in ipairs(o.vertices and o.vertices[i]or{})do row[#row+1]=n end end
   for i,n in ipairs(row)do if type(n)=='number'then row[i]=string.format('%.9g',n)end end
   rows[#rows+1]=table.concat(row,',')
  end end
  for _,f in ipairs(frames)do
   for _,s in ipairs{f,f.PortraitFrame,f.atlasBorderFrame,f.outerBorderFrame,f.CastBar.IconBorder,f.CastBar.BorderFrame,f.ThreatBar}do
    local c=s._FluxBorderUnitColor;local opts=s._FluxBorderTintOpts
    rows[#rows+1]=table.concat({s.label or f.unit,tostring(s._FluxBorderNatural),c and c.r or'none',c and c.g or'none',c and c.b or'none',tostring(b._accentFrames[s]),opts and opts.alpha or'none',opts and tostring(opts.tintBackdrop)or'none'},',')
   end
  end
  for t,r in pairs(b._pieces)do local c=r.unitColor;rows[#rows+1]=table.concat({t.label or'piece',r.current or'none',r.art or'none',tostring(r.naturalArt),c and c.r or'none',c and c.g or'none',c and c.b or'none',tostring(r.themed),r.alpha or'none'},',')end
  table.sort(rows);local value=table.concat(rows,';');local hash=0;for i=1,#value do hash=(hash*257+value:byte(i))%2147483647 end;return hash
 end
 local function assertClassification()
  for _,f in ipairs(frames)do
   local pf=f.PortraitFrame;local expected
   if f._fluxPartyMember and f._fluxPartyClassChrome then expected=e.RAID_CLASS_COLORS[classes[f.unit]or'MAGE']
   elseif(f.unit=='target'or f.unit=='focus')and players[f.unit]~=false then expected=e.RAID_CLASS_COLORS[classes[f.unit]or'MAGE']end
   local actual=pf._FluxBorderUnitColor
   check(expected and actual and expected.r==actual.r and expected.g==actual.g and expected.b==actual.b or not expected and not actual,'portrait material classification follows current class/party option/unit')
   check(b._accentFrames[pf]and pf._FluxBorderTintOpts.alpha==1 and pf._FluxBorderTintOpts.tintBackdrop,'constructor accent registration and options survive final portrait paint')
   if enabled and combat[f.unit]then
    local c=pf.FluxBorderFrame.TL.color
    check(c[1]==1 and c[2]==.08 and c[3]==.08,'final combat red remains authoritative after class or settings refresh')
   end
  end
 end
 local function emit(label,fn)
  local before={reads=j.stats.geometryReads or 0,solves=j.stats.solves or 0,passes=j.stats.passes or 0,full=j.stats.fullInvalidations or 0,objects=#objects}
  count={};measuring=true;local start=os.clock();fn();later();flush();local elapsed=(os.clock()-start)*1000;measuring=false
  local row={'TINT',style,enabled and'on'or'off',label,'ms='..elapsed,'solves='..((j.stats.solves or 0)-before.solves),'geometry='..((j.stats.geometryReads or 0)-before.reads),'passes='..((j.stats.passes or 0)-before.passes),'full='..((j.stats.fullInvalidations or 0)-before.full),'alloc='..(#objects-before.objects),'ops='..(j.stats.operations or 0),'triangles='..(j.stats.triangles or 0)}
  assertClassification()
  results[label]={mesh=digest(),counts=count}
  if label=='warm-repeat'or label=='enter-portrait-only'or label=='enter-redundant-full-paint'then
   check(j.stats.solves==before.solves and j.stats.geometryReads==before.reads and #objects==before.objects,'ordinary/red redundant portrait paint retains prepared geometry and resources')
  end
  if not reference and label=='enter-redundant-full-paint'then
   check((count['field.SetVertexColor']or 0)==0 and(count['field.GetAlpha']or 0)==0,'already-final portrait repaint avoids ordinary-to-red derived paint churn')
  end
 end
 emit('warm-repeat',function()for _,f in ipairs(frames)do UF.UpdateBorderColors(f)end end)
 emit('enter-portrait-only',function()lock(true);for _,f in ipairs(frames)do combat[f.unit]=true;UF.UpdatePortraitCombatTint(f)end end)
 emit('enter-redundant-full-paint',function()for _,f in ipairs(frames)do UF.UpdateBorderColors(f)end end)
 for _,mode in ipairs{'class','atlas','custom'}do
  emit('red-mode-'..mode,function()choose(style,mode);e.FluxOptions.db.profile.appearance.customAccent={r=.7,g=.2,b=.4};for _,f in ipairs(frames)do UF.UpdateBorderColors(f)end end)
  emit('red-class-replace-'..mode,function()for _,f in ipairs(frames)do classes[f.unit]='WARRIOR';UF.UpdateBorderColors(f)end end)
  emit('red-party-opt-off-'..mode,function()for _,f in ipairs(frames)do if f._fluxPartyMember then f._fluxPartyClassChrome=false end;UF.UpdateBorderColors(f)end end)
  emit('red-npc-replace-'..mode,function()players.target=false;players.focus=false;for _,f in ipairs(frames)do UF.UpdateBorderColors(f)end end)
  emit('red-party-opt-on-'..mode,function()for _,f in ipairs(frames)do if f._fluxPartyMember then f._fluxPartyClassChrome=true end;UF.UpdateBorderColors(f)end end)
  emit('red-player-replace-'..mode,function()players.target=true;players.focus=true;for _,f in ipairs(frames)do classes[f.unit]='MAGE';UF.UpdateBorderColors(f)end end)
 end
 emit('friendly-dispel',function()debuff='Magic';UF.RefreshDebuffTint()end)
 emit('exit-portrait-only',function()for _,f in ipairs(frames)do combat[f.unit]=false;UF.UpdatePortraitCombatTint(f)end;lock(false)end)
 emit('exit-full-7-surface-paint',function()for _,f in ipairs(frames)do UF.UpdateBorderColors(f)end end)
 emit('dispel-clear',function()debuff=nil;UF.RefreshDebuffTint()end)
 local secret=setmetatable({}, {__eq=function()error('private alpha compared')end,__lt=function()error('private alpha ordered')end,__tostring=function()error('private alpha formatted')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end
 local nativeSource,entry
 for t,r in pairs(b._pieces)do local c=e.junctionExports.clipped[t];if r.staticUnit and c and c.active and #c.pool>0 then nativeSource,entry=t,c;break end end
 check(nativeSource~=nil,'actual prepared static-unit source exercises native private alpha')
 local r,g,bb,a=table.unpack(entry.color);local n,solves,reads=#objects,j.stats.solves,j.stats.geometryReads
 for _=1,3 do nativeSource:SetVertexColor(r,g,bb,secret);flush();for _,t in ipairs(entry.pool)do
  if t._fallbackSource and not t._fallbackEnabled or entry.sourceShown==false then
   check(t.alpha==0,'opaque source alpha cannot revive an owner-blocked or hidden field')
  else check(rawequal(t.alpha,secret),'each opaque source write forwards to prepared native sinks')end
 end end
 nativeSource:SetVertexColor(r,g,bb,a);flush()
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==n,'actual producer mesh keeps private alpha/recovery paint-only')
 return results
end
local stages=0
for _,style in ipairs{1,2}do for _,enabled in ipairs{false,true}do
 local actual,reference=Scene(style,enabled,false),Scene(style,enabled,true)
 for label,row in pairs(actual)do check(reference[label].mesh==row.mesh,'final paint/material/rounded aura and cast output matches ordinary-first reference: '..label);stages=stages+1 end
end end
check(stages==100,'both styles and tint policies cover one hundred class/NPC/default/custom/party/dispel/enter/exit stages')
print('Unit portrait final paint: '..checks..' checks PASS;100 stages; both styles; current material/classification; ordinary-first output parity; no redundant normal-to-red field repaint; private native opacity; actual friendly dispel; native pixels/taint/FPS pending.')

