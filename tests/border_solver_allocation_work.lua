-- Actual current solver versus COMPLETE frozen R57 Solve support. Identical
-- producer objects, full operation/source/budget/foreign-callback signatures.
-- Shared helpers are current by design; their independent semantics are outside
-- this oracle. Args: [Core path] [legacy support path] [--verbose]. No native or
-- CPU claim. Prospective R58 safe elisions only; installation requires fitness.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function replace(s,a,b)local p=assert(s:find(a,1,true),a);assert(not s:find(a,p+#a,true),'ambiguous '..a);return s:sub(1,p-1)..b..s:sub(p+#a)end
local candidate=read(arg[1]or'Core/BorderJunctions.lua')
-- This oracle isolates the frozen/current solver and their complete legacy
-- consumer. Regional dispatch intentionally changes native query/resource
-- counts; its actual consumer parity is covered by border_locality.lua.
candidate=candidate:gsub("if Spatial.Try%(segments,signature,","if false and Spatial.Try(segments,signature,")
local legacySupport=read(arg[2]or'tests/support/border_solver_legacy_r57.txt')
local verbose=arg[3]=='--verbose'
assert(legacySupport:find('Parent normalized SHA256:244413aac79c8f8ab04e55cadd6c1eb22cf08efc32de2d27917b096f804798df',1,true),'wrong frozen legacy solver support')
local method='function J:Solve(segments)'
local afterMethod='\n-- Restore only our opacity suppression.'
local legacyAt=assert(legacySupport:find(method,1,true),'complete frozen Solve body required')
local solverAt=assert(candidate:find(method,1,true),'current Solve entry required')
local solverEnd=assert(candidate:find(afterMethod,solverAt,true),'current Solve boundary required')
-- Replace the ENTIRE method from immutable support, never a reverse-patch of
-- a specific optimization. Other current helpers remain shared intentionally.
local base=candidate:sub(1,solverAt-1)..legacySupport:sub(legacyAt)..candidate:sub(solverEnd)
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local function loadenv(s,n,m,e)
 if _VERSION=="Lua 5.1"then local f,err=loadstring(s,n);if f then setfenv(f,e)end;return f,err end
 return load(s,n,m,e)
end
local compatTable={};for k,v in pairs(table)do compatTable[k]=v end;compatTable.unpack=table.unpack or unpack
local function fixtureGlobals()
 local e=setmetatable({load=loadenv,table=compatTable},{__index=_G});e._G=e;return e
end
local function fixture(code)
 local text,n=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return string.format('%q',code)end);assert(n==1)
 local j,n,p,f,o,l,c,q,e=assert(loadenv(text..'\nreturn fixture','@solve-pair-fixture','t',fixtureGlobals()))()();j._pointFixtureEnv=e;return j,n,p,f,o,l,c,q,e
end
local function scene(code,kind,style,fullConsumer)
 local j,new,piece,flush,objects,_,choose,_,e=fixture(code);choose(style,'class')
 local nativeCounts={}
 if fullConsumer then
  for _,name in ipairs{'issecretvalue','issecrettable','canaccesstable'}do
   e[name]=function()nativeCounts[name]=(nativeCounts[name]or 0)+1;return name=='canaccesstable'end
  end
  local m=getmetatable(e.UIParent).__index
  for _,name in ipairs{'GetParent','GetRect','GetEffectiveScale','GetLeft','GetBottom','GetAlpha','GetEffectiveAlpha','GetDrawLayer','GetVertexColor','GetTexture','GetTexCoord','IsVisible','IsShown'}do
   local original=m[name]
   m[name]=function(self,...)nativeCounts[name]=(nativeCounts[name]or 0)+1;return original(self,...)end
  end
 end
 local nextLabel=0
 local function edge(parent,key,rect)local t=piece(parent,key,rect);nextLabel=nextLabel+1;t.label='texture'..nextLabel;return t end
 local moving
 if kind=='connected' then
  local root=new(e.UIParent);edge(root,'Top',{0,-9,3400,17})
  for i=1,8 do for k=1,7 do local t=edge(root,'Left',{i*400+k*26-9,-40,16,80});if i==1 and k==7 then moving=t end end end
 else
  local n=kind=='hud20' and 20 or kind=='hud1' and 1 or 8
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
 if fullConsumer then
  j._pointWork={};flush()
  local fields={objects=#objects,textures=0,rendered=0}
  for _,object in ipairs(objects)do
   if object.objectType=='Texture'then fields.textures=fields.textures+1 end
   -- Read only fixture-owned stored fields; do not add modeled native getters
   -- to the exact native/permission-query counters under comparison.
   if object.decorative and object.size and object.point and object.shown and(object.alpha or 1)>0 then fields.rendered=fields.rendered+1 end
  end
  return {j=j,objects=objects,e=e,work=j._pointWork,native=nativeCounts,fields=fields,kind=kind,style=style}
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

local unpack=table.unpack or unpack
local function instrument(s,kind)
 local function patch(a,b)s=replace(s,a,b)end
 patch('    local bucketEntries=0\n',[[    local bucketEntries=0
    local pointWork=self._pointWork
    local function Work(k,n)if pointWork then pointWork[k]=(pointWork[k]or 0)+(n or 1)end end
    Work("solves")
]])
 patch('        s.id=i;s.rawP=s.p;s.paintCuts={};s.weldOffset=0','        s.id=i;s.rawP=s.p;s.paintCuts={};s.weldOffset=0;Work("segments")')
 patch('                        local node\n','                        local node\n                        Work("searches")\n')
 patch('                                local bucket=nodes[h.group.plane..":"..(bx+dx)..":"..(by+dy)]',[[                                Work("probes");Work("keys")
                                local bucket=nodes[h.group.plane..":"..(bx+dx)..":"..(by+dy)]
                                if not bucket then Work("emptyBuckets")]]..(kind=='baseline'and';Work("emptyTables")'or'')..'end')
 local loop=kind=='baseline'and'                                for _,n in ipairs(bucket or {}) do'or'                                if bucket then for _,n in ipairs(bucket) do'
 patch(loop,loop..'\n                                    Work("nodeComparisons")')
 patch('                        if not node then\n                            node=','                        if not node then\n                            Work("nodes")\n                            node=')
 patch('                            local nk=h.group.plane..":"..bx..":"..by','                            Work("keys")\n                            local nk=h.group.plane..":"..bx..":"..by\n                            if not nodes[nk]then Work("buckets")end')
 if kind=='baseline'then
  patch('        for _,axis in ipairs({bin.H,bin.V}) do','        Work("axisArrays")\n        for _,axis in ipairs({bin.H,bin.V}) do')
  patch('                for _,other in ipairs(patches[key] or {}) do','                Work("patchProbes");if not patches[key]then Work("patchEmptyTables")end\n                for _,other in ipairs(patches[key] or {}) do')
 else
  patch('        local bh,bv=bin.H,bin.V','        Work("axisPrefetchPairs")\n        local bh,bv=bin.H,bin.V')
  patch('                local patchBucket=patches[key]','                Work("patchProbes")\n                local patchBucket=patches[key]')
 end
 return s
end
local baselineInstrumented=instrument(base,'baseline')
local candidateInstrumented=instrument(candidate,'candidate')
local function val(t,k)return t[k]or 0 end
local function workLine(label,kind,style,t)
 if not verbose then return end
 local parts={'POINTWORK',label,kind,tostring(style)}
 for _,k in ipairs{'solves','segments','admissionSegments','searches','probes','keys','emptyBuckets','emptyTables','planeMaps','columnMaps','buckets','nodes','nodeComparisons','axisArrays','axisPrefetchPairs','patchProbes','patchEmptyTables'}do parts[#parts+1]=k..'='..val(t,k)end
 parts[#parts+1]='numeric='..tostring(t.numeric);print(table.concat(parts,'|'))
end
-- These complete consumers exercise the real ReadLayout -> Solve -> plan ->
-- commit path. Independent fixture instances establish work, not a same-object
-- renderer rewind. Strict solver parity above replays identical producer objects.
for _,kind in ipairs{'connected','hud1','hud8','hud20'}do for _,style in ipairs{1,2}do
 local a=scene(baselineInstrumented,kind,style,true)
 local b=scene(candidateInstrumented,kind,style,true)
 check(a.j.stats.fallback==nil and b.j.stats.fallback==nil,'whole '..kind..' both full consumers build real mesh')
 check((a.j.stats.triangles or 0)>0 and (b.j.stats.triangles or 0)>0,'whole consumers retain actual triangle work')
 check(a.work.probes==a.work.searches*9 and b.work.probes==b.work.searches*9,'all9logical neighbor probes retained')
 check(val(b.work,'keys')==val(a.work,'keys')and val(b.work,'emptyTables')==0 and val(b.work,'patchEmptyTables')==0,'all old string keys remain; both empty-table allocations removed')
 check(val(b.work,'axisArrays')==0 and val(b.work,'axisPrefetchPairs')==val(a.work,'axisArrays'),'private axis prefetch keeps both arrays without tuple allocation')
 workLine('baseline',kind,style,a.work);workLine('candidate',kind,style,b.work)
 local ak,bk={},{};for k,v in pairs(a.native)do ak[#ak+1]=k..'='..v end;for k,v in pairs(b.native)do bk[#bk+1]=k..'='..v end;table.sort(ak);table.sort(bk)
 check(table.concat(ak,',')==table.concat(bk,','),'all current native/permission queries retained '..kind..style)
 check(a.fields.objects==b.fields.objects and a.fields.textures==b.fields.textures and a.fields.rendered==b.fields.rendered,'complete consumer field/resource counts retained '..kind..style)
 if verbose then
  print('NATIVECOUNTS|'..kind..'|'..style..'|baseline|'..table.concat(ak,','))
  print('NATIVECOUNTS|'..kind..'|'..style..'|candidate|'..table.concat(bk,','))
  print('FIELDCOUNTS|'..kind..'|'..style..'|'..a.fields.objects..'|'..a.fields.textures..'|'..a.fields.rendered)
 end
end end
-- Frozen explicit baseline also proves the counting observers themselves do not
-- alter complete operation/source mutations on exactly the same objects.
for _,kind in ipairs{'connected','hud8','hud20'}do for _,style in ipairs{1,2}do
 local a=scene(base,kind,style)
 equivalent(a,twin(a,baselineInstrumented),'baseline observer-neutral complete solve '..kind..style)
 equivalent(a,twin(a,candidateInstrumented),'candidate observer complete solve '..kind..style)
end end
local function guardCase(kind,code)
 local j=fixture(code);local gs,segments,items,labels={},{},{},{}
 local log={};local function note(s)log[#log+1]=s end
 for i=1,4 do gs[i]={id=i,plane='HUD',priority=i,pieces={}};labels[gs[i]]='G:'..i end
 local function add(axis,p,a,b,g,label)
  local texture={};local item={texture=texture,record={key=axis=='H'and'Top'or'Left'}}
  local s={axis=axis,p=p,a=a,b=b,group=g,side=item.record.key,scale=1,texture=texture,item=item}
  s.rect=axis=='H'and{a,p-8,b,p+9}or{p-9,a,p+7,b};item.rect=s.rect
  segments[#segments+1]=s;items[#items+1]=item;g.pieces[#g.pieces+1]=item
  labels[s]='S:'..label;labels[texture]='T:'..label;labels[item]='I:'..label
  return s
 end
 local tReset
 local p=0
 if kind=='upper-fast'then p=1000000 elseif kind=='lower-fast'then p=-1000000
 elseif kind=='upper-fallback'then p=1000000.125 elseif kind=='lower-fallback'then p=-1000000.125
 elseif kind=='large-rounded-cell'then p=2^54 elseif kind=='large-rounded-cell2'then p=2^55
 elseif kind=='negative-zero'then p=-1/math.huge elseif kind=='positive-zero'then p=0
 elseif kind=='secret-rawp'then p=13
 elseif kind=='nan'then p=0/0 elseif kind=='positive-infinity'then p=math.huge elseif kind=='negative-infinity'then p=-math.huge end
 local extent=(p==p and p~=math.huge and p~=-math.huge)and p or 0
 local h=add('H',p,extent-40,extent+40,gs[1],'H')
 local v=add('V',p,extent-40,extent+40,gs[2],'V')
 if kind=='numeric-plane'then gs[1].plane=1;gs[2].plane=1
 elseif kind=='float-numeric-plane'then gs[1].plane=1.0;gs[2].plane=1.0
 elseif kind=='numeric-string-plane'then gs[1].plane=1;gs[2].plane='1'
 elseif kind=='float-string-plane'then gs[1].plane=1.0;gs[2].plane='1.0'
 elseif kind=='colon-plane'then gs[1].plane='HUD:0:1';gs[2].plane='HUD:0:1'
 elseif kind=='concat-plane'then
  local proxy=setmetatable({},{__concat=function(a,b)note('concat:'..tostring(b));return 'HUD'..b end})
  labels[proxy]='plane-proxy';gs[1].plane=proxy;gs[2].plane=proxy
 elseif kind=='group-proxy'then
  for _,g in ipairs{gs[1],gs[2]}do g.plane=nil;setmetatable(g,{__index=function(_,k)note('group:'..k);if k=='plane'then return 'HUD'end end})end
 elseif kind=='segment-proxy'then
  for _,s in ipairs{h,v}do
   local fields={};for k,x in pairs(s)do fields[k]=x;s[k]=nil end
   setmetatable(s,{__index=function(_,k)note('segment:get:'..k);return fields[k]end,__newindex=function(_,k,x)note('segment:set:'..k);fields[k]=x end})
  end
 elseif kind=='container-proxy'then setmetatable(segments,{})
 elseif kind=='late-unsafe-plane'then add('V',4,-40,40,gs[3],'late');gs[3].plane=7
 elseif kind=='mixed-fast-boundary'then add('V',1000000.125,extent-40,extent+40,gs[3],'edge')
 elseif kind=='neighbor-choice'then
  -- First build three separate small-tolerance nodes on y=-4. A later
  -- large-tolerance contact at0,0 matches all three neighboring x cells.
  -- The original last bucket wins; an early-match shortcut changes its core.
  segments={};items={};for _,g in ipairs(gs)do g.pieces={}end
  add('H',-4,-10,10,gs[1],'smallH').scale=.25
  add('V',-4,-5,-3,gs[2],'leftV').scale=.25
  add('V',0,-10,10,gs[3],'largeV').scale=2.5
  add('V',4,-5,-3,gs[4],'rightV').scale=.25
  add('H',0,-10,10,gs[4],'largeH').scale=2.5
 elseif kind=='unitowner-reentry'then
  local proxy=setmetatable({},{__concat=function(_,suffix)note('reentry-concat:'..suffix);return 'HUD'..suffix end});labels[proxy]='reentry-plane'
  local equal=function()note('owner-equality');gs[1].plane=proxy;gs[2].plane=proxy;return true end
  local a=setmetatable({},{__eq=equal});local b=setmetatable({},{__eq=equal});labels[a]='ownerA';labels[b]='ownerB';gs[1].unitOwner=a;gs[2].unitOwner=b
  tReset=function()gs[1].plane='HUD';gs[2].plane='HUD'end
 elseif kind=='distinct-units'then gs[1].unitOwner='party1';gs[2].unitOwner='party2'
 end
 if kind=='nan'or kind:find('infinity',1,true)then j.limits.bucketEntries=24;j.limits.candidates=24 end
 local t={j=j,segments=segments,items=items,labels=labels,log=log,kind=kind,reset=tReset}
 if kind=='deny-container'then t.denied=segments
 elseif kind=='deny-segment'then t.denied=segments[1]
 elseif kind=='deny-group'or kind=='secret-group'then t.denied=gs[1]
 elseif kind=='secret-rawp'then t.secret=p
 elseif kind=='secret-metatable'then t.secret={};setmetatable(gs[1],{__metatable=t.secret})end
 return t
end
local function configureDenial(t)
 local e=t.j._pointFixtureEnv
 if not t.denied and not t.secret then return end
 local original=getmetatable;local marker={}
 e.getmetatable=function(v)if rawequal(v,t.denied)then error(marker)end;return original(v)end
 e.canaccesstable=function(v)return t.kind=='secret-group'or not rawequal(v,t.denied)end
 e.issecrettable=function(v)return t.kind=='secret-group'and rawequal(v,t.denied)end
 e.issecretvalue=function(v)return t.secret~=nil and rawequal(v,t.secret)end
end
local function actual(t)
 configureDenial(t);if t.reset then t.reset()end
 clean(t);if t.log then for k in pairs(t.log)do t.log[k]=nil end end
 local ok,ops,reason=pcall(t.j.Solve,t.j,t.segments)
 local digest
 if ok then digest=signature(t,ops,reason)
 else digest='ERROR:'..tostring(ops):gsub('@?Core/BorderJunctions.lua:%d+:','Core/BorderJunctions.lua:LINE:')end
 local trace=t.log and table.concat(t.log,'\n')or''
 return digest,trace,ok
end
local function compared(t,code,label,work)
 local ad,at=actual(t)
 local b=twin(t,code);b.log=t.log;b.kind=t.kind;b.denied=t.denied;b.secret=t.secret;b.reset=t.reset;if work then b.j._pointWork={}end
 local bd,bt=actual(b)
 check(ad==bd,label..': exact operations/source fields/error')
 check(at==bt,label..': exact foreign metadata/concat sequence')
 return b.j._pointWork,b
end
local guardKinds={'numeric-string-plane','float-string-plane','concat-plane','group-proxy','segment-proxy','container-proxy','neighbor-choice','deny-container','deny-segment','deny-group','secret-group','secret-rawp','secret-metatable','unitowner-reentry'}
for _,kind in ipairs(guardKinds)do
 local a=guardCase(kind,base);compared(a,candidate,'complete metadata '..kind);compared(a,candidateInstrumented,'observer metadata '..kind,true)
end
do
 local a=guardCase('unitowner-reentry',base);local ad,at=actual(a)
 local b=twin(a,candidate);b.log=a.log;b.reset=a.reset
 local bd,bt=actual(b);local ac=select(2,at:gsub('reentry%-concat:',''));local bc=select(2,bt:gsub('reentry%-concat:',''))
 check(ad==bd and at==bt,'owner equality may replace plane before every subsequent lookup')
 check(ac==14 and bc==14,'full frozen legacy and current retain all14 observable plane concatenations')
 -- This compiled control isolates the rejected numeric index's observable
 -- callback-elision defect without vendoring its200k archived Core. The proxy
 -- returns exactly these HUD strings; output can match while callbacks vanish.
 local lost=replace(candidate,'local bucket=nodes[h.group.plane..":"..(bx+dx)..":"..(by+dy)]','local bucket=nodes["HUD:"..(bx+dx)..":"..(by+dy)]')
 lost=replace(lost,'local nk=h.group.plane..":"..bx..":"..by','local nk="HUD:"..bx..":"..by')
 local wrong=twin(a,lost);wrong.log=a.log;wrong.reset=a.reset;local wd,wt=actual(wrong);local wc=select(2,wt:gsub('reentry%-concat:',''))
 check(wc==4,'plane callback-elision control reproduces14to4 defect')
 check(ad~=wd or at~=wt,'complete oracle rejects metadata callback loss even if numeric output matches')
 print('METACALLBACK|legacy='..ac..'|current='..bc..'|elision-control='..wc)
 print('CONTROL|plane-concat-elision|REJECTED')
end
do
 local early=replace(candidate,'                                if bucket then for _,n in ipairs(bucket) do','                                if bucket and not node then for _,n in ipairs(bucket) do')
 local rejected=false
 -- Standard pairs leaves bucket order unspecified. Exercise one valid stable
 -- spatial-bin order explicitly so this control does not depend on a process's
 -- randomized string hash. Every non-bin table still uses the native iterator.
 local function orderedBins(code)
  local j,_,_,_,_,_,_,_,e=fixture(code);local nativePairs=pairs
  e.pairs=function(t)
   local keys={}
   for k,v in nativePairs(t)do
    if type(k)~='string'or type(v)~='table'or type(v.H)~='table'or type(v.V)~='table'then return nativePairs(t)end
    keys[#keys+1]=k
   end
   if #keys==0 then return nativePairs(t)end
   table.sort(keys);local i=0
   return function()i=i+1;local k=keys[i];if k then return k,t[k]end end
  end
  return j
 end
 local a=guardCase('neighbor-choice',base);local ad=actual(a);local b=twin(a,early);if ad~=actual(b)then rejected=true end
 if not rejected then
  a=guardCase('neighbor-choice',base);a.j=orderedBins(base);ad=actual(a);b=twin(a,early);b.j=orderedBins(early)
  if ad~=actual(b)then rejected=true end
 end
 for seed=1,120 do if rejected then break end
  a=synthetic(base,seed);ad=actual(a);b=twin(a,early);if ad~=actual(b)then rejected=true end
 end
 check(rejected,'first-match shortcut rejected by full operation/source signature');print('CONTROL|first-match|REJECTED')
end
do
 local persist=replace(candidate,'    local bins, nodes, operations, candidates = {}, {}, {}, 0','    self._unsafePointNodes=self._unsafePointNodes or {};local bins,nodes,operations,candidates={ },self._unsafePointNodes,{},0')
 local a=guardCase('positive-zero',base);local b=twin(a,persist)
 local ad=actual(a);check(ad==actual(b),'persistent index mutant starts equivalent')
 -- ReadLayout creates new segment tables on each pass while texture/group
 -- identities persist. A stale node must not retain old segment coordinates.
 local nextSegments={}
 for _,s in ipairs(a.segments)do
  local n={};for k,v in pairs(s)do n[k]=v end;n.p=s.p+1;n.rect={unpack(s.rect)}
  local axis=s.axis=='H'and 2 or 1;n.rect[axis]=n.rect[axis]+1;n.rect[axis+2]=n.rect[axis+2]+1
  n.item.rect=n.rect;a.labels[n]='S:next-'..a.labels[s];nextSegments[#nextSegments+1]=n
 end
 a.segments=nextSegments;b.segments=nextSegments
 ad=actual(a);check(ad~=actual(b),'persistent node index rejected after same identities move');print('CONTROL|persistent-point-index|REJECTED')
end

print('Border solver allocation: '..checks..' checks PASS; complete frozen R57Solve/current helpers,8native/permission/field pairs,14/14metadata calls,8controls; no CPU/native claim')
