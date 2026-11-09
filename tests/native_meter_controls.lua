-- Production picker/backend routing with widget mocks. Optional arg3 replays
-- Blizzard's pinned DropdownButtonMixin:OpenMenu; no native secure VM claim.
local source = arg[1] or "Battlezonemap/FluxBlizzardMeter.lua"
local layoutSource = arg[2] or "Battlezonemap/FluxMeterLayout.lua"
local dropdownSource = arg[3]
local menuSource = arg[4]
local windowSource = arg[5] or "Battlezonemap/FluxWindowFrame.lua"
local arguments = arg; arg = {source,"--harness"}
local harness = assert(loadfile("tests/native_meter_ownership.lua"))(); arg = arguments
local checks = 0
local function check(value,label) checks = checks + 1; assert(value,label) end
local nativeOpen
local nativePick
if dropdownSource then
    local f = assert(io.open(dropdownSource)); local text = f:read("*a"); f:close()
    local first = assert(text:find("function DropdownButtonMixin:OpenMenu()",1,true))
    local last = assert(text:find("\nfunction ",first+1,true))
    nativeOpen = text:sub(first,last-1)
end
if menuSource then
    local f=assert(io.open(menuSource));local text=f:read("*a");f:close()
    local first=assert(text:find("\tlocal function SecureCallResponder(",1,true))
    local last=assert(text:find("\nend\n\n--[[\nA single shared factory",first,true))
    nativePick=text:sub(first,last-1)
end
local names = {"DamageDone","Dps","HealingDone","Hps","Absorbs","Interrupts","Dispels","DamageTaken","AvoidableDamageTaken","Deaths","EnemyDamageTaken"}
for _,gamepad in ipairs({false,true}) do
    local e,s = harness(gamepad)
    for i,name in ipairs(names) do e.Enum.DamageMeterType[name] = i-1 end
    e.C_DamageMeter = { IsDamageMeterAvailable = function() return s.available end }
    e.C_AddOns = { IsAddOnLoaded = function(name) return name=="Details" and s.details end,
        DoesAddOnExist = function(name) return name=="Blizzard_DamageMeter" end }
    e._FluxUI_CharSavedVars = {}
    e.FluxWindowFrame.GetFrame = function() return {Content=s.host} end
    e.FluxWindowFrame.SwitchToTab = function(_,name) s.activeTab=name end
    local notices,opened,picks = {},{},{}
    e.MenuInputContext={MouseButton=1}
    e.DAMAGE_METER_SHOW_NEW_WINDOW="New Window"
    e.MenuUtil={GetElementText=function(description) return description.label end}
    local after
    local pickMethod
    if nativePick then
        e.MenuElementDescriptionProxyMixin={}
        e.Proxies={ToPrivate=function() return {SendResponseToMenu=function() end} end}
        e.securecallfunction=function(fn,...) return fn(...) end
        assert(load("local Proxies=Proxies\n"..nativePick,"@pinned native Menu Pick","t",e))()
        pickMethod=e.MenuElementDescriptionProxyMixin.Pick
    end
    local function description(label,data,responder,children,radio,enabled)
        local d={label=label,native=true,responder=responder}
        function d:EnumerateElementDescriptions() return ipairs(children or {}) end
        function d:GetData() return data end
        function d:IsRadio() return radio end
        function d:CanSelect() return not enabled or enabled() end
        function d:HasResponder() return responder~=nil end
        function d:GetDefaultResponse() end
        function d:SetData() error("native menu data must not be replaced") end
        function d:SetResponder() error("native menu responder must not be replaced") end
        function d:Pick(context,button)
            check(context==e.MenuInputContext.MouseButton,"direct row uses native mouse selection context")
            picks[#picks+1]=self
            if pickMethod then return pickMethod(self,context,button) end
            if self:CanSelect() and responder then responder(self:GetData());return true end
        end
        return d
    end
    local create = e.CreateFrame
    function s.dm:CreateFontString() end -- Native capability for the setup action.
    e.CreateFrame = function(kind,name,parent)
        local f = create(kind,name,parent); f.parent=parent
        function f:EnableMouse() end
        function f:SetFrameLevel() end
        function f:SetBackdrop() end
        function f:SetBackdropColor() end
        function f:SetBackdropBorderColor() end
        function f:SetWidth(value) self.width=value end
        function f:SetHeight(value) self.height=value end
        function f:CreateTexture()
            return {SetAllPoints=function() end,SetColorTexture=function() end,SetAlpha=function() end,Show=function() end,
                SetSize=function() end,SetPoint=function() end,SetTexture=function() end,SetTexCoord=function() end,Hide=function() end}
        end
        function f:CreateFontString()
            return {SetPoint=function() end,SetTextColor=function() end,SetWordWrap=function() end,SetJustifyH=function() end,
                SetText=function(self,text) self.text=text end}
        end
        if parent==s.dm then notices[#notices+1]=f end
        return f
    end
    local function menus(window)
        for _,kind in ipairs({"type","session","settings"}) do
            local button={window=window,kind=kind}
            function button:IsEnabled() return true end
            function button:IsMenuOpen() return false end
            function button:GenerateMenu()
                local categories={}
                if kind=="type" then
                    for _,category in ipairs({{"Damage",{0,1,7,8,10}},{"Healing",{2,3}},{"Actions",{5,6,9}}}) do
                        local children={}
                        for _,value in ipairs(category[2]) do
                            children[#children+1]=description(names[value+1],value,function(nativeData)
                                s.dm:SetSessionWindowDamageMeterType(window,nativeData)
                                after("SetSessionWindowDamageMeterType",window,nativeData)
                            end,nil,true)
                        end
                        categories[#categories+1]=description(category[1],nil,nil,children)
                    end
                elseif kind=="settings" then
                    categories[1]=description("New Window",nil,function()
                        s.dm:ShowNewSecondarySessionWindow();menus(s.windows[#s.windows]);after("ShowNewSecondarySessionWindow")
                    end,nil,false,function() return #s.windows<3 end)
                elseif kind=="session" then
                    for _,option in ipairs({{type=nil,sessionID=42},{type=e.Enum.DamageMeterSessionType.Current},
                        {type=e.Enum.DamageMeterSessionType.Overall}}) do
                        categories[#categories+1]=description("Session",option,function(nativeData)
                            s.dm:SetSessionWindowSessionID(window,nativeData.type,nativeData.sessionID)
                        end,nil,true)
                    end
                end
                self.menuDescription=description("root",nil,nil,categories)
            end
            function button:GetMenuDescription() return self.menuDescription end
            function button:OnMenuOpened() end
            if nativeOpen then
                e.DropdownButtonMixin={}
                e.Menu={GetManager=function() return {OpenMenu=function(_,owner,description)
                    check(description.native,"original dropdown generates native menu description")
                    opened[#opened+1]=owner
                    return {SetClosedCallback=function() end}
                end} end}
                assert(load(nativeOpen,"@pinned DropdownButton OpenMenu","t",e))()
                button.OpenMenu=e.DropdownButtonMixin.OpenMenu
            else
                function button:OpenMenu() opened[#opened+1]=self end
            end
            window[({type="DamageMeterTypeDropdown",session="SessionDropdown",settings="SettingsDropdown"})[kind]]=button
        end
    end
    for _,window in ipairs(s.windows) do menus(window) end
    after=function(method,...)
        for _,fn in ipairs(s.hooks[s.dm] and s.hooks[s.dm][method] or {}) do fn(s.dm,...) end
    end
    assert(loadfile(layoutSource,"t",e))()
    local lib,meter=e.FluxMeterLayout,e.FluxBlizzardMeter
    check(type(lib.GetPickerGroups)=="function" and type(lib.OpenNativeMenu)=="function"
        and type(meter.OpenNativeMenu)=="function","Flux native controls must be available")
    lib.ApplyBuiltin(1)
    local lay=lib.GetWorkingLayout()
    meter:Embed(s.host,lay); s.drain()
    local groups=lib.GetPickerGroups("bottom",1)
    local nativeTypes={}
    for _,group in ipairs(groups) do for _,item in ipairs(group.items or {}) do
        if item.nativeType~=nil then nativeTypes[item.nativeType]=true end
    end end
    check(nativeTypes[0] and nativeTypes[6] and nativeTypes[7] and nativeTypes[10] and not nativeTypes[4],
        "native picker lists native type rows and preserves native Absorbs omission")
    for _,group in ipairs(groups) do for _,item in ipairs(group.items or {}) do
        check(not item.slot or item.slot.kind~="blizzard","native enum request rows no longer masquerade as working type controls")
    end end
    -- Execute the production picker method and its actual OnClick closure too.
    local file=assert(io.open(layoutSource)); local text=file:read("*a"); file:close()
    local first=assert(text:find("    function f:RefreshPicker()",1,true))
    local last=assert(text:find("\n    function f:",first+1,true))
    local refresh=assert(load("local f={}\n"..text:sub(first,last-1).."\nreturn f.RefreshPicker","@production picker","t",e))()
    local child=e.CreateFrame("Frame")
    local editor={pickerChild=child,selectedRow="bottom",selectedIndex=1}
    refresh(editor)
    local function actionFor(label)
        for _,action in ipairs(child._rows) do if action.label.text==label then return action end end
    end
    local direct=assert(actionFor("Dispels"))
    local typeCalls,pickCount=s.typeCalls,#picks
    direct.scripts.OnClick(direct,"LeftButton");s.drain()
    check(s.windows[2].meterType==6 and s.typeCalls==typeCalls+1 and #picks==pickCount+3,
        "actual Flux Dispels row selects native stored entry without a type-menu launcher")
    check(lib.GetWorkingLayout().bottomSlots[1].damageMeterType==6,"direct type row updates the Flux layout label")
    for _,pair in ipairs({{"Combat session...","session"},{"Window settings...","settings"}}) do
        local action=actionFor(pair[1]);local kind=pair[2]
        check(action and action.scripts.OnClick,"real editor creates clickable native menu action")
        action.scripts.OnClick()
        check(opened[#opened].window==s.windows[2] and opened[#opened].kind==kind,
            "real picker OnClick dispatches the selected window's "..kind.." menu")
    end
    local types,sessions,windows=s.typeCalls,s.sessionCalls,#s.windows
    for _,kind in ipairs({"type","session","settings"}) do
        check(lib.OpenNativeMenu("bottom",1,kind),"Flux selected window opens native "..kind.." menu")
        check(opened[#opened].window==s.windows[2] and opened[#opened].kind==kind,"menu belongs to selected Healing window")
    end
    check(s.typeCalls==types and s.sessionCalls==sessions and #s.windows==windows,"opening native controls never issues configuration calls")
    check(not meter:OpenNativeMenu("bad",1,"type") and not meter:OpenNativeMenu("top",1,"bad"),"invalid menu/slot do not open another window's menu")
    -- This is a modeled player choice in the native menu, not an addon writer.
    s.dm:SetSessionWindowDamageMeterType(s.windows[2],6)
    after("SetSessionWindowDamageMeterType",s.windows[2],6); s.drain()
    check(lib.GetWorkingLayout().bottomSlots[1].damageMeterType==6 and not meter:GetLayoutStatus().configurationRequired,
        "native Dispels selection updates the selected Flux slot without an old Healing setup cover")
    check(s.windows[2].meterType==6 and s.typeCalls==types+1,"exactly the player action changed the native type")
    lib.SaveWorkingOverActive()
    check(e._FluxUI_CharSavedVars.fluxWindowBlizzardMeterLayouts[1].bottomSlots[1].damageMeterType==6,
        "existing Save control persists native type choice in a custom layout")
    for value=0,10 do
        check(lib.OpenNativeMenu("bottom",1,"type"),"native type-menu dispatch is stable across all enum-response cases")
        local window=opened[#opened].window
        s.dm:SetSessionWindowDamageMeterType(window,value)
        after("SetSessionWindowDamageMeterType",window,value); s.drain()
        check(lib.GetWorkingLayout().bottomSlots[1].damageMeterType==(value==4 and 3 or value),
            "native responses are adopted; unavailable legacy Absorbs requests normalize in the working copy")
    end
    local stale=lib.GetWorkingLayout()
    lib.SetSlot("bottom",1,{kind="blizzard",damageMeterType=7})
    lib.OnNativeMeterTypeChanged(stale,"bottom",1,5,10)
    check(lib.GetWorkingLayout().bottomSlots[1].damageMeterType==7,"stale native menu cannot replace a newer Flux slot request")
    lib.ApplyBuiltin(2)
    lib.OnNativeMeterTypeChanged(stale,"top",1,5,0)
    check(lib.GetWorkingLayout().topSlots[1].damageMeterType==0,"stale menu cannot edit a newly selected layout")
    -- One explicit setup click uses the native New Window entry and type entry.
    s.dm:SetSessionWindowDamageMeterType(s.windows[2],2)
    after("SetSessionWindowDamageMeterType",s.windows[2],2); s.drain()
    lib.ApplyBuiltin(3); lay=lib.GetWorkingLayout()
    meter:Embed(s.host,lay); s.drain()
    local missing
    for _,notice in ipairs(notices) do if notice:IsShown() and notice.menuKind=="settings" then missing=notice end end
    check(missing and missing.scripts.OnClick,"missing native window is an actionable button")
    check(lib.OpenNativeMenu("top",1,"session") and opened[#opened].kind=="settings",
        "an uncreated slot opens New Window settings instead of another native window's session menu")
    local beforeCreate=#picks
    missing.scripts.OnClick(missing);s.drain()
    check(#s.windows==3 and s.windows[3].meterType==5 and #picks==beforeCreate+3,
        "one setup click creates the third native pane and selects Interrupts/Current through original menu entries")
    s.windows[3].meterType=6;meter:RefreshEmbeddedLayout()
    local setup
    for _,notice in ipairs(notices) do
        if notice:IsShown() and notice.menuRow=="top" and notice.menuColumn==1 then setup=notice end
    end
    check(setup and setup.menuKind=="type","existing mismatched native pane offers its requested type action")
    setup.scripts.OnClick(setup);s.drain()
    check(s.windows[3].meterType==5 and #s.windows==3,"setup type action reuses the existing window")
    check(lay.topSlots[1].damageMeterType==5,"native type response is adopted by its actual row and column")
    check(lib.OpenNativeMenu("top",2,"type") and opened[#opened].window==s.windows[1],
        "second-column action targets its own native window")
    s.dm:SetSessionWindowDamageMeterType(s.windows[1],8)
    after("SetSessionWindowDamageMeterType",s.windows[1],8); s.drain()
    local columns=lib.GetWorkingLayout().topSlots
    check(columns[2].damageMeterType==8 and columns[1].damageMeterType==5,
        "native type choice changes the selected column without editing its neighbor")
    local mapped=meter:GetLayoutStatus()
    check(not mapped.configurationRequired and mapped.sessionChoices[1].damageMeterType==5
        and mapped.sessionChoices[2].damageMeterType==8,
        "docked native windows agree with both edited columns")
    -- Owned Threat remains separate; a four-pane layout cannot become four native windows.
    e.FluxThreatMeter={IsAvailable=function() return true end}
    lib.ApplyBuiltin(8)
    groups=lib.GetPickerGroups("top",1)
    local nativeActions=0
    for _,group in ipairs(groups) do for _,item in ipairs(group.items or {}) do
        if item.nativeMenu or (item.slot and item.slot.kind=="blizzard") then nativeActions=nativeActions+1 end
    end end
    check(nativeActions==0,"owned Threat cannot be configured through another native meter or replaced with a fourth native window")
    local threatFrame=e.CreateFrame("Frame",nil,s.host)
    e.FluxThreatMeter={IsAvailable=function() return true end,GetFrame=function() return threatFrame end,
        Embed=function() return threatFrame end,RefreshLayout=function() end,
        Show=function() threatFrame:Show() end,Hide=function() threatFrame:Hide() end,Cleanup=function() threatFrame:Hide() end}
    lib.ApplyBuiltin(10)
    local split=lib.GetWorkingLayout()
    check(split.topSlots[1].kind=="plugin" and split.topSlots[2].damageMeterType==0
        and split.bottomSlots[1].damageMeterType==5 and split.bottomSlots[2].damageMeterType==2,
        "new layout is Threat/Damage over Interrupts/Healing")
    check(lib.CommitUserLayout() and not meter:GetLayoutStatus().configurationRequired,
        "one layout choice applies all native types without a second setup click")
    lib.ApplyBuiltin(8)
    check(lib.CommitUserLayout() and not meter:GetLayoutStatus().configurationRequired,
        "switching Interrupts layout to Dispels layout applies native Dispels immediately")
    for id=1,lib.GetBuiltinCount() do
        for i,window in ipairs(s.windows) do
            window.sessionType=i==3 and e.Enum.DamageMeterSessionType.Current or e.Enum.DamageMeterSessionType.Overall
            window.sessionID=i>1 and 42 or nil
        end
        lib.ApplyBuiltin(id)
        local beforeSession=s.sessionCalls
        check(lib.CommitUserLayout() and not meter:GetLayoutStatus().configurationRequired,
            "every offered native preset applies all native windows in one user action")
        local status=meter:GetLayoutStatus()
        check(not status.perFightSetupRequired and s.sessionCalls==beforeSession+status.visibleNativePanes,
            "each layout defaults every displayed native pane to Current, including unchanged types and historical selections")
        for _,window in ipairs(s.windows) do
            if window:IsShown() then check(window.sessionType==e.Enum.DamageMeterSessionType.Current and window.sessionID==nil,
                "Current selection uses the native entry's nil historical ID") end
        end
    end
    s.dm:SetSessionWindowSessionID(s.windows[1],e.Enum.DamageMeterSessionType.Overall,nil)
    local manualSessions=s.sessionCalls
    meter:RefreshEmbeddedLayout()
    check(s.windows[1].sessionType==e.Enum.DamageMeterSessionType.Overall and s.sessionCalls==manualSessions,
        "geometry refresh preserves a later manual Overall choice")
    check(lib.CommitUserLayout() and s.windows[1].sessionType==e.Enum.DamageMeterSessionType.Current
        and s.sessionCalls==manualSessions+1,"reselecting the same layout restores Current on its manually overridden pane")
    manualSessions=s.sessionCalls
    check(lib.CommitUserLayout() and s.sessionCalls==manualSessions,"already-Current panes do not receive repeated native selections")
    check(#s.windows==3 and threatFrame~=s.windows[1] and threatFrame~=s.windows[2] and threatFrame~=s.windows[3],
        "all ten layouts preserve three native windows plus the separate Threat frame")
    -- Exercise the actual FluxWindow cycle/setter/tab OnClick code, not just the
    -- editor's CommitUserLayout helper. These used to re-embed geometry only.
    local file=assert(io.open(windowSource));local windowText=file:read("*a");file:close()
    local first=assert(windowText:find("local function GetMeterPresetCount()",1,true))
    local last=assert(windowText:find("\n--- Save tab state",first,true))
    local setterStart=assert(windowText:find("function FluxWindowFrame:SetMeterPresetIndex(",1,true))
    local setterEnd=assert(windowText:find("\nend",setterStart,true))+4
    local clickStart=assert(windowText:find('    tab.button:SetScript("OnClick", function(self, button)',1,true))
    local clickEnd=assert(windowText:find("\n    -- Mouseover effects",clickStart,true))
    local prefix=[[
local activeTab="Meter"
local name="Meter"
local click
local tab={button={SetScript=function(_,_,fn)click=fn end}}
local ResolveMeterSystem=function()return FluxMeterLayout.GetMeterBackend()=="Blizzard" and "BlizzardMeter" or "Details" end
]]
    local suffix=[[
return click,function(value)activeTab=value end
]]
    local click,setActive=assert(load(prefix..windowText:sub(first,last-1).."\n"..windowText:sub(setterStart,setterEnd)
        .."\n"..windowText:sub(clickStart,clickEnd-1).."\n"..suffix,"@actual FluxWindow meter click routes","t",e))()
    lib.ApplyBuiltin(5);check(lib.CommitUserLayout(),"prepare native HPS before actual tab cycle")
    for _,window in ipairs(s.windows)do window.sessionType=0;window.sessionID=nil end
    click({},"LeftButton");s.drain()
    local cycled=meter:GetLayoutStatus()
    check(lib.GetActiveLayoutId()=="builtin:6" and not cycled.configurationRequired and not cycled.perFightSetupRequired
        and cycled.sessionChoices[1].damageMeterType==7,
        "actual active Meter-tab click changes HPS to Damage Taken and Current without a pane click")
    e.FluxWindowFrame:SetMeterPresetIndex(8,true);s.drain()
    check(lib.GetActiveLayoutId()=="builtin:8" and not meter:GetLayoutStatus().configurationRequired,
        "actual FluxWindow preset setter applies Dispels layout completely")
    local beforePlan=#picks
    e.FluxWindowFrame:SetMeterPresetIndex(10,false)
    check(#picks==beforePlan,"planning-only preset setter leaves native configuration alone")
    s.activeTab="Map";setActive("Map");meter:Hide()
    click({},"LeftButton");s.drain()
    check(s.activeTab=="Meter" and not meter:GetLayoutStatus().configurationRequired and not meter:GetLayoutStatus().perFightSetupRequired,
        "actual inactive Meter-tab click applies the requested layout and Current immediately")
    s.activeTab="Map";setActive("Map");meter:Hide();lib.ApplyBuiltin(6)
    check(lib.CommitUserLayout() and s.activeTab=="Meter" and not meter:GetLayoutStatus().configurationRequired
        and meter:GetLayoutStatus().sessionChoices[1].damageMeterType==7,
        "FluxUI options choice while Map is active switches to Meter and applies the new layout, not a stale snapshot")
    s.combat=true;local blocked=#picks
    click({},"LeftButton")
    check(#picks==blocked,"actual Meter-tab OnClick does no native work in combat")
    s.combat=false
    -- Only a queued explicit choice may apply after delayed native readiness.
    meter:Cleanup();e.DamageMeter=nil;s.activeTab="Map"
    lib.ApplyBuiltin(5);check(lib.CommitUserLayout(),"explicit layout request queues while native UI is unavailable")
    lib.ApplyBuiltin(6);local waitingPicks=#picks
    check(lib.CommitUserLayout() and #picks==waitingPicks,"latest waiting layout supersedes the older choice without native work")
    s.windows[1].meterType=0;s.windows[2].meterType=2;s.windows[3].meterType=3
    for _,window in ipairs(s.windows)do window.sessionType=0;window.sessionID=nil end
    e.DamageMeter=s.dm
    meter:Embed(s.host,lib.GetWorkingLayout());s.drain()
    check(not meter:GetLayoutStatus().configurationRequired and not meter:GetLayoutStatus().perFightSetupRequired
        and meter:GetLayoutStatus().sessionChoices[1].damageMeterType==7,
        "existing readiness embed consumes the latest explicit choice and selects native type/Current")
    s.windows[1].sessionType=0;local once=s.sessionCalls
    meter:Embed(s.host,lib.GetWorkingLayout());s.drain()
    check(s.sessionCalls==once and s.windows[1].sessionType==0,"readiness intent is consumed once; ordinary embeds do not force Current")
    for _,cancel in ipairs({"Hide","Cleanup"})do
        e.DamageMeter=nil;lib.ApplyBuiltin(6);lib.CommitUserLayout();meter[cancel](meter)
        e.DamageMeter=s.dm;s.windows[1].meterType=0;s.windows[2].meterType=2;s.windows[3].meterType=3
        local canceled=#picks
        meter:Embed(s.host,lib.GetWorkingLayout());s.drain()
        check(#picks==canceled and meter:GetLayoutStatus().configurationRequired,
            "leaving or cleaning up cancels the delayed native apply intent")
    end
    check(lib.CommitUserLayout(),"restore explicit layout after cancellation cases")
    local quiet,commits,preset=0,0,11
    local detailsEnv=setmetatable({}, {__index=e})
    detailsEnv.FluxWindowFrame={}
    detailsEnv.FluxMeterLayout={GetMeterBackend=function()return "Details" end,GetBuiltinCount=function()return 11 end,
        GetActiveLayoutId=function()return "builtin:"..preset end,ApplyBuiltin=function(id)preset=id end,
        ReembedQuiet=function()quiet=quiet+1 end,CommitUserLayout=function()commits=commits+1 end}
    local detailsClick=assert(load(prefix..windowText:sub(first,last-1).."\n"..windowText:sub(setterStart,setterEnd)
        .."\n"..windowText:sub(clickStart,clickEnd-1).."\n"..suffix,"@actual Details meter choice route","t",detailsEnv))()
    detailsClick({},"LeftButton")
    check(preset==1 and quiet==1 and commits==0,"Details tab cycle retains its immediate quiet re-embed and eleven-preset wrap")
    detailsEnv.FluxWindowFrame:SetMeterPresetIndex(3,true)
    check(preset==3 and quiet==2 and commits==0,"Details preset setter retains its original re-embed path")
    for _,group in ipairs(lib.BuildCatalog()) do for _,item in ipairs(group.items or {}) do
        check(not item.slot or item.slot.damageMeterType~=4,"catalog does not advertise Absorbs")
    end end
    check(not lib.GetBuiltinLabels()[5]:find("Absorbs",1,true) and not lib.SetSlot("top",2,{kind="blizzard",damageMeterType=4}),
        "presets and slot controls reject unavailable Absorbs")
    e.FluxThreatMeter=nil
    lib.ApplyBuiltin(3); meter:Embed(s.host,lib.GetWorkingLayout()); s.drain()
    -- Combat, Details takeover, and cleanup cannot dispatch stale controls.
    local before=#opened
    s.combat=true
    check(not lib.OpenNativeMenu("top",1,"type") and #opened==before,"combat blocks editor/native menu dispatch")
    local beforeSessions=s.sessionCalls
    check(not meter:ApplyCurrentSegments() and s.sessionCalls==beforeSessions,"Current default never writes during combat")
    s.windows[3].meterType=7
    after("SetSessionWindowDamageMeterType",s.windows[3],7)
    s.combat=false; s.event("PLAYER_REGEN_ENABLED"); s.drain()
    check(lib.GetWorkingLayout().topSlots[1].damageMeterType==7,"native type choice survives deferred combat layout repair")
    s.details=true; e.Details={}
    check(not meter:OpenNativeMenu("top",1,"settings") and #opened==before,"Details takeover disables native menu actions")
    check(not meter:ApplyCurrentSegments() and s.sessionCalls==beforeSessions,"Details takeover disables Current selection")
    s.details=false; e.Details=nil; meter:Cleanup()
    check(not meter:OpenNativeMenu("top",1,"settings"),"cleanup retires native menu bridge")
    check(not meter:ApplyCurrentSegments() and s.sessionCalls==beforeSessions,"cleanup retires Current selection")
    check(s.nativeMethodsIntact(),"native meter and entry methods remain unchanged")
    -- Legacy unavailable types normalize only in the working copy. Serialization
    -- of untouched saved custom layouts retains the original request until Save.
    e._FluxUI_CharSavedVars.fluxWindowBlizzardMeterLayouts={{id="user:legacy",name="Legacy",topSlots={{kind="blizzard",damageMeterType=0}},
        bottomSlots={{kind="blizzard",damageMeterType=4}}}}
    e._FluxUI_CharSavedVars.fluxWindowBlizzardMeterActiveLayoutId="user:legacy"
    assert(loadfile(layoutSource,"t",e))()
    lib=e.FluxMeterLayout
    check(lib.GetWorkingLayout().bottomSlots[1].damageMeterType==3,"legacy Absorbs working layout becomes supported HPS")
    lib.ReembedQuiet()
    check(e._FluxUI_CharSavedVars.fluxWindowBlizzardMeterLayouts[1].bottomSlots[1].damageMeterType==4,
        "working repair does not overwrite an untouched serialized custom layout")
end
print(string.format("native meter controls: %d checks; native input/taint/pixels pending; pinned dropdown=%s",checks,tostring(dropdownSource~=nil)))
