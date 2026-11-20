-- Run the actual current solver against its string-key reference or an exact
-- archived source passed with --parallel-intervals. Both use
-- identical producer-captured input objects; snapshot baseline outputs before
-- the candidate resets mutable ownership fields. No native performance claim.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function replace(s,a,b)local p=assert(s:find(a,1,true),a);assert(not s:find(a,p+#a,true),'ambiguous '..a);return s:sub(1,p-1)..b..s:sub(p+#a)end
local archived=arg[2]=='--parallel-intervals' and arg[1]
local candidate=read((not archived and arg[1]) or 'Core/BorderJunctions.lua')
local base=archived and read(archived) or candidate
if not archived then
base=replace(base,[=[                local seenA=parallelSeen[a]
                if not seenA then seenA={};parallelSeen[a]=seenA end
                if not seenA[b] then
                    seenA[b]=true]=],[=[                local key=min(a.id,b.id)..":"..max(a.id,b.id)
                if not parallelSeen[key] then
                    parallelSeen[key]=true]=])
base=replace(base,[=[                local seenH=seen[h]
                if not seenH then seenH={};seen[h]=seenH end
                if not seenH[v] then
                    seenH[v]=true]=],[=[                local key=h.id..":"..v.id
                if not seen[key] then
                    seen[key]=true]=])
end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local function fixture(code)
 local text,n=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return string.format('%q',code)end);assert(n==1)
 return assert(load(text..'\nreturn fixture','@solve-pair-fixture','t',_G))()()
end
local function scene(code,kind,style)
 local j,new,piece,flush,objects,_,choose,_,e=fixture(code);choose(style,'class')
 local nextLabel=0
 local function edge(parent,key,rect)local t=piece(parent,key,rect);nextLabel=nextLabel+1;t.label='texture'..nextLabel;return t end
 local moving
 if kind=='connected' then
  local root=new(e.UIParent);edge(root,'Top',{0,-9,3400,17})
  for i=1,8 do for k=1,7 do local t=edge(root,'Left',{i*400+k*26-9,-40,16,80});if i==1 and k==7 then moving=t end end end
 else
  local n=kind=='hud20' and 20 or 8
  for i=1,n do
   local root=new(e.UIParent);local x=i*360
   edge(root,'Top',{x,-9,320,17});local high=new(root);high.level=10;edge(high,'Top',{x,-9,320,17})
   for k=1,6 do local t=edge(root,'Left',{x+k*41-9,-40,16,80});if i==1 and k==6 then moving=t end end
   local unit=new(e.UIParent);unit.unit=i==1 and 'player' or i==2 and 'target' or 'party'..i;unit._FluxBorderStatic=true
   edge(unit,'Top',{x,110,300,17});edge(unit,'Bottom',{x,10,300,17});edge(unit,'Left',{x-9,27,16,83});edge(unit,'Right',{x+291,27,16,83})
   for _,r in ipairs{{'TL',x-9,110},{'TR',x+291,110},{'BL',x-9,10},{'BR',x+291,10}}do edge(unit,r[1],{r[2],r[3],16,17})end
   edge(unit,'Top',{x,60,300,17})
  end
 end
 local solve=j.Solve;local segments
 j.Solve=function(_,s)segments=s;return {}end;flush();j.Solve=solve
 assert(segments and #segments>0)
 local labels={}
 for _,s in ipairs(segments)do labels[s]='S:'..s.texture.label;labels[s.texture]='T:'..s.texture.label;labels[s.group]='G:'..s.group.id end
 local items={};local seen={}
 for _,s in ipairs(segments)do for _,item in ipairs(s.group.pieces or {})do if not seen[item] then
  seen[item]=true;items[#items+1]=item;labels[item]='I:'..item.texture.label;labels[item.texture]='T:'..item.texture.label
 end end end
 local result={j=j,segments=segments,items=items,labels=labels,moving=moving,kind=kind,style=style}
 return result
end
local function encode(value,labels,key)
 local t=type(value)
 if t=='number' then return string.format('%.17g',value)end
 if t=='string' then return string.format('%q',value)end
 if t~='table' then return tostring(value)end
 if labels[value] then return labels[value]end
 local rows={}
 if key=='protectedRects' or key=='roundCaps' or key=='corners' then
  for _,v in ipairs(value)do rows[#rows+1]=encode(v,labels)end;table.sort(rows);return '{'..table.concat(rows,',')..'}'
 end
 for k,v in pairs(value)do rows[#rows+1]=encode(k,labels)..'='..encode(v,labels,k)end
 table.sort(rows);return '{'..table.concat(rows,',')..'}'
end
local function clean(t)
 for _,item in ipairs(t.items)do item.availabilityCuts=nil end
end
local function execute(t)
 clean(t)
 local ops,reason=t.j:Solve(t.segments)
 return ops,reason
end
local function signature(t,ops,reason)
 local rows={'reason='..tostring(reason),'candidates='..tostring(t.j.stats.candidates),'ops='..encode(ops,t.labels)}
 for _,s in ipairs(t.segments)do rows[#rows+1]=t.labels[s]..'='..encode({p=s.p,rawP=s.rawP,weldOffset=s.weldOffset,paintCuts=s.paintCuts,id=s.id},t.labels)end
 for _,item in ipairs(t.items)do rows[#rows+1]=t.labels[item]..'='..encode(item.availabilityCuts,t.labels)end
 table.sort(rows);return table.concat(rows,'\n')
end
local checks=0
local function check(ok,msg)checks=checks+1;assert(ok,msg)end
local function equivalent(a,b,why)
 local ao,ar=execute(a);local ad=signature(a,ao,ar)
 local bo,br=execute(b);local bd=signature(b,bo,br)
 check(ad==bd,why)
 return ao,ar
end
local function twin(a,code)
 -- Use identical actual captured objects, IDs and input order. Comparing two
 -- separately collected scenes would introduce unrelated weak-table traversal
 -- order differences before Solve. Snapshot the baseline BEFORE its twin runs.
 return {j=fixture(code),segments=a.segments,items=a.items,labels=a.labels,moving=a.moving,kind=a.kind,style=a.style}
end
local scenes={}
for _,kind in ipairs{'connected','hud8','hud20'}do for _,style in ipairs{1,2}do
 local a=scene(base,kind,style);local b=twin(a,candidate)
 equivalent(a,b,kind..' initial all operation fields, memberships, caps, source cuts')
 -- Work on the same source identities: misses cannot survive this layout change.
 for _,delta in ipairs{11,-11,0,.125,-.125,64,-64}do
  for _,s in ipairs(a.segments)do if s.texture==a.moving then
   s.p=s.p+delta;s.rect[1]=s.rect[1]+delta;s.rect[3]=s.rect[3]+delta
  end end
  equivalent(a,b,kind..' changed source with retained identity '..delta)
 end
 scenes[kind..':'..style]={a,b}
end end
local function synthetic(code,seed)
 local j=fixture(code);local groups,segments,items,labels={},{},{},{}
 for i=1,5 do local g={id=i,plane=i==5 and 'WINDOW' or 'HUD',priority=(seed+i)%4,pieces={},
  fixedBounds=(seed+i)%11==0,unitOwner=(seed+i)%4==0 and 'party'..(i%2) or nil,
  actionStrip=(seed+i)%7==0,parent={_FluxBorderAuraPanel=(seed+i)%13==0,_FluxBorderRoundCorners=(seed+i)%13==0,
   _FluxBorderCastInternalSide=(seed+i)%17==0 and 'Right' or nil}}
  groups[i]=g;labels[g]='G:'..i
 end
 local function add(axis,p,a,b,g,side)
  local s={axis=axis,p=p,a=a,b=b,group=g,side=side,scale=({.75,1,1.25,2.5})[(seed+#segments)%4+1]}
  s.rect=axis=='H' and {a,p-8,b,p+9} or {p-9,a,p+7,b}
  local texture={label='synthetic'..(#segments+1)};labels[texture]='T:'..texture.label
  local item={texture=texture,rect=s.rect,record={key=side}};g.pieces[#g.pieces+1]=item;items[#items+1]=item;s.item=item;s.texture=texture
  labels[s]='S:'..texture.label;labels[item]='I:'..texture.label;segments[#segments+1]=s
 end
 for i=1,18 do local g=groups[(i+seed)%#groups+1]
  local axis=i%2==0 and 'H' or 'V';local p=((i*37+seed*13)%127)-62;local a=((i*11+seed)%61)-90;local b=a+80+(i*3)%70
  add(axis,p,a,b,g,axis=='H' and (i%3==0 and 'Bottom' or 'Top') or (i%3==0 and 'Right' or 'Left'))
 end
 for i,g in ipairs(groups)do for _,key in ipairs{'TL','TR','BL','BR'}do
  local x=(seed+i*9)%35-17;local y=(seed+i*7)%47-23
  local item={texture={label='cap'..i..key},rect={x-8,y-8,x+8,y+9},record={key=key},cornerX=x,cornerY=y}
  g.pieces[#g.pieces+1]=item;items[#items+1]=item;labels[item]='I:cap'..i..key;labels[item.texture]='T:cap'..i..key
 end end
 return {j=j,segments=segments,items=items,labels=labels}
end
for seed=1,120 do
 local a=synthetic(base,seed);equivalent(a,twin(a,candidate),'adversarial priority/unit/plane/cap/cast/aura/scale case '..seed)
end
do
 local a={j=fixture(base),segments={},items={},labels={}}
 local function item(g,key,rect)
  local label='piece'..(#a.items+1)
  local p={texture={},rect=rect,record={key=key}}
  g.pieces[#g.pieces+1]=p;a.items[#a.items+1]=p
  a.labels[p],a.labels[p.texture]='I:'..label,'T:'..label
  return p
 end
 local function outline(id,priority)
  local g={id=id,plane='HUD',priority=priority,pieces={}}
  local edge=item(g,'Top',{0,-8,60,9})
  local segment={axis='H',side='Top',group=g,rect=edge.rect,item=edge,texture=edge.texture,p=0,a=0,b=60,scale=1}
  a.labels[g],a.labels[segment]='G:'..id,'S:'..id
  a.segments[#a.segments+1]=segment
  return g
 end
 local lower,higher=outline(1,5),outline(2,6)
 local cap=item(lower,'TL',{-8,-8,8,9})
 local first=item(higher,'TL',{-8,-8,8,9})
 local second=item(higher,'TL',{-7.5,-8,8.5,9})
 item(higher,'TL',{-6,-8,10,9})
 local ops=equivalent(a,twin(a,candidate),'coincident caps preserve every owner in original order')
 local cuts=cap.availabilityCuts
 check(#ops==1 and #ops[1].corners==2 and #cuts==2
  and cuts[1].owner==first.texture and cuts[2].owner==second.texture,'only coincident duplicate caps enter the visibility backup')
end
for _,limit in ipairs{{'segments',1},{'candidates',5},{'bucketEntries',10},{'operations',0}}do
 local a=scene(base,'hud8',2);local b=twin(a,candidate)
 a.j.limits[limit[1]]=limit[2];b.j.limits[limit[1]]=limit[2]
 local _,why=equivalent(a,b,'exact '..limit[1]..' budget behavior');check(why~=nil,'budget actually crossed '..limit[1])
end
-- Negative controls are checked with the same complete signature; no acceptance
-- claim based solely on operation counts or sorted rectangle coverage.
local controls={
 {'numeric',function(s)return replace(s,'node.fullRect={unpack(node.rect)}','node.rect[1]=node.rect[1]+.125;node.fullRect={unpack(node.rect)}')end},
 {'membership',function(s)return replace(s,'node.members[originalH.group]=true;node.members[originalV.group]=true','node.members[originalV.group]=true')end},
 {'caps',function(s)return replace(s,'node.protectedCaps[item]=true','node.protectedCaps[item]=nil')end},
 {'budget',function(s)return replace(s,'if candidates>self.limits.candidates then self.stats.candidates=candidates;return nil,"candidate budget" end\n                local seenA=','if candidates>=self.limits.candidates then self.stats.candidates=candidates;return nil,"candidate budget" end\n                local seenA=')end},
}
for _,entry in ipairs(controls)do
 local rejected=false
 do
  local a=scene(base,'hud8',2);local b=twin(a,entry[2](candidate))
  if entry[1]=='budget' then a.j.limits.candidates=1;b.j.limits.candidates=1 end
  local ao,ar=execute(a);local ad=signature(a,ao,ar);local bo,br=execute(b)
  rejected=ad~=signature(b,bo,br)
 end
 for seed=1,30 do
  if rejected then break end
  local a=synthetic(base,seed);local b=twin(a,entry[2](candidate))
  if entry[1]=='budget' then a.j.limits.candidates=1;b.j.limits.candidates=1 end
  local ao,ar=execute(a);local ad=signature(a,ao,ar);local bo,br=execute(b)
  if ad~=signature(b,bo,br)then rejected=true;break end
 end
 check(rejected,'meaningful negative control rejected '..entry[1]);print('CONTROL|'..entry[1]..'|REJECTED')
end
do
 local a=synthetic(base,1)
 local s1,s2=a.segments[1],a.segments[2]
 for i,s in ipairs{s1,s2}do
  s.axis='H';s.side='Top';s.p=i==1 and 0 or 12;s.a=0;s.b=100;s.scale=1
  s.rect={0,s.p-8,100,s.p+9};s.item.rect=s.rect
  s.group={id=i,plane='HUD',pieces={s.item}};a.labels[s.group]='G:negative'..i
 end
 a.segments={s1,s2};a.items={s1.item,s2.item}
 local unsafe=replace(candidate,'    local parallelSeen,pairsToPaint={},{}','    self._unsafeSeen=self._unsafeSeen or {}\n    local parallelSeen,pairsToPaint=self._unsafeSeen,{}')
 local b=twin(a,unsafe)
 local ao,ar=execute(a);local ad=signature(a,ao,ar);local bo,br=execute(b)
 check(ad==signature(b,bo,br),'unsafe miss-cache control starts equivalent with rejected pair')
 s2.p=1;s2.rect={0,-7,100,10};s2.item.rect=s2.rect
 ao,ar=execute(a);ad=signature(a,ao,ar);bo,br=execute(b)
 check(ad~=signature(b,bo,br),'persistent miss cache rejected when original source identities become valid')
 print('CONTROL|persistent-miss|REJECTED')
end
print('Border pair identity: '..checks..' checks PASS; exact complete operations/source mutations; per-pass ownership/caps/budgets; stale-miss controls; native performance/pixels/taint pending')
