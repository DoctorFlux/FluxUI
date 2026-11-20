-- Execute the actual structural solver and mask-free renderer. Native GPU/FPS pending.
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,msg) end
local function read(path) local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s end
local function fixture(waitForWorld)
    local e=setmetatable({unpack=table.unpack,SlashCmdList={}}, {__index=_G});e._G=e
    local queue,objects={},{}
    local m={}
    local function new(parent,rect,objectType)
        local o=setmetatable({parent=parent,rect=rect or {0,0,100,100},objectType=objectType or "Frame",shown=true,scale=1,hooks={},masks={},alpha=1,color={1,1,1,1},uv={0,0,0,1,1,0,1,1},path="original.tga",snap=true,snapBias=1}, {__index=m})
        objects[#objects+1]=o;return o
    end
    function m:GetParent() return self.parent end
    function m:SetParent(p) self.parent=p end
    function m:GetFrameStrata() return self.strata or "MEDIUM" end
    function m:GetFrameLevel() return self.level or 0 end
    function m:SetFrameLevel(level) self.level=level end
    function m:GetRect() e.rectReads=(e.rectReads or 0)+1;if self.target then return self.target:GetRect() end;return table.unpack(self.rect) end
    function m:GetLeft() return self.target and self.target:GetLeft() or self.rect[1] end
    function m:GetBottom() return self.target and self.target:GetBottom() or self.rect[2] end
    function m:GetEffectiveScale() return self.scale*(self.inheritScale and self.parent and self.parent:GetEffectiveScale() or 1) end
    function m:SetFrameStrata(strata) self.strata=strata end
    function m:IsShown() return self.shown end
    function m:IsVisible() return self.shown and (not self.alphaSensitive or self.alpha>0) and (not self.parent or self.parent:IsVisible()) end
    function m:HasScript(name)
        if self.scriptSupport then return self.scriptSupport[name]==true end
        return name=="OnShow" or name=="OnHide" or name=="OnSizeChanged" and self.objectType=="Frame"
    end
    function m:HookScript(name,fn)
        assert(self.objectType~="Texture","Texture scripts are unsupported by this strict fixture")
        assert(m.HasScript(self,name),self.objectType..":HookScript(): unsupported "..name)
        local old=self.hooks[name]
        self.hooks[name]=function(...) if old then old(...) end;fn(...) end
    end
    function m:Show() local changed=not self.shown;self.shown=true;if changed and self.hooks.OnShow then self.hooks.OnShow()end end
    function m:Hide() local changed=self.shown;self.shown=false;if changed and self.hooks.OnHide then self.hooks.OnHide()end end
    function m:CreateTexture() local t=new(self,nil,"Texture");t.decorative=true;return t end
    function m:CreateMaskTexture() error("junctions must never allocate masks") end
    function m:SetAllPoints(target) self.target=target;self.anchors={{"TOPLEFT",target,"TOPLEFT"},{"BOTTOMRIGHT",target,"BOTTOMRIGHT"}} end
    function m:SetTexture(path) self.path=path end
    function m:SetSnapToPixelGrid(enabled) self.snap=enabled end
    function m:SetTexelSnappingBias(bias) self.snapBias=bias end
    function m:SetTexCoord(...) self.uv={...} end
    function m:SetVertexOffset(index,x,y) self.vertices=self.vertices or {};self.vertices[index]={x,y} end
    function m:SetVertexColor(r,g,b,a) self.color={r,g,b,a or 1};self.alpha=a or 1 end
    function m:GetVertexColor() return table.unpack(self.color) end
    function m:GetTexture() return self.path end
    function m:GetTexCoord() return table.unpack(self.uv) end
    function m:GetObjectType() return self.objectType end
    function m:GetAlpha() return self.alpha end
    function m:SetAlpha(a) self.alpha=a;self.color[4]=a end
    function m:GetEffectiveAlpha() return self.alpha*(self.parent and self.parent:GetEffectiveAlpha() or 1) end
    function m:GetDrawLayer() return "ARTWORK",0 end
    function m:SetDrawLayer(layer,sublevel) self.layer,self.sublevel=layer,sublevel end
    function m:SetSize(w,h) self.size={w,h} end
    function m:SetPoint(...)
        self.point={...};self.anchors=self.anchors or {}
        for i,point in ipairs(self.anchors)do if point[1]==self.point[1]then self.anchors[i]=self.point;return end end
        self.anchors[#self.anchors+1]=self.point
    end
    function m:ClearAllPoints() self.anchors={};self.target=nil end
    function m:GetNumPoints() return #(self.anchors or {}) end
    function m:GetPoint(i) return table.unpack((self.anchors or {})[i]or {}) end
    function m:GetNumMaskTextures()
        if self.maskCountOverride~=nil then return self.maskCountOverride end
        local n=0;for _ in pairs(self.masks)do n=n+1 end;return n
    end
    function m:AddMaskTexture() error("junctions must never attach masks") end
    function m:RemoveMaskTexture() error("junctions must never remove foreign masks") end
    function m:RegisterEvent() end
    function m:SetScript(name,fn) check(name~="OnUpdate","no idle update driver");self[name]=fn end
    local locked=false
    e.InCombatLockdown=function()return locked end
    e.hooksecurefunc=function(o,name,fn)
        local original=assert(o[name],name)
        o[name]=function(self,...)
            local result={original(self,...)};fn(self,...);return table.unpack(result)
        end
    end
    e.UIParent=new()
    e.CreateFrame=function(_,_,parent)local f=new(parent or e.UIParent);f.inheritScale=true;return f end
    e.Flux={Scheduler={Request=function(tier,token,fn)
        check(tier=="structural" and token=="border.junctions","shared structural scheduler")
        queue[#queue+1]=fn
    end}}
    local style,accent=1,"class"
    local B={_pieces={}}
    function B:GetBorderType()return style end
    function B:GetAccentMode()return accent end
    function B:GetAccentColor()return .2,.5,.8 end
    assert(load(read("Core/BorderJunctions.lua"),"@Core/BorderJunctions.lua","t",e))("_FluxUI",{Border=B})
    if not waitForWorld then for _,o in ipairs(objects)do if o.OnEvent then o:OnEvent("PLAYER_ENTERING_WORLD")end end end
    local function piece(parent,key,rect,anchors)
        local p=new(parent,rect,"Texture");p.anchors=anchors;local r={key=key};B._pieces[p]=r;B.Junctions:Adopt(p,r);return p,r
    end
    local function flush()
        local q=queue;queue={};for _,fn in ipairs(q)do fn()end
    end
    return B.Junctions,new,piece,flush,objects,function(v)locked=v end,
        function(a,b)style=a;accent=b end,function()return #queue end,e
end
local J=fixture()
local function group(id,plane)return {id=id,plane=plane or "HUD"}end
local function seg(axis,p,a,b,g,side)return {axis=axis,p=p,a=a,b=b,group=g,side=side or (axis=="H" and "Top" or "Left"),scale=1}end
local function kinds(ops)
    local out={};for _,op in ipairs(ops)do if op.bits then out[op.bits]=(out[op.bits]or 0)+1 end end;return out
end
for _,case in ipairs({{0,20,7},{-20,0,11},{-20,20,15}}) do
    local ops=assert(J:Solve({seg("H",0,-20,20,group(1)),seg("V",0,case[1],case[2],group(2))}))
    check(kinds(ops)[case[3]]==1,"top/bottom T and X junction arms")
end
for _,case in ipairs({{0,20,14},{-20,0,13}}) do
    local ops=assert(J:Solve({seg("V",0,-20,20,group(1)),seg("H",0,case[1],case[2],group(2))}))
    check(kinds(ops)[case[3]]==1,"left/right T arms")
end
check(#assert(J:Solve({seg("H",0,-20,0,group(1)),seg("V",0,0,20,group(2))}))==0,"ordinary L corner keeps its cap")
check(#assert(J:Solve({seg("H",0,-20,20,group(1,"DIALOG")),seg("V",0,-20,20,group(2))}))==0,"separate window/HUD planes")
for _,units in ipairs({{"player","target"},{"party1","party2"},{"party2","party3"}}) do
    local a,b=group(1),group(2);a.unitOwner,b.unitOwner=units[1],units[2]
    check(#assert(J:Solve({seg("H",0,-20,20,a),seg("V",0,-20,20,b)}))==0,"different unit frames never join one another")
end
do
    local a,b=group(1),group(2);a.unitOwner,b.unitOwner="player","target"
    local left,right=seg("V",0,-40,40,a,"Right"),seg("V",6,-40,40,b,"Left")
    left.rect,right.rect={-9.5,-40,6.5,40},{-3,-40,13,40}
    local ops=assert(J:Solve({left,right}))
    check(#ops==2 and ops[1].shadowOnly and ops[2].shadowOnly,"independent units trim only doubled facing shadows")
    check(left.p==0 and right.p==6 and not next(kinds(ops)),"independent units keep separate straight cores and receive no T/X join")
end
local a,b,c=group(1),group(2),group(3)
local ops=assert(J:Solve({seg("H",0,0,100,a),seg("H",.5,20,80,b),seg("H",0,30,90,c)}))
check(#ops==2 and not ops[1].bits,"triple collinear overlap clipped once per later run")
do
    local a,b,c=group(1),group(2),group(3)
    local x,y,z=seg("H",0,0,100,a,"Bottom"),seg("H",6,0,100,b,"Top"),seg("H",7,0,100,c,"Bottom")
    x.rect,y.rect,z.rect={0,-8,100,8},{0,-2,100,14},{0,-1,100,15}
    local result=assert(J:Solve({x,y,z}))
    check(#result==2,"interleaved opposing lines cannot hide a close neighbour behind the representative line")
    check(#z.paintCuts==1 and z.paintCuts[1].owner==x and #y.paintCuts==1 and y.paintCuts[1].owner==x,
        "overlapping neighbours follow a deterministic acyclic paint-owner chain")
    check(x.p==0 and y.p==6 and z.p==7,"neighbor discovery keeps each original edge field straight and stationary")
end
for _,priority in ipairs({{1,2,3},{1,3,2},{2,1,3},{2,3,1},{3,1,2},{3,2,1}}) do
    local edges={}
    for i,p in ipairs({0,6,7}) do
        local g=group(i);g.priority=priority[i]
        local s=seg("H",p,0,100,g,i==2 and "Top" or "Bottom");s.rect={0,p-8,100,p+8};edges[i]=s
    end
    local result=assert(J:Solve(edges));local highest
    for _,s in ipairs(edges) do if not highest or s.group.priority>highest.group.priority then highest=s end end
    check(#result==2,"every registration/paint order removes each redundant shared line exactly once")
    for _,s in ipairs(edges) do
        check(s==highest and #s.paintCuts==0 or #s.paintCuts==1 and s.paintCuts[1].owner==highest,
            "an already owned intermediary cannot leave a third overlapping border visible")
    end
end
do
    local a,b,c=group(1),group(2),group(3);a.priority,b.priority,c.priority=100,10,50
    local x,y,z=seg("H",0,0,50,a,"Bottom"),seg("H",6,0,100,b,"Top"),seg("H",7,0,100,c,"Bottom")
    x.rect,y.rect,z.rect={0,-8,50,8},{0,-2,100,14},{0,-1,100,15}
    check(#assert(J:Solve({x,y,z}))==3,"partial shared runs split at actual ownership boundaries")
    check(#y.paintCuts==2 and y.paintCuts[1].owner==x and y.paintCuts[2].owner==z
        and #z.paintCuts==1 and z.paintCuts[1].owner==x,"each part of a long border keeps its correct local paint owner")
end
ops=assert(J:Solve({seg("H",0,-30,30,a),seg("H",.5,-30,30,b),seg("V",0,-30,30,c)}))
check(kinds(ops)[15]==1,"subpixel adjacent lines share one X patch")
ops=assert(J:Solve({seg("H",0,-30,30,a),seg("V",0,-30,30,b),seg("V",5,-30,30,c)}))
local patches={}
for _,op in ipairs(ops) do if op.bits then patches[#patches+1]=op end end
check(#patches==2 and (patches[1].rect[3]<=patches[2].rect[1] or patches[2].rect[3]<=patches[1].rect[1]),"nearby X patches partition their overlap instead of stacking")
-- 1,000 separated widgets: local work stays bounded instead of an all-pairs pass.
local many={}
for i=1,1000 do
    local x=(i%40)*150;local y=math.floor(i/40)*150
    many[#many+1]=seg("H",y,x-20,x+20,group(2*i))
    many[#many+1]=seg("V",x,y-20,y+20,group(2*i+1))
end
check(#assert(J:Solve(many))==1000,"large layout retains every isolated X")
check(J.stats.candidates<12000,"spatial candidates below quadratic comparisons")
local crowded={}
for i=1,500 do crowded[#crowded+1]=seg(i%2==0 and "H" or "V",0,-20,20,group(i)) end
local result,why=J:Solve(crowded)
check(not result and why=="candidate budget" and J.stats.candidates==J.limits.candidates+1,"pathological overlap exits at fixed budget")
local wide={}
for i=1,1000 do wide[#wide+1]=seg("H",i*100,0,4000,group(i)) end
result,why=J:Solve(wide)
check(not result and why=="bucket budget","large nonintersecting extents cannot allocate unbounded spatial entries")

-- One source can be crossed many times: fragments are a disjoint UV partition,
-- never several alpha masks attached to a native texture.
local rects={{0,0,100,16}}
for _,x in ipairs({10,30,50,70,90}) do rects=J:Subtract(rects,{x,0,x+4,16}) end
local area=0
for i,r in ipairs(rects) do
    area=area+(r[3]-r[1])*(r[4]-r[2])
    for k=i+1,#rects do local v=rects[k]
        check(not(r[1]<v[3] and r[3]>v[1] and r[2]<v[4] and r[4]>v[2]),"fragments never stack")
    end
end
check(area==1280 and #rects==6,"five joins preserve the exact remaining original surface")
local uv=J.SliceUV({0,0,0,1,1,0,1,1},{0,0,100,100},{25,25,75,75})
check(uv[1]==.25 and uv[2]==.25 and uv[7]==.75 and uv[8]==.75,"native eight-coordinate UV interpolation")
-- Outgoing seams sample the original texture field, including longitudinal
-- variation and fractional perpendicular centers. No generic junction profile
-- may introduce a different bevel, thickness, tint sheet or alpha at that cut.
do
    local source={path="bevel.tga",uv={.1,.2,.1,.7,.8,.2,.8,.7}}
    local h={axis="H",side="Top",p=0,rawP=0,scale=1,rect={-80,-9,80,8},source=source}
    local v={axis="V",side="Left",p=0,rawP=0,scale=1,rect={-9,-80,7,80},source=source}
    local incoming={axis="H",side="Bottom",p=0,rawP=2.5,scale=.8,rect={-4,-3.1,70,9.7},source=source}
    for _,rect in ipairs({{-16,-16,16,16},{-7,-11,12,9}}) do
        local op={bits=15,x=0,y=0,hs=h,vs=v,rect=rect,fullRect={-16,-16,16,16}}
        local triangles=assert(J:BranchTriangles(op,{[1]=h,[2]=incoming,[3]=v,[4]=v}))
        local seams=0
        for _,t in ipairs(triangles) do
            local bounds=t.arm==2 and incoming.rect or t.arm<=2 and h.rect or v.rect
            for _,p in ipairs({t.a,t.b,t.c}) do
                check(p[3]>=.1-1e-9 and p[3]<=.8+1e-9 and p[4]>=.2-1e-9 and p[4]<=.7+1e-9,
                    "clipped branch cannot sample another cell of the source border sheet")
                local wx=rect[1]+p[1]*(rect[3]-rect[1])
                local wy=rect[4]-p[2]*(rect[4]-rect[2])
                local sampleX=math.max(bounds[1],math.min(bounds[3],wx))
                local sampleY=math.max(bounds[2],math.min(bounds[4],wy))
                check(math.abs(p[3]-(.1+.7*(sampleX-bounds[1])/(bounds[3]-bounds[1])))<1e-9 and
                    math.abs(p[4]-(.2+.5*(bounds[4]-sampleY)/(bounds[4]-bounds[2])))<1e-9,
                    "every interior source profile stays straight rather than bending toward the junction center")
                if t.arm==2 and math.abs(wx-rect[3])<1e-9 then
                    local expectedU=.1+.7*(wx-bounds[1])/(bounds[3]-bounds[1])
                    local expectedV=.2+.5*(bounds[4]-wy)/(bounds[4]-bounds[2])
                    check(math.abs(p[3]-expectedU)<1e-9 and math.abs(p[4]-expectedV)<1e-9,
                        "outgoing boundary uses exact source UVs even with cropped patches and opposing offsets")
                    seams=seams+1
                end
            end
        end
        check(seams>1,"the seam regression observes actual surviving outgoing branch vertices")
    end
end
local function cross(a,b,c)return(b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])end
for _,bits in ipairs({7,11,13,14,15})do
    for _,center in ipairs({{.5,.5},{.2,.7},{.85,.15}})do
        local triangles=J:Triangles(bits,center[1],center[2]);local area=0
        for _,t in ipairs(triangles)do area=area+math.abs(cross(t.a,t.b,t.c))/2 end
        check(math.abs(area-1)<1e-9,"every T/X color partition exactly covers the patch including cropped nearby joins")
        for x=0,8 do for y=0,8 do
            local p={(x+.237)/9,(y+.613)/9};local hits=0
            for _,t in ipairs(triangles)do
                if cross(t.a,t.b,p)<0 and cross(t.b,t.c,p)<0 and cross(t.c,t.a,p)<0 then hits=hits+1 end
            end
            check(hits==1,"colored branch interiors never overlap or leave gaps")
        end end
    end
end

do
    local j,new,piece,flush,objects,lock,selectStyle,_,e=fixture()
    selectStyle(2,"custom")
    local lp,rp,vp=new(e.UIParent),new(e.UIParent),new(e.UIParent)
    local left,leftRecord=piece(lp,"Top",{0,-8,50,17});left.color={1,0,0,1};leftRecord.naturalArt=true
    local right=piece(rp,"Top",{50,-8,50,17});right.color={0,0,1,1}
    local vertical=piece(vp,"Left",{40.5,-40,16,80});vertical.color={0,1,0,1}
    left.path="gold.tga";right.path="accent.tga";vertical.path="accent.tga"
    -- The natural target branch must use gold artwork while adjacent custom
    -- branches use the neutral tint sheet; a white multiplier alone is not enough.
    j:Invalidate();flush()
    local node
    for _,o in ipairs(objects)do if o._junctionOp then node=o._junctionOp end end
    check(node and #node.sprites>=4,"one X is tiled by disjoint source-profile triangles")
    local owners={}
    for _,t in ipairs(node.sprites)do
        owners[t._junctionSource]=true
        if t._junctionSource==left then check(t.path=="gold.tga","NPC branch keeps the natural gold profile")
        else check(t.path=="accent.tga","accent branches retain the neutral tint profile")end
        local c=t._junctionSource.color
        check(t.color[1]==c[1] and t.color[2]==c[2] and t.color[3]==c[3],"each branch retains its own source tint across different parents")
        if t._junctionQuad then
            check(t.size[1]>0 and t.size[2]>0,"an optimized rectangular field has positive native dimensions")
            for _,offset in ipairs(t.vertices) do check(offset[1]==0 and offset[2]==0,"a rectangular field uses its four native corners") end
        else
            check(t.vertices[3][1]==t.vertices[4][1] and t.vertices[3][2]+t.size[2]==t.vertices[4][2],"the second mesh triangle collapses without distorting the shared UV field")
        end
    end
    check(owners[left] and owners[right] and owners[vertical],"junction tracks all three independent color owners")
    lock(true);left:SetVertexColor(.8,.2,.1,.5)
    for _,t in ipairs(node.sprites)do
        if t._junctionSource==left then check(t.color[1]==.8 and t.color[4]==.5,"live branch color updates are combat-safe forwards")
        elseif t._junctionSource==right then check(t.color[3]==1 and t.color[1]==0,"neighbor tint remains unchanged")end
    end
end

-- Native GetRect coordinates belong to each owner's effective scale. A screen
-- rectangle must subtract the owner's screen origin BEFORE converting to local
-- anchor offsets. Zero-origin / 100%-scale fixtures conceal that distinction.
for _,style in ipairs({1,2}) do
    for _,key in ipairs({"Top","Left"})do
        local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,"atlas")
        local parent=new(e.UIParent)
        local horizontal=key=="Top"
        local original=horizontal and {-9,0,114,17} or {-9,-5,16,109}
        local line=piece(parent,key,original);line._FluxBorderRunCaps=true;flush()
        local tracks=style==1 and {left=9,right=9.5,top=8,bottom=8}or{left=9.5,right=9,top=9,bottom=7}
        local low=horizontal and original[1]+tracks.left or original[2]+16-tracks.bottom
        local high=horizontal and original[1]+original[3]-(16-tracks.right) or original[2]+original[4]-tracks.top
        check(j.stats.operations==0 and line:GetAlpha()==0,"an isolated internal divider trims its native cap field without requiring a T/X")
        local drawn=0
        for _,t in ipairs(objects)do
            if t.decorative and t:IsVisible() and t.path=="original.tga"then
                local at=horizontal and t.point[4]or t.point[5]
                local length=horizontal and t.size[1]or t.size[2]
                check(math.abs(at-low)<1e-8 and math.abs(at+length-high)<1e-8,"actual divider artwork ends at both logical stroke endpoints")
                local expected=j.SliceUV({0,0,0,1,1,0,1,1},
                    {original[1],original[2],original[1]+original[3],original[2]+original[4]},
                    horizontal and {low,original[2],high,original[2]+original[4]}or{original[1],low,original[1]+original[3],high})
                for i,v in ipairs(expected)do check(math.abs(t.uv[i]-v)<1e-8,"divider endpoint trimming crops the original UV field without stretching")end
                drawn=drawn+1
            end
        end
        check(drawn==1,"one bounded source fragment paints each isolated divider")
    end
end

for _,style in ipairs({1,2}) do
    for _,scales in ipairs({{.64,.8},{.8,.64},{1,1},{1.25,.75},{2,1.5}}) do
        for _,front in ipairs({1,2}) do
            local j,new,piece,flush,objects,_,selectStyle,_,e=fixture()
            selectStyle(style,"custom")
            local hs,vs=scales[1],scales[2]
            local hp=new(e.UIParent,{450/hs,65/hs,400/hs,200/hs})
            local vp=new(e.UIParent,{720/vs,100/vs,200/vs,200/vs})
            hp.scale,vp.scale=hs,vs
            hp.level,vp.level=front==1 and 20 or 10,front==2 and 20 or 10
            local ht=style==1 and 8 or 9
            local vx=style==1 and 9 or 9.5
            local h=piece(hp,"Top",{750/hs,170/hs-17+ht,100/hs,17})
            local v=piece(vp,"Left",{800/vs-vx,120/vs,16,100/vs})
            flush()
            local node
            for _,o in ipairs(objects) do if o._junctionOp then node=o._junctionOp end end
            check(node and node.bits==15,"scaled translated owners retain their real screen intersection")
            for _,t in ipairs(node.sprites) do
                check(t.parent:GetParent()==t._junctionSource:GetParent(),"raised junction retains its source visibility and coordinate owner")
                check(t.parent:GetFrameLevel()>math.max(hp.level,vp.level),"source-owned junction still draws above every participating peer")
                local scale=t.parent:GetEffectiveScale()
                local x=(t.parent:GetLeft()+t.point[4])*scale
                local y=(t.parent:GetBottom()+t.point[5])*scale
                if t._junctionQuad then
                    local source=t._junctionSource
                    local bounds,uv,s=source.rect,t.uv,source:GetParent():GetEffectiveScale()
                    check(math.abs(x-(bounds[1]+uv[1]*bounds[3])*s)<1e-8 and
                        math.abs(y-(bounds[2]+(1-uv[4])*bounds[4])*s)<1e-8,
                        "rectangular junction fields preserve the original source UV's screen position")
                    check(math.abs(t.size[1]*scale-(uv[5]-uv[1])*bounds[3]*s)<1e-8 and
                        math.abs(t.size[2]*scale-(uv[4]-uv[2])*bounds[4]*s)<1e-8,
                        "rectangular junction fields preserve source dimensions across mixed screen scales")
                    check(x>=node.rect[1]-1e-8 and y>=node.rect[2]-1e-8 and
                        x+t.size[1]*scale<=node.rect[3]+1e-8 and y+t.size[2]*scale<=node.rect[4]+1e-8,
                        "optimized rectangles stay inside the current cropped junction patch")
                else
                    check(math.abs(x-node.rect[1])<1e-8 and math.abs(y-node.rect[2])<1e-8,
                        "junction anchor lands on the cut rectangle at translated fractional UI scales")
                    check(math.abs(t.size[1]*scale-(node.rect[3]-node.rect[1]))<1e-8 and
                        math.abs(t.size[2]*scale-(node.rect[4]-node.rect[2]))<1e-8,
                        "junction dimensions share the source cut's screen scale")
                end
            end
            for _,t in ipairs(objects) do
                if t.decorative and t.shown and not t._junctionOwnerOp and t.path=="original.tga" then
                    local source=(t.parent==hp or t.parent:GetParent()==hp) and h or v
                    local r,uv=source.rect,t.uv
                    local scale=t.parent:GetEffectiveScale()
                    local x=(t.parent:GetLeft()+t.point[4])*scale
                    local y=(t.parent:GetBottom()+t.point[5])*scale
                    check(math.abs(x-(r[1]+uv[1]*r[3])*scale)<1e-8 and
                        math.abs(y-(r[2]+(1-uv[4])*r[4])*scale)<1e-8,
                        "remaining source fragments retain their original screen position")
                end
            end
        end
    end
end

for _,style in ipairs({1,2}) do
    local j,new,piece,flush,objects,lock,selectStyle,queued,e=fixture()
    selectStyle(style,"custom")
    local p=new(e.UIParent)
    local ht=style==1 and 8 or 9
    local vx=style==1 and 9 or 9.5
    local h=piece(p,"Top",{0,-17+ht,100,17})
    local v=piece(p,"Left",{50-vx,-40,16,80})
    check(queued()==1,"all new borders share one scheduled batch")
    flush()
    local node
    for _,o in ipairs(objects) do if o._junctionOp then node=o end end
    check(node and node._junctionOp.bits==15,"crossing border pieces produce one X")
    local op=node._junctionOp
    check(j.stats.triangles==#op.triangles+#(op.fallbackTriangles or {}),"diagnostic counts committed numeric triangles, including optimized rectangle pairs")
    local fields=0
    for _,triangle in ipairs(op.triangles) do if not triangle.quadTail then fields=fields+1 end end
    for _,triangle in ipairs(op.fallbackTriangles or {}) do if not triangle.quadTail then fields=fields+1 end end
    check(#op.sprites==fields,"each effective triangle or rectangle has one native field; rectangle tails allocate none")
    check(h.alpha==0 and v.alpha==0 and j.stats.fragments>0,"original overlap is removed; cropped source fragments retain the rest")
    check(not h.snap and h.snapBias==0 and not v.snap and v.snapBias==0,"original border fields use the same continuous sampling as native NineSlice")
    for _,o in ipairs(objects) do
        if o.decorative and o.shown and (o._junctionOwnerOp or o.path=="original.tga") then
            check(not o.snap and o.snapBias==0,"source fragments and junction meshes cannot independently sharpen or snap their cut UVs")
        end
    end
    check(node.path==node._junctionSource.path,"each type samples its own registered source artwork")
    local count,solves=#objects,j.stats.solves
    for _=1,100 do j:Invalidate() end
    check(queued()==1,"repeated geometry requests merge")
    flush()
    check(#objects==count and j.stats.solves==solves and j.stats.unchanged==1,"unchanged layout does not solve or allocate")
    h:SetVertexColor(.9,.2,.1,.4)
    check(h:GetAlpha()==0,"native recolor cannot revive the suppressed original")
    h:SetVertexColor(.9,.2,.1,.4)
    check(h:GetAlpha()==0,"identical RGBA writes still re-suppress native shared alpha")
    local copies=0
    for _,o in ipairs(objects) do
        if o.decorative and o.shown and o.path=="original.tga" and o.color[1]==.9 then copies=copies+1 end
    end
    check(copies>0,"native texture color updates reach its fragments without another solve")
    h:SetAlpha(.7);flush()
    check(h.alpha==0,"author alpha updates keep the overlapping original suppressed")
    j:Invalidate(true);flush()
    local preserved=0
    for _,o in ipairs(objects)do
        if o._junctionOwnerOp and o._junctionSource==h then
            check(o.alpha==.7,"forced rebuild uses cached native RGBA instead of suppressed alpha zero")
            preserved=preserved+1
        end
    end
    check(preserved>0,"alpha preservation is checked on visible source branches")
    h:SetVertexColor(.9,.2,.1,0);flush()
    check(h:GetAlpha()==0 and v:GetAlpha()==1,"native zero-alpha color restores its visible neighbour")
    h:SetVertexColor(.9,.2,.1,.7);flush()
    check(h:GetAlpha()==0 and v:GetAlpha()==0,"positive native color reconnects the restored source")
    j:Recolor(p,.9,.1,.2,.4)
    check(node.color[1]==.9 and node.color[4]==.4,"parent accent updates reach the single join")
    lock(true);j:Invalidate();flush()
    check(h.alpha==0 and v.alpha==0 and node.shown and queued()==0,"combat invalidation keeps stable joins and defers discovery")
    j:SetOverlay(p,true)
    check(not node.shown and h.alpha==.7,"combat portrait overlay preserves its native alpha/color")
    lock(false);j:SetOverlay(p,false);flush()
    check(node.shown and #objects==count,"restoring normal chrome reuses fragments and join sprites")
    h:Hide();flush()
    check(v.alpha==1 and not node.shown,"hidden neighbour never leaves a cut hole")
    h:Show();flush()
    check(node.shown and #objects==count,"show reuses the existing graphics")
    j:Forget(h)
    check(v.alpha==1 and not node.shown,"pool removal restores neighbours")
    p._FluxBorderJunctionRole="overlay";j:Invalidate(true);flush()
    check(j.stats.operations==0,"cast and explicit overlay regions stay independent")
    p._FluxBorderJunctionRole=nil;p.unit="party2target";j:Invalidate(true);flush()
    check(v.alpha==1 and j.stats.operations==0,"an isolated party-target edge remains complete after its internal neighbour is removed")
end

for _,unit in ipairs({"targettarget","focustarget","party2target","pet","pettarget"})do
    local j,new,piece,flush,objects,_,_,_,e=fixture()
    local main=new(e.UIParent);main.unit="target"
    local small=new(main);small.unit=unit
    local base=new(small);local outer=new(small)
    local atlas=new(e.UIParent);atlas._FluxBorderOwner=small
    local underlay=piece(main,"Top",{0,-9,100,17})
    local h=piece(base,"Top",{0,-9,100,17})
    local duplicate=piece(outer,"Top",{0,-9,100,17})
    local v=piece(atlas,"Left",{41,-40,16,80})
    flush()
    check(j.stats.operations==2 and underlay.alpha==1,"mini-unit cleanup never joins or suppresses the underlying main unit")
    check(v.alpha==0 and (h.alpha==0 or duplicate.alpha==0),"mini-unit detached atlas and duplicate outlines share one internal scope")
    local count,solves=#objects,j.stats.solves
    for _=1,20 do h:SetVertexColor(.2,.6,.8,1);duplicate:SetVertexColor(.2,.6,.8,1);v:SetVertexColor(.2,.6,.8,1)end
    flush()
    check(#objects==count and j.stats.solves==solves and v.alpha==0,"mini-unit class repaint neither exposes originals nor rebuilds geometry")
end

do
    local j,new,piece,flush,objects,_,_,_,e=fixture()
    local p=new(e.UIParent)
    local h=piece(p,"Top",{0,-9,100,17});local v=piece(p,"Left",{41,-40,16,80})
    j.limits.junctionTriangles=0
    flush()
    check(j.stats.fallback=="junction triangle budget" and h.alpha==1 and v.alpha==1,
        "junction graphics budget falls back before suppressing original artwork")
    for _,o in ipairs(objects) do
        check(not o._junctionOwnerOp,"budget fallback leaves no partially committed junction")
    end
end

-- Adjacent complete rectangles: the action strip, portrait/HP and HP/resource
-- panels all use this same eight-piece contract; caps must be cut too.
for _,style in ipairs({1,2}) do
    local j,new,piece,flush,objects,_,selectStyle,_,e=fixture()
    selectStyle(style,"atlas")
    local track=style==1 and {Top=8,Bottom=8,Left=9,Right=9.5} or {Top=9,Bottom=7,Left=9.5,Right=9}
    local function rectangle(x)
        local p=new(e.UIParent,{x,-60,100,60})
        local parts={}
        parts.Top=piece(p,"Top",{x+8,track.Top-17,84,17})
        parts.Bottom=piece(p,"Bottom",{x+8,-60+track.Bottom-16,84,16})
        parts.Left=piece(p,"Left",{x-track.Left,-52,16,44})
        parts.Right=piece(p,"Right",{x+100-track.Right,-52,16,44})
        for _,key in ipairs({"TL","TR","BL","BR"}) do
            local left=key:sub(2)=="L";local top=key:sub(1,1)=="T"
            parts[key]=piece(p,key,{x+(left and -track.Left or 100-track.Right),top and -8 or -68,16,16})
        end
        return p,parts
    end
    local _,first=rectangle(0)
    local secondParent,second=rectangle(100)
    flush()
    local nodes=0
    for _,o in ipairs(objects) do if o._junctionOp then nodes=nodes+1;check(o._junctionOp.bits==7 or o._junctionOp.bits==11,"shared edge endpoints use T artwork")end end
    check(nodes==2 and j.stats.operations==3,"two adjacent panels have one shared edge and two T joins")
    check(first.TR.alpha==0 and second.TL.alpha==0,"rounded caps are cropped at shared joins")
    secondParent.level=10
    for _,key in ipairs({"Left","TL","BL"})do second[key].rect[1]=second[key].rect[1]+2.5 end
    j:Invalidate(true);flush()
    local welded=0
    for _,o in ipairs(objects)do if o._junctionOp then welded=welded+1 end end
    check(welded==2 and j.stats.operations==3,"asymmetric opposite-edge profiles weld to one shared run and two deterministic T joins")
    piece(secondParent,"Top",{100,-39,100,17})
    j:Invalidate(true);flush()
    local extraNodes=0
    for _,o in ipairs(objects) do if o._junctionOp then extraNodes=extraNodes+1 end end
    check(extraNodes==4 and j.stats.operations==5,"an extra HP/resource divider keeps outer corners connected and adds its two T joins")
    secondParent:Hide();flush()
    check(first.TR.alpha==1,"remaining panel regains its complete original corner")
end

-- The source is scoped to decoration. These regressions would immediately fail
-- Opposing shadows can overlap with cores farther apart than the old 3px weld.
-- Match player/target, stance/player and strip/status seams without moving any
-- source or parent rectangle. One opaque probe remains through the shared run.
for _,style in ipairs({1,2}) do
    for _,vertical in ipairs({false,true}) do
        for _,gap in ipairs({6,7,17}) do
            local j,new,piece,flush,objects,_,selectStyle,_,e=fixture()
            selectStyle(style,"atlas")
            local track=style==1 and {Top=8,Bottom=8,Left=9,Right=9.5} or {Top=9,Bottom=7,Left=9.5,Right=9}
            local originals={}
            local function rectangle(x,y)
                local p=new(e.UIParent,{x,y,100,60})
                local function part(key,r)
                    local t=piece(p,key,r);originals[t]={table.unpack(r)};return t
                end
                local parts={}
                parts.Top=part("Top",{x+8,y+60+track.Top-17,84,17})
                parts.Bottom=part("Bottom",{x+8,y+track.Bottom-16,84,16})
                parts.Left=part("Left",{x-track.Left,y+8,16,44})
                parts.Right=part("Right",{x+100-track.Right,y+8,16,44})
                for _,key in ipairs({"TL","TR","BL","BR"}) do
                    local left,top=key:sub(2)=="L",key:sub(1,1)=="T"
                    part(key,{x+(left and -track.Left or 100-track.Right),y+(top and 52 or -8),16,16})
                end
                return parts
            end
            rectangle(0,0);rectangle(vertical and 0 or 100+gap,vertical and 60+gap or 0)
            flush()
            for t,r in pairs(originals) do
                for i=1,4 do check(t.rect[i]==r[i],"shared-shadow fit never moves or resizes a source border piece") end
            end
            if gap<10 then
                check(j.stats.operations==3,"opposing shadow footprints produce one shared run and two T ends for both styles")
                local hits=0;local px,py=vertical and 50 or 103,vertical and 63 or 30
                for _,t in ipairs(objects) do
                    if t.objectType=="Texture" and t.alpha>0 and t:IsVisible() then
                        local x,y,w,h=table.unpack(t.rect)
                        if t.point and t.size then
                            x=t.parent:GetLeft()+t.point[4];y=t.parent:GetBottom()+t.point[5];w,h=t.size[1],t.size[2]
                        end
                        if x<px and x+w>px and y<py and y+h>py then hits=hits+1 end
                    end
                end
                check(hits==1,"the shared shadow band is drawn once instead of two layered borders")
            else
                check(j.stats.operations==0,"separated panels retain independent borders instead of connecting across open space")
            end
        end
    end
end

-- The source is scoped to decoration. These regressions would immediately fail
-- if the algorithm attempted native mask allocation or Texture:HookScript.
check(not read("Core/BorderJunctions.lua"):match(":AddMaskTexture%s*%("),"no native mask attachment calls in production; read-only observers are allowed")
check(not read("Core/BorderJunctions.lua"):find("SetAttribute",1,true),"no secure action-attribute writes in topology")

do
    local j,new,piece,flush,objects,_,_,_,e=fixture()
    local p=new(e.UIParent)
    local h=piece(p,"Top",{0,-9,100,17});piece(p,"Left",{41,-40,16,80})
    flush();local solves=j.stats.solves
    h.alphaSensitive=true
    for i=1,100 do
        p:Show();h:Show();h:SetTexture("original.tga");h:SetTexCoord(0,0,0,1,1,0,1,1)
        j:Invalidate()
        check(h.alpha==0,"no-op native layout/paint calls never expose the original overlap before the next frame")
    end
    flush()
    check(j.stats.solves==solves and h.alpha==0,"unchanged source/geometry neither rebuilds nor oscillates when suppressed alpha changes IsVisible")
    h:SetTexture("new-source.tga")
    check(h.alpha==0,"real artwork change retains the previous complete layout until replacement is ready")
    flush()
    check(j.stats.solves==solves+1 and h.alpha==0,"changed artwork commits exactly once")
end

-- Real transient Hide/Show and zero-alpha callbacks used to dismantle the whole
-- connected component before the coalesced final layout was even inspected.
do
    local j,new,piece,flush,objects,lock,_,_,e=fixture()
    local p,q=new(e.UIParent),new(e.UIParent)
    local h=piece(p,"Top",{0,-9,100,17});local v=piece(q,"Left",{41,-40,16,80})
    flush()
    local solves,count=j.stats.solves,#objects
    for _=1,100 do
        q:Hide()
        check(h.alpha==0,"hiding one neighbour cannot expose doubled borders throughout the connected HUD")
        q:Show();v:Hide()
        check(h.alpha==0,"texture visibility cannot reset the committed mesh before atomic layout")
        v:Show();q:SetAlpha(0)
        check(h.alpha==0,"a zero-opacity neighbour cannot tear down unrelated committed artwork")
        q:SetAlpha(1)
    end
    flush()
    check(j.stats.solves==solves and #objects==count,"transient visibility bursts with unchanged final geometry do not solve or allocate")
    p:SetFrameLevel(500);q:SetFrameLevel(600);flush()
    check(j.stats.solves==solves and #objects==count,"temporary combat/highlight levels cannot change static weld ownership")
    lock(true);q.hooks.OnSizeChanged()
    check(h.alpha==0 and v.alpha==0,"combat sizing callbacks retain the committed mesh")
    lock(false);flush()
    check(j.stats.solves==solves,"unchanged sizing callback does not rebuild the mesh")
    j:Invalidate(true);flush()
    check(j.stats.solves==solves+1,"an explicit settings refresh can replace the committed mesh and paint priority")
end

do
    local j,new,piece,flush,objects,_,_,_,e=fixture()
    local p,q=new(e.UIParent),new(e.UIParent)
    local h=piece(p,"Top",{0,-9,100,17});local v=piece(q,"Left",{41,-40,16,80})
    p.unit="player";q.unit="target";flush()
    check(j.stats.operations==0 and h.alpha==1 and v.alpha==1,"logical unit owners keep player/target renderers independent")
    q._FluxBorderOwner=p;j:Invalidate();flush()
    check(j.stats.operations==1,"separate hosts belonging to one unit can join its internal pieces")
    p.unit=nil;q.unit=nil;q._FluxBorderOwner=nil;j:Invalidate();flush()
    local count=#objects
    q.rect[1]=q.rect[1]+200;v.rect[1]=v.rect[1]+200
    q:SetPoint("LEFT",e.UIParent,"LEFT",200,0)
    check(h.alpha==0,"moving an element keeps the old mesh committed until atomic replacement")
    flush()
    check(j.stats.operations==0 and h.alpha==1 and v.alpha==1,"layout detachment restores the complete remaining border")
    q.rect[1]=q.rect[1]-200;v.rect[1]=v.rect[1]-200
    q:SetPoint("LEFT",e.UIParent,"LEFT",0,0);flush()
    check(j.stats.operations==1 and h.alpha==0 and v.alpha==0 and #objects==count,"layout attachment rebuilds the new junction with pooled graphics")
end

do
    local j,new,piece,flush,objects,_,_,_,e=fixture()
    local player,target=new(e.UIParent),new(e.UIParent);player.unit="player";target.unit="target"
    target:Hide()
    local placeholder=new(e.UIParent);placeholder._FluxBorderOwner=target
    local h=piece(player,"Top",{0,-9,100,17});local v=piece(placeholder,"Left",{41,-40,16,80})
    flush()
    check(j.stats.operations==0 and h.alpha==1 and v.alpha==1,"visible no-target placeholder stays independent of player even with its logical unit hidden")
    local cast=new(player);cast._FluxBorderJunctionRole="connected"
    local shell,icon=new(cast),new(cast)
    piece(shell,"Top",{300,-9,100,17});piece(icon,"Left",{341,-40,16,80})
    player.unit="pet";j:Invalidate();flush()
    check(j.stats.operations==1,"explicit cast icon/shell connection works even on a normally independent pet-unit family")
    player.unit="player"
    local underlay=piece(player,"Left",{341,-40,16,80})
    j:Invalidate();flush()
    check(j.stats.operations==1 and underlay.alpha==1,"cast connection scope never lifts underlying unit/class separators into the cast fill")
end

for _,style in ipairs({1,2}) do
    local j,new,piece,flush,objects,_,selectStyle,_,e=fixture()
    selectStyle(style,"atlas")
    local top=style==1 and 8 or 9;local bottom=style==1 and 8 or 7;local left=style==1 and 9 or 9.5
    local strip,unit=new(e.UIParent),new(e.UIParent)
    e.FluxActionStrip=strip;unit.unit="target";unit.level=1000
    local h=piece(strip,"Top",{0,-17+top,100,17})
    local base=piece(unit,"Bottom",{0,2.24-16+bottom,100,16})
    piece(unit,"Left",{25-left,2.24,16,60})
    flush()
    local node
    for _,t in ipairs(objects) do if t._junctionOp then node=t._junctionOp end end
    check(node and math.abs(node.y)<1e-9 and node.hs.texture==h,"the real action-strip top owns the unit-bottom seam in both styles regardless of unit frame level")
    for _,t in ipairs(node.sprites) do
        check(t.parent:GetParent()==strip,"unit-bottom T pieces inherit persistent strip visibility instead of disappearing with the target")
        check(t.parent:GetFrameLevel()>unit:GetFrameLevel(),"the strip seam draws above the unit's 3D portrait layer")
    end
    check(base.alpha==0 and h.alpha==0,"unit bottom is removed once and the strip remains as cropped original material")
    check(base.rect[2]==2.24-16+bottom and h.rect[2]==-17+top,"strip ownership does not move source textures or unit frames")
end

for _,style in ipairs({1,2}) do
    local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,"atlas")
    local p=new(e.UIParent);p.unit="target"
    local h=piece(p,"Top",{-9,0,114,17});h._FluxBorderRunCaps=true
    piece(p,"Left",{-9,-40,16,100});flush()
    local bits
    for _,t in ipairs(objects)do if t._junctionOp then bits=t._junctionOp.bits end end
    check(bits==14,"straight target header endpoints create a T rather than an outward X/shadow stub")
    local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,"atlas")
    local p=new(e.UIParent);p.unit="target"
    local top,bottom=style==1 and 8 or 9,style==1 and 8 or 7
    local logicalBottom=11-bottom
    piece(p,"Top",{-40,logicalBottom-17+top,100,17})
    local v=piece(p,"Left",{-9,-5,16,109});v._FluxBorderRunCaps=true;flush()
    local bits
    for _,t in ipairs(objects)do if t._junctionOp then bits=t._junctionOp.bits end end
    check(bits==7,"portrait divider endpoints stop at the body boundary instead of adding a false X below it")
end

do
    local j,new,piece,flush,objects,_,_,queued,e=fixture()
    local p,q=new(e.UIParent),new(e.UIParent)
    local h=piece(p,"Top",{0,-9,100,17});local other=piece(q,"Top",{0,-3,100,17})
    flush();local count,solves=#objects,j.stats.solves
    local output={};e.Flux.Print=function(s)output[#output+1]=s end
    e.SlashCmdList.FLUXBORDERS("audit")
    check(#output==2 and output[1]:find("unmatched=1",1,true) and output[2]:find("gap=6.00",1,true),"read-only native audit reports the actual unresolved opposing geometry")
    check(#objects==count and j.stats.solves==solves and queued()==0 and h.alpha==1 and other.alpha==1,"audit never rebuilds, reallocates or changes visible artwork")
end

do
    local j,new,piece,flush,objects,_,selectStyle,_,e=fixture()
    selectStyle(2,"atlas")
    -- Native audit: Grid.Top80.89 and MicroMenu.Bottom82.54. An earlier
    -- Bottom77.30 representative hid their 1.65px contact in the old grouping.
    local ref,grid,menu=new(e.UIParent),new(e.UIParent),new(e.UIParent)
    piece(ref,"Bottom",{0,68.30,100,16})
    piece(grid,"Top",{0,76.89,100,8.5})
    piece(menu,"Bottom",{0,73.54,100,16})
    flush()
    check(j.stats.operations==2,"native grid/menu coordinates remain connected despite an interleaved representative: "..tostring(j.stats.operations))
    local output={};e.Flux.Print=function(s)output[#output+1]=s end
    e.SlashCmdList.FLUXBORDERS("audit")
    check(#output==1 and output[1]:find("unmatched=0",1,true),"audit recognizes transitive paint ownership instead of flagging already removed duplicate shadows")
end

do
    local j,new,piece,flush,objects,_,_,_,e=fixture()
    local p=new(e.UIParent)
    local h=piece(p,"Top",{0,-9,100,17});piece(p,"Left",{41,-40,16,80})
    for i=1,1000 do piece(new(e.UIParent),"Top",{500+i*200,-9,100,17}) end
    flush()
    local reads,solves=j.stats.geometryReads,j.stats.solves
    e.rectReads=0
    for _=1,100 do h:SetPoint("TOPLEFT",p,"TOPLEFT",0,0) end
    flush()
    check(j.stats.geometryReads==reads and j.stats.solves==solves,"unchanged setter bursts bypass the entire global geometry read and solver")
    check(e.rectReads<=2,"one unchanged dirty texture does not reread 1000 unrelated border pieces")
end

do
    local j,new,piece,flush,objects,_,_,_,e=fixture()
    local p,q=new(e.UIParent),new(e.UIParent)
    local h=piece(p,"Top",{0,-9,100,17});piece(q,"Left",{41,-40,16,80})
    h.path="Interface\\AddOns\\_FluxUI\\Texture\\borders\\ForeverMetal150.tga"
    flush()
    local reads,solves=j.stats.geometryReads,j.stats.solves
    local path="Interface\\AddOns\\_FluxUI\\Texture\\borders\\ForeverMetal150Tint.tga"
    h:SetTexture(path);h:SetVertexColor(.2,.6,1,1)
    local seen=0
    for _,t in ipairs(objects) do
        if t.shown and (t._junctionSource==h or t.decorative and t.parent==p and not t._junctionOwnerOp) then
            check(t.path==path and t.color[1]==.2 and t.color[2]==.6 and t.color[3]==1,
                "unit-class neutral material and RGB reach visible fragments/joins before any deferred layout pass")
            seen=seen+1
        end
    end
    check(seen>2,"instant material regression observes actual fragments and branch triangles")
    flush()
    check(j.stats.geometryReads==reads and j.stats.solves==solves,"canonical material swaps never rebuild unchanged geometry")
end

do
    local j,new,piece,flush,objects,_,selectStyle,queued,e=fixture(true)
    selectStyle(2,"custom")
    local p=new(e.UIParent)
    local h=piece(p,"Top",{0,-8,100,17});piece(p,"Left",{40.5,-40,16,80})
    check(queued()==0 and j.stats.passes==0,"startup defers topology until world/profile/layout initialization")
    for _,o in ipairs(objects)do if o.OnEvent then o:OnEvent("PLAYER_ENTERING_WORLD")end end
    flush()
    check(h.alpha==0 and j.stats.solves==1,"the first initialized layout commits the chosen style once")
    for _,o in ipairs(objects)do if o._junctionOp then check(o.path==o._junctionSource.path,"startup junctions sample the already initialized source artwork")end end
end

do
    local j,new,piece,flush,objects,_,_,_,e=fixture()
    local p,q=new(e.UIParent),new(e.UIParent)
    local h=piece(p,"Top",{0,-9,100,17});piece(p,"Left",{41,-40,16,80})
    local bad=piece(q,"Top",{300,-9,100,17});piece(q,"Left",{341,-40,16,80})
    bad.masks.foreign=true
    flush()
    check(j.stats.operations==1 and j.stats.skippedComponents==1 and h.alpha==0 and bad.alpha==1,"foreign mask falls back locally; unrelated component still joins")
    bad.masks={};j:Invalidate(true);flush()
    check(j.stats.operations==2 and bad.alpha==0,"native mask removal permits a later complete retry without owning a mask")
    p:SetAlpha(0);flush()
    check(h.alpha==1 and bad.alpha==0 and j.stats.operations==1,"alpha-hidden panels cannot cut visible neighbours")
    p:SetAlpha(1);flush()
    j:ReleaseAll();local originals={}
    for _,o in ipairs(objects)do
        local ancestor=o
        while ancestor and ancestor~=p do ancestor=ancestor:GetParent()end
        if ancestor==p and o:GetObjectType()~="Texture"then
            originals[o]=o.CreateTexture
            o.CreateTexture=function()error("injected native texture creation failure",0)end
        end
    end
    -- Force a new fragment beyond the existing pool, then fail during rendering.
    for i=1,4 do piece(p,"Left",{10+i*15-9,-40,16,80})end
    local ok,err=pcall(flush)
    check(not ok and tostring(err):find("injected native texture creation failure",1,true),"renderer surfaces native failures after cleanup")
    check(h.alpha==1 and bad.alpha==1,"failed render restores original opacity in every affected component")
    for _,o in ipairs(objects) do if o.decorative then check(not o.shown,"partial render never strands visible fragments")end end
    for o,original in pairs(originals)do o.CreateTexture=original end;j:Invalidate(true);flush()
    check(h.alpha==0 and j.stats.operations>1,"failed render stays retryable")
end

do
    local j,new,piece,flush,objects,lock,selectStyle,queued,e=fixture()
    local p=new(e.UIParent)
    local h=piece(p,"Top",{0,-9,100,17});piece(p,"Left",{41,-40,16,80})
    local now,timers=0,{}
    e.GetTime=function()return now end
    e.C_Timer={After=function(delay,fn)timers[#timers+1]={delay=delay,fn=fn}end}
    flush();local passes=j.stats.passes
    for i=1,100 do j:Invalidate()end
    flush()
    check(#timers==1 and queued()==0 and j.stats.passes==passes,"layout burst schedules one delayed wake and no early geometry scan")
    now=.05;timers[1].fn();flush()
    check(j.stats.passes==passes+1 and queued()==0 and #timers==1,"settled layout leaves no idle timer or scheduler work")
    local other=new(e.UIParent)
    h:SetParent(other);now=.1;flush();now=.15;flush()
    check(h.alpha==0,"reparented source rejoins through its new owner")
    local parentMatches=false
    for _,fragment in ipairs(objects)do
        if fragment.decorative and fragment.shown and fragment.path=="original.tga"
            and (fragment:GetParent()==other or fragment:GetParent():GetParent()==other) then parentMatches=true end
    end
    check(parentMatches,"pooled fragments follow the source's new parent")
end

do
    local j,new,piece,flush,objects,_,_,_,e=fixture()
    local private={};e.issecretvalue=function(value)return value==private end
    local p=new(e.UIParent)
    local h=piece(p,"Top",{0,-9,100,17});local v=piece(p,"Left",{41,-40,16,80})
    flush()
    h:SetAlpha(private)
    check(h.alpha==private and v.alpha==1,"private native alpha is preserved on its original texture; neighbors are restored")
    for _,o in ipairs(objects)do if o.decorative then check(o.alpha~=private,"private opacity is never forwarded into addon-created fragments")end end
    flush();h:SetAlpha(1);flush()
    check(h.alpha==0,"public alpha recovery can reconnect without a permanent fallback")
    h:SetVertexColor(private,1,1,1)
    check(h.alpha==1 and v.alpha==1,"private paint restores the native source without attempting to inspect it")
    for _,o in ipairs(objects)do if o.decorative then check(o.color[1]~=private,"private color is never copied into junction sprites")end end
    h:SetVertexColor(1,1,1,1);flush()
    check(h.alpha==0,"public color recovery retries the component")
end
for _,style in ipairs({1,2})do
    local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,"class")
    local root=new(e.UIParent);root.unit="targettarget"
    local track=style==1 and {Top=8,Bottom=8,Left=9,Right=9.5}or{Top=9,Bottom=7,Left=9.5,Right=9}
    local sets,parents={},{}
    for i=1,3 do
        local p=new(root);p.level=i;parents[i]=p
        local parts={};sets[i]=parts
        parts.Top=piece(p,"Top",{8,track.Top-17,84,17})
        parts.Bottom=piece(p,"Bottom",{8,-60+track.Bottom-16,84,16})
        parts.Left=piece(p,"Left",{-track.Left,-52,16,44})
        parts.Right=piece(p,"Right",{100-track.Right,-52,16,44})
        for _,key in ipairs({"TL","TR","BL","BR"})do
            parts[key]=piece(p,key,{key:sub(2)=="L" and -track.Left or 100-track.Right,key:sub(1,1)=="T" and -8 or -68,16,16})
            parts[key]:SetTexture("corner-"..i.."-"..key..".tga")
        end
    end
    flush()
    for _,key in ipairs({"TL","TR","BL","BR"})do
        check(sets[1][key]:GetAlpha()==0 and sets[2][key]:GetAlpha()==0 and sets[3][key]:GetAlpha()==1,
            "three coincident unit outlines paint each original corner exactly once")
        for i=1,2 do
            local duplicates=0
            for _,t in ipairs(objects)do
                if t.decorative and t:IsVisible() and t:GetAlpha()>0 and t.path=="corner-"..i.."-"..key..".tga" then duplicates=duplicates+1 end
            end
            check(duplicates==0,"duplicate corner UV fragments cannot remain outside the edge-only clipping rectangles")
        end
    end
    local count=#objects
    parents[3]:Hide();flush()
    for _,key in ipairs({"TL","TR","BL","BR"})do
        check(sets[1][key]:GetAlpha()==0 and sets[2][key]:GetAlpha()==1,"hiding the corner owner restores the next complete outline")
    end
    parents[3]:Show();flush()
    check(#objects==count and sets[2].TL:GetAlpha()==0 and sets[3].TL:GetAlpha()==1,"reappearing duplicate outlines reuse corner ownership without allocations")
end
print(("Border junctions: %d checks PASS; bounded interval/bucket solver, mask-free disjoint fragments, live tint/alpha, two styles, shared panels and overlay/combat lifecycle. Native GPU/FPS/taint pending."):format(checks))

