-- Stable-size drag crossings through the actual strip, host skin and ring code.
-- Optional directory contains the archived Layout.lua, Hosts.lua and Blizzard.lua.
local function Read(path)
    local file=assert(io.open(path,"rb"))
    local source=file:read("*a")
    file:close()
    return (source:gsub("\r\n","\n"))
end

local function Section(source,first,last)
    local from=assert(source:find(first,1,true),first)
    return source:sub(from,assert(source:find(last,from+#first,true),last)-1)
end

local parkedChrome=arg[1]=="--parked-chrome"
local prior=arg[parkedChrome and 2 or 1]
local function Archived(name)
    return prior.."/"..(parkedChrome and "Bars-" or "")..name
end
local baselinePaths=prior and {Archived("Layout.lua"),"Bars/Strip.lua"} or {}
local body=Read("tests/bars_strip_layout_work.lua")
body=body:sub(1,assert(body:find("local candidate=true;local checks=0",1,true))-1)
local env=setmetatable({arg=baselinePaths},{__index=_G})
local fixture=assert(load(body.."\nreturn fixture","@drag-chrome-layout","t",env))()

local function Model(client, current)
    local f=fixture(current)
    local e,flux,bars=f.env,f.flux,f.B
    flux.Client=client
    flux.EBS={}
    local resize,writes=0,0
    local parts={}
    local function Texture(widget,key)
        local t={path=key,parent=widget,shown=true,alpha=1,w=0,h=0,color={1,1,1,1}}
        function t:GetTexture() return self.path end
        function t:SetTexture(path) writes=writes+1;self.path=path end
        function t:ClearAllPoints() writes=writes+1;self.point=nil end
        function t:SetPoint(...) writes=writes+1;self.point={...} end
        function t:SetSize(w,h) writes=writes+1;self.w,self.h=w,h end
        function t:IsShown() return self.shown end
        function t:Show() writes=writes+1;self.shown=true end
        function t:Hide() writes=writes+1;self.shown=false end
        function t:SetAlpha(a) writes=writes+1;self.alpha=a end
        function t:GetAlpha() return self.alpha end
        function t:SetVertexColor(r,g,b,a)
            writes=writes+1
            self.color={string.unpack("ffff",string.pack("ffff",r,g,b,a or 1))}
            self.color[5]=nil
        end
        function t:GetVertexColor() return table.unpack(self.color) end
        function t:SetDrawLayer(...) writes=writes+1;self.layer=table.concat({...},",") end
        function t:SetTexCoord(...) writes=writes+1;self.uv=table.concat({...},",") end
        function t:SetBlendMode(mode) writes=writes+1;self.blend=mode end
        function t:SetAtlas(atlas) writes=writes+1;self.path=atlas end
        return t
    end
    local tint={.3,.4,.7}
    e.FluxBorder.GetThemedVertexRGB=function()return table.unpack(tint)end
    local function file(name)
        return Read(current and "Bars/"..name or Archived(name))
    end
    local blizzard=file("Blizzard.lua")
    local hosts=file("Hosts.lua")
    assert(load(Read("ExtraButtonSystem/Engine/Style.lua"),"@actual-slot-art","t",e))("_FluxUI",{Flux=flux})
    local realResize=flux.EBS.Style.SizeRing
    flux.EBS.Style.SizeRing=function(record) resize=resize+1;return realResize(record) end
    local skin=Section(blizzard,'local EMPTY_SLOT = ','function Blizzard.Prepare()')
    local lockdown=Section(blizzard,"local function InLockdown()","local function CanReplaceBar(")
    assert(load("local Flux, Bars, Blizzard=...\nlocal skinRecords={}\n"..lockdown..skin,
        "@actual-strip-chrome","t",e))(flux,bars,bars.Blizzard)
    assert(load("local Bars, Hosts=...\n"..Section(hosts,"function Hosts.Skin(","function Hosts.FinishSurface")
        ..Section(hosts,"function Hosts.ApplyChrome(","function Hosts.InvalidateKeys"),"@actual-host-skin","t",e))(bars,bars.Hosts)

    bars.ForEachHost(function(host)
        local widget=host.widget
        parts[#parts+1]=widget
        function widget:CreateTexture() return Texture(self,"created") end
        for _,key in ipairs({"NormalTexture","PushedTexture","CheckedTexture","HighlightTexture","Border","SlotArt","SlotBackground"}) do
            widget[key]=Texture(widget,key)
        end
        function widget:SetNormalAtlas(atlas) self.NormalTexture:SetAtlas(atlas) end
        function widget:SetPushedAtlas(atlas) self.PushedTexture:SetAtlas(atlas) end
        function widget:SetNormalTexture(path) self.NormalTexture:SetTexture(path) end
        function widget:SetPushedTexture(path) self.PushedTexture:SetTexture(path) end
        function widget:SetCheckedTexture(path) self.CheckedTexture:SetTexture(path) end
        function widget:UpdateButtonArt() self.NormalTexture:SetTexture("native-restyle") end
    end)
    bars.Hosts.ApplyChrome()
    function f.cross(inside)
        f.cursor="spell"
        f.hover=inside
        f.reset()
        resize,writes=0,0
        bars.Layout.OnDragHover()
        f.drain()
        assert(f.counts().commit==1,"real crossing finishes one border transaction")
        return resize,writes
    end
    function f.art()
        local values={}
        for _,widget in ipairs(parts) do
            if widget.shown and not widget._fluxParked then
                for _,key in ipairs({"NormalTexture","PushedTexture","CheckedTexture","HighlightTexture","Border","SlotArt","SlotBackground","BackgroundTexture","_fluxQuickslotRing"}) do
                    local t=widget[key]
                    if t then
                        local p=t.point or {}
                        values[#values+1]=table.concat({t.path,t.w,t.h,t.alpha,tostring(t.shown),t.layer or "",t.uv or "",
                            table.concat(t.color,","),p[1] or "",p[2] and p[2].name or "",p[3] or "",t.blend or ""},":")
                    end
                end
            end
        end
        return table.concat(values,"|")
    end
    f.tint,f.parts,f.Texture=tint,parts,Texture
    return f
end

local clients={
    {"retail",{isPostDF=true}},{"forever",{isForever=true}},{"classic",{isAnyClassic=true}},
}
if parkedChrome or not prior then
    for _,client in ipairs(clients) do
        local before,current=Model(client[2],not prior),Model(client[2],true)
        local firstBefore=before.cross(true)
        local firstAfter=current.cross(true)
        assert(firstAfter<=firstBefore and before.signature()==current.signature() and before.art()==current.art(),
            "the first reveal retains identical geometry and repairs art at new sizes")
        for _,model in ipairs({before,current}) do
            model.cross(false)
            model.B.hosts[1].main.widget:UpdateButtonArt()
        end
        local oldSize,newSize,oldWrites,newWrites=0,0,0,0
        for step=1,60 do
            local entering=step%2==1
            local a,b=before.cross(entering)
            local c,d=current.cross(entering)
            oldSize,newSize,oldWrites,newWrites=oldSize+a,newSize+c,oldWrites+b,newWrites+d
            assert(before.signature()==current.signature() and before.art()==current.art(),
                "warm parking preserves layout, routes and visible artwork on every crossing")
        end
        assert(newSize==0 and newWrites==0,"warm parking performs zero repeat chrome fits or writes")
        if prior then assert(oldSize>newSize and oldWrites>newWrites,"archived parking repeats chrome work") end
        print(("STRIP_PARKED_CHROME %s first=%d/%d steps=60 sizes=%d/%d writes=%d/%d")
            :format(client[1],firstBefore,firstAfter,oldSize,newSize,oldWrites,newWrites))

        local parked=current.B.hosts[6].sec.widget
        assert(parked._fluxParked,"collapsed layout parks the empty secondary face")
        local normal=parked.NormalTexture
        normal:SetAlpha(.2)
        local fits=current.cross(true)
        assert(not parked._fluxParked and fits>0 and normal:GetAlpha()==1,
            "a changed native ring is repaired when the mini becomes visible")
        current.cross(false)
        local main=current.B.hosts[1].main.widget
        main:UpdateButtonArt()
        assert(main.NormalTexture.path~="native-restyle","the native hook repairs art immediately")
        assert(current.cross(true)==0,"the next crossing retains verified art from the native hook")
        current.combat=true
        local shown=main.IsShown
        main.IsShown=function()error("locked art must not sample face visibility")end
        main:UpdateButtonArt()
        main.IsShown=shown
        current.combat=false
        assert(current.cross(false)==1,"a locked art update leaves verification for the next unlocked pass")
    end
    if parkedChrome then return end
end
for _,client in ipairs(clients) do
    local current=Model(client[2],true)
    local before=prior and Model(client[2],false) or Model(client[2],true)
    -- Force the ordinary full skin path if the archive was not supplied.
    if not prior then
        local skin=before.B.Blizzard.SkinButton
        before.B.Blizzard.SkinButton=function(widget) return skin(widget) end
    end
    for step,inside in ipairs({true,false,true,false}) do
        local a,b=before.cross(inside)
        local c,d=current.cross(inside)
        assert(before.signature()==current.signature(),"action mappings and button geometry agree")
        assert(before.art()==current.art(),"visible art agrees")
        assert(a==57 and c<a and d<b,"stable-size crossings avoid bulk sizing and paint")
        print(("STRIP_BUTTON_CHROME|%s|%d|sizing=%d/%d|writes=%d/%d"):format(client[1],step,a,c,b,d))
    end

    for _,m in ipairs({before,current}) do
        local widget=m.B.hosts[1].main.widget
        widget.NormalTexture=m.Texture(widget,"replacement")
        widget.BackgroundTexture:Hide()
    end
    before.cross(true)
    current.cross(true)
    assert(before.art()==current.art(),"replacement and hidden artwork are repaired at equal sizes")
    for _,m in ipairs({before,current}) do m.B.hosts[1].main.widget.NormalTexture:SetAlpha(.4) end
    local normal=current.B.hosts[1].main.widget.NormalTexture
    local getAlpha=normal.GetAlpha
    local private=setmetatable({},{__eq=function() error("private opacity compared") end})
    current.env.issecretvalue=function(value) return rawequal(value,private) end
    normal.GetAlpha=function() return private end
    before.cross(false)
    current.cross(false)
    normal.GetAlpha=getAlpha
    assert(before.art()==current.art(),"unreadable normal opacity takes the original repair path")

    for _,m in ipairs({before,current}) do
        m.env.FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactor=function(_,cols)
            return cols>14 and .83 or 1
        end
        m.B.hosts[1].main.widget.NormalTexture:SetVertexColor(1,0,0,1)
    end
    local resized=current.B.hosts[1].main.widget
    local oldWidth=resized.width
    local getWidth=resized.GetWidth
    resized.GetWidth=function() return oldWidth end
    before.cross(true)
    current.cross(true)
    assert(resized.width~=oldWidth and before.art()==current.art(),"the requested new size wins over a lagging width getter")
    resized.GetWidth=getWidth

    local w=current.B.hosts[1].main.widget
    w:UpdateButtonArt()
    assert(w.NormalTexture.path~="native-restyle","native art hook still reapplies the ordinary skin")
    current.tint[1]=.8
    current.B.Strip.ApplyAppearanceAccent()
    assert(math.abs(w.NormalTexture.color[1]-.8)<1e-6,"explicit accent refresh always applies")
end
print("Strip button chrome: exact layout, visible art, squeeze, native repair and accent controls pass.")
