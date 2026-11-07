-- Actual Layout/Hide modules plus supplied native selection/manager handlers.
-- FLUX_RAID_UPSTREAM_CACHE or arg1 selects the task's pinned source cache.
-- Desktop geometry/input contracts do not establish native pixels or taint.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local layout,hide,compat=read("RaidFrame/FluxRaidLayout.lua"),read("Blizzard/Hide.lua"),read("RaidFrame/FluxRaidCompat.lua")
local cache=arg[1] or os.getenv("FLUX_RAID_UPSTREAM_CACHE")
local checks=0
local function check(ok,why)checks=checks+1;assert(ok,why)end
local function func(source,name)
    local a=assert(source:find("function "..name.."(",1,true))
    local b=source:find("\nfunction ",a+1,true)
    return source:sub(a,b and b-1 or #source)
end
local function fixture(branch,source)
    local e=setmetatable({},{__index=_G});e._G=e
    local s={combat=false,editing=false,enabled=true,raid=true,mt=0,timers={},afterEdit={},widgets={},hooks={},uiScale=1.2,gridX=500,gridTop=300,writes=0,auraTouches=0,gridXReads=0}
    e.secret={}
    e.issecretvalue=function(value)return value==e.secret end
    e.type=function(value)
        assert(value~=e.secret,"opaque native scalar must be checked before inspection")
        return type(value)
    end
    e.InCombatLockdown=function()return s.combat end
    e.FluxEditModeBusy=function()return s.editing end
    e.FluxAfterEditMode=function(fn,key)s.afterEdit[key or fn]=fn end
    e.FluxRaid_IsFluxRaidEnabled=function()return s.enabled end
    e.IsInRaid=function()return s.raid end
    e.IsInGroup=function()return true end
    e.GetRaidRosterInfo=function(i)if i<=s.mt then return "MT"..i,0,1,60,"Warrior","WARRIOR",nil,nil,nil,"MAINTANK"end end
    e.UnitExists=function()return true end
    e.UnitInRaid=function()return 1 end
    e.FluxRaid_DisplayMainTankAndAssistCVarEnabled=function()return true end
    local classic=branch~="live"and branch~="forever"
    e.FLUX_API={isAnyClassic=classic}
    local options={raidManagerScale=.9,showGroupLabels=true}
    e.FluxOptions={GetRaidFrameDB=function()return options end}
    e.FluxRaidVisuals={FRAME_WIDTH=72,FRAME_HEIGHT=43,BLIZZARD_RAID_MANAGER_SCALE=.9*.7}
    local methods={}
    local function widget(name,owned,parent,kind)
        local f=setmetatable({name=name,owned=owned,parent=parent,kind=kind or"Frame",children={},scripts={},hooks={},events={},attrs={},shown=true,
            alpha=1,click=true,motion=true,wheel=true,scale=1,points={},alphaWrites=0},{__index=methods})
        s.widgets[#s.widgets+1]=f
        if parent then parent.children[#parent.children+1]=f end
        if name then e[name]=f end
        return f
    end
    local function write(frame)
        if frame.owned then return end
        check(not s.combat and not s.editing,"native structural changes wait for combat/Edit Mode")
        s.writes=s.writes+1
    end
    function methods:GetName()return self.name end
    function methods:GetObjectType()return self.kind end
    function methods:IsForbidden()return self.forbidden==true end
    function methods:IsProtected()return not self.owned end
    function methods:GetParent()return self.parent end
    function methods:SetParent(parent)write(self);check(not self.nativeGrid,"native grid parent is retained");self.parent=parent end
    function methods:GetChildren()return table.unpack(self.children)end
    function methods:GetAlpha()return self.opaqueAlpha and e.secret or self.alpha end
    local function displayWrite(self)if self.overlay then check(not s.editing,"overlay display changes defer Edit Mode");s.writes=s.writes+1 else write(self)end end
    function methods:SetAlpha(value)displayWrite(self);self.alpha=value;self.alphaWrites=self.alphaWrites+1 end
    function methods:IsIgnoringParentAlpha()return self.ignoreParentAlpha==true end
    function methods:SetIgnoreParentAlpha(value)displayWrite(self);self.ignoreParentAlpha=value end
    function methods:GetAttribute(key)return self.attrs[key]end
    function methods:SetAttribute(key,value)write(self);self.attrs[key]=value end
    function methods:GetScale()return self.scale end
    function methods:GetEffectiveScale()return self==e.CompactRaidFrameManager and self.scale*s.uiScale or s.uiScale end
    function methods:SetScale(value)write(self);self.scale=value end
    function methods:GetLeft()s.gridXReads=s.gridXReads+1;return s.gridX end
    function methods:GetTop()return self.gridTop or s.gridTop end
    function methods:GetBottom()return 0 end
    function methods:GetWidth()return self.width or 72 end
    function methods:GetHeight()return self.height or 140 end
    function methods:SetPoint(...)write(self);self.points={...}end
    function methods:GetPoint()return table.unpack(self.points)end
    function methods:ClearAllPoints()write(self);self.points={}end
    function methods:SetAllPoints()end
    function methods:SetHeight(value)write(self);self.height=value end
    function methods:SetWidth(value)write(self);self.width=value end
    function methods:SetSize(w,h)write(self);self.width,self.height=w,h end
    function methods:SetFrameStrata()end
    function methods:SetFrameLevel()end
    function methods:IsShown()return self.shown end
    function methods:Hide()write(self);check(not self.nativeGrid,"native grid visibility stays native");self.shown=false end
    function methods:Show()
        if not s.nativeVisibility then write(self) end
        self.shown=true
        if self.scripts.OnShow then self.scripts.OnShow(self)end
        for _,fn in ipairs(self.hooks.OnShow or{})do fn(self)end
    end
    function methods:HookScript(event,fn)self.hooks[event]=self.hooks[event]or{};table.insert(self.hooks[event],fn)end
    function methods:SetScript(event,fn)check(self.owned,"native script handlers are retained");self.scripts[event]=fn end
    function methods:RegisterEvent(event)self.events[event]=true end
    function methods:UnregisterEvent(event)self.events[event]=nil end
    function methods:UnregisterAllEvents()self.events={}end
    function methods:IsMouseClickEnabled()return self.click end
    function methods:IsMouseMotionEnabled()return self.opaqueMotion and e.secret or self.motion end
    function methods:IsMouseWheelEnabled()return self.wheel end
    function methods:SetMouseClickEnabled(v)write(self);self.click=v end
    function methods:SetMouseMotionEnabled(v)write(self);self.motion=v end
    function methods:EnableMouseWheel(v)write(self);self.wheel=v end
    function methods:GetNormalTexture()self.normal=self.normal or widget(nil,true,nil,"Texture");return self.normal end
    function methods:SetTexCoord(...)self.coords={...}end
    function methods:SetAtlas(atlas)self.atlas=atlas end
    function methods:SetStatus(status)return e.CompactUnitFrameReadyCheckMixin.SetStatus(self,status)end
    e.CreateFrame=function(_,name,parent)return widget(name,true,parent)end
    e.C_Timer={After=function(_,fn)s.timers[#s.timers+1]=fn end}
    e.hooksecurefunc=function(name,fn)
        local original=e[name]
        e[name]=function(...)local result=original(...);fn(...);return result end
    end
    function s:flush()local timers=self.timers;self.timers={};for _,fn in ipairs(timers)do fn()end end
    function s:leaveEdit()self.editing=false;local q=self.afterEdit;self.afterEdit={};for _,fn in pairs(q)do fn()end end
    e.UIParent=widget("UIParent",true)
    local ns={Flux={}}
    assert(load(hide,"@Blizzard/Hide","t",e))("_FluxUI",ns)
    assert(load(compat,"@FluxRaidCompat","t",e))("_FluxUI",ns)
    local state=e.FluxRaidState
    state.containerFrame=widget("FluxRaidContainer",true,e.UIParent)
    local member=widget("FluxRaidOwnedMember",true,state.containerFrame)
    member.attrs.unit="raid1"
    local header=widget("FluxRaidGrp1",true,state.containerFrame);header.attrs.child1=member;state.raidHeaders[1]=header
    state.isInitialized,state.secureConfigured=true,true
    local root=widget("CompactRaidFrameContainer",false,e.UIParent);root.nativeGrid=true
    local originalEvent=function()end;root.scripts.OnEvent=originalEvent;root.events.GROUP_ROSTER_UPDATE=true
    local pool={}
    function root:ApplyToFrames(mode,fn)check(mode=="all","native public iterator selects all compact cell kinds");for _,f in ipairs(pool)do fn(f)end end
    local function nativeCell(name,parent,alpha)
        local f=widget(name,false,parent)
        f.selectionHighlight=widget(nil,false,f,"Texture")
        f.selectionHighlight.alpha=alpha or.7;f.selectionHighlight.ignoreParentAlpha=true
        f.selectionHighlight.overlay=true
        f.readyCheckIcon=widget(nil,false,f);f.readyCheckIcon.alpha=.8;f.readyCheckIcon.ignoreParentAlpha=true
        f.readyCheckIcon.Icon=widget(nil,false,f.readyCheckIcon,"Texture");f.readyCheckIcon.Icon.alpha=.9;f.readyCheckIcon.Icon.ignoreParentAlpha=true
        f.readyCheckIcon.overlay,f.readyCheckIcon.Icon.overlay=true,true
        f.optionTable={displaySelectionHighlight=true};f.displayedUnit="party1";f.unit="party1"
        pool[#pool+1]=f;return f
    end
    local native=nativeCell("CompactRaidFrame1",root,.7)
    local aura=widget(nil,false,root,"AuraContainer");aura.forbidden=true
    for _,name in ipairs({"GetObjectType","GetChildren","IsMouseClickEnabled","IsMouseMotionEnabled","IsMouseWheelEnabled","GetAlpha"})do
        aura[name]=function()s.auraTouches=s.auraTouches+1;error("forbidden native aura subtree inspected")end
    end
    local party=widget("CompactPartyFrame",false,e.UIParent);party.nativeGrid=true
    party.memberUnitFrames={nativeCell(nil,party,.55)};party.petUnitFrames={}
    local mgr=widget("CompactRaidFrameManager",false,e.UIParent);mgr.scale=1.1
    mgr.displayFrame=widget(nil,false,mgr);mgr.toggleButton=widget(nil,false,mgr)
    mgr.toggleButtonForward=widget(nil,false,mgr);mgr.toggleButtonBack=widget(nil,false,mgr)
    mgr.BottomButtons=widget(nil,false,mgr);mgr.GamepadInputIcon=widget(nil,false,mgr);mgr.GamepadInputIcon.shown=false
    e.InputUtil={IsGamepadUIEnabled=function()return false end}
    e.EditModeManagerFrame={IsEditModeActive=function()return false end}
    e.UnitIsUnit=function(a,b)return a=="party1"and b=="target"end
    local nativeRoot=cache and(cache.."/"..branch)or("../__AddonsForRef/wow-ui-source-"..branch)
    local unitPath=nativeRoot.."/Interface/AddOns/Blizzard_UnitFrame/Shared/CompactUnitFrame"
    local xml=read(unitPath..".xml")
    check(xml:find('parentKey="selectionHighlight".-ignoreParentAlpha="true"')~=nil,"supplied native XML declares selection independent of ancestor alpha")
    check(xml:find('parentKey="readyCheckIcon".-ignoreParentAlpha="true".-parentKey="Icon".-ignoreParentAlpha="true"')~=nil,"native ready-check frame and texture both ignore ancestor alpha")
    local unitSource=read(unitPath..".lua")
    assert(load(func(unitSource,"CompactUnitFrame_UpdateSelectionHighlight"),"@native-selection-"..branch,"t",e))()
    e.CompactUnitFrameReadyCheckMixin={};e.TextureKitConstants={IgnoreAtlasSize=true}
    e.READY_CHECK_READY_TEXTURE_RAID,e.READY_CHECK_NOT_READY_TEXTURE_RAID,e.READY_CHECK_WAITING_TEXTURE_RAID="ready","notready","waiting"
    e.GetReadyCheckStatus=function()return s.readyStatus or"ready"end
    e.GetReadyCheckTimeLeft=function()return 10 end
    assert(load(func(unitSource,"CompactUnitFrameReadyCheckMixin:SetStatus").."\n"..func(unitSource,"CompactUnitFrame_UpdateReadyCheck"),"@native-ready-check-"..branch,"t",e))()
    local managerPath=nativeRoot.."/Interface/AddOns/Blizzard_CompactRaidFrames/"..(classic and"Classic"or"Mainline").."/Blizzard_CompactRaidFrameManager.lua"
    local managerSource=read(managerPath)
    local managerXML=read(managerPath:gsub("%.lua$",".xml"))
    local width,height=managerXML:match('<Frame name="CompactRaidFrameManager".-<Size x="(%d+)" y="(%d+)"')
    mgr.width,mgr.height=assert(tonumber(width)),assert(tonumber(height))
    local toggle=assert(managerXML:match('<Button [^>]-parentKey="'..(classic and"toggleButton"or"toggleButtonForward")..'".-</Button>'))
    local toggleWidth=assert(tonumber(toggle:match('<Size x="(%d+)"')))
    local toggleOffset=assert(tonumber(toggle:match('<Anchor point="RIGHT" x="([%-%.%d]+)"')))
    s.toggleWidth,s.toggleRight=toggleWidth,mgr.width+toggleOffset
    assert(load(func(managerSource,"CompactRaidFrameManager_Expand").."\n"..func(managerSource,"CompactRaidFrameManager_Collapse"),"@native-manager-"..branch,"t",e))()
    assert(load(source or layout,"@FluxRaidLayout","t",e))("_FluxUI",ns)
    return e,s,ns,options,root,native,mgr,member,nativeCell,originalEvent
end

local function exercise(branch,source)
    local e,s,ns,db,root,native,mgr,member,cell,eventHandler=fixture(branch,source)
    root:SetAlpha(0);e.CompactUnitFrame_UpdateSelectionHighlight(native)
    e.CompactUnitFrame_UpdateReadyCheck(native)
    check(native.selectionHighlight.shown and native.selectionHighlight.alpha==.7,"baseline ancestor alpha zero leaves the native selection ghost visible")
    check(native.readyCheckIcon.shown and native.readyCheckIcon.Icon.alpha==.9,"baseline also leaves native ignore-parent ready-check artwork visible")
    root:SetAlpha(1)
    e.FluxRaid_ApplyBlizzardCompactGridHidden();s:flush()
    check(root.alpha==0 and native.selectionHighlight.alpha==0,"dedicated selection alpha removes the ignore-parent ghost")
    check(native.readyCheckIcon.alpha==0 and native.readyCheckIcon.Icon.alpha==0,"dedicated ready frame and texture alpha remove both ignore-parent layers")
    check(root.scripts.OnEvent==eventHandler and root.events.GROUP_ROSTER_UPDATE and root.parent==e.UIParent and root.shown,
        "native scripts/events/parent/visibility stay owned by Blizzard")
    for i=1,100 do
        e.CompactUnitFrame_UpdateSelectionHighlight(native)
        s.readyStatus=({"ready","notready","waiting"})[i%3+1];e.CompactUnitFrame_UpdateReadyCheck(native)
    end
    check(native.selectionHighlight.shown and native.selectionHighlight.alpha==0,"repeated actual native Show updates cannot resurrect the ghost")
    check(native.readyCheckIcon.shown and native.readyCheckIcon.alpha==0 and native.readyCheckIcon.Icon.alpha==0,"actual native ready/waiting/not-ready callbacks cannot resurrect ready-check ghosts")
    check(s.auraTouches==0,"suppression never queries or traverses forbidden native aura children")
    local unknown=cell("CompactRaidFrame2",root,.6);unknown.selectionHighlight.opaqueAlpha=true
    e.FluxRaid_ApplyBlizzardCompactGridHidden();s:flush()
    check(unknown.selectionHighlight.alphaWrites==0,"initial opaque alpha is not compared, snapshotted or guessed")
    check(not unknown.selectionHighlight.ignoreParentAlpha,"opaque-alpha overlays still inherit hidden native grid opacity")
    unknown.selectionHighlight.opaqueAlpha=false
    e.FluxRaid_ApplyBlizzardCompactGridHidden();s:flush()
    check(unknown.selectionHighlight.alpha==0,"later readable native selection is safely added to suppression")
    local pooled=cell(nil,root,.9)
    e.CompactUnitFrame_UpdateSelectionHighlight(pooled)
    check(pooled.selectionHighlight.alpha==0 and not pooled.selectionHighlight.ignoreParentAlpha,
        "late anonymous pooled cells are suppressed by the actual native selection callback without another hide pass")
    pooled.selectionHighlight.alpha=1
    check(not pooled.selectionHighlight.ignoreParentAlpha,"later alpha writes cannot escape the hidden ancestor")
    s.combat=true
    local combatCell=cell("CompactRaidFrameCombat",root,.8)
    s.nativeVisibility=true;e.CompactUnitFrame_UpdateSelectionHighlight(combatCell);s.nativeVisibility=false
    check(combatCell.selectionHighlight.alpha==0 and not combatCell.selectionHighlight.ignoreParentAlpha,
        "late combat-created native highlights are suppressed using unprotected display methods only")
    s.combat=false

    e.FluxRaid_InstallManagerHooks();e.FluxRaid_PositionContainer()
    local classic=branch~="live"and branch~="forever"
    local scale=.9*.7
    check(math.abs(mgr.scale-scale)<1e-8 and db.raidManagerScale==.9,"manager applies the compact70percent baseline without changing saved scale")
    check(mgr.points[1]=="BOTTOMLEFT"and mgr.points[4]==(classic and -7 or 0),"expanded manager keeps original horizontal native anchor")
    local y=mgr.points[5]
    check(math.abs(y*scale*s.uiScale-(s.gridTop+20)*s.uiScale)<1e-8,"full manager bottom clears actual member top and labels")
    s.gridX=s.gridX+300;e.FluxRaid_PositionContainer()
    check(mgr.points[4]==(classic and -7 or 0)and mgr.points[5]==y and s.gridXReads==0,"raid grid X never affects manager X or Y")
    e.CompactRaidFrameManager_Collapse(mgr);s:flush()
    check(mgr.points[4]==(classic and-182 or-200)and mgr.points[5]==y,"collapsed handle preserves native X and exactly the expanded Y reference")
    local toggleRight=(mgr.points[4]+s.toggleRight)*mgr:GetEffectiveScale()
    local toggleLeft=toggleRight-s.toggleWidth*mgr:GetEffectiveScale()
    check(toggleRight>0 and toggleLeft<=0,"actual XML toggle spans screen left after frame point and dimensions share effective scaling")
    mgr:Hide();e.FluxRaid_PositionContainer()
    check(not mgr.shown and mgr.points[5]==y,"hidden manager retains the same full-panel Y without forcing visibility")
    mgr:Show();s:flush();check(mgr.points[5]==y,"native reveal reuses the invariant manager Y")
    e.CompactRaidFrameManager_Expand(mgr);s:flush();check(mgr.points[5]==y,"actual native expand callback returns to identical Y")
    mgr.height=mgr.height+200;e.FluxRaid_PositionContainer()
    check(mgr.points[5]==y,"native panel-height changes do not switch the full-panel bottom reference")
    s.mt=4;e.FluxRaid_PositionContainer()
    check(math.abs(mgr.scale-scale)<1e-8,"tank count cannot change the requested manager size")
    check(math.abs(mgr.points[5]*mgr.scale-y*scale)<1e-8,"manager scale changes preserve physical panel bottom")
    s.mt=0;e.FluxRaid_PositionContainer()
    e.FluxRaidVisuals.BLIZZARD_RAID_MANAGER_SCALE=1;e.FluxRaid_PositionContainer()
    check(mgr.scale==1,"manager size1.00 uses Blizzard's unscaled dimensions")
    check(math.abs(mgr.points[5]-y*scale)<1e-8,"native default size preserves the same physical manager bottom")
    e.FluxRaidVisuals.BLIZZARD_RAID_MANAGER_SCALE=scale;e.FluxRaid_PositionContainer()
    s.gridTop=s.gridTop+40;e.FluxRaid_PositionContainer()
    local raised=mgr.points[5]
    check(math.abs((raised-y)*scale-40)<1e-8,"manager follows only vertical roster movement")
    e.CompactRaidFrameManager_Collapse(mgr);s:flush();check(mgr.points[5]==raised,"collapsed and expanded modes move vertically by the same amount")
    s.combat=true;local writes=s.writes;e.FluxRaid_PositionContainer();s:flush()
    check(s.writes==writes,"combat manager reposition defers all protected writes")
    local late=cell("CompactRaidFrame3",root,.8)
    e.FluxRaid_ApplyBlizzardCompactGridHidden();s:flush()
    check(late.selectionHighlight.alpha==.8 and s.writes==writes,"combat ghost reconciliation also defers native mutations")
    s.combat=false;e.FluxRaid_RunPendingCombatWork();s:flush()
    check(late.selectionHighlight.alpha==0,"post-combat reconciliation suppresses late native cells")
    s.editing=true;writes=s.writes;e.FluxRaid_PositionContainer();e.FluxRaid_ApplyBlizzardCompactGridHidden();s:flush()
    check(s.writes==writes,"Edit Mode defers both manager and ghost presentation")
    s:leaveEdit();s:flush();check(s.auraTouches==0,"deferred restoration never enters forbidden aura subtrees")
    local changed=cell("CompactRaidFrame4",root,.45)
    e.FluxRaid_ApplyBlizzardCompactGridHidden();s:flush();changed.selectionHighlight.alpha=.25
    native.selectionHighlight.opaqueAlpha=true;s.enabled=false;e.FluxRaid_RestoreBlizzardRaidFrames()
    check(native.selectionHighlight.alpha==.7 and unknown.selectionHighlight.alpha==.6 and late.selectionHighlight.alpha==.8,
        "disable restores exact known native selection alphas even if a later getter is opaque")
    check(changed.selectionHighlight.alpha==.25,"disable preserves a newer readable external selection-alpha change")
    check(native.readyCheckIcon.alpha==.8 and native.readyCheckIcon.Icon.alpha==.9,"disable restores exact known ready-check frame and texture alphas")
    check(native.selectionHighlight.ignoreParentAlpha and native.readyCheckIcon.ignoreParentAlpha and native.readyCheckIcon.Icon.ignoreParentAlpha,
        "disable restores original native parent-alpha inheritance flags")
    check(root.alpha==1 and root.click and root.motion and root.wheel,"native grid artwork/input restore with prior policies")
    check(mgr.scale==1.1 and mgr.points[1]=="TOPLEFT"and mgr.points[4]==(classic and-182 or-200),
        "disable restores prior manager scale and calls the actual native family collapse signature")
end
local function preparedSolo(branch,source)
    local e,s,ns,db,root,native,mgr,member=fixture(branch,source)
    member.attrs.unit=nil
    local container=e.FluxRaidState.containerFrame
    container.gridTop=470
    e.FluxRaid_InstallManagerHooks();e.FluxRaid_PositionContainer()
    local y=mgr.points[5]
    check(y~=nil and math.abs(y*mgr:GetEffectiveScale()-(470+20)*s.uiScale)<1e-8,
        "solo pool preparation positions the full manager above its future secure grid")
    mgr:Hide();s.combat=true
    local writes=s.writes
    s.nativeVisibility=true;mgr:Show();s.nativeVisibility=false;s:flush()
    check(mgr.shown and mgr.points[5]==y and s.writes==writes,
        "native combat reveal retains the solo-prepared Y without insecure geometry writes")
    s.combat=false;e.FluxRaid_RunPendingCombatWork();s:flush()
    check(mgr.points[5]==y,"post-combat reconciliation retains prepared Y while no child is bound")
    member.attrs.unit="party1";member.gridTop=510;e.FluxRaid_PositionContainer()
    check(math.abs((mgr.points[5]-y)*mgr.scale-40)<1e-8,
        "a bound member's actual top takes priority over solo preparation after combat")
end
for _,branch in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    exercise(branch);preparedSolo(branch)
end
local ghost=layout:gsub('region:SetAlpha%(0%)','-- omitted selection suppression')
check(not pcall(exercise,"forever",ghost),"negative control detects the native ignore-parent-alpha ghost")
local x=layout:gsub('        x,\n','        200,\n')
check(not pcall(exercise,"forever",x),"negative control detects unwanted horizontal manager movement")
local opaque=layout:gsub('if Secret%(alpha%) or type%(alpha%)~="number" then return end','if type(alpha)~="number" then return end')
check(not pcall(exercise,"forever",opaque),"negative control rejects scalar inspection before the secret guard")
local unprepared=layout:gsub('    if not top then top=PhysicalTop%(State%.containerFrame%) end\n','')
check(not pcall(preparedSolo,"forever",unprepared),"negative control catches solo startup leaving the manager at native Y")
print("Raid manager/ghost: "..checks.." checks; five actual native handlers; four rejected negative controls; "..(cache and"pinned source cache"or"reference source trees"))
