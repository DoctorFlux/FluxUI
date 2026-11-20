-- Whole-operation draw reuse on one connected crossbar. Numeric meshes and
-- native setter work are measured independently; no native FPS/taint claim.
local sourcePath=arg[1]or"Core/BorderJunctions.lua"
local measure=arg[2]=="--measure"
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function corrected(v,m)if not measure then check(v,m)end end
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a");f:close();return s end
local function replace(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(1,i-1)..b..s:sub(i+#a)end
local core=read(sourcePath).."\nreturn {active=function()return active end,sprites=sprites,cache=function()return drawPrevious end,work=function()return renderWork end}"
local prefix=assert(read("tests/border_junctions.lua"):match("^(.-)local J=fixture%(%)"))
prefix=replace(prefix,'assert(load(read("Core/BorderJunctions.lua"),"@Core/BorderJunctions.lua","t",e))("_FluxUI",{Border=B})',
    'e.exports=assert(load('..string.format("%q",core)..',"@draw-reuse-production-core","t",e))("_FluxUI",{Border=B})')
prefix=replace(prefix,'function(a,b)style=a;accent=b end,function()return #queue end,e',
    'function(a,b)style=a;accent=b end,function()return #queue end,e,m')
local fixture=assert(load(prefix.."\nreturn fixture","@connected-draw-reuse-fixture","t",_G))()
local function signature(objects)
    local rows={}
    for _,t in ipairs(objects)do if t.decorative and t.shown and t.size then
        local p=t:GetParent();local x,y=p:GetLeft(),p:GetBottom();local scale=p:GetEffectiveScale()
        local a={t.path,t.alpha,p:GetFrameStrata(),p:GetFrameLevel(),x,y,scale,t._fallbackEnabled and 1 or 0}
        for _,v in ipairs(t.uv)do a[#a+1]=v end
        for _,v in ipairs(t.size)do a[#a+1]=v end
        for _,v in ipairs(t.color)do a[#a+1]=v end
        for _,v in ipairs(t.point or{})do if type(v)~="table"then a[#a+1]=v end end
        for i=1,4 do for _,v in ipairs(t.vertices and t.vertices[i]or{})do a[#a+1]=v end end
        for i,v in ipairs(a)do a[i]=type(v)=="number"and string.format("%.17g",v)or tostring(v)end
        rows[#rows+1]=table.concat(a,",")
    end end
    table.sort(rows);local text=table.concat(rows,";");local h=0
    for i=1,#text do h=(h*257+text:byte(i))%2147483647 end
    return h,#rows
end
for _,style in ipairs{1,2}do
    local j,new,piece,flush,objects,lock,choose,_,e,m=fixture();choose(style,"class")
    local root=new(e.UIParent);root.unit="focus";root._FluxBorderStatic=true
    local top=piece(root,"Top",{0,-9,3400,17});top:SetTexture("crossbar.tga")
    local verticals={};for i=1,8 do for k=1,7 do verticals[#verticals+1]=piece(root,"Left",{i*400+k*26-9,-40,16,80})end end
    local report={};e.Flux.PerfCapture={GetActiveWatchReport=function()return report end}
    local clock=0;e.debugprofilestop=function()clock=clock+1;return clock end
    local solve=j.Solve
    j.Solve=function(self,segments)
        local ops,why=solve(self,segments)
        if ops then table.sort(ops,function(a,b)
            local ac,bc=a.vs and a.vs.texture==verticals[7],b.vs and b.vs.texture==verticals[7]
            if ac~=bc then return ac end
            return (a.vs and a.vs.paintID or 0)<(b.vs and b.vs.paintID or 0)
        end)end
        return ops,why
    end
    flush();check(j.stats.triangles>=672,"one parent prepares a connected56junction mesh")
    local initial,fields=signature(objects)
    j:Invalidate(true);flush()
    check(signature(objects)==initial,"unchanged forced commit retains exact rendered mesh")
    local warm=report.borderLast.work
    corrected(warm.drawReuses==56 and warm.drawFields>=672 and warm.fieldCalls<1000,
        "unchanged operations skip triangle setter walks and claim all prepared sprites")
    if not measure then
        for _,cached in pairs(e.exports.cache()) do
            check(cached.sprites and #cached.sprites==#cached.indices,
                "cached draw keeps one triangle index per actual sprite")
            for index,field in ipairs(cached.sprites) do
                local owner=field._junctionOwnerOp
                local offset=cached.indices[index]
                local triangle=owner.triangles[offset] or owner.fallbackTriangles[offset-#owner.triangles]
                check(owner.sprites==cached.sprites and triangle and not triangle.quadTail
                    and field._junctionSource==triangle.texture,
                    "warm draws share the sprite list and preserve live triangle ownership")
            end
        end
    end
    verticals[7].rect[1]=verticals[7].rect[1]+11;j:Invalidate(nil,verticals[7]);flush()
    local moved,movedFields=signature(objects);local work=report.borderLast.work
    check(moved~=initial and movedFields>=fields,"real local change updates the connected mesh")
    corrected((work.drawReuses or 0)>=54 and(work.drawMisses or 0)<=2 and work.fieldCalls<1500,
        "changed-first allocator cannot steal preclaimed stable operation sprites")
    print(string.format("DRAW_REUSE_WORK style=%d fields=%d warmCalls=%d warmHits=%d warmReuses=%d moveCalls=%d moveReuses=%d moveMisses=%d claimed=%d mesh=%d beforeMesh=%d",
        style,movedFields,warm.fieldCalls,warm.fieldHits,warm.drawReuses or 0,work.fieldCalls,work.drawReuses or 0,work.drawMisses or 0,work.drawFields or 0,moved,initial))
    -- Live RGB and opacity callbacks must still reach fast-path fields.
    local solves,reads=j.stats.solves,j.stats.geometryReads
    lock(true);top:SetVertexColor(.3,.5,.8,.6);flush()
    for _,t in ipairs(objects)do if t._junctionSource==top and t._junctionOwnerOp then
        check(t.color[1]==.3 and t.color[2]==.5 and t.color[3]==.8 and t.alpha==(t._fallbackBlockers and 0 or .6),"live combat paint reaches normal listeners while unneeded continuations remain gated")
    end end
    check(j.stats.solves==solves and j.stats.geometryReads==reads,"live combat paint remains topology static")
    lock(false)
    top:SetVertexColor(1,1,1,1);j:Invalidate(true);flush()
    local public=setmetatable({}, {__lt=function()error("private alpha ordered")end,__eq=function()error("private alpha compared")end})
    e.issecretvalue=function(v)return rawequal(v,public)end
    top:SetAlpha(public);j:Invalidate(true);flush()
    j:Invalidate(true);flush()
    corrected((report.borderLast.work.drawReuses or 0)==56,"unchanged opaque-alpha class can reuse already-forwarded native paint")
    for _,t in ipairs(objects)do if t._junctionSource==top and t._junctionOwnerOp then
        check(t._fallbackBlockers and t.alpha==0 or not t._fallbackBlockers and rawequal(t.alpha,public),"opaque source opacity is forwarded while inactive continuations stay gated after reuse")
    end end
    if not measure then
        for _,cached in pairs(e.exports.cache())do
            check(cached.contexts==nil and cached.gates==nil and cached.source==nil and cached.op==nil and cached.group==nil,
                "draw generation retains no current Source/group/operation/context wrappers")
            for _,value in ipairs(cached.inputs)do check(not e.issecretvalue(value),"draw descriptor stores no opaque alpha")end
        end
    end
    local nextPrivate=setmetatable({},getmetatable(public))
    e.issecretvalue=function(v)return rawequal(v,public)or rawequal(v,nextPrivate)end
    top:SetAlpha(nextPrivate);j:Invalidate(true);flush()
    corrected((report.borderLast.work.drawReuses or 0)==56,"new opaque value within the same class relies on current live native forwarding")
    for _,t in ipairs(objects)do if t._junctionSource==top and t._junctionOwnerOp then
        check(t._fallbackBlockers and t.alpha==0 or not t._fallbackBlockers and rawequal(t.alpha,nextPrivate),"reuse forwards the current opaque value without reviving inactive continuations")
    end end
    top:SetAlpha(1);flush();e.issecretvalue=nil
    top:SetTexture("changed-material.tga");j:Invalidate(true);flush()
    check((report.borderLast.work.drawMisses or 0)>0 or measure,"changed current material rejects full draw reuse")
    for _,t in ipairs(objects)do if t._junctionSource==top and t._junctionOwnerOp then
        check(t.path=="changed-material.tga","material change reaches every fresh/current field")
    end end
    top.masks.foreign=true;j:Invalidate(true);flush()
    check(j.stats.skippedComponents>0,"source masks reject unavailable full-draw component")
    top.masks.foreign=nil;j:Invalidate(true);flush()
    root.scale=.75;j:Invalidate(true);flush()
    check((report.borderLast.work.drawMisses or 0)>0 or measure,"changed actual render basis rejects full reuse")
    root.scale=1;j:Invalidate(true);flush()
    root.level=55;root.strata="HIGH";j:Invalidate(true);flush()
    check((report.borderLast.work.drawMisses or 0)>0 or measure,"changed canvas rank/level rejects full draw reuse")
    for _,t in ipairs(objects)do if t._junctionOwnerOp then check(t.parent:GetFrameStrata()=="HIGH"and t.parent:GetFrameLevel()==56,"updated canvas rank reaches current mesh")end end
    local replacement=new(e.UIParent,{10,20,100,100});replacement.unit="focus";replacement._FluxBorderStatic=true
    replacement.strata="HIGH";replacement.level=55
    verticals[7]:SetParent(replacement);j:Invalidate(true);flush()
    check((report.borderLast.work.drawMisses or 0)>0 or measure,"new actual source parent rejects old render binding")
    -- Foreign/native field state must still reject the whole-op fast path.
    local function currentField()
        for _,field in ipairs(objects)do if field._junctionOwnerOp and field._junctionSource==top then return field end end
        error("no prepared whole-op field for current native-state guard")
    end
    local beforeHidden=e.exports.cache()
    local field=currentField();field:Hide();j:Invalidate(true);flush()
    check((report.borderLast.work.drawMisses or 0)>0,"actual derived field Hide rejects reuse")
    local repairs=0
    for key,cached in pairs(e.exports.cache()) do
        local before=beforeHidden[key]
        if before and cached~=before then
            corrected(cached.inputs==before.inputs,"native field repair shares the verified public input list")
            repairs=repairs+1
        end
    end
    corrected(repairs>0,"hiding a derived field exercises repaint with matching inputs")
    field=currentField();local originalParent=field:GetParent()
    field:SetParent(e.UIParent);j:Invalidate(true);flush()
    check((report.borderLast.work.drawMisses or 0)>0,"actual derived field reparent rejects reuse")
    field:SetParent(originalParent);j:Invalidate(true);flush()
    field=currentField();local nativeParent=field.GetParent
    local opaque=setmetatable({}, {__index=function()error("private field parent indexed")end,__eq=function()error("private field parent compared")end})
    e.issecretvalue=function(v)return rawequal(v,opaque)end
    field.GetParent=function()return opaque end;j:Invalidate(true);flush()
    check((report.borderLast.work.drawMisses or 0)>0,"private current field parent rejects reuse")
    field.GetParent=nativeParent;e.issecretvalue=nil;j:Invalidate(true);flush()
    field=currentField();local nativeShown=field.IsShown
    e.issecretvalue=function(v)return rawequal(v,opaque)end
    field.IsShown=function()return opaque end;j:Invalidate(true);flush()
    check((report.borderLast.work.drawMisses or 0)>0,"private current field shown flag rejects reuse")
    field.IsShown=nativeShown;e.issecretvalue=nil;j:Invalidate(true);flush()

    -- Stable operations are preclaimed before a changed operation allocates.
    -- A native failure still must retire ALL old+new claimed generations.
    local create=m.CreateTexture;local preclaims=0
    m.CreateTexture=function(self,name,layer,...)
        if layer=="OVERLAY"then
            local current=e.exports.work();preclaims=current and current.drawReuses or 0
            error("preclaimed draw allocation failure",0)
        end
        return create(self,name,layer,...)
    end
    for i=1,6 do piece(root,"Left",{28+i*29-9,-40,16,80})end
    local ok,err=pcall(flush)
    check(not ok and tostring(err):find("preclaimed draw allocation failure",1,true),"native allocation failure after reservation is surfaced")
    corrected(preclaims>0,"allocator failure occurs after stable operation sprites were preclaimed")
    for _,t in ipairs(objects)do if t.decorative then check(not t.shown,"rollback hides every preclaimed old/new field")end end
    check(top.alpha==1,"rollback restores original source suppression")
    if not measure then check(next(e.exports.cache())==nil,"failed transaction publishes no draw generation")end
    m.CreateTexture=create;j:Invalidate(true);flush()
    check(j.stats.fallback==nil and top.alpha==0,"failed preclaimed transaction remains retryable")
end
print("border draw reuse: "..checks.." checks passed"..(measure and" (measurement)"or""))
