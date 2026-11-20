-- Actual Init/Watch/Hosts cursor callback/Layout/Strip boundary replay.
-- The control source removes only the optional same-hash argument, restoring
-- the old forced Strip writer. Native performance/pixels/taint remain pending.
-- Optional paths are the exact previous Layout.lua and Strip.lua.
local prior={["Bars/Layout.lua"]=arg[1],["Bars/Strip.lua"]=arg[2]}
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s:gsub('\r\n','\n')end
local prefix=assert(read('tests/bars_refresh_regression.lua'):match('^(.-)local function pageRefresh%('))
local oldarg=arg;arg={[0]='tests/bars_refresh_regression.lua'}
local factory=assert(load(prefix..'\nreturn fixture','@bars-strip-work-fixture','t',_G))();arg=oldarg
local function fixture(candidate)
 local f=factory();local B,e,flux=f.B,f.env,f.flux
 local queue,counts={},{};local function count(k)counts[k]=(counts[k]or 0)+1 end
 local originalLoad=f.load
 f.load=function(path)
  local code=read(not candidate and prior[path] or path)
  if not candidate and not prior[path] and path=='Bars/Layout.lua'then
   local pattern='(Bars%.Strip%.Layout%(visibleCols, anyMini or expanding, expanding, extraScale, xFactor), true[^)]*%)'
   local count
   code,count=code:gsub(pattern,'%1)',1)
   assert(count==1,'same-hash optional argument remains testable')
   code=code:gsub('function Layout.Apply%(hoverOnly, slotLayout%)','function Layout.Apply(hoverOnly)',1)
     :gsub("return false, stripChanged","return false",1)
     :gsub(", checkExistingStrip, deferUnitAnchors%)",", nil, deferUnitAnchors)",1)
  end
  assert(load(code,'@actual-'..path,'t',e))('_FluxUI',{Flux=flux})
 end
 local hosts=B.hosts;e.SlashCmdList={};flux.Module={Register=function()end};f.load('Bars/Init.lua');B.hosts=hosts;B.started=true;B.secureReady=true
 flux.Scheduler={Request=function(tier,token,fn)count('request.'..tier);if fn then queue[tier..':'..token]=fn end end}
 local mt={}
 local function widget(name,parent)local o=setmetatable({name=name,parent=parent,width=1,height=1,scale=1,shown=true,points={},attributes={}}, {__index=mt});return o end
 function mt:ClearAllPoints()count('native.clear');self.points={}end
 function mt:SetPoint(...)count('native.point');self.points[#self.points+1]={...}end
 function mt:SetSize(w,h)count('native.size');self.width,self.height=w,h end
 function mt:SetScale(s)count('native.scale');self.scale=s end
 function mt:SetAlpha(a)count('native.alpha');self.alpha=a end
 function mt:Show()count('native.show');self.shown=true end
 function mt:Hide()count('native.hide');self.shown=false end
 function mt:IsShown()return self.shown end
 function mt:IsVisible()return self.shown end
 function mt:GetParent()return self.parent end
 function mt:GetWidth()count('get.width');return self.width end
 function mt:GetHeight()count('get.height');return self.height end
 function mt:GetScale()count('get.scale');return self.scale end
 function mt:GetNumPoints()count('get.points');return #self.points end
 function mt:GetPoint(i)count('get.point');return table.unpack(self.points[i]or{})end
 function mt:IsMouseOver()return f.hover end
 function mt:GetAttribute(k)return self.attributes[k]end
 function mt:SetAttribute(k,v)assert(not f.combat,'no protected writes in combat');count('mappingWrites');self.attributes[k]=v end
 e.UIParent=widget('UIParent');e.GetCursorInfo=function()return f.cursor end
 e.FluxUnitFrames_ApplyPlayerStatusBarLayout=function(anchorsOnly)count('playerLayout');if anchorsOnly then count('scopedUnits')end end
 e.FluxUILayoutSqueeze={NotifyLayoutDependents=function(_, settleStrip)count('dependents');if settleStrip then count('scopedDependents')end end}
 e.FluxUnifiedBorder={UpdateBorder=function()count('envelope')end}
 e.FluxBorder={Junctions={CommitLayout=function()count('commit')end}}
 B.Hosts.ApplyChrome=function(reuse)count('chrome');if reuse then count('scopedChrome')end end;B.Hosts.RefreshKeys=function()count('keys')end
 B.Blizzard.Reassert=function()count('stockSweep')end
 B.State.GetSecondarySlot=function(c)return c<=12 and c+60 or c+36 end
 B.State.GetTertiarySlot=function(c)return c<=12 and c+24 or c+24 end
 B.State.GetMinirowPosition=function()return f.bottom and'bottom'or'top'end
 B.Watch.InvalidateColumnStamps=function()count('columnStamps')end
 f.occupied={};for i=1,14 do f.occupied[i]=100+i end;for i=61,65 do f.occupied[i]=100+i end
 flux.Action.HasAction=function(slot)return f.occupied[slot]~=nil end
 B.Hosts.ForSlot=function(slot)local out={};B.ForEachHost(function(h)if h.slot==slot then out[#out+1]=h end end);return out end
 f.load('Bars/Strip.lua');local strip=B.Strip
 strip.frame=widget('strip',e.UIParent);strip.inner=widget('inner',strip.frame);strip.sensing=widget('sensing',e.UIParent)
 for c=1,19 do for _,r in ipairs{'main','sec','tert'}do
  local h=B.hosts[c][r];h.slot=r=='main'and c or r=='sec'and B.State.GetSecondarySlot(c)or B.State.GetTertiarySlot(c)
  h.widget=widget(c..r,strip.inner);h.widget._fluxHost=h
 end end
 f.load('Bars/Layout.lua');B.Layout.Start()
 local hostsCode=read('Bars/Hosts.lua')
 local first=assert(hostsCode:find('local function CurrentSlot(widget)',1,true))
 local last=assert(hostsCode:find('\nlocal hoverWidget',first,true))
 local currentSlot=hostsCode:sub(first,last-1)
 first=assert(hostsCode:find('local function AfterCursorChange(',1,true))
 last=assert(hostsCode:find('\n\twidget:SetScript("OnDragStart"',first,true))
 f.afterCursor=assert(load('local Bars,Hosts=...\n'..currentSlot..'\n'..hostsCode:sub(first,last-1)..'\nreturn AfterCursorChange','@actual-host-cursor-change','t',e))(B,B.Hosts)
 function f.drain()
  for _=1,20 do f.advance(0);local run=queue;queue={};if next(run)==nil then break end
   local keys={};for k in pairs(run)do keys[#keys+1]=k end;table.sort(keys);for _,k in ipairs(keys)do run[k]()end
  end
  assert(next(queue)==nil,'layout work terminates')
 end
 function f.reset()counts={};f.applies=0 end
 function f.signature()
  local rows={};local function frame(o)
   if not o then rows[#rows+1]='missing';return end
   local p=o.points[1]or{};rows[#rows+1]=table.concat({o.name,o.width,o.height,o.scale,tostring(o.shown),p[1]or'',type(p[2])=='table'and p[2].name or tostring(p[2]),p[3]or'',p[4]or'',p[5]or'',tostring(o._fluxParked)},':')
  end
  frame(strip.frame);frame(strip.inner);frame(strip.sensing);B.ForEachHost(function(h)frame(h.widget);rows[#rows+1]=h.column..h.row..'='..h.slot
   for _,k in ipairs{'flux-promoted','flux-has-sec','flux-has-tert'}do rows[#rows+1]=tostring(h.widget.attributes[k])end end)
  return table.concat(rows,';')
 end
 f.counts=function()return counts end
 B.Layout.Apply();f.drain();f.reset()
 return f
end
local candidate=true;local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function run(which,change)
 local f=fixture(which);change(f);f.drain();return f.signature(),f.counts(),f.applies
end
local cases={
 {'occupied-swap',function(f)f.occupied[1],f.occupied[2]=f.occupied[2],f.occupied[1];f.emit('ACTIONBAR_SLOT_CHANGED',1);f.emit('ACTIONBAR_SLOT_CHANGED',2)end},
 {'actual-host-occupied-swap',function(f)f.occupied[1],f.occupied[2]=f.occupied[2],f.occupied[1];f.afterCursor(f.B.hosts[1].main.widget,1);f.afterCursor(f.B.hosts[2].main.widget,2);f.emit('ACTIONBAR_SLOT_CHANGED',1);f.emit('ACTIONBAR_SLOT_CHANGED',2)end},
 {'real-column-growth',function(f)f.occupied[15]=115;f.emit('ACTIONBAR_SLOT_CHANGED',15)end},
 {'mini-moved-within-shell',function(f)f.occupied[63]=nil;f.occupied[67]=167;f.emit('ACTIONBAR_SLOT_CHANGED',63);f.emit('ACTIONBAR_SLOT_CHANGED',67)end},
 {'duplicate-cursor-requests',function(f)for _=1,10 do f.B.Layout.Request('cursor')end end},
 {'expand-collapse',function(f)f.cursor='spell';f.hover=true;f.B.Layout.OnCursor();f.drain();f.cursor=nil;f.B.Layout.OnCursor()end},
 {'external-point-change',function(f)f.B.Strip.frame:SetPoint('BOTTOM',f.env.UIParent,'BOTTOM',13,2);f.reset();f.B.Layout.Request('slot')end},
 {'button-size-change',function(f)f.B.CONFIG.buttonSize=46;f.B.Layout.Request('slot')end},
 {'configured-scale-change',function(f)f.B.CONFIG.scale=.83;f.B.Layout.Request('slot')end},
 {'configured-padding-change',function(f)f.B.CONFIG.padding=2;f.B.Layout.Request('slot')end},
 {'inner-scale-change',function(f)f.B.Strip.inner.scale=.4;f.B.Layout.Request('slot')end},
 {'no-sensing-frame',function(f)f.B.Strip.sensing=nil;f.B.Layout.Request('slot')end},
}
for _,case in ipairs(cases)do
 local a,ac,ap=run(nil,case[2]);local b,bc,bp=run(candidate,case[2])
 local repaired=case[1]=='external-point-change' or case[1]=='button-size-change'
     or case[1]=='configured-scale-change' or case[1]=='configured-padding-change' or case[1]=='inner-scale-change'
 check(a==b,case[1]..' preserves exact57host geometry/visibility/mapping/slot signature')
 check(ap==bp,case[1]..' preserves ForceApply cadence')
 for _,k in ipairs{'commit','dependents','chrome','envelope','keys','stockSweep','mappingWrites','columnStamps'}do
  if not repaired or (k~='commit' and k~='dependents' and k~='envelope') then
   check((ac[k]or 0)==(bc[k]or 0),case[1]..' preserves '..k)
  end
 end
 if case[1]=='occupied-swap'or case[1]=='actual-host-occupied-swap'or case[1]=='duplicate-cursor-requests'then
  local control=prior["Bars/Layout.lua"] and 0 or 1
  check((ac.playerLayout or 0)==control and not bc.playerLayout,'unchanged decorative pass skips player reanchor')
  check((ac['native.clear']or 0)==3*control and not bc['native.clear'],'unchanged decorative pass avoids redundant clears')
  check((ac['native.point']or 0)==3*control and not bc['native.point'],'unchanged decorative pass avoids redundant anchors')
  check((ac['native.size']or 0)==3*control and not bc['native.size'],'unchanged decorative pass avoids redundant sizes')
  check((bc['get.point']or 0)==3 and (bc['get.width']or 0)==3,'skipped pass pays fresh current public geometry reads')
  if case[1]=='actual-host-occupied-swap'then check(bc.mappingWrites==18 and bp==1,'actual host cursor callback restamps both touched columns with one secure ForceApply')end
 elseif case[1]=='real-column-growth'then
  check(bc.commit==1 and bc.dependents==1,'real new column commits once after dependents')
  check(bc.scopedDependents==1 and bc.envelope==1 and bc.scopedChrome==1 and bc.scopedUnits==1,
      'a settled slot resize uses the guarded strip paths')
 elseif repaired then
  check(bc.commit==1 and bc.envelope==1 and bc.dependents==1 and not bc.chrome,
      'real shell repair settles adjoining panels and the border before leaving the transaction')
 elseif case[1]=='mini-moved-within-shell'then
  check((ac.playerLayout or 0)==(prior["Bars/Layout.lua"] and 0 or 1) and bc.scopedUnits==1,
      'moving a mini checks existing unit anchors without a full layout')
  check(bc.commit==1 and bc.chrome==1,'the moved slot still updates its chrome and border')
  print(("STRIP_INTERNAL clears %d -> %d; points %d -> %d; player layout %d -> %d")
     :format(ac['native.clear'] or 0,bc['native.clear'] or 0,ac['native.point'] or 0,bc['native.point'] or 0,
      ac.playerLayout or 0,bc.playerLayout or 0))
 elseif case[1]=='no-sensing-frame'then check(not bc.playerLayout,'optional absent sensing does not force decorative work')
 else check(bc.playerLayout==ac.playerLayout,'real changed or mismatched geometry retains full callback')end
end
for _,kind in ipairs{'private-width','private-point','private-relative','private-scale','private-point-count','denied-getter','missing-getter','nan-width','infinite-width','string-width'}do
 local function change(f)
  local secret=setmetatable({}, {__eq=function()error('opaque compared')end,__sub=function()error('opaque arithmetic')end,__index=function()error('opaque indexed')end})
  f.env.issecretvalue=function(v)return rawequal(v,secret)end
  local o=f.B.Strip.frame
  if kind=='private-width'then o.GetWidth=function()return secret end
  elseif kind=='private-scale'then o.GetScale=function()return secret end
  elseif kind=='private-point-count'then o.GetNumPoints=function()return secret end
  elseif kind=='private-point'then o.GetPoint=function()return secret,f.env.UIParent,'BOTTOM',0,2 end
  elseif kind=='private-relative'then o.GetPoint=function()return 'BOTTOM',secret,'BOTTOM',0,2 end
  elseif kind=='denied-getter'then o.GetWidth=function()error('native getter denied')end
  elseif kind=='missing-getter'then o.GetWidth=false end
  if kind=='nan-width'then o.GetWidth=function()return 0/0 end
  elseif kind=='infinite-width'then o.GetWidth=function()return math.huge end
  elseif kind=='string-width'then o.GetWidth=function()return 'width'end end
  f.B.Layout.Request('slot')
 end
 local a,ac,ap=run(nil,change);local b,bc,bp=run(candidate,change)
 check(a==b,kind..' conservatively preserves exact old writer output')
 check(bc.playerLayout==1 and bc['native.clear']==3,kind..' unknown getter retains forced path')
end
local a,ac=run(nil,function(f)local o=f.B.Strip.frame;o.GetWidth=function()return o.width+1/32768 end;f.B.Layout.Request('slot')end)
local b,bc=run(candidate,function(f)local o=f.B.Strip.frame;o.GetWidth=function()return o.width+1/32768 end;f.B.Layout.Request('slot')end)
check(a==b and (ac.playerLayout or 0)==(prior["Bars/Layout.lua"] and 0 or 1) and not bc.playerLayout,
    'sub-1/1024 native float noise preserves exact stored geometry and avoids redundant writers')
local f=fixture(candidate);f.B.Strip.Layout(14,true,false,1,1)
check(f.counts().playerLayout==1 and f.counts()['native.clear']==3,'direct/options-style callers remain forced without changedOnly')
f=fixture(candidate);f.combat=true;f.B.RequestLayout('slot');f.drain()
check(not f.counts()['native.point'] and not f.counts().playerLayout and f.pending['bars.layout'],'combat still defers before all structural work')
f=fixture(candidate)
f.occupied[15]=115;f.emit('ACTIONBAR_SLOT_CHANGED',15);f.B.RequestLayout('options');f.drain()
local mixed=f.counts()
check(mixed.commit==1 and mixed.dependents==1 and mixed.chrome==1 and not mixed.scopedDependents and not mixed.scopedChrome,
    'a coalesced options change still takes the full layout path')
f.reset();f.occupied[15]=nil;f.emit('ACTIONBAR_SLOT_CHANGED',15);f.drain()
check(f.counts().scopedDependents==1 and f.counts().envelope==1 and f.counts().commit==1,
    'the next slot removal again settles only the strip-owned geometry')
print('Bars same-occupancy decorative controls: '..checks..' PASS; exact geometry/slots/mappings; real growth and expansion; current public/private/denied reads; forced direct calls; combat deferral')
