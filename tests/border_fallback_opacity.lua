-- Actual duplicated crossbar/T aliases under deep public ancestry. Disabled
-- aliases must never be raised before their final opacity gate on a reflow.
local sourcePath=arg[1]or"Core/BorderJunctions.lua"
local measure=arg[2]=="--measure"
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function corrected(v,m)if not measure then check(v,m)end end
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a");f:close();return s end
local function replace(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(1,i-1)..b..s:sub(i+#a)end
local core=read(sourcePath):gsub("\r\n","\n")
core=replace(core,"local function RegisterFallback(","local function NativeRegisterFallback(")
local paintStart=core:find("\ndo\n    local function PaintFallbackList",1,true) and "\ndo\n    local function PaintFallbackList" or "\nPaintFallbacks="
core=replace(core,paintStart,[[

local function RegisterFallback(...)
    _G.fallbackDepth=(_G.fallbackDepth or 0)+1
    NativeRegisterFallback(...)
    _G.fallbackDepth=_G.fallbackDepth-1
end
]]..paintStart)
local availabilityHeader=assert(core:match("local function PaintAvailable%b()"))
core=replace(core,availabilityHeader,availabilityHeader..[[

    if (_G.fallbackDepth or 0)>0 then _G.fallbackGateCalls=(_G.fallbackGateCalls or 0)+1 end]])
core=replace(core,"local function StaticUnitOwner(object)",[[local function StaticUnitOwner(object)
    if (_G.fallbackDepth or 0)>0 then _G.fallbackOwnerCalls=(_G.fallbackOwnerCalls or 0)+1 end]])
core=core..[[

return {
    memos=function()return fallbackChains,fallbackAvailability end,
    current=PaintAvailable,
    tile=function(visibility)
        painting=visibility~=nil
        fallbackChains=visibility and {ancestry={},owners={},ancestorVisibility=visibility}
        fallbackAvailability=visibility and {}
    end,
}]]
local prefix=assert(read("tests/border_junctions.lua"):match("^(.-)local J=fixture%(%)"))
prefix=replace(prefix,'assert(load(read("Core/BorderJunctions.lua"),"@Core/BorderJunctions.lua","t",e))("_FluxUI",{Border=B})',
    'e.exports=assert(load('..string.format("%q",core)..',"@fallback-opacity-core","t",e))("_FluxUI",{Border=B})')
prefix=replace(prefix,'function(a,b)style=a;accent=b end,function()return #queue end,e',
    'function(a,b)style=a;accent=b end,function()return #queue end,e,m')
local fixture=assert(load(prefix.."\nreturn fixture","@fallback-opacity-fixture","t",_G))()
local function digest(objects)
    local rows={}
    for _,t in ipairs(objects)do if t.decorative and t.shown and t.size then
        local a={t.path,t.alpha,t._fallbackEnabled and 1 or 0}
        for _,v in ipairs(t.uv)do a[#a+1]=v end
        for _,v in ipairs(t.size)do a[#a+1]=v end
        for _,v in ipairs(t.color)do a[#a+1]=v end
        for _,v in ipairs(t.point or{})do if type(v)~="table"then a[#a+1]=v end end
        for i=1,4 do for _,v in ipairs(t.vertices and t.vertices[i]or{})do a[#a+1]=v end end
        for i,v in ipairs(a)do a[i]=type(v)=="number"and string.format("%.17g",v)or tostring(v)end
        rows[#rows+1]=table.concat(a,",")
    end end
    table.sort(rows);local text=table.concat(rows,";");local hash=0
    for i=1,#text do hash=(hash*257+text:byte(i))%2147483647 end
    return hash,#rows
end
for _,style in ipairs{1,2}do
    local j,new,piece,flush,objects,lock,choose,_,e,m=fixture();choose(style,"class")
    local counts={parents=0,aliasWrites=0,revivals=0,liveParents=0}
    local getParent=m.GetParent
    m.GetParent=function(self)
        if (e.fallbackDepth or 0)>0 then counts.parents=counts.parents+1 end
        if counts.liveUpdate then counts.liveParents=counts.liveParents+1 end
        return getParent(self)
    end
    local alpha=m.SetAlpha
    m.SetAlpha=function(self,value)
        if self.decorative and self._fallbackBlockers and self._fallbackEnabled==false then
            counts.aliasWrites=counts.aliasWrites+1
            if not(e.issecretvalue and e.issecretvalue(value))and type(value)=="number"and value>0 then counts.revivals=counts.revivals+1 end
        end
        if counts.failGate and self.decorative and self._fallbackBlockers then error("injected fallback gate failure",0)end
        return alpha(self,value)
    end
    local root=new(e.UIParent);root.unit="player";root._FluxBorderStatic=true
    local function host(level)
        local p=root
        for _=1,6 do p=new(p)end
        p.level=level;return p
    end
    local lowerHost,upperHost=host(1),host(20)
    local lower=piece(lowerHost,"Top",{0,-9,1000,17});lower:SetTexture("low.tga");lower:SetVertexColor(.2,.4,.6,.7)
    local upper=piece(upperHost,"Top",{0,-9,1000,17});upper:SetTexture("high.tga");upper:SetVertexColor(.8,.5,.1,1)
    local verticals={}
    for i=1,24 do verticals[i]=piece(root,"Left",{i*37-9,-40,16,80})end
    local report={};e.Flux.PerfCapture={GetActiveWatchReport=function()return report end}
    local clock=0;e.debugprofilestop=function()clock=clock+1;return clock end
    flush();check(j.stats.fallback==nil,"duplicate crossbar compiles complete fallback mesh")
    local function aliases()
        local list={}
        -- This test exercises the original lower crossbar's parallel backups.
        -- Optional perpendicular continuations have their own visibility gates.
        for _,t in ipairs(objects)do if t._junctionOwnerOp and t._fallbackBlockers and t._junctionSource==lower
            and #t._fallbackBlockers==1 and t._fallbackBlockers[1]==upper then list[#list+1]=t end end
        return list
    end
    local first=digest(objects);local hidden=aliases()
    check(#hidden>100,"fixture owns many inactive triangle aliases")
    for _,t in ipairs(hidden)do check(t.alpha==0 and t._fallbackEnabled==false,"higher source keeps lower alias disabled")end
    local function reset()counts.parents,counts.aliasWrites,counts.revivals=0,0,0;e.fallbackOwnerCalls=0;e.fallbackGateCalls=0 end
    reset();j:Invalidate(true);flush()
    check(digest(objects)==first,"warm forced commit retains exact mesh/tint/visibility")
    corrected(counts.aliasWrites==0 and counts.revivals==0,"unchanged disabled aliases never receive intermediate alpha revival or redundant gate writes")
    corrected(counts.parents<1000 and e.fallbackOwnerCalls<100,"fallback chains and availability are read once per commit")
    print(string.format("FALLBACK_OPACITY_WORK style=%d aliases=%d alphaWrites=%d revivals=%d parents=%d owners=%d gates=%d totalAlphaWrites=%d mesh=%d",
        style,#hidden,counts.aliasWrites,counts.revivals,counts.parents,e.fallbackOwnerCalls,e.fallbackGateCalls,report.borderLast.work.alphaWrites,first))
    local chains,availability=e.exports.memos();check(chains==nil and availability==nil,"availability/ancestry memos end before live paint")
    reset();verticals[7].rect[1]=verticals[7].rect[1]+5;j:Invalidate(nil,verticals[7]);flush()
    corrected(counts.revivals==0,"real layout reflow does not expose a disabled alias before gating")
    local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
    for _,combat in ipairs{false,true}do
        lock(combat)
        counts.liveUpdate=true;upper:Hide();counts.liveUpdate=false;flush()
        for _,t in ipairs(aliases())do check(t.alpha==.7 and t._fallbackEnabled,"live source hide enables prepared aliases with author alpha")end
        counts.liveUpdate=true;upper:Show();counts.liveUpdate=false;flush()
        for _,t in ipairs(aliases())do check(t.alpha==0 and not t._fallbackEnabled,"live source show disables aliases without stale memo")end
        counts.liveUpdate=true;upperHost:SetAlpha(0);counts.liveUpdate=false;flush()
        for _,t in ipairs(aliases())do check(t.alpha==.7,"live ancestor alpha-zero enables aliases")end
        counts.liveUpdate=true;upperHost:SetAlpha(1);counts.liveUpdate=false;flush()
        for _,t in ipairs(aliases())do check(t.alpha==0,"live ancestor alpha return disables aliases")end
    end
    lock(false)
    check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,"visibility/alpha transitions stay prebuilt and static including combat")
    corrected(counts.liveParents<1000,"shared sources are queried once per live fallback update")
    print(string.format("FALLBACK_LIVE_WORK style=%d updates=8 parents=%d",style,counts.liveParents))
    if not measure then
        counts.failGate=true
        local ok,err=pcall(upperHost.SetAlpha,upperHost,0)
        check(not ok and err=="injected fallback gate failure","live paint surfaces the original setter error")
        counts.failGate=false;upperHost:SetAlpha(0);flush()
        for _,t in ipairs(aliases())do check(t.alpha==.7,"the same visibility event can retry after failed paint")end
        upperHost:SetAlpha(1);flush()
    end
    local newParent=new(root);upperHost:SetParent(newParent);j:Invalidate(true);flush()
    newParent:Hide();flush()
    for _,t in ipairs(aliases())do check(t.alpha==.7,"next commit observes freshly reparented blocker ancestry")end
    newParent:Show();flush()
    local private=setmetatable({}, {__eq=function()error("private opacity compared")end,
        __lt=function()error("private opacity ordered")end,__tostring=function()error("private opacity formatted")end})
    e.issecretvalue=function(value)return rawequal(value,private)end
    upper:SetAlpha(private);j:Invalidate(true);flush()
    for _,t in ipairs(aliases())do check(t.alpha==0,"opaque winner opacity cannot enable lower aliases during a commit")end
    chains,availability=e.exports.memos();check(chains==nil and availability==nil,"opaque paint retains no availability/ancestry memo")
    upper:SetAlpha(1);flush();e.issecretvalue=nil
    local target=aliases()[1];target.alpha=1;counts.failGate=true;j:Invalidate(true)
    local ok,err=pcall(flush)
    check(not ok and tostring(err):find("injected fallback gate failure",1,true),"mid-gate native failure surfaces")
    chains,availability=e.exports.memos();check(chains==nil and availability==nil,"error rollback drops both commit-local memos")
    counts.failGate=nil;e.fallbackDepth=0;j:Invalidate(true);flush()
    check(j.stats.fallback==nil and lower.alpha==0,"failed gate remains retryable")
    for _,t in ipairs(aliases())do check(t.alpha==0,"recovered aliases retain final disabled opacity")end
    j:ReleaseAll();chains,availability=e.exports.memos();check(chains==nil and availability==nil,"explicit release clears fallback memos")
end
if not measure then
    local j,new,piece,_,_,_,_,_,e,m=fixture()
    local parent=new(e.UIParent)
    local a=piece(parent,"Top",{0,0,100,17})
    local b=piece(parent,"Bottom",{0,40,100,17})
    local samples={}
    local reads,alpha=0,m.GetAlpha
    function m:GetAlpha()
        if self==parent then reads=reads+1 end
        return alpha(self)
    end
    local function tile()e.exports.tile(samples)end
    local current=e.exports.current
    tile();check(current(a),"first public parent appearance remains visible")
    tile();check(current(b) and samples[parent]==true and reads==1,"next tile shares the confirmed ancestor alpha")
    check(current(parent) and reads==1,"the same parent as a fallback observer uses its confirmed sample")
    parent:SetAlpha(0)
    tile();check(samples[parent]==nil and not current(a),"observed alpha write clears the shared sample during draw")
    tile();check(not current(b) and samples[parent]==false and reads==2,"public zero remains authoritative across tiles")
    check(not current(parent) and reads==2,"the parent observer also reports its confirmed absence")
    parent:SetAlpha(1);tile();check(current(a),"a later native alpha write admits the source")
    parent:Hide();tile();check(not current(b) and samples[parent]==false,"observed parent hide affects the next tile")
    parent:Show();tile();check(current(b),"observed parent show restores the next tile")
    local opaque=setmetatable({}, {__eq=function()error("opaque ancestor compared")end,
        __lt=function()error("opaque ancestor ordered")end})
    e.issecretvalue=function(value)return rawequal(value,opaque)end
    parent:SetAlpha(opaque);tile();check(current(a) and samples[parent]==nil,"opaque ancestor alpha keeps native visibility without caching a decision")
    parent:SetAlpha(1)
    parent.GetAlpha=function()return 0 end
    tile();check(not current(b) and samples[parent]==nil,"foreign instance getters stay live across tiles")
    parent.GetAlpha=function()return 1 end
    tile();check(current(b) and samples[parent]==nil,"the next foreign getter answer is evaluated immediately")
    parent.GetAlpha=nil
    e.exports.tile(nil)
    j:ReleaseAll()
    local chains,availability=e.exports.memos()
    check(chains==nil and availability==nil,"regional ancestor samples never survive publication or release")
end
print("border fallback opacity: "..checks.." checks passed"..(measure and" (measurement)"or""))
