-- Portrait geometry parity/lifecycle against the retained production baseline.
-- Heal/absorb native-clip canvas behavior is in prediction_public_geometry.lua.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local source=read("UnitFrames/FluxUnitFrames_Shared.lua")
local function cut(a,b)local i=assert(source:find(a,1,true));return source:sub(i,assert(source:find(b,i+#a,true))-1)end
local helpers=cut("local function ValueIsSecret(value)","local function PlayerDeadOrGhost(unit)")
local candidate=cut("function UF.SyncPortraitModelGeometry(self)","--- Full portrait refresh after resolution")
local baseline=read("tests/fixtures/unit_portrait_geometry_before.txt")
local checks=0
local function check(ok,msg)checks=checks+1;assert(ok,msg)end
local function fixture(body)
    local s={sizeWrites=0,anchors=0,reads=0}
    local env=setmetatable({UF={},API={IsSecretValue=function(v)return type(v)=="table"and v.opaque end}},{__index=_G});env._G=env
    env.C_Timer=setmetatable({},{__index=function()error("portrait geometry must not schedule a timer")end})
    local methods={}
    local function region(name,width)return setmetatable({name=name,width=width,height=width,points={}},{__index=methods})end
    function methods:GetWidth()s.reads=s.reads+1;if self.secret then error("opaque native width getter inspected")end;return self.width end
    function methods:SetSize(w,h)if self.failSize then error("transient model resize")end;self.width,self.height=w,h;s.sizeWrites=s.sizeWrites+1 end
    function methods:ClearAllPoints()self.points={};s.anchors=s.anchors+1 end
    function methods:SetPoint(p,r,rp,x,y)self.points[p]={r.name,rp,x,y};s.anchors=s.anchors+1 end
    local frame={PortraitFrame=region("container",110),Portrait=region("3d",0),Portrait2D=region("2d",0),GetHeight=function()return 110 end}
    assert(load(helpers..body,"@actual-portrait-geometry","t",env))()
    s.frame,s.uf,s.region=frame,env.UF,region
    function s.paint()s.uf.SyncPortraitModelGeometry(frame)end
    function s.state()
        local out={}
        for _,r in ipairs({frame.Portrait,frame.Portrait2D})do
            out[#out+1]=table.concat({r.name,r.width,r.height,table.concat(r.points.CENTER or{},",")},"|")
        end
        return table.concat(out,"\n")
    end
    return s
end
local oldWrites,newWrites=0,0
for _,client in ipairs({"live","forever","classic_era","classic_anniversary","classic"})do
    local a,b=fixture(baseline),fixture(candidate)
    for i=1,300 do a.paint();b.paint();check(a.state()==b.state(),client..": idle paints preserve portrait geometry")end
    oldWrites,newWrites=oldWrites+a.sizeWrites,newWrites+b.sizeWrites
    for _,width in ipairs({90,72,110,50})do
        a.frame.PortraitFrame.width=width;b.frame.PortraitFrame.width=width;a.paint();b.paint()
        check(a.state()==b.state(),"changed public portrait geometry preserves baseline")
    end
    a.frame.PortraitFrame=a.region("replacement.container",50);b.frame.PortraitFrame=b.region("replacement.container",50)
    a.paint();b.paint();check(a.state()==b.state(),"replacement same-size container reanchors")
    b.frame.Portrait.failSize=true;b.frame.PortraitFrame.width=72;b.paint()
    check(b.frame.Portrait._fluxPortraitGeometrySize==nil,"failed resize leaves no accepted cache")
    b.frame.Portrait.failSize=false;b.paint();check(b.frame.Portrait.width==68,"failed resize retries")
    b.frame.Portrait=b.region("replacement.model",0);b.paint();check(b.frame.Portrait.width==68,"new model gets current geometry")
    b.uf.RecordFrameDimensions(b.frame.PortraitFrame,90,90);b.frame.PortraitFrame.secret=true
    local reads=b.reads;b.paint()
    check(b.frame.Portrait.width==86 and b.reads==reads,"public construction dimensions avoid native secret getter")
end
check(newWrites<oldWrites,"idle portrait size writes remain bounded")
local old="region._fluxPortraitGeometryFrame == pf and "
local at=assert(candidate:find(old,1,true));local mutated=candidate:sub(1,at-1)..candidate:sub(at+#old)
local s=fixture(mutated);s.paint();s.frame.PortraitFrame=s.region("new.container",110);s.paint()
check(s.frame.Portrait.points.CENTER[1]~="new.container","negative control catches stale same-size anchor")
print(("idle unit geometry: %d portrait checks; five clients; 300 unchanged size writes %d -> %d; prediction clip/UV checks separate")
    :format(checks,oldWrites,newWrites))
