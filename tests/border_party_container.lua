-- Actual Core/Border and Raid InitLayoutFrames prefix. A negative control only
-- clears _FluxBorderStatic on the exact unit-only container before adoption.
-- Optional arg1 is an archived Layout source; --prototype injects the proposed
-- marker into an ephemeral loaded copy before runtime admission.
-- Native anchor/layout primitives are modeled. This is work/semantic evidence,
-- not a secure-VM, native rendering or latency benchmark.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return math.abs(a-b)<1e-7 end
local bootstrap=read("tests/unit_portrait_overlay_attachment.lua")
bootstrap=bootstrap:sub(1,assert(bootstrap:find("local scenes=0",1,true))-1)
local factory=assert(load(bootstrap.."\nreturn factory","@actual-container-border-model","t",_G))()
local prototype=arg and arg[1]=="--prototype"
local layout=read(arg and arg[1]and not prototype and arg[1]or"RaidFrame/FluxRaidLayout.lua")
local first=assert(layout:find("function FluxRaid_InitLayoutFrames()",1,true))
local last=assert(layout:find("    for i = 1, GROUP_COUNT do",first,true))
local init=layout:sub(first,last-1).."\nend\n"
local function scalar(v)
    if type(v)=="number"then return string.format("%.12g",v)end
    return tostring(v)
end
local function digest(f,visibleOnly)
    local rows={}
    for _,object in ipairs(f.objects)do
        if object:GetObjectType()=="Texture"and object:IsShown()and object.texture
            and (not visibleOnly or object:IsVisible())then
            -- Offline oracle inspects the model's resolved drawing rectangle,
            -- independently of the deliberately unavailable cold native getter.
            -- Production Core still receives nil/private values normally.
            local resolving=f.state.nativeResolve;f.state.nativeResolve=true
            local x,y,w,h=object:GetRect();f.state.nativeResolve=resolving
            local values={object.texture,x,y,w,h,object:GetEffectiveScale(),object:GetAlpha()}
            for _,v in ipairs(object.uv or{})do values[#values+1]=v end
            for i=1,4 do local p=object.vertices and object.vertices[i]or{0,0};values[#values+1]=p[1];values[#values+1]=p[2]end
            for _,v in ipairs(object.color or{})do values[#values+1]=v end
            for i,v in ipairs(values)do values[i]=scalar(v)end
            rows[#rows+1]=table.concat(values,",")
        end
    end
    table.sort(rows);return table.concat(rows,"\n")
end
local function members(f)
    local result={}
    for _,object in ipairs(f.objects)do
        local op=object._junctionOp
        if op then
            local names={}
            for group in pairs(op.members)do names[#names+1]=group.unitOwner or"-"end
            table.sort(names);result[#result+1]=table.concat(names,",")..":"..tostring(op.bits or 0)
        end
    end
    table.sort(result);return table.concat(result,";")
end
local function scene(style,candidate,cold)
    local f=factory(style,0,.75,false,"");local e,B,new,m=f.e,f.B,f.new,f.m
    local state={aligns=0,wakes=0,cold=cold,private=false,privateReads=0,nativeResolve=false}
    f.state=state
    local secret=setmetatable({},{__add=function()error("private arithmetic")end,__mul=function()error("private arithmetic")end})
    e.issecretvalue=function(v)return rawequal(v,secret)end
    local native=m.GetRect
    function m:GetRect()
        if state.nativeResolve then return native(self)end
        if state.cold and not self:IsVisible()then return nil end
        state.nativeResolve=true
        local values={pcall(native,self)};state.nativeResolve=false
        assert(values[1],values[2]);return table.unpack(values,2)
    end
    function m:GetSize()
        if self.rect then return self.rect[3],self.rect[4]end
        return self.width,self.height
    end
    function m:GetNumPoints()return self.allPoints and 2 or#self.points end
    function m:GetPoint(i)
        if self.allPoints then return i==1 and"TOPLEFT"or"BOTTOMRIGHT",self.allPoints,i==1 and"TOPLEFT"or"BOTTOMRIGHT",0,0 end
        local p=self.points[i]
        if p then return p[1],p[2]or self.parent,p[3]or p[1],p[4]or 0,p[5]or 0 end
    end
    local dock=new(e.UIParent);dock.name="FluxRaidContainer";dock:SetSize(340,600)
    dock:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",100,40);e.FluxRaidContainer=dock
    e.State={containerFrame=dock,isInitialized=true,secureConfigured=true,secureRosterPrepared=true}
    if cold then dock:Hide()end
    local text=init
    if candidate and prototype then
        local n;text,n=text:gsub("local container = State.containerFrame","local container = State.containerFrame\n    if container then container._FluxBorderStatic = true end",1)
        check(n==1,"candidate is one guarded container marker at the real initialization owner")
    end
    assert(load("local State=State\n"..text,"@actual-unit-only-container-init","t",e))()
    e.FluxRaid_InitLayoutFrames()
    if not candidate then dock._FluxBorderStatic=nil end
    f.units={}
    for i=1,4 do
        local unit=new(dock);unit.unit="party"..i;unit._fluxPartyMember=true;unit._FluxBorderIndependent=true
        unit.name="FluxUnitFrame_"..unit.unit;e[unit.name]=unit
        unit:SetSize(120,60);unit:SetPoint("TOPRIGHT",dock,"TOPRIGHT",-10,-10-(i-1)*100)
        B:ApplyTo(unit,2,2,2,6);B:SetBorderColor(unit,.2,.5,.8,1)
        local hp=unit:CreateTexture();hp:SetHeight(17);hp:SetWidth(120);hp:SetPoint("CENTER",unit,"TOP",0,-30)
        hp:SetTexture("Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga");hp:SetTexCoord(.004,.816,.004,.070)
        B:RegisterPiece(hp,"Top",true,1);f.units[i]=unit
    end
    for i=1,48 do
        local p=new(e.UIParent);p:SetSize(100,70);p:SetPoint("BOTTOMLEFT",e.UIParent,"BOTTOMLEFT",4000+i*200,4000+i*200)
        local t=p:CreateTexture();t:SetSize(100,17);t:SetPoint("BOTTOMLEFT",p,"BOTTOMLEFT",0,0)
        t:SetTexture("Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga");t:SetTexCoord(.004,.816,.004,.070)
        B:RegisterPiece(t,"Top",true,1)
        if i==48 then
            local get=t.GetRect
            t.GetRect=function(self)
                state.privateReads=state.privateReads+1
                if state.private then return secret,secret,secret,secret end
                return get(self)
            end
            f.privateSource=t
        end
    end
    local align=B.Junctions.AlignNearbyPanels
    B.Junctions.AlignNearbyPanels=function(self,...)state.aligns=state.aligns+1;return align(self,...)end
    local request=e.Flux.Scheduler.Request
    e.Flux.Scheduler.Request=function(...)state.wakes=state.wakes+1;return request(...)end
    f.dock=dock;f.flush()
    check(B.Junctions.stats.fallback==nil,"prepared four-member source compiles within budgets")
    return f
end
local function stats(f)
    local j=f.B.Junctions
    return {reads=j.stats.geometryReads or 0,solves=j.stats.solves or 0,aligns=f.state.aligns,wakes=f.state.wakes,objects=#f.objects}
end
local function delta(a,b)local out={};for k,v in pairs(b)do out[k]=v-a[k]end;return out end
local reports={}
for _,style in ipairs({1,2})do for _,cold in ipairs({false,true})do
    local pair={}
    for _,candidate in ipairs({false,true})do
        local f=scene(style,candidate,cold);local j=f.B.Junctions
        local topology=members(f);local prepared=digest(f,false)
        local before=stats(f)
        if cold then f.dock:Show()else f.dock:Hide()end
        f.flush();local visibility=delta(before,stats(f))
        check(members(f)==topology,"container visibility does not merge independent member scopes: style="..style..
            " cold="..tostring(cold).." candidate="..tostring(candidate)..
            "\nbefore="..topology.."\nafter="..members(f))
        if not cold then
            for _,unit in ipairs(f.units)do check(not unit:IsVisible(),"native parent hide hides prepared unit descendants")end
            f.dock:Show();f.flush()
        end
        check(digest(f,false)==prepared,"visible recovery preserves the exact prepared material/UV/mesh")
        check(j.stats.fallback==nil,"visibility changes preserve compiled output")
        if candidate then
            check(visibility.reads==0 and visibility.solves==0 and visibility.aligns==0 and visibility.wakes==0,
                "unit-only container visibility requires no geometry wake/read/alignment/solve")
        else
            check(visibility.reads>0 and visibility.aligns>0,"baseline untyped container visibility forces global geometry preflight")
        end
        local opacityBefore=stats(f)
        f.dock:SetAlpha(0);f.flush()
        for _,unit in ipairs(f.units)do check(unit:GetEffectiveAlpha()==0,"native ancestor alpha hides prepared unit descendants")end
        f.dock:SetAlpha(1);f.flush()
        local opacity=delta(opacityBefore,stats(f))
        if candidate then
            check(opacity.reads==0 and opacity.aligns==0 and opacity.wakes==0,"unit-only ancestor alpha crossings stay paint-only")
        else check(opacity.reads>0 and opacity.aligns>0,"untyped ancestor alpha crossings retain the baseline read tax")end
        local work=stats(f)
        f.dock:ClearAllPoints();f.dock:SetPoint("BOTTOMLEFT",f.e.UIParent,"BOTTOMLEFT",101,40);f.flush()
        check((j.stats.geometryReads or 0)>work.reads and j.stats.solves>work.solves,"real container move still updates current geometry")
        work=stats(f);f.dock:SetSize(360,620);f.flush()
        check((j.stats.geometryReads or 0)>work.reads and j.stats.solves>work.solves,"real container resize still updates anchored geometry")
        work=stats(f);f.dock:SetScale(1.2);f.flush()
        check((j.stats.geometryReads or 0)>work.reads and j.stats.solves>work.solves,"real container scale still updates current geometry")
        local other=f.new(f.e.UIParent);other:SetSize(360,620);other:SetPoint("BOTTOMLEFT",f.e.UIParent,"BOTTOMLEFT",700,40)
        work=stats(f);f.units[1]:SetParent(other);f.flush()
        check((j.stats.geometryReads or 0)>work.reads,"real reparent remains observable")
        f.units[1]:ClearAllPoints();f.units[1]:SetPoint("TOPRIGHT",other,"TOPRIGHT",-10,-10);f.flush()
        local reads=f.state.privateReads;f.state.private=true
        work=stats(f);f.dock:ClearAllPoints();f.dock:SetPoint("BOTTOMLEFT",f.e.UIParent,"BOTTOMLEFT",102,40);f.flush()
        check(f.state.privateReads>reads,"real layout still freshly queries unrelated native availability")
        check((j.stats.geometryReads or 0)>work.reads,"unrelated private availability does not suppress a real layout transaction")
        f.state.private=false
        f.dock:ClearAllPoints();f.dock:SetPoint("BOTTOMLEFT",f.e.UIParent,"BOTTOMLEFT",103,40);f.flush()
        check(j.stats.fallback==nil,"public recovery remains available after opaque geometry")
        local hud=f.privateSource:GetParent()
        work=stats(f);hud:Hide();f.flush()
        check((j.stats.geometryReads or 0)>work.reads and j.stats.solves>work.solves,
            "unrelated generic HUD visibility still changes ordinary topology")
        hud:Show();f.flush()
        pair[candidate and 2 or 1]={visibility=visibility,final=digest(f,true),membership=members(f)}
        reports[#reports+1]="CONTAINER|style="..style.."|cold="..tostring(cold).."|candidate="..tostring(candidate)..
            "|reads="..visibility.reads.."|aligns="..visibility.aligns.."|solves="..visibility.solves.."|wakes="..visibility.wakes..
            "|alphaReads="..opacity.reads.."|alphaAligns="..opacity.aligns.."|alphaWakes="..opacity.wakes
    end
    check(pair[1].final==pair[2].final and pair[1].membership==pair[2].membership,"candidate preserves final mesh/paint and unit membership across all controls")
end end
for _,line in ipairs(reports)do print(line)end
print("Party container borders: "..checks.." checks; "..os.date("!%Y-%m-%dT%H:%M:%SZ")..
    "; actual Core/Border/init prefix;"..(prototype and" EXTERNAL-ONLY PROTOTYPE;"or"").." no native latency claim")
