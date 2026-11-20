-- Actual Core Draw/canvas/release code with native setters counted at the mock
-- boundary. Geometry/UV output is retained; these counts are not native FPS.
-- Supply an exact external Core source as arg[1] and --measure for old budgets.
local sourcePath = arg[1] or "Core/BorderJunctions.lua"
local measure = arg[2] == "--measure"
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function corrected(ok, why) if not measure then check(ok, why) end end
local function read(path) local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s end
local function replace(s, before, after)
    local i=assert(s:find(before,1,true),before)
    return s:sub(1,i-1)..after..s:sub(i+#before)
end
local core = read(sourcePath):gsub("\r\n", "\n")
-- Count actual free-pool probes in the loaded fixture only. The production
-- arrays, renderer, native method calls and search algorithm remain unchanged.
if core:find("local t=pool[free]",1,true) then
    core=replace(core,"local t=pool[free]","local t=pool[free];_G._poolVisits=(_G._poolVisits or 0)+1")
    core=replace(core,"free=free+1;t=pool[free]","free=free+1;t=pool[free];_G._poolVisits=(_G._poolVisits or 0)+1")
else
    core=replace(core,"for _,piece in ipairs(pool) do if not piece._junctionOwnerOp then t=piece;break end end",
        "for _,piece in ipairs(pool) do _G._poolVisits=(_G._poolVisits or 0)+1;if not piece._junctionOwnerOp then t=piece;break end end")
end
core=core..[[
return {Draw=Draw,CapCanvas=CapCanvas,JunctionCanvas=JunctionCanvas,sprites=sprites,
    JunctionLayer=JunctionLayer,setLayers=function(values)
        renderLayers=values and {native=values,members={}} or nil
    end,
    active=function()return active end,activate=function(op)active[#active+1]=op end}
]]
local prefix=assert(read("tests/border_junctions.lua"):match("^(.-)local J=fixture%(%)"))
prefix=replace(prefix,'assert(load(read("Core/BorderJunctions.lua"),"@Core/BorderJunctions.lua","t",e))("_FluxUI",{Border=B})',
    'e.exports=assert(load('..string.format("%q",core)..',"@actual-render-core","t",e))("_FluxUI",{Border=B})')
prefix=replace(prefix,'function(a,b)style=a;accent=b end,function()return #queue end,e',
    'function(a,b)style=a;accent=b end,function()return #queue end,e,m')
local fixture=assert(load(prefix.."\nreturn fixture","@renderer-production-fixture","t",_G))()

local function build()
    local j,new,piece,flush,objects,_,style,_,e,m=fixture()
    e.renderMethods=m
    local metrics={level=0,strata=0,textures=0,frames=0,sourceParents=0}
    local level,strata,texture,create=m.SetFrameLevel,m.SetFrameStrata,m.CreateTexture,e.CreateFrame
    m.SetFrameLevel=function(self,value)metrics.level=metrics.level+1;return level(self,value)end
    m.SetFrameStrata=function(self,value)metrics.strata=metrics.strata+1;return strata(self,value)end
    m.CreateTexture=function(self,name,layer,...)
        if metrics.failAt and (not metrics.failDrawOnly or layer=="OVERLAY") then
            metrics.failAt=metrics.failAt-1
            if metrics.failAt==0 then error("injected render-pool allocation failure",0)end
        end
        metrics.textures=metrics.textures+1;return texture(self,name,layer,...)
    end
    e.CreateFrame=function(...)metrics.frames=metrics.frames+1;return create(...)end
    local function reset()
        metrics.level,metrics.strata,metrics.textures,metrics.frames,metrics.sourceParents=0,0,0,0,0;e._poolVisits=0
    end
    local function group(name,rank,frameLevel)
        local p=new(e.UIParent);p.name=name;p.strata=rank or "MEDIUM";p.level=frameLevel or 10
        local t=piece(p,"Top",{0,0,120,17});t.path=name..".tga";t.color={.2,.5,.8,.7};t.alpha=.7
        local parent=t.GetParent
        function t:GetParent()metrics.sourceParents=metrics.sourceParents+1;return parent(self)end
        return {parent=p,id=#objects,priority=frameLevel or 10,pieces={{texture=t,record={key="Top"}}}},t
    end
    local function operation(label,g,t,other,count)
        local op={label=label,hs={group=g},members={[g]=true,[other]=true},root={},rect={12,16,44,48},triangles={}}
        for i=1,count do
            local x=(i%4)/8
            local triangle={texture=t,source={path=t.path},a={x,0,.1,.2},b={0,1,.3,.4},c={1,1,.5,.6}}
            if i%3==0 then triangle.quad={{x,0,.1,.2},{x,1,.3,.4},{1,0,.5,.6},{1,1,.7,.8}} end
            op.triangles[#op.triangles+1]=triangle
        end
        return op
    end
    local function draw(op)e.exports.activate(op);e.exports.Draw(op)end
    return j,e,metrics,group,operation,draw,reset,flush,new,piece,objects,style
end
local function mesh(e)
    local out={}
    for owner,pool in pairs(e.exports.sprites) do
        for index,t in ipairs(pool) do if t._junctionOwnerOp then
            local a={owner.name or (owner.parent and owner.parent.name) or "canvas",index,t._junctionOwnerOp.label,t.path,t.shown and 1 or 0,t.alpha,
                t.parent:GetFrameStrata(),t.parent:GetFrameLevel()}
            for _,v in ipairs(t.uv)do a[#a+1]=v end
            for _,v in ipairs(t.size)do a[#a+1]=v end
            for _,v in ipairs(t.color)do a[#a+1]=v end
            for _,v in ipairs(t.point)do
                if type(v)=="table"then a[#a+1]=v.parent and v.parent.name or "root"else a[#a+1]=v end
            end
            for i=1,4 do for _,v in ipairs(t.vertices[i])do a[#a+1]=v end end
            for i,v in ipairs(a)do if type(v)=="number"then a[i]=string.format("%.9f",v)end end
            out[#out+1]=table.concat(a,",")
        end end
    end
    table.sort(out);return table.concat(out,";")
end
local function digest(text)
    local hash=0;for i=1,#text do hash=(hash*257+text:byte(i))%2147483647 end;return hash
end

for _,count in ipairs({64,128,256})do
    local j,e,m,group,op,draw,reset=build()
    local a,t=group("source","MEDIUM",10);local b=group("higher","HIGH",80)
    reset();draw(op("first",a,t,b,count))
    check(#e.exports.sprites[a.parent]==count,"all triangle textures are allocated")
    local first=mesh(e)
    corrected(m.strata<=1 and m.level<=1,"one Draw resolves its shared canvas once and avoids identical native layer writes")
    corrected((e._poolVisits or 0)<=count,"cold free-pool lookup is linear")
    corrected(m.sourceParents==1,"one operation resolves an individual source's parent only once")
    local cold={level=m.level,strata=m.strata,visits=e._poolVisits,textures=m.textures,sourceParents=m.sourceParents}
    for _,texture in ipairs(e.exports.sprites[a.parent])do
        check(texture.path==t.path and texture.alpha==1 and texture.shown,"every rendered sprite retains path/visibility/opacity")
        check(texture.parent:GetFrameStrata()=="HIGH"and texture.parent:GetFrameLevel()==81,"canvas retains highest member layer")
    end
    j:ReleaseAll();reset();draw(op("first",a,t,b,count))
    check(mesh(e)==first,"warm pooled rendering preserves exact UV/vertices/anchors/tint/visibility")
    check(m.textures==0 and m.frames==0,"unchanged warm mesh reuses every graphic")
    corrected(m.strata==0 and m.level==0,"unchanged warm mesh performs zero native canvas layer writes")
    corrected(m.sourceParents==1,"repainting still reads each live parent once")
    corrected((e._poolVisits or 0)<=count,"warm free-pool lookup is linear")
    print(string.format("RENDER_POOL_WORK triangles=%d coldLevel=%d coldStrata=%d coldVisits=%d coldTextures=%d warmLevel=%d warmStrata=%d warmVisits=%d warmTextures=%d mesh=%d parents=%d/%d",
        count,cold.level,cold.strata,cold.visits,cold.textures,m.level,m.strata,e._poolVisits,m.textures,digest(first),cold.sourceParents,m.sourceParents))
end

do
    local j,e,m,group,op,draw,reset=build()
    local a,t=group("raised-source","MEDIUM",5)
    local b,u=group("unit-source","MEDIUM",11)
    b.parent._FluxBorderStatic=true
    local strip=group("strip","MEDIUM",15).parent
    local strata,stripReads=strip.GetFrameStrata,0
    function strip:GetFrameStrata()stripReads=stripReads+1;return strata(self)end
    local function mixed()
        local joined=op("strip-and-unit",a,t,b,96)
        joined.renderStrip,joined.renderLevel=strip,30
        for index=2,#joined.triangles,2 do
            joined.triangles[index].texture=u
            joined.triangles[index].source={path=u.path}
        end
        return joined
    end
    reset();draw(mixed())
    corrected(m.sourceParents==2 and stripReads==1,"mixed seam reads two native source parents and configures the strip canvas once")
    local first=mesh(e)
    local raised
    for canvas in pairs(e.exports.sprites) do if canvas.parent==strip then raised=canvas end end
    check(raised and raised:GetFrameLevel()==30 and #e.exports.sprites[raised]==48,"raised mesh fields share the strip canvas")
    check(#e.exports.sprites[b.parent]==48,"retained unit fields keep their own canvas and visibility")
    print(string.format("RENDER_STRIP_WORK fields=96 parents=%d stripReads=%d mesh=%d",m.sourceParents,stripReads,digest(first)))
    j:ReleaseAll()
    local moved=group("moved-unit","HIGH",60)
    moved.parent._FluxBorderStatic=true
    u:SetParent(moved.parent)
    local later=mixed();draw(later)
    check(#e.exports.sprites[moved.parent]==48,"a later operation follows the source to its current owner")
    for index=2,#later.sprites,2 do
        check(later.sprites[index].parent:GetParent()==moved.parent,"the old source context is never retained across draws")
    end
end

do
    local j,e,m,group,op,draw,reset=build()
    local a,t=group("shared","MEDIUM",5);local b=group("high","HIGH",70)
    local c,u=group("retained","MEDIUM",6);c.parent=a.parent
    u:SetParent(a.parent)
    local first,second=op("released",a,t,b,12),op("retained",c,u,b,12)
    draw(first);draw(second)
    local pool=e.exports.sprites[a.parent]
    local retained={};for _,texture in ipairs(second.sprites)do retained[texture]=true end
    j:ReleaseFor(t)
    check(#e.exports.active()==1 and e.exports.active()[1]==second,"partial release retains independent operation")
    for texture in pairs(retained)do check(texture._junctionOwnerOp==second and texture.shown,"partial release preserves live pool ownership")end
    reset();draw(op("replacement",a,t,b,12))
    check(m.textures==0 and #pool==24,"partial release resets cursor and reuses freed entries")
    for texture in pairs(retained)do check(texture._junctionOwnerOp==second,"free cursor never steals retained operation's sprite")end
    corrected((e._poolVisits or 0)<=24,"partial free search scans retained sprites at most once")
    local lower=group("lower","MEDIUM",2)
    draw(op("lower-op",a,t,lower,3))
    check(pool[1].parent:GetFrameStrata()=="HIGH"and pool[1].parent:GetFrameLevel()==71,"later lower operation cannot lower a required canvas")
    j:ReleaseAll();draw(op("fresh-lower",a,t,lower,3))
    check(pool[1].parent:GetFrameStrata()=="MEDIUM"and pool[1].parent:GetFrameLevel()==6,"full release resets accumulated layer requirements")
    local cap=e.exports.CapCanvas(a.parent);reset()
    check(e.exports.CapCanvas(a.parent)==cap,"rounded cap canvas is reused")
    corrected(m.level==0 and m.strata==0,"unchanged rounded cap performs zero native layer writes")
    a.parent.level=17;a.parent.strata="HIGH";e.exports.CapCanvas(a.parent)
    check(cap:GetFrameStrata()=="HIGH"and cap:GetFrameLevel()==19,"changed cap parent still updates its native layer")

    -- Current canvas getters can be restricted on a client. Only the desired
    -- addon-owned layer is public; unknown current values must take the setter
    -- path without an addon comparison/arithmetic on the private value.
    local private=setmetatable({}, {__lt=function()error("private layer ordered")end,
        __le=function()error("private layer ordered")end,__sub=function()error("private layer arithmetic")end})
    local privateChecks=0
    e.issecretvalue=function(value)if value==private then privateChecks=privateChecks+1;return true end;return false end
    local methods=e.renderMethods
    local getStrata,getLevel=methods.GetFrameStrata,methods.GetFrameLevel
    methods.GetFrameStrata=function(self)if self.privateLayerReads then return private end;return getStrata(self)end
    methods.GetFrameLevel=function(self)if self.privateLayerReads then return private end;return getLevel(self)end
    local junction=e.exports.JunctionCanvas(a.parent,{[a]=true,[lower]=true})
    cap.privateLayerReads=true;junction.privateLayerReads=true;reset()
    e.exports.CapCanvas(a.parent);e.exports.JunctionCanvas(a.parent,{[a]=true,[lower]=true})
    corrected(privateChecks==4,"both canvas comparators check private strata/level before comparing values")
    check(m.strata==2 and m.level==2,"unknown current canvas layer conservatively writes public desired values")
    cap.privateLayerReads=nil;junction.privateLayerReads=nil
    check(cap:GetFrameStrata()=="HIGH"and cap:GetFrameLevel()==19
        and junction:GetFrameStrata()=="HIGH"and junction:GetFrameLevel()==18,"private getter fallback retains intended public layer")
end

do
    local j,e,m,group=build()
    local layer=e.exports.JunctionLayer
    if layer then
        local groups={
            group("low","LOW",14),group("medium","MEDIUM",91),group("dialog","DIALOG",32),
            group("dialog-higher","DIALOG",58),group("tooltip","TOOLTIP",80),(group("high","HIGH",120)),
        }
        local snapshot={}
        local ranks={LOW=1,MEDIUM=2,HIGH=3,DIALOG=4,TOOLTIP=4}
        for _,g in ipairs(groups) do
            local p=g.parent
            snapshot[p]={strata=p.strata,rank=ranks[p.strata],level=p.level}
        end
        local sets={{}}
        for i=1,#groups do
            local members={}
            for j=1,i do members[groups[j]]=true end
            sets[#sets+1]=members
        end
        for _,members in ipairs(sets) do
            for _,g in ipairs(groups) do
                e.exports.setLayers()
                local strata,rank,level=layer(g.parent,members)
                e.exports.setLayers(snapshot)
                local s,r,l=layer(g.parent,members)
                check(s==strata and r==rank and l==level,
                    "public commit layers match the original rule, including equal-rank native strata")
            end
        end
        local parent=groups[1].parent
        local other=groups[6].parent
        snapshot[other]=nil
        e.exports.setLayers(snapshot)
        local s,r,l=layer(parent,{[groups[6]]=true})
        check(s=="HIGH" and r==3 and l==120,"a group absent from the snapshot retains live layer resolution")
        j:ReleaseAll()
        parent.level=33
        local _,_,updated=layer(parent,{})
        check(updated==33,"release discards the old participant layer snapshot")
    end
end

-- Run the real transaction failure path as well: a failed native allocation
-- must release every partially claimed sprite and remain retryable afterward.
do
    local j,e,m,_,_,_,_,flush,new,piece,objects=build()
    local p=new(e.UIParent);local h=piece(p,"Top",{0,-9,120,17})
    for i=1,4 do piece(p,"Left",{10+i*20-9,-40,16,80})end
    m.failAt=5;m.failDrawOnly=true
    local ok,err=pcall(flush)
    check(not ok and tostring(err):find("injected render-pool allocation failure",1,true),"actual Flush surfaces allocator failure")
    check(h.alpha==1,"failed render restores source opacity")
    for _,object in ipairs(objects)do if object.decorative then check(not object.shown,"error cleanup hides partial graphics")end end
    local pooled=0
    for _,pool in pairs(e.exports.sprites)do
        pooled=pooled+#pool
        corrected(pool.freeIndex==1,"error cleanup resets every free cursor")
        for _,texture in ipairs(pool)do check(not texture._junctionOwnerOp,"error cleanup releases partial sprite claims")end
    end
    check(pooled>0,"injected allocation failure occurs after actual Draw claimed pooled sprites")
    m.failAt=nil;j:Invalidate(true);flush()
    check(j.stats.operations>0 and h.alpha==0,"allocation retry can rebuild the complete mesh")
    for _,pool in pairs(e.exports.sprites)do
        local used={};for _,texture in ipairs(pool)do if texture._junctionOwnerOp then
            check(not used[texture],"retry assigns a sprite once");used[texture]=true
        end end
    end
end
print(string.format("border render pool work: %d checks passed%s",checks,measure and " (measurement)"or""))
