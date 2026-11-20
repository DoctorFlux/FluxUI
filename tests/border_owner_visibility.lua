-- A retained duplicate winner can hide independently of the still-visible
-- unit. Its suppressed lower source must fill the same interval without a solve.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@border-owner-visibility','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function Hit(t,x,y)
 local scale=t:GetParent():GetEffectiveScale()
 local bx,by,bw,bh
 if t.decorative and t.point and t.size then
  bx=t:GetParent():GetLeft()+t.point[4];by=t:GetParent():GetBottom()+t.point[5];bw,bh=table.unpack(t.size)
 else bx,by,bw,bh=t:GetRect()end
 if not bx then return false end
 bx,by,bw,bh=bx*scale,by*scale,bw*scale,bh*scale
 if t._junctionOwnerOp and not t._junctionQuad and t.vertices then
  local function vertex(i,dx,dy)local o=t.vertices[i]or{0,0};return{bx+dx*bw+o[1]*scale,by+dy*bh+o[2]*scale}end
  local a,b,c=vertex(1,0,1),vertex(2,0,0),vertex(3,1,1)
  local function cross(a,b,p)return(b[1]-a[1])*(p[2]-a[2])-(b[2]-a[2])*(p[1]-a[1])end
  local point={x,y};local p,q,r=cross(a,b,point),cross(b,c,point),cross(c,a,point)
  return math.abs(cross(a,b,c))>1e-8 and((p>1e-7 and q>1e-7 and r>1e-7)or(p< -1e-7 and q< -1e-7 and r< -1e-7))
 end
 return x>bx+.0001 and x<bx+bw-.0001 and y>by+.0001 and y<by+bh-.0001
end
for _,style in ipairs{1,2}do for _,partial in ipairs{false,true}do for _,scale in ipairs{.75,1,1.25}do
 local j,new,piece,flush,objects,lock,choose,_,e=fixture();choose(style,'class')
 local root=new(e.UIParent);root.unit='player';root._FluxBorderStatic=true
 local base=new(root);base.scale=scale;base.level=1
 local shell=new(root);shell.scale=scale;shell.level=20;shell._FluxBorderOwner=root
 local lower=piece(base,'Top',{0,-9,200,17});lower:SetTexture('base.tga');lower:SetVertexColor(.2,.4,.6,.7)
 local high=piece(shell,'Top',partial and{40,-9,80,17}or{0,-9,200,17});high:SetTexture('shell.tga');high:SetVertexColor(.8,.5,.1,1)
 flush();check(j.stats.fallback==nil,'parallel duplicate ownership is prepared')
 local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
 local function sample(x,wanted)
  local n,source=0,nil
  for _,t in ipairs(objects)do
   if t:GetObjectType()=='Texture'and t:IsVisible()and t:GetEffectiveAlpha()>0 and(t:GetTexture()=='base.tga'or t:GetTexture()=='shell.tga')then
    if Hit(t,x*scale,-1*scale)then n=n+1;source=t:GetTexture()end
   end
  end
  check(n==1 and source==wanted,'one visible source fills each shared interval after owner transition: '..tostring(source)..' count='..n)
 end
 for _,combat in ipairs{false,true}do
  lock(combat)
  for _=1,8 do
   sample(80,'shell.tga')
   high:Hide();flush();sample(80,'base.tga')
   if partial then sample(20,'base.tga');sample(160,'base.tga')end
   high:Show();flush();sample(80,'shell.tga')
   shell:Hide();flush();sample(80,'base.tga')
   shell:Show();flush();sample(80,'shell.tga')
   shell:SetAlpha(0);flush();sample(80,'base.tga')
   shell:SetAlpha(1);flush();sample(80,'shell.tga')
   high:SetAlpha(0);flush();sample(80,'base.tga')
   high:SetAlpha(1);flush();sample(80,'shell.tga')
  end
 end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'owner paint/visibility fallback reuses prebuilt resources without geometry work, including combat')
end end end
for _,style in ipairs{1,2}do for _,withT in ipairs{false,true}do
 local j,new,piece,flush,objects,lock,choose,_,e=fixture();choose(style,'class')
 local root=new(e.UIParent);root.unit='player';root._FluxBorderStatic=true
 local function box(level,prefix)
  local p=new(root);p.level=level;p._FluxBorderRoundCorners=true
  local r={TL={-9,-13,16,17},TR={189,-13,16,17},BL={-9,-105,16,16},BR={189,-105,16,16},Top={7,-13,182,17},Bottom={7,-105,182,16},Left={-9,-89,16,76},Right={189,-89,16,76}}
  for _,key in ipairs{'TL','TR','BL','BR','Top','Bottom','Left','Right'}do local t=piece(p,key,r[key]);t:SetTexture(prefix..'-'..key)end
  return p
 end
 local base=box(1,'base');local shell=box(20,'shell')
 if withT then local v=piece(root,'Left',{91,-40,16,80});v:SetTexture('stem')end
 flush();local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
 local function sample(x,y,wanted)
  local n,source=0,nil
  for _,t in ipairs(objects)do
   local path=t:GetTexture()
   if t:GetObjectType()=='Texture'and t:IsVisible()and t:GetEffectiveAlpha()>0 and type(path)=='string'and(path:find('base-',1,true)or path:find('shell-',1,true)or path=='stem')and Hit(t,x,y)then n=n+1;source=path end
  end
  check(n==1 and(not wanted or source==wanted),'one visible rounded/T field survives owner visibility: '..tostring(source)..' count='..n)
 end
 for _,combat in ipairs{false,true}do lock(combat)
  for _=1,8 do
   sample(-2,-2,'shell-TL');sample(30,-3,'shell-Top')
   shell:Hide();flush();sample(-2,-2,'base-TL');sample(30,-3,'base-Top')
   if withT then sample(98.1,-3.3)end
   shell:Show();flush();sample(-2,-2,'shell-TL');sample(30,-3,'shell-Top')
  end
 end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'rounded corners and intersecting T reuse prepared source fields in combat')
end end
-- Three overlapping priorities must expose the nearest available source, not
-- skip an intermediary or revive a blocked lower field after author repaint.
for _,style in ipairs{1,2}do
 local j,new,piece,flush,objects,lock,choose,_,e=fixture();choose(style,'class')
 local root=new(e.UIParent);root.unit='focus';root._FluxBorderStatic=true
 local frames,textures={},{ }
 for i,r in ipairs{{0,-9,240,17},{40,-9,140,17},{80,-9,60,17}}do
  local f=new(root);f.level=i*10;frames[i]=f
  local t=piece(f,'Top',r);t:SetTexture('level'..i);t:SetVertexColor(i*.2,.4,.6,1);textures[i]=t
 end
 flush();local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
 local function sample(wanted,red)
  local n,path,color=0
  for _,t in ipairs(objects)do if t:GetObjectType()=='Texture'and t:IsVisible()and t:GetEffectiveAlpha()>0 and t:GetTexture():match('^level')and Hit(t,100,-1)then
   n=n+1;path=t:GetTexture();color=t.color[1]
  end end
  check(n==1 and path==wanted and(not red or color==red),'nearest visible level has one current source/tint; got '..tostring(path)..' count='..n)
 end
 for _,combat in ipairs{false,true}do lock(combat)
  for _=1,8 do
   sample('level3')
   textures[1]:SetVertexColor(.15,.7,.4,.5);textures[1]:SetAlpha(.5);flush();sample('level3')
   frames[3]:Hide();flush();sample('level2')
   textures[3]:SetVertexColor(.9,.2,.1,.8);textures[3]:SetAlpha(.8);flush();sample('level2')
   frames[2]:Hide();flush();sample('level1',.15)
   textures[1]:Hide();textures[1]:SetVertexColor(.25,.5,.8,.7);flush()
   textures[1]:Show();flush();sample('level1',.25)
   frames[2]:Show();flush();sample('level2')
   frames[3]:Show();flush();sample('level3',.9)
  end
 end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'three levels and hidden repaint remain geometry/resource static')
 -- Unit existence/fade belongs to the native unit root. Availability must stop
 -- before reading root visibility/alpha, including an opaque native fade.
 function root:IsShown()error('unit-root shown state must not select a paint owner')end
 function root:GetAlpha()error('unit-root opacity must not select a paint owner')end
 local secret=setmetatable({}, {__eq=function()error('opaque alpha compared')end,__lt=function()error('opaque alpha ordered')end,__tostring=function()error('opaque alpha formatted')end,__mul=function()error('opaque alpha multiplied')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end
 root:Hide();textures[1]:SetVertexColor(.3,.5,.8,.7);textures[3]:Hide();flush()
 root:Show();textures[3]:Show();flush();sample('level3')
 root:SetAlpha(secret);textures[1]:SetAlpha(.7);flush();root:SetAlpha(1);flush();sample('level3')
 -- A source's opaque opacity stays on native SetAlpha sinks; it cannot enable
 -- a lower alias or cause Lua to inspect/arithmetic that value.
 textures[3]:SetAlpha(secret);textures[1]:SetVertexColor(.4,.5,.8,.7);flush()
 textures[3]:SetAlpha(1);flush();sample('level3')
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'native root visibility/opaque fades and source alpha do not rebuild or allocate')
end
-- Ordinary non-unit HUD pieces use the same overlap fields. Recolor must not
-- revive their lower fallback while a higher source is still present.
for _,style in ipairs{1,2}do
 local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,'class')
 local lowerHost=new(e.UIParent);lowerHost.level=1
 local upperHost=new(e.UIParent);upperHost.level=20
 local lower=piece(lowerHost,'Top',{0,-9,200,17});lower:SetTexture('hud-low')
 local upper=piece(upperHost,'Top',{40,-9,80,17});upper:SetTexture('hud-high');flush()
 local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
 lower:SetVertexColor(.2,.5,.8,.6);flush()
 local n=0
 for _,t in ipairs(objects)do if t:GetObjectType()=='Texture'and t:IsVisible()and t:GetEffectiveAlpha()>0 and t:GetTexture():match('^hud%-')and Hit(t,80,-1)then n=n+1 end end
 check(n==1,'non-unit lower recolor cannot reveal an owner-blocked fallback')
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'non-unit public recolor keeps prepared topology')
end
-- Anchor observers can be installed before the referenced texture is adopted.
-- A later scalar paint must reapply fallback gating regardless of hook order.
do
 local exposed=prefix:gsub('return B%.Junctions,new,piece','e.TestBorder=B;return B.Junctions,new,piece')
 local watchedFixture=assert(load(exposed..'\nreturn fixture','@owner-watch-order','t',_G))()
 for _,style in ipairs{1,2}do
  local j,new,piece,flush,objects,lock,choose,_,e=watchedFixture();choose(style,'class')
  local root=new(e.UIParent);root.unit='target';root._FluxBorderStatic=true
  local base=new(root);base.level=1;local upper=new(root);upper.level=20
  local lower=new(base,{0,-9,200,17},'Texture')
  piece(base,'Left',{41,-40,16,80},{{'CENTER',lower,'CENTER',0,0}})
  local record={key='Top'};e.TestBorder._pieces[lower]=record;j:Adopt(lower,record);lower:SetTexture('order-low')
  local high=piece(upper,'Top',{0,-9,200,17});high:SetTexture('order-high');flush()
  local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
  lock(true);lower:SetAlpha(.8);flush()
  local n=0
  for _,t in ipairs(objects)do if t:GetObjectType()=='Texture'and t:IsVisible()and t:GetEffectiveAlpha()>0 and t:GetTexture():match('^order%-')and Hit(t,80,-1)then n=n+1 end end
  check(n==1,'anchor-before-adoption hook order cannot revive an owner-blocked field')
  check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'watch-order-safe alpha remains paint-only in combat')
 end
end
-- Getter work during one source's paint is independent of unrelated registered
-- sources: dispatch must use its prepared local field list, not the registry.
do
 local function workload(extra)
  local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(2,'class')
  local root=new(e.UIParent);root.unit='focus';root._FluxBorderStatic=true
  local lowHost=new(root);lowHost.level=1;local highHost=new(root);highHost.level=20
  local lower=piece(lowHost,'Top',{0,-9,200,17});piece(highHost,'Top',{40,-9,80,17})
  for i=1,extra do local other=new(e.UIParent);other.unit='party'..i;other._FluxBorderStatic=true;piece(other,'Top',{10000+i*200,-9,100,17})end
  flush();local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
  local metric=0;local m=getmetatable(root).__index
  for _,name in ipairs{'GetParent','IsShown','GetAlpha'}do local original=m[name];m[name]=function(...)metric=metric+1;return original(...)end end
  for i=1,16 do lower:SetVertexColor(.2+i*.01,.4,.7,.8)end
  check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'local paint dispatch performs no geometry/resources')
  return metric
 end
 local small,large=workload(0),workload(100)
 check(small==large,'adding100 unrelated sources does not increase per-source availability getter work: '..small..'/'..large)
end
print('Border owner visibility: '..checks..' checks PASS; own source/host hide and public alpha-zero; whole/partial overlap; both styles/scales; one source per interval; zero solves/reads/allocations including combat; native pixels/taint pending')
