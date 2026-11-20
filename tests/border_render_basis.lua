-- Actual hidden-unit render parents and production commit. Count native basis
-- reads separately from the geometry phase; exact output is not a native FPS test.
local sourcePath=arg[1]or"Core/BorderJunctions.lua"
local measure=arg[2]=="--measure"
local checks=0
local function check(ok,why)checks=checks+1;assert(ok,why)end
local function corrected(ok,why)if not measure then check(ok,why)end end
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a");f:close();return s end
local function replace(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(1,i-1)..b..s:sub(i+#a)end
local core=read(sourcePath):gsub("\r\n","\n")
core=replace(core,"cache.color={r,g,b,a}","cache.color={r,g,b,a};_G.colorTuples=(_G.colorTuples or 0)+1")
core=core.."\nreturn {paint=FieldPaint,bases=function()return renderBases end}"
local prefix=assert(read("tests/border_junctions.lua"):match("^(.-)local J=fixture%(%)"))
prefix=replace(prefix,'assert(load(read("Core/BorderJunctions.lua"),"@Core/BorderJunctions.lua","t",e))("_FluxUI",{Border=B})',
    'e.exports=assert(load('..string.format("%q",core)..',"@basis-production-core","t",e))("_FluxUI",{Border=B})')
prefix=replace(prefix,'function(a,b)style=a;accent=b end,function()return #queue end,e',
    'function(a,b)style=a;accent=b end,function()return #queue end,e,m')
local fixture=assert(load(prefix.."\nreturn fixture","@hidden-render-basis-fixture","t",_G))()
local function digest(objects)
    local rows={}
    for _,t in ipairs(objects)do if t.decorative and t.shown and t.size then
        local a={t.path,t.alpha,t.parent:GetFrameStrata(),t.parent:GetFrameLevel()}
        for _,v in ipairs(t.uv)do a[#a+1]=v end
        for _,v in ipairs(t.size)do a[#a+1]=v end
        for _,v in ipairs(t.point or{})do if type(v)~="table"then a[#a+1]=v end end
        for i=1,4 do for _,v in ipairs(t.vertices and t.vertices[i]or{})do a[#a+1]=v end end
        for i,v in ipairs(a)do if type(v)=="number"then a[i]=string.format("%.8f",v)end end
        rows[#rows+1]=table.concat(a,",")
    end end
    table.sort(rows);local s=table.concat(rows,";");local h=0
    for i=1,#s do h=(h*257+s:byte(i))%2147483647 end
    return h,#rows
end
for _,style in ipairs{1,2}do
    local j,new,piece,flush,objects,_,choose,_,e,m=fixture();choose(style,"class")
    local counts={left=0,bottom=0,rect=0,scale=0}
    local create=e.CreateFrame
    e.CreateFrame=function(...)
        local canvas=create(...)
        local point=canvas.GetPoint
        function canvas:GetPoint(i)local p,r,rp,x,y=point(self,i);if p then return p,r,rp,x or 0,y or 0 end end
        function canvas:GetLeft()if self._requiredRank then counts.left=counts.left+1;return end;return m.GetLeft(self)end
        function canvas:GetBottom()if self._requiredRank then counts.bottom=counts.bottom+1;return end;return m.GetBottom(self)end
        function canvas:GetRect()if self._requiredRank then counts.rect=counts.rect+1;return end;return m.GetRect(self)end
        local scale=canvas.GetEffectiveScale
        function canvas:GetEffectiveScale()if self._requiredRank then counts.scale=counts.scale+1 end;return scale(self)end
        return canvas
    end
    local regions={}
    local function hidden(region,w,h)
        function region:GetRect()end
        function region:GetLeft()end
        function region:GetBottom()end
        if w then function region:GetSize()return w,h end end
        regions[#regions+1]=region;return region
    end
    local root=hidden(new(e.UIParent),400,120);root.unit="focus";root._FluxBorderStatic=true
    root:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",200,100);root:Hide()
    local host=hidden(new(root));host._FluxBorderOwner=root;host:SetAllPoints(root)
    host.anchors={{"TOPLEFT",root,"TOPLEFT",0,0},{"BOTTOMRIGHT",root,"BOTTOMRIGHT",0,0}}
    local top=hidden(piece(host,"Top",{0,0,360,17}),360,17)
    top:SetPoint("TOPLEFT",host,"TOPLEFT",20,-2)
    local edges={}
    for i=1,12 do
        local edge=hidden(piece(host,"Left",{0,0,16,55}),16,55)
        edge:SetPoint("TOPLEFT",host,"TOPLEFT",20+i*26,-2);edges[i]=edge
    end
    flush();check(j.stats.triangles>100,"shared hidden render parent produces a real dense mesh")
    local first,fields=digest(objects)
    corrected(counts.left<=1 and counts.bottom<=1 and counts.rect<=1,
        "hidden configured render parent resolves origin once per commit")
    corrected(counts.scale<=8,"hidden shared render parent basis reads stay bounded")
    print(string.format("RENDER_BASIS_WORK style=%d fields=%d left=%d bottom=%d rect=%d scale=%d mesh=%d",
        style,fields,counts.left,counts.bottom,counts.rect,counts.scale,first))
    check(e.exports.bases()==nil,"successful commit releases public basis memo")
    for key in pairs(counts)do counts[key]=0 end
    for _,region in ipairs(regions)do region.scale=.75 end
    root:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",210,104)
    j:Invalidate(true);flush()
    local scaled=digest(objects)
    check(scaled==first and counts.left>0,"changed scale/origin recompute basis and preserve exact local coordinates")
    corrected(counts.left<=1 and counts.bottom<=1 and counts.rect<=1,"scale change uses a fresh bounded commit basis")
    local replacement=hidden(new(e.UIParent),400,120);replacement._FluxBorderStatic=true;replacement.unit="focus"
    replacement:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",350,150)
    replacement.scale=.75
    for key in pairs(counts)do counts[key]=0 end
    host:SetParent(replacement);host._FluxBorderOwner=replacement;host:SetAllPoints(replacement)
    host.anchors={{"TOPLEFT",replacement,"TOPLEFT",0,0},{"BOTTOMRIGHT",replacement,"BOTTOMRIGHT",0,0}}
    j:Invalidate(true);flush()
    check(digest(objects)==scaled and counts.left>0,"reparenting reads a fresh basis and preserves exact local coordinates")
    check(e.exports.bases()==nil,"reparent commit clears its basis after use")
    local oldCreate=m.CreateTexture;m.CreateTexture=function()error("basis allocation failure",0)end
    for i=1,6 do
        local edge=hidden(piece(host,"Left",{0,0,16,55}),16,55)
        edge.scale=.75;edge:SetPoint("TOPLEFT",host,"TOPLEFT",28+i*31,-2)
    end
    local ok,err=pcall(flush)
    check(not ok and tostring(err):find("basis allocation failure",1,true),"real rendering allocator failure is surfaced")
    check(e.exports.bases()==nil,"failed commit and rollback release the basis memo")
    m.CreateTexture=oldCreate;j:Invalidate(true);flush()
    check(j.stats.triangles>100 and e.exports.bases()==nil,"error cleanup leaves later hidden-parent render retryable")
    j:ReleaseAll();check(e.exports.bases()==nil,"explicit release has no retained basis")
    if not measure then
        local parent
        for _,field in ipairs(objects)do if field.decorative and field.size then parent=field:GetParent();break end end
        local private=setmetatable({}, {__div=function()error("private basis arithmetic")end,
            __mul=function()error("private basis arithmetic")end,__tostring=function()error("private basis formatted")end})
        e.issecretvalue=function(v)return rawequal(v,private)end
        local getScale=parent.GetEffectiveScale;parent.GetEffectiveScale=function()return private end
        j:Invalidate(true)
        local publicOk,publicErr=pcall(flush)
        check(not publicOk and tostring(publicErr):find("Unavailable public junction render basis",1,true),
            "private render scale fails before arithmetic or memo retention")
        check(e.exports.bases()==nil,"private basis error clears the render epoch memo")
        parent.GetEffectiveScale=getScale;e.issecretvalue=nil;j:Invalidate(true);flush()
        check(e.exports.bases()==nil and top.alpha==0,"private basis failure remains retryable after public recovery")
    end

    local paint=e.exports.paint
    local target={textures=0,layers=0,colors=0}
    function target:SetTexture(path) self.textures=self.textures+1;self.path=path end
    function target:SetDrawLayer(...) self.layers=self.layers+1;self.layerArgs=table.pack(...) end
    function target:SetVertexColor(...) self.colors=self.colors+1;self.colorArgs=table.pack(...) end
    e.colorTuples=0
    for _=1,1000 do
        paint.Texture(target,"border.tga")
        paint.Layer(target,"ARTWORK",nil)
        paint.Color(target,.2,.5,.8,1)
    end
    check(target.textures==1 and target.layers==1 and target.colors==1,
        "identical material, layer and RGBA paints each write once")
    corrected(e.colorTuples==1,"one thousand identical RGBA paints allocate one cached tuple")
    check(target.layerArgs.n==2 and target.layerArgs[1]=="ARTWORK" and target.layerArgs[2]==nil,
        "native layer writer preserves the explicit nil sublevel")
    check(target.colorArgs.n==4 and target.colorArgs[4]==1,"native color writer preserves RGBA")
    print(string.format("FIELD_PAINT_WORK style=%d calls=1000 nativeColors=%d colorTuples=%d",style,target.colors,e.colorTuples))
    target._junctionSetCache.uv={0,1,0,1}
    paint.Texture(target,"new-border.tga")
    paint.Layer(target,"ARTWORK",0)
    paint.Color(target,.2,.5,.8,0)
    check(target.textures==2 and target.path=="new-border.tga" and target._junctionSetCache.uv==nil,
        "material changes invalidate cached texture sampling")
    check(target.layers==2 and target.layerArgs[2]==0,"a changed sublevel reaches the native writer")
    check(target.colors==2 and target.colorArgs[4]==0,"a changed alpha reaches the native writer")
end
print("border render basis: "..checks.." checks passed"..(measure and" (measurement)"or""))
