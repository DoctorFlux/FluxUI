-- Actual border lifecycle: a clean combat exit must not scan the registry;
-- real pending public geometry/material/settings work still commits once.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
prefix=prefix:gsub('read%("Core/BorderJunctions.lua"%)','read(os.getenv("FLUX_BORDER_JUNCTION_SOURCE") or "Core/BorderJunctions.lua")',1)
local fixture=assert(load(prefix..'\nreturn fixture','@combat-transition-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,style in ipairs{1,2}do
 local j,new,piece,flush,objects,locked,choose,queued,e=fixture();choose(style,'class')
 local root=new(e.UIParent,{0,0,100,100});root.unit='player';root._FluxBorderStatic=true
 local h,record=piece(root,'Top',{0,-9,100,17});local v=piece(root,'Left',{41,-40,16,80})
 for _,source in ipairs{h,v}do
  local get=source.GetRect
  function source:GetRect()local x,y,w,height=get(self);return x+root.rect[1],y+root.rect[2],w,height end
 end
 local art='Interface\\AddOns\\_FluxUI\\Texture\\borders\\ForeverMetal150.tga'
 record.art=art;h:SetTexture(art);flush()
 local function stats()return j.stats.geometryReads or 0,j.stats.solves or 0,j.stats.fullInvalidations or 0,#objects end
 local function regen()
  local listeners={};for _,o in ipairs(objects)do if o.OnEvent then listeners[#listeners+1]=o end end
  for _,o in ipairs(listeners)do o:OnEvent('PLAYER_REGEN_ENABLED')end
 end
 local reads,solves,full,count=stats()
 for _=1,10 do locked(true);locked(false);regen();flush()end
 local a,b,c,d=stats()
 check(a==reads and b==solves and c==full and d==count,'ten clean combat exits perform zero geometry reads/solves/full requests/allocations')
 -- A native public geometry change can occur under lockdown. Queue that
 -- observed fact without authorizing an insecure protected SetPoint in combat.
 locked(true);root.rect[1]=root.rect[1]+8
 j:Invalidate(nil,root);j:CommitLayout();flush()
 check(queued()==0 and(j.stats.geometryReads or 0)==reads,'pending native geometry waits without a combat layout write')
 locked(false);regen();regen()
 check(queued()==1,'repeated regen notifications coalesce the existing pending geometry wake')
 flush();a,b,c,d=stats()
 check(a==reads+1 and b==solves+1 and c==full,'actual queued geometry commits once without escalating to global invalidation')
 -- An ordinary unchanged setter can queue just before combat begins. Its
 -- paused callback must retain the object preflight, not force a global scan.
 reads,solves,full,count=stats()
 root:SetPoint('BOTTOMLEFT',e.UIParent,'BOTTOMLEFT',root.rect[1],root.rect[2])
 locked(true);flush();locked(false);regen();flush()
 a,b,c,d=stats()
 check(a==reads and b==solves and c==full and d==count,'unchanged pending setter survives lockdown and skips global geometry work after release')
 -- Canonical material forwarding is paint-only, even when its coalesced
 -- availability check was held during combat.
 locked(true);record.art=art:gsub('150.tga','150Tint.tga');h:SetTexture(record.art);flush()
 locked(false);regen();flush();a,b,c,d=stats()
 check(a==reads and b==solves and c==full and d==count,'pending canonical material paint survives regen without solving or losing its dirty preflight')
 -- A real public UV change is a genuine material-layout change. It must not
 -- disappear when only the combat wake changes from a forced to a dirty flush.
 locked(true);h:SetTexCoord(.1,.9,.2,.8);flush();locked(false);regen();flush()
 a,b,c,d=stats()
 check(a==reads+1 and b==solves+1 and c==full,'real pending UV change still prepares and commits once')
 reads,solves,full,count=stats()
 locked(true);choose(style==1 and 2 or 1,'custom');j:Invalidate(true);flush()
 check((j.stats.geometryReads or 0)==reads,'explicit settings invalidation stays deferred during combat')
 locked(false);regen();regen();regen();flush();a,b,c,d=stats()
 check(a==reads+1 and b==solves+1 and c==full+1,'actual style/settings force is preserved exactly once without regen adding global requests')
 local finalReads,finalSolves,finalFull,finalCount=stats()
 regen();flush();a,b,c,d=stats()
 check(a==finalReads and b==finalSolves and c==finalFull and d==finalCount,'a clean later exit cannot replay an already consumed deferred rebuild')
end
print('Border combat transitions: '..checks..' checks PASS; actual clean10exits0reads/solves/full requests/resources; pending native geometry/material/UV/style retained once; unchanged dirty preflight; coalesced wakes; no native FPS/taint claim')
