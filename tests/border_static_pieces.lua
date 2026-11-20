-- Native R34 trace: individual unit edges changed shown/opacity-zero, although
-- root hide/fade was already retained. Replay those exact source transitions.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@static-piece-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,style in ipairs{1,2}do for _,unit in ipairs{'target','focus','party1','pet','targettarget'}do
 for _,scale in ipairs{.75,1,1.25}do for _,knownGlobal in ipairs{false,true}do
  local j,new,piece,flush,objects,lock,choose,queued,e=fixture();choose(style,'class')
  local root=new(e.UIParent);root.unit=unit;root.scale=scale
  if knownGlobal then e['FluxUnitFrame_'..unit]=root else root._FluxBorderStatic=true end
  local host=new(root);host.scale=scale;host._FluxBorderOwner=root
  local h=piece(host,'Top',{0,-9,120,17})
  local v=piece(host,'Left',{51,-45,16,90})
  -- Both initial alpha-zero and own Hide must still prebuild the topology.
  h:Hide();h:SetAlpha(0);v:SetAlpha(0);root:Hide();flush()
  check(j.stats.fallback==nil and j.stats.triangles>0,'initial hidden/zero-opacity source pieces are prepared')
  local sinks={}
  for _,t in ipairs(objects)do if t._junctionSource==h then sinks[#sinks+1]=t end end
  check(#sinks>0,'actual native branch paint is observed')
  local solves,reads,full,count=j.stats.solves,j.stats.geometryReads,j.stats.fullInvalidations,#objects
  local baselineReads=e.rectReads
  for _,combat in ipairs{false,true}do
   lock(combat)
   for _=1,12 do
    root:Show();h:Show();h:SetVertexColor(.2,.6,.9,.4);v:SetAlpha(1);flush()
    for _,t in ipairs(sinks)do
     if t._fallbackBlockers then check(t:GetAlpha()==0,'conditional continuation stays hidden while the perpendicular source is available')
     else check(t:IsVisible() and t:GetAlpha()==.4,'own Show/recolor reveals the existing source branch')end
    end
    h:Hide();h:SetVertexColor(.2,.6,.9,.8)
    for _,t in ipairs(sinks)do check(t:GetAlpha()==0,'recolor cannot reveal paint of an individually hidden source')end
    h:Show()
    for _,t in ipairs(sinks)do check(t:GetAlpha()==(t._fallbackBlockers and 0 or .8),'own Show restores normal paint while keeping unnecessary backups disabled')end
    v:Hide()
    for _,t in ipairs(sinks)do check(t:GetAlpha()==.8,'hiding the perpendicular source reveals its already-prepared continuation')end
    v:Show()
    for _,t in ipairs(sinks)do if t._fallbackBlockers then check(t:GetAlpha()==0,'returning perpendicular paint disables the continuation without a solve')end end
    h:SetAlpha(0);v:SetAlpha(0);root:Hide();j:CommitLayout();flush()
   end
  end
  check(j.stats.solves==solves and j.stats.geometryReads==reads and j.stats.fullInvalidations==full,
   'unit edge own visibility/opacity transitions perform zero solves/geometry reads/global requests')
  check(#objects==count and e.rectReads==baselineReads and queued()==0,'no allocations or geometry probes while replaying native visibility paint, including combat')
  lock(false);root:Show();h:Show();h:SetAlpha(1);v:SetAlpha(1);flush()
  v.rect[1]=v.rect[1]+8;v:SetPoint('LEFT',host,'LEFT',8,0);j:CommitLayout()
  check(j.stats.solves==solves+1,'real edge-layout changes still invalidate retained geometry')
 end end
end end
print('Static unit pieces: '..checks..' checks PASS; R34 own Hide/Show and opacity-zero trace; hidden prebuild; logical/global ownership; zero probes/solves/resources; combat paint; real moves rebuild; native acceptance pending')
