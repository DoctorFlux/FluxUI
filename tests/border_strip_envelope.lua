-- Actual Strip, FluxBorder factory, UnifiedBorder anchor producer and Core.
-- Engine primitive anchor/render methods are modeled. No native pixel/FPS claim.
local corePath=arg[1]or'Core/BorderJunctions.lua'
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local sideSource=read(os.getenv('FLUX_MINIMAP_EXTRA_SOURCE') or 'Minimap/FluxMinimapButtons.lua')
local hoverStart=assert(sideSource:find('local function PointerInside(',1,true))
local hoverEnd=assert(sideSource:find('local function ApplyVisibility(',hoverStart,true))
local hoverCode=[[
local containerFrame, visibilityFrame, sideBorderHost = ...
local buttonWidgets = {}
local InCombat = InCombatLockdown
local UsesMouseover = function() return true end
local Engine = function() end
local function UIUnits(frame, method)
 return frame[method](frame) * frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
end
]]..sideSource:sub(hoverStart,hoverEnd-1)..'\nreturn UpdateMouseover'
local prefix=assert(read('tests/border_types.lua'):match('^(.-)for _, forever in ipairs'))
prefix=prefix:gsub('return env, env.FluxBorder, appearance, object, function%(%) return #objects,writes,queries end','return env, env.FluxBorder, appearance, object, function() return #objects,writes,queries end,objects',1)
local model=assert(load(prefix..'\nreturn model','@strip-envelope-factory-model','t',_G))()
local factor={TOPLEFT={0,1},TOPRIGHT={1,1},BOTTOMLEFT={0,0},BOTTOMRIGHT={1,0},TOP={.5,1},BOTTOM={.5,0},LEFT={0,.5},RIGHT={1,.5},CENTER={.5,.5}}
local function json(v)
 if type(v)=='table'then local out={};for _,x in ipairs(v)do out[#out+1]=json(x)end;return'['..table.concat(out,',')..']'end
 if type(v)=='string'then return string.format('%q',v):gsub('\\\n','\\n')end
 if type(v)=='boolean'then return v and'true'or'false'end;return tostring(v or 0)
end
local function fixture(style,cols,scale,mini,mode,coreOverride)
 local activeCorePath=coreOverride or corePath
 mode=mode or ''
 local e,B,db,new,counts,objects=model(true,'none');db.borderType=style;db.borderAccent='atlas'
 local m=getmetatable(e.UIParent).__index;local queue={};e.SlashCmdList={};e.UIParent.rect={0,0,1920,1080};e.UIParent.scale=scale
 function m:GetEffectiveScale()return(self.scale or 1)*(self.parent and self.parent:GetEffectiveScale()or 1)end
 function m:SetScale(v)self.scale=v end
 function m:ClearAllPoints()self.points={};self.allPoints=nil end
 function m:SetPoint(...)local p={...};for i,old in ipairs(self.points)do if old[1]==p[1]then self.points[i]=p;return end end;self.points[#self.points+1]=p end
 function m:SetAllPoints(p)self.allPoints=p or self.parent;self.points={}end
 function m:GetNumPoints()return #self.points end
 function m:GetPoint(i)return table.unpack(self.points[i]or{})end
 function m:GetRect()
  if self.rect then return table.unpack(self.rect)end
  if self.allPoints then local x,y,w,h=self.allPoints:GetRect();local q=self.allPoints:GetEffectiveScale()/self:GetEffectiveScale();return x*q,y*q,w*q,h*q end
  if #self.points==0 then return 0,0,self.width or 0,self.height or 0 end
  local xs,ys={},{};for _,p in ipairs(self.points)do local r=p[2]or self.parent;local x,y,w,h=r:GetRect();local q=r:GetEffectiveScale()/self:GetEffectiveScale();local a,b=factor[p[1]],factor[p[3]or p[1]];xs[#xs+1]={a[1],(x+b[1]*w)*q+(p[4]or 0)};ys[#ys+1]={a[2],(y+b[2]*h)*q+(p[5]or 0)}end
  local function axis(c,size)local a=c[1];for i=2,#c do if c[i][1]~=a[1]then size=(c[i][2]-a[2])/(c[i][1]-a[1]);break end end;size=size or 0;return a[2]-a[1]*size,size end
  local x,w=axis(xs,self.width);local y,h=axis(ys,self.height);return x,y,w,h
 end
 function m:GetLeft()return self:GetRect()end;function m:GetBottom()local _,y=self:GetRect();return y end
 function m:GetRight()local x,_,w=self:GetRect();return x+w end;function m:GetTop()local _,y,_,h=self:GetRect();return y+h end
 function m:GetWidth()local _,_,w=self:GetRect();return w end;function m:GetHeight()local _,_,_,h=self:GetRect();return h end
 function m:GetAlpha()return self.alpha or 1 end;function m:SetAlpha(v)self.alpha=v end
 function m:GetEffectiveAlpha()return self:GetAlpha()*(self.parent and self.parent:GetEffectiveAlpha()or 1)end
 function m:SetVertexColor(r,g,b,a)self.color={r,g,b,a or 1};self.alpha=a or 1 end
 function m:IsShown()return self.shown end;function m:IsVisible()return self.shown and(not self.parent or self.parent:IsVisible())end
 function m:GetObjectType()return self.objectType or'Frame'end
 function m:CreateTexture()local t=new(self);t.objectType='Texture';return t end
 function m:HasScript(k)return self:GetObjectType()~='Texture'and(k=='OnShow'or k=='OnHide'or k=='OnSizeChanged')end
 function m:HookScript(k,fn)assert(self:HasScript(k));local old=self[k];self[k]=function(...)if old then old(...)end;fn(...)end end
 function m:GetDrawLayer()return self.layer or'OVERLAY',self.sublevel or 7 end
 function m:SetDrawLayer(a,b)self.layer,self.sublevel=a,b end
 function m:SetVertexOffset(i,x,y)self.vertices=self.vertices or{};self.vertices[i]={x,y}end
 function m:SetSnapToPixelGrid()end;function m:SetTexelSnappingBias()end;function m:SetClampedToScreen()end
 local show,hide=m.Show,m.Hide
 function m:Show()local changed=not self.shown;show(self);if changed and self.OnShow then self:OnShow()end end
 function m:Hide()local changed=self.shown;hide(self);if changed and self.OnHide then self:OnHide()end end
 e.CreateFrame=function(_,name,parent)local f=new(parent or e.UIParent);if name then e[name]=f end;return f end
 e.hooksecurefunc=function(o,k,fn)local old=assert(o[k]);o[k]=function(self,...)local out={old(self,...)};fn(self,...);return table.unpack(out)end end
 e.InCombatLockdown=function()return false end;e.GetCursorInfo=function()return nil end;e.MouseIsOver=function()return false end
 e.Flux.Scheduler={Request=function(_,_,fn)queue[#queue+1]=fn end};e.Flux.Combat={InLockdown=function()return false end}
 assert(load(read(activeCorePath),'@actual-strip-envelope-Core','t',e))('_FluxUI',{Border=B})
 for _,o in ipairs(objects)do if o.OnEvent then o:OnEvent('PLAYER_ENTERING_WORLD')end end
 local init=read('Bars/Init.lua');init=init:sub(1,assert(init:find('local function InLockdown()',1,true))-1)
 assert(load(init,'@actual-bars-config','t',e))('_FluxUI',{Flux=e.Flux})
 assert(load(read('Bars/Strip.lua'),'@actual-strip','t',e))('_FluxUI',{Flux=e.Flux})
 local S=e.Flux.Bars.Strip;e.Flux.Bars.secureReady=true;S.Create();S.Layout(cols,mini,false,1,1)
 local x,y,w,h=S.frame:GetRect()
 local grid=new(e.UIParent);grid.rect={x-100,y,100,h};grid.level=5;B:ApplyTo(grid,-4,-4,-4,-4)
 if mode=='distant'then grid.rect[4]=h+30 end
 e.FluxNonCombatAPI={DefaultGrid={Frame=grid}}
 local trinket=new(e.UIParent);trinket.rect={x+w,y,52,h};trinket.level=5;B:ApplyTo(trinket,-4,-4,-4,-4);e.FluxTrinketMenu={Frame=trinket};e.FluxTrinketMenuFrame=trinket
 local u=read('Layout/UnifiedBorder.lua');local p=u:sub(1,assert(u:find('-- Get anchor points for StatusBar/MicroMenu',1,true))-1)
 local ca=assert(u:find('local function RefreshBorderArrows()',1,true));local cb=assert(u:find('local function CreateStatusBarBorderFrame()',ca,true))
 local ua=assert(u:find('local lastBorderLayoutHash',1,true));local ub=assert(u:find('--- Unified micro+status chrome',ua,true))
 e.UpdateActionStripInfoGapBackdrop=function()end;e.UpdateGapBackdrop=function()end
 local setup=assert(load(p..u:sub(ca,cb-1)..u:sub(ua,ub-1)..'\nreturn function()CreateBorderFrame();UpdateBorder();return borderFrame end','@actual-unified-envelope','t',e))()
 local envelope=setup()
 if mode=='hidden'then envelope:Hide()end
 if mode=='detached'then envelope.rect={x+w+400,y,100,h}end
 local rootBounds={S.frame:GetRect()};local track=B:GetJoinTracks()
 local beforeTop=S.frame.FluxBorderFrame.Top:GetTop()*scale-track.Top*scale
 local function flush()local n=0;while #queue>0 do n=n+1;assert(n<30,'bounded queue');local q=queue;queue={};for _,fn in ipairs(q)do fn()end end end
 flush()
 local solves,reads,count=B.Junctions.stats.solves,B.Junctions.stats.geometryReads,#objects
 for _=1,5 do B.Junctions:Flush()end
 assert(B.Junctions.stats.solves==solves and B.Junctions.stats.geometryReads==reads and #objects==count,'settled crest remains static')
 local stripTop=S.frame.FluxBorderFrame.Top:GetTop()*scale-track.Top*scale
 local envTop=envelope.FluxBorderFrame.Top:GetTop()*scale-track.Top*scale
 assert(table.concat(rootBounds,',')==table.concat({S.frame:GetRect()},','),'decorative fitting must not move strip root')
 local function readFields()
 local fields={};for _,t in ipairs(objects)do if t:GetObjectType()=='Texture'and t:IsVisible()and t:GetEffectiveAlpha()>0 and t.texture then
  local px,py,pw,ph=t:GetRect();local es=t:GetEffectiveScale();local uv=t.uv or{0,1,0,1};if #uv==4 then uv={uv[1],uv[3],uv[1],uv[4],uv[2],uv[3],uv[2],uv[4]}end
  local offsets={};for i=1,4 do local v=t.vertices and t.vertices[i]or{0,0};offsets[i]={v[1]*es,v[2]*es}end
  fields[#fields+1]={t.texture,{px*es,py*es,pw*es,ph*es},uv,offsets,t:GetEffectiveAlpha(),t:GetParent():GetFrameLevel()}
 end end
 return fields end
 local record={style,cols,scale,mini,beforeTop,stripTop,envTop,B.Junctions.stats.operations,B.Junctions.stats.fragments,B.Junctions.stats.triangles,readFields(),{x*scale,y*scale,w*scale,h*scale}}
 return {record=record,env=e,e=e,B=B,Border=B,Strip=S,objects=objects,new=new,methods=m,flush=flush,envelope=envelope,grid=grid,trinket=trinket,readFields=readFields}
end
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local images={}
local function image(path)
 local old=images[path];if old then return old end
 local localPath=path:gsub('Interface\\AddOns\\_FluxUI\\',''):gsub('\\','/')
 local f=assert(io.open(localPath,'rb'));local data=f:read('*a');f:close()
 local function word(i)local a,b=data:byte(i,i+1);return a+256*b end
 local id,cmap,kind=data:byte(1,3);local w,h=word(13),word(15);local depth,descriptor=data:byte(17,18)
 check(cmap==0 and kind==2 and depth==32,'canonical artwork uses the expected raw32-bit TGA source')
 old={w=w,h=h,descriptor=descriptor,data=data,start=19+id};images[path]=old;return old
end
local function sample(t,x,y)
 local path,box,uv,offset,alpha=t[1],t[2],t[3],t[4],t[5];local bx,by,w,h=table.unpack(box)
 if not w or not h then return 0 end
 local p={{bx+offset[1][1],by+h+offset[1][2]},{bx+offset[2][1],by+offset[2][2]},
  {bx+w+offset[3][1],by+h+offset[3][2]},{bx+w+offset[4][1],by+offset[4][2]}}
 for _,ids in ipairs{{1,2,3},{3,2,4}}do
  local a,b,c=p[ids[1]],p[ids[2]],p[ids[3]];local den=(b[2]-c[2])*(a[1]-c[1])+(c[1]-b[1])*(a[2]-c[2])
  if math.abs(den)>1e-10 then
   local q=((b[2]-c[2])*(x-c[1])+(c[1]-b[1])*(y-c[2]))/den
   local r=((c[2]-a[2])*(x-c[1])+(a[1]-c[1])*(y-c[2]))/den;local s=1-q-r
   if math.min(q,r,s)>=-1e-8 then
    local u=q*uv[2*ids[1]-1]+r*uv[2*ids[2]-1]+s*uv[2*ids[3]-1]
    local v=q*uv[2*ids[1]]+r*uv[2*ids[2]]+s*uv[2*ids[3]]
    local im=image(path);local fx,fy=u*im.w-.5,v*im.h-.5;local ix,iy=math.floor(fx),math.floor(fy);local dx,dy=fx-math.floor(fx),fy-math.floor(fy)
    local function pixel(cx,cy)
     cx=math.max(0,math.min(im.w-1,cx));cy=math.max(0,math.min(im.h-1,cy))
     if math.floor(im.descriptor/32)%2==0 then cy=im.h-1-cy end
     if math.floor(im.descriptor/16)%2==1 then cx=im.w-1-cx end
     return im.data:byte(im.start+(cy*im.w+cx)*4+3)/255
    end
    return alpha*((1-dy)*((1-dx)*pixel(ix,iy)+dx*pixel(ix+1,iy))+dy*((1-dx)*pixel(ix,iy+1)+dx*pixel(ix+1,iy+1)))
   end
  end
 end
 return 0
end
local function coverage(row,x,y)
 local n,alpha=0,0
 for _,field in ipairs(row[11])do local value=sample(field,x,y);alpha=math.max(alpha,value);if value>1/255 then n=n+1 end end
 return alpha,n
end
local scenes,crest=0,0
for _,style in ipairs{1,2}do for _,cols in ipairs{8,16,19}do for _,scale in ipairs{.75,1,1.25}do for _,mini in ipairs{false,true}do
 local f=fixture(style,cols,scale,mini,'');local row=f.record;scenes=scenes+1
 check(math.abs(row[7]-row[6])<1e-7,'packed strip and containing envelope must have the same final top stroke')
 local x,y,w,h=table.unpack(row[12]);local top=row[6]
 for i=-48,48 do
  local yy=top+i*scale/4
  local inside=coverage(row,x+w/2,yy);local outside=coverage(row,x-50*scale,yy)
  check(math.abs(inside-outside)<1e-7,'final horizontal profiles use continuous canonical-art sampling')
 end
 for _,edge in ipairs{x,x+w}do for _,offset in ipairs{-32,-24,-16,-8,-4,-2,-1,0,1,2,4,8,16,24,32}do
  local alpha,n=coverage(row,edge+(offset+.137)*scale,top+.173*scale);crest=crest+1
  check(alpha>.5,'final crest stays filled at a packed endpoint/T')
  check(n==1,'final crest has one painted source at a packed endpoint/T')
 end end
end end end end
for _,mode in ipairs{'hidden','distant','detached'}do for _,style in ipairs{1,2}do for _,cols in ipairs{8,16,19}do for _,scale in ipairs{.75,1,1.25}do for _,mini in ipairs{false,true}do
 local f=fixture(style,cols,scale,mini,mode);local row=f.record;scenes=scenes+1
 if mode=='hidden'then check(not f.envelope:IsVisible(),'hidden envelope is excluded from the nearby crest owner')
 elseif mode=='distant'then check(math.abs(row[7]-row[6])>9*scale,'distant envelope retains its separate top')
 else check(f.envelope:GetLeft()>f.Strip.frame:GetRight()+100,'detached envelope keeps its complete separate position')end
end end end end end
for _,style in ipairs{1,2}do for _,scale in ipairs{.75,1,1.25}do for _,sideScale in ipairs{.085,.2,.425,.85,1.7}do
 local f=fixture(style,19,scale,false,'detached')
 local e,B,new=f.e,f.B,f.new
 local window=new(e.UIParent);window.level=10;window.rect={1500,110,420,270}
 e.FluxWindowFrame={frame=window}
 local root=new(e.UIParent);root.scale=sideScale
 root.rect={1920/sideScale-88,380/sideScale,88,240}
 function root:SetShown(shown) if shown then self:Show() else self:Hide() end end
 local gate=new(root);gate.level=sideScale==.425 and 46 or 26;gate:SetAllPoints(root)
 e.FluxMinimapButtonsVisibility=gate
 local side=new(gate);side.level=gate.level
 side:SetAllPoints(gate)
 e.FluxMinimapButtonsSideBorder=side
 B:ApplyTo(window);B:ApplyTo(side)
 local wb,sb=window.FluxBorderFrame,side.FluxBorderFrame
 wb._FluxBorderOwnLayer=true;wb:SetFrameLevel(12)
 sb._FluxBorderOwnLayer=true;sb:SetFrameLevel(gate.level+3)
 local adjacentBorder
 if sideScale==.425 then
  local adjacent=new(e.UIParent);adjacent.level=6;adjacent.rect={1840,380,80-88*sideScale,106}
  e.Minimap=adjacent;adjacentBorder=B:ApplyTo(adjacent)
 end
 local J=B.Junctions
 local track=B:GetJoinTracks()
 local function sideBottom() return (sb.Bottom:GetTop()-track.Bottom)*sideScale*scale end
 local function windowTop() return (wb.Top:GetTop()-track.Top)*scale end
 local originalBottom=sideBottom()
 local button=new(gate);button.level=gate.level+2
 local arrowFloor=J.GetArrowBorderLevel and J:GetArrowBorderLevel(button,'MEDIUM',button.level)
 local refreshes=0
 e.Flux.Flyout={Arrow={RefreshArtLayers=function() refreshes=refreshes+1 end}}
 J:Invalidate(true);f.flush()
 check(math.abs(sideBottom()-windowTop())<1e-7,'the docked side and Flux Window strokes must meet at unequal scales')
 local windowFields,sideFields,adjacentFields=0,0,0
 for _,field in ipairs(f.objects)do
  local source=field._junctionSource and field._junctionSource:GetParent()
  if field._junctionOwnerOp and (source==wb or source==sb)then
   check(field:GetParent()==source,'joined panel artwork keeps its own source frame layer')
   if source==wb then windowFields=windowFields+1 else sideFields=sideFields+1 end
  elseif field._junctionOwnerOp and source and source==adjacentBorder then
   adjacentFields=adjacentFields+1
   check(field:GetParent():GetFrameLevel()==adjacentBorder:GetFrameLevel()+1,
    'a neighboring minimap joint does not inherit the side input level')
  end
 end
 check(windowFields>0 and sideFields>0,'the dock produces artwork from both panels')
 if adjacentBorder then check(adjacentFields>0,'the neighboring minimap shares the junction')end
 check(J:GetArrowBorderLevel(button,'MEDIUM',button.level)==arrowFloor,
  'the shared seam preserves the side glyph floor')
 local stripButton=new(f.Strip.frame)
 local foreign=new(e.UIParent);foreign.rect={1400,0,500,500};foreign.strata='HIGH';foreign.level=500
 check(J:GetArrowBorderLevel(stripButton,'MEDIUM',8)<500,'an ordinary arrow only samples its own stratum and HUD chrome')
 check(side:GetBottom()==380/sideScale and window:GetTop()==380,'dock fitting leaves both content frames in place')
 local row={[11]=f.readFields()}
 local alpha,n=coverage(row,(1920-44*sideScale)*scale,windowTop()+.13*scale)
 check(alpha>.8 and n==1,'midway along the dock the seam paints one stroke')
 local leftAlpha=coverage(row,(1920-88*sideScale)*scale,windowTop()+.13*scale)
 check(leftAlpha>.55,'the shared crossbar remains continuous across the left T')
 local solves=J.stats.solves
 local published=refreshes
 for _=1,4 do J:Flush() end
 check(solves==J.stats.solves and published==refreshes,'settled docking and glyph layers stay idle')
 root:Hide();f.flush()
 check(math.abs(sideBottom()-originalBottom)<1e-7,'hiding the side grid restores its nominal stroke for reuse')
 local cursorInside=true
 e.GetCursorPosition=function()
  if cursorInside then return (1920-44*sideScale)*scale,(380+120*sideScale)*scale end
  return 0,0
 end
 local hover=assert(load(hoverCode,'@actual side grid mouseover','t',e))(root,gate,side)
 local fullRequests=J.stats.fullInvalidations
 hover()
 check(root:IsShown() and math.abs(sideBottom()-windowTop())<1e-7,
  'mouseover reveal commits the side seam before the queued border pass')
 row={[11]=f.readFields()}
 alpha,n=coverage(row,(1920-44*sideScale)*scale,windowTop()+.13*scale)
 check(alpha>.8 and n==1,'revealing the grid paints one stroke on the first visible pass')
 local visibleSolves=J.stats.solves
 hover();hover();f.flush()
 check(visibleSolves==J.stats.solves,'stationary mouseover performs no additional solve')
 cursorInside=false;hover()
 check(not root:IsShown() and math.abs(sideBottom()-originalBottom)<1e-7,
  'mouseout immediately restores the independent outline')
 cursorInside=true;hover()
 check(J.stats.fullInvalidations==fullRequests,'hover transitions stay local to the side grid')
 root.rect[2]=root.rect[2]+36/sideScale
 J:Invalidate(true);f.flush()
 check(sideBottom()-windowTop()>35*scale,'a detached side grid keeps its own bottom outline')
 check(J:GetArrowBorderLevel(button,'MEDIUM',button.level)==arrowFloor,'detached arrows retain their own panel border level')

 -- Below-map mode touches the bottom of the minimap with the top of the grid.
 local map=e.Minimap or new(e.UIParent)
 e.Minimap=map
 root.rect[2]=380/sideScale
 map.rect={1720,380+240*sideScale,200,190}
 local mb=adjacentBorder or B:ApplyTo(map)
 root:Hide();J:Invalidate(true);f.flush()
 local function mapBottom() return (mb.Bottom:GetTop()-track.Bottom)*scale end
 local standaloneBottom=mapBottom()
 hover()
 local sideTop=(sb.Top:GetTop()-track.Top)*sideScale*scale
 check(math.abs(sideTop-mapBottom())<1e-7,'the first revealed side crest meets the minimap bottom')
 check(math.abs(standaloneBottom-mapBottom())<1e-7,'revealing the side grid holds the minimap bottom in place')
 row={[11]=f.readFields()}
 alpha,n=coverage(row,(1920-44*sideScale)*scale,mapBottom()+.13*scale)
 check(alpha>.55 and n==1,'the first revealed frame paints one stroke below the minimap')
 local leftAlpha=coverage(row,(1920-88*sideScale)*scale,mapBottom()+.13*scale)
 check(leftAlpha>.55,'the first revealed frame has a continuous crest at the minimap T')
 if sideScale==.425 then
  local before=J.stats.solves
  for _=1,5 do
   cursorInside=false;hover()
   check(not root:IsShown() and math.abs(standaloneBottom-mapBottom())<1e-7,'leaving hover keeps the standalone minimap rim')
   cursorInside=true;hover()
   check(root:IsShown() and math.abs(standaloneBottom-mapBottom())<1e-7,'returning to hover keeps the same minimap rim')
  end
  f.flush()
  check(J.stats.solves<=before+10,'each hover crossing commits at most one solve')
 end
end end end
print('Strip/envelope border: '..checks..' checks PASS; '..scenes..' strip scenes; 30 side/window dock scenes; '..crest..' one-source crest samples; static warm checks; native pixels/FPS/taint pending')
