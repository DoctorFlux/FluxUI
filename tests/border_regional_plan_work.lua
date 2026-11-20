-- Execute production planning/renderer with the established canonical-art fixture.
-- A changed contact on a long strip must not compile every distant T/X mesh.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local test=read('tests/border_locality.lua')
local stop=assert(test:find("if arg[1]=='--work' then",1,true))
local prefix=test:sub(1,stop-1):gsub("local corePath='Core/BorderJunctions.lua'","local corePath=arg[1]or'Core/BorderJunctions.lua'",1)
local run=prefix..[[
local totals={compiled=0,misses=0,milliseconds=0}
for _,style in ipairs{1,2}do for _,scale in ipairs{.75,1,1.25}do
 local current=model(scenes(style)[1].groups,style,scale)
 local reference=model(scenes(style)[1].groups,style,scale,true)
 local samples={}
 for step,index in ipairs{8,18,8,18,8,18}do
  local start=os.clock()
  local t=current.sources[index][1];t.rect[1]=t.rect[1]+(step<=2 and 7 or step<=4 and -7 or 7)
  current.j:Invalidate(nil,t);current.j:CommitLayout()
  local ms=(os.clock()-start)*1000
  local count=(current.j.stats.compileHits or 0)+(current.j.stats.compileMisses or 0)
  totals.compiled=totals.compiled+count;totals.misses=totals.misses+(current.j.stats.compileMisses or 0);totals.milliseconds=totals.milliseconds+ms
  local r=reference.sources[index][1];r.rect[1]=t.rect[1];reference.j:Invalidate(nil,r);reference.j:CommitLayout()
  compare(current,reference,{{90,0},{630,0},{637,0},{1530,0},{1537,0},{2160,0}},scale)
  if not arg[2]then check(count<=8,'only junction meshes intersecting four changed cells may compile; distant contacts stay prepared')end
  samples[#samples+1]=string.format('%d/%d/%.3f',count,current.j.stats.compileMisses or 0,ms)
 end
 print(string.format('REGIONAL_PLAN style=%d scale=%.2f compiled/misses/ms=%s',style,scale,table.concat(samples,',')))
end end
-- Publishing an unchanged region must preserve its immutable cache records.
do
 local m=model(scenes(2)[1].groups,2,1)
 local compile=m.j.BranchTriangles;local calls=0
 m.j.BranchTriangles=function(self,...)calls=calls+1;return compile(self,...)end
 for _=1,3 do m.j:_PublishBranchCompileCache();m.j:_PublishFallbackPlanCache()end
 local t=m.sources[8][1];t.rect[1]=t.rect[1]+7;m.j:Invalidate(nil,t);m.j:CommitLayout()
 local cold=calls
 -- A real move elsewhere must not evict the already prepared neighbourhood.
 t=m.sources[18][1];t.rect[1]=t.rect[1]+7;m.j:Invalidate(nil,t);m.j:CommitLayout()
 if not arg[2]then check(calls-cold<=2,'untouched regions keep base compile records across partial commits')end
end
print(string.format('REGIONAL_PLAN_TOTAL compiled=%d misses=%d ms=%.3f checks=%d; desktop source/art parity only, native latency/taint pending',totals.compiled,totals.misses,totals.milliseconds,checks))
]]
assert(load(run,'@regional-plan-work','t',_G))()

-- Read the exact fragment-owner phase from either the archived or current core.
-- Check late-created fragments independently of the already-prepared variants.
local source=read(arg[1] or 'Core/BorderJunctions.lua')
local start=source:find("local function PrepareFragmentOwners(",1,true)
local phase
if start then
 local finish=assert(source:find("function J:_PreparePlan(",start,true))
 phase=source:sub(start,finish-1).."\nreturn PrepareFragmentOwners"
else
 local first=assert(source:find("    -- Keep raised shared fields",1,true))
 local finish=assert(source:find('    PlanCost(cost,"owners")',first,true))
 phase="return function(operations,plans,blocked)\n"..source:sub(first,finish-1).."\nend"
end
local counts={items=0,writes=0,sourceCalls=0}
phase=phase:gsub("for _,item in ipairs%(([%w]+)%.pieces%) do",
 "for _,item in ipairs(%1.pieces) do CountItem()")
phase=phase:gsub("([%w.]+)%[member%]=true","CountWrite();%1[member]=true")
local ownerEnv=setmetatable({CountItem=function()counts.items=counts.items+1 end,
 CountWrite=function()counts.writes=counts.writes+1 end,
 Source=function(texture)counts.sourceCalls=counts.sourceCalls+1;return texture.material end},{__index=_G})
local prepareOwners=assert(load(phase,"@actual-fragment-owners","t",ownerEnv))()
local groups,initial,ops,root,blocked={},{},{},{},{}
local function border(id,unit,fixed)
 local g={id=id,pieces={},unitOwner=unit,fixedBounds=fixed}
 for i=1,8 do
  local texture={id=id*10+i,material={key=id*10+i}}
  g.pieces[i]={texture=texture,rect={i,i,i+16,i+16}}
 end
 groups[#groups+1]=g
 return g
end
local strip=border(1)
local isolated=border(2,nil,true)
local player=border(3,"player")
local neighbor=border(4)
local cosmetic=border(5,nil,true)
local extra=border(6)
local unpaintable=strip.pieces[6].texture
unpaintable.material=nil
local function hasPlan(item)
 initial[item.texture]={item=item,root=root,source=item.texture.material,rects={item.rect}}
end
hasPlan(strip.pieces[1])
hasPlan(strip.pieces[2])
hasPlan(player.pieces[1])
local function contact(opRoot,...)
 local op={root=opRoot,members={}}
 for _,g in ipairs({...}) do op.members[g]=true end
 ops[#ops+1]=op
end
contact(blocked,strip,cosmetic)
for _=1,18 do contact(root,strip,neighbor,extra) end
contact(root,strip,player)
for _=1,18 do contact(root,strip,isolated,player) end
for _=1,18 do contact(root,strip,extra,player) end
local plans={}
for texture,p in pairs(initial) do
 plans[texture]={item=p.item,root=p.root,source=p.source,rects=p.rects}
end
prepareOwners(ops,plans,{[blocked]=true})
for _,g in ipairs(groups) do
 for _,item in ipairs(g.pieces) do
  local expected=initial[item.texture] and {} or nil
  for _,op in ipairs(ops) do if op.root~=blocked and op.members[g] then
   if not expected and item.texture.material then
    for member in pairs(op.members) do
     if g.fixedBounds or member.unitOwner and not g.unitOwner then expected={};break end
    end
   end
   if expected then for member in pairs(op.members) do expected[member]=true end end
  end end
  local plan=plans[item.texture]
  assert((expected~=nil)==(plan~=nil),"fragment activation matches the all-pieces phase")
  if plan then
   assert(plan.item==item and plan.source==item.texture.material and plan.root==root and plan.rects[1]==item.rect)
   for member in pairs(expected) do assert(plan.renderMembers[member],"expected owner missing") end
   for member in pairs(plan.renderMembers) do assert(expected[member],"unexpected earlier or blocked owner") end
  end
 end
end
if not arg[2] then
 assert(counts.items<100 and counts.writes<1000,"shared frame pieces are indexed once per owner phase")
end
print(string.format("REGIONAL_OWNER_WORK items=%d ownerWrites=%d sourceCalls=%d",counts.items,counts.writes,counts.sourceCalls))
