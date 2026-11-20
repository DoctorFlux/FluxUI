-- Compare the production regional planning code with a matched source baseline.
-- Without a baseline, use an independent all-pairs routing oracle.
local function read(path)
    local file=assert(io.open(path,"rb"))
    local source=file:read("*a"):gsub("\r\n","\n")
    file:close()
    return source
end

local function bind(path)
    local source=read(path)
    local clip=assert(source:match("(local function ClipField.-)\nlocal function UVPoint"))
    local spatial=assert(source:match("(local Spatial={size=128.-)\nfunction Spatial.Hide"))
    spatial=spatial:gsub("_castPlane","_scopePlane")
    local checks={intersection=0,queries=0,owners=0,planes=0,halo=0,polygons=0}
    local env=setmetatable({floor=math.floor,min=math.min,max=math.max,abs=math.abs,unpack=table.unpack,
        capSides={TL=true},Intersects=function(a,b)
            checks.queries=checks.queries+1
            return a[1]<b[3] and a[3]>b[1] and a[2]<b[4] and a[4]>b[2]
        end,CountClipPlane=function() checks.planes=checks.planes+1 end,
        CountHalo=function() checks.halo=checks.halo+1 end,
        CountTilePolygon=function() checks.polygons=checks.polygons+1 end},{__index=_G})
    clip=clip:gsub("local function ClipField%(poly,axis,limit,keepAbove%)",
        "local function ClipField(poly,axis,limit,keepAbove) CountClipPlane()",1)
    spatial=spatial:gsub("function Spatial.TouchesHalo%(batch,rect,padding%)",
        "function Spatial.TouchesHalo(batch,rect,padding) CountHalo()",1)
    spatial=spatial:gsub("for _,tile in ipairs%(tiles%) do\n(%s+if rect%[1%])",
        "for _,tile in ipairs(tiles) do CountHalo()\n%1",1)
    spatial=spatial:gsub("    local poly=", "    CountTilePolygon();local poly=", 1)
    local route=assert(load(clip.."\n"..spatial.."\nreturn Spatial","@production-region-routing","t",env))()
    local intersection=route.Intersection
    function route.Intersection(...)
        checks.intersection=checks.intersection+1
        return intersection(...)
    end
    local owners=route.Owners
    function route.Owners(...)
        checks.owners=checks.owners+1
        return owners(...)
    end
    return route,checks
end

local raw,operations,plans,sources={},{},{},{}
local function group(plane,rects)
    local g={id=#raw+1,parent={},pieces={},plane=plane or "hud",castSection=plane~=nil,scale=1}
    for _,rect in ipairs(rects) do
        local item={texture=#raw+1,rect=rect,record={key=rect.key or "Top"}}
        g.pieces[#g.pieces+1]=item
        raw[#raw+1]={group=g,item=item,texture=item.texture,rect=rect}
        sources[item.texture]={id=item.texture}
        if rect.clip then plans[item.texture]={item=item,rects={rect},fallbackRects={{rect=rect,blockers={-1}}}} end
    end
    return g
end
for row=0,4 do
    for column=0,7 do
        local x,y=column*78-290,row*36-124
        group(nil,{{x,y,x+73,y+10},{x+62,y+6,x+73,y+35},{x,y+30,x+73,y+35,key="TL"}})
    end
end
local strip=group(nil,{{-1024,-3,2000,3,clip=true}})
local cast=group("visible-cast",{{-120,-11,230,11},{-132,-11,-120,11,key="TL",clip=true}})
group("unaffected-cast",{{-190,-40,120,40}})
local thin=group(nil,{{-128,-4,-128+1e-11,2,clip=true},{0,-4,0,2}})
local arm=group(nil,{{200,-40,208,-10}})
local function op(g,texture,rect)
    operations[#operations+1]={bits=7,hs={group=g},rect=rect,
        triangles={{texture=texture,source=sources[texture],arm=1,a={0,0,0,0},b={0,1,0,1},c={1,1,1,1}}},fallbackTriangles={}}
end
op(strip,arm.pieces[1].texture,{117,-10,142,11})
op(thin,thin.pieces[1].texture,{-130,-6,-128+1e-11,4})
op(cast,cast.pieces[2].texture,{-132,-11,-100,11})
local regions={cast={-134,-11,128,11,_scopePlane="visible-cast"}}
for x=-3,3 do
    for y=-1,1 do
        regions[x..":"..y]={x*128,y*128,(x+1)*128,(y+1)*128}
    end
end

local function fingerprint(cells)
    local rows={}
    for key,cell in pairs(cells) do
        for _,p in ipairs(cell.plans) do
            local parts={key,p.item.texture}
            for _,rect in ipairs(p.rects) do parts[#parts+1]=table.concat(rect,",") end
            for _,r in ipairs(p.fallbackRects) do parts[#parts+1]=table.concat(r.rect,",").."/"..table.concat(r.blockers,",") end
            rows[#rows+1]=table.concat(parts,"|")
        end
        for _,op in ipairs(cell.operations) do
            for _,t in ipairs(op.triangles) do
                rows[#rows+1]=table.concat({key,"T",t.texture,table.concat(t.a,","),table.concat(t.b,","),table.concat(t.c,",")},"|")
            end
        end
    end
    table.sort(rows)
    return table.concat(rows,"\n"),#rows
end

local function prepare(spatial,oracle)
    local selected=spatial.Query(raw,regions)
    local cells={}
    if spatial.RouteRegions then
        local owners=spatial.Owners(selected)
        local batches,items=spatial.RouteRegions(regions,owners,operations)
        if oracle then
            local function overlaps(a,b)
                return math.min(a[3],b[3])>math.max(a[1],b[1]) and math.min(a[4],b[4])>math.max(a[2],b[2])
            end
            for _,batch in pairs(batches) do
                local function allowed(g)
                    return g.castSection and g.plane==batch.rect._scopePlane or not g.castSection and not batch.rect._scopePlane
                end
                local pieces,ops=0,0
                for _,g in pairs(owners) do if allowed(g) then
                    for _,p in ipairs(g.pieces) do if overlaps(p.rect,batch.rect) then pieces=pieces+1 end end
                end end
                for _,op in ipairs(operations) do if allowed(op.hs.group) and overlaps(op.rect,batch.rect) then ops=ops+1 end end
                assert(#batch.pieces==pieces and #batch.operations==ops,"regional routing matches exact overlap and cast-plane eligibility")
            end
        end
        for key,batch in pairs(batches) do cells[key]=spatial.PrepareCell(batch,selected,plans,sources,items) end
    else
        for key,rect in pairs(regions) do cells[key]=spatial.PrepareCell(rect,selected,operations,plans,sources) end
    end
    return cells
end

local current,currentWork=bind("Core/BorderJunctions.lua")
local cells=prepare(current,true)
local result,fields=fingerprint(cells)
assert(fields>0 and result:find("|T|",1,true),"replay contains clipped source pieces, fallback rectangles and triangles")
local castOnly=fingerprint({cast=cells.cast})
assert(castOnly:find("cast|T|",1,true) and not castOnly:find("cast|1|",1,true),"cast scope retains its local junction without HUD fields")
local function retainedGroupWork(spatial)
    local reads=0
    local border={parent={},scale=1,pieces={{texture={},rect={0,0,24,10}}}}
    setmetatable(border,{__index=function() reads=reads+1 end})
    local unchanged={[1]=border}
    local dirty={}
    assert(spatial.Changed(unchanged,unchanged,dirty) and not next(dirty))
    return reads
end
assert(retainedGroupWork(current)==0,"a retained immutable group skips its geometry comparison")
local beforeCast=group("moving-cast",{{10,20,30,40}})
local afterCast=group("moving-cast",{{20,10,40,30}})
local castScope={_scopePlane="moving-cast"}
current.ScopeBounds({cast=castScope,["scope:moving-cast"]=castScope},
    {[afterCast.id]=afterCast},{[beforeCast.id]=beforeCast})
assert(table.concat(castScope,",")=="-31,-31,81,81","cast scope includes both the existing and changed pieces")
local moved={parent=beforeCast.parent,scale=1,pieces={{texture=beforeCast.pieces[1].texture,rect={80,20,120,40}}},
    castSection=true,plane=beforeCast.plane}
local dirty={}
assert(current.Changed({[1]=beforeCast},{[1]=moved},dirty) and dirty["scope:moving-cast"],
    "changed geometry still invalidates its local scope")
local function clippedFields(spatial,metrics)
    local fields={}
    local op={rect={-2.125,-2.375,2.875,2.625}}
    local triangle={a={0,0,.1,.1},b={0,1,.3,.5},c={1,0,.6,.7},texture="test",arm=1}
    local quad={triangle.a,triangle.b,triangle.c,{1,1,.9,1}}
    local cells={{-10,-10,10,10},{-2.125,-2.375,2.875,2.625},{-10,-10,.375,10},
        {-.125,0,1,1},{-10,-10,10,-2.375},{0,0,4,4},{2.875,-10,10,10},{3,-10,10,10}}
    local before=metrics.planes
    local skewed={quad[1],quad[2],{.85,.05,.6,.7},quad[4]}
    local degenerate={a=triangle.a,b=triangle.b,c=triangle.b,texture="test",arm=1}
    for _,field in ipairs({triangle,degenerate,{quad=quad},{quad=skewed}}) do
        for _,cell in ipairs(cells) do
            local output={}
            spatial.ClipTriangle(field,op,cell,output)
            if field==degenerate and cell==cells[1] then
                assert(#output==0,"contained degenerate fields produce no paint")
            elseif field.quad==skewed and cell==cells[1] then
                assert(#output==2 and not output[1].quad,"contained nonrectangular quads keep the original triangle fan")
            end
            fields[#fields+1]=tostring(#output)
            for _,t in ipairs(output) do
                for _,point in ipairs(t.quad or {t.a,t.b,t.c}) do
                    fields[#fields+1]=string.format("%.17g|%.17g|%.17g|%.17g",table.unpack(point))
                end
            end
        end
    end
    return table.concat(fields,"\n"),metrics.planes-before
end
local clipped,planeCalls=clippedFields(current,currentWork)
assert(planeCalls>0 and planeCalls<128,"fields skip contained clipping planes")

local function splitTileFields(spatial,metrics)
    local fields={}
    local planeStart,polyStart=metrics.planes,metrics.polygons
    local cells={{-64,-64,0,0},{0,-64,64,0},{-64,0,0,64},{0,0,64,64}}
    local op={rect={-30.125,-29.875,37.375,44.625}}
    for n=1,248 do
        local x,y=((23*n)%100)/100,((37*n)%100)/100
        local l,t,r,b=x-.13,y-.1,x+.13,y+.1
        local a,c,d,e={l,t,.13,.28},{l,b,.23,.32},{r,t,.48,.64},{r,b,.82,.89}
        if n>240 then
            -- Adjacent floating-point coordinates and seams on the axes.
            local edge=(0-op.rect[1])/(op.rect[3]-op.rect[1])
            local fuzz=({-1e-17,0,1e-17,1e-12})[1+n%4]
            a[1],c[1],d[1],e[1]=edge+fuzz,edge+fuzz,edge+fuzz+.02,edge+fuzz+.02
        end
        local field={a=a,b=c,c=e,texture="split",arm=2,fallbackBlockers={"underlay"}}
        if n%3==0 then field.quad={a,c,d,e} end
        for _,cell in ipairs(cells) do
            local out={}
            spatial.ClipTriangle(field,op,cell,out)
            fields[#fields+1]=tostring(#out)
            for _,piece in ipairs(out) do
                assert(piece.texture==field.texture and piece.fallbackBlockers==field.fallbackBlockers)
                fields[#fields+1]=piece.quad and "Q" or "T"
                for _,p in ipairs(piece.quad or {piece.a,piece.b,piece.c}) do
                    fields[#fields+1]=string.format("%.17g|%.17g|%.17g|%.17g",table.unpack(p))
                end
            end
        end
    end
    return table.concat(fields,"\n"),metrics.polygons-polyStart,metrics.planes-planeStart
end
local split,splitPolygons,splitPlanes=splitTileFields(current,currentWork)
assert(splitPolygons>0 and splitPolygons<500,"only fields touching the destination tile allocate clipping polygons")

local function operationScopes(spatial,metrics)
    local scope={cast={-130,-20,190,30,_scopePlane="visible-cast"}}
    for x=-7,8 do
        for y=-6,6 do
            if (x+y)%3~=0 then scope[x..":"..y]={x*128,y*128,(x+1)*128,(y+1)*128} end
        end
    end
    local index=spatial.IndexRegions and spatial.IndexRegions(scope)
    local cases={
        {hs={group=strip},rect={-1024,-3,2000,3}},
        {members={[strip]=true},rect={128,-5,128,5}},
        {hs={group=cast},rect={10000,10000,10080,10080}},
        {members={[{plane="invisible-cast",castSection=true}]=true},rect={1,1,9,9}},
    }
    for n=1,400 do
        local x=(n*137)%2300-1150
        local y=(n*163)%1700-850
        cases[#cases+1]={hs={group=strip},rect={x,y,x+8+n%35,y+4+n%49}}
    end
    local start=metrics.queries
    local affected={}
    for i,op in ipairs(cases) do
        local actual
        if index then actual=spatial.Affects(op,index)
        else for _,r in pairs(scope) do if spatial.Affects(op,r) then actual=true;break end end end
        local g=op.hs and op.hs.group or next(op.members)
        local a=op.rect
        local expected=false
        for _,b in pairs(scope) do
            if b._scopePlane then
                expected=expected or (g.castSection and g.plane==b._scopePlane)
            elseif not g.castSection then
                expected=expected or (a[1]<b[3] and a[3]>b[1] and a[2]<b[4] and a[4]>b[2])
            end
        end
        assert((actual and true or false)==expected,"operation scope preserves mixed cast and HUD membership")
        if actual then affected[#affected+1]=i end
    end
    return table.concat(affected,","),metrics.queries-start
end
local affected,scopeChecks=operationScopes(current,currentWork)
assert(scopeChecks<1000,"operation scope only visits candidate dirty tiles")
local function neighborSelection(spatial,metrics)
    local scope={cast={-130,-20,190,30,_scopePlane="local-cast"}}
    for x=-8,8 do
        for y=-3,3 do
            if (x+y)%3~=0 then scope[x..":"..y]={x*128,y*128,(x+1)*128,(y+1)*128} end
        end
    end
    local segments={}
    local function add(pieces,scale,plane)
        local g={id=#segments+1,parent={},pieces={},plane=plane or "hud",castSection=plane~=nil,scale=scale}
        for _,rect in ipairs(pieces) do
            local item={texture=#segments+1,rect=rect}
            g.pieces[#g.pieces+1]=item
            segments[#segments+1]={group=g,item=item,texture=item.texture,rect=rect}
        end
    end
    -- Select the complete source group when any one of its edges touches.
    for i=1,320 do
        local x=(i*137)%5000-2500
        local y=(i*163)%2200-1100
        add({{x,y,x+32,y+6},{x+26,y,x+32,y+30}},({.75,1,1.25,1.33})[1+i%4])
    end
    add({{-4096,-8,4096,8},{2048,2048,2080,2056}},.75)
    add({{2048,2048,2080,2056}},1,"local-cast")
    add({{0,0,2,2}},1,"other-cast")
    for _,scale in ipairs({.75,1,1.25,1.33}) do
        local padding=scale*40+1
        for _,delta in ipairs({-1e-11,0,1e-11}) do
            add({{128+padding+delta,0,130+padding+delta,2}},scale)
            add({{-130-padding+delta,0,-128-padding+delta,2}},scale)
            add({{0,128+padding+delta,2,130+padding+delta}},scale)
            add({{0,-130-padding+delta,2,-128-padding+delta}},scale)
        end
    end
    local start=metrics.halo
    local actual=spatial.Query(segments,scope)
    local calls=metrics.halo-start
    local expected={}
    local groups=spatial.Owners(segments)
    for _,g in pairs(groups) do
        local pad=g.scale*40+1
        for _,r in pairs(scope) do
            if g.castSection then
                if g.plane==r._scopePlane then expected[g]=true end
            elseif not r._scopePlane then
                for _,p in ipairs(g.pieces) do
                    local a=p.rect
                    if a[1]<r[3]+pad and a[3]>r[1]-pad and a[2]<r[4]+pad and a[4]>r[2]-pad then expected[g]=true end
                end
            end
        end
    end
    local index=1
    local selected={}
    for _,s in ipairs(segments) do
        if expected[s.group] then
            assert(actual[index] and actual[index].texture==s.texture,"halo selection preserves source order and complete groups")
            selected[#selected+1]=s.texture
            index=index+1
        end
    end
    assert(index==#actual+1,"halo selection matches the all-pairs oracle")
    assert(calls>0,"halo checks were counted")
    return table.concat(selected,","),calls,#segments
end
local neighbors,neighborChecks,sourceCount=neighborSelection(current,currentWork)
assert(neighborChecks<sourceCount,"selection tests only nearby dirty tiles")
do
    local localGroup={id=1,parent={},plane="local-cast",castSection=true,scale=1,pieces={}}
    local distant={id=2,parent={},plane="other-cast",castSection=true,scale=1,pieces={}}
    local source={}
    for i,g in ipairs({localGroup,distant,localGroup,localGroup}) do
        local item={texture=i,rect={i,0,i+2,2}}
        g.pieces[#g.pieces+1]=item
        source[#source+1]={group=g,item=item,texture=i,rect=item.rect}
    end
    local scope={cast={-10,-10,10,10,_scopePlane="local-cast"}}
    local raw,owners,runs=current.Copy(source,true,true)
    assert(#runs==3 and runs[1]==1 and runs[2]==2 and runs[3]==3,"all contiguous runs are indexed in raw order")
    local indexed=current.Query(raw,scope,owners,nil,true,runs)
    local ordinary=current.Query(raw,scope,owners,nil,true)
    assert(#indexed==3 and #ordinary==#indexed,"both contact paths select every segment of the local group")
    for i,segment in ipairs(ordinary) do
        assert(indexed[i]==segment,"separate runs for the same group retain exact source order")
    end
end
local function work(metrics)
    return string.format("query=%d rect=%d owners=%d",metrics.queries,metrics.intersection,metrics.owners)
end
print("REGION_ROUTE after "..work(currentWork).." outputFields="..fields)
if arg[1] then
    local baseline,beforeWork=bind(arg[1])
    assert(fingerprint(prepare(baseline))==result,"every prepared field matches the archived renderer")
    print("REGION_ROUTE retainedGroupMetadataReads="..retainedGroupWork(baseline).."/"..retainedGroupWork(current))
    local before,beforePlanes=clippedFields(baseline,beforeWork)
    assert(before==clipped,"clipped triangles and quads retain exact vertices and UVs")
    print("REGION_ROUTE tileClipPlanes="..beforePlanes.."/"..planeCalls)
    local oldSplit,oldPolygons,oldPlanes=splitTileFields(baseline,beforeWork)
    assert(oldSplit==split,"split tile geometry, order, boundaries and UVs match archived clipping")
    print(string.format("REGION_TILE_FIELDS polygons=%d/%d planes=%d/%d",oldPolygons,splitPolygons,oldPlanes,splitPlanes))
    local beforeAffected,beforeChecks=operationScopes(baseline,beforeWork)
    assert(beforeAffected==affected,"indexed selection retains every affected operation in order")
    print("REGION_SCOPE intersectionChecks="..beforeChecks.."/"..scopeChecks)
    local oldNeighbors,oldNeighborChecks=neighborSelection(baseline,beforeWork)
    assert(oldNeighbors==neighbors,"both versions select the same neighboring source groups")
    print("REGION_NEIGHBORS sourceSegments="..sourceCount.." overlapChecks="..oldNeighborChecks.."/"..neighborChecks)
    print("REGION_ROUTE before "..work(beforeWork).." outputFields="..fields)
    for trial=1,5 do
        local function elapsed(spatial)
            collectgarbage("collect")
            local start=os.clock()
            for _=1,100 do prepare(spatial) end
            return (os.clock()-start)*1000/100
        end
        local before,after
        if trial%2==1 then before,after=elapsed(baseline),elapsed(current)
        else after,before=elapsed(current),elapsed(baseline) end
        print(string.format("REGION_ROUTE sample=%d before=%.3fms after=%.3fms",trial,before,after))
    end
end
print("Border region routing: source and operation binning, boundary/cast scope and foreign texture references PASS")
