-- Shared art/tint lifecycle. Engine primitives are modeled; no native pixel/taint claim.
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function source(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s
end
local keys = { "TL", "TR", "BL", "BR", "Top", "Bottom", "Left", "Right" }
local function model(forever, atlasMode)
    local env = setmetatable({ unpack = table.unpack }, { __index = _G }); env._G = env
    local objects, writes, queries = {}, 0, 0
    local m = {}
    local function object(parent)
        local o = setmetatable({ parent = parent, points = {}, color = {1,1,1,1}, shown = true }, { __index = m })
        objects[#objects + 1] = o; return o
    end
    function m:SetPoint(...) self.points[#self.points + 1] = {...}; writes = writes + 1 end
    function m:SetAllPoints(p) self.allPoints = p; writes = writes + 1 end
    function m:SetHeight(h) self.height=h; writes=writes+1 end
    function m:SetWidth(w) self.width=w; writes=writes+1 end
    function m:GetAtlas() return self.atlas end
    function m:GetTexture() return self.texture end
    function m:GetTexCoord() return table.unpack(self.uv or {0,1,0,1}) end
    function m:SetSize(w,h) self.width,self.height = w,h; writes = writes + 1 end
    function m:SetTexture(p) self.texture,self.atlas = p,nil end
    function m:SetTexCoord(...) self.uv = {...} end
    function m:SetAtlas(p,resize)
        assert(atlasMode ~= "none")
        assert(not (atlasMode == "partial" and p == "!UI-Frame-Metal-EdgeRight"))
        assert(not (atlasMode == "defaultPartial" and p == "battlefieldminimap-border-bottom"))
        self.atlas,self.texture,self.uv = p,nil,nil
        if resize then self:SetSize(16,17) end
    end
    function m:SetVertexColor(...) self.color = {...} end
    function m:GetVertexColor() return table.unpack(self.color) end
    function m:SetColorTexture(...) self.fill = {...} end
    function m:SetFrameStrata(v) self.strata = v end
    function m:GetFrameStrata() return self.strata or "MEDIUM" end
    function m:SetFrameLevel(v) self.level = v end
    function m:GetFrameLevel() return self.level or 1 end
    function m:SetParent(p) self.parent = p end
    function m:GetParent() return self.parent end
    function m:EnableMouse(v) self.mouse = v end
    function m:GetObjectType() return "Frame" end
    function m:CreateTexture() return object(self) end
    function m:Hide() self.shown = false end
    function m:Show() self.shown = true end
    function m:RegisterEvent() end
    function m:UnregisterEvent() end
    function m:SetScript(event,fn) self[event] = fn end
    env.UIParent = object()
    env.CreateFrame = function(_,_,parent) return object(parent) end
    env.UnitClass = function() return "Mage","MAGE" end
    env.RAID_CLASS_COLORS = { MAGE = { r=.2,g=.5,b=.8 } }
    env.Flux = { Client = { isForever = forever } }
    env.C_Texture = { GetAtlasInfo = function(name)
        queries = queries + 1
        if atlasMode == "none" or atlasMode == "partial" and name == "!UI-Frame-Metal-EdgeRight" then return nil end
        return { width=16,height=17 }
    end }
    local appearance = { borderAccent="class", customAccent={r=.3,g=.6,b=.9} }
    env.FluxOptions = { db = { profile = { appearance=appearance } } }
    assert(load(source("FluxBorder.lua"), "FluxBorder", "t", env))("_FluxUI", {})
    return env, env.FluxBorder, appearance, object, function() return #objects,writes,queries end
end

for _, forever in ipairs({false,true}) do
 for _, atlasMode in ipairs({"all","none","partial","defaultPartial"}) do
    local e,b,db,new,counts = model(forever,atlasMode)
    local host,fixed,plain = new(e.UIParent),new(e.UIParent),new(e.UIParent)
    local bf = b:ApplyTo(host,-3,5,2,4)
    b:SetClassColor(host,.4,true)
    b:ApplyTo(fixed); b:SetBorderColor(fixed,.9,.1,.2,.25)
    b:ApplyTo(plain)
    check(b:GetBorderType()==1,"missing saved option retains current border")
    check(bf.TL.atlas==nil and bf.TL.texture:find("Battlefield100.tga",1,true),"type 1 uses its exact canonical canvas rather than copying native atlas UV metadata")
    local original = {}
    for _,key in ipairs(keys) do
        local p = bf[key]
        original[key] = { points=p.points,width=p.width,height=p.height,atlas=p.atlas,texture=p.texture,uv=p.uv }
    end
    for _,key in ipairs(keys) do
        bf[key].GetVertexColor=function()error("style change must not read potentially private gameplay colors")end
    end
    local frameCount,geometryWrites = counts()
    db.borderAccent = "atlas"
    b:RefreshAppearanceDependents()
    check(bf.TL.color[1]==(forever and .502 or 1),"type 1 no-tint preserves Forever exception")
    local choices = b:GetBorderTypeChoices()
    check(choices[1]:find("Border type 1",1,true) and choices[2]:find("Border type 2",1,true),"ordered numbered choices")
    check(choices[2]:find(":255:255:255|",1,true),"type 2 preview is white even while Forever type 1 is selected")
    if forever then check(choices[1]:find(":128:113:71|",1,true),"type 1 Forever preview uses bronze") end
    local option = b:CreateTypeOption(11.5)
    check(option.order==11.5 and option.get()==1 and option.sorting[2]==2,"option contract")
    option.set(nil,2)
    check(db.borderType==2 and b:GetBorderType()==2,"selection persists in active appearance profile")
    check(bf._accentAlpha==.4,"themed alpha is retained without reading texture color values")
    check(b:IsUntintedAtlasAccent() and b:GetThemedVertexRGB()==1,"type 2 no tint stays white")
    check(bf.TL.color[1]==1 and bf.TL.color[4]==.4,"type 2 removes bronze without changing themed alpha")
    check(bf.Background.fill[1]==.15 and bf.Background.fill[4]==.85,"no-tint fill is neutral")
    check(fixed.FluxBorderFrame.TL.color[1]==.9 and fixed.FluxBorderFrame.TL.color[4]==.25,"explicit gameplay RGB and alpha survive art switch")
    check(plain.FluxBorderFrame.TL.color[1]==1,"ApplyTo-only borders receive art and natural accent changes")
    for _,key in ipairs(keys) do
        local p,o = bf[key],original[key]
        check(p.points==o.points and p.width==o.width and p.height==o.height,"art switch preserves each corner/edge geometry")
    end
    check(bf.TL.atlas==nil and bf.TL.texture=="Interface\\AddOns\\_FluxUI\\Texture\\borders\\ForeverMetal150.tga", "all clients use the same extracted Forever art")
    check(bf.TL.uv[1]==211/256 and bf.TL.uv[4]==18/256,"normalized canvas uses exact integer UV bounds")
    local stableFrames,stableGeometry=counts()
    for _,oldWeight in ipairs({50,75,100,125,150,175,200}) do
        db.borderThickness=oldWeight
        b:RefreshAppearanceDependents()
        check(b:GetBorderThickness()==150 and bf.TL.texture:find("ForeverMetal150.tga",1,true),"type 2 ignores obsolete saved thickness")
        option.set(nil,1)
        check(b:GetBorderThickness()==100 and bf.TL.atlas==original.TL.atlas and bf.TL.texture==original.TL.texture,"type 1 always restores original 100% art")
        option.set(nil,2)
    end
    check(not b.CreateThicknessOption,"thickness has no settings factory")
    check(select(1,counts())==stableFrames and select(2,counts())==stableGeometry,"fixed weights never change geometry")
    check(b:GetBorderTypeChoices()[2]:find("Preview2.tga",1,true) and option.desc():find(":48:192:",1,true),"complete dropdown and enlarged tooltip previews")
    option.set(nil,2)
    local n,w,q = counts()
    b:RefreshAppearanceDependents()
    local nn,ww,qq = counts()
    check(n==nn and w==ww and q==qq,"repeated refresh adds no objects/geometry/capability work")
    db.borderAccent="custom"; b:RefreshAppearanceDependents()
    check(bf.TR.color[1]==.3 and bf.TR.color[3]==.9,"custom tint applies to native artwork")
    check(b:GetBorderTypeChoices()[2]:find(":77:153:230|",1,true),"preview follows custom accent")
    option.set(nil,1)
    for _,key in ipairs(keys) do
        local p,o = bf[key],original[key]
        check(p.atlas==o.atlas and p.texture==o.texture,"switch back restores original atlas or texture")
        if o.uv then check(table.concat(p.uv,",")==table.concat(o.uv,","),"legacy UV restore") end
    end
    check(select(1,counts())==frameCount and select(2,counts())==geometryWrites,"switches never recreate frames/textures or touch geometry")
    db.borderType=2
    local later=new(e.UIParent); local laterBF=b:ApplyTo(later,7,8,1,2)
    check(laterBF._borderType==2 and b:ApplyTo(later)==laterBF,"new consumers inherit selected type; ApplyTo remains idempotent")
    -- Execute the actual direct-owner factories, not parallel copies of them.
    local shared=source("UnitFrames/FluxUnitFrames_Shared.lua"):gsub("\r\n","\n")
    local separator=assert(shared:match("local function CreateSeparator%(parent%)(.-)\nend"))
    local icon=assert(shared:match("local function CreateIconBorder%(parent%)(.-)\n    end"))
    local status=source("StatusBars/FluxStatusBar.lua"):gsub("\r\n","\n")
    local column=assert(status:match("local function ApplyVerticalColSeparatorTexture%(vsep%)(.-)\nend"))
    e.ns={Border=b};e.GetStatusBarPixelHeight=function()return 9 end;e.COL_SEP_ATLAS_WIDTH=18
    local makeSep=assert(load("return function(parent)"..separator.."\nend","actual HP/resource separator","t",e))()
    local makeIcon=assert(load("return function(parent)"..icon.."\nend","actual icon edge","t",e))()
    local applyColumn=assert(load("return function(vsep)"..column.."\nend","actual status column","t",e))()
    local sep,edge,col=makeSep(later),makeIcon(later),new(later);applyColumn(col)
    check(sep.texture==laterBF.TL.texture and edge.texture==sep.texture and col.texture==sep.texture,"HP/resource, class icon and status column factories inherit selected art")
    check(b._pieces[sep].key=="Top" and b._pieces[edge].key=="Left" and b._pieces[col].key=="Left","direct owners register semantic pieces centrally")
    applyColumn(col)
    check(col.texture==sep.texture,"ordinary status layout cannot overwrite the selected style")
    local auraSource=source("UnitFrames/FluxUnitFrames_Auras.lua"):gsub("\r\n","\n")
    local legacy=assert(auraSource:match("(local function CreateLegacyBattlefieldBorderPiece.-)\nend")).."\nend"
    local corner=assert(auraSource:match("    local function addCorner%(parent, key, point, xOfs, yOfs, atlas%)(.-)\n    end"))
    local edgeCode=assert(auraSource:match("    local function addEdge%(parent, key, atlas%)(.-)\n    end"))
    e.SafeSetAtlas=function(t,a,resize)return pcall(t.SetAtlas,t,a,resize)end
    local factories="local frame, Border=...; "..legacy.."; local function addCorner(parent,key,point,xOfs,yOfs,atlas)"..corner.."\nend; local function addEdge(parent,key,atlas)"..edgeCode.."\nend; return addCorner,addEdge"
    local auraCorner,auraEdge=assert(load(factories,"actual target/focus aura pieces","t",e))(later,b)
    local auraHost=new(later)
    local ac=auraCorner(auraHost,"TL","TOPLEFT",0,0,"battlefieldminimap-border-topleft")
    local ae=auraEdge(auraHost,"Top","battlefieldminimap-border-top")
    local ab=auraEdge(auraHost,"Bottom","battlefieldminimap-border-bottom")
    local al=auraEdge(auraHost,"Left","battlefieldminimap-border-left")
    local ar=auraEdge(auraHost,"Right","battlefieldminimap-border-right")
    local lower=auraCorner(auraHost,"BL","BOTTOMLEFT",0,0,"battlefieldminimap-border-bottomleft")
    check(ac.width==16 and ac.height==17 and lower.width==16 and lower.height==16,
        "target/focus aura caps use the same canonical sizes as shared unit chrome on atlas and fallback clients")
    check(ae.height==17 and ab.height==16 and al.width==16 and ar.width==16,
        "aura edge dimensions agree with their canonical caps instead of relying on conflicting fallback dimensions")
    check(ac.texture==sep.texture and ae.texture==sep.texture,"actual aura corner/edge factories inherit Forever art")
    check(ac.color[1]==.3 and ac.color[4]==.4,"aura panel uses current accent while retaining faint alpha")
    b:RefreshAppearanceDependents()
    check(sep.texture:find("150Tint.tga",1,true) and edge.texture==sep.texture and col.texture==sep.texture and ac.texture==sep.texture and ae.texture==sep.texture,"thickness reaches all actual divider/icon/aura factories")
    db.borderAccent="atlas";b:RefreshAppearanceDependents()
    check(ac.color[1]==1 and ac.color[4]==.4,"aura no tint preserves native gold without gray vertex tint")
    db.borderType=1;b:RefreshAppearanceDependents()
    check(ac.color[1]==.6 and ac.color[4]==.4,"type 1 restores original aura tint")
    db.borderType=2;b:RefreshAppearanceDependents()
    b:RemoveFrom(host)
    check(b._frames[host]==nil and b._accentFrames[host]==nil and not bf.shown,"removal releases both registries and hides art")
    e.FluxOptions.db.profile={appearance={borderType=1,borderAccent="atlas"}}
    b:RefreshAppearanceDependents()
    check(laterBF._borderType==1,"profile switching refreshes all existing bordered frames")
    check(bf._borderType==2,"removed border is never refreshed again")
    e.FluxOptions.db.profile.appearance.borderType="invalid"
    check(b:GetBorderType()==1,"invalid saved choice safely uses existing type")
 end
end
for _,forever in ipairs({false,true})do
    local e,b,db,new,counts=model(forever,"all")
    check(b:GetJoinTracks().Top==8,"type 1 provides its static geometry contract to the real topology service")
    db.borderType=2;db.borderAccent="custom"
    check(b:GetJoinTracks().Top==9 and b:GetJoinTracks().Right==9,"type 2 exposes the measured fitted tracks")
    local unit=new(e.UIParent);local child=new(unit)
    local bf=b:ApplyTo(child,2,2,2,2)
    local aura=new(child);aura:SetTexture("original.tga");aura:SetTexCoord(0,1,0,1)
    b:RegisterPiece(aura,"Top",true,.4)
    local _,writes=counts()
    b:SetUntinted(unit,true)
    check(bf.Top.texture:find("ForeverMetal150.tga",1,true) and not bf.Top.texture:find("Tint",1,true),"NPC family retains native gold artwork independently of global custom accent")
    check(aura.texture==bf.Top.texture and aura.color[1]==1 and aura.color[2]==1 and aura.color[4]==.4,"nested aura pieces inherit untinted art and retain their faint alpha")
    local _,after=counts();check(after==writes,"NPC tint classification never moves or resizes the unit")
    b:SetUntinted(unit,false)
    check(bf.Top.texture:find("150Tint.tga",1,true) and aura.texture==bf.Top.texture,"player classification restores tintable artwork across the family")
    local classColor={r=.2,g=.6,b=1}
    for _,mode in ipairs({"atlas","custom","class"}) do
        db.borderAccent=mode;b:RefreshAppearanceDependents()
        b:SetUnitColor(unit,classColor)
        b:RefreshAllBorderTypes()
        check(bf.Top.texture:find("150Tint.tga",1,true) and aura.texture==bf.Top.texture,
            "explicit per-unit class chrome always uses neutral type-2 material in every global mode")
        check(aura.color[1]==classColor.r and aura.color[2]==classColor.g and aura.color[3]==classColor.b and aura.color[4]==.4,
            "class-colored aura chrome retains the unit hue and its own alpha")
    end
    db.borderAccent="atlas"
    b:SetUntinted(unit,true)
    check(bf.Top.texture:find("ForeverMetal150.tga",1,true) and not bf.Top.texture:find("Tint",1,true),
        "NPC natural artwork wins over an old player class material during classification changes")
    b:SetUnitColor(unit,nil);b:SetUntinted(unit,false)
    check(bf.Top.texture:find("ForeverMetal150.tga",1,true) and aura.color[1]==1,
        "clearing unit class chrome restores global untinted natural artwork")
    local _,finalWrites=counts();check(finalWrites==writes,"unit-class material switching never changes geometry")
end
print(("Border types: %d checks PASS; atlas/legacy/partial families; native pixels/controller pending"):format(checks))
