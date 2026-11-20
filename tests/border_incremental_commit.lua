-- Actual global solve/plan/commit with one changed panel among prepared peers.
-- Exact drawing-field parity and native mutation counts, not native FPS/taint.
local sourcePath=arg[1]or"Core/BorderJunctions.lua"
local measure=arg[2]=="--measure"
local checks=0
local function check(ok,why)checks=checks+1;assert(ok,why)end
local function corrected(ok,why)if not measure then check(ok,why)end end
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a");f:close();return s end
local function replace(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(1,i-1)..b..s:sub(i+#a)end
local core=read(sourcePath).."\nreturn {clipped=clipped,sprites=sprites,FieldColor=FieldColor,FieldAlpha=FieldAlpha,FieldHide=FieldHide,geometry=J._FieldGeometry,source=Source,active=function()return active end,suppressed=function(texture)return renderBases and renderBases.suppressedSources and renderBases.suppressedSources[texture] end}"
local prefix=assert(read("tests/border_junctions.lua"):match("^(.-)local J=fixture%(%)"))
prefix=replace(prefix,'assert(load(read("Core/BorderJunctions.lua"),"@Core/BorderJunctions.lua","t",e))("_FluxUI",{Border=B})',
    'e.exports=assert(load('..string.format("%q",core)..',"@incremental-production-core","t",e))("_FluxUI",{Border=B})')
prefix=replace(prefix,'function(a,b)style=a;accent=b end,function()return #queue end,e',
    'function(a,b)style=a;accent=b end,function()return #queue end,e,m')
local fixture=assert(load(prefix.."\nreturn fixture","@incremental-production-fixture","t",_G))()
local function owner(field)
    local parent=field
    for _=1,20 do if not parent then break end;if parent.testName then return parent.testName end;parent=parent:GetParent()end
    return "unknown"
end
local function signature(objects)
    local rows={}
    for _,t in ipairs(objects)do if t.decorative and t.shown and t.size then
        local a={owner(t),t.path,t.alpha,t.parent:GetFrameStrata(),t.parent:GetFrameLevel()}
        for _,v in ipairs(t.uv)do a[#a+1]=v end
        for _,v in ipairs(t.size)do a[#a+1]=v end
        for _,v in ipairs(t.color)do a[#a+1]=v end
        for _,v in ipairs(t.point or{})do a[#a+1]=type(v)=="table"and owner(v)or v end
        for i=1,4 do for _,v in ipairs(t.vertices and t.vertices[i]or{})do a[#a+1]=v end end
        for i,v in ipairs(a)do if type(v)=="number"then a[i]=string.format("%.8f",v)end end
        rows[#rows+1]=table.concat(a,",")
    end end
    table.sort(rows);local text=table.concat(rows,";");local hash=0
    for i=1,#text do hash=(hash*257+text:byte(i))%2147483647 end
    return hash,#rows
end
for _,style in ipairs({1,2})do
    local j,new,piece,flush,objects,_,setStyle,_,e,m=fixture()
    setStyle(style,"class")
    local counts={total=0,unaffected=0,allocations=0}
    for _,name in ipairs({"SetTexture","SetTexCoord","ClearAllPoints","SetPoint","SetSize","SetVertexOffset","SetVertexColor","SetAlpha","Show","Hide","SetDrawLayer"})do
        local old=m[name]
        m[name]=function(self,...)
            if self.decorative then counts.total=counts.total+1;if owner(self)~="panel1"then counts.unaffected=counts.unaffected+1 end end
            if self.decorative and name=="Hide"and not self.shown then counts.redundantHides=(counts.redundantHides or 0)+1 end
            return old(self,...)
        end
    end
    local create=m.CreateTexture
    m.CreateTexture=function(self,...)
        if counts.fail then error("incremental allocator failure",0)end
        counts.allocations=counts.allocations+1;return create(self,...)
    end
    local parents,tops,verticals={},{},{}
    for i=1,8 do
        local p=new(e.UIParent);p.testName="panel"..i;parents[i]=p
        local x=i*400
        tops[i]=piece(p,"Top",{x,-9,220,17})
        verticals[i]={}
        for k=1,7 do verticals[i][k]=piece(p,"Left",{x+k*26-9,-40,16,80})end
    end
    flush();check(j.stats.triangles>100,"fixture prepares a real multi-panel mesh")
    local firstHash,firstFields=signature(objects)
    local solves=j.stats.solves
    counts.total,counts.unaffected,counts.allocations=0,0,0
    verticals[1][7].rect[1]=verticals[1][7].rect[1]+11
    j:Invalidate(nil,verticals[1][7]);flush()
    check(j.stats.solves==solves+1,"one real changed separator commits one new global plan")
    local hash,fields=signature(objects)
    check(hash~=firstHash and fields>100,"real reflow changes pixels while preserving the prepared mesh")
    corrected(counts.unaffected<fields,"small reflow avoids native mutations across most unrelated fields")
    corrected(counts.total<fields*5,"real reflow reuses unchanged owned geometry/material/paint")
    print(string.format("INCREMENTAL_WORK style=%d fields=%d beforeFields=%d writes=%d unrelated=%d allocations=%d mesh=%d beforeMesh=%d",
        style,fields,firstFields,counts.total,counts.unaffected,counts.allocations,hash,firstHash))
    -- A forced unchanged transaction must also reuse its exact setters.
    counts.total,counts.unaffected,counts.allocations=0,0,0;j:Invalidate(true);flush()
    check(signature(objects)==hash,"forced redraw keeps the same exact mesh")
    corrected(counts.total<fields,"forced identical plan performs fewer writes than owned fields")
    check(counts.allocations==0,"forced identical plan allocates no graphics")
    -- A source recolor can expose alpha. Its fields must get current RGB/alpha
    -- and remain correct after another geometry commit using old descriptors.
    tops[1]:SetVertexColor(.8,.2,.1,.35);flush()
    j:Invalidate(true);flush()
    for _,field in ipairs(e.exports.clipped[tops[1]].pool)do if field.shown and not field._fallbackBlockers then
        check(field.color[1]==.8 and field.color[2]==.2 and field.color[3]==.1 and field.alpha==.35,
            "recolor and SetVertexColor alpha remain current through cached commit")
    end end
    if not measure then
        local target
        for _,pool in pairs(e.exports.sprites)do if pool[1]then target=pool[1];break end end
        local source=target._junctionSource
        e.exports.FieldColor(target,.2,.3,.4,1)
        e.exports.FieldColor(target,.8,.7,.6,1)
        e.exports.FieldColor(target,.2,.3,.4,1)
        check(target.color[1]==.2 and target.color[2]==.3 and target.color[3]==.4,
            "direct owned RGB paint keeps descriptors current for public A to B to A")
        local private=setmetatable({}, {__eq=function()error("private RGB compared")end,
            __lt=function()error("private RGB ordered")end,__tostring=function()error("private RGB formatted")end})
        e.issecretvalue=function(value)return rawequal(value,private)end
        e.exports.FieldColor(target,private,private,private,1)
        check(target._junctionSetCache.color==nil,"opaque direct RGB clears its public descriptor")
        e.exports.FieldColor(target,.2,.3,.4,1)
        check(target._junctionSource==source and target.color[1]==.2 and target.color[2]==.3 and target.color[3]==.4,
            "private RGB to same-source public recovery cannot skip native repaint")
        target.alpha=private;e.exports.FieldAlpha(target,.5)
        check(target.alpha==.5,"private current alpha takes the public native setter path")
        local getAlpha=target.GetAlpha
        target.GetAlpha=function()error("opaque desired alpha must not read current alpha")end
        e.exports.FieldAlpha(target,private)
        check(rawequal(target.alpha,private),"opaque desired alpha goes directly to native sink")
        target.GetAlpha=getAlpha;e.exports.FieldAlpha(target,1)
        target.shown=private;e.exports.FieldHide(target)
        check(target.shown==false,"opaque current shown state always takes native Hide")
        e.issecretvalue=nil
        j:Invalidate(true);flush()
    end
    -- Full old and new generations must both be retired if allocation fails.
    for k=1,4 do piece(parents[1],"Left",{400+7+k*20,-40,16,80})end
    counts.fail=true
    local ok,err=pcall(flush)
    check(not ok and tostring(err):find("incremental allocator failure",1,true),"native allocation failure is surfaced")
    for _,top in ipairs(tops)do check(top.alpha~=0,"rollback restores original source alpha in old and new components")end
    for _,t in ipairs(objects)do if t.decorative then check(not t.shown,"rollback hides every old/new rendered field")end end
    counts.fail=nil;j:Invalidate(true);flush()
    check(j.stats.operations>0 and tops[1].alpha==0,"transaction remains retryable after rollback")
    parents[2]:SetAlpha(0);flush()
    check(tops[2].alpha~=0 and tops[1].alpha==0,"removed or blocked component cannot retain stale suppressed source")
    parents[2]:SetAlpha(1);flush()
    check(tops[2].alpha==0,"returning component rejoins through normal visibility lifecycle")
    for k=4,7 do verticals[1][k]:Hide()end;flush()
    local retired=0
    for _,t in ipairs(objects)do if t.decorative and t.size and not t.shown then retired=retired+1 end end
    check(retired>0,"smaller panel retains previously allocated hidden pool entries")
    counts.redundantHides=0
    verticals[3][2].rect[1]=verticals[3][2].rect[1]+5
    j:Invalidate(nil,verticals[3][2]);flush()
    corrected(counts.redundantHides==0,"later unrelated reflow does not hide already-retired pool fields again")
end
if not measure then
    local _,new,_,_,_,_,_,_,e=fixture()
    local parent=new(e.UIParent)
    local field=new(parent,nil,"Texture")
    field._junctionSetCache={}
    local box,vertices=e.exports.geometry.Box,e.exports.geometry.Vertices
    box(field,parent,4,5,12,8)
    local setPoint=field.SetPoint
    field.SetPoint=function()error("anchor writer failed",0)end
    local ok,err=pcall(box,field,parent,6,5,12,8)
    check(not ok and err=="anchor writer failed" and #field.anchors==0,"failed anchor write leaves native points cleared")
    field.SetPoint=setPoint
    box(field,parent,4,5,12,8)
    check(#field.anchors==1 and field.point[4]==4 and field.point[5]==5,"retry at the previous position restores the cleared native anchor")

    local setSize=field.SetSize
    field.SetSize=function(self,w,h)setSize(self,w,h);error("size writer failed",0)end
    ok,err=pcall(box,field,parent,4,5,15,8)
    check(not ok and err=="size writer failed" and field.size[1]==15,"failed size write can follow a partial native change")
    field.SetSize=setSize
    box(field,parent,4,5,12,8)
    check(field.size[1]==12 and field.size[2]==8,"retry keeps the old complete size and anchor")

    local setVertex=field.SetVertexOffset
    local writes=0
    field.SetVertexOffset=function(self,...)writes=writes+1;return setVertex(self,...)end
    vertices(field);vertices(field)
    check(writes==4,"warm rectangle retains all four offsets")
    local warp={a={.2,.3},b={.4,.6},c={.8,.5}}
    vertices(field,warp,20,10)
    check(writes==8 and field.vertices[1][1]==4 and field.vertices[1][2]==-3,"triangle writes all four exact offsets")
    vertices(field,warp,20,10)
    check(writes==8,"warm triangle retains all four offsets")
    field.SetVertexOffset=function(self,...)setVertex(self,...);error("vertex writer failed",0)end
    ok,err=pcall(vertices,field)
    check(not ok and err=="vertex writer failed" and field.vertices[1][1]==0,"partial rectangle write changes the native offset before failing")
    field.SetVertexOffset=setVertex
    vertices(field,warp,20,10)
    check(field.vertices[1][1]==4 and field.vertices[1][2]==-3,"retry restores prior triangle offset after a failed rectangle write")
    vertices(field)
    for i=1,4 do check(field.vertices[i][1]==0 and field.vertices[i][2]==0,"recycled rectangle resets native vertex offsets") end
    local readColor=field.GetVertexColor
    field.GetVertexColor=function()return .2,nil,.5,1 end
    check(e.exports.source(field)==nil,"missing RGBA channel cannot admit a public render source")
    field.GetVertexColor=readColor
    check(e.exports.source(field),"restored public RGBA can render normally")
end
if not measure then
    for _,watched in ipairs({true,false}) do
        local j,new,piece,flush,_,_,_,_,e,methods=fixture()
        if not watched then e.hooksecurefunc=nil end
        local parent=new(e.UIParent)
        parent._FluxBorderStatic=true
        local top,topRecord=piece(parent,"Top",{0,-9,120,17})
        local side,sideRecord=piece(parent,"Left",{40,-40,16,80})
        local art="Interface\\AddOns\\_FluxUI\\Texture\\borders\\Battlefield100.tga"
        topRecord.art,sideRecord.art=art,art
        top:SetTexture(art);side:SetTexture(art)
        flush()
        check(j.stats.localMode and top:GetAlpha()==0,"fixture clips the source in a regional commit")
        local write=methods.SetVertexOffset
        for _,mutate in ipairs({
            function() top:SetAlpha(.4) end,
            function() top:SetVertexColor(.8,.2,.1,.35) end,
        }) do
            local changed=false
            methods.SetVertexOffset=function(self,...)
                if not changed and self._junctionOwnerOp and e.exports.suppressed(top)~=nil then
                    check(top:GetAlpha()==0,"source is already suppressed when the mesh is written")
                    mutate()
                    changed=true
                    check(top:GetAlpha()~=0,"native callback rewrites the original source during paint")
                end
                return write(self,...)
            end
            side.rect[1]=side.rect[1]+5
            j:Invalidate(nil,side)
            flush()
            check(changed and top:GetAlpha()==0,
                "publication restores source suppression after native alpha or RGBA reentry")
        end
        methods.SetVertexOffset=write
    end
end
print("border incremental commit: "..checks.." checks passed"..(measure and" (measurement)"or""))
