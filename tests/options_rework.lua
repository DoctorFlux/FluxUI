-- Full production shell/renderer/widgets lifecycle on modeled engine primitives.
-- Native artwork, secure VM, gamepad, persistence and performance are not emulated.
local function read(path)
    if path=="AddonOptions/FluxOptionsShell.lua" and os.getenv("FLUX_OPTIONS_REWORK_SHELL") then path=os.getenv("FLUX_OPTIONS_REWORK_SHELL") end
    if path=="AddonOptions/FluxOptionsRender.lua" and os.getenv("FLUX_OPTIONS_REWORK_RENDER") then path=os.getenv("FLUX_OPTIONS_REWORK_RENDER") end
    if path=="AddonOptions/FluxOptionsNavigation.lua" and os.getenv("FLUX_OPTIONS_REWORK_NAVIGATION") then path=os.getenv("FLUX_OPTIONS_REWORK_NAVIGATION") end
    if path=="AddonOptions/FluxOptionsSkin.lua" and os.getenv("FLUX_OPTIONS_REWORK_SKIN") then path=os.getenv("FLUX_OPTIONS_REWORK_SKIN") end
    if path=="AddonOptions/FluxOptionsCatalog.lua" and os.getenv("FLUX_OPTIONS_CATALOG_SOURCE") then path=os.getenv("FLUX_OPTIONS_CATALOG_SOURCE") end
    if path=="AddonOptions/FluxOptions.lua" and os.getenv("FLUX_OPTIONS_REWORK_OPTIONS") then path=os.getenv("FLUX_OPTIONS_REWORK_OPTIONS") end
    if path=="Battlezonemap/FluxWindowFrame.lua" and os.getenv("FLUX_OPTIONS_REWORK_WINDOW") then path=os.getenv("FLUX_OPTIONS_REWORK_WINDOW") end
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function run(source, env, ns)
    local fn = assert(load(source, "@options-rework", "t", env))
    return fn("_FluxUI", ns)
end
local function nativeSource(client, file)
    local cache=os.getenv("FLUX_OPTIONS_NATIVE_CACHE")
    local root=cache and cache.."/"..client.."/"or"../__AddonsForRef/wow-ui-source-"..client.."/"
    return read(root.."Interface/AddOns/Blizzard_SharedXML/"..file)
end
local function nativeMethod(source, name)
    local first=assert(source:find("function "..name,1,true),name)
    local last=assert(source:find("\nend",first,true),name)+3
    return source:sub(first,last)
end

local function fixture(client)
    local env = setmetatable({unpack = table.unpack or unpack}, {__index = _G})
    env._G = env
    local ns, objects, methods, hooks, jobs = {}, {}, {}, {}, {}
    local function object(kind, name, parent, template)
        local f = setmetatable({engineKind=kind,name=name,parent=parent,template=template,
            shown=true,enabled=true,children={},scripts={},events={},points={}}, {__index=methods})
        if parent then parent.children[#parent.children+1]=f end
        if name then env[name]=f end
        objects[#objects+1]=f
        return f
    end
    function methods:SetPoint(...) self.points[#self.points+1]={...} end
    function methods:ClearAllPoints() self.points={} end
    function methods:SetAllPoints(p) self.allPoints=p or self.parent end
    function methods:SetWidth(v) self.width=v end
    function methods:SetHeight(v) self.height=v end
    function methods:SetSize(w,h) self.width,self.height=w,h end
    function methods:GetWidth() return self.width or 920 end
    function methods:GetHeight() return self.height or 480 end
    function methods:SetScale(v) self.scale=v end
    function methods:GetScale() return self.scale or 1 end
    function methods:SetFrameLevel(v) self.level=v end
    function methods:GetFrameLevel() return self.level or (self.parent and self.parent:GetFrameLevel()+1) or 1 end
    function methods:SetFrameStrata(v) self.strata=v end
    function methods:GetFrameStrata() return self.strata or "DIALOG" end
    function methods:GetParent() return self.parent end
    function methods:GetName() return self.name end
    function methods:GetChildren() return table.unpack(self.children) end
    function methods:SetParent(p)
        if self.parent then for i=#self.parent.children,1,-1 do if self.parent.children[i]==self then table.remove(self.parent.children,i) end end end
        self.parent=p; if p then p.children[#p.children+1]=self end
    end
    function methods:SetScript(key, fn) self.scripts[key]=fn end
    function methods:HookScript(key, fn)
        local old=self.scripts[key]
        self.scripts[key]=function(...) if old then old(...) end; fn(...) end
    end
    function methods:Fire(key, ...) if self.scripts[key] then self.scripts[key](self, ...) end end
    function methods:Show() local was=self.shown; self.shown=true; if not was then self:Fire("OnShow") end end
    function methods:Hide() local was=self.shown; self.shown=false; if was then self:Fire("OnHide") end end
    function methods:SetShown(v) if v then self:Show() else self:Hide() end end
    function methods:IsShown() return self.shown end
    function methods:IsMouseOver() return false end
    function methods:RegisterEvent(e) self.events[e]=true end
    function methods:UnregisterEvent(e) self.events[e]=nil end
    function methods:UnregisterAllEvents() self.events={} end
    function methods:CreateTexture(name) return object("Texture",name,self) end
    function methods:CreateFontString(name) return object("FontString",name,self) end
    function methods:SetText(v) self.text=v; self:Fire("OnTextChanged") end
    function methods:GetText() return self.text or "" end
    function methods:GetStringWidth() return #self:GetText()*7 end
    function methods:GetUnboundedStringWidth() return self:GetStringWidth() end
    function methods:GetStringHeight() return 16 end
    function methods:GetFontString() self.Text=self.Text or object("FontString",nil,self); return self.Text end
    function methods:SetTextColor(...) self.color={...} end
    function methods:SetTexture(v) self.texture=v end
    function methods:SetAtlas(v) self.atlasName=v end
    function methods:SetHorizTile(v)self.horizTile=v end
    function methods:SetVertTile(v)self.vertTile=v end
    function methods:SetVertexColor(...) self.vertex={...} end
    function methods:SetAlpha(v) self.alpha=v end
    function methods:SetBackdrop(v) self.backdrop=v end
    function methods:SetBackdropColor(...) self.backdropColor={...} end
    function methods:SetBackdropBorderColor(...) self.borderColor={...} end
    function methods:SetHighlightTexture(v) self.highlight=v end
    function methods:SetNormalTexture(v) self.normal=v end
    function methods:SetPushedTexture(v) self.pushed=v end
    function methods:SetThumbTexture(v) self.thumb=v end
    function methods:SetChecked(v) self.checked=v;self.paints=(self.paints or 0)+1 end
    function methods:SetEnabled(v) self.enabled=v end
    function methods:Enable() self.enabled=true end
    function methods:Disable() self.enabled=false end
    function methods:EnableMouse(v) self.mouse=v end
    function methods:SetID(v) self.id=v end
    function methods:SetValueStep(v) self.step=v end
    function methods:GetValue() return self.value or 0 end
    function methods:SetValue(v)
        local lo,hi=self:GetMinMaxValues(); v=math.max(lo,math.min(hi,v))
        if self.value~=v then self.value=v; self:Fire("OnValueChanged",v) end
    end
    function methods:SetMinMaxValues(lo,hi) self.lo,self.hi=lo,hi end
    function methods:GetMinMaxValues() return self.lo or 0,self.hi or 100 end
    function methods:SetVerticalScroll(v) self.scroll=v end
    function methods:SetHorizontalScroll(v) self.horizontal=v end
    function methods:GetHorizontalScroll() return self.horizontal or 0 end
    function methods:SetScrollChild(v) self.scrollChild=v end
    for _,key in ipairs({"SetJustifyH","SetJustifyV","SetWordWrap","SetFontObject","SetTextInsets",
        "SetTexCoord","SetOrientation","SetObeyStepOnDrag","SetToplevel","SetMovable","SetResizable",
        "SetClampedToScreen","SetResizeBounds","SetMinResize","SetMaxResize","SetClipsChildren",
        "EnableMouseWheel","SetAutoFocus","RegisterForDrag","StartMoving","StopMovingOrSizing",
        "StartSizing","ClearFocus","SetMultiLine","SetNormalFontObject","SetHighlightFontObject","SetDisabledFontObject",
        "SetDrawLayer","SetSnapToPixelGrid","SetTexelSnappingBias"}) do methods[key]=function() end end
    function methods:SetTexCoord(...)self.coords={...}end
    env.CreateFrame=function(kind,name,parent,template)
        local f=object(kind,name,parent,template)
        if template=="PortraitFrameTemplate" then
            f.CloseButton=object("Button",nil,f)
            f.PortraitContainer=object("Frame",nil,f)
            f.PortraitContainer.portrait=object("Texture",nil,f.PortraitContainer)
            f.Bg=object("Texture",nil,f);f.Bg.horizTile,f.Bg.vertTile=true,true
            f.layoutType="PortraitFrameTemplate"
            for key,value in pairs(env.PortraitFrameMixin)do f[key]=value end
            f.TitleContainer=object("Frame",nil,f)
            f.TitleContainer.TitleText=object("FontString",nil,f.TitleContainer)
            f.NineSlice=object("Frame",nil,f)
            for key,value in pairs(env.NineSlicePanelMixin)do f.NineSlice[key]=value end
            f.NineSlice:OnLoad()
            if client~="live"and client~="forever"then
                f.TitleText=object("FontString",nil,f)
                for _,key in ipairs({"PortraitFrame","TopRightCorner","TopBorder","BotLeftCorner","BotRightCorner","BottomBorder","LeftBorder","RightBorder"})do
                    f[key]=object("Texture",nil,f)
                end
                for key,value in pairs(env.PortraitFrameTemplateMixin)do f[key]=value end
                f:OnLoad()
            end
            f:SetScript("OnShow",function() f.nativeShows=(f.nativeShows or 0)+1 end)
            f:SetScript("OnHide",function() f.nativeHides=(f.nativeHides or 0)+1 end)
        elseif template=="MinimalTabTemplate" then
            f.Text=object("FontString",nil,f)
            f.SetSelected=function(self,value) self.selected=value end
            f.GetFontString=function() return nil end -- native MinimalTab uses a child FontString
            f.SetText=function() error("MinimalTab text belongs to Text, not ButtonText") end
        elseif template=="MinimalSliderTemplate" then
            f.Middle=object("Texture",nil,f);f.Thumb=object("Texture",nil,f)
            f.thumb=f.Thumb
        elseif template=="WowStyle1DropdownTemplate" then
            f.Text=object("FontString",nil,f)
            f.SetupMenu=function(self,fn) self.menuBuilder=fn end
            f.OverrideText=function(self,text) self.Text:SetText(text) end
        elseif template=="SearchBoxTemplate" then
            f.Instructions=object("FontString",nil,f)
            f:SetScript("OnTextChanged",function() f.nativeChanges=(f.nativeChanges or 0)+1 end)
        elseif template=="UICheckButtonTemplate" then f.text=object("FontString",nil,f)
        end
        return f
    end
    env.UIParent=object("Frame"); env.UIParent:SetSize(1360,900)
    env.BackdropTemplateMixin={}
    env.Flux={Client={isForever=client=="forever"}}
    env.C_Texture={GetAtlasInfo=function() return {width=768,height=512,leftTexCoord=0,rightTexCoord=1,topTexCoord=0,bottomTexCoord=1} end}
    env.CreateFromMixins=function(...)
        local result={};for _,mixin in ipairs({...})do for key,value in pairs(mixin)do result[key]=value end end;return result
    end
    env.GetFinalNameFromTextureKit=function(atlas,kit)return kit and atlas:format(kit)or atlas end
    env.GetCVarBool=function(name)assert(name=="useHighResolutionUITextures");return env.highResolution==true end
    local family=(client=="live"or client=="forever")and"Mainline"or"Classic"
    run(nativeSource(client,family.."/NineSliceLayouts.lua"),env,ns)
    run(nativeSource(client,"NineSlice.lua"),env,ns)
    run(nativeSource(client,"PortraitFrame.lua"),env,ns)
    if family=="Classic"then
        env.PortraitFrameTemplateMixin={}
        local shared=nativeSource(client,"Classic/SharedUIPanelTemplates.lua")
        for _,name in ipairs({"OnLoad()","GetTitleText()","SetTitle(title)"})do
            run(nativeMethod(shared,"PortraitFrameTemplateMixin:"..name),env,ns)
        end
    end
    env.C_AddOns={LoadAddOn=function() end}
    env.PanelTemplates_SelectTab=function(b) b.selected=true end
    env.PanelTemplates_DeselectTab=function(b) b.selected=false end
    env.PanelTemplates_TabResize=function(b,_,width) b:SetWidth(width) end
    env.C_Timer={After=function(_,fn) jobs[#jobs+1]=fn end}
    env.InCombatLockdown=function() return env.combat==true end
    env.SetOverrideBindingClick=function() env.binding=true end
    env.ClearOverrideBindings=function() env.binding=false end
    env.UISpecialFrames={"OtherAddon"}
    env.wipe=function(t) for k in pairs(t) do t[k]=nil end end
    env.PlaySound=function() end
    env.SOUNDKIT={IG_MAINMENU_OPTION=1}
    env.LibStub=function() return nil end
    env.hooksecurefunc=function(t,key,fn) hooks[#hooks+1]={t,key,fn}; local old=t[key]; t[key]=function(...) old(...); fn(...) end end
    local getters,writes=0,0
    local sourceInfo={}
    local roots={}
    run(read("AddonOptions/FluxOptionsCatalog.lua"),env,ns)
    for id,entry in pairs(ns.FluxOptionsCatalog.sources) do
        roots[id]={type="group",name=entry.name,args={
            header={type="header",name="Display",order=1},
            enabled={type="toggle",name="Enable display",order=2,get=function() getters=getters+1;return true end,
                set=function(_,v) writes=writes+1 end},
            unavailable={type="toggle",name="Unavailable sentinel",order=2.5,hidden=true},
            details={type="description",name="Display appearance and behavior",order=3},
            size={type="range",name="Size",order=4,min=1,max=10,step=1,get=function() return 5 end,set=function() writes=writes+1 end},
            advanced={type="header",name="Performance",order=5},
            secret={type="toggle",name="Private test option",hidden=true,order=6},
            feature={type="toggle",name="Deferred repaint",order=7,get=function() return true end},
        }}
    end
    roots.actionbars={type="group",name="Action Bars",childGroups="tab",args={
        bar={type="group",name="Bars",order=1,args={enabled={type="toggle",name="Enable bars",get=function() return true end}}},
        extra={type="group",name="Extra buttons",order=2,args={consumableSwapHeader={type="header",name="Consumables",order=1},
            consumableSwapFoodWater={type="toggle",name="Drink water",desc="Unique aquamarine refill",order=2,
                get=function(info)sourceInfo.get=info;return true end,set=function(info)sourceInfo.set=info end}}},
        hidden={type="group",name="Invisible",hidden=true,args={x={type="toggle",name="Invisible sentinel"}}},
    }}
    roots.unitframes={type="group",name="Unit Frames",childGroups="tab",args={
        general={type="group",name="General",args={scopeHeader={type="header",name="Settings",order=0},
            useFluxPlayer={type="toggle",name="Use Flux player frame",order=1,get=function()return true end},
            featuresHeader={type="header",name="Features",order=2},use3DPortraits={type="toggle",name="3D portraits",order=3,get=function()return true end},
            auraTimersUnderMinute={type="toggle",name="Aura timers below one minute",order=4,get=function()return false end},
            threatBarVisibility={type="select",name="Threat visibility",order=5,values={always="Always",never="Never"},get=function()return "always"end}}},
        unitPlayer={type="group",name="Player",args={playerWidth={type="range",name="Player width",min=100,max=400,step=1,get=function()return 200 end}}},
        unitTarget={type="group",name="Target",args={targetWidth={type="range",name="Target width",min=100,max=400,step=1,get=function()return 200 end}}},
        unitFocus={type="group",name="Focus",hidden=function()return env.testFocusHidden end,args={focusWidth={type="range",name="Focus width",min=100,max=400,step=1,get=function()return 200 end}}},
        unitPet={type="group",name="Pet",args={petWidth={type="range",name="Pet width",min=100,max=400,step=1,get=function()return 200 end}}},
        partyRaid={type="group",name="Party / Raid",hidden=function()return env.testPartyHidden end,args={
            partyStyle={type="group",name="Party frames",inline=true,disabled=function()return env.testPartyLocked end,args={
                enabled={type="toggle",name="Party frame styling",desc="Unique marigold party style",order=1,
                    get=function(info)sourceInfo.partyGet=info;return true end,set=function(info)sourceInfo.partySet=info end}}},
            header={type="header",name="Raid layout",order=2},enabled={type="toggle",name="Raid health text",order=3,get=function()return true end}}},
        castBarThemes={type="group",name="Cast bar themes",args={enabled={type="toggle",name="Enable school themes",get=function()return true end}}},
    }}
    local generations={}
    env.FluxOptions={ResolveModuleOptions=function(_,id)return roots[id]end,GetProfilesOptions=function()return roots.profiles end,
        GetModuleGen=function(_,id)return generations[id]or 0 end,GetConfigStatusText=function()return "Account-wide"end}
    env.FluxOptions.RegisterModuleOptions=function(_,id,builder)roots[id]=builder()end
    env.FluxOptions.IsLayoutCharacterSpecific=function()return env.layoutCharacter==true end
    env.FluxOptions.SetLayoutCharacterSpecific=function(_,value)env.layoutCharacter=value end
    env.FluxOptions.ResetLayoutToDefaults=function()env.layoutResets=(env.layoutResets or 0)+1 end
    run(read("AddonOptions/FluxOptionsLayout.lua"),env,ns)
    objects[#objects]:Fire("OnEvent","ADDON_LOADED","_FluxUI")
    roots.fluxwindow.args.headerMeter={type="header",name="Damage meter",order=20}
    roots.fluxwindow.args.meterEditor={type="description",name="Meter layout editor sentinel",order=21}
    roots.statusBars.args.invTipHeader={type="header",name="Inventory awareness",order=12.5}
    roots.statusBars.args.invTipShowItems={type="toggle",name="Show item locations on tooltips",order=12.52,
        disabled=function()return env.syndicatorOwnsTips==true end,
        get=function(info)sourceInfo.inventoryGet=info;return true end,
        set=function(info)sourceInfo.inventorySet=info end}
    env.createdWidgets={}
    local ace={}
    function ace:Create(kind)
        local widget={type=kind,frame=env.CreateFrame("Frame")};widget.frame:SetHeight(180)
        function widget:OnWidthSet(width)self.lastWidth=width end
        self.last=widget;env.createdWidgets[#env.createdWidgets+1]=widget;return widget
    end
    function ace:Release(widget)widget.released=true;widget.frame:Hide()end
    env.LibStub=function(name)if name=="AceGUI-3.0"then return ace end end
    for _,name in ipairs({"FluxOptionsWidgets","FluxOptionsSkin","FluxOptionsRender","FluxOptionsNavigation","FluxOptionsShell"}) do
        run(read("AddonOptions/"..name..".lua"),env,ns)
    end
    local shell=ns.FluxOptionsShell
    env.FluxOptions.ShowConfig=function(_,page,sub) shell:Show(page,sub) end
    local function flush() while #jobs>0 do local fn=table.remove(jobs,1); fn() end end
    return env,ns,shell,objects,roots,function()return getters,writes end,flush,hooks,sourceInfo,generations
end

local clients={"live","forever","classic","classic_era","classic_anniversary"}
if os.getenv("FLUX_OPTIONS_REWORK_CLIENT")then clients={os.getenv("FLUX_OPTIONS_REWORK_CLIENT")}end
for _,client in ipairs(clients) do
    local env,ns,shell,objects,roots,counters,flush,hooks,sourceInfo,generations=fixture(client)
    shell:Show("general")
    check(shell.frame.template=="PortraitFrameTemplate"and shell.frame:GetTitleText():GetText()=="FluxUI",client..": native window template and title mixins")
    if client=="live"or client=="forever"then
        check(shell.frame.NineSlice.TopLeftCorner and shell.frame.NineSlice.TopLeftCorner.atlasName=="UI-Frame-PortraitMetal-CornerTopLeft",client..": native child OnLoad initializes the portrait NineSlice")
    else
        check(shell.frame.NineSlice.TopLeftCorner==nil and shell.frame.SetBorder~=nil,client..": Classic inherits SetBorder without a portrait NineSlice layout")
        local ok,err=pcall(shell.frame.SetBorder,shell.frame,"PortraitFrameTemplate")
        check(not ok and tostring(err):find("userLayout",1,true),client..": real native method reproduces the reported nil-layout failure")
        env.highResolution=true;shell.frame:OnLoad()
        check(shell.frame.PortraitFrame.atlasName=="UI-Frame-Portrait-2x"and shell.frame.RightBorder.atlasName=="!UI-Frame-RightTile2x",client..": Classic native high-resolution border initialization retained")
        env.highResolution=false
    end
    check((shell.frame.Bg.atlasName=="ui-journeys-bg")== (client=="forever"),client..": Forever artwork stays client-specific")
    local systemButtons=0
    for _,button in ipairs(shell.navButtons)do if button.parent==shell.systemNav then systemButtons=systemButtons+1 end end
    check(systemButtons==4,client..": four reference system pages stay in the fixed sidebar footer")
    for _,button in ipairs(shell.navButtons)do
        local entry=ns.FluxOptionsCatalog.pages[button.pageId]
        local expectedIcon=entry.icon
        if button.subKey then for _,tab in ipairs(entry.tabs)do if tab.key==button.subKey then expectedIcon=tab.icon;check(button.label:GetText()==tab.name,client..": sidebar child has its section label")end end end
        check(button.icon.shown and button.icon.texture==expectedIcon,
            client..": visible fitting icon beside "..button.pageId)
        check(button.height<=24 and button.icon.height==16,client..": compact sidebar row and icon fit "..button.pageId)
    end
    for _,header in ipairs(shell.navHeaders)do
        check(header.height<=20 and header.backdrop and header.borderColor,client..": compact framed category header")
    end
    check(shell.frame.nativeShows==1 and shell.frame.nativeHides==1,client..": inherited window lifecycle preserved")
    check(#env.UISpecialFrames==1 and env.binding,client..": Escape uses only shell override")
    if client=="forever"then
        check(shell.frame.Bg.horizTile==false and shell.frame.Bg.vertTile==false,client..": atlas background disables inherited native tiling")
        shell.frame.Bg:Hide();shell.frame.Bg:SetAlpha(0);shell.frame:SetSize(860,520);shell.frame:Fire("OnSizeChanged",860,520)
        local uv=shell.frame.Bg.coords
        check(shell.frame.Bg.shown and shell.frame.Bg.alpha==1 and uv and uv[1]>=0 and uv[2]<=1 and uv[3]>=0 and uv[4]<=1,client..": background stays visible with bounded cover crop when resized smaller")
        shell.frame:SetSize(1240,780);shell.frame:Fire("OnSizeChanged",1240,780);flush()
    else check(shell.frame.Bg.horizTile and shell.frame.Bg.vertTile,client..": other clients keep their native tiled background")end
    local page=shell.active
    local minimalSliders=0
    for _,object in ipairs(objects)do if object.template=="MinimalSliderTemplate" then
        minimalSliders=minimalSliders+1
        check(object.thumb==object.Thumb and object.fill and not object.fill.shown,client..": native slider keeps its own knob and track")
    end end
    check((minimalSliders>0)==(client=="forever"),client..": reference slider artwork is limited to Forever")
    local header=page.rows[1]
    check(header.card and header.card.shown,client..": shared renderer creates a section card")
    header:Fire("OnClick")
    check(not page.rows[2].shown and page.rows[1].shown,client..": collapse retains accessible header")
    shell.search:SetText("Enable display")
    check(page.rows[2].shown,client..": search reveals a folded match")
    shell.search:SetText("")
    check(not page.rows[2].shown,client..": clearing search restores fold")
    header:Fire("OnClick")
    local toggle
    for _,f in ipairs(objects) do if f.parent==page.rows[2] and f.template=="UICheckButtonTemplate" then toggle=f end end
    check(toggle and toggle.checked,client..": native checkbox receives stored value")
    local _,before=counters();toggle:Fire("OnClick")
    local _,after=counters();check(after==before+1 and not toggle.checked,client..": control calls original setter once")
    local count,sub=ns.FluxOptionsRender.Search(roots.actionbars,"aquamarine")
    check(count==1 and sub=="extra",client..": full declaration search identifies matching tab")
    local gets=counters(); ns.FluxOptionsRender.Search(roots.general,"display")
    check(counters()==gets,client..": search does not invoke getters")
    check(ns.FluxOptionsRender.Search(roots.actionbars,"invisible")==0,client..": hidden groups excluded from results")
    shell:Select("actionbars","bar")
    shell.search:SetText("Extra Buttons")
    check(shell.pageId=="actionbars" and shell.subKey=="buttons",client..": category title finds its relocated settings")
    local titleMatchVisible=false
    for _,row in ipairs(shell.active.rows)do if row.kind=="toggle" and row.searchText:find("aquamarine",1,true) and row.shown then titleMatchVisible=true end end
    check(titleMatchVisible,client..": matching a subpage title reveals its controls")
    shell.search:SetText(" aquamarine ")
    check(shell.pageId=="actionbars" and shell.subKey=="buttons",client..": search jumps across pages and tabs")
    check(shell.search.nativeChanges>0,client..": native search handler retained")
    local matchedVisible=false
    for _,row in ipairs(shell.active.rows)do if row.kind=="toggle" and row.searchText:find("aquamarine",1,true) and row.shown then matchedVisible=true end end
    check(matchedVisible,client..": matched setting visible")
    check(sourceInfo.get and sourceInfo.get.options==roots.actionbars and sourceInfo.get[1]=="extra" and sourceInfo.get[2]=="consumableSwapFoodWater",client..": moved getter retains original Ace root and info path")
    for _,row in ipairs(shell.active.rows)do
        if row.kind=="toggle" and row.searchText:find("aquamarine",1,true) then
            for _,child in ipairs(row.children)do if child.template=="UICheckButtonTemplate" then child:Fire("OnClick") end end
        end
    end
    check(sourceInfo.set and sourceInfo.set.options==roots.actionbars and sourceInfo.set[1]=="extra" and sourceInfo.set[2]=="consumableSwapFoodWater",client..": moved setter retains original Ace root and info path")
    local selectedNative=false
    for _,button in ipairs(shell.tabButtons)do if button.subKey==shell.subKey and button.selected and button.template==(client=="forever"and"MinimalTabTemplate"or"PanelTopTabButtonTemplate") then selectedNative=true end end
    check(selectedNative,client..": client-appropriate native selected tab")
    shell.search:SetText("no such option 439825")
    check(shell.noResults.shown and shell.active.empty.shown,client..": no-result feedback")
    shell.search:SetText("")
    shell:Select("general")
    shell.search:SetText("Unavailable sentinel")
    check(shell.noResults.shown and shell.active.empty.shown,client..": hidden controls cannot leave a matching section header")
    shell.search:SetText("")
    shell:Select("binding")
    check(shell.pageId=="bindings",client..": old binding link opens Bindings")
    shell.search:SetText("macros")
    check(shell.pageId=="bindings"and shell.active.query=="",client..": macro search reveals the complete binding browser")
    shell.search:SetText("")
    -- Execute the real Meter-tab right-click, window forwarding method and
    -- options accessor through the complete production shell.
    local optionsText=read("AddonOptions/FluxOptions.lua")
    local helperStart=assert(optionsText:find("local function OpenFluxUIOptionsToGroup(...)",1,true))
    local helperEnd=assert(optionsText:find("\nfunction FluxOptions:ShowConfig(",helperStart,true))
    local meterStart=assert(optionsText:find("function FluxOptions:OpenToFluxWindowTab()",1,true))
    local damageStart=assert(optionsText:find("function FluxOptions:OpenToDamageMeterTab()",meterStart,true))
    local meterEnd=assert(optionsText:find("\nend",damageStart,true))+4
    run(optionsText:sub(helperStart,helperEnd-1).."\n"..optionsText:sub(meterStart,meterEnd),env,ns)
    env.FluxWindowFrame={}
    local windowText=read("Battlezonemap/FluxWindowFrame.lua")
    local routeStart=assert(windowText:find("local function ShowMeterLayoutMenu(anchor)",1,true))
    local routeEnd=assert(windowText:find("\nfunction FluxWindowFrame:IsMeterEditMode()",routeStart,true))
    run(windowText:sub(routeStart,routeEnd-1),env,ns)
    local clickStart=assert(windowText:find('    tab.button:SetScript("OnClick", function(self, button)',1,true))
    local clickEnd=assert(windowText:find("\n    -- Mouseover effects",clickStart,true))
    local meterClick
    env._optionsMeterTestTab={button={SetScript=function(_,_,fn)meterClick=fn end}}
    run('local name="Meter"; local tab=_optionsMeterTestTab; local activeTab="Map"\n'..windowText:sub(clickStart,clickEnd-1),env,ns)
    shell:Select("qol","interface")
    meterClick({},"RightButton")
    check(shell.pageId=="fluxwindow"and shell.subKey=="damageMeter"and shell.tabBar.shown,client..": actual Meter right-click opens Flux Window > Damage Meter")
    local meterVisible=false;for _,row in ipairs(shell.active.rows)do if row.searchText:find("meter layout editor sentinel",1,true)and row.shown then meterVisible=true end end
    check(meterVisible,client..": Meter destination renders its editor settings")
    env.FluxOptions:OpenToFluxWindowTab()
    check(shell.pageId=="fluxwindow"and shell.subKey=="general",client..": general Flux Window shortcut remains distinct from Meter shortcut")
    env._optionsMeterTestTab=nil
    shell:Select("actionbars","bindings")
    check(shell.pageId=="bindings" and shell.subKey=="settings",client..": old keybinding shortcut opens merged Bindings > Keybindings")
    shell:Select("keybindings")
    check(shell.pageId=="bindings" and shell.subKey=="settings",client..": old Keybindings page opens its merged tab")
    shell.search:SetText("macros")
    check(shell.pageId=="bindings" and shell.subKey=="browser" and shell.active.query=="",client..": macro search leaves Keybindings and reveals the complete browser")
    shell.search:SetText("")
    shell:Select("qol","combat")
    check(shell.pageId=="ufNameplates",client..": old QoL combat link opens Nameplates")
    shell:Select("unitframes","castBarThemes")
    check(shell.pageId=="ufCastBars",client..": old theme link opens Cast Bars")
    shell:Select("unitframes","partyRaid")
    check(shell.pageId=="ufRaid",client..": old raid helper opens Raid Frames")
    shell:Select("unitframes","appearance")
    check(shell.pageId=="ufGeneral"and not shell.tabBar.shown,client..": Appearance and General share one page")
    local headers={};for _,h in ipairs(shell.navHeaders)do headers[h.groupId]=h end
    check(headers.hud and headers.hud.label:GetText()=="HUD",client..": HUD is a framed sidebar category")
    local hudButtons={}
    for _,button in ipairs(shell.navButtons)do
        check(button.pageId~="qol",client..": no Quality of Life sidebar entry")
        if button.groupId=="hud"then hudButtons[button.pageId]=button end
        if button.pageId=="windows"then check(button.groupId=="utilities",client..": Windows is under Utilities")end
    end
    for _,id in ipairs({"layout","chat","info","micromenu","fluxwindow","statusBars"})do
        local button=hudButtons[id];check(button and button.shown,client..": visible HUD entry "..id);button:Fire("OnClick")
        check(shell.pageId==id and shell.breadcrumb:GetText():find("HUD",1,true),client..": HUD entry opens its pane with matching breadcrumb")
    end
    hudButtons.layout:Fire("OnClick")
    local layoutWidget=shell.active.embeds[1]
    check(layoutWidget and layoutWidget.type=="FluxLayoutPreview"and layoutWidget.frame.shown and layoutWidget.lastWidth>0,client..": restored Layout acquires original preview widget and fits it")
    roots.layout.args.layoutSettingsScope.set(nil,"character")
    check(roots.layout.args.layoutSettingsScope.get()=="character",client..": original Layout callback changes its independent scope")
    roots.layout.args.resetLayout.func();check(env.layoutResets==1,client..": original Layout reset remains reachable")
    hudButtons.chat:Fire("OnClick")
    check(not layoutWidget.frame.shown,client..": leaving Layout hides the embedded preview")
    shell.search:SetText("meter layout editor sentinel")
    check(shell.pageId=="fluxwindow"and shell.subKey=="damageMeter"and hudButtons.fluxwindow.selected,client..": search finds meter inside HUD Flux Window")
    shell.search:SetText("")
    check(headers.unitframes and headers.unitframes.label:GetText()=="UNIT FRAME"and headers.lootItems.label:GetText()=="LOOT & ITEMS",client..": framed Unit Frame and Loot & Items headers")
    local frameButtons,itemButtons={},{}
    for _,button in ipairs(shell.navButtons)do
        if button.groupId=="unitframes"then check(button.subKey==nil,client..": merged frame rows open complete entries");frameButtons[button.pageId]=button end
        if button.groupId=="lootItems"then itemButtons[button.subKey]=button end
    end
    for _,id in ipairs({"ufGeneral","ufUnits","ufParty","ufRaid","ufCastBars","ufNameplates"})do
        local button=frameButtons[id];check(button and button.shown,client..": sidebar row "..id);button:Fire("OnClick")
        check(shell.pageId==id and shell.title:GetText()==ns.FluxOptionsCatalog.pages[id].name,client..": frame row opens its merged entry")
        check(shell.tabBar.shown==(id=="ufUnits"),client..": only Individual Frames has inner unit tabs")
        local selected=0;for _,candidate in pairs(frameButtons)do if candidate.selected then selected=selected+1;check(candidate==button,client..": only clicked frame row selected")end end
        check(selected==1,client..": one active frame entry")
    end
    for _,unit in ipairs({"unitPlayer","unitTarget","unitFocus","unitPet"})do
        shell:Select("unitframes",unit)
        check(shell.pageId=="ufUnits"and shell.subKey==unit and shell.tabBar.shown,client..": legacy unit link selects its inner tab")
    end
    for _,key in ipairs({"loot","vendor","restock"})do
        local button=itemButtons[key];check(button and button.shown and button.icon.shown,client..": item sidebar row/icon "..key)
        button:Fire("OnClick");check(shell.pageId=="lootItems"and shell.subKey==key and not shell.tabBar.shown,client..": item row directly opens its settings")
    end
    check(itemButtons.restock.icon.texture=="Interface\\Icons\\INV_Misc_Bag_10",client..": Restock uses the known bag texture")
    shell:Select("statusBars")
    local inventoryFound=false;for _,row in ipairs(shell.active.rows)do if row.searchText:find("inventory awareness",1,true)then inventoryFound=true end end
    check(not inventoryFound,client..": Inventory awareness removed from Status Bars")
    itemButtons.loot:Fire("OnClick")
    local inventoryToggle
    for _,row in ipairs(shell.active.rows)do if row.kind=="toggle"and row.searchText:find("show item locations",1,true)then
        for _,child in ipairs(row.children)do if child.template=="UICheckButtonTemplate"then inventoryToggle=child end end
    end end
    check(inventoryToggle and sourceInfo.inventoryGet.options==roots.statusBars and sourceInfo.inventoryGet[1]=="invTipShowItems",client..": Loot renders inventory settings with original Status Bars source context")
    inventoryToggle:Fire("OnClick")
    check(sourceInfo.inventorySet and sourceInfo.inventorySet.options==roots.statusBars and sourceInfo.inventorySet[1]=="invTipShowItems",client..": moved inventory setter retains its original source context")
    env.syndicatorOwnsTips=true;shell.active:Refresh()
    check(not inventoryToggle.enabled,client..": moved inventory control retains Syndicator delegation gate");env.syndicatorOwnsTips=false
    shell:Select("chat");shell.search:SetText("inventory awareness")
    check(shell.pageId=="lootItems"and shell.subKey=="loot"and itemButtons.loot.selected,client..": Inventory awareness search opens Loot directly")
    shell.search:SetText("")
    shell:Select("ufNameplates")
    local navHeight=shell.navScroll:GetHeight();shell.navScroll:SetHeight(120);shell:FilterSidebar()
    local maxScroll=select(2,shell.navBar:GetMinMaxValues());local selectedTop=-frameButtons.ufNameplates.points[1][5];local offset=shell.navBar:GetValue()
    check(shell.navBar.shown and selectedTop>=offset and selectedTop+24<=offset+120,client..": resized sidebar keeps selected row visible")
    shell.navBar:SetValue(maxScroll);check(shell.navScroll.scroll==maxScroll and shell.systemNav.height==104,client..": scroll reaches lower entries with fixed footer")
    shell.navScroll:SetHeight(navHeight);shell:FilterSidebar()
    for _,id in ipairs({"hud","unitframes","combat","lootItems","utilities"})do
        local header=headers[id];header:Fire("OnClick","LeftButton")
        local hidden=true;for _,button in ipairs(shell.navButtons)do if button.groupId==id and button.shown then hidden=false end end
        check(header.shown and header.indicator:GetText()=="+"and hidden,client..": category minimizes without hiding its header")
        header:Fire("OnClick","LeftButton")
        check(header.indicator:GetText()=="-",client..": category expands again")
    end
    headers.hud:Fire("OnClick","LeftButton")
    meterClick({},"RightButton")
    check(not shell.navCollapsed.hud and hudButtons.fluxwindow.shown and hudButtons.fluxwindow.selected and shell.subKey=="damageMeter",client..": Meter right-click expands minimized HUD and selects its Flux Window entry")
    shell:Select("missing obsolete page")
    check(shell.pageId=="layout"and shell.active.embeds[1].type=="FluxLayoutPreview",client..": missing page falls back to visible HUD Layout")
    headers.unitframes:Fire("OnClick","LeftButton")
    shell:Hide();flush();shell:Show()
    check(shell.navCollapsed.unitframes and not frameButtons.ufParty.shown,client..": ordinary close/reopen remembers minimized categories")
    shell.search:SetText("marigold")
    check(frameButtons.ufParty.shown and frameButtons.ufParty.selected and not frameButtons.ufUnits.shown and frameButtons.ufParty.count:GetText()=="1",client..": search temporarily reveals matching child in minimized group")
    shell.search:SetText("")
    check(shell.navCollapsed.unitframes and not frameButtons.ufParty.shown and headers.unitframes.indicator:GetText()=="+",client..": clearing search restores minimized category")
    shell:Select("unitframes","unitTarget")
    check(not shell.navCollapsed.unitframes and frameButtons.ufUnits.shown,client..": explicit old link expands its minimized category")
    shell:Select("ufParty")
    local partyToggle
    for _,row in ipairs(shell.active.rows)do if row.kind=="toggle"and row.searchText:find("marigold",1,true)then
        for _,child in ipairs(row.children)do if child.template=="UICheckButtonTemplate"then partyToggle=child end end
    end end
    check(partyToggle and sourceInfo.partyGet.options==roots.unitframes and sourceInfo.partyGet[1]=="partyRaid"and sourceInfo.partyGet[2]=="partyStyle"and sourceInfo.partyGet[3]=="enabled",client..": merged layout preserves nested party getter context")
    partyToggle:Fire("OnClick")
    check(sourceInfo.partySet and sourceInfo.partySet.options==roots.unitframes and sourceInfo.partySet[3]=="enabled",client..": nested party setter retains source context")
    env.testPartyLocked=true;shell.active:Refresh();check(not partyToggle.enabled,client..": original parent disabled gate retained");env.testPartyLocked=false
    env.testPartyHidden=true;env.testFocusHidden=true;shell:FilterSidebar()
    local subs=ns.FluxOptionsRender.ListSubpages(ns.FluxOptionsNavigation.Resolve("ufUnits"));local available={};for _,entry in ipairs(subs)do available[entry.key]=true end
    check(not frameButtons.ufParty.shown and not frameButtons.ufRaid.shown and frameButtons.ufUnits.shown and not available.unitFocus,client..": merged entries and inner tabs retain source hidden gates")
    env.testPartyHidden=false;env.testFocusHidden=false
    shell:Select("ufNameplates");local oldView=shell.active
    roots.nameplates.args.enabled={type="toggle",name="Updated nameplate setting",get=function()return true end};generations.nameplates=1;shell:RefreshOpenPageNow()
    check(shell.active~=oldView and oldView.released,client..": direct source page invalidates on original module generation")
    local found=false;for _,row in ipairs(shell.active.rows)do if row.searchText:find("updated nameplate setting",1,true)then found=true end end
    check(found,client..": refreshed source declarations rendered")
    local pages=0
    for id in pairs(ns.FluxOptionsCatalog.pages) do shell:Select(id);check(shell.active and not shell.active.released,client..": reachable page "..id);pages=pages+1 end
    check(pages==21 and #ns.FluxOptionsCatalog.sourceModules==14,client..": merged categories retain all14 feature sources plus profiles")
    shell:Select("general")
    shell.scrollApi.scroll:SetWidth(650);shell.active:Layout()
    check(shell.active.rows[2].width>600,client..": narrow content uses full-width controls")
    shell.scrollApi.scroll:SetWidth(960);shell.active:Layout()
    shell:Hide();flush()
    check(not env.binding and shell.active==nil and next(shell.cache)==nil,client..": close releases page cache and Escape")
    check(layoutWidget.released,client..": closing options releases the restored Layout preview")
    local oldToggle=toggle.checked
    local oldPaints=toggle.paints
    local _,closedWrites=counters();ns.FluxOptionsWidgets.RefreshAccent()
    check(toggle.checked==oldToggle and toggle.paints==oldPaints and select(2,counters())==closedWrites,client..": released rows have no accent callbacks")
    shell:Show("actionbars","bar")
    check(shell.active and shell.subKey=="bars",client..": close/reopen and old bar route work")
    shell:Hide();flush()
    -- Model native menu pool reset, including a lazy-loaded menu and a second addon.
    run(read("AddonOptions/FluxOptionsGameMenu.lua"),env,ns)
    env.GAMEMENU_OPTIONS="Options"
    local menu=env.CreateFrame("Frame","GameMenuFrame",env.UIParent)
    function menu:MarkDirty() self.dirty=true end
    function menu:AddButton(text,callback)
        local b=env.CreateFrame("Button",nil,self);b.layoutIndex=#self.children;b:SetText(text);b:SetScript("OnClick",callback);return b
    end
    function menu:InitButtons()
        for _,b in ipairs(self.children) do b:Hide();b.layoutIndex=nil end
        self:AddButton("Options",function()end); self:AddButton("Other addon",function()end)
    end
    function menu:ResetGamepadButtons() self.navResets=(self.navResets or 0)+1 end
    function menu:SetupGamepadButtons() self.navSetups=(self.navSetups or 0)+1 end
    env.HideUIPanel=function(f) f:Hide() end
    for _,f in ipairs(objects) do if f.events.ADDON_LOADED then f:Fire("OnEvent","ADDON_LOADED","Blizzard_GameMenu") end end
    check(#hooks==1,client..": one menu hook after lazy load")
    for n=1,4 do
        menu:InitButtons()
        local found=0;local entry,options
        for _,b in ipairs(menu.children) do if b.shown and b.text=="FluxUI Settings" then found=found+1;entry=b elseif b.shown and b.text=="Options" then options=b end end
        check(found==1 and entry.layoutIndex>options.layoutIndex and entry.layoutIndex<options.layoutIndex+1,client..": one entry after native settings on rebuild "..n)
        if n==4 then entry:Fire("OnClick");check(shell:IsShown(),client..": menu opens common shell") end
    end
    env.InputUtil={IsGamepadUIEnabled=function()return true end}
    menu:InitButtons()
    local last=menu.children[#menu.children]
    check(last.text=="FluxUI Settings" and last.layoutIndex==#menu.children,client..": gamepad preserves native append/navigation order")
    check(menu.navResets==1 and menu.navSetups==1,client..": native gamepad wrap reset and rebuilt once")
    shell:Hide();flush()
end
print("Options rework: "..checks.." checks; complete shell/renderer/widgets and menu lifecycle across five client models; native acceptance pending")
