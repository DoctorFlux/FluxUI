-- Actual Border/Core material ownership, including detached unit shells.
-- Engine primitives are modeled; no native latency, GPU or taint certification.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local bootstrap=read('tests/unit_portrait_overlay_attachment.lua')
bootstrap=bootstrap:sub(1,assert(bootstrap:find('local shared=read(',1,true))-1)
local factory=assert(load(bootstrap..'\nreturn factory','@paint-owner-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function digest(f)
 local rows={}
 for texture,r in pairs(f.B._pieces)do
  local c={texture:GetVertexColor()};local uv={texture:GetTexCoord()}
  rows[#rows+1]=table.concat({texture.label or '',r.art or '',table.concat(c,','),table.concat(uv,','),tostring(r.naturalArt),r.unitColor and tostring(r.unitColor.r)or'-'},'|')
 end
 table.sort(rows);return table.concat(rows,'\n')
end
local function scene(style)
 local f=factory(style,0,.75,false,'');local new,B,e=f.new,f.B,f.e
 f.roots={};f.shells={};f.children={}
 local function Border(frame,label)
  B:ApplyTo(frame)
  for key,t in pairs(frame.FluxBorderFrame)do if B._pieces[t]then t.label=label..'.'..key end end
 end
 for i=1,4 do
  local root=new(e.UIParent);root.unit='party'..i;root._FluxBorderStatic=true;root:SetSize(120,70);root:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',100+i*140,100)
  Border(root,'party'..i);f.roots[i]=root
  local child=new(root);child:SetSize(20,20);child:SetPoint('BOTTOMLEFT',root,'BOTTOMLEFT',0,0);Border(child,'child'..i);f.children[i]=child
  local shell=new(e.UIParent);shell._FluxBorderOwner=root;shell:SetSize(130,80);shell:SetPoint('BOTTOMLEFT',root,'BOTTOMLEFT',0,0);Border(shell,'shell'..i);f.shells[i]=shell
 end
 for i=1,96 do local p=new(e.UIParent);p:SetSize(80,60);p:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',5000+i*100,3000);Border(p,'unrelated'..i)end
 return f
end
for _,style in ipairs{1,2}do
 local current,reference=scene(style),scene(style)
 local function Repaint(f,legacy,fn)
  local old=f.e.hooksecurefunc;if legacy then f.e.hooksecurefunc=nil end
  local calls=0;local parent=f.m.GetParent
  f.m.GetParent=function(self)calls=calls+1;return parent(self)end
  fn(f)
  f.m.GetParent=parent;f.e.hooksecurefunc=old
  return calls
 end
 local colours={{r=.2,g=.6,b=.9},{r=.9,g=.2,b=.4},{r=.3,g=.8,b=.2},{r=.8,g=.5,b=.9}}
 local function first(f)
  for i,root in ipairs(f.roots)do
   f.B:SetUntinted(root,false);f.B:SetUnitColor(root,colours[i])
   f.B:SetUnitColor(f.children[i],colours[i]);f.B:SetUnitColor(f.shells[i],colours[i])
  end
 end
 local localReads,fullReads=Repaint(current,false,first),Repaint(reference,true,first)
 check(digest(current)==digest(reference),'all material/RGBA/UV and detached-owner results match the legacy traversal')
 check(localReads<fullReads/8,'party class transitions do not traverse unrelated HUD pieces')
 print(string.format('PARTY_PAINT_WORK style=%d scopedParentReads=%d legacyParentReads=%d',style,localReads,fullReads))
 if arg[1]=='--work' then
  for trial=1,5 do
   local times={}
   for _,f in ipairs(trial%2==1 and{current,reference}or{reference,current})do
    collectgarbage('collect')
    local start=os.clock()
    local calls=Repaint(f,f==reference,function(x)
     for n=1,20 do for i,root in ipairs(x.roots)do
      local color=colours[(i+n+trial)%4+1]
      x.B:SetUnitColor(root,color);x.B:SetUnitColor(x.children[i],color);x.B:SetUnitColor(x.shells[i],color)
     end end
    end)
    times[f==current and 1 or 2]={(os.clock()-start)*1000,calls}
   end
   print(string.format('PARTY_PAINT_TIME style=%d trial=%d scopedMs=%.3f legacyMs=%.3f scopedReads=%d legacyReads=%d',style,trial,times[1][1],times[2][1],times[1][2],times[2][2]))
  end
 end
 -- Colour changes remain presentation-only in combat; no protected layout/input.
 for _,f in ipairs{current,reference}do
  f.e.InCombatLockdown=function()return true end
  for _,name in ipairs{'SetPoint','ClearAllPoints','SetSize','SetParent','SetAttribute','SetFrameRef'}do
   local old=f.m[name]
   if old then f.m[name]=function()error('protected/layout write during colour: '..name)end end
  end
 end
 local function combat(f)for i,root in ipairs(f.roots)do f.B:SetUnitColor(root,colours[5-i]);f.B:SetUntinted(f.shells[i],true)end end
 Repaint(current,false,combat);Repaint(reference,true,combat)
 check(digest(current)==digest(reference),'combat material paths use the same native colour/texture sinks')
end
-- Existing observer maintenance follows both a texture and an entire subtree.
do
 local f=scene(2);local B,e=f.B,f.e
 local moved=f.children[1];moved:SetParent(f.roots[2]);B:SetUnitColor(f.roots[1],{r=.9,g=.1,b=.1});B:SetUnitColor(f.roots[2],{r=.1,g=.9,b=.1})
 for _,t in pairs(moved.FluxBorderFrame)do local r=B._pieces[t];if r then check(r.unitColor==f.roots[2]._FluxBorderUnitColor,'subtree reparent updates paint owners')end end
 local t=f.children[2].FluxBorderFrame.Top;t:SetParent(f.roots[3]);B:SetUnitColor(f.roots[2],{r=.8,g=.1,b=.1});B:SetUnitColor(f.roots[3],{r=.1,g=.1,b=.9})
 check(B._pieces[t].unitColor==f.roots[3]._FluxBorderUnitColor,'texture reparent updates paint owners')
 local old=B._pieces[f.children[3].FluxBorderFrame.Top];B:RemoveFrom(f.children[3]);B:SetUnitColor(f.roots[3],{r=.8,g=.8,b=.1})
 check(old~=nil,'removed frame had registered paint')
end
print('Border paint ownership: '..checks..' checks PASS; actual scoped/legacy parity; detached shells; reparent; combat presentation only; native acceptance pending.')
